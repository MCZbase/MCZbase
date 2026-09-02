<!---
tools/searchSqlSpike.cfm

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
<!--- Redmine 1031 phase 0 spike.

	Answers the empirical questions that determine how /includes/SearchSql.cfm and its
	callers can be converted from string assembled SQL to parameterized queryExecute:

	T1  Does Oracle reject bind variables in CREATE TABLE ... AS SELECT (ORA-01027)?
	    SpecimenResults.cfm and bnhmMaps/kml.cfm both wrap the assembled select that way.
	T2  Does a bind free "WHERE 1=0" shell plus a parameterized INSERT work as a replacement?
	T3  Does SCORE(1) survive a shell whose predicate carries no CONTAINS?  The containssearch
	    block of SearchSql.cfm appends SCORE(1) to the select list, and Oracle ties SCORE(n)
	    to a labelled CONTAINS.
	T4  Does queryExecute honour cachedwithin in its options struct?  SpecimenResultsHTML.cfm
	    caches its results for 60 minutes and must keep doing so.
	T5  Do list=true bindings work for CF_SQL_VARCHAR and CF_SQL_DECIMAL?
	T6  Do any cf_spec_res_cols.sql_element rows carry the literal token flatTableName?  This
	    decides whether replace(sqlstring,"flatTableName",...) in SpecimenResults.cfm:199 and
	    kml.cfm:96 is load bearing or removable.

	This page creates and drops one scratch table owned by the session database user.  It
	executes no user supplied SQL and changes no application data.  Each test is wrapped
	independently so that one failure does not prevent the remaining tests from running.

	Run on a test server and record the results on Redmine 1031.
--->
<cfset pageTitle="Redmine 1031 Phase 0 Spike">
<cfinclude template="/shared/_header.cfm">
<cfif NOT (isDefined("session.roles") AND listContainsNoCase(session.roles,"manage_specimens"))>
	<!--- extra check to ensure access only by authorized users, this page creates a table --->
	<cfthrow message="Inadequate Permissions.">
</cfif>

<!--- The flat table name comes from the session and is used as an identifier, which cannot be
	bound.  Whitelist it, which is the control phase 4 will apply at the six include sites. --->
<cfset variables.FLAT_TABLE_ALLOWED = "flat,filtered_flat">
<cfset variables.flatTable = lcase(session.flatTableName)>
<cfif NOT listFindNoCase(variables.FLAT_TABLE_ALLOWED,variables.flatTable)>
	<cfthrow message="Unexpected value for session.flatTableName: not one of #variables.FLAT_TABLE_ALLOWED#.">
</cfif>

<!--- Scratch table name is constructed here from the session identity with no user input, the
	same discipline shared/loginFunctions.cfm:109 applies to session.SpecSrchTab.  Oracle
	identifiers are limited to 30 characters in the versions this application supports. --->
<cfset variables.DBOBJECTNAME_MAX_LEN = 30>
<cfset variables.scratchTable = "SPK1031_" & cookie.cfid>
<cfif REFind("^[A-Za-z][A-Za-z0-9_]*$",variables.scratchTable) EQ 0
		OR len(variables.scratchTable) GT variables.DBOBJECTNAME_MAX_LEN>
	<cfthrow message="Could not construct a safe scratch table name from the session.">
</cfif>

<cfset variables.results = arrayNew(1)>

<!--- Function recordResult appends one test outcome to the results array rendered at the end
	of the page.

	@param testName short identifier for the test, e.g. "T1".
	@param question what the test is asking.
	@param expectation what result would confirm the plan's assumption.
	@param status one of PASS, FAIL, ERROR or INFO.
	@param detail observed outcome, including any Oracle error text.
	@return void, appends to variables.results.
--->
<cffunction name="recordResult" access="private" returntype="void" output="false">
	<cfargument name="testName" type="string" required="yes">
	<cfargument name="question" type="string" required="yes">
	<cfargument name="expectation" type="string" required="yes">
	<cfargument name="status" type="string" required="yes">
	<cfargument name="detail" type="string" required="yes">

	<cfset arrayAppend(variables.results,{
		testName = arguments.testName,
		question = arguments.question,
		expectation = arguments.expectation,
		status = arguments.status,
		detail = arguments.detail
	})>
</cffunction>

<!--- Function dropScratchTable removes the spike's scratch table if it is present.  Used both
	before and after the tests so a previous aborted run cannot affect this one.

	@return true if a table was dropped, false if none was present.
--->
<cffunction name="dropScratchTable" access="private" returntype="boolean" output="false">
	<cftry>
		<!--- Query name is explicitly scoped: cfquery writes its result to the variables scope
			rather than the function local scope, so do not rely on a var declaration here. --->
		<cfquery name="variables.scratchTableCheck" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.short_timeout#">
			SELECT count(*) AS ct
			FROM user_tables
			WHERE
				table_name = upper(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.scratchTable#">)
		</cfquery>
		<cfif variables.scratchTableCheck.ct EQ 0>
			<cfreturn false>
		</cfif>
		<cfquery datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.short_timeout#">
			DROP TABLE #variables.scratchTable#
		</cfquery>
		<cfreturn true>
	<cfcatch>
		<cfreturn false>
	</cfcatch>
	</cftry>
</cffunction>

<cfset variables.droppedStale = dropScratchTable()>

<!--- ===================== T0 environment ===================== --->
<cfset variables.sampleCollCde = "">
<cftry>
	<cfquery name="sampleColl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.short_timeout#" result="sampleColl_result">
		SELECT collection_cde
		FROM collection
		WHERE
			ROWNUM = 1
	</cfquery>
	<cfset variables.sampleCollCde = sampleColl.collection_cde>
	<cfset recordResult("T0a","Is a real collection_cde available to use as a test criterion?","A value, so later row counts are meaningful.","INFO","Using collection_cde = #variables.sampleCollCde#")>
<cfcatch>
	<cfset recordResult("T0a","Is a real collection_cde available to use as a test criterion?","A value, so later row counts are meaningful.","ERROR","#cfcatch.message# #cfcatch.detail#")>
</cfcatch>
</cftry>

<!--- T3 is only interpretable once it is clear whether CONTAINS can work against this session's
	flat table at all.  For internal users session.flatTableName is FLAT, a table carrying the
	CTXSYS.CONTEXT domain index FLAT_TEXT_INDEX on CAT_NUM.  For external users it is
	FILTERED_FLAT, a view, which cannot carry an index of its own -- so the containssearch
	block of SearchSql.cfm:45 may not be usable at all for external sessions.  Establish which
	situation this run is in before reading T3. --->
<cftry>
	<!--- DISTINCT and an owner qualified join: the flat objects and their indexes are visible
		under more than one owner or edition, so an unqualified join multiplies rows. --->
	<cfquery name="flatObjectType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.short_timeout#" result="flatObjectType_result">
		SELECT DISTINCT object_type
		FROM all_objects
		WHERE
			upper(object_name) = upper(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.flatTable#">)
			AND object_type IN ('TABLE','VIEW')
		ORDER BY object_type
	</cfquery>
	<cfquery name="textIndex" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.short_timeout#" result="textIndex_result">
		SELECT DISTINCT all_indexes.index_name, all_indexes.index_type
		FROM all_indexes
			JOIN all_ind_columns ON (all_indexes.owner = all_ind_columns.index_owner
				AND all_indexes.index_name = all_ind_columns.index_name)
		WHERE
			upper(all_ind_columns.table_name) = upper(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.flatTable#">)
			AND upper(all_ind_columns.column_name) = 'CAT_NUM'
		ORDER BY all_indexes.index_name
	</cfquery>
	<cfset variables.flatTypeText = "not found">
	<cfif flatObjectType.recordcount GT 0><cfset variables.flatTypeText = valuelist(flatObjectType.object_type)></cfif>
	<cfset variables.domainIndexText = "none">
	<cfset variables.hasDomainIndex = false>
	<cfif textIndex.recordcount GT 0>
		<cfset variables.domainIndexText = "">
		<cfloop query="textIndex">
			<cfset variables.domainIndexText = listAppend(variables.domainIndexText,"#textIndex.index_name# (#textIndex.index_type#)")>
			<cfif textIndex.index_type EQ "DOMAIN"><cfset variables.hasDomainIndex = true></cfif>
		</cfloop>
	</cfif>
	<cfset variables.t0bNote = "">
	<cfif NOT variables.hasDomainIndex>
		<cfset variables.t0bNote = " No DOMAIN index is visible on this object, so containssearch cannot work for this user class at all. FILTERED_FLAT is a view and cannot carry one; that is a pre-existing condition, not caused by this refactor. Read any T3 failure below in that light.">
	</cfif>
	<cfset recordResult("T0b","Can CONTAINS work against #variables.flatTable#.cat_num in this session?","A DOMAIN index, so T3 measures SCORE(1) rather than a missing index.","INFO","#variables.flatTable# is a #variables.flatTypeText#. Indexes on its CAT_NUM: #variables.domainIndexText#.#variables.t0bNote#")>
<cfcatch>
	<cfset recordResult("T0b","Can CONTAINS work against #variables.flatTable#.cat_num in this session?","A DOMAIN index, so T3 measures SCORE(1) rather than a missing index.","ERROR","#cfcatch.message# #cfcatch.detail#")>
</cfcatch>
</cftry>

<!--- Probe CONTAINS on its own, with no CTAS and no SCORE, so that a T3 failure can be
	attributed either to SCORE(1) in a bind free shell or to CONTAINS being unusable here. --->
<cftry>
	<cfquery name="containsProbe" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.short_timeout#" result="containsProbe_result">
		SELECT count(*) AS ct
		FROM #variables.flatTable#
		WHERE
			CONTAINS(#variables.flatTable#.cat_num, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="spike">, 1) > 0
			AND ROWNUM <= 1
	</cfquery>
	<cfset recordResult("T0c","Does a plain CONTAINS query work against #variables.flatTable#?","Success, meaning containssearch is usable for this user class.","PASS","CONTAINS executed. Note it also accepted a bound search string, which is what phase 3 needs.")>
<cfcatch>
	<cfset recordResult("T0c","Does a plain CONTAINS query work against #variables.flatTable#?","Success, meaning containssearch is usable for this user class.","INFO","CONTAINS failed here: #cfcatch.message# #cfcatch.detail# -- if #variables.flatTable# is a view this is expected and pre-existing. Any T3 failure below is then explained by this, not by SCORE(1).")>
</cfcatch>
</cftry>

<!--- ===================== T1 bind in CTAS ===================== --->
<!--- If this SUCCEEDS the plan's central assumption is wrong and the CTAS restructure of
	phase 4 is unnecessary.  That would be the most valuable result this page can produce. --->
<cftry>
	<cfquery datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
		CREATE TABLE #variables.scratchTable# AS
		SELECT DISTINCT #variables.flatTable#.collection_object_id
		FROM #variables.flatTable#
			INNER JOIN cataloged_item ON (#variables.flatTable#.collection_object_id = cataloged_item.collection_object_id)
		WHERE
			#variables.flatTable#.collection_object_id IS NOT NULL
			AND cataloged_item.collection_cde = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.sampleCollCde#">
			AND ROWNUM <= 10
	</cfquery>
	<cfset recordResult("T1","Does Oracle allow a bind variable in CREATE TABLE ... AS SELECT?","Rejection with ORA-01027, confirming the CTAS sites must be restructured.","FAIL","The statement SUCCEEDED. Binds are permitted here, so the DDL shell plus INSERT restructure in phase 4 is NOT needed and the plan should be simplified.")>
	<cfset variables.discard = dropScratchTable()>
<cfcatch>
	<cfif findNoCase("ORA-01027",cfcatch.message & cfcatch.detail) GT 0>
		<cfset recordResult("T1","Does Oracle allow a bind variable in CREATE TABLE ... AS SELECT?","Rejection with ORA-01027, confirming the CTAS sites must be restructured.","PASS","Rejected as expected: #cfcatch.message# #cfcatch.detail#")>
	<cfelse>
		<cfset recordResult("T1","Does Oracle allow a bind variable in CREATE TABLE ... AS SELECT?","Rejection with ORA-01027, confirming the CTAS sites must be restructured.","ERROR","Failed, but not with ORA-01027. Read the error before concluding anything: #cfcatch.message# #cfcatch.detail#")>
	</cfif>
	<cfset variables.discard = dropScratchTable()>
</cfcatch>
</cftry>

<!--- ===================== T2 shell plus parameterized insert ===================== --->
<cfset variables.t2ShellOk = false>
<cftry>
	<cfquery datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
		CREATE TABLE #variables.scratchTable# AS
		SELECT DISTINCT #variables.flatTable#.collection_object_id
		FROM #variables.flatTable#
			INNER JOIN cataloged_item ON (#variables.flatTable#.collection_object_id = cataloged_item.collection_object_id)
		WHERE
			#variables.flatTable#.collection_object_id IS NOT NULL
			AND 1=0
	</cfquery>
	<cfset variables.t2ShellOk = true>
	<cfset recordResult("T2a","Does a bind free WHERE 1=0 shell create the table?","Success, with the same column list the insert will supply.","PASS","Table #variables.scratchTable# created empty.")>
<cfcatch>
	<cfset recordResult("T2a","Does a bind free WHERE 1=0 shell create the table?","Success, with the same column list the insert will supply.","FAIL","#cfcatch.message# #cfcatch.detail#")>
</cfcatch>
</cftry>

<cfif variables.t2ShellOk>
	<cftry>
		<cfquery datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#" result="t2Insert_result">
			INSERT INTO #variables.scratchTable#
			SELECT DISTINCT #variables.flatTable#.collection_object_id
			FROM #variables.flatTable#
				INNER JOIN cataloged_item ON (#variables.flatTable#.collection_object_id = cataloged_item.collection_object_id)
			WHERE
				#variables.flatTable#.collection_object_id IS NOT NULL
				AND cataloged_item.collection_cde = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.sampleCollCde#">
				AND ROWNUM <= 10
		</cfquery>
		<cfquery name="t2Count" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.short_timeout#">
			SELECT count(*) AS ct
			FROM #variables.scratchTable#
		</cfquery>
		<cfif t2Count.ct GT 0>
			<cfset recordResult("T2b","Does a parameterized INSERT ... SELECT into that table work?","Success with rows, confirming the phase 4 restructure is viable.","PASS","Inserted #t2Count.ct# row(s) with a bound criterion.")>
		<cfelse>
			<cfset recordResult("T2b","Does a parameterized INSERT ... SELECT into that table work?","Success with rows, confirming the phase 4 restructure is viable.","ERROR","The insert ran without error but produced 0 rows. The bind may not have matched; check the collection_cde used in T0a.")>
		</cfif>
	<cfcatch>
		<cfset recordResult("T2b","Does a parameterized INSERT ... SELECT into that table work?","Success with rows, confirming the phase 4 restructure is viable.","FAIL","#cfcatch.message# #cfcatch.detail#")>
	</cfcatch>
	</cftry>
</cfif>
<cfset variables.discard = dropScratchTable()>

<!--- ===================== T3 SCORE(1) in a shell with no CONTAINS ===================== --->
<cftry>
	<cfquery datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
		CREATE TABLE #variables.scratchTable# AS
		SELECT DISTINCT #variables.flatTable#.collection_object_id, SCORE(1) AS sco
		FROM #variables.flatTable#
			INNER JOIN cataloged_item ON (#variables.flatTable#.collection_object_id = cataloged_item.collection_object_id)
		WHERE
			#variables.flatTable#.collection_object_id IS NOT NULL
			AND 1=0
	</cfquery>
	<cfset recordResult("T3a","Does SCORE(1) survive a shell whose predicate has no CONTAINS?","Either outcome is useful. Success means one shell shape serves every criteria combination.","PASS","Accepted. The phase 4 shell can carry SCORE(1) without a matching CONTAINS.")>
	<cfset variables.discard = dropScratchTable()>
<cfcatch>
	<cfset recordResult("T3a","Does SCORE(1) survive a shell whose predicate has no CONTAINS?","Either outcome is useful. Failure means the shell must retain a bind free CONTAINS when containssearch is in play.","INFO","Rejected: #cfcatch.message# #cfcatch.detail# -- see T3b for the workaround.")>
	<cfset variables.discard = dropScratchTable()>
</cfcatch>
</cftry>

<cftry>
	<cfquery datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
		CREATE TABLE #variables.scratchTable# AS
		SELECT DISTINCT #variables.flatTable#.collection_object_id, SCORE(1) AS sco
		FROM #variables.flatTable#
			INNER JOIN cataloged_item ON (#variables.flatTable#.collection_object_id = cataloged_item.collection_object_id)
		WHERE
			#variables.flatTable#.collection_object_id IS NOT NULL
			AND CONTAINS(#variables.flatTable#.cat_num, 'spike', 1) > 0
			AND 1=0
	</cfquery>
	<cfset recordResult("T3b","Does SCORE(1) work in a shell that keeps a literal CONTAINS?","Success, giving a fallback shell shape for the containssearch case.","PASS","Accepted. If T3a failed, build the shell with the literal CONTAINS retained and bind the search text only in the INSERT.")>
	<cfset variables.discard = dropScratchTable()>
<cfcatch>
	<cfset recordResult("T3b","Does SCORE(1) work in a shell that keeps a literal CONTAINS?","Success, giving a fallback shell shape for the containssearch case.","FAIL","#cfcatch.message# #cfcatch.detail# -- if T0b found no text index this is expected and says nothing about SCORE(1).")>
	<cfset variables.discard = dropScratchTable()>
</cfcatch>
</cftry>

<!--- ===================== T4 queryExecute with cachedwithin ===================== --->
<cftry>
	<cfset variables.t4Sql = "SELECT count(*) AS ct FROM collection WHERE collection_cde = :cde">
	<cfset variables.t4Params = { cde = { value = variables.sampleCollCde, cfsqltype = "CF_SQL_VARCHAR" } }>
	<cfset variables.t4First = queryExecute(variables.t4Sql,variables.t4Params,{
		datasource = "user_login",
		username = session.dbuser,
		password = decrypt(session.epw,cookie.cfid),
		cachedwithin = createtimespan(0,0,10,0),
		result = "t4FirstResult"
	})>
	<cfset variables.t4Second = queryExecute(variables.t4Sql,variables.t4Params,{
		datasource = "user_login",
		username = session.dbuser,
		password = decrypt(session.epw,cookie.cfid),
		cachedwithin = createtimespan(0,0,10,0),
		result = "t4SecondResult"
	})>
	<cfset variables.t4FirstCached = "not reported">
	<cfset variables.t4SecondCached = "not reported">
	<cfif isDefined("variables.t4FirstResult") AND isStruct(variables.t4FirstResult) AND structKeyExists(variables.t4FirstResult,"cached")>
		<cfset variables.t4FirstCached = variables.t4FirstResult.cached>
	</cfif>
	<cfif isDefined("variables.t4SecondResult") AND isStruct(variables.t4SecondResult) AND structKeyExists(variables.t4SecondResult,"cached")>
		<cfset variables.t4SecondCached = variables.t4SecondResult.cached>
	</cfif>
	<cfif isBoolean(variables.t4SecondCached) AND variables.t4SecondCached>
		<cfset recordResult("T4","Does queryExecute honour cachedwithin in its options struct?","The second identical call reports cached = true.","PASS","First call cached: #variables.t4FirstCached#. Second call cached: #variables.t4SecondCached#. SpecimenResultsHTML.cfm can keep its 60 minute cache.")>
	<cfelse>
		<cfset recordResult("T4","Does queryExecute honour cachedwithin in its options struct?","The second identical call reports cached = true.","FAIL","First call cached: #variables.t4FirstCached#. Second call cached: #variables.t4SecondCached#. If caching is not honoured, SpecimenResultsHTML.cfm needs another mechanism or must accept losing the cache.")>
	</cfif>
<cfcatch>
	<cfset recordResult("T4","Does queryExecute honour cachedwithin in its options struct?","The second identical call reports cached = true.","ERROR","#cfcatch.message# #cfcatch.detail#")>
</cfcatch>
</cftry>

<!--- ===================== T5 list bindings ===================== --->
<cftry>
	<cfset variables.t5Varchar = queryExecute(
		"SELECT collection_cde FROM collection WHERE collection_cde IN (:cdes)",
		{ cdes = { value = variables.sampleCollCde, cfsqltype = "CF_SQL_VARCHAR", list = true } },
		{ datasource = "user_login", username = session.dbuser, password = decrypt(session.epw,cookie.cfid) }
	)>
	<cfset recordResult("T5a","Does a list=true CF_SQL_VARCHAR binding work for IN clauses?","Success, so the many IN (list) sites can each become one bind.","PASS","Returned #variables.t5Varchar.recordcount# row(s) for a single element list.")>
<cfcatch>
	<cfset recordResult("T5a","Does a list=true CF_SQL_VARCHAR binding work for IN clauses?","Success, so the many IN (list) sites can each become one bind.","FAIL","#cfcatch.message# #cfcatch.detail#")>
</cfcatch>
</cftry>

<cftry>
	<cfquery name="sampleCollIds" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.short_timeout#">
		SELECT collection_id
		FROM collection
		WHERE
			ROWNUM <= 3
	</cfquery>
	<cfset variables.t5Decimal = queryExecute(
		"SELECT collection_id FROM collection WHERE collection_id IN (:ids)",
		{ ids = { value = valuelist(sampleCollIds.collection_id), cfsqltype = "CF_SQL_DECIMAL", list = true } },
		{ datasource = "user_login", username = session.dbuser, password = decrypt(session.epw,cookie.cfid) }
	)>
	<cfif variables.t5Decimal.recordcount EQ sampleCollIds.recordcount>
		<cfset recordResult("T5b","Does a list=true CF_SQL_DECIMAL binding work for IN clauses?","Success, returning as many rows as ids supplied.","PASS","Supplied #sampleCollIds.recordcount# id(s), returned #variables.t5Decimal.recordcount# row(s).")>
	<cfelse>
		<cfset recordResult("T5b","Does a list=true CF_SQL_DECIMAL binding work for IN clauses?","Success, returning as many rows as ids supplied.","ERROR","Supplied #sampleCollIds.recordcount# id(s) but returned #variables.t5Decimal.recordcount# row(s). The list may not be expanding as expected.")>
	</cfif>
<cfcatch>
	<cfset recordResult("T5b","Does a list=true CF_SQL_DECIMAL binding work for IN clauses?","Success, returning as many rows as ids supplied.","FAIL","#cfcatch.message# #cfcatch.detail#")>
</cfcatch>
</cftry>

<!--- ===================== T6 flatTableName token in configuration ===================== --->
<cfset variables.t6Rows = "">
<cftry>
	<cfquery name="t6" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.short_timeout#" result="t6_result">
		SELECT column_name, sql_element
		FROM cf_spec_res_cols
		WHERE
			lower(sql_element) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%flattablename%">
		ORDER BY column_name
	</cfquery>
	<cfif t6.recordcount GT 0>
		<cfset recordResult("T6","Do any cf_spec_res_cols.sql_element rows carry the literal token flatTableName?","Either outcome is decisive for whether replace(sqlstring,...) can be removed.","INFO","#t6.recordcount# row(s) carry the token, so replace(sqlstring,'flatTableName',...) in SpecimenResults.cfm:199 and kml.cfm:96 IS load bearing and must be kept or replaced with an equivalent. Rows listed below.")>
		<cfset variables.t6Rows = t6>
	<cfelse>
		<cfset recordResult("T6","Do any cf_spec_res_cols.sql_element rows carry the literal token flatTableName?","Either outcome is decisive for whether replace(sqlstring,...) can be removed.","INFO","No rows carry the token. Combined with the absence of the token in SearchSql.cfm, replace(sqlstring,'flatTableName',...) can be removed in phase 4.")>
	</cfif>
<cfcatch>
	<cfset recordResult("T6","Do any cf_spec_res_cols.sql_element rows carry the literal token flatTableName?","Either outcome is decisive for whether replace(sqlstring,...) can be removed.","ERROR","#cfcatch.message# #cfcatch.detail#")>
</cfcatch>
</cftry>

<!--- Leave nothing behind.  Each test drops the scratch table on its own way out, so a false
	here is the normal case and means there was nothing left over to clean up.  Verify that
	no scratch table remains either way. --->
<cfset variables.finalDrop = dropScratchTable()>
<cfset variables.scratchResidual = "unknown">
<cftry>
	<cfquery name="residualCheck" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.short_timeout#">
		SELECT count(*) AS ct
		FROM user_tables
		WHERE
			table_name = upper(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.scratchTable#">)
	</cfquery>
	<cfset variables.scratchResidual = residualCheck.ct>
<cfcatch>
	<cfset variables.scratchResidual = "check failed: #cfcatch.message#">
</cfcatch>
</cftry>

<cfoutput>
<main class="container py-3" id="content">
	<section class="row border rounded my-2 p-2">
		<div class="col-12 pt-2">
			<h1 class="h2">Redmine 1031 Phase 0 Spike</h1>
			<p>
				Establishes whether the specimen search SQL can be parameterized as planned.
				Copy this table onto Redmine 1031.
			</p>
			<table class="table table-responsive table-striped d-xl-table">
				<thead class="thead-light">
					<tr>
						<th>Test</th>
						<th>Status</th>
						<th>Question</th>
						<th>Observed</th>
					</tr>
				</thead>
				<tbody>
					<cfloop array="#variables.results#" index="variables.row">
						<cfset variables.statusClass = "">
						<cfif variables.row.status EQ "PASS"><cfset variables.statusClass = "text-success font-weight-bold"></cfif>
						<cfif variables.row.status EQ "FAIL"><cfset variables.statusClass = "text-danger font-weight-bold"></cfif>
						<cfif variables.row.status EQ "ERROR"><cfset variables.statusClass = "text-warning font-weight-bold"></cfif>
						<tr>
							<td>#encodeForHtml(variables.row.testName)#</td>
							<td class="#variables.statusClass#">#encodeForHtml(variables.row.status)#</td>
							<td>
								#encodeForHtml(variables.row.question)#
								<br><span class="small text-secondary">Looking for: #encodeForHtml(variables.row.expectation)#</span>
							</td>
							<td>#encodeForHtml(variables.row.detail)#</td>
						</tr>
					</cfloop>
				</tbody>
			</table>
		</div>
	</section>
	<cfif isQuery(variables.t6Rows)>
		<section class="row border rounded my-2 p-2">
			<div class="col-12 pt-2">
				<h2 class="h3">T6 detail: cf_spec_res_cols rows carrying the flatTableName token</h2>
				<table class="table table-responsive table-striped d-xl-table">
					<thead class="thead-light">
						<tr><th>column_name</th><th>sql_element</th></tr>
					</thead>
					<tbody>
						<cfloop query="variables.t6Rows">
							<tr>
								<td>#encodeForHtml(variables.t6Rows.column_name)#</td>
								<td>#encodeForHtml(variables.t6Rows.sql_element)#</td>
							</tr>
						</cfloop>
					</tbody>
				</table>
			</div>
		</section>
	</cfif>
	<section class="row my-2 mb-4 p-2">
		<div class="col-12">
			<h2 class="h3">Run environment</h2>
			<ul>
				<li>session.flatTableName: #encodeForHtml(variables.flatTable)#</li>
				<li>scratch table used: #encodeForHtml(variables.scratchTable)#</li>
				<li>stale scratch table found and dropped before running: #variables.droppedStale#</li>
				<li>leftover scratch table dropped at end: #variables.finalDrop# (false is normal, each test cleans up as it exits)</li>
				<li>scratch tables still present (must be 0): #variables.scratchResidual#</li>
			</ul>
		</div>
	</section>
</main>
</cfoutput>
<cfinclude template="/shared/_footer.cfm">
