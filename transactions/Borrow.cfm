<cfset pageTitle = "Borrow Management">
<cfif isdefined("action") AND action EQ 'new'>
	<cfset pageTitle = "Create New Borrow">
</cfif>
<cfif isdefined("action") AND action EQ 'edit'>
	<cfset pageTitle = "Edit Borrow">
	<cfif isdefined("transaction_id") >
		<cfquery name="borrowNumber" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select
				borrow_number
			from
				borrow
			where
				borrow.transaction_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
		</cfquery>
		<cfset pageTitle = "Edit Borrow #borrowNumber.borrow_number#">
	</cfif>
</cfif>
<cfset MAGIC_MCZ_COLLECTION = 12>
<cfset MAGIC_MCZ_CRYO = 11>
<cfset BORROWNUMBERPATTERN = '^B[12][0-9]{3}-[-0-9a-zA-Z]+-[A-Z][a-zA-Z]+$'>
<!--
transactions/Borrow.cfm

Copyright 2008-2017 Contributors to Arctos
Copyright 2008-2021 President and Fellows of Harvard College

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

-->
<cfif not isdefined('action') OR action is "nothing">
	<!--- redirect to borrow search page --->
	<cflocation url="/Transactions.cfm?action=findBorrows" addtoken="false">
</cfif>
<!-------------------------------------------------------------------------------------------------->
<cfinclude template = "/shared/_header.cfm">

<cfif not isdefined("project_id")>
	<cfset project_id = -1>
</cfif>

<!--- Borrow controlled vocabularies --->
<cfquery name="ctBorrowStatus" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select borrow_status from ctborrow_status order by borrow_status
</cfquery>
<cfquery name="ctcollection" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select COLLECTION_CDE, INSTITUTION_ACRONYM, DESCR, COLLECTION, COLLECTION_ID, WEB_LINK,
		WEB_LINK_TEXT, CATNUM_PREF_FG, CATNUM_SUFF_FG, GENBANK_PRID, GENBANK_USERNAME,
		GENBANK_PWD, LOAN_POLICY_URL, ALLOW_PREFIX_SUFFIX, GUID_PREFIX, INSTITUTION 
	from collection order by collection
</cfquery>
<!--- Obtain list of transaction agent roles relevant to borrows --->
<cfquery name="cttrans_agent_role" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select distinct(cttrans_agent_role.trans_agent_role) 
	from cttrans_agent_role
		left join trans_agent_role_allowed on cttrans_agent_role.trans_agent_role = trans_agent_role_allowed.trans_agent_role
	where 
		trans_agent_role_allowed.transaction_type = 'Borrow'
	order by cttrans_agent_role.trans_agent_role
</cfquery>

<cfoutput>
	<script language="javascript" type="text/javascript">
		// setup date pickers
		jQuery(document).ready(function() {
			$("##trans_date").datepicker({ dateFormat: 'yy-mm-dd'});
			$("##received_date").datepicker({ dateFormat: 'yy-mm-dd'});
			$("##due_date").datepicker({ dateFormat: 'yy-mm-dd'});
			$("##lenders_loan_date").datepicker({ dateFormat: 'yy-mm-dd'});
		});
	</script>
</cfoutput>
<!-------------------------------------------------------------------------------------------------->
<cfif action is "new">
	<cfset title="New Borrow">
	<cfoutput>
		<main class="container py-3" id="content">
			<h1 class="h2" id="newBorrowFormSectionLabel" >Create New Borrow <i class="fas fa-info-circle" onClick="getMCZDocs('Borrow)" aria-label="help link"></i></h1>
			<div class="row border rounded bg-light mt-2 mb-4 p-2">
				<section class="col-12" title="next available borrow number"> 
					<script>
						function setDeaccNum(cid,borrowNum) {
							$("##borrow_number").val(borrowNum);
							$("##collection_id").val(cid);
							$("##collection_id").change();
						}
					</script>
					<div id="nextNumDiv">
						<h2 class="h4 mx-2 mb-1" id="nextNumberSectionLabel" title="Click on a collection button and the next available borrow number in the database for that collection will be entered">Next Available Borrow Number:</h2>
						<!--- Find list of all collections --->
						<cfquery name="allCollections" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							select collection_id, collection_cde, collection from collection 
							order by collection 
						</cfquery>
						<div class="flex-row float-left mb-1">
						<cfloop query="allCollections">
							<cftry>
								<!---- Borrow numbers follow Dyyyy-n-CCDE format, obtain highest n for current year for each collection. --->
								<cfquery name="nextNumberQuery" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
									select
									'B#dateformat(now(),"yyyy")#-' || nvl( max(to_number(substr(borrow_number,instr(borrow_number,'-')+1,instr(borrow_number,'-',1,2)-instr(borrow_number,'-')-1) + 1)) , 1) || '-#collection_cde#' as nextNumber
									from
										borrow,
										trans,
										collection
									where
										borrow.transaction_id=trans.transaction_id 
										AND trans.collection_id=collection.collection_id
										AND collection.collection_id = <cfqueryparam value="#collection_id#" cfsqltype="CF_SQL_DECIMAL">
										AND substr(borrow_number, 2,4) ='#dateformat(now(),"yyyy")#'
								</cfquery>
							<cfcatch>
								<hr>
								#cfcatch.detail#<br>
								#cfcatch.message# 
								<!--- Put an error message into nextNumberQuery.nextNumber --->
								<cfquery name="nextNumberQuery" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
									select 'check data' as nextNumber from dual
								</cfquery>
							</cfcatch>
							</cftry>
							<cfif len(nextNumberQuery.nextNumber) gt 0>
								<button type="button" class="btn btn-xs btn-outline-primary float-left mx-1 pt-1 mb-2 px-2 w-auto text-left" onclick="setDeaccNum('#collection_id#','#nextNumberQuery.nextNumber#')">#collection# #nextNumberQuery.nextNumber#</button>
							<cfelse>
								<span style="font-size:x-small"> No data available for #collection#. </span>
							</cfif>
						</cfloop>
						</div>
					</div>
				</section><!--- next number section --->
				<section class="col-12 border bg-white pt-3" id="newBorrowFormSection" aria-label="Form to create new borrow">
					<form name="newBorrow" id="newBorrow" class="" action="/transactions/Borrow.cfm" method="post" onSubmit="return noenter();">
						<input type="hidden" name="action" value="makeBorrow">
						<div class="form-row mb-2">
							<div class="col-12 col-md-3">
								<label for="collection_id" class="data-entry-label">Collection</label>
								<select name="collection_id" size="1" id="collection_id" class="reqdClr data-entry-select" required >
									<option value=""></option>
									<cfloop query="ctcollection">
										<option value="#ctcollection.collection_id#">#ctcollection.collection#</option>
									</cfloop>
								</select>
							</div>
							<div class="col-12 col-md-3">
								<label for="borrow_number" class="data-entry-label">Borrow Number (Byyyy-n-Coll)</label>
								<input type="text" name="borrow_number" class="reqdClr data-entry-input" id="borrow_number" required pattern="#BORROWNUMBERPATTERN#">
							</div>
							<div class="col-12 col-md-3">
								<label for="status" class="data-entry-label">Status</label>
								<select name="borrow_status" id="status" class="reqdClr data-entry-select" required >
									<cfloop query="ctBorrowStatus">
											<cfif #ctBorrowStatus.borrow_status# is "in process">
												<cfset selected = "selected='selected'">
											<cfelse>
												<cfset selected="">
											</cfif>
											<option value="#ctBorrowStatus.borrow_status#" #selected# >#ctBorrowStatus.borrow_status#</option>
									</cfloop>
								</select>
							</div>
							<div class="col-12 col-md-3">
								<label for="lenders_trans_num_cde" class="data-entry-label">Lender's Loan Number</label>
								<input type="text" name="lenders_trans_num_cde" id="lenders_trans_num_cde" class="data-entry-input" >
							</div>
						</div>
						<div class="form-row mb-2">
							<div class="col-12 col-md-3">
								<label for="lender_loan_type" class="data-entry-label">Lender's Loan Type</label>
								<input type="text" name="lender_loan_type" id="lender_loan_type" class="data-entry-input" >
							</div>
							<div class="col-12 col-md-3">
								<label for="lenders_loan_date" class="data-entry-label">Lender's Loan Date</label>
								<input type="text" name="lenders_loan_date" id="lenders_loan_date" class="data-entry-input">
							</div>
							<div class="col-12 col-md-3">
								<label for="no_of_specimens" class="data-entry-label">Total No. of Specimens</label>
								<input type="text" name="no_of_specimens" id="no_of_specimens" class="reqdClr data-entry-input" required>
							</div>
							<div class="col-12 col-md-3">
								<label for="return_acknowledged" class="data-entry-label">Lender acknowledged as returned?</label>
								<select name="LENDERS_INVOICE_RETURNED_FG" id="return_acknowledged" size="1" class="data-entry-select">
									<option value="0" selected="selected">no</option>
									<option value="1">yes</option>
								</select>
							</div>
						</div>
						<div class="form-row mb-2">
							<div class="col-12 col-md-4">
								<label for="due_date" class="data-entry-label">Due Date</label>
								<input type="text" name="due_date" id="due_date" class="w-100 data-entry-input">
							</div>
							<div class="col-12 col-md-4">
								<label for="received_date" class="data-entry-label">Received Date</label>
								<input type="text" name="received_date" id="received_date" class="w-100 data-entry-input">
							</div>
							<div class="col-12 col-md-4">
								<label for="trans_date" class="data-entry-label">Transaction Date</label>
								<input type="text" name="trans_date" id="trans_date" 
									required
									value="#dateformat(now(),"yyyy-mm-dd")#" 
									class="reqdClr w-100 data-entry-input">
							</div>
						</div>
						<div class="form-row mb-2">
							<div class="col-12 col-md-4">
								<span>
									<label for="auth_agent" class="data-entry-label">
										Outside authorized by:
										<span id="auth_agent_view">&nbsp;&nbsp;&nbsp;&nbsp;</span>
									</label>
								</span>
								<div class="input-group">
									<div class="input-group-prepend">
										<span class="input-group-text smaller bg-lightgreen" id="auth_agent_icon"><i class="fa fa-user" aria-hidden="true"></i></span> 
									</div>
									<input name="auth_agent_name" id="auth_agent_name" class="form-control form-control-sm data-entry-input" >
								</div>
								<input type="hidden" name="auth_agent_id" id="auth_agent_id" >
								<script>
									$(makeRichTransAgentPicker('auth_agent_name', 'auth_agent_id','auth_agent_icon','auth_agent_view',null))
								</script> 
							</div>
							<div class="col-12 col-md-4">
								<span>
									<label for="overseenby_agent_name" class="data-entry-label">
										Borrow Overseen By (MCZ):
										<span id="overseenby_agent_view">&nbsp;&nbsp;&nbsp;&nbsp;</span>
									</label>
								</span>
								<div class="input-group">
									<div class="input-group-prepend">
										<span class="input-group-text smaller bg-lightgreen" id="overseenby_agent_icon"><i class="fa fa-user" aria-hidden="true"></i></span> 
									</div>
									<input name="overseenby_agent_name" id="overseenby_agent_name" required class="form-control form-control-sm data-entry-input reqdClr" >
								</div>
								<input type="hidden" name="over_agent_id" id="over_agent_id" >
								<script>
									$(makeRichTransAgentPicker('overseenby_agent_name','over_agent_id','overseenby_agent_icon','overseenby_agent_view',null));
								</script> 
							</div>
							<div class="col-12 col-md-4">
								<span>
									<label for="received_agent_name" class="data-entry-label">
										Received By:
										<span id="received_agent_view">&nbsp;&nbsp;&nbsp;&nbsp;</span>
									</label>
								</span>
								<div class="input-group">
									<div class="input-group-prepend">
										<span class="input-group-text smaller bg-lightgreen" id="received_agent_icon"><i class="fa fa-user" aria-hidden="true"></i></span> 
									</div>
									<input name="received_agent_name" id="received_agent_name" required class="form-control form-control-sm data-entry-input reqdClr" >
								</div>
								<input type="hidden" name="received_agent_id" id="received_agent_id" >
								<script>
									$(makeRichTransAgentPicker('received_agent_name','received_agent_id','received_agent_icon','received_agent_view',null));
								</script> 
							</div>
						</div>
						<div class="form-row mb-2">
							<div class="col-12 col-md-4">
								<span>
									<label for="received_from_agent_name" class="data-entry-label">
										Received From:
										<span id="received_from_agent_view">&nbsp;&nbsp;&nbsp;&nbsp;</span>
									</label>
								</span>
								<div class="input-group">
									<div class="input-group-prepend">
										<span class="input-group-text smaller bg-lightgreen" id="received_from_agent_icon"><i class="fa fa-user" aria-hidden="true"></i></span> 
									</div>
									<input name="received_from_agent_name" id="received_from_agent_name" required class="form-control form-control-sm data-entry-input reqdClr" >
								</div>
								<input type="hidden" name="received_from_agent_id" id="received_from_agent_id" >
								<script>
									$(makeRichTransAgentPicker('received_from_agent_name','received_from_agent_id','received_from_agent_icon','received_from_agent_view',null));
								</script> 
							</div>
							<div class="col-12 col-md-4">
								<span>
									<label for="lending_institution_agent_name" class="data-entry-label">
										Lending Institution:
										<span id="lending_institution_agent_view">&nbsp;&nbsp;&nbsp;&nbsp;</span> 
									</label>
								</span>
								<div class="input-group">
									<div class="input-group-prepend">
										<span class="input-group-text smaller bg-lightgreen" id="lending_institution_agent_icon"><i class="fa fa-user" aria-hidden="true"></i></span> 
									</div>
									<input type="text" name="lending_institution_agent_name" id="lending_institution_agent_name" class="reqdClr form-control form-control-sm data-entry-input" required>
								</div>
								<input type="hidden" name="lending_institution_agent_id" id="lending_institution_agent_id" >
								<script>
									$(makeRichTransAgentPicker('lending_institution_agent_name','lending_institution_agent_id','lending_institution_agent_icon','lending_institution_agent_view',null));
								</script> 
							</div>
							<div class="col-12 col-md-4">
								<span>
									<label for="inhouse_contact_agent_name" class="data-entry-label">
										In-house Contact:
										<span id="inhouse_contact_agent_view">&nbsp;&nbsp;&nbsp;&nbsp;</span> 
									</label>
								</span>
								<div class="input-group">
									<div class="input-group-prepend">
										<span class="input-group-text smaller bg-lightgreen" id="inhouse_contact_agent_icon"><i class="fa fa-user" aria-hidden="true"></i></span> 
									</div>
									<input type="text" name="inhouse_contact_agent_name" id="inhouse_contact_agent_name" class="form-control form-control-sm data-entry-input reqdClr" required>
								</div>
								<input type="hidden" name="inhouse_contact_agent_id" id="inhouse_contact_agent_id" >
								<script>
									$(makeRichTransAgentPicker('inhouse_contact_agent_name','inhouse_contact_agent_id','inhouse_contact_agent_icon','inhouse_contact_agent_view',null));
								</script> 
							</div>
						</div>
						<div class="form-row mb-2">
							<div class="col-12 col-md-4">
								<span>
									<label for="outside_contact_agent_name" class="data-entry-label">
										Outside Contact:
										<span id="outside_contact_agent_view">&nbsp;&nbsp;&nbsp;&nbsp;</span>
									</label>
								</span>
								<div class="input-group">
									<div class="input-group-prepend">
										<span class="input-group-text smaller bg-lightgreen" id="outside_contact_agent_icon"><i class="fa fa-user" aria-hidden="true"></i></span> 
									</div>
									<input name="outside_contact_agent_name" id="outside_contact_agent_name" class="form-control form-control-sm data-entry-input" >
								</div>
								<input type="hidden" name="outside_contact_agent_id" id="outside_contact_agent_id" >
								<script>
									$(makeRichTransAgentPicker('outside_contact_agent_name','outside_contact_agent_id','outside_contact_agent_icon','outside_contact_agent_view',null));
								</script> 
							</div>
							<div class="col-12 col-md-4">
								<span>
									<label for="additional_out_contact_agent_name" class="data-entry-label">
										Additional Outside Contact:
										<span id="additional_out_contact_agent_view">&nbsp;&nbsp;&nbsp;&nbsp;</span>
									</label>
								</span>
								<div class="input-group">
									<div class="input-group-prepend">
										<span class="input-group-text smaller bg-lightgreen" id="additional_out_contact_agent_icon"><i class="fa fa-user" aria-hidden="true"></i></span> 
									</div>
									<input name="additional_out_contact_agent_name" id="additional_out_contact_agent_name" class="form-control form-control-sm data-entry-input" >
								</div>
								<input type="hidden" name="additional_out_contact_agent_id" id="additional_out_contact_agent_id" >
								<script>
									$(makeRichTransAgentPicker('additional_out_contact_agent_name','additional_out_contact_agent_id','additional_out_contact_agent_icon','additional_out_contact_agent_view',null));
								</script> 
							</div>
							<div class="col-12 col-md-4">
								<span>
									<label for="for_use_by_agent_name" class="data-entry-label">
										Received From:
										<span id="for_use_by_agent_view">&nbsp;&nbsp;&nbsp;&nbsp;</span>
									</label>
								</span>
								<div class="input-group">
									<div class="input-group-prepend">
										<span class="input-group-text smaller bg-lightgreen" id="for_use_by_agent_icon"><i class="fa fa-user" aria-hidden="true"></i></span> 
									</div>
									<input name="for_use_by_agent_name" id="for_use_by_agent_name" class="form-control form-control-sm data-entry-input" >
								</div>
								<input type="hidden" name="for_use_by_agent_id" id="for_use_by_agent_id" >
								<script>
									$(makeRichTransAgentPicker('for_use_by_agent_name','for_use_by_agent_id','for_use_by_agent_icon','for_use_by_agent_view',null));
								</script> 
							</div>
						</div>
						<div class="form-row mb-2">
							<div class="col-12 col-md-12">
								<label for="lenders_instructions" class="data-entry-label">Lender's Instructions (<span id="length_lenders_instructions"></span>)</label>
								<textarea name="lenders_instructions" id="lenders_instructions" rows="2" 
									onkeyup="countCharsLeft('lenders_instructions', 4000, 'length_lenders_instructions');"
									class="data-entry-textarea autogrow" 
									></textarea>
							</div>
						</div>
						<div class="form-row mb-2">
							<div class="col-12 col-md-12">
								<label for="nature_of_material" class="data-entry-label">Nature of Material (<span id="length_nature_of_material"></span>)</label>
								<textarea name="nature_of_material" id="nature_of_material" rows="2" 
									onkeyup="countCharsLeft('nature_of_material', 4000, 'length_nature_of_material');"
									class="reqdClr data-entry-textarea autogrow" 
									required ></textarea>
							</div>
						</div>
						<div class="form-row mb-2">
							<div class="col-12 col-md-12">
								<label for="description_of_borrow" class="data-entry-label">Description of Borrow (<span id="length_description_of_borrow"></span>)</label>
								<textarea name="description_of_borrow" id="description_of_borrow" rows="2" 
									onkeyup="countCharsLeft('description_of_borrow', 4000, 'length_description_of_borrow');"
									class="reqdClr data-entry-textarea autogrow" 
									required ></textarea>
							</div>
						</div>
						<div class="form-row mb-2">
							<div class="col-12 col-md-12">
								<label for="trans_remarks" class="data-entry-label">Internal Remarks (<span id="length_trans_remarks"></span>)</label>
								<textarea name="trans_remarks" id="trans_remarks" 
									onkeyup="countCharsLeft('trans_remarks', 4000, 'length_trans_remarks');"
									class="data-entry-textarea autogrow" 
									rows="2"></textarea>
							</div>
						</div>
						<script>
							// Make all textareas with autogrow class be bound to the autogrow function on key up
							$(document).ready(function() { 
								$("textarea.autogrow").keyup(autogrow);
								$('textarea.autogrow').keyup();
							});
						</script>
						<div class="form-row my-2">
							<div class="form-group col-12">
								<input type="button" value="Create Borrow" class="btn mt-2 btn-xs btn-primary"
									onClick="if (checkFormValidity($('##newBorrow')[0])) { submit(); } ">
							</div>
						</div>
					</form>
					<!--- Set initial state for new borrow --->
					<script>
					</script>
					<!--- handlers for various change events --->
					<script>
					</script>
				</section>
			</div>
		</main>
	</cfoutput>
</cfif>
<!-------------------------------------------------------------------------------------------------->
<cfif action is "edit">
	<cfset title="Edit Borrow">
	<!--- Include the template that contains functions used to load portions of this page --->
	<cfinclude template="/transactions/component/functions.cfc" runOnce="true">
	<cfinclude template="/transactions/component/borrowFunctions.cfc" runOnce="true">
	
	<cfif not isdefined("transaction_id") or len(transaction_id) EQ 0>
		<cfthrow message="Edit Borrow called without a transaction_id for the borrow to be edited">
	</cfif>
	<cfoutput>
		<script>
			function addMediaHere(targetid,title,relationLabel,transaction_id,relationship){
				console.log(targetid);
				var url = '/media.cfm?action=newMedia&relationship='+relationship+'&related_value='+relationLabel+'&related_id='+transaction_id ;
				var amddialog = $('##'+targetid)
					.html('<iframe style="border: 0px; " src="'+url+'" width="100%" height="100%" id="mediaIframe"></iframe>')
					.dialog({
						title: title,
						autoOpen: false,
						dialogClass: 'dialog_fixed,ui-widget-header',
						modal: true,
						height: 900,
						width: 1100,
						minWidth: 400,
						minHeight: 400,
						draggable:true,
						buttons: {
							"Ok": function () { 
								loadTransactionFormMedia(#transaction_id#,"borrow"); 
								$(this).dialog("close"); 
							} 
						}
					});
				amddialog.dialog('open');
				console.log(transaction_id);
				console.log(relationship);
		 	};
		</script>
		<cftry>
			<cfquery name="borrowDetails" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="borrowDetails_result">
				select
					trans.transaction_id,
					trans.transaction_type,
					trans_date dateEntered,
					borrow_number,
					borrow_status,
					trans_date,
					received_date,
					due_date,
					lenders_loan_date,
					nature_of_material,
					description_of_borrow,
					lenders_trans_num_cde,
					lender_loan_type,
					lenders_instructions,
					lenders_invoice_returned_fg,
					no_of_specimens,
					trans_remarks,
					trans.collection_id,
					collection.collection,
					concattransagent(trans.transaction_id,'entered by') enteredby,
					return_acknowledged_date,
					ret_acknowledged_by
				 from
					trans
					left join borrow on trans.transaction_id = borrow.transaction_id 
					left join collection on trans.collection_id=collection.collection_id 
				where
					trans.transaction_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
			</cfquery>
			<cfif borrowDetails.RecordCount EQ 0 >
				<cfthrow message = "No such Borrow.">
			</cfif>
			<cfif borrowDetails.RecordCount GT 0 AND borrowDetails.transaction_type NEQ 'borrow'>
				<cfthrow message = "Request to edit an borrow, but the provided transaction_id was for a different transaction type [#borrowDetails.transaction_type#].">
			</cfif>
			<cfquery name="transAgents" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select
					trans_agent_id,
					trans_agent.agent_id,
					agent_name,
					trans_agent_role,
					MCZBASE.get_worstagentrank(trans_agent.agent_id) worstagentrank
				from
					trans_agent,
					preferred_agent_name
				where
					trans_agent.agent_id = preferred_agent_name.agent_id and
					trans_agent_role != 'entered by' and
					trans_agent.transaction_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
				order by
					trans_agent_role,
					agent_name
			</cfquery>
			<script>
				$(function() {
					// on page load, hide the create project from borrow fields
					$("##create_project").hide();
					$("##saveNewProject").change( function () {
						if ($("##saveNewProject").is(":checked")) {
							$("##create_project").show();
						} else {
							$("##create_project").hide();
						}
					});
				});
			</script>
		<cfcatch>
			<!--- Report any exceptions thrown in setting up the page --->
			<h2>Error: #cfcatch.message#</h2>
			<cfif cfcatch.detail NEQ ''>#cfcatch.detail#</cfif>
			<cfabort>
			<!--- Stop processing page, don't display form with data --->
		</cfcatch>
		</cftry>
		<!--- Note cftry-cfcatch block embeded below within the container div to avoid breaking page layout on failure. --->
		
		<main class="container py-3" id="content" title="Edit Borrow Form Content">
			<cftry>
				<h1 class="h2 pb-0 ml-3">Edit Borrow
					<strong>#borrowDetails.collection# #borrowDetails.borrow_number#</strong> 
					<i class="fas fa-info-circle" onClick="getMCZDocs('Borrow_Field_Definitions')" aria-label="help link"></i>
				</h1>
				<section class="row mx-0 border rounded my-2 pt-2" title="Edit Borrow Details" >
					<form class="col-12" name="editBorrowForm" id="editBorrowForm" action="/transactions/Borrow.cfm" method="post" onSubmit="return noenter();">
						<input type="hidden" name="method" value="saveBorrow"><!--- used in normal ajax save, which uses the form fields to post to transactions/component/functions.cfc --->
						<input id="action" type="hidden" name="action" value="edit"><!--- reused by delete borrow, not used in normal save --->
						<input type="hidden" name="transaction_id" value="#borrowDetails.transaction_id#">
						<!--- function handleChange: action to take when an input has its value changed, binding to inputs below and on load of agent inputs in table --->
						<script>
							function handleChange(){
								$('##saveResultDiv').html('Unsaved changes.');
								$('##saveResultDiv').addClass('text-danger');
								$('##saveResultDiv').removeClass('text-success');
								$('##saveResultDiv').removeClass('text-warning');
							};
						</script>
						
						<div class="form-row mb-1">
							<div class="col-12 col-md-3">
								<label class="data-entry-label" for="collection_id">Department</label>
								<select name="collection_id" id="collection_id" size="1" class="reqdClr data-entry-select" required >
									<cfloop query="ctcollection">
										<option <cfif ctcollection.collection_id is borrowDetails.collection_id> selected </cfif>
											value="#ctcollection.collection_id#">#ctcollection.collection#</option>
									</cfloop>
								</select>
							</div>
							<div class="col-12 col-md-3">
								<label for="borrow_number" class="data-entry-label">MCZ Borrow Number (Byyyy-n-Dept)</label>
								<input type="text" name="borrow_number" id="borrow_number" value="#encodeForHTML(borrowDetails.borrow_number)#" class="reqdClr data-entry-input" 
									required pattern="#BORROWNUMBERPATTERN#" >
							</div>
							<div class="col-12 col-md-3">
								<label for="lenders_trans_num_cde" class="data-entry-label">Lender's Loan Number</label>
								<input type="text" name="lenders_trans_num_cde" id="lenders_trans_num_cde" class="data-entry-input" value="#encodeForHTML(borrowDetails.lenders_trans_num_cde)#">
							</div>
							<div class="col-12 col-md-3">
								<label for="borrow_status" class="data-entry-label">Borrow Status</label>
								<span>
									<select name="borrow_status" id="borrow_status" class="reqdClr data-entry-select" required >
										<cfloop query="ctBorrowStatus">
											<option <cfif ctBorrowStatus.borrow_status is borrowDetails.borrow_status> selected="selected" </cfif>
												value="#ctBorrowStatus.borrow_status#">#ctBorrowStatus.borrow_status#</option>
										</cfloop>
									</select>
								</span>
							</div>
						</div>
						<div class="form-row mb-2">
							<div class="col-12 col-md-3">
								<label for="lender_loan_type" class="data-entry-label">Lender's Loan Type</label>
								<input type="text" name="lender_loan_type" id="lender_loan_type" class="data-entry-input" value="#encodeForHTML(borrowDetails.lender_loan_type)#">
							</div>
							<div class="col-12 col-md-3">
								<label for="no_of_specimens" class="data-entry-label">Total No. of Specimens</label>
								<input type="text" name="no_of_specimens" id="no_of_specimens" class="data-entry-input" value="#encodeForHTML(borrowDetails.no_of_specimens)#">
							</div>
							<div class="col-12 col-md-3">
								<span class="data-entry-label">Date Entered</span>
								<div class="col-12 bg-light border non-field-text">
									<span id="date_entered">#dateformat(borrowDetails.dateEntered,'yyyy-mm-dd')#</span>
								</div>
							</div>
							<div class="col-12 col-md-3">
								<span class="data-entry-label">Entered By</span>
								<div class="col-12 bg-light: border non-field-text">
									<span id="entered_by">#encodeForHTML(borrowDetails.enteredby)#</span>
								</div>
							</div>
						</div>
						<div class="form-row mb-1">
							<div class="col-12 col-md-3">
								<label for="lenders_loan_date" class="data-entry-label">Lender's Loan Date</label>
								<input type="text" name="lenders_loan_date" id="lenders_loan_date" 
									value="#dateformat(borrowDetails.lenders_loan_date,"yyyy-mm-dd")#" class="data-entry-input" >
							</div>
							<div class="col-12 col-md-3">
								<label for="due_date" class="data-entry-label">Due Date</label>
								<input type="text" name="due_date" id="due_date"
									value="#dateformat(borrowDetails.due_date,"yyyy-mm-dd")#" class="reqdClr data-entry-input" >
							</div>
							<div class="col-12 col-md-3">
								<label for="return_acknowledged" class="data-entry-label">Lender acknowledged returned?</label>
								<cfif borrowDetails.lenders_invoice_returned_fg EQ 1 >
									<cfset selected0 = "">
									<cfset selected1 = "selected='selected'">
								<cfelse>
									<cfset selected0 = "selected='selected'">
									<cfset selected1 = "">
								</cfif>
								<select name="lenders_invoice_returned_fg" id="return_acknowledged" size="1" class="data-entry-select reqdClr" required>
									<option value="0" #selected0#>no</option>
									<option value="1" #selected1#>yes</option>
								</select>
							</div>
							<div class="col-12 col-md-3">
								<label for="return_acknowledged_date" class="data-entry-label">Return Acknowledged Date</label>
								<input type="text" name="return_acknowledged_date" id="return_acknowledged_date" class="data-entry-input" value="#encodeForHTML(borrowDetails.return_acknowledged_date)#">
							</div>
						</div>
						<!--- Begin transaction agents table: Load via ajax. --->
						<div class="form-row my-1">
							<script>
								function reloadTransactionAgents() { 
									loadAgentTable("agentTableContainerDiv",#transaction_id#,"editBorrowForm",handleChange);
								}
							</script>
							<cfset containing_form_id = "editBorrowForm">
							<cfset agentBlock = agentTableHtml("#transaction_id#", "#containing_form_id#")>
							<div class="col-12 mt-1" id="agentTableContainerDiv">
								#agentBlock#
							</div>
							<script>
								$(document).ready(function() { 
									$('##agentTableContainerDiv').on('domChanged',function() {
										console.log("dom change within agentTableContainerDiv");
										monitorForChanges('editBorrowForm',handleChange);
									});
								});
							</script>
						</div>
						<div class="form-row mb-1">
							<div class="col-12">
								<label for="lenders_instructions" class="data-entry-label">Lender's Instructions (<span id="length_lenders_instructions"></span>)</label>
								<textarea type="text" name="lenders_instructions" id="lenders_instructions" 
									onkeyup="countCharsLeft('lenders_instructions', 4000, 'length_lenders_instructions');"
									class="data-entry-input autogrow" >#encodeForHTML(borrowDetails.lenders_instructions)#</textarea>
							</div>
						</div>
						<div class="form-row mb-1">
							<div class="col-12">
								<label for="nature_of_material" class="data-entry-label">Nature of Material (<span id="length_nature_of_material"></span>)</label>
								<textarea name="nature_of_material" id="nature_of_material" rows="1" 
									onkeyup="countCharsLeft('nature_of_material', 4000, 'length_nature_of_material');"
									class="reqdClr autogrow data-entry-textarea" required >#encodeForHtml(borrowDetails.nature_of_material)#</textarea>
							</div>
						</div>
						<div class="form-row mb-1">
							<div class="col-12">
								<label for="description_of_borrow" class="data-entry-label">Description of Borrow (<span id="length_description_of_borrow"></span>)</label>
								<textarea name="description_of_borrow" id="description_of_borrow" rows="1" 
									onkeyup="countCharsLeft('description_of_borrow', 4000, 'length_description_of_borrow');"
									class="reqdClr autogrow data-entry-textarea" required >#encodeForHTML(borrowDetails.description_of_borrow)#</textarea>
							</div>
						</div>
						<div class="form-row mb-1">
							<div class="col-12">
								<label for="trans_remarks" class="data-entry-label">Internal Remarks (<span id="length_trans_remarks"></span>)</label>
								<textarea name="trans_remarks" id="trans_remarks" rows="1"
									onkeyup="countCharsLeft('trans_remarks', 4000, 'length_trans_remarks');"
									class="autogrow data-entry-textarea">#encodeForHTML(borrowDetails.trans_remarks)#</textarea>
							</div>
						</div>
						<script>
							// make selected textareas autogrow as text is entered.
							$(document).ready(function() {
								// bind the autogrow function to the keyup event
								$('textarea.autogrow').keyup(autogrow);
								// trigger keyup event to size textareas to existing text
								$('textarea.autogrow').keyup();
							});
						</script> 
						<div class="form-row mb-1">
							<div class="form-group col-12">
								<input type="button" value="Save" class="btn btn-xs btn-primary mr-2"
									onClick="if (checkFormValidity($('##editBorrowForm')[0])) { saveEdits();  } " 
									id="submitButton" >
								<button type="button" aria-label="Print Borrow Paperwork" id="borrowPrintDialogLauncher"
									class="btn btn-xs btn-info mr-2" value="Print..."
									onClick=" openTransactionPrintDialog(#transaction_id#, 'Borrow', 'borrowPrintDialog');">Print...</button>
								<output id="saveResultDiv" class="text-danger">&nbsp;</output>	
								<input type="button" value="Delete Borrow" class="btn btn-xs btn-danger float-right"
									onClick=" $('##action').val('edit'); confirmDialog('Delete this Borrow?','Confirm Delete Borrow', function() { $('##action').val('deleBorrow'); $('##editBorrowForm').removeAttr('onsubmit'); $('##editBorrowForm').submit(); } );">
							</div>
						</div>
						<div id="borrowPrintDialog"></div>
						<script>
							$(document).ready(function() {
								monitorForChanges('editBorrowForm',handleChange);
							});
							function saveEdits(){ 
								$('##saveResultDiv').html('Saving....');
								$('##saveResultDiv').addClass('text-warning');
								$('##saveResultDiv').removeClass('text-success');
								$('##saveResultDiv').removeClass('text-danger');
								jQuery.ajax({
									url : "/transactions/component/functions.cfc",
									type : "post",
									dataType : "json",
									data : $('##editBorrowForm').serialize(),
									success : function (data) {
										$('##saveResultDiv').html('Saved.');
										$('##saveResultDiv').addClass('text-success');
										$('##saveResultDiv').removeClass('text-danger');
										$('##saveResultDiv').removeClass('text-warning');
										loadAgentTable("agentTableContainerDiv",#transaction_id#,"editBorrowForm",handleChange);
									},
									error: function(jqXHR,textStatus,error){
										$('##saveResultDiv').html('Error.');
										$('##saveResultDiv').addClass('text-danger');
										$('##saveResultDiv').removeClass('text-success');
										$('##saveResultDiv').removeClass('text-warning');
										var message = "";
										if (error == 'timeout') {
											message = ' Server took too long to respond.';
										} else if (error && error.toString().startsWith('Syntax Error: "JSON.parse:')) {
											message = ' Backing method did not return JSON.';
										} else {
											message = jqXHR.responseText;
										}
										messageDialog('Error saving transaction record: '+message, 'Error: '+error.substring(0,50));
									}
								});
							};
						</script>
					</form>
				</section>
				<section name="borrowItemsSection" class="row border rounded mx-0 my-2" title="Collection Objects in this Borrow">
					<div class="col-12 pt-3 pb-1">
						<h3 class="h4">Add Borrowed Item</h3>
						<form id="addBorrowItemform">
							<div class="row">
								<input type="hidden" name="method" value="addBorrowItem">
								<input type="hidden" name="returnformat" value="json">
								<input type="hidden" name="queryformat" value="column">
								<input type="hidden" name="transaction_id" id="transaction_id" value="#transaction_id#">
								<div class="col-12 col-md-1">
									<label for="catalog_number" class="data-entry-label">Catalog Number</label>
									<input type="text" class="data-entry-input" name="catalog_number" id="catalog_number">
								</div>
								<div class="col-12 col-md-2">
									<label for="sci_name" style="width: 190px;margin-right:5px;">Scientific Name</label>
									<input type="text" name="sci_name" id="sci_name" class="data-entry-input">
								</div>
								<div class="col-12 col-md-1">
									<label for="no_of_spec" class="data-entry-label">No.&nbsp;of Specimens</label>
									<input type="text" name="no_of_spec" id="no_of_spec" class="data-entry-input">
								</div>
								<div class="col-12 col-md-2">
									<label for="spec_prep" class="data-entry-label">Specimen Preparation</label>
									<input type="text" name="spec_prep" id="spec_prep" class="data-entry-input">
								</div>
								<div class="col-12 col-md-1">
									<label for="type_status" class="data-entry-label">Type Status</label>
									<input type="text" class="data-entry-input" name="type_status" id="type_status" >
								</div>
								<div class="col-12 col-md-2">
									<label for="country_of_origin" class="data-entry-label">County of Origin</label>
									<input type="text" class="data-entry-input" name="country_of_origin" id="country_of_origin" >
								</div>
								<div class="col-12 col-md-2">
									<label for="object_remarks" class="data-entry-label">Remarks</label>
									<input type="text" class="data-entry-input" name="object_remarks" id="object_remarks" >
								</div>
								<div class="col-12 col-md-1">
									<label class="data-entry-label">&nbsp;</label>
									<button class="btn btn-xs btn-primary" type="button" onclick=" addBorrowItem2();" value="Add Row">Add Row</button>
								</div>
							</div>
						</form>
					</div>
					<!--- TODO: Copy and refactor add item from /Borrow.cfm --->
					<div class="col-12 pt-3 pb-1">
						<!--- TODO: editable borrow item table --->
						<div id="borrowItems"></div>
					</div>
					<div class="col-12 pt-3 pb-1">
						<!--- TODO: Copy and refactor upload csv from /Borrow.cfm --->
						<h4 style="margin-bottom: 0;margin-left: 5px;">Upload Items From CSV File</h4>
						<cfform name="csv" method="post" action="/transactions/Borrow.cfm" enctype="multipart/form-data">
							<input type="hidden" name="action" value="getFile">
							<input type="hidden" name="transaction_id" id="transaction_id" value="#transaction_id#">
							<input type="file"
								name="FiletoUpload"
								size="45">
							<input type="submit" value="Upload this file" >
						</cfform>
					</div>
					<div class="col-12 pt-3 pb-1">
						<p style="margin: 1em 0;"><span class="likeLink" onclick=" toggleTemplate(); " id="toggleLink">View csv file template</span></p>
						<div id="template" style="display:none;">
							<label for="t">Copy the following code and save as a .csv file</label>
							<textarea rows="2" cols="90" id="t">CATALOG_NUMBER,SCI_NAME,NO_OF_SPEC,SPEC_PREP,TYPE_STATUS,COUNTRY_OF_ORIGIN,OBJECT_REMARKS</textarea>
						</div>
						<script>
							function toggleTemplate() {
								$('##template').toggle();
								if ($('##template').is(':visible')) {
									$('##toggleLink').html('Hide csv file temlate');
								} else {
									$('##toggleLink').html('View csv file temlate');
								}
							}
						</script>
					</div>
					<script>
						function addBorrowItem2() {
							jQuery.ajax( {
								url : "/transactions/component/borrowFunctions.cfc",
								type : "post",
								dataType : "json",
								data : $("##addBorrowItemform").serialize(),
								success : function (data) {
									loadBorrowItems(#transaction_id#);
									$("##catalog_number").val('');
									$("##no_of_spec").val('');
									$("##type_status").val('');
								},
								error: function(jqXHR,textStatus,error){
									handleFail(jqXHR,textStatus,error,"adding borrow item");
								}
							});
						};
						function deleteBorrowItem(borrow_item_id) {
							jQuery.ajax({
								url : "/transactions/component/borrowFunctions.cfc",
								type : "post",
								dataType : "json",
								data : {
									method : "deleteBorrowItem",
									returnformat : "json",
									queryformat : 'column',
									borrow_item_id : borrow_item_id
								},
								success : function (data) {
									loadBorrowItems(#transaction_id#);
			 					},
								error: function(jqXHR,textStatus,error){
									handleFail(jqXHR,textStatus,error,"adding borrow item");
								}
							});
						};
						function loadBorrowItems(transaction_id) {
							jQuery.ajax({
								url: "/transactions/component/borrowFunctions.cfc",
								dataType: "html",
								data : {
									method : "getBorrowItemsHTML",
									transaction_id : transaction_id
								},
								success: function (result) {
									$("##borrowItems").html(result);
								},
								error: function(jqXHR,textStatus,error){
									handleFail(jqXHR,textStatus,error,"adding borrow item");
								}
							});
						};
						$(document).ready(loadBorrowItems(#transaction_id#));
					</script>
				</section>
				<!--- TODO: Edtable JQXgrid. --->
				<section class="container-fluid">
					<div class="row">
						<div class="col-12 mb-5">
							<div class="row mt-1 mb-0 pb-0 jqx-widget-header border px-2 mx-0">
							<h1 class="h4">Borrow Items <span class="px-1 font-weight-normal text-success" id="resultCount" tabindex="0"><a class="messageResults" tabindex="0" aria-label="search results"></a></span> </h1><span id="resultLink" class="d-inline-block px-1 pt-2"></span>
								<div id="columnPickDialog">
									<div class="container-fluid">
										<div class="row">
											<div class="col-12 col-md-6">
												<div id="columnPick" class="px-1"></div>
											</div>
											<div class="col-12 col-md-6">
												<div id="columnPick1" class="px-1"></div>
											</div>
										</div>
									</div>
								</div>
								<div id="columnPickDialogButton"></div>
								<div id="resultDownloadButtonContainer"></div>
							</div>
							<div class="row mt-0 mx-0">
								<!--- Grid Related code is below along with search handlers --->
								<div id="searchResultsGrid" class="jqxGrid" role="table" aria-label="Search Results Table"></div>
								<div id="enableselection"></div>
							</div>
						</div>
					</div>
				</section>
				<script>
					$(document).ready(function() {
	
						$("##searchResultsGrid").replaceWith('<div id="searchResultsGrid" class="jqxGrid" style="z-index: 1;"></div>');
						$('##resultCount').html('');
						$('##resultLink').html('');
	
						var search =
							{
							datatype: "json",
							datafields:
								[
								{ name: 'transaction_id', type: 'string' },
								{ name: 'borrow_item_id', type: 'string' },
								{ name: 'catalog_number', type: 'string' },
								{ name: 'sci_name', type: 'string' },
								{ name: 'no_of_spec', type: 'string' },
								{ name: 'spec_prep', type: 'string' },
								{ name: 'type_status', type: 'string' },
								{ name: 'country_of_origin', type: 'string' },
								{ name: 'object_remarks', type: 'string' }
								],
							updaterow: function (rowid, rowdata, commit) {
								var data = "method=updateBorrowItem"
								data = data + "&transaction_id=" + rowdata.transaction_id
								$.ajax({
									dataType: 'json',
									url: '/transactions/component/borrowFunctions.cfc',
									data: data,
										success: function (data, status, xhr) {
										commit(true);
									},
									error: function (jqXHR,textStatus,error) {
										commit(false);
										handleFail(jqXHR,textStatus,error,"saving borrow item");
									}
								});
							},
							root: 'borrowItemRecord',
							id: 'borrow_item_id',
							url: '/transactions/component/borrowFunctions.cfc?method=getBorrowItemsData&transaction_id=#transaction_id#',
							timeout: 30000, // units not specified, miliseconds? 
							loadError: function(jqXHR, textStatus, error) { 
								handleFail(jqXHR,textStatus,error,"loading borrow items");
							},
							async: true
						};
	
						var dataAdapter = new $.jqx.dataAdapter(search);
						var initRowDetails = function (index, parentElement, gridElement, datarecord) {
						// could create a dialog here, but need to locate it later to hide/show it on row details opening/closing and not destroy it.
						var details = $($(parentElement).children()[0]);
						details.html("<div id='rowDetailsTarget" + index + "'></div>");
						createRowDetailsDialog('searchResultsGrid','rowDetailsTarget',datarecord,index);
						// Workaround, expansion sits below row in zindex.
						var maxZIndex = getMaxZIndex();
						$(parentElement).css('z-index',maxZIndex - 1); // will sit just behind dialog
					};
	
					$("##searchResultsGrid").jqxGrid({
						width: '100%',
						autoheight: 'true',
						source: dataAdapter,
						filterable: true,
						sortable: true,
						pageable: true,
						editable: true,
						pagesize: 50,
						pagesizeoptions: ['5','50','100'],
						showaggregates: true,
						columnsresize: true,
						autoshowfiltericon: true,
						autoshowcolumnsmenubutton: false,
						autoshowloadelement: false, // overlay acts as load element for form+results
						columnsreorder: true,
						groupable: true,
						selectionmode: 'singlerow',
						altrows: true,
						showtoolbar: false,
						ready: function () {
							$("##searchResultsGrid").jqxGrid('selectrow', 0);
						},
						columns: [
							{text: 'transactionID', datafield: 'transaction_id', width: 50, hideable: true, hidden: true },
							{text: 'borrowItemID', datafield: 'borrow_item_id', width: 50, hideable: true, hidden: true },
							{text: 'Catalog Number', datafield: 'catalog_number', width:120, hideable: true, hidden: false },
							{text: 'Scientific Name', datafield: 'sci_name', width:120, hideable: true, hidden: false },
							{text: 'No. of Specimens', datafield: 'no_of_spec', width:120, hideable: true, hidden: false },
							{text: 'Parts/Prep', datafield: 'spec_prep', width:120, hideable: true, hidden: false },
							{text: 'Type Status', datafield: 'type_status', width:120, hideable: true, hidden: false },
							{text: 'Country of Origin', datafield: 'country_of_origin', width:120, hideable: true, hidden: false },
							{text: 'Remarks', datafield: 'object_remarks', hideable: true, hidden: false }
						],
						rowdetails: true,
						rowdetailstemplate: {
							rowdetails: "<div style='margin: 10px;'>Row Details</div>",
							rowdetailsheight: 1 // row details will be placed in popup dialog
						},
						initrowdetails: initRowDetails
					});
					$("##searchResultsGrid").on("bindingcomplete", function(event) {
						gridLoaded('searchResultsGrid','borrow item');
					});
					$('##searchResultsGrid').on('rowexpand', function (event) {
						// Create a content div, add it to the detail row, and make it into a dialog.
						var args = event.args;
						var rowIndex = args.rowindex;
						var datarecord = args.owner.source.records[rowIndex];
						createRowDetailsDialog('searchResultsGrid','rowDetailsTarget',datarecord,rowIndex);
					});
					$('##searchResultsGrid').on('rowcollapse', function (event) {
						// remove the dialog holding the row details
						var args = event.args;
						var rowIndex = args.rowindex;
						$("##searchResultsGridRowDetailsDialog" + rowIndex ).dialog("destroy");
					});
				</script>

				<section class="row mx-0" arial-label="Associated Shipments, Permits, Documents and Media">
					<div class="col-12 mt-2 mb-4 border rounded px-2 pb-2 bg-grayish">
						<section name="permitSection" class="row mx-0 border rounded bg-light my-2 px-3 pb-3" title="Subsection: Permissions and Rights Documents">
							<script>
								// callback for ajax methods to reload permits from dialog
								function reloadTransPermits() { 
									loadTransactionFormPermits(#transaction_id#);
									if ($("##addPermitDlg_#transaction_id#").hasClass('ui-dialog-content')) {
										$('##addPermitDlg_#transaction_id#').html('').dialog('destroy');
									}
									updateDeaccLimitations('#transaction_id#','borrowLimitationsDiv');
								};
								$( document ).ready( function() { 
									loadTransactionFormPermits(#transaction_id#);
									updateDeaccLimitations('#transaction_id#','borrowLimitationsDiv');
								});
							</script>
								<h2 class="h3">Permissions and Rights documents (e.g. Permits):</h2>
								<p>List here all permissions and rights related documents associated with this borrow including the deed of gift, collecting permits, CITES Permits, material transfer agreements, access benefit sharing agreements and other compliance or permit-like documents.  Permits (but not deeds of gift and some other document types) listed here are linked to all subsequent shipments of material from this borrow.  <strong>If you aren't sure of whether a permit or permit-like document should be listed with a particular shipment for the borrow or here under the borrow, list it at least here.</strong>
								</p>
								<div id="transactionFormPermits" class="col-12 px-0 pb-1">Loading permits...</div>
								<div id='addPermit_#transaction_id#' class="col-12 px-0">
									<input type='button' 
										class="btn btn-xs btn-secondary mb-2 mb-sm-0 mr-2"
										onClick="openlinkpermitdialog('addPermitDlg_#transaction_id#','#transaction_id#','Borrow: #borrowDetails.collection# #borrowDetails.borrow_number#',reloadTransPermits);" 
										value='Add Permit to this Borrow'>
								</div>
								<div id='addPermitDlg_#transaction_id#' class="my-2"></div>
						</section>
						<section name="mediaSection" class="row mx-0 border rounded bg-light my-2" title="Subsection: Media">
							<div class="col-12">
								<h2 class="h3">
									Media documenting this Borrow
<!--- TODO: Rework text --->
									<span class="mt-1 smaller d-block">Include correspondence, specimen lists, etc. here.  Attach deed of gift, collecting permits, etc., as permissions and rights documents, not here.</span>
								</h2>
								<span>
									<cfset relation="documents borrow">
									<input type='button' onClick="opencreatemediadialog('newMediaDlg_#transaction_id#','Borrow: #borrowDetails.borrow_number#','#transaction_id#','#relation#',reloadTransMedia);" value='Create Media' class='btn btn-xs btn-secondary' >
									&nbsp; 
									<span id='addMedia_#transaction_id#'>
										<input type='button' onClick="openlinkmediadialog('newMediaDlg_#transaction_id#','Borrow: #borrowDetails.borrow_number#','#transaction_id#','#relation#',reloadTransMedia);" value='Link Media' class='btn btn-xs btn-secondary' >
									&nbsp; 
									</span> 
								</span>
								<div id="addMediaDlg_#transaction_id#" class="my-2"></div>
								<div id="newMediaDlg_#transaction_id#" class="my-2"></div>
 								<cfset mediaBlock = getMediaForTransHtml(transaction_id="#transaction_id#", transaction_type="borrow") >
								<div id="transactionFormMedia" class="my-2">#mediaBlock#</div>
								<script>
									// callback for ajax methods to reload from dialog
									function reloadTransMedia() { 
										loadTransactionFormMedia(#transaction_id#,"borrow");
										if ($("##addMediaDlg_#transaction_id#").hasClass('ui-dialog-content')) {
											$('##addMediaDlg_#transaction_id#').html('').dialog('destroy');
										}
									};
								</script>
							</div> 
						</section>
						<section name="shipmentSection" class="row mx-0 border bg-light rounded my-2" title="Subsection: Shipments">
							<div class="col-12 pb-3">
								<h2 class="h3">Shipment Information</h2>
								<script>
									function opendialog(page,id,title) {
									var content = '<iframe style="border: 0px; " src="' + page + '" width="100%" height="100%"></iframe>'
									var adialog = $(id)
										.html(content)
										.dialog({
											title: title,
											autoOpen: false,
											dialogClass: 'dialog_fixed,ui-widget-header',
											modal: true,
											height: 'auto',
											width: 'auto',
											minWidth: 360,
											minHeight: 450,
											draggable:true,
											resizable:true,
											buttons: { "Ok": function () { loadShipments(#transaction_id#); $(this).dialog("destroy"); $(id).html(''); } },
											close: function() { loadShipments(#transaction_id#);  $(this).dialog("destroy"); $(id).html(''); }
										});
										adialog.dialog('open');
									};
								</script>
								<cfquery name="ship" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
									select sh.*, toaddr.country_cde tocountry, toaddr.institution toinst, fromaddr.country_cde fromcountry, fromaddr.institution frominst
									from shipment sh
										left join addr toaddr on sh.shipped_to_addr_id  = toaddr.addr_id
										left join addr fromaddr on sh.shipped_from_addr_id = fromaddr.addr_id
									where transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#borrowDetails.transaction_id#">
								</cfquery>
									<div id="shipmentTable" class="bg-light"> 
										<div class="my-2 text-center"><img src='/shared/images/indicator.gif'> Loading Shipments</div>
									</div>
								<!--- shippmentTable for ajax replace ---> 
								<script>
									$( document ).ready(loadShipments(#transaction_id#));
								</script>
								<div>
									<input type="button" class="btn btn-xs btn-secondary float-left mr-4" value="Add Shipment" onClick="$('##dialog-shipment').dialog('open'); setupNewShipment(#transaction_id#);">
									<div class="float-left mt-2 mt-md-0">Note: please check the <a href="https://code.mcz.harvard.edu/wiki/index.php/Country_Alerts">Country Alerts</a> page for special instructions or restrictions associated with specific countries</div>
								</div>
							</div>
						</section>
						<cfinclude template="/transactions/shipmentDialog.cfm">
						<section title="Summary of Restrictions and Agreed Benefits" name="limitationsSection" class="row mx-0 mt-2">
							<div class="col-12 border bg-light float-left px-3 pb-3 h-100 w-100 rounded">
								<h2 class="h3">Summary of Restrictions and Agreed Benefits from Permissions &amp; Rights Documents</h2>
								<div id="borrowLimitationsDiv"></div>
							</div>
						</section>	
						<section title="Projects" class="row mx-0 border rounded bg-light mt-2 mb-0 pb-2">
							<div class="col-12 pb-0 px-0">
								<h2 class="h3 px-3">
									Projects associated with this borrow
									<i class="fas fas-info fa-info-circle" onClick="getMCZDocs('Project')" aria-label="help link for projects"></i>
								</h2>
								<div id="projectsDiv" class="mx-3"></div>
								<script>
									$(document).ready( 
										loadProjects('projectsDiv',#borrowDetails.transaction_id#) 
									);
									function reloadTransProjects() {
										loadProjects('projectsDiv',#borrowDetails.transaction_id#);
									} 
								</script>
								<div class="col-12 my-2">
									<button type="button" aria-label="Link this borrow to an existing Project" id="linkProjectDialogLauncher"
											class="btn btn-xs btn-secondary mr-2" value="Link to Project"
											onClick=" openTransProjectLinkDialog(#transaction_id#, 'projectsLinkDialog','projectsDiv');">Link To Project</button>
									<button type="button" aria-label="Create a new Project linked to this borrow" id="newProjectDialogLauncher"
											class="btn btn-xs btn-secondary" value="New Project"
											onClick=" openTransProjectCreateDialog(#transaction_id#, 'projectsAddDialog','projectsDiv');">New Project</button>
								</div>
								<div id="projectsLinkDialog"></div>
								<div id="projectsAddDialog"></div>
							</div>
						</section>
					</div>	
				</section>
			<cfcatch>
				<h2>Error: #cfcatch.message#</h2>
				<cfif cfcatch.detail NEQ ''>
					#cfcatch.detail#
				</cfif>
			</cfcatch>
			</cftry>
		</main>
	</cfoutput> 
</cfif>

<!-------------------------------------------------------------------------------------------------->
<cfif Action is "deleBorrow">
	<cftry>
		<cftransaction>
			<cfquery name="getBorrowNum" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select borrow_number from borrow 
				where transaction_id = <cfqueryparam CFSQLType="CF_SQL_DECIMAL" value="#transaction_id#">
			</cfquery>
			<cfset deleteTarget = getBorrowNum.borrow_number>
			<cfquery name="killBorrow" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				delete from borrow 
				where transaction_id = <cfqueryparam CFSQLType="CF_SQL_DECIMAL" value="#transaction_id#">
			</cfquery>
			<cfquery name="killTransAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				delete from trans_agent 
				where transaction_id = <cfqueryparam CFSQLType="CF_SQL_DECIMAL" value="#transaction_id#">
			</cfquery>
			<cfquery name="killTrans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				delete from trans 
				where transaction_id = <cfqueryparam CFSQLType="CF_SQL_DECIMAL" value="#transaction_id#">
			</cfquery>
		</cftransaction>
		<cfoutput>
			<section class="container">
				<h1 class="h2">Borrow #deleteTarget# deleted.....</h1>
				<ul>
					<li><a href="/Transactions.cfm?action=findBorrows">Search for Borrows</a>.</li>
					<li><a href="/transactions/Borrow.cfm?action=new">Create a New Borrow</a>.</li>
				</ul>
			</section>
		</cfoutput>
	<cfcatch>
		<section class="container">
			<div class="row">
				<div class="col-10 mx-5">
				<div class="alert alert-danger" role="alert">
					<img src="/shared/images/Process-stop.png" alt="[ Error ]" style="float:left; width: 50px;margin-right: 1em;">
					<h1 class="h2">DELETE FAILED</h1>
					<p>You cannot delete an active borrow. This borrow probably has specimens or
						shipments attached. Use your back button.</p>
					<p><a href="/info/bugs.cfm">“Feedback/Report Errors”</a></p>
				</div>
				</div>
			</div>
			<p><cfdump var=#cfcatch#></p>
		</section>
	</cfcatch>
	</cftry>
</cfif>
<!-------------------------------------------------------------------------------------------------->
<cfif action is "makeBorrow">
	<cfoutput>
		<cfif not isDefined("date_entered") OR len(date_entered) is 0 >
			<cfset date_entered = dateformat(now(),"yyyy-mm-dd") >
		</cfif>
		<cfif
			( 
				not isDefined("collection_id") OR 
				not isDefined("borrow_number") OR
				not isDefined("borrow_status") OR
				not isDefined("trans_date") OR
				not isDefined("no_of_specimens") OR
				not isDefined("nature_of_material")  OR
				not isDefined("description_of_borrow")  OR
				not isDefined("inhouse_contact_agent_id") OR
				not isDefined("received_agent_id") OR
				not isDefined("received_from_agent_id") OR
				not isDefined("over_agent_id") OR
				not isDefined("lending_institution_agent_id")
			) OR (
				len(collection_id) is 0 OR 
				len(borrow_number) is 0 OR
				len(borrow_status) is 0 OR
				len(trans_date) is 0 OR
				len(no_of_specimens) is 0 OR
				len(nature_of_material) is 0 OR
				len(description_of_borrow) is 0 OR
				len(inhouse_contact_agent_id) is 0 OR
				len(received_agent_id) is 0 OR
				len(received_from_agent_id) is 0 OR
				len(over_agent_id) is 0 OR
				len(lending_institution_agent_id) is 0
			)
		>
			<!--- we shouldn't reach here, as the browser should enforce the required fields on the form before submission --->
			<h1 class="h2">One or more required fields are missing.</h1>
			<p>You must fill in Collection, Borrow Number, Status, Transaction Date Received, Nature of Material, Description of Borrow, Received From, Received By, Outside Authorized By, Number of Specimens, and Borrow Overseen By.</p>
			<p>Use your browser's back button to fix the problem and try again.</p>
			<cfabort>
		</cfif>
		<cftransaction>
			<cfquery name="obtainTransNumber" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="obtainTransNumber_result">
				select sq_transaction_id.nextval as trans_id from dual
			</cfquery>
			<cfloop query="obtainTransNumber">
				<cfset new_transaction_id = obtainTransNumber.trans_id>
			</cfloop>
			<cfquery name="newBorrowTrans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="newBorrowTrans_result">
				INSERT INTO trans (
					TRANSACTION_ID,
					TRANS_DATE, 
					CORRESP_FG,
					TRANSACTION_TYPE,
					NATURE_OF_MATERIAL,
					collection_id
					<cfif len(#trans_remarks#) gt 0>
						,trans_remarks
					</cfif>
				) VALUES (
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#new_transaction_id#">,
					<cfqueryparam cfsqltype="CF_SQL_TIMESTAMP" value='#dateformat(trans_date,"yyyy-mm-dd")#'>,
					0,
					'borrow',
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#nature_of_material#">,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_id#">
					<cfif len(#trans_remarks#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trans_remarks#">
					</cfif>
				)
			</cfquery>
			<cfquery name="newBorrow" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="newBorrow_result">
				INSERT INTO borrow (
					TRANSACTION_ID
					,borrow_number
					,description_of_borrow
					,BORROW_STATUS
					,no_of_specimens
					<cfif len(#lenders_trans_num_cde#) gt 0>
						,lenders_trans_num_cde
					</cfif>
					<cfif len(#lenders_invoice_returned_fg#) gt 0>
						,lenders_invoice_returned_fg
					</cfif>
					<cfif len(#received_date#) gt 0>
						,received_date
					</cfif>
					<cfif len(#due_date#) gt 0>
						,due_date
					</cfif>
					<cfif len(#lenders_instructions#) gt 0>
						,lenders_instructions
					</cfif>
					<cfif len(#lender_loan_type#) gt 0>
						,lender_loan_type
					</cfif>
				) VALUES (
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value='#new_transaction_id#'>
					, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value='#borrow_number#'>
					, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value='#description_of_borrow#'>
					, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value='#borrow_status#'>
					, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value='#no_of_specimens#'>
					<cfif len(#lenders_trans_num_cde#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#lenders_trans_num_cde#">
					</cfif>
					<cfif len(#lenders_invoice_returned_fg#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#lenders_invoice_returned_fg#">
					</cfif>
					<cfif len(#received_date#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_TIMESTAMP" value='#dateformat(received_date,"yyyy-mm-dd")#'>
					</cfif>
					<cfif len(#due_date#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_TIMESTAMP" value='#dateformat(due_date,"yyyy-mm-dd")#'>
					</cfif>
					<cfif len(#lenders_instructions#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#lenders_instructions#">
					</cfif>
					<cfif len(#lender_loan_type#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#lender_loan_type#">
					</cfif>
				)
			</cfquery>
			<cfquery name="q_authAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				INSERT INTO trans_agent (
					transaction_id,
					agent_id,
					trans_agent_role
				) values (
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#new_transaction_id#">,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#over_agent_id#">,
					'borrow overseen by')
			</cfquery>
			<cfquery name="q_authAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				INSERT INTO trans_agent (
					transaction_id,
					agent_id,
					trans_agent_role
				) values (
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#new_transaction_id#">,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#auth_agent_id#">,
					'outside authorized by')
			</cfquery>
			<cfquery name="q_receivedby" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				INSERT INTO trans_agent (
					transaction_id,
					agent_id,
					trans_agent_role
				) values (
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#new_transaction_id#">,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#received_agent_id#">,
					'received by')
			</cfquery>
			<cfquery name="q_receivedby" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				INSERT INTO trans_agent (
					transaction_id,
					agent_id,
					trans_agent_role
				) values (
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#new_transaction_id#">,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#received_from_agent_id#">,
					'received from')
			</cfquery>
			<cfquery name="q_recipinst" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				INSERT INTO trans_agent (
					transaction_id,
					agent_id,
					trans_agent_role
				) values (
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#new_transaction_id#">,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#lending_institution_agent_id#">,
					'lending institution')
			</cfquery>
			<cfif isdefined("inhouse_contact_agent_id") and len(inhouse_contact_agent_id) gt 0>
				<cfquery name="q_inhousecontact" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					INSERT INTO trans_agent (
						transaction_id,
						agent_id,
						trans_agent_role
					) values (
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#new_transaction_id#">,
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#inhouse_contact_agent_id#">,
						'in-house contact')
				</cfquery>
			</cfif>
			<cfif isdefined("for_use_by_agent_id") and len(for_use_by_agent_id) gt 0>
				<cfquery name="q_forUseBy" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					INSERT INTO trans_agent (
						transaction_id,
						agent_id,
						trans_agent_role
					) values (
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#new_transaction_id#">,
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#for_use_by_agent_id#">,
						'for use by')
				</cfquery>
			</cfif>
			<cfif isdefined("outside_contact_agent_id") and len(outside_contact_agent_id) gt 0>
				<cfquery name="q_addinhousecontact" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					INSERT INTO trans_agent (
						transaction_id,
						agent_id,
						trans_agent_role
					) values (
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#new_transaction_id#">,
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#outside_contact_agent_id#">,
						'outside contact')
				</cfquery>
			</cfif>
			<cfif isdefined("additional_outcontact_agent_id") and len(additional_outcontact_agent_id) gt 0>
				<cfquery name="q_addoutsidecontact" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					INSERT INTO trans_agent (
						transaction_id,
						agent_id,
						trans_agent_role
					) values (
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#new_transaction_id#">,
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#additional_outcontact_agent_id#">,
						'additional outside contact')
				</cfquery>
			</cfif>
		</cftransaction>
		<cflocation url="/transactions/Borrow.cfm?action=edit&transaction_id=#new_transaction_id#" addtoken="false">
	</cfoutput>
</cfif>

<!-------------------------------------------------------------------------------------------------->
<cfinclude template="/shared/_footer.cfm">
