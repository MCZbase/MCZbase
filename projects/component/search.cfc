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
@param page 1-based page number of results to return; ignored (treated as 1) if size
	indicates "return every row" (see size below).
@param size rows per page; any non-numeric value (Tabulator sends the literal string
	"true" for its "All" page-size choice) means "return every matching row on one page."
@param sort_field one of "project_name" (default), "participants", "sponsors",
	"start_date", "end_date" -- anything else falls back to the default. Validated against
	this fixed list rather than used directly, since an ORDER BY column name can't go
	through <cfqueryparam>.
@param sort_dir "ASC" (default) or "DESC"; anything else falls back to the default.
@return a struct: data (an array of structs, one per matching project: project_id,
	project_name, start_date, end_date ('YYYY-MM-DD', or "" if null), participants,
	sponsors (both semicolon-separated display strings, or "" if none)), last_page (total
	page count for the current size), last_row (total matching row count across all pages).
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
	<cfargument name="page" type="string" required="no" default="1">
	<cfargument name="size" type="string" required="no" default="50">
	<cfargument name="sort_field" type="string" required="no" default="">
	<cfargument name="sort_dir" type="string" required="no" default="">

	<cfset data = ArrayNew(1)>
	<cftry>
		<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
			<cfset oneOfUs = 1>
		<cfelse>
			<cfset oneOfUs = 0>
		</cfif>

		<cfset variables.orderByColumn = "project_name">
		<cfif listfindnocase("project_name,participants,sponsors,start_date,end_date", arguments.sort_field) GT 0>
			<cfset variables.orderByColumn = arguments.sort_field>
		</cfif>
		<cfset variables.orderByDir = "ASC">
		<cfif ucase(arguments.sort_dir) EQ "DESC">
			<cfset variables.orderByDir = "DESC">
		</cfif>

		<cfset variables.currentPage = 1>
		<cfif isnumeric(arguments.page) AND val(arguments.page) GTE 1>
			<cfset variables.currentPage = int(val(arguments.page))>
		</cfif>
		<!--- Tabulator sends the literal string "true" for its "All" page-size choice --->
		<cfset variables.showAllRows = true>
		<cfset variables.pageSize = 50>
		<cfif isnumeric(arguments.size) AND val(arguments.size) GT 0>
			<cfset variables.showAllRows = false>
			<cfset variables.pageSize = int(val(arguments.size))>
		</cfif>
		<cfset variables.rowOffset = (variables.currentPage - 1) * variables.pageSize>

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
				) AS sponsors,
				<!--- Total matching row count, computed once over the whole filtered
				      result set before OFFSET/FETCH below clips it to one page, so the
				      pager can show an accurate "of N" total on every page, not just an
				      estimate. --->
				COUNT(*) OVER() AS total_count
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
			<!--- orderByColumn/orderByDir are validated above against a fixed list, not
			      passed through <cfqueryparam> -- an ORDER BY column/direction can't be a
			      bind variable. --->
			ORDER BY
				#variables.orderByColumn# #variables.orderByDir#
			<cfif NOT variables.showAllRows>
				OFFSET <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#variables.rowOffset#"> ROWS
				FETCH NEXT <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#variables.pageSize#"> ROWS ONLY
			</cfif>
		</cfquery>

		<cfloop query="search">
			<cfset row = StructNew()>
			<!--- Explicitly scoped to the query, not left bare -- this function also has
			      a project_id argument (the optional single-project filter), and a bare
			      reference here would silently resolve to that argument instead of this
			      row's own column. --->
			<cfset row["project_id"] = search.project_id>
			<cfset row["project_name"] = search.project_name>
			<cfset row["start_date"] = search.start_date>
			<cfset row["end_date"] = search.end_date>
			<cfset row["participants"] = search.participants>
			<cfset row["sponsors"] = search.sponsors>
			<cfset ArrayAppend(data, row)>
		</cfloop>

		<cfset variables.totalRows = 0>
		<cfif search.recordcount GT 0>
			<cfset variables.totalRows = search.total_count[1]>
		</cfif>
		<cfset variables.effectiveSize = variables.pageSize>
		<cfif variables.showAllRows>
			<cfset variables.effectiveSize = max(variables.totalRows, 1)>
		</cfif>
		<cfset variables.lastPage = max(1, ceiling(variables.totalRows / variables.effectiveSize))>

		<cfset result = StructNew()>
		<cfset result["data"] = data>
		<cfset result["last_page"] = variables.lastPage>
		<cfset result["last_row"] = variables.totalRows>
		<cfreturn #serializeJSON(result)#>
	<cfcatch>
		<cfset error_message = cfcatchToErrorMessage(cfcatch)>
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfset result = StructNew()>
	<cfset result["data"] = data>
	<cfset result["last_page"] = 1>
	<cfset result["last_row"] = 0>
	<cfreturn #serializeJSON(result)#>
</cffunction>

</cfcomponent>
