<!---
/reporting/Reports.cfm

Copyright 2021 President and Fellows of Harvard College

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
Landing pad page with lists of various self service reports.
--->
<cfset pageTitle = "Reports">
<cfinclude template = "/shared/_header.cfm">

<cfoutput>
	<main class="container py-3">
		<section class="row">
			<div class="col-12">
				<h1 class="h2">Reports</h1>
				<ul>
					<li class="py-1"><a href="/info/recentgeorefs.cfm">Recently Georeferenced Localities</a> &ndash; Listed by collection or timeframe; sort by oldest, newest; links to each locality georeferenced</li>
					<li class="py-1"><a href="/info/collnHoldgByClass.cfm">Holdings by Class</a> &ndash; Report lists collection alphabetically in the first column; lists class alphabetically in the second column; sum of parts with that name in MCZbase in the third column; count of part name used per collection with link to specimen results</li>
					<li class="py-1"><a href="/info/noParts.cfm">Partless Specimen Records</a> &ndash; Find specimens with no parts per collection (or in all collections) </li>
					<li class="py-1"><a href="/reporting/PartUsageReport.cfm">Part Usage</a> &ndash; Distribution of Part name usage by collection. &ndash; Part names (e.g., partial animal, cast, whole animal); <em>is Tissue</em> codings of that part name; with sums of parts by name and; count of part name by collection with links to specimens.</li>
				 	<li class="py-1"><a href="/Taxa.cfm?execute=true&method=getTaxa&action=search&kingdom=NULL&phylum=NULL&phylclass=NULL&phylorder=NULL&family=NULL">Missing Higher Taxonomy</a> &ndash; No kingdom, phylumn, class, order, or family (using "Null" in a query on Taxa.cfm)</li>
				 	<li class="py-1"><a href="/tools/findGap.cfm">Catalog Number Gaps</a> &ndash; Show gaps in Catalog Number series</li>
					<li class="py-1"><a href="/reporting/PrimaryTypes.cfm">Primary Types</a> &ndash; Obtain reports by collection.</li>
					<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_locality")>
				 		<li class="py-1"><a href="/reporting/UnknownSovereignNation.cfm">Unknown Sovereign Nation</a> &ndash; Find localities with [unknown] Sovereign Nation for cleanup.</li>
					</cfif>
					<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"global_admin")>
						<br/>
						<h2 class="h3">Broken or Problematic Reports</h1>
						<li><a href="/info/mia_in_genbank.cfm">Genbank Missing Data</a></li>
						<li><a href="/info/slacker.cfm">Suspect Data</a></li>
						<li><a href="/info/dupAgent.cfm">Duplicate Agents</a></li>
						<li><a href="/Admin/bad_taxonomy.cfm">Invalid Taxonomy</a></li>
						<li><a href="/tools/TaxonomyScriptGap.cfm">Taxonomy Gaps</a></li>
						<li><a href="/tools/TaxonomyGaps.cfm">Messy Taxonomy</a></li>
					</cfif>
				</ul>
			</div>
		</section>
	</main>
</cfoutput>
<cfinclude template = "/shared/_footer.cfm">
