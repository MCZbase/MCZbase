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
					<li><a href="/Bulkloader/bulkloaderBuilder.cfm">Bulkload Builder</a> (Create CSV files for Specimen Bulkloader)</li>
					<li><a href="/Bulkloader/BulkloadSpecimens.cfm">Bulkload Specimens</a> (Load CSV files into Specimen Bulkloader)</li>
					<li><a href="/Bulkloader/browseBulk.cfm">Browse and Edit</a> (Records in Specimen Bulkloader)</a></li>
					<li><a href="/Bulkloader/bulkloader_status.cfm">Bulkloader Status</a> (status values for records in the Specimen Bulkloader)</li>
					<li><a href="/Bulkloader/">Bulkload Specimens Instructions</a></li>
				</ul>
				<h3 class="h4">Add Data to Existing Specimens (batch tools)</h3>
				<ul>
					<li><a href="/tools/BulkloadNewParts.cfm">Bulkload New Parts</a></li>
					<li><a href="/tools/BulkloadAttributes.cfm">Bulkload Attributes</a></li>
					<li><a href="/tools/BulkloadCitations.cfm">Bulkload Citations</a></li>
					<li><a href="/tools/BulkloadOtherId.cfm">Bulkload Identifiers</a> (bulk add Other ID numbers)</li>
					<li><a href="/tools/BulkloadIdentification.cfm">Bulkload Identifications</a></li>
					<li><a href="/tools/BulkloadRelations.cfm">Bulkload Relationships</a> (add relationships between specimens)</li>
				</ul>
				<h3 class="h4">Manipulate existing data</h3>
				<ul>
					<li><a href="/tools/BulkloadLoanItems.cfm">Bulkload Loan Items</a> (bulk add parts to loans) *</li>
					<li><a href="/tools/BulkloadEditedParts.cfm">Bulkload Edited Parts</a> (edit part data, or append to part remarks) *</li>
					<li><a href="/tools/BulkloadPartContainer.cfm">Bulkload Parts to Containers</a> (place parts in containers) *</li>
					<li><a href="/tools/BulkloadContEditParent.cfm">Bulkload Container - Edit Parent</a> (move containers into containers</li>
					<li>Bulkloaders marked with * can work with Specimen Search -> Manage -> Parts Report/Download csv files.</li>
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

