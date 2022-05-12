<cfif not isdefined("headerPath")>
	<!---  if header has been included, headerPath will have a value --->
	<cfset pageTitle = "MCZbase: 404 Error: Resource not found">
	<cfinclude template="/shared/_header.cfm">
</cfif>
<cfoutput>
	<CFIF isdefined("CGI.HTTP_X_Forwarded_For") and len(CGI.HTTP_X_Forwarded_For) gt 0>
		<CFSET ipaddress=CGI.HTTP_X_Forwarded_For>
	<CFELSEif  isdefined("CGI.Remote_Addr") and len(CGI.Remote_Addr) gt 0>
		<CFSET ipaddress=CGI.Remote_Addr>
	<cfelse>
		<cfset ipaddress='unknown'>
	</CFIF>
	<cfset cTemp="">
	<cfif len(cgi.redirect_url) gt 0>
		<cfset cTemp=cgi.redirect_url>
	<cfelseif len(cgi.script_name) gt 0>
		<cfset cTemp=cgi.script_name>
	</cfif>
	<cfquery name="redir" datasource="cf_dbuser">
		select new_path
		from redirect
		where upper(old_path)=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(cTemp)#">
	</cfquery>
	<cfif redir.recordcount is 1>
		<cfheader statuscode="301" statustext="Moved permanently">
		<cfif left(redir.new_path,4) is "http">
			<cfheader name="Location" value="#redir.new_path#">
		<cfelse>
			<cfheader name="Location" value="#application.serverRootURL##redir.new_path#">
		</cfif>
		<cfabort>
	</cfif>
	<cfset nono="wp-admin,tipguide,userfiles,okey,@@version,w00tw00t,announce,php,cgi,ini,config,client,webmail,roundcubemail,roundcube,HovercardLauncher,README,cube,mail,board,zboard,phpMyAdmin,Diagnostics,connector,info_sub,fuseaction,_unselectableClass,phpunit,mysql,MyAdmin">
	<cfset fourohthree="dll,asp">
	<cfloop list="#cgi.redirect_url#" delimiters="./" index="i">
		<cfif listfindnocase(nono,i)>
			<cfinclude template="/errors/autoblacklist.cfm">
			<cfabort>
		</cfif>
		<cfif listfindnocase(fourohthree,i)>
			<cfset errm=i>
			<cfinclude template="/errors/403.cfm">
			<cfabort>
		</cfif>
	</cfloop>
	<cfif find('Fuzz Faster U Fool',cgi.http_user_agent) GT 0 >
		<cfinclude template="/errors/autoblacklist.cfm">
		<cfabort>
	</cfif>
	<cfif find('PetalBot',cgi.http_user_agent) GT 0 >
		<cfinclude template="/errors/autoblacklist.cfm">
		<cfabort>
	</cfif>
	<!--- log bad requests not otherwise handled --->
	<cfif isdefined("CGI.HTTP_X_Forwarded_For") and len(CGI.HTTP_X_Forwarded_For) gt 0>
		<cfset ipaddress=CGI.HTTP_X_Forwarded_For>
	<cfelseif  isdefined("CGI.Remote_Addr") and len(CGI.Remote_Addr) gt 0>
		<cfset ipaddress=CGI.Remote_Addr>
	<cfelse>
		<cfset ipaddress='unknown'>
	</cfif>
	<cflog text="[#cgi.request_method#][#cgi.redirect_url#][#cgi.script_name#][#cgi.query_string#] by: [#ipaddress#] user agent: [#cgi.http_user_agent#]" file="bad_requests" application="no">
	<!--- we don't have a redirect, and it's not on our hitlist, so 404 --->
<article class="container" id="content">
	<div class="row">
		<div class="col-8 mx-auto pt-5">
			<cfheader statuscode="404" statustext="Not found">
			<cfset title="404: not found">
			<h1 class="h2">
				404! The page you tried to access does not exist.
			</h1>
			<script type="text/javascript">
				var GOOG_FIXURL_LANG = 'en';
				var GOOG_FIXURL_SITE = 'http://arctos.database.museum/';
			</script>
			<script type="text/javascript" src="http://linkhelp.clients.google.com/tbproxy/lh/wm/fixurl.js"></script>
			<script type="text/javascript" language="javascript">
				function changeCollection () {
					jQuery.getJSON("/component/functions.cfc",
						{
							method : "changeexclusive_collection_id",
							tgt : '',
							returnformat : "json",
							queryformat : 'column'
						},
						function (d) {
							document.location='#cgi.REDIRECT_URL#';
						}
					);
				}
			</script>
			<cfset isGuid=false>
			<cfif len(cgi.REDIRECT_URL) gt 0 and cgi.redirect_url contains "guid">
				<cfset isGuid=true>
				<cfif session.dbuser is not "pub_usr_all_all">
					<cfquery name="yourcollid" datasource="cf_dbuser">
						select collection
						from cf_collection
						where DBUSERNAME=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.dbuser#">
					</cfquery>
					<p>
						<cfif len(session.roles) gt 0 and session.roles is not "public">
							If you are an operator, you may have to log out or ask your supervisor for more access.
						</cfif>
						You are accessing MCZbase through the #yourcollid.collection# portal, and cannot access specimen data in
						other collections. You may
						<span class="likeLink" onclick="changeCollection()">try again in the public portal</span>.
					</p>
				</cfif>
			</cfif>
			<p>
				If you followed a link from within MCZbase, please <a class="" href="/info/bugs.cfm">submit a bug report</a>
				containing any information that might help us resolve this issue.
			</p>
			<p>
				If you followed an external link, please use your back button and tell the webmaster that
				something is broken, or <a class="" href="/info/bugs.cfm">submit a bug report</a> telling us how you got this error.
				<ul class="list-group px-5">
					<li class="pb-1"><a href="/TaxonomySearch"> Search for Taxon Names (search form)</a></li>
					<li class="pb-1"><a href="/SpecimenUsage"> Search for Projects and Publications (search form)</a></li>
				</ul>
			</p>
			<p>
				If you're trying to find specimens, you may:
				<ul class="list-group px-5">
					<li class="pb-1"><a href="/SpecimenSearch">Search for specimens (search form)</a></li>
					<li class="pb-1">Access them by URLs of the format:
						#Application.serverRootUrl#/guid/{institution}:{collection}:{catnum}<br>
						Example: <i><a href="#Application.serverRootUrl#/guid/MCZ:Mamm:1">#Application.serverRootUrl#/guid/MCZ:Mamm:1</a></i>
					</li>
				</ul>
			</p>
			<p> Some specimens are restricted. You may <a href="/contact.cfm">contact us</a> for more information.
				Occasionally, a specimen is recataloged. You may be able to find them by using <i>Other Identifiers</i> in Specimen Search.
			</p>
			<cfif isGuid is false>
				<cfset sub="Dead Link">
				<cfset frm="dead.link">
			<cfelse>
				<cfset sub="Missing GUID">
				<cfset frm="dead.guid">
			</cfif>
			<cftry>
			<cfif frm NEQ "dead.link">
			<cfmail subject="#sub#" to="#Application.PageProblemEmail#" from="#frm#@#application.fromEmail#" type="html">
				A user found a dead link! The referring site was #cgi.HTTP_REFERER#.
				<cfif isdefined("CGI.script_name")>
					<br>The missing page is #Replace(CGI.script_name, "/", "")#
				</cfif>
				<cfif isdefined("cgi.REDIRECT_URL")>
					<br>cgi.REDIRECT_URL: #cgi.REDIRECT_URL#
				</cfif>
				<cfif isdefined("session.username")>
					<br>The username is #session.username#
				</cfif>
				<br>The IP requesting the dead link was <a href="http://network-tools.com/default.asp?prog=network&host=#ipaddress#">#ipaddress#</a>
				 - <a href="http://mczbase.mcz.harvard.edu/Admin/blacklist.cfm?action=ins&ip=#ipaddress#">blacklist</a>
				<br>This message was generated by #cgi.CF_TEMPLATE_PATH#.
				<hr><cfdump var="#cgi#">
			</cfmail>
			</cfif>
			<p>A message has been sent to the site administrator.</p>
			<cfcatch>
			<p>Error in sending mail to the site administrator.</p>
			</cfcatch>
			</cftry>
			<p>
				Use the menu in the header to continue navigating MCZbase.
			</p>
		</div>
	</div>
</article>
</cfoutput>
<cfif headerPath IS "includes">
	<cfinclude template="/includes/_footer.cfm">
<cfelse>
	<cfinclude template="/shared/_footer.cfm">
</cfif>
