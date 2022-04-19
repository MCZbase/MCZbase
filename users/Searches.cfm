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
	<main class="container py-3" id="content" >
		<section class="row border rounded my-2">
			<h1 class="h2">Saved Searches for #session.username#</h1>
			<cfquery name="getSavedSearches" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getSavedSearches_result">
				SELECT SEARCH_NAME, URL, canned_id, execute
				FROM 
					cf_users
					left join cf_canned_search on cf_users.user_id=cf_canned_search.user_id
				WHERE
					username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				ORDER BY search_name
			</cfquery>
			<cfif getSavedSearches.recordcount is 0>
				<h2 class="h3">No Saved Searches</h2>
				<p>You may save Specimen Results from searches on the home page for later reference.</p>
 				<p>They will appear here when you have done so.</p>
			<cfelse>
				<h2 class="h3">#getSavedSearches.recordcount# Saved Searches</h2>
				<table class="table table-responsive table-striped d-lg-table">
					<thead class="thead-light">
					<tr>
						<th><strong>Search For</strong></th>
						<th><strong>Name</strong></th>
						<th><strong>Search URL</strong></th>
						<th><strong>Execute</strong></th>
						<th>&nbsp;</th>
					</tr>
					</thead>
					<tbody>
					<cfloop query="getSavedSearches">
						<cfset target = "">
						<cfset page="#reMatch('/[A-Za-z]+\.cfm')[0]#">
						<cfswitch expression="#page#">
							<cfcase value="/Specimens.cfm"><cfset target="Specimens"></cfcase>
							<cfcase value="/SpecimenResults.cfm"><cfset target="Specimens (old)"></cfcase>
							<cfcase value="/SpecimenResultsHTML.cfm"><cfset target="Specimens (old)"></cfcase>
							<cfcase value="/Transactions.cfm"><cfset target="Transactions"></cfcase>
						</cfswitch>
						<cfset execute_text = "">
						<cfif target NEQ "Specimens (old)">
							<cfif getSavedSearches.execute EQ 1>
								<cfset execute_text = "Run immediately">
							<cfelseif getSavedSearches.execute EQ 0>
								<cfset execute_text = "Populate search form">
							</cfif>
						</cfif>
						<tr id="tr#canned_id#">
							<td>#target#</td>
							<td><a href="/saved/#encodeForURL(search_name)#">#search_name#</a></td>
							<td>#url#</td>
							<td>#execute_text#</td>
							<td><button class="btn btn-xs btn-danger" onClick="killMe('#canned_id#');">Delete</button></td>
						</tr>
					</cfloop>
					</tbody>
				</table>
			</cfif>
		</section>
	</main>
</cfoutput>

<cfinclude template="/shared/_footer.cfm">
