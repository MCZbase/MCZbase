<cfset pageTitle = "Manage Loan">
<cfif isdefined("action") AND action EQ 'newLoan'>
	<cfset pageTitle = "Create Loan">
</cfif>
<cfif isdefined("action") AND action EQ 'edit'>
	<cfset action="editLoan">
</cfif>
<cfif isdefined("action") AND action EQ 'editLoan'>
	<cfset pageTitle = "Edit Loan">
	<cfif isdefined("transaction_id") >
		<cfquery name="loanNumber" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select
				loan_number
			from
				loan
			where
				loan.transaction_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
		</cfquery>
		<cfset pageTitle = " #loanNumber.loan_number# Edit Loan">
	</cfif>
</cfif>
<cfset MAGIC_MCZ_COLLECTION = 12>
<cfset MAGIC_MCZ_CRYO = 11>
<cfset LOANNUMBERPATTERN = '^[12][0-9]{3}-[-0-9a-zA-Z]+-[A-Z][a-zA-Z]+$'>
<!--
transactions/Loan.cfm

Copyright 2008-2017 Contributors to Arctos
Copyright 2008-2020 President and Fellows of Harvard College

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
	<!--- redirect to loan search page --->
	<cflocation url="/Transactions.cfm?action=findLoans" addtoken="false">
</cfif>
<!-------------------------------------------------------------------------------------------------->
<cfinclude template = "/shared/_header.cfm">

<cfif not isdefined("project_id")>
	<cfset project_id = -1>
</cfif>

<!--- Loan types --->
<cfquery name="ctLoanType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select loan_type from ctloan_type order by ordinal asc, loan_type
</cfquery>
<cfquery name="ctLoanStatus" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select loan_status from ctloan_status order by loan_status
</cfquery>
<!--- Obtain list of transaction agent roles relevant to loan editing --->
<cfquery name="cttrans_agent_role" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select distinct(cttrans_agent_role.trans_agent_role) 
	from cttrans_agent_role  
	left join trans_agent_role_allowed on cttrans_agent_role.trans_agent_role = trans_agent_role_allowed.trans_agent_role
	where 
		trans_agent_role_allowed.transaction_type = 'Loan'
	order by cttrans_agent_role.trans_agent_role
</cfquery>
<cfquery name="ctcollection" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select COLLECTION_CDE, INSTITUTION_ACRONYM, DESCR, COLLECTION, COLLECTION_ID, WEB_LINK,
		WEB_LINK_TEXT, CATNUM_PREF_FG, CATNUM_SUFF_FG, GENBANK_PRID, GENBANK_USERNAME,
		GENBANK_PWD, LOAN_POLICY_URL, ALLOW_PREFIX_SUFFIX, GUID_PREFIX, INSTITUTION 
	from collection order by collection
</cfquery>
<cfscript>
	function isAllowedLoanStateChange(oldState, newState) {
		if (oldState eq newState) return True;
		if (newState.length() eq 0) return False;

		if (left(oldState,4) eq 'open' and newState eq 'closed') { return True; }

		if (oldState eq 'in process' and newState eq 'open') { return True; }
		if (oldState eq 'in process' and newState eq 'open in-house') { return True; }

		if (oldState eq 'open' and newState eq 'open partially returned') { return True; }
		if (oldState eq 'open' and newState eq 'open under-review') { return True; }

		if (oldState eq 'open in-house' and newState eq 'open partially returned') { return True; }
		if (oldState eq 'open in-house' and newState eq 'open under-review') { return True; }

		if (oldState eq 'open partially returned' and newState eq 'open under-review') { return True; }

		return False;
	}
</cfscript>

<cfoutput>
	<script language="javascript" type="text/javascript">
		// setup date pickers
		jQuery(document).ready(function() {
			$("##trans_date").datepicker({ dateFormat: 'yy-mm-dd'});
			$("##to_trans_date").datepicker({ dateFormat: 'yy-mm-dd'});
			$("##return_due_date").datepicker({ dateFormat: 'yy-mm-dd'});
			$("##to_return_due_date").datepicker({ dateFormat: 'yy-mm-dd'});
			$("##closed_date").datepicker({ dateFormat: 'yy-mm-dd'});
			$("##to_closed_date").datepicker({ dateFormat: 'yy-mm-dd'});
			$("##initiating_date").datepicker({ dateFormat: 'yy-mm-dd'});
			$("##shipped_date").datepicker({ dateFormat: 'yy-mm-dd'});
		});
		// Set the loan number and collection for a loan.
		function setLoanNum(cid,loanNum) {
			$("##loan_number").val(loanNum);
			$("##collection_id").val(cid);
			$("##collection_id").change();
			if (cid==#MAGIC_MCZ_CRYO#) {
				$("##loan_instructions").val( $("##loan_instructions").val() + "If not all the genetic material is consumed, any unused portion must be returned to the MCZ-CRYO after the study is complete. Grantees may be requested to return extracts derived from granted samples (e.g., DNA). Publications should include a table that lists MCZ voucher numbers and acknowledge the MCZ departmental collection (i.e., Ornithology) and MCZ-CRYO for providing samples. Grantees must provide reprints of any publications to the MCZ-CRYO. In addition, GenBank, NCBI BioProject, NBCI BioSample or other accession numbers for published sequence data must be submitted to officially close the loan. Genetic samples and their derivatives cannot be distributed to other researchers without MCZ permission.");
				$("##loan_instructions").trigger("keyup");
			}
		}
	</script>
</cfoutput>
<!-------------------------------------------------------------------------------------------------->
<cfif  action is "newLoan">
	<cfset title="New Loan">
	<cfoutput>
		<main class="container py-3" id="content" aria-labelledby="newLoanFormSectionLabel">
			<h1 class="h2" id="newLoanFormSectionLabel" >Create New Loan <i class="fas fa-info-circle" onClick="getMCZDocs('Loan_Transactions##Create_a_New_Loan')" aria-label="help link"></i></h1>
			<div class="row border rounded bg-light mt-2 mb-4 px-2 pt-2 pb-4 pb-sm-2">
					<!--- Begin next available number list in an aside, ml-sm-4 to provide offset from column above holding the form. --->
				<section class="col-12" aria-labeledby="nextNumberSectionLabel"> 
					<div id="nextNumDiv">
						<h2 class="h4 mx-2 mb-1" id="nextNumberSectionLabel" title="Click on a collection button and the next available loan number in the database will be entered">Next Available Loan Number:</h2>
						<!--- Find list of all non-observational collections --->
						<cfquery name="loanableCollections" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							select collection_id, collection_cde, collection from collection 
							where collection not like '% Observations'
							order by collection 
						</cfquery>
						<div class="flex-row float-left mb-1">
						<cfloop query="loanableCollections">
							<cftry>
								<!---- Loan numbers follow yyyy-n-CCDE format, obtain highest n for current year for each collection. --->
								<cfquery name="nextNumberQuery" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
									select
									'#dateformat(now(),"yyyy")#-' || nvl( max(to_number(substr(loan_number,instr(loan_number,'-')+1,instr(loan_number,'-',1,2)-instr(loan_number,'-')-1) + 1)) , 1) || '-#collection_cde#' as nextNumber
									from
										loan,
										trans,
										collection
									where
										loan.transaction_id=trans.transaction_id 
										AND trans.collection_id=collection.collection_id
										AND collection.collection_id = <cfqueryparam value="#collection_id#" cfsqltype="CF_SQL_DECIMAL">
										AND substr(loan_number, 1,4) ='#dateformat(now(),"yyyy")#'
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
								<button type="button" class="btn btn-xs btn-outline-primary float-left mx-1 pt-1 mb-2 px-2 w-auto text-left" onclick="setLoanNum('#collection_id#','#nextNumberQuery.nextNumber#')">#collection# #nextNumberQuery.nextNumber#</button>
							<cfelse>
								<span style="font-size:x-small"> No data available for #collection#. </span>
							</cfif>
						</cfloop>
						</div>
					</div>
				</section><!--- next number section --->
				<section class="col-12 border bg-white pt-3" id="newLoanFormSection" aria-labeledby="newLoanFormSectionLabel" title="Form for creating a new loan">
					<form name="newloan" id="newLoan" class="" action="/transactions/Loan.cfm" method="post" onSubmit="return noenter();">
						<input type="hidden" name="action" value="makeLoan">
						<div class="form-row mb-2">
							<div class="col-12 col-sm-6 col-xl-3">
								<label for="collection_id" class="data-entry-label">Collection</label>
								<select name="collection_id" size="1" id="collection_id" class="reqdClr data-entry-select mb-1">
									<cfloop query="ctcollection">
										<option value="#ctcollection.collection_id#">#ctcollection.collection#</option>
									</cfloop>
								</select>
							</div>
							<div class="col-12 col-sm-6 col-xl-3">
								<label for="loan_number" class="data-entry-label">Loan Number (yyyy-n-Coll)</label>
								<input type="text" name="loan_number" class="reqdClr data-entry-input mb-1" id="loan_number" required pattern="#LOANNUMBERPATTERN#">
							</div>
							<div class="col-12 col-sm-6 col-xl-3">
								<label for="loan_type" class="data-entry-label">Loan Type</label>
								<select name="loan_type" id="loan_type" class="reqdClr data-entry-select mb-1" required >
									<cfloop query="ctLoanType">
										<option value="#ctLoanType.loan_type#">#ctLoanType.loan_type#</option>
									</cfloop>
								</select>
							</div>
							<div class="col-12 col-sm-6 col-xl-3">
								<label for="loan_status" class="data-entry-label">Loan Status</label>
								<select name="loan_status" id="loan_status" class="reqdClr data-entry-select mb-1" required >
									<cfloop query="ctLoanStatus">
										<cfif isAllowedLoanStateChange('in process',ctLoanStatus.loan_status) >
											<cfif #ctLoanStatus.loan_status# is "in process">
												<cfset selected = "selected='selected'">
											<cfelse>
												<cfset selected="">
											</cfif>
											<option value="#ctLoanStatus.loan_status#" #selected# >#ctLoanStatus.loan_status#</option>
										</cfif>
									</cfloop>
								</select>
							</div>
						</div>
						<div class="form-row mb-2">
							<div class="col-12 col-sm-6 col-xl-3">
								<span>
									<label for="auth_agent_name" class="data-entry-label">
										In-House Authorized By
										<span id="auth_agent_view">&nbsp;&nbsp;&nbsp;&nbsp;</span>
									</label>
								</span>
								<div class="input-group mb-1">
									<div class="input-group-prepend">
										<span class="input-group-text smaller bg-lightgreen" id="auth_agent_icon"><i class="fa fa-user" aria-hidden="true"></i></span> 
									</div>
									<input name="auth_agent_name" id="auth_agent_name" class="reqdClr form-control form-control-sm data-entry-input" required >
								</div>
								<input type="hidden" name="auth_agent_id" id="auth_agent_id"  >
								<script>
									$(makeRichTransAgentPicker('auth_agent_name', 'auth_agent_id','auth_agent_icon','auth_agent_view',null))
								</script> 
							</div>
							<div class="col-12 col-sm-6 col-xl-3">
								<span>
									<label for="rec_agent_name" class="data-entry-label">
										Received By:
										<span id="rec_agent_view">&nbsp;&nbsp;&nbsp;&nbsp;</span>
									</label>
								</span>
								<div class="input-group mb-1">
									<div class="input-group-prepend">
										<span class="input-group-text smaller bg-lightgreen" id="rec_agent_icon"><i class="fa fa-user" aria-hidden="true"></i></span> 
									</div>
									<input  name="rec_agent_name" id="rec_agent_name" class="reqdClr form-control form-control-sm data-entry-input" required >
								</div>
								<input type="hidden" name="rec_agent_id" id="rec_agent_id" >
								<script>
									$(makeRichTransAgentPicker('rec_agent_name','rec_agent_id','rec_agent_icon','rec_agent_view',null));
								</script> 
							</div>
				
							<div class="col-12 col-sm-6 col-xl-3">
								<span>
									<label for="in_house_contact_agent_name" class="data-entry-label">
										In-House Contact:
										<span id="in_house_contact_agent_view">&nbsp;&nbsp;&nbsp;&nbsp;</span> 
									</label>
								</span>
								<div class="input-group mb-1">
									<div class="input-group-prepend">
										<span class="input-group-text smaller bg-lightgreen" id="in_house_contact_agent_icon"><i class="fa fa-user" aria-hidden="true"></i></span> 
									</div>
									<input type="text" name="in_house_contact_agent_name" id="in_house_contact_agent_name" class="reqdClr form-control form-control-sm data-entry-input" required >
								</div>
								<input type="hidden" name="in_house_contact_agent_id" id="in_house_contact_agent_id" >
								<script>
									$(makeRichTransAgentPicker('in_house_contact_agent_name','in_house_contact_agent_id','in_house_contact_agent_icon','in_house_contact_agent_view',null));
								</script> 
							</div>
							<div class="col-12 col-sm-6 col-xl-3"> 
								<span>
									<label for="recipient_institution_agent_name" class="data-entry-label">
										Recipient Institution:
										<span id="recipient_institution_agent_view">&nbsp;&nbsp;&nbsp;&nbsp;</span> 
									</label>
								</span>
								<div class="input-group mb-1">
									<div class="input-group-prepend">
										<span class="input-group-text smaller bg-lightgreen" id="recipient_institution_agent_icon"><i class="fa fa-user" aria-hidden="true"></i></span> 
									</div>
									<input type="text" name="recipient_institution_agent_name"  id="recipient_institution_agent_name" class="reqdClr form-control form-control-sm data-entry-input" required >
								</div>
								<input type="hidden" name="recipient_institution_agent_id"  id="recipient_institution_agent_id" >
								<script>
									$(makeRichTransAgentPickerConstrained('recipient_institution_agent_name','recipient_institution_agent_id','recipient_institution_agent_icon','recipient_institution_agent_view',null,'organization_agent'));
								</script> 
							</div>
						</div>
						<div class="form-row mb-2">
							<div class="col-12 col-sm-6 col-xl-3">
								<span>
									<label for="additional_incontact_agent_name" class="data-entry-label">
										Additional In-house Contact:
										<span id="additional_incontact_agent_view">&nbsp;&nbsp;&nbsp;&nbsp;</span> 
									</label>
								</span>
								<div class="input-group mb-1">
									<div class="input-group-prepend">
										<span class="input-group-text smaller bg-lightgreen" id="additional_incontact_agent_icon"><i class="fa fa-user" aria-hidden="true"></i></span> 
									</div>
									<input type="text" name="additional_incontact_agent_name" id="additional_incontact_agent_name" class="form-control form-control-sm data-entry-input" >
								</div>
								<input type="hidden" name="additional_incontact_agent_id" id="additional_incontact_agent_id" >
								<script>
									$(makeRichTransAgentPicker('additional_incontact_agent_name','additional_incontact_agent_id','additional_incontact_agent_icon','additional_incontact_agent_view',null));
								</script> 
							</div>
							<div class="col-12 col-sm-6 col-xl-3"> 
								<span>
									<label for="foruseby_agent_name" class="data-entry-label">
										For Use By:
										<span id="foruseby_agent_view">&nbsp;&nbsp;&nbsp;&nbsp;</span> 
									</label>
								</span>
								<div class="input-group mb-1">
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
							<div class="col-12 col-sm-6 col-xl-3">
								<label for="initiating_date" class="data-entry-label">Transaction Date</label>
								<input type="text" name="initiating_date" id="initiating_date" value="#dateformat(now(),"yyyy-mm-dd")#" class="w-100 form-control form-control-sm data-entry-input mb-1">
							</div>
							<div class="col-12 col-sm-6 col-xl-3">
								<label for="return_due_date" class="data-entry-label">Return Due Date</label>
								<input type="text" name="return_due_date" id="return_due_date" value="#dateformat(dateadd("m",6,now()),"yyyy-mm-dd")#" class="w-100 form-control form-control-sm data-entry-input mb-1" >
							</div>
						</div>
						<div class="form-row mb-2" id="insurance_section">
							<div class="col-12 col-md-4">
								<label for="insurance_value" class="data-entry-label">Insurance value</label>
								<input type="text" name="insurance_value" id="insurance_value" value="" class="data-entry-input mb-1">
							</div>
							<div class="col-12 col-md-6">
								<label for="insurance_maintained_by" class="data-entry-label">Insurance Maintained By</label>
								<input type="text" name="insurance_maintained_by" id="insurance_maintained_by" value="" class="data-entry-input mb-1">
							</div>
						</div>
						<script>
							$(document).ready(function() {
								// on page load, hide the insurance section.
								$("##insurance_section").hide();
								// on page load, remove transfer and exhibition-master from the list of loan/gift types
								$("##loan_type option[value='transfer']").each(function() { $(this).remove(); } );
								$("##loan_type option[value='exhibition-master']").each(function() { $(this).remove(); } );
								// on page load, bind a function to collection_id to change the list of loan types
								// based on the selected collection
								$("##collection_id").change( function () {
									if ( $("##collection_id option:selected").text() == "MCZ Collections" ) {
										// only MCZ collections (the non-specimen collection) is allowed to be exhibition-masters (but only add once).
										if ($("##loan_type option[value='exhibition-master']").length < 1) { 
											$("##loan_type").append($("<option></option>").attr("value",'exhibition-master').text('exhibition-master'));
										}
									} else {
										$("##loan_type option[value='exhibition-master']").each(function() { $(this).remove(); } );
										$("##insurance_section").hide();
									}
								});
								// on page load, bind a function to loan_type to hide/show the insurance section.
								$("##loan_type").change( function () {
									if ($("##loan_type").val() == "exhibition-master") {
										$("##insurance_section").show();
										$("##return_due_date").datepicker('option','disabled',false);
									} else if ($("##loan_type").val() == "exhibition-subloan") {
										$("##insurance_section").hide();
										$("##return_due_date").datepicker('option','disabled',true);
									} else {
										$("##insurance_section").hide();
										$("##return_due_date").datepicker('option','disabled',false);
									}
								});
							});
						</script>
						<div class="form-row mb-2">
							<div class="col-12 mt-1">
								<label for="nature_of_material" class="data-entry-label">Nature of Material (<span id="length_nature_of_material"></span>)</label>
								<textarea name="nature_of_material" id="nature_of_material" rows="2" 
									onkeyup="countCharsLeft('nature_of_material', 4000, 'length_nature_of_material');"
									class="reqdClr form-control form-control-sm w-100 autogrow mb-1" 
									required ></textarea>
							</div>
						</div>
						<div class="form-row mb-2">
							<div class="col-12 ">
								<label for="loan_description" class="data-entry-label">Description (<span id="length_loan_description"></span>)</label>
								<textarea name="loan_description" id="loan_description"
									onkeyup="countCharsLeft('loan_description', 4000, 'length_loan_description');"
									class="form-control form-control-sm w-100 autogrow mb-1" rows="2"></textarea>
							</div>
						</div>
						<div class="form-row mb-2">
							<div class="col-12 ">
								<label for="loan_instructions" class="data-entry-label">Loan Instructions (<span id="length_loan_instructions"></span>)</label>
								<textarea name="loan_instructions" id="loan_instructions" 
									onkeyup="countCharsLeft('loan_instructions', 4000, 'length_loan_instructions');"
									rows="2" class="form-control form-control-sm w-100 autogrow mb-1"></textarea>
							</div>
						</div>
						<div class="form-row mb-2">
							<div class="col-12 ">
								<label for="trans_remarks" class="data-entry-label">Internal Remarks (<span id="length_trans_remarks"></span>)</label>
								<textarea name="trans_remarks" id="trans_remarks" 
									onkeyup="countCharsLeft('trans_remarks', 4000, 'length_trans_remarks');"
									class="form-control form-control-sm w-100 autogrow mb-1" rows="2"></textarea>
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
								<input type="button" value="Create Loan" class="btn btn-xs btn-primary"
									onClick="if (checkFormValidity($('##newLoan')[0])) { submit();  } ">
							</div>
						</div>
					</form>
				</section>
			
			</div>
		</main>
	</cfoutput>
</cfif>
<!-------------------------------------------------------------------------------------------------->
<cfif action is "editLoan">
	<cfset title="Edit Loan">
	
	<cfif not isdefined("transaction_id") or len(transaction_id) EQ 0>
		<cfthrow message="Edit Loan called without a transaction_id for the loan to edit">
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
			<cfquery name="loanDetails" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select
					trans.transaction_id,
					trans.transaction_type,
					trans_date,
					date_entered,
					loan_number,
					loan_type,
					loan_status,
					loan_instructions,
					loan_description,
					nature_of_material,
					trans_remarks,
					return_due_date,
					to_char(closed_date, 'YYYY-MM-DD') closed_date,
					trans.collection_id,
					collection.collection,
					concattransagent(trans.transaction_id,'entered by') enteredby,
					insurance_value,
					insurance_maintained_by
				 from
					loan,
					trans,
					collection
				where
					loan.transaction_id = trans.transaction_id AND
					trans.collection_id=collection.collection_id and
					trans.transaction_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
			</cfquery>
			<cfif loanDetails.RecordCount EQ 0 >
				<cfthrow message = "No such Loan.">
			</cfif>
			<cfif loanDetails.RecordCount GT 0 AND loanDetails.transaction_type NEQ 'loan'>
				<cfthrow message = "Request to edit a loan, but the provided transaction_id was for a different transaction type.">
			</cfif>
			<cfquery name="loanAgents" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
			<!--- Parent exhibition-master loan of the current exhibition-subloan loan, if applicable--->
			<cfquery name="parentLoan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select p.loan_number, p.transaction_id 
				from loan c left join loan_relations lr on c.transaction_id = lr.related_transaction_id 
					left join loan p on lr.transaction_id = p.transaction_id 
				where lr.relation_type = 'Subloan' 
					and c.transaction_id = <cfqueryparam value=#transaction_id# CFSQLType="CF_SQL_DECIMAL" >
			</cfquery>
			<!--- Subloans of the current loan (used for exhibition-master/exhibition-subloans) --->
			<cfquery name="childLoans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select c.loan_number, c.transaction_id 
				from loan p left join loan_relations lr on p.transaction_id = lr.transaction_id 
					left join loan c on lr.related_transaction_id = c.transaction_id 
				where lr.relation_type = 'Subloan'
					 and p.transaction_id = <cfqueryparam value=#transaction_id# CFSQLType="CF_SQL_DECIMAL" >
				order by c.loan_number
			</cfquery>
			<!---  Loans which are available to be used as subloans for an exhibition master loan (exhibition-subloans that are not allready children) --->
			<cfquery name="potentialChildLoans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select pc.loan_number, pc.transaction_id 
				from loan pc left join loan_relations lr on pc.transaction_id = lr.related_transaction_id
				where pc.loan_type = 'exhibition-subloan' 
					and (lr.transaction_id is null or lr.relation_type <> 'Subloan')
				order by pc.loan_number
			</cfquery>
			<cfquery name="getRestrictions" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select distinct restriction_summary, permit_id, permit_num from (
				select permit.restriction_summary, permit.permit_id, permit.permit_num
				from loan_item li 
					join specimen_part sp on li.collection_object_id = sp.collection_object_id
					join cataloged_item ci on sp.derived_from_cat_item = ci.collection_object_id
					join accn on ci.accn_id = accn.transaction_id
					join permit_trans on accn.transaction_id = permit_trans.transaction_id
					join permit on permit_trans.permit_id = permit.permit_id
				where li.transaction_id = <cfqueryparam CFSQLType="CF_SQL_DECIMAL" value="#loanDetails.transaction_id#">
					and permit.restriction_summary is not null
				union
				select permit.restriction_summary, permit.permit_id, permit.permit_num
				from loan
					join shipment on loan.transaction_id = shipment.transaction_id
					join permit_shipment on shipment.shipment_id = permit_shipment.shipment_id
					join permit on permit_shipment.permit_id = permit.permit_id
				where loan.transaction_id = <cfqueryparam CFSQLType="CF_SQL_DECIMAL" value="#loanDetails.transaction_id#">
					and permit.restriction_summary is not null
				)
			</cfquery>
			<script>
				$(function() {
					// on page load, hide the create project from loan fields
					$("##create_project").hide();
					<cfif loanDetails.loan_type neq 'exhibition-master'>
						// on page load, hide the insurance and subloan sections.
						$("##insurance_section").hide();
						$("##subloan_section").hide();
					</cfif>
					<cfif loanDetails.loan_type neq 'exhibition-subloan'>
						$("##parentloan_section").hide();
						$("##return_due_date").datepicker('option','disabled',false);
					<cfelse>
						$("##return_due_date").datepicker('option','disabled',true);
					</cfif>
					// on page load, remove transfer and exhibition-master from the list of loan/gift types, if not current values
					<cfif loanDetails.loan_type neq 'transfer' and loanDetails.collection_id NEQ MAGIC_MCZ_COLLECTION >
						$("##loan_type option[value='transfer']").each(function() { $(this).remove(); } );
					</cfif>
					<cfif loanDetails.loan_type neq 'exhibition-master' and loanDetails.collection_id NEQ MAGIC_MCZ_COLLECTION >
						$("##loan_type option[value='exhibition-master']").each(function() { $(this).remove(); } );
					</cfif>
					// on page load, bind a function to collection_id to change the list of loan types
					// based on the selected collection
					$("##collection_id").change( function () {
						if ( $("##collection_id option:selected").text() == "MCZ Collections" ) {
							// only MCZ collections (the non-specimen collection) is allowed to be exhibition-masters (but only add once).
							if ($("##loan_type option[value='exhibition-master']").length < 1) { 
								$("##loan_type").append($("<option></option>").attr("value",'exhibition-master').text('exhibition-master'));
							}
						} else {
							$("##loan_type option[value='exhibition-master']").each(function() { $(this).remove(); } );
							$("##insurance_section").hide();
							$("##subloan_section").hide();
						}
					});
					// on page load, bind a function to loan_type to hide/show the insurance section.
					$("##loan_type").change( function () {
						if ($("##loan_type").val() == "exhibition-master") {
							$("##insurance_section").show();
							$("##subloan_section").show();
							$("##parentloan_section").hide();
							$("##return_due_date").datepicker('option','disabled',false);
						} else if ($("##loan_type").val() == "exhibition-subloan") {
							$("##insurance_section").hide();
							$("##subloan_section").hide();
							$("##parentloan_section").show();
							$("##return_due_date").datepicker('option','disabled',true);
						} else {
							$("##insurance_section").hide();
							$("##subloan_section").hide();
							$("##parentloan_section").hide();
							$("##return_due_date").datepicker('option','disabled',false);
						}
					});
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
				<h1 class="h2 pb-0 ml-3">Edit Loan 
					<strong>#loanDetails.collection# #loanDetails.loan_number#</strong> 
					<i class="fas fa-info-circle" onClick="getMCZDocs('Loan_Transactions##Edit_a_Loan')" aria-label="help link"></i>
				</h1>
				<section class="row mx-0 border rounded my-2 pt-2" title="Edit Loan" >
					<form class="col-12" name="editLoanForm" id="editLoanForm" action="/transactions/Loan.cfm" method="post">
						<input type="hidden" name="method" value="saveLoan">
						<input id="action" type="hidden" name="action" value="editLoan">
						<input type="hidden" name="transaction_id" value="#loanDetails.transaction_id#">
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
										<option <cfif ctcollection.collection_id is loanDetails.collection_id> selected </cfif>
											value="#ctcollection.collection_id#">#ctcollection.collection#</option>
									</cfloop>
								</select>
							</div>
							<div class="col-12 col-md-3">
								<label for="loan_number" class="data-entry-label">Loan Number (yyyy-n-Coll)</label>
								<input type="text" name="loan_number" id="loan_number" value="#encodeForHTML(loanDetails.loan_number)#" class="reqdClr data-entry-input" 
									required pattern="#LOANNUMBERPATTERN#" >
							</div>
							<div class="col-12 col-md-2">
								<label for="loan_type" class="data-entry-label">Loan Type</label>
								<select name="loan_type" id="loan_type" class="reqdClr data-entry-select" required >
									<cfloop query="ctLoanType">
										<cfif ctLoanType.loan_type NEQ "transfer" OR loanDetails.collection_id EQ MAGIC_MCZ_COLLECTION >
											<option <cfif ctLoanType.loan_type is loanDetails.loan_type> selected="selected" </cfif>
												value="#ctLoanType.loan_type#">#ctLoanType.loan_type#</option>
										<cfelseif loanDetails.loan_type EQ "transfer" AND loanDetails.collection_id NEQ MAGIC_MCZ_COLLECTION >
											<option <cfif ctLoanType.loan_type is loanDetails.loan_type> selected="selected" </cfif> value="" ></option>
										</cfif>
									</cfloop>
								</select>
							</div>
							<div class="col-12 col-md-2">
								<label for="initiating_date" class="data-entry-label">Loan Date</label>
								<input type="text" name="initiating_date" id="initiating_date"
									value="#dateformat(loanDetails.trans_date,"yyyy-mm-dd")#" class="reqdClr data-entry-input" required >
							</div>
							<div class="col-12 col-md-2">
								<span class="data-entry-label">Entered Date</span>
								<div class="col-12 bg-light border non-field-text">
									<span id="date_entered">#dateformat(loanDetails.date_entered,'yyyy-mm-dd')#</span>
								</div>
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
											<cfif isAllowedLoanStateChange(loanDetails.loan_status,ctLoanStatus.loan_status)  or (isdefined("session.roles") and listfindnocase(session.roles,"ADMIN_TRANSACTIONS"))  >
												<option <cfif ctLoanStatus.loan_status is loanDetails.loan_status> selected="selected" </cfif>
													value="#ctLoanStatus.loan_status#">#ctLoanStatus.loan_status#</option>
											</cfif>
										</cfloop>
									</select>
								</span>
							</div>
							<div class="col-12 col-md-3">
								<label for="return_due_date" class="data-entry-label">Due Date</label>
								<input type="text" id="return_due_date" name="return_due_date" class="data-entry-input"
									value="#dateformat(loanDetails.return_due_date,'yyyy-mm-dd')#">
							</div>
							<div class="col-12 col-md-3" tabindex="0">
								<span class="data-entry-label">Closed Date:</span>
								<div class="col-12 bg-light border non-field-text">
									<cfif loanDetails.loan_status EQ 'closed' and len(loanDetails.closed_date) GT 0>
									#loanDetails.closed_date#
									<cfelse>
										--
									</cfif>
								</div>
							</div>
							<div class="col-12 col-md-3" tabindex="0">
								<span class="data-entry-label">Entered By</span>
								<div class="col-12 bg-light border non-field-text">
									<span id="entered_by">#encodeForHTML(loanDetails.enteredby)#</span>
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
								Loading Agents....  <span id='agentWarningSpan' style="display:none;">(if agents don&apos;t appear here, there is an error).</span>
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
								<input type="text" name="insurance_value" id="insurance_value" value="#encodeForHTML(loanDetails.insurance_value)#" size="40" class="data-entry-input">
							</div>
							<div class="col-12 col-md-6">
								<label for="insurance_maintained_by" class="data-entry-label">Insurance Maintained By</label>
								<input type="text" name="insurance_maintained_by" id="insurance_maintained_by" value="#encodeForHTML(loanDetails.insurance_maintained_by)#" size="40" class="data-entry-input">
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
										loadSubLoans(#loanDetails.transaction_id#);
									});
								</script>
							</div>
						</div>
						<div class="form-row mb-1">
							<div class="col-12 col-xl-6">
								<label for="nature_of_material" class="data-entry-label mb-1">Nature of Material (<span id="length_nature_of_material"></span>)</label>
								<textarea name="nature_of_material" id="nature_of_material" rows="1" 
									onkeyup="countCharsLeft('nature_of_material', 4000, 'length_nature_of_material');"
									class="reqdClr autogrow data-entry-textarea mb-2" required >#encodeForHTML(loanDetails.nature_of_material)#</textarea>
							</div>
							<div class="col-12 col-xl-6">
								<label for="loan_description" class="data-entry-label mb-1">Description (<span id="length_loan_description"></span>)</label>
								<textarea name="loan_description" id="loan_description" rows="1"
									onkeyup="countCharsLeft('loan_description', 4000, 'length_loan_description');"
									class="autogrow data-entry-textarea mb-2">#encodeForHTML(loanDetails.loan_description)#</textarea>
							</div>
						</div>
						<div class="form-row mb-1">
							<div class="col-12 col-xl-6">
								<label for="loan_instructions" class="data-entry-label mb-1">Loan Instructions (<span id="length_loan_instructions"></span>)</label>
								<textarea name="loan_instructions" id="loan_instructions" rows="1" 
									onkeyup="countCharsLeft('loan_instructions', 4000, 'length_loan_instructions');"
									class="autogrow data-entry-textarea mb-2">#encodeForHTML(loanDetails.loan_instructions)#</textarea>
							</div>
							<div class="col-12 col-xl-6">
								<label for="trans_remarks" class="data-entry-label mb-1">Internal Remarks (<span id="length_trans_remarks"></span>)</label>
								<textarea name="trans_remarks" id="trans_remarks" rows="1"
									onkeyup="countCharsLeft('trans_remarks', 4000, 'length_trans_remarks');"
									class="autogrow data-entry-textarea mb-2">#encodeForHTML(loanDetails.trans_remarks)#</textarea>
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
										handleFail(jqXHR,textStatus,error,'saving loan record');
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
							onClick=" doItemUpdate(); ">
					</div>
					<div class="col-12 pt-2">
						<div id="loanItemCountDiv" class="pb-3" tabindex="0"></div>
						<script>
							function doItemUpdate() { 
							 	updateLoanItemCount('#transaction_id#','loanItemCountDiv');
								updateRestrictionsBlock('#transaction_id#','restrictionSection','restrictionWarningDiv');
							}
							$(document).ready( updateLoanItemCount('#transaction_id#','loanItemCountDiv') );
						</script>
						<cfif loanDetails.loan_type EQ 'consumable'>
							<h2 class="h3 mt-2 pt-1">Disposition of material in loan:</h2>
							<cfquery name="getDispositions" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
								select count(loan_item.collection_object_id) as pcount, coll_obj_disposition, deacc_number, deacc_type, deacc_status
								from loan 
									left join loan_item on loan.transaction_id = loan_item.transaction_id
									left join coll_object on loan_item.collection_object_id = coll_object.collection_object_id
									left join deacc_item on loan_item.collection_object_id = deacc_item.collection_object_id
									left join deaccession on deacc_item.transaction_id = deaccession.transaction_id
								where loan.transaction_id = <cfqueryparam CFSQLType="CF_SQL_DECIMAL" value="#loanDetails.transaction_id#">
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
													<td><a href="/Transactions.cfm?action=findDeaccessions&execute=true&deacc_number=#encodeForURL(deacc_number)#">#deacc_number# (#deacc_status#)</a></td>
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
					<cfif getRestrictions.recordcount GT 0>
						<cfset restrictionsVisibility = "">
					<cfelse>
						<cfset restrictionsVisibility = "hidden">
					</cfif>
					<div id="restrictionWarningDiv" class="col-12 pt-2 border rounded bg-verylightred" #restrictionsVisibility#>
						<div class="h2">One of more specimens in this loan has retrictions on its use.  See summary below and details in permissions and rights documents.  Review Items to see which specimens have restrictions.</div>
					</div>
				</section>
				<section class="row mx-0">
					<div class="col-12 mt-3 mb-4 border rounded px-2 pb-2 bg-grayish">
						<section name="mediaSection" class="row mx-0 border rounded bg-light my-2" tabindex="0">
							<div class="col-12">
								<h2 class="h3">
									Media documenting this Loan 
									<span class="mt-1 smaller d-block">Include copies of signed loan invoices and correspondence here.  Attach permits to shipments. <strong>DO NOT Attach permits here.</strong></span>
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
									<input type='button' onClick="opencreatemediadialog('newMediaDlg_#transaction_id#','Loan: #loanDetails.loan_number#','#transaction_id#','#relation#',reloadTransMedia);" value='Create Media' class='btn btn-xs btn-secondary' >
									&nbsp; 
									<span id='addMedia_#transaction_id#'>
										<input type='button' onClick="openlinkmediadialog('newMediaDlg_#transaction_id#','Loan: #loanDetails.loan_number#','#transaction_id#','#relation#',reloadTransMedia);" value='Link Media' class='btn btn-xs btn-secondary' >
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
									where transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#loanDetails.transaction_id#">
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
										loan_item.transaction_id =  <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#" >
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
											where li.transaction_id = <cfqueryparam CFSQLType="CF_SQL_DECIMAL" value="#loanDetails.transaction_id#">
										</cfquery>
										<ul class="ml-1 pl-4 pr-2 list-style-disc">
											<cfloop query="getAccessions">
												<li class="accn2">
													<a class="font-weight-bold" href="/transactions/Accession.cfm?action=edit&transaction_id=#transaction_id#"><span>Accession ##</span>#accn_number#</a>, <span>Type:</span> #accn_type#, <span>Received: </span>#dateformat(received_date,'yyyy-mm-dd')# <cfquery name="getAccnPermits" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
												where li.transaction_id = <cfqueryparam CFSQLType="CF_SQL_DECIMAL" value="#loanDetails.transaction_id#">
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
												where li.transaction_id = <cfqueryparam CFSQLType="CF_SQL_DECIMAL" value="#loanDetails.transaction_id#">
												union
												select 
													mczbase.get_media_id_for_relation(p.permit_id, 'shows permit','application/pdf') as media_id, 
													mczbase.get_media_uri_for_relation(p.permit_id, 'shows permit','application/pdf') as uri,
													p.permit_type, p.permit_num, p.permit_title, p.specific_type, 1 as show_on_shipment
												from shipment s
													left join permit_shipment ps on s.shipment_id = ps.shipment_id
													left join permit p on ps.permit_id = p.permit_id
												where s.transaction_id = <cfqueryparam CFSQLType="CF_SQL_DECIMAL" value="#loanDetails.transaction_id#">
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
										
										<a href="/Reports/combinePermits.cfm?transaction_id=#loanDetails.transaction_id#" class="font-weight-bold pl-2 d-block mb-3">PDF of All Permission and Rights documents</a>
											
									</cfif>
								</div>
							</section>
						</div>
						<cfif getRestrictions.recordcount GT 0>
							<section id="restrictionSection" title="Restrictions" class="row mx-0 border rounded bg-light mt-2 mb-0 pb-2" tabindex="0">
								<div class="col-12 pb-0 px-0">
									<h2 class="h3 px-3">Restrictions on Use</h2>
									<p class="px-3">Restrictions on use from one or more permissions and rights document apply to one or more items in this loan.</p>
									<ul>
										<cfloop query="getRestrictions">
											<li><a href="/transactions/Permit.cfm?action=view&permit_id=#getRestrictions.permit_id#" target="_blank">#getRestrictions.permit_num#</a>#getRestrictions.restriction_summary#</li>
										</cfloop>
									</ul>
								</div>
							</section>
						<cfelse>
							<section id="restrictionSection" title="Restrictions" class="row mx-0 border rounded bg-light mt-2 mb-0 pb-2" tabindex="0"><section>
						</cfif>
						<section title="Projects" class="row mx-0 border rounded bg-light mt-2 mb-0 pb-2" tabindex="0">
							<div class="col-12 pb-0 px-0">
								<h2 class="h3 px-3">
									Projects associated with this loan
									<i class="fas fas-info fa-info-circle" onClick="getMCZDocs('Loan_Transactions##Projects_and_Permits')" aria-label="help link for projects"></i>
								</h2>
								<div id="projectsDiv" class="mx-3"></div>
								<script>
									$(document).ready( 
										loadProjects('projectsDiv',#loanDetails.transaction_id#) 
									);
									function reloadTransProjects() {
										loadProjects('projectsDiv',#loanDetails.transaction_id#);
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
<cfif action is "makeLoan">
	<cfif not isdefined("return_due_date")>
		<cfset return_due_date = ''>
	</cfif>
	<cfoutput>
		<cfif
			len(loan_type) is 0 OR
			len(loan_number) is 0 OR
			len(initiating_date) is 0 OR
			len(rec_agent_id) is 0 OR
			len(auth_agent_id) is 0
		>
			<br>
			One or more required fields are missing.<br>
			You must fill in loan_type, loannumber, authorizing_agent_name, initiating_date, loan_num_prefix, received_agent_name. <br>
			Use your browser's back button to fix the problem and try again.
			<cfabort>
		</cfif>
		<cfif loan_type EQ 'transfer' AND collection_id NEQ MAGIC_MCZ_COLLECTION >
			<p>Loans of type <strong>transfer</strong> cannot be made in this collection.</p>
			<p>Use your browser's back button to fix the problem and try again.</p>
			<cfabort>
		</cfif>
		<cfif len(in_house_contact_agent_id) is 0>
			<cfset in_house_contact_agent_id=auth_agent_id>
		</cfif>
		<!--- cfif len(outside_contact_agent_id) is 0>
			<cfset outside_contact_agent_id=REC_AGENT_ID>
		</cfif --->
		<cftransaction>
			<cfquery name="obtainTransNumber" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select sq_transaction_id.nextval as trans_id from dual
			</cfquery>
			<cfloop query="obtainTransNumber">
				<cfset new_transaction_id = obtainTransNumber.trans_id>
			</cfloop>
			<!--- date_entered has default sysdate in trans, not set from here --->
			<cfquery name="newLoanTrans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#NATURE_OF_MATERIAL#">,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_id#">
					<cfif len(#trans_remarks#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trans_remarks#">
					</cfif>
					)
			</cfquery>
			<cfquery name="newLoan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				INSERT INTO loan (
					TRANSACTION_ID,
					LOAN_TYPE,
					LOAN_NUMBER
					<cfif len(#loan_status#) gt 0>
						,loan_status
					</cfif>
					<cfif len(#return_due_date#) gt 0>
						,return_due_date
					</cfif>
					<cfif len(#LOAN_INSTRUCTIONS#) gt 0>
						,LOAN_INSTRUCTIONS
					</cfif>
					<cfif len(#loan_description#) gt 0>
						,loan_description
					</cfif>
					<cfif len(#insurance_value#) gt 0>
						,insurance_value
					</cfif>
					<cfif len(#insurance_maintained_by#) gt 0>
						,insurance_maintained_by
					</cfif>
					 )
				values (
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#new_transaction_id#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#loan_type#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#loan_number#">
					<cfif len(#loan_status#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#loan_status#">
					</cfif>
					<cfif len(#return_due_date#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_TIMESTAMP" value="#dateformat(return_due_date,"yyyy-mm-dd")#">
					</cfif>
					<cfif len(#LOAN_INSTRUCTIONS#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#LOAN_INSTRUCTIONS#">
					</cfif>
					<cfif len(#loan_description#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#loan_description#">
					</cfif>
					<cfif len(#insurance_value#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#insurance_value#">
					</cfif>
					<cfif len(#insurance_maintained_by#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#insurance_maintained_by#">
					</cfif>
					)
			</cfquery>
			<cfquery name="authBy" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				INSERT INTO trans_agent (
					transaction_id,
					agent_id,
					trans_agent_role
				) values (
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#new_transaction_id#">,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#auth_agent_id#">,
					'in-house authorized by')
			</cfquery>
			<cfquery name="in_house_contact" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				INSERT INTO trans_agent (
					transaction_id,
					agent_id,
					trans_agent_role
				) values (
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#new_transaction_id#">,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#in_house_contact_agent_id#">,
					'in-house contact')
			</cfquery>
			<cfquery name="recipient_institution" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				INSERT INTO trans_agent (
					transaction_id,
					agent_id,
					trans_agent_role
				) values (
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#new_transaction_id#">,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#recipient_institution_agent_id#">,
					'recipient institution')
			</cfquery>
			<cfif isdefined("additional_contact_agent_id") and len(additional_contact_agent_id) gt 0>
				<cfquery name="additional_contact" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				INSERT INTO trans_agent (
					transaction_id,
					agent_id,
					trans_agent_role
				) values (
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#new_transaction_id#">,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#additional_contact_agent_id#">,
					'additional outside contact')
			</cfquery>
			</cfif>
			<cfif isdefined("additional_incontact_agent_id") and len(additional_incontact_agent_id) gt 0>
				<cfquery name="additional_incontact" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
			<cfif isdefined("foruseby_agent_id") and len(foruseby_agent_id) gt 0>
				<cfquery name="foruseby_contact" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				INSERT INTO trans_agent (
					transaction_id,
					agent_id,
					trans_agent_role
				) values (
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#new_transaction_id#">,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#foruseby_agent_id#">,
					'for use by')
			</cfquery>
			</cfif>
			<cfquery name="newLoan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				INSERT INTO trans_agent (
					transaction_id,
					agent_id,
					trans_agent_role
				) values (
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#new_transaction_id#">,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#REC_AGENT_ID#">,
					'received by')
			</cfquery>
		</cftransaction>
		<cflocation url="/transactions/Loan.cfm?Action=editLoan&transaction_id=#new_transaction_id#" addtoken="false">
	</cfoutput>
</cfif>

<!-------------------------------------------------------------------------------------------------->
<cfinclude template="/shared/_footer.cfm">
