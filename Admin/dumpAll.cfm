<!--- The application scope holds credentials and API keys: global_admin only.
	This page includes no header, so cf_rolecheck does not run here. --->
<cfif NOT ( isdefined("session.roles") AND listfindnocase(session.roles,"global_admin") ) >
	<cflocation url="/errors/forbidden.cfm" addtoken="false">
</cfif>
<cfdump var="#variables#" label="variables">
<cfdump var=#client# label="client">
<cfdump var=#session# label="session">
<cfdump var=#application# label="application">
<cfdump var=#cgi# label="cgi">
