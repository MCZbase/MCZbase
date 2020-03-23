<cfif not isdefined("action")> <cfset action="findAll"> </cfif>
<cfswitch expression="#action#">
	<cfcase value="findLoans">
		<cfset pageTitle = "Search Loans">
		<cfif isdefined("execute")> <cfset execute="loan"> </cfif>
	</cfcase>
	<cfdefaultcase>
		<cfset pageTitle = "Search Transactions">
		<cfif isdefined("execute")> <cfset execute="all"> </cfif>
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
<cfinclude template = "/includes/_header.cfm">

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

<cfoutput>

<!--- Search form --->
<div id="search-form-div" class="search-form-div pb-4 px-3">
	<div class="container-fluid">
		<div class="row">
			<div class="col-md-11 col-sm-12 col-lg-11">
				<h1 class="h3 smallcaps mt-4 pl-1">Search Transactions <span class="mt-2 font-italic pb-4 color-green fs-15 mx-0">(#getCount.cnt# records)</span></h1>
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
							<li class="nav-item col-sm-12 col-md-2 px-1">
								<a class="nav-link #allTabActive#" id="all-tab" data-toggle="tab" href="##transactionsTab" role="tab" aria-controls="All" aria-selected="true" >All</a>
							</li>
							<li class="nav-item col-sm-12 col-md-2 px-1">
								<a class="nav-link #loanTabActive#" id="loans-tab" data-toggle="tab" href="##loanTab" role="tab" aria-controls="Loans" aria-selected="false" >Loans</a>
							</li>
						</ul>
					</div><!--- End tab header div --->

					<!--- Tab content div --->
					<div class="tab-content pb-0" id="tabContentDiv">
						<!--- All Transactions search tab panel --->
						<div class="tab-pane fade #allTabShow# #allTabActive# py-0 mx-sm-3 mb-1" id="transactionsTab" role="tabpanel" aria-labelledby="all-tab">
							<h2 class="h3 card-title ml-2">Search All Transactions</h2>
							<form id="searchForm">
								<input  type="hidden" name="method" value="getTransactions">
								<div class="form-row mb-2">
									<div class="col-12 col-md-6">
										<label for="collection_id">Collection/Number (nnn, yyyy-n-Coll, Byyyy-n-Coll, Dyyyy-n-Coll):</label>
										<div class="input-group">
											<select name="collection_id" size="1" class="input-group-prepend form-control form-control-sm rounded ">
												<option value="-1">any collection</option>
												<cfloop query="ctcollection">
													<option value="#collection_id#">#collection#</option>
												</cfloop>
											</select>
											<cfif not isdefined("number")><cfset number=""></cfif>
											<input id="number" type="text" class="has-clear form-control form-control-sm rounded" name="number" placeholder="" value="#number#">
										</div>
									</div>
									<div class="col-12 col-md-6">
										<label for="status">Status:</label>
										<select name="status" id="status" class="custom-select1 form-control-sm" >
											<option value=""></option>
											<cfloop query="ctStatus">
												<option value="#ctStatus.status#">#ctStatus.status#</option>
											</cfloop>
										</select>
									</div>
								</div>
								<div class="form-row mb-2">
									<div class="col-12">
										<button class="btn btn-primary px-3" id="searchButton" type="submit" aria-label="Search all transactions">Search<span class="fa fa-search pl-1"></span></button>
											<button id="transcsvbutton" class="btn btn-secondary px-3" aria-label="Export results to csv" 
												onclick=" exportGridToCSV('searchResultsGrid', 'transaction_list.csv'); "
												disabled >Export to CSV</button>
										<button type="reset" class="btn btn-warning" aria-label="Clear transaction search form">Clear</button>
									</div>
								</div>
							</form>
						</div>

						<!--- Loan search tab panel --->
						<div class="tab-pane fade #loanTabShow# #loanTabActive# py-0 mx-sm-3 mb-1" id="loanTab" role="tabpanel" aria-labelledby="loans-tab">
     						<h2 class="wikilink">Find Loans <img src="/includes/images/info_i_2.gif" onClick="getMCZDocs('Loan_Transactions##Search_for_a_Loan')" class="likeLink" alt="[ help ]"></h2>

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

								<cfif not isdefined("loan_number")><cfset loan_number=""></cfif>
								<form id="loanSearchForm">
									<input type="hidden" name="method" value="getLoans">
									<input type="hidden" name="project_id" <cfif isdefined('project_id') AND project_id gt 0> value="#project_id#" </cfif>>
									<div class="form-row mb-2">
										<div class="col-12 col-md-3">
											<label for="collection_id">Collection Name:</label>
											<select name="collection_id" size="1" class="custom-select1 form-control-sm">
												<option value="-1">any collection</option>
												<cfloop query="ctcollection">
													<option value="#collection_id#">#collection#</option>
												</cfloop>
											</select>
										</div>
										<div class="col-12 col-md-3">
											<label for="loan_number">Number: (yyyy-n-Coll)</label>
											<input type="text" name="loan_number" id="loan_number" class="form-control-sm" value="#loan_number#">
										</div>
										<div class="col-12 col-md-3">
											<label for="loan_type">Type:</label>
											<select name="loan_type" id="loan_type" class="custom-select1 form-control-sm">
												<option value=""></option>
												<cfloop query="ctLoanType">
													<option value="#ctLoanType.loan_type#">#ctLoanType.loan_type#</option>
												</cfloop>
											</select>
										</div>
										<div class="col-12 col-md-3">
											<label for="loan_status">Status:</label>
											<select name="loan_status" id="loan_status" class="custom-select1 form-control-sm" >
												<option value=""></option>
												<cfloop query="ctLoanStatus">
													<option value="#ctLoanStatus.loan_status#">#ctLoanStatus.loan_status#</option>
												</cfloop>
												<option value="not closed">not closed</option>
											</select>
										</div>
									</div>
									<div class="form-row mb-2">
										<div class="col-12 col-md-4">
											<div class="input-group">
												<select name="trans_agent_role_1" id="trans_agent_role_1" class="form-control form-control-sm input-group-prepend">
													<option value="">agent role...</option>
													<cfloop query="cttrans_agent_role_loan">
														<option value="#trans_agent_role#">#trans_agent_role#:</option>
													</cfloop>
												</select>
												<input type="text" name="agent_1" id="agent_1" class="form-control form-control-sm" >
												<input type="hidden" name="agent_1_id" id="agent_1_id" >
											</div>
										</div>
										<div class="col-12 col-md-4">
											<div class="input-group">
												<select name="trans_agent_role_2" id="trans_agent_role_2" class="form-control form-control-sm input-group-prepend">
													<option value="">agent role...</option>
													<cfloop query="cttrans_agent_role_loan">
														<option value="#trans_agent_role#">#trans_agent_role#:</option>
													</cfloop>
												</select>
												<input type="text" name="agent_2" id="agent_2" class="form-control form-control-sm" >
												<input type="hidden" name="agent_2_id" id="agent_2_id" >
											</div>
										</div>
										<div class="col-12 col-md-4">
											<div class="input-group">
												<select name="trans_agent_role_3" id="trans_agent_role_3" class="form-control form-control-sm input-group-prepend">
													<option value="">agent role...</option>
													<cfloop query="cttrans_agent_role_loan">
														<option value="#trans_agent_role#">#trans_agent_role#:</option>
													</cfloop>
												</select>
												<input type="text" name="agent_3" id="agent_3" class="form-control form-control-sm" >
												<input type="hidden" name="agent_3_id" id="agent_3_id" >
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
									<div class="form-row mb-2">
										<div class="col-12 col-md-6">
											<div class="form-row">
												<div class="col-md-2 col-12 float-right">
													<label for"trans_date">Loan Date:</label>
												</div>
												<div class="col-md-5 col-12 float-left">
													<input name="trans_date" id="trans_date" type="text" class="jqxdatetimeinput float-right" >
												</div>
												<div class="col-md-5 col-12 float-left">
													<div class="input-group float-left">
														<div class="input-group-prepend" id="trans_date_to_marker" >To:</div>
														<input type='text' name='to_trans_date' id="to_trans_date" class="jqxdatetimeinput" aria-label="loan date search range to" aria-described="rans_date_to_marker">
													</div>
												</div>
											</div>
										</div>
										<div class="col-12 col-md-6">
											<div class="form-row">
												<div class="col-md-2 col-12 float-right">
													<label for="return_due_date"> Due Date: </label>
												</div>
												<div class="col-md-5 col-12 float-left">
													<input type="text" name="return_due_date" id="return_due_date" class="jqxdatetimeinput float-right">
												</div>
												<div class="col-md-5 col-12 float-left">
													<div class="input-group float-left">
														<div id="return_due_date_to_marker" class="input-group-prepend">To:</div>
														<input type='text' name='to_return_due_date' id="to_return_due_date" class="jqxdatetimeinput" aria-label="due date search range to" aria-described-by="return_due_date_to_marker">
													</div>
												</div>
											</div>
										</div>
									</div>
									<div class="form-row mb-2">
										<div class="col-12 col-md-6">
											<div class="form-row">
												<div class="col-md-2 col-12 float-right">
													<label for="closed_date"> Closed Date: </label>
												</div>
												<div class="col-md-5 col-12 float-left">
													<input type="text" name="closed_date" id="closed_date" class="jqxdatetimeinput float-right">
												</div>
												<div class="col-md-5 col-12 float-left">
													<div class="input-group float-left">
														<div id="closed_date_to_marker" class="input-group-prepend">To:</div>
														<input type='text' name='to_closed_date' id="to_closed_date" class="jqxdatetimeinput" aria-label="closed date search range to" aria-described-by="closed_date_to_marker">
													</div>
												</div>
											</div>
										</div>
										<div class="col-12 col-md-6">
											<div class="form-row mb-2">
												<div class="col-12 col-md-3">
													<label for="permit_num">Permit Number:</label>
												</div>
												<div class="col-12 col-md-9">
													<div class="input-group float-left">
														<input type="text" name="permit_num" id="permit_num" class="form-control py-0 h-auto" aria-described-by="permitNumberLabel">
														<!--- TODO: move backing into transactions/ change from popup window. --->
														<div class="input-group-append">
															<span class="input-group-text py-0" onclick="getHelp('get_permit_number');" aria-label="Pick a Permit">Pick</span>
														</div>
													</div>
												</div>
											</div>
										</div>
									</div>
									<div class="form-row mb-2">
										<div class="col-12 col-md-3">
											<label for="">Nature of Material:</label>
											<input type="text" name="nature_of_material" class="form-control-sm">
										</div>
										<div class="col-12 col-md-3">
											<label for="">Description: </label>
											<input type="text" name="loan_description" class="form-control-sm">
										</div>
										<div class="col-12 col-md-3">
											<label for="">Instructions:</label>
											<input type="text" name="loan_instructions" class="form-control-sm">
										</div>
										<div class="col-12 col-md-3">
											<label for="">Internal Remarks: </label>
											<input type="text" name="trans_remarks" class="form-control-sm">
										</div>
									</div>
									<div class="form-row mb-2 border border-secondary pb-2">
										<div class="col-12 col-md-3">
											<label for="part_name_oper">Part Match</label>
											<select id="part_name_oper" name="part_name_oper" class="form-control-sm custom-select1">
												<option value="is">is</option>
												<option value="contains">contains</option>
											</select>
										</div>
										<div class="col-12 col-md-3">
											<label for="part_name">Part Name</label>
											<input type="text" id="part_name" name="part_name" class="form-control-sm">
										</div>
										<div class="col-12 col-md-3">
											<label for="part_disp_oper">Disposition Match</label>
											<select id="part_disp_oper" name="part_disp_oper" class="form-control-sm custom-select1">
												<option value="is">is</option>
												<option value="isnot">is not</option>
											</select>
										</div>
										<div class="col-12 col-md-3">
											<label for="coll_obj_disposition">Part Disposition</label>
											<div name="coll_obj_disposition" id="coll_obj_disposition"></div>
											<script>
												$(document).ready(function () {
													var dispositionsource = [
														""
														<cfloop query="ctCollObjDisp">
															,"#ctCollObjDisp.coll_obj_disposition#"
														</cfloop>
													];
													$("##coll_obj_disposition").jqxComboBox({ source: dispositionsource, selectedIndex: 0, multiSelect: true });
												});
											</script>
										</div>
									</div>
									<div class="form-row mb-2">
										<div class="col-12">
											<button class="btn btn-primary px-3" id="loanSearchButton" type="submit" aria-label="Search loans">Search<span class="fa fa-search pl-1"></span></button>
											<button id="loancsvbutton" class="btn btn-secondary px-3" aria-label="Export results to csv" 
												onclick=" exportGridToCSV('searchResultsGrid', 'loan_list.csv'); "
												disabled >Export to CSV</button>
											<button type="reset" class="btn btn-warning" aria-label="Clear loan search form">Clear</button>
										</div>
									</div>
								</form>
							</div>
						</div> <!---tab-pane loan search--->

					</div> <!--- End tab-content div --->

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
					<div class="row mt-1">
						<span id="resultCount"></span>
						<span id="resultLink"></span>
					</div>
					<div class="row mt-1">
						<div id="searchText"></div>
						<!--Grid Related code is below along with search handlers-->
						<div id="searchResultsGrid" class="jqxGrid"></div>
						<div class="mt-005" id="enableselection"></div>
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
	$(".jqxdatetimeinput").jqxDateTimeInput({ value: null, height: '25px', theme: 'summer', min: new Date(1700,0,1) });

	/* Setup jqxgrid for Transactions Search */
	$('##searchForm').bind('submit', function(evt){
		evt.preventDefault();

		$("##searchResultsGrid").replaceWith('<div id="searchResultsGrid" class="jqxGrid"></div>');
		$('##loancsvbutton').prop('disabled',true);
		$('##transcsvbutton').prop('disabled',true);
		$('##resultCount').html('');
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
			autoshowfiltericon: false,
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
				{text: 'Nature of Material', datafield: 'nature_of_material', width: 130, hideable:true, hidden: false },
				{text: 'Remarks', datafield: 'trans_remarks', hideable: true, hidden: false }
			]
		});
		$("##searchResultsGrid").on("bindingcomplete", function(event) {
				$('##loancsvbutton').prop('disabled',true);
				$('##transcsvbutton').prop('disabled',false);
				var datainformation = $('##searchResultsGrid').jqxGrid('getdatainformation');
				var rowcount = datainformation.rowscount;
				$('##resultCount').html('Found ' + rowcount + ' transactions');
			}
		);
	});

	/* Setup jqxgrid for Loan Search */
	$('##loanSearchForm').bind('submit', function(evt){
		evt.preventDefault();

		$("##searchResultsGrid").replaceWith('<div id="searchResultsGrid" class="jqxGrid"></div>');
		$('##loancsvbutton').prop('disabled',true);
		$('##transcsvbutton').prop('disabled',true);
		$('##resultCount').html('');
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
			autoshowfiltericon: false,
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
				{text: 'Nature of Material', datafield: 'nature_of_material', hideable: true, hidden: false },
				{text: 'Transaction ID', datafield: 'transaction_id', hideable: true, hidden: true }
			]
		});
		$("##searchResultsGrid").on("bindingcomplete", function(event) {
				$('##loancsvbutton').prop('disabled',false);
				$('##transcsvbutton').prop('disabled',true);
				var datainformation = $('##searchResultsGrid').jqxGrid('getdatainformation');
				var rowcount = datainformation.rowscount;
				$('##resultCount').html('Found ' + rowcount + ' loans');
				$('##resultLink').html('<a href="/Transactions.cfm?action=findLoans&execute=true&' + $('##loanSearchForm').serialize() + '>Link to this search</a>');
			}
		);

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
	</cfif>

});
</script>

</cfoutput>
<cfinclude template="/includes/_footer.cfm">
