<!---
/reporting/PrimaryTypes.cfm

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
<!---
Report on primary types, by department.
--->
<cfset pageTitle = "Primary Type Report">
<cfinclude template = "/shared/_header.cfm">

<cfif not isDefined("collection")><cfset collection=""></cfif>
<cfset selectedCollection = collection>

<cfset defaultSelectionMode = "none">
<cfif defaultSelectionMode EQ "none">
	<cfset defaultenablebrowserselection = "true">
<cfelse>
	<cfset defaultenablebrowserselection = "false">
</cfif>	

<cfoutput>
	<div id="overlaycontainer" style="position: relative;"> 
		<main id="content" class="container py-3">
			<section class="row">
				<div class="col-12">
					<form name="searchForm" id="searchForm">
						<input type="hidden" name="method" value="getTypes" class="keeponclear excludeFromLink">
						<input type="hidden" name="kind" value="Primary" class="keeponclear excludeFromLink">
						<h1 class="h2">Primary Types By Department</h1>
						<cfquery name="getcounts" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getcounts_result">
							select count(collection_object_id) ct, collection_cde, collection
							from <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat
							where flat.toptypestatuskind = 'Primary'
							group by collection_cde, collection
						</cfquery>
						<div class="form-row mb-2">
							<div class="col-12">
								<ul class="list-inline">
									<cfset accumulate_shared = 0>
									<cfif getcounts.recordcount EQ 0>
										<li class="py-1 list-inline-item">None.  No Types</li>
									<cfelse>
										<cfloop query="getcounts">
											<li class="px-1 list-inline-item">#getcounts.collection#:&nbsp;#getcounts.ct# </li>
										</cfloop>
									</cfif>
								</ul>
							</div>
						</div>
						<div class="form-row mb-2">
							<div class="col-12 col-md-3">
								<label for="collection" id="collection_label" class="data-entry-label">Collection</label>
								<select name="collection" id="collection" class="data-entry-select" size="1">
									<cfloop query="getcounts">
										<cfif getcounts.ct GT 0>
											<cfif selectedCollection EQ getCounts.collection_cde><cfset selected="selected='true'"><cfelse><cfset selected=""></cfif>
											<option value="#getcounts.collection_cde#" #selected#>#getcounts.collection# (#getcounts.ct#)</option>
										</cfif>
									</cfloop>
								</select>
							</div>
							<div class="col-12 col-md-3">
								<cfif not isDefined("phylorder")><cfset phylorder=""></cfif>
								<label for="phylorder" class="data-entry-label align-left-center">Order 
									<span class="small">
										(<button type="button" aria-hidden="true" tabindex="-1" class="btn-link border-0 small90 p-0 bg-light" onclick="var e=document.getElementById('phylorder');e.value='='+e.value;">=</button>,
										<button type="button" tabindex="-1" aria-hidden="true" class="btn-link border-0 p-0 bg-light" onclick="var e=document.getElementById('phylorder');e.value='$'+e.value;">$<span class="sr-only">prefix with dollarsign for sounds like search</span></button>,
										NULL, NOT NULL)
									</span>
								</label>
								<input type="text" class="data-entry-input" id="phylorder" name="phylorder" value="#phylorder#" placeholder="order">
							</div>
							<div class="col-12 col-md-3">
								<cfif not isDefined("family")><cfset family=""></cfif>
								<label for="family" class="data-entry-label align-left-center">Family 
									<span class="small">
										(<button type="button" aria-hidden="true" tabindex="-1" class="btn-link border-0 small90 p-0 bg-light" onclick="var e=document.getElementById('family');e.value='='+e.value;">=</button>,
										<button type="button" tabindex="-1" aria-hidden="true" class="btn-link border-0 p-0 bg-light" onclick="var e=document.getElementById('family');e.value='$'+e.value;">$<span class="sr-only">prefix with dollarsign for sounds like search</span></button>,
										NULL, NOT NULL)
									</span>
								</label>
								<input type="text" class="data-entry-input" id="family" name="family" value="#family#" placeholder="family">
							</div>
							<div class="col-12 col-md-3">
								<cfif not isDefined("author_text")><cfset author_text=""></cfif>
								<label for="author_text" class="data-entry-label align-left-center">Authorship 
									<span class="small">
										(<button type="button" aria-hidden="true" tabindex="-1" class="btn-link border-0 small90 p-0 bg-light" onclick="var e=document.getElementById('author_text');e.value='='+e.value;">=</button>,
										<button type="button" tabindex="-1" aria-hidden="true" class="btn-link border-0 p-0 bg-light" onclick="var e=document.getElementById('author_text');e.value='$'+e.value;">$<span class="sr-only">prefix with dollarsign for sounds like search</span></button>,
										NULL, NOT NULL)
									</span>
								</label>
								<input type="text" class="data-entry-input" id="author_text" name="author_text" value="#author_text#" placeholder="author_text">
							</div>
						</div>
						<div class="form-row mb-2">
							<div class="col-12">
								<button class="btn-xs btn-primary px-2 my-2 mr-1" id="searchButton" type="submit" aria-label="Search for type specimens by collection">Search<span class="fa fa-search pl-1"></span></button>
							</div>
						</div>
						<script>
							jQuery(document).ready(function() {
								makeTaxonSearchAutocomplete('phylorder','order');
								makeTaxonSearchAutocomplete('family','family');
								makeTaxonSearchAutocomplete('author_text','author_text');
							});
						</script>
					</form>
				</div>
			</section>
			<!--- Results table as a jqxGrid. --->
			<section class="container-fluid px-0">
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
		<div id="overlay" style="position: absolute; top:0px; left:0px; width: 100%; height: 100%; background: rgba(0,0,0,0.5); opacity: 0.99; display: none; z-index: 2;">
			<div class="jqx-rc-all jqx-fill-state-normal" style="position: absolute; left: 50%; top: 25%; width: 10em; height: 2.4em;line-height: 2.4em; padding: 5px; color: ##333333; border-color: ##898989; border-style: solid; margin-left: -5em; opacity: 1;">
				<div class="jqx-grid-load" style="float: left; overflow: hidden; height: 32px; width: 32px;"></div>
				<div style="float: left; display: block; margin-left: 1em;" >Searching...</div>
			</div>
		</div>
		<cfset cellRenderClasses = "ml-1">
		<script>
			// cell renderer to link out to specimen details page by guid, when value is guid.
			var linkGuidCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
				return '<span class="#cellRenderClasses#" style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; "><a target="_blank" href="/guid/' + value + '" aria-label="specimen details">'+value+'</a></span>';
			};
			var linkNameCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
				return '<span class="#cellRenderClasses#" style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; "><a target="_blank" href="/name/' + encodeURIComponent(value) + '" aria-label="specimen details">'+value+'</a></span>';
			};
			var linkPubCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
				var result = "";
				if (value && value.toString().startsWith('http')) {
						result = '<span class="#cellRenderClasses#" style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; "><a target="_blank" href="' + value + '">'+value+'</a></span>';
					} else { 
						result = '<span class="#cellRenderClasses#" style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; ">'+value+'</span>';
					}
				return result; 
			};
			var linkPageCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
				var rowData = jQuery("##searchResultsGrid").jqxGrid('getrowdata',row);
				var citation_page_uri = rowData['citation_page_uri'];
				if (citation_page_uri && citation_page_uri.toString().startsWith('http') && value && value.toString().length > 0) {
						result = '<span class="#cellRenderClasses#" style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; "><a target="_blank" href="' + citation_page_uri + '">'+value+'</a></span>';
					} else { 
						result = '<span class="#cellRenderClasses#" style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; ">'+value+'</span>';
					}
				return result; 
			}

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
							{ name: 'guid', type: 'string' },
							{ name: 'cat_num', type: 'string' },
							{ name: 'toptypestatuskind', type: 'string' },
							{ name: 'toptypestatus', type: 'string' },
							{ name: 'phylorder', type: 'string' },
							{ name: 'family', type: 'string' },
							{ name: 'typegenus', type: 'string' },
							{ name: 'typespecies', type: 'string' },
							{ name: 'typesubspecies', type: 'string' },
							{ name: 'typeepithet', type: 'string' },
							{ name: 'typestatusplain', type: 'string' },
							{ name: 'pubauthorship', type: 'string' },
							{ name: 'citation', type: 'string' },
							{ name: 'page_number', type: 'string' },
							{ name: 'citation_page_uri', type: 'string' },
							{ name: 'publication_id', type: 'string' },
							{ name: 'typename', type: 'string' },
							{ name: 'typeauthorship', type: 'string' },
							{ name: 'currentname', type: 'string' },
							{ name: 'currentauthorship', type: 'string' },
							{ name: 'associatedgrant', type: 'string' },
							{ name: 'namedgroups', type: 'string' },
							{ name: 'country', type: 'string' },
							{ name: 'spec_locality', type: 'string' }
						],
						updaterow: function (rowid, rowdata, commit) {
							commit(true);
						},
						root: 'specimenRecord',
						id: 'collection_object_id',
						url: '/specimens/component/search.cfc?' + $('##searchForm').serialize(),
						timeout: #Application.ajax_timeout#000,  // units not specified, miliseconds? 
						loadError: function(jqXHR, textStatus, error) { 
							$("##overlay").hide();
							handleFail(jqXHR,textStatus,error, "Error searching for types: "); 
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
						selectionmode: '#defaultSelectionMode#',
						enablebrowserselection: #defaultenablebrowserselection#,
						altrows: true,
						showtoolbar: false,
						columns: [
							{text: 'GUID', datafield: 'guid', width: 150, hidable: true, hidden: getColHidProp('guid', false), cellsrenderer: linkGuidCellRenderer },
							{text: 'Catalog Number', datafield: 'cat_num', width: 100, hidable: true, hidden: getColHidProp('cat_num', true) },
							{text: 'Category', datafield: 'toptypestatuskind', width: 130, hidable: true, hidden: getColHidProp('toptypestatuskind', true) },
							{text: 'Type Status', datafield: 'toptypestatus', width: 130, hidable: true, hidden: getColHidProp('toptypestatus', false) },
							{text: 'Order', datafield: 'phylorder', width: 120, hidable: true, hidden: getColHidProp('family', true) },
							{text: 'Family', datafield: 'family', width: 100, hidable: true, hidden: getColHidProp('family', true) },
							{text: 'Type Name Genus', datafield: 'typegenus', width: 130, hidable: true, hidden: getColHidProp('typegenus', false) },
							{text: 'Type Name Species', datafield: 'typespecies', width: 130, hidable: true, hidden: getColHidProp('typespecies', false) },
							{text: 'Type Name Subspecies', datafield: 'typesubspecies', width: 130, hidable: true, hidden: getColHidProp('typesubspecies', false) },
							{text: 'Type Name', datafield: 'typename', width: 130, hidable: true, hidden: getColHidProp('typename', true), cellsrenderer: linkNameCellRenderer },
							{text: 'Type Authorship', datafield: 'typeauthorship', width: 130, hidable: true, hidden: getColHidProp('typeauthorship', false) },
							{text: 'Type Publication Authorship', datafield: 'pubauthorship', width: 130, hidable: true, hidden: getColHidProp('pubauthorship', true) },
							{text: 'Type Epithet', datafield: 'typeepithet', width: 130, hidable: true, hidden: getColHidProp('typeepithet', true) },
							{text: 'Types Of', datafield: 'typestatusplain', width: 130, hidable: true, hidden: getColHidProp('typestatusplain', true) },
							{text: 'Current Name', datafield: 'currentname', width: 130, hidable: true, hidden: getColHidProp('currentname', false), cellsrenderer: linkNameCellRenderer },
							{text: 'Current Author', datafield: 'currentauthorship', width: 130, hidable: true, hidden: getColHidProp('currentauthorship', false) },
							{text: 'Country', datafield: 'country', width: 100, hidable: true, hidden: getColHidProp('country', true) },
							{text: 'Specific Locality', datafield: 'spec_locality', width: 130, hidable: true, hidden: getColHidProp('spec_locality', true) },
							{text: 'Associated Grant', datafield: 'associatedgrant', width: 130, hidable: true, hidden: getColHidProp('associatedgrant', true) },
							{text: 'Named Groups', datafield: 'named_groups', width: 130, hideable: true, hidden: getColHidProp('namedgroups', false) },
							{text: 'Page Number', datafield: 'page_number', width: 50, hidable: true, hidden: getColHidProp('page_number', false), cellsrenderer: linkPageCellRenderer },
							{text: 'Citation Page URI', datafield: 'citation_page_uri', width: 80, hidable: true, hidden: getColHidProp('citation_page_uri', true), cellsrenderer: linkPubCellRenderer },
							{text: 'PublicationID', datafield: 'publication_id', width: 40, hidable: true, hidden: getColHidProp('publication_id', true) },
							{text: 'Citation', datafield: 'citation', hidable: true, hidden: getColHidProp('citation', false) }
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
						$('##resultLink').html('<a href="/reporting/PrimaryTypes.cfm?action=search&execute=true&' + $('##searchForm :input').filter(function(index,element){ return $(element).val()!='';}).not(".excludeFromLink").serialize() + '">Link to this search</a>');
						gridLoaded('searchResultsGrid','cataloged item');
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
	</div><!--- overlay container --->
</cfoutput>
<cfinclude template = "/shared/_footer.cfm">
