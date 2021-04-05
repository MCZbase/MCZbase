<!---
/Agents.cfm

Agent search/results 

Copyright 2021 President and Fellows of Harvard College

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
<cfset pageTitle = "Search Agents">
<cfinclude template = "/shared/_header.cfm">

<cfquery name="dist_prefix" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select distinct(prefix) as dist_prefix from person where prefix is not null
</cfquery>
<cfquery name="dist_suffix" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select distinct(suffix) as dist_suffix from person where suffix is not null
</cfquery>
<cfquery name="ctagent_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select agent_type  from ctagent_type
</cfquery>

<div id="overlaycontainer" style="position: relative;"> 
	<!--- ensure fields have empty values present if not defined. --->
	<cfif not isdefined("prefix")> 
		<cfset prefix="">
	</cfif>
	<cfif not isdefined("suffix")> 
		<cfset suffix="">
	</cfif>
	<cfif not isdefined("anyName")> 
		<cfset anyName="">
	</cfif>
	<cfif not isdefined("agent_remarks")> 
		<cfset agent_remarks="">
	</cfif>
	<cfif not isdefined("last_name")> 
		<cfset last_name="">
	</cfif>
	<cfif not isdefined("middle_name")> 
		<cfset middle_name="">
	</cfif>
	<cfif not isdefined("first_name")> 
		<cfset first_name="">
	</cfif>
	<cfif NOT isDefined("agent_type")>
		<cfset in_agent_type="">
	<cfelse>
		<cfset in_agent_type="#agent_type#">
	</cfif>
	<!--- Search Form ---> 
	<cfoutput>
		<main id="content">
			<section class="container-fluid mt-2 mb-3" role="search" aria-labelledby="formheader">
				<div class="row mx-0 mb-3">
					<div class="search-box">
						<div class="search-box-header">
							<h1 class="h3 text-white" id="formheading">Find Agents</h1>
						</div>
						<div class="col-12 px-4 pt-3 pb-2">
							<form name="searchForm" id="searchForm">
								<input type="hidden" name="method" value="getAgents">
								<div class="form-row mb-2">
									<div class="col-md-5">
										<label for="anyName" class="data-entry-label" id="anyName_label">Any part of any name</label>
										<input type="text" id="anyName" name="anyName" class="data-entry-input" value="#anyName#" aria-labelledby="anyName_label" >
									</div>
									<div class="col-md-5">
										<label for="agent_remarks" class="data-entry-label" id="agent_remarks_label">Agent Remarks</label>
										<input type="text" id="agent_remarks" name="agent_remarks" class="data-entry-input" value="#agent_remarks#" aria-labelledby="agent_remarks_label" >
									</div>
									<div class="col-md-2">
										<label for="agent_type" class="data-entry-label" id="agent_type_label">Agent Type</label>
										<select id="agent_type" name="agent_type" class="data-entry-select">
											<option></option>
											<cfloop query="ctagent_type">
												<cfif in_agent_type EQ ctagent_type.agent_type><cfset selected="selected='true'"><cfelse><cfset selected=""></cfif>
												<option value="#ctagent_type.agent_type#" #selected#>#ctagent_type.agent_type#</option>
											</cfloop>
											<cfloop query="ctagent_type">
												<cfif in_agent_type EQ "!#ctagent_type.agent_type#"><cfset selected="selected='true'"><cfelse><cfset selected=""></cfif>
												<option value="!#ctagent_type.agent_type#" #selected#>not #ctagent_type.agent_type#</option>
											</cfloop>
										</select>
									</div>
								</div>
								<div class="form-row mb-2">
									<div class="col-md-2">
										<label for="prefix" class="data-entry-label" id="prefix_label">Prefix</label>
										<select id="prefix" name="prefix" class="data-entry-select">
											<option></option>
											<cfloop query="dist_prefix">
												<cfif prefix EQ dist_prefix.dist_prefix><cfset selected="selected='true'"><cfelse><cfset selected=""></cfif>
												<option value="#dist_prefix.dist_prefix#" #selected#>#dist_prefix.dist_prefix#</option>
											</cfloop>
											<cfloop query="dist_prefix">
												<cfif prefix EQ "!#dist_prefix.dist_prefix#"><cfset selected="selected='true'"><cfelse><cfset selected=""></cfif>
												<option value="!#dist_prefix.dist_prefix#" #selected#>not #dist_prefix.dist_prefix#</option>
											</cfloop>
											<option value="NULL">NULL</option>
											<option value="NOT NULL">NOT NULL</option>
										</select>
									</div>
									<div class="col-md-3">
										<label for="first_name" class="data-entry-label" id="first_name_label">First Name</label>
										<input type="text" id="first_name" name="first_name" class="data-entry-input" value="#first_name#" aria-labelledby="first_name_label" >
									</div>
									<div class="col-md-2">
										<label for="middle_name" class="data-entry-label" id="middle_name_label">Middle Name</label>
										<input type="text" id="middle_name" name="middle_name" class="data-entry-input" value="#middle_name#" aria-labelledby="middle_name_label" >
									</div>
									<div class="col-md-3">
										<label for="last_name" class="data-entry-label" id="last_name_label">Last Name</label>
										<input type="text" id="last_name" name="last_name" class="data-entry-input" value="#last_name#" aria-labelledby="last_name_label" >
									</div>
									<div class="col-md-2">
										<label for="suffix" class="data-entry-label" id="suffix_label">Suffix</label>
										<select id="suffix" name="suffix" class="data-entry-select">
											<option></option>
											<cfloop query="dist_suffix">
												<cfif suffix EQ dist_suffix.dist_suffix><cfset selected="selected='true'"><cfelse><cfset selected=""></cfif>
												<option value="#dist_suffix.dist_suffix#" #selected#>#dist_suffix.dist_suffix#</option>
											</cfloop>
											<cfloop query="dist_suffix">
												<cfif suffix EQ "!#dist_suffix.dist_suffix#"><cfset selected="selected='true'"><cfelse><cfset selected=""></cfif>
												<option value="!#dist_suffix.dist_suffix#" #selected#>not #dist_suffix.dist_suffix#</option>
											</cfloop>
											<option value="NULL">NULL</option>
											<option value="NOT NULL">NOT NULL</option>
										</select>
									</div>
								</div>
								<div class="form-row mb-2">
									<div class="col-md-4">
										<div class="date row bg-light border pb-2 mb-2 mb-md-0 pt-1 px-0 px-md-1 px-xl-1 mx-0 rounded justify-content-center">
											<label class="data-entry-label px-4 px-md-4 mx-1 mb-0" for="birth_date">Date Of Birth</label>
											<input name="birth_date" id="birth_date" type="text" class="datetimeinput data-entry-input col-4 col-xl-5" placeholder="start yyyy-mm-dd or yyyy" value="#birth_date#" aria-label="start of range for date of birth">
											<div class="col-1 col-xl-1 text-center px-0"><small> to</small></div>
											<label class="data-entry-label sr-only" for="to_birth_date">end of search range for date of birth</label>		
											<input type="text" name="to_birth_date" id="to_birth_date" value="#to_birth_date#" class="datetimeinput col-4 col-xl-4 data-entry-input" placeholder="end yyyy-mm-dd or yyyy" title="end of date range">
										</div>
									</div>
									<div class="col-md-4">
										<div class="date row bg-light border pb-2 mb-2 mb-md-0 pt-1 px-0 px-md-1 px-xl-1 mx-0 rounded justify-content-center">
											<label class="data-entry-label px-4 px-md-4 mx-1 mb-0" for="death_date">Date Of Death</label>
											<input name="death_date" id="death_date" type="text" class="datetimeinput data-entry-input col-4 col-xl-5" placeholder="start yyyy-mm-dd or yyyy" value="#death_date#" aria-label="start of range for date of death">
											<div class="col-1 col-xl-1 text-center px-0"><small> to</small></div>
											<label class="data-entry-label sr-only" for="to_death_date">end of search range for date of death</label>		
											<input type="text" name="to_death_date" id="to_death_date" value="#to_death_date#" class="datetimeinput col-4 col-xl-4 data-entry-input" placeholder="end yyyy-mm-dd or yyyy" title="end of date range">
										</div>
									</div>
									<div class="col-md-4">
										<div class="date row bg-light border pb-2 mb-2 mb-md-0 pt-1 px-0 px-md-1 px-xl-1 mx-0 rounded justify-content-center">
											<label class="data-entry-label px-4 px-md-4 mx-1 mb-0" for="collected_date">Dates Collected</label>
											<input name="collected_date" id="collected_date" type="text" class="datetimeinput data-entry-input col-4 col-xl-5" placeholder="start yyyy-mm-dd or yyyy" value="#collected_date#" aria-label="start of range for dates collected">
											<div class="col-1 col-xl-1 text-center px-0"><small> to</small></div>
											<label class="data-entry-label sr-only" for="to_collected_date">end of search range for dates collected</label>
											<input type="text" name="to_collected_date" id="to_collected_date" value="#to_collected_date#" class="datetimeinput col-4 col-xl-4 data-entry-input" placeholder="end yyyy-mm-dd or yyyy" title="end of date range">
										</div>
									</div>
								</div>
								<div class="form-row my-2 mx-0">
									<div class="col-12 px-0 pt-2">
										<button class="btn-xs btn-primary px-2 my-2 mr-1" id="searchButton" type="submit" aria-label="Search for agents">Search<span class="fa fa-search pl-1"></span></button>
										<button type="reset" class="btn-xs btn-warning my-2 mr-1" aria-label="Reset search form to inital values" onclick="">Reset</button>
										<button type="button" class="btn-xs btn-warning my-2 mr-1" aria-label="Start a new collection search with a clear form" onclick="window.location.href='#Application.serverRootUrl#/Agents.cfm';" >New Search</button>
									</div>
								</div>
							</form>
						</div><!--- col --->
					</div><!--- search box --->
				</div><!--- row --->
			</section>
		
			<!--- Results table as a jqxGrid. --->
			<section class="container-fluid">
				<div class="row mx-0">
					<div class="col-12">
						<div class="mb-5">
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
				</div>
			</section>
		</main>

		<script>
			var linkIdCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
				var rowData = jQuery("##searchResultsGrid").jqxGrid('getrowdata',row);
				var vetted = rowData['edited'];
				return '<span style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; "><a href="/editAllAgent.cfm?agent_id=' + rowData['agent_id'] + '">'+value+'</a> ' +vetted+ '</span>';
			};
	
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
							{ name: 'agent_id', type: 'string' },
							{ name: 'agent_name', type: 'string' },
							{ name: 'prefix', type: 'string' },
							{ name: 'first_name', type: 'string' },
							{ name: 'middle_name', type: 'string' },
							{ name: 'last_name', type: 'string' },
							{ name: 'suffix', type: 'string' },
							{ name: 'agent_type', type: 'string' },
							{ name: 'edited', type: 'string' },
							<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_transactions")>
								{ name: 'worstagentrank', type: 'string' },
							</cfif>
							{ name: 'birth_date', type: 'string' },
							{ name: 'death_date', type: 'string' },
							{ name: 'agent_remarks', type: 'string' },
							{ name: 'abbreviation', type: 'string' },
							{ name: 'preferred', type: 'string' },
							{ name: 'acronym', type: 'string' },
							{ name: 'aka', type: 'string' },
							{ name: 'author', type: 'string' },
							{ name: 'second_author', type: 'string' },
							{ name: 'expanded', type: 'string' },
							{ name: 'full', type: 'string' },
							{ name: 'initials', type: 'string' },
							{ name: 'initials_plus_last', type: 'string' },
							{ name: 'last_plus_initials', type: 'string' },
							<cfif isdefined("session.roles") and listfindnocase(session.roles,"global_admin")>
								{ name: 'login', type: 'string' },
							</cfif>
							{ name: 'maiden', type: 'string' },
							{ name: 'married', type: 'string' },
							{ name: 'agentguid', type: 'string' }
						],
						updaterow: function (rowid, rowdata, commit) {
							commit(true);
						},
						root: 'agentRecord',
						id: 'agent_id',
						url: '/agents/component/search.cfc?' + $('##searchForm').serialize(),
						timeout: 30000,  // units not specified, miliseconds? 
						loadError: function(jqXHR, status, error) { 
							$("##overlay").hide();
							var message = "";
							if (error == 'timeout') { 
								message = ' Server took too long to respond.';
							} else { 
								message = jqXHR.responseText;
							}
							messageDialog('Error:' + message,'Error: ' + error.substring(0,50));
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
							{text: 'ID', datafield: 'agent_id', width:100, hideable: true, hidden: true },
							{text: 'Name', datafield: 'agent_name', width: 300, hidable: true, hidden: false, cellsrenderer: linkIdCellRenderer },
							{text: 'Vetted', datafield: 'edited', width: 80, hidable: true, hidden: false },
							<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_transactions")>
								{text: 'Rank', datafield: 'worstagentrank', width: 80, hidable: true, hidden: false },
							</cfif>
							{text: 'Prefix', datafield: 'prefix', width: 60, hidable: true, hidden: true },
							{text: 'First', datafield: 'first_name', width: 100, hidable: true, hidden: true },
							{text: 'Middle', datafield: 'middle_name', width: 100, hidable: true, hidden: true },
							{text: 'Last', datafield: 'last_name', width: 100, hidable: true, hidden: true },
							{text: 'Suffix', datafield: 'suffix', width: 60, hidable: true, hidden: true },
							{text: 'Type', datafield: 'agent_type', width: 150, hidable: true, hidden: false },
							{text: 'Birth', datafield: 'birth_date', width:100, hideable: true, hidden: false },
							{text: 'Death', datafield: 'death_date', width:100, hideable: true, hidden: false },
							{text: 'preferred', datafield: 'preferred', width:100, hideable: true, hidden: true },
							{text: 'abbreviation', datafield: 'abbreviation', width:100, hideable: true, hidden: true },
							{text: 'acronym', datafield: 'acronym', width:100, hideable: true, hidden: true },
							{text: 'aka', datafield: 'aka', width:100, hideable: true, hidden: true },
							{text: 'author', datafield: 'author', width:100, hideable: true, hidden: true },
							{text: 'second_author', datafield: 'second_author', width:100, hideable: true, hidden: true },
							{text: 'expanded', datafield: 'expanded', width:100, hideable: true, hidden: true },
							{text: 'maiden', datafield: 'maiden', width:100, hideable: true, hidden: true },
							{text: 'married', datafield: 'married', width:100, hideable: true, hidden: true },
							{text: 'full', datafield: 'full', width:100, hideable: true, hidden: true },
							{text: 'initials', datafield: 'initials', width:100, hideable: true, hidden: true },
							{text: 'initials_plus_last', datafield: 'initials_plus_last', width:100, hideable: true, hidden: true },
							{text: 'last_plus_initials', datafield: 'last_plus_initials', width:100, hideable: true, hidden: true },
							<cfif isdefined("session.roles") and listfindnocase(session.roles,"global_admin")>
								{text: 'login', datafield: 'login', width:100, hideable: true, hidden: true },
							</cfif>
							{text: 'Guid', datafield: 'agentguid', width:150, hideable: true, hidden: false },
							{text: 'Remarks', datafield: 'agent_remarks', hideable: true, hidden: false },
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
						$('##resultLink').html('<a href="/Agents.cfm?execute=true&' + $('##searchForm').serialize() + '">Link to this search</a>');
						gridLoaded('searchResultsGrid','agent');
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

			function gridLoaded(gridId, searchType) { 
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
					$('##' + gridId).jqxGrid({ pagesizeoptions: ['5','50', '100', rowcount],pagesize: 50});
				} else if (rowcount > 50) { 
					$('##' + gridId).jqxGrid({ pagesizeoptions: ['5','50', rowcount],pagesize:50});
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
						// force to lie above the jqx-grid-cell and related elements, see z-index workaround below
						$('.ui-dialog').css({'z-index': maxZIndex + 4 });
						$('.ui-widget-overlay').css({'z-index': maxZIndex + 3 });
					} 
				});
				$("##columnPickDialogButton").html(
					"<button id='columnPickDialogOpener' onclick=\" $('##columnPickDialog').dialog('open'); \" class='btn-xs btn-secondary px-3 py-1 mt-2 mx-3' >Show/Hide Columns</button>"
				);
				// workaround for menu z-index being below grid cell z-index when grid is created by a loan search.
				// likewise for the popup menu for searching/filtering columns, ends up below the grid cells.
				var maxZIndex = getMaxZIndex();
				$('.jqx-grid-cell').css({'z-index': maxZIndex + 1});
				$('.jqx-grid-group-cell').css({'z-index': maxZIndex + 1});
				$('.jqx-menu-wrapper').css({'z-index': maxZIndex + 2});
				$('##resultDownloadButtonContainer').html('<button id="loancsvbutton" class="btn-xs btn-secondary px-3 py-1 mt-2 mx-0" aria-label="Export results to csv" onclick=" exportGridToCSV(\'searchResultsGrid\', \''+filename+'\'); " >Export to CSV</button>');
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
