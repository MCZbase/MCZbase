<cfoutput>
	<cfquery name="pn" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
		select family 
		from taxonomy 
		where upper(family) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(q)#%">
		group by family
		order by family
	</cfquery>
	<cfloop query="pn">
		#family# #chr(10)#
	</cfloop>
</cfoutput>
