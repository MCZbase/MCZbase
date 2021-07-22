<!---
CollEventNumberSeries.cfm

For managing collecting event number series.

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

--->
<cfif not isdefined("action")>
	<cfset action="findAll">
</cfif>
<cfswitch expression="#action#">
	<cfcase value="findAll">
		<cfset pageTitle = "Search Collecting Event Number Series">
	</cfcase>
	<cfcase value="new">
		<cfset pageTitle = "Add New Collecting Event Number Series">
	</cfcase>
	<cfcase value="edit">
		<cfset pageTitle = "Edit a Collecting Event Number Series">
	</cfcase>
	<cfdefaultcase>
		<cfset pageTitle = "Collecting Event Number Series">
	</cfdefaultcase>
</cfswitch>
<!---------------------------------------------------------------------------------->
<cfinclude template = "/shared/_header.cfm">
<!---------------------------------------------------------------------------------->
<cfswitch expression="#action#">
	<cfcase value="findAll">
		<div id="overlaycontainer" style="position: relative;">
			<!--- ensure fields have empty values present if not defined. --->
			<cfif not isdefined("number_series")><cfset number_series=""></cfif>
			<cfif not isdefined("number")><cfset number=""></cfif>
			<cfif not isdefined("pattern")><cfset pattern=""></cfif>
			<cfif not isdefined("remarks")><cfset remarks=""></cfif>
			<!--- Search Form --->
			<cfoutput>
				<main  id="content">
					<section class="container-fluid" role="search">
						<div class="row mx-0 mb-3">
							<div class="search-box">
								<div class="search-box-header">
									<h1 class="h3 text-white" id="formheading">Find Collecting Event Number Series</h1>
								</div>
								<div class="col-12 px-4 mt-3 py-1">
									<form name="searchForm" id="searchForm"> 
										<input type="hidden" name="method" value="getCollEventNumberSeries" class="keeponclear">
										<div class="form-row my-2">
											<div class="col-md-6">
												<label for="number_series" class="data-entry-label" id="number_series_label">Name for the Collector Number Series</label>
												<input type="text" id="number_series" name="number_series" class="data-entry-input" value="#number_series#" aria-labelledby="number_series_label" >
											</div>
											<div class="col-md-6">
												<label for="pattern" class="data-entry-label" id="pattern_label">Pattern</label>
												<input type="text" id="pattern" name="pattern" class="data-entry-input" value="#pattern#" aria-labelledby="pattern_label" >					
											</div>
										</div>
										<div class="form-row mb-2">
											<div class="col-md-12">
												<label for="number" class="data-entry-label" id="number_label">A number in the Series</label>
												<input type="text" id="number" name="number" class="data-entry-input" value="#number#" aria-labelledby="number_label" >					
											</div>
										</div>
										<div class="form-row my-2 mx-0">
											<div class="col-12 px-0">
												<button class="btn-xs mr-1 btn-primary px-2 mt-3" id="loanSearchButton" type="submit" aria-label="Search loans">Search<span class="fa fa-search pl-1"></span></button>
												<button type="reset" class="mr-1 btn-xs btn-warning mt-3" aria-label="Reset search form to inital values" onclick="">Reset</button>
												<button type="button" class="mr-1 btn-xs btn-warning mt-3" aria-label="Start a new collecting event number series search with a clear form" onclick="window.location.href='#Application.serverRootUrl#/vocabularies/CollEventNumberSeries.cfm?action=findAll';" >New Search</button>
												<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_specimens")>
													<button type="button" class="mr-1 btn-xs btn-secondary my-2" aria-label="Create a new collecting event number series" onclick="window.location.href='#Application.serverRootUrl#/vocabularies/CollEventNumberSeries.cfm?action=new';" >Create New Number Series</button>
												</cfif>
											</div>
										</div>
									</form>
								</div>
							</div>
						</div>
					</section>

					<!--- Results table as a jqxGrid. --->
					<section class="container-fluid">
						<div class="row mx-0">
							<div class="col-12 mb-5">
								<div class="row mt-1 mb-0 pb-0 jqx-widget-header border px-2">
									<h1 class="h4">Results: </h1>
									<span class="d-block px-3 p-2" id="resultCount"></span> <span id="resultLink" class="d-block p-2"></span>
									<div id="columnPickDialog">
										<div id="columnPick" class="px-1"></div>
									</div>
									<div id="columnPickDialogButton"></div>
									<div id="resultDownloadButtonContainer"></div>
								</div>
								<div class="row mt-0">
									<!--- Grid Related code is below along with search handlers --->
									<div id="searchResultsGrid" class="jqxGrid" role="table" aria-label="Search Results Table"></div>
									<div id="enableselection"></div>
								</div>
							</div>
						</div>
					</section>
				</main>
		
				<script>
					window.columnHiddenSettings = new Object();
					<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
						lookupColumnVisibilities ('#cgi.script_name#','Default');
					</cfif>

					$(document).ready(function() {
						/* Setup jqxgrid for Search */
						$('##searchForm').bind('submit', function(evt){
							evt.preventDefault();
					
							$("##overlay").show();
					
							$("##searchResultsGrid").replaceWith('<div id="searchResultsGrid" class="jqxGrid" style="z-index: 1;"></div>');
							$('##resultCount').html('');
							$('##resultLink').html('');
					
							var search =
							{
								datatype: "json",
								datafields:
								[
									{ name: 'number_series', type: 'string' },
									{ name: 'coll_event_num_series_id', type: 'string' },
									{ name: 'pattern', type: 'string' },
									{ name: 'remarks', type: 'string' },
									{ name: 'agentname', type: 'string' },
									{ name: 'collector_agent_id', type: 'string' },
									{ name: 'number_count', type: 'string' },
									{ name: 'id_link', type: 'string' }
								],
								updaterow: function (rowid, rowdata, commit) {
									commit(true);
								},
								root: 'numberSeriesRecord',
								id: 'coll_event_num_series_id',
								url: '/vocabularies/component/search.cfc?' + $('##searchForm').serialize(),
								timeout: 30000,  // units not specified, miliseconds? 
								loadError: function(jqXHR, status, error) { 
									$("##overlay").hide();
					            var message = "";      
									if (error == 'timeout') { 
					               message = ' Server took too long to respond.';
					            } else { 
					               message = jqXHR.responseText;
					            }
					            messageDialog('Error:' + message ,'Error: ' + error.substring(0,50));
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
								pagesizeoptions: ['5','50','100'],
								showaggregates: true,
								columnsresize: true,
								autoshowfiltericon: true,
								autoshowcolumnsmenubutton: false,
								autoshowloadelement: false,  // overlay acts as load element for form+results
								columnsreorder: true,
								groupable: true,
								selectionmode: 'singlerow',
								altrows: true,
								showtoolbar: false,
								columns: [
									{text: 'Number Series', datafield: 'number_series', width:150, hideable: true, hidden: true },
									{text: 'Number Series Link', datafield: 'id_link', width: 150},
									{text: 'Pattern', datafield: 'pattern', width:120, hideable: true, hidden: false },
									{text: 'Collector', datafield: 'agentname', width:150, hideable: true, hidden: false },
									{text: 'AgentID', datafield: 'collector_agent_id', width:100, hideable: true, hidden: true },
									{text: 'Number Count', datafield: 'number_count', width:150, hideable: true, hidden: false },
									{text: 'Remarks', datafield: 'remarks', hideable: true, hidden: false },
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
								$('##resultLink').html('<a href="/vocabularies/CollEventNumberSeries.cfm?action=findAll&execute=true&' + $('##searchForm :input').filter(function(index,element){return $(element).val()!='';}).serialize() + '">Link to this search</a>');
								gridLoaded('searchResultsGrid','collecting event number');
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
						/* End Setup jqxgrid for number series Search ******************************/
		
						// If requested in uri, execute search immediately.
						<cfif isdefined("execute")>
							$('##searchForm').submit();
						</cfif>
					}); /* End document.ready */
	
					function gridLoaded(gridId, searchType) { 
						if (Object.keys(window.columnHiddenSettings).length == 0) { 
							window.columnHiddenSettings = getColumnVisibilities('searchResultsGrid');		
							<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
								saveColumnVisibilities('#cgi.script_name#',window.columnHiddenSettings,'Default');
							</cfif>
						}
						$("##overlay").hide();
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
								Ok: function(){ 
									window.columnHiddenSettings = getColumnVisibilities('searchResultsGrid');		
									<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
										saveColumnVisibilities('#cgi.script_name#',window.columnHiddenSettings,'Default');
									</cfif>
									$(this).dialog("close"); 
								}
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
						$('##resultDownloadButtonContainer').html('<button id="loancsvbutton" class="btn-xs btn-secondary px-3 py-1 my-2 mx-3 mx-lg-0" aria-label="Export results to csv" onclick=" exportGridToCSV(\'searchResultsGrid\', \''+filename+'\'); " >Export to CSV</button>');
					}
				</script>
			</cfoutput>
			<div id="overlay" style="position: absolute; top:0px; left:0px; width: 100%; height: 100%; background: rgba(0,0,0,0.5); opacity: 0.99; display: none; z-index: 2;">
				<div class="jqx-rc-all jqx-fill-state-normal" style="position: absolute; left: 50%; top: 25%; width: 10em; height: 2.4em;line-height: 2.4em; padding: 5px; color: ##333333; border-color: ##898989; border-style: solid; margin-left: -5em; opacity: 1;">
					<div class="jqx-grid-load" style="float: left; overflow: hidden; height: 32px; width: 32px;"></div>
					<div style="float: left; display: block; margin-left: 1em;" >Searching...</div>	
				</div>
			</div>
		</div><!--- overlay container --->
	</cfcase>
	<!---------------------------------------------------------------------------------->
	<cfcase value="new">
		<!---  Add a new collecting event number series, link to agent --->
		<cfoutput>
			<main class="container mt-3" id="content">
				<section class="row" aria-labelledby="formheading">
					<div class="col-12">
						<h1 class="h2 pl-3 ml-2" id="formheading">New Collecting Event Number Series</h1>
						<div class="border rounded px-3 py-2">
							<form name="newNumSeries" id="newNumSeries" action="/vocabularies/CollEventNumberSeries.cfm" method="post"> 
								<input type="hidden" id="action" name="action" value="saveNew" >
								<div class="form-row mb-2">
									<div class="col-12 col-md-6">
										<label for="number_series" class="data-entry-label" id="number_series_label">Name for the Collector Number Series</label>
										<input type="text" id="number_series" name="number_series" class="reqdClr data-entry-input" required value="" aria-labelledby="number_series_label" >
									</div>
									<div class="col-12 col-md-6">
										<label for="pattern" id="pattern_label" class="data-entry-label">Pattern for numbers in this series</label>
										<input type="text" id="pattern" name="pattern" class="data-entry-input" value="" aria-labelledby="pattern_label" >
									</div>
								</div>
								<div class="form-row mb-2">
									<div class="col-12 col-md-12">
										<label for="remarks" id="remarks_label" class="data-entry-label">Remarks (<span id="length_remarks">0 characters 4000 left</span>)</label>
										<textarea id="remarks" name="remarks" class="data-entry-textarea"
											onkeyup="countCharsLeft('remarks',4000,'length_remarks');"
											rows="3" aria-labelledby="remarks_label" ></textarea>
									</div>
								</div>
								<div class="form-row mb-2">
										<div class="col-12 col-md-6">
										<span>
											<label for="collector_agent_name" class="data-entry-label w-auto">Numbers in this series assigned by Agent</label>
											<span id="collector_agent_view" class="d-inline">&nbsp;&nbsp;&nbsp;&nbsp;</span>
										</span>
										<div class="input-group">
											<div class="input-group-prepend">
												<span class="input-group-text smaller" id="collector_agent_name_icon"><i class="fa fa-user" aria-hidden="true"></i></span> 
											</div>
											<input name="collector_agent_name" id="collector_agent_name" class="form-control form-control-sm data-entry-input rounded-right" value="" aria-label="This is a number series of collector: " >
											<input type="hidden" name="collector_agent_id" id="collector_agent_id" value="" >
										</div>
										<script>
											$(document).ready(function() {
												$(makeRichAgentPicker('collector_agent_name', 'collector_agent_id', 'collector_agent_name_icon', 'collector_agent_view', ''));
											});
										</script>
									</div>
	
								</div>
								<script>
									$('##remarks').keyup(autogrow);
								</script>
								<div class="form-row mb-0">
									<div class="col-12 col-md-12 my-2">   								
										<input type="button" 
											value="Create" title="Create" aria-label="Create"
											class="btn btn-xs btn-primary"
											onClick="if (checkFormValidity($('##newNumSeries')[0])) { submit();  } " 
											>
									</div>
								</div>
							</form>
						</div>
					</div><!--- col --->
				</section>
			</main>
		</cfoutput>
	</cfcase>
	<!---------------------------------------------------------------------------------->
	<cfcase value="saveNew">
		<cftry>
			<cfif not isdefined("number_series") OR len(trim(#number_series#)) EQ 0 >
				<cfthrow type="Application" message="Error: No value provided for required value number_series">
			</cfif>
			<cfquery name="save" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="insertResult">
				insert into coll_event_num_series (
					number_series
					<cfif isdefined("pattern")>
						,pattern
					</cfif>
					<cfif isdefined("remarks")>
						,remarks
					</cfif>
					<cfif isdefined("collector_agent_id")>
						,collector_agent_id
					</cfif>
				) values (
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#number_series#">
					<cfif isdefined("pattern")>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#pattern#">
					</cfif>
					<cfif isdefined("remarks")>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#remarks#">
					</cfif>
					<cfif isdefined("collector_agent_id")>
						,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collector_agent_id#">
					</cfif>
				)
			</cfquery>
			<cfquery name="savePK" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="pkResult">
				select coll_event_num_series_id from coll_event_num_series 
				where ROWIDTOCHAR(rowid) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#insertResult.GENERATEDKEY#">
			</cfquery>
			<cflocation url="/vocabularies/CollEventNumberSeries.cfm?action=edit&coll_event_num_series_id=#savePK.coll_event_num_series_id#" addtoken="false">
		<cfcatch>
			<cfthrow type="Application" message="Error Saving new Collecting Event Number Series: #cfcatch.Message# #cfcatch.Detail#">
		</cfcatch>
		</cftry>
	</cfcase>
	<!---------------------------------------------------------------------------------->
	<cfcase value="edit">
		<cfif not isDefined("coll_event_num_series_id")>
			<cfset coll_event_num_series_id = "">
		</cfif>
		<cfif len("coll_event_num_series_id") EQ 0>
			<cfthrow type="Application" message="Error: No value provided for coll_event_num_series_id">
		<cfelse>
			<cfquery name="numSeries" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="numSeries_result">
				select coll_event_num_series_id, number_series, pattern, remarks, collector_agent_id,
					case 
						when collector_agent_id is null then '[No Agent]'
						else MCZBASE.get_agentnameoftype(collector_agent_id, 'preferred')
						end
					as agentname
				from coll_event_num_series 
				where coll_event_num_series_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#coll_event_num_series_id#">
			</cfquery>
			<cfoutput query="numSeries">
				<main id="content">
					<section class="container py-3" aria-labelledby="formheading">
						<h1 class="h2" id="formheading">Edit Collecting Event Number Series</h1>
						<div class="row py-3 border rounded">
							<div class="col-12 px-3">
								<form name="editNumSeries" id="editNumSeries"> 
									<input type="hidden" id="coll_event_num_series_id" name="coll_event_num_series_id" value="#coll_event_num_series_id#" >
									<input type="hidden" id="method" name="method" value="saveNumSeries" >
									<div class="form-row mb-2">
										<div class="col-12 col-md-6">
											<label for="number_series" id="number_series_label" class="data-entry-label">Name for the Collector Number Series</label>
											<input type="text" id="number_series" name="number_series" class="reqdClr data-entry-input" required value="#number_series#" aria-labelledby="number_series_label">	
										</div>
										<div class="col-12 col-md-6">
											<label for="pattern" id="pattern_label" class="data-entry-label">Pattern for numbers in this series</label>
											<input type="text" id="pattern" name="pattern" class="data-entry-input" value="#pattern#" aria-labelledby="pattern_label" >
										</div>
									</div>
									<div class="form-row mb-2">
										<div class="col-md-12">
											<label for="remarks" id="remarks_label" class="data-entry-label">Remarks (<span id="length_remarks"></span>)</label>
											<textarea id="remarks" name="remarks" class="data-entry-textarea mt-0 autogrow"
												onkeyup="countCharsLeft('remarks',4000,'length_remarks');"
												rows="3" aria-labelledby="remarks_label" >#remarks#</textarea>
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
									<div class="form-row mb-0">
										<div class="col-12 col-md-6"> 
											<span>
												<label for="collector_agent_name" id="collector_agent_name_label" class="data-entry-label w-auto">Numbers in this series assigned by Agent</label>
												<h5 id="collector_agent_view" class="d-inline">&nbsp;&nbsp;&nbsp;&nbsp;</h5>
											</span>
											<div class="input-group">
												<div class="input-group-prepend">
													<span class="input-group-text smaller" id="collector_agent_name_icon"><i class="fa fa-user" aria-hidden="true"></i></span> 
												</div>
												<input name="collector_agent_name" id="collector_agent_name" class="form-control form-control-sm data-entry-input rounded-right" value="#agentname#" aria-labelledby="collector_agent_name_label" >
												<input type="hidden" name="collector_agent_id" id="collector_agent_id" value="#collector_agent_id#"  >
											</div>
											<script>
												function changed(){
													$('##saveResultDiv').html('Unsaved changes.');
													$('##saveResultDiv').addClass('text-danger');
													$('##saveResultDiv').removeClass('text-success');
													$('##saveResultDiv').removeClass('text-warning');
												};
												$(document).ready(function() {
													$(makeRichAgentPicker('collector_agent_name', 'collector_agent_id', 'collector_agent_name_icon', 'collector_agent_view', '#collector_agent_id#'));
													$('##editNumSeries input[type=text]').on("change",changed);
													$('##remarks').on("change",changed);
												});
												function saveChanges(){ 
													var agenttext = $('##collector_agent_name').val();
													var agentid = $('##collector_agent_id').val();
													if (agenttext.length == 0 || (agentid.length>0 && agenttext.length>0)) { 
														$('##saveResultDiv').html('Saving....');
														$('##saveResultDiv').addClass('text-warning');
														$('##saveResultDiv').removeClass('text-success');
														$('##saveResultDiv').removeClass('text-danger');
														jQuery.ajax({
															url : "/vocabularies/component/functions.cfc",
															type : "post",
															dataType : "json",
															data :  $('##editNumSeries').serialize(),
															success : function (data) {
																$('##saveResultDiv').html('Saved.');
																$('##saveResultDiv').removeClass('text-warning');
																$('##saveResultDiv').addClass('text-success');
																$('##saveResultDiv').removeClass('text-danger');
															},
															error: function(jqXHR,textStatus,error){
																$('##saveResultDiv').html('Error.');
																$('##saveResultDiv').addClass('text-danger');
																$('##saveResultDiv').removeClass('text-success');
																$('##saveResultDiv').removeClass('text-warning');
																var message = "";
																if (error == 'timeout') {
																	message = ' Server took too long to respond.';
																} else {
																	message = jqXHR.responseText;
																}
																messageDialog('Error saving collecting event number series: '+message, 'Error: '+error.substring(0,50));
															}
														});
													} else { 
														messageDialog('Error saving collecting event number series: If an entry is made in the agent field an agent must be selected from the picklist.', 'Error: Agent not selected');
														$('##saveResultDiv').html('Fix error in Agent field.');
														$('##saveResultDiv').addClass('text-danger');
														$('##saveResultDiv').removeClass('text-success');
														$('##saveResultDiv').removeClass('text-warning');
													}
												};
											</script>
										</div>
									</div>
									<div class="form-row mb-1">	
										<div class="col-12">   
											<div id="saveResultDiv">&nbsp;</div>
											<input type="button" 
												value="Save" title="Save" aria-label="Save"
												class="btn btn-xs btn-primary"
												onClick="if (checkFormValidity($('##editNumSeries')[0])) { saveChanges();  } " 
												>
										</div>
									</div>
								</form>
							</div><!--- col --->
						</div><!--- row --->
					</section>
					<cfif numSeries_result.recordcount GT 0>
						<!--- list instances of the collecting event number, link out to specimen search --->
						<cfquery name="numSeriesUse" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="numSeriesUse_result">
							select coll_event_number, collecting_event_id 
							from coll_event_number
							where coll_event_num_series_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#coll_event_num_series_id#">
							order by coll_event_number
						</cfquery>
						<section class="container pb-4">
							<div class="row">
								<div class="col-12" aria-labelledby="existingvalues">
									<cfif numSeriesUse_result.recordcount EQ 0>
										<h2 class="h3 mt-0" id="existingvalues">There are no Instances of this Collecting Event Number Series</h2>
									<cfelse>
										<h2 class="h3 mt-0" id="existingvalues">Instances of this Collecting Event Number Series</h2>
										<ul class="px-4 list-style-disc">
											<cfloop query="numSeriesUse">
												<li><a href="/SpecimenResults.cfm?collecting_event_id=#numSeriesUse.collecting_event_id#" target="_blank">#coll_event_number#</a>
											</cfloop>
										</ul>
									</cfif>
								</div>
							</div>
						</section>
					</cfif>
				</main>
			</cfoutput>
		</cfif>
	</cfcase>
	<!---------------------------------------------------------------------------------->
	<cfdefaultcase>
		<cfthrow type="Application" message="Unknown action.">
	</cfdefaultcase>
</cfswitch>
<!---------------------------------------------------------------------->
<cfinclude template = "/shared/_footer.cfm">
