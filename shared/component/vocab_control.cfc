<!---
shared/component/vocab_control.cfc
Functions for working with code tables and other controlled vocabularies.

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
<!---   
	Function getGuidTypeInfo 
	Obtain metadata about an entry in ctGUID_TYPE, on error return http status 500
	@param guid_type the guid_type to lookup
	@return a json structure containing key value pairs of the metadata describing the guid_type.
--->
<cffunction name="getGuidTypeInfo" access="remote" returntype="any" returnformat="json">
	<cfargument name="guid_type" type="string" required="yes">
	<cfset data = ArrayNew(1)>
	<cftry>
		<cfquery name="qryLoc" datasource="uam_god">
			SELECT
				guid_type, description, applies_to, placeholder, 
				pattern_regex, resolver_regex, resolver_replacement, search_uri 
			FROM 
				ctGuid_Type
			WHERE 
				guid_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#guid_type#">
		</cfquery>
		<cfset i = 1>
		<cfloop query="qryLoc">
			<cfset row = StructNew()>
			<cfset row["guid_type"] = "#qryLoc.guid_type#">
			<cfset row["description"] = "#qryLoc.description#">
			<cfset row["applies_to"] = "#qryLoc.applies_to#">
			<cfset row["placeholder"] = "#qryLoc.placeholder#">
			<cfset row["pattern_regex"] = "#qryLoc.pattern_regex#">
			<cfset row["resolver_regex"] = "#qryLoc.resolver_regex#">
			<cfset row["resolver_replacement"] = "#qryLoc.resolver_replacement#">
			<cfset row["search_uri"] = "#qryLoc.search_uri#">
			<cfset data[i]  = row>
			<cfset i = i + 1>
		</cfloop>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset message = trim("Error processing getPermitsJSON: " & cfcatch.message & " " & cfcatch.detail & " " & queryError)  >
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
		<cfabort> <!---- ********** ---->
	</cfcatch>
	</cftry>

	<cfreturn #serializeJSON(data)#>
</cffunction>

</cfcomponent>
