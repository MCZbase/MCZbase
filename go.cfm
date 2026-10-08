<!--- Redirect to a saved search by its id.  Only URLs on this site are followed, so a saved search
	can't make this page an open redirect to another site. --->
<cfparam name="url.id" default="">
<cfif len(url.id) is 0 OR NOT isNumeric(url.id)><cfabort></cfif>
<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	select url
	from cf_canned_search
	where canned_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#url.id#">
</cfquery>
<cfif left(d.url, len(Application.serverRootUrl) + 1) EQ Application.serverRootUrl & "/"
		OR (left(d.url, 1) EQ "/" AND left(d.url, 2) NEQ "//")>
	<cflocation addtoken="false" url="#d.url#">
</cfif>
