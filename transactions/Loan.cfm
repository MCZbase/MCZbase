<cfset pageTitle = "Loan Management">
<cfif isdefined("action") AND action EQ 'newLoan'>
	<cfset pageTitle = "Create New Loan">
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
		<cfset pageTitle = "Edit Loan #loanNumber.loan_number#">
	</cfif>
</cfif>
<cfset MAGIC_MCZ_COLLECTION = 12>
<cfset MAGIC_MCZ_CRYO = 11>
<cfset LOANNUMBERPATTERN = '^[12][0-9]{3}-[0-9a-zA-Z]+-[A-Z][a-zA-Z]+$'>
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
<cfquery name="ctcoll" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select collection_cde from ctcollection_cde order by collection_cde
</cfquery>
<!--- Obtain list of transaction agent roles, excluding those not relevant to loan editing --->
<cfquery name="cttrans_agent_role" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select distinct(trans_agent_role) from cttrans_agent_role  where trans_agent_role != 'entered by' and trans_agent_role != 'associated with agency' and trans_agent_role != 'received from' and trans_agent_role != 'borrow overseen by' order by trans_agent_role
</cfquery>
<cfquery name="ctcollection" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select * from collection order by collection
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
		<main class="container">
			<div class="row">
				<div class="col-12">
					<h2 class="wikilink mt-2 mb-0" id="newLoanFormSectionLabel" >Create New Loan <i class="fas fas-info2 fa-info-circle" onClick="getMCZDocs('Loan_Transactions##Create_a_New_Loan')" aria-label="help link"></i></h2>
					<div class="form-row mb-2">
						<section id="newLoanFormSection" class="col-12 col-md-9 col-xl-7 offset-xl-1" aria-labeledby="newLoanFormSectionLabel" >
							<form name="newloan" id="newLoan" action="/transactions/Loan.cfm" method="post" onSubmit="return noenter();">
								<input type="hidden" name="action" value="makeLoan">
								<div class="form-row mb-2">
									<div class="col-12 col-md-6">
										<label for="collection_id">Collection</label>
										<select name="collection_id" size="1" id="collection_id" class="reqdClr custom-select form-control-sm">
											<cfloop query="ctcollection">
												<option value="#ctcollection.collection_id#">#ctcollection.collection#</option>
											</cfloop>
										</select>
									</div>
									<div class="col-12 col-md-6">
										<label for="loan_number" class="data-entry-label">Loan Number (yyyy-n-Coll)</label>
										<input type="text" name="loan_number" class="reqdClr form-control-sm" id="loan_number" required pattern="#LOANNUMBERPATTERN#">
									</div>
								</div>
								<div class="form-row mb-2">
									<div class="col-12 col-md-6">
										<span>
											<label for="auth_agent_name">Authorized By</label>
											<span id="auth_agent_view">&nbsp;&nbsp;&nbsp;&nbsp;</span>
										</span>
										<div class="input-group">
											<div class="input-group-prepend">
												<span class="input-group-text" id="auth_agent_icon"><i class="fa fa-user" aria-hidden="true"></i></span> 
											</div>
											<input name="auth_agent_name" id="auth_agent_name" class="reqdClr form-control form-control-sm" required >
										</div>
										<input type="hidden" name="auth_agent_id" id="auth_agent_id"  >
										<script>
											$(makeRichTransAgentPicker('auth_agent_name', 'auth_agent_id','auth_agent_icon','auth_agent_view',null))
										</script> 
									</div>
									<div class="col-12 col-md-6">
										<span>
											<label for="rec_agent_name">Received By:</label>
											<span id="rec_agent_view">&nbsp;&nbsp;&nbsp;&nbsp;</span>
										</span>
										<div class="input-group">
											<div class="input-group-prepend">
												<span class="input-group-text" id="rec_agent_icon"><i class="fa fa-user" aria-hidden="true"></i></span> 
											</div>
											<input  name="rec_agent_name" id="rec_agent_name" class="reqdClr form-control form-control-sm" required >
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
												<span class="input-group-text" id="in_house_contact_agent_icon"><i class="fa fa-user" aria-hidden="true"></i></span> 
											</div>
											<input type="text" name="in_house_contact_agent_name" id="in_house_contact_agent_name"
												class="reqdClr form-control form-control-sm" required >
										</div>
										<input type="hidden" name="in_house_contact_agent_id" id="in_house_contact_agent_id" >
										<script>
											$(makeRichTransAgentPicker('in_house_contact_agent_name','in_house_contact_agent_id','in_house_contact_agent_icon','in_house_contact_agent_view',null));
										</script> 
									</div>
									<div class="col-12 col-md-6">
										<span>
											<label for="additional_contact_agent_name">Additional Outside Contact:</label>
											<span id="additional_contact_agent_view">&nbsp;&nbsp;&nbsp;&nbsp;</span> 
										</span>
										<div class="input-group">
											<div class="input-group-prepend">
												<span class="input-group-text" id="additional_contact_agent_icon"><i class="fa fa-user" aria-hidden="true"></i></span> 
											</div>
											<input type="text" name="additional_contact_agent_name" id="additional_contact_agent_name" class="form-control form-control-sm" >
										</div>
										<input type="hidden" name="additional_contact_agent_id" id="additional_contact_agent_id" >
										<script>
											$(makeRichTransAgentPicker('additional_contact_agent_name','additional_contact_agent_id','additional_contact_agent_icon','additional_contact_agent_view',null));
										</script> 
									</div>
								</div>
								<div class="form-row mb-2">
									<div class="col-12 col-md-6"> 
										<span>
											<label for="recipient_institution_agent_name">Recipient Institution:</label>
											<span id="recipient_institution_agent_view">&nbsp;&nbsp;&nbsp;&nbsp;</span> 
										</span>
										<div class="input-group">
											<div class="input-group-prepend">
												<span class="input-group-text" id="recipient_institution_agent_icon"><i class="fa fa-user" aria-hidden="true"></i></span> 
											</div>
											<input type="text" name="recipient_institution_agent_name"  id="recipient_institution_agent_name" 
												class="reqdClr form-control form-control-sm" required >
										</div>
										<input type="hidden" name="recipient_institution_agent_id"  id="recipient_institution_agent_id" >
										<script>
											$(makeRichTransAgentPicker('recipient_institution_agent_name','recipient_institution_agent_id','recipient_institution_agent_icon','recipient_institution_agent_view',null));
										</script> 
									</div>
									<div class="col-12 col-md-6"> 
										<span>
											<label for="foruseby_agent_name">For Use By:</label>
											<span id="foruseby_agent_view">&nbsp;&nbsp;&nbsp;&nbsp;</span> 
										</span>
										<div class="input-group">
											<div class="input-group-prepend">
												<span class="input-group-text" id="foruseby_agent_icon"><i class="fa fa-user" aria-hidden="true"></i></span> 
											</div>
											<input type="text" name="foruseby_agent_name" id="foruseby_agent_name" class="form-control form-control-sm" >
										</div>
										<input type="hidden" name="foruseby_agent_id" id="foruseby_agent_id" >
										<script>
											$(makeRichTransAgentPicker('foruseby_agent_name','foruseby_agent_id','foruseby_agent_icon','foruseby_agent_view',null));
										</script> 
									</div>
								</div>
								<div class="form-row mb-2">
									<div class="col-12 col-md-6">
										<label for="loan_type">Loan Type</label>
										<select name="loan_type" id="loan_type" class="reqdClr custom-select1 form-control-sm" required >
											<cfloop query="ctLoanType">
												<option value="#ctLoanType.loan_type#">#ctLoanType.loan_type#</option>
											</cfloop>
										</select>
									</div>
									<div class="col-12 col-md-6">
										<label for="loan_status">Loan Status</label>
										<select name="loan_status" id="loan_status" class="reqdClr custom-select1 form-control-sm" required >
											<cfloop query="ctLoanStatus">
												<cfif isAllowedLoanStateChange('in process',ctLoanStatus.loan_status) >
													<cfif #ctLoanStatus.loan_status# is "open">
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
									<div class="col-12 col-md-5">
										<label for="initiating_date">Transaction Date</label>
										<input type="text" name="initiating_date" id="initiating_date" value="#dateformat(now(),"yyyy-mm-dd")#" class="w-100 form-control form-control-sm">
									</div>
									<div class="col-12 col-md-5">
										<label for="return_due_date">Return Due Date</label>
										<input type="text" name="return_due_date" id="return_due_date" value="#dateformat(dateadd("m",6,now()),"yyyy-mm-dd")#" class="w-100 form-control form-control-sm" >
									</div>
								</div>
								<div class="form-row mb-2" id="insurance_section">
									<div class="col-12 col-md-5">
										<label for="insurance_value" class="data-entry-label">Insurance value</label>
										<input type="text" name="insurance_value" id="insurance_value" value="" class="data-entry-input">
									</div>
									<div class="col-12 col-md-5">
										<label for="insurance_maintained_by" class="data-entry-label">Insurance Maintained By</label>
										<input type="text" name="insurance_maintained_by" id="insurance_maintained_by" value="" class="data-entry-input">
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
									<div class="col-12 col-md-10">
										<label for="nature_of_material">Nature of Material (<span id="length_nature_of_material"></span>)</label>
										<textarea name="nature_of_material" id="nature_of_material" rows="2" 
											onkeyup="countCharsLeft('nature_of_material', 4000, 'length_nature_of_material');"
											class="reqdClr form-control form-control-sm w-100 autogrow" 
											required ></textarea>
									</div>
								</div>
								<div class="form-row mb-2">
									<div class="col-12 col-md-10">
										<label for="loan_description">Description (<span id="length_loan_description"></span>)</label>
										<textarea name="loan_description" id="loan_description"
											onkeyup="countCharsLeft('loan_description', 4000, 'length_loan_description');"
											class="form-control-sm form-control w-100 autogrow" rows="2"></textarea>
									</div>
								</div>
								<div class="form-row mb-2">
									<div class="col-12 col-md-10">
										<label for="loan_instructions">Loan Instructions (<span id="length_loan_instructions"></span>)</label>
										<textarea name="loan_instructions" id="loan_instructions" 
											onkeyup="countCharsLeft('loan_instructions', 4000, 'length_loan_instructions');"
											rows="2" class="form-control form-control-sm w-100 autogrow"></textarea>
									</div>
								</div>
								<div class="form-row mb-2">
									<div class="col-12 col-md-10">
										<label for="trans_remarks">Internal Remarks (<span id="length_trans_remarks"></span>)</label>
										<textarea name="trans_remarks" id="trans_remarks" 
											onkeyup="countCharsLeft('trans_remarks', 4000, 'length_trans_remarks');"
											class="form-control form-control-sm w-100 autogrow" rows="2"></textarea>
									</div>
								</div>
								<script>
									// Make all textareas with autogrow class re bound to the autogrow function on key up
									$(document).ready(function() { 
										$("textarea.autogrow").keyup(autogrow);  
										$('textarea.autogrow').keyup();
									});
								</script>
								<div class="form-row my-2">
									<div class="form-group col-12">
										<input type="button" value="Create Loan" class="btn btn-sm btn-primary"
											onClick="if (checkFormValidity($('##newLoan')[0])) { submit();  } ">
									</div>
								</div>
							</form>
						</section>
						<!--- Begin next available number list in an aside, ml-sm-4 to provide offset from column above holding the form. --->
						<aside class="coll-sm-4 ml-sm-4" aria-labeledby="nextNumberSectionLabel"> 
							<div id="nextNumDiv" class="border border-primary p-md-2">
								<h3 id="nextNumberSectionLabel">Next Available Loan Number:</h3>
								<!--- Find list of all non-observational collections --->
								<cfquery name="loanableCollections" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
									select collection_id, collection_cde, collection from collection 
									where collection not like '% Observations'
									order by collection 
								</cfquery>
								<nav class="nav flex-column align-items-start">
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
										<span class="btn btn-link " onclick="setLoanNum('#collection_id#','#nextNumberQuery.nextNumber#')">#collection# #nextNumberQuery.nextNumber#</span>
									<cfelse>
										<span style="font-size:x-small"> No data available for #collection#. </span>
									</cfif>
								</cfloop>
								</nav>
							</div>
						</aside><!--- next number aside --->
					</div>
				</div>
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
		
		<main class="container">
			<!--- div class="row" --->
				<cftry>
					<section title="Edit Loan" class="row border rounded">
						<form name="editLoanForm" id="editLoanForm" action="/transactions/Loan.cfm" method="post" class="col-12">
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
							<h2 class="wikilink mt-1 mb-0">
								Edit Loan 
								<strong>#loanDetails.collection# #loanDetails.loan_number#</strong> 
								<i class="fas fas-info fa-info-circle" onClick="getMCZDocs('Loan_Transactions##Edit_a_Loan')" aria-label="help link"></i>
							</h2>
							<div class="form-row mb-1">
								<div class="col-12 col-md-3">
									<label class="data-entry-label" for="collection_id">Department</label>
									<select name="collection_id" id="collection_id" size="1" class="reqdClr form-control-sm" required >
										<cfloop query="ctcollection">
											<option <cfif ctcollection.collection_id is loanDetails.collection_id> selected </cfif>
												value="#ctcollection.collection_id#">#ctcollection.collection#</option>
										</cfloop>
									</select>
								</div>
								<div class="col-12 col-md-3">
									<label for="loan_number" class="data-entry-label">Loan Number (yyyy-n-Coll)</label>
									<input type="text" name="loan_number" id="loan_number" value="#loanDetails.loan_number#" class="reqdClr form-control-sm" 
										required  pattern="#LOANNUMBERPATTERN#"  >
								</div>
								<div class="col-12 col-md-3">
									<label for="loan_type" class="data-entry-label">Loan Type</label>
									<select name="loan_type" id="loan_type" class="reqdClr form-control-sm" required >
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
								<div class="col-12 col-md-3">
									<label for="initiating_date" class="data-entry-label">Transaction Date</label>
									<input type="text" name="initiating_date" id="initiating_date"
										value="#dateformat(loanDetails.trans_date,"yyyy-mm-dd")#" class="reqdClr form-control-sm" required >
								</div>
							</div>
							<div class="form-row mb-1">
								<div class="col-12 col-md-3">
									<label for="loan_status" class="data-entry-label">Loan Status</label>
									<span>
										<select name="loan_status" id="loan_status" class="reqdClr form-control-sm" required >
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
									<span class="data-entry-label">Date Closed:</span>
									<div class="col-12 bg-light border">
										<cfif loanDetails.loan_status EQ 'closed' and len(loanDetails.closed_date) GT 0>
											#loanDetails.closed_date#
										<cfelse>
											--
										</cfif>
									</div>
								</div>
								<div class="col-12 col-md-3">
									<label for="return_due_date" class="data-entry-label">Due Date</label>
									<input type="text" id="return_due_date" name="return_due_date" class="form-control-sm"
										value="#dateformat(loanDetails.return_due_date,'yyyy-mm-dd')#">
								</div>
								<div class="col-12 col-md-3">
									<label for="entered_by" class="data-entry-label">Entered By</label>
									<div class="col-12 bg-light border">
										<span id="entered_by">#loanDetails.enteredby#</span>
									</div>
								</div>
							</div>
							<!--- Begin loan agents table: Load via ajax. --->
							<div class="form-row my-1">
								<script>
									$(document).ready(loadAgentTable("agentTableContainerDiv",#transaction_id#,"editLoanForm",handleChange));
								</script>
								<div class="col-12 table-responsive mt-1" id="agentTableContainerDiv" >
									<span>Awaiting load.... (if agents don't show up here shortly, there is an error).</span>
								</div>
								<script>
									$(document).ready(function() { 
										$('##agentTableContainerDiv').on('domChanged',function() {
											console.log("dom Cchange within agentTableContainerDiv");
											monitorForChanges('editLoanForm',handleChange);
										});
									});
								</script>
							</div>
							<div class="form-row mb-1" id="insurance_section">
								<div class="col-12 col-md-6">
									<label for="insurance_value" class="data-entry-label">Insurance value</label>
									<input type="text" name="insurance_value" id="insurance_value" value="#loanDetails.insurance_value#" size="40" class="form-control-sm">
								</div>
								<div class="col-12 col-md-6">
									<label for="insurance_maintained_by" class="data-entry-label">Insurance Maintained By</label>
									<input type="text" name="insurance_maintained_by" id="insurance_maintained_by" value="#loanDetails.insurance_maintained_by#" size="40" class="form-control-sm">
								</div>
							</div>
							<div class="form-row mb-1">
								<div class="col-12 col-md-6">
									<span id="parentloan_section">Exhibition-Master Loan:
										<cfif parentLoan.RecordCount GT 0>
											<cfloop query="parentLoan">
												<a href="/transactions/Loan.cfm?action=editLoan&transaction_id=#parentLoan.transaction_id#">#parentLoan.loan_number#</a>
											</cfloop>
										<cfelse>
											This exhibition subloan has not been linked to a master loan.
										</cfif>
									</span>
									<span id="subloan_section">
										<span id="subloan_list"> Exhibition-Subloans (#childLoans.RecordCount#):
											<cfif childLoans.RecordCount GT 0>
												<cfset childLoanCounter = 0>
												<cfset childseparator = "">
												<cfloop query="childLoans">
													#childseparator#
 													<a href="/transactions/Loan.cfm?action=editLoan&transaction_id=#childLoans.transaction_id#">#childLoans.loan_number#</a>
													<button class="btn-xs btn-warning" id="button_remove_subloan_#childLoanCounter#">-</button>
													<script>
														$(function() {
															$("##button_remove_subloan_#childLoanCounter#").click( function(event) {
																event.preventDefault();
																$.get( "/transactions/component/functions.cfc", {
																	transaction_id : "#loanDetails.transaction_id#",
																	subloan_transaction_id : "#childLoans.transaction_id#" ,
																	method : "removeSubLoan",
																	returnformat : "json",
																	queryformat : 'column'
																},
																function(r) {
																	var retval = "Exhibition-Subloans (" + r.ROWCOUNT + "): ";
																	var separator = "";
																	for (var i=0; i<r.ROWCOUNT; i++) {
																		retval = retval + separator + "<a href='/transactions/Loan.cfm?action=editLoan&transaction_id=" + r.DATA.TRANSACTION_ID[i] + "'>" + r.DATA.LOAN_NUMBER[i] + "</a>";
																		retval = retval + "<button type='button' class='btn-xs btn-warning' onclick='removeSubloanFromParent(#loanDetails.transaction_id#,"+r.DATA.TRANSACTION_ID[i]+")'>-</button>"; 
																	separator = ";&nbsp";
																	};
																	retval = retval + "<BR>";
																	$("##subloan_list").html(retval);
																},
																"json"
																);
															});
														});
													</script>
													<cfset childLoanCounter = childLoanCounter + 1 >
													<cfset childseparator = ";&nbsp;">
												</cfloop>
											</cfif>
											<br>
										</span><!--- end subloan_list ---> 
										<script>
											$(function() {
												$("##button_add_subloans").click( function(event) {
													event.preventDefault();
													$.get( "/transactions/component/functions.cfc",
														{ transaction_id : "#loanDetails.transaction_id#",
															subloan_transaction_id : $("##possible_subloans").val() ,
															method : "addSubLoanToLoan",
															returnformat : "json",
															queryformat : 'column'
														},
														function(r) {
															var retval = "Exhibition-Subloans (" + r.ROWCOUNT + "): ";
															var separator = "";
															for (var i=0; i<r.ROWCOUNT; i++) {
																retval = retval + separator + "<a href='/transactions/Loan.cfm?action=editLoan&transaction_id=" + r.DATA.TRANSACTION_ID[i] + "'>" + r.DATA.LOAN_NUMBER[i] + "</a>";
																retval = retval + "<button type='button' class='btn-xs btn-warning' onclick='removeSubloanFromParent(#loanDetails.transaction_id#,"+r.DATA.TRANSACTION_ID[i]+")'>-</button>"; 
																separator = ";&nbsp";
															};
															retval = retval + "<BR>";
															$("##subloan_list").html(retval);
														},
														"json"
													);
												});
											});
										</script>
										<select name="possible_subloans" id="possible_subloans" class="form-control-sm">
											<cfloop query="potentialChildLoans">
												<option value="#transaction_id#">#loan_number#</option>
											</cfloop>
										</select>
										<button class="ui-button ui-widget ui-corner-all" id="button_add_subloans"> Add </button>
									</span><!--- end subloan section ---> 
								</div>
							</div>
							<div class="form-row mb-1">
								<div class="col-12 col-xl-6">
									<label for="nature_of_material" class="data-entry-label">Nature of Material (<span id="length_nature_of_material"></span>)</label>
									<textarea name="nature_of_material" id="nature_of_material" rows="1" 
										onkeyup="countCharsLeft('nature_of_material', 4000, 'length_nature_of_material');"
										class="reqdClr autogrow border rounded w-100" required >#loanDetails.nature_of_material#</textarea>
								</div>
								<div class="col-12 col-xl-6">
									<label for="loan_description" class="data-entry-label">Description (<span id="length_loan_description"></span>)</label>
									<textarea name="loan_description" id="loan_description" rows="1"
										onkeyup="countCharsLeft('loan_description', 4000, 'length_loan_description');"
										class="autogrow border rounded w-100">#loanDetails.loan_description#</textarea>
								</div>
							</div>
							<div class="form-row mb-1">
								<div class="col-12 col-xl-6">
									<label for="loan_instructions" class="data-entry-label">Loan Instructions (<span id="length_loan_instructions"></span>)</label>
									<textarea name="loan_instructions" id="loan_instructions" rows="1" 
										onkeyup="countCharsLeft('loan_instructions', 4000, 'length_loan_instructions');"
										class="autogrow border rounded w-100">#loanDetails.loan_instructions#</textarea>
								</div>
								<div class="col-12 col-xl-6">
									<label for="trans_remarks" class="data-entry-label">Internal Remarks (<span id="length_trans_remarks"></span>)</label>
									<textarea name="trans_remarks" id="trans_remarks" rows="1"
										onkeyup="countCharsLeft('trans_remarks', 4000, 'length_trans_remarks');"
										class="autogrow border w-100 rounded">#loanDetails.trans_remarks#</textarea>
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
									<input type="button" value="Save" class="btn-xs btn-primary mr-2"
										onClick="if (checkFormValidity($('##editLoanForm')[0])) { saveEdits();  } " 
										id="submitButton" >
									<button type="button" aria-label="Print Loan Paperwork" id="loanPrintDialogLauncher"
										class="btn btn-sm btn-info" value="Print..."
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
											messageDialog('Error saving taxon record: '+message, 'Error: '+error.substring(0,50));
										}
									});
								};
							</script>
						</form>
					</section>

					<section name="loanItemsSection" class="row border rounded" title="Collection Objects in this loan">
						<div class="col-12 mt-1">
							<input type="button" value="Add Items" class="btn btn-xs btn-secondary"
								onClick="window.open('/SpecimenSearch.cfm?Action=dispCollObj&transaction_id=#transaction_id#');">
							<input type="button" value="Add Items BY Barcode" class="btn btn-xs btn-secondary"
								onClick="window.open('/loanByBarcode.cfm?transaction_id=#transaction_id#');">
							<input type="button" value="Review Items" class="btn btn-xs btn-secondary"
								onClick="window.open('/a_loanItemReview.cfm?transaction_id=#transaction_id#');">
							<input type="button" value="Refresh Item Count" class="btn btn-xs btn-info"
								onClick=" updateLoanItemCount('#transaction_id#','loanItemCountDiv'); ">
						</div>
						<div class="col-12">
							<div id="loanItemCountDiv"></div>
							<script>
								$(document).ready( updateLoanItemCount('#transaction_id#','loanItemCountDiv') );
							</script>
							<cfif loanDetails.loan_type EQ 'consumable'>
								<h3>Disposition of material in loan:</h3>
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
									<table class="table table-sm">
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

					<section name="mediaSection" class="row border rounded bg-light">
						<div class="col-12">
							<h3>
								Media documenting this Loan: <br/>
								<small>Include copies of signed loan invoices and correspondence here.  Attach permits to shipments.</small>
							</h3>
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
							<br>			
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
					<section name="countriesOfOriginSection" class="row border rounded">
						<div class="col-12">
							<h3>Countries of Origin of items in this loan</h3>
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
								<span>None</span>
							<cfelse>
								<cfloop query=ctSovereignNation>
									<cfif len(sovereign_nation) eq 0>
										<cfset sovereign_nation = '[no value set]'>
									</cfif>
									<span>#sep##sovereign_nation#&nbsp;(#ct#)</span>
									<cfset sep="; ">
								</cfloop>
							</cfif>
						</div>
					</section>
					<section name="shipmentSection" class="row border rounded">
						<div class="col-12">
							<h3>Shipment Information:</h3>
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
										height: 900,
										width: 1100,
										minWidth: 400,
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
							<div id="shipmentTable">Loading shipments...</div>
							<!--- shippmentTable for ajax replace ---> 
							<script>
								$( document ).ready(loadShipments(#transaction_id#));
							</script>
							<div class="addstyle">
								<input type="button" class="btn btn-xs btn-secondary float-left mr-4" value="Add Shipment" onClick="$('##dialog-shipment').dialog('open'); setupNewShipment(#transaction_id#);">
								<div class="shipmentnote float-left mb-4">Note: please check the <a href="https://code.mcz.harvard.edu/wiki/index.php/Country_Alerts">Country Alerts</a> page for special instructions or restrictions associated with specific countries</div>
							</div>
						</div>
					</section>
		
					<cfinclude template="/transactions/shipmentDialog.cfm">
					
					<div class="row px-0">
						<section title="Accessions associated with material in this loan" name="accessionsSection" class="col-12 col-md-6 border rounded">
							<h3>Accessions of material in this loan:</h3>
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
							<ul class="accn">
								<cfloop query="getAccessions">
									<li class="accn2">
										<a style="font-weight:bold;" href="editAccn.cfm?Action=edit&transaction_id=#transaction_id#"><span>Accession ##</span> #accn_number#</a>
										, <span>Type:</span> #accn_type#, <span>Received: </span>#dateformat(received_date,'yyyy-mm-dd')#
										<cfquery name="getAccnPermits" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
											<ul class="accnpermit">
												<cfloop query="getAccnPermits">
													<li>
														<span style="font-weight:bold;">#permit_type#:</span> 
														#specific_type# #permit_num#, 
														<span>Issued:</span> #dateformat(issued_date,'yyyy-mm-dd')# <span>by</span> #IssuedByAgent# 
														<a href="Permit.cfm?Action=editPermit&permit_id=#permit_id#" target="_blank">Edit</a>
													</li>
												</cfloop>
											</ul>
										</cfif>
									</li>
								</cfloop>
							</ul>
						</section>
					
						<!--- Print permits associated with these accessions --->
						<section title="Permissions And Rights Documents from Accessions and Shipments" class="col-12 col-md-6 border rounded">
							<h3>
								Permissions and Rights Documents: 
								<br/>
								<small>PDF copies of Permits from Accessions and the Shipments of this Loan</small>
							</h3>
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
							<ul class="">
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
							<cfif ListLen(uriList,',',false) gt 0 >
								<a href="/Reports/combinePermits.cfm?transaction_id=#loanDetails.transaction_id#" >PDF of All Permission and Rights documents</a>
							</cfif>
						</section>
					</div>
					<section title="Projects" class="row border rounded bg-light pb-1">
						<div class="col-12">
							<h3>
								Projects associated with this loan: 
								<i class="fas fas-info fa-info-circle" onClick="getMCZDocs('Loan_Transactions##Projects_and_Permits')" aria-label="help link for projects"></i>
							</h3>
							<div id="projectsDiv"></div>
							<script>
								$(document).ready( loadProjects('projectsDiv',#loanDetails.transaction_id#) );
								function reloadTransProjects() {
									loadProjects('projectsDiv',#loanDetails.transaction_id#);
								} 
							</script>
							<div class="col-12">
								<button type="button" aria-label="Link this loan to an existing Project" id="linkProjectDialogLauncher"
										class="btn btn-sm btn-secondary" value="Link to Project"
										onClick=" openTransProjectLinkDialog(#transaction_id#, 'projectsLinkDialog','projectsDiv');">Link To Project</button>
								<button type="button" aria-label="Create a new Project linked to this loan" id="newProjectDialogLauncher"
										class="btn btn-sm btn-secondary" value="New Project"
										onClick=" openTransProjectCreateDialog(#transaction_id#, 'projectsAddDialog','projectsDiv');">New Project</button>
							</div>
							<div id="projectsLinkDialog"></div>
							<div id="projectsAddDialog"></div>
						</div>
					</section>
				<cfcatch>
					<h2>Error: #cfcatch.message#</h2>
					<cfif cfcatch.detail NEQ ''>
						#cfcatch.detail#
					</cfif>
				</cfcatch>
				</cftry>

			<!--- /div --->
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
				<div class="alert alert-danger" role="alert">
					<img src="/shared/images/Process-stop.png" alt="[ Error ]" style="float:left; width: 50px;margin-right: 1em;">
					<h1 class="h2">DELETE FAILED</h1>
					<p>You cannot delete an active loan. This loan probably has specimens or
						other transactions attached. Use your back button.</p>
					<p><a href="/info/bugs.cfm">“Feedback/Report Errors”</a></p>
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
					'authorized by')
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
