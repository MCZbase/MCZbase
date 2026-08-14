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
@param year restrict to projects active in this year, i.e. this year falls between the
	project's start year and end year, inclusive.
@param start_year restrict to projects whose start_date falls in this year.
@param end_year restrict to projects whose end_date falls in this year; "NOT NULL" restricts
	to projects with a defined end_date (i.e. not ongoing), "NULL" restricts to projects with
	no end_date (ongoing).
@param descr_len minimum length, in characters, of project_description.
@param project_description substring to match against project_description.
@param project_remarks substring to match against project_remarks.
@param mask_project_fg restrict to projects with this exact mask_project_fg value ("0" for
	public, "1" for hidden) -- redundant with the caller's own visibility for a non-
	coldfusion_user session, since mask_project_fg=0 is already enforced unconditionally
	for those callers below.
@param publication_id restrict results to projects linked to this publication.
@param collection_object_id restrict to projects related to this cataloged item, either
	having contributed it (via an accession) or used it (via a loan, either directly or as
	a part derived from it).
@param loan_number substring to match (case-insensitively) against the loan_number of any
	loan linked to a project via project_trans. Loan-specific rather than a generic
	transaction_id filter, so a future accession_number field can be added independently. A
	leading "=" matches the rest of the value exactly instead of by substring (appended
	automatically when a loan is picked from the autocomplete); a leading "!" excludes
	projects with that exact loan number instead of restricting to them.
@param accn_transaction_id restrict to projects linked (via project_trans) to this specific
	accession.
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
	<cfargument name="start_year" type="string" required="no" default="">
	<cfargument name="end_year" type="string" required="no" default="">
	<cfargument name="descr_len" type="string" required="no" default="">
	<cfargument name="project_description" type="string" required="no" default="">
	<cfargument name="project_remarks" type="string" required="no" default="">
	<cfargument name="mask_project_fg" type="string" required="no" default="">
	<cfargument name="publication_id" type="string" required="no" default="">
	<cfargument name="collection_object_id" type="string" required="no" default="">
	<cfargument name="loan_number" type="string" required="no" default="">
	<cfargument name="accn_transaction_id" type="string" required="no" default="">
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

		<!--- loan_number: a leading "=" means an exact match (appended automatically when a
		      loan is picked from the autocomplete), a leading "!" means exclude an exact
		      match, otherwise a plain substring match. --->
		<cfset variables.loanNumberMode = "substring">
		<cfset variables.loanNumberTerm = arguments.loan_number>
		<cfif left(arguments.loan_number,1) EQ "=">
			<cfset variables.loanNumberMode = "exact">
			<cfset variables.loanNumberTerm = RemoveChars(arguments.loan_number,1,1)>
		<cfelseif left(arguments.loan_number,1) EQ "!">
			<cfset variables.loanNumberMode = "exclude">
			<cfset variables.loanNumberTerm = RemoveChars(arguments.loan_number,1,1)>
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
				<cfif len(arguments.project_description) GT 0>
					AND UPPER(project.project_description) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(arguments.project_description)#%">
				</cfif>
				<cfif len(arguments.project_remarks) GT 0>
					AND UPPER(project.project_remarks) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(arguments.project_remarks)#%">
				</cfif>
				<cfif len(arguments.mask_project_fg) GT 0 AND isnumeric(arguments.mask_project_fg)>
					AND project.mask_project_fg = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#arguments.mask_project_fg#">
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
				<cfif len(arguments.start_year) GT 0 AND isnumeric(arguments.start_year)>
					AND TO_NUMBER(TO_CHAR(project.start_date,'YYYY')) = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.start_year#">
				</cfif>
				<cfif arguments.end_year EQ "NOT NULL">
					AND project.end_date IS NOT NULL
				<cfelseif arguments.end_year EQ "NULL">
					AND project.end_date IS NULL
				<cfelseif len(arguments.end_year) GT 0 AND isnumeric(arguments.end_year)>
					AND TO_NUMBER(TO_CHAR(project.end_date,'YYYY')) = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.end_year#">
				</cfif>
				<cfif len(arguments.publication_id) GT 0 AND isnumeric(arguments.publication_id)>
					AND project.project_id IN (
						SELECT project_publication.project_id FROM project_publication
						WHERE project_publication.publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.publication_id#">)
				</cfif>
				<!--- Mirrors the relationships showProject.cfm's own Specimens Used/Specimens
				      Contributed sections query: contributed via an accession, or used via a
				      loan -- either the whole cataloged item directly, or a specimen_part
				      derived from it. --->
				<cfif len(arguments.collection_object_id) GT 0 AND isnumeric(arguments.collection_object_id)>
					AND project.project_id IN (
						SELECT project_trans.project_id
						FROM project_trans, accn, cataloged_item
						WHERE
							project_trans.transaction_id = accn.transaction_id AND
							accn.transaction_id = cataloged_item.accn_id AND
							cataloged_item.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.collection_object_id#">
						UNION
						SELECT project_trans.project_id
						FROM project_trans, loan_item
						WHERE
							project_trans.transaction_id = loan_item.transaction_id AND
							loan_item.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.collection_object_id#">
						UNION
						SELECT project_trans.project_id
						FROM project_trans, loan_item, specimen_part
						WHERE
							project_trans.transaction_id = loan_item.transaction_id AND
							loan_item.collection_object_id = specimen_part.collection_object_id AND
							specimen_part.derived_from_cat_item = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.collection_object_id#">
					)
				</cfif>
				<cfif len(arguments.loan_number) GT 0>
					<cfif variables.loanNumberMode EQ "exclude">
						AND project.project_id NOT IN (
							SELECT project_trans.project_id
							FROM project_trans, loan
							WHERE
								project_trans.transaction_id = loan.transaction_id AND
								UPPER(loan.loan_number) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(variables.loanNumberTerm)#">
						)
					<cfelseif variables.loanNumberMode EQ "exact">
						AND project.project_id IN (
							SELECT project_trans.project_id
							FROM project_trans, loan
							WHERE
								project_trans.transaction_id = loan.transaction_id AND
								UPPER(loan.loan_number) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(variables.loanNumberTerm)#">
						)
					<cfelse>
						AND project.project_id IN (
							SELECT project_trans.project_id
							FROM project_trans, loan
							WHERE
								project_trans.transaction_id = loan.transaction_id AND
								UPPER(loan.loan_number) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(variables.loanNumberTerm)#%">
						)
					</cfif>
				</cfif>
				<cfif len(arguments.accn_transaction_id) GT 0 AND isnumeric(arguments.accn_transaction_id)>
					AND project.project_id IN (
						SELECT project_trans.project_id FROM project_trans
						WHERE project_trans.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.accn_transaction_id#">)
				</cfif>
				<cfif len(arguments.project_id) GT 0 AND isnumeric(arguments.project_id)>
					AND project.project_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.project_id#">
				</cfif>
			ORDER BY
				<cfswitch expression="#arguments.sort_field#">
					<cfcase value="participants">
						participants
					</cfcase>
					<cfcase value="sponsors">
						sponsors
					</cfcase>
					<cfcase value="start_date">
						project.start_date
					</cfcase>
					<cfcase value="end_date">
						project.end_date
					</cfcase>
					<cfdefaultcase>
						project.project_name
					</cfdefaultcase>
				</cfswitch>
				<cfif ucase(arguments.sort_dir) EQ "DESC">
					DESC
				<cfelse>
					ASC
				</cfif>
			<cfif NOT variables.showAllRows>
				OFFSET <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#variables.rowOffset#"> ROWS
				FETCH NEXT <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#variables.pageSize#"> ROWS ONLY
			</cfif>
		</cfquery>

		<cfloop query="search">
			<cfset row = StructNew()>
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
