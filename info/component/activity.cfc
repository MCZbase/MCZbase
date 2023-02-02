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

<!--- getCollobjectActivity obtain activity statistics for a set of cataloged items over a period of time.
  @param underscore_collection_id if specified, limit to cataloged items in a particular named group.
  @param result_id if specified, limit to cataloged items in a user's search result.  One of underscore_collection_id
    and result_id can be specified, if both are provided, only underscore_collection_id will be used, if neither
    are specified results will count from all cataloged items.
  @param start_date a date, in the form yyyy-mm-dd, to be used as the earliest date for georeference determinations and 
    the entered date for cataloged items.  Note that georeference determinations on specimens entered outside the specified
    start and end dates will not be counted.
  @param end_date a date, in the form yyyy-mm-dd, to be used as the latest date for georeference determinations and
    the entered date for cataloged items.  If neither start_date nor end_date are provided, results will count from all dates.
    If only one of start_date and end_date are specified, then it will be ignored.
  @param group_by_collection, if equal to true, then group the results by collection code, otherwise provide one set of counts.
  @return a json structure containing collection, catitem_entered, part_ct, collobj_georefed, collobj_georef_verified
    if group_by_collection is not true, then one row with collection="All", otherwise one row for each 
    collection found.  
--->
<cffunction name="getCollObjectActivity" access="remote" returntype="any" returnformat="json">
	<cfargument name="underscore_collection_id" type="string" required="no">
	<cfargument name="result_id" type="string" required="no">
	<cfargument name="start_date" type="string" required="no">
	<cfargument name="end_date" type="string" required="no">
	<cfargument name="group_by_collection" type="string" required="no">
	
	<cfset data = ArrayNew(1)>
	<cftry>
		<cfquery name="activity" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="activity_result">
			SELECT 
				count(distinct flatTableName.collection_object_id) as catitem_entered,
				sum(flatTableName.total_parts) as part_ct,
				count(distinct lat_long.locality_id) as collobj_georefed,
				count(distinct verified_lat_long.locality_id) as collobj_georef_verified
				<cfif isDefined("group_by_collection") and group_by_collection EQ "true" >
					, flatTableName.collection_cde
				</cfif>
			FROM
				<cfif session.flatTableName EQ "FLAT">flat<cfelse>filtered_flat</cfif> flatTableName
				left join lat_long on flatTableName.locality_id = lat_long.locality_id
					<cfif isDefined("start_date") and len(start_date) GT 0 and isDefined("end_date") and len(end_date) GT 0>
						and lat_long.determined_date 
							between to_date(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#start_date#">,'yyyy-mm-dd') 
								AND to_date(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#end_date#">,'yyyy-mm-dd')
					</cfif>
				left join lat_long verified_lat_long on flatTableName.locality_id = verified_lat_long.locality_id
					and verified_lat_long.accepted_lat_long_fg = 1
					and verified_lat_long.verificationstatus like 'verified%'
					<cfif isDefined("start_date") and len(start_date) GT 0 and isDefined("end_date") and len(end_date) GT 0>
						and verified_lat_long.determined_date
							between to_date(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#start_date#">,'yyyy-mm-dd')
								AND to_date(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#end_date#">,'yyyy-mm-dd')
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
					and coll_object.coll_object_entered_date 
						between to_date(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#start_date#">,'yyyy-mm-dd')
							AND to_date(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#end_date#">,'yyyy-mm-dd')
				</cfif>
			<cfif isDefined("group_by_collection") and group_by_collection EQ "true" >
				GROUP BY
					flatTableName.collection_cde
			</cfif>
		</cfquery>

		<cfset i = 0>
		<cfloop query="activity">
			<cfset i = i+1>
			<cfset row = StructNew()>
			<cfif isDefined("group_by_collection") and group_by_collection EQ "true" >
				<cfset row["collection"] = "#collection_cde#">
			<cfelse>
				<cfset row["collection"] = "all">
			</cfif>
			<cfset row["catitems_entered"] = "#catitem_entered#">
			<cfset row["part_count"] = "#part_ct#">
			<cfset row["georeferences_added"] = "#collobj_georefed#">
			<cfset row["verified_georeferences_added"] = "#collobj_georef_verified#">
			<cfset data[i] = row>
		</cfloop>
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

</cfcomponent>
