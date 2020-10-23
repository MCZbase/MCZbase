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
			jQuery("##phylum").autocomplete({
				source: function (request, response) {
					$.ajax({
						url: "/taxonomy/component/search.cfc",
						data: { term: request.term, method: 'getPhylumAutocomplete' },
						dataType: 'json',
						success : function (data) { response(data); },
						error : handleError
					})
				},
				minLength: 3
			}).autocomplete( "instance" )._renderItem = function( ul, item ) {
      		return $("<li>").append( "<span>" + item.value + " (" + item.meta +")</span>").appendTo( ul );
    		};
			jQuery("##subphylum").autocomplete({
				source: function (request, response) {
					$.ajax({
						url: "/taxonomy/component/search.cfc",
						data: { term: request.term, method: 'getHigherRankAutocomplete', rank: 'subphylum' },
						dataType: 'json',
						success : function (data) { response(data); },
						error : handleError
					})
				},
				minLength: 3
			}).autocomplete( "instance" )._renderItem = function( ul, item ) {
      		return $("<li>").append( "<span>" + item.value + " (" + item.meta +")</span>").appendTo( ul );
    		};
			jQuery("##superclass").autocomplete({
				source: function (request, response) {
					$.ajax({
						url: "/taxonomy/component/search.cfc",
						data: { term: request.term, method: 'getHigherRankAutocomplete', rank: 'superclass' },
						dataType: 'json',
						success : function (data) { response(data); },
						error : handleError
					})
				},
				minLength: 3
			}).autocomplete( "instance" )._renderItem = function( ul, item ) {
      		return $("<li>").append( "<span>" + item.value + " (" + item.meta +")</span>").appendTo( ul );
    		};
			jQuery("##phylclass").autocomplete({
				source: function (request, response) {
					$.ajax({
						url: "/taxonomy/component/search.cfc",
						data: { term: request.term, method: 'getClassAutocomplete' },
						dataType: 'json',
						success : function (data) { response(data); },
						error : handleError
					})
				},
				minLength: 3
			}).autocomplete( "instance" )._renderItem = function( ul, item ) {
      		return $("<li>").append( "<span>" + item.value + " (" + item.meta +")</span>").appendTo( ul );
    		};
			jQuery("##subclass").autocomplete({
				source: function (request, response) {
					$.ajax({
						url: "/taxonomy/component/search.cfc",
						data: { term: request.term, method: 'getHigherRankAutocomplete', rank: 'subclass' },
						dataType: 'json',
						success : function (data) { response(data); },
						error : handleError
					})
				},
				minLength: 3
			}).autocomplete( "instance" )._renderItem = function( ul, item ) {
      		return $("<li>").append( "<span>" + item.value + " (" + item.meta +")</span>").appendTo( ul );
    		};
			jQuery("##superorder").autocomplete({
				source: function (request, response) {
					$.ajax({
						url: "/taxonomy/component/search.cfc",
						data: { term: request.term, method: 'getHigherRankAutocomplete', rank: 'superorder' },
						dataType: 'json',
						success : function (data) { response(data); },
						error : handleError
					})
				},
				minLength: 3
			}).autocomplete( "instance" )._renderItem = function( ul, item ) {
      		return $("<li>").append( "<span>" + item.value + " (" + item.meta +")</span>").appendTo( ul );
    		};
			jQuery("##phylorder").autocomplete({
				source: function (request, response) {
					$.ajax({
						url: "/taxonomy/component/search.cfc",
						data: { term: request.term, method: 'getHigherRankAutocomplete', rank: 'order' },
						dataType: 'json',
						success : function (data) { response(data); },
						error : handleError
					})
				},
				minLength: 3
			}).autocomplete( "instance" )._renderItem = function( ul, item ) {
      		return $("<li>").append( "<span>" + item.value + " (" + item.meta +")</span>").appendTo( ul );
    		};
			jQuery("##suborder").autocomplete({
				source: function (request, response) {
					$.ajax({
						url: "/taxonomy/component/search.cfc",
						data: { term: request.term, method: 'getHigherRankAutocomplete', rank: 'suborder' },
						dataType: 'json',
						success : function (data) { response(data); },
						error : handleError
					})
				},
				minLength: 3
			}).autocomplete( "instance" )._renderItem = function( ul, item ) {
      		return $("<li>").append( "<span>" + item.value + " (" + item.meta +")</span>").appendTo( ul );
    		};
			jQuery("##infraorder").autocomplete({
				source: function (request, response) {
					$.ajax({
						url: "/taxonomy/component/search.cfc",
						data: { term: request.term, method: 'getHigherRankAutocomplete', rank: 'infraorder' },
						dataType: 'json',
						success : function (data) { response(data); },
						error : handleError
					})
				},
				minLength: 3
			}).autocomplete( "instance" )._renderItem = function( ul, item ) {
      		return $("<li>").append( "<span>" + item.value + " (" + item.meta +")</span>").appendTo( ul );
    		};
			jQuery("##superfamily").autocomplete({
				source: function (request, response) {
					$.ajax({
						url: "/taxonomy/component/search.cfc",
						data: { term: request.term, method: 'getHigherRankAutocomplete', rank: 'superfamily' },
						dataType: 'json',
						success : function (data) { response(data); },
						error : handleError
					})
				},
				minLength: 3
			}).autocomplete( "instance" )._renderItem = function( ul, item ) {
      		return $("<li>").append( "<span>" + item.value + " (" + item.meta +")</span>").appendTo( ul );
    		};
			jQuery("##family").autocomplete({
				source: function (request, response) {
					$.ajax({
						url: "/taxonomy/component/search.cfc",
						data: { term: request.term, method: 'getHigherRankAutocomplete', rank: 'family' },
						dataType: 'json',
						success : function (data) { response(data); },
						error : handleError
					})
				},
				minLength: 3
			}).autocomplete( "instance" )._renderItem = function( ul, item ) {
      		return $("<li>").append( "<span>" + item.value + " (" + item.meta +")</span>").appendTo( ul );
    		};
			jQuery("##subfamily").autocomplete({
				source: function (request, response) {
					$.ajax({
						url: "/taxonomy/component/search.cfc",
						data: { term: request.term, method: 'getHigherRankAutocomplete', rank: 'subfamily' },
						dataType: 'json',
						success : function (data) { response(data); },
						error : handleError
					})
				},
				minLength: 3
			}).autocomplete( "instance" )._renderItem = function( ul, item ) {
      		return $("<li>").append( "<span>" + item.value + " (" + item.meta +")</span>").appendTo( ul );
    		};
			jQuery("##tribe").autocomplete({
				source: function (request, response) {
					$.ajax({
						url: "/taxonomy/component/search.cfc",
						data: { term: request.term, method: 'getHigherRankAutocomplete', rank: 'tribe' },
						dataType: 'json',
						success : function (data) { response(data); },
						error : handleError
					})
				},
				minLength: 3
			}).autocomplete( "instance" )._renderItem = function( ul, item ) {
      		return $("<li>").append( "<span>" + item.value + " (" + item.meta +")</span>").appendTo( ul );
    		};
			jQuery("##genus").autocomplete({
				source: function (request, response) {
					$.ajax({
						url: "/taxonomy/component/search.cfc",
						data: { term: request.term, method: 'getHigherRankAutocomplete', rank: 'genus' },
						dataType: 'json',
						success : function (data) { response(data); },
						error : handleError
					})
				},
				minLength: 3
			}).autocomplete( "instance" )._renderItem = function( ul, item ) {
      		return $("<li>").append( "<span>" + item.value + " (" + item.meta +")</span>").appendTo( ul );
    		};
			jQuery("##author_text").autocomplete({
				source: function (request, response) {
					$.ajax({
						url: "/taxonomy/component/search.cfc",
						data: { term: request.term, method: 'getHigherRankAutocomplete', rank: 'author_text' },
						dataType: 'json',
						success : function (data) { response(data); },
						error : handleError
					})
				},
				select: function (event,ui) { 
					$("##author_text").val("="+ui.item.value);
					return false; // prevents default action
				},
				minLength: 3
			}).autocomplete( "instance" )._renderItem = function( ul, item ) {
      		return $("<li>").append( "<span>" + item.value + " (" + item.meta +")</span>").appendTo( ul );
    		};
		});
	</script>
	
	<div id="overlaycontainer" style="position: relative;">
		<!--- Search form --->
		<div id="search-form-div">
			<div class="container-fluid">
				<section id="content" role="search" class="row mx-0 mb-3">
					<form name="searchForm" id="searchForm" class="search-box">
						<input type="hidden" name="method" value="getTaxa" class="keeponclear">
						<input type="hidden" name="action" value="search">
						<div class="search-box-header">
							<h1 class="h3 smallcaps text-white" tabindex="0">Search Taxonomy  <span class="count font-italic text-grayish mx-0"><small>(#getCount.cnt# records)</small></span></h1>
						</div>
						<div class="row mx-2 py-2">
							<div class="col-12 col-xl-3">
							
								<div id=blurb class="smaller-text mt-2" tabindex="0">
									Search taxonomies used in MCZbase. <a class="" href="##" onClick="getMCZDocs('Taxonomy Search')"><i class="fa fa-info-circle" aria-label="hidden"></i> <span class="sr-only" style="color: transparent !important"> link to more info </span></a>  
									<div class="readMore"><input type="checkbox" id="readMore_check_id"><label class="read" for="readMore_check_id"></label><span class="ilt">Names include current identifications, accepted names for future identifications, previous identifications (including now-unaccepted names, invalid names, and nomina nuda found on labels). Taxonomies are neither complete nor authoritative. Not all taxa in MCZbase have associated specimens.</span>
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
									<p class="smaller-text" tabindex="0"><span id="equals">Add equals sign for exact match when shown.</span> Add ! for not. Name fields accept comma separated lists.  NULL finds blanks.</p>
								</div>
								<div class="form-row bg-light border rounded p-2 mx-0">
									<div class="col-md-4">
										<label for="scientific_name" class="data-entry-label align-left-center">Scientific Name <a href="##" tabindex="-1" aria-hidden="true" class="btn-link" onclick="var e=document.getElementById('scientific_name');e.value='='+e.value;" > (=) </a></label>
										<input type="text" class="data-entry-input" name="scientific_name" id="scientific_name" placeholder="scientific name" value="#scientific_name#" aria-labelledby="scientific_name equals">
									</div>
									<div class="col-md-4">
										<label for="full_taxon_name" class="data-entry-label align-left-center">Any part of name or classification</label>
										<input type="text" class="data-entry-input" id="full_taxon_name" name="full_taxon_name" placeholder="name at any rank" value="#full_taxon_name#">
									</div>
									<div class="col-md-4">
										<label for="common_name" class="data-entry-label align-left-center">Common Name <a aria-hidden="true" tabindex="-1" href="##" class="btn-link" onclick="var e=document.getElementById('common_name');e.value='='+e.value;"> (=) </a></label>
										<input type="text" class="data-entry-input" aria-labelledby="common_name equals" id="common_name" name="common_name" value="#common_name#" placeholder="common name">
									</div>
								</div>
								<div class="form-row mt-2">
									<div class="form-group col-md-2">
										<label for="genus" class="data-entry-label align-left-center">Genus <a href="##" aria-hidden="true" tabindex="-1" class="btn-link" onclick="var e=document.getElementById('genus');e.value='='+e.value;" > (=) </a></label>
										<input type="text" class="data-entry-input" aria-labelledby="genus equals" id="genus" name="genus" value="#genus#" placeholder="generic name">
									</div>
									<div class="col-md-2">
										<label for="subgenus" class="data-entry-label align-left-center">Subgenus <a href="##" tabindex="-1" aria-hidden="true" class="btn-link" onclick="var e=document.getElementById('subgenus');e.value='='+e.value;"> (=) </a></label>
										<input type="text" class="data-entry-input" id="subgenus" aria-labelledby="subgenus equals" name="subgenus" value="#subgenus#" placeholder="subgenus">
									</div>
									<div class="form-group col-md-2">
										<label for="species" class="data-entry-label align-left-center">Species <a href="##" tabindex="-1" aria-hidden="true" class="btn-link" onclick="var e=document.getElementById('species');e.value='='+e.value;"> (=)</a> </label>
										<input type="text" class="data-entry-input" id="species" aria-labelledby="species equals" name="species" value="#species#" placeholder="specific name">
									</div>
									<div class="form-group col-md-2">
										<label for="subspecies" class="data-entry-label align-left-center">Subspecies <a href="##" tabindex="-1" aria-hidden="true" class="btn-link" onclick="var e=document.getElementById('subspecies');e.value='='+e.value;"> (=) </a></label>
										<input type="text" class="data-entry-input" id="subspecies" name="subspecies" aria-labelledby="subspecies equals" value="#subspecies#" placeholder="subspecific name">
									</div>
									<div class="col-md-2">
										<label for="author_text" class="data-entry-label align-left-center">Authorship <a href="##" tabindex="-1" aria-hidden="true" class="btn-link" onclick="var e=document.getElementById('author_text');e.value='='+e.value;" > (=) </a> </label>
										<input type="text" class="data-entry-input" id="author_text" name="author_text" aria-labelledby="author_text equals" value="#author_text#" placeholder="author text">
									</div>
								</div>
								<div class="form-row mb-1">
									<div class="col-md-2">
										<label for="kingdom" class="data-entry-label align-left-center">Kingdom <a href="##" aria-hidden="true" tabindex="-1"  class="btn-link" onclick="var e=document.getElementById('kingdom');e.value='='+e.value;">(=) </a></label>
										<input type="text" class="data-entry-input" id="kingdom" aria-labelledby="kingdom equals" name="kingdom" value="#kingdom#" placeholder="kingdom">
									</div>
									<div class="col-md-2">
										<label for="phylum" class="data-entry-label align-left-center">Phylum <a href="##" tabindex="-1" aria-hidden="true" class="btn-link" onclick="var e=document.getElementById('phylum');e.value='='+e.value;"> (=) </a></label>
										<input type="text" class="data-entry-input" id="phylum" name="phylum" aria-labelledby="phylum equals" value="#phylum#" placeholder="phylum">
									</div>
									<div class="col-md-2">
										<label for="subphylum" class="data-entry-label align-left-center">Subphylum <a href="##" tabindex="-1" aria-hidden="true" class="btn-link" onclick="var e=document.getElementById('subphylum');e.value='='+e.value;">(=) </a></label>
										<input type="small" class="data-entry-input" id="subphylum" name="subphylum" aria-labelledby="subphylum equals" value="#subphylum#" placeholder="subphylum">
									</div>
									<div class="col-md-2">
										<label for="superclass" class="data-entry-label align-left-center">Superclass <a href="##" tabindex="-1" aria-hidden="true" class="btn-link" onclick="var e=document.getElementById('superclass');e.value='='+e.value;">(=) </a></label>
										<input type="small" class="data-entry-input" id="superclass" aria-labelledby="superclass equals" name="superclass" value="#superclass#" placeholder="superclass">
									</div>
									<div class="col-md-2">
										<label for="phylclass" class="data-entry-label align-left-center">Class <a href="##" tabindex="-1" aria-hidden="true" class="btn-link" onclick="var e=document.getElementById('phylclass');e.value='='+e.value;"> (=) </a></label>
										<input type="text" class="data-entry-input" id="phylclass" name="phylclass" aria-labelledby="phylclass equals" value="#phylclass#" placeholder="class">
									</div>
									<div class="col-md-2">
										<label for="subclass" class="data-entry-label align-left-center">Subclass <a href="##" tabindex="-1" aria-hidden="true" class="btn-link" onclick="var e=document.getElementById('subclass');e.value='='+e.value;">(=) </a></label>
										<input type="text" class="data-entry-input" id="subclass" id="subclass" aria-labelledby="subclass equals" name="subclass" value="#subclass#" placeholder="subclass">
									</div>
								</div>
								<div class="form-row mb-1">
									<div class="col-md-2">
										<label for="superorder" class="data-entry-label align-left-center">Superorder <a href="##" aria-hidden="true" tabindex="-1" class="btn-link" onclick="var e=document.getElementById('superorder');e.value='='+e.value;">(=) </a></label>
										<input type="text" class="data-entry-input" id="superorder" name="superorder" aria-labelledby="superorder equals" value="#superorder#" placeholder="superorder">
									</div>
									<div class="col-md-2">
										<label for="phylorder" class="data-entry-label align-left-center">Order <a href="##" aria-hidden="true" tabindex="-1" class="btn-link" onclick="var e=document.getElementById('phylorder');e.value='='+e.value;"> (=) </a></label>
										<input type="text" class="data-entry-input" id="phylorder" name="phylorder" aria-labelledby="phylorder equals" value="#phylorder#" placeholder="order">
									</div>
									<div class="col-md-2">
										<label for="suborder" class="data-entry-label align-left-center">Suborder <a href="##" aria-hidden="true" tabindex="-1" class="btn-link" onclick="var e=document.getElementById('suborder');e.value='='+e.value;"> (=) </a></label>
										<input type="text" class="data-entry-input" id="suborder" name="suborder" aria-labelledby="suborder equals" value="#suborder#" placeholder="suborder">
									</div>
									<div class="col-md-2">
										<label for="infraorder" class="data-entry-label align-left-center">Infraorder <a href="##" aria-hidden="true" tabindex="-1" class="btn-link" onclick="var e=document.getElementById('infraorder');e.value='='+e.value;">(=) </a></label>
										<input type="text" class="data-entry-input" id="infraorder" name="infraorder" aria-labelledby="infraorder equals" value="#infraorder#" placeholder="infraorder">
									</div>
								</div>
								<div class="form-row mb-1">
									<div class="col-md-2">
										<label for="superfamily" class="data-entry-label align-left-center">Superfamily <a href="##" tabindex="-1" aria-hidden="true" class="btn-link" onclick="var e=document.getElementById('superfamily');e.value='='+e.value;">(=) </a></label>
										<input type="text" class="data-entry-input" id="superfamily" name="superfamily" value="#superfamily#" placeholder="superfamily">
									</div>
									<div class="col-md-2">
										<label for="family" class="data-entry-label align-left-center">Family <a href="##" tabindex="-1" aria-hidden="true" class="btn-link" onclick="var e=document.getElementById('family');e.value='='+e.value;"> (=) </a></label>
										<input type="text" class="data-entry-input" id="family" name="family" aria-labelledby="family equals" value="#family#" placeholder="family">
									</div>
									<div class="col-md-2">
										<label for="subfamily" class="data-entry-label align-left-center">Subfamily <a class="btn-link" tabindex="-1" aria-hidden="true" href="##" onclick="var e=document.getElementById('subfamily');e.value='='+e.value;"> (=) </a></label>
										<input type="text" class="data-entry-input" id="subfamily" name="subfamily" aria-labelledby="subfamily equals" value="#subfamily#" placeholder="subfamily">
									</div>
									<div class="col-md-2">
										<label for="tribe" class="data-entry-label align-left-center">Tribe <a href="##" tabindex="-1" class="btn-link" aria-hidden="true" onclick="var e=document.getElementById('tribe');e.value='='+e.value;"> (=) </a></label>
										<input type="text" class="data-entry-input" id="tribe" name="tribe" aria-labelledby="tribe equals" value="#tribe#" placeholder="tribe">
									</div>
									<div class="col-md-2">
										<label for="taxon_remarks" class="data-entry-label align-left-center">Remarks</label>
										<input type="text" class="data-entry-input" id="taxon_remarks" name="taxon_remarks" value="#taxon_remarks#"  placeholder="taxon remarks">
									</div>
								</div>
								<div class="form-row mb-3 mt-2">
									<div class="col-md-3">
										<label for="nomenclatural_code" class="data-entry-label align-left-center">Nomenclatural Code</label>
										<select name="nomenclatural_code" class="data-entry-select" id="nomenclatural_code">
											<option></option>
											<cfloop query="ctnomenclatural_code">
												<cfif in_nomenclatural_code EQ nomenclatural_code><cfset selected="selected='true'"><cfelse><cfset selected=""></cfif>
												<option value="#nomenclatural_code#" #selected#>#nomenclatural_code#</option>
											</cfloop>
										</select>
									</div>
									<div class="col-md-3">
										<label for="source_authority" class="data-entry-label align-left-center">Source Authority</label>
										<select name="source_authority" id="source_authority" class="data-entry-select" size="1">
											<option></option>
											<cfloop query="CTTAXONOMIC_AUTHORITY">
												<cfif in_source_authority EQ source_authority><cfset selected="selected='true'"><cfelse><cfset selected=""></cfif>
												<option value="#source_authority#">#source_authority#</option>
											</cfloop>
										</select>
									</div>
									<div class="col-md-3">
										<label for="taxon_status" class="data-entry-label align-left-center">Nomenclatural Status</label>
										<select name="taxon_status" id="taxon_status" class="data-entry-select" size="1">
											<option></option>
											<cfloop query="cttaxon_status">
												<cfif in_taxon_status EQ taxon_status><cfset selected="selected='true'"><cfelse><cfset selected=""></cfif>
												<option value="#taxon_status#">#taxon_status#</option>
											</cfloop>
										</select>
									</div>
									<div class="col-md-3">
										<label for="infraspecific_author" class="data-entry-label align-left-center">Infraspecifc Author<a href="##" tabindex="-1" class="btn-link" onclick="var e=document.getElementById('infraspecific_author');e.value='='+e.value;"> (=) </a></label>
										<input type="text" class="data-entry-input" id="infraspecific_author" name="infraspecific_author" value="#infraspecific_author#" placeholder="infraspecific author" aria-labelledby="infraspecific_author equals" aria-label="infraspecific author for botanical names only">
									</div>
								</div>
								<button type="submit" class="btn btn-xs btn-primary mr-2" id="searchButton" aria-label="Search all taxa with set parameters">Search<span class="fa fa-search pl-1"></span></button>
								<button type="reset" class="btn btn-xs btn-warning mr-2" aria-label="Reset taxon search form to inital values">Reset</button>
								<button type="button" class="btn btn-xs btn-warning" aria-label="Start a new taxon search with a clear page" onclick="window.location.href='#Application.serverRootUrl#/Taxa.cfm';">New Search</button>
							</div>
						</div>
					</form>
				</section>
			</div>
		</div><!--- end search form div --->

		<!--- Results table as a jqxGrid. --->
		<div class="container-fluid">
			<main class="row">
				<div class="col-12 mb-5">
					<div class="row mt-1 mb-0 pb-0 jqx-widget-header border px-2 mx-0">
						<h2 class="h4">Results: </h2>
						<span class="d-block px-3 p-2" id="resultCount"></span> <span id="resultLink" class="d-block p-2"></span>
						<div id="columnPickDialog">
							<div id="columnPick" class="px-1"></div>
						</div>
						<div id="columnPickDialogButton"></div>
						<div id="resultDownloadButtonContainer"></div>
					</div>
					<div class="row mt-0 mx-0">
						<!--- Grid Related code is below along with search handlers --->
						<div id="searchResultsGrid" class="jqxGrid" role="table" aria-label="Search Results Table"></div>
						<div id="enableselection"></div>
					</div>
				</div>
			</main>
		</div>

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
		<cfif isdefined("Application.header_image")>
			<!--- Production links --->
			<script>
				<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_taxonomy")>
					var idCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
					return '<span class="#cellRenderClasses#" style="margin: 6px; display:block; float: ' + columnproperties.cellsalign + '; "><button type="button" class="btn-xs btn-outline-primary pt-1 px-2" onClick=" window.open(\'#Application.serverRootUrl#/Taxonomy.cfm?action=edit&taxon_name_id=' + value + '\');">Edit</button></span>';
					};
				</cfif>
				
				var linkIdCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
					var rowData = jQuery("##searchResultsGrid").jqxGrid('getrowdata',row);
					return '<span class="#cellRenderClasses#" style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; "><a target="_blank" href="/TaxonomyDetails.cfm?taxon_name_id=' + rowData['TAXON_NAME_ID'] + '">'+value+'</a></span>';
				};
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
			<!--- Redesign links --->
			<script>
				<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_taxonomy")>
					var idCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
					return '<span class="#cellRenderClasses#" style="margin: 6px; display:block; float: ' + columnproperties.cellsalign + '; "><button type="button" class="btn-xs btn-outline-primary pt-1 px-2" onClick=" window.open(\'#Application.serverRootUrl#/taxonomy/Taxonomy.cfm?action=edit&taxon_name_id=' + value + '\');">Edit</button></span>';
					};
				</cfif>
				
				var linkIdCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
					var rowData = jQuery("##searchResultsGrid").jqxGrid('getrowdata',row);
					return '<span class="#cellRenderClasses#" style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; "><a target="_blank" href="/taxonomy/showTaxonomy.cfm?taxon_name_id=' + rowData['TAXON_NAME_ID'] + '">'+value+'</a></span>';
				};
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
							{ name: 'TAXON_NAME_ID', type: 'n' }, 
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
							{ name: 'VALID_CATALOG_TERM', type: 'string' },
							{ name: 'SOURCE_AUTHORITY', type: 'string' },
							{ name: 'SCIENTIFICNAMEID', type: 'string' },
							{ name: 'TAXONID', type: 'string' },
							{ name: 'TAXON_STATUS', type: 'string' },
							{ name: 'TAXON_REMARKS', type: 'string' },
							{ name: 'display_name_author', type: 'string' },
							{ name: 'COMMON_NAMES', type: 'string' },
							{ name: 'SPECIMEN_COUNT', type: 'int' }
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
						pagesizeoptions: ['20','50','100'], // reset in gridLoaded
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
							{ text: 'Taxon', datafield: 'display_name_author', width:300, hideable: true, hidden: false, cellsrenderer: linkIdCellRenderer },
							<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_taxonomy")>
								{ text: 'Taxon_Name_ID', datafield: 'TAXON_NAME_ID', width:50, hideable: true, hidden: false, cellsrenderer: idCellRenderer }, 
							<cfelse>
								{ text: 'Taxon_name_id', datafield: 'TAXON_NAME_ID', width:50, hideable: true, hidden: true }, 
							</cfif>
							{ text: 'Specimen Count', datafield: 'SPECIMEN_COUNT', width: 100,  hideable: true, hidden: false, cellsrenderer: specimenCellRenderer },
							{ text: 'Full Taxon Name', datafield: 'FULL_TAXON_NAME', width:300, hideable: true, hidden: true },
							{ text: 'Valid for Catalog', datafield: 'VALID_CATALOG_TERM', width:60, hideable: true, hidden: false, cellsrenderer: validCellRenderer },
							{ text: 'Common Name(s)', datafield: 'COMMON_NAMES', width:100, hideable: true, hidden: true },
							{ text: 'Kingdom', datafield: 'KINGDOM', width:100, hideable: true, hidden: true },
							{ text: 'Phylum', datafield: 'PHYLUM', width:90, hideable: true, hidden: false },
							{ text: 'Subphylum', datafield: 'SUBPHYLUM', width:100, hideable: true, hidden: true },
							{ text: 'Superclass', datafield: 'SUPERCLASS', width:100, hideable: true, hidden: true },
							{ text: 'Class', datafield: 'PHYLCLASS', width:100, hideable: true, hidden: false },
							{ text: 'Subclass', datafield: 'SUBCLASS', width:100, hideable: true, hidden: true },
							{ text: 'Superorder', datafield: 'SUPERORDER', width:100, hideable: true, hidden: true },
							{ text: 'Order', datafield: 'PHYLORDER', width:120, hideable: true, hidden: false },
							{ text: 'Suborder', datafield: 'SUBORDER', width:100, hideable: true, hidden: true },
							{ text: 'Infraorder', datafield: 'INFRAORDER', width:100, hideable: true, hidden: true },
							{ text: 'Superfamily', datafield: 'SUPERFAMILY', width:120, hideable: true, hidden: true },
							{ text: 'Family', datafield: 'FAMILY', width:120, hideable: true, hidden: false },
							{ text: 'Subfamily', datafield: 'SUBFAMILY', width:120, hideable: true, hidden:true },
							{ text: 'Tribe', datafield: 'TRIBE', width:100, hideable: true, hidden: true },
							{ text: 'Genus', datafield: 'GENUS', width:100, hideable: true, hidden: false },
							{ text: 'Subgenus', datafield: 'SUBGENUS', width:100, hideable: true, hidden: false },
							{ text: 'Species', datafield: 'SPECIES', width:100, hideable: true, hidden: false },
							{ text: 'Subspecies', datafield: 'SUBSPECIES', width:90, hideable: true, hidden: false },
							{ text: 'Rank', datafield: 'INFRASPECIFIC_RANK', width:60, hideable: true, hidden: false },
							{ text: 'Scientific Name', datafield: 'SCIENTIFIC_NAME', width:150, hideable: true, hidden: true },
							{ text: 'Authorship', datafield: 'AUTHOR_TEXT', width:140, hideable: true, hidden: false },
							{ text: 'Display Name', datafield: 'DISPLAY_NAME', width:300, hideable: true, hidden: true },
							{ text: 'Code', datafield: 'NOMENCLATURAL_CODE', width:100, hideable: true, hidden: true },
							{ text: 'Division', datafield: 'DIVISION', width:100, hideable: true, hidden: true },
							{ text: 'Subdivision', datafield: 'SUBDIVISION', width:100, hideable: true, hidden: true },
							{ text: 'Infraspecific Author', datafield: 'INFRASPECIFIC_AUTHOR', width:100, hideable: true, hidden: true },
							{ text: 'Source Authority', datafield: 'SOURCE_AUTHORITY', width:100, hideable: true, hidden: true },
							{ text: 'dwc:scientificNameID', datafield: 'SCIENTIFICNAMEID', width:100, hideable: true, hidden: true },
							{ text: 'dwc:taxonID', datafield: 'TAXONID', width:100, hideable: true, hidden: true },
							{ text: 'Status', datafield: 'TAXON_STATUS', width:100, hideable: true, hidden: true },
							{ text: 'Remarks', datafield: 'TAXON_REMARKS', hideable: true, hidden: true }
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
				   $('##' + gridId).jqxGrid({ pagesizeoptions: ['20','50', '100', rowcount]});
				   $('##' + gridId).jqxGrid({ pagesize: 50});
				} else if (rowcount > 50) { 
				   $('##' + gridId).jqxGrid({ pagesizeoptions: ['20','50', rowcount]});
				   $('##' + gridId).jqxGrid({ pagesize: 50});
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
					`<span class="border rounded p-1 mx-lg-2">Show/Hide 
						<button id='columnPickDialogOpener' onclick=" $('##columnPickDialog').dialog('open'); " class='btn-xs btn-secondary px-1 py-1 my-2' >Select Columns</button>
					 	<button id='commonNameToggle' onclick=" toggleCommon(); " class='btn-xs btn-secondary px-1 py-1 my-2' >Common Names</button>
					 	<button id='superSubToggle' onclick=" toggleSuperSub(); " class='btn-xs btn-secondary px-1 py-1 my-2' >Super/Sub/Infra</button>
					 	<button id='sciNameToggle' onclick=" toggleScientific(); " class='btn-xs btn-secondary px-1 py-1 my-2' >Scientific Name</button>
					 	<button id='pinTaxonToggle' onclick=" togglePinTaxonColumn(); " class='btn-xs btn-secondary px-1 py-1 my-2' >Pin Taxon Column</button>
					</span>`
				);
				// workaround for menu z-index being below grid cell z-index when grid is created by a loan search.
				// likewise for the popup menu for searching/filtering columns, ends up below the grid cells.
				var maxZIndex = getMaxZIndex();
				$('.jqx-grid-cell').css({'z-index': maxZIndex + 1});
				$('.jqx-grid-cell').css({'border-color': '##aaa'});
				$('.jqx-grid-group-cell').css({'z-index': maxZIndex + 1});
				$('.jqx-grid-group-cell').css({'border-color': '##aaa'});
				$('.jqx-menu-wrapper').css({'z-index': maxZIndex + 2});
				$('##resultDownloadButtonContainer').html('<button id="loancsvbutton" class="btn-xs btn-secondary px-3 py-1 my-2 mx-0" aria-label="Export results to csv" onclick=" exportGridToCSV(\'searchResultsGrid\', \''+filename+'\'); " >Export to CSV</button>');
			}

			function togglePinTaxonColumn() { 
				var state = $('##searchResultsGrid').jqxGrid('getcolumnproperty', 'display_name_author', 'pinned');
				$("##searchResultsGrid").jqxGrid('beginupdate');
				if (state==true) {
					$('##searchResultsGrid').jqxGrid('unpincolumn', 'display_name_author');
				} else {
					$('##searchResultsGrid').jqxGrid('pincolumn', 'display_name_author');
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

		<div id="overlay">
			<div class="overlay__wrapper">
				<div class="overlay__spinner">
					<button class="btn btn-dark" type="button">
						 <span class="spinner-border_overlay spinner-border-sm" role="status" aria-hidden="true"></span>
						  Searching...
					</button>
				</div>
			</div>
		</div>

	</div>
</cfoutput>
<cfinclude template = "shared/_footer.cfm">
