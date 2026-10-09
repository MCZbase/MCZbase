<!---
Admin/component/activity.cfc

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
<!--- Backing methods for the user activity pages, /Admin/ActivityLog.cfm and /Admin/download.cfm, for
	the global_admin and curatorial_associate roles.  The component's row is curatorial_associate,
	which cf_rolecheck also lets global_admin through, and each method checks for either role. --->
<cfcomponent>
<cf_rolecheck>
<cfinclude template="/shared/component/error_handler.cfc" runOnce="true">

<!---
	isActivityViewer whether the current user may see the user activity pages.

	@return true for global_admin or curatorial_associate.
--->
<cffunction name="isActivityViewer" access="public" returntype="boolean" output="false">
	<cfif NOT isdefined("session.roles")>
		<cfreturn false>
	</cfif>
	<cfif listfindnocase(session.roles,"global_admin") OR listfindnocase(session.roles,"curatorial_associate")>
		<cfreturn true>
	</cfif>
	<cfreturn false>
</cffunction>

<!---
	requireActivityViewer stop a method for anyone who may not see the user activity pages.
--->
<cffunction name="requireActivityViewer" access="private" returntype="void" output="false">
	<cfif NOT isActivityViewer()>
		<cfthrow message="Not authorized">
	</cfif>
</cffunction>

<!---
	autocompleteJson the shared body of the autocompletes below: run a lookup returning value and
	meta columns, and return them as JSON for a jQuery UI autocomplete.

	@param lookup the query to return.
	@return JSON array of value and meta pairs.
--->
<cffunction name="autocompleteJson" access="private" returntype="string" output="false">
	<cfargument name="lookup" type="query" required="yes">
	<cfset var data = ArrayNew(1)>
	<cfset var row = "">
	<cfloop query="arguments.lookup">
		<cfset row = StructNew()>
		<cfset row["value"] = arguments.lookup.value>
		<cfset row["meta"] = arguments.lookup.meta>
		<cfset ArrayAppend(data, row)>
	</cfloop>
	<cfreturn serializeJSON(data)>
</cffunction>

<!---
	getDownloadUserAutocomplete usernames of users with logged downloads, for /Admin/download.cfm.

	@param term text the username contains; a leading = is ignored.
	@return JSON array of value (username) and meta (username and name).
--->
<cffunction name="getDownloadUserAutocomplete" access="remote" returntype="any" returnformat="plain">
	<cfargument name="term" type="string" required="yes">
	<cfset var lookup = "">
	<cfset var metaText = "">
	<cfset var lookup_result = "">
	<cfset requireActivityViewer()>
	<cfquery name="lookup" datasource="cf_dbuser" result="lookup_result">
		SELECT * FROM (
			SELECT DISTINCT cf_users.username AS value, cf_user_data.first_name, cf_user_data.last_name
			FROM cf_users
				JOIN cf_download ON cf_users.user_id = cf_download.user_id
				LEFT JOIN cf_user_data ON cf_users.user_id = cf_user_data.user_id
			WHERE upper(cf_users.username) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(REReplace(arguments.term, '^=', ''))#%">
			ORDER BY cf_users.username
		)
		WHERE rownum <= 50
	</cfquery>
	<cfset QueryAddColumn(lookup, "meta", "varchar", ArrayNew(1))>
	<cfloop query="lookup">
		<cfset metaText = lookup.value>
		<cfif len(lookup.last_name) GT 0>
			<cfset metaText = "#lookup.value# (#trim(lookup.first_name & ' ' & lookup.last_name)#)">
		</cfif>
		<cfset QuerySetCell(lookup, "meta", metaText, lookup.currentRow)>
	</cfloop>
	<cfreturn autocompleteJson(lookup)>
</cffunction>

<!---
	getAuditUserAutocomplete database account names, for the database user field of /Admin/ActivityLog.cfm.

	@param term text the account name contains; a leading = is ignored.
	@return JSON array of value and meta (both the account name).
--->
<cffunction name="getAuditUserAutocomplete" access="remote" returntype="any" returnformat="plain">
	<cfargument name="term" type="string" required="yes">
	<cfset var lookup = "">
	<cfset var lookup_result = "">
	<cfset requireActivityViewer()>
	<cfquery name="lookup" datasource="uam_god" result="lookup_result">
		SELECT * FROM (
			SELECT username AS value, username AS meta
			FROM dba_users
			WHERE username LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(REReplace(arguments.term, '^=', ''))#%">
			ORDER BY username
		)
		WHERE rownum <= 50
	</cfquery>
	<cfreturn autocompleteJson(lookup)>
</cffunction>

<!---
	getAuditTableAutocomplete tables with a fine grained audit policy, for the table field of
	/Admin/ActivityLog.cfm.

	@param term text the table name contains; a leading = is ignored.
	@return JSON array of value and meta (both the table name).
--->
<cffunction name="getAuditTableAutocomplete" access="remote" returntype="any" returnformat="plain">
	<cfargument name="term" type="string" required="yes">
	<cfset var lookup = "">
	<cfset var lookup_result = "">
	<cfset requireActivityViewer()>
	<cfquery name="lookup" datasource="uam_god" result="lookup_result">
		SELECT DISTINCT object_name AS value, object_name AS meta
		FROM dba_audit_policies
		WHERE object_name LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(REReplace(arguments.term, '^=', ''))#%">
		ORDER BY object_name
	</cfquery>
	<cfreturn autocompleteJson(lookup)>
</cffunction>

</cfcomponent>
