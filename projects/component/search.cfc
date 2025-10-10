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
		<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
			<cfset oneOfUs = 1>
		<cfelse>
			<cfset oneOfUs = 0>
		</cfif>
      <cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="search_result">
			SELECT 
				project_id, project_name, project_description,
				start_date, end_date
			FROM 
				project
			WHERE
				(
				upper(project_name) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(term)#%">
				OR
				upper(project_description) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(term)#%">
				)
				<cfif oneOfUs NEQ 1>
					AND project.mask_project_fg = 0
				</cfif>
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

</cfcomponent>
