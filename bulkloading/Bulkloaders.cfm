<cfset pageTitle = "Bulkloaders">
<cfinclude template = "/shared/_header.cfm">

<cfoutput>
	<main class="container py-3">
		<section class="row">
			<div class="col-12 mt-4">
				<h1 class="h2">Tools for Adding or Modifing MCZbase Records in Bulk</h1>
				<h2 class="h3">Select a Template</h2>
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
					<li><a href="/tools/BulkloadNewParts.cfm">Bulkload New Parts</a></li>
					<li><a href="/tools/BulkloadEditedParts.cfm">Bulkload Edited Parts</a></li>
					<li><a href="/tools/BulkloadAttributes.cfm">Bulkload Attributes</a></li>
					<li><a href="/tools/BulkloadCitations.cfm">Bulkload Citations</a></li>
					<li><a href="/tools/BulkloadOtherId.cfm">Bulkload Identifiers</a></li>
					<li><a href="/tools/loanBulkload.cfm">Bulkload Loan Items</a></li>
					<li><a href="/DataServices/agents.cfm">Bulkload Agents</a></li>
					<li><a href="/tools/BulkloadIdentification.cfm">Bulkload Identifications</a></li>
					<li><a href="/tools/DataLoanBulkload.cfm">Bulkload Data Loans</a></li>
					<li><a href="/tools/BulkloadPartContainer.cfm">Bulkload Parts to Containers</a></li>
					<li><a href="/tools/BulkloadContEditParent.cfm">Bulkload Container - Edit Parent</a></li>
					<li><a href="/tools/BulkloadMedia.cfm">Bulkload Media </a></li>
					<li><a href="/tools/BulkloadRelations.cfm">Bulkload Relationships</a></li>
					<li><a href="/tools/BulkloadGeoref.cfm">Bulkload Georeferences</a></li>
				</ul>
			</div>
			</div>
		</section>
	</main>
</cfoutput>
<cfinclude template = "/shared/_footer.cfm">

