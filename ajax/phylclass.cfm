<cfoutput>
	<cfquery name="pn" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
		select phylclass 
		from taxonomy 
		where upper(phylclass) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(q)#%">
		group by phylclass
		order by phylclass
	</cfquery>
	<cfloop query="pn">
		#phylclass# #chr(10)#
	</cfloop>
</cfoutput>
