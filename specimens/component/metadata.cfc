<!---
specimens/component/metadata.cfc

admin listing and metadata viewer functions
for cf_spec_search_cols and cf_spec_res_cols_r

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

<!--- search for rows in the cf_spec_res_cols_r table for management of the metadata
  concerning search results grids for specimen search.
  @param category search term to find rows by category
  @param hidden search term to find rows by hidden property
  @param column_name search term to find rows by column name
  @param label  search term to find rows by label
  @return json suitable for populating a jqx grid 
--->
<cffunction name="getcf_spec_res_cols" access="remote" returntype="any" returnformat="json">
	<cfargument name="category" type="string" required="no">
	<cfargument name="hidden" type="string" required="no">
	<cfargument name="column_name" type="string" required="no">
	<cfargument name="label" type="string" required="no">
	<cfargument name="sql_element" type="string" required="no">
	<cfargument name="access_role" type="string" required="no">

	<cftry>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			SELECT COLUMN_NAME, SQL_ELEMENT, CATEGORY, CF_SPEC_RES_COLS_ID, DISP_ORDER,
				LABEL, ACCESS_ROLE, HIDEABLE, HIDDEN, CELLSRENDERER, WIDTH, DATA_TYPE
			FROM cf_spec_res_cols_r
			WHERE 
				CF_SPEC_RES_COLS_ID is not null
				<cfif isdefined("category") AND len(category) GT 0>
					<cfif left(category,1) is "=">
						AND upper(category) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(category,len(category)-1))#">
					<cfelseif left(category,1) is "~">
						AND utl_match.jaro_winkler(category, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(category,len(category)-1)#">) >= 0.90
					<cfelseif left(category,1) is "!~">
						AND utl_match.jaro_winkler(category, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(category,len(category)-1)#">) < 0.90
					<cfelseif left(category,1) is "!">
						AND upper(category) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(category,len(category)-1))#">
					<cfelse>
						<cfif find(',',category) GT 0>
							AND upper(category) in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(category)#" list="yes"> )
						<cfelse>
							AND upper(category) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(category)#%">
						</cfif>
					</cfif>
				</cfif>
				<cfif isdefined("hidden") AND len(hidden) GT 0>
					<cfif left(hidden,1) is "=">
						AND upper(hidden) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(hidden,len(hidden)-1))#">
					<cfelseif left(hidden,1) is "~">
						AND utl_match.jaro_winkler(hidden, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(hidden,len(hidden)-1)#">) >= 0.90
					<cfelseif left(hidden,1) is "!~">
						AND utl_match.jaro_winkler(hidden, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(hidden,len(hidden)-1)#">) < 0.90
					<cfelseif left(hidden,1) is "!">
						AND upper(hidden) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(hidden,len(hidden)-1))#">
					<cfelse>
						<cfif find(',',hidden) GT 0>
							AND upper(hidden) in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(hidden)#" list="yes"> )
						<cfelse>
							AND upper(hidden) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(hidden)#%">
						</cfif>
					</cfif>
				</cfif>
				<cfif isdefined("column_name") AND len(column_name) GT 0>
					<cfif left(column_name,1) is "=">
						AND upper(column_name) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(column_name,len(column_name)-1))#">
					<cfelseif left(column_name,1) is "~">
						AND utl_match.jaro_winkler(column_name, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(column_name,len(column_name)-1)#">) >= 0.90
					<cfelseif left(column_name,1) is "!~">
						AND utl_match.jaro_winkler(column_name, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(column_name,len(column_name)-1)#">) < 0.90
					<cfelseif left(column_name,1) is "!">
						AND upper(column_name) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(column_name,len(column_name)-1))#">
					<cfelse>
						<cfif find(',',column_name) GT 0>
							AND upper(column_name) in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(column_name)#" list="yes"> )
						<cfelse>
							AND upper(column_name) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(column_name)#%">
						</cfif>
					</cfif>
				</cfif>
				<cfif isdefined("label") AND len(label) GT 0>
					<cfif left(label,1) is "=">
						AND upper(label) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(label,len(label)-1))#">
					<cfelseif left(label,1) is "~">
						AND utl_match.jaro_winkler(label, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(label,len(label)-1)#">) >= 0.90
					<cfelseif left(label,1) is "!~">
						AND utl_match.jaro_winkler(label, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(label,len(label)-1)#">) < 0.90
					<cfelseif left(label,1) is "!">
						AND upper(label) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(label,len(label)-1))#">
					<cfelse>
						<cfif find(',',label) GT 0>
							AND upper(label) in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(label)#" list="yes"> )
						<cfelse>
							AND upper(label) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(label)#%">
						</cfif>
					</cfif>
				</cfif>
				<cfif isdefined("sql_element") AND len(sql_element) GT 0>
					<cfif left(sql_element,1) is "=">
						AND upper(sql_element) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(sql_element,len(sql_element)-1))#">
					<cfelseif left(sql_element,1) is "~">
						AND utl_match.jaro_winkler(sql_element, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(sql_element,len(sql_element)-1)#">) >= 0.90
					<cfelseif left(sql_element,1) is "!~">
						AND utl_match.jaro_winkler(sql_element, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(sql_element,len(sql_element)-1)#">) < 0.90
					<cfelseif left(sql_element,1) is "!">
						AND upper(sql_element) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(sql_element,len(sql_element)-1))#">
					<cfelse>
						<cfif find(',',sql_element) GT 0>
							AND upper(sql_element) in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(sql_element)#" list="yes"> )
						<cfelse>
							AND upper(sql_element) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(sql_element)#%">
						</cfif>
					</cfif>
				</cfif>
				<cfif isdefined("access_role") AND len(access_role) GT 0>
					<cfif left(access_role,1) is "=">
						AND upper(access_role) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(access_role,len(access_role)-1))#">
					<cfelseif left(access_role,1) is "~">
						AND utl_match.jaro_winkler(access_role, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(access_role,len(access_role)-1)#">) >= 0.90
					<cfelseif left(access_role,1) is "!~">
						AND utl_match.jaro_winkler(access_role, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(access_role,len(access_role)-1)#">) < 0.90
					<cfelseif left(access_role,1) is "!">
						AND upper(access_role) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(access_role,len(access_role)-1))#">
					<cfelse>
						<cfif find(',',access_role) GT 0>
							AND upper(access_role) in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(access_role)#" list="yes"> )
						<cfelse>
							AND upper(access_role) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(access_role)#%">
						</cfif>
					</cfif>
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

<!--- search for rows in the cf_spec_search_cols table for management of the metadata
  concerning searching specimen search, supports both the search builder field picklist
  and the backing build_query_dbms_sql stored procedure.
  @param search_category search term to find rows by category
  @param table_name search term to find rows by table name
  @param column_name search term to find rows by column name
  @param label  search term to find rows by label
  @return json suitable for populating a jqx grid 
--->
<cffunction name="getcf_spec_search_cols" access="remote" returntype="any" returnformat="json">
	<cfargument name="search_category" type="string" required="no">
	<cfargument name="table_name" type="string" required="no">
	<cfargument name="column_name" type="string" required="no">
	<cfargument name="label" type="string" required="no">
	<cfargument name="access_role" type="string" required="no">
	<cfargument name="ui_function" type="string" required="no">

	<cftry>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			SELECT ID, TABLE_NAME, TABLE_ALIAS, COLUMN_NAME, COLUMN_ALIAS, SEARCH_CATEGORY,
				DATA_TYPE, DATA_LENGTH, LABEL, ACCESS_ROLE, UI_FUNCTION,
				EXAMPLE_VALUES, DESCRIPTION,
				all_col_comments.comments definition
			FROM cf_spec_search_cols
            left join all_col_comments
            	on cf_spec_search_cols.table_name = all_col_comments.table_name
            		and cf_spec_search_cols.column_name = all_col_comments.column_name
            		and all_col_comments.owner = 'MCZBASE'
			WHERE 
				ID is not null
				<cfif isdefined("search_category") AND len(search_category) GT 0>
					<cfif left(search_category,1) is "=">
						AND upper(search_category) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(search_category,len(search_category)-1))#">
					<cfelseif left(search_category,1) is "~">
						AND utl_match.jaro_winkler(search_category, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(search_category,len(search_category)-1)#">) >= 0.90
					<cfelseif left(search_category,1) is "!~">
						AND utl_match.jaro_winkler(search_category, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(search_category,len(search_category)-1)#">) < 0.90
					<cfelseif left(search_category,1) is "!">
						AND upper(search_category) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(search_category,len(search_category)-1))#">
					<cfelse>
						<cfif find(',',search_category) GT 0>
							AND upper(search_category) in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(search_category)#" list="yes"> )
						<cfelse>
							AND upper(search_category) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(search_category)#%">
						</cfif>
					</cfif>
				</cfif>
				<cfif isdefined("table_name") AND len(table_name) GT 0>
					<cfif left(table_name,1) is "=">
						AND upper(table_name) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(table_name,len(table_name)-1))#">
					<cfelseif left(table_name,1) is "~">
						AND utl_match.jaro_winkler(table_name, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(table_name,len(table_name)-1)#">) >= 0.90
					<cfelseif left(table_name,1) is "!~">
						AND utl_match.jaro_winkler(table_name, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(table_name,len(table_name)-1)#">) < 0.90
					<cfelseif left(table_name,1) is "!">
						AND upper(table_name) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(table_name,len(table_name)-1))#">
					<cfelse>
						<cfif find(',',table_name) GT 0>
							AND upper(table_name) in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(table_name)#" list="yes"> )
						<cfelse>
							AND upper(table_name) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(table_name)#%">
						</cfif>
					</cfif>
				</cfif>
				<cfif isdefined("column_name") AND len(column_name) GT 0>
					<cfif left(column_name,1) is "=">
						AND upper(column_name) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(column_name,len(column_name)-1))#">
					<cfelseif left(column_name,1) is "~">
						AND utl_match.jaro_winkler(column_name, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(column_name,len(column_name)-1)#">) >= 0.90
					<cfelseif left(column_name,1) is "!~">
						AND utl_match.jaro_winkler(column_name, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(column_name,len(column_name)-1)#">) < 0.90
					<cfelseif left(column_name,1) is "!">
						AND upper(column_name) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(column_name,len(column_name)-1))#">
					<cfelse>
						<cfif find(',',column_name) GT 0>
							AND upper(column_name) in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(column_name)#" list="yes"> )
						<cfelse>
							AND upper(column_name) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(column_name)#%">
						</cfif>
					</cfif>
				</cfif>
				<cfif isdefined("label") AND len(label) GT 0>
					<cfif left(label,1) is "=">
						AND upper(label) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(label,len(label)-1))#">
					<cfelseif left(label,1) is "~">
						AND utl_match.jaro_winkler(label, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(label,len(label)-1)#">) >= 0.90
					<cfelseif left(label,1) is "!~">
						AND utl_match.jaro_winkler(label, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(label,len(label)-1)#">) < 0.90
					<cfelseif left(label,1) is "!">
						AND upper(label) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(label,len(label)-1))#">
					<cfelse>
						<cfif find(',',label) GT 0>
							AND upper(label) in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(label)#" list="yes"> )
						<cfelse>
							AND upper(label) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(label)#%">
						</cfif>
					</cfif>
				</cfif>
				<cfif isdefined("access_role") AND len(access_role) GT 0>
					<cfif left(access_role,1) is "=">
						AND upper(access_role) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(access_role,len(access_role)-1))#">
					<cfelseif left(access_role,1) is "~">
						AND utl_match.jaro_winkler(access_role, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(access_role,len(access_role)-1)#">) >= 0.90
					<cfelseif left(access_role,1) is "!~">
						AND utl_match.jaro_winkler(access_role, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(access_role,len(access_role)-1)#">) < 0.90
					<cfelseif left(access_role,1) is "!">
						AND upper(access_role) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(access_role,len(access_role)-1))#">
					<cfelse>
						<cfif find(',',access_role) GT 0>
							AND upper(access_role) in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(access_role)#" list="yes"> )
						<cfelse>
							AND upper(access_role) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(access_role)#%">
						</cfif>
					</cfif>
				</cfif>
				<cfif isdefined("ui_function") AND len(ui_function) GT 0>
					<cfif left(ui_function,1) is "=">
						AND upper(ui_function) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(ui_function,len(ui_function)-1))#">
					<cfelseif ui_function IS "NULL">
						AND ui_function IS NULL
					<cfelseif ui_function IS "NOT NULL">
						AND ui_function IS NOT NULL
					<cfelseif left(ui_function,1) is "~">
						AND utl_match.jaro_winkler(ui_function, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(ui_function,len(ui_function)-1)#">) >= 0.90
					<cfelseif left(ui_function,1) is "!~">
						AND utl_match.jaro_winkler(ui_function, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(ui_function,len(ui_function)-1)#">) < 0.90
					<cfelseif left(ui_function,1) is "!">
						AND upper(ui_function) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(ui_function,len(ui_function)-1))#">
					<cfelse>
						<cfif find(',',ui_function) GT 0>
							AND upper(ui_function) in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(ui_function)#" list="yes"> )
						<cfelse>
							AND upper(ui_function) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(ui_function)#%">
						</cfif>
					</cfif>
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
