<cftry>
	<!--- assuming a git repository and readable by coldfusion, determine the checked out branch by reading HEAD --->
	<cfset gitBranch = trim(fileRead("#Application.webDirectory#/.git/HEAD"))>
<cfcatch>
	<cfset gitBranch = "unknown">
</cfcatch>
</cftry>
<cfscript>
	getPageContext().forward("/Specimens.cfm");
</cfscript>
<cfabort>
