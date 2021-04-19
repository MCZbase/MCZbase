<cfset pageTitle = "Agent Details">
<!--
agents/Agent.cfm

Form for displaying agent details, editing agent details, and creating new agents.

Copyright 2020 President and Fellows of Harvard College

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
	<!--- if no action was given, but an agent_id was given, then assume we want agent details, otherwise newAgent form. --->
	<cfif isdefined("agent_id")>
		<cfset action = "agentDetails">
		<cfif len(agent_id) GT 0 and REFind("^[0-9]*$",agent_id) EQ 0>
			<cfinclude template="/errors/autoblacklist.cfm">
			<cfabort>
		</cfif>
	<cfelse>
		<cfset action = "newAgent">
	</cfif>
</cfif>

<cfswitch expression="#action#">
<cfcase value="agentDetails">
	<cfset pageTitle = "Agent Details">
</cfcase>
<cfcase value="editAgent">
	<cfset pageTitle = "Edit Agent">
</cfcase>
<cfcase value="newAgent">
	<cfset pageTitle = "New Agent">
</cfcase>
</cfswitch>

<cfinclude template = "/shared/_header.cfm">

<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
	<cfset oneOfUs = 1>
<cfelse>
	<cfset oneOfUs = 0>
</cfif>
<cfquery name="ctguid_type_agent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select guid_type, placeholder, pattern_regex, resolver_regex, resolver_replacement, search_uri
   from ctguid_type 
   where applies_to like '%agent.agentguid%'
</cfquery>


<cfswitch expression="#action#">
<cfcase value="agentDetails">
	<cfif NOT isdefined("agent_id")>
		<cfoutput>
			<!--- TODO: Throw exception or otherwise make into error message --->
			<h2>No Agent ID provided</h2>
		</cfoutput>
	<cfelse>
		<!--- TODO: Add full implementation of agent details. --->
		<cfquery name="getAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			SELECT 
				agent.agent_type, agent.edited, 
				agent_remarks, 
				agentguid_guid_type, agentguid,
				prefername.agent_name as preferred_agent_name
			FROM 
				agent
				left join agent_name prefername on agent.preferred_agent_name_id = prefername.agent_name_id
			WHERE
				agent.agent_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#agent_id#">
		</cfquery>

		<cfoutput>
			<div class="container">
				<div class="row">
					<div id="agentDiv" class="col-12 my-4">
				<cfloop query="getAgent">
					<cfif getAgent.edited EQ 1 ><cfset edited_marker="*"><cfelse><cfset edited_marker=""></cfif> 
					<h2>#preferred_agent_name# #edited_marker#</h2>
					<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_agents")>
						<a href="/agents.cfm?agent_id=#agent_id#" class="btn btn-primary">Edit</a>
					</cfif>
					<ul class="mt-3 list-unstyled">
						<li>#agent_type#</li>
						<cfif len(agentguid) GT 0>
							<cfif len(ctguid_type_agent.resolver_regex) GT 0>
								<cfset guidLink = REReplace(agentguid,ctguid_type_agent.resolver_regex,ctguid_type_agent.resolver_replacement) >
							<cfelse>
								<cfset guidLink = agentguid >
							</cfif>
							<li><a href="#guidLink#">#agentguid#</a></li>
						</cfif>
					</ul>
					<cfif oneOfUs EQ 1>
						<div>#agent_remarks#</div>
					</cfif>
					<cfif oneOfUs EQ 1>
						<cfquery name="getAgentElecAddr" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							select address_type, address 
							from electronic_address 
							WHERE
								electronic_address.agent_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#agent_id#">
							order by address_type
						</cfquery>
						<cfif getAgentElecAddr.recordcount GT 0>
							<div>
								<h2 class="h3">Phone/Email</h2>
								<ul>
									<cfloop query="getAgentElecAddr">
										<li>#address_type#: #address#</li>
									</cfloop>
								</ul>
							</div>
						</cfif>
					</cfif>
					<cfif oneOfUs EQ 1>
						<cfquery name="getAgentAddr" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							select addr_type, REPLACE(formatted_addr, CHR(10),'<br>') FORMATTED_ADDR
							from addr
							WHERE
								addr.agent_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#agent_id#">
							order by addr_type
						</cfquery>
						<cfif getAgentAddr.recordcount GT 0>
							<div>
								<h2 class="h3">Postal Addresses</h2>
								<cfloop query="getAgentAddr">
									<h3 class="h4">#addr_type# address</h3>
									<div>#formatted_addr#</div>
								</cfloop>
							</div>
						</cfif>
					</cfif>
					<cfquery name="getAgentRel" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select agent_relationship, related_agent_id, MCZBASE.get_agentnameoftype(related_agent_id) as related_name
						from agent_relations 
						WHERE
							agent_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#agent_id#">
							and agent_relationship not like '% duplicate of'
						order by agent_relationship
					</cfquery>
					<cfif getAgentRel.recordcount GT 0>
						<div>
							<h2 class="h3">Relationships to other agents</h2>
							<ul>
							<cfloop query="getAgentRel">
								<li>#agent_relationship# <a href="/agents/Agent.cfm?agent_id=#related_agent_id#">#related_name#</a></li>
							</cfloop>
							</ul>
						</div>
					</cfif>
					<cfif oneOfUs EQ 1>
						<cfquery name="getRevAgentRel" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							select agent_relationship, agent_id as related_agent_id, MCZBASE.get_agentnameoftype(agent_id) as related_name
							from agent_relations 
							WHERE
								related_agent_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#agent_id#">
								and agent_relationship not like '% duplicate of'
							order by agent_relationship
						</cfquery>
						<cfif getRevAgentRel.recordcount GT 0>
							<div>
								<h2 class="h3">Relationships from other agents</h2>
								<ul>
								<cfloop query="getRevAgentRel">
									<li><a href="/agents/Agent.cfm?agent_id=#related_agent_id#">#related_name#</a> #agent_relationship# #getAgent.preferred_agent_name# </li>
								</cfloop>
								</ul>
							</div>
						</cfif>
					</cfif>
				</cfloop>
					</div>
				</div>
			</div>
		</cfoutput>
		
	</cfif>
</cfcase>
<cfcase value="editAgent">
	<cfif NOT isdefined("agent_id")>
		<cfoutput>
			<!--- TODO: Throw exception or otherwise make into error message --->
			<h2>No Agent ID provided</h2>
		</cfoutput>
	<cfelse>
		<cfoutput>
			<!--- TODO: Implement--->
			<h2>Edit agent not yet implemented.</h2>
		</cfoutput>
	</cfif>
</cfcase>
<cfcase value="newAgent">
		<cfoutput>
			<!--- TODO: Implement--->
			<h2>New agent not yet implemented.</h2>
		</cfoutput>
</cfcase>
</cfswitch>

<cfinclude template = "/shared/_footer.cfm">
