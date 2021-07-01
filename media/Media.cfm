<!--
Media.cfm

Copyright 2008-2017 Contributors to Arctos
Copyright 2008-2020 President and Fellows of Harvard College

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

-->
<cfif NOT isdefined("action")>
	<cfset action = "edit">
</cfif>
<cfset pageTitle = "Manage Media">
<cfswitch expression="#action#">
	<cfcase value="new">
		<cfset pageTitle = "New Media Record">
	</cfcase>
	<cfcase value="edit">
		<cfset pageTitle = "Edit Media Record">
	</cfcase>
</cfswitch>

<cfinclude template = "/shared/_header.cfm">

<cfquery name="ctmedia_relationship" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
	select media_relationship from ctmedia_relationship order by media_relationship
</cfquery>
<cfquery name="ctmedia_label" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
	select media_label from ctmedia_label order by media_label
</cfquery>
<cfquery name="ctmedia_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
	select media_type from ctmedia_type order by media_type
</cfquery>
<cfquery name="ctmime_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
	select mime_type from ctmime_type order by mime_type
</cfquery>
<cfquery name="ctmedia_license" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select media_license_id,display media_license from ctmedia_license order by media_license_id
</cfquery>

<!---------------------------------------------------------------------------------------------------->
<cfswitch expression="#action#">
	<cfcase value="edit">
		<cfquery name="media" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select MEDIA_ID, MEDIA_URI, MIME_TYPE, MEDIA_TYPE, PREVIEW_URI, MEDIA_LICENSE_ID, MASK_MEDIA_FG,
				mczbase.get_media_descriptor(media_id) as alttag 
			from media 
			where media_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
		</cfquery>
		<cfquery name="labels"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select
				media_label,
				label_value,
				agent_name,
				media_label_id
			from
				media_labels,
				preferred_agent_name
			where
				media_labels.assigned_by_agent_id=preferred_agent_name.agent_id (+) and
				media_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
		</cfquery>
		<cfquery name="tag"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select count(*) c 
			from tag 
			where media_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
		</cfquery>
		<cfset relns=getMediaRelations(#media_id#)>
		<cfoutput>
			<div class="container">
				<div class="row mb-4">
					<div class="col-12">
						<h1 class="h2">Edit Media <i class="fas fa-info-circle" onClick="getMCZDocs('Edit/Delete_Media')" aria-label="help link"></i>  </h1>
						<a href="/TAG.cfm?media_id=#media_id#">edit #tag.c# TAGs</a> ~ <a href="/showTAG.cfm?media_id=#media_id#">View #tag.c# TAGs</a> ~ <a href="/MediaSearch.cfm?action=search&media_id=#media_id#" class="btn btn-xs btn-info">Detail Page</a>
					<form name="editMedia" method="post" action="media.cfm">
						<div class="border px-3 pb-2">
							<input type="hidden" name="action" value="saveEdit">
							<input type="hidden" id="number_of_relations" name="number_of_relations" value="#relns.recordcount#">
							<input type="hidden" id="number_of_labels" name="number_of_labels" value="#labels.recordcount#">
							<input type="hidden" id="media_id" name="media_id" value="#media_id#">
							<div class="form-row mt-1">
								<div class="col-12">
									<label for="media_uri" class="data-entry-label">Media URI (<a href="#media.media_uri#" class="infoLink" target="_blank">open</a>)</label>
									<input type="text" name="media_uri" id="media_uri" size="90" value="#media.media_uri#" class="data-entry-input">
										<cfif #media.media_uri# contains #application.serverRootUrl#>
											<span class="infoLink" onclick="generateMD5()">Generate Checksum</span>
										</cfif>
								</div>
							</div>
							<div class="form-row mt-1">
								<div class="col-12">
									<label for="preview_uri" class="data-entry-label">Preview URI
										<cfif len(media.preview_uri) gt 0>
											(<a href="#media.preview_uri#" class="infoLink" target="_blank">open</a>)
										</cfif>
									</label>
									<input type="text" name="preview_uri" id="preview_uri" size="90" value="#media.preview_uri#" class="data-entry-input">
									<!--- <span class="infoLink" onclick="clickUploadPreview()">Load...</span> --->
								</div>
							</div>
							<div class="form-row mt-1">
								<div class="col-12 col-md-6">
									<label for="mime_type" class="data-entry-label">MIME Type</label>
									<select name="mime_type" id="mime_type" class="data-entry-select">
										<cfloop query="ctmime_type">
											<option <cfif #media.mime_type# is #ctmime_type.mime_type#> selected="selected"</cfif> value="#mime_type#">#mime_type#</option>
										</cfloop>
									</select>
								</div>
								<div class="col-12 col-md-6">
									<label for="media_type" class="data-entry-label">Media Type</label>
									<select name="media_type" id="media_type" class="data-entry-select">
									<cfloop query="ctmedia_type">
										<option <cfif #media.media_type# is #ctmedia_type.media_type#> selected="selected"</cfif> value="#media_type#">#media_type#</option>
									</cfloop>
									</select>
								</div>
							</div>
							<div class="form-row mt-1">
								<div class="col-12 col-md-6">
									<label for="media_license_id" class="data-entry-label">License (<span class="infoLink" onclick="popupDefine();">Define</span>)</label>
									<select name="media_license_id" id="media_license_id" class="data-entry-select">
										<option value="">NONE</option>
										<cfloop query="ctmedia_license">
										<option <cfif media.media_license_id is ctmedia_license.media_license_id> selected="selected"</cfif> value="#ctmedia_license.media_license_id#">#ctmedia_license.media_license#</option>
										</cfloop>
									</select>
								</div>
								<div class="col-12 col-md-6">
									<label for="mask_media_fg" class="data-entry-label">Media Record Visibility</label>
									<select name="mask_media_fg" value="mask_media_fg" class="data-entry-select">
										<cfif #media.mask_media_fg# eq 1 >
											<option value="0">Public</option>
											<option value="1" selected="selected">Hidden</option>
										<cfelse>
											<option value="0" selected="selected">Public</option>
											<option value="1">Hidden</option>
										</cfif>
									</select>
								</div>
							</div>
							<div class="form-row mx-0 mt-1">
								<div class="bg-light rounded border col-12 mt-2 px-3 py-1">
									<h3 class="h5" title="alternative text for vision impaired users">Alternative text for vision impared users:</h3>
									<p class="small">#media.alttag#</p>
								</div>
							</div>
							<div class="form-row mt-2">
								<div class="col-12">
									 <label for="relationships" class="data-entry-label">Media Relationships | <span class="text-secondary" onclick="manyCatItemToMedia('#media_id#')">Add multiple "shows cataloged_item" records</span></label>
									<div id="relationships">
										<cfset i=1>
										<cfif relns.recordcount is 0>
											<!--- seed --->
											<div id="seedMedia" style="display:none">
												<input type="hidden" id="media_relations_id__0" name="media_relations_id__0">
												<cfset d="">
												<select name="relationship__0" id="relationship__0" class="data-entry-select col-6" size="1"  onchange="pickedRelationship(this.id)">
													<option value="delete">delete</option>
													<cfloop query="ctmedia_relationship">
														<option <cfif #d# is #media_relationship#> selected="selected" </cfif>value="#media_relationship#">#media_relationship#</option>
													</cfloop>
												</select>
												<input type="text" name="related_value__0" id="related_value__0" class="data-entry-input col-6">
												<input type="hidden" name="related_id__0" id="related_id__0">
											</div>
											<!--- end seed data --->
										</cfif>
										
										<cfloop query="relns">
											<cfset d=media_relationship>
										<div class="form-row col-12 px-0 mx-0">
											<input type="hidden" id="media_relations_id__#i#" name="media_relations_id__#i#" value="#media_relations_id#">
												<label class="sr-only" for="relationship__#i#">Relationship</label>
												<select name="relationship__#i#" id="relationship__#i#" size="1"  onchange="pickedRelationship(this.id)" class="data-entry-select custom-select col-6">
														<option value="delete">delete</option>
														<cfloop query="ctmedia_relationship">
															<option <cfif #d# is #media_relationship#> selected="selected" </cfif>value="#media_relationship#">#media_relationship#</option>
														</cfloop>
													</select>
												<input type="text" name="related_value__#i#" id="related_value__#i#" value="#summary#" class="data-entry-input col-6">
												<input type="hidden" name="related_id__#i#" id="related_id__#i#" value="#related_primary_key#">
												<cfset i=i+1>
										</div>
										</cfloop>
											<span class="infoLink h5 box-shadow-0 d-block col-12 col-md-2 offset-md-10 text-right my-1" id="addRelationship" onclick="addRelation(#i#)">Add Relationship (+)</span>
										</div>
									</div>	
			</div>
							<div class="form-row mt-2">
								<div class="col-12">	
									<label for="labels" class="data-entry-label">Media Labels  | <span class="text-secondary">Note: For media of permits, correspondence, and other transaction related documents, please enter a 'description' media label.</span></label> 
									<div id="labels">
										<cfset i=1>
										<cfif labels.recordcount is 0>
											<!--- seed --->
											<div id="seedLabel" style="display:none;">
												<div id="labelsDiv__0" class="form-row mx-0 col-12">
													<input type="hidden" id="media_label_id__0" name="media_label_id__0">
													<cfset d="">
													<label for="label__#i#" class='sr-only'>Media Label</label>
													<select name="label__0" id="label__0" size="1" class="col-6 data-entry-select">
														<option value="delete">delete</option>
														<cfloop query="ctmedia_label">
															<option <cfif #d# is #media_label#> selected="selected" </cfif>value="#media_label#">#media_label#</option>
														</cfloop>
													</select>
													<input type="text" name="label_value__0" id="label_value__0" class="col-6 data-entry-input">
												</div>
											</div>
											<!--- end labels seed --->
										</cfif>
										<div class="form-row">
										<cfloop query="labels">
											<cfset d=media_label>
											<div id="labelsDiv__#i#" class="col-12 form-row mx-0">		
												<input type="hidden" id="media_label_id__#i#" name="media_label_id__#i#" value="#media_label_id#" class="data-entry-input">
													<label class="pt-0 pb-1 sr-only" for="label__#i#">Media Label</label>
													<select name="label__#i#" id="label__#i#" size="1" class="data-entry-select custom-select col-6">
															<option value="delete">delete</option>
															<cfloop query="ctmedia_label">
																<option <cfif #d# is #media_label#> selected="selected" </cfif>value="#media_label#">#media_label#</option>
															</cfloop>
													</select>
													<input type="text" name="label_value__#i#" id="label_value__#i#" value="#encodeForHTML(label_value)#" class="data-entry-input col-6">
											</div>
													<cfset i=i+1>
											
										</cfloop>
											<span class="infoLink h5 box-shadow-0 col-12 col-md-2 offset-md-10 d-block text-right my-1" id="addLabel" onclick="addLabelTo(#i#,'labels','addLabel');">Add Label (+)</span> 
										</div>
									</div>	
									
								</div>
								</div>
					<!---  TODO: Make for main form only, set relations/labels as separate ajax calls ---->
							<div class="form-row mt-2 mb-4">
								<div class="col-12">
									<!---  TODO: Change to ajax save of form. ---->
									<input type="submit" value="Save Edits"	class="btn btn-xs btn-primary">
								</div>
							</div>
							</div>
							<!--  TODO: Change to ajax save of form. 
							<script>
								$(document).ready(function() {
									monitorForChanges('editMediaForm',handleChange);
								});
								function saveEdits(){ 
									saveEditsFromForm("editMediaForm","/media/component/functions.cfc","saveResultDiv","saving media record");
								};
							</script>
							-->
						</form>
					</div>
				</div>
			</div>
		</cfoutput>
	</cfcase>
	<!---------------------------------------------------------------------------------------------------->
	<cfcase value="new">
		<cfoutput>
			<div class="container">
				<div class="row">
					<div class="col-12">
				
          <h1 class="h2">Create Media <i onClick="getMCZDocs('Media')" class="fas fa-circle-info" alt="[ help ]"></h1>
   
    <form name="newMedia" method="post" action="media.cfm">
      <input type="hidden" name="action" value="saveNew">
      <input type="hidden" id="number_of_relations" name="number_of_relations" value="1">
      <input type="hidden" id="number_of_labels" name="number_of_labels" value="1">
      <label for="media_uri">Media URI</label>
      <input type="text" name="media_uri" id="media_uri" size="105" class="reqdClr">
      <!--- <span class="infoLink" id="uploadMedia">Upload</span> --->
      <label for="preview_uri">Preview URI</label>
      <input type="text" name="preview_uri" id="preview_uri" size="105">
      <label for="mime_type">MIME Type</label>
      <select name="mime_type" id="mime_type" class="reqdClr" style="width: 160px;">
        <option value=""></option>
        <cfloop query="ctmime_type">
          <option value="#mime_type#">#mime_type#</option>
        </cfloop>
      </select>
      <label for="media_type">Media Type</label>
      <select name="media_type" id="media_type" class="reqdClr" style="width: 160px;">
        <option value=""></option>
        <cfloop query="ctmedia_type">
          <option value="#media_type#">#media_type#</option>
        </cfloop>
      </select>
      <div class="license_box" style="padding-bottom: 1em;padding-left: 1.15em;">
        <label for="media_license_id">License  <a class="infoLink" onClick="popupDefine()">Define Licenses</a></label>
        <select name="media_license_id" id="media_license_id" style="width:300px;">
          <option value="">Research copyright &amp; then choose...</option>
          <cfloop query="ctmedia_license">
            <option value="#media_license_id#">#media_license#</option>
          </cfloop>
        </select>
       <br/>
        <ul class="lisc">
            <p>Notes:</p>
          <li>media should not be uploaded until copyright is assessed and, if relevant, permission is granted (<a href="https://code.mcz.harvard.edu/wiki/index.php/Non-MCZ_Digital_Media_Licenses/Assignment" target="_blank">more info</a>)</li>
          <li>remove media immediately if owner requests it</li>
          <li>contact <a href="mailto:mcz_collections_operations@oeb.harvard.edu?subject=media licensing">MCZ Collections Operations</a> if additional licensing situations arise</li>
        </ul>
      </div>
      <label for="mask_media_fg">Media Record Visibility</label>
      <select name="mask_media_fg" value="mask_media_fg">
           <option value="0" selected="selected">Public</option>
           <option value="1">Hidden</option>
      </select>
   
      <label for="relationships" style="margin-top:.5em;">Media Relationships</label>
      <div id="relationships" class="graydot">
        <div id="relationshiperror"></div>
        <select name="relationship__1" id="relationship__1" size="1" onchange="pickedRelationship(this.id)" style="width: 200px;">
          <option value="">None/Unpick</option>
          <cfloop query="ctmedia_relationship">
            <option value="#media_relationship#">#media_relationship#</option>
          </cfloop>
        </select>
        :&nbsp;
        <input type="text" name="related_value__1" id="related_value__1" size="70" readonly>
        <input type="hidden" name="related_id__1" id="related_id__1">
       <br>
        <span class="infoLink" id="addRelationship" onclick="addRelation(2)">Add Relationship</span> </div>
 
      <label for="labels" style="margin-top:.5em;">Media Labels</label>
      <p>Note: For media of permits, correspondence, and other transaction related documents, please enter a 'description' media label.</p><label for="labels">Media Labels <span class="likeLink" onclick="getCtDoc('ctmedia_label');"> Define</span></label>
      <div id="labels" class="graydot" style="padding: .5em .25em;">
      <cfset i=1>
      	<cfloop>
 		       <div id="labelsDiv__#i#">
      	    <select name="label__#i#" id="label__#i#" size="1">
            <option value="delete">Select label...</option>
            <cfloop query="ctmedia_label">
              <option value="#media_label#">#media_label#</option>
            </cfloop>
          </select>
          :&nbsp;
          <input type="text" name="label_value__#i#" id="label_value__#i#" size="80" value="">
			 </div>
			 <cfset i=i+1>
			</cfloop>
        	<span class="infoLink" id="addLabel" onclick="addLabelTo(#i#,'labels','addLabel');">Add Label</span>
      </div>
        
      <input type="submit" 
				value="Create Media" 
				class="insBtn"
				onmouseover="this.className='insBtn btnhov'" 
				onmouseout="this.className='insBtn'">

    </form>
    <cfif isdefined("collection_object_id") and len(collection_object_id) gt 0>
       <cfquery name="s"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
          select guid from flat where collection_object_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
       </cfquery>
       <script language="javascript" type="text/javascript">
          $("##relationship__1").val('shows cataloged_item');
          $("##related_value__1").val('#s.guid#');
          $("##related_id__1").val('#collection_object_id#');
       </script>
    </cfif>
    <cfif isdefined("relationship") and len(relationship) gt 0>
      <cfquery name="s"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select media_relationship from ctmedia_relationship where media_relationship= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#relationship#">
      </cfquery>
      <cfif s.recordCount eq 1 >
         <script language="javascript" type="text/javascript">
         <script language="javascript" type="text/javascript">
            $("##relationship__1").val('#relationship#');
            $("##related_value__1").val('#related_value#');
            $("##related_id__1").val('#related_id#');
         </script>
      <cfelse>
          <script language="javascript" type="text/javascript">
				$("##relationshiperror").html('<h2>Error: Unknown media relationship type "#relationship#"</h2>');
         </script>
      </cfif>
    </cfif>

					</div>
				</div>
			</div>
		</cfoutput>
	</cfcase>
	<!---------------------------------------------------------------------------------------------------->
	<cfcase value="saveNew">
		<!--- See also function createMedia in /media/component/functions.cfc, which can back an ajax call to create a new media record. --->
		<cftransaction>
			<cftry>
				<cfquery name="mid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select sq_media_id.nextval nv from dual
				</cfquery>
				<cfset media_id=mid.nv>
				<cfquery name="makeMedia" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					insert into media (
							media_id,
							media_uri,
							mime_type,
							media_type,
							preview_uri
						 	<cfif len(media_license_id) gt 0>
								,media_license_id
							</cfif>
						) values (
							<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">,
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#media_uri#">,
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#mime_type#">,
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#media_type#">,
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#preview_uri#">
							<cfif len(media_license_id) gt 0>
								,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_license_id#">
							</cfif>
						)
				</cfquery>
				<cfquery name="makeDescriptionRelation" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					insert into media_labels (
						media_id,
						media_label,
						label_value
					) values (
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">,
						'description',
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#description#">
					)
				</cfquery>
				<cfloop from="1" to="#number_of_relations#" index="n">
					<cfset thisRelationship = #evaluate("relationship__" & n)#>
					<cfset thisRelatedId = #evaluate("related_id__" & n)#>
					<cfset thisTableName=ListLast(thisRelationship," ")>
					<cfif len(#thisRelationship#) gt 0 and len(#thisRelatedId#) gt 0>
						<cfquery name="makeRelation" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							insert into media_relations (
								media_id,
								media_relationship,
								related_primary_key
							) values (
								<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">,
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#thisRelationship#">,
								<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#thisRelatedId#">
							)
						</cfquery>
					</cfif>
				</cfloop>
				<cfloop from="1" to="#number_of_labels#" index="n">
					<cfset thisLabel = #evaluate("label__" & n)#>
					<cfset thisLabelValue = #evaluate("label_value__" & n)#>
					<cfif len(#thisLabel#) gt 0 and len(#thisLabelValue#) gt 0>
						<cfquery name="makeRelation" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							insert into media_labels (
								media_id,
								media_label,
								label_value
							) values (
								<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">,
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#thisLabel#">,
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#thisLabelValue#">
							)
						</cfquery>
					</cfif>
				</cfloop>
				<cfset error=false>
			<cfcatch>
				<cftransaction action="rollback">
				<cfset error=true>
				<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ""></cfif>
				<cfset message = trim("Error processing #GetFunctionCalledName()#: " & cfcatch.message & " " & cfcatch.detail & " " & queryError) >
				<cfheader statusCode="500" statusText="#message#">
				<cfoutput>
					<div class="container">
						<div class="row">
							<div class="alert alert-danger" role="alert">
								<img src="/shared/images/Process-stop.png" alt="[ error ]" style="float:left; width: 50px;margin-right: 1em;">
								<cfif cfcatch.detail contains "ORA-00001: unique constraint (MCZBASE.U_MEDIA_URI)" >
									<h2>A media record for that resource already exists in MCZbase.</h2>
								<cfelse>
									<h2>Internal Server Error.</h2>
								</cfif>
								<p>#message#</p>
								<p><a href="/info/bugs.cfm">“Feedback/Report Errors”</a></p>
							</div>
						</div>
					</div>
				</cfoutput>
			</cfcatch>
			</cftry>
		</cftransaction>
			<cfif error EQ false>
			<cfoutput>
				<cflocation url="media.cfm?action=edit&media_id=#media_id#" addtoken="false">
			</cfoutput>
		</cfif>
	</cfcase>
</cfswitch>

<cfinclude template="/shared/_footer.cfm">
