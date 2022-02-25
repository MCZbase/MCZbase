<cfif not isdefined("HEADER_DELIVERED") AND not isdefined("toProperCase")>
	<!---  if includes header has been included, functionLib.cfm will have been invoked and toProperCase will be defined --->
	<!---  if shared header has been included then HEADER_DELIVERED is defined --->
<cfset pageTitle = "500 Error - Internal Server Error">
<cfinclude template="/shared/_header.cfm">
</cfif>
<cfoutput>
	<main class="container" id="content">
		<div class="row">
			<div class="col-8 mx-auto pt-5">
				<cfheader statuscode="500" statustext="Internal Server Error">
				<cfset title="500: Internal Server Error">
				<h1 class="h2 mt-2">500 Internal Server Error. </h1>
				<cfif isdefined("errorMessage")>
					<h3>#errorMessage#</h3>
				</cfif>
				<cfif isdefined("errorDetail")>
					<p>#errorDetail#</p>
				</cfif>
				<p>
					Please <a href="/info/bugs.cfm">submit a bug report</a> containing any information that might help us resolve this issue.
				</p>
			</div>
		</div>
	</main>
</cfoutput>
<cfif not isdefined("HEADER_DELIVERED")>
	<cfinclude template="/includes/_footer.cfm">
<cfelse>
	<cfinclude template="/shared/_footer.cfm">
</cfif>
