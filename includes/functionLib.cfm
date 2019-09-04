<!---  
functionLib.cfm 

This file is to hold only globaly reused coldfusion functions.

Copyright 2019 President and Fellows of Harvard College

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

  @author Paul J. Morris

--->

<!----------------------------------------------------------->

<cffunction name="setDbUser" output="true" returntype="boolean">
    <cfargument name="portal_id" type="string" required="false">
    <cfif not isdefined("portal_id") or len(portal_id) is 0 or not isnumeric(portal_id)>
        <cfset portal_id=0>
    </cfif>
    <cfif session.roles does not contain "coldfusion_user">
			<!--- User does not have access privileges to the data in flat, use filtered_flat.  --->
        <cfquery name="portalInfo" datasource="cf_dbuser">
            select * from cf_collection where cf_collection_id = #portal_id#
        </cfquery>
        <cfset session.dbuser=portalInfo.dbusername>
        <cfset session.epw = encrypt(portalInfo.dbpwd,cfid)>
        <cfset session.flatTableName = "filtered_flat">
    <cfelse>
			<!--- User has access privileges to the data in flat.  --->
        <cfset session.flatTableName = "flat">
    </cfif>
    <cfset session.portal_id=portal_id>
    <cfset session.collection_link_text =  Application.collection_link_text>
    <cfset session.stylesheet =  Application.stylesheet>
    <cfreturn true>
</cffunction>

<!----------------------------------------------------------->


<!---  function initSession to initialize a new login session.
	@param pwd a login password for username
	@param username the user to attempt to login wiht pwd
	@return true on successful login, otherwise false
---> 
<cffunction name="initSession" returntype = boolean output="true">
	<cfargument name="pwd" type="string" required="false">
	<cfargument name="username" type="string" required="false">
	<!--- Clear any current session and log any current session user out --->
	<cfset StructClear(Session)>
	<cflogout>
	<cfset session.roles="public">

	<cfif isdefined("username") and len(username) gt 0 and isdefined("pwd") and len(pwd) gt 0>
		<cfquery name="getPrefs" datasource="cf_dbuser">
			select * from cf_users where username = '#username#' and password='#hash(pwd)#'
		</cfquery>
		<cfif getPrefs.recordcount is 0>
			<cfset session.username = "">
			<cfset session.epw = "">
			<cflocation url="login.cfm?badPW=true&username=#username#">
		</cfif>
		<cfset session.username=username>
		<cfquery name="dbrole" datasource="uam_god">
			select upper(granted_role) role_name
			from dba_role_privs, cf_ctuser_roles
			where
			upper(dba_role_privs.granted_role) = upper(cf_ctuser_roles.role_name) and
			upper(grantee) = '#ucase(getPrefs.username)#'
		</cfquery>
		<cfset session.roles = valuelist(dbrole.role_name)>
		<cfset session.roles=listappend(session.roles,"public")>
		<cfset session.last_login = "#getPrefs.last_login#">

		<cfif len(getPrefs.CustomOtherIdentifier) gt 0>
			<cfset session.customOtherIdentifier = getPrefs.CustomOtherIdentifier>
		<cfelse>
			<cfset session.customOtherIdentifier = "">
		</cfif>

		<cfif listcontainsnocase(session.roles,"coldfusion_user")>
<!--- TODO: refactor setDbUser() so that  session.dbuser is set in one place, not two.  ---> 
			<cfset session.dbuser = "#getPrefs.username#">
			<cfset session.epw = encrypt(pwd,cfid)>
			<cftry>
				<cfquery name="ckUserName" datasource="uam_god">
					select agent_id from agent_name 
					where agent_name=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#"> 
							and agent_name_type='login'
				</cfquery>
			<cfcatch>
				<div class="error">Your Oracle login has issues. Contact a Database Administrator.</div>
				<cfabort>
			</cfcatch>
			</cftry>
			<cfif len(ckUserName.agent_id) is 0>
				<div class="error">You must have an agent_name of type login that matches your MCZbase username.</div>
				<cfabort>
			</cfif>
			<cfset session.myAgentId=ckUserName.agent_id>
			<cfset pwtime =  round(now() - getPrefs.pw_change_date)>
			<cfset pwage = Application.max_pw_age - pwtime>
			<cfif pwage lte 0>
				<cfset session.force_password_change = "yes">
				<cflocation url="ChangePassword.cfm">
			</cfif>
		</cfif>
	</cfif>

	<cfif isdefined("getPrefs.exclusive_collection_id") and len(getPrefs.exclusive_collection_id) gt 0>
		<cfset ecid=getPrefs.exclusive_collection_id>
		<cfset session.exclusive_collection_id=getPrefs.exclusive_collection_id>
	<cfelse>
		<cfset ecid="">
	</cfif>
	<cfset setDbUser(ecid)>

	<cfreturn false>
</cffunction>
