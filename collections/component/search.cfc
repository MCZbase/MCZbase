<!---
collections/component/search.cfc

Copyright 2021 President and Fellows of Harvard College

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
<cfinclude template="/shared/component/error_handler.cfc" runOnce="true">

<!---
Function getCollectionAutocomplete.  Search for collection by name with a substring match on name, returning json suitable for jquery-ui autocomplete for
 paired collection_id and collection controls.

@param term collection name to search for.
@return a json structure containing id, meta, and value, with matching with matched collection name/collection_id in value and id, and specimen count in meta.
--->
<cffunction name="getCollectionAutocomplete" access="remote" returntype="any" returnformat="json">
	<cfargument name="term" type="string" required="yes">
	<!--- perform wildcard search anywhere in collection.collection --->
	<cfset name = "%#term#%"> 

	<cfset data = ArrayNew(1)>
	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result" cachedwithin="#createtimespan(1,0,0,0)#">
			SELECT 
				count(flat.collection_object_id) as ct,
				collection.collection_id, 
				collection.collection as name
			FROM 
				collection
				LEFT JOIN <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat
					on collection.collection_id = flat.collection_id
			WHERE
				upper(collection.collection) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(name)#">
			GROUP BY
				collection.collection, collection.collection_id
			ORDER BY
				collection.collection
		</cfquery>
	<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfset row["id"] = "#search.collection_id#">
			<cfset row["value"] = "#search.name#" >
			<cfset row["meta"] = "#search.ct# spec." >
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
Function getCollectionCodeAutocomplete.  Search for collection by name with a substring match on collection code or name, returning json suitable for jquery-ui autocomplete for
 a collection code.

@param term collection name or code to search for.
@return a json structure containing value, with matching with matched collection_cde in value.
--->
<cffunction name="getCollectionCdeAutocomplete" access="remote" returntype="any" returnformat="json">
	<cfargument name="term" type="string" required="yes">
	<!--- perform wildcard search anywhere in collection.collection or collection.collection_cde --->
	<cfset name = "%#term#%"> 

	<cfset data = ArrayNew(1)>
	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result" cachedwithin="#createtimespan(1,0,0,0)#">
			SELECT DISTINCT 
				collection.collection_cde
			FROM 
				collection
			WHERE
				upper(collection.collection) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(name)#">
				OR
				upper(collection.collection_cde) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(name)#">
			ORDER BY
				collection.collection_cde
		</cfquery>
	<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfset row["value"] = "#search.collection_cde#" >
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
