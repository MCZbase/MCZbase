<cfset pageTitle = "Bulkloaders">
<cfinclude template = "/shared/_header.cfm">

<cfoutput>
	<main class="container py-3">
		<section class="row">
			<div class="col-12 mt-4">
				<h1 class="h2">Tools for Adding or Modifing MCZbase Records in Bulk</h1>
				<div class="">
					<h3 class="h4">Bulkload Specimens</h3>
				<ul>
					<li><a href="/Bulkloader/">Bulkload Specimens</a></li>
					<li><a href="/Bulkloader/bulkloader_status.cfm">Bulkloader Status</a></li>
					<li><a href="/Bulkloader/bulkloaderBuilder.cfm">Bulkload Builder</a></li>
					<li><a href="/Bulkloader/browseBulk.cfm">Browse Bulkloader</a></li>
				</ul>
				<h3 class="h4">Add Data to Existing Specimens (batch tools)</h3>
				<ul>
					<cfif findNoCase('redesign',Session.gitBranch) EQ 0>
						<!--- TODO: remove this test when switchover to BulkloadNewParts is complete --->
						<!--- Deprecated --->
						<li><a href="/tools/BulkloadParts.cfm">Bulkload New Parts</a></li>
					<cfelse>
						<!--- currently only for use in redesign2 branch --->
						<li><a href="/tools/BulkloadNewParts.cfm">Bulkload New Parts</a></li>
					</cfif>
					<li><a href="/tools/BulkloadAttributes.cfm">Bulkload Attributes</a></li>
					<li><a href="/tools/BulkloadCitations.cfm">Bulkload Citations</a></li>
					<li><a href="/tools/BulkloadOtherId.cfm">Bulkload Identifiers (bulk add Other ID numbers)</a></li>
					<cfif findNoCase('redesign',Session.gitBranch) EQ 0>
						<!--- TODO: remove this test when switchover to BulkloadLoanItems is complete --->
						<!--- Deprecated? --->
						<li><a href="/tools/loanBulkload.cfm">Bulkload Loan Items (bulk add parts to loans)</a></li>
					<cfelse>
						<!--- currently only for use in redesign2 branch --->
						<li><a href="/tools/BulkloadLoanItems.cfm">Bulkload Loan Items (bulk add parts to loans)</a></li>
					</cfif>
					<li><a href="/tools/BulkloadIdentification.cfm">Bulkload Identifications</a></li>
					<li><a href="/tools/BulkloadRelations.cfm">Bulkload Relationships (add relationships between specimens)</a></li>
					<li><a href="/tools/BulkloadPartContainer.cfm">Bulkload Parts to Containers (place parts in containers)</a></li>
				</ul>
				<h3 class="h4">Manipulate existing data</h3>
				<ul>
					<li><a href="/tools/BulkloadEditedParts.cfm">Bulkload Edited Parts (edit part data, or append to part remarks)</a></li>
					<li><a href="/tools/BulkloadContEditParent.cfm">Bulkload Container - Edit Parent</a></li>
				</ul>
				<h3 class="h4">Bulkload Data Other than Specimens</h3>
				<ul>
					<li><a href="/tools/BulkloadAgents.cfm">Bulkload Agents</a></li>
					<li><a href="/tools/BulkloadMedia.cfm">Bulkload Media Records</a></li>
					<li><a href="/tools/BulkloadGeoref.cfm">Bulkload Georeferences</a></li>
				</ul>
				<h3 class="h4">Unused</h3>
					<li><a href="/tools/DataLoanBulkload.cfm" class="text-muted">Bulkload Data Loans </a></li>
				<ul>
				</ul>
			</div>
			</div>
		</section>
	</main>
</cfoutput>
<cfinclude template = "/shared/_footer.cfm">

