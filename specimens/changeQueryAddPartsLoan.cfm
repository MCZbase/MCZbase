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
<cfif not isDefined("transaction_id") OR len(transaction_id) EQ 0 >
	<cfset action = "entryPoint">
<cfelse>
	<cfset action = "hasTransaction">
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
		<cfthrow message="Unable to identify parts on [required variable result_id not defined].">
	</cfif>
	<cfswitch expression="#action#">
	<cfcase value="entryPoint">
		<!--- initial entry point, show form to select loan before listing parts--->
		<div class="row mx-0">
			<div class="col-12">
				<h1 class="h2 px-2">Add Parts to Loan</h1>
				<p class="px-2 mb-1">Add Parts from #getCount.ct# cataloged items from specimen search result [#result_id#] to a Loan</p>
				<cfif getCount.ct gte 1000>
					<cfthrow message="You can only use this form on up to 1000 specimens at a time. Please <a href='/Specimens.cfm'>revise your search</a>."><!--- " --->
				</cfif>
				<h2 class="h3">Pick Loan to add Parts To:</h2>
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
								var transaction_id = $("##loan_transaction_id").val();
								$.ajax({
									url: "/transactions/component/itemFunctions.cfc",
									dataType: "html",
									data: {
										method: "getLoanSummaryHTML",
										transaction_id: transaction_id
									},
									success: function(data) {
										$("##loanDetails").html(data);
										// enable continue button
										$("##continueButton").prop("disabled",false);
										$("##continueButton").removeClass("disabled");
										// rewrite a tag continueButton href to include transaction_id
										$("##continueButton").attr("href","/specimens/changeQueryAddPartsLoan.cfm?result_id=#encodeForUrl(result_id)#&action=hasTransaction&transaction_id="+transaction_id);
									},
									error: function() {
										$("##loanDetails").html("<div class='text-danger'>Error fetching loan details.</div>");
									}
								});
							}
						</script>
					</div>
					<div class="col-12 col-md-8 pt-1">
						<div id="loanDetails"></div>
					</div>
					<div class="col-12">
						<a href="/specimens/changeQueryAddPartsLoan.cfm?result_id=#encodeForUrl(result_id)#&action=hasTransaction" 
							class="btn btn-primary mt-2 disabled" 
							id="continueButton"
							disabled="disabled">Continue to Add Parts</a>
					</div>
				</div>
			</div>
		</div>
	</cfcase>
	<!--------------------------------------------------------------------->
	<cfcase value="hasTransaction">
		<script>
			var resultbc = new BroadcastChannel('resultset_channel');
			resultbc.onmessage = function (message) { 
				console.log(message);
				if (message.data.result_id == "#result_id#") { 
					messageDialog("Warning: You have removed one or more records from this result set, you must reload this page to see the current list of records this page affects.", "Result Set Changed Warning");
					$(".makeChangeButton").prop("disabled",true);
					$(".makeChangeButton").addClass("disabled");
					$(".tabChangeButton").prop("disabled",true);
					$(".tabChangeButton").addClass("disabled");
				}  
			} 
			var loanbc = new BroadcastChannel('loan_channel');
			function loanModifiedHere() { 
				loanbc.postMessage({"source":"addloanitems","transaction_id":"#transaction_id#"});
			}
			loanbc.onmessage = function (message) { 
				console.log(message);
				if (message.data.source == "loan" && message.data.transaction_id == "#transaction_id#") { 
					 reloadLoanSummary();
				}
				if (message.data.source == "reviewitems" && message.data.transaction_id == "#transaction_id#") { 
					messageDialog("Warning: You have added or removed an item from this loan, you must reload this page to see the current list of records this page affects.", "Loan Item List Changed Warning");
				}
			}
		</script>
		<!--- lookup loan number from transaction_id --->
		<cfquery name="getLoanNumber" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			SELECT loan.transaction_id, loan.loan_number
			FROM loan
			WHERE loan.transaction_id = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#transaction_id#">
		</cfquery>
		<cfif getLoanNumber.recordcount GT 0>
			<cfset loannumber = "#getLoanNumber.loan_number#">
		<cfelse>
			<cfthrow message="Unable to identify loan with provided transaction ID [#encodeForHtml(transaction_id)#].">
		</cfif>
		<div class="row mx-0">
			<div class="col-12">
				<h1 class="h2 px-2">Add Parts to Loan</h1>
				<p class="px-2 mb-1">Add Parts from #getCount.ct# cataloged items from specimen search result [#result_id#] to Loan #loannumber#</p>
				<cfif getCount.ct gte 1000>
					<cfthrow message="You can only use this form on up to 1000 specimens at a time. Please <a href='/Specimens.cfm'>revise your search</a>."><!--- " --->
				</cfif>
				<h2 class="h3">Loan to add Parts To:</h2>
				<div class="row border mx-0 mb-3 p-2">
					<div class="col-12 col-md-2 pt-1">
						<label for="loan_number" class="data-entry-label">Loan Number</label>
						<input type="hidden" id="loan_transaction_id" name="loan_transaction_id" value="#transaction_id#">
						<input type="text" name="loan_number" id="loan_number" class="data-entry-text" readonly disabled value="#loannumber#">
					</div>
					<div class="col-12 col-md-8 pt-1">
						<div id="loanDetails">
							<!--- lookup information about loan --->
							<cfset aboutLoan = getLoanSummaryHtml(transaction_id=transaction_id)>
							#aboutLoan#
						</div>
					</div>
					<script>
						function reloadLoanSummary() { 
							// ajax invocation of getLoanSummaryHtml to refresh loan details in loanDetails div
							$.ajax({
								url: "/transactions/component/itemFunctions.cfc",
								dataType: "html",
								data: {
									method: "getLoanSummaryHTML",
									transaction_id: $("##loan_transaction_id").val(),
								},
								success: function(data) {
									$("##loanDetails").html(data);
								},
								error: function() {
									$("##loanDetails").html("<div class='text-danger'>Error fetching loan details.</div>");
								}
							});
						}
					</script>
				</div>
				<div class="col-12 row">
					<div class="col-12 col-md-6">
						<label for="common_instruction_text" class="data-entry-label">Instructions to add to each item when adding to loan.</label>
						<input type="text" value="" id="common_instruction_text" class="data-entry-input">
					</div>
					<div class="col-12 col-md-6">
						<label for="common_append_part_condition" class="data-entry-label">Append the part condition to each loan item description.</label>
						<select id="common_append_part_condition" class="data-entry-select">
							<option value="false" selected>No</option>
							<option value="true">Yes</option>
						</select>
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
									lot_count, 
									lot_count_modifier
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
									SELECT loan_item_id,
										item_instructions,
										loan_item_remarks
									FROM loan_item
									WHERE 
										loan_item.transaction_id = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#transaction_id#">
										AND loan_item.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#getParts.part_id#">
								</cfquery>
								<cfif checkPartInLoan.recordcount GT 0>
									<cfset item_instructions = "#checkPartInLoan.item_instructions#">
									<cfset loan_item_remarks = "#checkPartInLoan.loan_item_remarks#">
								<cfelse>
									<cfset item_instructions = "">
									<cfset loan_item_remarks = "">
								</cfif>
								<cfquery name="checkPartInOtherLoan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									SELECT
										loan_item_id, 
										loan_item.loan_item_state,
										loan.loan_number, 
										loan.transaction_id
									FROM loan_item
										join loan on loan_item.transaction_id = loan.transaction_id
									WHERE 
										loan_item.transaction_id <> <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#transaction_id#">
										AND loan_item.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#getParts.part_id#">
										AND loan.loan_status <> 'closed'
										AND loan_item.loan_item_state <> 'returned'
								</cfquery>
								<div class="col-12 row mx-0 py-1 border-top border-secondary">
									<div class="col-12 col-md-2">
										<input type="hidden" name="part_name_#part_id#" id="part_name_#part_id#" value="#getParts.part_name# (#getParts.preserve_method#)">
										#getParts.part_name# (#getParts.preserve_method#) #getParts.lot_count_modifier#&nbsp;#getParts.lot_count#
									</div>
									<div class="col-12 col-md-3">
										<label class="data_entry_label" for="item_instructions_#part_id#">Item Instructions</label>
										<input type="text" name="item_instructions" id="item_instructions_#part_id#" class="data-entry-input" value="#item_instructions#">
									</div>
									<div class="col-12 col-md-3">
										<label class="data_entry_label" for="loan_item_remarks_#part_id#">Item Remarks</label>
										<input type="text" name="loan_item_remarks" id="loan_item_remarks_#part_id#" class="data-entry-input" value="#loan_item_remarks#">
									</div>
									<div class="col-12 col-md-2">
										<label class="data_entry_label" for="col_obj_disposition_#part_id#">Disposition</label>
										<input type="text" name="coll_obj_disposition" id="coll_obj_disposition_#part_id#" class="data-entry-select" value="#getParts.coll_obj_disposition#"
											readonly="readonly" disabled="disabled">
									</div>
									<div class="col-12 col-md-1">
										<label class="data_entry_label" for="subsample#part_id#">Subsample</label>
										<select name="subsample" id="subsample_#part_id#" class="data-entry-select">
											<option value="0" selected>No</option>
											<option value="1">Yes</option>
										</select>
									</div>
									<div class="col-12 col-md-1">
										<button class="btn btn-xs btn-primary addpartbutton"
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
														$("##add_part_#part_id#").hide();
														$("##edit_part_#part_id#").show();
														$("##item_instructions_#part_id#").prop("disabled",true);
														$("##item_instructions_#part_id#").addClass("disabled");
														$("##loan_item_remarks_#part_id#").prop("disabled",true);
														$("##loan_item_remarks_#part_id#").addClass("disabled");
														$("##coll_obj_disposition_#part_id#").prop("disabled",true);
														$("##coll_obj_disposition_#part_id#").addClass("disabled");
													});
												</script>
											</cfif>
										</output>
									</div>
									<cfif checkPartInOtherLoan.recordcount GT 0>
										<div class="col-12">
											<ul>
												<cfloop query="checkPartInOtherLoan">
													<li>
														<span class="text-danger font-weight-bold">Note:</span> This part is in loan 
														<a href="/transactions/Loan.cfm?action=edit&transaction_id=#checkPartInOtherLoan.transaction_id#">
															#checkPartInOtherLoan.loan_number#
														</a>
														(in state: #checkPartInOtherLoan.loan_item_state#).
													</li>
												</cfloop>
											</ul>
										</div>
									</cfif>
								</div>
							</cfloop>
						</div>
					</cfloop>
					<div id="editItemDialogDiv"></div>
					<script>
						function launchEditDialog(part_id) { 
							var loan_item_id = $("##loan_item_id_"+part_id).val();
							var part_name = $("##part_name_"+part_id).val();
							openLoanItemDialog(loan_item_id,"editItemDialogDiv",part_name,null);
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
							common_instructions = $("##common_instruction_text").val(); 
							if (length(common_instructions) > 0) {
								if (!instructions.contains(common_instructions)) { 
									if (length(instructions) > 0) { 
										instructions = instructions + "; " + common_instructions;
									} else {
										instructions = common_instructions;
									}
									 $("##item_instructions_"+part_id).val(instructions);
								} 
							}
							append_part_condition = $("##common_append_part_condtion").val();
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
								append_part_condition: append_part_condition,
								returnformat : "json",
								queryformat : 'column'
							},
							success: function (result) {
								if (typeof result == 'string') { result = JSON.parse(result); } 
								if (result.DATA.STATUS[0]==1) {
									loanModifiedHere();
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
	</cfcase>
	</cfswitch>
	</cfoutput>
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
