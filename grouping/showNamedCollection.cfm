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
			<div class="col-12 col-md-9 px-2 float-left mt-4">
			<h1>#getNamedGroup.collection_name#</h1>
			<hr>
			<p>#getNamedGroup.description#</p>
			<p>#getNamedGroup.html_description#</p>
			<hr>
			<h2 class="h1 mt-5 pt-3" style="border-top: 8px solid ##000">Featured Information</h2>
			<hr>
		<div class="row">
				<div class="col-12 col-md-3">
					<h3>Localities</h3>
					<p>Maps and location images</p>
					<div id="carouselExampleControls4" class="carousel slide" data-keyboard="true"  data-ride="false">
						<div class="carousel-inner">
							<div class="carousel-item active"> <img class="d-block w-100" src="https://mczbase.mcz.harvard.edu/specimen_images/invertebrates/large/Mount_Greylock_top.jpg" alt="First slide"> </div>
							<div class="carousel-item"> <img class="d-block w-100" src="https://mczbase.mcz.harvard.edu/specimen_images/malacology/agents/large/bfg_007.jpg" alt="First slide"> </div>
							<div class="carousel-item"> <img class="d-block w-100" src="https://mczbase.mcz.harvard.edu/specimen_images/malacology/agents/large/beatty_001.jpg" alt="First slide"> </div>
						</div>
						<a class="carousel-control-prev" href="##carouselExampleControls4" role="button" data-slide="prev"> <span class="carousel-control-prev-icon" aria-hidden="true"></span> <span class="sr-only">Previous</span> </a> <a class="carousel-control-next" href="##carouselExampleControls4" role="button" data-slide="next"> <span class="carousel-control-next-icon" aria-hidden="true"></span> <span class="sr-only">Next</span> </a> </div>
				</div>
				<div class="col-12 col-md-3">
					<h3>Journals, Notes, Ledgers</h3>
					<p>Library scans of written material</p>
					<div id="carouselExampleControls3" class="carousel slide" data-keyboard="true"  data-ride="false">
						<div class="carousel-inner">
							<div class="carousel-item active"> <img class="d-block w-100" src="https://mczbase-dev.rc.fas.harvard.edu/specimen_images/invertpaleo/agents/large/Samuel_Henshaw_2_Large.jpg" alt="First slide"> </div>
							<div class="carousel-item"> <img class="d-block w-100" src="https://mczbase.mcz.harvard.edu/specimen_images/malacology/agents/large/bfg_007.jpg" alt="Second slide"> </div>
							<div class="carousel-item"> <img class="d-block w-100" src="https://mczbase.mcz.harvard.edu/specimen_images/malacology/agents/large/bfg_007.jpg" alt="Third slide"> </div>
						</div>
						<a class="carousel-control-prev" href="##carouselExampleControls3" role="button" data-slide="prev"> <span class="carousel-control-prev-icon" aria-hidden="true"></span> <span class="sr-only">Previous</span> </a> <a class="carousel-control-next" href="##carouselExampleControls3" role="button" data-slide="next"> <span class="carousel-control-next-icon" aria-hidden="true"></span> <span class="sr-only">Next</span> </a> </div>
				</div>
				<div class="col-12 col-md-3 ">
					<h3>Collectors and other agents</h3>
					<p>James Henry Blake, Louis Agassiz, Franz Steindachner, LF dePourtales</p>
					<div id="carouselExampleControls2" class="carousel slide" data-keyboard="true"  data-ride="false">
						<div class="carousel-inner">
							<div class="carousel-item active"> <img class="d-block w-100" src="https://mczbase.mcz.harvard.edu/specimen_images/test/Louis_Agassiz256px.jpg" alt=""> </div>
							<div class="carousel-item"> <img class="d-block w-100" src="https://mczbase.mcz.harvard.edu/specimen_images/test/Louis_Agassiz256px.jpg" alt=""> </div>
							<div class="carousel-item"> <img class="d-block w-100" src="https://mczbase.mcz.harvard.edu/specimen_images/test/Louis_Agassiz256px.jpg" alt=""> </div>
						</div>
						<a class="carousel-control-prev" href="##carouselExampleControls2" role="button" data-slide="prev"> <span class="carousel-control-prev-icon" aria-hidden="true"></span> <span class="sr-only">Previous</span> </a> <a class="carousel-control-next" href="##carouselExampleControls2" role="button" data-slide="next"> <span class="carousel-control-next-icon" aria-hidden="true"></span> <span class="sr-only">Next</span> </a> </div>
				</div>		
				<div class="col-12 col-md-3 ">
				<h3>Featured Specimen Images</h3>
				<p>Specimen Images linked to the #getNamedGroup.collection_name#</p>
				<!--Carousel Wrapper-->
				<div id="carousel-example-2" class="carousel slide carousel-fade" data-ride="carousel"> 
					<!--Indicators-->
					<ol class="carousel-indicators">
						<li data-target="##carousel-example-2" data-slide-to="0" class="active"></li>
						<li data-target="##carousel-example-2" data-slide-to="1"></li>
						<li data-target="##carousel-example-2" data-slide-to="2"></li>
					</ol>
					<!--/.Indicators--> 
					<!--Slides-->
					<div class="carousel-inner" role="listbox">
						<div class="carousel-item active">
							<div class="view"> <img class="d-block w-100" src="https://mczbase-dev.rc.fas.harvard.edu/specimen_images/herpetology/large/A17734_P_snethlageae_P_v.jpg"
			  alt="First slide">
								<div class="mask rgba-black-light"></div>
							</div>
							<div class="carousel-caption">
								<h3 class="h3-responsive">Light mask</h3>
								<p>First text</p>
							</div>
						</div>
						<div class="carousel-item"> 
							<!--Mask color-->
							<div class="view"> <img class="d-block w-100" src="https://mczbase-dev.rc.fas.harvard.edu/specimen_images/herpetology/large/A17734_P_snethlageae_P_v.jpg"
			  alt="Second slide">
								<div class="mask rgba-black-strong"></div>
							</div>
							<div class="carousel-caption">
								<h3 class="h3-responsive">MCZ Herpetology A-15810 - Ooeidozyga floresiana</h3>
								<p>Indonesia, Rana Mese: Flores: Dutch East Indies</p>
							</div>
						</div>
						<div class="carousel-item"> 
							<!--Mask color-->
							<div class="view"> <img class="d-block w-100" src="https://mczbase.mcz.harvard.edu/specimen_images/ent-lepidoptera/images/2011_10_17/IMG_104291.JPG"
			  alt="Third slide">
								<div class="mask rgba-black-slight"></div>
							</div>
							<div class="carousel-caption">
								<h3 class="h3-responsive">Slight mask</h3>
								<p>Third text</p>
							</div>
						</div>
					</div>
					<!--/.Slides--> 
					<!--Controls--> 
					<a class="carousel-control-prev" href="##carousel-example-2" role="button" data-slide="prev"> <span class="carousel-control-prev-icon" aria-hidden="true"></span> <span class="sr-only">Previous</span> </a> <a class="carousel-control-next" href="##carousel-example-2" role="button" data-slide="next"> <span class="carousel-control-next-icon" aria-hidden="true"></span> <span class="sr-only">Next</span> </a> 
					<!--/.Controls--> 
				</div>
				<!--/.Carousel Wrapper--> 
				</div>
		</div>
		</div>
			<div class="col-12 col-md-3 mt-5 float-left">
			<div class="row mx-0">
				<div class="col-12">
					<h3>Taxa</h3>
					<ul class="list-group py-3 border-top border-bottom rounded-0 border-dark">
						<li class="list-group-item float-left" style=""><a class="h4" href="##">Aves</a></li>
						<li class="list-group-item float-left" style=""><a class="h4" href="##">Amphibia</a></li>
						<li class="list-group-item float-left" style=""><a class="h4" href="##">Reptilia</a></li>
						<li class="list-group-item float-left" style=""><a class="h4" href="##">Cephalopoda</a></li>
					</ul>
				</div>
				
				<div class="col-12">
					<h3>Countries</h3>
					<ul class="list-group py-3 border-top border-bottom rounded-0 border-dark">
						<li class="list-group-item float-left" style=""><a class="h4" href="##">Uganda</a></li>
						<li class="list-group-item float-left" style=""><a class="h4" href="##">Democratic Republic of the Congo</a></li>
					</ul>
				</div>
				<div class="col-12">
					<h3>Specimen Records</h3>
					<ul class="list-group d-inline-block py-3 border-top border-bottom rounded-0 border-dark" style="width:240px;">
						<li class="list-group-item float-left d-inline mr-2" style="width:105px"><a class="h4" href="##">MCZ:IP:100540</a></li>
						<li class="list-group-item float-left d-inline mr-2" style="width:105px"><a class="h4" href="##">MCZ:IP:100541</a></li>
						<li class="list-group-item float-left d-inline mr-2 " style="width:105px"><a class="h4" href="##">MCZ:IP:100542</a></li>
						<li class="list-group-item float-left d-inline mr-2 " style="width:105px"><a class="h4" href="##">MCZ:IP:100543</a></li>
						<li class="list-group-item float-left d-inline mr-2" style="width:105px"><a class="h4" href="##">MCZ:IP:100544</a></li>
						<li class="list-group-item float-left d-inline mr-2" style="width:105px"><a class="h4" href="##">MCZ:IP:100545</a></li>
						<li class="list-group-item float-left d-inline mr-2" style="width:105px"><a class="h4" href="##">MCZ:IP:100546</a></li>
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
