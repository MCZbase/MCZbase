<!--- 
  specimens/changeQueryPart.cfm manage parts in bulk.

Copyright 2008-2017 Contributors to Arctos
Copyright 2008-2023 President and Fellows of Harvard College

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
<cfset pageTitle="Bulk Modify Parts">
<cfset pageHasTabs="true">
<cfinclude template="/shared/_header.cfm">
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
				<cfquery name="getCount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT count(*) ct
					FROM 
						user_search_table
					WHERE
						user_search_table.result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
				</cfquery>
			<cfelse>
				<!--- TODO: Remove support for table_name --->
				<cfquery name="getCount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select count(*) ct
					from #table_name#
				</cfquery>
			</cfif>
			<div class="row mx-0">
				<div class="col-12">
					<h1 class="h2 px-2">Bulk Part Management</h1>
					<cfif isDefined("result_id") and len(result_id) GT 0>
						<p class="px-2 mb-1">Add, Modify, or Delete Parts on #getCount.ct# cataloged items from specimen search result [#result_id#]</p>
					<cfelse>
						<p class="px-2 mb-1">Add, Modify, or Delete parts on list of #getCount.ct# cataloged items.</p>
					</cfif>
					<cfif getCount.ct gte 1000>
						<cfthrow message="You can only use this form on up to 1000 specimens at a time. Please <a href='/Specimens.cfm'>revise your search</a>."><!--- " --->
					</cfif>


					<cfset numParts=3>
					<cfif not isdefined("table_name")>
						<!--- TODO: Remove support for table_name --->
						<cfthrow message="Unable to identify parts to work on [required variable table_name or result_id not defined].">
					</cfif>
					<cfif isDefined("result_id") and len(result_id) GT 0>
						<cfquery name="colcde" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							SELECT distinct(collection_cde) 
							FROM 
								user_search_table
								JOIN cataloged_item ON user_search_table.collection_object_id = cataloged_item.collection_object_id
							WHERE
								user_search_table.result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
						</cfquery>
					<cfelse>
						<!--- TODO: Remove support for table_name --->
						<cfquery name="colcde" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							select distinct(collection_cde) 
							from #table_name#
						</cfquery>
					</cfif>
					<cfset colcdes = valuelist(colcde.collection_cde)>
					<cfif listlen(colcdes) is not 1>
						<cfthrow message="You can only use this form on one collection at a time. Please revise your search.">
					</cfif>

					<cfquery name="ctDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						SELECT coll_obj_disposition
						FROM ctcoll_obj_disp
					</cfquery>
					<cfquery name="ctNumericModifiers" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						SELECT modifier 
						FROM ctnumeric_modifiers
					</cfquery>
					<cfquery name="ctPreserveMethod" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						SELECT preserve_method 
						FROM ctspecimen_preserv_method 
						WHERE collection_cde = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#colcdes#">
					</cfquery>

					<div class="tabs card-header tab-card-header px-1 pb-0" id="partActionTabs">
						<div class="tab-headers tabList" role="tablist" aria-label="Tabs for bulk Add, Edit, or Delete Parts options">
							<button class="px-5 px-sm-3 px-md-5 col-12 col-md-auto mb-1 mb-md-0 active" id="tab-1" tabid="1" role="tab" aria-controls="addPanel" aria-selected="true" tabindex="0">
								Add Parts
							</button>
							<button class="px-5 px-sm-3 px-md-5 col-12 col-md-auto mb-1 mb-md-0" id="tab-2" tabid="2" role="tab" aria-controls="modifyPanel" aria-selected="false" tabindex="-1">
								Modify Existing Parts
							</button>
							<button class="px-5 px-sm-3 px-md-5 col-12 col-md-auto mb-1 mb-md-0" id="tab-3" tabid="3" role="tab" aria-controls="deletePanel" aria-selected="false" tabindex="-1">
								Delete Parts
							</button>
						</div>
						<!--- End tab header div ---> 
						<!--- Tab content div --->
						<div class="tab-content"> 
							<!--- Add Parts tab panel **************************************** --->
							<div id="addPanel" role="tabpanel" aria-labelledby="tab-1" tabindex="0" class="mx-0 active" >
								<h2 class="h3 card-title my-0" >Add New Parts to Each Cataloged Item</h2>
								<p class="px-2">
									Add one to three new parts to each cataloged item.  
									<cfif getCount.ct EQ 1>
										This set of parts will be added to the cataloged item.
									<cfelse>
										The same set of parts will be added to each of the #getCount.ct# cataloged items.
									</cfif>
								</p>
								<form name="newPart" method="post" action="/specimens/changeQueryParts.cfm">
									<input type="hidden" name="action" value="newPart">
									<input type="hidden" name="table_name" value="#table_name#">
									<input type="hidden" name="numParts" value="#numParts#">
									<cfif isDefined("result_id") and len(result_id) GT 0>
										<input type="hidden" name="result_id" value="#result_id#">
									</cfif>
									<div class="form-row mx-0">
										<cfloop from="1" to="#numParts#" index="i">
											<div class="col-12 col-md-4 border-left border-bottom border-top px-0">
												<cfif i EQ 1>
													<cfset requireClass = "reqdClr">
													<cfset require = "required">
												<cfelse>
													<cfset requireClass = " requirable#i#">
													<cfset require = "">
												</cfif>
												<h3 class="h4 pt-2 pb-1 px-3" style="color: ##495057;background-color: ##e9ecef!important;border:##dee2e6;border:##dee2e6;">
													<cfif i EQ 1>
														First
													<cfelseif i EQ 2>
														Second
													<cfelseif i EQ 3>
														Third
													</cfif>
													Part To Add
												</h3>
												<div class="form-row mx-0 p-2">
													<div class="col-12 pt-1">
														<label for="part_name_#i#" class="data-entry-label">
															Add Part (#i#)
															<a href="javascript:void(0)" tabindex="-1" aria-hidden="true" class="btn-link" onclick=" $('##part_name_#i#').autocomplete('search','%%%'); return false;" > (&##8595;) <span class="sr-only">open pick list</span></a>
														</label>
														<input type="text" name="part_name_#i#" id="part_name_#i#" class="data-entry-input #requireClass#" #require#>
														<script>
															<cfif i GT 1>
																function togglePart#i#() { 
																	if ($("##part_name_#i#").val()!="") { 
																		$(".forpart#i#").show();
																		$(".requirable#i#").addClass("reqdClr");
																		$(".requirable#i#").prop('required',true);
																	} else { 
																		$(".forpart#i#").hide();
																		$(".requirable#i#").removeClass("reqdClr");
																		$(".requirable#i#").prop('required',false);
																	} 
																}
															</cfif>
															$(document).ready(function() {
																makeCTAutocompleteColl("part_name_#i#","SPECIMEN_PART_NAME","#colcdes#");
																<cfif i GT 1>
																	// enable/disable additional parts entry 
																	// (input when typing, blur when picking from dropped list)
																	$("##part_name_#i#").on("input",function() { 
																		togglePart#i#();
																	});
																	$("##part_name_#i#").on("blur",function() { 
																		togglePart#i#();
																	});
																	$(".forpart#i#").hide();
																</cfif>
															});
														</script>
													</div>
													<div class="col-12 forpart#i# pt-1">
														<label for="preserve_method_#i#" class="data-entry-label">Preserve Method (#i#)</label>
														<select name="preserve_method_#i#" id="preserve_method_#i#" size="1" class="data-entry-select #requireClass#" #require#>
															<option></option>
															<cfloop query="ctPreserveMethod">
																<option value="#ctPreserveMethod.preserve_method#">#ctPreserveMethod.preserve_method#</option>
															</cfloop>
														</select>
													</div>
													<div class="col-12 forpart#i# pt-1">
														<label for="lot_count_modifier_#i#" class="data-entry-label">Count Modifier (#i#)</label>
														<select name="lot_count_modifier_#i#" id="lot_count_modifier_#i#" class="data-entry-select">
															<option value=""></option>
															<cfloop query="ctNumericModifiers">
																<option value="#ctNumericModifiers.modifier#">#ctNumericModifiers.modifier#</option>
															</cfloop>
														</select>
													</div>
													<div class="col-12 forpart#i# pt-1">
													<label for="lot_count_#i#" class="data-entry-label">Part Count (#i#)</label>
													<input type="text" name="lot_count_#i#" id="lot_count_#i#" class="data-entry-input #requireClass#" #require# pattern="^[0-9]+$">
													</div>
													<div class="col-12 forpart#i# pt-1">
													<label for="coll_obj_disposition_#i#" class="data-entry-label">Disposition (#i#)</label>
													<select name="coll_obj_disposition_#i#" id="coll_obj_disposition_#i#" size="1"  class="data-entry-select #requireClass#" #require#>
															<option value=""></option>
															<cfloop query="ctDisp">
																<option value="#ctDisp.coll_obj_disposition#">#ctDisp.coll_obj_disposition#</option>
															</cfloop>
														</select>
													</div>
													<div class="col-12 forpart#i# pt-1">
														<label for="condition_#i#" class="data-entry-label">Condition (#i#)</label>
													<input type="text" name="condition_#i#" id="condition_#i#" class="data-entry-input #requireClass#" #require#>
													</div>
													<div class="col-12 forpart#i# py-1">
													<label for="coll_object_remarks_#i#" class="data-entry-label">Remark (#i#)</label>
													<input type="text" name="coll_object_remarks_#i#" id="coll_object_remarks_#i#" class="data-entry-input">
													</div>
												</div>
											</div>
										</cfloop>
									</div>
									<input type="submit" value="Add Parts" class="btn ml-2 mt-2 btn-xs btn-primary">
								</form>
							</div>
							<!--- queries used for picklists on modify and delete forms --->
							<cfquery name="existParts" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
								SELECT
									count(specimen_part.collection_object_id) partcount,
									specimen_part.part_name
								FROM
									specimen_part
									<cfif isDefined("result_id") and len(result_id) GT 0>
										JOIN user_search_table on specimen_part.derived_from_cat_item = user_search_table.collection_object_id
								WHERE
										user_search_table.result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
									<cfelse>
										JOIN #table_name# on specimen_part.derived_from_cat_item=#table_name#.collection_object_id
								</cfif>
								GROUP BY specimen_part.part_name
								ORDER BY specimen_part.part_name
							</cfquery>
							<cfquery name="existPreserve" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
								SELECT
									count(specimen_part.collection_object_id) partcount,
									specimen_part.preserve_method
								FROM
									specimen_part
									<cfif isDefined("result_id") and len(result_id) GT 0>
										JOIN user_search_table on specimen_part.derived_from_cat_item = user_search_table.collection_object_id
								WHERE
										user_search_table.result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
									<cfelse>
										JOIN #table_name# on specimen_part.derived_from_cat_item=#table_name#.collection_object_id
									</cfif>
								GROUP BY specimen_part.preserve_method
								ORDER BY specimen_part.preserve_method
							</cfquery>
							<!--- TODO: Split into two queries, this group on then group on again paired queries may not produce the expected results. --->
							<cfquery name="existCO" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
								SELECT
									coll_object.lot_count,
									coll_object.coll_obj_disposition
								FROM
									specimen_part
									JOIN coll_object on specimen_part.collection_object_id=coll_object.collection_object_id
									<cfif isDefined("result_id") and len(result_id) GT 0>
										JOIN user_search_table on specimen_part.derived_from_cat_item = user_search_table.collection_object_id
								WHERE
										user_search_table.result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
									<cfelse>
										JOIN #table_name# on specimen_part.derived_from_cat_item=#table_name#.collection_object_id
									</cfif>
								GROUP BY 
									coll_object.lot_count,
									coll_object.coll_obj_disposition
							</cfquery>
							<cfquery name="existLotCount" dbtype="query">
								SELECT lot_count 
								FROM existCO
								GROUP BY lot_count 
								ORDER BY lot_count
							</cfquery>
							<cfquery name="existDisp" dbtype="query">
								SELECT coll_obj_disposition 
								FROM existCO 
								GROUP BY coll_obj_disposition 
								ORDER BY coll_obj_disposition
							</cfquery>
							<!--- Modify Parts tab panel ****************************** --->
							<div id="modifyPanel" role="tabpanel" aria-labelledby="tab-2" class="mx-0 " tabindex="0" hidden>
								<h2 class="h3 card-title my-0">Modify Selected Existing Parts</h2>
								<p class="px-2">You will be able to review changes on the next screen.</p>

								<form name="modPart" method="post" action="/specimens/changeQueryParts.cfm">
									<input type="hidden" name="action" value="modPart">
									<input type="hidden" name="table_name" value="#table_name#">
									<cfif isDefined("result_id") and len(result_id) GT 0>
										<input type="hidden" name="result_id" value="#result_id#">
									</cfif>
									<table class="table table-responsive d-xl-table">
										<thead class="thead-light">
											<tr>
												<th class="h4">
													Filter specimens for parts matching...
												</th>
												<th class="h4">
													Update matching parts to...
												</th>
											</tr>
										</thead>
										<tbody>
											<tr>
												<td valign="top">
													<div class="form-row">
														<div class="col-12 pt-1">
															<label for="exist_part_name" class="data-entry-label">Part Name Matches</label>
														<select name="exist_part_name" id="exist_part_name" size="1" class="reqdClr data-entry-select" required>
																<option selected="selected" value=""></option>
																<cfloop query="existParts">
																	<option value="#Part_Name#">#Part_Name# (#existParts.partCount# parts)</option>
																</cfloop>
															</select>
														</div>
														<div class="col-12 pt-1">
															<label for="exist_preserve_method" class="data-entry-label">Preserve Method Matches</label>
														<select name="exist_preserve_method" id="exist_preserve_method" size="1" class="data-entry-select">
																<option selected="selected" value=""></option>
																<cfloop query="existPreserve">
																	<option value="#Preserve_method#">#Preserve_method# (#existPreserve.partCount# parts)</option>
																</cfloop>
															</select>
														</div>
														<div class="col-12 pt-1">
															<label for="existing_lot_count" class="data-entry-label">Lot Count Matches</label>
															<select name="existing_lot_count" id="existing_lot_count" size="1" class="data-entry-select">
																<option selected="selected" value=""></option>
																<cfloop query="existLotCount">
																	<option value="#lot_count#">#lot_count#</option>
																</cfloop>
															</select>
														</div>
														<div class="col-12 pt-1">
															<label for="existing_coll_obj_disposition" class="data-entry-label">Disposition Matches</label>
															<select name="existing_coll_obj_disposition" id="existing_coll_obj_disposition" size="1" class="data-entry-select">
																<option selected="selected" value=""></option>
																<cfloop query="existDisp">
																	<option value="#coll_obj_disposition#">#coll_obj_disposition#</option>
																</cfloop>
															</select>
														</div>
													</div>
												</td>
												<td>
													<div class="form-row">
														<div class="col-12 pt-1">
															<label for="new_part_name" class="data-entry-label">
																New Part Name
																<a href="javascript:void(0)" tabindex="-1" aria-hidden="true" class="btn-link" onclick=" $('##new_part_name').autocomplete('search','%%%'); return false;" > (&##8595;) <span class="sr-only">open pick list</span></a>
															</label>
															<input type="text" name="new_part_name" id="new_part_name" class="data-entry-input reqdClr" required>
															<script>
																$(document).ready(function() {
																	makeCTAutocompleteColl("new_part_name","SPECIMEN_PART_NAME","#colcdes#");
																});
															</script>
														</div>
														<div class="col-12 pt-1">
															<label for="new_preserve_method" class="data-entry-label">New Preserve Method</label>
															<select name="new_preserve_method" id="new_preserve_method" size="1"  class="data-entry-select">
																<option value=""></option>
																<cfloop query="ctPreserveMethod">
																	<option value="#ctPreserveMethod.preserve_method#">#ctPreserveMethod.preserve_method#</option>
																</cfloop>
															</select>
														</div>
														<div class="col-12 pt-1">
															<label for="new_lot_count_modifier" class="data-entry-label">New Lot Count Modifier</label>
															<input type="text" name="new_lot_count_modifier" id="new_lot_count_modifier" class="data-entry-input">
														</div>
														<div class="col-12 pt-1">
															<label for="new_lot_count" class="data-entry-label">New Lot Count</label>
															<input type="text" name="new_lot_count" id="new_lot_count" class="data-entry-input">
														</div>
														<div class="col-12 pt-1">
															<label for="new_coll_obj_disposition" class="data-entry-label">Disposition</label>
															<select name="new_coll_obj_disposition" id="new_coll_obj_disposition" size="1"  class="data-entry-select">
																<option value=""></option>
																<cfloop query="ctDisp">
																	<option value="#ctDisp.coll_obj_disposition#">#ctDisp.coll_obj_disposition#</option>
																</cfloop>
															</select>
														</div>
														<div class="col-12 pt-1">
															<label for="new_condition" class="data-entry-label">New Condition</label>
															<input type="text" name="new_condition" id="new_condition" class="data-entry-input">
														</div>
														<div class="col-12 py-1">
															<label for="new_remark" class="data-entry-label">Add Remark</label>
															<input type="text" name="new_remark" id="new_remark" class="data-entry-input">
														</div>
													</div>
												</td>
											</tr>
										</tbody>
									</table>
									<input type="submit" value="Update Parts" class="btn ml-2 mt-2 btn-xs btn-secondary">
								</form>
							</div>
							<!--- Delete Parts tab panel ****************************** --->
							<div id="deletePanel" role="tabpanel" aria-labelledby="tab-3" class="mx-0 " tabindex="0" hidden>
								<h2 class="h3 card-title">Delete Selected Parts</h2>
								<p class="px-2">Identify existing parts to be deleted from all the #getCount.ct# cataloged items.  You must provide at least one filter condition for deletion.  You will be able to review and confirm on the next screen.</p>
								<h3 class="h4 px-2">Select values to identify the existing parts to be deleted.</h3>
								<form name="delPart" id="deletePartForm" method="post" action="/specimens/changeQueryParts.cfm">
									<input type="hidden" name="action" value="delPart">
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
													$("##deletePartForm").on("submit",function(e) { 
														var valuesArray = $('##deletePartForm .one_must_be_filled_in').get().map(e => e.value);
														if (valuesArray.every(element => element == "")){ 
															e.preventDefault();
															messageDialog("Error: You must specify at least one value to specify which parts to delete.","No Delete Criteria Provided.");
														}
													});
												});
											</script>
											<input type="submit" value="Delete Parts" class="btn btn-xs btn-danger">
										</div>
									</div>
								</form>
							</div>
						</div>
					</div>

					<h2 class="h3">Specimens to be Updated</h2>
					<cfquery name="getCollObjList" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
							<cfif isDefined("result_id") and len(result_id) GT 0>
								user_search_table
							<cfelse>
								#table_name#
							</cfif>
						WHERE
							cataloged_item.collection_id=collection.collection_id and
							<cfif isDefined("result_id") and len(result_id) GT 0>
								cataloged_item.collection_object_id=user_search_table.collection_object_id and
								user_search_table.result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#"> and
							<cfelse>
								cataloged_item.collection_object_id=#table_name#.collection_object_id and
							</cfif>
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
									select
										part_name,
										preserve_method,
										condition,
										lot_count_modifier,
										lot_count,
										coll_obj_disposition,
										coll_object_remarks
									from
										getCollObjList
									where
										collection_object_id=#collection_object_id#
								</cfquery>
								<td>
									<table border width="100%">
										<thead class="thead-dark">
											<th style="width:10%">Part</th>
											<th style="width:13%">Preserve Method</th>
											<th style="width:6%">Condition</th>
											<th style="width:6%;">Ct Mod</th>
											<th style="width:6%">Count</th>
											<th style="width:10%">Disposition</th>
											<th style="30%;">Remark</th>
										</thead>
										<tbody>
											<cfloop query="getParts">
												<tr>
													<td style="width:10%">#part_name#</td>
													<td style="width:13%">#preserve_method#</td>
													<td style="width:6%">#condition#</td>
													<td style="width:6%">#lot_count_modifier#</td>
													<td style="width:6%">#lot_count#</td>
													<td style="width:10%">#coll_obj_disposition#</td>
													<td style="30%;">#coll_object_remarks#</td>
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
	<cfcase value="delPart2">
		<cfoutput>
			<!--- Delete fires TR_SPECIMENPART_AD for cleanup of related tables --->
			<cfquery name="delete" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="delete_result">
				DELETE FROM
					specimen_part 
				WHERE
					collection_object_id in (<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#partID#" list="yes">)
			</cfquery>
			<div class="row mx-0">
				<div class="col-12 mt-2">
					<h2>Successfully deleted #delete_result.recordcount# parts</h2>
					<cfif isDefined("result_id") and len(result_id) GT 0>
						<cfset targeturl="/specimens/changeQueryParts.cfm?result_id=#result_id#">
					<cfelse>
						<cfset targeturl="/specimens/changeQueryParts.cfm?table_name=#table_name#">
					</cfif>
					<h4 class="mt-2"><a href="#targeturl#">Return to bulk part editor (see remaining parts)</a></h4>
				</div>
			</div>
		</cfoutput>
	</cfcase>
	<!---------------------------------------------------------------------------->
	<cfcase value="delPart">
		<cfoutput>
			<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
					<cfif isDefined("result_id") and len(result_id) GT 0>
						user_search_table
					<cfelse>
						#table_name#
					</cfif>
				where
					cataloged_item.collection_id=collection.collection_id and
					<cfif isDefined("result_id") and len(result_id) GT 0>
						cataloged_item.collection_object_id=user_search_table.collection_object_id and
						user_search_table.result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#"> and
					<cfelse>
						cataloged_item.collection_object_id=#table_name#.collection_object_id and
					</cfif>
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
						<h2 class="mt-2">Found #d.recordcount# parts to delete</h2>
						<cfif isDefined("result_id") and len(result_id) GT 0>
							<cfset targeturl="/specimens/changeQueryParts.cfm?result_id=#result_id#">
						<cfelse>
							<cfset targeturl="/specimens/changeQueryParts.cfm?table_name=#table_name#">
						</cfif>
						<cfif d.recordcount EQ 0>
							<h3 class="h4 mt-2">
								Return to the Bulk Part Management tool <a href="#targeturl#">to change your criteria</a>.
							</h3>
						<cfelse>
							<form name="deletePartForm" method="post" action="/specimens/changeQueryParts.cfm">
								<input type="hidden" name="action" value="delPart2">
								<input type="hidden" name="table_name" value="#table_name#">
								<cfif isDefined("result_id") and len(result_id) GT 0>
									<input type="hidden" name="result_id" value="#result_id#">
								</cfif>
								<input type="hidden" name="partID" value="#valuelist(d.partID)#">
								<input type="submit" value="Delete these Parts" class="btn btn-xs btn-danger">
							</form>
						<h3 class="h4 mt-2">
							Or return to the Bulk Part Management tool <a href="#targeturl#">without making changes</a>.
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
	<cfcase value="modPart2">
		<cfoutput>
		<cfset partUpdateCount = 0>
		<cfset remarkCount = 0>
		<cftransaction>
			<cfloop list="#partID#" index="i">
				<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					update specimen_part set
						part_name='#new_part_name#'
						<cfif len(new_preserve_method) gt 0>
								,preserve_method='#new_preserve_method#'
						</cfif>
					where collection_object_id=#i#
				</cfquery>
				<cfif len(new_lot_count) gt 0 or len(new_coll_obj_disposition) gt 0 or len(new_condition) gt 0>
					<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						update coll_object set
							flags=flags
							<cfif len(new_lot_count) gt 0>
								,lot_count=#new_lot_count#
							</cfif>
							<cfif len(new_coll_obj_disposition) gt 0>
								,coll_obj_disposition='#new_coll_obj_disposition#'
							</cfif>
							<cfif len(new_condition) gt 0>
								,condition='#new_condition#'
							</cfif>
						where collection_object_id=#i#
					</cfquery>
				</cfif>
				<cfif len(new_remark) gt 0>
					<!--- TODO: Evaluate if this treatment of remarks is correct.  Should append? --->
					<cftry>
						<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							insert into coll_object_remark (collection_object_id,coll_object_remarks) values (#i#,'#new_remark#')
						</cfquery>
					<cfcatch>
						<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							update coll_object_remark set coll_object_remarks='#new_remark#' where collection_object_id=#i#
						</cfquery>
					</cfcatch>
					</cftry>
				</cfif>
				<cfset partUpdateCount = partUpdateCount + 1>
			</cfloop>
			</cftransaction>
			<div class="row mx-0">
				<div class="col-12">
					<h2 class="h2 pt-2">Succesfully updated #partUpdateCount# parts</h2>
					<h3 class="h4 pt-2">
						<cfif isDefined("result_id") and len(result_id) GT 0>
							<cfset targeturl="/specimens/changeQueryParts.cfm?result_id=#result_id#">
						<cfelse>
							<cfset targeturl="/specimens/changeQueryParts.cfm?table_name=#table_name#">
						</cfif>
						<a href="#targeturl#">Return to bulk part editor</a>
					</h3>
				</div>
			</div>

		</cfoutput>
	</cfcase>
	<!---------------------------------------------------------------------------->
	<cfcase value="modPart">
		<cfif len(exist_part_name) is 0 or len(new_part_name) is 0>
			<cfthrow message="Not enough information.  [exist_part_name or new_part_name not provided]">
		</cfif>
		<cfoutput>
			<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
					<cfif isDefined("result_id") and len(result_id) GT 0>
						user_search_table
					<cfelse>
						#table_name#
					</cfif>
				where
					cataloged_item.collection_id=collection.collection_id and
					<cfif isDefined("result_id") and len(result_id) GT 0>
						cataloged_item.collection_object_id=user_search_table.collection_object_id and
						user_search_table.result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#"> and
					<cfelse>
						cataloged_item.collection_object_id=#table_name#.collection_object_id and
					</cfif>
					cataloged_item.collection_object_id=specimen_part.derived_from_cat_item and
					specimen_part.collection_object_id=coll_object.collection_object_id and
					specimen_part.collection_object_id=coll_object_remark.collection_object_id (+) and
					cataloged_item.collection_object_id=identification.collection_object_id and
					accepted_id_fg=1 and
					part_name='#exist_part_name#'
					<cfif len(existing_lot_count_modifier) gt 0>
						and lot_count=#existing_lot_count_modifier#
					</cfif>
					<cfif len(existing_lot_count) gt 0>
						and lot_count=#existing_lot_count#
					</cfif>
					<cfif len(existing_coll_obj_disposition) gt 0>
						and coll_obj_disposition='#existing_coll_obj_disposition#'
					</cfif>
				order by
					collection.collection,cataloged_item.cat_num
			</cfquery>
			<cfif isDefined("result_id") and len(result_id) GT 0>
				<cfset targeturl="/specimens/changeQueryParts.cfm?result_id=#result_id#">
			<cfelse>
				<cfset targeturl="/specimens/changeQueryParts.cfm?table_name=#table_name#">
			</cfif>
			<h2 class="h2 mt-2">Found #d.recordcount# parts to modifiy.</h2>
			<cfif d.recordcount EQ 0>
				<p class="px-2">
					Return to the Bulk Part Management tool <a href="#targeturl#">to change your criteria</a>.
				</p>
			<cfelse>
				<form name="modPart" method="post" action="/specimens/changeQueryParts.cfm">
					<input type="hidden" name="action" value="modPart2">
					<input type="hidden" name="table_name" value="#table_name#">
					<cfif isDefined("result_id") and len(result_id) GT 0>
						<input type="hidden" name="result_id" value="#result_id#">
					</cfif>
					<input type="hidden" name="exist_part_name" value="#exist_part_name#">
					<input type="hidden" name="new_part_name" value="#new_part_name#">
					<input type="hidden" name="exist_preserve_method" value="#exist_preserve_method#">
					<input type="hidden" name="new_preserve_method" value="#new_preserve_method#">
					<input type="hidden" name="existing_lot_count_modifier" value="#existing_lot_count_modifier#">
					<input type="hidden" name="new_lot_count_modifier" value="#new_lot_count_modifier#">
					<input type="hidden" name="existing_lot_count" value="#existing_lot_count#">
					<input type="hidden" name="new_lot_count" value="#new_lot_count#">
					<input type="hidden" name="existing_coll_obj_disposition" value="#existing_coll_obj_disposition#">
					<input type="hidden" name="new_coll_obj_disposition" value="#new_coll_obj_disposition#">
					<input type="hidden" name="new_condition" value="#new_condition#">
					<input type="hidden" name="new_remark" value="#new_remark#">
					<input type="hidden" name="partID" value="#valuelist(d.partID)#">
					<input type="submit" value="Change all of these parts" class="btn btn-xs btn-warning">
				</form>
				<h3 class="h4 px-3 mt-2">
					Or return to the Bulk Part Management tool <a href="#targeturl#">without making changes</a>.
				</h3>
				<table class="table table-responsive table-striped d-xl-table">
					<thead class="thead-light">
					<tr>
						<th>Specimen</th>
						<th>ID</th>
						<th>OldPart</th>
						<th>NewPart</th>
						<th>OldPresMethod</th>
						<th>NewPresMethod</th>
						<th>OldCondition</th>
						<th>NewCondition</th>
						<th>OldCntMod</th>
						<th>NewCntMod</th>
						<th>OldCnt</th>
						<th>NewCnt</th>
						<th>OldDispn</th>
						<th>NewDispn</th>
						<th>OldRemark</th>
						<th>NewRemark</th>
					</tr>
					</thead>
					<tbody>
					<cfloop query="d">
						<tr>
							<td>#collection# #cat_num#</td>
							<td>#scientific_name#</td>
							<td>#part_name#</td>
							<td>#new_part_name#</td>
							<td>#preserve_method#</td>
							<td>
								<cfif len(new_preserve_method) gt 0>
									<strong>#new_preserve_method#</strong>
								<cfelse>
									NOT UPDATED
								</cfif>
							</td>
							<td>#condition#</td>
							<td>
								<cfif len(new_condition) gt 0>
									<strong>#new_condition#</strong>
								<cfelse>
									NOT UPDATED
								</cfif>
							</td>
							<td>#lot_count_modifier#</td>
							<td>
								<cfif len(new_lot_count_modifier) gt 0>
									<strong>#new_lot_count_modifer#</strong>
								<cfelse>
									NOT UPDATED
								</cfif>
							</td>
							<td>#lot_count#</td>
							<td>
								<cfif len(new_lot_count) gt 0>
									<strong>#new_lot_count#</strong>
								<cfelse>
									NOT UPDATED
								</cfif>
							</td>
							<td>#coll_obj_disposition#</td>
							<td>
								<cfif len(new_coll_obj_disposition) gt 0>
									<strong>#new_coll_obj_disposition#</strong>
								<cfelse>
									NOT UPDATED
								</cfif>
							</td>
							<td>#coll_object_remarks#</td>
							<td>
								<cfif len(new_remark) gt 0>
									<strong>#new_remark#</strong>
								<cfelse>
									NOT UPDATED
								</cfif>
							</td>
		
						</tr>
					</cfloop>
					</tbody>
				</table>
			</cfif>
		</cfoutput>
	</cfcase>
	<!---------------------------------------------------------------------------->
	<cfcase value="newPart">
		<cfoutput>
			<cfquery name="ids" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT DISTINCT 
					collection_object_id 
				<cfif isDefined("result_id") and len(result_id) GT 0>
				FROM
					user_search_table
				WHERE
					user_search_table.result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
				<cfelse>
				FROM
					#table_name#
				</cfif>
			</cfquery>
			<cfset partCounter = 0>
			<cfset remarkCounter = 0>
			<cftransaction>
				<cftry>
					<cfloop query="ids">
						<cfloop from="1" to="#numParts#" index="n">
							<cfset thisPartName = #evaluate("part_name_" & n)#>
							<cfset thisPreserveMethod = #evaluate("preserve_method_" & n)#>
							<cfset thisLotCountModifier = #evaluate("lot_count_modifier_" & n)#>
							<cfset thisLotCount = #evaluate("lot_count_" & n)#>
							<cfset thisDisposition = #evaluate("coll_obj_disposition_" & n)#>
							<cfset thisCondition = #evaluate("condition_" & n)#>
							<cfset thisRemark = #evaluate("coll_object_remarks_" & n)#>
							<cfif len(#thisPartName#) gt 0>
								<cfquery name="insCollPart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
									INSERT INTO coll_object (
										COLLECTION_OBJECT_ID,
										COLL_OBJECT_TYPE,
										ENTERED_PERSON_ID,
										COLL_OBJECT_ENTERED_DATE,
										LAST_EDITED_PERSON_ID,
										COLL_OBJ_DISPOSITION,
										lot_count_modifier,
										LOT_COUNT,
										CONDITION,
										FLAGS )
									VALUES (
										sq_collection_object_id.nextval,
										'SP',
										#session.myAgentId#,
										sysdate,
										#session.myAgentId#,
										'#thisDisposition#',
										'#thisLotCountModifier#',
										#thisLotCount#,
										'#thisCondition#',
										0 )
								</cfquery>
								<cfquery name="newTiss" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
									INSERT INTO specimen_part (
										  COLLECTION_OBJECT_ID,
										  PART_NAME,
										  Preserve_method
											,DERIVED_FROM_cat_item)
										VALUES (
											sq_collection_object_id.currval,
										  '#thisPartName#',
										  '#thisPreserveMethod#'
											,#ids.collection_object_id#)
								</cfquery>
								<cfset partCounter = partCounter + 1>
								<cfif len(#thisRemark#) gt 0>
									<cfquery name="newCollRem" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
										INSERT INTO coll_object_remark (collection_object_id, coll_object_remarks)
										VALUES (sq_collection_object_id.currval, '#thisRemark#')
									</cfquery>
								</cfif>
							</cfif>
						</cfloop>
					</cfloop>
				<cftransaction action="commit">
				<cfcatch>
					<cftransaction action="rollback">
				</cfcatch>
				</cftry>
			</cftransaction>
			<div class="row mx-0">
				<div class="col-12 mt-3">
					<h2 class="px-2">Successfully added #partCounter# new parts.</h2>
					<h3 class="p-2">
						<cfif isDefined("result_id") and len(result_id) GT 0>
							<cfset targeturl="/specimens/changeQueryParts.cfm?result_id=#result_id#">
						<cfelse>
							<cfset targeturl="/specimens/changeQueryParts.cfm?table_name=#table_name#">
						</cfif>
						<a href="#targeturl#">Return to bulk part editor (see added parts)</a>
					</h3>
				</div>
			</div>
		</cfoutput>
	</cfcase>
	</cfswitch>
<cfcatch>
	<cfinclude template="/shared/component/error_handler.cfc" runOnce="true">
	<h2 class="h3 px-2 mt-1">Error</h2>
	<cfoutput>
		<cfset error_message = cfcatchToErrorMessage(cfcatch)>
		<p class="px-2">#error_message#</p>
	</cfoutput>
</cfcatch>
</cftry>
</main>

<cfinclude template="/shared/_footer.cfm">
