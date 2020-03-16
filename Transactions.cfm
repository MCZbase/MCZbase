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

					<!--- Tab header div --->
					<div class="card-header tab-card-header pb-0 w-100">
						<ul class="nav nav-tabs card-header-tabs pt-1" id="myTab" role="tablist">
							<li class="nav-item col-sm-12 col-md-2 px-1">
								<a class="nav-link active" id="one-tab" data-toggle="tab" href="##transactionsTab" role="tab" aria-controls="One" aria-selected="true" >All</a>
							</li>
							<li class="nav-item col-sm-12 col-md-2 px-1">
								<a class="nav-link active" id="one-tab" data-toggle="tab" href="##loanTab" role="tab" aria-controls="One" aria-selected="true" >Loans</a>
							</li>
						</ul>
					</div><!--- End tab header div --->

					<!--- Tab content div --->
					<div class="tab-content pb-0" id="tabContentDiv">
						<!--- All Transactions search tab panel --->
						<div class="tab-pane fade show active py-3 mx-sm-3 mb-3" id="transactionsTab" role="tabpanel" aria-labelledby="one-tab">
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

						<!--- Loan search tab panel --->
						<div class="tab-pane fade show py-3 mx-sm-3 mb-3" id="loanTab" role="tabpanel" aria-labelledby="one-tab">
     						<h2 class="wikilink">Find Loans <img src="/images/info_i_2.gif" onClick="getMCZDocs('Loan_Transactions##Search_for_a_Loan')" class="likeLink" alt="[ help ]"></h2>

					<!--- Search for just loans ---->
					<cfquery name="ctType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select loan_type from ctloan_type order by loan_type
					</cfquery>
					<cfquery name="ctStatus" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select loan_status from ctloan_status order by loan_status
					</cfquery>
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

      <form name="SpecData" action="transactions/Loan.cfm" method="post">
        <input type="hidden" name="Action" value="listLoans">
        <input type="hidden" name="project_id" <cfif isdefined('project_id') AND project_id gt 0> value="#project_id#" </cfif>>
        <table>
          <tr>
            <td align="right">Collection Name: </td>
            <td><select name="collection_id" size="1">
                <option value=""></option>
                <cfloop query="ctcollection">
                  <option value="#collection_id#">#collection#</option>
                </cfloop>
              </select>
              <img src="images/nada.gif" width="2" height="1"> Number: (yyyy-n-Coll) <span class="lnum">
              <input type="text" name="loan_number">
              </span></td>
          </tr>
          <tr>
            <td align="right"><select name="trans_agent_role_1">
                <option value="">Please choose an agent role...</option>
                <cfloop query="cttrans_agent_role_loan">
                  <option value="#trans_agent_role#">-> #trans_agent_role#:</option>
                </cfloop>
              </select></td>
            <td><input type="text" name="agent_1"  size="50"></td>
          </tr>
          <tr>
            <td align="right"><select name="trans_agent_role_2">
                <option value="">Please choose an agent role...</option>
                <cfloop query="cttrans_agent_role_loan">
                  <option value="#trans_agent_role#">-> #trans_agent_role#:</option>
                </cfloop>
              </select></td>
            <td><input type="text" name="agent_2"  size="50"></td>
          </tr>
          <tr>
            <td align="right"><select name="trans_agent_role_3">
                <option value="">Please choose an agent role...</option>
                <cfloop query="cttrans_agent_role_loan">
                  <option value="#trans_agent_role#">-> #trans_agent_role#:</option>
                </cfloop>
              </select></td>
            <td><input type="text" name="agent_3"  size="50"></td>
          </tr>
          <tr>
            <td align="right">Type: </td>
            <td><select name="loan_type">
                <option value=""></option>
                <cfloop query="ctLoanType">
                  <option value="#ctLoanType.loan_type#">#ctLoanType.loan_type#</option>
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
          <tr>
              <td align="right"> Due Date: </td>
              <td><input type="text" name="return_due_date" id="return_due_date">
               &nbsp; To:
                <input type='text' name='to_return_due_date' id="to_return_due_date"></td>
          </tr>
          <tr>
              <td align="right"> Closed Date: </td>
              <td><input type="text" name="closed_date" id="closed_date">
               &nbsp; To:
                <input type='text' name='to_closed_date' id="to_closed_date"></td>
          </tr>
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
				<div id="jqxWidget">
					<div class="pl-2 mb-5">
						<div class="row mt-4">
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
				{ name: 'status', type: 'string' },
				{ name: 'id_link', type: 'string' }
			],
			updaterow: function (rowid, rowdata, commit) {
				commit(true);
			},
			root: 'transRecord',
			id: 'collection_object_id',
			url: '/transactions/component/search.cfc?method=getTransactions&number=' + searchParam,
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
			editable: false,
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
				{text: 'Transaction', datafield: 'id_link', width: 190},
				{text: 'Coll.', datafield: 'collection_cde', width: 50},
				{text: 'Transaction', datafield: 'transaction_type', width: 150},
				{text: 'Number', datafield: 'number', width: 130},
				{text: 'Date', datafield: 'trans_date', width: 50},
				{text: 'Type', datafield: 'type', width: 50},
				{text: 'Status', datafield: 'status', width: 130},
				{text: 'Nature of Material', datafield: 'nature_of_material', width: 130 },
				{text: 'Collection', datafield: 'collection', width: 130},
				{text: 'Remarks', datafield: 'trans_remarks' }
			]
		});
	});
});
</script>

</cfoutput>
<cfinclude template="/includes/_footer.cfm">
