<cfif not isdefined("action")>
	<cfset action="nothing">
</cfif>
<cfif action EQ 'editPermit'>
	<cfset action = 'edit'><!--- support old API --->
</cfif>
<!--- TODO: Handle Headless (? for dialogs ?) --->
<cfswitch expression="#action#">
	<cfcase value="search">
		<cfset pageTitle = "Find Permissions/Rights Documents">
	</cfcase>
	<cfcase value="new">
		<cfset pagetitle = "New Permissions/Rights Document">
	</cfcase>
	<cfcase value="create">
		<cfset pagetitle = "Save New Permissions/Rights Document">
	</cfcase>
	<cfcase value="edit">
		<cfset pagetitle = "Edit Permissions/Rights Document">
	</cfcase>
	<cfcase value="view">
		<cfset pagetitle = "View Permissions/Rights Document">
	</cfcase>
	<cfcase value="delete">
		<cfset pagetitle = "Delete a Permissions/Rights Document">
	</cfcase>
	<cfcase value="permitUseReport">
		<cfset pagetitle = "Permissions/Rights Document Use Report">
	</cfcase>
	<cfdefaultcase>
		<cfset pageTitle = "Find Permissions/Rights Documents">
		<cfset action="search">
	</cfdefaultcase>
</cfswitch>
<!--
/transactions/Permit.cfm

Copyright 2008-2017 Contributors to Arctos
Copyright 2008-2022 President and Fellows of Harvard College

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

-->
<cfinclude template = "/shared/_header.cfm">

<cfset defaultSelectionMode = "none">
<cfif defaultSelectionMode EQ "none">
	<cfset defaultenablebrowserselection = "true">
<cfelse>
	<cfset defaultenablebrowserselection = "false">
</cfif>	

<cfquery name="ctPermitType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" timeout="#Application.short_timeout#">
	select ct.permit_type, count(p.permit_id) uses
		from ctpermit_type ct left join permit p on ct.permit_type = p.permit_type
		group by ct.permit_type
		order by ct.permit_type
</cfquery>
<cfquery name="ctSpecificPermitType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" timeout="#Application.short_timeout#">
	select ct.specific_type, ct.permit_type, count(p.permit_id) uses from 
		ctspecific_permit_type ct left join permit p on ct.specific_type = p.specific_type
		group by ct.specific_type, ct.permit_type
		order by ct.specific_type
</cfquery>

<cfswitch expression="#action#">
	<cfcase value="search">
		<div id="overlaycontainer" style="position: relative;">
			<main id="content">
				<cfif isdefined("permit_id") and len(permit_id) GT 0>
					<cfquery name="lookupPermit" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="lookupPermit_result">
						SELECT permit_title, permit_number, permit_type, specific_type
						FROM permit
						WHERE permit_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="permit_id">
					</cfquery>
					<cfloop query="lookupPermit">
						<cfset permit_title=lookupPermit.permit_title>
						<cfset permit_number=lookupPermit.permit_number>
						<cfset permit_type=lookupPermit.permit_type>
						<cfset specific_type=lookupPermit.specific_type>
					</cfloop>
				</cfif>
				<!--- ensure fields have empty values present if not defined. --->
				<cfif not isdefined("permit_title")><cfset permit_title=""></cfif>
				<cfif not isdefined("permit_num")><cfset permit_num=""></cfif>
				<cfif not isdefined("IssuedByAgent")><cfset IssuedByAgent=""></cfif>
				<cfif not isdefined("IssuedToAgent")><cfset IssuedToAgent=""></cfif>
				<cfif not isdefined("ContactAgent")><cfset ContactAgent=""></cfif>
				<cfif not isdefined("issued_by_agent_id")><cfset issued_by_agent_id=""></cfif>
				<cfif not isdefined("issued_to_agent_id")><cfset issued_to_agent_id=""></cfif>
				<cfif not isdefined("contact_agent_id")><cfset contact_agent_id=""></cfif>
				<cfif not isdefined("issued_date")><cfset issued_date=""></cfif>
				<cfif not isdefined("issued_until_date")><cfset issued_until_date=""></cfif>
				<cfif not isdefined("renewed_date")><cfset renewed_date=""></cfif>
				<cfif not isdefined("renewed_until_date")><cfset renewed_until_date=""></cfif>
				<cfif not isdefined("exp_date")><cfset exp_date=""></cfif>
				<cfif not isdefined("exp_until_date")><cfset exp_until_date=""></cfif>
				<cfif not isdefined("permit_type")><cfset permit_type=""></cfif>
				<cfif not isdefined("specific_type")><cfset specific_type=""></cfif>
				<cfif not isdefined("permit_remarks")><cfset permit_remarks=""></cfif>
				<cfif not isdefined("benefits_provided")><cfset benefits_provided=""></cfif>
				<cfif not isdefined("benefits_summary")><cfset benefits_summary=""></cfif>
				<cfif not isdefined("restriction_summary")><cfset restriction_summary=""></cfif>
				<!--- Search Form --->
				<cfoutput>
					<section class="container-fluid" role="search" aria-labelledby="formheading">
						<div class="row mx-0 mb-3">
							<div class="search-box">
								<div class="search-box-header">
									<h1 class="h3 text-white" id="formheading">Find Permissions &amp; Rights Documents</h1>
								</div>
								<div class="col-12 px-4 py-1">
									<p class="my-2 small" tabindex="0">Search for permits and other documents related to permissions and rights (access benefit sharing agreements,
									material transfer agreements, collecting permits, salvage permits, etc.) Any part of names accepted, case is not important.  
									</p>
									<form name="searchForm" id="searchForm"> 
										<input type="hidden" name="method" value="getPermits" class="keeponclear">
										<div class="form-row mb-2">
											<div class="col-md-6">
												<label for="permit_title" class="data-entry-label" id="permit_title_label">Document Title</label>
												<input type="text" id="permit_title" name="permit_title" class="data-entry-input" value="#permit_title#" aria-labelledby="permit_title_label" >
											</div>
											<div class="col-md-6">
												<label for="permit_num" class="data-entry-label" id="permit_num_label">Permit Number</label>
												<input type="text" id="permit_num" name="permit_num" class="data-entry-input" value="#permit_num#" aria-labelledby="permit_num_label" >					
											</div>
										</div>
										<script>
											$(document).ready(function() {
												makePermitTitleAutocomplete("permit_title");	
												makePermitNumberAutocomplete("permit_num");	
											});
										</script>
										<div class="form-row mb-2">
											<div class="col-md-4">
												<label for="IssuedByAgent" class="data-entry-label" id="IssuedByAgent_label">Issued By</label>
												<input type="text" id="IssuedByAgent" name="IssuedByAgent" class="data-entry-input" value="#IssuedByAgent#" aria-labelledby="IssuedByAgent_label" >
												<input type="hidden" id="issued_by_agent_id" name="issued_by_agent_id" value="#issued_by_agent_id#">
											</div>
											<div class="col-md-4">
												<label for="IssuedToAgent" class="data-entry-label" id="IssuedToAgent_label">Issued To</label>
												<input type="text" id="IssuedToAgent" name="IssuedToAgent" class="data-entry-input" value="#IssuedToAgent#" aria-labelledby="IssuedToAgent_label" >
												<input type="hidden" id="issued_to_agent_id" name="issued_to_agent_id" value="#issued_to_agent_id#">
											</div>
											<div class="col-md-4">
												<label for="ContactAgent" class="data-entry-label" id="ContactAgent_label">Contact</label>
												<input type="text" id="ContactAgent" name="ContactAgent" class="data-entry-input" value="#ContactAgent#" aria-labelledby="ContactAgent_label" >
												<input type="hidden" id="contact_agent_id" name="contact_agent_id" value="#contact_agent_id#">
											</div>
											<script>
												$(document).ready(function() {
													makeConstrainedAgentPicker("IssuedByAgent", "issued_by_agent_id","permit_issued_by_agent");
													makeConstrainedAgentPicker("IssuedToAgent", "issued_to_agent_id","permit_issued_to_agent");
													makeConstrainedAgentPicker("ContactAgent", "contact_agent_id","permit_contact_agent");
												});
											</script>
										</div>
										<div class="form-row mb-2">
											<div class="col-12 col-md-4">
												<div class="date form-row border bg-light pb-2 pt-1 rounded mx-0 justify-content-center">
													<label class="data-entry-label mb-0 px-4 mx-1" for="issued_date">Issued Date:</label>
													<input name="issued_date" id="issued_date" type="text" class="datetimeinput data-entry-input col-4" placeholder="start yyyy-mm-dd" value="#issued_date#" aria-label="start of range for closed date">
													<div class="col-1 col-xl-2 text-center px-0"><small> to</small></div>
													<label class="data-entry-label sr-only" for="issued_until_date">end of range for issued date </label>
													<input type='text' name='issued_until_date' id="issued_until_date" value="#issued_until_date#" placeholder="end yyyy-mm-dd" class="datetimeinput data-entry-input col-4">
												</div>
											</div>
											<div class="col-12 col-md-4">
												<div class="date form-row border bg-light pb-2 pt-1 rounded mx-0 justify-content-center">
													<label class="data-entry-label mb-0 px-4 mx-1" for="renewed_date">Renewed Date:</label>
													<input name="renewed_date" id="renewed_date" type="text" class="datetimeinput data-entry-input col-4" placeholder="start yyyy-mm-dd" value="#renewed_date#" aria-label="start of range for closed date">
													<div class="col-1 col-xl-2 text-center px-0"><small> to</small></div>
													<label class="data-entry-label sr-only" for="renewed_until_date">end of range for renewed date </label>
													<input type='text' name='renewed_until_date' id="renewed_until_date" value="#renewed_until_date#" placeholder="end yyyy-mm-dd" class="datetimeinput data-entry-input col-4">
												</div>
											</div>
											<div class="col-12 col-md-4">
												<div class="date form-row border bg-light pb-2 pt-1 rounded mx-0 justify-content-center">
													<label class="data-entry-label mb-0 px-4 mx-1" for="exp_date">Expiration Date:</label>
													<input name="exp_date" id="exp_date" type="text" class="datetimeinput data-entry-input col-4" placeholder="start yyyy-mm-dd" value="#exp_date#" aria-label="start of range for closed date">
													<div class="col-1 col-xl-2 text-center px-0"><small> to</small></div>
													<label class="data-entry-label sr-only" for="exp_until_date">end of range for expiration date </label>
													<input type='text' name='exp_until_date' id="exp_until_date" value="#exp_until_date#" placeholder="end yyyy-mm-dd" class="datetimeinput data-entry-input col-4">
												</div>
											</div>
											<script>
												/* Setup date time input controls */
												$(".datetimeinput").datepicker({ 
													defaultDate: null,
													changeMonth: true,
													changeYear: true,
													dateFormat: 'yy-mm-dd', /* ISO Date format, yy is 4 digit year */
													buttonImageOnly: true,
													buttonImage: "/shared/images/calendar_icon.png",
													showOn: "both"
												});
											</script>
										</div>
	
										<div class="form-row mb-2">
											<div class="col-md-4">
												<cfset ppermit_type = permit_type>
												<label for="permit_type" class="data-entry-label mb-0">Document Category:</label>
												<select name="permit_type" id="permit_type" class="data-entry-select">
													<option value=""></option>
													<cfloop query="ctPermitType">
														<cfif ppermit_type eq ctPermitType.permit_type>
															<cfset selected="selected">
															<cfelse>
															<cfset selected="">
														</cfif>
														<option value="#ctPermitType.permit_type#" #selected#>#ctPermitType.permit_type# (#ctPermitType.uses#)</option>
													</cfloop>
												</select>
											</div>
											<div class="col-md-4">
												<cfset pspecific_type = specific_type>
												<label for="specific_type" class="data-entry-label mb-0">Specific Document Type:</label>
												<select name="specific_type" id="specific_type" class="data-entry-select">
													<option value=""></option>
													<cfloop query="ctSpecificPermitType">
														<cfif pspecific_type eq ctSpecificPermitType.specific_type>
															<cfset selected="selected">
															<cfelse>
															<cfset selected="">
														</cfif>
														<option value="#ctSpecificPermitType.specific_type#" #selected#>#ctSpecificPermitType.specific_type# (#ctSpecificPermitType.uses#)</option>
													</cfloop>
												</select>
											</div>
											<div class="col-md-4">
												<label for="permit_remarks" class="data-entry-label" id="permit_remarks_label">Remarks:</label>
												<input type="text" id="permit_remarks" name="permit_remarks" class="data-entry-input" value="#permit_remarks#" aria-labelledby="permit_remarks_label" >					
											</div>
											<div class="col-md-4">
												<label for="restriction_summary" class="data-entry-label" id="restriction_summary_label">
													Summary of Restrictions on Use
													<span class="small">(
													<a href="javascript:void(0)" tabindex="-1" aria-hidden="true" class="btn-link" onclick="$('##restriction_summary').val('NULL'); return false;" >NULL<span class="sr-only">use NULL to find permissions and rights documents with no values in restrictions on use</span></a>
													,
													<a href="javascript:void(0)" tabindex="-1" aria-hidden="true" class="btn-link" onclick="$('##restriction_summary').val('NOT NULL'); return false;" >NOT NULL<span class="sr-only">use NOT NULL to find permissions and rights documents with any restrictions on use</span></a>
													)</span>
												</label>
												<input type="text" id="restriction_summary" name="restriction_summary" class="data-entry-input" value="#restriction_summary#" aria-labelledby="restriction_summary_label" >					
											</div>
											<div class="col-md-4">
												<label for="benefits_summary" class="data-entry-label" id="benefits_summary_label">
													Summary of Agreed Benefits
													<span class="small">(
													<a href="javascript:void(0)" tabindex="-1" aria-hidden="true" class="btn-link" onclick="$('##benefits_summary').val('NULL'); return false;" >NULL<span class="sr-only">use NULL to find permissions and rights documents with no values in agreed benefits</span></a>
													,
													<a href="javascript:void(0)" tabindex="-1" aria-hidden="true" class="btn-link" onclick="$('##benefits_summary').val('NOT NULL'); return false;" >NOT NULL<span class="sr-only">use NOT NULL to find permissions and rights documents with any agreed benefits</span></a>
													)</span>
												</label>
												<input type="text" id="benefits_summary" name="benefits_summary" class="data-entry-input" value="#benefits_summary#" aria-labelledby="benefits_summary_label" >					
											</div>
											<div class="col-md-4">
												<label for="benefits_provided" class="data-entry-label" id="benefits_provided_label">
													Benefits Provided
													<span class="small">(
													<a href="javascript:void(0)" tabindex="-1" aria-hidden="true" class="btn-link" onclick="$('##benefits_provided').val('NULL'); return false;" >NULL<span class="sr-only">use NULL to find permissions and rights documents with no benefits provided</span></a>
													,
													<a href="javascript:void(0)" tabindex="-1" aria-hidden="true" class="btn-link" onclick="$('##benefits_provided').val('NOT NULL'); return false;" >NOT NULL<span class="sr-only">use NOT NULL to find permissions and rights documents with any benefits provided</span></a>
													)</span>
												</label>
												<input type="text" id="benefits_provided" name="benefits_provided" class="data-entry-input" value="#benefits_provided#" aria-labelledby="benefits_provided_label" >					
											</div>
										</div>
										<div class="form-row my-2 mx-0">
											<div class="col-12 px-0">
												<button class="btn-xs btn-primary px-2 mt-2" id="permitSearchButton" type="submit" aria-label="Search permits">Search<span class="fa fa-search pl-1"></span></button>
												<button type="reset" class="btn-xs btn-warning mt-2" aria-label="Reset search form to inital values" onclick="">Reset</button>
												<button type="button" class="btn-xs btn-warning mt-2" aria-label="Start a permit search with a clear form" onclick="window.location.href='#Application.serverRootUrl#/transactions/Permit.cfm?action=search';" >New Search</button>
												<a class="btn-xs btn-secondary my-2 text-decoration-none" aria-label="Create a new permissions and rights record" href="/transactions/Permit.cfm?action=new">Create New Permissions&amp;Rights</a>
											</div>
										</div>
									</form>
								</div>
							</div>
						</div>
					</section>
				</cfoutput>
		
				<!--- Results table as a jqxGrid. --->
				<div class="container-fluid">
					<div class="row mx-0">
						<div class="col-12 mb-5">
							<section>
								<div class="row mt-1 mb-0 pb-0 jqx-widget-header border px-2">
									<h1 class="h4 pt-2 ml-2 ml-md-1 mt-1">Results: 
										<span class="pr-2 font-weight-normal" id="resultCount"></span> 
										<span id="resultLink" class="pr-2 font-weight-normal"></span>
									</h1>
									
									<div id="saveDialogButton" class=""></div>
									<div id="saveDialog"></div>
									<div id="columnPickDialog">
										<div id="columnPick" class="px-1"></div>
									</div>
									<div id="columnPickDialogButton"></div>
									<div id="resultDownloadButtonContainer"></div>
									<div id="selectModeContainer" class="ml-3" style="display: none;" >
										<cfoutput>
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
										</cfoutput>
									</div>
									<output id="actionFeedback" class="btn btn-xs btn-transparent my-2 pt-1 px-2 mx-1 border-0"></output>
								</div>
								<div class="row mt-0">
									<!--- Grid Related code is below along with search handlers --->
									<div id="searchResultsGrid" class="jqxGrid" role="table" aria-label="Search Results Table"></div>
									<div id="enableselection"></div>
								</div>
							</section>
						</div>
					</div>
				</div>
			</main>
		
			<cfoutput>
				<cfset cellRenderClasses = "ml-1"><!--- for cell renderers to match default --->
				<script>

					window.columnHiddenSettings = new Object();
					<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
						lookupColumnVisibilities ('#cgi.script_name#','Default');
					</cfif>

					/* Supporting cell renderers for Permit Search *****************************/
					var pdfCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
						var rowData = jQuery("##searchResultsGrid").jqxGrid('getrowdata',row);
						var result = "";
						var pid = rowData['pdf'];
						if (pid) {
							result = '<span class="#cellRenderClasses#" style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; "><a href="'+pid+'" target="_blank">'+value.split('/').pop()+'</a></span>';
						} else { 
							result = '<span class="#cellRenderClasses#" style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; ">'+value+'</span>';
						}
						return result;
					};

					/* Permit Search */
					$(document).ready(function() {
						/* Setup jqxgrid for Search */
						$('##searchForm').bind('submit', function(evt){
							evt.preventDefault();
					
							$("##overlay").show();
					
							$("##searchResultsGrid").replaceWith('<div id="searchResultsGrid" class="jqxGrid" style="z-index: 1;"></div>');
							$('##resultCount').html('');
							$('##resultLink').html('');
							$('##saveDialogButton').html('');
							$('##selectModeContainer').hide();
					
							var search =
							{
								datatype: "json",
								datafields:
								[
									{ name: 'permit_id', type: 'string' },
									{ name: 'permit_num', type: 'string' },
									{ name: 'issuedbyagent', type: 'string' },
									{ name: 'issuedtoagent', type: 'string' },
									{ name: 'contactagent', type: 'string' },
									{ name: 'issued_date', type: 'string' },
									{ name: 'renewed_date', type: 'string' },
									{ name: 'exp_date', type: 'string' },
									{ name: 'permit_type', type: 'string' },
									{ name: 'specific_type', type: 'string' },
									{ name: 'permit_title', type: 'string' },
									{ name: 'permit_remarks', type: 'string' },
									{ name: 'pdf', type: 'string' },
									{ name: 'id_link', type: 'string' }
								],
								updaterow: function (rowid, rowdata, commit) {
									commit(true);
								},
								root: 'permitsRecord',
								id: 'permit_id',
								url: '/transactions/component/search.cfc?' + $('##searchForm').serialize(),
								timeout: #Application.ajax_timeout#000,  // units not specified, miliseconds? 
								loadError: function(jqXHR, status, error) { 
									$("##overlay").hide();
								var message = "";      
									if (error == 'timeout') { 
									message = ' Server took too long to respond.';
								} else { 
								message = jqXHR.responseText;
								}
								messageDialog('Error:' + message ,'Error: ' + error.substring(0,50));
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
									{text: 'Permit ID', datafield: 'permit_id', width:100, hideable: true, hidden: getColHidProp('permit_id', true) },
									{text: 'Link', datafield: 'id_link', width: 150},
									{text: 'Title', datafield: 'permit_title', width:150, hideable: true, hidden: getColHidProp('permit_title', false) },
									{text: 'Number', datafield: 'permit_num', width:150, hideable: true, hidden: getColHidProp('permit_num', false) },
									{text: 'Issued', datafield: 'issued_date', width:110, hideable: true, hidden: getColHidProp('issued_date', false) },
									{text: 'Category', datafield: 'permit_type', width:200, hideable: true, hidden: getColHidProp('permit_type', false) },
									{text: 'Specific Type', datafield: 'specific_type', width:200, hideable: true, hidden: getColHidProp('specific_type', false) },
									{text: 'Issued By', datafield: 'issuedbyagent', width:100, hideable: true, hidden: getColHidProp('issuedbyagent', false) },
									{text: 'Issued To', datafield: 'issuedtoagent', width:100, hideable: true, hidden: getColHidProp('issuedtoagent', false) },
									{text: 'Contact', datafield: 'contactagent', width:100, hideable: true, hidden: getColHidProp('contactagent', true) },
									{text: 'Renewed', datafield: 'renewed_date', width:80, hideable: true, hidden: getColHidProp('renewed_date', true) },
									{text: 'Expires', datafield: 'exp_date', width:80, hideable: true, hidden: getColHidProp('exp_date', true) },
									{text: 'PDF', datafield: 'pdf', width:200, hideable: true, hidden: getColHidProp('pdf', true), cellsrenderer: pdfCellRenderer},
									{text: 'Remarks', datafield: 'permit_remarks', hideable: true, hidden: getColHidProp('permit_remarks', false) }
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
								$('##resultLink').html('<a href="/transactions/Permit.cfm?action=search&execute=true&' + $('##searchForm :input').filter(function(index,element){return $(element).val()!='';}).serialize() + '">Link to this search</a>');
								gridLoaded('searchResultsGrid','permission and rights document');
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
						/* End Setup jqxgrid for number series Search ******************************/
		
						// If requested in uri, execute search immediately.
						<cfif isdefined("execute")>
							$('##searchForm').submit();
						</cfif>
					}); /* End document.ready */
	

					<cfif isdefined("session.roles") AND listfindnocase(session.roles,"coldfusion_user") >
					function populateSaveSearch() { 
						// set up a dialog for saving the current search.
						var uri = "/transactions/Permit.cfm?execute=true&" + $('##searchForm :input').filter(function(index,element){ return $(element).val()!='';}).not(".excludeFromLink").serialize();
						$("##saveDialog").html(
							"<div class='row'>"+ 
							"<form id='saveForm'> " + 
							" <input type='hidden' value='"+uri+"' name='url'>" + 
							" <div class='col-12'>" + 
							"  <label for='search_name_input'>Search Name</label>" + 
							"  <input type='text' id='search_name_input'  name='search_name' value='' class='data-entry-input reqdClr' placeholder='Your name for this search' maxlength='60' required>" + 
							" </div>" + 
							" <div class='col-12'>" + 
							"  <label for='execute_input'>Execute Immediately</label>"+
							"  <input id='execute_input' type='checkbox' name='execute' checked>"+
							" </div>" +
							"</form>"+
							"</div>"
						);
					}
					</cfif>

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
						   $('##' + gridId).jqxGrid({ pagesizeoptions: ['5','50', '100', rowcount], pagesize: 50});
						} else if (rowcount > 50) { 
						   $('##' + gridId).jqxGrid({ pagesizeoptions: ['5','50', rowcount], pagesize: 50});
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
							"<button id='columnPickDialogOpener' onclick=\" $('##columnPickDialog').dialog('open'); \" class='btn btn-xs btn-secondary px-2 my-2 mx-1' >Show/Hide Columns</button>"
						);

						<cfif isdefined("session.roles") AND listfindnocase(session.roles,"coldfusion_user") >
							$("##saveDialog").dialog({
								height: 'auto',
								width: 'auto',
								adaptivewidth: true,
								title: 'Save Search',
								autoOpen: false,
								modal: true,
								reszable: true,
								buttons: [
									{
										text: "Save",
										click: function(){
											var url = $('##saveForm :input[name=url]').val();
											var execute = $('##saveForm :input[name=execute]').is(':checked');
											var search_name = $('##saveForm :input[name=search_name]').val();
											saveSearch(url, execute, search_name,"actionFeedback");
											$(this).dialog("close"); 
										},
										tabindex: 0
									},
									{
										text: "Cancel",
										click: function(){ 
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
							$("##saveDialogButton").html(
							`<button id="`+gridId+`saveDialogOpener"
									onclick=" populateSaveSearch(); $('##saveDialog').dialog('open'); " 
									class="btn btn-xs btn-secondary my-2 px-2 mx-1" >Save Search</button>
							`);
						</cfif>

						// workaround for menu z-index being below grid cell z-index when grid is created by a loan search.
						// likewise for the popup menu for searching/filtering columns, ends up below the grid cells.
						var maxZIndex = getMaxZIndex();
						$('.jqx-grid-cell').css({'z-index': maxZIndex + 1});
						$('.jqx-grid-group-cell').css({'z-index': maxZIndex + 1});
						$('.jqx-menu-wrapper').css({'z-index': maxZIndex + 2});
						$('##resultDownloadButtonContainer').html('<button id="permitcsvbutton" class="btn btn-xs btn-secondary px-2 my-2 mx-1" aria-label="Export results to csv" onclick=" exportGridToCSV(\'searchResultsGrid\', \''+filename+'\'); " >Export to CSV</button>');
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
	<!--------------------------------------------------------------------------->
	<cfcase value="new">
		<cfoutput>
			<script>
				jQuery(document).ready(function() {
					$("##issued_date").datepicker({ dateFormat: 'yy-mm-dd'});
					$("##renewed_date").datepicker({ dateFormat: 'yy-mm-dd'});
					$("##exp_date").datepicker({ dateFormat: 'yy-mm-dd'});
				});
			</script>
			<main class="container py-3" id="content">
				<h1 class="h2 ml-3" target="0" id="newPermitFormSectionLabel" >
					Create New Permissions &amp; Rights Document 
					<i class="fas fas-info fa-info-circle" onClick="getMCZDocs('Permit##Create_a_Permissions_and_Rights_.28Permit.29_record')" aria-label="help link"></i>
				</h1>
				<p class="ml-3" target="0">
					Enter a new record for a permit or similar document related to permissions and rights (access benefit sharing agreements,
					material transfer agreements, collecting permits, salvage permits, etc.)
				</p>
				<section class="col-12 border rounded mb-5 bg-white pt-3" id="newPermitFormSection" class="row" aria-labeledby="newPermitFormSectionLabel" >
					<form name="newPermitForm" id="newPermitForm" action="/transactions/Permit.cfm" method="post" onSubmit="return noenter();">
						<input type="hidden" name="action" value="create">
								<cfif isdefined("headless") and headless EQ 'true'>
									<input type="hidden" name="headless" value="true">
								</cfif>
						<div class="form-row mb-2">
							<div class="col-12 col-md-4">
								<span>
									<label for="issued_by_agent_name" class="data-entry-label">
										Issued By:
										<span id="issued_by_agent_view">&nbsp;&nbsp;&nbsp;&nbsp;</span>
									</label>
								</span>
								<div class="input-group">
									<div class="input-group-prepend">
										<span class="input-group-text smaller" id="issued_by_agent_icon"><i class="fa fa-user" aria-hidden="true"></i></span> 
									</div>
									<input  name="issued_by_agent_name" id="issued_by_agent_name" class="reqdClr form-control data-entry-input data-height" required >
								</div>
								<input type="hidden" name="issued_by_agent_id" id="issued_by_agent_id" >
								<script>
									$(makeRichTransAgentPicker('issued_by_agent_name','issued_by_agent_id','issued_by_agent_icon','issued_by_agent_view',null));
								</script> 
							</div>
							<div class="col-12 col-md-4">
								<span>
									<label for="issued_to_agent_name" class="data-entry-label">
										Issued To:
										<span id="issued_to_agent_view">&nbsp;&nbsp;&nbsp;&nbsp;</span>
									</label>
								</span>
								<div class="input-group">
									<div class="input-group-prepend">
										<span class="input-group-text smaller" id="issued_to_agent_icon"><i class="fa fa-user" aria-hidden="true"></i></span> 
									</div>
									<input  name="issued_to_agent_name" id="issued_to_agent_name" class="reqdClr form-control data-entry-input data-height" required >
								</div>
								<input type="hidden" name="issued_to_agent_id" id="issued_to_agent_id" >
								<script>
									$(makeRichTransAgentPicker('issued_to_agent_name','issued_to_agent_id','issued_to_agent_icon','issued_to_agent_view',null));
								</script> 
							</div>
							<div class="col-12 col-md-4">
								<span>
									<label for="contact_agent_name" class="data-entry-label">
										Contact Person:
										<span id="contact_agent_view">&nbsp;&nbsp;&nbsp;&nbsp;</span>
									</label>
								</span>
								<div class="input-group">
									<div class="input-group-prepend">
										<span class="input-group-text smaller" id="contact_agent_icon"><i class="fa fa-user" aria-hidden="true"></i></span> 
									</div>
									<input  name="contact_agent_name" id="contact_agent_name" class="form-control data-entry-input data-height">
								</div>
								<input type="hidden" name="contact_agent_id" id="contact_agent_id" >
								<script>
									$(makeRichTransAgentPicker('contact_agent_name','contact_agent_id','contact_agent_icon','contact_agent_view',null));
								</script> 
							</div>
						</div>
						<div class="form-row mb-2">
							<div class="col-12 col-md-4">
								<label for="issued_date" class="data-entry-label">Issued Date</label>
								<input type="text" id="issued_date" name="issued_date" class="data-entry-input" value="">
							</div>
							<div class="col-12 col-md-4">
								<label for="renewed_date" class="data-entry-label">Renewed Date</label>
								<input type="text" id="renewed_date" name="renewed_date" class="data-entry-input" value="">
							</div>
							<div class="col-12 col-md-4">
								<label for="exp_date" class="data-entry-label">Expiration Date</label>
								<input type="text" id="exp_date" name="exp_date" class="data-entry-input" value="">
							</div>
						</div>
						<div class="form-row mb-2">
							<div class="col-12 col-md-6">
								<label for="permit_num" class="data-entry-label">Permit Number</label>
								<input type="text" name="permit_num" id="permit_num" class="data-entry-input">
							</div>
							<div class="col-12 col-md-6">
								<label for="permit_title" class="data-entry-label">Document Title</label>
								<input type="text" name="permit_title" id="permit_title" class="data-entry-input">
							</div>
						</div>
						<div class="form-row mb-2">
							<div class="col-12 col-md-6">
								<label for="specific_type" class="data-entry-label">Specific Document Type</label>
							<select name="specific_type" id="specific_type" size="1" class="reqdClr data-entry-select" required>
									<option value=""></option>
									<cfloop query="ctSpecificPermitType">
										<option value = "#ctSpecificPermitType.specific_type#">#ctSpecificPermitType.specific_type# (#ctSpecificPermitType.permit_type#)</option>
									</cfloop>
								</select>
								<cfif isdefined("session.roles") and listfindnocase(session.roles,"admin_permits")>
									<button id="addSpecificTypeButton" class="btn-light rounded btn btn-xs" onclick="openAddSpecificTypeDialog(); event.preventDefault();">+</button>
									<div id="newPermitASTDialog"></div>
								</cfif>
							</div>
							<div class="col-12 col-md-6">
								<label for="permit_remarks" class="data-entry-label">Remarks</label>
								<input type="text" name="permit_remarks" id="permit_remarks" class="data-entry-input" maxlength="300">
							</div>
						</div>
						<div class="form-row mb-2">
							<div class="col-12">
								<label for="restriction_summary" class="data-entry-label">Summary of Restrictions on Use (<span id="length_restriction_summary"></span>)</label>
								<textarea rows="1" name="restriction_summary" id="restriction_summary" 
									onkeyup="countCharsLeft('restriction_summary', 4000, 'length_restriction_summary');"
									class="autogrow border rounded w-100"></textarea>
							</div>
						</div>
						<div class="form-row mb-2">
							<div class="col-12">
								<label for="benefits_summary" class="data-entry-label">Summary of Agreed Benefits (<span id="length_benefits_summary"></span>)</label>
								<textarea rows="1" name="benefits_summary" id="benefits_summary" 
									onkeyup="countCharsLeft('benefits_summary', 4000, 'length_benefits_summary');"
									class="autogrow border rounded w-100"></textarea>
							</div>
						</div>
						<div class="form-row mb-2">
							<div class="col-12">
								<label for="benefits_provided" class="data-entry-label">Benefits Provided (<span id="length_benefits_provided"></span>)</label>
								<textarea rows="1" name="benefits_provided" id="benefits_provided" 
									onkeyup="countCharsLeft('benefits_provided', 4000, 'length_benefits_provided');"
									class="autogrow border rounded w-100"></textarea>
							</div>
						</div>
						<div class="form-row mb-1">
							<div class="form-group col-12">
								<input type="button" value="Create" class="btn btn-xs btn-primary"
									onClick="if (checkFormValidity($('##newPermitForm')[0])) { submit();  } " 
									id="submitButton" >
							</div>
						</div>
					</form>
					<script>
						// make selected textareas autogrow as text is entered.
						$(document).ready(function() {
							// bind the autogrow function to the keyup event
							$('textarea.autogrow').keyup(autogrow);
							// trigger keyup event to size textareas to existing text
							$('textarea.autogrow').keyup();
						});
					</script> 
				</section>
			</main>
		</cfoutput>
	</cfcase>
	<!--------------------------------------------------------------------------------------------------->
	<cfcase value="delete">
		<cfoutput>
			<cftry>
				<cfif NOT isdefined("permit_id") or len(permit_id) EQ 0 >
					<cfthrow message="No permit_id provided to delete">
				</cfif>
				<!--- FK constraints will prevent deletion of a permit if a parent permit has children or a permit is in a permit_trans or permit_shipment relationship --->
				<cfquery name="deletePermit" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					DELETE FROM permit 
					WHERE permit_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#permit_id#">
				</cfquery>
				<section class="container">
					<h1 class="h2">Permission and Rights Document deleted.....</h1>
					<ul>
						<li><a href="/transactions/Permit.cfm?action=search">Search for Permissions and Rights Documents</a>.</li>
						<li><a href="/transactions/Permit.cfm?action=new">Create a New Permissions and Rights Document</a>.</li>
					</ul>
				</section>
			<cfcatch>
				<section class="container">
					<div class="row">
						<div class="alert alert-danger" role="alert">
							<img src="/shared/images/Process-stop.png" alt="[ Error ]" style="float:left; width: 50px;margin-right: 1em;">
							<h1 class="h2">Delete Failed</h1>
							<p>Permissions and Rights records cannot be deleted if they are used in a shipment, in a transaction, have attached media, or have child permits.</p>
							<p>#cfcatch.message#</p>
							<p><a href="/info/bugs.cfm">“Feedback/Report Errors”</a></p>
						</div>
					</div>
					<p><cfdump var=#cfcatch#></p>
				</section>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfcase>
	<!--------------------------------------------------------------------------------------------------->
	<cfcase value="edit">
		<cfif not isdefined("permit_id") OR len(#permit_id#) is 0>
			<cfthrow message="Error: Unable to edit a permissions and rights document without a permit_id">
		</cfif>
		<cfquery name="permitInfo" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select distinct
				permit.permit_id,
				issuedBy.agent_name as IssuedByAgent,
				issuedBy.agent_id as IssuedByAgentID,
				issuedTo.agent_name as IssuedToAgent,
				issuedTo.agent_id as IssuedToAgentID,
				contact_agent_id,
				contact.agent_name as ContactAgent,
				issued_Date,
				renewed_Date,
				exp_Date,
				restriction_summary,
				benefits_summary,
				benefits_provided,
				permit_num,
				permit_Type,
				specific_type,
				permit_title,
				permit_remarks
			from
				permit left join preferred_agent_name issuedTo on permit.issued_to_agent_id = issuedTo.agent_id
				left join preferred_agent_name issuedBy on permit.issued_by_agent_id = issuedBy.agent_id
				left join preferred_agent_name contact on permit.contact_agent_id = contact.agent_id
			where
				permit_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#permit_id#">
			order by permit_id
		</cfquery>
		<cfoutput query="permitInfo" group="permit_id">
			<script>
				jQuery(document).ready(function() {
					$("##issued_date").datepicker({ dateFormat: 'yy-mm-dd'});
					$("##renewed_date").datepicker({ dateFormat: 'yy-mm-dd'});
					$("##exp_date").datepicker({ dateFormat: 'yy-mm-dd'});
				});
			</script>
			<main class="container pt-2 pb-5">
				<h1 class="h2 wikilink my-2 ml-3" id="editPermitFormSectionLabel" >
					Edit Permissions &amp; Rights Document 
					<i class="fas fas-info fa-info-circle" onClick="getMCZDocs('Permit##Create_a_Permissions_and_Rights_.28Permit.29_record')" aria-label="help link"></i>
				</h1>
				<section id="editPermitFormSection" class="row mx-0 border rounded mt-2" aria-labeledby="editPermitFormSectionLabel" >
					<form name="editPermitForm" id="editPermitForm" action="/transactions/Permit.cfm" method="post" class="col-12 px-3">
						<input type="hidden" name="method" value="savePermit">
						<input type="hidden" name="permit_id" id="permit_id" value="#permit_id#">
						<!--- make permit number available as a element with a distinct id to grab with jquery --->
						<input type="hidden" name="permit_number_passon" id="permit_number_passon" value="#permit_num#">
						<cfif isdefined("headless") and headless EQ 'true'>
							<input type="hidden" name="headless" value="true">
						</cfif>
						<div class="form-row my-2 pt-2">
							<div class="col-12 col-md-4">
								<span>
									<label for="issued_by_agent_name" class="data-entry-label">
										Issued By:
										<span id="issued_by_agent_view">&nbsp;&nbsp;&nbsp;&nbsp;</span>
									</label>
								</span>
								<div class="input-group">
									<div class="input-group-prepend">
										<span class="input-group-text smaller" id="issued_by_agent_icon"><i class="fa fa-user" aria-hidden="true"></i></span> 
									</div>
									<input name="issued_by_agent_name" id="issued_by_agent_name" class="reqdClr form-control form-control-sm data-entry-input" required value="#IssuedByAgent#" >
								</div>
								<input type="hidden" name="issued_by_agent_id" id="issued_by_agent_id" value="#IssuedByAgentID#" >
								<script>
									$(makeRichTransAgentPicker('issued_by_agent_name','issued_by_agent_id','issued_by_agent_icon','issued_by_agent_view',#IssuedByAgentId#));
								</script> 
							</div>
							<div class="col-12 col-md-4">
								<span>
									<label for="issued_to_agent_name" class="data-entry-label">
										Issued To:
										<span id="issued_to_agent_view">&nbsp;&nbsp;&nbsp;&nbsp;</span>
									</label>
								</span>
								<div class="input-group">
									<div class="input-group-prepend">
										<span class="input-group-text smaller" id="issued_to_agent_icon"><i class="fa fa-user" aria-hidden="true"></i></span> 
									</div>
									<input name="issued_to_agent_name" id="issued_to_agent_name" class="reqdClr form-control form-control-sm data-entry-input" required value="#IssuedToAgent#" >
								</div>
								<input type="hidden" name="issued_to_agent_id" id="issued_to_agent_id" value="#IssuedToAgentID#" >
								<script>
									$(makeRichTransAgentPicker('issued_to_agent_name','issued_to_agent_id','issued_to_agent_icon','issued_to_agent_view',#IssuedToAgentID#));
								</script> 
							</div>
							<div class="col-12 col-md-4">
								<span>
									<label for="contact_agent_name" class="data-entry-label">
										Contact Person:
										<span id="contact_agent_view">&nbsp;&nbsp;&nbsp;&nbsp;</span>
									</label>
								</span>
								<div class="input-group">
									<div class="input-group-prepend">
										<span class="input-group-text smaller" id="contact_agent_icon"><i class="fa fa-user" aria-hidden="true"></i></span> 
									</div>
									<input name="contact_agent_name" id="contact_agent_name" class="form-control form-control-sm data-entry-input" value="#ContactAgent#">
								</div>
								<input type="hidden" name="contact_agent_id" id="contact_agent_id" value="#contact_agent_id#" >
								<script>
									$(makeRichTransAgentPicker('contact_agent_name','contact_agent_id','contact_agent_icon','contact_agent_view',#contact_agent_id#));
								</script> 
							</div>
						</div>
						<div class="form-row mb-2">
							<div class="col-12 col-md-4">
								<label for="issued_date" class="data-entry-label">Issued Date</label>
								<input type="text" id="issued_date" name="issued_date" class="data-entry-input" value="#dateformat(issued_date,"yyyy-mm-dd")#">
							</div>
							<div class="col-12 col-md-4">
								<label for="renewed_date" class="data-entry-label">Renewed Date</label>
								<input type="text" id="renewed_date" name="renewed_date" class="data-entry-input" value="#dateformat(renewed_date,"yyyy-mm-dd")#">
							</div>
							<div class="col-12 col-md-4">
								<label for="exp_date" class="data-entry-label">Expiration Date</label>
								<input type="text" id="exp_date" name="exp_date" class="data-entry-input" value="#dateformat(exp_date,"yyyy-mm-dd")#">
							</div>
						</div>
						<div class="form-row mb-2">
							<div class="col-12 col-md-6">
								<label for="permit_num" class="data-entry-label">Permit Number</label>
								<input type="text" name="permit_num" id="permit_num" class="data-entry-input" value="#permit_num#">
							</div>
							<div class="col-12 col-md-6">
								<label for="permit_title" class="data-entry-label">Document Title</label>
								<input type="text" name="permit_title" id="permit_title" class="data-entry-input" value="#permit_title#">
							</div>
						</div>
						<div class="form-row mb-2">
							<div class="col-12 col-md-6">
								<label for="specific_type" class="data-entry-label">Specific Document Type</label>
								<select name="specific_type" id="specific_type" size="1" class="reqdClr data-entry-select">
									<option value=""></option>
									<cfloop query="ctSpecificPermitType">
										<cfif permitInfo.specific_type IS ctSpecificPermitType.specific_type>
											<cfset selected=' selected="true" '>
										<cfelse>
											<cfset selected=''>
										</cfif>
										<option #selected# value = "#ctSpecificPermitType.specific_type#">#ctSpecificPermitType.specific_type# (#ctSpecificPermitType.permit_type#)</option>
									</cfloop>
								</select>
								<cfif isdefined("session.roles") and listfindnocase(session.roles,"admin_permits")>
									<button id="addSpecificTypeButton" class="btn-light rounded btn btn-xs" onclick="openAddSpecificTypeDialog(); event.preventDefault();">+</button>
									<div id="newPermitASTDialog"></div>
								</cfif>
							</div>
							<div class="col-12 col-md-6">
								<label for="permit_remarks" class="data-entry-label">Remarks</label>
								<input type="text" name="permit_remarks" id="permit_remarks" class="data-entry-input" maxlength="300" value="#permit_remarks#">
							</div>
						</div>
						<div class="form-row mb-2">
							<div class="col-12">
								<label for="restriction_summary" class="data-entry-label">Summary of Restrictions on Use (<span id="length_restriction_summary"></span>)</label>
								<textarea rows="1" name="restriction_summary" id="restriction_summary" 
									onkeyup="countCharsLeft('restriction_summary', 4000, 'length_restriction_summary');"
									class="autogrow border rounded w-100">#restriction_summary#</textarea>
							</div>
						</div>
						<div class="form-row mb-2">
							<div class="col-12">
								<label for="benefits_summary" class="data-entry-label">Summary of Agreed Benefits (<span id="length_benefits_summary"></span>)</label>
								<textarea rows="1" name="benefits_summary" id="benefits_summary" 
									onkeyup="countCharsLeft('benefits_summary', 4000, 'length_benefits_summary');"
									class="autogrow border rounded w-100">#benefits_summary#</textarea>
							</div>
						</div>
						<div class="form-row mb-2">
							<div class="col-12">
								<label for="benefits_provided" class="data-entry-label">Benefits Provided (<span id="length_benefits_provided"></span>)</label>
								<textarea rows="1" name="benefits_provided" id="benefits_provided" 
									onkeyup="countCharsLeft('benefits_provided', 4000, 'length_benefits_provided');"
									class="autogrow border rounded w-100">#benefits_provided#</textarea>
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
							function handleChange(){
								$('##saveResultDiv').html('Unsaved changes.');
								$('##saveResultDiv').addClass('text-danger');
								$('##saveResultDiv').removeClass('text-success');
								$('##saveResultDiv').removeClass('text-warning');
							};
						</script> 
						<div class="form-row mb-1">
							<div class="form-group col-12">
								<input type="button" value="Save" class="btn btn-xs btn-primary"
									onClick="if (checkFormValidity($('##editPermitForm')[0])) { saveChanges();  } " 
									id="submitButton" >
								<script>
									function saveChanges(){ 
										$('##saveResultDiv').html('Saving....');
										$('##saveResultDiv').addClass('text-warning');
										$('##saveResultDiv').removeClass('text-success');
										$('##saveResultDiv').removeClass('text-danger');
										jQuery.ajax({
											url : "/transactions/component/functions.cfc",
											type : "post",
											dataType : "json",
											data : $('##editPermitForm').serialize(),
											success : function (data) {
												$('##saveResultDiv').html('Saved.');
												$('##saveResultDiv').addClass('text-success');
												$('##saveResultDiv').removeClass('text-danger');
												$('##saveResultDiv').removeClass('text-warning');
											},
											error: function(jqXHR,textStatus,error){
												$('##saveResultDiv').html('Error.');
												$('##saveResultDiv').addClass('text-danger');
												$('##saveResultDiv').removeClass('text-success');
												$('##saveResultDiv').removeClass('text-warning');
												handleFail(jqXHR,textStatus,error,'saving permit record');
											}
										});
									};
								</script>
								<output id="saveResultDiv" class="text-danger">&nbsp;</output>	
								<!--- TODO: Refactor/fix/remove Headless use --->
								<cfif isdefined("headless") and headless EQ 'true' >
									<strong>Permit Added.  Click OK when done.</strong>
								</cfif>
								<script>
									function submitDeletePermit() { 
										$('##deletePermitForm').submit();
									};
								</script>
								<input type="button" value="Delete" class="btn btn-xs btn-danger float-right"
									onClick=" confirmDialog('Delete this permissions and rights document record?','Confirm Delete Permit', submitDeletePermit ); ">
							</div>
						</div>
						<script>
							$(document).ready(function() {
								monitorForChanges('editPermitForm',handleChange);
							});
						</script>
					</form>
					<form id="deletePermitForm" action="/transactions/Permit.cfm" method="POST">
						<input type="hidden" name="action" value="delete">
						<input type="hidden" name="permit_id" value="#permit_id#">
					</form>
				</section>
				<div class="col-12 mt-3 mb-4 border rounded px-2 pb-2 bg-grayish">
					<section name="permitMediaSection" class="row mx-0 bg-light border pb-2 rounded my-2">
						<div class="col-12">
							<!---  Show/add media copy of permit  (shows permit) --->
							<div id="copyofpermit"><img src='images/indicator.gif'></div>
						</div>
					</section>
					<section name="associatedMediaSection" class="row mx-0 bg-light border pb-2 rounded my-2">
						<div class="col-12 pb-2">
							<!---  list/add media copy of associated documents (document for permit) --->
							<div id="associateddocuments"><img src='images/indicator.gif'></div>
						</div>
					</section>
					<script>
						function addMediaHere(targetid,title,permitLabel,permit_id,relationship){
							var url = '/media.cfm?action=newMedia&relationship='+relationship+'&related_value='+permitLabel+'&related_id='+permit_id ;
							var amddialog = $('##'+targetid)
							.html('<iframe style="border: 0px; " src="'+url+'" width="100%" height="100%" id="mediaIframe"></iframe>')
							.dialog({
								title: title,
								autoOpen: false,
								dialogClass: 'dialog_fixed,ui-widget-header',
								modal: true,
								height: 900,
								width: 1100,
								minWidth: 400,
								minHeight: 400,
								draggable:true,
								buttons: { "Ok": function () { loadPermitMedia(#permit_id#); loadPermitRelatedMedia(#permit_id#); $(this).dialog("close"); } }
							});
							amddialog.dialog('open');
							amddialog.dialog('moveToTop');
						};
			
						function removeMediaDiv() {
							if(document.getElementById('bgDiv')){
								jQuery('##bgDiv').remove();
							}
							if	(document.getElementById('mediaDiv')) {
								jQuery('##mediaDiv').remove();
							}
						};
						function loadPermitMedia(permit_id) {
							jQuery.get("/transactions/component/functions.cfc",
							{
								method : "getPermitMediaHtml",
								permit_id : permit_id
							},
							function (result) {
								$("##copyofpermit").html(result);
							});
						};
			
						function loadPermitRelatedMedia(permit_id) {
							jQuery.get("/transactions/component/functions.cfc",
							{
								method : "getPermitMediaHtml",
								permit_id : permit_id,
								correspondence : "yes"
							},
							function (result) {
								$("##associateddocuments").html(result);
							});
						};
				
						function	reloadTransMedia() { 
							reloadPermitMedia();
						}
						function	reloadPermitMedia() { 
							loadPermitMedia(#permit_id#);
							loadPermitRelatedMedia(#permit_id#);
						}
			
						jQuery(document).ready(loadPermitMedia(#permit_id#));
						jQuery(document).ready(loadPermitRelatedMedia(#permit_id#));
					</script>
					<section name="associatedMediaSection" class="mx-0 pb-2 bg-light row border rounded mt-2">
						<cfquery name="permituse" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							select 'accession' as ontype, accn_number as tnumber, accn_type as ttype, trans.transaction_type, trans.trans_date, collection.guid_prefix,
								concat('/transactions/Accession.cfm?Action=edit&transaction_id=',trans.transaction_id) as uri
							from permit_trans left join trans on permit_trans.transaction_id = trans.transaction_id
								left join collection on trans.collection_id = collection.collection_id
								left join accn on trans.transaction_id = accn.transaction_id
							where trans.transaction_type = 'accn'
								and permit_trans.permit_id = <cfqueryparam cfsqltype="cf_sql_decimal" value="#permit_id#">
							union
							select 'loan' as ontype, loan_number as tnumber, loan_type as ttype, trans.transaction_type, trans.trans_date, collection.guid_prefix,
								concat('/transactions/Loan.cfm?Action=editLoan&transaction_id=',trans.transaction_id) as uri
							from permit_trans left join trans on permit_trans.transaction_id = trans.transaction_id
								left join collection on trans.collection_id = collection.collection_id
								left join loan on trans.transaction_id = loan.transaction_id
							where trans.transaction_type = 'loan'
								and permit_trans.permit_id = <cfqueryparam cfsqltype="cf_sql_decimal" value="#permit_id#">
							union
							select 'deaccession' as ontype, deacc_number as tnumber, deacc_type as ttype, trans.transaction_type, trans.trans_date, collection.guid_prefix,
								concat('/transactions/Deaccession.cfm?Action=edit&transaction_id=',trans.transaction_id) as uri
							from permit_trans left join trans on permit_trans.transaction_id = trans.transaction_id
								left join collection on trans.collection_id = collection.collection_id
								left join MCZBASE.deaccession on trans.transaction_id = deaccession.transaction_id
							where trans.transaction_type = 'deaccession'
								and permit_trans.permit_id = <cfqueryparam cfsqltype="cf_sql_decimal" value="#permit_id#">
							union
							select 'borrow' as ontype, lenders_trans_num_cde as tnumber, lender_loan_type as ttype, trans.transaction_type, trans.trans_date, collection.guid_prefix,
								concat('/transactions/Borrow.cfm?Action=edit&transaction_id=',trans.transaction_id) as uri
							from permit_trans left join trans on permit_trans.transaction_id = trans.transaction_id
								left join collection on trans.collection_id = collection.collection_id
								left join borrow on trans.transaction_id = borrow.transaction_id
							where trans.transaction_type = 'borrow'
								and permit_trans.permit_id = <cfqueryparam cfsqltype="cf_sql_decimal" value="#permit_id#">
							union
							select 'borrow shipment' as ontype, lenders_trans_num_cde as tnumber, lender_loan_type as ttype, trans.transaction_type, trans.trans_date, collection.guid_prefix,
								concat('/transactions/Borrow.cfm?action=edit&transaction_id=',trans.transaction_id) as uri
							from permit_shipment left join shipment on permit_shipment.shipment_id = shipment.shipment_id
								left join trans on shipment.transaction_id = trans.transaction_id
								left join collection on trans.collection_id = collection.collection_id
								left join borrow on trans.transaction_id = borrow.transaction_id
							where trans.transaction_type = 'borrow'
								and permit_shipment.permit_id = <cfqueryparam cfsqltype="cf_sql_decimal" value="#permit_id#">
							union
							select 'loan shipment' as ontype, loan_number as tnumber, loan_type as ttype, trans.transaction_type, trans.trans_date, collection.guid_prefix,
								concat('/transactions/Loan.cfm?Action=editLoan&transaction_id=',trans.transaction_id) as uri
							from permit_shipment left join shipment on permit_shipment.shipment_id = shipment.shipment_id
								left join trans on shipment.transaction_id = trans.transaction_id
								left join collection on trans.collection_id = collection.collection_id
								left join loan on trans.transaction_id = loan.transaction_id
							where trans.transaction_type = 'loan'
								and permit_shipment.permit_id = <cfqueryparam cfsqltype="cf_sql_decimal" value="#permit_id#">
							union
							select 'accession shipment' as ontype, accn_number as tnumber, accn_type as ttype, trans.transaction_type, trans.trans_date, collection.guid_prefix,
								concat('/transactions/Accession.cfm?action=edit&transaction_id=',trans.transaction_id) as uri
							from permit_shipment left join shipment on permit_shipment.shipment_id = shipment.shipment_id
								left join trans on shipment.transaction_id = trans.transaction_id
								left join collection on trans.collection_id = collection.collection_id
								left join accn on trans.transaction_id = accn.transaction_id
							where trans.transaction_type = 'accn'
								and permit_shipment.permit_id = <cfqueryparam cfsqltype="cf_sql_decimal" value="#permit_id#">
							union
							select 'deaccession shipment' as ontype, deacc_number as tnumber, deacc_type as ttype, trans.transaction_type, trans.trans_date, collection.guid_prefix,
								concat('/transactions/Deaccession.cfm?Action=edit&transaction_id=',trans.transaction_id) as uri
							from permit_shipment left join shipment on permit_shipment.shipment_id = shipment.shipment_id
								left join trans on shipment.transaction_id = trans.transaction_id
								left join collection on trans.collection_id = collection.collection_id
								left join deaccession on trans.transaction_id = deaccession.transaction_id
							where trans.transaction_type = 'deaccession'
								and permit_shipment.permit_id = <cfqueryparam cfsqltype="cf_sql_decimal" value="#permit_id#">
						</cfquery>
						<div class="col-12">
							<div id="permitsusedin" class="shippingBlock" >
								<h2 class="h3">Permit used for</h2>
								<ul class="col-12 col-md-8 mx-0 px-4 float-left list-style-disc">
									<cfloop query="permituse">
										<li><a href="#uri#" target="_blank">#transaction_type# #tnumber#</a> #ontype# type: #ttype# on: #dateformat(trans_date,'yyyy-mm-dd')# went to: #guid_prefix#</li>
									</cfloop>
									<cfif permituse.recordCount eq 0>
										<li>No linked transactions or shipments.</li>
									</cfif>
								</ul>
							</div>
							<span>
								<form action="/transactions/Permit.cfm" method="get">
									<input type="hidden" name="permit_id" value="#permit_id#">
									<input type="hidden" name="Action" value="PermitUseReport">
									<input type="submit" value="Detailed report on use of this Permit" class="btn btn-xs btn-secondary float-right">
								</form>
							</span>
						</div>
					</section>
				</div>
			</main>
		</cfoutput>
	</cfcase>
	<!--------------------------------------------------------------------------------------------------->
	<cfcase value="view">
		<cfif not isdefined("permit_id") OR len(#permit_id#) is 0>
			<cfthrow message="Error: Unable to view a permissions and rights document without a permit_id">
		</cfif>
		<cfquery name="permitInfo" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select distinct
				permit.permit_id,
				issuedBy.agent_name as IssuedByAgent,
				issuedBy.agent_id as IssuedByAgentID,
				issuedTo.agent_name as IssuedToAgent,
				issuedTo.agent_id as IssuedToAgentID,
				contact_agent_id,
				contact.agent_name as ContactAgent,
				issued_Date,
				renewed_Date,
				exp_Date,
				restriction_summary,
				benefits_summary,
				benefits_provided,
				permit_num,
				permit_Type,
				specific_type,
				permit_title,
				permit_remarks
			from
				permit left join preferred_agent_name issuedTo on permit.issued_to_agent_id = issuedTo.agent_id
				left join preferred_agent_name issuedBy on permit.issued_by_agent_id = issuedBy.agent_id
				left join preferred_agent_name contact on permit.contact_agent_id = contact.agent_id
			where
				permit_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#permit_id#">
			order by permit_id
		</cfquery>
		<cfoutput query="permitInfo" group="permit_id">
			<script>
				jQuery(document).ready(function() {
					$("##issued_date").datepicker({ dateFormat: 'yy-mm-dd'});
					$("##renewed_date").datepicker({ dateFormat: 'yy-mm-dd'});
					$("##exp_date").datepicker({ dateFormat: 'yy-mm-dd'});
				});
			</script>
			<main class="container pt-2 pb-5">
				<h1 class="h2 wikilink my-2 ml-3" id="PermitFormSectionLabel" >
					Permissions &amp; Rights Document 
					<a href="/transactions/Permit.cfm?action=edit&permit_id=#encodeForURL(permit_id)#" class="btn btn-xs btn-primary">Edit</a>
				</h1>
				<section id="PermitFormSection" class="row mx-0 border rounded mt-2" aria-labeledby="PermitFormSectionLabel" >
					<form id="noActionForm" action="javascript:void(0);" class="col-12 px-3">
						<div class="form-row my-2 pt-2">
							<div class="col-12 col-md-4">
								<span>
									<label for="issued_by_agent_name" class="data-entry-label">
										Issued By:
										<span id="issued_by_agent_view"><a href="/agents/Agent.cfm?agent_id=#IssuedByAgentId#">View</a></span>
									</label>
								</span>
								<input name="issued_by_agent_name" id="issued_by_agent_name" class="form-control form-control-sm data-entry-input" readonly value="#IssuedByAgent#" >
							</div>
							<div class="col-12 col-md-4">
								<span>
									<label for="issued_to_agent_name" class="data-entry-label">
										Issued To:
										<span id="issued_to_agent_view"><a href="/agents/Agent.cfm?agent-id=#IssuedToAgentID#">View</a></span>
									</label>
								</span>
								<input name="issued_to_agent_name" id="issued_to_agent_name" class="form-control form-control-sm data-entry-input" readonly value="#IssuedToAgent#" >
							</div>
							<div class="col-12 col-md-4">
								<span>
									<label for="contact_agent_name" class="data-entry-label">
										Contact Person:
										<span id="contact_agent_view"><a href="/agents/Agent.cfm?agent-id=#contact_agent_id#">View</a></span>
									</label>
								</span>
								<input name="contact_agent_name" id="contact_agent_name" class="form-control form-control-sm data-entry-input" readonly value="#ContactAgent#">
							</div>
						</div>
						<div class="form-row mb-2">
							<div class="col-12 col-md-4">
								<label for="issued_date" class="data-entry-label">Issued Date</label>
								<input type="text" id="issued_date" name="issued_date" class="data-entry-input" readonly  value="#dateformat(issued_date,"yyyy-mm-dd")#">
							</div>
							<div class="col-12 col-md-4">
								<label for="renewed_date" class="data-entry-label">Renewed Date</label>
								<input type="text" id="renewed_date" name="renewed_date" class="data-entry-input" readonly value="#dateformat(renewed_date,"yyyy-mm-dd")#">
							</div>
							<div class="col-12 col-md-4">
								<label for="exp_date" class="data-entry-label">Expiration Date</label>
								<input type="text" id="exp_date" name="exp_date" class="data-entry-input" readonly value="#dateformat(exp_date,"yyyy-mm-dd")#">
							</div>
						</div>
						<div class="form-row mb-2">
							<div class="col-12 col-md-6">
								<label for="permit_num" class="data-entry-label">Permit Number</label>
								<input type="text" name="permit_num" id="permit_num" class="data-entry-input" readonly value="#permit_num#">
							</div>
							<div class="col-12 col-md-6">
								<label for="permit_title" class="data-entry-label">Document Title</label>
								<input type="text" name="permit_title" id="permit_title" class="data-entry-input" readonly value="#permit_title#">
							</div>
						</div>
						<div class="form-row mb-2">
							<div class="col-12 col-md-6">
								<label for="permit_type" class="data-entry-label">Type</label>
								<input type="text" name="permit_type" id="permit_type" class="data-entry-input" readonly value="#permit_type#">
							</div>
							<div class="col-12 col-md-6">
								<label for="specific_type" class="data-entry-label">Specific Document Type</label>
								<input type="text" name="specific_type" id="specific_type" class="data-entry-input" readonly value="#specific_type#">
							</div>
							<div class="col-12">
								<label for="permit_remarks" class="data-entry-label">Remarks</label>
								<input type="text" name="permit_remarks" id="permit_remarks" class="data-entry-input" readonly value="#permit_remarks#">
							</div>
						</div>
						<div class="form-row mb-2">
							<div class="col-12">
								<label for="restriction_summary" class="data-entry-label">Summary of Restrictions on Use (<span id="length_restriction_summary"></span>)</label>
								<textarea rows="1" name="restriction_summary" id="restriction_summary" 
									onkeyup="countCharsLeft('restriction_summary', 4000, 'length_restriction_summary');"
									class="autogrow border rounded w-100" readonly>#restriction_summary#</textarea>
							</div>
						</div>
						<div class="form-row mb-2">
							<div class="col-12">
								<label for="benefits_summary" class="data-entry-label">Summary of Agreed Benefits (<span id="length_benefits_summary"></span>)</label>
								<textarea rows="1" name="benefits_summary" id="benefits_summary" 
									onkeyup="countCharsLeft('benefits_summary', 4000, 'length_benefits_summary');"
									class="autogrow border rounded w-100" readonly >#benefits_summary#</textarea>
							</div>
						</div>
						<div class="form-row mb-2">
							<div class="col-12">
								<label for="benefits_provided" class="data-entry-label">Benefits Provided (<span id="length_benefits_provided"></span>)</label>
								<textarea rows="1" name="benefits_provided" id="benefits_provided" 
									onkeyup="countCharsLeft('benefits_provided', 4000, 'length_benefits_provided');"
									class="autogrow border rounded w-100" readonly>#benefits_provided#</textarea>
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
					</form>
				</section>
				<div class="col-12 mt-3 mb-4 border rounded px-2 pb-2 bg-grayish">
					<section name="permitMediaSection" class="row mx-0 bg-light border pb-2 rounded my-2">
						<div class="col-12">
							<!---  Show/add media copy of permit  (shows permit) --->
							<div id="copyofpermit"><img src='images/indicator.gif'></div>
						</div>
					</section>
					<section name="associatedMediaSection" class="row mx-0 bg-light border pb-2 rounded my-2">
						<div class="col-12 pb-2">
							<!---  list/add media copy of associated documents (document for permit) --->
							<div id="associateddocuments"><img src='images/indicator.gif'></div>
						</div>
					</section>
					<script>
						function loadPermitMedia(permit_id) {
							jQuery.get("/transactions/component/functions.cfc",
							{
								method : "getPermitMediaHtml",
								editable : "false",
								permit_id : permit_id
							},
							function (result) {
								$("##copyofpermit").html(result);
							});
						};
			
						function loadPermitRelatedMedia(permit_id) {
							jQuery.get("/transactions/component/functions.cfc",
							{
								method : "getPermitMediaHtml",
								permit_id : permit_id,
								editable : "false",
								correspondence : "yes"
							},
							function (result) {
								$("##associateddocuments").html(result);
							});
						};
						jQuery(document).ready(loadPermitMedia(#permit_id#));
						jQuery(document).ready(loadPermitRelatedMedia(#permit_id#));
					</script>
					<section name="associatedMediaSection" class="mx-0 pb-2 bg-light row border rounded mt-2">
						<cfquery name="permituse" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							select 'accession' as ontype, accn_number as tnumber, accn_type as ttype, trans.transaction_type, trans.trans_date, collection.guid_prefix,
								concat('/transactions/Accession.cfm?Action=edit&transaction_id=',trans.transaction_id) as uri
							from permit_trans left join trans on permit_trans.transaction_id = trans.transaction_id
								left join collection on trans.collection_id = collection.collection_id
								left join accn on trans.transaction_id = accn.transaction_id
							where trans.transaction_type = 'accn'
								and permit_trans.permit_id = <cfqueryparam cfsqltype="cf_sql_decimal" value="#permit_id#">
							union
							select 'loan' as ontype, loan_number as tnumber, loan_type as ttype, trans.transaction_type, trans.trans_date, collection.guid_prefix,
								concat('/transactions/Loan.cfm?Action=editLoan&transaction_id=',trans.transaction_id) as uri
							from permit_trans left join trans on permit_trans.transaction_id = trans.transaction_id
								left join collection on trans.collection_id = collection.collection_id
								left join loan on trans.transaction_id = loan.transaction_id
							where trans.transaction_type = 'loan'
								and permit_trans.permit_id = <cfqueryparam cfsqltype="cf_sql_decimal" value="#permit_id#">
							union
							select 'deaccession' as ontype, deacc_number as tnumber, deacc_type as ttype, trans.transaction_type, trans.trans_date, collection.guid_prefix,
								concat('/transactions/Deaccession.cfm?Action=edit&transaction_id=',trans.transaction_id) as uri
							from permit_trans left join trans on permit_trans.transaction_id = trans.transaction_id
								left join collection on trans.collection_id = collection.collection_id
								left join MCZBASE.deaccession on trans.transaction_id = deaccession.transaction_id
							where trans.transaction_type = 'deaccession'
								and permit_trans.permit_id = <cfqueryparam cfsqltype="cf_sql_decimal" value="#permit_id#">
							union
							select 'borrow' as ontype, lenders_trans_num_cde as tnumber, lender_loan_type as ttype, trans.transaction_type, trans.trans_date, collection.guid_prefix,
								concat('/transactions/Borrow.cfm?Action=edit&transaction_id=',trans.transaction_id) as uri
							from permit_trans left join trans on permit_trans.transaction_id = trans.transaction_id
								left join collection on trans.collection_id = collection.collection_id
								left join borrow on trans.transaction_id = borrow.transaction_id
							where trans.transaction_type = 'borrow'
								and permit_trans.permit_id = <cfqueryparam cfsqltype="cf_sql_decimal" value="#permit_id#">
							union
							select 'borrow shipment' as ontype, lenders_trans_num_cde as tnumber, lender_loan_type as ttype, trans.transaction_type, trans.trans_date, collection.guid_prefix,
								concat('/transactions/Borrow.cfm?action=edit&transaction_id=',trans.transaction_id) as uri
							from permit_shipment left join shipment on permit_shipment.shipment_id = shipment.shipment_id
								left join trans on shipment.transaction_id = trans.transaction_id
								left join collection on trans.collection_id = collection.collection_id
								left join borrow on trans.transaction_id = borrow.transaction_id
							where trans.transaction_type = 'borrow'
								and permit_shipment.permit_id = <cfqueryparam cfsqltype="cf_sql_decimal" value="#permit_id#">
							union
							select 'loan shipment' as ontype, loan_number as tnumber, loan_type as ttype, trans.transaction_type, trans.trans_date, collection.guid_prefix,
								concat('/transactions/Loan.cfm?Action=editLoan&transaction_id=',trans.transaction_id) as uri
							from permit_shipment left join shipment on permit_shipment.shipment_id = shipment.shipment_id
								left join trans on shipment.transaction_id = trans.transaction_id
								left join collection on trans.collection_id = collection.collection_id
								left join loan on trans.transaction_id = loan.transaction_id
							where trans.transaction_type = 'loan'
								and permit_shipment.permit_id = <cfqueryparam cfsqltype="cf_sql_decimal" value="#permit_id#">
							union
							select 'accession shipment' as ontype, accn_number as tnumber, accn_type as ttype, trans.transaction_type, trans.trans_date, collection.guid_prefix,
								concat('/transactions/Accession.cfm?action=edit&transaction_id=',trans.transaction_id) as uri
							from permit_shipment left join shipment on permit_shipment.shipment_id = shipment.shipment_id
								left join trans on shipment.transaction_id = trans.transaction_id
								left join collection on trans.collection_id = collection.collection_id
								left join accn on trans.transaction_id = accn.transaction_id
							where trans.transaction_type = 'accn'
								and permit_shipment.permit_id = <cfqueryparam cfsqltype="cf_sql_decimal" value="#permit_id#">
							union
							select 'deaccession shipment' as ontype, deacc_number as tnumber, deacc_type as ttype, trans.transaction_type, trans.trans_date, collection.guid_prefix,
								concat('/transactions/Deaccession.cfm?Action=edit&transaction_id=',trans.transaction_id) as uri
							from permit_shipment left join shipment on permit_shipment.shipment_id = shipment.shipment_id
								left join trans on shipment.transaction_id = trans.transaction_id
								left join collection on trans.collection_id = collection.collection_id
								left join deaccession on trans.transaction_id = deaccession.transaction_id
							where trans.transaction_type = 'deaccession'
								and permit_shipment.permit_id = <cfqueryparam cfsqltype="cf_sql_decimal" value="#permit_id#">
						</cfquery>
						<div class="col-12">
							<div id="permitsusedin" class="shippingBlock" >
								<h2 class="h3">Permit used for</h2>
								<ul class="col-12 col-md-8 mx-0 px-4 float-left list-style-disc">
									<cfloop query="permituse">
										<li><a href="#uri#" target="_blank">#transaction_type# #tnumber#</a> #ontype# type: #ttype# on: #dateformat(trans_date,'yyyy-mm-dd')# went to: #guid_prefix#</li>
									</cfloop>
									<cfif permituse.recordCount eq 0>
										<li>No linked transactions or shipments.</li>
									</cfif>
								</ul>
							</div>
							<span>
								<form action="/transactions/Permit.cfm" method="get">
									<input type="hidden" name="permit_id" value="#permit_id#">
									<input type="hidden" name="Action" value="PermitUseReport">
									<input type="submit" value="Detailed report on use of this Permit" class="btn btn-xs btn-secondary float-right">
								</form>
							</span>
						</div>
					</section>
				</div>
			</main>
		</cfoutput>
	</cfcase>
	<!--------------------------------------------------------------------------------------------------->
	<cfcase value="create">
		<cfoutput>
			<cfset hasError = 0 >
			<cfif not isdefined("specific_type") OR len(#specific_type#) is 0>
				Error: You didn't select a document type. 
				<cfset hasError = 1 >
			</cfif>
			<cfif not isdefined("issued_by_agent_id") OR len(#issued_by_agent_id#) is 0>
				Error: You didn't select an issued by agent. 
				<cfset hasError = 1 >
			</cfif>
			<cfif not isdefined("issued_to_agent_id") OR len(#issued_to_agent_id#) is 0>
				Error: You didn't select an issued to agent. 
				<cfset hasError = 1 >
			</cfif>
			<cfquery name="ptype" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select permit_type 
				from ctspecific_permit_type 
				where specific_type = <cfqueryparam CFSQLTYPE="CF_SQL_VARCHAR" value="#specific_type#">
			</cfquery>
			<cfset permit_type = #ptype.permit_type#>
			<cfquery name="nextPermit" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select sq_permit_id.nextval nextPermit from dual
			</cfquery>
			<cfif isdefined("specific_type") and len(#specific_type#) is 0 and ( not isdefined("permit_type") OR len(#permit_type#) is 0 )>
				Error: There was an error selecting the permit type for the specific document type.  Please file a bug report.
				<cfset hasError = 1 >
			</cfif>
			<cfif hasError eq 1>
				<cfabort>
			</cfif>
			<cfquery name="newPermit" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="newPermitResult">
				INSERT INTO permit (
					PERMIT_ID,
					ISSUED_BY_AGENT_ID
					<cfif len(#ISSUED_DATE#) gt 0>
						,ISSUED_DATE
					</cfif>
					,ISSUED_TO_AGENT_ID
					<cfif len(#RENEWED_DATE#) gt 0>
						,RENEWED_DATE
					</cfif>
					<cfif len(#EXP_DATE#) gt 0>
						,EXP_DATE
					</cfif>
					<cfif len(#PERMIT_NUM#) gt 0>
						,PERMIT_NUM
					</cfif>
					,PERMIT_TYPE
					,SPECIFIC_TYPE
					<cfif len(#PERMIT_TITLE#) gt 0>
						,PERMIT_TITLE
					</cfif>
					<cfif len(#PERMIT_REMARKS#) gt 0>
						,PERMIT_REMARKS
					</cfif>
					<cfif len(#restriction_summary#) gt 0>
						,restriction_summary
					</cfif>
					<cfif len(#benefits_summary#) gt 0>
						,benefits_summary
					</cfif>
					<cfif len(#benefits_provided#) gt 0>
						,benefits_provided
					</cfif>
					<cfif len(#contact_agent_id#) gt 0>
						,contact_agent_id
					</cfif>)
				VALUES (
					#nextPermit.nextPermit#
					, <cfqueryparam CFSQLTYPE="CF_SQL_DECIMAL" value="#issued_by_agent_id#">
					<cfif len(#ISSUED_DATE#) gt 0>
						,'#dateformat(ISSUED_DATE,"yyyy-mm-dd")#'
					</cfif>
					, <cfqueryparam CFSQLTYPE="CF_SQL_DECIMAL" value="#issued_to_agent_id#">
					<cfif len(#RENEWED_DATE#) gt 0>
						,'#dateformat(RENEWED_DATE,"yyyy-mm-dd")#'
					</cfif>
					<cfif len(#EXP_DATE#) gt 0>
						,'#dateformat(EXP_DATE,"yyyy-mm-dd")#'
					</cfif>
					<cfif len(#PERMIT_NUM#) gt 0>
						, <cfqueryparam CFSQLTYPE="CF_SQL_VARCHAR" value="#permit_num#">
					</cfif>
					, <cfqueryparam CFSQLTYPE="CF_SQL_VARCHAR" value="#permit_type#">
					, <cfqueryparam CFSQLTYPE="CF_SQL_VARCHAR" value="#specific_type#">
					<cfif len(#PERMIT_TITLE#) gt 0>
						, <cfqueryparam CFSQLTYPE="CF_SQL_VARCHAR" value="#permit_title#">
					</cfif>
					<cfif len(#PERMIT_REMARKS#) gt 0>
						, <cfqueryparam CFSQLTYPE="CF_SQL_VARCHAR" value="#permit_remarks#">
					</cfif>
					<cfif len(#restriction_summary#) gt 0>
						, <cfqueryparam CFSQLTYPE="CF_SQL_VARCHAR" value="#restriction_summary#">
					</cfif>
					<cfif len(#benefits_summary#) gt 0>
						, <cfqueryparam CFSQLTYPE="CF_SQL_VARCHAR" value="#benefits_summary#">
					</cfif>
					<cfif len(#benefits_provided#) gt 0>
						, <cfqueryparam CFSQLTYPE="CF_SQL_VARCHAR" value="#benefits_provided#">
					</cfif>
					<cfif len(#contact_agent_id#) gt 0>
						, <cfqueryparam CFSQLTYPE="CF_SQL_DECIMAL" value="#contact_agent_id#">
					</cfif>)
			</cfquery>
			<cfif isdefined("headless") and headless EQ 'true'>
				<cflocation url="Permit.cfm?Action=edit&headless=true&permit_id=#nextPermit.nextPermit#">
			<cfelse>
				<cflocation url="/transactions/Permit.cfm?Action=edit&permit_id=#nextPermit.nextPermit#">
			</cfif>
		</cfoutput>
	</cfcase>
	<!--------------------------------------------------------------------------------------------------->
	<cfcase value="permitUseReport">
		<cfif not isdefined("permit_id") OR len(#permit_id#) is 0>
			<cfthrow message="Error: permit use report invoked without a permit_id. Go back and try again">
 		</cfif>
	 	<cfoutput>
			<main id="content">
				<cfquery name="permitInfo" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select permit.permit_id,
					issuedBy.agent_name as IssuedByAgent,
					issuedTo.agent_name as IssuedToAgent,
					contact_agent_id,
					contact.agent_name as ContactAgent,
					to_char(issued_Date,'yyyy-mm-dd') as issued_date,
					to_char(renewed_Date,'yyyy-mm-dd') as renewed_date,
					to_char(exp_Date,'yyyy-mm-dd') as exp_date,
					restriction_summary,
					benefits_summary,
					benefits_provided,
					permit_num,
					permit_Type,
					specific_type,
					permit_title,
					permit_remarks
					from
						permit,
						preferred_agent_name issuedTo,
						preferred_agent_name issuedBy ,
						preferred_agent_name contact
					where
						permit.issued_by_agent_id = issuedBy.agent_id (+) and
					permit.issued_to_agent_id = issuedTo.agent_id (+) AND
					permit.contact_agent_id = contact.agent_id (+)
					and permit_id=<cfqueryparam cfsqltype="cf_sql_decimal" value="#permit_id#">
					order by permit_id
				</cfquery>
				
				<section class="container-fluid">
					<h1 class="h4 mt-3 font-weight-normal">Use Report for Permissions &amp; Rights Document</h1>
					<cfloop query="permitInfo">
						<div class="form-row">
							<div class="col-12">
								<h2 class="h3 mb-0">#permit_Type# #permit_num# #permit_title#</h2>
							</div>
							<div class="col-12 mb-2">
							Issued: #issued_date# | Expires: #exp_Date# | Renewed: #renewed_Date# | Issued By: #issuedByAgent# | Issued To: #issuedToAgent# | Remarks: #permit_remarks#
							</div>
							<div class="col-12">
								<button type="button" class="btn btn-xs btn-primary" id="displayReportButton" >Display/Download Detailed Report</button>
								<a class="btn btn-xs btn-secondary ml-2" href="/transactions/Permit.cfm?action=edit&permit_id=#permit_id#">Edit This Permissions &amp; Rights Document</a>
								<a class="btn btn-xs btn-secondary ml-2" href="/Reports/permit.cfm?permit_id=#permit_id#">(Old) Permit Use Report</a>
							</div>
						</div>
					</cfloop>
					<!--- NOTE: This query is duplicated in the backing method used to populate the jqx grid --->
					<cfquery name="permituse" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select 'accession' as ontype, accn_number as tnumber, accn_type as ttype, trans.transaction_type, trans.trans_date, collection.guid_prefix,
							concat('/transactions/Accession.cfm?action=edit&transaction_id=',trans.transaction_id) as uri,
							locality.sovereign_nation,
							flat.country, flat.state_prov, flat.county, flat.island, flat.scientific_name, flat.guid,
							GET_TRANS_SOLE_SHIP_DATE(permit_trans.transaction_id) as shipped_date,'Museum of Comparative Zoology' as toinstitution, ' ' as frominstitution, flat.parts,
							decode(mczbase.concatcommonname(taxon_name_id),null,'none recorded',mczbase.concatcommonname(taxon_name_id)) as common_name
						from permit_trans left join trans on permit_trans.transaction_id = trans.transaction_id
							left join collection on trans.collection_id = collection.collection_id
							left join accn on trans.transaction_id = accn.transaction_id
							left join cataloged_item on accn.transaction_id = cataloged_item.accn_id
							left join flat on cataloged_item.collection_object_id = flat.collection_object_id
							left join locality on flat.locality_id = locality.locality_id
							left join taxonomy on flat.scientific_name = taxonomy.scientific_name
							where trans.transaction_type = 'accn'
								and permit_trans.permit_id = <cfqueryparam cfsqltype="cf_sql_decimal" value="#permit_id#">
						union
						select 'accession shipment' as ontype, accn_number as tnumber, accn_type as ttype, trans.transaction_type, trans.trans_date, collection.guid_prefix,
							concat('/transactions/Accession.cfm?action=edit&transaction_id=',trans.transaction_id) as uri,
							locality.sovereign_nation,
							flat.country, flat.state_prov, flat.county, flat.island, flat.scientific_name, flat.guid,
							shipped_date, toaddr.institution toinstitution, fromaddr.institution frominstitution, flat.parts,
							decode(mczbase.concatcommonname(taxon_name_id),null,'none recorded',mczbase.concatcommonname(taxon_name_id)) as common_name
						from permit_shipment left join shipment on permit_shipment.shipment_id = shipment.shipment_id
							left join addr toaddr on shipped_to_addr_id = toaddr.addr_id
							left join addr fromaddr on shipped_from_addr_id = fromaddr.addr_id
							left join trans on shipment.transaction_id = trans.transaction_id
							left join collection on trans.collection_id = collection.collection_id
							left join accn on trans.transaction_id = accn.transaction_id
							left join cataloged_item on accn.transaction_id = cataloged_item.accn_id
							left join flat on cataloged_item.collection_object_id = flat.collection_object_id
							left join locality on flat.locality_id = locality.locality_id
							left join taxonomy on flat.scientific_name = taxonomy.scientific_name
							where trans.transaction_type = 'accn'
								and permit_shipment.permit_id = <cfqueryparam cfsqltype="cf_sql_decimal" value="#permit_id#">
						union
						select 'loan' as ontype, loan_number as tnumber, loan_type as ttype, trans.transaction_type, trans.trans_date, collection.guid_prefix,
							concat('/transactions/Loan.cfm?Action=editLoan&transaction_id=',trans.transaction_id) as uri,
							locality.sovereign_nation,
							flat.country, flat.state_prov, flat.county, flat.island, flat.scientific_name, flat.guid,
							TO_DATE(null) as shipped_date, ' ' as toinstitution, ' ' as frominstitution, flat.parts,
							decode(mczbase.concatcommonname(taxon_name_id),null,'none recorded',mczbase.concatcommonname(taxon_name_id)) as common_name
						from permit_trans left join trans on permit_trans.transaction_id = trans.transaction_id
							left join collection on trans.collection_id = collection.collection_id
							left join loan on trans.transaction_id = loan.transaction_id
							left join loan_item on loan.transaction_id = loan_item.transaction_id
							left join specimen_part on loan_item.collection_object_id = specimen_part.collection_object_id
							left join flat on specimen_part.derived_from_cat_item = flat.collection_object_id
							left join locality on flat.locality_id = locality.locality_id
							left join taxonomy on flat.scientific_name = taxonomy.scientific_name
							where trans.transaction_type = 'loan'
								and permit_trans.permit_id = <cfqueryparam cfsqltype="cf_sql_decimal" value="#permit_id#">
						union
						select 'loan shipment' as ontype, loan_number as tnumber, loan_type as ttype, trans.transaction_type, trans.trans_date, collection.guid_prefix,
							concat('/transactions/Loan.cfm?Action=editLoan&transaction_id=',trans.transaction_id) as uri,
							locality.sovereign_nation,
							flat.country, flat.state_prov, flat.county, flat.island, flat.scientific_name, flat.guid,
							shipped_date, toaddr.institution toinstitution, fromaddr.institution frominstitution, flat.parts,
							decode(mczbase.concatcommonname(taxon_name_id),null,'none recorded',mczbase.concatcommonname(taxon_name_id)) as common_name
						from permit_shipment left join shipment on permit_shipment.shipment_id = shipment.shipment_id
							left join addr toaddr on shipped_to_addr_id = toaddr.addr_id
							left join addr fromaddr on shipped_from_addr_id = fromaddr.addr_id
							left join trans on shipment.transaction_id = trans.transaction_id
							left join collection on trans.collection_id = collection.collection_id
							left join loan on trans.transaction_id = loan.transaction_id
							left join loan_item on loan.transaction_id = loan_item.transaction_id
							left join specimen_part on loan_item.collection_object_id = specimen_part.collection_object_id
							left join flat on specimen_part.derived_from_cat_item = flat.collection_object_id
							left join locality on flat.locality_id = locality.locality_id
							left join taxonomy on flat.scientific_name = taxonomy.scientific_name
							where trans.transaction_type = 'loan'
								and permit_shipment.permit_id = <cfqueryparam cfsqltype="cf_sql_decimal" value="#permit_id#">
						union
						select 'deaccession' as ontype, deacc_number as tnumber, deacc_type as ttype, trans.transaction_type, trans.trans_date, collection.guid_prefix,
							concat('/transactions/Deaccession.cfm?action=edit&transaction_id=',trans.transaction_id) as uri,
							locality.sovereign_nation,
							flat.country, flat.state_prov, flat.county, flat.island, flat.scientific_name, flat.guid,
							GET_TRANS_SOLE_SHIP_DATE(permit_trans.transaction_id) as shipped_date, ' ' as toinstitution, 'Museum of Comparative Zoology' as frominstitution, flat.parts,
							decode(mczbase.concatcommonname(taxon_name_id),null,'none recorded',mczbase.concatcommonname(taxon_name_id)) as common_name
						from permit_trans left join trans on permit_trans.transaction_id = trans.transaction_id
							left join collection on trans.collection_id = collection.collection_id
							left join deaccession on trans.transaction_id = deaccession.transaction_id
							left join deacc_item on deaccession.transaction_id = deacc_item.transaction_id
							left join flat on deacc_item.collection_object_id = flat.collection_object_id
							left join locality on flat.locality_id = locality.locality_id
							left join taxonomy on flat.scientific_name = taxonomy.scientific_name
							where trans.transaction_type = 'deaccession'
								and permit_trans.permit_id = <cfqueryparam cfsqltype="cf_sql_decimal" value="#permit_id#">
						union
						select 'deaccession shipment' as ontype, deacc_number as tnumber, deacc_type as ttype, trans.transaction_type, trans.trans_date, collection.guid_prefix,
							concat('/transactions/Deaccession.cfm?action=edit&transaction_id=',trans.transaction_id) as uri,
							locality.sovereign_nation,
							flat.country, flat.state_prov, flat.county, flat.island, flat.scientific_name, flat.guid,
							shipped_date, toaddr.institution toinstitution, fromaddr.institution frominstitution, flat.parts,
							decode(mczbase.concatcommonname(taxon_name_id),null,'none recorded',mczbase.concatcommonname(taxon_name_id)) as common_name
						from permit_shipment left join shipment on permit_shipment.shipment_id = shipment.shipment_id
							left join addr toaddr on shipped_to_addr_id = toaddr.addr_id
							left join addr fromaddr on shipped_from_addr_id = fromaddr.addr_id
							left join trans on shipment.transaction_id = trans.transaction_id
							left join collection on trans.collection_id = collection.collection_id
							left join deaccession on trans.transaction_id = deaccession.transaction_id
							left join deacc_item on deaccession.transaction_id = deacc_item.transaction_id
							left join flat on deacc_item.collection_object_id = flat.collection_object_id
							left join locality on flat.locality_id = locality.locality_id
							left join taxonomy on flat.scientific_name = taxonomy.scientific_name
							where trans.transaction_type = 'deaccession'
								and permit_shipment.permit_id = <cfqueryparam cfsqltype="cf_sql_decimal" value="#permit_id#">
						union
						select 'borrow' as ontype, lenders_trans_num_cde as tnumber, lender_loan_type as ttype, trans.transaction_type, trans.trans_date, collection.guid_prefix,
							concat('/transactions/Borrow.cfm?action=edit&transaction_id=',trans.transaction_id) as uri,
							borrow_item.country_of_origin as sovereign_nation,
							borrow_item.country_of_origin as country, '' as state_prov, '' as county, '' as island, borrow_item.sci_name as scientific_name, borrow_item.catalog_number as guid,
							TO_DATE(null) as shipped_date,'Museum of Comparative Zoology' as toinstitution, '' as frominstitution, borrow_item.spec_prep as parts,
							' ' as common_name
						from permit_trans left join trans on permit_trans.transaction_id = trans.transaction_id
							left join collection on trans.collection_id = collection.collection_id
							left join borrow on trans.transaction_id = borrow.transaction_id
							left join borrow_item on borrow.transaction_id = borrow_item.transaction_id
							where trans.transaction_type = 'borrow'
								and permit_trans.permit_id = <cfqueryparam cfsqltype="cf_sql_decimal" value="#permit_id#">
						union
						select 'borrow shipment' as ontype, lenders_trans_num_cde as tnumber, lender_loan_type as ttype, trans.transaction_type, trans.trans_date, collection.guid_prefix,
							concat('/transactions/Borrow.cfm?action=edit&transaction_id=',trans.transaction_id) as uri,
							borrow_item.country_of_origin as sovereign_nation,
							borrow_item.country_of_origin as country, '' as state_prov, '' as county, '' as island, borrow_item.sci_name as scientific_name, borrow_item.catalog_number as guid,
							shipped_date, toaddr.institution toinstitution, fromaddr.institution frominstitution, borrow_item.spec_prep as parts,
							' ' as common_name
						from permit_shipment left join shipment on permit_shipment.shipment_id = shipment.shipment_id
							left join addr toaddr on shipped_to_addr_id = toaddr.addr_id
							left join addr fromaddr on shipped_from_addr_id = fromaddr.addr_id
							left join trans on shipment.transaction_id = trans.transaction_id
							left join collection on trans.collection_id = collection.collection_id
							left join borrow on trans.transaction_id = borrow.transaction_id
							left join borrow_item on borrow.transaction_id = borrow_item.transaction_id
							where trans.transaction_type = 'borrow'
								and permit_shipment.permit_id = <cfqueryparam cfsqltype="cf_sql_decimal" value="#permit_id#">
					</cfquery>
				</section>	

				<!--- Results table as a jqxGrid. --->
				<section class="container-fluid">
					<div class="row mx-0">
						<div class="col-12 mb-5">
							<div class="row mt-2 mb-0 pb-0 jqx-widget-header border px-2">
								<h2 class="h4 mt-1">Report: </h2>
								<span class="d-block px-3 p-2" tabindex="0" id="resultCount"></span> <span id="resultLink" tabindex="0" class="d-block p-2"></span>
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
				</section>
				<script>
					$(document).ready(function() {
						/* Setup jqxgrid for Search */
						$('##displayReportButton').bind('click', function(evt){
							evt.preventDefault();

							$("##overlay").show();

							$("##searchResultsGrid").replaceWith('<div id="searchResultsGrid" class="jqxGrid" style="z-index: 1;"></div>');
							$('##resultCount').html('');
							$('##resultLink').html('');
							$('##selectModeContainer').hide();
							$('##actionFeedback').html('');

							var search =
							{
								datatype: "json",
								datafields:
								[
									{ name: 'id_link', type: 'string' },
									{ name: 'ontype', type: 'string' },
									{ name: 'tnumber', type: 'string' },
									{ name: 'ttype', type: 'string' },
									{ name: 'transaction_type', type: 'string' },
									{ name: 'trans_date', type: 'string' },
									{ name: 'shipped_date', type: 'string' },
									{ name: 'guid_prefix', type: 'string' },
									{ name: 'uri', type: 'string' },
									{ name: 'sovereign_nation', type: 'string' },
									{ name: 'country', type: 'string' },
									{ name: 'state_prov', type: 'string' },
									{ name: 'county', type: 'string' },
									{ name: 'island', type: 'string' },
									{ name: 'scientific_name', type: 'string' },
									{ name: 'eventdate', type: 'string' },
									{ name: 'guid', type: 'string' },
									{ name: 'toinstitution', type: 'string' },
									{ name: 'frominstitution', type: 'string' },
									{ name: 'parts', type: 'string' },
									{ name: 'commonname', type: 'string' },
									{ name: 'row_number', type: 'string' }
								],
								updaterow: function (rowid, rowdata, commit) {
									commit(true);
								},
								root: 'permitUseRecord',
								id: 'row_number',
								url: '/transactions/component/functions.cfc?method=getUseReportJSON&permit_id=#permit_id#',
								timeout: #Application.ajax_timeout#000,  // units not specified, miliseconds? 
								loadError: function(jqXHR, status, error) { 
									$("##overlay").hide();
									var message = "";      
									if (error == 'timeout') { 
										message = ' Server took too long to respond.';
									} else { 
										message = jqXHR.responseText;
									}
									messageDialog('Error:' + message ,'Error: ' + error.substring(0,50));
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
									{text: 'Catalog Number', datafield: 'guid', width:180, hideable: false, hidden: false },
									{text: 'Transaction', datafield: 'id_link', width: 160, hideable: false, hidden: false},
									{text: 'Type', datafield: 'ttype', width:50, hideable: true, hidden: false },
									{text: 'Number', datafield: 'tnumber', width:150, hideable: true, hidden: true },
									{text: 'Transaction Type', datafield: 'transaction_type', width:150, hideable: true, hidden: true },
									{text: 'Date', datafield: 'trans_date', width:110, hideable: true, hidden: false },
									{text: 'Ship Date', datafield: 'shipped_date', width:110, hideable: true, hidden: false },
									{text: 'Collection', datafield: 'guid_prefix', width:80, hideable: true, hidden: true },
									{text: 'Sovereign Nation', datafield: 'sovereign_nation', width:180, hideable: true, hidden: false },
									{text: 'Country', datafield: 'country', width:150, hideable: true, hidden: true },
									{text: 'State/Province', datafield: 'state_prov', width:160, hideable: true, hidden: false },
									{text: 'County', datafield: 'county', width:150, hideable: true, hidden: true },
									{text: 'Scientific Name', datafield: 'scientific_name', width:200, hideable: true, hidden: false },
									{text: 'Date Collected', datafield: 'eventdate', width:120, hideable: true, hidden: false },
									{text: 'Common Name', datafield: 'common_name', width:150, hideable: true, hidden: false },
									{text: 'Preparations', datafield: 'parts', width:180, hideable: true, hidden: false },
									{text: 'From Institution', datafield: 'frominstitution', width:100, hideable: true, hidden: false},
									{text: 'To Institution', datafield: 'toinstitution', hideable: true, hidden: false }
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
								$('##resultLink').html('<a href="/transactions/Permit.cfm?action=PermitUseReport&permit_id=#permit_id#">Link to this report</a>');
								gridLoaded('searchResultsGrid','use');
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
						/* End Setup jqxgrid for number series Search ******************************/

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
						   $('##' + gridId).jqxGrid({ pagesizeoptions: ['5','50', '100', rowcount], pagesize: 50});
						} else if (rowcount > 50) { 
						   $('##' + gridId).jqxGrid({ pagesizeoptions: ['5','50', rowcount], pagesize: 50});
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
							"<button id='columnPickDialogOpener' onclick=\" $('##columnPickDialog').dialog('open'); \" class='btn btn-xs btn-secondary px-2 my-2 mx-1' >Show/Hide Columns</button>"
						);
						// workaround for menu z-index being below grid cell z-index when grid is created by a loan search.
						// likewise for the popup menu for searching/filtering columns, ends up below the grid cells.
						var maxZIndex = getMaxZIndex();
						$('.jqx-grid-cell').css({'z-index': maxZIndex + 1});
						$('.jqx-grid-group-cell').css({'z-index': maxZIndex + 1});
						$('.jqx-menu-wrapper').css({'z-index': maxZIndex + 2});
						$('##resultDownloadButtonContainer').html('<button id="permitcsvbutton" class="btn btn-xs btn-secondary px-2 my-2 mx-1" aria-label="Export results to csv" onclick=" exportGridToCSV(\'searchResultsGrid\', \''+filename+'\'); " >Export to CSV</button>');
						$('##selectModeContainer').show();
					}
				</script>
				<section class="container-fluid">
					<div id="permitsusedin" class="row">
						<div class="col-12">
							<h3 class="h4">This Permissions &amp; Rights Document Used for/Linked to:</h3>
							<table class="table table-responsive border table-striped table-sm">
								<thead class="thead-light">
									<tr>
										<th>Catalog&nbsp;Number</th>
										<th>Transaction</th>
										<th>Type</th>
										<th>Date</th>
										<th>Ship&nbsp;Date</th>
										<th>Collection</th>
										<th>Sovereign&nbsp;Nation</th>
										<th>Country</th>
										<th>State/Province</th>
										<th>County</th>
										<th>Scientific&nbsp;Name</th>
										<th>Common&nbsp;Name</th>
										<th>Preparations</th>
										<th>From&nbsp;Institution</th>
										<th>To&nbsp;Institution</th>
									</tr>
								</thead>
								<tbody>
									<cfloop query="permituse">
										<tr>
											<td>#guid#</td>
											<td><a href="#uri#" target="_blank">#transaction_type# #tnumber#</a></td>
											<td>#ontype# #ttype#</td>
											<td>#dateformat(trans_date,'yyyy-mm-dd')#</td>
											<td>#dateformat(shipped_date,'yyyy-mm-dd')#</td>
											<td>#guid_prefix#</td>
											<td>#sovereign_nation#</td>
											<td>#country#</td>
											<td>#state_prov#</td>
											<td>#county#</td>
											<td>#scientific_name#</td>
											<td>#common_name#</td>
											<td>#parts#</td>
											<td>#frominstitution#</td>
											<td>#toinstitution#</td>
										</tr>
									</cfloop>
								</tbody>
							</table>
						</div>
					</div>
				</section>
				<section class="container-fluid">
					<cfquery name="permitsalvagereport" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select
							count(cataloged_item.collection_object_id) as cat_count,
							sum(coll_object.lot_count) as spec_count,
							collection.guid_prefix,
							flat.country, flat.state_prov, flat.scientific_name, flat.county,
							mczbase.get_part_prep(specimen_part.collection_object_id) as parts,
							decode(mczbase.concatcommonname(taxon_name_id),null,'none recorded',mczbase.concatcommonname(taxon_name_id)) as common_name
						from permit_trans left join trans on permit_trans.transaction_id = trans.transaction_id
							left join collection on trans.collection_id = collection.collection_id
							left join accn on trans.transaction_id = accn.transaction_id
							left join cataloged_item on accn.transaction_id = cataloged_item.accn_id
							left join flat on cataloged_item.collection_object_id = flat.collection_object_id
							left join specimen_part on cataloged_item.collection_object_id = specimen_part.derived_from_cat_item
							left join coll_object on specimen_part.collection_object_id = coll_object.collection_object_id
							left join taxonomy on flat.scientific_name = taxonomy.scientific_name
						where trans.transaction_type = 'accn'
							and permit_trans.permit_id = <cfqueryparam cfsqltype="cf_sql_decimal" value="#permit_id#">
						group by collection.guid_prefix, country, state_prov, flat.scientific_name, flat.county,
							mczbase.get_part_prep(specimen_part.collection_object_id),
							decode(mczbase.concatcommonname(taxon_name_id),null,'none recorded',mczbase.concatcommonname(taxon_name_id))
					</cfquery>
					<div id="permitaccessionsummary" class="row pb-3">
						<div class="col-12">
							<h3 class="h5">Accession Summary (Salvage Permit Reporting)</h3>
						</div>
						<div class="col-12">
							<cfif permitsalvagereport.RecordCount eq 0>
								<strong>No accessions for this Permissions &amp; Rights Document</strong>
							<cfelse>
								<table class="table d-table table-responsive border">
									<thead class="thead-light">
										<tr>
											<th>Specimen&nbsp;Count</th>
											<th>Collection</th>
											<th>Country</th>
											<th>State</th>
											<th>County</th>
											<th>Scientific&nbsp;Name</th>
											<th>Common&nbsp;Name</th>
											<th>Parts</th>
										</tr>
									</thead>
									<tbody>
									<cfloop query="permitsalvagereport">
										<tr>
											<td>#spec_count#</td>
											<td>#guid_prefix#</td>
											<td>#country#</td>
											<td>#state_prov#</td>
											<td>#county#</td>
											<td>#scientific_name#</td>
											<td>#common_name#</td>
											<td>#parts#</td>
										</tr>
									</cfloop>
									</tbody>
								</table>
							</cfif>
						</div>
					</div>
				</section>
			</main>
		</cfoutput>
	</cfcase>
</cfswitch>

<cfinclude template = "/shared/_footer.cfm">
