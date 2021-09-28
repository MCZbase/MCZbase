<!---
specimens/component/admin.cfc

admin for cf_spec_search_cols and cf_spec_res_cols_r

Copyright 2019 President and Fellows of Harvard College

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
<cfcomponent>
<cf_rolecheck>
<cfinclude template="/shared/component/error_handler.cfc" runOnce="true">

<cffunction name="getcf_spec_res_cols" access="remote" returntype="any" returnformat="json">
	<cfargument name="category" type="string" required="no">
	<cfargument name="hidden" type="string" required="no">
	<cfargument name="column_name" type="string" required="no">
	<cfargument name="label" type="string" required="no">

	<cftry>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			SELECT COLUMN_NAME, SQL_ELEMENT, CATEGORY, CF_SPEC_RES_COLS_ID, DISP_ORDER,
				LABEL, ACCESS_ROLE, HIDEABLE, HIDDEN, CELLSRENDERER, WIDTH, DATA_TYPE 
			FROM cf_spec_res_cols_r
			WHERE 
				CF_SPEC_RES_COLS_ID is not null
				<cfif isdefined("category") AND len(category) GT 0>
					AND category = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#category#">
				</cfif>
				<cfif isdefined("hidden") AND len(hidden) GT 0>
					AND hidden = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#hidden#">
				</cfif>
				<cfif isdefined("column_name") AND len(column_name) GT 0>
					AND column_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#column_name#">
				</cfif>
				<cfif isdefined("label") AND len(label) GT 0>
					AND label = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#label#">
				</cfif>
			ORDER BY CATEGORY, COLUMN_NAME
		</cfquery>

		<cfset rows = 0>
		<cfset data = ArrayNew(1)>

		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfloop list="#ArrayToList(search.getColumnNames())#" index="col" >
				<cfset row["#ucase(col)#"] = replace(search[col][currentRow],'""','&quot;','all')>
			</cfloop>
			<cfset data[i]  = row>
			<cfset i = i + 1>
		</cfloop>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn #serializeJSON(data)#>
</cffunction>

<cffunction name="getcf_spec_search_cols" access="remote" returntype="any" returnformat="json">
	<cfargument name="search_category" type="string" required="no">
	<cfargument name="table_name" type="string" required="no">
	<cfargument name="column_name" type="string" required="no">
	<cfargument name="label" type="string" required="no">

	<cftry>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			SELECT ID, TABLE_NAME, TABLE_ALIAS, COLUMN_NAME, COLUMN_ALIAS, SEARCH_CATEGORY,
				 DATA_TYPE, DATA_LENGTH, LABEL  
			FROM cf_spec_search_cols
			WHERE 
				ID is not null
				<cfif isdefined("search_category") AND len(search_category) GT 0>
					AND search_category = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#search_category#">
				</cfif>
				<cfif isdefined("table_name") AND len(table_name) GT 0>
					AND table_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#table_name#">
				</cfif>
				<cfif isdefined("column_name") AND len(column_name) GT 0>
					AND column_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#column_name#">
				</cfif>
				<cfif isdefined("label") AND len(label) GT 0>
					AND label = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#label#">
				</cfif>
			ORDER BY SEARCH_CATEGORY, COLUMN_NAME
		</cfquery>

		<cfset rows = 0>
		<cfset data = ArrayNew(1)>

		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfloop list="#ArrayToList(search.getColumnNames())#" index="col" >
				<cfset row["#ucase(col)#"] = replace(search[col][currentRow],'""','&quot;','all')>
			</cfloop>
			<cfset data[i]  = row>
			<cfset i = i + 1>
		</cfloop>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn #serializeJSON(data)#>
</cffunction>

</cfcomponent>
