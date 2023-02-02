<!---
info/component/activity.cfc

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
<cfinclude template="/shared/component/error_handler.cfc" runOnce="true">
<cf_rolecheck>

<!--- getCollobjectActivity obtain activity statistics for a set of cataloged items over a period of time 
--->
<cffunction name="getCollObjectActivity" access="remote" returntype="any" returnformat="json">
	<cfargument name="underscore_collection_id" type="string" required="no">
	<cfargument name="result_id" type="string" required="no">
	<cfargument name="start_date" type="string" required="no">
	<cfargument name="end_date" type="string" required="no">
	
	<cfset data = ArrayNew(1)>
	<cftry>
		<cfquery name="activity" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="activity_result">
			SELECT 
				count(distinct flatTableName.collection_object_id) as catitem_entered,
				sum(flatTableName.total_parts) as part_ct,
				count(lat_long.locality_id) as collobj_georefed,
				count(verified_lat_long.locality_id) as collobj_georef_verified
			FROM
				<cfif session.flatTableName EQ "FLAT">flat<cfelse>filtered_flat</cfif> as flatTableName
				left join lat_long on flatTableName.locality_id = lat_long.locality_id
					<cfif isDefined("start_date") and len(start_date) GT 0 and isDefined("end_date") and len(end_date) GT 0>
						and determined_date between <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#start_date#"> AND <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#end_date#">
					</cfif>
				left join lat_long verified_lat_long on flatTableName.locality_id = verified_lat_long.locality_id
					and verified_lat_long.accepted_lat_long_fg = 1
					and verified_lat_long.verificationstatus like 'verified%'
					<cfif isDefined("start_date") and len(start_date) GT 0 and isDefined("end_date") and len(end_date) GT 0>
						and determined_date between <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#start_date#"> AND <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#end_date#">
					</cfif>
				join coll_object on flatTableName.collection_object_id = coll_object.collection_object_id
				<cfif isDefined("underscore_collection_id") and len(underscore_collection_id) GT 0>
					join underscore_relation on flatTableName.collection_object_id = underscore_relation.collection_object_id
				<cfelseif isDefined("result_id") and len(result_id) GT 0>
					join user_search_table on flatTableName.collection_object_id = user_search_table.collection_object_id
				</cfif>
			WHERE
				<cfif isDefined("underscore_collection_id") and len(underscore_collection_id) GT 0>
					underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
				<cfelseif isDefined("result_id") and len(result_id) GT 0>
					result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
				<cfelse>
					flatTableName.collection_object_id is not null
				</cfif>
				<cfif isDefined("start_date") and len(start_date) GT 0 and isDefined("end_date") and len(end_date) GT 0>
					and coll_object.entered_date between <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#start_date#"> AND <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#end_date#">
				</cfif>
		</cfquery>

		<cfset row = StructNew()>
		<cfset row["catitems_entered"] = "#catitem_entered#">
		<cfset row["part_count"] = "#part_ct#">
		<cfset row["georeferences_added"] = "#collobj_georefed#">
		<cfset row["verified_georefences_added"] = "#collobj_georef_verified#">
		<cfset data[1] = row>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn #serializeJSON(data)#>
</cfunction>

</cfcomponent>
