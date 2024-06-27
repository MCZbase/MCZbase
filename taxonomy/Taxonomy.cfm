<cfset pageTitle = "Taxon Management">
<cfif isdefined("action") AND action EQ 'newTaxon'>
	<cfset pageTitle = "Create New Taxon">
</cfif>
<cfif isdefined("action") AND action EQ 'edit'>
	<cfset pageTitle = "Edit Taxon">
	<cfif isdefined("taxon_name_id") >
		<cfquery name="TaxonIDNumber" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		select * from taxonomy where taxon_name_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#taxon_name_id#">
		</cfquery>
		<cfset pageTitle = "Edit Taxon #TaxonIDNumber.taxon_name_id#">
	</cfif>
</cfif>
<cfset MAGIC_MCZ_COLLECTION = 12>
<cfset MAGIC_MCZ_CRYO = 11>
<cfset LOANNUMBERPATTERN = '^[12][0-9]{3}-[0-9a-zA-Z]+-[A-Z][a-zA-Z]+$'>
<!--
taxonomy/Taxonomy.cfm

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
<cfif not isdefined('action') OR  action is "nothing">
	<!--- redirect to Taxonomy search page --->
	<cflocation url="/Taxa.cfm">
</cfif>

<!-------------------------------------------------------------------------------------------------->
<cfinclude template = "/shared/_header.cfm">
<cfinclude template="/taxonomy/component/functions.cfc" runOnce="true">
<cfquery name="ctInfRank" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	select infraspecific_rank from ctinfraspecific_rank order by infraspecific_rank
</cfquery>
<cfquery name="ctRelation" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	select taxon_relationship  from cttaxon_relation order by taxon_relationship
</cfquery>
<cfquery name="ctSourceAuth" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	select source_authority from CTTAXONOMIC_AUTHORITY order by source_authority
</cfquery>
<cfquery name="ctnomenclatural_code" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	select nomenclatural_code from ctnomenclatural_code order by sort_order
</cfquery>
<cfquery name="cttaxon_status" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	select taxon_status from cttaxon_status order by taxon_status
</cfquery>
<cfquery name="cttaxon_habitat" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	select taxon_habitat from cttaxon_habitat order by taxon_habitat
</cfquery>
<cfquery name="ctguid_type_taxon" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	select guid_type, placeholder, pattern_regex, resolver_regex, resolver_replacement, search_uri
	from ctguid_type 
	where applies_to like '%taxonomy.taxonid%'
</cfquery>
<cfquery name="ctguid_type_scientificname" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	select guid_type, placeholder, pattern_regex, resolver_regex, resolver_replacement, search_uri
	from ctguid_type 
	where applies_to like '%taxonomy.scientificnameid%'
</cfquery>
<cfset title="Edit Taxon">
<cfif !isdefined("subgenus_message")>
	<cfset subgenus_message ="">
</cfif>
<cfif isdefined("subgenus") and len(#subgenus#) gt 0 and REFind("^\(.*\)$",#subgenus#) gt 0>
	<cfset subgenus_message = "Do Not include parethesies">
	<cfset subgenus = replace(replace(#subgenus#,")",""),"(","") >
</cfif>

<cfoutput> 
	<script>
	// Check values once per second, warn for issues
	window.setInterval(chkTax, 1000);
	function chkTax(){
		if ($("##nomenclatural_code").val()=="unknown"){
			// no longer in use, but retain if added again
			$("##nomenclatural_code").addClass("warning");
		} else {
			$("##nomenclatural_code").removeClass("warning");
		}
		var ncode = $("##nomenclatural_code").val();
		if ($("##kingdom").val()==""){
			// kingdom should have a value
			$("##kingdom").addClass("warning");
		} else {
			$("##kingdom").removeClass("warning");
			if ( (ncode=="ICNafp" || ncode=="ICBN") && $("##kingdom").val()=="Animalia"){
				// animals shouldn't have the botanical (ICNafp) code.
				$("##kingdom").addClass("warning");
		 	}
		}
		if (ncode=="ICZN" && $("##infraspecific_author").val()!="") {
			$("##infraspecific_author").addClass("warning");
		} else { 
			$("##infraspecific_author").removeClass("warning");
		} 
		if (ncode=="ICZN" && $("##division").val()!="") {
			$("##division").addClass("warning");
		} else { 
			$("##division").removeClass("warning");
		} 
		if (ncode=="ICZN" && $("##subdivision").val()!="") {
			$("##subdivision").addClass("warning");
		} else { 
			$("##subdivision").removeClass("warning");
		} 
		if ((ncode=="ICNafp" || ncode=="ICBN") && $("##phylum").val()!="") {
			$("##phylum").addClass("warning");
		} else { 
			$("##phylum").removeClass("warning");
		} 
		if ((ncode=="ICNafp" || ncode=="ICBN") && $("##subphylum").val()!="") {
			$("##subphylum").addClass("warning");
		} else { 
			$("##subphylum").removeClass("warning");
		} 
	}
	/** getLowestTaxon 
	* find the lowest ranking taxon name on the taxonomy form.
	* @return the value of the lowest rank filled in field (or set of fields if below generic rank).
	*/
	function getLowestTaxon() { 
		var result = "";
		if ($('##genus').val()!="") { 
			result = $('##genus').val();
			if ($('##subgenus').val()!="") { 
				result = result + " (" + $('##subgenus').val() + ")";
			}
			if ($('##species').val()!="") { 
				result = result + " " + $('##species').val();
			}
			if ($('##subspecies').val()!="") { 
				result = result + " " + $('##subspecies').val();
			}
		} else if ($('##tribe').val()!="") { 
			result = $('##tribe').val();
		} else if ($('##subfamily').val()!="") { 
			result = $('##subfamily').val();
		} else if ($('##family').val()!="") { 
			result = $('##family').val();
		} else if ($('##superfamily').val()!="") { 
			result = $('##superfamily').val();
		} else if ($('##infraorder').val()!="") { 
			result = $('##infraorder').val();
		} else if ($('##suborder').val()!="") { 
			result = $('##suborder').val();
		} else if ($('##phylorder').val()!="") { 
			result = $('##phylorder').val();
		} else if ($('##superorder').val()!="") { 
			result = $('##superorder').val();
		} else if ($('##infraclass').val()!="") { 
			result = $('##infraclass').val();
		} else if ($('##subclass').val()!="") { 
			result = $('##subclass').val();
		} else if ($('##phylclass').val()!="") { 
			result = $('##phylclass').val();
		} else if ($('##superclass').val()!="") { 
			result = $('##superclass').val();
		} else if ($('##subphylum').val()!="") { 
			result = $('##subphylum').val();
		} else if ($('##phylum').val()!="") { 
			result = $('##phylum').val();
		} else if ($('##subdivision').val()!="") { 
			result = $('##subdivision').val();
		} else if ($('##division').val()!="") { 
			result = $('##division').val();
		} else if ($('##kingdom').val()!="") { 
			result = $('##kingdom').val();
		}
		return result;
	}

	/** toggleBotanicalVisibility
	*/
	function toggleBotanicalVisibility() { 
		var ncode = $('##nomenclatural_code').val();
		if (ncode=='ICNafp' || ncode=='ICBN') { 
			$('.botanical').show();	
			$('##infraspecific_author').show(); 
			$('##infraspecific_author_label').show(); 
			$('##division').show(); 
			$('##division_label').show(); 
			$('##subdivision').show(); 
			$('##subdivision_label').show(); 
			$('##division_row').show(); 
			if ($('##phylum').val()=="") { 
				$('##phylum').hide(); 
				$('##phylum_label').hide(); 
				if ($('##subphylum').val()=="") { 
					$('##subphylum').hide(); 
					$('##subphylum_label').hide(); 
					$('##phylum_row').hide(); 
				}
			}
		} else { 
			$('.botanical').hide();	
			if ($('##infraspecific_author').val()=="") { 
				$('##infraspecific_author').hide(); 
				$('##infraspecific_author_label').hide(); 
			}
			if ($('##division').val()=="") { 
				$('##division').hide(); 
				$('##division_label').hide(); 
				if ($('##subdivision').val()=="") { 
					$('##subdivision').hide(); 
					$('##subdivision_label').hide(); 
					$('##division_row').hide(); 
				}
			}
			$('##phylum').show(); 
			$('##phylum_label').show(); 
			$('##subphylum').show(); 
			$('##subphylum_label').show(); 
			$('##phylum_row').show(); 
		}
	}

	// Hide botanical code elements of form when code is ICZN
	$(document).ready(function() { 
		$('##nomenclatural_code').change(function() { 
			console.log($('##nomenclatural_code').val());
			toggleBotanicalVisibility();
		});
		toggleBotanicalVisibility();
	});  

</script> 
</cfoutput> 

<!---------------------------------------------------------------------------------------------------->
<cfif action is "edit">
	<cfset title="Edit Taxonomy">
	<cfquery name="getTaxa" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		select * from taxonomy where taxon_name_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#taxon_name_id#">
	</cfquery>
	<cfquery name="isSourceAuthorityCurrent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		select count(*) as ct from CTTAXONOMIC_AUTHORITY where source_authority = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#gettaxa.source_authority#">
	</cfquery>
	<cfoutput>
		<main class="container-xl px-xl-5 py-3" id="content">
			<h1 class="h2"><span class="font-weight-normal">Edit Taxon:</span>
				<div id="scientificNameAndAuthor" class="d-inline"></div>
				<i class="fas fa-info-circle mr-2" onClick="getMCZDocs('Edit_Taxonomy')" aria-label="help link"></i>
			</h1>
			<!---  Check to see if this record currently has a GUID assigned, record so change on edit can be warned --->
			<cfif len(getTaxa.taxonid) GT 0>
				<cfset hasTaxonID = true>
			<cfelse>
				<cfset hasTaxonID = false>
			</cfif>
			<div>
				<a class="btn btn-info btn-xs" href="/name/#encodeForURL(getTaxa.scientific_name)#" target="_blank">View Details</a>
				<span tabindex="0"><em> Placed in:</em> <span id="full_taxon_name_span">#encodeForHTML(ListDeleteAt(getTaxa.full_taxon_name,ListLen(getTaxa.full_taxon_name," ")," "))#</span></span>
			</div>
			<script>
				function updateHigher() {
					jQuery.ajax({
						url: "/taxonomy/component/functions.cfc",
						data : {
							method : "getFullTaxonName",
							taxon_name_id: #getTaxa.taxon_name_id#
						},
						success: function (result) {
							$("##full_taxon_name_span").html(result);
						},
						error: function (jqXHR, textStatus, error) {
							handleFail(jqXHR,textStatus,error, "Error checking existence of preferred name: "); 
						},
						dataType: "text"
					});
				};
			</script>
			<section class="row mx-0 border rounded my-2 px-1 pt-1 pb-2">
				<form class="col-12" name="taxon_form" method="post" action="/taxonomy/Taxonomy.cfm" id="taxon_form">
					<div class="row my-1">
						<div class="col-12 col-sm-3 mb-1">
							<!---some devices (under @media < 991px need 4 columns)--->
							<input type="hidden" id="taxon_name_id" name="taxon_name_id" value="#getTaxa.taxon_name_id#">
							<input type="hidden" id="method" name="method" value="saveTaxonomy" >
							<label for="source_authority"><span>Edit Taxon Source&nbsp;</span>
								<cfif isSourceAuthorityCurrent.ct eq 0> (#getTaxa.source_authority#) </cfif>
							</label>
							<select name="source_authority" id="source_authority" size="1" class="reqdClr data-entry-select" required>
								<cfif isSourceAuthorityCurrent.ct eq 0>
									<option value="" selected="selected"></option>
								</cfif>
								<cfloop query="ctSourceAuth">
									<option <cfif isSourceAuthorityCurrent.ct eq 1 and gettaxa.source_authority is ctsourceauth.source_authority> selected="selected" </cfif>
										value="#ctSourceAuth.source_authority#">#ctSourceAuth.source_authority#</option>
								</cfloop>
							</select>
						</div>
						<div class="col-12 col-sm-3 mb-1">
							<label for="valid_catalog_term_fg"><span>Allowed for Data Entry</span></label>
							<select name="valid_catalog_term_fg" id="valid_catalog_term_fg" class="reqdClr data-entry-select" required>
								<option <cfif getTaxa.valid_catalog_term_fg is "1"> selected="selected" </cfif> value="1">yes</option>
								<option <cfif getTaxa.valid_catalog_term_fg is "0"> selected="selected" </cfif> value="0">no</option>
							</select>
						</div>
						<div class="col-12 col-sm-3 mb-1">
							<label for="nomenclatural_code"><span>Nomenclatural Code</span></label>
							<select name="nomenclatural_code" id="nomenclatural_code" size="1" class="reqdClr data-entry-select" required>
								<cfloop query="ctnomenclatural_code">
									<option <cfif gettaxa.nomenclatural_code is ctnomenclatural_code.nomenclatural_code> selected="selected" </cfif>
										value="#ctnomenclatural_code.nomenclatural_code#">#ctnomenclatural_code.nomenclatural_code#</option>
								</cfloop>
							</select>
						</div>
						<div class="col-12 col-sm-3 mb-1">
							<label for="taxon_status" >Nomenclatural Status <i class="fas fas-info fa-info-circle" onclick="getCtDoc('cttaxon_status');" aria-label="help link"></i></label>
							<select name="taxon_status" id="taxon_status" class="data-entry-select">
								<option value=""></option>
								<cfloop query="cttaxon_status">
									<option 
										<cfif gettaxa.taxon_status is cttaxon_status.taxon_status> selected="selected" </cfif>
										value="#cttaxon_status.taxon_status#">#cttaxon_status.taxon_status#</option>
								</cfloop>
							</select>
						</div>
					</div>
					<div class="row mx-0 mt-0 mb-3">
						<div class="col-12 col-md-5 px-0 pb-2 pt-1 mt-1">
							<label for="taxonid" class="data-entry-label pt-1">GUID for Taxon (dwc:taxonID)</label>
							<cfset pattern = "">
							<cfset placeholder = "">
							<cfset regex = "">
							<cfset replacement = "">
							<cfset searchlink = "" >
							<cfset searchtext = "" >
							<cfset searchclass = "" >
							<cfloop query="ctguid_type_taxon">
								<cfif gettaxa.taxonid_guid_type is ctguid_type_taxon.guid_type OR ctguid_type_taxon.recordcount EQ 1 >
									<cfset searchlink = ctguid_type_taxon.search_uri & getTaxa.scientific_name >
									<cfif len(gettaxa.taxonid) GT 0>
										<cfset searchtext = "&nbsp; Edit GUID &nbsp;" >
										<cfset searchclass = 'class="small btn btn-xs btn-secondary editGuidButton"' >
									<cfelse>
										<cfset searchtext = "Find GUID" >
										<cfset searchclass = 'class="small btn btn-xs pl-2 pr-3 btn-secondary findGuidButton external"' >
									</cfif>
								</cfif>
							</cfloop>
							<div class="col-6 col-xl-3 px-0 float-left">
								<select name="taxonid_guid_type" id="taxonid_guid_type" class="data-entry-select">
									<cfif searchtext EQ "">
										<option value=""></option>
									</cfif>
									<cfloop query="ctguid_type_taxon">
										<cfset sel="">
										<cfif gettaxa.taxonid_guid_type is ctguid_type_taxon.guid_type OR ctguid_type_taxon.recordcount EQ 1 >
											<cfset sel="selected='selected'">
											<cfset placeholder = "#ctguid_type_taxon.placeholder#">
											<cfset pattern = "#ctguid_type_taxon.pattern_regex#">
											<cfset regex = "#ctguid_type_taxon.resolver_regex#">
											<cfset replacement = "#ctguid_type_taxon.resolver_replacement#">
										</cfif>
										<option #sel# value="#ctguid_type_taxon.guid_type#">#ctguid_type_taxon.guid_type#</option>
									</cfloop>
								</select>
							</div>
							<div class="col-auto px-0 float-left"> 
								<a href="#searchlink#" id="taxonid_search" target="_blank" #searchclass# >#searchtext# </a> 
							</div>
							<div class="col-12 col-md-11 col-xl-6 pl-0 pr-1 float-left">
								<input type="text" name="taxonid" id="taxonid" value="#gettaxa.taxonid#" 
									placeholder="#placeholder#" pattern="#pattern#" title="Enter a guid in the form #placeholder#" class="data-entry-input">
								<cfif len(regex) GT 0 >
									<cfset link = REReplace(gettaxa.taxonid,regex,replacement)>
								<cfelse>
									<cfset link = gettaxa.taxonid>
								</cfif>
								<a id="taxonid_link" href="#link#" target="_blank" class="px-2 wrapurl py-0 d-block small90 line-height-sm mt-1">#gettaxa.taxonid#</a> 
								<script>
									$(document).ready(function () { 
										if ($('##taxonid').val().length > 0) {
											$('##taxonid').hide();
											$('##taxonid_link').show();
										} else { 
											$('##taxonid').show();
											$('##taxonid_link').hide();
										}
										$('##taxonid_search').click(function (evt) { 
											switchGuidEditToFind('taxonid','taxonid_search','taxonid_link',evt);
										});
										$('##taxonid_guid_type').change(function () { 
											// On selecting a guid_type, remove an existing guid value.
											$('##taxonid').val("");
											$('##taxonid').show();
											// On selecting a guid_type, change the pattern.
											getGuidTypeInfo($('##taxonid_guid_type').val(), 'taxonid', 'taxonid_link','taxonid_search',getLowestTaxon());
										});
										$('##taxonid').blur( function () { 
											// On loss of focus for input, validate against the regex, update link
											getGuidTypeInfo($('##taxonid_guid_type').val(), 'taxonid', 'taxonid_link','taxonid_search',getLowestTaxon());
										});
										$('##species').change(function () { 
											// On changing species name, update search.
											getGuidTypeInfo($('##taxonid_guid_type').val(), 'taxonid', 'taxonid_link','taxonid_search',getLowestTaxon());
										});
										$('##genus').change(function () { 
											// On changing species name, update search.
											getGuidTypeInfo($('##taxonid_guid_type').val(), 'taxonid', 'taxonid_link','taxonid_search',getLowestTaxon());
										});
									});
								</script> 
							</div>
						</div>
						<div class="col-12 col-md-7 px-0 mt-1 mb-0 pt-1 pb-2">
							<label for="scientificnameid" class="data-entry-label pt-1">GUID for Nomenclatural Act (dwc:scientificNameID)</label>
							<cfset pattern = "">
							<cfset placeholder = "">
							<cfset regex = "">
							<cfset replacement = "">
							<cfset searchlink = "" >
							<cfset searchtext = "" >
							<cfset searchclass = "" >
							<cfloop query="ctguid_type_scientificname">
								<cfif gettaxa.scientificnameid_guid_type is ctguid_type_scientificname.guid_type OR ctguid_type_scientificname.recordcount EQ 1 >
									<cfset searchlink = ctguid_type_scientificname.search_uri & gettaxa.scientific_name >
									<cfif len(gettaxa.scientificnameid) GT 0>
										<cfset searchtext = "&nbsp; Edit GUID &nbsp;" >
										<cfset searchclass = 'class="btn btn-xs small btn-secondary editGuidButton"' >
									<cfelse>
										<cfset searchtext = "Find GUID" >
										<cfset searchclass = 'class="btn btn-xs small btn-secondary findGuidButton external"' >
									</cfif>
								</cfif>
							</cfloop>
							<div class="col-6 col-xl-2 px-0 float-left">
								<select name="scientificnameid_guid_type" id="scientificnameid_guid_type" class="data-entry-select" >
									<cfif searchtext EQ "">
										<option value=""></option>
									</cfif>
									<cfloop query="ctguid_type_scientificname">
										<cfset sel="">
										<cfif gettaxa.scientificnameid_guid_type is ctguid_type_scientificname.guid_type OR ctguid_type_scientificname.recordcount EQ 1 >
											<cfset sel="selected='selected'">
											<cfset placeholder = "#ctguid_type_scientificname.placeholder#">
											<cfset pattern = "#ctguid_type_scientificname.pattern_regex#">
											<cfset regex = "#ctguid_type_scientificname.resolver_regex#">
											<cfset replacement = "#ctguid_type_scientificname.resolver_replacement#">
										</cfif>
										<option #sel# value="#ctguid_type_scientificname.guid_type#">#ctguid_type_scientificname.guid_type#</option>
									</cfloop>
								</select>
							</div>
							<div class="col-auto px-0 float-left">
								<a href="#searchlink#" id="scientificnameid_search" target="_blank" #searchclass#>#searchtext# </a>
							</div>
							<div class="col-12 col-xl-8 pl-0 pr-1 float-left">
								<input type="text" name="scientificnameid" class="data-entry-input" id="scientificnameid" value="#gettaxa.scientificnameid#" 
									placeholder="#placeholder#" 
									pattern="#pattern#" title="Enter a guid in the form #placeholder#">
								<cfif len(regex) GT 0 >
									<cfset link = REReplace(gettaxa.scientificnameid,regex,replacement)>
								<cfelse>
									<cfset link = gettaxa.scientificnameid>
								</cfif>
								<a id="scientificnameid_link" href="#link#" target="_blank" class="px-2 py-0 d-block wrapurl small90 line-height-sm mt-1">#gettaxa.scientificnameid#</a> 
								<script>
									$(document).ready(function () { 
										if ($('##scientificnameid').val().length > 0) {
											$('##scientificnameid').hide();
											$('##scientificnameid_link').show();
										} else { 
											$('##scientificnameid').show();
											$('##scientificnameid_link').hide();
										}
										$('##scientificnameid_search').click(function (evt) { 
											switchGuidEditToFind('scientificnameid','scientificnameid_search','scientificnameid_link',evt);
										});
										$('##scientificnameid_guid_type').change( function () { 
											// On selecting a guid_type, remove an existing guid value.
											$('##scientificnameid').val("");
											// On selecting a guid_type, change the pattern.
											getGuidTypeInfo($('##scientificnameid_guid_type').val(), 'scientificnameid', 'scientificnameid_link','scientificnameid_search',getLowestTaxon());
										});
										$('##scientificnameid').blur( function () { 
											// On loss of focus for input, validate against the regex, update link
											getGuidTypeInfo($('##scientificnameid_guid_type').val(), 'scientificnameid', 'scientificnameid_link','scientificnameid_search',getLowestTaxon());
										});
										$('##species').change( function () { 
											// On changing species name, update the search link.
											getGuidTypeInfo($('##scientificnameid_guid_type').val(), 'scientificnameid', 'scientificnameid_link','scientificnameid_search',getLowestTaxon());
										});
										$('##genus').change( function () { 
											// On changing species name, update the search link.
											getGuidTypeInfo($('##scientificnameid_guid_type').val(), 'scientificnameid', 'scientificnameid_link','scientificnameid_search',getLowestTaxon());
										});
									});
								</script> 
							</div>
						</div>
					</div>
					<div class="form-row"><!--- organize layout so that phylum, class, order, family stack in same column --->
						<div class="col-12 col-xl-3 col-md-6 px-0 float-left">
							<label for="kingdom" class="col-12 col-md-3 col-form-label pb-0 align-left float-left">Kingdom</label>
							<div  class="col-12 col-md-9 float-left">
								<input type="text" name="kingdom" id="kingdom" value="#encodeForHTML(gettaxa.kingdom)#" class="data-entry-input my-1">
							</div>
						</div>
						<div id="phylum_row" class="col-12 col-xl-3 col-md-6 px-0 float-left">
							<label for="phylum" id="phylum_label" class="col-12 col-md-3 pb-0 col-form-label align-left float-left">Phylum</label>
							<div class="col-12 col-md-9 float-left">
								<input type="text" name="phylum" id="phylum" value="#encodeForHTML(gettaxa.phylum)#" class="data-entry-input my-1">
							</div>
						</div>
						<div class="col-12 col-md-6 col-xl-3 px-0 float-left">
							<label for="subphylum" id="subphylum_label" class="col-12 pb-0 col-md-3 col-form-label align-left float-left">Subphylum</label>
							<div  class="col-12 col-md-9 float-left">
								<input type="text" name="subphylum" id="subphylum" value="#encodeForHTML(gettaxa.subphylum)#" class="data-entry-input my-1">
							</div>
						</div>
					</div>
					<div id="division_row" class="botanical form-row">
						<div class="col-12 col-xl-3 px-0 botanical float-left">
						</div>
						<div class="col-12 col-md-6 col-xl-3 px-0 botanical float-left">
							<label for="division" id="division_label" class="col-12 col-md-3 pb-0 col-form-label align-left float-left">Division</label>
							<div class="col-12 col-md-9 float-left">
								<input type="text" name="division" id="division" value="#encodeForHTML(gettaxa.division)#" class="data-entry-input my-1">
							</div>
						</div>
						<div class="col-12 col-xl-3 col-md-6 px-0 botanical float-left">
							<label for="subdivision" id="subdivsion_label" class="col-sm-3 pb-0 col-form-label align-left float-left">SubDivision</label>
							<div class="col-12 col-md-9 float-left">
								<input type="text" name="subdivision" id="subdivision" value="#encodeForHTML(gettaxa.subdivision)#" class="data-entry-input my-1">
							</div>
						</div>
					</div>
					<div class="form-row">
						<div class="col-12 col-md-6 col-xl-3 px-0 float-left">
							<label for="superclass" class="col-12 col-md-3 col-form-label pb-0 align-left float-left">Superclass</label>
							<div class="col-12 col-md-9 float-left">
								<input type="text" name="superclass" id="superclass" value="#encodeForHTML(gettaxa.superclass)#" class="data-entry-input my-1">
							</div>
						</div>
						<div class="col-12 col-md-6 col-xl-3 px-0 float-left">
							<label for="phylclass" class="col-12 col-md-3 col-form-label pb-0 align-left float-left">Class</label>
							<div class="col-12 col-md-9 float-left">
								<input type="text" name="phylclass" id="phylclass" value="#encodeForHTML(gettaxa.phylclass)#" class="data-entry-input my-1">
							</div>
						</div>
						<div class="col-12 col-md-6 col-xl-3 px-0 float-left">
							<label for="subclass" class="col-12 col-md-3 col-form-label pb-0 align-left float-left">SubClass</label>
							<div class="col-12 col-md-9 float-left">
								<input type="text" name="subclass" id="subclass" value="#encodeForHTML(gettaxa.subclass)#" class="data-entry-input my-1">
							</div>
						</div>
						<div class="col-12 col-md-6 col-xl-3 px-0 float-left">
							<label for="infraclass" class="col-12 col-md-3 col-form-label pb-0 align-left float-left">InfraClass</label>
							<div class="col-12 col-md-9 float-left">
								<input type="text" name="infraclass" id="infraclass" value="#encodeForHTML(gettaxa.infraclass)#" class="data-entry-input my-1">
							</div>
						</div>
					</div>
					<div class="form-row">
						<div class="col-12 col-md-6 col-xl-3 px-0 float-left">
							<label for="superorder" class="col-12 col-md-3 col-form-label pb-0 align-left float-left">Superorder</label>
							<div class="col-12 col-md-9 float-left">
								<input type="text" name="superorder" id="superorder" value="#encodeForHTML(gettaxa.superorder)#" class="data-entry-input my-1">
							</div>
						</div>
						<div class="col-12 col-md-6 col-xl-3 px-0 float-left">
							<label for="phylorder" class="col-12 col-md-3 col-form-label pb-0 align-left float-left">Order</label>
							<div class="col-12 col-md-9 float-left">
								<input type="text" name="phylorder" id="phylorder" value="#encodeForHTML(gettaxa.phylorder)#" class="data-entry-input my-1">
							</div>
						</div>
						<div class="col-12 col-md-6 col-xl-3 px-0 float-left">
							<label for="suborder" class="col-12 col-md-3 col-form-label pb-0 align-left float-left">Suborder</label>
							<div class="col-12 col-md-9 float-left">
								<input type="text" name="suborder" id="suborder" value="#encodeForHTML(gettaxa.suborder)#" class="data-entry-input my-1">
							</div>
						</div>
						<div class="col-12 col-md-6 col-xl-3 px-0 float-left">
							<label for="infraorder" class="col-12 col-md-3 col-form-label pb-0 align-left float-left">Infraorder</label>
							<div class="col-12 col-md-9 float-left">
								<input type="text" name="infraorder" id="infraorder" value="#encodeForHTML(gettaxa.infraorder)#" class="data-entry-input my-1">
							</div>
						</div>
					</div>
				
					<cfif len(gettaxa.subsection) GT 0.>
						<div class="form-row col-12 px-0 mx-0">
							<div class="col-12 col-md-6 col-xl-3 px-0">
							</div>
							<div class="col-12 col-md-6 col-xl-3 px-0">
								<label for="subsection" class="col-sm-3 col-form-label pb-0 float-left">Section (zoological)</label>
								<!--- Section would go here --->
								<div class="col-12 col-md-9 float-left">
									--
								</div>
							</div>
							<div class="col-12 col-md-6 px-0">
								<label for="subsection" class="col-12 col-md-3 data-entry-label pb-0 mt-md-2 float-left">Subsection (zoological)</label>
								<div class="col-12 col-md-9 float-left">
									<input type="text" name="subsection" id="subsection" value="#encodeForHTML(gettaxa.subsection)#" class="data-entry-input my-1">
								</div>
							</div>
							<div class="col-12 col-md-6 col-xl-3 px-0">
							</div>
						</div>
					</cfif>
							
					<div class="form-row">
						<div class="col-12 col-md-6 col-xl-3 px-0 float-left">
							<label for="superfamily" class="col-12 col-md-3 col-form-label pb-0 align-left float-left">Superfamily</label>
							<div class="col-12 col-md-9 float-left">
								<input type="text" name="superfamily" id="superfamily" value="#encodeForHTML(gettaxa.superfamily)#" class="data-entry-input my-1">
							</div>
						</div>
						<div class="col-12 col-md-6 col-xl-3 px-0 float-left">
							<label for="family" class="col-12 col-md-3 col-form-label pb-0 align-left float-left">Family</label>
							<div class="col-12 col-md-9 float-left">
								<input type="text" name="family" id="family" value="#encodeForHTML(gettaxa.family)#" class="data-entry-input my-1">
							</div>
						</div>
						<div class="col-12 col-md-6 col-xl-3 px-0 float-left">
							<label for="subfamily" class="col-md-3 col-form-label pb-0 align-left float-left">Subfamily</label>
							<div class="col-12 col-md-9 float-left">
								<input type="text" name="subfamily" id="subfamily" value="#encodeForHTML(gettaxa.subfamily)#" class="data-entry-input my-1">
							</div>
						</div>
						<div class="col-12 col-md-6 col-xl-3 px-0 float-left">
							<label for="tribe" class="col-12 col-md-3 col-form-label pb-0 align-left float-left">Tribe</label>
							<div class="col-12 col-md-9 float-left">
								<input type="text" name="tribe" id="tribe" value="#encodeForHTML(gettaxa.tribe)#" class="data-entry-input my-1">
							</div>
						</div>
					</div>
					<div class="form-row">
						<div class="col-12 col-md-6 col-xl-3 px-0 float-left">
							<label for="genus" class="col-12 col-md-3 col-form-label pb-0  align-left float-left">Genus
								<span class="likeLink botanical" onClick="$('##genus').val('&##215;' + $('##genus').val());">
									<small class="link-color">Add&nbsp;&##215;</small>
								</span>
							</label>
							<div class="col-12 col-md-9 float-left px-3">
								<input type="text" name="genus" id="genus" class="data-entry-input my-1" value="#encodeForHtml(gettaxa.genus)#">
							</div>
						</div>
						<div class="col-12 col-md-6 col-xl-3 px-0 float-left">
							<cfif len(#gettaxa.subgenus#) gt 0 and REFind("^\(.*\)$",#gettaxa.subgenus#) gt 0>
								<cfset subgenus_message = "Do Not include parethesies">
							</cfif>
							<label for="subgenus" class="col-12 col-md-3 col-form-label pb-0 align-left float-left">Subgenus</label>
							<div class="col-12 col-md-9 float-left">
								<span class="float-left d-inline brackets mt-1">( </span><input type="text" name="subgenus" id="subgenus" value="#encodeForHTML(gettaxa.subgenus)#" class="data-entry-input m-1 w-75 float-left"><span class="float-left d-inline brackets mt-1">)</span><small class="text-danger float-left mx-3"> #encodeForHTML(subgenus_message)# </small> 
							</div>
						</div>
			
						<div class="col-12 col-md-6 col-xl-3 px-0 float-left">
							<label for="species" class="col-12 col-md-3 col-form-label pb-0 align-left float-left">Species</label>
							<div class="col-12 col-md-9 float-left">
								<input type="text" name="species" id="species" class="data-entry-input my-1" value="#encodeForHTML(gettaxa.species)#">
							</div>
						</div>		
						<div class="col-12 col-md-6 col-xl-3 px-0 float-left">
							<label for="subspecies" class="col-12 col-md-3 pb-0 col-form-label align-left float-left">Subspecies</label>
							<div class="col-12 col-md-9 float-left">
								<input type="text" name="subspecies" id="subspecies" value="#encodeForHTML(gettaxa.subspecies)#" class="data-entry-input my-1">
							</div>
						</div>
					</div>

					<div class="form-row">
						<div class="col-12 col-md-6 col-xl-3 px-0 float-left">
							<label for="infraspecific_rank" class="col-12 col-md-4 pb-0 col-form-label align-left float-left"><span>Infraspecific Rank</span></label>
							<div class="col-12 col-md-8 float-left">
								<select name="infraspecific_rank" id="infraspecific_rank" class="data-entry-select my-1" data-style="btn-primary" show-tick>
									<option value=""></option>
									<cfloop query="ctInfRank">
										<option
											<cfif gettaxa.infraspecific_rank is ctinfrank.infraspecific_rank> selected="selected" </cfif>
											value="#ctInfRank.infraspecific_rank#">#ctInfRank.infraspecific_rank#</option>
									</cfloop>
								</select>
							</div>
						</div>
					
						<div class="col-12 col-md-4 col-xl-7 px-0 float-left">
							<label for="author_text" class="col-12 col-md-2 col-xl-1 col-form-label pb-0 align-left float-left">Authorship <small>(incl. year)</small></label>
							<div class="col-12 col-md-10 col-xl-11 mb-2 float-left">
								<input type="text" name="author_text" id="author_text" value="#encodeForHTML(gettaxa.author_text)#" class="data-entry-input mt-1">
								<span class="infoLink botanical"
									onclick=" window.open('https://ipni.org/?q='+$('##genus').val()+'%20'+$('##species').val(),'_blank'); ">
									 <small class="link-color">Find in IPNI</small>
								</span>
							 </div>
						</div>
						<div class="col-12 col-md-2 col-xl-2 px-0 float-left">
							<label for="year_of_publication" class="col-12 col-md-2 col-xl-1 col-form-label pb-0 align-left float-left">Year</label>
							<div class="col-12 col-md-10 col-xl-11 mb-2 float-left">
								<input type="text" name="year_of_publication" id="year_of_publication" value="#encodeForHTML(gettaxa.year_of_publication)#" class="data-entry-input mt-1">
							 </div>
						</div>
					</div>

					<div class="form-row col-12 px-0 botanical">
						<div class="col-12 col-md-6 col-xl-3 botanical">
						</div>
						<div class="col-12 col-md-6 col-xl-9 my-1 px-0 botanical">
							<label for="infraspecific_author" id="infraspecific_author_label" class="py-0 py-xl-1 col-12 col-md-12 col-xl-1 col-form-label align-left float-left"> Infraspecific Author </label>
							<div class="col-12 col-md-12 col-xl-11 float-left pr-1">
								<input type="text" name="infraspecific_author" id="infraspecific_author" class="data-entry-input mt-1" value="#encodeForHTML(gettaxa.infraspecific_author)#">
								<span class="infoLink botanical" 
									onclick=" window.open('https://ipni.org/?q='+$('##genus').val()+'%20'+$('##species').val()+'%20'+$('##subspecies').val(),'_blank'); ">
									<small class="link-color">Find in IPNI</small> 
								</span>
								<span class="small line-height-sm d-block d-md-inline ml-2 text-secondary float-right">(do not use infraspecific author for ICZN names)</span>
							</div>
						</div>
					</div>
						
					<div class="form-row px-0 mb-3">
						<div class="col-12 px-0 mt-0">
							<label for="taxon_remarks" class="col-12 col-md-3 col-form-label mt-1 float-left text-right">Remarks (<span id="length_taxon_remarks">0 characters 4000 left</span>)</label>
							<div class="col-12 col-md-9 float-left">
							<textarea name="taxon_remarks" id="taxon_remarks" 
								onkeyup="countCharsLeft('taxon_remarks', 4000, 'length_taxon_remarks');"
								rows="3" class="data-entry-textarea col-12 mt-1 autogrow">#encodeForHTML(gettaxa.taxon_remarks)#</textarea>
							</div>
						</div>
					</div>
					<script>
						// Make all textareas currently defined autogrow as text is entered.
						$("textarea").keyup(autogrow);
						$(document).ready(function() { 
							// trigger autogrow event on autogrow text areas
							$('textarea.autogrow').keyup();
						});
					</script>
					<script>
						function changed(){
							$('##saveResultDiv').html('Unsaved changes.');
							$('##saveResultDiv').addClass('text-danger');
							$('##saveResultDiv').removeClass('text-success');
							$('##saveResultDiv').removeClass('text-warning');
						};
						$(document).ready(function() {
							// caution, text inputs must have type=text to be bound to change function.
							$('##taxon_form input[type=text]').on("change",changed);
							$('##taxon_form select').on("change",changed);
							$('##taxon_remarks').on("change",changed);
							countCharsLeft('taxon_remarks', 4000, 'length_taxon_remarks');
						});
						function saveEdits(confirmClicked=false){ 
							<cfif hasTaxonId>
								if (!confirmClicked && $("##taxonid").val()=="#gettaxa.taxonid#") { 
								 	// GUID value has not changed from the initial value, but record changes are being saved, provide warning dialog.
									confirmDialog("This taxon record is linked to an authority with a taxonID value.  Changes to the taxon name (but not the higher taxonomy) should only be made to conform the name with authority.", "Confirm Edits to taxon with GUID", function(){ saveEdits(true); } )
								} else { 
							</cfif>
									// no taxonid on page load, or confirm edit clicked.
									var sourcetext = $('##source_authority').val();
									var taxonid = $('##taxon_name_id').val();
									var subgenus = $('##subgenus').val();
									if ( subgenus.length > 0 && subgenus.match(/^\(.*\)$/) ) {
										<cfset subgenus_message = "Do not include parethesies">
										messageDialog('Error saving taxon record: Do not include the parethesies in the subgenus field.', 'Error: parenthesies in subgenus.');
										$('##saveResultDiv').html('Remove parenthesies from Subgenus.');
										$('##saveResultDiv').addClass('text-danger');
										$('##saveResultDiv').removeClass('text-success');
										$('##saveResultDiv').removeClass('text-warning');
									} else if (sourcetext.length == 0) { 
										messageDialog('Error saving taxon record : You must select a valid source for this taxon from the pick list.', 'Error: source must be specified.');
										$('##saveResultDiv').html('Fix error in Source field.');
										$('##saveResultDiv').addClass('text-danger');
										$('##saveResultDiv').removeClass('text-success');
										$('##saveResultDiv').removeClass('text-warning');
									} else {
										$('##saveResultDiv').html('Saving....');
										$('##saveResultDiv').addClass('text-warning');
										$('##saveResultDiv').removeClass('text-success');
										$('##saveResultDiv').removeClass('text-danger');
										jQuery.ajax({
											url : "/taxonomy/component/functions.cfc",
											type : "post",
											dataType : "json",
											data : $('##taxon_form').serialize(),
											success : function (data) {
												$('##saveResultDiv').html('Saved.');
												$('##saveResultDiv').addClass('text-success');
												$('##saveResultDiv').removeClass('text-danger');
												$('##saveResultDiv').removeClass('text-warning');
												loadTaxonName(#getTaxa.taxon_name_id#,'scientificNameAndAuthor');
												updateHigher();
											},
											error: function(jqXHR,textStatus,error){
												$('##saveResultDiv').html('Error.');
												$('##saveResultDiv').addClass('text-danger');
												$('##saveResultDiv').removeClass('text-success');
												$('##saveResultDiv').removeClass('text-warning');
												var message = "";
												if (error == 'timeout') {
													message = ' Server took too long to respond.';
												} else if (error && error.toString().startsWith('Syntax Error: "JSON.parse:')) {
													message = ' Backing method did not return JSON.';
												} else {
													message = jqXHR.responseText;
												}
												messageDialog('Error saving taxon record: '+message, 'Error: '+error.substring(0,50));
											}
										});
									}
							<cfif hasTaxonId>
								}
							</cfif>
						};
						$( document ).ready(function(){
							loadTaxonName(#taxon_name_id#,'scientificNameAndAuthor');
						});
					</script>
					<div class="row mt-1 mb-2">
						<div class="col-10">
							<input type="button" 
								value="Save" title="Save" aria-label="Save"
								class="btn btn-xs btn-primary mx-1"
								onClick="if (checkFormValidity($('##taxon_form')[0])) { saveEdits(); } " 
								>
							<a class="btn btn-xs btn-secondary mx-1" href='/taxonomy/Taxonomy.cfm?action=newTaxon&taxon_name_id=#taxon_name_id#'>Clone</a>
							<output id="saveResultDiv" class="text-danger mx-auto text-left" style="width: 10em;">&nbsp;</output>	
						</div>
						<div class="col-2">
							<input type="button" value="Delete" class="btn btn-xs btn-danger mx-1 float-right"	onclick=" confirmDialog('Delete this Taxon?','Confirm Delete Taxon',function(){ window.location.href='#Application.serverRootUrl#/taxonomy/Taxonomy.cfm?action=deleTaxon&taxon_name_id=#taxon_name_id#' });">
						</div>
					</div>
				</form>
			</section>

			<div class="row mx-0">
				<div class="col-12 row mt-2 mb-2 border rounded px-2 pb-2 bg-grayish">
					<h2 class="h3 mt-0 mb-1 px-1">Matches on this name in other scientific name data sets:</h4>
					<section class="col-12 col-md-12 px-0">
						<div class="form-row mx-0 mt-2 px-3 py-3 border bg-light rounded">	
								<div id="taxonLookupDiv" class="mx-0 row mt-1">Loading....</div>
						</div>
						<script>
							$(document).ready(function(){
								lookupName(#taxon_name_id#,"taxonLookupDiv");
							});
						</script>
					</section>
				</div>
			</div>

			<div class="row mx-0">
				<div class="col-12 row mt-2 mb-4 border rounded px-2 pb-2 bg-grayish">

					<section class="col-12 col-md-12 px-0">
						<div class="form-row mx-0 mt-2 px-3 py-3 border bg-light rounded">	
							<div class="col-12 px-0">
								<h2 class="h3 mt-0 mb-1 px-1">Related Publications</h4>
								<div id="taxonPublicationsDiv" class="mx-0 row mt-1">Loading....</div>
							</div>
							<div class="col-12 px-0">
								<label for="new_pub_formatted" class="data-entry-label">Pick Publication</label>
								<span>
									<input type="text" id="new_pub_formatted" name="newPub" class="data-entry-input col-12 col-md-9 float-left">
									<form name="newPubForm" id="newPubForm">
										<div class="col-12 col-sm-3 pl-1 pr-0 float-left">
											<input type="submit" value="Add" class="btn btn-xs btn-secondary mt-2 mt-md-0">
										</div>
								<input type="hidden" name="taxon_name_id" value="#getTaxa.taxon_name_id#">
								<input type="hidden" name="method" value="newTaxonPub">
								<input type="hidden" name="publication_id" id="publication_id">
									</form>
								</span>
							</div>
						</div>
						<script>
							$(document).ready(function(){ 
								$('##newPubForm').bind('submit', function(evt){
									evt.preventDefault();
									var pubId = $('##publication_id').val();
									if (pubId.length > 0) { 
										jQuery.ajax({
											url : "/taxonomy/component/functions.cfc",
											type : "post",
											dataType : "json",
											data :  $('##newPubForm').serialize(),
											success : function (data) {
												loadTaxonPublications(#taxon_name_id#,'taxonPublicationsDiv');
												$('##publication_id').val("");
												$('##new_pub_formatted').val("");
											},
											error: function(jqXHR,textStatus,error){
												var message = "";
												if (error == 'timeout') {
													message = ' Server took too long to respond.';
												} else {
													message = jqXHR.responseText;
												}
												messageDialog('Error adding publication: '+message, 'Error: '+error.substring(0,50));
											}
										});
									} else { 
										messageDialog('Error adding publication. You must select a publication to add from the picklist.', 'Error: Publication not selected');
									};
								})
							});
						</script>
						<script>
							$( document ).ready(makePublicationPicker('new_pub_formatted','publication_id'));
							$( document ).ready(loadTaxonPublications(#taxon_name_id#,'taxonPublicationsDiv'));
							function removeTaxonPub(taxonomy_publication_id) { 
								jQuery.ajax({
									url : "/taxonomy/component/functions.cfc",
									type : "post",
									dataType : "json",
									data :  { 
										method: 'removeTaxonPub',
										taxonomy_publication_id: taxonomy_publication_id
									},
									success : function (data) {
										loadTaxonPublications(#taxon_name_id#,'taxonPublicationsDiv');
									},
									error: function(jqXHR,textStatus,error){
										var message = "";
										if (error == 'timeout') {
											message = ' Server took too long to respond.';
										} else {
											message = jqXHR.responseText;
										}
										messageDialog('Error removing publication: '+message, 'Error: '+error.substring(0,50));
									}
								});
							}
						</script>
					</section>

					<section class="col-12 px-0">
						<div class="p-3 border bg-light rounded mt-2">
							<h2 class="h3 mt-0 mb-1 px-1">Related Taxa</h2>
							<div id="taxonRelationsDiv">Loading....</div>
							<div id="editTaxonRelationDialog"></div>
							<script>
								$(document).ready( loadTaxonRelations(#getTaxa.taxon_name_id#,'taxonRelationsDiv') );
							</script>
							<form id="taxonRelationsForm">
							<div class="form-row">
								<div class="col-12 col-md-3 col-xl-2">
									<label for="new_taxon_relationship" class="data-entry-label mt-1">Add Relationship</label>
									<select name="taxon_relationship" class="reqdClr data-entry-select" id="new_taxon_relationship" required>
										<cfloop query="ctRelation">
											<option value="#ctRelation.taxon_relationship#">#ctRelation.taxon_relationship#</option>
										</cfloop>
									</select>
								</div>
								<div class="col-12 col-md-4 col-xl-4">
									<label for="newRelatedName" class="data-entry-label mt-1">Related Taxon</label>
									<input type="text" name="relatedName" class="reqdClr data-entry-input" id="newRelatedName" required>
									<input type="hidden" name="newRelatedId" id="newRelatedId">
									<script>
										$(document).ready( 
											makeScientificNameAutocompleteMeta('newRelatedName', 'newRelatedId')
										);
									</script>
								</div>
								<div class="col-12 col-md-3 col-xl-4">
									<label for="new_relation_authority" class="data-entry-label mt-1">Authority</label>
									<input type="text" name="relation_authority" class="data-entry-input" id="new_relation_authority">
								</div>
								<script>
									function clearTaxonRelationFields() {
										$('##newRelatedName').val("");
										$('##newRelatedId').val("");
										if ($('##new_taxon_relationship').val() != 'accepted synonym of') {
											$('##newRelatedId').val("");
										}
									}
									function addTaxonRelationHandler() { 
										if ($('##taxonRelationsForm')[0].checkValidity()) { 
											if ($('##newRelatedId').val() == "") { 
												messageDialog('Error: Unable to create relationship, you must pick a related taxon from the picklist.' ,'Error: No related taxon selected');
											} else { 
												$("##addTaxonRelationFeedback").show();
												addTaxonRelation(#getTaxa.taxon_name_id#,
													$('##newRelatedId').val(),
													$('##new_taxon_relationship').val(),
													$('##new_relation_authority').val(),
													'taxonRelationsDiv'
												);
											}
										} else { 
											messageDialog('Error: Unable to create relationship, required field missing a value.' ,'Error: Required fields not filled in.');
										}
									}
								</script>
								<div class="col-12 col-md-2 pt-1">
									<label for="addTaxonRelationButton" class="data-entry-label mt-1" aria-hidden="true">
										<output id="addTaxonRelationFeedback" style="display: none;"><img src='/shared/images/indicator.gif'>&nbsp;</output>
									</label>
									<input type="button" value="Create" class="btn btn-xs btn-secondary mt-2"
										onclick=" addTaxonRelationHandler(); "
										id="addTaxonRelationButton"
									>
								</div>
							</div>
							</form>
							<script>
								$(document).ready(function(){
									$('##taxonRelationsForm').submit( function(event){ event.preventDefault(); } );
								});
							</script>
						</div>
					</section>

					<section class="mt-2 float-left col-12 col-md-6 pl-0 pr-0 pr-md-1">
						<div class="border bg-light float-left p-3 w-100 rounded">
							<script>
								function reloadCommonNames() {
									loadCommonNames(#getTaxa.taxon_name_id#,'commonNamesDiv');
								};
								function addCommonNameAction() { 
									newCommon(#getTaxa.taxon_name_id#,$('##new_common_name').val(),'commonNamesDiv'); 
								};
							</script>
							<cfset commonBit = getCommonHtml(taxon_name_id="#getTaxa.taxon_name_id#",target="commonNamesDiv")>
							<div id="commonNamesDiv">#commonBit#</div>
							<label for="new_common_name" class="data-entry-label float-left mt-4 pb-0">Add New Common Name</label>
							<input type="text" name="common_name" class="data-entry-input my-1 float-left w-75" id="new_common_name">
							<input type="button" value="Create" class="btn btn-xs btn-secondary ml-1 mt-1 float-left" id="newCommonNameButton" >
							<script>
								$(document).ready(function(){
									$('##newCommonNameButton').click( function(event){ 
										event.preventDefault(); 
										addCommonNameAction();
									});
								});
							</script>
						</div>
					</section>

					<section class="mt-2 float-left col-12 col-md-6 pl-md-1 px-0">
						<div class="border bg-light float-left p-3 w-100 rounded">
							<cfquery name="habitat" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
								select taxon_habitat 
								from taxon_habitat 
								where taxon_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#taxon_name_id#">
							</cfquery>
						
							<cfset usedHabitats = valueList(habitat.taxon_habitat)>
							<h2 class="h3 mt-0 px-1">Habitat</h2>
							<div id="habitatsDiv">Loading....</div>
							<script>
								$(document).ready(function(){
									loadHabitats(#getTaxa.taxon_name_id#,'habitatsDiv');
								});
							</script>
							<label for="taxon_habitat" class="data-entry-label float-left mt-4 pb-0">Add New Habitat</label>
							<select name="taxon_habitat" id="new_taxon_habitat"size="1" class="data-entry-select my-1 w-75 float-left">
								<cfloop query="cttaxon_habitat">
									<cfif not listcontains(usedHabitats,cttaxon_habitat.taxon_habitat)>
										<option value="#cttaxon_habitat.taxon_habitat#">#cttaxon_habitat.taxon_habitat#</option>
									</cfif>
								</cfloop>
							</select>
							<input type="button" value="Add" class="btn btn-xs btn-secondary ml-1 mt-1 float-left" 
								onclick=" newHabitat(#getTaxa.taxon_name_id#,$('##new_taxon_habitat').val(),'habitatsDiv'); "
								>
						</div>
					</section>
					<section class="mt-2 float-left col-12 px-0">
						<div class="p-3 border bg-light rounded mt-2">
							<script type='text/javascript' language="javascript" src='/dataquality/js/bdq_quality_control.js'></script>
							<script>
								function runTests() {
									$("##NameDQDiv").html("Running tests....");
									loadNameQC("", #getTaxa.taxon_name_id#, "NameDQDiv");
								}
							</script>
							<input type="button" value="Run Quality Control Tests" class="btn btn-xs btn-secondary" onClick=" runTests(); ">
							<!---  Scientific Name tests --->
							<div id="NameDQDiv"></div>
						</div>
					</section>
					<section class="mt-2 float-left col-12 px-0">
						<div class="p-3 border bg-light rounded mt-2">
							<h2 class="h4">Annotations:</h2>
							<cfquery name="existingAnnotations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
								select count(*) cnt from annotations
								where taxon_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTaxa.taxon_name_id#">
							</cfquery>
							<cfif #existingAnnotations.cnt# GT 0>
								<button type="button" aria-label="Annotate" id="annotationDialogLauncher"
									class="btn btn-xs btn-info" value="Annotate this record and view existing annotations"
									onClick=" openAnnotationsDialog('annotationDialog','taxon_name',#getTaxa.taxon_name_id#,null);">Annotate/View Annotations</button>
							<cfelse>
								<button type="button" aria-label="Annotate" id="annotationDialogLauncher"
									class="btn btn-xs btn-info" value="Annotate this record"
									onClick=" openAnnotationsDialog('annotationDialog','taxon_name',#getTaxa.taxon_name_id#,null);">Annotate</button>
							</cfif>
							<div id="annotationDialog"></div>
							<cfif #existingAnnotations.cnt# gt 0>
								<cfif #existingAnnotations.cnt# EQ 1>
									<cfset are = "is">
									<cfset s = "">
								<cfelse>
									<cfset are = "are">
									<cfset s = "s">
								</cfif>
								<p>There #are# #existingAnnotations.cnt# annotation#s# on this taxon record</p>
								<cfquery name="annotations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									SELECT
										annotation_id,
										to_char(annotate_date,'yyyy-mm-dd') annotate_date,
										cf_username,
										annotation,
										reviewer_agent_id,
										MCZBASE.get_agentnameoftype(reviewer_agent_id) reviewer,
										reviewed_fg,
										reviewer_comment,
										state, 
										resolution,
										motivation
									FROM 
										annotations
									WHERE
										taxon_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTaxa.taxon_name_id#">
									ORDER BY 
									annotate_date
								</cfquery>
								<ul class="list-group">
									<cfloop query="annotations">
										<cfif len(#annotation#) gt 0>
											<li class="list-group-item py-1">
												#annotation#
												<span class="d-block small mb-0 pb-0">#motivation# (#annotate_date#) #state#</span>
												<cfif reviewed_fg EQ "1">
													<span class="d-block small mb-0 pb-0">#resolution# #reviewer# #reviewer_comment#</span>
												</cfif>
											</li>
										</cfif>
									</cfloop>
								</ul>
							<cfelse>
								<p class="my-2">There are no annotations on this taxon record</p>
							</cfif>
						</div>
					</section>

				</div>
			</div>
		</main>
	</cfoutput>
</cfif>
<!---------------------------------------------------------------------------------------------------->
<cfif Action is "deleTaxon">
	<cftry>
		<cfoutput>
			<cfquery name="deleTaxon" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				DELETE FROM
					taxonomy
				WHERE
					taxon_name_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#taxon_name_id#">
			</cfquery>
			<section class="container">
				<h1 class="h3">Taxon record successfully deleted.</h1>
				<ul>
					<li><a href="/Taxa.cfm">Search for taxon records</a>.</li>
				</ul>
			</section>
		</cfoutput>
	<cfcatch>
		<cfoutput>
			<section class="container">
				<div class="row">
					<div class="alert alert-danger" role="alert">
						<img src="/shared/images/Process-stop.png" alt="[ Error ]" style="float:left; width: 50px;margin-right: 1em;">
						<h1 class="h2">
							Delete of <a href="/taxonomy/Taxonomy.cfm?Action=edit&taxon_name_id=#taxon_name_id#">taxon record</a> failed.
						</h1>
						<p>There was an error deleting this taxon record.</p>
						<p><a href="/info/bugs.cfm">“Feedback/Report Errors”</a></p>
					</div>
				</div>
				<p><cfdump var=#cfcatch#></p>
			</section>
		</cfoutput>	
	</cfcatch>
	</cftry>
</cfif>

<!---------------------------------------------------------------------------------------------------->
<cfif action is "newTaxon">
	<cfset title = "Add Taxon">
	<cfquery name="getClonedFromTaxon" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		select * from taxonomy where taxon_name_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#taxon_name_id#">
	</cfquery>
	<cfoutput query="getClonedFromTaxon">
		<cfquery name="isSourceAuthorityCurrent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			select count(*) as ct from CTTAXONOMIC_AUTHORITY where source_authority = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getClonedFromTaxon.source_authority#">
		</cfquery>
		<main class="container-xl px-xl-5 py-3" id="content">
			<h1 class="h2 ml-3">Create New Taxonomy Record
				<span class="smaller">
					(through cloning and editing) <i class="fas fa-info-circle mr-2" onClick="getMCZDocs('Edit_Taxonomy')" aria-label="help link"></i>
				</span>
			</h1>
			<div class="row mx-0 pt-2 pb-3 mt-1 mb-5 px-2 border rounded">
				<form name="taxon_form" id="taxon_form2" method="post" action="/taxonomy/Taxonomy.cfm" class="float-left w-100 col-12 px-2">
					<input type="hidden" name="Action" value="saveNewTaxon">
	
					<div class="row">
						<div class="col-12 col-sm-3">
							<!---some devices (under @media < 991px need 4 columns)--->
							<input type="hidden" id="taxon_name_id" name="taxon_name_id" value="#getClonedFromTaxon.taxon_name_id#">
							<input type="hidden" id="method" name="method" value="saveTaxonomy" >
							<label for="source_authority"><span>Edit Taxon Source&nbsp;</span>
								<cfif isSourceAuthorityCurrent.ct GT 0> (Clone source: #encodeForHTML(getClonedFromTaxon.source_authority)#) </cfif>
							</label>
							<select name="source_authority" id="source_authority" size="1" class="reqdClr data-entry-select" required>
								<option value="" selected="selected"></option>
								<cfloop query="ctSourceAuth">
									<option value="#ctSourceAuth.source_authority#">#ctSourceAuth.source_authority#</option>
								</cfloop>
							</select>
						</div>
						<div class="col-12 col-sm-3">
							<label for="valid_catalog_term_fg"><span>Allowed for Data Entry</span></label>
							<select name="valid_catalog_term_fg" id="valid_catalog_term_fg" class="reqdClr data-entry-select" required>
								<option <cfif getClonedFromTaxon.valid_catalog_term_fg is "1"> selected="selected" </cfif> value="1">yes</option>
								<option <cfif getClonedFromTaxon.valid_catalog_term_fg is "0"> selected="selected" </cfif> value="0">no</option>
							</select>
						</div>
						<div class="col-12 col-sm-3">
							<label for="nomenclatural_code"><span>Nomenclatural Code</span></label>
							<select name="nomenclatural_code" id="nomenclatural_code" size="1" class="reqdClr data-entry-select" required>
								<cfloop query="ctnomenclatural_code">
									<option <cfif getClonedFromTaxon.nomenclatural_code is ctnomenclatural_code.nomenclatural_code> selected="selected" </cfif>
										value="#ctnomenclatural_code.nomenclatural_code#">#ctnomenclatural_code.nomenclatural_code#</option>
								</cfloop>
							</select>
						</div>
						<div class="col-12 col-sm-3">
							<label for="taxon_status">Nomenclatural Status <i class="fas fas-info fa-info-circle" onclick="getCtDoc('cttaxon_status');" aria-label="help link"></i></label>
							<select name="taxon_status" id="taxon_status" class="data-entry-select">
								<option value=""></option>
								<cfloop query="cttaxon_status">
									<option 
										<cfif getClonedFromTaxon.taxon_status is cttaxon_status.taxon_status> selected="selected" </cfif>
										value="#cttaxon_status.taxon_status#">#cttaxon_status.taxon_status#</option>
								</cfloop>
							</select>
						</div>
					</div>
					<div class="row mx-0 mx-md-1 mt-2 mb-3">
						<div class="col-12 col-md-5 px-0 mb-0 pb-2 pt-1 mt-2">
							<label for="taxonid" class="data-entry-label">GUID for Taxon (dwc:taxonID)</label>
							<cfset pattern = "">
							<cfset placeholder = "">
							<cfset regex = "">
							<cfset replacement = "">
							<cfset searchlink = "" >
							<cfset searchtext = "" >
							<cfset searchclass = "" >
							<cfloop query="ctguid_type_taxon">
								<cfif getClonedFromTaxon.taxonid_guid_type is ctguid_type_taxon.guid_type OR ctguid_type_taxon.recordcount EQ 1 >
									<cfset searchlink = ctguid_type_taxon.search_uri & getClonedFromTaxon.scientific_name >
									<cfset searchtext = "Find GUID" >
									<cfset searchclass = 'class="btn btn-xs small btn-secondary findGuidButton external"' >
								</cfif>
							</cfloop>
							<div class="col-6 col-xl-3 px-0 float-left">
								<select name="taxonid_guid_type" id="taxonid_guid_type" class="data-entry-select">
									<cfif searchtext EQ "">
										<option value=""></option>
									</cfif>
									<cfloop query="ctguid_type_taxon">
										<cfset sel="">
										<cfif getClonedFromTaxon.taxonid_guid_type is ctguid_type_taxon.guid_type OR ctguid_type_taxon.recordcount EQ 1 >
											<cfset sel="selected='selected'">
											<cfset placeholder = "#ctguid_type_taxon.placeholder#">
											<cfset pattern = "#ctguid_type_taxon.pattern_regex#">
											<cfset regex = "#ctguid_type_taxon.resolver_regex#">
											<cfset replacement = "#ctguid_type_taxon.resolver_replacement#">
										</cfif>
										<option #sel# value="#ctguid_type_taxon.guid_type#">#ctguid_type_taxon.guid_type#</option>
									</cfloop>
								</select>
							</div>
							<div class="col-auto px-0 float-left"> 
								<a href="#searchlink#" id="taxonid_search" target="_blank" #searchclass# >#searchtext# </a> 
							</div>
							<div class="col-12 col-xl-6 pl-0 float-left">
								<input type="text" name="taxonid" id="taxonid" value="" 
									placeholder="#placeholder#" pattern="#pattern#" title="Enter a guid in the form #placeholder#" 
									class="data-entry-input small">
								<a id="taxonid_link" href="" target="_blank" class="px-2 small py-0 d-block line-height-sm mt-1"></a> 
								<script>
									$(document).ready(function(){ 
										$('##taxonid').show();
										$('##taxonid_link').hide();
										$('##taxonid_search').click(function (evt) { 
											switchGuidEditToFind('taxonid','taxonid_search','taxonid_link',evt);
										});
										$('##taxonid_guid_type').change(function () { 
											// On selecting a guid_type, remove an existing guid value.
											$('##taxonid').val("");
											$('##taxonid').show();
											// On selecting a guid_type, change the pattern.
											getGuidTypeInfo($('##taxonid_guid_type').val(), 'taxonid', 'taxonid_link','taxonid_search',getLowestTaxon());
										});
										$('##taxonid').blur( function () { 
											// On loss of focus for input, validate against the regex, update link
											getGuidTypeInfo($('##taxonid_guid_type').val(), 'taxonid', 'taxonid_link','taxonid_search',getLowestTaxon());
										});
										$('##species').change(function () { 
											// On changing species name, update search.
											getGuidTypeInfo($('##taxonid_guid_type').val(), 'taxonid', 'taxonid_link','taxonid_search',getLowestTaxon());
										});
										$('##genus').change(function () { 
											// On changing species name, update search.
											getGuidTypeInfo($('##taxonid_guid_type').val(), 'taxonid', 'taxonid_link','taxonid_search',getLowestTaxon());
										});
									});
								</script> 
							</div>
						</div>
						<div class="col-12 col-md-7 mb-0 px-0 pb-2 pt-1 mt-2">
							<label for="scientificnameid" class="data-entry-label">GUID for Nomenclatural Act (dwc:scientificNameID)</label>
							<cfset pattern = "">
							<cfset placeholder = "">
							<cfset regex = "">
							<cfset replacement = "">
							<cfset searchlink = "" >
							<cfset searchtext = "" >
							<cfset searchclass = "" >
							<cfloop query="ctguid_type_scientificname">
								<cfif getClonedFromTaxon.scientificnameid_guid_type is ctguid_type_scientificname.guid_type OR ctguid_type_scientificname.recordcount EQ 1 >
									<cfset searchlink = ctguid_type_scientificname.search_uri & getClonedFromTaxon.scientific_name >
									<cfset searchtext = "Find GUID" >
									<cfset searchclass = 'class="btn btn-xs btn-secondary small findGuidButton external"' >
								</cfif>
							</cfloop>
							<div class="col-6 col-xl-3 px-0 float-left">
								<select name="scientificnameid_guid_type" id="scientificnameid_guid_type" class="data-entry-select" >
									<cfif searchtext EQ "">
										<option value=""></option>
									</cfif>
									<cfloop query="ctguid_type_scientificname">
										<cfset sel="">
										<cfif getClonedFromTaxon.scientificnameid_guid_type is ctguid_type_scientificname.guid_type OR ctguid_type_scientificname.recordcount EQ 1 >
											<cfset sel="selected='selected'">
											<cfset placeholder = "#ctguid_type_scientificname.placeholder#">
											<cfset pattern = "#ctguid_type_scientificname.pattern_regex#">
											<cfset regex = "#ctguid_type_scientificname.resolver_regex#">
											<cfset replacement = "#ctguid_type_scientificname.resolver_replacement#">
										</cfif>
										<option #sel# value="#ctguid_type_scientificname.guid_type#">#ctguid_type_scientificname.guid_type#</option>
									</cfloop>
								</select>
							</div>
							<div class="col-auto px-0 float-left">
								<a href="#searchlink#" id="scientificnameid_search" target="_blank" #searchclass#>#searchtext# </a>
							</div>
							<div class="col-12 col-xl-7 pl-0 float-left">
								<input type="text" name="scientificnameid" class="data-entry-input small" id="scientificnameid" value="" 
									placeholder="#placeholder#" 
									pattern="#pattern#" title="Enter a guid in the form #placeholder#">
								<a id="scientificnameid_link" href="" target="_blank" class="px-2 py-0 d-block small line-height-sm mt-1"></a> 
								<script>
									$(document).ready(function () { 
										$('##scientificnameid').show();
										$('##scientificnameid_link').hide();
										$('##scientificnameid_search').click(function (evt) { 
											switchGuidEditToFind('scientificnameid','scientificnameid_search','scientificnameid_link',evt);
										});
										$('##scientificnameid_guid_type').change( function () { 
											// On selecting a guid_type, remove an existing guid value.
											$('##scientificnameid').val("");
											// On selecting a guid_type, change the pattern.
											getGuidTypeInfo($('##scientificnameid_guid_type').val(), 'scientificnameid', 'scientificnameid_link','scientificnameid_search',getLowestTaxon());
										});
										$('##scientificnameid').blur( function () { 
											// On loss of focus for input, validate against the regex, update link
											getGuidTypeInfo($('##scientificnameid_guid_type').val(), 'scientificnameid', 'scientificnameid_link','scientificnameid_search',getLowestTaxon());
										});
										$('##species').change( function () { 
											// On changing species name, update the search link.
											getGuidTypeInfo($('##scientificnameid_guid_type').val(), 'scientificnameid', 'scientificnameid_link','scientificnameid_search',getLowestTaxon());
										});
										$('##genus').change( function () { 
											// On changing species name, update the search link.
											getGuidTypeInfo($('##scientificnameid_guid_type').val(), 'scientificnameid', 'scientificnameid_link','scientificnameid_search',getLowestTaxon());
										});
									});
								</script> 
							</div>
						</div>
					</div>
					<div class="form-row"><!--- organize layout so that phylum, class, order, family stack in same column --->
						<div class="col-12 col-xl-3 col-md-6 px-0 float-left">
							<label for="kingdom" class="col-12 col-md-3 align-left float-left col-form-label">Kingdom</label>
							<div  class="col-12 col-md-9 float-left">
								<input type="text" name="kingdom" id="kingdom" value="#encodeForHTML(getClonedFromTaxon.kingdom)#" class="data-entry-input">
							</div>
						</div>
						<div id="phylum_row" class="col-12 col-xl-3 col-md-6 px-0 float-left">
							<label for="phylum" id="phylum_label" class="col-12 col-md-3 col-form-label align-left float-left">Phylum</label>
							<div class="col-12 col-md-9 float-left">
								<input type="text" name="phylum" id="phylum" value="#encodeForHTML(getClonedFromTaxon.phylum)#" class="data-entry-input my-1">
							</div>
						</div>
						<div class="col-12 col-md-6 col-xl-3 px-0 float-left">
							<label for="subphylum" id="subphylum_label" class="col-12 col-md-3 col-form-label align-left float-left">Subphylum</label>
							<div  class="col-12 col-md-9 float-left">
								<input type="text" name="subphylum" id="subphylum" value="#encodeForHTML(getClonedFromTaxon.subphylum)#" class="data-entry-input my-1">
							</div>
						</div>
					</div>
					<div id="division_row" class="botanical form-row">
						<div class="col-12 col-xl-3 px-0 botanical float-left">
						</div>
						<div class="col-12 col-md-6 col-xl-3 px-0 botanical float-left">
							<label for="division" id="division_label" class="col-12 col-md-3  col-form-label align-left float-left">Division</label>
							<div class="col-12 col-md-9 float-left">
								<input type="text" name="division" id="division" value="#encodeForHTML(getClonedFromTaxon.division)#" class="data-entry-input my-1">
							</div>
						</div>
						<div class="col-12 col-xl-3 col-md-6 px-0 botanical float-left">
							<label for="subdivision" id="subdivsion_label" class="col-sm-3 col-form-label align-left float-left">SubDivision</label>
							<div class="col-12 col-md-9 float-left">
								<input type="text" name="subdivision" id="subdivision" value="#encodeForHTML(getClonedFromTaxon.subdivision)#" class="data-entry-input my-1">
							</div>
						</div>
					</div>
					<div class="form-row">
						<div class="col-12 col-md-6 col-xl-3 px-0 float-left">
							<label for="superclass" class="col-12 col-md-3 pb-1 col-form-label align-left float-left">Superclass</label>
							<div class="col-12 col-md-9 float-left">
								<input type="text" name="superclass" id="superclass" value="#encodeForHTML(getClonedFromTaxon.superclass)#" class="data-entry-input my-1">
							</div>
						</div>
						<div class="col-12 col-md-6 col-xl-3 px-0 float-left">
							<label for="phylclass" class="col-12 col-md-3 pb-1 col-form-label align-left float-left">Class</label>
							<div class="col-12 col-md-9 float-left">
								<input type="text" name="phylclass" id="phylclass" value="#encodeForHTML(getClonedFromTaxon.phylclass)#" class="data-entry-input my-1">
							</div>
						</div>
						<div class="col-12 col-md-6 col-xl-3 px-0 float-left">
							<label for="subclass" class="col-12 col-md-3 pb-1 col-form-label align-left float-left">SubClass</label>
							<div class="col-12 col-md-9 float-left">
								<input type="text" name="subclass" id="subclass" value="#encodeForHTML(getClonedFromTaxon.subclass)#" class="data-entry-input my-1">
							</div>
						</div>
						<div class="col-12 col-md-6 col-xl-3 px-0 float-left">
							<label for="infraclass" class="col-12 col-md-3 pb-1 col-form-label align-left  float-left">InfraClass</label>
							<div class="col-12 col-md-9 float-left">
								<input type="text" name="infraclass" id="infraclass" value="#encodeForHTML(getClonedFromTaxon.infraclass)#" class="data-entry-input my-1">
							</div>
						</div>
					</div>
					<div class="form-row">
						<div class="col-12 col-md-6 col-xl-3 px-0 float-left">
							<label for="superorder" class="col-12 col-md-3 pb-1 col-form-label align-left float-left">Superorder</label>
							<div class="col-12 col-md-9 float-left">
								<input type="text" name="superorder" id="superorder" value="#encodeForHTML(getClonedFromTaxon.superorder)#" class="data-entry-input my-1">
							</div>
						</div>
						<div class="col-12 col-md-6 col-xl-3 px-0 float-left">
							<label for="phylorder" class="col-12 col-md-3 pb-1 col-form-label align-left float-left">Order</label>
							<div class="col-12 col-md-9 float-left">
								<input type="text" name="phylorder" id="phylorder" value="#encodeForHTML(getClonedFromTaxon.phylorder)#" class="data-entry-input my-1">
							</div>
						</div>
						<div class="col-12 col-md-6 col-xl-3 px-0 float-left">
							<label for="suborder" class="col-12 col-md-3 pb-1 col-form-labelalign-left float-left">Suborder</label>
							<div class="col-12 col-md-9 float-left">
								<input type="text" name="suborder" id="suborder" value="#encodeForHTML(getClonedFromTaxon.suborder)#" class="data-entry-input my-1">
							</div>
						</div>
						<div class="col-12 col-md-6 col-xl-3 px-0 float-left">
							<label for="infraorder" class="col-12 col-md-3 pb-1 col-form-label align-left float-left">Infraorder</label>
							<div class="col-12 col-md-9 float-left">
								<input type="text" name="infraorder" id="infraorder" value="#encodeForHTML(getClonedFromTaxon.infraorder)#" class="data-entry-input my-1">
							</div>
						</div>
					</div>
				
					<cfif len(getClonedFromTaxon.subsection) GT 0.>
						<div class="form-row col-12 px-0 mx-0">
							<div class="col-12 col-md-6 col-xl-3 px-0">
							</div>
							<div class="col-12 col-md-6 col-xl-3 px-0">
								<label for="subsection" class="col-sm-3 pb-1 col-form-label float-left">Section (zoological)</label>
								<!--- Section would go here --->
								<div class="col-12 col-md-9 float-left">
									--
								</div>
							</div>
							<div class="col-12 col-md-6 px-0">
								<label for="subsection" class="col-12 col-md-3 pb-1 col-form-label float-left">Subsection (zoological)</label>
								<div class="col-12 col-md-9 float-left">
									<input type="text" name="subsection" id="subsection" value="#encodeForHTML(getClonedFromTaxon.subsection)#" class="data-entry-input my-1">
								</div>
							</div>
							<div class="col-12 col-md-6 col-xl-3 px-0">
							</div>
						</div>
					</cfif>
							
					<div class="form-row">
						<div class="col-12 col-md-6 col-xl-3 px-0 float-left">
							<label for="superfamily" class="col-12 col-md-3 pb-1 col-form-label align-left float-left">Superfamily</label>
							<div class="col-12 col-md-9 float-left">
								<input type="text" name="superfamily" id="superfamily" value="#encodeForHTML(getClonedFromTaxon.superfamily)#" class="data-entry-input my-1">
							</div>
						</div>
						<div class="col-12 col-md-6 col-xl-3 px-0 float-left">
							<label for="family" class="col-12 col-md-3 pb-1 col-form-label align-left float-left">Family</label>
							<div class="col-12 col-md-9 float-left">
								<input type="text" name="family" id="family" value="#encodeForHTML(getClonedFromTaxon.family)#" class="data-entry-input my-1">
							</div>
						</div>
						<div class="col-12 col-md-6 col-xl-3 px-0 float-left">
							<label for="subfamily" class="col-md-3 pb-1 col-form-label align-left float-left">Subfamily</label>
							<div class="col-12 col-md-9 float-left">
								<input type="text" name="subfamily" id="subfamily" value="#encodeForHTML(getClonedFromTaxon.subfamily)#" class="data-entry-input my-1">
							</div>
						</div>
						<div class="col-12 col-md-6 col-xl-3 px-0 float-left">
							<label for="tribe" class="col-12 col-md-3 pb-1 col-form-label align-left float-left">Tribe</label>
							<div class="col-12 col-md-9 float-left">
								<input type="text" name="tribe" id="tribe" value="#encodeForHTML(getClonedFromTaxon.tribe)#" class="data-entry-input my-1">
							</div>
						</div>
					</div>
					<div class="form-row">
						<div class="col-12 col-md-6 col-xl-3 px-0 pl-md-1 float-left">
							<label for="genus" class="col-12 col-md-3 pb-1 col-form-label align-left float-left">Genus
								<span class="likeLink botanical" onClick="$('##genus').val('&##215;' + $('##genus').val());">
									<small class="link-color">Add&nbsp;&##215;</small>
								</span>
							</label>
							<div class="col-12 col-md-9 float-left">
								<input type="text" name="genus" id="genus" class="data-entry-input my-1" value="#encodeForHTML(getClonedFromTaxon.genus)#">
							</div>
						</div>
						<div class="col-12 col-md-6 col-xl-3 px-0 float-left">
							<cfif len(#getClonedFromTaxon.subgenus#) gt 0 and REFind("^\(.*\)$",#getClonedFromTaxon.subgenus#) gt 0>
								<cfset subgenus_message = "Do Not include parethesies">
							</cfif>
							<label for="subgenus" class="col-12 col-md-3 pb-1 col-form-label align-left float-left">Subgenus</label>
							<div class="col-12 col-md-9 float-left">
								<span class="float-left d-inline brackets mt-1">( </span>
								<input type="text" name="subgenus" id="subgenus" value="#encodeForHTML(getClonedFromTaxon.subgenus)#" class="data-entry-input m-1 w-75 float-left">
								<span class="float-left d-inline brackets mt-1">)</span><small class="text-danger float-left mx-3"> #subgenus_message# </small> 
							</div>
						</div>
			
						<div class="col-12 col-md-6 col-xl-3 px-0 float-left">
							<label for="species" class="col-12 col-md-3 pb-1 col-form-label align-left float-left">Species</label>
							<div class="col-12 col-md-9 float-left">
								<input type="text" name="species" id="species" class="data-entry-input my-1" value="#encodeForHTML(getClonedFromTaxon.species)#">
							</div>
						</div>		
						<div class="col-12 col-md-6 col-xl-3 px-0 float-left">
							<label for="subspecies" class="col-12 col-md-3 pb-1 col-form-label align-left float-left">Subspecies</label>
							<div class="col-12 col-md-9 float-left">
								<input type="text" name="subspecies" id="subspecies" value="#encodeForHTML(getClonedFromTaxon.subspecies)#" class="data-entry-input my-1">
							</div>
						</div>
					</div>

					<div class="form-row">
						<div class="col-12 col-md-6 col-xl-3 px-0 float-left">
							<label for="infraspecific_rank" class="col-12 col-md-4 pb-1 col-form-label align-left float-left"><span>Infraspecific Rank</span></label>
							<div class="col-12 col-md-8 float-left">
								<select name="infraspecific_rank" id="infraspecific_rank" class="data-entry-select my-1" data-style="btn-primary" show-tick>
									<option value=""></option>
									<cfloop query="ctInfRank">
										<option
											<cfif getClonedFromTaxon.infraspecific_rank is ctinfrank.infraspecific_rank> selected="selected" </cfif>
											value="#ctInfRank.infraspecific_rank#">#ctInfRank.infraspecific_rank#</option>
									</cfloop>
								</select>
							</div>
						</div>
					
						<div class="col-12 col-md-4 col-xl-7 px-0 float-left">
							<label for="author_text" class="col-12 col-md-2 col-xl-1 pb-1 col-form-label align-left float-left">Author <small>(inc. year)</small></label>
							<div class="col-12 col-md-10 col-xl-11 float-left">
								<input type="text" name="author_text" id="author_text" value="#encodeForHTML(getClonedFromTaxon.author_text)#" class="data-entry-input mt-1">
								<span class="infoLink botanical"
									onclick=" window.open('https://ipni.org/?q='+$('##genus').val()+'%20'+$('##species').val(),'_blank'); ">
									 <small class="link-color">Find in IPNI</small>
								</span>
							 </div>
						</div>
						<div class="col-12 col-md-2 col-xl-2 px-0 float-left">
							<label for="year_of_publication" class="col-12 col-md-2 col-xl-1 col-form-label pb-0 align-left float-left">Year</label>
							<div class="col-12 col-md-10 col-xl-11 mb-2 float-left">
								<input type="text" name="year_of_publication" id="year_of_publication" value="#encodeForHTML(gettaxa.year_of_publication)#" class="data-entry-input mt-1">
							 </div>
						</div>
					</div>

					<div class="form-row col-12 px-0 botanical">
						<div class="col-12 col-md-6 col-xl-3 botanical">
						</div>
						<div class="col-12 col-md-6 col-xl-9 my-1 px-0 botanical">
							<label for="infraspecific_author" id="infraspecific_author_label" class="py-0 py-xl-1 col-12 col-md-12 col-xl-1 col-form-label align-left float-left"> Infraspecific Author </label>
							<div class="col-12 col-md-12 col-xl-11 float-left pr-1">
								<input type="text" name="infraspecific_author" id="infraspecific_author" class="data-entry-input mt-1" value="#encodeForHTML(getClonedFromTaxon.infraspecific_author)#">
								<span class="infoLink botanical" 
									onclick=" window.open('https://ipni.org/?q='+$('##genus').val()+'%20'+$('##species').val()+'%20'+$('##subspecies').val(),'_blank'); ">
									<small class="link-color">Find in IPNI</small> 
								</span>
								<span class="small line-height-sm d-block d-md-inline ml-2 text-secondary float-right">(do not use infraspecific author for ICZN names)</span>
							</div>
						</div>
					</div>
						
					<div class="form-row px-0 mb-3">
						<div class="col-12 px-0 mt-0">
							<label for="taxon_remarks" class="col-12 col-md-3 mt-1 col-form-label float-left text-right">Remarks (<span id="length_taxon_remarks">0 characters 4000 left</span>)</label>
							<div class="col-12 col-md-9 float-left">
							<textarea name="taxon_remarks" id="taxon_remarks" 
								onkeyup="countCharsLeft('taxon_remarks', 4000, 'length_taxon_remarks');"
								rows="3" class="data-entry-textarea col-12 mt-1 autogrow">#encodeForHTML(getClonedFromTaxon.taxon_remarks)#</textarea>
							</div>
						</div>
						<script>
							// Make all textareas currently defined autogrow as text is entered.
							$("textarea").keyup(autogrow);
							$(document).ready(function() { 
								// trigger autogrow event on autogrow text areas
								$('textarea.autogrow').keyup();
							});
						</script>
					</div>

					<div class="row mt-1">
						<div class="col-12">
							<input type="submit" value="Create" title="Create" class="btn btn-xs btn-primary" aria-label="Save and create new taxon record">
						</div>
					</div>

				</form>
			</div>
		</main>
	</cfoutput>
</cfif>
<!---------------------------------------------------------------------------------------------------->
<cfif action is "saveNewTaxon">
	<cfoutput>
		<cftransaction>
			<cftry>
					<cfquery name="nextID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						select sq_taxon_name_id.nextval nextID from dual
					</cfquery>
					<cfquery name="newTaxon" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					INSERT INTO taxonomy (
						taxon_name_id,
						valid_catalog_term_fg,
						source_authority
					<cfif len(#author_text#) gt 0>
						,author_text
					</cfif>
					<cfif len(#year_of_publication#) gt 0>
						,year_of_publication
					</cfif>
					<cfif len(#taxonid_guid_type#) gt 0>	
						,taxonid_guid_type 
					</cfif>
					<cfif len(#taxonid#) gt 0>	
						,taxonid
					</cfif>
					<cfif len(#scientificnameid_guid_type#) gt 0>	
						,scientificnameid_guid_type 
					</cfif>
					<cfif len(#scientificnameid#) gt 0>	
						,scientificnameid
					</cfif>
					<cfif len(#tribe#) gt 0>
						,tribe
					</cfif>
					<cfif len(#infraspecific_rank#) gt 0>
						,infraspecific_rank
					</cfif>
					<cfif len(#phylclass#) gt 0>
						,phylclass
					</cfif>
					<cfif len(#phylorder#) gt 0>
						,phylorder
					</cfif>
					<cfif len(#suborder#) gt 0>
						,suborder
					</cfif>
					<cfif len(#family#) gt 0>
						,family
					</cfif>
					<cfif len(#subfamily#) gt 0>
						,subfamily
					</cfif>
					<cfif len(#genus#) gt 0>
						,genus
					</cfif>
					<cfif len(#subgenus#) gt 0>
						,subgenus
					</cfif>
					<cfif len(#species#) gt 0>
						,species
					</cfif>
					<cfif len(#subspecies#) gt 0>
						,subspecies
					</cfif>
					<cfif len(#taxon_remarks#) gt 0>
						,taxon_remarks
					</cfif>
					<cfif len(#phylum#) gt 0>
						,phylum
					</cfif>
					<cfif len(#infraspecific_author#) gt 0>
						,infraspecific_author
					</cfif>
					<cfif len(#kingdom#) gt 0>
						,kingdom
					</cfif>
					<cfif len(#nomenclatural_code#) gt 0>
						,nomenclatural_code
					</cfif>
					<cfif len(#subphylum#) gt 0>
						,subphylum
					</cfif>
					<cfif len(#superclass#) gt 0>
						,superclass
					</cfif>
					<cfif len(#subclass#) gt 0>
						,subclass
					</cfif>
					<cfif len(#superorder#) gt 0>
						,superorder
					</cfif>
					<cfif len(#infraorder#) gt 0>
						,infraorder
					</cfif>
					<cfif len(#superfamily#) gt 0>
						,superfamily
					</cfif>
					<cfif len(#division#) gt 0>
						,division
					</cfif>
					<cfif len(#subdivision#) gt 0>
						,subdivision
					</cfif>
					<cfif isdefined("subsection") AND len(#subsection#) gt 0>
						,subsection
					</cfif>
					<cfif len(#infraclass#) gt 0>
						,infraclass
					</cfif>
					<cfif len(#taxon_status#) gt 0>
						,taxon_status
					</cfif>
					) VALUES (
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#nextID.nextID#">,
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#valid_catalog_term_fg#">,
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#source_authority#">
					<cfif len(#author_text#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(author_text)#">
					</cfif>
					<cfif len(#year_of_publication#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(year_of_publication)#">
					</cfif>
					<cfif len(#taxonid_guid_type#) gt 0>	
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#taxonid_guid_type#">
					</cfif>
					<cfif len(#taxonid#) gt 0>	
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#taxonid#">
					</cfif>
					<cfif len(#scientificnameid_guid_type#) gt 0>	
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#scientificnameid_guid_type#">
					</cfif>
					<cfif len(#scientificnameid#) gt 0>	
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#scientificnameid#">
					</cfif>
					<cfif len(#tribe#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(tribe)#">
					</cfif>
					<cfif len(#infraspecific_rank#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(infraspecific_rank)#">
					</cfif>
					<cfif len(#phylclass#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(phylclass)#">
					</cfif>
					<cfif len(#phylorder#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(phylorder)#">
					</cfif>
					<cfif len(#suborder#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(suborder)#">
					</cfif>
					<cfif len(#family#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(family)#">
					</cfif>
					<cfif len(#subfamily#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(subfamily)#">
					</cfif>
					<cfif len(#genus#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(genus)#">
					</cfif>
					<cfif len(#subgenus#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(subgenus)#">
					</cfif>
					<cfif len(#species#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(species)#">
					</cfif>
					<cfif len(#subspecies#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(subspecies)#">
					</cfif>
					<cfif len(#taxon_remarks#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(taxon_remarks)#">
					</cfif>
					<cfif len(#phylum#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#phylum#">
					</cfif>
					<cfif len(#infraspecific_author#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(infraspecific_author)#">
					</cfif>
					<cfif len(#kingdom#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(kingdom)#">
					</cfif>
					<cfif len(#nomenclatural_code#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#nomenclatural_code#">
					</cfif>
					<cfif len(#subphylum#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(subphylum)#">
					</cfif>
					<cfif len(#superclass#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(superclass)#">
					</cfif>
				 	<cfif len(#subclass#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(subclass)#">
					</cfif>
					<cfif len(#superorder#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(superorder)#">
					</cfif>
					<cfif len(#infraorder#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(infraorder)#">
					</cfif>
					<cfif len(#superfamily#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(superfamily)#">
					</cfif>
					<cfif len(#division#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(division)#">
					</cfif>
					<cfif len(#subdivision#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(subdivision)#">
					</cfif>
					<cfif isdefined("subsection") AND len(#subsection#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(subsection)#">
					</cfif>
					<cfif len(#infraclass#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(infraclass)#">
					</cfif>
					<cfif len(#taxon_status#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(taxon_status)#">
					</cfif>
					)
				</cfquery>
				<cftransaction action="commit">
				<cflocation url="/taxonomy/Taxonomy.cfm?Action=edit&taxon_name_id=#nextID.nextID#" addtoken="false">
			<cfcatch>
				<cftransaction action="rollback">
				<cfset ruleFailure = false>
				<cfif cfcatch.detail contains "ORA-01400">
					<!--- expected failure when rules for nomenclatural code are not met: [Macromedia][Oracle JDBC Driver][Oracle]ORA-01400: cannot insert NULL into ("MCZBASE"."TAXONOMY"."FULL_TAXON_NAME") --->
					<cfset ruleFailure = true>
				</cfif>
				<section class="container">
					<div class="row">
						<div class="alert alert-danger" role="alert">
							<img src="/shared/images/Process-stop.png" alt="[ Error ]" style="float:left; width: 50px;margin-right: 1em;">
							<h1 class="h2">Creation of new taxon record failed.<h1>
							<cfif ruleFailure >
								<p>The content of one or more fields did not match the rules for the selected nomeclatural code
									<cfif isdefined("nomenclatural_code") AND len(#nomenclatural_code#) gt 0>#nomenclatural_code#</cfif>.
									A higher taxon name may not be properly capitialized, there may be spaces or unexpected characters in a taxon name.
									Historical names may not comply with the ICZN rules, an may need to be entered with a nomenclatural code of "noncompliant".
									Go back, check the values for errors, and try saving again.
								</p>
							<cfelse>
								<p>There was an error creating this taxon record, please file a bug report describing the problem.</p>
								<p><a href="/info/bugs.cfm">“Feedback/Report Errors”</a></p>
							</cfif>
						</div>
					</div>
					<cfif NOT ruleFailure >
						<p><cfdump var=#cfcatch#></p>
					</cfif>
				</section>
			</cfcatch>
			</cftry>
		</cftransaction>
	</cfoutput>
</cfif>
<!---------------------------------------------------------------------------------------------------->

<cfinclude template="/shared/_footer.cfm">
