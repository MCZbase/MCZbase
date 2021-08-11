<cfset pageTitle = "Deaccession Management">
<cfif isdefined("action") AND action EQ 'newDeacc'>
	<cfset action = "new">
</cfif>
<cfif isdefined("action") AND action EQ 'new'>
	<cfset pageTitle = "Create New Deaccession">
</cfif>
<cfif isdefined("action") AND action EQ 'edit'>
	<cfset pageTitle = "Edit Deaccession">
	<cfif isdefined("transaction_id") >
		<cfquery name="deaccessionNumber" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select
				deacc_number
			from
				deaccession
			where
				deaccession.transaction_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
		</cfquery>
		<cfset pageTitle = "Edit Deaccession #deaccessionNumber.deacc_number#">
	</cfif>
</cfif>
<cfset MAGIC_MCZ_COLLECTION = 12>
<cfset MAGIC_MCZ_CRYO = 11>
<cfset MAGIC_TTYPE_OTHER = 'other'><!--- Special Transaction type other, which can only be set by a sysadmin --->
<cfset MAGIC_DTYPE_TRANSFER = 'transfer'><!--- Deaccession type of Transfer --->
<cfset MAGIC_DTYPE_INTERNALTRANSFER = 'transfer (internal)'><!--- Deaccession type of Transfer (internal) --->
<cfset DEACCNUMBERPATTERN = '^D[12][0-9]{3}-[-0-9a-zA-Z]+-[A-Z][a-zA-Z]+$'>
<!--
transactions/Deaccession.cfm

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
	<!--- redirect to deaccession search page --->
	<cflocation url="/Transactions.cfm?action=findDeaccessions" addtoken="false">
</cfif>
<!-------------------------------------------------------------------------------------------------->
<cfinclude template = "/shared/_header.cfm">

<cfif not isdefined("project_id")>
	<cfset project_id = -1>
</cfif>

<!--- Deaccession controlled vocabularies --->
<cfquery name="ctDeaccessionStatus" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select deacc_status from ctdeacc_status order by deacc_status
</cfquery>
<cfquery name="ctDeaccessionType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select deacc_type from ctdeacc_type order by deacc_type
</cfquery>
<cfquery name="ctcollection" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select COLLECTION_CDE, INSTITUTION_ACRONYM, DESCR, COLLECTION, COLLECTION_ID, WEB_LINK,
		WEB_LINK_TEXT, CATNUM_PREF_FG, CATNUM_SUFF_FG, GENBANK_PRID, GENBANK_USERNAME,
		GENBANK_PWD, LOAN_POLICY_URL, ALLOW_PREFIX_SUFFIX, GUID_PREFIX, INSTITUTION 
	from collection order by collection
</cfquery>
<!--- Obtain list of transaction agent roles relevant to deaccessions --->
<cfquery name="queryNotApplicableAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select distinct agent_id from agent_name where agent_name = 'not applicable' and rownum < 2
</cfquery>
<cfset NOTAPPLICABLEAGENTID = queryNotApplicableAgent.agent_id >
<cfquery name="cttrans_agent_role" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select distinct(cttrans_agent_role.trans_agent_role) 
	from cttrans_agent_role
		left join trans_agent_role_allowed on cttrans_agent_role.trans_agent_role = trans_agent_role_allowed.trans_agent_role
	where 
		trans_agent_role_allowed.transaction_type = 'Deaccession'
	order by cttrans_agent_role.trans_agent_role
</cfquery>

<cfoutput>
	<script language="javascript" type="text/javascript">
		// setup date pickers
		jQuery(document).ready(function() {
			$("##trans_date").datepicker({ dateFormat: 'yy-mm-dd'});
			$("##to_trans_date").datepicker({ dateFormat: 'yy-mm-dd'});
			$("##initiating_date").datepicker({ dateFormat: 'yy-mm-dd'});
			$("##shipped_date").datepicker({ dateFormat: 'yy-mm-dd'});
		});
	</script>
</cfoutput>
<!-------------------------------------------------------------------------------------------------->
<cfif action is "new">
	<cfset title="New Deaccession">
	<cfoutput>
		<main class="container py-3" id="content">
			<h1 class="h2" id="newDeaccessionFormSectionLabel" >Create New Deaccession <i class="fas fa-info-circle" onClick="getMCZDocs('Deaccession)" aria-label="help link"></i></h1>
			<div class="row border rounded bg-light mt-2 mb-4 p-2">
				<section class="col-12" title="next available deaccession number"> 
					<script>
						function setDeaccNum(cid,deaccNum) {
							$("##deacc_number").val(deaccNum);
							$("##collection_id").val(cid);
							$("##collection_id").change();
						}
					</script>
					<div id="nextNumDiv">
						<h2 class="h4 mx-2 mb-1" id="nextNumberSectionLabel" title="Click on a collection button and the next available deaccession number in the database for that collection will be entered">Next Available Deaccession Number:</h2>
						<!--- Find list of all collections --->
						<cfquery name="allCollections" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							select collection_id, collection_cde, collection from collection 
							order by collection 
						</cfquery>
						<div class="flex-row float-left mb-1">
						<cfloop query="allCollections">
							<cftry>
								<!---- Deaccession numbers follow Dyyyy-n-CCDE format, obtain highest n for current year for each collection. --->
								<cfquery name="nextNumberQuery" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
									select
									'D#dateformat(now(),"yyyy")#-' || nvl( max(to_number(substr(deacc_number,instr(deacc_number,'-')+1,instr(deacc_number,'-',1,2)-instr(deacc_number,'-')-1) + 1)) , 1) || '-#collection_cde#' as nextNumber
									from
										deaccession,
										trans,
										collection
									where
										deaccession.transaction_id=trans.transaction_id 
										AND trans.collection_id=collection.collection_id
										AND collection.collection_id = <cfqueryparam value="#collection_id#" cfsqltype="CF_SQL_DECIMAL">
										AND substr(deacc_number, 2,4) ='#dateformat(now(),"yyyy")#'
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
				<section class="col-12 border bg-white pt-3" id="newDeaccessionFormSection" aria-label="Form to create new deaccession">
					<form name="newDeaccession" id="newDeaccession" class="" action="/transactions/Deaccession.cfm" method="post" onSubmit="return noenter();">
						<input type="hidden" name="action" value="makeDeaccession">
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
								<label for="deacc_number" class="data-entry-label">Deaccession Number (Dyyyy-n-Coll)</label>
								<input type="text" name="deacc_number" class="reqdClr data-entry-input" id="deacc_number" required pattern="#DEACCNUMBERPATTERN#">
							</div>
							<div class="col-12 col-md-3">
								<label for="status" class="data-entry-label">Status</label>
								<select name="deacc_status" id="status" class="reqdClr data-entry-select" required >
									<cfloop query="ctDeaccessionStatus">
											<cfif #ctDeaccessionStatus.deacc_status# is "in process">
												<cfset selected = "selected='selected'">
											<cfelse>
												<cfset selected="">
											</cfif>
											<option value="#ctDeaccessionStatus.deacc_status#" #selected# >#ctDeaccessionStatus.deacc_status#</option>
									</cfloop>
								</select>
							</div>
							<div class="col-12 col-md-3">
								<label for="deacc_type" class="data-entry-label">Deaccession Type</label>
								<select name="deacc_type" id="deacc_type" class="reqdClr data-entry-select" required >
									<option value=""></option>
									<cfloop query="ctDeaccessionType">
											<option value="#ctDeaccessionType.deacc_type#">#ctDeaccessionType.deacc_type#</option>
									</cfloop>
								</select>
							</div>
						</div>
						<div class="form-row mb-2">
							<div class="col-12 col-md-6">
								<span>
									<label for="auth_agent" class="data-entry-label">
										In-house authorized by:
										<span id="auth_agent_view">&nbsp;&nbsp;&nbsp;&nbsp;</span>
									</label>
								</span>
								<div class="input-group">
									<div class="input-group-prepend">
										<span class="input-group-text smaller bg-lightgreen" id="auth_agent_icon"><i class="fa fa-user" aria-hidden="true"></i></span> 
									</div>
									<input name="auth_agent_name" id="auth_agent_name" class="reqdClr form-control form-control-sm data-entry-input" required >
								</div>
								<input type="hidden" name="auth_agent_id" id="auth_agent_id" >
								<script>
									$(makeRichTransAgentPicker('auth_agent_name', 'auth_agent_id','auth_agent_icon','auth_agent_view',null))
								</script> 
							</div>
							<div class="col-12 col-md-6">
								<span>
									<label for="rec_agent_name" class="data-entry-label">
										Received By:
										<span id="rec_agent_view">&nbsp;&nbsp;&nbsp;&nbsp;</span>
									</label>
								</span>
								<div class="input-group">
									<div class="input-group-prepend">
										<span class="input-group-text smaller bg-lightgreen" id="rec_agent_icon"><i class="fa fa-user" aria-hidden="true"></i></span> 
									</div>
									<input name="rec_agent_name" id="rec_agent_name" required class="form-control form-control-sm data-entry-input reqdClr" >
								</div>
								<input type="hidden" name="rec_agent_id" id="rec_agent_id" >
								<script>
									$(makeRichTransAgentPicker('rec_agent_name','rec_agent_id','rec_agent_icon','rec_agent_view',null));
								</script> 
							</div>
						</div>
						<div class="form-row mb-2">
							<div class="col-12 col-md-6">
								<span>
									<label for="inhouse_contact_agent_name" class="data-entry-label">
										In-House Contact:
										<span id="inhouse_contact_agent_view">&nbsp;&nbsp;&nbsp;&nbsp;</span> 
									</label>
								</span>
								<div class="input-group">
									<div class="input-group-prepend">
										<span class="input-group-text smaller bg-lightgreen" id="inhouse_contact_agent_icon"><i class="fa fa-user" aria-hidden="true"></i></span> 
									</div>
									<input type="text" name="inhouse_contact_agent_name" id="inhouse_contact_agent_name" required class="reqdClr form-control form-control-sm data-entry-input">
								</div>
								<input type="hidden" name="inhouse_contact_agent_id" id="inhouse_contact_agent_id" >
								<script>
									$(makeRichTransAgentPicker('inhouse_contact_agent_name','inhouse_contact_agent_id','inhouse_contact_agent_icon','inhouse_contact_agent_view',null));
								</script> 
							</div>
							<div class="col-12 col-md-6">
								<span>
									<label for="additional_outcontact_agent_name" class="data-entry-label">
										Additional Outside Contact:
										<span id="additional_outcontact_agent_view">&nbsp;&nbsp;&nbsp;&nbsp;</span> 
									</label>
								</span>
								<div class="input-group">
									<div class="input-group-prepend">
										<span class="input-group-text smaller bg-lightgreen" id="additional_outcontact_agent_icon"><i class="fa fa-user" aria-hidden="true"></i></span> 
									</div>
									<input type="text" name="additional_outcontact_agent_name" id="additional_outcontact_agent_name" class="form-control form-control-sm data-entry-input" >
								</div>
								<input type="hidden" name="additional_outcontact_agent_id" id="additional_outcontact_agent_id" >
								<script>
									$(makeRichTransAgentPicker('additional_outcontact_agent_name','additional_outcontact_agent_id','additional_outcontact_agent_icon','additional_outcontact_agent_view',null));
								</script> 
							</div>
						</div>
						<div class="form-row mb-2">
							<div class="col-12 col-md-6">
								<span>
									<label for="recipient_institution_agent_name" class="data-entry-label">
										Recipent Institution
										<span id="recipient_institution_agent_view">&nbsp;&nbsp;&nbsp;&nbsp;</span> 
									</label>
								</span>
								<div class="input-group">
									<div class="input-group-prepend">
										<span class="input-group-text smaller bg-lightgreen" id="recipient_institution_agent_icon"><i class="fa fa-user" aria-hidden="true"></i></span> 
									</div>
									<input type="text" name="recipient_institution_agent_name" id="recipient_institution_agent_name" required class="form-control form-control-sm data-entry-input reqdClr">
								</div>
								<input type="hidden" name="recipient_institution_agent_id" id="recipient_institution_agent_id" >
								<script>
									$(makeRichTransAgentPickerConstrained('recipient_institution_agent_name','recipient_institution_agent_id','recipient_institution_agent_icon','recipient_institution_agent_view',null,'organization_agent'));
								</script> 
							</div>
							<div class="col-12 col-md-6">
								<span>
									<label for="foruseby_agent_name" class="data-entry-label">
										For Use By:
										<span id="foruseby_agent_view">&nbsp;&nbsp;&nbsp;&nbsp;</span> 
									</label>
								</span>
								<div class="input-group">
									<div class="input-group-prepend">
										<span class="input-group-text smaller bg-lightgreen" id="foruseby_agent_icon"><i class="fa fa-user" aria-hidden="true"></i></span> 
									</div>
									<input type="text" name="foruseby_agent_name" id="foruseby_agent_name" class="form-control form-control-sm data-entry-input" >
								</div>
								<input type="hidden" name="foruseby_agent_id" id="foruseby_agent_id" >
								<script>
									$(makeRichTransAgentPicker('foruseby_agent_name','foruseby_agent_id','foruseby_agent_icon','foruseby_agent_view',null));
								</script> 
							</div>
						</div>
						<div class="form-row mb-2">
							<div class="col-12 col-md-4">
								<label for="trans_date" class="data-entry-label">Transaction Date</label>
								<input type="text" name="trans_date" id="trans_date" 
									required
									value="#dateformat(now(),"yyyy-mm-dd")#" 
									class="reqdClr w-100 data-entry-input">
							</div>
							<div class="col-12 col-md-4">
								<label for="method" class="data-entry-label">Method of Transfer</label>
								<input type="text" name="method" id="method" class="w-100 data-entry-input">
							</div>
							<div class="col-12 col-md-4">
								<label for="value" class="data-entry-label">Value of Specimen(s)</label>
								<input type="text" name="value" id="value" class="w-100 data-entry-input">
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
								<label for="deacc_reason" class="data-entry-label">Reason for Deaccession (<span id="length_deacc_reason"></span>)</label>
								<textarea name="deacc_reason" id="deacc_reason" rows="2" 
									onkeyup="countCharsLeft('deacc_reason', 4000, 'length_deacc_reason');"
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
								<input type="button" value="Create Deaccession" class="btn mt-2 btn-xs btn-primary"
									onClick="if (checkFormValidity($('##newDeaccession')[0])) { submit(); } ">
							</div>
						</div>
					</form>
					<!--- Set initial state for new deaccession --->
					<script>
						$('##deacc_type').val('discarded').prop('selected', true);
						$("##rec_agent_name").val('not applicable');
						$("##rec_agent_id").val('#NOTAPPLICABLEAGENTID#');
						$("##rec_agent_id").trigger('change');
						$("##recipient_institution_agent_name").val('not applicable');
						$("##recipient_institution_agent_id").val('#NOTAPPLICABLEAGENTID#');
						$("##recipient_institution_agent_id").trigger('change');
						forcedAgentPick('rec_agent_id',#NOTAPPLICABLEAGENTID#,'rec_agent_view','rec_agent_icon','rec_agent_name');
						forcedAgentPick('recipient_institution_agent_id',#NOTAPPLICABLEAGENTID#,'recipient_institution_agent_view','recipient_institution_agent_icon','recipient_institution_agent_name');

						// Handle special cases of deaccession types transfer and other 
						// transfer is not allowed as a type for a new accesison by default (but see below on selection of MCZ collection).
						$("##deacc_type option[value='#MAGIC_DTYPE_TRANSFER#']").each(function() { $(this).remove(); } );
						<cfif isdefined("session.roles") and not listfindnocase(session.roles,"admin_transactions")>
							// only admin_transaction role can create new accessions of type internal transfer.
							$("##deacc_type option[value='#MAGIC_DTYPE_INTERNALTRANSFER#']").each(function() { $(this).remove(); } );
						</cfif>
						<cfif NOT (isdefined("session.roles") and listcontainsnocase(session.roles,"global_admin"))>
							// other (MAGIC_TTYPE_OTHER) is not allowed as a type for a new deaccesison (must be set by sysadmin).
							$("##deacc_type option[value='#MAGIC_TTYPE_OTHER#']").each(function() { $(this).remove(); } );
						</cfif>
					</script>
					<!--- handlers for various change events --->
					<script>
						// on page load, bind a function to collection_id to change the list of deaccession
						// based on the selected collection
						$("##collection_id").change( function () {
							if ( $("##collection_id option:selected").text() == "MCZ Collections" ) {
								// only MCZ collections (the non-specimen collection) is allowed to make transfers.
								$("##deacc_type").append($("<option></option>").attr("value",'#MAGIC_DTYPE_TRANSFER#').text('#MAGIC_DTYPE_TRANSFER#'));
							} else {
								$("##deacc_type option[value='#MAGIC_DTYPE_TRANSFER#']").each(function() { $(this).remove(); } );
							}
						});
						$("##deacc_type").change( function () {
							if ( $("##deacc_type option:selected").text() == "discarded" ) {
								$("##rec_agent_name").val('not applicable');
								$("##rec_agent_id").val('#NOTAPPLICABLEAGENTID#');
								$("##rec_agent_id").trigger('change');
								$("##recipient_institution_agent_name").val('not applicable');
								$("##recipient_institution_agent_id").val('#NOTAPPLICABLEAGENTID#');
								$("##recipient_institution_agent_id").trigger('change');
								forcedAgentPick('rec_agent_id',#NOTAPPLICABLEAGENTID#,'rec_agent_view','rec_agent_icon','rec_agent_name');
								forcedAgentPick('recipient_institution_agent_id',#NOTAPPLICABLEAGENTID#,'recipient_institution_agent_view','recipient_institution_agent_icon','recipient_institution_agent_name');
							} else {
								if ($("##rec_agent_id").val()=='#NOTAPPLICABLEAGENTID#') {
									$("##rec_agent_name").val('');
									$("##rec_agent_id").val('');
									$("##rec_agent_id").trigger('change');
								}
								if ($("##recipient_institution_agent_id").val()=='#NOTAPPLICABLEAGENTID#') {
									$("##recipient_institution_agent_name").val('');
									$("##recipient_institution_agent_id").val('');
									$("##recipient_institution_agent_id").trigger('change');
								}
							}
						});
					</script>
				</section>
			</div>
		</main>
	</cfoutput>
</cfif>
<!-------------------------------------------------------------------------------------------------->
<cfif action is "edit">
	<cfset title="Edit Deaccession">
	
	<cfif not isdefined("transaction_id") or len(transaction_id) EQ 0>
		<cfthrow message="Edit Deaccession called without a transaction_id for the deaccession to edit">
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
								loadTransactionFormMedia(#transaction_id#,"deaccession"); 
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
			<cfquery name="deaccessionDetails" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="deaccessionDetails_result">
				select
					trans.transaction_id,
					trans.transaction_type,
					trans_date dateEntered,
					deacc_number,
					deacc_type,
					deacc_status,
					trans_date,
					nature_of_material,
					deacc_reason,
					value,
					method,
					trans_remarks,
					trans.collection_id,
					collection.collection,
					concattransagent(trans.transaction_id,'entered by') enteredby
				 from
					trans
					left join deaccession on trans.transaction_id = deaccession.transaction_id 
					left join collection on trans.collection_id=collection.collection_id 
				where
					trans.transaction_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
			</cfquery>
			<cfif deaccessionDetails.RecordCount EQ 0 >
				<cfthrow message = "No such Deaccession.">
			</cfif>
			<cfif deaccessionDetails.RecordCount GT 0 AND deaccessionDetails.transaction_type NEQ 'deaccession'>
				<cfthrow message = "Request to edit an deaccession, but the provided transaction_id was for a different transaction type [#deaccessionDetails.transaction_type#].">
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
					// on page load, hide the create project from deaccession fields
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
		
		<main class="container py-3" id="content" title="Edit Deaccession Form Content">
			<cftry>
				<h1 class="h2 pb-0 ml-3">Edit Deaccession
					<strong>#deaccessionDetails.collection# #deaccessionDetails.deacc_number#</strong> 
					<i class="fas fa-info-circle" onClick="getMCZDocs('Deaccession_Field_Definitions')" aria-label="help link"></i>
				</h1>
				<section class="row mx-0 border rounded my-2 pt-2" title="Edit Deaccession Details" >
					<form class="col-12" name="editDeaccessionForm" id="editDeaccessionForm" action="/transactions/Deaccession.cfm" method="post" onSubmit="return noenter();">
						<input type="hidden" name="method" value="saveDeaccession"><!--- used in normal ajax save, which uses the form fields to post to transactions/component/functions.cfc --->
						<input id="action" type="hidden" name="action" value="edit"><!--- reused by delete deaccession, not used in normal save --->
						<input type="hidden" name="transaction_id" value="#deaccessionDetails.transaction_id#">
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
										<option <cfif ctcollection.collection_id is deaccessionDetails.collection_id> selected </cfif>
											value="#ctcollection.collection_id#">#ctcollection.collection#</option>
									</cfloop>
								</select>
							</div>
							<div class="col-12 col-md-3">
								<label for="deacc_number" class="data-entry-label">Deaccession Number (nnnnnn)</label>
								<input type="text" name="deacc_number" id="deacc_number" value="#encodeForHTML(deaccessionDetails.deacc_number)#" class="reqdClr data-entry-input" 
									required pattern="#DEACCNUMBERPATTERN#" >
							</div>
							<div class="col-12 col-md-3">
								<label for="deacc_status" class="data-entry-label">Deaccession Status</label>
								<span>
									<select name="deacc_status" id="deacc_status" class="reqdClr data-entry-select" required >
										<cfloop query="ctDeaccessionStatus">
											<option <cfif ctDeaccessionStatus.deacc_status is deaccessionDetails.deacc_status> selected="selected" </cfif>
												value="#ctDeaccessionStatus.deacc_status#">#ctDeaccessionStatus.deacc_status#</option>
										</cfloop>
									</select>
								</span>
							</div>
							<div class="col-12 col-md-3">
								<label for="deacc_type" class="data-entry-label">Deaccession Type</label>
								<!--- special case handling of other and transfer deaccession types --->
								<cfif deaccessionDetails.deacc_type EQ "#MAGIC_TTYPE_OTHER#">
									<!--- deacc_type other (MAGIC_TTYPE_OTHER) is read only --->
									<input type="hidden" name="deacc_type" id="deacc_type" value="#MAGIC_TTYPE_OTHER#">
									<select name="deacc_type_readonly" id="deacc_type" class="reqdClr data-entry-select" disabled="true">
										<option selected="selected" value="#MAGIC_TTYPE_OTHER#">#MAGIC_TTYPE_OTHER#</option>
									</select>
								<cfelse>
									<select name="deacc_type" id="deacc_type" class="reqdClr data-entry-select" required>
										<cfloop query="ctDeaccessionType">
											<!--- Other is not an allowed option (unless it is already set) --->
											<cfif ctDeaccessionType.deacc_type NEQ MAGIC_TTYPE_OTHER >
												<!--- Only the MCZ Collection is allowed to make transfers --->
												<cfif ctDeaccessionType.deacc_type NEQ MAGIC_DTYPE_TRANSFER OR deaccessionDetails.collection_id EQ MAGIC_MCZ_COLLECTION >
													<option <cfif ctDeaccessionType.deacc_type is deaccessionDetails.deacc_type> selected="selected" </cfif>
														value="#ctDeaccessionType.deacc_type#">#ctDeaccessionType.deacc_type#</option>
												<cfelseif deaccessionDetails.deacc_type EQ "#MAGIC_DTYPE_TRANSFER#" AND deaccessionDetails.collection_id NEQ MAGIC_MCZ_COLLECTION >
													<option <cfif ctDeaccessionType.deacc_type is deaccessionDetails.deacc_type> selected="selected" </cfif> value=""></option>
												</cfif>
											</cfif>
										</cfloop>
									</select>
								</cfif>
							</div>
						</div>
						<div class="form-row mb-1">
							<div class="col-12 col-md-3">
								<label for="method" class="data-entry-label">Method of Transfer</label>
								<!--- needs to submit as methodoftransfer to disambiguate from cfcomponent method in post --->
								<input type="text" name="methodoftransfer" id="method" 
									value="#encodeForHTML(deaccessionDetails.method)#" class="data-entry-input" >
							</div>
							<div class="col-12 col-md-3">
								<label for="value" class="data-entry-label">Value of Specimen(s)</label>
								<input type="text" name="value" id="value" 
									value="#encodeForHTML(deaccessionDetails.value)#" class="data-entry-input" >
							</div>
							<div class="col-12 col-md-2">
								<label for="trans_date" class="data-entry-label">Transaction Date</label>
								<input type="text" name="trans_date" id="trans_date" required
									value="#dateformat(deaccessionDetails.trans_date,"yyyy-mm-dd")#" class="reqdClr data-entry-input" >
							</div>
							<div class="col-12 col-md-2">
								<span class="data-entry-label">Entered Date</span>
								<div class="col-12 bg-light border non-field-text">
									<span id="date_entered">#dateformat(deaccessionDetails.dateEntered,'yyyy-mm-dd')#</span>
								</div>
							</div>
							<div class="col-12 col-md-2">
								<span class="data-entry-label">Entered By</span>
								<div class="col-12 bg-light: border non-field-text">
									<span id="entered_by">#encodeForHTML(deaccessionDetails.enteredby)#</span>
								</div>
							</div>
						</div>
						<!--- Begin transaction agents table: Load via ajax. --->
						<div class="form-row my-1">
							<script>
								function reloadTransactionAgents() { 
									loadAgentTable("agentTableContainerDiv",#transaction_id#,"editDeaccessionForm",handleChange);
								}
								$(document).ready(function() {
									reloadTransactionAgents();
								});
							</script>
							<div class="col-12 mt-1" id="agentTableContainerDiv">
								<img src='/shared/images/indicator.gif'>
								Loading Agents....  <span id='agentWarningSpan' style="display:none;">(if agents don't appear here, there is an error).</span>
								<script>
								$(document).ready(function() { 
									$('##agentWarningSpan').delay(1000).fadeIn(300);
								});
								</script>
							</div>
							<script>
								$(document).ready(function() { 
									$('##agentTableContainerDiv').on('domChanged',function() {
										console.log("dom change within agentTableContainerDiv");
										monitorForChanges('editDeaccessionForm',handleChange);
									});
								});
							</script>
						</div>
						<div class="form-row mb-1">
							<div class="col-12">
								<label for="nature_of_material" class="data-entry-label">Nature of Material (<span id="length_nature_of_material"></span>)</label>
								<textarea name="nature_of_material" id="nature_of_material" rows="1" 
									onkeyup="countCharsLeft('nature_of_material', 4000, 'length_nature_of_material');"
									class="reqdClr autogrow data-entry-textarea" required >#encodeForHtml(deaccessionDetails.nature_of_material)#</textarea>
							</div>
						</div>
						<div class="form-row mb-1">
							<div class="col-12">
								<label for="deacc_reason" class="data-entry-label">Reason For Deaccession (<span id="length_deacc_reason"></span>)</label>
								<textarea name="deacc_reason" id="deacc_reason" rows="1" 
									onkeyup="countCharsLeft('deacc_reason', 4000, 'length_deacc_reason');"
									class="reqdClr autogrow data-entry-textarea" required >#encodeForHTML(deaccessionDetails.deacc_reason)#</textarea>
							</div>
						</div>
						<div class="form-row mb-1">
							<div class="col-12">
								<label for="trans_remarks" class="data-entry-label">Internal Remarks (<span id="length_trans_remarks"></span>)</label>
								<textarea name="trans_remarks" id="trans_remarks" rows="1"
									onkeyup="countCharsLeft('trans_remarks', 4000, 'length_trans_remarks');"
									class="autogrow data-entry-textarea">#encodeForHTML(deaccessionDetails.trans_remarks)#</textarea>
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
									onClick="if (checkFormValidity($('##editDeaccessionForm')[0])) { saveEdits();  } " 
									id="submitButton" >
								<button type="button" aria-label="Print Deaccession Paperwork" id="deaccessionPrintDialogLauncher"
									class="btn btn-xs btn-info mr-2" value="Print..."
									onClick=" openTransactionPrintDialog(#transaction_id#, 'Deaccession', 'deaccessionPrintDialog');">Print...</button>
								<output id="saveResultDiv" class="text-danger">&nbsp;</output>	
								<input type="button" value="Delete Deaccession" class="btn btn-xs btn-danger float-right"
									onClick=" $('##action').val('edit'); confirmDialog('Delete this Deaccession?','Confirm Delete Deaccession', function() { $('##action').val('deleDeaccession'); $('##editDeaccessionForm').removeAttr('onsubmit'); $('##editDeaccessionForm').submit(); } );">
							</div>
						</div>
						<div id="deaccessionPrintDialog"></div>
						<script>
							$(document).ready(function() {
								monitorForChanges('editDeaccessionForm',handleChange);
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
									data : $('##editDeaccessionForm').serialize(),
									success : function (data) {
										$('##saveResultDiv').html('Saved.');
										$('##saveResultDiv').addClass('text-success');
										$('##saveResultDiv').removeClass('text-danger');
										$('##saveResultDiv').removeClass('text-warning');
										loadAgentTable("agentTableContainerDiv",#transaction_id#,"editDeaccessionForm",handleChange);
									},
									error: function(jqXHR,textStatus,error){
										$('##saveResultDiv').html('Error.');
										$('##saveResultDiv').addClass('text-danger');
										$('##saveResultDiv').removeClass('text-success');
										$('##saveResultDiv').removeClass('text-warning');
										handleFail(jqXHR,textStatus,error,'saving deaccession record');
									}
								});
							};
						</script>
					</form>
				</section>
				<script>
					function updateItemSections() { 
						updateDeaccItemCount('#transaction_id#','deaccessionItemCountDiv');
						updateDeaccItemDispositions('#transaction_id#','deaccessionItemDispositionsDiv');
						updateTransItemCountries('#transaction_id#','countriesOfOriginDiv');
						updateDeaccLoans('#transaction_id#','deaccessionLoansDiv');
					};
					$(document).ready(function() {
						updateItemSections();
					});
				</script>
				<section name="deaccessionItemsSection" class="row border rounded mx-0 my-2" title="Collection Objects in this Deaccession">
					<div class="col-12 pt-3 pb-1">
						<input type="button" value="Add Items" class="btn btn-xs btn-secondary mb-2 mb-sm-0 mr-2"
							onClick="window.open('/SpecimenSearch.cfm?action=dispCollObjDeacc&transaction_id=#transaction_id#');">
						<input type="button" value="Add Items by Barcode" class="btn btn-xs btn-secondary mb-2 mb-sm-0 mr-2"
							onClick="window.open('/deaccByBarcode.cfm?transaction_id=#transaction_id#');">
						<input type="button" value="Review Items" class="btn btn-xs btn-secondary mb-2 mb-sm-0 mr-2"
							onClick="window.open('/a_deaccItemReview.cfm?transaction_id=#transaction_id#');">
						<input type="button" value="Refresh Item Count" class="btn btn-xs btn-info mb-2 mb-sm-0 mr-2"
							onClick=" updateItemSections(); ">
					</div>
					<div class="col-12 pt-2 pb-1">
						<div id="deaccessionItemCountDiv"></div>
						<div id="deaccessionItemDispositionsDiv"></div>
					</div>
				</section>
				<section role="search" aria-labelledby="guid_list_label" class="container my-3" title="Search for collection objects to add to this deaccession">
					<h2 class="h3">Add Cataloged Items to this Deaccession</h2>
						<div class="row border rounded mb-2 pb-2" >
							<form name="addCollObjectsDeaccession" id="addCollObjectsDeaccession" class="col-12">
							<input type="hidden" id="transaction_id" name="transaction_id" value="#transaction_id#" >
							<input type="hidden" id="method" name="method" value="addCollObjectsDeaccession" >
							<div class="form-row mx-0 my-2">
								<div class="col-12 col-md-8">
									<label for="guid_list" id="guid_list_label" class="data-entry-label">Cataloged items to add to this deaccession (comma separated list of GUIDs in the form MCZ:Dept:number)</label>
									<input type="text" id="guid_list" name="guid_list" class="data-entry-input" 
											value="" placeholder="MCZ:Dept:1111,MCZ:Dept:1112" >
								</div>
								<div class="col-12 col-md-2">
									<label for="deacc_items_remarks" id="deacc_items_remarks_label" class="data-entry-label">Remarks</label>
									<input type="text" id="deacc_item_remarks" name="deacc_items_remarks" class="data-entry-input" value="" >
								</div>
								<script>
									function addCollectionObjects(){ 
										$('##addResultDiv').html("Saving.... ");
										jQuery.ajax({
											url : "/transactions/component/functions.cfc",
											type : "post",
											dataType : "json",
											data : $('##addCollObjectsDeaccession').serialize(),
											success : function (data) {
												updateItemSections();
												$('##addResultDiv').html("Added " + data[0].added);
											},
											error: function(jqXHR,textStatus,error){
												handleFail(jqXHR,textStatus,error,"adding item to deaccession");
												$('##addResultDiv').html("Error.");
											}
										});
									};
									$(document).ready( function() {
										$('##addCollObjectsDeaccession').on('submit', 
											function(event){
												event.preventDefault();
												if ($('##guid_list').val().length > 0)  {
													addCollectionObjects();
												}
											}
										);
									});
								</script>
								<div class="col-12 col-md-2">
									<div id="addResultDiv">&nbsp;</div>
									<input type="button" id="addbutton"
											value="Add" aria-label="Add catalog items"
											class="btn mt-0 mt-md-3 mt-lg-1 btn-xs btn-secondary"
											onClick=" addCollectionObjects(); " 
											>
								</div>
							</div>
						</form>
						</div>
					</section>
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
									updateDeaccLimitations('#transaction_id#','deaccessionLimitationsDiv');
								};
								$( document ).ready( function() { 
									loadTransactionFormPermits(#transaction_id#);
									updateDeaccLimitations('#transaction_id#','deaccessionLimitationsDiv');
								});
							</script>
								<h2 class="h3">Permissions and Rights documents (e.g. Permits):</h2>
								<p>List here all permissions and rights related documents associated with this deaccession including the deed of gift, collecting permits, CITES Permits, material transfer agreements, access benefit sharing agreements and other compliance or permit-like documents.  Permits (but not deeds of gift and some other document types) listed here are linked to all subsequent shipments of material from this deaccession.  <strong>If you aren't sure of whether a permit or permit-like document should be listed with a particular shipment for the deaccession or here under the deaccession, list it at least here.</strong>
								</p>
								<div id="transactionFormPermits" class="col-12 px-0 pb-1">Loading permits...</div>
								<div id='addPermit_#transaction_id#' class="col-12 px-0">
									<input type='button' 
										class="btn btn-xs btn-secondary mb-2 mb-sm-0 mr-2"
										onClick="openlinkpermitdialog('addPermitDlg_#transaction_id#','#transaction_id#','Deaccession: #deaccessionDetails.collection# #deaccessionDetails.deacc_number#',reloadTransPermits);" 
										value='Add Permit to this Deaccession'>
								</div>
								<div id='addPermitDlg_#transaction_id#' class="my-2"></div>
						</section>
						<section name="mediaSection" class="row mx-0 border rounded bg-light my-2" title="Subsection: Media">
							<div class="col-12">
								<h2 class="h3">
									Media documenting this Deaccession
<!--- TODO: Rework text --->
									<span class="mt-1 smaller d-block">Include correspondence, specimen lists, etc. here.  Attach deed of gift, collecting permits, etc., as permissions and rights documents, not here.</span>
								</h2>
								<cfquery name="media" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
									select
										media.media_id,
										preview_uri,
										media_uri,
										media_type,
										label_value
									from
										media,
										media_relations,
										(select * from media_labels where media_label='description') media_labels
									where
										media.media_id=media_labels.media_id (+) and
										media.media_id=media_relations.media_id and
										media_relationship like '% deaccession' and
										related_primary_key=<cfqueryparam value="#transaction_id#" cfsqltype="CF_SQL_DECIMAL">
								</cfquery>
								<span>
									<cfset relation="documents deaccession">
									<input type='button' onClick="opencreatemediadialog('newMediaDlg_#transaction_id#','Deaccession: #deaccessionDetails.deacc_number#','#transaction_id#','#relation#',reloadTransMedia);" value='Create Media' class='btn btn-xs btn-secondary' >
									&nbsp; 
									<span id='addMedia_#transaction_id#'>
										<input type='button' onClick="openlinkmediadialog('newMediaDlg_#transaction_id#','Deaccession: #deaccessionDetails.deacc_number#','#transaction_id#','#relation#',reloadTransMedia);" value='Link Media' class='btn btn-xs btn-secondary' >
									&nbsp; 
									</span> 
								</span>
								<div id="addMediaDlg_#transaction_id#" class="my-2"></div>
								<div id="newMediaDlg_#transaction_id#" class="my-2"></div>
								<div id="transactionFormMedia" class="my-2"><img src='/shared/images/indicator.gif'> Loading Media....</div>
								<script>
									// callback for ajax methods to reload from dialog
									function reloadTransMedia() { 
										loadTransactionFormMedia(#transaction_id#,"deaccession");
										if ($("##addMediaDlg_#transaction_id#").hasClass('ui-dialog-content')) {
											$('##addMediaDlg_#transaction_id#').html('').dialog('destroy');
										}
									};
									$( document ).ready(loadTransactionFormMedia(#transaction_id#,"deaccession"));
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
									where transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#deaccessionDetails.transaction_id#">
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
						<section name="countriesOfOriginSection" class="row mx-0 border bg-light rounded mt-2" title="Subsection: Country of Origin">
							<div class="col-12 pb-3">
								<div id="countriesOfOriginDiv"></div>
							</div>
						</section>
						<section title="Loans of material in this deaccession" name="loansSection" class="row mx-0 mt-2" title="Subsection: Loan of Deaccession Material">
							<div class="col-12 border bg-light float-left px-3 pb-3 h-100 w-100 rounded">
								<h2 class="h3">Loans of material in this deaccession</h2>
								<div id="deaccessionLoansDiv"></div>
							</div>
						</section>	
						<section title="Summary of Restrictions and Agreed Benefits" name="limitationsSection" class="row mx-0 mt-2">
							<div class="col-12 border bg-light float-left px-3 pb-3 h-100 w-100 rounded">
								<h2 class="h3">Summary of Restrictions and Agreed Benefits from Permissions &amp; Rights Documents</h2>
								<div id="deaccessionLimitationsDiv"></div>
							</div>
						</section>	
						<section title="Projects" class="row mx-0 border rounded bg-light mt-2 mb-0 pb-2">
							<div class="col-12 pb-0 px-0">
								<h2 class="h3 px-3">
									Projects associated with this deaccession
									<i class="fas fas-info fa-info-circle" onClick="getMCZDocs('Project')" aria-label="help link for projects"></i>
								</h2>
								<div id="projectsDiv" class="mx-3"></div>
								<script>
									$(document).ready( 
										loadProjects('projectsDiv',#deaccessionDetails.transaction_id#) 
									);
									function reloadTransProjects() {
										loadProjects('projectsDiv',#deaccessionDetails.transaction_id#);
									} 
								</script>
								<div class="col-12 my-2">
									<button type="button" aria-label="Link this deaccession to an existing Project" id="linkProjectDialogLauncher"
											class="btn btn-xs btn-secondary mr-2" value="Link to Project"
											onClick=" openTransProjectLinkDialog(#transaction_id#, 'projectsLinkDialog','projectsDiv');">Link To Project</button>
									<button type="button" aria-label="Create a new Project linked to this deaccession" id="newProjectDialogLauncher"
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
<cfif Action is "deleDeaccession">
	<cftry>
		<cftransaction>
			<cfquery name="getDeaccessionNum" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select deacc_number from deaccession 
				where transaction_id = <cfqueryparam CFSQLType="CF_SQL_DECIMAL" value="#transaction_id#">
			</cfquery>
			<cfset deleteTarget = getDeaccessionNum.deacc_number>
			<cfquery name="killDeaccession" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				delete from deaccession 
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
				<h1 class="h2">Deaccession #deleteTarget# deleted.....</h1>
				<ul>
					<li><a href="/Transactions.cfm?action=findDeaccessions">Search for Deaccessions</a>.</li>
					<li><a href="/transactions/Deaccession.cfm?action=new">Create a New Deaccession</a>.</li>
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
					<p>You cannot delete an active deaccession. This deaccession probably has specimens or
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
<cfif action is "makeDeaccession">
	<cfoutput>
		<cfif not isDefined("date_entered") OR len(date_entered) is 0 >
			<cfset date_entered = dateformat(now(),"yyyy-mm-dd") >
		</cfif>
		<cfif
			( 
				not isDefined("collection_id") OR 
				not isDefined("deacc_number") OR
				not isDefined("deacc_status") OR
				not isDefined("deacc_type") OR
				not isDefined("trans_date") OR
				not isDefined("nature_of_material")  OR
				not isDefined("deacc_reason")  OR
				not isDefined("auth_agent_id") OR
				not isDefined("rec_agent_id") OR
				not isDefined("inhouse_contact_agent_id") OR
				not isDefined("recipient_institution_agent_id") 
			) OR (
				len(collection_id) is 0 OR 
				len(deacc_number) is 0 OR
				len(deacc_status) is 0 OR
				len(deacc_type) is 0 OR
				len(trans_date) is 0 OR
				len(nature_of_material) is 0 OR
				len(deacc_reason) is 0 OR
				len(auth_agent_id) is 0 OR
				len(rec_agent_id) is 0 OR
				len(inhouse_contact_agent_id) is 0 OR
				len(recipient_institution_agent_id) is 0
			)
		>
			<!--- we shouldn't reach here, as the browser should enforce the required fields on the form before submission --->
			<h1 class="h2">One or more required fields are missing.</h1>
			<p>You must fill in Collection, Deaccession Number, Deaccession Type, Status, Received Date, Nature of Material, Deaccession Reason, Received From, In-House Authorized By, Recipient Institution, and Received By.  Use the agent <i>not applicable</i> if recipient institution or received by are not applicable to a discarded deaccession.</p>
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
			<cfquery name="newDeaccessionTrans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="newDeaccessionTrans_result">
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
					'deaccession',
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#nature_of_material#">,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_id#">
					<cfif len(#trans_remarks#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trans_remarks#">
					</cfif>
				)
			</cfquery>
			<cfquery name="newDeaccession" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="newDeaccession_result">
				INSERT INTO deaccession (
					TRANSACTION_ID
					,DEACC_TYPE
					,deacc_number
					,deacc_reason
					,DEACC_STATUS
					<cfif len(#value#) gt 0>
						,value
					</cfif>
					<cfif len(#method#) gt 0>
						,method
					</cfif>
				) VALUES (
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value='#new_transaction_id#'>
					, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value='#deacc_type#'>
					, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value='#deacc_number#'>
					, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value='#deacc_reason#'>
					, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value='#deacc_status#'>
					<cfif len(#value#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#value#">
					</cfif>
					<cfif len(#method#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#method#">
					</cfif>
				)
			</cfquery>
			<cfif isdefined("for_use_by") and len(for_use_by) gt 0>
				<cfquery name="q_forUseBy" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					INSERT INTO trans_agent (
						transaction_id,
						agent_id,
						trans_agent_role
					) values (
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#new_transaction_id#">,
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#for_use_by#">,
						'for use by')
				</cfquery>
			</cfif>
			<cfquery name="q_authAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				INSERT INTO trans_agent (
					transaction_id,
					agent_id,
					trans_agent_role
				) values (
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#new_transaction_id#">,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#auth_agent_id#">,
					'in-house authorized by')
			</cfquery>
			<cfquery name="q_recipinst" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				INSERT INTO trans_agent (
					transaction_id,
					agent_id,
					trans_agent_role
				) values (
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#new_transaction_id#">,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#recipient_institution_agent_id#">,
					'recipient institution')
			</cfquery>
			<cfif isdefined("rec_agent_id") and len(rec_agent_id) gt 0>
				<cfquery name="q_recievedby" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					INSERT INTO trans_agent (
						transaction_id,
						agent_id,
						trans_agent_role
					) values (
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#new_transaction_id#">,
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#rec_agent_id#">,
						'received by')
				</cfquery>
			</cfif>
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
			<cfif isdefined("additional_incontact_agent_id") and len(additional_incontact_agent_id) gt 0>
				<cfquery name="q_addinhousecontact" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					INSERT INTO trans_agent (
						transaction_id,
						agent_id,
						trans_agent_role
					) values (
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#new_transaction_id#">,
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#additional_incontact_agent_id#">,
						'additional in-house contact')
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
		<cflocation url="/transactions/Deaccession.cfm?action=edit&transaction_id=#new_transaction_id#" addtoken="false">
	</cfoutput>
</cfif>

<!-------------------------------------------------------------------------------------------------->
<cfinclude template="/shared/_footer.cfm">
