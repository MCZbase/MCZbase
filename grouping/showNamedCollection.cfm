<cfset pageTitle = "Named Group">
<cfinclude template="/shared/_header.cfm">
	<cfoutput>
	<cfset underscore_collection_id = "1">
	<cfset underscore_agent_id = "117103">
		<cfset collection_object_id = "">	
	<cfquery name="getNamedGroup" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select underscore_collection.collection_name, underscore_collection.description, underscore_collection.underscore_agent_id, underscore_relation.collection_object_id, underscore_collection.html_description, underscore_collection.mask_fg 
		from underscore_collection, underscore_relation where underscore_relation.underscore_collection_id = underscore_collection.underscore_collection_id and underscore_collection.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
	</cfquery>

	<main class="container py-3">
		<div class="row">
			<article class="w-100">
		
				<div class="col-12">
				
					<div class="row">
						<div class="col-12 col-md-6 px-0 float-left mt-4">
							<h1>#getNamedGroup.collection_name#</h1>
							<hr>
							<p>#getNamedGroup.description#</p>
							<p>#getNamedGroup.html_description#</p>
							<hr>
							<h2 class="h1 mt-5 pt-3" style="border-top: 8px solid ##000">Featured Information</h2>
							<hr>
							<div class="row">
								<div class="col-12 col-md-4">
						
		
						

									<h3>Localities</h3>
									<p>Maps and location images</p>
									<div id="carouselExampleControls4" class="carousel slide" data-keyboard="true">
										<div class="carousel-inner">
											<div class="carousel-item active"> <img class="d-block w-100" src="https://mczbase-dev.rc.fas.harvard.edu/specimen_images/ent-lepidoptera/images/2011_10_17/IMG_104291.JPG" alt="First slide"> </div>
											<div class="carousel-item"> <img class="d-block w-100" src="https://mczbase-dev.rc.fas.harvard.edu/media/94165" alt="First slide"> </div>
											<div class="carousel-item"> <img class="d-block w-100" src="https://mczbase-dev.rc.fas.harvard.edu/media/94187" alt="First slide"> </div>
										</div>
										<a class="carousel-control-prev" href="##carouselExampleControls4" role="button" data-slide="prev"> <span class="carousel-control-prev-icon" aria-hidden="true"></span> <span class="sr-only">Previous</span> </a> <a class="carousel-control-next" href="##carouselExampleControls" role="button" data-slide="next"> <span class="carousel-control-next-icon" aria-hidden="true"></span> <span class="sr-only">Next</span> </a> 
									</div>
								</div>
								<div class="col-12 col-md-4 px-3">
									<h3>Journals, Notes, Ledgers</h3>
									<p>Library scans of written material</p>
									<div id="carouselExampleControls3" class="carousel slide" data-keyboard="true">
										<div class="carousel-inner">
										
											<div class="carousel-item active"> <img class="d-block w-100" src="https://mczbase-dev.rc.fas.harvard.edu/specimen_images/herpetology/large/A10442_B_uluguruensis_H_label.jpg" alt="First slide"> </div>
											<div class="carousel-item"> <img class="d-block w-100" src="https://mczbase-dev.rc.fas.harvard.edu/specimen_images/herpetology/large/A11968_P_alleni_P_v.jpg" alt="Second slide"> </div>
											<div class="carousel-item"> <img class="d-block w-100" src="https://mczbase-dev.rc.fas.harvard.edu/specimen_images/herpetology/large/R9631_S_guttatus_H_hv.jpg" alt="Third slide"> </div>	
																				</div>
										<a class="carousel-control-prev" href="##carouselExampleControls3" role="button" data-slide="prev"> <span class="carousel-control-prev-icon" aria-hidden="true"></span> <span class="sr-only">Previous</span> </a> <a class="carousel-control-next" href="##carouselExampleControls" role="button" data-slide="next"> <span class="carousel-control-next-icon" aria-hidden="true"></span> <span class="sr-only">Next</span> </a> 
									</div>
								</div>
								<div class="col-12 col-md-4 "> 
									<h3>Collectors and other agents</h3>
									<p>James Henry Blake, Louis Agassiz, Franz Steindachner, LF dePourtales</p>
									<div id="carouselExampleControls2" class="carousel slide" data-keyboard="true">
										<div class="carousel-inner">
									
										<div class="carousel-item"> <img class="d-block w-100" src="https://mczbase-dev.rc.fas.harvard.edu/specimen_images/ent-lepidoptera/images/2012_11_03/IMG_134172.JPG" alt=""> </div>
										<div class="carousel-item"> <img class="d-block w-100" src="https://mczbase-dev.rc.fas.harvard.edu/specimen_images/ent-lepidoptera/images/2012_11_08/IMG_134637.JPG" alt=""> </div>
										<div class="carousel-item"> <img class="d-block w-100" src="https://mczbase-dev.rc.fas.harvard.edu/specimen_images/ent-lepidoptera/images/2012_11_03/IMG_134169.JPG" alt=""> </div>
									
										</div>
										<a class="carousel-control-prev" href="##carouselExampleControls2" role="button" data-slide="prev"> <span class="carousel-control-prev-icon" aria-hidden="true"></span> <span class="sr-only">Previous</span> </a> <a class="carousel-control-next" href="##carouselExampleControls" role="button" data-slide="next"> <span class="carousel-control-next-icon" aria-hidden="true"></span> <span class="sr-only">Next</span> </a> 
									</div>
								</div>
							</div>
						</div>
						<div class="col-12 col-md-6 px-5 mt-4 float-left">
									<div class="col-12">	
									<ul class="list-group py-2 border-top border-bottom border-light">
										<li class="list-group-item float-left" style="width:100px"><a href="##">Aves</a></li>
										<li class="list-group-item float-left" style="width:100px"><a href="##">Amphibia</a></li>
										<li class="list-group-item float-left" style="width:100px"><a href="##">Reptilia</a></li>
										<li class="list-group-item float-left" style="width:100px"><a href="##">Cephalopoda</a></li>
					</ul></div>
						<cfquery name="spec_media" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							select distinct media_id
							from underscore_relation
							left outer join media_relations on underscore_relation.collection_object_id = media_relations.related_primary_key
							where
							media_relationship like 'shows cataloged_item' and underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
						</cfquery>
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
