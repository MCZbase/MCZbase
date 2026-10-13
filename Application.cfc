<!---
Application.cfc
 
TODO: Confirm years
Copyright 2008-2017 Contributors to Arctos
Copyright 2008-2026 President and Fellows of Harvard College

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

--->
<cfcomponent>

	<cfset This.name = "MCZbase" />
	<cfset This.SessionManagement="True" />
	<cfset This.ClientManagement="true" />
	<cfset This.ClientStorage="Cookie" />
	<cfset This.sessionTimeout=#CreateTimeSpan(0,3,0,0)# />
	<!--- A new session lasts five minutes, until the client comes back with it (onRequestStart), so a
		crawler that keeps no cookies leaves only a short lived session behind. --->
	<cfset variables.NEW_SESSION_SECONDS = 300>
	<cfset variables.SESSION_SECONDS = round(This.sessionTimeout * 86400)>
	<!--- Pages that only forward to another page.  The forwarded request can't find a session these
		start, as its cookie hasn't reached the browser, and starts a second one; so these start none. --->
	<cfset variables.FORWARD_ONLY_PAGES = "/index.cfm,/agents/index.cfm,/dataquality/index.cfm,/localities/index.cfm,/media/index.cfm,/metrics/index.cfm,/metrics/datafiles/index.cfm,/shared/images/index.cfm,/specimens/index.cfm,/transactions/index.cfm,/users/index.cfm,/vocabularies/index.cfm">
	<!--- The load balancer's health check never returns a session, so it gets none, and onRequestStart
		answers it without running the page.  Anything else sending this user agent gets only that answer. --->
	<cfset variables.isHealthCheck = false>
	<cfif left(cgi.http_user_agent, 17) EQ "ELB-HealthChecker">
		<cfset variables.isHealthCheck = true>
	</cfif>
	<!--- Client management is off too, as it would still set CFID, CFTOKEN and CFGLOBALS cookies. --->
	<cfif variables.isHealthCheck OR listFindNoCase(variables.FORWARD_ONLY_PAGES, cgi.script_name) GT 0>
		<cfset This.SessionManagement="False" />
		<cfset This.ClientManagement="False" />
	</cfif>
	<!--- SameSite=Lax keeps the session cookies off posts from other sites (cross-site request
		forgery); links from other sites and email still arrive logged in.  Secure requires every
		host to be served over https, as a browser will not return the cookie over http. --->
	<cfset This.sessioncookie = { httponly = true, secure = true, samesite = "Lax" } />
	<!--- requestSummary, exceptionSummary and redactedScope, for onError. --->
	<cfinclude template="/shared/component/diagnostics.cfc" runOnce="true">
	<cfinclude template="/shared/component/clientAddress.cfc" runOnce="true">
	<cfinclude template="/shared/component/mailThrottle.cfc" runOnce="true">

	<cffunction name="onMissingTemplate" returnType="boolean" output="false">
		<cfargument name="thePage" type="string" required="true" />
		<!---
			<cfscript>
			getPageContext().forward("/errors/404.cfm");
			</cfscript
			--->
		<cfinclude template="/errors/404.cfm">
		<cfabort />
	</cffunction>

	<cffunction name="onError">
		<cfargument name="exception" required="true" />
		<cfargument name="EventName" type="String" required="true" />
		<cfif isdefined("exception.type") and exception.type eq "coldfusion.runtime.AbortException">
			<cfreturn />
		</cfif>
		<!--- The error is logged under a reference shown to the user.  Diagnostics never include the
			session scope or cookies: session.epw and the CFID cookie together give away the user's
			database password (see diagnostics.cfc). --->
		<cfset local.errorReference = dateFormat(now(), "yyyymmdd") & "-" & left(replace(createUUID(), "-", "", "all"), 8)>
		<cfset local.requestFacts = requestSummary()>
		<cfset local.problem = exceptionSummary(arguments.exception)>
		<cfset local.location = "unknown line">
		<cfif structKeyExists(local.problem, "location")>
			<cfset local.location = local.problem.location>
		</cfif>
		<cflog file="MCZbase" type="error" text="Error #local.errorReference# on #local.requestFacts.page# at #local.location# for user [#local.requestFacts.username#] from #local.requestFacts['remote address']#: #serializeJSON(local.problem)#">
		<cfset local.showDetail = false>
		<cfif isDefined("session.roles") AND listFindNoCase(session.roles, "global_admin") GT 0>
			<cfset local.showDetail = true>
		</cfif>
		<table cellpadding="10">
			<tr>
				<td valign="top"><img src="/images/blowup.gif"></td>
				<td>
					<font color="##FF0000" size="+1">
						<strong>An error occurred while processing this page!</strong>
					</font>
					<cfoutput>
						<cfif structKeyExists(local.problem, "message")>
							<br>
							<i>
								#encodeForHtml(local.problem.message)#
								<cfif structKeyExists(local.problem, "detail")>
									<br>
									#encodeForHtml(local.problem.detail)#
								</cfif>
							</i>
						</cfif>
						<p>
							<cfset local.bugMessage = "">
							<cfif structKeyExists(local.problem, "message")>
								<cfset local.bugMessage = local.problem.message>
							</cfif>
							This error has been logged with the reference <strong>#encodeForHtml(local.errorReference)#</strong>.
							Please
							<a href="/info/bugs.cfm?error_reference=#encodeForUrl(local.errorReference)#&error_message=#encodeForUrl(left(local.bugMessage, 1000))#">submit a bug report</a>,
							which will start with the reference and the error message above, and add anything else that might help us to resolve this problem.
						</p>
					</cfoutput>
				</td>
			</tr>
		</table>
		<cfif local.showDetail>
			<!--- For administrators: the request and exception, with secrets removed. --->
			<cfdump var="#local.requestFacts#" label="request">
			<cfdump var="#local.problem#" label="exception">
			<cfdump var="#redactedScope(form)#" label="form (redacted)">
			<cfdump var="#redactedScope(url)#" label="url (redacted)">
		</cfif>
		<cfinclude template="/includes/_footer.cfm">
		<cfreturn />
	</cffunction>

	<!-------------------------->
	<cffunction name="onApplicationStart" returnType="boolean" output="false">
		<cfscript>
			serverName = CreateObject("java", "java.net.InetAddress").getLocalHost().getHostName();
		</cfscript>
		<cfset Application.serverName=serverName /><!--- Store the server name returned away for debugging --->
		<!--- Proxies whose X-Forwarded-For can be believed, beyond loopback, this server's subnets and,
			on EC2, its VPC, which are trusted automatically (shared/component/clientAddress.cfc):
			addresses or IPv4 ranges, needed only for a proxy outside those. --->
		<cfset Application.trustedProxies = "" />
		<!--- Addresses or IPv4 ranges never added to the blocklist automatically, e.g. staff networks. --->
		<cfset Application.blockExemptAddresses = "" />
		<!--- this server's addresses and subnets, and on EC2 its VPC, cached in Application.localNetworks
			and Application.cloudNetworks --->
		<cfset localAddresses() />
		<cfset cloudNetworks() />
		<cfif serverName is "web.arctos.database.museum">
			<cfset serverName="arctos.database.museum" />
		</cfif>
		<!--- In VM environment, how java resolves getLocalHost().getHostName() changes in ways outside our control.  --->
  		<!--- So, make sure that we are handling the cases where only the unqualified local name is returned. ---> 
		<cfif serverName is "mczbase-prod2.rc.fas.harvard.edu" or serverName is "mczbase-prod2">
			<cfset serverName="mczbase.mcz.harvard.edu" />
		</cfif>
		<cfif serverName is "mczbase-dev">
			<cfset serverName="mczbase-dev.rc.fas.harvard.edu" />
		</cfif>
		<cfif serverName is "mczbase-dev2">
			<cfset serverName="mczbase-dev2.rc.fas.harvard.edu" />
		</cfif>
		<cfif serverName is "mczbase-test2">
			<cfset serverName="mczbase-test2.rc.fas.harvard.edu" />
		</cfif>
		<cfif serverName is "mczbase-test">
			<cfset serverName="mczbase-test.rc.fas.harvard.edu" />
		</cfif>
		<cfif serverName is "huhbase-test">
			<cfset serverName="huhbase-test.rc.fas.harvard.edu" />
		</cfif>
 		<cfset Application.hostName = '#serverName#'><!--- make available for reference from the code --->

 		<cfset Application.protocol = 'http'>
		<!--- *** Test to see if TLS is on and redirection to https is enabled --->
		<cfhttp url='http://#serverName#/' redirect="no" />
		<!--- don't actually follow the redirect to avoid having to test for both signed and self-signed certificates --->
		<cfif left(#cfhttp.statusCode#, 1) EQ '3'>
			<!--- Redirection is on. --->
			<cfif left(cfhttp.responseHeader['Location'],6) EQ 'https:' >
 			    <cfset Application.protocol = 'https'>
			    <!--- and the target location uses https, TLS support is enabled. --->
			</cfif>
		</cfif>
        	<!--- load persisted settings from database --->
		<cfset Application.gmap_api_key = "not set" />
		<cfset Application.Google_uacct = "not set" />
		<cfset Application.g_sitekey = "" />
		<cfset Application.bugzillaToEmail = "" />
		<cfset Application.bugzillaFromEmail = "" />
		<cfset Application.bugzilla_api_key = "" />
		<cfset Application.bugzilla_api_url = "" />
		<cfset Application.genBankPwd= "" />
		<cfset Application.allowed_profile= "" />
		<cfset Application.allowed_tablespace= "" />
		<cfquery name="cf_global_settings" datasource="uam_god">
			SELECT gmap_api_key, google_site_key, google_uacct, bugzilla_to_email, bugzilla_from_email, genbank_password, 
				allowed_profile, allowed_tablespace, bugzilla_api_key, bugzilla_server
			FROM cf_global_settings
			WHERE rownum < 2
		</cfquery>
		<cfloop query="cf_global_settings">
			<cfset application.gmap_api_key="#cf_global_settings.gmap_api_key#" />
			<cfset application.g_sitekey="#cf_global_settings.google_site_key#">
			<cfset Application.Google_uacct = "#cf_global_settings.google_uacct#" />
			<cfset Application.bugzillaToEmail = "#cf_global_settings.bugzilla_to_email#" />
			<cfset Application.bugzillaFromEmail = "#cf_global_settings.bugzilla_from_email#" />
			<cfset Application.bugzilla_api_key = "#cf_global_settings.bugzilla_api_key#" />
			<cfset Application.bugzilla_api_url = "#cf_global_settings.bugzilla_server#" />
			<cfset Application.genBankPwd=encrypt("#cf_global_settings.genbank_password#","genbank") />
			<cfset Application.allowed_profile = "#cf_global_settings.allowed_profile#"/>
			<cfset Application.allowed_tablespace = "#cf_global_settings.allowed_tablespace#"/>
		</cfloop>

		<!---cfset Application.sessionTimeout=createTimeSpan(0,1,40,0) /--->
		<cfset Application.ajax_timeout=60 /><!--- in seconds, for ajax calls for search/browse --->
		<cfset Application.query_timeout=55 /><!--- in seconds, for cfquery for search/browse --->
		<cfset Application.short_timeout=5 /><!--- in seconds, for cfquery that should complete rapidly --->
		<cfset Application.serverRootUrl = "#Application.protocol#://#serverName#" />
		<cfset Application.user_login="user_login" />
		<cfset Application.max_pw_age = 365 />
		<cfset Application.fromEmail = "#serverName#" />
		<!--- Default header/style apperance --->
		<cfset Application.application_name = "MCZbase" />
		<cfset Application.header_image = "/images/genericHeaderIcon.gif" />
		<cfset Application.old_header_image = "/images/genericHeaderIcon.gif" /><!--- NOTE: old_ variables are intended for use on old includes/_header.cfm --->
		<cfset Application.header_image_alt = "logo with link to website" />
		<cfset Application.header_image_class = "mcz_logo_krono" />
		<cfset Application.collection_url = "/" />
		<cfset Application.collection_link_text = "Error" />
		<cfset Application.old_collection_link_text = "Error" />
		<cfset Application.institution_url = "/" />
		<cfset Application.stylesheet = "" />
		<cfset Application.institution_link_text = "Host configuration problem: #serverName# not recognized" />
		<cfset Application.meta_description = "Arctos is a biological specimen database." />
		<cfset Application.meta_keywords = "museum, collection, management, system" />
		<cfset Application.domain = replace(Application.serverRootUrl,"#Application.protocol#://",".") />
		<cfset Application.header_color = "##000066" />
		<cfset Application.old_header_color = "##000000" />
		<cfset Application.institutionlinkcolor = "##FF0000" />
		<cfset Application.old_institutionlinkcolor = "##000066" />
		<cfset Application.collectionlinkcolor = "##00FF00" />
		<cfset Application.old_collectionlinkcolor = "##FF0000" />
		<cfset Application.serverrole ="unknown">
		<cfquery name="d" datasource="uam_god">
			select ip from blacklist where sysdate-LISTDATE<180
		</cfquery>
		<cfset Application.blacklist=valuelist(d.ip) />
		<cfif serverName contains "harvard.edu">
			<cfif serverName contains "-test">
				 <cfset Application.serverrole ="test">
		    <cfelseif serverName contains "-dev">
				 <cfset Application.serverrole ="development">
			 <cfelse>
				 <cfset Application.serverrole ="production">
			</cfif>
			<!--- TODO: Choice of HUH or MCZ or biodiversity portal values here --->
			<cfif serverName contains "mczbase">
				<!--- MCZbase values --->
				<cfset Application.application_name = "MCZbase" />
				<!--- TODO: Set default user to limit to MCZ VPDs. --->
				<cfset Application.meta_description = "MCZbase, the database of the natural science collections of the Museum of Comparative Zoology, Harvard University." />
				<cfset Application.header_image_alt = "MCZ Kronosaurus logo with link to website" />
				<cfset Application.collection_url = "https://www.mcz.harvard.edu" />
				<cfset Application.institution_url = "https://www.mcz.harvard.edu" />
				<cfset Application.institution_link_text = "Museum of Comparative Zoology" />
				<cfset Application.old_institution_link_text = "Museum of Comparative Zoology - Harvard University" />
				<cfset Application.InstitutionBlurb = "Collections Database, Museum of Comparative Zoology, Harvard University" />
				<cfset Application.DataProblemReportEmail = "bhaley@oeb.harvard.edu" />
				<cfset Application.PageProblemEmail = "bhaley@oeb.harvard.edu" />
				<cfset Application.header_image_class = "mcz_logo_krono" />
				<cfset Application.header_image = "/shared/images/mcz_logo_white_left.png" />
				<cfset Application.old_header_image = "/images/krono.gif" />
				<cfif Application.serverrole EQ "production">
					 <!--- Production MCZbase values --->
				    <cfset Application.header_color = "##a51c30" />
					 <cfset Application.old_header_color = "##000000" />
				    <cfset Application.login_color = "##000000" />
				    <cfset Application.institutionlinkcolor = "##FFFFFF" />
				    <cfset Application.old_institutionlinkcolor = "##FFFFFF" />
				    <cfset Application.collectionlinkcolor = "##FFFFFF" />
					 <cfset Application.old_collectionlinkcolor = "##FF0000" />
				    <cfset Application.collection_link_text = "<span style='font-size: 1.1rem;'>MCZ</span><span class='headerCollectionTextSmall' >BASE</span><span class='headerCollectionText'>:The Database of the Zoological Collections</span>" /><!--- " --->
				    <cfset Application.old_collection_link_text = "<span style='font-size: 1.2rem;'>MCZ</span><span class='headerCollectionTextSmall' >BASE</span><span class='headerCollectionText'>:The Database of the Zoological Collections</span>" /><!--- " --->
				<cfelseif Application.serverrole EQ "development">
				    <cfset Application.header_color = "##CAEAAD" />
					 <cfset Application.old_header_color = "#Application.header_color#" />
				    <cfset Application.login_color = "##000066" />
				    <cfset Application.institutionlinkcolor = "##000066" />
				    <cfset Application.old_institutionlinkcolor = "##000066a" />
				    <cfset Application.collectionlinkcolor = "##94131C" />
				    <cfset Application.old_collectionlinkcolor = "##94131C" />
				    <cfset Application.collection_link_text = "<span style='font-size: 1.1rem;'>MCZ</span><span class='headerCollectionTextSmall'>BASE-DEV</span><span class='headerCollectionText'>:The Database of the Zoological Collections</span>" /><!--- " --->
				    <cfset Application.old_collection_link_text = "<span style='font-size: 1.2rem;'>MCZ</span><span class='headerCollectionTextSmall'>BASE-DEV</span><span class='headerCollectionText'>:The Database of the Zoological Collections</span>" /><!--- " --->
					<cfset Application.old_header_image = "/images/mcz_krono_logo.png" />
				<cfelse>
				    <cfset Application.header_color = "##ADE1EA" />
					 <cfset Application.old_header_color = "#Application.header_color#" />
				    <cfset Application.login_color = "##000066" />
				    <cfset Application.institutionlinkcolor = "##000066" />
				    <cfset Application.old_institutionlinkcolor = "##000066" />
				    <cfset Application.collectionlinkcolor = "##94131C" />
				    <cfset Application.old_collectionlinkcolor = "##94131C" />
				    <cfset Application.collection_link_text = "<span style='font-size: 1.1rem;'>MCZ</span><span class=""headerCollectionTextSmall"">BASE-TEST</span><span class=""headerCollectionText"">:The Database of the Zoological Collections</span>" /><!--- " --->
				    <cfset Application.old_collection_link_text = "<span style='font-size: 1.2rem;'>MCZ</span><span class=""headerCollectionTextSmall"">BASE-TEST</span><span class=""headerCollectionText"">:The Database of the Zoological Collections</span>" /><!--- " --->
					 <cfset Application.old_header_image = "/images/mcz_krono_logo.png" />
				</cfif>
			<cfelseif serverName contains "huh">
				<cfset Application.application_name = "HUHbase" />
				<!--- TODO: Set default user to limit to HUH VPDs. --->
				<cfset Application.meta_description = "HUHbase, the database of the natural science collections of the Harvard University Hebaria." />
				<cfset Application.header_image_alt = "logo with link to website" />
				<cfset Application.collection_url = "https://www.huh.harvard.edu" />
				<cfset Application.institution_url = "https://www.huh.harvard.edu" />
				<cfset Application.institution_link_text = "Harvard University Herbaria" />
				<cfset Application.old_institution_link_text = "Harvard University Herbaria" />
				<cfset Application.InstitutionBlurb = "Collections Database Harvard University Herbaria" />
				<cfset Application.DataProblemReportEmail = "bhaley@oeb.harvard.edu" />
				<!--- cfset Application.header_image_class = "mcz_logo_krono" />
				<cfset Application.header_image = "/shared/images/huh_logo_white_left.png" />
				<cfset Application.old_header_image = "/shared/images/huh_logo_white_left.png" / --->
				<cfset Application.header_image_class = "pr-1" />
				<cfset Application.header_image = "/shared/images/HUH_color_4-4-11.png" />
				<cfset Application.old_header_image = "/shared/images/HUH_color_4-4-11.png" />
				<cfif Application.serverrole EQ "production">
					 <!--- Production HUHbase values --->
				    <cfset Application.header_color = "##a51c30" />
					 <cfset Application.old_header_color = "##000000" />
				    <cfset Application.login_color = "##000000" />
				    <cfset Application.institutionlinkcolor = "##FFFFFF" />
				    <cfset Application.old_institutionlinkcolor = "##FFFFFF" />
				    <cfset Application.collectionlinkcolor = "##FFFFFF" />
					 <cfset Application.old_collectionlinkcolor = "##FF0000" />
				    <cfset Application.collection_link_text = "<span style='font-size: 1.1rem;'>HUH</span><span class='headerCollectionTextSmall' >BASE</span><span class='headerCollectionText'>:The Database of the Botanical Collections</span>" /><!--- " --->
				    <cfset Application.old_collection_link_text = "<span style='font-size: 1.2rem;'>HUH</span><span class='headerCollectionTextSmall' >BASE</span><span class='headerCollectionText'>:The Database of the Botanical Collections</span>" /><!--- " --->
				<cfelseif Application.serverrole EQ "development">
				    <cfset Application.header_color = "##FFE92E" />
					 <cfset Application.old_header_color = "#Application.header_color#" />
				    <cfset Application.login_color = "##000066" />
				    <cfset Application.institutionlinkcolor = "##000066" />
				    <cfset Application.old_institutionlinkcolor = "##000066a" />
				    <cfset Application.collectionlinkcolor = "##94131C" />
				    <cfset Application.old_collectionlinkcolor = "##94131C" />
				    <cfset Application.collection_link_text = "<span style='font-size: 1.1rem;'>HUH</span><span class='headerCollectionTextSmall'>BASE-DEV</span><span class='headerCollectionText'>:The Database of the Botanical Collections</span>" /><!--- " --->
				    <cfset Application.old_collection_link_text = "<span style='font-size: 1.2rem;'>HUH</span><span class='headerCollectionTextSmall'>BASE-DEV</span><span class='headerCollectionText'>:The Database of the Botanical Collections</span>" /><!--- " --->
				<cfelse>
				    <cfset Application.header_color = "##FFC12E" />
					 <cfset Application.old_header_color = "#Application.header_color#" />
				    <cfset Application.login_color = "##000066" />
				    <cfset Application.institutionlinkcolor = "##000066" />
				    <cfset Application.old_institutionlinkcolor = "##000066" />
				    <cfset Application.collectionlinkcolor = "##94131C" />
				    <cfset Application.old_collectionlinkcolor = "##94131C" />
				    <cfset Application.collection_link_text = "<span style='font-size: 1.1rem;'>HUH</span><span class=""headerCollectionTextSmall"">BASE-TEST</span><span class=""headerCollectionText"">:The Database of the Botanical Collections</span>" /><!--- " --->
				    <cfset Application.old_collection_link_text = "<span style='font-size: 1.2rem;'>HUH</span><span class=""headerCollectionTextSmall"">BASE-TEST</span><span class=""headerCollectionText"">:The Database of the Botanical Collections</span>" /><!--- " --->
				</cfif>
			<cfelseif serverName contains "biodiversity">
				<!--- placeholder for a combined biodiversity portal --->
				<cfset Application.meta_description = "Data portal for the the natural science collections of Harvard University." />
				<cfset Application.header_image_alt = "logo with link to website" />
				<cfset Application.collection_url = "https://www.mcz.harvard.edu" />
				<cfset Application.institution_url = "https://www.mcz.harvard.edu" />
				<cfset Application.institution_link_text = "Museum of Comparative Zoology" />
				<cfset Application.old_institution_link_text = "Museum of Comparative Zoology - Harvard University" />
				<cfset Application.InstitutionBlurb = "Collections Database, Museum of Comparative Zoology, Harvard University" />
				<cfset Application.DataProblemReportEmail = "bhaley@oeb.harvard.edu" />
				<cfset Application.header_image_class = "mcz_logo_krono" />
				<cfset Application.header_image = "/shared/images/mcz_logo_white_left.png" />
				<cfset Application.old_header_image = "/images/krono.gif" />
				<cfif Application.serverrole EQ "production">
				    <cfset Application.header_color = "##a51c30" />
					 <cfset Application.old_header_color = "##000000" />
				    <cfset Application.login_color = "##000000" />
				    <cfset Application.institutionlinkcolor = "##FFFFFF" />
				    <cfset Application.old_institutionlinkcolor = "##FFFFFF" />
				    <cfset Application.collectionlinkcolor = "##FFFFFF" />
					 <cfset Application.old_collectionlinkcolor = "##FF0000" />
				    <cfset Application.collection_link_text = "<span style='font-size: 1.1rem;'>MCZ</span><span class='headerCollectionTextSmall' >BASE</span><span class='headerCollectionText'>:The Database of the Zoological Collections</span>" /><!--- " --->
				    <cfset Application.old_collection_link_text = "<span style='font-size: 1.2rem;'>MCZ</span><span class='headerCollectionTextSmall' >BASE</span><span class='headerCollectionText'>:The Database of the Zoological Collections</span>" /><!--- " --->
				<cfelseif Application.serverrole EQ "development">
				    <cfset Application.header_color = "##CAEAAD" />
					 <cfset Application.old_header_color = "#Application.header_color#" />
				    <cfset Application.login_color = "##000066" />
				    <cfset Application.institutionlinkcolor = "##000066" />
				    <cfset Application.old_institutionlinkcolor = "##000066a" />
				    <cfset Application.collectionlinkcolor = "##94131C" />
				    <cfset Application.old_collectionlinkcolor = "##94131C" />
				    <cfset Application.collection_link_text = "<span style='font-size: 1.1rem;'>MCZ</span><span class='headerCollectionTextSmall'>BASE-DEV</span><span class='headerCollectionText'>:The Database of the Zoological Collections</span>" /><!--- " --->
				    <cfset Application.old_collection_link_text = "<span style='font-size: 1.2rem;'>MCZ</span><span class='headerCollectionTextSmall'>BASE-DEV</span><span class='headerCollectionText'>:The Database of the Zoological Collections</span>" /><!--- " --->
				<cfelse>
				    <cfset Application.header_color = "##ADE1EA" />
					 <cfset Application.old_header_color = "#Application.header_color#" />
				    <cfset Application.login_color = "##000066" />
				    <cfset Application.institutionlinkcolor = "##000066" />
				    <cfset Application.old_institutionlinkcolor = "##000066" />
				    <cfset Application.collectionlinkcolor = "##94131C" />
				    <cfset Application.old_collectionlinkcolor = "##94131C" />
				    <cfset Application.collection_link_text = "<span style='font-size: 1.1rem;'>MCZ</span><span class=""headerCollectionTextSmall"">BASE-TEST</span><span class=""headerCollectionText"">:The Database of the Zoological Collections</span>" /><!--- " --->
				    <cfset Application.old_collection_link_text = "<span style='font-size: 1.2rem;'>MCZ</span><span class=""headerCollectionTextSmall"">BASE-TEST</span><span class=""headerCollectionText"">:The Database of the Zoological Collections</span>" /><!--- " --->
				</cfif>
			</cfif>
			<!--- shared configuration information for Harvard deployment --->
			<cfset Application.webDirectory = "/var/www/html/arctos" />
			<cfset Application.SpecimenDownloadPath = "/var/www/html/arctos/download/" />
			<cfset Application.DownloadPath = "/var/www/html/arctos/download/" />
			<cfset Application.bugReportEmail = "bhaley@oeb.harvard.edu" />
			<cfset Application.technicalEmail = "bhaley@oeb.harvard.edu" />
			<cfset Application.mapHeaderUrl = "#Application.serverRootUrl#/images/nada.gif" />
			<cfset Application.mapFooterUrl = "#Application.serverRootUrl#/bnhmMaps/BerkMapFooter.html" />
			<cfset Application.genBankPrid = "" />
			<cfset Application.genBankUsername="" />
			<cfset Application.convertPath = "/usr/bin/convert" />
			<cfset Application.BerkeleyMapperConfigFile = "/bnhmMaps/MCZConfig.xml" />

			<cfset Application.stylesheet = "style.css" />
		</cfif>
		<cfreturn true />
	</cffunction>

	<!-------------------------------------------------------------->

	<!---
		sessionStats counts sessions started and sessions that came back after their first request,
		for the Admin Panel.  Created on first use, as onApplicationStart doesn't run again when new code
		is deployed.

		@return Application.sessionStats, with since, the time counting began, and started and returned,
			java.util.concurrent.atomic.AtomicLong counters.
	--->
	<cffunction name="sessionStats" access="private" output="false" returntype="struct">
		<cfif NOT structKeyExists(Application, "sessionStats")>
			<cflock scope="Application" type="exclusive" timeout="5">
				<cfif NOT structKeyExists(Application, "sessionStats")>
					<cfset Application.sessionStats = {
						since = now(),
						started = createObject("java", "java.util.concurrent.atomic.AtomicLong").init(javaCast("long", 0)),
						returned = createObject("java", "java.util.concurrent.atomic.AtomicLong").init(javaCast("long", 0))
					}>
				</cfif>
			</cflock>
		</cfif>
		<cfreturn Application.sessionStats>
	</cffunction>
	<!-------------------------------------------------------------->

	<!---
		refuseRequest shows /errors/forbidden.cfm within this request, as a forward or redirect to it would
		start a second session for a client without a session cookie, and ends the request.  The page's
		Access_Violation is passed to onError here, as thrown out of onRequestStart ColdFusion would wrap it
		as an event handler exception, losing its message and the 403.
	--->
	<cffunction name="refuseRequest" access="private" output="true" returntype="void">
		<cftry>
			<cfinclude template="/errors/forbidden.cfm">
		<cfcatch type="Access_Violation">
			<cfset onError(cfcatch, "onRequestStart")>
		</cfcatch>
		</cftry>
		<cfabort />
	</cffunction>
	<!-------------------------------------------------------------->

	<cffunction name="onSessionStart" output="false">
		<!--- only initSession's file: refuseRequest's page includes /shared/functionLib.cfm into this
			component, which would redeclare functions of /includes/functionLib.cfm --->
		<cfinclude template="/shared/loginFunctions.cfm" runOnce="true">
		<cfset initSession() />
		<!--- onSessionStart runs ahead of onRequestStart in the same request --->
		<cfset request.sessionIsNew = true>
		<cfset session.setMaxInactiveInterval(javaCast("long", variables.NEW_SESSION_SECONDS))>
		<cfset sessionStats().started.incrementAndGet()>
	</cffunction>
	<!-------------------------------------------------------------->

	<cffunction name="onRequestStart" returnType="boolean" output="true">
		<cfset var healthCheck = "">
		<cfset var healthCheck_result = "">
		<!--- healthy when ColdFusion answers and the database responds, as when the check loaded / --->
		<cfif variables.isHealthCheck>
			<cftry>
				<cfquery name="healthCheck" datasource="cf_dbuser" result="healthCheck_result" timeout="5">
					SELECT 1 FROM dual
				</cfquery>
				<cfcontent type="text/plain" reset="true">OK
			<cfcatch>
				<cfheader statuscode="503" statustext="Service Unavailable">
				<cfcontent type="text/plain" reset="true">Database not responding
			</cfcatch>
			</cftry>
			<cfreturn false />
		</cfif>
		<!--- uncomment for a break from googlebot ---->
		<!----
			<cfif cgi.HTTP_USER_AGENT contains "bot" or cgi.HTTP_USER_AGENT contains "slurp" or cgi.HTTP_USER_AGENT contains "spider">
			<cfheader statuscode="503" statustext="Service Temporarily Unavailable"/>
			<cfheader name="retry-after" value="3600"/>
			Down for maintenance
			<cfreturn false>
			<cfabort>
			</cfif>
			---->
		<cfif not isdefined("application.blacklist")>
			<cfset application.blacklist="" />
		</cfif>
		<!--- Refusals below show their page within this request (see refuseRequest). --->
		<cfif listfindnocase(application.blacklist,clientAddress())>
			<!---cfif cgi.script_name is not "/errors/gtfo.cfm"--->
			<cfif replace(cgi.script_name,"//","/") is not "/errors/gtfo.cfm" and replace(cgi.script_name,"//","/") is not "/bkh.cfm">
				<cfinclude template="/errors/gtfo.cfm">
				<cfabort />
			</cfif>
		</cfif>
		<cfparam name="request.fixAmp" type="boolean" default="false">
		<cfif (NOT request.fixAmp) AND (findNoCase("&amp;", cgi.query_string ) gt 0)>
			<cfscript>
				request.fixAmp = true;
				queryString = replace(cgi.query_string, "&amp;", "&", "all");
				getPageContext().forward(cgi.script_Name & "?" & queryString);
			</cfscript>
			<cfabort />
		<cfelse>
			<cfscript>StructDelete(request, "fixAmp");</cfscript>
		</cfif>
		<!--- no session scope here; the page forwarded to runs onRequestStart again with its own --->
		<cfif listFindNoCase(variables.FORWARD_ONLY_PAGES, cgi.script_name) GT 0>
			<cfreturn true />
		</cfif>
		<cfif not isdefined("session.roles")>
			<cfinclude template="/shared/loginFunctions.cfm" runOnce="true">
			<cfset initSession() />
		</cfif>
		<!--- A client that never sends the session back, such as a crawler that keeps no cookies, never
			reaches this, and its session ends after NEW_SESSION_SECONDS. --->
		<cfif NOT structKeyExists(request, "sessionIsNew")>
			<cfset session.setMaxInactiveInterval(javaCast("long", variables.SESSION_SECONDS))>
			<!--- locked as a page's AJAX requests come back together --->
			<cfif NOT structKeyExists(session, "sessionReturned")>
				<cflock scope="Session" type="exclusive" timeout="5">
					<cfif NOT structKeyExists(session, "sessionReturned")>
						<cfset session.sessionReturned = true>
						<cfset sessionStats().returned.incrementAndGet()>
					</cfif>
				</cflock>
			</cfif>
		</cfif>
		<cfset currentPath=GetDirectoryFromPath(GetTemplatePath()) />
		<cfif currentPath contains "/CustomTags/" OR
			currentPath contains "/binary_stuff/" OR
			currentPath contains "/log/">
			<cfset url.ref=replace(currentPath,application.webDirectory,"") />
			<cfset refuseRequest()>
		</cfif>
		<!--- Scheduled tasks run only for the ColdFusion scheduler, which calls them from this server, or for a
			global_admin running one by hand: they send email and change data. --->
		<cfif currentPath contains "/ScheduledTasks/" AND NOT isRequestFromThisServer()
				AND NOT (isdefined("session.roles") AND listFindNoCase(session.roles, "global_admin"))>
			<cfset refuseRequest()>
		</cfif>
		<!--- protect "us" directories --->
		<cfif NOT isRequestFromThisServer() and
			(not isdefined("session.roles") or session.roles is "public" or len(session.roles) is 0) and
			(currentPath contains "/Admin/" or
			currentPath contains "/ALA_Imaging/" or
			currentPath contains "/Bulkloader/" or
			currentPath contains "/fix/" or
			currentPath contains "/picks/" or
			currentPath contains "/tools/")>
			<cfset r=replace(#currentPath#,#application.webDirectory#,"") />
			<cfset refuseRequest()>
		</cfif>
		<!--- coldfusion_user distinguishes a logged in account from a visitor: setDbUser gives
			anything without it the portal's Oracle account. --->
		<cfif (currentPath contains "/Reports/") and
			(not isdefined("session.roles") or not listFindNoCase(session.roles,"coldfusion_user"))>
			<cfset refuseRequest()>
		</cfif>
		<cfreturn true />
	</cffunction>

</cfcomponent>
