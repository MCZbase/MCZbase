<!---
specimens/component/public.cfc
Copyright 2021 President and Fellows of Harvard College
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
--->
<!--- publicly available functions to support /specimens/Specimen.cfm --->
<cfcomponent>
<cf_rolecheck>
<cfinclude template = "/shared/functionLib.cfm" runOnce="true">
<cfinclude template="/media/component/search.cfc" runOnce="true"><!--- ? unused ? remove ? --->
<cfinclude template="/media/component/public.cfc" runOnce="true"><!--- for getMediaBlockHtml --->
<cfinclude template = "/shared/component/functions.cfc" runOnce="true"><!--- for getGuidLink() --->
<cfif NOT isDefined("reportError")>
	<cfinclude template="/shared/component/error_handler.cfc" runOnce="true">
</cfif>

<cffunction name="getSummaryHeaderHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfthread name="getSummaryHeaderThread">
		<cfoutput>
			<cftry>
				<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
					<cfset oneOfUs = 1>
				<cfelse>
					<cfset oneOfUs = 0>
				</cfif>
				<cfquery name="check" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT 
						concatEncumbranceDetails(<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">) encumbranceDetail
					FROM DUAL
				</cfquery>
				<cfif oneOfUs EQ 0 AND Findnocase("mask record", check.encumbranceDetail)>
					<cfthrow message="Record Masked">
				</cfif>
				<!--- Lookup live data (with redactions as specified by encumbrances) as flat may be stale --->
				<cfquery name="summary" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				 	SELECT DISTINCT
						collection.collection,
						cataloged_item.collection_object_id as collection_object_id,
						cataloged_item.cat_num,
						collecting_event.verbatim_date,
						collecting_event.began_date,
						collecting_event.ended_date,
						MCZBASE.GET_SCIENTIFIC_NAME_AUTHS_PL(cataloged_item.collection_object_id) as sci_name, MCZBASE.get_pretty_date(collecting_event.verbatim_date,collecting_event.began_date,collecting_event.ended_date,1,0) as pretty_date,
						MCZBASE.get_scientific_name_auths(cataloged_item.collection_object_id) as scientific_name,
						geog_auth_rec.higher_geog,
						<cfif oneOfUs EQ 0 AND Findnocase("mask coordinates", check.encumbranceDetail) >
							'[Masked]' as spec_locality,
						<cfelse>
							locality.spec_locality,
						</cfif>
						MCZBASE.GET_TOP_TYPESTATUS(cataloged_item.collection_object_id) as type_status,
						MCZBASE.concattypestatus_plain_s(cataloged_item.collection_object_id,1,1,0) as typestatusplain,
						MCZBASE.concatcitedas(cataloged_item.collection_object_id) as cited_as,
						MCZBASE.GET_TOP_TYPESTATUS_KIND(cataloged_item.collection_object_id) as toptypestatuskind
					FROM
						cataloged_item
						join collection on cataloged_item.collection_id = collection.collection_id
						join collecting_event on collecting_event.collecting_event_id = cataloged_item.collecting_event_id
						join locality on locality.locality_id = collecting_event.locality_id
						join geog_auth_rec on locality.geog_auth_rec_id = geog_auth_rec.geog_auth_rec_id
					WHERE
						cataloged_item.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
						AND rownum < 2
				</cfquery>
				<cfif summary.recordcount LT 1>
					<cfthrow message="No such cataloged item found.">
				</cfif>

				<cfset typeName = summary.type_status>
				<!--- handle the edge cases of a specimen having more than one type status --->
				<cfif summary.toptypestatuskind eq 'Primary' > 
					<cfset twotypes = '#replace(summary.typestatusplain,"|"," &nbsp; <br> &nbsp; ","all")#'>
					<cfset typeName = '<span class="font-weight-bold bg-white pt-0 px-2 text-center" style="padding-bottom:2px;"> #twotypes# </span>'>
				<cfelseif summary.toptypestatuskind eq 'Secondary' >
					<cfset twotypes= '#replace(summary.typestatusplain,"|"," &nbsp; <br> &nbsp; ","all")#'>
					<cfset typeName = '<span class="font-weight-bold bg-white pt-0 px-2 text-center" style="padding-bottom:2px;"> #twotypes# </span>'>
				<cfelse>
					<cfset twotypes= '#replace(summary.typestatusplain,"|"," &nbsp; <br> &nbsp; ","all")#'>
					<cfset typeName = '<span class="font-weight-bold bg-white pt-0 px-2 text-center" style="padding-bottom:2px;"> </span>'>
				</cfif>
				<div class="container-fluid" id="content">
					<cfif isDefined("summary.cited_as") and len(summary.cited_as) gt 0>
						<cfif summary.toptypestatuskind eq 'Primary' >
							<cfset sectionclass="primaryType">
						<cfelseif summary.toptypestatuskind eq 'Secondary' >
							<cfset sectionclass="secondaryType">
						</cfif>
					<cfelse>
						<cfset sectionclass="defaultType">
					</cfif>
					<section class="row #sectionclass# mb-2">
						<div class="col-12">
							<cfif isDefined("summary.cited_as") and len(summary.cited_as) gt 0>
								<cfif summary.toptypestatuskind eq 'Primary' >
									<cfset divclass="border-0">
								<cfelseif summary.toptypestatuskind eq 'Secondary' >
									<cfset divclass="no-card">
								</cfif>
							<cfelse>
								<cfset divclass="no-card">
							</cfif>
							<div class="card box-shadow #divclass# bg-transparent">
								<div class="row mb-0">
									<div class="float-left pr-md-0 my-1 
										<cfif len(header.imageurl) gt 7 and len(summary.cited_as) gt 7> 
											col-12 col-xl-4 
										<cfelseif len(header.imageurl) gt 7 and len(summary.cited_as) lt 7> 
											col-12 col-xl-6
										<cfelseif len(header.imageurl) lt 7 and len(summary.cited_as) gt 7> 
											col-12 col-xl-3 
										<cfelseif len(header.imageurl) lt 7 and len(summary.cited_as) lt 7>
											col-12 col-xl-5
										<cfelse>
											col-6 </cfif>
									">
								<cfset thisLink='<a href="/name/#summary.sci_name#" class="text-dark font-weight-bold">#summary.sci_name#</a>'>
										<div class="col-12 px-0">
											<h1 class="col-12 mb-1 h4 font-weight-bold">MCZ #summary.collection# #summary.cat_num#</h1>
											<h2 class="col-12 d-inline-block mt-0 mb-0 mb-xl-1">
												#thisLink#
											</h2>
										</div>
									</div>
									<div class="float-left mt-1 mt-xl-3 pr-md-0 
										<cfif len(header.imageurl) gt 7 and len(summary.cited_as) gt 7> 
												col-12 col-xl-3 
										<cfelseif len(header.imageurl) gt 7 and len(summary.cited_as) lt 7> 
												col-12 col-xl-1
										<cfelseif len(header.imageurl) lt 7 and len(summary.cited_as) gt 7> 
												col-12 col-xl-3 
										<cfelseif len(header.imageurl) lt 7 and len(summary.cited_as) lt 7>
											col-12 col-xl-1
										<cfelse>
											col-12 </cfif>
										">
										<cfif isDefined("summary.cited_as") and len(summary.cited_as) gt 0>
											<cfif summary.toptypestatuskind eq 'Primary' >
												<h2 class="col-12 d-inline-block h4 mb-2 my-xl-0">#typeName#</h2>
											</cfif>
											<cfif summary.toptypestatuskind eq 'Secondary'>
												<h2 class="col-12 d-inline-block h4 mb-2 my-xl-0">#typeName#</h2>
											</cfif>
										<cfelse>
											<!--- No type name to display for non-type specimens --->
										</cfif>	
									</div>
										
									<div class="float-left pr-md-0 my-1 mt-xl-2
										<cfif len(header.imageurl) gt 7 and len(summary.cited_as) gt 7> 
											col-12 col-xl-5 
										<cfelseif len(header.imageurl) gt 7 and len(summary.cited_as) lt 7> 
											col-12 col-xl-5
										<cfelseif len(header.imageurl) lt 7 and len(summary.cited_as) gt 7> 
											col-12 col-xl-5 
										<cfelseif len(header.imageurl) lt 7 and len(summary.cited_as) lt 7> 
											col-12 col-xl-5
										<cfelse> 
											col-xl-5 </cfif>
										">
										<div class="col-12 px-xl-0"><span class="small">Date Collected: </span>
											<h2 class="h5 mb-1 d-inline-block">
												<cftry>
													<cfobject type="Java" class="org.filteredpush.qc.date.DateUtils" name="dateUtils">
													<cfset formatted_date = dateUtils.extractDateFromVerbatimER(#summary.pretty_date#).getResult()>
												<cfcatch>
												</cfcatch>
												</cftry>
												<cfset date ="#summary.pretty_date#">
											
												<cfif isDefined("formatted_date") AND len(formatted_date) GT 0 >
													<cfset date = "#formatted_date#">
												<cfelseif summary.pretty_date EQ "[date unknown]" AND summary.began_date EQ "1700-01-01">
													<cfset date = "#summary.pretty_date# prior to #summary.ended_date#">
												</cfif>
												<span class="text-dark font-weight-lessbold">#date#</span>
											</h2>
										</div>
										<div class="col-12 px-xl-0">
											<h2 class="h5 mb-0">#summary.higher_geog#
											<cfif len(summary.spec_locality) GT 0> | #summary.spec_locality#<cfelse></cfif></h2>
										</div>
										<div class="col-12 px-xl-0 small">
											occurrenceID: <a class="h5 mb-1" href="https://mczbase.mcz.harvard.edu/guid/#GUID#">https://mczbase.mcz.harvard.edu/guid/#GUID#</a>
											<a href="/guid/#GUID#/json"><img src="/shared/images/json-ld-data-24.png" alt="JSON-LD"></a>
										</div>
									</div>
								</div>
							</div>
						</div>
					</section>
				</div>
			<cfcatch>
				<cfset error_message = cfcatchToErrorMessage(cfcatch)>
				<cfset function_called = "#GetFunctionCalledName()#">
				<h2 class='h3'>Error in #function_called#:</h2>
				<div>#error_message#</div>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="getSummaryHeaderThread" />
	<cfreturn getSummaryHeaderThread.output>
</cffunction>
					
<!--- getMediaHTML obtain a block of html listing media related to a cataloged item
 @param collection_object_id the collection_object_id for the cataloged item for which to obtain the media.
 @param relationship_type which relationships to show, one of 'shows' for shows cataloged item, 'documents' for
   ledger entry for cataloged item and field notes, or 'all' for any cataloged_item media relationship.
 @param get_count if equal to 'true', return just the count of the number of related media records, not the html (forces the count
   to be the same query as the media record query).
 @return html for viewing media for the specified cataloged item, or the integer count of media records if get_count
   is specified as true. 
--->
<cffunction name="getMediaHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfargument name="relationship_type" type="string" required="yes">
	<cfargument name="get_count" type="string" required="no" default="">

	<cfset l_get_count = arguments.get_count>
	<cfset l_relationship_type= arguments.relationship_type>
	<cfset l_collection_object_id= arguments.collection_object_id>
	<cfset tn = REReplace(CreateUUID(), "[-]", "", "all") >	
	<cfthread name="getMediaThread#tn#">
		<cfoutput>
			<cftry>
				<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
					<cfset oneOfUs = 1>
				<cfelse>
					<cfset oneOfUs = 0>
				</cfif>
				<!--- check for mask record, hide if mask record and not one of us ---->
				<cfquery name="check" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT 
						concatEncumbranceDetails(<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">) encumbranceDetail
					FROM DUAL
				</cfquery>
				<cfif oneOfUs EQ 0 AND Findnocase("mask record", check.encumbranceDetail)>
					<cfthrow message="Record Masked">
				</cfif>
				<cfquery name="getImages" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select distinct 
					media_id, auto_host, auto_path, auto_filename, media_uri, preview_uri, mime_type, media_type, media_descriptor 
				FROM (
					SELECT
						media.media_id,
						media.auto_host,
						media.auto_path,
						media.auto_filename,
						media.media_uri,
						media.preview_uri as preview_uri,
						media.mime_type as mime_type,
						media.media_type,
						mczbase.get_media_descriptor(media.media_id) as media_descriptor
					FROM 
						media
							LEFT JOIN media_relations on media.media_id = media_relations.media_id 
						JOIN media_relations cmr on media.media_id = cmr.media_id
					WHERE
						MCZBASE.is_media_encumbered(media.media_id) < 1 
						AND cmr.related_primary_key = <cfqueryparam value="#l_collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
						<cfif l_relationship_type EQ 'shows'>
							AND cmr.media_relationship = 'shows cataloged_item'
						<cfelseif l_relationship_type EQ 'documents'>
							AND (cmr.media_relationship = 'ledger entry for cataloged_item' OR cmr.media_relationship = 'documents cataloged_item')
						<cfelse>
							AND cmr.media_relationship like '% cataloged_item'
						</cfif>
					<cfif l_relationship_type EQ 'documents'>
					UNION
					SELECT
						media.media_id,
						media.auto_host,
						media.auto_path,
						media.auto_filename,
						media.media_uri,
						media.preview_uri as preview_uri,
						media.mime_type as mime_type,
						media.media_type,
						mczbase.get_media_descriptor(media.media_id) as media_descriptor
					FROM 
						media
						LEFT JOIN media_relations lmr on media.media_id = lmr.media_id
						LEFT JOIN cataloged_item on lmr.related_primary_key = cataloged_item.collecting_event_id 
					WHERE
						MCZBASE.is_media_encumbered(media.media_id)  < 1 
						AND lmr.media_relationship = 'documents collecting_event'
						AND cataloged_item.collection_object_id = <cfqueryparam value="#l_collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
					</cfif>
					)
				ORDER BY
					length(media_descriptor) asc
				</cfquery>
				<cfif isDefined("l_get_count") AND l_get_count EQ "true">
					#getImages.recordcount#
				<cfelse>
					<cfloop query="getImages">
						<cfif l_relationship_type EQ "shows">
							<!--- two column specimen media --->
							<cfset enclosingClass = "col-12 col-lg-6 px-1 mb-1 px-md-1 py-1 float-left">
						<cfelse>
							<!--- three column for other media types --->
							<cfset enclosingClass = "col-12 px-2 col-sm-6 col-lg-6 col-xl-4 mb-1 px-md-2 pt-1 float-left">
						</cfif>
						<div class='#enclosingClass#'>
							<!---For getMediaBlockHtml variables: use size that expands img to container with max-width: 350px so it look good on desktop and phone; --without displayAs-- captionAs="textShort" (truncated to 50 characters) --->
							<!--- note, size=350 will set minimum zoom on multizoom to 2, not 4, making small zoom on desktop --->
							<div id='mediaBlock#getImages.media_id#'>
								<cfset mediaBlock= getMediaBlockHtmlUnthreaded(media_id="#getImages.media_id#",size="350",captionAs="textShort")>
							</div>
						</div>
					</cfloop>
				
				</cfif>
			<cfcatch>
				<cfset error_message = cfcatchToErrorMessage(cfcatch)>
				<cfset function_called = "#GetFunctionCalledName()#">
				<h2 class='h3'>Error in #function_called#:</h2>
				<div>#error_message#</div>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="getMediaThread#tn#" />
	<cfreturn cfthread["getMediaThread#tn#"].output>
</cffunction>
							
<!--- getIdentifiersHTML obtain a block of html listing cataloge number information for a cataloged item
 @param collection_object_id the collection_object_id for the cataloged item for which to obtain the catalog number
 @return html for viewing catalog number information for the specified cataloged item. 
--->
<cffunction name="getIdentifiersHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfthread name="getIdentifiersThread">
		<cfoutput>
			<cftry>
				<cfquery name="identifiers" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT distinct
						collection.collection, cataloged_item.cat_num, collection.guid_prefix, collection.web_link
					FROM 
						collection, cataloged_item 
					WHERE 
						collection.collection_id = cataloged_item.collection_id 
					AND 
						cataloged_item.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
				</cfquery>
				<cfif len(identifiers.cat_num) gt 0>
					<ul class="list-group pl-0 py-1">
						<li class="list-group-item py-0">
								<span class="float-left font-weight-lessbold">Collection: </span>
							<cfif len(identifiers.cat_num) gt 0>
								<a class="pl-1 mb-0" href="#identifiers.web_link#"> #identifiers.collection# </a>
							<cfelse>
								<span class="float-left pl-1 mb-0"> #identifiers.collection#</span>
							</cfif>
						</li>
						<li class="list-group-item py-0">
								<span class="float-left font-weight-lessbold">Catalog Number: </span>
								<span class="float-left pl-1 mb-0"> #identifiers.cat_num#</span>
						</li>
						<li class="list-group-item py-0">
							<span class="float-left font-weight-lessbold">GUID: </span>
							<span class="float-left pl-1 mb-0"><a href="https://mczbase.mcz.harvard.edu/guid/#identifiers.guid_prefix#:#identifiers.cat_num#">#identifiers.guid_prefix#:#identifiers.cat_num#</a></span>
						</li>
					</ul>
				</cfif>
			<cfcatch>
				<cfset error_message = cfcatchToErrorMessage(cfcatch)>
				<cfset function_called = "#GetFunctionCalledName()#">
				<h2 class="h3">Error in #function_called#:</h2>
				<div>#error_message#</div>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="getIdentifiersThread" />
	<cfreturn getIdentifiersThread.output>
</cffunction>
							
<!--- getIdentificationsHTML obtain a block of html listing identifications for a cataloged item
 @param collection_object_id the collection_object_id for the cataloged item for which to obtain the identifications.
 @return html for viewing identifications for the specified cataloged item. 
--->
<cffunction name="getIdentificationsHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="collection_object_id" type="string" required="yes">

	<cfthread name="getIdentificationsThread">
		<cfoutput>
			<cftry>
				<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
					<cfset oneOfUs = 1>
				<cfelse>
					<cfset oneOfUs = 0>
				</cfif>
				<!--- check for mask record, hide if mask record and not one of us ---->
				<cfquery name="check" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT 
						concatEncumbranceDetails(<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">) encumbranceDetail
					FROM DUAL
				</cfquery>
				<cfif oneOfUs EQ 0 AND Findnocase("mask record", check.encumbranceDetail)>
					<cfthrow message="Record Masked">
				</cfif>
				<cfquery name="identification" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT
						identification.scientific_name,
						identification.collection_object_id,
						made_date,
						nature_of_id,
						identification_remarks,
						identification.identification_id,
						accepted_id_fg,
						taxa_formula,
						formatted_publication,
						identification.publication_id,
						stored_as_fg
					FROM
						identification
						left join formatted_publication on identification.publication_id=formatted_publication.publication_id and format_style='short'
					WHERE
						identification.collection_object_id = <cfqueryparam value="#collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
					ORDER BY 
						accepted_id_fg DESC,sort_order, made_date DESC
				</cfquery>
				<cfset i=1>
				<cfloop query="identification">
					<cfquery name="determiners" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						SELECT distinct
							preferred_agent_name.agent_name,
							identification_agent.agent_id,
							agent.agentguid,
							agent.agentguid_guid_type,
							identifier_order
						FROM
							identification_agent
							left join preferred_agent_name on identification_agent.agent_id = preferred_agent_name.agent_id
							left join agent on identification_agent.agent_id = agent.agent_id
						WHERE 
							identification_agent.identification_id = <cfqueryparam value="#identification_id#" cfsqltype="CF_SQL_DECIMAL">
						ORDER BY
							identifier_order
					</cfquery>
					<cfset nameAsInIdentification = identification.scientific_name>
					<cfquery name="getTaxa" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						SELECT distinct
							identification_taxonomy.variable,
							taxonomy.taxon_name_id,
							display_name,
							scientific_name,
							author_text,
							full_taxon_name,
							taxonomy.taxonid,
							taxonomy.taxonid_guid_type
						FROM 
							identification_taxonomy
							JOIN taxonomy on identification_taxonomy.taxon_name_id = taxonomy.taxon_name_id
						WHERE 
							identification_id = <cfqueryparam value="#identification_id#" cfsqltype="CF_SQL_DECIMAL">
					</cfquery>
					<cfif identification.accepted_id_fg is 1>
						<!---	Start for current Identification, enclose in green bordered block. --->
						<div class="list-group border-green rounded mx-1 my-2 p-2 h4 font-weight-normal">
						<div class="d-inline-block my-0 h5 text-success">Current Identification</div>
					<cfelse>
						<div class="list-group border-transparent rounded mx-1 mt-0 mb-1 p-1 h4 font-weight-normal">
						<!---	Start of former Identifications --->
						<cfif identification.recordcount GT 2><cfset plural = "s"><cfelse><cfset plural = ""></cfif>
						<cfset IDtitle = "Previous Identification#plural#">
						<!--- no ul for previous identifications --->
						<cfif i EQ 2>
						
							<div class="h6 mt-0 mb-1 text-success formerID">#IDtitle#</div>
						</cfif>
					</cfif>
					<div class="h4 my-0 font-weight-lessbold d-inline-block">
						<cfif getTaxa.recordcount is 1 and identification.taxa_formula IS 'A'>
							<!--- simple formula with no added information just show name and link --->
							<cfloop query="getTaxa"><!--- just to be explicit, only one row should match --->
								<a href="/name/#getTaxa.scientific_name#">#getTaxa.display_name# </a>
								<cfif len(getTaxa.author_text) gt 0>
									<span class="sm-caps font-weight-lessbold">#getTaxa.author_text#</span>
								</cfif>
								<cfif len(getTaxa.taxonid) gt 0>
									<cfset link = getGuidLink(guid=#getTaxa.taxonid#,guid_type=#getTaxa.taxonid_guid_type#)>
									<span>#link#</span>
								</cfif>
								<cfset nameAsInTaxon = getTaxa.scientific_name>
							</cfloop>
						<cfelse>
							<!--- interpret the taxon formula in identification --->
							<cfset expandedVariables="#identification.taxa_formula#">
							<cfset nameAsInTaxon="#identification.taxa_formula#">
							<cfloop query="getTaxa">
								<!--- replace each component of the formula with the name, in a hyperlink --->
								<cfset thisLink='<a href="/name/#getTaxa.scientific_name#" class="d-inline">#getTaxa.display_name#</a>'>
								<cfif identification.taxa_formula NEQ "A x B">
									<!--- include the authorship if not a hybrid --->
									<cfset thisLink= '#thisLink# <span class="sm-caps font-weight-lessbold">#getTaxa.author_text#</span>'>
								</cfif>
								<cfset expandedVariables=#replace(expandedVariables,getTaxa.variable,thisLink)#>
								<cfset nameAsInTaxon=#replace(nameAsInTaxon,getTaxa.variable,getTaxa.scientific_name)#>
								<cfset i=#i#+1>
							</cfloop>
							#expandedVariables#
						</cfif>
					</div>
					<cfif listcontainsnocase(session.roles,"manage_specimens")>
						<cfif stored_as_fg is 1>
							<span class="bg-gray float-right rounded p-1 text-muted font-weight-lessbold">STORED AS</span>
						</cfif>
					</cfif>
					<cfif len(formatted_publication) gt 0>
						<div class="h6 px-3 mb-1">
							sensu <a href="/publication/#publication_id#">#formatted_publication#</a>
						</div>
					</cfif>
					<cfif not isdefined("metaDesc")>
						<cfset metaDesc="">
					</cfif>
					<cfquery name="getHigher" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						SELECT distinct replace(full_taxon_name,scientific_name,'') distinct_higher
						FROM 
							identification_taxonomy
							JOIN taxonomy on identification_taxonomy.taxon_name_id = taxonomy.taxon_name_id
						WHERE 
							identification_id = <cfqueryparam value="#identification_id#" cfsqltype="CF_SQL_DECIMAL">
					</cfquery>
					<!--- show the distinct bits of the full classification for each name in the identification --->
					<div class="h6 mb-1 text-dark"> #getHigher.distinct_higher# </div>
					<cfloop query="getTaxa">
						<!--- get the list of common names for each taxon in the identification ---->
						<cfset metaDesc=metaDesc & '; ' & full_taxon_name>
						<cfquery name="cName" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							SELECT 
								common_name 
							FROM 
								common_name
							WHERE 
								taxon_name_id= <cfqueryparam value="#getTaxa.taxon_name_id#" cfsqltype="CF_SQL_DECIMAL"> 
								and common_name is not null
							GROUP BY 
								common_name order by common_name
						</cfquery>
						<cfif len(cName.common_name) gt 0>
							<div class="font-weight-lessbold mb-1 mt-0 h5 text-muted pl-3">Common Name(s): #valuelist(cName.common_name,"; ")# </div>
						</cfif>
						<cfset metaDesc=metaDesc & '; ' & valuelist(cName.common_name,"; ")>
					</cfloop>
					<cfif nameAsInTaxon NEQ nameAsInIdentification>
						<!--- show the name preserving the original form used in the identification --->
						<div class="form-row mx-0">
							<div class="small mr-2"><span class="font-weight-lessbold">Determined As:</span> #identification.scientific_name# </div>
						</div>
					</cfif>
					<div class="form-row mx-0">
						<cfset determinedBy = "">
						<cfset detbysep = "">
						<cfloop query="determiners">
							<cfif len(determiners.agent_id) GT 0 AND determiners.agent_id NEQ "0"> 
								<cfset determinedBy="#determinedBy##detbysep#<a href='/agents/Agent.cfm?agent_id=#determiners.agent_id#'>#determiners.agent_name#</a>" > <!--- " --->
								<cfif len(determiners.agentguid) gt 0>
									<cfset link = getGuidLink(guid=#determiners.agentguid#,guid_type=#determiners.agentguid_guid_type#)>
									<cfset determinedBy ="#determinedBy#<span>#link#</span>" > <!--- " --->
								</cfif>
							<cfelse>
								<cfset determinedBy="#determinedBy##detbysep##determiners.agent_name#" >
							</cfif>
							<cfset detbysep="; ">
						</cfloop>
						<div class="small mr-2"><span class="font-weight-lessbold">Determiner:</span> #determinedBy#
							<cfif len(made_date) gt 0>
								<cfif len(made_date) gt 8>
									<span class="font-weight-lessbold">on</span> #identification.made_date#
								<cfelse>
									<span class="font-weight-lessbold">in</span> #identification.made_date#
								</cfif>
							</cfif>
						</div>
					</div>
					<div class="small mr-2"><span class="font-weight-lessbold">Nature of ID:</span> #identification.nature_of_id# </div>
					<cfif len(identification_remarks) gt 0>
						<div class="small"><span class="font-weight-lessbold">Remarks:</span> #identification.identification_remarks#</div>
					</cfif>
					
					
						</div>
					
					<cfset i = i+1>
				</cfloop>
			<cfcatch>
				<cfset error_message = cfcatchToErrorMessage(cfcatch)>
				<cfset function_called = "#GetFunctionCalledName()#">
				<h2 class='h3'>Error in #function_called#:</h2>
				<div>#error_message#</div>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="getIdentificationsThread" />
	<cfreturn getIdentificationsThread.output>
</cffunction>

<!--- getOtherIdsHTML obtain a block of html listing other id numbers for a cataloged item
 @param collection_object_id the collection_object_id for the cataloged item for which to obtain the other id numbers
 @return html for viewing other identifiers for the specified cataloged item. 
--->
<cffunction name="getOtherIDsHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="collection_object_id" type="string" required="yes">

	<cfthread name="getOtherIDsThread">
		<cfoutput>
			<cftry>
				<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
					<cfset oneOfUs = 1>
				<cfelse>
					<cfset oneOfUs = 0>
				</cfif>
				<!--- check for mask record, hide if mask record and not one of us ---->
				<cfquery name="check" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT 
						concatEncumbranceDetails(<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">) encumbranceDetail
					FROM DUAL
				</cfquery>
				<cfif oneOfUs EQ 0 AND Findnocase("mask record", check.encumbranceDetail)>
					<cfthrow message="Record Masked">
				</cfif>
				<cfquery name="oid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT
						<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
							coll_obj_other_id_num.display_value, 
						<cfelse>
							case 
								when concatencumbrances(coll_obj_other_id_num.collection_object_id) like '%mask original field number%' and
									ctcoll_other_id_type.encumber_as_field_num = 1 
								then 'Masked'
								else coll_obj_other_id_num.display_value
							end display_value,
						</cfif>
						coll_obj_other_id_num.other_id_type,
						case when base_url is not null then
							ctcoll_other_id_type.base_url || coll_obj_other_id_num.display_value
						else
							null
						end link
					FROM
						coll_obj_other_id_num 
						left join ctcoll_other_id_type on coll_obj_other_id_num.other_id_type=ctcoll_other_id_type.other_id_type
					where
						collection_object_id= <cfqueryparam value="#collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
					ORDER BY
						other_id_type,
						display_value
				</cfquery>
				<cfif len(oid.other_id_type) gt 0>
					<ul class="list-group pl-0 py-1">
						<cfloop query="oid">
							<li class="list-group-item py-0">
								<span class="text-capitalize float-left font-weight-lessbold">#other_id_type#: </span>
							<cfif len(link) gt 0>
								<a class="pl-1 mb-0" href="#link#"> #display_value# <img src="/shared/images/linked_data.png" height="15" width="15" alt="linked data icon"></a>
							<cfelse>
								<span class="float-left pl-1 mb-0"> #display_value#</span>
							</cfif>
							</li>
						</cfloop>
					</ul>
				</cfif>
			<cfcatch>
				<cfset error_message = cfcatchToErrorMessage(cfcatch)>
				<cfset function_called = "#GetFunctionCalledName()#">
				<h2 class="h3">Error in #function_called#:</h2>
				<div>#error_message#</div>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="getOtherIDsThread" />
	<cfreturn getOtherIDsThread.output>
</cffunction>
					
<!--- getCitationsHTML obtain a block of html listing citations for a cataloged item
 @param collection_object_id the collection_object_id for the cataloged item for which to obtain the citations
 @return html for viewing other citations for the specified cataloged item. 
 @see getCitationMediaHTML for media linked to the citations (publication media).
--->
<cffunction name="getCitationsHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfthread name="getCitationsThread">
		<cfoutput>
			<cftry>
				<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
					<cfset oneOfUs = 1>
				<cfelse>
					<cfset oneOfUs = 0>
				</cfif>
				<!--- check for mask record, hide if mask record and not one of us ---->
				<cfquery name="check" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT 
						concatEncumbranceDetails(<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">) encumbranceDetail
					FROM DUAL
				</cfquery>
				<cfif oneOfUs EQ 0 AND Findnocase("mask record", check.encumbranceDetail)>
					<cfthrow message="Record Masked">
				</cfif>
				<cfquery name="citations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT distinct
						citation.type_status,
						citation.occurs_page_number,
						citation.citation_page_uri,
						citation.CITATION_REMARKS,
						cited_taxa.scientific_name as cited_name,
						cited_taxa.author_text as cited_name_author_text,
						cited_taxa.taxon_name_id as cited_name_id,
						formatted_publication.formatted_publication,
						formatted_publication.publication_id,
						publication.doi,
						cited_taxa.taxon_status as cited_name_status
					FROM
						citation
						left join taxonomy cited_taxa on citation.cited_taxon_name_id = cited_taxa.taxon_name_id
						left join publication on citation.publication_id = publication.publication_id
						left join formatted_publication on publication.publication_id = formatted_publication.publication_id and format_style='short'
					WHERE
						citation.collection_object_id = <cfqueryparam value="#collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
					ORDER BY
						substr(formatted_publication, - 4)
				</cfquery>
				<cfset i = 1>
				<cfloop query="citations" group="formatted_publication">
					<div class="list-group pt-0 d-block pb-1 px-2 w-100 mb-0 small95">
						<span class="d-inline"></span>
						<a href="/publications/showPublication.cfm?publication_id=#publication_id#">#formatted_publication#</a>,
						<cfif len(occurs_page_number) gt 0>page 
							<cfif len(citation_page_uri) gt 0>
								<a href ="#citation_page_uri#">#occurs_page_number#</a>,
							<cfelse>
								#occurs_page_number#,
							</cfif>
						<cfelse>
							<cfif len(citation_page_uri) gt 0>
								<a href ="#citation_page_uri#">[link]</a>,
							</cfif>
						</cfif>
						<span class="font-weight-lessbold">#type_status#</span> of 
						<a href="/taxonomy/showTaxonomy.cfm?taxon_name_id=#cited_name_id#">
							<i>#replace(cited_name," ","&nbsp;","all")#</i>
							<span class="sm-caps">#cited_name_author_text#</span>
						</a>
						<cfif find("(ms)", #type_status#) NEQ 0>
							<!--- Type status with (ms) is used to mark to be published types, for which we aren't (yet) exposing the new name.  Append sp. nov or ssp. nov.as appropriate to the name of the parent taxon of the new name --->
							<cfif find(" ", #cited_name#) NEQ 0>
								&nbsp;ssp. nov.
							<cfelse>
								&nbsp;sp. nov.
							</cfif>
						</cfif>
						<cfif len(cited_name_status) GT 0>
							<span class="font-weight-lessbold">[#cited_name_status#]</span>
						</cfif>
						<cfif len(#doi#) GT 0>
							doi: <a target="_blank" href="https://doi.org/#doi#">#doi# <img src="/shared/images/linked_data.png" height="15" width="15" alt="linked data icon"></a><br>
						</cfif>
						<span class="small font-italic">
							<cfif len(citation_remarks) gt 0></cfif>
							#CITATION_REMARKS#
						</span>
					</div>
					<cfset i = i + 1>
				</cfloop>
			<cfcatch>
				<cfset error_message = cfcatchToErrorMessage(cfcatch)>
				<cfset function_called = "#GetFunctionCalledName()#">
				<h2 class='h3'>Error in #function_called#:</h2>
				<div>#error_message#</div>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="getCitationsThread" />
	<cfreturn getCitationsThread.output>
</cffunction>

<!--- getCitationMediaHTML obtain a block of html listing media related to citations a cataloged item
 @param collection_object_id the collection_object_id for the cataloged item for which to obtain the media.
 @param get_count if equal to 'true', return just the count of the number of related media records, not the html (forces the count
   to be the same query as the media record query).
 @return html for viewing media for the specified cataloged item, or the integer count of media records if get_count
   is specified as true. 
 @see getCitationsHTML for list of citations.
--->
<cffunction name="getCitationMediaHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfargument name="get_count" type="string" required="no" default="">

	<cfset l_get_count = arguments.get_count>
	<cfset l_collection_object_id= arguments.collection_object_id>
	<cfset tn = REReplace(CreateUUID(), "[-]", "", "all") >
	<cfthread name="getCitMediaThread#tn#">
		<cfoutput>
			<cftry>
				<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
					<cfset oneOfUs = 1>
				<cfelse>
					<cfset oneOfUs = 0>
				</cfif>
				<!--- check for mask record, hide if mask record and not one of us ---->
				<cfquery name="check" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT 
						concatEncumbranceDetails(<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">) encumbranceDetail
					FROM DUAL
				</cfquery>
				<cfif oneOfUs EQ 0 AND Findnocase("mask record", check.encumbranceDetail)>
					<cfthrow message="Record Masked">
				</cfif>
				<cfquery name="getImages" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT distinct 
						media_relations.media_id, formatted_publication
					FROM
						citation 
						left join publication on citation.publication_id = publication.publication_id
						left join formatted_publication on publication.publication_id = formatted_publication.publication_id and format_style='short'
						left join media_relations on publication.publication_id = media_relations.related_primary_key
					WHERE
						MEDIA_RELATIONSHIP like '% publication' and
						citation.collection_object_id = <cfqueryparam value="#collection_object_id#" cfsqltype="CF_SQL_DECIMAL"> and
						MCZBASE.is_media_encumbered(media_relations.media_id) < 1
					ORDER by substr(formatted_publication, -4)
				</cfquery>
				<cfif isDefined("l_get_count") AND l_get_count EQ "true">
					#getImages.recordcount#
				<cfelse>
					<cfloop query="getImages">
						<div class='col-12 col-sm-6 px-2 col-lg-6 col-xl-4 mb-1 px-md-2 pt-1 float-left'>
							<!---For getMediaBlockHtml variables: use size that expands img to container with max-width: 350px so it look good on desktop and phone; --without displayAs-- captionAs="textShort" (truncated to 50 characters) --->
							<div id='mediaBlock#getImages.media_id#'>
								<cfset mediaBlock= getMediaBlockHtmlUnthreaded(media_id="#getImages.media_id#",size="350",captionAs="textCaption")>
							</div>
						</div>
					</cfloop>
				</cfif>
			<cfcatch>
				<cfset error_message = cfcatchToErrorMessage(cfcatch)>
				<cfset function_called = "#GetFunctionCalledName()#">
				<h2 class='h3'>Error in #function_called#:</h2>
				<div>#error_message#</div>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="getCitMediaThread#tn#" />
	<cfreturn cfthread["getCitMediaThread#tn#"].output>
</cffunction>
								
<!--- getPartsHTML obtain a block of html listing parts/preparations for a specified cataloged item
 @param collection_object_id the collection_object_id for the cataloged item for which to obtain the parts.
 @return html listing parts for the specified cataloged item.
--->
<cffunction name="getPartsHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="collection_object_id" type="string" required="yes">

	<cfthread name="getPartsThread">
		<cfoutput>
			<cftry>
				<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
					<cfset oneOfUs = 1>
				<cfelse>
					<cfset oneOfUs = 0>
				</cfif>
				<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_transactions")>
					<cfset manageTransactions = 1>
				<cfelse>
					<cfset manageTransactions = 0>
				</cfif>
				<cfquery name="check" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT 
						concatEncumbranceDetails(<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">) encumbranceDetail
					FROM DUAL
				</cfquery>
				<!--- check for mask record, hide if mask record and not one of us ---->
				<cfif oneOfUs EQ 0 AND Findnocase("mask record", check.encumbranceDetail)>
					<cfthrow message="Record Masked">
				</cfif>
				<!--- return text instead of throwing an exception if mask parts --->
				<cfif oneofus EQ 0 AND Findnocase("mask parts", check.encumbranceDetail)>
					<div class="mt-1"></div><!--- Masked, return no data on parts --->
				<cfelse>
					<!--- find out if any of this material is on loan --->
					<cfquery name="loanList" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						SELECT distinct loan_number, loan_type, loan_status, loan.transaction_id 
						FROM
							specimen_part 
							left join loan_item on specimen_part.collection_object_id=loan_item.collection_object_id
				 			left join loan on loan_item.transaction_id = loan.transaction_id
						WHERE
							loan_number is not null and
							specimen_part.derived_from_cat_item=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
					</cfquery>
					<!--- find out if any of this material has been deaccessioned --->
					<cfquery name="deaccessionList" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						SELECT distinct deacc_number, deaccession.transaction_id, specimen_part.collection_object_id
						FROM
							specimen_part 
							left join deacc_item on specimen_part.collection_object_id=deacc_item.collection_object_id
				 			left join deaccession on deacc_item.transaction_id = deaccession.transaction_id
						WHERE
							deacc_number is not null and
							specimen_part.derived_from_cat_item=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
					</cfquery>
					<!--- retrieve all the denormalized parts data in one query, then query those results to get normalized information to display --->
					<cfquery name="getParts" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select
							specimen_part.collection_object_id part_id,
							<cfif oneOfUs EQ 1>
								pc.label, 
							<cfelse>
								null as label,
							</cfif>
							nvl2(preserve_method, part_name || ' (' || preserve_method || ')',part_name) part_name,
							sampled_from_obj_id,
							coll_object.COLL_OBJ_DISPOSITION part_disposition,
							coll_object.CONDITION part_condition,
							nvl2(lot_count_modifier, lot_count_modifier || lot_count, lot_count) lot_count,
							coll_object_remarks part_remarks,
							attribute_type,
							attribute_value,
							attribute_units,
							determined_date,
							attribute_remark,
							agent_name,
							agent.agent_id,
							agentguid,
							agentguid_guid_type
						from
							specimen_part
							left join coll_object on specimen_part.collection_object_id=coll_object.collection_object_id
							left join coll_object_remark on coll_object.collection_object_id=coll_object_remark.collection_object_id
							left join coll_obj_cont_hist on coll_object.collection_object_id=coll_obj_cont_hist.collection_object_id
							left join container oc on coll_obj_cont_hist.container_id=oc.container_id
							left join container pc on oc.parent_container_id=pc.container_id
							left join specimen_part_attribute on specimen_part.collection_object_id=specimen_part_attribute.collection_object_id
							left join preferred_agent_name on specimen_part_attribute.determined_by_agent_id=preferred_agent_name.agent_id
							left join agent on specimen_part_attribute.determined_by_agent_id = agent.agent_id
						where
							specimen_part.derived_from_cat_item = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
					</cfquery>
					<!---- obtain the distinct parts from the getParts query (collapsing duplicated rows from attributes) --->
					<cfquery name="distinctParts" dbtype="query">
						select
							part_id,
							label,
							part_name,
							sampled_from_obj_id,
							part_disposition,
							part_condition,
							lot_count,
							part_remarks
						from
							getParts
						group by
							part_id,
							label,
							part_name,
							sampled_from_obj_id,
							part_disposition,
							part_condition,
							lot_count,
							part_remarks
						order by
							part_name, part_id
					</cfquery>
					<table class="table px-1 table-responsive-md w-100 tablesection my-1">
						<thead class="thead-light">
							<tr>
								<th class="py-0"><span>Part</span></th>
								<th class="py-0"><span>Condition</span></th>
								<th class="py-0"><span>Disposition</span></th>
								<th class="py-0"><span>Count</span></th>
								<cfif oneOfus is "1">
									<th class="py-0">
										<span>Container</span>
									</th>
								</cfif>
								<th class="py-0"></th>
								
							</tr>
						</thead>
						<tbody class="bg-white">
							<!--- iterate through the main (not subsampled) parts --->
							<cfquery name="mainParts" dbtype="query">
								select * from distinctParts where sampled_from_obj_id is null order by part_name
							</cfquery>
							<cfset i=1>
							<cfloop query="mainParts">
								<cfquery name="historyCount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
									SELECT sum(cti) ct from (
										SELECT count(*) cti 
										FROM object_condition 
										WHERE
											collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#mainParts.part_id#">
										UNION
										SELECT count(*) cti
										FROM specimen_part_pres_hist
										WHERE
											collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#mainParts.part_id#">
									)
								</cfquery>
								<cfif historyCount.ct GT 2><cfset histCount = " (#historyCount.ct#)"><cfelse><cfset histCount = ""></cfif>
								<div id="historyDialog#mainParts.part_id#"></div>
								<tr <cfif mainParts.recordcount gt 1>class="line-top-sd"<cfelse></cfif>>
									<td class="py-1"><span class="font-weight-lessbold">#part_name#</span></td>
									<td class="py-1">
										#part_condition#
									</td>
									<!--- TODO: Link out to history for part(s) --->
									<td class="py-1">
										#part_disposition#
										<cfif loanList.recordcount GT 0 AND manageTransactions IS "1">
											<!--- look up whether this part is in an open loan --->
											<cfquery name="partonloan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
												SELECT
													loan_number, loan_type, loan_status, loan.transaction_id, item_descr, loan_item_remarks
												FROM 
													specimen_part 
													LEFT JOIN loan_item on specimen_part.collection_object_id = loan_item.collection_object_id
													LEFT JOIN loan on loan_item.transaction_id = loan.transaction_id
												WHERE
													 specimen_part.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#mainParts.part_id#">
													and loan_status <> 'closed'
											</cfquery>
											<cfloop query="partonloan">
												<cfif partonloan.loan_status EQ 'open' and mainParts.part_disposition EQ 'on loan'>
													<!--- normal case --->
													<a href="/transactions/Loan.cfm?action=editLoan&transaction_id=#partonloan.transaction_id#">#partonloan.loan_number#</a>
												<cfelse>
													<!--- partial returns, in process, historical, in-house, or in open loan but part disposition in collection--->
													<a href="/transactions/Loan.cfm?action=editLoan&transaction_id=#partonloan.transaction_id#">#partonloan.loan_number# (#partonloan.loan_status#)</a>
												</cfif>
											</cfloop>
										</cfif>
										<cfif deaccessionList.recordcount GT 0 AND manageTransactions IS "1">
											<!--- look up whether this part has been deaccessioned --->
											<cfquery name="partdeacc" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
												SELECT
													deacc_number, deacc_type, deaccession.transaction_id
												FROM 
													specimen_part 
													JOIN deacc_item on specimen_part.collection_object_id = deacc_item.collection_object_id
													JOIN deaccession on deacc_item.transaction_id = deaccession.transaction_id
												WHERE
													specimen_part.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#mainParts.part_id#">
											</cfquery>
											<cfif partdeacc.recordcount GT 0>
												<cfif deaccessionList.recordcount EQ mainParts.recordcount>
													<!--- just mark all parts as deaccessioned, deaccession number will be in Transaction section --->
													<span class="d-block small mb-0 pb-0">In Deaccession.</span>
												<cfelse>
													<!--- when not all parts have been deaccessioned, link to the deaccession --->
													<span class="d-block small mb-0 pb-0">In Deacc:
														<cfloop query="partdeacc">
															<a href="/transactions/Deaccession.cfm?action=edit&transaction_id=#partdeacc.transaction_id#">#partdeacc.deacc_number#</a> (#partdeacc.deacc_type#)
														</cfloop>
													</span>
												</cfif>
											</cfif>
										</cfif>
									</td>
									<td class="py-1">#lot_count#</td>
								
									<cfif oneOfus is "1">
										<td class="pb-0">#label#</td>
									</cfif>
									<td class="py-1">
										<span class="small mb-0 pb-0">
											<a href="javascript:void(0)" aria-label="Condition/Preparation History"
												onClick=" openHistoryDialog(#mainParts.part_id#, 'historyDialog#mainParts.part_id#');">History#histCount#</a>
										</span>
									</td>
								</tr>
								<cfif len(part_remarks) gt 0>
									<tr class="small90">
										<td colspan="6" class="mb-0 pb-1 pt-0">
											<span class="pl-3 d-block"><span class="font-italic">Remarks:</span> #part_remarks#</span>
										</td>
									</tr>
								</cfif>
								<!--- for each part list the part attributes --->
								<cfquery name="partAttributes" dbtype="query">
									SELECT
										attribute_type,
										attribute_value,
										attribute_units,
										determined_date,
										attribute_remark,
										agent_name,
										agent_id,
										agentguid,
										agentguid_guid_type
									FROM
										getParts
									WHERE
										attribute_type is not null and
										part_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#mainParts.part_id#">
									GROUP BY
										attribute_type,
										attribute_value,
										attribute_units,
										determined_date,
										attribute_remark,
										agent_name,
										agent_id,
										agentguid,
										agentguid_guid_type
								</cfquery>
								<cfif partAttributes.recordcount gt 0>
									<tr class="border-top-0">
										<td colspan="6" class="border-top-0 mt-0 py-0">
											<cfloop query="partAttributes">
												<div class="small90 pl-3 line-height-sm">
													#attribute_type#=<span class="">#attribute_value#</span> &nbsp;
												<cfif len(attribute_units) gt 0>
													#attribute_units# &nbsp;
												</cfif>
												<cfif len(determined_date) gt 0>
													determined date=<span class="">#dateformat(determined_date,"yyyy-mm-dd")#</span> &nbsp;
												</cfif>
												<cfif len(agent_name) gt 0>
													<cfif #agent_id# NEQ "0">
														<cfset agentLinkOut = "">
														<cfif len(agentguid) GT 0>
															<cfset agentLinkOut = getGuidLink(guid=#agentguid#,guid_type=#agentguid_guid_type#)>
														</cfif>
														<cfset attDeterminer="<a href='/agents/Agent.cfm?agent_id=#agent_id#'>#agent_name#</a>#agentLinkOut#"> <!--- " --->
													<cfelse>
														<cfset attDeterminer="#agent_name#">
													</cfif>
													determined by=<span class="">#attDeterminer#</span> &nbsp;
												</cfif>
												<cfif len(attribute_remark) gt 0>
													remark=<span class="">#attribute_remark#</span> &nbsp;
												</cfif>
												</div>
											</cfloop>
										</td>
									</tr>
								</cfif>
								<!--- iterate through the subsampled parts for each part --->
								<cfquery name="subsampleParts" dbtype="query">
									select * from distinctParts where sampled_from_obj_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#mainParts.part_id#">
								</cfquery>
								<cfloop query="subsampleParts">
									<cfquery name="historyCount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
										SELECT sum(cti) ct from (
											SELECT count(*) cti 
											FROM object_condition 
											WHERE
												collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#subsampleParts.part_id#">
											UNION
											SELECT count(*) cti
											FROM specimen_part_pres_hist
											WHERE
												collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#subsampleParts.part_id#">
										)
									</cfquery>
									<cfif historyCount.ct GT 2><cfset histCount = " (#historyCount.ct#)"><cfelse><cfset histCount = ""></cfif>
									<div id="historyDialog#subsampleParts.part_id#"></div>
									<tr>
										<td class="py-1">
											<span class="d-inline-block pl-3">
											<span class="font-weight-bold " style="font-size: 17px;">&##172;</span> 
											<span class="font-italic">Subsample:</span> #part_name#</span>
										</td>
										<td class="py-1">
											#part_condition#
											
										</td>
										<td class="py-1">
											#part_disposition#
											<cfif loanList.recordcount GT 0 AND manageTransactions IS "1">
												<!--- look up whether this part is in an open loan --->
												<cfquery name="partonloan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
													SELECT
														loan_number, loan_type, loan_status, loan.transaction_id, item_descr, loan_item_remarks
													FROM 
														specimen_part 
														LEFT JOIN loan_item on specimen_part.collection_object_id = loan_item.collection_object_id
														LEFT JOIN loan on loan_item.transaction_id = loan.transaction_id
													WHERE
														specimen_part.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#subsampleParts.part_id#">
														and loan_status <> 'closed'
												</cfquery>
												<cfloop query="partonloan">
													<cfif partonloan.loan_status EQ 'open' and subsampleParts.part_disposition EQ 'on loan'>
														<!--- normal case --->
														<a href="/transactions/Loan.cfm?action=editLoan&transaction_id=#partonloan.transaction_id#">#partonloan.loan_number#</a>
													<cfelse>
														<!--- partial returns, in process, historical, in-house, or in open loan but part disposition in collection--->
														<a href="/transactions/Loan.cfm?action=editLoan&transaction_id=#partonloan.transaction_id#">#partonloan.loan_number# (#partonloan.loan_status#)</a>
													</cfif>
												</cfloop>
											</cfif>
											<cfif deaccessionList.recordcount GT 0 AND manageTransactions IS "1">
												<!--- look up whether this part has been deaccessioned --->
												<cfquery name="partdeacc" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
													SELECT
														deacc_number, deacc_type, deaccession.transaction_id
													FROM 
														specimen_part 
														JOIN deacc_item on specimen_part.collection_object_id = deacc_item.collection_object_id
														JOIN deaccession on deacc_item.transaction_id = deaccession.transaction_id
													WHERE
														specimen_part.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#subsampleParts.part_id#">
												</cfquery>
												<cfif partdeacc.recordcount>
													<cfif deaccessionList.recordcount EQ mainParts.recordcount>
														<!--- just mark all parts as deaccessioned, deaccession number will be in Transaction section --->
														<span class="d-block small mb-0 pb-0">In Deaccession</span>
													<cfelse>
														<!--- when not all parts have been deaccessioned, link to the deaccession --->
														<span class="d-block small mb-0 pb-0">Deacc:
															<cfloop query="partdeacc">
																<a href="/transactions/Deaccession.cfm?action=edit&transaction_id=#partdeacc.transaction_id#">#partdeacc.deacc_number#</a> (#partdeacc.deacc_type#)
															</cfloop>
														</span>
													</cfif>
												</cfif>
											</cfif>
										</td>
										
										<td class="py-1">#lot_count#</td>
										<cfif oneOfus is "1">
											<td class="py-1">#label#</td>
										</cfif>
										<td class="py-1">
											<span class="small mb-0 pb-0">
												<a href="javascript:void(0)" aria-label="Condition/Preparation History"
													onClick=" openHistoryDialog(#subsampleParts.part_id#, 'historyDialog#subsampleParts.part_id#');">History#histCount#</a>
											</span>
										</td>
									</tr>
									<cfif len(part_remarks) gt 0>
										<tr class="small90">
											<td colspan="6" class="pt-1">
												<span class="pl-3 d-block pb-1">
													<span class="font-italic">Remarks:</span> #part_remarks#
												</span>
											</td>
										</tr>
									</cfif>
									<!--- for each subsample part list any part attributes --->
									<cfquery name="partAttributes" dbtype="query">
										SELECT
											attribute_type,
											attribute_value,
											attribute_units,
											determined_date,
											attribute_remark,
											agent_name,
											agent_id,
											agentguid,
											agentguid_guid_type
										FROM
											getParts
										WHERE
											attribute_type is not null and
											part_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#subsampleParts.part_id#">
										GROUP BY
											attribute_type,
											attribute_value,
											attribute_units,
											determined_date,
											attribute_remark,
											agent_name,
											agent_id,
											agentguid,
											agentguid_guid_type
									</cfquery>
									<cfif partAttributes.recordcount gt 0>
										<tr class="border-top-0">
											<td colspan="6" class="border-top-0 mt-0 pb-2 pt-1">
												<cfloop query="partAttributes">
													<div class="small90 pl-3 pb-2 line-height-sm">
														#attribute_type#=<span class="">#attribute_value#</span> &nbsp;
													<cfif len(attribute_units) gt 0>
														#attribute_units# &nbsp;
													</cfif>
													<cfif len(determined_date) gt 0>
														determined date=<span class="">#dateformat(determined_date,"yyyy-mm-dd")#</span> &nbsp;
													</cfif>
													<cfif len(agent_name) gt 0>
														<cfif #agent_id# NEQ "0">
															<cfset agentLinkOut = "">
															<cfif len(agentguid) GT 0>
																<cfset agentLinkOut = getGuidLink(guid=#agentguid#,guid_type=#agentguid_guid_type#)>
															</cfif>
															<cfset attDeterminer="<a href='/agents/Agent.cfm?agent_id=#agent_id#'>#agent_name#</a>#agentLinkOut#"> <!--- " --->
														<cfelse>
															<cfset attDeterminer="#agent_name#">
														</cfif>
														determined by=<span class="">#attDeterminer#</span> &nbsp;
													</cfif>
													<cfif len(attribute_remark) gt 0>
														remark=<span class="f">#attribute_remark#</span> &nbsp;
													</cfif>
													</div>
												</cfloop>
											</td>
										</tr>
									</cfif>
								</cfloop><!--- subsamples --->
		
							</cfloop><!--- parts --->
						</tbody>
					</table>
				</cfif>
			<cfcatch>
				<cfset error_message = cfcatchToErrorMessage(cfcatch)>
				<cfset function_called = "#GetFunctionCalledName()#">
				<h2 class='h3'>Error in #function_called#:</h2>
				<div>#error_message#</div>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="getPartsThread"/>
	<cfreturn getPartsThread.output>
</cffunction>

<!--- getPartCount obtain the number of parts for a cataloged item 
  @param collection_object_id the collection_object_id for the cataloged item for which to return a part count 
  @return a json structure containg the part count in ct
--->
<cffunction name="getPartCount" access="remote" returntype="any" returnformat="json">
	<cfargument name="collection_object_id" type="string" required="yes">

	<cfset data = ArrayNew(1)>
	<cftry>
		<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
			<cfset oneOfUs = 1>
		<cfelse>
			<cfset oneOfUs = 0>
		</cfif>
		<!--- check for mask record, hide if mask record and not one of us ---->
		<cfquery name="check" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			SELECT 
				concatEncumbranceDetails(<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">) encumbranceDetail
			FROM DUAL
		</cfquery>
		<cfif oneOfUs EQ 0 AND Findnocase("mask record", check.encumbranceDetail)>
			<cfthrow message="Record Masked">
		</cfif>
		<cfquery name="countParts" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			SELECT
				count(specimen_part.collection_object_id) ct
			FROM
				specimen_part
			WHERE
				specimen_part.derived_from_cat_item = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#"> 
		</cfquery>
		<cfset i = 1>
		<cfloop query="countParts">
			<cfset row = StructNew()>
			<cfif oneofus EQ 0 AND Findnocase("mask parts", check.encumbranceDetail)>
				<cfset row["ct"] = "">
			<cfelse>
				<cfset row["ct"] = "#countParts.ct#">
			</cfif>
			<cfset data[i]  = row>
			<cfset i = i + 1>
		</cfloop>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn #serializeJSON(data)#>
</cffunction>
						
<cffunction name="getAttributesHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="collection_object_id" type="string" required="yes">

	<cfthread name="getAttributesThread">
		<cfoutput>
			<cftry>
				<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
					<cfset oneOfUs = 1>
				<cfelse>
					<cfset oneOfUs = 0>
				</cfif>
				<!--- check for mask record, hide if mask record ---->
				<cfquery name="check" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT 
						concatEncumbranceDetails(<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">) encumbranceDetail
					FROM DUAL
				</cfquery>
				<cfif oneOfUs EQ 0 AND Findnocase("mask record", check.encumbranceDetail)>
					<cfthrow message="Record Masked">
				</cfif>
				<cfquery name="attributes" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT distinct
						attributes.attribute_type,
						ctattribute_type.description as attribute_description,
						attributes.attribute_value,
						attributes.attribute_units,
						attributes.attribute_remark,
						attributes.determination_method,
						attributes.determined_date,
						attribute_determiner.agent_name attributeDeterminer,
						attribute_determiner.agent_id attributeDeterminer_agent_id
					FROM
						attributes
						left join preferred_agent_name attribute_determiner on attributes.determined_by_agent_id = attribute_determiner.agent_id
						LEFT JOIN ctattribute_type on attributes.attribute_type = ctattribute_type.attribute_type 
						LEFT JOIN cataloged_item on attributes.collection_object_id = cataloged_item.collection_object_id
					WHERE
						attributes.collection_object_id = <cfqueryparam value="#collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
						AND (cataloged_item.collection_cde = ctattribute_type.collection_cde OR ctattribute_type.collection_cde is null)
					ORDER BY
						decode(attribute_type,'sex',0,1), attribute_type
				</cfquery>
				<cfif attributes.recordcount GT 0>
					<table class="table px-1 table-responsive-md w-100 tablesection my-1" aria-label="attributes">
						<thead class="thead-light">
							<tr>
								<th class="py-0">Attribute</th>
								<th class="py-0">Value</th>
								<th class="py-0">Determination</th>
								<th class="py-0" style="min-width: 93px;">On</th>
							</tr>
						</thead>
						<tbody class="bg-white">
						<cfloop query="attributes">
							<tr <cfif attributes.recordcount gt 1>class="line-top-sd"<cfelse></cfif>>
								<td><span class="font-weight-lessbold" title="#attribute_description#">#attribute_type#</span></td>
								<td>
									#attribute_value#
									<cfif len(attribute_units) gt 0>
										#attribute_units#
									</cfif>
								</td>
								<cfset determination = "">
								<cfif len(attributeDeterminer) gt 0>
									<cfif attributeDeterminer_agent_id EQ "0">
										<cfset determination ="#attributeDeterminer#">
									<cfelse>
										<cfset determination ="<span class='d-inline font-weight-lessbold'>By: </span> <a href='/agents/Agent.cfm?agent_id=#attributeDeterminer_agent_id#'>#attributeDeterminer#</a>">
									</cfif>
									<cfif len(determination_method) gt 0>
										<cfset determination = " <span class='d-inline'>#determination#</span>, <span class='d-inline font-weight-lessbold'>Method: </span> #determination_method#">
									</cfif>
								</cfif>
								<td>#determination#</td>
								<td>
									<cfif len(determined_date) gt 0>#dateformat(determined_date,'yyyy-mm-dd')#</cfif>
								</td>
							</tr>
							<cfif len(attribute_remark)gt 0>
								<tr>
									<td colspan="1"></td>
									<td colspan="3"><span class="inputHeight d-inline-block pb-1"><em>Remarks:</em> #attribute_remark#</span></td>
								</tr>
							</cfif>
						</cfloop>
						</tbody>
					</table>
				</cfif>
			<cfcatch>
				<cfset error_message = cfcatchToErrorMessage(cfcatch)>
				<cfset function_called = "#GetFunctionCalledName()#">
				<h2 class='h3'>Error in #function_called#:</h2>
				<div>#error_message#</div>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="getAttributesThread" />
	<cfreturn getAttributesThread.output>
</cffunction>			
						
<!--- getRelationsHTML get a block of html containing relationships of a cataloged item record to
  other cataloged items.  
 @param collection_object_id for the cataloged item for which to return relationships
 @return a block of html with cataloged item record relationships, or if none, html with the word None.
--->
<cffunction name="getRelationsHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="collection_object_id" type="string" required="yes">

	<cfthread name="getRelationsThread">
		<cfoutput>
			<cftry>
				<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
					<cfset oneOfUs = 1>
				<cfelse>
					<cfset oneOfUs = 0>
				</cfif>
				<!--- check for mask record, hide if mask record ---->
				<cfquery name="check" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT 
						concatEncumbranceDetails(<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">) encumbranceDetail
					FROM DUAL
				</cfquery>
				<cfif oneOfUs EQ 0 AND Findnocase("mask record", check.encumbranceDetail)>
					<cfthrow message="Record Masked">
				</cfif>
				<!--- Use appropriate data source to allow access to relationships to records in other VPDs ---->
				<cfif oneOfUs EQ 1>
					<!--- if coldfusion_user, then the VPD may be involved and all cataloged items may not be visible, use a user that can see relationships across VPDs --->
					<cfquery name="relns" datasource="cf_dbuser">
						SELECT 
							distinct biol_indiv_relationship, related_coll_cde, related_collection, 
							related_coll_object_id, related_cat_num, biol_indiv_relation_remarks 
						FROM 
							(
							SELECT
								rel.biol_indiv_relationship as biol_indiv_relationship,
								collection as related_collection,
								rel.collection.collection_cde as related_coll_cde,
								rel.related_coll_object_id as related_coll_object_id,
								rcat.cat_num as related_cat_num,
								rel.biol_indiv_relation_remarks as biol_indiv_relation_remarks
							FROM
								biol_indiv_relations rel
								left join cataloged_item rcat on rel.related_coll_object_id = rcat.collection_object_id
								left join collection on collection.collection_id = rcat.collection_id
								left join ctbiol_relations ctrel on rel.biol_indiv_relationship = ctrel.biol_indiv_relationship
							WHERE rel.collection_object_id = <cfqueryparam value="#collection_object_id#" cfsqltype="CF_SQL_DECIMAL"> 
								and ctrel.rel_type <> 'functional'
							UNION
							SELECT
								ctrel.inverse_relation as biol_indiv_relationship,
								collection as related_collection,
								ctrel.collection.collection_cde as related_coll_cde,
								irel.collection_object_id as related_coll_object_id,
								rcat.cat_num as related_cat_num,
								irel.biol_indiv_relation_remarks as biol_indiv_relation_remarks
							FROM
								biol_indiv_relations irel
								left join ctbiol_relations ctrel on irel.biol_indiv_relationship = ctrel.biol_indiv_relationship
								left join cataloged_item rcat on irel.collection_object_id = rcat.collection_object_id
								left join collection on collection.collection_id = rcat.collection_id
							WHERE irel.related_coll_object_id = <cfqueryparam value="#collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
								 and ctrel.rel_type <> 'functional'
							)
						ORDER BY 
							related_cat_num
					</cfquery>
				<cfelse>
					<cfquery name="relns" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						SELECT 
							distinct biol_indiv_relationship, related_coll_cde, related_collection, 
							related_coll_object_id, related_cat_num, biol_indiv_relation_remarks 
						FROM 
							(
							SELECT
								rel.biol_indiv_relationship as biol_indiv_relationship,
								collection as related_collection,
								rel.collection.collection_cde as related_coll_cde,
								rel.related_coll_object_id as related_coll_object_id,
								rcat.cat_num as related_cat_num,
								rel.biol_indiv_relation_remarks as biol_indiv_relation_remarks
							FROM
								biol_indiv_relations rel
								left join cataloged_item rcat on rel.related_coll_object_id = rcat.collection_object_id
								left join collection on collection.collection_id = rcat.collection_id
								left join ctbiol_relations ctrel on rel.biol_indiv_relationship = ctrel.biol_indiv_relationship
							WHERE rel.collection_object_id = <cfqueryparam value="#collection_object_id#" cfsqltype="CF_SQL_DECIMAL"> 
								and ctrel.rel_type <> 'functional'
							UNION
							SELECT
								ctrel.inverse_relation as biol_indiv_relationship,
								collection as related_collection,
								ctrel.collection.collection_cde as related_coll_cde,
								irel.collection_object_id as related_coll_object_id,
								rcat.cat_num as related_cat_num,
								irel.biol_indiv_relation_remarks as biol_indiv_relation_remarks
							FROM
								biol_indiv_relations irel
								left join ctbiol_relations ctrel on irel.biol_indiv_relationship = ctrel.biol_indiv_relationship
								left join cataloged_item rcat on irel.collection_object_id = rcat.collection_object_id
								left join collection on collection.collection_id = rcat.collection_id
							WHERE irel.related_coll_object_id = <cfqueryparam value="#collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
								 and ctrel.rel_type <> 'functional'
							)
						ORDER BY 
							related_cat_num
					</cfquery>
				</cfif>
				<cfif len(relns.biol_indiv_relationship) gt 0 >
					<ul class="list-group">
						<cfloop query="relns">
							<li class="list-group-item pt-0 pb-1"><span class="text-capitalize">#biol_indiv_relationship#</span> 
								<a href="/Specimens.cfm?execute=true&action=fixedSearch&collection=#relns.related_coll_cde#&cat_num=#relns.related_cat_num#">
									#related_collection# #related_cat_num# 
								</a>
								<cfif len(relns.biol_indiv_relation_remarks) gt 0>
									(Remark: #biol_indiv_relation_remarks#)
								</cfif>
							</li>
						</cfloop>
						<cfquery name="lookupGuid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="named_groups">
							SELECT flat.guid
							FROM
								<cfif ucase(session.flatTableName) EQ "FLAT"> flat <cfelse> filtered_flat </cfif> flat
							WHERE
								flat.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
						</cfquery>
						<li class="pb-1 pt-0 list-group-item">
							<a href="/Specimens.cfm?execute=true&builderMaxRows=1&action=builderSearch&nestdepth1=0&field1=BIOL_INDIV_RELATIONS%3ARELATED_COLL_OBJECT_ID&searchText1=#lookupGuid.guid#&searchId1=#collection_object_id#">List of Related Specimens</a>
						</li>
					</ul>
				<cfelse>
					<ul class="pl-0 list-group my-0">
						<li class="small list-group-item py-0 font-italic">None</li>
					</ul>
				</cfif>
			<cfcatch>
				<cfset error_message = cfcatchToErrorMessage(cfcatch)>
				<cfset function_called = "#GetFunctionCalledName()#">
				<h2 class='h3'>Error in #function_called#:</h2>
				<div>#error_message#</div>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="getRelationsThread"/>
	<cfreturn getRelationsThread.output>
</cffunction>

<!--- getTransactionsHTML get a block of html containing information about transactions for a cataloged
  item suitable to the current user's access rights.
 @param collection_object_id for the cataloged item for which to return transaction information
 @return a block of html with transactions information, or if none are visible, html with the word Masked.
--->
<cffunction name="getTransactionsHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="collection_object_id" type="string" required="yes">

	<cfthread name="getTransactionsThread">
		<cfoutput>
			<cftry>
				<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_transactions")>
					<cfset oneOfUs = 1>
				<cfelse>
					<cfset oneOfUs = 0>
				</cfif>
	
				<cfset hasContent = false>
				<ul class="list-group pl-0">
					<!--- Accession for the cataloged item, display internally only --->
					<cfif oneOfUs is 1>
						<cfquery name="checkAccn" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							SELECT
								decode(trans.transaction_id, null, 0, 1) accnVpdVisible
							FROM
								cataloged_item
								left join accn on cataloged_item.accn_id = accn.transaction_id
								left join trans on accn.transaction_id = trans.transaction_id
							WHERE 
								cataloged_item.collection_object_id = <cfqueryparam value="#collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
						</cfquery>
						<cfif checkAccn.accnVpdVisible EQ 1>
							<cfquery name="lookupAccn" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
								SELECT
									cataloged_item.accn_id,
									cataloged_item.collection_cde catitem_coll_cde,
									accn.accn_number,
									accn_type,
									accn_status,
									to_char(received_date,'yyyy-mm-dd') received_date,
									concattransagent(trans.transaction_id,'received from') received_from
								FROM
									cataloged_item
									left join accn on cataloged_item.accn_id =  accn.transaction_id
									left join trans on accn.transaction_id = trans.transaction_id
								WHERE
									cataloged_item.collection_object_id = <cfqueryparam value="#collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
							</cfquery>
						<cfelse>
							<!--- internal user may be constrained by a VPD, use a datasource that can look accross VPDs to get the accession number --->
							<cfquery name="lookupAccn" datasource="cf_dbuser">
								SELECT
									'' as accn_id,
									cataloged_item.collection_cde catitem_coll_cde,
									accn.accn_number,
									'' as accn_type,
									'' as accn_status,
									'' as received_date,
									'' as received_from
								FROM
									cataloged_item
									left join accn on cataloged_item.accn_id =  accn.transaction_id
									left join trans on accn.transaction_id = trans.transaction_id
								WHERE
									cataloged_item.collection_object_id = <cfqueryparam value="#collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
							</cfquery>
						</cfif>
						<cfquery name="accnLimitations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							select specific_type, restriction_summary 
							from  permit_trans 
								left join permit on permit_trans.permit_id = permit.permit_id
							where 
								permit_trans.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#lookupAccn.accn_id#">
								and permit.restriction_summary IS NOT NULL
						</cfquery>
						<cfquery name="accnCollection" datasource="cf_dbuser">
							SELECT collection_cde
							from trans 
								left join collection on trans.collection_id = collection.collection_id
							WHERE
								trans.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#lookupAccn.accn_id#">
					  	</cfquery>
						<cfset accnDept = "">
						<cfif NOT lookupAccn.catitem_coll_cde IS accnCollection.collection_cde>
							<!--- accession is in a different department than the cataloged item --->
							<cfset accnDept = "(#accnCollection.collection_cde#)">
						</cfif>
						<cfquery name="accnMedia" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" >
							SELECT 
								media.media_id,
								media.media_uri,
								media.mime_type,
								media.media_type,
								media.preview_uri,
								label_value descr 
							FROM 
								media
								left join media_relations on media.media_id=media_relations.media_id
								left join (select media_id,label_value from media_labels where media_label='description') media_labels on media.media_id=media_labels.media_id 
							WHERE 
								media_relations.media_relationship like '% accn' and
								media_relations.related_primary_key = <cfqueryparam value="#collection_object_id#" cfsqltype="CF_SQL_DECIMAL"> and
								MCZBASE.is_media_encumbered(media.media_id) < 1
						</cfquery>
						<cfset hasContent = true>
						<li class="list-group-item pt-0"><span class="font-weight-lessbold mb-0 d-inline-block">Accession:</span>
							<cfif len(lookupAccn.accn_id) GT 0>
								<a href="/transactions/Accession.cfm?action=edit&transaction_id=#lookupAccn.accn_id#">#lookupAccn.accn_number#</a>
								#lookupAccn.accn_type# (#lookupAccn.accn_status#) Received: #lookupAccn.received_date# From: #lookupAccn.received_from#
							<cfelse>
								#lookupAccn.accn_number#
							</cfif>
							<cfif accnMedia.recordcount gt 0>
								<cfloop query="accnMedia">
									<div class="col-12 px-1 col-lg-6 col-xl-4 mb-1 px-md-1 pt-1 float-left"> 
										<div id='accMediaBlock#accnMedia.media_id#'>
											<cfset mediaBlock= getMediaBlockHtmlUnthreaded(media_id="#accnMedia.media_id#",size="350",captionAs="textCaption")>
										</div>
									</div>
								</cfloop>
							</cfif>
						</li>
					</cfif>
					<!--------------------  Projects ------------------------------------>	
					<cfquery name="isProj" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						SELECT 
							project_name, project.project_id 
						FROM
							project
							join project_trans on project.project_id = project_trans.project_id
							join cataloged_item on project_trans.transaction_id = cataloged_item.accn_id
						WHERE
							cataloged_item.collection_object_id = <cfqueryparam value="#collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
						GROUP BY project_name, project.project_id
					</cfquery>
					<cfquery name="isLoan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						SELECT 
							project_name, project.project_id 
						FROM 
							loan_item
							join project_trans on loan_item.transaction_id=project_trans.transaction_id
							join project on project_trans.project_id=project.project_id
							join specimen_part on specimen_part.collection_object_id = loan_item.collection_object_id
						WHERE 
							specimen_part.derived_from_cat_item = <cfqueryparam value="#collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
						GROUP BY 
							project_name, project.project_id
					</cfquery>
					<cfif isProj.project_name gt 0>
						<cfset hasContent = true>
						<cfloop query="isProj">
							<li class="list-group-item pt-0">
								<span class="mb-0 d-inline-block font-weight-lessbold">Contributed By Project:</span>
								<a href="/project/#project_name#">#isProj.project_name#</a>
							</li>
						</cfloop>
					</cfif>
					<cfif isLoan.project_name gt 0>
						<cfset hasContent = true>
						<cfloop query="isLoan">
							<li class="list-group-item pt-0">
								<span class="mb-0 d-inline-block font-weight-lessbold">Used By Project:</span> 
								<a href="/project/#project_name#" target="_mainFrame">#isLoan.project_name#</a> 
							</li>
						</cfloop>
					</cfif>
					<!--- Usage ---->
					<cfif oneOfUs IS 1>
						<cfquery name="isLoanedItem" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							SELECT 
								loan_item.collection_object_id 
							FROM 
								loan_item
								join specimen_part on loan_item.collection_object_id=specimen_part.collection_object_id
							WHERE 
								specimen_part.derived_from_cat_item = <cfqueryparam value="#collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
						</cfquery>
						<cfquery name="loanList" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							SELECT 
								distinct loan_number, loan_type, loan_status, loan.transaction_id 
							FROM
								specimen_part 
								join loan_item on specimen_part.collection_object_id=loan_item.collection_object_id
								join loan on loan_item.transaction_id = loan.transaction_id
							WHERE
								loan_number is not null AND
								specimen_part.derived_from_cat_item = <cfqueryparam value="#collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
						</cfquery>
						<cfquery name="isDeaccessionedItem" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							SELECT 
								deacc_item.collection_object_id 
							FROM
								specimen_part 
								join deacc_item on specimen_part.collection_object_id=deacc_item.collection_object_id
							WHERE
								specimen_part.derived_from_cat_item = <cfqueryparam value="#collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
						</cfquery>
						<cfquery name="deaccessionList" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							SELECT 
								distinct deacc_number, deacc_type, deaccession.transaction_id 
							FROM
								specimen_part 
								join deacc_item on specimen_part.collection_object_id=deacc_item.collection_object_id
								join deaccession on deacc_item.transaction_id = deaccession.transaction_id
							WHERE
								deacc_number is not null AND
								specimen_part.derived_from_cat_item = <cfqueryparam value="#collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
						</cfquery>
						<cfif isLoanedItem.collection_object_id gt 0 and oneOfUs is 1>
							<cfset hasContent = true>
							<li class="list-group-item pt-0">
								<span class="font-weight-lessbold mb-0 d-inline-block float-left pr-1">Loan History:</span>
								<a class="d-inline-block" href="/Loan.cfm?action=listLoans&collection_object_id=#valuelist(isLoanedItem.collection_object_id)#" target="_mainFrame">Loans that include this cataloged item (#loanList.recordcount#).</a>
								<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_transactions")>
									<cfloop query="loanList">
										<ul class="d-block">
											<li class="d-block">#loanList.loan_number# (#loanList.loan_type# #loanList.loan_status#)</li>
										</ul>
									</cfloop>
								</cfif>
							</li>
						</cfif>
						<cfif isDeaccessionedItem.collection_object_id gt 0 and oneOfUs is 1>
							<cfset hasContent = true>
							<li class="list-group-item">
								<span class="font-weight-lessbold mb-1 d-inline-block float-left">Deaccessions: </span>
								<a href="/Deaccession.cfm?action=listDeacc&collection_object_id=#valuelist(isDeaccessionedItem.collection_object_id)#" target="_mainFrame">Deaccessions that include parts from cataloged item (#deaccessionList.recordcount#).</a> &nbsp;
								<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_transactions")>
									<cfloop query="deaccessionList">
										<ul class="d-block">
											<li class="d-block"> <a href="/Deaccession.cfm?action=editDeacc&transaction_id=#deaccessionList.transaction_id#">#deaccessionList.deacc_number# (#deaccessionList.deacc_type#)</a></li>
										</ul>
									</cfloop>
								</cfif>
							</li>
						</cfif>
					<cfelse>
						<cfquery name="deaccessionCount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							SELECT
								count(specimen_part.collection_object_id) parts,
								count(deacc_item.collection_object_id) deaccessionedParts
							FROM
								specimen_part 
								join deacc_item on specimen_part.collection_object_id=deacc_item.collection_object_id
							WHERE
								specimen_part.derived_from_cat_item = <cfqueryparam value="#collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
							GROUP BY
								specimen_part.derived_from_cat_item
						</cfquery>
						<cfif deaccessionCount.deaccessionedParts GT 0>
							<cfset hasContent = true>
							<li class="font-weight-lessbold mb-1 d-inline-block float-left pr-1">
							<cfif deaccessionCount.parts EQ deaccessionCount.deaccessionedParts>
								Deaccessioned
							<cfelse>
								Some Parts have been Deaccessioned
							</cfif>
							</li>

						</cfif>
					</cfif>
				</ul>
					<cfif NOT hasContent>
						<cfif oneOfUs IS 1>
							<ul class="list-group pl-0">
								<!--- we shoudn't actually get here, as all cataloged items have an accession --->
								<li class="small list-group-item py-0 font-italic">None</li>
							</ul>
						<cfelse>
							<ul class="list-group pl-0">
								<li class="small list-group-item py-0 font-italic">[Masked]</li>
							</ul>
						</cfif>
					</cfif>
			
			<cfcatch>
				<cfset error_message = cfcatchToErrorMessage(cfcatch)>
				<cfset function_called = "#GetFunctionCalledName()#">
				<h2 class='h3'>Error in #function_called#:</h2>
				<div>#error_message#</div>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="getTransactionsThread" />
	<cfreturn getTransactionsThread.output>
</cffunction>
						
<!--- getLocalityHTML get a block of html containing collecting event, locality, and higher
 geography information for a specified cataloged item
 @param collection_object_id for the cataloged item for which to return spatial/temporal information.
 @return a block of html with the spatial/temporal information or an error message, the case
   of no information is not handled, as the chain of foreign key constraints from cataloged item
   to geog_auth_rec all have not null constraints.
--->
<cffunction name="getLocalityHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="collection_object_id" type="string" required="yes">

	<cfthread name="getLocalityThread">
		<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
			<cfset oneOfUs = 1>
		<cfelse>
			<cfset oneOfUs = 0>
		</cfif>
		<!--- check for mask record, hide if mask record ---->
		<cfquery name="check" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			SELECT 
				concatEncumbranceDetails(<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">) encumbranceDetail
			FROM DUAL
		</cfquery>
		<cfif oneOfUs EQ 0 AND Findnocase("mask record", check.encumbranceDetail)>
			<cfthrow message="Record Masked">
		</cfif>
		<cfoutput>
			<cftry>
				<cfset maskCoordinates = false>
				<cfif oneOfUs EQ 0 AND Findnocase("mask coordinates", check.encumbranceDetail)>
					<cfset maskCoordinates = true>
				</cfif>
				<cfquery name="loc_collevent"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT
						collecting_event.collecting_event_id, 
						locality.locality_id,
						geog_auth_rec.geog_auth_rec_id,
						collecting_event.collecting_time,
						to_char(collecting_event.date_began_date,'yyyy-mm-dd') date_began_date,
						to_char(collecting_event.date_ended_date,'yyyy-mm-dd') date_ended_date,
						collecting_event.verbatim_date,
						collecting_event.began_date,
						collecting_event.ended_date,
						collecting_event.startdayofyear,
						collecting_event.enddayofyear,
						<cfif maskCoordinates>
							'[Masked]' as verbatim_locality,
							'' as verbatimdepth,
							'' as verbatimelevation,
						<cfelse>
							collecting_event.verbatim_locality,
							collecting_event.verbatimdepth,
							collecting_event.verbatimelevation,
						</cfif>
						collecting_event.coll_event_remarks,
						collecting_event.valid_distribution_fg,
						collecting_event.collecting_source,
						collecting_event.collecting_method,
						<cfif maskCoordinates>
							'[Masked]' as  habitat_desc,
						<cfelse>
							collecting_event.habitat_desc,
						</cfif>
						MCZBASE.get_agentnameoftype(collecting_event.date_determined_by_agent_id) as date_determiner,
						collecting_event.date_determined_by_agent_id,
						collecting_event.fish_field_number,
						<cfif maskCoordinates>
							'[Masked]' as verbatimcoordinates,
							'' as verbatimlatitude,
							'' as verbatimlongitude,
							'' as verbatimsrs,
						<cfelse>
							collecting_event.verbatimcoordinates,
							collecting_event.verbatimlatitude,
							collecting_event.verbatimlongitude,
							collecting_event.verbatimsrs,
						</cfif>
						locality.maximum_elevation,
						locality.minimum_elevation,
						locality.orig_elev_units,
						<cfif maskCoordinates>
							'' as township,
							'' as township_direction,
							'' as range,
							'' as range_direction,
							'' as section,
							'' as section_part,
						<cfelse>
							locality.township,
							locality.township_direction,
							locality.range,
							locality.range_direction,
							locality.section,
							locality.section_part,
						</cfif>
						<cfif maskCoordinates>
							'[Masked]' as spec_locality,
						<cfelse>
							locality.spec_locality,
						</cfif>
						locality.locality_remarks,
						locality.legacy_spec_locality_fg,
						locality.depth_units,
						locality.min_depth,
						locality.max_depth,
						<cfif maskCoordinates>
							'' as nogeorefbecause,
							'' as georef_updated_date,
							'' as georef_by,
						<cfelse>
							locality.nogeorefbecause,
							to_char(locality.georef_updated_date,'yyyy-mm-dd') georef_updated_date,
							locality.georef_by,
						</cfif>
						locality.sovereign_nation,
						locality.curated_fg,
						geog_auth_rec.continent_ocean,
						geog_auth_rec.country,
						geog_auth_rec.state_prov,
						geog_auth_rec.county,
						geog_auth_rec.island_group,
						geog_auth_rec.island,
						geog_auth_rec.quad,
						geog_auth_rec.feature,
						geog_auth_rec.sea,
						geog_auth_rec.valid_catalog_term_fg,
						geog_auth_rec.source_authority,
						geog_auth_rec.higher_geog,
						geog_auth_rec.ocean_region,
						geog_auth_rec.ocean_subregion,
						geog_auth_rec.water_feature,
						geog_auth_rec.wkt_polygon,
						geog_auth_rec.highergeographyid_guid_type,
						geog_auth_rec.highergeographyid
					FROM cataloged_item
						join collecting_event on cataloged_item.collecting_event_id = collecting_event.collecting_event_id
						join locality on collecting_event.locality_id = locality.locality_id
						join geog_auth_rec on locality.geog_auth_rec_id = geog_auth_rec.geog_auth_rec_id
					WHERE
						collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
				</cfquery>
				<!--- field coll_object_remark.habitat is labeled microhabitat --->
				<cfquery name="microhabitatlookup"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT
						habitat
					FROM
						coll_object_remark
					WHERE	
						collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#"> 
				</cfquery>
				<cfset microhabitat = "">
				<cfset sep = "">
				<cfloop query="microhabitatlookup">
					<cfif maskCoordinates>
						<cfset microhabitat = "[Masked]">
					<cfelse>
						<cfset microhabitat = "#microhabitat##sep##microhabitatlookup.habitat#">
						<cfset sep = ";">
					</cfif>
				</cfloop>
				<cfquery name="coordlookup"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT
						<cfif maskCoordinates>
							'' as lat_long_id,
							'' as accepted_lat_long_fg,
							'[Masked]' as dec_lat,
							'[Masked]' as dec_long,
							'' as coordinate_precision,
							'' as datum,
							'' as max_error_distance,
							'' as max_error_units,
							'' as orig_lat_long_units,
							'' as lat_deg,
							'' as dec_lat_min,
							'' as lat_min,
							'' as lat_sec,
							'' as lat_dir,
							'' as long_deg,
							'' as dec_long_min,
							'' as long_min,
							'' as long_sec,
							'' as long_dir,
							'' as utm_zone,
							'' as utm_ew,
							'' as utm_ns,
							'' as lat_long_determined_by,
							'' as determined_by_agent_id,
							'' as determined_date,
							'' as lat_long_verified_by,
							'' as verified_by_agent_id,
							'' as lat_long_ref_source,
							'' as lat_long_remarks,
							'' as nearest_named_place,
							'' as lat_long_for_nnp_fg,
							'' as field_verified_fg,
							'' as extent,
							'' as gpsaccuracy,
							'' as georefmethod,
							'' as verificationstatus,
							'' as spatialfit,
							'' as geolocate_score,
							'' as geolocate_precision,
							'' as geolocate_numresults,
							'' as geolocate_parsepattern,
							'' as error_polygon,
							'' as footprint_spatialfit
						<cfelse>
							lat_long_id,
							accepted_lat_long_fg,
							to_char(dec_lat, '99' || rpad('.',nvl(coordinate_precision,5) + 1, '0')) lat, dec_lat,
							to_char(dec_long, '999' || rpad('.',nvl(coordinate_precision,5) + 1, '0')) lng, dec_long,
							coordinate_precision,
							datum,
							max_error_distance,
							max_error_units,
							orig_lat_long_units,
							lat_deg,
							dec_lat_min,
							lat_min,
							cast(lat_sec as INTEGER) lat_sec,
							lat_dir,
							long_deg,
							dec_long_min,
							long_min,
							cast(long_sec as INTEGER) long_sec,
							long_dir,
							utm_zone,
							utm_ew,
							utm_ns,
							case 
								when determined_by_agent_id is null then ''
								else MCZBASE.get_agentnameoftype(determined_by_agent_id) 
								end
							as lat_long_determined_by,
							determined_by_agent_id,
							to_char(determined_date,'yyyy-mm-dd') determined_date,
							case 
								when verified_by_agent_id is null then ''
								else MCZBASE.get_agentnameoftype(verified_by_agent_id) 
								end
							as lat_long_verified_by,
							verified_by_agent_id,
							lat_long_ref_source,
							lat_long_remarks,
							nearest_named_place,
							lat_long_for_nnp_fg,
							field_verified_fg,
							to_meters(extent, nvl(extent_units,'km')) extent,
							gpsaccuracy,
							georefmethod,
							verificationstatus,
							spatialfit,
							geolocate_score,
							geolocate_precision,
							geolocate_numresults,
							geolocate_parsepattern,
							error_polygon,
							footprint_spatialfit
						</cfif>
					FROM
						lat_long
					WHERE
						locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#loc_collevent.locality_id#">
						<cfif maskCoordinates>
							and rownum < 2
						</cfif>
					ORDER BY
						accepted_lat_long_fg desc, determined_date asc
				</cfquery>
				<cfquery name="geology" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT 
						geology_attributes.geology_attribute,
						geo_att_value,
						geo_att_determiner_id,
						case 
							when geo_att_determiner_id is null then '[No Agent]'
							else MCZBASE.get_agentnameoftype(geo_att_determiner_id) 
							end
						as determiner,
						to_char(geo_att_determined_date,'yyyy-mm-dd') geo_att_determined_date,
						geo_att_determined_method,
						geo_att_remark,
						previous_values
					FROM
						geology_attributes
						left join ctgeology_attributes on geology_attributes.geology_attribute = ctgeology_attributes.geology_attribute
					WHERE
						locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#loc_collevent.locality_id#">
					ORDER BY
						ctgeology_attributes.type, ctgeology_attributes.ordinal
				</cfquery>
				<cfif len(coordlookup.dec_lat) gt 0 and len(coordlookup.dec_long) gt 0 AND coordlookup.dec_lat NEQ "[Masked]">
					<!--- include map --->
					<cfset leftOfMapClass = "col-12 col-md-7">
					<script>
						jQuery(document).ready(function() {
							localityMapSetup();
						});
					</script>
					<div class="col-12 col-md-5 pl-md-0 mb-1 float-right">
						<cfset coordinates="#coordlookup.dec_lat#,#coordlookup.dec_long#">
						<!--- coordinates_* referenced in localityMapSetup --->
						<input type="hidden" id="coordinates_#loc_collevent.locality_id#" value="#coordinates#">
						<input type="hidden" id="error_#loc_collevent.locality_id#" value="1196">
						<div id="mapdiv_#loc_collevent.locality_id#" class="tinymap" style="width:100%;height:180px;" aria-label="Google Map of specimen collection location"></div>
					</div>
				<cfelse>
					<cfset leftOfMapClass = "col-12">
				</cfif>
				<div class="#leftOfMapClass# px-0 float-left">
					<ul class="sd list-unstyled row mx-0 px-2 py-1 mb-0">
						<cfif len(loc_collevent.continent_ocean) gt 0>
							<cfif find('Ocean',loc_collevent.continent_ocean) GT 0><cfset colabel="Ocean"><cfelse><cfset colabel="Continent"></cfif>
							<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold">#colabel#:</li>
							<li class="list-group-item col-7 col-xl-8 px-0">#loc_collevent.continent_ocean#</li>
						</cfif>
						<cfif len(loc_collevent.ocean_region) gt 0>
							<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold">Ocean Region:</li>
							<li class="list-group-item col-7 col-xl-8 px-0">#loc_collevent.ocean_region#</li>
						</cfif>
						<cfif len(loc_collevent.ocean_subregion) gt 0>
							<li class="list-group-item col-5 px-0 font-weight-lessbold">Ocean Subregion:</li>
							<li class="list-group-item col-7 px-0">#loc_collevent.ocean_subregion#</li>
						</cfif>
						<cfif len(loc_collevent.sea) gt 0>
							<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold">Sea:</li>
							<li class="list-group-item col-7 col-xl-8 px-0">#loc_collevent.sea#</li>
						</cfif>
						<cfif len(loc_collevent.water_feature) gt 0>
							<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold"><em>Water Feature:</em></li>
							<li class="list-group-item col-7 col-xl-8 px-0">#loc_collevent.water_feature#</li>
						</cfif>
						<cfif len(loc_collevent.country) gt 0>
							<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold">Country:</li>
							<li class="list-group-item col-7 col-xl-8 px-0">#loc_collevent.country#</li>
						</cfif>
						<cfif len(loc_collevent.state_prov) gt 0>
							<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold">State/Province:</li>
							<li class="list-group-item col-7 col-xl-8 px-0">#loc_collevent.state_prov#</li>
						</cfif>
						<cfif len(loc_collevent.feature) gt 0>
							<li class="list-group-item col-5 col-xl-4 col-xl-4 px-0 font-weight-lessbold">Feature:</li>
							<li class="list-group-item col-7 col-xl-8 px-0">#loc_collevent.feature#</li>
						</cfif>
						<cfif len(loc_collevent.county) gt 0>
							<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold"><em>County:</em></li>
							<li class="list-group-item col-7 col-xl-8 px-0">#loc_collevent.county#</li>
						</cfif>
						<cfif len(loc_collevent.island_group) gt 0>
							<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold">Island Group:</li>
							<li class="list-group-item col-7 col-xl-8 px-0">#loc_collevent.island_group#</li>
						</cfif>
						<cfif len(loc_collevent.island) gt 0>
							<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold">Island:</li>
							<li class="list-group-item col-7 col-xl-8 px-0">#loc_collevent.island#</li>
						</cfif>
						<cfif len(loc_collevent.quad) gt 0>
							<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold">Quad:</li>
							<li class="list-group-item col-7 col-xl-8 px-0">#loc_collevent.quad#</li>
						</cfif>
						<cfif loc_collevent.country NEQ loc_collevent.sovereign_nation AND len(loc_collevent.sovereign_nation) GT 0 >
							<cfif loc_collevent.country NEQ "United States" AND loc_collevent.sovereign_nation NEQ "United States of America">
								<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold">Sovereign Nation:</li>
								<li class="list-group-item col-7 col-xl-8 px-0">#loc_collevent.sovereign_nation#</li>
							</cfif>
						</cfif>
						<cfif len(loc_collevent.highergeographyid) gt 0>
							<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold">dwc:highergeographyID:</li>
							<cfset geogLink = getGuidLink(guid=#loc_collevent.highergeographyid#,guid_type=#loc_collevent.highergeographyid_guid_type#)>
							<li class="list-group-item col-7 col-xl-8 px-0">
								#loc_collevent.highergeographyid# #geogLink#
							</li>
						</cfif>
					</ul>
					<div class="w-100 float-left">
						<span class="px-2 float-left pt-0 pb-1"><a class="small90" href="/Specimens.cfm?execute=true&action=fixedSearch&higher_geog==#loc_collevent.higher_geog#" title="See other specimens with this Higher Geography">Specimens with same Higher Geography</a></span>
					</div>
					<div class="w-100 float-left">
						<span class="px-2 float-left pt-0 pb-1"><a class="small90" href="/Specimens.cfm?execute=true&builderMaxRows=1&action=builderSearch&nestdepth1=0&field1=LOCALITY%3ALOCALITY_LOCALITY_ID_PICK&searchText1=#encodeForURL(loc_collevent.spec_locality)#%20(#loc_collevent.locality_id#)&searchId1=#loc_collevent.locality_id#" title="See other specimens with this Locality">Specimens from the same Locality</a></span>
					</div>
					<!--- TODO: Display dwcEventDate not underlying began/end dates. --->
					<cfset eventDate = "">
					<cfif len(loc_collevent.began_date) gt 0>
						<cfif loc_collevent.began_date eq #loc_collevent.ended_date#>
							<cfset eventDate = "#loc_collevent.began_date#">
						<cfelse>
							<cfset eventDate ="#loc_collevent.began_date# / #loc_collevent.ended_date#">
						</cfif>
					</cfif>
					<div class="w-100 float-left">
						<span class="float-left px-2 pb-1"><a class="small90" href="/Specimens.cfm?execute=true&builderMaxRows=1&action=builderSearch&nestdepth1=0&field1=CATALOGED_ITEM%3ACATALOGED%20ITEM_COLLECTING_EVENT_ID&searchText1=#encodeForURL(loc_collevent.spec_locality)#%20#eventDate#%20(#loc_collevent.collecting_event_id#)&searchId1=#loc_collevent.collecting_event_id#" title="See other specimens from this collecting event">Specimens from the same Collecting Event</a></span>
					</div>
				</div>
				<div class="col-12 float-left px-0">
					<ul class="sd list-unstyled bg-light row mx-0 px-2 pt-1 mb-0 border-top">
						<cfif len(loc_collevent.spec_locality) gt 0>
							<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold">Specific Locality: </li>
							<li class="list-group-item col-7 col-xl-8 px-0 last">#loc_collevent.spec_locality#</li>
						</cfif>
						<cfif len(loc_collevent.verbatim_locality) gt 0>
							<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold">Verbatim Locality: </li>
							<li class="list-group-item col-7 col-xl-8 px-0 ">#loc_collevent.verbatim_locality#</li>
						</cfif>
						<cfif len(loc_collevent.verbatimcoordinates) gt 0>
							<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold">Verbatim Coordinates: </li>
							<li class="list-group-item col-7 col-xl-8 px-0">#loc_collevent.verbatimcoordinates#</li>
						</cfif>
						<cfif len(loc_collevent.township) gt 0>
							<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold">PLSS: </li>
							<cfif REFind("^[0-9]+$",loc_collevent.section)><cfset sec="S"><cfelse><cfset sec=""></cfif>
							<li class="list-group-item col-7 col-xl-8 px-0">#loc_collevent.section_part# #sec##loc_collevent.section# T#loc_collevent.township##ucase(loc_collevent.township_direction)#R#loc_collevent.range##ucase(loc_collevent.range_direction)# </li>
						</cfif>
						<cfif len(loc_collevent.max_depth) gt 0>
							<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold">Depth: </li>
							<li class="list-group-item col-7 col-xl-8 px-0"><cfif #loc_collevent.min_depth# eq #loc_collevent.max_depth#>#loc_collevent.min_depth# #loc_collevent.depth_units#<cfelse>#loc_collevent.min_depth# - #loc_collevent.max_depth# #loc_collevent.depth_units#</cfif></li>
						</cfif>
						<cfif len(loc_collevent.verbatimdepth) gt 0>
							<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold">Verbatim Depth: </li>
							<li class="list-group-item col-7 col-xl-8 px-0">#loc_collevent.verbatimdepth#</li>
						</cfif>
						<cfif len(loc_collevent.minimum_elevation) gt 0>
							<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold">Elevation: </li>
							<li class="list-group-item col-7 col-xl-8 px-0"><cfif #loc_collevent.minimum_elevation# eq #loc_collevent.maximum_elevation#>#loc_collevent.minimum_elevation# #loc_collevent.orig_elev_units#<cfelse>#loc_collevent.minimum_elevation# - #loc_collevent.maximum_elevation# #loc_collevent.orig_elev_units#</cfif></li>
						</cfif>
						<cfif len(loc_collevent.verbatimelevation) gt 0>
							<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold">Verbatim Elevation: </li>
							<li class="list-group-item col-7 col-xl-8 px-0">#loc_collevent.verbatimelevation#</li>
						</cfif>
						<cfif geology.recordcount GT 0> 
							<cfloop query="geology">
								<cfif len(geology.geo_att_value) GT 0>
									<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold">#geology.geology_attribute#: </li>
									<cfset geo_determiner = geology.determiner>
									<cfif geology.geo_att_determiner_id NEQ "0" AND len(geology.geo_att_determiner_id) GT 0>
										<cfset geo_determiner = "<a href='/agents/Agent.cfm?agent_id=#geology.geo_att_determiner_id#'>#geo_determiner#</a>">
									</cfif>
									<cfif len(geo_determiner) GT 0>
										<cfset geo_determiner = "By: #geo_determiner#">
									</cfif>
									<cfset geology_previous = "">
									<cfif len(geology.previous_values) GT 0 AND oneOfUs EQ 1>
										<cfset geology_previous = " [previously: #geology.previous_values#]">
									</cfif>
									<cfif len(geology.geo_att_determined_date) GT 0>
										<cfset geoOnDate=" on #geology.geo_att_determined_date#">
									<cfelse>
										<cfset geoOnDate="">
									</cfif>
									<cfif len(geology.geo_att_determined_method) GT 0>
										<cfset geoMethod=" (Method: #geology.geo_att_determined_method#)">
									<cfelse>
										<cfset geoMethod="">
									</cfif>
									<li class="list-group-item col-7 col-xl-8 px-0">#geology.geo_att_value#<span class="d-block small mb-0 pb-0"> #geo_determiner##geoOnDate##geoMethod# #geology.geo_att_remark##geology_previous#</span></li>
								</cfif>
							</cfloop>
						</cfif>
						<cfif len(loc_collevent.habitat_desc) gt 0>
							<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold">Habitat Description: </li>
							<li class="list-group-item col-7 col-xl-8 px-0">#loc_collevent.habitat_desc#</li>
						</cfif>
						<cfif len(microhabitat) gt 0>
							<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold">Microhabitat: </li>
							<li class="list-group-item col-7 col-xl-8 px-0">#microhabitat#</li>
						</cfif>
						<cfif len(loc_collevent.locality_remarks) gt 0>
							<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold">Locality Remarks: </li>
							<li class="list-group-item col-7 col-xl-8 px-0">#loc_collevent.locality_remarks#</li>
						</cfif>
						<cfif len(coordlookup.dec_lat) gt 0>
							<!--- georeference and metadata --->
							<cfset dateDet = coordlookup.determined_date>
							<!--- TODO: zero pad to coordinate_precision --->
							<cfset dla = left(#coordlookup.dec_lat#,10)>
							<cfset dlo = left(#coordlookup.dec_long#,10)>
							<cfset warn301="">
							<cfif coordlookup.max_error_distance EQ "301" AND coordlookup.max_error_units EQ "m">
								<cfset warn301="<span class='d-block small mb-0 pb-0'>[Note: a coordinate uncertainty of 301m is given by Biogeomancer and GeoLocate when unable to determine an uncertainty] </span>">
							</cfif>
							<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold">Georeference: </li>
							<cfset georef_determiner= coordlookup.lat_long_determined_by>
							<cfif coordlookup.determined_by_agent_id NEQ "0" and len(coordlookup.determined_by_agent_id) GT 0>
								<cfset georef_determiner = "<a href='/agents/Agent.cfm?agent_id=#coordlookup.determined_by_agent_id#'>#georef_determiner#</a>">
							</cfif>
							<cfif len(georef_determiner) GT 0>
								<cfset georef_determiner = "By: #georef_determiner#">
							</cfif>
							<cfif len(dateDet) GT 0>
								<cfset dateDet = " on #dateDet#">
							</cfif>
							<cfset georef_source=coordlookup.lat_long_ref_source>
							<cfif len(georef_source) GT 0>
								<cfset georef_source = " (Source: #georef_source#)">
							</cfif>
							<li class="list-group-item col-7 col-xl-8 px-0">
								<cfif dla EQ "[Masked]">
									#dla#
								<cfelse>
									#dla#&##176;, #dlo#&##176; 
								</cfif>
								<cfif dla EQ "[Masked]">
									<!--- don't display Not Specified for error radius --->
								<cfelseif coordlookup.max_error_distance EQ "0">
									(Error radius: Unknown) 
								<cfelseif len(coordlookup.max_error_distance) EQ 0>
									(Error radius: Not Specified) 
								<cfelse>
									(Error radius: #coordlookup.max_error_distance##coordlookup.max_error_units#) 
								</cfif>
								<span class="d-block small mb-0 pb-0"> #georef_determiner##dateDet##georef_source#</span>#warn301#
							</li>

							<cfif len(coordlookup.datum) GT 0>
								<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold">Datum: </li>
								<li class="list-group-item col-7 col-xl-8 px-0">#coordlookup.datum#</li>
							</cfif>

							<cfif len(coordlookup.utm_zone) GT 0>
								<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold">UTM Coordinates: </li>
								<li class="list-group-item col-7 col-xl-8 px-0">#coordlookup.utm_zone# #coordlookup.utm_ew# #coordlookup.utm_ns#</li>
							</cfif>

							<cfif len(coordlookup.extent) GT 0>
								<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold">Radial of Feature: </li>
								<li class="list-group-item col-7 col-xl-8 px-0">#coordlookup.extent# m</li>
							</cfif>
							<cfif len(coordlookup.gpsaccuracy) GT 0>
								<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold">GNSS/GPS Accuracy: </li>
								<li class="list-group-item col-7 col-xl-8 px-0">#coordlookup.gpsaccuracy#</li>
							</cfif>
							<cfif len(coordlookup.spatialfit) GT 0>
								<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold">Point-Radius Spatial Fit: </li>
								<li class="list-group-item col-7 col-xl-8 px-0">#coordlookup.spatialfit#</li>
							</cfif>

							<cfif len(coordlookup.orig_lat_long_units) GT 0>
								<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold">Coordinates Entered As: </li>
								<li class="list-group-item col-7 col-xl-8 px-0">
									#coordlookup.orig_lat_long_units#
									<cfif coordlookup.orig_lat_long_units NEQ "decimal degrees" and coordlookup.orig_lat_long_units NEQ "unknown">
										<cfset originalForm = "">
										<cfif coordlookup.orig_lat_long_units EQ "deg. min. sec.">
											<cfset originalForm = "#coordlookup.lat_deg#&deg; #coordlookup.lat_min#&prime; #coordlookup.lat_sec#&Prime; #coordlookup.lat_dir#">
											<cfset originalForm = "#originalForm#&nbsp; #coordlookup.long_deg#&deg; #coordlookup.long_min#&prime; #coordlookup.long_sec#&Prime; #coordlookup.long_dir#">
										<cfelseif coordlookup.orig_lat_long_units EQ "degrees dec. minutes">
											<cfset originalForm = "#coordlookup.lat_deg#&deg; #coordlookup.dec_lat_min#&prime; #coordlookup.lat_dir#">
											<cfset originalForm = "#originalForm#&nbsp; #coordlookup.long_deg#&deg; #coordlookup.dec_long_min#&prime; #coordlookup.long_dir#">
										</cfif>
										<cfif len(originalForm) GT 0>
											<span class="d-block small mb-0 pb-0">(#originalForm#)</span>
										</cfif>
								</cfif>
								</li>
							</cfif>
							<cfif len(loc_collevent.verbatimcoordinates) GT 0>
								<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold">Verbatim Coordinates: </li>
								<cfif len(loc_collevent.verbatimsrs) GT 0><cfset verbsrs="(Datum: #loc_collevent.verbatimsrs#)"><cfelse><cfset verbsrs=""></cfif>
								<li class="list-group-item col-7 col-xl-8 px-0">
									<span class="d-block small mb-0 pb-0">#loc_collevent.verbatimcoordinates# #verbsrs#</span>
								</li>
							</cfif>
	
							<cfif oneOfUs EQ 1>
								<cfif len(coordlookup.error_polygon) GT 0>
									<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold">Has Footprint: </li>
									<li class="list-group-item col-7 col-xl-8 px-0">Yes (see map)</li>
									<cfif len(coordlookup.footprint_spatialfit) GT 0>
										<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold">Footprint Spatial Fit: </li>
										<li class="list-group-item col-7 col-xl-8 px-0">#coordLookup.footprint_spatialfit#</li>
									</cfif>
								</cfif>
								<cfif len(coordlookup.verificationstatus) GT 0>
									<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold">Georeference Verification Status: </li>
									<li class="list-group-item col-7 col-xl-8 px-0">#coordlookup.verificationstatus#</li>
								</cfif>
								<cfif len(coordlookup.lat_long_verified_by) GT 0>
									<cfset georef_determiner = coordlookup.lat_long_verified_by>
									<cfif coordlookup.verified_by_agent_id NEQ "0">
										<cfset georef_verifier = "<a href='/agents/Agent.cfm?agent_id=#coordlookup.verified_by_agent_id#'>#georef_determiner#</a>">
									</cfif>
									<cfif len(coordlookup.lat_long_verified_by) GT 0>
										<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold">Georeference verified by: </li>
										<li class="list-group-item col-7 col-xl-8 px-0">#georef_verifier#</li>
									</cfif>
								</cfif>
								<cfif len(coordlookup.geolocate_score) GT 0>
									<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold">Geo-Locate Metadata: </li>
									<li class="list-group-item col-7 col-xl-8 px-0">Score: #coordlookup.geolocate_score# Precision: #coordlookup.geolocate_precision# Number of results: #coordlookup.geolocate_numresults# Pattern used: #coordlookup.geolocate_parsepattern#</li>
								</cfif>
								<cfif coordlookup.recordcount GT 1>
									<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold">Unaccepted Georeferences: </li>
									<li class="list-group-item col-7 col-xl-8 px-0">
										#coordlookup.recordcount - 1#
										<button onclick="toggleUnacceptedGeorefs();" role="button" class="btn btn-xs small py-0 ml-1 btn-secondary" id="unaccGeoToggleButton">Show</button>
									</li>
									<script>
										function toggleUnacceptedGeorefs() { 
											$('.unacceptedGeoreferenceLI').toggle();
											if ($('.unacceptedGeoreferenceLI').is(':visible')) { 
												$('##unaccGeoToggleButton').html("Hide");
											} else {
												$('##unaccGeoToggleButton').html("Show");
											}
										}
										jQuery(document).ready(function() {
											$('.unacceptedGeoreferenceLI').hide();
										});
									</script>
									<cfset i = 0>
									<cfloop query="coordlookup">
										<cfset i = i+1>
										<cfif i GT 1>
											<li class="list-group-item col-5 col-xl-4 px-0 unacceptedGeoreferenceLI font-weight-lessbold">
												Unaccepted: 
											</li>
											<cfset dla = left(#coordlookup.dec_lat#,10)>
											<cfset dlo = left(#coordlookup.dec_long#,10)>
											<cfset georef_determiner= coordlookup.lat_long_determined_by>
											<cfif coordlookup.determined_by_agent_id NEQ "0">
												<cfset georef_determiner = "<a href='/agents/Agent.cfm?agent_id=#coordlookup.determined_by_agent_id#'>#georef_determiner#</a>">
											</cfif>
											<cfif len(georef_determiner) GT 0>
												<cfset georef_determiner = "By: #georef_determiner#">
											</cfif>
											<cfset dateDet = coordlookup.determined_date>
											<cfif len(dateDet) GT 0>
												<cfset dateDet = " on #dateDet#">
											</cfif>
											<cfset georef_source=coordlookup.lat_long_ref_source>
											<cfif len(georef_source) GT 0>
												<cfset georef_source = " (Source: #georef_source#)">
											</cfif>
											<li class="list-group-item col-7 col-xl-8 px-0 unacceptedGeoreferenceLI">
												#dla#, #dlo# (error radius: #coordlookup.max_error_distance##coordlookup.max_error_units#) 
												<span class="d-block small mb-0 pb-0"> #georef_determiner##dateDet##georef_source##warn301#</span>
											</li>
											<cfif len(coordlookup.geolocate_score) GT 0>
												<li class="list-group-item col-5 col-xl-4 px-0 unacceptedGeoreferenceLI font-weight-lessbold">
													Geo-Locate Metadata: 
												</li>
												<li class="list-group-item col-7 col-xl-8 px-0 unacceptedGeoreferenceLI">
													Score: #coordlookup.geolocate_score# Precision: #coordlookup.geolocate_precision# Number of results: #coordlookup.geolocate_numresults# Pattern used: #coordlookup.geolocate_parsepattern#
												</li>
											</cfif>
										</cfif>
									</cfloop>
								</cfif>
							</cfif>
						</cfif>
				
						<cfif len(loc_collevent.collecting_method) gt 0>
							<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold">Collecting Method: </li>
							<li class="list-group-item col-7 col-xl-8 px-0">#loc_collevent.collecting_method#</li>
						</cfif>
						<cfif len(loc_collevent.collecting_source) gt 0>
							<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold">Collecting Source: </li>
							<li class="list-group-item col-7 col-xl-8 px-0">#loc_collevent.collecting_source#</li>
						</cfif>
						<cfif len(loc_collevent.began_date) gt 0>
							<cfif loc_collevent.began_date eq #loc_collevent.ended_date#>
								<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold">Collected On: </li>
							<cfelse>
								<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold">Began Date / Ended Date: </li>
							</cfif>
							<li class="list-group-item col-7 col-xl-8 px-0">#eventDate#</li>
						</cfif>
						<cfif len(loc_collevent.verbatim_date) gt 0>
							<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold">Verbatim Date: </li>
							<li class="list-group-item col-7 col-xl-8 px-0">#loc_collevent.verbatim_date#</li>
						</cfif>
						<cfif len(loc_collevent.collecting_time) gt 0>
							<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold">Time Collected: </li>
							<li class="list-group-item col-7 col-xl-8 px-0">#loc_collevent.collecting_time#</li>
						</cfif>
						<cfif len(loc_collevent.coll_event_remarks) gt 0>
							<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold">Collecting Event Remarks: </li>
							<li class="list-group-item col-7 col-xl-8 px-0">#loc_collevent.coll_event_remarks#</li>
						</cfif>
						<cfif len(loc_collevent.fish_field_number) gt 0>
							<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold">Ich. Field Number: </li>
							<li class="list-group-item col-7 col-xl-8 px-0">#loc_collevent.fish_field_number#</li>
						</cfif>
						<cfquery name="collEventNumbers"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							SELECT
								coll_event_number, number_series, 
								case 
									when collector_agent_id is null then '[No Agent]'
									else MCZBASE.get_agentnameoftype(collector_agent_id, 'preferred') 
								end
								as collector_agent_name,
								collector_agent_id
							FROM
								coll_event_number
								left join coll_event_num_series on coll_event_number.coll_event_num_series_id = coll_event_num_series.coll_event_num_series_id
							WHERE
								collecting_event_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#loc_collevent.collecting_event_id#"> 
						</cfquery>
						<cfif collEventNumbers.recordcount gt 0>
							<cfloop query="collEventNumbers">
								<li class="list-group-item col-5 col-xl-4 px-0"><span class="my-0 font-weight-lessbold">Collecting Event/Field Number: </span></li>
								<cfset num_determiner= collEventNumbers.collector_agent_name>
								<cfif len(collEventNumbers.collector_agent_id) GT 0 AND collEventNumbers.collector_agent_id NEQ "0">
									<cfset num_determiner = "<a href='/agents/Agent.cfm?agent_id=#collEventNumbers.collector_agent_id#'>#num_determiner#</a>">
								</cfif>
								<li class="list-group-item col-7 col-xl-8 px-0">
									#collEventNumbers.coll_event_number# 
									<span class="d-block small mb-0 pb-0"> (#collEventNumbers.number_series# of #num_determiner#)</span>
								</li>
							</cfloop>
						</cfif>
						<cfquery name="colls" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							SELECT
								collector.agent_id,
								collector.coll_order,
								MCZBASE.get_agentnameoftype(collector.agent_id) collector_name,
								agent.agentguid_guid_type,
								agent.agentguid
							FROM
								collector
								join agent on collector.agent_id = agent.agent_id
							WHERE
								collector.collector_role='c' and
								collector.collection_object_id = <cfqueryparam value="#collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
							ORDER BY
								coll_order
						</cfquery>
						<cfif colls.recordcount EQ 0>
							<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold"><em>Collector: </em></li>
							<li class="list-group-item col-7 col-xl-8 px-0 font-weight-lessbold">
								None
								<cfif listcontainsnocase(session.roles,"manage_specimens")>
									<a href="javascript:void(0)" role="button" class="btn btn-xs small py-0 anchorFocus" onClick="openEditCollectorsDialog(#collection_object_id#,'collectorsDialog','#guid#',reloadLocality)"> Add </a>
								</cfif>
							</li>
						<cfelse>
							<li class="list-group-item col-5 col-xl-4 px-0">
								<cfset plural="s">
								<cfif colls.recordcount EQ 1>
									<cfset plural = "">
								</cfif>
								<span class="my-0 font-weight-lessbold">Collector#plural#: </span>
								<cfif listcontainsnocase(session.roles,"manage_specimens")>
									<a href="javascript:void(0)" role="button" class="btn btn-xs small py-0 anchorFocus" onClick="openEditCollectorsDialog(#collection_object_id#,'collectorsDialog','#guid#',reloadLocality)"> Edit </a>
								</cfif>
							</li>
							<cfif oneOfUs EQ 0 AND Findnocase("mask collector", check.encumbranceDetail)>
								<li class="list-group-item col-7 col-xl-8 px-0 font-weight-lessbold">[Masked]</li>
							<cfelse>
								<cfset collectors = "">
								<cfset sep="">
								<cfloop query="colls">
									<cfif #colls.agent_id# NEQ "0">
										<cfset agentLinkOut = "">
										<cfif len(colls.agentguid) GT 0>
											<cfset agentLinkOut = getGuidLink(guid=#colls.agentguid#,guid_type=#colls.agentguid_guid_type#)>
										</cfif>
										<cfset collectors="#collectors##sep#<a href='/agents/Agent.cfm?agent_id=#colls.agent_id#'>#colls.collector_name#</a>#agentLinkOut#"> <!--- " --->
									<cfelse>
										<cfset collectors="#collectors##sep##colls.collector_name#">
									</cfif>
									<cfset sep="; ">
								</cfloop>
								<li class="list-group-item col-7 col-xl-8 px-0 font-weight-lessbold">#collectors#</li>
							</cfif>
						</cfif>
						</ul>
				</div>
				<cfquery name="localityMedia"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select
						media_id
					from
						media_relations
					where
						RELATED_PRIMARY_KEY= <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#loc_collevent.locality_id#">
						AND MEDIA_RELATIONSHIP like '% locality'
						AND MCZBASE.is_media_encumbered(media_id) < 1 
				</cfquery>
				<cfquery name="collEventMedia"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select
						media_id
					from
						media_relations
					where
						RELATED_PRIMARY_KEY=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#loc_collevent.collecting_event_id#">
						AND MEDIA_RELATIONSHIP like '% collecting_event'
						AND MCZBASE.is_media_encumbered(media_id) < 1 
				</cfquery>
				<cfif localityMedia.recordcount gt 0>
					<cfset mediaType1 = "Locality">
					<cfset mediaType2 = "">
					<cfset conjunction = "">
					<cfset mediaLabel="Media">
					
				</cfif>
				<cfif collEventMedia.recordcount gt 0>
					<cfset mediaType2 = "Collecting Event">
					<cfset mediaType1 = "">
					<cfset conjunction = "">
					<cfset mediaLabel="Media">
				</cfif>
				<cfif collEventMedia.recordcount gt 0 and localityMedia.recordcount gt 0>
					<cfset mediaType1 = "Locality">
					<cfset mediaType2 = "Collecting Event">
					<cfset conjunction = "and">
					<cfset mediaLabel="Media:">
				<cfelse>
					<cfset mediaType1 = "">
					<cfset mediaType2 = "">
					<cfset conjunction = "">
					<cfset mediaLabel="">
				</cfif>
				<div class="w-100 float-left px-2">
					<div class="col-12 px-0 py-1 small90 font-weight-lessbold border-top-gray">#mediaType1# #conjunction# #mediaType2# #mediaLabel#</div>
					<cfif localityMedia.recordcount gt 0>
						<cfloop query="localityMedia">
							<div class="col-6 px-1 col-sm-3 col-lg-3 col-xl-3 mb-1 px-md-2 pt-1 float-left"> 
								<div id='locMediaBlock#localityMedia.media_id#'>
									<cfset mediaBlock= getMediaBlockHtmlUnthreaded(media_id="#localityMedia.media_id#",size="350",captionAs="textShort")>
								</div>
							</div>
						</cfloop>
					</cfif>
					<cfif collEventMedia.recordcount gt 0>
						<cfloop query="collEventMedia">
							<div class="col-6 col-sm-3 px-1 col-lg-3 col-xl-3 mb-1 px-md-2 pt-1 float-left"> 
								<div id='ceMediaBlock#collEventMedia.media_id#'>
									<cfset mediaBlock= getMediaBlockHtmlUnthreaded(media_id="#collEventMedia.media_id#",size="350",captionAs="textShort")>
								</div>
							</div>
						</cfloop>
					</cfif>
				</div>
			<cfcatch>
				<cfset error_message = cfcatchToErrorMessage(cfcatch)>
				<cfset function_called = "#GetFunctionCalledName()#">
				<h2 class='h3'>Error in #function_called#:</h2>
				<div>#error_message#</div>
			</cfcatch>
			</cftry>
		</cfoutput> 
	</cfthread>
	<cfthread action="join" name="getLocalityThread" />
	<cfreturn getLocalityThread.output>
</cffunction>
							
<!--- getPreparatorsHTML get a block of html containing preparators for the specified cataloged item
 @param collection_object_id for the cataloged item for which to return preparators.
 @return a block of html with collection object preparators, or if none, html with the text None
--->
<cffunction name="getPreparatorsHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="collection_object_id" type="string" required="yes">

	<cfthread name="getPreparatorsThread">
	<cfoutput>
		<cftry>
			<cfif not isdefined("collection_object_id") or not isnumeric(collection_object_id)>
				<div class="error"> Improper call. Aborting..... </div>
				<cfabort>
			</cfif>
			<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
				<cfset oneOfUs = 1>
			<cfelse>
				<cfset oneOfUs = 0>
			</cfif>
			<!--- check for mask record, hide if mask record ---->
			<cfquery name="check" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT 
					concatEncumbranceDetails(<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">) encumbranceDetail
				FROM DUAL
			</cfquery>
			<cfif oneOfUs EQ 0 AND Findnocase("mask record", check.encumbranceDetail)>
				<cfthrow message="Record Masked">
			</cfif>
			<cfquery name="preps" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT
					collector.agent_id,
					collector.coll_order,
					case when
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#oneOfUs#"> != 1 and concatencumbrances(collector.collection_object_id) like '%mask preparator%' then '[Masked]'
					else
						preferred_agent_name.agent_name
					end preparator
				FROM
					collector,
					preferred_agent_name
				WHERE
					collector.collector_role='p' and
					collector.agent_id=preferred_agent_name.agent_id and
					collector.collection_object_id = <cfqueryparam value="#collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
				ORDER BY
					coll_order
			</cfquery>
			<ul class="list-group">
				<cfif preps.recordcount EQ 0>
					<li class="small list-group-item py-0 font-italic">None</li>
				</cfif>
				<cfif preps.recordcount gt 0>
					<cfif preps.recordcount eq 1>
						<li class="list-group-item pt-0">
							<span class="my-0 d-inline font-weight-lessbold">Preparator:&nbsp;</span>
							<cfloop query="preps">
								<cfif len(preps.agent_id) GT 0 AND preps.agent_id NEQ "0">
									<a href="/agents/Agent.cfm?agent_id=#preps.agent_id#">#preps.preparator#</a>
								<cfelse>
									#preps.preparator#
								</cfif>
							</cfloop>
						</li>
					<cfelse>
						<li class="list-group-item pt-0">
							<span class="my-0 font-weight-lessbold d-inline">Preparators:&nbsp;</span>
							<cfset separator = "">
								<cfloop query="preps">
								<cfif len(preps.agent_id) GT 0 AND preps.agent_id NEQ "0">
									#separator#<a href="/agents/Agent.cfm?agent_id=#preps.agent_id#">#preps.preparator#</a>
								<cfelse>
									#separator##preps.preparator#
								</cfif>
								<cfset separator="<span class='sd'>,</span> " > <!--- " --->
							</cfloop>
						</li>
					</cfif>
				</ul>
				</cfif>
			<cfcatch>
				<cfset error_message = cfcatchToErrorMessage(cfcatch)>
				<cfset function_called = "#GetFunctionCalledName()#">
				<h2 class='h3'>Error in #function_called#:</h2>
				<div>#error_message#</div>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="getPreparatorsThread"/>
	<cfreturn getPreparatorsThread.output>
</cffunction>		

<!--- getRemarksHTML get a block of html containing collection object remarks for a specified cataloged item
 @param collection_object_id for the cataloged item for which to return remarks.
 @return a block of html with collection object remarks, or if none, html with the text None
--->
<cffunction name="getRemarksHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="collection_object_id" type="string" required="yes">

	<cfthread name="getRemarksThread">
		<cfoutput>
			<cftry>
				<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
					<cfset oneOfUs = 1>
				<cfelse>
					<cfset oneOfUs = 0>
				</cfif>
				<!--- check for mask record and prevent access, further check for mask parts below ---->
				<cfquery name="check" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT 
						concatEncumbranceDetails(<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">) encumbranceDetail
					FROM DUAL
				</cfquery>
				<cfif oneOfUs EQ 0 AND Findnocase("mask record", check.encumbranceDetail)>
					<cfthrow message="Record Masked">
				</cfif>
				<cfquery name="object_rem" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT
						coll_object_remark.coll_object_remarks,
						coll_object_remark.disposition_remarks,
						coll_object_remark.associated_species
					FROM
						cataloged_item
						left join coll_object_remark on cataloged_item.collection_object_id = coll_object_remark.collection_object_id
					WHERE
						cataloged_item.collection_object_id = <cfqueryparam value="#collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
				</cfquery>
				<ul class="list-group">
					<!--- check for mask parts, hide collection object remarks if mask parts ---->
					<cfif oneofus EQ 0 AND Findnocase("mask parts", check.encumbranceDetail)>
						<li class="list-group-item">Masked</li>
					<cfelse>
						<cfloop query="object_rem">
							<cfif len(#object_rem.coll_object_remarks#) EQ 0 AND len(object_rem.disposition_remarks) EQ 0 AND len(object_rem.associated_species) EQ 0>
								<li class="small list-group-item font-italic py-0">None </li>
							</cfif>
							<cfif len(#object_rem.coll_object_remarks#) gt 0>
								<li class="list-group-item py-1">#object_rem.coll_object_remarks#</li>
							</cfif>
							<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_specimens")>
								<cfif len(object_rem.disposition_remarks) gt 0 >
									<li class="list-group-item py-1">Disposition Remarks: #object_rem.disposition_remarks#</li>
								</cfif>
							</cfif>
							<cfif len(object_rem.associated_species) gt 0 >
								<li class="list-group-item py-1">Associated Species: #object_rem.associated_species#</li>
							</cfif>
						</cfloop>
					</cfif>
				</ul>
			<cfcatch>
				<cfset error_message = cfcatchToErrorMessage(cfcatch)>
				<cfset function_called = "#GetFunctionCalledName()#">
				<h2 class='h3'>Error in #function_called#:</h2>
				<div>#error_message#</div>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="getRemarksThread"/>
	<cfreturn getRemarksThread.output>
</cffunction>


<!--- getAnnotationsHTML get a block of html containing annotations for a specified cataloged item.
 @param collection_object_id for the cataloged item for which to return annotations.
 @return a block of html with collection object annotations, or if none, html with the text None
--->
<cffunction name="getAnnotationsHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="collection_object_id" type="string" required="yes">

	<cfthread name="getAnnotationsThread">
		<cfoutput>
			<cftry>
				<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
					<cfset oneOfUs = 1>
				<cfelse>
					<cfset oneOfUs = 0>
				</cfif>
				<!--- check for mask record and prevent access, further check for mask parts below ---->
				<cfquery name="check" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT 
						concatEncumbranceDetails(<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">) encumbranceDetail
					FROM DUAL
				</cfquery>
				<cfif oneOfUs EQ 0 AND Findnocase("mask record", check.encumbranceDetail)>
					<cfthrow message="Record Masked">
				</cfif>
				<cfquery name="annotations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT
						annotation_id,
						to_char(annotate_date,'yyyy-mm-dd') annotate_date,
						cf_username,
						annotation,
						motivation,
						reviewer_agent_id,
						MCZBASE.get_agentnameoftype(reviewer_agent_id) reviewer,
						reviewed_fg,
						reviewer_comment,
						state, 
						resolution
					FROM 
						annotations
					WHERE
						collection_object_id = <cfqueryparam value="#collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
					ORDER BY 
						annotate_date
				</cfquery>
				<ul class="list-group">
					<!--- check for mask parts, hide collection object remarks if mask parts ---->
					<cfif oneofus EQ 0 AND Findnocase("mask parts", check.encumbranceDetail)>
						<li class="list-group-item">Masked</li>
					<cfelse>
						<cfif annotations.recordcount EQ 0>
							<li class="small list-group-item font-italic py-0">None </li>
						</cfif>
						<cfloop query="annotations">
							<cfif len(#annotation#) gt 0>
								<li class="list-group-item py-1">
									<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_specimens")>
										#annotation#
									<cfelse>
										#rereplace(annotation,"^.* reported:","[Masked] reported:")#
									</cfif>
									<span class="d-block small mb-0 pb-0">#motivation# (#annotate_date#) #state#</span>
									<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_specimens")>
										<cfif reviewed_fg EQ "1">
											<span class="d-block small mb-0 pb-0">#resolution# #reviwer# #reviewer_comment#</span>
										</cfif>
									</cfif>
								</li>
							</cfif>
						</cfloop>
					</cfif>
				</ul>
			<cfcatch>
				<cfset error_message = cfcatchToErrorMessage(cfcatch)>
				<cfset function_called = "#GetFunctionCalledName()#">
				<h2 class='h3'>Error in #function_called#:</h2>
				<div>#error_message#</div>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="getAnnotationsThread"/>
	<cfreturn getAnnotationsThread.output>
</cffunction>

<!--- getMetaHTML get a block of html containing metadata about a cataloged item record 
 @param collection_object_id for the cataloged item for which to return metadata.
 @return a block of html with cataloged item record metadata, or if none, whitespace only
--->
<cffunction name="getMetaHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="collection_object_id" type="string" required="yes">

	<cfthread name="getMetadataThread">
		<cfoutput>
			<cftry>
				<cfif not isdefined("collection_object_id") or not isnumeric(collection_object_id)>
					<div class="error"> Improper call. Aborting..... </div>
					<cfabort>
				</cfif>
				<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
					<cfset oneOfUs = 1>
				<cfelse>
					<cfset oneOfUs = 0>
				</cfif>
				<!--- check for mask record, hide if mask record ---->
				<cfquery name="check" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT 
						concatEncumbranceDetails(<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">) encumbranceDetail
					FROM DUAL
				</cfquery>
				<cfif oneOfUs EQ 0 AND Findnocase("mask record", check.encumbranceDetail)>
					<cfthrow message="Record Masked">
				</cfif>
				<cfquery name="meta" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT
						coll_object.coll_object_entered_date,
						coll_object.last_edit_date,
						coll_object.flags,
						enteredPerson.agent_name EnteredBy,
						editedPerson.agent_name EditedBy,
						concatencumbrances(cataloged_item.collection_object_id) concatenatedEncumbrances,
						concatEncumbranceDetails(cataloged_item.collection_object_id) encumbranceDetail
					FROM
						cataloged_item
						left join collection on cataloged_item.collection_id = collection.collection_id
						left join coll_object on cataloged_item.collection_object_id = coll_object.collection_object_id
						left join preferred_agent_name enteredPerson on coll_object.entered_person_id = enteredPerson.agent_id
						left join preferred_agent_name editedPerson on coll_object.last_edited_person_id = editedPerson.agent_id
					WHERE
						cataloged_item.collection_object_id = <cfqueryparam value="#collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
				</cfquery>
				<ul class="list-group">
					<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
						<cfif #meta.EditedBy# is not "unknown" OR len(#meta.last_edit_date#) is not 0>
							<li class="list-group-item pt-0 pb-1"> <span class="my-0 d-inline font-weight-lessbold">Entered By:</span> #meta.EnteredBy# on #dateformat(meta.coll_object_entered_date,"yyyy-mm-dd")# </li>
							<li class="list-group-item pt-0 pb-1"><span class="my-0 d-inline font-weight-lessbold">Last Edited By:</span> #meta.EditedBy# on #dateformat(meta.last_edit_date,"yyyy-mm-dd")# </li>
						</cfif>
						<cfif len(#meta.flags#) is not 0>
							<li class="list-group-item pt-0 pb-1"><span class="my-0 d-inline font-weight-lessbold">Missing (flags):</span> #isOne.flags# </li>
						</cfif>
						<cfif len(#meta.encumbranceDetail#) is not 0>
							<li class="list-group-item pt-0 pb-1"><span class="my-0 d-inline font-weight-lessbold">Encumbrances:</span> #replace(meta.encumbranceDetail,";","<br>","all")# </li>
						</cfif>
					</cfif>
					<cfif isdefined("session.roles") and listfindnocase(session.roles,"global_admin")>
							<li class="list-group-item pt-0 pb-1"><span class="my-0 d-inline font-weight-lessbold">collection_object_id:</span> #collection_object_id# </li>
					</cfif>
				</ul>
			<cfcatch>
				<cfset error_message = cfcatchToErrorMessage(cfcatch)>
				<cfset function_called = "#GetFunctionCalledName()#">
				<h2 class='h3'>Error in #function_called#:</h2>
				<div>#error_message#</div>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="getMetadataThread"/>
	<cfreturn getMetadataThread.output>
</cffunction>
							
<!--- getNamedGroupsHTML get a block of html containing a list of named groups that a cataloged item belongs to.
 @param collection_object_id for the cataloged item for which to return named groups.
 @return a block of html with cataloged item record groups, or if none, a list containing 'None'
--->
<cffunction name="getNamedGroupsHTML" access="remote" returntype="any" returnformat="json">
	<cfargument name="collection_object_id" type="string" required="yes">

	<cfthread name="getNamedGroupsThread">
		<cfoutput>
			<cftry>
				<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
					<cfset oneOfUs = 1>
				<cfelse>
					<cfset oneOfUs = 0>
				</cfif>
				<!--- check for mask record, hide if mask record ---->
				<cfquery name="check" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT 
						concatEncumbranceDetails(<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">) encumbranceDetail
					FROM DUAL
				</cfquery>
				<cfif oneOfUs EQ 0 AND Findnocase("mask record", check.encumbranceDetail)>
					<cfthrow message="Record Masked">
				</cfif>
				<cfquery name="named_groups" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="named_groups">
					SELECT DISTINCT 
						collection_name, underscore_relation.underscore_collection_id, mask_fg
					FROM
						underscore_collection
						left join underscore_relation on underscore_collection.underscore_collection_id = underscore_relation.underscore_collection_id
						left join <cfif ucase(session.flatTableName) EQ "FLAT"> flat <cfelse> filtered_flat </cfif> flat on underscore_relation.collection_object_id = flat.collection_object_id
					WHERE
						flat.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
						<cfif isdefined("session.roles") AND listcontainsnocase(session.roles,"manage_specimens")>
							-- all groups
						<cfelse>
							and mask_fg = 0
						</cfif>
				</cfquery>
				<ul class="list-group">
					<cfif named_groups.recordcount EQ 0>
						<li class="small list-group-item font-italic py-0">None</li>
					<cfelse>
						<cfloop query="named_groups">
							<li class="list-group-item">
								<a href= "/grouping/showNamedCollection.cfm?underscore_collection_id=#named_groups.underscore_collection_id#">#named_groups.collection_name#</a>
							</li>
						</cfloop>
					</cfif>
				</ul>
			<cfcatch>
				<cfset error_message = cfcatchToErrorMessage(cfcatch)>
				<cfset function_called = "#GetFunctionCalledName()#">
				<h2 class='h3'>Error in #function_called#:</h2>
				<div>#error_message#</div>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="getNamedGroupsThread"/>
	<cfreturn getNamedGroupsThread.output>
</cffunction>	


<!--- getHistoryHTML get a block of html containing prepservation and condition history for a collection object
 @param collection_object_id for the collection object for which to return condition history.
 @return a block of html with condition history, or if none, a list containing 'None'
--->
<cffunction name="getHistoryHTML" access="remote" returntype="any" returnformat="json">
	<cfargument name="collection_object_id" type="string" required="yes">

	<cfset tn = REReplace(CreateUUID(), "[-]", "", "all") >	
	<cfthread name="getHistoryThread#tn#">
		<cfoutput>
			<cftry>
				<cfquery name="itemDetails" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT
						'cataloged item' part_name,
						cat_num,
						collection.collection,
						MCZBASE.GET_SCIENTIFIC_NAME_AUTHS(collection_object_id) scientific_name
					FROM
						cataloged_item
						join collection on cataloged_item.collection_id = collection.collection_id
					WHERE
						cataloged_item.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
					UNION
					SELECT 
						part_name,
						cat_num,
						collection.collection,
						MCZBASE.GET_SCIENTIFIC_NAME_AUTHS(cataloged_item.collection_object_id) scientific_name
					FROM
						cataloged_item
						join collection on cataloged_item.collection_id = collection.collection_id
						join specimen_part on cataloged_item.collection_object_id = specimen_part.derived_from_cat_item
					WHERE
						specimen_part.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
				</cfquery>

				<h2 class="h3">
					#itemDetails.collection# #itemDetails.cat_num#
					(#itemDetails.scientific_name#) #itemDetails.part_name#
				</h2>
				<cfquery name="cond" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT 
						object_condition_id,
						determined_agent_id,
						MCZBASE.get_agentnameoftype(determined_agent_id) agent_name,
						determined_date,
						condition
					FROM 
						object_condition
					WHERE
						collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
					ORDER BY determined_date DESC
				</cfquery>
				<cfif cond.recordcount GT 0>
					<h2 class="h3">Condition History</h3>
					<table class="table px-1 w-100" >
						<thead>
						<tr>
							<th>Determined By</th>
							<th>Date</th>
							<th>Condition</th>
						</tr>
						</thead>
						<tbody>
						<cfloop query="cond">
							<cfset thisDate = #dateformat(determined_date,"yyyy-mm-dd")#>
							<tr>
								<td> 
									<cfif len(determined_agent_id) GT 0 AND determined_agent_id NEQ "0">
										<a href="/agents/Agent.cfm?agent_id=#determined_agent_id#">#agent_name#</a>
									<cfelse>
										#agent_name#
									</cfif>
								</td>
								<td> #thisDate# </td>
								<td> #condition# </td>
							</tr>
						</cfloop>
						</tbody>
					</table>
				<cfelse>
					<h2 class="h3">(No Condition History)</h3>
				</cfif>

				<cfquery name="pres" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT
						SPECIMEN_PART_PRES_HIST_ID,
						CHANGED_AGENT_ID,
						MCZBASE.get_agentnameoftype(changed_agent_id) agent_name,
						CHANGED_DATE,
						preserve_method,
						part_name,
						decode(lot_count_modifier, null, '', lot_count_modifier) || lot_count as lotCount,
						coll_object_remarks,
						is_current_fg
					FROM 
						SPECIMEN_PART_PRES_HIST
					WHERE
						collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
					ORDER BY CHANGED_DATE DESC
				</cfquery>
				<cfif pres.recordcount GT 0>
					<h2 class="h3"> Preservation History </h2>
					<table class="px-1 w-100 table">
						<thead>
						<tr>
							<th>Changed By</th>
							<th>Date</th>
							<th>Part Name</th>
							<th>Preserve Method</th>
							<th>Lot Count</th>
						</tr>
						</thead>
						<tbody>
						<cfloop query="pres">
							<cfset thisDate = #dateformat(CHANGED_DATE,"yyyy-mm-dd")#>
							<tr>
								<td> 
									<cfif len(changed_agent_id) GT 0 AND changed_agent_id NEQ "0">
										<a href="/agents/Agent.cfm?agent_id=#changed_agent_id#">#agent_name#</a>
									<cfelse>
										#agent_name#
									</cfif>
								</td>
								<td> #thisDate# </td>
								<td> #part_name# </td>
								<td> #preserve_method# </td>
								<td>#lotCount# </td>
							</tr>
							<cfif len(coll_object_remarks) gt 0>
							<tr>
								<td colspan="6" class="w-100">Remarks:  #coll_object_remarks# </td>
							</tr>
							</cfif>
						</cfloop>
						</tbody>
					</table>
				<cfelse>
					<h2 class="h3">(No Preservation History)</h3>
				</cfif>
			<cfcatch>
				<cfset error_message = cfcatchToErrorMessage(cfcatch)>
				<cfset function_called = "#GetFunctionCalledName()#">
				<h2 class='h3'>Error in #function_called#:</h2>
				<div>#error_message#</div>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="getHistoryThread#tn#"/>
	<cfreturn cfthread["getHistoryThread#tn#"].output>
</cffunction>	

</cfcomponent>
