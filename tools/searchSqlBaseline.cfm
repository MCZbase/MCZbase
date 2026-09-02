<!---
tools/searchSqlBaseline.cfm

Copyright 2026 President and Fellows of Harvard College

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
<!--- Redmine 1031 phase 1 regression harness, corpus driver.

	One page visit runs /tools/searchSqlDump.cfm once for every corpus entry and produces two
	things:

	(1) A pasteable digest, one line per entry carrying a hash of the generated SQL.  Comparing
	    the before and after digests identifies exactly which criteria combinations changed
	    behaviour, without anyone having to read 500 SQL dumps.  Only the entries whose hash
	    moved need their full text examined.
	(2) One full report file per entry plus a manifest, written to a labelled directory, for
	    diffing on the server and for inspecting whichever entries the digest flags.

	Corpus: the saved searches in cf_canned_search whose URL targets SpecimenResults.cfm.
	These are real parameter combinations that real users saved, which is the point -- they
	include combinations nobody would think to write a test for.  Additional URLs, for example
	harvested from web server logs, can be pasted into the form.

	Each entry is fetched as a separate HTTP request rather than by including SearchSql.cfm in
	a loop.  Two reasons: the include leaves roughly 163 criteria variables in the variables
	scope, so a second iteration would inherit the first entry's criteria; and SearchSql.cfm
	calls <cfabort> on some invalid input, which would end the whole run.  A separate request
	per entry gives each one a clean scope, and an abort affects only that entry.

	Workflow:
	  1. Run with label "before" on an unmodified checkout. Keep the digest.
	  2. Do the phase 3 work.
	  3. Run with label "after". Compare digests.
	  4. For each entry whose hash changed, diff the two report files to see what moved.
	Use the same login for both runs: session.flatTableName is FLAT for internal users and
	FILTERED_FLAT for external ones, and that token appears throughout the generated SQL.
--->
<cfset pageTitle="Redmine 1031 Phase 1 Baseline Capture">
<cfinclude template="/shared/_header.cfm">
<cfif NOT (isDefined("session.roles") AND listContainsNoCase(session.roles,"manage_specimens"))>
	<!--- extra check to ensure access only by authorized users --->
	<cfthrow message="Inadequate Permissions.">
</cfif>

<!--- Obtain parameters with explicit scopes, form taking priority over url. --->
<cfparam name="url.dumpLabel" default="before">
<cfparam name="form.dumpLabel" default="">
<cfparam name="url.action" default="list">
<cfparam name="form.action" default="">
<cfparam name="url.baseUrl" default="">
<cfparam name="form.baseUrl" default="">
<cfparam name="url.outputDir" default="">
<cfparam name="form.outputDir" default="">
<cfparam name="url.maxEntries" default="0">
<cfparam name="form.maxEntries" default="">
<cfparam name="form.extraUrls" default="">

<cfset variables.dumpLabel = url.dumpLabel>
<cfif len(form.dumpLabel) GT 0><cfset variables.dumpLabel = form.dumpLabel></cfif>
<cfset variables.action = url.action>
<cfif len(form.action) GT 0><cfset variables.action = form.action></cfif>
<cfset variables.baseUrl = url.baseUrl>
<cfif len(form.baseUrl) GT 0><cfset variables.baseUrl = form.baseUrl></cfif>
<cfif len(variables.baseUrl) EQ 0><cfset variables.baseUrl = Application.serverRootUrl></cfif>
<cfset variables.outputDir = url.outputDir>
<cfif len(form.outputDir) GT 0><cfset variables.outputDir = form.outputDir></cfif>
<cfif len(variables.outputDir) EQ 0>
	<cfset variables.outputDir = getTempDirectory() & "searchSqlBaseline">
</cfif>
<cfset variables.maxEntries = url.maxEntries>
<cfif len(form.maxEntries) GT 0><cfset variables.maxEntries = form.maxEntries></cfif>
<cfif NOT isNumeric(variables.maxEntries)><cfset variables.maxEntries = 0></cfif>

<!--- Label becomes a directory name, so restrict it to characters safe in a path. --->
<cfif REFind("^[A-Za-z0-9_\-]{1,40}$",variables.dumpLabel) EQ 0>
	<cfthrow message="dumpLabel must be 1 to 40 characters of letters, digits, underscore or hyphen.">
</cfif>
<cfset variables.runDir = variables.outputDir & "/" & variables.dumpLabel>

<!--- Several hundred separate requests in one page visit. --->
<cfsetting requesttimeout="3600">

<!--- Apache rejects a request line over roughly 8190 bytes and some saved searches carry
	catalogue number lists thousands of characters long.  Fetch by GET where it fits, which is
	how production receives these, and fall back to POST beyond that.  SearchSql.cfm resolves
	criteria with isdefined("name"), which finds either scope, so the generated SQL is the same
	either way; the method used is recorded so the difference is never invisible. --->
<cfset variables.MAX_GET_QUERYSTRING_LEN = 6000>

<cfquery name="corpus" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#" result="corpus_result">
	SELECT
		cf_canned_search.canned_id,
		cf_canned_search.search_name,
		cf_canned_search.url
	FROM
		cf_canned_search
		JOIN cf_users ON (cf_users.user_id = cf_canned_search.user_id)
	WHERE
		cf_canned_search.url LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%SpecimenResults.cfm%">
	ORDER BY
		cf_canned_search.canned_id
</cfquery>

<!--- Build the working corpus: saved searches, plus any pasted URLs. --->
<cfset variables.entries = arrayNew(1)>
<cfloop query="corpus">
	<cfset arrayAppend(variables.entries,{
		source = "cf_canned_search",
		id = corpus.canned_id,
		name = corpus.search_name,
		url = corpus.url
	})>
</cfloop>
<cfif len(trim(form.extraUrls)) GT 0>
	<cfset variables.extraSeq = 0>
	<cfloop list="#form.extraUrls#" delimiters="#chr(10)##chr(13)#" index="variables.extraUrl">
		<cfif len(trim(variables.extraUrl)) GT 0>
			<cfset variables.extraSeq = variables.extraSeq + 1>
			<cfset arrayAppend(variables.entries,{
				source = "pasted",
				id = "x#variables.extraSeq#",
				name = "pasted entry #variables.extraSeq#",
				url = trim(variables.extraUrl)
			})>
		</cfif>
	</cfloop>
</cfif>
<cfif variables.maxEntries GT 0 AND arrayLen(variables.entries) GT variables.maxEntries>
	<cfset variables.entries = arraySlice(variables.entries,1,variables.maxEntries)>
</cfif>

<!--- Function queryStringOf extracts the query string from a stored search URL.

	@param storedUrl a URL as saved in cf_canned_search, which may or may not carry a scheme
		and host, and may or may not carry a leading question mark.
	@return everything after the first question mark, or an empty string if there is none.
--->
<cffunction name="queryStringOf" access="private" returntype="string" output="false">
	<cfargument name="storedUrl" type="string" required="yes">
	<cfset var markAt = find("?",arguments.storedUrl)>

	<cfif markAt EQ 0>
		<cfreturn "">
	</cfif>
	<cfreturn right(arguments.storedUrl,len(arguments.storedUrl) - markAt)>
</cffunction>

<!--- Function sqlBodyOf isolates the part of a dump report that describes the generated SQL,
	discarding the header lines that legitimately differ between runs such as the run label and
	the session roles.  Hashing only this part means a hash change always signals a real change
	in generated SQL.

	@param report the full text of one /tools/searchSqlDump.cfm response.
	@return the report from the basJoin marker to the END marker, or an empty string if the
		report is truncated or malformed.
--->
<cffunction name="sqlBodyOf" access="private" returntype="string" output="false">
	<cfargument name="report" type="string" required="yes">
	<cfset var startAt = find("--- basJoin ---",arguments.report)>
	<cfset var endAt = find("=== MCZbase SearchSql dump END ===",arguments.report)>

	<cfif startAt EQ 0 OR endAt EQ 0 OR endAt LTE startAt>
		<cfreturn "">
	</cfif>
	<cfreturn trim(mid(arguments.report,startAt,endAt - startAt))>
</cffunction>

<cfset variables.runResults = arrayNew(1)>
<cfset variables.digest = "">

<cfif variables.action EQ "capture">
	<cfdirectory action="create" directory="#variables.runDir#" mode="770" storeacl="no">
	<cfset variables.seq = 0>
	<cfset variables.manifest = "seq" & chr(9) & "source" & chr(9) & "id" & chr(9) & "status" & chr(9) & "method" & chr(9) & "httpStatus" & chr(9) & "sqlHash" & chr(9) & "file" & chr(9) & "url" & chr(10)>
	<cfset variables.digest = "## MCZbase Redmine 1031 SearchSql baseline digest" & chr(10)>
	<cfset variables.digest = variables.digest & "## label=" & variables.dumpLabel & " flatTableName=" & session.flatTableName & " generated=" & dateformat(now(),"yyyy-mm-dd") & "T" & timeformat(now(),"HH:mm:ss") & chr(10)>
	<cfset variables.digest = variables.digest & "## columns: seq, id, status, method, sqlHash, criteria" & chr(10)>

	<cfloop array="#variables.entries#" index="variables.entry">
		<cfset variables.seq = variables.seq + 1>
		<cfset variables.qs = queryStringOf(variables.entry.url)>
		<cfset variables.outFile = numberFormat(variables.seq,"0000") & "_" & variables.entry.id & ".txt">
		<cfset variables.status = "UNKNOWN">
		<cfset variables.httpStatus = "">
		<cfset variables.method = "">
		<cfset variables.body = "">
		<cfset variables.sqlHash = "">
		<cfif len(variables.qs) EQ 0>
			<cfset variables.status = "NO_CRITERIA">
			<cfset variables.body = "Stored URL carried no query string, nothing to dump." & chr(10) & variables.entry.url>
		<cfelse>
			<cftry>
				<cfset variables.target = variables.baseUrl & "/tools/searchSqlDump.cfm?dumpLabel=" & encodeForUrl(variables.dumpLabel)>
				<cfif len(variables.qs) LTE variables.MAX_GET_QUERYSTRING_LEN>
					<cfset variables.method = "GET">
					<cfhttp url="#variables.target#&#variables.qs#" method="get" charset="utf-8" timeout="90" throwonerror="false" result="dumpCall">
						<!--- Forward the session identifiers so the child request runs as this user and
							therefore sees the same session.flatTableName, roles and credentials. --->
						<cfhttpparam type="cookie" name="cfid" value="#cookie.cfid#">
						<cfhttpparam type="cookie" name="cftoken" value="#cookie.cftoken#">
					</cfhttp>
				<cfelse>
					<cfset variables.method = "POST">
					<cfhttp url="#variables.target#" method="post" charset="utf-8" timeout="90" throwonerror="false" result="dumpCall">
						<cfhttpparam type="cookie" name="cfid" value="#cookie.cfid#">
						<cfhttpparam type="cookie" name="cftoken" value="#cookie.cftoken#">
						<cfhttpparam type="header" name="Content-Type" value="application/x-www-form-urlencoded">
						<cfhttpparam type="body" value="#variables.qs#">
					</cfhttp>
				</cfif>
				<cfset variables.httpStatus = dumpCall.statusCode>
				<cfset variables.body = dumpCall.fileContent>
				<cfif left(variables.httpStatus,3) NEQ "200">
					<cfset variables.status = "HTTP_ERROR">
				<cfelse>
					<cfset variables.sqlHash = "">
					<cfif len(sqlBodyOf(variables.body)) GT 0>
						<cfset variables.status = "OK">
						<cfset variables.sqlHash = lcase(hash(sqlBodyOf(variables.body),"MD5"))>
					<cfelse>
						<!--- SearchSql.cfm aborted, most likely on input it rejects as invalid. --->
						<cfset variables.status = "ABORTED">
					</cfif>
				</cfif>
			<cfcatch>
				<cfset variables.status = "FETCH_ERROR">
				<cfset variables.body = "#cfcatch.message# #cfcatch.detail#">
			</cfcatch>
			</cftry>
		</cfif>
		<cffile action="write" file="#variables.runDir#/#variables.outFile#" output="#variables.body#" charset="utf-8" addnewline="no">
		<cfset variables.manifest = variables.manifest & variables.seq & chr(9) & variables.entry.source & chr(9) & variables.entry.id & chr(9) & variables.status & chr(9) & variables.method & chr(9) & variables.httpStatus & chr(9) & variables.sqlHash & chr(9) & variables.outFile & chr(9) & variables.entry.url & chr(10)>
		<!--- Criteria are truncated in the digest to keep it pasteable; the manifest file on the
			server carries the full URL for any entry that needs investigating. --->
		<cfset variables.digestCriteria = variables.qs>
		<cfif len(variables.digestCriteria) GT 160>
			<cfset variables.digestCriteria = left(variables.digestCriteria,160) & "...[truncated, " & len(variables.qs) & " chars]">
		</cfif>
		<cfset variables.digest = variables.digest & variables.seq & chr(9) & variables.entry.id & chr(9) & variables.status & chr(9) & variables.method & chr(9) & variables.sqlHash & chr(9) & variables.digestCriteria & chr(10)>
		<cfset arrayAppend(variables.runResults,{
			seq = variables.seq,
			id = variables.entry.id,
			name = variables.entry.name,
			status = variables.status,
			method = variables.method,
			httpStatus = variables.httpStatus,
			sqlHash = variables.sqlHash,
			outFile = variables.outFile
		})>
	</cfloop>
	<cffile action="write" file="#variables.runDir#/manifest.tsv" output="#variables.manifest#" charset="utf-8" addnewline="no">
	<cffile action="write" file="#variables.runDir#/digest.tsv" output="#variables.digest#" charset="utf-8" addnewline="no">
</cfif>

<cfoutput>
<main class="container py-3" id="content">
	<section class="row border rounded my-2 p-2">
		<div class="col-12 pt-2">
			<h1 class="h2">Redmine 1031 Phase 1 Baseline Capture</h1>
			<p>
				One submit runs <code>/tools/searchSqlDump.cfm</code> once for every corpus entry.
				Nothing here executes the assembled search SQL.
			</p>
			<p class="mb-1">
				<strong>Capture <code>before</code> on an unmodified checkout, then <code>after</code> once
				phase 3 is done, using the same login both times.</strong>
				<code>session.flatTableName</code> is <code>FLAT</code> for internal users and
				<code>FILTERED_FLAT</code> for external ones, and that token appears throughout the
				generated SQL.
			</p>
			<p>
				This session would capture as: <strong>#encodeForHtml(session.flatTableName)#</strong>
			</p>
			<form name="capture" id="capture" method="post" action="/tools/searchSqlBaseline.cfm">
				<input type="hidden" name="action" id="action" value="capture">
				<div class="form-row">
					<div class="col-12 col-md-3">
						<label for="dumpLabel" class="data-entry-label">Run label (directory name)</label>
						<input type="text" name="dumpLabel" id="dumpLabel" class="data-entry-input mb-1" value="#encodeForHtml(variables.dumpLabel)#" required pattern="[A-Za-z0-9_\-]{1,40}">
					</div>
					<div class="col-12 col-md-3">
						<label for="maxEntries" class="data-entry-label">Max entries (0 for all)</label>
						<input type="text" name="maxEntries" id="maxEntries" class="data-entry-input mb-1" value="#encodeForHtml(variables.maxEntries)#">
					</div>
					<div class="col-12 col-md-6">
						<label for="outputDir" class="data-entry-label">Output directory</label>
						<input type="text" name="outputDir" id="outputDir" class="data-entry-input mb-1" value="#encodeForHtml(variables.outputDir)#">
					</div>
				</div>
				<div class="form-row">
					<div class="col-12 col-md-6">
						<label for="baseUrl" class="data-entry-label">Base URL for self requests</label>
						<input type="text" name="baseUrl" id="baseUrl" class="data-entry-input mb-1" value="#encodeForHtml(variables.baseUrl)#">
						<small class="text-secondary">If the server cannot verify its own certificate, use http://127.0.0.1 here.</small>
					</div>
					<div class="col-12 col-md-6">
						<label for="extraUrls" class="data-entry-label">Additional URLs, one per line (optional)</label>
						<textarea name="extraUrls" id="extraUrls" class="data-entry-input mb-1" rows="4">#encodeForHtml(form.extraUrls)#</textarea>
						<small class="text-secondary">For example harvested from web server logs. Only the query string is used.</small>
					</div>
				</div>
				<button type="submit" class="btn btn-xs btn-primary mt-2">Capture baseline</button>
			</form>
		</div>
	</section>

	<cfif variables.action EQ "capture">
		<cfset variables.countOk = 0>
		<cfset variables.countAborted = 0>
		<cfset variables.countOther = 0>
		<cfloop array="#variables.runResults#" index="variables.row">
			<cfif variables.row.status EQ "OK"><cfset variables.countOk = variables.countOk + 1>
			<cfelseif variables.row.status EQ "ABORTED"><cfset variables.countAborted = variables.countAborted + 1>
			<cfelse><cfset variables.countOther = variables.countOther + 1>
			</cfif>
		</cfloop>
		<section class="row border rounded my-2 p-2">
			<div class="col-12 pt-2">
				<h2 class="h3">Digest</h2>
				<p>
					One line per entry with a hash of the generated SQL. Comparing a
					<code>before</code> digest against an <code>after</code> digest identifies exactly
					which criteria combinations changed behaviour. Select all and copy.
				</p>
				<p>
					OK: #variables.countOk# &nbsp; Aborted by SearchSql.cfm: #variables.countAborted#
					&nbsp; Other: #variables.countOther#
					&nbsp;&mdash;&nbsp; also written to <code>#encodeForHtml(variables.runDir)#/digest.tsv</code>
				</p>
				<label for="digestText" class="sr-only">Baseline digest, tab separated</label>
				<textarea id="digestText" class="w-100" rows="24" readonly onclick="this.select();">#encodeForHtml(variables.digest)#</textarea>
			</div>
		</section>
		<section class="row border rounded my-2 mb-4 p-2">
			<div class="col-12 pt-2">
				<h2 class="h3">Run results</h2>
				<p>
					Wrote #arrayLen(variables.runResults)# report(s), <code>manifest.tsv</code> and
					<code>digest.tsv</code> to <code>#encodeForHtml(variables.runDir)#</code>
				</p>
				<p class="small text-secondary">
					To compare two runs on the server:
					<code>diff -r #encodeForHtml(variables.outputDir)#/before #encodeForHtml(variables.outputDir)#/after</code>
				</p>
				<table class="table table-responsive table-striped d-xl-table">
					<thead class="thead-light">
						<tr>
							<th>##</th>
							<th>Status</th>
							<th>Method</th>
							<th>HTTP</th>
							<th>SQL hash</th>
							<th>Saved search</th>
							<th>File</th>
						</tr>
					</thead>
					<tbody>
						<cfloop array="#variables.runResults#" index="variables.row">
							<cfset variables.statusClass = "">
							<cfif variables.row.status EQ "OK"><cfset variables.statusClass = "text-success"></cfif>
							<cfif variables.row.status EQ "ABORTED"><cfset variables.statusClass = "text-warning font-weight-bold"></cfif>
							<cfif listFindNoCase("HTTP_ERROR,FETCH_ERROR",variables.row.status)><cfset variables.statusClass = "text-danger font-weight-bold"></cfif>
							<tr>
								<td>#variables.row.seq#</td>
								<td class="#variables.statusClass#">#encodeForHtml(variables.row.status)#</td>
								<td>#encodeForHtml(variables.row.method)#</td>
								<td>#encodeForHtml(variables.row.httpStatus)#</td>
								<td class="small">#encodeForHtml(variables.row.sqlHash)#</td>
								<td>#encodeForHtml(variables.row.name)#</td>
								<td>#encodeForHtml(variables.row.outFile)#</td>
							</tr>
						</cfloop>
					</tbody>
				</table>
			</div>
		</section>
	<cfelse>
		<section class="row border rounded my-2 mb-4 p-2">
			<div class="col-12 pt-2">
				<h2 class="h3">Corpus preview: #arrayLen(variables.entries)# entries</h2>
				<p>
					Saved searches in <code>cf_canned_search</code> targeting SpecimenResults.cfm.
					Nothing has been fetched or written yet. One submit above processes all of them.
				</p>
				<table class="table table-responsive table-striped d-xl-table">
					<thead class="thead-light">
						<tr><th>##</th><th>Source</th><th>id</th><th>Saved search</th><th>Criteria</th></tr>
					</thead>
					<tbody>
						<cfset variables.previewSeq = 0>
						<cfloop array="#variables.entries#" index="variables.entry">
							<cfset variables.previewSeq = variables.previewSeq + 1>
							<cfset variables.previewCriteria = queryStringOf(variables.entry.url)>
							<cfif len(variables.previewCriteria) GT 160>
								<cfset variables.previewCriteria = left(variables.previewCriteria,160) & "...[truncated, " & len(queryStringOf(variables.entry.url)) & " chars]">
							</cfif>
							<tr>
								<td>#variables.previewSeq#</td>
								<td>#encodeForHtml(variables.entry.source)#</td>
								<td>#encodeForHtml(variables.entry.id)#</td>
								<td>#encodeForHtml(variables.entry.name)#</td>
								<td class="small">#encodeForHtml(variables.previewCriteria)#</td>
							</tr>
						</cfloop>
					</tbody>
				</table>
			</div>
		</section>
	</cfif>
</main>
</cfoutput>
<cfinclude template="/shared/_footer.cfm">
