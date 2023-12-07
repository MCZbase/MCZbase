<!---
specimens/changeQueryNamedCollection.cfm

For managing arbitrary groupings of collection objects, allows add or remove 
items from the group.

Copyright 2020-2023 President and Fellows of Harvard College

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
<cfset pageTitle = "Manage Cataloged Items in Named Group">
<cfinclude template="/shared/_header.cfm">
<cfif NOT isdefined("action") >
	<cfset action="selectColl">
</cfif>
<cfswitch expression="#action#">
	<cfcase value="selectColl">
		<cfoutput>
			<cfset pass = "">
			<cfif isdefined("collection_object_id") and listlen(collection_object_id) is 1>
				<cfset pass = "collection_object">
			<cfelseif  isdefined("collection_object_id") and listlen(collection_object_id) gt 1>
				<cfset pass = "collection_object list">
			<cfelseif isDefined("result_id") AND len(result_id) GT 0>
				<cfset pass = "result_id">
			</cfif>
			<cfquery name="getItems" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT
					cataloged_item.collection_object_id,
					cataloged_item.cat_num,
					MCZBASE.concatcoll(cataloged_item.collection_object_id) as collectors,
					geog_auth_rec.higher_geog,
					locality.spec_locality,
					collecting_event.verbatim_date,
					identification.scientific_name,
					collection.institution_acronym,
					collection.collection
				FROM
					cataloged_item
					join collecting_event on cataloged_item.collecting_event_id = collecting_event.collecting_event_id 
					join locality on collecting_event.locality_id = locality.locality_id
					left outer join geog_auth_rec on locality.geog_auth_rec_id = geog_auth_rec.geog_auth_rec_id 
					left outer join identification on cataloged_item.collection_object_id = identification.collection_object_id
					join collection on cataloged_item.collection_id = collection.collection_id
					<cfif isdefined("result_id") and len(result_id) gt 1>
						join user_search_table on cataloged_item.collection_object_id = user_search_table.collection_object_id
					<cfelseif (not isdefined("collection_object_id")) > 
						left outer join #session.SpecSrchTab# on cataloged_item.collection_object_id = #session.SpecSrchTab#.collection_object_id
					</cfif>
				WHERE
					identification.accepted_id_fg = 1 AND
					<cfif isdefined("result_id") and len(result_id) gt 1>
						result_id=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
					<cfelseif isdefined("collection_object_id") and listlen(collection_object_id) is 1>
						cataloged_item.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
					<cfelseif  isdefined("collection_object_id") and listlen(collection_object_id) gt 1>
						cataloged_item.collection_object_id IN (<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#" list="yes">)
					<cfelse>
						#session.SpecSrchTab#.collection_object_id is not null
					</cfif>
				ORDER BY cataloged_item.collection_object_id
			</cfquery>
			<div class="container-fluid mt-2 mb-3">
				<div class="row mx-0">
					<div class="col-12">
						<div role="region" aria-labeled-by="formheading">
							<h1 class="h2 mt-3" id="formheading">Add or Remove all the items (#getItems.recordcount#) listed below to/from the selected named group of cataloged items.</h1>
							<script>
								function changeItemsSubmitHandler() { 
									if ($('##underscore_collection_id').val() == ''){ 
										messageDialog('Error: You must select a named group from the Select a Named Group picklist before you can add or remove items.' ,'Error: Select a named group.');
									} else if ($('##action').val() == ''){ 
										messageDialog('Error: You must select an action to take on these items.' ,'Error: Select Add or Remove.');
									} else { 
										$('##changeItemsForm').removeAttr('onsubmit'); 
										$('##changeItemsForm').submit();
									}
								}
							</script>
							<form id="changeItemsForm" name="changeItems" method="post" action="/specimens/changeQueryNamedCollection.cfm" onsubmit="return noenter();">
								<input type="hidden" name="recordcount" value="#getItems.recordcount#">
								<input type="hidden" name="pass" value="#pass#">
								<cfif isdefined("collection_object_id") AND len(collection_object_id) GT 0 >
									<input type="hidden" name="collection_object_id" value="#collection_object_id#">
								</cfif>
								<cfif isdefined("result_id") AND len(result_id) GT 0 >
									<input type="hidden" name="result_id" value="#result_id#">
								</cfif>
								<div class="form-row mb-3">
									<div class="col-12 col-md-8">
										<label for="underscore_collection" class="px-2">Select a Named Group</label>
										<input type="text" name="collection_name" id="collection_name" class="data-entry-input reqdClr" required>
										<input type="hidden" name="underscore_collection_id" id="underscore_collection_id">
										<script>
											$(document).ready(function() {
												makeNamedCollectionPicker('collection_name','underscore_collection_id');
											});
										</script>
									</div>					
									<div class="col-12 col-md-4 pb-2">
										<label for="action" class="data-entry-label">Action to take on these specimens</label>
										<select id="action" name="action" required class="data-entry-select reqdClr">
											<option selected value=""></option>
											<option value="addItems">Add To Named Group</option>
											<option value="removeItems">Remove From Named Group</option>
										</select>
									</div>
									<div class="col-12 mt-3">
										<input type="button" id="remove_button" value="Change" class="btn btn-xs btn-primary" onclick=" changeItemsSubmitHandler(); ">
									</div>
								</div>
							</form>
						</div>
		
							<div class="form-row mb-5">
								<table class="table table-responsive-md table-striped">
									<thead class="thead-light">
										<tr>
										<th>Cat Num</th>
										<th>Scientific Name</th>
										<th>Collectors</th>
										<th>Geog</th>
										<th>Spec Loc</th>
										<th>Date</th>
									</tr>
									</thead>
									<tbody>
									<cfloop query="getItems" group="collection_object_id">
									<tr>
										<td>#collection# #cat_num#</td>
										<td style="width: 200px;">#scientific_name#</td>
										<td style="width: 200px;">#collectors#</td>
										<td>#higher_geog#</td>
										<td>#spec_locality#</td>
										<td style="width:100px;">#verbatim_date#</td>
									</tr>
									</cfloop>
									</tbody>
								</table>
		
							</div>
						</div>
					</div>
				</div>
			</div>
		</cfoutput>
	</cfcase>
	<cfcase value="addItems">
		<cfif NOT isdefined("underscore_collection_id")>
			<cfthrow message="No named group selected, unable to add cataloged items">
		<cfelseif len(underscore_collection_id) EQ 0 >
			<cfthrow message="No named group selected (blank id value provided), unable to add cataloged items">
		</cfif>
		<cfif NOT isdefined("recordcount") OR recordcount EQ 0>
			<cfthrow message="No cataloged items to add to named group.">
		</cfif>
		<cfif NOT isdefined("pass") OR len(pass) EQ 0>
			<cfthrow message="Error: No means included by which to add to named group.  File a bug report.">
		</cfif>
		<cfset numberInResult = 0>
		<cfset numberChanged = 0>
		<cfset collectionName = "">
		<cfif pass EQ "result_id">
			<cftransaction>
				<cfquery name="countToAdd" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT count(*) as ct 
					FROM user_search_table
					WHERE result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
				</cfquery>
				<cfif countToAdd.ct NEQ recordcount>
					<cfthrow message="Add failed.  Discrepancy between the expected and actual number of records to add, result set modified since search was run.">
				</cfif>
				<cfset numberInResult = countToAdd.ct>
				<cfquery name="unColl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT underscore_collection.underscore_collection_id as id, collection_name
					FROM underscore_collection
					WHERE underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
				</cfquery>
				<cfset idToAdd = unColl.id>
				<cfset collectionName = unColl.collection_name>
				<cfif unColl.recordcount NEQ 1>
					<cfthrow message="No such named group found, unable to add cataloged items">
				</cfif>
				<cfquery name="addItemsToColl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="add_result">
					INSERT /*+ ignore_row_on_dupkey_index ( underscore_relation (collection_object_id, underscore_collection_id ) ) */
						into underscore_relation (underscore_collection_id, collection_object_id)
					SELECT #idToAdd#, collection_object_id 
						FROM user_search_table
						WHERE result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
				</cfquery>
				<cfset numberChanged = add_result.recordcount>
			</cftransaction>
		<cfelseif pass EQ "collection_object" OR pass EQ "collection_object list">
			<cfif NOT (isdefined("collection_object_id") AND listlen(collection_object_id) GT 0) >
				<cfthrow message="No cataloged items listed to add to named group.">
			</cfif>
			<cftransaction>
				<cfquery name="countToAdd" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select count(*) as ct 
					from cataloged item 
					where 
						<cfif isdefined("collection_object_id") and listlen(collection_object_id) is 1>
							cataloged_item.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
						<cfelseif  isdefined("collection_object_id") and listlen(collection_object_id) gt 1>
							cataloged_item.collection_object_id IN (<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#" list="yes">)
						</cfif>
				</cfquery>
				<cfif countToAdd.ct NEQ recordcount>
					<cfthrow message="Add failed.  Discrepancy between the expected and actual number of records to add.">
				</cfif>
				<cfset numberInResult = countToAdd.ct>
				<cfquery name="unColl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT underscore_collection.underscore_collection_id as id, collection_name
					FROM underscore_collection
					WHERE underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
				</cfquery>
				<cfset idToAdd = unColl.id>
				<cfset collectionName = unColl.collection_name>
				<cfif unColl.recordcount NEQ 1>
					<cfthrow message="No such named group found, unable to add cataloged items">
				</cfif>
				<cfquery name="addItemsToColl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="add_result">
					INSERT /*+ ignore_row_on_dupkey_index ( underscore_relation (collection_object_id, underscore_collection_id ) ) */
						into underscore_relation (underscore_collection_id, collection_object_id)
					select #idToAdd#, collection_object_id 
						from cataloged item 
						where 
							<cfif isdefined("collection_object_id") and listlen(collection_object_id) is 1>
								cataloged_item.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
							<cfelseif isdefined("collection_object_id") and listlen(collection_object_id) gt 1>
								cataloged_item.collection_object_id IN (<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#" list="yes">)
							</cfif>
				</cfquery>
				<cfset numberChanged = add_result.recordcount>
			</cftransaction>
		<cfelse>
			<cfthrow message="Error: Unknown means by which to add to named group.  File a bug report.">
		</cfif>
		<cfoutput>
			<div class="container-fluid">
				<div class="row mx-0">
					<div class="col-12 px-4 mt-3">
						<h2 class="h2">Added #numberChanged# cataloged items [in #encodeForHtml(result_id)#] to Named Group: #collectionName#</h2>
						<ul class="col-12 list-group list-group-horizontal">
							<cfif numberInResult NEQ numberChanged>
								<p>Some of these specimens were already in this named group, manage from this result can not easily reverse the addition of the others.</p>
							</cfif>
							<li class="list-group-item d-flex justify-content-between align-items-center">
								<a href="/grouping/NamedCollection.cfm?action=edit&underscore_collection_id=#underscore_collection_id#">View Named Group #collectionName#</a>
							</li>
						</ul>
					</div>
				</div>
			</div>
		</cfoutput>
	</cfcase>
	<cfcase value="removeItems">
		<cfif NOT isdefined("underscore_collection_id")>
			<cfthrow message="No named group selected, unable to remove cataloged items">
		<cfelseif len(underscore_collection_id) EQ 0 >
			<cfthrow message="No named group selected (blank id value provided), unable to remove cataloged items">
		</cfif>
		<cfif NOT isdefined("recordcount") OR recordcount EQ 0>
			<cfthrow message="No cataloged items to remove from named group.">
		</cfif>
		<cfif NOT isdefined("pass") OR len(pass) EQ 0>
			<cfthrow message="Error: No means included by which to remove from named group.  File a bug report.">
		</cfif>
		<cfset numberInResult = 0>
		<cfset numberChanged = 0>
		<cfset collectionName = "">
		<cfif pass EQ "result_id">
			<cftransaction>
				<cfquery name="countToRemove" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT count(*) as ct 
					FROM user_search_table
					WHERE result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
				</cfquery>
				<cfif countToRemove.ct NEQ recordcount>
					<cfthrow message="Remove failed.  Discrepancy between the expected and actual number of records to remove, result set modified since search was run.">
				</cfif>
				<cfset numberInResult = countToRemove.ct>
				<cfquery name="unColl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT underscore_collection.underscore_collection_id as id, collection_name
					FROM underscore_collection
					WHERE underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
				</cfquery>
				<cfset idToRemove = unColl.id>
				<cfset collectionName = unColl.collection_name>
				<cfif unColl.recordcount NEQ 1>
					<cfthrow message="No such named group found, unable to remove cataloged items">
				</cfif>
				<cfquery name="removeItemsFromColl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="remove_result">
					DELETE FROM underscore_relation 
					WHERE 
						underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#idToRemove#">
						AND 
						collection_object_id IN (
							SELECT collection_object_id 
							FROM user_search_table
							WHERE result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
						)
				</cfquery>
				<cfset numberChanged = remove_result.recordcount>
			</cftransaction>
		<cfelseif pass EQ "collection_object" OR pass EQ "collection_object list">
			<cfif NOT (isdefined("collection_object_id") AND listlen(collection_object_id) GT 0) >
				<cfthrow message="No cataloged items listed to remove from named group.">
			</cfif>
			<cftransaction>
				<cfquery name="countToRemove" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select count(*) as ct 
					from cataloged item 
					where 
						<cfif isdefined("collection_object_id") and listlen(collection_object_id) is 1>
							cataloged_item.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
						<cfelseif  isdefined("collection_object_id") and listlen(collection_object_id) gt 1>
							cataloged_item.collection_object_id IN (<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#" list="yes">)
						</cfif>
				</cfquery>
				<cfif countToRemove.ct NEQ recordcount>
					<cfthrow message="Remove failed.  Discrepancy between the expected and actual number of records to remove.">
				</cfif>
				<cfset numberInResult = countToRemove.ct>
				<cfquery name="unColl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT underscore_collection.underscore_collection_id as id, collection_name
					FROM underscore_collection
					WHERE underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
				</cfquery>
				<cfset idToRemove = unColl.id>
				<cfset collectionName = unColl.collection_name>
				<cfif unColl.recordcount NEQ 1>
					<cfthrow message="No such named group found, unable to remove cataloged items">
				</cfif>
				<cfquery name="removeItemsFromColl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="remove_result">
					DELETE FROM underscore_relation 
					WHERE 
						underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#idToRemove#">
						AND 
						<cfif isdefined("collection_object_id") and listlen(collection_object_id) is 1>
							collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
						<cfelseif isdefined("collection_object_id") and listlen(collection_object_id) gt 1>
							collection_object_id IN (<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#" list="yes">)
						</cfif>
				</cfquery>
				<cfset numberChanged = remove_result.recordcount>
			</cftransaction>
		<cfelse>
			<cfthrow message="Error: Unknown means by which to remove from named group.  File a bug report.">
		</cfif>
		<cfoutput>
			<div class="container-fluid">
				<div class="row mx-0">
					<div class="col-12 px-4 mt-3">
						<h2 class="h2">Removed #numberChanged# cataloged items [in #encodeForHtml(result_id)#] from Named Group: #collectionName#</h2>
						<cfif numberChanged EQ 0>
							<p>None these specimens were in this named group.</p>
						<cfelseif numberInResult NEQ numberChanged>
							<p>Some of these specimens were not this named group, manage from this result can not easily reverse the removal of the others.</p>
						</cfif>
						<ul class="col-12 list-group list-group-horizontal">
							<li class="list-group-item d-flex justify-content-between align-items-center">
								<a href="/grouping/NamedCollection.cfm?action=edit&underscore_collection_id=#underscore_collection_id#">View Named Group #collectionName#</a>
							</li>
						</ul>
					</div>
				</div>
			</div>
		</cfoutput>
	</cfcase>
	<cfdefaultcase>
		<cfthrow message="Action for changeQueryNamedCollection.cfm not recognized.">
	</cfdefaultcase>
</cfswitch>
<cfinclude template = "/shared/_footer.cfm">
