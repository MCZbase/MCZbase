<cfoutput>
	<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
		<cfset oneOfUs = 1>
	<cfelse>
		<cfset oneOfUs = 0>
	</cfif>
	<cfquery name="pn" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
		select regexp_replace(project.project_name,'<[^>]*>') project_name 
		from project 
		where upper(regexp_replace(project.project_name,'<[^>]*>')) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(q)#%">
		<cfif oneOfUs NEQ 1>
			and project.mask_project_fg = 0
		</cfif>
		order by project_name
	</cfquery>
	<cfloop query="pn">
		#project_name# #chr(10)#
	</cfloop>
</cfoutput>
