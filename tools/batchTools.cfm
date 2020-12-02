<cfset pageTitle = "Batch Tools">
<cfinclude template = "/shared/_header.cfm">
<cfoutput>
<main class="container py-3">
	<section class="row">
		<div class="col-12">
			<h1 class="h2">Batch Tools</h1>
			<div class="accordion w-100" id="accordionForNewParts">
				<div class="card mb-2">
					<div class="card-header w-100" id="headingPart1">
						<h2 class="h4 my-0 float-left">  
							<a class="btn-link text-black" role="button" data-toggle="collapse" data-target="##collapseForNewParts">
								Bulk Add New Parts to Existing Specimen Records
							</a>
						</h2>
					</div>
					<div class="card-body px-3 py-0">
						<div id="collapseForNewParts" class="" aria-labelledby="headingPart1" data-parent="##accordionForNewParts">
							<div class="row">
								<div class="col-12 col-lg-6">
									<div class="accordion w-100" id="accordionForNewParts">
										<!--- included subspecies --->
				
										<div class="card mb-2">
											<div class="card-header w-100" id="headingPart1">
												<h2 class="h4 my-0 float-left">  
													<a class="btn-link text-black" role="button" data-toggle="collapse" data-target="##collapseForNewParts">
														Bulk Add New Parts 
													</a>
												</h2>
											</div>
											<div class="card-body px-3 py-0">
												<div id="collapseForNewParts" class="" aria-labelledby="headingPart1" data-parent="##accordionForNewParts">
													<div class="row">
														<div class="col-12">Hello again</div>
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
					
					
		<div class="accordion w-100" id="accordionForEditParts">
				<div class="card mb-2">
					<div class="card-header w-100" id="headingPart2">
						<h2 class="h4 my-0 float-left">  
							<a class="btn-link text-black" role="button" data-toggle="collapse" data-target="##collapseForEditParts">
								Bulk Edit Parts to Existing Specimen Records
							</a>
						</h2>
					</div>
					<div class="card-body px-3 py-0">
						<div id="collapseForEditParts" class="" aria-labelledby="headingPart2" data-parent="##accordionForEditParts">
							<div class="row">
								<div class="col-12 col-lg-6">
									<div class="accordion w-100" id="accordionForEditParts">
										<!--- included subspecies --->
				
										<div class="card mb-2">
											<div class="card-header w-100" id="headingPart2">
												<h2 class="h4 my-0 float-left">  
													<a class="btn-link text-black" role="button" data-toggle="collapse" data-target="##collapseForEditParts">
														Bulk Add New Parts 
													</a>
												</h2>
											</div>
											<div class="card-body px-3 py-0">
												<div id="collapseForEditParts" class="" aria-labelledby="headingPart2" data-parent="##accordionForEditParts">
													<div class="row">
														<div class="col-12">Hello</div>
													</div>
												</div><!--- collapseForEditParts --->
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
	</cfoutput>
<cfinclude template = "/shared/_footer.cfm">
