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
<!--- The diagnose button is a second submit on the capture form, so that a single request can
	be tried against whatever base URL has just been typed into the field. --->
<cfparam name="form.diagnoseNow" default="">
<cfif len(form.diagnoseNow) GT 0><cfset variables.action = "diagnose"></cfif>
<cfset variables.baseUrl = url.baseUrl>
<cfif len(form.baseUrl) GT 0><cfset variables.baseUrl = form.baseUrl></cfif>
<cfif len(variables.baseUrl) EQ 0><cfset variables.baseUrl = Application.serverRootUrl></cfif>
<cfset variables.outputDir = url.outputDir>
<cfif len(form.outputDir) GT 0><cfset variables.outputDir = form.outputDir></cfif>
<cfif len(variables.outputDir) EQ 0>
	<!--- Not getTempDirectory(): that is the ColdFusion working directory, which the developer
		who has to read and diff these files typically has no permission to enter. --->
	<cfset variables.outputDir = "/tmp/searchSqlBaseline">
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

<!--- Function fetchDump performs one request to /tools/searchSqlDump.cfm.

	Every cookie in the current request is forwarded, not just cfid and cftoken: the child
	request has to land in this same session or Application.cfc onRequestStart will call
	initSession() and hand it a guest identity, which then fails the dump page's role check.
	Which cookies matter depends on how the container is configured, so forward them all
	rather than guessing.

	@param target full URL to request.
	@param httpMethod "get" or "post".
	@param body request body for post, ignored for get.
	@return the cfhttp result struct, carrying statusCode, fileContent and errorDetail.
--->
<cffunction name="fetchDump" access="private" returntype="struct" output="false">
	<cfargument name="target" type="string" required="yes">
	<cfargument name="httpMethod" type="string" required="yes">
	<cfargument name="body" type="string" required="no" default="">

	<cfif arguments.httpMethod EQ "post">
		<cfhttp url="#arguments.target#" method="post" charset="utf-8" timeout="90" throwonerror="false" result="local.dumpCall">
			<cfloop collection="#cookie#" item="local.cookieName">
				<cfhttpparam type="cookie" name="#local.cookieName#" value="#cookie[local.cookieName]#">
			</cfloop>
			<cfhttpparam type="header" name="Content-Type" value="application/x-www-form-urlencoded">
			<cfhttpparam type="body" value="#arguments.body#">
		</cfhttp>
	<cfelse>
		<cfhttp url="#arguments.target#" method="get" charset="utf-8" timeout="90" throwonerror="false" result="local.dumpCall">
			<cfloop collection="#cookie#" item="local.cookieName">
				<cfhttpparam type="cookie" name="#local.cookieName#" value="#cookie[local.cookieName]#">
			</cfloop>
		</cfhttp>
	</cfif>
	<cfreturn local.dumpCall>
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

<!--- Diagnose mode: one request, with the whole cfhttp result reported.  When every entry in a
	run fails identically the cause is at the connection or authentication level, and the
	per-entry status alone does not say which.  This shows the actual status, error detail and
	response body so the cause is visible rather than guessed at. --->
<cfset variables.diagnosis = structNew()>
<cfif variables.action EQ "diagnose">
	<cfset variables.diagTarget = variables.baseUrl & "/tools/searchSqlDump.cfm?dumpLabel=diagnose&any_taxa_term=Pongo">
	<cftry>
		<cfset variables.diagCall = fetchDump(variables.diagTarget,"get")>
		<cfset variables.diagnosis.target = variables.diagTarget>
		<cfset variables.diagnosis.statusCode = variables.diagCall.statusCode>
		<cfset variables.diagnosis.mimeType = "">
		<cfif structKeyExists(variables.diagCall,"mimeType")><cfset variables.diagnosis.mimeType = variables.diagCall.mimeType></cfif>
		<cfset variables.diagnosis.errorDetail = "">
		<cfif structKeyExists(variables.diagCall,"errorDetail")><cfset variables.diagnosis.errorDetail = variables.diagCall.errorDetail></cfif>
		<cfset variables.diagnosis.body = left(variables.diagCall.fileContent,3000)>
	<cfcatch>
		<cfset variables.diagnosis.target = variables.diagTarget>
		<cfset variables.diagnosis.statusCode = "exception">
		<cfset variables.diagnosis.mimeType = "">
		<cfset variables.diagnosis.errorDetail = "#cfcatch.message# #cfcatch.detail#">
		<cfset variables.diagnosis.body = "">
	</cfcatch>
	</cftry>
</cfif>

<cfif variables.action EQ "capture">
	<cfdirectory action="create" directory="#variables.runDir#" mode="770" storeacl="no">
	<cfset variables.seq = 0>
	<cfset variables.manifest = "seq" & chr(9) & "source" & chr(9) & "id" & chr(9) & "status" & chr(9) & "method" & chr(9) & "httpStatus" & chr(9) & "sqlHash" & chr(9) & "file" & chr(9) & "url" & chr(10)>
	<cfset variables.digest = "## MCZbase Redmine 1031 SearchSql baseline digest" & chr(10)>
	<cfset variables.digest = variables.digest & "## label=" & variables.dumpLabel & " flatTableName=" & session.flatTableName & " generated=" & dateformat(now(),"yyyy-mm-dd") & "T" & timeformat(now(),"HH:mm:ss") & chr(10)>
	<cfset variables.digest = variables.digest & "## columns: seq, id, status, method, httpStatus, sqlHash, criteria" & chr(10)>

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
					<cfset dumpCall = fetchDump(variables.target & "&" & variables.qs,"get")>
				<cfelse>
					<cfset variables.method = "POST">
					<cfset dumpCall = fetchDump(variables.target,"post",variables.qs)>
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
		<cfset variables.digest = variables.digest & variables.seq & chr(9) & variables.entry.id & chr(9) & variables.status & chr(9) & variables.method & chr(9) & variables.httpStatus & chr(9) & variables.sqlHash & chr(9) & variables.digestCriteria & chr(10)>
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
						<small class="text-secondary">
							ColdFusion's cfhttp has no option to skip certificate verification, so on a server
							with a self signed certificate the public https URL fails for every entry. Bypass
							Apache and TLS by addressing the bundled application server directly, trying in
							order: <code>http://127.0.0.1:8500</code>, <code>http://localhost:8500</code>,
							<code>http://127.0.0.1</code>. Use "Diagnose a single request" to find which one
							answers before running the whole corpus.
						</small>
					</div>
					<div class="col-12 col-md-6">
						<label for="extraUrls" class="data-entry-label">Additional URLs, one per line (optional)</label>
						<textarea name="extraUrls" id="extraUrls" class="data-entry-input mb-1" rows="4">#encodeForHtml(form.extraUrls)#</textarea>
						<small class="text-secondary">For example harvested from web server logs. Only the query string is used.</small>
					</div>
				</div>
				<button type="submit" class="btn btn-xs btn-primary mt-2">Capture baseline</button>
				<button type="submit" name="diagnoseNow" id="diagnoseNow" value="1" class="btn btn-xs btn-secondary mt-2">Diagnose a single request</button>
				<small class="text-secondary d-block mt-1">
					Diagnose makes one request using the base URL above and reports the status, error
					detail and response body. Run it first if a capture reports every entry as
					HTTP_ERROR.
				</small>
			</form>
		</div>
	</section>

	<cfif variables.action EQ "diagnose">
		<section class="row border rounded my-2 p-2">
			<div class="col-12 pt-2">
				<h2 class="h3">Single request diagnosis</h2>
				<table class="table table-responsive d-xl-table">
					<tbody>
						<tr><th>Target</th><td class="small">#encodeForHtml(variables.diagnosis.target)#</td></tr>
						<tr><th>Status</th><td><strong>#encodeForHtml(variables.diagnosis.statusCode)#</strong></td></tr>
						<tr><th>MIME type</th><td>#encodeForHtml(variables.diagnosis.mimeType)#</td></tr>
						<tr><th>Error detail</th><td class="small">#encodeForHtml(variables.diagnosis.errorDetail)#</td></tr>
						<tr><th>Cookies forwarded</th><td class="small">#encodeForHtml(structKeyList(cookie))#</td></tr>
					</tbody>
				</table>
				<h3 class="h4">First 3000 characters of the response</h3>
				<label for="diagBody" class="sr-only">Response body</label>
				<textarea id="diagBody" class="w-100" rows="16" readonly onclick="this.select();">#encodeForHtml(variables.diagnosis.body)#</textarea>
				<p class="small text-secondary mt-2">
					A status of <code>Connection Failure</code> with no numeric code means the server could
					not connect to itself, usually certificate verification &mdash; retry with
					<code>http://127.0.0.1</code> as the base URL. A <code>500</code> carrying
					"Inadequate Permissions" means the session did not travel with the request, so the
					child request was treated as a guest. A <code>302</code> means something redirected it.
				</p>
			</div>
		</section>
	</cfif>

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
