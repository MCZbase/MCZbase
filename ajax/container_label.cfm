<cfoutput>
	<cfif not isdefined("container_type") or len(container_type) eq 0  >
    	<cfquery name="pn" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
	    	select distinct label from container
            where upper(label) like <cfqueryparam CFSQLTYPE="CF_SQL_VARCHAR" value = "%#ucase(q)#%">
		    order by label
    	</cfquery>
    <cfelse>
    	<cfquery name="pn" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
	    	select distinct label from container 
            where upper(label) like <cfqueryparam CFSQLTYPE="CF_SQL_VARCHAR" value = "%#ucase(q)#%">
            and container_type = <cfqueryparam CFSQLTYPE="CF_SQL_VARCHAR" value = "#container_type#">
		    order by label
    	</cfquery>
    </cfif>
	<cfloop query="pn">
		#label# #chr(10)#
	</cfloop>
</cfoutput>
