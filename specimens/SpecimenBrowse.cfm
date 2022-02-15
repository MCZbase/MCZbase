<cfset pageTitle = "Browse Specimen Data">
<!--
specimens/SpecimenBrowse.cfm

Copyright 2020-2022 President and Fellows of Harvard College

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

-->
<cfif not isdefined("action")>
	<cfset action="featured">
</cfif>
<cfswitch expression="#action#">
	<cfcase value="browseprimarytypes">
		<cfset pageTitle = "Browse Primary Types">
	</cfcase>
	<cfcase value="browsefeatured">
		<cfset pageTitle = "Browse Featured Collections">
	</cfcase>
	<cfcase value="browsehighergeo">
		<cfset pageTitle = "Browse Higher Geography">
	</cfcase>
	<cfcase value="browseislands">
		<cfset pageTitle = "Browse Islands">
	</cfcase>
	<cfcase value="browsetaxonomy">
		<cfset pageTitle = "Browse Taxonomy">
	</cfcase>
	<cfdefaultcase>
		<cfset pageTitle = "Browse Featured Collection">
	</cfdefaultcase>
</cfswitch>
<cfinclude template = "/shared/_header.cfm">
<cfinclude template="/grouping/component/search.cfc" runOnce="true">
<cfinclude template="/media/component/search.cfc" runOnce="true">
<script src="/shared/js/tabs.js"></script>

<cfquery name="phyla" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#CreateTimespan(24,0,0,0)#" >
	select count(*) ct, phylum 
	from 
		<cfif ucase(session.flatTableName) EQ "FLAT"> flat <cfelse> filtered_flat </cfif>
	where phylum is not null
	group by phylum
	order by phylum
</cfquery>
<cfquery name="notphyla" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#CreateTimespan(24,0,0,0)#" >
	select count(*) ct, kingdom, phylorder 
	from 
		<cfif ucase(session.flatTableName) EQ "FLAT"> flat <cfelse> filtered_flat </cfif>
	where phylum is null and (kingdom is not null or phylorder is not null)
	group by kingdom, phylorder
	order by phylorder
</cfquery>
<cfquery name="notkingdoms" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#CreateTimespan(24,0,0,0)#" >
	select count(*) ct, scientific_name
	from 
		<cfif ucase(session.flatTableName) EQ "FLAT"> flat <cfelse> filtered_flat </cfif>
	where kingdom is null and phylum is null and phylorder is null
	group by scientific_name
	order by scientific_name
</cfquery> 

<!--- temporary code for testing production/redesign links on redesign branch --->
<cfif not isDefined("links_for")>
	<cfset links_for = "redesign">
</cfif>
<!--- end temporary code, but also remove links_for clause in next line.--->
<cfif links_for EQ "redesign" AND findNoCase('redesign',Session.gitBranch) GT 0>
	<cfset specimenSearch="/Specimens.cfm?execute=true&action=fixedSearch">
<cfelse>
	<cfset specimenSearch="/SpecimenResults.cfm?ShowObservations=true">
</cfif>

<cfquery name="namedGroups" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#CreateTimespan(24,0,0,0)#">
	SELECT
		count(flat.collection_object_id) ct, 
		underscore_collection.collection_name, 
		underscore_collection.underscore_collection_id, underscore_collection.mask_fg,
		underscore_collection.description, underscore_collection.underscore_collection_type,
		underscore_collection.displayed_media_id
	FROM
		underscore_collection 
		JOIN underscore_relation on underscore_collection.underscore_collection_id = underscore_relation.underscore_collection_id
		JOIN <cfif ucase(session.flatTableName) EQ "FLAT"> flat <cfelse> filtered_flat </cfif> flat
			on underscore_relation.collection_object_id = flat.collection_object_id
	WHERE
		underscore_collection.underscore_collection_id IS NOT NULL
		<cfif NOT isdefined("session.roles") OR listfindnocase(session.roles,"coldfusion_user") EQ 0>
			AND underscore_collection.mask_fg = 0
		</cfif>
		<cfif NOT isdefined("session.roles") AND listfindnocase(session.roles,"manage_specimens") EQ 0>
			AND underscore_collection.underscore_collection_type <> 'workflow'
		</cfif>
	GROUP BY
		underscore_collection.collection_name, 
		underscore_collection.underscore_collection_id, underscore_collection.mask_fg,
		underscore_collection.description, underscore_collection.underscore_collection_type,
		underscore_collection.displayed_media_id
	ORDER BY underscore_collection_type, lower(collection_name)
</cfquery>

<cfquery name="continents" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#CreateTimespan(24,0,0,0)#" >
	SELECT sum(coll_obj_count) as ct, continent_ocean
	FROM cf_geog_cat_item_counts
	WHERE
		target_table = <cfif ucase(session.flatTableName) EQ "FLAT"> 'FLAT' <cfelse> 'FILTERED_FLAT' </cfif> 
	GROUP BY continent_ocean
	ORDER BY continent_ocean
</cfquery>

<cfquery name="island_groups" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#CreateTimespan(24,0,0,0)#" >
	SELECT sum(coll_obj_count) as ct, island_group
	FROM cf_geog_cat_item_counts
	WHERE
		(island_group IS NOT NULL OR island IS NOT NULL) AND 
		target_table = <cfif ucase(session.flatTableName) EQ "FLAT"> 'FLAT' <cfelse> 'FILTERED_FLAT' </cfif> 
	GROUP BY island_group
	ORDER BY island_group
</cfquery>

<div class="container-fluid">
	<div class="row mx-0 mb-4">
	<h1 class="px-2 mt-4 mb-0 w-100 text-center">Browse MCZ Specimens by Category</h1>	
		<cfoutput>
			<main class="col-12 col-md-12 px-0 px-sm-2 py-2 mb-3 float-left mt-1">
				<div class="container-fluid mt-0">
					<p class="text-dark mt-0 px-0 px-md-3 text-justified">The Museum of Comparative Zoology (MCZ) contains over 21-million specimens in ten research collections that comprise one of the world&apos;s richest and most varied resources for studying the diversity of life. The museum serves as the primary repository for zoological specimens collected by past and present Harvard faculty-curators, staff, and associates conducting research around the world. The public can see a small percentage of our holdings on display at the Harvard Museum of Natural History, but visitors can also browse MCZ specimens and metadata online via these catagories.</p>
					<div class="tabs card-header tab-card-header px-2 pt-3">
						<cfswitch expression="#action#">
							<cfcase value="browsefeatured">
								<cfset primarytypesTabActive = "">
								<cfset primarytypesTabShow = "hidden">
								<cfset featuredTabActive = "active">
								<cfset featuredTabShow = "">
								<cfset highergeoTabActive = "">
								<cfset highergeoTabShow = "hidden">
								<cfset taxonomyTabActive = "">
								<cfset taxonomyTabShow = "hidden">
								<cfset featuredTabAria = "aria-selected=""true"" tabindex=""0"" ">
								<cfset primarytypesTabAria = "aria-selected=""false"" tabindex=""-1"" ">
								<cfset highergeoTabAria = "aria-selected=""false"" tabindex=""-1"" ">
								<cfset taxonomyTabAria = "aria-selected=""false"" tabindex=""-1"" ">
								<cfset islandTabActive = "">
								<cfset islandTabShow = "hidden">
								<cfset islandTabAria = "aria-selected=""false"" tabindex=""-1"" ">
							</cfcase>
							<cfcase value="browseprimarytypes">
								<cfset primarytypesTabActive = "active">
								<cfset primarytypesTabShow = "">
								<cfset featuredTabActive = "">
								<cfset featuredTabShow = "hidden">
								<cfset highergeoTabActive = "">
								<cfset highergeoTabShow = "hidden">
								<cfset taxonomyTabActive = "">
								<cfset taxonomyTabShow = "hidden">
								<cfset primarytypesTabAria = "aria-selected=""true"" tabindex=""0"" ">
								<cfset featuredTabAria = "aria-selected=""false"" tabindex=""-1"" ">
								<cfset highergeoTabAria = "aria-selected=""false"" tabindex=""-1"" ">
								<cfset taxonomyTabAria = "aria-selected=""false"" tabindex=""-1"" ">
								<cfset islandTabActive = "">
								<cfset islandTabShow = "hidden">
								<cfset islandTabAria = "aria-selected=""false"" tabindex=""-1"" ">
							</cfcase>
							<cfcase value="browsehighergeo">
								<cfset primarytypesTabActive = "">
								<cfset primarytypesTabShow = "hidden">
								<cfset featuredTabActive = "">
								<cfset featuredTabShow = "hidden">
								<cfset highergeoTabActive = "">
								<cfset highergeoTabShow = "hidden">
								<cfset taxonomyTabActive = "active">
								<cfset taxonomyTabShow = "">
								<cfset primarytypesTabAria = "aria-selected=""false"" tabindex=""-1"" ">
								<cfset featuredTabAria = "aria-selected=""false"" tabindex=""-1"" ">
								<cfset highergeoTabAria = "aria-selected=""false"" tabindex=""-1"" ">
								<cfset taxonomyTabAria = "aria-selected=""true"" tabindex=""0"" ">
								<cfset islandTabActive = "">
								<cfset islandTabShow = "hidden">
								<cfset islandTabAria = "aria-selected=""false"" tabindex=""-1"" ">
							</cfcase>
							<cfcase value="browsetaxonomy">
								<cfset primarytypesTabActive = "">
								<cfset primarytypesTabShow = "hidden">
								<cfset featuredTabActive = "">
								<cfset featuredTabShow = "hidden">
								<cfset highergeoTabActive = "">
								<cfset highergeoTabShow = "hidden">
								<cfset taxonomyTabActive = "active">
								<cfset taxonomyTabShow = "">
								<cfset primarytypesTabAria = "aria-selected=""false"" tabindex=""-1"" ">
								<cfset featuredTabAria = "aria-selected=""false"" tabindex=""-1"" ">
								<cfset highergeoTabAria = "aria-selected=""false"" tabindex=""-1"" ">
								<cfset taxonomyTabAria = "aria-selected=""true"" tabindex=""0"" ">
								<cfset islandTabActive = "">
								<cfset islandTabShow = "hidden">
								<cfset islandTabAria = "aria-selected=""false"" tabindex=""-1"" ">
							</cfcase>			
							<cfcase value="browseislands">
								<cfset primarytypesTabActive = "">
								<cfset primarytypesTabShow = "hidden">
								<cfset featuredTabActive = "">
								<cfset featuredTabShow = "hidden">
								<cfset highergeoTabActive = "">
								<cfset highergeoTabShow = "hidden">
								<cfset taxonomyTabActive = "">
								<cfset taxonomyTabShow = "hidden">
								<cfset primarytypesTabAria = "aria-selected=""false"" tabindex=""-1"" ">
								<cfset featuredTabAria = "aria-selected=""false"" tabindex=""-1"" ">
								<cfset highergeoTabAria = "aria-selected=""false"" tabindex=""-1"" ">
								<cfset taxonomyTabAria = "aria-selected=""false"" tabindex=""-1"" ">
								<cfset islandTabActive = "active">
								<cfset islandTabShow = "">
								<cfset islandTabAria = "aria-selected=""true"" tabindex=""0"" ">
							</cfcase>			
							<cfdefaultcase>
								<cfset featuredTabActive = "active">
								<cfset featuredTabShow = "">
								<cfset primarytypesTabActive = "">
								<cfset primarytypesTabShow = "hidden">
								<cfset highergeoTabActive = "">
								<cfset highergeoTabShow = "hidden">
								<cfset taxonomyTabActive = "">
								<cfset taxonomyTabShow = "hidden">
								<cfset featuredTabAria = "aria-selected=""true"" tabindex=""0"" ">
								<cfset primarytypesTabAria = "aria-selected=""false"" tabindex=""-1"" ">
								<cfset highergeoTabAria = "aria-selected=""false"" tabindex=""-1"" ">
								<cfset taxonomyTabAria = "aria-selected=""false"" tabindex=""-1"" ">
								<cfset islandTabActive = "">
								<cfset islandTabShow = "hidden">
								<cfset islandTabAria = "aria-selected=""false"" tabindex=""-1"" ">
							</cfdefaultcase>
						</cfswitch>
						<!-- Nav tabs -->
						<div class="tab-headers tabList px-0 px-md-3" role="tablist" aria-label="browse specimens">
							<button class="col-12 px-1 col-sm-3 px-sm-2 col-xl-auto px-xl-5 my-1 text-truncate my-md-0 #featuredTabActive#" id="1" role="tab" aria-controls="featuredPanel" #featuredTabAria# aria-label="Browse Featured Collections">Featured Collections of <br>Cataloged Items</button>
							<button class="col-12 px-1 col-sm-2 px-sm-2 col-xl-auto px-xl-5 my-1 my-md-0 #primarytypesTabActive#" id="2" role="tab" aria-controls="primarytypesPanel" #primarytypesTabAria# aria-label="Browse Primary Types">Primary <br>Types</button>
							<button class="col-12 px-1 col-sm-2 px-sm-2 col-xl-auto px-xl-5 my-1 text-truncate my-md-0 #highergeoTabActive#" id="3" role="tab" aria-controls="highergeoPanel" #highergeoTabAria# aria-label="Browse Higher Geography">Higher <br>Geography</button>
							<button class="col-12 px-1 col-sm-2 px-sm-2 col-xl-auto px-xl-5 my-1 my-md-0 #islandTabActive#" id="3" role="tab" aria-controls="islandPanel" #islandTabAria# aria-label="Browse Specimens by Islands and Island Groups">Islands<br>&nbsp;&nbsp;</button>
							<button class="col-12 px-1 col-sm-2 px-sm-2 col-xl-auto px-xl-5 my-1 my-md-0 #taxonomyTabActive#" id="4" role="tab" aria-controls="taxonomyPanel" #taxonomyTabAria# aria-label="Browse Taxonomy">Higher <br>Taxonomy</button>
						</div>
						<!-- Tab panes -->
						<div class="tab-content flex-wrap d-flex mb-1">
							<div id="featuredPanel" role="tabpanel" aria-labelledby="1" tabindex="0" class="col-12 px-0 mx-0 #featuredTabActive# unfocus"  #featuredTabShow#>
								<h2 class="px-2 h3">MCZ Featured Collections of Cataloged Items</h2>
								<cfloop query="namedGroups">
									<cfif len(#namedGroups.description#)gt 0>
										<div class="col-12 col-sm-6 col-md-4 col-xl-3 px-1 float-left my-1">
											<div class="border rounded bg-white p-2 col-12 float-right" style="height:117px;">
												<div class="row mx-0">
													<div class="col float-right px-2 mt-2">
													<cfset showTitleText = trim(collection_name)>
														<h3 class="text-truncate h5 mb-1">
															<a href="/grouping/showNamedCollection.cfm?underscore_collection_id=#namedGroups.underscore_collection_id#">
															<cfif len(showTitleText) GT 66>
																<cfset showTitleText = "#left(showTitleText,66)#..." >
															</cfif>#showTitleText#
															</a>
														</h3>
														<p class="mb-1 small">Includes #namedGroups.ct# Cataloged Items</p>
														<p class="font-italic text-capitalize mb-0 small">Collection Type: #namedGroups.underscore_collection_type#</p>
													</div>
													<cfif len(namedGroups.displayed_media_id) gt 0>
														<cfset mediablock= getMediaBlockHtml(media_id="#namedGroups.displayed_media_id#",displayAs="fixedSmallThumb",background_color="white",size="100",captionAs="textNone")>
															<div class="float-right" id="mediaBlock#namedGroups.displayed_media_id#">
																#mediablock#
															</div>
													</cfif>
												</div>
											</div>
										</div>
									</cfif>
								</cfloop>
							</div>
							<div id="primarytypesPanel" role="tabpanel" aria-labelledby="2" tabindex="-1" class="col-12 px-0 mx-0 #primarytypesTabActive# unfocus"  #primarytypesTabShow#>
								<h3 class="px-2">Primary Types</h3>			
								<div class="col-12 float-left float-left px-0 mt-1 mb-1">
									<ul class="list-group list-group-horizontal d-flex flex-wrap px-1">
										<cfquery name="primaryTypes" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#CreateTimespan(24,0,0,0)#">
											SELECT collection, collection_id, toptypestatus, count(collection_object_id) as ct
											FROM
												<cfif ucase(session.flatTableName) EQ "FLAT"> flat <cfelse> filtered_flat </cfif>
											WHERE
												toptypestatuskind = 'Primary'
												and collection is not null
												and collection != 'Herpetology Observations'
												and collection != 'Special Collections'
												and collection != 'MCZ Collections'
												and collection != 'Cryogenic'
											GROUP BY
												collection, collection_id, toptypestatus
											order by collection, toptypestatus
										</cfquery>
										<cfset lastCollection = "">
										<cfloop query="primaryTypes">
											<!--- TODO: Support specimen search for any primary type --->
											<cfif NOT lastCollection EQ primaryTypes.collection>
												<li class="list-group-item bg-white rounded border-white float-left px-2 pb-2 w-100 font-weight-bold">
													<a href="#specimenSearch#&collection_id=#primaryTypes.collection_id#&type_Status=any%20primary"> #primaryTypes.collection# </a> 
												</li>
											</cfif>
											<li class="list-group-item col-12 col-md-6 col-xl-3 float-left px-2 py-2 mb-2">
												<a href="#specimenSearch#&collection_id=#primaryTypes.collection_id#&type_status=#primaryTypes.toptypestatus#"> #primaryTypes.collection# #primaryTypes.toptypestatus#</a> (#ct#)
											</li>
											<cfset lastCollection = primaryTypes.collection>
										</cfloop>
									</ul>
								</div>
							</div>
							<div id="highergeoPanel" role="tabpanel" aria-labelledby="3" tabindex="-1" class="col-12 px-0 mx-0 #highergeoTabActive# unfocus"  #highergeoTabShow#>
								<h3 class="px-2">Browse by Higher Geography</h3>
								<div class="col-12 px-0">
								<cfset i="1">
								<cfloop query="continents">
									<cfset continent = continents.continent_ocean>
									<cfset continentLookup = continents.continent_ocean>
									<cfif len(continent) EQ 0> 
										<cfset continent = "[No Continent Value]">
										<cfset continentLookup = "NULL">
									</cfif>
									<!--- TODO: Support continent in specimen search API --->
									
									<cfquery name="countries" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#"  cachedwithin="#CreateTimespan(24,0,0,0)#">
										SELECT sum(coll_obj_count) ct, country
										FROM 
											cf_geog_cat_item_counts 
										WHERE
											target_table = <cfif ucase(session.flatTableName) EQ "FLAT"> 'FLAT' <cfelse> 'FILTERED_FLAT' </cfif> 
											AND
											<cfif len(continents.continent_ocean) EQ 0>
												continent_ocean IS NULL
											<cfelse> 
												continent_ocean = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#continents.continent_ocean#">
											</cfif>
										GROUP BY country
										ORDER BY country
									</cfquery>
										<cfif FindNoCase("continent",continents.continent_ocean) GT 0>
											<div class="w-100" id="cont_#i#">
												<h4 class="collapsebar my-2">
													<button type="button" class="border rounded headerLnk py-1 text-left w-100" data-toggle="collapse" data-target="##cont_#i#" aria-expanded="false" aria-controls="cont_#i#">#continent# <a href="#specimenSearch#&higher_geog=#continents.continent_ocean#">(#continents.ct#) </a></button>
												</h4>
												<div class="collapse w-100" id="cont_#i#">
													<ol class="flow">
														<cfset j=1>
														<cfloop query="countries">
															<cfset countryVal = countries.country>
															<cfset countryLookup = countries.country>
															<cfif len(countryVal) EQ 0> 
																<cfset countryVal = "[No Country Value]">
																<cfset countryLookup = "NULL">
															</cfif>
															<li class="list-group-item col-12 py-2 col-md-6 col-xl-4"><a href="#specimenSearch#&continent_ocean=#continentLookup#&country=#countryLookup#">#countryVal#</a> (#countries.ct#) </li>
															<cfset j=j+1>
														</cfloop>
													</ol>
												</div>
											</div>
										</cfif>
										<cfif FindNoCase("ocean",continents.continent_ocean) GT 0>
											<div class="w-100" id="ocean_#i#">
												<h4 class="collapsebar my-2">
													<button type="button" class="border rounded headerLnk py-1 text-left w-100" data-toggle="collapse" data-target="##ocean_#i#" aria-expanded="false" aria-controls="ocean_#i#">#continent# <a href="#specimenSearch#&higher_geog=#continents.continent_ocean#">(#continents.ct#) </a></button>
												</h4>
												<cfquery name="ocean_regions" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#"  cachedwithin="#CreateTimespan(24,0,0,0)#">
													SELECT sum(coll_obj_count) ct, ocean_region
													FROM 
														cf_geog_cat_item_counts 
													WHERE
														ocean_region IS NOT NULL 
														AND
														target_table = <cfif ucase(session.flatTableName) EQ "FLAT"> 'FLAT' <cfelse> 'FILTERED_FLAT' </cfif> 
														AND
														continent_ocean = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#continents.continent_ocean#">
													GROUP BY ocean_region
													ORDER BY ocean_region
												</cfquery>
												<div class="collapse w-100" id="ocean_#i#">
													<ol class="flow">
														<cfset k=1>
														<cfloop query="ocean_regions">
															<cfset regionVal = ocean_regions.ocean_region>
															<cfset regionLookup = ocean_regions.ocean_region>
															<cfif len(regionVal) EQ 0> 
																<cfset regionVal = "[No Ocean Region Value]">
																<cfset regionLookup = "NULL">
															</cfif>
															<li class="list-group-item col-12 py-2 col-md-6 col-xl-4"><a href="#specimenSearch#&continent_ocean=#continentLookup#&ocean_region=#regionLookup#">#regionVal#</a> (#ocean_regions.ct#) </li>
															<cfset k=k+1>
														</cfloop>
													</ol>
												</div>
											</div>
										</cfif>
									<cfset i=i+1>
								</cfloop>
								</div>
							</div>
							<div id="islandPanel" role="tabpanel" aria-labelledby="3" tabindex="-1" class="col-12 px-0 mx-0 #islandTabActive# unfocus"  #islandTabShow#>
							<h3 class="px-3">Browse By Islands</h3>
								<div class="col-12 px-0">
									<cfset i=1>
									<cfloop query="island_groups">
										<cfset group = island_groups.island_group>
										<cfset groupLookup = island_groups.island_group>
										<cfif len(group) EQ 0> 
											<cfset group = "[No Island Group]">
											<cfset groupLookup = "NULL">
										</cfif>
											<cfif #i# eq island_groups.recordCount>
												<cfset isnogroup = "col-12">
											<cfelse>
												<cfset isnogroup ="col-12 col-md-6">
											</cfif>
											<div class="#isnogroup#">
										<!--- TODO: Support island/island_group in specimen search API --->
										<div class="w-100 my-2">
											<h4 class="collapsebar mb-0">
												<button type="button" class="border rounded headerLnk py-1 text-left w-100" data-toggle="collapse" data-target="##islandgroup_#i#" aria-expanded="false" aria-controls="islandgroup_#i#">
													#group# &nbsp;&nbsp;
													<a class="w-100 d-inline px-3 py-1" href="#specimenSearch#&higher_geog=#island_groups.island_group#">(#island_groups.ct#)</a>
												</button>
											</h4>
											<cfquery name="islands" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#"  cachedwithin="#CreateTimespan(24,0,0,0)#">
												SELECT sum(coll_obj_count) ct, island
												FROM 
													cf_geog_cat_item_counts 
												WHERE
													target_table = <cfif ucase(session.flatTableName) EQ "FLAT"> 'FLAT' <cfelse> 'FILTERED_FLAT' </cfif> 
													AND
													<cfif len(island_groups.island_group) EQ 0>
														island_group IS NULL
													<cfelse> 
														island_group = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#island_groups.island_group#">
													</cfif>
												GROUP BY island
												ORDER BY island
											</cfquery>
											
											<cfif #i# eq island_groups.recordCount> 
												<cfset islandValues = "flow-manyislandgroups">
											<cfelse>
												<cfset islandValues = "flow-islandgroups">
											</cfif>
								
											<div class="collapse w-100" id="islandgroup_#i#">
												<ol class=" pt-2 #islandValues#">
													<cfloop query="islands">
														<cfset islandVal = islands.island>
														<cfset islandLookup = islands.island>
														<cfif len(islandVal) EQ 0> 
															<cfset islandVal = "[No Island Value]">
															<cfset islandLookup = "NULL">
														</cfif>
														<li>	
														<a href="#specimenSearch#&island_group=#groupLookup#&island=#islandLookup#">#islandVal# (#islands.ct#)</a>
														</li>
													</cfloop>
												</ol>
											</div>
										</div>
									
									</div>
										<cfset i= i+1>
									</cfloop>
								</div>
							</div>
							<div id="taxonomyPanel" role="tabpanel" aria-labelledby="4" tabindex="-1" class="col-12 px-0 mx-0 #taxonomyTabActive# unfocus"  #taxonomyTabShow#>
								<h3 class="px-3">Browse by Higher Taxonomy</h3>
								<div class="col-12">
									<div class="w-100 my-2">
										<h4 class="collapsebar">
											<button class="border rounded headerLnk py-1 text-left w-100" data-target="##phylum" data-toggle="collapse" aria-expanded="false" aria-controls="phylum">Phylum</button>
										</h4>
										<div class="collapse w-100" id="phylum">
											<ol class="flow pt-2">
											<cfloop query="phyla">
												<li>
													<a href="#specimenSearch#&phylum=#phylum#">#phylum# (#ct#)</a> 
												</li>
											</cfloop>
											</ol>
										</div>
									</div>
									<div class="my-2 w-100">
										<h4 class="collapsebar">
											<button class="border rounded headerLnk py-1 text-left w-100" data-target="##notphylum" data-toggle="collapse" aria-expanded="false" aria-controls="notphylum">Orders &ndash; no Phylum value</button>
										</h4>
										<div class="collapse" id="notphylum">
											<ol class="flow pt-2">
												<cfloop query="notphyla">
													<li>
														<a class="" href="#specimenSearch#&phylum=NULL&kingdom=#kingdom#&phylorder=#phylorder#">#kingdom#:#phylorder# (#ct#)</a> 
													</li>
												</cfloop>
											</ol>
										</div>
									</div>
									<div class="my-1 w-100">
										<h4 class="collapsebar">
											<button type="button" class="border rounded headerLnk py-1 text-left w-100" data-toggle="collapse" data-target="##notkingdom" aria-expanded="false" aria-controls="notkingdom">Taxon records with no value for Kingdom</button>
										</h4>
										<div class="collapse" id="notkingdom" >
											<ol class="flow pt-2">
											<cfloop query="notkingdoms">
												<li>
													
													<a class="" href="#specimenSearch#&phylum=NULL&kingdom=NULL&phylorder=NULL&scientific_name=#scientific_name#">#scientific_name# (#ct#)</a>
												</li>
											</cfloop>
											</ol>
										</div>
									</div>
								</div>
							</div>
						</div>
					</div>
				</div>
			</main>
		</cfoutput>
	</div>
</div>

<cfinclude template = "/shared/_footer.cfm">
