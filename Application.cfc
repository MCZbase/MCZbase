<!---
Application.cfc
 
TODO: Confirm years
Copyright 2008-2017 Contributors to Arctos
Copyright 2008-2020 President and Fellows of Harvard College

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
		<cfset showErr=1 />
		<cfif isdefined("exception.type") and exception.type eq "coldfusion.runtime.AbortException">
                         <cfif  Application.serverRootUrl contains "-test">
                                <cfset showErr=1 />
                        <cfelse>
                                <cfset showErr=0 />
                        </cfif>

			<cfreturn />
		</cfif>
		<cfif StructKeyExists(form,"C0-METHODNAME")>
			<!--- cfajax calling cfabort --->
                         <cfif  Application.serverRootUrl contains "-test">
                                <cfset showErr=1 />
                        <cfelse>
                                <cfset showErr=0 />
                        </cfif>

			<cfreturn />
		</cfif>
		<cfif showErr is 1>
			<cfsavecontent variable="errortext">
				<CFIF isdefined("CGI.HTTP_X_Forwarded_For") and len(CGI.HTTP_X_Forwarded_For) gt 0>
					<CFSET ipaddress=CGI.HTTP_X_Forwarded_For />
				<CFELSEif  isdefined("CGI.Remote_Addr") and len(CGI.Remote_Addr) gt 0>
					<CFSET ipaddress=CGI.Remote_Addr />
				<cfelse>
					<cfset ipaddress='unknown' />
				</CFIF>
				<cfoutput>
					<p>
						ipaddress:
						<a href="http://network-tools.com/default.asp?prog=network&host=#ipaddress#">#ipaddress#</a>
					</p>
					(
					<a href="https://mczbase.mcz.harvard.edu/Admin/blacklist.cfm?action=ins&ip=#ipaddress#">add to blocklist</a>
					)
					<cfif isdefined("session.username")>
						<br>
						Username: #session.username#
					</cfif>
					<cfif isdefined("exception.Sql")>
						<p>Sql: #exception.Sql#</p>
					</cfif>
				</cfoutput>
				<hr>
				Exceptions:
				<hr>
				<cfdump var="#exception#" label="exception" />
				<hr>
				<cfif isdefined("session")>
					Session Dump:
					<hr>
					<cfdump var="#session#" label="session" />
				</cfif>
				Client Dump:
				<hr>
				<cfdump var="#client#" label="client" />
				<hr>
				Form Dump:
				<hr>
				<cfdump var="#form#" label="form" />
				<hr>
				URL Dump:
				<hr>
				<cfdump var="#url#" label="url" />
				CGI Dump:
				<hr>
				<cfdump var="#CGI#" label="CGI" />
			</cfsavecontent>

			<cfif  Application.serverRootUrl contains "harvard.edu">
				<cfif isdefined("session.username") and
				(
				#session.username# is "mkennedy" or
				#session.username# is "mole" or
				#session.username# is "heliumcell"
				)>
				<cfoutput>#errortext#</cfoutput>
				</cfif>
			</cfif>
			<!---cfoutput>#errortext#</cfoutput--->
			<cfif isdefined("exception.errorCode") and exception.errorCode is "403">
				<cfset subject="locked form" />
			<cfelse>
				<cfif isdefined("exception.detail")>
					<cfif exception.detail contains "[Macromedia][Oracle JDBC Driver][Oracle]ORA-00600">
						<cfset subject="[Macromedia][Oracle JDBC Driver][Oracle]ORA-00600" />
					<cfelse>
						<cfset subject="#exception.detail#" />
					</cfif>
				<cfelse>
					<cfset subject="Unknown Error" />
				</cfif>
			</cfif>
			<!---cfmail subject="Error" to="#Application.PageProblemEmail#" from="SomethingBroke@#Application.fromEmail#" type="html">
				#subject# #errortext#
			</cfmail--->
			<table cellpadding="10">
				<tr>
					<td valign="top"><img src="/images/blowup.gif"></td>
					<td>
						<font color="##FF0000" size="+1">
							<strong>An error occurred while processing this page!</strong>
						</font>
						<cfif isdefined("exception.message")>
							<br>
							<i>
								<cfoutput>
									#exception.message#
									<cfif isdefined("exception.detail")>
										<br>
										#exception.detail#
									</cfif>
								</cfoutput>
							</i>
						</cfif>
						<p>
							This message has been logged. Please select
							<a href="/info/bugs.cfm">“Feedback/Report Errors”</a>
							below to submit a bug report and include the error message above and any other info that might help us to resolve this problem.
						</p>
					</td>
				</tr>
			</table>
			<cfinclude template="/includes/_footer.cfm">
		</cfif>
		<cfreturn />
	</cffunction>

	<!-------------------------->
	<cffunction name="onApplicationStart" returnType="boolean" output="false">
		<cfscript>
			serverName = CreateObject("java", "java.net.InetAddress").getLocalHost().getHostName();
		</cfscript>
		<cfset Application.serverName=serverName /><!--- Store the server name returned away for debugging --->
		<cfif serverName is "web.arctos.database.museum">
			<cfset serverName="arctos.database.museum" />
		</cfif>
		<!--- In VM environment, how java resolves getLocalHost().getHostName() changes in ways outside our control.  --->
  		<!--- So, make sure that we are handling the cases where only the unqualified local name is returned. ---> 
		<cfif serverName is "mczbase-prd.rc.fas.harvard.edu" or serverName is "mczbase-prd" or serverName is "mczbase-prd1" or serverName is "mczbase-prd1.rc.fas.harvard.edu">
			<cfset serverName="mczbase.mcz.harvard.edu" />
		</cfif>
		<cfif serverName is "mczbase-dev">
			<cfset serverName="mczbase-dev.rc.fas.harvard.edu" />
		</cfif>
		<cfif serverName is "mczbase-test">
			<cfset serverName="mczbase-test.rc.fas.harvard.edu" />
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
		<cfset Application.genBankPwd= "" />
		<cfset Application.allowed_profile= "" />
		<cfset Application.allowed_tablespace= "" />
		<cfquery name="cf_global_settings" datasource="uam_god">
			select gmap_api_key, google_site_key, google_uacct, bugzilla_to_email, bugzilla_from_email, genbank_password, allowed_profile, allowed_tablespace
			from cf_global_settings
			where rownum < 2
		</cfquery>
		<cfloop query="cf_global_settings">
			<cfset application.gmap_api_key="#cf_global_settings.gmap_api_key#" />
			<cfset application.g_sitekey="#cf_global_settings.google_site_key#">
			<cfset Application.Google_uacct = "#cf_global_settings.google_uacct#" />
			<cfset Application.bugzillaToEmail = "#cf_global_settings.bugzilla_to_email#" />
			<cfset Application.bugzillaFromEmail = "#cf_global_settings.bugzilla_from_email#" />
			<cfset Application.genBankPwd=encrypt("#cf_global_settings.genbank_password#","genbank") />
			<cfset Application.allowed_profile = "#cf_global_settings.allowed_profile#"/>
			<cfset Application.allowed_tablespace = "#cf_global_settings.allowed_tablespace#"/>
		</cfloop>

		<!---cfset Application.sessionTimeout=createTimeSpan(0,1,40,0) /--->
		<cfset Application.session_timeout=90 /><!--- in minutes --->
		<cfset Application.ajax_timeout=60 /><!--- in seconds, for ajax calls for search/browse --->
		<cfset Application.query_timeout=55 /><!--- in seconds, for cfquery for search/browse --->
		<cfset Application.short_timeout=5 /><!--- in seconds, for cfquery that should complete rapidly --->
		<cfset Application.serverRootUrl = "#Application.protocol#://#serverName#" />
		<cfset Application.user_login="user_login" />
		<cfset Application.max_pw_age = 365 />
		<cfset Application.fromEmail = "#serverName#" />
		<!--- Default header/style apperance --->
		<cfset Application.header_color = "##E7E7E7" />
		<cfset Application.header_image = "/images/genericHeaderIcon.gif" />
		<cfset Application.collection_url = "/" />
		<cfset Application.collection_link_text = "Error" />
		<cfset Application.institution_url = "/" />
		<cfset Application.stylesheet = "" />
		<cfset Application.institution_link_text = "Host configuration problem: #serverName# not recognized" />
		<cfset Application.meta_description = "Arctos is a biological specimen database." />
		<cfset Application.meta_keywords = "museum, collection, management, system" />
		<cfset Application.domain = replace(Application.serverRootUrl,"#Application.protocol#://",".") />
		<cfset Application.header_color = "##000066" />
		<cfset Application.institutionlinkcolor = "##FF0000" />
		<cfset Application.collectionlinkcolor = "##00FF00" />
		<cfset Application.serverrole ="unknown">
		<cfquery name="d" datasource="uam_god">
			select ip from blacklist where sysdate-LISTDATE<180
		</cfquery>
		<cfset Application.blacklist=valuelist(d.ip) />
		<cfif serverName contains "harvard.edu">
			<cfset Application.meta_description = "MCZbase, the database of the natural science collections of the Museum of Comparative Zoology, Harvard University." />
			<cfif serverName contains "-test">
				 <cfset Application.serverrole ="test">
			    <cfset Application.header_color = "##ADE1EA" />
			    <cfset Application.login_color = "##000066" />
			    <cfset Application.institutionlinkcolor = "##000066" />
			    <cfset Application.collectionlinkcolor = "##94131C" />
			    <cfset Application.collection_link_text = "MCZ</span><span class=""headerCollectionTextSmall"">BASE-TEST</span><span class=""headerCollectionText"">:The Database of the Zoological Collections" />
			    <cfset Application.header_image = "/images/mcz_krono_logo.png" />
		    <cfelseif serverName contains "-dev">
				 <cfset Application.serverrole ="development">
			    <cfset Application.header_color = "##CAEAAD" />
			    <cfset Application.login_color = "##000066" />
			    <cfset Application.institutionlinkcolor = "##000066" />
			    <cfset Application.collectionlinkcolor = "##94131C" />
			    <cfset Application.collection_link_text = "MCZ</span><span class=""headerCollectionTextSmall"">BASE-DEV</span><span class=""headerCollectionText"">:The Database of the Zoological Collections" />
			    <cfset Application.header_image = "/images/mcz_krono_logo.png" />
			 <cfelse>
				 <cfset Application.serverrole ="production">
                <!--- Production MCZbase values --->
			    <cfset Application.header_color = "##000000" />
			    <cfset Application.login_color = "##000000" />
			    <cfset Application.institutionlinkcolor = "##ffffff" />
			    <!--- cfset Application.collectionlinkcolor = "##A51C30" / --->
			    <cfset Application.collectionlinkcolor = "##FF0000" />
			    <cfset Application.collection_link_text = "MCZ</span><span class=""headerCollectionTextSmall"" >BASE</span><span class=""headerCollectionText"">:The Database of the Zoological Collections" />
			    <cfset Application.header_image = "/images/krono.gif" />
			</cfif>
			<cfset Application.collection_url = "http://www.mcz.harvard.edu" />
			<cfset Application.institution_url = "http://www.mcz.harvard.edu" />
			<cfset Application.institution_link_text = "Museum of Comparative Zoology - Harvard University" />
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
			<cfset Application.BerkeleyMapperConfigFile = "/bnhmMaps/UamConfig.xml" />

			<cfset Application.InstitutionBlurb = "Collections Database, Museum of Comparative Zoology, Harvard University" />
			<cfset Application.DataProblemReportEmail = "bhaley@oeb.harvard.edu" />
			<cfset Application.PageProblemEmail = "bhaley@oeb.harvard.edu" />
			<cfset Application.stylesheet = "style.css" />
		</cfif>
		<cfreturn true />
	</cffunction>

	<!-------------------------------------------------------------->

	<cffunction name="onSessionStart" output="false">
		<cfinclude template="/includes/functionLib.cfm">
		<cfset initSession() />
	</cffunction>
	<!-------------------------------------------------------------->

	<cffunction name="onRequestStart" returnType="boolean" output="true">
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
		<cfif listfindnocase(application.blacklist,cgi.REMOTE_ADDR)>
			<!---cfif cgi.script_name is not "/errors/gtfo.cfm"--->
			<cfif replace(cgi.script_name,"//","/") is not "/errors/gtfo.cfm" and replace(cgi.script_name,"//","/") is not "/bkh.cfm">
				<cfscript>getPageContext().forward("/errors/gtfo.cfm");</cfscript>
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
		<cfif not isdefined("session.roles")>
			<cfinclude template="/includes/functionLib.cfm">
			<cfset initSession() />
		</cfif>
		<cfset currentPath=GetDirectoryFromPath(GetTemplatePath()) />
		<cfif currentPath contains "/CustomTags/" OR
			currentPath contains "/binary_stuff/" OR
			currentPath contains "/log/">
			<cfset r=replace(currentPath,application.webDirectory,"") />
			<cflocation url="/errors/forbidden.cfm?ref=#r#" addtoken="false">
		</cfif>
		<!--- protect "us" directories --->
		<cfif (CGI.Remote_Addr is not "10.242.110.167") and
			(not isdefined("session.roles") or session.roles is "public" or len(session.roles) is 0) and
			(currentPath contains "/Admin/" or
			currentPath contains "/ALA_Imaging/" or
			currentPath contains "/Bulkloader/" or
			currentPath contains "/fix/" or
			currentPath contains "/picks/" or
			currentPath contains "/tools/" or
			currentPath contains "/ScheduledTasks/")>
			<cfset r=replace(#currentPath#,#application.webDirectory#,"") />
			<cfscript>getPageContext().forward("/errors/forbidden.cfm");</cfscript>
			<cfabort />
		</cfif>
		<cfreturn true />
	</cffunction>

</cfcomponent>
