<!---<cflocation url="SpecimenSearch.cfm" addtoken="false">--->
<cftry>
	<!--- assuming a git repository and readable by coldfusion, determine the checked out branch by reading HEAD --->
	<cfset gitBranch = FileReadLine(FileOpen("#Application.webDirectory#/.git/HEAD", "read"))>
<cfcatch>
	<cfset gitBranch = "unknown">
</cfcatch>
</cftry>
<!--- TODO: Make new search default for logged in users.  --->
<cfif findNoCase('redesign',gitBranch) EQ 0>
	<cfscript>
		getPageContext().forward("/SpecimenSearch.cfm");
	</cfscript>
<cfelse>
	<cfscript>
		getPageContext().forward("/Specimens.cfm");
	</cfscript>
</cfif>
<cfabort>
