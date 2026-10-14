<!---
shared/component/roles.cfc

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
<!--- Functions for showing database roles consistently, as on /tools/access_report.cfm.  No method is remote. --->
<cfcomponent>

<!---
	collectionRoleNames the roles named by cf_collection.portal_name, in upper case.

	@return a comma separated list of role names.
--->
<cffunction name="collectionRoleNames" access="public" returntype="string" output="false">
	<cfset var getCollectionRoles = "">
	<cfset var getCollectionRoles_result = "">
	<cfquery name="getCollectionRoles" datasource="uam_god" result="getCollectionRoles_result" cachedwithin="#createTimeSpan(0,1,0,0)#">
		SELECT DISTINCT upper(portal_name) AS role_name
		FROM cf_collection
		WHERE portal_name IS NOT NULL
	</cfquery>
	<cfreturn valueList(getCollectionRoles.role_name)>
</cffunction>

<!---
	isCollectionRole test whether a role gives access to a collection's data.

	@param role the role name, in upper case.
	@param collectionRoles the list from collectionRoleNames(), which is looked up when not given.
	@return true for roles named by cf_collection.portal_name, or starting MCZ_.
--->
<cffunction name="isCollectionRole" access="public" returntype="boolean" output="false">
	<cfargument name="role" type="string" required="yes">
	<cfargument name="collectionRoles" type="string" required="no" default="#collectionRoleNames()#">
	<cfreturn listFind(arguments.collectionRoles, arguments.role) GT 0 OR left(arguments.role, 4) EQ "MCZ_">
</cffunction>

<!---
	roleBadgeClass choose the badge colour for a role, so kinds of role can be told apart at a glance.

	@param role the role name, in upper case.
	@param collectionRoles the list from collectionRoleNames(), which is looked up when not given.
	@return Bootstrap badge classes.
--->
<cffunction name="roleBadgeClass" access="public" returntype="string" output="false">
	<cfargument name="role" type="string" required="yes">
	<cfargument name="collectionRoles" type="string" required="no" default="#collectionRoleNames()#">
	<cfif listFind("DBA,GLOBAL_ADMIN", arguments.role) GT 0>
		<cfreturn "badge-danger">
	<cfelseif left(arguments.role, 6) EQ "ADMIN_">
		<cfreturn "badge-warning">
	<cfelseif ucase(arguments.role) EQ "CURATORIAL_ASSOCIATE">
		<cfreturn "badge-primary">
	<cfelseif arguments.role EQ "MANAGE_COLLECTION">
		<cfreturn "badge-info">
	<cfelseif isCollectionRole(arguments.role, arguments.collectionRoles)>
		<cfreturn "badge-success">
	<cfelseif arguments.role EQ "CONNECT">
		<cfreturn "badge-dark">
	</cfif>
	<cfreturn "badge-light border">
</cffunction>

</cfcomponent>
