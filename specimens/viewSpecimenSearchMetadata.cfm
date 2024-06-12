<!---
specimens/viewSpecimenSearchMetadata.cfm

For viewing information about search fields and search results columns for specimen search.

Copyright 2021-2022 President and Fellows of Harvard College

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
<cfif action EQ "flat" AND (NOT isdefined("session.roles") OR NOT listcontainsnocase(session.roles,"coldfusion_user"))>
	<!--- external users have no need to see the flat columns --->
	<cfset action="search">
</cfif>
<cfswitch expression="#action#">
	<cfcase value="search">
		<cfset pageTitle = "View Specimen Search Fields">
	</cfcase>
	<cfcase value="results">
		<cfset pageTitle = "View Specimen Results Columns">
	</cfcase>
	<cfcase value="flat">
		<cfset pageTitle = "View Flat Table Columns">
	</cfcase>
	<cfdefaultcase>
		<cfset pageTitle = "View Specimen Search Fields/Results">
	</cfdefaultcase>
</cfswitch>
<!---------------------------------------------------------------------------------->
<cfinclude template = "/shared/_header.cfm">

<cfset defaultSelectionMode = "none">
<cfif defaultSelectionMode EQ "none">
	<cfset defaultenablebrowserselection = "true">
<cfelse>
	<cfset defaultenablebrowserselection = "false">
</cfif>	
<!---------------------------------------------------------------------------------->
<cfswitch expression="#action#">
	<cfcase value="flat">
		<cfoutput>
			<main id="content">
				<div class="row mx-0 mb-3">
					<h2 class="h2">Fields in the FLAT table</h2>
					<p>This is the list of fields in the denormalized FLAT table.  These are available for search on the User SQL page.<p>
					<cfquery name="getFlatCols" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getFlatCols_result" timeout="#Application.query_timeout#">
						SELECT 
							all_tab_columns.column_name, 
							all_tab_columns.data_type, 
							all_col_comments.comments definition
						FROM all_tab_columns
            			left join all_col_comments
            				on  all_tab_columns.table_name = all_col_comments.table_name
            				and all_tab_columns.column_name = all_col_comments.column_name
            				and all_col_comments.owner = 'MCZBASE'
						WHERE 
							all_tab_columns.table_name='FLAT' 
							AND all_tab_columns.owner='MCZBASE'
						ORDER BY column_id
					</cfquery>
					<table class="table-responsive sortable">
						<thead>
							<th>
								<td>Fieldname</td>
								<td>Definition</td>
								<td>Data Type</td>
								<td>Example Value</td>
							</th>
						</thead>
						<tbody>
							<cfloop query="getFlatCols">
								<!--- get one not null example --->
								<cfset coll = RandRange(1,9)> 
								<cfquery name="getExample" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">									SELECT 
										<cfif getFlatCols.data_type EQ 'DATE'>
											to_char(#getFlatCols.column_name#,'yyyy-mm-dd') 
										<cfelse>
											#getFlatCols.column_name# 
										</cfif>
										as value
									FROM flat
									WHERE #getFlatCols.coumn_name# IS NOT NULL
										and rowum = 1
										and collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#col#">
										and collection_object_id not in (select collection_object_id from coll_object_encumbrance)
								</cfquery>
								<tr>
									<td>
										<cfif getFlatCols.data_type EQ 'DATE'>
											to_char(#getFlatCols.column_name#,'yyyy-mm-dd') 
										<cfelse>
											#getFlatCols.column_name#
										</cfif>
									</td>
									<td>#getFlatCols.definition#</td>
									<td>#getFlatCols.data_type#</td>
									<td>#getExample.value#<td>
								<tr>
							</cfloop>
						</tbody>
					</table>
				</div>
			</main>
		</cfoutput>
	</cfcase>
	<cfcase value="results">
		<div id="overlaycontainer" style="position: relative;"> 
			<!--- ensure fields have empty values present if not defined. --->
			<cfif not isdefined("category")>
				<cfset category="">
			</cfif>
			<cfif not isdefined("hidden")>
				<cfset hidden="">
			</cfif>
			<cfif not isdefined("column_name")>
				<cfset column_name="">
			</cfif>
			<cfif not isdefined("label")>
				<cfset label="">
			</cfif>
			<!--- Search Form ---> 
			<cfoutput>
				<main id="content">
					<section class="container-fluid mt-2 mb-3" role="search" aria-labelledby="formheader">
						<div class="row mx-0 mb-3">
							<div class="search-box">
								<div class="search-box-header">
									<h1 class="h3 text-white" id="formheading">Manage Specimen Results Columns (cf_spec_res_cols_r)</h1>
								</div>
								<div class="col-12 px-4 pt-3 pb-2">
									<form name="searchForm" id="searchForm">
										<input type="hidden" name="method" value="getcf_spec_res_cols" class="keeponclear">
										<div class="form-row mt-1 mb-2">
											<div class="col-md-2">
												<cfif NOT isDefined("category")><cfset category=""></cfif>
												<label for="category" class="data-entry-label" id="category_label">Category (= ! ~ !~ ,)</label>
												<input type="text" id="category" name="category" class="data-entry-input" value="#category#" aria-labelledby="category_label" >
												<script>
													jQuery(document).ready(function() {
														makeSpecResColsAutocomplete('category','category');
													});
												</script>
											</div>
											<div class="col-md-2">
												<cfif NOT isDefined("column_name")><cfset column_name=""></cfif>
												<label for="column_name" class="data-entry-label" id="column_name_label">Column Name (= ! ~ !~ ,)</label>
												<input type="text" id="column_name" name="column_name" class="data-entry-input" value="#column_name#" aria-labelledby="column_name_label" >
												<script>
													jQuery(document).ready(function() {
														makeSpecResColsAutocomplete('column_name','column_name');
													});
												</script>
											</div>
											<div class="col-md-2">
												<cfif NOT isDefined("label")><cfset label=""></cfif>
												<label for="label" class="data-entry-label" id="label_label">Label (= ! ~ !~ ,)</label>
												<input type="text" id="label" name="label" class="data-entry-input" value="#label#" aria-labelledby="label_label" >
												<script>
													jQuery(document).ready(function() {
														makeSpecResColsAutocomplete('label','label');
													});
												</script>
											</div>
											<div class="col-md-2">
												<cfif NOT isDefined("hidden")><cfset hidden=""></cfif>
												<label for="hiddenctl" class="data-entry-label" id="hidden_label">Hidden (= ! ~ !~ ,)</label>
												<input type="text" id="hiddenctl" name="hidden" class="data-entry-input" value="#hidden#" aria-labelledby="hidden_label" >
												<script>
													jQuery(document).ready(function() {
														makeSpecResColsAutocomplete('hiddenctl','hidden');
													});
												</script>
											</div>
											<div class="col-12 col-md-2">
												<cfif NOT isDefined("access_role")><cfset access_role=""></cfif>
												<label for="access_role" class="data-entry-label" id="label_access_role">Access Role (= ! ~ !~ ,)</label>
												<input type="text" id="access_role" name="access_role" class="data-entry-input" value="#access_role#" aria-labelledby="label_access_role" >
												<script>
													jQuery(document).ready(function() {
														makeSpecResColsAutocomplete('access_role','access_role');
													});
												</script>
											</div>
											<div class="col-12 col-md-2">
												<cfif NOT isDefined("sql_element")><cfset sql_element=""></cfif>
												<label for="sql_element" class="data-entry-label" id="label_sql_element">SQL (= ! ~ !~ ,)</label>
												<input type="text" id="sql_element" name="sql_element" class="data-entry-input" value="#sql_element#" aria-labelledby="label_sql_element" >
												<script>
													jQuery(document).ready(function() {
														makeSpecResColsAutocomplete('sql_element','sql_element');
													});
												</script>
											</div>
										</div>
										<div class="form-row mt-2 mx-0">
											<div class="col-12 px-0 pt-0">
												<button class="btn-xs btn-primary px-2 my-2 mr-1" id="searchButton" type="submit" aria-label="Search for Specimen Search Fields">Search<span class="fa fa-search pl-1"></span></button>
												<button type="reset" class="btn-xs btn-warning my-2 mr-1" aria-label="Reset search form to inital values" onclick="">Reset</button>
												<button type="button" class="btn-xs btn-warning my-2 mr-1" aria-label="Start a new search with a clear form" onclick="window.location.href='#Application.serverRootUrl#/specimens/viewSpecimenSearchMetadata.cfm?action=results';" >New Search</button>
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
									{ name: 'CF_SPEC_RES_COLS_ID', type: 'string' },
									{ name: 'SQL_ELEMENT', type: 'string' },
									{ name: 'DISP_ORDER', type: 'string' },
									{ name: 'COLUMN_NAME', type: 'string' },
									{ name: 'CATEGORY', type: 'string' },
									{ name: 'DATA_TYPE', type: 'string' },
									{ name: 'ACCESS_ROLE', type: 'string' },
									{ name: 'HIDEABLE', type: 'string' },
									{ name: 'HIDDEN', type: 'string' },
									{ name: 'CELLSRENDERER', type: 'string' },
									{ name: 'WIDTH', type: 'string' },
									{ name: 'LABEL', type: 'string' }
								],
								root: 'cf_spec_res_cols_Record',
								id: 'CF_SPEC_RES_COLS_ID',
								url: '/specimens/component/metadata.cfc?' + $('##searchForm').serialize(),
								timeout: #Application.ajax_timeout#000,  // units not specified, miliseconds? 
								loadError: function(jqXHR, textStatus, error) {
									handleFail(jqXHR,textStatus,error, "Error performing search for cf_spec_res_cols rows: "); 
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
								pagesizeoptions: ['5','10','50','100','500'],
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
									{text: 'Column Name', datafield: 'COLUMN_NAME', width: 140, hideable: true, hidden: getColHidProp('COLUMN_NAME', false) },
									{text: 'Label', datafield: 'LABEL', width: 180, hideable: true, hidden: getColHidProp('LABEL', false) },
									{text: 'Category', datafield: 'CATEGORY', width: 120, hideable: true, hidden: getColHidProp('CATEGORY', false) },
									{text: 'Order', datafield: 'DISP_ORDER', width: 70, hideable: true, hidden: getColHidProp('DISP_ORDER', false) },
									{text: 'Access Role', datafield: 'ACCESS_ROLE', width: 100, hideable: true, hidden: getColHidProp('ACCESS_ROLE', false) },
									{text: 'Hideable', datafield: 'HIDEABLE', width: 80, hideable: true, hidden: getColHidProp('HIDEABLE', false) },
									{text: 'Hidden', datafield: 'HIDDEN', width: 70, hideable: true, hidden: getColHidProp('HIDDEN', false) },
									{text: 'CellsRenderer', datafield: 'CELLSRENDERER', width: 150, hideable: true, hidden: getColHidProp('CELLSRENDERER', false) },
									{text: 'Width', datafield: 'WIDTH', width: 70, hideable: true, hidden: getColHidProp('WIDTH', false) },
									{text: 'Data Type', datafield: 'DATA_TYPE', width: 100, hideable: true, hidden: getColHidProp('DATA_TYPE', false) },
									{text: 'SQL', datafield: 'SQL_ELEMENT', width: 250, hideable: true, hidden: getColHidProp('SQL_ELEMENT', false) },
									{text: 'ID', datafield: 'CF_SPEC_RES_COLS_ID', editable: false, hideable: true, hidden: getColHidProp('CF_SPEC_RES_COLS_ID', false) }
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
								$('##resultLink').html('<a href="/specimens/viewSpecimenSearchMetadata.cfm?action=results&execute=true&' + $('##searchForm').serialize() + '">Link to this search</a>');
								gridLoaded('searchResultsGrid','cf_spec_res_col_r row');
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
							$('##resultCount').html('Found ' + rowcount + ' ' + searchType + '.');
						} else { 
							$('##resultCount').html('Found ' + rowcount + ' ' + searchType + 's.');
						}
						// set maximum page size
						// commenting out dynamic page size set, for some reason it causes browser to go into a 15 second+ javascript delay 
 						// for just this grid when all rows are selected, so using pagable fails, for just this grid... 
						$('##' + gridId).jqxGrid({ pageable: false });
						//if (rowcount > 100) { 
						//	$('##' + gridId).jqxGrid({ pagesizeoptions: ['5','50', '100', rowcount],pagesize: 50});
						//} else if (rowcount > 50) { 
						//	$('##' + gridId).jqxGrid({ pagesizeoptions: ['5','50', rowcount],pagesize:50});
						//} else { 
						//	$('##' + gridId).jqxGrid({ pageable: false });
						//}
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
	<cfcase value="search">
		<div id="overlaycontainer" style="position: relative;"> 
			<!--- ensure fields have empty values present if not defined. --->
			<cfif not isdefined("search_category")>
				<cfset search_category="">
			</cfif>
			<cfif not isdefined("table_name")>
				<cfset table_name="">
			</cfif>
			<cfif not isdefined("column_name")>
				<cfset column_name="">
			</cfif>
			<cfif not isdefined("label")>
				<cfset label="">
			</cfif>
			<!--- Search Form ---> 
			<cfoutput>
				<main id="content">
					<section class="container-fluid mt-2 mb-1" role="search" aria-labelledby="formheader">
						<div class="row mx-0 mb-3">
							<div class="search-box">
								<div class="search-box-header">
									<h1 class="h3 text-white" id="formheading">
										View Specimen Search Fields (<a href="/Specimens.cfm?action=builderSearch" target="_blank" class="text-light">specimen search builder</a> help)
									</h1>
								</div>
								<div class="col-12 px-4 pt-3 pb-2">
									<form name="searchForm" id="searchForm">
										<input type="hidden" name="method" value="getcf_spec_search_cols" class="keeponclear">
										<div class="form-row mt-1 mb-2">
											<div class="col-12 col-md-2">
												<cfif NOT isDefined("search_category")><cfset search_category=""></cfif>
												<label for="search_category" class="data-entry-label" id="search_category_label">Search Category (= ! ~ !~ ,)</label>
												<input type="text" id="search_category" name="search_category" class="data-entry-input" value="#search_category#" aria-labelledby="search_category_label" >
												<script>
													jQuery(document).ready(function() {
														makeSpecSearchColsAutocomplete('search_category','search_category');
													});
												</script>
											</div>
											<div class="col-12 col-md-2">
												<cfif NOT isDefined("table_name")><cfset table_name=""></cfif>
												<label for="table_name" class="data-entry-label" id="table_name_label">Table Name (= ! ~ !~ ,)</label>
												<input type="text" id="table_name" name="table_name" class="data-entry-input" value="#table_name#" aria-labelledby="table_name_label" >
												<script>
													jQuery(document).ready(function() {
														makeSpecSearchColsAutocomplete('table_name','table_name');
													});
												</script>
											</div>
											<div class="col-12 col-md-2">
												<cfif NOT isDefined("column_name")><cfset column_name=""></cfif>
												<label for="column_name" class="data-entry-label" id="column_name_label">Column Name (= ! ~ !~ ,)</label>
												<input type="text" id="column_name" name="column_name" class="data-entry-input" value="#column_name#" aria-labelledby="column_name_label" >
												<script>
													jQuery(document).ready(function() {
														makeSpecSearchColsAutocomplete('column_name','column_name');
													});
												</script>
											</div>
											<div class="col-12 col-md-2">
												<cfif NOT isDefined("label")><cfset label=""></cfif>
												<label for="label" class="data-entry-label" id="label_label">Label (= ! ~ !~ ,)</label>
												<input type="text" id="label" name="label" class="data-entry-input" value="#label#" aria-labelledby="label_label" >
												<script>
													jQuery(document).ready(function() {
														makeSpecSearchColsAutocomplete('label','label');
													});
												</script>
											</div>
											<div class="col-12 col-md-2">
												<cfif NOT isDefined("access_role")><cfset access_role=""></cfif>
												<label for="access_role" class="data-entry-label" id="label_access_role">Access Role (= ! ~ !~ ,)</label>
												<input type="text" id="access_role" name="access_role" class="data-entry-input" value="#access_role#" aria-labelledby="label_access_role" >
												<script>
													jQuery(document).ready(function() {
														makeSpecSearchColsAutocomplete('access_role','access_role');
													});
												</script>
											</div>
											<div class="col-12 col-md-2">
												<cfif NOT isDefined("description")><cfset description=""></cfif>
												<label for="description" class="data-entry-label" id="label_description">Description <span class="small">(NULL, NOT NULL)</span></label>
												<input type="text" id="description" name="description" class="data-entry-input" value="#description#" aria-labelledby="label_description" >
											</div>
											<cfif isdefined("session.roles") and listfindnocase(session.roles,"COLLOPS")>
												<div class="col-12 col-md-2">
													<cfif NOT isDefined("ui_function")><cfset ui_function=""></cfif>
													<label for="ui_function" class="data-entry-label" id="label_ui_function">UI Function (NOT NULL = ! ~ !~ , NULL)</label>
													<input type="text" id="ui_function" name="ui_function" class="data-entry-input" value="#ui_function#" aria-labelledby="label_ui_function" >
													<script>
														jQuery(document).ready(function() {
															makeSpecSearchColsAutocomplete('ui_function','ui_function');
														});
													</script>
												</div>
											</cfif>
										</div>
										<div class="form-row mt-2 mx-0">
											<div class="col-12 px-0 pt-0">
												<button class="btn-xs btn-primary px-2 my-2 mr-1" id="searchButton" type="submit" aria-label="Search for Specimen Search Fields">Search<span class="fa fa-search pl-1"></span></button>
												<button type="reset" class="btn-xs btn-warning my-2 mr-1" aria-label="Reset search form to inital values" onclick="">Reset</button>
												<button type="button" class="btn-xs btn-warning my-2 mr-1" aria-label="Start a new search with a clear form" onclick="window.location.href='#Application.serverRootUrl#/specimens/viewSpecimenSearchMetadata.cfm?action=search';" >New Search</button>
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

					$(document).ready(function() {
						/* Setup jqxgrid for Search */
						$('##searchForm').bind('submit', function(evt){
							evt.preventDefault();
					
							$("##overlay").show();
					
							$("##searchResultsGrid").replaceWith('<div id="searchResultsGrid" class="jqxGrid" style="z-index: 1;"></div>');
							$('##resultCount').html('');
							$('##resultLink').html('');
							$('##selectModeContainer').hide();

							// Cell renderers
							var autocompleteCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
								var rowData = jQuery("##searchResultsGrid").jqxGrid('getrowdata',row);
								var result = "";
								var ui_function = rowData['UI_FUNCTION'];
								if (ui_function) {
									if (ui_function.includes('makeCTFieldSearchAutocomplete')) { 
                              var table = "";
										var ui_function_bits = ui_function.split(',');
										if (ui_function_bits.length==2) {
											table = ui_function_bits[1].replace(/[^A-Z_]/,"");
										}
										if (table.length>0) { 
											result = '<span class="#cellRenderClasses#" style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; "><a href="/vocabularies/ControlledVocabulary.cfm?table=CT'+table+'" target="_blank">Yes</a></span>';
										} else { 
											result = '<span class="#cellRenderClasses#" style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; ">Yes</span>';
										}
									} else { 
										result = '<span class="#cellRenderClasses#" style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; ">Yes</span>';
									}
								} else { 
									result = '<span class="#cellRenderClasses#" style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; ">'+value+'</span>';
								}
								return result;
							};
							var categoryCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
								var rowData = jQuery("##searchResultsGrid").jqxGrid('getrowdata',row);
								var result = "";
								var category = rowData['SEARCH_CATEGORY'];
								if (category=='Accessions' || category=='Attributes' || category=='Cataloged Item' || category=='Collecting Events' || category=='Named Groups' || category=='Citations' || category=='Collectors' || category=='Identifications' || category=='Media' || category=='Specimen Parts'  ) {
									result = '<span class="#cellRenderClasses#" style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; "><a href="/documentation/er_diagrams/'+value.toLowerCase().replace(' ','_')+'.svg" target="blank">'+value+'</a></span>';
								} else { 
									result = '<span class="#cellRenderClasses#" style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; ">'+value+'</span>';
								}
								return result;
							};
							var tableCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
								var rowData = jQuery("##searchResultsGrid").jqxGrid('getrowdata',row);
								var result = "";
								var category = rowData['SEARCH_CATEGORY'];
								var tablename = rowData['TABLE_NAME'];
								if (category=='Collecting Events' && ( tablename == 'LAT_LONG' || tablename == 'LOCALITY' || tablename == 'GEOG_AUTH_REC' ) ) {
									result = '<span class="#cellRenderClasses#" style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; "><a href="/documentation/er_diagrams/localities.svg" target="blank">'+value+'</a></span>';
								} else { 
									result = '<span class="#cellRenderClasses#" style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; ">'+value+'</span>';
								}
								return result;
							};
					
							var search =
							{
								datatype: "json",
								datafields:
								[
									{ name: 'ID', type: 'string' },
									{ name: 'TABLE_NAME', type: 'string' },
									{ name: 'TABLE_ALIAS', type: 'string' },
									{ name: 'COLUMN_NAME', type: 'string' },
									{ name: 'COLUMN_ALIAS', type: 'string' },
									{ name: 'SEARCH_CATEGORY', type: 'string' },
									{ name: 'DATA_TYPE', type: 'string' },
									{ name: 'DATA_LENGTH', type: 'string' },
									{ name: 'LABEL', type: 'string' },
									{ name: 'ACCESS_ROLE', type: 'string' },
									{ name: 'UI_FUNCTION', type: 'string' },
									{ name: 'EXAMPLE_VALUES', type: 'string' },
									{ name: 'DESCRIPTION', type: 'string' },
									{ name: 'DEFINITION', type: 'string' }
								],
								root: 'cf_spec_search_cols_Record',
								id: 'ID',
								url: '/specimens/component/metadata.cfc?' + $('##searchForm').serialize(),
								timeout: #Application.ajax_timeout#000,  // units not specified, miliseconds? 
								loadError: function(jqXHR, textStatus, error) {
									handleFail(jqXHR,textStatus,error, "Error performing search for cf_spec_search_cols rows: "); 
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
								pagesizeoptions: ['5','10','50','100','500'],
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
									{text: 'Category', datafield: 'SEARCH_CATEGORY', width: 110, hideable: true, hidden: getColHidProp('SEARCH_CATEGORY', false), cellsrenderer: categoryCellRenderer },
									{text: 'Label', datafield: 'LABEL', width: 250, hideable: false, hidden: false },
									{text: 'Search Description', datafield: 'DESCRIPTION', width: 400, hideable: true, hidden: getColHidProp('DESCRIPTION', false) },
									{text: 'Example Values', datafield: 'EXAMPLE_VALUES', width: 240, hideable: true, hidden: getColHidProp('EXAMPLE_VALUES', false) },
									{text: 'Autocomplete', datafield: 'UI_FUNCTION', width: 60, hideable: true, hidden: getColHidProp('UI_FUNCTION', false), cellsrenderer: autocompleteCellRenderer },
									{text: 'Field Definition', datafield: 'DEFINITION', width: 200, hideable: true, hidden: getColHidProp('DEFINITION', false) },
									{text: 'Table Name', datafield: 'TABLE_NAME', width: 140, hideable: true, hidden: getColHidProp('TABLE_NAME', false), cellsrenderer: tableCellRenderer },
									{text: 'Column Name', datafield: 'COLUMN_NAME', width: 150, hideable: true, hidden: getColHidProp('COLUMN_NAME', false) },
									{text: 'Data Type', datafield: 'DATA_TYPE', width: 80, hideable: true, hidden: getColHidProp('DATA_TYPE', false) },
									{text: 'Access Role', datafield: 'ACCESS_ROLE', hideable: true, hidden: getColHidProp('ACCESS_ROLE', false) }
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
								$('##resultLink').html('<a href="/specimens/viewSpecimenSearchMetadata.cfm?action=search&execute=true&' + $('##searchForm').serialize() + '">Link to this search</a>');
								gridLoaded('searchResultsGrid','cf_spec_search_col row');
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
							$('##resultCount').html('Found ' + rowcount + ' ' + searchType + '.');
						} else { 
							$('##resultCount').html('Found ' + rowcount + ' ' + searchType + 's.');
						}
						// set maximum page size
						if (rowcount > 100) { 
							$('##' + gridId).jqxGrid({ pagesizeoptions: ['5','10','50', '100', rowcount],pagesize: 50});
						} else if (rowcount > 50) { 
							$('##' + gridId).jqxGrid({ pagesizeoptions: ['5','10','50', rowcount],pagesize:50});
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
	<cfdefaultcase>
		<cfthrow type="Application" message="Unknown action.">
	</cfdefaultcase>
</cfswitch>
<!---------------------------------------------------------------------->
<cfinclude template = "/shared/_footer.cfm">
