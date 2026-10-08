<!---
Admin/ActivityLog.cfm

Copyright 2008-2017 Contributors to Arctos
Copyright 2008-2026 President and Fellows of Harvard College

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
<!--- Report on the data changes recorded by Oracle fine grained auditing, through the
	mczbase.arctos_audit view of dba_fga_audit_trail.  Access is by this page's cf_form_permissions
	row; as the audit trail shows every user's changes with their values, it would suit a role of
	its own. --->
<cfset pageTitle = "Audit SQL">
<cfinclude template="/shared/_header.cfm">

<!--- Statements listed individually; the summaries cover every matching statement. --->
<cfset DETAIL_ROW_LIMIT = 500>
<cfset STATEMENT_TYPES = "INSERT,UPDATE,DELETE,MERGE">

<cfparam name="url.db_user" default="">
<cfparam name="url.object_name" default="">
<cfparam name="url.statement_type" default="">
<cfparam name="url.sql_text" default="">
<cfparam name="url.sql_bind" default="">
<cfparam name="url.begin_date" default="">
<cfparam name="url.end_date" default="">
<cfparam name="url.execute" default="">

<cfset variables.db_user = trim(url.db_user)>
<cfset variables.object_name = trim(url.object_name)>
<cfset variables.statement_type = "">
<cfif listFindNoCase(STATEMENT_TYPES, url.statement_type) GT 0>
	<cfset variables.statement_type = ucase(url.statement_type)>
</cfif>
<cfset variables.sql_text = trim(url.sql_text)>
<cfset variables.sql_bind = trim(url.sql_bind)>
<cfset variables.begin_date = trim(url.begin_date)>
<cfset variables.end_date = trim(url.end_date)>
<cfset variables.execute = false>
<cfif url.execute EQ "true">
	<cfset variables.execute = true>
</cfif>
<!--- With no parameters at all, open on the last week, as the trail goes back to 2009. --->
<cfif structIsEmpty(url)>
	<cfset variables.begin_date = dateFormat(dateAdd("d", -7, now()), "yyyy-mm-dd")>
	<cfset variables.execute = true>
</cfif>

<!--- Dates come from date inputs as yyyy-mm-dd; anything else is reported and ignored. --->
<cfset variables.dateProblems = "">
<cfloop list="begin_date,end_date" index="variables.dateField">
	<cfset variables.dateValue = variables[variables.dateField]>
	<cfif len(variables.dateValue) GT 0>
		<cfif REFind("^[0-9]{4}-[0-9]{2}-[0-9]{2}$", variables.dateValue) EQ 0 OR NOT isDate(variables.dateValue)>
			<cfset variables.dateProblems = listAppend(variables.dateProblems, replace(variables.dateField, "_", " "))>
			<cfset variables[variables.dateField] = "">
		</cfif>
	</cfif>
</cfloop>

<!--- The link back to this report with the current filters, and one or two of them changed. --->
<cffunction name="filterLink" returntype="string" output="false">
	<cfargument name="field" type="string" required="yes">
	<cfargument name="value" type="string" required="yes">
	<cfargument name="field2" type="string" required="no" default="">
	<cfargument name="value2" type="string" required="no" default="">
	<cfset var parameters = { db_user = variables.db_user, object_name = variables.object_name, statement_type = variables.statement_type,
		sql_text = variables.sql_text, sql_bind = variables.sql_bind, begin_date = variables.begin_date, end_date = variables.end_date }>
	<cfset var link = "/Admin/ActivityLog.cfm?execute=true">
	<cfset var key = "">
	<cfset parameters[arguments.field] = arguments.value>
	<cfif len(arguments.field2) GT 0>
		<cfset parameters[arguments.field2] = arguments.value2>
	</cfif>
	<cfloop list="db_user,object_name,statement_type,sql_text,sql_bind,begin_date,end_date" index="key">
		<cfif len(parameters[key]) GT 0>
			<cfset link = link & "&#key#=#encodeForUrl(parameters[key])#">
		</cfif>
	</cfloop>
	<cfreturn link>
</cffunction>

<cfoutput>
	<main class="container-fluid py-3" id="content">
		<section class="row mx-0 mb-3" role="search">
			<div class="search-box">
				<div class="search-box-header">
					<h1 class="h3 text-white" id="formheading">Audit SQL</h1>
				</div>
				<div class="col-12 px-4 py-2">
					<p class="small mb-2">Data changes recorded by Oracle fine grained auditing: most INSERT, UPDATE and DELETE statements, with the values bound to them.</p>
					<form name="auditSearch" id="auditSearch" method="get" action="/Admin/ActivityLog.cfm">
						<input type="hidden" name="execute" value="true">
						<div class="form-row">
							<div class="col-12 col-md-4 col-xl-2">
								<label for="db_user" class="data-entry-label">Database user (contains)</label>
								<input type="text" name="db_user" id="db_user" class="data-entry-input" value="#encodeForHtmlAttribute(variables.db_user)#">
							</div>
							<div class="col-12 col-md-4 col-xl-2">
								<label for="object_name" class="data-entry-label">Table (contains)</label>
								<input type="text" name="object_name" id="object_name" class="data-entry-input" value="#encodeForHtmlAttribute(variables.object_name)#">
							</div>
							<div class="col-12 col-md-4 col-xl-2">
								<label for="statement_type" class="data-entry-label">Statement</label>
								<select name="statement_type" id="statement_type" class="data-entry-select">
									<option value="">Any</option>
									<cfloop list="#STATEMENT_TYPES#" index="variables.typeOption">
										<cfset selected = "">
										<cfif variables.typeOption EQ variables.statement_type>
											<cfset selected = "selected">
										</cfif>
										<option value="#variables.typeOption#" #selected#>#variables.typeOption#</option>
									</cfloop>
								</select>
							</div>
							<div class="col-12 col-md-4 col-xl-2">
								<label for="sql_text" class="data-entry-label">SQL contains</label>
								<input type="text" name="sql_text" id="sql_text" class="data-entry-input" value="#encodeForHtmlAttribute(variables.sql_text)#">
							</div>
							<div class="col-12 col-md-4 col-xl-2">
								<label for="sql_bind" class="data-entry-label">Parameters contain</label>
								<input type="text" name="sql_bind" id="sql_bind" class="data-entry-input" value="#encodeForHtmlAttribute(variables.sql_bind)#">
							</div>
							<div class="col-6 col-md-2 col-xl-1">
								<label for="begin_date" class="data-entry-label">From</label>
								<input type="date" name="begin_date" id="begin_date" class="data-entry-input" value="#encodeForHtmlAttribute(variables.begin_date)#">
							</div>
							<div class="col-6 col-md-2 col-xl-1">
								<label for="end_date" class="data-entry-label">To (inclusive)</label>
								<input type="date" name="end_date" id="end_date" class="data-entry-input" value="#encodeForHtmlAttribute(variables.end_date)#">
							</div>
						</div>
						<div class="form-row my-2">
							<div class="col-12">
								<input type="submit" value="Search" class="btn btn-xs btn-primary">
								<a href="/Admin/ActivityLog.cfm" class="btn btn-xs btn-warning">New Search</a>
							</div>
						</div>
					</form>
				</div>
			</div>
		</section>
		<cfif len(variables.dateProblems) GT 0>
			<div class="alert alert-warning">The #encodeForHtml(variables.dateProblems)# was not a valid date and was ignored.</div>
		</cfif>
		<cfif variables.execute>
			<!--- Each query repeats the same filters, every value bound; the statement type is one of a fixed list. --->
			<cfquery name="getTotals" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getTotals_result">
				SELECT count(*) AS statements, count(distinct db_user) AS users, count(distinct object_name) AS tables,
					to_char(min(timestamp), 'yyyy-mm-dd HH24:MI') AS first_time, to_char(max(timestamp), 'yyyy-mm-dd HH24:MI') AS last_time
				FROM mczbase.arctos_audit
				WHERE 1 = 1
					<cfif len(variables.db_user) GT 0>AND upper(db_user) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(variables.db_user)#%"></cfif>
					<cfif len(variables.object_name) GT 0>AND upper(object_name) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(variables.object_name)#%"></cfif>
					<cfif len(variables.statement_type) GT 0>AND upper(ltrim(sql_text)) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.statement_type#%"></cfif>
					<cfif len(variables.sql_text) GT 0>AND upper(sql_text) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(variables.sql_text)#%"></cfif>
					<cfif len(variables.sql_bind) GT 0>AND upper(sql_bind) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(variables.sql_bind)#%"></cfif>
					<cfif len(variables.begin_date) GT 0>AND timestamp >= <cfqueryparam cfsqltype="CF_SQL_DATE" value="#variables.begin_date#"></cfif>
					<cfif len(variables.end_date) GT 0>AND timestamp < <cfqueryparam cfsqltype="CF_SQL_DATE" value="#dateAdd('d', 1, variables.end_date)#"></cfif>
			</cfquery>
			<cfquery name="getByUser" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getByUser_result">
				SELECT db_user, count(*) AS statements, to_char(max(timestamp), 'yyyy-mm-dd HH24:MI') AS last_time
				FROM mczbase.arctos_audit
				WHERE 1 = 1
					<cfif len(variables.db_user) GT 0>AND upper(db_user) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(variables.db_user)#%"></cfif>
					<cfif len(variables.object_name) GT 0>AND upper(object_name) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(variables.object_name)#%"></cfif>
					<cfif len(variables.statement_type) GT 0>AND upper(ltrim(sql_text)) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.statement_type#%"></cfif>
					<cfif len(variables.sql_text) GT 0>AND upper(sql_text) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(variables.sql_text)#%"></cfif>
					<cfif len(variables.sql_bind) GT 0>AND upper(sql_bind) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(variables.sql_bind)#%"></cfif>
					<cfif len(variables.begin_date) GT 0>AND timestamp >= <cfqueryparam cfsqltype="CF_SQL_DATE" value="#variables.begin_date#"></cfif>
					<cfif len(variables.end_date) GT 0>AND timestamp < <cfqueryparam cfsqltype="CF_SQL_DATE" value="#dateAdd('d', 1, variables.end_date)#"></cfif>
				GROUP BY db_user
				ORDER BY count(*) DESC
			</cfquery>
			<cfquery name="getByTable" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getByTable_result">
				SELECT object_name, count(*) AS statements, to_char(max(timestamp), 'yyyy-mm-dd HH24:MI') AS last_time
				FROM mczbase.arctos_audit
				WHERE 1 = 1
					<cfif len(variables.db_user) GT 0>AND upper(db_user) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(variables.db_user)#%"></cfif>
					<cfif len(variables.object_name) GT 0>AND upper(object_name) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(variables.object_name)#%"></cfif>
					<cfif len(variables.statement_type) GT 0>AND upper(ltrim(sql_text)) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.statement_type#%"></cfif>
					<cfif len(variables.sql_text) GT 0>AND upper(sql_text) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(variables.sql_text)#%"></cfif>
					<cfif len(variables.sql_bind) GT 0>AND upper(sql_bind) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(variables.sql_bind)#%"></cfif>
					<cfif len(variables.begin_date) GT 0>AND timestamp >= <cfqueryparam cfsqltype="CF_SQL_DATE" value="#variables.begin_date#"></cfif>
					<cfif len(variables.end_date) GT 0>AND timestamp < <cfqueryparam cfsqltype="CF_SQL_DATE" value="#dateAdd('d', 1, variables.end_date)#"></cfif>
				GROUP BY object_name
				ORDER BY count(*) DESC
			</cfquery>
			<cfquery name="getByDay" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getByDay_result">
				SELECT to_char(trunc(timestamp), 'yyyy-mm-dd') AS audit_day, count(*) AS statements, count(distinct db_user) AS users
				FROM mczbase.arctos_audit
				WHERE 1 = 1
					<cfif len(variables.db_user) GT 0>AND upper(db_user) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(variables.db_user)#%"></cfif>
					<cfif len(variables.object_name) GT 0>AND upper(object_name) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(variables.object_name)#%"></cfif>
					<cfif len(variables.statement_type) GT 0>AND upper(ltrim(sql_text)) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.statement_type#%"></cfif>
					<cfif len(variables.sql_text) GT 0>AND upper(sql_text) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(variables.sql_text)#%"></cfif>
					<cfif len(variables.sql_bind) GT 0>AND upper(sql_bind) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(variables.sql_bind)#%"></cfif>
					<cfif len(variables.begin_date) GT 0>AND timestamp >= <cfqueryparam cfsqltype="CF_SQL_DATE" value="#variables.begin_date#"></cfif>
					<cfif len(variables.end_date) GT 0>AND timestamp < <cfqueryparam cfsqltype="CF_SQL_DATE" value="#dateAdd('d', 1, variables.end_date)#"></cfif>
				GROUP BY trunc(timestamp)
				ORDER BY trunc(timestamp) DESC
			</cfquery>
			<cfquery name="getStatements" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getStatements_result">
				SELECT * FROM (
					SELECT to_char(timestamp, 'yyyy-mm-dd HH24:MI:SS') AS audit_time, db_user, object_name, sql_text, sql_bind
					FROM mczbase.arctos_audit
					WHERE 1 = 1
						<cfif len(variables.db_user) GT 0>AND upper(db_user) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(variables.db_user)#%"></cfif>
						<cfif len(variables.object_name) GT 0>AND upper(object_name) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(variables.object_name)#%"></cfif>
						<cfif len(variables.statement_type) GT 0>AND upper(ltrim(sql_text)) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.statement_type#%"></cfif>
						<cfif len(variables.sql_text) GT 0>AND upper(sql_text) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(variables.sql_text)#%"></cfif>
						<cfif len(variables.sql_bind) GT 0>AND upper(sql_bind) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(variables.sql_bind)#%"></cfif>
						<cfif len(variables.begin_date) GT 0>AND timestamp >= <cfqueryparam cfsqltype="CF_SQL_DATE" value="#variables.begin_date#"></cfif>
						<cfif len(variables.end_date) GT 0>AND timestamp < <cfqueryparam cfsqltype="CF_SQL_DATE" value="#dateAdd('d', 1, variables.end_date)#"></cfif>
					ORDER BY timestamp DESC
				)
				WHERE rownum <= <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#DETAIL_ROW_LIMIT#">
			</cfquery>
			<cfset variables.isGlobalAdmin = isDefined("session.roles") AND listFindNoCase(session.roles, "global_admin") GT 0>
			<section class="row mx-0 mb-3">
				<div class="col-12">
					<h2 class="h3">Summary</h2>
					<cfif getTotals.statements EQ 0>
						<p>No audited statements match.</p>
					<cfelse>
						<p>
							#numberFormat(getTotals.statements)# statements by #numberFormat(getTotals.users)# database users on
							#numberFormat(getTotals.tables)# tables, from #getTotals.first_time# to #getTotals.last_time#.
						</p>
						<div class="row">
							<div class="col-12 col-xl-4">
								<h3 class="h4">By user</h3>
								<table class="table table-responsive d-xl-table table-sm table-striped sortable">
									<thead class="thead-light">
										<tr><th scope="col">Database user</th><th scope="col">Statements</th><th scope="col">Most recent</th></tr>
									</thead>
									<tbody>
										<cfloop query="getByUser">
											<tr>
												<td>
													<a href="#filterLink('db_user', getByUser.db_user)#">#encodeForHtml(getByUser.db_user)#</a>
													<cfif variables.isGlobalAdmin>
														<a href="/Admin/AdminUsers.cfm?action=list&username=#encodeForUrl(getByUser.db_user)#" class="small ml-1">user</a>
													</cfif>
												</td>
												<td>#numberFormat(getByUser.statements)#</td>
												<td>#getByUser.last_time#</td>
											</tr>
										</cfloop>
									</tbody>
								</table>
							</div>
							<div class="col-12 col-xl-4">
								<h3 class="h4">By table</h3>
								<table class="table table-responsive d-xl-table table-sm table-striped sortable">
									<thead class="thead-light">
										<tr><th scope="col">Table</th><th scope="col">Statements</th><th scope="col">Most recent</th></tr>
									</thead>
									<tbody>
										<cfloop query="getByTable">
											<tr>
												<td><a href="#filterLink('object_name', getByTable.object_name)#">#encodeForHtml(getByTable.object_name)#</a></td>
												<td>#numberFormat(getByTable.statements)#</td>
												<td>#getByTable.last_time#</td>
											</tr>
										</cfloop>
									</tbody>
								</table>
							</div>
							<div class="col-12 col-xl-4">
								<h3 class="h4">By day</h3>
								<table class="table table-responsive d-xl-table table-sm table-striped sortable">
									<thead class="thead-light">
										<tr><th scope="col">Day</th><th scope="col">Statements</th><th scope="col">Users</th></tr>
									</thead>
									<tbody>
										<cfloop query="getByDay">
											<tr>
												<td><a href="#filterLink('begin_date', getByDay.audit_day, 'end_date', getByDay.audit_day)#">#getByDay.audit_day#</a></td>
												<td>#numberFormat(getByDay.statements)#</td>
												<td>#numberFormat(getByDay.users)#</td>
											</tr>
										</cfloop>
									</tbody>
								</table>
							</div>
						</div>
					</cfif>
				</div>
			</section>
			<cfif getStatements.recordcount GT 0>
				<section class="row mx-0 mb-4">
					<div class="col-12">
						<h2 class="h3">Statements
							<cfif getTotals.statements GT DETAIL_ROW_LIMIT>
								<span class="small">(most recent #DETAIL_ROW_LIMIT# of #numberFormat(getTotals.statements)#)</span>
							</cfif>
						</h2>
						<table class="table table-responsive d-xl-table table-sm table-striped sortable">
							<thead class="thead-light">
								<tr><th scope="col">Time</th><th scope="col">Database user</th><th scope="col">Table</th><th scope="col">Statement and bound values</th></tr>
							</thead>
							<tbody>
								<cfloop query="getStatements">
									<tr>
										<td class="text-nowrap">#getStatements.audit_time#</td>
										<td><a href="#filterLink('db_user', getStatements.db_user)#">#encodeForHtml(getStatements.db_user)#</a></td>
										<td><a href="#filterLink('object_name', getStatements.object_name)#">#encodeForHtml(getStatements.object_name)#</a></td>
										<td>
											<code class="text-dark">#encodeForHtml(getStatements.sql_text)#</code>
											<cfif len(getStatements.sql_bind) GT 0>
												<div class="small text-secondary">#encodeForHtml(getStatements.sql_bind)#</div>
											</cfif>
										</td>
									</tr>
								</cfloop>
							</tbody>
						</table>
					</div>
				</section>
			</cfif>
		</cfif>
	</main>
</cfoutput>
<script src="/lib/misc/sorttable.js"></script>
<cfinclude template="/shared/_footer.cfm">
