<cfset pageTitle = "Search Specimens">
<!--
TaxonomySearch.cfm

Copyright 2019 President and Fellows of Harvard College

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
	select nomenclatural_code from ctnomenclatural_code order by nomenclatural_code
</cfquery>
<cfquery name="cttaxon_status" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select taxon_status from cttaxon_status order by taxon_status
</cfquery>
<script type="text/javascript" language="javascript">
	jQuery(document).ready(function() {
		jQuery("#phylclass").autocomplete("/ajax/phylclass.cfm", {
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
		jQuery("#kingdom").autocomplete("/ajax/kingdom.cfm", {
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
		jQuery("#phylum").autocomplete("/ajax/phylum.cfm", {
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
		jQuery("#phylorder").autocomplete("/ajax/phylorder.cfm", {
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
		jQuery("#family").autocomplete("/ajax/family.cfm", {
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

<cfoutput>
	
	<div id="overlaycontainer" style="position: relative;">
	<!--- Search form --->
	<div id="search-form-div" class="search-form-div pb-3 px-3">
		<div class="container-fluid">
			<div class="row">
				<div class="col-md-12 col-sm-12 col-lg-11">
					<h1 class="h3 smallcaps my-1 pl-1">Search Taxonomy <span class="count font-italic color-green mx-0"><small>(#getCount.cnt# records)</small></span></h1>
					<div class="tab-card-main mt-1 pb-2 tab-card"> 
						<!--- Tab header div --->
						<div class="card-header tab-card-header pb-0 w-100">
							<ul class="nav nav-tabs card-header-tabs pt-1" id="tabHeaders" role="tablist">
								<li class="nav-item col-sm-12 col-md-2 px-1"> <a class="nav-link " id="all-tab" data-toggle="tab" href="##one" role="tab" aria-controls="All Transactions" aria-selected="true" >Taxonomy</a> <i class="fas fas-info fa-info-circle" onClick="getMCZDocs('Loan_Transactions')" aria-label="help link"></i></li>
							</ul>
						</div>
						<!--- End tab header div ---> 
								
											
						<!--- Tab content div --->
						<div class="tab-content pb-0" id="myTabContent">
							<!---Keyword Search--->
							<div class="tab-pane fade show active py-3 mb-1" id="one" role="tabpanel" aria-label="tab 1">
							
								<div class="row mx-2">
									<div class="col-12 col-md-3">
										<h2 class="h3 card-title px-0 mx-1 mb-0" aria-activedescendant="all-tab">Search Taxonomy</h2>
										<p class="smaller-text">Search the taxonomy used in MCZbase for:	common names, synonymies, taxa used for current identifications, taxa used as authorities for future identifications, taxa used in previous identifications	(especially where specimens were cited by a now-unaccepted name).</p>
										<p class="smaller-text">These #getCount.cnt# records represent current and past taxonomic treatments in MCZbase. They are neither complete nor necessarily authoritative.</p>
										<p class="smaller-text">Not all taxa in MCZbase have associated specimens. <a href="javascript:void(0)" onClick="taxa.we_have_some.checked=false;">Uncheck</a> the "Find only taxa for which specimens exist?" box to see all matches.</p>
										<form ACTION="TaxonomyResults.cfm" METHOD="post" name="taxa">
											<ul class="list-group list-group-flush">
												<li class="list-group-item">
													<input type="radio" name="VALID_CATALOG_TERM_FG" checked="checked" value="">
													<a href="javascript:void(0)" class="smaller-text" onClick="taxa.VALID_CATALOG_TERM_FG[0].checked=true;">Display all matches?</a></li>
												<li  class="list-group-item"> <a href="javascript:void(0)" class="smaller-text" onClick="taxa.VALID_CATALOG_TERM_FG[1].checked=true;">
													<input type="radio" name="VALID_CATALOG_TERM_FG" value="1">
													Display only taxa currently accepted for identification?</a></li>
												<li class="list-group-item">
													<input type="checkbox" name="we_have_some" value="1" id="we_have_some">
													<a href="javascript:void(0)" class="smaller-text" onClick="taxa.we_have_some.checked=true;">Find only taxa for which specimens exist?</a></li>
												<cfif isdefined("session.username") and #session.username# is "gordon">
													<script type="text/javascript" language="javascript">
																		document.getElementById('we_have_some').checked=false;
																	</script>
												</cfif>
												</li>
											</ul>
									</div>
									<div class="col-12 col-md-8">
											<div class="col-12">
												<p class="small text-success">Add equals sign for exact match where (=) is in the label.</p>
											</div>
										<div class="form-row bg-light border px-2 pb-2">
										
										
											<div class="col-md-4">
												<label for="taxonomic_scientific_name" class="data-entry-label">Scientific Name <span class="small text-success" onclick="var e=document.getElementById('scientific_name');e.value='='+e.value;">(=) </span></label>
												<input type="text" class="data-entry-input" id="scientific_name" placeholder="scientific name">
											</div>
											<div class="col-md-2">
												<label for="full_taxon_name" class="data-entry-label">Any Category</label>
												<input type="text" class="data-entry-input" id="full_taxon_name" placeholder="any category">
											</div>
											<div class="col-md-2">
												<label for="author_text" class="data-entry-label">Author Text <span class="small text-success" onclick="var e=document.getElementById('author_text');e.value='='+e.value;"> (=) </span> </label>
												<input type="text" class="data-entry-input" id="author_text" placeholder="author text">
											</div>
											<div class="col-md-2">
												<label for="infraspecific_author" class="data-entry-label">Infraspecific Author <span class="small text-success" onclick="var e=document.getElementById('infraspecific_author');e.value='='+e.value;"> (=) </span></label>
												<input type="text" class="data-entry-input" id="infraspecific_author" placeholder="infraspecific author" aria-label="infraspecific author">
											</div>
												<div class="col-md-2">
												<label for="common_name" class="data-entry-label">Common Name</label>
												<input type="text" class="data-entry-input" id="common_name" placeholder="common name" aria-label="common name">
											</div>
										</div>
										<div class="form-row">
											<div class="form-group col-md-2">
												<label for="genus" class="data-entry-label">Genus <span class="small text-success" onclick="var e=document.getElementById('genus');e.value='='+e.value;"> (=) </span></label>
												<input type="text" class="data-entry-input" id="genus" placeholder="genus">
											</div>
											<div class="form-group col-md-2">
												<label for="species" class="data-entry-label">Species <span class="small text-success" onclick="var e=document.getElementById('species');e.value='='+e.value;"> (=)</span> </label>
												<input type="text" class="data-entry-input" id="species" placeholder="species">
											</div>
											<div class="form-group col-md-2">
												<label for="subspecies" class="data-entry-label">Subspecies <span class="small text-success" onclick="var e=document.getElementById('subspecies');e.value='='+e.value;"> (=) </span></label>
												<input type="text" class="data-entry-input" id="subspecies" placeholder="subspecies">
											</div>
											<div class="form-group col-md-2"> </div>
											<div class="form-group col-md-2"> </div>
										</div>
										<div class="form-row">
											<div class="form-group col-md-2">
												<label for="genus" class="data-entry-label">Kingdom <span class="small text-success" onclick="var e=document.getElementById('kingdom');e.value='='+e.value;">(=) </span></label>
												<input type="text" class="data-entry-input" id="kingdom" placeholder="kingdom">
											</div>
											<div class="form-group col-md-2">
												<label for="phylum" class="data-entry-label">Phylum <span class="small text-success" onclick="var e=document.getElementById('phylum');e.value='='+e.value;"> (=) </span></label>
												<input type="text" class="data-entry-input" id="phylum" placeholder="phylum">
											</div>
											<div class="form-group col-md-2">
												<label for="subphylum" class="data-entry-label">Subphylum</label>
												<input type="small" class="data-entry-input" id="subphylum" placeholder="subphylum">
											</div>
											<div class="form-group col-md-2">
												<label for="superclass" class="data-entry-label">Superclass</label>
												<input type="small" class="data-entry-input" id="superclass" placeholder="superclass">
											</div>
											<div class="form-group col-md-2">
												<label for="phylclass" class="data-entry-label">Class <span class="small text-success" onclick="var e=document.getElementById('phylclass');e.value='='+e.value;"> (=) </span></label>
												<input type="text" class="data-entry-input" id="phylclass" placeholder="phylclass">
											</div>
										</div>
										<div class="form-row">
											<div class="form-group col-md-2">
												<label for="subclass" class="data-entry-label">Subclass <span class="small text-success" onclick="var e=document.getElementById('subclass');e.value='='+e.value;">(=) </span></label>
												<input type="text" class="data-entry-input" id="subclass" placeholder="subclass">
											</div>
											<div class="form-group col-md-2">
												<label for="superorder" class="data-entry-label">Superorder</label>
												<input type="text" class="data-entry-input" id="superorder" placeholder="superorder">
											</div>
											<div class="form-group col-md-2">
												<label for="phylorder" class="data-entry-label">Order <span class="small text-success" onclick="var e=document.getElementById('phylorder');e.value='='+e.value;"> (=) </span></label>
												<input type="text" class="data-entry-input" id="phylorder" placeholder="phylorder">
											</div>
											<div class="form-group col-md-2">
												<label for="suborder" class="data-entry-label">Suborder <span class="small text-success" onclick="var e=document.getElementById('suborder');e.value='='+e.value;"> (=) </span></label>
												<input type="text" class="data-entry-input" id="suborder" placeholder="suborder">
											</div>
											<div class="form-group col-md-2">
												<label for="infraorder" class="data-entry-label">Infraorder <span class="small text-success" onclick="var e=document.getElementById('infraorder');e.value='='+e.value;"> (=) </span></label>
												<input type="text" class="data-entry-input" id="infraorder" placeholder="infraorder">
											</div>
										</div>
										<div class="form-row">
											<div class="form-group col-md-2">
												<label for="superfamily" class="data-entry-label">Superfamily</label>
												<input type="text text-success" class="data-entry-input" id="superfamily" placeholder="superfamily">
											</div>
											<div class="form-group col-md-2">
												<label for="subphylum" class="data-entry-label">Family <span class="small text-success" onclick="var e=document.getElementById('family');e.value='='+e.value;"> (=) </span></label>
												<input type="text" class="data-entry-input" id="family" placeholder="family">
											</div>
											<div class="form-group col-md-2">
												<label for="subfamily" class="data-entry-label">Subfamily <span class="small text-success" onclick="var e=document.getElementById('subfamily');e.value='='+e.value;"> (=) </span></label>
												<input type="text" class="data-entry-input" id="subfamily" placeholder="subfamily">
											</div>
											<div class="form-group col-md-2">
												<label for="tribe" class="data-entry-label">Tribe <span class="small text-success" onclick="var e=document.getElementById('tribe');e.value='='+e.value;"> (=) </span></label>
												<input type="text" class="data-entry-input" id="tribe" placeholder="tribe">
											</div>
											<div class="form-group col-md-2">
												<label for="subgenus" class="data-entry-label">Subgenus <span class="small text-success" onclick="var e=document.getElementById('subgenus');e.value='='+e.value;"> (=) </span></label>
												<input type="text" class="data-entry-input" id="subgenus" placeholder="subgenus">
											</div>
										</div>
										<div class="form-row">
											<div class="form-group col-md-2">
												<label for="nomenclatural_code" class="data-entry-label">Nomenclatural Code</label>
												<select name="nomenclatural_code" class="data-entry-select" id="nomenclatural_code">
													<option></option>
													<cfloop query="ctnomenclatural_code">
														<option value="#nomenclatural_code#">#nomenclatural_code#</option>
													</cfloop>
												</select>
											</div>
											<div class="form-group col-md-4">
												<label for="source_authority" class="data-entry-label">Authority</label>
												<select name="source_authority" id="source_authority" class="data-entry-select" size="1">
													<option></option>
													<cfloop query="CTTAXONOMIC_AUTHORITY">
														<option value="#source_authority#">#source_authority#</option>
													</cfloop>
												</select>
											</div>
											<div class="form-group col-md-2">
												<label for="taxon_status" class="data-entry-label">Taxon Status</label>
												<select name="taxon_status" id="taxon_status" class="data-entry-select" size="1">
													<option></option>
													<cfloop query="cttaxon_status">
														<option value="#taxon_status#">#taxon_status#</option>
													</cfloop>
												</select>
											</div>
										</div>
										<div class=""><p class="small"> Note: This form will not return >1000 records; you may need to narrow your search to return all relevant matches.</p> </div>
										<input type="submit" value="Search" class="schBtn btn btn-primary btn-xs mr-2">
										<input type="reset" value="Clear Form" class="clrBtn btn btn-xs btn-warning">
										<input type="hidden" name="action" value="search">
										</form>
									</div>
								</div>
							</div>
						</div>
					</div>
				</div>
			</div>
		</div>
	</div>
	</div>
</cfoutput>
<cfinclude template = "shared/_footer.cfm">
