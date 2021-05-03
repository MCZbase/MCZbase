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
		<cfset action = "newAgent">
	</cfif>
</cfif>

<cfswitch expression="#action#">
<cfcase value="editAgent">
	<cfset pageTitle = "Edit Agent">
</cfcase>
<cfcase value="newAgent">
	<cfset pageTitle = "New Agent">
	<cfif isDefined("agent_type") AND len(agent_type) GT 0>
		<cfset curAgentType = agent_type>
	<cfelse>
		<cfset curAgentType = 'person'>
	</cfif>
</cfcase>
<cfcase value="createAgent">
	<cfset pageTitle = "Saving New Agent">
</cfcase>
</cfswitch>

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
<cfcase value="newAgent">
	<cfoutput>
		<main class="container py-3" id="content">
			<cfif isdefined("agent_type") and len(agent_type) GT 0>
				<h2>Create new #encodeForHtml(agent_type)# Agent.</h2>
			<cfelse>
				<h2>Create new Agent.</h2>
			</cfif>
			<section class="row border rounded my-2 px-1 pt-1 pb-2">
				<form id="newAgentForm">
					<input type="hidden" name="action" value="createAgent">
					<div class="row">
						<div class="col-12 col-md-4">
							<script>
								function changeType() { 
									var selectedType = $('##agent_type').val();
									if (selectedType == 'person') { 
										$('##personRow').show();
										$('##last_name').prop('required',true);
									} else { 
										$('##personRow').hide();
										$('##last_name').removeAttr('required');
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
						<div class="col-12 col-md-8">
							<label for="pref_name" class="data-entry-label">Preferred Name</label>
							<input type="text" name="pref_name" id="pref_name" class="data-entry-input reqdClr" required>
							<!--- TODO: Add test for unique preferred name --->
						</div>
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
					<div id="personRow" class="row">
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
							<label for="middle_name"class="data-entry-label">Middle Name</label>
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
						<div class="col-12">
							<label for="agentguid"class="data-entry-label">GUID for Agent</label>
							<cfset pattern = "">
							<cfset placeholder = "">
							<cfset regex = "">
							<cfset replacement = "">
							<cfset searchlink = "" >
							<cfset searchtext = "" >
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
							<a href="#searchlink#" id="agentguid_search" target="_blank">#searchtext#</a>
							<input size="55" name="agentguid" id="agentguid" value="" placeholder="#placeholder#" pattern="#pattern#" title="Enter a guid in the form #placeholder#">
							<a id="agentguid_link" href="" target="_blank" class="hints"></a>
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
					<div class="row">
						<div class="col-12 col-md-3">
							<input type="submit" value="Add Person" class="savBtn">
						</div>
					</div>
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
			FROM cfagent_type 
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
						<cfif len(#agentguid_guid_type#) gt 0>
							,agentguid_guid_type
						</cfif>
						<cfif len(#agentguid#) gt 0>
							,agentguid
						</cfif>
					) VALUES (
						<cfqueryparam cfsqltype='CF_SQL_DECIMAL' value='#agentID.nextAgentId#'>,
						<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value="#agent_type#">
						<cfqueryparam cfsqltype='CF_SQL_DECIMAL' value='#agentNameID.nextAgentNameId#'>
						<cfif len(#agentguid_guid_type#) gt 0>
							,<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value="#agentguid_guid_type#">
						</cfif>
						<cfif len(#agentguid#) gt 0>
							,<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value="#agentguid#">
						</cfif>
					)
				</cfquery>
				<cfif agent_type EQ 'person'>
					<cfquery name="insPerson" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						INSERT INTO person (
							PERSON_ID
							<cfif len(#prefix#) gt 0>
								,prefix
							</cfif>
							<cfif len(#LAST_NAME#) gt 0>
								,LAST_NAME
							</cfif>
							<cfif len(#FIRST_NAME#) gt 0>
								,FIRST_NAME
							</cfif>
							<cfif len(#MIDDLE_NAME#) gt 0>
								,MIDDLE_NAME
							</cfif>
							<cfif len(#SUFFIX#) gt 0>
								,SUFFIX
							</cfif>
						) VALUES (
							<cfqueryparam cfsqltype='CF_SQL_DECIMAL' value="#agentID.nextAgentId#">
							<cfif len(#prefix#) gt 0>
								,<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#prefix#'>
							</cfif>
							<cfif len(#LAST_NAME#) gt 0>
								,<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#LAST_NAME#'>
							</cfif>
							<cfif len(#FIRST_NAME#) gt 0>
								,<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#FIRST_NAME#'>
							</cfif>
							<cfif len(#MIDDLE_NAME#) gt 0>
								,<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#MIDDLE_NAME#'>
							</cfif>
							<cfif len(#SUFFIX#) gt 0>
								,<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#SUFFIX#'>
							</cfif>
						)
					</cfquery>
				</cfif>
				<cfif len(pref_name) is 0>
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
				<cfif not isdefined("ignoreDupChek") or ignoreDupChek is false>
					<cfquery name="dupPref" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select agent.agent_type,agent_name.agent_id,agent_name.agent_name
						from agent_name, agent
						where agent_name.agent_id = agent.agent_id
							and upper(agent_name.agent_name) like <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='%#ucase(pref_name)#%'>
					</cfquery>
					<cfif dupPref.recordcount gt 0>
						<!---- TODO: Change potential duplicate handling --->
						<cfthrow message="Unable to create agent Duplcate preferred name [#encodeForHtml(pref_name)#].">
						<!---
						<div style="padding: 1em;width: 75%;">
							<h3>That agent may already exist!</h3>
							<p>The name you entered is either a preferred name or other name for an existing agent.</p>
							<p>A duplicated preferred name will prevent MCZbase from functioning normally. </p>
							<p>Click duplicated names below to see details. Add the fullest version of the name if it can be differentiated from another. If the need for a duplicate agent should arise, please merge the pre-existing matches (bad duplicates) so they will not create problems.</p>
							<cfloop query="dupPref">
								<br><a href="/info/agentActivity.cfm?agent_id=#agent_id#">#agent_name# (agent ID ## #agent_id# - #agent_type#)</a>
							</cfloop>
							<p>Are you sure you want to continue?</p>
							<form name="ac" method="post" action="/agents/editAgent.cfm">
								<input type="hidden" name="action" value="newAgent">
								<input type="hidden" name="prefix" value="#prefix#">
								<input type="hidden" name="LAST_NAME" value="#LAST_NAME#">
								<input type="hidden" name="FIRST_NAME" value="#FIRST_NAME#">
								<input type="hidden" name="MIDDLE_NAME" value="#MIDDLE_NAME#">
								<input type="hidden" name="SUFFIX" value="#SUFFIX#">
								<input type="hidden" name="pref_name" value="#pref_name#">
								<input type="hidden" name="ignoreDupChek" value="true">
								<input type="submit" class="insBtn" value="Create Agent">
							</form>
							<br><br>
							<input type="cancel" value="Cancel" class="insBtn" style="background-color: ##ffcc00;border: 1px solid ##336666; width: 42px;" onclick="javascript:window.location='';return false;">
							<cfabort>
						</div>
						--->
					</cfif>
				</cfif>
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
				<cflocation url="editAllAgent.cfm?agent_id=#agentID.nextAgentId#">
			<cfcatch>
				<cftransaction action="rollback">
			</cfcatch>
			</cftry>
		</cftransaction>
	</cfoutput>
</cfcase>
</cfswitch>

<cfinclude template = "/shared/_footer.cfm">
