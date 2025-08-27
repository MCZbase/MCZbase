<!---
specimens/Specimen.cfm

Copyright 2019-2025 President and Fellows of Harvard College

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
 top portion of the specimen summarys page, header, summary information/type bar, then the bulk of the body of the
 specimen summarys page, then the footer.
--->
<cfif isDefined("url.result_id") and len(url.result_id) GT 0>
	<cfset result_id = url.result_id>
</cfif>
<cfif isDefined("url.collection_object_id") and len(url.collection_object_id) GT 0>
	<cfset collection_object_id = url.collection_object_id>
</cfif>
<cfif isDefined("url.guid") and len(url.guid) GT 0>
	<cfset guid = url.guid>
</cfif>

<!--- (1) Check the provided guid or collection object id --->
<!--- Set page title to reflect failure condition, if queries succeed it will be changed to reflect specimen record found --->
<cfset pageTitle = "MCZbase Specimen not found.">

<!--- load javascript libraries for the page --->
<script type='text/javascript' src='/media/js/media.js'></script>
<script type="text/javascript" src="/localities/js/collectingevents.js"></script>
<cfif isdefined("session.roles") AND listfindnocase(session.roles,"coldfusion_user")>
	<script type="text/javascript" src="/specimens/js/specimens.js"></script>
	<script type="text/javascript" src="/containers/js/containers.js"></script>
</cfif>
<cfif isdefined("session.roles") AND listfindnocase(session.roles,"manage_transactions")>
	<script type="text/javascript" src="/transactions/js/transactions.js"></script>
</cfif>

<cfif isdefined("collection_object_id")>
	<cfoutput>
		<cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			select GUID 
			from <cfif ucase(session.flatTableName) EQ "FLAT"> flat <cfelse> filtered_flat </cfif>
			where collection_object_id = <cfqueryparam value="#collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
		</cfquery>
		<cfif isDefined("result_id") and len(result_id) GT 0>
			<!--- Use 308 to preserve result_id post parameter see: https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/308  --->
			<cfheader statuscode="308" statustext="Permanent Redirect">
		<cfelseif isDefined("old") and len(old) GT 0>
			<!--- Use 308 to preserve old post parameter see: https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/308  --->
			<cfheader statuscode="308" statustext="Permanent Redirect">
		<cfelse>
			<cfheader statuscode="301" statustext="Moved permanently">
		</cfif>
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
		<cfif isDefined("result_id") and len(result_id) GT 0>
			<!--- Use 308 to preserve result_id post parameter see: https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/308  --->
			<cfheader statuscode="308" statustext="Permanent Redirect">
		<cfelseif isDefined("old") and len(old) GT 0>
			<!--- Use 308 to preserve old post parameter see: https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/308  --->
			<cfheader statuscode="308" statustext="Permanent Redirect">
		<cfelse>
			<cfheader statuscode="301" statustext="Moved permanently">
		</cfif>
		<cfheader name="Location" value="/guid/#guid#">
		<cfabort>
	</cfif>
	
	<!---  GUID is expected to be in the form MCZ:collectioncode:catalognumber --->
	<cfif guid contains ":">
		<cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="cresult">
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
		<cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="cresult">
			select collection_object_id 
			from
				cataloged_item 
				left join collection on cataloged_item.collection_id = collection.collection_id 
			WHERE
				cat_num = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#cn#"> 
				AND lower(collection.collection) = <cfqueryparam value='#lcase(cc)#' cfsqltype="CF_SQL_VARCHAR" >
		</cfquery>
	</cfif>
	<cfif not isDefined("cresult") OR cresult.recordcount EQ 0>
		<!--- Record for this GUID was not found ---> 
		<cfinclude template="/errors/404.cfm">
		<cfabort>
	<cfelse>
		<!--- Record for this GUID was found, make the collection_object_id available to obtain specimen record summarys. ---> 
		<cfoutput query="c">
			<cfset collection_object_id=c.collection_object_id>
		</cfoutput>
	</cfif>
<cfelse>
	<cfinclude template="/errors/404.cfm">
	<cfabort>
</cfif>

<!--- Check to see if the user is logged in and has the role coldfusion_user, granted to internal users --->
<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
	<cfset oneOfUs = 1>
<cfelse>
	<cfset oneOfUs = 0>
</cfif>
<cfquery name="check" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	SELECT 
		concatEncumbranceDetails(<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">) encumbranceDetail
	FROM DUAL
</cfquery>

<!--- (2) Look up summary and type information on the specimen for the html header, this isn't reloaded, so can come from flat --->
<cfquery name="header" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
 	SELECT 
		collection,
		scientific_name,
		full_taxon_name,
		higher_geog,
		spec_locality,
		typestatusplain,
		typestatuswords,
		imageurl
	FROM
		<cfif ucase(session.flatTableName) EQ "FLAT"> flat <cfelse> filtered_flat </cfif>
	WHERE
		collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
</cfquery>
<!--- check for mixed collection --->
<cfset variables.isMixed = false>
<cfquery name="checkMixed" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	SELECT 
		count(identification.collection_object_id) ct
	FROM
		<cfif ucase(session.flatTableName) EQ "FLAT"> flat <cfelse> filtered_flat </cfif> flatTable
		join coll_object on flatTable.collection_object_id = coll_object.collection_object_id
		join specimen_part on coll_object.collection_object_id = specimen_part.derived_from_cat_item
		join identification on specimen_part.collection_object_id = identification.collection_object_id
	WHERE
		flatTable.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
</cfquery>
<cfif checkMixed.ct GT 0>
	<cfset variables.isMixed = true>
</cfif>

<!--- (3) Display the page header ---> 
<!--- Successfully found a specimen, set the pageTitle plus page metadata and call the header to reflect this ---> 
<cfset addedMetaDescription="Specimen Record for: #guid# in the #header.collection# collection; #header.scientific_name#; #header.higher_geog#; #header.spec_locality#; #header.typestatusplain#">
<cfset addedKeywords=",#header.full_taxon_name#,#header.higher_geog#,#header.typestatuswords#">
<cfset pageTitle = "MCZbase #guid# specimen record">
<cfinclude template="/shared/_header.cfm">

<cfif not isdefined("session.sdmapclass") or len(session.sdmapclass) is 0>
	<cfset session.sdmapclass='tinymap'>
</cfif>
<cfoutput>
	<cfhtmlhead text='<script src="#Application.protocol#://maps.googleapis.com/maps/api/js?key=#application.gmap_api_key#&libraries=geometry" type="text/javascript"></script>'>
</cfoutput>

<!--- (4) Display the summary/type bar for the record --->
<!--- Include the templates that contains functions used to load portions of this page --->
<cfinclude template="/specimens/component/public.cfc">
<cfinclude template="/media/component/search.cfc" runOnce="true"><!--- ? unused ? removed ? --->
<cfinclude template="/media/component/public.cfc" runOnce="true"><!--- getMediaBlockHtml --->
<cfinclude template="/vocabularies/component/search.cfc" runOnce="true">
<cfset summaryHeadingBlock = getSummaryHeaderHTML(collection_object_id = "#collection_object_id#")>
<cfoutput>
<div id="specimenDetailsPageContent">
<div id="specimenSummaryHeaderDiv">
#summaryHeadingBlock#
</div>
</cfoutput>

<!--- (5) Bulk of the specimen page (formerly in SpecimenDetailBody) --->

<!--- query getCatalogedItem is needed for determining what is public and what is partitioned --->
<cfquery name="getCatalogedItem" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	SELECT 
		cataloged_item.collection_object_id,
		cataloged_item.collection_cde,
		cataloged_item.cat_num,
		cataloged_item.collecting_event_id,
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
	<cfquery name="countParts" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
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
	<!--- public.js provides functions available for everyone, edit.js provides functions that support editing ---->
	<script type="text/javascript" src="/specimens/js/public.js"></script> 
	<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_specimens")>
		<script type="text/javascript" src="/specimens/js/edit.js"></script> 
	</cfif>
   <cfif isdefined("session.username") AND len(session.username) gt 0>
		<script>
			function reloadAnnotations() { 
				loadAnnotations(#getCatalogedItem.collection_object_id#,'annotationsCardBody');
			}

		</script>
	</cfif>
	<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_specimens")>
		<!--- user can edit the specimen record --->
		<!--- scripts for reloading sections of pages after edits, use as callabcks on edit dialogs --->
		<script>
			function reloadPage() { 
				$("##specimenDetailsPageContent").html("<h2 class=h3>Reloading page...</h2>");
				window.location.reload();
			}
			function reloadHeadingBar() { 
				// invoke specimen/component/public function to reload summary header section.
				// called from several other sections where data shown in summary may be changed.
				loadSummaryHeaderHTML(#getCatalogedItem.collection_object_id#,"specimenSummaryHeaderDiv");
			} 
			function reloadCatalog() { 
				reloadHeadingBar();
				reloadTransactions();
			}
			function reloadSpecimenMedia() { 
				// if accordionMedia exists, reload its content, if it does not, reload the page.
				if ($("##accordionMedia").length) {
					// invoke specimen/component/public.cfc function getMediaHTML via ajax with relationship_type shows  and repopulate the specimen media block.
					loadMedia(#getCatalogedItem.collection_object_id#,'specimenMediaCardBody');
					// Update media count
					updateMediaCounts(#getCatalogedItem.collection_object_id#,'specimenMediaCount');
				} else {
					$("##editControlsBlock").html("<h2 class=h3>Reloading page...</h2>");
					reloadPage();
				}
			}
			function reloadIdentifiers() { 
				// invoke specimen/component/public.cfc function getIdentifiersHTML via ajax and repopulate the identifiers block.
				loadIdentifiers(#getCatalogedItem.collection_object_id#,'identifiersCardBody');
			}
			function reloadIdentifications() { 
				// invoke specimen/component/public.cfc function getIdentificationsHTML via ajax and repopulate the identification block.
				loadIdentifications(#getCatalogedItem.collection_object_id#,'identificationsCardBody');
				reloadHeadingBar();
			}
			function reloadCitations() { 
				// replace the citations block via ajax.
				loadCitations(#getCatalogedItem.collection_object_id#,'citationsCardBody');
				// replace the citation media block via ajax.
				loadCitationMedia(#getCatalogedItem.collection_object_id#,'citationMediaBlock');
				reloadHeadingBar();
			}
			function reloadOtherIDs() { 
				// invoke specimen/component/public.cfc function getOtherIDsHTML via ajax and repopulate the Other Identifiers block.
				loadOtherIDs(#getCatalogedItem.collection_object_id#,'otherIDsCardBody');
			}
			function reloadParts() { 
				// reload the parts html block
				loadParts(#getCatalogedItem.collection_object_id#,'partsCardBody');
				// Update part count
				loadPartCount(#getCatalogedItem.collection_object_id#,'partCountSpan');
			}
			function reloadAttributes() { 
				// invoke specimen/component/public.cfc function getAttributesHTML via ajax and repopulate the attributes block.
				loadAttributes(#getCatalogedItem.collection_object_id#,'attributesCardBody');
			}
			function reloadRelations() { 
				loadRelations(#getCatalogedItem.collection_object_id#,'relationsCardBody');
			}
			function reloadRemarks() { 
				loadRemarks(#getCatalogedItem.collection_object_id#,'remarksCardBody');
				// also reload microhabitat 
				loadLocality(#getCatalogedItem.collection_object_id#,'localityCardBody');
			}
			function reloadMeta() { 
				loadMeta(#getCatalogedItem.collection_object_id#,'metaCardBody');
			}

			function reloadLocality() { 
				loadLocality(#getCatalogedItem.collection_object_id#,'localityCardBody');
				reloadHeadingBar();
			}
			function reloadPreparators() { 
				loadPreparators(#getCatalogedItem.collection_object_id#,'collectorsCardBody');
			}
			function reloadLedger() { 
				// replace the ledger/field notes block via ajax.
				// invoke specimen/component/public.cfc function getMediaHTML via ajax with relationship_type documents.
				loadLedger(#getCatalogedItem.collection_object_id#,'ledgerCardBody');
			}
			function reloadTransactions() { 
				loadTransactions(#getCatalogedItem.collection_object_id#,'transactionsCardBody');
			}
			function reloadNamedGroups() { 
				loadNamedGroups(#getCatalogedItem.collection_object_id#,'namedGroupsCardBody');
			}
		</script>
		<!--- setup for navigation between specimen records within a result set. --->
		<cfset navigable = false>
		<cfset oldBit = ""><!--- explicit marker for using session.collObjIdList for result navigation --->
		<cfif isdefined("result_id") and len(result_id) gt 0>
			<!--- orders records by institution:collection_cde:catalog_number, to change, change all the order by and over clauses --->
		   <cfset isPrev = "no">
			<cfset isNext = "no">
			<!--- confirm that the record is part of an orderable result accessible to the current user --->
			<cfquery name="positionInResult" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT pagesort  
				FROM user_search_table
				WHERE collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getCatalogedItem.collection_object_id#">
					AND result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
			</cfquery>
			<cfif positionInResult.recordcount GT 0>
				<cfset navigable = true>
				<cfquery name="getFirst" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT collection_object_id, pagesort, guid 
					FROM (
						SELECT user_search_table.collection_object_id, pagesort, guid
						FROM user_search_table 
							join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat 
							on user_search_table.collection_object_id = flat.collection_object_id
						WHERE result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
						ORDER BY guid ASC
					) WHERE rownum < 2
				</cfquery>
				<cfset firstID = getFirst.collection_object_id>
				<cfset firstGUID = getFirst.guid>
				<cfquery name="getLast" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT collection_object_id, pagesort, guid 
					FROM (
						SELECT user_search_table.collection_object_id, pagesort, guid
						FROM user_search_table 
							JOIN <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat 
							on user_search_table.collection_object_id = flat.collection_object_id
						WHERE result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
						ORDER BY guid DESC
					) WHERE rownum < 2
				</cfquery>
				<cfset lastID = getLast.collection_object_id>
				<cfset lastGUID = getLast.guid>
				<cfquery name="previousNext" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT prevcol, prevguid, collection_object_id, nextcol, nextguid
					FROM (
						SELECT 
							lag(user_search_table.collection_object_id) over (order by guid asc) prevcol, 
							lag(flat.guid) over (order by guid asc) prevguid, 
							user_search_table.collection_object_id collection_object_id, 
							lead(user_search_table.collection_object_id) over (order by guid asc) nextcol,
							lead(flat.guid) over (order by guid asc) nextguid
						FROM user_search_table 
						JOIN <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat 
							on user_search_table.collection_object_id = flat.collection_object_id
						WHERE result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
						ORDER by guid asc
					) WHERE collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
				</cfquery>
				<cfset prevID = previousNext.prevcol>
				<cfif len(prevID) GT 0>
					<cfset isPrev = "yes">
					<cfset prevGUID = previousNext.prevguid>
				</cfif>
				<cfset nextID = previousNext.nextcol>
				<cfif len(nextID) GT 0>
					<cfset isNext = "yes">
					<cfset nextGUID = previousNext.nextguid>
				</cfif>
			</cfif>
		<cfelseif isdefined("session.collObjIdList") and len(session.collObjIdList) gt 0 AND isDefined("old") and old EQ 'true' >
			<cfset navigable = true>
		   <cfset isPrev = "no">
			<cfset isNext = "no">
			<cfset currPos = 0>
			<cfset oldBit = "&old=true">

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
					<cfquery name="getFirstGuid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						SELECT guid 
						FROM <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat 
						WHERE collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#firstID#">
					</cfquery>
					<cfset firstGUID = getFirstGuid.guid>
					<cfquery name="getPreviousGuid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						SELECT guid 
						FROM <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat 
						WHERE collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#prevID#">
					</cfquery>
					<cfset prevGUID = getPreviousGuid.guid>
				</cfif>
				<cfif currPos lt lenOfIdList>
					<cfset isNext = "yes">
					<cfquery name="getNextGuid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						SELECT guid 
						FROM <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat 
						WHERE collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#nextID#">
					</cfquery>
					<cfset nextGUID = getNextGuid.guid>
					<cfquery name="getLastGuid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						SELECT guid 
						FROM <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat 
						WHERE collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#lastID#">
					</cfquery>
					<cfset lastGUID = getLastGuid.guid>
				</cfif>
			</cfif>
		<cfelse>
			<cfset isNext="">
			<cfset isPrev="">
		</cfif>
		
		<!--- Div to hold full page editing dialog --->
		<div id="InPageEditorDiv" class="container-fluid"></div>

		<!--- controls for editing record --->
		<div class="container-lg d-none d-lg-block" id="editControlsDiv">
			<div class="row mt-2" id="editControlsBlock">
				<ul class="list-group list-inline list-group-horizontal-md py-0 mx-auto">
					<cfset resultBit = "">
					<!--- Navigation through records in a result set --->
					<cfif navigable>
						<cfif isdefined("result_id") and len(result_id) gt 0>
							<cfset resultBit = "&result_id=#result_id#">
						</cfif>
						<cfif isPrev is "yes">
							<li class="list-group-item px-0 mx-1">
								<span>
									<a href="/guid/#firstGUID#" onClick=" event.preventDefault(); $('##firstRecordForm').submit();">
										<img src="/images/first.gif" alt="[ First Record ]">
									</a>
									<form action="/guid/#firstGUID#" method="post" id="firstRecordForm">
										<cfif len(resultBit) GT 0>
											<input type="hidden" name="result_id" value="#result_id#" />
										<cfelseif isDefined("old") AND len(old) GT 0>
											<input type="hidden" name="old" value="true" />
										</cfif>
									</form>
								</span>
							</li>
							<li class="list-group-item px-0 mx-1">
								<span>
									<a href="/guid/#prevGUID#" onClick=" event.preventDefault(); $('##previousRecordForm').submit();">
										<img src="/images/previous.gif" alt="[ Previous Record ]">
									</a>
									<form action="/guid/#prevGUID#" method="post" id="previousRecordForm">
										<cfif len(resultBit) GT 0>
											<input type="hidden" name="result_id" value="#result_id#" />
										<cfelseif isDefined("old") AND len(old) GT 0>
											<input type="hidden" name="old" value="true" />
										</cfif>
									</form>
								</span>
							</li>
						<cfelse>
							<li class="list-group-item px-0 mx-1">
								<img src="/images/no_first.gif" alt="[ inactive button ]">
							</li>
							<li class="list-group-item px-0 mx-1">
								<img src="/images/no_previous.gif" alt="[ inactive button ]">
							</li>
						</cfif>
					</cfif>
					<!--- Task Bar of edit dialog controls --->
					<li class="list-group-item px-0 mx-1">
						<div id="catalogDialog"></div>
						<button type="button" id="btn_pane1" class="btn btn-xs btn-powder-blue py-0 small" onclick="openEditCatalogDialog(#collection_object_id#,'catalogDialog','#guid#',reloadPage)">Catalog</button>
					</li>
					<li class="list-group-item px-0 mx-1">
						<cfif listcontainsnocase(session.roles,"manage_media")>
							<button type="button" class="btn btn-xs btn-powder-blue small py-0" onClick="openEditMediaDialog(#collection_object_id#,'mediaDialog','#guid#',reloadSpecimenMedia)">Media</button>
						</cfif>
					</li>
					<li class="list-group-item px-0 mx-1">
						<button type="button" id="btn_pane2" class="btn btn-xs btn-powder-blue py-0 small" onclick="openEditIdentificationsInPage(#collection_object_id#,'identificationsDialog','#guid#',reloadIdentifications)">Identifications</button>
					</li>
					<li class="list-group-item px-0 mx-1">
						<button type="button" id="btn_pane3" class="btn btn-xs btn-powder-blue py-0 small" onclick="openEditCitationsDialog(#collection_object_id#,'citationsDialog','#guid#',reloadCitations)">Citations</button>
					</li>
					<li class="list-group-item px-0 mx-1">
						<button type="button" id="btn_pane4" class="btn btn-xs btn-powder-blue py-0 small" onclick="openEditOtherIDsDialog(#collection_object_id#,'otherIDsDialog','#guid#',reloadOtherIDs)">Other&nbsp;IDs</button>
					</li>
					<li class="list-group-item px-0 mx-1">
						<button type="button" id="btn_pane5" class="btn btn-xs btn-powder-blue py-0 small" onclick="openEditPartsInPage(#collection_object_id#,reloadParts)">Parts</button>
					</li>
					<li class="list-group-item px-0 mx-1">
						<button type="button" id="btn_pane6" class="btn btn-xs btn-powder-blue py-0 small" onclick="openEditPreparatorsDialog(#collection_object_id#,'collectorsDialog','#guid#',reloadPreparators)">Preparators</button>
					</li>
					<li class="list-group-item px-0 mx-1">
						<button type="button" id="btn_pane7" class="btn btn-xs btn-powder-blue py-0 small" onclick="openEditAttributesDialog(#collection_object_id#,'attributesDialog','#guid#',reloadAttributes)">Attributes</button>
					</li>
					<li class="list-group-item px-0 mx-1">
						<button type="button" id="btn_pane8" class="btn btn-xs btn-powder-blue py-0 small" onclick="openEditRelationsDialog(#collection_object_id#,'relationsDialog','#guid#',reloadRelations)">Relationships</button>
					</li>
					<li class="list-group-item px-0 mx-1">
						<button type="button" id="btn_pane9" class="btn btn-xs btn-powder-blue py-0 small" onclick="openEditRemarksDialog(#collection_object_id#,'remarksDialog','#guid#',reloadRemarks)">Remarks</button>
					</li>
					<li class="list-group-item px-0 mx-1">
						<div id="collEventPickerDialogDiv"></div>
						<input type="hidden" id="collecting_event_id_control" name="collecting_event_id_control" value="#getCatalogedItem.collecting_event_id#">
						<button type="button" id="btn_pane10" class="btn btn-xs btn-powder-blue py-0 small" 
							onclick=" launchCollectingEventDialog(); ">Coll&nbsp;Event</button>
						<script>
							function launchCollectingEventDialog() {
								console.log("launchCollectingEventDialog called");
								// open the collecting event dialog to select a new collecting event
								openlinkcollectingeventdialog('collEventPickerDialogDiv', '#guid#', 'collecting_event_id_control', 'changeCollectingEvent', null);
							}
							function changeCollectingEvent() {
								console.log("changeCollectingEvent called");
								// change the collecting event id from the value in the hidden input field
								var new_collecting_event_id = $("##collecting_event_id_control").val();
								console.log("New collecting_event_id: " + new_collecting_event_id);
								if (new_collecting_event_id.length == 0) {
									// but not if empty
									console.log("No collecting event selected, aborting change.");
									return;
								} else if (new_collecting_event_id == "#getCatalogedItem.collecting_event_id#") {
									// but not if the same as the current one
									console.log("Selected collecting event is the same as the current one, aborting change.");
									return;
								}
								// launch a confirm dialog, if the user confirms, proceed with the change
								confirmDialog("Change the collecting event for this cataloged item?  This will unlink this cataloged item from the current collecting event and locality and switch it to the new collecting event and locality.", "Confirm change collecting event", 
								function() { 
									// otherwise make an ajax call to change the collecting event id on the cataloged item.
									$.ajax({
										url: '/specimens/component/functions.cfc',
										data: {
											method: 'changeCollectingEvent',
											collection_object_id: #collection_object_id#,
											collecting_event_id: new_collecting_event_id
										},
										success: function(response) {
                        	      var response = JSON.parse(response);
											if (response.success) {
												console.log("Collecting event changed successfully.");
												reloadLocality();
												reloadHeadingBar();
											} else {
												alert("Error changing collecting event: " + response.message);
											}
										},
										error: function(xhr, status, error) {
											// handle error
											console.error("Error changing collecting event:", error);
											handleError(xhr, status, error);
										}
									});
								} );
							}
						</script>
					</li>
					<li class="list-group-item px-0 mx-1">
						<!--- 
						<button type="button" id="btn_pane11" class="btn btn-xs btn-powder-blue py-0 small" onclick="openEditLocalityDialog(#collection_object_id#,'localityDialog','#guid#',reloadLocality)">Locality</button>
						--->
						<button type="button" id="btn_pane12" class="btn btn-xs btn-powder-blue py-0 small" onclick="openEditLocalityInPage(#collection_object_id#,reloadLocality)">Locality/Event</button>
					</li>
					<li class="list-group-item px-0 mx-1">
						<button type="button" id="btn_pane13" class="btn btn-xs btn-powder-blue py-0 small" onclick="openEditCollectorsDialog(#collection_object_id#,'collectorsDialog','#guid#',reloadLocality)">Collectors</button>
					</li>
					<li class="list-group-item px-0 mx-1">
						<button type="button" id="btn_pane14" class="btn btn-xs btn-powder-blue py-0 small" onclick="openEditNamedGroupsDialog(#collection_object_id#,'NamedGroupsDialog','#guid#',reloadNamedGroups)">Named&nbsp;Groups</button>
					</li>
					<!--- Navigation through records in a result set --->
					<cfif navigable>
						<cfif isNext is "yes">
							<li class="list-group-item px-0 mx-1">
								<span>
									<a href="/guid/#nextGUID#" onClick=" event.preventDefault(); $('##nextRecordForm').submit();">
										<img src="/images/next.gif" alt="[ Next Record ]">
									</a>
									<form action="/guid/#nextGUID#" method="post" id="nextRecordForm">
										<cfif len(resultBit) GT 0>
											<input type="hidden" name="result_id" value="#result_id#" />
										<cfelseif isDefined("old") AND len(old) GT 0>
											<input type="hidden" name="old" value="true" />
										</cfif>
									</form>
								</span>
							</li>
							<li class="list-group-item px-0 mx-1">
								<span>
									<a href="/guid/#lastGUID#" onClick=" event.preventDefault(); $('##lastRecordForm').submit();">
										<img src="/images/last.gif" alt="[ Last Record ]">
									</a>
									<form action="/guid/#lastGUID#" method="post" id="lastRecordForm">
										<cfif len(resultBit) GT 0>
											<input type="hidden" name="result_id" value="#result_id#" />
										<cfelseif isDefined("old") AND len(old) GT 0>
											<input type="hidden" name="old" value="true" />
										</cfif>
									</form>
								</span>
							</li>
						<cfelse>
							<li class="list-group-item px-0 mx-1">
								<img src="/images/no_next.gif" alt="[ inactive button ]">
							</li>
							<li class="list-group-item px-0 mx-1">
								<img src="/images/no_last.gif" alt="[ inactive button ]">
							</li>
						</cfif>
					</cfif>
				</ul>
			</div>
		</div>
	</cfif>
	
	<div class="container-fluid " id="SpecimenDetailsDiv">
		<div class="row mx-0 mt-2">

			<!----------------------------- one left column for media only if media exist ---------------------------------->
			<cfset specimenMediaCount = getMediaHTML(collection_object_id = "#collection_object_id#", relationship_type = "shows", get_count = 'true')>
			<cfset specimenMediaCount = val(rereplace(specimenMediaCount,"[^0-9]","","all"))>
			<cfif specimenMediaCount gt 0>
				<div class="col-12 col-sm-3 col-md-3 col-lg-3 col-xl-3 px-1 mb-2 float-left">

					<!-----------------------------Media----------------------------------> 
					<div class="accordion" id="accordionMedia">
						<div class="card mb-2 bg-light">
							<div id="mediaDialog"></div>
							<div class="card-header" id="headingMedia">
								<h3 class="h5 my-0 text-dark">
									<button type="button" class="headerLnk text-left h-100 w-100" aria-label="mediaPane" data-toggle="collapse" data-target="##mediaPane" aria-expanded="true" aria-controls="mediaPane" title="media">
										Media
										<span class="text-dark">(<span id="specimenMediaCount">#specimenMediaCount#</span>)</span>
									</button>
									<cfif listcontainsnocase(session.roles,"manage_specimens")>
										<a role="button" href="javascript:void(0)" class="btn btn-xs small py-0 anchorFocus" id="btn_openEditMediaDialog" onClick="openEditMediaDialog(#collection_object_id#,'mediaDialog','#guid#',reloadSpecimenMedia)">Add/Remove</a>
									</cfif>
								</h3>
							</div> 
							<div id="mediaPane" class="collapse show"aria-labelledby="headingMedia" <cfif #specimenMediaCount# gt 24>style="height:940px;"</cfif> data-parent="##accordionMedia">
								<cfset specimenMediaBlock = getMediaHTML(collection_object_id = "#collection_object_id#", relationship_type = "shows")>
								<div class="card-body text-center" id="specimenMediaCardBody">
									<cfif #specimenMediaCount# gt 24><p class="smaller">Click media header once to close and again to see all #specimenMediaCount#.</p></cfif>
									#specimenMediaBlock#
								</div>
							</div>
						</div>
					</div>
				</div>
				<!--- three column layout --->
				<cfset twoThreeColumnClasses="col-sm-9 col-md-9 col-lg-9 col-xl-9 float-left">
			<cfelse>
				<!--- two column layout --->
				<div id="mediaDialog"></div>
				<cfset twoThreeColumnClasses="col-sm-12 col-md-12 col-lg-12 col-xl-12 float-left">
			</cfif>

			<!----------------------------- two right columns ---------------------------------->
			<div class="col-12 mb-2 clearfix px-0 #twoThreeColumnClasses#">

				<!---- column 2 the leftmost of the two right columns ---->
				<div class="col-12 col-lg-6 px-1 float-left"> 
										
					<!-----------------------------Identifiers----------------------------------> 
							
					<div class="accordion" id="accordionIdentifiers">
						<div class="card mb-2 bg-light">
							<cfset blockidentifiers = getIdentifiersHTML(collection_object_id = "#collection_object_id#")>
							<div class="card-header" id="headingIdentifiers">
								<h3 class="h5 my-0">
									<button type="button" role="button" aria-label="identifiers pane" class="headerLnk text-left w-100" data-toggle="collapse" data-target="##identifiersPane" aria-expanded="true" aria-controls="identifiersPane">
										Cataloged Item
									</button>
								</h3>
							</div>
							<div id="identifiersPane" class="collapse show" aria-labelledby="headingIdentifiers" data-parent="##accordionIdentifiers">
								<div class="card-body" id="identifiersCardBody">
									#blockidentifiers#
								</div>
							</div>
						</div>
					</div>
				
					<!------------------------------------ identifications ------------------------------------>
					<div class="accordion" id="accordionID">
						<div class="card mb-2 bg-light">
							<div id="identificationsDialog"></div>
							<cfset blockident = getIdentificationsHTML(collection_object_id = "#collection_object_id#")>
							<div class="card-header" id="headingID">
								<h3 class="h5 my-0">
									<button type="button" role="button" aria-label="identifications pane" class="headerLnk text-left w-100" data-toggle="collapse" data-target="##identificationsPane" aria-expanded="true" aria-controls="identificationsPane">
										Identifications
									</button>
									<cfif len(#blockident#) gt 10> 
										<cfif listcontainsnocase(session.roles,"manage_specimens")>
											<a role="button" href="javascript:void(0)" id="btn_openEditIdentDialog" class="anchorFocus btn btn-xs small py-0" onClick="openEditIdentificationsInPage(#collection_object_id#,'identificationsDialog','#guid#',reloadIdentifications)">
												Edit
											</a>
										</cfif>
									<cfelse>
										<cfif listcontainsnocase(session.roles,"manage_specimens")>
											<a role="button" href="javascript:void(0)" id="btn_openEditIdentDialog" class="anchorFocus btn btn-xs small py-0" onClick="openEditIdentificationsDialog(#collection_object_id#,'identificationsDialog','#guid#',reloadIdentifications)">
												Add
											</a>
										</cfif>
									</cfif>
								</h3>
							</div>
							<div id="identificationsPane" class="collapse show" aria-labelledby="headingID" data-parent="##accordionID">
								<div class="card-body" id="identificationsCardBody">
									#blockident#
									<div id="identificationHTML"></div>
								</div>
							</div>
						</div>
					</div>
					<!------------------------------------ Citations ------------------------------------------>
					<div class="accordion" id="accordionCitations">
						<div class="card mb-2 bg-light">
							<div id="citationsDialog"></div>
							<cfset blockcit = getCitationsHTML(collection_object_id = "#collection_object_id#")>
							<div class="card-header" id="headingCitations">
								<h3 class="h5 my-0 text-dark">
									<button type="button" class="headerLnk text-left h-100 w-100" data-toggle="collapse" aria-label="citations Pane" data-target="##citationsPane" aria-expanded="true" aria-controls="citationsPane">
										Citations
									</button>
									<cfif listcontainsnocase(session.roles,"manage_specimens")>
										<a role="button" href="javascript:void(0)" class="btn btn-xs small py-0 anchorFocus" onClick="openEditCitationsDialog(#collection_object_id#,'citationsDialog','#guid#',reloadCitations)">Edit</a>
									</cfif>
								</h3>
							</div>
							<div id="citationsPane" class="collapse show" aria-labelledby="headingCitations" data-parent="##accordionCitations">
								<cfif len(trim(#blockcit#)) GT 0>
									<div class="card-body pt-2 pb-1" id="citationsCardBody">
										#blockcit#
									</div>
								<cfelse>
									<div class="card-body" id="citationsCardBody">
										<ul class="list-group">
											<li class="small list-group-item py-0 font-italic">None</li>
										</ul>
									</div>
								</cfif>
								<cfset citationMediaCount = getCitationMediaHTML(collection_object_id="#collection_object_id#",get_count="true")>
								<cfif refind("^[0-9 ]+$",citationMediaCount) EQ 0>
									<!--- error, display the resulting error message --->
									#citationMediaCount#
								</cfif>
								<cfif citationMediaCount gt 0>
									<div class="">
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
								<h3 class="h5 my-0">
									<button type="button" aria-label="OtherID Pane" class="headerLnk text-left w-100 h-100" aria-expanded="true" aria-controls="OtherIDsPane" data-toggle="collapse" data-target="##OtherIDsPane">
										Other Identifiers
									</button>
									<cfif len(#blockotherid#) gt 1> 
										<cfif listcontainsnocase(session.roles,"manage_specimens")>
											<a role="button" href="javascript:void(0)" class="anchorFocus btn btn-xs small py-0" onClick="openEditOtherIDsDialog(#collection_object_id#,'otherIDsDialog','#guid#',reloadOtherIDs)">
												Edit
											</a>
										</cfif>
									<cfelse>
										<cfif listcontainsnocase(session.roles,"manage_specimens")>
											<a role="button" href="javascript:void(0)" class="btn btn-xs small py-0 anchorFocus" onClick="openEditOtherIDsDialog(#collection_object_id#,'otherIDsDialog','#guid#',reloadOtherIDs)">
												Add
											</a>
										</cfif>
									</cfif>
								</h3>
							</div>
							<div id="OtherIDsPane" class="collapse show" aria-labelledby="headingOtherID" data-parent="##accordionOtherID">
								<cfif len(trim(#blockotherid#)) GT 0> 
									<div class="card-body" id="otherIDsCardBody">
										#blockotherid# 
									</div>
								<cfelse>
									<div class="card-body py-0" id="otherIDsCardBody">
										<ul class="list-group my-0">
											<li class="small list-group-item py-0 font-italic">None</li>
										</ul>
									</div>
								</cfif>
							</div>
						</div>
					</div>
					<!------------------------------------ parts ---------------------------------------------->
					<div class="accordion" id="accordionParts">
						<div class="card mb-2 bg-light">
							<div id="partsDialog"></div>
							<div id="editPartAttributesDialog"></div>
							<div class="card-header" id="headingParts">
								<h3 class="h5 my-0">
									<button type="button" class="headerLnk text-left w-100 h-100" aria-controls="PartsPane" aria-label="Parts Pane" aria-expanded="true" data-toggle="collapse" data-target="##PartsPane">
										<cfif len(partCount) GT 0>
											Parts <span class="text-dark">(<span id="partCountSpan">#partCount#</span>)</span>
										<cfelse>
											Parts <span class="text-dark"><span id="partCountSpan"></span></span>
										</cfif>
									</button>
									<cfif listcontainsnocase(session.roles,"manage_specimens")>
										<a href="javascript:void(0)" role="button" class="btn btn-xs small py-0 anchorFocus" onClick="openEditPartsInPage(#collection_object_id#,reloadParts)">
											Edit
										</a>
									</cfif>
								</h3>
							</div>
							<div id="PartsPane" <cfif #partCount# gt 5>style="height:300px;"</cfif> class="collapse show" aria-labelledby="headingParts" data-parent="##accordionParts">
								<div class="card-body px-1" id="partsCardBody">
									<p class="smaller py-0 mb-0 text-center w-100">
										<cfif #partCount# gt 5>click once to close and another time to see all #partCount#</cfif>
									</p>
									<cfset blockparts = getPartsHTML(collection_object_id = "#collection_object_id#")>
									#blockparts#
								</div>
							</div>
						</div>
					</div>
					<!------------------------------------ attributes ----------------------------------------->
					<div class="accordion" id="accordionAttributes">
						<div class="card mb-2 bg-light">
							<div id="attributesDialog"></div>
							<cfset blockattributes = getAttributesHTML(collection_object_id = "#collection_object_id#")>
							<div class="card-header" id="headingAttributes">
								<h3 class="h5 my-0">
									<button type="button" aria-label="Attributes Pane" class="headerLnk text-left w-100 h-100" aria-expanded="true" aria-controls="AttributesPane" data-toggle="collapse" data-target="##AttributesPane">
										Attributes
									</button>
									<cfif len(#blockattributes#) gt 50> 
										<cfif listcontainsnocase(session.roles,"manage_specimens")>
											<a href="javascript:void(0)" role="button" class="btn btn-xs small py-0 anchorFocus" onClick="openEditAttributesDialog(#collection_object_id#,'attributesDialog','#guid#',reloadAttributes)">
												Edit
											</a>
										</cfif>
									<cfelse>
										<cfif listcontainsnocase(session.roles,"manage_specimens")>
											<a href="javascript:void(0)" role="button" class="btn btn-xs small py-0 anchorFocus" onClick="openEditAttributesDialog(#collection_object_id#,'attributesDialog','#guid#',reloadAttributes)">
												Add
											</a>
										</cfif>
									</cfif>
								</h3>
							</div>
							<div id="AttributesPane" class="collapse show" aria-labelledby="headingAttributes" data-parent="##accordionAttributes">
								<cfif len(trim(#blockattributes#)) GT 0>
									<div class="card-body px-1" id="attributesCardBody">
										#blockattributes#
									</div>
								<cfelse>
									<div class="card-body py-0" id="attributesCardBody">
										<ul class="list-group my-0">
											<li class="small list-group-item py-1 font-italic">None</li>
										</ul>
									</div>
								</cfif>
							</div>
						</div>
					</div>
					<!------------------------------------ relationships  ------------------------------------->
					<div class="accordion" id="accordionRelations">
						<div class="card mb-2 bg-light">
							<div id="relationsDialog"></div>
							<div class="card-header" id="headingRelations">
								<h3 class="h5 my-0">
									<button type="button" class="headerLnk w-100 h-100 text-left" aria-label="Relations Pane" data-toggle="collapse" aria-expanded="true" data-target="##RelationsPane">
										Relationships
									</button>
									<cfif listcontainsnocase(session.roles,"manage_specimens")>
										<a role="button" href="javascript:void(0)" class="btn btn-xs small py-0 anchorFocus" onClick="openEditRelationsDialog(#collection_object_id#,'relationsDialog','#guid#',reloadRelations)">
											Edit
										</a>
									</cfif>
								</h3>
							</div>
							<cfset blockrel = getRelationsHTML(collection_object_id = "#collection_object_id#")>
							<div id="RelationsPane" class="collapse show" aria-labelledby="headingRelations" data-parent="##accordionRelations">
								<div class="card-body" id="relationsCardBody">
									#blockrel# 
								</div>
							</div>
						</div>
					</div>
					<!------------------------------------ coll object remarks -------------------------------->
					<div class="accordion" id="accordionRemarks">
						<div class="card mb-2 bg-light">
							<div id="remarksDialog"></div>
							<cfset blockRemarks = getRemarksHTML(collection_object_id = "#collection_object_id#")>
							<div class="card-header" id="headingRemarks">
								<h3 class="h5 my-0">
									<button type="button" class="headerLnk text-left w-100 h-100" aria-label="Remarks Pane" aria-expanded="true" aria-controls="RemarksPane" data-toggle="collapse" data-target="##RemarksPane">
										Cataloged Item Remarks
									</button>
									<cfif listcontainsnocase(session.roles,"manage_specimens")>
										<a href="javascript:void(0)" role="button" class="btn btn-xs small py-0 anchorFocus" onClick="openEditRemarksDialog(#collection_object_id#,'remarksDialog','#guid#',reloadRemarks)">
											Edit
										</a>
									</cfif>
								</h3>
							</div>
							<div id="RemarksPane" class="collapse show" aria-labelledby="headingRemarks" data-parent="##accordionRemarks">
								<div class="card-body" id="remarksCardBody">
									#blockRemarks#
								</div>
							</div>
						</div>
					</div>
					<!------------------------------------ annotations -------------------------------->
					<div class="accordion" id="accordionAnnotations">
						<div class="card mb-2 bg-light">
							<div id="annotationDialog"></div>
							<div id="AnnotationsDialog"></div>
							<cfset blockAnnotations = getAnnotationsHTML(collection_object_id = "#collection_object_id#")>
							<div class="card-header" id="headingAnnotations">
								<h3 class="h5 my-0">
									<button type="button" class="headerLnk text-left w-100 h-100" aria-expanded="true" aria-label="Annotations Pane" aria-controls="AnnotationsPane" data-toggle="collapse" data-target="##AnnotationsPane">
										Collection Object Annotations
									</button>
 									<cfif isdefined("session.username") AND len(session.username) gt 0>
										<!--- anyone with a username can create annotations --->
										<a href="javascript:void(0)" role="button" class="btn btn-xs small py-0 mr-5 anchorFocus" onclick="openAnnotationsDialog('annotationDialog','collection_object',#collection_object_id#,reloadAnnotations);">
											Report Bad Data
										</a>
									</cfif>
									<cfif listcontainsnocase(session.roles,"manage_specimens")>
										<a href="javascript:void(0)" role="button" class="btn btn-xs small py-0 anchorFocus" onClick="openEditAnnotationsDialog(#collection_object_id#,'AnnotationsDialog','#guid#',reloadAnnotations)">
											Edit
										</a>
									</cfif>
								</h3>
							</div>
							<div id="AnnotationsPane" class="collapse show" aria-labelledby="headingAnnotations" data-parent="##accordionAnnotations">
								<div class="card-body" id="annotationsCardBody">
									#blockAnnotations#
								</div>
							</div>
						</div>
					</div>
					<!------------------------------------ Meta Data------------------------------------------->
					<cfif #oneOfUs# eq 1>
						<div class="accordion" id="accordionMeta">
							<div class="card mb-2 bg-light">
								<div id="metaDialog"></div>
								<cfset blockmeta = getMetaHTML(collection_object_id = "#collection_object_id#")>
								<div class="card-header" id="headingMeta">
									<h3 class="h5 my-0">
										<button type="button" class="headerLnk text-left w-100 h-100" aria-expanded="true" aria-label="Meta Pane" aria-controls="MetaPane" data-toggle="collapse" data-target="##MetaPane">
											Metadata
										</button>
									</h3>
								</div>
								<div id="MetaPane" class="collapse show" aria-labelledby="headingMeta" data-parent="##accordionMeta">
									<div class="card-body" id="metaCardBody">
										#blockmeta#
									</div>
								</div>
							</div>
						</div>
					</cfif>
				</div>

				<!----- start of column 3 (rightmost of the two right columns) --->
				<div class="col-12 col-lg-6 px-1 float-left"> 
					<!-------------------.locality and collecting event----------------->
					<div class="accordion" id="accordionLocality">
						<div class="card mb-2 bg-light">
							<div id="localityDialog"></div>
							<div id="collectorsDialog"></div>
							<div class="card-header" id="headingLocality">
								<h3 class="h5 my-0">
									<button type="button" data-toggle="collapse" aria-expanded="true" aria-label="Locality Pane" data-target="##LocalityPane" aria-controls="LocalityPane" class="headerLnk w-100 h-100 text-left">
										Location and Collecting Event
									</button>
									<cfif listcontainsnocase(session.roles,"manage_specimens")>
										<a href="javascript:void(0)" role="button" class="btn btn-xs small py-0 anchorFocus" onClick="openEditLocalityInPage(#collection_object_id#,reloadLocality)">
											Edit
										</a>
									</cfif>
								</h3>
							</div>
							<cfset blocklocality = getLocalityHTML(collection_object_id = "#collection_object_id#")>
							<div id="LocalityPane" class="collapse show" aria-labelledby="headingLocality" data-parent="##accordionLocality">
								<div class="card-body" id="localityCardBody">
									#blocklocality# 
								</div>
							</div>
						</div>
					</div>
					<!------------------- Preparators ---------------------------------->
					<div class="accordion" id="accordionPreparators">
						<div class="card mb-2 bg-light">
							<div id="preparatorsDialog"></div>
							<cfset blockpreparators = getPreparatorsHTML(collection_object_id = "#collection_object_id#")>
							<div class="card-header" id="headingPreparators">
								<h3 class="h5 my-0">
									<button type="button" data-toggle="collapse" class="w-100 h-100 headerLnk text-left" aria-label="Preparators Pane" aria-controls="PreparatorsPane" aria-expanded="true" data-target="##PreparatorsPane">
										Preparators
									</button>
									<cfif listcontainsnocase(session.roles,"manage_specimens")>
										<a href="javascript:void(0)" role="button" class="btn btn-xs small py-0 anchorFocus" onClick="openEditPreparatorsDialog(#collection_object_id#,'preparatorsDialog','#guid#',reloadPreparators)">
											Edit
										</a>
									</cfif>
								</h3>
							</div>
							<div id="PreparatorsPane" class="collapse show" aria-labelledby="headingPreparators" data-parent="##accordionPreparators">
								<div class="card-body" id="collectorsCardBody">
									#blockpreparators# 
								</div>
							</div>
						</div>
					</div>
					<!------------------- Ledger---------------------------------------->
					<cfset ledgerMediaCount = getMediaHTML(collection_object_id = "#collection_object_id#", relationship_type = "documents", get_count = 'true')>
					<cfset ledgerMediaCount = val(rereplace(ledgerMediaCount,"[^0-9]","","all"))>
					<div class="accordion" id="accordionLedger">
						<div class="card mb-2 bg-light">
							<div id="ledgerDialog"></div>
							<div class="card-header" id="headingLedger">
								<h3 class="h5 my-0">
									<button type="button" aria-controls="ledgerPane" class="headerLnk text-left h-100 w-100" aria-label="ledger Pane" data-toggle="collapse" data-target="##ledgerPane" aria-expanded="true" >
										Documentation
									</button>
								</h3>
							</div>
							<div id="ledgerPane" class="collapse show" aria-labelledby="headingLedger" data-parent="##accordionLedger">
								<cfif ledgerMediaCount gt 0> 
									<div class="card-body" id="ledgerCardBody">
										<cfset ledgerBlock = getMediaHTML(collection_object_id = "#collection_object_id#", relationship_type = "documents")>
										<div class="col-12 px-2 mb-1 px-md-2 pt-1 float-left">
											#ledgerBlock# 
										</div>
									</div>
								<cfelse>
									<div class="card-body py-0" id="ledgerCardBody">
										<ul class="list-group my-0">
											<li class="small list-group-item py-0 font-italic">None</li>
										</ul>
									</div>
								</cfif>
							</div>
						</div>
					</div>
					<!------------------- tranactions  --------------------------------->
					<div class="accordion" id="accordionTransactions">
						<div class="card mb-2 bg-light">
							<div id="transactionsDialog"></div>
							<div class="card-header" id="headingTransactions">
								<h3 class="h5 my-0">
									<button type="button" aria-controls="TransactionsPane" class="w-100 h-100 text-left headerLnk" aria-label="Transactions Pane" aria-expanded="true" data-toggle="collapse" data-target="##TransactionsPane">
										Transactions
									</button>
								</h3>
							</div>
							<div id="TransactionsPane" class="collapse show" aria-labelledby="headingTransactions" data-parent="##accordionTransactions">
								<div class="card-body" id="transactionsCardBody">
									<cfset block = getTransactionsHTML(collection_object_id = "#collection_object_id#")>
									#block#
								</div>
							</div>
						</div>
					</div>
					<!------------------- named groups  -------------------------------->
					<div class="accordion" id="accordionNamedGroups">
						<div class="card mb-2 bg-light">
							<div id="NamedGroupsDialog"></div>
							<div class="card-header" id="headingNamedGroups">
								<h3 class="h5 my-0">
									<button type="button" role="button" aria-label="Named Groups Pane" aria-controls="NamedGroupsPane" class="w-100 h-100 text-left headerLnk" aria-expanded="true" data-toggle="collapse" data-target="##NamedGroupsPane">
										Featured Collections (Named Groups)
									</button>
									<cfif listcontainsnocase(session.roles,"manage_specimens")>
										<a role="button" href="javascript:void(0)" class="btn btn-xs small py-0 anchorFocus" onClick="openEditNamedGroupsDialog(#collection_object_id#,'NamedGroupsDialog','#GUID#',reloadNamedGroups)">
											Edit
										</a>
									</cfif>
								</h3>
							</div>
							<div id="NamedGroupsPane" class="collapse show" aria-labelledby="headingNamedGroups" data-parent="##accordionNamedGroups">
								<cfset namedGroupBlock = getNamedGroupsHTML(collection_object_id = "#collection_object_id#")>
								<div class="card-body" id="namedGroupsCardBody">
									#namedGroupBlock#
								</div>
							</div>
						</div>
					</div>
				</div> <!--- end of column 3 --->
			</div><!--- end of column to hold the two right colums (the two colums if no media) --->
		</div><!--- end row --->
	</div><!--- end container-fluid --->
</cfoutput>

<!--- (6) QC section --->
<cfoutput>
	<cfif isdefined("session.roles") and listfindnocase(session.roles,"collops")>
		<div class="container-fluid">
			<section class="row" id="QCSection">
				<div class="col-12 px-2 border bg-light rounded mt-2">
					<!---  Include the TDWG BDQ TG2 test integration --->
					<script type='text/javascript' language="javascript" src='/dataquality/js/bdq_quality_control.js'></script>
					<script>
						function runTests() {
							loadNameQC(#collection_object_id#, "", "NameDQDiv");
							loadSpaceQC(#collection_object_id#, "", "SpatialDQDiv");
							loadEventQC(#collection_object_id#, "", "EventDQDiv");
						}
					</script>
					<input type="button" value="Run Quality Control Tests" class="btn btn-secondary btn-xs" onClick=" runTests(); ">
					<!---  Scientific Name tests --->
					<div id="NameDQDiv"></div>
					<!---  Spatial tests --->
					<div id="SpatialDQDiv"></div>
					<!---  Temporal tests --->
					<div id="EventDQDiv"></div>
				</div>					
			</section><!-- end QCSection --->
		</div>
	</cfif>
</cfoutput>
</div><!--- end of specimenDetailsPageContent --->

<!--- (7) Finish up with the page footer --->
<cfinclude template="/shared/_footer.cfm">
