<!---
tools/findGap.cfm

Copyright 2008-2017 Contributors to Arctos
Copyright 2008-2026 President and Fellows of Harvard College

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
<!---
Gaps in a catalog number series: one collection's catalog numbers with one prefix (or none), by
their integer part.  Lists each gap with the cataloged items on either side of it and, optionally,
the ledger scans whose pages cover it, and downloads the gaps or every missing number as CSV.

GET parameters: collection_id and cat_num_prefix (empty for no prefix) pick the series, or series
as collection_id|cat_num_prefix from the form's picklist; low and high limit the numbers looked at
(defaulting to the lowest and highest in the series); ledgers=true adds the ledger scans;
format=csv with download=gaps or download=missing returns a file instead of the page.
--->
<cfparam name="url.series" default="">
<cfparam name="url.collection_id" default="">
<cfparam name="url.cat_num_prefix" default="">
<cfparam name="url.low" default="">
<cfparam name="url.high" default="">
<cfparam name="url.ledgers" default="">
<cfparam name="url.format" default="">
<cfparam name="url.download" default="">

<!--- a missing number list is built from every number in the range, so the range is limited --->
<cfset MAXMISSINGRANGE = 5000000>
<cfset VIEWERBASE = "https://viewer.lib.harvard.edu/viewer/">
<!--- a jump is listed as a likely entry error, such as 999999999 for 999999, when it is wider than
	the count of numbers below it and has no more than this many numbers above it --->
<cfset SUSPECTMAXABOVE = 100>
<cfset LARGESTJUMPCOUNT = 10>

<!---
	csvField quote a value for a CSV file, with a leading apostrophe on text a spreadsheet would
	take as a formula.

	@param value the value.
	@return the quoted value.
--->
<cffunction name="csvField" returntype="string" output="false">
	<cfargument name="value" type="string" required="yes">
	<cfset var text = arguments.value>
	<cfif REFind("^[=+\-@\t\r]", text) GT 0>
		<cfset text = "'" & text>
	</cfif>
	<cfreturn '"' & replace(text, '"', '""', "all") & '"'>
</cffunction>

<!--- Each collection's catalog number series, one per prefix. --->
<cfquery name="seriesList" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" cachedwithin="#createTimeSpan(0,1,0,0)#" result="seriesList_result">
	SELECT
		collection.collection_id,
		collection.institution_acronym,
		collection.collection_cde,
		collection.collection,
		cataloged_item.cat_num_prefix,
		count(*) AS item_count
	FROM
		cataloged_item
		JOIN collection ON cataloged_item.collection_id = collection.collection_id
	GROUP BY
		collection.collection_id, collection.institution_acronym, collection.collection_cde,
		collection.collection, cataloged_item.cat_num_prefix
	ORDER BY
		collection.collection, cataloged_item.cat_num_prefix NULLS FIRST
</cfquery>

<!--- The series asked for. --->
<cfset variables.collection_id = url.collection_id>
<cfset variables.cat_num_prefix = url.cat_num_prefix>
<cfif len(url.series) GT 0>
	<cfset variables.collection_id = listFirst(url.series, "|")>
	<cfset variables.cat_num_prefix = "">
	<cfif find("|", url.series) GT 0>
		<cfset variables.cat_num_prefix = mid(url.series, find("|", url.series) + 1, len(url.series))>
	</cfif>
</cfif>
<cfset variables.seriesRow = 0>
<cfloop query="seriesList">
	<cfif seriesList.collection_id EQ variables.collection_id AND compare(seriesList.cat_num_prefix, variables.cat_num_prefix) EQ 0>
		<cfset variables.seriesRow = seriesList.currentRow>
	</cfif>
</cfloop>
<cfset variables.problem = "">
<cfif len(variables.collection_id) GT 0 AND variables.seriesRow EQ 0>
	<cfset variables.problem = "That collection has no cataloged items with that catalog number prefix.">
</cfif>
<cfloop list="low,high" index="variables.boundName">
	<cfif len(url[variables.boundName]) GT 0 AND NOT isValid("integer", url[variables.boundName])>
		<cfset variables.problem = "The lowest and highest numbers must be whole numbers.">
	</cfif>
</cfloop>
<cfset variables.showLedgers = (url.ledgers EQ "true")>

<cfset variables.hasSeries = (variables.seriesRow GT 0 AND len(variables.problem) EQ 0)>
<cfif variables.hasSeries>
	<cfset variables.institution_acronym = seriesList.institution_acronym[variables.seriesRow]>
	<cfset variables.collection_cde = seriesList.collection_cde[variables.seriesRow]>
	<cfset variables.collectionName = seriesList.collection[variables.seriesRow]>
	<cfset variables.seriesName = variables.collectionName>
	<cfif len(variables.cat_num_prefix) GT 0>
		<cfset variables.seriesName = "#variables.seriesName#, prefix #variables.cat_num_prefix#">
	<cfelse>
		<cfset variables.seriesName = "#variables.seriesName#, no prefix">
	</cfif>

	<cfquery name="summary" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="summary_result">
		SELECT
			totals.item_count,
			totals.number_count,
			totals.lowest,
			totals.highest,
			totals.suffix_count,
			shared.shared_count
		FROM
			(
				SELECT
					count(*) AS item_count,
					count(DISTINCT cat_num_integer) AS number_count,
					min(cat_num_integer) AS lowest,
					max(cat_num_integer) AS highest,
					count(cat_num_suffix) AS suffix_count
				FROM cataloged_item
				WHERE
					collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.collection_id#">
					<cfif len(variables.cat_num_prefix) EQ 0>
						AND cat_num_prefix IS NULL
					<cfelse>
						AND cat_num_prefix = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.cat_num_prefix#">
					</cfif>
			) totals
			CROSS JOIN (
				SELECT count(*) AS shared_count
				FROM (
					SELECT cat_num_integer
					FROM cataloged_item
					WHERE
						collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.collection_id#">
						<cfif len(variables.cat_num_prefix) EQ 0>
							AND cat_num_prefix IS NULL
						<cfelse>
							AND cat_num_prefix = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.cat_num_prefix#">
						</cfif>
					GROUP BY cat_num_integer
					HAVING count(*) > 1
				)
			) shared
	</cfquery>
	<!--- The widest jumps in the whole series, with the counts of numbers below and above each. --->
	<cfquery name="jumps" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="jumps_result">
		WITH numbers AS (
			SELECT DISTINCT cat_num_integer AS num
			FROM cataloged_item
			WHERE
				collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.collection_id#">
				<cfif len(variables.cat_num_prefix) EQ 0>
					AND cat_num_prefix IS NULL
				<cfelse>
					AND cat_num_prefix = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.cat_num_prefix#">
				</cfif>
		),
		steps AS (
			SELECT
				num AS below_num,
				LEAD(num) OVER (ORDER BY num) AS above_num,
				ROW_NUMBER() OVER (ORDER BY num) AS numbers_below,
				count(*) OVER () AS number_total
			FROM numbers
		)
		SELECT
			below_num,
			above_num,
			above_num - below_num - 1 AS jump_size,
			numbers_below,
			number_total - numbers_below AS numbers_above
		FROM steps
		WHERE above_num - below_num > 1
		ORDER BY jump_size DESC, below_num
		FETCH FIRST <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#LARGESTJUMPCOUNT#"> ROWS ONLY
	</cfquery>
	<!--- the cataloged items above each likely entry error, to open and correct --->
	<cfset variables.suspectItems = structNew()>
	<cfloop query="jumps">
		<cfif jumps.jump_size GT jumps.numbers_below AND jumps.numbers_above LTE SUSPECTMAXABOVE>
			<cfquery name="itemsAbove" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="itemsAbove_result">
				SELECT cat_num, cat_num_integer
				FROM cataloged_item
				WHERE
					collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.collection_id#">
					<cfif len(variables.cat_num_prefix) EQ 0>
						AND cat_num_prefix IS NULL
					<cfelse>
						AND cat_num_prefix = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.cat_num_prefix#">
					</cfif>
					AND cat_num_integer > <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#jumps.below_num#">
				ORDER BY cat_num_integer, cat_num
				FETCH FIRST <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#SUSPECTMAXABOVE * 2#"> ROWS ONLY
			</cfquery>
			<cfset variables.suspectItems[jumps.below_num] = itemsAbove>
		</cfif>
	</cfloop>

	<cfset variables.low = summary.lowest>
	<cfset variables.high = summary.highest>
	<cfif len(url.low) GT 0><cfset variables.low = int(url.low)></cfif>
	<cfif len(url.high) GT 0><cfset variables.high = int(url.high)></cfif>
	<cfif variables.low GT variables.high>
		<cfset variables.problem = "The lowest number must not be above the highest.">
		<cfset variables.hasSeries = false>
	</cfif>
</cfif>

<cfif variables.hasSeries>
	<!--- Sentinels one below and one above the range make gaps at either end of it show, when the
		range reaches past the series' own lowest or highest number. --->
	<cfquery name="gaps" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="gaps_result">
		WITH numbers AS (
			SELECT cat_num_integer AS num, min(cat_num) AS cat_num
			FROM cataloged_item
			WHERE
				collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.collection_id#">
				<cfif len(variables.cat_num_prefix) EQ 0>
					AND cat_num_prefix IS NULL
				<cfelse>
					AND cat_num_prefix = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.cat_num_prefix#">
				</cfif>
				AND cat_num_integer BETWEEN <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.low#"> AND <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.high#">
			GROUP BY cat_num_integer
			UNION ALL
			SELECT <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#int(variables.low - 1)#">, NULL FROM dual
			UNION ALL
			SELECT <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#int(variables.high + 1)#">, NULL FROM dual
		),
		found_gaps AS (
			SELECT
				num + 1 AS gap_start,
				LEAD(num) OVER (ORDER BY num) - 1 AS gap_end,
				cat_num AS before_cat_num,
				LEAD(cat_num) OVER (ORDER BY num) AS after_cat_num
			FROM numbers
		)
		SELECT
			found_gaps.gap_start,
			found_gaps.gap_end,
			found_gaps.gap_end - found_gaps.gap_start + 1 AS missing_count,
			found_gaps.before_cat_num,
			found_gaps.after_cat_num
			<cfif variables.showLedgers>
				, ledger.volumename, ledger.volumetype, ledger.volumepage, ledger.startnum, ledger.endnum, ledger.idsurn, ledger.pdsurn, ledger.filename
			</cfif>
		FROM
			found_gaps
			<cfif variables.showLedgers>
				LEFT JOIN MCZBASE.ledgerscans_master ledger ON
					ledger.collection_cde = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.collection_cde#">
					<cfif len(variables.cat_num_prefix) EQ 0>
						AND ledger.cat_num_prefix IS NULL
					<cfelse>
						AND ledger.cat_num_prefix = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.cat_num_prefix#">
					</cfif>
					AND ledger.startnum <= found_gaps.gap_end
					AND ledger.endnum >= found_gaps.gap_start
			</cfif>
		WHERE
			found_gaps.gap_end >= found_gaps.gap_start
		ORDER BY
			found_gaps.gap_start
			<cfif variables.showLedgers>
				, ledger.volumename, ledger.volumepage
			</cfif>
	</cfquery>
	<cfset variables.gapCount = 0>
	<cfset variables.missingTotal = 0>
	<cfset variables.lastGapStart = "">
	<cfloop query="gaps">
		<cfif gaps.gap_start NEQ variables.lastGapStart>
			<cfset variables.gapCount = variables.gapCount + 1>
			<cfset variables.missingTotal = variables.missingTotal + gaps.missing_count>
			<cfset variables.lastGapStart = gaps.gap_start>
		</cfif>
	</cfloop>

	<!--- Downloads. --->
	<cfset variables.fileStem = REReplace("#variables.collection_cde#_#variables.cat_num_prefix#", "[^A-Za-z0-9_]", "", "all")>
	<cfif url.format EQ "csv" AND url.download EQ "gaps">
		<cfheader name="Content-Disposition" value="attachment; filename=catalog_number_gaps_#variables.fileStem#.csv">
		<cfcontent type="text/csv; charset=utf-8" reset="true">
		<cfset variables.csvLines = []>
		<cfset variables.headerLine = "GAP_START,GAP_END,MISSING_COUNT,LAST_BEFORE_GAP,FIRST_AFTER_GAP">
		<cfif variables.showLedgers>
			<cfset variables.headerLine = variables.headerLine & ",VOLUMENAME,VOLUMETYPE,VOLUMEPAGE,STARTNUM,ENDNUM,IDSURN,PDSURN,FILENAME">
		</cfif>
		<cfset arrayAppend(variables.csvLines, variables.headerLine)>
		<cfloop query="gaps">
			<cfset variables.line = "#gaps.gap_start#,#gaps.gap_end#,#gaps.missing_count#,#csvField(gaps.before_cat_num)#,#csvField(gaps.after_cat_num)#">
			<cfif variables.showLedgers>
				<cfset variables.line = variables.line & ",#csvField(gaps.volumename)#,#csvField(gaps.volumetype)#,#gaps.volumepage#,#gaps.startnum#,#gaps.endnum#,#csvField(gaps.idsurn)#,#csvField(gaps.pdsurn)#,#csvField(gaps.filename)#">
			</cfif>
			<cfset arrayAppend(variables.csvLines, variables.line)>
		</cfloop>
		<cfoutput>#arrayToList(variables.csvLines, chr(13) & chr(10))#</cfoutput>
		<cfabort>
	</cfif>
	<cfif url.format EQ "csv" AND url.download EQ "missing">
		<cfif variables.high - variables.low + 1 GT MAXMISSINGRANGE>
			<cfset variables.problem = "The list of missing numbers is limited to a range of #numberFormat(MAXMISSINGRANGE)# numbers; set the lowest and highest numbers closer together.">
		<cfelse>
			<cfquery name="missing" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="missing_result">
				SELECT <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.low#"> + LEVEL - 1 AS missing_number
				FROM dual
				CONNECT BY LEVEL <= <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#int(variables.high - variables.low + 1)#">
				MINUS
				SELECT cat_num_integer
				FROM cataloged_item
				WHERE
					collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.collection_id#">
					<cfif len(variables.cat_num_prefix) EQ 0>
						AND cat_num_prefix IS NULL
					<cfelse>
						AND cat_num_prefix = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.cat_num_prefix#">
					</cfif>
				ORDER BY 1
			</cfquery>
			<cfheader name="Content-Disposition" value="attachment; filename=catalog_numbers_missing_#variables.fileStem#.csv">
			<cfcontent type="text/csv; charset=utf-8" reset="true">
			<cfset variables.csvLines = ["MISSING_NUMBER,MISSING_CATALOG_NUMBER"]>
			<cfloop query="missing">
				<cfset arrayAppend(variables.csvLines, "#missing.missing_number#,#csvField(variables.cat_num_prefix & missing.missing_number)#")>
			</cfloop>
			<cfoutput>#arrayToList(variables.csvLines, chr(13) & chr(10))#</cfoutput>
			<cfabort>
		</cfif>
	</cfif>
</cfif>

<cfset pageTitle = "Catalog Number Gaps">
<cfinclude template="/shared/_header.cfm">
<cfoutput>
<main class="container-fluid py-3" id="content">
	<section class="row mx-0 mb-3" role="search" aria-labelledby="gapSearchHeading">
		<div class="search-box">
			<div class="search-box-header">
				<h1 class="h3 text-white" id="gapSearchHeading">Catalog Number Gaps</h1>
			</div>
			<form class="col-12 px-4 py-2" action="/tools/findGap.cfm" method="get">
				<div class="form-row">
					<div class="col-12 col-md-6 col-xl-4 mb-1">
						<label for="series" class="data-entry-label">Collection and catalog number prefix</label>
						<select name="series" id="series" class="data-entry-select reqdClr" required>
							<option value=""></option>
							<cfset variables.lastCollectionId = "">
							<cfloop query="seriesList">
								<cfif seriesList.collection_id NEQ variables.lastCollectionId>
									<cfif len(variables.lastCollectionId) GT 0></optgroup></cfif>
									<optgroup label="#encodeForHtmlAttribute(seriesList.collection)#">
									<cfset variables.lastCollectionId = seriesList.collection_id>
								</cfif>
								<cfset variables.selected = "">
								<cfif seriesList.currentRow EQ variables.seriesRow>
									<cfset variables.selected = "selected">
								</cfif>
								<cfset variables.prefixLabel = "no prefix">
								<cfif len(seriesList.cat_num_prefix) GT 0>
									<cfset variables.prefixLabel = "prefix #seriesList.cat_num_prefix#">
								</cfif>
								<option value="#encodeForHtmlAttribute(seriesList.collection_id & '|' & seriesList.cat_num_prefix)#" #variables.selected#>#encodeForHtml(seriesList.collection_cde)#, #encodeForHtml(variables.prefixLabel)# (#numberFormat(seriesList.item_count)#)</option>
							</cfloop>
							<cfif len(variables.lastCollectionId) GT 0></optgroup></cfif>
						</select>
					</div>
					<div class="col-6 col-md-3 col-xl-2 mb-1">
						<label for="low" class="data-entry-label">Lowest number (blank for the series' lowest)</label>
						<input type="text" name="low" id="low" class="data-entry-input" inputmode="numeric" value="#encodeForHtmlAttribute(url.low)#">
					</div>
					<div class="col-6 col-md-3 col-xl-2 mb-1">
						<label for="high" class="data-entry-label">Highest number (blank for the series' highest)</label>
						<input type="text" name="high" id="high" class="data-entry-input" inputmode="numeric" value="#encodeForHtmlAttribute(url.high)#">
					</div>
					<div class="col-12 col-xl-4 mb-1 pt-xl-3">
						<cfset variables.checked = "">
						<cfif variables.showLedgers><cfset variables.checked = "checked"></cfif>
						<input type="checkbox" name="ledgers" id="ledgers" value="true" #variables.checked#>
						<label for="ledgers">Show the ledger scans covering each gap</label>
					</div>
				</div>
				<div class="form-row">
					<div class="col-12">
						<button type="submit" class="btn btn-xs btn-primary">Find Gaps</button>
						<a class="btn btn-xs btn-warning" href="/tools/findGap.cfm">New Search</a>
					</div>
				</div>
			</form>
		</div>
	</section>

	<section class="row mx-0 mb-4" aria-labelledby="gapResultsHeading">
		<div class="col-12">
			<cfif len(variables.problem) GT 0>
				<h2 class="h3" id="gapResultsHeading">No Results</h2>
				<div class="alert alert-warning" role="alert">#encodeForHtml(variables.problem)#</div>
			<cfelseif NOT variables.hasSeries>
				<h2 class="h3" id="gapResultsHeading">About this report</h2>
				<p>Pick a collection and catalog number prefix to list the gaps in its catalog numbers: runs of whole numbers with no cataloged item, between the lowest and highest numbers in the series or in the range you give. A number counts as present when any cataloged item has it, whatever its suffix.</p>
			<cfelse>
				<cfset variables.linkParams = "collection_id=#encodeForUrl(variables.collection_id)#&cat_num_prefix=#encodeForUrl(variables.cat_num_prefix)#&low=#encodeForUrl(url.low)#&high=#encodeForUrl(url.high)#">
				<cfif variables.showLedgers>
					<cfset variables.linkParams = "#variables.linkParams#&ledgers=true">
				</cfif>
				<h2 class="h3" id="gapResultsHeading">#numberFormat(variables.gapCount)# gaps, #numberFormat(variables.missingTotal)# missing numbers: #encodeForHtml(variables.seriesName)#</h2>
				<dl class="row small mb-2">
					<dt class="col-6 col-md-3 col-xl-2">Cataloged items</dt><dd class="col-6 col-md-3 col-xl-2">#numberFormat(summary.item_count)#</dd>
					<dt class="col-6 col-md-3 col-xl-2">Distinct numbers</dt><dd class="col-6 col-md-3 col-xl-2">#numberFormat(summary.number_count)#</dd>
					<dt class="col-6 col-md-3 col-xl-2">Series' lowest and highest</dt><dd class="col-6 col-md-3 col-xl-2">#summary.lowest# &ndash; #summary.highest#</dd>
					<dt class="col-6 col-md-3 col-xl-2">Range looked at</dt><dd class="col-6 col-md-3 col-xl-2">#variables.low# &ndash; #variables.high#</dd>
					<dt class="col-6 col-md-3 col-xl-2">Items with a suffix</dt><dd class="col-6 col-md-3 col-xl-2">#numberFormat(summary.suffix_count)#</dd>
					<dt class="col-6 col-md-3 col-xl-2">Numbers on more than one item</dt><dd class="col-6 col-md-3 col-xl-2">#numberFormat(summary.shared_count)#</dd>
				</dl>
				<cfset variables.ledgerParam = "">
				<cfif variables.showLedgers>
					<cfset variables.ledgerParam = "&ledgers=true">
				</cfif>
				<cfif jumps.recordcount GT 0>
					<h3 class="h4" id="jumpsHeading">Widest jumps in the series</h3>
					<p class="small mb-1">A number entered with extra digits, such as 999999999 for 999999, shows as a jump wider than all the numbers below it, with few numbers above. Those are marked as likely entry errors and their cataloged items listed; until they are corrected, set the highest number below them to keep them out of the gaps and missing number counts.</p>
					<table class="table table-responsive d-xl-table table-sm" aria-labelledby="jumpsHeading">
						<thead>
							<tr>
								<th scope="col" aria-sort="descending">Missing in it</th>
								<th scope="col">Jump</th>
								<th scope="col">Numbers below</th>
								<th scope="col">Numbers above</th>
								<th scope="col">Likely entry error</th>
							</tr>
						</thead>
						<tbody>
							<cfloop query="jumps">
								<tr>
									<td><strong>#numberFormat(jumps.jump_size)#</strong></td>
									<td>#jumps.below_num# to #jumps.above_num#</td>
									<td>#numberFormat(jumps.numbers_below)#</td>
									<td>#numberFormat(jumps.numbers_above)#</td>
									<td>
										<cfif structKeyExists(variables.suspectItems, jumps.below_num)>
											<cfset variables.itemsAbove = variables.suspectItems[jumps.below_num]>
											<strong>Yes:</strong>
											<cfloop query="variables.itemsAbove">
												<a href="/guid/#encodeForUrl(variables.institution_acronym)#:#encodeForUrl(variables.collection_cde)#:#encodeForUrl(variables.itemsAbove.cat_num)#" target="_blank">#encodeForHtml(variables.itemsAbove.cat_num)#</a><cfif variables.itemsAbove.currentRow LT variables.itemsAbove.recordcount>,</cfif>
											</cfloop>
											<cfif variables.itemsAbove.recordcount EQ SUSPECTMAXABOVE * 2>and more</cfif>
											<br><a href="/tools/findGap.cfm?collection_id=#encodeForUrl(variables.collection_id)#&cat_num_prefix=#encodeForUrl(variables.cat_num_prefix)#&low=#encodeForUrl(url.low)#&high=#jumps.below_num##variables.ledgerParam#">Find gaps up to #jumps.below_num# only</a>
										<cfelse>
											No
										</cfif>
									</td>
								</tr>
							</cfloop>
						</tbody>
					</table>
				</cfif>
				<p>
					<a class="btn btn-xs btn-secondary" href="/tools/findGap.cfm?#variables.linkParams#&format=csv&download=gaps">Download Gaps (CSV)</a>
					<a class="btn btn-xs btn-secondary" href="/tools/findGap.cfm?#variables.linkParams#&format=csv&download=missing">Download Every Missing Number (CSV)</a>
					<a class="ml-2" href="/tools/findGap.cfm?#variables.linkParams#">Link to this report</a>
				</p>
				<cfif variables.gapCount EQ 0>
					<p>There are no gaps in this range of the series.</p>
				<cfelse>
					<a class="sr-only sr-only-focusable" href="##afterGapTable">Skip past the gaps</a>
					<table class="table table-responsive d-xl-table table-sm table-striped" aria-labelledby="gapResultsHeading">
						<thead>
							<tr>
								<th scope="col">Gap</th>
								<th scope="col">Missing</th>
								<th scope="col">Last before the gap</th>
								<th scope="col">First after the gap</th>
								<cfif variables.showLedgers><th scope="col">Ledger scans covering the gap</th></cfif>
							</tr>
						</thead>
						<tbody>
							<cfloop query="gaps" group="gap_start">
								<tr>
									<td>
										#variables.cat_num_prefix##gaps.gap_start#<cfif gaps.gap_end NEQ gaps.gap_start> &ndash; #variables.cat_num_prefix##gaps.gap_end#</cfif>
									</td>
									<td>#numberFormat(gaps.missing_count)#</td>
									<td>
										<cfif len(gaps.before_cat_num) GT 0>
											<a href="/guid/#encodeForUrl(variables.institution_acronym)#:#encodeForUrl(variables.collection_cde)#:#encodeForUrl(gaps.before_cat_num)#" target="_blank">#encodeForHtml(variables.collection_cde)# #encodeForHtml(gaps.before_cat_num)#</a>
										<cfelse>
											(start of range)
										</cfif>
									</td>
									<td>
										<cfif len(gaps.after_cat_num) GT 0>
											<a href="/guid/#encodeForUrl(variables.institution_acronym)#:#encodeForUrl(variables.collection_cde)#:#encodeForUrl(gaps.after_cat_num)#" target="_blank">#encodeForHtml(variables.collection_cde)# #encodeForHtml(gaps.after_cat_num)#</a>
										<cfelse>
											(end of range)
										</cfif>
									</td>
									<cfif variables.showLedgers>
										<td>
											<cfset variables.ledgerCount = 0>
											<cfloop>
												<cfif len(gaps.volumename) GT 0 OR len(gaps.idsurn) GT 0>
													<cfset variables.ledgerCount = variables.ledgerCount + 1>
													<div>
														#encodeForHtml(gaps.volumename)#<cfif len(gaps.volumepage) GT 0>, page #encodeForHtml(gaps.volumepage)#</cfif>
														(#encodeForHtml(gaps.startnum)#&ndash;#encodeForHtml(gaps.endnum)#)
														<!--- linked only when an identifier has the characters a URN uses: IDS for the page image, PDS for the volume to page through --->
														<cfif REFind("^[A-Za-z0-9:._\-]+$", gaps.idsurn) GT 0>
															<a href="#VIEWERBASE##gaps.idsurn#" target="_blank">Page image<span class="sr-only"> of #encodeForHtml(gaps.volumename)# page #encodeForHtml(gaps.volumepage)#</span></a>
														</cfif>
														<cfif REFind("^[A-Za-z0-9:._\-]+$", gaps.pdsurn) GT 0>
															<a class="ml-2" href="#VIEWERBASE##gaps.pdsurn#?buttons=y" target="_blank">Page 1 of Page Turned Volume<span class="sr-only"> #encodeForHtml(gaps.volumename)#</span></a>
														</cfif>
													</div>
												</cfif>
											</cfloop>
											<cfif variables.ledgerCount EQ 0>None found</cfif>
										</td>
									</cfif>
								</tr>
							</cfloop>
						</tbody>
					</table>
					<div id="afterGapTable" tabindex="-1"></div>
				</cfif>
			</cfif>
		</div>
	</section>
</main>
</cfoutput>
<cfinclude template="/shared/_footer.cfm">
