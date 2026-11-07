<!---
shared/component/codeTables.cfc
Checks on code table names read from configuration tables.

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
<!--- Tables such as ctattribute_code_tables, ctspec_part_att_att and ctpublication_attribute name the
	code table that controls a value.  A table or column name cannot be bound, so a name read from one
	of them is written into a statement only when it is a plain name of an MCZBASE table (and column)
	in the data dictionary.  No method is remote. --->
<cfcomponent>

<!---
	isCodeTable test whether a name is a plain table name of an MCZBASE table.

	@param tableName the table name.
	@param columnName optionally, a column the table must have.
	@return true if the name, and the column if given, can be written into a statement.
--->
<cffunction name="isCodeTable" access="public" returntype="boolean" output="false">
	<cfargument name="tableName" type="string" required="yes">
	<cfargument name="columnName" type="string" required="no" default="">

	<cfset var findCodeTable = "">

	<cfif REFind("^[A-Za-z][A-Za-z0-9_]*$", arguments.tableName) EQ 0>
		<cfreturn false>
	</cfif>
	<cfif len(arguments.columnName) GT 0 AND REFind("^[A-Za-z][A-Za-z0-9_]*$", arguments.columnName) EQ 0>
		<cfreturn false>
	</cfif>
	<cfquery name="findCodeTable" datasource="uam_god" cachedwithin="#createTimeSpan(0,1,0,0)#">
		SELECT count(*) AS found
		FROM all_tab_columns
		WHERE
			owner = 'MCZBASE'
			AND table_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(arguments.tableName)#">
			<cfif len(arguments.columnName) GT 0>
				AND column_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(arguments.columnName)#">
			</cfif>
	</cfquery>
	<cfreturn findCodeTable.found GT 0>
</cffunction>

<!---
	requireCodeTable throw unless a name can be written into a statement as a code table.

	@param tableName the table name.
	@param columnName optionally, a column the table must have.
	@see isCodeTable
--->
<cffunction name="requireCodeTable" access="public" returntype="void" output="false">
	<cfargument name="tableName" type="string" required="yes">
	<cfargument name="columnName" type="string" required="no" default="">

	<cfif NOT isCodeTable(arguments.tableName, arguments.columnName)>
		<cfthrow type="InvalidParameter" message="Configured code table is not a table of MCZbase: #encodeForHtml(arguments.tableName)#">
	</cfif>
</cffunction>

</cfcomponent>
