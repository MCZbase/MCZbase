<cfset pageTitle = "Named Group">
<cfinclude template="/shared/_header.cfm">

<cfoutput>
	<main class="container py-3">
		<div class="row">
			<article class="w-100">
				<div class="col-12">
					<div class="col-12 col-md-6">
						<h1>Hassler Expedition</h1>
						<hr>
						<p>Description</p>
						<hr>
						<div class="bg-white border border-dark">
							<figure> <img src="../images/D_arenaria.jpg" class="p-2 w-100 border"/>
								<figcaption>Featured Image for the Hassler Expedition</figcaption>
							</figure>
						</div>
					</div>
					<div class="col-12 col-md-3">
						<h2>Related Information</h2>
						<hr>
						<h3>Localities</h3>
						<p>Higher Geographies Visited</p>
						<figure>
							<img src="../images/northern.gif" class="p-2 w-100 border"/>
							<figcaption>Maps and location images</figcaption>
						</figure>
						<hr>
						</div>
				</div>
			</article>
		</div>
	</main>
	<!--- class="container" ---> 
</cfoutput>
<cfinclude template = "/shared/_footer.cfm">
