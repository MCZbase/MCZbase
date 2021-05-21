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
							<input type='button' onClick=""opencreatemediadialog('newMediaDlg1_#target_id#','#target_label#','#target_id#','#relationship#',reloadTransMedia);"" 
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

</cfcomponent>
