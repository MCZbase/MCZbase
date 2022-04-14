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
	<cfquery name="getRelations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select * from media_relations where media_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
	</cfquery>
		<cfquery name="media" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select MEDIA_ID, MEDIA_URI, MIME_TYPE, MEDIA_TYPE, PREVIEW_URI, MEDIA_LICENSE_ID, MASK_MEDIA_FG, auto_host,
				mczbase.get_media_descriptor(media_id) as alttag, MCZBASE.get_media_title(media.media_id) as caption 
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
		<cfset relns=getMediaRelations(#media_id#)>
		<cfoutput>
			<div class="container-fluid container-xl">
				<div class="row">
					<div class="col-12 mt-3 pb-5">
						<h1 class="h2 px-1 border-bottom border-dark pb-2">Edit Media 
							<i class="fas fa-info-circle" onClick="getMCZDocs('Edit/Delete_Media')" aria-label="help link"></i>
						</h1>
						<div class="px-1">
							<h4 class="pr-3 d-inline-block">Media ID = #media_id#</h4>
							<a href="/MediaSearch.cfm?action=search&media_id=#media_id#" class="btn btn-xs btn-info">Media Record</a>
						</div>
						<form name="editMedia" method="post" action="media.cfm" class="my-2">
							<input type="hidden" name="action" value="saveEdit">
							<input type="hidden" id="number_of_relations" name="number_of_relations" value="#relns.recordcount#">
							<input type="hidden" id="number_of_labels" name="number_of_labels" value="#labels.recordcount#">
							<input type="hidden" id="media_id" name="media_id" value="#media.media_id#">
							<div class="col-12 px-0 float-left">
								<div class="rounded border bg-light col-12 col-sm-6 col-md-3 col-xl-2 float-left mb-3 pt-3 pb-2">
									<cfset mediaBlock= getMediaBlockHtml(media_id="#media.media_id#",displayAs="full",size="300",captionAs="textFull")>
									<div id="mediaBlock#media.media_id#" class="mx-auto text-center pt-1">
										#mediaBlock#
									</div><!---end image block--->
								</div><!---end col-md-1 col-5 (image block)--->
								<div class="col-12 col-md-9 col-xl-10 pb-4 pb-xl-2 px-0 px-md-2 float-left">
									<div class="col-12 col-xl-9 px-0 px-xl-2 float-left">
										<div class="form-row mx-0 mt-2">	
											<label for="media_uri" class="h5 mb-1 mt-0 data-entry-label">Media URI (<a href="#media.media_uri#" class="infoLink" target="_blank">open</a>)</label>
											<input type="text" name="media_uri" id="media_uri" size="90" value="#media.media_uri#" class="data-entry-input small reqdClr">
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
												<input type="submit" value="Save Core Media Data"	class="btn btn-xs btn-primary">
											</div>
										</div>
									</div>
								</div>
							</div>
						</form>
						<form>
							<div class="col-12 col-md-12 px-0 float-left">
									<div class="form-row my-1">
										<div class="col-12 col-sm-12 col-md-12 col-lg-6 col-xl-6 px-0 pr-lg-2 float-left">
											<h2>
												<label for="relationships" class="mb-1 mt-2 px-1 data-entry-label font-weight-bold" style="font-size: 1rem;">Media Relationships | <span class="text-dark small90 font-weight-normal"  onclick="manyCatItemToMedia('#media_id#')">Add multiple "shows cataloged_item" records. Click the buttons to rows and delete row(s).</span></label>
											</h2>
											<cfset mediaBlockContent= getMediaRelHtml(parameter="#media_id#",other_parameter="static value")>
											<div id="mediahtmlBlock">
												#mediaBlockContent#
											</div>

										</div><!---end col-12--->

									<!---Start of Label Block--->
										<div class="col-12 col-sm-12 col-md-12 col-lg-6 col-xl-6 px-0 pl-lg-2 float-left">	
											<h2>
												<label for="labels" class="mb-1 mt-2 px-1 data-entry-label font-weight-bold" style="font-size: 1rem">Media Labels  | <span class="font-weight-normal text-dark small90">Note: For media of permits, and other transaction related documents, please enter a 'description' media label.</span>
												</label>
											</h2>
											<div id="labels">
												<cfset i=1>
												<cfif labels.recordcount is 0>
													<!--- seed --->
													<div id="seedLabel" style="display:none;">
														<input type="hidden" id="media_label_id__0" name="media_label_id__0">
														<cfset d="">
														<label for="label__#i#" class='sr-only'>Media Label</label>
														<select name="label__0" id="label__0" size="1" class="data-entry-select float-left col-5">
															<cfloop query="ctmedia_label">
																<option <cfif #d# is #media_label#> selected="selected" </cfif>value="#media_label#">#media_label#</option>
															</cfloop>
														</select>
														<input type="text" name="label_value__0" id="label_value__0" class="col-7 float-left data-entry-input">
													</div>
													<!--- end labels seed --->
												</cfif>
												<cfloop query="labels">
													<cfset d=media_label>
													<div class="form-row col-12 px-0 mx-0" id="labelDiv__#i#" >		
														<input type="hidden" id="media_label_id__#i#" name="media_label_id__#i#" value="#media_label_id#">
														<label class="pt-0 pb-1 sr-only" for="label__#i#">Media Label</label>
														<select name="label__#i#" id="label__#i#" size="1" class="inputDisabled data-entry-select col-3 float-left">
															<cfloop query="ctmedia_label">
																<option <cfif #d# is #media_label#> selected="selected" </cfif>value="#media_label#">#media_label#</option>
															</cfloop>
														</select>
														<input type="text" name="label_value__#i#" id="label_value__#i#" value="#encodeForHTML(label_value)#"  class="data-entry-input inputDisabled col-7 float-left">
														<button class="btn btn-danger btn-xs float-left small"> Delete </button>
														<input class="btn btn-secondary btn-xs mx-2 small float-left edit-toggle__#i#" onclick="edit_revert()" type="button" value="Edit" style="width:50px;"></input>
													</div>
													<script type="text/javascript">
														$(document).ready(function edit_revert() {
																$("##label__#i#").prop("disabled", true);
																$("##label_value__#i#").prop("disabled", true);
																$(".edit-toggle__#i#").click(function() {
																	if (this.value=="Edit") {
																		this.value = "Revert";
																		$("##label__#i#").prop("disabled", false);
																		$("##label_value__#i#").prop("disabled", false);
																	}
																	else {
																		this.value = "Edit";
																		$("##label__#i#").prop("disabled", true);
																		$("##label_value__#i#").prop("disabled", true);
																	}
																});
															});
													</script>
													<cfset i=i+1>
												</cfloop>
												<span class="infoLink h5 box-shadow-0 col-3 float-right d-block text-right my-1 pr-4" id="addLabel" onclick="addLabelTo(#i#,'labels','addLabel');">Add Label (+)</span> 
											</div><!---end id labels--->
											<div class="col-12 px-0 float-left">
												<input class="btn btn-xs btn-primary float-left" type="button" value="Save Label Changes">
											</div>
										</div><!---end col-6--->	
									</div><!---end form-row Relationships and labels--->

									<!---  TODO: Make for main form only, set relations/labels as separate ajax calls ---->
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
					</div><!---end col-12--->
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
								<div id="labelsDiv__#i#" class="form-row mx-0 px-0 col-12">
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
