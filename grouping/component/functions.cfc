<!---
vocabularies/component/functions.cfc

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

<!--- function saveUndColl 
Update an existing arbitrary collection record (underscore_collection).

@param underscore_collection_id primary key of record to update
@param collection_name the brief uman readable description of the arbitrary collection, must not be blank.
@param description description of the collection
@param underscore_agent_id the agent associated with this arbitrary collection
@return json structure with status and id or http status 500
--->
<cffunction name="saveUndColl" access="remote" returntype="any" returnformat="json">
	<cfargument name="underscore_collection_id" type="string" required="yes">
	<cfargument name="collection_name" type="string" required="yes">
	<cfargument name="description" type="string" required="no">
	<cfargument name="underscore_agent_id" type="string" required="no">

	<cfset data = ArrayNew(1)>
	<cftry>
		<cfif len(trim(#collection_name#)) EQ 0>
			<cfthrow type="Application" message="Number Series must contain a value.">
		</cfif>
		<cfquery name="save" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			update underscore_collection set
				collection_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#collection_name#">
				<cfif isdefined("description")>
					,description = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#description#">
				</cfif>
				<cfif isdefined("underscore_agent_id") and length(underscore_agent_id) GT 0>
					,underscore_agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_agent_id#">
				<cfelse>
					,underscore_agent_id = NULL
				</cfif>
			where 
				underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
		</cfquery>
		<cfset row = StructNew()>
		<cfset row["status"] = "saved">
		<cfset row["id"] = "#underscore_collection_id#">
		<cfset data[1] = row>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset message = trim("Error processing saveUndColl: " & cfcatch.message & " " & cfcatch.detail & " " & queryError) >
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

<!---
Function getUndCollList.  Search for arbitrary collections returning json suitable for a dataadaptor.

@param collection_name name of the underscore collection (arbitrary grouping) to search for.
@return a json structure containing matching coll event number series.
--->
<cffunction name="getUndCollList" access="remote" returntype="any" returnformat="json">
	<cfargument name="collection_name" type="string" required="yes">
	<!--- perform wildcard search anywhere in coll_event_collection_name.collection_name --->
	<cfset collection_name = "%#collection_name#%"> 

	<cfset data = ArrayNew(1)>
	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			SELECT 
				underscore_collection_id, 
				collection_name, description,
				underscore_agent_id, 
				MCZBASE.get_agentnameoftype(underscore_agent_id,'preferred') as agent_name
			FROM 
				underscore_collection
			WHERE
				collection_name like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#collection_name#">
		</cfquery>
	<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfif search.edited EQ 1 ><cfset edited_marker="*"><cfelse><cfset edited_marker=""></cfif> 
			<cfset row["coll_event_num_series_id"] = "#search.coll_event_num_series_id#">
			<cfset row["collection_name"] = "#search.collection_name#">
			<cfset row["description"] = "#search.description#">
			<cfset row["agent_name"] = "#search.agent_name#">
			<cfset row["id_link"] = "<a href='/grouping/UnderscoreCollection.cfm?method=edit&underscore_collection_id#search.underscore_collection_id#' target='_blank'>#search.collection_name#</a>">
			<cfset data[i] = row>
			<cfset i = i + 1>
		</cfloop>
		<cfreturn #serializeJSON(data)#>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset message = trim("Error processing getUndCollList: " & cfcatch.message & " " & cfcatch.detail & " " & queryError) >
		<cfheader statusCode="500" statusText="#message#">
			<cfoutput>
				<div class="container">
					<div class="row">
						<div class="alert alert-danger" role="alert">
							<img src="/shared/images/Process-stop.png" alt="[ Error ]" style="float:left; width: 50px;margin-right: 1em;">
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


</cfcomponent>
