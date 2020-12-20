<cfset pageTitle = "Reports">
<cfinclude template = "/shared/_header.cfm">

<cfoutput>
	<main class="container py-3">
		<section class="row">
			<div class="col-12">
				<h1 class="h2">Reports</h1>
				<ul>	
					<li><a href="/info/recentgeorefs.cfm">Recently Georeferenced Localities</a></li>
					<li><a href="/info/mia_in_genbank.cfm">Genbank Missing Data</a></li> 
					<li><a href="/info/collnHoldgByClass.cfm">Holdings by Class</a></li> 
					<li><a href="/Admin/bad_taxonomy.cfm">Invalid Taxonomy</a> </li> 		
					<li><a href="/tools/TaxonomyScriptGap.cfm">Taxonomy Gaps</a> </li> 
					<li><a href="/tools/TaxonomyGaps.cfm">Messy Taxonomy</a> </li> 		
					<li><a href="/info/slacker.cfm">Suspect Data</a> </li> 		
					<li><a href="/Reports/partusage.cfm">Part Usage</a> </li> 		
					<li><a href="/info/noParts.cfm">Partless Specimen Records</a> </li> 
					<li><a href="/tools/findGap.cfm">Catalog Number Gaps</a> </li> 		
					<li><a href="/info/dupAgent.cfm">Duplicate Agents</a></li> 						
				</ul>
			</div>
		</section>
	</main>
</cfoutput>
<cfinclude template = "/shared/_footer.cfm">
