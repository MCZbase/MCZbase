<!---
Specimen.cfm

Copyright 2019-2022 President and Fellows of Harvard College

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
<!--- this page checks that a provided guid or collection_object_id matches a visible record, then displays the 
 top portion of the specimen details page, header, summary information/type bar, then the bulk of the body of the
 specimen details page, then the footer.
--->

<!--- (1) Check the provided guid or collection object id --->
<!--- Set page title to reflect failure condition, if queries succeed it will be changed to reflect specimen record found --->
<cfset pageTitle = "MCZbase Specimen not found.">

<cfif isdefined("collection_object_id")>
	<cfoutput>
		<cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select GUID 
			from <cfif ucase(session.flatTableName) EQ "FLAT"> flat <cfelse> filtered_flat </cfif>
			where collection_object_id = <cfqueryparam value="#collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
		</cfquery>
		<cfheader statuscode="301" statustext="Moved permanently">
		<cfset guid = c.GUID>
		<cfheader name="Location" value="/guid/#guid#">
		<cfabort>
	</cfoutput>
</cfif>
<cfif isdefined("guid")>
	<cfset pageTitle = "MCZbase Specimen not found: #guid#">
	<!---  Lookup the GUID, handling several possible variations --->

	<!---  Redirect from explicit Specimen Detail page to  to /guid/ --->
	<cfif cgi.script_name contains "/specimens/Specimen.cfm">
		<cfheader statuscode="301" statustext="Moved permanently">
		<cfheader name="Location" value="/guid/#guid#">
		<cfabort>
	</cfif>
	
	<!---  GUID is expected to be in the form MCZ:collectioncode:catalognumber --->
	<cfif guid contains ":">
		<cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="cresult">
			select collection_object_id 
			from <cfif ucase(session.flatTableName) EQ "FLAT"> flat <cfelse> filtered_flat </cfif>
			WHERE
				upper(guid) = <cfqueryparam value='#ucase(guid)#' cfsqltype="CF_SQL_VARCHAR">
		</cfquery>
	<cfelseif guid contains " ">
		<!--- TODO: Do we want to continue supporting guid={collection catalognumber}? --->
		<!--- TODO: NOTE: Existing MCZbase code is broken without trim on cn. --->
		<cfset spos=find(" ",reverse(guid))>
		<cfset cc=left(guid,len(guid)-spos)>
		<cfset cn=trim(right(guid,spos))>
		<cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="cfesult">
			select collection_object_id 
			from
				cataloged_item 
				left join collection on cataloged_item.collection_id = collection.collection_id 
			WHERE
				cat_num = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#cn#"> 
				AND lower(collection.collection) = <cfqueryparam value='#lcase(cc)#' cfsqltype="CF_SQL_VARCHAR" >
		</cfquery>
	</cfif>
	<cfif cresult.recordcount EQ 0>
		<!--- Record for this GUID was not found ---> 
		<cfinclude template="/errors/404.cfm">
		<cfabort>
	<cfelse>
		<!--- Record for this GUID was found, make the collection_object_id available to obtain specimen record details. ---> 
		<cfoutput query="c">
			<cfset collection_object_id=c.collection_object_id>
		</cfoutput>
	</cfif>
<cfelse>
	<cfinclude template="/errors/404.cfm">
	<cfabort>
</cfif>

<cfif findNoCase('master',Session.gitBranch) GT 0>
	<cfthrow message="Not for production use yet.">
</cfif>

<!--- (2) Look up summary and type information on the specimen --->
<!---  TODO: Refactor this to obtain live data --->
<cfquery name="detail" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	SELECT DISTINCT
		flattable.collection,
		web_link,
		flattable.collection_id,
		flattable.cat_num,
		flattable.collection_object_id as collection_object_id,
		flattable.scientific_name,
		flattable.full_taxon_name,
		flattable.collecting_event_id,
		flattable.higher_geog,
		flattable.collectors,
		flattable.spec_locality,
<!---added--->	flattable.locality_id,flattable.geog_auth_rec_id,flattable.continent_ocean,flattable.sea,flattable.country,flattable.state_prov,flattable.feature,flattable.county,flattable.island_group,flattable.island,flattable.quad,collecting_event.verbatim_locality,collecting_event.verbatimcoordinates,collecting_event.collecting_method,collecting_event.coll_event_remarks,collecting_event.habitat_desc,flattable.habitat,flattable.locality_remarks,flattable.verbatim_date,collecting_event.BEGAN_DATE,collecting_event.ended_date,flattable.collecting_source,flattable.depth_units,flattable.maximum_elevation,flattable.minimum_elevation,flattable.max_depth,flattable.min_depth,accepted_lat_long.determined_date latLongDeterminedDate,latLongAgnt.agent_name latLongDeterminer,accepted_lat_long.max_error_distance,accepted_lat_long.max_error_units,flattable.lat_long_ref_source,flattable.orig_lat_long_units,flattable.datum,flattable.orig_elev_units,
<!---end addition--->		
		case flattable.author_text  when 'undefinable' then '' else flattable.author_text end as author_text,
		flattable.cited_as,
		flattable.typestatuswords,
		MCZBASE.concattypestatus_plain_s(flattable.collection_object_id,1,1,0) as typestatusplain,
		flattable.toptypestatuskind,
		concatparts_ct(flattable.collection_object_id) as partString,
		concatEncumbrances(flattable.collection_object_id) as encumbrance_action,
		flattable.dec_lat,
		flattable.dec_long,
		flattable.COORDINATEUNCERTAINTYINMETERS
<!---	<cfif len(#session.CustomOtherIdentifier#) gt 0>
		,concatSingleOtherId(#session.flatTableName#.collection_object_id,'#session.CustomOtherIdentifier#') as CustomID
		</cfif>--->
	FROM
		<cfif ucase(session.flatTableName) EQ "FLAT"> flat <cfelse> filtered_flat </cfif> flattable
		left join collection on flattable.collection_id = collection.collection_id
		<!---added below--->
		left join collecting_event on flattable.collecting_event_id = collecting_event.collecting_event_id
		left join accepted_lat_long on collecting_event.locality_id = accepted_lat_long.locality_id
		left join preferred_agent_name latLongAgnt on accepted_lat_long.determined_by_agent_id = latLongAgnt.agent_id
	WHERE
		flattable.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
		AND rownum < 2 
	ORDER BY
		cat_num
</cfquery>

<!--- (3) Display the page header ---> 
<!--- Successfully found a specimen, set the pageTitle and call the header to reflect this, then show the details ---> 
<cfset addedMetaDescription="Specimen Record for: #guid# in the #detail.collection# collection; #detail.scientific_name#; #detail.higher_geog#; #detail.spec_locality#">
<cfset addedKeywords=",#detail.full_taxon_name#,#detail.higher_geog#,#detail.typestatuswords#">
<cfset pageTitle = "MCZbase #guid# specimen details">
<cfinclude template="/shared/_header.cfm">
<cfif not isdefined("session.sdmapclass") or len(session.sdmapclass) is 0>
	<cfset session.sdmapclass='tinymap'>
</cfif>
<cfoutput>
	<cfhtmlhead text='<script src="#Application.protocol#://maps.googleapis.com/maps/api/js?key=#application.gmap_api_key#&libraries=geometry" type="text/javascript"></script>'>
</cfoutput>

<!--- (4) Display the summary/type bar for the record --->
<cfif detail.recordcount LT 1>
	<!--- It shouldn't be possible to reach here, the logic early in the page should catch this condition. --->
	<cfinclude template="/errors/404.cfm">
	<cfabort>
</cfif>

<cfoutput query="detail">
	<cfset typeName = typestatuswords>
	<!--- handle the edge cases of a specimen having more than one type status --->
	<cfif toptypestatuskind eq 'Primary' > 
		<cfset twotypes = '#replace(typestatusplain,"|"," &nbsp; <br> &nbsp; ","all")#'>
		<cfset typeName = '<span class="font-weight-bold bg-white pt-0 px-2 pb-1 text-center ml-xl-1"> #twotypes# </span>'>
	<cfelseif toptypestatuskind eq 'Secondary' >
		<cfset twotypes= '#replace(typestatusplain,"|"," &nbsp; <br> &nbsp; ","all")#'>
		<cfset typeName = '<span class="font-weight-bold bg-white pt-0 px-2 pb-1 text-center ml-xl-1"> #twotypes# </span>'>
	<cfelse>
		<cfset twotypes= '#replace(typestatusplain,"|"," &nbsp; <br> &nbsp; ","all")#'>
		<cfset typeName = '<span class="font-weight-bold bg-white pt-0 pb-1 px-2 text-center ml-xl-1"> </span>'>
	</cfif>
	<div class="container-fluid" id="content">
		<cfif isDefined("cited_as") and len(cited_as) gt 0>
			<cfif toptypestatuskind eq 'Primary' >
				<cfset sectionclass="primaryType">
			<cfelseif toptypestatuskind eq 'Secondary' >
				<cfset sectionclass="secondaryType">
			</cfif>
		<cfelse>
			<cfset sectionclass="defaultType">
		</cfif>
		<section class="row #sectionclass#">
			<div class="col-12">
				<cfif isDefined("cited_as") and len(cited_as) gt 0>
					<cfif toptypestatuskind eq 'Primary' >
						<cfset divclass="border-0">
					<cfelseif toptypestatuskind eq 'Secondary' >
						<cfset divclass="no-card">
					</cfif>
				<cfelse>
					<cfset divclass="no-card">
				</cfif>
				<div class="card box-shadow #divclass# bg-transparent">
					<div class="row mx-0">
						<cfif len(web_link) GT 0>
							<cfset collection_heading = "<a href='#web_link#'>#collection#</a>">
						<cfelse>
							<cfset collection_heading = "#web_link#">
						</cfif>
						<h1 class="col-12 col-md-6 mb-0 h4">#collection_heading#&nbsp;#cat_num#</h1>
						<div class="float-right col-12 ml-auto col-md-6 my-2 w-auto">
							occurrenceId: <a class="h5" href="https://mczbase.mcz.harvard.edu/guid/#GUID#">https://mczbase.mcz.harvard.edu/guid/#GUID#</a>
						</div>
					</div>
					<div class="row mx-0">
						<div class="col-12 col-md-6">
							<h2 class="mt-0 px-0">
								<a class="font-italic text-dark font-weight-bold" href="##">#scientific_name#</a>&nbsp;<span class="sm-caps h3">#author_text#</span>
							</h2>
						</div>
						<div class="col-12 col-md-6 mt-0 mb-2">
							<cfif isDefined("cited_as") and len(cited_as) gt 0>
								<cfif toptypestatuskind eq 'Primary' >
									<h2 class="h4 mt-0">#typeName#</h2>
								</cfif>
								<cfif toptypestatuskind eq 'Secondary'>
									<h2 class="h4 mt-0">#typeName#</h2>
								</cfif>
							<cfelse>
								<!--- No type name to display for non-type specimens --->
							</cfif>	
						</div>
					</div>
				</div>
			</div>
		</section>
	</div>
	<div class="container-fluid">
		<section class="row" id="resultSetNavigationSection">
			<div class="col-12 px-2">
				<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
					<!--- TODO: This handles navigation through a result set and will need to be refactored with redesign of specimen search/results handling --->
					<form name="incPg" method="post" action="/specimens/Specimen.cfm">
						<input type="hidden" name="collection_object_id" value="#collection_object_id#">
						<input type="hidden" name="suppressHeader" value="true">
						<input type="hidden" name="action" value="nothing">
						<input type="hidden" name="collecting_event_id" value="#detail.collecting_event_id#">
						<cfif isdefined("session.collObjIdList") and len(session.collObjIdList) gt 0>
							<cfset isPrev = "no">
							<cfset isNext = "no">
							<cfset currPos = 0>
							<cfset lenOfIdList = 0>
							<cfset firstID = collection_object_id>
							<cfset nextID = collection_object_id>
							<cfset prevID = collection_object_id>
							<cfset lastID = collection_object_id>
							<cfset currPos = listfind(session.collObjIdList,collection_object_id)>
							<cfset lenOfIdList = listlen(session.collObjIdList)>
							<cfset firstID = listGetAt(session.collObjIdList,1)>
							<cfif currPos lt lenOfIdList>
								<cfset nextID = listGetAt(session.collObjIdList,currPos + 1)>
							</cfif>
							<cfif currPos gt 1>
								<cfset prevID = listGetAt(session.collObjIdList,currPos - 1)>
							</cfif>
							<cfset lastID = listGetAt(session.collObjIdList,lenOfIdList)>
							<cfif lenOfIdList gt 1>
								<cfif currPos gt 1>
									<cfset isPrev = "yes">
								</cfif>
								<cfif currPos lt lenOfIdList>
									<cfset isNext = "yes">
								</cfif>
							</cfif>
						<cfelse>
							<cfset isNext="">
							<cfset isPrev="">
						</cfif>
					</form>
				</cfif>
			</div>					
		</section><!-- end resultSetNavivationSection --->
	</div>
</cfoutput>

<!--- (4) Bulk of the specimen page (formerly in SpecimenDetailBody) --->

<!--- TODO: Refactor these checks to earlier in the page --->
<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
	<cfset oneOfUs = 1>
	<cfelse>
	<cfset oneOfUs = 0>
</cfif>
<!--- Include the templates that contains functions used to load portions of this page --->
<cfinclude template="/specimens/component/public.cfc">
<cfinclude template="/media/component/search.cfc" runOnce="true">
<cfinclude template="/vocabularies/component/search.cfc" runOnce="true">
<!--- query getCatalogedItem is needed for determining what is public and what is partitioned --->
<cfquery name="getCatalogedItem" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	SELECT 
		cataloged_item.collection_object_id,
		cataloged_item.collection_cde,
		cataloged_item.cat_num,
		concatEncumbranceDetails(cataloged_item.collection_object_id) encumbranceDetail
	FROM
		cataloged_item
	WHERE
		cataloged_item.collection_object_id = <cfqueryparam value="#collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
</cfquery>
<cfif getCatalogedItem.recordcount EQ 0>
	<cfthrow message = "Error: Unable to find cataloged_item.collection_object_id = '#encodeForHtml(collection_object_id)#'">
</cfif>
<cfif getCatalogedItem.recordcount GT 1>
	<cfthrow message = "Error: multiple rows returned from query 'getCatalogedItem' for cataloged_item.collection_object_id = '#encodeForHtml(collection_object_id)#'">
</cfif>
<cfif getCatalogedItem.encumbranceDetail contains "mask record" and oneOfUs neq 1>
	<!--- it shouldn't be possible to reach this check, as it is preceeded by a query on session.flattablename which has the same effect --->
	<cfthrow message="Record masked.">
</cfif>
<cfset guid = "MCZ:#getCatalogedItem.collection_cde#:#getCatalogedItem.cat_num#">
<cfif oneOfUs NEQ 1 AND Findnocase("mask parts", getCatalogedItem.encumbranceDetail)>
	<cfset partCount="">
<cfelse>
	<cfquery name="countParts" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		SELECT
			count(specimen_part.collection_object_id) ct
		FROM
			specimen_part
		WHERE
			specimen_part.derived_from_cat_item = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getCatalogedItem.collection_object_id#"> 
	</cfquery>
	<cfset partCount=#countParts.ct#>
</cfif>
<cfoutput>
	<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_specimens")>
		<script type="text/javascript" src="/specimens/js/details.js"></script> 
		<!--- user can edit the specimen record --->
		<!--- scripts for reloading sections of pages after edits, use as callabcks on edit dialogs --->
		<script>
			function reloadMedia() { 
				// invoke specimen/component/public.cfc function getMediaHTML via ajax with relationship_type shows  and repopulate the specimen media block.
				loadMedia(#collection_object_id#,'specimenMediaCardBody');
			}
		</script>
		<script>
			function reloadIdentifications() { 
				// invoke specimen/component/public.cfc function getIdentificationHTML via ajax and repopulate the identification block.
				loadIdentifications(#collection_object_id#,'identificationsCardBody');
			}
		</script>
		<script>
			function reloadCitations() { 
				// replace the citations block via ajax.
				loadCitations(#collection_object_id#,'citationsCardBody');
				// replace the citation media block via ajax.
				loadCitationMedia(#collection_object_id#,'citationMediaBlock')'
			}
		</script>
		<script>
			function reloadOtherIDs() { 
				// invoke specimen/component/public.cfc function getOtherIDsHTML via ajax and repopulate the Other Identifiers block.
				loadOtherIDs(#collection_object_id#,'otherIDsCardBody');
			}
		</script>
		<script>
			function reloadParts() { 
				// reload the parts html block
				loadParts(#collection_object_id#,'partsCardBody');
				// Update part count
				loadPartCount(#collection_object_id#,'partCountSpan');
			}
		</script>
		<script>
			function reloadAttributes() { 
				// invoke specimen/component/public.cfc function getAttributesHTML via ajax and repopulate the attributes block.
				loadAttributes(#collection_object_id#,'attributesCardBody');
			}
		</script>
		<script>
			function reloadRemarks() { 
				loadRemarks(#collection_object_id#,'remarksCardBody');
			}
		</script>
		<script>
			function reloadLedger() { 
				// replace the ledger/field notes block via ajax.
				// invoke specimen/component/public.cfc function getMediaHTML via ajax with relationship_type documents.
				loadLedger(#collection_object_id#,'ledgerCardBody');
			}
		</script>
		<script>
			function reloadLocality() { 
				loadLocality(#collection_object_id#,'localityCardBody');
			}
		</script>
		<!--- controls for editing record --->
		<div class="container-lg d-none d-lg-block">
			<div class="row mt-2">
				<ul class="list-group list-inline list-group-horizontal-md py-0 mx-auto">
					<li class="list-group-item px-0 mx-1">
						<div id="mediaDialog"></div>
						<cfif listcontainsnocase(session.roles,"manage_media")>
							<button type="button" class="btn btn-xs btn-powder-blue small py-0" onClick="openEditMediaDialog(#collection_object_id#,'mediaDialog','#guid#',reloadMedia)">Media</button>
						</cfif>
					</li>
					<li class="list-group-item px-0 mx-1">
						<button type="button" id="btn_pane" class="btn btn-xs btn-powder-blue py-0 small" onclick="openEditIdentificationsDialog(#collection_object_id#,'identificationsDialog','#guid#',reloadIdentifications)">Identifications</button>
					</li>
					<li class="list-group-item px-0 mx-1">
						<button type="button" id="btn_pane" class="btn btn-xs btn-powder-blue py-0 small" onclick="openEditCitationsDialog(#collection_object_id#,'citationsDialog','#guid#',reloadCitations)">Citations</button>
					</li>
					<li class="list-group-item px-0 mx-1">
						<div id="otherIDsDialog"></div>
						<button type="button" id="btn_pane" class="btn btn-xs btn-powder-blue py-0 small" onclick="openEditOtherIDsDialog(#collection_object_id#,'otherIDsDialog','#guid#',reloadOtherIDs)">Other&nbsp;IDs</button>
					</li>
					<li class="list-group-item px-0 mx-1">
						<button type="button" id="btn_pane" class="btn btn-xs btn-powder-blue py-0 small" onclick="openEditPartsDialog(#collection_object_id#,'partsDialog','#guid#',reloadParts)">Parts</button>
					</li>
					<li class="list-group-item px-0 mx-1">
						<button type="button" id="btn_pane" class="btn btn-xs btn-powder-blue py-0 small" onclick="openEditAttributesDialog(#collection_object_id#,'attributesDialog','#guid#',reloadAttributes)">Attributes</button>
					</li>
					<li class="list-group-item px-0 mx-1">
						<button type="button" id="btn_pane" class="btn btn-xs btn-powder-blue py-0 small" onclick="openEditRelationsDialog(#collection_object_id#,'relationsDialog','#guid#',reloadRelations)">Relationships</button>
					</li>
					<li class="list-group-item px-0 mx-1">
						<button type="button" id="btn_pane" class="btn btn-xs btn-powder-blue py-0 small" onclick="openEditLocalityDialog(#collection_object_id#,'localityDialog','#guid#',reloadLocality)">Locality</button>
					</li>
					<li class="list-group-item px-0 mx-1">
						<button type="button" id="btn_pane" class="btn btn-xs btn-powder-blue py-0 small" onclick="openEditLocalityDialog(#collection_object_id#,'localityDialog','#guid#',reloadLocality)">Event</button>
					</li>
					<li class="list-group-item px-0 mx-1">
						<button type="button" id="btn_pane" class="btn btn-xs btn-powder-blue py-0 small" onclick="openEditCollectorsDialog(#collection_object_id#,'collectorsDialog','#guid#',reloadCollectors)">Collectors</button>
					</li>
					<li class="list-group-item px-0 mx-1">
						<button type="button" id="btn_pane" class="btn btn-xs btn-powder-blue py-0 small" onclick="openEditTransactionsDialog(110406,'transactionsDialog','#guid#',reloadTransactions)">Transactions</button>
					</li>
					<li class="list-group-item px-0 mx-1">
						<button type="button" id="btn_pane" class="btn btn-xs btn-powder-blue py-0 small" onclick="openEditMetadataDialog(#collection_object_id#,'metadataDialog','#guid#',reloadMetadata)">Meta&nbsp;Data</button>
					</li>
				</ul>
			</div>
		</div>
	</cfif>
	
	<div class="container-fluid ">
		<div class="row mx-0 mt-2">

			<!----------------------------- one left column for media only if media exist ---------------------------------->
			<cfset specimenMediaCount = getMediaHTML(collection_object_id = "#collection_object_id#", relationship_type = "shows", get_count = 'true')>
			<cfset specimenMediaCount = val(rereplace(specimenMediaCount,"[^0-9]","","all"))>
			<cfif specimenMediaCount gt 0>
				<div class="col-12 col-sm-3 col-md-3 col-lg-3 col-xl-2 px-1 mb-2 float-left">
					<!-----------------------------Media----------------------------------> 
					<div class="accordion" id="accordionMedia">
						<div class="card mb-2 bg-light">
							<div id="mediaDialog"></div>
							<div class="card-header" id="headingMedia">
								<h3 class="h5 my-0 text-dark">
									<button type="button" class="headerLnk text-left h-100 w-100" href="##" data-toggle="collapse" data-target="##mediaPane" aria-expanded="true" aria-controls="mediaPane">
										Media
										<span class="text-dark">(#specimenMediaCount#)</span>
									</button>
									<cfif listcontainsnocase(session.roles,"manage_specimens")>
										<a role="button" href="##" class="btn btn-xs small py-0 anchorFocus" id="btn_pane" onClick="openEditMediaDialog(#collection_object_id#,'mediaDialog','#guid#',reloadMedia)">Add/Remove</a>
									</cfif>
								</h3>
							</div>
							<div id="mediaPane" class="collapse show" <cfif #specimenMediaCount# gt 8>style="height:940px;"</cfif> aria-labelledby="headingMedia" data-parent="##accordionMedia">
								<cfset specimenMediaBlock = getMediaHTML(collection_object_id = "#collection_object_id#", relationship_type = "shows")>
								<div class="card-body w-100 px-1 pt-2 float-left" id="specimenMediaCardBody">
									#specimenMediaBlock#
								</div>
							</div>
						</div>
					</div>
				</div>
				<!--- three column layout --->
				<cfset twoThreeColumnClasses="col-md-9 col-lg-9 col-xl-10 float-left">
			<cfelse>
				<!--- two column layout --->
				<cfset twoThreeColumnClasses="col-md-12 col-lg-12 col-xl-12 float-left">
			</cfif>

			<!----------------------------- two right columns ---------------------------------->
			<div class="col-12 col-sm-12 mb-2 clearfix px-0 #twoThreeColumnClasses#">

				<!---- column 2 the leftmost of the two right columns ---->
				<div class="col-12 col-md-6 px-1 float-left"> 
					<!----------------------------- identifications ----------------------------------> 
					<div class="accordion" id="accordionB">
						<div class="card mb-2 bg-light">
							<div id="identificationsDialog"></div>
							<cfset blockident = getIdentificationsHTML(collection_object_id = "#collection_object_id#")>
							<div class="card-header" id="heading1">
								<cfif len(#blockident#) gt 10> 
									<h3 class="h5 my-0" tabindex="0">
										<button type="button" class="headerLnk text-left w-100" href="##" data-toggle="collapse" data-target="##identificationsPane" aria-expanded="true" aria-controls="identificationPane">
											Identifications
										</button>
										<cfif listcontainsnocase(session.roles,"manage_specimens")>
											<a role="button" href="##" id="btn_pane" class="anchorFocus btn btn-xs small py-0" onClick="openEditIdentificationsDialog(#collection_object_id#,'identificationsDialog','#guid#',reloadIdentifications)">
												Edit
											</a>
										</cfif>
									</h3>
								<cfelse>
									<h3 class="h5 my-0" tabindex="0">
										<button type="button" class="headerLnk text-left w-100 h-100" href="##" data-toggle="collapse" data-target="##identificationsPane" aria-controls="identificationPane">
											Identifications
										</button>
										<cfif listcontainsnocase(session.roles,"manage_specimens")>
											<a role="button" href="##" id="btn_pane" class="anchorFocus btn btn-xs small py-0" onClick="openEditIdentificationsDialog(#collection_object_id#,'identificationsDialog','#guid#',reloadIdentifications)">
												Add
											</a>
										</cfif>
									</h3>
								</cfif>
							</div>
							<div id="identificationsPane" class="collapse show" aria-labelledby="heading1" data-parent="##accordionB">
								<div class="card-body py-1 mb-0 w-100 float-left" id="identificationsCardBody">
									#blockident#
									<div id="identificationHTML"></div>
								</div>
							</div>
						</div>
					</div>
					<!----------------------------- Citations ----------------------------------> 
					<div class="accordion" id="accordionCitations">
						<div class="card mb-2 bg-light">
							<div id="citationsDialog"></div>
							<cfset blockcit = getCitationsHTML(collection_object_id = "#collection_object_id#")>
							<div class="card-header" id="headingCitations">
								<h3 class="h5 my-0 text-dark">
									<button type="button" class="headerLnk text-left h-100 w-100" href="##" data-toggle="collapse" data-target="##citationsPane" aria-expanded="true" aria-controls="citationsPane">
										Citations
									</button>
									<cfif listcontainsnocase(session.roles,"manage_specimens")>
										<a role="button" href="##" class="btn btn-xs small py-0 anchorFocus" onClick="openEditCitationsDialog(#collection_object_id#,'citationsDialog','#guid#',reloadCitations)">Add/Remove</a>
									</cfif>
								</h3>
							</div>
							<div id="citationsPane" class="collapse show" aria-labelledby="headingCitations" data-parent="##accordionCitations">
								<cfif len(trim(#blockcit#)) GT 0>
									<div class="card-body py-1 mb-1 float-left w-100" id="citationsCardBody">
										#blockcit#
									</div>
								<cfelse>
									<ul class="pl-2 list-group py-0 mb-0">
										<li class="small90 list-group-item font-italic">None</li>
									</ul>
								</cfif>
								<cfset citationMediaCount = getCitationMediaHTML(collection_object_id="#collection_object_id#",get_count="true")>
								<cfif citationMediaCount gt 0>
									<div class="float-left d-inline">
										<cfset citationMediaBlock= getCitationMediaHtml(collection_object_id="#collection_object_id#")>
										<div id="citationMediaBlock" class="px-2">
											#citationMediaBlock#
										</div>
									</div>
								</cfif>
							</div>
						</div>
					</div>
					<!------------------------------------ other identifiers ---------------------------------->
					<div class="accordion" id="accordionOtherID">
						<div class="card mb-2 bg-light">
							<div id="otherIDsDialog"></div>
							<cfset blockotherid = getOtherIDsHTML(collection_object_id = "#collection_object_id#")>
							<div class="card-header" id="headingOtherID">
								<cfif len(#blockotherid#) gt 1> 
									<h3 class="h5 my-0">
										<button type="button" class="headerLnk text-left w-100 h-100" aria-expanded="true" aria-controls="OtherIDsPane" data-toggle="collapse" data-target="##OtherIDsPane">
											Other Identifiers
										</button>
										<cfif listcontainsnocase(session.roles,"manage_specimens")>
											<a role="button" href="##" class="anchorFocus btn btn-xs small py-0" onClick="openEditOtherIDsDialog(#collection_object_id#,'otherIDsDialog','#guid#',reloadOtherIDs)">
												Edit
											</a>
										</cfif>
									</h3>
								<cfelse>
									<h3 class="h5 my-0">
										<button type="button" class="headerLnk text-left w-100 h-100" aria-controls="OtherIDsPane" aria-expanded="true" data-toggle="collapse" data-target="##OtherIDsPane">
											Other Identifiers
										</button>
										<cfif listcontainsnocase(session.roles,"manage_specimens")>
											<a role="button" href="##" class="btn btn-xs small py-0 anchorFocus" onClick="openEditOtherIDsDialog(#collection_object_id#,'otherIDsDialog','#guid#',reloadOtherIDs)">
												Add
											</a>
										</cfif>
									</h3>
								</cfif>
							</div>
							<div id="OtherIDsPane" class="collapse show" aria-labelledby="headingOtherID" data-parent="##accordionOtherID">
								<cfif len(trim(#blockotherid#)) GT 0> 
									<div class="card-body py-1 mb-0 float-left" id="otherIDsCardBody">
										#blockotherid# 
									</div>
								<cfelse>
									<ul class="pl-2 list-group py-0 mb-0">
										<li class="small90 list-group-item font-italic">None</li>
									</ul>
								</cfif>
							</div>
						</div>
					</div>
					<!------------------------------------ parts ---------------------------------->
					<div class="accordion" id="accordionParts">
						<div class="card mb-2 bg-light">
							<div id="partsDialog"></div>
							<div class="card-header" id="headingParts">
								<h3 class="h5 my-0">
									<button type="button" class="headerLnk text-left w-100 h-100" aria-controls="PartsPane" aria-expanded="true" data-toggle="collapse" data-target="##PartsPane">
										<cfif len(partCount) GT 0>
											Parts <span class="text-dark">(<span id="partCountSpan">#partCount#</span>)</span>
										<cfelse>
											Parts <span class="text-dark"><span id="partCountSpan"></span></span>
										</cfif>
									</button>
									<cfif listcontainsnocase(session.roles,"manage_specimens")>
										<a href="##" role="button" class="btn btn-xs small py-0 anchorFocus" onClick="openEditPartsDialog(#collection_object_id#,'partsDialog','#guid#',reloadParts)">
											Edit
										</a>
									</cfif>
								</h3>
							</div>
							<div id="PartsPane" <cfif #partCount# gt 5>style="height:300px;"</cfif> class="collapse show" aria-labelledby="headingParts" data-parent="##accordionParts">
								<div class="card-body py-1 w-100 mb-1 float-left" id="partsCardBody">
									<p class="smaller py-0 mb-0 text-center w-100">
										<cfif #partCount# gt 5>double-click part header to see all #partCount#</cfif>
									</p>
									<cfset blockparts = getPartsHTML(collection_object_id = "#collection_object_id#")>
									#blockparts#
								</div>
							</div>
						</div>
					</div>
					<!------------ attributes ----------------------------------------->
					<div class="accordion" id="accordionAttributes">
						<div class="card mb-2 bg-light">
							<div id="attributesDialog"></div>
							<cfset blockattributes = getAttributesHTML(collection_object_id = "#collection_object_id#")>
							<div class="card-header" id="headingAttributes">
								<cfif len(#blockattributes#) gt 50> 
									<h3 class="h5 my-0">
										<button type="button" class="headerLnk text-left w-100 h-100" aria-expanded="true" aria-controls="AttributesPane" data-toggle="collapse" data-target="##AttributesPane">
											Attributes
										</button>
										<cfif listcontainsnocase(session.roles,"manage_specimens")>
											<a href="##" role="button" class="btn btn-xs small py-0 anchorFocus" onClick="openEditAttributesDialog(#collection_object_id#,'attributesDialog','#guid#',reloadAttributes)">
												Edit
											</a>
										</cfif>
									</h3>
								<cfelse>
									<h3 class="h5 my-0">
										<button type="button" class="headerLnk text-left w-100 h-100" aria-expanded="true" aria-controls="AttributesPane" data-toggle="collapse" data-target="##AttributesPane">
											Attributes
										</button>
										<cfif listcontainsnocase(session.roles,"manage_specimens")>
											<a href="##" role="button" class="btn btn-xs small py-0 anchorFocus" onClick="openEditAttributesDialog(#collection_object_id#,'attributesDialog','#guid#',reloadAttributes)">
												Add
											</a>
										</cfif>
									</h3>
								</cfif>
							</div>
							<div id="AttributesPane" class="collapse show" aria-labelledby="headingAttributes" data-parent="##accordionAttributes">
								<cfif len(trim(#blockattributes#)) GT 0>
									<div class="card-body py-1 mb-1 float-left w-100" id="attributesCardBody">
										#blockattributes#
									</div>
								<cfelse>
									<ul class="pl-2 list-group py-0 mb-0">
										<li class="small90 list-group-item font-italic">None</li>
									</ul>
								</cfif>
							</div>
						</div>
					</div>
					<!------------------------------------ relationships  ------------------------------------->
					<cfif #oneOfUs# eq 0>
						<div class="accordion" id="accordionRelations">
							<div class="card mb-2 bg-light">
								<div id="relationsDialog"></div>
								<script>
									function reloadRelations() { 
										loadRelations(#collection_object_id#,'RelationsCardBody');
									}
								</script>
								<cfset blockrel = getRelationsHTML(collection_object_id = "#collection_object_id#")>
								<div class="card-header" id="headingRelations">
									<cfif len(#blockrel#) gt 15> 
										<h3 class="h5 my-0">
											<button type="button" class="headerLnk w-100 h-100 text-left" data-toggle="collapse" aria-expanded="true" data-target="##RelationsPane">
												Relationships
											</button>
											<cfif listcontainsnocase(session.roles,"manage_specimens")>
												<a role="button" href="##" class="btn btn-xs small py-0 anchorFocus" onClick="openEditRelationsDialog(#collection_object_id#,'relationsDialog','#guid#',reloadRelations)">
													Edit
												</a>
											</cfif>
										</h3>
									<cfelse>
										<h3 class="h5 my-0">
											<button type="button" class="headerLnk w-100 h-100 text-left" data-toggle="collapse" aria-expanded="true" data-target="##RelationsPane">
												Relationships
											</button>
											<cfif listcontainsnocase(session.roles,"manage_specimens")>
												<a role="button" href="##" class="btn btn-xs small py-0 anchorFocus" onClick="openEditRelationsDialog(#collection_object_id#,'relationsDialog','#guid#',reloadRelations)">
													Add
												</a>
											</cfif>
										</h3>
									</cfif>
								</div>
								<div id="RelationsPane" class="collapse show" aria-labelledby="headingRelations" data-parent="##accordionRelations">
									<cfif len(trim(#blockrel#)) GT 0>
										<div class="card-body py-1 mb-1 float-left" id="relationsCardBody">
											#blockrel# 
										</div>
									<cfelse>
										<ul class="pl-2 py-0 list-group mb-0">
											<li class="list-group-item small90 font-italic">None</li>
										</ul>
									</cfif>
								</div>
							</div>
						</div>
					</cfif>
					<!------------ coll object remarks ----------------------------------------->
					<div class="accordion" id="accordionRemarks">
						<div class="card mb-2 bg-light">
							<div id="RemarksDialog"></div>
							<cfset blockRemarks = getRemarksHTML(collection_object_id = "#collection_object_id#")>
							<div class="card-header" id="headingRemarks">
								<cfif len(#blockRemarks#) gt 50>
									<h3 class="h5 my-0">
										<button type="button" class="headerLnk text-left w-100 h-100" aria-expanded="true" aria-controls="RemarksPane" data-toggle="collapse" data-target="##RemarksPane">
											Collection Object Remarks
										</button>
										<cfif listcontainsnocase(session.roles,"manage_specimens")>
											<a href="##" role="button" class="btn btn-xs small py-0 anchorFocus" onClick="openEditRemarksDialog(#collection_object_id#,'RemarksDialog','#guid#',reloadRemarks)">
												Edit
											</a>
										</cfif>
									</h3>
								<cfelse>
									<h3 class="h5 my-0">
										<button type="button" class="headerLnk text-left w-100 h-100" aria-expanded="true" aria-controls="RemarksPane" data-toggle="collapse" data-target="##RemarksPane">
											Collection Object Remarks
										</button>
										<cfif listcontainsnocase(session.roles,"manage_specimens")>
											<a href="##" role="button" class="btn btn-xs small py-0 anchorFocus" onClick="openEditRemarksDialog(#collection_object_id#,'RemarksDialog','#guid#',reloadRemarks)">
												Add
											</a>
										</cfif>
									</h3>
								</cfif>
							</div>
							<div id="RemarksPane" class="collapse show" aria-labelledby="headingRemarks" data-parent="##accordionRemarks">
								<cfif len(trim(blockRemarks)) gt 0>
									<div class="card-body py-1 my-1 float-left" id="remarksCardBody">
										#blockRemarks#
									</div>
								<cfelse>
									<ul class="pl-2 list-group py-0 mb-0">
										<li class="small90 list-group-item font-italic">None</li>
									</ul>
								</cfif>
							</div>
						</div>
					</div>
					<!------------ Meta Data----------------------------------------->
					<cfif #oneOfUs# eq 1>
						<div class="accordion" id="accordionMeta">
							<div class="card mb-2 bg-light">
								<div id="metaDialog"></div>
								<script>
									function reloadMeta() { 
										loadMeta(#collection_object_id#,'metaCardBody');
									}
								</script>
								<cfset blockmeta = getMetaHTML(collection_object_id = "#collection_object_id#")>
								<div class="card-header" id="headingMeta">
									<cfif len(#blockmeta#) gt 0> 
										<h3 class="h5 my-0">
											<button type="button" class="headerLnk text-left w-100 h-100" aria-expanded="true" aria-controls="MetaPane" data-toggle="collapse" data-target="##MetaPane">
												Metadata
											</button>
											<cfif listcontainsnocase(session.roles,"manage_specimens")>
												<a href="##" role="button" class="btn btn-xs small py-0 anchorFocus" onClick="openEditMetaDialog(#collection_object_id#,'metaDialog','#guid#',reloadMeta)">
													Edit
												</a>
											</cfif>
										</h3>
									<cfelse>
										<h3 class="h5 my-0">
											<button type="button" class="headerLnk text-left w-100 h-100" aria-expanded="true" aria-controls="MetaPane" data-toggle="collapse" data-target="##MetaPane">
												Metadata
											</button>
											<cfif listcontainsnocase(session.roles,"manage_specimens")>
												<a href="##" role="button" class="btn btn-xs small py-0 anchorFocus" onClick="openEditMetaDialog(#collection_object_id#,'metaDialog','#guid#',reloadMeta)">
													Add
												</a>
											</cfif>
										</h3>
									</cfif>
								</div>
								<div id="MetaPane" class="collapse show" aria-labelledby="headingMeta" data-parent="##accordionMeta">
									<cfif len(#blockmeta#) gt 0>
										<div class="card-body py-1 my-1 float-left" id="metaCardBody">
											#blockmeta#
										</div>
									<cfelse>
										<ul class="pl-3 py-0 mb-0">
											<li class="list-group-item small90 font-italic">None</li>
										</ul>
									</cfif>
								</div>
							</div>
						</div>
					</cfif>
				</div>

				<!---  start of column three  (rightmost of the two right columns) --->
				<div class="col-12 col-md-6 px-1 float-left"> 
					<!--------------------locality and collecting event------------------------------>
					<div class="accordion" id="accordionLocality">
						<div class="card mb-2 bg-light">
							<div id="localityDialog"></div>
							<cfset blocklocality = getLocalityHTML(collection_object_id = "#collection_object_id#")>
							<div class="card-header" id="headingLocality">
								<cfif len(#blocklocality#) gt 60>
									<h3 class="h5 my-0">
										<button type="button" data-toggle="collapse" aria-expanded="true" data-target="##LocalityPane" aria-controls="LocalityPane" class="headerLnk w-100 h-100 text-left">
											Location and Collecting Event
										</button>
										<cfif listcontainsnocase(session.roles,"manage_specimens")>
											<a href="##" role="button" class="btn btn-xs small py-0 anchorFocus" onClick="openEditLocalityDialog(#collection_object_id#,'localityDialog','#guid#',reloadLocality)">
												Edit
											</a>
										</cfif>
									</h3>
								<cfelse>
									<h3 class="h5 my-0">
										<button type="button" class="headerLnk w-100 h-100 text-left" data-toggle="collapse" aria-expanded="true" aria-controls="LocalityPane" data-target="##LocalityPane">
											Location and Collecting Event
										</button>
										<cfif listcontainsnocase(session.roles,"manage_specimens")>
											<a href="##" role="button" class="btn btn-xs small py-0 anchorFocus" onClick="openEditLocalityDialog(#collection_object_id#,'localityDialog','#guid#',reloadLocality)">
												Add
											</a>
										</cfif>
									</h3>
								</cfif>
							</div>
							<div id="LocalityPane" class="collapse show" aria-labelledby="headingLocality" data-parent="##accordionLocality">
								<cfif len(#blocklocality#) gt 60> 
									<div class="card-body px-0 py-1 mb-1 float-left" id="localityCardBody">
										#blocklocality# 
									</div>
								<cfelse>
									<ul class="pl-2 mb-0 list-group py-0">
										<li class="small90 list-group-item font-italic">None</li>
									</ul>
								</cfif>
							</div>
						</div>
					</div>
					<!------------------- Collectors and Preparators ---------------------------->
					<div class="accordion" id="accordionCollectors">
						<div class="card mb-2 bg-light">
							<div id="collectorsDialog"></div>
							<script>
								function reloadCollectors() { 
									loadCollectors(#collection_object_id#,'collectorsCardBody');
								}
							</script>
							<cfset blockcollectors = getCollectorsHTML(collection_object_id = "#collection_object_id#")>
							<div class="card-header" id="headingCollectors">
								<cfif len(#blockcollectors#) gt 5>
									<h3 class="h5 my-0">
										<button type="button" data-toggle="collapse" class="w-100 h-100 headerLnk text-left" aria-controls="CollectorsPane" aria-expanded="true" data-target="##CollectorsPane">
											Collectors and Preparators
										</button>
										<cfif listcontainsnocase(session.roles,"manage_specimens")>
											<a href="##" role="button" class="btn btn-xs small py-0 anchorFocus" onClick="openEditCollectorsDialog(#collection_object_id#,'collectorsDialog','#guid#',reloadCollectors)">
												Edit
											</a>
										</cfif>
									</h3>
								<cfelse>
									<h3 class="h5 my-0">
										<button class="headerLnk w-100 h-100 text-left" aria-expanded="true" type="button" aria-controls="CollectorsPane" data-toggle="collapse" data-target="##CollectorsPane">
											Collectors and Preparators
										</button>
										<cfif listcontainsnocase(session.roles,"manage_specimens")>
											<a href="##" role="button" class="btn btn-xs small py-0 anchorFocus" onClick="openEditCollectorsDialog(#collection_object_id#,'collectorsDialog','#guid#',reloadCollectors)">
												Add
											</a>
										</cfif>
									</h3>
								</cfif>
							</div>
							<div id="CollectorsPane" class="collapse show" aria-labelledby="headingCollectors" data-parent="##accordionCollectors">
								<div class="card-body py-1 mb-1 float-left" id="collectorsCardBody">
									<cfif len(#blockcollectors#) gt 60> 
										#blockcollectors# 
									<cfelse>
										<ul class="pl-2 list-group py-0 mb-0">
											<li class="small90 list-group-item font-italic">None</li>
										</ul>
									</cfif>
								</div>
							</div>
						</div>
					</div>
					<!-----------------------------Ledger--------------------------------> 
					<cfset ledgerMediaCount = getMediaHTML(collection_object_id = "#collection_object_id#", relationship_type = "documents", get_count = 'true')>
					<cfset ledgerMediaCount = val(rereplace(ledgerMediaCount,"[^0-9]","","all"))>
					<div class="accordion" id="accordionLedger">
						<div class="card mb-2 bg-light">
							<div id="ledgerDialog"></div>
							<div class="card-header" id="headingLedger">
								<h3 class="h5 my-0">
									<button type="button" aria-controls="ledgerPane" class="headerLnk text-left h-100 w-100" data-toggle="collapse" data-target="##ledgerPane" aria-expanded="true" >
										Ledger and Field Notes
									</button>
								</h3>
							</div>
							<div id="ledgerPane" class="collapse show" aria-labelledby="headingLedger" data-parent="##accordionLedger">
								<cfif ledgerMediaCount gt 0> 
									<div class="card-body w-100 px-1 pt-2 pb-0 float-left" id="ledgerCardBody">
										<cfset ledgerBlock = getMediaHTML(collection_object_id = "#collection_object_id#", relationship_type = "documents")>
										<div class="col-12 px-1 mb-1 px-md-1 pt-1 float-left">
											#ledgerBlock# 
										</div>
									</div>
								<cfelse>
									<ul class="pl-2 list-group py-0 mb-0">
										<li class="small90 list-group-item font-italic">None</li>
									</ul>
								</cfif>
							</div>
						</div>
					</div>
					<!------------------------------ tranactions  --------------------------------->
					<div class="accordion" id="accordionTransactions">
						<div class="card mb-2 bg-light">
							<div id="transactionsDialog"></div>
							<script>
								function reloadTransactions() { 
									loadTransactions(#collection_object_id#,'transactionsCardBody');
								}
							</script>
							<div class="card-header" id="headingTransactions">
								<h3 class="h5 my-0">
									<button type="button" aria-controls="TransactionsPane" class="w-100 h-100 text-left headerLnk" aria-expanded="true" data-toggle="collapse" data-target="##TransactionsPane">
										Transactions
									</button>
									<cfif listcontainsnocase(session.roles,"manage_specimens")>
										<a role="button" href="##" class="btn btn-xs small py-0 anchorFocus" onClick="openEditTransactionsDialog(#collection_object_id#,'transactionsDialog','#guid#',reloadTransactions)">
											Edit
										</a>
									</cfif>
								</h3>
							</div>
							<div id="TransactionsPane" class="collapse show" aria-labelledby="headingTransactions" data-parent="##accordionTransactions">
								<div class="card-body py-1 mb-1 float-left" id="transactionsCardBody">
									<cfset block = getTransactionsHTML(collection_object_id = "#collection_object_id#")>
									#block#
								</div>
							</div>
						</div>
					</div>
					<!------------------------------ named groups  --------------------------------->
					<div class="accordion" id="accordionNamedGroups">
						<div class="card mb-2 bg-light">
							<div id="NamedGroupsDialog"></div>
							<script>
								function reloadNamedGroups() { 
									loadNamedGroups(#collection_object_id#,'NamedGroupsCardBody');
								}
							</script>
							<div class="card-header" id="headingNamedGroups">
								<h3 class="h5 my-0">
									<button type="button" aria-controls="NamedGroupsPane" class="w-100 h-100 text-left headerLnk" aria-expanded="true" data-toggle="collapse" data-target="##NamedGroupsPane">
										Named Groups
									</button>
									<cfif listcontainsnocase(session.roles,"manage_specimens")>
										<a role="button" href="##" class="btn btn-xs small py-0 anchorFocus" onClick="openEditNamedGroupsDialog(#collection_object_id#,'NamedGroupsDialog','#GUID#',reloadNamedGroups)">
											Edit
										</a>
									</cfif>
								</h3>
							</div>
							<div id="NamedGroupsPane" class="collapse show" aria-labelledby="headingNamedGroups" data-parent="##accordionNamedGroups">
								<cfif #block# gt 0>
									<div class="card-body py-1 mb-1 float-left" id="NamedGroupsCardBody">
										<cfset block = getNamedGroups(collection_object_id = "#collection_object_id#")>
										#block#
									</div>
								<cfelse>
									<ul class="pl-2 list-group py-0 mb-0">
										<li class="small90 list-group-item font-italic">
											None
										</li>
									</ul>	
								</cfif>
							</div>
						</div>
					</div>
				</div> <!--- end of column 3 --->

			</div><!--- end of column to hold the two right colums (the two colums if no media) --->
		</div><!--- end row --->
	</div><!--- end container-fluid --->
</cfoutput>

<!--- (4a) QC section --->
<cfoutput>
	<cfif isdefined("session.roles") and listfindnocase(session.roles,"collops")>
		<div class="container-fluid">
			<section class="row" id="QCSection">
				<div class="col-12 px-2">
					<!---  Include the TDWG BDQ TG2 test integration --->
					<script type='text/javascript' language="javascript" src='/dataquality/js/bdq_quality_control.js'></script>
					<script>
						function runTests() {
							loadNameQC(#collection_object_id#, "", "NameDQDiv");
							loadSpaceQC(#collection_object_id#, "", "SpatialDQDiv");
							loadEventQC(#collection_object_id#, "", "EventDQDiv");
						}
					</script>
					<input type="button" value="QC" class="btn btn-secondary btn-xs" onClick=" runTests(); ">
					<!---  Scientific Name tests --->
					<div id="NameDQDiv"></div>
					<!---  Spatial tests --->
					<div id="SpatialDQDiv"></div>
					<!---  Temporal tests --->
					<div id="EventDQDiv"></div>
				</div>					
				</div>					
			</section><!-- end QCSection --->
		</div>
	</cfif>
</cfoutput>

<!--- (5) Finish up with the page footer --->
<cfinclude template="/shared/_footer.cfm">
