<cfoutput>
	<cfquery name="pn" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
		select distinct label from container where upper(label) like '%#ucase(q)#%'
		order by label
	</cfquery>
	<cfloop query="pn">
		#label# #chr(10)#
	</cfloop>
</cfoutput>
