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
	<cfset session.header_color = Application.header_color>
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
	<cfset session.last_login="">
	<cfset session.loan_request_coll_id="">
	<cfset session.collection_link_text="">
	<cfset session.target=''>
	<cfset session.meta_description=''>
	<cfset temp=cfid & '_' & cftoken & '_' & RandRange(0, 9999)>
	<!--- determine which git branch is currently checked out --->
	<cftry>
		<!--- assuming a git repository and readable by coldfusion, determine the checked out branch by reading HEAD --->
		<cfset gitBranch = FileReadLine(FileOpen("#Application.webDirectory#/.git/HEAD", "read"))>
	<cfcatch>
		<cfset gitBranch = "unknown">
	</cfcatch>
	</cftry>
	<cfset Session.gitBranch = gitBranch>

	<cfif isdefined("username") and len(username) gt 0 and isdefined("pwd") and len(pwd) gt 0>
		
		<cfquery name="getPrefs" datasource="cf_dbuser">
			select * 
			from cf_users 
			where 
				username = <cfqueryparam value='#username#' cfsqltype="CF_SQL_VARCHAR">
				AND password = <cfqueryparam value='#hash(pwd)#' cfsqltype="CF_SQL_VARCHAR">
		</cfquery>
		<cfif getPrefs.recordcount is 0>
			<cfset session.username = "">
			<cfset session.epw = "">
       		<cflocation url="/login.cfm?action=nothing">
		</cfif>
		<cfset session.username=username>
		<cfquery name="dbrole" datasource="uam_god">
			 select 
				upper(granted_role) role_name
	       from
				dba_role_privs,
				cf_ctuser_roles
			where
				upper(dba_role_privs.granted_role) = upper(cf_ctuser_roles.role_name) 
				AND upper(grantee) = <cfqueryparam value='#ucase(getPrefs.username)#' cfsqltype="CF_SQL_VARCHAR" >
		</cfquery>
		<cfset session.roles = valuelist(dbrole.role_name)>
		<cfset session.roles=listappend(session.roles,"public")>
		<cfset session.last_login = "#getPrefs.last_login#">
	
		<cfset session.locSrchPrefs=getPrefs.locSrchPrefs>
		<cfquery name="logLog" datasource="cf_dbuser">
			update cf_users 
			set last_login = sysdate 
			where username = <cfqueryparam value='#session.username#' cfsqltype="CF_SQL_VARCHAR">
		</cfquery>
		<cfif listcontainsnocase(session.roles,"coldfusion_user")>
			<cfset session.dbuser = "#getPrefs.username#">
			<cfset session.epw = encrypt(pwd,cfid)>
			<cftry>
				<cfquery name="ckUserName" datasource="uam_god">
					select agent_id 
					from agent_name 
					where 
						agent_name = <cfqueryparam value='#session.username#' cfsqltype="CF_SQL_VARCHAR">
						AND agent_name_type='login'
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
					You must have an agent_name of type login that matches your MCZbase username.
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
<!---		<cfelse>
			<cflocation url="/login.cfm?action=signIn&username=#username#&password=#password#" addtoken="false">--->
	</cfif>

	<cfset setDbUser()>
	</cfoutput>
	<cfreturn true>
</cffunction>


