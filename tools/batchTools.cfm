<cfset pageTitle = "Batch Tools">
<cfinclude template = "/shared/_header.cfm">

<main class="container py-3">
	<section class="row">
		<div class="col-12">
			<h1 class="h2">Batch Tools</h1>
			<div class="accordion w-100" id="accordionForTaxa">
				<cfif qsubspecies.recordcount LT 10 AND qspecies.recordcount LT 10>
					<cfset collapsed = "">
					<cfset collapseshow = "collapse show">
				<cfelse>
					<cfset collapsed = "collapsed">
					<cfset collapseshow = "collapse">
				</cfif>
				<div class="card mb-2">
					<div class="card-header w-100" id="headingPart">
						<h2 class="h4 my-0 float-left">  
							<a class="btn-link text-black #collapsed#" role="button" data-toggle="collapse" data-target="##collapseRelatedTaxa">
								Bulk Add New Parts to Existing Specimen Records
							</a>
						</h2>
					</div>
					<div class="card-body px-3 py-0">
						<div id="collapseRelatedTaxa" class="#collapseshow#" aria-labelledby="headingPart" data-parent="##accordionForTaxa">
							<div class="row">
								<div class="col-12 col-lg-6">
									<div class="accordion w-100" id="accordionForTaxa">
										<!--- included subspecies --->
				
										<div class="card mb-2">
											<div class="card-header w-100" id="headingPart">
												<h2 class="h4 my-0 float-left">  
													<a class="btn-link text-black #collapsed#" role="button" data-toggle="collapse" data-target="##collapseRelatedTaxa">
														Bulk Add New Parts 
													</a>
												</h2>
											</div>
											<div class="card-body px-3 py-0">
												<div id="collapseRelatedTaxa" class="#collapseshow#" aria-labelledby="headingPart" data-parent="##accordionForTaxa">
													<div class="row">
														<div class="col-12"></div>
													</div>
												</div><!--- collapseRelatedTaxa --->
											</div>
										</div>
									</div><!--- accordion --->
								</div>
							</div>
						</div>
					</div>
				</div>
			</div>
		</div>
	</section>
</main>
<cfinclude template = "/shared/_footer.cfm">
