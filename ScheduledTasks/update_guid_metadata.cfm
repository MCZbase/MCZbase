<!--- ScheduledTasks/update_guid_metadata.cfm

Copyright 2025 President and Fellows of Harvard College

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
<!--- This script updates the metadata field in the guid_our_thing table for records where 
   metadata is NULL and the resolver_prefix indicates an MCZBase UUID and the disposition is 'exists'
   it allows for persistence of metadata about the object even if it is deleted from MCZBase.
	This script fetches the JSON representation of the object from the assembled_resolvable URL and 
   stores it in the guid_our_thing.metadata field. --->
<cfquery  name="getGuids" datasource="cf_dbuser">
	SELECT assembled_resolvable 
	FROM guid_our_thing 
	WHERE metadata IS NULL
		AND resolver_prefix = 'https://mczbase.mcz.harvard.edu/uuid/'
		AND disposition = 'exists'
</cfquery>
<cfloop query="getGuids">
	<!--- lookup the current json representation of the object --->
	<cfhttp url="#getGuids.assembled_resolvable#/json" method="get" result="httpResponse" timeout="10">
	<cfif httpResponse.statusCode EQ "200 OK">
		<cftry>
			<!--- test for valid json, if so save as guid_our_thing.metadata --->
			<cfset jsonData = deserializeJson(httpResponse.fileContent)>
			<cfquery datasource="uam_god">
				UPDATE guid_our_thing
				SET metadata = <cfqueryparam value="#httpResponse.fileContent#" cfsqltype="cf_sql_longvarchar">
				WHERE assembled_resolvable = <cfqueryparam value="#getGuids.assembled_resolvable#" cfsqltype="cf_sql_varchar">
			</cfquery>
			<cfoutput>Updated metadata for GUID: #getGuids.assembled_resolvable#<br></cfoutput>
		<cfcatch>
			<cfoutput>Error processing JSON for GUID: #getGuids.assembled_resolvable# - #cfcatch.message#<br></cfoutput>
		</cfcatch>
		</cftry>
	<cfelse>
		<cfoutput>No metadata found for GUID: #getGuids.assembled_resolvable#<br></cfoutput>
	</cfif>
</cfloop>
