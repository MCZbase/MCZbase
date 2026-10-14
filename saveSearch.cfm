<cfinclude template="/includes/_header.cfm">
<cfset title="Save Searches">
<cfparam name="url.action" default="">
<cfparam name="form.action" default="">
<cfparam name="form.returnURL" default="">
<cfparam name="form.srchName" default="">
<cfset variables.action = "nothing">
<cfif len(form.action) GT 0>
	<cfset variables.action = form.action>
<cfelseif len(url.action) GT 0>
	<cfset variables.action = url.action>
</cfif>
<cfif variables.action is "nothing">
<cf_showMenuOnly>
"Can" the dynamic page that you are currently on to quickly return later. Results are data-based, so you may get different results the next time you visit; only your criteria are stored.

<cfoutput>
    <div class="basic_box">
	<cfquery name="me" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		select user_id from cf_users where username=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
	</cfquery>
	<cfif len(#me.user_id#) is 0>
		<p>	
			You must <a href="/login.cfm">log in</a> to use this feature.
		</p>
		<cfabort>
	</cfif>
	<form name="canMe" method="post" action="saveSearch.cfm">
		<input type="hidden" name="action" value="saveThis">
		<input type="hidden" name="returnURL" value="#encodeForHtmlAttribute(form.returnURL)#">
		<label for="srchName">Name this Search</label>
		<input type="text" name="srchName" id="srchName" value="" class="reqdClr">
		<input type="submit" value="Can It!" class="savBtn"
   					onmouseover="this.className='savBtn btnhov'" onmouseout="this.className='savBtn'">
		<input type="button" value="Nevermind...." class="qutBtn" onClick="self.close();"
   					onmouseover="this.className='qutBtn btnhov'" onmouseout="this.className='qutBtn'">	
	</form>
	<script>
		document.getElementById('srchName').focus();
	</script>
	<p>
        <a href="/users/Searches.cfm">[ Manage ]</a></p>
        </div>   
</cfoutput>
</cfif>
<cfif variables.action is "saveThis">
	<!--- The search is saved for the logged in user, never for a user_id taken from the request,
		which let anyone put a search in another user's list.  Saved searches are shared by name through
		/saved/{name} (errors/missing.cfm), which doesn't depend on the owner.  The stored URL must be on
		this site, as go.cfm and /saved/ send visitors to it. --->
	<cfquery name="getSaver" datasource="cf_dbuser" result="getSaver_result">
		SELECT user_id
		FROM cf_users
		WHERE
			username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
	</cfquery>
	<cfset variables.saveProblem = "">
	<cfif cgi.request_method NEQ "POST" OR getSaver.recordcount NEQ 1>
		<cfset variables.saveProblem = "You must log in, and save the search from a search results page.">
	<cfelseif len(trim(form.srchName)) EQ 0>
		<cfset variables.saveProblem = "Give the search a name.">
	<cfelseif NOT (left(form.returnURL, len(Application.serverRootUrl) + 1) EQ Application.serverRootUrl & "/"
			OR (left(form.returnURL, 1) EQ "/" AND left(form.returnURL, 2) NEQ "//"))>
		<cfset variables.saveProblem = "Only searches on this site can be saved.">
	</cfif>
	<cfif len(variables.saveProblem) GT 0>
		<cfoutput><p class="text-danger">#encodeForHtml(variables.saveProblem)#</p></cfoutput>
	<cfelse>
		<cfquery name="i" datasource="cf_dbuser">
			insert into cf_canned_search (
			user_id,
			search_name,
			url
			) values (
			 <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getSaver.user_id#">,
			 <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(form.srchName)#">,
			 <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.returnURL#">)
		</cfquery>
		<script>self.close();</script>
	</cfif>
</cfif>
<cfinclude template="/includes/_footer.cfm">
