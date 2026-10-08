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


<cfif variables.action is "manage">
<script type="text/javascript" language="javascript">
	function killMe(canned_id) {
		jQuery.getJSON("/component/functions.cfc",
			{
				method : "kill_canned_search",
				canned_id : canned_id,
				returnformat : "json",
				queryformat : 'column'
			},
			killMe_success
		);
	}
	function killMe_success (result) {
		if (IsNumeric(result)) {
			var e = "document.getElementById('tr" + result + "')";
			var el = eval(e);
			el.style.display='none';
		}else{
			alert(result);
		}
	}
</script>

<cfoutput>
        <div class="basic_box">
	<cfquery name="hasCanned" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	select SEARCH_NAME,URL,canned_id
	from cf_canned_search,cf_users
	where cf_users.user_id=cf_canned_search.user_id
	and username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
	order by search_name
</cfquery>
   
<cfif hasCanned.recordcount is 0>
 <p>You may save Specimen Results from searches on the home page for later reference.</p>
 <p>They will appear here when you have done so.</p>

<cfelse>

<table border>
	<tr>
		<td>&nbsp;</td>
		<td><strong>Name</strong></td>
		<td><strong>URL</strong></td>
		<td><strong>Email</strong></td>
	</tr>
<cfloop query="hasCanned">
	<tr id="tr#canned_id#">
		<td><img src="/images/del.gif" class="likeLink" onClick="killMe('#canned_id#');" border="0"></td>
		<td>#search_name#</td>
		<td>
			<a href="/saved/#search_name#">#Application.ServerRootUrl#/saved/#search_name#</a>
		</td>
		<td>
			<span class="likeLink" onclick="window.open('/tools/mailSaveSearch.cfm?canned_id=#canned_id#','_mail','height=300,width=400,resizable,scrollbars')">Mail</span>
		</td>
	</tr>
</cfloop>
</table>
    </div>
</cfif>
</cfoutput>
</cfif>
<cfinclude template="/includes/_footer.cfm">
