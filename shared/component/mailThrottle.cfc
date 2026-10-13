<!---
shared/component/mailThrottle.cfc
Limits on alert emails that anonymous requests can trigger.

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
<!--- Error pages email the administrators on each probe, dead GUID, access violation or blocklist
	objection.  Blocking stops a single address after its first probe, but a bot spread over many
	addresses could still flood the mailbox, so each kind of alert is limited per address and in
	total per hour.  Counts are kept in the application scope and reset on restart.  No method is
	remote. --->
<cfcomponent>

<!---
	allowAlertMail decide whether an alert email may be sent, and count it if so.

	@param category the kind of alert, e.g. autoblacklist; each is limited separately.
	@param address the client address the alert is about.
	@param perHour the most emails of this category to send in an hour.
	@return true to send the email; false if this address has already caused one of this category in
		the current hour, or the category has reached its limit for the hour.  Suppressed emails are
		counted, and the count is logged when the hour ends.
--->
<cffunction name="allowAlertMail" access="public" returntype="boolean" output="false">
	<cfargument name="category" type="string" required="yes">
	<cfargument name="address" type="string" required="yes">
	<cfargument name="perHour" type="numeric" required="no" default="20">
	<cfset var state = "">
	<cfset var allowed = false>
	<cflock scope="Application" type="exclusive" timeout="5" throwontimeout="false">
		<cfif NOT structKeyExists(Application, "alertMailThrottle")>
			<cfset Application.alertMailThrottle = structNew()>
		</cfif>
		<cfif NOT structKeyExists(Application.alertMailThrottle, arguments.category)
				OR dateDiff("n", Application.alertMailThrottle[arguments.category].windowStart, now()) GE 60>
			<cfif structKeyExists(Application.alertMailThrottle, arguments.category)
					AND Application.alertMailThrottle[arguments.category].suppressed GT 0>
				<cflog file="MCZbase" text="mailThrottle: #Application.alertMailThrottle[arguments.category].suppressed# #arguments.category# alert emails suppressed in the hour from #dateTimeFormat(Application.alertMailThrottle[arguments.category].windowStart, 'yyyy-mm-dd HH:nn')#">
			</cfif>
			<cfset Application.alertMailThrottle[arguments.category] = { windowStart = now(), sent = 0, suppressed = 0, addresses = structNew() }>
		</cfif>
		<cfset state = Application.alertMailThrottle[arguments.category]>
		<cfif structKeyExists(state.addresses, arguments.address)>
			<cfset state.suppressed = state.suppressed + 1>
		<cfelseif state.sent GE arguments.perHour>
			<cfset state.suppressed = state.suppressed + 1>
			<cfif state.suppressed EQ 1>
				<cflog file="MCZbase" text="mailThrottle: #arguments.category# alert emails reached #arguments.perHour# this hour; further ones are suppressed until #dateTimeFormat(dateAdd('n', 60, state.windowStart), 'HH:nn')#">
			</cfif>
		<cfelse>
			<!--- addresses are only recorded while under the limit, so the structure stays small --->
			<cfset state.addresses[arguments.address] = true>
			<cfset state.sent = state.sent + 1>
			<cfset allowed = true>
		</cfif>
	</cflock>
	<cfreturn allowed>
</cffunction>

</cfcomponent>
