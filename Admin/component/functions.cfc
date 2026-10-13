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
	role listed for a path, except that global_admin may open any path with rows, and refuses a path
	with no rows.

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
		<!--- timestamp is reserved in query of queries, so it is renamed --->
		SELECT object_name, db_user, timestamp AS changed_at, sql_text, sql_bind
		FROM mczbase.arctos_audit
		WHERE
			upper(object_name) LIKE 'CT%'
			AND timestamp > sysdate - <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#lookbackDays#">
		ORDER BY object_name, timestamp DESC
	</cfquery>
	<cfquery name="getTables" dbtype="query">
		SELECT object_name, count(*) AS statements, max(changed_at) AS last_change
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
					SELECT db_user, changed_at, sql_text, sql_bind
					FROM getChanges
					WHERE object_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTables.object_name#">
					ORDER BY changed_at DESC
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
									<td class="text-nowrap">#dateTimeFormat(tableChanges.changed_at, "yyyy-mm-dd HH:nn:ss")#</td>
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

<!---
	recentLogEntries the entries of a ColdFusion log written within a period, read from the end of
	the file so a large log is not read whole.

	@param logName one of MCZbase, mail, mailsent, scheduler, exception, application.
	@param sinceHours how far back to go.
	@param contains if given, only entries whose message contains this text.
	@return an array of structures with severity, logged (a date) and message, oldest first; empty if
		the log can't be read.
--->
<cffunction name="recentLogEntries" access="private" returntype="array" output="false">
	<cfargument name="logName" type="string" required="yes">
	<cfargument name="sinceHours" type="numeric" required="yes">
	<cfargument name="contains" type="string" required="no" default="">
	<cfset var entries = arrayNew(1)>
	<cfset var logFile = "">
	<cfset var path = "">
	<cfset var line = "">
	<cfset var parts = "">
	<cfset var logged = "">
	<cfset var since = dateAdd("h", -arguments.sinceHours, now())>
	<cfset var TAIL_BYTES = 2000000>
	<cfif NOT listFindNoCase("MCZbase,mail,mailsent,scheduler,exception,application", arguments.logName)>
		<cfreturn entries>
	</cfif>
	<cfset path = server.coldfusion.rootdir & "/logs/" & arguments.logName & ".log">
	<cftry>
		<cfif NOT fileExists(path)>
			<cfreturn entries>
		</cfif>
		<cfset logFile = fileOpen(path, "read", "utf-8", true)>
		<cfif getFileInfo(path).size GT TAIL_BYTES>
			<cfset fileSeek(logFile, getFileInfo(path).size - TAIL_BYTES)>
			<!--- the first line read after seeking is partial --->
			<cfset fileReadLine(logFile)>
		</cfif>
		<cfloop condition="NOT fileIsEOF(logFile)">
			<cfset line = fileReadLine(logFile)>
			<!--- "Severity","ThreadID","Date","Time","Application","Message"; other lines continue a message --->
			<cfset parts = REFind('^"([^"]*)","[^"]*","(\d\d)/(\d\d)/(\d\d)","(\d\d):(\d\d):(\d\d)","[^"]*","(.*)$', line, 1, true)>
			<cfif parts.pos[1] GT 0>
				<cfset logged = createDateTime(2000 + mid(line, parts.pos[5], 2), mid(line, parts.pos[3], 2), mid(line, parts.pos[4], 2),
					mid(line, parts.pos[6], 2), mid(line, parts.pos[7], 2), mid(line, parts.pos[8], 2))>
				<cfif logged GE since AND (len(arguments.contains) EQ 0 OR findNoCase(arguments.contains, line) GT 0)>
					<cfset arrayAppend(entries, {
						severity = mid(line, parts.pos[2], parts.len[2]),
						logged = logged,
						message = REReplace(mid(line, parts.pos[9], parts.len[9]), '"$', '')
					})>
				</cfif>
			</cfif>
		</cfloop>
		<cfset fileClose(logFile)>
	<cfcatch>
		<cftry><cfset fileClose(logFile)><cfcatch></cfcatch></cftry>
	</cfcatch>
	</cftry>
	<cfreturn entries>
</cffunction>

<!---
	requireGlobalAdmin stop a widget method for anyone without the global_admin role.
--->
<cffunction name="requireGlobalAdmin" access="private" returntype="void" output="false">
	<cfif NOT ( isdefined("session.roles") AND listfindnocase(session.roles,"global_admin") ) >
		<cfthrow message="Not authorized">
	</cfif>
</cffunction>

<!---
	getErrorDetailHtml the Admin Panel's lookup of one error by the reference onError shows the user
	(yyyymmdd-xxxxxxxx), searching the whole MCZbase log and its rotated copies.

	@param error_reference the reference to look up.
	@return HTML describing the logged error, or saying it wasn't found.
--->
<cffunction name="getErrorDetailHtml" access="remote" returntype="string" returnformat="plain">
	<cfargument name="error_reference" type="string" required="yes">
	<cfset var html = "">
	<cfset var reference = ucase(trim(arguments.error_reference))>
	<cfset var logDirectory = server.coldfusion.rootdir & "/logs/">
	<cfset var logFiles = "">
	<cfset var logFile = "">
	<cfset var line = "">
	<cfset var found = "">
	<cfset var foundIn = "">
	<cfset var header = "">
	<cfset var detail = "">
	<cfset var jsonStart = 0>
	<cfset var key = "">
	<cfset requireGlobalAdmin()>
	<cfif NOT REFind("^[0-9]{8}-[0-9A-F]{8}$", reference)>
		<cfreturn '<p class="text-danger mb-0">An error reference looks like 20261009-1A2B3C4D.</p>'>
	</cfif>
	<cftry>
		<cfset logFiles = directoryList(logDirectory, false, "name", "MCZbase*.log", "name asc")>
		<cfloop array="#logFiles#" index="logFile">
			<cfif REFind("^MCZbase(\.[0-9]+)?\.log$", logFile)>
				<cfloop file="#logDirectory##logFile#" index="line">
					<cfif find("Error #reference# ", line) GT 0>
						<cfset found = line>
						<cfset foundIn = logFile>
						<cfbreak>
					</cfif>
				</cfloop>
			</cfif>
			<cfif len(found) GT 0><cfbreak></cfif>
		</cfloop>
	<cfcatch>
		<cfreturn '<p class="text-danger mb-0">The log could not be read: #encodeForHtml(cfcatch.message)#</p>'>
	</cfcatch>
	</cftry>
	<cfif len(found) EQ 0>
		<cfreturn '<p class="mb-0">#encodeForHtml(reference)# was not found in the MCZbase log; it may have been rotated out, or been logged on another server.</p>'>
	</cfif>
	<!--- the message is "Error ref on page at location for user [name] from address: {json}", in a quoted CSV field --->
	<cfset found = REReplace(found, '"$', '')>
	<cfset jsonStart = find(": {", found)>
	<cfif jsonStart GT 0>
		<cfset header = left(found, jsonStart - 1)>
		<cftry>
			<cfset detail = deserializeJSON(replace(mid(found, jsonStart + 2, len(found)), '""', '"', "all"))>
		<cfcatch>
			<cfset detail = "">
		</cfcatch>
		</cftry>
	<cfelse>
		<cfset header = found>
	</cfif>
	<cfsavecontent variable="html">
		<cfoutput>
			<p class="mb-1 small">From #encodeForHtml(foundIn)#:</p>
			<p class="mb-1 small text-break">#encodeForHtml(header)#</p>
			<cfif isStruct(detail)>
				<dl class="small mb-0">
					<cfloop collection="#detail#" item="key">
						<dt>#encodeForHtml(key)#</dt>
						<dd class="text-break"><cfif isSimpleValue(detail[key])>#encodeForHtml(detail[key])#<cfelse><pre class="mb-0">#encodeForHtml(serializeJSON(detail[key]))#</pre></cfif></dd>
					</cfloop>
				</dl>
			<cfelseif jsonStart GT 0>
				<pre class="small mb-0">#encodeForHtml(mid(found, jsonStart + 2, len(found)))#</pre>
			</cfif>
		</cfoutput>
	</cfsavecontent>
	<cfreturn html>
</cffunction>

<!---
	getServerChecksHtml the Admin Panel widget checking this server's configuration: protocol, root
	URL, role, checked out branch, ColdFusion version, reCAPTCHA, and the size of the download folders.

	@return HTML for the widget body.
--->
<cffunction name="getServerChecksHtml" access="remote" returntype="string" returnformat="plain">
	<cfset var html = "">
	<cfset var gitBranch = "unknown">
	<cfset var recaptcha = "">
	<cfset var folder = "">
	<cfset var folderFiles = "">
	<cfset var folderBytes = 0>
	<cfset requireGlobalAdmin()>
	<cfif NOT isDefined("recaptchaStatus")>
		<cfinclude template="/shared/component/captcha.cfc" runOnce="true">
	</cfif>
	<cfset recaptcha = recaptchaStatus()>
	<cftry>
		<cfset gitBranch = trim(fileRead("#Application.webDirectory#/.git/HEAD"))>
	<cfcatch></cfcatch>
	</cftry>
	<cfsavecontent variable="html">
		<cfoutput>
			<ul class="mb-2">
				<li>Protocol: #encodeForHtml(Application.protocol)#
					<cfif Application.protocol EQ "https"><span class="badge badge-success">OK</span><cfelse><span class="badge badge-danger">Not https</span></cfif>
					<cfif Application.serverrole EQ "production" AND Application.protocol NEQ "https">(restart ColdFusion while Apache is running)</cfif></li>
				<li>Server root URL: #encodeForHtml(Application.serverRootUrl)#</li>
				<li>Server role: #encodeForHtml(Application.serverrole)#</li>
				<li>Checked out: #encodeForHtml(gitBranch)#</li>
				<li>ColdFusion: #encodeForHtml(server.coldfusion.productversion)#</li>
				<li>reCAPTCHA:
					<cfif recaptcha.siteKeySet AND recaptcha.classLoaded AND recaptcha.validatorResponds><span class="badge badge-success">OK</span><cfelse><span class="badge badge-danger">Failing</span></cfif>
					<ul>
						<li>Site key (cf_global_settings.google_site_key): <cfif recaptcha.siteKeySet>set<cfelse><strong>not set</strong></cfif></li>
						<li>Validator class: <cfif recaptcha.classLoaded>loaded from #encodeForHtml(recaptcha.classLocation)#<cfelse><strong>not available</strong></cfif></li>
						<li>Check of a dummy answer: <cfif recaptcha.validatorResponds>completed<cfelse><strong>failed</strong></cfif></li>
						<cfif len(recaptcha.message) GT 0><li>#encodeForHtml(recaptcha.message)#</li></cfif>
						<cfif NOT (recaptcha.siteKeySet AND recaptcha.validatorResponds)>
							<li><strong>Visitors who aren't logged in can't submit the contact, bug report, bad data report or blocklist forms.</strong></li>
						</cfif>
					</ul>
				</li>
				<cfloop list="download,temp" index="folder">
					<cftry>
						<cfset folderFiles = directoryList("#Application.webDirectory#/#folder#", false, "query")>
						<cfset folderBytes = 0>
						<cfloop query="folderFiles"><cfset folderBytes = folderBytes + val(folderFiles.size)></cfloop>
						<li>/#folder#/: #folderFiles.recordcount# files, #numberFormat(folderBytes / 1048576, "0.0")# MB</li>
					<cfcatch>
						<li>/#folder#/: can't be read</li>
					</cfcatch>
					</cftry>
				</cfloop>
			</ul>
		</cfoutput>
	</cfsavecontent>
	<cfreturn html>
</cffunction>

<!---
	getScheduledTasksHtml the Admin Panel widget listing this server's ColdFusion scheduled tasks, with
	each task's latest scheduler log entry from the last week.

	@return HTML for the widget body.
--->
<cffunction name="getScheduledTasksHtml" access="remote" returntype="string" returnformat="plain">
	<cfset var html = "">
	<cfset var tasks = "">
	<cfset var taskList = arrayNew(1)>
	<cfset var task = "">
	<cfset var row = "">
	<cfset var column = "">
	<cfset var logEntries = "">
	<cfset var lastEntry = "">
	<cfset var entry = "">
	<cfset var listError = "">
	<cfset var taskName = "">
	<cfset requireGlobalAdmin()>
	<cftry>
		<cfschedule action="list" result="tasks">
		<!--- the result is a query or an array of structures, depending on the ColdFusion version --->
		<cfif isQuery(tasks)>
			<cfloop query="tasks">
				<cfset row = structNew()>
				<cfloop list="#tasks.columnList#" index="column">
					<cfset row[lcase(column)] = tasks[column][tasks.currentRow]>
				</cfloop>
				<cfset arrayAppend(taskList, row)>
			</cfloop>
		<cfelseif isArray(tasks)>
			<cfset taskList = tasks>
		</cfif>
	<cfcatch>
		<cfset listError = cfcatch.message>
	</cfcatch>
	</cftry>
	<cfset logEntries = recentLogEntries("scheduler", 24 * 7)>
	<cfsavecontent variable="html">
		<cfoutput>
			<cfif len(listError) GT 0>
				<cfif Application.serverrole EQ "production">
					<p class="text-danger">The scheduled tasks could not be listed: #encodeForHtml(listError)#</p>
				<cfelse>
					<p class="mb-2">The scheduled tasks could not be listed, as expected on a #encodeForHtml(Application.serverrole)# server: #encodeForHtml(listError)#</p>
				</cfif>
			<cfelse>
				<p class="mb-2">#arrayLen(taskList)# scheduled tasks on this server. The latest scheduler log entry for each is from the last week.</p>
				<table class="table table-sm table-striped table-responsive d-xl-table small mb-1">
					<thead class="thead-light">
						<tr><th scope="col">Task</th><th scope="col">URL</th><th scope="col">Interval</th><th scope="col">Status</th><th scope="col">Latest log entry</th></tr>
					</thead>
					<tbody>
						<cfloop array="#taskList#" index="task">
							<cfset taskName = "">
							<cfif structKeyExists(task, "task")><cfset taskName = task.task><cfelseif structKeyExists(task, "name")><cfset taskName = task.name></cfif>
							<cfset lastEntry = "">
							<cfloop array="#logEntries#" index="entry">
								<cfif len(taskName) GT 0 AND (findNoCase(".#taskName# ", entry.message & " ") GT 0 OR findNoCase(" #taskName# ", " " & entry.message & " ") GT 0)>
									<cfset lastEntry = entry>
								</cfif>
							</cfloop>
							<tr>
								<td>#encodeForHtml(taskName)#</td>
								<td class="text-break"><cfif structKeyExists(task, "url")>#encodeForHtml(task.url)#</cfif></td>
								<td><cfif structKeyExists(task, "interval")>#encodeForHtml(task.interval)#</cfif></td>
								<td><cfif structKeyExists(task, "status")>#encodeForHtml(task.status)#<cfelseif structKeyExists(task, "paused") AND task.paused>paused</cfif></td>
								<td>
									<cfif isStruct(lastEntry)>
										#dateTimeFormat(lastEntry.logged, "yyyy-mm-dd HH:nn")#:
										<cfif lastEntry.severity NEQ "Information"><span class="badge badge-danger">#encodeForHtml(lastEntry.severity)#</span></cfif>
										#encodeForHtml(left(lastEntry.message, 200))#
									<cfelse>
										none
									</cfif>
								</td>
							</tr>
						</cfloop>
					</tbody>
				</table>
			</cfif>
		</cfoutput>
	</cfsavecontent>
	<cfreturn html>
</cffunction>

<!---
	getRecentErrorsHtml the Admin Panel widget summarising the errors Application.cfc onError logged
	to the MCZbase log in the last day, by page.

	@return HTML for the widget body.
--->
<cffunction name="getRecentErrorsHtml" access="remote" returntype="string" returnformat="plain">
	<cfset var html = "">
	<cfset var errors = "">
	<cfset var byPage = structNew()>
	<cfset var entry = "">
	<cfset var page = "">
	<cfset var pageMatch = "">
	<cfset var i = 0>
	<cfset var SHOWN = 20>
	<cfset requireGlobalAdmin()>
	<cfset errors = recentLogEntries("MCZbase", 24, "Error ")>
	<cfloop array="#errors#" index="entry">
		<cfset pageMatch = REFind("on (/[^ ]*) ", entry.message, 1, true)>
		<cfset page = "unknown">
		<cfif pageMatch.pos[1] GT 0>
			<cfset page = mid(entry.message, pageMatch.pos[2], pageMatch.len[2])>
		</cfif>
		<cfif NOT structKeyExists(byPage, page)>
			<cfset byPage[page] = 0>
		</cfif>
		<cfset byPage[page] = byPage[page] + 1>
	</cfloop>
	<cfsavecontent variable="html">
		<cfoutput>
			<p class="mb-2">#arrayLen(errors)# errors logged in the last day.</p>
			<cfif arrayLen(errors) GT 0>
				<details class="mb-1">
					<summary><strong>By page</strong> (#structCount(byPage)#)</summary>
					<ul class="small mb-1">
						<cfloop collection="#byPage#" item="page">
							<li>#encodeForHtml(page)#: #byPage[page]#</li>
						</cfloop>
					</ul>
				</details>
				<details>
					<summary><strong>Latest</strong> (up to #SHOWN#)</summary>
					<ul class="small mb-1">
						<cfloop from="#arrayLen(errors)#" to="#max(1, arrayLen(errors) - SHOWN + 1)#" step="-1" index="i">
							<li>#dateTimeFormat(errors[i].logged, "HH:nn")# #encodeForHtml(left(errors[i].message, 300))#</li>
						</cfloop>
					</ul>
				</details>
			</cfif>
		</cfoutput>
	</cfsavecontent>
	<cfreturn html>
</cffunction>

<!---
	getMailHtml the Admin Panel widget summarising email sent in the last day (mailsent log, written
	when mail logging is on) and mail errors in the last week (mail log).

	@return HTML for the widget body.
--->
<cffunction name="getMailHtml" access="remote" returntype="string" returnformat="plain">
	<cfset var html = "">
	<cfset var sent = "">
	<cfset var failed = "">
	<cfset var i = 0>
	<cfset var SHOWN = 20>
	<cfset requireGlobalAdmin()>
	<cfset sent = recentLogEntries("mailsent", 24)>
	<cfset failed = recentLogEntries("mail", 24 * 7)>
	<cfsavecontent variable="html">
		<cfoutput>
			<ul class="mb-2">
				<li>Sent in the last day: #arrayLen(sent)# (recorded only when ColdFusion's mail logging is on).</li>
				<li>Mail errors in the last week: #arrayLen(failed)#
					<cfif arrayLen(failed) GT 0><span class="badge badge-danger">Errors</span></cfif></li>
			</ul>
			<cfif arrayLen(sent) GT 0>
				<details class="mb-1">
					<summary><strong>Latest sent</strong> (up to #SHOWN#)</summary>
					<ul class="small mb-1">
						<cfloop from="#arrayLen(sent)#" to="#max(1, arrayLen(sent) - SHOWN + 1)#" step="-1" index="i">
							<li>#dateTimeFormat(sent[i].logged, "HH:nn")# #encodeForHtml(left(sent[i].message, 300))#</li>
						</cfloop>
					</ul>
				</details>
			</cfif>
			<cfif arrayLen(failed) GT 0>
				<details>
					<summary><strong>Latest errors</strong> (up to #SHOWN#)</summary>
					<ul class="small mb-1">
						<cfloop from="#arrayLen(failed)#" to="#max(1, arrayLen(failed) - SHOWN + 1)#" step="-1" index="i">
							<li>#dateTimeFormat(failed[i].logged, "yyyy-mm-dd HH:nn")# #encodeForHtml(left(failed[i].message, 300))#</li>
						</cfloop>
					</ul>
				</details>
			</cfif>
		</cfoutput>
	</cfsavecontent>
	<cfreturn html>
</cffunction>

<!---
	getSecurityEventsHtml the Admin Panel widget summarising security events of the last week:
	blocklist additions, login lockouts and changes to form permissions and the role list.

	@return HTML for the widget body.
--->
<cffunction name="getSecurityEventsHtml" access="remote" returntype="string" returnformat="plain">
	<cfset var html = "">
	<cfset var blocked = "">
	<cfset var blocked_result = "">
	<cfset var lockouts = "">
	<cfset var permissionChanges = "">
	<cfset var permissionChanges_result = "">
	<cfset var i = 0>
	<cfset requireGlobalAdmin()>
	<cfquery name="blocked" datasource="uam_god" result="blocked_result">
		SELECT ip, listdate
		FROM blacklist
		WHERE listdate > sysdate - 7
		ORDER BY listdate DESC
	</cfquery>
	<cfset lockouts = recentLogEntries("MCZbase", 24 * 7, "loginThrottle: logins locked")>
	<cfquery name="permissionChanges" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="permissionChanges_result">
		SELECT object_name, db_user, timestamp AS changed_at, sql_text
		FROM mczbase.arctos_audit
		WHERE
			upper(object_name) IN ('CF_FORM_PERMISSIONS', 'CF_CTUSER_ROLES')
			AND timestamp > sysdate - 7
		ORDER BY timestamp DESC
	</cfquery>
	<cfsavecontent variable="html">
		<cfoutput>
			<ul class="mb-2">
				<li>Addresses blocklisted: #blocked.recordcount# (<a href="/Admin/blacklist.cfm">Manage Blocklist</a>)</li>
				<li>Login lockouts: #arrayLen(lockouts)#</li>
				<li>Audited changes to form permissions and the role list: #permissionChanges.recordcount#</li>
			</ul>
			<p class="small mb-2">All for the last 7 days. Role grants to accounts are Oracle DDL, which the audit trail does not record.</p>
			<cfif blocked.recordcount GT 0>
				<details class="mb-1">
					<summary><strong>Blocklisted</strong> (#blocked.recordcount#)</summary>
					<ul class="small mb-1">
						<cfloop query="blocked">
							<li>#dateFormat(blocked.listdate, "yyyy-mm-dd")# #encodeForHtml(blocked.ip)#</li>
						</cfloop>
					</ul>
				</details>
			</cfif>
			<cfif arrayLen(lockouts) GT 0>
				<details class="mb-1">
					<summary><strong>Lockouts</strong> (#arrayLen(lockouts)#)</summary>
					<ul class="small mb-1">
						<cfloop from="#arrayLen(lockouts)#" to="1" step="-1" index="i">
							<li>#dateTimeFormat(lockouts[i].logged, "yyyy-mm-dd HH:nn")# #encodeForHtml(replace(lockouts[i].message, "loginThrottle: ", ""))#</li>
						</cfloop>
					</ul>
				</details>
			</cfif>
			<cfif permissionChanges.recordcount GT 0>
				<details>
					<summary><strong>Permission and role list changes</strong> (#permissionChanges.recordcount#)</summary>
					<ul class="small mb-1">
						<cfloop query="permissionChanges">
							<li>#dateTimeFormat(permissionChanges.changed_at, "yyyy-mm-dd HH:nn")# #encodeForHtml(permissionChanges.db_user)#: <code>#encodeForHtml(left(permissionChanges.sql_text, 200))#</code></li>
						</cfloop>
					</ul>
				</details>
			</cfif>
		</cfoutput>
	</cfsavecontent>
	<cfreturn html>
</cffunction>

<!---
	getAccountsHtml the Admin Panel widget listing MCZbase users whose Oracle accounts are locked,
	expired, or have passwords expiring within two weeks.

	@return HTML for the widget body.
--->
<cffunction name="getAccountsHtml" access="remote" returntype="string" returnformat="plain">
	<cfset var html = "">
	<cfset var accounts = "">
	<cfset var accounts_result = "">
	<cfset requireGlobalAdmin()>
	<cfquery name="accounts" datasource="uam_god" result="accounts_result">
		SELECT cf_users.username, dba_users.account_status, dba_users.lock_date, dba_users.expiry_date
		FROM cf_users
			JOIN dba_users ON upper(cf_users.username) = dba_users.username
		WHERE
			dba_users.account_status <> 'OPEN'
			OR dba_users.expiry_date < sysdate + 14
		ORDER BY dba_users.account_status, cf_users.username
	</cfquery>
	<cfsavecontent variable="html">
		<cfoutput>
			<p class="mb-2">#accounts.recordcount# MCZbase users with an Oracle account that is locked, expired, or expiring within two weeks.</p>
			<cfif accounts.recordcount GT 0>
				<table class="table table-sm table-striped table-responsive d-xl-table small mb-1">
					<thead class="thead-light">
						<tr><th scope="col">Username</th><th scope="col">Status</th><th scope="col">Locked</th><th scope="col">Password expires</th></tr>
					</thead>
					<tbody>
						<cfloop query="accounts">
							<tr>
								<td><a href="/Admin/AdminUsers.cfm?action=edit&username=#encodeForUrl(accounts.username)#">#encodeForHtml(accounts.username)#</a></td>
								<td>#encodeForHtml(lcase(accounts.account_status))#</td>
								<td>#dateFormat(accounts.lock_date, "yyyy-mm-dd")#</td>
								<td>#dateFormat(accounts.expiry_date, "yyyy-mm-dd")#</td>
							</tr>
						</cfloop>
					</tbody>
				</table>
			</cfif>
		</cfoutput>
	</cfsavecontent>
	<cfreturn html>
</cffunction>

<!---
	getDataHealthHtml the Admin Panel widget summarising data waiting for attention: FLAT rows by
	stale flag and pending specimen relationships.

	@return HTML for the widget body.
--->
<cffunction name="getDataHealthHtml" access="remote" returntype="string" returnformat="plain">
	<cfset var html = "">
	<cfset var flatStatus = "">
	<cfset var flatStatus_result = "">
	<cfset var pending = "">
	<cfset var pending_result = "">
	<cfset requireGlobalAdmin()>
	<cfquery name="flatStatus" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="flatStatus_result">
		SELECT stale_flag, count(*) AS ct
		FROM flat
		GROUP BY stale_flag
		ORDER BY stale_flag
	</cfquery>
	<cfquery name="pending" datasource="uam_god" result="pending_result">
		SELECT count(*) AS ct
		FROM cf_temp_relations
		WHERE related_collection_object_id IS NULL
	</cfquery>
	<cfsavecontent variable="html">
		<cfoutput>
			<ul class="mb-2">
				<li>FLAT:
					<cfif flatStatus.recordcount EQ 1 AND flatStatus.stale_flag EQ 0><span class="badge badge-success">OK</span></cfif>
					<cfloop query="flatStatus">stale_flag #flatStatus.stale_flag#: #flatStatus.ct# rows<cfif flatStatus.stale_flag GT 1> (manually excluded)</cfif><cfif flatStatus.currentRow LT flatStatus.recordcount>; </cfif></cfloop></li>
				<li>Pending specimen relationships: #pending.ct#</li>
			</ul>
		</cfoutput>
	</cfsavecontent>
	<cfreturn html>
</cffunction>

<!---
	getJavaLibrariesHtml the Admin Panel widget checking that the Java classes MCZbase calls can be
	loaded, with the jar each library was loaded from and its version where the jar declares one.  Add
	a class here when new code calls one from a library added to the ColdFusion server.

	@return HTML for the widget body.
--->
<cffunction name="getJavaLibrariesHtml" access="remote" returntype="string" returnformat="plain">
	<cfset var html = "">
	<cfset var libraries = [
		{ name = "reCAPTCHA validator", usedBy = "contact, bug and bad data reports, blocklist form (shared/component/captcha.cfc)",
			classes = [ "edu.harvard.mcz.recaptchavalidate.RecaptchaValidate" ] },
		{ name = "eDec builder", usedBy = "USFWS eDec for loans (edecView.cfm)",
			classes = [ "edu.harvard.mcz.edec.mczbase.EDecBuilder" ] },
		{ name = "QR code utility", usedBy = "exhibit labels (Reports/handlers/exhibit.cfm)",
			classes = [ "edu.harvard.mcz.qrCodeUtility.QRCodeUtility" ] },
		{ name = "Name tools", usedBy = "taxonomy and name checks (dataquality/, taxonomy/component/functions.cfc)",
			classes = [ "edu.harvard.mcz.nametools.NameUsage", "edu.harvard.mcz.nametools.ICZNAuthorNameComparator" ] },
		{ name = "Scientific name QC", usedBy = "taxonomy and name checks (dataquality/, taxonomy/component/functions.cfc)",
			classes = [ "org.filteredpush.qc.sciname.DwCSciNameDQ", "org.filteredpush.qc.sciname.SciNameSourceAuthority", "org.filteredpush.qc.sciname.Taxon",
				"org.filteredpush.qc.sciname.services.Validator", "org.filteredpush.qc.sciname.services.WoRMSService",
				"org.filteredpush.qc.sciname.services.GBIFService", "org.filteredpush.qc.sciname.services.IRMNGService" ] },
		{ name = "Event date QC", usedBy = "date checks (dataquality/), collecting event and georeference bulkloaders",
			classes = [ "org.filteredpush.qc.date.DwCEventDQ", "org.filteredpush.qc.date.DwCEventDQDefaults", "org.filteredpush.qc.date.DwCOtherDateDQ",
				"org.filteredpush.qc.date.DwCOtherDateDQDefaults", "org.filteredpush.qc.date.EventResult", "org.filteredpush.qc.date.util.DateUtils" ] },
		{ name = "Event date QC, older package", usedBy = "date collected on the specimen page (specimens/component/public.cfc)",
			classes = [ "org.filteredpush.qc.date.DateUtils" ] },
		{ name = "Georeference QC", usedBy = "georeference checks (dataquality/)",
			classes = [ "org.filteredpush.qc.georeference.DwCGeoRefDQ" ] },
		{ name = "FFDQ annotations", usedBy = "data quality test descriptions (dataquality/)",
			classes = [ "org.datakurator.ffdq.annotations.Mechanism", "org.datakurator.ffdq.annotations.Provides",
				"org.datakurator.ffdq.annotations.Validation", "org.datakurator.ffdq.annotations.Amendment" ] },
		{ name = "Barbecue barcodes", usedBy = "barcode images (CustomTags/makeBarcode.cfm)",
			classes = [ "net.sourceforge.barbecue.Barcode", "net.sourceforge.barbecue.BarcodeImageHandler", "net.sourceforge.barbecue.linear.code39.Code39Barcode" ] },
		{ name = "Apache Commons CSV", usedBy = "CSV uploads to the bulkloaders (tools/component/csv.cfc)",
			classes = [ "org.apache.commons.csv.CSVFormat", "org.apache.commons.csv.CSVParser", "org.apache.commons.csv.CSVRecord" ] }
	]>
	<cfset var library = "">
	<cfset var className = "">
	<cfset var javaClass = "">
	<cfset var codeSource = "">
	<cfset var classPackage = "">
	<cfset var missing = "">
	<cfset var location = "">
	<cfset var version = "">
	<cfset var failingCount = 0>
	<cfset requireGlobalAdmin()>
	<cfloop array="#libraries#" index="library">
		<cfset missing = arrayNew(1)>
		<cfset location = "">
		<cfset version = "">
		<cfloop array="#library.classes#" index="className">
			<cftry>
				<cfset javaClass = createObject("java", className).getClass()>
				<cfif len(location) EQ 0>
					<cftry>
						<cfset codeSource = javaClass.getProtectionDomain().getCodeSource()>
						<cfif NOT isNull(codeSource)>
							<cfset location = codeSource.getLocation().toString()>
						</cfif>
						<cfset classPackage = javaClass.getPackage()>
						<cfif NOT isNull(classPackage) AND NOT isNull(classPackage.getImplementationVersion())>
							<cfset version = classPackage.getImplementationVersion()>
						</cfif>
					<cfcatch></cfcatch>
					</cftry>
				</cfif>
			<cfcatch>
				<cfset arrayAppend(missing, className)>
			</cfcatch>
			</cftry>
		</cfloop>
		<cfset library.missing = missing>
		<cfset library.location = location>
		<cfset library.version = version>
		<cfif arrayLen(missing) GT 0>
			<cfset failingCount = failingCount + 1>
		</cfif>
	</cfloop>
	<cfsavecontent variable="html">
		<cfoutput>
			<p class="mb-2">
				<cfif failingCount EQ 0><span class="badge badge-success">OK</span> All classes load.<cfelse><span class="badge badge-danger">#failingCount# failing</span> Pages using a failing library will not work.</cfif>
			</p>
			<ul class="mb-2">
				<cfloop array="#libraries#" index="library">
					<li>#encodeForHtml(library.name)#
						<cfif arrayLen(library.missing) EQ 0><span class="badge badge-success">OK</span><cfelseif arrayLen(library.missing) EQ arrayLen(library.classes)><span class="badge badge-danger">Not found</span><cfelse><span class="badge badge-danger">Incomplete</span></cfif>
						<cfif len(library.version) GT 0>version #encodeForHtml(library.version)#</cfif>
						<div class="small">Used by: #encodeForHtml(library.usedBy)#</div>
						<cfif len(library.location) GT 0><div class="small text-break">#encodeForHtml(library.location)#</div></cfif>
						<cfif arrayLen(library.missing) GT 0>
							<div class="small">Can't load: #encodeForHtml(arrayToList(library.missing, ", "))#</div>
						</cfif>
					</li>
				</cfloop>
			</ul>
		</cfoutput>
	</cfsavecontent>
	<cfreturn html>
</cffunction>

</cfcomponent>
