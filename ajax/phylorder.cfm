<cfoutput>
	<cfquery name="pn" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
		select phylorder 
		from taxonomy 
		where upper(phylorder) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(q)#%">
		group by phylorder
		order by phylorder
	</cfquery>
	<cfloop query="pn">
		#phylorder# #chr(10)#
	</cfloop>
</cfoutput>
