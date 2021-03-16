<cfset pageTitle = "Manage Blocklist">
<cfinclude template="/shared/_header.cfm">
<cfoutput>
	<main class="container py-3" id="content">
		<h2 class="h3">Manage Blocklist</h2>
		<cfif not isdefined("action")><cfset action=""></cfif>
		<cfswitch expression="#action#">
			<cfcase value="all">
				<!--- list all ip addresses on the block list and reload the application variable --->
				<form name="i" method="post" action="/Admin/blacklist.cfm">
					<div class="row">
						<div class="col-12 col-md-6">
							<input type="hidden" name="action" value="ins">
							<label for="ip" class="data-entry-label">IP address to block</label>
							<input type="text" name="ip" id="ip" class="data-entry-input" placeholder="0.0.0.0">
						</div>
						<div class="col-12 col-md-6">
							<label for="addbutton" class="data-entry-label" aria-hidden="true">&nbsp;</label>
							<input type="submit" id="addbutton" value="Add to blocklist" class="btn btn-xs btn-primary">
						</div>
					</div>
				</form>
				<cfquery name="all" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select ip, to_char(listdate,'YYYY-MM-DD') as listdate
					from blacklist 
					order by to_number(replace(ip,'.'))
				</cfquery>
				<cfset application.blacklist=valuelist(all.ip)>
				<h3 class="h4">The application.blacklist has been reloaded</h3>
				<h3 class="h4">All Blocked IP Addresses (#d.recordcount#)</h3>
				<cfloop query="all">
					<br>#ip# <a href="blacklist.cfm?action=del&ip=#ip#">Remove</a>
					<a href="http://whois.domaintools.com/#ip#" target="_blank">whois: #ip#</a>
				</cfloop>
				<ul>
					<cfif all.recordcount EQ 0>
						<li>None</li>
					<cfelse>
						<cfloop query="all">
							<li>
								#ip# added on #listdate#
								<a href="/Admin/blacklist.cfm?action=del&ip=#ip#">Remove</a> from blocklist. 
								<a href="http://whois.domaintools.com/#ip#" target="_blank">whois: #ip#</a>
							</li>
						</cfloop>
					</cfif>
				</ul>
			</cfcase>
			<cfcase value="ins">
				<!--- add an ip address to the block list --->
				<cftry>
				   <cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		   		   insert into blacklist 
							(ip) 
						values 
							(<cfqueryparam CFSQLTYPE="CF_SQL_VARCHAR" value="#trim(ip)#">)
			  	   </cfquery>
	      		<cfset application.blacklist=listappend(application.blacklist,trim(ip))>
					<h2 class="h3">Added specified IP address to the blocklist</h2>
					<div>
				   	<a href="/Admin/blacklist.cfm">List recent/local blocked addresses</a>.
				   	<a href="/Admin/blacklist.cfm?action=all">List all blocked addresses</a>.
					</div>
				<cfcatch>
					<cfdump var=#cfcatch#>
				</cfcatch>
				</cftry>
			</cfcase>
			<cfcase value="del">
				<!--- remove an ip address from the block list --->
				<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					delete from blacklist 
					where ip = <cfqueryparam CFSQLTYPE="CF_SQL_VARCHAR" value="#ip#">
				</cfquery>
	   		<cfset application.blacklist=ListDeleteAt(application.blacklist,ListFind(application.blacklist,trim(ip)))>
				<h2 class="h3">Removed specified IP address from the blocklist</h2>
				<div>
				  	<a href="/Admin/blacklist.cfm">List recent/local blocked addresses</a>.
				  	<a href="/Admin/blacklist.cfm?action=all">List all blocked addresses</a>.
				</div>
			</cfcase>
			<cfdefaultcase>
				<!--- show recent and local additions to the block list --->
				<form name="i" method="post" action="/Admin/blacklist.cfm">
					<div class="row">
						<div class="col-12 col-md-6">
							<input type="hidden" name="action" value="ins">
							<label for="ip" class="data-entry-label">IP address to block</label>
							<input type="text" name="ip" id="ip" class="data-entry-input" placeholder="0.0.0.0">
						</div>
						<div class="col-12 col-md-6">
							<label for="addbutton" class="data-entry-label" aria-hidden="true">&nbsp;</label>
							<input type="submit" id="addbutton" value="Add to blocklist" class="btn btn-xs btn-primary">
						</div>
					</div>
				</form>
				<cfquery name="last30" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select ip, to_char(listdate,'YYYY-MM-DD') as listdate, UTL_INADDR.get_host_name(ip) as hostname from blacklist 
					where listdate > sysdate - 30
					order by ip
				</cfquery>
				<h3 class="h4">Addresses blocked in the last 30 days</h3>
				<ul>
					<cfif last30.recordcount EQ 0>
						<li>None</li>
					<cfelse>
						<cfloop query="last30">
							<li>
								#ip# added on #listdate# #hostname# 
								<a href="/Admin/blacklist.cfm?action=del&ip=#ip#">Remove</a> from blocklist.
								<a href="http://whois.domaintools.com/#ip#" target="_blank">whois: #ip#</a>
							</li>
						</cfloop>
					</cfif>
				</ul>
				<cfquery name="localaddr" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select ip, to_char(listdate,'YYYY-MM-DD') as listdate, UTL_INADDR.get_host_name(ip) as hostname from blacklist 
					where ip like '140.247.%' or ip like '10.255.%'
					order by ip
				</cfquery>
				<h3 class="h4">Blocked Harvard Addresses</h3>
				<ul>
					<cfif localaddr.recordcount EQ 0>
						<li>None</li>
					<cfelse>
						<cfloop query="localaddr">
							<li>
								#ip# added on #listdate# #hostname# 
								<a href="/Admin/blacklist.cfm?action=del&ip=#ip#">Remove</a> from blocklist.
								<a href="http://whois.domaintools.com/#ip#" target="_blank">whois: #ip#</a>
							</li>
						</cfloop>
					</cfif>
				</ul>
				<div>
					<a href="/Admin/blacklist.cfm?action=all">List All</a> (Reloads application.blacklist)
				</div>
			</cfdefaultcase>
		</cfswitch>
	</main>
</cfoutput>
<cfinclude template="/shared/_footer.cfm">
