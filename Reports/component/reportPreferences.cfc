<!---
Reports/component/reportPreferences.cfc
Functions for a user's report preferences, the collection codes whose label reports
Reports/report_printer.cfm lists by default.

Copyright 2026 President and Fellows of Harvard College

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
<!--- A label report belongs to the collection codes after the double underscore in its name, split on
	single underscores (Fluid_Single_Jar__Herp_Orn is for Herp and Orn); __All is for everyone, so it is
	never a preference.  The preferences are stored in cf_users.reportprefs as a comma separated list.
	Included with runOnce; no method is remote. --->
<cfcomponent>

<!---
	reportCollectionCodes the codes a user may choose among for their report preferences: the collection
	codes of the collections, and any other code a label report's name carries.

	@return a query with code, the collection code, and report_count, the number of label reports
		for it, sorted by code.
--->
<cffunction name="reportCollectionCodes" access="public" returntype="query" output="false">
	<cfset var getCollectionCodes = "">
	<cfset var getReportNames = "">
	<cfset var reportCounts = {}>
	<cfset var nameCodes = "">
	<cfset var code = "">
	<cfset var codes = "">
	<cfset var result = queryNew("code,report_count", "varchar,integer")>
	<cfquery name="getCollectionCodes" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		SELECT DISTINCT collection_cde
		FROM collection
	</cfquery>
	<cfloop query="getCollectionCodes">
		<cfset reportCounts[getCollectionCodes.collection_cde] = 0>
	</cfloop>
	<!--- As on Reports/report_printer.cfm, which leaves the mcz_ transaction reports out of its list. --->
	<cfquery name="getReportNames" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		SELECT report_name
		FROM cf_report_sql
		WHERE report_name NOT LIKE 'mcz_%'
	</cfquery>
	<cfloop query="getReportNames">
		<cfset nameCodes = REMatch("__[a-zA-Z_]+$", getReportNames.report_name)>
		<cfif NOT arrayIsEmpty(nameCodes)>
			<cfloop list="#nameCodes[1]#" delimiters="_" index="code">
				<cfif code NEQ "All">
					<cfif NOT structKeyExists(reportCounts, code)>
						<cfset reportCounts[code] = 0>
					</cfif>
					<cfset reportCounts[code] = reportCounts[code] + 1>
				</cfif>
			</cfloop>
		</cfif>
	</cfloop>
	<cfset codes = listSort(structKeyList(reportCounts), "textnocase")>
	<cfloop list="#codes#" index="code">
		<cfset queryAddRow(result, { "code" = code, "report_count" = reportCounts[code] })>
	</cfloop>
	<cfreturn result>
</cffunction>

<!---
	validReportPrefs the codes of a submitted list that are among reportCollectionCodes(), once each.

	@param reportprefs a comma separated list of collection codes.
	@return a comma separated list of the valid codes, in the order of reportCollectionCodes().
--->
<cffunction name="validReportPrefs" access="public" returntype="string" output="false">
	<cfargument name="reportprefs" type="string" required="yes">
	<cfset var validCodes = reportCollectionCodes()>
	<cfset var result = "">
	<cfloop query="validCodes">
		<cfif listFindNoCase(replace(arguments.reportprefs, " ", "", "all"), validCodes.code) GT 0>
			<cfset result = listAppend(result, validCodes.code)>
		</cfif>
	</cfloop>
	<cfreturn result>
</cffunction>

</cfcomponent>
