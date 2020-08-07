<cfset pageTitle = "Edit Taxon">
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
<cfinclude template = "/shared/_header.cfm">
<cfquery name="ctInfRank" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select infraspecific_rank from ctinfraspecific_rank order by infraspecific_rank
</cfquery>
<cfquery name="ctRelation" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select taxon_relationship  from cttaxon_relation order by taxon_relationship
</cfquery>
<cfquery name="ctSourceAuth" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select source_authority from CTTAXONOMIC_AUTHORITY order by source_authority
</cfquery>
<cfquery name="ctnomenclatural_code" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select nomenclatural_code from ctnomenclatural_code order by sort_order
</cfquery>
<cfquery name="cttaxon_status" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select taxon_status from cttaxon_status order by taxon_status
</cfquery>
<cfquery name="cttaxon_habitat" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select taxon_habitat from cttaxon_habitat order by taxon_habitat
</cfquery>
<cfquery name="ctguid_type_taxon" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select guid_type, placeholder, pattern_regex, resolver_regex, resolver_replacement, search_uri
   from ctguid_type 
   where applies_to like '%taxonomy.taxonid%'
</cfquery>
<cfquery name="ctguid_type_scientificname" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
<!------------------------------------------------>
<cfif action is "nothing">
	<cfheader statuscode="301" statustext="Moved permanently">
	<cfheader name="Location" value="/Taxa.cfm">
	<cfabort>
</cfif>
<!---------------------------------------------------------------------------------------------------->
<cfif action is "edit">
<cfset title="Edit Taxonomy">
<cfquery name="getTaxa" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select * from taxonomy where taxon_name_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#taxon_name_id#">
	</cfquery>
<cfquery name="isSourceAuthorityCurrent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select count(*) as ct from CTTAXONOMIC_AUTHORITY where source_authority = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#gettaxa.source_authority#">
	</cfquery>
<cfoutput>
		<div class="container">
			<div class="row">
				<div class="col-12 mb-3">
					<div class="row">
						<h1 class="h2" id="content">Edit Taxon:
							<span id="scientificNameAndAuthor">#getTaxa.display_name# <span class="sm-caps">#getTaxa.author_text#</span></span>
							<i class="fas fas-info fa-info-circle mr-2" onClick="getMCZDocs('Edit_Taxonomy')" aria-label="help link"></i>
						</h1>
						<!---  Check to see if this record currently has a GUID assigned, record so change on edit can be warned --->
						<cfif len(getTaxa.taxonid) GT 0>
							<cfset hasTaxonID = true>
							<cfelse>
							<cfset hasTaxonID = false>
						</cfif>
					</div>
					<div class="row">
						<span>
						<a class="btn-info btn-sm" href="/name/#getTaxa.scientific_name#" target="_blank">View Details</a>
							<em>Placed in:</em> #ListDeleteAt(getTaxa.full_taxon_name,ListLen(getTaxa.full_taxon_name," ")," ")#
						</span>
					</div>
				</div>
				<form name="taxon_form" method="post" action="Taxonomy.cfm" id="taxon_form" class="w-100 pb-1 float-left border rounded">
					<div class="tInput form-row mx-2 my-1">
						<div class="col-12 col-sm-5">
							<input type="hidden" id="taxon_name_id" name="taxon_name_id" value="#getTaxa.taxon_name_id#">
							<input type="hidden" id="method" name="method" value="saveTaxonomy" >
							
							<label for="source_authority">Source
								<cfif isSourceAuthorityCurrent.ct eq 0>
									(#getTaxa.source_authority#)
								</cfif>
							</label>
							<select name="source_authority" id="source_authority" class="reqdClr custom-select data-entry-select" required>
								<cfif isSourceAuthorityCurrent.ct eq 0>
									<option value="" selected="selected"></option>
								</cfif>
								<cfloop query="ctSourceAuth">
									<option <cfif isSourceAuthorityCurrent.ct eq 1 and gettaxa.source_authority is ctsourceauth.source_authority> selected="selected" </cfif>
										value="#ctSourceAuth.source_authority#">#ctSourceAuth.source_authority#</option>
								</cfloop>
							</select>
						</div>
						<div class="col-12 col-sm-2">
							<label for="valid_catalog_term_fg"><span>ValidForCatalog?</span></label>
							<select name="valid_catalog_term_fg" id="valid_catalog_term_fg" class="reqdClr custom-select data-entry-select" required>
								<option <cfif getTaxa.valid_catalog_term_fg is "1"> selected="selected" </cfif> value="1">yes</option>
								<option <cfif getTaxa.valid_catalog_term_fg is "0"> selected="selected" </cfif> value="0">no</option>
							</select>
						</div>
						<div class="col-12 col-sm-2">
							<label for="nomenclatural_code"><span>Nomenclatural Code</span></label>
							<select name="nomenclatural_code" id="nomenclatural_code" size="1" class="reqdClr custom-select data-entry-select" required>
								<cfloop query="ctnomenclatural_code">
									<option <cfif gettaxa.nomenclatural_code is ctnomenclatural_code.nomenclatural_code> selected="selected" </cfif>
										value="#ctnomenclatural_code.nomenclatural_code#">#ctnomenclatural_code.nomenclatural_code#</option>
								</cfloop>
							</select>
						</div>
						<div class="col-12 col-sm-3">
							<label for="taxon_status" >Nomenclatural Status <i class="fas fas-info fa-info-circle" onclick="getCtDoc('cttaxon_status');" aria-label="help link"></i></label>
							<select name="taxon_status" id="taxon_status" class="data-entry-input">
								<option value=""></option>
								<cfloop query="cttaxon_status">
									<option 
										<cfif gettaxa.taxon_status is cttaxon_status.taxon_status> selected="selected" </cfif>
										value="#cttaxon_status.taxon_status#">#cttaxon_status.taxon_status#</option>
								</cfloop>
							</select>
						</div>
					</div>
					<div class="form-row col-12 mb-2">
						<div class="col-12 col-md-6 border bg-light row pb-2 ml-0 pr-0 rounded mt-2 pl-2">
							<label for="taxonid" class="data-entry-label">GUID for Taxon (dwc:taxonID)</label>
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
										<cfset searchtext = "Replace <i class='fas fa-external-link-alt'></i>" >
										<cfelse>
										<cfset searchtext = "Find GUID <i class='fas fa-external-link-alt'></i>" >
									</cfif>
									<cfset searchclass = 'class="btn-xs btn-secondary"' >
								</cfif>
							</cfloop>
							<div class="col-7 col-md-4 px-0 float-left">
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
							<div class="col-5 col-md-3 w-100 px-0 float-left"> 
								<a href="#searchlink#" id="taxonid_search" style="font-size: 88%" target="_blank" #searchclass# >#searchtext# </a> 
							</div>
							<div class="col-12 col-md-12 pl-0 float-left">
								<input type="text" name="taxonid" id="taxonid" value="#gettaxa.taxonid#" 
									placeholder="#placeholder#" pattern="#pattern#" title="Enter a guid in the form #placeholder#" 
									class="px-2 border w-100 rounded py-0">
								<cfif len(regex) GT 0 >
									<cfset link = REReplace(gettaxa.taxonid,regex,replacement)>
									<cfelse>
									<cfset link = gettaxa.taxonid>
								</cfif>
								<a id="taxonid_link" href="#link#" target="_blank" class="px-2 py-0">#gettaxa.taxonid#</a> 
								<script>
									$(document).ready(function () { 
										if ($('##taxonid').val().length > 0) {
											$('##taxonid').hide();
											$('##taxonid_link').show();
										} else { 
											$('##taxonid').show();
											$('##taxonid_link').hide();
										}
										$('##taxonid_search').click(function () { 
											$('##taxonid').show();
											$('##taxonid_link').hide();
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
						<div class="col-12 col-md-6 border bg-light row ml-4 ml-4 rounded mt-2 mb-0 pt-0 pb-2 pl-2">
							<label for="scientificnameid" class="data-entry-label">GUID for Nomenclatural Act (dwc:scientificNameID)</label>
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
										<cfset searchtext = "Replace <i class='fas fa-external-link-alt'></i>" >
										<cfelse>
										<cfset searchtext = "Find GUID <i class='fas fa-external-link-alt'></i>" >
									</cfif>
									<cfset searchclass = 'class="btn-xs btn-secondary"' >
								</cfif>
							</cfloop>
							<div class="col-7 col-md-3 px-0 float-left">
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
							<div class="col-5 col-md-3 px-0 float-left">
								<a href="#searchlink#" id="scientificnameid_search" style="font-size: 88%;" target="_blank" #searchclass#>#searchtext# </a>
							</div>
							<div class="col-12 col-md-12 pl-0 float-left">
								<input type="text" name="scientificnameid" class="px-2 border w-100 rounded py-0" id="scientificnameid" value="#gettaxa.scientificnameid#" 
									placeholder="#placeholder#" 
									pattern="#pattern#" title="Enter a guid in the form #placeholder#">
								<cfif len(regex) GT 0 >
									<cfset link = REReplace(gettaxa.scientificnameid,regex,replacement)>
								<cfelse>
									<cfset link = gettaxa.scientificnameid>
								</cfif>
								<a id="scientificnameid_link" href="#link#" target="_blank" class="px-2 py-0" style="font-size: 80%;">#gettaxa.scientificnameid#</a> 
								<script>
									$(document).ready(function () { 
										if ($('##scientificnameid').val().length > 0) {
											$('##scientificnameid').hide();
											$('##scientificnameid_link').show();
										} else { 
											$('##scientificnameid').show();
											$('##scientificnameid_link').hide();
										}
										$('##scientificnameid_search').click(function () { 
											$('##scientificnameid').show();
											$('##scientificnameid_link').hide();
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
					<div class="form-row col-12 px-0 botanical">
						<div class="col-6 px-0 botanical">
							<label for="infraspecific_author" id="infraspecific_author_label" class="col-sm-5 col-form-label float-left"> Infraspecific Author <small class="line-height-sm d-block">(do not use for ICZN names)</small></label>
							<div class="col-sm-7 float-left">
								<input type="text" name="infraspecific_author" id="infraspecific_author" class="custom-select data-entry-select mt-2" value="#gettaxa.infraspecific_author#">
								<span class="infoLink botanical" 
									onclick="window.open('/taxonomy/KewAbbrPick.cfm?tgt=infraspecific_author','picWin','width=700,height=400, resizable,scrollbars')"> 
									<small class="link-color">Find Kew Abbr</small>
								</span>
							</div>
						</div>
					</div>
					<div class="form-row col-12 px-0">
						<div class="col-12 col-md-3 px-0">
							<label for="kingdom" class="col-12 col-md-3 col-form-label float-left">Kingdom</label>
							<div  class="col-12 col-md-9 float-left">
								<input type="text" name="kingdom" id="kingdom" value="#gettaxa.kingdom#" class="data-entry-input my-1">
							</div>
						</div>
						<div id="phylum_row" class="col-12 col-md-3 px-0">
							<label for="phylum" id="phylum_label" class="col-12 col-md-3 col-form-label float-left">Phylum</label>
							<div class="col-12 col-md-9 float-left">
								<input type="text" name="phylum" id="phylum" value="#gettaxa.phylum#" class="data-entry-input my-1">
							</div>
						</div>
						<div class="col-12 col-md-3 px-0">
							<label for="subphylum" id="subphylum_label" class="col-12 col-md-3 col-form-label float-left">Subphylum</label>
							<div  class="col-12 col-md-9 float-left">
								<input type="text" name="subphylum" id="subphylum" value="#gettaxa.subphylum#" class="data-entry-input my-1">
							</div>
						</div>
						<div class="col-12 col-md-3 px-0">
						</div>
					</div>
					<div id="division_row" class="form-row col-12 px-0 botanical">
						<div class="col-3 px-0">
						</div>
						<div class="col-12 col-md-3 px-0 botanical">
							<label for="division" id="division_label" class="col-12 col-md-3 col-form-label float-left">Division</label>
							<div class="col-12 col-md-9 float-left">
								<input type="text" name="division" id="division" value="#gettaxa.division#" class="data-entry-input my-1">
							</div>
						</div>
						<div class="col-12 col-md-3 px-0 botanical">
							<label for="subdivision" id="subdivsion_label" class="col-sm-3 col-form-label float-left">SubDivision</label>
							<div class="col-12 col-md-9 float-left">
								<input type="text" name="subdivision" id="subdivision" value="#gettaxa.subdivision#" class="data-entry-input my-1">
							</div>
						</div>
						<div class="col-12 col-md-3 px-0">
						</div>
					</div>
					<div class="form-row col-12 px-0">
						<div class="col-12 col-md-3 px-0">
							<label for="superclass" class="col-12 col-md-3 col-form-label float-left">Superclass</label>
							<div class="col-12 col-md-9 float-left">
								<input type="text" name="superclass" id="superclass" value="#gettaxa.superclass#" class="data-entry-input my-1">
							</div>
						</div>
						<div class="col-12 col-md-3 px-0">
							<label for="phylclass" class="col-12 col-md-3 col-form-label float-left">Class</label>
							<div class="col-12 col-md-9 float-left">
								<input type="text" name="phylclass" id="phylclass" value="#gettaxa.phylclass#" class="data-entry-input my-1">
							</div>
						</div>
						<div class="col-12 col-md-3 px-0">
							<label for="subclass" class="col-12 col-md-3 col-form-label float-left">SubClass</label>
							<div class="col-12 col-md-9 float-left">
								<input type="text" name="subclass" id="subclass" value="#gettaxa.subclass#" class="data-entry-input my-1">
							</div>
						</div>
						<div class="col-12 col-md-3 px-0">
							<label for="infraclass" class="col-12 col-md-3 col-form-label float-left">InfraClass</label>
							<div class="col-12 col-md-9 float-left">
								<input type="text" name="infraclass" id="infraclass" value="#gettaxa.infraclass#" class="data-entry-input my-1">
							</div>
						</div>
					</div>
					<div class="form-row col-12 px-0">
						<div class="col-12 col-md-3 px-0">
							<label for="superorder" class="col-12 col-md-3 col-form-label float-left">Superorder</label>
							<div class="col-12 col-md-9 float-left">
								<input type="text" name="superorder" id="superorder" value="#gettaxa.superorder#" class="data-entry-input my-1">
							</div>
						</div>
						<div class="col-12 col-md-3 px-0">
							<label for="phylorder" class="col-12 col-md-3 col-form-label float-left">Order</label>
							<div class="col-12 col-md-9 float-left">
								<input type="text" name="phylorder" id="phylorder" value="#gettaxa.phylorder#" class="data-entry-input my-1">
							</div>
						</div>
						<div class="col-12 col-md-3 px-0">
							<label for="suborder" class="col-12 col-md-3 col-form-label float-left">Suborder</label>
							<div class="col-12 col-md-9 float-left">
								<input type="text" name="suborder" id="suborder" value="#gettaxa.suborder#" class="data-entry-input my-1">
							</div>
						</div>
						<div class="col-12 col-md-3 px-0">
							<label for="infraorder" class="col-12 col-md-3 col-form-label float-left">Infraorder</label>
							<div class="col-12 col-md-9 float-left">
								<input type="text" name="infraorder" id="infraorder" value="#gettaxa.infraorder#" class="data-entry-input my-1">
							</div>
						</div>
					</div>
					<cfif len(gettaxa.subsection) GT 0.>
						<div class="form-row col-12 px-0">
							<div class="col-12 col-md-3 px-0">
							</div>
							<div class="col-12 col-md-3 px-0">
								<label for="subsection" class="col-sm-3 col-form-label float-left">Section (zoological)</label>
								<!--- Section would go here --->
								<div class="col-12 col-md-9 float-left">
									--
								</div>
							</div>
							<div class="col-12 col-md-3 px-0">
								<label for="subsection" class="col-12 col-md-3 col-form-label float-left">Subsection (zoological)</label>
								<div class="col-12 col-md-9 float-left">
									<input type="text" name="subsection" id="subsection" value="#gettaxa.subsection#" class="data-entry-input my-1">
								</div>
							</div>
							<div class="col-12 col-md-3 px-0">
							</div>
						</div>
					</cfif>
					<div class="form-row col-12 px-0">
						<div class="col-12 col-md-3 px-0">
							<label for="superfamily" class="col-sm-3 col-form-label float-left">Superfamily</label>
							<div class="col-12 col-md-9 float-left">
								<input type="text" name="superfamily" id="superfamily" value="#gettaxa.superfamily#" class="data-entry-input my-1">
							</div>
						</div>
						<div class="col-12 col-md-3 px-0">
							<label for="family" class="col-12 col-md-3 col-form-label float-left">Family</label>
							<div class="col-12 col-md-9 float-left">
								<input type="text" name="family" id="family" value="#gettaxa.family#" class="data-entry-input my-1">
							</div>
						</div>
						<div class="col-12 col-md-3 px-0">
							<label for="subfamily" class="col-sm-3 col-form-label float-left">Subfamily</label>
							<div class="col-12 col-md-9 float-left">
								<input type="text" name="subfamily" id="subfamily" value="#gettaxa.subfamily#" class="data-entry-input my-1">
							</div>
						</div>
						<div class="col-12 col-md-3 px-0">
							<label for="tribe" class="col-12 col-md-3 col-form-label float-left">Tribe</label>
							<div class="col-12 col-md-9 float-left">
								<input type="text" name="tribe" id="tribe" value="#gettaxa.tribe#" class="data-entry-input my-1">
							</div>
						</div>
					</div>
					<div class="form-row col-12 px-0">
						<div class="col-12 col-md-3 px-0">
						</div>
						<div class="col-12 col-md-3 px-0">
							<label for="genus" class="col-12 col-md-3 col-form-label float-left">Genus</label>
								<span class="likeLink botanical" onClick="$('##genus').val('&##215;' + $('##genus').val());">
									<small class="link-color">Add &##215;</small>
								</span>
							</label>
							<div class="col-12 col-md-9 float-left">
								<input type="text" name="genus" id="genus" class="data-entry-input my-1" value="#gettaxa.genus#">
							</div>
						</div>
						<div class="col-12 col-md-3 px-0">
							<cfif len(#gettaxa.subgenus#) gt 0 and REFind("^\(.*\)$",#gettaxa.subgenus#) gt 0>
								<cfset subgenus_message = "Do Not include parethesies">
							</cfif>
							<label for="subgenus" class="col-12 col-md-3 col-form-label float-left">Subgenus</label>
							<div class="col-12 col-md-9 float-left"><span class="float-left d-inline brackets">(</span>
								<input type="text" name="subgenus" id="subgenus" value="#gettaxa.subgenus#" class="data-entry-input my-1 w-75 float-left">
								<span class="float-left d-inline brackets">)</span><small class="text-danger float-left mx-3"> #subgenus_message# </small> </div>
						</div>
						<div class="col-12 col-md-3 px-0">
						</div>
					</div>
					<div class="form-row col-12 px-0">
						<div class="col-12 col-md-3 px-0">
						</div>
						<div class="col-12 col-md-3 px-0">
							<label for="species" class="col-12 col-md-3 col-form-label float-left">Species</label>
							<div class="col-12 col-md-9 float-left">
								<input type="text" name="species" id="species" class="data-entry-input my-1" value="#gettaxa.species#">
							</div>
						</div>		
						<div class="col-12 col-md-3 px-0">
							<label for="subspecies" class="col-12 col-md-3 col-form-label float-left">Subspecies</label>
							<div class="col-12 col-md-9 float-left">
								<input type="text" name="subspecies" id="subspecies" value="#gettaxa.subspecies#" class="data-entry-input my-1">
							</div>
						</div>
						<div class="col-12 col-md-3 px-0">
							<label for="infraspecific_rank" class="col-12 col-md-6 col-form-label float-left"><span>Infraspecific&nbsp;Rank</span></label>
							<div class="col-12 col-md-6 float-left">
								<select name="infraspecific_rank" id="infraspecific_rank" class="custom-select data-entry-input my-1" data-style="btn-primary" show-tick>
									<option value=""></option>
									<cfloop query="ctInfRank">
										<option
											<cfif gettaxa.infraspecific_rank is ctinfrank.infraspecific_rank> selected="selected" </cfif>
											value="#ctInfRank.infraspecific_rank#">#ctInfRank.infraspecific_rank#</option>
									</cfloop>
								</select>
							</div>
						</div>
					</div>
					<div class="form-row col-12 px-0">
						<div class="col-12 col-md-3 px-0">
						</div>
						<div class="col-12 col-md-6 px-0">
							<label for="author_text" class="col-12 col-md-2 col-form-label float-left">Author</label>
							<div class="col-12 col-md-10 float-left">
								<input type="text" name="author_text" id="author_text" value="#gettaxa.author_text#" class="data-entry-input mt-1">
								<span class="infoLink botanical"
									onclick="window.open('/taxonomy/KewAbbrPick.cfm?tgt=author_text','picWin','width=700,height=400, resizable,scrollbars')">
									 <small class="link-color">Find Kew Abbr</small>
								</span>
							 </div>
						</div>
						<div class="col-12 col-md-3 px-0">
						</div>
					</div>
					<div class="form-row col-12 px-0">
						<div class="col-12 px-0">
							<label for="taxon_remarks" class="col-12 col-md-3 text-right col-form-label float-left">Remarks (<span id="length_taxon_remarks">0 characters 4000 left</span>)</label>
							<div class="col-12 col-md-9 float-right">
								<textarea name="taxon_remarks" id="taxon_remarks" 
									onkeyup="countCharsLeft('taxon_remarks', 4000, 'length_taxon_remarks');"
									rows="3" class="data-entry-textarea mt-1">#gettaxa.taxon_remarks#</textarea>
							</div>
						</div>
					</div>
					<script>
						// Make all textareas currently defined autogrow as text is entered.
						$("textarea").keyup(autogrow);  
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
											data :  $('##taxon_form').serialize(),
											success : function (data) {
												$('##saveResultDiv').html('Saved.');
												$('##saveResultDiv').addClass('text-success');
												$('##saveResultDiv').removeClass('text-danger');
												$('##saveResultDiv').removeClass('text-warning');
												loadTaxonName(#getTaxa.taxon_name_id#,'scientificNameAndAuthor');
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
						$( document ).ready(loadTaxonName(#taxon_name_id#,'scientificNameAndAuthor'));
					</script>
					<div class="form-row col-12 px-0 justify-content-center mt-2">
						<input type="button" 
							value="Save" title="Save" aria-label="Save"
							class="btn btn-xs btn-primary mx-1"
							onClick="if (checkFormValidity($('##taxon_form')[0])) { saveEdits();  } " 
							>
						<input type="button" value="Clone" class="btn-xs btn-secondary mx-1" onclick="taxon_form.Action.value='newTaxon';submit();">
						<input type="button" value="Delete" class="btn-xs btn-danger mx-1"	onclick="taxon_form.Action.value='deleTaxa';confirmDelete('taxon_form');">
					
					</div>
					<div id="saveResultDiv" class="text-danger mx-auto text-center">&nbsp;</div>	
				</form>

				<div class="col-12 mt-3 mb-5 px-0">
					<div class="border rounded p-2 bg-grayish float-left w-100">
						<div class="col-12">
						<div class="form-row mx-0 mt-2 p-3 border bg-light rounded">	
						
								<div class="col-12">
									<h4 class="mt-0 mb-1">Related Publications</h4>
									<label for="new_pub_formatted" class="data-entry-label">Pick Publication</label>
									<span>
										<input type="text" id="new_pub_formatted" name="newPub" class="data-entry-input col-12 col-md-9 float-left">
										<form name="newPubForm" id="newPubForm">
											<div class="col-12 col-sm-3 pl-1 pr-0 float-left">
												<input type="submit" value="Add" class="insBtn btn-xs btn-secondary">
											</div>
									<input type="hidden" name="taxon_name_id" value="#getTaxa.taxon_name_id#">
									<input type="hidden" name="method" value="newTaxonPub">
									<input type="hidden" name="publication_id" id="publication_id">
										</form>
									</span>
								</div>
								<div id="taxonPublicationsDiv" class="col-12 mx-0 row mt-3 float-left"></div>
						</div>
					</div>
						<script>
						$( document ).ready(
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
						);
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

						<div class="col-12 px-3">
						<form name="newRelation" method="post" action="/taxonomy/Taxonomy.cfm">
							<input type="hidden" name="taxon_name_id" value="#getTaxa.taxon_name_id#">
							<input type="hidden" name="Action" value="newTaxonRelation">
							<div class="p-3 border bg-light rounded mt-3">
								<h4 class="mt-0 mb-1">Related Taxa:</h4>
								<label for="taxon_relationship" class="data-entry-label">Add Relationship</label>
								<select name="taxon_relationship" class="reqdClr custom-select data-entry-select">
									<cfloop query="ctRelation">
										<option value="#ctRelation.taxon_relationship#">#ctRelation.taxon_relationship#</option>
									</cfloop>
								</select>
								<label for="relatedName" class="data-entry-label">Related Taxa</label>
								<input type="text" name="relatedName" class="reqdClr data-entry-input"
						onChange="taxaPick('newRelatedId','relatedName','newRelation',this.value); return false;"
						onKeyPress="return noenter(event);">
								<input type="hidden" name="newRelatedId">
								<label for="relation_authority" class="data-entry-label">Authority</label>
								<input type="text" name="relation_authority" class="data-entry-input">
								<input type="submit" value="Create" class="btn-xs btn-secondary mt-1 ml-1">
							</div>
						</form>
						<div id="taxonrelations"></div>
					</div>

						<cfquery name="common" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							select common_name 
							from common_name 
							where taxon_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#taxon_name_id#">
					</cfquery>
						<div class="border bg-light p-3 rounded mt-3 float-left col-12 col-md-6">
						<h4 class="mt-0">Common Names</h4>
						<cfset i=1>
						<cfloop query="common">
							<form name="common#i#" method="post" action="/taxonomy/Taxonomy.cfm">
								<input type="hidden" name="Action">
								<input type="hidden" name="origCommonName" value="#common_name#">
								<input type="hidden" name="taxon_name_id" value="#taxon_name_id#">
								<div class="form-row mx-0 my-1">
								<input type="text" name="common_name" value="#common_name#" class="data-entry-input w-50 float-left">
								<input type="button" value="Save" class="btn-xs btn-primary ml-1 float-left" onClick="common#i#.Action.value='saveCommon';submit();">
								<input type="button" value="Delete" class="btn-xs btn-danger ml-1 float-left" onClick="common#i#.Action.value='deleteCommon';confirmDialog('Delete <b>common#i#</b> common name entry','Delete?');">
								</div>
							</form>
							<cfset i=i+1>
						</cfloop>
							<form name="newCommon" method="post" action="/taxonomy/Taxonomy.cfm">
								<input type="hidden" name="Action" value="newCommon">
								<input type="hidden" name="taxon_name_id" value="#taxon_name_id#">
								<label for="common_name" class="data-entry-label float-left mt-1">Add New Common Name</label>
								<input type="text" name="common_name" class="data-entry-input my-1 float-left w-75">
								<input type="submit" value="Create" class="btn-xs btn-secondary ml-1 mt-3 float-left">
							</form>
						</div>
						<div class="border bg-light p-3 rounded mt-3 float-left col-12 col-md-6">
						<cfquery name="habitat" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							select taxon_habitat 
							from taxon_habitat 
							where taxon_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#taxon_name_id#">
						</cfquery>
						
						<cfset usedHabitats = valueList(habitat.taxon_habitat)>
						<h4 class="mt-0">Habitat</h4>
						<cfset i=1>
						<cfloop query="habitat">
						<form name="habitat#i#" method="post" action="/taxonomy/Taxonomy.cfm">
							<input type="hidden" name="Action">
							<input type="hidden" name="orighabitatName" value="#taxon_habitat#">
							<input type="hidden" name="taxon_name_id" value="#taxon_name_id#">
							<div class="form-row mx-0">
							<input type="text" name="taxon_habitat" value="#taxon_habitat#" class="data-entry-input w-50 float-left">
							<input type="button" value="Delete" class="btn-xs btn-danger ml-1 mb-1 float-left" onClick="habitat#i#.Action.value='deletehabitat';confirmDialog('Delete <b>#taxon_habitat#</b> habitat entry','Delete?');">
							</div>
						</form>
						<cfset i=i+1>
					</cfloop>
						<form name="newhabitat" method="post" action="/taxonomy/Taxonomy.cfm">
					<input type="hidden" name="Action" value="newhabitat">
					<input type="hidden" name="taxon_name_id" value="#taxon_name_id#">
					<label for="taxon_habitat" class="data-entry-label float-left mt-1">Add New Habitat</label>
					<select name="taxon_habitat" id="habitat_name"size="1" class="custom-select data-entry-select my-1 w-75 float-left">
					<cfloop query="cttaxon_habitat">
						<cfif not listcontains(usedHabitats,cttaxon_habitat.taxon_habitat)>
							<option value="#cttaxon_habitat.taxon_habitat#">#cttaxon_habitat.taxon_habitat#</option>
						</cfif>
					</cfloop>
					</select>
					<input type="submit" value="Add" class="btn-xs btn-secondary m-1 float-left">
				</form>
						</div>
					</div>
				</div>
			</div>
		</div>
</cfoutput>
</cfif>
<!---------------------------------------------------------------------------------------------------->
<cfif action is "newCommon">
	<cfoutput>
		<cfquery name="newCommon" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		INSERT INTO common_name 
			(common_name, taxon_name_id)
		VALUES 
			(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#common_name#"> , 
			<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#taxon_name_id#"> )
	</cfquery>
		<cflocation url="/taxonomy/Taxonomy.cfm?Action=edit&taxon_name_id=#taxon_name_id#" addtoken="false">
	</cfoutput>
</cfif>
<!---------------------------------------------------------------------------------------------------->
<cfif action is "newHabitat">
	<cfoutput>
		<cfquery name="newHabitat" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		INSERT INTO taxon_habitat 
			(taxon_habitat, taxon_name_id)
		VALUES 
			(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#taxon_habitat#">, 
			<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#taxon_name_id#">)
	</cfquery>
		<cflocation url="/taxonomy/Taxonomy.cfm?Action=edit&taxon_name_id=#taxon_name_id#" addtoken="false">
	</cfoutput>
</cfif>
<!---------------------------------------------------------------------------------------------------->
<cfif Action is "deleTaxa">
	<cfoutput>
		<cfquery name="deleTaxa" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		DELETE FROM
			taxonomy
		WHERE
			taxon_name_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#taxon_name_id#">
	</cfquery>
		Taxon record successfully deleted. </cfoutput>
</cfif>
<!---------------------------------------------------------------------------------------------------->
<cfif action is "deleteCommon">
	<cfoutput>
		<cfquery name="killCommon" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		DELETE FROM
			common_name
		WHERE
			common_name=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#common_name#"> 
			AND taxon_name_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#taxon_name_id#">
	</cfquery>
		<cflocation url="/taxonomy/Taxonomy.cfm?Action=edit&taxon_name_id=#taxon_name_id#" addtoken="false">
	</cfoutput>
</cfif>
<!---------------------------------------------------------------------------------------------------->
<cfif action is "saveCommon">
	<cfoutput>
		<cfquery name="upCommon" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		UPDATE
			common_name
		SET
			common_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#common_name#">
		WHERE
			common_name=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#origCommonName#">
			AND taxon_name_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#taxon_name_id#">
	</cfquery>
		<cflocation url="/taxonomy/Taxonomy.cfm?Action=edit&taxon_name_id=#taxon_name_id#" addtoken="false">
	</cfoutput>
</cfif>
<!---------------------------------------------------------------------------------------------------->
<cfif action is "deleteHabitat">
	<cfoutput>
		<cfquery name="killhabitat" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		DELETE FROM
			taxon_habitat
		WHERE
			taxon_habitat=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#orighabitatName#">
			AND taxon_name_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#taxon_name_id#">
	</cfquery>
		<cflocation url="/taxonomy/Taxonomy.cfm?Action=edit&taxon_name_id=#taxon_name_id#" addtoken="false">
	</cfoutput>
</cfif>

<!---------------------------------------------------------------------------------------------------->
<cfif action is "newTaxon">
	<cfset title = "Add Taxon">
	<cfquery name="getClonedFromTaxon" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select * from taxonomy where taxon_name_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#taxon_name_id#">
</cfquery>
	<cfoutput>
		<div class="container-fluid">
			<div class="row mb-4 mx-0">
				<div class="col-12 px-0">
					<div class="col-12 col-xl-7 offset-xl-1 float-left px-0 mb-5">
						<div class="col-12">
							<div class="row mx-0">
								<div class="col-12 col-sm-6 px-0 float-left my-2">
							<h1 class="h3 mb-0 px-1 float-left">Create New Taxonomy</h1>
							<p class="px-3 float-left w-100">(through cloning and editing)</p>
							</div>
								<div class="col-12 col-sm-6 px-0 float-right text-right mt-sm-5 pr-2">
									<input type="button" value="Save" class="savBtn btn-xs btn-primary" onclick=" qcTaxonEdits(); ">
									<input type="button" value="Clone" class="insBtn btn-xs btn-secondary mx-1" onclick="taxa.Action.value='newTaxon';submit();">
									<input type="button" value="Delete" class="delBtn btn-xs btn-warning mr-2"	onclick="taxa.Action.value='deleTaxa';confirmDelete('taxa');">
								</div>
							</div>
						</div>
						<form name="taxa" method="post" action="/taxonomy/Taxonomy.cfm" class="float-left w-100">
								
								<div class="tInput form-row mx-2 mb-1">
									<div class="col-12 col-sm-6">
										<input type="hidden" name="Action" value="saveNewTaxa">
										<label for="source_authority">Source</label>
										<select name="source_authority" id="source_authority" class="reqdClr custom-select data-entry-select w-75">
											<cfloop query="ctSourceAuth">
												<option
													<cfif form.source_authority is ctsourceauth.source_authority> selected="selected" </cfif>
													value="#ctSourceAuth.source_authority#">#ctSourceAuth.source_authority#</option>
											</cfloop>
										</select>
									</div>
									<div class="col-12 col-sm-3">
										<label for="valid_catalog_term_fg">Valid?</label>
										<select name="valid_catalog_term_fg" id="valid_catalog_term_fg" class="reqdClr custom-select data-entry-select w-75">
											<option <cfif valid_catalog_term_fg is "1"> selected="selected" </cfif> value="1">yes</option>
											<option <cfif valid_catalog_term_fg is "0"> selected="selected" </cfif> value="0">no</option>
										</select>
									</div>
									<div class="col-12 col-sm-3">
										<label for="nomenclatural_code">Nomenclatural Code</label>
										<select name="nomenclatural_code" id="nomenclatural_code" class="reqdClr custom-select data-entry-select w-75">
											<cfloop query="ctnomenclatural_code">
												<option
													<cfif #form.nomenclatural_code# is "#ctnomenclatural_code.nomenclatural_code#"> selected </cfif>
													value="#ctnomenclatural_code.nomenclatural_code#">#ctnomenclatural_code.nomenclatural_code#</option>
											</cfloop>
										</select>
									</div>
								</div>
								<div class="form-row col-12">
								<div class="col-12 border rounded mt-2 mb-1 pt-0 pb-2 pl-2">
									<label for="taxonid" class="data-entry-label">GUID for Taxon (dwc:taxonID)</label>
									<cfset pattern = "">
									<cfset placeholder = "">
									<cfset regex = "">
									<cfset replacement = "">
									<cfset searchlink = "" >
									<cfset searchtext = "" >
									<cfset searchclass = "" >
									<cfloop query="ctguid_type_taxon">
										<cfif form.taxonid_guid_type is ctguid_type_taxon.guid_type OR ctguid_type_taxon.recordcount EQ 1 >
											<cfset searchlink = ctguid_type_taxon.search_uri & getClonedFromTaxon.scientific_name >
												<cfset searchtext = "Find GUID <i class='fas fa-external-link-alt'></i>" >
											<cfset searchclass = 'class="btn-xs btn-secondary"'>
										</cfif>
									</cfloop>
									<div class="col-12 col-md-2 px-0 float-left">
									<select name="taxonid_guid_type" id="taxonid_guid_type" class="custom-select data-entry-select">
										<cfif searchtext EQ "">
											<option value=""></option>
										</cfif>
										<cfloop query="ctguid_type_taxon">
											<cfset sel="">
											<cfif form.taxonid_guid_type is ctguid_type_taxon.guid_type OR ctguid_type_taxon.recordcount EQ 1 >
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
									<div class="col-12 col-md-2 px-0 float-left"> 
									<a href="#searchlink#" id="taxonid_search" target="_blank" #searchclass#>#searchtext#</a> 
													</div>
									<!---  Note: value of guid is blank, user must look up a value for the cloned taxon --->
									<div class="col-12 col-md-7 px-0 float-left">
									<input name="taxonid" id="taxonid" value="" 
										placeholder="#placeholder#" pattern="#pattern#" 
										title="Enter a guid in the form #placeholder#" class="px-2 border w-100 rounded py-0">
									<a id="taxonid_link" href="" target="_blank" class="px-2 py-0"></a> 
								</div>
									<script>
										$(document).ready(function () { 
											if ($('##taxonid').val().length > 0) {
												$('##taxonid').hide();
											}
											$('##taxonid_search').click(function () { 
												$('##taxonid').show();
												$('##taxonid_link').hide();
											});
											$('##taxonid_guid_type').change(function () { 
												// On selecting a guid_type, remove an existing guid value.
												$('##taxonid').val("");
												// On selecting a guid_type, change the pattern.
												getGuidTypeInfo($('##taxonid_guid_type').val(), 'taxonid', 'taxonid_link','taxonid_search',getLowestTaxon());
											});
											$('##taxonid').blur( function () { 
												// On loss of focus for input, validate against the regex, update link
												getGuidTypeInfo($('##taxonid_guid_type').val(), 'taxonid', 'taxonid_link','taxonid_search',getLowestTaxon());
											});
											$('##subspecies').change(function () { 
												// On changing species name, update search.
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
								<div class="form-row col-12">
								<div class="col-12 border rounded mt-2 mb-1 pt-0 pb-2 pl-2">
									<label for="scientificnameid" class="data-entry-label" >GUID for Nomenclatural Act (dwc:scientificNameID)</label>
									<cfset pattern = "">
									<cfset placeholder = "">
									<cfset regex = "">
									<cfset replacement = "">
									<cfset searchlink = "" >
									<cfset searchtext = "" >
									<cfset searchclass = "" >
									<cfloop query="ctguid_type_scientificname">
										<cfif form.scientificnameid_guid_type is ctguid_type_scientificname.guid_type OR ctguid_type_scientificname.recordcount EQ 1 >
											<cfset searchlink = ctguid_type_scientificname.search_uri & getClonedFromTaxon.scientific_name >
											<cfset searchtext = "Find GUID <i class='fas fa-external-link-alt'></i>" >
											<cfset searchclass = 'class="btn-xs btn-secondary"' >
										</cfif>
									</cfloop>
									<div class="col-12 col-md-2 px-0 float-left">
									<select name="scientificnameid_guid_type" id="scientificnameid_guid_type" class="custom-select data-entry-select">
										<cfif searchtext EQ "">
											<option value=""></option>
										</cfif>
										<cfloop query="ctguid_type_scientificname">
											<cfset sel="">
											<cfif form.scientificnameid_guid_type is ctguid_type_scientificname.guid_type OR ctguid_type_scientificname.recordcount EQ 1 >
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
								<div class="col-12 col-md-2 px-0 float-left"> 
									<a href="#searchlink#" id="scientificnameid_search" target="_blank" #searchclass# style="font-size: .9em;margin-top: .2em;border-radius: .12em;">#searchtext#</a> 
									<!---  Note: value of guid is blank, user must look up a value for the cloned taxon --->
								</div>	
								<div class="col-12 col-md-auto w-50 px-0 float-left">
									<input name="scientificnameid" id="scientificnameid" value="" placeholder="#placeholder#" pattern="#pattern#" title="Enter a guid in the form #placeholder#"  class="px-2 border w-100 rounded py-0">
									<a id="scientificnameid_link" href="" target="_blank" class="px-2 py-0"></a> 
								</div>
								<script>
						$(document).ready(function () { 
							if ($('##scientificnameid').val().length > 0) {
								$('##scientificnameid').hide();
							}
							$('##scientificnameid_search').click(function () { 
								$('##scientificnameid').show();
								$('##scientificnameid_link').hide();
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
							$('##subspecies').change( function () { 
								// On changing species name, update the search link.
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
								<div class="form-row col-12 px-0 mt-3">
									<div class="col-6 px-0">
										<label for="genus" class="col-sm-3 col-form-label float-left">Genus <small class="likeLink botanical"
						onClick="taxa.genus.value='&##215;' + taxa.genus.value;">Add &##215;</small></label>
										<div class="col-sm-9 float-left">
											<input name="genus" id="genus" value="#genus#" class="data-entry-input my-1">
										</div>
									</div>
									<div class="col-6 px-0">
										<label for="species" class="col-sm-3 col-form-label float-left">Species</label>
										<div class="col-sm-9 float-left"> 
											<!---  <span class="likeLink" onClick="taxa.species.value='&##215;' + taxa.species.value;">Add &##215;</span>--->
											<input name="species" id="species" value="#species#" class="data-entry-input my-1">
										</div>
									</div>
								</div>
								<div class="form-row col-12 px-0">
									<div class="col-6 px-0">
										<label for="subspecies" class="col-sm-3 col-form-label float-left">Subspecies</label>
										<div class="col-sm-9 float-left">
											<input name="subspecies" id="subspecies" value="#subspecies#" class="data-entry-input my-1">
										</div>
									</div>
									<div class="col-6 px-0">
										<label for="author_text" class="col-sm-3 col-form-label float-left">Author</label>
										<div class="col-sm-9 float-left">
											<input type="text" name="author_text" id="author_text" value="#author_text#" class="data-entry-input mt-2">
											<span class="infoLink botanical"
						onclick="window.open('/picks/KewAbbrPick.cfm?tgt=author_text','picWin','width=700,height=400, resizable,scrollbars')"><small class="link-color"> Find Kew Abbr</small> </span> </div>
									</div>
								</div>
								<div class="form-row col-12 px-0">
									<div class="col-6 px-0">
										<label for="infraspecific_author" id="infraspecific_author_label" class="col-sm-5 col-form-label float-left">Infraspecific Author  <small class="line-height-sm d-block">(do not use for ICZN names)</small></label>
										<div class="col-sm-7 float-left">
											<input type="text" name="infraspecific_author" id="infraspecific_author" value="#infraspecific_author#" class="data-entry-input mt-2">
											<span class="infoLink botanical"
						onclick="window.open('/picks/KewAbbrPick.cfm?tgt=infraspecific_author','picWin','width=700,height=400, resizable,scrollbars')"><small class="link-color"> Find Kew Abbr </small></span> </div>
									</div>
									<div class="col-6 px-0">
										<label for="infraspecific_rank" class="col-sm-4 col-form-label float-left">Infraspecific Rank</label>
										<div class="col-sm-8 float-left">
											<select name="infraspecific_rank" id="infraspecific_rank" class="custom-select data-entry-select my-1">
												<option <cfif form.infraspecific_rank is ""> selected </cfif>  value=""></option>
												<cfloop query="ctInfRank">
													<option
														<cfif form.infraspecific_rank is ctinfrank.infraspecific_rank> selected="selected" </cfif>
														value="#ctInfRank.infraspecific_rank#">#ctInfRank.infraspecific_rank#</option>
												</cfloop>
											</select>
										</div>
									</div>
								</div>
								<div class="form-row col-12 px-0">
									<div class="col-6 px-0">
										<label for="taxon_status" class="col-sm-4 col-form-label float-left">Taxon Status <i class="fas fas-info mt-1 fa-info-circle" onclick="getCtDoc('cttaxon_status');" aria-label="help link"></i></label>
										<div class="col-sm-8 float-left">
											<select name="taxon_status" id="taxon_status" class="custom-select data-entry-select my-1">
												<option value=""></option>
												<cfloop query="cttaxon_status">
													<option <cfif form.taxon_status is cttaxon_status.taxon_status> selected="selected" </cfif>
				            						value="#cttaxon_status.taxon_status#">#cttaxon_status.taxon_status#</option>
												</cfloop>
											</select>
										</div>
									</div>
									<div class="col-6 px-0">
										<label for="kingdom" class="col-sm-3 col-form-label float-left">Kingdom</label>
										<div class="col-sm-9 float-left">
											<input type="text" name="kingdom" id="kingdom" value="#kingdom#" class="data-entry-input my-1">
										</div>
									</div>
								</div>
								<div class="form-row col-12 px-0">
									<div id="phylum_row" class="col-6 px-0">
										<label for="phylum" id="phylum_label" class="col-sm-3 col-form-label float-left">Phylum</label>
										<div class="col-sm-9 float-left">
											<input type="text" name="phylum" id="phylum" value="#phylum#" class="data-entry-input my-1">
										</div>
									</div>
									<div class="col-6 px-0">
										<label for="subphylum" id="subphylum_label" class="col-sm-3 col-form-label float-left">Subphylum</label>
										<div class="col-sm-9 float-left">
											<input type="text" name="subphylum" id="subphylum" value="#subphylum#" class="data-entry-input my-1">
										</div>
									</div>
								</div>
								<div class="form-row col-12 px-0">
									<div id="division_row" class="col-6 px-0">
										<label for="division" id="division_label" class="col-sm-3 col-form-label float-left">Division</label>
										<div class="col-sm-9 float-left">
											<input type="text" name="division" id="division" value="#division#" class="data-entry-input my-1">
										</div>
									</div>
									<div class="col-6 px-0">
										<label for="subdivision" id="subdivision_label" class="col-sm-3 col-form-label float-left">SubDivision</label>
										<div class="col-sm-9 float-left">
											<input type="text" name="subdivision" id="subdivision" value="#subdivision#" class="data-entry-input my-1">
										</div>
									</div>
								</div>
								<div class="form-row col-12 px-0">
									<div class="col-6 px-0">
										<label for="superclass" class="col-sm-3 col-form-label float-left">Superclass</label>
										<div class="col-sm-9 float-left">
											<input type="text" name="superclass" id="superclass" value="#superclass#" class="data-entry-input my-1">
										</div>
									</div>
									<div class="col-6 px-0">
										<label for="phylclass" class="col-sm-3 col-form-label float-left">Class</label>
										<div class="col-sm-9 float-left">
											<input type="text" name="phylclass" id="phylclass" value="#phylclass#" class="data-entry-input my-1">
										</div>
									</div>
								</div>
								<div class="form-row col-12 px-0">
									<div class="col-6 px-0">
										<label for="subclass" class="col-sm-3 col-form-label float-left">SubClass</label>
										<div class="col-sm-9 float-left">
											<input type="text" name="subclass" id="subclass" value="#subclass#" class="data-entry-input my-1">
										</div>
									</div>
									<div class="col-6 px-0">
										<label for="infraclass" class="col-sm-3 col-form-label float-left">InfraClass</label>
										<div class="col-sm-9 float-left">
											<input type="text" name="infraclass" id="infraclass" value="#infraclass#" class="data-entry-input my-1">
										</div>
									</div>
								</div>
								<div class="form-row col-12 px-0">
									<div class="col-6 px-0">
										<label for="superorder" class="col-sm-3 col-form-label float-left">Superorder</label>
										<div class="col-sm-9 float-left">
											<input type="text" name="superorder" id="superorder" value="#superorder#" class="data-entry-input my-1">
										</div>
									</div>
									<div class="col-6 px-0">
										<label for="phylorder" class="col-sm-3 col-form-label float-left">Order</label>
										<div class="col-sm-9 float-left">
											<input type="text" name="phylorder" id="phylorder" value="#phylorder#" class="data-entry-input my-1">
										</div>
									</div>
								</div>
								<div class="form-row col-12 px-0">
									<div class="col-6 px-0">
										<label for="suborder" class="col-sm-3 col-form-label float-left">Suborder</label>
										<div class="col-sm-9 float-left">
											<input type="text" name="suborder" id="suborder" value="#suborder#" class="data-entry-input my-1">
										</div>
									</div>
									<div class="col-6 px-0">
										<label for="infraorder" class="col-sm-3 col-form-label float-left">Infraorder</label>
										<div class="col-sm-9 float-left">
											<input type="text" name="infraorder" id="infraorder" value="#infraorder#" class="data-entry-input my-1">
										</div>
									</div>
								</div>
								<div class="form-row col-12 px-0">
									<div class="col-6 px-0">
										<label for="subgenus" class="col-sm-3 col-form-label float-left">Subsection (zoological)</label>
										<div class="col-sm-9 float-left">
											<input type="text" name="subsection" id="subsection" value="#subsection#" class="data-entry-input my-1">
										</div>
									</div>
								</div>
								<div class="form-row col-12 px-0">
									<div class="col-6 px-0">
										<label for="superfamily" class="col-sm-3 col-form-label float-left">Superfamily</label>
										<div class="col-sm-9 float-left">
											<input type="text" name="superfamily" id="superfamily" value="#superfamily#" class="data-entry-input my-1">
										</div>
									</div>
									<div class="col-6 px-0">
										<label for="family" class="col-sm-3 col-form-label float-left">Family</label>
										<div class="col-sm-9 float-left">
											<input type="text" name="family" id="family" value="#family#" class="data-entry-input my-1">
										</div>
									</div>
								</div>
								<div class="form-row col-12 px-0">
									<div class="col-6 px-0">
										<label for="subfamily" class="col-sm-3 col-form-label float-left">Subfamily</label>
										<div class="col-sm-9 float-left">
											<input type="text" name="subfamily" id="subfamily" value="#subfamily#" class="data-entry-input my-1">
										</div>
									</div>
									<div class="col-6 px-0">
										<label for="tribe" class="col-sm-3 col-form-label float-left">Tribe</label>
										<div class="col-sm-9 float-left">
											<input type="text" name="tribe" id="tribe" value="#tribe#" class="data-entry-input my-1">
										</div>
									</div>
								</div>
								<div class="form-row col-12 px-0">
									<div class="col-6 px-0">
										<label for="subgenus" class="col-sm-3 col-form-label float-left">Subgenus</label>
										<div class="col-sm-9 float-left"><span class="float-left d-inline brackets">(</span> 
											<input type="text" name="subgenus" id="subgenus" value="#subgenus#" class="data-entry-input my-1 w-75 float-left">
											<span class="float-left d-inline brackets">)</span><small> #subgenus_message# </small>
										</div>
									</div>
								</div>
								<div class="form-row col-12 px-0">
									<div class="col-12 px-0">
								<label for="taxon_remarks" class="col-sm-3 col-form-label float-left">Remarks</label>
								<div class="col-sm-9 float-left">
									<textarea name="taxon_remarks" id="taxon_remarks" rows="3" class="data-entry-textarea mt-1">#taxon_remarks#</textarea>
								</div>
									</div>
									</div>
									<div class="form-row col-12 px-0 justify-content-center mt-2">
								<input type="submit" value="Create" class="btn-xs btn-primary">
									</div>
							</form>
					</div>
				</div>
			</div>
		</div>
	</cfoutput>
</cfif>
<!---------------------------------------------------------------------------------------------------->
<cfif action is "saveNewtaxa">
	<cfoutput>
		<cftransaction>
			<cfquery name="nextID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select sq_taxon_name_id.nextval nextID from dual
		</cfquery>
			<cfquery name="newTaxon" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			INSERT INTO taxonomy (
				taxon_name_id,
				valid_catalog_term_fg,
				source_authority
			<cfif len(#author_text#) gt 0>
				,author_text
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
			<cfif len(#subsection#) gt 0>
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
				,'#phylum#'
			</cfif>
			<cfif len(#infraspecific_author#) gt 0>
				,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(infraspecific_author)#">
			</cfif>
			<cfif len(#kingdom#) gt 0>
				,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(kingdom)#">
			</cfif>
			<cfif len(#nomenclatural_code#) gt 0>
				,'#nomenclatural_code#'
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
			<cfif len(#subsection#) gt 0>
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
		</cftransaction>
		<cflocation url="/taxonomy/Taxonomy.cfm?Action=edit&taxon_name_id=#nextID.nextID#" addtoken="false">
	</cfoutput>
</cfif>
<!---------------------------------------------------------------------------------------------------->
<cfif action is "newTaxonRelation">
	<cfoutput>
		<cfquery name="newReln" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		INSERT INTO taxon_relations (
			TAXON_NAME_ID,
			RELATED_TAXON_NAME_ID,
			TAXON_RELATIONSHIP,
			RELATION_AUTHORITY
		) VALUES (
			<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#TAXON_NAME_ID#">,
			<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#newRelatedId#">,
			<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#TAXON_RELATIONSHIP#">,
			<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#RELATION_AUTHORITY#">
		)
	</cfquery>
		<cflocation url="/taxonomy/Taxonomy.cfm?Action=edit&taxon_name_id=#taxon_name_id#" addtoken="false">
	</cfoutput>
</cfif>
<!---------------------------------------------------------------------------------------------------->
<cfif Action is "deleReln">
	<cfoutput>
		<cfquery name="deleReln" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	DELETE FROM
		taxon_relations
	WHERE
		taxon_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#taxon_name_id#">
		AND Taxon_relationship = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#origtaxon_relationship#">
		AND related_taxon_name_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#related_taxon_name_id#">
		</cfquery>

		<cflocation url="/taxonomy/Taxonomy.cfm?Action=edit&taxon_name_id=#taxon_name_id#" addtoken="false">
	</cfoutput>
</cfif>
<!---------------------------------------------------------------------------------------------------->
<cfif #Action# is "saveRelnEdit">
	<cfoutput>
		<cfquery name="edRel" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	UPDATE taxon_relations SET
		taxon_relationship = '#taxon_relationship#'
		<cfif len(#newRelatedId#) gt 0>
			,related_taxon_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#newRelatedId#">
		<cfelse>
			,related_taxon_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#related_taxon_name_id#">
		</cfif>
		<cfif len(#relation_authority#) gt 0>
			,relation_authority = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#relation_authority#">
		<cfelse>
			,relation_authority = null
		</cfif>
	WHERE
		taxon_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#taxon_name_id#">
		AND Taxon_relationship = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#origTaxon_relationship#">
		AND related_taxon_name_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#related_taxon_name_id#">
</cfquery>
		<cflocation url="/taxonomy/Taxonomy.cfm?Action=edit&taxon_name_id=#taxon_name_id#" addtoken="false">
	</cfoutput>
</cfif>
<!---------------------------------------------------------------------------------------------------->
<!---<cfif #Action# is "saveTaxonEdits">
	<cfoutput>
		<cfset subgenus_message = "">
		<cfif len(#subgenus#) gt 0 and REFind("^\(.*\)$",#subgenus#) gt 0>
			<cfset subgenus_message = "Do Not include parethesies">
			<cfset subgenus = replace(replace(#subgenus#,")",""),"(","") >
		</cfif>
		<cfset hasError = 0 >
		<cfif not isdefined("source_authority") OR len(#source_authority#) is 0>
			Error: You didn't select a Source. Go back and try again.
			<cfset hasError = 1 >
		</cfif>
		<cfif hasError eq 0>
			<cftransaction>
				<cfquery name="edTaxa" datasource="user_login" username='#session.username#' password="#decrypt(session.epw,cfid)#">
	UPDATE taxonomy SET
		valid_catalog_term_fg=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#valid_catalog_term_fg#">,
		source_authority = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#source_authority#">
		<cfif len(#author_text#) gt 0>
			,author_text=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(author_text)#">
		<cfelse>
			,author_text=null
		</cfif>
		<cfif len(#taxonid_guid_type#) gt 0>
			,taxonid_guid_type=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(taxonid_guid_type)#">
		<cfelse>
			,taxonid_guid_type=null
		</cfif>
		<cfif len(#taxonid#) gt 0>
			,taxonid=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(taxonid)#">
		<cfelse>
			,taxonid=null
		</cfif>
		<cfif len(#scientificnameid_guid_type#) gt 0>
			,scientificnameid_guid_type=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(scientificnameid_guid_type)#">
		<cfelse>
			,scientificnameid_guid_type=null
		</cfif>
		<cfif len(#scientificnameid#) gt 0>
			,scientificnameid=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(scientificnameid)#">
		<cfelse>
			,scientificnameid=null
		</cfif>
		<cfif len(#tribe#) gt 0>
			,tribe = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(tribe)#">
		<cfelse>
			,tribe = null
		</cfif>
		<cfif len(#infraspecific_rank#) gt 0>
			,infraspecific_rank = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#infraspecific_rank#">
		<cfelse>
			,infraspecific_rank = null
		</cfif>
		<cfif len(#phylclass#) gt 0>
			,phylclass = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(phylclass)#">
		<cfelse>
			,phylclass = null
		</cfif>
		<cfif len(#phylorder#) gt 0>
			,phylorder = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(phylorder)#">
		<cfelse>
			,phylorder = null
		</cfif>
		<cfif len(#suborder#) gt 0>
			,suborder = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(suborder)#">
		<cfelse>
			,suborder = null
		</cfif>
		<cfif len(#family#) gt 0>
			,family = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(family)#">
		<cfelse>
			,family = null
		</cfif>
		<cfif len(#subfamily#) gt 0>
			,subfamily = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(subfamily)#">
		<cfelse>
			,subfamily = null
		</cfif>
		<cfif len(#genus#) gt 0>
			,genus = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(genus)#">
		<cfelse>
			,genus = null
		</cfif>
		<cfif len(#subgenus#) gt 0>
			,subgenus = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(subgenus)#">
		<cfelse>
			,subgenus = null
		</cfif>
		<cfif len(#species#) gt 0>
			,species = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(species)#">
		<cfelse>
			,species = null
		</cfif>
		<cfif len(#subspecies#) gt 0>
			,subspecies = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(subspecies)#">
		<cfelse>
			,subspecies = null
		</cfif>
		<cfif len(#phylum#) gt 0>
			,phylum = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(phylum)#">
		<cfelse>
			,phylum = null
		</cfif>
		<cfif len(#taxon_remarks#) gt 0>
			,taxon_remarks = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(taxon_remarks)#">
		<cfelse>
			,taxon_remarks = null
		</cfif>
		<cfif len(#kingdom#) gt 0>
			,kingdom = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(kingdom)#">
		<cfelse>
			,kingdom = null
		</cfif>
		<cfif len(#nomenclatural_code#) gt 0>
			,nomenclatural_code = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#nomenclatural_code#">
		<cfelse>
			,nomenclatural_code = null
		</cfif>
		<cfif len(#infraspecific_author#) gt 0>
			,infraspecific_author = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(infraspecific_author)#">
		<cfelse>
			,infraspecific_author = null
		</cfif>
		<cfif len(#subphylum#) gt 0>
			,subphylum = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(subphylum)#">
		<cfelse>
			,subphylum = null
		</cfif>
		<cfif len(#superclass#) gt 0>
			,superclass = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(superclass)#">
		<cfelse>
			,superclass = null
		</cfif>
		<cfif len(#subclass#) gt 0>
			,subclass = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(subclass)#">
		<cfelse>
			,subclass = null
		</cfif>
		<cfif len(#superorder#) gt 0>
			,superorder = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(superorder)#">
		<cfelse>
			,superorder = null
		</cfif>
		<cfif len(#infraorder#) gt 0>
			,infraorder = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(infraorder)#">
		<cfelse>
			,infraorder = null
		</cfif>
		<cfif len(#superfamily#) gt 0>
			,superfamily = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(superfamily)#">
		<cfelse>
			,superfamily = null
		</cfif>
		<cfif len(#division#) gt 0>
			,division = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(division)#">
		<cfelse>
			,division = null
		</cfif>
		<cfif len(#subdivision#) gt 0>
			,subdivision = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(subdivision)#">
		<cfelse>
			,subdivision = null
		</cfif>
		<cfif len(#subsection#) gt 0>
			,subsection = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(subsection)#">
		<cfelse>
			,subsection = null
		</cfif>
		<cfif len(#infraclass#) gt 0>
			,infraclass  = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(infraclass)#">
		<cfelse>
			,infraclass = null
		</cfif>
		<cfif len(#taxon_status#) gt 0>
			,taxon_status = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(taxon_status)#">
		<cfelse>
			,taxon_status = null
		</cfif>
	WHERE taxon_name_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#taxon_name_id#">
	</cfquery>
			</cftransaction>
			<cflocation url="/taxonomy/Taxonomy.cfm?Action=edit&taxon_name_id=#taxon_name_id#&subgenus_message=#subgenus_message#" addtoken="false">
		</cfif>
	</cfoutput>
</cfif>--->
<!---------------------------------------------------------------------------------------------------->

<cfinclude template="/shared/_footer.cfm">
