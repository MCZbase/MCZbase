<cfoutput>
	<cfif not isdefined("limit") or not isnumeric(limit)>
		<cfset limit=100>
	</cfif>
	<cfquery name="pn" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
		select * from (
			select
				higher_geog,
				geog_auth_rec_id
			from
				geog_auth_rec
			where 
				upper(higher_geog) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(q)#%">
			order by
				higher_geog
		) 
		where rownum <= <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#limit#">
	</cfquery>
	<cfloop query="pn">
		#higher_geog#|#geog_auth_rec_id##chr(10)#
	</cfloop>
</cfoutput>
