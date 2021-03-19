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

<!--- function getAgents search for agents returning json suitable for a jqxgrid --->
<cffunction name="getAgents" access="remote" returntype="any" returnformat="json">
	<cfargument name="first_name" type="string" required="no">
	<cfargument name="last_name" type="string" required="no">
	<cfargument name="middle_name" type="string" required="no">
	<cfargument name="suffix" type="string" required="no">
	<cfargument name="prefix" type="string" required="no">
	<cfargument name="birth_date" type="string" required="no">
	<cfargument name="death_date" type="string" required="no">
	<cfargument name="birthOper" type="string" required="no">
	<cfargument name="deathOper" type="string" required="no">
	<cfargument name="anyName" type="string" required="no">
	<cfargument name="agent_id" type="string" required="no">
	<cfargument name="address" type="string" required="no">

	<cfif not isDefined("birthOper")><cfset birthOper="="></cfif>
	<cfif not isDefined("deathOper")><cfset deathOper="="></cfif>

	<cfset data = ArrayNew(1)>
	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			SELECT distinct
				preferred_agent_name.agent_id as agent_id,
				preferred_agent_name.agent_name as agent_name,
				agent_type,
				agent.edited,
				MCZBASE.get_worstagentrank(agent.agent_id) as worstagentrank,
				birth_date,
				death_date
			FROM 
				agent_name
				left outer join preferred_agent_name ON (agent_name.agent_id = preferred_agent_name.agent_id)
				LEFT OUTER JOIN agent ON (agent_name.agent_id = agent.agent_id)
				LEFT OUTER JOIN person ON (agent.agent_id = person.person_id)
			WHERE
				agent.agent_id > -1
				and rownum<500
				<cfif isdefined("First_Name") AND len(#First_Name#) gt 0>
					AND first_name LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#First_Name#">
				</cfif>
				<cfif isdefined("Last_Name") AND len(#Last_Name#) gt 0>
					AND Last_Name LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#last_name#">
				</cfif>
				<cfif isdefined("Middle_Name") AND len(#Middle_Name#) gt 0>
					AND Middle_Name LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#Middle_Name#">
				</cfif>
				<cfif isdefined("Suffix") AND len(#Suffix#) gt 0>
					AND Suffix = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#Suffix#">
				</cfif>
				<cfif isdefined("Prefix") AND len(#Prefix#) gt 0>
					AND Prefix = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#Prefix#">
				</cfif>
				<cfif isdefined("Birth_Date") AND len(#Birth_Date#) gt 0>
					<cfset bdate = dateformat(birth_date,'yyyy-mm-dd')>
					AND Birth_Date 
						<cfif birthOper IS "<="> <= <cfelseif birthOper IS ">="> >= <cfelse> = </cfif>
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#bdate#">
				</cfif>
				<cfif isdefined("Death_Date") AND len(#Death_Date#) gt 0>
					<cfset ddate = #dateformat(Death_Date,'yyyy-mm-dd')#>
					AND Death_Date 
						<cfif deathOper IS "<="> <= <cfelseif deathOper IS ">="> >= <cfelse> = </cfif>
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ddate#">
				</cfif>
				<cfif isdefined("anyName") AND len(#anyName#) gt 0>
					AND upper(agent_name.agent_name) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(anyName)#%">
				</cfif>
				<cfif isdefined("agent_id") AND isnumeric(#agent_id#)>
					AND agent_name.agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
				</cfif>
				<cfif isdefined("address") AND len(#address#) gt 0>
					AND agent.agent_id IN (
						select agent_id from addr where upper(formatted_addr) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(address)#%">
					)
				</cfif>
			ORDER BY preferred_agent_name.agent_name
		</cfquery>
		<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfif search.edited EQ 1 ><cfset edited_marker="*"><cfelse><cfset edited_marker=""></cfif> 
			<cfset row["agent_id"] = "#search.agent_id#">
			<cfset row["agent_name"] = "#search.agent_name#">
			<cfset row["agent_type"] = "#search.agent_type#">
			<cfset row["edited"] = "#search.edited#">
			<cfset row["preferred_agent_name"] = "#search.agent_name#">
			<cfset row["worstagentrank"] = "#search.worstagentrank#">
			<cfset row["birth_date"] = "#search.birth_date#">
			<cfset row["death_date"] = "#search.death_date#">
			<cfset row["id_link"] = "<a href='/agents/Agent.cfm?agent_id#search.agent_id#' target='_blank'>#search.agent_name# #edited_marker#</a>">
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
				searchname.agent_id, searchname.agent_name, 
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
	<cfargument name="constraint" type="string" required="no">
	<!--- perform wildcard search anywhere in agent_name.agent_name --->
	<cfset name = "%#term#%"> 

	<cfset data = ArrayNew(1)>
	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			SELECT distinct
				searchname.agent_id, searchname.agent_name,
				agent.agent_type, agent.edited,
				prefername.agent_name as preferred_agent_name
			FROM 
				agent_name searchname
				left join agent on searchname.agent_id = agent.agent_id
				left join agent_name prefername on agent.preferred_agent_name_id = prefername.agent_name_id
				<cfif isdefined("constraint") AND constraint EQ 'permit_issued_by_agent'>
					left join permit on agent.agent_id = permit.issued_by_agent_id
				</cfif>
				<cfif isdefined("constraint") AND constraint EQ 'permit_issued_to_agent'>
					left join permit on agent.agent_id = permit.issued_to_agent_id
				</cfif>
				<cfif isdefined("constraint") AND constraint EQ 'permit_contact_agent'>
					left join permit on agent.agent_id = permit.contact_agent_id
				</cfif>
				<cfif isdefined("constraint") AND constraint EQ 'transaction_agent'>
					left join trans_agent on agent.agent_id = trans_agent.agent_id
				</cfif>
				<cfif isdefined("constraint") AND constraint EQ 'project_agent'>
					left join project_agent on searchname.agent_name_id = trans_agent.agent_name_id
				</cfif>
			WHERE
				upper(searchname.agent_name) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(name)#">
				<cfif isdefined("constraint") AND (constraint EQ 'permit_issued_to_agent' or constraint EQ 'permit_issued_by_agent' or constraint EQ 'permit_contact_agent' )>
					AND permit.permit_id is not null
				</cfif>
				<cfif isdefined("constraint") AND constraint EQ 'transaction_agent'>
					AND trans_agent.trans_agent_id is not null
				</cfif>
				<cfif isdefined("constraint") AND constraint EQ 'project_agent'>
					AND project_agent.project_id is not null
				</cfif>
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
