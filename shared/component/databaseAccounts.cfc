<!---
shared/component/databaseAccounts.cfc
Functions for code that changes Oracle database accounts with DDL.

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
<!--- Oracle DDL such as ALTER USER cannot take bind variables.  Statements built with these functions
	use only an account name the data dictionary returns, and a password checked here, each in double
	quotes, so no value from a request can end the quoted text.  No method is remote. --->
<cfcomponent>

<!---
	databaseAccountName find the Oracle account for an MCZbase username.

	@param username the MCZbase username.
	@return the account name as the data dictionary holds it, or an empty string when the username
		has no Oracle account.  Throws if the dictionary name is not a plain identifier, which
		accounts created by MCZbase administrators always are.
--->
<cffunction name="databaseAccountName" access="public" returntype="string" output="false">
	<cfargument name="username" type="string" required="yes">

	<cfset var getAccount = "">
	<cfset var getAccount_result = "">

	<cfquery name="getAccount" datasource="uam_god" result="getAccount_result">
		SELECT username
		FROM dba_users
		WHERE
			username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(arguments.username)#">
	</cfquery>
	<cfif getAccount.recordcount NEQ 1>
		<cfreturn "">
	</cfif>
	<cfif REFind("^[A-Z][A-Z0-9_$##]*$", getAccount.username) EQ 0 OR REFind("[\r\n]", getAccount.username) GT 0>
		<cfthrow message="The database account name has unexpected characters.">
	</cfif>
	<cfreturn getAccount.username>
</cffunction>

<!---
	databasePasswordProblem check that a password can be placed in quoted DDL.  Complexity rules
	are left to the account's Oracle profile, which ALTER USER and CREATE USER apply; see
	isPasswordComplexityError.

	@param password the proposed password.
	@return an empty string if the password is acceptable, otherwise a message for the user.
--->
<cffunction name="databasePasswordProblem" access="public" returntype="string" output="false">
	<cfargument name="password" type="string" required="yes">

	<cfif len(arguments.password) LT 8 OR len(arguments.password) GT 30>
		<cfreturn "Your password must be 8 to 30 characters long.">
	</cfif>
	<!--- Printable ASCII other than space and double quote. --->
	<cfif REFind("^[!##-~]+$", arguments.password) EQ 0 OR REFind("[\r\n]", arguments.password) GT 0>
		<cfreturn "Your password may contain letters, digits and punctuation, but not spaces, double quotes or accented characters.">
	</cfif>
	<cfreturn "">
</cffunction>

<!---
	isPasswordComplexityError test whether a caught database error is the account profile's
	password verify function rejecting a password.

	@param caught the cfcatch structure from ALTER USER or CREATE USER.
	@return true for ORA-28003, password verification failed.
--->
<cffunction name="isPasswordComplexityError" access="public" returntype="boolean" output="false">
	<cfargument name="caught" type="any" required="yes">

	<cfset var text = "">
	<cfif structKeyExists(arguments.caught, "message")>
		<cfset text = text & arguments.caught.message>
	</cfif>
	<cfif structKeyExists(arguments.caught, "detail")>
		<cfset text = text & " " & arguments.caught.detail>
	</cfif>
	<cfreturn findNoCase("ORA-28003", text) GT 0>
</cffunction>

</cfcomponent>
