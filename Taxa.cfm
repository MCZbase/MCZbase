<cfset pageTitle = "Search Taxonomy">
<!--
Taxa.cfm

Copyright 2020-2022 President and Fellows of Harvard College

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

<cfset addedMetaDescription = "Search MCZbase for taxonomic name records, including accepted, unaccepted, used, and unused names, higher taxonomy, and common names.">
<cfinclude template = "/shared/_header.cfm">

<cfset defaultSelectionMode = "none">
<cfif defaultSelectionMode EQ "none">
	<cfset defaultenablebrowserselection = "true">
<cfelse>
	<cfset defaultenablebrowserselection = "false">
</cfif>	

<cfquery name="getCount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" timeout="#Application.short_timeout#">
	select count(*) as cnt from taxonomy
</cfquery>
<cfquery name="CTTAXONOMIC_AUTHORITY" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" timeout="#Application.short_timeout#">
	select source_authority from CTTAXONOMIC_AUTHORITY order by source_authority
</cfquery>
<cfquery name="ctnomenclatural_code" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" timeout="#Application.short_timeout#">
	select nomenclatural_code from ctnomenclatural_code order by sort_order
</cfquery>
<cfquery name="cttaxon_status" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" timeout="#Application.short_timeout#">
	select taxon_status from cttaxon_status order by taxon_status
</cfquery>
<cfquery name="cttaxon_relation" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" timeout="#Application.short_timeout#">
	select cttaxon_relation.taxon_relationship, count(taxon_relations.taxon_name_id) ct
	from cttaxon_relation
		left join taxon_relations on cttaxon_relation.taxon_relationship = taxon_relations.taxon_relationship 
	group by cttaxon_relation.taxon_relationship
	order by taxon_relationship
</cfquery>
<cfquery name="cttaxon_habitat" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" timeout="#Application.short_timeout#">
	SELECT count(taxon_name_id) ct, taxon_habitat
	FROM taxon_habitat
	GROUP BY taxon_habitat
	ORDER BY taxon_habitat
</cfquery>
<cfquery name="cttaxon_habitat_null" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" timeout="#Application.short_timeout#">
	SELECT count(distinct taxon_name_id) ct, 'NOT NULL' taxon_habitat
	FROM taxon_habitat
	UNION
	SELECT count(distinct taxon_name_id) ct, 'NULL' taxon_habitat
	FROM taxonomy 
	WHERE taxon_name_id not in (select taxon_name_id from taxon_habitat)
</cfquery>
<!--- set default search field values if not passed in --->
<cfif NOT isDefined("valid_catalog_term_fg")><cfset valid_catalog_term_fg=""></cfif>
<cfif NOT isDefined("we_have_some")><cfset we_have_some=""></cfif>
<cfif NOT isDefined("scientific_name")><cfset scientific_name=""></cfif>
<cfif NOT isDefined("full_taxon_name")><cfset full_taxon_name=""></cfif>
<cfif NOT isDefined("common_name")><cfset common_name=""></cfif>
<cfif NOT isDefined("kingdom")><cfset kingdom=""></cfif>
<cfif NOT isDefined("phylum")><cfset phylum=""></cfif>
<cfif NOT isDefined("subphylum")><cfset subphylum=""></cfif>
<cfif NOT isDefined("superclass")><cfset superclass=""></cfif>
<cfif NOT isDefined("phylclass")><cfset phylclass=""></cfif>
<cfif NOT isDefined("subclass")><cfset subclass=""></cfif>
<cfif NOT isDefined("infraclass")><cfset infraclass=""></cfif>
<cfif NOT isDefined("superorder")><cfset superorder=""></cfif>
<cfif NOT isDefined("phylorder")><cfset phylorder=""></cfif>
<cfif NOT isDefined("suborder")><cfset suborder=""></cfif>
<cfif NOT isDefined("infraorder")><cfset infraorder=""></cfif>
<cfif NOT isDefined("superfamily")><cfset superfamily=""></cfif>
<cfif NOT isDefined("family")><cfset family=""></cfif>
<cfif NOT isDefined("subfamily")><cfset subfamily=""></cfif>
<cfif NOT isDefined("tribe")><cfset tribe=""></cfif>
<cfif NOT isDefined("genus")><cfset genus=""></cfif>
<cfif NOT isDefined("subgenus")><cfset subgenus=""></cfif>
<cfif NOT isDefined("species")><cfset species=""></cfif>
<cfif NOT isDefined("subspecies")><cfset subspecies=""></cfif>
<cfif NOT isDefined("author_text")><cfset author_text=""></cfif>
<cfif NOT isDefined("infraspecific_author")><cfset infraspecific_author=""></cfif>
<cfif NOT isDefined("taxon_remarks")><cfset taxon_remarks=""></cfif>
<cfif NOT isDefined("nomenclatural_code")>
	<cfset in_nomenclatural_code="">
<cfelse>
	<cfset in_nomenclatural_code="#nomenclatural_code#">
</cfif>
<cfif NOT isDefined("taxon_habitat")>
	<cfset in_taxon_habitat="">
<cfelse>
	<cfset in_taxon_habitat="#taxon_habitat#">
</cfif>
<cfif NOT isDefined("source_authority")>
	<cfset in_source_authority="">
<cfelse>
	<cfset in_source_authority="#source_authority#">
</cfif>
<cfif NOT isDefined("taxon_status")>
	<cfset in_taxon_status="">
<cfelse>
	<cfset in_taxon_status="#taxon_status#">
</cfif>
<cfif NOT isDefined("relationship")>
	<cfset in_relationship="">
<cfelse>
	<cfset in_relationship="#relationship#">
</cfif>

<cfoutput>
	<script type="text/javascript" language="javascript">
		var handleError = function (jqXHR, status, error) {
			var message = "";
			if (error == 'timeout') {
				message = ' Server took too long to respond.';
			} else {
				message = jqXHR.responseText;
			}
			messageDialog('Error:' + message ,'Error: ' + error);
		};

		jQuery(document).ready(function() {
			makeTaxonSearchAutocomplete('kingdom','kingdom');
			makeTaxonSearchAutocomplete('phylum','phylum');
			makeTaxonSearchAutocomplete('subphylum','subphylum');
			makeTaxonSearchAutocomplete('superclass','superclass');
			makeTaxonSearchAutocomplete('phylclass','class');
			makeTaxonSearchAutocomplete('subclass','subclass');
			makeTaxonSearchAutocomplete('infraclass','infraclass');
			makeTaxonSearchAutocomplete('superorder','superorder');
			makeTaxonSearchAutocomplete('phylorder','order');
			makeTaxonSearchAutocomplete('suborder','suborder');
			makeTaxonSearchAutocomplete('infraorder','infraorder');
			makeTaxonSearchAutocomplete('superfamily','superfamily');
			makeTaxonSearchAutocomplete('family','family');
			makeTaxonSearchAutocomplete('subfamily','subfamily');
			makeTaxonSearchAutocomplete('tribe','tribe');
			makeTaxonSearchAutocomplete('genus','genus');
			makeTaxonSearchAutocomplete('subgenus','subgenus');
			makeTaxonSearchAutocomplete('species','species');
			makeTaxonSearchAutocomplete('subspecies','subspecies');
			makeTaxonSearchAutocomplete('author_text','author_text');
			makeTaxonSearchAutocomplete('infraspecific_author','infraspecific_author');
		});
	</script>
	
	<div id="overlaycontainer" style="position: relative;">
		<!--- Search form --->
		<main id="content">
			<section class="container-fluid" role="search">
				<div class="row mx-0 mb-3">
					<div class="search-box">
						<div class="search-box-header">
							<h1 class="h3 text-white" tabindex="0">Search Taxonomy  <span class="count font-italic text-grayish mx-0"><small>(#getCount.cnt# records)</small></span></h1>
						</div>
						<div class="row px-3 mx-2 pt-2 pb-3">
							<form name="searchForm" id="searchForm" class="row">
								<input type="hidden" name="method" value="getTaxa" class="keeponclear">
								<input type="hidden" name="action" value="search">
								<div class="col-12 col-xl-3">
									<div id="searchHelpTextBlock" class="smaller-text mt-2" tabindex="0">
										Search taxonomies used in MCZbase. 
										<a class="" href="javascript:void(0)" onClick="getMCZDocs('Search Taxonomy')">
											<i class="fa fa-info-circle" aria-label="link to more info icon"></i> 
										</a>  
										<div class="readMore"><input type="checkbox" id="readMore_check_id"><label class="read" for="readMore_check_id"></label><span class="ilt bg-transparent">Names include current identifications, accepted names for future identifications, previous identifications (including now-unaccepted names, invalid names, and nomina nuda found on labels). Taxonomies are neither complete nor authoritative. Not all taxa in MCZbase have associated specimens.</span>
											<span class="sr-only" tabindex="0">Names include current identifications, accepted names for future identifications, previous identifications (including now-unaccepted names, invalid names, and nomina nuda found on labels). Taxonomies are neither complete nor authoritative. Not all taxa in MCZbase have associated specimens.</span>
										</div>
									</div>
									<div class="form-row">
										<fieldset class="col-12 col-md-6 col-lg-6 col-xl-12 mt-3 mt-md-2 mt-lg-3 mb-2">
											<legend class="text-dark mb-2">Search accepted names:</legend>
											<ul class="list-group btn-link list-group-flush mt-1 p-2 border bg-light rounded">
												<cfif valid_catalog_term_fg EQ 1>
													<cfset validFlagAllSelected = ''>
													<cfset validFlagOnlySelected = 'checked="checked"'>
													<cfset validFlagNotSelected = ''>
												<cfelseif valid_catalog_term_fg EQ 0>
													<cfset validFlagAllSelected = ''>
													<cfset validFlagOnlySelected = ''>
													<cfset validFlagNotSelected = 'checked="checked"'>
												<cfelse>
													<cfset validFlagAllSelected = 'checked="checked"'>
													<cfset validFlagOnlySelected = ''>
													<cfset validFlagNotSelected = ''>
												</cfif>
												<li class="list-group-item px-0 pb-0 pt-1">
													<input type="radio" name="valid_catalog_term_fg" id="validFGChecked" #validFlagAllSelected# value="">
													<label for="validFGChecked" class="btn-link smaller-text d-inline">Show all matches.</label>
												</li>
												<li class="list-group-item px-0 pb-0 pt-1">
													<input type="radio" name="valid_catalog_term_fg" id="validFGUnchecked" #validFlagOnlySelected# value="1">
													<label for="validFGUnchecked" class="btn-link smaller-text d-inline">Show only taxa currently accepted for data entry.</label>
												</li>
												<li class="list-group-item px-0 py-1">
													<input type="radio" name="valid_catalog_term_fg" id="validFGNot" #validFlagNotSelected# value="0">
													<label for="validFGNot" class="btn-link smaller-text d-inline">Show only taxa not accepted for data entry.</label>
												</li>
											</ul>
										</fieldset>
										<fieldset class="col-12 col-md-6 col-lg-6 col-xl-12 mt-3 mt-md-2 mt-lg-3 mb-2">
											<legend class="text-dark mb-2" >Search taxa used on specimen records:</legend>
											<ul class="list-group list-group-flush mt-1 p-2 bg-light border rounded">
												<cfif we_have_some EQ 1>
													<cfset usedInIdAllSelected = ''>
													<cfset usedInIdOnlySelected = 'checked="checked"'>
													<cfset usedInIdNotSelected = ''>
												<cfelseif we_have_some EQ 0>
													<cfset usedInIdAllSelected = ''>
													<cfset usedInIdOnlySelected = ''>
													<cfset usedInIdNotSelected = 'checked="checked"'>
												<cfelse>
													<cfset usedInIdAllSelected = 'checked="checked"'>
													<cfset usedInIdOnlySelected = ''>
													<cfset usedInIdNotSelected = ''>
												</cfif>
												<li class="list-group-item px-0 pb-0 pt-1">
													<input type="radio" name="we_have_some" id="wehavesomeAll" #usedInIdAllSelected# value="">
													<label for="wehavesomeAll" class="btn-link smaller-text d-inline">Show all taxa without regard for use.</label>
												</li>
												<li class="list-group-item px-0 pb-0 pt-1">
													<input type="radio" name="we_have_some" id="wehavesomeHave" #usedInIdOnlySelected# value="1">
													<label for="wehavesomeHave" class="btn-link smaller-text d-inline">Show only taxa for which cataloged items exist.</label>
												</li>
												<li class="list-group-item px-0 py-1">
													<input type="radio" name="we_have_some" id="wehavesomeNot" #usedInIdNotSelected# value="0">
													<label for="wehavesomeNot" class="btn-link smaller-text d-inline">Show only taxa not used in identifications.</label>
												</li>
											</ul>
										</fieldset>
									</div>
								</div>
								<div class="col-12 col-xl-9 mt-2">
									<div class="col-12">
										<p class="smaller-text" tabindex="0">Add an = <span class="sr-only">(equals sign)</span> to the beginning of names for exact match, $<span class="sr-only">dolar sign</span> for sounds like match. Add ! <span class="sr-only">(an exclamation point)</span> to the beginning of names for a NOT search. Name fields accept comma separated lists. NULL finds blanks.</p>
									</div>
									<div class="form-row bg-light border rounded p-2 mx-0">
										<div class="col-md-4">
											<label for="scientific_name" class="data-entry-label align-left-center">Scientific Name 
												<span class="small90">
													(<button type="button" tabindex="-1" aria-hidden="true" class="btn-link p-0 border-0 bg-light" onclick="var e=document.getElementById('scientific_name');e.value='='+e.value;" >=<span class="sr-only">prefix with equals sign for exact match search</span></button>,
													<button type="button" tabindex="-1" aria-hidden="true" class="btn-link p-0 border-0 bg-light" onclick="var e=document.getElementById('scientific_name');e.value='~'+e.value;" >~<span class="sr-only">prefix with tilde for search for similar text</span></button>)
												</span>
											</label>
											<input type="text" class="data-entry-input mb-2" name="scientific_name" id="scientific_name" placeholder="scientific name" value="#encodeForHtml(scientific_name)#" aria-labelledby="scientific_name">
										</div>
										<div class="col-md-4">
											<label for="full_taxon_name" class="data-entry-label align-left-center">Any part of name or classification
												<span class="small90">
													(<button type="button" tabindex="-1" aria-hidden="true" class="btn-link p-0 border-0 bg-light" onclick="var e=document.getElementById('full_taxon_name');e.value='!'+e.value;" >!<span class="sr-only">prefix with exclamation point for not search</span></button>)
												</span>
											</label>
											<input type="text" class="data-entry-input mb-2" id="full_taxon_name" name="full_taxon_name" placeholder="name at any rank" value="#encodeForHtml(full_taxon_name)#">
										</div>
										<div class="col-md-4">
											<label for="common_name" class="data-entry-label align-left-center">Common Name 
												<span class="small90">
													(<button type="button" aria-hidden="true" tabindex="-1" class="btn-link p-0 border-0 bg-light" onclick="var e=document.getElementById('common_name');e.value='='+e.value;">=</button>)
												</span>
											</label>
											<input type="text" class="data-entry-input mb-2" id="common_name" name="common_name" value="#encodeForHtml(common_name)#" placeholder="common name">
										</div>
									</div>
									<div class="form-row mt-1">
										<div class="form-group col-md-2">
											<label for="genus" class="data-entry-label align-left-center">Genus 
												<span class="small">
													(<button type="button" tabindex="-1" aria-hidden="true" class="btn-link border-0 p-0 bg-light" onclick="var e=document.getElementById('genus');e.value='='+e.value;">=<span class="sr-only">prefix with equals sign for exact match search</span></button>, 
													<button type="button" tabindex="-1" aria-hidden="true" class="btn-link border-0 p-0 bg-light" onclick="var e=document.getElementById('genus');e.value='$'+e.value;">$<span class="sr-only">prefix with dollarsign for sounds like search</span></button>)
												</span>
											</label>
											<input type="text" class="data-entry-input" id="genus" name="genus" value="#encodeForHtml(genus)#" placeholder="generic name">
										</div>
										<div class="col-md-2">
											<label for="subgenus" class="data-entry-label align-left-center">Subgenus 
												<span class="small">
													(<button type="button" tabindex="-1" aria-hidden="true" class="btn-link border-0 p-0 bg-light" onclick="var e=document.getElementById('subgenus');e.value='='+e.value;">=<span class="sr-only">prefix with equals sign for exact match search</span></button>, 
													<button type="button" tabindex="-1" aria-hidden="true" class="btn-link border-0 p-0 bg-light" onclick="var e=document.getElementById('subgenus');e.value='$'+e.value;">$<span class="sr-only">prefix with dollarsign for sounds like search</span></button>)
												</span>
											</label>
											<input type="text" class="data-entry-input" id="subgenus" name="subgenus" value="#encodeForHtml(subgenus)#" placeholder="subgenus">
										</div>
										<div class="form-group col-md-2">
											<label for="species" class="data-entry-label align-left-center">Species 
												<span class="small">
													(<button type="button" tabindex="-1" aria-hidden="true" class="btn-link border-0 p-0 bg-light" onclick="var e=document.getElementById('species');e.value='='+e.value;">=<span class="sr-only">prefix with equals sign for exact match search</span></button>, 
													<button type="button" tabindex="-1" aria-hidden="true" class="btn-link border-0 p-0 bg-light" onclick="var e=document.getElementById('species');e.value='$'+e.value;">$<span class="sr-only">prefix with dollarsign for sounds like search</span></button>)
												</span>
											</label>
											<input type="text" class="data-entry-input" id="species" name="species" value="#encodeForHtml(species)#" placeholder="specific name">
										</div>
										<div class="form-group col-md-2">
											<label for="subspecies" class="data-entry-label align-left-center">Subspecies 
												<span class="small">
													(<button type="button" tabindex="-1" aria-hidden="true" class="btn-link border-0 p-0 bg-light" onclick="var e=document.getElementById('subspecies');e.value='='+e.value;">=<span class="sr-only">prefix with equals sign for exact match search</span></button>, 
													<button type="button" tabindex="-1" aria-hidden="true" class="btn-link border-0 p-0 bg-light" onclick="var e=document.getElementById('subspecies');e.value='$'+e.value;">$<span class="sr-only">prefix with dollarsign for sounds like search</span></button>)
												</span>
											</label>
											<input type="text" class="data-entry-input" id="subspecies" name="subspecies" value="#encodeForHtml(subspecies)#" placeholder="subspecific name">
										</div>
										<div class="col-md-2">
											<label for="author_text" class="data-entry-label align-left-center">Authorship 
												<span class="small">
													(<button type="button" tabindex="-1" aria-hidden="true" class="btn-link border-0 p-0 bg-light" onclick="var e=document.getElementById('author_text');e.value='='+e.value;">=<span class="sr-only">prefix with equals sign for exact match search</span></button>, 
													<button type="button" tabindex="-1" aria-hidden="true" class="btn-link border-0 p-0 bg-light" onclick="var e=document.getElementById('author_text');e.value='$'+e.value;">$<span class="sr-only">prefix with dollarsign for sounds like search</span></button>)
												</span>
											</label>
											<input type="text" class="data-entry-input" id="author_text" name="author_text" value="#encodeForHtml(author_text)#" placeholder="author text">
										</div>
										<div class="col-md-2">
											<label for="infraspecific_author" class="data-entry-label align-left-center">Infrasp. Author
												<button type="button" aria-hidden="true" tabindex="-1" class="btn-link border-0 small90 p-0 bg-light" onclick="var e=document.getElementById('infraspecific_author');e.value='='+e.value;">(=)</button>
											</label>
											<input type="text" class="data-entry-input" id="infraspecific_author" name="infraspecific_author" value="#encodeForHtml(infraspecific_author)#" placeholder="infraspecific author" aria-label="infraspecific author for botanical names only">
										</div>
									</div>
									<div class="form-row mb-0">
										<div class="col-md-2">
											<label for="kingdom" class="data-entry-label align-left-center">Kingdom 
												<a href="javascript:void(0)" tabindex="-1" aria-hidden="true" class="btn-link" onclick=" $('##kingdom').autocomplete('search','%%%'); return false;" > (&##8595;) <span class="sr-only">open pick list</span></a>
												<button type="button" aria-hidden="true" tabindex="-1" class="btn-link border-0 small90 p-0 bg-light" onclick="var e=document.getElementById('kingdom');e.value='='+e.value;">(=)</button>
											</label>
											<input type="text" class="data-entry-input" id="kingdom" name="kingdom" value="#encodeForHtml(kingdom)#" placeholder="kingdom">
										</div>
										<div class="col-md-2">
											<label for="phylum" class="data-entry-label align-left-center">Phylum 
												<span class="small">
													<a href="javascript:void(0)" tabindex="-1" aria-hidden="true" class="btn-link" onclick=" $('##phylum').autocomplete('search','%%%'); return false;" > (&##8595;) <span class="sr-only">open pick list</span></a>
													(<button type="button" aria-hidden="true" tabindex="-1" class="btn-link border-0 p-0 bg-light" onclick="var e=document.getElementById('phylum');e.value='='+e.value;">=</button>,
													<button type="button" tabindex="-1" aria-hidden="true" class="btn-link border-0 p-0 bg-light" onclick="var e=document.getElementById('phylum');e.value='$'+e.value;">$<span class="sr-only">prefix with dollarsign for sounds like search</span></button>)
												</span>
											</label>
											<input type="text" class="data-entry-input" id="phylum" name="phylum" value="#encodeForHtml(phylum)#" placeholder="phylum">
										</div>
										<div class="col-md-2">
											<label for="subphylum" class="data-entry-label align-left-center">Subphylum 
												<span class="small">
													(<button type="button" aria-hidden="true" tabindex="-1" class="btn-link border-0 p-0 bg-light" onclick="var e=document.getElementById('subphylum');e.value='='+e.value;">=</button>,
													<button type="button" tabindex="-1" aria-hidden="true" class="btn-link border-0 p-0 bg-light" onclick="var e=document.getElementById('subphylum');e.value='$'+e.value;">$<span class="sr-only">prefix with dollarsign for sounds like search</span></button>)
												</span>
											</label>
											<input type="small" class="data-entry-input" id="subphylum" name="subphylum" value="#encodeForHtml(subphylum)#" placeholder="subphylum">
										</div>
										<div class="col-md-2">&nbsp;
										</div>
										<div class="col-md-2">
											<label for="nomenclatural_code" class="data-entry-label align-left-center">Nomenclatural Code</label>
											<select name="nomenclatural_code" class="data-entry-select" id="nomenclatural_code">
												<option></option>
												<cfloop query="ctnomenclatural_code">
													<cfif in_nomenclatural_code EQ nomenclatural_code><cfset selected="selected='true'"><cfelse><cfset selected=""></cfif>
													<option value="#nomenclatural_code#" #selected#>#nomenclatural_code#</option>
												</cfloop>
											</select>
										</div>
										<div class="col-md-2">
											<label for="taxon_habitat" class="data-entry-label align-left-center">Habitat</label>
											<select name="taxon_habitat" class="data-entry-select" id="taxon_habitat">
												<option></option>
												<cfloop query="cttaxon_habitat_null">
													<cfif in_taxon_habitat EQ taxon_habitat><cfset selected="selected='true'"><cfelse><cfset selected=""></cfif>
													<option value="#taxon_habitat#" #selected#>#taxon_habitat# (#ct#)</option>
												</cfloop>
												<cfloop query="cttaxon_habitat">
													<cfif in_taxon_habitat EQ taxon_habitat><cfset selected="selected='true'"><cfelse><cfset selected=""></cfif>
													<option value="#taxon_habitat#" #selected#>#taxon_habitat# (#ct#)</option>
												</cfloop>
											</select>
										</div>
									</div>
									<div class="form-row mb-0">
										<div class="col-md-2">
											<label for="superclass" class="data-entry-label align-left-center">Superclass 
												<span class="small">
													(<button type="button" aria-hidden="true" tabindex="-1" class="btn-link border-0 p-0 bg-light" onclick="var e=document.getElementById('phylum');e.value='='+e.value;">=</button>,
													<button type="button" tabindex="-1" aria-hidden="true" class="btn-link border-0 p-0 bg-light" onclick="var e=document.getElementById('phylum');e.value='$'+e.value;">$<span class="sr-only">prefix with dollarsign for sounds like search</span></button>)
												</span>
											</label>
											<input type="small" class="data-entry-input" id="superclass" name="superclass" value="#encodeForHtml(superclass)#" placeholder="superclass">
										</div>
										<div class="col-md-2">
											<label for="phylclass" class="data-entry-label align-left-center">Class 
												<span class="small">
													(<button type="button" aria-hidden="true" tabindex="-1" class="btn-link border-0 p-0 bg-light" onclick="var e=document.getElementById('phylclass');e.value='='+e.value;">=</button>,
													<button type="button" tabindex="-1" aria-hidden="true" class="btn-link border-0 p-0 bg-light" onclick="var e=document.getElementById('phylclass');e.value='$'+e.value;">$<span class="sr-only">prefix with dollarsign for sounds like search</span></button>)
												</span>
											</label>
											<input type="text" class="data-entry-input" id="phylclass" name="phylclass" value="#encodeForHtml(phylclass)#" placeholder="class">
										</div>
										<div class="col-md-2">
											<label for="subclass" class="data-entry-label align-left-center">Subclass 
												<span class="small">
													(<button type="button" aria-hidden="true" tabindex="-1" class="btn-link border-0 p-0 bg-light" onclick="var e=document.getElementById('subclass');e.value='='+e.value;">=</button>,
													<button type="button" tabindex="-1" aria-hidden="true" class="btn-link border-0 p-0 bg-light" onclick="var e=document.getElementById('subclass');e.value='$'+e.value;">$<span class="sr-only">prefix with dollarsign for sounds like search</span></button>)
												</span>
											</label>
											<input type="text" class="data-entry-input" id="subclass" id="subclass" name="subclass" value="#encodeForHtml(subclass)#" placeholder="subclass">
										</div>
										<div class="col-md-2">
											<label for="infraclass" class="data-entry-label align-left-center">Infraclass 
												<span class="small">
													(<button type="button" aria-hidden="true" tabindex="-1" class="btn-link border-0 p-0 bg-light" onclick="var e=document.getElementById('infraclass');e.value='='+e.value;">=</button>,
													<button type="button" tabindex="-1" aria-hidden="true" class="btn-link border-0 p-0 bg-light" onclick="var e=document.getElementById('infraclass');e.value='$'+e.value;">$<span class="sr-only">prefix with dollarsign for sounds like search</span></button>)
												</span>
											</label>
											<input type="text" class="data-entry-input" id="infraclass" name="infraclass" value="#encodeForHtml(infraclass)#" placeholder="infraclass">
										</div>
										<div class="col-md-4">
											<label for="source_authority" class="data-entry-label align-left-center">Source Authority</label>
											<select name="source_authority" id="source_authority" class="data-entry-select" size="1">
												<option></option>
												<cfloop query="CTTAXONOMIC_AUTHORITY">
													<cfif in_source_authority EQ source_authority><cfset selected="selected='true'"><cfelse><cfset selected=""></cfif>
													<option value="#source_authority#" #selected#>#source_authority#</option>
												</cfloop>
											</select>
										</div>
									</div>
									<div class="form-row mb-0">
										<div class="col-md-2">
											<label for="superorder" class="data-entry-label align-left-center">Superorder 
												<span class="small">
													(<button type="button" aria-hidden="true" tabindex="-1" class="btn-link border-0 p-0 bg-light" onclick="var e=document.getElementById('superorder');e.value='='+e.value;">=</button>,
													<button type="button" tabindex="-1" aria-hidden="true" class="btn-link border-0 p-0 bg-light" onclick="var e=document.getElementById('superorder');e.value='$'+e.value;">$<span class="sr-only">prefix with dollarsign for sounds like search</span></button>)
												</span>
											</label>
											<input type="text" class="data-entry-input" id="superorder" name="superorder" value="#encodeForHtml(superorder)#" placeholder="superorder">
										</div>
										<div class="col-md-2">
											<label for="phylorder" class="data-entry-label align-left-center">Order 
												<span class="small">
													(<button type="button" tabindex="-1" aria-hidden="true" class="btn-link border-0 p-0 bg-light" onclick="var e=document.getElementById('phylorder');e.value='='+e.value;">=<span class="sr-only">prefix with equals sign for exact match search</span></button>, 
													<button type="button" tabindex="-1" aria-hidden="true" class="btn-link border-0 p-0 bg-light" onclick="var e=document.getElementById('phylorder');e.value='$'+e.value;">$<span class="sr-only">prefix with dollarsign for sounds like search</span></button>)
												</span>
											</label>
											<input type="text" class="data-entry-input" id="phylorder" name="phylorder" value="#encodeForHtml(phylorder)#" placeholder="order">
										</div>
										<div class="col-md-2">
											<label for="suborder" class="data-entry-label align-left-center">Suborder
												<span class="small">
													(<button type="button" tabindex="-1" aria-hidden="true" class="btn-link border-0 p-0 bg-light" onclick="var e=document.getElementById('suborder');e.value='='+e.value;">=<span class="sr-only">prefix with equals sign for exact match search</span></button>, 
													<button type="button" tabindex="-1" aria-hidden="true" class="btn-link border-0 p-0 bg-light" onclick="var e=document.getElementById('suborder');e.value='$'+e.value;">$<span class="sr-only">prefix with dollarsign for sounds like search</span></button>)
												</span>
											</label>
											<input type="text" class="data-entry-input" id="suborder" name="suborder" value="#encodeForHtml(suborder)#" placeholder="suborder">
										</div>
										<div class="col-md-2">
											<label for="infraorder" class="data-entry-label align-left-center">Infraorder 
												<span class="small">
													(<button type="button" tabindex="-1" aria-hidden="true" class="btn-link border-0 p-0 bg-light" onclick="var e=document.getElementById('infraorder');e.value='='+e.value;">=<span class="sr-only">prefix with equals sign for exact match search</span></button>, 
													<button type="button" tabindex="-1" aria-hidden="true" class="btn-link border-0 p-0 bg-light" onclick="var e=document.getElementById('infraorder');e.value='$'+e.value;">$<span class="sr-only">prefix with dollarsign for sounds like search</span></button>)
												</span>
											</label>
											<input type="text" class="data-entry-input" id="infraorder" name="infraorder" value="#encodeForHtml(infraorder)#" placeholder="infraorder">
										</div>
										<div class="col-md-2">
											<label for="taxon_status" class="data-entry-label align-left-center">Nomenclatural Status</label>
											<select name="taxon_status" id="taxon_status" class="data-entry-select" size="1">
												<option></option>
												<cfloop query="cttaxon_status">
													<cfif in_taxon_status EQ taxon_status><cfset selected="selected='true'"><cfelse><cfset selected=""></cfif>
													<option value="#taxon_status#" #selected#>#taxon_status#</option>
												</cfloop>
											</select>
										</div>
										<div class="col-md-2">
											<label for="relationship" class="data-entry-label align-left-center">Has Relationship</label>
											<select name="relationship" id="relationship" class="data-entry-select" size="1">
												<option></option>
												<cfloop query="cttaxon_relation">
													<cfif in_relationship EQ taxon_relationship><cfset selected="selected='true'"><cfelse><cfset selected=""></cfif>
													<option value="#cttaxon_relation.taxon_relationship#" #selected#>#cttaxon_relation.taxon_relationship# (#cttaxon_relation.ct#)</option>
												</cfloop>
												<cfif in_relationship EQ "NOT NULL"><cfset selected="selected='true'"><cfelse><cfset selected=""></cfif>
												<option value="NOT NULL" #selected# >Any Relationship</option>
											</select>
										</div>
									</div>
									<div class="form-row mb-3">
										<div class="col-md-2">
											<label for="superfamily" class="data-entry-label align-left-center">Superfamily 
												<span class="small">
													(<button type="button" tabindex="-1" aria-hidden="true" class="btn-link border-0 p-0 bg-light" onclick="var e=document.getElementById('superfamily');e.value='='+e.value;">=<span class="sr-only">prefix with equals sign for exact match search</span></button>, 
													<button type="button" tabindex="-1" aria-hidden="true" class="btn-link border-0 p-0 bg-light" onclick="var e=document.getElementById('superfamily');e.value='$'+e.value;">$<span class="sr-only">prefix with dollarsign for sounds like search</span></button>)
												</span>
											</label>
											<input type="text" class="data-entry-input" id="superfamily" name="superfamily" value="#encodeForHtml(superfamily)#" placeholder="superfamily">
										</div>
										<div class="col-md-2">
											<label for="family" class="data-entry-label align-left-center">Family 
												<span class="small">
													(<button type="button" tabindex="-1" aria-hidden="true" class="btn-link border-0 p-0 bg-light" onclick="var e=document.getElementById('family');e.value='='+e.value;">=<span class="sr-only">prefix with equals sign for exact match search</span></button>, 
													<button type="button" tabindex="-1" aria-hidden="true" class="btn-link border-0 p-0 bg-light" onclick="var e=document.getElementById('family');e.value='$'+e.value;">$<span class="sr-only">prefix with dollarsign for sounds like search</span></button>)
												</span>
											</label>
											<input type="text" class="data-entry-input" id="family" name="family" value="#encodeForHtml(family)#" placeholder="family">
										</div>
										<div class="col-md-2">
											<label for="subfamily" class="data-entry-label align-left-center">Subfamily 
												<span class="small">
													(<button type="button" tabindex="-1" aria-hidden="true" class="btn-link border-0 p-0 bg-light" onclick="var e=document.getElementById('subfamily');e.value='='+e.value;">=<span class="sr-only">prefix with equals sign for exact match search</span></button>, 
													<button type="button" tabindex="-1" aria-hidden="true" class="btn-link border-0 p-0 bg-light" onclick="var e=document.getElementById('subfamily');e.value='$'+e.value;">$<span class="sr-only">prefix with dollarsign for sounds like search</span></button>)
												</span>
											</label>
											<input type="text" class="data-entry-input" id="subfamily" name="subfamily" value="#encodeForHtml(subfamily)#" placeholder="subfamily">
										</div>
										<div class="col-md-2">
											<label for="tribe" class="data-entry-label align-left-center">Tribe 
												<span class="small">
													(<button type="button" tabindex="-1" aria-hidden="true" class="btn-link border-0 p-0 bg-light" onclick="var e=document.getElementById('tribe');e.value='='+e.value;">=<span class="sr-only">prefix with equals sign for exact match search</span></button>, 
													<button type="button" tabindex="-1" aria-hidden="true" class="btn-link border-0 p-0 bg-light" onclick="var e=document.getElementById('tribe');e.value='$'+e.value;">$<span class="sr-only">prefix with dollarsign for sounds like search</span></button>)
												</span>
											</label>
											<input type="text" class="data-entry-input" id="tribe" name="tribe" value="#encodeForHtml(tribe)#" placeholder="tribe">
										</div>
										<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_taxonomy")>
											<cfset remark_col = "col-md-2">
										<cfelse>
											<cfset remark_col = "col-md-4">
										</cfif>
										<div class="#remark_col#">
											<label for="taxon_remarks" class="data-entry-label align-left-center">Remarks</label>
											<input type="text" class="data-entry-input" id="taxon_remarks" name="taxon_remarks" value="#encodeForHtml(taxon_remarks)#"  placeholder="taxon remarks">
										</div>
										<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_taxonomy")>
											<cfquery name="ctcollection" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
												select collection, collection_cde, collection_id from collection order by collection
											</cfquery>
											<cfset selectedCollection = ''>
											<cfif isdefined("collection_cde") and len(collection_cde) gt 0>
												<cfquery name="lookupCollection" dbtype="query">
													select collection from ctcollection where collection_cde = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#collection_cde#">
												</cfquery>
												<cfset selectedCollection = lookupCollection.collection >
											</cfif>
											<div class="col-md-2">
												<label for="collection_cde" class="data-entry-label align-left-center">Used by Coll.</label>
												<select name="collection_cde" size="1" class="data-entry-prepend-select pr-0" aria-label="collection">
													<option value="">any collection</option>
													<cfloop query="ctcollection">
														<cfif ctcollection.collection eq selectedCollection>
															<cfset selected="selected">
														<cfelse>
															<cfset selected="">
														</cfif>
														<option value="#ctcollection.collection_cde#" #selected#>#ctcollection.collection#</option>
													</cfloop>
												</select>
											</div>
										</cfif>
									</div>
									<button type="submit" class="btn btn-xs btn-primary mr-2 my-1" id="searchButton" aria-label="Search all taxa with set parameters">Search<span class="fa fa-search pl-1"></span>			</button>
									<button type="reset" class="btn btn-xs btn-warning mr-2 my-1" aria-label="Reset taxon search form to inital values">Reset</button>
									<button type="button" class="btn btn-xs btn-warning mr-2 my-1" aria-label="Start a new taxon search with a clear page" onclick="window.location.href='#Application.serverRootUrl#/Taxa.cfm';">New Search</button>
									<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_taxonomy")>
										<button type="button" class="btn btn-xs btn-warning my-1" aria-label="Run selected taxonomy quality control queries" onclick="window.location.href='#Application.serverRootUrl#/tools/TaxonomyGaps.cfm';">QC Queries</button>
									</cfif>
								</div>
							</form>
						</div>
					</div>
				</div>
			</section>

			<!--- Results table as a jqxGrid. --->
			<section class="container-fluid">
				<div class="row">
					<div class="col-12 mb-5">
						<div class="row mt-1 mb-0 pb-0 pt-1 jqx-widget-header border px-2 mx-0">
							<h1 class="h4 mt-3 ml-2 ml-md-1">
								<span tabindex="0">Results: </span>
								<span class="pr-2 font-weight-normal" id="resultCount" tabindex="0">
									<a class="messageResults" aria-label="search results"></a>
								</span> 
								<span id="resultLink" class="pr-2 font-weight-normal"></span>
							</h1>
							
							<div id="saveDialogButton" class="py-1"></div>
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
							<div id="columnPickDialogButton" class="pb-1"></div>
							<div id="resultDownloadButtonContainer" class="py-0 py-md-1"></div>
							<div id="selectModeContainer" class="ml-3" style="display: none;" >
								<script>
									function changeSelectMode(){
										var selmode = $("##selectMode").val();
										$("##searchResultsGrid").jqxGrid({selectionmode: selmode});
										if (selmode=="none") { 
											$("##searchResultsGrid").jqxGrid({enableBrowserSelection: true});
										} else {
											$("##searchResultsGrid").jqxGrid({enableBrowserSelection: false});
										}
									};
								</script>
								<label class="data-entry-label d-inline w-auto mt-1" for="selectMode">Grid Select:</label>
								<select class="data-entry-select d-inline w-auto mt-1" id="selectMode" onChange="changeSelectMode();">
									<cfif defaultSelectionMode EQ 'none'><cfset selected="selected"><cfelse><cfset selected=""></cfif>
									<option #selected# value="none">Text</option>
									<cfif defaultSelectionMode EQ 'singlecell'><cfset selected="selected"><cfelse><cfset selected=""></cfif>
									<option #selected# value="singlecell">Single Cell</option>
									<cfif defaultSelectionMode EQ 'singlerow'><cfset selected="selected"><cfelse><cfset selected=""></cfif>
									<option #selected# value="singlerow">Single Row</option>
									<cfif defaultSelectionMode EQ 'multiplerowsextended'><cfset selected="selected"><cfelse><cfset selected=""></cfif>
									<option #selected# value="multiplerowsextended">Multiple Rows (click, drag, release)</option>
									<cfif defaultSelectionMode EQ 'multiplecellsadvanced'><cfset selected="selected"><cfelse><cfset selected=""></cfif>
									<option #selected# value="multiplecellsadvanced">Multiple Cells (click, drag, release)</option>
								</select>
							</div>
							<output id="actionFeedback" class="mx-1 my-0 my-md-2 p-2 h5"></output>
						</div>
						<div class="row mt-0 mx-0">
							<!--- Grid Related code is below along with search handlers --->
							<div id="searchResultsGrid" class="jqxGrid" role="table" aria-label="Search Results Table"></div>
							<div id="enableselection"></div>
						</div>
					</div>
				</div>
			</section>
		</main>

		<cfset cellRenderClasses = "ml-1">
		<script>
			var validCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
				var rowData = jQuery("##searchResultsGrid").jqxGrid('getrowdata',row);
				var v = String(value);
				if (v.toUpperCase().trim()=='YES') { 
					color = 'text-success'; 
					bg = '';
				} else { 
					color = 'text-white'; 
					bg = 'bg-danger'; 
				} 
				return '<span class="#cellRenderClasses# '+bg+'" style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; "><span class="'+color+'">'+value+'</span></span>';
			};
		</script>
		<!--- links --->
		<script>
				<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_taxonomy")>
					var idCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
					return '<span class="#cellRenderClasses#" style="margin: 6px; display:block; float: ' + columnproperties.cellsalign + '; "><a target="_blank" class="px-2 btn-xs btn-outline-primary" href="#Application.serverRootUrl#/taxonomy/Taxonomy.cfm?action=edit&taxon_name_id=' + value + '">Edit</a></span>';
					};
				</cfif>

				var linkIdCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
					var rowData = jQuery("##searchResultsGrid").jqxGrid('getrowdata',row);
					var displayNameAuthor = rowData['DISPLAY_NAME_AUTHOR'];
					return '<span class="#cellRenderClasses#" style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; "><a target="_blank" href="/taxonomy/showTaxonomy.cfm?taxon_name_id=' + rowData['TAXON_NAME_ID'] + '">'+displayNameAuthor+'</a></span>';
				};
		</script>
		<cfif findNoCase('redesign',Session.gitBranch) EQ 0>
			<!--- Production specific links --->
			<script>
				var specimenCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
					var rowData = jQuery("##searchResultsGrid").jqxGrid('getrowdata',row);
					var result = "";
					if (value==0) {
						result = '<span class="#cellRenderClasses#" style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; ">'+value+'</span>';
					} else { 
						result = '<span class="#cellRenderClasses#" style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; ">' + value + '&nbsp;<a target="_blank" href="/SpecimenResults.cfm?taxon_name_id=' + rowData['TAXON_NAME_ID'] + '">Specimens</a></span>';
					}
					return result;
				};
			</script>
		<cfelse>
			<!--- Redesign specific links --->
			<script>
				var specimenCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
					var rowData = jQuery("##searchResultsGrid").jqxGrid('getrowdata',row);
					var result = "";
					if (value==0) {
						result = '<span class="#cellRenderClasses#" style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; ">'+value+'</span>';
					} else { 
						result = '<span class="#cellRenderClasses#" style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; ">' + value + '&nbsp;<a target="_blank" href="/SpecimenResults.cfm?taxon_name_id=' + rowData['TAXON_NAME_ID'] + '">Specimens</a></span>';
					}
					return result;
				};
			</script>
		</cfif>
		<script>
			
			window.columnHiddenSettings = new Object();
			<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
				lookupColumnVisibilities ('#cgi.script_name#','Default');
			</cfif>

			$(document).ready(function() {
				/* Setup jqxgrid for Search */
				$('##searchForm').bind('submit', function(evt){
					evt.preventDefault();

					$("##overlay").show();

					$("##searchResultsGrid").replaceWith('<div id="searchResultsGrid" class="jqxGrid" style="z-index: 1;"></div>');
					$('##resultCount').html('');
					$('##resultLink').html('');
					$('##saveDialogButton').html('');
					$('##actionFeedback').html('');
					$('##selectModeContainer').hide();

					var search =
					{
						datatype: "json",
						datafields:
						[
							{ name: 'TAXON_NAME_ID', type: 'n' }, 
							{ name: 'FULL_TAXON_NAME', type: 'string' },
							{ name: 'KINGDOM', type: 'string' },
							{ name: 'PHYLUM', type: 'string' },
							{ name: 'SUBPHYLUM', type: 'string' },
							{ name: 'SUPERCLASS', type: 'string' },
							{ name: 'PHYLCLASS', type: 'string' },
							{ name: 'SUBCLASS', type: 'string' },
							{ name: 'INFRACLASS', type: 'string' },
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
							{ name: 'VALID_CATALOG_TERM', type: 'string' },
							{ name: 'SOURCE_AUTHORITY', type: 'string' },
							{ name: 'SCIENTIFICNAMEID', type: 'string' },
							{ name: 'TAXONID', type: 'string' },
							{ name: 'TAXON_STATUS', type: 'string' },
							{ name: 'TAXON_REMARKS', type: 'string' },
							{ name: 'DISPLAY_NAME_AUTHOR', type: 'string' },
							{ name: 'PLAIN_NAME_AUTHOR', type: 'string' },
							{ name: 'COMMON_NAMES', type: 'string' },
							{ name: 'SPECIMEN_COUNT', type: 'int' }
						],
						updaterow: function (rowid, rowdata, commit) {
							commit(true);
						},
						root: 'taxonRecord',
						id: 'taxon_name_id',
						url: '/taxonomy/component/search.cfc?' + $('##searchForm').serialize(),
						timeout: #Application.ajax_timeout#000,  // units not specified, miliseconds? 
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
					$(document).ajaxSuccess(function() {
					$( ".messageResults" ).html( "<div class='color: red' aria-label='results'>Search successful</div>" );
					});

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
						pagesizeoptions: ['5','50','100'], // reset in gridLoaded
						showaggregates: true,
						columnsresize: true,
						autoshowfiltericon: true,
						autoshowcolumnsmenubutton: false,
						autoshowloadelement: false,  // overlay acts as load element for form+results
						columnsreorder: true,
						groupable: true,
						selectionmode: '#defaultSelectionMode#',
						enablebrowserselection: #defaultenablebrowserselection#,
						altrows: true,
						showtoolbar: false,
						ready: function () {
							$("##searchResultsGrid").jqxGrid('selectrow', 0);
						},
						columns: [
							{ text: 'Taxon', datafield: 'PLAIN_NAME_AUTHOR', width:300, hideable: true, hidden: getColHidProp('PLAIN_NAME_AUTHOR', false), cellsrenderer: linkIdCellRenderer },
							<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_taxonomy")>
								{ text: 'Taxon_Name_ID', datafield: 'TAXON_NAME_ID', width:50, hideable: true, hidden: getColHidProp('TAXON_NAME_ID', false), cellsrenderer: idCellRenderer }, 
							<cfelse>
								{ text: 'Taxon_name_id', datafield: 'TAXON_NAME_ID', width:50, hideable: true, hidden: getColHidProp('TAXON_NAME_ID', true) }, 
							</cfif>
							{ text: 'Specimen Count', datafield: 'SPECIMEN_COUNT', width: 105,  hideable: true, hidden: getColHidProp('SPECIMEN_COUNT', false), cellsrenderer: specimenCellRenderer },
							{ text: 'Full Taxon Name', datafield: 'FULL_TAXON_NAME', width:300, hideable: true, hidden: getColHidProp('FULL_TAXON_NAME', true) },
							{ text: 'Allowed Data Entry', datafield: 'VALID_CATALOG_TERM', width:60, hideable: true, hidden: getColHidProp('VALID_CATALOG_TERM', false), cellsrenderer: validCellRenderer },
							{ text: 'Common Name(s)', datafield: 'COMMON_NAMES', width:100, hideable: true, hidden: getColHidProp('COMMON_NAMES', true) },
							{ text: 'Kingdom', datafield: 'KINGDOM', width:100, hideable: true, hidden: getColHidProp('KINGDOM', true) },
							{ text: 'Phylum', datafield: 'PHYLUM', width:90, hideable: true, hidden: getColHidProp('PHULUM', false) },
							{ text: 'Subphylum', datafield: 'SUBPHYLUM', width:100, hideable: true, hidden: getColHidProp('SUBPHYLUM', true) },
							{ text: 'Superclass', datafield: 'SUPERCLASS', width:100, hideable: true, hidden: getColHidProp('SUPERCLASS', true) },
							{ text: 'Class', datafield: 'PHYLCLASS', width:100, hideable: true, hidden: getColHidProp('PHYLCLASS', false) },
							{ text: 'Subclass', datafield: 'SUBCLASS', width:100, hideable: true, hidden: getColHidProp('SUBCLASS', true) },
							{ text: 'Infraclass', datafield: 'INFRACLASS', width:100, hideable: true, hidden: getColHidProp('INFRACLASS', true) },
							{ text: 'Superorder', datafield: 'SUPERORDER', width:100, hideable: true, hidden: getColHidProp('SUPERORDER', true) },
							{ text: 'Order', datafield: 'PHYLORDER', width:120, hideable: true, hidden: getColHidProp('PHYLORDER', false) },
							{ text: 'Suborder', datafield: 'SUBORDER', width:100, hideable: true, hidden: getColHidProp('SUBORDER', true) },
							{ text: 'Infraorder', datafield: 'INFRAORDER', width:100, hideable: true, hidden: getColHidProp('INFRAORDER', true) },
							{ text: 'Superfamily', datafield: 'SUPERFAMILY', width:120, hideable: true, hidden: getColHidProp('SUPERFAMILY', true) },
							{ text: 'Family', datafield: 'FAMILY', width:120, hideable: true, hidden: getColHidProp('FAMILY', false) },
							{ text: 'Subfamily', datafield: 'SUBFAMILY', width:120, hideable: true, hidden: getColHidProp('SUBFAMILY',true) },
							{ text: 'Tribe', datafield: 'TRIBE', width:100, hideable: true, hidden: getColHidProp('TRIBE', true) },
							{ text: 'Genus', datafield: 'GENUS', width:100, hideable: true, hidden: getColHidProp('GENUS', false) },
							{ text: 'Subgenus', datafield: 'SUBGENUS', width:100, hideable: true, hidden: getColHidProp('SUBGENUS', false) },
							{ text: 'Species', datafield: 'SPECIES', width:100, hideable: true, hidden: getColHidProp('SPECIES', false) },
							{ text: 'Subspecies', datafield: 'SUBSPECIES', width:90, hideable: true, hidden: getColHidProp('SUBSPECIES', false) },
							{ text: 'Rank', datafield: 'INFRASPECIFIC_RANK', width:60, hideable: true, hidden: getColHidProp('INFRASPECIFIC_RANK', false) },
							{ text: 'Scientific Name', datafield: 'SCIENTIFIC_NAME', width:150, hideable: true, hidden: getColHidProp('SCIENTIFIC_NAME', true) },
							{ text: 'Authorship', datafield: 'AUTHOR_TEXT', width:140, hideable: true, hidden: getColHidProp('AUTHOR_TEXT', false) },
							{ text: 'Display Name', datafield: 'DISPLAY_NAME', width:300, hideable: true, hidden: getColHidProp('DISPLAY_NAME', true) },
							{ text: 'Code', datafield: 'NOMENCLATURAL_CODE', width:100, hideable: true, hidden: getColHidProp('NOMENCLATURAL_CODE', true) },
							{ text: 'Division', datafield: 'DIVISION', width:100, hideable: true, hidden: getColHidProp('DIVISION', true) },
							{ text: 'Subdivision', datafield: 'SUBDIVISION', width:100, hideable: true, hidden: getColHidProp('SUBDIVISION', true) },
							{ text: 'Infraspecific Author', datafield: 'INFRASPECIFIC_AUTHOR', width:100, hideable: true, hidden: getColHidProp('INFRASPECIFIC_AUTHOR', true) },
							{ text: 'Source Authority', datafield: 'SOURCE_AUTHORITY', width:100, hideable: true, hidden: getColHidProp('SOURCE_AUTHORITY', true) },
							{ text: 'dwc:scientificNameID', datafield: 'SCIENTIFICNAMEID', width:100, hideable: true, hidden: getColHidProp('SCIENTIFICNAMEID', true) },
							{ text: 'dwc:taxonID', datafield: 'TAXONID', width:100, hideable: true, hidden: getColHidProp('TAXONID', true) },
							{ text: 'Status', datafield: 'TAXON_STATUS', width:100, hideable: true, hidden: getColHidProp('TAXON_STATUS', true) },
							{ text: 'Remarks', datafield: 'TAXON_REMARKS', hideable: true, hidden: getColHidProp('TAXON_REMARKS', true) }
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
						$('##resultLink').html('<a href="/Taxa.cfm?execute=true&' + $('##searchForm :input').filter(function(index,element){ return $(element).val()!='';}).serialize() + '">Link to this search</a>');
						gridLoaded('searchResultsGrid','taxon record');
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

			<cfif isdefined("session.roles") AND listfindnocase(session.roles,"coldfusion_user") >
			function populateSaveSearch() { 
				// set up a dialog for saving the current search.
				var uri = "/Taxa.cfm?execute=true&" + $('##searchForm :input').filter(function(index,element){ return $(element).val()!='';}).not(".excludeFromLink").serialize();
				$("##saveDialog").html(
					"<div class='row'>"+ 
					"<form id='saveForm'> " + 
					" <input type='hidden' value='"+uri+"' name='url'>" + 
					" <div class='col-12'>" + 
					"  <label for='search_name_input'>Search Name</label>" + 
					"  <input type='text' id='search_name_input'  name='search_name' value='' class='data-entry-input reqdClr' placeholder='Your name for this search' maxlength='60' required>" + 
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
				$('.jqx-header-widget').css({'z-index': maxZIndex + 1 }); 
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
					$('##' + gridId).jqxGrid({ pagesize: 50});
				} else if (rowcount > 50) { 
					$('##' + gridId).jqxGrid({ pagesizeoptions: ['5','50', rowcount],pagesize: 50});
					$('##' + gridId).jqxGrid({ pagesize: 50});
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
					buttons: [
						{
							text: "Ok",
							click: function(){ 
								window.columnHiddenSettings = getColumnVisibilities('searchResultsGrid');		
								<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
									saveColumnVisibilities('#cgi.script_name#',window.columnHiddenSettings,'Default');
								</cfif>
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
				$("##columnPickDialogButton").html(
					`<span class="border d-inline-block rounded px-1 pb-1 pb-sm-0 m-1"><span class="h5 px-2">Show/Hide </span>
						<button id="columnPickDialogOpener" onclick=" $('##columnPickDialog').dialog('open'); " class="btn btn-xs btn-secondary my-2 mx-1">Select Columns</button>
						<button id="commonNameToggle" onclick=" toggleCommon(); " class="btn btn-xs btn-secondary my-2 mx-1" >Common Names</button>
						<button id="superSubToggle" onclick=" toggleSuperSub(); " class="btn btn-xs btn-secondary my-2 mx-1" >Super/Sub/Infra</button>
						<button id="sciNameToggle" onclick=" toggleScientific(); " class="btn btn-xs btn-secondary mt-2 mb-1 my-md-2 mx-1" >Scientific Name</button>
					</span>
					<button id="pinTaxonToggle" onclick=" togglePinTaxonColumn(); " class="btn btn-xs btn-secondary mx-1 mt-2 mb-1 my-md-2" >Pin Taxon Column</button>
					`
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
							class="btn btn-xs btn-secondary mx-1 mt-2 mb-1 my-md-2">Save Search</button>
					`);
				</cfif>
				// workaround for menu z-index being below grid cell z-index when grid is created by a loan search.
				// likewise for the popup menu for searching/filtering columns, ends up below the grid cells.
				var maxZIndex = getMaxZIndex();
				$('.jqx-grid-cell').css({'z-index': maxZIndex + 1});
				$('.jqx-grid-cell').css({'border-color': '##aaa'});
				$('.jqx-grid-group-cell').css({'z-index': maxZIndex + 1});
				$('.jqx-grid-group-cell').css({'border-color': '##aaa'});
				$('.jqx-menu-wrapper').css({'z-index': maxZIndex + 2});
				$('##resultDownloadButtonContainer').html('<button id="loancsvbutton" class="btn btn-xs btn-secondary px-2 mx-1 mt-1 mb-2 my-md-2" aria-label="Export results to csv" onclick=" exportGridToCSV(\'searchResultsGrid\', \''+filename+'\'); " >Export to CSV</button>');
				$('##selectModeContainer').show();
			}

			function togglePinTaxonColumn() { 
				var state = $('##searchResultsGrid').jqxGrid('getcolumnproperty', 'PLAIN_NAME_AUTHOR', 'pinned');
				$("##searchResultsGrid").jqxGrid('beginupdate');
				if (state==true) {
					$('##searchResultsGrid').jqxGrid('unpincolumn', 'PLAIN_NAME_AUTHOR');
				} else {
					$('##searchResultsGrid').jqxGrid('pincolumn', 'PLAIN_NAME_AUTHOR');
				}
				$("##searchResultsGrid").jqxGrid('endupdate');
			}
			function toggleCommon() { 
				var state = $('##searchResultsGrid').jqxGrid('getcolumnproperty', 'COMMON_NAMES', 'hidden');
				$("##searchResultsGrid").jqxGrid('beginupdate');
				if (state==true) {
					$("##searchResultsGrid").jqxGrid('showcolumn', 'COMMON_NAMES');
				} else {
					$("##searchResultsGrid").jqxGrid('hidecolumn', 'COMMON_NAMES');
				}
				$("##searchResultsGrid").jqxGrid('endupdate');
			}
			function toggleSuperSub() { 
				var state = $('##searchResultsGrid').jqxGrid('getcolumnproperty', 'SUBPHYLUM', 'hidden');
				$("##searchResultsGrid").jqxGrid('beginupdate');
				if (state==true) {
					var action = 'showcolumn';
				} else {
					var action = 'hidecolumn';
				}
				$("##searchResultsGrid").jqxGrid(action, 'SUBPHYLUM');
				$("##searchResultsGrid").jqxGrid(action, 'SUPERCLASS');
				$("##searchResultsGrid").jqxGrid(action, 'SUBCLASS');
				$("##searchResultsGrid").jqxGrid(action, 'INFRACLASS');
				$("##searchResultsGrid").jqxGrid(action, 'SUPERORDER');
				$("##searchResultsGrid").jqxGrid(action, 'SUBORDER');
				$("##searchResultsGrid").jqxGrid(action, 'INFRAORDER');
				$("##searchResultsGrid").jqxGrid(action, 'SUPERFAMILY');
				$("##searchResultsGrid").jqxGrid(action, 'SUBFAMILY');
				$("##searchResultsGrid").jqxGrid(action, 'TRIBE');
				$("##searchResultsGrid").jqxGrid(action, 'SUBGENUS');
				$("##searchResultsGrid").jqxGrid('endupdate');
			}
			function toggleScientific() { 
				var state = $('##searchResultsGrid').jqxGrid('getcolumnproperty', 'SPECIES', 'hidden');
				$("##searchResultsGrid").jqxGrid('beginupdate');
				if (state==true) {
					var action = 'showcolumn';
				} else {
					var action = 'hidecolumn';
				}
				$("##searchResultsGrid").jqxGrid(action, 'GENUS');
				$("##searchResultsGrid").jqxGrid(action, 'SUBGENUS');
				$("##searchResultsGrid").jqxGrid(action, 'SPECIES');
				$("##searchResultsGrid").jqxGrid(action, 'SUBSPECIES');
				$("##searchResultsGrid").jqxGrid(action, 'AUTHOR_TEXT');
				$("##searchResultsGrid").jqxGrid(action, 'INFRASPECIFIC_RANK');
				$("##searchResultsGrid").jqxGrid('endupdate');
			}
		</script>

		<div id="overlay" style="position: absolute; top:0px; left:0px; width: 100%; height: 100%; background: rgba(0,0,0,0.5); border-color: transparent; opacity: 0.99; display: none; z-index: 2;">
			<div class="jqx-rc-all jqx-fill-state-normal" style="position: absolute; left: 50%; top: 25%; width: 10em; height: 2.4em;line-height: 2.4em; padding: 5px; color: ##333333; border-color: ##898989; border-style: solid; margin-left: -5em; opacity: 1;">
				<div class="jqx-grid-load" style="float: left; overflow: hidden; height: 32px; width: 32px;"></div>
				<div style="float: left; display: block; margin-left: 1em;" >Searching...</div>	
			</div>
		</div>	
	</div>
</cfoutput>
<cfinclude template = "shared/_footer.cfm">
