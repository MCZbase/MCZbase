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
	select publication_attribute, description, control  
	from ctpublication_attribute
	where publication_attribute not in ('journal name','volume','issue','number','publisher','begin page')
	order by publication_attribute asc
</cfquery>
<cfquery name="collections" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select publication_attribute, description, control  from ctpublication_attribute
</cfquery>

<div id="overlaycontainer" style="position: relative;"> 
	<!--- ensure fields have empty values present if not defined. --->
	<cfif not isdefined("publication_title")> 
		<cfset publication_title="">
	</cfif>
	<cfif not isdefined("text")> 
		<cfset text="">
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
	<cfif not isdefined("publisher")> 
		<cfset publisher="">
	</cfif>
	<cfif not isdefined("author_agent_name")>
		<cfset author_agent_name="">
	</cfif>
	<cfif not isdefined("author_agent_id")>
		<cfset author_agent_id="">
	</cfif>
	<cfif not isdefined("editor_agent_name")>
		<cfset editor_agent_name="">
	</cfif>
	<cfif not isdefined("editor_agent_id")>
		<cfset editor_agent_id="">
	</cfif>
	<cfif not isdefined("published_year")> 
		<cfset published_year="">
	</cfif>
	<cfif not isdefined("to_published_year")> 
		<cfset to_published_year="">
	</cfif>
	<cfif not isdefined("is_peer_reviewed_fg")> 
		<cfset is_peer_reviewed_fg="">
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
	<cfif not isdefined("begin_page")> 
		<cfset begin_page="">
	</cfif>
	<cfif not isdefined("journal_name")> 
		<cfset journal_name="">
	</cfif>
	<cfif not isdefined("doi")> 
		<cfset doi="">
	</cfif>
	<cfif not isdefined("related_cataloged_item")>
		<cfset related_cataloged_item="">
	</cfif>
	<cfif not isdefined("collection_object_id")>
		<cfset collection_object_id="">
	</cfif>
	<cfif not isdefined("cites_specimens")>
		<cfset cites_specimens="">
	</cfif>
	<cfif not isdefined("cites_collection")>
		<cfset cites_collection="">
	</cfif>
	<cfif not isdefined("cited_taxon")>
		<cfset cited_taxon="">
	</cfif>
	<cfif not isdefined("accepted_for_cited_taxon")>
		<cfset accepted_for_cited_taxon="">
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
							<h1 class="h3 text-white" id="formheading">Find Publication Records</h1>
						</div>

						<div class="col-12 pt-3 px-4 pb-2">
							<form name="searchForm" id="searchForm">
								<input type="hidden" name="method" value="getPublications">
								<div class="form-row">
									<div class="col-12 col-md-5">
										<div class="form-group mb-2">
											<label for="text" class="data-entry-label mb-0" id="text_label">Any Part of Citation</label>
											<input type="text" id="text" name="text" class="data-entry-input" value="#encodeForHtml(text)#" aria-labelledby="text_label" >
										</div>
									</div>
									<div class="col-12 col-md-5">
										<div class="form-group mb-2">
											<label for="publication_title" class="data-entry-label mb-0" id="publication_title_label">Title</label>
											<input type="text" id="publication_title" name="publication_title" class="data-entry-input" value="#encodeForHtml(publication_title)#" aria-labelledby="publication_title_label" >
										</div>
									</div>
									<div class="col-12 col-md-2">
										<div class="form-group mb-2">
											<label for="publication_id" class="data-entry-label mb-0" id="publicationid_label">Publication ID</label>
											<input type="text" id="publication_id" name="publication_id" value="#encodeForHtml(publication_id)#" class="data-entry-input" pattern="[0-9]+" title="publication_id is the numeric primary key for the publication record.">
										</div>
									</div>
								</div>
								<div class="form-row">
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
									<div class="col-12 col-md-4">
										<div class="form-group mb-2">
											<label for="journal_name" class="data-entry-label mb-0" id="journal_name_label">Journal <span class="small">(pick, substring, NULL, NOT NULL)</span></label>
											<input type="text" id="journal_name" name="journal_name" class="data-entry-input" value="#encodeForHtml(journal_name)#" aria-labelledby="journal_name_label" >
										</div>
										<script>
											$(document).ready(function() {
												makeJournalAutocomplete("journal_name");
											});
										</script>
									</div>
									<div class="col-12 col-md-2">
										<div class="form-group mb-2">
											<label for="volume" class="data-entry-label mb-0" id="volume_label">Volume <span class="small">(=,!,NULL, NOT NULL)</span></label>
											<input type="text" id="volume" name="volume" class="data-entry-input" value="#encodeForHtml(volume)#" aria-labelledby="volume_label" >
										</div>
									</div>
									<div class="col-12 col-md-2">
										<div class="form-group mb-2">
											<label for="issue" class="data-entry-label mb-0 " id="issue_label">Issue <span class="small">(=,!,NULL, NOT NULL)</span></label>
											<input type="text" id="issue" name="issue" class="data-entry-input" value="#encodeForHtml(issue)#" aria-labelledby="issue_label" >
										</div>
									</div>
									<div class="col-12 col-md-2">
										<div class="form-group mb-2">
											<label for="number" class="data-entry-label mb-0" id="number_label">Number <span class="small">(=,!,NULL, NOT NULL)</span></label>
											<input type="text" id="number" name="number" class="data-entry-input" value="#encodeForHtml(volume)#">
										</div>
									</div>
								</div>
								<div class="form-row">
									<div class="col-12 col-md-4 col-xl-2">
										<div class="form-row mx-0 mb-2">
											<label class="data-entry-label mx-1 mb-0" for="doi" id="doi_label">DOI</label>
											<input type="text" name="doi" id="doi" value="#encodeForHtml(doi)#" class="data-entry-input" title="DOI (digital object identifier)">
										</div>
										<script>
											$(document).ready(function() {
												makeDOIAutocomplete("doi");
											});
										</script>
									</div>
									<div class="col-12 col-md-4 col-xl-2">
										<div class="form-group mb-2">
											<label for="publication_remarks" class="data-entry-label mb-0" id="publication_remarks_label">Publication Remarks</label>
											<input type="text" id="publication_remarks" name="publication_remarks" class="data-entry-input" value="#encodeForHtml(publication_remarks)#" aria-labelledby="publication_remarks_label" >
										</div>
									</div>
									<div class="col-12 col-md-4 col-xl-2">
										<div class="form-row mx-0 mb-2">
											<label class="data-entry-label mx-1 mb-0" for="published_year">Publication Year Start</label>
											<input name="published_year" id="published_year" type="text" class="data-entry-input" placeholder="start yyyy" value="#encodeForHtml(published_year)#" aria-label="start of range for publication year">
										</div>
									</div>
									<div class="col-12 col-md-4 col-xl-2">
										<div class="form-row mx-0 mb-2">
											<label class="data-entry-label mx-1 mb-0" for="to_published_year">Publication Year End</label>
											<input type="text" name="to_published_year" id="to_published_year" value="#encodeForHtml(to_published_year)#" class="data-entry-input" placeholder="end yyyy" title="end of date range">
										</div>
									</div>
									<div class="col-12 col-md-4 col-xl-4">
										<div class="form-row mx-0 mb-2">
											<label for="publication_attribute_type" class="data-entry-label mb-0" id="nedia_label_type_label">Any Attribute
												<span class="small">
													(<a href="##" tabindex="-1" aria-hidden="true" class="btn-link" onclick="var e=document.getElementById('publication_attribute_value');e.value='='+e.value;">=</a><span class="sr-only">prefix with equals sign for exact match search</span>, 
													NULL, NOT NULL)
												</span>
											</label>
											<cfset selectedpublication_attribute_type= "#publication_attribute_type#">
											<select id="publication_attribute_type" name="publication_attribute_type" class="data-entry-select col-6">
												<option></option>
												<cfloop query="ctpublication_attribute">
													<cfif selectedpublication_attribute_type EQ ctpublication_attribute.publication_attribute>
														<cfset selected="selected='true'">
													<cfelse>
														<cfset selected="">
													</cfif>
													<option value="#publication_attribute#" #selected#>#publication_attribute#</option>
												</cfloop>
											</select>
											<input type="text" id="publication_attribute_value" name="publication_attribute_value" class="data-entry-input col-6" value="#encodeForHtml(publication_attribute_value)#">
										</div>
									</div>


									<div class="col-12 col-md-4 col-xl-3">
										<div class="form-group mb-2">
											<label for="author_agent_name" id="author_agent_name_label" class="data-entry-label mb-0 pb-0 small">Author
												<h5 id="author_agent_view" class="d-inline">&nbsp;&nbsp;&nbsp;&nbsp;</h5> 
											</label>
											<div class="input-group">
												<div class="input-group-prepend">
													<span class="input-group-text smaller bg-lightgreen" id="author_agent_name_icon"><i class="fa fa-user" aria-hidden="true"></i></span> 
												</div>
												<input type="text" name="author_agent_name" id="author_agent_name" class="form-control rounded-right data-entry-input form-control-sm" aria-label="Agent Name" aria-describedby="author_agent_name_label" value="#encodeForHtml(author_agent_name)#">
												<input type="hidden" name="author_agent_id" id="author_agent_id" value="#encodeForHtml(author_agent_id)#">
											</div>
										</div>
									</div>
									<script>
										$(document).ready(function() {
											$(makeConstrainedRichAgentPicker('author_agent_name', 'author_agent_id', 'author_agent_name_icon', 'author_agent_view', '#author_agent_id#','author'));
										});
									</script>
									<div class="col-12 col-md-4 col-xl-3">
										<div class="form-group mb-2">
											<label for="editor_agent_name" id="editor_agent_name_label" class="data-entry-label mb-0 pb-0 small">Editor
												<h5 id="editor_agent_view" class="d-inline">&nbsp;&nbsp;&nbsp;&nbsp;</h5> 
											</label>
											<div class="input-group">
												<div class="input-group-prepend">
													<span class="input-group-text smaller bg-lightgreen" id="editor_agent_name_icon"><i class="fa fa-user" aria-hidden="true"></i></span> 
												</div>
												<input type="text" name="editor_agent_name" id="editor_agent_name" class="form-control rounded-right data-entry-input form-control-sm" aria-label="Agent Name" aria-describedby="editor_agent_name_label" value="#encodeForHtml(editor_agent_name)#">
												<input type="hidden" name="editor_agent_id" id="editor_agent_id" value="#encodeForHtml(editor_agent_id)#">
											</div>
										</div>
									</div>
									<div class="col-12 col-md-2">
										<div class="form-group mb-2">
											<label for="begin_page" class="data-entry-label mb-0 " id="begin_page_label">Begin Page <span class="small">(=,!,NULL, NOT NULL)</span></label>
											<input type="text" id="begin_page" name="begin_page" class="data-entry-input" value="#encodeForHtml(begin_page)#" aria-labelledby="begin_page_label" >
										</div>
									</div>
									<script>
										$(document).ready(function() {
											$(makeConstrainedRichAgentPicker('editor_agent_name', 'editor_agent_id', 'editor_agent_name_icon', 'editor_agent_view', '#editor_agent_id#','editor'));
										});
									</script>
									<div class="col-12 col-md-6 col-xl-2">
										<label for="publisher" class="data-entry-label">Publisher <span class="small">(!,NULL,NOT NULL)</span></label>
										<input type="text" id="publisher" name="publisher" class="data-entry-input" value="#encodeForHtml(publisher)#" >
									</div>

									<div class="col-12 col-md-6 col-xl-2">
										<label for="is_peer_reviewed_fg" class="data-entry-label">Peer Reviewed</label>
										<select name="is_peer_reviewed_fg" id="is_peer_reviewed_fg" size="1" class="data-entry-select">
											<option value=""></option>
											<!--- Note, only including No option, as flag field has not null constraint, but is very seldom set, so may be missleading if yes is selected --->
											<cfif is_peer_reviewed_fg EQ 0 ><cfset selected="selected"><cfelse><cfset selected=""></cfif>
											<option value="0" #selected#>No</option>
										</select>
									</div>

								</div>
								<div class="form-row">
									<div class="col-12 col-md-6 col-xl-4">
										<div class="form-group mb-2">
											<input type="hidden" id="collection_object_id" name="cited_collection_object_id" value="#encodeForHtml(collection_object_id)#">
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
											<label for="related_cataloged_item" class="data-entry-label mb-0" id="related_cataloged_item_label">Cited Cataloged Item 
												<span class="small">
													(NULL, NOT NULL, accepts comma separated list)
												</span>
											</label>
											<input type="text" name="related_cataloged_item" 
												class="data-entry-input" value="#encodeForHtml(related_cataloged_item)#" id="related_cataloged_item" placeholder="MCZ:Coll:nnnnn"
												onchange="$('##collection_object_id').val('');">
										</div>
									</div>
									<div class="col-12 col-md-6 col-xl-2">
										<label for="cites_specimens" class="data-entry-label">Cites Specimens</label>
										<select name="cites_specimens" id="cites_specimens" size="1" class="data-entry-select">
											<option value=""></option>
											<cfif cites_specimens EQ "true"><cfset selected=" selected "><cfelse><cfset selected=""></cfif>
											<option value="true"#selected#>Yes</option>
											<cfif cites_specimens EQ "false"><cfset selected=" selected "><cfelse><cfset selected=""></cfif>
											<option value="false"#selected#>No</option>
										</select>
									</div>
									<div class="col-12 col-md-6 col-xl-2">
										<cfquery name="ctcollection" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
											select collection, collection_cde, collection_id from collection order by collection
										</cfquery>
										<label for="cites_collection" class="data-entry-label">Cites Collection</label>
										<select name="cites_collection" id="cites_collection" size="1" class="data-entry-select">
											<option value=""></option>
											<option value="NOT NULL">any collection</option>
											<cfloop query="ctcollection">
												<cfif ctcollection.collection_cde eq cites_collection >
													<cfset selected="selected">
												<cfelse>
													<cfset selected="">
												</cfif>
												<option value="#ctcollection.collection_cde#" #selected#>#ctcollection.collection#</option>
											</cfloop>
										</select>
									</div>
									<div class="col-12 col-md-6 col-xl-2">
										<label for="cited_taxon" class="data-entry-label">Cited Scientific Name</label>
										<input type="text" id="cited_taxon" name="cited_taxon" class="data-entry-input" value="#encodeForHtml(cited_taxon)#" >
										<script>
											$(document).ready(function() {
												makeScientificNameAutocomplete("cited_taxon","false","cited");
											});
										</script>
									</div>
									<div class="col-12 col-md-6 col-xl-2">
										<label for="accepted_for_cited_taxon" class="data-entry-label">Current Scientific Name</label>
										<input type="text" id="accepted_for_cited_taxon" name="accepted_for_cited_taxon" class="data-entry-input" value="#encodeForHtml(accepted_for_cited_taxon)#" >
										<script>
											$(document).ready(function() {
												makeScientificNameAutocomplete("accepted_for_cited_taxon","false","");
											});
										</script>
									</div>


									<div class="col-12 pt-0">
										<button class="btn-xs btn-primary px-2 my-2 mr-1" id="searchButton" type="submit" aria-label="Search for publications">Search<span class="fa fa-search pl-1"></span></button>
										<button type="reset" class="btn-xs btn-warning my-2 mr-1" aria-label="Reset search form to inital values" onclick="">Reset</button>
										<button type="button" class="btn-xs btn-warning my-2 mr-1" aria-label="Start a new publications search with a clear form" onclick="window.location.href='#Application.serverRootUrl#/Publications.cfm';" >New Search</button>
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
				return '<span style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; "><a target="_blank" href="/publications/showPublication.cfm/?publication_id=' + rowData['publication_id'] + '">'+value+'</a></span>';
			};
			var citationCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
				var rowData = jQuery("##searchResultsGrid").jqxGrid('getrowdata',row);
				var id = rowData['publication_id'];
				var cite = rowData['short_citation'];
				return '<span style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; "><a target="_blank" href="/publications/showPublication.cfm/?publication_id=' + id + '">'+cite+'</a></span>';
			};
			var editCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
				var rowData = jQuery("##searchResultsGrid").jqxGrid('getrowdata',row);
				return '<span style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; "><a target="_blank" class="ml-1 px-2 btn btn-xs btn-outline-primary" href="/Publication.cfm/?publication_id=' + rowData['publication_id'] + '">Edit</a></span>';
			};
			var doiCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
				var rowData = jQuery("##searchResultsGrid").jqxGrid('getrowdata',row);
				var doi = rowData['doi'];
				if (doi != "") { 
					return '<span style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; "><a target="_blank" href="https://doi.org/' + doi + '">'+doi+'</a></span>';
				} else { 
					return '<span class="ml-1" style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; "></span>';
				}
			};
			var countCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
				var rowData = jQuery("##searchResultsGrid").jqxGrid('getrowdata',row);
				var ct = rowData['cited_specimen_count'];
				var id = rowData['publication_id'];
				var short_citation = encodeURIComponent(rowData['short_citation']);
				if (ct != "" && ct != "0") { 
					target = "/Specimens.cfm?execute=true&builderMaxRows=1&action=builderSearch&nestdepth1=1&field1=CITATION%3ACITATIONS_PUBLICATION_ID&searchText1="+short_citation+"&searchId1="+id;
					return '<span style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; "><a target="_blank" href="' + target + '">'+ct+'</a></span>';
				} else { 
					return '<span class="ml-1" style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; ">'+ct+'</span>';
				}
			};
			var manageCitationsCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
				var rowData = jQuery("##searchResultsGrid").jqxGrid('getrowdata',row);
				var publication_id = rowData['publication_id'];
				return '<a class="ml-1 mt-2 px-2 btn btn-xs btn-outline-primary" target="_blank" href="/Citation.cfm?publication_id='+publication_id+'">Manage</a>';
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
							{ name: 'short_citation', type: 'string' },
							{ name: 'publication_type', type: 'string' },
							{ name: 'published_year', type: 'string' },
							{ name: 'publisher', type: 'string' },
							{ name: 'publication_title', type: 'string' },
							{ name: 'publication_remarks', type: 'string' },
							{ name: 'formatted_publication', type: 'string' },
							{ name: 'authors', type: 'string' },
							{ name: 'editors', type: 'string' },
							{ name: 'doi', type: 'string' },
							{ name: 'cited_specimen_count', type: 'string' },
							{ name: 'journal_name', type: 'string' }
						],
						updaterow: function (rowid, rowdata, commit) {
							commit(true);
						},
						root: 'publicationsRecord',
						id: 'publication_id',
						url: '/publications/component/search.cfc?' + $('##searchForm').serialize(),
						timeout: 60000,  // units not specified, miliseconds? 
						loadError: function(jqXHR, textStatus, error) { 
							$("##overlay").hide();
							handleFail(jqXHR,textStatus,error,"running publications search");
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
						columns: [
							<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_publications")>
								{text: 'Publication', datafield: 'short_citation', width:150, hideable: false, cellsrenderer: citationCellRenderer },
								{text: 'ID', datafield: 'publication_id', width:60, hideable: false, cellsrenderer: editCellRenderer},
								{text: 'Citations', datafield: 'Citations', width:80, hideable: false, editable: false, cellsrenderer: manageCitationsCellRenderer, exportable: false },
							<cfelse>
								{text: 'Publication', datafield: 'short_citation', width:150, hideable: false, cellsrenderer: citationCellRenderer },
								{text: 'ID', datafield: 'publication_id', width:100, hideable: true, hidden: getColHidProp('publication_id', true), cellsrenderer: linkIdCellRenderer},
							</cfif>
							{text: 'Specimens Cited', datafield: 'cited_specimen_count', width:80, hideable: true, hidden: getColHidProp('authors', false), cellsrenderer: countCellRenderer },
							{text: 'Authors', datafield: 'authors', width:150, hideable: true, hidden: getColHidProp('authors', false) },
							{text: 'Editors', datafield: 'editors', width:100, hideable: true, hidden: getColHidProp('editors', true) },
							{text: 'Year', datafield: 'published_year', width:65, hideable: true, hidden: getColHidProp('published_year', false) },
							{text: 'Title', datafield: 'publication_title', width:300, hideable: true, hidden: getColHidProp('publication_title', true) },
							{text: 'Type', datafield: 'publication_type', width:120, hideable: true, hidden: getColHidProp('publication_type', false) },
							{text: 'Journal', datafield: 'journal_name', width:100, hideable: true, hidden: getColHidProp('journal_name', true) },
							{text: 'Publisher', datafield: 'publisher', width:100, hideable: true, hidden: getColHidProp('publisher', true) },
							{text: 'DOI', datafield: 'doi', width:100, hideable: true, hidden: getColHidProp('doi', false), cellsrenderer: doiCellRenderer },
							{text: 'Remarks', datafield: 'publication_remarks', width:150, hidable: true, hidden: getColHidProp('publication_remarks', true) },
							{text: 'Citation', datafield: 'formatted_publication', hidable: true, hidden: getColHidProp('formatted_publication', false) }
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
						$('##resultLink').html('<a href="/Publications.cfm?execute=true&' + $('##searchForm :input').filter(function(index,element){return $(element).val()!='';}).serialize() + '">Link to this search</a>');
						gridLoaded('searchResultsGrid','publication record');
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
				var uri = "/Publications.cfm?execute=true&" + $('##searchForm :input').filter(function(index,element){ return $(element).val()!='';}).not(".excludeFromLink").serialize();
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
				var filename = searchType.replace(/[ ]/g,'_') + '_results_' + nowstring + '.csv';
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
				var columnslength = columns.length
				<!--- leave off columns where hidable = false --->
				<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_publications")>
					columnslength = columnslength - 3;
				<cfelse>
					columnslength = columnslength - 1;
				</cfif>
				var halfcolumns = Math.round(columnslength/2);
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
				for (i = halfcolumns; i < columnslength; i++) {
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
				$('##resultDownloadButtonContainer').html('<button id="loancsvbutton" class="btn btn-xs btn-secondary mx-1 my-2" aria-label="Export results to csv" onclick=" exportGridToCSV(\'searchResultsGrid\', \''+filename+'\'); " >Export to CSV</button>');
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
