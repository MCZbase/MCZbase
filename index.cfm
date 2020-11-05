<!---<cflocation url="SpecimenSearch.cfm" addtoken="false">--->
<cftry>
	<!--- assuming a git repository and readable by coldfusion, determine the checked out branch by reading HEAD --->
	<cfset gitBranch = FileReadLine(FileOpen("/var/www/html/arctos/.git/HEAD", "read"))>
<cfcatch>
	<cfset gitBranch = "unknown">
</cfcatch>
</cftry>
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
