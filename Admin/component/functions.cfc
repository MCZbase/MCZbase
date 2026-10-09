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

<!---
	getCodeTableChangesHtml the Admin Panel widget summarising recent changes to code tables (CT*)
	from the audit trail, each table expanding into its statements.

	@param days how many days back to look: 1, 7 or 30.
	@return HTML for the widget body.
--->
<cffunction name="getCodeTableChangesHtml" access="remote" returntype="string" returnformat="plain">
	<cfargument name="days" type="string" required="no" default="7">
	<cfset var lookbackDays = 7>
	<cfset var getChanges = "">
	<cfset var getChanges_result = "">
	<cfset var getTables = "">
	<cfset var tableChanges = "">
	<cfset var tableUsers = "">
	<cfset var beginDate = "">
	<cfset var html = "">
	<cfset var DETAIL_LIMIT = 200>
	<cfif NOT ( isdefined("session.roles") AND listfindnocase(session.roles,"global_admin") ) >
		<cfthrow message="Not authorized">
	</cfif>
	<cfif listFind("1,7,30", arguments.days)>
		<cfset lookbackDays = arguments.days>
	</cfif>
	<cfset beginDate = dateFormat(dateAdd("d", -lookbackDays, now()), "yyyy-mm-dd")>
	<cfquery name="getChanges" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getChanges_result">
		SELECT object_name, db_user, timestamp, sql_text, sql_bind
		FROM mczbase.arctos_audit
		WHERE
			upper(object_name) LIKE 'CT%'
			AND timestamp > sysdate - <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#lookbackDays#">
		ORDER BY object_name, timestamp DESC
	</cfquery>
	<cfquery name="getTables" dbtype="query">
		SELECT object_name, count(*) AS statements, max(timestamp) AS last_change
		FROM getChanges
		GROUP BY object_name
		ORDER BY object_name
	</cfquery>
	<cfsavecontent variable="html">
		<cfoutput>
			<p class="mb-2">
				#getChanges.recordcount# statements on #getTables.recordcount# code tables in the last #lookbackDays# day<cfif lookbackDays GT 1>s</cfif>.
			</p>
			<cfloop query="getTables">
				<cfquery name="tableChanges" dbtype="query" maxrows="#DETAIL_LIMIT#">
					SELECT db_user, timestamp, sql_text, sql_bind
					FROM getChanges
					WHERE object_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTables.object_name#">
					ORDER BY timestamp DESC
				</cfquery>
				<cfquery name="tableUsers" dbtype="query">
					SELECT DISTINCT db_user
					FROM getChanges
					WHERE object_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTables.object_name#">
					ORDER BY db_user
				</cfquery>
				<details class="mb-1">
					<summary>
						<strong>#encodeForHtml(getTables.object_name)#</strong>:
						#getTables.statements# statement<cfif getTables.statements GT 1>s</cfif>,
						last #dateTimeFormat(getTables.last_change, "yyyy-mm-dd HH:nn")#
						by #encodeForHtml(valueList(tableUsers.db_user, ", "))#
					</summary>
					<table class="table table-sm table-striped table-responsive d-xl-table small mb-1">
						<thead class="thead-light">
							<tr><th scope="col">When</th><th scope="col">Who</th><th scope="col">Statement</th><th scope="col">Values</th></tr>
						</thead>
						<tbody>
							<cfloop query="tableChanges">
								<tr>
									<td class="text-nowrap">#dateTimeFormat(tableChanges.timestamp, "yyyy-mm-dd HH:nn:ss")#</td>
									<td>#encodeForHtml(tableChanges.db_user)#</td>
									<td><code>#encodeForHtml(tableChanges.sql_text)#</code></td>
									<td><code>#encodeForHtml(tableChanges.sql_bind)#</code></td>
								</tr>
							</cfloop>
						</tbody>
					</table>
					<cfif getTables.statements GT DETAIL_LIMIT>
						<p class="small mb-1">Showing the latest #DETAIL_LIMIT#.</p>
					</cfif>
					<a class="small" href="/Admin/ActivityLog.cfm?object_name=#encodeForUrl('=' & getTables.object_name)#&begin_date=#encodeForUrl(beginDate)#&execute=true">All changes to #encodeForHtml(getTables.object_name)# in the Audit SQL Log</a>
				</details>
			</cfloop>
		</cfoutput>
	</cfsavecontent>
	<cfreturn html>
</cffunction>

<!---
	getActiveUsersHtml the Admin Panel widget summarising who is using MCZbase now: recent logins,
	Oracle sessions, ColdFusion sessions and login locks.

	@return HTML for the widget body.
--->
<cffunction name="getActiveUsersHtml" access="remote" returntype="string" returnformat="plain">
	<cfset var getLogins = "">
	<cfset var getLogins_result = "">
	<cfset var getSessions = "">
	<cfset var getSessions_result = "">
	<cfset var getLocks = "">
	<cfset var getLocks_result = "">
	<cfset var sessionCount = "">
	<cfset var html = "">
	<!--- ColdFusion sessions last three hours (Application.cfc sessionTimeout) --->
	<cfset var SESSION_HOURS = 3>
	<cfif NOT ( isdefined("session.roles") AND listfindnocase(session.roles,"global_admin") ) >
		<cfthrow message="Not authorized">
	</cfif>
	<cfquery name="getLogins" datasource="uam_god" result="getLogins_result">
		SELECT cf_users.username, cf_users.last_login, dba_users.account_status
		FROM cf_users
			LEFT JOIN dba_users ON upper(cf_users.username) = dba_users.username
		WHERE cf_users.last_login > sysdate - <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#SESSION_HOURS#"> / 24
		ORDER BY cf_users.last_login DESC
	</cfquery>
	<cfquery name="getSessions" datasource="uam_god" result="getSessions_result">
		SELECT
			username,
			count(*) AS connections,
			sum(CASE WHEN status = 'ACTIVE' THEN 1 ELSE 0 END) AS active,
			min(last_call_et) AS idle_seconds,
			min(logon_time) AS first_logon
		FROM gv$session
		WHERE type = 'USER' AND username IS NOT NULL
		GROUP BY username
		ORDER BY username
	</cfquery>
	<cfquery name="getLocks" datasource="uam_god" result="getLocks_result">
		SELECT lock_kind, count(*) AS locked
		FROM cf_login_failure
		WHERE locked_until > sysdate
		GROUP BY lock_kind
	</cfquery>
	<!--- ColdFusion's own session count; an internal class, so shown only where it can be used --->
	<cftry>
		<cfset sessionCount = createObject("java", "coldfusion.runtime.SessionTracker").getSessionCount()>
	<cfcatch>
		<cfset sessionCount = "">
	</cfcatch>
	</cftry>
	<cfsavecontent variable="html">
		<cfoutput>
			<ul class="mb-2">
				<li>MCZbase logins in the last #SESSION_HOURS# hours: #getLogins.recordcount#
					(#listLen(valueList(getLogins.account_status))# with an Oracle account).</li>
				<li>ColdFusion sessions on this server:
					<cfif len(sessionCount) GT 0>#sessionCount#<cfelse>not available</cfif>.</li>
				<li>Login locks:
					<cfif getLocks.recordcount EQ 0>none<cfelse><cfloop query="getLocks">#getLocks.locked# #encodeForHtml(getLocks.lock_kind)#<cfif getLocks.currentRow LT getLocks.recordcount>, </cfif></cfloop></cfif>
					(<a href="/Admin/AdminUsers.cfm?action=list&state=locked">Locked Account search</a>).</li>
			</ul>
			<details class="mb-2">
				<summary><strong>Recent logins</strong> (#getLogins.recordcount#)</summary>
				<table class="table table-sm table-striped table-responsive d-xl-table small mb-1">
					<thead class="thead-light">
						<tr><th scope="col">Username</th><th scope="col">Logged in</th><th scope="col">Oracle account</th></tr>
					</thead>
					<tbody>
						<cfloop query="getLogins">
							<tr>
								<td><a href="/Admin/AdminUsers.cfm?action=edit&username=#encodeForUrl(getLogins.username)#">#encodeForHtml(getLogins.username)#</a></td>
								<td class="text-nowrap">#dateTimeFormat(getLogins.last_login, "yyyy-mm-dd HH:nn")#</td>
								<td><cfif len(getLogins.account_status) GT 0>#encodeForHtml(lcase(getLogins.account_status))#<cfelse>none (public account)</cfif></td>
							</tr>
						</cfloop>
					</tbody>
				</table>
			</details>
			<details>
				<summary><strong>Oracle sessions</strong> by account (#getSessions.recordcount#)</summary>
				<p class="small mb-1">
					ColdFusion keeps database connections open in a pool, so these are connections, not people logged in.
					Idle time is since the last call on the account's most recent connection.
				</p>
				<table class="table table-sm table-striped table-responsive d-xl-table small mb-1">
					<thead class="thead-light">
						<tr><th scope="col">Account</th><th scope="col">Connections</th><th scope="col">Active</th><th scope="col">Idle</th><th scope="col">Oldest connection</th></tr>
					</thead>
					<tbody>
						<cfloop query="getSessions">
							<tr>
								<td>#encodeForHtml(getSessions.username)#</td>
								<td>#getSessions.connections#</td>
								<td>#getSessions.active#</td>
								<td class="text-nowrap"><cfif getSessions.idle_seconds LT 3600>#int(getSessions.idle_seconds / 60)# min<cfelse>#int(getSessions.idle_seconds / 3600)# h</cfif></td>
								<td class="text-nowrap">#dateTimeFormat(getSessions.first_logon, "yyyy-mm-dd HH:nn")#</td>
							</tr>
						</cfloop>
					</tbody>
				</table>
			</details>
		</cfoutput>
	</cfsavecontent>
	<cfreturn html>
</cffunction>

</cfcomponent>
