<!---
shared/component/loginThrottle.cfc
A timed lock on logins after repeated failures, by username and by client address.

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
<!--- The login checks passwords against cf_users and never connects to Oracle with the password typed,
	so Oracle's failed-login limit never counts web login failures.  This limits guessing instead: too
	many failures for a username, or from a client address, within the window lock further logins
	for that username or address for a while, without checking the password.  Failures are counted
	for any username, existing or not, so the lock reveals nothing about which usernames exist.

	Counts and locks are kept in MCZBASE.CF_LOGIN_FAILURE, through uam_god (the table has no grants),
	so every instance behind a load balancer shares them, and a DBA can clear them with SQL when no
	administrator can log in.  The CF_LOGIN_FAILURE_CLEANUP job removes expired rows daily.  No method
	is remote. --->
<cfcomponent>

<!---
	loginThrottleSettings the limits.

	@return a structure: usernameLimit and addressLimit (failures that lock), windowMinutes (over
		which failures are counted), lockMinutes (how long a lock lasts).
--->
<cffunction name="loginThrottleSettings" access="public" returntype="struct" output="false">
	<cfreturn { usernameLimit = 10, addressLimit = 40, windowMinutes = 15, lockMinutes = 15 }>
</cffunction>

<!---
	loginLockStatus whether a login for a username from an address is locked.

	@param username the username typed; case doesn't matter.
	@param address the client address.
	@return a structure: locked (boolean), kind (username or address) and until (date) when locked.
--->
<cffunction name="loginLockStatus" access="public" returntype="struct" output="false">
	<cfargument name="username" type="string" required="yes">
	<cfargument name="address" type="string" required="yes">
	<cfset var result = { locked = false, kind = "", until = "" }>
	<cfset var getLock = "">
	<cfquery name="getLock" datasource="uam_god">
		SELECT lock_kind, locked_until
		FROM cf_login_failure
		WHERE
			locked_until > sysdate
			AND (
				(lock_kind = 'username' AND lock_key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#left(lcase(trim(arguments.username)), 255)#">)
				OR (lock_kind = 'address' AND lock_key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#left(arguments.address, 255)#">)
			)
		ORDER BY lock_kind DESC
	</cfquery>
	<cfif getLock.recordcount GT 0>
		<cfset result = { locked = true, kind = getLock.lock_kind, until = getLock.locked_until }>
	</cfif>
	<cfreturn result>
</cffunction>

<!---
	countFailure add a failure for one username or address, locking it when the limit is reached.
	One MERGE statement, so concurrent requests on different instances don't lose counts.

	@param kind username or address.
	@param key the lower case username or the address.
	@param limit the failures that lock.
	@return true if this failure locked the username or address.
--->
<cffunction name="countFailure" access="private" returntype="boolean" output="false">
	<cfargument name="kind" type="string" required="yes">
	<cfargument name="key" type="string" required="yes">
	<cfargument name="limit" type="numeric" required="yes">
	<cfset var settings = loginThrottleSettings()>
	<cfset var lockedBefore = "">
	<cfset var lockedAfter = "">
	<cfset var countIt = "">
	<cfset var attempt = 0>
	<cfquery name="lockedBefore" datasource="uam_god">
		SELECT count(*) AS ct
		FROM cf_login_failure
		WHERE lock_kind = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.kind#">
			AND lock_key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.key#">
			AND locked_until > sysdate
	</cfquery>
	<!--- a second try covers two instances inserting the same new key at once --->
	<cfloop from="1" to="2" index="attempt">
		<cftry>
			<cfquery name="countIt" datasource="uam_god">
				MERGE INTO cf_login_failure f
				USING (
					SELECT
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.kind#"> AS lock_kind,
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.key#"> AS lock_key
					FROM dual
				) s
				ON (f.lock_kind = s.lock_kind AND f.lock_key = s.lock_key)
				WHEN MATCHED THEN UPDATE SET
					f.failures = CASE
						WHEN f.window_start < sysdate - <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#settings.windowMinutes#"> / 1440 THEN 1
						ELSE f.failures + 1 END,
					f.window_start = CASE
						WHEN f.window_start < sysdate - <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#settings.windowMinutes#"> / 1440 THEN sysdate
						ELSE f.window_start END,
					f.locked_until = CASE
						WHEN f.locked_until > sysdate THEN f.locked_until
						WHEN f.window_start >= sysdate - <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#settings.windowMinutes#"> / 1440
							AND f.failures + 1 >= <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.limit#">
							THEN sysdate + <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#settings.lockMinutes#"> / 1440
						ELSE NULL END
				WHEN NOT MATCHED THEN INSERT (lock_kind, lock_key, failures, window_start, locked_until)
					VALUES (s.lock_kind, s.lock_key, 1, sysdate,
						CASE WHEN 1 >= <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.limit#">
							THEN sysdate + <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#settings.lockMinutes#"> / 1440
							ELSE NULL END)
			</cfquery>
			<cfbreak>
		<cfcatch>
			<cfif attempt EQ 2>
				<cflog file="MCZbase" text="loginThrottle: could not count a failed login for #arguments.kind# #arguments.key#: #cfcatch.message#">
			</cfif>
		</cfcatch>
		</cftry>
	</cfloop>
	<cfquery name="lockedAfter" datasource="uam_god">
		SELECT count(*) AS ct
		FROM cf_login_failure
		WHERE lock_kind = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.kind#">
			AND lock_key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.key#">
			AND locked_until > sysdate
	</cfquery>
	<cfreturn lockedBefore.ct EQ 0 AND lockedAfter.ct GT 0>
</cffunction>

<!---
	recordLoginFailure count a failed login, and lock the username or address when its limit is
	reached.  A new lock is logged, and emailed through the alert throttle where it is available.

	@param username the username typed.
	@param address the client address.
--->
<cffunction name="recordLoginFailure" access="public" returntype="void" output="false">
	<cfargument name="username" type="string" required="yes">
	<cfargument name="address" type="string" required="yes">
	<cfset var settings = loginThrottleSettings()>
	<cfset var key = left(lcase(trim(arguments.username)), 255)>
	<cfset var newLocks = "">
	<cfif len(key) GT 0 AND countFailure("username", key, settings.usernameLimit)>
		<cfset newLocks = listAppend(newLocks, "username #key#")>
	</cfif>
	<cfif len(arguments.address) GT 0 AND countFailure("address", left(arguments.address, 255), settings.addressLimit)>
		<cfset newLocks = listAppend(newLocks, "address #arguments.address#")>
	</cfif>
	<cfif len(newLocks) GT 0>
		<cflog file="MCZbase" text="loginThrottle: logins locked for #settings.lockMinutes# minutes after repeated failures: #newLocks# (last attempt username [#key#] from #arguments.address#)">
		<cfif isDefined("allowAlertMail") AND isDefined("Application.PageProblemEmail") AND allowAlertMail("loginLockout", arguments.address)>
			<cftry>
				<cfmail subject="Login lockout" to="#Application.PageProblemEmail#" from="security@#Application.fromEmail#" type="html">
					Logins locked for #settings.lockMinutes# minutes after repeated failed attempts:
					#encodeForHtml(newLocks)#.
					<br>Last attempt: username #encodeForHtml(key)# from #encodeForHtml(arguments.address)#.
					<br>Locked users and addresses can be seen and cleared from
					<a href="#Application.serverRootUrl#/Admin/AdminUsers.cfm?action=list&state=locked">the Locked Account search</a>,
					or by a DBA in MCZBASE.CF_LOGIN_FAILURE.
				</cfmail>
			<cfcatch>
				<cflog file="MCZbase" text="loginThrottle: lockout email failed: #cfcatch.message#">
			</cfcatch>
			</cftry>
		</cfif>
	</cfif>
</cffunction>

<!---
	recordLoginSuccess clear the failures for a username after a successful login.  The address's
	count is kept, so an attacker can't reset it by logging in to their own account.

	@param username the username.
--->
<cffunction name="recordLoginSuccess" access="public" returntype="void" output="false">
	<cfargument name="username" type="string" required="yes">
	<cfset clearLoginLock("username", arguments.username)>
</cffunction>

<!---
	clearLoginLock remove a username's or an address's failures and lock.

	@param kind username or address.
	@param key the username (any case) or address.
--->
<cffunction name="clearLoginLock" access="public" returntype="void" output="false">
	<cfargument name="kind" type="string" required="yes">
	<cfargument name="key" type="string" required="yes">
	<cfset var clearIt = "">
	<cfset var lockKey = trim(arguments.key)>
	<cfif arguments.kind EQ "username">
		<cfset lockKey = lcase(lockKey)>
	</cfif>
	<cfquery name="clearIt" datasource="uam_god">
		DELETE FROM cf_login_failure
		WHERE lock_kind = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.kind#">
			AND lock_key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#left(lockKey, 255)#">
	</cfquery>
</cffunction>

<!---
	usernameLoginLockedUntil whether logins for a username are locked now.

	@param username the username; case doesn't matter.
	@return the time the lock ends, or an empty string if not locked.
--->
<cffunction name="usernameLoginLockedUntil" access="public" returntype="string" output="false">
	<cfargument name="username" type="string" required="yes">
	<cfset var getLock = "">
	<cfquery name="getLock" datasource="uam_god">
		SELECT locked_until
		FROM cf_login_failure
		WHERE lock_kind = 'username'
			AND lock_key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#left(lcase(trim(arguments.username)), 255)#">
			AND locked_until > sysdate
	</cfquery>
	<cfreturn getLock.locked_until>
</cffunction>

<!---
	lockedLogins the usernames or addresses whose logins are locked now.

	@param kind username or address.
	@return a query with lock_key, failures and locked_until.
--->
<cffunction name="lockedLogins" access="public" returntype="query" output="false">
	<cfargument name="kind" type="string" required="yes">
	<cfset var getLocks = "">
	<cfquery name="getLocks" datasource="uam_god">
		SELECT lock_key, failures, locked_until
		FROM cf_login_failure
		WHERE lock_kind = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.kind#">
			AND locked_until > sysdate
		ORDER BY lock_key
	</cfquery>
	<cfreturn getLocks>
</cffunction>

</cfcomponent>
