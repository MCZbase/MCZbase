<cfset pageTitle = "Named Group">
<cfinclude template="/shared/_header.cfm">

<cfoutput>
	<style>
		a:focus {box-shadow: none;}
	</style>
	<cfset underscore_collection_id = "1">
	<cfset underscore_agent_id = "117103">
	<cfset collection_object_id = "">
	<cfquery name="getNamedGroup" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select underscore_collection.collection_name, underscore_collection.description, underscore_collection.underscore_agent_id, underscore_relation.collection_object_id, underscore_collection.html_description, underscore_collection.mask_fg 
		from underscore_collection, underscore_relation where underscore_relation.underscore_collection_id = underscore_collection.underscore_collection_id and underscore_collection.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
	</cfquery>
	<main class="container-fluid py-3">
		<div class="row mx-0">
			<article class="w-100">
				<div class="col-12">
					<div class="row mx-0">
						<div class="col-12 px-0 px-md-4 border-dark mt-4">
							<h1 class="pb-2" style="border-bottom: 8px solid ##000">#getNamedGroup.collection_name#</h1>
						</div>
					</div>
					<div class="row mx-0">
						<div class="col-12 col-md-7 col-lg-7 col-xl-7 px-0 px-md-4 float-left mt-0">
							<h2>Description</h2>
							<p class="">#getNamedGroup.description#</p>
							<h2>Featured Data</h2>
							<p>#getNamedGroup.html_description#</p>
							<h2 class="mt-5 pt-3" style="border-top: 8px solid ##000">Specimen Images</h2>
							<p>Specimen Images not linked to the #getNamedGroup.collection_name# (dev placeholders)</p>
							<!--Carousel Wrapper-->
							<div id="carousel-example-2" class="carousel slide carousel-fade" data-interval="false" data-ride="carousel" data-pause="hover" > 
								<!--Indicators-->
								<ol class="carousel-indicators">
									<li data-target="##carousel-example-2" data-slide-to="0" class="active"></li>
									<li data-target="##carousel-example-2" data-slide-to="1"></li>
									<li data-target="##carousel-example-2" data-slide-to="2"></li>
								</ol>
								<!--/.Indicators---> 
								<!--Slides-->
								<div class="carousel-inner" role="listbox">
									<div class="carousel-item active">
										<div class="view"> <img class="d-block w-100" src="/shared/images/1024px-Berlin_Naturkundemuseum_Muscheln.jpg" alt="First slide"/>
											   <div class="mask rgba-black-strong"></div>
										</div>
										<div class="carousel-caption">
											<h3 class="h3-responsive">Diversity and variability of shells of molluscs on display</h3>
											<p>Photo from Museum für Naturkunde Berlin</p>
										</div>
									</div>
									<div class="carousel-item">
										<div class="view"> <img class="d-block w-100" src="/shared/images/800px-Fossilized_Ammonite_Mollusk_displayed_at_Philippine_National_Museum.jpg" alt="Second slide"/>
											   <div class="mask rgba-black-strong"></div>
										</div>
										<div class="carousel-caption">
											<h3 class="h3-responsive">Fossilized ammonite displayed</h3>
											<p>National Museum of the Philippines</p>
										</div>
									</div>
									<div class="carousel-item">
										<div class="view"> <img class="d-block w-100" src="/shared/images/800px-Snail-wiki-120-Zachi-Evenor.jpg" alt="Second slide"/>
											   <div class="mask rgba-black-strong"></div>
										</div>
										<div class="carousel-caption">
											<h3 class="h3-responsive">Cornu aspersum (formerly Helix aspersa) – a common land snail</h3>
											<p>Photo by Zachi Evenor</p>
										</div>
									</div>
								</div>
								<!--/.Slides--> 
								<!--Controls--> 
								<a class="carousel-control-prev" href="##carousel-example-2" role="button" data-slide="prev" style="top:-5%;"> <span class="carousel-control-prev-icon" aria-hidden="true"></span> <span class="sr-only">Previous</span> </a> <a class="carousel-control-next" href="##carousel-example-2" role="button" data-slide="next" style="top:-5%;"> <span class="carousel-control-next-icon" aria-hidden="true"></span> <span class="sr-only">Next</span> </a> 
								<!--/.Controls--> 
							</div>
							<!--/.Carousel Wrapper-->
							<h2 class="mt-5 pt-3" style="border-top: 8px solid ##000">Other Media</h2>
							<hr>
							<div class="row">
								<div class="col-12 col-md-4">
									<h3>Localities</h3>
									<p>Maps and location images</p>
									<div id="carouselExampleControls4"  class="carousel slide carousel-fade" data-interval="false" data-ride="carousel" data-pause="hover" >
										<div class="carousel-inner">
											<div class="carousel-item active"> <img class="d-block col-10 col-md-12 px-0 mx-auto" src="/shared/images/800px-Democratic_Republic_of_the_Congo_(orthographic_projection).svg.png" alt="First slide">
												   <div class="mask rgba-black-strong"></div>
												<div class="carousel-caption" style="position: relative;color: black;padding-top:20px;left:0;">
													<h3 class="h3-responsive">Location of Democratic Republic of the Congo (dark green)</h3>
													<p>Photo by Radio Okapi</p>
												</div>
											</div>
											<div class="carousel-item"> <img class="d-block col-10 col-md-12 px-0 mx-auto" src="/shared/images/La_rivière_Lulilaka,_parc_national_de_Salonga,_2005.jpg" alt="second slide">
												   <div class="mask rgba-black-strong"></div>
												<div class="carousel-caption" style="position: relative;color: black;padding-top:20px;left:0;">
													<h3 class="h3-responsive">Salonga National Park</h3>
													<p>Photo by Radio Okapi</p>
												</div>
											</div>
											<div class="carousel-item"> <img class="d-block col-10 col-md-12 px-0 mx-auto" src="/shared/images/800px-Okapi2.jpg" alt="third slide">   <div class="mask rgba-black-strong"></div>
												<div class="carousel-caption" style="position: relative;color: black;padding-top:20px;left:0;">
													<h3 class="h3-responsive">An Okapi</h3>
													<p>Photo by Raul654</p>
												</div>
											</div>
											
										</div>
										<a class="carousel-control-prev box-shadow-0" href="##carouselExampleControls4" role="button" data-slide="prev" style="top: -46%;"> <span class="carousel-control-prev-icon" aria-hidden="true"></span> <span class="sr-only">Previous</span> </a> <a class="carousel-control-next box-shadow-0" href="##carouselExampleControls4" role="button" data-slide="next" style="top:-46%;"> <span class="carousel-control-next-icon" aria-hidden="true"></span> <span class="sr-only">Next</span> </a> </div>
								</div>
								<div class="col-12 col-md-4">
									<h3>Journals, Notes, Ledgers</h3>
									<p>Library scans of written material</p>
									<div id="carouselExampleControls3" class="carousel slide carousel-fade" data-interval="false" data-ride="carousel" data-pause="hover" >
										<div class="carousel-inner">
											<div class="carousel-item active"> <img class="d-block w-100" src="/images/ledger.PNG" alt="First slide"><div class="carousel-caption" style="position: relative;color: black;padding-top:20px;left:0;">
													<h3 class="h3-responsive">Ledger Scan</h3>
													<p>MCZ/Ernst Mayr Library</p>
												</div> </div>
											<div class="carousel-item"> <img class="d-block w-100" src="/images/Hassler_expedition_route.png" alt="Second slide"><div class="carousel-caption" style="position: relative;color: black;padding-top:20px;left:0;">
													<h3 class="h3-responsive">Annotation of Map/ Collecting route</h3>
													<p>MCZ note example</p>
												</div> </div>
											<div class="carousel-item"> <img class="d-block w-100" src="/images/IP_semliki_notes.PNG" alt="Third slide"><div class="carousel-caption" style="position: relative;color: black;padding-top:20px;left:0;">
													<h3 class="h3-responsive">Semliki Notes</h3>
													<p>MCZ IP dept.</p>
												</div> </div>
										</div>
										<a class="carousel-control-prev" href="##carouselExampleControls3" role="button" data-slide="prev" style="top:-46%;"> <span class="carousel-control-prev-icon" aria-hidden="true"></span> <span class="sr-only">Previous</span> </a> <a class="carousel-control-next" href="##carouselExampleControls3" role="button" data-slide="next" style="top:-46%;"> <span class="carousel-control-next-icon" aria-hidden="true"></span> <span class="sr-only">Next</span> </a> </div>
								</div>
								<div class="col-12 col-md-4 ">
									<h3>Collectors and other agents</h3>
									<p>Collector, vessel, institution, and related group images. </p>
									<div id="carouselExampleControls2"  class="carousel slide carousel-fade" data-interval="false" data-ride="carousel" data-pause="hover" >
										<div class="carousel-inner">
											<div class="carousel-item active"> 
												<img class="d-block w-100" src="/images/student_images.png" alt="">
											<div class="carousel-caption" style="position: relative;color: black;padding-top:20px;left:0;">
											<h3 class="h3-responsive">Collector Images</h3>
											<p>MCZ historical images (placeholder)</p>
											</div>
										</div> 
									</div>
										
								</div>
										<a class="carousel-control-prev" href="##carouselExampleControls2" role="button" data-slide="prev" style="top:-5%;"> <span class="carousel-control-prev-icon" aria-hidden="true"></span> <span class="sr-only">Previous</span> </a> <a class="carousel-control-next" href="##carouselExampleControls2" role="button" data-slide="next" style="top:-5%;"> <span class="carousel-control-next-icon" aria-hidden="true"></span> <span class="sr-only">Next</span> </a> </div>
								</div>
							</div>
					
						<div class="col-12 col-md-12 col-lg-4 col-xl-5  px-0 mt-1 px-md-4 float-left">
							<div class="row">
								<div class="col-12">
									<h3>Taxa</h3>
									<cfquery name="taxa_class"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
									select distinct flat.phylclass as phylclass from flat, underscore_collection, underscore_relation 
									where underscore_relation.collection_object_id = flat.collection_object_id
									and underscore_collection.underscore_collection_id = underscore_relation.underscore_collection_id
									and underscore_collection.underscore_collection_id = 1
									and flat.PHYLCLASS is not null
									order by flat.phylclass asc
									</cfquery>
									<ul class="list-group py-3 border-top border-bottom rounded-0 border-dark">
										<cfloop query="taxa_class">
											<li class="list-group-item float-left"><a class="h4" href="##">#taxa_class.phylclass#</a></li>
										</cfloop>
									</ul>
								</div>
								<div class="col-12">
									<h3>Countries</h3>
									<cfquery name="country"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
									select distinct flat.country as country from flat, underscore_collection, underscore_relation 
									where underscore_relation.collection_object_id = flat.collection_object_id
									and underscore_collection.underscore_collection_id = underscore_relation.underscore_collection_id
									and underscore_collection.underscore_collection_id = 1
									and flat.country is not null
									order by flat.country asc
									</cfquery>
									<ul class="list-group py-3 border-top border-bottom rounded-0 border-dark">
										<cfloop query="country">
											<li class="list-group-item float-left"><a class="h4" href="##">#country.country#</a></li>
										</cfloop>
									</ul>
								</div>
								<div class="col-12">
									<cfquery name="agents"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
									select distinct flat.collectors as collectors from flat, underscore_collection, underscore_relation 
									where underscore_relation.collection_object_id = flat.collection_object_id
									and underscore_collection.underscore_collection_id = underscore_relation.underscore_collection_id
									and underscore_collection.underscore_collection_id = 1
									and flat.collectors is not null
									order by flat.collectors asc
									</cfquery>
									<h3>Agents</h3>
									<ul class="list-group d-inline-block py-3 border-top border-bottom rounded-0 border-dark w-100">
										<cfloop query="agents">
											<li class="list-group-item float-left d-inline mr-2" style="width:105px"><a class="h4" href="##">#agents.collectors#</a></li>
										</cfloop>
									</ul>
								</div>
								<div class="col-12">
									<cfquery name="specimens"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
									select distinct flat.GUID as guid, flat.specimendetailurl as specimendetailurl 
									from flat, underscore_collection, underscore_relation 
									where underscore_relation.collection_object_id = flat.collection_object_id
									and underscore_collection.underscore_collection_id = underscore_relation.underscore_collection_id
									and underscore_collection.underscore_collection_id = 1
									and flat.GUID is not null
									order by flat.GUID,flat.specimendetailurl asc
									</cfquery>
									<h3>Specimen Records</h3>
									<ul class="list-group d-inline-block py-3 border-top border-bottom rounded-0 border-dark">
										<cfloop query="specimens">
											<li class="list-group-item float-left d-inline mr-2" style="width:105px">#specimens.specimendetailurl#</a></li>
										</cfloop>
									</ul>
								</div>
							</div>
						</div>
					</div>
				</div>
			</article>
		</div>
	</main>
</cfoutput> 
<!--- class="container" --->

<cfinclude template = "/shared/_footer.cfm">
