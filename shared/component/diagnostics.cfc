<!---
shared/component/diagnostics.cfc
Functions for describing a request in error pages, error emails and logs without exposing secrets.

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
<!--- session.epw holds each user's database password encrypted with their CFID, which is in every
	request's Cookie header, so a dump showing both gives away the password.  Diagnostics must never
	include the session scope, cookies, or password and token fields.  No method is remote. --->
<cfcomponent>

<!---
	isSensitiveKey test whether a scope key names a value that must not appear in diagnostics.

	@param keyName the key.
	@return true for passwords, tokens, session identifiers, cookies and authorization headers.
--->
<cffunction name="isSensitiveKey" access="public" returntype="boolean" output="false">
	<cfargument name="keyName" type="string" required="yes">
	<cfreturn REFindNoCase("(epw|pass|pwd|secret|token|cfid|cftoken|jsessionid|sessionid|cookie|authorization|csrf|key)", arguments.keyName) GT 0>
</cffunction>

<!---
	redactedScope copy a scope such as form, url or cgi for display, with sensitive values replaced.
	Nested structures are copied the same way; queries, arrays and objects are summarised, not shown.

	@param scope the scope or structure to copy.
	@param depth how many levels of nested structures to copy.
	@return a new structure safe to dump or log.
--->
<cffunction name="redactedScope" access="public" returntype="struct" output="false">
	<cfargument name="scope" type="any" required="yes">
	<cfargument name="depth" type="numeric" required="no" default="2">

	<cfset var result = structNew()>
	<cfset var keyName = "">
	<cfset var value = "">

	<cfif NOT isStruct(arguments.scope)>
		<cfreturn result>
	</cfif>
	<cfloop collection="#arguments.scope#" item="keyName">
		<cfif isSensitiveKey(keyName)>
			<cfset result[keyName] = "[redacted]">
		<cfelse>
			<cftry>
				<cfset value = arguments.scope[keyName]>
				<cfif isSimpleValue(value)>
					<cfset result[keyName] = redactedText(value)>
				<cfelseif isStruct(value) AND arguments.depth GT 1>
					<cfset result[keyName] = redactedScope(value, arguments.depth - 1)>
				<cfelseif isQuery(value)>
					<cfset result[keyName] = "[query, #value.recordcount# rows]">
				<cfelseif isArray(value)>
					<cfset result[keyName] = "[array, #arrayLen(value)# elements]">
				<cfelse>
					<cfset result[keyName] = "[not shown]">
				</cfif>
			<cfcatch>
				<cfset result[keyName] = "[not readable]">
			</cfcatch>
			</cftry>
		</cfif>
	</cfloop>
	<cfreturn result>
</cffunction>

<!---
	redactedText remove passwords from text that may contain them, such as the SQL of a failed
	ALTER USER or CREATE USER statement, or a query string.

	@param text the text.
	@return the text with password values replaced.
--->
<cffunction name="redactedText" access="public" returntype="string" output="false">
	<cfargument name="text" type="string" required="yes">

	<cfset var cleaned = arguments.text>
	<cfset cleaned = REReplaceNoCase(cleaned, "IDENTIFIED[[:space:]]+BY[[:space:]]+(""[^""]*""|[^[:space:]]+)", "IDENTIFIED BY [redacted]", "all")>
	<cfset cleaned = REReplaceNoCase(cleaned, "((pass|pwd|password|token|csrfToken|cfid|cftoken|jsessionid)[a-z_]*=)[^&[:space:]]*", "\1[redacted]", "all")>
	<cfreturn cleaned>
</cffunction>

<!---
	requestSummary the facts about the current request needed to follow up an error, without
	cookies, session data or form values.

	@return a structure of the time, page, method, query string, referrer, user agent, addresses
		and username.
--->
<cffunction name="requestSummary" access="public" returntype="struct" output="false">
	<cfset var summary = structNew()>
	<cfset summary["time"] = dateTimeFormat(now(), "yyyy-mm-dd HH:nn:ss")>
	<cfset summary["page"] = cgi.script_name>
	<cfset summary["method"] = cgi.request_method>
	<cfset summary["query string"] = redactedText(cgi.query_string)>
	<cfset summary["referrer"] = redactedText(cgi.http_referer)>
	<cfset summary["user agent"] = cgi.http_user_agent>
	<cfset summary["remote address"] = cgi.remote_addr>
	<cfset summary["forwarded for"] = cgi.http_x_forwarded_for>
	<cfset summary["username"] = "">
	<cfif isDefined("session.username")>
		<cfset summary["username"] = session.username>
	</cfif>
	<cfreturn summary>
</cffunction>

<!---
	exceptionSummary the parts of an exception needed to find its cause, with passwords removed
	from any SQL.

	@param exception the exception or cfcatch structure.
	@return a structure of the type, message, detail, SQL, location (the template and line where it
		happened, when known) and the templates and lines involved.
--->
<cffunction name="exceptionSummary" access="public" returntype="struct" output="false">
	<cfargument name="exception" type="any" required="yes">

	<cfset var summary = structNew()>
	<cfset var frames = "">
	<cfset var i = 0>
	<cfset var source = arguments.exception>
	<cfset var contextSource = "">
	<cfset var contextHolder = "">

	<!--- onError wraps the original exception in rootCause. --->
	<cfif isStruct(source) AND structKeyExists(source, "rootCause") AND isStruct(source.rootCause)>
		<cfset source = source.rootCause>
	</cfif>
	<cfloop list="type,message,detail,errorCode,nativeErrorCode,sqlState,queryError,sql,where" index="i">
		<cftry>
			<cfif structKeyExists(source, i) AND isSimpleValue(source[i]) AND len(source[i]) GT 0>
				<cfset summary[i] = redactedText(source[i])>
			</cfif>
		<cfcatch>
		</cfcatch>
		</cftry>
	</cfloop>
	<!--- The root cause may have no tag context, as when a remote method is called without a
		required argument, so take the first of the root cause, the exception and its cause that has one. --->
	<cfloop list="rootCause,self,cause" index="contextSource">
		<cftry>
			<cfset contextHolder = arguments.exception>
			<cfif contextSource NEQ "self">
				<cfset contextHolder = arguments.exception[contextSource]>
			</cfif>
			<cfif len(frames) EQ 0 AND isStruct(contextHolder) AND structKeyExists(contextHolder, "tagContext") AND isArray(contextHolder.tagContext)>
				<cfloop from="1" to="#min(arrayLen(contextHolder.tagContext), 10)#" index="i">
					<cfset frames = listAppend(frames, "#replace(contextHolder.tagContext[i].template, expandPath('/'), '/')#:#contextHolder.tagContext[i].line#", chr(10))>
				</cfloop>
			</cfif>
		<cfcatch>
		</cfcatch>
		</cftry>
	</cfloop>
	<cfif len(frames) GT 0>
		<cfset summary["location"] = listFirst(frames, chr(10))>
		<cfset summary["tagContext"] = frames>
	</cfif>
	<cfreturn summary>
</cffunction>

</cfcomponent>
