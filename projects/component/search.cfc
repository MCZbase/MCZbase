<!---
/projects/component/search.cfc

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
Function getProjectAutocompleteMeta.  Search for projects by name with a substring match on name or description, returning json suitable for jquery-ui autocomplete
 with a _renderItem overriden to display more detail on the picklist, and just the project name as the selected value.

@param term publication name to search for.
@return a json structure containing id and value, with matching projects with matched name in value and project_id in id, and matched name 
  with more information in meta.
--->
<cffunction name="getProjectAutocompleteMeta" access="remote" returntype="any" returnformat="json">
	<cfargument name="term" type="string" required="yes">

	<cfset data = ArrayNew(1)>
	<cftry>
      <cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="search_result">
			SELECT 
				project_id, project_name, project_description,
				start_date, end_date
			FROM 
				project
			WHERE
				upper(project_name) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(term)#%">
				OR
				upper(project_description) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(term)#%">
		</cfquery>
	<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfset row["id"] = "#search.project_id#">
			<cfset row["value"] = "#search.project_name#" >
			<cfset row["meta"] = "#search.project_name# (#search.start_date# - #search.end_date#)" >
			<cfset data[i]  = row>
			<cfset i = i + 1>
		</cfloop>
		<cfreturn #serializeJSON(data)#>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset message = trim("Error processing #GetFunctionCalledName()#: " & cfcatch.message & " " & cfcatch.detail & " " & queryError)  >
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

<cffunction name="getProjects"  access="remote" returntype="any" returnformat="json">
	<cfargument name="project_title" type="string" required="no">
	<cfargument name="project_participant" type="string" required="no">
	<cfargument name="project_sposor" type="string" required="no">
	<cfargument name="project_year" type="string" required="no">
	<cfargument name="project_type" type="string" required="no">
	<cfargument name="min_proj_desc_length" type="string" required="no">

	<cfset data = ArrayNew(1)>

	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="search_result" timeout="#Application.query_timeout#">
				SELECT distinct
					project.project_id,
					project.project_name,
					project.start_date,
					project.end_date,
					agent_name.agent_name,
					project_agent_role,
					agent_position,
					ACKNOWLEDGEMENT,
					s_name.agent_name sponsor_name
				FROM
					project
					left join project_agent on project.project_id = project_agent.project_id
					left join agent_name on project_agent.agent_name_id = agent_name.agent_name_id
					left join project_sponsor on project.project_id = project_sponsor.project_id
					left join agent_name s_name on project_sponsor.agent_name_id = s_name.agent_name_id
				WHERE
					project.project_id is not null
					<cfif isdefined("project_title") AND len(project_title) gt 0>
						<cfset title = "#project_title#">
						<cfset go="yes">
						AND upper(regexp_replace(project.project_name,'<[^>]*>')) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(escapeQuotes(project_title))#%">
					</cfif>
					<cfif isdefined("min_proj_desc_length") AND len(min_proj_desc_length) gt 0>
						<cfset go="yes">
						AND project.project_description is not null and length(project.project_description) >= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#min_proj_desc_length#">
					</cfif>
					<cfif isdefined("project_participant") AND len(project_participant) gt 0>
						<cfset go="yes">
						AND project.project_id IN
							( select project_id FROM project_agent
								WHERE agent_name_id IN
								( select agent_name_id FROM agent_name WHERE
								upper(agent_name) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#escapeQuotes(ucase(project_participant))#%"> ))
					</cfif>
					<cfif isdefined("project_type") AND len(project_type) gt 0>
						<cfset go="yes">
						<cfif project_type is "loan">
							AND project.project_id in (
							select project_id from project_trans,loan_item
							where project_trans.transaction_id=loan_item.transaction_id)
						<cfelseif project_type is "accn">
							AND project.project_id in (
								select project_id from project_trans,cataloged_item
								where project_trans.transaction_id=cataloged_item.accn_id)
						<cfelseif project_type is "both">
							AND project.project_id in (
								select project_id from project_trans,loan_item
								where project_trans.transaction_id=loan_item.transaction_id)
							AND project.project_id in (
								select project_id from project_trans,cataloged_item
								where project_trans.transaction_id=cataloged_item.accn_id)
						<cfelseif project_type is "neither">
							AND project.project_id not in (
								select project_id from project_trans,loan_item
								where project_trans.transaction_id=loan_item.transaction_id)
							AND project.project_id not in (
								select project_id from project_trans,cataloged_item
								where project_trans.transaction_id=cataloged_item.accn_id)
						<cfelseif project_type is "loan_no_pub">
							AND project.project_id in (
								select project_id from project_trans,loan_item
								where project_trans.transaction_id=loan_item.transaction_id)
							AND project.project_id not in (
								select project_id from project_publication)
						</cfif>
					</cfif>
					<cfif isdefined("project_sponsor") AND len(#project_sponsor#) gt 0>
						<cfset go="yes">
						AND project.project_id IN
						( select project_id FROM project_sponsor
							WHERE agent_name_id IN
							( select agent_name_id FROM agent_name WHERE
							upper(agent_name) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(project_sponsor)#%"> ))
					</cfif>
					<cfif isdefined("project_year") AND isnumeric(#project_year#)>
						<cfset go="yes">
							AND (
							 <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#project_year#"> between to_number(to_char(start_date,'YYYY')) AND to_number(to_char(end_date,'YYYY'))
							)
					</cfif>
					<cfif isdefined("publication_id") AND len(#publication_id#) gt 0>
						<cfset go="yes">
						AND project.project_id in
							(select project_id from project_publication where publication_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">)
					</cfif>
					<cfif isdefined("project_id") AND len(#project_id#) gt 0>
						<cfset go="yes">
						AND project.project_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#project_id#">
					</cfif>
					<cfif go is "no">
						AND 1=2
					</cfif>
				ORDER BY project_name
		</cfquery>
	<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfloop list="#ArrayToList(search.getColumnNames())#" index="col" >
				<cfset row["#lcase(col)#"] = "#search[col][currentRow]#">
			</cfloop>
			<cfset data[i]  = row>
			<cfset i = i + 1>
		</cfloop>
		<cfreturn #serializeJSON(data)#>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn #serializeJSON(data)#>
</cffunction>



</cfcomponent>
