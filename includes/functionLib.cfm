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
<!------------------------------------------------------------------------------------->
<cffunction name="checkSql" access="public" output="true" returntype="boolean">
    <cfargument name="sql" required="true" type="string">
    <cfset nono="chr,char,update,insert,delete,drop,create,execute,exec,begin,declare,all_tables,session,cast(,sys,ascii,utl_,ctxsys,all_users">
    <cfset dels="';','|',">
    <cfset safe=0>
    <cfloop index="i" list="#sql#" delimiters=" .,?!;:%$&""'/|[]{}()#chr(10)##chr(13)##chr(9)#@">
	    <cfif ListFindNoCase(nono, i)>
	        <cfset safe=1>
	    </cfif>
    </cfloop>
    <cfif safe is 0>
        <cfreturn true>
    <cfelse>
		<cfinclude template="/errors/autoblacklist.cfm">
		<cfreturn false>
    </cfif>
</cffunction>
<!------------------------------------------------------------------------------------->			
<cffunction name="setDbUser" output="true" returntype="boolean">
	<cfargument name="portal_id" type="string" required="false">
	<cfif not isdefined("portal_id") or len(portal_id) is 0 or not isnumeric(portal_id)>
		<cfset portal_id=0>
	</cfif>
	<cfif session.roles does not contain "coldfusion_user">
		<cfquery name="portalInfo" datasource="cf_dbuser">
			select * from cf_collection where cf_collection_id = #portal_id#
		</cfquery>
		<cfset session.dbuser=portalInfo.dbusername>
		<cfset session.epw = encrypt(portalInfo.dbpwd,cfid)>
		<cfset session.flatTableName = "filtered_flat">
	<cfelse>
		<cfset session.flatTableName = "flat">
	</cfif>
	<cfset session.portal_id=portal_id>
	<!--- may need to get generic appearance --->
	<cfset session.header_color = Application.header_color>
	<cfset session.header_image =  Application.header_image>
	<cfset session.collection_url =  Application.collection_url>
	<cfset session.collection_link_text =  Application.collection_link_text>
	<cfset session.institution_url =  Application.institution_url>
	<cfset session.institution_link_text =  Application.institution_link_text>
	<cfset session.meta_description =  Application.meta_description>
	<cfset session.meta_keywords =  Application.meta_keywords>
	<cfset session.stylesheet =  Application.stylesheet>
	<cfset session.header_credit = "">
	<cfreturn true>
</cffunction>
<!----------------------------------------------------------->
<cffunction name="initSession" output="true" returntype="boolean">
	<cfargument name="username" type="string" required="false">
	<cfargument name="pwd" type="string" required="false">
	<cfoutput>
	<!------------------------ logout ------------------------------------>
	<cfset StructClear(Session)>
	<cflogout>
	<cfset session.DownloadFileName = "MCZbaseData_#cfid##cftoken#.txt">
	<cfset session.DownloadFileID = "#cfid##cftoken#">
	<cfset session.roles="public">
	<cfset session.username="">
	<cfset session.killrow="0">
	<cfset session.searchBy="">
	<cfset session.fancyCOID="">
	<cfset session.last_login="">
	<cfset session.customOtherIdentifier="">
	<cfset session.loan_request_coll_id="">
	<cfset session.target=''>
	<cfset session.block_suggest=1>
	<cfset session.meta_description=''>
	<cfset temp=cfid & '_' & cftoken & '_' & RandRange(0, 9999)>

	<cfif isdefined("username") and len(username) gt 0 and isdefined("pwd") and len(pwd) gt 0>
		<cfquery name="getPrefs" datasource="cf_dbuser">
			select * from cf_users where username = '#username#' and password='#hash(pwd)#'
		</cfquery>
		<cfif getPrefs.recordcount is 0>
			<cfset session.username = "">
			<cfset session.epw = "">
       		<cflocation url="/login.cfm?action=nothing&badPW=true&username=#username#">
		</cfif>
		<cfset session.username=username>
		<cfquery name="dbrole" datasource="uam_god">
			 select upper(granted_role) role_name
	         	from
	         dba_role_privs,
	         cf_ctuser_roles
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
	
		<cfif getPrefs.bigsearchbox is 1>
			<cfset session.searchBy="bigsearchbox">
		<cfelse>
			<cfset session.searchBy="">
		</cfif>
		<cfif getPrefs.killRow is 1>
			<cfset session.killRow=1>
		<cfelse>
			<cfset session.killRow=0>
		</cfif>
		<cfset session.locSrchPrefs=getPrefs.locSrchPrefs>
		<cfquery name="logLog" datasource="cf_dbuser">
			update cf_users set last_login = sysdate where username = '#session.username#'
		</cfquery>
		<cfif listcontainsnocase(session.roles,"coldfusion_user")>
			<cfset session.dbuser = "#getPrefs.username#">
			<cfset session.epw = encrypt(pwd,cfid)>
			<cftry>
				<cfquery name="ckUserName" datasource="uam_god">
					select agent_id from agent_name where agent_name='#session.username#' and
					agent_name_type='login'
				</cfquery>
				<cfcatch>
					<div class="error">
						Your Oracle login has issues. Contact a DBA.
					</div>
					<cfabort>
				</cfcatch>
			</cftry>
			<cfif len(ckUserName.agent_id) is 0>
				<div class="error">
					You must have an agent_name of type login that matches your Arctos username.
				</div>
				<cfabort>
			</cfif>
			<cfset session.myAgentId=ckUserName.agent_id>
		<cfset pwtime =  round(now() - getPrefs.pw_change_date)>
		<cfset pwage = Application.max_pw_age - pwtime>
		<cfif pwage lte 0>
			<cfset session.force_password_change = "yes">
			<cflocation url="/changePassword.cfm">
		</cfif>
		</cfif>
	</cfif>

	<cfset setDbUser()>
	</cfoutput>
	<cfreturn true>
</cffunction>


