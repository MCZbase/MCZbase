<!--
transactions/reviewLoanItems.cfm

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
<cfset pageTitle="Review Loan Items">
<cfinclude template="/shared/_header.cfm">

<script type='text/javascript' src='/transactions/js/reviewLoanItems.js'></script>
<script type='text/javascript' src='/specimens/js/specimens.js'></script>

<cfquery name="ctDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select coll_obj_disposition from ctcoll_obj_disp
</cfquery>
<!--- set up a json source for a jqxDropDownList --->
<cfset ctDispSource = "[">
<cfset sep="">
<cfloop query="ctDisp">
	<cfset ctDispSource = "#ctDispSource##sep#'#ctDisp.coll_obj_disposition#'">
	<cfset sep=",">
</cfloop>
<cfset ctDispSource = "#ctDispSource#]">

<cfif not isdefined("transaction_id")>
	<cfthrow message="No transaction specified.">
</cfif>
<cfif not isdefined("action")><cfset action="nothing"></cfif>

<!-------------------------------------------------------------------------------->
<cfif #Action# is "delete">
	<cfoutput>
	<cfif isdefined("coll_obj_disposition") AND coll_obj_disposition is "on loan">
		<!--- see if it's a subsample --->
		<cfquery name="isSSP" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select SAMPLED_FROM_OBJ_ID from specimen_part where collection_object_id = #partID#
		</cfquery>
		<cfif #isSSP.SAMPLED_FROM_OBJ_ID# gt 0>
					You cannot remove this item from a loan while it's disposition is "on loan." 
			<br />Use the form below if you'd like to change the disposition and remove the item 
			from the loan, or to delete the item from the database completely.
			
			<form name="cC" method="post" action="a_loanItemReview.cfm">
				<input type="hidden" name="action" />
				<input type="hidden" name="transaction_id" value="#transaction_id#" />
				<input type="hidden" name="item_instructions" value="#item_instructions#" />
				<input type="hidden" name="loan_item_remarks" value="#loan_item_remarks#" />
				<input type="hidden" name="partID" value="#partID#" />
				<input type="hidden" name="spRedirAction" value="delete" />
				Change disposition to: <select name="coll_obj_disposition" size="1">
					<cfloop query="ctDisp">
						<option value="#coll_obj_disposition#">#ctDisp.coll_obj_disposition#</option>
					</cfloop>				
				</select>
				<p />
				<input type="button" 
					class="delBtn"
					onmouseover="this.className='delBtn btnhov'"
					onmouseout="this.className='delBtn'"
					value="Remove Item from Loan" 
					onclick="cC.action.value='saveDisp'; submit();" />
				
				<p /><input type="button" 
					class="delBtn"
					onmouseover="this.className='delBtn btnhov'"
					onmouseout="this.className='delBtn'"
					value="Delete Subsample From Database" 
					onclick="cC.action.value='killSS'; submit();"/>
					<p /><input type="button" 
					class="qutBtn"
					onmouseover="this.className='qutBtn btnhov'"
					onmouseout="this.className='qutBtn'"
					value="Discard Changes" 
					onclick="cC.action.value='nothing'; submit();"/>
			</form>
			<cfabort>
			<cfabort>
		<cfelse>
			You cannot remove this item from a loan while it's disposition is "on loan." 
			<br />Use the form below if you'd like to change the disposition and remove the item 
			from the loan.
			
			<form name="cC" method="post" action="a_loanItemReview.cfm">
				<input type="hidden" name="action" />
				<input type="hidden" name="transaction_id" value="#transaction_id#" />
				<input type="hidden" name="item_instructions" value="#item_instructions#" />
				<input type="hidden" name="loan_item_remarks" value="#loan_item_remarks#" />
				<input type="hidden" name="partID" id="partID" value="#partID#" />
				<input type="hidden" name="spRedirAction" value="delete" />
				<br />Change disposition to: <select name="coll_obj_disposition" size="1">
					<cfloop query="ctDisp">
						<option value="#coll_obj_disposition#">#ctDisp.coll_obj_disposition#</option>
					</cfloop>				
				</select>
				<br /><input type="button" 
					class="delBtn"
					onmouseover="this.className='delBtn btnhov'"
					onmouseout="this.className='delBtn'"
					value="Remove Item from Loan" 
					onclick="cC.action.value='saveDisp'; submit();" />
				<br /><input type="button" 
					class="qutBtn"
					onmouseover="this.className='qutBtn btnhov'"
					onmouseout="this.className='qutBtn'"
					value="Discard Changes" 
					onclick="cC.action.value='nothing'; submit();"/>
			</form>
			<cfabort>
		</cfif>
	</cfif>
	<cfquery name="deleLoanItem" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		DELETE FROM loan_item where collection_object_id = #partID#
		and transaction_id = #transaction_id#
	</cfquery>
		<cflocation url="/transactions/reviewLoanItems.cfm?transaction_id=#transaction_id#">
	</cfoutput>
</cfif>
<!-------------------------------------------------------------------------------->

<cfif #Action# is "killSS">
	<cfoutput>
<cftransaction>
	<cfquery name="deleLoan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		DELETE FROM loan_item WHERE collection_object_id = #partID#
		and transaction_id=#transaction_id#
	</cfquery>
	<cfquery name="delePart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		DELETE FROM specimen_part WHERE collection_object_id = #partID#
	</cfquery>
	<cfquery name="delePartCollObj" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		DELETE FROM coll_object WHERE collection_object_id = #partID#
	</cfquery>
	<cfquery name="delePartRemark" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		DELETE FROM coll_object_remark WHERE collection_object_id = #partID#
	</cfquery>
	<cfquery name="getContID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select container_id from coll_obj_cont_hist where
		collection_object_id = #partID#
	</cfquery>
	
	<cfquery name="deleCollCont" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		DELETE FROM coll_obj_cont_hist WHERE collection_object_id = #partID#
	</cfquery>
	<cfquery name="deleCont" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		DELETE FROM container_history WHERE container_id = #getContID.container_id#
	</cfquery>
	<cfquery name="deleCont" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		DELETE FROM container WHERE container_id = #getContID.container_id#
	</cfquery>
</cftransaction>
	<cflocation url="a_loanItemReview.cfm?transaction_id=#transaction_id#">
	</cfoutput>

</cfif>
<!-------------------------------------------------------------------------------->

<cfif #Action# is "BulkUpdateDisp">
	<cfoutput>
		<cfquery name="getCollObjId" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select collection_object_id FROM loan_item where transaction_id=#transaction_id#
		</cfquery>
		<cfloop query="getCollObjId">
			<cfquery name="upDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			UPDATE coll_object SET coll_obj_disposition = '#coll_obj_disposition#'
			where collection_object_id = #collection_object_id#
			</cfquery>
		</cfloop>
	<cflocation url="a_loanItemReview.cfm?transaction_id=#transaction_id#">
	</cfoutput>
</cfif>
<!-------------------------------------------------------------------------------->

<cfif #Action# is "BulkUpdatePres">
	<cfoutput>
		<cfquery name="getCollObjId" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select collection_object_id FROM loan_item where transaction_id=#transaction_id#
		</cfquery>
		<cfloop query="getCollObjId">
			<cfquery name="upDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			UPDATE specimen_part SET preserve_method  = '#part_preserve_method#'
			where collection_object_id = #collection_object_id#
			</cfquery>
		</cfloop>
	<cflocation url="a_loanItemReview.cfm?transaction_id=#transaction_id#">
	</cfoutput>
</cfif>
<!-------------------------------------------------------------------------------->

<cfif #Action# is "saveDisp">
	<cfoutput>
	<cftransaction>
		<cfquery name="upDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			UPDATE coll_object SET coll_obj_disposition = '#coll_obj_disposition#'
			where collection_object_id = #partID#
		</cfquery>
		<cfquery name="upItem" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			UPDATE loan_item SET
				 transaction_id=#transaction_id#
				<cfif len(#item_instructions#) gt 0>
					,item_instructions = '#item_instructions#'
				<cfelse>
					,item_instructions = null
				</cfif>
				<cfif len(#loan_item_remarks#) gt 0>
					,loan_item_remarks = '#loan_item_remarks#'
				<cfelse>
					,loan_item_remarks = null
				</cfif>
			WHERE
				collection_object_id = #partID# AND
				transaction_id=#transaction_id#
		</cfquery>
	</cftransaction>
	<cfif isdefined("spRedirAction") and len(#spRedirAction#) gt 0>
		<cfset action=#spRedirAction#>
	<cfelse>
		<cfset action="nothing">
	</cfif>
	<cflocation url="a_loanItemReview.cfm?transaction_id=#transaction_id#&item_instructions=#item_instructions#&partID=#partID#&loan_item_remarks=#loan_item_remarks#&action=#action#">
	</cfoutput>
</cfif>
<!-------------------------------------------------------------------------------->

<cfif #action# is "nothing">
	<cfquery name="getPartLoanRequests" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select 
			cat_num, 
			cataloged_item.collection_object_id,
			collection,
			collection.collection_cde,
			part_name,
			preserve_method,
			condition,
			sampled_from_obj_id,
			item_descr,
			item_instructions,
			loan_item_remarks,
			coll_obj_disposition,
			scientific_name,
			Encumbrance,
			agent_name,
			loan_number,
			specimen_part.collection_object_id as partID,
			concatSingleOtherId(cataloged_item.collection_object_id,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.CustomOtherIdentifier#">) AS CustomID		 			 
		from 
			loan_item, 
			loan,
			specimen_part, 
			coll_object,
			cataloged_item,
			coll_object_encumbrance,
			encumbrance,
			agent_name,
			identification,
			collection
		WHERE
			loan_item.collection_object_id = specimen_part.collection_object_id AND
			loan.transaction_id = loan_item.transaction_id AND
			specimen_part.derived_from_cat_item = cataloged_item.collection_object_id AND
			specimen_part.collection_object_id = coll_object.collection_object_id AND
			coll_object.collection_object_id = coll_object_encumbrance.collection_object_id (+) and
			coll_object_encumbrance.encumbrance_id = encumbrance.encumbrance_id (+) AND
			encumbrance.encumbering_agent_id = agent_name.agent_id (+) AND
			cataloged_item.collection_object_id = identification.collection_object_id AND
			identification.accepted_id_fg = 1 AND
			cataloged_item.collection_id=collection.collection_id AND
			loan_item.transaction_id = <cfqueryparam cfsqltype="cf_sql_number" value="#transaction_id#" >
		ORDER BY cat_num
	</cfquery>
	<cfquery name="ctSovereignNation" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		SELECT count(*) as ct, sovereign_nation
		FROM loan_item 
			left join specimen_part on loan_item.collection_object_id = specimen_part.collection_object_id
			left join cataloged_item on specimen_part.derived_from_cat_item = cataloged_item.collection_object_id
			left join collecting_event on cataloged_item.collecting_event_id = collecting_event.collecting_event_id
			left join locality on collecting_event.locality_id = locality.locality_id
		WHERE 
			loan_item.transaction_id = <cfqueryparam cfsqltype="cf_sql_number" value="#transaction_id#" >
		GROUP BY sovereign_nation
	</cfquery>
	<!--- Obtain list of preserve_method values for the collection that this loan is from --->
	<cfquery name="ctPreserveMethod" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select ct.preserve_method, c.collection_cde 
		from ctspecimen_preserv_method ct 
			left join collection c on ct.collection_cde = c.collection_cde
			left join trans t on c.collection_id = t.collection_id 
		where t.transaction_id = <cfqueryparam cfsqltype="cf_sql_number" value="#transaction_id#" >
	</cfquery>
	<!--- handle legacy loans with cataloged items as the item --->
	<main class="container-fluid" id="content">
		<cfoutput>
			<cfquery name="aboutLoan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select l.loan_number, c.collection_cde, c.collection,
					l.loan_type, l.loan_status, 
					l.return_due_date, l.closed_date
				from collection c 
					left join trans t on c.collection_id = t.collection_id 
					left join loan l on t.transaction_id = l.transaction_id
				where t.transaction_id = <cfqueryparam cfsqltype="cf_sql_number" value="#transaction_id#" >
			</cfquery>

			<!--- count cataloged items and parts in the loan --->
			<cfquery name="catCnt" dbtype="query">
				select count(distinct(collection_object_id)) c 
				from getPartLoanRequests
			</cfquery>
			<cfif catCnt.c eq ''>
				<cfset catCount = 'no'>
			<cfelse>
				<cfset catCount = catCnt.c>
			</cfif>
			<cfquery name="prtItemCnt" dbtype="query">
				select count(distinct(partID)) c 
				from getPartLoanRequests
			</cfquery>
			<cfif prtItemCnt.c eq ''>
				<cfset partCount = 'no'>
			<cfelse>
				<cfset partCount = prtItemCnt.c>
			</cfif>
			<section class="row border rounded my-2 pt-2" title="Review Loan Items" >
				<div class="col-12">
					<div class="container-fluid">
						<div class="row">
							<div class="col-12 mb-3">
								<div class="row mt-1 mb-0 pb-0 px-2 mx-0">
									<div class="col-12 col-xl-6">
										<h1 class="h3">
											Review items in loan
											<a href="/transactions/Loan.cfm?action=editLoan&transaction_id=#transaction_id#">#encodeForHtml(aboutLoan.loan_number)#</a>.
											<p class="font-weight-normal pb-2">There are #partCount# items from #catCount# specimens in this loan.</p>
										</h1>
										<h2 class="h4 d-inline font-weight-normal">Type: <span class="font-weight-lessbold">#aboutLoan.loan_type#</span> </h2>
										<h2 class="h4 d-inline font-weight-normal"> &bull; Status: <span class="font-weight-lessbold">#aboutLoan.loan_status#</span> </h2>
										<h2 class="h4 d-inline font-weight-normal"><cfif aboutLoan.return_due_date NEQ ''> &bull; Due Date: <span class="font-weight-lessbold">#dateFormat(aboutLoan.return_due_date,'yyyy-mm-dd')#</span></cfif></h2>
										<h2 class="h4 d-inline font-weight-normal"><cfif aboutLoan.closed_date NEQ ''> &bull; Closed Date: <span class="font-weight-lessbold">#dateFormat(aboutLoan.closed_date,'yyyy-mm-dd')#</span> </cfif></h2>
									</div>
									<div class="col-12 col-xl-6 pt-3">
										<h3 class="h4">Countries of Origin</h3>
										<cfset sep="">
										<cfloop query=ctSovereignNation>
											<cfif len(sovereign_nation) eq 0><cfset sovereign_nation = '[no value set]'></cfif>
											<span>#sep##encodeforHtml(sovereign_nation)#&nbsp;(#ct#)</span>
											<cfset sep="; ">
										</cfloop>
									</div>
								</div>
								<div class="row mb-0 pb-0 px-2 mx-0">
									<div class="col-12 col-xl-6">
										<form name="BulkUpdateDisp" method="post" action="a_loanItemReview.cfm">
										<br>Change disposition of all these items to:
										<input type="hidden" name="Action" value="BulkUpdateDisp">
											<input type="hidden" name="transaction_id" value="#transaction_id#" id="transaction_id">
											<select name="coll_obj_disposition" class="data-entry-select col-3 d-inline" size="1">
												<cfloop query="ctDisp">
													<option value="#coll_obj_disposition#">#ctDisp.coll_obj_disposition#</option>
												</cfloop>				
											</select>
											<input type="submit" value="Update Dispositions" class="btn btn-xs btn-primary" >
										</form>
										<cfif aboutLoan.collection EQ 'Cryogenic'>
												<form name="BulkUpdatePres" method="post" action="a_loanItemReview.cfm">
													<br>Change preservation method of all these items to:
													<input type="hidden" name="Action" value="BulkUpdatePres">
													<input type="hidden" name="transaction_id" value="#transaction_id#" id="transaction_id">
													<select name="part_preserve_method" class="data-entry-select col-3 d-inline" size="1">
														<cfloop query="ctPreserveMethod">
															<option value="#ctPreserveMethod.preserve_method#">#ctPreserveMethod.preserve_method#</option>
														</cfloop>				
													</select>
													<input type="submit" value="Update Preservation methods" class="btn btn-xs btn-primary"> 
												</form>
										</cfif>
									</div>
									<div class="col-12 col-xl-6">
											<div class="my-2 py-1">View 
											<a href="/findContainer.cfm?loan_trans_id=#transaction_id#">Part Locations</a>
											or <a href="/loanFreezerLocn.cfm?transaction_id=#transaction_id#">Print Freezer Locations</a></div>
									</div>
								</div>
								</div>
						</div>
					</div>
				</div>
				<div class="col-12">
					<div class="container-fluid">
						<div class="row">
							<div class="col-12 mb-3">
								<div class="row mt-1 mb-0 pb-0 jqx-widget-header border px-2 mx-0">
								<h1 class="h4">Loan Items <span class="px-1 font-weight-normal text-success" id="resultCount" tabindex="0"><a class="messageResults" tabindex="0" aria-label="search results"></a></span> </h1><span id="resultLink" class="d-inline-block px-1 pt-2"></span>
									<div id="columnPickDialog">
										<div class="container-fluid">
											<div class="row">
												<div class="col-12 col-md-6">
													<div id="columnPick" class="px-1"></div>
												</div>
												<div class="col-12 col-md-6">
													<div id="columnPick1" class="px-1"></div>
												</div>
											</div>
										</div>
									</div>
									<div id="columnPickDialogButton"></div>
									<div id="resultDownloadButtonContainer"></div>
								</div>
								<div class="row mt-0 mx-0">
									<!--- Grid Related code is below along with search handlers --->
									<div id="searchResultsGrid" class="jqxGrid" role="table" aria-label="Search Results Table"></div>
									<div id="enableselection"></div>
								</div>
							</div>
						</div>
					</div>
					<div id="itemConditionHistoryDialog"></div>
					<cfset cellRenderClasses = "ml-1"><!--- for cell renderers to match default --->
					<script>
						function removeLoanItem(item_collection_object_id, transaction_id) { 
							alert("TODO: Implement. [" + item_collection_object_id + "][" + transaction_id + "]" );
						};
						$(document).ready(function() {
							$("##searchResultsGrid").replaceWith('<div id="searchResultsGrid" class="jqxGrid" style="z-index: 1;"></div>');
							$('##resultCount').html('');
							$('##resultLink').html('');
						});
	
						function gridLoaded(gridId, searchType) { 
							$("##overlay").hide();
							var now = new Date();
							var nowstring = now.toISOString().replace(/[^0-9TZ]/g,'_');
							var filename = searchType + '_results_' + nowstring + '.csv';
							// display the number of rows found
							var datainformation = $('##' + gridId).jqxGrid('getdatainformation');
							var rowcount = datainformation.rowscount;
							var items = "."
							if (rowcount > 0) {
								items = ". Click on conditions, instructions, remarks, or disposition cell to edit. ";
							}
							if (rowcount == 1) {
								$('##resultCount').html('Found ' + rowcount + ' ' + searchType + items);
							} else { 
								$('##resultCount').html('Found ' + rowcount + ' ' + searchType + 's' + items);
							}
							// set maximum page size
							if (rowcount > 100) { 
								$('##' + gridId).jqxGrid({ pagesizeoptions: ['5','50', '100', rowcount], pagesize: 50});
							} else if (rowcount > 50) { 
								$('##' + gridId).jqxGrid({ pagesizeoptions: ['5','50', rowcount], pagesize: 50});
							} else { 
								$('##' + gridId).jqxGrid({ pageable: false });
							}
							// add a control to show/hide columns
							var columns = $('##' + gridId).jqxGrid('columns').records;
							var columnListSource = [];
							for (i = 1; i < columns.length; i++) {
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
									// force to lie above the jqx-grid-cell and related elements, see z-index workaround below
									$('.ui-dialog').css({'z-index': maxZIndex + 4 });
									$('.ui-widget-overlay').css({'z-index': maxZIndex + 3 });
								} 
							});
							$("##columnPickDialogButton").html(
								"<button id='columnPickDialogOpener' onclick=\" $('##columnPickDialog').dialog('open'); \" class='btn-xs btn-secondary px-3 py-1 my-2 mx-3' >Show/Hide Columns</button>"
							);
							// workaround for menu z-index being below grid cell z-index when grid is created by a loan search.
							// likewise for the popup menu for searching/filtering columns, ends up below the grid cells.
							var maxZIndex = getMaxZIndex();
							$('.jqx-grid-cell').css({'z-index': maxZIndex + 1});
							$('.jqx-grid-group-cell').css({'z-index': maxZIndex + 1});
							$('.jqx-menu-wrapper').css({'z-index': maxZIndex + 2});
							$('##resultDownloadButtonContainer').html('<button id="loancsvbutton" class="btn-xs btn-secondary px-3 py-1 my-2 mx-0" aria-label="Export results to csv" onclick=" exportGridToCSV(\'searchResultsGrid\', \''+filename+'\'); " >Export to CSV</button>');
						};
	
						// Cell renderers
						var specimenCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
							var rowData = jQuery("##searchResultsGrid").jqxGrid('getrowdata',row);
							var result = "";
							result = '<span class="#cellRenderClasses#" style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; "><a target="_blank" href="/guid/' + rowData['guid'] + '">'+value+'</a></span>';
							return result;
						};
						var deleteCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
							var rowData = jQuery("##searchResultsGrid").jqxGrid('getrowdata',row);
							var result = "";
							var itemid = rowData['part_id'];
							if (itemid) {
								result = '<span class="#cellRenderClasses# float-left mt-1"' + columnproperties.cellsalign + '; "><a name="removeLoanItem" type="button" value="Delete" onclick="removeLoanItem(' + itemid+ ',#transaction_id#);" class="btn btn-xs btn-warning">Remove</a></span>';
							} else { 
								result = '<span class="#cellRenderClasses#" style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; ">'+value+'</span>';
							}
							return result;
						};
						var historyCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
							return 'History';
						};
						var historyButtonClick = function(row) {
							var rowData = jQuery("##searchResultsGrid").jqxGrid('getrowdata',row);
							var itemid = rowData['part_id'];
							openItemConditionHistoryDialog(itemid,'itemConditionHistoryDialog');
						};
	
						var search = {
							datatype: "json",
							datafields:
								[
									{ name: 'transaction_id', type: 'string' },
									{ name: 'part_id', type: 'string' },
									{ name: 'catalog_number', type: 'string' },
									{ name: 'scientific_name', type: 'string' },
									{ name: 'collection', type: 'string' },
									{ name: 'collection_cde', type: 'string' },
									{ name: 'part_name', type: 'string' },
									{ name: 'preserve_method', type: 'string' },
									{ name: 'condition', type: 'string' },
									{ name: 'sampled_from_obj_id', type: 'string' },
									{ name: 'item_descr', type: 'string' },
									{ name: 'item_instructions', type: 'string' },
									{ name: 'loan_item_remarks', type: 'string' },
									{ name: 'coll_obj_disposition', type: 'string' },
									{ name: 'encumbrance', type: 'string' },
									{ name: 'encumbering_agent', type: 'string' },
									{ name: 'sovereign_nation', type: 'string' },
									{ name: 'loan_number', type: 'string' },
									{ name: 'guid', type: 'string' },
									{ name: 'collection_object_id', type: 'string' },
									{ name: 'custom_id', type: 'string' }
								],
							updaterow: function (rowid, rowdata, commit) {
								var data = "method=updateLoanItem";
								data = data + "&transaction_id=" + rowdata.transaction_id;
								data = data + "&part_id=" + rowdata.part_id;
								data = data + "&condition=" + rowdata.condition;
								data = data + "&item_instructions=" + rowdata.item_instructions;
								data = data + "&coll_obj_disposition=" + rowdata.coll_obj_disposition;
								data = data + "&loan_item_remarks=" + rowdata.loan_item_remarks;
								$.ajax({
									dataType: 'json',
									url: '/transactions/component/itemFunctions.cfc',
									data: data,
									success: function (data, status, xhr) {
										commit(true);
									},
									error: function (jqXHR,textStatus,error) {
										commit(false);
										handleFail(jqXHR,textStatus,error,"saving loan item");
									}
								});
							},
							root: 'loanItemRecord',
							id: 'itemId',
							url: '/transactions/component/itemFunctions.cfc?method=getLoanItemsData&transaction_id=#transaction_id#',
							timeout: 30000, // units not specified, miliseconds? 
							loadError: function(jqXHR, textStatus, error) { 
								handleFail(jqXHR,textStatus,error,"loading loan items");
							},
							async: true
						};
	
						function reloadGrid() { 
							var dataAdapter = new $.jqx.dataAdapter(search);
							$("##searchResultsGrid").jqxGrid({ source: dataAdapter });
						};
	
						function loadGrid() { 
		
							var dataAdapter = new $.jqx.dataAdapter(search);
							var initRowDetails = function (index, parentElement, gridElement, datarecord) {
								// could create a dialog here, but need to locate it later to hide/show it on row details opening/closing and not destroy it.
								var details = $($(parentElement).children()[0]);
								details.html("<div id='rowDetailsTarget" + index + "'></div>");
								createRowDetailsDialog('searchResultsGrid','rowDetailsTarget',datarecord,index);
								// Workaround, expansion sits below row in zindex.
								var maxZIndex = getMaxZIndex();
								$(parentElement).css('z-index',maxZIndex - 1); // will sit just behind dialog
							};
							$("##searchResultsGrid").jqxGrid({
								width: '100%',
								autoheight: 'true',
								source: dataAdapter,
								filterable: true,
								sortable: true,
								pageable: true,
								editable: true,
								pagesize: 50,
								pagesizeoptions: ['5','50','100'],
								showaggregates: true,
								columnsresize: true,
								autoshowfiltericon: true,
								autoshowcolumnsmenubutton: false,
								autoshowloadelement: false, // overlay acts as load element for form+results
								columnsreorder: true,
								groupable: true,
								selectionmode: 'singlerow',
								altrows: true,
								showtoolbar: false,
								ready: function () {
									$("##searchResultsGrid").jqxGrid('selectrow', 0);
								},
								columns: [
									{text: 'transactionID', datafield: 'transaction_id', width: 50, hideable: true, hidden: true, editable: false },
									{text: 'Loan Number', datafield: 'loan_number', hideable: true, hidden: true, editable: false },
									{text: 'Collection', datafield: 'collection', width:80, hideable: true, hidden: true, editable: false  },
									{text: 'Collection Code', datafield: 'collection_cde', width:60, hideable: true, hidden: false, editable: false  },
									{text: 'Catalog Number', datafield: 'catalog_number', width:100, hideable: true, hidden: false, editable: false, cellsrenderer: specimenCellRenderer },
									{text: 'GUID', datafield: 'guid', width:80, hideable: true, hidden: true, editable: false  },
									{text: '#session.CustomOtherIdentifier#', width: 100, datafield: 'custom_id', hideable: true, hidden: true, editable: false },
									{text: 'Scientific Name', datafield: 'scientific_name', width:210, hideable: true, hidden: false, editable: false },
									{text: 'Part Name', datafield: 'part_name', width:110, hideable: true, hidden: false, editable: false },
									{text: 'Preserve Method', datafield: 'preserve_method', width:130, hideable: true, hidden: false, editable: false },
									{text: 'Item Descr', datafield: 'item_descr', width:110, hideable: true, hidden: true, editable: false },
									{text: 'Subsample', datafield: 'sampled_from_obj_id', width:80, hideable: false, hidden: false, editable: false },
									{text: 'Condition', datafield: 'condition', width:180, hideable: false, hidden: false, editable: true },
									{text: 'History', datafield: 'History', width:80, columntype: 'button', hideable: true, hidden: true, editable: false, 
										cellsrenderer: historyCellRenderer, buttonclick: historyButtonClick
									},
									{text: 'Item Instructions', datafield: 'item_instructions', width:180, hideable: false, hidden: false, editable: true },
									{text: 'Item Remarks', datafield: 'loan_item_remarks', width:180, hideable: false, hidden: false, editable: true },
									{text: 'Disposition', datafield: 'coll_obj_disposition', width:180, hideable: false, hidden: false, editable: true, columntype: 'dropdownlist',
										initEditor: function(row, cellvalue, editor) { editor.jqxDropDownList({ source: #ctDispSource# }).jqxDropDownList('selectItem', cellvalue ); }
									},
									{text: 'Encumbrance', datafield: 'encumbrance', width:100, hideable: true, hidden: false, editable: false },
									{text: 'Encumbered By', datafield: 'encumbering_agent', width:100, hideable: true, hidden: true, editable: false },
									{text: 'PartID', datafield: 'part_id', width: 80, hideable: true, hidden: false, cellsrenderer: deleteCellRenderer, editable: false },
									{text: 'Country of Origin', datafield: 'sovereign_nation', hideable: true, hidden: false, editable: false }
								],
								rowdetails: true,
								rowdetailstemplate: {
									rowdetails: "<div style='margin: 10px;'>Row Details</div>",
									rowdetailsheight: 1 // row details will be placed in popup dialog
								},
								initrowdetails: initRowDetails
							});
							$("##searchResultsGrid").on("bindingcomplete", function(event) {
								gridLoaded('searchResultsGrid','loan item');
							});
							$('##searchResultsGrid').on('rowexpand', function (event) {
								// Create a content div, add it to the detail row, and make it into a dialog.
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
						};
						$(document).ready(function() {
							loadGrid();
						});
					</script>

				</div>
			</section>
		</cfoutput>
	</main>
</cfif>

<cfinclude template="/shared/_footer.cfm">
