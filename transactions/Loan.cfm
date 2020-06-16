<cfset pageTitle = "Loan Management">
<cfif isdefined("action") AND action EQ 'newLoan'>
	<cfset pageTitle = "Create New Loan">
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
   function countCharsLeft(elementid, maxsize, outputelementid){ 
      var current = $('##'+elementid).val().length;
      var remaining = maxsize - current;
      var result = current + " characters, " + remaining + " left";
      $('##'+outputelementid).html(result);
   }
</script>
</cfoutput>
<!-------------------------------------------------------------------------------------------------->
<cfif action is "nothing">
	<cflocation url="/Transactions.cfm?type=Loan" addtoken="false">
</cfif>
<!-------------------------------------------------------------------------------------------------->
<cfif  action is "newLoan">
	<cfset title="New Loan">
	<cfoutput>
		<div class="container-fluid">
			<div class="row">
			<div class="col-12">
				<h2 class="wikilink mt-2 mb-0" >Create New Loan <i class="fas fas-info2 fa-info-circle" onClick="getMCZDocs('Loan_Transactions##Create_a_New_Loan')" aria-label="help link"></i></h2>
				<div class="form-row mb-2">
					<div class="col-12 col-md-9 col-xl-7 offset-xl-1">
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
								<div class="col-12 col-md-6 ui-widget"> <span>
									<label for="auth_agent_id">Authorized By</label>
									<span id="auth_agent_view">&nbsp;&nbsp;&nbsp;&nbsp;</span> </span>
									<input name="auth_agent_name" id="auth_agent_name" class="reqdClr form-control-sm" required >
									<input type="hidden" name="auth_agent_id" id="auth_agent_id"  >
									<script>
									$(makeTransAgentPicker('auth_agent_name','auth_agent_id','auth_agent_view'));
								</script> 
								</div>
								<div class="col-12 col-md-6"> <span>
									<label for="rec_agent_name">Received By:</label>
									<span id="rec_agent_view">&nbsp;&nbsp;&nbsp;&nbsp;</span> </span>
									<input  name="rec_agent_name" id="rec_agent_name" class="reqdClr form-control-sm" required >
									<input type="hidden" name="rec_agent_id" id="rec_agent_id" >
									<script>
									$(makeTransAgentPicker('rec_agent_name','rec_agent_id','rec_agent_view'));
								</script> 
								</div>
							</div>
							<div class="form-row mb-2">
								<div class="col-12 col-md-6"> <span>
									<label for="in_house_contact_agent_name">In-House Contact:</label>
									<span id="in_house_contact_agent_view">&nbsp;&nbsp;&nbsp;&nbsp;</span> </span>
									<input type="text" name="in_house_contact_agent_name" id="in_house_contact_agent_name"
										class="reqdClr form-control-sm" required >
									<input type="hidden" name="in_house_contact_agent_id" id="in_house_contact_agent_id" >
									<script>
									$(makeTransAgentPicker('in_house_contact_agent_name','in_house_contact_agent_id','in_house_contact_agent_view'));
								</script> 
								</div>
								<div class="col-12 col-md-6"> <span>
									<label for="additional_contact_agent_name">Additional Outside Contact:</label>
									<span id="additional_contact_agent_view">&nbsp;&nbsp;&nbsp;&nbsp;</span> </span>
									<input type="text" name="additional_contact_agent_name" id="additional_contact_agent_name" class="form-control-sm" >
									<input type="hidden" name="additional_contact_agent_id" id="additional_contact_agent_id" >
									<script>
									$(makeTransAgentPicker('additional_contact_agent_name','additional_contact_agent_id','additional_contact_agent_view'));
								</script> 
								</div>
							</div>
							<div class="form-row mb-2">
								<div class="col-12 col-md-6"> <span>
									<label for="recipient_institution_agent_name">Recipient Institution:</label>
									<span id="recipient_institution_agent_view">&nbsp;&nbsp;&nbsp;&nbsp;</span> </span>
									<input type="text" name="recipient_institution_agent_name"  id="recipient_institution_agent_name" 
										class="reqdClr form-control-sm" required >
									<input type="hidden" name="recipient_institution_agent_id"  id="recipient_institution_agent_id" >
									<script>
									$(makeTransAgentPicker('recipient_institution_agent_name','recipient_institution_agent_id','recipient_institution_agent_view'));
								</script> 
								</div>
								<div class="col-12 col-md-6"> <span>
									<label for="foruseby_agent_name">For Use By:</label>
									<span id="foruseby_agent_view">&nbsp;&nbsp;&nbsp;&nbsp;</span> </span>
									<input type="text" name="foruseby_agent_name" id="foruseby_agent_name" class="form-control-sm" >
									<input type="hidden" name="foruseby_agent_id" id="foruseby_agent_id" >
									<script>
									$(makeTransAgentPicker('foruseby_agent_name','foruseby_agent_id','foruseby_agent_view'));
								</script> 
								</div>
							</div>
							<div class="form-row mb-2">
								<div class="col-12 col-md-6">
									<label for="loan_type">Loan Type</label>
									<script>
									 $(function() {
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
												>
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
							<div class="form-row mb-2">
								<div class="col-12 col-md-10">
									<label for="nature_of_material">Nature of Material (<span id="length_nature_of_material"></span>)</label>
									<textarea name="nature_of_material" id="nature_of_material" rows="2" 
										onkeyup="countCharsLeft('nature_of_material', 4000, 'length_nature_of_material');"
										class="reqdClr form-control form-control-sm w-100" 
										required ></textarea>
								</div>
							</div>
							<div class="form-row mb-2">
								<div class="col-12 col-md-10">
									<label for="loan_description">Description (<span id="length_loan_description"></span>)</label>
									<textarea name="loan_description" id="loan_description"
										onkeyup="countCharsLeft('loan_description', 4000, 'length_loan_description');"
										class="form-control-sm form-control w-100" rows="2"></textarea>
								</div>
							</div>
							<div class="form-row mb-2">
								<div class="col-12 col-md-10">
									<label for="loan_instructions">Loan Instructions (<span id="length_loan_instructions"></span>)</label>
									<textarea name="loan_instructions" id="loan_instructions" 
										onkeyup="countCharsLeft('loan_instructions', 4000, 'length_loan_instructions');"
										rows="2" class="form-control form-control-sm w-100"></textarea>
								</div>
							</div>
							<div class="form-row mb-2">
								<div class="col-12 col-md-10">
									<label for="trans_remarks">Internal Remarks (<span id="length_trans_remarks"></span>)</label>
									<textarea name="trans_remarks" id="trans_remarks" 
										onkeyup="countCharsLeft('trans_remarks', 4000, 'length_trans_remarks');"
										class="form-control form-control-sm w-100" rows="2"></textarea>
								</div>
							</div>
							<script>
							// Make all textareas currently defined autogrow as text is entered.
							$("textarea").keyup(autogrow);  
						</script>
							<div class="form-row my-2">
								<div class="ml-auto">
									<input type="button" value="Create Loan" class="insBtn"
						      	 onClick="if (checkFormValidity($('##newLoan')[0])) { submit();  } ">
								</div>
							</div>
						</form>
						<script>
						$("##newLoan").submit( function(event) {
							validated = true;
							errors = "";
							errorCount = 0;
							$(".reqdClr").each(function(index, element) {
								if ($(element).val().length===0) {
									validated = false;
									errorCount++;
									errors = errors + " " + element.name;
								}
							});
							if (!validated) {
								if (errorCount==1) {
									msg = 'A required value is missing:' + errors;
								} else {
									msg = errorCount + ' required values are missing:' + errors;
								}
								var errdiv = document.createElement('div');
								errdiv.innerHTML = msg;
								$(errdiv).dialog({ title:"Error Creating Loan" }).dialog("open"); 
								event.preventDefault();
							};
						});
					</script> 
					</div>
					<div class="coll-sm-4 ml-sm-4"> <!--- Begin next available number list, ml-sm-4 to provide offset from column above holding form. --->
						<div id="nextNumDiv" class="border border-primary p-md-2">
							<h3>Next Available Loan Number:</h3>
							<!--- Find list of all non-observational collections --->
							<cfquery name="loanableCollections" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							select collection_id, collection_cde, collection from collection 
							where collection not like '% Observations'
							order by collection 
						</cfquery>
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
#cfcatch.detail# 										<br>
#cfcatch.message# 
										<!--- Put an error message into nextNumberQuery.nextNumber --->
										<cfquery name="nextNumberQuery" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
										select 'check data' as nextNumber from dual
									</cfquery>
									</cfcatch>
								</cftry>
								<cfif len(nextNumberQuery.nextNumber) gt 0>
									<span class="likeLink" onclick="setLoanNum('#collection_id#','#nextNumberQuery.nextNumber#')">#collection# #nextNumberQuery.nextNumber#</span>
									<cfelse>
									<span style="font-size:x-small"> No data available for #collection#. </span>
								</cfif>
								<br>
							</cfloop>
						</div>
					</div>
				</div>
			</div>
		
	</cfoutput>
</cfif>
<!-------------------------------------------------------------------------------------------------->
<cfif action is "editLoan">
	<cfset title="Edit Loan">
	<cfoutput>
		<cftry>
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
             select p.loan_number, p.transaction_id from loan c left join loan_relations lr on c.transaction_id = lr.related_transaction_id left join loan p on lr.transaction_id = p.transaction_id where lr.relation_type = 'Subloan' and c.transaction_id = <cfqueryparam value=#transaction_id# CFSQLType="CF_SQL_DECIMAL" >
        </cfquery>
			<!--- Subloans of the current loan (used for exhibition-master/exhibition-subloans) --->
			<cfquery name="childLoans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
             select c.loan_number, c.transaction_id from loan p left join loan_relations lr on p.transaction_id = lr.transaction_id left join loan c on lr.related_transaction_id = c.transaction_id where lr.relation_type = 'Subloan' and p.transaction_id = <cfqueryparam value=#transaction_id# CFSQLType="CF_SQL_DECIMAL" >  order by c.loan_number
        </cfquery>
			<!---  Loans which are available to be used as subloans for an exhibition master loan (exhibition-subloans that are not allready children) --->
			<cfquery name="potentialChildLoans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
             select pc.loan_number, pc.transaction_id from loan pc left join loan_relations lr on pc.transaction_id = lr.related_transaction_id
             where pc.loan_type = 'exhibition-subloan' and (lr.transaction_id is null or lr.relation_type <> 'Subloan')
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
		
		<div class="container-fluid">
		<div class="row">
		<cftry>
			<div class="col-12">
			<form name="editloan" id="editLoan" action="/transactions/Loan.cfm" method="post">
				<div class="row mt-3">
					<div class="col-12 col-md-9 col-xl-7 offset-xl-1">
						<h2 class="wikilink mt-2 mb-0">Edit Loan <i class="fas fas-info2 fa-info-circle" onClick="getMCZDocs('Loan_Transactions##Edit_a_Loan')" aria-label="help link"></i><span class="loanNum">#loanDetails.collection# #loanDetails.loan_number# </span> </h2>
						<input type="hidden" name="action" value="saveEdits">
						<input type="hidden" name="transaction_id" value="#loanDetails.transaction_id#">
						<span class="small d-block mb-2">Entered by #loanDetails.enteredby#</span>
						<div class="form-row mb-2">
							<div class="col-12 col-md-6">
								<label class="data-entry-label">Department</label>
								<select name="collection_id" id="collection_id" size="1" class="reqdClr form-control-sm" >
									<cfloop query="ctcollection">
										<option <cfif ctcollection.collection_id is loanDetails.collection_id> selected </cfif>
										value="#ctcollection.collection_id#">#ctcollection.collection#</option>
									</cfloop>
								</select>
							</div>
							<div class="col-12 col-md-6">
								<label for="loan_number" class="data-entry-label">Loan Number (yyyy-n-Coll)</label>
								<input type="text" name="loan_number" id="loan_number" value="#loanDetails.loan_number#" class="reqdClr form-control-sm" 
							required  pattern="#LOANNUMBERPATTERN#"  >
							</div>
						</div>
						<!--- Obtain picklist values for loan agents controls.  --->
						<cfquery name="inhouse" dbtype="query">
								select count(distinct(agent_id)) c from loanAgents where trans_agent_role='in-house contact'
									</cfquery>
						<cfquery name="outside" dbtype="query">
								select count(distinct(agent_id)) c from loanAgents where trans_agent_role='received by'
									</cfquery>
						<cfquery name="authorized" dbtype="query">
								select count(distinct(agent_id)) c from loanAgents where trans_agent_role='authorized by'
									</cfquery>
						<cfquery name="recipientinstitution" dbtype="query">
								select count(distinct(agent_id)) c from loanAgents where trans_agent_role='recipient institution'
									</cfquery>
						<!--- Begin loan agents table TODO: Rework --->
						<div class="form-row my-2">
							<div class="col-12 table-responsive mt-2">
								<table id="loanAgents" class="table table-sm">
									<thead class="thead-light">
										<tr>
											<th colspan="2"> <span>Agent&nbsp;Name&nbsp;
												<button type="button" class="ui-button btn-primary btn-xs ui-widget ui-corner-all" id="button_add_trans_agent" onclick=" addTransAgentToForm('','','','editLoan');"> Add Row </button>
												</span> </th>
											<th>Role</th>
											<th>Delete?</th>
											<th>Clone As</th>
										</tr>
									</thead>
									<tbody>
										<tr>
											<td colspan="5">
												<cfif inhouse.c is 1 and outside.c is 1 and authorized.c GT 0 and recipientinstitution.c GT 0 >
													<span class="text-success small px-1">OK to print</span>
												<cfelse>
													<span class="text-danger small px-1">
													One "authorized by", one "in-house contact", one "received by", and one "recipient institution" are required to print loan forms. 
													</span>
												</cfif>
											</td>
										</tr>
										<cfset i=1>
										<cfloop query="loanAgents">
											<tr>
												<td>
													<input type="hidden" name="trans_agent_id_#i#" id="trans_agent_id_#i#" value="#trans_agent_id#"><!--- Identifies row in trans_agent table --->
													<input type="text" name="trans_agent_#i#" id="trans_agent_#i#" class="reqdClr data-entry-input" value="#agent_name#"><!--- human readable --->
													<input type="hidden" name="agent_id_#i#" id="agent_id_#i#" value="#agent_id#"
														onchange=" updateAgentLink($('##agent_id_#i#').val(),'agentViewLink_#i#'); "><!--- Link to the agent record --->
													<script>
														$(document).ready(function() {
															$(makeTransAgentPicker('trans_agent_#i#','agent_id_#i#','agentViewLink_#i#'));  // human readable picks id for link to agent
														});
													</script>
												</td>
												<td style=" min-width: 3.5em; ">
													<span id="agentViewLink_#i#" class="px-2"><a href="/agents.cfm?agent_id=#agent_id#" target="_blank">View</a>
													<cfif loanAgents.worstagentrank EQ 'A'>
														&nbsp;
														<cfelseif loanAgents.worstagentrank EQ 'F'>
														<img src='/shared/images/flag-red.svg.png' width='16' alt="flag-red">
														<cfelse>
														<img src='/shared/images/flag-yellow.svg.png' width='16' alt="flag-yellow">
													</cfif>
													</span>
												</td>
												<td>
													<select name="trans_agent_role_#i#" id="trans_agent_role_#i#" class="data-entry-select">
														<cfloop query="cttrans_agent_role">
															<option 
																<cfif cttrans_agent_role.trans_agent_role is loanAgents.trans_agent_role> selected="selected"</cfif>
																value="#trans_agent_role#">#trans_agent_role#</option>
														</cfloop>
													</select>
												</td>
												<td>
													<input type="checkbox" name="del_agnt_#i#" id="del_agnt_#i#" value="1" class="data-entry-input">
													<!--- uses i and the trans_agent_id to delete a row from trans_agent --->
												</td>
												<td>
													<select id="cloneTransAgent_#i#" onchange="cloneTransAgent(#i#)" class="data-entry-select">
														<option value=""></option>
														<cfloop query="cttrans_agent_role">
															<option value="#trans_agent_role#">#trans_agent_role#</option>
														</cfloop>
													</select>
												</td>
											</tr>
											<cfset i=i+1>
										</cfloop>
										<cfset na=i-1>
									<input type="hidden" id="numAgents" name="numAgents" value="#na#">
										</tbody>
									
								</table>
								<!-- end agents table ---> 
							</div>
						</div>
						<div class="form-row mb-2">
							<div class="col-12 col-md-4">
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
							<div class="col-12 col-md-4">
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
							</div>
							<div class="col-12 col-md-4 bg-light mt-4 border">
								<cfif loanDetails.loan_status EQ 'closed' and len(loanDetails.closed_date) GT 0>
									Date Closed: #loanDetails.closed_date#
								</cfif>
								</span> </div>
						</div>
						<div class="form-row mb-2">
							<div class="col-12 col-md-6">
								<label for="initiating_date" class="data-entry-label">Transaction Date</label>
								<input type="text" name="initiating_date" id="initiating_date"
							value="#dateformat(loanDetails.trans_date,"yyyy-mm-dd")#" class="reqdClr form-control-sm" required >
							</div>
							<div class="col-12 col-md-6">
								<label for="return_due_date" class="data-entry-label">Due Date</label>
								<input type="text" id="return_due_date" name="return_due_date" class="form-control-sm"
							value="#dateformat(loanDetails.return_due_date,'yyyy-mm-dd')#">
							</div>
						</div>
						<div class="form-row mb-2" id="insurance_section">
							<div class="col-12 col-md-6">
								<label for="insurance_value" class="data-entry-label">Insurance value</label>
								<input type="text" name="insurance_value" id="insurance_value" value="#loanDetails.insurance_value#" size="40" class="form-control-sm">
							</div>
							<div class="col-12 col-md-6">
								<label for="insurance_maintained_by" class="data-entry-label">Insurance Maintained By</label>
								<input type="text" name="insurance_maintained_by" id="insurance_maintained_by" value="#loanDetails.insurance_maintained_by#" size="40" class="form-control-sm">
							</div>
						</div>
						<div class="form-row mb-2">
							<div class="col-12 col-md-6"> <span id="parentloan_section">Exhibition-Master Loan:
								<cfif parentLoan.RecordCount GT 0>
									<cfloop query="parentLoan">
										<a href="/transactions/Loan.cfm?action=editLoan&transaction_id=#parentLoan.transaction_id#">#parentLoan.loan_number#</a>
									</cfloop>
									<cfelse>
									This exhibition subloan has not been linked to a master loan.
								</cfif>
								</span> <span id="subloan_section"> <span id="subloan_list"> Exhibition-Subloans (#childLoans.RecordCount#):
								<cfif childLoans.RecordCount GT 0>
									<cfset childLoanCounter = 0>
									<cfset childseparator = "">
									<cfloop query="childLoans">
#childseparator# 										<a href="/transactions/Loan.cfm?action=editLoan&transaction_id=#childLoans.transaction_id#">#childLoans.loan_number#</a>
										<button class="ui-button ui-widget ui-corner-all" id="button_remove_subloan_#childLoanCounter#"> - </button>
										<script>
										$(function() {
											$("##button_remove_subloan_#childLoanCounter#").click( function(event) {
												event.preventDefault();
												$.get( "component/functions.cfc", {
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
														retval = retval + separator + "<a href='/transactions/Loan.cfm?action=editLoan&transaction_id=" + r.DATA.TRANSACTION_ID[i] + "'>" + r.DATA.LOAN_NUMBER[i] + "</a>[-]";
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
										$.get( "component/functions.cfc",
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
												retval = retval + separator + "<a href='/transactions/Loan.cfm?action=editLoan&transaction_id=" + r.DATA.TRANSACTION_ID[i] + "'>" + r.DATA.LOAN_NUMBER[i] + "</a>[-]";
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
						<div class="form-row mb-2">
							<div class="col-12">
								<label for="nature_of_material" class="data-entry-label">Nature of Material (<span id="length_nature_of_material"></span>)</label>
								<textarea name="nature_of_material" id="nature_of_material" rows="2" 
									onkeyup="countCharsLeft('nature_of_material', 4000, 'length_nature_of_material');"
									class="reqdClr autogrow border rounded w-100" required >#loanDetails.nature_of_material#</textarea>
							</div>
						</div>
						<div class="form-row mb-2">
							<div class="col-12">
								<label for="loan_description" class="data-entry-label">Description (<span id="length_loan_description"></span>)</label>
								<textarea name="loan_description" id="loan_description" rows="2"
									onkeyup="countCharsLeft('loan_description', 4000, 'length_loan_description');"
									class="autogrow border rounded w-100">#loanDetails.loan_description#</textarea>
							</div>
						</div>
						<div class="form-row mb-2">
							<div class="col-12">
								<label for="loan_instructions" class="data-entry-label">Loan Instructions (<span id="length_loan_instructions"></span>)</label>
								<textarea name="loan_instructions" id="loan_instructions" rows="2" 
									onkeyup="countCharsLeft('loan_instructions', 4000, 'length_loan_instructions');"
									class="autogrow border rounded w-100">#loanDetails.loan_instructions#</textarea>
							</div>
						</div>
						<div class="form-row mb-2">
							<div class="col-12">
								<label for="trans_remarks" class="data-entry-label">Internal Remarks (<span id="length_trans_remarks"></span>)</label>
								<textarea name="trans_remarks" id="trans_remarks" 
									onkeyup="countCharsLeft('trans_remarks', 4000, 'length_trans_remarks');"
									rows="2" class="autogrow border w-100 rounded">#loanDetails.trans_remarks#</textarea>
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
						</div>
						<div class="form-row mb-2">
							<div class="col-12">
								<input type="button" value="Save Edits" class="btn btn-xs btn-primary"
											onClick="if (checkFormValidity($('##editLoan')[0])) { editLoan.action.value='saveEdits'; submit();  } ">
								<div class="w-100 mt-4 float-right">
							<input type="button" value="Delete Loan" class="btn btn-xs btn-warning float-right"
											onClick="editloan.action.value='deleLoan';confirmDelete('editloan');">
							<input type="button" value="Add Items" class="btn btn-xs btn-secondary"
											onClick="window.open('SpecimenSearch.cfm?Action=dispCollObj&transaction_id=#transaction_id#');">
							<input type="button" value="Add Items BY Barcode" class="btn btn-xs btn-secondary"
											onClick="window.open('loanByBarcode.cfm?transaction_id=#transaction_id#');">
							<input type="button" value="Review Items" class="btn btn-xs btn-secondary"
											onClick="window.open('a_loanItemReview.cfm?transaction_id=#transaction_id#');">
						</div>
					</div>
				</div>
				<div class="form-row my-4">
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
									</thead><tbody>
									<cfloop query="getDispositions">
										<cfif len(trim(getDispositions.deacc_number)) GT 0>
											<tr>
												<td>#pcount#</td>
												<td>#coll_obj_disposition#</td>
												<td><a href="Deaccession.cfm?action=listDeacc&deacc_number=#deacc_number#">#deacc_number# (#deacc_status#)</a></td>
												</tr>
											<cfelse>
											<tr>
												<td>#pcount#</td>
												<td>#coll_obj_disposition#</td>
												<td>Not in a Deaccession</td>
											</tr>
										</cfif>
									</cfloop>
										</tbody>
								</table>
							</cfif>
						</cfif>
					</div>
				</div>
				</div>
				<div class="col-12 col-md-3">
					<div id="project" class="p-3 mb-2 bg-light mt-4 border text-dark">
						<h3>Projects associated with this loan: <i class="fas fas-info2 fa-info-circle" onClick="getMCZDocs('Loan_Transactions##Projects_and_Permits')" aria-label="help link"></i></h3>
						<cfquery name="projs" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
											select project_name, project.project_id from project,
											project_trans where
											project_trans.project_id =  project.project_id
											and transaction_id= <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
										</cfquery>
						<ul class="list-group">
							<cfif projs.recordcount gt 0>
								<cfloop query="projs">
									<li class="list-group-item"><a href="/Project.cfm?Action=editProject&project_id=#project_id#"><strong>#project_name#</strong></a></li>
								</cfloop>
								<cfelse>
								<li class="list-group-item">None</li>
							</cfif>
						</ul>
						<hr>
						<label for="project_id">Pick a Project to associate with this Loan</label>
						<input type="hidden" name="project_id" class="form-control-sm">
						<input type="text" name="pick_project_name" class="reqdClr form-control-sm" onchange="getProject('project_id','pick_project_name','editloan',this.value); return false;"onKeyPress="return noenter(event);">
						<hr>
						<label for="create_project"> Create a project from this Loan </label>
						<div id="create_project">
							<label for="newAgent_name" class="data-entry-label">Project Agent Name</label>
							<input type="text" name="newAgent_name" id="newAgent_name"
								class="reqdClr form-control-sm"
								onchange="findAgentName('newAgent_name_id','newAgent_name',this.value); return false;"
								onKeyPress="return noenter(event);"
								value="">
							<input type="hidden" name="newAgent_name_id" id="newAgent_name_id" value="">
							<cfquery name="ctProjAgRole" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
									select project_agent_role from ctproject_agent_role order by project_agent_role
								</cfquery>
							<label for="project_agent_role" class="data-entry-label">Project Agent Role</label>
							<select name="project_agent_role" size="1" class="reqdClr form-control-sm">
								<cfloop query="ctProjAgRole">
									<option value="#ctProjAgRole.project_agent_role#">#ctProjAgRole.project_agent_role#</option>
								</cfloop>
							</select>
							<label for="project_name" class="data-entry-label">Project Title</label>
							<textarea name="project_name" cols="50" rows="2" class="reqdClr form-control autogrow"></textarea>
							<label for="start_date" class="data-entry-label">Project Start Date</label>
							<input type="text" name="start_date" value="#dateformat(loanDetails.trans_date,"yyyy-mm-dd")#" class="form-control-sm">
							<label for="end_date" class="data-entry-label">Project End Date</label>
							<input type="text" name="end_date" class="form-control-sm">
							<label for="project_description" class="data-entry-label">Project Description</label>
							<textarea name="project_description" class="form-control autogrow"
										id="project_description" cols="50" rows="2">#loanDetails.loan_description#</textarea>
							<label for="project_remarks" class="data-entry-label">Project Remark</label>
							<textarea name="project_remarks" cols="50" rows="2" class="form-control autogrow">#loanDetails.trans_remarks#</textarea>
						</div>
						<div class="form-check">
							<input type="checkbox" name="saveNewProject"  value="yes" class="form-check-input" id="saveNewProject">
							<label class="form-check-label" for="saveNewProject">Check to create project with save</label>
						</div>
					</div>
				</div>
				</div>
			</form>
			</div>
			</div>
			</div>
			<div class="container-fluid">
			<div class="row">
				<div class="col-12 col-xl-10 offset-xl-1">
					<div class="form-row mb-4">
						<div class="col-12 col-md-7">
							<label for="redir">Print...</label>
							<select name="redir" class="form-control-sm" id="redir" size="1" onchange="if(this.value.length>0){window.open(this.value,'_blank')};">
								<option value=""></option>
								<!--- report_printer.cfm takes parameters transaction_id, report, and sort, where
								sort={a field name that is in the select portion of the query specified in the custom tag}, or
								sort={cat_num_pre_int}, which is interpreted as order by cat_num_prefix, cat_num_integer.
						--->
								<cfif inhouse.c is 1 and outside.c is 1 and authorized.c GT 0 >
									<option value="/Reports/report_printer.cfm?transaction_id=#transaction_id#&report=mcz_loan_header">MCZ Invoice Header</option>
								</cfif>
								<option value="/Reports/report_printer.cfm?transaction_id=#transaction_id#&report=mcz_files_loan_header">Header Copy for MCZ Files</option>
								<cfif inhouse.c is 1 and outside.c is 1 and loanDetails.loan_type eq 'exhibition-master' and recipientinstitution.c GT 0 >
									<option value="/Reports/report_printer.cfm?transaction_id=#transaction_id#&report=mcz_exhibition_loan_header">MCZ Exhibition Loan Header</option>
								</cfif>
								<cfif inhouse.c is 1 and outside.c is 1 and loanDetails.loan_type eq 'exhibition-master' and recipientinstitution.c GT 0 >
									<option value="/Reports/report_printer.cfm?transaction_id=#transaction_id#&report=mcz_exhib_loan_header_five_plus">MCZ Exhibition Loan Header Long</option>
								</cfif>
								<cfif inhouse.c is 1 and outside.c is 1 >
									<option value="/Reports/report_printer.cfm?transaction_id=#transaction_id#&report=mcz_loan_legacy">MCZ Legacy Invoice Header</option>
								</cfif>
								<cfif inhouse.c is 1 and outside.c is 1 and authorized.c GT 0 >
									<option value="/Reports/report_printer.cfm?transaction_id=#transaction_id#&report=mcz_loan_items&sort=cat_num">MCZ Item Invoice</option>
									<option value="/Reports/report_printer.cfm?transaction_id=#transaction_id#&report=mcz_loan_items&sort=cat_num_pre_int">MCZ Item Invoice (cat num sort)</option>
									<option value="/Reports/report_printer.cfm?transaction_id=#transaction_id#&report=mcz_loan_items&sort=scientific_name">MCZ Item Invoice (taxon sort)</option>
									<option value="/Reports/report_printer.cfm?transaction_id=#transaction_id#&report=mcz_loan_items_parts&sort=cat_num">MCZ Item Parts Grouped Invoice</option>
									<option value="/Reports/report_printer.cfm?transaction_id=#transaction_id#&report=mcz_loan_items_parts&sort=cat_num_pre_int">MCZ Item Parts Grouped Invoice (cat num sort)</option>
									<option value="/Reports/report_printer.cfm?transaction_id=#transaction_id#&report=mcz_loan_items_parts&sort=scientific_name">MCZ Item Parts Grouped Invoice (taxon sort)</option>
								</cfif>
								<cfif inhouse.c is 1 and outside.c is 1 >
									<option value="/Reports/report_printer.cfm?transaction_id=#transaction_id#&report=mcz_loan_summary">MCZ Loan Summary Report</option>
								</cfif>
								<option value="/Reports/MVZLoanInvoice.cfm?transaction_id=#transaction_id#&Action=itemLabels&format=Malacology">MCZ Drawer Tags</option>
								<option value="/edecView.cfm?transaction_id=#transaction_id#">USFWS eDec</option>
							</select>
						</div>
					</div>
					<div class="form-row mb-2 mt-5">
						<div class="col-12 col-md-12 border bg-light px-3 mt-2 py-1">
							<h3>Media documenting this Loan: <br/>
								<small>Include copies of signed loan invoices and correspondence here.  Attach permits to shipments.</small></h3>
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
							&nbsp; <span id='addMedia_#transaction_id#'>
							<input type='button' onClick="openlinkmediadialog('newMediaDlg_#transaction_id#','Loan: #loanDetails.loan_number#','#transaction_id#','#relation#',reloadTransMedia);" value='Link Media' class='btn btn-xs btn-secondary' >
							&nbsp; </span> </span>
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
					</div>
					<div class="form-row mb-2">
						<div class="col-12 col-md-12">
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
							<cfloop query=ctSovereignNation>
								<cfif len(sovereign_nation) eq 0>
									<cfset sovereign_nation = '[no value set]'>
								</cfif>
								<span>#sep##sovereign_nation#&nbsp;(#ct#)</span>
								<cfset sep="; ">
							</cfloop>
						</div>
					</div>
					<div class="form-row mb-2">
						<div class="col-12 col-md-12">
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
							<cfquery name="ctShip" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select shipped_carrier_method from ctshipped_carrier_method order by shipped_carrier_method
				</cfquery>
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
					$(function() {
					$("##dialog-shipment").dialog({
						autoOpen: false,
						modal: true,
						width: 650,
						buttons: {
							"Save": function() {  saveShipment(#transaction_id#); } ,
							Cancel: function() { $(this).dialog( "close" ); }
						},
						close: function() {
							$(this).dialog( "close" );
						}
					});
				});
				</script>
							<div class="addstyle">
								<input type="button" class="btn btn-xs btn-secondary float-left mr-4" value="Add Shipment" onClick="$('##dialog-shipment').dialog('open'); setupNewShipment(#transaction_id#);">
								<div class="shipmentnote float-left mb-4">Note: please check the <a href="https://code.mcz.harvard.edu/wiki/index.php/Country_Alerts">Country Alerts</a> page for special instructions or restrictions associated with specific countries</div>
							</div>
							<!---moved this to inside of the shipping block--one div up---> 
						</div>
					</div>
					
					<!----  Shipment Popup Dialog autoOpen is false --->
					<div id="dialog-shipment" title="Create new Shipment">
						<form name="shipmentForm" id="shipmentForm" >
							<fieldset>
								<input type="hidden" name="transaction_id" value="#transaction_id#" id="shipmentForm_transaction_id" >
								<input type="hidden" name="shipment_id" value="" id="shipment_id">
								<input type="hidden" name="returnFormat" value="json" id="returnFormat">
								<table>
									<tr>
										<td><label for="shipped_carrier_method">Shipping Method</label>
											<select name="shipped_carrier_method" id="shipped_carrier_method" size="1" class="reqdClr">
												<option value=""></option>
												<cfloop query="ctShip">
													<option value="#ctShip.shipped_carrier_method#">#ctShip.shipped_carrier_method#</option>
												</cfloop>
											</select></td>
										<td colspan="2"><label for="carriers_tracking_number">Tracking Number</label>
											<input type="text" value="" name="carriers_tracking_number" id="carriers_tracking_number" size="30" ></td>
									</tr>
									<tr>
										<td><label for="no_of_packages">Number of Packages</label>
											<input type="text" value="1" name="no_of_packages" id="no_of_packages"></td>
										<td><label for="shipped_date">Ship Date</label>
											<input type="text" value="#dateformat(Now(),'yyyy-mm-dd')#" name="shipped_date" id="shipped_date"></td>
										<td><label for="foreign_shipment_fg">Foreign shipment?</label>
											<select name="foreign_shipment_fg" id="foreign_shipment_fg" size="1">
												<option selected value="0">no</option>
												<option value="1">yes</option>
											</select></td>
									</tr>
									<tr>
										<td><label for="package_weight">Package Weight (TEXT, include units)</label>
											<input type="text" value="" name="package_weight" id="package_weight"></td>
										<td><label for="insured_for_insured_value">Insured Value (NUMBER, US$)</label>
											<input type="text" validate="float" label="Numeric value required."
										value="" name="insured_for_insured_value" id="insured_for_insured_value"></td>
										<td><label for="hazmat_fg">HAZMAT?</label>
											<select name="hazmat_fg" id="hazmat_fg" size="1">
												<option selected value="0">no</option>
												<option value="1">yes</option>
											</select></td>
									</tr>
								</table>
								<label for="packed_by_agent">Packed By Agent</label>
								<input type="text" name="packed_by_agent" class="reqdClr" size="50" value="" id="packed_by_agent"
							onchange="getAgent('packed_by_agent_id','packed_by_agent','shipmentForm',this.value); return false;"
							onKeyPress="return noenter(event);">
								<input type="hidden" name="packed_by_agent_id" value="" id="packed_by_agent_id" >
								<label for="shipped_to_addr">Shipped To Address</label>
								<input type="button" value="Pick Address" class="picBtn"
							onClick="addrPick('shipped_to_addr_id','shipped_to_addr','shipmentForm'); return false;">
								<textarea name="shipped_to_addr" id="shipped_to_addr" cols="60" rows="5"
							readonly="yes" class="reqdClr"></textarea>
								<!--- not autogrow --->
								<input type="hidden" name="shipped_to_addr_id" id="shipped_to_addr_id" value="">
								<label for="shipped_from_addr">Shipped From Address</label>
								<input type="button" value="Pick Address" class="picBtn"
							onClick="addrPick('shipped_from_addr_id','shipped_from_addr','shipmentForm'); return false;">
								<textarea name="shipped_from_addr" id="shipped_from_addr" cols="60" rows="5"
							readonly="yes" class="reqdClr"></textarea>
								<!--- not autogrow --->
								<input type="hidden" name="shipped_from_addr_id" id="shipped_from_addr_id" value="">
								<label for="shipment_remarks">Remarks</label>
								<input type="text" value="" name="shipment_remarks" id="shipment_remarks" size="60">
								<label for="contents">Contents</label>
								<input type="text" value="" name="contents" id="contents" size="60">
							</fieldset>
						</form>
						<div id="shipmentFormPermits"></div>
						<div id="shipmentFormStatus"></div>
					</div>
					<!----  End Shipment dialog --->
					
					<div class="form-row mb-2 mt-3">
						<div class="col-12 col-md-12 border bg-light px-3">
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
									<li class="accn2"><a  style="font-weight:bold;" href="editAccn.cfm?Action=edit&transaction_id=#transaction_id#"><span>Accession ##</span> #accn_number#</a>, <span>Type:</span> #accn_type#, <span>Received: </span>#dateformat(received_date,'yyyy-mm-dd')#
										<cfquery name="getAccnPermits" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							select distinct permit_num, permit.permit_type, permit.specific_type, issued_date, permit.permit_id,
								issuedBy.agent_name as IssuedByAgent
							from permit_trans 
								left join permit on permit_trans.permit_id = permit.permit_id
								left join ctspecific_permit_type on permit.specific_type = ctspecific_permit_type.specific_type
								left join preferred_agent_name issuedBy on permit.issued_by_agent_id = issuedBy.agent_id
							where permit_trans.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value=#transaction_id#>
								and ctspecific_permit_type.accn_show_on_shipment = 1
							order by permit.permit_type, issued_date
						</cfquery>
										<cfif getAccnPermits.recordcount gt 0>
											<ul class="accnpermit">
												<cfloop query="getAccnPermits">
													<li><span style="font-weight:bold;">#permit_type#:</span> #specific_type# #permit_num#, <span>Issued:</span> #dateformat(issued_date,'yyyy-mm-dd')# <span>by</span> #IssuedByAgent# <a href="Permit.cfm?Action=editPermit&permit_id=#permit_id#" target="_blank">Edit</a></li>
												</cfloop>
											</ul>
										</cfif>
									</li>
								</cfloop>
							</ul>
						</div>
					</div>
					
					<!--- Print permits associated with these accessions --->
					<div class="form-row mb-5">
						<div class="col-12 col-md-12">
							<h3>Permissions and Rights Documents: <br/>
								<small>PDF copies of Permits from Accessions and the Shipments of this Loan</small></h3>
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
								p.permit_type, p.permit_num, p.permit_title, p.specific_type, 1 as show_on_shipment
							from shipment s
								left join permit_shipment ps on s.shipment_id = ps.shipment_id
								left join permit p on ps.permit_id = p.permit_id
							where s.transaction_id = <cfqueryparam CFSQLType="CF_SQL_DECIMAL" value="#loanDetails.transaction_id#">
						) where permit_type is not null
					</cfquery>
							<cfset uriList = ''>
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
							<cfif ListLen(uriList,',',false) gt 0 >
								<a href="/Reports/combinePermits.cfm?transaction_id=#loanDetails.transaction_id#" >PDF of All Permission and Rights documents</a>
							</cfif>
						</div>
					</div>
				</div>
				<div class="col-12 col-md-4"></div>
			</div>
			<cfcatch>
				<h2>Error: #cfcatch.message#</h2>
				<cfif cfcatch.detail NEQ ''>
#cfcatch.detail#
				</cfif>
			</cfcatch>
		</cftry>
		</div>
		
		<!--- class="container" --->
		</div>
		<!--- class="container-fluid form-div" ---> 
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
		Loan deleted.....
		<cfcatch>
			DELETE FAILED
			<p>You cannot delete an active loan. This loan probably has specimens or
				other transactions attached. Use your back button.</p>
			<p>
				<cfdump var=#cfcatch#>
			</p>
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
<cfif action is "saveEdits">
	<cfoutput>
		<cftransaction>
			<cfquery name="upTrans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE trans SET
					collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_id#">,
					TRANS_DATE = <cfqueryparam cfsqltype="CF_SQL_TIMESTAMP" value="#dateformat(initiating_date,"yyyy-mm-dd")#">,
					NATURE_OF_MATERIAL = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#NATURE_OF_MATERIAL#">,
					trans_remarks = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trans_remarks#">
				where
					transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
			</cfquery>
			<cfif not isdefined("return_due_date") or len(return_due_date) eq 0  >
				<!--- If there is no value set for return_due_date, don't overwrite an existing value.  ---> 
				<!--- This prevents edits to exhibition-subloans from wiping out an existing date value --->
				<cfquery name="upLoan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					UPDATE loan SET
						LOAN_TYPE = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#LOAN_TYPE#">,
						LOAN_NUMBER = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#loan_number#">,
						loan_status = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#loan_status#">,
						loan_description = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#loan_description#">,
						LOAN_INSTRUCTIONS = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#LOAN_INSTRUCTIONS#">,
						insurance_value = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#INSURANCE_VALUE#">,
						insurance_maintained_by = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#INSURANCE_MAINTAINED_BY#">
					where 
						transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
				</cfquery>
				<cfelse>
				<cfquery name="upLoan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					UPDATE loan SET
						return_due_date = <cfqueryparam cfsqltype="CF_SQL_TIMESTAMP" value="#dateformat(return_due_date,"yyyy-mm-dd")#">,
						LOAN_TYPE = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#LOAN_TYPE#">,
						LOAN_NUMBER = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#loan_number#">,
						loan_status = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#loan_status#">,
						loan_description = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#loan_description#">,
						LOAN_INSTRUCTIONS = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#LOAN_INSTRUCTIONS#">,
						insurance_value = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#INSURANCE_VALUE#">,
						insurance_maintained_by = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#INSURANCE_MAINTAINED_BY#">
					where 
						transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
				</cfquery>
			</cfif>
			<cfif isdefined("project_id") and len(project_id) gt 0>
				<cfquery name="newProj" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						INSERT INTO project_trans (
							project_id, 
							transaction_id)
						VALUES (
							<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#project_id#">,
							<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">)
					</cfquery>
			</cfif>
			<cfif isdefined("loan_type") and loan_type EQ 'exhibition-master' >
				<!--- Propagate due date to child exhibition-subloans --->
				<cfset formatted_due_date = dateformat(return_due_date,"yyyy-mm-dd")>
				<cfquery name="upChildLoans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						UPDATE loan SET
							return_due_date = <cfqueryparam value = "#formatted_due_date#" CFSQLType="CF_SQL_TIMESTAMP">
						WHERE 
							loan_type = 'exhibition-subloan' AND
 							transaction_id in (select lr.related_transaction_id from loan_relations lr where
							lr.relation_type = 'Subloan' AND
							lr.transaction_id = <cfqueryparam value = "#TRANSACTION_ID#" CFSQLType="CF_SQL_DECIMAL">)
					</cfquery>
			</cfif>
			<cfif isdefined("saveNewProject") and saveNewProject is "yes">
				<cfquery name="newProj" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						INSERT INTO project (
							PROJECT_ID,
							PROJECT_NAME
							<cfif len(#START_DATE#) gt 0>
								,START_DATE
							</cfif>
							<cfif len(#END_DATE#) gt 0>
								,END_DATE
							</cfif>
							<cfif len(#PROJECT_DESCRIPTION#) gt 0>
								,PROJECT_DESCRIPTION
							</cfif>
							<cfif len(#PROJECT_REMARKS#) gt 0>
								,PROJECT_REMARKS
							</cfif>
							 )
						VALUES (
							sq_project_id.nextval,
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#PROJECT_NAME#">
							<cfif len(#START_DATE#) gt 0>
								,<cfqueryparam cfsqltype="CF_SQL_TIMESTAMP" value="#dateformat(START_DATE,"yyyy-mm-dd")#">
							</cfif>
							<cfif len(#END_DATE#) gt 0>
								,<cfqueryparam cfsqltype="CF_SQL_TIMESTAMP" value="#dateformat(END_DATE,"yyyy-mm-dd")#">
							</cfif>
							<cfif len(#PROJECT_DESCRIPTION#) gt 0>
								,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#PROJECT_DESCRIPTION#">
							</cfif>
							<cfif len(#PROJECT_REMARKS#) gt 0>
								,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#PROJECT_REMARKS#">
							</cfif>
							 )
					</cfquery>
				<cfquery name="newProjAgnt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						INSERT INTO project_agent (
							PROJECT_ID,
							AGENT_NAME_ID,
							PROJECT_AGENT_ROLE,
							AGENT_POSITION )
						VALUES (
							sq_project_id.currval,
							<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#newAgent_name_id#">,
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#project_agent_role#">,
							1 )
					</cfquery>
				<cfquery name="newTrans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						INSERT INTO project_trans 
							(project_id, transaction_id) 
						values (
							sq_project_id.currval,
							<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
						)
					</cfquery>
			</cfif>
			<cfloop from="1" to="#numAgents#" index="n">
				<cfif IsDefined("trans_agent_id_" & n) >
					<cfset trans_agent_id_ = evaluate("trans_agent_id_" & n)>
					<cfset agent_id_ = evaluate("agent_id_" & n)>
					<cfset trans_agent_role_ = evaluate("trans_agent_role_" & n)>
					<cftry>
						<cfset del_agnt_=evaluate("del_agnt_" & n)>
						<cfcatch>
							<cfset del_agnt_=0>
						</cfcatch>
					</cftry>
					<cfif  del_agnt_ is "1" and isnumeric(trans_agent_id_) and trans_agent_id_ gt 0>
						<cfquery name="del" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							delete from trans_agent 
							where trans_agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#trans_agent_id_#">
						</cfquery>
						<cfelse>
						<cfif len(agent_id_) GT 0>
							<!--- don't try to add/update a blank row --->
							<cfif trans_agent_id_ is "new" and del_agnt_ is 0>
								<cfquery name="newTransAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
								insert into trans_agent (
									transaction_id,
									agent_id,
									trans_agent_role
								) values (
									<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">,
									<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id_#">,
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trans_agent_role_#">
								)
							</cfquery>
								<cfelseif del_agnt_ is 0>
								<cfquery name="upTransAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
								update trans_agent set
									agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id_#">,
									trans_agent_role = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trans_agent_role_#">
								where
									trans_agent_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#trans_agent_id_#">
							</cfquery>
							</cfif>
						</cfif>
					</cfif>
				</cfif>
			</cfloop>
		</cftransaction>
		<cflocation url="/transactions/Loan.cfm?Action=editLoan&transaction_id=#transaction_id#">
	</cfoutput>
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
			Something bad happened. <br>
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
<cfinclude template="/shared/_footer.cfm">
