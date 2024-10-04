<!---
users/component/functions.cfc

Copyright 2022 President and Fellows of Harvard College

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	 http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

--->
<cfcomponent>
<cf_rolecheck>
<cfinclude template="/shared/component/error_handler.cfc" runOnce="true">

<!--- getDownloadProfilesHtml get a block of html listing download profiles visible to the current user
  takes no parameters.
 @return a block of html listing the csv download profiles visible to the current user 
--->
<cffunction name="getDownloadProfilesHtml" returntype="string" access="remote">

	<cfset tn = REReplace(CreateUUID(), "[-]", "", "all") >
	<cfthread name="downloadProfileThread#tn#">
		<cfoutput>
			<cftry>
				<cfif not isDefined("session.username") OR len(session.username) EQ 0>
					<cfthrow message="Login required to view csv download profiles">
				</cfif>
				<cfquery name="getProfiles" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getProfiles_result">
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
						<cfif isdefined("session.roles") and listfindnocase(session.roles,"global_admin")>
							OR download_profile_id IS NOT NULL
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
							<th><strong>Uses as a Default</strong></th>
							<th>Manage My Profiles</th>
						</tr>
						</thead>
						<tbody>
						<cfloop query="getProfiles">
							<cfset columnCount = ListLen(column_list)>
							<cfquery name="checkUse" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="checkUse_result">
								SELECT count(*) ct
								FROM
									cf_users
								WHERE
									specimens_download_profile = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#download_profile_id#">
							</cfquery>
							<tr id="tr#download_profile_id#">
								<td>#encodeForHtml(name)#</td>
								<td>#encodeForHtml(owner_name)#</td>
								<td>#sharing#</td>
								<cfset column_list_formatted = lcase(replace(column_list,",",", ","all"))>
								<td><button class="btn btn-xs btn-info" onClick="messageDialog('#column_list_formatted#');">#columnCount#</button></td>
								<td>#target_search#</td>
								<td>#checkUse.ct#</td>
								<td>
									<cfif ucase(getProfiles.username) EQ ucase(session.username)>
										<cfif checkUse.ct EQ 0>
											<button class="btn btn-xs btn-danger" onClick="confirmDialog('Delete this CSV Download Column Profile?','Confirm Delete Profile', function() { deleteDownloadProfile('#download_profile_id#'); } );">Delete</button>
										</cfif>
										<button class="btn btn-xs btn-secondary" onClick="loadEditDownloadProfileForm('#download_profile_id#');">Edit</button>
									</cfif>
								</td>
							</tr>
						</cfloop>
						</tbody>
					</table>
					</script>
				</cfif>
			<cfcatch>
				<cfset error_message = cfcatchToErrorMessage(cfcatch)>
				<cfset function_called = "#GetFunctionCalledName()#">
				Error in #function_called# #error_message#
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="downloadProfileThread#tn#" />
	<cfreturn cfthread["downloadProfileThread#tn#"].output>
</cffunction>

<!--- editDownloadProfileHtml get a block of html for editing an existing or creating a new
  download profile.
 @param download_profile_id the csv column download profile to edit, if not provided, return
  a form for adding a new profile.
 @return a block of html listing the csv download profiles visible to the current user 
--->
<cffunction name="editDownloadProfileHtml" returntype="string" access="remote">
	<cfargument name="download_profile_id" type="string" required="no">

	<cfif not isDefined("download_profile_id") or len(download_profile_id) EQ 0>
		<cfset mode="new">
	<cfelse>
		<cfset mode="edit">
		<cfset target_download_profile_id = download_profile_id>
	</cfif>

	<cfset tn = REReplace(CreateUUID(), "[-]", "", "all") >
	<cfthread name="editDownloadProfileThread#tn#">
		<cfoutput>
			<cftry>
				<cfif not isDefined("session.username") OR len(session.username) EQ 0>
					<cfthrow message="Login required to view csv download profiles">
				</cfif>
				<cfset name_value = "">
				<cfset sharing_value = "Self">
				<cfset target_search_value = "Specimens">
				<cfset username_value = "">
				<cfif mode EQ "edit">
					<cfquery name="getProfile" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getProfile_result">
						SELECT 
							username, name, download_profile_id, sharing, target_search, column_list,
							decode(agent_name.agent_id,NULL,username,MCZBASE.get_agentnameoftype(agent_name.agent_id)) as owner_name
						FROM 
							download_profile
							left join agent_name on upper(download_profile.username) = upper(agent_name.agent_name) and agent_name_type = 'login'
						WHERE
							download_profile_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#target_download_profile_id#">
							and upper(username) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(session.username)#">
					</cfquery>
					<cfif getProfile.recordcount NEQ 1>
						<cfthrow message="Unable to edit the specified download profile [#encodeForHtml(target_download_profile_id)#]">
					</cfif>
					<cfset column_list = getProfile.column_list>
					<cfset name_value = getProfile.name>
					<cfset sharing_value = getProfile.sharing>
					<cfset target_search_value = getProfile.target_search>
					<cfset username_value = getProfile.username>
				</cfif>
				<cfquery name="getFields" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getFields_result">
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
				<div id="manageProfileFormDiv">
					<cfif mode EQ "edit">
						<h2 class="h3">Edit profile of columns to include in CSV downloads for Specimens</h2>
					<cfelse>
						<h2 class="h3">Create a new profile of columns to include in CSV downloads for Specimens</h2>
					</cfif>
					<div class="form-row">
						<div class="col-6">
							
							<h3 class="h4">#getFields.recordcount# Columns available (drag to columns included to add)</h3>
							<div class="form-row">
								<div class="col-10">
									<div id="available_fields" class="w-100"></div>
								</div>
								<div class="col-2 pt-5">
									<button onClick="moveSelectionToIncluded();" class="btn btn-secondary w-100 h1 mt-5" aria-label="Move selected fields from available fields to included fields.">&rArr;</button>
									<button onClick="removeSelectionFromIncluded();" class="btn btn-secondary w-100 h1" arial-label="Move selected fields from included fields to available fields.">&lArr;</button>
								</div>
							</div>
							<script>
								function moveFieldToIncluded(item) {
									$("##included_fields").jqxListBox("addItem",item);
									$("##available_fields").jqxListBox("removeItem",item);
								}
								function moveFieldToAvailable(item) {
									$("##available_fields").jqxListBox("addItem",item);
									$("##included_fields").jqxListBox("removeItem",item);
								}
								function moveSelectionToIncluded() { 
									var selectedItems = $("##available_fields").jqxListBox("getSelectedItems");
									$("##included_fields").jqxListBox("beginUpdate");
									$("##available_fields").jqxListBox("beginUpdate");
									selectedItems.forEach(moveFieldToIncluded);
									$("##included_fields").jqxListBox("endUpdate");
									$("##available_fields").jqxListBox("endUpdate");
								}
								function removeSelectionFromIncluded() { 
									var selectedItems = $("##included_fields").jqxListBox("getSelectedItems");
									$("##included_fields").jqxListBox("beginUpdate");
									$("##available_fields").jqxListBox("beginUpdate");
									selectedItems.forEach(moveFieldToAvailable);
									$("##included_fields").jqxListBox("endUpdate");
									$("##available_fields").jqxListBox("endUpdate");
								}
								$(document).ready(function () {
									var fieldList = [
										<cfset separator="">
										<cfloop query="getFields">
											<cfif (mode EQ "edit" AND NOT listcontains(column_list,column_name) ) OR ( minimal_fg EQ 0) >
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
										enableSelection:true,
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
							<cfif mode EQ "edit">
								<button class="btn btn-xs btn-primary d-block" onClick="saveProfile();">Save Profile</button>
							<cfelse>
								<button class="btn btn-xs btn-primary d-block" onClick="saveNewProfile();">Save New Profile</button>
							</cfif>
							<output id="feedback"></output>
							<label class="data-entry-label" for="name">Column Profile Name</label>
							<input type="text" class="data-entry-input reqdClr" id="name" name="name" value="#encodeForHtml(name_value)#">
							<label class="data-entry-label" for="target_search">For Search</label>
							<input type="text" class="data-entry-input disabled" id="target_search" name="target_search" value="#target_search_value#" disabled >
							<label class="data-entry-label" for="sharing">Share with</label>
							<select class="data-entry-select" id="sharing" name="sharing">
								<cfif sharing_value EQ "Self"><cfset selected = "selected"><cfelse><cfset selected = ""></cfif>
								<option value="Self" #selected# >Self</option>
								<cfif sharing_value EQ "MCZ"><cfset selected = "selected"><cfelse><cfset selected = ""></cfif>
								<option value="MCZ" #selected#>MCZ</option>
								<cfif sharing_value EQ "Everyone"><cfset selected = "selected"><cfelse><cfset selected = ""></cfif>
								<option value="Everyone" #selected#>Everyone</option>
							</select>
							<label class="h4" for="included_fields">Columns Included (drag to change order or drag to columns available to remove)</label>
							<div class="form-row">
								<div class="col-10">
									<div id="included_fields" class="w-100"></div>
								</div>
								<div class="col-2">
									<button onClick="moveUp();" class="btn btn-secondary w-100 h1" aria-label="Move selected included field earlier in sort order.">&uArr;</button>
									<button onClick="moveDown();" class="btn btn-secondary w-100 h1" aria-label="Move selected included field later in sort order.">&dArr;</button>
								</div>
							</div>
							<script>
								function selectItem(item) {
									var movedItem = $("##included_fields").jqxListBox("getItemByValue",item);
									$("##included_fields").jqxListBox("selectItem",movedItem);
								}
								function moveFieldEarlier(item) {
									var idx = item.index;
									if (idx > 1) { 
										$("##included_fields").jqxListBox("removeItem",item);
										$("##included_fields").jqxListBox("insertAt",item,idx-1);
									}
								}
								function moveFieldLater(item) {
									var idx = item.index;
									var items = $("##included_fields").jqxListBox("getItems");
									if (idx<items.length) { 
										$("##included_fields").jqxListBox("removeItem",item);
										$("##included_fields").jqxListBox("insertAt",item,idx+1);
									}
								}
								function moveUp() { 
									$("##included_fields").jqxListBox("beginUpdate");
									var selectedItems = $("##included_fields").jqxListBox("getSelectedItems");
									selectedItems.forEach(moveFieldEarlier);
									$("##included_fields").jqxListBox("endUpdate");
									selectedItems.forEach(selectItem);
								}
								function moveDown() { 
									$("##included_fields").jqxListBox("beginUpdate");
									var selectedItems = $("##included_fields").jqxListBox("getSelectedItems");
									selectedItems.forEach(moveFieldLater);
									$("##included_fields").jqxListBox("endUpdate");
									selectedItems.forEach(selectItem);
								}
								$(document).ready(function () {
									var fieldList = [
										<cfif mode EQ "edit">
											// Preserve field order on edit, store then iterate through column_list from getProfile
											<cfset listItems = ArrayNew(1)>
											<cfloop from="1" to="#listLen(column_list,',',false)#" index="i">
												<cfset listItems[i] = ""> 
											</cfloop>
											<cfloop query="getFields">
												<cfif listContainsNoCase(column_list,column_name) GT 0 >
													<cfset position = listFindNoCase(column_list,column_name)>
													<cfif position GT 0>
														<cfset listItems[position] = '{ "label":"#label#", "id":"#cf_spec_res_cols_id#","access_role":"#access_role#","category":"#category#" }'>
													</cfif>
												</cfif>
											</cfloop>
											<cfset separator="">
											<cfloop array="#listItems#" index="item">
												#separator##item#
												<cfset separator=",">
											</cfloop>
										<cfelse>
											// field order as specified in metadata table
											<cfset separator="">
											<cfloop query="getFields">
												<cfif minimal_fg EQ 1>
													#separator#{ "label":"#label#", "id":"#cf_spec_res_cols_id#","access_role":"#access_role#","category":"#category#" }
													<cfset separator=",">
												</cfif>
											</cfloop>
										</cfif>
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
										enableSelection:true,
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
									//Disable removal of GUID column
									var items = $("##included_fields").jqxListBox("getItems");
									for (i=0; i<items.length; i++) {
										if(items[i].label=="GUID") {
											$("##included_fields").jqxListBox("disableAt",i);
										}
									}
								});	
							</script>
							<!--- $("#included_fields").jqxListBox('getItems'); gets list in sorted order $("#included_fields").jqxListBox('getItems')[0].label; (or .value for id) ---> 
							<cfif mode EQ "edit">
								<script>
									function saveProfile() { 
										// check if requirements are met.
										if ($("##name").val().trim().length==0) { 
											messageDialog("You must enter a name for the profile.");
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
													method : "saveDownloadProfile",
													download_profile_id: "#target_download_profile_id#",
													name: $("##name").val(), 
													sharing: $("##sharing").val(), 
													target_search: "Specimens", 
													column_id_list: column_id_list,
													returnformat : "json",
													queryformat : "column"
												},
												success : function(result) { 
													retval = JSON.parse(result)
													if (retval.DATA.STATUS[0]=="saved") { 
														$("##feedbackDiv").html(retval.DATA.MESSAGE[0]);
														$("##manageProfileFormDiv").hide();
													} else {
														// we should not get here, but in case.
														alert("Error, problem adding new download profile");
													}
													reloadDownloadProfileList();
												}, 
												error: function (jqXHR, textStatus, error) {
													 handleFail(jqXHR,textStatus,error,"creating a download profile");
												 }
											});
										}
									}
								</script> 
							<cfelse>
								<script> 
									function saveNewProfile() { 
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
														$("##feedbackDiv").html(retval.DATA.MESSAGE[0]);
														$("##manageProfileFormDiv").hide();
													} else {
														// we should not get here, but in case.
														alert("Error, problem adding new download profile");
													}
													reloadDownloadProfileList();
												}, 
												error: function (jqXHR, textStatus, error) {
													 handleFail(jqXHR,textStatus,error,"updating a download profile");
												 }
											});
										}
									};
								</script>
							</cfif>
						</div>
					</div>
				</div>

			<cfcatch>
				<cfset error_message = cfcatchToErrorMessage(cfcatch)>
				<cfset function_called = "#GetFunctionCalledName()#">
				Error in #function_called# #error_message#
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="editDownloadProfileThread#tn#" />
	<cfreturn cfthread["editDownloadProfileThread#tn#"].output>
</cffunction>

<!--- createDownloadProfile create a new download profile.
 @param name the name for the new profile
 @param sharing value for the new profile
 @param target_search for the new profile
 @param column_id_list a list of cf_spec_res_cols_r.cf_spec_res_cols_id values specifying, in order, the columns to
  include in the profile
 @return a data structure containing status=inserted and the new download profile id on success, otherwise throws an error.
--->
<cffunction name="createDownloadProfile" access="remote" returntype="query">
	<cfargument name="name" type="string" required="yes">
	<cfargument name="sharing" type="string" required="yes">
	<cfargument name="target_search" type="string" required="yes">
	<cfargument name="column_id_list" type="string" required="yes">

	<cfset result=queryNew("status, message, download_profile_id")>
	<cftransaction>
		<cftry>
			<cfset column_list = "">
			<cfset separator = "">
			<cfloop list="#column_id_list#" index="idx">
				<cfquery name="getCol" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getCol_result">
					SELECT column_name
					FROM cf_spec_res_cols_r
					WHERE cf_spec_res_cols_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#idx#">
				</cfquery>
				<cfif getCol.recordcount EQ 1>
					<cfset column_list = "#column_list##separator##getCol.column_name#">
					<cfset separator = ",">
				</cfif>
			</cfloop>
			<cfif len(column_list) EQ 0>
				<cfthrow message="Unable to add specified profile, no fields found for the list of specified column id values.">
			</cfif>
			<cfquery name="createProfile" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="createProfile_result">
				INSERT INTO download_profile
				(
					username,
					name,
					<cfif isdefined("sharing") AND len(sharing) GT 0>
						sharing,
					</cfif>
					target_search,
					column_list
				) VALUES (
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#name#">,
					<cfif isdefined("sharing") AND len(sharing) GT 0>
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#sharing#">,
					</cfif>
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#target_search#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#column_list#">
				)
			</cfquery>
			<cfif createProfile_result.recordcount EQ 1>
				<cfset t = queryaddrow(result,1)>
				<cfset t = QuerySetCell(result, "status", "inserted", 1)>
				<cfset t = QuerySetCell(result, "message", "Record created.", 1)>
				<cfset t = QuerySetCell(result, "download_profile_id", "#createProfile_result.generatedkey#", 1)>
			<cfelse>
				<cfthrow message="Unable to add specified profile.">
			</cfif>
			<cftransaction action="commit"> 
		<cfcatch>
			<cftransaction action="rollback">
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn result>
</cffunction>

<!--- saveDownloadProfile save changes to an existing download profile.
 @param download_profile_id the primary key value for the csv column profile to edit
 @param name the new value for the name for the profile
 @param sharing the new value for sharing of the profile
 @param target_search the new value for the target_search for the profile
 @param column_id_list a list of cf_spec_res_cols_r.cf_spec_res_cols_id values specifying, in order, the columns to
  include in the profile.
 @return a data structure containing status=saved and the download profile id on success, otherwise throws an error.
--->
<cffunction name="saveDownloadProfile" access="remote" returntype="query">
	<cfargument name="download_profile_id" type="string" required="yes">
	<cfargument name="name" type="string" required="yes">
	<cfargument name="sharing" type="string" required="yes">
	<cfargument name="target_search" type="string" required="yes">
	<cfargument name="column_id_list" type="string" required="yes">

	<cfset result=queryNew("status, message, download_profile_id")>
	<cftransaction>
		<cftry>
			<cfset column_list = "">
			<cfset separator = "">
			<cfloop list="#column_id_list#" index="idx">
				<cfquery name="getCol" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getCol_result">
					SELECT column_name
					FROM cf_spec_res_cols_r
					WHERE cf_spec_res_cols_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#idx#">
				</cfquery>
				<cfif getCol.recordcount EQ 1>
					<cfset column_list = "#column_list##separator##getCol.column_name#">
					<cfset separator = ",">
				</cfif>
			</cfloop>
			<cfif len(column_list) EQ 0>
				<cfthrow message="Unable to save changes to specified profile, no fields found for the list of specified column id values.">
			</cfif>
			<cfquery name="createProfile" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="createProfile_result">
				UPDATE download_profile
				SET
					name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#name#">,
					sharing = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#sharing#">,
					target_search = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#target_search#">,
					column_list = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#column_list#">
				WHERE 
					download_profile_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#download_profile_id#">
					<cfif NOT listfindnocase(session.roles,"global_admin")>
						AND
						username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
					</cfif>
			</cfquery>
			<cfif createProfile_result.recordcount EQ 1>
				<cfset t = queryaddrow(result,1)>
				<cfset t = QuerySetCell(result, "status", "saved", 1)>
				<cfset t = QuerySetCell(result, "message", "Record saved.", 1)>
				<cfset t = QuerySetCell(result, "download_profile_id", "#encodeForHtml(download_profile_id)#", 1)>
			<cfelse>
				<cfthrow message="Unable to save specified profile [#encodeForHtml(download_profile_id)#].">
			</cfif>
			<cftransaction action="commit"> 
		<cfcatch>
			<cftransaction action="rollback">
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn result>
</cffunction>

<!--- deleteDownloadProfile delete a specified download profile.
 @param download_profile_id the download_profile_id to delete.
 @return a data structure containing status=deleted on success, otherwise throw an error.
--->
<cffunction name="deleteDownloadProfile" access="remote" returntype="query">
	<cfargument name="download_profile_id" type="string" required="yes">
	<cfset result=queryNew("status, message, user_search_count")>
	<cftransaction>
		<cftry>
			<cfquery name="deleteProfile" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="deleteProfile_result">
				DELETE FROM
					download_profile
				WHERE
					username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
					AND
					download_profile_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#download_profile_id#">
			</cfquery>
			<cfif deleteProfile_result.recordcount EQ 1>
				<cfquery name="getProfiles" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getProfiles_result">
					SELECT 
						count(*) ct
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
				<cfset t = queryaddrow(result,1)>
				<cfset t = QuerySetCell(result, "status", "deleted", 1)>
				<cfset t = QuerySetCell(result, "user_search_count", "#getProfiles.ct#", 1)>
				<cfset t = QuerySetCell(result, "message", "Record #encodeForHtml(download_profile_id)# deleted.", 1)>
			<cfelse>
				<cfthrow message="Unable to delete specified profile.">
			</cfif>
			<cftransaction action="commit"> 
		<cfcatch>
			<cftransaction action="rollback">
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn result>
</cffunction>

<!--- changeSpecimenDefaultProfile change the user profile value for the
 default csv column download profile.
 @param target_profile_id the download_profile_id to use as the default.
 @return success on success, otherwise throw an error.
--->
<cffunction name="changeSpecimenDefaultProfile" access="remote">
	<cfargument name="target_profile_id" type="string" required="yes">
	<cftransaction>
		<cftry>
			<cfquery name="up" datasource="cf_dbuser">
				UPDATE cf_users 
				SET
					specimens_download_profile = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#target_profile_id#">
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<!--- unlike other user profile variables, not stored as a session variable but retrieved on demand (in ajax backing method for csv download dialog) --->
			<cfset result="success">
			<cftransaction action="commit"> 
		<cfcatch>
			<cftransaction action="rollback">
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn result>
</cffunction>

<!--- changeBlockSuggest change the user profile block_suggest value
   currently unused by application.
--->
<cffunction name="changeBlockSuggest" access="remote">
	<cfargument name="onoff" type="string" required="yes">
	<cftransaction>
		<cftry>
			<cfquery name="up" datasource="cf_dbuser">
				UPDATE cf_users SET
					block_suggest = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#onoff#">
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfset session.block_suggest = onoff>
			<cfset result="success">
			<cftransaction action="commit"> 
		<cfcatch>
			<cftransaction action="rollback">
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn result>
</cffunction>


<!--- changekillRows change the user profile killrow value for enabling/disabling row removal from speciemn search,
  on success, changes the value of session.KILLROW.
 @param tgt the target value to change killRows to, should be 0 or 1, if value other than 0, 1 will be used.
 @return the string "success" or an error message.
--->
<cffunction name="changekillRows" access="remote">
	<cfargument name="tgt" type="string" required="yes">

	<cftry>
		<cfif (tgt is not 1) AND (tgt is not 2) >
			<cfset tgt=0>
		</cfif>
		<cfquery name="up" datasource="cf_dbuser">
			UPDATE cf_users 
			SET
				KILLROW = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#tgt#">
			WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
		</cfquery>
		<cfset session.KILLROW = "#tgt#">
		<cfset result="success">
	<cfcatch>
		<cfset result = "#cfcatch.Message# #cfcatch.Detail#">
	</cfcatch>
	</cftry>
	<cfreturn result>
</cffunction>

<!--- saveSearch save searches 
 @param search_name the user provided name for the search
 @param execute whether to execute the search immediately on page load, or only display the populated search form
 @param url the path, page name, and parameters of the search to run.
 @return json containing status=saved and name=html encoded search_name.
--->
<cffunction name="saveSearch" access="remote" returntype="any" returnformat="json">
	<cfargument name="search_name" type="string" required="yes">
	<cfargument name="execute" type="string" required="yes">
	<cfargument name="url" type="string" required="yes">
	<cfif execute EQ "true"><cfset execute="1"></cfif>
	<cfif execute EQ "false"><cfset execute="0"></cfif>

	<cfset data = ArrayNew(1)>
	<cftransaction>
		<cftry>
			<cfquery name="getUserID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT user_id 
				FROM cf_users
				WHERE
					username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="upIns" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				INSERT INTO cf_canned_search
				(
					search_name,
					url,
					execute,
					user_id
				)
				VALUES
				(
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#search_name#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#url#">,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#execute#">,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getUserID.user_id#">
				)
			</cfquery>
			<cftransaction action="commit"> 
			<cfset row = StructNew()>
			<cfset row["status"] = "saved">
			<cfset row["name"] = "#encodeForHTML(search_name)#">
			<cfset data[1] = row>
		<cfcatch>
			<cftransaction action="rollback"> 
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfif error_message CONTAINS "ORA-00001: unique constraint">
				<cfset error_message = "Unable to save search, the search name and the search must each be unique.  You have already saved either a search with the same name, or a search with the same URI.  See the <a href='/users/Searches.cfm' target='_blank'>list of saved searches</a> in your user profile.">
			</cfif>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn #serializeJSON(data)#>
</cffunction>

<!--- deleteSavedSearch delete a saved search owned by the current user 
 @param canned_id the id of the saved search to delete. 
 @return a json structure containing status=deleted on success, otherwise
   throws an exception through reportError.
--->
<cffunction name="deleteSavedSearch" access="remote" returntype="any" returnformat="json">
	<cfargument name="canned_id" type="numeric" required="yes">

	<cfset data = ArrayNew(1)>
	<cftransaction>
		<cftry>
			<cfquery name="getUserID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT user_id 
				FROM cf_users
				WHERE
					username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfif getUserId.recordcount NEQ 1>
				<cfthrow message = "delete failed, user not found">
			</cfif>
			<cfquery name="doDelete" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="doDelete_result">
				DELETE 
				FROM cf_canned_search 
				WHERE 
					canned_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#canned_id#">
					AND user_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getUserId.user_id#">
			</cfquery>
			<cfif doDelete_result.recordcount EQ 0>
				<cfthrow message = "delete failed, no search with that id for the current user">
			<cfelseif doDelete_result.recordcount GT 1>
				<cfthrow message = "delete failed, error condition">
			</cfif> 
			<cfquery name="userSearches" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="userSearches_result">
				SELECT count(*) ct
				FROM cf_canned_search
				WHERE
					user_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getUserId.user_id#">
			</cfquery>
			<cftransaction action="commit">
			<cfset row = StructNew()>
			<cfset row["status"] = "deleted">
			<cfset row["removed_id"] = "#canned_id#">
			<cfset row["user_search_count"] = "#userSearches.ct#">
			<cfset data[1] = row>
		<cfcatch>
			<cftransaction action="rollback">
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn #serializeJSON(data)#>
</cffunction>

</cfcomponent>
