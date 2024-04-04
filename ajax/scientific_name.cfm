<cfoutput>
	<cfif not isdefined("limit") or not isnumeric(limit)>
		<cfset limit=100>
	</cfif>
	<cfquery name="pn" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
		select * from (
			select
				scientific_name,
				taxon_name_id
			from
				taxonomy
			where 
				upper(scientific_name) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(q)#%">
			order by
				scientific_name
		) 
		where rownum <= <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#limit#">
	</cfquery>
	<cfloop query="pn">
		#scientific_name#|#taxon_name_id##chr(10)#
	</cfloop>
</cfoutput>
