<!---
/agents/Agents.cfm

Agent search/results 

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
<cfset pageTitle = "Search Agents">
<cfinclude template = "/shared/_header.cfm">

<cfquery name="dist_prefix" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select distinct(prefix) as dist_prefix from person where prefix is not null
</cfquery>
<cfquery name="dist_suffix" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select distinct(suffix) as dist_suffix from person where suffix is not null
</cfquery>
<cfquery name="ctagent_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select agent_type  from ctagent_type
</cfquery>

<div id="overlaycontainer" style="position: relative;"> 
	<!--- ensure fields have empty values present if not defined. --->
	<cfif not isdefined("prefix")> 
		<cfset prefix="">
	</cfif>
	<cfif not isdefined("suffix")> 
		<cfset suffix="">
	</cfif>
	<cfif not isdefined("anyName")> 
		<cfset anyName="">
	</cfif>
	<cfif not isdefined("agent_remarks")> 
		<cfset agent_remarks="">
	</cfif>
	<cfif not isdefined("last_name")> 
		<cfset last_name="">
	</cfif>
	<cfif not isdefined("middle_name")> 
		<cfset middle_name="">
	</cfif>
	<cfif not isdefined("first_name")> 
		<cfset first_name="">
	</cfif>
	<cfif not isdefined("birth_date")> 
		<cfset birth_date="">
	</cfif>
	<cfif not isdefined("to_birth_date")> 
		<cfset to_birth_date="">
	</cfif>
	<cfif not isdefined("death_date")> 
		<cfset death_date="">
	</cfif>
	<cfif not isdefined("to_death_date")> 
		<cfset to_death_date="">
	</cfif>
	<cfif not isdefined("collected_date")> 
		<cfset collected_date="">
	</cfif>
	<cfif not isdefined("to_collected_date")> 
		<cfset to_collected_date="">
	</cfif>
	<cfif NOT isDefined("agent_type")>
		<cfset in_agent_type="">
	<cfelse>
		<cfset in_agent_type="#agent_type#">
	</cfif>
	<cfif not isdefined("agent_id")> 
		<cfset agent_id="">
	</cfif>
	<cfif not isdefined("specificagent")> 
		<cfset specificagent="">
	</cfif>
	<cfif not isdefined("address")> 
		<cfset address="">
	</cfif>
	<cfif not isdefined("email")> 
		<cfset email="">
	</cfif>
	<cfif not isdefined("phone")> 
		<cfset phone="">
	</cfif>
	<cfif not isdefined("edited")> 
		<cfset edited="">
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
										<label for="anyName" class="data-entry-label" id="anyName_label">Any part of any name
											<span class="small90">
												(<button type="button" tabindex="-1" aria-hidden="true" class="btn-link border-0 p-0 bg-light" onclick="var e=document.getElementById('anyName');e.value='='+e.value;">=<span class="sr-only">prefix with equals sign for case insensitive exact match search</span></button>, 
												<!--- 
													! for not search works, but probably not as expected, it finds agents who have any agent name which doesn't match.
												<button type="button" tabindex="-1" aria-hidden="true" class="btn-link border-0 p-0 bg-light" onclick="var e=document.getElementById('anyName');e.value='!'+e.value;">!<span class="sr-only">prefix with exclamation point for case insensitive not search</span></button>,
												--->
												<button type="button" tabindex="-1" aria-hidden="true" class="btn-link border-0 p-0 bg-light" onclick="var e=document.getElementById('anyName');e.value='~'+e.value;">~<span class="sr-only">prefix with tilde for 0.8 or greater jaro winkler text matching search</span></button>,
												NULL, NOT NULL)
											</span>
										</label>
										<input type="text" id="anyName" name="anyName" class="data-entry-input" value="#anyName#" aria-labelledby="anyName_label" >
									</div>
									<div class="col-12 col-md-4">
										<label for="specificagent" class="data-entry-label" id="specificagent_label">Specific Agent</label>
										<input type="text" id="specificagent" name="specificagent" class="data-entry-input" value="#specificagent#" aria-labelledby="specificagent_label"
											onblur=" if($('##specificagent').val()=='') { $('##agent_id').val(''); }"
											>
										<script>
											$(document).ready(function() {
												makeAgentPicker("specificagent", "agent_id");
											});
										</script>
									</div>
									<div class="col-12 col-md-1">
										<label for="specificagent" class="data-entry-label" id="specificagent_label">Agent ID</label>
										<input type="text" id="agent_id" name="agent_id" value="#agent_id#" class="data-entry-input">
									</div>
									<div class="col-12 col-md-2">
										<label for="agent_type" class="data-entry-label" id="agent_type_label">Agent Type</label>
										<select id="agent_type" name="agent_type" class="data-entry-select">
											<option></option>
											<cfloop query="ctagent_type">
												<cfif in_agent_type EQ ctagent_type.agent_type><cfset selected="selected='true'"><cfelse><cfset selected=""></cfif>
												<option value="#ctagent_type.agent_type#" #selected#>#ctagent_type.agent_type#</option>
											</cfloop>
											<cfloop query="ctagent_type">
												<cfif in_agent_type EQ "!#ctagent_type.agent_type#"><cfset selected="selected='true'"><cfelse><cfset selected=""></cfif>
												<option value="!#ctagent_type.agent_type#" #selected#>not #ctagent_type.agent_type#</option>
											</cfloop>
										</select>
									</div>
								</div>
								<div class="form-row mb-2">
									<div class="col-12 col-md-2">
										<label for="prefix" class="data-entry-label" id="prefix_label">Prefix</label>
										<select id="prefix" name="prefix" class="data-entry-select">
											<option></option>
											<cfloop query="dist_prefix">
												<cfif prefix EQ dist_prefix.dist_prefix><cfset selected="selected='true'"><cfelse><cfset selected=""></cfif>
												<option value="#dist_prefix.dist_prefix#" #selected#>#dist_prefix.dist_prefix#</option>
											</cfloop>
											<cfloop query="dist_prefix">
												<cfif prefix EQ "!#dist_prefix.dist_prefix#"><cfset selected="selected='true'"><cfelse><cfset selected=""></cfif>
												<option value="!#dist_prefix.dist_prefix#" #selected#>not #dist_prefix.dist_prefix#</option>
											</cfloop>
											<cfif prefix EQ "NULL"><cfset sel = "selected='true'"><cfelse><cfset sel = ""></cfif>
											<option value="NULL" #sel# >NULL</option>
											<cfif prefix EQ "NOT NULL"><cfset sel = "selected='true'"><cfelse><cfset sel = ""></cfif>
											<option value="NOT NULL" #sel#>NOT NULL</option>
										</select>
									</div>
									<div class="col-12 col-md-3">
										<label for="first_name" class="data-entry-label" id="first_name_label">First Name
											<span class="small">
												(accepts <button type="button" tabindex="-1" aria-hidden="true" class="btn-link border-0 p-0 bg-light" onclick="var e=document.getElementById('first_name');e.value='='+e.value;">=<span class="sr-only">prefix with equals sign for case insensitive exact match search</span></button>, 
												<button type="button" tabindex="-1" aria-hidden="true" class="btn-link border-0 p-0 bg-light" onclick="var e=document.getElementById('first_name');e.value='!'+e.value;">!<span class="sr-only">prefix with exclamation point for case insensitive not search</span></button>,
												<button type="button" tabindex="-1" aria-hidden="true" class="btn-link border-0 p-0 bg-light" onclick="var e=document.getElementById('first_name');e.value='$'+e.value;">$<span class="sr-only">prefix with dollarsign for sounds like search</span></button>,
												NULL, NOT NULL)
											</span>
										</label>
										<input type="text" id="first_name" name="first_name" class="data-entry-input" value="#first_name#" aria-labelledby="first_name_label" >
									</div>
									<div class="col-12 col-md-2">
										<label for="middle_name" class="data-entry-label" id="middle_name_label">Middle Name 
											<span class="small">
												(accepts <button type="button" tabindex="-1" aria-hidden="true" class="btn-link border-0 p-0 bg-light" onclick="var e=document.getElementById('middle_name');e.value='='+e.value;">=<span class="sr-only">prefix with equals sign for case insensitive exact match search</span></button>, 
												<button type="button" tabindex="-1" aria-hidden="true" class="btn-link border-0 p-0 bg-light" onclick="var e=document.getElementById('middle_name');e.value='!'+e.value;">!<span class="sr-only">prefix with exclamation point for case insensitive not search</span></button>,
												<button type="button" tabindex="-1" aria-hidden="true" class="btn-link border-0 p-0 bg-light" onclick="var e=document.getElementById('middle_name');e.value='$'+e.value;">$<span class="sr-only">prefix with dollarsign for sounds like search</span></button>,
												NULL, NOT NULL)
											</span>
										</label>
										<input type="text" id="middle_name" name="middle_name" class="data-entry-input" value="#middle_name#" aria-labelledby="middle_name_label" >
									</div>
									<div class="col-12 col-md-2">
										<label for="last_name" class="data-entry-label" id="last_name_label">Last Name 
											<span class="small">
												(accepts <button type="button" tabindex="-1" aria-hidden="true" class="btn-link border-0 p-0 bg-light" onclick="var e=document.getElementById('last_name');e.value='='+e.value;">=<span class="sr-only">prefix with equals sign for case insensitive exact match search</span></button>, 
												<button type="button" tabindex="-1" aria-hidden="true" class="btn-link border-0 p-0 bg-light" onclick="var e=document.getElementById('last_name');e.value='!'+e.value;">!<span class="sr-only">prefix with exclamation point for case insensitive not search</span></button>,
												<button type="button" tabindex="-1" aria-hidden="true" class="btn-link border-0 p-0 bg-light" onclick="var e=document.getElementById('last_name');e.value='$'+e.value;">$<span class="sr-only">prefix with dollarsign for sounds like search</span></button>,
												NULL, NOT NULL)
											</span>
										</label>
										<input type="text" id="last_name" name="last_name" class="data-entry-input" value="#last_name#" aria-labelledby="last_name_label" >
									</div>
									<div class="col-12 col-md-2">
										<label for="suffix" class="data-entry-label" id="suffix_label">Suffix</label>
										<select id="suffix" name="suffix" class="data-entry-select">
											<option></option>
											<cfloop query="dist_suffix">
												<cfif suffix EQ dist_suffix.dist_suffix><cfset selected="selected='true'"><cfelse><cfset selected=""></cfif>
												<option value="#dist_suffix.dist_suffix#" #selected#>#dist_suffix.dist_suffix#</option>
											</cfloop>
											<cfloop query="dist_suffix">
												<cfif suffix EQ "!#dist_suffix.dist_suffix#"><cfset selected="selected='true'"><cfelse><cfset selected=""></cfif>
												<option value="!#dist_suffix.dist_suffix#" #selected#>not #dist_suffix.dist_suffix#</option>
											</cfloop>
											<cfif suffix EQ "NULL"><cfset sel = "selected='true'"><cfelse><cfset sel = ""></cfif>
											<option value="NULL" #sel#>NULL</option>
											<cfif suffix EQ "NOT NULL"><cfset sel = "selected='true'"><cfelse><cfset sel = ""></cfif>
											<option value="NOT NULL" #sel#>NOT NULL</option>
										</select>
									</div>
								</div>
								<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
									<div class="form-row mb-2">
										<div class="col-12 col-md-3">
											<label for="agent_remarks" class="data-entry-label" id="agent_remarks_label">Agent Remarks <span class="small">(accepts NULL, NOT NULL)</span></label>
											<input type="text" id="agent_remarks" name="agent_remarks" class="data-entry-input" value="#agent_remarks#" aria-labelledby="agent_remarks_label" >
										</div>
										<div class="col-12 col-md-3">
											<label for="address" class="data-entry-label" id="address_label">Address (Correspondence/Shipping)</label>
											<input type="text" id="address" name="address" class="data-entry-input" value="#address#" aria-labelledby="address_label" >
										</div>
										<div class="col-12 col-md-2">
											<label for="email" class="data-entry-label" id="email_label">Email</label>
											<input type="text" id="email" name="email" class="data-entry-input" value="#email#" aria-labelledby="email_label" >
										</div>
										<div class="col-12 col-md-2">
											<label for="phone" class="data-entry-label" id="phone_label">Phone</label>
											<input type="text" id="phone" name="phone" class="data-entry-input" value="#phone#" aria-labelledby="phone_label" >
										</div>
										<div class="col-12 col-md-2">
											<label for="edited" class="data-entry-label" id="edited_label">Vetted</label>
											<select id="edited" name="edited" class="data-entry-select">
												<option></option>
												<cfif edited EQ 1><cfset sel = "selected='true'"><cfelse><cfset sel = ""></cfif>
												<option value="1" #sel# >Yes *</option>
												<cfif edited EQ 0><cfset sel = "selected='true'"><cfelse><cfset sel = ""></cfif>
												<option value="0" #sel#>No</option>
											</select>
										</div>
									</div>
								</cfif>
								<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
									<cfset dateWord = "Date">
									<cfset dateplaceholder = "yyyy-mm-dd or yyyy">
								<cfelse>
									<cfset dateWord = "Year">
									<cfset dateplaceholder = "yyyy">
								</cfif>
								<div class="form-row mb-2">
									<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
										<div class="col-12 col-md-4">
											<div class="date row bg-light border pb-2 mb-2 mb-md-0 pt-1 px-0 px-md-1 px-xl-1 mx-0 rounded justify-content-center">
												<label class="data-entry-label px-4 px-md-4 mx-1 mb-0" for="birth_date">#dateWord# Of Birth</label>
												<input name="birth_date" id="birth_date" type="text" class="datetimeinput data-entry-input col-4 col-xl-5" placeholder="start #dateplaceholder#" value="#birth_date#" aria-label="start of range for #dateWord# of birth">
												<div class="col-1 col-xl-1 text-center px-0"><small> to</small></div>
												<label class="data-entry-label sr-only" for="to_birth_date">end of search range for date of birth</label>		
												<input type="text" name="to_birth_date" id="to_birth_date" value="#to_birth_date#" class="datetimeinput col-4 col-xl-4 data-entry-input" placeholder="end #dateplaceholder#" title="end of date range">
											</div>
										</div>
									</cfif>
									<div class="col-12 col-md-4">
										<div class="date row bg-light border pb-2 mb-2 mb-md-0 pt-1 px-0 px-md-1 px-xl-1 mx-0 rounded justify-content-center">
											<label class="data-entry-label px-4 px-md-4 mx-1 mb-0" for="death_date">#dateWord# Of Death</label>
											<input name="death_date" id="death_date" type="text" class="datetimeinput data-entry-input col-4 col-xl-5" placeholder="start #dateplaceholder#" value="#death_date#" aria-label="start of range for #dateWord# of death">
											<div class="col-1 col-xl-1 text-center px-0"><small> to</small></div>
											<label class="data-entry-label sr-only" for="to_death_date">end of search range for #dateWord# of death</label>		
											<input type="text" name="to_death_date" id="to_death_date" value="#to_death_date#" class="datetimeinput col-4 col-xl-4 data-entry-input" placeholder="end #dateplaceholder#" title="end of date range">
										</div>
									</div>
									<div class="col-12 col-md-4">
										<div class="date row bg-light border pb-2 mb-2 mb-md-0 pt-1 px-0 px-md-1 px-xl-1 mx-0 rounded justify-content-center">
											<label class="data-entry-label px-4 px-md-4 mx-1 mb-0" for="collected_date">Dates Collected</label>
											<input name="collected_date" id="collected_date" type="text" class="datetimeinput data-entry-input col-4 col-xl-5" placeholder="start yyyy-mm-dd or yyyy" value="#collected_date#" aria-label="start of range for dates collected">
											<div class="col-1 col-xl-1 text-center px-0"><small> to</small></div>
											<label class="data-entry-label sr-only" for="to_collected_date">end of search range for dates collected</label>
											<input type="text" name="to_collected_date" id="to_collected_date" value="#to_collected_date#" class="datetimeinput col-4 col-xl-4 data-entry-input" placeholder="end yyyy-mm-dd or yyyy" title="end of date range">
										</div>
									</div>
								</div>
								<div class="form-row my-2 mx-0">
									<div class="col-12 px-0 pt-2">
										<button class="btn-xs btn-primary px-2 my-2 mr-1" id="searchButton" type="submit" aria-label="Search for agents">Search<span class="fa fa-search pl-1"></span></button>
										<button type="reset" class="btn-xs btn-warning my-2 mr-1" aria-label="Reset search form to inital values" onclick="">Reset</button>
										<button type="button" class="btn-xs btn-warning my-2 mr-1" aria-label="Start a new agent search with a clear form" onclick="window.location.href='#Application.serverRootUrl#/agents/Agents.cfm';" >New Search</button>
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
			var linkIdCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
				var rowData = jQuery("##searchResultsGrid").jqxGrid('getrowdata',row);
				var vetted = rowData['edited'];
				return '<span style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; "><a target="_blank" href="/agents/Agent.cfm?agent_id=' + rowData['agent_id'] + '">'+value+'</a> ' +vetted+ '</span>';
			};
			<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
				var editIdCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
					var rowData = jQuery("##searchResultsGrid").jqxGrid('getrowdata',row);
					var vetted = rowData['edited'];
					return '<span style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; "><a target="_blank" class="ml-1 px-2 btn btn-xs btn-outline-primary" href="/editAllAgent.cfm?agent_id=' + rowData['agent_id'] + '">Edit</a></span>';
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
							{ name: 'agent_id', type: 'string' },
							{ name: 'agent_name', type: 'string' },
							{ name: 'prefix', type: 'string' },
							{ name: 'first_name', type: 'string' },
							{ name: 'middle_name', type: 'string' },
							{ name: 'last_name', type: 'string' },
							{ name: 'suffix', type: 'string' },
							{ name: 'agent_type', type: 'string' },
							{ name: 'edited', type: 'string' },
							<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_transactions")>
								{ name: 'worstagentrank', type: 'string' },
							</cfif>
							{ name: 'birth_date', type: 'string' },
							{ name: 'death_date', type: 'string' },
							{ name: 'collections_scope', type: 'string' },
							<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
								{ name: 'agent_remarks', type: 'string' },
							</cfif>
							<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
								{ name: 'emails', type: 'string' },
								{ name: 'phones', type: 'string' },
							</cfif>
							{ name: 'abbreviation', type: 'string' },
							{ name: 'preferred', type: 'string' },
							{ name: 'acronym', type: 'string' },
							{ name: 'aka', type: 'string' },
							{ name: 'author', type: 'string' },
							{ name: 'second_author', type: 'string' },
							{ name: 'expanded', type: 'string' },
							{ name: 'full', type: 'string' },
							{ name: 'initials', type: 'string' },
							{ name: 'initials_plus_last', type: 'string' },
							{ name: 'last_plus_initials', type: 'string' },
							<cfif isdefined("session.roles") and listfindnocase(session.roles,"global_admin")>
								{ name: 'login', type: 'string' },
							</cfif>
							{ name: 'maiden', type: 'string' },
							{ name: 'married', type: 'string' },
							{ name: 'agentguid', type: 'string' }
						],
						updaterow: function (rowid, rowdata, commit) {
							commit(true);
						},
						root: 'agentRecord',
						id: 'agent_id',
						url: '/agents/component/search.cfc?' + $('##searchForm').serialize(),
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
							<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
								{text: 'Name', datafield: 'agent_name', width: 300, hidable: true, hidden: false, cellsrenderer: linkIdCellRenderer },
								{text: 'ID', datafield: 'agent_id', width:100, hideable: true, hidden: false, cellsrenderer: editIdCellRenderer },
							<cfelse>
								{text: 'ID', datafield: 'agent_id', width:100, hideable: true, hidden: true },
								{text: 'Name', datafield: 'agent_name', width: 300, hidable: true, hidden: false, cellsrenderer: linkIdCellRenderer },
							</cfif>
							{text: 'Vetted', datafield: 'edited', width: 80, hidable: true, hidden: false },
							<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_transactions")>
								{text: 'Rank', datafield: 'worstagentrank', width: 80, hidable: true, hidden: false },
							</cfif>
							{text: 'Prefix', datafield: 'prefix', width: 60, hidable: true, hidden: true },
							{text: 'First', datafield: 'first_name', width: 100, hidable: true, hidden: true },
							{text: 'Middle', datafield: 'middle_name', width: 100, hidable: true, hidden: true },
							{text: 'Last', datafield: 'last_name', width: 100, hidable: true, hidden: true },
							{text: 'Suffix', datafield: 'suffix', width: 60, hidable: true, hidden: true },
							{text: 'Type', datafield: 'agent_type', width: 150, hidable: true, hidden: false },
							{text: 'Birth', datafield: 'birth_date', width:100, hideable: true, hidden: false },
							{text: 'Death', datafield: 'death_date', width:100, hideable: true, hidden: false },
							{text: 'Collections Scope', datafield: 'collections_scope', width:180, hideable: true, hidden: true },
							{text: 'preferred', datafield: 'preferred', width:100, hideable: true, hidden: true },
							{text: 'abbreviation', datafield: 'abbreviation', width:100, hideable: true, hidden: true },
							{text: 'acronym', datafield: 'acronym', width:100, hideable: true, hidden: true },
							{text: 'aka', datafield: 'aka', width:100, hideable: true, hidden: true },
							{text: 'author', datafield: 'author', width:100, hideable: true, hidden: true },
							{text: 'second_author', datafield: 'second_author', width:100, hideable: true, hidden: true },
							{text: 'expanded', datafield: 'expanded', width:100, hideable: true, hidden: true },
							{text: 'maiden', datafield: 'maiden', width:100, hideable: true, hidden: true },
							{text: 'married', datafield: 'married', width:100, hideable: true, hidden: true },
							{text: 'full', datafield: 'full', width:100, hideable: true, hidden: true },
							{text: 'initials', datafield: 'initials', width:100, hideable: true, hidden: true },
							{text: 'initials_plus_last', datafield: 'initials_plus_last', width:100, hideable: true, hidden: true },
							{text: 'last_plus_initials', datafield: 'last_plus_initials', width:100, hideable: true, hidden: true },
							<cfif isdefined("session.roles") and listfindnocase(session.roles,"global_admin")>
								{text: 'login', datafield: 'login', width:100, hideable: true, hidden: true },
							</cfif>
							<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
								{text: 'EmailAddresses', datafield: 'emails', width:150, hideable: true, hidden: true },
								{text: 'PhoneNumbers', datafield: 'phones', width:120, hideable: true, hidden: true },
							</cfif>
							<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
								{text: 'Guid', datafield: 'agentguid', width:150, hideable: true, hidden: false },
								{text: 'Remarks', datafield: 'agent_remarks', hideable: true, hidden: false }
							<cfelse>
								{text: 'Guid', datafield: 'agentguid', hideable: true, hidden: false }
							</cfif>
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
						$('##resultLink').html('<a href="/agents/Agents.cfm?execute=true&' + $('##searchForm :input').filter(function(index,element){return $(element).val()!='';}).serialize() + '">Link to this search</a>');
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
				var halfcolumns = Math.round(columns.length/2);
				var columnListSource = [];
				for (i = 1; i < halfcolumns; i++) {
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
				for (i = halfcolumns; i < columns.length; i++) {
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
				$("##columnPickDialog").dialog({ 
					height: 'auto', 
					width: 'auto',
					adaptivewidth: true,
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
