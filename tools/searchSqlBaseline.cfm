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

	Visit the page and it runs: no form, no options to set.  It puts every corpus entry through
	/includes/SearchSql.cfm and prints one line per entry carrying a hash of the generated SQL.
	Copy the whole report.

	Comparing a report taken before parameterizing SearchSql.cfm against one taken after
	identifies exactly which criteria combinations changed behaviour, so nobody has to read
	several hundred SQL dumps -- only the entries whose hash moved need their full report
	examined, and /tools/searchSqlDump.cfm produces that for one entry on demand.

	Nothing is written to disk and the assembled search SQL is never executed.

	Output is flushed as each entry completes, because two things can end this page early:
	SearchSql.cfm calls <cfabort> on input it rejects, and several hundred entries can outrun
	the request timeout.  Either way the lines already printed are in the browser, and the tail
	of the report says how to resume.

	Optional url parameters, none normally needed:
		label      names the run in the report header, default "before"
		startAt    first entry to process, for resuming after an early end, default 1
		maxEntries how many entries to process from startAt, default all
		showSql    1 prints the constructed query under each entry, the default; 0 omits it

	Corpus: the saved searches in cf_canned_search whose URL targets SpecimenResults.cfm.
	Real parameter combinations that real users saved, including combinations nobody would
	think to write a test for.

	Running SearchSql.cfm repeatedly in one request needs care: the include leaves roughly 163
	criteria variables in the variables scope, so a naive loop would have each entry inherit
	the previous entry's criteria and the report would be quietly wrong.  Each iteration
	therefore deletes every key it introduced before the next one starts.

	Use the same login for the before and after runs: session.flatTableName is FLAT for
	internal users and FILTERED_FLAT for external ones, and that token appears throughout the
	generated SQL.  SearchSql.cfm never branches on its value, only interpolates it as an
	identifier, so that token is the only difference between the two user classes.
--->
<cfsetting enablecfoutputonly="true">
<cfif NOT (isDefined("session.roles") AND listContainsNoCase(session.roles,"manage_specimens"))>
	<!--- extra check to ensure access only by authorized users --->
	<cfthrow message="Inadequate Permissions.">
</cfif>
<cfif NOT isDefined("session.flatTableName")>
	<cfthrow message="session.flatTableName is not set. Log in before running the harness.">
</cfif>

<cfparam name="url.label" default="before">
<cfparam name="url.startAt" default="1">
<cfparam name="url.maxEntries" default="0">
<cfparam name="url.showSql" default="1">
<cfset variables.runLabel = url.label>
<cfif REFind("^[A-Za-z0-9_\-]{1,40}$",variables.runLabel) EQ 0>
	<cfset variables.runLabel = "before">
</cfif>
<cfset variables.startAt = url.startAt>
<cfif NOT isNumeric(variables.startAt) OR variables.startAt LT 1><cfset variables.startAt = 1></cfif>
<cfset variables.maxEntries = url.maxEntries>
<cfif NOT isNumeric(variables.maxEntries) OR variables.maxEntries LT 0><cfset variables.maxEntries = 0></cfif>
<!--- The constructed query is printed under each entry by default.  A hash tells you that
	something moved but not what, and once phase 3 has landed the old SQL cannot be reproduced
	without checking out the earlier commit, so the baseline has to carry the queries
	themselves to be useful for debugging a mismatch.  showSql=0 gives the compact hash only
	report when that is all that is wanted. --->
<cfset variables.showSql = 1>
<cfif isNumeric(url.showSql) AND url.showSql EQ 0><cfset variables.showSql = 0></cfif>

<!--- Several hundred criteria sets in one page visit. --->
<cfsetting requesttimeout="3600">

<!--- Load functionLib here, before the pristine key snapshot below, and not incidentally via
	the dump page.  SearchSql.cfm calls escapeQuotes, isYear, listcatnumToBasQualTable and
	getMeters, which this file defines as user defined functions in the variables scope.  The
	dump page includes it with runOnce, so if the functions were first defined inside the loop
	the per iteration reset would delete them and runOnce would then refuse to define them
	again, and every entry after the first would fail with "Variable ESCAPEQUOTES is
	undefined".  Defining them before the snapshot makes them pristine, so the reset leaves
	them alone. --->
<cfinclude template="/includes/functionLib.cfm">

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

<cfset variables.entries = arrayNew(1)>
<cfloop query="corpus">
	<cfset arrayAppend(variables.entries,{
		id = corpus.canned_id,
		url = corpus.url
	})>
</cfloop>

<!--- Function queryStringOf extracts the query string from a stored search URL.

	@param storedUrl a URL as saved in cf_canned_search, which may or may not carry a scheme
		and host.
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

	@param report the full text of one dump report.
	@return the report from the basJoin marker to the END marker, or an empty string if the
		report is truncated or malformed, which is how an abort inside SearchSql.cfm is
		detected.
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

<!--- A bare <pre> rather than the site header and footer: this is a report to be copied whole,
	and <pre> is what preserves the tabs and line breaks that make it a table. --->
<cfoutput><html><head><title>Redmine 1031 SearchSql baseline</title></head><body><pre>
## MCZbase Redmine 1031 SearchSql baseline report
## label=#variables.runLabel# flatTableName=#session.flatTableName# generated=#dateformat(now(),"yyyy-mm-dd")#T#timeformat(now(),"HH:mm:ss")#
## corpus=#arrayLen(variables.entries)# entries
## columns: seq, canned_id, status, sqlHash, criteria, note
## Indented blocks under each entry are the constructed query as hashed. grep "^[0-9]" for summary lines only.
</cfoutput>
<cfflush>

<!--- Bookkeeping lives in the request scope, out of reach of the code under test: SearchSql.cfm
	writes freely into the variables scope, and the reset at the end of each iteration deletes
	every key the iteration introduced.  This is protection from the code being tested, not
	parameter passing between templates. --->
<cfset request.h = structNew()>
<cfset request.h.label = variables.runLabel>
<cfset request.h.countOk = 0>
<cfset request.h.countAborted = 0>
<cfset request.h.countError = 0>
<cfset request.h.countOther = 0>
<cfset request.h.firstSeq = variables.startAt>
<cfset request.h.lastSeq = variables.startAt - 1>
<cfset request.h.stopAt = arrayLen(variables.entries)>
<cfif variables.maxEntries GT 0>
	<cfset request.h.stopAt = min(arrayLen(variables.entries),variables.startAt + variables.maxEntries - 1)>
</cfif>

<!--- Declared before the snapshot so the per iteration reset leaves them alone, and so that
	the cfloop index and cfsavecontent variable attributes get plain unscoped names. --->
<cfset variables.hIdx = 0>
<cfset variables.hPair = "">
<cfset variables.hKey = "">
<cfset variables.hBody = "">

<!--- Every key present now survives the per iteration reset below. --->
<cfset request.h.pristineKeys = structKeyList(variables)>

<cfloop from="#variables.startAt#" to="#request.h.stopAt#" index="variables.hIdx">
	<cfset variables.thisEntry = variables.entries[variables.hIdx]>
	<cfset variables.qs = queryStringOf(variables.thisEntry.url)>
	<cfset variables.status = "UNKNOWN">
	<cfset variables.sqlHash = "">
	<cfset variables.body = "">
	<cfset variables.note = "">

	<cfif len(variables.qs) EQ 0>
		<cfset variables.status = "NO_CRITERIA">
	<cfelse>
		<!--- One entry that throws must not end the run: record it and carry on.  The parsing
			below is inside the try as well as the include, because malformed saved searches are
			exactly the kind of input that breaks a parser.  A <cfabort> inside SearchSql.cfm is
			not an exception and cannot be caught, which is why output is still flushed per entry
			and the report tail names a startAt to resume from. --->
		<cftry>
			<!--- Set each criterion under its own name in the variables scope, which is where
				SearchSql.cfm's unscoped isdefined("name") calls resolve.  Names that are not valid
				ColdFusion identifiers are skipped: unscoped lookup cannot see them, so production
				ignores them too, and some saved searches do carry malformed names such as
				"coll_role LIKE c". --->
			<cfloop list="#variables.qs#" delimiters="&" index="variables.hPair">
				<cfset variables.eqAt = find("=",variables.hPair)>
				<cfif variables.eqAt GT 1>
					<cfset variables.pName = left(variables.hPair,variables.eqAt - 1)>
					<!--- A parameter can carry an empty value, as CustomOidOper= does in several saved
						searches.  right() throws on a length of zero, and the parameter still has to be
						defined as an empty string, because production defines it that way in the url
						scope and some criteria blocks test isdefined() without also testing len(). --->
					<cfset variables.pValue = "">
					<cfif len(variables.hPair) GT variables.eqAt>
						<cfset variables.pValue = urlDecode(right(variables.hPair,len(variables.hPair) - variables.eqAt))>
					</cfif>
					<cfif REFind("^[A-Za-z_][A-Za-z0-9_]*$",variables.pName) GT 0>
						<cfset variables[variables.pName] = variables.pValue>
					</cfif>
				</cfif>
			</cfloop>
			<!--- The report itself comes from /tools/searchSqlDump.cfm, which also serves single
				entries on request.  One page for the harness means one page to permission, and the
				report shape cannot drift between the two callers.  harnessMode suppresses the content
				type and output suppression that page applies when requested directly. --->
			<cfset variables.harnessMode = "include">
			<cfset variables.harnessLabel = request.h.label>
			<cfset variables.harnessQueryString = variables.qs>
			<cfsavecontent variable="variables.hBody"><cfinclude template="/tools/searchSqlDump.cfm"></cfsavecontent>
			<cfset variables.body = variables.hBody>
		<cfcatch>
			<cfset variables.status = "ERROR">
			<cfset variables.note = "#cfcatch.type#: #cfcatch.message#">
		</cfcatch>
		</cftry>
	</cfif>

	<cfif variables.status EQ "UNKNOWN">
		<cfif len(sqlBodyOf(variables.body)) GT 0>
			<cfset variables.status = "OK">
			<cfset variables.sqlHash = lcase(hash(sqlBodyOf(variables.body),"MD5"))>
		<cfelse>
			<cfset variables.status = "ABORTED">
		</cfif>
	</cfif>
	<cfif variables.status EQ "OK">
		<cfset request.h.countOk = request.h.countOk + 1>
	<cfelseif variables.status EQ "ABORTED">
		<cfset request.h.countAborted = request.h.countAborted + 1>
	<cfelseif variables.status EQ "ERROR">
		<cfset request.h.countError = request.h.countError + 1>
	<cfelse>
		<cfset request.h.countOther = request.h.countOther + 1>
	</cfif>
	<cfset request.h.lastSeq = variables.hIdx>

	<!--- Criteria are truncated so the report stays a manageable size to copy. --->
	<cfset variables.reportCriteria = variables.qs>
	<cfif len(variables.reportCriteria) GT 160>
		<cfset variables.reportCriteria = left(variables.reportCriteria,160) & "...[truncated, " & len(variables.qs) & " chars]">
	</cfif>
	<!--- Line break emitted as chr(10) rather than as a literal newline in the template, so that
		it cannot be lost to whitespace handling between the tags. --->
	<cfoutput>#variables.hIdx##chr(9)##variables.thisEntry.id##chr(9)##variables.status##chr(9)##variables.sqlHash##chr(9)##encodeForHtml(variables.reportCriteria)##chr(9)##encodeForHtml(variables.note)##chr(10)#</cfoutput>
	<cfif variables.showSql EQ 1 AND len(variables.body) GT 0>
		<!--- The hashed section verbatim, indented under its entry.  Indenting rather than
			interleaving keeps the report greppable: "^[0-9]" selects the summary lines alone. --->
		<cfset variables.sqlForReport = sqlBodyOf(variables.body)>
		<cfif len(variables.sqlForReport) EQ 0>
			<!--- Aborted or malformed, so there is no hashed section; show what did come back so the
				failure can be read rather than guessed at. --->
			<cfset variables.sqlForReport = variables.body>
		</cfif>
		<!--- Indent with chr(9) rather than literal spaces in the template: ColdFusion whitespace
			management strips template whitespace from the generated output, so literal indentation
			never reaches the page, while a generated character does. --->
		<cfloop list="#variables.sqlForReport#" delimiters="#chr(10)#" index="variables.hSqlLine">
			<cfoutput>#chr(9)##encodeForHtml(variables.hSqlLine)##chr(10)#</cfoutput>
		</cfloop>
		<cfoutput>#chr(10)#</cfoutput>
	</cfif>
	<cfflush>

	<!--- Reset: delete every key this iteration introduced, so the next entry starts from the
		same state.  Without this the next entry would inherit this one's criteria and the report
		would be wrong in a way that looks plausible. --->
	<cfloop list="#structKeyList(variables)#" index="variables.hKey">
		<cfif NOT listFindNoCase(request.h.pristineKeys,variables.hKey)>
			<cfset structDelete(variables,variables.hKey)>
		</cfif>
	</cfloop>
</cfloop>

<cfoutput>
## END OF REPORT
## processed seq #request.h.firstSeq# through #request.h.lastSeq#
## OK #request.h.countOk#, ABORTED #request.h.countAborted#, ERROR #request.h.countError#, other #request.h.countOther#
<cfif request.h.lastSeq LT arrayLen(variables.entries)>## not finished: resume with ?startAt=#request.h.lastSeq + 1#&label=#variables.runLabel#
</cfif></pre></body></html>
</cfoutput>
