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
<cfinclude template="/media/component/search.cfc" runOnce="true"><!--- for autocompletes --->
<cfinclude template="/media/component/public.cfc" runOnce="true"><!--- for media widget --->

<cfif NOT isdefined("action")>
	<cfset action = "edit">
</cfif>
<cfset pageTitle = "Manage Media">
<cfswitch expression="#action#">
	<cfcase value="new">
		<cfset pageTitle = "Create Media Record">
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
			select media_relationship, related_primary_key, media_relations_id, media_id
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
			<div class="container-fluid container-xl pb-5">
				<div class="row mx-0">
						<div class="col-12 px-2 border-bottom border-dark my-3">
							<h1 class="h2 px-0 py-2 my-2">Edit Media 
								<i class="fas fa-info-circle" onClick="getMCZDocs('Edit/Delete_Media')" aria-label="help link"></i>
								<a href="/MediaSearch.cfm?action=search&media_id=#media_id#" class="btn btn-xs btn-info float-right">Media Record</a>
							</h1>
						</div>
						<div class="col-12 px-0 my-0">
						<div class="px-1">
							<h4 class="pr-3 d-inline-block">Media ID = media/#media_id#</h4>
						</div>
						<form name="editMedia" method="post" action="Media.cfm" class="my-2">
							<input type="hidden" name="action" value="saveEditMedia">
							<input type="hidden" id="number_of_relations" name="number_of_relations" value="#getRelations.recordcount#">
							<input type="hidden" id="media_relationship" name="media_relationship" value="#getRelations.media_relationship#">
							<input type="hidden" id="related_primary_key" name="related_primary_key" value="#getRelations.related_primary_key#">
							<input type="hidden" id="media_relations_id" name="media_relations_id" value="#getRelations.media_relations_id#">
							<input type="hidden" id="media_id" name="media_id" value="#getRelations.media_id#">
							<div class="col-12 px-1 float-left">
								<div class="rounded border bg-light col-12 col-sm-6 col-md-3 col-xl-2 float-left mb-3 pt-3 pb-2">
									<cfset mediablock= getMediaBlockHtml(media_id="#media_id#",size="300",captionAs="textLinks")>
									<div class="mx-auto text-center h3 pt-1" id="mediaBlock#media.media_id#"> #mediablock# </div>
								</div>
								<div class="col-12 col-md-9 col-xl-10 pb-4 pb-xl-2 px-0 px-md-2 float-left">
									<div class="col-12 col-xl-9 px-0 px-xl-2 float-left">
										<div class="form-row mx-0 mt-2">	
											<label for="media_uri" class="h5 mb-1 mt-0 data-entry-label">Media URI (<a href="#media.media_uri#" class="infoLink" target="_blank">open</a>)</label>
											<input type="text" name="media_uri" id="media_uri" size="90" value="#media.media_uri#" class="data-entry-input small reqdClr">
											<cfif media.auto_host EQ "mczbase.mcz.harvard.edu">
												<!--- prepare some rewrites to iiif lookup for use later --->
												<cfset iiifSchemeServerPrefix = "#Application.protocol#://iiif.mcz.harvard.edu/iiif/3/">
												<cfset iiifIdentifier = "#encodeForURL(replace(media.auto_path,'/specimen_images/',''))##encodeForURL(media.auto_filename)#">
												<!--- check to see if the file exists on the filesystem with the expected name and location --->
												<cfset filefull = "#Application.webDirectory#/#media.auto_path##media.auto_filename#">
												<cfset directory = "#Application.webDirectory#/#media.auto_path#">
												<cfif fileExists("#filefull#")>
													<output id="fileStatusOutput">[File Exists]</output>
												<cfelse>
													<output id="fileStatusOutput">
													[File Not Found]
													<cfif NOT directoryExists("#directory#")>[Directory Not Found]</cfif>
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
			
							<div class="col-12 px-1 float-left">
								<div class="form-row my-1">
									<div class="col-12 col-sm-12 col-md-12 col-lg-6 col-xl-6 px-0  float-left">
										<h2>
											<label for="relationships" class="mb-1 mt-2 px-1 data-entry-label float-left"><span class="font-weight-bold h4">Media Relationships |</span> <a class="btn-link h5" type="button" onClick="addMediaRelationshipToForm('#media.media_id#')">Add Row</a> &bull; <a class="btn-link h5" type="button" onclick="manyCatItemToMedia('#media.media_id#')">Add multiple "shows cataloged_item" records</a>
											</label>
										</h2>
										<div class="row">
											<div class="col-12">
											<form id="relationshipForm">
												<input type="hidden" name="action" value="saveMediaRelationship">
												<input type="hidden" id="number_of_relations" name="number_of_relations" value="#getRelations.recordcount#">
												<input type="hidden" id="media_relationship" name="media_relationship" value="#getRelations.media_relationship#">
												<input type="hidden" id="related_primary_key" name="related_primary_key" value="#getRelations.related_primary_key#">
												<input type="hidden" id="media_relations_id" name="media_relations_id" value="#getRelations.media_relations_id#">
												<input type="hidden" id="media_id" name="media_id" value="#getRelations.media_id#">
												<cfset relationsBlockContent= getMediaRelationsHtml(media_id='#media.media_id#')>
												<div id="relationsBlock">
													#relationsBlockContent#
												</div>
												<div class="col-9 px-0 pt-2 float-left">
													<button class="btn btn-xs btn-primary float-left mr-4" type="button" onClick="loadMediaRelations('relationsBlock','#media_id#');">Load Relationships 
													</button>
													<button class="btn btn-xs btn-primary float-left" type="button" onClick="saveMediaRelationship('relationshipForm','#media_id#');">Save Relationships 
													</button>
												</div>
											</form>
											</div>
										</div>
									</div>
									<!---	end col-12 Start of Label Block--->
									<div class="col-12 col-sm-12 col-md-12 col-lg-6 col-xl-6 px-0 pl-lg-2 float-left">	
										<h2>
											<label for="labels" class="mb-1 mt-2 px-1 data-entry-label font-weight-bold" style="font-size: 1rem">Media Labels  | <span class="font-weight-normal text-dark small90"><a class="btn-link h5" type="button" >Add Row</a> &bull; Please add a "description."</span>
											</label>
										</h2>
										<form id="labelForm">
											<div class="col-12">
												<cfset labelBlockContent= getLabelsHtml(media_id="#media.media_id#")>
												<div id="labelBlock">
													#labelBlockContent#
												</div>
											</div>
										</form>
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
		<section class="jumbotron pb-3 bg-white text-center">
			<div class="container">
				<h1 class="jumbotron-heading">Create Media Records</h1>
				<p class="lead text-muted">
					Select the stored type of the media you want to add to MCZbase. Each storage type has a different pathway to create a media record.
				</p>
			</div>
		</section>
		<div class="album pb-5 bg-light">
			<div class="container">
				<div class="row">
					<div class="col-md-4 px-5 pb-5">
						<h2 class="text-center pt-3">Shared Drive</h2>
						<div class="card mb-4 box-shadow bg-lt-gray border-lt-gray ">
							<img class="card-img-top mx-auto" data-src="https://iiif.mcz.harvard.edu/iiif/3/1400828/full/max/0/default.jpg" alt="placeholder thumbnail" style="width: 93.5%; display: block;" src="https://iiif.mcz.harvard.edu/iiif/3/1400828/full/max/0/default.jpg" data-holder-rendered="true">
							<div class="card-body bg-white p-4">
								<p class="card-text">The shared drive is where MCZ files are stored. It located in a facility managed by Harvard. Map to the drive or use Filezilla to transfer files to the shared drive.</p>
								<div class="d-flex justify-content-between align-items-center">
									<div class="btn-group">
										<button type="button" class="btn btn-xs btn-primary px-5"  onclick="location.href='/media/SharedDrive.cfm'">Start</button>
									</div>
								</div>
							</div>
						</div>
					</div>
					<div class="col-md-4 px-5 pb-5">
						<h2 class="text-center pt-3">External Link</h2>
						<div class="card mb-4 box-shadow bg-lt-gray border-lt-gray">
							<img class="card-img-top" data-src="https://mczbase.mcz.harvard.edu/specimen_images/specialcollections/large/mcz_newsletter_BHL.jpg" alt="external file placeholder image" style="width: 100%; display: block;" src="https://mczbase.mcz.harvard.edu/specimen_images/specialcollections/large/mcz_newsletter_BHL.jpg" data-holder-rendered="true">
							<div class="card-body bg-white p-4">
								<p class="card-text">External files could be stored anywhere outside of Harvard's facilities. Example:  Biodiversity Heritage Library. Permission must be on file before uploading.</p>
								<div class="d-flex justify-content-between align-items-center">
									<div class="btn-group">
										<button type="button" class="btn btn-xs btn-primary px-5">Start</button>
									</div>
								</div>
							</div>
						</div>
					</div>
					<div class="col-md-4 px-5 pb-5">
						<h2 class="text-center pt-3">Submit to DSpace</h2>
						<div class="card mb-4 box-shadow bg-lt-gray border-lt-gray">
							<img class="card-img-top" data-src="https://iiif.mcz.harvard.edu/iiif/3/3823370/full/max/0/default.jpg" alt="DSpace logo" style="width: 100%; display: block;" src="https://iiif.mcz.harvard.edu/iiif/3/3823370/full/max/0/default.jpg" data-holder-rendered="true">
							<div class="card-body bg-white p-4">
								<p class="card-text">DSpace is for larger files such as tif and/or for batch loading files. Metadata is submitted with the file and is kept in the media record and on DSpace.</p>
								<div class="d-flex justify-content-between align-items-center">
									<div class="btn-group">
										<button type="button" class="btn btn-xs btn-primary px-5">Start</button>
									</div>
								</div>
							</div>
						</div>
					</div>
				</div>
			</div>
		</div>
			

		</cfoutput>
	</cfcase>
							
	<!---------------------------------------------------------------------------------------------------->

</cfswitch>

<cfinclude template="/shared/_footer.cfm">
