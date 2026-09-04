<!---
includes/sqlBuilder.cfm

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
<!--- Helpers for assembling a parameterized SQL WHERE clause.

	Used by /includes/SearchSql.cfm, which builds the specimen search criteria out of roughly
	140 independent optional blocks.  That cannot be expressed as a single <cfquery> with
	<cfqueryparam> tags, so the criteria are accumulated as an array of clause fragments
	carrying named bind tokens, plus a struct of the parameters those tokens refer to, and
	executed with queryExecute.  No user supplied value reaches the database except as a bind
	parameter.

	These live in /includes/ rather than /shared/, which would advertise them to redesigned
	pages; those build their SQL from the JSON search specification and the
	build_query_dbms_sql_nest stored procedure, by way of specimens/component/search.cfc.

	localities/component/search.cfc keeps its own private copy of addNamedQueryParam for
	getCollectingEvents_queryExecute, so that target pattern code does not depend on a legacy
	include.  Do not consolidate them.

	@see localities/component/search.cfc for the pattern these follow.
--->

<!--- Function addNamedQueryParam adds a named typed parameter to a queryExecute parameter
	struct and returns the token to write into the SQL text in its place.

	@param params struct of named query parameters to append to.
	@param paramBase trusted internal base name for generating a unique parameter name.
		MUST be code-defined, never user-provided, and must match [A-Za-z_][A-Za-z0-9_]*.
	@param value parameter value to bind.
	@param cfsqltype SQL type to use for binding, e.g. CF_SQL_VARCHAR.
	@param list true to bind value as a comma separated list, for an IN clause.
	@param scale optional numeric scale for decimal bindings.
	@return the generated named parameter token, e.g. :catnum_3, for use in the SQL text.
--->
<cffunction name="addNamedQueryParam" access="public" returntype="string" output="false">
	<cfargument name="params" type="struct" required="yes">
	<cfargument name="paramBase" type="string" required="yes">
	<cfargument name="value" required="yes">
	<cfargument name="cfsqltype" type="string" required="yes">
	<cfargument name="list" type="boolean" required="no" default="false">
	<cfargument name="scale" type="numeric" required="no">

	<cfset var paramName = "">
	<cfset var paramStruct = { value = arguments.value, cfsqltype = arguments.cfsqltype }>

	<!--- A user supplied string reaching this argument would put user content into the SQL text
		itself, which is the whole thing this file exists to prevent.  Fail loudly rather than
		generate a token from it. --->
	<cfif REFind("^[A-Za-z_][A-Za-z0-9_]*$",arguments.paramBase) EQ 0>
		<cfthrow type="Application" message="Invalid parameter base name for queryExecute binding.">
	</cfif>
	<!--- Suffixing with the running count makes the name unique across the whole struct, so the
		same paramBase can be reused inside a loop without collision. --->
	<cfset paramName = arguments.paramBase & "_" & (structCount(arguments.params) + 1)>
	<cfif arguments.list>
		<cfset paramStruct["list"] = true>
	</cfif>
	<cfif structKeyExists(arguments,"scale")>
		<cfset paramStruct["scale"] = arguments.scale>
	</cfif>
	<cfset arguments.params[paramName] = paramStruct>

	<cfreturn ":" & paramName>
</cffunction>

<!--- Function addNamedLikeParam binds a value for a case insensitive containment match, the
	idiom SearchSql.cfm uses at more than sixty sites in the form
	upper(field) LIKE '%#ucase(value)#%'.

	Having one function for it keeps the wildcards and the case folding consistent across those
	sites rather than repeating them by hand.  Note that a percent sign a user typed is still a
	wildcard once bound, exactly as it was when the value was interpolated, so this preserves
	the existing search behaviour rather than changing it.

	@param params struct of named query parameters to append to.
	@param paramBase trusted internal base name, as for addNamedQueryParam.
	@param value user supplied value to match anywhere within the field.
	@return the generated named parameter token for use after LIKE in the SQL text.
--->
<cffunction name="addNamedLikeParam" access="public" returntype="string" output="false">
	<cfargument name="params" type="struct" required="yes">
	<cfargument name="paramBase" type="string" required="yes">
	<cfargument name="value" type="string" required="yes">

	<cfreturn addNamedQueryParam(
		params = arguments.params,
		paramBase = arguments.paramBase,
		value = "%" & ucase(arguments.value) & "%",
		cfsqltype = "CF_SQL_VARCHAR"
	)>
</cffunction>

<!--- Function appendWhereClause adds one complete predicate to a WHERE clause array.

	Each element must stand on its own with no leading AND: the caller joins them.  Keeping
	them separate is what makes it impossible to leave a dangling conjunction behind when an
	inner condition takes an unexpected branch, which the single accumulated string it replaces
	allowed.

	@param whereClauses array of SQL WHERE clause fragments.
	@param clause one complete predicate, carrying bind tokens rather than values.
	@return the updated array, for assignment back by the caller.
--->
<cffunction name="appendWhereClause" access="public" returntype="array" output="false">
	<cfargument name="whereClauses" type="array" required="yes">
	<cfargument name="clause" type="string" required="yes">

	<cfif len(trim(arguments.clause)) GT 0>
		<cfset arrayAppend(arguments.whereClauses,trim(arguments.clause))>
	</cfif>

	<cfreturn arguments.whereClauses>
</cffunction>

<!--- Function whereClausesToSql joins a WHERE clause array into SQL to follow an existing
	WHERE, or returns an empty string when no criteria were supplied.

	@param whereClauses array of complete predicates.
	@return the predicates joined with AND and prefixed with AND, or an empty string.
--->
<cffunction name="whereClausesToSql" access="public" returntype="string" output="false">
	<cfargument name="whereClauses" type="array" required="yes">

	<cfif arrayLen(arguments.whereClauses) EQ 0>
		<cfreturn "">
	</cfif>

	<cfreturn " AND " & arrayToList(arguments.whereClauses," AND ")>
</cffunction>
