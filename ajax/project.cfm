<cfoutput>
	<cfquery name="pn" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
		select regexp_replace(project.project_name,'<[^>]*>') project_name 
		from project 
		where upper(regexp_replace(project.project_name,'<[^>]*>')) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(q)#%">
		order by project_name
	</cfquery>
	<cfloop query="pn">
		#project_name# #chr(10)#
	</cfloop>
</cfoutput>
