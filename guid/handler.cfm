<!---
guid/handler.cfm

Copyright 2008-2017 Contributors to Arctos
Copyright 2008-2024 President and Fellows of Harvard College

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

Handle requests for data by guid, depends on apache configuration: 

RewriteEngine On
RewriteRule "^/guid/(MCZ:[A-Za-z]+:.*)"    /guid/handler.cfm?catalog=$1 [QSA,PT]

--->
<cftry>
	<cfset accept = GetHttpRequestData().Headers['accept'] >
<cfcatch>
	<cfset accept = "">
</cfcatch>
</cftry>
<cfif isdefined("url.occurrenceID") and len(url.occurrenceID) gt 0>
	<cfset occurrenceID = url.occurrenceID>
	<!--- TODO: Support occurrenceID --->
	<!--- Expected form is a UUID --->
</cfif>
<cfif isdefined("url.materialSampleID") and len(url.materialSampleID) gt 0>
	<cfset materialSampleID = url.materialSampleID>
	<!--- TODO: Support materialSampleID --->
	<!--- Expected form is a UUID --->
</cfif>
<cfif isdefined("url.taxonID") and len(url.taxonID) gt 0>
	<cfset taxonID = url.taxonID>
	<!--- TODO: Support taxonID --->
	<!--- Expected form is a UUID --->
</cfif>
<cfif isdefined("url.agent") and len(url.agent) gt 0>
	<cfset agent = url.agent>
	<!--- TODO: Support agent guids --->
	<!--- Expected form is a UUID --->
</cfif>
<cfif isdefined("url.catalog") and len(url.catalog) gt 0>
	<cfset catalog = url.catalog>
	<!--- Expected form is a urn:catalog, Darwin Core Triplet --->

	<cfif REFind('^[A-Z]+:[A-Za-z]+:[A-Za-z0-9-]+$',catalog) GT 0>
		<cfset rdurl=catalog>
		<!---  path terminator /{json|json-ld|turtle|rdf} is rewritten by apache to deliver, if present, override accept header. --->
		<cfif isDefined("url.deliver") AND len(url.deliver) GT 0>
			<cfif find('/',deliver) EQ 1>
   			<cfset deliver = RemoveChars(url.deliver,1,1)>
			</cfif>
		</cfif>
	<cfelse>
		<cfinclude template="/errors/404.cfm">
		<cfabort>
	</cfif>
	<cfquery name="checkForGuid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		select GUID 
		from <cfif ucase(session.flatTableName) EQ "FLAT"> flat <cfelse> filtered_flat </cfif>
		where GUID = <cfqueryparam value="#catalog#" cfsqltype="CF_SQL_VARCHAR">
	</cfquery>
	<cfif checkForGuid.recordcount NEQ 1>
		<cfinclude template="/errors/404.cfm">
		<cfabort>
	</cfif>

	<!--- Content negotiation, pick highest priority content type that we can deliver from the http accept header list --->
	<!--- default to human readable web page --->
	<cfif NOT isDefined("deliver") OR len(deliver) EQ 0>
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
		<cfelseif findNoCase('test',Session.gitBranch) GT 0>	
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
