<!---
Reports/SpecUsageReport.cfm

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
<!--- Builds a table in the user's own schema summarising specimen use by a list of projects and
	publications, for report templates in Reports/report_printer.cfm, which refer to it as
	#session.projectReportTable#.
	TODO: Nothing links to this page; evaluate whether it is still needed, and remove it (and the
	projectReportTable substitution in report_printer.cfm) if it is not. --->
<cfinclude template="/shared/component/requestForgery.cfc" runOnce="true">

<!--- The table name can't be bound, so it is built only from the session's random hex key. --->
<cfset TABLE_NAME_PREFIX = "projTable">
<cfset ID_LIST_PATTERN = "^[0-9]+(,[0-9]+)*$">

<cfparam name="url.project_id" default="">
<cfparam name="url.publication_id" default="">
<cfparam name="form.action" default="">
<cfparam name="form.project_id" default="">
<cfparam name="form.publication_id" default="">
<cfparam name="form.report_title" default="">

<cfset variables.action = "entryPoint">
<cfset variables.project_id = url.project_id>
<cfset variables.publication_id = url.publication_id>
<cfset variables.report_title = "">
<cfif form.action EQ "buildIt">
	<cfset variables.action = "buildIt">
	<cfset variables.project_id = form.project_id>
	<cfset variables.publication_id = form.publication_id>
	<cfset variables.report_title = trim(form.report_title)>
</cfif>
<cfset variables.project_id = REReplace(variables.project_id, "\s", "", "all")>
<cfset variables.publication_id = REReplace(variables.publication_id, "\s", "", "all")>

<!---
	joinNames make a list of names into text: "a", "a and b", or "a, b, and c".

	@param names the names, delimited by |, as names may contain commas.
	@return the names as text.
--->
<cffunction name="joinNames" returntype="string" output="false">
	<cfargument name="names" type="string" required="yes">
	<cfset var nameCount = listLen(arguments.names, "|")>
	<cfset var lastName = "">
	<cfif nameCount LTE 1>
		<cfreturn arguments.names>
	</cfif>
	<cfif nameCount EQ 2>
		<cfreturn listChangeDelims(arguments.names, " and ", "|")>
	</cfif>
	<cfset lastName = listLast(arguments.names, "|")>
	<cfreturn listChangeDelims(listDeleteAt(arguments.names, nameCount, "|"), ", ", "|") & ", and " & lastName>
</cffunction>

<cfset pageTitle = "Specimen Usage Report Data">
<cfinclude template="/shared/_header.cfm">
<cfoutput>
	<main class="container py-3" id="content">
		<section class="row border rounded my-2 mb-4">
			<div class="col-12">
				<h1 class="h2 mt-2">Specimen Usage Report Data</h1>
				<p>
					Builds a table of specimen counts for a list of projects (specimens accessioned and loaned
					through each project's transactions) and of citation counts for a list of publications,
					for use in reports.
				</p>
				<form name="buildReport" id="buildReport" method="post" action="/Reports/SpecUsageReport.cfm">
					#csrfTokenInput()#
					<input type="hidden" name="action" value="buildIt">
					<div class="form-row mb-2">
						<div class="col-12 col-md-4">
							<label for="report_title" class="data-entry-label">Report Title</label>
							<input type="text" name="report_title" id="report_title" class="data-entry-input" value="#encodeForHtmlAttribute(variables.report_title)#">
						</div>
						<div class="col-12 col-md-4">
							<label for="project_id" class="data-entry-label">Project IDs (comma separated)</label>
							<input type="text" name="project_id" id="project_id" class="data-entry-input" value="#encodeForHtmlAttribute(variables.project_id)#">
						</div>
						<div class="col-12 col-md-4">
							<label for="publication_id" class="data-entry-label">Publication IDs (comma separated)</label>
							<input type="text" name="publication_id" id="publication_id" class="data-entry-input" value="#encodeForHtmlAttribute(variables.publication_id)#">
						</div>
					</div>
					<input type="submit" value="Build Report Data" class="btn btn-xs btn-primary mb-2">
				</form>
			</div>
		</section>
		<cfif variables.action EQ "buildIt">
			<cfset variables.problems = "">
			<cfif NOT isPostWithCsrfToken()>
				<cfset variables.problems = listAppend(variables.problems, "The form had expired; please submit it again.", "|")>
			</cfif>
			<cfif len(variables.project_id) GT 0 AND REFind(ID_LIST_PATTERN, variables.project_id) EQ 0>
				<cfset variables.problems = listAppend(variables.problems, "Project IDs must be numbers separated by commas.", "|")>
			</cfif>
			<cfif len(variables.publication_id) GT 0 AND REFind(ID_LIST_PATTERN, variables.publication_id) EQ 0>
				<cfset variables.problems = listAppend(variables.problems, "Publication IDs must be numbers separated by commas.", "|")>
			</cfif>
			<cfif len(variables.project_id) EQ 0 AND len(variables.publication_id) EQ 0>
				<cfset variables.problems = listAppend(variables.problems, "Enter at least one project or publication ID.", "|")>
			</cfif>
			<cfif NOT isDefined("session.DownloadFileID") OR REFind("^[0-9a-f]{32}$", session.DownloadFileID) EQ 0>
				<cfset variables.problems = listAppend(variables.problems, "Your session is too old to build the table; please log out and in again.", "|")>
			</cfif>
			<cfif len(variables.problems) GT 0>
				<section class="row">
					<div class="col-12 alert alert-warning">
						<ul class="mb-0">
							<cfloop list="#variables.problems#" index="problem" delimiters="|">
								<li>#encodeForHtml(problem)#</li>
							</cfloop>
						</ul>
					</div>
				</section>
			<cfelse>
				<cfset session.projectReportTable = TABLE_NAME_PREFIX & left(session.DownloadFileID, 21)>
				<cfset variables.tableName = session.projectReportTable>
				<cfquery name="tableExists" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="tableExists_result">
					SELECT count(*) AS ct
					FROM user_tables
					WHERE table_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(variables.tableName)#">
				</cfquery>
				<cfif tableExists.ct GT 0>
					<cfquery name="dropTable" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="dropTable_result">
						DROP TABLE #variables.tableName#
					</cfquery>
				</cfif>
				<cfquery name="createTable" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="createTable_result">
					CREATE TABLE #variables.tableName# (
						report_title VARCHAR2(4000),
						project_id NUMBER,
						project_name VARCHAR2(4000),
						project_dates VARCHAR2(4000),
						project_agents VARCHAR2(4000),
						project_sponsors VARCHAR2(4000),
						numberProjectAccnSpecimens NUMBER,
						numberProjectLoanSpecimens NUMBER,
						publication_id NUMBER,
						formatted_publication VARCHAR2(4000),
						numberOfCitations NUMBER
					)
				</cfquery>
				<cftransaction>
					<cfif len(variables.project_id) GT 0>
						<cfquery name="getProjects" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getProjects_result">
							SELECT
								project.project_id,
								project.project_name,
								to_char(project.start_date, 'yyyy-mm-dd') AS start_date,
								to_char(project.end_date, 'yyyy-mm-dd') AS end_date
							FROM project
							WHERE
								project.project_id IN (<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.project_id#" list="yes">)
						</cfquery>
						<cfloop query="getProjects">
							<cfquery name="getProjectAgents" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getProjectAgents_result">
								SELECT agent_name.agent_name
								FROM project_agent
									JOIN agent_name ON project_agent.agent_name_id = agent_name.agent_name_id
								WHERE
									project_agent.project_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getProjects.project_id#">
								ORDER BY project_agent.agent_position
							</cfquery>
							<cfquery name="getProjectSponsors" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getProjectSponsors_result">
								SELECT agent_name.agent_name
								FROM project_sponsor
									JOIN agent_name ON project_sponsor.agent_name_id = agent_name.agent_name_id
								WHERE
									project_sponsor.project_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getProjects.project_id#">
							</cfquery>
							<cfquery name="getAccnCount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getAccnCount_result">
								SELECT count(DISTINCT cataloged_item.collection_object_id) AS numSpec
								FROM project_trans
									JOIN accn ON project_trans.transaction_id = accn.transaction_id
									JOIN cataloged_item ON accn.transaction_id = cataloged_item.accn_id
								WHERE
									project_trans.project_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getProjects.project_id#">
							</cfquery>
							<cfquery name="getLoanCount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getLoanCount_result">
								SELECT count(DISTINCT specimen_part.derived_from_cat_item) AS numSpec
								FROM project_trans
									JOIN loan ON project_trans.transaction_id = loan.transaction_id
									JOIN loan_item ON loan.transaction_id = loan_item.transaction_id
									JOIN specimen_part ON loan_item.collection_object_id = specimen_part.collection_object_id
								WHERE
									project_trans.project_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getProjects.project_id#">
							</cfquery>
							<cfset variables.projectDates = "">
							<cfif getProjects.start_date EQ getProjects.end_date>
								<cfset variables.projectDates = getProjects.start_date>
							<cfelseif len(getProjects.start_date) GT 0 AND len(getProjects.end_date) GT 0>
								<cfset variables.projectDates = getProjects.start_date & "-" & getProjects.end_date>
							<cfelse>
								<cfset variables.projectDates = getProjects.start_date & getProjects.end_date>
							</cfif>
							<cfquery name="insertProject" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="insertProject_result">
								INSERT INTO #variables.tableName# (
									report_title,
									project_id,
									project_name,
									project_dates,
									project_agents,
									project_sponsors,
									numberProjectAccnSpecimens,
									numberProjectLoanSpecimens
								) VALUES (
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.report_title#">,
									<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getProjects.project_id#">,
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getProjects.project_name#">,
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.projectDates#">,
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#joinNames(valueList(getProjectAgents.agent_name, '|'))#">,
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#joinNames(valueList(getProjectSponsors.agent_name, '|'))#">,
									<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getAccnCount.numSpec#">,
									<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getLoanCount.numSpec#">
								)
							</cfquery>
						</cfloop>
					</cfif>
					<cfif len(variables.publication_id) GT 0>
						<cfquery name="getPublications" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getPublications_result">
							SELECT
								formatted_publication.publication_id,
								formatted_publication.formatted_publication,
								count(DISTINCT citation.collection_object_id) AS numCits
							FROM formatted_publication
								LEFT JOIN citation ON formatted_publication.publication_id = citation.publication_id
							WHERE
								formatted_publication.format_style = 'long'
								AND formatted_publication.publication_id IN (<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.publication_id#" list="yes">)
							GROUP BY
								formatted_publication.publication_id,
								formatted_publication.formatted_publication
						</cfquery>
						<cfloop query="getPublications">
							<cfquery name="insertPublication" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="insertPublication_result">
								INSERT INTO #variables.tableName# (
									report_title,
									publication_id,
									formatted_publication,
									numberOfCitations
								) VALUES (
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.report_title#">,
									<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getPublications.publication_id#">,
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getPublications.formatted_publication#">,
									<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getPublications.numCits#">
								)
							</cfquery>
						</cfloop>
					</cfif>
				</cftransaction>
				<cfquery name="getReportRows" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getReportRows_result">
					SELECT
						project_id, project_name, project_dates, project_agents, project_sponsors,
						numberProjectAccnSpecimens, numberProjectLoanSpecimens,
						publication_id, formatted_publication, numberOfCitations
					FROM #variables.tableName#
					ORDER BY project_id, publication_id
				</cfquery>
				<section class="row mb-4">
					<div class="col-12">
						<h2 class="h3">Table #encodeForHtml(variables.tableName)#</h2>
						<p>
							The table is in your own schema and is replaced each time you build it. Each row holds either
							a project or a publication. Report templates in the
							<a href="/Reports/reporter.cfm">Reporter</a> refer to it as
							<code>##session.projectReportTable##</code> (see the ProjectTemplate and PublicationTemplate
							reports). You can also query it with
							<a href="/tools/userSQL.cfm?sql=#encodeForUrl('SELECT * FROM ' & variables.tableName)#">Write SQL</a>,
							which can download the result as CSV.
						</p>
						<cfif getReportRows.recordcount EQ 0>
							<p>No matching projects or publications were found.</p>
						<cfelse>
							<table class="table table-responsive d-xl-table table-striped">
								<thead>
									<tr>
										<th>Project or Publication</th>
										<th>Dates</th>
										<th>Agents</th>
										<th>Sponsors</th>
										<th>Accessioned Specimens</th>
										<th>Loaned Specimens</th>
										<th>Citations</th>
									</tr>
								</thead>
								<tbody>
									<cfloop query="getReportRows">
										<tr>
											<cfif len(getReportRows.project_id) GT 0>
												<td><a href="/project/#encodeForUrl(getReportRows.project_id)#">#encodeForHtml(getReportRows.project_name)#</a></td>
												<td>#encodeForHtml(getReportRows.project_dates)#</td>
												<td>#encodeForHtml(getReportRows.project_agents)#</td>
												<td>#encodeForHtml(getReportRows.project_sponsors)#</td>
												<td>#encodeForHtml(getReportRows.numberProjectAccnSpecimens)#</td>
												<td>#encodeForHtml(getReportRows.numberProjectLoanSpecimens)#</td>
												<td></td>
											<cfelse>
												<td colspan="6"><a href="/publication/#encodeForUrl(getReportRows.publication_id)#">#encodeForHtml(getReportRows.formatted_publication)#</a></td>
												<td>#encodeForHtml(getReportRows.numberOfCitations)#</td>
											</cfif>
										</tr>
									</cfloop>
								</tbody>
							</table>
						</cfif>
					</div>
				</section>
			</cfif>
		</cfif>
	</main>
</cfoutput>
<cfinclude template="/shared/_footer.cfm">
