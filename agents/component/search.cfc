<!---
agents/component/search.cfc

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

--->
<cfcomponent>

<!---
Function getAgentList.  Search for agents by name with a substring match on any name, returning json suitable for a dataadaptor.

@param name agent name to search for.
@return a json structure containing matching agents with matched names, preferred names, types, edited states, and links.
--->
<cffunction name="getAgentList" access="remote" returntype="any" returnformat="json">
	<cfargument name="name" type="string" required="yes">
	<!--- perform wildcard search anywhere in agent_name.agent_name --->
	<cfset name = "%#name#%"> 

	<cfset data = ArrayNew(1)>
	<cftry>
      <cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			SELECT 
				searchname.agent_id, searchname.agent_name, searchname.agent_name_type,
				agent.agent_type, agent.edited,
				prefername.agent_name as preferred_agent_name
			FROM 
				agent_name searchname
				left join agent on searchname.agent_id = agent.agent_id
				left join agent_name prefername on agent.preferred_agent_name_id = prefername.agent_name_id
			WHERE
				searchname.agent_name like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#name#">
		</cfquery>
	<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfif search.edited EQ 1 ><cfset edited_marker="*"><cfelse><cfset edited_marker=""></cfif> 
			<cfset row["agent_id"] = "#search.agent_id#">
			<cfset row["agent_name"] = "#search.agent_name#">
			<cfset row["agent_name_type"] = "#search.agent_name_type#">
			<cfset row["agent_type"] = "#search.agent_type#">
			<cfset row["edited"] = "#search.edited#">
			<cfset row["preferred_agent_name"] = "#search.preferred_agent_name#">
			<cfif search.preferred_agent_name EQ search.agent_name >
				<cfset row["id_link"] = "<a href='/agents/Agent.cfm?agent_id#search.agent_id#' target='_blank'>#search.agent_name# #edited_marker#</a>">
			<cfelse>
				<cfset row["id_link"] = "<a href='/agents/Agent.cfm?agent_id#search.agent_id#' target='_blank'>#search.agent_name# (#search.preferred_agent_name#)#edited_marker#</a>">
			</cfif>
			<cfset data[i]  = row>
			<cfset i = i + 1>
		</cfloop>
		<cfreturn #serializeJSON(data)#>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset message = trim("Error processing getAgentList: " & cfcatch.message & " " & cfcatch.detail & " " & queryError)  >
		<cfheader statusCode="500" statusText="#message#">
			<cfoutput>
				<div class="container">
					<div class="row">
						<div class="alert alert-danger" role="alert">
							<img src="/shared/images/Process-stop.png" alt="[ unauthorized access ]" style="float:left; width: 50px;margin-right: 1em;">
							<h2>Internal Server Error.</h2>
							<p>#message#</p>
							<p><a href="/info/bugs.cfm">“Feedback/Report Errors”</a></p>
						</div>
					</div>
				</div>
			</cfoutput>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn #serializeJSON(data)#>
</cffunction>

<!---
Function getAgentAutocomplete.  Search for agents by name with a substring match on any name, returning json suitable for jquery-ui autocomplete.

@param term agent name to search for.
@return a json structure containing id and value, with matching agents with matched name in value and agent_id in id.
--->
<cffunction name="getAgentAutocomplete" access="remote" returntype="any" returnformat="json">
	<cfargument name="term" type="string" required="yes">
	<!--- perform wildcard search anywhere in agent_name.agent_name --->
	<cfset name = "%#term#%"> 

	<cfset data = ArrayNew(1)>
	<cftry>
      <cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			SELECT 
				searchname.agent_id, searchname.agent_name, searchname.agent_name_type,
				agent.agent_type, agent.edited,
				prefername.agent_name as preferred_agent_name
			FROM 
				agent_name searchname
				left join agent on searchname.agent_id = agent.agent_id
				left join agent_name prefername on agent.preferred_agent_name_id = prefername.agent_name_id
			WHERE
				upper(searchname.agent_name) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(name)#">
		</cfquery>
	<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfif search.edited EQ 1 ><cfset edited_marker="*"><cfelse><cfset edited_marker=""></cfif> 
			<cfset row["id"] = "#search.agent_id#">
			<cfif search.preferred_agent_name EQ search.agent_name >
				<cfset row["value"] = "#search.agent_name# #edited_marker#" >
			<cfelse>
				<cfset row["value"] = "#search.agent_name# (#search.preferred_agent_name#)#edited_marker#" >
			</cfif>
			<cfset data[i]  = row>
			<cfset i = i + 1>
		</cfloop>
		<cfreturn #serializeJSON(data)#>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset message = trim("Error processing getAgentList: " & cfcatch.message & " " & cfcatch.detail & " " & queryError)  >
		<cfheader statusCode="500" statusText="#message#">
			<cfoutput>
				<div class="container">
					<div class="row">
						<div class="alert alert-danger" role="alert">
							<img src="/shared/images/Process-stop.png" alt="[ unauthorized access ]" style="float:left; width: 50px;margin-right: 1em;">
							<h2>Internal Server Error.</h2>
							<p>#message#</p>
							<p><a href="/info/bugs.cfm">“Feedback/Report Errors”</a></p>
						</div>
					</div>
				</div>
			</cfoutput>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn #serializeJSON(data)#>
</cffunction>

<!---
Function getAgentAutocompleteMeta.  Search for agents by name with a substring match on any name, returning json suitable for jquery-ui autocomplete
 with a _renderItem overriden to display more detail on the picklist, and just the agent name as the selected value.

@param term agent name to search for.
@return a json structure containing id and value, with matching agents with matched name in value and agent_id in id, and matched name 
  with * and preferred name in meta.
--->
<cffunction name="getAgentAutocompleteMeta" access="remote" returntype="any" returnformat="json">
	<cfargument name="term" type="string" required="yes">
	<!--- perform wildcard search anywhere in agent_name.agent_name --->
	<cfset name = "%#term#%"> 

	<cfset data = ArrayNew(1)>
	<cftry>
      <cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			SELECT 
				searchname.agent_id, searchname.agent_name, searchname.agent_name_type,
				agent.agent_type, agent.edited,
				prefername.agent_name as preferred_agent_name
			FROM 
				agent_name searchname
				left join agent on searchname.agent_id = agent.agent_id
				left join agent_name prefername on agent.preferred_agent_name_id = prefername.agent_name_id
			WHERE
				upper(searchname.agent_name) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(name)#">
		</cfquery>
	<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfif search.edited EQ 1 ><cfset edited_marker="*"><cfelse><cfset edited_marker=""></cfif> 
			<cfset row["id"] = "#search.agent_id#">
			<cfset row["value"] = "#search.preferred_agent_name#" >
			<cfif search.preferred_agent_name EQ search.agent_name >
				<cfset row["meta"] = "#search.agent_name# #edited_marker#" >
			<cfelse>
				<cfset row["meta"] = "#search.agent_name# (#search.preferred_agent_name#)#edited_marker#" >
			</cfif>
			<cfset data[i]  = row>
			<cfset i = i + 1>
		</cfloop>
		<cfreturn #serializeJSON(data)#>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset message = trim("Error processing getAgentList: " & cfcatch.message & " " & cfcatch.detail & " " & queryError)  >
		<cfheader statusCode="500" statusText="#message#">
			<cfoutput>
				<div class="container">
					<div class="row">
						<div class="alert alert-danger" role="alert">
							<img src="/shared/images/Process-stop.png" alt="[ unauthorized access ]" style="float:left; width: 50px;margin-right: 1em;">
							<h2>Internal Server Error.</h2>
							<p>#message#</p>
							<p><a href="/info/bugs.cfm">“Feedback/Report Errors”</a></p>
						</div>
					</div>
				</div>
			</cfoutput>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn #serializeJSON(data)#>
</cffunction>

</cfcomponent>
