<cfset pageTitle = "Reports">
<cfinclude template = "/shared/_header.cfm">

<cfoutput>
	<main class="container py-3">
		<section class="row">
			<div class="col-12">
				<h1 class="h2">Reports</h1>
				<ul>	
					<li class="py-1"><a href="/info/recentgeorefs.cfm">Recently Georeferenced Localities</a> &nbsp; listed by collection or timeframe; sort by oldest, newest; links to each locality georeferenced</li>
					<li class="py-1"><a href="/info/collnHoldgByClass.cfm">Holdings by Class</a> &nbsp; lists collection alphabetically in the first column; lists class alphabetically in the second column; sum of parts with that name in MCZbase in the third column; count of part name used per collection with link to specimen results</li> 
					<li class="py-1"><a href="/info/noParts.cfm">Partless Specimen Records</a> &ndash; Find specimens with no parts per collection (or in all collections) </li>
					<li class="py-1"><a href="/Reports/partusage.cfm">Part Usage</a> &ndash; Part name usage &ndash; Part in first column (e.g., brain, cast, whole animal); isTissue in the second column; sum of parts with that name in the third column; count of part name used per collection with link to specimen results. </li> 		
				 	<li class="py-1"><a href="/Taxa.cfm?execute=true&method=getTaxa&action=search&kingdom=NULL&phylum=NULL&phylclass=NULL&phylorder=NULL&family=NULL">Missing Higher Taxonomy</a> &ndash; No kingdom, phylumn, class, order, or family filled in with "Null" with a query on Taxa.cfm</li>
					<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"global_admin")>
						<br/><br/>
						<li><a href="/info/mia_in_genbank.cfm">Genbank Missing Data</a></li>
						<li><a href="/info/slacker.cfm">Suspect Data</a></li>
						<li><a href="/tools/findGap.cfm">Catalog Number Gaps</a></li>
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
