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
<cfswitch expression="#action#">
	<cfcase value="search">

		<div id="overlaycontainer" style="position: relative;"> 
			<!--- Search Form ---> 
			<cfoutput>
				<main id="content">
					<form name="searchForm" id="searchForm">
						<cfset showLocality=1>
						<cfset showEvent=0>
						<cfset showExtraFields=1>
						<cfset newSearchTarget = "/localities/Localities.cfm">
						<input type="hidden" id="method" name="method" value="getLocalities">
						<cfinclude template = "/localities/searchLocationForm.cfm">
					</form>
		
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
						<!--- TODO: Locality Details Page --->
						var rowData = jQuery("##searchResultsGrid").jqxGrid('getrowdata',row);
						return '<span class="#cellRenderClasses#" style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; "><a href="/editLocality.cfm?locality_id=' + rowData['LOCALITY_ID'] + '" target="_blank">'+value+'</a></span>';
					};
					var summaryCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
						var rowData = jQuery("##searchResultsGrid").jqxGrid('getrowdata',row);
						var spec_locality = rowData['SPEC_LOCALITY'];
						var id = rowData['LOCALITY_ID'];
						var locality_remarks = rowData['LOCALITY_REMARKS'];
						if (locality_remarks) { remarks = " remarks: " + locality_remarks + " "; } else { remarks = ""; }
						var curated_fg = rowData['CURATED_FG'];
						if (curated_fg=="1") { curated = "*"; } else { curated = ""; }
						var sovereign_nation = rowData['SOVEREIGN_NATION'];
						var minimum_elevation = rowData['MINIMUM_ELEVATION'];
						var maximum_elevation = rowData['MAXIMUM_ELEVATION'];
						var orig_elevation_units = rowData['ORIG_ELEV_UNITS'];
						if (minimum_elevation) { 
							elevation = " Elev: " + minimum_elevation;
							if (maximum_elevation && maximum_elevation != minimum_elevation) {
								elevation = elevation + "-" + maximum_elevation;
							}
							elevation = elevation + " " + orig_elev_units + " ";
						} else {
							elevation = "";
						}
						var min_depth = rowData['MIN_DEPTH'];
						var max_depth = rowData['MAX_DEPTH'];
						var depth_units = rowData['DEPTH_UNITS'];
						if (min_depth) { 
							depth = " Depth: " + min_depth;
							if (max_depth && max_depth != min_depth) {
								depth = depth + "-" + max_depth;
							}
							depth = depth + " " + depth_units + " ";
						} else {
							depth = "";
						}
						var plss = rowData['PLSS'];
						var geolatts = rowData['GEOLATTS'];
						if (geolatts) { geology = " [" + geolatts + "] "; } else { geology = ""; } 
						var dec_lat = rowData['DEC_LAT'];
						var dec_long = rowData['DEC_LONG'];
						var datum = rowData['DATUM'];
						var max_error_distance = rowData['MAX_ERROR_DISTANCE'];
						var extent = rowData['EXTENT'];
						var verificationstatus = rowData['VERIFICATIONSTATUS'];
						var georefmethod = rowData['GEOREFMETHOD'];
						var nogeorefbecause = rowData['NOGEOREFBECAUSE'];
						if (dec_lat) { 
							coordinates = " " + dec_lat + ", " dec_long + " " + datum + " ±" + max_error_distance + " " + verificationstatus + " " 
						} else { 
							coordinates = " " + nogeorefbecause + " "; }
						}
						if (sovereign_nation) {
							if (sovereign_nation=="[unknown]") { 
								sovereign_nation = " Sovereign Nation: " + sovereign_nation + " ";
							} else {
								sovereign_nation = " " + sovereign_nation + " ";
							}
						}
						if (plss) { plss = " " + plss + " "; } 
						var data = spec_locality + geology +  elevation + depth + sovereign_nation + plss + coordinates + remarks + " (" + id + ")" + curated;
						return '<span class="#cellRenderClasses#" style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; ">' + data + '</span>';
					};
					var specimensCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
						var rowData = jQuery("##searchResultsGrid").jqxGrid('getrowdata',row);
						if (value==0) {
							return '<span class="#cellRenderClasses#" style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; ">None</span>';
						} else {
							var loc = encodeURIComponent(rowData['SPEC_LOCALITY']);
							var id = encodeURIComponent(rowData['LOCALITY_ID']);
							return '<span class="#cellRenderClasses#" style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; "><a href="/Specimens.cfm?execute=true&builderMaxRows=1&action=builderSearch&nestdepth1=1&field1=LOCALITY%3ALOCALITY_LOCALITY_ID_PICK&searchText1=' + loc + '&searchId1='+ id +'" target="_blank">'+value+'</a></span>';
						}
					};
					<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_locality")>
						var editCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
							var rowData = jQuery("##searchResultsGrid").jqxGrid('getrowdata',row);
							var id = encodeURIComponent(rowData['LOCALITY_ID']);
							return '<a target="_blank" href="/editLocality.cfm?locality_id=' + id + '">Edit</a>';
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
									{ name: 'LOCALITY_ID', type: 'string' },
									{ name: 'SPEC_LOCALITY', type: 'string' },
									{ name: 'CURATED_FG', type: 'string' },
									{ name: 'SOVEREIGN_NATION', type: 'string' },
									{ name: 'MINIMUM_ELEVATION', type: 'string' },
									{ name: 'MAXIMUM_ELEVATION', type: 'string' },
									{ name: 'ORIG_ELEV_UNITS', type: 'string' },
									{ name: 'MIN_DEPTH', type: 'string' },
									{ name: 'MAX_DEPTH', type: 'string' },
									{ name: 'DEPTH_UNITS', type: 'string' },
									{ name: 'PLSS', type: 'string' },
									{ name: 'GEOLATTS', type: 'string' },
									{ name: 'COLLCOUNTLOCALITY', type: 'string' },
									{ name: 'DEC_LAT', type: 'string' },
									{ name: 'DEC_LONG', type: 'string' },
									{ name: 'DATUM', type: 'string' },
									{ name: 'MAX_ERROR_DISTANCE', type: 'string' },
									{ name: 'EXTENT', type: 'string' },
									{ name: 'VERIFICATIONSTATUS', type: 'string' },
									{ name: 'GEOREFMETHOD', type: 'string' },
									{ name: 'NOGEOREFBECAUSE', type: 'string' },
									{ name: 'LOCALITY_REMARKS', type: 'string' }
								],
								updaterow: function (rowid, rowdata, commit) {
									commit(true);
								},
								root: 'locality',
								id: 'geog_auth_rec_id',
								url: '/localities/component/search.cfc?' + $('##searchForm').serialize(),
								timeout: 30000,  // units not specified, miliseconds? 
								loadError: function(jqXHR, textStatus, error) {
									handleFail(jqXHR,textStatus,error, "Error performing locality search: "); 
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
								autorowheight: 'true', // for text to wrap in cells
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
									<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_locality")>
										{text: 'Edit', datafield: 'Edit', width:60, columntype: 'button', hideable: false, cellsrenderer: editCellRenderer},
									</cfif>
									{ text: 'Cat.Items', datafield: 'SPECIMEN_COUNT',width: 100, hideabel: true, hidden: getColHidProp('SPECIMEN_COUNT',false), cellsrenderer: specimensCellRenderer  },
									{ text: 'Locality', datafield: 'LOCALITY_ID',width: 300, hideabel: true, hidden: getColHidProp('LOCALITY_ID',false), cellsrenderer: summaryCellRenderer  },
									{ text: 'Specific Locality', datafield: 'SPEC_LOCALITY',width: 200, hideabel: true, hidden: getColHidProp('SPEC_LOCALITY',true)  },
									{ text: 'Vetted', datafield: 'CURATED_FG',width: 50, hideabel: true, hidden: getColHidProp('CURATED_FG',false)  },
									{ text: 'Locality Remarks', datafield: 'LOCALITY_REMARKS',width: 100, hideabel: true, hidden: getColHidProp('LOCALITY_REMARKS',true)  },
									{ text: 'Min Depth', datafield: 'MIN_DEPTH',width: 100, hideabel: true, hidden: getColHidProp('MIN_DEPTH',true)  },
									{ text: 'Max Depth', datafield: 'MAX_DEPTH',width: 100, hideabel: true, hidden: getColHidProp('MAX_DEPTH',true)  },
									{ text: 'Depth Units', datafield: 'DEPTH_UNITS',width: 100, hideabel: true, hidden: getColHidProp('DEPTH_UNITS',true)  },
									{ text: 'Min Elevation', datafield: 'MINIMUM_ELEVATION',width: 100, hideabel: true, hidden: getColHidProp('MINIMUM_ELEVATION',true)  },
									{ text: 'Max Elevation', datafield: 'MAXIMUM_ELEVATION',width: 100, hideabel: true, hidden: getColHidProp('MAXIMUM_ELEVATION',true)  },
									{ text: 'Elev Units', datafield: 'ORIG_ELEV_UNITS',width: 100, hideabel: true, hidden: getColHidProp('ORIG_ELEV_UNITS',true)  },
									{ text: 'Lat.', datafield: 'DEC_LAT', width: 100, hideable: true, hidden: getColHidProp('DEC_LAT',true) },
									{ text: 'Long.', datafield: 'DEC_LONG', width: 100, hideable: true, hidden: getColHidProp('DEC_LONG',true) },
									{ text: 'Datum', datafield: 'DATUM', width: 100, hideable: true, hidden: getColHidProp('DATUM',true) },
									{ text: 'Error Radius', datafield: 'MAX_ERROR_DISTANCE', width: 100, hideable: true, hidden: getColHidProp('MAX_ERROR_DISTANCE',true) },
									{ text: 'Extent', datafield: 'EXTENT', width: 100, hideable: true, hidden: getColHidProp('EXTENT',true) },
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
							$("##searchResultsGrid").on("bindingcomplete", function(event) {
								// add a link out to this search, serializing the form as http get parameters
								$('##resultLink').html('<a href="/localities/Localities.cfm?action=search&execute=true&' + $('##searchForm :input').filter(function(index,element){return $(element).val()!='';}).serialize() + '">Link to this search</a>');
								gridLoaded('searchResultsGrid','locality record');
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
