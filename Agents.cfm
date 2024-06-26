<!---
/Agents.cfm

Agent search/results 

Copyright 2021-2022 President and Fellows of Harvard College

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

<cfset defaultSelectionMode = "none">
<cfif defaultSelectionMode EQ "none">
	<cfset defaultenablebrowserselection = "true">
<cfelse>
	<cfset defaultenablebrowserselection = "false">
</cfif>	

<cfquery name="dist_prefix" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.short_timeout#">
	select distinct(prefix) as dist_prefix from person where prefix is not null
</cfquery>
<cfquery name="dist_suffix" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.short_timeout#">
	select distinct(suffix) as dist_suffix from person where suffix is not null
</cfquery>
<cfquery name="ctagent_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.short_timeout#">
	select agent_type  from ctagent_type
</cfquery>
<cfquery name="collections" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.short_timeout#">
	select collection_cde, collection_id from collection
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
	<cfif not isdefined("biography")> 
		<cfset biography="">
	</cfif>
	<cfif not isdefined("remarks_biography")> 
		<cfset remarks_biography="">
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
	<cfif not isdefined("ranking")> 
		<cfset ranking="">
	</cfif>
	<cfif not isdefined("collector_collection")>
		<cfset collector_collection = "">
	</cfif>
	<cfif not isdefined("author_collection")>
		<cfset author_collection = "">
	</cfif>
	<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_transactions")>
		<cfif not isdefined("trans_agent_collection")>
			<cfset trans_agent_collection = "">
		</cfif>
		<cfif not isdefined("permit_agent_role")>
			<cfset permit_agent_role = "">
		</cfif>
	<cfelse>
		<cfset trans_agent_collection = "">
		<cfset permit_agent_role = "">
	</cfif>
	<!--- Search Form ---> 
	<cfoutput>
		<main id="content">
			<section class="container-fluid mb-3" role="search" aria-labelledby="formheader">
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
						<div class="col-12 px-4 pt-3 pb-2" id="searchFormDiv">
							<form name="searchForm" id="searchForm">
								<input type="hidden" name="method" value="getAgents">
								<div class="form-row mb-2">
									<div class="col-12 col-md-5">
										<label for="anyName" class="data-entry-label" id="anyName_label">Any part of any name
											<span class="small90">
												(<button type="button" tabindex="-1" aria-hidden="true" class="btn-link border-0 p-0 bg-light" onclick="var e=document.getElementById('anyName');e.value='='+e.value;">=<span class="sr-only">prefix with equals sign for case insensitive exact match search</span></button>, 
												<button type="button" tabindex="-1" aria-hidden="true" class="btn-link border-0 p-0 bg-light" onclick="var e=document.getElementById('anyName');e.value='~'+e.value;">~<span class="sr-only">prefix with tilde for 0.8 or greater jaro winkler text matching search</span></button>,
												NULL, NOT NULL, or a comma separated list of names)
											</span>
										</label>
										<input type="text" id="anyName" name="anyName" class="data-entry-input" value="#encodeForHtml(anyName)#" aria-labelledby="anyName_label" >
									</div>
									<!--- onblur, if field is emptied, clear the agent_id. --->
									<script>
										function specificagentBlurHandler() { 
											if($('##specificagent').val()=='') { 
												$('##agent_id').val('');
											}
										}
									</script>
									<div class="col-12 col-md-4">
										<label for="specificagent" class="data-entry-label" id="specificagent_label">Specific Agent</label>
										<input type="text" id="specificagent" name="specificagent" class="data-entry-input" value="#encodeForHtml(specificagent)#" aria-labelledby="specificagent_label"
											onblur=" specificagentBlurHandler();"
											>
										<script>
											$(document).ready(function() {
												makeAgentPicker("specificagent", "agent_id");
											});
										</script>
									</div>
									<div class="col-12 col-md-1">
										<label for="specificagent" class="data-entry-label" id="specificagent_label">Agent ID</label>
										<input type="text" id="agent_id" name="agent_id" value="#encodeForHtml(agent_id)#" class="data-entry-input">
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
										<input type="text" id="first_name" name="first_name" class="data-entry-input" value="#encodeForHtml(first_name)#" aria-labelledby="first_name_label" >
									</div>
									<div class="col-12 col-md-3">
										<label for="middle_name" class="data-entry-label" id="middle_name_label">Middle Name 
											<span class="small">
												(accepts <button type="button" tabindex="-1" aria-hidden="true" class="btn-link border-0 p-0 bg-light" onclick="var e=document.getElementById('middle_name');e.value='='+e.value;">=<span class="sr-only">prefix with equals sign for case insensitive exact match search</span></button>, 
												<button type="button" tabindex="-1" aria-hidden="true" class="btn-link border-0 p-0 bg-light" onclick="var e=document.getElementById('middle_name');e.value='!'+e.value;">!<span class="sr-only">prefix with exclamation point for case insensitive not search</span></button>,
												<button type="button" tabindex="-1" aria-hidden="true" class="btn-link border-0 p-0 bg-light" onclick="var e=document.getElementById('middle_name');e.value='$'+e.value;">$<span class="sr-only">prefix with dollarsign for sounds like search</span></button>,
												NULL, NOT NULL)
											</span>
										</label>
										<input type="text" id="middle_name" name="middle_name" class="data-entry-input" value="#encodeForHtml(middle_name)#" aria-labelledby="middle_name_label" >
									</div>
									<div class="col-12 col-md-3">
										<label for="last_name" class="data-entry-label" id="last_name_label">Last Name 
											<span class="small">
												(accepts <button type="button" tabindex="-1" aria-hidden="true" class="btn-link border-0 p-0 bg-light" onclick="var e=document.getElementById('last_name');e.value='='+e.value;">=<span class="sr-only">prefix with equals sign for case insensitive exact match search</span></button>, 
												<button type="button" tabindex="-1" aria-hidden="true" class="btn-link border-0 p-0 bg-light" onclick="var e=document.getElementById('last_name');e.value='!'+e.value;">!<span class="sr-only">prefix with exclamation point for case insensitive not search</span></button>,
												<button type="button" tabindex="-1" aria-hidden="true" class="btn-link border-0 p-0 bg-light" onclick="var e=document.getElementById('last_name');e.value='$'+e.value;">$<span class="sr-only">prefix with dollarsign for sounds like search</span></button>,
												NULL, NOT NULL)
											</span>
										</label>
										<input type="text" id="last_name" name="last_name" class="data-entry-input" value="#encodeForHtml(last_name)#" aria-labelledby="last_name_label" >
									</div>
									<div class="col-12 col-md-1">
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
										<div class="col-12 col-md-4">
											<label for="agent_remarks" class="data-entry-label" id="agent_remarks_label">Internal Remarks <span class="small">(accepts NULL, NOT NULL)</span></label>
											<input type="text" id="agent_remarks" name="agent_remarks" class="data-entry-input" value="#encodeForHtml(agent_remarks)#" aria-labelledby="agent_remarks_label" >
										</div>
										<div class="col-12 col-md-4">
											<label for="biography" class="data-entry-label" id="biography_label">Biography <span class="small">(accepts NULL, NOT NULL)</span></label>
											<input type="text" id="biography" name="biography" class="data-entry-input" value="#encodeForHtml(biography)#" aria-labelledby="biography_label" >
										</div>
										<div class="col-12 col-md-4">
											<label for="remarks_biography" class="data-entry-label" id="remarks_biography_label">Internal Remarks or Biography</label>
											<input type="text" id="remarks_biography" name="remarks_biography" class="data-entry-input" value="#encodeForHtml(remarks_biography)#" aria-labelledby="remarks_biography_label" >
										</div>
										<div class="col-12 col-md-4">
											<label for="address" class="data-entry-label" id="address_label">Address (Correspondence/Shipping)</label>
											<input type="text" id="address" name="address" class="data-entry-input" value="#encodeForHtml(address)#" aria-labelledby="address_label" >
										</div>
										<div class="col-12 col-md-3">
											<label for="email" class="data-entry-label" id="email_label">Email</label>
											<input type="text" id="email" name="email" class="data-entry-input" value="#encodeForHtml(email)#" aria-labelledby="email_label" >
										</div>
										<div class="col-12 col-md-3">
											<label for="phone" class="data-entry-label" id="phone_label">Phone</label>
											<input type="text" id="phone" name="phone" class="data-entry-input" value="#encodeForHtml(phone)#" aria-labelledby="phone_label" >
										</div>
										<cfif listcontainsnocase(session.roles,"manage_transactions")>
											<cfset vcollmd = "col-md-1">
										<cfelse>
											<cfset vcollmd = "col-md-2">
										</cfif>
										<div class="col-12 #vcollmd#">
											<label for="edited" class="data-entry-label" id="edited_label">Vetted</label>
											<select id="edited" name="edited" class="data-entry-select">
												<option></option>
												<cfif edited EQ 1><cfset sel = "selected='true'"><cfelse><cfset sel = ""></cfif>
												<option value="1" #sel# >Yes *</option>
												<cfif edited EQ 0><cfset sel = "selected='true'"><cfelse><cfset sel = ""></cfif>
												<option value="0" #sel#>No</option>
											</select>
										</div>
										<cfif listcontainsnocase(session.roles,"manage_transactions")>
											<div class="col-12 col-md-1">
												<label for="ranking" class="data-entry-label" id="edited_label">Ranking</label>
												<select id="ranking" name="ranking" class="data-entry-select">
													<option></option>
													<cfif ranking EQ 'none'><cfset sel = "selected='true'"><cfelse><cfset sel = ""></cfif>
													<option value="none" #sel# >None (A)</option>
													<cfif ranking EQ 'any'><cfset sel = "selected='true'"><cfelse><cfset sel = ""></cfif>
													<option value="any" #sel#>Any (B-F)</option>
												</select>
											</div>
										</cfif>
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
												<input name="birth_date" id="birth_date" type="text" class="datetimeinput data-entry-input col-4 col-xl-5" placeholder="start #dateplaceholder#" value="#encodeForHtml(birth_date)#" aria-label="start of range for #dateWord# of birth">
												<div class="col-1 col-xl-1 text-center px-0"><small> to</small></div>
												<label class="data-entry-label sr-only" for="to_birth_date">end of search range for date of birth</label>		
												<input type="text" name="to_birth_date" id="to_birth_date" value="#encodeForHtml(to_birth_date)#" class="datetimeinput col-4 col-xl-4 data-entry-input" placeholder="end #dateplaceholder#" title="end of date range">
											</div>
										</div>
									</cfif>
									<div class="col-12 col-md-4">
										<div class="date row bg-light border pb-2 mb-2 mb-md-0 pt-1 px-0 px-md-1 px-xl-1 mx-0 rounded justify-content-center">
											<label class="data-entry-label px-4 px-md-4 mx-1 mb-0" for="death_date">#dateWord# Of Death</label>
											<input name="death_date" id="death_date" type="text" class="datetimeinput data-entry-input col-4 col-xl-5" placeholder="start #dateplaceholder#" value="#encodeForHtml(death_date)#" aria-label="start of range for #dateWord# of death">
											<div class="col-1 col-xl-1 text-center px-0"><small> to</small></div>
											<label class="data-entry-label sr-only" for="to_death_date">end of search range for #dateWord# of death</label>		
											<input type="text" name="to_death_date" id="to_death_date" value="#encodeForHtml(to_death_date)#" class="datetimeinput col-4 col-xl-4 data-entry-input" placeholder="end #dateplaceholder#" title="end of date range">
										</div>
									</div>
									<div class="col-12 col-md-4">
										<div class="date row bg-light border pb-2 mb-2 mb-md-0 pt-1 px-0 px-md-1 px-xl-1 mx-0 rounded justify-content-center">
											<label class="data-entry-label px-4 px-md-4 mx-1 mb-0" for="collected_date">Dates Collected</label>
											<input name="collected_date" id="collected_date" type="text" class="datetimeinput data-entry-input col-4 col-xl-5" placeholder="start yyyy-mm-dd or yyyy" value="#encodeForHtml(collected_date)#" aria-label="start of range for dates collected">
											<div class="col-1 col-xl-1 text-center px-0"><small> to</small></div>
											<label class="data-entry-label sr-only" for="to_collected_date">end of search range for dates collected</label>
											<input type="text" name="to_collected_date" id="to_collected_date" value="#encodeForHtml(to_collected_date)#" class="datetimeinput col-4 col-xl-4 data-entry-input" placeholder="end yyyy-mm-dd or yyyy" title="end of date range">
										</div>
									</div>
								</div>
								<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
									<div class="form-row mb-2">
										<div class="col-12 col-md-3">
											<label for="collector_collection" class="data-entry-label" id="edited_label">Collector in Collection</label>
											<select id="collector_collection" name="collector_collection" class="data-entry-select">
												<option></option>
												<cfloop query="collections">
													<cfif collector_collection EQ collections.collection_id ><cfset sel = "selected='true'"><cfelse><cfset sel = ""></cfif>
													<option value="#collections.collection_id#" #sel# >#collections.collection_cde#</option>
												</cfloop>
											</select>
										</div>
										<div class="col-12 col-md-3">
											<label for="author_collection" class="data-entry-label" id="edited_label">Author in Collection</label>
											<select id="author_collection" name="author_collection" class="data-entry-select">
												<option></option>
												<cfloop query="collections">
													<cfif author_collection EQ collections.collection_id ><cfset sel = "selected='true'"><cfelse><cfset sel = ""></cfif>
													<option value="#collections.collection_id#" #sel# >#collections.collection_cde#</option>
												</cfloop>
											</select>
										</div>
										<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_transactions")>
											<div class="col-12 col-md-3">
												<label for="trans_agent_collection" class="data-entry-label" id="edited_label">Transactions in Collection</label>
												<select id="trans_agent_collection" name="trans_agent_collection" class="data-entry-select">
													<option></option>
													<cfloop query="collections">
														<cfif trans_agent_collection EQ collections.collection_id ><cfset sel = "selected='true'"><cfelse><cfset sel = ""></cfif>
														<option value="#collections.collection_id#" #sel# >#collections.collection_cde#</option>
													</cfloop>
												</select>
											</div>
											<div class="col-12 col-md-3">
												<label for="permit_agent_role" class="data-entry-label" id="edited_label">Permissions &amp; Rights Role</label>
												<select id="permit_agent_role" name="permit_agent_role" class="data-entry-select">
													<option></option>
													<cfif permit_agent_role EQ 'none'><cfset sel = "selected='true'"><cfelse><cfset sel = ""></cfif>
													<option value="issued by" #sel# >Issued By</option>
													<cfif permit_agent_role EQ 'none'><cfset sel = "selected='true'"><cfelse><cfset sel = ""></cfif>
													<option value="issued to" #sel# >Issued To</option>
													<cfif permit_agent_role EQ 'none'><cfset sel = "selected='true'"><cfelse><cfset sel = ""></cfif>
													<option value="contact" #sel# >Contact Agent</option>
													<cfif permit_agent_role EQ 'any'><cfset sel = "selected='true'"><cfelse><cfset sel = ""></cfif>
													<option value="any" #sel#>Any</option>
												</select>
											</div>
										</cfif>
									</div>
								</cfif>
								<div class="form-row my-2 mx-0">
									<div class="col-12 px-0 pt-2">
										<button class="btn-xs btn-primary px-2 my-2 mr-1" id="searchButton" type="submit" aria-label="Search for agents">Search<span class="fa fa-search pl-1"></span></button>
										<button type="reset" class="btn-xs btn-warning my-2 mr-1" aria-label="Reset search form to inital values" onclick="">Reset</button>
										<button type="button" class="btn-xs btn-warning my-2 mr-1" aria-label="Start a new agent search with a clear form" onclick="window.location.href='#Application.serverRootUrl#/Agents.cfm';" >New Search</button>

										<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_agents")>
											<a class="btn-xs btn-secondary my-2 text-decoration-none" aria-label="Create a new agent" href="/agents/editAgent.cfm?action=new">Create New Agent</a>
										</cfif>
										<cfif isdefined("session.roles") and ( listcontainsnocase(session.roles,"manage_agents") or listcontainsnocase(session.roles,"MANAGE_AGENT_RANKING") or listcontainsnocase(session.roles,"ADMIN_AGENT_RANKING "))>
											<a class="btn btn-xs btn-secondary my-2 text-decoration-none" aria-label="Review pending merges of agent records" href="/Admin/agentMergeReview.cfm">Review Pending Agent Merges</a>
										</cfif>
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
							<div class="row mt-1 mb-0 pt2px pb-0 jqx-widget-header border px-2">
								<h1 class="h4 ml-2 ml-md-1 mt-2 pt3px">
									<span tabindex="0">Results: </span>
									<span class="pr-2 font-weight-normal" id="resultCount"></span>
									<span id="resultLink" class="pr-2 font-weight-normal"></span>
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
								<output id="actionFeedback"  class="btn btn-xs btn-transparent my-2 pt-1 px-2 mx-1 border-0"></output>
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

			var linkIdCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
				var rowData = jQuery("##searchResultsGrid").jqxGrid('getrowdata',row);
				var vetted = rowData['edited'];
				return '<span style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; "><a target="_blank" href="/agents/Agent.cfm?agent_id=' + rowData['agent_id'] + '">'+value+'</a> ' +vetted+ '</span>';
			};
			<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
				var editIdCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
					var rowData = jQuery("##searchResultsGrid").jqxGrid('getrowdata',row);
					var vetted = rowData['edited'];
					return '<span style="margin-top: 6px; float: ' + columnproperties.cellsalign + '; "><a target="_blank" class="ml-1 px-2 btn btn-xs btn-outline-primary" href="/agents/editAgent.cfm?agent_id=' + rowData['agent_id'] + '">Edit</a></span>';
				};
			</cfif>
			<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_transactions")>
				var rankCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
					var rowData = jQuery("##searchResultsGrid").jqxGrid('getrowdata',row);
					var rank = rowData['worstagentrank'];
					var flag = "";
					if (rank=="F") { 
						flag = "&nbsp;<img src='/agents/images/flag-red.svg.png' width='16'>";
					} else if (rank=="D") {
						flag = "&nbsp;<img src='/agents/images/flag-yellow.svg.png' width='16'>";
					} else if (rank=="C") {
						flag = "&nbsp;<img src='/agents/images/flag-yellow.svg.png' width='16'>";
					} else if (rank=="B") {
						flag = "&nbsp;<img src='/agents/images/flag-yellow.svg.png' width='16'>";
					} 
					return '<span style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; ">' + value + flag + '</span>';
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
					$('##saveDialogButton').html('');
					$('##selectModeContainer').hide();
					$('##actionFeedback').html('');
			
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
						timeout: #Application.ajax_timeout#000,  // units not specified, miliseconds? 
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
							<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
								{text: 'Name', datafield: 'agent_name', width: 300, hidable: true, hidden: getColHidProp('agent_name', false), cellsrenderer: linkIdCellRenderer },
								{text: 'ID', datafield: 'agent_id', width:100, hideable: true, hidden: getColHidProp('agent_id', false), cellsrenderer: editIdCellRenderer },
							<cfelse>
								{text: 'ID', datafield: 'agent_id', width:100, hideable: true, hidden: getColHidProp('agent_id', true) },
								{text: 'Name', datafield: 'agent_name', width: 300, hidable: true, hidden: getColHidProp('agent_name', false), cellsrenderer: linkIdCellRenderer },
							</cfif>
							{text: 'Vetted', datafield: 'edited', width: 80, hidable: true, hidden: getColHidProp('edited', false) },
							<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_transactions")>
								{text: 'Rank', datafield: 'worstagentrank', width: 80, hidable: true, hidden: getColHidProp('worstagentrank', false), cellsrenderer: rankCellRenderer },
							</cfif>
							{text: 'Prefix', datafield: 'prefix', width: 60, hidable: true, hidden: getColHidProp('prefix', true) },
							{text: 'First', datafield: 'first_name', width: 100, hidable: true, hidden: getColHidProp('first_name', true) },
							{text: 'Middle', datafield: 'middle_name', width: 100, hidable: true, hidden: getColHidProp('middle_name', true) },
							{text: 'Last', datafield: 'last_name', width: 100, hidable: true, hidden: getColHidProp('last_name', true) },
							{text: 'Suffix', datafield: 'suffix', width: 60, hidable: true, hidden: getColHidProp('suffix', true) },
							{text: 'Type', datafield: 'agent_type', width: 150, hidable: true, hidden: getColHidProp('agent_type', false) },
							{text: 'Birth', datafield: 'birth_date', width:100, hideable: true, hidden: getColHidProp('birth_date', false) },
							{text: 'Death', datafield: 'death_date', width:100, hideable: true, hidden: getColHidProp('death_date', false) },
							{text: 'Collections Scope', datafield: 'collections_scope', width:180, hideable: true, hidden: getColHidProp('collections_scope', true) },
							{text: 'preferred', datafield: 'preferred', width:100, hideable: true, hidden: getColHidProp('preferred', true) },
							{text: 'abbreviation', datafield: 'abbreviation', width:100, hideable: true, hidden: getColHidProp('abbreviation', true) },
							{text: 'acronym', datafield: 'acronym', width:100, hideable: true, hidden: getColHidProp('acronym', true) },
							{text: 'aka', datafield: 'aka', width:100, hideable: true, hidden: getColHidProp('aka', true) },
							{text: 'author', datafield: 'author', width:100, hideable: true, hidden: getColHidProp('author', true) },
							{text: 'second_author', datafield: 'second_author', width:100, hideable: true, hidden: getColHidProp('second_author', true) },
							{text: 'expanded', datafield: 'expanded', width:100, hideable: true, hidden: getColHidProp('expanded', true) },
							{text: 'maiden', datafield: 'maiden', width:100, hideable: true, hidden: getColHidProp('maiden', true) },
							{text: 'married', datafield: 'married', width:100, hideable: true, hidden: getColHidProp('married', true) },
							{text: 'full', datafield: 'full', width:100, hideable: true, hidden: getColHidProp('full', true) },
							{text: 'initials', datafield: 'initials', width:100, hideable: true, hidden: getColHidProp('initials', true) },
							{text: 'initials_plus_last', datafield: 'initials_plus_last', width:100, hideable: true, hidden: getColHidProp('initials_plus_last', true) },
							{text: 'last_plus_initials', datafield: 'last_plus_initials', width:100, hideable: true, hidden: getColHidProp('last_plus_initials', true) },
							<cfif isdefined("session.roles") and listfindnocase(session.roles,"global_admin")>
								{text: 'login', datafield: 'login', width:100, hideable: true, hidden: getColHidProp('login', true) },
							</cfif>
							<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
								{text: 'EmailAddresses', datafield: 'emails', width:150, hideable: true, hidden: getColHidProp('emails', true) },
								{text: 'PhoneNumbers', datafield: 'phones', width:120, hideable: true, hidden: getColHidProp('phones', true) },
							</cfif>
							<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
								{text: 'Guid', datafield: 'agentguid', width:150, hideable: true, hidden: getColHidProp('agentguid', false) },
								{text: 'Remarks', datafield: 'agent_remarks', hideable: true, hidden: getColHidProp('agent_remarks', false) }
							<cfelse>
								{text: 'Guid', datafield: 'agentguid', hideable: true, hidden: getColHidProp('agentguid', false) }
							</cfif>
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
						$('##resultLink').html('<a href="/Agents.cfm?execute=true&' + $('##searchForm :input').filter(function(index,element){return $(element).val()!='';}).serialize() + '">Link to this search</a>');
						$('##showhide').html('<button class="my-2 border rounded" title="hide search form" onclick=" toggleAnySearchForm(\'searchFormDiv\',\'searchFormToggleIcon\'); "><i id="searchFormToggleIcon" class="fas fa-eye-slash"></i></button>');
						gridLoaded('searchResultsGrid','agent');
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

			<cfif isdefined("session.roles") AND listfindnocase(session.roles,"coldfusion_user") >
			function populateSaveSearch() { 
				// set up a dialog for saving the current search.
				var uri = "/Agents.cfm?execute=true&" + $('##searchForm :input').filter(function(index,element){ return $(element).val()!='';}).not(".excludeFromLink").serialize();
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
							class="btn btn-xs btn-secondary mx-1 my-2 px-2" >Save Search</button>
					`);
				</cfif>
				// workaround for menu z-index being below grid cell z-index when grid is created by a loan search.
				// likewise for the popup menu for searching/filtering columns, ends up below the grid cells.
				var maxZIndex = getMaxZIndex();
				$('.jqx-grid-cell').css({'z-index': maxZIndex + 1});
				$('.jqx-grid-group-cell').css({'z-index': maxZIndex + 1});
				$('.jqx-menu-wrapper').css({'z-index': maxZIndex + 2});
				$('##resultDownloadButtonContainer').html('<button id="loancsvbutton" class="btn btn-xs btn-secondary px-2 my-2 mx-1" aria-label="Export results to csv" onclick=" exportGridToCSV(\'searchResultsGrid\', \''+filename+'\'); " >Export to CSV</button>');
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
	
<cfinclude template = "/shared/_footer.cfm">
