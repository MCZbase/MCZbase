<!--- 
  specimens/changeQueryDeaccession.cfm add parts to a deaccession, one at a time.

  Patterned after specimens/changeQueryAddPartsLoan.cfm:
   (1) If no deaccession transaction_id is provided, show an entry point to pick a deaccession.
   (2) Once a deaccession is known, list specimen parts for each cataloged item in the
       result referenced by result_id, and provide per‑item Add controls that can
       supply deacc_item.item_instructions and deacc_item.deacc_item_remarks.
   NOTE: Unlike loans, subsample is not relevant here, so no subsample controls.

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

<cfset pageTitle="Add Parts To Deaccession">
<cfinclude template="/shared/_header.cfm">
<cfinclude template="/shared/component/error_handler.cfc" runOnce="true">
<cfinclude template="/transactions/component/itemFunctions.cfc" runOnce="true">
<cfinclude template="/transactions/component/functions.cfc" runOnce="true">

<!--- Enforce non‑master branch for safety, mirroring original file. --->
<cfif findNoCase('master',Session.gitBranch) GT 0>
	<cfthrow message="Not ready for production use.">
</cfif>

<!--- Obtain result_id and transaction_id from URL or FORM scopes --->
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

<cfif not isDefined("result_id") OR len(result_id) EQ 0>
	<cfthrow message="Unable to identify parts on [required variable result_id not defined].">
</cfif>

<!--- Determine action based on whether a deaccession transaction is known --->
<cfif not isDefined("transaction_id") OR len(transaction_id) EQ 0 >
	<cfset action = "entryPoint">
<cfelse>
	<cfset action = "hasTransaction">
</cfif>

<!--- get list of collection codes in result set (for information/validation if needed) --->
<cfquery name="colcde" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	SELECT distinct(cataloged_item.collection_cde) 
	FROM 
		user_search_table
		JOIN cataloged_item ON user_search_table.collection_object_id = cataloged_item.collection_object_id
	WHERE
		user_search_table.result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
</cfquery>
<cfset colcdes = valuelist(colcde.collection_cde)>

<script type="text/javascript" src="/transactions/js/transactions.js"></script>

<main class="container-fluid px-4 py-3" id="content">
<cftry>
	<cfoutput>
		<!--- Count cataloged items in result set --->
		<cfquery name="getCount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			SELECT count(*) ct
			FROM user_search_table
			WHERE user_search_table.result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
		</cfquery>

		<cfswitch expression="#action#">
		<cfcase value="entryPoint">
			<!--- ENTRY POINT: pick a deaccession before listing parts --->
			<div class="row mx-0">
				<div class="col-12">
					<h1 class="h2 px-2">Add Parts to Deaccession</h1>
					<p class="px-2 mb-1">
						Add Parts from #getCount.ct# cataloged items from specimen search result [#result_id#] to a Deaccession.
					</p>
					<cfif getCount.ct gte 1000>
						<cfthrow message="You can only use this form on up to 1000 specimens at a time. Please <a href='/Specimens.cfm'>revise your search</a>."><!--- " --->
					</cfif>

					<h2 class="h3">Pick Deaccession to add Parts To:</h2>
					<div class="row border mx-0 mb-3 p-2">
						<div class="col-12 col-md-3 pt-1">
							<label for="deacc_number" class="data-entry-label">Deaccession Number</label>
							<input type="hidden" id="deacc_transaction_id" name="deacc_transaction_id" value="">
							<input type="text" name="deacc_number" id="deacc_number" size="20" class="reqdClr data-entry-text" required>
							<script>
								$(document).ready(function() { 
									makeDeaccessionAutocompleteMeta("deacc_number", "deacc_transaction_id");
									$("##deacc_number").on("change", fetchDeaccessionDetails);
								});
								function fetchDeaccessionDetails() {
									var transaction_id = $("##deacc_transaction_id").val();
									if (!transaction_id) { 
										$("##deaccDetails").html("<div class='text-warning'>Please select a valid deaccession.</div>");
										$("##continueButton").prop("disabled",true).addClass("disabled");
										return;
									}
									$.ajax({
										url: "/transactions/component/itemFunctions.cfc",
										dataType: "html",
										data: {
											method: "getDeaccessionSummaryHTML",
											transaction_id: transaction_id
										},
										success: function(data) {
											$("##deaccDetails").html(data);
											// enable continue button
											$("##continueButton").prop("disabled",false).removeClass("disabled");
											// rewrite continue button href to include transaction_id
											$("##continueButton").attr(
												"href",
												"/specimens/changeQueryDeaccession.cfm?result_id=#encodeForUrl(result_id)#&action=hasTransaction&transaction_id="+transaction_id
											);
										},
										error: function() {
											$("##deaccDetails").html("<div class='text-danger'>Error fetching deaccession details.</div>");
											$("##continueButton").prop("disabled",true).addClass("disabled");
										}
									});
								}
							</script>
						</div>
						<div class="col-12 col-md-7 pt-1">
							<div id="deaccDetails"></div>
						</div>
						<div class="col-12">
							<a href="/specimens/changeQueryDeaccession.cfm?result_id=#encodeForUrl(result_id)#&action=hasTransaction" 
								class="btn btn-primary mt-2 disabled" 
								id="continueButton"
								disabled="disabled">Continue to Add Parts</a>
						</div>
					</div>
				</div>
			</div>
		</cfcase>


		<cfcase value="hasTransaction">
			<!--- action hasTransaction: a deaccession is known, list parts to add --->	
			<!--- get list of possible dispositions --->
			<cfquery name="ctcoll_obj_disp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT coll_obj_disposition 
				FROM ctcoll_obj_disp 
				ORDER BY coll_obj_disposition
			</cfquery>
			<!--- Broadcast channel hooks --->
			<script>
				var resultbc = new BroadcastChannel('resultset_channel');
				resultbc.onmessage = function (message) { 
					console.log(message);
					if (message.data.result_id == "#result_id#") { 
						messageDialog(
							"Warning: You have removed one or more records from this result set, you must reload this page to see the current list of records this page affects.",
							"Result Set Changed Warning"
						);
						$(".makeChangeButton").prop("disabled",true).addClass("disabled");
						$(".tabChangeButton").prop("disabled",true).addClass("disabled");
						$(".addpartbutton").prop("disabled",true).addClass("disabled");
					}  
				};

				var deaccbc = new BroadcastChannel('deaccession_channel');
				function deaccessionModifiedHere() { 
					deaccbc.postMessage({"source":"adddeaccitems","transaction_id":"#transaction_id#"});
				}
				deaccbc.onmessage = function (message) { 
					console.log(message);
					if (message.data.source == "deaccession" && message.data.transaction_id == "#transaction_id#") { 
						reloadDeaccessionSummary();
					}
					if (message.data.source == "reviewdeaccitems" && message.data.transaction_id == "#transaction_id#") { 
						messageDialog(
							"Warning: You have added or removed an item from this deaccession, you must reload this page to see the current list of records this page affects.",
							"Deaccession Item List Changed Warning"
						);
					}
				}
			</script>

			<!--- lookup deaccession number and collection info from transaction_id --->
			<cfquery name="getDeaccNumber" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT 
					deaccession.transaction_id,
					deaccession.deacc_number,
					trans.collection_id,
					c.collection
				FROM 
					deaccession
					JOIN trans ON deaccession.transaction_id = trans.transaction_id
					JOIN collection c ON trans.collection_id = c.collection_id
				WHERE 
					deaccession.transaction_id = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#transaction_id#">
			</cfquery>
			<cfif getDeaccNumber.recordcount GT 0>
				<cfset deaccnumber = "#getDeaccNumber.deacc_number#">
				<cfset deacc_collection = "#getDeaccNumber.collection#">
			<cfelse>
				<cfthrow message="Unable to identify deaccession with provided transaction ID [#encodeForHtml(transaction_id)#].">
			</cfif>

			<div class="row mx-0">
				<div class="col-12">
					<h1 class="h2 px-2">Add Parts to Deaccession</h1>
					<p class="px-2 mb-1">
						Add Parts from #getCount.ct# cataloged items from specimen search result [#result_id#] 
						to Deaccession #deaccnumber# (#deacc_collection#).
					</p>
					<cfif getCount.ct gte 1000>
						<cfthrow message="You can only use this form on up to 1000 specimens at a time. Please <a href='/Specimens.cfm'>revise your search</a>."><!--- " --->
					</cfif>

					<h2 class="h3">Deaccession to add Parts To:</h2>
					<div class="row border mx-0 mb-3 p-2">
						<div class="col-12 col-md-3 pt-1">
							<label for="deacc_number" class="data-entry-label">Deaccession Number</label>
							<input type="hidden" id="deacc_transaction_id" name="deacc_transaction_id" value="#transaction_id#">
							<input type="text" name="deacc_number" id="deacc_number" class="data-entry-text" readonly disabled value="#deaccnumber#">
						</div>
						<div class="col-12 col-md-7 pt-1">
							<div id="deaccDetails">
								<!--- lookup information about deaccession via backing function --->
								<cfset aboutDeacc = getDeaccessionSummaryHtml(transaction_id=transaction_id)>
								#aboutDeacc#
							</div>
						</div>
						<script>
							function reloadDeaccessionSummary() { 
								// ajax invocation of getDeaccessionSummaryHtml to refresh deaccession details
								$.ajax({
									url: "/transactions/component/itemFunctions.cfc",
									dataType: "html",
									data: {
										method: "getDeaccessionSummaryHTML",
										transaction_id: $("##deacc_transaction_id").val()
									},
									success: function(data) {
										$("##deaccDetails").html(data);
									},
									error: function() {
										$("##deaccDetails").html("<div class='text-danger'>Error fetching deaccession details.</div>");
									}
								});
							}
						</script>
					</div>

					<!--- Common actions on each added item (instructions/remarks) --->
					<div class="col-12">
						<div class="add-form mt-2">
							<div class="add-form-header pt-1 px-2">
								<h2 class="h4 mb-0 pb-0">Actions on each added item</h2>
							</div>
							<div class="card-body form-row my-1">
								<div class="col-12 col-md-4">
									<label for="common_remarks_text" class="data-entry-label">
										Remarks to append to each item when adding to deaccession.
									</label>
									<input type="text" value="" id="common_remarks_text" class="data-entry-input">
								</div>
								<div class="col-12 col-md-4">
									<label for="common_instruction_text" class="data-entry-label">
										Instructions to add to each item when adding to deaccession.
									</label>
									<input type="text" value="" id="common_instruction_text" class="data-entry-input">
								</div>
								<div class="col-12 col-md-4">
									<label for="common_disposition" class="data-entry-label">
										Disposition to use for all parts added to this deaccession.
									</label>
									<select id="common_disposition" class="data-entry-select">
										<option value=""></option>
										<cfloop query="ctcoll_obj_disp">
											<option value="#ctcoll_obj_disp.coll_obj_disposition#">#ctcoll_obj_disp.coll_obj_disposition#</option>
										</cfloop>
									</select>
								</div>
							</div>
						</div>
					</div>

					<!--- List cataloged items and then their parts --->
					<div class="col-12">
						<cfquery name="getCatItems" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							SELECT DISTINCT 
								cataloged_item.collection_object_id,
								collection.institution_acronym,
								cataloged_item.collection_cde,
								cataloged_item.cat_num,
								collecting_event.began_date,
								collecting_event.ended_date,
								locality.spec_locality,
								geog_auth_rec.higher_geog
							FROM 
								user_search_table 
								JOIN cataloged_item on user_search_table.collection_object_id = cataloged_item.collection_object_id
								JOIN collection on cataloged_item.collection_id = collection.collection_id
								JOIN collecting_event on cataloged_item.collecting_event_id = collecting_event.collecting_event_id
								JOIN locality on collecting_event.locality_id = locality.locality_id
								JOIN geog_auth_rec on locality.geog_auth_rec_id = geog_auth_rec.geog_auth_rec_id
							WHERE user_search_table.result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
							ORDER BY collection_cde, cat_num
						</cfquery>

						<cfloop query="getCatItems">
							<cfset guid = "#institution_acronym#:#collection_cde#:#cat_num#">
							<div class="row border border-2 mx-0 mb-2 p-2" style="border: 2px solid black !important;">
								<div class="col-12 col-md-4 mb-1">
									<a href="/guid/#guid#" target="_blank">#institution_acronym#:#collection_cde#:#cat_num#</a>
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

								<!--- Parts for this cataloged item within the result set --->
								<cfquery name="getParts" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									SELECT DISTINCT
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
									WHERE 
										user_search_table.result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
										AND cataloged_item.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#getCatItems.collection_object_id#">
									ORDER BY part_name
								</cfquery>

								<cfloop query="getParts">
									<!--- Look for this part already in this deaccession --->
									<cfquery name="checkPartInDeacc" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
										SELECT 
											deacc_item_id,
											item_instructions,
											deacc_item_remarks
										FROM deacc_item
										WHERE 
											deacc_item.transaction_id = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#transaction_id#">
											AND deacc_item.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#getParts.part_id#">
									</cfquery>

									<!--- Existing remarks on the part (coll_object_remark) --->
									<cfquery name="getPartRemarks" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
										SELECT coll_object_remarks 
										FROM coll_object_remark
										WHERE collection_object_id = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#getParts.part_id#">
									</cfquery>
									<cfset partRemarks ="">
									<cfset separator="">
									<cfloop query="getPartRemarks">
										<cfif len(getPartRemarks.coll_object_remarks) GT 0>
											<cfset partRemarks ="#separator##getPartRemarks.coll_object_remarks#">
											<cfset separator="; ">
										</cfif>
									</cfloop>

									<cfif checkPartInDeacc.recordcount GT 0>
										<cfset item_instructions = "#checkPartInDeacc.item_instructions#">
										<cfset deacc_item_remarks = "#checkPartInDeacc.deacc_item_remarks#">
									<cfelse>
										<cfset item_instructions = "">
										<cfset deacc_item_remarks = "">
									</cfif>

									<!--- Check if this part is already in any other deaccession --->
									<cfquery name="checkPartInOtherDeacc" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
										SELECT
											deacc_item_id, 
											deaccession.deacc_number,
											deaccession.transaction_id
										FROM deacc_item
											JOIN deaccession ON deacc_item.transaction_id = deaccession.transaction_id
										WHERE 
											deacc_item.transaction_id <> <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#transaction_id#">
											AND deacc_item.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#getParts.part_id#">
									</cfquery>

									<div class="col-12 row mx-0 py-1 border-top border-secondary">
										<div class="col-12 col-md-3">
											<input type="hidden" name="part_name_#part_id#" id="part_name_#part_id#" value="#getParts.part_name# (#getParts.preserve_method#)">
											<span>
												#getParts.part_name# (#getParts.preserve_method#) #getParts.lot_count_modifier#&nbsp;#getParts.lot_count#
											</span>
											<cfif len(partRemarks) GT 0>
												<br>#partRemarks#
											</cfif>
										</div>
										<div class="col-12 col-md-3">
											<label class="data_entry_label" for="item_instructions_#part_id#">Item Instructions</label>
											<input type="text" name="item_instructions" id="item_instructions_#part_id#" class="data-entry-input" value="#item_instructions#">
										</div>
										<div class="col-12 col-md-3">
											<label class="data_entry_label" for="deacc_item_remarks_#part_id#">Item Remarks</label>
											<input type="text" name="deacc_item_remarks" id="deacc_item_remarks_#part_id#" class="data-entry-input" value="#deacc_item_remarks#">
										</div>
										<div class="col-12 col-md-2">
											<label class="data_entry_label" for="coll_obj_disposition_#part_id#">Disposition</label>
											<select name="coll_obj_disposition" id="coll_obj_disposition_#part_id#" class="data-entry-select">
												<cfloop query="ctcoll_obj_disp">
													<cfif ctcoll_obj_disp.coll_obj_disposition EQ getParts.coll_obj_disposition>
														<cfset selected = "selected">
													<cfelse>
														<cfset selected = "">
													</cfif>
													<option value="#ctcoll_obj_disp.coll_obj_disposition#" #selected#>#ctcoll_obj_disp.coll_obj_disposition#</option>
												</cfloop>
											</select>
										</div>
										<div class="col-12 col-md-1">
											<button class="btn btn-xs btn-primary addpartbutton"
												onClick="addPartToDeaccession(#part_id#);" 
												name="add_part_#part_id#" id="add_part_#part_id#">Add</button>
											<cfif checkPartInDeacc.recordcount GT 0>
												<cfset deacc_item_id = "#checkPartInDeacc.deacc_item_id#">
											<cfelse>
												<cfset deacc_item_id = "">
											</cfif>
											<input type="hidden" name="deacc_item_id_#part_id#" id="deacc_item_id_#part_id#" value="#deacc_item_id#">
											<button class="btn btn-xs btn-primary editpartbutton" style="display: none;"
												onClick="launchDeaccEditDialog(#part_id#);" 
												name="edit_part_#part_id#" id="edit_part_#part_id#">Edit</button>
											<output id="output#part_id#">
												<cfif checkPartInDeacc.recordcount GT 0>
													In this deaccession.
													<script>
														$(document).ready(function() { 
															$("##add_part_#part_id#").hide();
															$("##edit_part_#part_id#").show();
															$("##item_instructions_#part_id#").prop("disabled",true).addClass("disabled");
															$("##deacc_item_remarks_#part_id#").prop("disabled",true).addClass("disabled");
															$("##coll_obj_disposition_#part_id#").prop("disabled",true).addClass("disabled");
														});
													</script>
												</cfif>
											</output>
										</div>

										<!--- Warnings if in other deaccessions or unusual disposition --->
										<cfif checkPartInOtherDeacc.recordcount GT 0>
											<div class="col-12">
												<ul class="mb-1">
													<cfloop query="checkPartInOtherDeacc">
														<li>
															<span class="text-danger font-weight-bold">Note:</span> This part is in deaccession 
															<a href="/transactions/Deaccession.cfm?action=edit&transaction_id=#checkPartInOtherDeacc.transaction_id#">
																#checkPartInOtherDeacc.deacc_number#
															</a>.
														</li>
													</cfloop>
												</ul>
											</div>
										</cfif>

										<cfif getParts.coll_obj_disposition contains "on loan">
											<div class="col-12">
												<ul class="mb-1">
													<li>
														<span class="text-danger font-weight-bold">
															This part is currently on loan (disposition: #getParts.coll_obj_disposition#) and may not be available for deaccession.
														</span>
													</li>
												</ul>
											</div>
										</cfif>
									</div>
								</cfloop>
							</div>
						</cfloop>

						<div id="editItemDialogDiv"></div>

						<script>
							function launchDeaccEditDialog(part_id) { 
								var deacc_item_id = $("##deacc_item_id_"+part_id).val();
								var part_name = $("##part_name_"+part_id).val();
								if (typeof openDeaccessionItemDialog === "function") {
									openDeaccessionItemDialog(deacc_item_id,"editItemDialogDiv",part_name,null);
								} else {
									messageDialog("Edit dialog for deaccession items is not implemented.","Not Implemented");
								}
							}

							function addPartToDeaccession(part_id) { 
								// get values from inputs for this part
								var transaction_id = $("##deacc_transaction_id").val();
								var remark = $("##deacc_item_remarks_"+part_id).val();
								var instructions = $("##item_instructions_"+part_id).val();
								var common_instructions = $("##common_instruction_text").val(); 
								var common_remarks = $("##common_remarks_text").val(); 
								var common_disposition = $("##common_disposition").val();
								var coll_obj_disposition = $("##coll_obj_disposition_"+part_id).val(),

								// append common instructions, if not already present
								if (common_instructions.length > 0) {
									if (!instructions.includes(common_instructions)) { 
										if (instructions.length > 0) { 
											instructions = instructions + "; " + common_instructions;
										} else {
											instructions = common_instructions;
										}
										$("##item_instructions_"+part_id).val(instructions);
									} 
								}

								// append common remarks, if any and not already present
								if (common_remarks.length > 0) {
									if (remark.length > 0) {
										remark = remark + "; " + common_remarks;
									} else {
										remark = common_remarks;
									}
									$("##deacc_item_remarks_"+part_id).val(remark);
								}
	
								// set common disposition, if any
								if (common_disposition.length > 0) {
									coll_obj_disposition = common_disposition;
									$("##coll_obj_disposition_"+part_id).val(coll_obj_disposition);
								}

								$("##output"+part_id).html("Saving...");
								jQuery.ajax({
									url: "/transactions/component/itemFunctions.cfc",
									data : {
										method : "addPartToDeaccession",
										transaction_id: transaction_id,
										part_id: part_id,
										remark: remark,
										instructions: instructions,
										coll_obj_disposition: coll_obj_disposition, 
										returnformat : "json",
										queryformat : "column"
									},
									success: function (result) {
										if (typeof result == "string") { result = JSON.parse(result); } 
										if (result.DATA.STATUS[0]==1) {
											deaccessionModifiedHere();
											$("##output"+part_id).html(result.DATA.MESSAGE[0]);
											// Obtain deacc_item_id from result and save where Edit button can use it.
											if (result.DATA.DEACC_ITEM_ID && result.DATA.DEACC_ITEM_ID.length > 0) {
												$("##deacc_item_id_"+part_id).val(result.DATA.DEACC_ITEM_ID[0]);
											}
											// Lock controls, part added.
											$("##add_part_"+part_id).hide();
											$("##edit_part_"+part_id).show();
											$("##item_instructions_"+part_id).prop("disabled",true).addClass("disabled");
											$("##deacc_item_remarks_"+part_id).prop("disabled",true).addClass("disabled");
											$("##coll_obj_disposition_"+part_id).prop("disabled",true).addClass("disabled");
										} else { 
											$("##output"+part_id).html("Error");
										}
									},
									error: function (jqXHR, textStatus, error) {
										$("##output"+part_id).html("Error");
										handleFail(jqXHR,textStatus,error,"adding a part to a deaccession");
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
