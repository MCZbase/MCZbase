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


<!--- backing method for row insert in cf_spec_search_cols grid 
--->
<cffunction name="addCFSpecSearchColsRow" access="remote" returntype="any" returnformat="json">
	<cfargument name="TABLE_NAME" type="string" required="yes">
	<cfargument name="TABLE_ALIAS" type="string" required="yes">
	<cfargument name="COLUMN_NAME" type="string" required="yes">
	<cfargument name="COLUMN_ALIAS" type="string" required="yes">
	<cfargument name="SEARCH_CATEGORY" type="string" required="yes">
	<cfargument name="DATA_TYPE" type="string" required="yes">
	<cfargument name="DATA_LENGTH" type="string" required="yes">
	<cfargument name="LABEL" type="string" required="yes">
	<cfargument name="DESCRIPTION" type="string" required="yes">

	<cftransaction>
		<cftry>
			<cfif NOT isdefined("session.roles") OR NOT listfindnocase(session.roles,"GLOBAL_ADMIN")>
				<cfthrow message="Insufficient Access Rights">
			</cfif>
				<cfquery name="doUpdate" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="doUpdate_result">
					INSERT INTO cf_spec_search_cols (
						TABLE_NAME,
						TABLE_ALIAS,
						COLUMN_NAME,
						COLUMN_ALIAS,
						SEARCH_CATEGORY,
						DATA_TYPE,
						DATA_LENGTH,
						LABEL,
						ACCESS_ROLE,
						UI_FUNCTION,
						DESCRIPTION
					) VALUES (
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#TABLE_NAME#">, 
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#TABLE_ALIAS#">, 
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#COLUMN_NAME#">, 
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#COLUMN_ALIAS#">, 
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#SEARCH_CATEGORY#">,
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#DATA_TYPE#">, 
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#DATA_LENGTH#">, 
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#LABEL#">,
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ACCESS_ROLE#">,  
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#UI_FUNCTION#">,
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#DESCRIPTION#">  
					)
				</cfquery>
			<cfif doUpdate_result.recordcount NEQ 1>
				<cfthrow message="Record not updated. #ID# #doUpdate_result.sql#">
			</cfif>
			<cfif doUpdate_result.recordcount eq 1>
				<cfset theResult=queryNew("status, message")>
				<cfset t = queryaddrow(theResult,1)>
				<cfset t = QuerySetCell(theResult, "status", "1", 1)>
				<cfset t = QuerySetCell(theResult, "message", "cf_spec_search_cols row added.", 1)>
			</cfif>
			<cftransaction action="commit">
		<cfcatch>
			<cftransaction action="rollback">
			<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
			<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn theResult>
</cffunction>

<!--- backing method for row update in cf_spec_search_cols grid 
	@param ID the id of the row to update
--->
<cffunction name="updatecf_spec_search_cols" access="remote" returntype="any" returnformat="json">
	<cfargument name="ID" type="string" required="yes">
	<cfargument name="TABLE_NAME" type="string" required="yes">
	<cfargument name="TABLE_ALIAS" type="string" required="yes">
	<cfargument name="COLUMN_NAME" type="string" required="yes">
	<cfargument name="COLUMN_ALIAS" type="string" required="yes">
	<cfargument name="SEARCH_CATEGORY" type="string" required="yes">
	<cfargument name="DATA_TYPE" type="string" required="yes">
	<cfargument name="DATA_LENGTH" type="string" required="yes">
	<cfargument name="LABEL" type="string" required="yes">
	<cfargument name="ACCESS_ROLE" type="string" required="yes">
	<cfargument name="UI_FUNCTION" type="string" required="yes">
	<cfargument name="EXAMPLE_VALUES" type="string" required="yes">
	<cfargument name="DESCRIPTION" type="string" required="yes">

	<cftransaction>
		<cftry>
			<cfif NOT isdefined("session.roles") OR NOT listfindnocase(session.roles,"GLOBAL_ADMIN")>
				<cfthrow message="Insufficient Access Rights">
			</cfif>
			<cfif len(ID) EQ 0>
				<cfthrow message="No value provided for primary key for row to update.">
			</cfif>
			<cfquery name="doUpdate" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="doUpdate_result">
				UPDATE cf_spec_search_cols
				SET			
					TABLE_NAME = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#TABLE_NAME#">, 
					TABLE_ALIAS = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#TABLE_ALIAS#">, 
					COLUMN_NAME = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#COLUMN_NAME#">, 
					COLUMN_ALIAS = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#COLUMN_ALIAS#">, 
					SEARCH_CATEGORY = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#SEARCH_CATEGORY#">,
					DATA_TYPE = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#DATA_TYPE#">, 
					DATA_LENGTH = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#DATA_LENGTH#">, 
					LABEL = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#LABEL#">,
					ACCESS_ROLE = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ACCESS_ROLE#">,
					UI_FUNCTION = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#UI_FUNCTION#">,
					EXAMPLE_VALUES = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#EXAMPLE_VALUES#">,
					DESCRIPTION = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#DESCRIPTION#">
				WHERE
					ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#ID#">
			</cfquery>
			<cfif doUpdate_result.recordcount NEQ 1>
				<cfthrow message="Record not updated. #ID# #doUpdate_result.sql#">
			</cfif>
			<cfif doUpdate_result.recordcount eq 1>
				<cfset theResult=queryNew("status, message")>
				<cfset t = queryaddrow(theResult,1)>
				<cfset t = QuerySetCell(theResult, "status", "1", 1)>
				<cfset t = QuerySetCell(theResult, "message", "cf_spec_search_cols row updated.", 1)>
			</cfif>
			<cftransaction action="commit">
		<cfcatch>
			<cftransaction action="rollback">
			<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
			<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn theResult>
</cffunction>

<!--- backing method for row insert in cf_spec_res_cols_r from grid 
--->
<cffunction name="addcf_spec_res_cols" access="remote" returntype="any" returnformat="json">
	<cfargument name="SQL_ELEMENT" type="string" required="yes">
	<cfargument name="CATEGORY" type="string" required="yes">
	<cfargument name="COLUMN_NAME" type="string" required="yes">
	<cfargument name="DISP_ORDER" type="string" required="yes">
	<cfargument name="ACCESS_ROLE" type="string" required="yes">
	<cfargument name="HIDEABLE" type="string" required="yes">
	<cfargument name="HIDDEN" type="string" required="yes">
	<cfargument name="CELLSRENDERER" type="string" required="yes">
	<cfargument name="WIDTH" type="string" required="yes">
	<cfargument name="DATA_TYPE" type="string" required="yes">
	<cfargument name="LABEL" type="string" required="yes">

	<cftransaction>
		<cftry>
			<cfif NOT isdefined("session.roles") OR NOT listfindnocase(session.roles,"GLOBAL_ADMIN")>
				<cfthrow message="Insufficient Access Rights">
			</cfif>
			<cfquery name="doUpdate" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="doUpdate_result">
				INSERT INTO cf_spec_res_cols_r (
					COLUMN_NAME,
					SQL_ELEMENT,
					CATEGORY,
					DISP_ORDER,
					ACCESS_ROLE,
					HIDEABLE,
					HIDDEN,
					CELLSRENDERER,
					WIDTH,
					DATA_TYPE, 
					LABEL
				) VALUES (
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#COLUMN_NAME#">, 
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#SQL_ELEMENT#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#CATEGORY#">, 
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#DISP_ORDER#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ACCESS_ROLE#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#HIDEABLE#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#HIDDEN#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#CELLSRENDERER#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#WIDTH#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#DATA_TYPE#">, 
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#LABEL#">
				)
			</cfquery>
			<cfif doUpdate_result.recordcount NEQ 1>
				<cfthrow message="Record not inserted. #doUpdate_result.sql#">
			</cfif>
			<cfif doUpdate_result.recordcount eq 1>
				<cfset theResult=queryNew("status, message")>
				<cfset t = queryaddrow(theResult,1)>
				<cfset t = QuerySetCell(theResult, "status", "1", 1)>
				<cfset t = QuerySetCell(theResult, "message", "cf_spec_res_cols_r row inserted.", 1)>
			</cfif>
			<cftransaction action="commit">
		<cfcatch>
			<cftransaction action="rollback">
			<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
			<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn theResult>
</cffunction>

<!--- backing method for row update in cf_spec_res_cols_r grid 
	@param CF_SPEC_RES_COLS_ID the primary key of the row to update
--->
<cffunction name="updatecf_spec_res_cols" access="remote" returntype="any" returnformat="json">
	<cfargument name="CF_SPEC_RES_COLS_ID" type="string" required="yes">
	<cfargument name="SQL_ELEMENT" type="string" required="yes">
	<cfargument name="CATEGORY" type="string" required="yes">
	<cfargument name="COLUMN_NAME" type="string" required="yes">
	<cfargument name="DISP_ORDER" type="string" required="yes">
	<cfargument name="ACCESS_ROLE" type="string" required="yes">
	<cfargument name="HIDEABLE" type="string" required="yes">
	<cfargument name="HIDDEN" type="string" required="yes">
	<cfargument name="CELLSRENDERER" type="string" required="yes">
	<cfargument name="WIDTH" type="string" required="yes">
	<cfargument name="DATA_TYPE" type="string" required="yes">
	<cfargument name="LABEL" type="string" required="yes">

	<cftransaction>
		<cftry>
			<cfif NOT isdefined("session.roles") OR NOT listfindnocase(session.roles,"GLOBAL_ADMIN")>
				<cfthrow message="Insufficient Access Rights">
			</cfif>
			<cfif len(CF_SPEC_RES_COLS_ID) EQ 0>
				<cfthrow message="Primary key for row to update not provided">
			</cfif>
			<cfquery name="doUpdate" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="doUpdate_result">
				UPDATE cf_spec_res_cols_r
				SET			
					COLUMN_NAME = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#COLUMN_NAME#">, 
					SQL_ELEMENT = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#SQL_ELEMENT#">,
					CATEGORY = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#CATEGORY#">, 
					DISP_ORDER = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#DISP_ORDER#">,
					ACCESS_ROLE = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ACCESS_ROLE#">,
					HIDEABLE = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#HIDEABLE#">,
					HIDDEN = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#HIDDEN#">,
					CELLSRENDERER = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#CELLSRENDERER#">,
					WIDTH = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#WIDTH#">,
					DATA_TYPE = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#DATA_TYPE#">, 
					LABEL = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#LABEL#">
				WHERE
					CF_SPEC_RES_COLS_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#CF_SPEC_RES_COLS_ID#">
			</cfquery>
			<cfif doUpdate_result.recordcount NEQ 1>
				<cfthrow message="Record not updated. #CF_SPEC_RES_COLS_ID# #doUpdate_result.sql#">
			</cfif>
			<cfif doUpdate_result.recordcount eq 1>
				<cfset theResult=queryNew("status, message")>
				<cfset t = queryaddrow(theResult,1)>
				<cfset t = QuerySetCell(theResult, "status", "1", 1)>
				<cfset t = QuerySetCell(theResult, "message", "cf_spec_res_cols_r row updated.", 1)>
			</cfif>
			<cftransaction action="commit">
		<cfcatch>
			<cftransaction action="rollback">
			<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
			<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn theResult>
</cffunction>

<!--- Remove a row from cf_spec_search_cols.
 @param ID the primary key value of the row to be deleted.
--->
<cffunction name="deleteCFSpecSearchColsRow" access="remote" returntype="any" returnformat="json">
	<cfargument name="ID" type="numeric" required="yes">

	<cftransaction>
		<cftry>
			<cfquery name="delRow" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="delRow_result">
				DELETE from cf_spec_search_cols
				where
					ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#ID#">
			</cfquery>
			<cfif delRow_result.recordcount NEQ 1>
				<cfthrow message = "Record not deleted. #ID# #delRow_result.sql#">
			</cfif>
			<cfif delRow_result.recordcount eq 1>
				<cfset theResult=queryNew("status, message")>
				<cfset t = queryaddrow(theResult,1)>
				<cfset t = QuerySetCell(theResult, "status", "1", 1)>
				<cfset t = QuerySetCell(theResult, "message", "cf_spec_search_cols row deleted.", 1)>
			</cfif>
			<cftransaction action="commit">
		<cfcatch>
			<cftransaction action="rollback">
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cftransaction>

	<cfreturn theResult>
</cffunction>

<!--- Remove a row from cf_spec_res_cols_r. 
 @param ID the primary key value of the row to be deleted.
--->
<cffunction name="deleteCFSpecResColsRow" access="remote" returntype="any" returnformat="json">
	<cfargument name="CF_SPEC_RES_COLS_ID" type="numeric" required="yes">

	<cftransaction>
		<cftry>
			<cfquery name="delRow" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="delRow_result">
				DELETE from cf_spec_res_cols_r
				where
					CF_SPEC_RES_COLS_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#CF_SPEC_RES_COLS_ID#">
			</cfquery>
			<cfif delRow_result.recordcount NEQ 1>
				<cfthrow message = "Record not deleted. #CF_SPEC_RES_COLS_ID# #delRow_result.sql#">
			</cfif>
			<cfif delRow_result.recordcount eq 1>
				<cfset theResult=queryNew("status, message")>
				<cfset t = queryaddrow(theResult,1)>
				<cfset t = QuerySetCell(theResult, "status", "1", 1)>
				<cfset t = QuerySetCell(theResult, "message", "cf_spec_res_cols row deleted.", 1)>
			</cfif>
			<cftransaction action="commit">
		<cfcatch>
			<cftransaction action="rollback">
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cftransaction>

	<cfreturn theResult>
</cffunction>

</cfcomponent>
