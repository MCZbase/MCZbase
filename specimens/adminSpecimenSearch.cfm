<!---
specimens/adminSpecimenSearch.cfm

For managing search fields and search results columns for specimen search.

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

<cfif not isdefined("action")>
	<cfset action="search">
</cfif>
<cfswitch expression="#action#">
	<cfcase value="search">
		<cfset pageTitle = "Manage Specimen Search Fields">
	</cfcase>
	<cfcase value="results">
		<cfset pageTitle = "Manage Specimen Results Columns">
	</cfcase>
	<cfcase value="newsearchfield">
		<cfset pageTitle = "Add New Specimen Search Field">
	</cfcase>
	<cfcase value="newresultcolumn">
		<cfset pageTitle = "Add New Specimen Result Column">
	</cfcase>
	<cfdefaultcase>
		<cfset pageTitle = "Manage Specimen Search Fields/Results">
	</cfdefaultcase>
</cfswitch>
<!---------------------------------------------------------------------------------->
<cfset includeJQXMoreInputs="true">
<cfinclude template = "/shared/_header.cfm">
<!---------------------------------------------------------------------------------->
<cfswitch expression="#action#">
	<cfcase value="newsearchfield">
		<cfthrow message="Not implemented yet">
	</cfcase>
	<cfcase value="newresultcolumn">
		<cfthrow message="Not implemented yet">
	</cfcase>
	<cfcase value="savenewsearchfield">
		<cfthrow message="Not implemented yet">
	</cfcase>
	<cfcase value="savenewresultcolumn">
		<cfthrow message="Not implemented yet">
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
												<button type="button" class="btn-xs btn-warning my-2 mr-1" aria-label="Start a new search with a clear form" onclick="window.location.href='#Application.serverRootUrl#/specimens/adminSpecimenSearch.cfm?action=results';" >New Search</button>
											</div>
										</div>
									</form>
								</div><!--- col --->
							</div><!--- search box --->
						</div><!--- row --->
					</section>
					<section class="container-fluid mt-1 mb-3">
						<cfset openAccord = "collapse">
						<cfset btnAccord = "">
						<cfset ariaExpanded ="false">
						<div class="accordion w-100" id="itemAccordion">
							<div class="card bg-light">
								<div class="card-header" id="itemAccordHeadingOne">
									<h3 class="h4 my-0">
										<button class="headerLnk w-100 text-left #btnAccord#" type="button" data-toggle="collapse" data-target="##itemCollapseOne" aria-expanded="#ariaExpanded#" aria-controls="itemCollapseOne">
											Add Specimen Results Column
										</button>
									</h3>
								</div>
								<div id="itemCollapseOne" class="#openAccord#" aria-labelledby="itemAccordHeadingOne" data-parent="##itemAccordion">
									<div class="card-body px-3">
										<form id="addSpecResColForm">
											<div class="row mx-0">
												<input type="hidden" name="method" value="addcf_spec_res_cols">
												<input type="hidden" name="returnformat" value="json">
												<input type="hidden" name="queryformat" value="column">
												<div class="col-12 col-md-3 px-1 mt-1">
													<label for="in_category" class="data-entry-label">Category</label>
													<input type="text" class="data-entry-input reqdClr" name="category" id="in_category" required>
													<script>
														jQuery(document).ready(function() {
															makeSpecResColsAutocomplete('in_category','category');
														});
													</script>
												</div>
												<div class="col-12 col-md-3 px-1 mt-1">
													<label for="in_column_name" class="data-entry-label">Column Name</label>
													<input type="text" class="data-entry-input reqdClr" name="column_name" id="in_column_name" required>
													<script>
														jQuery(document).ready(function() {
															makeSpecResColsAutocomplete('in_column_name','column_name');
														});
													</script>
												</div>
												<div class="col-12 col-md-3 px-1 mt-1">
													<label for="in_sql_element" class="data-entry-label">SQL Element (e.g. flatTableName.guid)</label>
													<input type="text" class="data-entry-input reqdClr" name="sql_element" id="in_sql_element" required>
												</div>
												<div class="col-12 col-md-3 px-1 mt-1">
													<label for="in_label" class="data-entry-label">Label</label>
													<input type="text" class="data-entry-input reqdClr" name="label" id="in_label" required>
												</div>
											</div>
											<div class="row mx-0">
												<div class="col-12 col-md-1 px-1 mt-1">
													<label for="in_disp_order" class="data-entry-label">Display Order</label>
													<input type="number" class="data-entry-input reqdClr" name="disp_order" id="in_disp_order" required pattern="[0-9]+" >
												</div>
												<div class="col-12 col-md-2 px-1 mt-1">
													<label for="in_access_role" class="data-entry-label">Access Role</label>
													<select class="data-entry-select reqdClr mb-1" name="access_role" id="in_access_role" required >
														<option value="PUBLIC" selected>PUBLIC</option>
														<option value="COLDFUSION_USER">COLDFUSION_USER</option>
														<option value="DATA_ENTRY">DATA_ENTRY</option>
														<option value="MANAGE_TRANSACTIONS">COLDFUSION_USER</option>
														<option value="MANAGE_SPECIMENS">COLDFUSION_USER</option>
														<option value="HIDE">HIDE (column is not queried or shown)</option>
													</select>
												</div>
												<div class="col-12 col-md-2 px-1 mt-1">
													<label for="in_hideable" class="data-entry-label">Hideable</label>
													<select class="data-entry-select reqdClr mb-1" size="1" name="hideable" id="in_hideable" required >
														<option value="true" selected>true (user can show/hide)</option>
														<option value="false">false (always shown)</option>
													</select>
												</div>
												<div class="col-12 col-md-2 px-1 mt-1">
													<label for="in_hidden" class="data-entry-label">Hidden</label>
													<select class="data-entry-select reqdClr mb-1" size="1" name="hidden" id="in_hidden" required >
														<option value="true" selected>true (hidden by default)</option>
														<option value="false">false (shown by default)</option>
													</select>
												</div>
												<div class="col-12 col-md-1 px-1 mt-1">
													<label for="in_width" class="data-entry-label">Width</label>
													<input type="number" class="data-entry-input reqdClr" name="width" id="in_width" required pattern="[0-9]+" >
												</div>
												<div class="col-12 col-md-2 px-1 mt-1">
													<label for="in_cellsrenderer" class="data-entry-label">Cellsrenderer</label>
													<input type="text" class="data-entry-input" name="cellsrenderer" id="in_cellsrenderer">
												</div>
												<div class="col-12 col-md-2 px-1 mt-1">
													<label for="in_data_type" class="data-entry-label">Data Type</label>
													<select class="data-entry-select reqdClr mb-1" name="data_type" id="in_data_type" required >
														<option value="VARCHAR2" selected>VARCHAR2</option>
														<option value="NUMBER">NUMBER</option>
														<option value="DATE">DATE</option>
														<option value="CHAR">CHAR</option>
														<option value="CLOB">CLOB</option>
													</select>
												</div>
											</div>
											<div class="row mx-0">
												<div class="form-group col-12 px-1 pt-2">
													<button class="btn btn-xs btn-primary mr-1" type="button" onclick=" addSpecResColRow();" value="Add Row">Add Row</button>
													<span id="addItemFeedback" class="text-danger">&nbsp;</span>
												</div>
											</div>
										</form>
									</div>
								</div>
							</div>
							<script>
								function addSpecResColRow() {
									$('##addItemFeedback').html("Saving...");
									$('##addItemFeedback').addClass('text-warning');
									$('##addItemFeedback').removeClass('text-success');
									$('##addItemFeedback').removeClass('text-danger');
									jQuery.ajax( {
										url : "/specimens/component/admin.cfc",
										type : "post",
										dataType : "json",
										data : $("##addSpecResColForm").serialize(),
										success : function (data) {
											$('##addItemFeedback').html("Added row to cf_spec_res_cols_r.");
											$('##addItemFeedback').addClass('text-success');
											$('##addItemFeedback').removeClass('text-warning');
											$('##addItemFeedback').removeClass('text-danger');
											$("##catalog_number").val('');
											$("##no_of_spec").val('');
											$("##type_status").val('');
										},
										error: function(jqXHR,textStatus,error){
											$('##addItemFeedback').html("Error");
											$('##addItemFeedback').addClass('text-danger');
											$('##addItemFeedback').removeClass('text-success');
											$('##addItemFeedback').removeClass('text-warning');
											handleFail(jqXHR,textStatus,error,"adding row to cf_spec_res_cols_r.");
										}
									});
								};
							</script>
						</div>
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
					function deleteSpecResRow(id) {
						jQuery.ajax({
						url : "/specimens/component/admin.cfc",
							type : "post",
							dataType : "json",
							data : {
								method : "deleteCFSpecResColsRow",
								returnformat : "json",
								queryformat : 'column',
								CF_SPEC_RES_COLS_ID : id
							},
							success : function (data) {
								$('##searchResultsGrid').jqxGrid('deleterow', id);
							},
							error: function(jqXHR,textStatus,error){
								handleFail(jqXHR,textStatus,error,"removing cf_spec_res_cols item");
							}
						});
					};
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

							// Cell renderers
							var deleteCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
								var rowData = jQuery("##searchResultsGrid").jqxGrid('getrowdata',row);
								var result = "";
								var itemid = rowData['CF_SPEC_RES_COLS_ID'];
								if (itemid) {
									result = '<span class="#cellRenderClasses# float-left mt-1"' + columnproperties.cellsalign + '; "><a name="deleteRow" type="button" value="Delete" onclick="deleteSpecResRow(' + itemid+ ');" class="btn btn-xs btn-danger">Delete</a></span>';
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
								updaterow: function (rowid, rowdata, commit) {
									var data = "method=updatecf_spec_res_cols";
									data = data + "&CF_SPEC_RES_COLS_ID=" + rowdata.CF_SPEC_RES_COLS_ID;
									data = data + "&SQL_ELEMENT=" + rowdata.SQL_ELEMENT;
									data = data + "&DISP_ORDER=" + rowdata.DISP_ORDER;
									data = data + "&COLUMN_NAME=" + rowdata.COLUMN_NAME;
									data = data + "&CATEGORY=" + rowdata.CATEGORY;
									data = data + "&DATA_TYPE=" + rowdata.DATA_TYPE;
									data = data + "&ACCESS_ROLE=" + rowdata.ACCESS_ROLE;
									data = data + "&HIDEABLE=" + rowdata.HIDEABLE;
									data = data + "&HIDDEN=" + rowdata.HIDDEN;
									data = data + "&CELLSRENDERER=" + rowdata.CELLSRENDERER;
									data = data + "&WIDTH=" + rowdata.WIDTH;
									data = data + "&LABEL=" + rowdata.LABEL;
									$.ajax({
										dataType: 'json',
										url: '/specimens/component/admin.cfc',
										data: data,
											success: function (data, status, xhr) {
											commit(true);
										},
										error: function (jqXHR,textStatus,error) {
											commit(false);
											handleFail(jqXHR,textStatus,error,"saving cf_spec_res_cols row");
										}
									});
								},
								root: 'cf_spec_res_cols_Record',
								id: 'CF_SPEC_RES_COLS_ID',
								url: '/specimens/component/admin.cfc?' + $('##searchForm').serialize(),
								timeout: 30000,  // units not specified, miliseconds? 
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
								editable: true,
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
									{text: 'Column Name', datafield: 'COLUMN_NAME', width: 140, hideable: true, hidden: getColHidProp('COLUMN_NAME', false) },
									{text: 'Label', datafield: 'LABEL', width: 180, hideable: true, hidden: getColHidProp('LABEL', false) },
									{text: 'Category', datafield: 'CATEGORY', width: 120, hideable: true, hidden: getColHidProp('CATEGORY', false) },
									{text: 'Order', datafield: 'DISP_ORDER', width: 70, hideable: true, hidden: getColHidProp('DISP_ORDER', false), 
										columntype: 'numberinput', 
										initeditor: function (row, cellvalue, editor) { 
											editor.jqxNumberInput({ decimalDigits: 0 } ); 
										}
									},
									{text: 'Access Role', datafield: 'ACCESS_ROLE', width: 100, hideable: true, hidden: getColHidProp('ACCESS_ROLE', false) },
									{text: 'Hideable', datafield: 'HIDEABLE', width: 80, hideable: true, hidden: getColHidProp('HIDEABLE', false),
										columntype: 'dropdownlist', 
										initeditor: function (row, cellvalue, editor) { 
											var tfList = ["true","false"]; 
											editor.jqxDropDownList( { source: tfList } ); 
										}
									},
									{text: 'Hidden', datafield: 'HIDDEN', width: 70, hideable: true, hidden: getColHidProp('HIDDEN', false),
										columntype: 'dropdownlist', 
										initeditor: function (row, cellvalue, editor) { 
											var tfList = ["true","false"]; 
											editor.jqxDropDownList( { source: tfList }); 
										}
									},
									{text: 'CellsRenderer', datafield: 'CELLSRENDERER', width: 150, hideable: true, hidden: getColHidProp('CELLSRENDERER', false) },
									{text: 'Width', datafield: 'WIDTH', width: 70, hideable: true, hidden: getColHidProp('WIDTH', false),
										columntype: 'numberinput', 
										initeditor: function (row, cellvalue, editor) { 
											editor.jqxNumberInput({ decimalDigits: 0 } ); 
										}
									},
									{text: 'Data Type', datafield: 'DATA_TYPE', width: 100, hideable: true, hidden: getColHidProp('DATA_TYPE', false),
										columntype: 'dropdownlist', 
										initeditor: function (row, cellvalue, editor) { 
											var typeList = ["VARCHAR2","NUMBER","DATE","CHAR","CLOB"];
											editor.jqxDropDownList( { source: typeList }); 
										}
									},
									{text: 'SQL', datafield: 'SQL_ELEMENT', width: 250, hideable: true, hidden: getColHidProp('SQL_ELEMENT', false) },
									{text: 'ID', datafield: 'CF_SPEC_RES_COLS_ID', editable: false, hideable: true, hidden: getColHidProp('CF_SPEC_RES_COLS_ID', false), cellsrenderer: deleteCellRenderer }
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
								$('##resultLink').html('<a href="/specimens/adminSpecimenSearch.cfm?action=results&execute=true&' + $('##searchForm').serialize() + '">Link to this search</a>');
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
						var items = "."
						if (rowcount > 0) {
							items = ". Click on a cell to edit. ";
						}
						if (rowcount == 1) {
							$('##resultCount').html('Found ' + rowcount + ' ' + searchType + items);
						} else { 
							$('##resultCount').html('Found ' + rowcount + ' ' + searchType + 's' + items);
						}
						// set maximum page size
						// commenting out dynamic page size set, for some reason it causes browser to go into a 15 second+ javascript delay 
 						// for just this grid when all rows are selected, so using pagable fales, for just this grid... 
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
									<h1 class="h3 text-white" id="formheading">Manage Specimen Search Fields (cf_spec_search_cols)</h1>
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
												<cfif NOT isDefined("ui_function")><cfset ui_function=""></cfif>
												<label for="ui_function" class="data-entry-label" id="label_ui_function">UI Function (NOT NULL = ! ~ !~ , NULL)</label>
												<input type="text" id="ui_function" name="ui_function" class="data-entry-input" value="#ui_function#" aria-labelledby="label_ui_function" >
												<script>
													jQuery(document).ready(function() {
														makeSpecSearchColsAutocomplete('ui_function','ui_function');
													});
												</script>
											</div>
										</div>
										<div class="form-row mt-2 mx-0">
											<div class="col-12 px-0 pt-0">
												<button class="btn-xs btn-primary px-2 my-2 mr-1" id="searchButton" type="submit" aria-label="Search for Specimen Search Fields">Search<span class="fa fa-search pl-1"></span></button>
												<button type="reset" class="btn-xs btn-warning my-2 mr-1" aria-label="Reset search form to inital values" onclick="">Reset</button>
												<button type="button" class="btn-xs btn-warning my-2 mr-1" aria-label="Start a new search with a clear form" onclick="window.location.href='#Application.serverRootUrl#/specimens/adminSpecimenSearch.cfm?action=search';" >New Search</button>
											</div>
										</div>
									</form>
								</div><!--- col --->
							</div><!--- search box --->
						</div><!--- row --->
					</section>
					<section class="container-fluid mt-1 mb-3">
						<cfset openAccord = "collapse">
						<cfset btnAccord = "">
						<cfset ariaExpanded ="false">
						<div class="accordion w-100" id="itemAccordion">
							<div class="card bg-light">
								<div class="card-header" id="itemAccordHeadingOne">
									<h3 class="h4 my-0">
										<button class="headerLnk w-100 text-left #btnAccord#" type="button" data-toggle="collapse" data-target="##itemCollapseOne" aria-expanded="#ariaExpanded#" aria-controls="itemCollapseOne">
											Add Specimen Search Field
										</button>
									</h3>
								</div>
								<div id="itemCollapseOne" class="#openAccord#" aria-labelledby="itemAccordHeadingOne" data-parent="##itemAccordion">
									<div class="card-body px-3">
										<form id="addSpecSearchColForm">
											<div class="row mx-0">
												<input type="hidden" name="method" value="addCFSpecSearchColsRow">
												<input type="hidden" name="returnformat" value="json">
												<input type="hidden" name="queryformat" value="column">
												<div class="col-12 col-md-3 px-1 mt-1">
													<label for="in_table_name" class="data-entry-label">Table Name</label>
													<input type="text" class="data-entry-input reqdClr" name="table_name" id="in_table_name" required >
													<script>
														jQuery(document).ready(function() {
															makeSpecSearchColsAutocomplete('in_table_name','table_name');
														});
													</script>
												</div>
												<div class="col-12 col-md-3 px-1 mt-1">
													<label for="in_table_alias" class="data-entry-label">Table Alias (in build_query_dbms_sql joins)</label>
													<input type="text" class="data-entry-input reqdClr" name="table_alias" id="in_table_alias" required >
													<script>
														jQuery(document).ready(function() {
															makeSpecSearchColsAutocomplete('in_table_alias','table_alias');
														});
													</script>
												</div>
												<div class="col-12 col-md-3 px-1 mt-1">
													<label for="in_column_name" class="data-entry-label">Column Name</label>
													<input type="text" class="data-entry-input reqdClr" name="column_name" id="in_column_name" required >
												</div>
												<div class="col-12 col-md-3 px-1 mt-1">
													<label for="in_column_alias" class="data-entry-label">Column Alias (unique)</label>
													<input type="text" class="data-entry-input reqdClr" name="column_alias" id="in_column_alias" required >
												</div>
											</div>
											<div class="row mx-0">
												<div class="col-12 col-md-3 px-1 mt-1">
													<label for="in_search_category" class="data-entry-label">Search Category (picks build_query_dbms_sql joins)</label>
													<input type="text" class="data-entry-input reqdClr" name="search_category" id="in_search_category" required >
													<script>
														jQuery(document).ready(function() {
															makeSpecSearchColsAutocomplete('in_search_category','search_category');
														});
													</script>
												</div>
												<div class="col-12 col-md-3 px-1 mt-1">
													<label for="in_data_type" class="data-entry-label">Data Type</label>
													<select class="data-entry-select reqdClr mb-1" name="data_type" id="in_data_type" required >
														<option value="VARCHAR2" selected>VARCHAR2</option>
														<option value="NUMBER">NUMBER</option>
														<option value="DATE">DATE</option>
														<option value="CHAR">CHAR</option>
														<option value="CLOB">CLOB</option>
														<option value="CLOB">CTXKEYWORD</option>
													</select>
												</div>
												<div class="col-12 col-md-3 px-1 mt-1">
													<label for="in_data_length" class="data-entry-label">Data Length</label>
													<input type="number" class="data-entry-input reqdClr" name="data_length" id="in_data_length" required pattern="[0-9]+" >
												</div>
												<div class="col-12 col-md-3 px-1 mt-1">
													<label for="in_access_role" class="data-entry-label">Access Role (to see in builder)</label>
													<select class="data-entry-select reqdClr mb-1" name="access_role" id="in_access_role" required >
														<option value="PUBLIC" selected>PUBLIC</option>
														<option value="COLDFUSION_USER">COLDFUSION_USER</option>
														<option value="DATA_ENTRY">DATA_ENTRY</option>
														<option value="MANAGE_TRANSACTIONS">MANAGE_TRANSACTIONS</option>
														<option value="MANAGE_SPECIMENS">MANAGE_SPECIMENS</option>
														<option value="MANAGE_CONTAINER">MANAGE_CONTAINER</option>
														<option value="GLOBAL_ADMIN">GLOBAL_ADMIN</option>
														<option value="MANAGE_AGENTS">MANAGE_AGENTS</option>
														<option value="MANAGE_MEDIA">MANAGE_MEDIA</option>
														<option value="MANAGE_COLLECTION">MANAGE_COLLECTION</option>
														<option value="MANAGE_TAXONOMY">MANAGE_TAXONOMY</option>
														<option value="MANAGE_CODETABLES">MANAGE_CODETABLES</option>
														<option value="MANAGE_LOCALITY">MANAGE_LOCALITY</option>
														<option value="MANAGE_PUBLICATIONS">MANAGE_PUBLICATIONS</option>
														<option value="MANAGE_AGENT_RANKING">MANAGE_AGENT_RANKING</option>
														<option value="HIDE">HIDE (column is not queried or shown)</option>
													</select>
												</div>
											</div>
											<div class="row mx-0">
												<div class="col-12 col-md-6 px-1 mt-1">
													<label for="in_label" class="data-entry-label">Label</label>
													<input type="text" class="data-entry-input reqdClr" name="label" id="in_label" required >
												</div>
												<div class="col-12 col-md-6 px-1 mt-1">
													<label for="in_ui_function" class="data-entry-label">UI Function (e.g. makeScientificNameAutocompleteMeta)</label>
													<input type="text" class="data-entry-input" name="ui_function" id="in_ui_function">
												</div>
											</div>
											<div class="row mx-0">
												<div class="col-12 col-md-10 px-1 mt-1">
													<label for="in_description" class="data-entry-label">Description</label>
													<input type="text" class="data-entry-input reqdClr" name="description" id="in_description" required >
												</div>
												<div class="form-group col-12 col-md-2 px-1 pt-2">
													<button class="btn btn-xs btn-primary mr-1" type="button" onclick=" addSpecSearchColRow();" value="Add Row">Add Row</button>
													<span id="addItemFeedback" class="text-danger">&nbsp;</span>
												</div>
											</div>
										</form>
									</div>
								</div>
							</div>
							<script>
								function addSpecSearchColRow() {
									$('##addItemFeedback').html("Saving...");
									$('##addItemFeedback').addClass('text-warning');
									$('##addItemFeedback').removeClass('text-success');
									$('##addItemFeedback').removeClass('text-danger');
									jQuery.ajax( {
										url : "/specimens/component/admin.cfc",
										type : "post",
										dataType : "json",
										data : $("##addSpecSearchColForm").serialize(),
										success : function (data) {
											$('##addItemFeedback').html("Added row to cf_spec_search_cols.");
											$('##addItemFeedback').addClass('text-success');
											$('##addItemFeedback').removeClass('text-warning');
											$('##addItemFeedback').removeClass('text-danger');
											$("##catalog_number").val('');
											$("##no_of_spec").val('');
											$("##type_status").val('');
										},
										error: function(jqXHR,textStatus,error){
											$('##addItemFeedback').html("Error");
											$('##addItemFeedback').addClass('text-danger');
											$('##addItemFeedback').removeClass('text-success');
											$('##addItemFeedback').removeClass('text-warning');
											handleFail(jqXHR,textStatus,error,"adding row to cf_spec_search_cols.");
										}
									});
								};
							</script>
						</div>
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
					function deleteSpecSearchRow(id) {
						jQuery.ajax({
						url : "/specimens/component/admin.cfc",
							type : "post",
							dataType : "json",
							data : {
								method : "deleteCFSpecSearchColsRow",
								returnformat : "json",
								queryformat : 'column',
								ID : id
							},
							success : function (data) {
								$('##searchResultsGrid').jqxGrid('deleterow', id);
							},
							error: function(jqXHR,textStatus,error){
								handleFail(jqXHR,textStatus,error,"removing cf_spec_search_cols item");
							}
						});
					};
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

							// Cell renderers
							var deleteCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
								var rowData = jQuery("##searchResultsGrid").jqxGrid('getrowdata',row);
								var result = "";
								var itemid = rowData['ID'];
								if (itemid) {
									result = '<span class="#cellRenderClasses# float-left mt-1"' + columnproperties.cellsalign + '; "><a name="deleteRow" type="button" value="Delete" onclick="deleteSpecSearchRow(' + itemid+ ');" class="btn btn-xs btn-danger">Delete</a></span>';
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
									{ name: 'DESCRIPTION', type: 'string' }
								],
								updaterow: function (rowid, rowdata, commit) {
									var data = "method=updatecf_spec_search_cols";
									data = data + "&id=" + rowdata.ID;
									data = data + "&table_name=" + rowdata.TABLE_NAME;
									data = data + "&table_alias=" + rowdata.TABLE_ALIAS;
									data = data + "&column_name=" + rowdata.COLUMN_NAME;
									data = data + "&column_alias=" + rowdata.COLUMN_ALIAS;
									data = data + "&search_category=" + rowdata.SEARCH_CATEGORY;
									data = data + "&data_type=" + rowdata.DATA_TYPE;
									data = data + "&data_length=" + rowdata.DATA_LENGTH;
									data = data + "&label=" + rowdata.LABEL;
									data = data + "&access_role=" + rowdata.ACCESS_ROLE;
									data = data + "&ui_function=" + rowdata.UI_FUNCTION;
									data = data + "&example_values=" + rowdata.EXAMPLE_VALUES;
									data = data + "&description=" + rowdata.DESCRIPTION;
									$.ajax({
										dataType: 'json',
										url: '/specimens/component/admin.cfc',
										data: data,
											success: function (data, status, xhr) {
											commit(true);
										},
										error: function (jqXHR,textStatus,error) {
											commit(false);
											handleFail(jqXHR,textStatus,error,"saving cf_spec_search_cols row");
										}
									});
								},
								root: 'cf_spec_search_cols_Record',
								id: 'ID',
								url: '/specimens/component/admin.cfc?' + $('##searchForm').serialize(),
								timeout: 30000,  // units not specified, miliseconds? 
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
								source: dataAdapter,
								filterable: true,
								sortable: true,
								pageable: true,
								editable: true,
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
									{text: 'Table Name', datafield: 'TABLE_NAME', width: 150, hideable: true, hidden: getColHidProp('TABLE_NAME', false) },
									{text: 'Table Alias', datafield: 'TABLE_ALIAS', width: 150, hideable: true, hidden: getColHidProp('TABLE_ALIAS', false) },
									{text: 'Column Name', datafield: 'COLUMN_NAME', width: 150, hideable: true, hidden: getColHidProp('COLUMN_NAME', false) },
									{text: 'Column Alias', datafield: 'COLUMN_ALIAS', width: 150, hideable: true, hidden: getColHidProp('COLUMN_ALIAS', false) },
									{text: 'Category', datafield: 'SEARCH_CATEGORY', width: 120, hideable: true, hidden: getColHidProp('SEARCH_CATEGORY', false) },
									{text: 'Data Type', datafield: 'DATA_TYPE', width: 80, hideable: true, hidden: getColHidProp('DATA_TYPE', false),
										columntype: 'dropdownlist', 
										initeditor: function (row, cellvalue, editor) { 
											var typeList = ["VARCHAR2","NUMBER","DATE","CHAR","CLOB","CTXKEYWORD"];
											editor.jqxDropDownList( { source: typeList }); 
										}
									},
									{text: 'Data Length', datafield: 'DATA_LENGTH', width: 80, hideable: true, hidden: getColHidProp('DATA_LENGTH', false),
										columntype: 'numberinput', 
										initeditor: function (row, cellvalue, editor) { 
											editor.jqxNumberInput({ decimalDigits: 0 } ); 
										}
									},
									{text: 'Label', datafield: 'LABEL', width: 250, hideable: true, hidden: getColHidProp('LABEL', false) },
									{text: 'Access Role', datafield: 'ACCESS_ROLE', width: 100, hideable: true, hidden: getColHidProp('ACCESS_ROLE', false),
										columntype: 'dropdownlist', 
										initeditor: function (row, cellvalue, editor) { 
											var typeList = ["PUBLIC","COLDFUSION_USER","MANAGE_TRANSACTIONS","DATA_ENTRY","GLOBAL_ADMIN","MANAGE_AGENTS","MANAGE_MEDIA","MANAGE_COLLECTION","MANAGE_TAXONOMY","MANAGE_CODETABLES","MANAGE_LOCALITY","MANAGE_PUBLICATIONS","MANAGE_AGENT_RANKING","MANAGE_SPECIMENS","MANAGE_CONTAINER","HIDE"];
											editor.jqxDropDownList( { source: typeList }); 
										}
									},
									{text: 'UI Function', datafield: 'UI_FUNCTION', width: 100, hideable: true, hidden: getColHidProp('UI_FUNCTION', false) },
									{text: 'Example Values', datafield: 'EXAMPLE_VALUES', width: 100, hideable: true, hidden: getColHidProp('EXAMPLE_VALUES', false) },
									{text: 'Description', datafield: 'DESCRIPTION', width: 100, hideable: true, hidden: getColHidProp('DESCRIPTION', false) },
									{text: 'ID', editable: false, datafield: 'ID', hideable: true, hidden: getColHidProp('ID', false), cellsrenderer: deleteCellRenderer }
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
								$('##resultLink').html('<a href="/specimens/adminSpecimenSearch.cfm?action=search&execute=true&' + $('##searchForm').serialize() + '">Link to this search</a>');
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
						var items = "."
						if (rowcount > 0) {
							items = ". Click on a cell to edit. ";
						}
						if (rowcount == 1) {
							$('##resultCount').html('Found ' + rowcount + ' ' + searchType + items);
						} else { 
							$('##resultCount').html('Found ' + rowcount + ' ' + searchType + 's' + items);
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
