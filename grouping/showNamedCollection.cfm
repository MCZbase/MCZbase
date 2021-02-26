<cfset pageTitle = "Named Group">
<cfinclude template="/shared/_header.cfm">

<cfoutput>
	<main class="container py-3">
		<div class="row">
			<article class="w-100">
				<div class="col-12">
					<ul class="list-group py-2 border-top border-bottom border-light float-left d-inline">
						<li class="list-group-item">Aves</li>
						<li class="list-group-item">Amphibia</li>
						<li class="list-group-item">Reptilia</li>
						<li class="list-group-item">Cephalopoda</li>
					</ul>
					<div class="row">
						<div class="col-12 col-md-6 px-0 float-left mt-4">
							<h1>Hassler Expedition</h1>
							<hr>
							<p>Information used in researching the Hassler Expedition, December 4, 1871 - October 1872. Louis Agassiz, Franz Steindachner (ichthyologist), LF dePourtales and others - Left Boston 4 Dec 1871, traveled through the Straits of Magellan on to San Francisco California, arrived in San Francisco 31 August 1872. They then traveled back to Cambridge cross land arriving by October 1872. While in the Straits of Magellan, the dredging gear broke. Most specimens had a collection date of 1872 following the break. The journal of James Henry Blake, student of Louis Agassiz and an artist, provided much information for the collections.</p>
							<hr>
							<h2 class="h1 mt-5 pt-3" style="border-top: 8px solid ##000">Featured Information</h2>
							<hr>
							<div class="row mx-0">
								<div class="col-12 col-md-4 px-0">
									<h3>Localities</h3>
									<p>Maps and location images</p>
									<div id="carouselExampleControls4" class="carousel slide" data-keyboard="true">
										<div class="carousel-inner">
											<div class="carousel-item active"> <img class="d-block w-100" src="/images/Hassler_expedition_route.png" alt="First slide"> </div>
											<div class="carousel-item"> <img class="d-block w-100" src="/images/dredging_stations.png" alt="Second slide"> </div>
											<div class="carousel-item"> <img class="d-block w-100" src="/images/Hassler_expedition_route.png" alt="Third slide"> </div>
										</div>
										<a class="carousel-control-prev" href="##carouselExampleControls4" role="button" data-slide="prev"> <span class="carousel-control-prev-icon" aria-hidden="true"></span> <span class="sr-only">Previous</span> </a> <a class="carousel-control-next" href="##carouselExampleControls" role="button" data-slide="next"> <span class="carousel-control-next-icon" aria-hidden="true"></span> <span class="sr-only">Next</span> </a> 
									</div>
								</div>
								<div class="col-12 col-md-4 border">
									<h3>Journals, Notes, Ledgers</h3>
									<p>Library scans of written material</p>
									<div id="carouselExampleControls3" class="carousel slide" data-keyboard="true">
										<div class="carousel-inner">
											<div class="carousel-item active"> <img class="d-block w-100" src="/images/library_screenshot.png" alt="First slide"> </div>
											<div class="carousel-item"> <img class="d-block w-100" src="/images/library_screenshot.png" alt="Second slide"> </div>
											<div class="carousel-item"> <img class="d-block w-100" src="/images/library_screenshot.png" alt="Third slide"> </div>
										</div>
										<a class="carousel-control-prev" href="##carouselExampleControls3" role="button" data-slide="prev"> <span class="carousel-control-prev-icon" aria-hidden="true"></span> <span class="sr-only">Previous</span> </a> <a class="carousel-control-next" href="##carouselExampleControls" role="button" data-slide="next"> <span class="carousel-control-next-icon" aria-hidden="true"></span> <span class="sr-only">Next</span> </a> 
									</div>
								</div>
								<div class="col-12 col-md-4 px-0 border"> 
									<h3>Collectors and other agents</h3>
									<p>James Henry Blake, Louis Agassiz, Franz Steindachner, LF dePourtales</p>
									<div id="carouselExampleControls2" class="carousel slide" data-keyboard="true">
										<div class="carousel-inner">
											<div class="carousel-item active"> <img class="d-block w-100" src="/images/student_images.png" alt="First slide"> </div>
											<div class="carousel-item"> <img class="d-block w-100" src="/images/student_images.png" alt="Second slide"> </div>
											<div class="carousel-item"> <img class="d-block w-100" src="/images/library_screenshot.png" alt="Third slide"> </div>
										</div>
										<a class="carousel-control-prev" href="##carouselExampleControls2" role="button" data-slide="prev"> <span class="carousel-control-prev-icon" aria-hidden="true"></span> <span class="sr-only">Previous</span> </a> <a class="carousel-control-next" href="##carouselExampleControls" role="button" data-slide="next"> <span class="carousel-control-next-icon" aria-hidden="true"></span> <span class="sr-only">Next</span> </a> 
									</div>
								</div>
							</div>
						</div>
						<div class="col-12 col-md-6 px-5 mt-4 float-left">
								<h3>Featured Specimen Images</h3>
						<p>Specimen Images linked to the Hassler Expedition</p>
							<div id="carouselExampleControls1" class="carousel slide" data-keyboard="true">
								<div class="carousel-inner">
									<div class="carousel-item active"> <img class="d-block w-100" src="/images/carousel_example.png" alt="First slide"> </div>
									<div class="carousel-item"> <img class="d-block w-100" src="/images/specimens_from_MA.png" alt="Second slide"> </div>
									<div class="carousel-item"> <img class="d-block w-100" src="/images/carousel_example.png" alt="Third slide"> </div>
								</div>
								<a class="carousel-control-prev" href="##carouselExampleControls1" role="button" data-slide="prev"> <span class="carousel-control-prev-icon" aria-hidden="true"></span> <span class="sr-only">Previous</span> </a> <a class="carousel-control-next" href="##carouselExampleControls" role="button" data-slide="next"> <span class="carousel-control-next-icon" aria-hidden="true"></span> <span class="sr-only">Next</span> </a> </div>
					
						</div>
					</div>
				</div>
			</article>
		</div>
	</main>
	<!--- class="container" ---> 
</cfoutput>
<cfinclude template = "/shared/_footer.cfm">
