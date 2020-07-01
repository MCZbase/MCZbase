<cfset pageTitle = "Search Taxonomy">
<!--
Taxa.cfm

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

-->

<cfinclude template = "/shared/_header.cfm">
<script src="/includes/jquery/jquery-autocomplete/jquery.autocomplete.pack.js" language="javascript" type="text/javascript"></script>
<cfset title = "Search for Taxa">
<cfset metaDesc = "Search MCZbase for taxonomy, including accepted, unaccepted, used, and unused names, higher taxonomy, and common names.">
<cfquery name="getCount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select count(*) as cnt from taxonomy
</cfquery>
<cfquery name="CTTAXONOMIC_AUTHORITY" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select source_authority from CTTAXONOMIC_AUTHORITY order by source_authority
</cfquery>
<cfquery name="ctnomenclatural_code" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select nomenclatural_code from ctnomenclatural_code order by sort_order
</cfquery>
<cfquery name="cttaxon_status" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select taxon_status from cttaxon_status order by taxon_status
</cfquery>
<!--- set default search field values if not passed in --->
<cfif NOT isDefined("scientific_name")><cfset scientific_name=""></cfif>
<cfif NOT isDefined("full_taxon_name")><cfset full_taxon_name=""></cfif>
<cfif NOT isDefined("common_name")><cfset common_name=""></cfif>
<cfif NOT isDefined("kingdom")><cfset kingdom=""></cfif>
<cfif NOT isDefined("phylum")><cfset phylum=""></cfif>
<cfif NOT isDefined("subphylum")><cfset subphylum=""></cfif>
<cfif NOT isDefined("superclass")><cfset superclass=""></cfif>
<cfif NOT isDefined("phylclass")><cfset phylclass=""></cfif>
<cfif NOT isDefined("subclass")><cfset subclass=""></cfif>
<cfif NOT isDefined("superorder")><cfset superorder=""></cfif>
<cfif NOT isDefined("phylorder")><cfset phylorder=""></cfif>
<cfif NOT isDefined("suborder")><cfset suborder=""></cfif>
<cfif NOT isDefined("infraorder")><cfset infraorder=""></cfif>
<cfif NOT isDefined("superfamily")><cfset superfamily=""></cfif>
<cfif NOT isDefined("family")><cfset family=""></cfif>
<cfif NOT isDefined("subfamily")><cfset subfamily=""></cfif>
<cfif NOT isDefined("tribe")><cfset tribe=""></cfif>
<cfif NOT isDefined("genus")><cfset genus=""></cfif>
<cfif NOT isDefined("subgenus")><cfset genus=""></cfif>
<cfif NOT isDefined("species")><cfset species=""></cfif>
<cfif NOT isDefined("subspecies")><cfset subspecies=""></cfif>
<cfif NOT isDefined("author_text")><cfset author_text=""></cfif>
<cfif NOT isDefined("infraspecific_author")><cfset infraspecific_author=""></cfif>

<cfoutput>
	<!--- TODO: Fix backing methods 
	<script type="text/javascript" language="javascript">
		jQuery(document).ready(function() {
			jQuery("##phylclass").autocomplete("/ajax/phylclass.cfm", {
				width: 320,
				max: 50,
				autofill: false,
				multiple: false,
				scroll: true,
				scrollHeight: 300,
				matchContains: true,
				minChars: 1,
				selectFirst:false
			});
			jQuery("##kingdom").autocomplete("/ajax/kingdom.cfm", {
				width: 320,
				max: 50,
				autofill: false,
				multiple: false,
				scroll: true,
				scrollHeight: 300,
				matchContains: true,
				minChars: 1,
				selectFirst:false
			});
			jQuery("##phylum").autocomplete("/ajax/phylum.cfm", {
				width: 320,
				max: 50,
				autofill: false,
				multiple: false,
				scroll: true,
				scrollHeight: 300,
				matchContains: true,
				minChars: 1,
				selectFirst:false
			});
			jQuery("##phylorder").autocomplete("/ajax/phylorder.cfm", {
				width: 320,
				max: 50,
				autofill: false,
				multiple: false,
				scroll: true,
				scrollHeight: 300,
				matchContains: true,
				minChars: 1,
				selectFirst:false
			});
			jQuery("##family").autocomplete("/ajax/family.cfm", {
				width: 320,
				max: 50,
				autofill: false,
				multiple: false,
				scroll: true,
				scrollHeight: 300,
				matchContains: true,
				minChars: 1,
				selectFirst:false
			});
		});
	</script>
	--->
	
	<div id="overlaycontainer" style="position: relative;">
		<!--- Search form --->
		<div id="search-form-div" class="search-form-div pb-3 px-3">
			<div class="container-fluid">
				<div class="row mb-3">
					<div class="col-12 col-xl-11">
						<h1 class="h3 smallcaps my-1 pl-1">Search Taxonomy <span class="count font-italic color-green mx-0"><small>(#getCount.cnt# records)</small></span></h1>
						<div class="tab-card-main mt-1 pb-2 tab-card"> 
							<!--- TODO: Why is taxonomy in a tab, this page doesn't have multiple tabs???? --->
							<!--- Tab header div --->
							<div class="card-header tab-card-header pb-0 w-100">
								<ul class="nav nav-tabs card-header-tabs pt-1" id="tabHeaders" role="tablist">
									<li class="nav-item col-sm-12 col-md-2 px-1"> <a class="nav-link active px-2" id="all-tab" data-toggle="tab" href="##one" role="tab" aria-controls="All Taxonomy" aria-selected="true">Taxonomy</a> <i class="fas fas-info fa-info-circle" onClick="getMCZDocs('Taxonomy Search')" aria-label="help link"></i></li>
								</ul>
							</div>
							<!--- End tab header div ---> 
												
							<!--- Tab content div --->
							<div class="tab-content pb-0" id="myTabContent">
								<!---Keyword Search--->
								<div class="tab-pane fade show active py-3 mb-1" id="one" role="tabpanel" aria-label="tab 1">
									<form name="searchForm" id="searchForm">
										<div class="row mx-2">
											<input type="hidden" name="method" value="getTaxa" class="keeponclear">
											<div class="col-12 col-xl-4">
												<h2 class="h3 card-title px-0 mx-0 mb-0">Search All Taxonomy</h2>
												<p class="smaller-text">Search the taxonomy used in MCZbase for:	common names, synonymies, taxa used for current identifications, taxa used as authorities for future identifications, taxa used in previous identifications	(especially where specimens were cited by a now-unaccepted name).</p>
												<p class="smaller-text">These #getCount.cnt# records represent current and past taxonomic treatments in MCZbase. They are neither complete nor necessarily authoritative.</p>
												<p class="smaller-text">Not all taxa in MCZbase have associated specimens. <a href="javascript:void(0)" onClick="taxa.we_have_some.checked=false;" aria-label="Find only taxa for which specimens exist?">Uncheck</a> the "Find only taxa for which specimens exist?" box to see all matches.</p>
												<input type="hidden" name="action" value="search">
												<ul class="list-group list-group-flush pb-3">
													<li class="list-group-item pb-0">
														<input type="radio" name="VALID_CATALOG_TERM_FG" checked="checked" value="">
														<a href="javascript:void(0)" class="smaller-text" onClick="taxa.VALID_CATALOG_TERM_FG[0].checked=true;">Display all matches?</a></li>
													<li class="list-group-item pb-0"> <a href="javascript:void(0)" class="smaller-text" onClick="taxa.VALID_CATALOG_TERM_FG[1].checked=true;">
														<input type="radio" name="VALID_CATALOG_TERM_FG" value="1">
														Display only taxa currently accepted for identification?</a></li>
													<li class="list-group-item pb-0">
														<input type="checkbox" name="we_have_some" value="1" id="we_have_some">
														<a href="javascript:void(0)" class="smaller-text" onClick="taxa.we_have_some.checked=true;">Find only taxa for which specimens exist?</a></li>
														<cfif isdefined("session.username") and #session.username# is "#session.dbuser#">
															<script type="text/javascript" language="javascript">
																document.getElementById('we_have_some').checked=false;
															</script>
														</cfif>
													</li>
												</ul>
											</div>
											<div class="col-12 col-xl-8">
												<div class="col-12">
													<p class="small text-success" aria-label="input info">Add equals sign for exact match.</p>
												</div>
												<div class="form-row bg-light border rounded px-2 pb-2">
													<div class="col-md-4">
														<label for="taxonomic_scientific_name" class="data-entry-label align-left-center">Scientific Name <span class="small text-success" onclick="var e=document.getElementById('scientific_name');e.value='='+e.value;" aria-label="Add equals sign for exact match.">(=) </span></label>
														<input type="text" class="data-entry-input" name="scientific_name" id="scientific_name" placeholder="scientific name" value="#scientific_name#">
													</div>
													<div class="col-md-4">
														<label for="full_taxon_name" class="data-entry-label align-left-center">Any part of name or classification</label>
														<input type="text" class="data-entry-input" id="full_taxon_name" name="full_taxon_name" placeholder="name at any rank" value="#full_taxon_name#">
													</div>
													<div class="col-md-4">
														<label for="common_name" class="data-entry-label align-left-center">Common Name <span class="small text-success" onclick="var e=document.getElementById('common_name');e.value='='+e.value;" aria-label="Add equals sign for exact match">(=) </span></label>
														<input type="text" class="data-entry-input" id="common_name" name="common_name" value="#common_name#" placeholder="common name" aria-label="common name">
													</div>
												</div>
												<div class="form-row mt-2">
													<div class="form-group col-md-2">
														<label for="genus" class="data-entry-label align-left-center">Genus <span class="small text-success" onclick="var e=document.getElementById('genus');e.value='='+e.value;"> (=) </span></label>
														<input type="text" class="data-entry-input" id="genus" name="genus" value="#genus#" placeholder="generic name">
													</div>
													<div class="form-group col-md-2">
														<label for="species" class="data-entry-label align-left-center">Species <span class="small text-success" onclick="var e=document.getElementById('species');e.value='='+e.value;"> (=)</span> </label>
														<input type="text" class="data-entry-input" id="species" name="species" value="#species#" placeholder="specific name">
													</div>
													<div class="form-group col-md-2">
														<label for="subspecies" class="data-entry-label align-left-center">Subspecies <span class="small text-success" onclick="var e=document.getElementById('subspecies');e.value='='+e.value;"> (=) </span></label>
														<input type="text" class="data-entry-input" id="subspecies" name="subspecies" value="#subspecies#" placeholder="subspecific name">
													</div>
													<div class="col-md-2">
														<label for="author_text" class="data-entry-label align-left-center">Authorship <span class="small text-success" onclick="var e=document.getElementById('author_text');e.value='='+e.value;"> (=) </span> </label>
														<input type="text" class="data-entry-input" id="author_text" name="author_text" value="#author_text#" placeholder="author text">
													</div>
													<div class="form-group col-md-2"> </div>
												</div>
												<div class="form-row mb-1">
													<div class="col-md-2">
														<label for="kingdom" class="data-entry-label align-left-center">Kingdom <span class="small text-success" onclick="var e=document.getElementById('kingdom');e.value='='+e.value;">(=) </span></label>
														<input type="text" class="data-entry-input" id="kingdom" name="kingdom" value="#kingdom#" placeholder="kingdom">
													</div>
													<div class="col-md-2">
														<label for="phylum" class="data-entry-label align-left-center">Phylum <span class="small text-success" onclick="var e=document.getElementById('phylum');e.value='='+e.value;"> (=) </span></label>
														<input type="text" class="data-entry-input" id="phylum" name="phylum" value="#phylum#" placeholder="phylum">
													</div>
													<div class="col-md-2">
														<label for="subphylum" class="data-entry-label align-left-center">Subphylum <span class="small text-success" onclick="var e=document.getElementById('subphylum');e.value='='+e.value;" aria-label="Add equals sign for exact match">(=) </span></label>
														<input type="small" class="data-entry-input" id="subphylum" name="subphylum" value="#subphylum#" placeholder="subphylum">
													</div>
													<div class="col-md-2">
														<label for="superclass" class="data-entry-label align-left-center">Superclass <span class="small text-success" onclick="var e=document.getElementById('superclass');e.value='='+e.value;" aria-label="Add equals sign for exact match">(=) </span></label>
														<input type="small" class="data-entry-input" id="superclass" name="superclass" value="#superclass#" placeholder="superclass">
													</div>
													<div class="col-md-2">
														<label for="phylclass" class="data-entry-label align-left-center">Class <span class="small text-success" onclick="var e=document.getElementById('phylclass');e.value='='+e.value;"> (=) </span></label>
														<input type="text" class="data-entry-input" id="phylclass" name="phylclass" value="#phylclass#" placeholder="phylclass">
													</div>
													<div class="col-md-2">
														<label for="subclass" class="data-entry-label align-left-center">Subclass <span class="small text-success" onclick="var e=document.getElementById('subclass');e.value='='+e.value;">(=) </span></label>
														<input type="text" class="data-entry-input" id="subclass" name="subclass" value="#subclass#" placeholder="subclass">
													</div>
												</div>
												<div class="form-row mb-1">
											
													<div class="col-md-2">
														<label for="superorder" class="data-entry-label">Superorder <span class="small text-success" onclick="var e=document.getElementById('superorder');e.value='='+e.value;" aria-label="Add equals sign for exact match">(=) </span></label>
														<input type="text" class="data-entry-input align-left-center" id="superorder" name="superorder" value="#superorder#" placeholder="superorder">
													</div>
													<div class="col-md-2">
														<label for="phylorder" class="data-entry-label align-left-center">Order <span class="small text-success" onclick="var e=document.getElementById('phylorder');e.value='='+e.value;"> (=) </span></label>
														<input type="text" class="data-entry-input" id="phylorder" name="phylorder" value="#phylorder#" placeholder="phylorder">
													</div>
													<div class="col-md-2">
														<label for="suborder" class="data-entry-label align-left-center">Suborder <span class="small text-success" onclick="var e=document.getElementById('suborder');e.value='='+e.value;"> (=) </span></label>
														<input type="text" class="data-entry-input" id="suborder" name="suborder" value="#suborder#" placeholder="suborder">
													</div>
													<div class="col-md-2">
														<label for="infraorder" class="data-entry-label align-left-center">Infraorder <span class="small text-success" onclick="var e=document.getElementById('infraorder');e.value='='+e.value;" aria-label="Add equals sign for exact match">(=) </span></label>
														<input type="text" class="data-entry-input" id="infraorder" name="infraorder" value="#infraorder#" placeholder="infraorder">
													</div>
												</div>
												<div class="form-row mb-1">
													<div class="col-md-2">
														<label for="superfamily" class="data-entry-label align-left-center">Superfamily <span class="small text-success" onclick="var e=document.getElementById('superfamily');e.value='='+e.value;" aria-label="Add equals sign for exact match">(=) </span></label>
														<input type="text text-success" class="data-entry-input" id="superfamily" name="superfamily" value="#superfamily#" placeholder="superfamily">
													</div>
													<div class="col-md-2">
														<label for="subphylum" class="data-entry-label align-left-center">Family <span class="small text-success" onclick="var e=document.getElementById('family');e.value='='+e.value;"> (=) </span></label>
														<input type="text" class="data-entry-input" id="family" name="family" value="#family#" placeholder="family">
													</div>
													<div class="col-md-2">
														<label for="subfamily" class="data-entry-label align-left-center">Subfamily <span class="small text-success" onclick="var e=document.getElementById('subfamily');e.value='='+e.value;"> (=) </span></label>
														<input type="text" class="data-entry-input" id="subfamily" name="subfamily" value="#subfamily#" placeholder="subfamily">
													</div>
													<div class="col-md-2">
														<label for="tribe" class="data-entry-label align-left-center">Tribe <span class="small text-success" onclick="var e=document.getElementById('tribe');e.value='='+e.value;"> (=) </span></label>
														<input type="text" class="data-entry-input" id="tribe" name="tribe" value="#tribe#" placeholder="tribe">
													</div>
													<div class="col-md-2">
														<label for="subgenus" class="data-entry-label align-left-center">Subgenus <span class="small text-success" onclick="var e=document.getElementById('subgenus');e.value='='+e.value;" aria-label="add equals sign before entry for exact match"> (=) </span></label>
														<input type="text" class="data-entry-input" id="subgenus" name="subgenus" value="#subgenus#" placeholder="subgenus">
													</div>
												</div>
												<div class="form-row mb-2 mt-2">
													<div class="col-md-3">
														<label for="nomenclatural_code" class="data-entry-label align-left-center">Nomenclatural Code</label>
														<select name="nomenclatural_code" class="data-entry-select" id="nomenclatural_code">
															<option></option>
															<cfloop query="ctnomenclatural_code">
																<option value="#nomenclatural_code#">#nomenclatural_code#</option>
															</cfloop>
														</select>
													</div>
													<div class="col-md-3">
														<label for="source_authority" class="data-entry-label align-left-center">Source Authority</label>
														<select name="source_authority" id="source_authority" class="data-entry-select" size="1">
															<option></option>
															<cfloop query="CTTAXONOMIC_AUTHORITY">
																<option value="#source_authority#">#source_authority#</option>
															</cfloop>
														</select>
													</div>
													<div class="col-md-3">
														<label for="taxon_status" class="data-entry-label align-left-center">Taxon Status</label>
														<select name="taxon_status" id="taxon_status" class="data-entry-select" size="1">
															<option></option>
															<cfloop query="cttaxon_status">
																<option value="#taxon_status#">#taxon_status#</option>
															</cfloop>
														</select>
													</div>
													<div class="col-md-3">
														<label for="infraspecific_author" class="data-entry-label align-left-center">Infraspecifc Author<span class="small text-success" onclick="var e=document.getElementById('infraspecific_author');e.value='='+e.value;"> (=) </span></label>
														<input type="text" class="data-entry-input" id="infraspecific_author" name="infraspecific_author" value="#infraspecific_author#" placeholder="infraspecific author" aria-label="infraspecific author for botanical names only">
													</div>
												</div>
												<button type="submit" class="btn btn-xs btn-primary mr-2" id="searchButton" aria-label="Search all taxa">Search<span class="fa fa-search pl-1"></span></button>
												<button type="reset" class="btn btn-xs btn-warning mr-2" aria-label="Reset taxon search form to inital values">Reset</button>
												<button type="button" class="btn btn-xs btn-warning" aria-label="Start a new taxon search with a clear form" onclick="window.location.href='#Application.serverRootUrl#/Taxa.cfm';" >New Search</button>
											</div>
										</div>
									</form>
								</div>
							</div>
						</div>
					</div>
				</div>
			</div>
		</div><!--- end search form div --->

		<!--- Results table as a jqxGrid. --->
		<div class="container-fluid">
			<div class="row">
				<div class="text-left col-md-12">
					<main role="main">
						<div class="pl-2 mb-5"> 
							
							<div class="row mt-1 mb-0 pb-0 jqx-widget-header border px-2">
								<h4>Results: </h4>
								<span class="d-block px-3 p-2" id="resultCount"></span> <span id="resultLink" class="d-block p-2"></span>
								<div id="columnPickDialog">
									<div id="columnPick" class="px-1"></div>
								</div>
								<div id="columnPickDialogButton"></div>
								<div id="resultDownloadButtonContainer"></div>
							</div>
							<div class="row mt-0">
								<!--- Grid Related code is below along with search handlers --->
								<div id="searchResultsGrid" class="jqxGrid" role="table" aria-label="Search Results Table"></div>
								<div id="enableselection"></div>
							</div>
						</div>
					</main>
				</div>
			</div>
		</div>

		<script>
			$(document).ready(function() {
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
							{ name: 'TAXON_NAME_ID', type: 'int' }, 
							{ name: 'FULL_TAXON_NAME', type: 'string' },
							{ name: 'KINGDOM', type: 'string' },
							{ name: 'PHYLUM', type: 'string' },
							{ name: 'SUBPHYLUM', type: 'string' },
							{ name: 'SUPERCLASS', type: 'string' },
							{ name: 'PHYLCLASS', type: 'string' },
							{ name: 'SUBCLASS', type: 'string' },
							{ name: 'SUPERORDER', type: 'string' },
							{ name: 'PHYLORDER', type: 'string' },
							{ name: 'SUBORDER', type: 'string' },
							{ name: 'INFRAORDER', type: 'string' },
							{ name: 'SUPERFAMILY', type: 'string' },
							{ name: 'FAMILY', type: 'string' },
							{ name: 'SUBFAMILY', type: 'string' },
							{ name: 'TRIBE', type: 'string' },
							{ name: 'GENUS', type: 'string' },
							{ name: 'SUBGENUS', type: 'string' },
							{ name: 'SPECIES', type: 'string' },
							{ name: 'SUBSPECIES', type: 'string' },
							{ name: 'INFRASPECIFIC_RANK', type: 'string' },
							{ name: 'SCIENTIFIC_NAME', type: 'string' },
							{ name: 'AUTHOR_TEXT', type: 'string' },
							{ name: 'DISPLAY_NAME', type: 'string' },
							{ name: 'NOMENCLATURAL_CODE', type: 'string' },
							{ name: 'DIVISION', type: 'string' },
							{ name: 'SUBDIVISION', type: 'string' },
							{ name: 'INFRASPECIFIC_AUTHOR', type: 'string' },
							{ name: 'VALID_CATALOG_TERM_FG', type: 'int' },
							{ name: 'SOURCE_AUTHORITY', type: 'string' },
							{ name: 'SCIENTIFICNAMEID', type: 'string' },
							{ name: 'TAXONID', type: 'string' },
							{ name: 'TAXON_STATUS', type: 'string' },
							{ name: 'TAXON_REMARKS', type: 'string' },
							{ name: 'id_link', type: 'string' }
						],
						updaterow: function (rowid, rowdata, commit) {
							commit(true);
						},
						root: 'taxonRecord',
						id: 'taxon_name_id',
						url: '/taxonomy/component/search.cfc?' + $('##searchForm').serialize(),
						timeout: 30000,  // units not specified, miliseconds? 
						loadError: function(jqXHR, status, error) { 
							$("##overlay").hide();
			            var message = "";      
							if (error == 'timeout') { 
			               message = ' Server took too long to respond.';
			            } else { 
			               message = jqXHR.responseText;
			            }
			            messageDialog('Error:' + message ,'Error: ' + error);
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
						source: dataAdapter,
						filterable: true,
						sortable: true,
						pageable: true,
						editable: false,
						pagesize: '50',
						pagesizeoptions: ['50','100'],
						showaggregates: true,
						columnsresize: true,
						autoshowfiltericon: true,
						autoshowcolumnsmenubutton: false,
						autoshowloadelement: false,  // overlay acts as load element for form+results
						columnsreorder: true,
						groupable: true,
						selectionmode: 'none',
						altrows: true,
						showtoolbar: false,
						columns: [
							{ text: 'Link', datafield: 'id_link', width:100, hideable: true, hidden: false },
							{ text: 'Taxon_name_id', datafield: 'TAXON_NAME_ID', width:80, hideable: true, hidden: true }, 
							{ text: 'Full Taxon Name', datafield: 'FULL_TAXON_NAME', width:200, hideable: true, hidden: true },
							{ text: 'Kingdom', datafield: 'KINGDOM', width:100, hideable: true, hidden: true },
							{ text: 'Phylum', datafield: 'PHYLUM', width:100, hideable: true, hidden: false },
							{ text: 'Subphylum', datafield: 'SUBPHYLUM', width:100, hideable: true, hidden: true },
							{ text: 'Superclass', datafield: 'SUPERCLASS', width:100, hideable: true, hidden: true },
							{ text: 'Class', datafield: 'PHYLCLASS', width:100, hideable: true, hidden: false },
							{ text: 'Subclass', datafield: 'SUBCLASS', width:100, hideable: true, hidden: true },
							{ text: 'Superorder', datafield: 'SUPERORDER', width:100, hideable: true, hidden: true },
							{ text: 'Order', datafield: 'PHYLORDER', width:100, hideable: true, hidden: false },
							{ text: 'Suborder', datafield: 'SUBORDER', width:100, hideable: true, hidden: true },
							{ text: 'Infraorder', datafield: 'INFRAORDER', width:100, hideable: true, hidden: true },
							{ text: 'Superfamily', datafield: 'SUPERFAMILY', width:100, hideable: true, hidden: true },
							{ text: 'Family', datafield: 'FAMILY', width:100, hideable: true, hidden: false },
							{ text: 'Subfamily', datafield: 'SUBFAMILY', width:100, hideable: true, hidden: true },
							{ text: 'Tribe', datafield: 'TRIBE', width:100, hideable: true, hidden: true },
							{ text: 'Genus', datafield: 'GENUS', width:100, hideable: true, hidden: true },
							{ text: 'Subgenus', datafield: 'SUBGENUS', width:100, hideable: true, hidden: true },
							{ text: 'Species', datafield: 'SPECIES', width:100, hideable: true, hidden: true },
							{ text: 'Subsepecies', datafield: 'SUBSPECIES', width:100, hideable: true, hidden: true },
							{ text: 'Infraspecific Rank', datafield: 'INFRASPECIFIC_RANK', width:100, hideable: true, hidden: true },
							{ text: 'Scientific Name', datafield: 'SCIENTIFIC_NAME', width:150, hideable: true, hidden: false },
							{ text: 'Authorship', datafield: 'AUTHOR_TEXT', width:100, hideable: true, hidden: false },
							{ text: 'Display Name', datafield: 'DISPLAY_NAME', width:100, hideable: true, hidden: true },
							{ text: 'Code', datafield: 'NOMENCLATURAL_CODE', width:100, hideable: true, hidden: true },
							{ text: 'Division', datafield: 'DIVISION', width:100, hideable: true, hidden: true },
							{ text: 'Subdivision', datafield: 'SUBDIVISION', width:100, hideable: true, hidden: true },
							{ text: 'Infraspecific Author', datafield: 'INFRASPECIFIC_AUTHOR', width:100, hideable: true, hidden: true },
							{ text: 'Valid for Catalog', datafield: 'VALID_CATALOG_TERM_FG', width:80, hideable: true, hidden: true },
							{ text: 'Source Authority', datafield: 'SOURCE_AUTHORITY', width:100, hideable: true, hidden: true },
							{ text: 'dwc:scientificNameID', datafield: 'SCIENTIFICNAMEID', width:100, hideable: true, hidden: true },
							{ text: 'dwc:taxonID', datafield: 'TAXONID', width:100, hideable: true, hidden: true },
							{ text: 'Status', datafield: 'TAXON_STATUS', width:100, hideable: true, hidden: false },
							{ text: 'Remarks', datafield: 'TAXON_REMARKS', width:200, hideable: true, hidden: true }
						],
						rowdetails: true,
						rowdetailstemplate: {
							rowdetails: "<div style='margin: 10px;'>Row Details</div>",
							rowdetailsheight:  1 // row details will be placed in popup dialog
						},
						initrowdetails: initRowDetails
					});
					$("##searchResultsGrid").on("bindingcomplete", function(event) {
						// add a link out to this search, serializing the form as http get parameters
						$('##resultLink').html('<a href="/Taxa.cfm?action=findAll&execute=true&' + $('##searchForm').serialize() + '">Link to this search</a>');
						gridLoaded('searchResultsGrid','collecting event number');
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
				/* End Setup jqxgrid for number series Search ******************************/

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
				   $('##' + gridId).jqxGrid({ pagesizeoptions: ['50', '100', rowcount]});
				} else if (rowcount > 50) { 
				   $('##' + gridId).jqxGrid({ pagesizeoptions: ['50', rowcount]});
				} else { 
				   $('##' + gridId).jqxGrid({ pageable: false });
				}
				// add a control to show/hide columns
				var columns = $('##' + gridId).jqxGrid('columns').records;
				var columnListSource = [];
				for (i = 0; i < columns.length; i++) {
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
				$("##columnPickDialog").dialog({ 
					height: 'auto', 
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
					"<button id='columnPickDialogOpener' onclick=\" $('##columnPickDialog').dialog('open'); \" class='btn btn-secondary px-3 py-1 my-1 mx-3' >Show/Hide Columns</button>"
				);
				// workaround for menu z-index being below grid cell z-index when grid is created by a loan search.
				// likewise for the popup menu for searching/filtering columns, ends up below the grid cells.
				var maxZIndex = getMaxZIndex();
				$('.jqx-grid-cell').css({'z-index': maxZIndex + 1});
				$('.jqx-grid-group-cell').css({'z-index': maxZIndex + 1});
				$('.jqx-menu-wrapper').css({'z-index': maxZIndex + 2});
				$('##resultDownloadButtonContainer').html('<button id="loancsvbutton" class="btn btn-secondary px-3 py-1 my-1 mx-0" aria-label="Export results to csv" onclick=" exportGridToCSV(\'searchResultsGrid\', \''+filename+'\'); " >Export to CSV</button>');
			}
		</script>

	</div>
</cfoutput>
<cfinclude template = "shared/_footer.cfm">
