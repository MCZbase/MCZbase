<!---
Admin/download.cfm

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
<!--- Report on data downloads logged in cf_download by the download agreement forms, and on
	specimen CSV file requests in cf_download_file, filtered by user, purpose, affiliation and date. --->
<cfset pageTitle = "Download Statistics">
<cfinclude template="/shared/_header.cfm">

<cfif NOT ( isdefined("session.roles") AND listfindnocase(session.roles,"global_admin") ) >
	<!--- this should be handled by rolecheck but add another layer here to make sure of access control --->
	<cflocation url="/errors/forbidden.cfm" addtoken="false">
</cfif>

<!--- Rows listed individually; the summaries cover every matching download. --->
<cfset DETAIL_ROW_LIMIT = 500>
<cfset TOP_USER_LIMIT = 25>

<cfparam name="url.username" default="">
<cfparam name="url.download_purpose" default="">
<cfparam name="url.affiliation" default="">
<cfparam name="url.begin_date" default="">
<cfparam name="url.end_date" default="">
<cfparam name="url.execute" default="">

<cfset variables.username = trim(url.username)>
<cfset variables.download_purpose = trim(url.download_purpose)>
<cfset variables.affiliation = trim(url.affiliation)>
<cfset variables.begin_date = trim(url.begin_date)>
<cfset variables.end_date = trim(url.end_date)>
<cfset variables.execute = false>
<cfif url.execute EQ "true">
	<cfset variables.execute = true>
</cfif>
<!--- With no parameters at all, open on the last year's downloads. --->
<cfif structIsEmpty(url)>
	<cfset variables.begin_date = dateFormat(dateAdd("yyyy", -1, now()), "yyyy-mm-dd")>
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

<cfquery name="ctPurpose" datasource="cf_dbuser" result="ctPurpose_result">
	SELECT download_purpose
	FROM ctdownload_purpose
	ORDER BY download_purpose
</cfquery>

<cfoutput>
	<main class="container-fluid py-3" id="content">
		<section class="row mx-0 mb-3" role="search">
			<div class="search-box">
				<div class="search-box-header">
					<h1 class="h3 text-white" id="formheading">Download Statistics</h1>
				</div>
				<div class="col-12 px-4 py-2">
					<form name="downloadSearch" id="downloadSearch" method="get" action="/Admin/download.cfm">
						<input type="hidden" name="execute" value="true">
						<div class="form-row">
							<div class="col-12 col-md-3">
								<label for="username" class="data-entry-label">Username (exact, any case)</label>
								<input type="text" name="username" id="username" class="data-entry-input" value="#encodeForHtmlAttribute(variables.username)#">
							</div>
							<div class="col-12 col-md-3">
								<label for="affiliation" class="data-entry-label">Affiliation contains</label>
								<input type="text" name="affiliation" id="affiliation" class="data-entry-input" value="#encodeForHtmlAttribute(variables.affiliation)#">
							</div>
							<div class="col-12 col-md-2">
								<label for="download_purpose" class="data-entry-label">Purpose</label>
								<select name="download_purpose" id="download_purpose" class="data-entry-select">
									<option value=""></option>
									<cfloop query="ctPurpose">
										<cfset selected = "">
										<cfif ctPurpose.download_purpose EQ variables.download_purpose>
											<cfset selected = "selected">
										</cfif>
										<option value="#encodeForHtmlAttribute(ctPurpose.download_purpose)#" #selected#>#encodeForHtml(ctPurpose.download_purpose)#</option>
									</cfloop>
								</select>
							</div>
							<div class="col-6 col-md-2">
								<label for="begin_date" class="data-entry-label">From</label>
								<input type="date" name="begin_date" id="begin_date" class="data-entry-input" value="#encodeForHtmlAttribute(variables.begin_date)#">
							</div>
							<div class="col-6 col-md-2">
								<label for="end_date" class="data-entry-label">To (inclusive)</label>
								<input type="date" name="end_date" id="end_date" class="data-entry-input" value="#encodeForHtmlAttribute(variables.end_date)#">
							</div>
						</div>
						<div class="form-row my-2">
							<div class="col-12">
								<input type="submit" value="Search" class="btn btn-xs btn-primary">
								<a href="/Admin/download.cfm?execute=true" class="btn btn-xs btn-secondary">All Downloads</a>
								<a href="/Admin/download.cfm" class="btn btn-xs btn-warning">New Search</a>
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
			<cfquery name="getDownloads" datasource="cf_dbuser" result="getDownloads_result">
				SELECT
					cf_download.user_id,
					cf_users.username,
					cf_user_data.first_name,
					cf_user_data.last_name,
					cf_user_data.affiliation,
					cf_download.download_purpose,
					cf_download.download_date,
					to_char(cf_download.download_date, 'yyyy-mm-dd') AS download_day,
					to_char(cf_download.download_date, 'yyyy') AS download_year,
					cf_download.num_records,
					cf_download.agree_to_terms
				FROM cf_download
					LEFT JOIN cf_users ON cf_download.user_id = cf_users.user_id
					LEFT JOIN cf_user_data ON cf_download.user_id = cf_user_data.user_id
				WHERE
					1 = 1
					<cfif len(variables.username) GT 0>
						AND upper(cf_users.username) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(variables.username)#">
					</cfif>
					<cfif len(variables.affiliation) GT 0>
						AND upper(cf_user_data.affiliation) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(variables.affiliation)#%">
					</cfif>
					<cfif len(variables.download_purpose) GT 0>
						AND cf_download.download_purpose = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.download_purpose#">
					</cfif>
					<cfif len(variables.begin_date) GT 0>
						AND cf_download.download_date >= <cfqueryparam cfsqltype="CF_SQL_DATE" value="#variables.begin_date#">
					</cfif>
					<cfif len(variables.end_date) GT 0>
						AND cf_download.download_date < <cfqueryparam cfsqltype="CF_SQL_DATE" value="#dateAdd('d', 1, variables.end_date)#">
					</cfif>
				ORDER BY cf_download.download_date DESC
			</cfquery>
			<cfquery name="getTotals" dbtype="query">
				SELECT count(*) AS downloads, sum(num_records) AS records, min(download_day) AS first_day, max(download_day) AS last_day
				FROM getDownloads
			</cfquery>
			<cfquery name="getUserCount" dbtype="query">
				SELECT DISTINCT user_id FROM getDownloads
			</cfquery>
			<cfquery name="getByPurpose" dbtype="query">
				SELECT download_purpose, count(*) AS downloads, sum(num_records) AS records, max(download_day) AS last_day
				FROM getDownloads
				GROUP BY download_purpose
				ORDER BY downloads DESC
			</cfquery>
			<cfquery name="getByYear" dbtype="query">
				SELECT download_year, count(*) AS downloads, sum(num_records) AS records
				FROM getDownloads
				GROUP BY download_year
				ORDER BY download_year DESC
			</cfquery>
			<cfquery name="getByUser" dbtype="query" maxrows="#TOP_USER_LIMIT#">
				SELECT username, first_name, last_name, affiliation, count(*) AS downloads, sum(num_records) AS records, max(download_day) AS last_day
				FROM getDownloads
				GROUP BY username, first_name, last_name, affiliation
				ORDER BY downloads DESC
			</cfquery>
			<cfquery name="getFileRequests" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getFileRequests_result">
				SELECT
					status,
					count(*) AS requests,
					to_char(max(time_created), 'yyyy-mm-dd') AS last_day
				FROM cf_download_file
				WHERE
					1 = 1
					<cfif len(variables.username) GT 0>
						AND upper(username) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(variables.username)#">
					</cfif>
					<cfif len(variables.begin_date) GT 0>
						AND time_created >= <cfqueryparam cfsqltype="CF_SQL_DATE" value="#variables.begin_date#">
					</cfif>
					<cfif len(variables.end_date) GT 0>
						AND time_created < <cfqueryparam cfsqltype="CF_SQL_DATE" value="#dateAdd('d', 1, variables.end_date)#">
					</cfif>
				GROUP BY status
				ORDER BY count(*) DESC
			</cfquery>
			<section class="row mx-0 mb-4">
				<div class="col-12">
					<h2 class="h3">Summary</h2>
					<cfif getDownloads.recordcount EQ 0>
						<p>No downloads match.</p>
					<cfelse>
						<p>
							#numberFormat(getTotals.downloads)# downloads of #numberFormat(getTotals.records)# records
							by #numberFormat(getUserCount.recordcount)# users, from #getTotals.first_day# to #getTotals.last_day#.
						</p>
						<div class="row">
							<div class="col-12 col-xl-6">
								<h3 class="h4">By purpose</h3>
								<table class="table table-responsive d-xl-table table-sm sortable">
									<thead class="thead-light">
										<tr><th scope="col">Purpose</th><th scope="col">Downloads</th><th scope="col">Records</th><th scope="col">Most recent</th></tr>
									</thead>
									<tbody>
										<cfloop query="getByPurpose">
											<tr>
												<td><a href="/Admin/download.cfm?execute=true&download_purpose=#encodeForUrl(getByPurpose.download_purpose)#&username=#encodeForUrl(variables.username)#&affiliation=#encodeForUrl(variables.affiliation)#&begin_date=#encodeForUrl(variables.begin_date)#&end_date=#encodeForUrl(variables.end_date)#">#encodeForHtml(getByPurpose.download_purpose)#</a></td>
												<td>#numberFormat(getByPurpose.downloads)#</td>
												<td>#numberFormat(getByPurpose.records)#</td>
												<td>#getByPurpose.last_day#</td>
											</tr>
										</cfloop>
									</tbody>
								</table>
							</div>
							<div class="col-12 col-xl-6">
								<h3 class="h4">By year</h3>
								<table class="table table-responsive d-xl-table table-sm sortable">
									<thead class="thead-light">
										<tr><th scope="col">Year</th><th scope="col">Downloads</th><th scope="col">Records</th></tr>
									</thead>
									<tbody>
										<cfloop query="getByYear">
											<tr>
												<td>#getByYear.download_year#</td>
												<td>#numberFormat(getByYear.downloads)#</td>
												<td>#numberFormat(getByYear.records)#</td>
											</tr>
										</cfloop>
									</tbody>
								</table>
							</div>
						</div>
						<h3 class="h4">Most active users <span class="small">(top #TOP_USER_LIMIT#)</span></h3>
						<table class="table table-responsive d-xl-table table-sm table-striped sortable">
							<thead class="thead-light">
								<tr><th scope="col">Username</th><th scope="col">Name</th><th scope="col">Affiliation</th><th scope="col">Downloads</th><th scope="col">Records</th><th scope="col">Most recent</th></tr>
							</thead>
							<tbody>
								<cfloop query="getByUser">
									<tr>
										<td>
											<cfif len(getByUser.username) GT 0>
												<a href="/Admin/AdminUsers.cfm?action=edit&username=#encodeForUrl(getByUser.username)#">#encodeForHtml(getByUser.username)#</a>
											<cfelse>
												[deleted user]
											</cfif>
										</td>
										<td>#encodeForHtml(getByUser.first_name)# #encodeForHtml(getByUser.last_name)#</td>
										<td>#encodeForHtml(getByUser.affiliation)#</td>
										<td>#numberFormat(getByUser.downloads)#</td>
										<td>#numberFormat(getByUser.records)#</td>
										<td>#getByUser.last_day#</td>
									</tr>
								</cfloop>
							</tbody>
						</table>
					</cfif>
					<h3 class="h4">Specimen CSV file requests</h3>
					<cfif getFileRequests.recordcount EQ 0>
						<p>No specimen CSV file requests match.</p>
					<cfelse>
						<p class="small">Requests from the specimen search download dialog, by status. These are not filtered by purpose or affiliation.</p>
						<table class="table table-responsive d-xl-table table-sm">
							<thead class="thead-light">
								<tr><th scope="col">Status</th><th scope="col">Requests</th><th scope="col">Most recent</th></tr>
							</thead>
							<tbody>
								<cfloop query="getFileRequests">
									<tr>
										<td>#encodeForHtml(getFileRequests.status)#</td>
										<td>#numberFormat(getFileRequests.requests)#</td>
										<td>#getFileRequests.last_day#</td>
									</tr>
								</cfloop>
							</tbody>
						</table>
					</cfif>
				</div>
			</section>
			<cfif getDownloads.recordcount GT 0>
				<section class="row mx-0 mb-4">
					<div class="col-12">
						<h2 class="h3">Downloads
							<cfif getDownloads.recordcount GT DETAIL_ROW_LIMIT>
								<span class="small">(most recent #DETAIL_ROW_LIMIT# of #numberFormat(getDownloads.recordcount)#)</span>
							</cfif>
						</h2>
						<table class="table table-responsive d-xl-table table-sm table-striped sortable">
							<thead class="thead-light">
								<tr><th scope="col">Date</th><th scope="col">Username</th><th scope="col">Name</th><th scope="col">Affiliation</th><th scope="col">Purpose</th><th scope="col">Records</th><th scope="col">Agreed</th></tr>
							</thead>
							<tbody>
								<cfloop query="getDownloads" endrow="#DETAIL_ROW_LIMIT#">
									<tr>
										<td>#getDownloads.download_day#</td>
										<td>
											<cfif len(getDownloads.username) GT 0>
												<a href="/Admin/AdminUsers.cfm?action=edit&username=#encodeForUrl(getDownloads.username)#">#encodeForHtml(getDownloads.username)#</a>
											<cfelse>
												[deleted user]
											</cfif>
										</td>
										<td>#encodeForHtml(getDownloads.first_name)# #encodeForHtml(getDownloads.last_name)#</td>
										<td>#encodeForHtml(getDownloads.affiliation)#</td>
										<td>#encodeForHtml(getDownloads.download_purpose)#</td>
										<td>#numberFormat(getDownloads.num_records)#</td>
										<td>#encodeForHtml(getDownloads.agree_to_terms)#</td>
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
