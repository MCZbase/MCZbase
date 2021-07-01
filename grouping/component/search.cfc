<!---
grouping/component/search.cfc

Copyright 2020 President and Fellows of Harvard College

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

<!---   Function getCollections  --->
<cffunction name="getCollections" access="remote" returntype="any" returnformat="json">
	<cfargument name="collection_name" type="string" required="no">
	<cfargument name="underscore_agent_id" type="string" required="no">
	<cfargument name="underscore_agent_name" type="string" required="no">
	<cfargument name="description" type="string" required="no">
	<cfargument name="underscore_collection_id" type="string" required="no">
	<cfargument name="guid" type="string" required="no">
	<cfargument name="collection_id" type="string" required="no">

	<cfset data = ArrayNew(1)>
	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			select count(underscore_relation.collection_object_id) as specimen_count, 
				underscore_collection.underscore_collection_id as underscore_collection_id, 
				collection_name,
				description,
				underscore_agent_id, 
				case 
					when underscore_agent_id is null then '[No Agent]'
					else MCZBASE.get_agentnameoftype(underscore_agent_id, 'preferred')
					end
				as agentname
			from underscore_collection
				left join underscore_relation on underscore_collection.underscore_collection_id = underscore_relation.underscore_collection_id
				<cfif (isDefined("guid") and len(guid) gt 0) OR (isDefined("collection_id") AND len(collection_id) GT 0)>
					left join #session.flatTableName# on underscore_relation.collection_object_id = #session.flatTableName#.collection_object_id
				</cfif>
			WHERE
				underscore_collection.underscore_collection_id is not null
				<cfif isDefined("collection_name") and len(collection_name) gt 0>
					and collection_name like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#collection_name#%">
				</cfif>
				<cfif isDefined("description") and len(description) gt 0>
					and upper(description) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(description)#%">
				</cfif>
				<cfif isDefined("underscore_agent_id") and len(underscore_agent_id) gt 0>
					and 
					( underscore_agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_agent_id#">
					<cfif isDefined("underscore_agent_name") and underscore_agent_name EQ "[no agent data]">
					 or underscore_agent_id IS NULL	
					</cfif>
					)
				</cfif>

				<cfif isDefined("collection_id") and len(collection_id) gt 0>
					and #session.flatTableName#.collection_id in (<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_id#" list="yes">)
				</cfif>
				<cfif isDefined("guid") and len(guid) gt 0>
					<cfif find(',',guid) GT 0> 
						and #session.flatTableName#.guid in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#guid#" list="yes">)
					<cfelseif guid EQ "NULL"> 
						and #session.flatTableName#.guid is NULL
					<cfelse>
						and #session.flatTableName#.guid = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#guid#">
					</cfif>
				</cfif>
			group by 
				underscore_collection.underscore_collection_id,
				collection_name,
				description,
				underscore_agent_id, 
				case 
					when underscore_agent_id is null then '[No Agent]'
					else MCZBASE.get_agentnameoftype(underscore_agent_id, 'preferred')
					end
		</cfquery>
		<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfset columnNames = ListToArray(search.columnList)>
			<cfloop array="#columnNames#" index="columnName">
				<cfset row["#columnName#"] = "#search[columnName][currentrow]#">
				<cfquery name="getClob" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getClob_result">
					SELECT html_description 
					FROM underscore_collection
					WHERE
						underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#search.underscore_collection_id#">
				</cfquery>
				<cfloop query="getClob">
					<cfset row["HTML_DESCRIPTION"] = "#replace(encodeForHTML(REReplace(getClob.html_description,'<[^>]*>','','All')),'\n','')#">
				</cfloop>
			</cfloop>
			<cfset data[i]  = row>
			<cfset i = i + 1>
		</cfloop>
		<cfreturn #serializeJSON(data)#>
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

<!---
Function getNamedCollectionAutocomplete.  Search for named collections by name with a substring match on any name, returning json suitable for jquery-ui autocomplete.

@param term named collection name to search for.
@return a json structure containing id, meta, and value, with matching named collections with matched name in value and underscore_collection_id in id,
  and the begining of the description in meta.
--->
<cffunction name="getNamedCollectionAutocomplete" access="remote" returntype="any" returnformat="json">
	<cfargument name="term" type="string" required="yes">
	<!--- perform wildcard search anywhere in underscore_collection.collection_name --->

	<cfset data = ArrayNew(1)>
	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			SELECT 
				underscore_collection.underscore_collection_id as underscore_collection_id, 
				collection_name,
				case 
					when length(description) > 40 then
						substr(description,1,40) || '...'
					else
						description
					end
					as description_trim
			FROM 
				underscore_collection
			WHERE
				upper(collection_name) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(term)#%">
		</cfquery>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfset row["id"] = "#search.underscore_collection_id#">
			<cfset row["value"] = "#search.collection_name#" >
			<cfset row["meta"] = "#search.description_trim#" >
			<cfset data[i]  = row>
			<cfset i = i + 1>
		</cfloop>
		<cfreturn #serializeJSON(data)#>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset message = trim("Error processing getNamedCollectionAutocomplete: " & cfcatch.message & " " & cfcatch.detail & " " & queryError)  >
		<cfheader statusCode="500" statusText="#message#">
			<cfoutput>
				<div class="container">
					<div class="row">
						<div class="alert alert-danger" role="alert">
							<img src="/shared/images/Process-stop.png" alt="[ error ]" style="float:left; width: 50px;margin-right: 1em;">
							<h2>Internal Server Error.</h2>
							<p>#message#</p>
							<p><a href="/info/bugs.cfm">“Feedback/Report Errors”</a></p>
						</div>
					</div>
				</div>
			</cfoutput>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn #serializeJSON(data)#>
</cffunction>

<!--- Obtain a list of the specimens in a named group in a form suitable for display in a jqxgrid. 
  @param underscore_collection_id the surrogate numeric primary key identifying the named group.
  @return a json data structure with specimen data 
--->
<cffunction name="getSpecimensInGroup" access="remote" returntype="any" returnformat="json">
	<cfargument name="underscore_collection_id" type="string" required="yes">

	<cftry>
		<cfquery name="qrySpecimens"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" >
			SELECT DISTINCT flat.guid, flat.scientific_name,  flat.verbatim_date, flat.higher_geog, flat.spec_locality, 
				flat.othercatalognumbers, flat.full_taxon_name
			FROM
				underscore_collection
				left join underscore_relation on underscore_collection.underscore_collection_id = underscore_relation.underscore_collection_id
				left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat 
					on underscore_relation.collection_object_id = flat.collection_object_id
			WHERE underscore_collection.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
				and flat.guid is not null
			ORDER BY flat.guid asc
		</cfquery>
		<cfset i = 1>
		<cfset data = ArrayNew(1)>
		<cfloop query="qrySpecimens">
			<cfset row = StructNew()>
			<cfloop list="#ArrayToList(search.getColumnNames())#" index="col" >
				<cfset row["#lcase(col)#"] = "#search[col][currentRow]#">
			</cfloop>
			<cfset data[i]  = row>
			<cfset i = i + 1>
		</cfloop>
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
