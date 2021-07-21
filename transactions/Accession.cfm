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
		<cfset pageTitle = "Edit Accession #accessionNumber.accn_number#">
		<cfquery name="accessControl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select trans.transaction_id, vpd_collection_cde.collection_cde 
			from 
				trans
				left outer join vpd_collection_cde on trans.collection_id = vpd_collection_cde.collection_id
			where trans.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
		</cfquery>
		<cfif accessControl.recordcount EQ 0>
			<cfthrow  message="No such accession record or you don't have access rights for this accession record.">
		<cfelse>
			<cfset cde = "">
			<cfloop query="accessControl">
				<cfset cde = "#cde##accessControl.collection_cde#">
			</cfloop>
			<cfif len(cde) EQ 0>
				<cfthrow  message="You don't have access rights for this accession record.">
			</cfif>
		</cfif>
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
	SELECT accn_status 
	FROM ctaccn_status 
	<cfif isdefined("session.roles") and NOT listcontainsnocase(session.roles,"admin_transactions")>
		WHERE accn_status <> 'complete-reviewed'
	</cfif>
	ORDER BY accn_status
</cfquery>
<cfquery name="ctAccnType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	SELECT accn_type 
	FROM ctaccn_type order by accn_type
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
			$("##received_date").datepicker({ dateFormat: 'yy-mm-dd'});
		});
	</script>
</cfoutput>
<!-------------------------------------------------------------------------------------------------->
<cfif action is "new">
	<cfset title="New Accession">
	<cfoutput>
		<main class="container py-3" id="content">
			<h1 class="h2" id="newAccnFormSectionLabel" >Create New Accession <i class="fas fa-info-circle" onClick="getMCZDocs('Accession)" aria-label="help link"></i></h1>
			<div class="row border rounded bg-light mt-2 mb-4 p-2">
				<section class="col-12" title="next available accession number"> 
					<div id="nextNumDiv">
						<h2 class="h4 float-left" id="nextNumberSectionLabel">Next Available Accession Number <span class="sr-only">to be used in accession number field</span>: &nbsp; &nbsp;</h2>
						<cfquery name="gnn" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							select max(to_number(accn_number)) + 1 as next_accn_num from accn 
						</cfquery>
						<div class="float-left">
							<cfloop query="gnn">
								<button type="button" style="min-width:200px;" class="btn btn-xs btn-outline-primary pt-1 mt-1 mb-3 px-2 w-auto text-left" onclick="$('##accn_number').val(#gnn.next_accn_num#);">#gnn.next_accn_num#</button>
							</cfloop>
						</div>
					</div>
				</section><!--- next number section --->
				<section class="col-12 border bg-white pt-3" id="newAccnFormSection" aria-label="Form to create new accession">
					<form name="newAccession" id="newAccession" class="" action="/transactions/Accession.cfm" method="post" onSubmit="return noenter();">
						<input type="hidden" name="action" value="makeAccn">
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
								<label for="accn_number" class="data-entry-label">Accession Number (nnnnn)</label>
								<input type="text" name="accn_number" class="reqdClr data-entry-input" id="accn_number" required pattern="#ACCNNUMBERPATTERN#">
							</div>
							<div class="col-12 col-md-3">
								<label for="status" class="data-entry-label">Status</label>
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
								<label for="accn_type" class="data-entry-label">Accession Type</label>
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
									<label for="received_agent" class="data-entry-label">
										Received From:
										<span id="received_agent_view">&nbsp;&nbsp;&nbsp;&nbsp;</span>
									</label>
								</span>
								<div class="input-group">
									<div class="input-group-prepend">
										<span class="input-group-text smaller bg-lightgreen" id="received_agent_icon"><i class="fa fa-user" aria-hidden="true"></i></span> 
									</div>
									<input name="received_agent_name" id="received_agent_name" class="reqdClr form-control form-control-sm data-entry-input" required >
								</div>
								<input type="hidden" name="received_agent_id" id="received_agent_id"  >
								<script>
									$(makeRichTransAgentPicker('received_agent_name', 'received_agent_id','received_agent_icon','received_agent_view',null))
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
									<input  name="rec_agent_name" id="rec_agent_name" class="form-control form-control-sm data-entry-input" >
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
									<label for="in_house_contact_agent_name" class="data-entry-label">
										In-House Contact:
										<span id="in_house_contact_agent_view">&nbsp;&nbsp;&nbsp;&nbsp;</span> 
									</label>
								</span>
								<div class="input-group">
									<div class="input-group-prepend">
										<span class="input-group-text smaller bg-lightgreen" id="in_house_contact_agent_icon"><i class="fa fa-user" aria-hidden="true"></i></span> 
									</div>
									<input type="text" name="in_house_contact_agent_name" id="in_house_contact_agent_name" class="form-control form-control-sm data-entry-input">
								</div>
								<input type="hidden" name="in_house_contact_agent_id" id="in_house_contact_agent_id" >
								<script>
									$(makeRichTransAgentPicker('in_house_contact_agent_name','in_house_contact_agent_id','in_house_contact_agent_icon','in_house_contact_agent_view',null));
								</script> 
							</div>
							<div class="col-12 col-md-6">
								<span>
									<label for="additional_incontact_agent_name" class="data-entry-label">
										Additional In-house Contact:
										<span id="additional_incontact_agent_view">&nbsp;&nbsp;&nbsp;&nbsp;</span> 
									</label>
								</span>
								<div class="input-group">
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
						</div>
						<div class="form-row mb-2">
							<div class="col-12 col-md-4">
								<label for="estimated_count" class="data-entry-label">Estimated Count</label>
								<input type="text" name="estimated_count" id="estimated_count" value="" class="w-100 data-entry-input">
							</div>
							<div class="col-12 col-md-4">
								<label for="received_date" class="data-entry-label">Date Received</label>
								<input type="text" name="received_date" id="received_date" 
									required
									value="#dateformat(now(),"yyyy-mm-dd")#" 
									class="reqdClr w-100 data-entry-input">
							</div>
							<div class="col-12 col-md-4">
								<label for="date_entered" class="data-entry-label">Date Entered</label>
								<input type="text" name="date_entered" id="date_entered"
									disabled="true"
									value="#dateformat(now(),"yyyy-mm-dd")#" 
									class="w-100 data-entry-input">
							</div>
						</div>
						<div class="form-row mb-2">
							<div class="col-12 col-md-12">
								<label for="nature_of_material" class="data-entry-label">Nature of Material (<span id="length_nature_of_material"></span>)</label>
								<textarea name="nature_of_material" id="nature_of_material" rows="2" 
									onkeyup="countCharsLeft('nature_of_material', 4000, 'length_nature_of_material');"
									class="reqdClr form-control form-control-sm w-100 autogrow" 
									required ></textarea>
							</div>
						</div>
						<div class="form-row mb-2">
							<div class="col-12 col-md-12">
								<label for="trans_remarks" class="data-entry-label">Internal Remarks (<span id="length_trans_remarks"></span>)</label>
								<textarea name="trans_remarks" id="trans_remarks" 
									onkeyup="countCharsLeft('trans_remarks', 4000, 'length_trans_remarks');"
									class="form-control form-control-sm w-100 autogrow" rows="2"></textarea>
							</div>
						</div>
						<div class="form-row mb-2">
							<div class="col-12 col-md-4">
								<label for="radio1" class="float-left text-left mt-1">To be MCZ cataloged</label>
								<input type="radio" name="for_use_by" value="" checked="checked" id="radio1" class="mt-2 mx-3 float-left">
							</div>
							<div class="col-12 col-md-4">
								<label for="radio2" class="float-left text-left mt-1">For use by HMNH Exhibits</label>
								<input type="radio" name="for_use_by" value="116195" id="radio2" class="mt-2 mx-3 float-left">
							</div>
							<div class="col-12 col-md-4">
								<label for="radio3" class="float-left text-left mt-1">For use by HMNH Education</label>
								<input type="radio" name="for_use_by" value="91906" id="radio3" class="mt-2 mx-3 float-left">
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
								<input type="button" value="Create Accession" class="btn mt-2 btn-xs btn-primary"
									onClick="if (checkFormValidity($('##newAccession')[0])) { submit();  } ">
							</div>
						</div>
					</form>
				</section>
				<!--- Begin next available number list in an aside, ml-sm-4 to provide offset from column above holding the form. --->
				
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
								loadTransactionFormMedia(#transaction_id#,"accn"); 
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
					trans_date dateEntered,
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
				<cfthrow message = "Request to edit an accession, but the provided transaction_id was for a different transaction type [#accessionDetails.transaction_type#].">
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
		
		<main class="container py-3" id="content" title="Edit Accession Form Content">
			<cftry>
				<h1 class="h2 pb-0 ml-3">Edit Accession
					<strong>#accessionDetails.collection# #accessionDetails.accn_number#</strong> 
					<i class="fas fa-info-circle" onClick="getMCZDocs('Accession_Field_Definitions')" aria-label="help link"></i>
				</h1>
				<section class="row mx-0 border rounded my-2 pt-2" title="Edit Accession Details" >
					<form class="col-12" name="editAccnForm" id="editAccnForm" action="/transactions/Accession.cfm" method="post" onSubmit="return noenter();">
						<input type="hidden" name="method" value="saveAccn"><!--- used in normal ajax save, which uses the form fields to post to transactions/component/functions.cfc --->
						<input id="action" type="hidden" name="action" value="edit"><!--- reused by delete accession, not used in normal save --->
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
								<label for="accn_number" class="data-entry-label">Accession Number (nnnnnn)</label>
								<input type="text" name="accn_number" id="accn_number" value="#encodeForHTML(accessionDetails.accn_number)#" class="reqdClr data-entry-input" 
									required pattern="#ACCNNUMBERPATTERN#" >
							</div>
							<div class="col-12 col-md-3">
								<label for="accn_type" class="data-entry-label">Accession Type</label>
								<select name="accn_type" id="accn_type" class="reqdClr data-entry-select" required >
									<cfloop query="ctAccnType">
										<cfif ctAccnType.accn_type NEQ "transfer" OR accessionDetails.collection_id EQ MAGIC_MCZ_COLLECTION >
											<option <cfif ctAccnType.accn_type is accessionDetails.accn_type> selected="selected" </cfif>
												value="#ctAccnType.accn_type#">#ctAccnType.accn_type#</option>
										<cfelseif accessionDetails.accn_type EQ "transfer" AND accessionDetails.collection_id NEQ MAGIC_MCZ_COLLECTION >
											<option <cfif ctAccnType.accn_type is accessionDetails.accn_type> selected="selected" </cfif> value="" ></option>
										</cfif>
									</cfloop>
								</select>
							</div>
							<div class="col-12 col-md-3">
								<label for="estimated_count" class="data-entry-label">Estimated Count</label>
								<input type="text" name="estimated_count" id="estimated_count" 
									value="#encodeForHTML(accessionDetails.estimated_count)#" class="reqdClr data-entry-input" required >
							</div>
						</div>
						<div class="form-row mb-1">
							<div class="col-12 col-md-3">
								<label for="accn_status" class="data-entry-label">Accession Status</label>
								<cfif isdefined("session.roles") and NOT listcontainsnocase(session.roles,"admin_transactions") and accessionDetails.accn_status IS 'complete-reviewed'>
									<input type="text" name="accn_status_view" id="accn_status" value="#encodeForHTML(accessionDetails.accn_status)#" class="reqdClr data-entry-input" disabled> 
									<input type="hidden" name="accn_status" id="accn_status_submit" value="#encodeForHTML(accessionDetails.accn_status)#"> 
								<cfelse>
									<span>
										<select name="accn_status" id="accn_status" class="reqdClr data-entry-select" required >
											<cfloop query="ctAccnStatus">
												<option <cfif ctAccnStatus.accn_status is accessionDetails.accn_status> selected="selected" </cfif>
													value="#ctAccnStatus.accn_status#">#ctAccnStatus.accn_status#</option>
											</cfloop>
										</select>
									</span>
								</cfif>
							</div>
							<div class="col-12 col-md-3">
								<label for="received_date" class="data-entry-label">Date Received</label>
								<input type="text" name="received_date" id="received_date" required
									value="#dateformat(accessionDetails.received_date,"yyyy-mm-dd")#" class="reqdClr data-entry-input" >
							</div>
							<div class="col-12 col-md-3">
								<span class="data-entry-label">Date Entered</span>
								<div class="col-12 bg-light border non-field-text">
									<span id="date_entered">#dateformat(accessionDetails.dateEntered,'yyyy-mm-dd')#</span>
								</div>
							</div>
							<div class="col-12 col-md-3">
								<span class="data-entry-label">Entered By</span>
								<div class="col-12 bg-light border non-field-text">
									<span id="entered_by">#encodeForHTML(accessionDetails.enteredby)#</span>
								</div>
							</div>
						</div>
						<!--- Begin transaction agents table: Load via ajax. --->
						<div class="form-row my-1">
							<script>
								function reloadTransactionAgents() { 
									loadAgentTable("agentTableContainerDiv",#transaction_id#,"editAccnForm",handleChange);
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
										monitorForChanges('editAccnForm',handleChange);
									});
								});
							</script>
						</div>
						<div class="form-row mb-1">
							<div class="col-12">
								<label for="nature_of_material" class="data-entry-label">Nature of Material (<span id="length_nature_of_material"></span>)</label>
								<textarea name="nature_of_material" id="nature_of_material" rows="1" 
									onkeyup="countCharsLeft('nature_of_material', 4000, 'length_nature_of_material');"
									class="reqdClr autogrow data-entry-textarea" required >#encodeForHtml(accessionDetails.nature_of_material)#</textarea>
							</div>
						</div>
						<div class="form-row mb-1">
							<div class="col-12">
								<label for="trans_remarks" class="data-entry-label">Internal Remarks (<span id="length_trans_remarks"></span>)</label>
								<textarea name="trans_remarks" id="trans_remarks" rows="1"
									onkeyup="countCharsLeft('trans_remarks', 4000, 'length_trans_remarks');"
									class="autogrow data-entry-textarea">#encodeForHTML(accessionDetails.trans_remarks)#</textarea>
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
									onClick="if (checkFormValidity($('##editAccnForm')[0])) { saveEdits();  } " 
									id="submitButton" >
								<button type="button" aria-label="Print Accession Paperwork" id="accnPrintDialogLauncher"
									class="btn btn-xs btn-info mr-2" value="Print..."
									onClick=" openTransactionPrintDialog(#transaction_id#, 'Accession', 'accnPrintDialog');">Print...</button>
								<output id="saveResultDiv" class="text-danger">&nbsp;</output>	
								<input type="button" value="Delete Accession" class="btn btn-xs btn-danger float-right"
									onClick=" $('##action').val('edit'); confirmDialog('Delete this Accession?','Confirm Delete Accession', function() { $('##editAccnForm').removeAttr('onsubmit'); $('##action').val('deleAccn'); $('##editAccnForm').submit(); } );">
							</div>
						</div>
						<div id="accnPrintDialog"></div>
						<script>
							$(document).ready(function() {
								monitorForChanges('editAccnForm',handleChange);
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
									data : $('##editAccnForm').serialize(),
									success : function (data) {
										$('##saveResultDiv').html('Saved.');
										$('##saveResultDiv').addClass('text-success');
										$('##saveResultDiv').removeClass('text-danger');
										$('##saveResultDiv').removeClass('text-warning');
										loadAgentTable("agentTableContainerDiv",#transaction_id#,"editAccnForm",handleChange);
									},
									error: function(jqXHR,textStatus,error){
										$('##saveResultDiv').html('Error.');
										$('##saveResultDiv').addClass('text-danger');
										$('##saveResultDiv').removeClass('text-success');
										$('##saveResultDiv').removeClass('text-warning');
										handleFail(jqXHR,textStatus,error,'saving accession record');
									}
								});
							};
						</script>
					</form>
				</section>
				<script>
					function updateItemSections() { 
						updateAccnItemCount('#transaction_id#','accnItemCountDiv');
						updateAccnItemDispositions('#transaction_id#','accnItemDispositionsDiv');
						updateTransItemCountries('#transaction_id#','countriesOfOriginDiv');
						updateAccnLoans('#transaction_id#','accnLoansDiv');
					};
					$(document).ready(function() {
						updateItemSections();
					});
				</script>
				<section name="accnItemsSection" class="row border rounded mx-0 my-2" title="Collection Objects in this Accession">
					<div class="col-12 pt-3 pb-1">
						<input type="button" value="Add Items (Search &amp; Manage)" class="btn btn-xs btn-secondary mb-2 mb-sm-0 mr-2"
							onClick="window.open('/SpecimenSearch.cfm');">
						<input type="button" value="Review Items" class="btn btn-xs btn-secondary mb-2 mb-sm-0 mr-2"
							onClick="window.open('/SpecimenResults.cfm?accn_trans_id=#transaction_id#');">
						<input type="button" value="Refresh Item Count" class="btn btn-xs btn-info mb-2 mb-sm-0 mr-2"
							onClick=" updateItemSections(); ">
					</div>
					<div class="col-12 pt-2 pb-1">
						<div id="accnItemCountDiv"></div>
						<div id="accnItemDispositionsDiv"></div>
					</div>
				</section>
				<section role="search" aria-labelledby="guid_list_label" class="container my-3" title="Search for collection objects to add to this accession">
					<h2 class="h3">Add Cataloged Items to this Accession</h2>
						<div class="row border rounded mb-2 pb-2" >
							<form name="addCollObjectsAccn" id="addCollObjectsAccn" class="col-12">
							<input type="hidden" id="transaction_id" name="transaction_id" value="#transaction_id#" >
							<input type="hidden" id="method" name="method" value="addCollObjectsAccn" >
							<div class="form-row mx-0 my-2">
								<div class="col-12 col-md-10">
									<label for="guid_list" id="guid_list_label" class="data-entry-label">Cataloged items to move into to this accession (comma separated list of GUIDs in the form MCZ:Dept:number)</label>
									<input type="text" id="guid_list" name="guid_list" class="data-entry-input" 
											value="" placeholder="MCZ:Dept:1111,MCZ:Dept:1112" >
								</div>
								<script>
									function addCollectionObjects(){ 
										$('##addResultDiv').html("Saving.... ");
										jQuery.ajax({
											url : "/transactions/component/functions.cfc",
											type : "post",
											dataType : "json",
											data : $('##addCollObjectsAccn').serialize(),
											success : function (data) {
												updateItemSections();
												$('##addResultDiv').html("Added " + data[0].added);
											},
											error: function(jqXHR,textStatus,error){
												handleFail(jqXHR,textStatus,error,"adding item to accession");
												$('##addResultDiv').html("Error.");
											}
										});
									};
									$(document).ready( function() {
										$('##addCollObjectsAccn').on('submit', 
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
									updateAccnLimitations('#transaction_id#','accnLimitationsDiv');
								};
								$( document ).ready( function() { 
									loadTransactionFormPermits(#transaction_id#);
									updateAccnLimitations('#transaction_id#','accnLimitationsDiv');
								});
							</script>
								<h2 class="h3">Permissions and Rights documents (e.g. Permits):</h2>
								<p>List here all permissions and rights related documents associated with this accession including the deed of gift, collecting permits, CITES Permits, material transfer agreements, access benefit sharing agreements and other compliance or permit-like documents.  Permits (but not deeds of gift and some other document types) listed here are linked to all subsequent shipments of material from this accession.  <strong>If you aren't sure of whether a permit or permit-like document should be listed with a particular shipment for the accession or here under the accession, list it at least here.</strong>
								</p>
								<div id="transactionFormPermits" class="col-12 px-0 pb-1">Loading permits...</div>
								<div id='addPermit_#transaction_id#' class="col-12 px-0">
									<input type='button' 
										class="btn btn-xs btn-secondary mb-2 mb-sm-0 mr-2"
										onClick="openlinkpermitdialog('addPermitDlg_#transaction_id#','#transaction_id#','Accession: #accessionDetails.collection# #accessionDetails.accn_number#',reloadTransPermits);" 
										value='Add Permit to this Accession'>
								</div>
								<div id='addPermitDlg_#transaction_id#' class="my-2"></div>
						</section>
						<section name="mediaSection" class="row mx-0 border rounded bg-light my-2" title="Subsection: Media">
							<div class="col-12">
								<h2 class="h3">
									Media documenting this Accession
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
										media_relationship like '% accn' and
										related_primary_key=<cfqueryparam value="#transaction_id#" cfsqltype="CF_SQL_DECIMAL">
								</cfquery>
								<span>
									<cfset relation="documents accn">
									<input type='button' onClick="opencreatemediadialog('newMediaDlg_#transaction_id#','Accession: #accessionDetails.accn_number#','#transaction_id#','#relation#',reloadTransMedia);" value='Create Media' class='btn btn-xs btn-secondary' >
									&nbsp; 
									<span id='addMedia_#transaction_id#'>
										<input type='button' onClick="openlinkmediadialog('newMediaDlg_#transaction_id#','Accession: #accessionDetails.accn_number#','#transaction_id#','#relation#',reloadTransMedia);" value='Link Media' class='btn btn-xs btn-secondary' >
									&nbsp; 
									</span> 
								</span>
								<div id="addMediaDlg_#transaction_id#" class="my-2"></div>
								<div id="newMediaDlg_#transaction_id#" class="my-2"></div>
								<div id="transactionFormMedia" class="my-2"><img src='/shared/images/indicator.gif'> Loading Media....</div>
								<script>
									// callback for ajax methods to reload from dialog
									function reloadTransMedia() { 
										loadTransactionFormMedia(#transaction_id#,"accn");
										if ($("##addMediaDlg_#transaction_id#").hasClass('ui-dialog-content')) {
											$('##addMediaDlg_#transaction_id#').html('').dialog('destroy');
										}
									};
									$( document ).ready(loadTransactionFormMedia(#transaction_id#,"accn"));
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
						<section name="countriesOfOriginSection" class="row mx-0 border bg-light rounded mt-2" title="Subsection: Country of Origin">
							<div class="col-12 pb-3">
								<div id="countriesOfOriginDiv"></div>
							</div>
						</section>
						<section title="Loans of material in this accession" name="loansSection" class="row mx-0 mt-2" title="Subsection: Loan of Accession Material">
							<div class="col-12 border bg-light float-left px-3 pb-3 h-100 w-100 rounded">
								<h2 class="h3">Loans of material in this accession</h2>
								<div id="accnLoansDiv"></div>
							</div>
						</section>	
						<section title="Summary of Restrictions and Agreed Benefits" name="limitationsSection" class="row mx-0 mt-2">
							<div class="col-12 border bg-light float-left px-3 pb-3 h-100 w-100 rounded">
								<h2 class="h3">Summary of Restrictions and Agreed Benefits from Permissions &amp; Rights Documents</h2>
								<div id="accnLimitationsDiv"></div>
							</div>
						</section>	
						<section title="Projects" class="row mx-0 border rounded bg-light mt-2 mb-0 pb-2">
							<div class="col-12 pb-0 px-0">
								<h2 class="h3 px-3">
									Projects associated with this accession
									<i class="fas fas-info fa-info-circle" onClick="getMCZDocs('Project')" aria-label="help link for projects"></i>
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
									<button type="button" aria-label="Link this accession to an existing Project" id="linkProjectDialogLauncher"
											class="btn btn-xs btn-secondary mr-2" value="Link to Project"
											onClick=" openTransProjectLinkDialog(#transaction_id#, 'projectsLinkDialog','projectsDiv');">Link To Project</button>
									<button type="button" aria-label="Create a new Project linked to this accession" id="newProjectDialogLauncher"
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
<cfif Action is "deleAccn">
	<cftry>
		<cftransaction>
			<cfquery name="getAccnNum" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select accn_number from accn 
				where transaction_id = <cfqueryparam CFSQLType="CF_SQL_DECIMAL" value="#transaction_id#">
			</cfquery>
			<cfset deleteTarget = getAccnNum.accn_number>
			<cfquery name="killAccn" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				delete from accn 
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
				<h1 class="h2">Accession #deleteTarget# deleted.....</h1>
				<ul>
					<li><a href="/Transactions.cfm?action=findAccessions">Search for Accessions</a>.</li>
					<li><a href="/transactions/Accession.cfm?action=new">Create a New Accession</a>.</li>
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
					<p>You cannot delete an active accession. This accession probably has specimens or
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
<cfif action is "makeAccn">
	<cfoutput>
		<cfif not isDefined("date_entered") OR len(date_entered) is 0 >
			<cfset date_entered = dateformat(now(),"yyyy-mm-dd") >
		</cfif>
		<cfif
			( 
				not isDefined("collection_id") OR 
				not isDefined("accn_number") OR
				not isDefined("accn_status") OR
				not isDefined("received_date") OR
				not isDefined("nature_of_material")  OR
				not isDefined("accn_type") OR
				not isDefined("received_agent_id") 
			) OR (
				len(collection_id) is 0 OR 
				len(accn_number) is 0 OR
				len(accn_status) is 0 OR
				len(received_date) is 0 OR
				len(nature_of_material) is 0 OR
				len(accn_type) is 0 OR
				len(received_agent_id) is 0
			)
		>
			<h1 class="h2">One or more required fields are missing.</h1>
			<p>You must fill in Collection, Accn Number, Status, Date Received, Nature of Material, Received From, and Accn Type.</p>
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
					<cfqueryparam cfsqltype="CF_SQL_TIMESTAMP" value="#date_entered#">,
					0,
					'accn',
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
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value='#new_transaction_id#'>
					, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value='#accn_type#'>
					, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value='#accn_number#'>
					, <cfqueryparam cfsqltype="CF_SQL_TIMESTAMP" value='#dateformat(received_date,"yyyy-mm-dd")#'>
					, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value='#accn_status#'>
					<cfif len(estimated_count) gt 0>
						, <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value='#estimated_count#'>
					<cfelse>
						, null
					</cfif>
					)
			</cfquery>
			<cfif isdefined("for_use_by") and len(for_use_by) gt 0>
				<!--- support for radio button passing agent id for HMNH agents --->
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
			<cfif isdefined("in_house_contact_agent_id") and len(in_house_contact_agent_id) gt 0>
				<cfquery name="q_inhousecontact" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					INSERT INTO trans_agent (
						transaction_id,
						agent_id,
						trans_agent_role
					) values (
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#new_transaction_id#">,
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#in_house_contact_agent_id#">,
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
