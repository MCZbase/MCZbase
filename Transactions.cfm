<cfif not isdefined("action")>
	<cfset action="findAll">
</cfif>
<cfswitch expression="#action#">
	<cfcase value="findLoans">
	<cfset pageTitle = "Search Loans">
	<cfif isdefined("execute")>
		<cfset execute="loan">
	</cfif>
	</cfcase>
	<cfdefaultcase>
	<cfset pageTitle = "Search Transactions">
	<cfif isdefined("execute")>
		<cfset execute="all">
	</cfif>
	</cfdefaultcase>
</cfswitch>
<!--
Transactions.cfm

Copyright 2019 President and Fellows of Harvard College

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
<cfquery name="getCount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	SELECT count(transaction_id) as cnt FROM trans
</cfquery>
<cfquery name="ctSpecificType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select distinct specific_type from mczbase.transaction_view order by specific_type
</cfquery>
<cfquery name="ctType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select count(transaction_id), specific_type, transaction_type 
	from mczbase.transaction_view 
	group by specific_type, transaction_type
	order by specific_type
</cfquery>
<cfquery name="ctStatus" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select distinct status from mczbase.transaction_view order by status
</cfquery>
<cfquery name="ctLoanType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select loan_type from ctloan_type order by loan_type
</cfquery>
<cfquery name="ctLoanStatus" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select loan_status from ctloan_status order by loan_status
</cfquery>
<cfquery name="ctCollObjDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select coll_obj_disposition from ctcoll_obj_disp
</cfquery>
<cfquery name="ctcollection" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select * from collection order by collection
</cfquery>
<cfquery name="cttrans_agent_role" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select count(*) as cnt, ct.trans_agent_role 
	from cttrans_agent_role ct left join trans_agent on ct.trans_agent_role = trans_agent.trans_agent_role
	group by ct.trans_agent_role
	order by ct.trans_agent_role
</cfquery>
<cfset selectedCollection = ''>
<cfif isdefined("collection_id") and len(collection_id) gt 0>
	<cfquery name="lookupCollection" dbtype="query">
		select collection from ctcollection where collection_id = <cfqueryparam cfsqltype="CF_SQL_NUMBER" value="#collection_id#">
	</cfquery>
	<cfset selectedCollection = lookupCollection.collection >
</cfif>

<cfoutput> 
	<!--- ensure fields have empty values present if not defined. --->
	<cfif not isdefined("status")>
		<cfset status="">
	</cfif>
	<cfif not isdefined("loan_status")>
		<cfset loan_status="">
	</cfif>
	<cfif not isdefined("loan_type")>
		<cfset loan_type="">
	</cfif>
	<cfif not isdefined("nature_of_material")>
		<cfset nature_of_material="">
	</cfif>
	<cfif not isdefined("loan_description")>
		<cfset loan_description="">
	</cfif>
	<cfif not isdefined("loan_instructions")>
		<cfset loan_instructions="">
	</cfif>
	<cfif not isdefined("trans_remarks")>
		<cfset trans_remarks="">
	</cfif>
	<cfif not isdefined("trans_agent_role_1")>
		<cfset trans_agent_role_1="">
	</cfif>
	<cfif not isdefined("agent_1")>
		<cfset agent_1="">
	</cfif>
	<cfif not isdefined("agent_1_id")>
		<cfset agent_1_id="">
	</cfif>
	<cfif not isdefined("trans_agent_role_2")>
		<cfset trans_agent_role_2="">
	</cfif>
	<cfif not isdefined("agent_2")>
		<cfset agent_2="">
	</cfif>
	<cfif not isdefined("agent_2_id")>
		<cfset agent_2_id="">
	</cfif>
	<cfif not isdefined("trans_agent_role_3")>
		<cfset trans_agent_role_3="">
	</cfif>
	<cfif not isdefined("agent_3")>
		<cfset agent_3="">
	</cfif>
	<cfif not isdefined("agent_3_id")>
		<cfset agent_3_id="">
	</cfif>
	<cfif not isdefined("trans_date")>
		<cfset trans_date="">
	</cfif>
	<cfif not isdefined("to_trans_date")>
		<cfset to_trans_date="">
	</cfif>
	<cfif not isdefined("return_due_date")>
		<cfset return_due_date="">
	</cfif>
	<cfif not isdefined("to_return_due_date")>
		<cfset to_return_due_date="">
	</cfif>
	<cfif not isdefined("closed_date")>
		<cfset closed_date="">
	</cfif>
	<cfif not isdefined("to_closed_date")>
		<cfset to_closed_date="">
	</cfif>
	<cfif not isdefined("permit_id")>
		<cfset permit_id="">
	</cfif>
	<cfif not isdefined("permit_num")>
		<cfset permit_num="">
	</cfif>
	<cfif not isdefined("part_name_oper")>
		<cfset part_name_oper="is">
	</cfif>
	<cfif not isdefined("part_name")>
		<cfset part_name="">
	</cfif>
	<cfif not isdefined("part_disp_oper")>
		<cfset part_disp_oper="is">
	</cfif>
	<cfif not isdefined("coll_obj_disposition")>
		<cfset coll_obj_disposition="">
	</cfif>
	
	<!--- Search form --->
	<div id="search-form-div" class="search-form-div pb-4 px-3">
		<div class="container-fluid">
			<div class="row">
				<div class="col-md-11 col-sm-12 col-lg-11">
					<h1 class="h3 smallcaps mt-4 pl-1">Search Transactions <span class="count font-italic color-green mx-0"><small>(#getCount.cnt# records)</small></span></h1>
					<div class="tab-card-main mt-1 tab-card">
					
					<!--- Set Active Tab --->
					<cfswitch expression="#action#">
						<cfcase value="findLoans">
						<cfset allTabActive = "">
						<cfset loanTabActive = "active">
						<cfset allTabShow = "">
						<cfset loanTabShow = "show">
						</cfcase>
						<cfdefaultcase>
						<cfset allTabActive = "active">
						<cfset loanTabActive = "">
						<cfset allTabShow = "show">
						<cfset loanTabShow = "">
						</cfdefaultcase>
					</cfswitch>
					
					<!--- Tab header div --->
					<div class="card-header tab-card-header pb-0 w-100">
						<ul class="nav nav-tabs card-header-tabs pt-1" id="tabHeaders" role="tablist">
							<li class="nav-item col-sm-12 col-md-2 px-1"> <a class="nav-link #allTabActive#" id="all-tab" data-toggle="tab" href="##transactionsTab" role="tab" aria-controls="All" aria-selected="true" >All</a> </li>
							<li class="nav-item col-sm-12 col-md-2 px-1"> <a class="nav-link #loanTabActive#" id="loans-tab" data-toggle="tab" href="##loanTab" role="tab" aria-controls="Loans" aria-selected="false" >Loans</a> </li>
						</ul>
					</div>
					<!--- End tab header div ---> 
					
					<!--- Tab content div --->
					<div class="tab-content pb-0" id="tabContentDiv">
					<!--- All Transactions search tab panel --->
					<div class="tab-pane fade #allTabShow# #allTabActive# py-0 mx-sm-3 mb-1" id="transactionsTab" role="tabpanel" aria-labelledby="all-tab">
						<h2 class="h3 card-title ml-2">Search All Transactions</h2>
						<form id="searchForm">
							<input  type="hidden" name="method" value="getTransactions" class="keeponclear">
							<div class="form-row mb-2">
								<div class="col-12 col-md-6">
									<label for="collection_id">Collection/Number (nnn, yyyy-n-Coll, Byyyy-n-Coll, Dyyyy-n-Coll):</label>
									<div class="input-group">
										<select name="collection_id" size="1" class="input-group-prepend form-control form-control-sm rounded ">
											<option value="-1">any collection</option>
											<cfloop query="ctcollection">
												<cfif ctcollection.collection eq selectedCollection>
													<cfset selected="selected">
													<cfelse>
													<cfset selected="">
												</cfif>
												<option value="#ctcollection.collection_id#" #selected#>#ctcollection.collection#</option>
											</cfloop>
										</select>
										<cfif not isdefined("number")>
											<cfset number="">
										</cfif>
										<input id="number" type="text" class="has-clear form-control form-control-sm rounded" name="number" placeholder="" value="#number#">
									</div>
								</div>
								<div class="col-12 col-md-6">
									<cfset pstatus = status>
									<!--- store a local variable as status may be CGI.status or VARIABLES.status --->
									<label for="status">Status:</label>
									<select name="status" id="status" class="custom-select1 form-control-sm" >
										<option value=""></option>
										<cfloop query="ctStatus">
											<cfif pstatus eq ctStatus.status>
												<cfset selected="selected">
												<cfelse>
												<cfset selected="">
											</cfif>
											<option value="#ctStatus.status#" #selected# >#ctStatus.status#</option>
										</cfloop>
									</select>
								</div>
							</div>
							<div class="form-row mb-2">
								<div class="col-12 col-md-4">
									<div class="input-group">
										<select name="trans_agent_role_1" id="all_trans_agent_role_1" class="form-control form-control-sm input-group-prepend">
											<option value="">agent role...</option>
											<cfloop query="cttrans_agent_role">
												<cfif len(trans_agent_role_1) gt 0 and trans_agent_role_1 EQ trans_agent_role >
													<cfset selected="selected">
													<cfelse>
													<cfset selected="">
												</cfif>
												<option value="#trans_agent_role#" #selected#>#trans_agent_role# (#cnt#):</option>
											</cfloop>
										</select>
										<input type="text" name="agent_1" id="all_agent_1" class="form-control form-control-sm" value="#agent_1#" >
										<input type="hidden" name="agent_1_id" id="all_agent_1_id" value="#agent_1_id#" >
									</div>
								</div>
								<div class="col-12 col-md-4">
									<div class="input-group">
										<select name="trans_agent_role_2" id="all_trans_agent_role_2" class="form-control form-control-sm input-group-prepend">
											<option value="">agent role...</option>
											<cfloop query="cttrans_agent_role">
												<cfif len(trans_agent_role_2) gt 0 and trans_agent_role_2 EQ trans_agent_role >
													<cfset selected="selected">
													<cfelse>
													<cfset selected="">
												</cfif>
												<option value="#trans_agent_role#" #selected#>#trans_agent_role# (#cnt#):</option>
											</cfloop>
										</select>
										<input type="text" name="agent_2" id="all_agent_2" class="form-control form-control-sm" value="#agent_2#" >
										<input type="hidden" name="agent_2_id" id="all_agent_2_id" value="#agent_2_id#" >
									</div>
								</div>
								<div class="col-12 col-md-4">
									<div class="input-group">
										<select name="trans_agent_role_3" id="all_trans_agent_role_3" class="form-control form-control-sm input-group-prepend">
											<option value="">agent role...</option>
											<cfloop query="cttrans_agent_role">
												<cfif len(trans_agent_role_3) gt 0 and trans_agent_role_3 EQ trans_agent_role >
													<cfset selected="selected">
													<cfelse>
													<cfset selected="">
												</cfif>
												<option value="#trans_agent_role#" #selected#>#trans_agent_role# (#cnt#):</option>
											</cfloop>
										</select>
										<input type="text" name="agent_3" id="all_agent_3" class="form-control form-control-sm" value="#agent_3#" >
										<input type="hidden" name="agent_3_id" id="all_agent_3_id" value="#agent_3_id#" >
									</div>
								</div>
								<script>
									$(document).ready(function() {
										$(makeAgentPicker('all_agent_1','all_agent_1_id'));
										$(makeAgentPicker('all_agent_2','all_agent_2_id'));
										$(makeAgentPicker('all_agent_3','all_agent_3_id'));
									});
									</script> 
							</div>
							<div class="form-row mb-2">
								<div class="col-12">
									<button class="btn btn-primary px-3" id="searchButton" type="submit" aria-label="Search all transactions">Search<span class="fa fa-search pl-1"></span></button>
									<button type="reset" class="btn btn-warning" aria-label="Reset transaction search form to inital values">Reset</button>
									<button type="button" class="btn btn-warning" aria-label="Start a new transaction search with a clear form" onclick="window.location.href='#Application.serverRootUrl#/Transactions.cfm?action=findAll';" >New Search</button>
								</div>
							</div>
						</form>
					</div>
					
					<!--- Loan search tab panel --->
					<div class="tab-pane fade #loanTabShow# #loanTabActive# py-0 mx-sm-3 mb-1 px-2 px-md-0" id="loanTab" role="tabpanel" aria-labelledby="loans-tab">
					<h2 class="wikilink pl-2 mb-0">Find Loans <img src="/shared/images/info_i_2.gif" onClick="getMCZDocs('Loan_Transactions##Search_for_a_Loan')" class="likeLink" alt="[ help ]"></h2>
					
					<!--- Search for just loans ---->
					<cfquery name="ctCollObjDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
									select coll_obj_disposition from ctcoll_obj_disp
								</cfquery>
					<cfquery name="cttrans_agent_role_loan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
									select distinct(trans_agent_role) 
									from cttrans_agent_role  
									where trans_agent_role != 'associated with agency' 
										and trans_agent_role != 'received from' 
										and trans_agent_role != 'borrow overseen by' 
									order by trans_agent_role
								</cfquery>
					<script>
									jQuery(document).ready(function() {
										jQuery("##part_name").autocomplete({
											source: function (request, response) { 
												$.ajax({
													url: "/specimens/component/functions.cfc",
													data: { term: request.term, method: 'getPartName' },
													dataType: 'json',
													success : function (data) { response(data); },
													error : function (jqXHR, status, error) {
														var message = "";      
														if (error == 'timeout') { 
															message = ' Server took too long to respond.';
														} else { 
															message = jqXHR.responseText;
														}
														messageDialog('Error:' + message ,'Error: ' + error);
													}
												})
											},
											select: function (event, result) {
												$('##part_name').val(result.item.id);
											},
											minLength: 1
										});
									});
								</script>
					<cfif not isdefined("loan_number")>
						<cfset loan_number="">
					</cfif>
					<form id="loanSearchForm">
						<input type="hidden" name="method" value="getLoans" class="keeponclear">
						<input type="hidden" name="project_id" <cfif isdefined('project_id') AND project_id gt 0> value="#project_id#" </cfif>>
						<div class="form-row mb-0 p-1">
							<div class="col-12 col-md-3">
								<label for="collection_id" class="data-entry-label mb-0">Collection Name:</label>
								<select name="collection_id" size="1" class="data-entry-select">
									<option value="-1">any collection</option>
									<cfloop query="ctcollection">
										<cfif ctcollection.collection eq selectedCollection>
											<cfset selected="selected">
											<cfelse>
											<cfset selected="">
										</cfif>
										<option value="#collection_id#" #selected#>#collection#</option>
									</cfloop>
								</select>
							</div>
							<div class="col-12 col-md-3">
								<label for="loan_number" class="data-entry-label mb-0">Number: (yyyy-n-Coll)</label>
								<input type="text" name="loan_number" id="loan_number" class="data-entry-input" value="#loan_number#">
							</div>
							<div class="col-12 col-md-3">
								<cfset ploan_type = loan_type>
								<label for="loan_type" class="data-entry-label mb-0">Type:</label>
								<select name="loan_type" id="loan_type" class="data-entry-select">
									<option value=""></option>
									<cfloop query="ctLoanType">
										<cfif ploan_type eq ctLoanType.loan_type>
											<cfset selected="selected">
											<cfelse>
											<cfset selected="">
										</cfif>
										<option value="#ctLoanType.loan_type#" #selected#>#ctLoanType.loan_type#</option>
									</cfloop>
								</select>
							</div>
							<div class="col-12 col-md-3">
								<cfset ploan_status = loan_status>
								<label for="loan_status" class="data-entry-label mb-0">Status:</label>
								<select name="loan_status" id="loan_status" class="data-entry-select" >
									<option value=""></option>
									<cfloop query="ctLoanStatus">
										<cfif ploan_status eq ctLoanStatus.loan_status>
											<cfset selected="selected">
											<cfelse>
											<cfset selected="">
										</cfif>
										<option value="#ctLoanStatus.loan_status#" #selected#>#ctLoanStatus.loan_status#</option>
									</cfloop>
									<option value="not closed">not closed</option>
								</select>
							</div>
						</div>
						<div class="form-row border rounded px-2 mb-2 mt-2 pt-1 pb-3 mx-1"> <span class="text-left mr-auto w-100 pl-2"><small>Loan Agents</small></span>
							<div class="col-12 col-md-4">
								<div class="input-group input-group-sm">
									<select name="trans_agent_role_1" id="trans_agent_role_1" class="data-entry-prepend-select col-md-6 input-group-prepend">
										<option value="">agent role...</option>
										<cfloop query="cttrans_agent_role_loan">
											<cfif len(trans_agent_role_1) gt 0 and trans_agent_role_1 EQ trans_agent_role >
												<cfset selected="selected">
												<cfelse>
												<cfset selected="">
											</cfif>
											<option value="#trans_agent_role#" #selected#>#trans_agent_role#:</option>
										</cfloop>
									</select>
									<input type="text" name="agent_1" id="agent_1" class="data-entry-select-input col-md-6" value="#agent_1#" >
									<input type="hidden" name="agent_1_id" id="agent_1_id" value="#agent_1_id#" >
								</div>
							</div>
							<div class="col-12 col-md-4">
								<div class="input-group input-group-sm">
									<select name="trans_agent_role_2" id="trans_agent_role_2" class="data-entry-prepend-select col-md-6 input-group-prepend">
										<option value="">agent role...</option>
										<cfloop query="cttrans_agent_role_loan">
											<cfif len(trans_agent_role_2) gt 0 and trans_agent_role_2 EQ trans_agent_role >
												<cfset selected="selected">
												<cfelse>
												<cfset selected="">
											</cfif>
											<option value="#trans_agent_role#" #selected#>#trans_agent_role#:</option>
										</cfloop>
									</select>
									<input type="text" name="agent_2" id="agent_2" class="data-entry-select-input col-md-6" value="#agent_2#" >
									<input type="hidden" name="agent_2_id" id="agent_2_id" value="#agent_2_id#" >
								</div>
							</div>
							<div class="col-12 col-md-4">
								<div class="input-group input-group-sm">
									<select name="trans_agent_role_3" id="trans_agent_role_3" class="data-entry-prepend-select col-md-6 input-group-prepend">
										<option value="">agent role...</option>
										<cfloop query="cttrans_agent_role_loan">
											<cfif len(trans_agent_role_3) gt 0 and trans_agent_role_3 EQ trans_agent_role >
												<cfset selected="selected">
												<cfelse>
												<cfset selected="">
											</cfif>
											<option value="#trans_agent_role#" #selected#>#trans_agent_role#:</option>
										</cfloop>
									</select>
									<input type="text" name="agent_3" id="agent_3" class="data-entry-select-input col-md-6" value="#agent_3#" >
									<input type="hidden" name="agent_3_id" id="agent_3_id" value="#agent_3_id#" >
								</div>
							</div>
							<script>
										$(document).ready(function() {
											$(makeAgentPicker('agent_1','agent_1_id'));
											$(makeAgentPicker('agent_2','agent_2_id'));
											$(makeAgentPicker('agent_3','agent_3_id'));
										});
										</script> 
						</div>
									
									
							<div class="col-12 col-md-12 col-xl-9">			
									
						<div class="container-fluid">
							<div class="row">
								<div class="col-sm"> 
									<div class='date form-row'>
										<label class="data-entry-label mb-0 " for="trans_date">Loan Date: (start)</label>
										<input name="trans_date" id="trans_date" type="text" class="datetimeinput data-entry-input col-10"  placeholder="start of range" value="#trans_date#">
										<label class="data-entry-label mb-0" for="to"></label>
										<input type='text' name='to_trans_date' id="to_trans_date" value="#to_trans_date#" class="datetimeinput data-entry-input col-10"  placeholder="start of range" aria-label="loan date search range to" aria-described="trans_date_to">
									</div>
								</div>
								<div class="col-sm"> 
									<div class='date form-row'>
									<label class="data-entry-label mb-0" for="return_due_date">Due Date:</label>
									<input name="return_due_date" id="return_due_date" type="text" placeholder="start of range" class="datetimeinput data-entry-input col-10">
									<label class="data-entry-label mb-0" for="to"></label>
									<input type='text' name='to_return_due_date' id="to_return_due_date" value="#to_return_due_date#" placeholder="end of range" class="datetimeinput data-entry-input col-10" aria-label="due date search range to" aria-described="return_due_date_to_marker">
									</div>
								</div>
								<div class="col-sm"> 
									<div class="date form-row">
									<label class="data-entry-label mb-0" for="closed_date">Close Date:</label>
									<input name="closed_date" id="closed_date" type="text" class="datetimeinput data-entry-input col-10"  placeholder="start of range" value="#closed_date#" > 
									<label class="data-entry-label mb-0" for="to_closed_date"> </label>
									<input type='text' name='to_closed_date' id="to_closed_date" value="#to_closed_date#" placeholder="end of range" class="datetimeinput data-entry-input col-10" aria-label="closed date search range to" aria-described="closed_date_to">
									</div>
								</div>
							</div>
						</div>
				<!---			<div class="form-row mb-0">
						<div class="col-12 col-md-12 col-xl-9 mb-1" style="border: 1px solid red;">
								<div class="row">
									<div class="col-lg-6 col-md-6 col-12">
										<div class='date'>
											<label class="data-entry-label mb-0 " for="trans_date">Loan Date: (start)</label>
											<input name="trans_date" id="trans_date" type="text" class="datetimeinput data-entry-input col-5" value="#trans_date#">
											<div class="input-group-append"> <span class="input-group-text" id="basic-addon2"></span> </div>
										</div>
										<div class='date'>
											<label class="data-entry-label mb-0" for="to"> (end date)</label>
											<input type='text' name='to_trans_date' id="to_trans_date" value="#to_trans_date#" class="datetimeinput data-entry-input col-5" aria-label="loan date search range to" aria-described="trans_date_to">
											<div class="input-group-append"> <span class="input-group-text" id="basic-addon2"></span> </div>
										</div>
									</div>
								</div>
							</div>
						</div>
						<div class='col-lg-2 col-md-6 col-12'>
							<div class="form-group">
								<div class='input-group date'>
									<label class="data-entry-label mb-0 ml-md-2" for="return_due_date">Due Date: (start)</label>
									<input name="return_due_date" id="return_due_date" type="text" class="datetimeinput data-entry-input col-10 ml-md-auto" value="#return_due_date#" >
								</div>
							</div>
						</div>
						<div class="col-lg-2 col-md-6 col-12">
							<div class="form-group">
								<div class='input-group date'>
									<label class="data-entry-label mb-0" for="to"> (end date)</label>
									<input type='text' name='to_return_due_date' id="to_return_due_date" value="#to_return_due_date#" class="datetimeinput data-entry-input col-10" aria-label="due date search range to" aria-described="return_due_date_to_marker">
								</div>
							</div>
						</div>
						<div class='col-lg-2 col-md-6 col-12'>
							<div class="form-group">
								<div class='input-group date'>
									<label class="data-entry-label mb-0 ml-xl-2" for="closed_date">Close Date: (start)</label>
									<input name="closed_date" id="closed_date" type="text" class="datetimeinput data-entry-input col-10 ml-md-auto" value="#closed_date#" >
								</div>
							</div>
						</div>
						<div class="col-lg-2 col-md-6 col-12">
							<div class="form-group">
								<div class='input-group date'>
									<label class="data-entry-label mb-0" for="to_closed_date"> (end date)</label>
									<input type='text' name='to_closed_date' id="to_closed_date" value="#to_closed_date#" class="datetimeinput data-entry-input col-10" aria-label="closed date search range to" aria-described="closed_date_to">
								</div>
							</div>
						</div>
						</div>
						</div>--->
						<div class="col-12 col-md-12 col-xl-3">
							<div class="form-row border rounded px-2 mt-1 py-3 mx-1">
								<div class="col-12 col-md-3">
									<label for="permit_num" class="data-entry-label mb-0 pt-0 mt-0">Permit Number:</label>
								</div>
								<div class="col-12 col-md-9">
									<div class="input-group float-left">
										<input type="hidden" name="permit_id" id="permit_id" value="#permit_id#">
										<input type="text" name="permit_num" id="permit_num" class="form-control py-0 h-auto" aria-described-by="permitNumberLabel" value="#permit_num#">
										
										<div class="input-group-append"> <span class="input-group-text py-0" onclick="getHelp('get_permit_number');" aria-label="Pick a Permit">Pick</span> </div>
									</div>
								</div>
							</div>
						</div>
						</div>
						<script>
										$(document).ready(function() {
											$(makePermitPicker('permit_num','permit_id'));
										});
									</script>
						<div class="form-row">
							<div class="col-12 col-md-6 px-2 m-0">
								<label for="nature_of_material" class="data-entry-label mb-0">Nature of Material:</label>
								<textarea class="data-entry-textarea" >#nature_of_material#</textarea>
							</div>
							<div class="col-12 col-md-6 px-2 m-0">
								<label for="loan_description" class="data-entry-label mb-0">Description: </label>
								<textarea class="data-entry-textarea">#loan_description#</textarea>
							</div>
							<div class="col-12 col-md-6 px-2 m-0">
								<label for="loan_instructions" class="data-entry-label mb-0">Instructions:</label>
								<textarea class="data-entry-textarea">#loan_instructions#</textarea>
							</div>
							<div class="col-12 col-md-6 px-2 m-0">
								<label for="trans_remarks" class="data-entry-label mb-0">Internal Remarks: </label>
								<textarea class="data-entry-textarea">#trans_remarks#</textarea>
							</div>
						</div>
						<div class="form-row border rounded pt-1 px-2 pb-3 my-3 mx-1 bg-light">
							<div class="col-12 col-md-3">
								<label for="part_name_oper" class="data-entry-label mb-0">Part Match</label>
								<cfif part_name_oper IS "is">
									<cfset isselect = "selected">
									<cfset containsselect = "">
									<cfelse>
									<cfset isselect = "">
									<cfset containsselect = "selected">
								</cfif>
								<select id="part_name_oper" name="part_name_oper" class="data-entry-select">
									<option value="is" #isselect#>is</option>
									<option value="contains" #containsselect#>contains</option>
								</select>
							</div>
							<div class="col-12 col-md-3">
								<label for="part_name" class="data-entry-label mb-0">Part Name</label>
								<input type="text" id="part_name" name="part_name" class="data-entry-input" value="#part_name#">
							</div>
							<div class="col-12 col-md-3">
								<label for="part_disp_oper" class="data-entry-label mb-0">Disposition Match</label>
								<cfif part_disp_oper IS "is">
									<cfset isselect = "selected">
									<cfset notselect = "">
									<cfelse>
									<cfset isselect = "">
									<cfset notselect = "selected">
								</cfif>
								<select id="part_disp_oper" name="part_disp_oper" class="data-entry-select">
									<option value="is" #isselect#>is</option>
									<option value="isnot" #notselect#>is not</option>
								</select>
							</div>
							<div class="col-12 col-md-3">
								<cfset coll_obj_disposition_array = ListToArray(coll_obj_disposition)>
								<label for="coll_obj_disposition" class="data-entry-label mb-0">Part Disposition</label>
								<div name="coll_obj_disposition" id="coll_obj_disposition" class="w-100"></div>
								<script>
												function setDispositionValues() {
													$('##coll_obj_disposition').jqxComboBox('clearSelection');
													<cfloop query="ctCollObjDisp">
														<cfif ArrayContains(coll_obj_disposition_array, ctCollObjDisp.coll_obj_disposition)>
															$("##coll_obj_disposition").jqxComboBox("selectItem","#ctCollObjDisp.coll_obj_disposition#");
														</cfif>
													</cfloop>
												};
												$(document).ready(function () {
													var dispositionsource = [
														""
														<cfloop query="ctCollObjDisp">
															,"#ctCollObjDisp.coll_obj_disposition#"
														</cfloop>
													];
													$("##coll_obj_disposition").jqxComboBox({ source: dispositionsource, multiSelect: true });
													setDispositionValues();
												});
											</script> 
							</div>
						</div>
						<div class="form-row mb-4">
							<div class="col-12 text-center">
								<button class="btn btn-primary px-3" id="loanSearchButton" type="submit" aria-label="Search loans">Search<span class="fa fa-search pl-1"></span></button>
								<button type="reset" class="btn btn-warning" aria-label="Reset search form to inital values" onclick="setDispositionValues();">Reset</button>
								<button type="button" class="btn btn-warning" aria-label="Start a new loan search with a clear form" onclick="window.location.href='#Application.serverRootUrl#/Transactions.cfm?action=findLoans';" >New Search</button>
							</div>
						</div>
					</form>
				</div>
			</div>
			<!---tab-pane loan search---> 
			
		</div>
		<!--- End tab-content div ---> 
		
	</div>
	</div>
	</div>
	</div>
	</div>
	
	<!--- Results table as a jqxGrid. --->
	<div class="container-fluid">
		<div class="row">
			<div class="text-left col-md-12">
				<main role="main">
					<div class="pl-2 mb-5"> 
						
						<!--- TODO: Move border styling to mimic jqx-grid, jqx-widget-content without the side effects of those classes to css file using faux-jqxwidget-header class. [I don't know that this is needed.  I used bootstrap styles.MHK]--->
						<div class="row mt-1 mb-0 pb-0 jqx-widget-header border px-2">
							<h4>Results: </h4>
							<span class="d-block px-3 p-2" id="resultCount"></span> <span id="resultLink" class="d-block p-2"></span>
							<div id="columnPickDialog">
								<div id="columnPick" class="px-1"></div>
							</div>
							<div id="columnPickDialogButton"></div>
							<div id="resultDownloadButtonContainer"></div>
						</div>
						<div class="row mt-0">
							<div id="searchText"></div>
							<!--Grid Related code is below along with search handlers-->
							<div id="searchResultsGrid" class="jqxGrid"></div>
							<div id="enableselection"></div>
						</div>
					</div>
				</main>
			</div>
		</div>
	</div>
	<script>

function exportGridToCSV (idOfGrid, filename) {
	var exportHeader = true;
	var rows = null; // null for all rows
	var exportHiddenColumns = true;
	var csvStringData = $('##' + idOfGrid).jqxGrid('exportdata', 'csv',null,exportHeader,rows,exportHiddenColumns);
	exportToCSV(csvStringData, filename);	
};

function exportToCSV (csvStringData, filename) {
	var downloadLink = document.createElement("a");
	var csvblob = new Blob(["\ufeff", csvStringData]);
	var url = URL.createObjectURL(csvblob);
	downloadLink.href = url;
	downloadLink.download = filename;
	document.body.appendChild(downloadLink);
	downloadLink.click();
	document.body.removeChild(downloadLink);
}; 

$(document).ready(function() {
	/* Setup date time input controls */
	$(".datetimeinput").datepicker({ 
		defaultDate: null,
		changeMonth: true,
		changeYear: true,
		buttonImageOnly: true,
		buttonImage: "/shared/images/calendar_icon.png",
		showOn: "both"
	});

	/* Setup jqxgrid for Transactions Search */
	$('##searchForm').bind('submit', function(evt){
		evt.preventDefault();

		$("##searchResultsGrid").replaceWith('<div id="searchResultsGrid" class="jqxGrid"></div>');
		$('##resultCount').html('');
		$('##resultLink').html('');
		$('##searchText').jqxGrid('showloadelement');

		var search =
		{
			datatype: "json",
			datafields:
			[
				{ name: 'transaction_id', type: 'string' },
				{ name: 'trans_date', type: 'string' },
				{ name: 'transaction_type', type: 'string' },
				{ name: 'nature_of_material', type: 'string' },
				{ name: 'trans_remarks', type: 'string' },
				{ name: 'collection_cde', type: 'string' },
				{ name: 'collection', type: 'string' },
				{ name: 'number', type: 'string' },
				{ name: 'type', type: 'string' },
				{ name: 'status', type: 'string' },
				{ name: 'entered_by', type: 'string' },
				{ name: 'authorized_by', type: 'string' },
				{ name: 'received_by', type: 'string' },
				{ name: 'for_use_by', type: 'string' },
				{ name: 'inhouse_contact', type: 'string' },
				{ name: 'additional_inhouse_contact', type: 'string' },
				{ name: 'additional_outside_contact', type: 'string' },
				{ name: 'recipient_institution', type: 'string' },
				{ name: 'id_link', type: 'string' }
			],
			updaterow: function (rowid, rowdata, commit) {
				commit(true);
			},
			root: 'transRecord',
			id: 'transaction_id',
			url: '/transactions/component/search.cfc?' + $('##searchForm').serialize(),
			timeout: 30000,  // units not specified, miliseconds? 
			loadError: function(jqXHR, status, error) { 
            var message = "";      
				if (error == 'timeout') { 
               message = ' Server took too long to respond.';
            } else { 
               message = jqXHR.responseText;
            }
            messageDialog('Error:' + message ,'Error: ' + error);
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
		}

		$("##searchResultsGrid").jqxGrid({
			width: '100%',
			autoheight: 'true',
			source: dataAdapter,
			filterable: true,
			sortable: true,
			pageable: true,
			editable: false,
			pagesize: '50',
			pagesizeoptions: ['50','100'],
			showaggregates: true,
			columnsresize: true,
			autoshowfiltericon: true,
			autoshowcolumnsmenubutton: false,
			columnsreorder: true,
			groupable: true,
			selectionmode: 'none',
			altrows: true,
			showtoolbar: false,
			columns: [
				{text: 'Number', datafield: 'number', width:110, hideable: true, hidden: true },
				{text: 'Transaction', datafield: 'id_link', width: 110},
				{text: 'transactionID', datafield: 'transaction_id', width: 50, hideable: true, hidden: true },
				{text: 'Coll.', datafield: 'collection_cde', width: 50},
				{text: 'Collection', datafield: 'collection', width: 80, hideable: true, hidden: true },
				{text: 'Transaction', datafield: 'transaction_type', width: 150},
				{text: 'Type', datafield: 'type', width: 80},
				{text: 'Date', datafield: 'trans_date', width: 100},
				{text: 'Status', datafield: 'status', width: 100},
				{text: 'Entered By', datafield: 'entered_by', width: 80, hideable: true, hidden: false },
				{text: 'Authorized By', datafield: 'authorized_by', width: 80, hideable: true, hidden: true },
				{text: 'Received By', datafield: 'received_by', width: 80, hideable: true, hidden: true },
				{text: 'For Use By', datafield: 'for_use_by', width: 80, hideable: true, hidden: true },
				{text: 'In-house Contact', datafield: 'inhouse_contact', width: 80, hideable: true, hidden: true },
				{text: 'Additional In-house Contact', datafield: 'additional_inhouse_contact', width: 80, hideable: true, hidden: true },
				{text: 'Additional Outside Contact', datafield: 'additional_outside_contact', width: 80, hideable: true, hidden: true },
				{text: 'Recipient Institution', datafield: 'recipient_institution', width: 80, hideable: true, hidden: true },
				{text: 'Nature of Material', datafield: 'nature_of_material', width: 130, hideable:true, hidden: true },
				{text: 'Remarks', datafield: 'trans_remarks', hideable: true, hidden: false }
			],
			rowdetails: true,
			rowdetailstemplate: {
				rowdetails: "<div style='margin: 10px;'>Row Details</div>",
				rowdetailsheight:  1 // row details will be placed in popup dialog
			},
			initrowdetails: initRowDetails
		});
		$("##searchResultsGrid").on("bindingcomplete", function(event) {
			// add a link out to this search, serializing the form as http get parameters
			$('##resultLink').html('<a href="/Transactions.cfm?action=findAll&execute=true&' + $('##searchForm').serialize() + '">Link to this search</a>');
			gridLoaded('searchResultsGrid','transaction');
		});
		$('##searchResultsGrid').on('rowexpand', function (event) {
			//  Create a content div, add it to the detail row, and make it into a dialog.
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
	});
	/* End Setup jqxgrid for Transactions Search ******************************/


	/* Setup jqxgrid for Loan Search ******************************************/
	$('##loanSearchForm').bind('submit', function(evt){
		evt.preventDefault();

		$("##searchResultsGrid").replaceWith('<div id="searchResultsGrid" class="jqxGrid"></div>');
		$('##resultCount').html('');
		$('##resultLink').html('');
		$('##searchText').jqxGrid('showloadelement');

		var loanSearch =
		{
			datatype: "json",
			datafields:
			[
				{ name: 'transaction_id', type: 'string' },
				{ name: 'trans_date', type: 'string' },
				{ name: 'trans_remarks', type: 'string' },
				{ name: 'loan_number', type: 'string' },
				{ name: 'loan_type', type: 'string' },
				{ name: 'loan_type_scope', type: 'string' },
				{ name: 'loan_status', type: 'string' },
				{ name: 'nature_of_material', type: 'string' },
				{ name: 'loan_instructions', type: 'string' },
				{ name: 'loan_description', type: 'string' },
				{ name: 'collection', type: 'string' },
				{ name: 'collection_cde', type: 'string' },
				{ name: 'return_due_date', type: 'string' },
				{ name: 'dueindays', type: 'string' },
				{ name: 'closed_date', type: 'string' },
				{ name: 'auth_agent', type: 'string' },
				{ name: 'ent_agent', type: 'string' },
				{ name: 'rec_agent', type: 'string' },
				{ name: 'foruseby_agent', type: 'string' },
				{ name: 'inHouse_agent', type: 'string' },
				{ name: 'addInhouse_agent', type: 'string' },
				{ name: 'addOutside_agent', type: 'string' },
				{ name: 'recip_inst', type: 'string' },
				{ name: 'project_name', type: 'string' },
				{ name: 'pid', type: 'string' },
				{ name: 'id_link', type: 'string' }
			],
			updaterow: function (rowid, rowdata, commit) {
				commit(true);
			},
			root: 'transRecord',
			id: 'transaction_id',
			url: '/transactions/component/search.cfc?' + $('##loanSearchForm').serialize(),
			timeout: 30000,  // units not specified, miliseconds? 
			loadError: function(jqXHR, status, error) { 
            var message = "";      
				if (error == 'timeout') { 
               message = ' Server took too long to respond.';
            } else { 
               message = jqXHR.responseText;
            }
            messageDialog('Error:' + message ,'Error: ' + error);
			},
			async: true
		};
		var loanDataAdapter = new $.jqx.dataAdapter(loanSearch);
		var initRowDetails = function (index, parentElement, gridElement, datarecord) {
			// could create a dialog here, but need to locate it later to hide/show it on row details opening/closing and not destroy it.
			var details = $($(parentElement).children()[0]);
			details.html("<div id='rowDetailsTarget" + index + "'></div>");

			createRowDetailsDialog('searchResultsGrid','rowDetailsTarget',datarecord,index);
			// Workaround, expansion sits below row in zindex.
			var maxZIndex = getMaxZIndex();
			$(parentElement).css('z-index',maxZIndex - 1); // will sit just behind dialog
		}
		$("##searchResultsGrid").jqxGrid({
			width: '100%',
			autoheight: 'true',
			source: loanDataAdapter,
			filterable: true,
			sortable: true,
			pageable: true,
			editable: false,
			pagesize: '50',
			pagesizeoptions: ['50','100'],
			showaggregates: true,
			columnsresize: true,
			autoshowfiltericon: true,
			autoshowcolumnsmenubutton: false,
			columnsreorder: true,
			groupable: true,
			selectionmode: 'none',
			altrows: true,
			showtoolbar: false,
			columns: [
				{text: 'Loan Number', datafield: 'loan_number', width: 100, hideable: true, hidden: true },
				{text: 'Loan', datafield: 'id_link', width: 100},
				{text: 'Coll.', datafield: 'collection_cde', width: 50},
				{text: 'Collection', datafield: 'collection', hideable: true, hidden: true },
				{text: 'Type', datafield: 'loan_type', width: 100},
				{text: 'Status', datafield: 'loan_status', width: 100},
				{text: 'Date', datafield: 'trans_date', width: 100},
				{text: 'Due Date', datafield: 'return_due_date', width: 100},
				{text: 'Due in (days)', datafield: 'dueindays', hideable: true, hidden: true },
				{text: 'Closed', datafield: 'closed_date', width: 100},
				{text: 'To', datafield: 'rec_agent', width: 100},
				{text: 'Recipient', datafield: 'recip_inst', width: 100},
				{text: 'Authorized By', datafield: 'auth_agent', hideable: true, hidden: true },
				{text: 'For Use By', datafield: 'foruseby_agent', hideable: true, hidden: true },
				{text: 'In-house contact', datafield: 'inHouse_agent', hideable: true, hidden: true },
				{text: 'Additional in-house contact', datafield: 'addInhouse_agent', hideable: true, hidden: true },
				{text: 'Additional outside contact', datafield: 'addOutside_agent', hideable: true, hidden: true },
				{text: 'Entered By', datafield: 'ent_agent', width: 80},
				{text: 'Remarks', datafield: 'trans_remarks', hideable: true, hidden: true },
				{text: 'Scope', datafield: 'loan_type_scope', hideable: true, hidden: true },
				{text: 'Instructions', datafield: 'loan_instructions', hideable: true, hidden: true },
				{text: 'Description', datafield: 'loan_description', hideable: true, hidden: true },
				{text: 'Project', datafield: 'project_name', hideable: true, hidden: true },
				{text: 'Transaction ID', datafield: 'transaction_id', hideable: true, hidden: true },
				{text: 'Nature of Material', datafield: 'nature_of_material', hideable: true, hidden: false }
			],
			rowdetails: true,
			rowdetailstemplate: {
				rowdetails: "<div style='margin: 10px;'>Row Details</div>",
				rowdetailsheight: 1
			},
			initrowdetails: initRowDetails
		});
		$("##searchResultsGrid").on("bindingcomplete", function(event) {
			// add a link out to this search, serializing the form as http get parameters
			$('##resultLink').html('<a href="/Transactions.cfm?action=findLoans&execute=true&' + $('##loanSearchForm').serialize() + '">Link to this search</a>');
			gridLoaded('searchResultsGrid','loan');
		});
		$('##searchResultsGrid').on('rowexpand', function (event) {
			//  Create a content div, add it to the detail row, and make it into a dialog.
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

	});
	// If requested in uri, execute search immediately.
	<cfif isdefined("execute")>
		<cfswitch expression="#execute#">
			<cfcase value="loan">
				$('##loanSearchForm').submit();
			</cfcase>
			<cfcase value="all">
				$('##searchForm').submit();
			</cfcase>
		</cfswitch>
	</cfif>

});


function gridLoaded(gridId, searchType) { 
	var now = new Date();
	var nowstring = now.toISOString().replace(/[^0-9TZ]/g,'_');
	var filename = searchType + '_results_' + nowstring + '.csv';
	// display the number of rows found
	var datainformation = $('##' + gridId).jqxGrid('getdatainformation');
	var rowcount = datainformation.rowscount;
	if (rowcount == 1) {
		$('##resultCount').html('Found ' + rowcount + ' ' + searchType);
	} else { 
		$('##resultCount').html('Found ' + rowcount + ' ' + searchType + 's');
	}
	// set maximum page size
	if (rowcount > 100) { 
	   $('##' + gridId).jqxGrid({ pagesizeoptions: ['50', '100', rowcount]});
	} else if (rowcount > 50) { 
	   $('##' + gridId).jqxGrid({ pagesizeoptions: ['50', rowcount]});
	} else { 
	   $('##' + gridId).jqxGrid({ pageable: false });
	}
	// add a control to show/hide columns
	var columns = $('##' + gridId).jqxGrid('columns').records;
	var columnListSource = [];
	for (i = 0; i < columns.length; i++) {
		var text = columns[i].text;
		var datafield = columns[i].datafield;
		var hideable = columns[i].hideable;
		var hidden = columns[i].hidden;
		var show = ! hidden;
		if (hideable == true) { 
			var listRow = { label: text, value: datafield, checked: show };
			columnListSource.push(listRow);
		}
	} 
	$("##columnPick").jqxListBox({ source: columnListSource, autoHeight: true, width: '260px', checkboxes: true });
	$("##columnPick").on('checkChange', function (event) {
		$("##" + gridId).jqxGrid('beginupdate');
		if (event.args.checked) {
			$("##" + gridId).jqxGrid('showcolumn', event.args.value);
		} else {
			$("##" + gridId).jqxGrid('hidecolumn', event.args.value);
		}
		$("##" + gridId).jqxGrid('endupdate');
	});
	$("##columnPickDialog").dialog({ 
		height: 'auto', 
		title: 'Show/Hide Columns',
		autoOpen: false,  
		modal: true, 
		reszable: true, 
		buttons: { 
			Ok: function(){ $(this).dialog("close"); }
		},
		open: function (event, ui) { 
			var maxZIndex = getMaxZIndex();
			$('.ui-dialog').css({'z-index': maxZIndex + 2 });
			$('.ui-widget-overlay').css({'z-index': maxZIndex + 1 });
		} 
	});
	$("##columnPickDialogButton").html(
		"<button id='columnPickDialogOpener' onclick=\" $('##columnPickDialog').dialog('open'); \" class='btn btn-secondary px-3 py-1 my-1 mx-3' >Show/Hide Columns</button>"
	);
	// workaround for menu z-index being below grid cell z-index when grid is created by a loan search.
	// 600 is the z-index of the grid cells when created from the transaction search
	var maxZIndex = getMaxZIndex();
	$('.jqx-grid-cell').css({'z-index': maxZIndex + 1});
	$('.jqx-grid-group-cell').css({'z-index': maxZIndex + 1});
	$('##resultDownloadButtonContainer').html('<button id="loancsvbutton" class="btn btn-secondary px-3 py-1 my-1 mx-0" aria-label="Export results to csv" onclick=" exportGridToCSV(\'searchResultsGrid\', \''+filename+'\'); " >Export to CSV</button>');
}

</script> 
</cfoutput>
<cfinclude template="/shared/_footer.cfm">
