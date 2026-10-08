<!---
Admin/component/functions.cfc

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
<!--- Backing methods for administrative pages in /Admin/, role global_admin. --->
<cfcomponent>
<cf_rolecheck>
<cfinclude template="/shared/component/error_handler.cfc" runOnce="true">
<cfinclude template="/shared/component/fileUtilities.cfc" runOnce="true">

<!---
	setFormPermission grant or remove one role's requirement for a page or component in
	cf_form_permissions, for /Admin/form_roles.cfm.  cf_rolecheck requires a user to hold every
	role listed for a path, and refuses a path with no rows.

	@param form_path the webroot relative path of an existing .cfm or .cfc file, starting with /.
	@param role_name a role in cf_ctuser_roles.
	@param granted true to require the role for the path, false to remove the requirement.
	@return a struct with status "saved", the path's resulting roles, the instance (host name) whose
		database was changed, and sql, a statement making the same change on another instance's
		database; or status "error" and a message when the request is not allowed or not valid.
--->
<cffunction name="setFormPermission" access="remote" returntype="any" returnformat="json">
	<cfargument name="form_path" type="string" required="yes">
	<cfargument name="role_name" type="string" required="yes">
	<cfargument name="granted" type="string" required="yes">

	<cfset var retval = structNew()>
	<cfset var getRole = "">
	<cfset var getExisting = "">
	<cfset var addPermission = "">
	<cfset var removePermission = "">
	<cfset var getRoles = "">
	<cfset var quotedPath = "">
	<cfset var quotedRole = "">

	<!--- Checked here as well as by cf_rolecheck, as this method writes the table every page check reads. --->
	<cfif NOT ( isdefined("session.roles") AND listfindnocase(session.roles,"global_admin") ) >
		<cfset retval["status"] = "error">
		<cfset retval["message"] = "Changing form permissions requires the global_admin role.">
		<cfreturn retval>
	</cfif>
	<cfif listFindNoCase("cfm,cfc", listLast(arguments.form_path, ".")) EQ 0
			OR left(arguments.form_path, 1) NEQ "/"
			OR len(resolveFileUnderDirectory(application.webDirectory, arguments.form_path)) EQ 0>
		<cfset retval["status"] = "error">
		<cfset retval["message"] = "Permissions can be set only for an existing .cfm or .cfc file under the webroot.">
		<cfreturn retval>
	</cfif>
	<cftry>
		<cfquery name="getRole" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getRole_result">
			SELECT role_name
			FROM cf_ctuser_roles
			WHERE
				upper(role_name) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(arguments.role_name)#">
		</cfquery>
		<cfif getRole.recordcount NEQ 1>
			<cfset retval["status"] = "error">
			<cfset retval["message"] = "Unknown role.">
			<cfreturn retval>
		</cfif>
		<cftransaction>
			<cfquery name="getExisting" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getExisting_result">
				SELECT count(*) AS ct
				FROM cf_form_permissions
				WHERE
					form_path = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.form_path#">
					AND upper(role_name) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(getRole.role_name)#">
			</cfquery>
			<cfif compareNoCase(arguments.granted, "true") EQ 0>
				<cfif getExisting.ct EQ 0>
					<cfquery name="addPermission" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="addPermission_result">
						INSERT INTO cf_form_permissions (
							form_path,
							role_name
						) VALUES (
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.form_path#">,
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getRole.role_name#">
						)
					</cfquery>
				</cfif>
			<cfelse>
				<cfquery name="removePermission" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="removePermission_result">
					DELETE FROM cf_form_permissions
					WHERE
						form_path = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.form_path#">
						AND upper(role_name) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(getRole.role_name)#">
				</cfquery>
			</cfif>
			<cfquery name="getRoles" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getRoles_result">
				SELECT role_name
				FROM cf_form_permissions
				WHERE
					form_path = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.form_path#">
				ORDER BY role_name
			</cfquery>
		</cftransaction>
		<cfset retval["status"] = "saved">
		<cfset retval["form_path"] = arguments.form_path>
		<cfset retval["role_name"] = getRole.role_name>
		<cfset retval["roles"] = valueList(getRoles.role_name)>
		<!--- The change applies only to this instance's database; the statement repeats it elsewhere, and is safe to run where the change is already present. --->
		<cfset retval["instance"] = application.hostName>
		<cfset quotedPath = "'" & replace(arguments.form_path, "'", "''", "all") & "'">
		<cfset quotedRole = "'" & replace(getRole.role_name, "'", "''", "all") & "'">
		<cfif compareNoCase(arguments.granted, "true") EQ 0>
			<cfset retval["sql"] = "INSERT INTO cf_form_permissions (form_path, role_name) SELECT #quotedPath#, #quotedRole# FROM dual WHERE NOT EXISTS (SELECT 1 FROM cf_form_permissions WHERE form_path = #quotedPath# AND upper(role_name) = upper(#quotedRole#));">
		<cfelse>
			<cfset retval["sql"] = "DELETE FROM cf_form_permissions WHERE form_path = #quotedPath# AND upper(role_name) = upper(#quotedRole#);">
		</cfif>
	<cfcatch>
		<cfset error_message = cfcatchToErrorMessage(cfcatch)>
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript>reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn retval>
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
	<cfif NOT ( isdefined("session.roles") AND listfindnocase(session.roles,"global_admin") ) >
		<cfthrow message="Not authorized">
	</cfif>
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
	<cfif NOT ( isdefined("session.roles") AND listfindnocase(session.roles,"global_admin") ) >
		<cfthrow message="Not authorized">
	</cfif>
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
	<cfif NOT ( isdefined("session.roles") AND listfindnocase(session.roles,"global_admin") ) >
		<cfthrow message="Not authorized">
	</cfif>
	<cfquery name="lookup" datasource="uam_god" result="lookup_result">
		SELECT DISTINCT object_name AS value, object_name AS meta
		FROM dba_audit_policies
		WHERE object_name LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(REReplace(arguments.term, '^=', ''))#%">
		ORDER BY object_name
	</cfquery>
	<cfreturn autocompleteJson(lookup)>
</cffunction>

</cfcomponent>
