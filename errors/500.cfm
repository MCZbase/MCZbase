<cfinclude template="/includes/_header.cfm">
<cfoutput>
	<cfheader statuscode="500" statustext="Internal Server Error">
	<div class="basic_box">
	<cfset title="500: Internal Server Error">
	<h2>500 Internal Server Error. </h2>
	<cfif isdefined(errorMessage)>
		<h3>#errorMessage#</h3>
	</cfif>
	<p>
      Please <a href="/info/bugs.cfm"><b>submit a bug report</b></a>
	 	containing any information that might help us resolve this issue.
	</p>
</cfoutput>
<cfinclude template="/includes/_footer.cfm">
