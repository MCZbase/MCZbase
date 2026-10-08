<!--- The application scope holds credentials and API keys: global_admin only. --->
<cf_rolecheck>
<cfif NOT ( isdefined("session.roles") AND listfindnocase(session.roles,"global_admin") ) >
	<cflocation url="/errors/forbidden.cfm" addtoken="false">
</cfif>
<!--- Redacted, so that a screenshot of this page can't give away the viewer's database password
	(session.epw with the CFID in the Cookie header) or the application's credentials. --->
<cfinclude template="/shared/component/diagnostics.cfc" runOnce="true">
<cfdump var="#variables#" label="variables">
<cfdump var="#redactedScope(client)#" label="client (redacted)">
<cfdump var="#redactedScope(session)#" label="session (redacted)">
<cfdump var="#redactedScope(application)#" label="application (redacted)">
<cfdump var="#redactedScope(cgi)#" label="cgi (redacted)">
