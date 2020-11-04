<cfif not isdefined("HEADER_DELIVERED") AND not isdefined("toProperCase")>
	<!---  if includes header has been included, functionLib.cfm will have been invoked and toProperCase will be defined --->
	<!---  if shared header has been included then HEADER_DELIVERED is defined --->
   <cfset pageTitle = "404 Error - Page Not Found">
   <cfinclude template="/shared/_header.cfm">
</cfif>
<cfoutput>
	<cfheader statuscode="500" statustext="Internal Server Error">
	<div class="basic_box">
	<cfset title="500: Internal Server Error">
	<h2>500 Internal Server Error. </h2>
	<cfif isdefined("errorMessage")>
		<h3>#errorMessage#</h3>
	</cfif>
	<cfif isdefined("errorDetail")>
		<p>#errorDetail#</p>
	</cfif>
	<p>
      Please <a href="/info/bugs.cfm"><b>submit a bug report</b></a>
	 	containing any information that might help us resolve this issue.
	</p>
</cfoutput>
<cfif not isdefined("HEADER_DELIVERED")>
	<cfinclude template="/includes/_footer.cfm">
<cfelse>
	<cfinclude template="/shared/_footer.cfm">
</cfif>
