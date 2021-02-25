<cfset pageTitle = "Named Group">
<cfinclude template="/shared/_header.cfm">

<cfoutput>
	<main class="container py-3">
		<div class="row">
			<article class="w-100">
				<div class="col-12">
					<div class="form-row">
					<div class="col-12 col-md-5 mr-2 float-left">
						<h1>Hassler Expedition</h1>
						<hr>
						<p>Description</p>
						<hr>
						<div class="bg-white p-2 border border-dark">
							<figure> <img src="/images/media_feature_grouping.png" class="p-2 w-100 border"/>
								<figcaption class="pt-2">Featured Image for the Hassler Expedition</figcaption>
							</figure>
						</div>
					</div>
					<div class="col-12 col-md-3 mr-2 float-left">
						<h2 class="h1">Related Information</h2>
						<hr>
						<h3>Localities</h3>
						<p>Higher Geographies Visited</p>
						<figure>
							<img src="http://mczbase.mcz.harvard.edu/specimen_images/entomology/large/MCZ-ENT00014536_Tachypeza_rostrata_hal.jpg" class="p-2 w-100 border"/>
							<figcaption>Maps and location images</figcaption>
						</figure>
						<hr>
						<h3>Collectors and other agents</h3>
						<p>Blake, James Henry</p>
						<figure>
							<img src="/images/student_images.png" class="p-2 w-100 border"/>
							<figcaption>James Henry Blake</figcaption>
						</figure>
						<hr>
						</div>
					</div>
				</div>
			</article>
		</div>
	</main>
	<!--- class="container" ---> 
</cfoutput>
<cfinclude template = "/shared/_footer.cfm">
