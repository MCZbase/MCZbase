<!---
/tools/TaxonomyGaps.cfm

Taxonomy quality control tools: check for missing higher taxon values,
scientific names with unexpected characters, and lower taxa placed in
multiple higher taxa.

Copyright 2008-2017 Contributors to Arctos
Copyright 2020-2026 President and Fellows of Harvard College

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
<cfset pageTitle = "Taxonomy Quality Control">
<cfinclude template="/shared/_header.cfm">
<script src="/lib/misc/sorttable.js"></script>

<!--- Variable defaults --->
<cfif isDefined("url.action")><cfset variables.action = url.action><cfelse><cfset variables.action = ""></cfif>
<cfif isDefined("url.limit")><cfset variables.limit = url.limit><cfelse><cfset variables.limit = 1000></cfif>
<cfif isDefined("url.lterm")><cfset variables.lterm = url.lterm><cfelse><cfset variables.lterm = "GENUS"></cfif>
<cfif isDefined("url.hterm")><cfset variables.hterm = url.hterm><cfelse><cfset variables.hterm = "FAMILY"></cfif>
<cfif isDefined("url.collection_id")><cfset variables.collection_id = url.collection_id><cfelse><cfset variables.collection_id = ""></cfif>
<cfif isDefined("url.nullstuff")><cfset variables.nullstuff = url.nullstuff><cfelse><cfset variables.nullstuff = "phylclass,phylorder,family"></cfif>
<cfset variables.taxaFields = "phylclass,phylorder,family,nomenclatural_code,kingdom">
<cfif isDefined("url.taxaReturns")><cfset variables.taxaReturns = url.taxaReturns><cfelse><cfset variables.taxaReturns = variables.taxaFields></cfif>
<cfset variables.taxaRanks = "PHYLCLASS,PHYLORDER,SUBORDER,FAMILY,SUBFAMILY,GENUS,SUBGENUS,SPECIES,SUBSPECIES,SCIENTIFIC_NAME,TRIBE,INFRASPECIFIC_RANK,PHYLUM,KINGDOM,SUBCLASS,SUPERFAMILY">

<cfquery name="ctcollection" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	select collection_id,collection from collection order by collection
</cfquery>

<main class="container-fluid py-3" id="content">
	<!--- Search / filter form --->
	<section class="row my-2" role="search">
		<div class="col-12">
			<h1 class="h2">Taxonomy Quality Control</h1>
		</div>
		<div class="col-12">
			<cfoutput>
			<script>
				function showOptions(v) {
					document.getElementById('gapOptions').style.display = 'none';
					document.getElementById('higherCrashOptions').style.display = 'none';
					if (v === 'gap') {
						document.getElementById('gapOptions').style.display = 'block';
					}
					if (v === 'higherCrash') {
						document.getElementById('higherCrashOptions').style.display = 'block';
					}
				}
			</script>
			<form name="cf" method="get" action="TaxonomyGaps.cfm">
				<div class="form-group mb-3">
					<label for="action">Check Taxonomy records for</label>
					<select name="action" id="action" class="data-entry-select" onchange="showOptions(this.value);">
						<option value=""></option>
						<option <cfif variables.action EQ "gap">selected="selected"</cfif> value="gap">Missing higher taxon values</option>
						<option <cfif variables.action EQ "funkyChar">selected="selected"</cfif> value="funkyChar">Scientific names containing unexpected characters</option>
						<option <cfif variables.action EQ "higherCrash">selected="selected"</cfif> value="higherCrash">Lower taxon placed in multiple higher taxa</option>
					</select>
				</div>
				<div id="higherCrashOptions" style="display:none;" class="mb-3">
					<div class="form-group">
						<label for="lterm" class="mr-2">Term</label>
						<select name="lterm" id="lterm" class="data-entry-select mr-3">
							<cfloop list="#variables.taxaRanks#" index="i">
								<option value="#encodeForHtmlAttribute(i)#" <cfif variables.lterm EQ i>selected="selected"</cfif>>#encodeForHtml(i)#</option>
							</cfloop>
						</select>
						<label for="hterm" class="mr-2">has multiple values under</label>
						<select name="hterm" id="hterm" class="data-entry-select">
							<cfloop list="#variables.taxaRanks#" index="i">
								<option value="#encodeForHtmlAttribute(i)#" <cfif variables.hterm EQ i>selected="selected"</cfif>>#encodeForHtml(i)#</option>
							</cfloop>
						</select>
					</div>
				</div>
				<div id="gapOptions" style="display:none;" class="mb-3">
					<table class="table table-sm table-bordered w-auto">
						<thead class="thead-light">
							<tr>
								<th scope="col">Require one of to be NULL</th>
								<th scope="col">Return</th>
							</tr>
						</thead>
						<tbody>
							<cfloop list="#variables.taxaFields#" index="i">
								<tr>
									<td>
										<label class="mb-0">
											<input type="checkbox" name="nullstuff" value="#encodeForHtmlAttribute(i)#" <cfif listFindNoCase(variables.nullstuff, i)>checked="checked"</cfif>>
											#encodeForHtml(i)#
										</label>
									</td>
									<td>
										<label class="mb-0">
											<input type="checkbox" name="taxaReturns" value="#encodeForHtmlAttribute(i)#" <cfif listFindNoCase(variables.taxaReturns, i)>checked="checked"</cfif>>
											#encodeForHtml(i)#
										</label>
									</td>
								</tr>
							</cfloop>
						</tbody>
					</table>
				</div>
				<div class="form-group mb-3">
					<label for="limit" class="mr-2">Row Limit</label>
					<select name="limit" id="limit" class="data-entry-select mr-3">
						<option <cfif variables.limit EQ 100>selected="selected"</cfif> value="1000">100</option>
						<option <cfif variables.limit EQ 1000>selected="selected"</cfif> value="1000">1000</option>
						<option <cfif variables.limit EQ 2000>selected="selected"</cfif> value="2000">2000</option>
						<option <cfif variables.limit EQ 5000>selected="selected"</cfif> value="5000">5000</option>
						<option <cfif variables.limit EQ 10000>selected="selected"</cfif> value="10000">10000</option>
					</select>
					<label for="collection_id" class="mr-2">Collection</label>
					<select name="collection_id" id="collection_id" class="data-entry-select">
						<option <cfif variables.collection_id EQ "">selected="selected"</cfif> value="">Ignore</option>
						<option <cfif variables.collection_id EQ "0">selected="selected"</cfif> value="0">Used by any collection</option>
						<option <cfif variables.collection_id EQ "-1">selected="selected"</cfif> value="-1">Not used by any collection</option>
						<cfset variables.thisCID = variables.collection_id>
						<cfloop query="ctcollection">
							<option <cfif variables.thisCID EQ ctcollection.collection_id>selected="selected"</cfif> value="#encodeForHtmlAttribute(collection_id)#">#encodeForHtml(collection)#</option>
						</cfloop>
					</select>
				</div>
				<div class="mb-3">
					<input type="submit" value="Go" class="btn btn-primary btn-xs">
				</div>
			</form>
			<script>showOptions('#encodeForJavaScript(variables.action)#');</script>
			</cfoutput>
		</div>
	</section>
	<!--- higherCrash results --->
	<cfif variables.action EQ "higherCrash">
		<cfoutput>
		<cfquery name="termCrash" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			select * from (
				select
					a.nomenclatural_code,a.#variables.lterm# l, a.#variables.hterm# h
				from
					(select nomenclatural_code, #variables.lterm#, #variables.hterm# from taxonomy group by nomenclatural_code, #variables.lterm#, #variables.hterm#) a,
					(select nomenclatural_code, #variables.lterm#, #variables.hterm# from taxonomy group by nomenclatural_code, #variables.lterm#, #variables.hterm#) b
				where
					a.#variables.lterm# = b.#variables.lterm# and
					a.#variables.hterm# != b.#variables.hterm#
				group by
					a.nomenclatural_code, a.#variables.lterm#, a.#variables.hterm#
				order by 
					a.#variables.lterm#, a.#variables.hterm#, a.nomenclatural_code
			) where rownum <= #variables.limit#
		</cfquery>
		</cfoutput>
		<section class="row my-2">
			<div class="col-12">
				<h2 class="h4">Lower Taxon Placed in Multiple Higher Taxa</h2>
				<cfoutput>
				<table class="sortable table table-responsive d-xl-table table-striped table-sm">
					<thead class="thead-light">
						<tr>
							<th scope="col">#encodeForHtml(variables.lterm)#</th>
							<th scope="col">#encodeForHtml(variables.hterm)#</th>
							<th scope="col">Nomenclatural Code</th>
						</tr>
					</thead>
					<tbody>
						<cfloop query="termCrash">
							<tr>
								<td><a href="/Taxa.cfm?execute=true&amp;#encodeForUrl(variables.lterm)#=#encodeForUrl(l)#">#encodeForHtml(l)#</a></td>
								<td><a href="/Taxa.cfm?execute=true&amp;#encodeForUrl(variables.hterm)#=#encodeForUrl(h)#&amp;#encodeForUrl(variables.lterm)#=#encodeForUrl(l)#">#encodeForHtml(h)#</a></td>
								<td>#encodeForHtml(nomenclatural_code)#</td>
							</tr>
						</cfloop>
					</tbody>
				</table>
				</cfoutput>
			</div>
		</section>
	</cfif>
	<!--- funkyChar results --->
	<cfif variables.action EQ "funkyChar">
		<cfoutput>
		<cfquery name="ctINFRASPECIFIC_RANK" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			select INFRASPECIFIC_RANK from ctINFRASPECIFIC_RANK
			where infraspecific_rank in ('forma','subsp.','var.','ab.','fo.')
		</cfquery>
		<cfset variables.s = "select
				taxonomy.taxon_name_id,
				taxonomy.subgenus,
				taxonomy.scientific_name,
				regexp_replace(taxonomy.scientific_name, '([^a-zA-Z ])','<b>\1</b>') matches,
				count(identification_taxonomy.identification_id) used">
		<cfset variables.f = "from
				taxonomy,
				identification_taxonomy">
		<cfif len(variables.collection_id) EQ 0 OR variables.collection_id EQ -1>
			<cfset variables.w = "where taxonomy.taxon_name_id=identification_taxonomy.taxon_name_id (+) and">
		<cfelse>
			<cfset variables.w = "where taxonomy.taxon_name_id=identification_taxonomy.taxon_name_id and">
		</cfif>
		<cfloop query="ctINFRASPECIFIC_RANK">
			<cfset variables.w = variables.w & " regexp_like(regexp_replace(regexp_replace(taxonomy.scientific_name, ' #INFRASPECIFIC_RANK# ', ''),'[a-z]-[a-z]',''), '[^A-Za-z ]') and">
		</cfloop>
		<cfset variables.w = variables.w & " regexp_like(regexp_replace(regexp_replace(taxonomy.scientific_name, chr(50071), ''),'[a-z]-[a-z]',''), '[^A-Za-z ]') ">
		<cfif len(variables.collection_id) GT 0 AND variables.collection_id GT 0>
			<cfset variables.f = variables.f & ",identification,cataloged_item">
			<cfset variables.w = variables.w & " and identification_taxonomy.identification_id=identification.identification_id and
					identification.collection_object_id=cataloged_item.collection_object_id and
					cataloged_item.collection_id=#variables.collection_id#">
		<cfelseif variables.collection_id EQ -1>
			<cfset variables.w = variables.w & " and identification_taxonomy.identification_id is null">
		</cfif>
		<cfset variables.sql = "select * from (" & variables.s & " " & variables.f & " " & variables.w & " group by
				taxonomy.taxon_name_id,
				taxonomy.scientific_name,
				taxonomy.subgenus
			order by taxonomy.scientific_name)
			where
				subgenus is null or (not scientific_name = replace(matches,'<b>(</b>'|| subgenus || '<b>)</b>','('||subgenus||')') )
				and rownum < #variables.limit# ">
		<cfquery name="md" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		#preserveSingleQuotes(variables.sql)#
		</cfquery>
		</cfoutput>
		<section class="row my-2">
			<div class="col-12">
				<h2 class="h4">Scientific Names Containing Unexpected Characters</h2>
				<cfoutput>
				<p>Showing the top #encodeForHtml(variables.limit)# records which have characters other than:</p>
				<ul>
					<li>A-Za-z (upper or lower case Roman characters)</li>
					<li>[a-z]-[a-z] (lower-case character followed by a dash followed by another lower-case character)</li>
					<li>&##215; (multiplication sign to mark hybrids)</li>
					<li>
						Allowed values in ctinfraspecific_rank
						<ul>
							<cfloop query="ctINFRASPECIFIC_RANK">
								<li>#encodeForHtml(INFRASPECIFIC_RANK)#</li>
							</cfloop>
						</ul>
					</li>
				</ul>
				<p class="text-muted">Note: Some records which have more than one excluded character will show up here anyway.</p>
				<table class="sortable table table-responsive d-xl-table table-striped table-sm">
					<thead class="thead-light">
						<tr>
							<th scope="col">Scientific Name</th>
							<th scope="col">NumIds</th>
						</tr>
					</thead>
					<tbody>
						<cfloop query="md">
							<cfset variables.matches = replace(matches, '<b> </b>', '<b>_</b>', 'all')>
							<tr>
								<td><a href="#encodeForHtmlAttribute(Application.ServerRootUrl)#/taxonomy/Taxonomy.cfm?action=edit&amp;taxon_name_id=#encodeForUrl(taxon_name_id)#">#variables.matches#</a></td>
								<td>#encodeForHtml(used)#</td>
							</tr>
						</cfloop>
					</tbody>
				</table>
				</cfoutput>
			</div>
		</section>
	</cfif>
	<!--- gap results --->
	<cfif variables.action EQ "gap">
		<cfoutput>
		<cfset variables.s = "select taxonomy.taxon_name_id, taxonomy.scientific_name, #variables.taxaReturns#">
		<cfset variables.f = " from taxonomy ">
		<cfset variables.w = " where (">
		<cfset variables.i = 1>
		<cfloop list="#variables.nullstuff#" index="n">
			<cfset variables.w = variables.w & " #n# is null ">
			<cfif variables.i LT listLen(variables.nullstuff)>
				<cfset variables.w = variables.w & " OR ">
			</cfif>
			<cfset variables.i = variables.i + 1>
		</cfloop>
		<cfset variables.w = variables.w & " ) ">
		<cfif variables.collection_id EQ 0><!--- used by any collection --->
			<cfset variables.f = variables.f & ",identification_taxonomy">
			<cfset variables.w = variables.w & " AND taxonomy.taxon_name_id=identification_taxonomy.taxon_name_id ">
		<cfelseif variables.collection_id EQ -1>
			<cfset variables.f = variables.f & ",identification_taxonomy">
			<cfset variables.w = variables.w & " AND taxonomy.taxon_name_id=identification_taxonomy.taxon_name_id (+)
					and identification_taxonomy.identification_id is null ">
		<cfelseif len(variables.collection_id) GT 0 AND variables.collection_id GT 0>
			<cfset variables.f = variables.f & ",identification_taxonomy,identification,cataloged_item">
			<cfset variables.w = variables.w & " and taxonomy.taxon_name_id=identification_taxonomy.taxon_name_id and
					identification_taxonomy.identification_id=identification.identification_id and
					identification.collection_object_id=cataloged_item.collection_object_id and
					cataloged_item.collection_id=#variables.collection_id#">
		</cfif>
		<cfset variables.sql = "select * from ( " & variables.s & variables.f & variables.w & " group by taxonomy.taxon_name_id, taxonomy.scientific_name, #variables.taxaReturns#
				order by taxonomy.scientific_name) where rownum < #variables.limit#">
		<cfquery name="md" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		#preserveSingleQuotes(variables.sql)#
		</cfquery>
		</cfoutput>
		<section class="row my-2">
			<div class="col-12">
				<h2 class="h4">Missing Higher Taxon Values</h2>
				<cfoutput>
				<table class="sortable table table-responsive d-xl-table table-striped table-sm">
					<thead class="thead-light">
						<tr>
							<th scope="col">Scientific Name</th>
							<cfloop list="#variables.taxaReturns#" index="n">
								<th scope="col">#encodeForHtml(n)#</th>
							</cfloop>
						</tr>
					</thead>
					<tbody>
						<cfloop query="md">
							<tr>
								<td><a href="#encodeForHtmlAttribute(Application.ServerRootUrl)#/taxonomy/Taxonomy.cfm?action=edit&amp;taxon_name_id=#encodeForUrl(taxon_name_id)#">#encodeForHtml(scientific_name)#</a></td>
								<cfloop list="#variables.taxaReturns#" index="n">
									<td>#encodeForHtml(evaluate("md." & n))#</td>
								</cfloop>
							</tr>
						</cfloop>
					</tbody>
				</table>
				</cfoutput>
			</div>
		</section>
	</cfif>
</main>

<cfinclude template="/shared/_footer.cfm">
