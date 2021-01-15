<cfset pageTitle = "Accession Management">
<cfif isdefined("action") AND action EQ 'new'>
	<cfset pageTitle = "Create New Accession">
</cfif>
<cfif isdefined("action") AND action EQ 'edit'>
	<cfset pageTitle = "Edit Accession">
	<cfif isdefined("transaction_id") >
		<cfquery name="accessionNumber" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select
				accn_number
			from
				accn
			where
				accn.transaction_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
		</cfquery>
		<cfset pageTitle = "Edit Accession #accessionNumber.loan_number#">
	</cfif>
</cfif>
<cfset MAGIC_MCZ_COLLECTION = 12>
<cfset MAGIC_MCZ_CRYO = 11>
<cfset ACCNNUMBERPATTERN = '^[0-9]+$'>
<!--
transactions/Accession.cfm

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
<cfif not isdefined('action') OR  action is "nothing">
	<!--- redirect to accession search page --->
	<cflocation url="/Transactions.cfm?action=findAccessions" addtoken="false">
</cfif>
<!-------------------------------------------------------------------------------------------------->
<cfinclude template = "/shared/_header.cfm">

<cfif not isdefined("project_id")>
	<cfset project_id = -1>
</cfif>

<!--- Accession controlled vocabularies --->
<cfquery name="ctAccnStatus" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select accn_status from ctaccn_status order by accn_status
</cfquery>
<cfquery name="ctAccnType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select accn_type from ctaccn_type order by accn_type
</cfquery>
<cfquery name="ctcollection" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select COLLECTION_CDE, INSTITUTION_ACRONYM, DESCR, COLLECTION, COLLECTION_ID, WEB_LINK,
		WEB_LINK_TEXT, CATNUM_PREF_FG, CATNUM_SUFF_FG, GENBANK_PRID, GENBANK_USERNAME,
		GENBANK_PWD, LOAN_POLICY_URL, ALLOW_PREFIX_SUFFIX, GUID_PREFIX, INSTITUTION 
	from collection order by collection
</cfquery>
<!--- Obtain list of transaction agent roles relevant to accessions --->
<cfquery name="cttrans_agent_role" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select distinct(cttrans_agent_role.trans_agent_role) 
	from cttrans_agent_role  
	left join trans_agent_role_allowed on cttrans_agent_role.trans_agent_role = trans_agent_role_allowed.trans_agent_role
	where 
		trans_agent_role_allowed.transaction_type = 'Accn'
	order by cttrans_agent_role.trans_agent_role
</cfquery>

<cfoutput>
	<script language="javascript" type="text/javascript">
		// setup date pickers
		jQuery(document).ready(function() {
			$("##rec_date").datepicker({ dateFormat: 'yy-mm-dd'});
			$("##closed_date").datepicker({ dateFormat: 'yy-mm-dd'});
		});
	</script>
</cfoutput>
<!-------------------------------------------------------------------------------------------------->
<cfif action is "new">
	<cfset title="New Accession">
	<cfoutput>
		<main class="container py-3" id="content">
			<h1 class="h2" id="newAccnFormSectionLabel" >Create New Accession <i class="fas fa-info-circle" onClick="getMCZDocs('Accession)" aria-label="help link"></i></h1>
			<div class="row border rounded bg-light mt-2 mb-4 px-2 pt-2 pb-4 pb-sm-2">
				<section class="col-12 col-sm-8 border bg-white pt-3" id="newAccnFormSection" aria-labeledby="newAccnFormSectionLabel">
					<form name="newAccession" id="newAccession" class="" action="/transactions/Accession.cfm" method="post" onSubmit="return noenter();">
						<input type="hidden" name="action" value="makeAccn">
						<div class="form-row mb-2">
							<div class="col-12 col-md-3">
								<label for="collection_id">Collection</label>
								<select name="collection_id" size="1" id="collection_id" class="reqdClr data-entry-select" required >
									<option value=""></option>
									<cfloop query="ctcollection">
										<option value="#ctcollection.collection_id#">#ctcollection.collection#</option>
									</cfloop>
								</select>
							</div>
							<div class="col-12 col-md-3">
								<label for="accn_number" class="data-entry-label">Accession Number (nnnnn)</label>
								<input type="text" name="accn_number" class="reqdClr data-entry-input" id="accn_number" required pattern="#ACCNNUMBERPATTERN#">
							</div>
							<div class="col-12 col-md-3">
								<label for="status">Status</label>
								<select name="accn_status" id="status" class="reqdClr data-entry-select" required >
									<cfloop query="ctAccnStatus">
											<cfif #ctAccnStatus.accn_status# is "in process">
												<cfset selected = "selected='selected'">
											<cfelse>
												<cfset selected="">
											</cfif>
											<option value="#ctAccnStatus.accn_status#" #selected# >#ctAccnStatus.accn_status#</option>
									</cfloop>
								</select>
							</div>
							<div class="col-12 col-md-3">
								<label for="accn_type">Accession Type</label>
								<select name="accn_type" id="accn_type" class="reqdClr data-entry-select" required >
									<option value=""></option>
									<cfloop query="ctAccnType">
											<option value="#ctAccnType.accn_type#">#ctAccnType.accn_type#</option>
									</cfloop>
								</select>
							</div>
						</div>
						<div class="form-row mb-2">
							<div class="col-12 col-md-6">
								<span>
									<label for="received_agent">Received From:</label>
									<span id="received_agent_view">&nbsp;&nbsp;&nbsp;&nbsp;</span>
								</span>
								<div class="input-group">
									<div class="input-group-prepend">
										<span class="input-group-text smaller bg-lightgreen" id="received_agent_icon"><i class="fa fa-user" aria-hidden="true"></i></span> 
									</div>
									<input name="received_agent_name" id="received_agent_name" class="reqdClr form-control data-entry-input" required >
								</div>
								<input type="hidden" name="received_agent_id" id="received_agent_id"  >
								<script>
									$(makeRichTransAgentPicker('received_agent_name', 'received_agent_id','received_agent_icon','received_agent_view',null))
								</script> 
							</div>
							<div class="col-12 col-md-6">
								<span>
									<label for="rec_agent_name">Received By:</label>
									<span id="rec_agent_view">&nbsp;&nbsp;&nbsp;&nbsp;</span>
								</span>
								<div class="input-group">
									<div class="input-group-prepend">
										<span class="input-group-text smaller bg-lightgreen" id="rec_agent_icon"><i class="fa fa-user" aria-hidden="true"></i></span> 
									</div>
									<input  name="rec_agent_name" id="rec_agent_name" class="form-control data-entry-input" >
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
									<label for="in_house_contact_agent_name">In-House Contact:</label>
									<span id="in_house_contact_agent_view">&nbsp;&nbsp;&nbsp;&nbsp;</span> 
								</span>
								<div class="input-group">
									<div class="input-group-prepend">
										<span class="input-group-text smaller bg-lightgreen" id="in_house_contact_agent_icon"><i class="fa fa-user" aria-hidden="true"></i></span> 
									</div>
									<input type="text" name="in_house_contact_agent_name" id="in_house_contact_agent_name" class="form-control data-entry-input">
								</div>
								<input type="hidden" name="in_house_contact_agent_id" id="in_house_contact_agent_id" >
								<script>
									$(makeRichTransAgentPicker('in_house_contact_agent_name','in_house_contact_agent_id','in_house_contact_agent_icon','in_house_contact_agent_view',null));
								</script> 
							</div>
							<div class="col-12 col-md-6">
								<span>
									<label for="additional_incontact_agent_name">Additional In-house Contact:</label>
									<span id="additional_incontact_agent_view">&nbsp;&nbsp;&nbsp;&nbsp;</span> 
								</span>
								<div class="input-group">
									<div class="input-group-prepend">
										<span class="input-group-text smaller bg-lightgreen" id="additional_incontact_agent_icon"><i class="fa fa-user" aria-hidden="true"></i></span> 
									</div>
									<input type="text" name="additional_incontact_agent_name" id="additional_incontact_agent_name" class="form-control data-entry-input" >
								</div>
								<input type="hidden" name="additional_incontact_agent_id" id="additional_incontact_agent_id" >
								<script>
									$(makeRichTransAgentPicker('additional_incontact_agent_name','additional_incontact_agent_id','additional_incontact_agent_icon','additional_incontact_agent_view',null));
								</script> 
							</div>
						</div>
						<div class="form-row mb-2">
							<div class="col-12 col-md-4">
								<label for="estimated_count">Estimated Count</label>
								<input type="text" name="estimated_count" id="estimated_count" value="" class="w-100 form-control data-entry-input">
							</div>
							<div class="col-12 col-md-4">
								<label for="date_received">Date Received</label>
								<input type="text" name="date_received" id="date_received" 
									required
									value="#dateformat(now(),"yyyy-mm-dd")#" 
									class="reqdClr w-100 form-control data-entry-input">
							</div>
							<div class="col-12 col-md-4">
								<label for="date_entered">Date Entered</label>
								<input type="text" name="date_entered" id="date_entered"
									disabled="true"
									value="#dateformat(now(),"yyyy-mm-dd")#" 
									class="w-100 form-control data-entry-input">
							</div>
						</div>
						<div class="form-row mb-2">
							<div class="col-12 col-md-12">
								<label for="nature_of_material">Nature of Material (<span id="length_nature_of_material"></span>)</label>
								<textarea name="nature_of_material" id="nature_of_material" rows="2" 
									onkeyup="countCharsLeft('nature_of_material', 4000, 'length_nature_of_material');"
									class="reqdClr form-control form-control-sm w-100 autogrow" 
									required ></textarea>
							</div>
						</div>
						<div class="form-row mb-2">
							<div class="col-12 col-md-12">
								<label for="trans_remarks">Internal Remarks (<span id="length_trans_remarks"></span>)</label>
								<textarea name="trans_remarks" id="trans_remarks" 
									onkeyup="countCharsLeft('trans_remarks', 4000, 'length_trans_remarks');"
									class="form-control form-control-sm w-100 autogrow" rows="2"></textarea>
							</div>
						</div>
						<div class="form-row mb-2">
							<div class="col-12 col-md-4">
                        <label for="radio1">To be MCZ cataloged</label>
                        <input type="radio" name="for_use_by" value="" checked="checked" id="radio1">
							</div>
							<div class="col-12 col-md-4">
                        <label for="radio2">For use by HMNH Exhibits</label>
                        <input type="radio" name="for_use_by" value="116195" id="radio2">
							</div>
							<div class="col-12 col-md-4">
                        <label for="radio3">For use by HMNH Education</label>
                        <input type="radio" name="for_use_by" value="91906" id="radio3">
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
								<input type="button" value="Create Accession" class="btn btn-xs btn-primary"
									onClick="if (checkFormValidity($('##newAccession')[0])) { submit();  } ">
							</div>
						</div>
					</form>
				</section>
				<!--- Begin next available number list in an aside, ml-sm-4 to provide offset from column above holding the form. --->
				<aside class="col-12 col-sm-4" aria-labeledby="nextNumberSectionLabel"> 
					<div id="nextNumDiv">
						<h3 id="nextNumberSectionLabel">Next Available Accession Number:</h3>
						<cfquery name="gnn" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							select max(to_number(accn_number)) + 1 as next_accn_num from accn 
						</cfquery>
						<nav class="nav flex-column align-items-start">
							<cfloop query="gnn">
								<button type="button" class="btn btn-xs btn-outline-primary pt-1 mt-1 px-2 w-100 text-left" onclick="$('##accn_number').val(#gnn.next_accn_num#);">#gnn.next_accn_num#</button>
							</cfloop>
						</nav>
					</div>
				</aside><!--- next number aside --->
			</div>
		</main>
	</cfoutput>
</cfif>
<!-------------------------------------------------------------------------------------------------->
<cfif action is "edit">
	<cfset title="Edit Accession">
	
	<cfif not isdefined("transaction_id") or len(transaction_id) EQ 0>
		<cfthrow message="Edit Accession called without a transaction_id for the accession to edit">
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
								loadTransactionFormMedia(#transaction_id#,"loan"); 
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
			<cfquery name="accessionDetails" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="accessionDetails_result">
				select
					trans.transaction_id,
					trans.transaction_type,
					trans_date,
					accn_number,
					accn_type,
					accn_status,
					received_date,
					nature_of_material,
					estimated_count,
					trans_remarks,
					trans.collection_id,
					collection.collection,
					concattransagent(trans.transaction_id,'entered by') enteredby
				 from
					trans
					left join accn on trans.transaction_id = accn.transaction_id 
					left join collection on trans.collection_id=collection.collection_id 
				where
					trans.transaction_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
			</cfquery>
			<cfif accessionDetails.RecordCount EQ 0 >
				<cfthrow message = "No such Accession.">
			</cfif>
			<cfif accessionDetails.RecordCount GT 0 AND accessionDetails.transaction_type NEQ 'accn'>
				<cfthrow message = "Request to edit an accession, but the provided transaction_id was for a different transaction type [#acccessionDetails.transaction_type#].">
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
<!--- TODO: Rework from here. --->
			<script>
				$(function() {
					// on page load, hide the create project from accn fields
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
		
		<main class="container py-3" id="content">
			<cftry>
				<h1 class="h2 pb-0 ml-3">Edit Accession
					<strong>#accessionDetails.collection# #accessionDetails.accn_number#</strong> 
					<i class="fas fa-info-circle" onClick="getMCZDocs('Loan_Transactions##Edit_a_Loan')" aria-label="help link"></i>
				</h1>
				<section class="row mx-0 border rounded my-2 pt-2" title="Edit Loan" >
					<form class="col-12" name="editLoanForm" id="editLoanForm" action="/transactions/Loan.cfm" method="post">
						<input type="hidden" name="method" value="saveLoan">
						<input id="action" type="hidden" name="action" value="editLoan">
						<input type="hidden" name="transaction_id" value="#accessionDetails.transaction_id#">
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
										<option <cfif ctcollection.collection_id is accessionDetails.collection_id> selected </cfif>
											value="#ctcollection.collection_id#">#ctcollection.collection#</option>
									</cfloop>
								</select>
							</div>
							<div class="col-12 col-md-3">
								<label for="loan_number" class="data-entry-label">Loan Number (yyyy-n-Coll)</label>
								<input type="text" name="loan_number" id="loan_number" value="#accessionDetails.loan_number#" class="reqdClr data-entry-input" 
									required pattern="#LOANNUMBERPATTERN#" >
							</div>
							<div class="col-12 col-md-3">
								<label for="loan_type" class="data-entry-label">Loan Type</label>
								<select name="loan_type" id="loan_type" class="reqdClr data-entry-select" required >
									<cfloop query="ctLoanType">
										<cfif ctLoanType.loan_type NEQ "transfer" OR accessionDetails.collection_id EQ MAGIC_MCZ_COLLECTION >
											<option <cfif ctLoanType.loan_type is accessionDetails.loan_type> selected="selected" </cfif>
												value="#ctLoanType.loan_type#">#ctLoanType.loan_type#</option>
										<cfelseif accessionDetails.loan_type EQ "transfer" AND accessionDetails.collection_id NEQ MAGIC_MCZ_COLLECTION >
											<option <cfif ctLoanType.loan_type is accessionDetails.loan_type> selected="selected" </cfif> value="" ></option>
										</cfif>
									</cfloop>
								</select>
							</div>
							<div class="col-12 col-md-3">
								<label for="initiating_date" class="data-entry-label">Transaction Date</label>
								<input type="text" name="initiating_date" id="initiating_date"
									value="#dateformat(accessionDetails.trans_date,"yyyy-mm-dd")#" class="reqdClr data-entry-input" required >
							</div>
						</div>
						<div class="form-row mb-1">
							<div class="col-12 col-md-3">
								<label for="loan_status" class="data-entry-label">Loan Status</label>
								<span>
									<select name="loan_status" id="loan_status" class="reqdClr data-entry-select" required >
										<!---  Normal transaction users are only allowed certain loan status state transitions, ---> 
										<!--- users with elevated privileges for loans are allowed to edit loans to place them into any state.  --->
										<cfloop query="ctLoanStatus">
											<cfif isAllowedLoanStateChange(accessionDetails.loan_status,ctLoanStatus.loan_status)  or (isdefined("session.roles") and listfindnocase(session.roles,"ADMIN_TRANSACTIONS"))  >
												<option <cfif ctLoanStatus.loan_status is accessionDetails.loan_status> selected="selected" </cfif>
													value="#ctLoanStatus.loan_status#">#ctLoanStatus.loan_status#</option>
											</cfif>
										</cfloop>
									</select>
								</span>
							</div>
							<div class="col-12 col-md-3">
								<label for="return_due_date" class="data-entry-label">Due Date</label>
								<input type="text" id="return_due_date" name="return_due_date" class="data-entry-input"
									value="#dateformat(accessionDetails.return_due_date,'yyyy-mm-dd')#">
							</div>
							<div class="col-12 col-md-3" tabindex="0">
								<span class="data-entry-label">Date Closed:</span>
								<div class="col-12 bg-light border non-field-text">
									<cfif accessionDetails.loan_status EQ 'closed' and len(accessionDetails.closed_date) GT 0>
									#accessionDetails.closed_date#
									<cfelse>
										--
									</cfif>
								</div>
							</div>
							<div class="col-12 col-md-3" tabindex="0">
								<span class="data-entry-label">Entered By</span>
								<div class="col-12 bg-light border non-field-text">
									<span id="entered_by">#accessionDetails.enteredby#</span>
								</div>
							</div>
						</div>
						<!--- Begin loan agents table: Load via ajax. --->
						<div class="form-row my-1">
							<script>
								function reloadTransactionAgents() { 
									loadAgentTable("agentTableContainerDiv",#transaction_id#,"editLoanForm",handleChange);
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
										monitorForChanges('editLoanForm',handleChange);
									});
								});
							</script>
						</div>
						<div class="form-row mb-1" id="insurance_section">
							<div class="col-12 col-md-6">
								<label for="insurance_value" class="data-entry-label">Insurance value</label>
								<input type="text" name="insurance_value" id="insurance_value" value="#accessionDetails.insurance_value#" size="40" class="data-entry-input">
							</div>
							<div class="col-12 col-md-6">
								<label for="insurance_maintained_by" class="data-entry-label">Insurance Maintained By</label>
								<input type="text" name="insurance_maintained_by" id="insurance_maintained_by" value="#accessionDetails.insurance_maintained_by#" size="40" class="data-entry-input">
							</div>
						</div>
						<div class="form-row mb-1">
							<div class="col-12">
								<!--- note, parentloan_section and subloan_section are turned on and off with javascript as loan type can change while editing --->
								<span id="parentloan_section">This is a subloan of Exhibition-Master Loan:
									<cfif parentLoan.RecordCount GT 0>
										<cfloop query="parentLoan">
											<a href="/transactions/Loan.cfm?action=editLoan&transaction_id=#parentLoan.transaction_id#">#parentLoan.loan_number#</a>
										</cfloop>
									<cfelse>
										This exhibition subloan has not been linked to a master loan.
									</cfif>
								</span>
							</div>
							<div class="col-12 mt-2">
								<span class="form-row" class="px-2" id="subloan_section">
									<img src='/shared/images/indicator.gif'>
									Loading subloans...
								</span><!--- end subloan section ---> 
								<script>
									$(document).ready(function() { 
										$('##agentTableDiv').on('domChanged',function() {
											console.log("dom change within agentTableContainerDiv");
											monitorForChanges('editLoanForm',handleChange);
										});
										loadSubLoans(#accessionDetails.transaction_id#);
									});
								</script>
							</div>
						</div>
						<div class="form-row mb-1">
							<div class="col-12 col-xl-6">
								<label for="nature_of_material" class="data-entry-label">Nature of Material (<span id="length_nature_of_material"></span>)</label>
								<textarea name="nature_of_material" id="nature_of_material" rows="1" 
									onkeyup="countCharsLeft('nature_of_material', 4000, 'length_nature_of_material');"
									class="reqdClr autogrow data-entry-textarea" required >#accessionDetails.nature_of_material#</textarea>
							</div>
							<div class="col-12 col-xl-6">
								<label for="loan_description" class="data-entry-label">Description (<span id="length_loan_description"></span>)</label>
								<textarea name="loan_description" id="loan_description" rows="1"
									onkeyup="countCharsLeft('loan_description', 4000, 'length_loan_description');"
									class="autogrow data-entry-textarea">#accessionDetails.loan_description#</textarea>
							</div>
						</div>
						<div class="form-row mb-1">
							<div class="col-12 col-xl-6">
								<label for="loan_instructions" class="data-entry-label">Loan Instructions (<span id="length_loan_instructions"></span>)</label>
								<textarea name="loan_instructions" id="loan_instructions" rows="1" 
									onkeyup="countCharsLeft('loan_instructions', 4000, 'length_loan_instructions');"
									class="autogrow data-entry-textarea">#accessionDetails.loan_instructions#</textarea>
							</div>
							<div class="col-12 col-xl-6">
								<label for="trans_remarks" class="data-entry-label">Internal Remarks (<span id="length_trans_remarks"></span>)</label>
								<textarea name="trans_remarks" id="trans_remarks" rows="1"
									onkeyup="countCharsLeft('trans_remarks', 4000, 'length_trans_remarks');"
									class="autogrow data-entry-textarea">#accessionDetails.trans_remarks#</textarea>
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
									onClick="if (checkFormValidity($('##editLoanForm')[0])) { saveEdits();  } " 
									id="submitButton" >
								<button type="button" aria-label="Print Loan Paperwork" id="loanPrintDialogLauncher"
									class="btn btn-xs btn-info mr-2" value="Print..."
									onClick=" openTransactionPrintDialog(#transaction_id#, 'Loan', 'loanPrintDialog');">Print...</button>
								<output id="saveResultDiv" class="text-danger">&nbsp;</output>	
								<input type="button" value="Delete Loan" class="btn btn-xs btn-danger float-right"
									onClick=" $('##action').val('editLoan'); confirmDialog('Delete this Loan?','Confirm Delete Loan', function() { $('##action').val('deleLoan'); $('##editLoanForm').submit(); } );">
							</div>
						</div>
						<div id="loanPrintDialog"></div>
						<script>
							$(document).ready(function() {
								monitorForChanges('editLoanForm',handleChange);
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
									data : $('##editLoanForm').serialize(),
									success : function (data) {
										$('##saveResultDiv').html('Saved.');
										$('##saveResultDiv').addClass('text-success');
										$('##saveResultDiv').removeClass('text-danger');
										$('##saveResultDiv').removeClass('text-warning');
										loadAgentTable("agentTableContainerDiv",#transaction_id#,"editLoanForm",handleChange);
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
				<section name="loanItemsSection" class="row border rounded mx-0 my-2" title="Collection Objects in this loan" tabindex="0">
					<div class="col-12 pt-3 pb-1">
						<input type="button" value="Add Items" class="btn btn-xs btn-secondary mb-2 mb-sm-0 mr-2"
							onClick="window.open('/SpecimenSearch.cfm?Action=dispCollObj&transaction_id=#transaction_id#');">
						<input type="button" value="Add Items BY Barcode" class="btn btn-xs btn-secondary mb-2 mb-sm-0 mr-2"
							onClick="window.open('/loanByBarcode.cfm?transaction_id=#transaction_id#');">
						<input type="button" value="Review Items" class="btn btn-xs btn-secondary mb-2 mb-sm-0 mr-2"
							onClick="window.open('/a_loanItemReview.cfm?transaction_id=#transaction_id#');">
						<input type="button" value="Refresh Item Count" class="btn btn-xs btn-info mb-2 mb-sm-0 mr-2"
							onClick=" updateLoanItemCount('#transaction_id#','loanItemCountDiv'); ">
					</div>
					<div class="col-12 pt-2 pb-3">
						<div id="loanItemCountDiv" tabindex="0"></div>
						<script>
							$(document).ready( updateLoanItemCount('#transaction_id#','loanItemCountDiv') );
						</script>
						<cfif accessionDetails.loan_type EQ 'consumable'>
							<h2 class="h3">Disposition of material in loan:</h2>
							<cfquery name="getDispositions" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
								select count(loan_item.collection_object_id) as pcount, coll_obj_disposition, deacc_number, deacc_type, deacc_status
								from loan 
									left join loan_item on loan.transaction_id = loan_item.transaction_id
									left join coll_object on loan_item.collection_object_id = coll_object.collection_object_id
									left join deacc_item on loan_item.collection_object_id = deacc_item.collection_object_id
									left join deaccession on deacc_item.transaction_id = deaccession.transaction_id
								where loan.transaction_id = <cfqueryparam CFSQLType="CF_SQL_DECIMAL" value="#accessionDetails.transaction_id#">
									and coll_obj_disposition is not null
								group by coll_obj_disposition, deacc_number, deacc_type, deacc_status
							</cfquery>
							<cfif getDispositions.RecordCount EQ 0 >
								<h4>There are no attached collection objects.</h4>
							<cfelse>
								<table class="table table-responsive">
									<thead class="thead-light">
										<tr>
											<th>Parts</th>
											<th>Disposition</th>
											<th>Deaccession</th>
										</tr>
									</thead>
									<tbody>
										<cfloop query="getDispositions">
											<tr>
												<cfif len(trim(getDispositions.deacc_number)) GT 0>
													<td>#pcount#</td>
													<td>#coll_obj_disposition#</td>
													<td><a href="Deaccession.cfm?action=listDeacc&deacc_number=#deacc_number#">#deacc_number# (#deacc_status#)</a></td>
												<cfelse>
													<td>#pcount#</td>
													<td>#coll_obj_disposition#</td>
													<td>Not in a Deaccession</td>
												</cfif>
											</tr>
										</cfloop>
									</tbody>
								</table>
							</cfif>
						</cfif>
					</div>
				</section>
				<section class="row mx-0">
					<div class="col-12 mt-3 mb-4 border rounded px-2 pb-2 bg-grayish">
						<section name="mediaSection" class="row mx-0 border rounded bg-light my-2" tabindex="0">
							<div class="col-12">
								<h2 class="h3">
									Media documenting this Loan 
									<span class="mt-1 smaller d-block">Include copies of signed loan invoices and correspondence here.  Attach permits to shipments.</span>
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
										media_relationship like '% loan' and
										related_primary_key=<cfqueryparam value="#transaction_id#" cfsqltype="CF_SQL_DECIMAL">
								</cfquery>
								<span>
									<cfset relation="documents loan">
									<input type='button' onClick="opencreatemediadialog('newMediaDlg_#transaction_id#','Loan: #accessionDetails.loan_number#','#transaction_id#','#relation#',reloadTransMedia);" value='Create Media' class='btn btn-xs btn-secondary' >
									&nbsp; 
									<span id='addMedia_#transaction_id#'>
										<input type='button' onClick="openlinkmediadialog('newMediaDlg_#transaction_id#','Loan: #accessionDetails.loan_number#','#transaction_id#','#relation#',reloadTransMedia);" value='Link Media' class='btn btn-xs btn-secondary' >
									&nbsp; 
									</span> 
								</span>
								<div id="addMediaDlg_#transaction_id#" class="my-2"></div>
								<div id="newMediaDlg_#transaction_id#" class="my-2"></div>
								<div id="transactionFormMedia" class="my-2"><img src='/shared/images/indicator.gif'> Loading Media....</div>
								<script>
									// callback for ajax methods to reload from dialog
									function reloadTransMedia() { 
										loadTransactionFormMedia(#transaction_id#,"loan");
										if ($("##addMediaDlg_#transaction_id#").hasClass('ui-dialog-content')) {
											$('##addMediaDlg_#transaction_id#').html('').dialog('destroy');
										}
									};
									$( document ).ready(loadTransactionFormMedia(#transaction_id#,"loan"));
								</script>
							</div> 
						</section>
						<section name="shipmentSection" class="row mx-0 border bg-light rounded my-2" tabindex="0">
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
									where transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#accessionDetails.transaction_id#">
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
						<section name="countriesOfOriginSection" class="row mx-0 border bg-light rounded mt-2">
							<div class="col-12 pb-3" tabindex="0">
								<h2 class="h3">Countries of Origin of items in this loan</h2>
								<cfquery name="ctSovereignNation" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
									select count(*) as ct, sovereign_nation 
									from loan_item 
										left join specimen_part on loan_item.collection_object_id = specimen_part.collection_object_id
										left join cataloged_item on specimen_part.derived_from_cat_item = cataloged_item.collection_object_id
										left join collecting_event on cataloged_item.collecting_event_id = collecting_event.collecting_event_id
										left join locality on collecting_event.locality_id = locality.locality_id
									where
										loan_item.transaction_id =  <cfqueryparam cfsqltype="cf_sql_number" value="#transaction_id#" >
									group by sovereign_nation
								</cfquery>
								<cfset sep="">
								<cfif ctSovereignNation.recordcount EQ 0>
									<span class="var-display">None</span>
								<cfelse>
									<cfloop query=ctSovereignNation>
										<cfif len(sovereign_nation) eq 0>
											<cfset sovereign_nation = '[no value set]'>
										</cfif>
										<span class="var-display">#sep##sovereign_nation#&nbsp;(#ct#)</span>
										<cfset sep="; ">
									</cfloop>
								</cfif>
							</div>
						</section>
						<div class="row mx-0">
							<section title="Accessions associated with material in this loan" name="accessionsSection" class="mt-2 float-left col-12 col-md-6 p-0 pr-md-1" tabindex="0">
								<div class="border bg-light float-left pl-2 pb-0 h-100 w-100 rounded">
									<div>
										<h2 class="h3 pl-2">Accessions of material in this loan</h2>
										<!--- List Accessions for collection objects included in the Loan --->
										<cfquery name="getAccessions" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
											select distinct accn.accn_type, accn.received_date, accn.accn_number, accn.transaction_id 
											from loan l
												left join loan_item li on l.transaction_id = li.transaction_id
												left join specimen_part sp on li.collection_object_id = sp.collection_object_id
												left join cataloged_item ci on sp.derived_from_cat_item = ci.collection_object_id
												left join accn on ci.accn_id = accn.transaction_id
											where li.transaction_id = <cfqueryparam CFSQLType="CF_SQL_DECIMAL" value="#accessionDetails.transaction_id#">
										</cfquery>
										<ul class="ml-1 pl-4 pr-2 list-style-disc">
											<cfloop query="getAccessions">
												<li class="accn2">
													<a class="font-weight-bold" href="editAccn.cfm?Action=edit&transaction_id=#transaction_id#"><span>Accession ##</span>#accn_number#</a>, <span>Type:</span> #accn_type#, <span>Received: </span>#dateformat(received_date,'yyyy-mm-dd')# <cfquery name="getAccnPermits" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
														select distinct permit_num, permit_type, specific_type, issued_date, permit_id, IssuedByAgent
														from (
															select permit_num, permit.permit_type as permit_type, permit.specific_type as specific_type, issued_date, permit.permit_id as permit_id,
																issuedBy.agent_name as IssuedByAgent
															from permit_trans 
																left join permit on permit_trans.permit_id = permit.permit_id
																left join ctspecific_permit_type on permit.specific_type = ctspecific_permit_type.specific_type
																left join preferred_agent_name issuedBy on permit.issued_by_agent_id = issuedBy.agent_id
															where permit_trans.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value=#transaction_id#>
																and ctspecific_permit_type.accn_show_on_shipment = 1
														union
															select permit_num, permit.permit_type as permit_type, permit.specific_type as specific_type, issued_date, permit.permit_id as permit_id,
																issuedBy.agent_name as IssuedByAgent
															from shipment
																left join permit_shipment on shipment.shipment_id = permit_shipment.shipment_id
																left join permit on permit_shipment.permit_id = permit.permit_id
																left join ctspecific_permit_type on permit.specific_type = ctspecific_permit_type.specific_type
																left join preferred_agent_name issuedBy on permit.issued_by_agent_id = issuedBy.agent_id
															where shipment.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value=#transaction_id#>
																and ctspecific_permit_type.accn_show_on_shipment = 1
														)
														where permit_id is not null
														order by permit_type, issued_date
													</cfquery>
													<cfif getAccnPermits.recordcount gt 0>
														<ul class="list-style-circle pl-4 pr-2">
															<cfloop query="getAccnPermits">
																<li>
																	<span style="font-weight:bold;">#permit_type#:</span> 
																	#specific_type# #permit_num#, 
																	<span>Issued:</span> #dateformat(issued_date,'yyyy-mm-dd')# <span>by</span> #IssuedByAgent# 
																	<a href="/transactions/Permit.cfm?action=edit&permit_id=#permit_id#" target="_blank">Edit</a>
																</li>
															</cfloop>
														</ul>
													</cfif>
												</li>
											</cfloop>
										</ul>
									</div>
								</div>
							</section>	
							<!--- Print permits associated with these accessions --->
							<section title="Permissions And Rights Documents from Accessions and Shipments" class="mt-2 float-left col-12 col-md-6 pl-md-1 p-0" tabindex="0">
								<div class="border bg-light float-left pl-3 py-0 h-100 w-100 rounded">
									<div>
										<h2 class="h3">
											Permissions and Rights Documents 
											<span class="smaller d-block mt-1">PDF copies of Permits from Accessions and Shipments of this Loan</span>
										</h2>
										<cfquery name="getPermitMedia" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
											select distinct media_id, uri, permit_type, specific_type, permit_num, permit_title, show_on_shipment 
											from (
												select 
													mczbase.get_media_id_for_relation(p.permit_id, 'shows permit','application/pdf') as media_id,
													mczbase.get_media_uri_for_relation(p.permit_id, 'shows permit','application/pdf') as uri,
													p.permit_type, p.permit_num, p.permit_title, p.specific_type,
													ctspecific_permit_type.accn_show_on_shipment as show_on_shipment
												from loan_item li
													left join specimen_part sp on li.collection_object_id = sp.collection_object_id
													left join cataloged_item ci on sp.derived_from_cat_item = ci.collection_object_id
													left join accn on ci.accn_id = accn.transaction_id
													left join permit_trans on accn.transaction_id = permit_trans.transaction_id
													left join permit p on permit_trans.permit_id = p.permit_id
													left join ctspecific_permit_type on p.specific_type = ctspecific_permit_type.specific_type
												where li.transaction_id = <cfqueryparam CFSQLType="CF_SQL_DECIMAL" value="#accessionDetails.transaction_id#">
												union
												select 
													mczbase.get_media_id_for_relation(p.permit_id, 'shows permit','application/pdf') as media_id,
													mczbase.get_media_uri_for_relation(p.permit_id, 'shows permit','application/pdf') as uri,
													p.permit_type, p.permit_num, p.permit_title, p.specific_type,
													ctspecific_permit_type.accn_show_on_shipment as show_on_shipment
												from loan_item li
													left join specimen_part sp on li.collection_object_id = sp.collection_object_id
													left join cataloged_item ci on sp.derived_from_cat_item = ci.collection_object_id
													left join shipment on ci.accn_id = shipment.transaction_id
													left join permit_shipment on shipment.shipment_id = permit_shipment.shipment_id
													left join permit p on permit_shipment.permit_id = p.permit_id
													left join ctspecific_permit_type on p.specific_type = ctspecific_permit_type.specific_type
												where li.transaction_id = <cfqueryparam CFSQLType="CF_SQL_DECIMAL" value="#accessionDetails.transaction_id#">
												union
												select 
													mczbase.get_media_id_for_relation(p.permit_id, 'shows permit','application/pdf') as media_id, 
													mczbase.get_media_uri_for_relation(p.permit_id, 'shows permit','application/pdf') as uri,
													p.permit_type, p.permit_num, p.permit_title, p.specific_type, 1 as show_on_shipment
												from shipment s
													left join permit_shipment ps on s.shipment_id = ps.shipment_id
													left join permit p on ps.permit_id = p.permit_id
												where s.transaction_id = <cfqueryparam CFSQLType="CF_SQL_DECIMAL" value="#accessionDetails.transaction_id#">
											) where permit_type is not null
										</cfquery>
										<cfset uriList = ''>
										<div id="transPermitMediaListDiv">
											<ul class="pl-4 pr-0 list-style-disc" tabindex="0">
												<cfloop query="getPermitMedia">
													<cfif media_id is ''>
														<li class="">#permit_type# #specific_type# #permit_num# #permit_title# (no pdf)</li>
													<cfelse>
														<cfif show_on_shipment EQ 1>
															<li class=""><a href="#uri#">#permit_type# #permit_num#</a> #permit_title#</li>
															<cfset uriList = ListAppend(uriList,uri)>
														<cfelse>
															<li class=""><a href="#uri#">#permit_type# #permit_num#</a> #permit_title# (not included in PDF of All)</li>
														</cfif>
													</cfif>
												</cfloop>
											</ul>
										</div>
									</div>
									<cfif ListLen(uriList,',',false) gt 0 >
										
										<a href="/Reports/combinePermits.cfm?transaction_id=#accessionDetails.transaction_id#" class="font-weight-bold pl-2 d-block mb-3">PDF of All Permission and Rights documents</a>
											
									</cfif>
								</div>
							</section>
						</div>
						<section title="Projects" class="row mx-0 border rounded bg-light mt-2 mb-0 pb-2" tabindex="0">
							<div class="col-12 pb-0 px-0">
								<h2 class="h3 px-3">
									Projects associated with this loan
									<i class="fas fas-info fa-info-circle" onClick="getMCZDocs('Loan_Transactions##Projects_and_Permits')" aria-label="help link for projects"></i>
								</h2>
								<div id="projectsDiv" class="mx-3"></div>
								<script>
									$(document).ready( 
										loadProjects('projectsDiv',#accessionDetails.transaction_id#) 
									);
									function reloadTransProjects() {
										loadProjects('projectsDiv',#accessionDetails.transaction_id#);
									} 
								</script>
								<div class="col-12 my-2">
									<button type="button" aria-label="Link this loan to an existing Project" id="linkProjectDialogLauncher"
											class="btn btn-xs btn-secondary mr-2" value="Link to Project"
											onClick=" openTransProjectLinkDialog(#transaction_id#, 'projectsLinkDialog','projectsDiv');">Link To Project</button>
									<button type="button" aria-label="Create a new Project linked to this loan" id="newProjectDialogLauncher"
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
<cfif Action is "deleLoan">
	<cftry>
		<cftransaction>
			<cfquery name="killLoan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				delete from loan 
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
		<section class="container">
			<h1 class="h2">Loan deleted.....</h1>
			<ul>
				<li><a href="/Transactions.cfm?action=findLoans">Search for Loans</a>.</li>
				<li><a href="/transactions/Loan.cfm?action=newLoan">Create a New Loan</a>.</li>
			</ul>
		</section>
	<cfcatch>
		<section class="container">
			<div class="row">
				<div class="col-10 mx-5">
				<div class="alert alert-danger" role="alert">
					<img src="/shared/images/Process-stop.png" alt="[ Error ]" style="float:left; width: 50px;margin-right: 1em;">
					<h1 class="h2">DELETE FAILED</h1>
					<p>You cannot delete an active loan. This loan probably has specimens or
						other transactions attached. Use your back button.</p>
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
<cfif Action is "delePermit">
	<cfquery name="killPerm" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		DELETE FROM permit_trans 
		where transaction_id = <cfqueryparam CFSQLType="CF_SQL_DECIMAL" value="#transaction_id#">
				AND permit_id = <cfqueryparam CFSQLType="CF_SQL_DECIMAL" value="#permit_id#">
	</cfquery>
	<cflocation url="/transactions/Loan.cfm?Action=editLoan&transaction_id=#transaction_id#">
</cfif>
<!-------------------------------------------------------------------------------------------------->
<cfif action is "makeAccn">
	<cfoutput>
		<cfif
			len(collection_id) is 0 OR
			len(accn_number) is 0 OR
			len(accn_status) is 0 OR
			len(rec_date) is 0 OR
			len(nature_of_material) is 0 OR
			len(accn_type) is 0 OR
			len(received_agent_id) is 0
		>
			<br>
			One or more required fields are missing.<br>
			You must fill in Collection, Accn Number, Status, Date Received, Nature of Material, Received From, and Accn Type. <br>
			Use your browser's back button to fix the problem and try again.
			<cfabort>
		</cfif>
		<cfif not isDefined("ent_date") OR len(ent_date) is 0>
		<cfelse>
			<cfset initiating_date = ent_date>
		</cfif>
		<cftransaction>
			<cfquery name="obtainTransNumber" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="obtainTransNumber_result">
				select sq_transaction_id.nextval as trans_id from dual
			</cfquery>
			<cfloop query="obtainTransNumber">
				<cfset new_transaction_id = obtainTransNumber.trans_id>
			</cfloop>
			<cfquery name="newAccnTrans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="newAccnTrans_result">
				INSERT INTO trans (
					TRANSACTION_ID,
					TRANS_DATE,
					CORRESP_FG,
					TRANSACTION_TYPE,
					NATURE_OF_MATERIAL,
					collection_id
					<cfif len(#trans_remarks#) gt 0>
						,trans_remarks
					</cfif>)
				VALUES (
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#new_transaction_id#">,
					<cfqueryparam cfsqltype="CF_SQL_TIMESTAMP" value="#initiating_date#">,
					0,
					'loan',
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#nature_of_material#">,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_id#">
					<cfif len(#trans_remarks#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trans_remarks#">
					</cfif>
					)
			</cfquery>
			<cfquery name="newAccn" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="newAccn_result">
				INSERT INTO accn (
					TRANSACTION_ID,
					ACCN_TYPE
					,accn_number
					,RECEIVED_DATE,
					ACCN_STATUS,
					estimated_count
					)
				VALUES (
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value='#n.n#'>
					, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value='#accn_type#'>
					, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value='#accn_number#'>
					, <cfqueryparam cfsqltype="CF_SQL_TIMESTAMP" value='#dateformat(rec_Date,"yyyy-mm-dd")#'>
					, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value='#accn_status#'>
					<cfif len(estimated_count) gt 0>
						, <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value='#estimated_count#'>
					<cfelse>
						, null
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
			<cfquery name="q_recFromAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				INSERT INTO trans_agent (
					transaction_id,
					agent_id,
					trans_agent_role
				) values (
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#new_transaction_id#">,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#received_agent_id#">,
					'received from')
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
		</cftransaction>
		<cflocation url="/transactions/Accession.cfm?Action=edit&transaction_id=#new_transaction_id#" addtoken="false">
	</cfoutput>
</cfif>

<!-------------------------------------------------------------------------------------------------->
<cfinclude template="/shared/_footer.cfm">
