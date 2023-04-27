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

<cfinclude template="/media/component/functions.cfc" runOnce="true"><!--- for autocompletes --->
<cfinclude template="/media/component/public.cfc" runOnce="true"><!--- for media widget --->

<!---<cfif NOT isdefined("action")>
	<cfset action = "edit">
</cfif>--->
<cfset pageTitle = "Shared Drive Media">
<!---<cfswitch expression="#action#">
	<cfcase value="">
		<cfset pageTitle = "New Shared Drive Media">
	</cfcase>
	<cfcase value="edit">
		<cfset pageTitle = "Edit Media Record">
		<cfif NOT isDefined("media_id") OR len(media_id) EQ 0>
			<cflocation url="/media/SharedDrive.cfm?action=edit" addtoken="false">
		</cfif>
	</cfcase>
</cfswitch>--->

<cfinclude template = "/shared/_header.cfm">
<cfquery name="ctcollection" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
	select COLLECTION_CDE, COLLECTION from collection order by collection
</cfquery>
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
<!--- Note, jqxcombobox doesn't properly handle options that vary only in trailing whitespace, so using trim() here --->
<cfquery name="distinctExtensions" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" timeout="#Application.short_timeout#">
	select trim(auto_extension) as extension, count(*) as ct
	from media
	where auto_extension is not null
	group by trim(auto_extension)
	order by upper(trim(auto_extension))
</cfquery>
	<cfif not isdefined("mask_media_fg")> 
		<cfset mask_media_fg="">
	</cfif>
	<cfif not isdefined("media_uri")> 
		<cfset media_uri="">
	</cfif>
	<cfif not isdefined("preview_uri")> 
		<cfset preview_uri="">
	</cfif>
	<cfif not isdefined("mime_type")> 
		<cfset mime_type="">
	</cfif>
	<cfset in_mime_type=mime_type>
	<cfif not isdefined("media_type")> 
		<cfset media_type="">
	</cfif>
	<cfset in_media_type=media_type>
	<cfif not isdefined("media_id")> 
		<cfset media_id="">
	</cfif>
	<cfif not isdefined("keywords")> 
		<cfset keywords="">
	</cfif>
	<cfif not isdefined("description")> 
		<cfset description="">
	</cfif>
	<cfif not isdefined("protocol")> 
		<cfset protocol="">
	</cfif>
	<cfif not isdefined("hostname")> 
		<cfset hostname="">
	</cfif>
	<cfif not isdefined("path")> 
		<cfset path="">
	</cfif>
	<cfif not isdefined("filename")> 
		<cfset filename="">
	</cfif>
	<cfif not isdefined("extension")> 
		<cfset extension="">
	</cfif>
	<cfset in_extension=extension>
	<cfif not isdefined("created_by_agent_name")>
		<cfset created_by_agent_name="">
	</cfif>
	<cfif not isdefined("created_by_agent_id")>
		<cfset created_by_agent_id="">
	</cfif>
	<cfif not isdefined("text_made_date")>
		<cfset text_made_date="">
	</cfif>
	<cfif not isdefined("to_made_date")>
		<cfset to_made_date="">
	</cfif>
	<cfif not isdefined("dcterms_identifier")>
		<cfset dcterms_identifier="">
	</cfif>
	<cfif not isdefined("related_cataloged_item")>
		<cfset related_cataloged_item="">
	</cfif>
	<cfif not isdefined("collection_object_id")>
		<cfset collection_object_id="">
	</cfif>
	<cfif not isdefined("unlinked")>
		<cfset unlinked="">
	</cfif>
	<cfif not isdefined("multilink")>
		<cfset multilink="">
	</cfif>
	<cfif not isdefined("multitypelink")>
		<cfset multitypelink="">
	</cfif>
	<cfif not isdefined("collection")>
		<cfset collection="">
	</cfif>
	<cfif not isdefined("folder")>
		<cfset folder="">
	</cfif>
	<cfif not isdefined("media_label_type")>
		<cfset media_label_type="">
	</cfif>
	<cfif not isdefined("media_label_value")>
		<cfset media_label_value="">
	</cfif>
	<cfif not isdefined("media_relationship_type")>
		<cfset media_relationship_type="">
	</cfif>
	<cfif not isdefined("media_relationship_value")>
		<cfset media_relationship_value="">
	</cfif>
	<cfif not isdefined("media_relationship_id")>
		<cfset media_relationship_id="">
	</cfif>
	<cfif not isdefined("media_relationship_type_1")>
		<cfset media_relationship_type_1="">
	</cfif>
	<cfif not isdefined("media_relationship_value_1")>
		<cfset media_relationship_value_1="">
	</cfif>
	<cfif not isdefined("media_relationship_id_1")>
		<cfset media_relationship_id_1="">
	</cfif>
<!---------------------------------------------------------------------------------------------------->

	<cfoutput>
		<section class="jumbotron pb-3 bg-white text-center">
			<div class="container">
				<h1 class="jumbotron-heading">Shared Drive</h1>
				<p class="lead text-muted">
					Save the largest size of the media available to the shared drive. A thumbnail will be created for you. 
					<br>The Shared Drive is MCZ media storage managed by Collections Operations and Research Computing (RC). Account questions can go into a RC ticket with a cc to Brendan Haley. 
				</p>
			</div>
		</section>
		<div class="album pb-5 bg-light">
			<form name="startMedia" id="newMedia" action="/media/SharedDrive.cfm" onsubmit="return noenter();" method="post" required>
				<div class="container">
					<div class="row">
						<div class="col-12 py-5">
							<div class="col-12 col-md-2 float-left">
								<div class="form-group mb-2">
									<label for="keywords" class="data-entry-label mb-0" id="keywords_label">Protocol<span></span></label>
									<select id="protocol" name="protocol" class="data-entry-select">
										<option></option>
										<cfif protocol EQ "http"><cfset sel = "selected='true'"><cfelse><cfset sel = ""></cfif>
										<option value="http" #sel#>http://</option>
										<cfif protocol EQ "https"><cfset sel = "selected='true'"><cfelse><cfset sel = ""></cfif>
										<option value="https" #sel#>https://</option>
										<cfif protocol EQ "httphttps"><cfset sel = "selected='true'"><cfelse><cfset sel = ""></cfif>
										<option value="httphttps" #sel#>http or https</option>
										<cfif protocol EQ "NULL"><cfset sel = "selected='true'"><cfelse><cfset sel = ""></cfif>
										<option value="NULL" #sel#>NULL</option>
									</select>
								</div>
							</div>
							<div class="col-12 col-md-2 float-left">
								<div class="form-group mb-2">
									<label for="hostname" class="data-entry-label mb-0" id="hostname_label">Host<span></span></label>
									<input type="text" id="hostname" name="hostname" class="data-entry-input" value="#encodeForHtml(hostname)#" aria-labelledby="hostname_label" >
								</div>
								<script>
									$(document).ready(function() {
										makeMediaURIPartAutocomplete("hostname","hostname");
									});
								</script>
							</div>
							<div class="col-12 col-md-3 float-left">
								<div class="form-group mb-2">
									<label for="path" class="data-entry-label mb-0" id="path_label">Path<span></span></label>
									<input type="text" id="path" name="path" class="data-entry-input" value="#encodeForHtml(path)#" aria-labelledby="path_label" >
								</div>
								<script>
									$(document).ready(function() {
										makeMediaURIPartAutocomplete("path","path");
									});
								</script>
							</div>
							<div class="col-12 col-md-3 float-left">
								<div class="form-group mb-2">
									<label for="filename" class="data-entry-label mb-0" id="filename_label">Filename <span></span></label>
									<input type="text" id="filename" name="filename" class="data-entry-input" value="#encodeForHtml(filename)#" aria-labelledby="filename_label">
								</div>
								<script>
									$(document).ready(function() {
										makeMediaURIPartAutocomplete("filename","filename");
									});
								</script>
							</div>
							<div class="col-12 col-md-2 col-xl-1 float-left">
								<div class="form-group mb-2">
									<label for="extension" class="data-entry-label mb-0" id="extension_label">Extension<span></span></label>
									<cfset selectedextensionlist = "">
									<select id="extension" name="extension" class="data-entry-select" multiple="true">
										<option></option>
										<cfloop query="distinctExtensions">
											<cfif listFind(in_extension, distinctExtensions.extension) GT 0>
												<cfset selected="selected='true'">
												<cfset selectedextensionlist = listAppend(selectedextensionlist,'#distinctExtensions.extension#') >
											<cfelse>
												<cfset selected="">
											</cfif>
											<option value="#distinctExtensions.extension#" #selected#>#distinctExtensions.extension# (#distinctExtensions.ct#)</option>
										</cfloop>
										<option value="Select All">Select All</option>
										<option value="NULL">NULL</option>
										<option value="NOT NULL">NOT NULL</option>
									</select>
									<script>
										$(document).ready(function () {
											$("##extension").jqxComboBox({  multiSelect: false, width: '100%', enableBrowserBoundsDetection: true });  
											<cfloop list="#selectedextensionlist#" index="ext">
												$("##extension").jqxComboBox('selectItem', '#ext#');
											</cfloop>
											$("##extension").jqxComboBox().on('select', function (event) {
												var args = event.args;
												if (args) {
													var item = args.item;
													if (item.label == 'Select All') { 
														for (i=0;i<args.index;i++) { 
															$("##extension").jqxComboBox('selectIndex', i);
														}
														$("##extension").jqxComboBox('unselectIndex', args.index);
													}
												}
											});
										});
									</script>
								</div>
							</div>
						</div>
						<input class="btn btn-xs btn-primary" type="submit" value="Submit" onClick="displayImage(protocol, hostname, path, filename)">
					</div>
				</div>
			</form>
			<div class="row">
				<div class="col-12">
					<div class="col-4">
						<script>
							function readURL(input) {
								if (input.text && input.text[0]) {
									var reader = new FileReader();

									reader.onload = function (e) {
										imgId = '#preview-'+$(input).attr('id');
										$(imgId).attr('src', e.target.result);
									}

									reader.readAsDataURL(input.text[0]);
								}
							  }


							  $("form#startMedia input[type='text']").change(function(){
								readURL(this);
							  });
						</script>
					</div>
				</div>
			</div>
		</div>
	</cfoutput>


<cfinclude template="/shared/_footer.cfm">
