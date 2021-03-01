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
	<main class="container-fluid py-3">
		<div class="row mx-0">
			<article class="w-100">
				<div class="col-12">
					<div class="row mx-0">
						<div class="col-12 px-4 border-dark mt-4">
							<h1 class="pb-2" style="border-bottom: 8px solid ##000">#getNamedGroup.collection_name#</h1>
						</div>
					</div>
					<div class="row mx-0">
						<div class="col-12 col-md-2 px-4 float-left mt-2">
							<p class="">#getNamedGroup.description#</p>
							<p>#getNamedGroup.html_description#</p>
						</div>
						<div class="col-12 col-md-5 px-2 float-left mt-0">
							<h2 class="h1 pb-2 mb-0">Featured Specimen Images</h2>
							<p>Specimen Images linked to the #getNamedGroup.collection_name#</p>

									<cfquery name="specimensimages"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
									select distinct flat.imageurlfiltered as imageurlfiltered, flat.collection_object_id as collection_object_id
									from flat, underscore_collection, underscore_relation
									where underscore_relation.collection_object_id = flat.collection_object_id 
									and underscore_collection.underscore_collection_id = underscore_relation.underscore_collection_id 
									and underscore_collection.underscore_collection_id = 1
									</cfquery>
									<cfquery name="getSpecMedia" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
									select 
										distinct media_id
									from 
										underscore_relation
									left outer join 
										media_relations on underscore_relation.collection_object_id = media_relations.related_primary_key 
									where 
										media_relations.media_relationship like 'shows cataloged_item' and underscore_relation.underscore_collection_id = 1
									and underscore_relations.collection_object_id = #specimenimages.collection_object_id#
									</cfquery>
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
								<cfloop query="getSpecMedia">
								<div class="carousel-inner" role="listbox">
									<div class="carousel-item active">
										<div class="view"> <img class="d-block w-100" src="#specimensimages.images#" alt="First slide"/>
											<div class="mask rgba-black-light"></div>
										</div>
										<div class="carousel-caption">
											<h3 class="h3-responsive">scientific name</h3>
												<p>location</p>
										</div>
								
									</div>
								</cfloop>
								</div>
								<!--/.Slides--> 
								<!--Controls--> 
								<a class="carousel-control-prev" href="##carousel-example-2" role="button" data-slide="prev"> <span class="carousel-control-prev-icon" aria-hidden="true"></span> <span class="sr-only">Previous</span> </a> <a class="carousel-control-next" href="##carousel-example-2" role="button" data-slide="next"> <span class="carousel-control-next-icon" aria-hidden="true"></span> <span class="sr-only">Next</span> </a> 
								<!--/.Controls--> 
							</div>
							<!--/.Carousel Wrapper-->
							<h2 class="h1 mt-5 pt-3" style="border-top: 8px solid ##000">Featured Record Data</h2>
							<hr>
							<div class="row">
								<div class="col-12 col-md-4">
									<h3>Localities</h3>
									<p>Maps and location images</p>
									<div id="carouselExampleControls4"  class="carousel slide carousel-fade" data-interval="false" data-ride="carousel" data-pause="hover" >
										<div class="carousel-inner">
											<div class="carousel-item active"> <img class="d-block w-100" src="https://mczbase.mcz.harvard.edu/specimen_images/invertebrates/large/Mount_Greylock_top.jpg" alt="First slide"> </div>
											<div class="carousel-item"> <img class="d-block w-100" src="https://mczbase.mcz.harvard.edu/specimen_images/malacology/agents/large/bfg_007.jpg" alt="First slide"> </div>
											<div class="carousel-item"> <img class="d-block w-100" src="https://mczbase.mcz.harvard.edu/specimen_images/malacology/agents/large/beatty_001.jpg" alt="First slide"> </div>
										</div>
										<a class="carousel-control-prev" href="##carouselExampleControls4" role="button" data-slide="prev"> <span class="carousel-control-prev-icon" aria-hidden="true"></span> <span class="sr-only">Previous</span> </a> <a class="carousel-control-next" href="##carouselExampleControls4" role="button" data-slide="next"> <span class="carousel-control-next-icon" aria-hidden="true"></span> <span class="sr-only">Next</span> </a> </div>
								</div>
								<div class="col-12 col-md-4">
									<h3>Journals, Notes, Ledgers</h3>
									<p>Library scans of written material</p>
									<div id="carouselExampleControls3" class="carousel slide carousel-fade" data-interval="false" data-ride="carousel" data-pause="hover" >
										<div class="carousel-inner">
											<div class="carousel-item active"> <img class="d-block w-100" src="https://mczbase-dev.rc.fas.harvard.edu/specimen_images/invertpaleo/agents/large/Samuel_Henshaw_2_Large.jpg" alt="First slide"> </div>
											<div class="carousel-item"> <img class="d-block w-100" src="https://mczbase.mcz.harvard.edu/specimen_images/malacology/agents/large/bfg_007.jpg" alt="Second slide"> </div>
											<div class="carousel-item"> <img class="d-block w-100" src="https://mczbase.mcz.harvard.edu/specimen_images/malacology/agents/large/bfg_007.jpg" alt="Third slide"> </div>
										</div>
										<a class="carousel-control-prev" href="##carouselExampleControls3" role="button" data-slide="prev"> <span class="carousel-control-prev-icon" aria-hidden="true"></span> <span class="sr-only">Previous</span> </a> <a class="carousel-control-next" href="##carouselExampleControls3" role="button" data-slide="next"> <span class="carousel-control-next-icon" aria-hidden="true"></span> <span class="sr-only">Next</span> </a> </div>
								</div>
								<div class="col-12 col-md-4 ">
									<h3>Collectors and other agents</h3>
									<p>James Henry Blake, Louis Agassiz, Franz Steindachner, LF dePourtales</p>
									<div id="carouselExampleControls2"  class="carousel slide carousel-fade" data-interval="false" data-ride="carousel" data-pause="hover" >
										<div class="carousel-inner">
											<div class="carousel-item active"> <img class="d-block w-100" src="https://mczbase.mcz.harvard.edu/specimen_images/test/Louis_Agassiz256px.jpg" alt=""> </div>
											<div class="carousel-item"> <img class="d-block w-100" src="https://mczbase.mcz.harvard.edu/specimen_images/test/Louis_Agassiz256px.jpg" alt=""> </div>
											<div class="carousel-item"> <img class="d-block w-100" src="https://mczbase.mcz.harvard.edu/specimen_images/test/Louis_Agassiz256px.jpg" alt=""> </div>
										</div>
										<a class="carousel-control-prev" href="##carouselExampleControls2" role="button" data-slide="prev"> <span class="carousel-control-prev-icon" aria-hidden="true"></span> <span class="sr-only">Previous</span> </a> <a class="carousel-control-next" href="##carouselExampleControls2" role="button" data-slide="next"> <span class="carousel-control-next-icon" aria-hidden="true"></span> <span class="sr-only">Next</span> </a> </div>
								</div>
							</div>
						</div>
						<div class="col-12 col-md-5 mt-1 float-left">
							<div class="row mx-0">
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
											<li class="list-group-item float-left" style=""><a class="h4" href="##">#taxa_class.phylclass#</a></li>
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
											<li class="list-group-item float-left" style=""><a class="h4" href="##">#country.country#</a></li>
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
									select distinct flat.GUID as guid, flat.specimendetailurl as GUIDLINK from flat, underscore_collection, underscore_relation 
									where underscore_relation.collection_object_id = flat.collection_object_id
									and underscore_collection.underscore_collection_id = underscore_relation.underscore_collection_id
									and underscore_collection.underscore_collection_id = 1
									and flat.GUID is not null
									order by flat.GUID asc
									</cfquery>
				
									<h3>Specimen Records</h3>
									<ul class="list-group d-inline-block py-3 border-top border-bottom rounded-0 border-dark">
										<cfloop query="specimens">
											<li class="list-group-item float-left d-inline mr-2" style="width:105px"><a class="h4" href="#specimens.guidlink#">#specimens.guid#</a></li>
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
