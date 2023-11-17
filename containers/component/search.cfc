<!---
containers/component/search.cfc

Copyright 2023 President and Fellows of Harvard College

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
<cf_rolecheck><!--- restricted role access --->
<cfinclude template="/shared/component/error_handler.cfc" runOnce="true">

<!---
Function getContainerAutocomplete.  Search for agents by name with a substring match on label or barcode, returning json suitable for jquery-ui autocomplete.

@param term container label or barcode to search for.
@return a json structure containing id and value, with matching container with matched type, label, and barcode in value and container_id in id.
--->
<cffunction name="getContainerAutocomplete" access="remote" returntype="any" returnformat="json">
	<cfargument name="term" type="string" required="yes">
	<!--- perform wildcard search anywhere in agent_name.agent_name --->
	<cfset name = "%#term#%"> 

	<cfset data = ArrayNew(1)>
	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result" timeout="#Application.query_timeout#">
			SELECT 
				container_id, label, barcode, container_type
			FROM 
				container
			WHERE
				upper(label) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(name)#">
				OR
				upper(barcode) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(name)#">
		</cfquery>
	<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfset row["id"] = "#search.container_id#" >
			<cfset row["value"] = "#search.container_type#: #search.label# (#search.barcode#)" >
			<cfset data[i]  = row>
			<cfset i = i + 1>
		</cfloop>
		<cfreturn #serializeJSON(data)#>
	<cfcatch>
		<cfset error_message = cfcatchToErrorMessage(cfcatch)>
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn #serializeJSON(data)#>
</cffunction>

<!---
Function getContainerAutocompleteMeta.  Search for agents by name with a substring match on label or barcode, returning json suitable for jquery-ui autocomplete.

@param term container label or barcode to search for.
@return a json structure containing id and value, with matching container with matched barcode in value and  type, label, and barcode in meta and container_id in id.
--->
<cffunction name="getContainerAutocompleteMeta" access="remote" returntype="any" returnformat="json">
	<cfargument name="term" type="string" required="yes">
	<!--- perform wildcard search anywhere in agent_name.agent_name --->
	<cfset name = "%#term#%"> 

	<cfset data = ArrayNew(1)>
	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result" timeout="#Application.query_timeout#">
			SELECT 
				container_id, label, barcode, container_type
			FROM 
				container
			WHERE
				upper(label) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(name)#">
				OR
				upper(barcode) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(name)#">
		</cfquery>
	<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfset row["id"] = "#search.container_id#" >
			<cfset row["meta"] = "#search.container_type#: #search.label# (#search.barcode#)" >
			<cfset row["value"] = "#search.barcode#" >
			<cfset data[i]  = row>
			<cfset i = i + 1>
		</cfloop>
		<cfreturn #serializeJSON(data)#>
	<cfcatch>
		<cfset error_message = cfcatchToErrorMessage(cfcatch)>
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn #serializeJSON(data)#>
</cffunction>

</cfcomponent>
