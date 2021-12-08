<cftry>
	<!--- assuming a git repository and readable by coldfusion, determine the checked out branch by reading HEAD --->
	<cfset gitBranch = FileReadLine(FileOpen("#Application.webDirectory#/.git/HEAD", "read"))>
<cfcatch>
	<cfset gitBranch = "unknown">
</cfcatch>
</cftry>
<cfif isdefined("session.roles") AND listfindnocase(session.roles,"coldfusion_user")>
	<cfscript>
		getPageContext().forward("/Specimens.cfm");
	</cfscript>
<cfelse>
	<cfscript>
		getPageContext().forward("/SpecimenSearch.cfm");
	</cfscript>
</cfif>
<cfabort>
