<!--- 
  specimens/changeQueryAddPartsLoan.cfm add parts to loans.

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
<cfset pageTitle="Add Parts To Loan">
<cfset pageHasTabs="true">
<cfinclude template="/shared/_header.cfm">
<cfinclude template="/shared/component/error_handler.cfc" runOnce="true">
<cfinclude template="/transactions/component/itemFunctions.cfc" runOnce="true">

<cfif isDefined("url.action") and len(url.action) GT 0>
	<cfset action = url.action>
<cfelseif isDefined("form.action") and len(form.action) GT 0>
	<cfset action = form.action>
<cfelse>
	<cfset action="entryPoint">
</cfif>
<cfif isDefined("url.result_id") and len(url.result_id) GT 0>
	<cfset result_id = url.result_id>
<cfelseif isDefined("form.result_id") and len(form.result_id) GT 0>
	<cfset result_id = form.result_id>
</cfif>
<cfif isDefined("url.transaction_id") and len(url.transaction_id) GT 0>
	<cfset transaction_id = url.transaction_id>
<cfelseif isDefined("form.transaction_id") and len(form.transaction_id) GT 0>
	<cfset transaction_id = form.transaction_id>
</cfif>

<!--- get list of collection codes in result set --->
<cfquery name="colcde" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	SELECT distinct(collection_cde) 
	FROM 
		user_search_table
		JOIN cataloged_item ON user_search_table.collection_object_id = cataloged_item.collection_object_id
	WHERE
	user_search_table.result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
</cfquery>
<cfset colcdes = valuelist(colcde.collection_cde)>

<script type="text/javascript" src="/transactions/js/transactions.js"></script> <!--- makeLoanPicker --->
<script type="text/javascript" src="/transactions/js/reviewLoanItems.js"></script><!--- openLoanItemDialog --->
<main class="container-fluid px-4 py-3" id="content">
<cftry>
	<cfswitch expression="#action#">
	<!--------------------------------------------------------------------->
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
				<cfthrow message="Unable to identify parts to work on [required variable table_name or result_id not defined].">
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
					<h1 class="h2 px-2">Add Parts to Loan</h1>
					<p class="px-2 mb-1">Add Parts from #getCount.ct# cataloged items from specimen search result [#result_id#] to a Loan</p>
					<cfif getCount.ct gte 1000>
						<cfthrow message="You can only use this form on up to 1000 specimens at a time. Please <a href='/Specimens.cfm'>revise your search</a>."><!--- " --->
					</cfif>

					<cfquery name="ctDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						SELECT coll_obj_disposition
						FROM ctcoll_obj_disp
						ORDER BY coll_obj_disposition
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
					<h2 class="h3">Loan to add Parts To:</h2>
					<div class="row border mx-0 mb-3 p-2">
						<div class="col-12 col-md-2 pt-1">
							<label for="loan_number" class="data-entry-label">Loan Number</label>
							<input type="hidden" id="loan_transaction_id" name="loan_transaction_id" value="">
							<input type="text" name="loan_number" id="loan_number" size="20" class="reqdClr data-entry-text" required>
							<script>
								$(document).ready(function() { 
									makeLoanPicker("loan_number", "loan_transaction_id",fetchLoanDetails); 
								});
								function fetchLoanDetails() {
									$.ajax({
										url: "/transactions/component/itemFunctions.cfc",
										dataType: "html",
										data: {
											method: "getLoanSummaryHTML",
											transaction_id: $("##loan_transaction_id").val(),
										},
										success: function(data) {
											$("##loanDetails").html(data);
											$(".addpartbutton").prop("disabled",false);
											$(".addpartbutton").removeClass("disabled");
										},
										error: function() {
											$("##loanDetails").html("<div class='text-danger'>Error fetching loan details.</div>");
										}
									});
								}
							</script>
						</div>
						<div class="col-12 col-md-8 pt-1">
							<div id="loanDetails">
								<cfif isDefined("transaction_id") and len(transaction_id) GT 0>
									<!--- lookup loan number and information about loan --->
									<cfset aboutLoan = getLoanSummaryHtml(transaction_id=transaction_id)>
									#aboutLoan#
								</cfif>
							</div>
						</div>
					</div>
					<div class="col-12">
						<cfquery name="getCatItems" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							SELECT 
								cataloged_item.collection_object_id,
								collection.institution_acronym,
								cataloged_item.collection_cde,
								cataloged_item.cat_num,
								collecting_event.began_date,
								collecting_event.ended_date,
								locality.spec_locality,
								geog_auth_rec.higher_geog
							FROM specimen_part
								JOIN user_search_table on specimen_part.derived_from_cat_item = user_search_table.collection_object_id
								JOIN cataloged_item on user_search_table.collection_object_id = cataloged_item.collection_object_id
								JOIN collection on cataloged_item.collection_id = collection.collection_id
								JOIN collecting_event on cataloged_item.collecting_event_id = collecting_event.collecting_event_id
								JOIN locality on collecting_event.locality_id = locality.locality_id
								JOIN geog_auth_rec on locality.geog_auth_rec_id = geog_auth_rec.geog_auth_rec_id
							WHERE user_search_table.result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
							ORDER BY part_name
						</cfquery>
						<cfloop query="getCatItems">
							<div class="row border border-2 mx-0 mb-2 p-2" style="border: 2px solid black !important;">
								<div class="col-12 col-md-4 mb-1">
									#institution_acronym#:#collection_cde#:#cat_num#
								</div>
								<div class="col-12 col-md-4 mb-1">
									#higher_geog#
									#spec_locality#
								</div>
								<div class="col-12 col-md-4 mb-1">
									<cfif began_date EQ ended_date>
										#began_date#
									<cfelse>
										#began_date#-#ended_date#
									</cfif>
								</div>
								<cfquery name="getParts" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									SELECT 
										specimen_part.collection_object_id part_id,
										part_name,
										preserve_method,
										coll_obj_disposition,
										lot_count, lot_count_modifier
									FROM specimen_part
										JOIN user_search_table on specimen_part.derived_from_cat_item = user_search_table.collection_object_id
										JOIN cataloged_item on user_search_table.collection_object_id = cataloged_item.collection_object_id
										JOIN coll_object on specimen_part.collection_object_id = coll_object.collection_object_id
									WHERE user_search_table.result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
										AND cataloged_item.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#getCatItems.collection_object_id#">
									ORDER BY part_name
								</cfquery>
								<cfloop query="getParts">
									<cfquery name="checkPartInLoan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
										SELECT loan_item_id
										FROM loan_item
										WHERE 
											loan_item.transaction_id = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#transaction_id#">
											AND loan_item.part_id = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#getParts.part_id#">
									</cfquery>
									<div class="col-12 row mx-0 py-1 border-top border-secondary">
										<div class="col-12 col-md-2">
											#part_name# (#preserve_method#) #lot_count_modifier#&nbsp;#lot_count#
										</div>
										<div class="col-12 col-md-3">
											<label class="data_entry_label" for="item_instructions_#part_id#">Item Instructions</label>
											<input type="text" name="item_instructions" id="item_instructions_#part_id#" class="data-entry-input" value="">
										</div>
										<div class="col-12 col-md-3">
											<label class="data_entry_label" for="loan_item_remarks_#part_id#">Item Remarks</label>
											<input type="text" name="loan_item_remarks" id="loan_item_remarks_#part_id#" class="data-entry-input" value="">
										</div>
										<div class="col-12 col-md-2">
											<label class="data_entry_label" for="col_obj_disposition_#part_id#">Disposition</label>
											<input type="text" name="coll_obj_disposition" id="coll_obj_disposition_#part_id#" class="data-entry-select" value="#getParts.coll_obj_disposition#"
												readonly="readonly" disabled="disabled">
											<!---
											<select name="coll_obj_disposition" id="coll_obj_disposition_#part_id#" class="data-entry-select">
												<cfloop query="ctDisp">
													<cfif ctDisp.coll_obj_disposition EQ getParts.coll_obj_disposition>
														<cfset selected="selected">
													<cfelse>
														<cfset selected="">
													</cfif>
													<option #selected# value="#ctDisp.coll_obj_disposition#">#ctDisp.coll_obj_disposition#</option> 
												</cfloop>
											</select>
											--->
										</div>
										<div class="col-12 col-md-1">
											<label class="data_entry_label" for="subsample#part_id#">Subsample</label>
											<select name="subsample" id="subsample_#part_id#" class="data-entry-select">
												<option value="0" selected>No</option>
												<option value="1">Yes</option>
											</select>
										</div>
										<div class="col-12 col-md-1">
											<!--- TODO: Check if this part is in this loan already, if so show Edit button instead of Add --->
											<button class="btn btn-xs btn-primary addpartbutton disabled" disabled
												onClick="addPartToLoan(#part_id#);" 
												name="add_part_#part_id#" id="add_part_#part_id#">Add</button>
											<cfif checkPartInLoan.recordcount GT 0>
												<cfset loan_item_id = "#checkPartInLoan.loan_item_id#">
											<cfelse>
												<cfset loan_item_id = "">
											</cfif>
											<input type="hidden" name="loan_item_id_#part_id#" id="loan_item_id_#part_id#" value="#loan_item_id#">
											<button class="btn btn-xs btn-primary editpartbutton" style="display: none;"
												onClick="launchEditDialog(#part_id#);" 
												name="edit_part_#part_id#" id="edit_part_#part_id#">Edit</button>
											<output id="output#part_id#">
												<cfif checkPartInLoan.recordcount GT 0>
													In this loan.
													<script>
														$(document).ready(function() { 
															$("#add_part_#part_id#").hide();
															$("#edit_part_#part_id#").show();
															$("#item_instructions_#part_id#").prop("disabled",true);
															$("#item_instructions_#part_id#").addClass("disabled");
															$("#loan_item_remarks_#part_id#").prop("disabled",true);
															$("#loan_item_remarks_#part_id#").addClass("disabled");
															$("#coll_obj_disposition_#part_id#").prop("disabled",true);
															$("#coll_obj_disposition_#part_id#").addClass("disabled");
														});
													</script>
												</cfif>
											</output>
										</div>
									</div>
								</cfloop>
							</div>
							<div id="editItemDialogDiv"></div>
						</cfloop>
						<script>
							function launchEditDialog(part_id) { 
								var loan_item_id = $("#loan_item_id_"+part_id).val();
								openLoanItemDialog(loan_item_id,"editItemDialogDiv",null);
							}
							function addPartToLoan(part_id) { 
								// get values from inputs for part
								subsample = $("##subsample"+part_id).val();
								var subsampleInt = 0;
								if (subsample=="true" || subsample==1 || subsample=="1") {
									subsampleInt = 1;
								}
								transaction_id = $("##loan_transaction_id").val();
								remark = $("##loan_item_remarks_"+part_id).val();
								instructions = $("##item_instructions_"+part_id).val();
								$("##output"+part_id).html("Saving...");
								jQuery.ajax({
									url: "/transactions/component/itemFunctions.cfc",
									data : {
									method : "addPartToLoan",
									transaction_id: transaction_id,
									part_id: part_id,
									remark: remark,
									instructions: instructions,
									subsample: subsampleInt,
									returnformat : "json",
									queryformat : 'column'
								},
								success: function (result) {
								if (typeof result == 'string') { result = JSON.parse(result); } 
									if (result.DATA.STATUS[0]==1) {
										$("##output"+part_id).html(result.DATA.MESSAGE[0]);
										$("##coll_obj_disposition_"+part_id).val("on loan");
										// Obtain loan_item_id from result and save where Edit button can use it.
										$("##loan_item_id_"+part_id).val(result.DATA.LOAN_ITEM_ID[0]);
										// Lock controls, part added.
										$("##add_part_"+part_id).hide();
										$("##edit_part_"+part_id).show();
										$("##item_instructions_"+part_id).prop("disabled",true);
										$("##item_instructions_"+part_id).addClass("disabled");
										$("##loan_item_remarks_"+part_id).prop("disabled",true);
										$("##loan_item_remarks_"+part_id).addClass("disabled");
										$("##coll_obj_disposition_"+part_id).prop("disabled",true);
										$("##coll_obj_disposition_"+part_id).addClass("disabled");
									 } else { 
										$("##output"+part_id).html("Error");
									}
								},
								error: function (jqXHR, textStatus, error) {
									$("##output"+part_id).html("Error");
									handleFail(jqXHR,textStatus,error,"adding a part as a loan item to a loan");
								},
								dataType: "html"
								});
							}
						</script>
					</div>
				</div>
			</div>
		</cfoutput>
	</cfcase>
	<cfcase value="filterParts">
		<!--- TODO: Implement or remove filtering logic --->
					<!--- queries to populate pick lists for filtering --->
					<cfquery name="existParts" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
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
					<cfquery name="existPreserve" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
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
					<cfquery name="existLotCountModifier" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						SELECT
							coll_object.lot_count_modifier
						FROM
							specimen_part
							JOIN coll_object on specimen_part.collection_object_id=coll_object.collection_object_id
							JOIN user_search_table on specimen_part.derived_from_cat_item = user_search_table.collection_object_id
						WHERE
							user_search_table.result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
						GROUP BY 
							coll_object.lot_count_modifier
					</cfquery>
					<cfquery name="existLotCount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						SELECT
							coll_object.lot_count
						FROM
							specimen_part
							JOIN coll_object on specimen_part.collection_object_id=coll_object.collection_object_id
							JOIN user_search_table on specimen_part.derived_from_cat_item = user_search_table.collection_object_id
						WHERE
							user_search_table.result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
						GROUP BY 
							coll_object.lot_count
					</cfquery>
					<cfquery name="existDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						SELECT
							coll_object.coll_obj_disposition 
						FROM
							specimen_part
							JOIN coll_object on specimen_part.collection_object_id=coll_object.collection_object_id
							JOIN user_search_table on specimen_part.derived_from_cat_item = user_search_table.collection_object_id
						WHERE
							user_search_table.result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
						GROUP BY 
							coll_object.coll_obj_disposition 
					</cfquery>

					<h2 class="h3">Filter specimens for parts matching...</h2>
					<form name="filterByPart" method="post" action="/specimens/changeQueryAddPartsToLoan.cfm">
						<input type="hidden" name="action" value="filterParts">
						<input type="hidden" name="result_id" value="#result_id#">
						<div class="form-row">
							<div class="col-12 col-md-4 pt-1">
								<label for="exist_part_name" class="data-entry-label">Part Name Matches</label>
								<select name="exist_part_name" id="exist_part_name" size="1" class="reqdClr data-entry-select" required>
									<option selected="selected" value=""></option>
									<cfloop query="existParts">
										<option value="#Part_Name#">#Part_Name# (#existParts.partCount# parts)</option>
									</cfloop>
								</select>
							</div>
							<div class="col-12 col-md-4 pt-1">
								<label for="exist_preserve_method" class="data-entry-label">Preserve Method Matches</label>
								<select name="exist_preserve_method" id="exist_preserve_method" size="1" class="data-entry-select">
									<option selected="selected" value=""></option>
									<cfloop query="existPreserve">
										<option value="#Preserve_method#">#Preserve_method# (#existPreserve.partCount# parts)</option>
									</cfloop>
								</select>
							</div>
							<div class="col-12 col-md-4 pt-1">
								<label for="existing_lot_count_modifier" class="data-entry-label">Lot Count Modifier Matches</label>
								<select name="existing_lot_count_modifier" id="existing_lot_count_modifier" size="1" class="data-entry-select">
									<option selected="selected" value=""></option>
									<cfloop query="existLotCountModifier">
										<option value="#lot_count_modifier#">#lot_count_modifier#</option>
									</cfloop>
								</select>
							</div>
							<div class="col-12 col-md-4 pt-1">
								<label for="existing_lot_count" class="data-entry-label">Lot Count Matches</label>
								<select name="existing_lot_count" id="existing_lot_count" size="1" class="data-entry-select">
									<option selected="selected" value=""></option>
									<cfloop query="existLotCount">
										<option value="#lot_count#">#lot_count#</option>
									</cfloop>
								</select>
							</div>
							<div class="col-12 col-md-4 pt-1">
								<label for="existing_coll_obj_disposition" class="data-entry-label">Disposition Matches</label>
								<select name="existing_coll_obj_disposition" id="existing_coll_obj_disposition" size="1" class="data-entry-select">
									<option selected="selected" value=""></option>
									<cfloop query="existDisp">
										<option value="#coll_obj_disposition#">#coll_obj_disposition#</option>
									</cfloop>
								</select>
							</div>
							<div class="col-12 col-md-4 pt-1">
								<input type="submit" value="Filter" class="btn ml-2 mt-2 btn-xs btn-secondary">
							</div>
						</div>
					</form>
		</cfcase>
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
