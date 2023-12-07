<cfset pageTitle = "Add Encumbrance for Search Result">
<cfinclude template="/shared/_header.cfm">

<cfif not isDefined("result_id") OR len(result_id) EQ 0>
	<cfthrow message = "No result_id provided for result set on which to set an encumbrance.">
</cfif>
<cfif not isDefined("action") OR len(action) EQ 0>
	<cfset action="entryPoint">
</cfif>
<cfoutput>
	<main class="container-fluid" id="content">
</cfoutput>

<!--------------------------------------------------------------------------------->
<cfswitch expression="#action#">
	<cfcase value="entryPoint">
		<cfoutput>
			<cfquery name="countItems" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="countItems_result">
				SELECT count(distinct cataloged_item.collection_object_id) ct 
				FROM
					cataloged_item
					join collecting_event on cataloged_item.collecting_event_id = collecting_event.collecting_event_id
					join locality on collecting_event.locality_id = locality.locality_id 
					join geog_auth_rec on locality.geog_auth_rec_id = geog_auth_rec.geog_auth_rec_id 
					join collection on cataloged_item.collection_id = collection.collection_id 
				WHERE 
					cataloged_item.collection_object_id IN 
						(
							select collection_object_id from user_search_table 
							where 
								result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
						) 
			</cfquery>
			<section class="row mx-0" aria-labelledby="formheading">
				<div class="col-12 pt-4">
					<h1 class="h3 px-1" id="formheading" >
						Add or Remove an Encumbrance to the (#countItems.ct#) cataloged items listed below.
						<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_collection")>
							<a class="btn btn-xs btn-primary" target="_blank" href="/Encumbrances.cfm?action=create">Create New Encumbrance</a>
						</cfif>
					</h1>
					<form name="changeEncumbrance" method="post" action="/specimens/changeQueryEncumbrance.cfm">
						<input type="hidden" name="result_id" value="#result_id#">
						<div class="form-row mb-2">
							<div class="col-12 col-md-8 pb-2">
								<label for="encumbrance" class="data-entry-label">Encumbrance</label>
								<input type="text" id="encumbrance" name="encumbrance" value="" required class="data-entry-input reqdClr">
								<input type="hidden" id="encumbrance_id" name="encumbrance_id" value="">
								<script>
									$(document).ready(function() { 
										makeEncumbranceAutocompleteMeta('encumbrance', 'encumbrance_id');
									});
								</script>
							</div>
							<div class="col-12 col-md-4 pb-2">
								<label for="action" class="data-entry-label">Action to take on these specimens</label>
								<select id="action" name="action" required class="data-entry-select reqdClr">
									<option selected value=""></option>
									<option value="addItems">Add To Encumbrance</option>
									<option value="removeItems">Remove From Encumbrance</option>
								</select>
							</div>
							<div class="col-12 col-md-4 col-lg-4 mb-2 mb-md-0">
								<div class="data-entry-label">&nbsp;</div>
								<input type="submit" id="s_btn" value="Change" class="btn btn-xs btn-warning">
							</div>
						</div>
					</form>
				</div>
			</section>
		</cfoutput>
	</cfcase>
	<!--------------------------------------------------------------------------------->
	<cfcase value="addItems">
		<cfif not isDefined("encumbrance_id") or len(encumbrance_id) EQ 0>
			<cfthrow message="No Enumbrance specified.">
		</cfif>
		<cfquery name="getRecords" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			SELECT collection_object_id 
			FROM user_search_table
			WHERE
				result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
		</cfquery>
		<cfloop query="getRecords">
			<cftransaction>
				<cfquery name="checkEncumbrance" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT count(*) ct 
					FROM coll_object_encumbrance
					WHERE
						encumbrance_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#encumbrance_id#"> AND
						collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getRecords.collection_object_id#">
				</cfquery>
				<cfif checkEncumbrance.ct EQ 0>
					<cfquery name="addToEncumbrance" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						INSERT INTO coll_object_encumbrance (
							encumbrance_id,
							collection_object_id
							) values (
							<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#encumbrance_id#">,
							<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getRecords.collection_object_id#">
						)
					</cfquery>
				</cfif>
				<cftransaction action="commit"/>
			</cftransaction>
		</cfloop>
		<cflocation url="/specimens/changeQueryEncumbrance.cfm?result_id=#encodeForURL(result_id)#&action=updateComplete" addtoken="false">
	</cfcase>
	<!--------------------------------------------------------------------------------->
	<cfcase value="removeItems">
		<cfif not isDefined("encumbrance_id") or len(encumbrance_id) EQ 0>
			<cfthrow message="No Enumbrance specified.">
		</cfif>
		<cfquery name="getRecords" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			SELECT collection_object_id 
			FROM user_search_table
			WHERE
				result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
		</cfquery>
		<cfloop query="getRecords">
			<cfquery name="removeFromEncumbrance" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				DELETE 
				FROM coll_object_encumbrance
				WHERE
					encumbrance_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#encumbrance_id#"> AND
					collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getRecords.collection_object_id#">
			</cfquery>
		</cfloop>
		<cflocation url="/specimens/changeQueryEncumbrance.cfm?result_id=#encodeForURL(result_id)#&action=updateComplete" addtoken="false">
	</cfcase>
	<!--------------------------------------------------------------------------------->
	<cfcase value="updateComplete">
		<cfset returnURL = "/specimens/changeQueryEncumbrance.cfm?result_id=#encodeForURL(result_id)#">
		<cfoutput>
			<cfquery name="countRecords" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT count(distinct collection_object_id) ct
				FROM user_search_table
				WHERE
					result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
			</cfquery>
			<div class="container-fluid">
				<div class="row mx-0">
					<div class="col-12 px-4 mt-3">
						<h2 class="h2">Changed encumbrance for all #countRecords.ct# cataloged items [in #encodeForHtml(result_id)#]</h2>
						<ul class="col-12 list-group list-group-horizontal">
							<li class="list-group-item d-flex justify-content-between align-items-center">
								<a href="#returnURL#"><i class="fa fa-arrow-left"></i> Back to Manage Encumbrance</a>
							</li>
							<li class="list-group-item d-flex justify-content-between align-items-center">
								<a href="/specimens/manageSpecimens.cfm?result_id=#encodeForURL(result_id)#"><i class="fa fa-arrow-left"></i> Back to Manage Results </a>
							</li>
						</ul>
					</div>
				</div>
			</div>
		</cfoutput>
	</cfcase>
</cfswitch>

<cfoutput>
	<!--- NOTE: has left joins to parts and encumbrances, cfloop groups by collection_object_id and loop contains loops through parts and encumbrances --->
	<cfquery name="getItems" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		 SELECT distinct
			cataloged_item.collection_object_id as collection_object_id, 
			cat_num, 
			concatSingleOtherId(cataloged_item.collection_object_id,'#session.CustomOtherIdentifier#') AS CustomID,
  			MCZBASE.GET_SCIENTIFIC_NAME_AUTHS (cataloged_item.collection_object_id) scientific_name, 
			country, 
			state_prov, 
			county, 
			cataloged_item.collection_object_id, 
			quad, 
			institution_acronym, 
			collection.collection_cde, 
			collection.collection, 
			part_name, 
			specimen_part.collection_object_id AS partID, 
			MCZBASE.get_agentnameoftype(encumbrance.encumbering_agent_id) AS encumbering_agent, 
			expiration_date, 
			expiration_event, 
			encumbrance, 
			encumbrance.made_date AS encumbered_date, 
			encumbrance.remarks AS remarks, 
			encumbrance_action, 
			encumbrance.encumbrance_id 
		FROM 
			cataloged_item
			join collecting_event on cataloged_item.collecting_event_id = collecting_event.collecting_event_id
			join locality on collecting_event.locality_id = locality.locality_id 
			join geog_auth_rec on locality.geog_auth_rec_id = geog_auth_rec.geog_auth_rec_id 
			join collection on cataloged_item.collection_id = collection.collection_id 
			left join specimen_part on cataloged_item.collection_object_id = specimen_part.derived_from_cat_item
			left join coll_object_encumbrance on cataloged_item.collection_object_id=coll_object_encumbrance.collection_object_id
			left join encumbrance on coll_object_encumbrance.encumbrance_id = encumbrance.encumbrance_id
		WHERE 
			cataloged_item.collection_object_id IN 
				(
					select collection_object_id from user_search_table 
					where 
						result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
				) 
		ORDER BY 
			cataloged_item.collection_object_id
	</cfquery>
	<!--- open main tag is above before cfswitch block --->
		<section class="row mx-0"> 
			<div class="col-12 pb-4">
				<table class="table table-responsive table-striped d-xl-table">
					<thead class="thead-light">
						<tr>
							<td><strong>GUID</strong></td>
							<td><strong>#session.CustomOtherIdentifier#</strong></td>
							<td><strong>Scientific Name</strong></td>
							<td><strong>Country</strong></td>
							<td><strong>State</strong></td>
							<td><strong>County</strong></td>
							<td><strong>Quad</strong></td>
							<td><strong>Part</strong></td>
							<td><strong>Existing Encumbrances</strong></td>
						</tr>
					</thead>
					<tbody>
						<cfloop query="getItems" group="collection_object_id">
							<tr>
								<td>#getItems.collection# <a href="/guid/MCZ:#collection_cde#:#cat_num#" target="_blank">MCZ:#collection_cde#:#cat_num#</a></td>
								<td>#CustomID#&nbsp;</td>
								<td><i>#Scientific_Name#</i></td>
								<td>#Country#&nbsp;</td>
								<td>#State_Prov#&nbsp;</td>
								<td>#county#&nbsp;</td>
								<td>#quad#&nbsp;</td>
								<td>
									<cfquery name="getParts" dbtype="query">
										SELECT 
											part_name, 
											partID
										FROM 
											getItems
										WHERE 
											collection_object_id = #collection_object_id# 
										GROUP BY
											part_name, 
											partID
									</cfquery>
									
									<cfloop query="getParts">
										<cfif len (#getParts.partID#) gt 0>
											#getParts.part_name#<br>
										</cfif>
									</cfloop>
								</td>
								<cfset existingBlock = "existEnc_#collection_object_id#">
								<td id="#existingBlock#">
									<cfquery name="getEncumbrances" dbtype="query">
										select 
											collection_object_id,
											encumbrance_id,
											encumbrance,
											encumbrance_action,
											encumbering_agent,
											encumbered_date,
											expiration_date,
											expiration_event,
											remarks
										FROM getItems
										WHERE 
											collection_object_id = #collection_object_id# 
										GROUP BY
											collection_object_id,
											encumbrance_id,
											encumbrance,
											encumbrance_action,
											encumbering_agent,
											encumbered_date,
											expiration_date,
											expiration_event,
											remarks
									</cfquery>
									<ul>
									<cfloop query="getEncumbrances">
										<cfif len(#encumbrance#) gt 0>
											<li>
												#encumbrance# (#encumbrance_action#) 
												by #encumbering_agent# made 
												#dateformat(encumbered_date,"yyyy-mm-dd")#, 
												expires #dateformat(expiration_date,"yyyy-mm-dd")# 
												#expiration_event# #remarks#
												<form name="removeEncumb_#collection_object_id#_#encumbrance_id#">
													<input type="button" value="Remove" class="btn btn-xs btn-warning"
														aria-label="Remove this cataloged item from this encumbrance"
														onClick="removeFromEncumbrance(#encumbrance_id#,#getEncumbrances.collection_object_id#,'#existingBlock#');">
												</form>
											</li>
										<cfelse>
											<li>None</li>
										</cfif> 
									</cfloop>
									</ul>
								</td>
							</tr>
						</cfloop>
					</tbody>
				</table>
				<script>
					// TODO: Move to specimens/js/specimens.js library accessible from cataloged item page
					function removeFromEncumbrance(encumbrance_id, collection_object_id, reloadBlock) { 
						jQuery.ajax({
							dataType: "json",
							url: "/specimens/component/functions.cfc",
							data: { 
								method : "removeObjectFromEncumbrance",
								encumbrance_id : encumbrance_id,
								collection_object_id : collection_object_id,
								returnformat : "json",
								queryformat : 'column'
							},
							error: function (jqXHR, status, message) {
								messageDialog("Error removing item from encumbrance: " + status + " " + jqXHR.responseText ,'Error: '+ status);
							},
							success: function (result) {
								reloadEncumbrances(reloadBlock,collection_object_id);
							}
						});
					}
					function reloadEncumbrances(reloadBlock,collection_object_id) { 
						jQuery.ajax({
							url: "/specimens/component/functions.cfc",
							data : {
								method : "getEncumbrancesHTML",
								collection_object_id: collection_object_id,
								containing_block: reloadBlock
							},
							success: function (result) {
								$("##" + reloadBlock ).html(result);
							},
							error: function (jqXHR, textStatus, error) {
								handleFail(jqXHR,textStatus,error,"loading encumbrances html");
							},
							dataType: "html"
						});
					}
				</script>
			</div>
		</section>
	</main>
</cfoutput>

<cfinclude template="/shared/_footer.cfm">
