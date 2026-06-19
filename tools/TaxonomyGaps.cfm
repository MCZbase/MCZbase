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
<!--- Ordered as: kingdom, phylum, class (phylclass), order (phylorder), family, genus --->
<cfset variables.taxaFields = "kingdom,phylum,phylclass,phylorder,family,genus,nomenclatural_code">
<!--- Friendly display labels for each field name --->
<cfset variables.taxaFieldLabels = {
	kingdom = "Kingdom",
	phylum = "Phylum",
	phylclass = "Class",
	phylorder = "Order",
	family = "Family",
	genus = "Genus",
	nomenclatural_code = "Nomenclatural Code"
}>
<cfif isDefined("url.nullstuff")><cfset variables.nullstuff = url.nullstuff><cfelse><cfset variables.nullstuff = "phylum,phylclass,phylorder,family"></cfif>
<cfif isDefined("url.taxaReturns")><cfset variables.taxaReturns = url.taxaReturns><cfelse><cfset variables.taxaReturns = variables.taxaFields></cfif>
<cfset variables.taxaRanks = "PHYLCLASS,PHYLORDER,SUBORDER,FAMILY,SUBFAMILY,GENUS,SUBGENUS,SPECIES,SUBSPECIES,SCIENTIFIC_NAME,TRIBE,INFRASPECIFIC_RANK,PHYLUM,KINGDOM,SUBCLASS,SUPERFAMILY">
<!--- Whitelist lterm and hterm against taxaRanks to prevent unsafe column-name injection --->
<cfif NOT listFindNoCase(variables.taxaRanks, variables.lterm)><cfset variables.lterm = "GENUS"></cfif>
<cfif NOT listFindNoCase(variables.taxaRanks, variables.hterm)><cfset variables.hterm = "FAMILY"></cfif>
<!--- Whitelist each item in nullstuff and taxaReturns against taxaFields --->
<cfset variables.safeNullstuff = "">
<cfloop list="#variables.nullstuff#" index="variables.n">
	<cfif listFindNoCase(variables.taxaFields, variables.n)><cfset variables.safeNullstuff = listAppend(variables.safeNullstuff, variables.n)></cfif>
</cfloop>
<cfif len(variables.safeNullstuff) EQ 0><cfset variables.safeNullstuff = "phylum,phylclass,phylorder,family"></cfif>
<cfset variables.nullstuff = variables.safeNullstuff>
<cfset variables.safeTaxaReturns = "">
<cfloop list="#variables.taxaReturns#" index="variables.n">
	<cfif listFindNoCase(variables.taxaFields, variables.n)><cfset variables.safeTaxaReturns = listAppend(variables.safeTaxaReturns, variables.n)></cfif>
</cfloop>
<cfif len(variables.safeTaxaReturns) EQ 0><cfset variables.safeTaxaReturns = variables.taxaFields></cfif>
<cfset variables.taxaReturns = variables.safeTaxaReturns>

<cfquery name="ctcollection" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	SELECT collection_id, collection 
	FROM collection 
	ORDER BY collection
</cfquery>

<main class="container-fluid py-3" id="content">
	<!--- Search / filter form --->
	<section class="row my-2" role="search">
		<div class="col-12">
			<h1 class="h2">Taxonomy Quality Control</h1>
		</div>
		<div class="col-12">
			<script>
				function showOptions(v) {
					$('#gap').hide();
					$('#higherCrash').hide();
					if (v === 'gap') {
						$('#gap').show();
					}
					if (v === 'higherCrash') {
						$('#higherCrash').show();
					}
				}
			</script>
			<cfoutput>
			<form name="cf" method="get" action="TaxonomyGaps.cfm">
				<div class="row g-2 align-items-end mb-2">
					<div class="col-auto">
						<label for="action" class="d-block">Check Taxonomy records for</label>
						<cfset variables.selActionGap = ""><cfif variables.action EQ "gap"><cfset variables.selActionGap = 'selected="selected"'></cfif>
						<cfset variables.selActionFunkyChar = ""><cfif variables.action EQ "funkyChar"><cfset variables.selActionFunkyChar = 'selected="selected"'></cfif>
						<cfset variables.selActionHigherCrash = ""><cfif variables.action EQ "higherCrash"><cfset variables.selActionHigherCrash = 'selected="selected"'></cfif>
						<select name="action" id="action" class="data-entry-select" onchange="showOptions(this.value);">
							<option value=""></option>
							<option #variables.selActionGap# value="gap">Missing higher taxon values</option>
							<option #variables.selActionFunkyChar# value="funkyChar">Scientific names containing unexpected characters</option>
							<option #variables.selActionHigherCrash# value="higherCrash">Lower taxon placed in multiple higher taxa</option>
						</select>
					</div>
					<div class="col-auto">
						<label for="limit" class="d-block">Row Limit</label>
						<cfset variables.sel100 = ""><cfif variables.limit EQ 100><cfset variables.sel100 = 'selected="selected"'></cfif>
						<cfset variables.sel1000 = ""><cfif variables.limit EQ 1000><cfset variables.sel1000 = 'selected="selected"'></cfif>
						<cfset variables.sel2000 = ""><cfif variables.limit EQ 2000><cfset variables.sel2000 = 'selected="selected"'></cfif>
						<cfset variables.sel5000 = ""><cfif variables.limit EQ 5000><cfset variables.sel5000 = 'selected="selected"'></cfif>
						<cfset variables.sel10000 = ""><cfif variables.limit EQ 10000><cfset variables.sel10000 = 'selected="selected"'></cfif>
						<select name="limit" id="limit" class="data-entry-select">
							<option #variables.sel100# value="100">100</option>
							<option #variables.sel1000# value="1000">1000</option>
							<option #variables.sel2000# value="2000">2000</option>
							<option #variables.sel5000# value="5000">5000</option>
							<option #variables.sel10000# value="10000">10000</option>
						</select>
					</div>
					<div class="col-auto">
						<label for="collection_id" class="d-block">Collection</label>
						<cfset variables.selCollIgnore = ""><cfif variables.collection_id EQ ""><cfset variables.selCollIgnore = 'selected="selected"'></cfif>
						<cfset variables.selCollAny = ""><cfif variables.collection_id EQ "0"><cfset variables.selCollAny = 'selected="selected"'></cfif>
						<cfset variables.selCollNone = ""><cfif variables.collection_id EQ "-1"><cfset variables.selCollNone = 'selected="selected"'></cfif>
						<cfset variables.thisCID = variables.collection_id>
						<select name="collection_id" id="collection_id" class="data-entry-select">
							<option #variables.selCollIgnore# value="">Ignore</option>
							<option #variables.selCollAny# value="0">Used by any collection</option>
							<option #variables.selCollNone# value="-1">Not used by any collection</option>
							<cfloop query="ctcollection">
								<cfset variables.selColl = ""><cfif variables.thisCID EQ ctcollection.collection_id><cfset variables.selColl = 'selected="selected"'></cfif>
								<option #variables.selColl# value="#encodeForHtmlAttribute(collection_id)#">#encodeForHtml(collection)#</option>
							</cfloop>
						</select>
					</div>
					<div class="col-auto">
						<input type="submit" value="Go" class="btn btn-primary btn-xs">
					</div>
				</div>
				<div id="higherCrash" style="display:none;" class="mb-3">
					<div class="row g-2 align-items-end">
						<div class="col-auto">
							<label for="lterm" class="d-block">Term</label>
							<select name="lterm" id="lterm" class="data-entry-select">
								<cfloop list="#variables.taxaRanks#" index="i">
									<cfset variables.selLterm = ""><cfif variables.lterm EQ i><cfset variables.selLterm = 'selected="selected"'></cfif>
									<option value="#encodeForHtmlAttribute(i)#" #variables.selLterm#>#encodeForHtml(i)#</option>
								</cfloop>
							</select>
						</div>
						<div class="col-auto">
							<label for="hterm" class="d-block">has multiple values under</label>
							<select name="hterm" id="hterm" class="data-entry-select">
								<cfloop list="#variables.taxaRanks#" index="i">
									<cfset variables.selHterm = ""><cfif variables.hterm EQ i><cfset variables.selHterm = 'selected="selected"'></cfif>
									<option value="#encodeForHtmlAttribute(i)#" #variables.selHterm#>#encodeForHtml(i)#</option>
								</cfloop>
							</select>
						</div>
					</div>
				</div>
				<div id="gap" style="display:none;" class="mb-3">
					<div class="row">
						<div class="col-auto">
							<div class="font-weight-bold mb-1">Require one of to be NULL</div>
							<cfloop list="#variables.taxaFields#" index="i">
							<cfset variables.checkedNullstuff = ""><cfif listFindNoCase(variables.nullstuff, i)><cfset variables.checkedNullstuff = 'checked="checked"'></cfif>
							<div class="form-check">
								<label class="form-check-label">
									<input class="form-check-input" type="checkbox" name="nullstuff" value="#encodeForHtmlAttribute(i)#" #variables.checkedNullstuff#>
									#encodeForHtml(variables.taxaFieldLabels[i])#
								</label>
							</div>
							</cfloop>
						</div>
						<div class="col-auto">
							<div class="font-weight-bold mb-1">Return</div>
							<cfloop list="#variables.taxaFields#" index="i">
							<cfset variables.checkedTaxaReturns = ""><cfif listFindNoCase(variables.taxaReturns, i)><cfset variables.checkedTaxaReturns = 'checked="checked"'></cfif>
							<div class="form-check">
								<label class="form-check-label">
									<input class="form-check-input" type="checkbox" name="taxaReturns" value="#encodeForHtmlAttribute(i)#" #variables.checkedTaxaReturns#>
									#encodeForHtml(variables.taxaFieldLabels[i])#
								</label>
							</div>
							</cfloop>
						</div>
					</div>
				</div>
			</form>
			<script>showOptions('#encodeForJavaScript(variables.action)#');</script>
			</cfoutput>
		</div>
	</section>
	<!--- higherCrash results --->
	<cfif variables.action EQ "higherCrash">
		<!--- Count query: total rows without the row limit --->
		<cfset variables.termCrashCountSql = "SELECT COUNT(*) AS total FROM (
				SELECT
					a.nomenclatural_code, a.#variables.lterm# l, a.#variables.hterm# h, a.author_text
				FROM
					(SELECT nomenclatural_code, #variables.lterm#, #variables.hterm#, author_text FROM taxonomy GROUP BY nomenclatural_code, #variables.lterm#, #variables.hterm#, author_text) a,
					(SELECT nomenclatural_code, #variables.lterm#, #variables.hterm# FROM taxonomy GROUP BY nomenclatural_code, #variables.lterm#, #variables.hterm#) b
				WHERE
					a.#variables.lterm# = b.#variables.lterm# AND
					a.#variables.hterm# != b.#variables.hterm#
				GROUP BY
					a.nomenclatural_code, a.#variables.lterm#, a.#variables.hterm#, a.author_text
			)">
		<cfset termCrashCount = queryExecute(
			variables.termCrashCountSql,
			{},
			{datasource="user_login", username=session.dbuser, password=decrypt(session.epw,cookie.cfid)}
		)>
		<!--- Data query: limited by row limit; includes author_text for the lower taxon --->
		<cfset variables.termCrashSql = "SELECT * FROM (
				SELECT
					a.nomenclatural_code, a.#variables.lterm# l, a.#variables.hterm# h, a.author_text
				FROM
					(SELECT nomenclatural_code, #variables.lterm#, #variables.hterm#, author_text FROM taxonomy GROUP BY nomenclatural_code, #variables.lterm#, #variables.hterm#, author_text) a,
					(SELECT nomenclatural_code, #variables.lterm#, #variables.hterm# FROM taxonomy GROUP BY nomenclatural_code, #variables.lterm#, #variables.hterm#) b
				WHERE
					a.#variables.lterm# = b.#variables.lterm# AND
					a.#variables.hterm# != b.#variables.hterm#
				GROUP BY
					a.nomenclatural_code, a.#variables.lterm#, a.#variables.hterm#, a.author_text
				ORDER BY
					a.#variables.lterm#, a.#variables.hterm#, a.nomenclatural_code
			) WHERE rownum <= :limitVal">
		<cfset termCrash = queryExecute(
			variables.termCrashSql,
			{limitVal = {value=variables.limit, cfsqltype="cf_sql_integer"}},
			{datasource="user_login", username=session.dbuser, password=decrypt(session.epw,cookie.cfid)}
		)>
		<section class="row my-2">
			<div class="col-12">
				<h2 class="h4">Lower Taxon Placed in Multiple Higher Taxa</h2>
				<cfoutput>
				<p>Showing #encodeForHtml(termCrash.recordCount)# of #encodeForHtml(termCrashCount.total)# total records.</p>
				<table class="sortable table table-responsive d-xl-table table-striped table-sm">
					<thead class="thead-light">
						<tr>
							<th scope="col">#encodeForHtml(variables.lterm)#</th>
							<th scope="col">Authorship</th>
							<th scope="col">#encodeForHtml(variables.hterm)#</th>
							<th scope="col">Nomenclatural Code</th>
						</tr>
					</thead>
					<tbody>
						<cfloop query="termCrash">
							<tr>
								<td><a href="/Taxa.cfm?execute=true&amp;#encodeForUrl(variables.lterm)#=#encodeForUrl(l)#">#encodeForHtml(l)#</a></td>
								<td>#encodeForHtml(author_text)#</td>
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
		<cfquery name="ctINFRASPECIFIC_RANK" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			SELECT INFRASPECIFIC_RANK FROM ctINFRASPECIFIC_RANK
			WHERE infraspecific_rank IN ('forma','subsp.','var.','ab.','fo.')
		</cfquery>
		<!--- Count query: total matching records before applying row limit --->
		<cfquery name="mdCount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			SELECT COUNT(*) AS total FROM (
				SELECT
					taxonomy.taxon_name_id,
					taxonomy.subgenus,
					taxonomy.scientific_name,
					regexp_replace(taxonomy.scientific_name, '([^a-zA-Z ])','<b>\1</b>') matches
				FROM taxonomy
				<cfif len(variables.collection_id) GT 0 AND variables.collection_id GT 0>
					INNER JOIN identification_taxonomy ON taxonomy.taxon_name_id = identification_taxonomy.taxon_name_id
					INNER JOIN identification ON identification_taxonomy.identification_id = identification.identification_id
					INNER JOIN cataloged_item ON identification.collection_object_id = cataloged_item.collection_object_id
				<cfelse>
					LEFT JOIN identification_taxonomy ON taxonomy.taxon_name_id = identification_taxonomy.taxon_name_id
				</cfif>
				WHERE
					<cfloop query="ctINFRASPECIFIC_RANK">
						regexp_like(regexp_replace(regexp_replace(taxonomy.scientific_name, ' #INFRASPECIFIC_RANK# ', ''),'[a-z]-[a-z]',''), '[^A-Za-z ]') AND
					</cfloop>
					regexp_like(regexp_replace(regexp_replace(taxonomy.scientific_name, chr(50071), ''),'[a-z]-[a-z]',''), '[^A-Za-z ]')
					<cfif len(variables.collection_id) GT 0 AND variables.collection_id GT 0>
						AND cataloged_item.collection_id = <cfqueryparam value="#variables.collection_id#" cfsqltype="CF_SQL_INTEGER">
					<cfelseif variables.collection_id EQ -1>
						AND identification_taxonomy.identification_id IS NULL
					</cfif>
				GROUP BY
					taxonomy.taxon_name_id,
					taxonomy.scientific_name,
					taxonomy.subgenus
			)
			WHERE (subgenus IS NULL OR NOT scientific_name = replace(matches,'<b>(</b>'|| subgenus || '<b>)</b>','('||subgenus||')'))
		</cfquery>
		<cfquery name="md" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			SELECT * FROM (
				SELECT
					taxonomy.taxon_name_id,
					taxonomy.subgenus,
					taxonomy.scientific_name,
					regexp_replace(taxonomy.scientific_name, '([^a-zA-Z ])','<b>\1</b>') matches,
					count(identification_taxonomy.identification_id) used
				FROM taxonomy
				<cfif len(variables.collection_id) GT 0 AND variables.collection_id GT 0>
					INNER JOIN identification_taxonomy ON taxonomy.taxon_name_id = identification_taxonomy.taxon_name_id
					INNER JOIN identification ON identification_taxonomy.identification_id = identification.identification_id
					INNER JOIN cataloged_item ON identification.collection_object_id = cataloged_item.collection_object_id
				<cfelse>
					LEFT JOIN identification_taxonomy ON taxonomy.taxon_name_id = identification_taxonomy.taxon_name_id
				</cfif>
				WHERE
					<cfloop query="ctINFRASPECIFIC_RANK">
						regexp_like(regexp_replace(regexp_replace(taxonomy.scientific_name, ' #INFRASPECIFIC_RANK# ', ''),'[a-z]-[a-z]',''), '[^A-Za-z ]') AND
					</cfloop>
					regexp_like(regexp_replace(regexp_replace(taxonomy.scientific_name, chr(50071), ''),'[a-z]-[a-z]',''), '[^A-Za-z ]')
					<cfif len(variables.collection_id) GT 0 AND variables.collection_id GT 0>
						AND cataloged_item.collection_id = <cfqueryparam value="#variables.collection_id#" cfsqltype="CF_SQL_INTEGER">
					<cfelseif variables.collection_id EQ -1>
						AND identification_taxonomy.identification_id IS NULL
					</cfif>
				GROUP BY
					taxonomy.taxon_name_id,
					taxonomy.scientific_name,
					taxonomy.subgenus
				ORDER BY taxonomy.scientific_name
			) WHERE
				(subgenus IS NULL OR NOT scientific_name = replace(matches,'<b>(</b>'|| subgenus || '<b>)</b>','('||subgenus||')'))
				AND rownum < <cfqueryparam value="#variables.limit#" cfsqltype="CF_SQL_INTEGER">
		</cfquery>
		<section class="row my-2">
			<div class="col-12">
				<h2 class="h4">Scientific Names Containing Unexpected Characters</h2>
				<cfoutput>
				<p>Showing #encodeForHtml(md.recordCount)# of #encodeForHtml(mdCount.total)# total records which have characters other than:</p>
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
		<!--- Build count SQL string; taxaReturns and nullstuff are column names whitelisted above --->
		<cfset variables.gapCountSql = "SELECT COUNT(*) AS total FROM (
				SELECT
					taxonomy.taxon_name_id
				FROM taxonomy">
		<cfif variables.collection_id EQ 0>
			<cfset variables.gapCountSql = variables.gapCountSql & "
				INNER JOIN identification_taxonomy ON taxonomy.taxon_name_id = identification_taxonomy.taxon_name_id">
		<cfelseif variables.collection_id EQ -1>
			<cfset variables.gapCountSql = variables.gapCountSql & "
				LEFT JOIN identification_taxonomy ON taxonomy.taxon_name_id = identification_taxonomy.taxon_name_id">
		<cfelseif len(variables.collection_id) GT 0 AND variables.collection_id GT 0>
			<cfset variables.gapCountSql = variables.gapCountSql & "
				INNER JOIN identification_taxonomy ON taxonomy.taxon_name_id = identification_taxonomy.taxon_name_id
				INNER JOIN identification ON identification_taxonomy.identification_id = identification.identification_id
				INNER JOIN cataloged_item ON identification.collection_object_id = cataloged_item.collection_object_id">
		</cfif>
		<cfset variables.gapCountSql = variables.gapCountSql & "
				WHERE (">
		<cfset variables.i = 1>
		<cfloop list="#variables.nullstuff#" index="variables.n">
			<cfset variables.gapCountSql = variables.gapCountSql & " " & variables.n & " IS NULL">
			<cfif variables.i LT listLen(variables.nullstuff)>
				<cfset variables.gapCountSql = variables.gapCountSql & " OR">
			</cfif>
			<cfset variables.i = variables.i + 1>
		</cfloop>
		<cfset variables.gapCountSql = variables.gapCountSql & "
				)">
		<cfif variables.collection_id EQ -1>
			<cfset variables.gapCountSql = variables.gapCountSql & "
				AND identification_taxonomy.identification_id IS NULL">
		<cfelseif len(variables.collection_id) GT 0 AND variables.collection_id GT 0>
			<cfset variables.gapCountSql = variables.gapCountSql & "
				AND cataloged_item.collection_id = :collectionId">
		</cfif>
		<cfset variables.gapCountSql = variables.gapCountSql & "
				GROUP BY taxonomy.taxon_name_id
			)">
		<cfset variables.gapCountParams = {}>
		<cfif len(variables.collection_id) GT 0 AND variables.collection_id GT 0>
			<cfset variables.gapCountParams.collectionId = {value=variables.collection_id, cfsqltype="cf_sql_integer"}>
		</cfif>
		<cfset gapCount = queryExecute(
			variables.gapCountSql,
			variables.gapCountParams,
			{datasource="user_login", username=session.dbuser, password=decrypt(session.epw,cookie.cfid)}
		)>
		<!--- Build data SQL string; taxaReturns and nullstuff are column names whitelisted above --->
		<cfset variables.gapSql = "SELECT * FROM (
				SELECT
					taxonomy.taxon_name_id,
					taxonomy.scientific_name,
					" & variables.taxaReturns & "
				FROM taxonomy">
		<cfif variables.collection_id EQ 0>
			<cfset variables.gapSql = variables.gapSql & "
				INNER JOIN identification_taxonomy ON taxonomy.taxon_name_id = identification_taxonomy.taxon_name_id">
		<cfelseif variables.collection_id EQ -1>
			<cfset variables.gapSql = variables.gapSql & "
				LEFT JOIN identification_taxonomy ON taxonomy.taxon_name_id = identification_taxonomy.taxon_name_id">
		<cfelseif len(variables.collection_id) GT 0 AND variables.collection_id GT 0>
			<cfset variables.gapSql = variables.gapSql & "
				INNER JOIN identification_taxonomy ON taxonomy.taxon_name_id = identification_taxonomy.taxon_name_id
				INNER JOIN identification ON identification_taxonomy.identification_id = identification.identification_id
				INNER JOIN cataloged_item ON identification.collection_object_id = cataloged_item.collection_object_id">
		</cfif>
		<cfset variables.gapSql = variables.gapSql & "
				WHERE (">
		<cfset variables.i = 1>
		<cfloop list="#variables.nullstuff#" index="variables.n">
			<cfset variables.gapSql = variables.gapSql & " " & variables.n & " IS NULL">
			<cfif variables.i LT listLen(variables.nullstuff)>
				<cfset variables.gapSql = variables.gapSql & " OR">
			</cfif>
			<cfset variables.i = variables.i + 1>
		</cfloop>
		<cfset variables.gapSql = variables.gapSql & "
				)">
		<cfif variables.collection_id EQ -1>
			<cfset variables.gapSql = variables.gapSql & "
				AND identification_taxonomy.identification_id IS NULL">
		<cfelseif len(variables.collection_id) GT 0 AND variables.collection_id GT 0>
			<cfset variables.gapSql = variables.gapSql & "
				AND cataloged_item.collection_id = :collectionId">
		</cfif>
		<cfset variables.gapSql = variables.gapSql & "
				GROUP BY
					taxonomy.taxon_name_id,
					taxonomy.scientific_name,
					" & variables.taxaReturns & "
				ORDER BY taxonomy.scientific_name
			) WHERE rownum < :limitVal">
		<cfset variables.gapParams = {limitVal = {value=variables.limit, cfsqltype="cf_sql_integer"}}>
		<cfif len(variables.collection_id) GT 0 AND variables.collection_id GT 0>
			<cfset variables.gapParams.collectionId = {value=variables.collection_id, cfsqltype="cf_sql_integer"}>
		</cfif>
		<cfset md = queryExecute(
			variables.gapSql,
			variables.gapParams,
			{datasource="user_login", username=session.dbuser, password=decrypt(session.epw,cookie.cfid)}
		)>
		<section class="row my-2">
			<div class="col-12">
				<h2 class="h4">Missing Higher Taxon Values</h2>
				<cfoutput>
				<p>Showing #encodeForHtml(md.recordCount)# of #encodeForHtml(gapCount.total)# total records.</p>
				<table class="sortable table table-responsive d-xl-table table-striped table-sm">
					<thead class="thead-light">
						<tr>
							<th scope="col">Scientific Name</th>
							<cfloop list="#variables.taxaReturns#" index="n">
								<th scope="col">#encodeForHtml(variables.taxaFieldLabels[n])#</th>
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
