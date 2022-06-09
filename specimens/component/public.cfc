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

<!--- getMediaHTML obtain a block of html listing identifications for a cataloged item
 @param collection_object_id the collection_object_id for the cataloged item for which to obtain the identifications.
 @return html for viewing identifications for the specified cataloged item. 
--->
<cffunction name="getMediaHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfthread name="getMediaThread">
		<cfoutput>
			<cftry>
			<cfquery name="images" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT
					media.media_id
				FROM
					media
					left join media_relations on media_relations.media_id = media.media_id
				WHERE
					media_relations.related_primary_key = <cfqueryparam value="#collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
			</cfquery>
			<!--- argument scope isn't available within the cfthread, so creating explicit local variables to bring optional arguments into scope within the thread --->
				<cfif len(images.media_id)gt 0>
					<cfloop query="images">
						<cfquery name="getImages" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							SELECT distinct
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
								left join media_relations on media_relations.media_id = media.media_id
							WHERE
								media.media_id = <cfqueryparam value="#images.media_id#" cfsqltype="CF_SQL_DECIMAL">
							and (media.media_type = 'image' OR media.media_type = 'audio' OR media.media_type = '3D model' OR media.media_type = 'video')
						</cfquery>
							<div class="col-6 py-1 float-left px-1">
								<div  class="border rounded py-2 px-1">
									<div class="col-12 px-1 col-md-6 mb-1 py-1 float-left">
										<cfset mediaBlock= getMediaBlockHtml(media_id="#images.media_id#",displayAs="thumbSm")>
										<div id="mediaBlock#images.media_id#">
											#mediaBlock#
										</div>
									</div>
								</div>
							</div>
					</cfloop>
				</cfif>
			<cfcatch>
				<cfif isDefined("cfcatch.queryError") >
					<cfset queryError=cfcatch.queryError>
				<cfelse>
					<cfset queryError = ''>
				</cfif>
				<cfset message = trim("Error processing #GetFunctionCalledName()#: " & cfcatch.message & " " & cfcatch.detail & " " & queryError) >
				<cfcontent reset="yes">
				<cfheader statusCode="500" statusText="#message#">
					<div class="container">
						<div class="row">
							<div class="alert alert-danger" role="alert">
								<img src="/shared/images/Process-stop.png" alt="[ error ]" style="float:left; width: 50px;margin-right: 1em;">
								<h2>Internal Server Error.</h2>
								<p>#message#</p>
								<p><a href="/info/bugs.cfm">"Feedback/Report Errors"</a></p>
							</div>
						</div>
					</div>
			</cfcatch>
		</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="getMediaThread" />
	<cfreturn getMediaThread.output>
</cffunction>
							
<cffunction name="getLedgerHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfthread name="getLedgerThread">
		<cfoutput>
			<cftry>
				<cfquery name="images1" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT
						media.media_id,
						media.media_uri,
						media.preview_uri,
						media.mime_type
					FROM
						media
						left join media_relations on media_relations.media_id = media.media_id
					WHERE
						media_relations.related_primary_key = <cfqueryparam value="#collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
				</cfquery>
				<!--- argument scope isn't available within the cfthread, so creating explicit local variables to bring optional arguments into scope within the thread --->
				<cfif len(images.media_id)gt 0>
					<cfloop query="images1">
						<cfquery name="getImages1" datasource="user_login" username="#session.dbuser#" 	password="#decrypt(session.epw,cfid)#">
							SELECT distinct
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
								media,
								media_relations
							WHERE 
								media_relations.media_id = media.media_id
							AND
								media.media_id = <cfqueryparam value="#images.media_id#" cfsqltype="CF_SQL_DECIMAL">
							and media.media_type = 'text'
						</cfquery>
						<div class="col-6 py-1 float-left px-1">
							<div class="border rounded py-2 px-1">
								<div class="col-12 px-1 col-md-6 mb-1 py-1 float-left">
										<cfset mediaBlock= getMediaBlockHtml(media_id="#images1.media_id#",displayAs="thumbSm")>
										<div id="mediaBlock#images1.media_id#">
											#mediaBlock#
										</div>
									</div>
								</div>
							</div>
						</div>
					</cfloop>
				</cfif>
			<cfcatch>
				<cfif isDefined("cfcatch.queryError") >
					<cfset queryError=cfcatch.queryError>
				<cfelse>
					<cfset queryError = ''>
				</cfif>
				<cfset message = trim("Error processing #GetFunctionCalledName()#: " & cfcatch.message & " " & cfcatch.detail & " " & queryError) >
				<cfcontent reset="yes">
				<cfheader statusCode="500" statusText="#message#">
					<div class="container">
						<div class="row">
							<div class="alert alert-danger" role="alert">
								<img src="/shared/images/Process-stop.png" alt="[ error ]" style="float:left; width: 50px;margin-right: 1em;">
								<h2>Internal Server Error.</h2>
								<p>#message#</p>
								<p><a href="/info/bugs.cfm">"Feedback/Report Errors"</a></p>
							</div>
						</div>
					</div>
			</cfcatch>
		</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="getLedgerThread" />
	<cfreturn getLedgerThread.output>
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
				<cfquery name="identification" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT
						identification.scientific_name,
						identification.collection_object_id,
						concatidagent(identification.identification_id) agent_name,
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
						identification,
						(select * from formatted_publication where format_style='short') formatted_publication
					WHERE
						identification.publication_id=formatted_publication.publication_id (+) and
						identification.collection_object_id = <cfqueryparam value="#collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
					ORDER BY accepted_id_fg DESC,sort_order, made_date DESC
				</cfquery>
				<cfset formerHeadShown = false>
				<cfloop query="identification">
					<cfquery name="getTaxa" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						SELECT distinct
							taxonomy.taxon_name_id,
							display_name,
							scientific_name,
							author_text,
							full_taxon_name 
						FROM 
							identification_taxonomy
							left join taxonomy on identification_taxonomy.taxon_name_id = taxonomy.taxon_name_id
						WHERE 
							identification_id = <cfqueryparam value="#identification_id#" cfsqltype="CF_SQL_DECIMAL">
					</cfquery>
					<cfif accepted_id_fg is 1>
						<ul class="list-group border-green mb-2 mt-2 mx-2 rounded px-3 py-2 h4 font-weight-normal">
							<div class="d-inline-block my-0 h4 text-success">Current Identification</div>
							<cfif getTaxa.recordcount is 1 and taxa_formula is 'a'>
								<div class="font-italic h4 mb-0 mt-2 font-weight-lessbold d-inline-block"> <a href="/name/#getTaxa.scientific_name#" target="_blank">#getTaxa.display_name# </a>
									<cfif len(getTaxa.author_text) gt 0>
										<span class="sm-caps font-weight-lessbold">#getTaxa.author_text#</span>
									</cfif>
								</div>
							<cfelse>
								<cfset link="">
								<cfset i=1>
								<cfset thisSciName="#scientific_name#">
								<cfloop query="getTaxa">
									<span class="font-italic h4 font-weight-lessbold d-inline-block">
									<cfset thisLink='<a href="/name/#scientific_name#" class="d-inline" target="_blank">#display_name#</a>'>
									<cfset thisSciName=#replace(thisSciName,scientific_name,thisLink)#>
									<cfset i=#i#+1>
									<a href="##">#thisSciName#</a> <span class="sm-caps font-weight-lessbold">#getTaxa.author_text#</span> </span>
								</cfloop>
							</cfif>
							<cfif listcontainsnocase(session.roles,"manage_specimens")>
								<cfif stored_as_fg is 1>
									<span class="bg-gray float-right rounded p-1">STORED AS</span>
								</cfif>
							</cfif>
							<cfif not isdefined("metaDesc")>
								<cfset metaDesc="">
							</cfif>
							<cfloop query="getTaxa">
								<div class="h5 mb-1 text-dark font-italic"> #full_taxon_name# </div>
								<cfset metaDesc=metaDesc & '; ' & full_taxon_name>
								<cfquery name="cName" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
									SELECT 
										common_name 
									FROM 
										common_name
									WHERE 
										taxon_name_id= <cfqueryparam value="#taxon_name_id#" cfsqltype="CF_SQL_DECIMAL"> 
										and common_name is not null
									GROUP BY 
										common_name order by common_name
								</cfquery>
								<cfif len(cName.common_name) gt 0>
									<div class="h5 mb-1 mt-0 text-muted font-weight-normal pl-3">Common Name(s): #valuelist(cName.common_name,"; ")# </div>
								</cfif>
								<cfset metaDesc=metaDesc & '; ' & valuelist(cName.common_name,"; ")>
							</cfloop>
							<div class="form-row mx-0">
								<div class="small mr-2"><span class="h5">Determiner:</span> #agent_name#
									<cfif len(made_date) gt 0>
										<span class="h5">on</span> #dateformat(made_date,"yyyy-mm-dd")#
									</cfif>
								</div>
							</div>
							<div class="small mr-2"><span class="h5">Nature of ID:</span> #nature_of_id# </div>
							<cfif len(identification_remarks) gt 0>
									<div class="small"><span class="h5">Remarks:</span> #identification_remarks#</div>
								</cfif>
						</ul>
					<cfelse>
						<!---Start of former Identifications--->
		<!---				<cfif getTaxa.recordcount GT 0 AND NOT formerHeadShown>
							<div class="h4 pl-4 mt-2 mb-0 text-success">Former Identifications</div>
							<cfset formerHeadShown = false>
						</cfif>--->
						<!---Add Title for former identifications--->
						<ul class="list-group py-1 px-3 ml-2 text-dark bg-light">
							<li class="px-0">
							<cfif getTaxa.recordcount is 1 and taxa_formula is 'a'>
								<span class="font-italic h4 font-weight-normal">
									<a href="/name/#getTaxa.scientific_name#" target="_blank">#getTaxa.display_name#</a>
								</span><!---identification  for former names when there is no author--->
								<cfif len(getTaxa.author_text) gt 0>
									<span class="color-black sm-caps">#getTaxa.author_text#</span><!---author text for former names--->
								</cfif>
							<cfelse>
									<cfset link="">
									<cfset i=1>
									<cfset thisSciName="#scientific_name#">
								<cfloop query="getTaxa">
									<cfset thisLink='<a href="/name/#scientific_name#" target="_blank">#display_name#</a>'>
									<cfset thisSciName=#replace(thisSciName,scientific_name,thisLink)#>
									<cfset i=#i#+1>
								</cfloop>
								#thisSciName#<!---identification for former names when there is an author--it put the sci name with the author--->
							</cfif>
							<cfif listcontainsnocase(session.roles,"manage_specimens")>
								<cfif stored_as_fg is 1>
									<span style="float-right rounded p-1 bg-light">STORED AS</span>
								</cfif>
							</cfif>
							<cfif not isdefined("metaDesc")>
								<cfset metaDesc="">
							</cfif>
							<cfloop query="getTaxa">
							<!--- TODO: We loop through getTaxa results three times, and query for common names twice?????  Construction here needs review.  --->
							<p class="small90 text-muted mb-0"> #full_taxon_name#</p>
							<!--- full taxon name for former id--->
							<cfset metaDesc=metaDesc & '; ' & full_taxon_name>
							<cfquery name="cName" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
									SELECT 
										common_name 
									FROM 
										common_name
									WHERE 
										taxon_name_id= <cfqueryparam value="#taxon_name_id#" cfsqltype="CF_SQL_DECIMAL"> 
										and common_name is not null
									GROUP BY 
										common_name order by common_name
							</cfquery>
							<cfif len(cName.common_name) gt 0>
								<div class="small90 text-muted pl-3">Common Name(s): #valuelist(cName.common_name,"; ")#</div>
								<cfset metaDesc=metaDesc & '; ' & valuelist(cName.common_name,"; ")>
							</cfif>
							<!---  common name for former id--->
						</cfloop>
							<cfif len(formatted_publication) gt 0>
							 sensu <a href="/publication/#publication_id#" target="_mainFrame"> #formatted_publication# </a><!---  Don't think this is used--->
							</cfif>
							<span class="small90">Determination: #agent_name#
								<cfif len(made_date) gt 0>
								on #dateformat(made_date,"yyyy-mm-dd")#
								</cfif>
								<span class="d-block">Nature of ID: #nature_of_id#</span>
								<cfif len(identification_remarks) gt 0>
								<span class="d-block">Remarks: #identification_remarks#</span>
								</cfif>
							</span>
							</li>
						</ul>
					</cfif>
				</cfloop>
			<cfcatch>
				<cfif isDefined("cfcatch.queryError") >
					<cfset queryError=cfcatch.queryError>
				<cfelse>
					<cfset queryError = ''>
				</cfif>
				<cfset message = trim("Error processing #GetFunctionCalledName()#: " & cfcatch.message & " " & cfcatch.detail & " " & queryError) >
				<cfcontent reset="yes">
				<cfheader statusCode="500" statusText="#message#">
					<div class="container">
						<div class="row">
							<div class="alert alert-danger" role="alert">
								<img src="/shared/images/Process-stop.png" alt="[ error ]" style="float:left; width: 50px;margin-right: 1em;">
								<h2>Internal Server Error.</h2>
								<p>#message#</p>
								<p><a href="/info/bugs.cfm">“Feedback/Report Errors”</a></p>
							</div>
						</div>
					</div>
			</cfcatch>
			</cftry>
			</cfoutput>
		</cfthread>
		<cfthread action="join" name="getIdentificationsThread" />
	<cfreturn getIdentificationsThread.output>
</cffunction>

<!--- getOtherIdsHTML obtain a block of html listing other id numbers for a cataloged item
 @param collection_object_id the collection_object_id for the cataloged item for which to obtain the other id numbers
 @return html for viewing identifications for the specified cataloged item. 
--->
<cffunction name="getOtherIDsHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="collection_object_id" type="string" required="yes">
		<cfthread name="getOtherIDsThread">
			<cfoutput>
				<cftry>
				<cfquery name="oid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT
						case when concatencumbrances(coll_obj_other_id_num.collection_object_id) like '%mask original field number%' and
							coll_obj_other_id_num.other_id_type = 'original identifier'
							then 'Masked'
						else
							coll_obj_other_id_num.display_value
						end display_value,
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
					<ul class="list-group pt-1">
						<cfloop query="oid">
							<li class="list-group-item pt-0">#other_id_type#:
							<cfif len(link) gt 0>
								<a class="external" href="#link#" target="_blank">#display_value#</a>
							<cfelse>
								#display_value#
							</cfif>
							</li>
						</cfloop>
					</ul>
				</cfif>
				<cfcatch>
				<cfif isDefined("cfcatch.queryError") >
				<cfset queryError=cfcatch.queryError>
				<cfelse>
				<cfset queryError = ''>
				</cfif>
				<cfset message = trim("Error processing #GetFunctionCalledName()#: " & cfcatch.message & " " & cfcatch.detail & " " & queryError) >
				<cfcontent reset="yes">
				<cfheader statusCode="500" statusText="#message#">
				<div class="container">
					<div class="row">
						<div class="alert alert-danger" role="alert"> <img src="/shared/images/Process-stop.png" alt="[ error ]" style="float:left; width: 50px;margin-right: 1em;">
							<h2>Internal Server Error.</h2>
							<p>#message#</p>
							<p><a href="/info/bugs.cfm">“Feedback/Report Errors”</a></p>
						</div>
					</div>
				</div>
			</cfcatch>
			</cftry>
			</cfoutput>
		</cfthread>
		<cfthread action="join" name="getOtherIDsThread" />
	<cfreturn getOtherIDsThread.output>
</cffunction>
					
<cffunction name="getCitationsHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="collection_object_id" type="string" required="yes">
		<cfthread name="getCitationsThread">
			<cfoutput>
				<cftry>
				<cfquery name="citations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						SELECT
							citation.type_status,
							citation.occurs_page_number,
							citation.citation_page_uri,
							citation.CITATION_REMARKS,
							cited_taxa.scientific_name as cited_name,
							cited_taxa.taxon_name_id as cited_name_id,
							formatted_publication.formatted_publication,
							formatted_publication.publication_id,
							cited_taxa.taxon_status as cited_name_status
						from
							citation
							left join taxonomy cited_taxa on citation.cited_taxon_name_id = cited_taxa.taxon_name_id
							left join formatted_publication on citation.publication_id = formatted_publication.publication_id
						where
							format_style='short' and
							citation.collection_object_id = <cfqueryparam value="#collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
						order by
							substr(formatted_publication, - 4)
					</cfquery>
					<cfset i = 1>
					<cfloop query="citations" group="formatted_publication">
						<div class="d-block py-1 px-2 w-100 float-left">
							<span class="d-inline"></span>
							<a href="/SpecimenUsage.cfm?action=search&publication_id=#publication_id#" target="_mainFrame">#formatted_publication#</a>,
							<cfif len(occurs_page_number) gt 0>
								Page
								<cfif len(citation_page_uri) gt 0>
									<a href ="#citation_page_uri#" target="_blank">#occurs_page_number#</a>,
								<cfelse>
								#occurs_page_number#,
								</cfif>
							</cfif>
							<span class="font-weight-lessbold">#cited_name_status#</span> of 
								<a href="/TaxonomyDetails.cfm?taxon_name_id=#cited_name_id#" target="_mainFrame">
									<i>#replace(cited_name," ","&nbsp;","all")#</i>
								</a>
								<cfif find("(ms)", #type_status#) NEQ 0>
								<!--- Type status with (ms) is used to mark to be published types, for which we aren't (yet) exposing the new name.  Append sp. nov or ssp. nov.as appropriate to the name of the parent taxon of the new name --->
									<cfif find(" ", #cited_name#) NEQ 0>
									&nbsp;ssp. nov.
									<cfelse>
									&nbsp;sp. nov.
									</cfif>
								</cfif>
								<span class="small font-italic">
									<cfif len(citation_remarks) gt 0></cfif>
									#CITATION_REMARKS#
								</span>
						</div>
						<cfset i = i + 1>
					</cfloop>
					<cfcatch>
						<cfif isDefined("cfcatch.queryError") >
							<cfset queryError=cfcatch.queryError>
						<cfelse>
							<cfset queryError = ''>
						</cfif>
						<cfset message = trim("Error processing #GetFunctionCalledName()#: " & cfcatch.message & " " & cfcatch.detail & " " & queryError) >
						<cfcontent reset="yes">
						<cfheader statusCode="500" statusText="#message#">
							<div class="container">
								<div class="row">
									<div class="alert alert-danger" role="alert"> <img src="/shared/images/Process-stop.png" alt="[ error ]" style="float:left; width: 50px;margin-right: 1em;">
										<h2>Internal Server Error.</h2>
										<p>#message#</p>
										<p><a href="/info/bugs.cfm">“Feedback/Report Errors”</a></p>
									</div>
								</div>
							</div>
					</cfcatch>
				</cftry>
			</cfoutput>
		</cfthread>
	<cfthread action="join" name="getCitationsThread" />
	<cfreturn getCitationsThread.output>
</cffunction>
								
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
			<cfquery name="rparts" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select
					specimen_part.collection_object_id part_id,
					Case
						when #oneOfus#= 1
						then pc.label
						else null
					End label,
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
					agent_name
				from
					specimen_part,
					coll_object,
					coll_object_remark,
					coll_obj_cont_hist,
					container oc,
					container pc,
					specimen_part_attribute,
					preferred_agent_name
				where
					specimen_part.collection_object_id=specimen_part_attribute.collection_object_id (+) and
					specimen_part_attribute.determined_by_agent_id=preferred_agent_name.agent_id (+) and
					specimen_part.collection_object_id=coll_object.collection_object_id and
					coll_object.collection_object_id=coll_obj_cont_hist.collection_object_id and
					coll_object.collection_object_id=coll_object_remark.collection_object_id (+) and
					coll_obj_cont_hist.container_id=oc.container_id and
					oc.parent_container_id=pc.container_id (+) and
					specimen_part.derived_from_cat_item = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
			</cfquery>
			<cfquery name="parts" dbtype="query">
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
					rparts
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
					part_name
			</cfquery>
			<cfquery name="mPart" dbtype="query">
				select * from parts where sampled_from_obj_id is null order by part_name
			</cfquery>
			<cfset ctPart.ct=''>
			<cfquery name="ctPart" dbtype="query">
				select count(*) as ct from parts
			</cfquery>
			<table class="table border-bottom mb-0 mt-1">
				<thead>
					<tr class="bg-light">
						<th><span>Part Name</span></th>
						<th><span>Condition</span></th>
						<th><span>Disposition</span></th>
						<th><span>##</span></th>
						<cfif oneOfus is "1">
							<th>
								<span>Container</span>
							</th>
						</cfif>
					</tr>
				</thead>
				<tbody>
					<cfset i=1>
					<cfloop query="mPart">
					<tr <cfif mPart.recordcount gt 1>class=""<cfelse></cfif>>
						<td><span class="">#part_name#</span></td>
						<td>#part_condition#</td>
						<td>#part_disposition#</td>
						<td>#lot_count#</td>
						<cfif oneOfus is "1">
							<td>#label#</td>
						</cfif>
					</tr>
					<cfif len(part_remarks) gt 0>
						<tr class="small90 border-bottom-0">
							<td colspan="5" class="border-bottom-0 mb-0 pt-1 pb-0">
								<span class="pl-3 d-block"><span class="font-italic">Remarks:</span> #part_remarks#</span>
							</td>
						</tr>
					</cfif>
					<cfquery name="patt" dbtype="query">
						select
							attribute_type,
							attribute_value,
							attribute_units,
							determined_date,
							attribute_remark,
							agent_name
						from
							rparts
						where
							attribute_type is not null and
							part_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#part_id#">
						group by
							attribute_type,
							attribute_value,
							attribute_units,
							determined_date,
							attribute_remark,
							agent_name
					</cfquery>
					<cfif patt.recordcount gt 0>
						<tr class="border-top-0">
							<td colspan="5" class="border-top-0 mt-0 pb-2 pt-1">
								<cfloop query="patt">
									<div class="small90 pl-3" style="line-height: .9rem;">
										#attribute_type#=<span class="font-weight-lessbold">#attribute_value#</span> &nbsp;
									<cfif len(attribute_units) gt 0>
										#attribute_units# &nbsp;
									</cfif>
									<cfif len(determined_date) gt 0>
										determined date=<span class="font-weight-lessbold">#dateformat(determined_date,"yyyy-mm-dd")#</span> &nbsp;
									</cfif>
									<cfif len(agent_name) gt 0>
										determined by=<span class="font-weight-lessbold">#agent_name#</span> &nbsp;
									</cfif>
									<cfif len(attribute_remark) gt 0>
										remark=<span class="font-weight-lessbold">#attribute_remark#</span> &nbsp;
									</cfif>
									</div>
								</cfloop>
							</td>
						</tr>
					</cfif>
					<cfquery name="sPart" dbtype="query">
						select * from parts where sampled_from_obj_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#part_id#">
					</cfquery>
					<cfloop query="sPart">
						<tr>
							<td><span class="d-inline-block pl-3">#part_name# <span class="font-italic">subsample</span></span></td>
							<td>#part_condition#</td>
							<td>#part_disposition#</td>
							<td>#lot_count#</td>
							<td>#label#</td>
						</tr>
						<cfif len(part_remarks) gt 0>
						<tr class="small">
							<td colspan="5">
								<span class="pl-3 d-block">
									<span class="font-italic">Remarks:</span> #part_remarks#
								</span>
							</td>
						</tr>
						</cfif>
					</cfloop>

				</cfloop>
				</tbody>
			</table>
			<cfcatch>
				<cfif isDefined("cfcatch.queryError") >
					<cfset queryError=cfcatch.queryError>
				<cfelse>
					<cfset queryError = ''>
				</cfif>
				<cfset message = trim("Error processing #GetFunctionCalledName()#: " & cfcatch.message & " " & cfcatch.detail & " " & queryError) >
				<cfcontent reset="yes">
				<cfheader statusCode="500" statusText="#message#">
				<div class="container">
					<div class="row">
						<div class="alert alert-danger" role="alert">
							<img src="/shared/images/Process-stop.png" alt="[ error ]" style="float:left; width: 50px;margin-right: 1em;">
							<h2>Internal Server Error.</h2>
							<p>#message#</p>
							<p><a href="/info/bugs.cfm">“Feedback/Report Errors”</a></p>
						</div>
					</div>
				</div>
			</cfcatch>
		</cftry>
	</cfoutput>
	</cfthread>
	<cfthread action="join" name="getPartsThread"/>
	<cfreturn getPartsThread.output>
</cffunction>
						
<cffunction name="getAttributesHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfthread name="getAttributesThread">
	<cfoutput>
		<cftry>
			<cfquery name="attribute" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT
					attributes.attribute_type,
					attributes.attribute_value,
					attributes.attribute_units,
					attributes.attribute_remark,
					attributes.determination_method,
					attributes.determined_date,
					attribute_determiner.agent_name attributeDeterminer
				FROM
					attributes,
					preferred_agent_name attribute_determiner
				WHERE
					attributes.determined_by_agent_id = attribute_determiner.agent_id and
					attributes.collection_object_id = <cfqueryparam value="#collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
			</cfquery>
			<cfquery name="relns" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT 
					distinct biol_indiv_relationship, related_collection, related_coll_object_id, related_cat_num, biol_indiv_relation_remarks FROM (
				SELECT
					 rel.biol_indiv_relationship as biol_indiv_relationship,
					 collection as related_collection,
					 rel.related_coll_object_id as related_coll_object_id,
					 rcat.cat_num as related_cat_num,
					rel.biol_indiv_relation_remarks as biol_indiv_relation_remarks
				FROM
					 biol_indiv_relations rel
					 left join cataloged_item rcat
						 on rel.related_coll_object_id = rcat.collection_object_id
					 left join collection
						 on collection.collection_id = rcat.collection_id
					 left join ctbiol_relations ctrel
					  on rel.biol_indiv_relationship = ctrel.biol_indiv_relationship
				WHERE rel.collection_object_id = <cfqueryparam value="#collection_object_id#" cfsqltype="CF_SQL_DECIMAL"> 
					  and ctrel.rel_type <> 'functional'
				UNION
				SELECT
					 ctrel.inverse_relation as biol_indiv_relationship,
					 collection as related_collection,
					 irel.collection_object_id as related_coll_object_id,
					 rcat.cat_num as related_cat_num,
					irel.biol_indiv_relation_remarks as biol_indiv_relation_remarks
				FROM
					 biol_indiv_relations irel
					 left join ctbiol_relations ctrel
					  on irel.biol_indiv_relationship = ctrel.biol_indiv_relationship
					 left join cataloged_item rcat
					  on irel.collection_object_id = rcat.collection_object_id
					 left join collection
					 on collection.collection_id = rcat.collection_id
				WHERE irel.related_coll_object_id = <cfqueryparam value="#collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
					 and ctrel.rel_type <> 'functional'
				)
			</cfquery>    
			<cfquery name="sex" dbtype="query">
				select * from attribute where attribute_type = 'sex'
			</cfquery>
			<ul class="list-group">
				<cfloop query="sex">
					<li class="list-group-item"> sex: #attribute_value#,
						<cfif len(attributeDeterminer) gt 0>
							<cfset determination = "determiner: #attributeDeterminer#">

							<cfif len(determined_date) gt 0>  
								<cfset determination = '#determination# on #dateformat(determined_date,"yyyy-mm-dd")#'>
							</cfif>
							<cfif len(determination_method) gt 0>
								<cfset determination = '#determination#, #determination_method#'>
							</cfif>
							#determination#
						</cfif>
						<cfif len(attribute_remark) gt 0>
							, Remark: #attribute_remark#
						</cfif>
					</li>
				</cfloop>
				<cfquery name="code" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select collection_cde from cataloged_item where collection_object_id = <cfqueryparam value="#collection_object_id#" cfsqltype="CF_SQL_DECIMAL"> 
				</cfquery>
				<cfif #code.collection_cde# is "Mamm">
					<cfquery name="total_length" dbtype="query">
						select * from attribute where attribute_type = 'total length'
					</cfquery>
					<cfquery name="tail_length" dbtype="query">
						select * from attribute where attribute_type = 'tail length'
					</cfquery>
					<cfquery name="hf" dbtype="query">
						select * from attribute where attribute_type = 'hind foot with claw'
					</cfquery>
					<cfquery name="efn" dbtype="query">
						select * from attribute where attribute_type = 'ear from notch'
					</cfquery>
					<cfquery name="weight" dbtype="query">
						select * from attribute where attribute_type = 'weight'
					</cfquery>
					<cfif
						len(total_length.attribute_units) gt 0 OR
						len(tail_length.attribute_units) gt 0 OR
						len(hf.attribute_units) gt 0  OR
						len(efn.attribute_units) gt 0  OR
						len(weight.attribute_units) gt 0>
						<!---semi-standard measurements --->
						<span class="h5 pt-1 px-2 mb-0">Standard Measurements</span>
						<table class="table table-striped border mb-1 mx-1" aria-label="Standard Measurements">
						<tr>
							<td><font size="-1">total length</font></td>
							<td><font size="-1">tail length</font></td>
							<td><font size="-1">hind foot</font></td>
							<td><font size="-1">efn</font></td>
							<td><font size="-1">weight</font></td>
						</tr>
						<tr>
							<td>#total_length.attribute_value# #total_length.attribute_units#&nbsp;</td>
							<td>#tail_length.attribute_value# #tail_length.attribute_units#&nbsp;</td>
							<td>#hf.attribute_value# #hf.attribute_units#&nbsp;</td>
							<td>#efn.attribute_value# #efn.attribute_units#&nbsp;</td>
							<td>#weight.attribute_value# #weight.attribute_units#&nbsp;</td>
						</tr>
					</table>
						<cfif isdefined("attributeDeterminer") and len(#attributeDeterminer#) gt 0>
							<cfset determination = ", determiner: #attributeDeterminer#">
							<cfif len(determined_date) gt 0>
								<cfset determination = '#determination# on #dateformat(determined_date,"yyyy-mm-dd")#'>
							</cfif>
							<cfif len(determination_method) gt 0>
								<cfset determination = '#determination#, #determination_method#'>
							</cfif>
							#determination#
						</cfif>
					</cfif>
					<cfquery name="theRest" dbtype="query">
						select * from attribute 
						where attribute_type NOT IN (
						'weight','sex','total length','tail length','hind foot with claw','ear from notch'
						)
					</cfquery>
					<cfelse>
					<!--- not Mamm --->
					<cfquery name="theRest" dbtype="query">
						select * from attribute where attribute_type NOT IN ('sex')
					</cfquery>
				</cfif>
				<cfloop query="theRest">
					<li class="list-group-item">#attribute_type#: #attribute_value#
						<cfif len(attribute_units) gt 0>#attribute_units#</cfif><cfif len(attributeDeterminer) gt 0><cfset determination =", determiner: #attributeDeterminer#">
						<cfif len(determined_date) gt 0>
							<cfset determination = '#determination# on #dateformat(determined_date,"yyyy-mm-dd")#'>
						</cfif>
						<cfif len(determination_method) gt 0>
							<cfset determination = '#determination#, #determination_method#'>
						</cfif>
							#determination#
						</cfif>
						<cfif len(attribute_remark) gt 0>
							, Remark: #attribute_remark#
						</cfif>
					</li>
				</cfloop>
			</ul>
			<cfcatch>
				<cfif isDefined("cfcatch.queryError") >
					<cfset queryError=cfcatch.queryError>
				<cfelse>
					<cfset queryError = ''>
				</cfif>
				<cfset message = trim("Error processing #GetFunctionCalledName()#: " & cfcatch.message & " " & cfcatch.detail & " " & queryError) >
				<cfcontent reset="yes">
				<cfheader statusCode="500" statusText="#message#">
				<div class="container">
					<div class="row">
						<div class="alert alert-danger" role="alert">
							<img src="/shared/images/Process-stop.png" alt="[ error ]" style="float:left; width: 50px;margin-right: 1em;">
							<h2>Internal Server Error.</h2>
							<p>#message#</p>
							<p><a href="/info/bugs.cfm">“Feedback/Report Errors”</a></p>
						</div>
					</div>
				</div>
			</cfcatch>
		</cftry>
	</cfoutput>
	</cfthread>
	<cfthread action="join" name="getAttributesThread" />
	<cfreturn getAttributesThread.output>
</cffunction>			
						
<cffunction name="getRelationsHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfthread name="getRelationsThread">
	<cfoutput>
		<cftry>
			<cfquery name="relns" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			SELECT 
				distinct biol_indiv_relationship, related_coll_cde, related_collection, 
				related_coll_object_id, related_cat_num, biol_indiv_relation_remarks FROM 
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
					 left join cataloged_item rcat
						 on rel.related_coll_object_id = rcat.collection_object_id
					 left join collection
						 on collection.collection_id = rcat.collection_id
					 left join ctbiol_relations ctrel
					  on rel.biol_indiv_relationship = ctrel.biol_indiv_relationship
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
					 left join ctbiol_relations ctrel
					  on irel.biol_indiv_relationship = ctrel.biol_indiv_relationship
					 left join cataloged_item rcat
					  on irel.collection_object_id = rcat.collection_object_id
					 left join collection
					 on collection.collection_id = rcat.collection_id
				WHERE irel.related_coll_object_id = <cfqueryparam value="#collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
					 and ctrel.rel_type <> 'functional'
				)
		</cfquery>
			<cfif len(relns.biol_indiv_relationship) gt 0 >
				<ul class="list-group list-group-flush pt-1 float-left">
					<cfloop query="relns">
						<li class="list-group-item py-0"> #biol_indiv_relationship# 
							<a href="/Specimens.cfm?execute=true&action=fixedSearch&collection=#relns.related_coll_cde#&cat_num=#relns.related_cat_num#" target="_blank"> #related_collection# #related_cat_num# </a>
							<cfif len(relns.biol_indiv_relation_remarks) gt 0>
								(Remark: #biol_indiv_relation_remarks#)
							</cfif>
						</li>
					</cfloop>
				<!---<cfif len(relns.biol_indiv_relationship) gt 0>
						<li class="pb-1 list-group-item">
						<a href="/Specimens.cfm?execute=true&action=fixedSearch&/SpecimenResults.cfm?collection_object_id=#valuelist(relns.related_coll_object_id)#" target="_blank">(Specimens List)</a>
						</li>
					</cfif>--->
				</ul>
			</cfif>
			<cfcatch>
				<cfif isDefined("cfcatch.queryError") >
					<cfset queryError=cfcatch.queryError>
				<cfelse>
					<cfset queryError = ''>
				</cfif>
				<cfset message = trim("Error processing #GetFunctionCalledName()#: " & cfcatch.message & " " & cfcatch.detail & " " & queryError) >
				<cfcontent reset="yes">
				<cfheader statusCode="500" statusText="#message#">
				<div class="container">
							<div class="row">
								<div class="alert alert-danger" role="alert">
									<img src="/shared/images/Process-stop.png" alt="[ error ]" style="float:left; width: 50px;margin-right: 1em;">
									<h2>Internal Server Error.</h2>
									<p>#message#</p>
									<p><a href="/info/bugs.cfm">“Feedback/Report Errors”</a></p>
								</div>
							</div>
						</div>
			</cfcatch>
		</cftry>
	</cfoutput>
	</cfthread>
	<cfthread action="join" name="getRelationsThread"/>
	<cfreturn getRelationsThread.output>
</cffunction>

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
			<cfquery name="one" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT
					cataloged_item.collection_object_id as collection_object_id,
					cataloged_item.cat_num,
					collection.collection_cde,
					cataloged_item.accn_id,
					collection.collection,
					identification.scientific_name,
					identification.identification_remarks,
					identification.identification_id,
					identification.made_date,
					identification.nature_of_id,
					collecting_event.collecting_event_id,
					collecting_event.began_date,
					collecting_event.ended_date,
					collecting_event.verbatim_date,
					collecting_event.startDayOfYear,
					collecting_event.endDayOfYear,
					collecting_event.habitat_desc,
					collecting_event.coll_event_remarks,
					coll_object.coll_object_entered_date,
					coll_object.last_edit_date,
					coll_object.flags,
					enteredPerson.agent_name EnteredBy,
					editedPerson.agent_name EditedBy,
					accn.transaction_id Accession,
					accn.accn_number,
					concatencumbrances(cataloged_item.collection_object_id) concatenatedEncumbrances,
					concatEncumbranceDetails(cataloged_item.collection_object_id) encumbranceDetail,
					collecting_method,
					collecting_source,
					decode(trans.transaction_id, null, 0, 1) vpdaccn
				FROM
					cataloged_item
					left join collection on cataloged_item.collection_id = collection.collection_id
					left join identification on cataloged_item.collection_object_id = identification.collection_object_id
					left join collecting_event on cataloged_item.collecting_event_id = collecting_event.collecting_event_id
					left join locality on collecting_event.locality_id = locality.locality_id
					left join accepted_lat_long on locality.locality_id = accepted_lat_long.locality_id
					left join preferred_agent_name latLongAgnt on accepted_lat_long.determined_by_agent_id = latLongAgnt.agent_id
					left join geog_auth_rec on locality.geog_auth_rec_id = geog_auth_rec.geog_auth_rec_id
					left join coll_object on cataloged_item.collection_object_id = coll_object.collection_object_id
					left join coll_object_remark on coll_object.collection_object_id = coll_object_remark.collection_object_id
					left join preferred_agent_name enteredPerson on coll_object.entered_person_id = enteredPerson.agent_id
					left join preferred_agent_name editedPerson on coll_object.last_edited_person_id = editedPerson.agent_id
					left join accn on cataloged_item.accn_id =  accn.transaction_id
					left join trans on accn.transaction_id = trans.transaction_id
				WHERE
					identification.accepted_id_fg = 1 AND
					cataloged_item.collection_object_id = <cfqueryparam value="#collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
			</cfquery>
			<cfquery name="accnMedia" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" >
					SELECT 
						media.media_id,
						media.media_uri,
						media.mime_type,
						media.media_type,
						media.preview_uri,
						label_value descr 
					FROM 
						media,
						media_relations,
						(select media_id,label_value from media_labels where media_label='description') media_labels 
					WHERE 
						media.media_id=media_relations.media_id and
						media.media_id=media_labels.media_id (+) and
						media_relations.media_relationship like '% accn' and
						media_relations.related_primary_key = <cfqueryparam value="#one.collection_object_id#" cfsqltype="CF_SQL_DECIMAL"> and
						MCZBASE.is_media_encumbered(media.media_id) < 1
				</cfquery>
					<ul class="list-group list-group-flush pl-0 pt-1">
						<li class="list-group-item pt-0"><h5 class="mb-0 d-inline-block">Accession:</h5>
							<cfif oneOfUs is 1>
								<a href="/transactions/Accession.cfm?action=edit&transaction_id=#one.accn_id#" target="_blank">#one.Accn_number#</a>
								<cfelse>
								#one.accn_number#
							</cfif>
							<cfif accnMedia.recordcount gt 0>
								<cfloop query="accnMedia">
									<div class="m-2 d-inline"> 
										<cfset mt = #media_type#>
										<a href="/media/#media_id#" target="_blank">
											<img src="#getMediaPreview('preview_uri','media_type')#" class="d-block border rounded" width="100" alt="#descr#">Media Details
										</a>
										<span class="small d-block">#media_type# (#mime_type#)</span>
										<span class="small d-block">#descr#</span> 
									</div>
								</cfloop>
							</cfif>
						</li>
						<!--------------------  Project / Usage ------------------------------------>	
						
						<cfquery name="isProj" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							SELECT 
								project_name, project.project_id project_id 
							FROM
								project left join project_trans on project.project_id = project_trans.project_id
							WHERE
								project_trans.transaction_id = <cfqueryparam value="#one.accn_id#" cfsqltype="CF_SQL_DECIMAL">
							GROUP BY project_name, project.project_id
						</cfquery>
						<cfquery name="isLoan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							SELECT 
								project_name, project.project_id 
							FROM 
								loan_item,
								project,
								project_trans,
								specimen_part 
							WHERE 
								specimen_part.derived_from_cat_item = <cfqueryparam value="#one.collection_object_id#" cfsqltype="CF_SQL_DECIMAL"> AND
								loan_item.transaction_id=project_trans.transaction_id AND
								project_trans.project_id=project.project_id AND
								specimen_part.collection_object_id = loan_item.collection_object_id 
							GROUP BY 
								project_name, project.project_id
						</cfquery>
						<cfquery name="isLoanedItem" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							SELECT 
								loan_item.collection_object_id 
							FROM 
								loan_item,specimen_part 
							WHERE 
								loan_item.collection_object_id=specimen_part.collection_object_id AND
								specimen_part.derived_from_cat_item = <cfqueryparam value="#one.collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
						</cfquery>
						<cfquery name="loanList" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							SELECT 
								distinct loan_number, loan_type, loan_status, loan.transaction_id 
							FROM
								specimen_part left join loan_item on specimen_part.collection_object_id=loan_item.collection_object_id
								left join loan on loan_item.transaction_id = loan.transaction_id
							WHERE
								loan_number is not null AND
								specimen_part.derived_from_cat_item = <cfqueryparam value="#one.collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
						</cfquery>
						<cfquery name="isDeaccessionedItem" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							SELECT 
								deacc_item.collection_object_id 
							FROM
								specimen_part left join deacc_item on specimen_part.collection_object_id=deacc_item.collection_object_id
							WHERE
								specimen_part.derived_from_cat_item = <cfqueryparam value="#one.collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
						</cfquery>
						<cfquery name="deaccessionList" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							SELECT 
								distinct deacc_number, deacc_type, deaccession.transaction_id 
							FROM
								specimen_part left join deacc_item on specimen_part.collection_object_id=deacc_item.collection_object_id
								left join deaccession on deacc_item.transaction_id = deaccession.transaction_id
							where
								deacc_number is not null AND
								specimen_part.derived_from_cat_item = <cfqueryparam value="#one.collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
						</cfquery>
						<cfif isProj.recordcount gt 0 OR isLoan.recordcount gt 0 or (oneOfUs is 1 and isLoanedItem.collection_object_id gt 0) or (oneOfUs is 1 and isDeaccessionedItem.collection_object_id gt 0)>
							<cfloop query="isProj">
								<li class="list-group-item pt-0"><h5 class="mb-0 d-inline-block">Contributed By Project:</h5>
									<a href="/ProjectDetail.cfm?src=proj&project_id=#isProj.project_id#">#isProj.project_name#</a> </li>
							</cfloop>
							<cfloop query="isLoan">
								<li class="list-group-item pt-0"><h5 class="mb-0 d-inline-block">Used By Project:</h5> 
									<a href="/ProjectDetail.cfm?src=proj&project_id=#isLoan.project_id#" target="_mainFrame">#isLoan.project_name#</a> 
								</li>
							</cfloop>
							<cfif isLoanedItem.collection_object_id gt 0 and oneOfUs is 1>
								<li class="list-group-item pt-0">
									<h5 class="mb-0 d-inline-block">Loan History:</h5>
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
								<li class="list-group-item">
									<h5 class="mb-1 d-inline-block">Deaccessions: </h5>
									<a href="/Deaccession.cfm?action=listDeacc&collection_object_id=#valuelist(isDeaccessionedItem.collection_object_id)#" target="_mainFrame">Deaccessions that include this cataloged item (#deaccessionList.recordcount#).</a> &nbsp;
									<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_transactions")>
										<cfloop query="deaccessionList">
											<ul class="d-block">
												<li class="d-block"> <a href="/Deaccession.cfm?action=editDeacc&transaction_id=#deaccessionList.transaction_id#">#deaccessionList.deacc_number# (#deaccessionList.deacc_type#)</a></li>
											</ul>
										</cfloop>
									</cfif>
								</li>
							</cfif>
						</cfif>
					</ul>
			<cfcatch>
				<cfif isDefined("cfcatch.queryError") >
					<cfset queryError=cfcatch.queryError>
				<cfelse>
					<cfset queryError = ''>
				</cfif>
				<cfset message = trim("Error processing #GetFunctionCalledName()#: " & cfcatch.message & " " & cfcatch.detail & " " & queryError) >
				<cfcontent reset="yes">
				<cfheader statusCode="500" statusText="#message#">
				<div class="container">
					<div class="row">
						<div class="alert alert-danger" role="alert">
							<img src="/shared/images/Process-stop.png" alt="[ error ]" style="float:left; width: 50px;margin-right: 1em;">
							<h2>Internal Server Error.</h2>
							<p>#message#</p>
							<p><a href="/info/bugs.cfm">“Feedback/Report Errors”</a></p>
						</div>
					</div>
				</div>
			</cfcatch>
		</cftry>
	</cfoutput>
	</cfthread>
	<cfthread action="join" name="getTransactionsThread" />
	<cfreturn getTransactionsThread.output>
</cffunction>
						
<cffunction name="getLocalityHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfthread name="getLocalityThread">
		<cfquery name="getLoc" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			SELECT
				cataloged_item.collection_object_id,
				cataloged_item.cat_num,
				collection.collection_cde,
				cataloged_item.accn_id,
				collection.collection,
				identification.scientific_name,
				identification.identification_remarks,
				identification.identification_id,
				identification.made_date,
				identification.nature_of_id,
				collecting_event.collecting_event_id,
				case when
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#oneOfUs#"> != 1 
					and concatencumbrances(cataloged_item.collection_object_id) like '%mask year collected%' 
				then
						replace(began_date,substr(began_date,1,4),'8888')
				else
					collecting_event.began_date
				end began_date,
				case when
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#oneOfUs#"> != 1 
					and concatencumbrances(cataloged_item.collection_object_id) like '%mask year collected%' 
				then
						replace(ended_date,substr(ended_date,1,4),'8888')
				else
					collecting_event.ended_date
				end ended_date,
				case when
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#oneOfUs#"> != 1 
					and concatencumbrances(cataloged_item.collection_object_id) like '%mask year collected%' 
				then
						'Masked'
				else
					collecting_event.verbatim_date
				end verbatim_date,
				collecting_event.startDayOfYear,
				collecting_event.endDayOfYear,
				collecting_event.habitat_desc,
				case when
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#oneOfUs#"> != 1 
					and concatencumbrances(cataloged_item.collection_object_id) like '%mask coordinates%' 
					and collecting_event.coll_event_remarks is not null
				then 
					'Masked'
				else
					collecting_event.coll_event_remarks
				end COLL_EVENT_REMARKS,
				locality.locality_id,
				locality.minimum_elevation,
				locality.maximum_elevation,
				locality.orig_elev_units,
				case when
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#oneOfUs#"> != 1
					and concatencumbrances(cataloged_item.collection_object_id) like '%mask coordinates%' 
					and locality.spec_locality is not null
				then 
					'Masked'
				else
					locality.spec_locality
				end spec_locality,
				case when
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#oneOfUs#"> != 1
					and concatencumbrances(cataloged_item.collection_object_id) like '%mask coordinates%'
					and accepted_lat_long.orig_lat_long_units is not null
				then 
					'Masked'
				else
					decode(accepted_lat_long.orig_lat_long_units,
						'decimal degrees',to_char(accepted_lat_long.dec_lat) || '&deg; ',
						'deg. min. sec.', to_char(accepted_lat_long.lat_deg) || '&deg; ' ||
							to_char(accepted_lat_long.lat_min) || '&acute; ' ||
							decode(accepted_lat_long.lat_sec, null,  '', to_char(accepted_lat_long.lat_sec) || '&acute;&acute; ') || accepted_lat_long.lat_dir,
						'degrees dec. minutes', to_char(accepted_lat_long.lat_deg) || '&deg; ' ||
							to_char(accepted_lat_long.dec_lat_min) || '&acute; ' || accepted_lat_long.lat_dir
					)
				end VerbatimLatitude,
				case when
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#oneOfUs#"> != 1 
					and concatencumbrances(cataloged_item.collection_object_id) like '%mask coordinates%' 
					and accepted_lat_long.orig_lat_long_units is not null
				then 
					'Masked'
				else
					decode(accepted_lat_long.orig_lat_long_units,
						'decimal degrees',to_char(accepted_lat_long.dec_long) || '&deg;',
						'deg. min. sec.', to_char(accepted_lat_long.long_deg) || '&deg; ' ||
							to_char(accepted_lat_long.long_min) || '&acute; ' ||
							decode(accepted_lat_long.long_sec, null, '', to_char(accepted_lat_long.long_sec) || '&acute;&acute; ') || accepted_lat_long.long_dir,
						'degrees dec. minutes', to_char(accepted_lat_long.long_deg) || '&deg; ' ||
							to_char(accepted_lat_long.dec_long_min) || '&acute; ' || accepted_lat_long.long_dir
					)
				end VerbatimLongitude,
				locality.sovereign_nation,
				collecting_event.verbatimcoordinates,
				collecting_event.verbatimlatitude verblat,
				collecting_event.verbatimlongitude verblong,
				collecting_event.verbatimcoordinatesystem,
				collecting_event.verbatimSRS,
				accepted_lat_long.dec_lat,
				accepted_lat_long.dec_long,
				accepted_lat_long.max_error_distance,
				accepted_lat_long.max_error_units,
				accepted_lat_long.determined_date latLongDeterminedDate,
				accepted_lat_long.lat_long_ref_source,
				accepted_lat_long.lat_long_remarks,
				accepted_lat_long.orig_lat_long_units,
				accepted_lat_long.datum,
				latLongAgnt.agent_name latLongDeterminer,
				geog_auth_rec.geog_auth_rec_id,
				geog_auth_rec.continent_ocean,
				geog_auth_rec.country,
				geog_auth_rec.state_prov,
				geog_auth_rec.quad,
				geog_auth_rec.county,
				geog_auth_rec.island,
				geog_auth_rec.island_group,
				geog_auth_rec.sea,
				geog_auth_rec.feature,
				coll_object.coll_object_entered_date,
				coll_object.last_edit_date,
				coll_object.flags,
				coll_object_remark.coll_object_remarks,
				coll_object_remark.disposition_remarks,
				coll_object_remark.associated_species,
				coll_object_remark.habitat,
				enteredPerson.agent_name EnteredBy,
				editedPerson.agent_name EditedBy,
				accn_number accession,
				concatencumbrances(cataloged_item.collection_object_id) concatenatedEncumbrances,
				concatEncumbranceDetails(cataloged_item.collection_object_id) encumbranceDetail,
				case when
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#oneOfUs#"> != 1 
					and concatencumbrances(cataloged_item.collection_object_id) like '%mask coordinates%'
					and locality.locality_remarks is not null
				then 
					'Masked'
				else
						locality.locality_remarks
				end locality_remarks,
				case when
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#oneOfUs#"> != 1
					and concatencumbrances(cataloged_item.collection_object_id) like '%mask coordinates%' 
					and verbatim_locality is not null
				then 
					'Masked'
				else
					verbatim_locality
				end verbatim_locality,
				collecting_time,
				fish_field_number,
				min_depth,
				max_depth,
				depth_units,
				collecting_method,
				collecting_source,
				specimen_part.derived_from_cat_item,
				decode(trans.transaction_id, null, 0, 1) vpdaccn
			FROM
				cataloged_item,
				collection,
				identification,
				collecting_event,
				locality,
				accepted_lat_long,
				preferred_agent_name latLongAgnt,
				geog_auth_rec,
				coll_object,
				coll_object_remark,
				preferred_agent_name enteredPerson,
				preferred_agent_name editedPerson,
				accn,
				trans,
				specimen_part
			WHERE
				cataloged_item.collection_id = collection.collection_id AND
				cataloged_item.collection_object_id = identification.collection_object_id AND
				identification.accepted_id_fg = 1 AND
				cataloged_item.collecting_event_id = collecting_event.collecting_event_id AND
				collecting_event.locality_id = locality.locality_id  AND
				locality.geog_auth_rec_id = geog_auth_rec.geog_auth_rec_id AND
				cataloged_item.collection_object_id = coll_object.collection_object_id AND
				coll_object.entered_person_id = enteredPerson.agent_id AND
				cataloged_item.accn_id =  accn.transaction_id  AND
				cataloged_item.collection_object_id = specimen_part.derived_from_cat_item AND
				locality.locality_id = accepted_lat_long.locality_id (+) AND
				accepted_lat_long.determined_by_agent_id = latLongAgnt.agent_id (+) AND
				coll_object.last_edited_person_id = editedPerson.agent_id (+) AND
				coll_object.collection_object_id = coll_object_remark.collection_object_id (+) AND
				accn.transaction_id = trans.transaction_id(+) AND
				cataloged_item.collection_object_id = <cfqueryparam value="#collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
		</cfquery>
		<cfquery name="localityMedia"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select
				media_id
			from
				media_relations
			where
				RELATED_PRIMARY_KEY= <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getLoc.locality_id#"> and
				MEDIA_RELATIONSHIP like '% locality'
		</cfquery>
		<script>
		/*map customization and polygon functionality commented  out for now. This will be useful as we implement more features -bkh*/
		jQuery(document).ready(function() {
			mapsYo();
		});
			function mapsYo(){
				$("input[id^='coordinates_']").each(function(e){
					var locid=this.id.split('_')[1];
					var coords=this.value;
					var bounds = new google.maps.LatLngBounds();
					var polygonArray = [];
					var ptsArray=[];
					var lat=coords.split(',')[0];
					var lng=coords.split(',')[1];
					var errorm=$("#error_" + locid).val();
					var mapOptions = {
						zoom: 1,
						center: new google.maps.LatLng(lat, lng),
						mapTypeId: google.maps.MapTypeId.ROADMAP,
						panControl: false,
						scaleControl: false,
						fullscreenControl: false,
						zoomControl: false
					};
					var map = new google.maps.Map(document.getElementById("mapdiv_" + locid), mapOptions);

					var center=new google.maps.LatLng(lat,lng);
					var marker = new google.maps.Marker({
						position: center,
						map: map,
						zIndex: 10
					});
					bounds.extend(center);
					if (parseInt(errorm)>0){
						var circleoptn = {
							strokeColor: '#FF0000',
							strokeOpacity: 0.8,
							strokeWeight: 2,
							fillColor: '#FF0000',
							fillOpacity: 0.15,
							map: map,
							center: center,
							radius: parseInt(errorm),
							zIndex:-99
						};
						crcl = new google.maps.Circle(circleoptn);
						bounds.union(crcl.getBounds());
					}
					// WKT can be big and slow, so async fetch
					$.get( "/component/utilities.cfc?returnformat=plain&method=getGeogWKT&locality_id=" + locid, function( wkt ) {
						  if (wkt.length>0){
							var regex = /\(([^()]+)\)/g;
							var Rings = [];
							var results;
							while( results = regex.exec(wkt) ) {
								Rings.push( results[1] );
							}
							for(var i=0;i<Rings.length;i++){
								// for every polygon in the WKT, create an array
								var lary=[];
								var da=Rings[i].split(",");
								for(var j=0;j<da.length;j++){
									// push the coordinate pairs to the array as LatLngs
									var xy = da[j].trim().split(" ");
									var pt=new google.maps.LatLng(xy[1],xy[0]);
									lary.push(pt);
									//console.log(lary);
									bounds.extend(pt);
								}
								// now push the single-polygon array to the array of arrays (of polygons)
								ptsArray.push(lary);
							}
							var poly = new google.maps.Polygon({
								paths: ptsArray,
								strokeColor: '#1E90FF',
								strokeOpacity: 0.8,
								strokeWeight: 2,
								fillColor: '#1E90FF',
								fillOpacity: 0.35
							});
							poly.setMap(map);
							polygonArray.push(poly);
							// END this block build WKT
							} else {
								$("#mapdiv_" + locid).addClass('noWKT');
							}
							if (bounds.getNorthEast().equals(bounds.getSouthWest())) {
							   var extendPoint1 = new google.maps.LatLng(bounds.getNorthEast().lat() + 0.05, bounds.getNorthEast().lng() + 0.05);
							   var extendPoint2 = new google.maps.LatLng(bounds.getNorthEast().lat() - 0.05, bounds.getNorthEast().lng() - 0.05);
							   bounds.extend(extendPoint1);
							   bounds.extend(extendPoint2);
							}
							map.fitBounds(bounds);
							for(var a=0; a<polygonArray.length; a++){
								if  (! google.maps.geometry.poly.containsLocation(center, polygonArray[a]) ) {
									$("#mapdiv_" + locid).addClass('uglyGeoSPatData');
								} else {
									$("#mapdiv_" + locid).addClass('niceGeoSPatData');
								}
							}
						});
						map.fitBounds(bounds);
				});
			}
		</script>
		<cfoutput>
			<cftry>
				<div class="col-12 col-md-5 pl-md-0 mb-2 float-right">
					<!---<img src="/specimens/images/map.png" height="auto" class="w-100 p-1 bg-white mt-2" alt="map placeholder"/>--->
					<cfif len(getLoc.dec_lat) gt 0 and len(getLoc.dec_long) gt 0>
						<cfset coordinates="#getLoc.dec_lat#,#getLoc.dec_long#">
						<input type="hidden" id="coordinates_#getLoc.locality_id#" value="#coordinates#">
						<input type="hidden" id="error_#getLoc.locality_id#" value="1196">
						<div id="mapdiv_#getLoc.locality_id#" class="tinymap" style="width:100%;height:180px;"></div>
						<!---span class="infoLink mapdialog">map key/tools</div--->
					</cfif>
					<cfif not isdefined("collection_object_id") or not isnumeric(collection_object_id)>
						<div class="error"> Improper call. Aborting..... </div>
						<cfabort>
					</cfif>
					<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
						<cfset oneOfUs = 1>
					<cfelse>
						<cfset oneOfUs = 0>
					</cfif>
					<!---<cfif oneOfUs is 0 and cgi.CF_TEMPLATE_PATH contains "/specimens/SpecimenDetailBody.cfm"></cfif>--->
				</div>
				<div class="col-7 px-0 float-left">
					<ul class="sd list-unstyled row mx-0 px-3 py-1 mb-0">
						<cfif len(getLoc.continent_ocean) gt 0>
							<li class="list-group-item col-5 px-0"><em>Continent or Ocean:</em></li>
							<li class="list-group-item col-7 px-0">#getLoc.continent_ocean#</li>
						</cfif>
						<cfif len(getLoc.sea) gt 0>
							<li class="list-group-item col-5 px-0"><em>Sea:</em></li>
							<li class="list-group-item col-7 px-0">#getLoc.sea#</li>
						</cfif>
						<cfif len(getLoc.country) gt 0>
							<li class="list-group-item col-5 px-0"><em>Country:</em></li>
							<li class="list-group-item col-7 px-0">#getLoc.country#</li>
						</cfif>
						<cfif len(getLoc.state_prov) gt 0>
							<li class="list-group-item col-5 px-0"><em>State:</em></li>
							<li class="list-group-item col-7 px-0">#getLoc.state_prov#</li>
						</cfif>
						<cfif len(getLoc.feature) gt 0>
							<li class="list-group-item col-5 px-0"><em>Feature:</em></li>
							<li class="list-group-item col-7 px-0">#getLoc.feature#</li>
						</cfif>
						<cfif len(getLoc.county) gt 0>
							<li class="list-group-item col-5 px-0"><em>County:</em></li>
							<li class="list-group-item col-7 px-0">#getLoc.county#</li>
						</cfif>
						<cfif len(getLoc.island_group) gt 0>
							<li class="list-group-item col-5 px-0"><em>Island Group:</em></li>
							<li class="list-group-item col-7 px-0">#getLoc.island_group#</li>
						</cfif>
						<cfif len(getLoc.island) gt 0>
							<li class="list-group-item col-5 px-0"><em>Island:</em></li>
							<li class="list-group-item col-7 px-0">#getLoc.island#</li>
						</cfif>
						<cfif len(getLoc.quad) gt 0>
							<li class="list-group-item col-5 px-0"><em>Quad:</em></li>
							<li class="list-group-item col-7 px-0">#getLoc.quad#</li>
						</cfif>
					</ul>
					<cfif listcontainsnocase(session.roles,"manage_specimens")>
						<div class="w-75 border">
							<button type="button" class="btn btn-xs btn-primary mx-2 float-left pt-0">Higher Geography</button>
							<button type="button" class="btn btn-xs btn-primary  mx-2 float-left pt-0 ">Specific Locality</button>
						</div>
					</cfif>
				</div>
				<div class="col-12 float-left px-0">
					<ul class="sd list-unstyled bg-light row mx-0 px-3 py-1 mb-0 border-top">
						<cfif len(getLoc.spec_locality) gt 0>
							<li class="list-group-item col-5 px-0"><h5 class="my-0">Specific Locality: </h5></li>
							<li class="list-group-item col-7 px-0 last">#getLoc.spec_locality#</li>
						</cfif>
						<cfif len(getLoc.verbatim_locality) gt 0>
							<li class="list-group-item col-5 px-0"><h5 class="my-0">Verbatim Locality: </h5></li>
							<li class="list-group-item col-7 px-0 ">#getLoc.verbatim_locality#</li>
						</cfif>
						<cfif len(getLoc.collecting_source) gt 0>
							<li class="list-group-item col-5 px-0"><h5 class="my-0">Collecting Source: </h5></li>
							<li class="list-group-item col-7 px-0">#getLoc.collecting_source#</li>
						</cfif>
						<!--- TODO: Display dwcEventDate not underlying began/end dates. --->
						<cfif len(getLoc.began_date) gt 0 AND getLoc.began_date eq #getLoc.ended_date#>
							<li class="list-group-item col-5 px-0"><h5 class="my-0">Collected On: </h5></li>
							<li class="list-group-item col-7 px-0">#getLoc.began_date#</li>
						</cfif>
						<cfif len(getLoc.began_date) gt 0 AND getLoc.began_date neq #getLoc.ended_date#>
							<li class="list-group-item col-5 px-0"><h5 class="my-0">Began Date / Ended Date: </h5></li>
							<li class="list-group-item col-7 px-0">#getLoc.began_date# / #getLoc.ended_date#</li>
						</cfif>
						<cfif len(getLoc.verbatim_date) gt 0>
							<li class="list-group-item col-5 px-0"><h5 class="my-0">Verbatim Date: </h5></li>
							<li class="list-group-item col-7 px-0">#getLoc.verbatim_date#</li>
						</cfif>
						<cfif len(getLoc.verbatimcoordinates) gt 0>
							<li class="list-group-item col-5 px-0"><h5 class="my-0">Verbatim Coordinates: </h5></li>
							<li class="list-group-item col-7 px-0">#getLoc.verbatimcoordinates#</li>
						</cfif>
						<cfif len(getLoc.collecting_method) gt 0>
							<li class="list-group-item col-5 px-0"><h5 class="my-0">Collecting Method: </h5></li>
							<li class="list-group-item col-7 px-0">#getLoc.collecting_method#</li>
						</cfif>
						<cfif len(getLoc.coll_event_remarks) gt 0>
							<li class="list-group-item col-5 px-0"><h5 class="my-0">Collecting Event Remarks: </h5></li>
							<li class="list-group-item col-7 px-0">#getLoc.coll_event_remarks#</li>
						</cfif>
						<cfif len(getLoc.habitat_desc) gt 0>
							<li class="list-group-item col-5 px-0"><h5 class="my-0">Habitat Description: </h5></li>
							<li class="list-group-item col-7 px-0">#getLoc.habitat_desc#</li>
						</cfif>
						<cfif len(getLoc.habitat) gt 0>
							<li class="list-group-item col-5 px-0"><h5 class="my-0">Microhabitat: </h5></li>
							<li class="list-group-item col-7 px-0">#getLoc.habitat#</li>
						</cfif>
						<cfif len(getLoc.dec_lat) gt 0>
							<li class="list-group-item col-5 px-0"><h5 class="my-0">Decimal Latitude, Longitude: </h5></li>
							<li class="list-group-item col-7 px-0">#getLoc.dec_lat#, #getLoc.dec_long# (error: #getLoc.max_error_distance##getLoc.max_error_units#)</li>
							<li class="list-group-item col-5 px-0"><h5 class="my-0">Coordinates Originally Recorded as: </h5></li>
							<li class="list-group-item col-7 px-0">#getLoc.orig_lat_long_units# (datum: #getLoc.datum#)</li>
						</cfif>
<!---						<cfif localityMedia.recordcount gt 0>
							<cfset locBlock= getMediaBlockHtml(media_id="#localityMedia.media_id#",size="350",captionAs="textCaption")>
							<div id="locBlock#localityMedia.media_id#">
								#locBlock#
							</div>
						</cfif>--->
					</ul>
				</div>
					<cfcatch>
						<cfif isDefined("cfcatch.queryError") >
							<cfset queryError=cfcatch.queryError>
						<cfelse>
							<cfset queryError = ''>
						</cfif>
						<cfset message = trim("Error processing #GetFunctionCalledName()#: " & cfcatch.message & " " & cfcatch.detail & " " & queryError) >
						<cfcontent reset="yes">
						<cfheader statusCode="500" statusText="#message#">
						<div class="container">
							<div class="row">
								<div class="alert alert-danger" role="alert"> <img src="/shared/images/Process-stop.png" alt="[ error ]" style="float:left; width: 50px;margin-right: 1em;">
								<h2>Internal Server Error.</h2>
									<p>#message#</p>
									<p><a href="/info/bugs.cfm">“Feedback/Report Errors”</a></p>
								</div>
							</div>
						</div>
					</cfcatch>
			</cftry>
		</cfoutput> 
	</cfthread>
	<cfthread action="join" name="getLocalityThread" />
	<cfreturn getLocalityThread.output>
</cffunction>
							
<cffunction name="getCollectorsHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfthread name="getCollectorsThread">
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
			<cfquery name="colls" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT
					collector.agent_id,
					collector.coll_order,
					case when
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#oneOfUs#"> != 1 and concatencumbrances(collector.collection_object_id) like '%mask collector%' then 'Anonymous'
					else
						preferred_agent_name.agent_name
					end collectors
				FROM
					collector,
					preferred_agent_name
				WHERE
					collector.collector_role='c' and
					collector.agent_id=preferred_agent_name.agent_id and
					collector.collection_object_id = <cfqueryparam value="#collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
				ORDER BY
					coll_order
			</cfquery>
			<cfquery name="preps" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT
					collector.agent_id,
					collector.coll_order,
					case when
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#oneOfUs#"> != 1 and concatencumbrances(collector.collection_object_id) like '%mask preparator%' then 'Anonymous'
					else
						preferred_agent_name.agent_name
					end preparators
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
			<ul class="list-unstyled list-group form-row px-1 pt-1 mb-0">
				<cfif colls.recordcount gt 0>
					<cfif colls.recordcount eq 1>
						<li class="list-group-item pt-0"><h5 class="my-0 d-inline">Collector:&nbsp;</h5>
							<cfloop query="colls">
								<a href="/agents/Agent.cfm?agent_id=#colls.agent_id#">#colls.collectors#</a>
							</cfloop>
						</li>
					<cfelse>
						<li class="list-group-item pt-0"><h5 class="my-0 d-inline">Collectors:&nbsp;</h5>
							<cfloop query="colls">
								<a href="/agents/Agent.cfm?agent_id=#colls.agent_id#">#colls.collectors#</a><span class="sd">,</span>
							</cfloop>
						</li>
					</cfif>
				</cfif>
				<cfif preps.recordcount gt 0>
					<cfif preps.recordcount eq 1>
						<li class="list-group-item pt-0">
							<h5 class="my-0 d-inline">Preparator:&nbsp;</h5>
							<cfloop query="preps">
								<a href="/agents/Agent.cfm?agent_id=#preps.agent_id#">#preps.preparators#</a>
							</cfloop>
						</li>
					<cfelse>
						<li class="list-group-item pt-0">
							<h5 class="my-0 d-inline">Preparators:&nbsp;</h5>
							<cfloop query="preps">
								<a href="/agents/Agent.cfm?agent_id=#preps.agent_id#">#preps.preparators#</a><span class="sd">,</span>
							</cfloop>
						</li>
					</cfif>
				</ul>
				</cfif>
			<cfcatch>
				<cfif isDefined("cfcatch.queryError") >
					<cfset queryError=cfcatch.queryError>
				<cfelse>
					<cfset queryError = ''>
				</cfif>
				<cfset message = trim("Error processing #GetFunctionCalledName()#: " & cfcatch.message & " " & cfcatch.detail & " " & queryError) >
				<cfcontent reset="yes">
				<cfheader statusCode="500" statusText="#message#">
				<div class="container">
							<div class="row">
								<div class="alert alert-danger" role="alert">
									<img src="/shared/images/Process-stop.png" alt="[ error ]" style="float:left; width: 50px;margin-right: 1em;">
									<h2>Internal Server Error.</h2>
									<p>#message#</p>
									<p><a href="/info/bugs.cfm">“Feedback/Report Errors”</a></p>
								</div>
							</div>
						</div>
			</cfcatch>
		</cftry>
	</cfoutput>
	</cfthread>
	<cfthread action="join" name="getCollectorsThread"/>
	<cfreturn getCollectorsThread.output>
</cffunction>		
							
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
				<cfquery name="meta" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT
						cataloged_item.collection_object_id as collection_object_id,
						cataloged_item.cat_num,
						coll_object.coll_object_entered_date,
						coll_object.last_edit_date,
						collection.collection_cde,
						coll_object.flags,
						coll_object_remark.habitat, 
						coll_object_remark.associated_species, 
						coll_object_remark.disposition_remarks, 
						coll_object_remark.coll_object_remarks,
						enteredPerson.agent_name EnteredBy,
						editedPerson.agent_name EditedBy,
						concatencumbrances(cataloged_item.collection_object_id) concatenatedEncumbrances,
						concatEncumbranceDetails(cataloged_item.collection_object_id) encumbranceDetail
					FROM
						cataloged_item
						left join collection on cataloged_item.collection_id = collection.collection_id
						left join identification on cataloged_item.collection_object_id = identification.collection_object_id
						left join collecting_event on cataloged_item.collecting_event_id = collecting_event.collecting_event_id
						left join coll_object on cataloged_item.collection_object_id = coll_object.collection_object_id
						left join coll_object_remark on coll_object.collection_object_id = coll_object_remark.collection_object_id
						left join coll_object on coll_object.collection_object_id = coll_object_remark.collection_object_id
						left join preferred_agent_name enteredPerson on coll_object.entered_person_id = enteredPerson.agent_id
						left join preferred_agent_name editedPerson on coll_object.last_edited_person_id = editedPerson.agent_id
					WHERE
						cataloged_item.collection_object_id = <cfqueryparam value="#collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
				</cfquery>
					<ul class="list-group pl-0 pt-0">
						<cfif len(#meta.coll_object_remarks#) gt 0>
							<li class="list-group-item pt-0 pb-2">Remarks: #meta.coll_object_remarks# </li>
						</cfif>
						<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_specimens")>
							<cfif #meta.EditedBy# is not "unknown" OR len(#meta.last_edit_date#) is not 0>
								<li class="list-group-item pt-0"> Entered By: #meta.EnteredBy# on #dateformat(meta.coll_object_entered_date,"yyyy-mm-dd")# </li>
								<li class="list-group-item pt-0"> Last Edited By: #meta.EditedBy# on #dateformat(meta.last_edit_date,"yyyy-mm-dd")# </li>
							</cfif>
							<cfif len(#meta.flags#) is not 0>
								<li class="list-group-item"> Missing (flags): #one.flags# </li>
							</cfif>
							<cfif len(#meta.encumbranceDetail#) is not 0>
								<li class="list-group-item pt-0"> Encumbrances: #replace(meta.encumbranceDetail,";","<br>","all")# </li>
							</cfif>
						</cfif>
					</ul>
					
					<ul class="list-group list-group-flush p-0">
						<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_specimens")>
							<cfif len(meta.disposition_remarks) gt 0 >
								<li class="list-group-item pt-0">Disposition Remarks: #meta.disposition_remarks#</li>
							</cfif>
						</cfif>
						<cfif len(meta.associated_species) gt 0 >
							<li class="list-group-item pt-0">Associated Species: #meta.associated_species#</li>
						</cfif>
					</ul>
			<cfcatch>
					<cfif isDefined("cfcatch.queryError") >
						<cfset queryError=cfcatch.queryError>
					<cfelse>
						<cfset queryError = ''>
					</cfif>
					<cfset message = trim("Error processing #GetFunctionCalledName()#: " & cfcatch.message & " " & cfcatch.detail & " " & queryError) >
					<cfcontent reset="yes">
					<cfheader statusCode="500" statusText="#message#">
					<div class="container">
						<div class="row">
							<div class="alert alert-danger" role="alert">
								<img src="/shared/images/Process-stop.png" alt="[ error ]" style="float:left; width: 50px;margin-right: 1em;">
								<h2>Internal Server Error.</h2>
								<p>#message#</p>
								<p><a href="/info/bugs.cfm">“Feedback/Report Errors”</a></p>
							</div>
						</div>
					</div>
			</cfcatch>
		</cftry>
	</cfoutput>
	</cfthread>
	<cfthread action="join" name="getMetadataThread"/>
	<cfreturn getMetadataThread.output>
</cffunction>

<cffunction name="getNamedGroups" access="remote" returntype="any" returnformat="json">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfthread name="getNamedGroupsThread">
	<cfoutput>
		<cftry>
		<cfquery name="named_groups" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="named_groups">
			SELECT DISTINCT collection_name, underscore_relation.underscore_collection_id
			FROM
				underscore_collection
				left join underscore_relation on underscore_collection.underscore_collection_id = underscore_relation.underscore_collection_id
				left join flat on underscore_relation.collection_object_id = flat.collection_object_id
			WHERE flat.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
		</cfquery>
			<ul class="list-unstyled list-group form-row px-1 pt-1 mb-0">
				<cfif named_groups.recordcount eq 1>
					<li class="list-group-item pt-0">
						<cfloop query="named_groups">
							<a href= "/grouping/showNamedCollection.cfm?underscore_collection_id=#named_groups.underscore_collection_id#">#named_groups.collection_name#</a>
						</cfloop>
					</li>
				</cfif>
			</ul>
			<cfcatch>
			<cfif isDefined("cfcatch.queryError") >
				<cfset queryError=cfcatch.queryError>
			<cfelse>
				<cfset queryError = ''>
			</cfif>
				<cfset message = trim("Error processing #GetFunctionCalledName()#: " & cfcatch.message & " " & cfcatch.detail & " " & queryError) >
				<cfcontent reset="yes">
				<cfheader statusCode="500" statusText="#message#">
				<div class="container">
					<div class="row">
						<div class="alert alert-danger" role="alert">
							<img src="/shared/images/Process-stop.png" alt="[ error ]" style="float:left; width: 50px;margin-right: 1em;">
							<h2>Internal Server Error.</h2>
							<p>#message#</p>
							<p><a href="/info/bugs.cfm">“Feedback/Report Errors”</a></p>
						</div>
					</div>
				</div>
			</cfcatch>
		</cftry>
	</cfoutput>
	</cfthread>
	<cfthread action="join" name="getNamedGroupsThread"/>
	<cfreturn getNamedGroupsThread.output>
</cffunction>	
							

</cfcomponent>
>
