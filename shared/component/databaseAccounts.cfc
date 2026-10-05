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
	databaseRoleName find a role MCZbase administrators may grant: an application role in
	cf_ctuser_roles or a collection role named by cf_collection.portal_name, that exists in the
	database.  Other roles, such as DBA, are never returned.

	@param roleName the requested role.
	@return the role name as the data dictionary holds it, or an empty string.  Throws if the
		dictionary name is not a plain identifier.
--->
<cffunction name="databaseRoleName" access="public" returntype="string" output="false">
	<cfargument name="roleName" type="string" required="yes">

	<cfset var getRole = "">
	<cfset var getRole_result = "">

	<cfquery name="getRole" datasource="uam_god" result="getRole_result">
		SELECT role
		FROM dba_roles
		WHERE
			role = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(arguments.roleName)#">
			AND (
				role IN (SELECT upper(role_name) FROM cf_ctuser_roles)
				OR role IN (SELECT upper(portal_name) FROM cf_collection WHERE portal_name IS NOT NULL)
			)
	</cfquery>
	<cfif getRole.recordcount NEQ 1>
		<cfreturn "">
	</cfif>
	<cfif REFind("^[A-Z][A-Z0-9_$##]*$", getRole.role) EQ 0 OR REFind("[\r\n]", getRole.role) GT 0>
		<cfthrow message="The database role name has unexpected characters.">
	</cfif>
	<cfreturn getRole.role>
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
	databasePasswordCheck check a new password for an Oracle account with the database function
	MCZBASE.CHECK_DATABASE_PASSWORD, which takes both values as bind variables.  It checks the
	account name and that the account exists, and the password's length and characters.

	@param username the account name.
	@param newPassword the proposed password.
	@param oldPassword the current password, if known.
	@return an empty string if the database accepts the password, otherwise its message.
--->
<cffunction name="databasePasswordCheck" access="public" returntype="string" output="false">
	<cfargument name="username" type="string" required="yes">
	<cfargument name="newPassword" type="string" required="yes">
	<cfargument name="oldPassword" type="string" required="no" default="">

	<cfset var checkPassword = "">
	<cfset var checkPassword_result = "">

	<cfquery name="checkPassword" datasource="uam_god" result="checkPassword_result">
		SELECT mczbase.check_database_password(
			<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.username#">,
			<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.newPassword#">,
			<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.oldPassword#" null="#len(arguments.oldPassword) EQ 0#">
		) AS result
		FROM dual
	</cfquery>
	<cfif checkPassword.result EQ "OK">
		<cfreturn "">
	</cfif>
	<cfreturn checkPassword.result>
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
