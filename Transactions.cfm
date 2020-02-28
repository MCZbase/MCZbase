<cfset pageTitle = "Search Transactions">
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

					<!--- Search Form, tab header div then tab contents div --->
					<div class="card-header tab-card-header pb-0 w-100">
						<ul class="nav nav-tabs card-header-tabs pt-1" id="myTab" role="tablist">
							<li class="nav-item col-sm-12 col-md-2 px-1"> <a class="nav-link active" id="one-tab" data-toggle="tab" href="##one" role="tab" aria-controls="One" aria-selected="true" >All</a> </li>
						</ul>
					</div>
					<div class="tab-content pb-0" id="myTabContent">
						<div class="tab-pane fade show active py-3 mx-sm-3 mb-3" id="one" role="tabpanel" aria-labelledby="one-tab">
							<h2 class="h3 card-title ml-2">Search All Transactions</h2>
							<form id="searchForm">

								<div class="col-xs-12 col-sm-12 col-md-12 col-lg-8 col-xs-offset-2">
									<div class="input-group">

										<select name="collection_id" size="1">
											<option value=""></option>
											<cfloop query="ctcollection">
												<option value="#collection_id#">#collection#</option>
											</cfloop>
										</select>
									   <cfif not isdefined("number")><cfset number=""></cfif>
										<input id="number" type="text" class="has-clear form-control w-50 form-control-borderless rounded" name="number" placeholder="" value="#number#">
										<span class="input-group-btn">
											<button class="btn button px-3 border-0" id="searchButton" type="submit">Search</button>
										</span>
									</div>
								</div>

							</form>
						</div>
					</div>

					<!--- Additional tabs with tab header then tab contents go here --->

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
				<div id="jqxWidget">
					<div class="pl-2 mb-5">
						<div class="row mt-4">
								<div id="messageDiv"></div>
								<div id="searchText"></div>
								<!--Grid Related code is below along with search handler for keyword search-->
								<div id="searchResultsGrid" class="jqxGrid"></div>
							<div class="mt-005" id="enableselection"></div>
						</div>
					</div>
				</div>
			</main>
		</div>
	</div>
</div>

<script>

$(document).ready(function () {
	$(".jqxdatetimeinput").jqxDateTimeInput({ width: '250px', height: '25px', theme: 'summer' });
});

/* Supporting JQXGRID for Search */
$(document).ready(function() {

	$('##searchForm').bind('submit', function(evt){
		evt.preventDefault();

		var searchParam = $('##number').val();

		$('##searchText').jqxGrid('showloadelement');
		$("##searchResultsGrid").jqxGrid('clearfilters');
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
				{ name: 'status', type: 'string' }
			],
			updaterow: function (rowid, rowdata, commit) {
				commit(true);
			},
			root: 'transRecord',
			id: 'collection_object_id',
			url: '/transactions/component/search.cfc?method=getTransactions&number=' + searchParam,
			timeout: 3000,  // units not specified, miliseconds? 
			loadError: function(jqXHR, status, error) { 
				$( "##messageDiv" ).dialog({
					modal: true,
					title: "Error: " + status,
					buttons: {
						Ok: function() {
							$( this ).dialog( "close" );
						}
					}
				});
            var message = "";      
				if (error == 'timeout') { 
               message = ' Server took too long to respond.';
            } else { 
               message = jqXHR.responseText;
            }
				$( "##messageDiv" ).html(error + message);
			},
			async: true
		};

		var dataAdapter = new $.jqx.dataAdapter(search) 
;

		var editrow = -1;
		// grid rendering starts below

		$("##searchResultsGrid").jqxGrid({
			width: '100%',
			autoheight: 'true',
			source: dataAdapter,
			filterable: true,
			sortable: true,
			pageable: true,
			editable: true,
			pagesize: '50',
			showaggregates: true,
			columnsresize: true,
			autoshowfiltericon: false,
			autoshowcolumnsmenubutton: false,
			selectionmode: 'multiplecellsextended',
			columnsreorder: true,
			groupable: true,
			selectionmode: 'checkbox',
			altrows: true,
			showtoolbar: false,
			columns: [
				{text: 'transaction_id', datafield: 'transaction_id', width: 190},
				{text: 'Coll.', datafield: 'collection_cde', width: 50},
				{text: 'Transaction', datafield: 'transaction_type', width: 150},
				{text: 'Number', datafield: 'number', width: 130},
				{text: 'Date', datafield: 'trans_date', width: 50},
				{text: 'Type', datafield: 'type', width: 50},
				{text: 'Status', datafield: 'status', width: 130},
				{text: 'Nature of Material', datafield: 'nature_of_material', width: 130 },
				{text: 'Collection', datafield: 'collection', width: 130},
				{text: 'Remarks', datafield: 'trans_remarks' },
			]
		});
	});
});
</script>

</cfoutput>
<cfinclude template="/includes/_footer.cfm">
