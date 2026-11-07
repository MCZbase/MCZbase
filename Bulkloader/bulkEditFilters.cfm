<!---
Bulkloader/bulkEditFilters.cfm

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
<!--- Included by the bulk edit page, Bulkloader/browseBulk.cfm. --->
<!--- Column names cannot be bound, so each one a request names is checked against BULKLOADER's
	columns in the data dictionary, and each operator against FILTEROPERATORS, before it is written
	into a statement. --->
<cfset FILTEROPERATORS = "=,like,in,between">
<cfquery name="bulkloaderColumnQuery" datasource="uam_god" result="bulkloaderColumnQuery_result">
	SELECT column_name
	FROM all_tab_columns
	WHERE owner = 'MCZBASE' AND table_name = 'BULKLOADER'
</cfquery>
<cfset BULKLOADERCOLUMNS = structNew()>
<cfloop query="bulkloaderColumnQuery">
	<cfset BULKLOADERCOLUMNS[ucase(bulkloaderColumnQuery.column_name)] = true>
</cfloop>

<!---
	requestValue the value of a request parameter, from the form or else the url.

	@param name the parameter name.
	@return its value, or an empty string if neither scope has it.
--->
<cffunction name="requestValue" returntype="string" output="false">
	<cfargument name="name" type="string" required="yes">
	<cfif structKeyExists(form, arguments.name)>
		<cfreturn form[arguments.name]>
	<cfelseif structKeyExists(url, arguments.name)>
		<cfreturn url[arguments.name]>
	</cfif>
	<cfreturn "">
</cffunction>

<!---
	collectFilters the column, operator and value filters c1/op1/v1 to c3/op3/v3 of the bulk edit
	forms, each with all three parts given, checked so that they can be written into a statement.

	@return a structure of filters, an array of structures of column, op, value and, for between,
		low and high; and problem, a message if a filter names an unknown column or operator or an
		unusable range, otherwise empty.
--->
<cffunction name="collectFilters" returntype="struct" output="false">
	<cfset var result = { filters = [], problem = "" }>
	<cfset var n = 0>
	<cfset var filter = "">
	<cfset var dash = 0>
	<cfloop from="1" to="3" index="n">
		<cfset filter = { column = ucase(trim(requestValue("c#n#"))), op = lcase(trim(requestValue("op#n#"))), value = requestValue("v#n#") }>
		<cfif len(filter.column) GT 0 AND len(filter.op) GT 0 AND len(filter.value) GT 0>
			<cfif NOT structKeyExists(BULKLOADERCOLUMNS, filter.column)>
				<cfset result.problem = "Filter #n# names a column the bulkloader does not have.">
			<cfelseif listFind(FILTEROPERATORS, filter.op) EQ 0>
				<cfset result.problem = "Filter #n# has an operator other than #FILTEROPERATORS#.">
			<cfelse>
				<cfif filter.op EQ "between">
					<cfset dash = find("-", filter.value, 2)>
					<cfif dash EQ 0 OR NOT isNumeric(trim(left(filter.value, dash - 1))) OR NOT isNumeric(trim(mid(filter.value, dash + 1, len(filter.value))))>
						<cfset result.problem = "Filter #n# needs a numeric range written low-high for between.">
						<cfcontinue>
					</cfif>
					<cfset filter.low = trim(left(filter.value, dash - 1))>
					<cfset filter.high = trim(mid(filter.value, dash + 1, len(filter.value)))>
				</cfif>
				<cfset arrayAppend(result.filters, filter)>
			</cfif>
		</cfif>
	</cfloop>
	<cfreturn result>
</cffunction>
