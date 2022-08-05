<cfset pageTitle="Manage Download Field Profiles">
<cfinclude template="/shared/_header.cfm">

<script type="text/javascript" language="javascript">
	function deleteDownloadProfile(download_profile_id) {
		jQuery.ajax({
			url: "/users/component/functions.cfc",
			data: {
				method : "deleteDownloadProfile",
				download_profile_id : download_profile_id,
				returnformat : "json",
				queryformat : "column"
			},
			success : function(result) { 
				retval = JSON.parse(result)
				if (retval.DATA.STATUS[0]=="deleted") { 
					$("#tr" + download_profile_id).hide();
					$("#userSearchCount").html(retval.DATA.USER_SEARCH_COUNT[0]);
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
						username, name, download_profile_id, sharing, target_search, column_list,
						decode(agent_name.agent_id,NULL,username,MCZBASE.get_agentnameoftype(agent_name.agent_id)) as owner_name
					FROM 
						download_profile
						left join agent_name on upper(download_profile.username) = upper(agent_name.agent_name) and agent_name_type = 'login'
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
							<th><strong>Created By</strong></th>
							<th><strong>Shared With</strong></th>
							<th><strong>Columns</strong></th>
							<th><strong>For Search</strong></th>
							<th>Manage My Profiles</th>
						</tr>
						</thead>
						<tbody>
						<cfloop query="getProfiles">
							<cfset columnCount = ListLen(column_list)>
							<tr id="tr#download_profile_id#">
								<td>#encodeForHtml(name)#</td>
								<td>#encodeForHtml(owner_name)#</td>
								<td>#sharing#</td>
								<td>#columnCount#</td>
								<td>#target_search#</td>
								<td>
									<cfif ucase(getProfiles.username) EQ ucase(session.username)>
										<cfquery name="checkUse" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="checkUse_result">
											SELECT count(*) ct
											FROM
												cf_users
											WHERE
												specimens_download_profile = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#download_profile_id#">
										</cfquery>
										<cfif checkUse.ct GT 0>
											<span>Default for #checkUse.ct# users</span>
										<cfelse>
											<button class="btn btn-xs btn-danger" onClick="deleteDownloadProfile('#download_profile_id#');">Delete</button>
										</cfif>
										<button class="btn btn-xs btn-secondary disabled" onClick="manageDownloadProfile('#download_profile_id#');">Edit</button>
									</cfif>
								</td>
							</tr>
						</cfloop>
						</tbody>
					</table>
					</script>
				</cfif>
				<button class="btn btn-xs btn-secondary" onClick="newDownloadProfileForm();">New</button>
				<div id="manageProfile">
					<cfquery name="getFields" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getFields_result">
						SELECT column_name, category, cf_spec_res_cols_id, disp_order, label, access_role, hidden, minimal_fg
						FROM
							cf_spec_res_cols_r
						WHERE
							access_role = 'PUBLIC'
							<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
								OR access_role = 'COLDFUSION_USER'
							</cfif>
							<cfif isdefined("session.roles") and listfindnocase(session.roles,"data_entry")>
								OR access_role = 'DATA_ENTRY'
							</cfif>
							<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_specimens")>
								OR access_role = 'MANAGE_SPECIMENS'
							</cfif>
							<cfif isdefined("session.roles") and listfindnocase(session.roles,"MANAGE_TRANSACTIONS")>
								OR access_role = 'MANAGE_TRANSACTIONS'
							</cfif>
						ORDER BY 
							disp_order
					</cfquery>
					<div id="manageProfileFormDiv" style="display: none;">
						<h2 class="h3">Create a new profile of columns to include in CSV downloads for Specimens</h2>
						<div class="form-row">
							<div class="col-6">
								<h3 class="h4">#getFields.recordcount# Columns available (drag to columns included to add)</h3>
								<div id="available_fields" class="w-75"></div>
								<script>
									$(document).ready(function () {
										var fieldList = [
											<cfset separator="">
											<cfloop query="getFields">
												<cfif minimal_fg EQ 0>
													#separator#{ "label":"#label#", "id":"#cf_spec_res_cols_id#","access_role":"#access_role#","category":"#category#"  }
													<cfset separator=",">
												</cfif>
											</cfloop>
										];
										var source = {
											datatype: "json",	
											datafields: [ {name:"label"},{name:"id"}],
											localdata: fieldList
										};
										var dataAdaptor = new $.jqx.dataAdapter(source);
										$("##available_fields").jqxListBox({ 
											source: dataAdaptor, 
											displayMember:"name", valueMember:"id",
											autoHeight:true,
											allowDrag:true,
											allowDrop:true,
											width:"75%",
											filterable:true,
											searchMode:"containsignorecase",
											enableSelection:false,
											renderer:function (index, label, value) 
												{
													var datarecord = $("##available_fields").jqxListBox('source').loadedData.filter(obj => { return obj.id===value })[0];
													if (datarecord===undefined) { 
														return label;
													} else {
														return "<strong>"+ label + "</strong>  " + datarecord.category + " (" + datarecord.access_role + ")" ;
													}
												}
										});
									});	
								</script>
							</div>
							<div class="col-6">
								<label class="data-entry-label" for="name">Column Profile Name</label>
								<input type="text" class="data-entry-input reqdClr" id="name" name="name">
								<label class="data-entry-label" for="target_search">For Search</label>
								<input type="text" class="data-entry-input disabled" id="target_search" name="target_search" value="Specimens" disabled >
								<label class="data-entry-label" for="sharing">Share with</label>
								<select class="data-entry-select" id="sharing" name="sharing">
									<option value="Self" selected >Self</option>
									<option value="MCZ">MCZ</option>
									<option value="Everyone">Everyone</option>
								</select>
								<label class="h4" for="included_fields">Columns Included (drag to columns available to remove)</label>
								<button class="btn btn-xs btn-primary" onClick="saveProfile();">Save</button>
								<output id="feedback"></output>
								<div id="included_fields" class="w-75"></div>
								<script>
									$(document).ready(function () {
										var fieldList = [
											<cfset separator="">
											<cfloop query="getFields">
												<cfif minimal_fg EQ 1>
													#separator#{ "label":"#label#", "id":"#cf_spec_res_cols_id#","access_role":"#access_role#","category":"#category#"  }
													<cfset separator=",">
												</cfif>
											</cfloop>
										];
										var source = {
											datatype: "json",	
											datafields: [ {name:"label"},{name:"id"}],
											localdata: fieldList
										};
										var dataAdaptor = new $.jqx.dataAdapter(source);
										$("##included_fields").jqxListBox({ 
											source: dataAdaptor, 
											displayMember:"name", valueMember:"id",
											autoHeight:true,
											allowDrag:true,
											allowDrop:true,
											width:"75%",
											enableSelection:false,
											renderer:function (index, label, value) 
												{
													var datarecord = $("##included_fields").jqxListBox('source').loadedData.filter(obj => { return obj.id===value })[0];
													if (datarecord===undefined) { 
														return label;
													} else {
														return "<strong>"+ label + "</strong>  " + datarecord.category + " (" + datarecord.access_role + ")" ;
													}
												}
										});
										//TODO: disable GUID
										//$("##included_fields").jqxListBox("disableItem","GUID");
									});	
								</script>
								<!--- $("#included_fields").jqxListBox('getItems'); gets list in sorted order $("#included_fields").jqxListBox('getItems')[0].label; (or .value for id) ---> 
								<script>
									function saveProfile() { 
										// check if requirements are met.
										if ($("##name").val().trim().length==0) { 
											messageDialog("You must enter a name for the new profile.");
										} else { 
											var fieldArray = $("##included_fields").jqxListBox('getItems'); 
											var column_id_list = "";
											var separator = "";
											for (i=0; i<fieldArray.length; i++) {
												column_id_list = column_id_list + separator + fieldArray[i].value; 
												separator = ",";
											}
											console.log(column_id_list);
											jQuery.ajax({
											url: "/users/component/functions.cfc",
												data: {
													method : "createDownloadProfile",
													name: $("##name").val(), 
													sharing: $("##sharing").val(), 
													target_search: "Specimens", 
													column_id_list: column_id_list,
													returnformat : "json",
													queryformat : "column"
												},
												success : function(result) { 
													retval = JSON.parse(result)
													if (retval.DATA.STATUS[0]=="inserted") { 
														$("##feedback").html(retval.DATA.MESSAGE[0]);
													} else {
														// we shouldn't get here, but in case.
														alert("Error, problem adding new download profile");
													}
												}, 
												error: function (jqXHR, textStatus, error) {
													 handleFail(jqXHR,textStatus,error,"creating a download profile");
												 }
											});
										}
									};
								</script>
							</div>
						</div>
					</div>
				</div>
				<script>
					function newDownloadProfileForm() { 
						$("##manageProfileFormDiv").show();
					};
				</script>
			</div>
		</section>
	</main>
</cfoutput>

<cfinclude template="/shared/_footer.cfm">
