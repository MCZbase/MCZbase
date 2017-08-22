<cfset jquery11=true>
<cfinclude template="includes/_header.cfm">
<cfset MAGIC_MCZ_COLLECTION = 12>
<cfset MAGIC_MCZ_CRYO = 11>
<script type='text/javascript' src='/includes/internalAjax.js'></script>
<script type='text/javascript' src='/includes/transAjax.js'></script>
<cfif not isdefined("project_id")><cfset project_id = -1></cfif>

<!---  Skin UI as Loan or Gift, either based on request, or for editing existing data the loan_type.  --->
<cfif not isdefined("scope")>
    <!--- Default scope is Loan --->
    <cfset scope = 'Loan'>
<cfelse>
   <!--- Only allowed scopes are Loan and Gift.  --->
    <cfif scope neq 'Gift'><cfset scope = 'Loan'></cfif>
</cfif>
<cfif action is "editLoan">
     <!--- for existing records, look up the scope from the record.  --->
	<cfquery name="loanScope" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
             select scope from loan left join ctloan_type on loan.loan_type = ctloan_type.loan_type where loan.transaction_id = <cfqueryparam value=#transaction_id# CFSQLType="CF_SQL_DECIMAL" >
        </cfquery>
        <cfset scope = loanScope.scope >
</cfif>

<!--- Loan types relevant to the current scope --->
<cfquery name="ctLoanType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select loan_type from ctloan_type where scope = <cfqueryparam value=#scope# CFSQLType="CF_SQL_VARCHAR" > order by ordinal asc, loan_type
</cfquery>
<!--- All loan types for loan and gift query --->
<cfquery name="ctAllLoanType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
	select distinct(trans_agent_role) from cttrans_agent_role  where trans_agent_role != 'entered by' and trans_agent_role != 'associated with agency' and trans_agent_role != 'received from' order by trans_agent_role
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
           }
	}
	function dCount() {
		var countThingees=new Array();
		countThingees.push('nature_of_material');
		countThingees.push('loan_description');
		countThingees.push('loan_instructions');
		countThingees.push('trans_remarks');
		for (i=0;i<countThingees.length;i++) {
			var els = countThingees[i];
			var el=document.getElementById(els);
			var elVal=el.value;
			var ds='lbl_'+els;
			var d=document.getElementById(ds);
			var lblVal=d.innerHTML;
			d.innerHTML=elVal.length + " characters";
		}
		var t=setTimeout("dCount()",500);
	}
</script>
</cfoutput>
<!-------------------------------------------------------------------------------------------------->
<cfif action is "nothing">
	<cflocation url="Loan.cfm?action=search" addtoken="false">
</cfif>
<!-------------------------------------------------------------------------------------------------->
<cfif  action is "newLoan">
<cfset title="New #scope#">
	<cfoutput>
  <form name="newloan" id="newLoan" action="Loan.cfm" method="post" onSubmit="return noenter();">
    <div class="newLoanWidth">
    	<h2 class="wikilink" style="margin-left: 0;">Initiate a #scope#
	   <img src="/images/info_i_2.gif" onClick="getMCZDocs('Loan/Gift_Transactions##Create_a_New_Loan_or_Gift')" class="likeLink" alt="[ help ]">
   </h2>
           <input type="hidden" name="action" value="makeLoan">
			<table border id="newLoanTable">
				<tr>
					<td>
						<label for="collection_id">Collection
						</label>
						<select name="collection_id" size="1" id="collection_id">
							<cfloop query="ctcollection">
								<option value="#ctcollection.collection_id#">#ctcollection.collection#</option>
							</cfloop>
						</select>
					</td>
					<td>
						<label for="loan_number">#scope# Number</label>
						<input type="text" name="loan_number" class="reqdClr" id="loan_number">
					</td>
				</tr>
				<tr>
					<td>
						<label for="auth_agent_name">Authorized By</label>
						<input type="text" name="auth_agent_name" class="reqdClr" size="40"
						  onchange="getAgent('auth_agent_id','auth_agent_name','newloan',this.value); return false;"
						  onKeyPress="return noenter(event);">
						<input type="hidden" name="auth_agent_id" id="auth_agent_id" 
                            				onChange=" updateAgentLink($('##auth_agent_id').val(),'auth_agent_view');">
  				                <div id="auth_agent_view">&nbsp;&nbsp;&nbsp;&nbsp;</div>
					</td>
					<td>
						<label for="rec_agent_name">Received By:</label>
						<input type="text" name="rec_agent_name" class="reqdClr" size="40"
						  onchange="getAgent('rec_agent_id','rec_agent_name','newloan',this.value); return false;"
						  onKeyPress="return noenter(event);">
						<input type="hidden" name="rec_agent_id" id="rec_agent_id" 
							onChange=" updateAgentLink($('##rec_agent_id').val(),'rec_agent_view');">
						<div id="rec_agent_view">&nbsp;&nbsp;&nbsp;&nbsp;</div>
					</td>
				</tr>
				<tr>
					<td>
						<label for="in_house_contact_agent_name">In-House Contact:</label>
						<input type="text" name="in_house_contact_agent_name" class="reqdClr" size="40"
						  onchange="getAgent('in_house_contact_agent_id','in_house_contact_agent_name','newloan',this.value); return false;"
						  onKeyPress="return noenter(event);">
						<input type="hidden" name="in_house_contact_agent_id" id="in_house_contact_agent_id"
							onChange=" updateAgentLink($('##in_house_contact_agent_id').val(),'in_house_contact_agent_view');">
						<div id="in_house_contact_agent_view">&nbsp;&nbsp;&nbsp;&nbsp;</div>
					</td>
					<td>
						<label for="additional_contact_agent_name">Additional Outside Contact:</label>
						<input type="text" name="additional_contact_agent_name" size="40"
						  onchange="getAgent('additional_contact_agent_id','additional_contact_agent_name','newloan',this.value); return false;"
						  onKeyPress="return noenter(event);">
						<input type="hidden" name="additional_contact_agent_id" id="additional_contact_agent_id" 
							onChange=" updateAgentLink($('##additional_contact_agent_id').val(),'additional_contact_agent_view');">
						<div id="additional_contact_agent_view">&nbsp;&nbsp;&nbsp;&nbsp;</div>
					</td>
				</tr>
				<tr>
					<td>
						<label for="recipient_institution_agent_name">Recipient Institution:</label>
						<input type="text" name="recipient_institution_agent_name" class="reqdClr" size="40"
						  onchange="getAgent('recipient_institution_agent_id','recipient_institution_agent_name','newloan',this.value); return false;"
						  onKeyPress="return noenter(event);">
						<input type="hidden" name="recipient_institution_agent_id"  id="recipient_institution_agent_id" 
							onChange=" updateAgentLink($('##recipient_institution_agent_id').val(),'recipient_institution_agent_view');">
						<div id="recipient_institution_agent_view">&nbsp;&nbsp;&nbsp;&nbsp;</div>
					</td>
					<td>
						<label for="foruseby_agent_name">For Use By:</label>
						<input type="text" name="foruseby_agent_name" size="40"
						  onchange="getAgent('foruseby_agent_id','foruseby_agent_name','newloan',this.value); return false;"
						  onKeyPress="return noenter(event);">
						<input type="hidden" name="foruseby_agent_id" id="foruseby_agent_id" 
							onChange=" updateAgentLink($('##foruseby_agent_id').val(),'foruseby_agent_view');">
						<div id="foruseby_agent_view">&nbsp;&nbsp;&nbsp;&nbsp;</div>
					</td>
				</tr>
				<tr>
				<tr>
					<td>
						<label for="loan_type">#scope# Type</label>
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
                                                           <cfif scope eq 'Gift'>
							  // only MCZ collections (the non-specimen collection) is allowed to make transfers.
							  $("##loan_type").append($("<option></option>").attr("value",'transfer').text('transfer'));
                                                           <cfelse>
							  // only MCZ collections (the non-specimen collection) is allowed to be exhibition-masters.
							  $("##loan_type").append($("<option></option>").attr("value",'exhibition-master').text('exhibition-master'));
                                                           </cfif>
							 } else {
							  $("##loan_type option[value='transfer']").each(function() { $(this).remove(); } );
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
						<select name="loan_type" id="loan_type" class="reqdClr">
							<cfloop query="ctLoanType">
								<option value="#ctLoanType.loan_type#">#ctLoanType.loan_type#</option>
							</cfloop>
						</select>

					</td>
					<td>
						<label for="loan_status">#scope# Status</label>
						<select name="loan_status" id="loan_status" class="reqdClr">
							<cfloop query="ctLoanStatus">
                                  <cfif isAllowedLoanStateChange('in process',ctLoanStatus.loan_status) >
								<option value="#ctLoanStatus.loan_status#"
								<cfif #ctLoanStatus.loan_status# is "open">selected='selected'</cfif>>
                                #ctLoanStatus.loan_status#</option>
                                 </cfif>
							</cfloop>
						</select>
					</td>
				</tr>
				<tr>
					<td>
						<label for="initiating_date">Transaction Date</label>
						<input type="text" name="initiating_date" id="initiating_date" value="#dateformat(now(),"yyyy-mm-dd")#">
					</td>
					<td>
                                             <cfif scope eq 'Loan'>
						<label for="return_due_date">Return Due Date</label>
						<input type="text" name="return_due_date" id="return_due_date" value="#dateformat(dateadd("m",6,now()),"yyyy-mm-dd")#" >
                                             <cfelse>
						<input type="hidden" name="return_due_date" id="return_due_date" value="">
                                             </cfif>
					</td>
				</tr>
				<tr>
					<td colspan="2">
						<label for="nature_of_material">Nature of Material</label>
						<textarea name="nature_of_material" id="nature_of_material" rows="3" cols="80" class="reqdClr"></textarea>
					</td>
				</tr>
				<tr>
					<td colspan="2">
						<label for="loan_description">Description</label>
						<textarea name="loan_description" id="loan_description" rows="3" cols="80"></textarea>
					</td>
				</tr>
				<tr>
					<td colspan="2">
						<label for="loan_instructions">#scope# Instructions</label>
						<textarea name="loan_instructions" id="loan_instructions" rows="3" cols="80"></textarea>
					</td>
				</tr>
				<tr>
					<td colspan="2">
						<label for="trans_remarks">Internal Remarks</label>
						<textarea name="trans_remarks" id="trans_remarks" rows="3" cols="80"></textarea>
					</td>
				</tr>
				<tr id="insurance_section">
					<td>
 		   				<label for="insurance_value">Insurance value</label>
						<input type="text" name="insurance_value" id="insurance_value" value="">
					</td>
					<td>
		   				<label for="insurance_maintained_by">Insurance Maintained By</label>
		   				<input type="text" name="insurance_maintained_by" id="insurance_maintained_by" value="">
					</td>
				</tr>
				<tr>
					<td colspan="2" align="center">
						<input type="submit" value="Create #scope#" class="insBtn">
						&nbsp;
						<input type="button" value="Quit" class="qutBtn" onClick="document.location = 'Loan.cfm'">
			   		</td>
				</tr>
			</table>
		</form>
                <script>
                          $("##newLoan").submit( function(event) {
                              if ($("##loan_type").val()=="gift" || $("##loan_type").val()=="transfer") {
                                 $("##return_due_date").val(null);
                              }
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
                                 $(errdiv).dialog({ title:"Error Creating Loan"}).dialog("open");
                                 event.preventDefault();
                              };
                           });
                </script>
		<div class="nextnum" id="nextNumDiv">
			<p>Next Available #scope# Number:</p>
			<cfquery name="all_coll" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select * from collection order by collection
			</cfquery>
			<cfloop query="all_coll">
				<cfif (institution_acronym is 'MCZ')>
					<!---- yyyy-n-CCDE format --->
					<cfset stg="'#dateformat(now(),"yyyy")#-' || max(to_number(substr(loan_number,instr(loan_number,'-')+1,instr(loan_number,'-',1,2)-instr(loan_number,'-')-1) + 1)) || '-#collection_cde#'">
					<cfset whr=" AND substr(loan_number, 1,4) ='#dateformat(now(),"yyyy")#'">
				<cfelse>
					<!--- n format --->
					<cfset stg="'#dateformat(now(),"yyyy")#.' || max(to_number(substr(loan_number,instr(loan_number,'.')+1,instr(loan_number,'.',1,2)-instr(loan_number,'.')-1) + 1)) || '.#collection_cde#'">
					<cfset whr=" AND is_number(loan_number)=1 and substr(loan_number, 1,4) ='#dateformat(now(),"yyyy")#'">
				</cfif>
				<cftry>
					<cfquery name="thisq" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select
							 #preservesinglequotes(stg)# nn
						from
							loan,
							trans,
							collection
						where
							loan.transaction_id=trans.transaction_id and
							trans.collection_id=collection.collection_id
							<cfif institution_acronym is not "MVZ" and institution_acronym is not "MVZObs">
								and	collection.collection_id=#collection_id#
							</cfif>
							#preservesinglequotes(whr)#
					</cfquery>
					<cfcatch>
						<hr>
						#cfcatch.detail#
						<br>
						#cfcatch.message#
						<cfquery name="thisq" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							select
								 'check data' nn
							from
								dual
						</cfquery>
					</cfcatch>
				</cftry>
				<cfif len(thisQ.nn) gt 0>
					<span class="likeLink" onclick="setLoanNum('#collection_id#','#thisQ.nn#')">#collection# #thisQ.nn#</span>
				<cfelse>
					<span style="font-size:x-small">
						No data available for #collection#.
					</span>
				</cfif>
				<br>
			</cfloop>
		</div>  
                <script>
                        $(document).ready( function() { $('##nextNumDiv').position( { my: "left top", at: "right top", of: $('##newLoanTable'), colision: "none" } ); } );
                </script>
        </div>
	</cfoutput>
</cfif>
<!-------------------------------------------------------------------------------------------------->
<cfif action is "editLoan">
	<cfset title="Edit #scope#">
	<cfoutput>
	<cfquery name="loanDetails" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select
			trans.transaction_id,
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
					<cfif scope eq 'Gift'>
					// only MCZ collections (the non-specimen collection) is allowed to make transfers.
					$("##loan_type").append($("<option></option>").attr("value",'transfer').text('transfer'));
					<cfelse>
					// only MCZ collections (the non-specimen collection) is allowed to be exhibition-masters.
					$("##loan_type").append($("<option></option>").attr("value",'exhibition-master').text('exhibition-master'));
					</cfif>
				} else {
					$("##loan_type option[value='transfer']").each(function() { $(this).remove(); } );
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
       <div class="editLoanbox">
       <h2 class="wikilink" style="margin-left: 0;">Edit #scope# <img src="/images/info_i_2.gif" onClick="getMCZDocs('Loan/Gift_Transactions##Edit_a_Loan_or_Gift')" class="likeLink" alt="[ help ]">
        <span class="loanNum">#loanDetails.collection# #loanDetails.loan_number# </span>	</h2>
	<table class="editLoanTable">
    <tr>
    <td valign="top" class="leftCell"><!--- left cell ---->

  <form name="editloan" action="Loan.cfm" method="post">
		<input type="hidden" name="action" value="saveEdits">
		<input type="hidden" name="transaction_id" value="#loanDetails.transaction_id#">

		<span style="font-size:14px;">Entered by #loanDetails.enteredby#</span>

    <table class="IDloan">
    <tr>
    <td>
      <label>Department</label>
		<select name="collection_id" id="collection_id" size="1">
			<cfloop query="ctcollection">
				<option <cfif ctcollection.collection_id is loanDetails.collection_id> selected </cfif>
					value="#ctcollection.collection_id#">#ctcollection.collection#</option>
			</cfloop>
		</select>
       </td>
       <td>
          <label for="loan_number">#scope# Number</label>
		<input type="text" name="loan_number" id="loan_number" value="#loanDetails.loan_number#" class="reqdClr">
        </td>
        </tr>
        </table>
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
		<table id="loanAgents">
			<tr style="height: 20px;">
				<th>Agent&nbsp;Name&nbsp;<span class="linkButton" onclick="addTransAgent()">Add Row</span></th>
				<th></th>
				<th>Role</th>
				<th>Delete?</th>
				<th>Clone&nbps;As</th>
				<td rowspan="99">
                     <cfif loanDetails.loan_type eq 'exhibition-master' or loanDetails.loan_type eq 'exhibition-subloan'>
                                        <!--- TODO: Rollout of mandatory recipient institution will put more types in this block.  --->
					<cfif inhouse.c is 1 and outside.c is 1 and authorized.c GT 0 and recipientinstitution.c GT 0 >
						<span style="color:green;font-size:small">OK to print</span>
					<cfelse>
						<span style="color:red;font-size:small">
							One "authorized by", one "in-house contact", one "received by", and one "recipient institution" are required to print loan forms.
						</span>
					</cfif>
                                     <cfelse>
					<cfif inhouse.c is 1 and outside.c is 1 and authorized.c GT 0 >
						<span style="color:green;font-size:small">OK to print</span>
					<cfelse>
						<span style="color:red;font-size:small">
							One "authorized by", one "in-house contact" and one "received by" are required to print loan forms.  Recipient institution will soon become mandatory as well.
						</span>
					</cfif>
                                     </cfif>
				</td>
			</tr>
			<cfset i=1>
			<cfloop query="loanAgents">
				<tr>
					<td>
						<input type="hidden" name="trans_agent_id_#i#" id="trans_agent_id_#i#" value="#trans_agent_id#">
						<input type="text" name="trans_agent_#i#" id="trans_agent_#i#" class="reqdClr" size="30" value="#agent_name#"
		  					onchange="getAgent('agent_id_#i#','trans_agent_#i#','editloan',this.value); return false;"
		  					onKeyPress="return noenter(event);">
		  				<input type="hidden" name="agent_id_#i#" id="agent_id_#i#" value="#agent_id#" 
                                                    onchange=" updateAgentLink($('##agent_id_#i#').val(),'agentViewLink_#i#'); ">
					</td>
					<td style=" min-width: 3.5em; ">
					    <span id="agentViewLink_#i#"><a href="/agents.cfm?agent_id=#agent_id#" target="_blank">View</a><cfif loanAgents.worstagentrank EQ 'A'> &nbsp;<cfelseif loanAgents.worstagentrank EQ 'F'><img src='/images/flag-red.svg.png' width='16'><cfelse><img src='/images/flag-yellow.svg.png' width='16'></cfif>
                                            </span>
					</td>
					<td>
						<select name="trans_agent_role_#i#" id="trans_agent_role_#i#">
							<cfloop query="cttrans_agent_role">
								<option
									<cfif cttrans_agent_role.trans_agent_role is loanAgents.trans_agent_role>
										selected="selected"
									</cfif>
									value="#trans_agent_role#">#trans_agent_role#</option>
							</cfloop>
						</select>
					</td>
					<td>
						<input type="checkbox" name="del_agnt_#i#" id="del_agnt_#i#" value="1">
					</td>
					<td>
						<select id="cloneTransAgent_#i#" onchange="cloneTransAgent(#i#)" style="width:8em">
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
		</table><!-- end agents table --->
		<table width="100%">
			<tr>
				<td width="44%">
					<label for="loan_type">#scope# Type</label>
					<select name="loan_type" id="loan_type" class="reqdClr">
						<cfloop query="ctLoanType">
                                                      <cfif ctLoanType.loan_type NEQ "transfer" OR loanDetails.collection_id EQ MAGIC_MCZ_COLLECTION >
							  <option <cfif ctLoanType.loan_type is loanDetails.loan_type> selected="selected" </cfif>
							  	  value="#ctLoanType.loan_type#">#ctLoanType.loan_type#</option>
                                                      <cfelseif loanDetails.loan_type EQ "transfer" AND loanDetails.collection_id NEQ MAGIC_MCZ_COLLECTION >
							  <option <cfif ctLoanType.loan_type is loanDetails.loan_type> selected="selected" </cfif>
								  value=""></option>
                                                      </cfif>
						</cfloop>
					</select>
				</td>
				<td>
					<label for="loan_status">#scope# Status</label>
					<select name="loan_status" id="loan_status" class="reqdClr">
                                                <!---  Normal transaction users are only allowed certain loan status state transitions, users with elevated privileges for loans are allowed to edit loans to place them into any state.  --->
						<cfloop query="ctLoanStatus">
                                                     <cfif isAllowedLoanStateChange(loanDetails.loan_status,ctLoanStatus.loan_status)  or (isdefined("session.roles") and listfindnocase(session.roles,"ADMIN_TRANSACTIONS"))  >
							<option <cfif ctLoanStatus.loan_status is loanDetails.loan_status> selected="selected" </cfif>
								value="#ctLoanStatus.loan_status#">#ctLoanStatus.loan_status#</option>
                                                     </cfif>
						</cfloop>
					</select>
					<cfif loanDetails.loan_status EQ 'closed' and len(loanDetails.closed_date) GT 0>
						Date Closed: #loanDetails.closed_date#
					</cfif>
				</td>
			</tr>
			<tr>
				<td>
					<label for="initiating_date">Transaction Date</label>
					<input type="text" name="initiating_date" id="initiating_date"
						value="#dateformat(loanDetails.trans_date,"yyyy-mm-dd")#" class="reqdClr">
				</td>
				<td>
                                      <cfif scope eq 'Loan'>
					<label for="return_due_date">Due Date</label>
					<input type="text" id="return_due_date" name="return_due_date"
						value="#dateformat(loanDetails.return_due_date,'yyyy-mm-dd')#">
                                      <cfelse>
					<input type="hidden" id="return_due_date" name="return_due_date" value="#loanDetails.return_due_date#" >
                                      </cfif>
				</td>
			</tr>
            <tr id="insurance_section">
				<td>
			   		<label for="insurance_value">Insurance value</label>
					<input type="text" name="insurance_value" id="insurance_value" value="#loanDetails.insurance_value#" size="40">
				</td>
				<td>
		   			<label for="insurance_maintained_by">Insurance Maintained By</label>
		   			<input type="text" name="insurance_maintained_by" id="insurance_maintained_by" value="#loanDetails.insurance_maintained_by#" size="40">
				</td>
			</tr>
		</table>
                <div id="parentloan_section">
                     Exhibition-Master Loan:
                     <cfif parentLoan.RecordCount GT 0>
			<cfloop query="parentLoan">
                  <a href="Loan.cfm?action=editLoan&transaction_id=#parentLoan.transaction_id#">#parentLoan.loan_number#</a>
            </cfloop>
  		     <cfelse>
                        This exhibition subloan has not been linked to a master loan.
                     </cfif>
                </div>
                <div id="subloan_section">
                     <span id="subloan_list">
                     Exhibition-Subloans (#childLoans.RecordCount#):
                     <cfif childLoans.RecordCount GT 0>
                        <cfset childLoanCounter = 0>
                        <cfset childseparator = "">
			<cfloop query="childLoans">
                           #childseparator#
                       <a href="Loan.cfm?action=editLoan&transaction_id=#childLoans.transaction_id#">#childLoans.loan_number#</a>
                           <button class="ui-button ui-widget ui-corner-all" id="button_remove_subloan_#childLoanCounter#"> - </button>
                           <script>
			   $(function() {
				$("##button_remove_subloan_#childLoanCounter#").click( function(event) {
                     			event.preventDefault();
					$.get( "component/functions.cfc",
 						{ transaction_id : "#loanDetails.transaction_id#",
						  subloan_transaction_id : "#childLoans.transaction_id#" ,
						  method : "removeSubLoan",
						  returnformat : "json",
						  queryformat : 'column'
						},
						function(r) {
                                                    var retval = "Exhibition-Subloans (" + r.ROWCOUNT + "): ";
                                                    var separator = "";
                                                    for (var i=0; i<r.ROWCOUNT; i++) {
      							retval = retval + separator + "<a href=Loan.cfm?action=editLoan&transaction_id=" + r.DATA.TRANSACTION_ID[i] + ">" + r.DATA.LOAN_NUMBER[i] + "</a>[-]";
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
                     </span>
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
      							retval = retval + separator + "<a href=Loan.cfm?action=editLoan&transaction_id=" + r.DATA.TRANSACTION_ID[i] + ">" + r.DATA.LOAN_NUMBER[i] + "</a>[-]";
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
                     <select name="possible_subloans" id="possible_subloans">
			<cfloop query="potentialChildLoans">
				<option value="#transaction_id#">#loan_number#</option>
			</cfloop>
                     </select>
                     <button class="ui-button ui-widget ui-corner-all" id="button_add_subloans"> Add </button>
                </div>
		<label for="">Nature of Material (<span id="lbl_nature_of_material"></span>)</label>
		<textarea name="nature_of_material" id="nature_of_material" rows="7" cols="60"
			class="reqdClr">#loanDetails.nature_of_material#</textarea>
		<label for="loan_description">Description (<span id="lbl_loan_description"></span>)</label>
		<textarea name="loan_description" id="loan_description" rows="7"
			cols="60">#loanDetails.loan_description#</textarea>
		<label for="loan_instructions">#scope# Instructions (<span id="lbl_loan_instructions"></span>)</label>
		<textarea name="loan_instructions" id="loan_instructions" rows="7"
			cols="60">#loanDetails.loan_instructions#</textarea>
		<label for="trans_remarks">Internal Remarks (<span id="lbl_trans_remarks"></span>)</label>
		<textarea name="trans_remarks" id="trans_remarks" rows="7" cols="60">#loanDetails.trans_remarks#</textarea>
		<br>
		<input type="button" value="Save Edits" class="savBtn"
			onClick="editloan.action.value='saveEdits';submit();">

   		<input type="button" style="margin-left: 30px;" value="Quit" class="qutBtn" onClick="document.location = 'Loan.cfm?Action=search'">
		<input type="button" value="Add Items" class="lnkBtn"
			onClick="window.open('SpecimenSearch.cfm?Action=dispCollObj&transaction_id=#transaction_id#');">
		<input type="button" value="Add Items BY Barcode" class="lnkBtn"
			onClick="window.open('loanByBarcode.cfm?transaction_id=#transaction_id#');">

		<input type="button" value="Review Items" class="lnkBtn"
			onClick="window.open('a_loanItemReview.cfm?transaction_id=#transaction_id#');">
                            <input type="button" value="Delete #scope#" class="delBtn"
			onClick="editloan.action.value='deleLoan';confirmDelete('editloan');">
   		<br />
                <div id="loanItemCountDiv"></div>
		<script>
			$(document).ready( updateLoanItemCount('#transaction_id#','loanItemCountDiv') );
 		</script>
   		<label for="redir">Print...</label>
		<select name="redir" id="redir" size="1" onchange="if(this.value.length>0){window.open(this.value,'_blank')};">
   			<option value=""></option>
			<cfif #cgi.HTTP_HOST# contains "arctos.database">
				<option value="/Reports/report_printer.cfm?transaction_id=#transaction_id#&report=uam_mamm_loan_head">UAM Mammal Invoice Header</option>
				<option value="/Reports/UAMMammLoanInvoice.cfm?transaction_id=#transaction_id#&Action=itemList">UAM Mammal Item Invoice</option>
				<option value="/Reports/UAMMammLoanInvoice.cfm?transaction_id=#transaction_id#&Action=showCondition">UAM Mammal Item Conditions</option>
				<option value="/Reports/report_printer.cfm?transaction_id=#transaction_id#&report=UAM_ES_Loan_Header_II">UAM ES Invoice Header</option>
				<option value="/Reports/MSBMammLoanInvoice.cfm?transaction_id=#transaction_id#">MSB Mammal Invoice Header</option>
				<option value="/Reports/MSBMammLoanInvoice.cfm?transaction_id=#transaction_id#&Action=itemList">MSB Mammal Item Invoice</option>
				<option value="/Reports/MSBBirdLoanInvoice.cfm?transaction_id=#transaction_id#">MSB Bird Invoice Header</option>
				<option value="/Reports/MSBBirdLoanInvoice.cfm?transaction_id=#transaction_id#&Action=itemList">MSB Bird Item Invoice</option>
				<option value="/Reports/UAMLoanInvoice.cfm?transaction_id=#transaction_id#">UAM Generic Invoice Header</option>
				<option value="/Reports/UAMLoanInvoice.cfm?transaction_id=#transaction_id#&Action=itemList">UAM Generic Item Invoice</option>
				<option value="/Reports/UAMLoanInvoice.cfm?transaction_id=#transaction_id#&Action=showCondition">UAM Generic Item Conditions</option>
				<option value="/Reports/report_printer.cfm?transaction_id=#transaction_id#&report=loan_instructions">Instructions Appendix</option>
				<option value="/Reports/report_printer.cfm?transaction_id=#transaction_id#&report=shipping_label">Shipping Label</option>
				<option value="/Reports/report_printer.cfm?transaction_id=#transaction_id#">Any Report</option>
			<cfelseif #cgi.HTTP_HOST# contains "harvard.edu">
                          <!--- report_printer.cfm takes parameters transaction_id, report, and sort, where
                                 sort={a field name that is in the select portion of the query specified in the custom tag}, or
                                 sort={cat_num_pre_int}, which is interpreted as order by cat_num_prefix, cat_num_integer.
                          --->
		          <cfif inhouse.c is 1 and outside.c is 1 and authorized.c GT 0 and scope EQ 'Loan' >
                             <option value="/Reports/report_printer.cfm?transaction_id=#transaction_id#&report=mcz_loan_header">MCZ Invoice Header</option>
                          </cfif>
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
		            <cfif scope eq 'Gift' >
                            <option value="/Reports/report_printer.cfm?transaction_id=#transaction_id#&report=mcz_loan_gift">MCZ Gift Invoice Header</option>
                            <option value="/Reports/report_printer.cfm?transaction_id=#transaction_id#&report=mcz_loan_object_header_short">MCZ Object Header (short)</option>
                            </cfif>
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
            <cfelse>
   			        <option value="">Host not recognized.</option>
            </cfif>
		</select>
	</td><!---- end left cell --->
	<td valign="top" class="rightCell"><!---- right cell ---->
   <div id="project">

			<h3>Projects associated with this loan: <img src="/images/info_i_2.gif" onClick="getMCZDocs('Loan/Gift_Transactions##Projects_and_Permits')" class="likeLink" alt="[ help ]"></h3>
		<cfquery name="projs" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select project_name, project.project_id from project,
			project_trans where
			project_trans.project_id =  project.project_id
			and transaction_id=#transaction_id#
		</cfquery>
		<ul>
			<cfif projs.recordcount gt 0>
				<cfloop query="projs">
					<li><a href="/Project.cfm?Action=editProject&project_id=#project_id#"><strong>#project_name#</strong></a></li>
				</cfloop>
			<cfelse>
				<li>None</li>
			</cfif>
		</ul>
		<hr>
		<label for="project_id">Pick a Project to associate with this #scope#</label>
		<input type="hidden" name="project_id">
		<input type="text"
			size="50"
			name="pick_project_name"
			class="reqdClr"
			onchange="getProject('project_id','pick_project_name','editloan',this.value); return false;"
			onKeyPress="return noenter(event);">
		<hr>
		<label for=""><span style="font-size:large">Create a project from this #scope#</span></label>
                <div id="create_project">
		<label for="newAgent_name">Project Agent Name</label>
		<input type="text" name="newAgent_name" id="newAgent_name"
			class="reqdClr"
			onchange="findAgentName('newAgent_name_id','newAgent_name',this.value); return false;"
			onKeyPress="return noenter(event);"
			value="">
		<input type="hidden" name="newAgent_name_id" id="newAgent_name_id" value="">
		<cfquery name="ctProjAgRole" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select project_agent_role from ctproject_agent_role order by project_agent_role
		</cfquery>
		<label for="">Project Agent Role</label>
		<select name="project_agent_role" size="1" class="reqdClr">
			<cfloop query="ctProjAgRole">
				<option value="#ctProjAgRole.project_agent_role#">#ctProjAgRole.project_agent_role#</option>
			</cfloop>
		</select>
		<label for="project_name" >Project Title</label>
		<textarea name="project_name" cols="50" rows="2" class="reqdClr"></textarea>
		<label for="start_date" >Project Start Date</label>
		<input type="text" name="start_date" value="#dateformat(loanDetails.trans_date,"yyyy-mm-dd")#">
		<label for="">Project End Date</label>
		<input type="text" name="end_date">
		<label for="project_description" >Project Description</label>
		<textarea name="project_description"
			id="project_description" cols="50" rows="6">#loanDetails.loan_description#</textarea>
		<label for="project_remarks">Project Remark</label>
		<textarea name="project_remarks" cols="50" rows="3">#loanDetails.trans_remarks#</textarea>
                </div>
		<label for="saveNewProject">Check to create project with save</label>
		<input type="checkbox" value="yes" name="saveNewProject" id="saveNewProject">
	</form>
	</td>
    </tr>
    </table>
      </div>

<div class="shippingBlock">
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
    height: 800,
    width: 950,
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
    <div id="shipmentTable">Loading shipments...</div> <!--- shippmentTable for ajax replace --->

<script>

$( document ).ready(loadShipments(#transaction_id#));

    $(function() {
      $("##dialog-shipment").dialog({
        autoOpen: false,
        modal: true,
        width: 650,
        buttons: {
          "Save": function() {  saveShipment(#transaction_id#); } ,
          Cancel: function() {
            $(this).dialog( "close" );
          }
        },
        close: function() {
            $(this).dialog( "close" );
        }
      });
    });
</script>
    <div class="addstyle">
    <input type="button" class="lnkBtn" value="Add Shipment" onClick="$('##dialog-shipment').dialog('open'); setupNewShipment(#transaction_id#);"><div class="shipmentnote">Note: please check the <a href="https://code.mcz.harvard.edu/wiki/index.php/Country_Alerts">Country Alerts</a> page for special instructions or restrictions associated with specific countries</div></div><!---moved this to inside of the shipping block--one div up--->
</div> <!--- end shipping block ---> 




<div id="dialog-shipment" title="Create new Shipment">
  <form name="shipmentForm" id="shipmentForm" >
    <fieldset>
	<input type="hidden" name="transaction_id" value="#transaction_id#" id="shipmentForm_transaction_id" >
	<input type="hidden" name="shipment_id" value="" id="shipment_id">
	<input type="hidden" name="returnFormat" value="json" id="returnFormat">
           <table>
             <tr>
              <td>
		<label for="shipped_carrier_method">Shipping Method</label>
		<select name="shipped_carrier_method" id="shipped_carrier_method" size="1" class="reqdClr">
			<option value=""></option>
			<cfloop query="ctShip">
				<option value="#ctShip.shipped_carrier_method#">#ctShip.shipped_carrier_method#</option>
			</cfloop>
		</select>
              </td>
              <td colspan="2">
		<label for="carriers_tracking_number">Tracking Number</label>
		<input type="text" value="" name="carriers_tracking_number" id="carriers_tracking_number" size="30" >
              </td>
            </tr><tr>
              <td>
		<label for="no_of_packages">Number of Packages</label>
		<input type="text" value="1" name="no_of_packages" id="no_of_packages">
              </td>
              <td>
		<label for="shipped_date">Ship Date</label>
		<input type="text" value="#dateformat(Now(),'yyyy-mm-dd')#" name="shipped_date" id="shipped_date">
              </td>
              <td>
		<label for="foreign_shipment_fg">Foreign shipment?</label>
		<select name="foreign_shipment_fg" id="foreign_shipment_fg" size="1">
			<option selected value="0">no</option>
			<option value="1">yes</option>
		</select>
              </td>
            </tr><tr>
              <td>
		<label for="package_weight">Package Weight (TEXT, include units)</label>
		<input type="text" value="" name="package_weight" id="package_weight">
              </td>
              <td>
		<label for="insured_for_insured_value">Insured Value (NUMBER, US$)</label>
		<input type="text" validate="float" label="Numeric value required."
			 value="" name="insured_for_insured_value" id="insured_for_insured_value">
              </td>
              <td>
		<label for="hazmat_fg">HAZMAT?</label>
		<select name="hazmat_fg" id="hazmat_fg" size="1">
			<option selected value="0">no</option>
			<option value="1">yes</option>
		</select>
              </td>
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
		<input type="hidden" name="shipped_to_addr_id" id="shipped_to_addr_id" value="">

		<label for="shipped_from_addr">Shipped From Address</label>
		<input type="button" value="Pick Address" class="picBtn"
			onClick="addrPick('shipped_from_addr_id','shipped_from_addr','shipmentForm'); return false;">
		<textarea name="shipped_from_addr" id="shipped_from_addr" cols="60" rows="5"
			readonly="yes" class="reqdClr"></textarea>
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
<div id="accsection">
	<h3>Accessions (and their permits) for material in this loan:</h3>
        <!--- List Accessions for collection objects included in the Loan --->
	<cfquery name="getAccessions" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select distinct accn.accn_type, accn.received_date, accn.accn_number, accn.transaction_id from 
		   loan l 
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
		select distinct permit_num, permit_type, issued_date, permit.permit_id,
                    issuedBy.agent_name as IssuedByAgent
		from permit_trans left join permit on permit_trans.permit_id = permit.permit_id
                     left join preferred_agent_name issuedBy on permit.issued_by_agent_id = issuedBy.agent_id
		where permit_trans.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value=#transaction_id#>
                order by permit_type, issued_date
            </cfquery>
             <cfif getAccnPermits.recordcount gt 0>
	      <ul class="accnpermit">
              <cfloop query="getAccnPermits">
                 <li><span style="font-weight:bold;">Permit:</span> #permit_type# #permit_num#, <span>Issued:</span> #dateformat(issued_date,'yyyy-mm-dd')# <span>by</span> #IssuedByAgent# <a href="Permit.cfm?Action=editPermit&permit_id=#permit_id#" target="_blank">Edit</a></li>
                 
              </cfloop>
              </ul>
             
	    </cfif>
        </li>
	</cfloop>
        </ul>
</div>
    <!--- TODO: Print permits associated with these accessions --->
	  <div id="permitmedia">
      <h3>Permit Media (PDF copies of Permits)</h3>
	<cfquery name="getPermitMedia" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
        select distinct media_id, uri, permit_type, permit_num from (
		select media.media_id, media.media_uri as uri, p.permit_type, p.permit_num
           from loan_item li
		   left join specimen_part sp on li.collection_object_id = sp.collection_object_id
		   left join cataloged_item ci on sp.derived_from_cat_item = ci.collection_object_id
		   left join accn on ci.accn_id = accn.transaction_id
           left join permit_trans on accn.transaction_id = permit_trans.transaction_id
           left join permit p on permit_trans.permit_id = p.permit_id
           left join media_relations on p.permit_id = media_relations.related_primary_key 
           left join media on media_relations.media_id = media.media_id
		where li.transaction_id = <cfqueryparam CFSQLType="CF_SQL_DECIMAL" value="#loanDetails.transaction_id#">
                and (media_relations.related_primary_key is null 
                or (media_relations.media_relationship = 'shows permit'
                    and mime_type = 'application/pdf'))
        union
		select media.media_id, media.media_uri as uri, p.permit_type, p.permit_num
           from shipment s
           left join permit_shipment ps on s.shipment_id = ps.shipment_id
           left join permit p on ps.permit_id = p.permit_id
           left join media_relations on p.permit_id = media_relations.related_primary_key 
           left join media on media_relations.media_id = media.media_id
		where s.transaction_id = <cfqueryparam CFSQLType="CF_SQL_DECIMAL" value="#loanDetails.transaction_id#"> 
                and (media_relations.related_primary_key is null 
                or (media_relations.media_relationship = 'shows permit'
                    and mime_type = 'application/pdf'))
        ) where permit_type is not null
    </cfquery>
  
    <ul>
  	<cfloop query="getPermitMedia">
        <cfif media_id is ''> 
           <li>#permit_type# #permit_num# (no pdf)</li>
        <cfelse>
           <li><a href="#uri#">#permit_type# #permit_num#</a></li>
        </cfif>
    </cfloop>
    </ul>
    </div>
</cfoutput>
<script>
	dCount();
</script>
</cfif>

<!-------------------------------------------------------------------------------------------------->
<cfif Action is "deleLoan">
	<cftry>
	<cftransaction>
		<cfquery name="killLoan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			delete from loan where transaction_id=#transaction_id#
		</cfquery>
		<cfquery name="killTransAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			delete from trans_agent where transaction_id=#transaction_id#
		</cfquery>
		<cfquery name="killTrans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			delete from trans where transaction_id=#transaction_id#
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
		DELETE FROM permit_trans WHERE transaction_id = #transaction_id# and
		permit_id=#permit_id#
	</cfquery>
	<cflocation url="Loan.cfm?Action=editLoan&transaction_id=#transaction_id#">
</cfif>
<!-------------------------------------------------------------------------------------------------->
<cfif action is "saveShip">
	<cfoutput>
		<cfquery name="isShip" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select * from shipment where transaction_id = #transaction_id#
		</cfquery>
		<cfif isShip.recordcount is 0>
			<cfquery name="newShip" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				INSERT INTO shipment (
					TRANSACTION_ID
					,PACKED_BY_AGENT_ID
					,SHIPPED_CARRIER_METHOD
					,CARRIERS_TRACKING_NUMBER
					,SHIPPED_DATE
					,PACKAGE_WEIGHT
					,NO_OF_PACKAGES
					,HAZMAT_FG
					,INSURED_FOR_INSURED_VALUE
					,SHIPMENT_REMARKS
					,CONTENTS
					,FOREIGN_SHIPMENT_FG
					,SHIPPED_TO_ADDR_ID
					,SHIPPED_FROM_ADDR_ID
				) VALUES (
					#TRANSACTION_ID#
					,#PACKED_BY_AGENT_ID#
					,'#SHIPPED_CARRIER_METHOD#'
					,'#CARRIERS_TRACKING_NUMBER#'
					,'#dateformat(SHIPPED_DATE,"yyyy-mm-dd")#'
					,'#PACKAGE_WEIGHT#'
					,'#no_of_packages#'
					,#HAZMAT_FG#
					<cfif len(INSURED_FOR_INSURED_VALUE) gt 0>
						,#INSURED_FOR_INSURED_VALUE#
					<cfelse>
					 	,NULL
					</cfif>
					,'#SHIPMENT_REMARKS#'
					,'#CONTENTS#'
					,#FOREIGN_SHIPMENT_FG#
					,#SHIPPED_TO_ADDR_ID#
					,#SHIPPED_FROM_ADDR_ID#
				)
			</cfquery>
		  <cfelse>
			<cfquery name="upShip" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				 UPDATE shipment SET
					PACKED_BY_AGENT_ID = #PACKED_BY_AGENT_ID#
					,SHIPPED_CARRIER_METHOD = '#SHIPPED_CARRIER_METHOD#'
					,CARRIERS_TRACKING_NUMBER='#CARRIERS_TRACKING_NUMBER#'
					,SHIPPED_DATE='#dateformat(SHIPPED_DATE,"yyyy-mm-dd")#'
					,PACKAGE_WEIGHT='#PACKAGE_WEIGHT#'
					,NO_OF_PACKAGES='#no_of_packages#'
					,HAZMAT_FG=#HAZMAT_FG#
					<cfif len(#INSURED_FOR_INSURED_VALUE#) gt 0>
						,INSURED_FOR_INSURED_VALUE=#INSURED_FOR_INSURED_VALUE#
					<cfelse>
					 	,INSURED_FOR_INSURED_VALUE=null
					</cfif>
					,SHIPMENT_REMARKS='#SHIPMENT_REMARKS#'
					,CONTENTS='#CONTENTS#'
					,FOREIGN_SHIPMENT_FG=#FOREIGN_SHIPMENT_FG#
					,SHIPPED_TO_ADDR_ID=#SHIPPED_TO_ADDR_ID#
					,SHIPPED_FROM_ADDR_ID=#SHIPPED_FROM_ADDR_ID#
				WHERE
					transaction_id = #TRANSACTION_ID#
			</cfquery>
		</cfif>
		<cflocation url="Loan.cfm?Action=editLoan&transaction_id=#transaction_id#" addtoken="false">
	</cfoutput>
</cfif>
<!-------------------------------------------------------------------------------------------------->
<cfif action is "saveEdits">
	<cfoutput>
		<cftransaction>
			<cfquery name="upTrans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE  trans  SET
					collection_id=#collection_id#,
					TRANS_DATE = '#dateformat(initiating_date,"yyyy-mm-dd")#'
					,NATURE_OF_MATERIAL = '#NATURE_OF_MATERIAL#'
					,trans_remarks = '#trans_remarks#'
				where
					transaction_id = #transaction_id#
			</cfquery>
			<cfif not isdefined("return_due_date") or len(return_due_date) eq 0  >
`			    <!--- If there is no value set for return_due_date, don't overwrite an existing value.  --->
`			    <!--- This prevents edits to exhibition-subloans from wiping out an existing date value --->
			    <cfquery name="upLoan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				 UPDATE loan SET
					TRANSACTION_ID = #TRANSACTION_ID#,
					LOAN_TYPE = '#LOAN_TYPE#',
					LOAN_NUMber = '#loan_number#'
					,loan_status = '#loan_status#'
					,loan_description = '#loan_description#'
					,LOAN_INSTRUCTIONS = '#LOAN_INSTRUCTIONS#'
                                        ,insurance_value = '#INSURANCE_VALUE#'
                                        ,insurance_maintained_by = '#INSURANCE_MAINTAINED_BY#'
					where transaction_id = #transaction_id#
			    </cfquery>
			<cfelse>
			    <cfquery name="upLoan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				 UPDATE loan SET
					TRANSACTION_ID = #TRANSACTION_ID#,
					LOAN_TYPE = '#LOAN_TYPE#',
					LOAN_NUMber = '#loan_number#'
					,return_due_date = '#dateformat(return_due_date,"yyyy-mm-dd")#'
					,loan_status = '#loan_status#'
					,loan_description = '#loan_description#'
					,LOAN_INSTRUCTIONS = '#LOAN_INSTRUCTIONS#'
                                        ,insurance_value = '#INSURANCE_VALUE#'
                                        ,insurance_maintained_by = '#INSURANCE_MAINTAINED_BY#'
					where transaction_id = #transaction_id#
			    </cfquery>
			</cfif>
				<cfif isdefined("project_id") and len(project_id) gt 0>
					<cfquery name="newProj" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						INSERT INTO project_trans (
							project_id, transaction_id)
							VALUES (
								#project_id#,#transaction_id#)
					</cfquery>
				</cfif>
				<cfif isdefined("loan_type") and loan_type EQ 'exhibition-master' >
`					<!--- Propagate due date to child exhibition-subloans --->
					<cfset formatted_due_date = dateformat(return_due_date,"yyyy-mm-dd")>
					<cfquery name="upChildLoans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						UPDATE loan
 						SET
						      return_due_date = <cfqueryparam value = "#formatted_due_date#" CFSQLType="CF_SQL_DATE">
						WHERE loan_type = 'exhibition-subloan' AND
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
							'#PROJECT_NAME#'
							<cfif len(#START_DATE#) gt 0>
								,'#dateformat(START_DATE,"yyyy-mm-dd")#'
							</cfif>

							<cfif len(#END_DATE#) gt 0>
								,'#dateformat(END_DATE,"yyyy-mm-dd")#'
							</cfif>
							<cfif len(#PROJECT_DESCRIPTION#) gt 0>
								,'#PROJECT_DESCRIPTION#'
							</cfif>
							<cfif len(#PROJECT_REMARKS#) gt 0>
								,'#PROJECT_REMARKS#'
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
							 #newAgent_name_id#,
							 '#project_agent_role#',
							 1
							)
					</cfquery>
					<cfquery name="newTrans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						INSERT INTO project_trans (project_id, transaction_id) values (sq_project_id.currval, #transaction_id#)
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
							delete from trans_agent where trans_agent_id=#trans_agent_id_#
						</cfquery>
					<cfelse>
	                			<cfif len(agent_id_) GT 0><!--- don't try to add/update a blank row --->
						<cfif trans_agent_id_ is "new" and del_agnt_ is 0>
							<cfquery name="newTransAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
								insert into trans_agent (
									transaction_id,
									agent_id,
									trans_agent_role
								) values (
									#transaction_id#,
									#agent_id_#,
									'#trans_agent_role_#'
								)
							</cfquery>
						<cfelseif del_agnt_ is 0>
							<cfquery name="upTransAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
								update trans_agent set
									agent_id = #agent_id_#,
									trans_agent_role = '#trans_agent_role_#'
								where
									trans_agent_id=#trans_agent_id_#
							</cfquery>
						</cfif>
						</cfif>
					</cfif>
				   </cfif>
				</cfloop>
			</cftransaction>
			<cflocation url="Loan.cfm?Action=editLoan&transaction_id=#transaction_id#">
	</cfoutput>
</cfif>
<!-------------------------------------------------------------------------------------------------->
<cfif action is "makeLoan">
	<cfif not isdefined("return_due_date")><cfset return_due_date = ''></cfif>
	<cfoutput>
		<cfif
			len(loan_type) is 0 OR
			len(loan_number) is 0 OR
			len(initiating_date) is 0 OR
			len(rec_agent_id) is 0 OR
			len(auth_agent_id) is 0
		>
			<br>Something bad happened.
			<br>You must fill in loan_type, loannumber, authorizing_agent_name, initiating_date, loan_num_prefix, received_agent_name.
			<br>Use your browser's back button to fix the problem and try again.
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
					sq_transaction_id.nextval,
					'#initiating_date#',
					0,
					'loan',
					'#NATURE_OF_MATERIAL#',
					#collection_id#
					<cfif len(#trans_remarks#) gt 0>
						,'#trans_remarks#'
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
					sq_transaction_id.currval,
					'#loan_type#',
					'#loan_number#'
					<cfif len(#loan_status#) gt 0>
						,'#loan_status#'
					</cfif>
					<cfif len(#return_due_date#) gt 0>
						,'#dateformat(return_due_date,"yyyy-mm-dd")#'
					</cfif>
					<cfif len(#LOAN_INSTRUCTIONS#) gt 0>
						,'#LOAN_INSTRUCTIONS#'
					</cfif>
					<cfif len(#loan_description#) gt 0>
						,'#loan_description#'
					</cfif>
					<cfif len(#insurance_value#) gt 0>
						,'#insurance_value#'
					</cfif>
					<cfif len(#insurance_maintained_by#) gt 0>
						,'#insurance_maintained_by#'
					</cfif>
					)
			</cfquery>
			<cfquery name="authBy" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				INSERT INTO trans_agent (
				    transaction_id,
				    agent_id,
				    trans_agent_role
				) values (
					sq_transaction_id.currval,
					#auth_agent_id#,
					'authorized by')
			</cfquery>
			<cfquery name="in_house_contact" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				INSERT INTO trans_agent (
				    transaction_id,
				    agent_id,
				    trans_agent_role
				) values (
					sq_transaction_id.currval,
					#in_house_contact_agent_id#,
					'in-house contact')
			</cfquery>
			<cfquery name="recipient_institution" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				INSERT INTO trans_agent (
				    transaction_id,
				    agent_id,
				    trans_agent_role
				) values (
					sq_transaction_id.currval,
					#recipient_institution_agent_id#,
					'recipient institution')
			</cfquery>
		<cfif isdefined("additional_contact_agent_id") and len(additional_contact_agent_id) gt 0>
			<cfquery name="additional_contact" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				INSERT INTO trans_agent (
				    transaction_id,
				    agent_id,
				    trans_agent_role
				) values (
					sq_transaction_id.currval,
					#additional_contact_agent_id#,
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
					sq_transaction_id.currval,
					#foruseby_agent_id#,
					'for use by')
			</cfquery>
		</cfif>
			<cfquery name="newLoan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				INSERT INTO trans_agent (
				    transaction_id,
				    agent_id,
				    trans_agent_role
				) values (
					sq_transaction_id.currval,
					#REC_AGENT_ID#,
					'received by')
			</cfquery>
			<cfquery name="nextTransId" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select sq_transaction_id.currval nextTransactionId from dual
			</cfquery>
		</cftransaction>
		<cflocation url="Loan.cfm?Action=editLoan&transaction_id=#nextTransId.nextTransactionId#" addtoken="false">
	</cfoutput>
</cfif>
<!-------------------------------------------------------------------------------------------------->
<cfif action is "search">
  <cfset title="Search for Loans/Gifts">
  <script src="/includes/jquery/jquery-autocomplete/jquery.autocomplete.pack.js" language="javascript" type="text/javascript"></script>
  <cfoutput>
  <script>
		jQuery(document).ready(function() {
	  		jQuery("##part_name").autocomplete("/ajax/part_name.cfm", {
				width: 320,
				max: 50,
				autofill: false,
				multiple: false,
				scroll: true,
				scrollHeight: 300,
				matchContains: true,
				minChars: 1,
				selectFirst:false
			});
		});



</script>
   <div class="searchLoanWidth">
     <h2 class="wikilink">Find Loans/Gifts <img src="/images/info_i_2.gif" onClick="getMCZDocs('Loan/Gift_Transactions##Search_for_a_Loan_or_Gift')" class="likeLink" alt="[ help ]">
      </h2>
    <div id="loan">
      <cfquery name="ctType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select loan_type from ctloan_type order by loan_type
	</cfquery>
      <cfquery name="ctStatus" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select loan_status from ctloan_status order by loan_status
	</cfquery>

      <cfquery name="ctCollObjDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select coll_obj_disposition from ctcoll_obj_disp
	</cfquery>
      <br>
      <form name="SpecData" action="Loan.cfm" method="post">
        <input type="hidden" name="Action" value="listLoans">
        <input type="hidden" name="project_id" <cfif project_id gt 0> value="#project_id#" </cfif>>
        <table>
          <tr>
            <td align="right">Collection Name: </td>
            <td><select name="collection_id" size="1">
                <option value=""></option>
                <cfloop query="ctcollection">
                  <option value="#collection_id#">#collection#</option>
                </cfloop>
              </select>
              <img src="images/nada.gif" width="2" height="1"> Number: <span class="lnum">
              <input type="text" name="loan_number">
              </span></td>
          </tr>
          <tr>
            <td align="right"><select name="trans_agent_role_1">
                <option value="">Please choose an agent role...</option>
                <cfloop query="cttrans_agent_role">
                  <option value="#trans_agent_role#">-> #trans_agent_role#:</option>
                </cfloop>
              </select></td>
            <td><input type="text" name="agent_1"  size="50"></td>
          </tr>
          <tr>
            <td align="right"><select name="trans_agent_role_2">
                <option value="">Please choose an agent role...</option>
                <cfloop query="cttrans_agent_role">
                  <option value="#trans_agent_role#">-> #trans_agent_role#:</option>
                </cfloop>
              </select></td>
            <td><input type="text" name="agent_2"  size="50"></td>
          </tr>
          <tr>
            <td align="right"><select name="trans_agent_role_3">
                <option value="">Please choose an agent role...</option>
                <cfloop query="cttrans_agent_role">
                  <option value="#trans_agent_role#">-> #trans_agent_role#:</option>
                </cfloop>
              </select></td>
            <td><input type="text" name="agent_3"  size="50"></td>
          </tr>
          <tr>
            <td align="right">Type: </td>
            <td><select name="loan_type">
                <option value=""></option>
                <cfloop query="ctAllLoanType">
                  <option value="#ctAllLoanType.loan_type#">#ctAllLoanType.loan_type#</option>
                </cfloop>
              </select>
              <img src="images/nada.gif" width="25" height="1"> Status:&nbsp;
              <select name="loan_status">
                <option value=""></option>
                <cfloop query="ctLoanStatus">
                  <option value="#ctLoanStatus.loan_status#">#ctLoanStatus.loan_status#</option>
                </cfloop>
                <option value="not closed">not closed</option>
              </select></td>
          </tr>
          <tr>
            <td align="right">Transaction Date:</td>
            <td><input name="trans_date" id="trans_date" type="text">
             &nbsp; To:
              <input type='text' name='to_trans_date' id="to_trans_date"></td>
          </tr>
          <cfif scope eq 'Loan' >
            <tr>
              <td align="right"> Due Date: </td>
              <td><input type="text" name="return_due_date" id="return_due_date">
               &nbsp; To:
                <input type='text' name='to_return_due_date' id="to_return_due_date"></td>
            </tr>
          </cfif>
          <tr>
            <td align="right">Permit Number:</td>
            <td><input type="text" name="permit_num" size="50">
              <span class="infoLink" onclick="getHelp('get_permit_number');">Pick</span></td>
          </tr>
          <tr>
            <td align="right">Nature of Material:</td>
            <td><textarea name="nature_of_material" rows="3" cols="50"></textarea></td>
          </tr>
          <tr>
            <td align="right">Description: </td>
            <td><textarea name="loan_description" rows="3" cols="50"></textarea></td>
          </tr>
          <tr>
          <tr>
            <td align="right">Instructions:</td>
            <td><textarea name="loan_instructions" rows="3" cols="50"></textarea></td>
          </tr>
          <tr>
            <td align="right">Internal Remarks: </td>
            <td><textarea name="trans_remarks" rows="3" cols="50"></textarea></td>
          </tr>
          <tr>
            <td class="parts1"> Parts: </td>
            <td><table class="partloan">
                <tr>
                  <td valign="top"><label for="part_name_oper">Part<br/>
                      Match</label>
                    <select id="part_name_oper" name="part_name_oper">
                      <option value="is">is</option>
                      <option value="contains">contains</option>
                    </select></td>
                  <td valign="top"><label for="part_name">Part<br/>
                      Name</label>
                    <input type="text" id="part_name" name="part_name"></td>
                  <td valign="top"><label for="part_disp_oper">Disposition&nbsp;<br/>
                      Match</label>
                    <select id="part_disp_oper" name="part_disp_oper">
                      <option value="is">is</option>
                      <option value="isnot">is not</option>
                    </select></td>
                  <td valign="top"><label for="coll_obj_disposition">Part Disposition</label>
                    <select name="coll_obj_disposition" id="coll_obj_disposition" size="5" multiple="multiple">
                      <option value=""></option>
                      <cfloop query="ctCollObjDisp">
                        <option value="#ctCollObjDisp.coll_obj_disposition#">#ctCollObjDisp.coll_obj_disposition#</option>
                      </cfloop>
                    </select></td>
                </tr>
              </table></td>
          </tr>
          <tr>
            <td colspan="2" align="center">
            <input type="submit" value="Search" class="schBtn">
              &nbsp;
            <input type="reset" value="Clear" class="qutBtn">
            </td>
          </tr>
        </table>
      </form>
    </div>
    </div>
  </cfoutput>
</cfif>
<!-------------------------------------------------------------------------------------------------->
<cfif action is "listLoans">
<cfoutput>
	<cfset title="Loan Item List">
	<cfset sel = "select
		trans.transaction_id,
		loan_number,
		loan.loan_type loan_type,
                ctloan_type.scope loan_type_scope,
		loan_status,
		loan_instructions,
		loan_description,
		concattransagent(trans.transaction_id,'authorized by') auth_agent,
		concattransagent(trans.transaction_id,'entered by') ent_agent,
		concattransagent(trans.transaction_id,'received by') rec_agent,
		concattransagent(trans.transaction_id,'for use by') foruseby_agent,
		concattransagent(trans.transaction_id,'in-house contact') inHouse_agent,
		concattransagent(trans.transaction_id,'additional in-house contact') addInhouse_agent,
		concattransagent(trans.transaction_id,'additional outside contact') addOutside_agent,
		concattransagent(trans.transaction_id,'recipient institution') recip_inst,
		nature_of_material,
		trans_remarks,
		to_char(return_due_date,'YYYY-MM-DD') return_due_date,
                return_due_date - trunc(sysdate) dueindays,
		trans_date,
		to_char(closed_date, 'YYYY-MM-DD') closed_date,
		project_name,
		project.project_id pid,
		collection.collection">
	<cfset frm = " from
		loan,
		trans,
		project_trans,
		project,
		permit_trans,
		permit,
		collection,
                ctloan_type">
	<cfset sql = "where
		loan.transaction_id = trans.transaction_id AND
		trans.collection_id = collection.collection_id AND
		trans.transaction_id = project_trans.transaction_id (+) AND
		project_trans.project_id = project.project_id (+) AND
		loan.transaction_id = permit_trans.transaction_id (+) AND
		loan.loan_type= ctloan_type.loan_type (+) AND
		permit_trans.permit_id = permit.permit_id (+)">
	<cfif isdefined("trans_agent_role_1") AND len(trans_agent_role_1) gt 0>
		<cfset frm="#frm#,trans_agent trans_agent_1">
		<cfset sql="#sql# and trans.transaction_id = trans_agent_1.transaction_id">
		<cfset sql = "#sql# AND trans_agent_1.trans_agent_role = '#trans_agent_role_1#'">
	</cfif>


	<cfif isdefined("agent_1") AND len(agent_1) gt 0>
		<cfif #sql# does not contain "trans_agent_1">
			<cfset frm="#frm#,trans_agent trans_agent_1">
			<cfset sql="#sql# and trans.transaction_id = trans_agent_1.transaction_id">
		</cfif>
		<cfset frm="#frm#,preferred_agent_name trans_agent_name_1">
		<cfset sql="#sql# and trans_agent_1.agent_id = trans_agent_name_1.agent_id">
		<cfset sql = "#sql# AND upper(trans_agent_name_1.agent_name) like '%#ucase(agent_1)#%'">
	</cfif>
	<cfif isdefined("trans_agent_role_2") AND len(trans_agent_role_2) gt 0>
		<cfset frm="#frm#,trans_agent trans_agent_2">
		<cfset sql="#sql# and trans.transaction_id = trans_agent_2.transaction_id">
		<cfset sql = "#sql# AND trans_agent_2.trans_agent_role = '#trans_agent_role_2#'">
	</cfif>
	<cfif isdefined("agent_2") AND len(agent_2) gt 0>
		<cfif #sql# does not contain "trans_agent_2">
			<cfset frm="#frm#,trans_agent trans_agent_2">
			<cfset sql="#sql# and trans.transaction_id = trans_agent_2.transaction_id">
		</cfif>
		<cfset frm="#frm#,preferred_agent_name trans_agent_name_2">
		<cfset sql="#sql# and trans_agent_2.agent_id = trans_agent_name_2.agent_id">
		<cfset sql = "#sql# AND upper(trans_agent_name_2.agent_name) like '%#ucase(agent_2)#%'">
	</cfif>
	<cfif isdefined("trans_agent_role_3") AND len(#trans_agent_role_3#) gt 0>
		<cfset frm="#frm#,trans_agent trans_agent_3">
		<cfset sql="#sql# and trans.transaction_id = trans_agent_3.transaction_id">
		<cfset sql = "#sql# AND trans_agent_3.trans_agent_role = '#trans_agent_role_3#'">
	</cfif>
	<cfif isdefined("agent_3") AND len(#agent_3#) gt 0>
		<cfif #sql# does not contain "trans_agent_3">
			<cfset frm="#frm#,trans_agent trans_agent_3">
			<cfset sql="#sql# and trans.transaction_id = trans_agent_3.transaction_id">
		</cfif>
		<cfset frm="#frm#,preferred_agent_name trans_agent_name_3">
		<cfset sql="#sql# and trans_agent_3.agent_id = trans_agent_name_3.agent_id">
		<cfset sql = "#sql# AND upper(trans_agent_name_3.agent_name) like '%#ucase(agent_3)#%'">
	</cfif>
	<cfif isdefined("loan_number") AND len(#loan_number#) gt 0>
		<cfset sql = "#sql# AND upper(loan_number) like '%#ucase(loan_number)#%'">
	</cfif>
	<cfif isdefined("permit_num") AND len(#permit_num#) gt 0>
		<cfset sql = "#sql# AND PERMIT_NUM = '#PERMIT_NUM#'">
	</cfif>
	<cfif isdefined("collection_id") AND len(#collection_id#) gt 0>
		<cfset sql = "#sql# AND trans.collection_id = #collection_id#">
	</cfif>
	<cfif isdefined("loan_type") AND len(#loan_type#) gt 0>
		<cfset sql = "#sql# AND loan.loan_type = '#loan_type#'">
	</cfif>
	<cfif isdefined("loan_status") AND len(#loan_status#) gt 0>
    	<cfif loan_status eq "not closed">
        	<cfset sql = "#sql# AND loan_status <> 'closed'">
    	<cfelse>
			<cfset sql = "#sql# AND loan_status = '#loan_status#'">
        </cfif>
	</cfif>
	<cfif isdefined("loan_instructions") AND len(#loan_instructions#) gt 0>
		<cfset sql = "#sql# AND upper(loan_instructions) LIKE '%#ucase(loan_instructions)#%'">
	</cfif>
	<cfif isdefined("rec_agent") AND len(#rec_agent#) gt 0>
		<cfset sql = "#sql# AND upper(recAgnt.agent_name) LIKE '%#ucase(escapeQuotes(rec_agent))#%'">
	</cfif>
	<cfif isdefined("auth_agent") AND len(#auth_agent#) gt 0>
		<cfset sql = "#sql# AND upper(authAgnt.agent_name) LIKE '%#ucase(escapeQuotes(auth_agent))#%'">
	</cfif>
	<cfif isdefined("ent_agent") AND len(#ent_agent#) gt 0>
		<cfset sql = "#sql# AND upper(entAgnt.agent_name) LIKE '%#ucase(escapeQuotes(ent_agent))#%'">
	</cfif>
	<cfif isdefined("nature_of_material") AND len(#nature_of_material#) gt 0>
		<cfset sql = "#sql# AND upper(nature_of_material) LIKE '%#ucase(escapeQuotes(nature_of_material))#%'">
	</cfif>
	<cfif isdefined("return_due_date") and len(return_due_date) gt 0>
		<cfif not isdefined("to_return_due_date") or len(to_return_due_date) is 0>
			<cfset to_return_due_date=return_due_date>
		</cfif>
		<cfset sql = "#sql# AND return_due_date between to_date('#dateformat(return_due_date, "yyyy-mm-dd")#')
			and to_date('#dateformat(to_return_due_date, "yyyy-mm-dd")#')">
	</cfif>
	<cfif isdefined("trans_date") and len(#trans_date#) gt 0>
		<cfif not isdefined("to_trans_date") or len(to_trans_date) is 0>
			<cfset to_trans_date=trans_date>
		</cfif>
		<cfset sql = "#sql# AND trans_date between to_date('#dateformat(trans_date, "yyyy-mm-dd")#')
			and to_date('#dateformat(to_trans_date, "yyyy-mm-dd")#')">
	</cfif>
	<cfif isdefined("trans_remarks") AND len(#trans_remarks#) gt 0>
		<cfset sql = "#sql# AND upper(trans_remarks) LIKE '%#ucase(trans_remarks)#%'">
	</cfif>
	<cfif isdefined("loan_description") AND len(#loan_description#) gt 0>
		<cfset sql = "#sql# AND upper(loan_description) LIKE '%#ucase(loan_description)#%'">
	</cfif>
	<cfif isdefined("collection_object_id") AND len(#collection_object_id#) gt 0>
		<cfset frm="#frm#, loan_item">
		<cfset sql = "#sql# AND loan.transaction_id=loan_item.transaction_id AND loan_item.collection_object_id IN (#collection_object_id#)">
	</cfif>
	<cfif isdefined("notClosed") AND len(#notClosed#) gt 0>
		<cfset sql = "#sql# AND loan_status <> 'closed'">
	</cfif>

	<cfif (isdefined("part_name") AND len(part_name) gt 0) or (isdefined("coll_obj_disposition") AND len(coll_obj_disposition) gt 0)>
		<cfif frm does not contain "loan_item">
			<cfset frm="#frm#, loan_item">
			<cfset sql = "#sql# AND loan.transaction_id=loan_item.transaction_id ">
		</cfif>
		<cfif frm does not contain "coll_object">
			<cfset frm="#frm#,coll_object">
			<cfset sql=sql & " and loan_item.collection_object_id=coll_object.collection_object_id ">
		</cfif>
		<cfif frm does not contain "specimen_part">
			<cfset frm="#frm#,specimen_part">
			<cfset sql=sql & " and coll_object.collection_object_id = specimen_part.collection_object_id ">
		</cfif>

		<cfif isdefined("part_name") AND len(part_name) gt 0>
			<cfif not isdefined("part_name_oper")>
				<cfset part_name_oper='is'>
			</cfif>
			<cfif part_name_oper is "is">
				<cfset sql=sql & " and specimen_part.part_name = '#part_name#'">
			<cfelse>
				<cfset sql=sql & " and upper(specimen_part.part_name) like  '%#ucase(part_name)#%'">
			</cfif>
		</cfif>
		<cfif isdefined("coll_obj_disposition") AND len(coll_obj_disposition) gt 0>
			<cfif not isdefined("part_disp_oper")>
				<cfset part_disp_oper='is'>
			</cfif>
			<cfif part_disp_oper is "is">
				<cfset sql=sql & " and coll_object.coll_obj_disposition IN ( #listqualify(coll_obj_disposition,'''')# )">
			<cfelse>
				<cfset sql=sql & " and coll_object.coll_obj_disposition NOT IN ( #listqualify(coll_obj_disposition,'''')# )">
			</cfif>
		</cfif>
	</cfif>
	<cfset sql ="#sel# #frm# #sql#
		group by
		 	trans.transaction_id,
		   	loan_number,
		    loan.loan_type,
            ctloan_type.scope,
		    loan_status,
		    loan_instructions,
		    loan_description,
			concattransagent(trans.transaction_id,'authorized by'),
		 	concattransagent(trans.transaction_id,'entered by'),
		 	concattransagent(trans.transaction_id,'received by'),
			concattransagent(trans.transaction_id,'additional outside contact'),
			concattransagent(trans.transaction_id,'additional in-house contact'),
			concattransagent(trans.transaction_id,'in-house contact'),
			concattransagent(trans.transaction_id,'recipient institution'),
		 	nature_of_material,
		 	trans_remarks,
		 	return_due_date,
		  	trans_date,
		  	closed_date,
		   	project_name,
		 	project.project_id,
		 	collection.collection
		ORDER BY to_number(regexp_substr (loan_number, '^[0-9]+', 1, 1)), to_number(regexp_substr (loan_number, '[0-9]+', 1, 2)), loan_number
    ">
	 <cfquery name="allLoans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		#preservesinglequotes(sql)#
	</cfquery>
    <cfif allLoans.recordcount is 0>
      Nothing matched your search criteria.
    </cfif>

    <cfset rURL="Loan.cfm?csv=true">
    <cfloop list="#StructKeyList(form)#" index="key">
    <cfset allLoans.recordcount ++ />
      <cfif len(form[key]) gt 0>
        <cfset rURL='#rURL#&#key#=#form[key]#'>
      </cfif>
    </cfloop>
       <cfset loannum = ''>
    <cfif #allLoans.recordcount# eq 1>
    <cfset loannum = 'item'>

    </cfif>
    <cfif #allLoans.recordcount# gt 1>
    <cfset loannum = 'items'>
    </cfif>
 <header>
     <div id="page_title">
      <h1  style="font-size: 1.5em;line-height: 1.6em;margin: 0;padding: 1em 0 0 0;">Search Results<img src="/images/info_i_2.gif" border="0" onClick="getMCZDocs('Loan/Gift_Transactions##Loan_Search_Results_List')" class="likeLink" alt="[ help ]" style="vertical-align:top;"></h1>
    </div>
   <p> #allLoans.recordcount# #loannum# <a href="#rURL#" class="download">Download these results as a CSV file</a></p>
   </header>
    <hr/>
  </cfoutput>

    <cfset i=1>

    <cfif not isdefined("csv")>
      <cfset csv=false>
    </cfif>
    <cfif csv is true>
      <cfset dlFile = "ArctosLoanData.csv">
      <cfset variables.fileName="#Application.webDirectory#/download/#dlFile#">
      <cfset variables.encoding="UTF-8">
      <cfscript>
			variables.joFileWriter = createObject('Component', '/component.FileWriter').init(variables.fileName, variables.encoding, 32768);
			d='loan_number,item_count,auth_agent,inHouse_agent,addInhouse_agent,Recipient,recip_inst,foruseby_agent,addOutside_agent,loan_type,loan_status,Transaction_Date,return_due_date,nature_of_material,loan_description,loan_instructions,trans_remarks,ent_agent,Project';
		 	variables.joFileWriter.writeLine(d);
	</cfscript>
    </cfif>
    <cfoutput query="allLoans" group="transaction_id">

      <cfset overdue = ''>
      <cfset overduemsg = ''>
      <cfif LEN(dueindays) GT 0 AND dueindays LT 0 AND loan_status IS NOT "closed" >
        <cfset overdue='style="color: RED;"'>
        <cfset overduedays = ABS(dueindays)>
        <cfset overduemsg=' #overduedays# days overdue'>
      </cfif>
            <cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select count(*) c from loan_item where transaction_id=#transaction_id#
		    </cfquery>
<div class="loan_results">
    <div id="listloans">

    <p>#i# of #allLoans.recordcount# #loannum#</p>
       <dl>
         <dt>Collection &amp; Number:</dt>
         <dd><strong>#collection# / #loan_number#</strong>
              <cfif c.c gt 0>
                (#c.c# items)
              </cfif>
         </dd>
                <dt>Authorized By:</dt>
                 <cfif len(auth_agent) GT 0>
                  <dd class="mandcolr">#auth_agent#</dd>
                       <cfelse>
                   <dd class="emptystatus">N/A</dd>
                    </cfif>
                <dt title="primary in-house contact; 1 of 2 possible in-house contacts to receive email reminder">In-house Contact:</dt>

                  <cfif len(inHouse_agent) GT 0>
                     <dd class="mandcolr"> #inHouse_agent#</dd>
                    <cfelse>
                   <dd class="emptystatus">N/A</dd>
                  </cfif>


                <dt title="primary in-house contact; 1 of 2 possible in-house contacts to receive email reminder">Additional In-house Contact:</dt>
                  <cfif len(addInhouse_agent) GT 0>
                    <dd>#addInhouse_agent#</dd>
                    <cfelse>
                  <dd class="emptystatus">N/A</dd>
                  </cfif>

                <dt title="this is the primary borrower; listed on email reminder; 1 of 3 possible outside agents to receive email reminder; ship to address should be for this agent">Recipient:</dt>
                <dd class="mandcolr" title="1 of 3 possible outside agents to receive email reminder; listed on email reminder">#rec_agent#</dd>
                <dt title="1 of 3 possible outside agents to receive email reminder; listed on email reminder">For use by:</dt>

                  <cfif len(foruseby_agent) GT 0>
                    <dd>#foruseby_agent#</dd>
                    <cfelse>
                   <dd class="emptystatus">N/A</dd>
                  </cfif>
                 <dt>Recipient Institution:</dt>
                  <cfif len(recip_inst) GT 0>
                    <dd>#recip_inst#</dd>
                    <cfelse>
                   <dd class="emptystatus">N/A</dd>
                  </cfif>
                <dt title="1 of 3 possible outside agents to receive email reminder">Additional Outside Contact:</dt>
                <cfif len(addOutside_agent) GT 0>
                    <dd>#addOutside_agent#</dd>
                    <cfelse>
                   <dd class="emptystatus">N/A</dd>
                  </cfif>
                </dd>
                <dt title="included in email reminder">Type:</dt>
                <dd class="mandcolr">#loan_type#</dd>
                <dt title="included in email reminder">Status:</dt>
                <dd class="mandcolr">#loan_status# <cfif loan_status EQ 'closed' and len(closed_date) GT 0>(#closed_date#)</cfif></dd>
                <dt title="included in email reminder">Transaction Date:</dt>
                 <cfif len(trans_date) GT 0>
                <dd  class="mandcolr">#dateformat(trans_date,"yyyy-mm-dd")#</dd>
                <cfelse>
                <dd class="mandcolrstatus">N/A</dd>
                </cfif>

                <dt title="included in email reminder">Due Date:</dt>
                <cfif len(return_due_date) GT 0>
                <dd #overdue# class="mandcolr"><strong>#return_due_date#</strong> #overduemsg#</dd>
				<cfelse>
                <dd class="mandcolrstatus">N/A</dd>
                </cfif>

                <dt title="included in email reminder">Nature of Material:</dt>
                <cfif len(nature_of_material) GT 0>
                <dd class="mandcolr large">#nature_of_material#</dd>
                <cfelse>
                <dd class="mandcolrstatus large">N/A</dd>
                </cfif>
                <dt>Description:</dt>
                <cfif len(loan_description) GT 0>
                   <dd class="large">#loan_description#</dd>
                    <cfelse>
                   <dd class="large emptystatus">N/A</dd>
                  </cfif>

                <dt>Instructions:</dt>
                 <cfif len(loan_instructions) GT 0>
                    <dd class="large">#loan_instructions#</dd>
                    <cfelse>
                    <dd class="large emptystatus">N/A</dd>
                  </cfif>

                <dt>Internal Remarks:</dt>

                  <cfif len(trans_remarks) GT 0>
                    <dd class="large">#trans_remarks#</dd>
                    <cfelse>
                    <dd class="large emptystatus">N/A</dd>
                  </cfif>

                <dt>Entered By:</dt>
                 <cfif len(ent_agent) GT 0>
                 <dd>#ent_agent#</dd>
                 <cfelse>
                 <dd>N/A</dd>
                 </cfif>
                <dt>Project:</dt>
                <dd>
                  <cfquery name="p" dbtype="query">
								select project_name,pid from allLoans where transaction_id=#transaction_id#
								group by project_name,pid
							</cfquery>
                  <cfloop query="p">
                    <cfif len(P.project_name)>
                      <CFIF P.RECORDCOUNT gt 1>

                      </CFIF>
                      <a href="/Project.cfm?Action=editProject&project_id=#p.pid#"> <strong>#P.project_name#</strong> </a><BR>
                      <cfelse>
                   None
                    </cfif>
                  </cfloop>
                </dd>
                <ul class="loan_buttons">
      <li><a href="a_loanItemReview.cfm?transaction_id=#transaction_id#">Review Items</a></li>
       <cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
       <li class="add"><a href="SpecimenSearch.cfm?Action=dispCollObj&transaction_id=#transaction_id#">Add Items</a></li>
       <li class="barcode"><a href="loanByBarcode.cfm?transaction_id=#transaction_id#">Add Items by Barcode</a></li>
       <li class="edit"><a href="Loan.cfm?transaction_id=#transaction_id#&Action=editLoan">Edit #loan_type_scope#</a></li>
       <cfif #project_id# gt 0>
       <li><a href="Project.cfm?Action=addTrans&project_id=#project_id#&transaction_id=#transaction_id#"> [ Add To Project ]</a></li>
         </cfif>
     </cfif>
  </ul>

              </dl>


        </div>
        </div>
      <cfif csv is true>
        <cfset d='"#escapeDoubleQuotes(collection)# #escapeDoubleQuotes(loan_number)#"'>
        <cfset d=d &',"#c.c#"'>
        <cfset d=d &',"#escapeDoubleQuotes(auth_agent)#"'>
        <cfset d=d &',"#escapeDoubleQuotes(inHouse_agent)#"'>
        <cfset d=d &',"#escapeDoubleQuotes(addInhouse_agent)#"'>
        <cfset d=d &',"#escapeDoubleQuotes(rec_agent)#"'>
        <cfset d=d &',"#escapeDoubleQuotes(recip_inst)#"'>
        <cfset d=d &',"#escapeDoubleQuotes(foruseby_agent)#"'>
        <cfset d=d &',"#escapeDoubleQuotes(addOutside_agent)#"'>
        <cfset d=d &',"#escapeDoubleQuotes(loan_type)#"'>
        <cfset d=d &',"#escapeDoubleQuotes(loan_status)#"'>
        <cfset d=d &',"#dateformat(trans_date,"yyyy-mm-dd")#"'>
        <cfset d=d &',"#escapeDoubleQuotes(return_due_date)#"'>
        <cfset d=d &',"#escapeDoubleQuotes(nature_of_material)#"'>
        <cfset d=d &',"#escapeDoubleQuotes(loan_description)#"'>
        <cfset d=d &',"#escapeDoubleQuotes(loan_instructions)#"'>
        <cfset d=d &',"#escapeDoubleQuotes(trans_remarks)#"'>
        <cfset d=d &',"#escapeDoubleQuotes(ent_agent)#"'>
        <cfset d=d &',"#escapeDoubleQuotes(valuelist(p.project_name))#"'>
        <cfscript>
				variables.joFileWriter.writeLine(d);
			</cfscript>
      </cfif>
      <cfset i=#i#+1>
    </cfoutput>

	<cfif csv is true>
		<cfscript>
			variables.joFileWriter.close();
		</cfscript>
		<cflocation url="/download.cfm?file=#dlFile#" addtoken="false">
	</cfif>
</table>
</cfif>
<cfinclude template="includes/_footer.cfm">
