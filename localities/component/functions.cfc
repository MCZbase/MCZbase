<!---
localities/component/functions.cfc

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

<!--- function deleteCollEventNumber
Delete an existing collecting event number record.

@param coll_event_number_id primary key of record to delete
@return json structure with status and id or http status 500
--->
<cffunction name="deleteCollEventNumber" access="remote" returntype="any" returnformat="json">
	<cfargument name="coll_event_number_id" type="string" required="yes">

	<cfset data = ArrayNew(1)>
	<cftry>
		<cfquery name="save" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			delete from coll_event_number 
			where 
				coll_event_number_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#coll_event_number_id#">
		</cfquery>
		<cfset row = StructNew()>
		<cfset row["status"] = "deleted">
		<cfset row["id"] = "#coll_event_number_id#">
		<cfset data[1] = row>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset message = trim("Error processing deleteCollEventNumber: " & cfcatch.message & " " & cfcatch.detail & " " & queryError) >
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

</cfcomponent>
