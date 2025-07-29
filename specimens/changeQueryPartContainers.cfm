<!--- 
  specimens/changeQueryPartContainers.cfm manage placement of parts in a container in bulk.

Copyright 2008-2017 Contributors to Arctos
Copyright 2008-2025 President and Fellows of Harvard College

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
<cfset pageTitle="Bulk Move Parts">
<cfset pageHasTabs="true">
<cfinclude template="/shared/_header.cfm">
<cfinclude template="/shared/component/error_handler.cfc" runOnce="true">
<!--------------------------------------------------------------------->
<cfif isDefined("result_id") and len(result_id) GT 0>
	<cfset table_name="user_search_table">
</cfif>
<cfif not isDefined("action")>
	<cfset action="entryPoint">
</cfif>

<main class="container-fluid px-4 py-3" id="content">
<cftry>
	<cfswitch expression="#action#">
	<cfcase value="entryPoint">
		<cfoutput>
			<cfif isDefined("result_id") and len(result_id) GT 0>
				<cfquery name="getCount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT count(*) ct
					FROM 
						user_search_table
					WHERE
						user_search_table.result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
				</cfquery>
			<cfelse>
				<cfthrow message="Unable to identify parts to work on, required parameter result_id missing.">
			</cfif>
			<script>
				var bc = new BroadcastChannel('resultset_channel');
				bc.onmessage = function (message) { 
					console.log(message);
					if (message.data.result_id == "#result_id#") { 
						messageDialog("Warning: You have removed one or more records from this result set, you must reload this page to see the current list of records this page affects.", "Result Set Changed Warning");
						$(".makeChangeButton").prop("disabled",true);
						$(".makeChangeButton").addClass("disabled");
						$(".tabChangeButton").prop("disabled",true);
						$(".tabChangeButton").addClass("disabled");
					}  
				} 
			</script>
			<div class="row mx-0">
				<div class="col-12">
					<h1 class="h2 px-2">Bulk Part Container Change</h1>
					<p class="px-2 mb-1">Move parts on #getCount.ct# cataloged items from specimen search result [#result_id#]</p>
					<cfif getCount.ct gte 1000>
						<cfthrow message="You can only use this form on up to 1000 specimens at a time. Please <a href='/Specimens.cfm'>revise your search</a>."><!--- " --->
					</cfif>

					<cfset numParts=3>
					<cfquery name="colcde" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						SELECT distinct(collection_cde) 
						FROM 
							user_search_table
							JOIN cataloged_item ON user_search_table.collection_object_id = cataloged_item.collection_object_id
						WHERE
							user_search_table.result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
					</cfquery>
					<cfset colcdes = valuelist(colcde.collection_cde)>
					<cfif listlen(colcdes) is not 1>
						<cfthrow message="You can only use this form on one collection at a time. Please revise your search.">
					</cfif>

					<cfquery name="ctDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						SELECT coll_obj_disposition
						FROM ctcoll_obj_disp
					</cfquery>
					<cfquery name="ctNumericModifiers" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						SELECT modifier 
						FROM ctnumeric_modifiers
					</cfquery>
					<cfquery name="ctPreserveMethod" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						SELECT preserve_method 
						FROM ctspecimen_preserv_method 
						WHERE collection_cde = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#colcdes#">
					</cfquery>

					<div class="tabs card-header tab-card-header px-1 pb-0" id="partActionTabs">
						<div class="tab-headers tabList" role="tablist" aria-label="Tabs for bulk Add, Edit, or Delete Parts options">
							<button class="px-5 px-sm-3 px-md-5 col-12 col-md-auto mb-1 mb-md-0 active tabChangeButton" id="tab-1" tabid="1" role="tab" aria-controls="movePanel" aria-selected="true" tabindex="0">
								Move Parts
							</button>
						</div>
						<!--- End tab header div ---> 
						<!--- Tab content div --->
						<div class="tab-content"> 
							<!--- Move Parts tab panel ****************************** --->
							<div id="movePanel" role="tabpanel" aria-labelledby="tab-3" class="mx-0 " tabindex="0" hidden>
								<h2 class="h3 card-title">Move Selected Parts</h2>
								<p class="px-2">Identify existing parts to be moved from all the #getCount.ct# cataloged items.  You must provide at least one filter condition for parts to move.  You will be able to select the destination container, review, and confirm on the next screen.</p>
								<h3 class="h4 px-2">Select values to identify the existing parts to be moved.</h3>
								<form name="movePart" id="movePartForm" method="post" action="/specimens/changeQueryPartContainers.cfm">
									<input type="hidden" name="action" value="movePart">
									<input type="hidden" name="table_name" value="#table_name#">
									<cfif isDefined("result_id") and len(result_id) GT 0>
										<input type="hidden" name="result_id" value="#result_id#">
									</cfif>
									<div class="form-row mx-0">
										<div class="col-12 col-md-3 pt-1">
											<label for="exist_part_name" class="data-entry-label">Part Name</label>
											<select name="exist_part_name" id="exist_part_name" size="1" class="data-entry-select one_must_be_filled_in">
												<option selected="selected" value=""></option>
												<cfloop query="existParts">
													<option value="#Part_Name#">#Part_Name# (#existParts.partCount# parts)</option>
												</cfloop>
											</select>
										</div>
										<div class="col-12 col-md-3 pt-1">
											<label for="exist_preserve_method" class="data-entry-label">Preserve Method</label>
											<select name="exist_preserve_method" id="exist_preserve_method" size="1" class="data-entry-select one_must_be_filled_in">
												<option selected="selected" value=""></option>
												<cfloop query="existPreserve">
													<option value="#preserve_method#">#preserve_method# (#existPreserve.partCount# parts)</option>
												</cfloop>
											</select>
										</div>
										<div class="col-12 col-md-3 pt-1">
											<label for="existing_lot_count" class="data-entry-label">Lot Count</label>
											<select name="existing_lot_count" id="existing_lot_count" size="1" class="data-entry-select one_must_be_filled_in">
												<option selected="selected" value=""></option>
												<cfloop query="existLotCount">
												<option value="#lot_count#">#lot_count#</option>
												</cfloop>
											</select>
										</div>
										<div class="col-12 col-md-3 pt-1">
											<label for="existing_coll_obj_disposition" class="data-entry-label">Disposition</label>
											<select name="existing_coll_obj_disposition" id="existing_coll_obj_disposition" size="1" class="data-entry-select one_must_be_filled_in">
												<option selected="selected" value=""></option>
												<cfloop query="existDisp">
													<option value="#coll_obj_disposition#">#coll_obj_disposition#</option>
												</cfloop>
											</select>
										</div>
									</div>
									<div class="form-row mx-0">
										<div class="col-12 pt-2">
											<script>
												$(document).ready(function () { 
													$("##movePartForm").on("submit",function(e) { 
														var valuesArray = $('##deletePartForm .one_must_be_filled_in').get().map(e => e.value);
														if (valuesArray.every(element => element == "")){ 
															e.preventDefault();
															messageDialog("Error: You must specify at least one value to specify which parts to delete.","No Delete Criteria Provided.");
														}
													});
												});
											</script>
											<input type="submit" value="Delete Parts" class="btn btn-xs btn-danger makeChangeButton">
										</div>
									</div>
								</form>
							</div>
						</div>
					</div>

					<h2 class="h3">Specimens to be Updated</h2>
					<cfquery name="getCollObjList" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						SELECT
							cataloged_item.collection_object_id,
							collection.collection,
							collection.collection_cde,
							collection.institution_acronym,
							cataloged_item.cat_num,
							identification.scientific_name,
							specimen_part.part_name,
							specimen_part.preserve_method,
							coll_object.condition,
							coll_object.lot_count_modifier,
							coll_object.lot_count,
							coll_object.coll_obj_disposition,
							coll_object_remark.coll_object_remarks
						FROM
							cataloged_item,
							collection,
							coll_object,
							specimen_part,
							identification,
							coll_object_remark,
							user_search_table
						WHERE
							cataloged_item.collection_id=collection.collection_id and
							cataloged_item.collection_object_id=user_search_table.collection_object_id and
							user_search_table.result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#"> and
							cataloged_item.collection_object_id=specimen_part.derived_from_cat_item and
							specimen_part.collection_object_id=coll_object.collection_object_id and
							specimen_part.collection_object_id=coll_object_remark.collection_object_id (+) and
							cataloged_item.collection_object_id=identification.collection_object_id and
							accepted_id_fg=1
						ORDER BY
							collection.collection,cataloged_item.cat_num
					</cfquery>
					<cfquery name="getCatItems" dbtype="query">
						SELECT 
							collection_object_id,collection,cat_num,scientific_name,institution_acronym,collection_cde
						FROM getCollObjList
						GROUP BY
							 collection_object_id,collection,cat_num,scientific_name,institution_acronym,collection_cde
					</cfquery>
					<table class="table table-responsive table-striped d-xl-table">
						<thead class="thead-light"
							<tr>
								<th>Specimen</th>
								<th>ID</th>
								<th>Parts</th>
							</tr>
						</thead>
						<tbody>
						<cfloop query="getCatItems">
							<tr>
								<td><a href="/guid/#institution_acronym#:#collection_cde#:#cat_num#">#collection# #cat_num#</a></td>
								<td>#scientific_name#</td>
								<cfquery name="getParts" dbtype="query">
									SELECT
										part_name,
										preserve_method,
										condition,
										lot_count_modifier,
										lot_count,
										coll_obj_disposition,
										coll_object_remarks
									FROM
										getCollObjList
									WHERE
										collection_object_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#collection_object_id#">
									ORDER BY
										part_name, preserve_method, lot_count
								</cfquery>
								<td>
									<table class="table table">
										<thead class="thead-dark">
											<th colspan="1">Part</th>
											<th colspan="1">Preserve Method</th>
											<th colspan="1">Condition</th>
											<th colspan="1">Count</th>
											<th colspan="1">Disposition</th>
											<th colspan="5">Remark</th>
										</thead>
										<tbody>
											<cfloop query="getParts">
												<tr>
													<td colspan="1">#part_name#</td>
													<td colspan="1">#preserve_method#</td>
													<td colspan="1">#condition#</td>
													<td colspan="1">#lot_count# #lot_count_modifier#</td>
													<td colspan="1">#coll_obj_disposition#</td>
													<td colspan="5">#coll_object_remarks#</td>
												</tr>
										
											</cfloop>
										</tbody>
									</table>
								</td>
							</tr>
						</cfloop>
						</tbody>
					</table>
				</div>
			</div>
		</cfoutput>
	</cfcase>
	<!---------------------------------------------------------------------------->
	<cfcase value="movePart2">
		<cfoutput>
			<!--- move parts into specified container --->
			<cfquery name="move" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="move_result">
				UPDATE container
				SET 
					parent_container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#target_container_id#">
				WHERE
					container_id in ( 
						SELECT container_id 
						FROM COLL_OBJ_CONT_HIST
						WHERE 
							collection_object_id IN (<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#partIDs#" list="yes"> )
							and current_container_fg = 1
					)
			</cfquery>
			<div class="row mx-0">
				<div class="col-12 mt-2">
					<h2>Successfully moved #move_result.recordcount# parts into </h2>
					<cfset targeturl="/specimens/changeQueryPartContainers.cfm?result_id=#result_id#">
					<h4 class="mt-2"><a href="#targeturl#">Return to move parts in bulk</a></h4>
					<cfset targeturl="">
					<h4 class="mt-2"><a href="#targeturl#">View Container</a></h4>
				</div>
			</div>
		</cfoutput>
	</cfcase>
	<!---------------------------------------------------------------------------->
	<cfcase value="movePart">
		<cfoutput>
			<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				select
					specimen_part.collection_object_id partID,
					collection.collection,
					cataloged_item.cat_num,
					identification.scientific_name,
					specimen_part.part_name,
					specimen_part.preserve_method,
					coll_object.condition,
					coll_object.lot_count_modifier,
					coll_object.lot_count,
					coll_object.coll_obj_disposition,
					coll_object_remark.coll_object_remarks
				from
					cataloged_item,
					collection,
					coll_object,
					specimen_part,
					identification,
					coll_object_remark,
					user_search_table
				where
					cataloged_item.collection_id=collection.collection_id and
					cataloged_item.collection_object_id=user_search_table.collection_object_id and
					user_search_table.result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#"> and
					cataloged_item.collection_object_id=specimen_part.derived_from_cat_item and
					specimen_part.collection_object_id=coll_object.collection_object_id and
					specimen_part.collection_object_id=coll_object_remark.collection_object_id (+) and
					cataloged_item.collection_object_id=identification.collection_object_id and
					accepted_id_fg=1 
					<cfif len(exist_part_name) gt 0>
						and part_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#exist_part_name#">
					</cfif>
					<cfif len(exist_preserve_method) gt 0>
						and preserve_method = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#exist_preserve_method#">
					</cfif>
					<cfif len(existing_lot_count) gt 0>
						and lot_count = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#existing_lot_count#">
					</cfif>
					<cfif len(existing_coll_obj_disposition) gt 0>
						and coll_obj_disposition = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#existing_coll_obj_disposition#">
					</cfif>
					<cfif len(exist_part_name) EQ 0 AND len(exist_preserve_method) EQ 0 AND len(existing_lot_count) EQ 0 AND len(existing_coll_obj_disposition) EQ 0>
						and 0=1
					</cfif>
				order by
					collection.collection,cataloged_item.cat_num
			</cfquery>
				<div class="row mx-0">
					<div class="col-12">
						<h2 class="mt-2">Found #d.recordcount# parts to move</h2>
						<cfset targeturl="/specimens/changeQueryPartContainers.cfm?result_id=#result_id#">
						<cfif d.recordcount EQ 0>
							<h3 class="h4 mt-2">
								Return to the Bulk Part Move tool <a href="#targeturl#">to change your criteria of which parts to move</a>.
							</h3>
						<cfelse>
							<form name="deletePartForm" method="post" action="/specimens/changeQueryPartContainerss.cfm">
								<input type="hidden" name="action" value="movePart2">
								<input type="hidden" name="result_id" value="#result_id#">
								<input type="hidden" name="partID" value="#valuelist(d.partID)#">
								<input type="submit" value="Delete these Parts" class="btn btn-xs btn-danger">
							</form>
							<!--- TODO: Select container to move into --->

							<!--- container autocomplete, limited by type and parent room --->


							<h3 class="h4 mt-2">
								Or return to the Bulk Part Management tool <a href="#targeturl#">to change your criteria of which parts to moves</a>.
							</h3>
							<table class="table table-responsive table-striped d-xl-table">
							<thead class="thead-light">
							<tr>
								<th>Specimen</th>
								<th>ID</th>
								<th>PartToBeDeleted</th>
								<th>PreserveMethod</th>
								<th>Condition</th>
								<th>CntMod</th>
								<th>Cnt</th>
								<th>Dispn</th>
								<th>Remark</th>
							</tr>
							</thead>
							<tbody>
							<cfloop query="d">
								<tr>
									<td>#collection# #cat_num#</td>
									<td>#scientific_name#</td>
									<td>#part_name#</td>
									<td>#preserve_method#</td>
									<td>#condition#</td>
									<td>#lot_count_modifier#</td>
									<td>#lot_count#</td>
									<td>#coll_obj_disposition#</td>
									<td>#coll_object_remarks#</td>
								</tr>
							</cfloop>
							</tbody>
						</table>
					</div>
				</div>						
			</cfif>
		</cfoutput>
	</cfcase>
	<!---------------------------------------------------------------------------->
	</cfswitch>
<cfcatch>
	<h2 class="h3 px-2 mt-1">Error</h2>
	<cfoutput>
		<cfset error_message = cfcatchToErrorMessage(cfcatch)>
		<p class="px-2">#error_message#</p>
	</cfoutput>
</cfcatch>
</cftry>
</main>

<cfinclude template="/shared/_footer.cfm">
