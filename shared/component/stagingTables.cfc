<!---
shared/component/stagingTables.cfc
Functions for bulkloaders that read a CSV file into a staging table.

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
<!--- A CSV file's header row names the columns its values are inserted into, and a column name cannot
	be bound, so only headers that are exactly columns of the staging table are written into an
	insert; the values under any other header are ignored.  No method is remote. --->
<cfcomponent>

<!---
	stagingTableColumns the columns of an MCZBASE staging table, from the data dictionary.

	@param tableName the table name.
	@return a structure with each column name, in upper case, as a key.
--->
<cffunction name="stagingTableColumns" access="public" returntype="struct" output="false">
	<cfargument name="tableName" type="string" required="yes">

	<cfset var columns = structNew()>
	<cfset var getStagingColumns = "">

	<cfquery name="getStagingColumns" datasource="uam_god">
		SELECT column_name
		FROM all_tab_columns
		WHERE
			owner = 'MCZBASE'
			AND table_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(arguments.tableName)#">
	</cfquery>
	<cfloop query="getStagingColumns">
		<cfset columns[ucase(getStagingColumns.column_name)] = true>
	</cfloop>
	<cfreturn columns>
</cffunction>

<!---
	usableHeaders match a CSV header row to a staging table's columns.  Headers that are not exactly a
	column of the table, that name a column the bulkloader sets itself, or that repeat an earlier
	header are left out, so their values are ignored, and are listed so the user can be told.

	@param headers an array of the header row's values.
	@param tableName the staging table.
	@param reservedColumns a comma separated list of columns the bulkloader sets itself.
	@return a structure of columns, an array of structures of name (the column, in upper case) and
		position (of its values in each row); and ignored, an array of the headers left out, each
		with the reason.
--->
<cffunction name="usableHeaders" access="public" returntype="struct" output="false">
	<cfargument name="headers" type="array" required="yes">
	<cfargument name="tableName" type="string" required="yes">
	<cfargument name="reservedColumns" type="string" required="no" default="">

	<cfset var tableColumns = stagingTableColumns(arguments.tableName)>
	<cfset var result = { columns = [], ignored = [] }>
	<cfset var seen = structNew()>
	<cfset var header = "">
	<cfset var i = 0>

	<cfloop from="1" to="#arrayLen(arguments.headers)#" index="i">
		<cfset header = ucase(trim(arguments.headers[i]))>
		<cfif len(header) EQ 0>
			<cfset arrayAppend(result.ignored, "Column #i# has no header.")>
		<cfelseif NOT structKeyExists(tableColumns, header)>
			<cfset arrayAppend(result.ignored, "#header# is not a column of #ucase(arguments.tableName)#.")>
		<cfelseif listFindNoCase(arguments.reservedColumns, header) GT 0>
			<cfset arrayAppend(result.ignored, "#header# is set by the bulkloader.")>
		<cfelseif structKeyExists(seen, header)>
			<cfset arrayAppend(result.ignored, "#header# appears again in column #i#; the first is used.")>
		<cfelse>
			<cfset seen[header] = true>
			<cfset arrayAppend(result.columns, { name = header, position = i })>
		</cfif>
	</cfloop>
	<cfreturn result>
</cffunction>

<!---
	columnNameList the names of the usable columns, for an insert's column list.

	@param columns the columns array from usableHeaders.
	@return a comma separated list of the column names.
--->
<cffunction name="columnNameList" access="public" returntype="string" output="false">
	<cfargument name="columns" type="array" required="yes">

	<cfset var names = "">
	<cfset var column = "">
	<cfloop array="#arguments.columns#" index="column">
		<cfset names = listAppend(names, column.name)>
	</cfloop>
	<cfreturn names>
</cffunction>

<!---
	cellValue a row's value for a column, or an empty string where the row is short.

	@param row an array of the row's values.
	@param position the column's position in the row.
	@return the value.
--->
<cffunction name="cellValue" access="public" returntype="string" output="false">
	<cfargument name="row" type="array" required="yes">
	<cfargument name="position" type="numeric" required="yes">

	<cfif arguments.position LTE arrayLen(arguments.row)>
		<cfreturn arguments.row[arguments.position]>
	</cfif>
	<cfreturn "">
</cffunction>

<!---
	isBlankRow test whether a parsed CSV row has no values, as for a trailing line break.

	@param row an array of the row's values.
	@return true if every value is empty.
--->
<cffunction name="isBlankRow" access="public" returntype="boolean" output="false">
	<cfargument name="row" type="array" required="yes">

	<cfset var cell = "">
	<cfloop array="#arguments.row#" index="cell">
		<cfif len(trim(cell)) GT 0>
			<cfreturn false>
		</cfif>
	</cfloop>
	<cfreturn true>
</cffunction>

</cfcomponent>
