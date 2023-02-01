<!--
media/Media.cfm

media record editor

Copyright 2008-2017 Contributors to Arctos
Copyright 2008-2022 President and Fellows of Harvard College

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
<cfinclude template="/media/component/search.cfc" runOnce="true">

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
		<cfif NOT isDefined("media_id") OR len(media_id) EQ 0>
			<!--- redirect to media search page --->
			<cflocation url="/media/findMedia.cfm" addtoken="false">
		</cfif>
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
				auto_host,
				auto_path,
				auto_filename,
				mczbase.get_media_descriptor(media_id) as alttag, MCZBASE.get_media_title(media.media_id) as caption 
			from 
				media
			where 
				media_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
		</cfquery>
		<cfquery name="getRelations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select media_relations_id, media_id, media_relationship,created_by_agent_id, related_primary_key 
			from 
				media_relations 
			where 
				media_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
		</cfquery>
		<cfquery name="labels"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select
				media_label, label_value, agent_name, media_label_id
			from
				media_labels,
				preferred_agent_name
			where
				media_labels.assigned_by_agent_id=preferred_agent_name.agent_id (+) and
				media_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
		</cfquery>

		<cfoutput>

			<div class="container-fluid container-xl">
				<div class="row mx-0">
					<div class="col-12 mt-3 pb-5">
						<h1 class="h2 px-1 border-bottom border-dark pb-2">Edit Media 
							<i class="fas fa-info-circle" onClick="getMCZDocs('Edit/Delete_Media')" aria-label="help link"></i>
							<a href="/MediaSearch.cfm?action=search&media_id=#media_id#" class="btn btn-xs btn-info float-right">Media Record</a>
						</h1>
						<div class="px-1">
							<h4 class="pr-3 d-inline-block">Media ID = media/#media_id#</h4>
						</div>
						<form name="editMedia" method="post" action="Media.cfm" class="my-2">
							<input type="hidden" name="action" value="saveEditMedia">
							<input type="hidden" id="number_of_relations" name="number_of_relations" value="#getRelations.recordcount#">
							<input type="hidden" id="media_relations_id" name="media_relations_id" value="#getRelations.media_relations_id#">
							<input type="hidden" id="media_relationship" name="media_relationship" value="#getRelations.media_relationship#">
							<input type="hidden" id="related_primary_key" name="related_primary_key" value="#getRelations.related_primary_key#">
							<input type="hidden" id="media_id" name="media_id" value="#media.media_id#">
							<div class="col-12 px-1 float-left">
								<div class="rounded border bg-light col-12 col-sm-6 col-md-3 col-xl-2 float-left mb-3 pt-3 pb-2">
							<!---		<cfset mediablock= getMediaBlockHtml(media_id="#media.media_id#",size="400",captionAs="textFull")>
									<div class="mx-auto text-center pt-1" id="mediaBlock#media.media_id#"> #mediablock# </div>--->
									<cfset mediablock= getMediaBlockHtml(media_id="#media_id#",size="300",captionAs="textLinks")>
								<div class="mx-auto text-center h3 pt-1" id="mediaBlock#media.media_id#"> #mediablock# </div>
								</div>
								<div class="col-12 col-md-9 col-xl-10 pb-4 pb-xl-2 px-0 px-md-2 float-left">
									<div class="col-12 col-xl-9 px-0 px-xl-2 float-left">
										<div class="form-row mx-0 mt-2">	
											<label for="media_uri" class="h5 mb-1 mt-0 data-entry-label">Media URI (<a href="#media.media_uri#" class="infoLink" target="_blank">open</a>)</label>
											<cfif #media.media_uri# contains #application.serverRootUrl#>
											<input type="text" name="media_uri" id="media_uri" size="90" value="#media.media_uri#" class="data-entry-input small reqdClr">
											</cfif>
											<cfif media.auto_host EQ "mczbase.mcz.harvard.edu">
												<cfset file = "#Application.webDirectory#/#media.auto_path##media.auto_filename#">
												<cfset directory = "#Application.webDirectory#/#media.auto_path#">
												<cfset iiifSchemeServerPrefix = "#Application.protocol#://iiif.mcz.harvard.edu/iiif/3/">
												<cfset iiifIdentifier = "#encodeForURL(replace(auto_path,'/specimen_images/',''))##encodeForURL(auto_filename)#">
												<cfif fileExists(file)>
													<output id="fileStatusOutput">[File Exists]</output>
												<cfelse>
													<output id="fileStatusOutput">
													[File Not Found]
													<cfif NOT directoryExists(directory)>[Directory Not Found]</cfif>
													</output>
												</cfif>
											</cfif>
											<cfif #media.media_uri# contains #application.serverRootUrl#>
												<span class="infoLink" onclick="generateMD5()">Generate Checksum</span>
											</cfif>
										</div><!---end form-row--->
										<div class="form-row mx-0 mt-2">
											<label for="preview_uri" class="h5 mb-1 mt-2 data-entry-label">Preview URI
												<cfif len(media.preview_uri) gt 0>
													(<a href="#media.preview_uri#" class="infoLink" target="_blank">open</a>)
												</cfif>
											</label>
											<input type="text" name="preview_uri" id="preview_uri" size="90" value="#media.preview_uri#" class="data-entry-input small reqdClr"><!--- <span class="infoLink" onclick="clickUploadPreview()">Load...</span> --->
										</div><!---end form-row--->
										<div class="row mt-2 mx-0">
											<div class="col-6 col-md-5 col-xl-4 px-0">
												<label for="mime_type" class="h5 mb-1 mt-1 data-entry-label">MIME Type</label>
												<select name="mime_type" id="mime_type" class="data-entry-select reqdClr">
													<cfloop query="ctmime_type">
														<option <cfif #media.mime_type# is #ctmime_type.mime_type#> selected="selected"</cfif> value="#mime_type#">#mime_type#</option>
													</cfloop>
												</select>
											</div><!---end col-6 col-xl-5--->
											<div class="col-6 col-md-5 col-xl-4 pr-0 pl-3">
												<label for="media_type" class="h5 mb-1 mt-1 data-entry-label">Media Type</label>
												<select name="media_type" id="media_type" class="data-entry-select reqdClr">
												<cfloop query="ctmedia_type">
													<option <cfif #media.media_type# is #ctmedia_type.media_type#> selected="selected"</cfif> value="#media_type#">#media_type#</option>
												</cfloop>
												</select>
											</div><!---end col-6 col-xl-5--->
										</div><!---end form-row--->
										<div class="row mt-2">
											<div class="col-12 col-md-9 col-xl-6">
												<label for="media_license_id" class="h5 mb-1 mt-2 data-entry-label">License (<a href="/info/ctDocumentation.cfm?table=ctmedia_label&field=undefined" onclick="getCtDoc('ctmedia_label');" class="infoLink" target="_blank">Define</a>)</label>
												<select name="media_license_id" id="media_license_id" class=" reqdClr data-entry-select">
													<option value="">NONE</option>
													<cfloop query="ctmedia_license">
													<option <cfif media.media_license_id is ctmedia_license.media_license_id> selected="selected"</cfif> value="#ctmedia_license.media_license_id#">#ctmedia_license.media_license#</option>
													</cfloop>
												</select>
											</div>
										</div>
										<div class="form-row mt-2 mx-0">
											<div class="col-12 col-md-6 col-xl-2 col-md-3 px-0">
												<label for="mask_media_fg" class="h5 mb-1 mt-2 data-entry-label">Media Visibility</label>
												<select name="mask_media_fg" value="mask_media_fg" class="reqdClr data-entry-select">
													<cfif #media.mask_media_fg# eq 1 >
														<option value="0">Public</option>
														<option value="1" selected="selected">Hidden</option>
													<cfelse>
														<option value="0" selected="selected">Public</option>
														<option value="1">Hidden</option>
													</cfif>
												</select>
											</div>
										</div><!---end col-12 (img, caption, text, preview URI and Media URI)--->
										<cfif listcontainsnocase(session.roles,"manage_specimens")>
											<div class="form-row mt-2">
												<div class="col-12 px-0">
													<h3 class="h5 mt-2 mb-0 font-italic px-2" title="alternative text for vision impaired users">Alternative Text for Vision Impaired Users</h3>
													<p class="small90 mb-2 px-2">#media.alttag#</p>
												</div>
											</div>
										</cfif>
									</div>
									<div class="col-12 px-0 float-left">
										<div class="form-row mx-0 mt-2 mb-4">
											<div class="col-12 float-left">
											<!---  TODO: Change to ajax save of form. ---->
												<input type="submit" value="Save Core Media Data" onClick="editCoreMedia()" class="btn btn-xs btn-primary">
											</div>
										</div>
									</div>
								</div>
							</div>
						</form>
						<form id="relationshipForm">
							<div class="col-12 px-1 float-left">
								<div class="form-row my-1">
									<div class="col-12 col-sm-12 col-md-12 col-lg-6 col-xl-6 px-0  float-left">
										<h2>
											<label for="relationships" class="mb-1 mt-2 px-1 data-entry-label float-left"><span class="font-weight-bold h4">Media Relationships |</span> <a class="btn-link h5" type="button" onClick="incrementCountersUpdate('#id_for_counter#');">Add Row</a> &bull; <a class="btn-link h5" type="button" onclick="manyCatItemToMedia('#media_id#')">Add multiple "shows cataloged_item" records</a>
											</label>
										</h2>
										<div class="row">
											<div class="col-12">
												<cfset relationsBlockContent= getMediaRelationsHtml(media_id="#media.media_id#")>
													
												<div id="relationsBlock">
													#relationsBlockContent#
												</div>
												<div id="#id_for_dialog#"></div>
												<div class="col-9 px-0 pt-2 float-left">
											<!---		<button class="btn btn-xs btn-primary float-left mr-4" type="button" onClick="loadMediaRelations('relationsBlock','#media_id#');">Load Relationships 
													</button>--->
													<button class="btn btn-xs btn-primary float-left" type="button" onClick="saveMediaRelationship('relationsBlock','#media_id#');">Save Relationships 
													</button>
												</div>
											</div>
										</div>
									</div>
									<!---	end col-12 Start of Label Block--->
									<div class="col-12 col-sm-12 col-md-12 col-lg-6 col-xl-6 px-0 pl-lg-2 float-left">	
										<h2>
											<label for="labels" class="mb-1 mt-2 px-1 data-entry-label font-weight-bold" style="font-size: 1rem">Media Labels  | <span class="font-weight-normal text-dark small90"><a class="btn-link h5" type="button" >Add Row</a> &bull; Please add a "description."</span>
											</label>
										</h2>
										<div class="row">
											<div class="col-12">
												<cfset labelBlockContent= getLabelsHtml(media_id="#media.media_id#")>
												<div id="labelBlock">
													#labelBlockContent#
												</div>
											</div>
										</div>
									</div><!---end col-6--->	
								</div><!---end form-row Relationships and labels--->
							</div>
						</form>
					</div><!---end col-12--->
				</div>
			</div>
		</cfoutput>
	</cfcase>
	<!---------------------------------------------------------------------------------------------------->
	<cfcase value="new">
		<cfoutput>
			<div class="container-fluid container-xl">
				<form name="newMedia" method="post" action="Media.cfm">
					<input type="hidden" name="action" value="saveNew">
					<input type="hidden" id="media_type" name="media_type" value="">
					<input type="hidden" id="mime_type" name="mime_type" value="">
					<input type="hidden" id="media_license_id" name="media_license_id" value="">
					<input type="hidden" id="number_of_relations" name="number_of_relations" value="1">
					<input type="hidden" id="number_of_labels" name="number_of_labels" value="1">
					<input type="hidden" id="preview_uri" name="preview_uri" value="">
					<input type="hidden" id="mask_media_fg" name="mask_media_fg" value="">
					<input type="hidden" id="media_uri" name="media_uri" value="">
			
					<div class="row mx-0">
						<div class="col-12 px-0 mt-4 pb-2">
							<h1 class="h2 px-1 border-bottom border-dark mb-3 pb-2">
								Create Media 
								<i onClick="getMCZDocs('Media')" class="fas fa-circle-info" alt="[ help ]"></i>
							</h1>
							<script>
								function previewFile(input){
									var file = $("input[type=file]").get(0).files[0];
									if(file){
										var reader = new FileReader();
										reader.onload = function(){
											$("##previewImg").attr("src", reader.result);
										}
										reader.readAsDataURL(file);
									}
								}
								function previewPreviewFile(input){
									var file = $("input.preview[type=file]").get(0).files[0];
									if(file){
										var reader = new FileReader();
										reader.onload = function(){
											$("##previewPreviewImg").attr("src", reader.result);
										}
										reader.readAsDataURL(file);
									}
								}
							</script>
							<div class="rounded border bg-light col-12 col-sm-4 col-md-3 col-xl-2 float-left mb-3 pt-3 pb-3">
								<img id="previewImg" src="/shared/images/placeholderGeneric.png" alt="Preview of Img File" style="width:100%">
								<p class="small mb-0">Preview of Media</p>
								
								<img id="previewPreviewImg" src="/shared/images/placeholderGeneric.png" alt="Preview of Img File" width="100" style="width:auto" class="mt-3">
								<p class="small mb-0">Preview of Thumbnail</p>
							</div>
							
								<div class="form-row mx-0 mt-0 mb-4">
									<div class="col-12 col-md-10 px-0 px-sm-2 px-md-4 float-left">
										<label for="media_uri" class="data-entry-label">Media IRI</label>
										<input name="media_uri" class="reqdClr data-entry-input" required>
									</div>
									<div class="col-12 col-md-4 px-0 px-sm-2 px-md-4">
										<button type="button" onClick="getIRIForFile();" >Find on Shared Storage</button>
									</div>
								</div>
								<div class="form-row mx-0 mt-0 mb-4">
									<div class="col-12 col-xl-10 px-0 px-sm-2 px-md-4 float-left">
										<label for="preview_uri" class="data-entry-label">Preview IRI</label>
										<input name="preview_uri" class="reqdClr data-entry-input" required>
									</div>
								</div>
								<div class="form-row col-12 px-0 mx-0 mt-2">
									<div class="col-12 col-md-6 col-xl-4 px-0 px-sm-2 px-md-4 float-left">
										<label for="mime_type" class="data-entry-label">MIME Type</label>
										<select name="mime_type" id="mime_type" class="reqdClr data-entry-select">
											<option value=""></option>
											<cfloop query="ctmime_type">
												<option value="#mime_type#">#mime_type#</option>
											</cfloop>
										</select>
									</div>
									<div class="col-12 col-md-6 col-xl-4 px-0 px-sm-2 px-md-4 float-left">
										<label for="media_type" class="data-entry-label">Media Type</label>
										<select name="media_type" id="media_type" class="reqdClr data-entry-select">
											<option value=""></option>
											<cfloop query="ctmedia_type">
											<option value="#media_type#">#media_type#</option>
											</cfloop>
										</select>
									</div>
								</div>
								<div class="form-row mx-0 mt-2">
									<div class="col-12 col-sm-8 col-md-6 px-0 px-sm-2 px-md-4 float-left">
										<label for="media_license_id" class="data-entry-label">
											License  <a class="infoLink btnlink" onClick="popupDefine()">Define Licenses</a>
										</label>
										<select name="media_license_id" id="media_license_id" class="data-entry-select">
											<option value="">Research copyright &amp; then choose...</option>
											<cfloop query="ctmedia_license">
												<option value="#media_license_id#">#media_license#</option>
											</cfloop>
										</select>
									</div>
								</div>
								<div class="form-row mx-0 mt-2">
									<div class="col-12 col-md-4 px-0 px-sm-2 px-md-4 float-left">
										<label for="mask_media_fg" class="data-entry-label">Media Record Visibility</label>
										<select name="mask_media_fg" value="mask_media_fg" class="data-entry-select">
											<option value="0" selected="selected">Public</option>
											<option value="1">Hidden</option>
										</select>
									</div>
								</div>
								<div class="form-row mx-0 mt-2">
									<!---NOTES to USER--->
									<div class="col-12 px-0 px-sm-2 px-md-4">
										<ul class="list-group float-left border-success border-right border-left mt-2 border-bottom border-top rounded p-2">
											<li class="mx-4" style="list-style:circle">Media should not be uploaded until copyright is assessed and, if relevant, permission is granted (<a href="https://code.mcz.harvard.edu/wiki/index.php/Non-MCZ_Digital_Media_Licenses/Assignment" target="_blank">more info</a>)</li>
											<li class="mx-4" style="list-style:circle">Remove media immediately if owner requests it</li>
											<li class="mx-4" style="list-style:circle">Contact <a href="mailto:mcz_collections_operations@oeb.harvard.edu?subject=media licensing">MCZ Collections Operations</a> if additional licensing situations arise</li>
										</ul>
									</div>
								</div>
							</div>
						</div>
					</div>
					<div class="row mx-0">
						<div class="col-12 pb-5 px-0">
							<div class="form-row mt-2 mx-0">
								<div class="col-12 col-xl-10 px-0">
									<div class="col-12 px-0 float-left">
										<label for="relationships" class="mb-1 mt-2 px-1 data-entry-label font-weight-bold" style="font-size: 1rem;">Media Relationships | <span class="text-dark small90 font-weight-normal">Multiple relationships to other records are possible.<!---Catalog Number picklist went here. Should it be type ahead now?---></span></label>
										<div id="relationshipDiv">
											<cfset i=1>
											<cfloop>
												<div id="relationshiperror"></div>
												<select name="relationship__1" id="relationship__1" size="1" onchange="pickedRelationship(this.id)" class="data-entry-select col-12 col-md-6 float-left">
													<option value="">None/Unpick</option>
													<cfloop query="ctmedia_relationship">
														<option value="#media_relationship#">#media_relationship#</option>
													</cfloop>
												</select>
												<input type="text" name="related_value__1" id="related_value__1" class="col-12 col-md-6 data-entry-input float-left">
												<input type="hidden" name="related_id__1" id="related_id__1">
											</cfloop>
											<div class="col-12 float-left">						
												<span class="infoLink h5 box-shadow-0 col-12 col-md-3 float-right d-block text-right my-1" id="addRelationship" onclick="addRelation(#i#, 'relationshipDiv','addRelationship');">Add Relationship (+)</span>
											</div>
										</div>
									</div>
									<div class="col-12 px-0 float-left">
										<label for="labels" class="mb-1 mt-2 px-1 data-entry-label font-weight-bold" style="font-size: 1rem">Media Labels  | <span class="font-weight-normal text-dark small90">Note: For media of permits, and other transaction related documents, please enter a 'description' media label.</span>
										</label>
										<div id="labels">
											<div class="form-row mx-0 px-0 col-12">
												<select class="data-entry-select col-12 col-md-6 px-0 float-left">
													<option>description</option>
												</select>
												<input class="data-entry-input col-12 col-md-6 float-left reqdClr" type="text" name="label_value__0" id="label_value__0" value="" required>
											</div>
											<cfset i=1>
											<cfloop>
												<div id="labelsDiv__#i#" class="form-row mx-0 px-0 col-12">
													<select name="label__#i#" id="label__#i#" size="1" class="data-entry-select col-12 col-md-6 float-left">
														<option value="delete">Select label...</option>
														<cfloop query="ctmedia_label">
															<option value="#media_label#">#media_label#</option>
														</cfloop>
													</select>
													<input class="data-entry-input col-12 col-md-6 float-left" type="text" name="label_value__#i#" id="label_value__#i#" value="">
												</div>
												<cfset i=i+1>
											</cfloop>
											<div class="col-12 float-left">
												<span class="infoLink h5 box-shadow-0 col-12 col-md-3 float-right d-block text-right my-1 pr-2" id="addLabel" onclick="addLabelTo(#i#,'labels','addLabel');">Add Label (+)</span> 
											</div>
										</div>
									</div>
								</div>
							</div>
							<div class="form-row mx-0 mt-2">
								<div class="col-12 px-0 float-left">
									<input type="submit" value="Create Media" onclick="createMedia()" class="btn btn-xs btn-primary">
								</div>
							</div>
						</div>
					</div>
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
					<cfquery name="s" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select media_relationship from ctmedia_relationship where media_relationship= 
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#relationship#">
					</cfquery>
					<cfif s.recordCount eq 1 >
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
		</cfoutput>
	</cfcase>
	<!---------------------------------------------------------------------------------------------------->

</cfswitch>

<cfinclude template="/shared/_footer.cfm">
