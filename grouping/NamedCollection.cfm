<!---
grouping/NamedCollection.cfm

For managing arbitrary groupings of collection objects.

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
	<cfset action="search">
</cfif>
<cfswitch expression="#action#">
	<cfcase value="search">
		<cfset pageTitle = "Search Named Collections">
	</cfcase>
	<cfcase value="new">
		<cfset pageTitle = "Add New Named Collection">
	</cfcase>
	<cfcase value="edit">
		<cfset pageTitle = "Edit a Named_ Collection">
	</cfcase>
	<cfdefaultcase>
		<cfset pageTitle = "Named Collection">
	</cfdefaultcase>
</cfswitch>
<!---------------------------------------------------------------------------------->
<cfset includeJQXEditor='true'>
<cfinclude template = "/shared/_header.cfm">
<cfswitch expression="#action#">
	<!--- Check for finer granularity permissions than rolecheck called in _header.cfm provides --->
	<cfcase value="new">
		<cfif NOT isdefined("session.roles") OR NOT listfindnocase(session.roles,"manage_specimens")>
			<cfthrow message="Insufficient permissions to add a new named group of cataloged items.">
		</cfif>
	</cfcase>
	<cfcase value="edit">
		<cfif NOT isdefined("session.roles") OR NOT listfindnocase(session.roles,"manage_specimens")>
			<cfthrow message="Insufficient permissions to edit a named group of cataloged items.">
		</cfif>
	</cfcase>
</cfswitch>
<!---------------------------------------------------------------------------------->
<cfswitch expression="#action#">
	<cfcase value="search">
		<cfquery name="colls" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="colls_result">
			select collection_id, collection_cde, collection from collection
		</cfquery>
		<div id="overlaycontainer" style="position: relative;"> 
			<!--- ensure fields have empty values present if not defined. --->
			<cfif not isdefined("collection_name")> <!--- the name of the underscore_collection/named group --->
				<cfset collection_name="">
			</cfif>
			<cfif not isdefined("description")>
				<cfset description="">
			</cfif>
			<cfif not isdefined("html_description")>
				<cfset html_description="">
			</cfif>
			<cfif not isdefined("guid")>
				<cfset guid="">
			</cfif>
			<cfif not isdefined("collection_id")> <!--- not the underscore_collection, the departmental collection --->
				<cfset collection_id="">
			</cfif>
			<cfset pcollection_id = collection_id>
			<cfif not isdefined("underscore_agent_name")>
				<cfset underscore_agent_name="">
			</cfif>
			<cfif not isdefined("underscore_agent_id")>
				<cfset underscore_agent_id="">
			</cfif>
			<cfif len(underscore_agent_id) EQ 0>
				<cfset underscore_agent_name="">
			</cfif>
			<!--- Search Form ---> 
			<cfoutput>
				<main id="content">
					<section class="container-fluid mt-2 mb-3" role="search" aria-labelledby="formheader">
						<div class="row mx-0 mb-3">
							<div class="search-box">
								<div class="search-box-header">
									<h1 class="h3 text-white" id="formheading">Find named groups of cataloged items</h1>
								</div>
								<div class="col-12 px-4 pt-3 pb-2">
									<form name="searchForm" id="searchForm">
										<input type="hidden" name="method" value="getCollections" class="keeponclear">
										<div class="form-row mt-1 mb-2">
											<div class="col-md-5">
												<label for="collection_name" class="data-entry-label" id="collection_name_label">Name for the group of cataloged items</label>
												<input type="text" id="collection_name" name="collection_name" class="data-entry-input" value="#collection_name#" aria-labelledby="collection_name_label" >
												<script>
													$(document).ready(function() {
														makeNamedCollectionPicker('collection_name',null);
													});
												</script>
											</div>
											<div class="col-md-5">
												<label for="description" class="data-entry-label" id="description_label">Description</label>
												<input type="text" id="description" name="description" class="data-entry-input" value="#description#" aria-labelledby="description_label" >
											</div>
											<div class="col-md-2">
												<label for="mask_fg" class="data-entry-label">Record Visibility</label>
												<select name="mask_fg" id="mask_fg" class="data-entry-select">
													<cfset masknullselect = 'selected="selected"'>
													<cfset mask0select = "">
													<cfset mask1select = "">
													<cfif isDefined("mask_fg")>
														<cfif mask_fg EQ 0>
															<cfset masknullselect = "">
															<cfset mask0select = 'selected="selected"'>
															<cfset mask1select = "">
														<cfelseif mask_fg EQ 1>
															<cfset masknullselect = "">
															<cfset mask0select = "">
															<cfset mask1select = 'selected="selected"'>
														</cfif>
													</cfif>
													<option value="" #masknullselect#></option>
													<option value="0" #mask0select#>Public</option>
													<option value="1" #mask1select#>Hidden</option>
												</select>
											</div>
										</div>
										<div class="form-row mb-2">
											<div class="col-12 mt-1 col-md-6">
												<label for="guid" class="data-entry-label" id="guid_label">A cataloged item that is a member of the named group (NULL finds empty groups).</label>
												<input type="text" id="guid" name="guid" class="data-entry-input" value="#guid#" aria-labelledby="guid_label" placeholder="MCZ:Coll:nnnnn" >
											</div>
											<div class="col-12 mt-1 col-md-2">
												<label for="coll" class="data-entry-label" id="coll_label">Collection holding cataloged items</label>
												<select id="coll" name="collection_id" class="data-entry-select" aria-labelledby="coll_label" >
													<!--- NOTE: current UI support is for just one collection, though backing method can take list of collection_id values --->
													<option value=""></option>
													<cfloop query="colls">
														<cfif pcollection_id eq "#colls.collection_id#" >
															<cfset selected="selected">
														<cfelse>
															<cfset selected="">
														</cfif>
														<option value="#colls.collection_id#" #selected# >#colls.collection#</option>
													</cfloop>
												</select>
											</div>
											<div class="col-12 mt-1 col-md-4">
												<label for="underscore_agent_name" id="underscore_agent_name_label" class="data-entry-label pb-0">Agent Associated with this Collection (use <i>[no agent data]</i> for no agent)
													<h5 id="underscore_agent_view" class="d-inline">&nbsp;&nbsp;&nbsp;&nbsp;</h5> 
												</label>
												<div class="input-group">
													<div class="input-group-prepend">
														<span class="input-group-text smaller bg-lightgreen" id="underscore_agent_name_icon"><i class="fa fa-user" aria-hidden="true"></i></span> 
													</div>
													<input type="text" name="underscore_agent_name" id="underscore_agent_name" class="form-control rounded-right data-entry-input form-control-sm" aria-label="Agent Name" aria-describedby="underscore_agent_name_label" value="#underscore_agent_name#">
													<input type="hidden" name="underscore_agent_id" id="underscore_agent_id" value="#underscore_agent_id#">
												</div>
											</div>
											<script>
												$(document).ready(function() {
													$(makeRichAgentPicker('underscore_agent_name', 'underscore_agent_id', 'underscore_agent_name_icon', 'underscore_agent_view', '#underscore_agent_id#'));
												});
											</script>
										</div>
										<div class="form-row mt-2 mx-0">
											<div class="col-12 px-0 pt-0">
												<button class="btn-xs btn-primary px-2 my-2 mr-1" id="searchButton" type="submit" aria-label="Search for named collections">Search<span class="fa fa-search pl-1"></span></button>
												<button type="reset" class="btn-xs btn-warning my-2 mr-1" aria-label="Reset search form to inital values" onclick="">Reset</button>
												<button type="button" class="btn-xs btn-warning my-2 mr-1" aria-label="Start a new collection search with a clear form" onclick="window.location.href='#Application.serverRootUrl#/grouping/NamedCollection.cfm?action=search';" >New Search</button>
												<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_specimens")>
													<button type="button" class="btn-xs btn-secondary my-2" aria-label="Create a new named collection" onclick="window.location.href='#Application.serverRootUrl#/grouping/NamedCollection.cfm?action=new';" >Create new named group of cataloged items</button>
												</cfif>
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
		
				<cfset cellRenderClasses = "ml-1">
				<script>
					window.columnHiddenSettings = new Object();
					<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
						lookupColumnVisibilities ('#cgi.script_name#','Default');
					</cfif>

					var linkIdCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
						var rowData = jQuery("##searchResultsGrid").jqxGrid('getrowdata',row);
						<cfif findNoCase('redesign',gitBranch) EQ 0>
							return '<span class="#cellRenderClasses#" style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; ">'+value+'</span>';
						<cfelse>
							return '<span class="#cellRenderClasses#" style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; "><a href="/grouping/showNamedCollection.cfm?underscore_collection_id=' + rowData['UNDERSCORE_COLLECTION_ID'] + '">'+value+'</a></span>';
						</cfif>
					};
					<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_specimens")>
						var editCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
							var rowData = jQuery("##searchResultsGrid").jqxGrid('getrowdata',row);
							return '<span class="cellRenderClasses" style="margin: 6px; display:block; float: ' + columnproperties.cellsalign + '; "><a target="_blank" class="px-2 btn-xs btn-outline-primary" href="/grouping/NamedCollection.cfm?action=edit&underscore_collection_id=' + rowData['UNDERSCORE_COLLECTION_ID'] + '">Edit</a></span>';
							return '<span class="#cellRenderClasses#" style="margin: 6px; display:block; float: ' + columnproperties.cellsalign + '; "><a target="_blank" class="px-2 btn-xs btn-outline-primary" href="#Application.serverRootUrl#/taxonomy/Taxonomy.cfm?action=edit&taxon_name_id=' + value + '">Edit</a></span>';
						};
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
									{ name: 'UNDERSCORE_COLLECTION_ID', type: 'string' },
									{ name: 'COLLECTION_NAME', type: 'string' },
									{ name: 'DESCRIPTION', type: 'string' },
									{ name: 'UNDERSCORE_AGENT_ID', type: 'string' },
									{ name: 'AGENTNAME', type: 'string' },
									{ name: 'SPECIMEN_COUNT', type: 'string' },
									{ name: 'HTML_DESCRIPTION', type: 'string' }
								],
								updaterow: function (rowid, rowdata, commit) {
									commit(true);
								},
								root: 'underscoreCollectionRecord',
								id: 'underscore_collection_id',
								url: '/grouping/component/search.cfc?' + $('##searchForm').serialize(),
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
									{text: 'Name', datafield: 'COLLECTION_NAME', width: 300, hidable: true, hidden: getColHidProp('COLLECTION_NAME', false), cellsrenderer: linkIdCellRenderer },
									<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_specimens")>
										{text: 'ID', datafield: 'UNDERSCORE_COLLECTION_ID', width:100, hideable: true, hidden: getColHidProp('UNDERSCORE_COLLECTION_ID', false), cellsrenderer: editCellRenderer },
									<cfelse>
										{text: 'ID', datafield: 'UNDERSCORE_COLLECTION_ID', width:100, hideable: true, hidden: getColHidProp('UNDERSCORE_COLLECTION_ID', true) },
									</cfif>
									{text: 'Agent', datafield: 'AGENTNAME', width: 150, hidable: true, hidden: getColHidProp('AGENTNAME', false) },
									{text: 'AgentID', datafield: 'UNDERSCORE_AGENT_ID', width:100, hideable: true, hidden: getColHidProp('UNDERSCORE_AGENT_ID', true) },
									{text: 'Specimen Count', datafield: 'SPECIMEN_COUNT', width:150, hideable: true, hidden: getColHidProp('SPECIMEN_COUNT', false) },
									{text: 'Featured Data', datafield: 'HTML_DESCRIPTION', hideable: true, hidden: getColHidProp('HTML_DESCRIPTION', true) },
									{text: 'Description', datafield: 'DESCRIPTION', hideable: true, hidden: getColHidProp('DESCRIPTION', false) }
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
								$('##resultLink').html('<a href="/grouping/NamedCollection.cfm?action=search&execute=true&' + $('##searchForm').serialize() + '">Link to this search</a>');
								gridLoaded('searchResultsGrid','collection');
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
							"<button id='columnPickDialogOpener' onclick=\" $('##columnPickDialog').dialog('open'); \" class='btn-xs btn-secondary px-3 py-1 mt-1 mx-3' >Show/Hide Columns</button>"
						);
						// workaround for menu z-index being below grid cell z-index when grid is created by a loan search.
						// likewise for the popup menu for searching/filtering columns, ends up below the grid cells.
						var maxZIndex = getMaxZIndex();
						$('.jqx-grid-cell').css({'z-index': maxZIndex + 1});
						$('.jqx-grid-group-cell').css({'z-index': maxZIndex + 1});
						$('.jqx-menu-wrapper').css({'z-index': maxZIndex + 2});
						$('##resultDownloadButtonContainer').html('<button id="loancsvbutton" class="btn-xs btn-secondary px-3 py-1 mt-1 mx-0" aria-label="Export results to csv" onclick=" exportGridToCSV(\'searchResultsGrid\', \''+filename+'\'); " >Export to CSV</button>');
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
		<!--- Add a new ____ collection, link to agent ---> 
		<cfoutput>
			<main class="container mt-3">
				<section class="row">
					<div class="col-12">
						<h1 class="h2 pl-2 ml-2" id="formheading">New named group of cataloged items</h1>
						<div class="border rounded px-2 pt-2" aria-labelledby="formheading">
							<form name="newUnderscoreCollection" id="newUnderscoreCollection" action="/grouping/NamedCollection.cfm" method="post" class="px-2">
								<input type="hidden" id="action" name="action" value="saveNew" >
								<div class="form-row mt-2 mb-2">
									<div class="col-md-9">
										<label for="collection_name" id="collection_name_label" class="data-entry-label">Name for the Group of cataloged items</label>
										<input type="text" id="collection_name" name="collection_name" class="data-entry-input reqdClr" required aria-labelledby="collection_name_label" >
									</div>
									<div class="col-md-3">
										<label for="mask_fg" class="data-entry-label">Record Visibility</label>
										<select name="mask_fg" id="mask_fg" required class="data-entry-select reqdClr"> 
											<option value="" selected="selected"></option>
											<option value="0">Public</option>
											<option value="1">Hidden</option>
										</select>
									</div>
								</div>
								<div class="form-row mb-2">
									<div class="col-md-12">
										<label for="description" id="description_label" class="data-entry-label">Description (<span id="length_description">0 characters, 4000 left</span>)</label>
										<textarea id="description" name="description" class="data-entry-textarea mt-0"
												onkeyup="countCharsLeft('description',4000,'length_description');"
												rows="3" aria-labelledby="description_label" ></textarea>
									</div>
									<script>
										$(document).ready(function() {
											$('##description').keyup(autogrow);
										});
									</script>
								</div>
								<div class="form-row mb-2">
									<div class="col-md-12">
										<label for="html_description" id="html_description_label" class="data-entry-label">Featured Data</label>
										<textarea id="html_description" name="html_description"											aria-labelledby="html_description_label" ></textarea>
									</div>
									<script>
										$(document).ready(function () {
											$('##html_description').jqxEditor({
												height: 400, maxWidth: 800, resizable: true
											});
										});
									</script>

								</div>
								<div class="form-row mb-1">
									<div class="col-12 col-md-6">
										<span>
											<label for="underscore_agent_name" id="underscore_agent_name_label" class="data-entry-label">Agent Associated with this Collection
											<span id="underscore_agent_view">&nbsp;&nbsp;&nbsp;&nbsp;</span> 
											</label>
										</span>
										<div class="input-group">
											<div class="input-group-prepend">
												<span class="input-group-text smaller bg-light" id="underscore_agent_name_icon"><i class="fa fa-user" aria-hidden="true"></i></span> 
											</div>
											<input type="text" name="underscore_agent_name" id="underscore_agent_name" class="form-control form-control-sm rounded-right data-entry-input" value="" aria-label="Agent associated with this named collection:" aria-describedby="underscore_agent_name_label">
											<input type="hidden" name="underscore_agent_id" id="underscore_agent_id" value="">
										</div>
										<script>
											$(document).ready(function() {
												$(makeRichAgentPicker('underscore_agent_name', 'underscore_agent_id', 'underscore_agent_name_icon', 'underscore_agent_view', null));
											});
										</script> 
									</div>
								</div>
								<div class="form-row mb-1">
									<div class="col-12 row mx-0 px-1 my-3">
										<input type="button" 
													value="Create" title="Create" aria-label="Create"
													class="btn btn-xs btn-primary"
													onClick="if (checkFormValidity($('##newUnderscoreCollection')[0])) { submit(); } " 
													>
									</div>
								</div>
							</form>
						</div>
						<!--- region ---> 
					</div>
					<!--- col ---> 
				</section>
				<!--- section ---> 
			</main>
			<!--- container ---> 
		</cfoutput>
	</cfcase>
	<!---------------------------------------------------------------------------------->
	<cfcase value="saveNew">
		<cftry>
			<cfif not isdefined("collection_name") OR len(trim(#collection_name#)) EQ 0 >
				<cfthrow type="Application" message="Error: No value provided for required value collection_name">
			</cfif>
			<cfquery name="save" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="insertResult">
				insert into underscore_collection (
					collection_name
					<cfif isdefined("description")>
						,description
					</cfif>
					<cfif isdefined("html_description")>
						,html_description
					</cfif>
					<cfif isdefined("underscore_agent_id") and len(underscore_agent_id) GT 0 >
						,underscore_agent_id
					</cfif>
				) values (
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#collection_name#">
					<cfif isdefined("description")>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#description#">
					</cfif>
					<cfif isdefined("html_description")>
						,<cfqueryparam cfsqltype="CF_SQL_CLOB" value="#html_description#">
					</cfif>
					<cfif isdefined("underscore_agent_id") and len(underscore_agent_id) GT 0 >
						,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_agent_id#">
					</cfif>
				)
			</cfquery>
			<cfquery name="savePK" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="pkResult">
					select underscore_collection_id from underscore_collection 
					where ROWIDTOCHAR(rowid) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#insertResult.GENERATEDKEY#">
			</cfquery>
			<cflocation url="/grouping/NamedCollection.cfm?action=edit&underscore_collection_id=#savePK.underscore_collection_id#" addtoken="false">
			<cfcatch>
				<cfthrow type="Application" message="Error Saving new Named Collection: #cfcatch.Message# #cfcatch.Detail#">
			</cfcatch>
		</cftry>
	</cfcase>
	<!---------------------------------------------------------------------------------->
	<cfcase value="edit">
		<cfif not isDefined("underscore_collection_id")>
			<cfset underscore_collection_id = "">
		</cfif>
		<cfif len(underscore_collection_id) EQ 0>
			<cfthrow type="Application" message="Error: No value provided for underscore_collection_id">
		<cfelse>
			<cfquery name="undColl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="undColl_result">
				select underscore_collection_id, collection_name, description, underscore_agent_id, html_description,
					case 
						when underscore_agent_id is null then '[No Agent]'
						else MCZBASE.get_agentnameoftype(underscore_agent_id, 'preferred')
						end
					as agentname,
					mask_fg
				from underscore_collection
				where underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
			</cfquery>
			<cfoutput query="undColl">
				<cfset collname = collection_name>
				<!--- save name for later use outside this output section --->
				<main id="content" class="pb-5">
					<section class="container pt-3">
						<h1 class="h2" id="formheading"> Edit Named Group of Cataloged Items</h1>
					<div class="row border rounded py-3" aria-labelledby="formheading">
						<div class="col-12 px-3">
							<form name="editUndColl" id="editUndColl">
								<input type="hidden" id="underscore_collection_id" name="underscore_collection_id" value="#underscore_collection_id#" >
								<input type="hidden" id="method" name="method" value="saveUndColl" >
								<div class="form-row mb-2">
									<div class="col-12 col-md-9">
										<label for="collection_name" id="collection_name_label" class="data-entry-label">Name for the Group of cataloged items</label>
										<input type="text" id="collection_name" name="collection_name" class="data-entry-input reqdClr" 
												required value="#collection_name#" aria-labelledby="collection_name_label" >
									</div>
									<div class="col-md-3">
										<label for="mask_fg" class="data_entry_label">Record Visibility</label>
										<select name="mask_fg" id="mask_fg" required class="data-entry-select reqdClr">
											<cfif #undColl.mask_fg# eq 1 >
												<option value="0">Public</option>
												<option value="1" selected="selected">Hidden</option>
											<cfelse>
												<option value="0" selected="selected">Public</option>
												<option value="1">Hidden</option>
											</cfif>
										</select>
									</div>
								</div>
								<div class="form-row mb-2">
									<div class="col-12 col-md-12">
										<label for="description" id="description_label" class="data-entry-label">Description (<span id="length_description"></span>)</label>
										<textarea id="description" name="description" class="data-entry-textarea mt-0 autogrow"
												onkeyup="countCharsLeft('description',4000,'length_description');"
												rows="3" aria-labelledby="description_label" >#description#</textarea>
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
								</div>
								<div class="form-row mb-2">
									<div class="col-md-12">
										<label for="html_description" id="html_description_label" class="data-entry-label">Featured Data</label>
										<textarea id="html_description" name="html_description" class="w-100" aria-labelledby="html_description_label" >#html_description#</textarea>
									</div>
									<script>
										$(document).ready(function () {
											$('##html_description').jqxEditor();
										});
									</script>
								</div>
								<div class="form-row mb-0">
									<div class="col-12 col-md-6">
										<label for="underscore_agent_name" id="underscore_agent_name_label" class="data-entry-label">Agent Associated with this Collection
											<h5 id="underscore_agent_view" class="d-inline">&nbsp;&nbsp;&nbsp;&nbsp;</h5> 
										</label>
										<div class="input-group">
											<div class="input-group-prepend">
												<span class="input-group-text smaller bg-lightgreen" id="underscore_agent_name_icon"><i class="fa fa-user" aria-hidden="true"></i></span> 
											</div>
											<input type="text" name="underscore_agent_name" id="underscore_agent_name" class="form-control rounded-right data-entry-input form-control-sm" aria-label="Agent Name" aria-describedby="underscore_agent_name_label" value="#agentname#">
											<input type="hidden" name="underscore_agent_id" id="underscore_agent_id" value="#underscore_agent_id#">
										</div>
										<script>
												function changed(){
													$('##saveResultDiv').html('Unsaved changes.');
													$('##saveResultDiv').addClass('text-danger');
													$('##saveResultDiv').removeClass('text-success');
													$('##saveResultDiv').removeClass('text-warning');
												};
												$(document).ready(function() {
													$(makeRichAgentPicker('underscore_agent_name', 'underscore_agent_id', 'underscore_agent_name_icon', 'underscore_agent_view', '#underscore_agent_id#'));
													$('##editUndColl input[type=text]').on("change",changed);
													$('##description').on("change",changed);
												});
												function saveChanges(){ 
													var agenttext = $('##underscore_agent_name').val();
													var agentid = $('##underscore_agent_id').val();
													if (agenttext.length == 0 || (agentid.length>0 && agenttext.length>0) || (agentid.length == 0 && agenttext == '[No Agent]') ) { 
														$('##saveResultDiv').html('Saving....');
														$('##saveResultDiv').addClass('text-warning');
														$('##saveResultDiv').removeClass('text-success');
														$('##saveResultDiv').removeClass('text-danger');
														jQuery.ajax({
															url : "/grouping/component/functions.cfc",
															type : "post",
															dataType : "json",
															data : $('##editUndColl').serialize(),
															success : function (data) {
																$('##saveResultDiv').html('Saved.');
																$('##saveResultDiv').addClass('text-success');
																$('##saveResultDiv').removeClass('text-danger');
																$('##saveResultDiv').removeClass('text-warning');
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
																messageDialog('Error saving named collection: '+message, 'Error: '+error.substring(0,50));
															}
														});
													} else { 
														messageDialog('Error saving named collection: If an entry is made in the agent field an agent must be selected from the picklist.', 'Error: Agent not selected');
														$('##saveResultDiv').html('Fix error in Agent field.');
														$('##saveResultDiv').addClass('text-danger');
														$('##saveResultDiv').removeClass('text-success');
														$('##saveResultDiv').removeClass('text-warning');
													}
												};
											</script> 
									</div>
									<div class="col-12 row mx-0 px-1 mt-3">
										<input type="button" 
												value="Save" title="Save" aria-label="Save"
												class="btn btn-xs btn-primary"
												onClick="if (checkFormValidity($('##editUndColl')[0])) { saveChanges(); } " 
												>
										<div id="saveResultDiv" class="ml-2">&nbsp;</div>
									</div>
								</div>
							</form>
						</div>
					</div>
					</section>
					<section role="search" aria-labelledby="guid_list_label" class="container my-2">
						<h2 class="h3">Add Catalog Items to Named Group</h2>
						<div class="row border rounded mb-2 pb-2" >
							<form name="addCollObjectsUndColl" id="addCollObjectsUndColl" class="col-12">
							<input type="hidden" id="underscore_collection_id" name="underscore_collection_id" value="#underscore_collection_id#" >
							<input type="hidden" id="method" name="method" value="addObjectsToUndColl" >
							<div class="form-row mx-0 my-2">
								<div class="col-12 col-md-10">
									<label for="guid_list" id="guid_list_label" class="data-entry-label">Cataloged items to add to this group (comma separated list of GUIDs in the form MCZ:Dept:number)</label>
									<input type="text" id="guid_list" name="guid_list" class="data-entry-input" 
											value="" aria-labelledby="guid_list_label" placeholder="MCZ:Dept:1111,MCZ:Dept:1112" >
								</div>
								<script>
									function addCollectionObjects(){ 
										$('##addResultDiv').html("Saving.... ");
										jQuery.ajax({
											url : "/grouping/component/functions.cfc",
											type : "post",
											dataType : "json",
											data : $('##addCollObjectsUndColl').serialize(),
											success : function (data) {
												$.ajax({
													url : "/grouping/component/functions.cfc?method=getUndCollObjectsHTML&underscore_collection_id=#underscore_collection_id#",
													type : "get",
													dataType : "html",
													success : function(data2){
														$('##divListOfContainedObjects').html(data2);
													}
												});
												$('##addResultDiv').html("Added " + data[0].added);
											},
											error: function(jqXHR,textStatus,error){
												var message = "";
												if (error == 'timeout') {
													message = ' Server took too long to respond.';
												} else {
													message = jqXHR.responseText;
												}
												messageDialog('Error saving named collection: '+message, 'Error: ' + error.substring(0,50));
												$('##addResultDiv').html("Error.");
											}
										});
									};
								</script>
								<div class="col-12 col-md-2">
									<div id="addResultDiv">&nbsp;</div>
									<input type="button" id="addbutton"
											value="Add" title="Add" aria-label="Add"
											class="btn btn-xs btn-secondary"
											onClick=" addCollectionObjects(); " 
											>
								</div>
							</div>
						</form>
						</div>
					</section>
				
				<cfif undColl_result.recordcount GT 0>
					<!--- list specimens in the collection, link out by guid --->
					<cfquery name="undCollUse" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="undCollUse_result">
						select guid, underscore_relation_id
						from #session.flatTableName#
							left join underscore_relation on underscore_relation.collection_object_id = flat.collection_object_id
						where underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
						order by guid
					</cfquery>
						<section class="container mt-2">
							<script>
								function removeUndRelation(id) { 
									jQuery.ajax({
										url : "/grouping/component/functions.cfc",
										type : "post",
										dataType : "json",
										data : { 
											method: "removeObjectFromUndColl",
											underscore_relation_id: id 
										},
										success : function (data) {
											$.ajax({
												url : "/grouping/component/functions.cfc?method=getUndCollObjectsHTML&underscore_collection_id=#underscore_collection_id#",
												type : "get",
												dataType : "html",
												success : function(data2){
													$('##divListOfContainedObjects').html(data2);
												}
											});
										},
										error: function(jqXHR,textStatus,error){
											$('##saveResultDiv').html('Error.');
											var message = "";
											if (error == 'timeout') {
												message = ' Server took too long to respond.';
											} else {
												message = jqXHR.responseText;
											}
											messageDialog('Error saving named collection: '+message, 'Error: '+error.substring(0,50));
										}
									});
								}
							</script>
							<div class="border rounded row">
								<div class="col-12 px-4" aria-labelledby="existingvalues" id="divListOfContainedObjects">
									<cfif undCollUse_result.recordcount EQ 0>
										<h2 class="h3" id="existingvalues">There are no collection objects in this named collection</h2>
										<form action="/grouping/NamedCollection.cfm" method="post" id="deleteForm">
											<input type="hidden" name="action" value="delete">
											<input type="hidden" name="underscore_collection_id" value="#underscore_collection_id#">
											<button class="btn btn-xs btn-danger mb-3" id="deleteButton" aria-label="Delete this collection.">Delete</button>
											<script>
												$(document).ready(function() {
													$('##deleteButton').bind('click', function(evt){
														evt.preventDefault();
														confirmDialog('Delete the #collname# collection? ', 'Delete?', function(){ $('##deleteForm').submit(); }); 
													});
												});
											</script>
										</form>
									<cfelse>
										<h2 class="h3" id="existingvalues">Cataloged items in this named collection (#undCollUse_result.recordcount#)</h2>
										<ul class="list-style-disc px-4">
											<cfloop query="undCollUse">
												<li class="my-1">
													<a href="/guid/#undCollUse.guid#" target="_blank">#undCollUse.guid#</a>
													<button class="btn-xs btn-warning mx-1" onclick="removeUndRelation(#undCollUse.underscore_relation_id#);">Remove</button>
												</li>
											</cfloop>
										</ul>
									</cfif>
								</div>
							</div>
						</section>
					</cfif>
				</main><!--- container ---> 
			</cfoutput>
		</cfif>
	</cfcase>
	<!---------------------------------------------------------------------------------->
	<cfcase value="delete">
		<cftry>
			<cfif not isdefined("underscore_collection_id") OR len(trim(#underscore_collection_id#)) EQ 0 >
				<cfthrow type="Application" message="Error: No value provided for required value underscore_collection_id">
			</cfif>
			<cfquery name="delete" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="delete_result">
					delete from underscore_collection 
					where
					 	underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
			</cfquery>
			<h1 class="h2">"Collection" successfully deleted.</h1>
			<ul>
				<li><a href="/grouping/NamedCollection.cfm">Search for Named groups of cataloged items</a>.</li>
				<li><a href="/grouping/NamedCollection.cfm?action=new">Create a new named group of cataloged items</a>.</li>
			</ul>
		<cfcatch>
			<cfthrow type="Application" message="Error deleting Named Collection: #cfcatch.Message# #cfcatch.Detail#">
		</cfcatch>
		</cftry>
	</cfcase>
	<!---------------------------------------------------------------------------------->
	<cfdefaultcase>
		<cfthrow type="Application" message="Unknown action.">
	</cfdefaultcase>
</cfswitch>
<!---------------------------------------------------------------------->
<cfinclude template = "/shared/_footer.cfm">
