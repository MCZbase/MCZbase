<!--- Blocks the client making the current request.  Only for inclusion by pages that detect a
	probe; a direct request is answered as not found.

	The client's address comes from clientAddress() in /shared/component/clientAddress.cfc, which is
	also what Application.cfc onRequestStart compares with the blocklist.  It is cgi.remote_addr,
	unless that address is a trusted proxy (loopback, this server's own addresses, or
	Application.trustedProxies), in which case it is the rightmost X-Forwarded-For entry not added by
	a trusted proxy.  Proxies in the server's own subnets are trusted automatically.  Trusted proxies
	and Application.blockExemptAddresses are never stored, as blocking a proxy would block every
	user, and nothing is stored when X-Forwarded-For arrives from an address that is not a trusted
	proxy, as that address may be an unconfigured proxy; that case is emailed instead.

	TODO: When production moves to EC2 behind an AWS load balancer, cgi.remote_addr becomes the load
	balancer's private address, which changes as AWS replaces load balancer nodes.  Before that
	deployment:
	1. In Application.cfc onApplicationStart, set Application.trustedProxies to the subnets of the
		load balancer (the VPC CIDR, or the subnets the load balancer is placed in), e.g.
		"10.0.0.0/16".  IPv4 ranges and single addresses are accepted.  Without this every request
		appears to come from the load balancer, which is never stored, so nothing is blocked.
	2. Confirm that the load balancer appends the client to X-Forwarded-For (the AWS Application Load
		Balancer default, routing.http.xff_header_processing.mode = append), and that the instance
		accepts web traffic only from the load balancer's security group, so that no request can
		reach Apache directly with a forged header.
	3. If Apache's mod_remoteip is configured instead (RemoteIPHeader X-Forwarded-For with
		RemoteIPTrustedProxy for the load balancer's subnets), cgi.remote_addr is already the client
		and Application.trustedProxies can stay empty; check that mod_jk passes the rewritten
		address.
	4. After deployment, trigger a block from a known address (see the test steps for Redmine 1037)
		and check that the address recorded in the blocklist and in the email is the client's, not
		the load balancer's.
	5. Consider moving blocking to an AWS WAF IP set on the load balancer, fed from the blacklist
		table, so blocked requests never reach the instance. --->
<cfif getFileFromPath(getBaseTemplatePath()) EQ "autoblacklist.cfm">
	<cfheader statuscode="404" statustext="Not Found">
	<cfabort>
</cfif>
<!--- also included from Application.cfc onMissingTemplate, where the functions are already defined --->
<cfif NOT isDefined("clientAddress")>
	<cfinclude template="/shared/component/clientAddress.cfc" runOnce="true">
</cfif>
<cfset ipaddress = clientAddress()>
	<cftry>
		<cfset inserted = false>
		<cfset notInsertedReason = "">
		<cfif NOT isIpAddress(ipaddress)>
			<cfset notInsertedReason = "not a single IP address">
		<cfelseif isForwardedByUntrustedProxy()>
			<!--- fail safe: the address may be an unconfigured proxy, and blocking it would block everyone --->
			<cfset notInsertedReason = "the request carried X-Forwarded-For from #ipaddress#, which is not a trusted proxy; if a proxy or load balancer is at that address, add it to Application.trustedProxies">
		<cfelseif isBlockExempt(ipaddress)>
			<!--- blocking a proxy or this server would block every user --->
			<cfset notInsertedReason = "exempt (this server, a trusted proxy, or an exempt address)">
		<cfelse>
			<cfquery name="d" datasource="uam_god">
				INSERT INTO mczbase.blacklist 
					(ip) 
				VALUES 
					(<cfqueryparam CFSQLTYPE="CF_SQL_VARCHAR" value="#ipaddress#">)
			</cfquery>
			<cfset inserted = true>
			<cfset application.blacklist=listappend(application.blacklist,ipaddress)>
		</cfif>
		<cfmail subject="Autoblacklist Success" to="#Application.PageProblemEmail#" from="blacklisted@#application.fromEmail#" type="html">
			MCZbase automatically blacklisted IP
			<cfif inserted>
			<a href="http://network-tools.com/default.asp?prog=network&host=#encodeForUrl(ipaddress)#">#encodeForHtml(ipaddress)#</a>
			- <a href="#application.serverRootUrl#/Admin/blacklist.cfm">blocklist</a>
			<cfelse>
				Not added to blacklist table: #encodeForHtml(ipaddress)#, #encodeForHtml(notInsertedReason)#
			</cfif>
			<br>Remote address: #encodeForHtml(cgi.remote_addr)#, forwarded for: #encodeForHtml(cgi.http_x_forwarded_for)#
			<p></p>
			<!--- No cgi, url, form or session dumps: the Cookie header carries the CFID, which decrypts
				session.epw, and forms may carry passwords. --->
			<br>Page: #encodeForHtml(cgi.script_name)#
			<br>Query string: #encodeForHtml(REReplaceNoCase(cgi.query_string, "((pass|pwd|password|token|cfid|cftoken|jsessionid)[a-z_]*=)[^&]*", "\1[redacted]", "all"))#
			<br>Referrer: #encodeForHtml(cgi.http_referer)#
			<br>User agent: #encodeForHtml(cgi.http_user_agent)#
			<cfif isDefined("session.username")>
				<br>Username: #encodeForHtml(session.username)#
			</cfif>
		</cfmail>
		<cfinclude template="/errors/gtfo.cfm">
		<script>
			try{document.getElementById('loading').style.display='none';}catch(e){}
		</script>
		<cfabort>
		<cfcatch>
			<cfmail subject="Autoblacklist Fail" to="#Application.PageProblemEmail#" from="blfail@#application.fromEmail#" type="html">
				Auto-blacklisting failed.
				<br>
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
				<br>The IP requesting the dead link was <a href="http://network-tools.com/default.asp?prog=network&host=#encodeForUrl(ipaddress)#">#encodeForHtml(ipaddress)#</a>
				 - <a href="#application.serverRootUrl#/Admin/blacklist.cfm">blocklist</a>
				<br>This message was generated by #cgi.CF_TEMPLATE_PATH#.
				<br>Query string: #encodeForHtml(REReplaceNoCase(cgi.query_string, "((pass|pwd|password|token|cfid|cftoken|jsessionid)[a-z_]*=)[^&]*", "\1[redacted]", "all"))#
				<br>User agent: #encodeForHtml(cgi.http_user_agent)#
			</cfmail>
		</cfcatch>
	</cftry>
