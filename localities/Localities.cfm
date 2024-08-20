<!---
localities/Localities.cfm

Find locality records.

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
		<cfset pageTitle = "Search Localities">
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
					<div id="searchFormDiv">
						<form name="searchForm" id="searchForm">
							<cfset showLocality=1>
							<cfset showEvent=0>
							<cfset showExtraFields=1>
							<cfset newSearchTarget = "/localities/Localities.cfm">
							<cfif pageTitle eq "Search Localities"><h1 class="h2 mt-3 px-4">Find Locality</h1></cfif>
							<input type="hidden" id="method" name="method" value="getLocalities">
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
										<span class="d-block px-3 p-2" id="resultCount"></span> 
										<span id="resultLink" class="d-block p-2"></span>
										<div id="showhide"></div>
										<div id="columnPickDialog" class="row pick-column-width">
											<div class="col-12 col-md-3">
												<div id="columnPick" class="px-1"></div>
											</div>
											<div class="col-12 col-md-3">
												<div id="columnPick1" class="px-1"></div>
											</div>
											<div class="col-12 col-md-3">
												<div id="columnPick2" class="px-1"></div>
											</div>
											<div class="col-12 col-md-3">
												<div id="columnPick3" class="px-1"></div>
											</div>
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
					/** makeSummary combine row data into a single text string **/
					function makeSummary(rowData) { 
						var spec_locality = rowData['SPEC_LOCALITY'];
						if(spec_locality) { spec_locality = spec_locality + ". ";}
						var id = rowData['LOCALITY_ID'];
						var locality_remarks = rowData['LOCALITY_REMARKS'];
						if (locality_remarks) { remarks = ". Remarks: " + locality_remarks + " "; } else { remarks = ""; }
						var curated_fg = rowData['CURATED_FG'];
						if (curated_fg=="1") { curated = "*"; } else { curated = ""; }
						var sovereignNation = rowData['SOVEREIGN_NATION'];
						var minimum_elevation = rowData['MINIMUM_ELEVATION'];
						var maximum_elevation = rowData['MAXIMUM_ELEVATION'];
						var origElevUnits = rowData['ORIG_ELEV_UNITS'];
						if (minimum_elevation) { 
							elevation = " Elev: " + minimum_elevation;
							if (maximum_elevation && maximum_elevation != minimum_elevation) {
								elevation = elevation + "-" + maximum_elevation;
							}
							elevation = $.trim(elevation + " " + origElevUnits) + ". ";
						} else {
							elevation = "";
						}
						var minDepth = rowData['MIN_DEPTH'];
						var maxDepth = rowData['MAX_DEPTH'];
						var depthval = "";
						var depthUnits = rowData['DEPTH_UNITS'];
						if (minDepth) { 
							depthval = " Depth: " + minDepth;
							if (maxDepth && maxDepth != minDepth) {
								depthval = depthval + "-" + max_depth;
							}
							depthval = $.trim(depthval + " " + depthUnits) + ". ";
						}
						var plss = rowData['PLSS'];
						var geolatts = rowData['GEOLATTS'];
						if (geolatts) { geology = " [" + geolatts + "] "; } else { geology = ""; } 
						var dec_lat = rowData['DEC_LAT'];
						var dec_long = rowData['DEC_LONG'];
						var datum = rowData['DATUM'];
						var max_error_distance = rowData['MAX_ERROR_DISTANCE'];
						var max_error_units = rowData['MAX_ERROR_UNITS'];
						var extent = rowData['EXTENT'];
						var verificationstatus = rowData['VERIFICATIONSTATUS'];
						var georefmethod = rowData['GEOREFMETHOD'];
						var nogeorefbecause = rowData['NOGEOREFBECAUSE'];
						if (dec_lat) { 
							coordinates = " " + dec_lat + ", " + dec_long + " " + datum + " ±" + max_error_distance + " " + max_error_units+ " " + verificationstatus + " ";
						} else { 
							coordinates = " " + nogeorefbecause + " ";
						}
						if (sovereignNation) {
							if (sovereignNation=="[unknown]") { 
								sovereignNation = " Sovereign Nation: " + sovereignNation + " ";
							} else {
								sovereignNation = " " + sovereignNation + " ";
							}
						}
						if (plss) { plss = " " + plss + " "; } 
						var data = $.trim(spec_locality + geology +  elevation + depthval + sovereignNation + plss + coordinates) + remarks + " (" + id + ")" + curated;
					   return data;
					};
					/** createLocalityRowDetailsDialog, create a custom loan specific popup dialog to show details for
						a row of locality data from the locality results grid.
					
						@see createRowDetailsDialog defined in /shared/js/shared-scripts.js for details of use.
					 */
					function createLocalityRowDetailsDialog(gridId, rowDetailsTargetId, datarecord, rowIndex) {
						var columns = $('##' + gridId).jqxGrid('columns').records;
						var content = "<div id='" + gridId+ "RowDetailsDialog" + rowIndex + "'><ul class='card-columns pl-md-3'>";
						if (columns.length < 21) {
							// don't split into columns for shorter sets of columns.
							content = "<div id='" + gridId+ "RowDetailsDialog" + rowIndex + "'><ul>";
						}
						var gridWidth = $('##' + gridId).width();
						var dialogWidth = Math.round(gridWidth/2);
						var locality_id = datarecord['LOCALITY_ID'];
						var geog_auth_rec_id = datarecord['GEOG_AUTH_REC_ID'];
						if (dialogWidth < 299) { dialogWidth = 300; }
						for (i = 1; i < columns.length; i++) {
							var text = columns[i].text;
							var datafield = columns[i].datafield;
							if (datafield == 'LOCALITY_ID') { 
					 			content = content + "<li class='pr-3'><strong>" + text + ":</strong> <a href='/localities/viewLocality.cfm?locality_id="+locality_id+"' target='_blank'>" + datarecord[datafield] + "</a></li>";
					 			content = content + "<li class='pr-3'><strong>" + text + ":</strong> <a href='/localities/Locality.cfm?locality_id="+locality_id+"' target='_blank'>" + datarecord[datafield] + " [Edit]</a></li>";
					 			content = content + "<li class='pr-3'><strong>Collecting Events:</strong> <a href='/localities/CollectingEvents.cfm?execute=true&locality_id="+locality_id+"' target='_blank'>Find</a></li>";
							} else if (datafield == 'SPECIMEN_COUNT') { 
								if (datarecord[datafield] == "0") {
									content = content + "<li class='pr-3'><strong>" + text + ":</strong> " + datarecord[datafield] + "</li>";
								} else { 
									var loc = encodeURIComponent(datarecord['SPEC_LOCALITY']);
					 				content = content + "<li class='pr-3'><strong>" + text + ":</strong> <a href='/Specimens.cfm?execute=true&builderMaxRows=1&action=builderSearch&nestdepth1=1&field1=LOCALITY%3ALOCALITY_LOCALITY_ID_PICK&searchText1="+loc+"&searchId1="+locality_id+"' target='_blank'>" + datarecord[datafield] + "</a></li>";
								}
							} else if (datafield == 'HIGHER_GEOG') { 
					 			content = content + "<li class='pr-3'><strong>" + text + ":</strong> <a href='/localities/viewHigherGeography.cfm?geog_auth_rec_id="+geog_auth_rec_id+"' target='_blank'>" + datarecord[datafield] + "</a></li>";
							} else if (datafield == 'VALID_CATALOG_TERM_FG') { 
								var val = datarecord[datafield];
								var flag = "True";
								if (val=="1") { flat = "False"; }
								content = content + "<li class='pr-3'><strong>Valid For Data Entry:</strong> " + flag + "</li>";
							} else if (datafield == 'LOCALITY_ID_1') {
								// duplicate column, omit
								console.log(datarecord[datafield]);
							} else if (datafield == 'summary') {
								content = content + "<li class='pr-3'><strong>" + text + ":</strong> " + makeSummary(datarecord) + "</li>";
							} else if (datarecord[datafield] == '') {
								// leave out blank column
								console.log(datafield);
							} else {
								content = content + "<li class='pr-3'><strong>" + text + ":</strong> " + datarecord[datafield] + "</li>";
							}
						}
						content = content + "</ul>";
						content = content + "</div>";
						$("##" + rowDetailsTargetId + rowIndex).html(content);
						$("##"+ gridId +"RowDetailsDialog" + rowIndex ).dialog(
							{
								autoOpen: true,
								buttons: [ { text: "Ok", click: function() { $( this ).dialog( "close" ); $("##" + gridId).jqxGrid('hiderowdetails',rowIndex); } } ],
								width: dialogWidth,
								title: 'Locality Details'
							}
						);
						// Workaround, expansion sits below row in zindex.
						var maxZIndex = getMaxZIndex();
						$("##"+gridId+"RowDetailsDialog" + rowIndex ).parent().css('z-index', maxZIndex + 1);
					};

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
						var rowData = jQuery("##searchResultsGrid").jqxGrid('getrowdata',row);
						return '<span class="#cellRenderClasses#" style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; "><a href="/localities/Locality.cfm?locality_id=' + rowData['LOCALITY_ID'] + '" target="_blank">'+value+'</a></span>';
					};
					var summaryCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
						var rowData = jQuery("##searchResultsGrid").jqxGrid('getrowdata',row);
						var data = makeSummary(rowData);
						return '<span class="#cellRenderClasses#" style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; ">' + data + '</span>';
					}
					var collectingEventCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties,rowData) {
						if (value==0) {
							return '<span class="#cellRenderClasses#" style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; ">None</span>';
						} else {
							var id = encodeURIComponent(rowData['LOCALITY_ID']);
							return '<span class="#cellRenderClasses#" style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; "><a href="/localities/CollectingEvents.cfm?execute=true&locality_id='+ id +'" target="_blank">'+value+'</a></span>';
						}
					};
					var specimensCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
						var rowData = jQuery("##searchResultsGrid").jqxGrid('getrowdata',row);
						if (value==0) {
							return '<span class="#cellRenderClasses#" style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; ">None</span>';
						} else {
							var loc = encodeURIComponent(rowData['SPEC_LOCALITY']);
							var id = encodeURIComponent(rowData['LOCALITY_ID']);
							if (loc=="") { loc = id; } 
							return '<span class="#cellRenderClasses#" style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; "><a href="/Specimens.cfm?execute=true&builderMaxRows=1&action=builderSearch&nestdepth1=1&field1=LOCALITY%3ALOCALITY_LOCALITY_ID_PICK&searchText1=' + loc + '&searchId1='+ id +'" target="_blank">'+value+'</a></span>';
						}
					};
					<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_locality")>
						var editCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties, rowData) {
							var id = encodeURIComponent(rowData['LOCALITY_ID']);
							return '<a target="_blank" class="btn btn-xs btn-outline-primary mt-2 ml-1" href="/localities/Locality.cfm?locality_id=' + id + '">Edit</a>';
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
									{ name: 'SOURCE_AUTHORITY', type: 'string' },
									{ name: 'HIGHER_GEOG', type: 'string' },
									{ name: 'OCEAN_REGION', type: 'string' },
									{ name: 'OCEAN_SUBREGION', type: 'string' },
									{ name: 'WATER_FEATURE', type: 'string' },
									{ name: 'WKT_POLYGON', type: 'string' },
									{ name: 'HIGHERGEOGRAPHYID_GUID_TYPE', type: 'string' },
									{ name: 'HIGHERGEOGRAPHYID', type: 'string' },
									{ name: 'SPECIMEN_COUNT', type: 'string' },
									{ name: 'COLLECTING_EVENT_COUNT', type: 'string' },
									{ name: 'LOCALITY_ID', type: 'string' },
									{ name: 'LOCALITY_ID_1', type: 'string', map: 'LOCALITY_ID' },
									{ name: 'SPEC_LOCALITY', type: 'string' },
									{ name: 'CURATED_FG', type: 'string' },
									{ name: 'SOVEREIGN_NATION', type: 'string' },
									{ name: 'MINIMUM_ELEVATION', type: 'string' },
									{ name: 'MAXIMUM_ELEVATION', type: 'string' },
									{ name: 'ORIG_ELEV_UNITS', type: 'string' },
									{ name: 'MIN_ELEVATION_METERS', type: 'string' },
									{ name: 'MAX_ELEVATION_METERS', type: 'string' },
									{ name: 'MIN_DEPTH', type: 'string' },
									{ name: 'MAX_DEPTH', type: 'string' },
									{ name: 'DEPTH_UNITS', type: 'string' },
									{ name: 'MIN_DEPTH_METERS', type: 'string' },
									{ name: 'MAX_DEPTH_METERS', type: 'string' },
									{ name: 'PLSS', type: 'string' },
									{ name: 'GEOLATTS', type: 'string' },
									{ name: 'COLLCOUNTLOCALITY', type: 'string' },
									{ name: 'DEC_LAT', type: 'string' },
									{ name: 'DEC_LONG', type: 'string' },
									{ name: 'DATUM', type: 'string' },
									{ name: 'MAX_ERROR_DISTANCE', type: 'string' },
									{ name: 'MAX_ERROR_UNITS', type: 'string' },
									{ name: 'COORDINATEUNCERTAINTYINMETERS', type: 'string' },
									{ name: 'EXTENT', type: 'string' },
									{ name: 'VERIFICATIONSTATUS', type: 'string' },
									{ name: 'GEOREFMETHOD', type: 'string' },
									{ name: 'NOGEOREFBECAUSE', type: 'string' },
									{ name: 'GEOREF_VERIFIED_BY_AGENT', type: 'string' },
									{ name: 'GEOREF_DETERMINED_BY_AGENT', type: 'string' },
									{ name: 'LOCALITY_REMARKS', type: 'string' }
								],
								updaterow: function (rowid, rowdata, commit) {
									commit(true);
								},
								root: 'locality',
								id: 'locality_id',
								url: '/localities/component/search.cfc?' + $('##searchForm').serialize(),
								timeout: #Application.ajax_timeout#000,  // units not specified, miliseconds? 
								loadError: function(jqXHR, textStatus, error) {
									handleFail(jqXHR,textStatus,error, "Error performing locality search: "); 
								},
								async: true
							};
					
							var dataAdapter = new $.jqx.dataAdapter(search, {
								autoBind: true,
								beforeLoadComplete: function (records) {
									var data = new Array();
									for (var i = 0; i < records.length; i++) {
										var locality = records[i];
										var summary = makeSummary(locality);
										locality.summary = summary;
										data.push(locality);
										console.log(summary);
									}
									return data;
								}
							});
							var initRowDetails = function (index, parentElement, gridElement, datarecord) {
								// could create a dialog here, but need to locate it later to hide/show it on row details opening/closing and not destroy it.
								var details = $($(parentElement).children()[0]);
								details.html("<div id='rowDetailsTarget" + index + "'></div>");
					
								createLocalityRowDetailsDialog('searchResultsGrid','rowDetailsTarget',datarecord,index);
								// Workaround, expansion sits below row in zindex.
								var maxZIndex = getMaxZIndex();
								$(parentElement).css('z-index',maxZIndex - 1); // will sit just behind dialog
							}
					
							$("##searchResultsGrid").jqxGrid({
								width: '100%',
								autoheight: 'true',
								autorowheight: 'true', // for text to wrap in cells
								source: dataAdapter,
								filterable: true,
								sortable: true,
								pageable: true,
								editable: false,
								enablemousewheel: #session.gridenablemousewheel#,
								pagesize: '50',
								pagesizeoptions: ['5','10','25','50','100'],
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
									<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_locality")>
										{text: 'Edit', datafield: 'LOCALITY_ID_1', width:60, hideable: false, cellsrenderer: editCellRenderer},
									<cfelse>
										{text: 'View', datafield: 'LOCALITY_ID_1', width:60, hideable: false, cellsrenderer: linkIdCellRenderer},
									</cfif>
									{ text: 'Cat.Items', datafield: 'SPECIMEN_COUNT',width: 100, hideabel: true, hidden: getColHidProp('SPECIMEN_COUNT',false), cellsrenderer: specimensCellRenderer  },
									{ text: 'Coll Events', datafield: 'COLLECTING_EVENT_COUNT',width: 100, hideabel: true, hidden: getColHidProp('COLLECTING_EVENT_COUNT',false), cellsrenderer: collectingEventCellRenderer  },
									{ text: 'Locality_id', datafield: 'LOCALITY_ID',width: 100, hideabel: true, hidden: getColHidProp('LOCALITY_ID',true) },
									{ text: 'Locality Summary', datafield: 'summary',width: 500, hideabel: true, hidden: getColHidProp('summary',false) },
									{ text: 'Specific Locality', datafield: 'SPEC_LOCALITY',width: 200, hideabel: true, hidden: getColHidProp('SPEC_LOCALITY',true)  },
									{ text: 'Vetted', datafield: 'CURATED_FG',width: 50, hideabel: true, hidden: getColHidProp('CURATED_FG',false)  },
									{ text: 'Locality Remarks', datafield: 'LOCALITY_REMARKS',width: 100, hideabel: true, hidden: getColHidProp('LOCALITY_REMARKS',true)  },
									{ text: 'Min Depth', datafield: 'MIN_DEPTH',width: 100, hideabel: true, hidden: getColHidProp('MIN_DEPTH',true)  },
									{ text: 'Max Depth', datafield: 'MAX_DEPTH',width: 100, hideabel: true, hidden: getColHidProp('MAX_DEPTH',true)  },
									{ text: 'Depth Units', datafield: 'DEPTH_UNITS',width: 100, hideabel: true, hidden: getColHidProp('DEPTH_UNITS',true)  },
									{ text: 'Min Depth m', datafield: 'MIN_DEPTH_METERS',width: 100, hideabel: true, hidden: getColHidProp('MIN_DEPTH_METERS',true)  },
									{ text: 'Max Depth m', datafield: 'MAX_DEPTH_METERS',width: 100, hideabel: true, hidden: getColHidProp('MAX_DEPTH_METERS',true)  },
									{ text: 'Min Elevation', datafield: 'MINIMUM_ELEVATION',width: 100, hideabel: true, hidden: getColHidProp('MINIMUM_ELEVATION',true)  },
									{ text: 'Max Elevation', datafield: 'MAXIMUM_ELEVATION',width: 100, hideabel: true, hidden: getColHidProp('MAXIMUM_ELEVATION',true)  },
									{ text: 'Elev Units', datafield: 'ORIG_ELEV_UNITS',width: 100, hideabel: true, hidden: getColHidProp('ORIG_ELEV_UNITS',true)  },
									{ text: 'Min Elevation m', datafield: 'MIN_ELEVATION_METERS',width: 100, hideabel: true, hidden: getColHidProp('MIN_ELEVATION_METERS',true)  },
									{ text: 'Max Elevation m', datafield: 'MAX_ELEVATION_METERS',width: 100, hideabel: true, hidden: getColHidProp('MAX_ELEVATION_METERS',true)  },
									{ text: 'Lat.', datafield: 'DEC_LAT', width: 100, hideable: true, hidden: getColHidProp('DEC_LAT',true) },
									{ text: 'Long.', datafield: 'DEC_LONG', width: 100, hideable: true, hidden: getColHidProp('DEC_LONG',true) },
									{ text: 'Datum', datafield: 'DATUM', width: 100, hideable: true, hidden: getColHidProp('DATUM',true) },
									{ text: 'Error Radius', datafield: 'MAX_ERROR_DISTANCE', width: 100, hideable: true, hidden: getColHidProp('MAX_ERROR_DISTANCE',true) },
									{ text: 'Error Units', datafield: 'MAX_ERROR_UNITS', width: 100, hideable: true, hidden: getColHidProp('MAX_ERROR_UNITS',true) },
									{ text: 'coordinateUncertantyInMeters', datafield: 'COORDINATEUNCERTAINTYINMETERS', width: 100, hideable: true, hidden: getColHidProp('COORDINATEUNCERTAINTYINMETERS',true) },
									{ text: 'Extent', datafield: 'EXTENT', width: 100, hideable: true, hidden: getColHidProp('EXTENT',true) },
									{ text: 'Georef Verifier', datafield: 'GEOREF_VERIFIED_BY_AGENT', width: 100, hideable: true, hidden: getColHidProp('GEOREF_VERIFIED_BY_AGENT',true) },
									{ text: 'Georef Determiner', datafield: 'GEOREF_DETERMINED_BY_AGENT', width: 100, hideable: true, hidden: getColHidProp('GEOREF_DETERMINED_BY_AGENT',true) },
									{ text: 'Verification', datafield: 'VERIFICATIONSTATUS', width: 100, hideable: true, hidden: getColHidProp('VERIFICATIONSTATUS',true) },
									{ text: 'GeoRef Method', datafield: 'GEOREFMETHOD', width: 100, hideable: true, hidden: getColHidProp('GEOREFMETHOD',true) },
									{ text: 'NotGeoreferenced', datafield: 'NOGEOREFBECAUSE', width: 100, hideable: true, hidden: getColHidProp('GEOREFMETHOD',true) },
									{ text: 'Continent/Ocean', datafield: 'CONTINENT_OCEAN',width: 100, hideabel: true, hidden: getColHidProp('CONTINENT_OCEAN',true)  },
									{ text: 'Ocean Region', datafield: 'OCEAN_REGION',width: 100, hideabel: true, hidden: getColHidProp('OCEAN_REGION',true)  },
									{ text: 'Ocean Subregion', datafield: 'OCEAN_SUBREGION',width: 100, hideabel: true, hidden: getColHidProp('OCEAN_SUBREGION',true)  },
									{ text: 'Sea', datafield: 'SEA',width: 100, hideabel: true, hidden: getColHidProp('SEA',true)  },
									{ text: 'Water Feature', datafield: 'WATER_FEATURE',width: 100, hideabel: true, hidden: getColHidProp('WATER_FEATURE',true)  },
									{ text: 'Island Group', datafield: 'ISLAND_GROUP',width: 100, hideabel: true, hidden: getColHidProp('ISLAND_GROUP',true)  },
									{ text: 'Island', datafield: 'ISLAND',width: 100, hideabel: true, hidden: getColHidProp('ISLAND',true)  },
									{ text: 'Country', datafield: 'COUNTRY',width: 100, hideabel: true, hidden: getColHidProp('COUNTRY',true)  },
									{ text: 'Sovereign Nation', datafield: 'SOVEREIGN_NATION',width: 100, hideabel: true, hidden: getColHidProp('SOVEREIGN_NATION',true)  },
									{ text: 'State/Province', datafield: 'STATE_PROV',width: 100, hideabel: true, hidden: getColHidProp('STATE_PROF',true)  },
									{ text: 'County', datafield: 'COUNTY',width: 100, hideabel: true, hidden: getColHidProp('COUNTY',true)  },
									{ text: 'Feature', datafield: 'FEATURE',width: 100, hideabel: true, hidden: getColHidProp('FEATURE',true)  },
									{ text: 'Quad', datafield: 'QUAD',width: 100, hideabel: true, hidden: getColHidProp('QUAD',true)  },
									{ text: 'PLSS', datafield: 'PLSS',width: 100, hideabel: true, hidden: getColHidProp('PLSS',true)  },
									{ text: 'Geological Attributes', datafield: 'GEOLATTS',width: 250, hideabel: true, hidden: getColHidProp('GEOLATTS',true)  },
									{ text: 'Departments', datafield: 'COLLCOUNTLOCALITY',width: 100, hideabel: true, hidden: getColHidProp('COLLCOUNTLOCALITY',true)  },
									{ text: 'Valid', datafield: 'VALID_CATALOG_TERM_FG',width: 50, hideabel: true, hidden: getColHidProp('VALID_CATALOG_TERM_FG',true)  },
									{ text: 'Source Authority', datafield: 'SOURCE_AUTHORITY',width: 100, hideabel: true, hidden: getColHidProp('SOURCE_AUTHORITY',true)  },
									{ text: 'WKT', datafield: 'WKT_POLYGON',width: 80, hideabel: true, hidden: getColHidProp('WKT_POLYGON',true)  },
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
								$('##resultLink').html('<a href="/localities/Localities.cfm?action=search&execute=true&' + $('##searchForm :input').filter(function(index,element){return $(element).val()!='';}).serialize() + '">Link to this search</a> <a href="/localities/CollectingEvents.cfm?action=search&execute=true&' + $('##searchForm :input').filter(function(index,element){return $(element).val()!='';}).serialize() + '">Find Collecting Events</a>');
								$('##showhide').html('<button class="my-2 border rounded" title="hide search form" onclick=" toggleAnySearchForm(\'searchFormDiv\',\'searchFormToggleIcon\'); "><i id="searchFormToggleIcon" class="fas fa-eye-slash"></i></button>');
								gridLoaded('searchResultsGrid','locality record');
								loadColumnOrder('searchResultsGrid');
							});
							$('##searchResultsGrid').on('rowexpand', function (event) {
								//  Create a content div, add it to the detail row, and make it into a dialog.
								var args = event.args;
								var rowIndex = args.rowindex;
								var datarecord = args.owner.source.records[rowIndex];
								createLocalityRowDetailsDialog('searchResultsGrid','rowDetailsTarget',datarecord,rowIndex);
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
							$('##' + gridId).jqxGrid({ pagesizeoptions: ['5','10','25','50', '100', rowcount],pagesize: 50});
						} else if (rowcount > 50) { 
							$('##' + gridId).jqxGrid({ pagesizeoptions: ['5','10','25','50', rowcount],pagesize:50});
						} else if (rowcount > 25) { 
							$('##' + gridId).jqxGrid({ pagesizeoptions: ['5','10','25', rowcount],pagesize:25});
						} else if (rowcount > 10) { 
							$('##' + gridId).jqxGrid({ pagesizeoptions: ['5','10', rowcount],pagesize:rowcount});
						} else { 
							$('##' + gridId).jqxGrid({ pageable: false });
						}
						// add a control to show/hide columns
						var columns = $('##' + gridId).jqxGrid('columns').records;
						var quarterColumns = Math.round(columns.length/4);

						var columnListSource = [];
						for (i = 1; i < quarterColumns; i++) {
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
						for (i = quarterColumns; i < (quarterColumns*2); i++) {
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

						var columnListSource2 = [];
						for (i = (quarterColumns*2); i < (quarterColumns*3); i++) {
							var text = columns[i].text;
							var datafield = columns[i].datafield;
							var hideable = columns[i].hideable;
							var hidden = columns[i].hidden;
							var show = ! hidden;
							if (hideable == true) { 
								var listRow = { label: text, value: datafield, checked: show };
								columnListSource2.push(listRow);
							}
						} 
						$("##columnPick2").jqxListBox({ source: columnListSource2, autoHeight: true, width: '260px', checkboxes: true });
						$("##columnPick2").on('checkChange', function (event) {
							$("##" + gridId).jqxGrid('beginupdate');
							if (event.args.checked) {
								$("##" + gridId).jqxGrid('showcolumn', event.args.value);
							} else {
								$("##" + gridId).jqxGrid('hidecolumn', event.args.value);
							}
							$("##" + gridId).jqxGrid('endupdate');
						});

						var columnListSource3 = [];
						for (i = (quarterColumns*3); i < columns.length; i++) {
							var text = columns[i].text;
							var datafield = columns[i].datafield;
							var hideable = columns[i].hideable;
							var hidden = columns[i].hidden;
							var show = ! hidden;
							if (hideable == true) { 
								var listRow = { label: text, value: datafield, checked: show };
								columnListSource3.push(listRow);
							}
						} 
						$("##columnPick3").jqxListBox({ source: columnListSource3, autoHeight: true, width: '260px', checkboxes: true });
						$("##columnPick3").on('checkChange', function (event) {
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
