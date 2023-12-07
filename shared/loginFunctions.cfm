<!--- shared/loginFunctions.cfm login and session initiation functions

Copyright 2008-2017 Contributors to Arctos
Copyright 2008-2022 President and Fellows of Harvard College

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
<!----------------------------------------------------------->
<cffunction name="setDbUser" output="true" returntype="boolean">
	<cfargument name="portal_id" type="string" required="false">
	<cfif not isdefined("portal_id") or len(portal_id) is 0 or not isnumeric(portal_id)>
		<cfset portal_id=0>
	</cfif>
	<!--- get the information for the portal --->
	<!---cfquery name="portalInfo" datasource="cf_dbuser">
		select * from cf_collection where cf_collection_id = #portal_id#
	</cfquery--->
	<cfif session.roles does not contain "coldfusion_user">
		<cfquery name="portalInfo" datasource="cf_dbuser">
			select * from cf_collection 
			where cf_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#portal_id#">
		</cfquery>
		<cfset session.dbuser=portalInfo.dbusername>
		<cfset session.epw = encrypt(portalInfo.dbpwd,cfid)>
		<cfset session.flatTableName = "filtered_flat">
	<cfelse>
		<cfset session.flatTableName = "flat">
	</cfif>
	<cfset session.portal_id=portal_id>
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
	<cfset session.showObservations="">
	<cfset session.result_sort="">
	<cfset session.username="">
	<cfset session.killrow="0">
	<cfset session.searchBy="">
	<cfset session.fancyCOID="">
	<cfset session.last_login="">
	<cfset session.customOtherIdentifier="">
	<cfset session.displayrows="20">
	<cfset session.loan_request_coll_id="">
	<cfset session.resultColumnList="">
	<cfset session.schParam = "">
	<cfset session.target=''>
	<cfset session.block_suggest=1>
	<cfset session.meta_description=''>
	<!--- cftoken may be a uuid, table names need to be limited to 30 characters --->
	<cfset rand = RandRange(0,9999)>
	<cfset lenTaken = len("MediaSrch#cfid#_#rand#_")>
	<cfset DBOBJECTNAME_MAX_LEN = 30>
	<cfset maxavailable = DBOBJECTNAME_MAX_LEN - lenTaken>
	<!--- prefered way of shortening a hash is to truncate on right, reencode cftoken from hex to base64 (reduces to 22 characters), then truncate that --->
	<!--- if cftoken is an integer, this will change it to a shorter alphanumeric string which likely wont be long enought to need to be truncated --->
	<cfset reencodedToken = binaryencode(binarydecode(replace(cftoken,"-","","All"),"Hex"),"Base64Url")>
	<!--- Base64Url is ^[A-Za-z0-9_-]+$, oracle table names are ^[A-Za-z0-9_#\$]+$, so replace - with # --->
	<cfset reencodedToken = replace(reencodedToken,"-","##","All")>
	<cfset temp=cfid & '_' & left(replace(reencodedToken,"-",""),maxavailable) & '_' & rand>
	<cfset session.reencodedToken = reencodedToken>
	<cfset session.SpecSrchTab="SpecSrch" & temp>
	<cfset session.MediaSrchTab="MediaSrch" & temp>
	<cfset session.TaxSrchTab="TaxSrch" & temp>
	<cfset session.exclusive_collection_id="">
	<cfset session.mczmediafail=0>
	<cfset session.specimens_default_action="fixedSearch">
	<cfset session.specimens_pin_guid="0">
	<cfset session.specimens_pagesize="25">
	<!--- determine which git branch is currently checked out --->
	<cftry>
		<!--- assuming a git repository and readable by coldfusion, determine the checked out branch by reading HEAD --->
		<cfset gitBranch = FileReadLine(FileOpen("#Application.webDirectory#/.git/HEAD", "read"))>
	<cfcatch>
		<cfset gitBranch = "unknown">
	</cfcatch>
	</cftry>
	<cfset Session.gitBranch = gitBranch>

	<!---------------------------- login ------------------------------------------------>
	<cfif isdefined("username") and len(username) gt 0 and isdefined("pwd") and len(pwd) gt 0>
		<cfquery name="checkUser" datasource="uam_god">
			SELECT count(*) as ct
			FROM cf_users 
				LEFT JOIN dba_users on upper(cf_users.username)=upper(dba_users.username)
			WHERE upper(cf_users.username) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(username)#">
				and (dba_users.username is null or 
                (
				        dba_users.default_tablespace = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#Application.allowed_tablespace#">
						  and ( dba_users.profile = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#Application.allowed_profile#"> or dba_users.user_id < 100 )
					 )
            )
		</cfquery>
		<cfif checkUser.ct NEQ 1>
			<cfset session.username = "">
			<cfset session.epw = "">
			<cflocation url="/login.cfm?badPW=true&username=#encodeForURL(username)#">
		</cfif>
		<cfquery name="getPrefs" datasource="cf_dbuser">
			select * 
			from cf_users 
			where 
				username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#username#"> 
				and password = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#hash(pwd)#">
		</cfquery>
		<cfif getPrefs.recordcount is 0>
			<cfset session.username = "">
			<cfset session.epw = "">
			<cflocation url="/login.cfm?badPW=true&username=#encodeForURL(username)#">
		</cfif>
		<cfset session.username=username>
		<cfquery name="dbrole" datasource="uam_god">
			select upper(granted_role) role_name
			from
				dba_role_privs,
				cf_ctuser_roles
			where
				upper(dba_role_privs.granted_role) = upper(cf_ctuser_roles.role_name) and
				upper(grantee) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(getPrefs.username)#">
		</cfquery>
		<cfset session.roles = valuelist(dbrole.role_name)>
		<cfset session.roles=listappend(session.roles,"public")>
		<cfset session.last_login = "#getPrefs.last_login#">
		<cfset session.displayrows = "#getPrefs.displayRows#">
		<cfset session.showObservations = "#getPrefs.showObservations#">
		<cfset session.resultcolumnlist = "#getPrefs.resultcolumnlist#">
		<cfset session.specimens_default_action = "#getPrefs.specimens_default_action#">
		<cfset session.specimens_pin_guid = "#getPrefs.specimens_pin_guid#">
		<cfset session.specimens_pagesize = "#getPrefs.specimens_pagesize#">
		<cfif len(getPrefs.fancyCOID) gt 0>
			<cfset session.fancyCOID = getPrefs.fancyCOID>
		<cfelse>
			<cfset session.fancyCOID = "">
		</cfif>
		<cfif len(getPrefs.block_suggest) gt 0>
			<!---cfset session.block_suggest = getPrefs.block_suggest--->
			<cfset session.block_suggest = 1>
		</cfif>
		<cfif len(getPrefs.result_sort) gt 0>
			<cfset session.result_sort = getPrefs.result_sort>
		<cfelse>
			<cfset session.result_sort = "">
		</cfif>
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
			update cf_users 
			set last_login = sysdate 
			where username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
		</cfquery>
		<cfif listcontainsnocase(session.roles,"coldfusion_user")>
			<cfset session.dbuser = "#getPrefs.username#">
			<cfset session.epw = encrypt(pwd,cfid)>
			<cftry>
				<cfquery name="ckUserName" datasource="uam_god">
					select agent_id 
					from agent_name 
					where agent_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						and agent_name_type = 'login'
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
			<cflocation url="/users/changePassword.cfm">
		</cfif>
		</cfif>
	</cfif>
	<cfif isdefined("getPrefs.exclusive_collection_id") and len(getPrefs.exclusive_collection_id) gt 0>
		<cfset ecid=getPrefs.exclusive_collection_id>
		<!---  TODO:  has exclusive_collection_id been renamed ecid?  --->
        <cfset session.exclusive_collection_id=getPrefs.exclusive_collection_id>
	<cfelse>
		<cfset ecid="">
	</cfif>
	<cfset setDbUser(ecid)>
	<!--- determine which git branch is currently checked out --->
	<cftry>
		<!--- assuming a git repository and readable by coldfusion, determine the checked out branch by reading HEAD --->
		<cfset gitBranch = FileReadLine(FileOpen("#Application.webDirectory#/.git/HEAD", "read"))>
	<cfcatch>
		<cfset gitBranch = "unknown">
	</cfcatch>
	</cftry>
	<cfset Session.gitBranch = gitBranch>
	</cfoutput>
	<cfreturn true>
</cffunction>

