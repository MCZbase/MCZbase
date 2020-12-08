<cfset pageTitle = "Batch Tools">
<cfinclude template = "/shared/_header.cfm">

<cfoutput>
	<main class="container py-3">
		<section class="row">
			<div class="col-12">
				<h1 class="h2">Reports</h1>
				<div class="card-columns">
				<ul>
					<cfif targetMenu EQ "production">		
					<li><a href="/info/recentgeorefs.cfm">Recently Georeferenced Localities</a></li>
					<cfelse>
					<li><a class="bg-warning" href="">Recently Georeferenced Localities</a></li> 
					</cfif>
					<cfif targetMenu EQ "production">		
					<li><a href="/info/mia_in_genbank.cfm">Genbank Missing Data</a></li> 
					<cfelse>
					<li><a class="bg-warning" href="">Genbank Missing Data</a></li>
					</cfif>
					<cfif targetMenu EQ "production">		
						<li><a href="/info/collnHoldgByClass.cfm">Holdings by Class</a></li> 
					<cfelse>
						<li><a class="bg-warning" href="">Holdings by Class</a> </li> 
					</cfif>
					<cfif targetMenu EQ "production">		
						<li><a href="/Admin/bad_taxonomy.cfm">Invalid Taxonomy</a> </li> 
					<cfelse>
						<li><a class="bg-warning" href="">Invalid Taxonomy</a> </li> 
					</cfif>
					<cfif targetMenu EQ "production">		
						<li><a href="/tools/TaxonomyScriptGap.cfm">Taxonomy Gaps</a> </li> 
					<cfelse>
						<li><a class="bg-warning" href="">Taxonomy Gaps</a> </li> 
					</cfif>
					<cfif targetMenu EQ "production">		
						<li><a href="/tools/TaxonomyGaps.cfm">Messy Taxonomy</a> </li> 
					<cfelse>
						<li><a class="bg-warning" href="">Messy Taxonomy</a> </li> 
					</cfif>
					<cfif targetMenu EQ "production">		
						<li><a href="/info/slacker.cfm">Suspect Data</a> </li> 
					<cfelse>
						<li><a class="bg-warning" href="">Suspect Data</a> </li> 
					</cfif>
					<cfif targetMenu EQ "production">		
						<li><a href="/Reports/partusage.cfm">Part Usage</a> </li> 
					<cfelse>
						<li><a class="bg-warning" href="">Part Usage</a> </li> 
					</cfif>
					<cfif targetMenu EQ "production">		
						<li><a href="/info/noParts.cfm">Partless Specimen Records</a> </li> 
					<cfelse>
						<li><a class="bg-warning" href="">Partless Specimen Records</a> </li> 
					</cfif>
					<cfif targetMenu EQ "production">		
						<li><a href="/tools/findGap.cfm">Catalog Number Gaps</a> </li> 
					<cfelse>
						<li><a class="bg-warning" href="">Catalog Number Gaps</a> </li> 
					</cfif>
					<cfif targetMenu EQ "production">		
						<li><a href="/info/dupAgent.cfm">Duplicate Agents</a></li> 
					<cfelse>
						<li><a class="bg-warning" href="">Duplicate Agents</a></li> 
					</cfif>							
	
					<li><a href="/tools/BulkloadPartContainer.cfm">Audit Sql</a></li>
					<li><a href="/tools/BulkloadOtherId.cfm">Download Tables</a></li>
					<li><a href="/tools/BulkloadContEditParent.cfm">Oracle Roles</a></li>
					<li><a href="/tools/DataLoanBulkload.cfm">Write SQL</a></li>
				</ul>
			</div>
		</div>
		</section>
	</main>
</cfoutput>
<cfinclude template = "/shared/_footer.cfm">

