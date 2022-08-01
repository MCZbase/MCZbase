<cfset pageTitle="Manage Download Field Profiles">
<cfinclude template="/shared/_header.cfm">

<script type="text/javascript" language="javascript">
	function deleteDownloadProfile(download_profile_id) {
		jQuery.ajax({
			url: "/users/component/functions.cfc",
			data: {
				method : "deleteDownloadProfile",
				download_profile_id : download_profile_id,
			},
			success : function(result) { 
				retval = JSON.parse(result)
				if (retval[0].status=="deleted") { 
					$("#tr" + retval[0].removed_id).hide();
					$("#userSearchCount").html(retval[0].user_search_count);
				} else {
					// we shouldn't get here, but in case.
					alert("Error, problem deleting download profile");
				}
			}, 
			 error: function (jqXHR, textStatus, error) {
				 handleFail(jqXHR,textStatus,error,"deleting a download profile");
			 }
		});
	}
</script>

<cfoutput>
	<main class="container py-3" id="content" >
		<section class="row border rounded my-2 p-2">
			<div class="col-12 pt-2">
				<h1 class="h2 w-100">Manage profiles for columns in Specimen Search CSV downloads for #encodeForHtml(session.username)#</h1>
				<cfquery name="getProfiles" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getProfiles_result">
					SELECT 
						username, name, download_profile_id, sharing, target_search, column_list
					FROM 
						download_profile
					WHERE
						upper(username) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(session.username)#">
						or sharing = 'Everyone'
						<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
							or sharing = 'MCZ'
						</cfif>
					ORDER BY name
				</cfquery>
				<cfif getProfiles.recordcount is 0>
					<h2 class="h4 w-100">No Visible Download Profiles</h2>
				<cfelse>
					<h2 class="h3"><span id="userSearchCount">#getProfiles.recordcount#</span> visible Download Profiles</h2>
					<table class="table table-responsive table-striped d-lg-table">
						<thead class="thead-light">
						<tr>
							<th><strong>Name</strong></th>
							<th><strong>Shared With</strong></th>
							<th><strong>Columns</strong></th>
							<th><strong>For Search</strong></th>
							<th>&nbsp;</th>
						</tr>
						</thead>
						<tbody>
						<cfloop query="getProfiles">
							<cfset columnCount = ListLen(column_list)>
							<tr id="tr#download_profile_id#">
								<td>#encodeForHtml(name)#</td>
								<td>#sharing#</td>
								<td>#columnCount#</td>
								<td>#target_search#</td>
								<td>
									<cfif ucase(getProfiles.username) EQ ucase(session.username)>
										<button class="btn btn-xs btn-danger disabled" onClick="deleteDownloadProfile('#download_profile_id#');">Delete</button>
										<button class="btn btn-xs btn-secondary disabled" onClick="manageDownloadProfile('#download_profile_id#');">Edit</button>
									</cfif>
								</td>
							</tr>
						</cfloop>
						</tbody>
					</table>
				</cfif>
				<button class="btn btn-xs btn-secondary" onClick="newDownloadProfile();">New</button>
				<div id="manageProfile"></div>
			</div>
		</section>
	</main>
</cfoutput>

<cfinclude template="/shared/_footer.cfm">
