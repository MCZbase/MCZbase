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
										related_agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
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
							<cfquery name="getAgentCollScope" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getAgentCollScope_result">
								select sum(ct) as ct, collection_cde, collection_id, sum(st) as startyear, sum(en) as endyear 
								from (
									select count(*) ct, flat.collection_cde, flat.collection_id, to_number(min(substr(flat.began_date,0,4))) st, to_number(max(substr(flat.ended_date,0,4))) en
									from agent
										left join collector on agent.agent_id = collector.AGENT_ID
										left join <cfif session.flatTableName EQ "flat">flat<cfelse>filtered_flat</cfif> flat
											on collector.COLLECTION_OBJECT_ID = flat.collection_object_id
									where collector.COLLECTOR_ROLE = 'c'
										and substr(flat.began_date,0,4) = substr(flat.ENDED_DATE,0,4)
										and agent.agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
									group by flat.collection_cde, flat.collection_id
									union
									select count(*) ct, flat.collection_cde, flat.collection_id, 0 as st, 0 as en
									from agent
										left join collector on agent.agent_id = collector.AGENT_ID
										left join <cfif session.flatTableName EQ "flat">flat<cfelse>filtered_flat</cfif> flat
											on collector.COLLECTION_OBJECT_ID = flat.collection_object_id
									where collector.COLLECTOR_ROLE = 'c'
										and (flat.began_date is null or substr(flat.began_date,0,4) <> substr(flat.ENDED_DATE,0,4))
										and agent.agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
									group by flat.collection_cde, flat.collection_id, 0
								) 
								group by collection_cde, collection_id
							</cfquery>
							<cfif getAgentCollScope.recordcount EQ 0>
								<div>
									<h2 class="h3">Not a collector of any material in MCZbase</h2>
								</div>
							<cfelse>
								<cfloop query="getAgentCollScope">
									<div>
										<h2 class="h3">Collector of</h2>
										<ul>
										<cfloop query="getAgentCollScope">
											<li>#getAgentCollScope.collection_cde# (<a href="/SpecimenResults.cfm?collector_agent_id=#agent_id#&collection_id=#getAgentCollScope.collection_id#" target="_blank">#getAgentCollScope.ct# records</a>) in years #getAgentCollScope.startyear#-#getAgentCollScope.endyear#</li>
										</cfloop>
										</ul>
									</div>
								</cfloop>
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
		<cfif isdefined("agent_type") and len(agent_type) GT 0>
			<h2>Create new #encodeForHtml(agent_type)# Agent.</h2>
			<cfswitch expression="#agent_type#">
				<cfcase value="person">
				<form name="newPerson" action="editAllAgent.cfm" method="post" target="_person">
					<input type="hidden" name="Action" value="insertPerson">
					<label for="prefix">Prefix</label>
					<select name="prefix" id="prefix" size="1">
						<option value=""></option>
						<cfloop query="ctprefix">
							<option value="#prefix#">#prefix#</option>
						</cfloop>
					</select>
					<label for="first_name">First Name</label>
					<input type="text" name="first_name" id="first_name">
					<label for="middle_name">Middle Name</label>
					<input type="text" name="middle_name" id="middle_name">
					<label for="last_name">Last Name</label>
					<input type="text" name="last_name" id="last_name" class="reqdClr">
					<label for="suffix">Suffix</label>
					<select name="suffix" size="1" id="suffix">
						<option value=""></option>
						<cfloop query="ctsuffix">
							<option value="#suffix#">#suffix#</option>
						</cfloop>
			    	</select>
					<label for="pref_name">Preferred Name</label>
					<input type="text" name="pref_name" id="pref_name">

					<div class="detailCell">
						<label for="agentguid">GUID for Agent</label>
						<cfset pattern = "">
						<cfset placeholder = "">
						<cfset regex = "">
						<cfset replacement = "">
						<cfset searchlink = "" >
						<cfset searchtext = "" >
						<select name="agentguid_guid_type" id="agentguid_guid_type" size="1">
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
						<input type="submit" value="Add Person" class="savBtn">
					</div>
				</form>
				</cfcase>
				<cfdefaultcase>
					<h2>Type Not implemented yet.</h2>
				</cfdefaultcase>
			</cfswitch>
		<cfelse>
			<h2>Create new Agent.</h2>
		</cfif>
		<!--- TODO: Implement--->
	</cfoutput>
</cfcase>
</cfswitch>

<cfinclude template = "/shared/_footer.cfm">
