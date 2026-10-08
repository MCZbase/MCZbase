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
	for any username, existing or not, so the lock reveals nothing about which usernames exist.  The
	counts are held in the application scope, so a restart clears them.  No method is remote. --->
<cfcomponent>

<!---
	loginThrottleSettings the limits.

	@return a structure: usernameLimit and addressLimit (failures that lock), windowMinutes (over
		which failures are counted), lockMinutes (how long a lock lasts), maxEntries (most keys kept
		of each kind).
--->
<cffunction name="loginThrottleSettings" access="public" returntype="struct" output="false">
	<cfreturn { usernameLimit = 10, addressLimit = 40, windowMinutes = 15, lockMinutes = 15, maxEntries = 10000 }>
</cffunction>

<!---
	loginThrottleStore the counts, created if needed.  Call only inside a lock named loginThrottle.

	@return a structure with usernames and addresses, each a structure of keys to entries holding
		failures, windowStart and lockedUntil.
--->
<cffunction name="loginThrottleStore" access="private" returntype="struct" output="false">
	<cfif NOT structKeyExists(Application, "loginThrottle")>
		<cfset Application.loginThrottle = { usernames = structNew(), addresses = structNew() }>
	</cfif>
	<cfreturn Application.loginThrottle>
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
	<cfset var store = "">
	<cfset var key = lcase(trim(arguments.username))>
	<cflock name="loginThrottle" type="readonly" timeout="5" throwontimeout="false">
		<cfset store = loginThrottleStore()>
		<cfif structKeyExists(store.usernames, key) AND isDate(store.usernames[key].lockedUntil) AND store.usernames[key].lockedUntil GT now()>
			<cfset result = { locked = true, kind = "username", until = store.usernames[key].lockedUntil }>
		<cfelseif structKeyExists(store.addresses, arguments.address) AND isDate(store.addresses[arguments.address].lockedUntil) AND store.addresses[arguments.address].lockedUntil GT now()>
			<cfset result = { locked = true, kind = "address", until = store.addresses[arguments.address].lockedUntil }>
		</cfif>
	</cflock>
	<cfreturn result>
</cffunction>

<!---
	countFailure add a failure to one entry, locking it when the limit is reached.  Call only inside
	a lock named loginThrottle.

	@param entries the usernames or addresses structure.
	@param key the username or address.
	@param limit the failures that lock.
	@return true if this failure locked the entry.
--->
<cffunction name="countFailure" access="private" returntype="boolean" output="false">
	<cfargument name="entries" type="struct" required="yes">
	<cfargument name="key" type="string" required="yes">
	<cfargument name="limit" type="numeric" required="yes">
	<cfset var settings = loginThrottleSettings()>
	<cfset var entry = "">
	<cfset var oldestKey = "">
	<cfset var entryKey = "">
	<cfif NOT structKeyExists(arguments.entries, arguments.key)
			OR dateDiff("n", arguments.entries[arguments.key].windowStart, now()) GE settings.windowMinutes>
		<cfif structKeyExists(arguments.entries, arguments.key) AND isDate(arguments.entries[arguments.key].lockedUntil) AND arguments.entries[arguments.key].lockedUntil GT now()>
			<!--- still locked: keep the lock, start a new count --->
			<cfset arguments.entries[arguments.key].windowStart = now()>
			<cfset arguments.entries[arguments.key].failures = 0>
		<cfelse>
			<cfif structCount(arguments.entries) GE settings.maxEntries>
				<!--- keep memory bounded when many usernames or addresses are tried: drop the oldest --->
				<cfloop collection="#arguments.entries#" item="entryKey">
					<cfif len(oldestKey) EQ 0 OR arguments.entries[entryKey].windowStart LT arguments.entries[oldestKey].windowStart>
						<cfset oldestKey = entryKey>
					</cfif>
				</cfloop>
				<cfset structDelete(arguments.entries, oldestKey)>
			</cfif>
			<cfset arguments.entries[arguments.key] = { failures = 0, windowStart = now(), lockedUntil = "" }>
		</cfif>
	</cfif>
	<cfset entry = arguments.entries[arguments.key]>
	<cfset entry.failures = entry.failures + 1>
	<cfif entry.failures GE arguments.limit AND NOT (isDate(entry.lockedUntil) AND entry.lockedUntil GT now())>
		<cfset entry.lockedUntil = dateAdd("n", settings.lockMinutes, now())>
		<cfreturn true>
	</cfif>
	<cfreturn false>
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
	<cfset var store = "">
	<cfset var key = lcase(trim(arguments.username))>
	<cfset var newLocks = "">
	<cflock name="loginThrottle" type="exclusive" timeout="5" throwontimeout="false">
		<cfset store = loginThrottleStore()>
		<cfif len(key) GT 0 AND countFailure(store.usernames, key, settings.usernameLimit)>
			<cfset newLocks = listAppend(newLocks, "username #key#")>
		</cfif>
		<cfif len(arguments.address) GT 0 AND countFailure(store.addresses, arguments.address, settings.addressLimit)>
			<cfset newLocks = listAppend(newLocks, "address #arguments.address#")>
		</cfif>
	</cflock>
	<cfif len(newLocks) GT 0>
		<cflog file="MCZbase" text="loginThrottle: logins locked for #settings.lockMinutes# minutes after repeated failures: #newLocks# (last attempt username [#key#] from #arguments.address#)">
		<cfif isDefined("allowAlertMail") AND isDefined("Application.PageProblemEmail") AND allowAlertMail("loginLockout", arguments.address)>
			<cftry>
				<cfmail subject="Login lockout" to="#Application.PageProblemEmail#" from="security@#Application.fromEmail#" type="html">
					Logins locked for #settings.lockMinutes# minutes after repeated failed attempts:
					#encodeForHtml(newLocks)#.
					<br>Last attempt: username #encodeForHtml(key)# from #encodeForHtml(arguments.address)#.
					<br>Current locks can be seen and cleared on <a href="#Application.serverRootUrl#/Admin/AdminUsers.cfm?action=loginLocks">Login Locks</a>.
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
	<cflock name="loginThrottle" type="exclusive" timeout="5" throwontimeout="false">
		<cfset structDelete(loginThrottleStore().usernames, lcase(trim(arguments.username)))>
	</cflock>
</cffunction>

<!---
	clearLoginLock remove a username's or an address's failures and lock.

	@param kind username or address.
	@param key the username or address.
--->
<cffunction name="clearLoginLock" access="public" returntype="void" output="false">
	<cfargument name="kind" type="string" required="yes">
	<cfargument name="key" type="string" required="yes">
	<cflock name="loginThrottle" type="exclusive" timeout="5" throwontimeout="false">
		<cfif arguments.kind EQ "username">
			<cfset structDelete(loginThrottleStore().usernames, lcase(trim(arguments.key)))>
		<cfelseif arguments.kind EQ "address">
			<cfset structDelete(loginThrottleStore().addresses, trim(arguments.key))>
		</cfif>
	</cflock>
</cffunction>

<!---
	usernameLoginLockedUntil whether logins for a username are locked now.

	@param username the username; case doesn't matter.
	@return the time the lock ends, or an empty string if not locked.
--->
<cffunction name="usernameLoginLockedUntil" access="public" returntype="string" output="false">
	<cfargument name="username" type="string" required="yes">
	<cfset var result = "">
	<cfset var key = lcase(trim(arguments.username))>
	<cflock name="loginThrottle" type="readonly" timeout="5" throwontimeout="false">
		<cfif structKeyExists(loginThrottleStore().usernames, key)
				AND isDate(Application.loginThrottle.usernames[key].lockedUntil)
				AND Application.loginThrottle.usernames[key].lockedUntil GT now()>
			<cfset result = Application.loginThrottle.usernames[key].lockedUntil>
		</cfif>
	</cflock>
	<cfreturn result>
</cffunction>

<!---
	loginLocks the usernames and addresses whose logins are locked now, and the usernames with
	recent failures.

	@return a query with kind (username or address), lock_key, failures, window_start and
		locked_until (empty when not locked), locked first.
--->
<cffunction name="loginLocks" access="public" returntype="query" output="false">
	<cfset var result = queryNew("kind,lock_key,failures,window_start,locked_until,is_locked", "varchar,varchar,integer,timestamp,varchar,integer")>
	<cfset var store = "">
	<cfset var kind = "">
	<cfset var entryKey = "">
	<cfset var entry = "">
	<cfset var settings = loginThrottleSettings()>
	<cfset var isLocked = 0>
	<cfset var pass = 0>
	<cflock name="loginThrottle" type="readonly" timeout="5" throwontimeout="false">
		<cfset store = loginThrottleStore()>
		<!--- locked entries in the first pass, recent failures in the second, so locks are listed first --->
		<cfloop from="1" to="2" index="pass">
			<cfloop list="usernames,addresses" index="kind">
				<cfloop collection="#store[kind]#" item="entryKey">
					<cfset entry = store[kind][entryKey]>
					<cfset isLocked = isDate(entry.lockedUntil) AND entry.lockedUntil GT now()>
					<cfif (pass EQ 1 AND isLocked) OR (pass EQ 2 AND NOT isLocked AND dateDiff("n", entry.windowStart, now()) LT settings.windowMinutes)>
						<cfset queryAddRow(result)>
						<cfset querySetCell(result, "kind", left(kind, len(kind) - 1))>
						<cfset querySetCell(result, "lock_key", entryKey)>
						<cfset querySetCell(result, "failures", entry.failures)>
						<cfset querySetCell(result, "window_start", entry.windowStart)>
						<cfif isLocked>
							<cfset querySetCell(result, "locked_until", dateTimeFormat(entry.lockedUntil, "yyyy-mm-dd HH:nn"))>
							<cfset querySetCell(result, "is_locked", 1)>
						<cfelse>
							<cfset querySetCell(result, "is_locked", 0)>
						</cfif>
					</cfif>
				</cfloop>
			</cfloop>
		</cfloop>
	</cflock>
	<cfreturn result>
</cffunction>

</cfcomponent>
