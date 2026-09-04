<!---
tData.cfm

Copyright 2008-2017 Contributors to Arctos
Copyright 2008-2026 President and Fellows of Harvard College

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
<!--- Suggestion list backing the geology attribute value autocomplete on SpecimenSearch.cfm.
	Returns one suggestion per line as plain text, the format the jquery autocomplete plugin expects. --->
<cfparam name="url.action" default="">
<cfparam name="url.q" default="">
<cfparam name="url.t" default="">

<cfset variables.action = url.action>
<cfset variables.q = url.q>
<cfset variables.t = url.t>

<cfif variables.action IS "suggestGeologyAttVal">
	<cfquery name="ins" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		SELECT 
			attribute_value
		FROM 
			geology_attribute_hierarchy
		WHERE 
			upper(attribute_value) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(variables.q)#%">
			<cfif len(variables.t) GT 0>
				AND attribute = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.t#">
			</cfif>
		GROUP BY 
			attribute_value
	</cfquery>
	<cfoutput query="ins">#attribute_value##chr(10)#
	</cfoutput>
</cfif>
