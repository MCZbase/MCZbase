<cfif not isdefined("id") or len(#id#) is 0><cfabort></cfif>
<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	select url 
	from cf_canned_search 
	where canned_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#id#">
</cfquery>
<cfif len(#d.url#) gt 0>
	<cflocation addtoken="false" url="#d.url#">
</cfif>
