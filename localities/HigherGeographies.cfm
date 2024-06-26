<!---
localities/HigherGeographies.cfm

Find higher geography authority records.

Copyright 2023 President and Fellows of Harvard College

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
		<cfset pageTitle = "Search Higher Geographies">
	</cfcase>
	<cfdefaultcase>
		<cfset pageTitle = "Error: Unknown action.">
	</cfdefaultcase>
</cfswitch>
<!---------------------------------------------------------------------------------->
<cfset includeJQXEditor='false'>
<cfinclude template = "/shared/_header.cfm">
<!---------------------------------------------------------------------------------->
<cfset defaultSelectionMode = "none">
<cfif defaultSelectionMode EQ "none">
	<cfset defaultenablebrowserselection = "true">
<cfelse>
	<cfset defaultenablebrowserselection = "false">
</cfif>	
<!---------------------------------------------------------------------------------->
<cfswitch expression="#action#">
	<cfcase value="search">

		<div id="overlaycontainer" style="position: relative;"> 
			<!--- Search Form ---> 
			<cfoutput>
				<main id="content">
					<div class="" id="searchFormDiv">
						<form name="searchForm" id="searchForm">
							<cfset showLocality=0>
							<cfset showEvent=0>
							<cfset showExtraFields=1>
							<cfset newSearchTarget = "/localities/HigherGeographies.cfm">
							<cfif pageTitle eq "Search Higher Geographies"><h1 class="h2 mt-3 px-4">Find Higher Geography</h1></cfif>
							<input type="hidden" id="method" name="method" value="getHigherGeographies">
							<div class="row mx-0">
								<section class="container-fluid" role="search">
									<cfinclude template = "/localities/searchLocationForm.cfm">
								</section>
							</div>
						</form>
					</div>
		
					<!--- Results table as a jqxGrid. --->
					<section class="container-fluid">
						<div class="row mx-0">
							<div class="col-12">
								<div class="mb-5">
									<div class="row mt-1 mb-0 pb-0 jqx-widget-header border px-2">
										<h1 class="h4">Results: </h1>
										<span class="d-block px-3 p-2" id="resultCount"></span> <span id="resultLink" class="d-block p-2"></span>
										<div id="showhide"></div>
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

					// prevent on columnreordered event from causing save of grid column order when loading order from persistance store
					var columnOrderLoading = 0
			
					<cfif isdefined("session.username") and len(#session.username#) gt 0>
						function columnOrderChanged(gridId) { 
							if (columnOrderLoading==0) { 
								var columnCount = $('##'+gridId).jqxGrid("columns").length();
								var columnMap = new Map();
								for (var i=0; i<columnCount; i++) { 
									var fieldName = $('##'+gridId).jqxGrid("columns").records[i].datafield;
									if (fieldName) { 
										var column_number = $('##'+gridId).jqxGrid("getColumnIndex",fieldName); 
										columnMap.set(fieldName,column_number);
									}
								}
								JSON.stringify(Array.from(columnMap));
								saveColumnOrder('#cgi.script_name#',columnMap,'Default',null);
							} else { 
								console.log("columnOrderChanged called while loading column order, ignoring");
							}
						}
					</cfif>
			
					function loadColumnOrder(gridId) { 
						<cfif isdefined("session.username") and len(#session.username#) gt 0>
							jQuery.ajax({
								dataType: "json",
								url: "/shared/component/functions.cfc",
								data: { 
									method : "getGridColumnOrder",
									page_file_path: '#cgi.script_name#',
									label: 'Default',
									returnformat : "json",
									queryformat : 'column'
								},
								ajaxGridId : gridId,
								error: function (jqXHR, status, message) {
									messageDialog("Error looking up column order: " + status + " " + jqXHR.responseText ,'Error: '+ status);
								},
								success: function (result) {
									var gridId = this.ajaxGridId;
									var settings = result[0];
									if (typeof settings !== "undefined" && settings!=null) { 
										setColumnOrder(gridId,JSON.parse(settings.column_order));
									}
								}
							});
						<cfelse>
							return null;
						</cfif>
					} 
			
					<cfif isdefined("session.username") and len(#session.username#) gt 0>
						function setColumnOrder(gridId, columnMap) { 
							columnOrderLoading = 1;
							$('##' + gridId).jqxGrid('beginupdate');
							for (var i=0; i<columnMap.length; i++) {
								var kvp = columnMap[i];
								var key = kvp[0];
								var value = kvp[1];
								if ($('##'+gridId).jqxGrid("getColumnIndex",key) != value) { 
									if (key && value) {
										try {
											console.log(key + " set to column " + value);
											$('##'+gridId).jqxGrid("setColumnIndex",key,value);
										} catch (e) {};
									}
								}
							}
							$('##' + gridId).jqxGrid('endupdate');
							columnOrderLoading = 0;
						}
					</cfif>

					var linkIdCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
						<!--- Link to Higher Geography Details Page --->
						var rowData = jQuery("##searchResultsGrid").jqxGrid('getrowdata',row);
						return '<span class="#cellRenderClasses#" style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; "><a href="/localities/viewHigherGeography.cfm?geog_auth_rec_id=' + rowData['GEOG_AUTH_REC_ID'] + '" target="_blank">'+value+'</a></span>';
					};
					var specimensCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
						var rowData = jQuery("##searchResultsGrid").jqxGrid('getrowdata',row);
						if (value==0) {
							return '<span class="#cellRenderClasses#" style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; ">None</span>';
						} else {
							return '<span class="#cellRenderClasses#" style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; "><a href="/Specimens.cfm?action=fixedSearch&execute=true&higher_geog==' + rowData['HIGHER_GEOG'] + '" target="_blank">'+value+'</a></span>';
						}
					};
					<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_geography")>
						var editCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties, rowData) {
							<!--- Link edit Higher Geography --->
							var id = encodeURIComponent(rowData['GEOG_AUTH_REC_ID']);
							return '<a target="_blank" class="btn btn-xs btn-outline-primary ml-1" href="/localities/HigherGeography.cfm?geog_auth_rec_id=' + id + '">Edit</a>';
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
							$('##showhide').html('');
							$('##selectModeContainer').hide();
					
							var search =
							{
								datatype: "json",
								datafields:
								[
									{ name: 'GEOG_AUTH_REC_ID', type: 'string' },
									{ name: 'GEOG_AUTH_REC_ID_1', type: 'string', map: 'GEOG_AUTH_REC_ID' },
									{ name: 'CONTINENT_OCEAN', type: 'string' },
									{ name: 'COUNTRY', type: 'string' },
									{ name: 'STATE_PROV', type: 'string' },
									{ name: 'COUNTY', type: 'string' },
									{ name: 'QUAD', type: 'string' },
									{ name: 'FEATURE', type: 'string' },
									{ name: 'ISLAND', type: 'string' },
									{ name: 'ISLAND_GROUP', type: 'string' },
									{ name: 'SEA', type: 'string' },
									{ name: 'VALID_CATALOG_TERM_FG', type: 'string' },
									<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_geography")>
										{ name: 'CURATED_FG', type: 'string' },
									</cfif>
									{ name: 'SOURCE_AUTHORITY', type: 'string' },
									{ name: 'HIGHER_GEOG', type: 'string' },
									{ name: 'OCEAN_REGION', type: 'string' },
									{ name: 'OCEAN_SUBREGION', type: 'string' },
									{ name: 'WATER_FEATURE', type: 'string' },
									{ name: 'WKT_POLYGON', type: 'string' },
									{ name: 'HIGHERGEOGRAPHYID_GUID_TYPE', type: 'string' },
									{ name: 'HIGHERGEOGRAPHYID', type: 'string' },
									{ name: 'SPECIMEN_COUNT', type: 'string' }
								],
								updaterow: function (rowid, rowdata, commit) {
									commit(true);
								},
								root: 'geog_auth_record',
								id: 'geog_auth_rec_id',
								url: '/localities/component/search.cfc?' + $('##searchForm').serialize(),
								timeout: #Application.ajax_timeout#000,  // units not specified, miliseconds? 
								loadError: function(jqXHR, textStatus, error) {
									handleFail(jqXHR,textStatus,error, "Error performing higher geography search: "); 
								},
								async: true
							};
					
							var dataAdapter = new $.jqx.dataAdapter(search);
							var initRowDetails = function (index, parentElement, gridElement, datarecord) {
								// could create a dialog here, but need to locate it later to hide/show it on row details opening/closing and not destroy it.
								var details = $($(parentElement).children()[0]);
								details.html("<div id='rowDetailsTarget" + index + "'></div>");
					
								var omitArray = ["GEOG_AUTH_REC_ID_1"];
								createRowDetailsDialog('searchResultsGrid','rowDetailsTarget',datarecord,index,omitArray);
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
									{ text: 'ID', datafield: 'GEOG_AUTH_REC_ID',width: 100, hideabel: false, cellsrenderer: linkIdCellRenderer  },
									<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_geography")>
										{text: 'Edit', datafield: 'GEOG_AUTH_REC_ID_1', width:60, hideable: false, cellsrenderer: editCellRenderer},
									</cfif>
									{ text: 'Cat.Items', datafield: 'SPECIMEN_COUNT',width: 100, hideabel: true, hidden: getColHidProp('SPECIMEN_COUNT',false), cellsrenderer: specimensCellRenderer  },
									<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_geography")>
										{ text: 'Vetted', datafield: 'CURATED_FG',width: 100, hideabel: true, hidden: getColHidProp('CURATED_FG',false)  },
									</cfif>
									{ text: 'Continent/Ocean', datafield: 'CONTINENT_OCEAN',width: 100, hideabel: true, hidden: getColHidProp('CONTINENT_OCEAN',true)  },
									{ text: 'Ocean Region', datafield: 'OCEAN_REGION',width: 100, hideabel: true, hidden: getColHidProp('OCEAN_REGION',true)  },
									{ text: 'Ocean Subregion', datafield: 'OCEAN_SUBREGION',width: 100, hideabel: true, hidden: getColHidProp('OCEAN_SUBREGION',true)  },
									{ text: 'Sea', datafield: 'SEA',width: 100, hideabel: true, hidden: getColHidProp('SEA',true)  },
									{ text: 'Water Feature', datafield: 'WATER_FEATURE',width: 100, hideabel: true, hidden: getColHidProp('WATER_FEATURE',true)  },
									{ text: 'Island Group', datafield: 'ISLAND_GROUP',width: 100, hideabel: true, hidden: getColHidProp('ISLAND_GROUP',true)  },
									{ text: 'Island', datafield: 'ISLAND',width: 100, hideabel: true, hidden: getColHidProp('ISLAND',true)  },
									{ text: 'Country', datafield: 'COUNTRY',width: 100, hideabel: true, hidden: getColHidProp('COUNTRY',true)  },
									{ text: 'State/Province', datafield: 'STATE_PROV',width: 100, hideabel: true, hidden: getColHidProp('STATE_PROF',true)  },
									{ text: 'County', datafield: 'COUNTY',width: 100, hideabel: true, hidden: getColHidProp('COUNTY',true)  },
									{ text: 'Feature', datafield: 'FEATURE',width: 100, hideabel: true, hidden: getColHidProp('FEATURE',true)  },
									{ text: 'Quad', datafield: 'QUAD',width: 100, hideabel: true, hidden: getColHidProp('QUAD',true)  },
									{ text: 'Valid', datafield: 'VALID_CATALOG_TERM_FG',width: 100, hideabel: true, hidden: getColHidProp('VALID_CATALOG_TERM_FG',true)  },
									{ text: 'Source Authority', datafield: 'SOURCE_AUTHORITY',width: 100, hideabel: true, hidden: getColHidProp('SOURCE_AUTHORITY',true)  },
									{ text: 'WKT', datafield: 'WKT_POLYGON',width: 100, hideabel: true, hidden: getColHidProp('WKT_POLYGON',true)  },
									{ text: 'GUID Type', datafield: 'HIGHERGEOGRAPHYID_GUID_TYPE',width: 100, hideabel: true, hidden: getColHidProp('HIGHERGEOGRPAHYID_GUID_TYPE',true)  },
									{ text: 'GUID', datafield: 'HIGHERGEOGRAPHYID',width: 100, hideabel: true, hidden: getColHidProp('HIGHERGEOGRAPHYID',true)  }, 
									{ text: 'Higher Geography', datafield: 'HIGHER_GEOG', hideabel: true, hidden: getColHidProp('HIGHER_GEOG',false) }
								],
								rowdetails: true,
								rowdetailstemplate: {
									rowdetails: "<div style='margin: 10px;'>Row Details</div>",
									rowdetailsheight: 1 // row details will be placed in popup dialog
								},
								initrowdetails: initRowDetails
							});
							<cfif isdefined("session.username") and len(#session.username#) gt 0>
								$('##searchResultsGrid').jqxGrid().on("columnreordered", function (event) { 
									columnOrderChanged('searchResultsGrid'); 
								}); 
							</cfif>
							$("##searchResultsGrid").on("bindingcomplete", function(event) {
								// add a link out to this search, serializing the form as http get parameters
								$('##resultLink').html('<a href="/localities/HigherGeographies.cfm?action=search&execute=true&' + $('##searchForm :input').filter(function(index,element){return $(element).val()!='';}).serialize() + '">Link to this search</a> <a href="/localities/Localities.cfm?action=search&execute=true&' + $('##searchForm :input').filter(function(index,element){return $(element).val()!='';}).serialize() + '">Find Localities</a>');
								$('##showhide').html('<button class="my-2 border rounded" title="hide search form" onclick=" toggleAnySearchForm(\'searchFormDiv\',\'searchFormToggleIcon\'); "><i id="searchFormToggleIcon" class="fas fa-eye-slash"></i></button>');
								gridLoaded('searchResultsGrid','higher geography record');
								loadColumnOrder('searchResultsGrid');
							});
							$('##searchResultsGrid').on('rowexpand', function (event) {
								//  Create a content div, add it to the detail row, and make it into a dialog.
								var args = event.args;
								var rowIndex = args.rowindex;
								var datarecord = args.owner.source.records[rowIndex];
								var omitArray = ["GEOG_AUTH_REC_ID_1"];
								createRowDetailsDialog('searchResultsGrid','rowDetailsTarget',datarecord,rowIndex,omitArray);
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
						<cfif isDefined("execute")>
							// race condtions between grid creation and lookup of column visibities may have caused grid to be created with default columns.
							setColumnVisibilities(window.columnHiddenSettings,'searchResultsGrid');
						</cfif>
						if (Object.keys(window.columnHiddenSettings).length == 0) { 
							window.columnHiddenSettings = getColumnVisibilities('searchResultsGrid');
							<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
								saveColumnVisibilities('#cgi.script_name#',window.columnHiddenSettings,'Default');
							</cfif>
						}
						$("##overlay").hide();
						var now = new Date();
						var nowstring = now.toISOString().replace(/[^0-9TZ]/g,'_');
						var filename = searchType.replace(/ /g,'_') + '_results_' + nowstring + '.csv';
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
								<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
									Defaults: function(){ 
										saveColumnVisibilities('#cgi.script_name#',null,'Default');
										saveColumnOrder('#cgi.script_name#',null,'Default',null);
										lookupColumnVisibilities ('#cgi.script_name#','Default');
										window.columnHiddenSettings = getColumnVisibilities('searchResultsGrid');
										messageDialog("Default values for show/hide columns and column order will be used on your next search." ,'Reset to Defaults');
										$(this).dialog("close");
									},
								</cfif>
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
