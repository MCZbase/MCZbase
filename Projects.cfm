<!---
/Projects.cfm

Projects search/results 

Copyright 2022-2024 President and Fellows of Harvard College

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
<cfset pageTitle = "Search Projects">
<cfinclude template = "/shared/_header.cfm">

<cfset defaultSelectionMode = "none">
<cfif defaultSelectionMode EQ "none">
	<cfset defaultenablebrowserselection = "true">
<cfelse>
	<cfset defaultenablebrowserselection = "false">
</cfif>

<div id="overlaycontainer" style="position: relative;"> 
	<!--- ensure fields have empty values present if not defined. --->
	<cfif not isdefined("project_title")> 
		<cfset project_title="">
	</cfif>
	<cfif not isdefined("project_participant")> 
		<cfset project_participant="">
	</cfif>
	<cfif not isdefined("project_year")> 
		<cfset project_year="">
	</cfif>
	<cfif not isdefined("project_sponsor")> 
		<cfset project_sponsor="">
	</cfif>
	<cfif not isdefined("project_type")> 
		<cfset project_type="">
	</cfif>
	<cfif not isdefined("min_proj_desc_length")> 
		<cfset min_proj_desc_length="">
	</cfif>
	<!--- cfset in_publication_type="#publication_type#">
	<cfset in_type_status="#type_status#" --->

	<!--- Search Form --->
	<cfoutput> 
		<main id="content">
			<section class="container-fluid mb-3" role="search" aria-labelledby="formheader">
				<div class="row mx-0 mb-3">
					<div class="search-box">
						<div class="search-box-header">
							<h1 class="h3 text-white" id="formheading">Find Project Records</h1>
						</div>
						<div class="col-12 pt-3 px-4 pb-2" id="searchFormDiv">
							<form name="searchForm" id="searchForm">
								<input type="hidden" name="method" value="getProjects">
								<div class="form-row">
									<div class="col-12 col-md-5">
										<div class="form-group mb-2">
											<label for="text" class="data-entry-label mb-0" id="project_title_label">Project Title</label>
											<input type="text" id="project_title" name="project_title" class="data-entry-input" value="#encodeForHtml(project_title)#" aria-labelledby="project_title_label" >
										</div>
									</div>
									<div class="col-12 col-md-5">
										<div class="form-group mb-2">
											<label for="project_sponsor" class="data-entry-label mb-0" id="project_sponsor_label">Sponsor</label>
											<input type="text" id="project_sponsor" name="project_sponsor" class="data-entry-input" value="#encodeForHtml(project_sponsor)#" aria-labelledby="project_sponsor_label" >
										</div>
									</div>
								</div>
								<div class="form-row">
									<div class="col-12 col-md-5">
										<div class="form-group mb-2">
											<label for="project_participant" class="data-entry-label mb-0" id="project_participant_label">Participant</label>
											<input type="text" id="project_participant" name="project_participant" class="data-entry-input" value="#encodeForHtml(project_participant)#" aria-labelledby="project_participant" >
										</div>
									</div>
                                                                        <div class="col-12 col-md-5">
                                                                                <div class="form-group mb-2">
                                                                                        <label for="project_type" class="data-entry-label mb-0" id="project_type_label">Type</label>
                                                                                        <input type="text" id="project_type" name="project_type" class="data-entry-input" value="#encodeForHtml(project_type)#" aria-labelledby="project_type_label" >
                                                                                </div>
                                                                        </div>

								</div>
								<div class="form-row">
									<div class="col-12 col-md-5">
										<div class="form-group mb-2">
											<label for="project_year" class="data-entry-label mb-0" id="project_year">Year</label>
											<input type="text" id="project_year" name="project_year" class="data-entry-input" value="#encodeForHtml(project_year)#" aria-labelledby="project_year_label" >
										</div>
									</div>
                                                                        <div class="col-12 col-md-5">
                                                                                <div class="form-group mb-2">
                                                                                        <label for=" min_proj_desc_length" class="data-entry-label mb-0" id=" min_proj_desc_length">Description Minimum Length</label>
                                                                                        <input type="text" id=" min_proj_desc_length" name=" min_proj_desc_length" class="data-entry-input" value="#encodeForHtml(min_proj_desc_length)#" aria-labelledby=" min_proj_desc_length_label" >
                                                                                </div>
                                                                        </div>
									<div class="col-12 pt-0">
										<button class="btn-xs btn-primary px-2 my-2 mr-1" id="searchButton" type="submit" aria-label="Search for projects">Search<span class="fa fa-search pl-1"></span></button>
										<button type="reset" class="btn-xs btn-warning my-2 mr-1" aria-label="Reset search form to inital values" onclick="">Reset</button>
										<button type="button" class="btn-xs btn-warning my-2 mr-1" aria-label="Start a new projects search with a clear form" onclick="window.location.href='#Application.serverRootUrl#/Projects.cfm';" >New Search</button>
										<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_publications")>
											<a class="btn-xs btn-secondary my-2 text-decoration-none" aria-label="Create a new project record" href="#Application.serverRootUrl#/projects/Project.cfm?action=new">Create New Project</a>
										</cfif>
									</div>
								</div>
							</form>
						</div>
					</div>
				</div>
			</section>
			<!--- Results table as a jqxGrid. --->
			<section class="container-fluid">
				<div class="row mx-0">
					<div class="col-12">
						<div class="mb-5">
							<div class="row my-1 jqx-widget-header border px-2">
								<h1 class="h4 pt-2 ml-2 ml-md-1 mt-1">Results: 
									<span class="pr-2 font-weight-normal" id="resultCount"></span> 
									<span id="resultLink" class="font-weight-normal pr-2"></span>
								</h1>
								<div id="showhide" class=""></div>
								<div id="saveDialogButton" class=""></div>
								<div id="saveDialog"></div>
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
								<output id="actionFeedback" class="btn btn-xs btn-transparent my-2 px-2 pt-1 mx-1 border-0"></output>
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

			$(document).ready(function() {
				/* Setup jqxgrid for Search */
				$('##searchForm').bind('submit', function(evt){
					evt.preventDefault();
			
					$("##overlay").show();
			
					$("##searchResultsGrid").replaceWith('<div id="searchResultsGrid" class="jqxGrid" style="z-index: 1;"></div>');
					$('##resultCount').html('');
					$('##resultLink').html('');
					$('##showhide').html('');
					$('##saveDialogButton').html('');
					$('##selectModeContainer').hide();
					$('##actionFeedback').html('');
			
					var search =
					{
						datatype: "json",
						datafields:
						[
							{ name: 'project_title', type: 'string' },
							{ name: 'project_sponsor', type: 'string' },
							{ name: 'project_participant', type: 'string' },
							{ name: 'project_type', type: 'string' },
							{ name: 'project_year', type: 'string' },
							{ name: 'min_proj_desc_length', type: 'string' },
						],
						updaterow: function (rowid, rowdata, commit) {
							commit(true);
						},
						root: 'projectsRecord',
						id: 'project_id',
						url: '/projects/component/search.cfc?' + $('##searchForm').serialize(),
						timeout: #Application.ajax_timeout#000,  // units not specified, miliseconds? 
						loadError: function(jqXHR, textStatus, error) { 
							$("##overlay").hide();
							handleFail(jqXHR,textStatus,error,"running projects search");
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
							<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_publications")>
								{text: 'Project', datafield: 'project_name', width:150, hideable: false, cellsrenderer: citationCellRenderer },
								{text: 'ID', datafield: 'project_id', width:60, hideable: false, cellsrenderer: editCellRenderer},
								{text: 'Citations', datafield: 'start_date', width:80, hideable: false, editable: false, cellsrenderer: manageCitationsCellRenderer, exportable: false },
							<cfelse>
								{text: 'Publication', datafield: 'end_date', width:150, hideable: false, cellsrenderer: citationCellRenderer },
								{text: 'ID', datafield: 'agent_name', width:100, hideable: true, hidden: getColHidProp('publication_id', true), cellsrenderer: linkIdCellRenderer},
							</cfif>
							{text: 'Specimens Cited', datafield: 'agent_role', width:80, hideable: true, hidden: getColHidProp('authors', false), cellsrenderer: countCellRenderer },
							{text: 'Authors', datafield: 'acknowledgement', width:150, hideable: true, hidden: getColHidProp('authors', false) },
							{text: 'Editors', datafield: 'sponsor', width:100, hideable: true, hidden: getColHidProp('editors', true) },
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
						$('##resultLink').html('<a href="/Publications.cfm?execute=true&' + $('##searchForm :input').filter(function(index,element){return $(element).val()!='';}).serialize() + '">Link to this search</a>');
						$('##showhide').html('<button class="my-2 border rounded" title="hide search form" onclick=" toggleAnySearchForm(\'searchFormDiv\',\'searchFormToggleIcon\'); "><i id="searchFormToggleIcon" class="fas fa-eye-slash"></i></button>');
						gridLoaded('searchResultsGrid','publication record');
						loadColumnOrder('searchResultsGrid');
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
	</cfoutput>
</div><!--- overlay container --->

<cfinclude template = "/shared/_footer.cfm">
