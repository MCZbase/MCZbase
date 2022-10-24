<!---
/Publications.cfm

Publications search/results 

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
<cfset pageTitle = "Search Publications">
<cfinclude template = "/shared/_header.cfm">

<cfquery name="ctpublication_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select publication_type  from ctpublication_type
</cfquery>
<cfquery name="ctpublication_attribute" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select publication_attribute, description, control  from ctpublication_attribute
</cfquery>

<div id="overlaycontainer" style="position: relative;"> 
	<!--- ensure fields have empty values present if not defined. --->
	<cfif not isdefined("publication_title")> 
		<cfset publication_title="">
	</cfif>
	<cfif not isdefined("publication_remarks")> 
		<cfset publication_remarks="">
	</cfif>
	<cfif not isdefined("publication_type")> 
		<cfset publication_type="">
	</cfif>
	<cfif not isdefined("publication_id")> 
		<cfset publication_id="">
	</cfif>
	<cfif not isdefined("volume")> 
		<cfset volume="">
	</cfif>
	<cfif not isdefined("issue")> 
		<cfset issue="">
	</cfif>
	<cfif not isdefined("number")> 
		<cfset number="">
	</cfif>
	<cfif not isdefined("journal_name")> 
		<cfset journal_name="">
	</cfif>
	<cfif not isdefined("related_cataloged_item")>
		<cfset related_cataloged_item="">
	</cfif>
	<cfif not isdefined("collection_object_id")>
		<cfset collection_object_id="">
	</cfif>
	<cfif not isdefined("publication_attribute_type")>
		<cfset publication_attribute_type="">
	</cfif>
	<cfif not isdefined("publication_attribute_value")>
		<cfset publication_attribute_value="">
	</cfif>
	<cfset in_publication_type="#publication_type#">
	<!--- Search Form ---> 
	<cfoutput>
		<main id="content">
			<section class="container-fluid mb-3" role="search" aria-labelledby="formheader">
				<div class="row mx-0 mb-3">
					<div class="search-box">
						<div class="search-box-header">
							<h1 class="h3 text-white" id="formheading">Find Media Records</h1>
						</div>
						<!--- setup date pickers --->
						<script>
							$(document).ready(function() {
								$("##begin_date").datepicker({ dateFormat: 'yy-mm-dd'});
								$("##end_date").datepicker({ dateFormat: 'yy-mm-dd'});
							});
						</script>

						<div class="col-12 pt-3 px-4 pb-2">
							<form name="searchForm" id="searchForm">
								<input type="hidden" name="method" value="getMedia">
								<div class="form-row">
									<div class="col-12 col-md-5">
										<div class="form-group mb-2">
											<label for="publication_title" class="data-entry-label mb-0" id="publication_title_label">Title</label>
											<input type="text" id="publication_title" name="publication_title" class="data-entry-input" value="#encodeForHtml(publication_title)#" aria-labelledby="publication_title_label" >
										</div>
									</div>
									<div class="col-12 col-md-2">
										<div class="form-group mb-2">
											<label for="publication_id" class="data-entry-label mb-0" id="mediaid_label">Publication ID</label>
											<input type="text" id="publication_id" name="publication_id" value="#encodeForHtml(publication_id)#" class="data-entry-input" pattern="[0-9]+" title="publication_id is the numeric primary key for the publication record.">
										</div>
									</div>
									<div class="col-12 col-md-2">
										<div class="form-group mb-2">
											<label for="publication_type" class="data-entry-label mb-0" id="publication_type_label">Publication Type</label>
											<select id="publication_type" name="publication_type" class="data-entry-select">
												<option></option>
												<cfloop query="ctpublication_type">
													<cfif in_publication_type EQ ctpublication_type.publication_type><cfset selected="selected='true'"><cfelse><cfset selected=""></cfif>
													<option value="#ctpublication_type.publication_type#" #selected#>#ctpublication_type.publication_type#</option>
												</cfloop>
												<cfloop query="ctpublication_type">
													<cfif in_publication_type EQ "!#ctpublication_type.publication_type#"><cfset selected="selected='true'"><cfelse><cfset selected=""></cfif>
													<option value="!#ctpublication_type.publication_type#" #selected#>not #ctpublication_type.publication_type#</option>
												</cfloop>
											</select>
										</div>
									</div>
								</div>
								<div class="form-row">
									<div class="col-12 col-md-1">
										<div class="form-group mb-2">
											<label for="volume" class="data-entry-label mb-0" id="volume_label">Volume<span></span></label>
											<input type="text" id="number" name="number" class="data-entry-input" value="#encodeForHtml(volume)#">
										</div>
									</div>
									<div class="col-12 col-md-2 col-xl-3">
										<div class="form-group mb-2">
											<label for="journal_name" class="data-entry-label mb-0" id="journal_name_label">Journal<span></span></label>
											<input type="text" id="journal_name" name="journal_name" class="data-entry-input" value="#encodeForHtml(journal_name)#" aria-labelledby="journal_name_label" >
										</div>
										<script>
											$(document).ready(function() {
												makeJournalAutocomplete("journal_name","journal_name");
											});
										</script>
									</div>
								</div>
								<div class="form-row">
									<div class="col-12 col-md-3">
										<div class="form-group mb-2">
											<label for="issue" class="data-entry-label mb-0 " id="issue_label">Issue <span class="small">(NULL, NOT NULL)</span></label>
											<input type="text" id="issue" name="issue" class="data-entry-input" value="#encodeForHtml(issue)#" aria-labelledby="issue_label" >
										</div>
									</div>
									<div class="col-12 col-md-3">
										<div class="form-group mb-2">
											<label for="volume" class="data-entry-label mb-0" id="volume_label">Volume <span class="small">(|,*,"",-)</span></label>
											<input type="text" id="volume" name="volume" class="data-entry-input" value="#encodeForHtml(volume)#" aria-labelledby="volume_label" >
										</div>
									</div>
								</div>
								<div class="form-row">
									<div class="col-12 col-md-4 col-xl-2">
										<div class="form-group mb-2">
											<label for="publication_remarks" class="data-entry-label mb-0" id="publication_remarks_label">Publication Remarks</label>
											<input type="text" id="publication_remarks" name="publication_remarks" class="data-entry-input" value="#encodeForHtml(publication_remarks)#" aria-labelledby="publication_remarks_label" >
										</div>
									</div>
									<div class="col-12 col-md-4 col-xl-2">
										<div class="form-row mx-0 mb-2">
											<label class="data-entry-label mx-1 mb-0" for="published_year">Publication Year Start</label>
											<input name="published_year" id="published_year" type="text" class="datetimeinput col-10 col-md-10 col-lg-10 pr-0 col-xl-10 data-entry-input" placeholder="start yyyy-mm-dd or yyyy" value="#encodeForHtml(published_year)#" aria-label="start of range for publication year">
										</div>
									</div>
									<div class="col-12 col-md-4 col-xl-2">
										<div class="form-row mx-0 mb-2">
											<label class="data-entry-label mx-1 mb-0" for="to_published_year">Publication Year End</label>
											<input type="text" name="to_published_year" id="to_published_year" value="#encodeForHtml(to_published_year)#" class="datetimeinput col-10 pr-0 col-md-10 col-lg-10 col-xl-10 data-entry-input" placeholder="end yyyy-mm-dd or yyyy" title="end of date range">
										</div>
									</div>
									<div class="col-12 col-md-4 col-xl-3">
										<div class="form-row mx-0 mb-2">
											<label for="publication_attribute_type" class="data-entry-label mb-0" id="nedia_label_type_label">Any Other Label
												<span class="small">
													(<a href="##" tabindex="-1" aria-hidden="true" class="btn-link" onclick="var e=document.getElementById('publication_attribute_value');e.value='='+e.value;">=</a><span class="sr-only">prefix with equals sign for exact match search</span>, 
													NULL, NOT NULL)
												</span>
											</label>
											<cfset selectedpublication_attribute_type= "#publication_attribute_type#">
											<select id="publication_attribute_type" name="publication_attribute_type" class="data-entry-select col-6">
												<option></option>
												<cfloop query="ctotherpublication_attribute">
													<cfif selectedpublication_attribute_type EQ ctotherpublication_attribute.publication_attribute>
														<cfset selected="selected='true'">
													<cfelse>
														<cfset selected="">
													</cfif>
													<option value="#publication_attribute#" #selected#>#publication_attribute#</option>
												</cfloop>
											</select>
											<input type="text" id="publication_attribute_value" name="publication_attribute_value" class="data-entry-input col-6" value="#encodeForHtml(publication_attribute_value)#">
											<script>
												$(document).ready(function() {
													makeAnyMediaLabelAutocomplete("publication_attribute_value","publication_attribute_type");
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
												<input type="text" id="owner" name="owner" class="data-entry-input" value="#encodeForHtml(owner)#" aria-labelledby="owner_label" >
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
												<input type="text" id="credit" name="credit" class="data-entry-input" value="#encodeForHtml(credit)#" aria-labelledby="credit_label" >
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
												<input type="text" id="md5hash" name="md5hash" class="data-entry-input" value="#encodeForHtml(md5hash)#" aria-labelledby="md5hash_label" >
											</div>
										</div>
										<div class="col-12 col-md-4 col-xl-2">
											<div class="form-group mt-2">
												<cfif len(unlinked) GT 0><cfset checked = "checked"><cfelse><cfset checked = ""></cfif>
												<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_media")>
													<div class="form-check">
														<input type="checkbox" #checked# name="unlinked" id="unlinked" value="true" class="form-check-input mt-1">
														<label for "unlinked" class="form-check-label small90">Limit to Media not yet linked to any record.</label>
													</div>
												</cfif>
											</div>
										</div>
										<div class="col-12 col-md-4 col-xl-2">
											<div class="form-group mt-2">
												<cfif len(multilink) GT 0><cfset checked = "checked"><cfelse><cfset checked = ""></cfif>
												<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_media")>
													<div class="form-check">
														<input type="checkbox" #checked# name="multilink" id="multilink" value="true" class="form-check-input mt-1">
														<label for "multilink" class="form-check-label small90">Limit to Media linked to more than one record.</label>
													</div>
												</cfif>
											</div>
										</div>
										<div class="col-12 col-md-4 col-xl-2">
											<div class="form-group mt-2">
												<cfif len(multitypelink) GT 0><cfset checked = "checked"><cfelse><cfset checked = ""></cfif>
												<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_media")>
													<div class="form-check">
														<input type="checkbox" #checked# name="multitypelink" id="multitypelink" value="true" class="form-check-input mt-1">
														<label for "multitypelink" class="form-check-label small90">Limit to Media with more than one type of relationship.</label>
													</div>
												</cfif>
											</div>
										</div>
									</div>
								</cfif>
								<div class="form-row">
									<div class="col-12 col-md-6 col-lg-5 col-xl-4">
									<div class="form-group mb-2">
										<input type="hidden" id="collection_object_id" name="collection_object_id" value="#encodeForHtml(collection_object_id)#">
										<cfif isDefined("collection_object_id") AND len(collection_object_id) GT 0>
											<cfquery name="guidLookup" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="guidLookup">
												select distinct guid 
												from 
													<cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat 
													left join specimen_part on flat.collection_object_id = specimen_part.derived_from_cat_item
												where 
													specimen_part.collection_object_id in (<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#" list="yes">)
												OR flat.collection_object_id in (<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#" list="yes">)
											</cfquery>
											<cfloop query="guidLookup">
												<cfif not listContains(related_cataloged_item,guidLookup.guid)>
													<cfif len(related_cataloged_item) EQ 0>
														<cfset related_cataloged_item = guidLookup.guid>
													<cfelse>
														<cfset related_cataloged_item = related_cataloged_item & "," & guidSearch.guid>
													</cfif>
												</cfif>
											</cfloop>
										</cfif>
										<label for="related_cataloged_item" class="data-entry-label mb-0" id="related_cataloged_item_label">Shows Cataloged Item 
											<span class="small">
												(NOT NULL, accepts comma separated list)
											</span>
										</label>
										<input type="text" name="related_cataloged_item" 
											class="data-entry-input" value="#encodeForHtml(related_cataloged_item)#" id="related_cataloged_item" placeholder="MCZ:Coll:nnnnn"
											onchange="$('##collection_object_id').val('');">
									</div>
								</div>
									<div class="col-12 col-md-6 col-xl-4">
										<div class="form-row mx-0 mb-2">
										<label for="media_relationship_type" class="data-entry-label mb-0" id="nedia_relationship_type_label">Relationship
											<span class="small">
												(
												<a href="##" tabindex="-1" aria-hidden="true" class="btn-link" onclick="var e=document.getElementById('media_relationship_value');e.value='NULL';">NULL</a><span class="sr-only">use NULL to find media records without the selected relationship</span>, 
												<a href="##" tabindex="-1" aria-hidden="true" class="btn-link" onclick="var e=document.getElementById('media_relationship_value');e.value='NOT_NULL';">NOT_NULL</a><span class="sr-only">use NOT_NULL to find media records with the selected relationship to any record</span>
												)
											</span>
										</label>
										<cfset selectedrelationship_type= "#media_relationship_type#">
										<select id="media_relationship_type" name="media_relationship_type" class="data-entry-select col-6">
											<option></option>
											<cfloop query="ctmedia_relationship">
												<cfif selectedrelationship_type EQ ctmedia_relationship.media_relationship>
													<cfset selected="selected='true'">
												<cfelse>
													<cfset selected="">
												</cfif>
												<option value="#media_relationship#" #selected#>#media_relationship#</option>
											</cfloop>
										</select>
										<input type="text" id="media_relationship_value" name="media_relationship_value" class="data-entry-input col-6" value="#encodeForHtml(media_relationship_value)#">
										<input type="hidden" id="media_relationship_id" name="media_relationship_id" value="#encodeForHtml(media_relationship_id)#">
										<script>
											$(document).ready(function() {
												$('##media_relationship_type').change(function() {
													makeAnyMediaRelationAutocomplete("media_relationship_value","media_relationship_type","media_relationship_id");
												});
											});
										</script>
									</div>
									</div>
									<div class="col-12 col-md-6 col-xl-4">
										<div class="form-row mx-0 mb-2">
										<label for="media_relationship_type_1" class="data-entry-label mb-0" id="nedia_relationship_type_label_1">Relationship
											<span class="small">
												(
												<a href="##" tabindex="-1" aria-hidden="true" class="btn-link" onclick="var e=document.getElementById('media_relationship_value_1');e.value='NULL';">NULL</a><span class="sr-only">use NULL to find media records without the selected relationship</span>, 
												<a href="##" tabindex="-1" aria-hidden="true" class="btn-link" onclick="var e=document.getElementById('media_relationship_value_1');e.value='NOT_NULL';">NOT_NULL</a><span class="sr-only">use NOT_NULL to find media records with the selected relationship to any record</span>
												)
											</span>
										</label>
										<cfset selectedrelationship_type= "#media_relationship_type_1#">
										<select id="media_relationship_type_1" name="media_relationship_type_1" class="data-entry-select col-6">
											<option></option>
											<cfloop query="ctmedia_relationship">
												<cfif selectedrelationship_type EQ ctmedia_relationship.media_relationship>
													<cfset selected="selected='true'">
												<cfelse>
													<cfset selected="">
												</cfif>
												<option value="#media_relationship#" #selected#>#media_relationship#</option>
											</cfloop>
										</select>
										<input type="text" id="media_relationship_value_1" name="media_relationship_value_1" class="data-entry-input col-6" value="#encodeForHtml(media_relationship_value_1)#">
										<input type="hidden" id="media_relationship_id_1" name="media_relationship_id_1" value="#encodeForHtml(media_relationship_id_1)#">
										<script>
											$(document).ready(function() {
												$('##media_relationship_type_1').change(function() {
													makeAnyMediaRelationAutocomplete("media_relationship_value_1","media_relationship_type_1","media_relationship_id_1");
												});
											});
										</script>
									</div>
									</div>
									<div class="col-12 pt-0">
										<button class="btn-xs btn-primary px-2 my-2 mr-1" id="searchButton" type="submit" aria-label="Search for media">Search<span class="fa fa-search pl-1"></span></button>
										<button type="reset" class="btn-xs btn-warning my-2 mr-1" aria-label="Reset search form to inital values" onclick="">Reset</button>
										<button type="button" class="btn-xs btn-warning my-2 mr-1" aria-label="Start a new media search with a clear form" onclick="window.location.href='#Application.serverRootUrl#/media/findMedia.cfm';" >New Search</button>
									</div>
								</div>
	
							</form>
						</div>
					</div><!--- search box --->
				</div><!--- row --->
			</section>
		
			<!--- Results table as a jqxGrid. --->
			<section class="container-fluid">
				<div class="row mx-0">
					<div class="col-12">
						<div class="mb-5">
							<div class="row my-1 jqx-widget-header border px-2">
								<h1 class="h4 pt-2 ml-2 ml-md-1 mt-1">Results: 
									<span class="pr-2 font-weight-normal" id="resultCount"></span> 
									<span id="resultLink" class="font-weight-normal pr-2"></span>
								</h1>
								<div id="saveDialogButton" class=""></div>
								<div id="saveDialog"></div>
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
								<output id="actionFeedback" class="btn btn-xs btn-transparent my-2 px-2 pt-1 mx-1 border-0"></output>
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
			window.columnHiddenSettings = new Object();
			<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
				lookupColumnVisibilities ('#cgi.script_name#','Default');
			</cfif>

			var linkIdCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
				var rowData = jQuery("##searchResultsGrid").jqxGrid('getrowdata',row);
				return '<span style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; "><a target="_blank" href="/media/' + rowData['publication_id'] + '">'+value+'</a></span>';
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
				var puri = rowData['publication_remarks'];
				var muri = rowData['publication_title'];
				var alt = rowData['ac_issue'];
				if (puri != "") { 
					return '<span style="margin-top: 0px; float: ' + columnproperties.cellsalign + '; "><a class="pl-0" target="_blank" href="'+ muri + '"><img src="'+puri+'" alt="'+alt+'" width="100%"></a></span>';
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
					$('##saveDialogButton').html('');
					$('##actionFeedback').html('');
			
					var search =
					{
						datatype: "json",
						datafields:
						[
							{ name: 'publication_id', type: 'string' },
							<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
								{ name: 'mask_media_fg', type: 'string' },
							</cfif>
							{ name: 'credit', type: 'string' },
							{ name: 'licence_uri', type: 'string' },
							{ name: 'licence_display', type: 'string' },
							{ name: 'publication_type', type: 'string' },
							{ name: 'mime_type', type: 'string' },
							{ name: 'number', type: 'string' },
							{ name: 'host', type: 'string' },
							{ name: 'path', type: 'string' },
							{ name: 'journal_name', type: 'string' },
							{ name: 'extension', type: 'string' },
							{ name: 'creator', type: 'string' },
							{ name: 'owner', type: 'string' },
							{ name: 'credit', type: 'string' },
							{ name: 'dc_rights', type: 'string' },
							{ name: 'relations', type: 'string' },
							{ name: 'ac_issue', type: 'string' },
							{ name: 'aspect', type: 'string' },
							{ name: 'issue', type: 'string' },
							{ name: 'made_date', type: 'string' },
							{ name: 'subject', type: 'string' },
							{ name: 'original_journal_name', type: 'string' },
							<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
								{ name: 'internal_remarks', type: 'string' },
							</cfif>
							{ name: 'remarks', type: 'string' },
							{ name: 'spectrometer', type: 'string' },
							{ name: 'light_source', type: 'string' },
							{ name: 'spectrometer_reading_location', type: 'string' },
							{ name: 'height', type: 'string' },
							{ name: 'width', type: 'string' },
							{ name: 'publication_remarks', type: 'string' },
							{ name: 'publication_title', type: 'string' }
						],
						updaterow: function (rowid, rowdata, commit) {
							commit(true);
						},
						root: 'mediaRecord',
						id: 'publication_id',
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
								{ width: 'auto', datafield: 'publication_id' },
								{ width: 'auto', datafield: 'publication_remarks' },
								{ width: 'auto', datafield: 'publication_type' },
								{ width: 'auto', datafield: 'mime_type' },
								{ width: 'auto', datafield: 'aspect' },
								{ width: 'auto', datafield: 'issue' },
								{ width: 'auto', datafield: 'original_journal_name' },
								{ width: 'auto', datafield: 'height' },
								{ width: 'auto', datafield: 'width' },
								{ width: 'auto', datafield: 'publication_title' }
							],
						</cfif>
						columns: [
							{text: 'ID', datafield: 'publication_id', width:100, hideable: true, hidden: getColHidProp('publication_id', false), cellsrenderer: linkIdCellRenderer },
							{text: 'Preview URI', datafield: 'publication_remarks', width: 100, hidable: true, hidden: getColHidProp('publication_remarks', false), cellsrenderer: thumbCellRenderer },
							<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
								{text: 'Visibility', datafield: 'mask_media_fg', width: 60, hidable: true, hidden: getColHidProp('mask_media_fg', true) },
							</cfif>
							{text: 'Media Type', datafield: 'publication_type', width: 100, hidable: true, hidden: getColHidProp('publication_type', false) },
							{text: 'Mime Type', datafield: 'mime_type', width: 100, hidable: true, hidden: getColHidProp('mime_type', false) },
							{text: 'Protocol', datafield: 'number', width: 80, hidable: true, hidden: getColHidProp('number', true) },
							{text: 'Host', datafield: 'host', width: 80, hidable: true, hidden: getColHidProp('host', true) },
							{text: 'Path', datafield: 'path', width: 80, hidable: true, hidden: getColHidProp('path', true) },
							{text: 'Filename', datafield: 'journal_name', width: 100, hidable: true, hidden: getColHidProp('journal_name', true) },
							{text: 'Extension', datafield: 'extension', width: 80, hidable: true, hidden: getColHidProp('extension', true) },
							{text: 'Aspect', datafield: 'aspect', width: 100, hidable: true, hidden: getColHidProp('aspect', false) },
							{text: 'Description', datafield: 'issue', width: 140, hidable: true, hidden: getColHidProp('issue', false) },
							{text: 'Made Date', datafield: 'made_date', width: 100, hidable: true, hidden: getColHidProp('made_date', true) },
							{text: 'Subject', datafield: 'subject', width: 100, hidable: true, hidden: getColHidProp('subject', true) },
							{text: 'Original Filename', datafield: 'original_journal_name', width: 120, hidable: true, hidden: getColHidProp('original_journal_name', false) },
							<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
								{text: 'Internal Remarks', datafield: 'internal_remarks', width: 100, hidable: true, hidden: getColHidProp('internal_remarks', true) },
							</cfif>
							{text: 'Remarks', datafield: 'remarks', width: 100, hidable: true, hidden: getColHidProp('remarks', true) },
							{text: 'Spectrometer', datafield: 'spectrometer', width: 100, hidable: true, hidden: getColHidProp('spectrometer', true) },
							{text: 'Light Source', datafield: 'light_source', width: 100, hidable: true, hidden: getColHidProp('light_source', true) },
							{text: 'Spectrometer Reading Location', datafield: 'spectrometer_reading_location', width: 100, hidable: true, hidden: getColHidProp('spectrometer_reading_location', true) },
							{text: 'height', datafield: 'height', width: 80, hidable: true, hidden: getColHidProp('height', false) },
							{text: 'width', datafield: 'width', width: 80, hidable: true, hidden: getColHidProp('width', false) },
							{text: 'Creator', datafield: 'creator', width: 100, hidable: true, hidden: getColHidProp('creator', true) },
							{text: 'Owner', datafield: 'owner', width: 100, hidable: true, hidden: getColHidProp('owner', true) },
							{text: 'Credit', datafield: 'credit', width: 100, hidable: true, hidden: getColHidProp('credit', true) },
							{text: 'DC:rights', datafield: 'dc_rights', width: 100, hidable: true, hidden: getColHidProp('dc_rights', true) },
							{text: 'License', datafield: 'license_display', width: 100, hidable: true, hidden: getColHidProp('license_display', true), cellsrenderer: licenceCellRenderer },
							{text: 'Relations', datafield: 'relations', width: 200, hidable: true, hidden: getColHidProp('relations', true) },
							{text: 'Alt Text', datafield: 'ac_issue', width: 200, hidable: true, hidden: getColHidProp('ac_issue', true) },
							{text: 'Media URI', datafield: 'publication_title', hideable: true, hidden: getColHidProp('publication_title', false) }
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
						$('##resultLink').html('<a href="/media/findMedia.cfm?execute=true&' + $('##searchForm :input').filter(function(index,element){return $(element).val()!='';}).serialize() + '">Link to this search</a>');
						gridLoaded('searchResultsGrid','media record');
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


			<cfif isdefined("session.roles") AND listfindnocase(session.roles,"coldfusion_user") >
			function populateSaveSearch() { 
				// set up a dialog for saving the current search.
				var uri = "/media/findMedia.cfm?execute=true&" + $('##searchForm :input').filter(function(index,element){ return $(element).val()!='';}).not(".excludeFromLink").serialize();
				$("##saveDialog").html(
					"<div class='row'>"+ 
					"<form id='saveForm'> " + 
					" <input type='hidden' value='"+uri+"' name='url'>" + 
					" <div class='col-12'>" + 
					"  <label for='search_name_input'>Search Name</label>" + 
					"  <input type='text' id='search_name_input'  name='search_name' value='' class='data-entry-input reqdClr' pattern='Your name for this search' maxlenght='60' required>" + 
					" </div>" + 
					" <div class='col-12'>" + 
					"  <label for='execute_input'>Execute Immediately</label>"+
					"  <input id='execute_input' type='checkbox' name='execute' checked>"+
					" </div>" +
					"</form>"+
					"</div>"
				);
			}
			</cfif>

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
				var journal_name = searchType.replace(/[ ]/g,'_') + '_results_' + nowstring + '.csv';
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
					"<button id='columnPickDialogOpener' onclick=\" $('##columnPickDialog').dialog('open'); \" class='btn btn-xs btn-secondary my-2 mx-1' >Show/Hide Columns</button>"
				);
				<cfif Application.serverrole NEQ "production" >
					$("##gridCardToggleButton").html(
						"<button id='gridCardToggleButton' onclick=\" toggleCardView(); \" class='btn btn-xs btn-secondary my-2 mx-1' >Grid/Card View</button>"
					);
				</cfif>

				<cfif isdefined("session.roles") AND listfindnocase(session.roles,"coldfusion_user") >
					$("##saveDialog").dialog({
						height: 'auto',
						width: 'auto',
						adaptivewidth: true,
						title: 'Save Search',
						autoOpen: false,
						modal: true,
						reszable: true,
						buttons: [
							{
								text: "Save",
								click: function(){
									var url = $('##saveForm :input[name=url]').val();
									var execute = $('##saveForm :input[name=execute]').is(':checked');
									var search_name = $('##saveForm :input[name=search_name]').val();
									saveSearch(url, execute, search_name,"actionFeedback");
									$(this).dialog("close"); 
								},
								tabindex: 0
							},
							{
								text: "Cancel",
								click: function(){ 
									$(this).dialog("close"); 
								},
								tabindex: 0
							}
						],
						open: function (event, ui) {
							var maxZIndex = getMaxZIndex();
							// force to lie above the jqx-grid-cell and related elements, see z-index workaround below
							$('.ui-dialog').css({'z-index': maxZIndex + 4 });
							$('.ui-widget-overlay').css({'z-index': maxZIndex + 3 });
						}
					});
					$("##saveDialogButton").html(
					`<button id="`+gridId+`saveDialogOpener"
							onclick=" populateSaveSearch(); $('##saveDialog').dialog('open'); " 
							class="btn btn-xs btn-secondary mx-1 my-2" >Save Search</button>
					`);
				</cfif>

				// workaround for menu z-index being below grid cell z-index when grid is created by a loan search.
				// likewise for the popup menu for searching/filtering columns, ends up below the grid cells.
				var maxZIndex = getMaxZIndex();
				$('.jqx-grid-cell').css({'z-index': maxZIndex + 1});
				$('.jqx-grid-group-cell').css({'z-index': maxZIndex + 1});
				$('.jqx-menu-wrapper').css({'z-index': maxZIndex + 2});
				$('##resultDownloadButtonContainer').html('<button id="loancsvbutton" class="btn btn-xs btn-secondary mx-1 my-2" aria-label="Export results to csv" onclick=" exportGridToCSV(\'searchResultsGrid\', \''+journal_name+'\'); " >Export to CSV</button>');
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
