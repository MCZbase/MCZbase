<!---
grouping/UnderscoreCollection.cfm

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
		<cfset pageTitle = "Search ____ Collections">
	</cfcase>
	<cfcase value="new">
		<cfset pageTitle = "Add New ____ Collection">
		<cfif NOT isdefined("session.roles") OR NOT listfindnocase(session.roles,"manage_specimens")>
			<cflocation url="/errors/forbidden.cfm?ref=#r#" addtoken="false">
		</cfif>
	</cfcase>
	<cfcase value="edit">
		<cfset pageTitle = "Edit an ______ Collection">
	</cfcase>
	<cfdefaultcase>
		<cfset pageTitle = "_______ Collection">
	</cfdefaultcase>
</cfswitch>
<!---------------------------------------------------------------------------------->
<cfinclude template = "/shared/_header.cfm">
<!---------------------------------------------------------------------------------->
<cfswitch expression="#action#">
	<cfcase value="search">
		<div id="overlaycontainer" style="position: relative;">
			<!--- ensure fields have empty values present if not defined. --->
			<cfif not isdefined("collection_name")><cfset collection_name=""></cfif>
			<cfif not isdefined("description")><cfset description=""></cfif>
			<cfif not isdefined("guid")><cfset guid=""></cfif>
			<!--- Search Form --->
			<cfoutput>
				<div class="container">
					<div class="row">
						<div class="col-12">
							<div role="region" aria-labelledby="formheading">
								<h2 id="formheading">Find "______ Collections" (arbitrary groups of collection objects)</h2>
								<p>Can represent collections by workers in natural history, as in <a href="http://id.lib.harvard.edu/alma/990011227530203941/catalog">Sherborn, 1940.</a> "Where is the _______ collection? An account of the various natural history collections which have come under the notice of the compiler", or any arbitrary grouping of cataloged items in MCZbase.</p>
								<form name="searchForm" id="searchForm"> 
									<input type="hidden" name="method" value="getCollections" class="keeponclear">
									<div class="form-row mb-2">
										<div class="col-md-6">
											<label for="collection_name" id="collection_name_label">Name for the Collection</label>
											<input type="text" id="collection_name" name="collection_name" class="form-control-sm" value="#collection_name#" aria-labelledby="collection_name_label" >					
										</div>
										<div class="col-md-6">
											<label for="description" id="description_label">Description</label>
											<input type="text" id="description" name="description" class="form-control-sm" value="#description#" aria-labelledby="description_label" >					
										</div>
									</div>
									<div class="form-row mb-2">
										<div class="col-md-12">
											<label for="guid" id="guid_label">A cataloged item which is a member of the collection</label>
											<input type="text" id="guid" name="guid" class="form-control-sm" value="#guid#" aria-labelledby="guid_label" >					
										</div>
									</div>
									<div class="form-row my-2 mx-0">
										<div class="col-12 text-left">
											<button class="btn-xs btn-primary px-2" id="searchButton" type="submit" aria-label="Search for arbitrary collections">Search<span class="fa fa-search pl-1"></span></button>
											<button type="reset" class="btn-xs btn-warning" aria-label="Reset search form to inital values" onclick="">Reset</button>
											<button type="button" class="btn-xs btn-warning" aria-label="Start a new collection search with a clear form" onclick="window.location.href='#Application.serverRootUrl#/grouping/UnderscoreCollection.cfm?action=search';" >New Search</button>
											<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_specimens")>
												<button type="button" class="btn-xs btn-secondary" aria-label="Create a new arbitrary collection" onclick="window.location.href='#Application.serverRootUrl#/grouping/UnderscoreCollection.cfm?action=new';" >Create new "Collection"</button>
											</cfif>
										</div>
									</div>
								</form>
							</div>
						</div>
					</div>
				</div>
			</cfoutput>
	
			<!--- Results table as a jqxGrid. --->
			<div class="container-fluid">
				<div class="row">
					<div class="text-left col-md-12">
						<main role="main">
							<div class="pl-2 mb-5"> 
								
								<div class="row mt-1 mb-0 pb-0 jqx-widget-header border px-2">
									<h4>Results: </h4>
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
						</main>
					</div>
				</div>
			</div>
		
			<cfoutput>
				<script>
					var linkIdCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
						var rowData = jQuery("##searchResultsGrid").jqxGrid('getrowdata',row);
						return '<span style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; "><a href="/grouping/UnderscoreCollection.cfm?action=edit&underscore_collection_id=' + rowData['UNDERSCORE_COLLECTION_ID'] + '">'+value+'</a></span>';
					};


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
									{ name: 'SPECIMEN_COUNT', type: 'string' }
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
								pagesizeoptions: ['50','100'],
								showaggregates: true,
								columnsresize: true,
								autoshowfiltericon: true,
								autoshowcolumnsmenubutton: false,
								autoshowloadelement: false,  // overlay acts as load element for form+results
								columnsreorder: true,
								groupable: true,
								selectionmode: 'none',
								altrows: true,
								showtoolbar: false,
								columns: [
									{text: '__ Collection', datafield: 'UNDERSCORE_COLLECTION_ID', width:100, hideable: true, hidden: true },
									{text: 'Name', datafield: 'COLLECTION_NAME', width: 300, hidable: true, hidden: false, cellsrenderer: linkIdCellRenderer },
									{text: 'Agent', datafield: 'AGENTNAME', width: 150, hidable: true, hidden: false },
									{text: 'AgentID', datafield: 'UNDERSCORE_AGENT_ID', width:100, hideable: true, hidden: true },
									{text: 'Specimen Count', datafield: 'SPECIMEN_COUNT', width:150, hideable: true, hidden: false },
									{text: 'Description', datafield: 'DESCRIPTION', hideable: true, hidden: false },
								],
								rowdetails: true,
								rowdetailstemplate: {
									rowdetails: "<div style='margin: 10px;'>Row Details</div>",
									rowdetailsheight:  1 // row details will be placed in popup dialog
								},
								initrowdetails: initRowDetails
							});
							$("##searchResultsGrid").on("bindingcomplete", function(event) {
								// add a link out to this search, serializing the form as http get parameters
								$('##resultLink').html('<a href="/grouping/UnderscoreCollection.cfm?action=search&execute=true&' + $('##searchForm').serialize() + '">Link to this search</a>');
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
						   $('##' + gridId).jqxGrid({ pagesizeoptions: ['50', '100', rowcount]});
						} else if (rowcount > 50) { 
						   $('##' + gridId).jqxGrid({ pagesizeoptions: ['50', rowcount]});
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
							"<button id='columnPickDialogOpener' onclick=\" $('##columnPickDialog').dialog('open'); \" class='btn btn-secondary px-3 py-1 my-1 mx-3' >Show/Hide Columns</button>"
						);
						// workaround for menu z-index being below grid cell z-index when grid is created by a loan search.
						// likewise for the popup menu for searching/filtering columns, ends up below the grid cells.
						var maxZIndex = getMaxZIndex();
						$('.jqx-grid-cell').css({'z-index': maxZIndex + 1});
						$('.jqx-grid-group-cell').css({'z-index': maxZIndex + 1});
						$('.jqx-menu-wrapper').css({'z-index': maxZIndex + 2});
						$('##resultDownloadButtonContainer').html('<button id="loancsvbutton" class="btn btn-secondary px-3 py-1 my-1 mx-0" aria-label="Export results to csv" onclick=" exportGridToCSV(\'searchResultsGrid\', \''+filename+'\'); " >Export to CSV</button>');
					}
				</script>
			</cfoutput>
			<div id="overlay" style="position: absolute; top:0px; left:0px; width: 100%; height: 100%; background: rgba(0,0,0,0.5); opacity: 0.99; display: none; z-index: 2;">
				<div class="jqx-rc-all jqx-fill-state-normal" style="position: absolute; left: 50%; top: 25%; width: 10em; height: 2.4em;line-height: 2.4em; padding: 5px; color: ##333333; border-color: ##898989; border-style: solid; margin-left: -10em; opacity: 1;">
					<div class="jqx-grid-load" style="float: left; overflow: hidden; height: 32px; width: 32px;"></div>
					<div style="float: left; display: block; margin-left: 1em;" >Searching...</div>	
				</div>
			</div>
		</div><!--- overlay container --->
	</cfcase>
	<!---------------------------------------------------------------------------------->
	<cfcase value="new">
		<!---  Add a new ____ collection, link to agent --->
		<cfoutput>
			<div class="container">
				<div class="row">
					<div class="col-12">
						<div role="region" aria-labelledby="formheading">
							<h2 id="formheading">New "Collection" (arbitrary grouping of specimens)</h2>
							<form name="newUnderscoreCollection" id="newUnderscoreCollection" action="/grouping/UnderscoreCollection.cfm" method="post"> 
								<input type="hidden" id="action" name="action" value="saveNew" >
								<div class="form-row mb-2">
									<div class="col-md-12">
										<label for="collection_name" id="collection_name_label">Name for the Collection</label>
										<input type="text" id="collection_name" name="collection_name" class="form-control-sm reqdClr" required aria-labelledby="collection_name_label" >					
									</div>
								</div>
								<div class="form-row mb-2">
									<div class="col-md-12">
										<label for="description" id="description_label">Description (<span id="length_description">0 characters, 4000 left</span>)</label>
										<textarea id="description" name="description" class="data-entry-textarea mt-1"
											onkeyup="countCharsLeft('description',4000,'length_description');"
											rows="3" aria-labelledby="description_label" ></textarea>
									</div>
								</div>
								<script>
									$('##description').keyup(autogrow);
								</script>
								<div class="form-row mb-5">
									<div class="col-12 col-md-6">
										<span>
											<label for="underscore_agent_name">Agent associated with this Collection</label>
											<span id="underscore_agent_view">&nbsp;&nbsp;&nbsp;&nbsp;</span>
										</span>
										<input name="underscore_agent_name" id="underscore_agent_name" class="form-control-sm" value="" aria-label="Agent associated with this arbitrary collection:" >
										<input type="hidden" name="underscore_agent_id" id="underscore_agent_id" value=""  >
										<script>
											$(document).ready(function() {
												$(makeAgentPicker('underscore_agent_name','underscore_agent_id'));
											});
										</script>
									</div>
									<div class="col-12 col-md-6 px-2 my-3 px-sm-2 my-4">   								
											<input type="button" 
												value="Create" title="Create" aria-label="Create"
												class="btn btn-xs btn-primary"
												onClick="if (checkFormValidity($('##newUnderscoreCollection')[0])) { submit();  } " 
												>
									</div>
								</div>
							</form>
						</div><!--- region --->
					</div><!--- col --->
				</div><!--- row --->
			</div><!--- container --->
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
					<cfif isdefined("underscore_agent_id") and len(underscore_agent_id) GT 0 >
						,underscore_agent_id
					</cfif>
				) values (
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#collection_name#">
					<cfif isdefined("description")>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#description#">
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
			<cflocation url="/grouping/UnderscoreCollection.cfm?action=edit&underscore_collection_id=#savePK.underscore_collection_id#" addtoken="false">
		<cfcatch>
			<cfthrow type="Application" message="Error Saving new _____ Collection: #cfcatch.Message# #cfcatch.Detail#">
		</cfcatch>
		</cftry>
	</cfcase>
	<!---------------------------------------------------------------------------------->
	<cfcase value="edit">
		<cfif not isDefined("underscore_collection_id")>
			<cfset underscore_collection_id = "">
		</cfif>
		<cfif len("underscore_collection_id") EQ 0>
			<cfthrow type="Application" message="Error: No value provided for underscore_collection_id">
		<cfelse>
			<cfquery name="undColl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="undColl_result">
				select underscore_collection_id, collection_name, description, underscore_agent_id,
					case 
						when underscore_agent_id is null then '[No Agent]'
						else MCZBASE.get_agentnameoftype(underscore_agent_id, 'preferred')
						end
					as agentname
				from underscore_collection
				where underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
			</cfquery>
			<cfoutput query="undColl">
				<cfset collname = collection_name><!--- save name for later use outside this output section --->
				<div class="container">
					<div class="row">
						<div class="col-12">
							<div role="region" aria-labelledby="formheading">
								<h2 id="formheading">Edit "Collection" (arbitrary grouping of collection objects)</h2>
								<form name="editUndColl" id="editUndColl"> 
									<input type="hidden" id="underscore_collection_id" name="underscore_collection_id" value="#underscore_collection_id#" >
									<input type="hidden" id="method" name="method" value="saveUndColl" >
									<div class="form-row mb-2">
										<div class="col-md-12">
											<label for="collection_name" id="collection_name_label">Name for the Collection</label>
											<input type="text" id="collection_name" name="collection_name" class="form-control-sm reqdClr" 
												required value="#collection_name#" aria-labelledby="collection_name_label" >					
										</div>
									</div>
									<div class="form-row mb-2">
										<div class="col-md-12">
											<label for="description" id="description_label">Description (<span id="length_description"></span>)</label>
											<textarea id="description" name="description" class="data-entry-textarea mt-1 autogrow"
												onkeyup="countCharsLeft('description',4000,'length_description');"
												rows="3" aria-labelledby="description_label" >#description#</textarea>
										</div>
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
									<div class="form-row mb-5">
										<div class="col-12 col-md-6"> 
											<span>
												<label for="underscore_agent_name" id="underscore_agent_name_label">Agent Associated with this Collection</label>
												<span id="underscore_agent_view">&nbsp;&nbsp;&nbsp;&nbsp;</span>
											</span>
											<input name="underscore_agent_name" id="underscore_agent_name" class="form-control-sm" value="#agentname#" aria-labelledby="underscore_agent_name_label" >
											<input type="hidden" name="underscore_agent_id" id="underscore_agent_id" value="#underscore_agent_id#"  >
											<script>
												function changed(){
													$('##saveResultDiv').html('Unsaved changes.');
												};
												$(document).ready(function() {
													$(makeAgentPicker('underscore_agent_name','underscore_agent_id'));
													$('##editUndColl input[type=text]').on("change",changed);
													$('##description').on("change",changed);
												});
												function saveChanges(){ 
													var agenttext = $('##underscore_agent_name').val();
													var agentid = $('##underscore_agent_id').val();
													if (agenttext.length == 0 || (agentid.length>0 && agenttext.length>0)) { 
														$('##saveResultDiv').html('Saving....');
														jQuery.ajax({
															url : "/grouping/component/functions.cfc",
															type : "post",
															dataType : "json",
															data :  $('##editUndColl').serialize(),
															success : function (data) {
																$('##saveResultDiv').html('Saved.');
															},
															error: function(jqXHR,textStatus,error){
																$('##saveResultDiv').html('Error.');
																var message = "";
																if (error == 'timeout') {
																	message = ' Server took too long to respond.';
																} else {
																	message = jqXHR.responseText;
																}
																messageDialog('Error saving ____ collection: '+message, 'Error: '+error.substring(0,50));
															}
														});
													} else { 
														messageDialog('Error saving ___ collection: If an entry is made in the agent field an agent must be selected from the picklist.', 'Error: Agent not selected');
														$('##saveResultDiv').html('Fix error in Agent field.');
													}
												};
											</script>
										</div>
										<div class="col-12 col-md-6"> 
											<div id="saveResultDiv">&nbsp;</div>
											<input type="button" 
												value="Save" title="Save" aria-label="Save"
												class="btn btn-xs btn-primary"
												onClick="if (checkFormValidity($('##editUndColl')[0])) { saveChanges();  } " 
												>
										</div>
									</div>
								</form>
							</div><!--- region --->
							<div role="region" aria-labelledby="formheading">
								<form name="addCollObjectsUndColl" id="addCollObjectsUndColl"> 
									<input type="hidden" id="underscore_collection_id" name="underscore_collection_id" value="#underscore_collection_id#" >
									<input type="hidden" id="method" name="method" value="addObjectsToUndColl" >
									<div class="form-row mb-2">
										<div class="col-md-10">
											<label for="guid_list" id="guid_list_label">Collection objects to add to this collection (comma separated list of GUIDs in the form MCZ:Dept:number)</label>
											<input type="text" id="guid_list" name="guid_list" class="form-control-sm " 
												value="" aria-labelledby="guid_list_label" placeholder="MCZ:Dept:1111,MCZ:Dept:1112" >					
										</div>
										<script>
											function addCollectionObjects(){ 
												$('##addResultDiv').html("Saving.... ");
												jQuery.ajax({
													url : "/grouping/component/functions.cfc",
													type : "post",
													dataType : "json",
													data :  $('##addCollObjectsUndColl').serialize(),
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
														messageDialog('Error saving ____ collection: '+message, 'Error: ' + error.substring(0,50));
														$('##addResultDiv').html("Error.");
													}
												});
											};
										</script>
										<div class="col-md-2">
											<div id="addResultDiv">&nbsp;</div>
											<input type="button" id="addbutton"
												value="Save" title="Save" aria-label="Save"
												class="btn btn-xs btn-primary"
												onClick=" addCollectionObjects(); " 
												>
										</div>
									</div>
								</form>
							</div>
						</div><!--- col --->
					</div><!--- row --->
				</div><!--- container --->
			</cfoutput>
			<cfif undColl_result.recordcount GT 0>
				<!--- list specimens in the collection, link out by guid --->
				<cfquery name="undCollUse" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="undCollUse_result">
					select guid 
					from #session.flatTableName#
						left join underscore_relation on underscore_relation.collection_object_id = flat.collection_object_id
					where underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
					order by guid
				</cfquery>
				<cfoutput>
					<div class="container">
						<div role="region" aria-labelledby="existingvalues" id="divListOfContainedObjects">
							<cfif undCollUse_result.recordcount EQ 0>
								<h2 id="existingvalues">There are no collection objects in this (arbitrary) collection</h2>
								<form action="/grouping/UnderscoreCollection.cfm" method="post" id="deleteForm">
									<input type="hidden" name="action" value="delete">
									<input type="hidden" name="underscore_collection_id" value="#underscore_collection_id#">
									<button class="btn btn-danger" id="deleteButton" aria-label="Delete this collection.">Delete</button>
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
								<h2 id="existingvalues">Collection objects in this (arbitrary) collection</h2>
								<ul>
									<cfloop query="undCollUse">
										<li><a href="/guid/#undCollUse.guid#" target="_blank">#undCollUse.guid#</a>
									</cfloop>
								</ul>
							</cfif>
						</div>
					</div>
				</cfoutput>
			</cfif>
		</cfif>
	</cfcase>
	<!---------------------------------------------------------------------------------->
	<cfcase value="delete">
		<cftry>
			<cfif not isdefined("underscore_collection_id") OR len(trim(#underscore_collection_id#)) EQ 0 >
				<cfthrow type="Application" message="Error: No value provided for required value underscore_collection_id">
			</cfif>
			<cfquery name="save" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="insertResult">
				delete from underscore_collection 
				where
				 	underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
			</cfquery>
			<h2>"Collection" successfully deleted.</h2>
			<ul>
				<li><a href="/grouping/UnderscoreCollection.cfm">Search for "Collections"</a> (arbitrary groupings of collection objects).</li>
				<li><a href="/grouping/UnderscoreCollection.cfm?action=new">Create a new "Collection"</a> (arbitrary grouping of collection objects).</li>
			</ul>
		<cfcatch>
			<cfthrow type="Application" message="Error deleting _____ Collection: #cfcatch.Message# #cfcatch.Detail#">
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
