<!--- Runs without a session or client variables (FORWARD_ONLY_PAGES in Application.cfc), so it may only forward. --->
<cfscript>
	getPageContext().forward("/media/findMedia.cfm");
</cfscript>
<cfabort>
