<!---
tools/searchSqlDump.cfm

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
<!--- Redmine 1031 phase 1 regression harness, one criteria set.

	Seeds the caller variables the way SpecimenResults.cfm does, includes
	/includes/SearchSql.cfm, and prints the resulting SQL fragments and bind parameters as
	plain text.  It NEVER executes the assembled SQL.

	Purpose: capture a "before" baseline for every criteria combination in the corpus, then
	capture an "after" baseline once the include has been parameterized, and diff the two.
	With roughly 140 independent criteria blocks in SearchSql.cfm, behaviour preservation
	cannot be established by reading a diff of the source.

	This page serves two callers, so that the harness needs only one page to be permissioned:

	(1) Requested directly, one criteria set per request.  Criteria arrive in the query string
	    exactly as SpecimenResults.cfm receives them:
	        /tools/searchSqlDump.cfm?dumpLabel=before&catnum=1-5&country=Peru
	(2) Included by /tools/searchSqlBaseline.cfm, which sets variables.harnessMode to "include"
	    along with variables.harnessLabel and variables.harnessQueryString, having already put
	    the criteria into the variables scope itself, and captures this output with
	    <cfsavecontent>.  In that mode this page must not set the response content type or
	    suppress output, because the caller is rendering an HTML page around it.

	Output is whitespace normalized so that the reformatting phase 3 inevitably causes does
	not swamp the diff with noise.  BEGIN and END markers bracket the report: SearchSql.cfm
	calls <cfabort> on some invalid input, so a report with no END marker means the include
	aborted, which the driver reports as ABORTED rather than silently accepting a short file.

	Notes on fidelity:
	- Criteria are resolved by SearchSql.cfm's own isdefined("name") calls, which look in the
	  url scope on a direct request and in the variables scope when included.  This page
	  deliberately does NOT <cfparam> them: defining all 163 names would make isdefined() true
	  for every one and change which blocks fire.  Phase 5 of Redmine 1031 corrects the scope
	  handling in SearchSql.cfm and in this harness together.
	- checkSql() is deliberately not called here.  It contributes nothing to the dump and on
	  a hit it includes /errors/autoblacklist.cfm, which would blacklist the running user.
	- basSelect is fixed rather than built from cf_spec_res_cols and session.resultColumnList,
	  so the diff isolates the criteria assembly rather than each user's column preferences.
	- session.flatTableName differs by user class: FLAT for internal users, FILTERED_FLAT for
	  external.  SearchSql.cfm never branches on its value, only interpolates it as an
	  identifier, so the two classes' SQL differs by that token alone.  A baseline is
	  therefore valid as long as the before and after runs use the same user class, which is
	  why the class is recorded in the report header.
--->
<cfparam name="variables.harnessMode" default="request">
<cfif variables.harnessMode NEQ "include">
	<cfset variables.harnessMode = "request">
</cfif>

<cfif variables.harnessMode EQ "request">
	<cfsetting enablecfoutputonly="true">
	<cfcontent type="text/plain; charset=utf-8">
	<cfparam name="url.dumpLabel" default="unlabelled">
	<cfset variables.harnessLabel = url.dumpLabel>
	<cfset variables.harnessQueryString = cgi.query_string>
</cfif>

<!--- SearchSql.cfm calls escapeQuotes, listcatnumToBasQualTable, isYear and getMeters, which
	live in /includes/functionLib.cfm and not in the /shared/ copy.  runOnce keeps the repeated
	includes of the in process loop from redefining them for every corpus entry. --->
<cfinclude template="/includes/functionLib.cfm" runOnce="true">

<cfif NOT (isDefined("session.roles") AND listContainsNoCase(session.roles,"manage_specimens"))>
	<!--- extra check to ensure access only by authorized users --->
	<cfthrow message="Inadequate Permissions.">
</cfif>

<!--- The flat table name is an identifier and cannot be bound, so whitelist it here exactly as
	phase 4 will at the six include sites. --->
<cfset variables.FLAT_TABLE_ALLOWED = "flat,filtered_flat">
<cfif NOT isDefined("session.flatTableName")>
	<cfthrow message="session.flatTableName is not set. Log in before running the harness.">
</cfif>
<cfset variables.flatTable = lcase(session.flatTableName)>
<cfif NOT listFindNoCase(variables.FLAT_TABLE_ALLOWED,variables.flatTable)>
	<cfthrow message="Unexpected value for session.flatTableName: not one of #variables.FLAT_TABLE_ALLOWED#.">
</cfif>

<!--- Function normalizeSqlFragment collapses runs of whitespace so that a reformatting change
	in SearchSql.cfm does not register as a behaviour change when baselines are diffed.

	@param sql a SQL fragment, possibly containing tabs and newlines.
	@return the fragment with each run of whitespace reduced to one space, trimmed.
--->
<cffunction name="normalizeSqlFragment" access="public" returntype="string" output="false">
	<cfargument name="sql" type="string" required="yes">

	<cfreturn trim(REReplace(arguments.sql,"\s+"," ","all"))>
</cffunction>

<cfset variables.showObservations = "not set">
<cfif isDefined("session.ShowObservations")>
	<cfset variables.showObservations = session.ShowObservations>
</cfif>
<cfset variables.sessionCollection = "not set">
<cfif isDefined("session.collection")>
	<cfset variables.sessionCollection = session.collection>
</cfif>
<cfset variables.sessionRoles = "not set">
<cfif isDefined("session.roles")>
	<cfset variables.sessionRoles = session.roles>
</cfif>

<!--- Emit the header before including SearchSql.cfm so that an abort inside the include still
	leaves enough context in the output to identify which corpus entry failed. --->
<cfoutput>=== MCZbase SearchSql dump BEGIN ===
dumpLabel: #variables.harnessLabel#
flatTableName: #variables.flatTable#
session.roles: #variables.sessionRoles#
session.ShowObservations: #variables.showObservations#
session.collection: #variables.sessionCollection#
query_string: #variables.harnessQueryString#
</cfoutput>

<!--- Seed exactly as SpecimenResults.cfm does at lines 188 to 194, except for basSelect. --->
<cfset basSelect = " SELECT DISTINCT #variables.flatTable#.collection_object_id">
<cfset basFrom = " FROM #variables.flatTable#">
<cfset basJoin = "INNER JOIN cataloged_item ON (#variables.flatTable#.collection_object_id =cataloged_item.collection_object_id)">
<cfset basWhere = " WHERE #variables.flatTable#.collection_object_id IS NOT NULL ">
<cfset basOrder = "">
<cfset mapurl = "">

<cfinclude template="/includes/SearchSql.cfm">

<cfoutput>
--- basJoin ---
#normalizeSqlFragment(basJoin)#

--- basWhere ---
#normalizeSqlFragment(basWhere)#

--- basOrder ---
#normalizeSqlFragment(basOrder)#
</cfoutput>

<!--- Printed under the basQual heading the earlier baselines used, so that a report captured
	now stays comparable with one captured before the criteria were parameterized. --->
<cfoutput>
--- basQual (string contract, pre phase 3) ---
#normalizeSqlFragment(whereClausesToSql(variables.whereClauses))#
</cfoutput>

<!--- Printed only when non-empty.  SearchSql.cfm now always defines both, so an unconditional
	section would change the hashed body of every entry the moment the contract was introduced,
	before any criteria block had actually been converted, and the phase 1 baseline would stop
	being a usable check.  Empty means nothing converted yet; a section appearing is itself the
	signal that this entry's criteria now bind. --->
<cfif isDefined("variables.whereClauses") AND isArray(variables.whereClauses) AND arrayLen(variables.whereClauses) GT 0>
	<cfoutput>
--- whereClauses (array contract, post phase 3): #arrayLen(variables.whereClauses)# clause(s) ---
</cfoutput>
	<cfloop from="1" to="#arrayLen(variables.whereClauses)#" index="variables.clauseIndex">
		<cfoutput>[#variables.clauseIndex#] #normalizeSqlFragment(variables.whereClauses[variables.clauseIndex])#
</cfoutput>
	</cfloop>
</cfif>

<cfif isDefined("variables.sqlParams") AND isStruct(variables.sqlParams) AND structCount(variables.sqlParams) GT 0>
	<cfoutput>
--- sqlParams (post phase 3): #structCount(variables.sqlParams)# parameter(s) ---
</cfoutput>
	<!--- Sorted so the report is deterministic regardless of struct iteration order. --->
	<cfset variables.paramNames = listToArray(listSort(structKeyList(variables.sqlParams),"textnocase"))>
	<cfloop array="#variables.paramNames#" index="variables.paramName">
		<cfset variables.thisParam = variables.sqlParams[variables.paramName]>
		<cfset variables.paramType = "">
		<cfset variables.paramList = "false">
		<cfset variables.paramValue = "">
		<cfif isStruct(variables.thisParam)>
			<cfif structKeyExists(variables.thisParam,"cfsqltype")><cfset variables.paramType = variables.thisParam.cfsqltype></cfif>
			<cfif structKeyExists(variables.thisParam,"list")><cfset variables.paramList = variables.thisParam.list></cfif>
			<cfif structKeyExists(variables.thisParam,"value")><cfset variables.paramValue = variables.thisParam.value></cfif>
		<cfelse>
			<cfset variables.paramValue = variables.thisParam>
		</cfif>
		<cfoutput>#variables.paramName# | #variables.paramType# | list=#variables.paramList# | #variables.paramValue#
</cfoutput>
	</cfloop>
</cfif>

<cfoutput>
--- mapurl ---
#mapurl#

=== MCZbase SearchSql dump END ===
</cfoutput>
