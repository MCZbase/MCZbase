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
	usernameProblem check a username proposed at registration: either a plain Oracle identifier, or
	an email address.  A user with an email address as their username must be renamed before they
	can be given a database account (see newDatabaseAccountName).

	@param username the proposed username.
	@param currentUsername when renaming a user, their current username, so that their own row is
		not counted as a clash.
	@return an empty string if the username can be used, otherwise a message for the user.
--->
<cffunction name="usernameProblem" access="public" returntype="string" output="false">
	<cfargument name="username" type="string" required="yes">
	<cfargument name="currentUsername" type="string" required="no" default="">

	<cfset var checkUsed = "">
	<cfset var checkUsed_result = "">

	<cfset var isIdentifier = REFind("^[A-Za-z][A-Za-z0-9_]*$", arguments.username) GT 0>
	<!--- Email addresses are limited to characters that are safe in file names, URLs and HTML. --->
	<cfset var isEmail = isValid("email", arguments.username) AND REFind("^[A-Za-z0-9._@+-]+$", arguments.username) GT 0>

	<cfif len(arguments.username) GT 30>
		<cfreturn "A username must be at most 30 characters long.">
	</cfif>
	<cfif NOT isIdentifier AND NOT isEmail>
		<cfreturn "A username must be an email address, or start with a letter and contain only letters, digits and underscores.">
	</cfif>
	<!--- Database accounts ignore case, so names differing only in case would share one. --->
	<cfquery name="checkUsed" datasource="uam_god" result="checkUsed_result">
		SELECT
			(SELECT count(*) FROM cf_users
				WHERE upper(username) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(arguments.username)#">
					<cfif len(arguments.currentUsername) GT 0>
						AND username <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.currentUsername#">
					</cfif>
			)
			+ (SELECT count(*) FROM dba_users WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(arguments.username)#">)
			+ (SELECT count(*) FROM dba_roles WHERE role = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(arguments.username)#">)
			AS ct
		FROM dual
	</cfquery>
	<cfif checkUsed.ct GT 0>
		<cfreturn "That username is already in use.">
	</cfif>
	<cfreturn "">
</cffunction>

<!---
	newDatabaseAccountName the name to give a new Oracle account for an MCZbase username.

	@param username the MCZbase username.
	@return the account name, in upper case, or an empty string when the username is not a plain
		identifier or the name is already an account or a role.
--->
<cffunction name="newDatabaseAccountName" access="public" returntype="string" output="false">
	<cfargument name="username" type="string" required="yes">

	<cfset var checkUsed = "">
	<cfset var checkUsed_result = "">
	<cfset var accountName = ucase(arguments.username)>

	<cfif REFind("^[A-Z][A-Z0-9_]{0,29}$", accountName) EQ 0>
		<cfreturn "">
	</cfif>
	<cfquery name="checkUsed" datasource="uam_god" result="checkUsed_result">
		SELECT
			(SELECT count(*) FROM dba_users WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#accountName#">)
			+ (SELECT count(*) FROM dba_roles WHERE role = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#accountName#">)
			AS ct
		FROM dual
	</cfquery>
	<cfif checkUsed.ct GT 0>
		<cfreturn "">
	</cfif>
	<cfreturn accountName>
</cffunction>

<!---
	passwordRuleProblem check a password against the rules of the database's password verify
	function (SYS.VERIFY_FUNCTION_MCZ), as orapwCheck in /shared/js/login_scripts.js does in the
	browser, and that it can be placed in quoted DDL.

	@param username the username, which the password may not contain.
	@param password the proposed password.
	@return an empty string if the password is acceptable, otherwise a message for the user.
--->
<cffunction name="passwordRuleProblem" access="public" returntype="string" output="false">
	<cfargument name="username" type="string" required="yes">
	<cfargument name="password" type="string" required="yes">

	<cfset var problem = databasePasswordProblem(arguments.password)>
	<cfif len(problem) GT 0>
		<cfreturn problem>
	</cfif>
	<cfif len(arguments.username) GT 0 AND findNoCase(arguments.username, arguments.password) GT 0>
		<cfreturn "Your password may not contain your username.">
	</cfif>
	<cfif REFind("[A-Za-z]", arguments.password) EQ 0 OR REFind("[0-9]", arguments.password) EQ 0>
		<cfreturn "Your password must contain at least one letter and one number.">
	</cfif>
	<!--- The punctuation the verify function counts, less the double quote. --->
	<cfif REFind("[!##$%&()`*+,/:;<=>?_-]", arguments.password) EQ 0>
		<cfreturn "Your password must contain at least one of: ! ## $ % & ( ) ` * + , - / : ; < = > ? _">
	</cfif>
	<cfreturn "">
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
