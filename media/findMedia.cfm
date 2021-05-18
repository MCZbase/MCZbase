<!---
/media/findMedia.cfm

Media search/results 

Copyright 2021 President and Fellows of Harvard College

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
<cfset pageTitle = "Search Media">
<cfinclude template = "/shared/_header.cfm">

<cfquery name="ctmedia_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select media_type  from ctmedia_type
</cfquery>
<cfquery name="ctmime_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select mime_type  from ctmime_type
</cfquery>
<cfquery name="ctmedia_label" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select media_label, description  from ctmedia_label
</cfquery>

<div id="overlaycontainer" style="position: relative;"> 
	<!--- ensure fields have empty values present if not defined. --->
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
	<cfif not isdefined("filename")> 
		<cfset filename="">
	</cfif>
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
	<cfloop query="ctmedia_label">
		<cfif ctmedia_label.media_label NEQ 'description' and ctmedia_label.media_label NEQ 'dcterms:identifier'>
			<cfset label = replace(ctmedia_label.media_label," ","_","all")>
			<cfif not isdefined(label)>
				<cfset "#label#" = "">
			</cfif>
		</cfif>
	</cfloop>
	<!--- Search Form ---> 
	<cfoutput>
		<main id="content">
			<section class="container-fluid mt-2 mb-3" role="search" aria-labelledby="formheader">
				<div class="row mx-0 mb-3">
					<div class="search-box">
						<div class="search-box-header">
							<h1 class="h3 text-white" id="formheading">Find Media Records</h1>
						</div>
						<!--- setup date pickers --->
						<script>
							$(document).ready(function() {
								<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
									$("##birth_date").datepicker({ dateFormat: 'yy-mm-dd'});
									$("##to_birth_date").datepicker({ dateFormat: 'yy-mm-dd'});
									$("##death_date").datepicker({ dateFormat: 'yy-mm-dd'});
									$("##to_death_date").datepicker({ dateFormat: 'yy-mm-dd'});
								</cfif>
								$("##collected_date").datepicker({ dateFormat: 'yy-mm-dd'});
								$("##to_collected_date").datepicker({ dateFormat: 'yy-mm-dd'});
							});
						</script>

						<div class="col-12 pt-3 pb-2">
							<form name="searchForm" id="searchForm">
								<input type="hidden" name="method" value="getMedia">
								<div class="form-row">
									<!--- TODO: controls in this row aren't stable enough yet to make responsive, when stable, typically col-md-4 col-xl-2 ratio --->
									<div class="col-12 col-md-5">
										<div class="form-group mb-2">
											<label for="media_uri" class="data-entry-label mb-0" id="media_uri_label">Media URI</label>
											<input type="text" id="media_uri" name="media_uri" class="data-entry-input" value="#media_uri#" aria-labelledby="media_uri_label" >
										</div>
									</div>
									<div class="col-12 col-md-1">
										<div class="form-group mb-2">
											<label for="media_id" class="data-entry-label mb-0" id="mediaid_label">Media ID</label>
											<input type="text" id="media_id" name="media_id" value="#media_id#" class="data-entry-input">
										</div>
									</div>
									<div class="col-12 col-md-3">
										<div class="form-group mb-2">
											<label for="media_type" class="data-entry-label mb-0" id="media_type_label">Media Type</label>
											<select id="media_type" name="media_type" class="data-entry-select">
												<option></option>
												<cfloop query="ctmedia_type">
													<cfif in_media_type EQ ctmedia_type.media_type><cfset selected="selected='true'"><cfelse><cfset selected=""></cfif>
													<option value="#ctmedia_type.media_type#" #selected#>#ctmedia_type.media_type#</option>
												</cfloop>
												<cfloop query="ctmedia_type">
													<cfif in_media_type EQ "!#ctmedia_type.media_type#"><cfset selected="selected='true'"><cfelse><cfset selected=""></cfif>
													<option value="!#ctmedia_type.media_type#" #selected#>not #ctmedia_type.media_type#</option>
												</cfloop>
											</select>
										</div>
									</div>
									<div class="col-12 col-md-3">
										<div class="form-group mb-2">
											<label for="mime_type" class="data-entry-label mb-0" id="mime_type_label">MIME Type</label>
											<select id="mime_type" name="mime_type" class="data-entry-select" multiple="true">
												<option></option>
												<cfset selectedmimetypelist = "">
												<cfloop query="ctmime_type">
													<cfif listContains(in_mime_type,ctmime_type.mime_type) GT 0>
														<cfset selected="selected='true'">
														<cfset selectedmimetypelist = listAppend(seletedmimetypelist,ctmime_type.mime_type) >
													<cfelse>
														<cfset selected="">
													</cfif>
													<option value="#ctmime_type.mime_type#" #selected#>#ctmime_type.mime_type#</option>
												</cfloop>
											</select>
											<script>
												$(document).ready(function () {
													$("##mime_type").jqxComboBox({  multiSelect: true, width: '100%', enableBrowserBoundsDetection: true });  
													<cfloop list="selectedmimetypelist" index="mt">
														$("##mime_type").jqxComboBox(selectItem: #mt#);
													</cfloop>
												});
											</script>
										</div>
									</div>
								</div>
								<div class="form-row">
									<!--- TODO: controls in this row aren't stable enough yet to make responsive, when stable, typically col-md-4 col-xl-2 ratio --->
									<!--- Set columns for keywords control depending on whether mask search is enabled or not --->
									<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
										<cfset keycols="5">
									<cfelse>
										<cfset keycols="7">
									</cfif>
									<div class="col-12 col-md-5">
										<div class="form-group mb-2">
											<label for="preview_uri" class="data-entry-label mb-0" id="preview_uri_label">Preview URI</label>
											<input type="text" id="preview_uri" name="preview_uri" class="data-entry-input" value="#preview_uri#" aria-labelledby="preview_uri_label" >
										</div>
									</div>
									<div class="col-12 col-md-#keycols#">
										<div class="form-group mb-2">
											<label for="keywords" class="data-entry-label mb-0" id="keywords_label">Keywords <span class="small">(|,*,"",-)</span></label>
											<input type="text" id="keywords" name="keywords" class="data-entry-input" value="#keywords#" aria-labelledby="keywords_label" >
										</div>
									</div>
									<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
										<div class="col-12 col-md-3 col-xl-2">
											<div class="form-group mb-2">
												<label for="mask_media_fg" class="data-entry-label mb-0" id="mask_media_fg_label">Media Record Visibility</label>
												<select id="mask_media_fg" name="mask_media_fg" class="data-entry-select">
													<option></option>
													<cfif mask_media_fg EQ "1"><cfset sel = "selected='true'"><cfelse><cfset sel = ""></cfif>
													<option value="1" #sel#>Hidden</option>
													<cfif mask_media_fg EQ "0"><cfset sel = "selected='true'"><cfelse><cfset sel = ""></cfif>
													<option value="0" #sel#>Public</option>
												</select>
											</div>
										</div>
									</cfif>
								</div>
								<div class="form-row">
									<!--- TODO: controls in this row aren't stable enough yet to make responsive, when stable, typically col-md-4 col-xl-2 ratio --->
									<div class="col-12 col-md-1">
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
									<div class="col-12 col-md-2">
										&nbsp;
										<!--- TODO: Split out more parts of the media_uri, put search controls here between protocol and filename --->
									</div>
									<div class="col-12 col-md-3">
										<div class="form-group mb-2">
											<label for="filename" class="data-entry-label mb-0" id="filename_label">Filename<span></span></label>
											<input type="text" id="filename" name="filename" class="data-entry-input" value="#filename#" aria-labelledby="filename_label" >
										</div>
									</div>
									<div class="col-12 col-md-2">
										<div class="form-group mb-2">
											<label for="original_filename" class="data-entry-label mb-0" id="original_filename_label">Original Filename
												<span class="small">
													(<button type="button" tabindex="-1" aria-hidden="true"  class="border-0 bg-light m-0 p-0 btn-link" onclick="var e=document.getElementById('original_filename');e.value='='+e.value;">=</button><span class="sr-only">prefix with equals sign for exact match search</span>, 
													NULL, NOT NULL)
												</span>
											</label>
											<input type="text" id="original_filename" name="original_filename" class="data-entry-input" value="#original_filename#" aria-labelledby="original_filename_label" >
										</div>
									</div>
									<div class="col-12 col-md-2">
										<div class="form-group mb-2">
											<label for="description" class="data-entry-label mb-0 " id="description_label">Description <span class="small">(NULL, NOT NULL)</span></label>
											<input type="text" id="description" name="description" class="data-entry-input" value="#description#" aria-labelledby="description_label" >
										</div>
									</div>
									<div class="col-12 col-md-2">
										<div class="form-group mb-2">
											<label for="created_by_agent_name" id="created_by_agent_name_label" class="data-entry-label mb-0 pb-0 small">Created By Agent
												<h5 id="created_by_agent_view" class="d-inline">&nbsp;&nbsp;&nbsp;&nbsp;</h5> 
											</label>
											<div class="input-group">
												<div class="input-group-prepend">
													<span class="input-group-text smaller bg-lightgreen" id="created_by_agent_name_icon"><i class="fa fa-user" aria-hidden="true"></i></span> 
												</div>
												<input type="text" name="created_by_agent_name" id="created_by_agent_name" class="form-control rounded-right data-entry-input form-control-sm" aria-label="Agent Name" aria-describedby="created_by_agent_name_label" value="#created_by_agent_name#">
												<input type="hidden" name="created_by_agent_id" id="created_by_agent_id" value="#created_by_agent_id#">
											</div>
										</div>
									</div>
									<script>
										$(document).ready(function() {
											$(makeRichAgentPicker('created_by_agent_name', 'created_by_agent_id', 'created_by_agent_name_icon', 'created_by_agent_view', '#created_by_agent_id#'));
										});
									</script>
								</div>
								<div class="form-row">
									<div class="col-12 col-md-4 col-xl-2">
										<div class="form-group mb-2">
											<label for="height" class="data-entry-label mb-0" id="height_label">Height 
												<span class="small">
													(<button type="button" tabindex="-1" aria-hidden="true"  class="border-0 bg-light m-0 p-0 btn-link" onclick="var e=document.getElementById('height');e.value='>'+e.value;">&gt;</button><span class="sr-only">prefix with greater than sign for search for larger than provided value</span>, 
													<button type="button" tabindex="-1" aria-hidden="true"  class="border-0 bg-light m-0 p-0 btn-link" onclick="var e=document.getElementById('height');e.value='<'+e.value;">&lt;</button><span class="sr-only">prefix with less than sign for search for smaller than provided value</span>, 
													NULL, NOT NULL)
												</span>
											</label>
											<input type="text" id="height" name="height" class="data-entry-input" value="#height#" aria-labelledby="height_label" >
										</div>
									</div>
									<div class="col-12 col-md-4 col-xl-2">
										<div class="form-group mb-2">
											<label for="width" class="data-entry-label mb-0" id="width_label">Width 
												<span class="small">
													(<button type="button" tabindex="-1" aria-hidden="true"  class="border-0 bg-light m-0 p-0 btn-link" onclick="var e=document.getElementById('width');e.value='>'+e.value;">&gt;</button><span class="sr-only">prefix with greater than sign for search for larger than provided value</span>, 
													<button type="button" tabindex="-1" aria-hidden="true"  class="border-0 bg-light m-0 p-0 btn-link" onclick="var e=document.getElementById('width');e.value='<'+e.value;">&lt;</button><span class="sr-only">prefix with less than sign for search for smaller than provided value</span>, 
													NULL, NOT NULL)
												</span>
											</label>
											<input type="text" id="width" name="width" class="data-entry-input" value="#width#" aria-labelledby="width_label" >
										</div>
									</div>
									<div class="col-12 col-md-4 col-xl-2">
										<div class="form-group mb-2">
											<label for="aspect" class="data-entry-label mb-0" id="aspect_label">Aspect 
												<span class="small">
													(<button type="button" tabindex="-1" aria-hidden="true"  class="border-0 bg-light m-0 p-0 btn-link" class="btn-link" onclick="var e=document.getElementById('aspect');e.value='='+e.value;">=</button><span class="sr-only">prefix with equals sign for exact match search</span>, 
													NULL, NOT NULL)
												</span>
											</label>
											<input type="text" id="aspect" name="aspect" class="data-entry-input" value="#aspect#" aria-labelledby="aspect_label" >
											<script>
												$(document).ready(function() {
													makeAspectAutocomplete("aspect");
												});
											</script>
										</div>
									</div>
									<div class="col-12 col-md-4 col-xl-2">
										<div class="form-group mb-2">
											<label for="subject" class="data-entry-label mb-0" id="subject_label">Subject <span class="small">(NULL, NOT NULL)</span></label>
											<input type="text" id="subject" name="subject" class="data-entry-input" value="#subject#" aria-labelledby="subject_label" >
											<script>
												$(document).ready(function() {
													makeMediaLabelAutocomplete("subject","subject");
												});
											</script>
										</div>
									</div>
									<cfset remcolm="8">
									<cfset remcolx="4">
									<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
										<cfset remcolm="4">
										<cfset remcolx="2">
										<div class="col-12 col-md-4 col-xl-2">
											<div class="form-group mb-2">
												<label for="internal_remarks" class="data-entry-label mb-0" id="internal_remarks_label">Internal Remarks <span class="small">(NULL, NOT NULL)</span></label>
												<input type="text" id="internal_remarks" name="internal_remarks" class="data-entry-input" value="#internal_remarks#" aria-labelledby="internal_remarks_label" >
											</div>
										</div>
									</cfif>
									<div class="col-12 col-md-#remcolm# col-xl-#remcolx#">
										<div class="form-group mb-2">
											<label for="remarks" class="data-entry-label" id="remarks_label">Remarks <span class="small">(NULL, NOT NULL)</span></label>
											<input type="text" id="remarks" name="remarks" class="data-entry-input" value="#remarks#" aria-labelledby="remarks_label" >
										</div>
									</div>
								</div>
								<div class="form-row">
									<!--- setup to hide search for date as text from most users --->
									<cfset datecolm="6">
									<cfset datecolx="3">
									<cfset asdate = "">
									<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_media")>
										<cfset datecolm="4">
										<cfset datecolx="2">
										<cfset asdate = "(as date)">
									</cfif>
									<div class="col-12 col-md-#datecolm# col-xl-#datecolx#">
										<div class="form-row mx-0 mb-2">
											<label class="data-entry-label mx-1 mb-0" for="made_date">Made Date Start #asdate#</label>
											<input name="made_date" id="made_date" type="text" class="datetimeinput col-11 data-entry-input" placeholder="start yyyy-mm-dd or yyyy" value="#made_date#" aria-label="start of range for transaction date">
										</div>
									</div>
									<div class="col-12 col-md-#datecolm# col-xl-#datecolx#">
										<div class="form-row mx-0 mb-2">
											<label class="data-entry-label mx-1 mb-0" for="made_date">Made Date End #asdate#</label>
											<input type="text" name="to_made_date" id="to_made_date" value="#to_made_date#" class="datetimeinput col-11 data-entry-input" placeholder="end yyyy-mm-dd or yyyy" title="end of date range">
										</div>
									</div>
									<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_media")>
										<!--- hide search for date as text from most users, too confusing --->
										<div class="col-12 col-md-4 col-xl-2">
											<div class="form-group mb-2">
												<label for="text_made_date" class="data-entry-label mb-0" id="text_made_date_label">Made Date (as text)
													<span class="small">
														(<a href="##" tabindex="-1" aria-hidden="true" class="btn-link" onclick="var e=document.getElementById('text_made_date');e.value='='+e.value;">=</a><span class="sr-only">prefix with equals sign for exact match search</span>, 
														NULL, NOT NULL)
													</span>
												</label>
												<input type="text" id="text_made_date" name="text_made_date" class="data-entry-input" value="#text_made_date#" aria-labelledby="text_made_date_label" >
												<script>
													$(document).ready(function() {
														makeMediaLabelAutocomplete("text_made_date","made date");
													});
												</script>
											</div>
										</div>
									</cfif>
									<div class="col-12 col-md-4 col-xl-2">
										<div class="form-group mb-2">
											<label for="light_source" class="data-entry-label mb-0" id="light_source_label">Light Source 
												<span class="small">
													(<button type="button" tabindex="-1" aria-hidden="true"  class="border-0 bg-light m-0 p-0 btn-link" onclick="var e=document.getElementById('light_source');e.value='='+e.value;">=</button><span class="sr-only">prefix with equals sign for exact match search</span>, 
													NULL, NOT NULL)
												</span>
											</label>
											<input type="text" id="light_source" name="light_source" class="data-entry-input" value="#light_source#" aria-labelledby="light_source_label" >
											<script>
												$(document).ready(function() {
													makeMediaLabelAutocomplete("light_source","light source");
												});
											</script>
										</div>
									</div>
									<div class="col-12 col-md-4 col-xl-2">
										<div class="form-group mb-2">
											<label for="spectrometer" class="data-entry-label mb-0" id="spectrometer_label">Spectrometer 
												<span class="small">
													(<button type="button" tabindex="-1" aria-hidden="true"  class="border-0 bg-transparent m-0 p-0 btn-link" onclick="var e=document.getElementById('spectrometer');e.value='='+e.value;">=</button><span class="sr-only">prefix with equals sign for exact match search</span>, 
													NULL, NOT NULL)
												</span>
											</label>
											<input type="text" id="spectrometer" name="spectrometer" class="data-entry-input" value="#spectrometer#" aria-labelledby="spectrometer_label" >
											<script>
												$(document).ready(function() {
												makeMediaLabelAutocomplete("spectrometer","spectrometer");
												});
											</script>
										</div>
									</div>
									<div class="col-12 col-md-4 col-xl-2">
										<div class="form-group mb-2">
											<label for="spectrometer_reading_location" class="data-entry-label mb-0" id="spectrometer_reading_location_label">Spectrometer Read Loc.
												<span class="small">
												(<button type="button" tabindex="-1" aria-hidden="true"  class="border-0 bg-light m-0 p-0 btn-link" onclick="var e=document.getElementById('spectrometer_reading_location');e.value='='+e.value;">=</button><span class="sr-only">prefix with equals sign for exact match search</span>, 
												NULL, NOT NULL)
												</span>
											</label>
											<input type="text" id="spectrometer_reading_location" name="spectrometer_reading_location" class="data-entry-input" value="#spectrometer_reading_location#" aria-labelledby="spectrometer_reading_location_label" >
											<script>
												$(document).ready(function() {
													makeMediaLabelAutocomplete("spectrometer_reading_location","spectrometer reading location");
												});
											</script>
										</div>
									</div>
								</div>
								<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
									<div class="form-row">
										<div class="col-12 col-md-4 col-xl-2">
											<div class="form-group mb-2">
												<label for="owner" class="data-entry-label mb-0" id="owner_label">Owner 
													<span class="small">
														(<a href="##" tabindex="-1" aria-hidden="true" class="btn-link" onclick="var e=document.getElementById('owner');e.value='='+e.value;">=</a><span class="sr-only">prefix with equals sign for exact match search</span>, 
														NULL, NOT NULL)
													</span>
												</label>
												<input type="text" id="owner" name="owner" class="data-entry-input" value="#owner#" aria-labelledby="owner_label" >
												<script>
													$(document).ready(function() {
														makeMediaLabelAutocomplete("owner","owner");
													});
												</script>
											</div>
										</div>
										<div class="col-12 col-md-4 col-xl-2">
											<div class="form-group mb-2">
												<label for="credit" class="data-entry-label mb-0" id="credit_label">Credit 
													<span class="small">
														(<button type="button" tabindex="-1" aria-hidden="true"  class="border-0 bg-light m-0 p-0 btn-link" onclick="var e=document.getElementById('credit');e.value='='+e.value;">=</button><span class="sr-only">prefix with equals sign for exact match search</span>, 
														NULL, NOT NULL)
													</span>
												</label>
												<input type="text" id="credit" name="credit" class="data-entry-input" value="#credit#" aria-labelledby="credit_label" >
												<script>
													$(document).ready(function() {
														makeMediaLabelAutocomplete("credit","credit");
													});
												</script>
											</div>
										</div>
										<div class="col-12 col-md-4 col-xl-2">
											<div class="form-group mb-2">
												<label for="md5hash" class="data-entry-label mb-0" id="md5hash_label">MD5 Hash 
													<span class="small">
														(<button type="button" tabindex="-1" aria-hidden="true" class="border-0 bg-light m-0 p-0 btn-link" onclick="var e=document.getElementById('md5hash');e.value='='+e.value;">=</button><span class="sr-only">prefix with equals sign for exact match search</span>, 
														NULL, NOT NULL)
													</span>
												</label>
												<input type="text" id="md5hash" name="md5hash" class="data-entry-input" value="#md5hash#" aria-labelledby="md5hash_label" >
											</div>
										</div>
										<div class="col-12 col-md-2">
											<!---- Place holder:  More internal only controls will go here --->
										</div>
									</div>
								</cfif>
								<div class="form-row">
									<div class="col-12 col-md-4 col-xl-2">
										<!---- Place holder:  Relationship search controls will go here --->
									</div>
								</div>
								<div class="form-row my-0 mx-0">
									<div class="col-12 px-0 pt-0">
										<button class="btn-xs btn-primary px-2 my-2 mr-1" id="searchButton" type="submit" aria-label="Search for media">Search<span class="fa fa-search pl-1"></span></button>
										<button type="reset" class="btn-xs btn-warning my-2 mr-1" aria-label="Reset search form to inital values" onclick="">Reset</button>
										<button type="button" class="btn-xs btn-warning my-2 mr-1" aria-label="Start a new media search with a clear form" onclick="window.location.href='#Application.serverRootUrl#/media/findMedia.cfm';" >New Search</button>
									</div>
								</div>
							</form>
						</div><!--- col --->
					</div><!--- search box --->
				</div><!--- row --->
			</section>
		
			<!--- Results table as a jqxGrid. --->
			<section class="container-fluid">
				<div class="row mx-0">
					<div class="col-12">
						<div class="mb-5">
							<div class="row mt-1 mb-0 pb-0 jqx-widget-header border px-2">
								<h1 class="h4">Results: </h1>
								<span class="d-block px-3 p-2" id="resultCount"></span> <span id="resultLink" class="d-block p-2"></span>
								<div id="columnPickDialog">
									<div class="container-fluid">
										<div class="row">
											<div class="col-12 col-md-6">
												<div id="columnPick" class="px-1"></div>
											</div>
											<div class="col-12 col-md-6">
												<div id="columnPick1" class="px-1"></div>
											</div>
										</div>
									</div>
								</div>
								<div id="columnPickDialogButton"></div>
								<cfif Application.serverrole NEQ "production" >
									<div id="gridCardToggleButton"></div>
								</cfif>
								<div id="resultDownloadButtonContainer"></div>
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
		</main>

		<script>
			var linkIdCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
				var rowData = jQuery("##searchResultsGrid").jqxGrid('getrowdata',row);
				return '<span style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; "><a target="_blank" href="/media/' + rowData['media_id'] + '">'+value+'</a></span>';
			};
			var licenceCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
				var rowData = jQuery("##searchResultsGrid").jqxGrid('getrowdata',row);
				var luri = rowData['licence_uri'];
				if (luri != "") { 
					return '<span style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; "><a target="_blank" href="' + luri + '">'+value+'</a></span>';
				} else { 
					return '<span style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; ">'+value+'</span>';
				}
			};
			var thumbCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
				var rowData = jQuery("##searchResultsGrid").jqxGrid('getrowdata',row);
				var puri = rowData['preview_uri'];
				var muri = rowData['media_uri'];
				var alt = rowData['ac_description'];
				if (puri != "") { 
					return '<span style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; "><a target="_blank" href="'+ muri + '"><img src="'+puri+'" alt="'+alt+'" width="100"></a></span>';
				} else { 
					return '<span style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; ">'+value+'</span>';
				}
			};
			function toggleCardView() { 
				var currentState = $("##searchResultsGrid").jqxGrid('cardview');
				$("##searchResultsGrid").jqxGrid({cardview: !currentState});
			};
	
			$(document).ready(function() {
				/* Setup date time input controls */
				$(".datetimeinput").datepicker({ 
					defaultDate: null,
					changeMonth: true,
					changeYear: true,
					dateFormat: 'yy-mm-dd', /* ISO Date format, yy is 4 digit year */
					buttonImageOnly: true,
					buttonImage: "/shared/images/calendar_icon.png",
					showOn: "button"
				});

				/* Setup jqxgrid for Search */
				$('##searchForm').bind('submit', function(evt){
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
							{ name: 'media_id', type: 'string' },
							<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
								{ name: 'mask_media_fg', type: 'string' },
							</cfif>
							{ name: 'credit', type: 'string' },
							{ name: 'licence_uri', type: 'string' },
							{ name: 'licence_display', type: 'string' },
							{ name: 'media_type', type: 'string' },
							{ name: 'mime_type', type: 'string' },
							{ name: 'protocol', type: 'string' },
							{ name: 'filename', type: 'string' },
							{ name: 'creator', type: 'string' },
							{ name: 'owner', type: 'string' },
							{ name: 'credit', type: 'string' },
							{ name: 'dc_rights', type: 'string' },
							{ name: 'relations', type: 'string' },
							{ name: 'ac_description', type: 'string' },
							{ name: 'aspect', type: 'string' },
							{ name: 'description', type: 'string' },
							{ name: 'made_date', type: 'string' },
							{ name: 'subject', type: 'string' },
							{ name: 'original_filename', type: 'string' },
							<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
								{ name: 'internal_remarks', type: 'string' },
							</cfif>
							{ name: 'remarks', type: 'string' },
							{ name: 'spectrometer', type: 'string' },
							{ name: 'light_source', type: 'string' },
							{ name: 'spectrometer_reading_location', type: 'string' },
							{ name: 'height', type: 'string' },
							{ name: 'width', type: 'string' },
							{ name: 'preview_uri', type: 'string' },
							{ name: 'media_uri', type: 'string' }
						],
						updaterow: function (rowid, rowdata, commit) {
							commit(true);
						},
						root: 'mediaRecord',
						id: 'media_id',
						url: '/media/component/search.cfc?' + $('##searchForm').serialize(),
						timeout: 60000,  // units not specified, miliseconds? 
						loadError: function(jqXHR, textStatus, error) { 
							$("##overlay").hide();
							handleFail(jqXHR,textStatus,error,"running media search");
						},
						async: true
					};
			
					var dataAdapter = new $.jqx.dataAdapter(search);
					var initRowDetails = function (index, parentElement, gridElement, datarecord) {
						// could create a dialog here, but need to locate it later to hide/show it on row details opening/closing and not destroy it.
						var details = $($(parentElement).children()[0]);
						details.html("<div id='rowDetailsTarget" + index + "'></div>");
			
						createRowDetailsDialog('searchResultsGrid','rowDetailsTarget',datarecord,index);
						// Workaround, expansion sits below row in zindex.
						var maxZIndex = getMaxZIndex();
						$(parentElement).css('z-index',maxZIndex - 1); // will sit just behind dialog
					}
			
					$("##searchResultsGrid").jqxGrid({
						width: '100%',
						autoheight: 'true',
						autorowheight: 'true',
						rowsheight: 83,
						source: dataAdapter,
						filterable: true,
						sortable: true,
						pageable: true,
						editable: false,
						pagesize: '50',
						pagesizeoptions: ['5','50','100'],
						showaggregates: true,
						columnsresize: true,
						autoshowfiltericon: true,
						autoshowcolumnsmenubutton: false,
						autoshowloadelement: false,  // overlay acts as load element for form+results
						columnsreorder: true,
						groupable: true,
						selectionmode: 'singlerow',
						altrows: true,
						showtoolbar: false,
						<cfif Application.serverrole NEQ "production" >
							cardview: false,
							cardviewcolumns: [
								{ width: 'auto', datafield: 'media_id' },
								{ width: 'auto', datafield: 'preview_uri' },
								{ width: 'auto', datafield: 'media_type' },
								{ width: 'auto', datafield: 'mime_type' },
								{ width: 'auto', datafield: 'aspect' },
								{ width: 'auto', datafield: 'description' },
								{ width: 'auto', datafield: 'original_filename' },
								{ width: 'auto', datafield: 'height' },
								{ width: 'auto', datafield: 'width' },
								{ width: 'auto', datafield: 'media_uri' }
							],
						</cfif>
						columns: [
							{text: 'ID', datafield: 'media_id', width:100, hideable: true, hidden: false, cellsrenderer: linkIdCellRenderer },
							{text: 'Preview URI', datafield: 'preview_uri', width: 102, hidable: true, hidden: false, cellsrenderer: thumbCellRenderer },
							<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
								{text: 'Visibility', datafield: 'mask_media_fg', width: 60, hidable: true, hidden: true },
							</cfif>
							{text: 'Media Type', datafield: 'media_type', width: 100, hidable: true, hidden: false },
							{text: 'Mime Type', datafield: 'mime_type', width: 100, hidable: true, hidden: false },
							{text: 'Protocol', datafield: 'protocol', width: 80, hidable: true, hidden: true },
							{text: 'Filename', datafield: 'filename', width: 100, hidable: true, hidden: true },
							{text: 'Aspect', datafield: 'aspect', width: 100, hidable: true, hidden: false },
							{text: 'Description', datafield: 'description', width: 140, hidable: true, hidden: false },
							{text: 'Made Date', datafield: 'made_date', width: 100, hidable: true, hidden: true },
							{text: 'Subject', datafield: 'subject', width: 100, hidable: true, hidden: true },
							{text: 'Original Filename', datafield: 'original_filename', width: 120, hidable: true, hidden: false },
							<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
								{text: 'Internal Remarks', datafield: 'internal_remarks', width: 100, hidable: true, hidden: true },
							</cfif>
							{text: 'Remarks', datafield: 'remarks', width: 100, hidable: true, hidden: true },
							{text: 'Spectrometer', datafield: 'spectrometer', width: 100, hidable: true, hidden: true },
							{text: 'Light Source', datafield: 'light_source', width: 100, hidable: true, hidden: true },
							{text: 'Spectrometer Reading Location', datafield: 'spectrometer_reading_location', width: 100, hidable: true, hidden: true },
							{text: 'height', datafield: 'height', width: 80, hidable: true, hidden: false },
							{text: 'width', datafield: 'width', width: 80, hidable: true, hidden: false },
							{text: 'Creator', datafield: 'creator', width: 100, hidable: true, hidden: true },
							{text: 'Owner', datafield: 'owner', width: 100, hidable: true, hidden: true },
							{text: 'Credit', datafield: 'credit', width: 100, hidable: true, hidden: true },
							{text: 'DC:rights', datafield: 'dc_rights', width: 100, hidable: true, hidden: true },
							{text: 'License', datafield: 'license_display', width: 100, hidable: true, hidden: true, cellsrenderer: licenceCellRenderer },
							{text: 'Relations', datafield: 'relations', width: 200, hidable: true, hidden: true },
							{text: 'Alt Text', datafield: 'ac_description', width: 200, hidable: true, hidden: true },
							{text: 'Media URI', datafield: 'media_uri', hideable: true, hidden: false }
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
						$('##resultLink').html('<a href="/media/findMedia.cfm?execute=true&' + $('##searchForm').serialize() + '">Link to this search</a>');
						gridLoaded('searchResultsGrid','media records');
					});
					$('##searchResultsGrid').on('rowexpand', function (event) {
						//  Create a content div, add it to the detail row, and make it into a dialog.
						var args = event.args;
						var rowIndex = args.rowindex;
						var datarecord = args.owner.source.records[rowIndex];
						createRowDetailsDialog('searchResultsGrid','rowDetailsTarget',datarecord,rowIndex);
					});
					$('##searchResultsGrid').on('rowcollapse', function (event) {
						// remove the dialog holding the row details
						var args = event.args;
						var rowIndex = args.rowindex;
						$("##searchResultsGridRowDetailsDialog" + rowIndex ).dialog("destroy");
					});
				});
				/* End Setup jqxgrid for Search ******************************/

				// If requested in uri, execute search immediately.
				<cfif isdefined("execute")>
					$('##searchForm').submit();
				</cfif>
			}); /* End document.ready */

			function gridLoaded(gridId, searchType) { 
				$("##overlay").hide();
				var now = new Date();
				var nowstring = now.toISOString().replace(/[^0-9TZ]/g,'_');
				var filename = searchType + '_results_' + nowstring + '.csv';
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
					$('##' + gridId).jqxGrid({ pagesizeoptions: ['5','50', '100', rowcount],pagesize: 50});
				} else if (rowcount > 50) { 
					$('##' + gridId).jqxGrid({ pagesizeoptions: ['5','50', rowcount],pagesize:50});
				} else { 
					$('##' + gridId).jqxGrid({ pageable: false });
				}
				// add a control to show/hide columns
				var columns = $('##' + gridId).jqxGrid('columns').records;
				var halfcolumns = Math.round(columns.length/2);
				var columnListSource = [];
				for (i = 1; i < halfcolumns; i++) {
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
				for (i = halfcolumns; i < columns.length; i++) {
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
				$("##columnPickDialog").dialog({ 
					height: 'auto', 
					width: 'auto',
					adaptivewidth: true,
					title: 'Show/Hide Columns',
					autoOpen: false,
					modal: true, 
					reszable: true, 
					buttons: { 
						Ok: function(){ $(this).dialog("close"); }
					},
					open: function (event, ui) { 
						var maxZIndex = getMaxZIndex();
						// force to lie above the jqx-grid-cell and related elements, see z-index workaround below
						$('.ui-dialog').css({'z-index': maxZIndex + 4 });
						$('.ui-widget-overlay').css({'z-index': maxZIndex + 3 });
					} 
				});
				$("##columnPickDialogButton").html(
					"<button id='columnPickDialogOpener' onclick=\" $('##columnPickDialog').dialog('open'); \" class='btn-xs btn-secondary px-3 my-1 mx-3' >Show/Hide Columns</button>"
				);
				<cfif Application.serverrole NEQ "production" >
					$("##gridCardToggleButton").html(
						"<button id='gridCardToggleButton' onclick=\" toggleCardView(); \" class='btn-xs btn-secondary px-3 my-1 mx-0' >Grid/Card View</button>"
					);
				</cfif>
				// workaround for menu z-index being below grid cell z-index when grid is created by a loan search.
				// likewise for the popup menu for searching/filtering columns, ends up below the grid cells.
				var maxZIndex = getMaxZIndex();
				$('.jqx-grid-cell').css({'z-index': maxZIndex + 1});
				$('.jqx-grid-group-cell').css({'z-index': maxZIndex + 1});
				$('.jqx-menu-wrapper').css({'z-index': maxZIndex + 2});
				$('##resultDownloadButtonContainer').html('<button id="loancsvbutton" class="btn-xs btn-secondary px-3 mx-0 my-1" aria-label="Export results to csv" onclick=" exportGridToCSV(\'searchResultsGrid\', \''+filename+'\'); " >Export to CSV</button>');
			}
		</script> 
	</cfoutput>
	<div id="overlay" style="position: absolute; top:0px; left:0px; width: 100%; height: 100%; background: rgba(0,0,0,0.5); opacity: 0.99; display: none; z-index: 2;">
		<div class="jqx-rc-all jqx-fill-state-normal" style="position: absolute; left: 50%; top: 25%; width: 10em; height: 2.4em;line-height: 2.4em; padding: 5px; color: ##333333; border-color: ##898989; border-style: solid; margin-left: -5em; opacity: 1;">
			<div class="jqx-grid-load" style="float: left; overflow: hidden; height: 32px; width: 32px;"></div>
			<div style="float: left; display: block; margin-left: 1em;" >Searching...</div>
		</div>
	</div>
</div><!--- overlay container --->
	
<cfinclude template = "/shared/_footer.cfm">
