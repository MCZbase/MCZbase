<!---
/media/findMedia.cfm

Media search/results 

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
<cfset pageTitle = "Search Media">
<cfinclude template = "/shared/_header.cfm">

<cfquery name="ctmedia_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select media_type  from ctmedia_type
</cfquery>
<cfquery name="ctmime_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select mime_type  from ctmime_type
</cfquery>

<div id="overlaycontainer" style="position: relative;"> 
	<!--- ensure fields have empty values present if not defined. --->
	<cfif not isdefined("mask_media_fg")> 
		<cfset mask_media_fg="">
	</cfif>
	<cfif not isdefined("media_uri")> 
		<cfset media_uri="">
	</cfif>
	<cfif not isdefined("preview_uri")> 
		<cfset preview_uri="">
	</cfif>
	<cfif not isdefined("mime_type")> 
		<cfset mime_type="">
	</cfif>
	<cfset in_mime_type=mime_type>
	<cfif not isdefined("media_type")> 
		<cfset media_type="">
	</cfif>
	<cfset in_media_type=media_type>
	<cfif not isdefined("media_id")> 
		<cfset media_id="">
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
						<!--- setup date pickers --->
						<script>
							$(document).ready(function() {
								<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
									$("##birth_date").datepicker({ dateFormat: 'yy-mm-dd'});
									$("##to_birth_date").datepicker({ dateFormat: 'yy-mm-dd'});
									$("##death_date").datepicker({ dateFormat: 'yy-mm-dd'});
									$("##to_death_date").datepicker({ dateFormat: 'yy-mm-dd'});
								</cfif>
								$("##collected_date").datepicker({ dateFormat: 'yy-mm-dd'});
								$("##to_collected_date").datepicker({ dateFormat: 'yy-mm-dd'});
							});
						</script>
						<div class="col-12 px-4 pt-3 pb-2">
							<form name="searchForm" id="searchForm">
								<input type="hidden" name="method" value="getAgents">
								<div class="form-row mb-2">
									<div class="col-12 col-md-5">
										<label for="media_uri" class="data-entry-label" id="media_uri_label">Media URI</label>
										<input type="text" id="media_uri" name="media_uri" class="data-entry-input" value="#media_uri#" aria-labelledby="media_uri_label" >
									</div>
									<div class="col-12 col-md-1">
										<label for="media_id" class="data-entry-label" id="mediaid_label">Media ID</label>
										<input type="text" id="media_id" name="media_id" value="#media_id#" class="data-entry-input">
									</div>
									<div class="col-12 col-md-3">
										<label for="media_type" class="data-entry-label" id="media_type_label">Media Type</label>
										<select id="media_type" name="media_type" class="data-entry-select">
											<option></option>
											<cfloop query="ctmedia_type">
												<cfif in_media_type EQ ctmedia_type.media_type><cfset selected="selected='true'"><cfelse><cfset selected=""></cfif>
												<option value="#ctmedia_type.media_type#" #selected#>#ctmedia_type.media_type#</option>
											</cfloop>
											<cfloop query="ctmedia_type">
												<cfif in_media_type EQ "!#ctmedia_type.media_type#"><cfset selected="selected='true'"><cfelse><cfset selected=""></cfif>
												<option value="!#ctmedia_type.media_type#" #selected#>not #ctmedia_type.media_type#</option>
											</cfloop>
										</select>
									</div>
									<div class="col-12 col-md-3">
										<label for="mime_type" class="data-entry-label" id="mime_type_label">MIME Type</label>
										<select id="mime_type" name="mime_type" class="data-entry-select">
											<option></option>
											<cfloop query="ctmime_type">
												<cfif in_mime_type EQ ctmime_type.mime_type><cfset selected="selected='true'"><cfelse><cfset selected=""></cfif>
												<option value="#ctmime_type.mime_type#" #selected#>#ctmime_type.mime_type#</option>
											</cfloop>
											<cfloop query="ctmime_type">
												<cfif in_mime_type EQ "!#ctmime_type.mime_type#"><cfset selected="selected='true'"><cfelse><cfset selected=""></cfif>
												<option value="!#ctmime_type.mime_type#" #selected#>not #ctmime_type.mime_type#</option>
											</cfloop>
										</select>
									</div>
								</div>
								<div class="form-row mb-2">
									<div class="col-12 col-md-5">
										<label for="preview_uri" class="data-entry-label" id="preview_uri_label">Preview URI</label>
										<input type="text" id="preview_uri" name="preview_uri" class="data-entry-input" value="#preview_uri#" aria-labelledby="preview_uri_label" >
									</div>
									<div class="col-12 col-md-2">
										<label for="mask_media_fg" class="data-entry-label" id="mask_media_fg_label">Mask Media Flag</label>
										<select id="mask_media_fg" name="mask_media_fg" class="data-entry-select">
											<option></option>
											<cfif mask_media_fg EQ "1"><cfset sel = "selected='true'"><cfelse><cfset sel = ""></cfif>
											<option value="1" #sel#>1</option>
											<cfif mask_media_fg EQ "0"><cfset sel = "selected='true'"><cfelse><cfset sel = ""></cfif>
											<option value="0" #sel#>0</option>
										</select>
									</div>
								</div>
								<div class="form-row my-2 mx-0">
									<div class="col-12 px-0 pt-2">
										<button class="btn-xs btn-primary px-2 my-2 mr-1" id="searchButton" type="submit" aria-label="Search for media">Search<span class="fa fa-search pl-1"></span></button>
										<button type="reset" class="btn-xs btn-warning my-2 mr-1" aria-label="Reset search form to inital values" onclick="">Reset</button>
										<button type="button" class="btn-xs btn-warning my-2 mr-1" aria-label="Start a new media search with a clear form" onclick="window.location.href='#Application.serverRootUrl#/media/findMedia.cfm';" >New Search</button>
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
							{ name: 'media_id', type: 'string' },
							{ name: 'mask_media_fg', type: 'string' },
							{ name: 'media_type', type: 'string' },
							{ name: 'mime_type', type: 'string' },
							{ name: 'preview_uri', type: 'string' },
							{ name: 'media_uri', type: 'string' }
						],
						updaterow: function (rowid, rowdata, commit) {
							commit(true);
						},
						root: 'mediaRecord',
						id: 'media_id',
						url: '/media/component/search.cfc?' + $('##searchForm').serialize(),
						timeout: 60000,  // units not specified, miliseconds? 
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
							{text: 'ID', datafield: 'media_id', width:100, hideable: true, hidden: false, cellsrenderer: editIdCellRenderer },
							{text: 'Visibility', datafield: 'mask_media_fg', width: 60, hidable: true, hidden: true },
							{text: 'Media Type', datafield: 'media_type', width: 100, hidable: true, hidden: true },
							{text: 'Mime Type', datafield: 'mime_type', width: 100, hidable: true, hidden: true },
							{text: 'Preview URI', datafield: 'preview_uri', width: 100, hidable: true, hidden: true },
							{text: 'Media URI', datafield: 'media_uri', hideable: true, hidden: false }
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
						$('##resultLink').html('<a href="/agents/Agents.cfm?execute=true&' + $('##searchForm').serialize() + '">Link to this search</a>');
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
