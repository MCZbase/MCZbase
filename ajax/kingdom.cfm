<cfoutput>
	<cfquery name="pn" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
		select kingdom 
		from taxonomy 
		where upper(kingdom) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(q)#%">
		group by kingdom
		order by kingdom
	</cfquery>
	<cfloop query="pn">
		#kingdom# #chr(10)#
	</cfloop>
</cfoutput>
