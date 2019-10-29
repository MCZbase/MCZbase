
<cfset pageTitle="Save Searches">
<cfinclude template="/includes/_header.cfm">

<cfif #action# is "nothing">



<cfoutput>
    <div class="container mb-3">
		<div class="row">

	<form name="canMe" method="post" action="/saveSearch.cfm">
		<input type="hidden" name="action" value="saveThis">
		<input type="hidden" name="user_id" value="#me.user_id#">
		<input type="hidden" name="returnURL" value="#returnURL#">
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
        <a href="/saveSearch.cfm?action=manage">[ Manage ]</a></p>
        </div>   
		</div>
</cfoutput>
</cfif>
<cfif #action# is "saveThis">
<cfquery name="i" datasource="cf_dbuser">
	insert into cf_canned_search (
	user_id,
	search_name,
	url
	) values (
	 #user_id#,
	 '#srchName#',
	 '#returnURL#')
</cfquery>
<script>self.close();</script>
</cfif>


<cfif #action# is "manage">
<!---<script type='text/javascript' src='/includes/_treeAjax.js'></script>--->
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
<div class="container">
	<div class="row my-3">
		
	<cfquery name="hasCanned" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select SEARCH_NAME,URL,canned_id
	from cf_canned_search,cf_users
	where cf_users.user_id=cf_canned_search.user_id
	and username = '#session.username#'
	order by search_name
</cfquery>
   
<cfif hasCanned.recordcount is 0>
	<div class="col-lg-8 col-md-8 col-sm-12 my-3">
	<h2> Save your search parameters</h2>
 <p>You may save Specimen Results from searches on the home page for later reference.</p>
 <p>They will appear here when you have done so.</p>
	</div>
<cfelse>
<h2>Saved Searches</h2>
<table class="table mb-3">
  <thead class="jqx-widget-header">
    <tr>
      <th scope="col">Delete?</th>
      <th scope="col">Name</th>
      <th scope="col">URL</th>
      <th scope="col">Email</th>
    </tr>
  </thead>
  <tbody>
<cfloop query="hasCanned">
	<tr id="tr#canned_id#">
	<td><a href="##" onClick="killMe('#canned_id#');" class="pl-4"><i class="far fa-trash-alt"></i></a></td>
		<td>#search_name#</td>
		<td><a href="/saved/#search_name#">#Application.ServerRootUrl#/saved/#search_name#</a></td>
		<td><span class="likeLink" onclick="window.open('/tools/mailSaveSearch.cfm?canned_id=#canned_id#','_mail','height=300,width=400,resizable,scrollbars')">Mail</span></td>
	</tr>
</cfloop>
  </tbody>
</table>
 <div class="bottom-spacer">
	</div>

</cfif>
	</div>
</div>
</cfoutput>
</cfif>
<cfinclude template="/includes/_footer.cfm">