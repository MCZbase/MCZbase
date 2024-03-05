<cfif isdefined("occurrence") and len(occurrence) gt 0>
	<!--- TODO: Support occurrenceID --->
</cfif>
<!--- TODO: Support materialSampleID --->
<!--- TODO: Support taxonID --->
<!--- TODO: Support agent guids --->
<cfif isdefined("catalog") and len(catalog) gt 0>
	<cfset rdurl=catalog>
	<cftry>
		<cfset accept = GetHttpRequestData().Headers['accept'] >
	<cfcatch>
		<cfset accept = "">
	</cfcatch>
	</cftry>

	<!--- Content negotiation, pick highest priority content type that we can deliver from the http accept header list --->
	<!--- default to human readable web page --->
	<cfif NOT isDefined("deliver")>
		<cfset deliver = "text/html">
		<cfset done = false>
		<cfloop list='#accept#' delimiters=',' index='a'>
			<cfif NOT done>
				<cfif a IS 'text/turtle' OR a IS 'application/rdf+xml' OR a IS 'application/ld+json'>
					<cfset deliver = a>
					<cfset done = true>
				<cfelseif a IS 'text/html' OR a IS 'text/xml' OR a IS 'application/xml' OR a IS 'application/xhtml+xml'> 
					<!--- use text/html for human readable delivery, actual is xhtml --->
					<cfset deliver = 'text/html'>
					<cfset done = true>
				</cfif>
			</cfif>
		</cfloop>
		<!--- allow path terminator /{json|json-ld|turtle|rdf} to override accept header. --->
		<cfif refind('/json$',rdurl) GT 0>
			<cfset rdurl = rereplace(rdurl,"/json$","")>
   		<cfset deliver = "application/ld+json">
		<cfelseif refind('/json-ld$',rdurl) GT 0>
			<cfset rdurl = rereplace(rdurl,"/json-ld$","")>
   		<cfset deliver = "application/ld+json">
		<cfelseif refind('/turtle$',rdurl) GT 0>
			<cfset rdurl = rereplace(rdurl,"/turtle$","")>
   		<cfset deliver = "text/turtle">
		<cfelseif refind('/rdf$',rdurl) GT 0>
			<cfset rdurl = rereplace(rdurl,"/rdf$","")>
   		<cfset deliver = "application/xhtml+xml">
		</cfif>
	<cfelse>
		<!--- NOTE: apache 404 redirect is not passing parameters or cgi.redirect_query_string, so this block is not entered --->
		<!--- allow url parameter deliver={json/json-ld/turtle/rdf} to override accept header. --->
		<cfif deliver IS "json" OR deliver IS "json-ld">
   		<cfset deliver = "application/ld+json">
		<cfelseif deliver IS "turtle">
 			  	<cfset deliver = "text/turtle">
		<cfelseif deliver IS "rdf">
   		<cfset deliver = "application/xhtml+xml">
		<cfelse>
			<cfset deliver = "text/html">
		</cfif>
	</cfif>

	<cfif deliver NEQ "text/html">
		<cftry>
			<cfset guid = catalog>
			<cfinclude template="/rdf/Occurrence.cfm">
		<cfcatch>
			<cfinclude template="/errors/404.cfm">
		</cfcatch>
		</cftry>
	<cfelse> 
		<cfif findNoCase('redesign',Session.gitBranch) GT 0>	
			<cfset guid = catalog>
			<cfinclude template="/specimens/Specimen.cfm">
		<cfelse>
			<cfset guid = catalog>
			<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
				<!--- logged in users see the old specimen details page, this allows editing --->
				<!--- wrapped in an error handler that redirects to /errors/404.cfm--->
				<cftry>
					<cfinclude template="/SpecimenDetail.cfm">
				<cfcatch>
					<cfinclude template="/errors/404.cfm">
				</cfcatch>
				</cftry>
			<cfelse>
				<!--- not logged in sees the redesigned specimen details page, editing not enabled for them and not working there yet --->
				<!--- not wrapped in an error handler that redirects to /errors/404, specimen not found handled internally --->
				<!---  exceptions should rise up to the Application.cfc error handler.  --->
				<cfinclude template="/specimens/Specimen.cfm">
			</cfif>
		</cfif>
	</cfif>
<cfelse>
	<cfset rdurl = cgi.SCRIPT_NAME>
	<cfinclude template="/errors/404.cfm">
</cfif>
