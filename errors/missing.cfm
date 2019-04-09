<cfif isdefined("cgi.REDIRECT_URL") and len(cgi.REDIRECT_URL) gt 0>
	<cfset rdurl=cgi.REDIRECT_URL>
	<cfif rdurl contains chr(195) & chr(151)>
		<cfset rdurl=replace(rdurl,chr(195) & chr(151),chr(215))>
	</cfif>
	<cfset gPos=listfindnocase(rdurl,"guid","/")>
	<cfif gPos >
        <cftry>
            <cfset accept = GetHttpRequestData().Headers['accept'] >
            <cfcatch>
                <cfset accept = "">
            </cfcatch>
        </cftry>
        <cfif left(accept,11) IS 'text/turtle'>
             <cfset deliver = "text/turtle">
        <cfelseif left(accept,19) IS 'application/rdf+xml'>
             <cfset deliver = "application/rdf+xml">
        <cfelseif left(accept,19) IS 'application/ld+json'>
             <cfset deliver = "application/ld+json">
        <cfelse>
            <cfset deliver = "text/html">
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
		    <cfset redesignPos=listfindnocase(rdurl,"redesign","/")>
	        <cfif redesignPos>
	            <cftry>
				    <cfset guid = listgetat(rdurl,gPos+1,"/")>
				    <cfinclude template="/redesign/SpecimenDetail.cfm">
	                <cfcatch>
					    <cfinclude template="/errors/404.cfm">
	                </cfcatch>
	            </cftry>
	        <cfelse>
				<cftry>
					<cfset guid = listgetat(rdurl,gPos+1,"/")>
					<cfif listfindnocase(guid,"fish",":") or listfindnocase(guid,"bird",":")>
						<cfset guid=replacenocase(guid, "fish", "Ich")>
						<cfset guid=replacenocase(guid, "bird", "Orn")>
						<cfheader statuscode="301" statustext="Moved permanently">
						<cfheader name="Location" value="/guid/#guid#">
					</cfif>
					<cfinclude template="/SpecimenDetail.cfm">
					<cfcatch>
						<cfinclude template="/errors/404.cfm">
					</cfcatch>
				</cftry>
	        </cfif>
        </cfif>
	<cfelseif listfindnocase(rdurl,'specimen',"/")>
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
		<cftry>
			<cfset gPos=listfindnocase(rdurl,"name","/")>
			<cfset scientific_name = listgetat(rdurl,gPos+1,"/")>
			<cfinclude template="/TaxonomyDetails.cfm">
			<cfcatch>
				<cfinclude template="/errors/404.cfm">
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
		<cftry>
			<cfset gPos=listfindnocase(rdurl,"media","/")>
			<cfif listlen(rdurl,"/") gt 1>
				<cfset media_id = listgetat(rdurl,gPos+1,"/")>
				<cfset action="search">
			</cfif>
			<cfinclude template="/MediaSearch.cfm">
			<cfcatch>
				<cfinclude template="/errors/404.cfm">
			</cfcatch>
		</cftry>
	<cfelseif listfindnocase(rdurl,'publication',"/")>
		<cftry>
			<cfset gPos=listfindnocase(rdurl,"publication","/")>
			<cfif listlen(rdurl,"/") gt 1>
				<cfset publication_id = listgetat(rdurl,gPos+1,"/")>
				<cfset action="search">
			</cfif>
			<cfinclude template="/SpecimenUsage.cfm">
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
					select url from cf_canned_search where upper(search_name)='#ucase(sName)#'
				</cfquery>
				<cfif d.recordcount is 0>
					<cfquery name="d" datasource="cf_dbuser">
						select url from cf_canned_search where upper(search_name)='#ucase(urldecode(sName))#'
					</cfquery>
				</cfif>
				<cfif d.recordcount is 0>
					<cfinclude template="/errors/404.cfm">
					<cfabort>
				</cfif>
				<cfif d.url contains "#application.serverRootUrl#/SpecimenResults.cfm?">
					<cfset mapurl=replace(d.url,"#application.serverRootUrl#/SpecimenResults.cfm?","","all")>
					<cfloop list="#mapURL#" delimiters="&" index="i">
						<cfset t=listgetat(i,1,"=")>
						<cfset v=listgetat(i,2,"=")>
						<cfset "#T#" = "#urldecode(v)#">
					</cfloop>
					<cfinclude template="/SpecimenResults.cfm">
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
	<cfinclude template="/errors/404.cfm">
</cfif>
