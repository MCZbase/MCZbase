<cfset pageTitle = "Agent Management">
<!--
agents/editAgent.cfm

Form for editing agent details and creating new agents.

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

-->

<!--- if we were given an action, use that, and let errors arise if requirements for action weren't met. --->
<cfif NOT isdefined("action")>
	<!--- if no action was given, but an agent_id was given, then assume we want to edit the agent, otherwise newAgent form. --->
	<cfif isdefined("agent_id")>
		<cfset action = "editAgent">
		<cfif len(agent_id) GT 0 and REFind("^[0-9]*$",agent_id) EQ 0>
			<cfinclude template="/errors/autoblacklist.cfm">
			<cfabort>
		</cfif>
	<cfelse>
		<cfset action = "new">
	</cfif>
<cfelse>
	<!--- support old api call --->
	<cfif action IS "newAgent"><cfset action = "new"></cfif>
</cfif>

<!--- TODO: Temporary test for non-production deployment, remove when ready --->
<cftry>
	<!--- assuming a git repository and readable by coldfusion, determine the checked out branch by reading HEAD --->
	<cfset gitBranch = FileReadLine(FileOpen("#Application.webDirectory#/.git/HEAD", "read"))>
<cfcatch>
	<cfset gitBranch = "unknown">
</cfcatch>
</cftry>
<cfset Session.gitBranch = gitBranch>
<cfif findNoCase('master',Session.gitBranch) GT 0>
	<cfthrow message="Page not ready for production use.">
</cfif>

<cfswitch expression="#action#">
<cfcase value="editAgent">
	<cfset pageTitle = "Edit Agent">
</cfcase>
<cfcase value="new">
	<cfset pageTitle = "New Agent">
	<cfif isDefined("agent_type") AND len(agent_type) GT 0>
		<cfset curAgentType = agent_type>
	<cfelse>
		<!--- default expectations of the new agent page are that a person is being created, and a change of agent type hides the person elements. --->
		<cfset curAgentType = 'person'>
	</cfif>
</cfcase>
<cfcase value="createAgent">
	<cfset pageTitle = "Saving New Agent">
</cfcase>
</cfswitch>

<cfset includeJQXEditor='true'>
<cfinclude template = "/shared/_header.cfm">

<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
	<cfset oneOfUs = 1>
<cfelse>
	<cfset oneOfUs = 0>
</cfif>
<cfquery name="ctAgentType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select agent_type from ctagent_type order by agent_type
</cfquery>
<cfquery name="ctNameType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select agent_name_type as agent_name_type from ctagent_name_type where agent_name_type != 'preferred' order by agent_name_type
</cfquery>
<cfquery name="ctAddrType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select addr_type from ctaddr_type
	where addr_type <> 'temporary'
</cfquery>
<cfquery name="ctElecAddrType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select address_type from ctelectronic_addr_type
</cfquery>
<cfquery name="ctprefix" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select prefix from ctprefix order by prefix
</cfquery>
<cfquery name="ctsuffix" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select suffix from ctsuffix order by suffix
</cfquery>
<cfquery name="ctRelns" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select AGENT_RELATIONSHIP from CTAGENT_RELATIONSHIP
</cfquery>
<cfquery name="ctguid_type_agent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select guid_type, placeholder, pattern_regex, resolver_regex, resolver_replacement, search_uri
   from ctguid_type 
   where applies_to like '%agent.agentguid%'
</cfquery>

<cfswitch expression="#action#">
<cfcase value="editAgent">
	<cfif NOT isdefined("agent_id")>
		<cfoutput>
			<cfthrow message="Agent to edit not specified.  No Agent ID provided">
		</cfoutput>
	<cfelse>
		<cfoutput>
			<main class="container py-3" id="content">
				<cfquery name="getAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getAgent_result">
					SELECT 
						agent.agent_type, agent.edited, 
						agent_remarks, 
						biography,
						agentguid_guid_type, agentguid,
						prefername.agent_name as preferred_agent_name
					FROM 
						agent
						left join agent_name prefername on agent.preferred_agent_name_id = prefername.agent_name_id
					WHERE
						agent.agent_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#agent_id#">
				</cfquery>
				<cfif getAgent.recordcount EQ 0>
					<h2>No such agent as agent_id = #encodeForHtml(agent_id)#.</h2>
				<cfelse>
					<cfloop query="getAgent">
						<cfif getAgent.edited EQ 1><cfset vetted="*"><cfelse><cfset vetted=""></cfif>
						<h2>Edit agent #getAgent.preferred_agent_name# #vetted# (#getAgent.agent_type#).</h2>
						<section class="row border rounded my-2 px-1 pt-1 pb-2">
							<!--- TODO: Implement--->
							<h2>Edit agent not yet implemented.</h2>
						</section>
					</cfloop>
				</cfif>
			</main>
		</cfoutput>
	</cfif>
</cfcase>
<cfcase value="new">
	<cfoutput>
		<script>
			function getAssembledName() {
				var result = "";
				if ($('##last_name').val()!="") {
					result = $('##last_name').val();
				}
				if ($('##middle_name').val()!="") {
					result = $('##middle_name').val() + " " + result;
				}
				if ($('##first_name').val()!="") {
					result = $('##first_name').val() + " " + result;
				}
				return result;
			}
		</script>
		<main class="container py-3" id="content">
			<cfif isdefined("agent_type") and len(agent_type) GT 0>
				<h2>Create new <span id="headingTypeSpan">#encodeForHtml(agent_type)#</span> Agent.</h2>
			<cfelse>
				<h2>Create new <span id="headingTypeSpan"></span> Agent.</h2>
			</cfif>
			<section class="border rounded my-2 px-1 pt-1 pb-2">
				<form id="newAgentForm" name="newAgentForm" method="post" action="/agents/editAgent.cfm">
					<input type="hidden" name="action" value="createAgent">
					<div class="row">
						<div class="col-12 col-md-4">
							<script>
								function changeType() { 
									var selectedType = $('##agent_type').val();
									if (selectedType == 'person') { 
										$('##personRow').show();
										$('##headingTypeSpan').html("Person");
										$('##last_name').prop('required',true);
										$('##start_date_label').html("Date of Birth");
										$('##end_date_label').html("Date of Death");
										$('##start_date').prop('disabled', false);
										$('##end_date').prop('disabled', false);
									} else { 
										$('##personRow').hide();
										$('##headingTypeSpan').html(selectedType);
										$('##last_name').removeAttr('required');
										$('##start_date_label').html("Start Date");
										$('##end_date_label').html("End Date");
										$('##start_date').prop('disabled', true);
										$('##end_date').prop('disabled', true);
									}
								}
							</script>
							<label for="agent_type" class="data-entry-label">Type of Agent</label>
							<select name="agent_type" id="agent_type" size="1" onChange=" changeType(); " class="data-entry-select">
								<cfloop query="ctAgentType">
									<cfif isdefined("curAgentType") and len(curAgentType) GT 0 and curAgentType IS ctAgentType.agent_type>
										<cfset selected = "selected='selected'">
									<cfelse>
										<cfset selected = "">
									</cfif>
									<option value="#ctAgentType.agent_type#" #selected#>#ctAgentType.agent_type#</option>
								</cfloop>
							</select>
						</div>
						<div class="col-12 col-md-6">
							<label for="pref_name" class="data-entry-label">Preferred Name</label>
							<input type="text" name="pref_name" id="pref_name" class="data-entry-input reqdClr" required>
							<script>
								$(document).ready(function () {
									$('##pref_name').change(function () {
										checkPrefNameExists($('##pref_name').val(),'name_matches');
									});
								});
							</script>
						</div>
						<div class="col-12 col-md-2">
							<label for="name_matches" class="data-entry-label">Duplicate check</label>
							<div id="name_matches"></div>
						</div>
					</div>
					<div id="personRow" class="row">
						<!--- we'll load the page as if for a new person, and if not a new person, will hide this row. --->
						<div class="col-12 col-md-2">
							<label for="prefix" class="data-entry-label">Prefix</label>
							<select name="prefix" id="prefix" size="1" class="data-entry-select">
								<option value=""></option>
								<cfloop query="ctprefix">
									<option value="#prefix#">#prefix#</option>
								</cfloop>
							</select>
						</div>
						<div class="col-12 col-md-3">
							<label for="first_name"class="data-entry-label">First Name</label>
							<input type="text" name="first_name" id="first_name"class="data-entry-input">
						</div>
						<div class="col-12 col-md-2">
							<label for="middle_name" class="data-entry-label">Middle Name</label>
							<input type="text" name="middle_name" id="middle_name"class="data-entry-input">
						</div>
						<div class="col-12 col-md-3">
							<cfif curAgentType EQ "person"><cfset req="required"><cfelse><cfset req=""></cfif>
							<label for="last_name"class="data-entry-label">Last Name</label>
							<input type="text" name="last_name" id="last_name" class="data-entry-input reqdClr" #req#>
						</div>
						<div class="col-12 col-md-2">
							<label for="suffix"class="data-entry-label">Suffix</label>
							<select name="suffix" size="1" id="suffix" class="data-entry-select">
								<option value=""></option>
								<cfloop query="ctsuffix">
									<option value="#suffix#">#suffix#</option>
								</cfloop>
						  	</select>
						</div>
					</div>
					<div id="guids" class="row">
						<div class="col-12 col-md-6">
							<label for="agentguid"class="data-entry-label">GUID for Agent</label>
							<cfset pattern = "">
							<cfset placeholder = "">
							<cfset regex = "">
							<cfset replacement = "">
							<cfset searchlink = "" >
							<cfset searchtext = "" >
							<div class="col-6 col-xl-3 px-0 float-left">
								<select name="agentguid_guid_type" id="agentguid_guid_type" size="1" class="data-entry-select">
									<cfif searchtext EQ "">
										<option value=""></option>
									</cfif>
									<cfloop query="ctguid_type_agent">
										<cfset sel="">
										<cfif ctguid_type_agent.recordcount EQ 1 >
											<cfset sel="selected='selected'">
											<cfset placeholder = "#ctguid_type_agent.placeholder#">
											<cfset pattern = "#ctguid_type_agent.pattern_regex#">
											<cfset regex = "#ctguid_type_agent.resolver_regex#">
											<cfset replacement = "#ctguid_type_agent.resolver_replacement#">
										</cfif>
										<option #sel# value="#ctguid_type_agent.guid_type#">#ctguid_type_agent.guid_type#</option>
									</cfloop>
								</select>
							</div>
							<div class="col-6 col-xl-3 w-100 px-0 float-left"> 
								<a href="#searchlink#" id="agentguid_search" target="_blank" style="font-size: 86%;">#searchtext#</a>
							</div>
							<div class="col-12 col-xl-6 pl-0 float-left">
								<input class="data-entry-input" name="agentguid" id="agentguid" 
									value="" placeholder="#placeholder#" pattern="#pattern#" title="Enter a guid in the form #placeholder#">
								<a id="agentguid_link" href="" target="_blank" class="px-1 py-0 d-block line-height-sm mt-1" style="font-size: 86%;"></a> 
							</div>
						<script>
							$(document).ready(function () {
								if ($('##agentguid').val().length > 0) {
									$('##agentguid').hide();
								}
								$('##agentguid_search').click(function (evt) {
									switchGuidEditToFind('agentguid','agentguid_search','agentguid_link',evt);
								});
								$('##agentguid_guid_type').change(function () {
									// On selecting a guid_type, remove an existing guid value.
									$('##agentguid').val("");
									// On selecting a guid_type, change the pattern.
									getGuidTypeInfo($('##agentguid_guid_type').val(), 'agentguid', 'agentguid_link','agentguid_search',getAssembledName());
								});
								$('##agentguid').blur( function () {
									// On loss of focus for input, validate against the regex, update link
									getGuidTypeInfo($('##agentguid_guid_type').val(), 'agentguid', 'agentguid_link','agentguid_search',getAssembledName());
								});
								$('##first_name').change(function () {
									// On changing prefered name, update search.
									getGuidTypeInfo($('##agentguid_guid_type').val(), 'agentguid', 'agentguid_link','agentguid_search',getAssembledName());
								});
								$('##middle_name').change(function () {
									// On changing prefered name, update search.
									getGuidTypeInfo($('##agentguid_guid_type').val(), 'agentguid', 'agentguid_link','agentguid_search',getAssembledName());
								});
								$('##last_name').change(function () {
									// On changing prefered name, update search.
									getGuidTypeInfo($('##agentguid_guid_type').val(), 'agentguid', 'agentguid_link','agentguid_search',getAssembledName());
								});
							});
						</script>
						</div>
						<div class="col-12 col-md-3">
							<cfif curAgentType EQ "person">
								<cfset label="Date of Birth">
							<cfelse>
								<cfset label="Start Date">
							</cfif>
							<label id="start_date_label" for="start_date" class="data-entry-label">#label#</label>
							<input type="text" name="start_date" id="start_date"class="data-entry-input" placeholder="yyyy, yyyy-mm-dd, or yyyy-mm">
						</div>
						<div class="col-12 col-md-3">
							<cfif curAgentType EQ "person">
								<cfset label="Date of Birth">
							<cfelse>
								<cfset label="End Date">
							</cfif>
							<label id="end_date_label" for="end_date" class="data-entry-label">#label#</label>
							<input type="text" name="end_date" id="end_date"class="data-entry-input" placeholder="yyyy, yyyy-mm-dd, or yyyy-mm">
						</div>
						<script>
							$(document).ready(function() {
								$("##start_date").datepicker({ dateFormat: 'yy-mm-dd'});
								$("##end_date").datepicker({ dateFormat: 'yy-mm-dd'});
							});
						</script>
					</div>
					<div class="row">
						<div class="col-12">
							<label for="biography" class="data-entry-label">Public Biography</label>
							<textarea name="biography" id="biography" class="w-100"></textarea>
							<script>
								$(document).ready(function () {
									$('##biography').jqxEditor();
								});
							</script>
						</div>
					</div>
					<div class="row">
						<div class="col-12">
							<label for="agent_remarks" class="data-entry-label">Internal Remarks</label>
							<textarea name="agent_remarks" id="agent_remarks" class="w-100"></textarea>
							<script>
								$(document).ready(function () {
									$('##agent_remarks').jqxEditor();
								});
							</script>
						</div>
					</div>
					<div class="row">
						<div class="col-12 col-md-3">
							<input type="submit" value="Add New Agent" class="btn btn-xs btn-primary">
						</div>
					</div>
					<cfif isdefined("curAgentType") and len(curAgentType) GT 0 and curAgentType IS "person">
						<!--- no action needed, this is the default load state for this form --->
					<cfelse>
						<!--- change elements appropriately --->
						<script>
							$(document).ready(function () {
								$('##agent_remarks').changeType();
							});
						</script>
					</cfif>
				</form>
			</section>
		</main>
	</cfoutput>
</cfcase>
<cfcase value="createAgent">
	<!--- TODO: Implement save new agent record --->
	<cfoutput>
		<cfquery name="agentTypeCheck" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			SELECT agent_type 
			FROM ctagent_type 
			WHERE agent_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#agent_type#">
		</cfquery>
		<cfif agentTypeCheck.recordcount NEQ 1>
			<cfthrow message="Unable to create agent.  Unknown agent type [#encodeForHtml(agent_type)#]">
		</cfif>
		<cftransaction>
			<cftry>
				<cfquery name="agentID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select sq_agent_id.nextval nextAgentId from dual
				</cfquery>
				<cfquery name="agentNameID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select sq_agent_name_id.nextval nextAgentNameId from dual
				</cfquery>
				<cfquery name="insAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					INSERT INTO agent (
						agent_id,
						agent_type,
						preferred_agent_name_id
						<cfif isdefined("agentguid_guid_type") AND len(#agentguid_guid_type#) GT 0>
							,agentguid_guid_type
						</cfif>
						<cfif isdefined("agentguid") AND len(#agentguid#) gt 0>
							,agentguid
						</cfif>
						<cfif isdefined("agent_remarks") AND len(#agent_remarks#) gt 0>
							,agent_remarks
						</cfif>
						<cfif isdefined("biography") AND len(#biography#) gt 0>
							,biography
						</cfif>
					) VALUES (
						<cfqueryparam cfsqltype='CF_SQL_DECIMAL' value='#agentID.nextAgentId#'>,
						<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value="#agent_type#">,
						<cfqueryparam cfsqltype='CF_SQL_DECIMAL' value='#agentNameID.nextAgentNameId#'>
						<cfif isdefined("agentguid_guid_type") AND len(#agentguid_guid_type#) gt 0>
							,<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value="#agentguid_guid_type#">
						</cfif>
						<cfif isdefined("agentguid") AND len(#agentguid#) gt 0>
							,<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value="#agentguid#">
						</cfif>
						<cfif isdefined("agent_remarks") AND len(#agent_remarks#) gt 0>
							,<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value="#agent_remarks#">
						</cfif>
						<cfif isdefined("biography") AND len(#biography#) gt 0>
							,<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value="#biography#">
						</cfif>
					)
				</cfquery>
				<cfif agent_type EQ 'person'>
					<cfquery name="insPerson" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						INSERT INTO person (
							PERSON_ID
							<cfif isdefined("prefix") AND len(#prefix#) gt 0>
								,prefix
							</cfif>
							<cfif isdefined("LAST_NAME") AND len(#LAST_NAME#) gt 0>
								,LAST_NAME
							</cfif>
							<cfif isdefined("FIRST_NAME") AND len(#FIRST_NAME#) gt 0>
								,FIRST_NAME
							</cfif>
							<cfif isdefined("MIDDLE_NAME") AND len(#MIDDLE_NAME#) gt 0>
								,MIDDLE_NAME
							</cfif>
							<cfif isdefined("SUFFIX") AND len(#SUFFIX#) gt 0>
								,SUFFIX
							</cfif>
							<cfif isdefined("start_date") AND len(#start_date#) gt 0>
								,birth_date
							</cfif>
							<cfif isdefined("end_date") AND len(#end_date#) gt 0>
								,death_date
							</cfif>
						) VALUES (
							<cfqueryparam cfsqltype='CF_SQL_DECIMAL' value="#agentID.nextAgentId#">
							<cfif isdefined("prefix") AND len(#prefix#) gt 0>
								,<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#prefix#'>
							</cfif>
							<cfif isdefined("LAST_NAME") AND len(#LAST_NAME#) gt 0>
								,<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#LAST_NAME#'>
							</cfif>
							<cfif isdefined("FIRST_NAME") AND len(#FIRST_NAME#) gt 0>
								,<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#FIRST_NAME#'>
							</cfif>
							<cfif isdefined("MIDDLE_NAME") AND len(#MIDDLE_NAME#) gt 0>
								,<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#MIDDLE_NAME#'>
							</cfif>
							<cfif isdefined("SUFFIX") AND len(#SUFFIX#) gt 0>
								,<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#SUFFIX#'>
							</cfif>
							<cfif isdefined("start_date") AND len(#start_date#) gt 0>
								,<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#start_date#'>
							</cfif>
							<cfif isdefined("end_date") AND len(#end_date#) gt 0>
								,<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#end_date#'>
							</cfif>
						)
					</cfquery>
				</cfif>
				<cfif len(pref_name) is 0>
					<!--- unused block, preferred name is required field on form --->
					<cfset name = "">
					<cfif len(#prefix#) gt 0>
						<cfset name = "#name# #prefix#">
					</cfif>
					<cfif len(#FIRST_NAME#) gt 0>
						<cfset name = "#name# #FIRST_NAME#">
					</cfif>
					<cfif len(#MIDDLE_NAME#) gt 0>
						<cfset name = "#name# #MIDDLE_NAME#">
					</cfif>
					<cfif len(#LAST_NAME#) gt 0>
						<cfset name = "#name# #LAST_NAME#">
					</cfif>
					<cfif len(#SUFFIX#) gt 0>
						<cfset name = "#name# #SUFFIX#">
					</cfif>
					<cfset pref_name = #trim(name)#>
				</cfif>
				<cfquery name="duplicatePreferredCheck" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT agent_name.agent_name, agent_name.agent_id 
					FROM agent_name
					WHERE 
						agent_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#pref_name#">
				</cfquery>
				<cfif duplicatePreferredCheck.recordcount gt 0>
					<!--- outright prevent creation of agents that duplicate the preferred name of other agents --->
					<cfthrow message="Unable to create agent: Duplicate preferred name [#encodeForHtml(pref_name)#].">
				</cfif>
				<cfset okToAddAgent = true>
				<cfif not isdefined("ignoreDupCheck") or ignoreDupCheck is false>
					<!--- allow possible optional creation of agents that duplicate other names names of other agents --->
					<cfquery name="findPotentialDups" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select agent.agent_type,agent_name.agent_id,agent_name.agent_name
						from agent_name, agent
						where agent_name.agent_id = agent.agent_id
							and upper(agent_name.agent_name) like <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='%#ucase(pref_name)#%'>
					</cfquery>
					<cfif findPotentialDups.recordcount gt 0>
						<!--- potential duplicates exist, require confirmation before continuing --->
						<!--- continuing involves resubmission of this action on this page from the form below, rollback the transaction and skip further inserts --->
						<cftransaction action="rollback">
						<cfset okToAddAgent = false>
						<main class="container py-3" id="content">
							<h2 class="h3">The agent <a href="/agents/Agents.cfm?execute=true&anyName=#encodeForURL(pref_name)#" target="_blank">#encodeForHTML(pref_name)#</a> may already exist.</h2>
							<section class="border rounded my-2 px-1 pt-1 pb-2">
								<div class="row">
									<div class="col-12">
										<p>The name you entered is already exists as a name (other than a preferred name) for an existing agent.</p>
										<p>Click duplicated names below to see details. Add the fullest version of the name if it can be differentiated from another. If the need for a duplicate agent should arise, please merge the pre-existing matches (bad duplicates) so they will not create problems.</p>
									</div>
									<div class="col-12">
										<ul>
											<cfloop query="findPotentialDups">
												<li><a href="/info/agentActivity.cfm?agent_id=#agent_id#">#agent_name#</a> (agent ID ## #agent_id# - #agent_type#)</li>
											</cfloop>
										</ul>
									</div>
									<div class="col-12">
										<label for="createAnywayButton">Do you still want to create this Agent?</p>
										<form name="ac" method="post" action="/agents/editAgent.cfm">
											<input type="hidden" name="action" value="new">
											<input type="hidden" name="prefix" value="#prefix#">
											<input type="hidden" name="LAST_NAME" value="#LAST_NAME#">
											<input type="hidden" name="FIRST_NAME" value="#FIRST_NAME#">
											<input type="hidden" name="MIDDLE_NAME" value="#MIDDLE_NAME#">
											<input type="hidden" name="SUFFIX" value="#SUFFIX#">
											<input type="hidden" name="pref_name" value="#pref_name#">
											<input type="hidden" name="ignoreDupChek" value="true">
											<input type="submit" class="btn btn-xs btn-warning" value="Create Agent" id="createAnywayButton">
										</form>
									</div>
								</div>
							</section>
						</main>
					</cfif>
				</cfif>
				<cfif okToAddAgent IS true>
					<!--- finish creating the agent record by adding a preferred name, and then committing the transaction --->
					<!--- NOTE: Retaining donor_card_fg_present_fg for now, this likely indicates names created through the MCZbase coldfusion UI as opposed to loads of data --->
					<cfquery name="insName" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						INSERT INTO agent_name (
							agent_name_id,
							agent_id,
							agent_name_type,
							agent_name,
							donor_card_present_fg)
						VALUES (
							<cfqueryparam cfsqltype='CF_SQL_DECIMAL' value="#agentNameID.nextAgentNameId#">,
							<cfqueryparam cfsqltype='CF_SQL_DECIMAL' value="#agentID.nextAgentId#">,
							'preferred',
							<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#pref_name#'>,
							0
						)
					</cfquery>
					<cftransaction action="commit">
					<!--- TODO redirect to redesiged edit agent page --->
					<cflocation url="/editAllAgent.cfm?agent_id=#agentID.nextAgentId#">
				</cfif>
			<cfcatch>
				<cftransaction action="rollback">
				<section class="container">
					<cfif cfcatch.message contains "Duplicate preferred name">
						<div class="row">
							<div class="alert alert-danger" role="alert">
								<img src="/shared/images/Process-stop.png" alt="[ Error ]" style="float:left; width: 50px;margin-right: 1em;">
								<h1 class="h2">#encodeForHtml(cfcatch.message)#<h1>
								<p>You cannot create a new agent record with a preferred name that duplicates an existing preferred name.</p>
								<p></p>
								<p><a href="/agents/Agents.cfm?execute=true&anyName=#encodeForURL(pref_name)#">Search for Agents with this name</a></p>
							</div>
						</div>
					<cfelse>
						<div class="row">
							<div class="alert alert-danger" role="alert">
								<img src="/shared/images/Process-stop.png" alt="[ Error ]" style="float:left; width: 50px;margin-right: 1em;">
								<h1 class="h2">Creation of new agent record failed.<h1>
								<p>There was an error creating this taxon record, please file a bug report describing the problem.</p>
								<p><a href="/info/bugs.cfm">“Feedback/Report Errors”</a></p>
							</div>
						</div>
						<p><cfdump var=#cfcatch#></p>
					</cfif>
				</section>
			</cfcatch>
			</cftry>
		</cftransaction>
	</cfoutput>
</cfcase>
</cfswitch>

<cfinclude template = "/shared/_footer.cfm">
