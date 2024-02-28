<cfset pageTitle="Saved Searches">
<cfinclude template="/shared/_header.cfm">

<script type="text/javascript" language="javascript">
	function deleteSavedSearch(canned_id) {
		jQuery.ajax({
			url: "/users/component/functions.cfc",
			data: {
				method : "deleteSavedSearch",
				canned_id : canned_id,
			},
			success : function(result) { 
				retval = JSON.parse(result)
				if (retval[0].status=="deleted") { 
					$("#tr" + retval[0].removed_id).hide();
					$("#userSearchCount").html(retval[0].user_search_count);
				} else {
					// we shouldn't get here, but in case.
					alert("Error, problem deleting saved search");
				}
			}, 
			 error: function (jqXHR, textStatus, error) {
				 handleFail(jqXHR,textStatus,error,"retrieving deleting a saved search");
			 }
		});
	}
</script>

<cfoutput>
	<main class="container py-3" id="content" >
		<section class="row border rounded my-2 p-2">
			<div class="col-12 pt-2">
				<h1 class="h2 w-100">Saved Searches for #session.username#</h1>
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
					<h2 class="h4 w-100">No Saved Searches</h2>
					<p>You may save Specimen Results from searches on the home page for later reference.</p>
					<p>They will appear here when you have done so.</p>
				<cfelse>
					<h2 class="h3"><span id="userSearchCount">#getSavedSearches.recordcount#</span> Saved Searches</h2>
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
							<cfset matches="#reMatch('/[A-Za-z/]+\.cfm',getSavedSearches.URL)#">
							<cfif ArrayLen(matches) EQ 1>
								<cfset page="#matches[1]#">
							</cfif>
							<cfswitch expression="#page#">
								<cfcase value="/Specimens.cfm"><cfset target="Specimens"></cfcase>
								<cfcase value="/SpecimenResults.cfm"><cfset target="Specimens (old)"></cfcase>
								<cfcase value="/SpecimenResultsHTML.cfm"><cfset target="Specimens (old)"></cfcase>
								<cfcase value="/Transactions.cfm"><cfset target="Transactions"></cfcase>
								<cfcase value="/Taxa.cfm"><cfset target="Taxa"></cfcase>
								<cfcase value="/Agents.cfm"><cfset target="Agents"></cfcase>
								<cfcase value="/media/findMedia.cfm"><cfset target="Media"></cfcase>
								<cfcase value="/transactions/Permit.cfm"><cfset target="Permissions & Rights Documents"></cfcase>
							</cfswitch>
							<cfset execute_text = "">
							<cfset doExecute = true>
							<cfif target NEQ "Specimens (old)">
								<cfif getSavedSearches.execute EQ 1>
									<cfset doExecute = true>
									<cfset execute_text = "Run immediately">
								<cfelseif getSavedSearches.execute EQ 0>
									<cfset doExecute = false>
									<cfset execute_text = "Populate search form">
								</cfif>
							</cfif>
							<cfset useUrl = getSavedSearches.url >
							<cfif NOT doExecute >
								<cfset useUrl = replace(useUrl,"&execute=true","","all")>
								<cfset useUrl = replace(useUrl,"?execute=true&","?")>
								<cfset useUrl = replace(useUrl,"?execute=true","")>
							</cfif>
							<tr id="tr#canned_id#">
								<td>#target#</td>
								<td><a href="/saved/#encodeForURL(search_name)#">#search_name#</a></td>
								<td><a class="wrapurl" href="#useUrl#" target="_blank">#useUrl#</a></td>
								<td>#execute_text#</td>
								<td><button class="btn btn-xs btn-danger" onClick="deleteSavedSearch('#canned_id#');">Delete</button></td>
							</tr>
						</cfloop>
						</tbody>
					</table>
				</cfif>
			</div>
		</section>
	</main>
</cfoutput>

<cfinclude template="/shared/_footer.cfm">
