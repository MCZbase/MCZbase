<!---
publications/Journals.cfm

Journal search/results 

Copyright 2022 President and Fellows of Harvard College

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
<cfset pageTitle = "Search Serial/Journal Names">
<cfinclude template = "/shared/_header.cfm">

<div id="overlaycontainer" style="position: relative;"> 
	<!--- ensure fields have empty values present if not defined. --->
	<cfif not isdefined("journal_name")> 
		<cfset journal_name="">
	</cfif>
	<cfif not isdefined("short_name")> 
		<cfset short_name="">
	</cfif>
	<cfif not isdefined("issn")> 
		<cfset issn="">
	</cfif>
	<cfif not isdefined("remarks")> 
		<cfset remarks="">
	</cfif>
	<cfif not isdefined("start_year")> 
		<cfset start_year="">
	</cfif>
	<cfif not isdefined("end_year")> 
		<cfset end_year="">
	</cfif>
	<!--- Search Form ---> 
	<cfoutput>
		<main id="content">
			<section class="container-fluid mb-3" role="search" aria-labelledby="formheader">
				<div class="row mx-0 mb-3">
					<div class="search-box">
						<div class="search-box-header">
							<h1 class="h3 text-white" id="formheading">Find Serials/Journal Names</h1>
						</div>

						<div class="col-12 pt-3 px-4 pb-2">
							<form name="searchForm" id="searchForm">
								<input type="hidden" name="method" value="getJournalNames">
								<div class="form-row">
									<div class="col-12 col-md-6">
										<div class="form-group mb-2">
											<label for="journal_name" class="data-entry-label mb-0" id="journal_name_label">Title
												<span class="small">
													(pick, substring,
													<button type="button" tabindex="-1" aria-hidden="true" class="btn-link border-0 p-0 bg-light" onclick="var e=document.getElementById('journal_name');e.value='='+e.value;">=<span class="sr-only">prefix with equals sign for exact match search</span></button>, 
													<button type="button" tabindex="-1" aria-hidden="true" class="btn-link border-0 p-0 bg-light" onclick="var e=document.getElementById('journal_name');e.value='~'+e.value;">~<span class="sr-only">prefix with tilde for nearby string search</span></button>,
													<button type="button" tabindex="-1" aria-hidden="true" class="btn-link border-0 p-0 bg-light" onclick="var e=document.getElementById('journal_name');e.value='$'+e.value;">$<span class="sr-only">prefix with dollarsign for sounds like search</span></button>)
												</span>
											</label>
											<input type="text" id="journal_name" name="journal_name" class="data-entry-input" value="#encodeForHtml(journal_name)#" aria-labelledby="journal_name_label" >
										</div>
										<script>
											$(document).ready(function() {
												makeJournalAutocomplete("journal_name");
											});
										</script>
									</div>
									<div class="col-12 col-md-6">
										<div class="form-group mb-2">
											<label for="short_name" class="data-entry-label mb-0" id="short_name_label">Short Name
												<span class="small">
													(<button type="button" tabindex="-1" aria-hidden="true" class="btn-link border-0 p-0 bg-light" onclick="var e=document.getElementById('short_name');e.value='='+e.value;">=<span class="sr-only">prefix with equals sign for exact match search</span></button>, 
													<button type="button" tabindex="-1" aria-hidden="true" class="btn-link border-0 p-0 bg-light" onclick="var e=document.getElementById('short_name');e.value='~'+e.value;">~<span class="sr-only">prefix with tilde for nearby string search</span></button>,
													<button type="button" tabindex="-1" aria-hidden="true" class="btn-link border-0 p-0 bg-light" onclick="var e=document.getElementById('short_name');e.value='$'+e.value;">$<span class="sr-only">prefix with dollarsign for sounds like search</span></button>)
												</span>
											</label>
											<input type="text" id="short_name" name="short_name" class="data-entry-input" value="#encodeForHtml(short_name)#" aria-labelledby="short_name_label" >
										</div>
									</div>
									<div class="col-12 col-md-4">
										<label for="issn" class="data-entry-label mb-0" id="issn_label">ISSN
											<span class="small">
												(<button type="button" tabindex="-1" aria-hidden="true" class="btn-link border-0 p-0 bg-light" onclick="var e=document.getElementById('issn');e.value='='+e.value;">=<span class="sr-only">prefix with equals sign for exact match search</span></button>, 
												<button type="button" tabindex="-1" aria-hidden="true" class="btn-link border-0 p-0 bg-light" onclick="var e=document.getElementById('issn');e.value='~'+e.value;">~<span class="sr-only">prefix with tilde for nearby string search</span></button>,
												<button type="button" tabindex="-1" aria-hidden="true" class="btn-link border-0 p-0 bg-light" onclick="var e=document.getElementById('issn');e.value='NULL';">NULL<span class="sr-only">use NULL to find records with no value in issn</span></button>,
												<button type="button" tabindex="-1" aria-hidden="true" class="btn-link border-0 p-0 bg-light" onclick="var e=document.getElementById('issn');e.value='NOT NULL';">NOT NULL<span class="sr-only">use NOT NULL to find records with any value in issn</span></button>)
											</span>
										</label>
										<input type="text" id="issn" name="issn" class="data-entry-input" value="#encodeForHtml(issn)#" aria-labelledby="issn_label" >
									</div>
									<div class="col-12 col-md-4">
										<div class="form-row mx-0 mb-2">
											<label class="data-entry-label mx-1 mb-0" for="end_year">Start Year
												<span class="small">
													(<button type="button" tabindex="-1" aria-hidden="true" class="btn-link border-0 p-0 bg-light" onclick="var e=document.getElementById('start_year');e.value='>'+e.value;">&gt;<span class="sr-only">prefix with greater than for start years after specified year</span></button>, 
													<button type="button" tabindex="-1" aria-hidden="true" class="btn-link border-0 p-0 bg-light" onclick="var e=document.getElementById('start_year');e.value='<'+e.value;">&lt;<span class="sr-only">prefix with less than for start years before the specified year</span></button>,
													<button type="button" tabindex="-1" aria-hidden="true" class="btn-link border-0 p-0 bg-light" onclick="var e=document.getElementById('start_year');e.value='NULL';">NULL<span class="sr-only">use NULL to find records with no value in start year</span></button>,
													<button type="button" tabindex="-1" aria-hidden="true" class="btn-link border-0 p-0 bg-light" onclick="var e=document.getElementById('start_year');e.value='NOT NULL';">NOT NULL<span class="sr-only">use NOT NULL to find records with any value in start year</span></button>)
												</span>
											</label>
											<input name="start_year" id="start_year" type="text" class="data-entry-input" placeholder="yyyy" value="#encodeForHtml(start_year)#" aria-label="start of range for publication year">
										</div>
									</div>
									<div class="col-12 col-md-4">
										<div class="form-row mx-0 mb-2">
											<label class="data-entry-label mx-1 mb-0" for="end_year">End Year
												<span class="small">
													(<button type="button" tabindex="-1" aria-hidden="true" class="btn-link border-0 p-0 bg-light" onclick="var e=document.getElementById('end_year');e.value='>'+e.value;">&gt;<span class="sr-only">prefix with greater than for end years after specified year</span></button>, 
													<button type="button" tabindex="-1" aria-hidden="true" class="btn-link border-0 p-0 bg-light" onclick="var e=document.getElementById('end_year');e.value='<'+e.value;">&lt;<span class="sr-only">prefix with less than for end years before the specified year</span></button>,
													<button type="button" tabindex="-1" aria-hidden="true" class="btn-link border-0 p-0 bg-light" onclick="var e=document.getElementById('end_year');e.value='NULL';">NULL<span class="sr-only">use NULL to find records with no value in start year</span></button>,
													<button type="button" tabindex="-1" aria-hidden="true" class="btn-link border-0 p-0 bg-light" onclick="var e=document.getElementById('end_year');e.value='NOT NULL';">NOT NULL<span class="sr-only">use NOT NULL to find records with any value in start year</span></button>)
												</span>
											</label>
											<input type="text" name="end_year" id="end_year" value="#encodeForHtml(end_year)#" class="data-entry-input" placeholder="yyyy" title="end of date range">
										</div>
									</div>

									<div class="col-12 pt-0">
										<button class="btn-xs btn-primary px-2 my-2 mr-1" id="searchButton" type="submit" aria-label="Search for serial/journal titles">Search<span class="fa fa-search pl-1"></span></button>
										<button type="reset" class="btn-xs btn-warning my-2 mr-1" aria-label="Reset search form to inital values" onclick="">Reset</button>
										<button type="button" class="btn-xs btn-warning my-2 mr-1" aria-label="Start a new journal search with a clear form" onclick="window.location.href='#Application.serverRootUrl#/publications/Journals.cfm';" >New Search</button>
									</div>
								</div>
	
							</form>
						</div>
					</div><!--- search box --->
				</div><!--- row --->
			</section>
		
			<!--- Results table as a jqxGrid. --->
			<section class="container-fluid">
				<div class="row mx-0">
					<div class="col-12">
						<div class="mb-5">
							<div class="row my-1 jqx-widget-header border px-2">
								<h1 class="h4 pt-2 ml-2 ml-md-1 mt-1">Results: 
									<span class="pr-2 font-weight-normal" id="resultCount"></span> 
									<span id="resultLink" class="font-weight-normal pr-2"></span>
								</h1>
								<div id="saveDialogButton" class=""></div>
								<div id="saveDialog"></div>
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
								<output id="actionFeedback" class="btn btn-xs btn-transparent my-2 px-2 pt-1 mx-1 border-0"></output>
							</div>
							<div class="row mt-0"> 
								<!--- Grid Related code is below along with search handlers --->
								<div id="searchResultsGrid" class="jqxGrid" role="table" aria-label="Search Results Table"></div>
								<div id="enableselection"></div>
							</div>
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

			var editCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
				var rowData = jQuery("##searchResultsGrid").jqxGrid('getrowdata',row);
				return '<a target="_blank" href="/publications/Journal.cfm?journal_name=' + rowData['journal_name'] + '">Edit</a>';
			};
			var pubCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
				var rowData = jQuery("##searchResultsGrid").jqxGrid('getrowdata',row);
				var journalName = encodeURIComponent(rowData['journal_name']);
				if (value==true && value>0) { 
					return '<span style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; "><a target="_blank" href="/Publications.cfm?execute=true&journal_name=' + journalName + '">'+value+'</a></span>';
				} else {
					return '<span style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; ">'+value+'</span>';
				}
			};
	
			$(document).ready(function() {
				/* Setup jqxgrid for Search */
				$('##searchForm').bind('submit', function(evt){
					evt.preventDefault();
			
					$("##overlay").show();
			
					$("##searchResultsGrid").replaceWith('<div id="searchResultsGrid" class="jqxGrid" style="z-index: 1;"></div>');
					$('##resultCount').html('');
					$('##resultLink').html('');
					$('##saveDialogButton').html('');
					$('##actionFeedback').html('');
			
					var search =
					{
						datatype: "json",
						datafields:
						[
							{ name: 'remarks', type: 'string' },
							{ name: 'issn', type: 'string' },
							{ name: 'end_year', type: 'string' },
							{ name: 'start_year', type: 'string' },
							{ name: 'short_name', type: 'string' },
							{ name: 'publication_count', type: 'string' },
							{ name: 'journal_name', type: 'string' }
						],
						updaterow: function (rowid, rowdata, commit) {
							commit(true);
						},
						root: 'journalRecord',
						id: 'journal_name',
						url: '/publications/component/search.cfc?' + $('##searchForm').serialize(),
						timeout: 60000,  // units not specified, miliseconds? 
						loadError: function(jqXHR, textStatus, error) { 
							$("##overlay").hide();
							handleFail(jqXHR,textStatus,error,"running journal search");
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
						autorowheight: 'true',
						source: dataAdapter,
						filterable: true,
						sortable: true,
						pageable: true,
						editable: false,
						pagesize: '50',
						pagesizeoptions: ['5','10','25','50','100'],
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
							<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_codetables")>
								{text: 'Edit', datafield: 'Edit', width:60, columntype: 'button', hideable: false, cellsrenderer: editCellRenderer},
							</cfif>
							{text: 'Journal Name', datafield: 'journal_name', width:400, hideable: false },
							{text: 'Publications', datafield: 'publication_count', width:50, hideable: true, hidden: getColHidProp('publication_count', false), cellsrenderer: pubCellRenderer },
							{text: 'ISSN', datafield: 'issn', width:120, hideable: true, hidden: getColHidProp('issn', false) },
							{text: 'Start Year', datafield: 'start_year', width:80, hideable: true, hidden: getColHidProp('start_year', false) },
							{text: 'End Year', datafield: 'end_year', width:80, hideable: true, hidden: getColHidProp('end_year', false) },
							{text: 'Short Name', datafield: 'short_name', width:160, hidable: true, hidden: getColHidProp('short_name', false) },
							{text: 'Remarks', datafield: 'remarks', hideable: true, hidden: getColHidProp('remarks', false) }
						],
						rowdetails: true,
						rowdetailstemplate: {
							rowdetails: "<div style='margin: 10px;'>Row Details</div>",
							rowdetailsheight: 1 // row details will be placed in popup dialog
						},
						initrowdetails: initRowDetails
					});
					$("##searchResultsGrid").on("bindingcomplete", function(event) {
						// add a link out to this search, serializing the form as http get parameters
						$('##resultLink').html('<a href="/publications/Journals.cfm?execute=true&' + $('##searchForm :input').filter(function(index,element){return $(element).val()!='';}).serialize() + '">Link to this search</a>');
						gridLoaded('searchResultsGrid','serial/journal name record');
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
				/* End Setup jqxgrid for Search ******************************/

				// If requested in uri, execute search immediately.
				<cfif isdefined("execute")>
					$('##searchForm').submit();
				</cfif>
			}); /* End document.ready */


			<cfif isdefined("session.roles") AND listfindnocase(session.roles,"coldfusion_user") >
			function populateSaveSearch() { 
				// set up a dialog for saving the current search.
				var uri = "/publications/Journals.cfm?execute=true&" + $('##searchForm :input').filter(function(index,element){ return $(element).val()!='';}).not(".excludeFromLink").serialize();
				$("##saveDialog").html(
					"<div class='row'>"+ 
					"<form id='saveForm'> " + 
					" <input type='hidden' value='"+uri+"' name='url'>" + 
					" <div class='col-12'>" + 
					"  <label for='search_name_input'>Search Name</label>" + 
					"  <input type='text' id='search_name_input'  name='search_name' value='' class='data-entry-input reqdClr' pattern='Your name for this search' maxlenght='60' required>" + 
					" </div>" + 
					" <div class='col-12'>" + 
					"  <label for='execute_input'>Execute Immediately</label>"+
					"  <input id='execute_input' type='checkbox' name='execute' checked>"+
					" </div>" +
					"</form>"+
					"</div>"
				);
			}
			</cfif>

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
				var filename = searchType.replace(/[ ]/g,'_') + '_results_' + nowstring + '.csv';
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
					$('##' + gridId).jqxGrid({ pagesizeoptions: ['5','10','25','50', '100', rowcount],pagesize: 50});
				} else if (rowcount > 50) { 
					$('##' + gridId).jqxGrid({ pagesizeoptions: ['5','10','25','50', rowcount],pagesize:50});
				} else if (rowcount > 25) { 
					$('##' + gridId).jqxGrid({ pagesizeoptions: ['5','10','25', rowcount],pagesize:25});
				} else if (rowcount > 10) { 
					$('##' + gridId).jqxGrid({ pagesizeoptions: ['5','10', rowcount],pagesize:10});
				} else { 
					$('##' + gridId).jqxGrid({ pageable: false });
				}
				// add a control to show/hide columns
				var columns = $('##' + gridId).jqxGrid('columns').records;
				var columnslength = columns.length
				<!--- leave off columns where hidable = false --->
				<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_codetables")>
					columnslength = columnslength - 2;
				<cfelse>
					columnslength = columnslength - 1;
				</cfif>
				var halfcolumns = Math.round(columnslength/2);
				var columnListSource = [];
				for (i = 1; i < halfcolumns; i++) {
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
				var columnListSource1 = [];
				for (i = halfcolumns; i < columnslength; i++) {
					var text = columns[i].text;
					var datafield = columns[i].datafield;
					var hideable = columns[i].hideable;
					var hidden = columns[i].hidden;
					var show = ! hidden;
					if (hideable == true) { 
						var listRow = { label: text, value: datafield, checked: show };
						columnListSource1.push(listRow);
					}
				} 
				$("##columnPick1").jqxListBox({ source: columnListSource1, autoHeight: true, width: '260px', checkboxes: true });
				$("##columnPick1").on('checkChange', function (event) {
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
					width: 'auto',
					adaptivewidth: true,
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
					"<button id='columnPickDialogOpener' onclick=\" $('##columnPickDialog').dialog('open'); \" class='btn btn-xs btn-secondary my-2 mx-1' >Show/Hide Columns</button>"
				);

				<cfif isdefined("session.roles") AND listfindnocase(session.roles,"coldfusion_user") >
					$("##saveDialog").dialog({
						height: 'auto',
						width: 'auto',
						adaptivewidth: true,
						title: 'Save Search',
						autoOpen: false,
						modal: true,
						reszable: true,
						buttons: [
							{
								text: "Save",
								click: function(){
									var url = $('##saveForm :input[name=url]').val();
									var execute = $('##saveForm :input[name=execute]').is(':checked');
									var search_name = $('##saveForm :input[name=search_name]').val();
									saveSearch(url, execute, search_name,"actionFeedback");
									$(this).dialog("close"); 
								},
								tabindex: 0
							},
							{
								text: "Cancel",
								click: function(){ 
									$(this).dialog("close"); 
								},
								tabindex: 0
							}
						],
						open: function (event, ui) {
							var maxZIndex = getMaxZIndex();
							// force to lie above the jqx-grid-cell and related elements, see z-index workaround below
							$('.ui-dialog').css({'z-index': maxZIndex + 4 });
							$('.ui-widget-overlay').css({'z-index': maxZIndex + 3 });
						}
					});
					$("##saveDialogButton").html(
					`<button id="`+gridId+`saveDialogOpener"
							onclick=" populateSaveSearch(); $('##saveDialog').dialog('open'); " 
							class="btn btn-xs btn-secondary mx-1 my-2" >Save Search</button>
					`);
				</cfif>

				// workaround for menu z-index being below grid cell z-index when grid is created by a loan search.
				// likewise for the popup menu for searching/filtering columns, ends up below the grid cells.
				var maxZIndex = getMaxZIndex();
				$('.jqx-grid-cell').css({'z-index': maxZIndex + 1});
				$('.jqx-grid-group-cell').css({'z-index': maxZIndex + 1});
				$('.jqx-menu-wrapper').css({'z-index': maxZIndex + 2});
				$('##resultDownloadButtonContainer').html('<button id="loancsvbutton" class="btn btn-xs btn-secondary mx-1 my-2" aria-label="Export results to csv" onclick=" exportGridToCSV(\'searchResultsGrid\', \''+filename+'\'); " >Export to CSV</button>');
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
	
<cfinclude template = "/shared/_footer.cfm">
