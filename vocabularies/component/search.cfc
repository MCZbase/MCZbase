<!---
vocabularies/component/search.cfc

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

<!---   Function getCollEventNumberSeries  --->
<cffunction name="getCollEventNumberSeries" access="remote" returntype="any" returnformat="json">
	<cfargument name="number_series" type="string" required="no">
	<cfargument name="collector_agent_id" type="string" required="no">
	<cfargument name="number" type="string" required="no">
	<cfargument name="pattern" type="string" required="no">
	<cfargument name="remarks" type="string" required="no">

	<cfset data = ArrayNew(1)>
	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			select count(*) as number_count, number_series, coll_event_num_series.coll_event_num_series_id as id, pattern, remarks,
				collector_agent_id,
				case collector_agent_id
					when null then '[No Agent]'
					else MCZBASE.get_agentnameoftype(collector_agent_id, 'preferred')
					end
				as agentname
			from coll_event_num_series
					left join coll_event_number on coll_event_number.coll_event_num_series_id = coll_event_num_series.coll_event_num_series_id
			WHERE
				coll_event_num_series.coll_event_num_series_id is not null
				<cfif isDefined("number_series") and len(number_series) gt 0>
					and number_series like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#number_series#%">
				</cfif>
				<cfif isDefined("number") and len(number) gt 0>
					and number like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#number#">
				</cfif>
				<cfif isDefined("pattern") and len(pattern) gt 0>
					and pattern like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#pattern#">
				</cfif>
				<cfif isDefined("remarks") and len(remarks) gt 0>
					and remarks like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#remarks#">
				</cfif>
			group by 
				number_series, coll_event_num_series.coll_event_num_series_id, pattern, remarks,
				collector_agent_id,
				case collector_agent_id
					when null then '[No Agent]'
					else MCZBASE.get_agentnameoftype(collector_agent_id, 'preferred')
					end
		</cfquery>
		<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfset row["coll_event_num_series_id"] = "#search.id#">
			<cfset row["number_series"] = "#search.number_series#">
			<cfset row["pattern"] = "#search.pattern#">
			<cfset row["remarks"] = "#search.remarks#">
			<cfset row["agentname"] = "#search.agentname#">
			<cfset row["collector_agent_id"] = "#search.collector_agent_id#">
			<cfset row["number_count"] = "#search.number_count#">
			<cfset row["id_link"] = "<a href='/vocabularies/CollEventNumberSeries.cfm?action=edit&coll_event_num_series_id=#search.id#' target='_blank'>#search.number_series#</a>">
			<cfset data[i]  = row>
			<cfset i = i + 1>
		</cfloop>
		<cfreturn #serializeJSON(data)#>
	<cfcatch>
      <cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
      <cfset message = trim("Error processing getTransactions: " & cfcatch.message & " " & cfcatch.detail & " " & queryError)  >
      <cfheader statusCode="500" statusText="#message#">
	   <cfabort>
	</cfcatch>
	</cftry>
	<cfreturn #serializeJSON(data)#>
</cffunction>

</cfcomponent>
