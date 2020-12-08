<cfset pageTitle = "Batch Tools">
<cfinclude template = "/shared/_header.cfm">

<cfoutput>
	<main class="container py-3">
		<section class="row">
			<div class="col-12">
				<h1 class="h2">Modify Records in Bulk</h1>
				<h2 class="h3">Select a Batch Tool</h2>
				<ul>
					<li><a href="/tools/BulkloadNewParts.cfm">Bulkload New Parts</a></li>
					<li><a href="/tools/BulkloadEditedParts.cfm">Bulkload Edited Parts</a></li>
					<li><a href="/tools/BulkloadAttributes.cfm">Bulkload Attributes</a></li>
					<li><a href="/tools/BulkloadCitations.cfm">Bulkload Citations</a></li>
					<li><a href="/tools/BulkloadOtherId.cfm">Bulkload Identifierss</a></li>
					<li><a href="/tools/loanBulkload.cfm">Bulkload Loan Items</a></li>
					<li><a href="/tools/DataLoanBulkload.cfm">Bulkload Data Loans</a></li>
					<li><a href="/DataServices/agents.cfm">Bulkload Agents</a></li>
					<li><a href="/tools/BulkloadPartContainer.cfm">Bulkload Part to Containers</a></li>
					<li><a href="/tools/BulkloadOtherId.cfm">Identifications</a></li>
					<li><a href="/tools/BulkloadContEditParent.cfm">Bulkload Container Edit Parent</a></li>
					<li><a href="/tools/DataLoanBulkload.cfm">Bulkload New Parts</a></li>
					<li><a href="/tools/BulkloadMedia.cfm">Bulkload Media </a></li>
					<li><a href="/tools/BulkloadRelations.cfm">Bulkload Relationships</a></li>
					<li><a href="/tools/BulkloadGeoref.cfm">Bulkload Georeferences</a></li>
			</div>
		</section>
	</main>
</cfoutput>
<cfinclude template = "/shared/_footer.cfm">

