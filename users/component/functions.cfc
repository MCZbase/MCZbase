<!---
users/component/functions.cfc

Copyright 2022 President and Fellows of Harvard College

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

<!--- saveSearch save searches 
 @param search_name the user provided name for the search
 @param execute whether to execute the search immediately on page load, or only display the populated search form
 @param url the path, page name, and parameters of the search to run.
 @return json containing status=saved and name=html encoded search_name.
--->
<cffunction name="saveSearch" access="remote" returntype="any" returnformat="json">
	<cfargument name="search_name" type="string" required="yes">
	<cfargument name="execute" type="string" required="yes">
	<cfargument name="url" type="string" required="yes">
	<cfif execute EQ "true"><cfset execute="1"></cfif>
	<cfif execute EQ "false"><cfset execute="0"></cfif>

	<cfset data = ArrayNew(1)>
	<cftry>
		<cftransaction>
			<cfquery name="getUserID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT user_id 
				FROM cf_users
				WHERE
					username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="upIns" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				INSERT INTO cf_canned_search
				(
					search_name,
					url,
					execute,
					user_id
				)
				VALUES
				(
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#search_name#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#url#">,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#execute#">,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getUserID.user_id#">
				)
			</cfquery>
		</cftransaction>
		<cfset row = StructNew()>
		<cfset row["status"] = "saved">
		<cfset row["name"] = "#encodeForHTML(search_name)#">
		<cfset data[1] = row>
		<cfcatch>
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfif error_message CONTAINS "ORA-00001: unique constraint">
				<cfset error_message = "Unable to save search, the search name and the search must each be unique.  You have already saved either a search with the same name, or a search with the same URI.  See the list of saved searches in your user profile.">
			</cfif>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
	</cftry>
	<cfreturn #serializeJSON(data)#>
</cffunction>

</cfcomponent>
