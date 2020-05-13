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
	<div class="container-fluid">
		<div class="row">
			<div class="col-12">
				<h2>Search Taxonomy <i class="fas fas-info fa-info-circle" onClick="getMCZDocs('Search_Taxonomy')" aria-label="help link"></i></h2>
			</div>
		</div>
		<div class="row">
			<div class="col-12 col-md-3 offset-md-1">
				<p>Search the taxonomy used in MCZbase for:	Common names, Synonymies, Taxa used for current identifications, Taxa used as authorities for future identifications, Taxa used in previous identifications	(especially where specimens were cited by a now-unaccepted name).</p>
				<p>These #getCount.cnt# records represent current and past taxonomic treatments in MCZbase. They are neither complete nor necessarily authoritative.</p>
				<p>Not all taxa in MCZbase have associated specimens. <a href="javascript:void(0)" onClick="taxa.we_have_some.checked=false;">Uncheck</a> the "Find only taxa for which specimens exist?" box to see all matches.</p>
			</div>
			<div class="col-10">
				<form ACTION="TaxonomyResults.cfm" METHOD="post" name="taxa">
					<div class="row">
						<div class="col-12 col-md-6">
							<ul class="list-group list-group-flush">
								<li class="list-group-item">
									<input type="radio" name="VALID_CATALOG_TERM_FG" checked="checked" value="">
								</li>
								<li class="list-group-item"><a href="javascript:void(0)" onClick="taxa.VALID_CATALOG_TERM_FG[0].checked=true;"><b>Display all matches?</b></a></li>
								<li>
									<input type="radio" name="VALID_CATALOG_TERM_FG" value="1">
								</li>
								<li class="list-group-item"><a href="javascript:void(0)" onClick="taxa.VALID_CATALOG_TERM_FG[1].checked=true;"><b>Display only taxa currently accepted for identification?</b></a></li>
								<li class="list-group-item">
									<input type="checkbox" name="we_have_some" value="1" id="we_have_some">
								</li>
								<li class="list-group-item"><a href="javascript:void(0)" onClick="taxa.we_have_some.checked=true;"><b>Find only taxa for which specimens exist?</b></a></li>
								<cfif isdefined("session.username") and #session.username# is "gordon">
									<script type="text/javascript" language="javascript">
										document.getElementById('we_have_some').checked=false;
									</script>
								</cfif>
								</li>
							</ul>
						</div>
					</div>
					<div class="row">
						<div class="col-12 col-md-12">
							<div class="form-row">
								<div class="form-group col-md-2">
									<label for="common_name">Common Name</label>
									<input type="text" class="form-control-sm" id="common_name" placeholder="common name" aria-label="common name">
								</div>
								<div class="form-group col-md-2">
									<label for="taxonomic_scientific_name">Scientific Name</label>
									<input type="text" class="form-control-sm" id="scientific_name" placeholder="scientific name">
									<span class="infoLink" onclick="var e=document.getElementById('scientific_name');e.value='='+e.value;"> Add = for exact match </span> </div>
								<div class="form-group col-md-2">
									<label for="full_taxon_name">Any Category</label>
									<input type="text" class="form-control-sm" id="full_taxon_name" placeholder="Any Category">
								</div>
								<div class="form-group col-md-2">
									<label for="author_text">Author Text</label>
									<input type="text" class="form-control-sm" id="author_text" placeholder="author text">
									<span class="infoLink" onclick="var e=document.getElementById('author_text');e.value='='+e.value;"> Add = for exact match </span> </div>
								<div class="form-group col-md-2">
									<label for="infraspecific_author">Infraspecific Author Text</label>
									<input type="text" class="form-control-sm" id="infraspecific_author" placeholder="infraspecific author" aria-label="infraspecific author">
									<span class="infoLink" onclick="var e=document.getElementById('infraspecific_author');e.value='='+e.value;"> Add = for exact match </span> </div>
							</div>
							<div class="form-row">
								<div class="form-group col-md-2">
									<label for="genus">Genus</label>
									<input type="text" class="form-control-sm" id="genus" placeholder="genus">
									<span class="" onclick="var e=document.getElementById('genus');e.value='='+e.value;"> Add = for exact match </span> </div>
								<div class="form-group col-md-2">
									<label for="species">Species</label>
									<input type="text" class="form-control-sm" id="species" placeholder="species">
									<span class="infoLink" onclick="var e=document.getElementById('species');e.value='='+e.value;"> Add = for exact match </span> </div>
								<div class="form-group col-md-2">
									<label for="subspecies">Subspecies</label>
									<input type="text" class="form-control-sm" id="subspecies" placeholder="subspecies">
									<span class="infoLink" onclick="var e=document.getElementById('subspecies');e.value='='+e.value;"> Add = for exact match </span> </div>
								<div class="form-group col-md-2">
									<label for="nomenclatural_code">Nomenclatural Code</label>
									<select name="nomenclatural_code" id="nomenclatural_code" size="1">
										<option></option>
										<cfloop query="ctnomenclatural_code">
											<option value="#nomenclatural_code#">#nomenclatural_code#</option>
										</cfloop>
									</select>
								</div>
								<div class="form-group col-md-2">
									<label for=""></label>
									<input type="text" class="form-control-sm" id="" placeholder="">
								</div>
							</div>
							<div class="form-row">
								<div class="form-group col-md-2">
									<label for="genus">Kingdom</label>
									<input type="text" class="form-control-sm" id="kingdom" placeholder="kingdom">
									<span class="infoLink" onclick="var e=document.getElementById('kingdom');e.value='='+e.value;"> Add = for exact match </span> </div>
								<div class="form-group col-md-2">
									<label for="phylum">Phylum</label>
									<input type="text" class="form-control-sm" id="phylum" placeholder="phylum">
									<span class="infoLink" onclick="var e=document.getElementById('phylum');e.value='='+e.value;"> Add = for exact match </span> </div>
								<div class="form-group col-md-2">
									<label for="subphylum">Subphylum</label>
									<input type="small" class="form-control-sm" id="subphylum" placeholder="subphylum">
								</div>
								<div class="form-group col-md-2">
									<label for="superclass">Superclass</label>
									<input type="small" class="form-control-sm" id="superclass" placeholder="superclass">
								</div>
								<div class="form-group col-md-2">
									<label for="phylclass">Class</label>
									<input type="text" class="form-control-sm" id="phylclass" placeholder="phylclass">
									<span class="small" onclick="var e=document.getElementById('phylclass');e.value='='+e.value;"> Add = for exact match </span> </div>
							</div>
							<div class="form-row">
								<div class="form-group col-md-2">
									<label for="subclass">Subclass</label>
									<input type="text" class="form-control-sm" id="subclass" placeholder="subclass">
									<span class="small" onclick="var e=document.getElementById('subclass');e.value='='+e.value;"> Add = for exact match </span> </div>
								<div class="form-group col-md-2">
									<label for="superorder">Superorder</label>
									<input type="text" class="form-control-sm" id="superorder" placeholder="superorder">
								</div>
								<div class="form-group col-md-2">
									<label for="phylorder">Order</label>
									<input type="text" class="form-control-sm" id="phylorder" placeholder="phylorder">
									<span class="small" onclick="var e=document.getElementById('phylorder');e.value='='+e.value;"> Add = for exact match </span> </div>
								<div class="form-group col-md-2">
									<label for="suborder">Suborder</label>
									<input type="text" class="form-control-sm" id="suborder" placeholder="suborder">
									<span class="infoLink" onclick="var e=document.getElementById('suborder');e.value='='+e.value;"> Add = for exact match </span> </div>
								<div class="form-group col-md-2">
									<label for="infraorder">Infraorder</label>
									<input type="text" class="form-control-sm" id="infraorder" placeholder="infraorder">
									<span class="infoLink" onclick="var e=document.getElementById('infraorder');e.value='='+e.value;"> Add = for exact match </span> </div>
							</div>
							<div class="form-row">
								<div class="form-group col-md-2">
									<label for="superfamily">Superfamily</label>
									<input type="text" class="form-control-sm" id="superfamily" placeholder="superfamily">
								</div>
								<div class="form-group col-md-2">
									<label for="subphylum">Family</label>
									<input type="text" class="form-control-sm" id="family" placeholder="family">
									<span class="small" onclick="var e=document.getElementById('family');e.value='='+e.value;"> Add = for exact match </span> </div>
								<div class="form-group col-md-2">
									<label for="subfamily">Subfamily</label>
									<input type="text" class="form-control-sm" id="subfamily" placeholder="subfamily">
									<span class="small" onclick="var e=document.getElementById('subfamily');e.value='='+e.value;"> Add = for exact match </span> </div>
								<div class="form-group col-md-2">
									<label for="tribe">Tribe</label>
									<input type="text" class="form-control-sm" id="tribe" placeholder="tribe">
									<span class="small" onclick="var e=document.getElementById('tribe');e.value='='+e.value;"> Add = for exact match </span> </div>
								<div class="form-group col-md-2">
									<label for="subgenus">Subgenus</label>
									<input type="text" class="form-control-sm" id="subgenus" placeholder="subgenus">
									<span class="small" onclick="var e=document.getElementById('subgenus');e.value='='+e.value;"> Add = for exact match </span> </div>
							</div>
							<div class="form-row">
								<div class="form-group col-md-2">
									<label for="source_authority">Authority</label>
									<select name="source_authority" id="source_authority" size="1">
										<option></option>
										<cfloop query="CTTAXONOMIC_AUTHORITY">
											<option value="#source_authority#">#source_authority#</option>
										</cfloop>
									</select>
								</div>
								<div class="form-group col-md-2">
									<label for="taxon_status">Taxon Status</label>
									<select name="taxon_status" id="taxon_status" size="1">
										<option></option>
										<cfloop query="cttaxon_status">
											<option value="#taxon_status#">#taxon_status#</option>
										</cfloop>
									</select>
								</div>
							</div>
							<input type="submit" value="Search" class="schBtn">
							<input type="reset" value="Clear Form" class="clrBtn">
							<input type="hidden" name="action" value="search">
							<div> Note: This form will not return >1000 records; you may need to narrow your search to return all relevant matches. </div>
						</div>
					</div>
				</form>
			</div>
		</div>
	</div>
</cfoutput>
<cfinclude template = "shared/_footer.cfm">
