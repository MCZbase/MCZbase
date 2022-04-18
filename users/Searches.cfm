<cfset pageTitle="Saved Searches">
<cfinclude template="/shared/_header.cfm">

	<!--- TODO Rework remove function, remove treeAjax --->
	<script type='text/javascript' src='/includes/_treeAjax.js'></script>
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
	<cfquery name="hasCanned" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		SELECT SEARCH_NAME, URL, canned_id, execute
		FROM 
			cf_users
			left join cf_canned_search on  cf_users.user_id=cf_canned_search.user_id
		WHERE
			username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
		ORDER BY search_name
	</cfquery>
   
<cfif hasCanned.recordcount is 0>
	 <p>You may save Specimen Results from searches on the home page for later reference.</p>
 	<p>They will appear here when you have done so.</p>
<cfelse>

<table border>
	<tr>
		<td>&nbsp;</td>
		<td><strong>Name</strong></td>
		<td><strong>Short URL</strong></td>
		<td><strong>Search URL</strong></td>
		<td><strong>Email</strong></td>
	</tr>
<cfloop query="hasCanned">
	<tr id="tr#canned_id#">
		<td><img src="/images/del.gif" class="likeLink" onClick="killMe('#canned_id#');" border="0"></td>
		<td>#search_name#</td>
		<td>
			<a href="/saved/#search_name#">#Application.ServerRootUrl#/saved/#search_name#</a>
		</td>
			<td>#url#</td>
		<td>
			<span class="likeLink" onclick="window.open('/tools/mailSaveSearch.cfm?canned_id=#canned_id#','_mail','height=300,width=400,resizable,scrollbars')">Mail</span>
		</td>
	</tr>
</cfloop>
</table>
    </div>
</cfif>
</cfoutput>

<cfinclude template="/shared/_footer.cfm">
