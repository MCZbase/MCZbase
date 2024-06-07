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
		<cfset pageTitle = "Search Named Groups">
	</cfcase>
	<cfcase value="new">
		<cfset pageTitle = "Create Named Group">
	</cfcase>
	<cfcase value="edit">
		<cfset pageTitle = "Edit Named Group">
	</cfcase>
	<cfdefaultcase>
		<cfset pageTitle = "Named Group of Cataloged Items">
	</cfdefaultcase>
</cfswitch>
<!---------------------------------------------------------------------------------->
<cfset includeJQXEditor='true'>
<cfinclude template = "/shared/_header.cfm">

<cfset defaultSelectionMode = "none">
<cfif defaultSelectionMode EQ "none">
	<cfset defaultenablebrowserselection = "true">
<cfelse>
	<cfset defaultenablebrowserselection = "false">
</cfif>	

<!---------------------------------------------------------------------------------->
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
<!--- code table used across several actions --->
<cfquery name="ctunderscore_collection_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="colls_result" timeout="#Application.short_timeout#">
	SELECT underscore_collection_type, description, allowed_agent_roles 
	FROM ctunderscore_collection_type
</cfquery>
<!---------------------------------------------------------------------------------->
<cfswitch expression="#action#">
	<cfcase value="search">
		<cfquery name="colls" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="colls_result" timeout="#Application.short_timeout#">
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
					<section class="container-fluid mb-3" role="search" aria-labelledby="formheader">
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
														makeNamedCollectionPicker('collection_name',null,false);
													});
												</script>
											</div>
											<div class="col-md-3">
												<label for="description" class="data-entry-label" id="description_label">Overview</label>
												<input type="text" id="description" name="description" class="data-entry-input" value="#description#" aria-labelledby="description_label" >
											</div>
											<div class="col-md-2">
												<cfif NOT isDefined("underscore_collection_type")>
													<cfset underscore_collection_type = "">
												</cfif>
												<cfset current_type = "#underscore_collection_type#">
												<label for="underscore_collection_type" class="data-entry-label" id="underscore_collection_type_label">Type</label>
												<select name="underscore_collection_type" id="underscore_collection_type" class="data-entry-select">
													<cfif len(current_type) EQ 0><cfset sel = ""><cfelse><cfset sel='selected="selected"'></cfif>
													<option value="" #sel#></option>
													<cfloop query="ctunderscore_collection_type">
														<cfif current_type EQ ctunderscore_collection_type.underscore_collection_type>
															<cfset sel='selected="selected"'>
														<cfelse>
															<cfset sel = "">
														</cfif> 
														<option value="#ctunderscore_collection_type.underscore_collection_type#" #sel#>#ctunderscore_collection_type.underscore_collection_type#</option>
													</cfloop>
												</select>
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
												<label for="underscore_agent_name" id="underscore_agent_name_label" class="data-entry-label pb-0">An Agent Associated with this Named Group 
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
												<button class="btn-xs btn-primary px-2 my-2 mr-1" id="searchButton" type="submit" aria-label="Search for named groups of cataloged items">Search<span class="fa fa-search pl-1"></span></button>
												<button type="reset" class="btn-xs btn-warning my-2 mr-1" aria-label="Reset search form to inital values" onclick="">Reset</button>
												<button type="button" class="btn-xs btn-warning my-2 mr-1" aria-label="Start a new named group search with a clear form" onclick="window.location.href='#Application.serverRootUrl#/grouping/NamedCollection.cfm?action=search';" >New Search</button>
												<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_specimens")>
													<button type="button" class="btn-xs btn-secondary my-2" aria-label="Create a new named group" onclick="window.location.href='#Application.serverRootUrl#/grouping/NamedCollection.cfm?action=new';" >Create new named group of cataloged items</button>
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
										<div id="selectModeContainer" class="ml-3" style="display: none;" >
											<script>
												function changeSelectMode(){
													var selmode = $("##selectMode").val();
													$("##searchResultsGrid").jqxGrid({selectionmode: selmode});
													if (selmode=="none") { 
														$("##searchResultsGrid").jqxGrid({enableBrowserSelection: true});
													} else {
														$("##searchResultsGrid").jqxGrid({enableBrowserSelection: false});
													}
												};
											</script>
											<label class="data-entry-label d-inline w-auto mt-1" for="selectMode">Grid Select:</label>
											<select class="data-entry-select d-inline w-auto mt-1" id="selectMode" onChange="changeSelectMode();">
												<cfif defaultSelectionMode EQ 'none'><cfset selected="selected"><cfelse><cfset selected=""></cfif>
												<option #selected# value="none">Text</option>
												<cfif defaultSelectionMode EQ 'singlecell'><cfset selected="selected"><cfelse><cfset selected=""></cfif>
												<option #selected# value="singlecell">Single Cell</option>
												<cfif defaultSelectionMode EQ 'singlerow'><cfset selected="selected"><cfelse><cfset selected=""></cfif>
												<option #selected# value="singlerow">Single Row</option>
												<cfif defaultSelectionMode EQ 'multiplerowsextended'><cfset selected="selected"><cfelse><cfset selected=""></cfif>
												<option #selected# value="multiplerowsextended">Multiple Rows (click, drag, release)</option>
												<cfif defaultSelectionMode EQ 'multiplecellsadvanced'><cfset selected="selected"><cfelse><cfset selected=""></cfif>
												<option #selected# value="multiplecellsadvanced">Multiple Cells (click, drag, release)</option>
											</select>
										</div>
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
						return '<span class="#cellRenderClasses#" style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; "><a href="/grouping/showNamedCollection.cfm?underscore_collection_id=' + rowData['UNDERSCORE_COLLECTION_ID'] + '">'+value+'</a></span>';
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
							$('##selectModeContainer').hide();
					
							var search =
							{
								datatype: "json",
								datafields:
								[
									{ name: 'UNDERSCORE_COLLECTION_ID', type: 'string' },
									{ name: 'COLLECTION_NAME', type: 'string' },
									{ name: 'UNDERSCORE_COLLECTION_TYPE', type: 'string' },
									{ name: 'VISIBILITY', type: 'string' },
									{ name: 'DESCRIPTION', type: 'string' },
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
								timeout: #Application.ajax_timeout#000,  // units not specified, miliseconds? 
								loadError: function(jqXHR, textStatus, error) {
									handleFail(jqXHR,textStatus,error, "Error performing specimen search: "); 
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
								enablemousewheel: #session.gridenablemousewheel#,
								pagesize: '50',
								pagesizeoptions: ['5','50','100'],
								showaggregates: true,
								columnsresize: true,
								autoshowfiltericon: true,
								autoshowcolumnsmenubutton: false,
								autoshowloadelement: false,  // overlay acts as load element for form+results
								columnsreorder: true,
								groupable: true,
								selectionmode: '#defaultSelectionMode#',
								enablebrowserselection: #defaultenablebrowserselection#,
								altrows: true,
								showtoolbar: false,
								columns: [
									{text: 'Name', datafield: 'COLLECTION_NAME', width: 300, hidable: true, hidden: getColHidProp('COLLECTION_NAME', false), cellsrenderer: linkIdCellRenderer },
									<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_specimens")>
										{text: 'ID', datafield: 'UNDERSCORE_COLLECTION_ID', width:100, hideable: true, hidden: getColHidProp('UNDERSCORE_COLLECTION_ID', false), cellsrenderer: editCellRenderer },
									<cfelse>
										{text: 'ID', datafield: 'UNDERSCORE_COLLECTION_ID', width:100, hideable: true, hidden: getColHidProp('UNDERSCORE_COLLECTION_ID', true) },
									</cfif>
									{text: 'Type', datafield: 'UNDERSCORE_COLLECTION_TYPE', width: 100, hidable: true, hidden: getColHidProp('UNDERSCORE_COLLECTION_TYPE', false) },
									{text: 'Visibility', datafield: 'VISIBILITY', width: 100, hidable: true, hidden: getColHidProp('VISIBILITY', true) },
									{text: 'Agents', datafield: 'AGENTNAME', width: 150, hidable: true, hidden: getColHidProp('AGENTNAME', false) },
									{text: 'Specimen Count', datafield: 'SPECIMEN_COUNT', width:150, hideable: true, hidden: getColHidProp('SPECIMEN_COUNT', false) },
									{text: 'Featured Data', datafield: 'HTML_DESCRIPTION', hideable: true, hidden: getColHidProp('HTML_DESCRIPTION', true) },
									{text: 'Overview', datafield: 'DESCRIPTION', hideable: true, hidden: getColHidProp('DESCRIPTION', false) }
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
							"<button id='columnPickDialogOpener' onclick=\" $('##columnPickDialog').dialog('open'); \" class='btn-xs btn-secondary px-3 py-1 mt-1 mx-3' >Show/Hide Columns</button>"
						);
						// workaround for menu z-index being below grid cell z-index when grid is created by a loan search.
						// likewise for the popup menu for searching/filtering columns, ends up below the grid cells.
						var maxZIndex = getMaxZIndex();
						$('.jqx-grid-cell').css({'z-index': maxZIndex + 1});
						$('.jqx-grid-group-cell').css({'z-index': maxZIndex + 1});
						$('.jqx-menu-wrapper').css({'z-index': maxZIndex + 2});
						$('##resultDownloadButtonContainer').html('<button id="loancsvbutton" class="btn-xs btn-secondary px-3 py-1 mt-1 mx-0" aria-label="Export results to csv" onclick=" exportGridToCSV(\'searchResultsGrid\', \''+filename+'\'); " >Export to CSV</button>');
						$('##selectModeContainer').show();
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
		<!--- Add a new ____ collection/named group, link to agent ---> 
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
									<div class="col-12 col-md-9">
										<label for="description" id="description_label" class="data-entry-label">Overview (<span id="length_description">0 characters, 4000 left</span>)</label>
										<textarea id="description" name="description" class="reqdClr data-entry-textarea mt-0"
												onkeyup="countCharsLeft('description',4000,'length_description');"
												rows="3" aria-labelledby="description_label" ></textarea>
									</div>
									<script>
										$(document).ready(function() {
											$('##description').keyup(autogrow);
										});
									</script>
									<div class="col-12 col-md-3">
										<label for="underscore_collection_type" class="reqdClr data-entry-label" id="underscore_collection_type_label">Type</label>
										<select name="underscore_collection_type" id="underscore_collection_type" class="data-entry-select reqdClr" required>
											<option value="" selected="selected"></option>
											<cfloop query="ctunderscore_collection_type">
												<option value="#ctunderscore_collection_type.underscore_collection_type#">#ctunderscore_collection_type.underscore_collection_type#</option>
											</cfloop>
										</select>
									</div>
								</div>
								<div class="form-row mb-2">
									<div class="col-md-12">
										<label for="html_description" id="html_description_label" class="data-entry-label">Featured Data</label>
										<textarea id="html_description" name="html_description" class="w-100"
											aria-labelledby="html_description_label" ></textarea>
									</div>
									<script>
										$(document).ready(function () {
											$('##html_description').jqxEditor({lineBreak:"p"});
										});
									</script>
								</div>
								<div class="form-row mb-1">
									<div class="col-12 col-md-6">
										<h3 class="h4">Add agents after saving the new record</h3>
									</div>
									<div class="col-12 col-md-6">
										<label for="displayed_media_id" id="displayed_media_id_label" class="data-entry-label">MediaID of exemplar image</label>
										<input type="text" id="displayed_media_id" name="displayed_media_id" class="data-entry-input" aria-labelledby="displayed_media_id_label" >
										<script>
											$(document).ready(function() {
												makeRichMediaPickerOneControlMeta("displayed_media_id",'image');
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
			<cfquery name="save" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="insertResult">
				insert into underscore_collection (
					collection_name,
					underscore_collection_type,
					mask_fg
					<cfif isdefined("description")>
						,description
					</cfif>
					<cfif isdefined("html_description")>
						,html_description
					</cfif>
					<cfif isdefined("displayed_media_id") and len(displayed_media_id) GT 0 >
						,displayed_media_id
					</cfif>
				) values (
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#collection_name#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#underscore_collection_type#">,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#mask_fg#">
					<cfif isdefined("description")>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#description#">
					</cfif>
					<cfif isdefined("html_description")>
						,<cfqueryparam cfsqltype="CF_SQL_CLOB" value="#html_description#">
					</cfif>
					<cfif isdefined("displayed_media_id") and len(displayed_media_id) GT 0 >
						,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#displayed_media_id#">
					</cfif>
				)
			</cfquery>
			<cfquery name="savePK" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="pkResult">
					select underscore_collection_id from underscore_collection 
					where ROWIDTOCHAR(rowid) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#insertResult.GENERATEDKEY#">
			</cfquery>
			<cflocation url="/grouping/NamedCollection.cfm?action=edit&underscore_collection_id=#savePK.underscore_collection_id#" addtoken="false">
			<cfcatch>
				<cfthrow type="Application" message="Error Saving new Named Group: #cfcatch.Message# #cfcatch.Detail#">
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
			<cfinclude template="/grouping/component/functions.cfc" runOnce="true">
			<cfquery name="undColl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="undColl_result">
				SELECT 
					underscore_collection_id, collection_name, underscore_collection_type,
					underscore_collection.description, 
					html_description,
					displayed_media_id,
					underscore_collection.mask_fg,
					media.auto_filename displayed_media_filename
				FROM underscore_collection
					left join media on underscore_collection.displayed_media_id = media.media_id
				WHERE
					underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
			</cfquery>
			<cfif undColl_result.recordcount EQ 0>
				<cfthrow message="No such named group found (underscore_collection_id=[#encodeForHtml(underscore_collection_id)#])" >
			</cfif>
			<cfoutput query="undColl">
				<cfset collname = collection_name>
				<!--- save name for later use outside this output section --->
				<main id="content" class="pb-5">
					<section class="container pt-3">
						<h1 class="h2" id="formheading">
							Edit Named Group of Cataloged Items: 
							<a href="/grouping/showNamedCollection.cfm?underscore_collection_id=#underscore_collection_id#"><span id="headingNameOfCollection">#collection_name#</span></a>
						</h1>
					<div class="row border rounded py-3" aria-labelledby="formheading">
						<div class="col-12 px-3">
							<form name="editUndColl" id="editUndColl">
								<input type="hidden" id="underscore_collection_id" name="underscore_collection_id" value="#encodeForHtml(underscore_collection_id)#" >
								<input type="hidden" id="method" name="method" value="saveUndColl" >
								<div class="form-row mb-2">
									<div class="col-12 col-md-9">
										<label for="collection_name" id="collection_name_label" class="data-entry-label">Name for the Group of cataloged items</label>
										<input type="text" id="collection_name" name="collection_name" class="data-entry-input reqdClr" 
												required value="#encodeForHtml(collection_name)#" aria-labelledby="collection_name_label" >
									</div>
									<div class="col-md-3">
										<label for="mask_fg" class="data-entry-label">Record Visibility</label>
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
									<div class="col-12 col-md-9">
										<label for="description" id="description_label" class="data-entry-label">Overview (<span id="length_description"></span>)</label>
										<textarea id="description" name="description" class="reqdClr data-entry-textarea mt-0 autogrow"
												onkeyup="countCharsLeft('description',4000,'length_description');"
												rows="3" aria-labelledby="description_label" >#encodeForHtml(description)#</textarea>
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
									<div class="col-12 col-md-3">
										<cfset current_type = "#underscore_collection_type#">
										<label for="underscore_collection_type" class="reqClr data-entry-label" id="underscore_collection_type_label">Type</label>
										<select name="underscore_collection_type" id="underscore_collection_type" class="reqdClr data-entry-select">
											<cfloop query="ctunderscore_collection_type">
												<cfif current_type EQ ctunderscore_collection_type.underscore_collection_type>
													<cfset sel='selected="selected"'>
												<cfelse>
													<cfset sel = "">
												</cfif> 
												<option value="#ctunderscore_collection_type.underscore_collection_type#" #sel#>#ctunderscore_collection_type.underscore_collection_type#</option>
											</cfloop>
										</select>
									</div>
								</div>
								<div class="form-row mb-2">
									<div class="col-md-12">
										<label for="html_description" id="html_description_label" class="data-entry-label">Featured Data</label>
										<textarea id="html_description" name="html_description" class="w-100" aria-labelledby="html_description_label"></textarea>
									</div>
									<script>
										$(document).ready(function () {
											$('##html_description').jqxEditor({lineBreak:"p"});
											$('##html_description').jqxEditor("val","#encodeForJavaScript(trim(html_description))#");
										});
									</script>
								</div>
								<div class="form-row mb-0">
									<div class="col-12 col-md-4">
										<label for="displayed_media_filename" id="displayed_media_filename_label" class="data-entry-label">Filename of first specimen image</label>
										<input type="text" id="displayed_media_filename" class="data-entry-input" aria-labelledby="displayed_media_filename_label" value="#displayed_media_filename#" >
									</div>
									<div class="col-12 col-md-4">
										<label for="displayed_media_id" id="displayed_media_id_label" class="data-entry-label">MediaID of first specimen image</label>
										<input type="text" id="displayed_media_id" name="displayed_media_id" class="data-entry-input bg-light" aria-labelledby="displayed_media_id_label" value="#displayed_media_id#" readonly >
									</div>
									<script>
										$(document).ready(function() {
											makeRichMediaPickerControlMeta("displayed_media_filename","displayed_media_id",'image');
										});
									</script>
								</div>
								<script>
									function changed(){
										$('##saveResultDiv').html('Unsaved changes.');
										$('##saveResultDiv').addClass('text-danger');
										$('##saveResultDiv').removeClass('text-success');
										$('##saveResultDiv').removeClass('text-warning');
									};
									$(document).ready(function() {
										$('##editUndColl input[type=text]').on("change",changed);
										$('##editUndColl input[type=checkbox]').on("change",changed);
										$('##editUndColl select').on("change",changed);
										$('##editUndColl textarea').on("change",changed);
										$('##description').on("change",changed);
									});
									function updateFromSave() { 
										$('##headingNameOfCollection').html($('#collection_name#').val());
									}
									function saveChanges(){ 
										saveEditsFromFormCallback("editUndColl","/grouping/component/functions.cfc","saveResultDiv","saving named group",updateFromSave);
									};
								</script> 
								<div class="form-row mb-0">
									<div class="col-12 row mx-0 px-1 mt-3">
										<input type="button" 
												value="Save" title="Save" aria-label="Save"
												class="btn btn-xs btn-primary"
												onClick="if (checkFormValidity($('##editUndColl')[0])) { saveChanges(); } " 
												>
										<output id="saveResultDiv" class="ml-2">&nbsp;</output>
									</div>
								</div>
							</form>
							<script>
								function reloadAgentBlock() { 
									loadAgentDivHTML("#underscore_collection_id#","agentBlock"); 
								}
								function reloadCitationBlock() { 
									loadCitationDivHTML("#underscore_collection_id#","citationBlock"); 
								}
							</script>
							<div class="form-row mb-0 mt-1 border">
								<cfset agentBlockContent = getAgentDivHTML(underscore_collection_id = "#underscore_collection_id#")>
								<div class="col-12" id="agentBlockHeading">
									<h2 class="h3">Agents with Roles in this Named Group</h2>
								</div>
								<div class="col-12" id="agentBlock">#agentBlockContent#</div>
								<div class="col-12 pb-1">
									<script>
										function showAddDialog() { 
											openlinkagenttogroupingdialog("agentDialogDiv", "#underscore_collection_id#", "#collection_name#", reloadAgentBlock);
										}
									</script>
									<button id="add_agent_button" class="btn btn-xs btn-secondary" aria-label="add a new agent to this named grouping." onclick="showAddDialog();">Add Agent</button>
								</div>
								<div id="agentDialogDiv"></div>
							</div>
							<div class="form-row mb-0 mt-1 border">
								<cfset citationBlockContent = getCitationDivHTML(underscore_collection_id = "#underscore_collection_id#")>
								<div class="col-12" id="citationBlockHeading">
									<h2 class="h3">Publications related to this Named Group</h2>
								</div>
								<div class="col-12" id="citationBlock">#citationBlockContent#</div>
								<div class="col-12 pb-1">
									<script>
										function showAddCitationDialog() { 
											opencitenamedgroupingdialog("citationDialogDiv", "#underscore_collection_id#", "#collection_name#", reloadCitationBlock);
										}
									</script>
									<button id="add_citation_button" class="btn btn-xs btn-secondary" aria-label="add a new citation to this named grouping." onclick="showAddCitationDialog();">Add Publication</button>
								</div>
								<div id="citationDialogDiv"></div>
							</div>
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
												$('##addResultDiv').html("Added " + data[0].added);
												$("##catalogedItemsGrid").jqxGrid("updateBoundData");
												$('##deleteSection').hide();
											},
											error: function(jqXHR,textStatus,error){
												$('##addResultDiv').html("Error.");
												handleFail(jqXHR,textStatus,error,"saving named group");
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
				
					<!--- list specimens in the collection, link out by guid --->
					<cfquery name="undCollRelationsSum" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="undCollRelationsSum_result">
						SELECT count(*) as ct
						FROM underscore_relation 
						where underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
					</cfquery>
					<cfif undCollRelationsSum.ct EQ 0>
						<section class="container-fluid" id="deleteSection">
							<div class="row mx-0">
								<div class="col-12">
									<div class="mb-5">
										<div class="row mt-1 mb-0 pb-0 jqx-widget-header border px-2">
											<h2 class="h3" id="existingvalues">There are no cataloged items in this named group.</h2>
											<form action="/grouping/NamedCollection.cfm" method="post" id="deleteForm">
												<input type="hidden" name="action" value="delete">
												<input type="hidden" name="underscore_collection_id" value="#underscore_collection_id#">
												<button class="btn btn-xs btn-danger mx-3 my-2" id="deleteButton" aria-label="Delete this named group.">Delete This Named Group</button>
												<script>
													$(document).ready(function() {
														$('##deleteButton').bind('click', function(evt){
															evt.preventDefault();
															confirmDialog('Delete the #collname# named group? ', 'Delete?', function(){ $('##deleteForm').submit(); }); 
														});
													});
												</script>
											</form>
										</div>
									</div>
								</div>
							</div>
						</section>
					<cfelse>
						<div id="deleteSection" style="display: none;"></div>
					</cfif>
					<section class="container-fluid">
						<div class="row mx-0">
							<div class="col-12">
								<div class="mb-5">
									<div class="row mt-1 mb-0 pb-0 jqx-widget-header border px-2">
										<h2 class="h3">
											Cataloged items in this named group
											<a href="/SpecimenResults.cfm?underscore_coll_id=#encodeForURL(underscore_collection_id)#" target="_blank">(#undCollRelationsSum.ct#)</a>
										</h2>
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
										<div id="selectModeContainer" class="ml-3" style="display: none;" >
											<script>
												function changeSelectMode(){
													var selmode = $("##selectMode").val();
													$("##catalogedItemsGrid").jqxGrid({selectionmode: selmode});
													if (selmode=="none") { 
														$("##catalogedItemsGrid").jqxGrid({enableBrowserSelection: true});
													} else {
														$("##catalogedItemsGrid").jqxGrid({enableBrowserSelection: false});
													}
												};
											</script>
											<label class="data-entry-label d-inline w-auto mt-1" for="selectMode">Grid Select:</label>
											<select class="data-entry-select d-inline w-auto mt-1" id="selectMode" onChange="changeSelectMode();">
												<cfif defaultSelectionMode EQ 'none'><cfset selected="selected"><cfelse><cfset selected=""></cfif>
												<option #selected# value="none">Text</option>
												<cfif defaultSelectionMode EQ 'singlecell'><cfset selected="selected"><cfelse><cfset selected=""></cfif>
												<option #selected# value="singlecell">Single Cell</option>
												<cfif defaultSelectionMode EQ 'singlerow'><cfset selected="selected"><cfelse><cfset selected=""></cfif>
												<option #selected# value="singlerow">Single Row</option>
												<cfif defaultSelectionMode EQ 'multiplerowsextended'><cfset selected="selected"><cfelse><cfset selected=""></cfif>
												<option #selected# value="multiplerowsextended">Multiple Rows (click, drag, release)</option>
												<cfif defaultSelectionMode EQ 'multiplecellsadvanced'><cfset selected="selected"><cfelse><cfset selected=""></cfif>
												<option #selected# value="multiplecellsadvanced">Multiple Cells (click, drag, release)</option>
											</select>
										</div>
									</div>
									<div class="row mt-0"> 
										<!--- Grid Related code is below along with search handlers --->
										<div id="catalogedItemsGrid" class="jqxGrid" role="table" aria-label="Cataloged items in this named group"></div>
										<div id="enableselection"></div>
									</div>
								</div>
							</div>
						</div>
					</section>
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
									$("##catalogedItemsGrid").jqxGrid("updateBoundData");
								},
								error: function(jqXHR,textStatus,error){
									$('##saveResultDiv').html('Error.');
									handleFail(jqXHR,textStatus,error,"removing cataloged item from named group");
								}
							});
						}
					</script>
					<!---- setup grid for cataloged items --->
					<script type="text/javascript">
						window.columnHiddenSettings = new Object();
						<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
							lookupColumnVisibilities ('#cgi.script_name#?action=edit','Default');
						</cfif>

						var cellsrenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
							if (value > 1) {
								return '<a href="/guid/'+value+'"><span style="margin: 4px; float: ' + columnproperties.cellsalign + '; color: ##0000ff;">' + value + '</span></a>';
							}
							else {
								return '<a href="/guid/'+value+'"><span style="margin: 4px; float: ' + columnproperties.cellsalign + '; color: ##007bff;">' + value + '</span></a>';
							}
						}
						$(document).ready(function () {
							var source =
							{
								datatype: "json",
								datafields:
								[
									{ name: 'underscore_relation_id', type: 'string' },
									{ name: 'guid', type: 'string' },
									{ name: 'scientific_name', type: 'string' },
									{ name: 'author_text', type: 'string' },
									{ name: 'verbatim_date', type: 'string' },
									{ name: 'date_collected', type: 'string' },
									{ name: 'collectors', type: 'string' },
									{ name: 'higher_geog', type: 'string' },
									{ name: 'continent_ocean', type: 'string' },
									{ name: 'country', type: 'string' },
									{ name: 'state_prov', type: 'string' },
									{ name: 'county', type: 'string' },
									{ name: 'island', type: 'string' },
									{ name: 'island_group', type: 'string' },
									{ name: 'spec_locality', type: 'string' },
									{ name: 'othercatalognumbers', type: 'string' },
									{ name: 'phylym', type: 'string' },
									{ name: 'phylclass', type: 'string' },
									{ name: 'phylorder', type: 'string' },
									{ name: 'family', type: 'string' },
									{ name: 'full_taxon_name', type: 'string' }
								],
								url: '/grouping/component/search.cfc?method=getSpecimensInGroup&returnallrecords=true&underscore_collection_id=#underscore_collection_id#',
								timeout: #Application.ajax_timeout#000,  // units not specified, miliseconds? 
								loadError: function(jqXHR, textStatus, error) { 
									handleFail(jqXHR,textStatus,error,"retrieving cataloged items in named group");
								}
							};
							var dataAdapter = new $.jqx.dataAdapter(source);
							var initRowDetails = function (index, parentElement, gridElement, datarecord) {
								// could create a dialog here, but need to locate it later to hide/show it on row details opening/closing and not destroy it.
								var details = $($(parentElement).children()[0]);
								details.html("<div id='rowDetailsTarget" + index + "'></div>");
								createRowDetailsDialog('catalogedItemsGrid','rowDetailsTarget',datarecord,index);
								// Workaround, expansion sits below row in zindex.
								var maxZIndex = getMaxZIndex();
								$(parentElement).css('z-index',maxZIndex - 1); // will sit just behind dialog
							}

							// initialize jqxGrid for cataloged items *****
							$("##catalogedItemsGrid").jqxGrid(
							{
								width: '100%',
								autoheight: 'true',
								source: dataAdapter,
								filterable: true,
								sortable: true,
								pageable: true,
								editable: false,
								pagesize: '50',
								pagesizeoptions: ['5','50','100','#undCollRelationsSum.ct#'], // reset in gridLoaded
								showaggregates: true,
								columnsresize: true,
								autoshowfiltericon: true,
								autoshowcolumnsmenubutton: false,
								autoshowloadelement: true, 
								columnsreorder: true,
								groupable: true,
								selectionmode: '#defaultSelectionMode#',
								enablebrowserselection: #defaultenablebrowserselection#,
								altrows: true,
								showtoolbar: false,
								ready: function () {
									$("##catalogedItemsGrid").jqxGrid('selectrow', 0);
								},
								columns: [
									{ text: 'GUID', datafield: 'guid', width:150,cellsalign: 'left',cellsrenderer: cellsrenderer, hideable: false},
									{ text: 'Scientific Name', datafield: 'scientific_name', width:250, hideable: true, hidden: getColHidProp('scientific_name', false) },
									{ text: 'Authorship', datafield: 'author_text', width:110, hideable: true, hidden: getColHidProp('author_text', true) },
									{ text: 'Higher Taxonomy', datafield: 'full_taxon_name', width:350, hideable: true, hidden: getColHidProp('taxonomy', true) },
									{ text: 'Phylum', datafield: 'phylum', width:110, hideable: true, hidden: getColHidProp('phylum', true) },
									{ text: 'Class', datafield: 'phylclass', width:110, hideable: true, hidden: getColHidProp('phylclass', true) },
									{ text: 'Order', datafield: 'phylorder', width:110, hideable: true, hidden: getColHidProp('phylorder', true) },
									{ text: 'Family', datafield: 'family', width:110, hideable: true, hidden: getColHidProp('family', false) },
									{ text: 'Other Catalog Numbers', datafield: 'othercatalognumbers',width:200, hideable: true, hidden: getColHidProp('othercatalognumbers', true) },
									{ text: 'Collector', datafield: 'collectors', width:110, hideable: true, hidden: getColHidProp('collector', false) },
									{ text: 'Date Collected', datafield: 'date_collected', width:150, hideable: true, hidden: getColHidProp('date_collected', false) },
									{ text: 'Verbatim Date', datafield: 'verbatim_date', width:150, hideable: true, hidden: getColHidProp('verbatim_date', true) },
									{ text: 'Higher Geography', datafield: 'higher_geog', width:350, hideable: true, hidden: getColHidProp('higher_geog', true) },
									{ text: 'Continent/Ocean', datafield: 'continent_ocean', width:110, hideable: true, hidden: getColHidProp('continent_ocean', true) },
									{ text: 'Country', datafield: 'country', width:110, hideable: true, hidden: getColHidProp('country', false) },
									{ text: 'State/Province', datafield: 'state_prov', width:110, hideable: true, hidden: getColHidProp('state_prov', false) },
									{ text: 'County', datafield: 'county', width:110, hideable: true, hidden: getColHidProp('county', true) },
									{ text: 'Island Group', datafield: 'island_group', width:110, hideable: true, hidden: getColHidProp('island_group', true) },
									{ text: 'Island', datafield: 'island', width:110, hideable: true, hidden: getColHidProp('island', true) },
									{ text: 'Specific Locality', datafield: 'spec_locality', hideable: true, hidden: getColHidProp('spec_locality', false) },
									{ text: 'Remove', datafield: 'Remove', columntype: 'button', 
										cellsrenderer: function () {
											return "Remove";
										}, buttonclick: function (row) { 
											var record = $("##catalogedItemsGrid").jqxGrid('getrowdata', row);
											var guidtoremove = record.guid;
											var idtoremove = record.underscore_relation_id;
											confirmDialog('Remove '+ guidtoremove +' from this named group? ', 'Remove?', function(){ 
												removeUndRelation(idtoremove);
											});
										}
									} 
								],
								rowdetails: true,
								rowdetailstemplate: {
									rowdetails: "<div style='margin: 10px;'>Row Details</div>",
									rowdetailsheight:  1 // row details will be placed in popup dialog
								},
								initrowdetails: initRowDetails
							});
							$("##catalogedItemsGrid").on("bindingcomplete", function(event) {
								gridLoaded('catalogedItemsGrid','taxon record');
							});
							$('##catalogedItemsGrid').on('rowexpand', function (event) {
								//  Create a content div, add it to the detail row, and make it into a dialog.
								var args = event.args;
								var rowIndex = args.rowindex;
								var datarecord = args.owner.source.records[rowIndex];
								createRowDetailsDialog('catalogedItemsGrid','rowDetailsTarget',datarecord,rowIndex);
							});
							$('##catalogedItemsGrid').on('rowcollapse', function (event) {
								// remove the dialog holding the row details
								var args = event.args;
								var rowIndex = args.rowindex;
								$("##catalogedItemsGridRowDetailsDialog" + rowIndex ).dialog("destroy");
							});
						});
						// gridLoaded for cataloged items ***********
						function gridLoaded(gridId, searchType) { 
							if (Object.keys(window.columnHiddenSettings).length == 0) { 
								window.columnHiddenSettings = getColumnVisibilities('catalogedItemsGrid');
								<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
									saveColumnVisibilities('#cgi.script_name#?action=edit',window.columnHiddenSettings,'Default');
								</cfif>
							}
							$("##overlay").hide();
							$('.jqx-header-widget').css({'z-index': maxZIndex + 1 }); 
							var now = new Date();
							var nowstring = now.toISOString().replace(/[^0-9TZ]/g,'_');
							var filename = searchType + '_results_' + nowstring + '.csv';
							// set maximum page size
							var datainformation = $('##' + gridId).jqxGrid('getdatainformation');
							var rowcount = datainformation.rowscount;
							if (rowcount > 100) { 
								$('##' + gridId).jqxGrid({ pagesizeoptions: ['5','50', '100', rowcount],pagesize: 50});
								$('##' + gridId).jqxGrid({ pagesize: 50});
							} else if (rowcount > 50) { 
								$('##' + gridId).jqxGrid({ pagesizeoptions: ['5','50', rowcount],pagesize: 50});
								$('##' + gridId).jqxGrid({ pagesize: 50});
							} else { 
								$('##' + gridId).jqxGrid({ pageable: false });
							}
							// add a control to show/hide columns
							var columns = $('##' + gridId).jqxGrid('columns').records;
							var halfcolumns = Math.round(columns.length/2);
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
							for (i = halfcolumns; i < columns.length; i++) {
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
								buttons: [
									{
										text: "Ok",
										click: function(){ 
											window.columnHiddenSettings = getColumnVisibilities('catalogedItemsGrid');
											<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
												saveColumnVisibilities('#cgi.script_name#?action=edit',window.columnHiddenSettings,'Default');
											</cfif>
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
							$("##columnPickDialogButton").html(
								"<button id='columnPickDialogOpener' onclick=\" $('##columnPickDialog').dialog('open'); \" class='btn-xs btn-secondary px-3 pb-1 mx-1 mb-1 my-md-2 mx-3' >Show/Hide Columns</button>"
							);
							// workaround for menu z-index being below grid cell z-index when grid is created by a loan search.
							// likewise for the popup menu for searching/filtering columns, ends up below the grid cells.
							var maxZIndex = getMaxZIndex();
							$('.jqx-grid-cell').css({'z-index': maxZIndex + 1});
							$('.jqx-grid-cell').css({'border-color': '##aaa'});
							$('.jqx-grid-group-cell').css({'z-index': maxZIndex + 1});
							$('.jqx-grid-group-cell').css({'border-color': '##aaa'});
							$('.jqx-menu-wrapper').css({'z-index': maxZIndex + 2});
							$('##resultDownloadButtonContainer').html('<button id="loancsvbutton" class="btn-xs btn-secondary px-3 pb-1 mx-1 mb-1 my-md-2" aria-label="Export results to csv" onclick=" exportGridToCSV(\'catalogedItemsGrid\', \''+filename+'\'); " >Export to CSV</button>');
							$('##selectModeContainer').show();
						}
					</script>
					<!---- end setup grid for cataloged items **** --->

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
			<cfquery name="getName" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="delete_result">
					select collection_name from underscore_collection 
					where
						underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
			</cfquery>
			<cfquery name="delete" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="delete_result">
					delete from underscore_collection 
					where
						underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
			</cfquery>
			<cfoutput>
				<h1 class="h2">Named Group "#getName.collection_name#" successfully deleted.</h1>
				<ul>
					<li><a href="/grouping/NamedCollection.cfm">Search for Named groups of cataloged items</a>.</li>
					<li><a href="/grouping/NamedCollection.cfm?action=new">Create a new named group of cataloged items</a>.</li>
				</ul>
			</cfoutput>
		<cfcatch>
			<cfthrow type="Application" message="Error deleting Named Group: #cfcatch.Message# #cfcatch.Detail#">
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
