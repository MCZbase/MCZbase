<!---
/projects/component/search.cfc

Copyright 2020-2026 President and Fellows of Harvard College

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
<cfinclude template="/shared/component/error_handler.cfc" runOnce="true">

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
		<cfset error_message = cfcatchToErrorMessage(cfcatch)>
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn #serializeJSON(data)#>
</cffunction>

<!---
Function search. Search for projects matching any combination of name, participant,
sponsor, minimum description length, project type, year, publication, or project_id. Any
argument may be left blank; if all arguments are blank, returns every project visible to
the caller. Returns one row per matching project, ordered by project_name.

@param p_title substring to match against project_name.
@param participant_agent_id restrict to projects with this agent as a participant; takes
	precedence over participant_agent_name when both are provided (matches the rich agent
	picker's own id-first-else-name-substring convention, e.g. Publications.cfm's Author).
@param participant_agent_name substring to match against a participant's agent_name, used
	only when participant_agent_id is blank.
@param sponsor_agent_id restrict to projects with this agent as a sponsor; takes precedence
	over sponsor_agent_name when both are provided.
@param sponsor_agent_name substring to match against a sponsor's agent_name, used only when
	sponsor_agent_id is blank.
@param project_type one of "loan" (uses specimens), "loan_no_pub" (uses specimens, no
	linked publication), "accn" (contributes specimens), "both" (uses and contributes),
	"neither" (neither uses nor contributes).
@param year a year that must fall between the project's start_date and end_date.
@param descr_len minimum length, in characters, of project_description.
@param publication_id restrict results to projects linked to this publication.
@param project_id restrict results to this specific project.
@return a JSON array of structs, one per matching project: project_id, project_name,
	start_date, end_date ('YYYY-MM-DD', or "" if null), participants, sponsors (both
	semicolon-separated display strings, or "" if none).
--->
<cffunction name="search" access="remote" returntype="any" returnformat="json">
	<cfargument name="p_title" type="string" required="no" default="">
	<cfargument name="participant_agent_id" type="string" required="no" default="">
	<cfargument name="participant_agent_name" type="string" required="no" default="">
	<cfargument name="sponsor_agent_id" type="string" required="no" default="">
	<cfargument name="sponsor_agent_name" type="string" required="no" default="">
	<cfargument name="project_type" type="string" required="no" default="">
	<cfargument name="year" type="string" required="no" default="">
	<cfargument name="descr_len" type="string" required="no" default="">
	<cfargument name="publication_id" type="string" required="no" default="">
	<cfargument name="project_id" type="string" required="no" default="">

	<cfset data = ArrayNew(1)>
	<cftry>
		<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
			<cfset oneOfUs = 1>
		<cfelse>
			<cfset oneOfUs = 0>
		</cfif>

		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="search_result">
			SELECT
				project.project_id,
				project.project_name,
				TO_CHAR(project.start_date,'YYYY-MM-DD') AS start_date,
				TO_CHAR(project.end_date,'YYYY-MM-DD') AS end_date,
				(
					SELECT LISTAGG(agent_name.agent_name || ' (' || project_agent.project_agent_role || ')', '; ')
						WITHIN GROUP (ORDER BY project_agent.agent_position)
					FROM
						project_agent
						JOIN agent_name ON project_agent.agent_name_id = agent_name.agent_name_id
					WHERE
						project_agent.project_id = project.project_id
				) AS participants,
				(
					SELECT LISTAGG(sponsor_name.agent_name, '; ') WITHIN GROUP (ORDER BY sponsor_name.agent_name)
					FROM
						project_sponsor
						JOIN agent_name sponsor_name ON project_sponsor.agent_name_id = sponsor_name.agent_name_id
					WHERE
						project_sponsor.project_id = project.project_id
				) AS sponsors
			FROM
				project
			WHERE
				project.project_id IS NOT NULL
				<cfif oneOfUs NEQ 1>
					AND project.mask_project_fg = 0
				</cfif>
				<cfif len(arguments.p_title) GT 0>
					AND UPPER(REGEXP_REPLACE(project.project_name,'<[^>]*>')) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(arguments.p_title)#%">
				</cfif>
				<cfif len(arguments.descr_len) GT 0 AND isnumeric(arguments.descr_len)>
					AND project.project_description IS NOT NULL
					AND LENGTH(project.project_description) >= <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.descr_len#">
				</cfif>
				<cfif len(arguments.participant_agent_id) GT 0 AND isnumeric(arguments.participant_agent_id)>
					AND project.project_id IN (
						SELECT project_agent.project_id
						FROM project_agent
						WHERE project_agent.agent_name_id IN (
							SELECT agent_name_id FROM agent_name
							WHERE agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.participant_agent_id#">
						)
					)
				<cfelseif len(arguments.participant_agent_name) GT 0>
					AND project.project_id IN (
						SELECT project_agent.project_id
						FROM
							project_agent
							JOIN agent_name ON project_agent.agent_name_id = agent_name.agent_name_id
						WHERE
							UPPER(agent_name.agent_name) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(arguments.participant_agent_name)#%">
					)
				</cfif>
				<cfif len(arguments.sponsor_agent_id) GT 0 AND isnumeric(arguments.sponsor_agent_id)>
					AND project.project_id IN (
						SELECT project_sponsor.project_id
						FROM project_sponsor
						WHERE project_sponsor.agent_name_id IN (
							SELECT agent_name_id FROM agent_name
							WHERE agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.sponsor_agent_id#">
						)
					)
				<cfelseif len(arguments.sponsor_agent_name) GT 0>
					AND project.project_id IN (
						SELECT project_sponsor.project_id
						FROM
							project_sponsor
							JOIN agent_name ON project_sponsor.agent_name_id = agent_name.agent_name_id
						WHERE
							UPPER(agent_name.agent_name) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(arguments.sponsor_agent_name)#%">
					)
				</cfif>
				<cfif len(arguments.project_type) GT 0>
					<cfif arguments.project_type EQ "loan">
						AND project.project_id IN (
							SELECT project_trans.project_id FROM project_trans, loan_item
							WHERE project_trans.transaction_id = loan_item.transaction_id)
					<cfelseif arguments.project_type EQ "accn">
						AND project.project_id IN (
							SELECT project_trans.project_id FROM project_trans, cataloged_item
							WHERE project_trans.transaction_id = cataloged_item.accn_id)
					<cfelseif arguments.project_type EQ "both">
						AND project.project_id IN (
							SELECT project_trans.project_id FROM project_trans, loan_item
							WHERE project_trans.transaction_id = loan_item.transaction_id)
						AND project.project_id IN (
							SELECT project_trans.project_id FROM project_trans, cataloged_item
							WHERE project_trans.transaction_id = cataloged_item.accn_id)
					<cfelseif arguments.project_type EQ "neither">
						AND project.project_id NOT IN (
							SELECT project_trans.project_id FROM project_trans, loan_item
							WHERE project_trans.transaction_id = loan_item.transaction_id)
						AND project.project_id NOT IN (
							SELECT project_trans.project_id FROM project_trans, cataloged_item
							WHERE project_trans.transaction_id = cataloged_item.accn_id)
					<cfelseif arguments.project_type EQ "loan_no_pub">
						AND project.project_id IN (
							SELECT project_trans.project_id FROM project_trans, loan_item
							WHERE project_trans.transaction_id = loan_item.transaction_id)
						AND project.project_id NOT IN (
							SELECT project_publication.project_id FROM project_publication)
					</cfif>
				</cfif>
				<cfif len(arguments.year) GT 0 AND isnumeric(arguments.year)>
					AND <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.year#">
						BETWEEN TO_NUMBER(TO_CHAR(project.start_date,'YYYY')) AND TO_NUMBER(TO_CHAR(project.end_date,'YYYY'))
				</cfif>
				<cfif len(arguments.publication_id) GT 0 AND isnumeric(arguments.publication_id)>
					AND project.project_id IN (
						SELECT project_publication.project_id FROM project_publication
						WHERE project_publication.publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.publication_id#">)
				</cfif>
				<cfif len(arguments.project_id) GT 0 AND isnumeric(arguments.project_id)>
					AND project.project_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.project_id#">
				</cfif>
			ORDER BY
				project.project_name
		</cfquery>

		<cfloop query="search">
			<cfset row = StructNew()>
			<cfset row["project_id"] = project_id>
			<cfset row["project_name"] = project_name>
			<cfset row["start_date"] = start_date>
			<cfset row["end_date"] = end_date>
			<cfset row["participants"] = participants>
			<cfset row["sponsors"] = sponsors>
			<cfset ArrayAppend(data, row)>
		</cfloop>

		<cfreturn #serializeJSON(data)#>
	<cfcatch>
		<cfset error_message = cfcatchToErrorMessage(cfcatch)>
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn #serializeJSON(data)#>
</cffunction>

</cfcomponent>
