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

<!--- function saveNumberSeries 
Update an existing collecting event number series record.

@param coll_event_num_series_id primary key of record to update
@param number_series the brief human readable description of the number series, must not be blank.
@param pattern pattern expected of values in the number series
@param remarks remarks about the number series
@param collector_agent_id the collector for whom this is a number series
@return json structure with status and id or http status 500
--->
<cffunction name="saveNumSeries" access="remote" returntype="any" returnformat="json">
	<cfargument name="coll_event_num_series_id" type="string" required="yes">
	<cfargument name="number_series" type="string" required="yes">
	<cfargument name="pattern" type="string" required="no">
	<cfargument name="remarks" type="string" required="no">
	<cfargument name="collector_agent_id" type="string" required="no">

	<cfset data = ArrayNew(1)>
	<cftry>
		<cfif len(trim(#number_series#) EQ 0)>
			<cfthrow type="Application" message="Number Series must contain a value.">
		</cfif>
		<cfquery name="save" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			update coll_event_num_series set
				number_series = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#number_series#">
				<cfif isdefined("pattern")>
					,pattern = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#pattern#">
				</cfif>
				<cfif isdefined("remarks")>
					,remarks = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#remarks#">
				</cfif>
				<cfif isdefined("collector_agent_id")>
					,collector_agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collector_agent_id#">
				</cfif>
			where 
				coll_event_num_series_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#coll_event_num_series_id#">
		</cfquery>
		<cfset row = StructNew()>
		<cfset row["status"] = "saved">
		<cfset row["id"] = "#coll_event_num_series_id#">
		<cfset data[1] = row>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset message = trim("Error processing getPermitsJSON: " & cfcatch.message & " " & cfcatch.detail & " " & queryError) >
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
Function getNumSeriesList.  Search for collector number series returning json suitable for a dataadaptor.

@param number_series name of the number series to search for.
@return a json structure containing matching coll event number series.
--->
<cffunction name="getNumSeriesList" access="remote" returntype="any" returnformat="json">
	<cfargument name="number_series" type="string" required="yes">
	<!--- perform wildcard search anywhere in coll_event_number_series.number_series --->
	<cfset number_series = "%#number_series#%"> 

	<cfset data = ArrayNew(1)>
	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			SELECT 
				coll_event_number_series_id, number_series, pattern, remarks,
				collector_agent_id, 
				MCZBASE.get_agentnameoftype(collector_agent_id,'preferred') preferred_agent_name
			FROM 
				coll_event_number_series
			WHERE
				number_series like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#number_series#">
		</cfquery>
	<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfif search.edited EQ 1 ><cfset edited_marker="*"><cfelse><cfset edited_marker=""></cfif> 
			<cfset row["coll_event_num_series_id"] = "#search.coll_event_num_series_id#">
			<cfset row["number_series"] = "#search.number_series#">
			<cfset row["pattern"] = "#search.pattern#">
			<cfset row["remarks"] = "#search.remarks#">
			<cfset row["preferred_agent_name"] = "#search.preferred_agent_name#">
			<cfset row["id_link"] = "<a href='/vocabularies/CollEventNumber.cfm?method=edit&coll_event_num_series_id#search.coll_event_num_series_id#' target='_blank'>#search.number_series#</a>">
			<cfset data[i] = row>
			<cfset i = i + 1>
		</cfloop>
		<cfreturn #serializeJSON(data)#>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset message = trim("Error processing getAgentList: " & cfcatch.message & " " & cfcatch.detail & " " & queryError) >
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
