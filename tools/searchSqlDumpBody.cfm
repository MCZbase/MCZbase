<!---
tools/searchSqlDumpBody.cfm

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
<!--- Redmine 1031 phase 1 regression harness, shared report body.

	Seeds the caller variables the way SpecimenResults.cfm does, includes
	/includes/SearchSql.cfm, and emits the sections of the report that describe the generated
	SQL.  It NEVER executes the assembled SQL.

	Included by both harness entry points so that the two produce byte identical output:
	  /tools/searchSqlDump.cfm      one criteria set per HTTP request
	  /tools/searchSqlBaseline.cfm  the whole corpus in process, no HTTP
	A hash of this output is what before and after baselines are compared on, so the two entry
	points must not be allowed to drift apart in formatting.

	Expects, in the variables scope, before inclusion:
	  variables.flatTable       whitelisted flat table name
	  the search criteria themselves, under their own names, e.g. variables.catnum
	SearchSql.cfm reads criteria with isdefined("name"), which resolves unscoped against the
	variables scope, so criteria set as variables.catnum are found exactly as url.catnum would
	be on a real request.

	Emits nothing before the first section marker, so the caller controls the header.
--->

<!--- Function normalizeSqlFragment collapses runs of whitespace so that a reformatting change
	in SearchSql.cfm does not register as a behaviour change when baselines are diffed.

	@param sql a SQL fragment, possibly containing tabs and newlines.
	@return the fragment with each run of whitespace reduced to one space, trimmed.
--->
<cffunction name="normalizeSqlFragment" access="public" returntype="string" output="false">
	<cfargument name="sql" type="string" required="yes">

	<cfreturn trim(REReplace(arguments.sql,"\s+"," ","all"))>
</cffunction>

<!--- Seed exactly as SpecimenResults.cfm does at lines 188 to 194, except for basSelect, which
	is fixed rather than built from cf_spec_res_cols and session.resultColumnList so that the
	diff isolates the criteria assembly rather than each user's column preferences. --->
<cfset basSelect = " SELECT DISTINCT #variables.flatTable#.collection_object_id">
<cfset basFrom = " FROM #variables.flatTable#">
<cfset basJoin = "INNER JOIN cataloged_item ON (#variables.flatTable#.collection_object_id =cataloged_item.collection_object_id)">
<cfset basWhere = " WHERE #variables.flatTable#.collection_object_id IS NOT NULL ">
<cfset basQual = "">
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

<!--- basQual is the pre phase 3 contract: one accumulated string.  whereClauses and sqlParams
	are the post phase 3 contract.  Print whichever exist so that the same harness captures
	both the before and the after baseline. --->
<cfif isDefined("basQual")>
	<cfoutput>
--- basQual (string contract, pre phase 3) ---
#normalizeSqlFragment(basQual)#
</cfoutput>
</cfif>

<cfif isDefined("variables.whereClauses") AND isArray(variables.whereClauses)>
	<cfoutput>
--- whereClauses (array contract, post phase 3): #arrayLen(variables.whereClauses)# clause(s) ---
</cfoutput>
	<cfloop from="1" to="#arrayLen(variables.whereClauses)#" index="variables.clauseIndex">
		<cfoutput>[#variables.clauseIndex#] #normalizeSqlFragment(variables.whereClauses[variables.clauseIndex])#
</cfoutput>
	</cfloop>
</cfif>

<cfif isDefined("variables.sqlParams") AND isStruct(variables.sqlParams)>
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
</cfoutput>
