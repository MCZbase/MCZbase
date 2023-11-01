<!---
shared/component/functions.cfc

Copyright 2020 President and Fellows of Harvard College

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

<!---
	linkMediaHtml create dialog content to link media to an object 
	@see findMediaSearchResults 
	@see linkMediaRecord
--->
<cffunction name="linkMediaHtml" access="remote">
	<cfargument name="relationship" type="string" required="yes">
	<cfargument name="related_value" type="string" required="yes">
	<cfargument name="related_id" type="string" required="yes">
	<cfargument name="callback" type="string" required="no" default="reloadTransMedia">

	<cfset target_id = related_id>
	<cfset target_relation = relationship>
	<cfset target_label = related_value>
	<cfset result = "">
	<cftry> 
		<cfquery name="ctmedia_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select media_type from ctmedia_type order by media_type
		</cfquery>
		<cfquery name="ctmime_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select mime_type from ctmime_type order by mime_type
		</cfquery>
		<cfset result = result & "
		<div class='container-fluid'><div class='row'><div class='col-12'><div id='mediaSearchForm' class='search-box px-3 py-2'><h1 class='h3 mt-2'>Search for Media</h1>
		<form id='findMediaForm' onsubmit='return searchformedia(event);' >
			<input type='hidden' name='method' value='findMediaSearchResults'>
			<input type='hidden' name='returnformat' value='plain'>
			<input type='hidden' name='target_id' value='#target_id#'>
			<input type='hidden' name='target_relation' value='#target_relation#'>
		
				<div class='form-row'>
					<div class='col-12 col-md-8 pb-2'>
						<label for='media_uri' class='data-entry-label'>Media URI (any part of media URI)</label>
			 			<input type='text' name='media_uri' id='media_uri' value='' class='data-entry-input'>
					</div>
					<div class='col-12 col-md-4 pb-2'>
						<label for='media_description' class='data-entry-label'>Description</label>
			 			<input type='text' name='media_description' id='media_description' value='' class='data-entry-input'>
					</div>
				</div>
				<div class='form-row'>
					<div class='col-12 col-md-6 col-xl-4 pb-2'>
						<label for='mimetype'>MIME Type</label>
						<select name='mimetype' id='mimetype' class='w-75'>
							<option value=''></option>
		">
							<cfloop query='ctmime_type'>
								<cfset result = result & "<option value='#ctmime_type.mime_type#'>#ctmime_type.mime_type#</option>">
							</cfloop>
		<cfset result = result & "
						</select>
			 		</div>
					<div class='col-12 col-md-6 col-xl-4 pb-2'>
			 			<label for='mediatype'>Media Type</label>
						<select name='mediatype' id='mediatype' class='w-75'>
							<option value=''></option>
		 ">
							<cfloop query='ctmedia_type'>
								<cfset result = result & "<option value='#ctmedia_type.media_type#'>#ctmedia_type.media_type#</option>">
							</cfloop>
		 <cfset result = result & "
						</select>
			 		</div>
			
					<div class='col-12 col-md-12 col-xl-4 pt-xl-0 pt-2 pb-2'>
						<span class=''>
							<input type='checkbox' name='unlinked' id='unlinked' value='true' style='position: relative; left:10px;'>
							<label class='pl-3' for='unlinked'>Media not yet linked to any record</label>
						</span>
					</div>
				</div>
				<div class='form-row mt-2'>
					<div class=''>
						<input type='submit' value='Search' class='btn-primary px-3 mb-2'>
					</div>
					<div class='ml-5'>
						<span ><input type='reset' value='Clear' class='btn-warning mb-2 mt-2 mt-sm-0 mr-1'>
							<input type='button' onClick=""opencreatemediadialog('newMediaDlg1_#target_id#','#target_label#','#target_id#','#relationship#',#callback#);"" 
								value='Create Media' class='btn-secondary mb-2 mt-2 mt-sm-0' >&nbsp;
						</span>
					</div>
				</div>
			</div>
		</form>
		</div></div></div>
		</div>
		<script language='javascript' type='text/javascript'>
			function searchformedia(event) { 
				event.preventDefault();
				jQuery.ajax({
					url: '/shared/component/functions.cfc',
					type: 'post',
					data: $('##findMediaForm').serialize(),
					success: function (data) {
						$('##mediaSearchResults').html(data);
					},
					error : function (jqXHR, status, error) {
						var message = '';
						if (error == 'timeout') {
							message = ' Server took too long to respond.';
						} else {
							message = jqXHR.responseText;
						}
						$('##mediaSearchResults').html('Error (' + error + '): ' + message);
					}
				});
				return false; 
			};
		</script>
		<div id='newMediaDlg1_#target_id#'></div>
		<div id='mediaSearchResults' class='container-fluid mt-1'></div>
		" >
	<cfcatch> 
		<cfset result = "Error: " & cfcatch.type & " " & cfcatch.message & " " & cfcatch.detail >
	</cfcatch>
	</cftry>

	<cfreturn result>
</cffunction>

<!------------------------------------->
<!--- Given some basic query parameters for media records, find matching media records and return
		a list with controls to link those media records in a provided relation to a provided target 
		@param target_relation the type of media relationship that is to be made. 
		@param target_id the primary key of the related record that the media record is to be related to.
		@param mediatype the media type to search for, can be blank.
		@param mimetype the mime type of the media to search for, can be blank.
		@param media_uri the uri of the media record to search for, can be blank.
		@param unlinked if equal to the string literal 'true' then only return matching media records that lack relations, can be blank.
		@return html listing matching media records with 'add this media' buttons for each record or an error message.
		@see linkMediaRecord
--->
<cffunction name="findMediaSearchResults" access="remote">
	<cfargument name="target_relation" type="string" required="yes">
	<cfargument name="target_id" type="string" required="yes">
	<cfargument name="mediatype" type="string" required="no">
	<cfargument name="mimetype" type="string" required="no">
	<cfargument name="media_uri" type="string" required="no">
	<cfargument name="media_description" type="string" required="no">
	<cfargument name="unlinked" type="string" required="no">
	<cfthread name="findMediaSearchResultsThread">
	<cftry>
	 <cfquery name="matchMedia" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select distinct media.media_id, media_uri uri, preview_uri, mime_type, media_type, 
			MCZBASE.get_medialabel(media.media_id,'description') description
		from media
			<cfif isdefined("unlinked") and unlinked EQ "true">
				left join media_relations on media.media_id = media_relations.media_id
			</cfif>
			<cfif isdefined("media_description") and len(media_description) GT 0>
				left join media_labels on media.media_id = media_labels.media_id
			</cfif>
		where
			media.media_id is not null
			<cfif isdefined("mediatype") and len(mediatype) gt 0>
				and media_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#mediatype#">
			</cfif>
			<cfif isdefined("mimetype") and len(mimetype) gt 0>
				and mime_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#mimetype#">
			</cfif>
			<cfif isdefined("media_uri") and len(media_uri) gt 0>
				and media_uri like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#media_uri#%">
			</cfif>
			<cfif isdefined("unlinked") and unlinked EQ "true">
				and media_relations.media_id is null
			</cfif>
			<cfif isdefined("media_description") and len(media_description) GT 0>
				and media_labels.media_label = 'description'
				and media_labels.label_value like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#media_description#%">
			</cfif>
	 </cfquery>

	<cfoutput>
		<cfset i=1>
		<cfif matchMedia.recordcount eq 0>
			<h2 class='h3'>No matching media records found</h2>
		<cfelse>
			<cfloop query="matchMedia">
				<cfset dbit = "<div">
					<cfif (i MOD 2) EQ 0> 
						<cfset dbit = dbit & "class='evenRow'"> 
					<cfelse> 
						<cfset dbit = dbit & "class='oddRow'"> 
					</cfif>
					<cfset dbit = dbit & ">">
					#dbit#
					<form id='pickForm#target_id#_#i#'>
						<input type='hidden' value='#target_relation#' name='target_relation'>
						<input type='hidden' name='target_id' value='#target_id#'>
						<input type='hidden' name='media_id' value='#media_id#'>
						<input type='hidden' name='Action' value='addThisOne'>
						<div>
							<a href='#uri#'>#uri#</a>
						</div>
						<div>#description# #mime_type# #media_type#</div>
						<div>
							<a href='/media/#media_id#' target='_blank'>Media Details</a>
						</div>
						<div id='pickResponse#target_id#_#i#'>
							<input type='button' class='btn-xs btn-secondary'
								onclick='linkmedia(#media_id#,#target_id#,"#target_relation#","pickResponse#target_id#_#i#");' value='Add this media'>
						</div>
						<hr class='bg-dark'>
					</form>
					<script language='javascript' type='text/javascript'>
						$('##pickForm#target_id#_#i#').removeClass('ui-widget-content');
						function linkmedia(media_id, target_id, target_relation, div_id) { 
							jQuery.ajax({
								url: '/shared/component/functions.cfc',
								type: 'post',
								data: {
									method: 'linkMediaRecord',
									returnformat: 'plain',
									target_relation: target_relation,
									target_id: target_id,
									media_id: media_id
								},
								success: function (data) {
									$('##'+div_id).html(data);
								},
								error: function (jqXHR, textStatus) {
									$('##'+div_id).html('Error:' + textStatus);
								}
							});
						};
					</script>
				</div>
				<cfset i=i+1>
			</cfloop>
		</cfif>
	</cfoutput>
	<cfcatch>
		<cfset err = "Error: " & cfcatch.type & " " & cfcatch.message & " " & cfcatch.detail >
		<cfoutput>#err#</cfoutput>
	</cfcatch>
	</cftry>
	</cfthread>
	<cfthread action="join" name="findMediaSearchResultsThread" />
	<cfreturn findMediaSearchResultsThread.output>
</cffunction>

<!------------------------------------->
<!--- 
	linkMediaRecord create a media_relations record.
	Given a relationship, primary key to link to, and media_id, create a media relation by
	performing an insert into media_relations.
	@return text indicating action performed or an error message.
--->
<cffunction name="linkMediaRecord" access="remote">
	<cfargument name="target_relation" type="string" required="yes">
	<cfargument name="target_id" type="string" required="yes">
	<cfargument name="media_id" type="string" required="yes">
	<cfset result = "">
	<cftry>
		<cfquery name="addMedia" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="addMediaResult">
			INSERT INTO media_relations 
				(media_id, related_primary_key, media_relationship,created_by_agent_id) 
			VALUES (
				<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">,
				<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#target_id#">,
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#target_relation#">,
				<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#session.myAgentId#">
			)
		</cfquery>
		<cfset result = "Added media #media_id# in relationship #target_relation# to #target_id#.">
	<cfcatch>
		<cfset result = "Error: " & cfcatch.type & " " & cfcatch.message & " " & cfcatch.detail >
	</cfcatch>
	</cftry>
	<cfreturn result>
</cffunction>

<!------------------------------------->
<!--- createMediaHtml given a relationship, and object to relate to, create an html dialog
	to allow the creation of a new media record to be linked with the provided relationship to the 
	provided object.
	@param relationship the type of media relation to create.
	@param related value the human readable description of object to relate the media record to.
	@param the primary key of the object to relate the media record to.
	@param collection_object_id if provided used to retrieve the guid of the cataloged item and as the
		primary key to relate to through the relationship shows cataloged item.
--->
<cffunction name="createMediaHtml" access="remote">
	<cfargument name="relationship" type="string" required="yes">
	<cfargument name="related_value" type="string" required="yes">
	<cfargument name="related_id" type="string" required="yes">
	<cfargument name="collection_object_id" type="string" required="no">

	<cfset result = "">
	<cfquery name="ctmedia_relationship" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select media_relationship from ctmedia_relationship order by media_relationship
	</cfquery>
	<cfquery name="ctmedia_label" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select media_label from ctmedia_label order by media_label
	</cfquery>
	<cfquery name="ctmedia_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select media_type from ctmedia_type order by media_type
	</cfquery>
	<cfquery name="ctmime_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select mime_type from ctmime_type order by mime_type
	</cfquery>
	<cfquery name="ctmedia_license" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select media_license_id,display media_license from ctmedia_license order by media_license_id
	</cfquery>

	<!---  TODO: Changed from post to media.cfm to ajax save operation.  --->
	<cfset result = result & '
		<div class="container-fluid">
		<div class="row">
			<h1 class="h3 pl-3 mb-0">Create Media</h1>
			<div class="col-12 border rounded bg-light p-3 mt-2 mb-4">
			<form name="newMedia" id="newMedia">
				<input type="hidden" name="method" value="createMedia">
				<input type="hidden" id="number_of_relations" name="number_of_relations" value="1">
				<input type="hidden" id="number_of_labels" name="number_of_labels" value="1">
				<div class="form-row">
					<div class="col-12 col-md-12 pb-2">
						<label for="media_uri">Media URI</label>
						<input type="text" name="media_uri" id="media_uri" class="reqdClr w-100" required>
						<!--- <span class="infoLink" id="uploadMedia">Upload</span> --->
					</div>
				</div>
				<div class="form-row">
					<div class="col-12 col-md-12 mb-3">
						<label for="preview_uri">Preview URI</label>
		 				<input type="text" name="preview_uri" id="preview_uri" class="w-100">
					</div>
				</div>
				<div class="form-row">
					<div class="col-12 col-md-4 pb-2">
						<label for="mime_type">MIME Type</label>
	 			 		<select name="mime_type" id="mime_type" class="reqdClr w-75" required>
							<option value=""></option>'>
							<cfloop query="ctmime_type">
								<cfset result = result & "<option value='#mime_type#'>#mime_type#</option>">
							</cfloop>
							<cfset result = result & '
						</select>
					</div>
					<div class="col-12 col-md-4 pb-2">
						<label for="media_type">Media Type</label>
							<select name="media_type" id="media_type" class="reqdClr w-75"  required>
								<option value=""></option>'>
								<cfloop query="ctmedia_type">
									<cfset result = result & '<option value="#media_type#">#media_type#</option>' >
								</cfloop> 
								<cfset result = result & '
							</select>
					</div>
					<div class="col-12 col-md-4 pb-2">
						<label for="mask_media_fg">Media Record Visibility</label>
						<select name="mask_media_fg" value="mask_media_fg" class="w-50">
							<option value="0" selected="selected">Public</option>
							<option value="1">Hidden</option>
						</select>
					</div>
				</div>
				<div class="form-row">
					<div class="col-12 col-md-12 py-2">
						<label for="media_license_id">License</label>
						<select name="media_license_id" id="media_license_id" class="col-3">
							<option value="">Research copyright &amp; then choose...</option>'>
							<cfloop query="ctmedia_license">
								<cfset result = result & '<option value="#media_license_id#">#media_license#</option>'>
							</cfloop>
							<cfset result = result & '
						</select>
						<a class="infoLink" onClick="popupDefine()">Define Licenses</a><br/>
					</div>
				</div>
				<div class="form-row">
					<div class="col-12 col-md-12">
						<p>Notes:</p>
						<ul class="lisc">
							<li>Media should not be uploaded until copyright is assessed and, if relevant, permission is granted (<a href="https://code.mcz.harvard.edu/wiki/index.php/Non-MCZ_Digital_Media_Licenses/Assignment" target="_blank">more info</a>).</li>
							<li>Remove media immediately if owner requests it.</li>
							<li>Contact <a href="mailto:mcz_collections_operations@oeb.harvard.edu?subject=media licensing">MCZ Collections Operations</a> if additional licensing situations arise,</li>
						</ul>
					</div>
				</div>
				<div class="form-row">
					<div class="col-12 col-md-12 pb-2">
						<label for="description">Description</label>
		 				<input type="text" name="description" id="description" class="w-100 reqdClr" required>
					</div>
				</div>
				<div class="form-row">
					<div class="col-12 col-md-12 pb-2">
						<label for="relationships" class="mt-2">Media Relationships</label>
						<div id="relationships" class="p-2 rounded dotted-border">
							<div id="relationshiperror"></div>
								<select name="relationship__1" id="relationship__1" size="1" class="col-3 float-left" onchange="pickedRelationship(this.id)">
									<option value="">None/Unpick</option>'>
									<cfloop query="ctmedia_relationship">
										<cfset result = result & '<option value="#media_relationship#">#media_relationship#</option>'>
									</cfloop>
									<cfset result = result & '
								</select>
						
								<input type="text" name="related_value__1" id="related_value__1" class="col-9 float-left" readonly>
								<input type="hidden" name="related_id__1" id="related_id__1">
								<button type="button" class="btn-xs btn-primary mt-1" id="addRelationship" onclick="addRelation(2);" aria-label="Add a relationship">Add Relationship</button>
							</div>
					</div>
				</div>
				<div class="form-row">
					<div class="col-12 col-md-12">
						<label for="labels" class="mt-2">Media Labels</label>
						<div id="labels" class="p-2 rounded dotted-border">
							<div id="labelsDiv__1">
								<select name="label__1" id="label__1" size="1" class="col-3 float-left">
									<option value="">None/Unpick</option>'>
									<cfloop query="ctmedia_label">
										<cfset result = result & '<option value="#media_label#">#media_label#</option>'>
									</cfloop>
									<cfset result = result & '
								</select>
				
								<input type="text" name="label_value__1" id="label_value__1" class="col-9 float-left">
								<button type="button" class="btn-xs btn-primary mt-1" id="addLabel" onclick="addLabelTo(2,''labels'',''addLabel'');" aria-label="Add a media label">Add Label</button>
							</div>
					</div>
				</div>
			</div>
</form></div></div></div>
	</div>'>
	<cfif isdefined("collection_object_id") and len(collection_object_id) gt 0>
		<cfquery name="s"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select guid from flat where collection_object_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
		</cfquery>
		<cfset result = result & '
		<script language="javascript" type="text/javascript">
			$("##relationship__1").val("shows cataloged_item");
			$("##related_value__1").val("#s.guid#");
			$("##related_id__1").val("#collection_object_id#");
		</script>'>
	</cfif>
	<cfif isdefined("relationship") and len(relationship) gt 0>
		<cfquery name="s"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select media_relationship from ctmedia_relationship where media_relationship= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#relationship#">
		</cfquery>
		<cfif s.recordCount eq 1 >
			<cfset result = result & '
			<script language="javascript" type="text/javascript">
				$("##relationship__1").val("#relationship#");
				$("##related_value__1").val("#related_value#");
				$("##related_id__1").val("#related_id#");
			</script>'>
		<cfelse>
			<cfset result = result & '
			<script language="javascript" type="text/javascript">
				$("##relationshiperror").html("<h2>Error: Unknown media relationship type #relationship#</h2>");
			</script>'>
		</cfif>
	 </cfif>
	 <cfset result = result & '</div>'>

	<cfreturn result>
</cffunction>


<!---
   Function to store the serialization of grid column hidden properties for a user and page.
   @param page the path and filename of the page on which the grid appears.
   @param columnhiddensettings json serialization of window.columnHiddenSettings.
	@param label an optional user supplied label for the settings for that page.
 --->
<cffunction name="saveGridColumnHiddenSettings" returntype="query" access="remote">
	<cfargument name="page_file_path" required="yes">
	<cfargument name="columnhiddensettings" required="yes">
	<cfargument name="label" required="no" default="Default">

	<cfset theResult=queryNew("status, message")>
	<cftry>
		<!--- check if this setting exists --->
		<cfquery name="exists" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="exists_result">
			select count(*) ct 
			from cf_grid_properties
			where 
				page_file_path = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#page_file_path#"> AND
				username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#"> AND
				label = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#label#"> 
		</cfquery>
		<cfif exists.ct EQ 0>
			<cfquery name="insert" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="insert_result">
				insert into cf_grid_properties (
					page_file_path,
					username,
					label,
					columnhiddensettings
				) values (
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#page_file_path#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#label#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#columnhiddensettings#"> 
				)
			</cfquery>
		<cfelse>
			<cfquery name="update" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="update_result">
				update cf_grid_properties
				set columnhiddensettings = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#columnhiddensettings#"> 
				where
					page_file_path = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#page_file_path#"> AND
					username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#"> AND
					label = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#label#"> 
			</cfquery>
		</cfif>
		<cfset t = queryaddrow(theResult,1)>
		<cfset t = QuerySetCell(theResult, "status", "1", 1)>
		<cfset t = QuerySetCell(theResult, "message", "Saved.", 1)>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn theResult>
</cffunction>

<cffunction name="getGridColumnHiddenSettings" returntype="any" returnformat="json" access="remote">
	<cfargument name="page_file_path" required="yes">
	<cfargument name="label" required="no" default="Default">
	
	<cfset data = ArrayNew(1)>
	<cftry>
		<cfquery name="getSettings" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getSettings_result">
			select columnhiddensettings
			from cf_grid_properties
			where 
				page_file_path = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#page_file_path#"> AND
				username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#"> AND
				label = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#label#"> AND
				rownum < 2
		</cfquery>
		<cfset i = 1>
		<cfloop query="getSettings">
			<cfset row = StructNew()>
			<cfloop list="#ArrayToList(getSettings.getColumnNames())#" index="col" >
				<cfset row["#lcase(col)#"] = "#getSettings[col][currentRow]#">
			</cfloop>
			<cfset data[i]  = row>
			<cfset i = i + 1>
		</cfloop>
		<cfreturn #serializeJSON(data)#>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset message = trim("Error processing #GetFunctionCalledName()#: " & cfcatch.message & " " & cfcatch.detail & " " & queryError)  >
		<cfheader statusCode="500" statusText="#message#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
</cffunction>

<!--- 
 ** given a query, return a serialization of that query as csv, with a header line.
 * @param queryToConvert the query to serialize as csv 
 * @return a string containing a csv serialization of the provided query 
 **
--->
<cffunction name="queryToCSV" returntype="string" output="false" access="public">
	<cfargument name="queryToConvert" type="query" required="true">

	<cfset controlChars = "\p{cntrl}">
	<cftry>
		<cfset engineCheck = refind("[[:digit:]]","1")>
		<cfif engineCheck EQ 1>
			<cfset controlChars = "[[:cntrl:]]">
		</cfif>
	<cfcatch>
		<!--- not the default perl regex engine --->
	</cfcatch>
	</cftry>		

	<!--- arrayToList on getColumnNames preserves order. --->
	<cfset columnNamesList = arrayToList(queryToConvert.getColumnNames()) >
	<cfset columnNamesArray = queryToConvert.getColumnNames() >
	<cfset columnCount = ArrayLen(columnNamesArray) >

	<cfset newLine =(chr(13) & chr(10)) >
	<cfset outputbuffer = CreateObject('java','java.lang.StringBuffer').Init() >

	<!--- header line --->
	<cfset header=[]>
	<cfloop index="i" from="1" to="#columnCount#" step="1">
		<cfset header[i] = """#ucase(columnNamesArray[i])#""" >
	</cfloop>
	<cfset outputBuffer.Append(JavaCast("string",( ArrayToList(header,",") & newLine)))>

	<!--- loop through query and append rows to buffer --->
	<cfloop query="queryToConvert">
		<cfset row=[]>
		<cfloop index="j" from="1" to="#columnCount#" step="1">
			<cfset row[j] = '"' & rereplace(replace(evaluate(columnNamesArray[j]),'"','""','all'),controlChars,"","all") & '"' >
		</cfloop>
		<cfset outputBuffer.append( JavaCast('string',(ArrayToList(row,","))))>
		<cfset outputBuffer.append(newLine) >
	</cfloop>
	<cfreturn outputBuffer.toString() >
</cffunction>


<!--- 
 ** given a query, write a serialization of that query as csv, with a header line
 * to a file.
 * @param queryToConvert the query to serialize as csv 
 * @return a structure containing the name of the file, the count of the number of records 
 * written to the file, and a status (STATUS, WRITTEN, FILENAME, MESSAGE), 
 * values of STATUS are Success, Incomplete, and Failed.  For Success and Incomplete, FILENAME 
 * contains the name of the file that was written.
 **
--->
<cffunction name="queryToCSVFile" returntype="any" output="false" access="public">
	<cfargument name="queryToConvert" type="query" required="true">
	<cfargument name="mode" type="string" required="no" default="create">
	<cfargument name="timestamp" type="string" required="no">
	<cfargument name="written" type="string" required="no">

	<cfsetting requestTimeout="600">
	<cfset controlChars = "\p{cntrl}">
	<cftry>
		<cfset engineCheck = refind("[[:digit:]]","1")>
		<cfif engineCheck EQ 1>
			<cfset controlChars = "[[:cntrl:]]">
		</cfif>
	<cfcatch>
		<!--- not the default perl regex engine --->
	</cfcatch>
	</cftry>		

	<cftry>
		<!--- remove the column added to order the query results for paging ---->
		<cfset queryToConvert = QueryDeleteColumn(queryToConvert,"FOUNDROWNUM")>
		<cfif mode EQ "create">
			<cfset timestamp = "#dateformat(now(),'yyyymmdd')#_#TimeFormat(Now(),'HHnnssl')#">
			<cfset written = 0>
		<cfelse>
			<cfif not isDefined("timestamp") OR len(timestamp) EQ 0 OR not isDefined("written") OR len(written) EQ 0>
				<cfthrow message="timestamp and written parameters are required if mode is other than create">
			<cfelseif REFind("^[0-9_]+$",timestamp) EQ 0>
				<cfthrow message="timestamp can only contain numbers">
			</cfif>
		</cfif>
		<cfset filename ="download_#session.dbuser#_#timestamp#">
		<cfset retval = StructNew()>
	
		<!--- arrayToList on getColumnNames preserves order. --->
		<cfset columnNamesList = arrayToList(queryToConvert.getColumnNames()) >
		<cfset columnNamesArray = queryToConvert.getColumnNames() >
		<cfset columnCount = ArrayLen(columnNamesArray) >
	
		<!--- header line --->
		<cfset header=[]>
		<cfloop index="i" from="1" to="#columnCount#" step="1">
			<cfset header[i] = """#ucase(columnNamesArray[i])#""" >
		</cfloop>
	
		<!--- loop through query and append rows to file --->
		<cfobject type="Java" class="java.io.FileOutputStream" name="fileOutputStreamClass">
		<cfobject type="Java" class="java.io.OutputStreamWriter" name="outputStreamWriterClass">
		<cfobject type="Java" class="java.io.BufferedWriter" name="bufferedWriterClass">
		<cfset fileoutputstream = fileOutputStreamClass.Init("#application.webDirectory#/temp/#filename#.csv",true)>
		<cfset outputstreamwriter = outputStreamWriterClass.Init(fileoutputstream,"utf-8")>
		<cfset bufferedwriter = bufferedWriterClass.Init(outputstreamwriter)>
		<cfif mode EQ "create">
			<cfset bufferedwriter.write("#JavaCast('string',ArrayToList(header,','))#") >
			<cfset bufferedwriter.newLine() >
		</cfif>
		<cfset buffer = CreateObject("java","java.lang.StringBuffer").Init()>
		<cfset stepsToWrite = 1000>
		<cfset counter = 0>
		<cfloop query="queryToConvert">
			<cfset counter = counter + 1>
			<cfset row=[]>
			<cfloop index="j" from="1" to="#columnCount#" step="1">
				<cfset row[j] = queryToConvert["#columnNamesArray[j]#"][queryToConvert.currentRow]>
			</cfloop>
			<cfscript>
				 row = ArrayMap(row, function(item){ return '"' & rereplace(replace(item,'"','""','all'),controlChars,"") & '"' }, "true",2) 
			</cfscript>
			<cfset buffer.Append(JavaCast('string',ArrayToList(row,',')))>
			<cfset buffer.Append(Chr(10))>
			<cfif counter EQ stepsToWrite>
				<cfset bufferedWriter.write(buffer.toString()) >
				<cfset written = written + counter>
				<cfset counter = 0>
				<cfset buffer.setLength(0)>
			</cfif>
		</cfloop>
		<cfif counter NEQ stepsToWrite>
			<cfset bufferedWriter.write(buffer.toString()) >
			<cfset written = written + counter>
			<cfset buffer.setLength(0)>
		</cfif>
		<cfset bufferedWriter.close()>
		<cfset retval.STATUS = "Success">
		<cfset retval.WRITTEN = "#written#">
		<cfset retval.TIMESTAMP= "#timestamp#">
		<cfset retval.FILENAME = "/temp/#filename#.csv">
		<cfset retval.MESSAGE = "Wrote #written# records into temporary file for download.">
	<cfcatch>
		// Failure case 
		<cflog text="#cfcatch.message#" file="MCZbase">
		<cfset retval.WRITTEN = "#written#">
		<cfset retval.TIMESTAMP= "#timestamp#">
		<cfif written GT 0> 
			<cfset retval.STATUS = "Incomplete">
			<cfset retval.FILENAME = "/temp/#filename#.csv">
			<cfset retval.MESSAGE = "Error: #cfcatch.message#. Wrote #written# records into temporary file for download.">
		<cfelse>
			<cfset retval.STATUS = "Failed">
			<cfset retval.MESSAGE = "Error: #cfcatch.message#.">
		</cfif>
		<cfif isDefined("bufferedWriter")>
			<cftry>
				<cfset bufferedWriter.close()>
			<cfcatch></cfcatch>
			</cftry>
		</cfif>
	</cfcatch>
	</cftry>
	<cfreturn retval >
</cffunction>

<!--- getGuidLink given an guid and guid type, return html for a link out to that guid, if
  either guid or guid_guid_type are not supplied or if the the guid_guid_type is not recognized
  in ctguid_type, then returns an empty string.
	@param guid the guid to provide as a link
	@param guid_guid_type the type of  guid, used to apply a replacement pattern to convert the
     guid in stored form into a resolvable link.
   @return html for link to a resource specified by a guid.
--->
<cffunction name="getGuidLink" returntype="string" access="remote" returnformat="plain">
	<cfargument name="guid" type="string" required="no">
	<cfargument name="guid_type" type="string" required="no">
	
	<cfset returnValue = "">
	<cfif len(guid) GT 0 and len(guid_type) GT 0>
		<cfquery name="ctguid_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select resolver_regex, resolver_replacement
			from ctguid_type
			where 
			guid_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#guid_type#">
		</cfquery>
		<cfif ctguid_type.recordcount GT 0>
			<cfif len(ctguid_type.resolver_regex) GT 0 >
				<cfset link = REReplace(guid,ctguid_type.resolver_regex,ctguid_type.resolver_replacement)>
			<cfelse>
				<cfset link = guid>
			</cfif>
			<cfif guid_type EQ "ORCiD">
				<cfset returnValue = "<a href='#link#' aria-label='link to ORCID record'><img src='/shared/images/ORCIDiD_icon.svg' height='15' width='15' class='ml-1' alt='ORCID iD icon'></a>" > <!--- " --->
			<cfelse>
				<cfset returnValue = "<a href='#link#'><img src='/shared/images/linked_data.png' height='15' width='15' alt='linked data icon'></a>" > <!--- " --->
			</cfif>
		</cfif>
	</cfif>
	<cfreturn returnValue>
</cffunction>

<!--- given a table and field return a comment on the field from the schema.

 @param table the name of the table the field is in 
 @param column the field for which to lookup a comment.
 @return the comment or an empty string.
--->
<cffunction name="getCommentForField" returntype="string" access="remote" returnformat="plain">
	<cfargument name="table" type="string" required="no">
	<cfargument name="column" type="string" required="no">

	<cfset table = ucase(table)>
	<cfset column = ucase(column)>

	<cfset returnValue = "">
	<cftry>
		<cfquery name="getComment" datasource="uam_god">
			SELECT all_tab_columns.column_name, comments
			FROM all_tab_columns
				left join all_col_comments 
					on all_tab_columns.table_name = all_col_comments.table_name
					and all_tab_columns.column_name = all_col_comments.column_name
					and all_col_comments.owner = 'MCZBASE'
			WHERE all_tab_columns.table_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#table#"> 
				AND all_tab_columns.owner='MCZBASE'
				and all_tab_columns.column_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#column#">
			ORDER BY column_id
		</cfquery>
		<cfloop query="getComment">
			<cfset returnValue = "#getComment.comments#">
		</cfloop>
	<cfcatch>
	</cfcatch>
	</cftry>
	<cfreturn returnValue>
</cffunction>


<!---
	pickCollectingEventHtml create dialog content to pick a collecting event
  @param collecting_event_id_control the id of an input in the dom into which the 
  selected collecting_event_id should be pasted.
  @param callback may not be needed
  @see findCollectingEventSearchResults 
--->
<cffunction name="pickCollectingEventHtml" access="remote" returntype="string" returnformat="plain">
	<cfargument name="collecting_event_id_control" type="string" required="yes">
	<cfargument name="callback" type="string" required="no" default="reloadCollectingEvent">

	<cfset target_id = collecting_event_id_control>
	<cfthread name="pickCollEventThread">
	<cftry> 
		<cfquery name="ctCollecting_Source" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedWithin="#CreateTimeSpan(0,1,0,0)#">
			SELECT 
				collecting_source 
			FROM
				ctcollecting_source
			ORDER BY 
				collecting_source
		</cfquery>
		<cfoutput>
		<div id="overlaycontainer" style="position: relative;"> 
			<div class='container-fluid'><div class='row'><div class='col-12'>
			<div id='collEventPickSearchForm' class='search-box px-3 py-2'>
			<h1 class='h3 mt-2'>Search for Collecting Events</h1>
			<form id='findCollectingEventForm' onsubmit='return searchforcollectingevents(event);' >
				<input type='hidden' name='method' value='getCollectingEvent'>
				<input type='hidden' name='returnformat' value='plain'>
				<input type='hidden' name='target_id' value='#target_id#'>
	
				<cfset showLocality=1>
				<cfset showEvent=1>
				<cfset showExtraFields=1>
				<div class="form-row mx-0">
					<section class="container-fluid" role="search">
						<cfinclude template = "/localities/searchLocationForm.cfm">
					</section>
				</div>
			
				<div class='form-row mt-2'>
					<div class=''>
						<input type='submit' value='Search' class='btn-primary px-3 mb-2'>
					</div>
				</div>
			</form>
			<!--- Results table as a jqxGrid with a picker cellrenderer. --->
			<section class="container-fluid">
				<div class="row mx-0">
					<div class="col-12">
						<div class="mb-5">
							<div class="row mt-1 mb-0 pb-0 jqx-widget-header border px-2">
								<h1 class="h4">Pick from Results: </h1>
								<span class="d-block px-3 p-2" id="resultCount"></span>
								<div id="columnPickDialog" class="row pick-column-width">
									<div class="col-12 col-md-3">
										<div id="columnPick" class="px-1"></div>
									</div>
									<div class="col-12 col-md-3">
										<div id="columnPick1" class="px-1"></div>
									</div>
									<div class="col-12 col-md-3">
										<div id="columnPick2" class="px-1"></div>
									</div>
									<div class="col-12 col-md-3">
										<div id="columnPick3" class="px-1"></div>
									</div>
								</div>
								<div id="columnPickDialogButton"></div>
							</div>
							<div class="row mt-0"> 
								<!--- Grid Related code is below along with search handlers --->
								<div id="searchResultsGrid" class="jqxGrid" role="table" aria-label="Search Results Table"></div>
								<div id="enableselection"></div>
							</div>
						</div>
					</div>
				</div>
			</section>
	
			<cfset cellRenderClasses = "ml-1">
			<script>
				/** makeLocalitySummary combine row data for locality into a single text string **/
				function makeLocalitySummary(rowData) { 
					var spec_locality = rowData['SPEC_LOCALITY'];
					var id = rowData['LOCALITY_ID'];
					var locality_remarks = rowData['LOCALITY_REMARKS'];
					if (locality_remarks) { remarks = ". Remarks: " + locality_remarks + " "; } else { remarks = ""; }
					var curated_fg = rowData['CURATED_FG'];
					if (curated_fg=="1") { curated = "*"; } else { curated = ""; }
					var sovereign_nation = rowData['SOVEREIGN_NATION'];
					var minimum_elevation = rowData['MINIMUM_ELEVATION'];
					var maximum_elevation = rowData['MAXIMUM_ELEVATION'];
					var orig_elevation_units = rowData['ORIG_ELEV_UNITS'];
					if (minimum_elevation) { 
						elevation = " Elev: " + minimum_elevation;
						if (maximum_elevation && maximum_elevation != minimum_elevation) {
							elevation = elevation + "-" + maximum_elevation;
						}
						elevation = $.trim(elevation + " " + orig_elevation_units) + ". ";
					} else {
						elevation = "";
					}
					var min_depth = rowData['MIN_DEPTH'];
					var max_depth = rowData['MAX_DEPTH'];
					var depth_units = rowData['DEPTH_UNITS'];
					if (min_depth) { 
						depth = " Depth: " + min_depth;
						if (max_depth && max_depth != min_depth) {
							depth = depth + "-" + max_depth;
						}
						depth = $.trim(depth + " " + depth_units) + ". ";
					} else {
						depth = "";
					}
					var plss = rowData['PLSS'];
					var geolatts = rowData['GEOLATTS'];
					if (geolatts) { geology = " [" + geolatts + "] "; } else { geology = ""; } 
					var dec_lat = rowData['DEC_LAT'];
					var dec_long = rowData['DEC_LONG'];
					var datum = rowData['DATUM'];
					var max_error_distance = rowData['MAX_ERROR_DISTANCE'];
					var max_error_units = rowData['MAX_ERROR_UNITS'];
					var extent = rowData['EXTENT'];
					var verificationstatus = rowData['VERIFICATIONSTATUS'];
					var georefmethod = rowData['GEOREFMETHOD'];
					var nogeorefbecause = rowData['NOGEOREFBECAUSE'];
					if (dec_lat) { 
						coordinates = " " + dec_lat + ", " + dec_long + " " + datum + " ±" + max_error_distance + " " + max_error_units +  " " + verificationstatus + " ";
					} else { 
						coordinates = " " + nogeorefbecause + " ";
					}
					if (sovereign_nation) {
						if (sovereign_nation=="[unknown]") { 
							sovereign_nation = " Sovereign Nation: " + sovereign_nation + " ";
						} else {
							sovereign_nation = " " + sovereign_nation + " ";
						}
					}
					if (plss) { plss = " " + plss + " "; } 
					var data = $.trim(spec_locality + geology +  elevation + depth + sovereign_nation + plss + coordinates) + remarks + " (" + id + ")" + curated;
				   return data;
				};
				/** makeEventSummary combine row data for collecting event into a single text string **/
				function makeEventSummary(rowData) { 
					var verbatim_locality = rowData['VERBATIM_LOCALITY'];
					var id = rowData['COLLECTING_EVENT_ID'];
					var remarks = "";
					var coll_event_remarks = rowData['COLL_EVENT_REMARKS'];
					if (coll_event_remarks) { remarks = " Remarks: " + coll_event_remarks + " "; }
					var source = rowData['COLLECTING_SOURCE'];
					var method = rowData['COLLECTING_METHOD'];
					var began_date = rowData['BEGAN_DATE'];
					var ended_date = rowData['ENDED_DATE'];
					var verbatim_date = rowData['VERBATIM_DATE'];
					var start_day = rowData['STARTDAYOFYEAR'];
					var end_day = rowData['ENDDAYOFYEAR'];
					var time = rowData['COLLECTING_TIME'];
					var verb_coordinates = rowData['VERBATIMCOORDINATES'];
					var verb_latitude = rowData['VERBATIMLATITUDE'];
					var verb_longitude = rowData['VERBATIMLONGITUDE'];
					var verb_coordsystem = rowData['VERBATIMCOORDINATESYSTEM'];
					var verb_srs = rowData['VERBATIMSRS'];
					var verbatim_elevation = rowData['VERBATIMELEVATION'];
					var verbatim_depth = rowData['VERBATIMDEPTH'];
					var fish_field_number = rowData['FISH_FIELD_NUMBER'];
					var date = began_date;
					if (began_date == ended_date) { 
						date = began_date;
					} else if (began_date!="" && ended_date!="") { 
						date = began_date + "/" + ended_date;
					}
					if (verbatim_date != "") { 
						date = date + " [" + verbatim_date + "]";
					} 
					var depth_elev = " ";
					if (verbatim_elevation) { depth_elev = " elevation: " + verbatim_elevation + " "; }
					if (verbatim_depth) { depth_elev = depth_elev + " depth: " + verbatim_depth + " "; }
					if (start_day != "" && end_day == "") { 
						date = date + " day:" + start_day;
					} else if (start_day != "" && end_day != "") { 
						date = date + " days:" + start_day + "-" + end_day;
					}
					var fish=""; 
					if (fish_field_number != "") {
						fish = " Ich. Field No: " + fish_field_number + " ";
					}
					var verb_georef = verb_coordinates + " " + verb_latitude + " " + verb_longitude + " " + verb_coordsystem + " " + verb_srs;
					var leadbit = date + " " + time + " " + verbatim_locality;
					var data = leadbit.trim() + " " + source + " " + method + " " + verb_georef + depth_elev + fish + remarks + " (" + id + ")";
				   return data;
				};
				/** createLocalityRowDetailsDialog, create a custom loan specific popup dialog to show details for
					a row of locality data from the locality results grid.
				
					@see createRowDetailsDialog defined in /shared/js/shared-scripts.js for details of use.
				 */
				function createLocalityRowDetailsDialog(gridId, rowDetailsTargetId, datarecord, rowIndex) {
					var columns = $('##' + gridId).jqxGrid('columns').records;
					var content = "<div id='" + gridId+ "RowDetailsDialog" + rowIndex + "'><ul class='card-columns pl-md-3'>";
					if (columns.length < 21) {
						// don't split into columns for shorter sets of columns.
						content = "<div id='" + gridId+ "RowDetailsDialog" + rowIndex + "'><ul>";
					}
					var gridWidth = $('##' + gridId).width();
					var dialogWidth = Math.round(gridWidth/2);
					var locality_id = datarecord['LOCALITY_ID'];
					var collecting_event_id = datarecord['COLLECTING_EVENT_ID'];
					var geog_auth_rec_id = datarecord['GEOG_AUTH_REC_ID'];
					if (dialogWidth < 299) { dialogWidth = 300; }
					for (i = 1; i < columns.length; i++) {
						var text = columns[i].text;
						var datafield = columns[i].datafield;
						if (datafield == 'LOCALITY_ID') { 	
							<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_locality")>
				 				content = content + "<li class='pr-3'><strong>" + text + ":</strong> <a href='/localities/Locality.cfm?locality_id="+locality_id+"' target='_blank'>" + datarecord[datafield] + "</a></li>";
							<cfelse>
				 				content = content + "<li class='pr-3'><strong>" + text + ":</strong> <a href='/localities/viewLocality.cfm?locality_id="+locality_id+"' target='_blank'>" + datarecord[datafield] + "</a></li>";
							</cfif>
						} else if (datafield == 'COLLECTING_EVENT_ID') { 
				 			content = content + "<li class='pr-3'><strong>" + text + ":</strong> <a href='/localities/CollectingEvent.cfm&collecting_event_id="+collecting_event_id+"' target='_blank'>" + datarecord[datafield] + "</a></li>";
						} else if (datafield == 'HIGHER_GEOG') { 
				 			content = content + "<li class='pr-3'><strong>" + text + ":</strong> <a href='/localities/viewHigherGeography.cfm?geog_auth_rec_id="+geog_auth_rec_id+"' target='_blank'>" + datarecord[datafield] + "</a></li>";
						} else if (datafield == 'SPECIMEN_COUNT') { 
							var loc = encodeURIComponent(datarecord['VERBATIM_LOCALITY']);
							var date = encodeURIComponent(datarecord['VEBATIM_DATE']);
				 			content = content + "<li class='pr-3'><strong>" + text + ":</strong> <a href='/Specimens.cfm?execute=true&builderMaxRows=1&action=builderSearch&nestdepth1=1&field1=CATALOGED_ITEM%3ACATALOGED%20ITEM_COLLECTING_EVENT_ID&searchText1=" + loc + "%20" + date + "%20(" + collecting_event_id + ")&searchId1="+ collecting_event_id +"' target='_blank'>" + datarecord[datafield] + "</a></li>";
						} else if (datafield == 'LOCALITY_ID_1' || datafield == 'COLLECTING_EVENT_ID_1') {
							// duplicate column for edit controls, skip
							console.log(datarecord[datafield]);
						} else if (datafield == 'VALID_CATALOG_TERM_FG') { 
							var val = datarecord[datafield];
							var flag = "True";
							if (val=="1") { flat = "False"; }
							content = content + "<li class='pr-3'><strong>Valid For Data Entry:</strong> " + flag + "</li>";
						} else if (datafield == 'summary') {
							content = content + "<li class='pr-3'><strong>" + text + ":</strong> " + makeLocalitySummary(datarecord) + "</li>";
						} else if (datafield == 'ce_summary') {
							content = content + "<li class='pr-3'><strong>" + text + ":</strong> " + makeEventSummary(datarecord) + "</li>";
						} else if (datarecord[datafield] == '') {
							// leave out blank column
							console.log(datafield);
						} else {
							content = content + "<li class='pr-3'><strong>" + text + ":</strong> " + datarecord[datafield] + "</li>";
						}
					}
					content = content + "</ul>";
					content = content + "</div>";
					$("##" + rowDetailsTargetId + rowIndex).html(content);
					$("##"+ gridId +"RowDetailsDialog" + rowIndex ).dialog(
						{
							autoOpen: true,
							buttons: [ { text: "Ok", click: function() { $( this ).dialog( "close" ); $("##" + gridId).jqxGrid('hiderowdetails',rowIndex); } } ],
							width: dialogWidth,
							title: 'Collecting Event Details'
						}
					);
					// Workaround, expansion sits below row in zindex.
					var maxZIndex = getMaxZIndex();
					$("##"+gridId+"RowDetailsDialog" + rowIndex ).parent().css('z-index', maxZIndex + 1);
				};
	
				window.columnHiddenSettings = new Object();
				<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
					lookupColumnVisibilities ('#cgi.script_name#','Default');
				</cfif>
	
				var linkIdCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
					var rowData = jQuery("##searchResultsGrid").jqxGrid('getrowdata',row);
					return '<span class="#cellRenderClasses#" style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; "><a href="/localities/viewLocality.cfm?locality_id=' + rowData['LOCALITY_ID'] + '" target="_blank">'+value+'</a></span>';
				};
				<!--- The Picker --->
				var pickEventCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties, rowData) {
					var id = encodeURIComponent(rowData['COLLECTING_EVENT_ID']);
					return '<button type="button" class="btn btn-xs btn-outline-primary ml-1" onClick=" $(\'##'+target_id+'\').val(\'' + id + ')\'">Pick</button>';
				};
				var summaryCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
					var rowData = jQuery("##searchResultsGrid").jqxGrid('getrowdata',row);
					var data = makeLocalitySummary(rowData);
					return '<span class="#cellRenderClasses#" style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; ">' + data + '</span>';
				}
				var summaryEventCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
					var rowData = jQuery("##searchResultsGrid").jqxGrid('getrowdata',row);
					var data = makeEventSummary(rowData);
					return '<span class="#cellRenderClasses#" style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; ">' + data + '</span>';
				}
				var specimensCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
					var rowData = jQuery("##searchResultsGrid").jqxGrid('getrowdata',row);
					if (value==0) {
						return '<span class="#cellRenderClasses#" style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; ">None</span>';
					} else {
						var loc = encodeURIComponent(rowData['VERBATIM_LOCALITY']);
						var date = encodeURIComponent(rowData['VEBATIM_DATE']);
						var id = encodeURIComponent(rowData['COLLECTING_EVENT_ID']);
						return '<span class="#cellRenderClasses#" style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; "><a href="/Specimens.cfm?execute=true&builderMaxRows=1&action=builderSearch&nestdepth1=1&field1=CATALOGED_ITEM%3ACATALOGED%20ITEM_COLLECTING_EVENT_ID&searchText1=' + loc + '%20' + date + '%20(' + id + ')&searchId1='+ id +'" target="_blank">'+value+'</a></span>';
					}
				};
				<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_locality")>
					var editLocCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties, rowData) {
						var id = encodeURIComponent(rowData['LOCALITY_ID']);
						return '<a target="_blank" class="btn btn-xs btn-outline-primary ml-1" href="/localities/Locality.cfm?locality_id=' + id + '">Loc.</a>';
					};
					var editEventCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties, rowData) {
						var id = encodeURIComponent(rowData['COLLECTING_EVENT_ID']);
						return '<a target="_blank" class="btn btn-xs btn-outline-primary ml-1" href="/localities/CollectingEvent.cfm?collecting_event_id=' + id + '">Evt.</a>';
					};
				</cfif>
	
				$(document).ready(function() {
					/* Setup jqxgrid for Search */
					$('##findCollectingEventForm').bind('submit', function(evt){
						evt.preventDefault();
				
						$("##overlay").show();
				
						$("##searchResultsGrid").replaceWith('<div id="searchResultsGrid" class="jqxGrid" style="z-index: 1;"></div>');
						$('##resultCount').html('');
						$('##resultLink').html('');
				
						var search =
						{
							datatype: "json",
							datafields:
							[
								{ name: 'GEOG_AUTH_REC_ID', type: 'string' },
								{ name: 'CONTINENT_OCEAN', type: 'string' },
								{ name: 'COUNTRY', type: 'string' },
								{ name: 'STATE_PROV', type: 'string' },
								{ name: 'COUNTY', type: 'string' },
								{ name: 'QUAD', type: 'string' },
								{ name: 'FEATURE', type: 'string' },
								{ name: 'ISLAND', type: 'string' },
								{ name: 'ISLAND_GROUP', type: 'string' },
								{ name: 'SEA', type: 'string' },
								{ name: 'VALID_CATALOG_TERM_FG', type: 'string' },
								{ name: 'SOURCE_AUTHORITY', type: 'string' },
								{ name: 'HIGHER_GEOG', type: 'string' },
								{ name: 'OCEAN_REGION', type: 'string' },
								{ name: 'OCEAN_SUBREGION', type: 'string' },
								{ name: 'WATER_FEATURE', type: 'string' },
								{ name: 'WKT_POLYGON', type: 'string' },
								{ name: 'HIGHERGEOGRAPHYID_GUID_TYPE', type: 'string' },
								{ name: 'HIGHERGEOGRAPHYID', type: 'string' },
								{ name: 'SPECIMEN_COUNT', type: 'string' },
								{ name: 'LOCALITY_ID', type: 'string' },
								{ name: 'LOCALITY_ID_1', type: 'string', map: 'LOCALITY_ID' },
								{ name: 'SPEC_LOCALITY', type: 'string' },
								{ name: 'CURATED_FG', type: 'string' },
								{ name: 'SOVEREIGN_NATION', type: 'string' },
								{ name: 'MINIMUM_ELEVATION', type: 'string' },
								{ name: 'MAXIMUM_ELEVATION', type: 'string' },
								{ name: 'ORIG_ELEV_UNITS', type: 'string' },
								{ name: 'MIN_ELEVATION_METERS', type: 'string' },
								{ name: 'MAX_ELEVATION_METERS', type: 'string' },
								{ name: 'MIN_DEPTH', type: 'string' },
								{ name: 'MAX_DEPTH', type: 'string' },
								{ name: 'DEPTH_UNITS', type: 'string' },
								{ name: 'MIN_DEPTH_METERS', type: 'string' },
								{ name: 'MAX_DEPTH_METERS', type: 'string' },
								{ name: 'PLSS', type: 'string' },
								{ name: 'GEOLATTS', type: 'string' },
								{ name: 'COLLCOUNTLOCALITY', type: 'string' },
								{ name: 'DEC_LAT', type: 'string' },
								{ name: 'DEC_LONG', type: 'string' },
								{ name: 'DATUM', type: 'string' },
								{ name: 'MAX_ERROR_DISTANCE', type: 'string' },
								{ name: 'MAX_ERROR_UNITS', type: 'string' },
								{ name: 'COORDINATEUNCERTAINTYINMETERS', type: 'string' },
								{ name: 'EXTENT', type: 'string' },
								{ name: 'VERIFICATIONSTATUS', type: 'string' },
								{ name: 'GEOREFMETHOD', type: 'string' },
								{ name: 'NOGEOREFBECAUSE', type: 'string' },
								{ name: 'GEOREF_VERIFIED_BY_AGENT', type: 'string' },
								{ name: 'GEOREF_DETERMINED_BY_AGENT', type: 'string' },
								{ name: 'LOCALITY_REMARKS', type: 'string' },
								{ name: 'COLLECTING_EVENT_ID', type: 'string' },
								{ name: 'COLLECTING_EVENT_ID_1', type: 'string', map: 'COLLECTING_EVENT_ID' },
								{ name: 'VERBATIM_DATE', type: 'string'},
								{ name: 'VERBATIM_LOCALITY', type: 'string'},
								{ name: 'VALID_DISTRIBUTION_FG', type: 'string'},
								{ name: 'COLLECTING_SOURCE', type: 'string'},
								{ name: 'COLLECTING_METHOD', type: 'string'},
								{ name: 'HABITAT_DESC', type: 'string'},
								{ name: 'DATE_DETERMINED_BY_AGENT_ID', type: 'string'},
								{ name: 'FISH_FIELD_NUMBER', type: 'string'},
								{ name: 'BEGAN_DATE', type: 'string'},
								{ name: 'ENDED_DATE', type: 'string'},
								{ name: 'COLLECTING_TIME', type: 'string'},
								{ name: 'VERBATIMCOORDINATES', type: 'string'},
								{ name: 'VERBATIMLATITUDE', type: 'string'},
								{ name: 'VERBATIMLONGITUDE', type: 'string'},
								{ name: 'VERBATIMCOORDINATESYSTEM', type: 'string'},
								{ name: 'VERBATIMSRS', type: 'string'},
								{ name: 'STARTDAYOFYEAR', type: 'string'},
								{ name: 'ENDDAYOFYEAR', type: 'string'},
								{ name: 'VERBATIMELEVATION', type: 'string'},
								{ name: 'VERBATIMDEPTH', type: 'string'},
								{ name: 'COLL_EVENT_REMARKS', type: 'string' }
							],
							updaterow: function (rowid, rowdata, commit) {
								commit(true);
							},
							root: 'collecting_event',
							id: 'collecting_event_id',
							url: '/localities/component/search.cfc?' + $('##findCollectingEventForm').serialize(),
							timeout: #Application.ajax_timeout#000,  // units not specified, miliseconds? 
							loadError: function(jqXHR, textStatus, error) {
								handleFail(jqXHR,textStatus,error, "Error performing collecting event search: "); 
							},
							async: true
						};
				
						var dataAdapter = new $.jqx.dataAdapter(search, {
							autoBind: true,
							beforeLoadComplete: function (records) {
								var data = new Array();
								for (var i = 0; i < records.length; i++) {
									var coll_event = records[i];
									coll_event.summary = makeLocalitySummary(coll_event);
									coll_event.ce_summary = makeEventSummary(coll_event);
									data.push(coll_event);
								}
								return data;
							}
						});
						var initRowDetails = function (index, parentElement, gridElement, datarecord) {
							// could create a dialog here, but need to locate it later to hide/show it on row details opening/closing and not destroy it.
							var details = $($(parentElement).children()[0]);
							details.html("<div id='rowDetailsTarget" + index + "'></div>");
				
							createLocalityRowDetailsDialog('searchResultsGrid','rowDetailsTarget',datarecord,index);
							// Workaround, expansion sits below row in zindex.
							var maxZIndex = getMaxZIndex();
							$(parentElement).css('z-index',maxZIndex - 1); // will sit just behind dialog
						}
				
						$("##searchResultsGrid").jqxGrid({
							width: '100%',
							autoheight: 'true',
							autorowheight: 'true', // for text to wrap in cells
							source: dataAdapter,
							filterable: true,
							sortable: true,
							pageable: true,
							editable: false,
							pagesize: '50',
							pagesizeoptions: ['5','10','25','50','100'],
							showaggregates: true,
							columnsresize: true,
							autoshowfiltericon: true,
							autoshowcolumnsmenubutton: false,
							autoshowloadelement: false,  // overlay acts as load element for form+results
							columnsreorder: true,
							groupable: true,
							selectionmode: '#defaultSelectionMode#',
							enablebrowserselection: #defaultenablebrowserselection#,
							altrows: true,
							showtoolbar: false,
							columns: [
								{ text: 'Pick', datafield: 'COLLECTING_EVENT_ID_1', width:60, hideable: false, cellsrenderer: pickEventCellRenderer},
								{ text: 'Loc.', datafield: 'LOCALITY_ID_1', width:60, hideable: false, cellsrenderer: linkIdCellRenderer},
								{ text: 'Cat.Items', datafield: 'SPECIMEN_COUNT',width: 100, hideabel: true, hidden: getColHidProp('SPECIMEN_COUNT',false), cellsrenderer: specimensCellRenderer  },
								{ text: 'collecting_event_id', datafield: 'COLLECTING_EVENT_ID',width: 100, hideabel: true, hidden: getColHidProp('COLLECTING_EVENT_ID',true) },
								{ text: 'Locality_id', datafield: 'LOCALITY_ID',width: 100, hideabel: true, hidden: getColHidProp('LOCALITY_ID',true) },
								{ text: 'Locality Summary', datafield: 'summary',width: 400, hideabel: true, hidden: getColHidProp('summary',false) },
								{ text: 'Coll Event Summary', datafield: 'ce_summary',width: 400, hideabel: true, hidden: getColHidProp('summary',false) },
								{ text: 'Verbatim Locality', datafield: 'VERBATIM_LOCALITY',width: 200, hideabel: true, hidden: getColHidProp('VERBATIM_LOCALITY',true)  },
								{ text: 'Verb. Date', datafield: 'VERBATIM_DATE',width: 200, hideabel: true, hidden: getColHidProp('VERBATIM_DATE',true)  },
								{ text: 'Start Date', datafield: 'BEGAN_DATE',width: 200, hideabel: true, hidden: getColHidProp('BEGAN_DATE',true)  },
								{ text: 'End Date', datafield: 'ENDED_DATE',width: 200, hideabel: true, hidden: getColHidProp('ENDED_DATE',true)  },
								{ text: 'Time', datafield: 'COLLECTING_TIME',width: 200, hideabel: true, hidden: getColHidProp('COLLECTING_TIME',true)  },
								{ text: 'Ich. Field No.', datafield: 'FISH_FIELD_NUMBER',width: 200, hideabel: true, hidden: getColHidProp('FISH_FIELD_NUMBER',true)  },
								{ text: 'Coll Method', datafield: 'COLLECTING_METHOD',width: 200, hideabel: true, hidden: getColHidProp('COLLECTING_METHOD',true)  },
								{ text: 'Coll Source', datafield: 'COLLECTING_SOURCE',width: 200, hideabel: true, hidden: getColHidProp('COLLECTING_SOURCE',true)  },
								{ text: 'Time', datafield: 'COLLECTIING_TIME',width: 200, hideabel: true, hidden: getColHidProp('COLLECTIING_TIME',true)  },
								{ text: 'Coll Event Remarks', datafield: 'COLL_EVENT_REMARKS',width: 100, hideabel: true, hidden: getColHidProp('COLL_EVENT_REMARKS',true)  },
								{ text: 'Habitat', datafield: 'HABITAT_DESC',width: 100, hideabel: true, hidden: getColHidProp('HABITAT_DESC',true)  },
								{ text: 'Verb. Coordinates', datafield: 'VERBATIMCOORDINATES',width: 200, hideabel: true, hidden: getColHidProp('VERBATIMCOORDINATES',true)  },
								{ text: 'Verb. Lat.', datafield: 'VERBATIMLATITUDE',width: 200, hideabel: true, hidden: getColHidProp('VERBATIMLATITUDE',true)  },
								{ text: 'Verb. Long.', datafield: 'VERBATIMLONGITUDE',width: 200, hideabel: true, hidden: getColHidProp('VERBATIMLONGITUDE',true)  },
								{ text: 'Verb. Coord System', datafield: 'VERBATIMCOORDINATESYSTEM',width: 200, hideabel: true, hidden: getColHidProp('VERBATIMCOORDINATESYSTEM',true)  },
								{ text: 'Verb. Datum', datafield: 'VERBATIMSRS',width: 150, hideabel: true, hidden: getColHidProp('VERBATIMSRS',true)  },
								{ text: 'Start Day', datafield: 'STARTDAYOFYEAR',width: 100, hideabel: true, hidden: getColHidProp('STARTDAYOFYEAR',true)  },
								{ text: 'End Day', datafield: 'ENDDAYOFYEAR',width: 100, hideabel: true, hidden: getColHidProp('ENDDAYOFYEAR',true)  },
								{ text: 'Verb. Elevation', datafield: 'VERBATIMELEVATION',width: 150, hideabel: true, hidden: getColHidProp('VERBATIMELEVATION',true)  },
								{ text: 'Verb. Depth', datafield: 'VERBATIMDEPTH',width: 150, hideabel: true, hidden: getColHidProp('VERBATIMDEPTH',true)  },
								{ text: 'Specific Locality', datafield: 'SPEC_LOCALITY',width: 200, hideabel: true, hidden: getColHidProp('SPEC_LOCALITY',true)  },
								{ text: 'Vetted', datafield: 'CURATED_FG',width: 50, hideabel: true, hidden: getColHidProp('CURATED_FG',false)  },
								{ text: 'Locality Remarks', datafield: 'LOCALITY_REMARKS',width: 100, hideabel: true, hidden: getColHidProp('LOCALITY_REMARKS',true)  },
								{ text: 'Min Depth', datafield: 'MIN_DEPTH',width: 100, hideabel: true, hidden: getColHidProp('MIN_DEPTH',true)  },
								{ text: 'Max Depth', datafield: 'MAX_DEPTH',width: 100, hideabel: true, hidden: getColHidProp('MAX_DEPTH',true)  },
								{ text: 'Depth Units', datafield: 'DEPTH_UNITS',width: 100, hideabel: true, hidden: getColHidProp('DEPTH_UNITS',true)  },
								{ text: 'Min Depth m', datafield: 'MIN_DEPTH_METERS',width: 100, hideabel: true, hidden: getColHidProp('MIN_DEPTH_METERS',true)  },
								{ text: 'Max Depth m', datafield: 'MAX_DEPTH_METERS',width: 100, hideabel: true, hidden: getColHidProp('MAX_DEPTH_METERS',true)  },
								{ text: 'Min Elevation', datafield: 'MINIMUM_ELEVATION',width: 100, hideabel: true, hidden: getColHidProp('MINIMUM_ELEVATION',true)  },
								{ text: 'Max Elevation', datafield: 'MAXIMUM_ELEVATION',width: 100, hideabel: true, hidden: getColHidProp('MAXIMUM_ELEVATION',true)  },
								{ text: 'Elev Units', datafield: 'ORIG_ELEV_UNITS',width: 100, hideabel: true, hidden: getColHidProp('ORIG_ELEV_UNITS',true)  },
								{ text: 'Min Elevation m', datafield: 'MIN_ELEVATION_METERS',width: 100, hideabel: true, hidden: getColHidProp('MIN_ELEVATION_METERS',true)  },
								{ text: 'Max Elevation m', datafield: 'MAX_ELEVATION_METERS',width: 100, hideabel: true, hidden: getColHidProp('MAX_ELEVATION_METERS',true)  },
								{ text: 'Lat.', datafield: 'DEC_LAT', width: 100, hideable: true, hidden: getColHidProp('DEC_LAT',true) },
								{ text: 'Long.', datafield: 'DEC_LONG', width: 100, hideable: true, hidden: getColHidProp('DEC_LONG',true) },
								{ text: 'Datum', datafield: 'DATUM', width: 100, hideable: true, hidden: getColHidProp('DATUM',true) },
								{ text: 'Error Radius', datafield: 'MAX_ERROR_DISTANCE', width: 100, hideable: true, hidden: getColHidProp('MAX_ERROR_DISTANCE',true) },
								{ text: 'Error Units', datafield: 'MAX_ERROR_UNITS', width: 100, hideable: true, hidden: getColHidProp('MAX_ERROR_UNITS',true) },
								{ text: 'coordinateUncertantyInMeters', datafield: 'COORDINATEUNCERTAINTYINMETERS', width: 100, hideable: true, hidden: getColHidProp('COORDINATEUNCERTAINTYINMETERS',true) },
								{ text: 'Extent', datafield: 'EXTENT', width: 100, hideable: true, hidden: getColHidProp('EXTENT',true) },
								{ text: 'Georef Verifier', datafield: 'GEOREF_VERIFIED_BY_AGENT', width: 100, hideable: true, hidden: getColHidProp('GEOREF_VERIFIED_BY_AGENT',true) },
								{ text: 'Georef Determiner', datafield: 'GEOREF_DETERMINED_BY_AGENT', width: 100, hideable: true, hidden: getColHidProp('GEOREF_DETERMINED_BY_AGENT',true) },
								{ text: 'Verification', datafield: 'VERIFICATIONSTATUS', width: 100, hideable: true, hidden: getColHidProp('VERIFICATIONSTATUS',true) },
								{ text: 'GeoRef Method', datafield: 'GEOREFMETHOD', width: 100, hideable: true, hidden: getColHidProp('GEOREFMETHOD',true) },
								{ text: 'NotGeoreferenced', datafield: 'NOGEOREFBECAUSE', width: 100, hideable: true, hidden: getColHidProp('GEOREFMETHOD',true) },
								{ text: 'Continent/Ocean', datafield: 'CONTINENT_OCEAN',width: 100, hideabel: true, hidden: getColHidProp('CONTINENT_OCEAN',true)  },
								{ text: 'Ocean Region', datafield: 'OCEAN_REGION',width: 100, hideabel: true, hidden: getColHidProp('OCEAN_REGION',true)  },
								{ text: 'Ocean Subregion', datafield: 'OCEAN_SUBREGION',width: 100, hideabel: true, hidden: getColHidProp('OCEAN_SUBREGION',true)  },
								{ text: 'Sea', datafield: 'SEA',width: 100, hideabel: true, hidden: getColHidProp('SEA',true)  },
								{ text: 'Water Feature', datafield: 'WATER_FEATURE',width: 100, hideabel: true, hidden: getColHidProp('WATER_FEATURE',true)  },
								{ text: 'Island Group', datafield: 'ISLAND_GROUP',width: 100, hideabel: true, hidden: getColHidProp('ISLAND_GROUP',true)  },
								{ text: 'Island', datafield: 'ISLAND',width: 100, hideabel: true, hidden: getColHidProp('ISLAND',true)  },
								{ text: 'Country', datafield: 'COUNTRY',width: 100, hideabel: true, hidden: getColHidProp('COUNTRY',true)  },
								{ text: 'Sovereign Nation', datafield: 'SOVEREIGN_NATION',width: 100, hideabel: true, hidden: getColHidProp('SOVEREIGN_NATION',true)  },
								{ text: 'State/Province', datafield: 'STATE_PROV',width: 100, hideabel: true, hidden: getColHidProp('STATE_PROF',true)  },
								{ text: 'County', datafield: 'COUNTY',width: 100, hideabel: true, hidden: getColHidProp('COUNTY',true)  },
								{ text: 'Feature', datafield: 'FEATURE',width: 100, hideabel: true, hidden: getColHidProp('FEATURE',true)  },
								{ text: 'Quad', datafield: 'QUAD',width: 100, hideabel: true, hidden: getColHidProp('QUAD',true)  },
								{ text: 'PLSS', datafield: 'PLSS',width: 100, hideabel: true, hidden: getColHidProp('PLSS',true)  },
								{ text: 'Geological Attributes', datafield: 'GEOLATTS',width: 250, hideabel: true, hidden: getColHidProp('GEOLATTS',true)  },
								{ text: 'Departments', datafield: 'COLLCOUNTLOCALITY',width: 100, hideabel: true, hidden: getColHidProp('COLLCOUNTLOCALITY',true)  },
								{ text: 'Valid', datafield: 'VALID_CATALOG_TERM_FG',width: 50, hideabel: true, hidden: getColHidProp('VALID_CATALOG_TERM_FG',true)  },
								{ text: 'Source Authority', datafield: 'SOURCE_AUTHORITY',width: 100, hideabel: true, hidden: getColHidProp('SOURCE_AUTHORITY',true)  },
								{ text: 'WKT', datafield: 'WKT_POLYGON',width: 80, hideabel: true, hidden: getColHidProp('WKT_POLYGON',true)  },
								{ text: 'GUID Type', datafield: 'HIGHERGEOGRAPHYID_GUID_TYPE',width: 100, hideabel: true, hidden: getColHidProp('HIGHERGEOGRPAHYID_GUID_TYPE',true)  },
								{ text: 'GUID', datafield: 'HIGHERGEOGRAPHYID',width: 100, hideabel: true, hidden: getColHidProp('HIGHERGEOGRAPHYID',true)  }, 
								{ text: 'Higher Geography', datafield: 'HIGHER_GEOG', hideabel: true, hidden: getColHidProp('HIGHER_GEOG',false) }
							],
							rowdetails: true,
							rowdetailstemplate: {
								rowdetails: "<div style='margin: 10px;'>Row Details</div>",
								rowdetailsheight: 1 // row details will be placed in popup dialog
							},
							initrowdetails: initRowDetails
						});
						$("##searchResultsGrid").on("bindingcomplete", function(event) {
							// add a link out to this search, serializing the form as http get parameters
							gridLoaded('searchResultsGrid','collecting event record');
						});
						$('##searchResultsGrid').on('rowexpand', function (event) {
							//  Create a content div, add it to the detail row, and make it into a dialog.
							var args = event.args;
							var rowIndex = args.rowindex;
							var datarecord = args.owner.source.records[rowIndex];
							createLocalityRowDetailsDialog('searchResultsGrid','rowDetailsTarget',datarecord,rowIndex);
						});
						$('##searchResultsGrid').on('rowcollapse', function (event) {
							// remove the dialog holding the row details
							var args = event.args;
							var rowIndex = args.rowindex;
							$("##searchResultsGridRowDetailsDialog" + rowIndex ).dialog("destroy");
						});
					});
					/* End Setup jqxgrid for Search ******************************/
	
				}); /* End document.ready */
		
				function gridLoaded(gridId, searchType) { 
					if (Object.keys(window.columnHiddenSettings).length == 0) { 
						window.columnHiddenSettings = getColumnVisibilities('searchResultsGrid');
						<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
							saveColumnVisibilities('#cgi.script_name#',window.columnHiddenSettings,'Default');
						</cfif>
					}
					$("##overlay").hide();
					var now = new Date();
					var nowstring = now.toISOString().replace(/[^0-9TZ]/g,'_');
					var filename = searchType.replace(/ /g,'_') + '_results_' + nowstring + '.csv';
					// display the number of rows found
					var datainformation = $('##' + gridId).jqxGrid('getdatainformation');
					var rowcount = datainformation.rowscount;
					if (rowcount == 1) {
						$('##resultCount').html('Found ' + rowcount + ' ' + searchType);
					} else { 
						$('##resultCount').html('Found ' + rowcount + ' ' + searchType + 's');
					}
					// set maximum page size
					if (rowcount > 100) { 
						$('##' + gridId).jqxGrid({ pagesizeoptions: ['5','10','25','50', '100', rowcount],pagesize: 50});
					} else if (rowcount > 50) { 
						$('##' + gridId).jqxGrid({ pagesizeoptions: ['5','10','25','50', rowcount],pagesize:50});
					} else if (rowcount > 25) { 
						$('##' + gridId).jqxGrid({ pagesizeoptions: ['5','10','25', rowcount],pagesize:25});
					} else if (rowcount > 10) { 
						$('##' + gridId).jqxGrid({ pagesizeoptions: ['5','10', rowcount],pagesize:rowcount});
					} else { 
						$('##' + gridId).jqxGrid({ pageable: false });
					}
					// add a control to show/hide columns
					var columns = $('##' + gridId).jqxGrid('columns').records;
					var quarterColumns = Math.round(columns.length/4);
	
					var columnListSource = [];
					for (i = 1; i < quarterColumns; i++) {
						var text = columns[i].text;
						var datafield = columns[i].datafield;
						var hideable = columns[i].hideable;
						var hidden = columns[i].hidden;
						var show = ! hidden;
						if (hideable == true) { 
							var listRow = { label: text, value: datafield, checked: show };
							columnListSource.push(listRow);
						}
					} 
					$("##columnPick").jqxListBox({ source: columnListSource, autoHeight: true, width: '260px', checkboxes: true });
					$("##columnPick").on('checkChange', function (event) {
						$("##" + gridId).jqxGrid('beginupdate');
						if (event.args.checked) {
							$("##" + gridId).jqxGrid('showcolumn', event.args.value);
						} else {
							$("##" + gridId).jqxGrid('hidecolumn', event.args.value);
						}
						$("##" + gridId).jqxGrid('endupdate');
					});
	
					var columnListSource1 = [];
					for (i = quarterColumns; i < (quarterColumns*2); i++) {
						var text = columns[i].text;
						var datafield = columns[i].datafield;
						var hideable = columns[i].hideable;
						var hidden = columns[i].hidden;
						var show = ! hidden;
						if (hideable == true) { 
							var listRow = { label: text, value: datafield, checked: show };
							columnListSource1.push(listRow);
						}
					} 
					$("##columnPick1").jqxListBox({ source: columnListSource1, autoHeight: true, width: '260px', checkboxes: true });
					$("##columnPick1").on('checkChange', function (event) {
						$("##" + gridId).jqxGrid('beginupdate');
						if (event.args.checked) {
							$("##" + gridId).jqxGrid('showcolumn', event.args.value);
						} else {
							$("##" + gridId).jqxGrid('hidecolumn', event.args.value);
						}
						$("##" + gridId).jqxGrid('endupdate');
					});
	
					var columnListSource2 = [];
					for (i = (quarterColumns*2); i < (quarterColumns*3); i++) {
						var text = columns[i].text;
						var datafield = columns[i].datafield;
						var hideable = columns[i].hideable;
						var hidden = columns[i].hidden;
						var show = ! hidden;
						if (hideable == true) { 
							var listRow = { label: text, value: datafield, checked: show };
							columnListSource2.push(listRow);
						}
					} 
					$("##columnPick2").jqxListBox({ source: columnListSource2, autoHeight: true, width: '260px', checkboxes: true });
					$("##columnPick2").on('checkChange', function (event) {
						$("##" + gridId).jqxGrid('beginupdate');
						if (event.args.checked) {
							$("##" + gridId).jqxGrid('showcolumn', event.args.value);
						} else {
							$("##" + gridId).jqxGrid('hidecolumn', event.args.value);
						}
						$("##" + gridId).jqxGrid('endupdate');
					});
	
					var columnListSource3 = [];
					for (i = (quarterColumns*3); i < columns.length; i++) {
						var text = columns[i].text;
						var datafield = columns[i].datafield;
						var hideable = columns[i].hideable;
						var hidden = columns[i].hidden;
						var show = ! hidden;
						if (hideable == true) { 
							var listRow = { label: text, value: datafield, checked: show };
							columnListSource3.push(listRow);
						}
					} 
					$("##columnPick3").jqxListBox({ source: columnListSource3, autoHeight: true, width: '260px', checkboxes: true });
					$("##columnPick3").on('checkChange', function (event) {
						$("##" + gridId).jqxGrid('beginupdate');
						if (event.args.checked) {
							$("##" + gridId).jqxGrid('showcolumn', event.args.value);
						} else {
							$("##" + gridId).jqxGrid('hidecolumn', event.args.value);
						}
						$("##" + gridId).jqxGrid('endupdate');
					});
	
					$("##columnPickDialog").dialog({ 
						height: 'auto', 
						width: 'auto',
						adaptivewidth: true,
						title: 'Show/Hide Columns',
						autoOpen: false,
						modal: true, 
						reszable: true, 
						buttons: { 
							Ok: function(){
								window.columnHiddenSettings = getColumnVisibilities('searchResultsGrid');
								<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
									saveColumnVisibilities('#cgi.script_name#',window.columnHiddenSettings,'Default');
								</cfif>
								$(this).dialog("close"); 
							}
						},
						open: function (event, ui) { 
							var maxZIndex = getMaxZIndex();
							// force to lie above the jqx-grid-cell and related elements, see z-index workaround below
							$('.ui-dialog').css({'z-index': maxZIndex + 4 });
							$('.ui-widget-overlay').css({'z-index': maxZIndex + 3 });
						} 
					});
					$("##columnPickDialogButton").html(
						"<button id='columnPickDialogOpener' onclick=\" $('##columnPickDialog').dialog('open'); \" class='btn-xs btn-secondary px-3 py-1 mt-1 mx-3' >Show/Hide Columns</button>"
					);
					// workaround for menu z-index being below grid cell z-index when grid is created by a loan search.
					// likewise for the popup menu for searching/filtering columns, ends up below the grid cells.
					var maxZIndex = getMaxZIndex();
					$('.jqx-grid-cell').css({'z-index': maxZIndex + 1});
					$('.jqx-grid-group-cell').css({'z-index': maxZIndex + 1});
					$('.jqx-menu-wrapper').css({'z-index': maxZIndex + 2});
				}
			</script> 
			<div id='collEventPickerDlg1_#target_id#'></div>
			<div id='collEventSearchResults' class='container-fluid mt-1'></div>
			</div></div>
			</div></div>
			<div id="overlay" style="position: absolute; top:0px; left:0px; width: 100%; height: 100%; background: rgba(0,0,0,0.5); opacity: 0.99; display: none; z-index: 2;">
				<div class="jqx-rc-all jqx-fill-state-normal" style="position: absolute; left: 50%; top: 25%; width: 10em; height: 2.4em;line-height: 2.4em; padding: 5px; color: ##333333; border-color: ##898989; border-style: solid; margin-left: -5em; opacity: 1;">
					<div class="jqx-grid-load" style="float: left; overflow: hidden; height: 32px; width: 32px;"></div>
					<div style="float: left; display: block; margin-left: 1em;" >Searching...</div>
				</div>
			</div>
		</div><!--- end overlayContainer --->
		</cfoutput>
	<cfcatch> 
		<cfset result = "Error: " & cfcatch.type & " " & cfcatch.message & " " & cfcatch.detail >
		<cfoutput>#result#</cfoutput>
	</cfcatch>
	</cftry>
	</cfthread>
	<cfthread action="join" name="pickCollEventThread" />
	<cfreturn pickCollEventThread.output>
</cffunction>

</cfcomponent>
