<cfif isdefined("cgi.REDIRECT_URL") and len(cgi.REDIRECT_URL) gt 0>
	<!--- TODO: Extract parameters from cgi.redirect_query_string, not being populated by apache/mod_jk though mod_jk is configured to do so --->
	<cfset rdurl=cgi.REDIRECT_URL>
	<cfif rdurl contains chr(195) & chr(151)>
		<cfset rdurl=replace(rdurl,chr(195) & chr(151),chr(215))>
	</cfif>
	<cfset gPos=listfindnocase(rdurl,"guid","/")>
	<cfif gPos >
		<!--- Request for GUID --->
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
				<cfset guid = listgetat(rdurl,gPos+1,"/")>
				<cfinclude template="/rdf/Occurrence.cfm">
			<cfcatch>
				<cfinclude template="/errors/404.cfm">
			</cfcatch>
			</cftry>
		<cfelse> 
			<cfif findNoCase('redesign',Session.gitBranch) GT 0>	
				<cfset guid = listgetat(rdurl,gPos+1,"/")>
				<cfinclude template="/specimens/Specimen.cfm">
			<cfelse>
				<cfset guid = listgetat(rdurl,gPos+1,"/")>
				<cfif listfindnocase(guid,"fish",":") or listfindnocase(guid,"bird",":")>
					<cfset guid=replacenocase(guid, "fish", "Ich")>
					<cfset guid=replacenocase(guid, "bird", "Orn")>
					<cfheader statuscode="301" statustext="Moved permanently">
					<cfheader name="Location" value="/guid/#guid#">
				</cfif>
				<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
					<!--- logged in users see the old specimen details page, this allows editing --->
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
	<cfelseif listfindnocase(rdurl,'specimen',"/")>
		<!--- Request by (old) specimen API --->
		<cfif findNoCase('redesign',Session.gitBranch) GT 0>	
			<cfset guid = listgetat(rdurl,gPos+1,"/")>
			<cfinclude template="/specimens/Specimen.cfm">
		<cfelse>
			<cftry>
				<cfset gPos=listfindnocase(rdurl,"specimen","/")>
				<cfset	i = listgetat(rdurl,gPos+1,"/")>
				<cfset	c = listgetat(rdurl,gPos+2,"/")>
				<cfset	n = listgetat(rdurl,gPos+3,"/")>
				<cfset guid=i & ":" & c & ":" & n>
				<cfinclude template="/SpecimenDetail.cfm">
			<cfcatch>
				<cfinclude template="/errors/404.cfm">
			</cfcatch>
			</cftry>
		</cfif>
	<cfelseif listfindnocase(rdurl,'document',"/")>
		<cfoutput>
		<cftry>
			<cfset gPos=listfindnocase(rdurl,"document","/")>
			<cftry>
				<cfset ttl = listgetat(rdurl,gPos+1,"/")>
				<cfcatch></cfcatch>
			</cftry>
			<cftry>
				<cfset p=listgetat(rdurl,gPos+2,"/")>
				<cfcatch></cfcatch>
			</cftry>

			<cfinclude template="/document.cfm">
			<cfcatch>
				<cfdump var=#cfcatch#>
				<!---
					<cfif listgetat(rdurl,gPos+2,"/")>
						<cfset p=listgetat(rdurl,gPos+2,"/")>
					<cfelse>
						<cfset p=1>
					</cfif>
					<cfinclude template="/errors/404.cfm">
				--->
			</cfcatch>
		</cftry>
		</cfoutput>
	<cfelseif listfindnocase(rdurl,'name',"/")>
		<!--- Request by name API (for taxon record) --->
		<cftry>
			<cfset gPos=listfindnocase(rdurl,"name","/")>
			<cfset scientific_name = listgetat(rdurl,gPos+1,"/")>
			<cfinclude template="/taxonomy/showTaxonomy.cfm">
			<cfcatch>
				<cfset errorMessage = cfcatch.message>
				<cfset errorDetail = cfcatch.detail>
				<cfinclude template="/errors/500.cfm">
			</cfcatch>
		</cftry>
	<cfelseif listfindnocase(rdurl,'api',"/")>
		<cftry>
			<cfset gPos=listfindnocase(rdurl,"api","/")>
			<cfif listlen(rdurl,"/") gt 1>
				<cfset action = listgetat(rdurl,gPos+1,"/")>
			</cfif>
			<cfinclude template="/info/api.cfm">
			<cfcatch>
				<cfinclude template="/errors/404.cfm">
			</cfcatch>
		</cftry>
	<cfelseif listfindnocase(rdurl,'project',"/")>
		<cftry>
			<cfset gPos=listfindnocase(rdurl,"project","/")>
			<cfif listlen(rdurl,"/") gt 1>
				<cfset niceProjName = listgetat(rdurl,gPos+1,"/")>
			</cfif>
			<cfinclude template="/ProjectDetail.cfm">
			<cfcatch>
				<cfinclude template="/errors/404.cfm">
			</cfcatch>
		</cftry>
	<cfelseif listfindnocase(rdurl,'media',"/")>
		<!--- Request by media API (for media record) --->
		<cftry>
			<cfset gPos=listfindnocase(rdurl,"media","/")>
			<cfif listlen(rdurl,"/") gt 1>
				<cfset media_id = listgetat(rdurl,gPos+1,"/")>
				<cfset action="search">
			</cfif>
			<cfif findNoCase('redesign',Session.gitBranch) GT 0>	
				<cfinclude template="/media/showMedia.cfm">
			<cfelse>
				<!--- WARNING: /production must continue to use /MediaSearch.cfm until it's API and functionality has been entirely replaced by working code.  --->
				<!--- WARNING: this is the redirect for /media/{media_id} which MUST go to the media details page for the media object.  --->
				<cfinclude template="/MediaSearch.cfm">
			</cfif>
			<cfcatch>
				<cfinclude template="/errors/404.cfm">
			</cfcatch>
		</cftry>
	<cfelseif listfindnocase(rdurl,'publication',"/")>
		<cftry>
			<cfset gPos=listfindnocase(rdurl,"publication","/")>
			<cfif listlen(rdurl,"/") gt 1>
				<cfset publication_id = listgetat(rdurl,gPos+1,"/")>
			</cfif>
			<cfinclude template="/publications/showPublication.cfm">
			<cfcatch>
				<cfinclude template="/errors/404.cfm">
			</cfcatch>
		</cftry>
	<cfelseif listfindnocase(rdurl,'saved',"/")>
		<Cfoutput>
		<cftry>
			<cfset gPos=listfindnocase(rdurl,"saved","/")>
			<cfif listlen(rdurl,"/") gt 1>
				<cfset sName = listgetat(rdurl,gPos+1,"/")>
				<cfquery name="d" datasource="cf_dbuser">
					SELECT url, execute 
					FROM cf_canned_search 
					WHERE upper(search_name)=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(sName)#">
				</cfquery>
				<cfif d.recordcount is 0>
					<cfquery name="d" datasource="cf_dbuser">
						SELECT url, execute
						FROM cf_canned_search
						WHERE upper(search_name)=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(urldecode(sName))#">
					</cfquery>
				</cfif>
				<cfif d.recordcount is 0>
					<cfinclude template="/errors/404.cfm">
					<cfabort>
				</cfif>
				<cfset useUrl = d.url >
				<cfif d.execute EQ 0 >
					<cfset useUrl = replace(useUrl,"&execute=true","","all")>
					<cfset useUrl = replace(useUrl,"?execute=true&","?")>
					<cfset useUrl = replace(useUrl,"?execute=true","")>
				</cfif>
				<cfif d.url contains "#application.serverRootUrl#/SpecimenResults.cfm?">
					<cfset mapurl=replace(d.url,"#application.serverRootUrl#/SpecimenResults.cfm?","","all")>
					<cfloop list="#mapURL#" delimiters="&" index="i">
						<cfset t=listgetat(i,1,"=")>
						<cfset v=listgetat(i,2,"=")>
						<cfset "#T#" = "#urldecode(v)#">
					</cfloop>
					<cfinclude template="/SpecimenResults.cfm">
				<cfelseif d.url contains "/Specimens.cfm?" OR d.url contains "/Transactions.cfm?" 
						OR d.url contains "/Agents.cfm?" OR d.url contains "/Taxa.cfm?"
						OR d.url contains "/media/findMedia.cfm?" OR d.url contains "/transactions/Permits.cfm?"
				>
					<cfset target="#application.serverRootUrl##useUrl#">
					If you are not redirected, please click this link: <a href="#target#">#target#</a>
					<script>
						document.location='#target#';
					</script>
				<cfelseif left(d.url,7) is "http://">
					Click to continue: <a href="#d.url#">#d.url#</a>
				<cfelse>
					If you are not redirected, please click this link: <a href="/#d.url#">#d.url#</a>
					<script>
						document.location='/#d.url#';
					</script>
				</cfif>
			<cfelse>
				<cfinclude template="/errors/404.cfm">
			</cfif>
			<cfcatch>
				<cfinclude template="/errors/404.cfm">
			</cfcatch>
		</cftry>
		</Cfoutput>
	<cfelse><!--- all the rest --->
		<!--- see if we can handle the peristent 404s elegantly --->
		<cfif cgi.SCRIPT_NAME contains "/DiGIRprov/www/DiGIR.php">
			<cfheader statuscode="301" statustext="Moved permanently">
			<cfheader name="Location" value="http://digir.mcz.harvard.edu/ipt/">
		<cfelse>
			<cftry>
				<cfif !isSet(cgi.REDIRECT_URL) or !isSet(cgi.redirect_query_string)>
					<cfscript>
						getPageContext().forward("/errors/404.cfm");
					</cfscript>
				<cfelse>
					<cfscript>
						getPageContext().forward(cgi.REDIRECT_URL & ".cfm?" & cgi.redirect_query_string);
					</cfscript>
				</cfif>
				<cfabort>
			<cfcatch>
				<cfscript>
					getPageContext().forward("/errors/404.cfm");
				</cfscript>
				<cfabort>
			</cfcatch>
			</cftry>
		</cfif>
	</cfif>
<cfelse>
	<cfset rdurl = cgi.SCRIPT_NAME>
	<cfinclude template="/errors/404.cfm">
</cfif>
