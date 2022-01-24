<cfset pageTitle = "Browse Specimen Data">
<!--
specimens/SpecimenBrowse.cfm

Copyright 2020 President and Fellows of Harvard College

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
	<cfset action="collection">
</cfif>
<cfswitch expression="#action#">
	<!--- API note: action and method seem duplicative, action is required and used to determine
			which tab to show, method invokes target backing method in form submission, but when 
			invoking this page with execute=true method does not need to be included in the call
			even though it will be included in the URI parameter list when clicking on the 
			"Link to this search" link.
	--->
	<cfcase value="browseprimarytypes">
		<cfset pageTitle = "Browse Primary Types">
		<cfif isdefined("execute")>
			<cfset execute="primarytypes">
		</cfif>
	</cfcase>
	<cfcase value="browsefeatured">
		<cfset pageTitle = "Browse Featured Collections">
		<cfif isdefined("execute")>
			<cfset execute="featured">
		</cfif>
	</cfcase>
	<cfcase value="browsehighergeo">
		<cfset pageTitle = "Browse Higher Geography">
		<cfif isdefined("execute")>
			<cfset execute="highergeo">
		</cfif>
	</cfcase>
	<cfcase value="browsetaxonomy">
		<cfset pageTitle = "Browse Taxonomy">
		<cfif isdefined("execute")>
			<cfset execute="taxonomy">
		</cfif>
	</cfcase>
	<cfdefaultcase>
		<cfset pageTitle = "Browse Primary Types">
		<cfif isdefined("execute")>
			<cfset execute="primarytypes">
		</cfif>
	</cfdefaultcase>
</cfswitch>
<cfinclude template = "/shared/_header.cfm">
<cfinclude template="/grouping/component/search.cfc" runOnce="true">
<cfinclude template="/media/component/search.cfc" runOnce="true">
<script src="/shared/js/tabs.js"></script>
<cfquery name="namedGroups" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#CreateTimespan(24,0,0,0)#">
	SELECT count(flat.collection_object_id) ct, underscore_collection.collection_name, underscore_collection.underscore_collection_id, underscore_collection.mask_fg
	FROM UNDERSCORE_COLLECTION
	LEFT JOIN underscore_relation on underscore_collection.underscore_collection_id = underscore_relation.underscore_collection_id
	LEFT JOIN<cfif ucase(session.flatTableName) EQ "FLAT"> flat <cfelse> filtered_flat </cfif> flat
		on underscore_relation.collection_object_id = flat.collection_object_id
	<cfif NOT isdefined("session.roles") OR listfindnocase(session.roles,"coldfusion_user") EQ 0>
		WHERE underscore_collection.mask_fg = 0
	</cfif>
	GROUP BY
		underscore_collection.collection_name, underscore_collection.underscore_collection_id, underscore_collection.mask_fg
	ORDER BY underscore_collection.collection_name
</cfquery>
<cfquery name="types" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	SELECT underscore_collection_type, description 
	FROM ctunderscore_collection_type
	WHERE
		<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_specimens")>
			underscore_collection_type is not null
		<cfelse>
			underscore_collection_type <> 'workflow'
		</cfif>
</cfquery>
<cfquery name="namedGroups2" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	SELECT
		count(flat.collection_object_id) ct, 
		underscore_collection.collection_name, 
		underscore_collection.underscore_collection_id, underscore_collection.mask_fg,
		underscore_collection.description, underscore_collection.underscore_collection_type,
		underscore_collection.displayed_media_id
	FROM
		underscore_collection 
		LEFT JOIN underscore_relation on underscore_collection.underscore_collection_id = underscore_relation.underscore_collection_id
		LEFT JOIN<cfif ucase(session.flatTableName) EQ "FLAT"> flat <cfelse> filtered_flat </cfif> flat
			on underscore_relation.collection_object_id = flat.collection_object_id
	WHERE
		underscore_collection.underscore_collection_id IS NOT NULL
		<cfif NOT isdefined("session.roles") OR listfindnocase(session.roles,"coldfusion_user") EQ 0>
			AND underscore_collection.mask_fg = 0
		</cfif>
		<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_specimens")>
			AND underscore_collection_type is not null
		<cfelse>
			AND underscore_collection.underscore_collection_type <> 'workflow'
		</cfif>
	GROUP BY
		underscore_collection.collection_name, 
		underscore_collection.underscore_collection_id, underscore_collection.mask_fg,
		underscore_collection.description, underscore_collection.underscore_collection_type,
		underscore_collection.displayed_media_id
	ORDER BY underscore_collection_type, collection_name
</cfquery>

<cfquery name="countries" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#CreateTimespan(24,0,0,0)#">
	select count(*) ct, country 
	from 
		<cfif ucase(session.flatTableName) EQ "FLAT"> flat <cfelse> filtered_flat </cfif>
	where country is not null
	group by country
	order by country
</cfquery>
<cfquery name="continents" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#CreateTimespan(24,0,0,0)#" >
	select count(*) ct, continent_ocean, country
	from
		<cfif ucase(session.flatTableName) EQ "FLAT"> flat <cfelse> filtered_flat </cfif>
	group by continent_ocean, country
	order by continent_ocean, country
</cfquery>

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
<cfquery name="primaryTypes" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#CreateTimespan(24,0,0,0)#" >
	SELECT collection, collection_id, toptypestatus, count(*) as ct
	FROM
		<cfif ucase(session.flatTableName) EQ "FLAT"> flat <cfelse> filtered_flat </cfif>
	WHERE
		toptypestatuskind = 'Primary'
	GROUP BY
		collection, collection_id, toptypestatus
	ORDER BY 
		collection
</cfquery>

<cfif findNoCase('redesign',Session.gitBranch) GT 0>
	<cfset specimenSearch="/Specimens.cfm?execute=true&action=fixedSearch">
<cfelse>
	<cfset specimenSearch="/SpecimenResults.cfm?ShowObservations=true">
</cfif>

<cfquery name="types" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	SELECT underscore_collection_type, description 
	FROM ctunderscore_collection_type
	WHERE
		<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_specimens")>
			underscore_collection_type is not null
		<cfelse>
			underscore_collection_type <> 'workflow'
		</cfif>
</cfquery>
<cfquery name="namedGroups" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	SELECT
		count(FF.collection_object_id) ct, 
		underscore_collection.collection_name, 
		underscore_collection.underscore_collection_id, underscore_collection.mask_fg,
		underscore_collection.description, underscore_collection.underscore_collection_type,
		underscore_collection.displayed_media_id
	FROM
		underscore_collection 
		LEFT JOIN underscore_relation on underscore_collection.underscore_collection_id = underscore_relation.underscore_collection_id
		LEFT JOIN <cfif ucase(session.flatTableName) EQ "FLAT"> flat <cfelse> filtered_flat </cfif> FF
			on underscore_relation.collection_object_id = FF.collection_object_id
	WHERE
		underscore_collection.underscore_collection_id IS NOT NULL
		<cfif NOT isdefined("session.roles") OR listfindnocase(session.roles,"coldfusion_user") EQ 0>
			AND underscore_collection.mask_fg = 0
		</cfif>
		<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_specimens")>
			AND underscore_collection_type is not null
		<cfelse>
			AND underscore_collection.underscore_collection_type <> 'workflow'
		</cfif>
	GROUP BY
		underscore_collection.collection_name, 
		underscore_collection.underscore_collection_id, underscore_collection.mask_fg,
		underscore_collection.description, underscore_collection.underscore_collection_type,
		underscore_collection.displayed_media_id
	ORDER BY underscore_collection_type, collection_name
</cfquery>



<div class="container-fluid">
	<div class="row mx-0 mb-4">
	<h1 class="px-2 mt-4 mb-0 w-100 text-center">Browse MCZ Specimens by Category</h1>	
		<cfoutput>
			<main class="col-12 col-md-12 px-2 py-2 mb-3 float-left mt-1">
				<div class="container mt-0">
					<p class="text-dark mt-0 px-3 text-justified">The Museum of Comparative Zoology (MCZ) contains over 21-million specimens in ten research collections that comprise one of the world's richest and most varied resources for studying the diversity of life. The museum serves as the primary repository for zoological specimens collected by past and present Harvard faculty-curators, staff, and associates conducting research around the world. The public can see a small percentage of our holdings on display at the Harvard Museum of Natural History, but visitors can also browse MCZ specimens and metadata online via these catagories.</p>
					<div class="tabs card-header tab-card-header px-2 pt-3">
						<cfswitch expression="#action#">
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
							</cfcase>
							<cfcase value="browsefeatured">
								<cfset primarytypesTabActive = "">
								<cfset primarytypesTabShow = "hidden">
								<cfset featuredTabActive = "active">
								<cfset featuredTabShow = "">
								<cfset highergeoTabActive = "">
								<cfset highergeoTabShow = "hidden">
								<cfset taxonomyTabActive = "">
								<cfset taxonomyTabShow = "hidden">
								<cfset primarytypesTabAria = "aria-selected=""false"" tabindex=""-1"" ">
								<cfset featuredTabAria = "aria-selected=""true"" tabindex=""0"" ">
								<cfset highergeoTabAria = "aria-selected=""false"" tabindex=""-1"" ">
								<cfset taxonomyTabAria = "aria-selected=""false"" tabindex=""-1"" ">
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
							</cfcase>			
							<cfdefaultcase>
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
							</cfdefaultcase>
						</cfswitch>
						<!-- Nav tabs -->
						<div class="tab-headers tabList" role="tablist" aria-label="browse specimens">
							<button class="col-12 col-md-auto px-md-5 my-1 my-md-0 #primarytypesTabActive#" id="1" role="tab" aria-controls="primarytypesPanel" #primarytypesTabAria# aria-label="Browse Primary Types">Primary Types</button>
							<button class="col-12 col-md-auto px-md-5 my-1 my-md-0 #featuredTabActive#" id="2" role="tab" aria-controls="featuredPanel" #featuredTabAria# aria-label="Browse Featured Collections">Featured Collections of Cataloged Items</button>
							<button class="col-12 col-md-auto px-md-5 my-1 my-md-0 #highergeoTabActive#" id="3" role="tab" aria-controls="highergeoPanel" #highergeoTabAria# aria-label="Browse Higher Geography">Higher Geography</button>
							<button class="col-12 col-md-auto px-md-5 my-1 my-md-0 #taxonomyTabActive#" id="4" role="tab" aria-controls="taxonomyPanel" #taxonomyTabAria# aria-label="Browse Taxonomy">Taxonomy</button>
						</div>
						<!-- Tab panes -->
						<div class="tab-content flex-wrap d-flex mb-1">
							<div id="primarytypesPanel" role="tabpanel" aria-labelledby="1" tabindex="0" class="col-12 px-0 mx-0 #primarytypesTabActive# unfocus"  #primarytypesTabShow#>
								<h3 class="px-2">Primary Types</h3>			
								<div class="col-12 float-left float-left px-0 mt-1 mb-1">
									<ul class="d-flex flex-wrap px-1">
										<cfloop query="primaryTypes">	
										<li class="list-group-item col-3 float-left px-1 mb-2">
											<a href="#specimenSearch#&collection_id=#primaryTypes.collection_id#&type_status=#toptypestatus#"> #collection# #toptypestatus#</a> (#ct#)
										</li>
										</cfloop>
									</ul>
								</div>
							</div>
							<div id="featuredPanel" role="tabpanel" aria-labelledby="2" tabindex="-1" class="col-12 px-0 mx-0 #featuredTabActive# unfocus"  #featuredTabShow#>
								<h3 class="px-2">MCZ Featured Collections of Cataloged Items</h3>
								<cfloop query="namedGroups2">
									<cfquery name="images" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
										SELECT
											displayed_media_id as media_id
										FROM
											underscore_relation 
										INNER JOIN underscore_collection
											on underscore_collection.underscore_collection_id = underscore_relation.underscore_collection_id
										WHERE rownum = 1 
										and underscore_relation.underscore_collection_id = #namedGroups2.underscore_collection_id#
									</cfquery>
									<cfif len(#namedGroups2.description#)gt 0>
										<div class="col-12 col-md-3 px-1 float-left my-1">
											<div class="border rounded bg-white p-2 col-12 float-left" style="min-height: 116px;">
												<div class="row mx-0">
													<cfif len(images.media_id) gt 0>
														<cfset mediablock= getMediaBlockHtml(media_id="#images.media_id#",size="105",displayAs="thumbTiny")>
															<div class="float-left" id="mediaBlock#images.media_id#">
																#mediablock#
															</div>
													</cfif>
													<div class="col float-left px-2 mt-2">
													<cfset showTitleText = trim(collection_name)>
														<h3 class="h5 mb-1">
															<a href="/grouping/showNamedCollection.cfm?underscore_collection_id=#namedGroups.underscore_collection_id#">
															<cfif len(showTitleText) GT 66>
																<cfset showTitleText = "#left(showTitleText,66)#..." >
															</cfif>#showTitleText#
															</a>
														</h3>
														<p class="mb-1 small">Includes #namedGroups2.ct# Cataloged Items</p>
														<p class="font-italic text-capitalize mb-0 small">Collection Type: #namedGroups2.underscore_collection_type#</p>
													</div>
												</div>
											</div>
										</div>
									</cfif>
								</cfloop>
							</div>
							<div id="highergeoPanel" role="tabpanel" aria-labelledby="3" tabindex="-1" class="col-12 px-0 mx-0 #highergeoTabActive# unfocus"  #highergeoTabShow#>
								<h3 class="px-2">Browse by Higher Geography</h3>
								<cfquery name="continental" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#CreateTimespan(24,0,0,0)#" >
									SELECT distinct g1.continent_ocean
									FROM
										geog_auth_rec g1
									WHERE 
										g1.continent_ocean is not null
										and g1.continent_ocean not like '%/%'
										and g1.continent_ocean not like '%[no higher_geography data]%'
									GROUP BY 
										g1.continent_ocean
									ORDER BY
										g1.continent_ocean
								</cfquery>
								<ul class="list-group col-12 px-0 list-group-horizontal d-flex flex-wrap pb-2">
								<cfloop query="continental">
									<cfquery name="country1" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#"  result="country1_result">
									select count(*) ct, flat.country 
									FROM geog_auth_rec 
									left join <cfif ucase(session.flatTableName) EQ "FLAT"> flat <cfelse> filtered_flat </cfif> on flat.continent_ocean = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#continental.continent_ocean#">
									group by flat.country
									order by ct desc
									</cfquery>

									<li class="w-100 list-group-item mt-2 font-weight-bold"><a href="#specimenSearch#&higher_geog=#continent_ocean#">#continental.continent_ocean# </a></li>
									<cfloop query="country1">
										<li class="list-group-item col-6 col-md-3"><a href="#specimenSearch#&country=#country1.country#">#country1.country#</a> </li>
									</cfloop>
								</cfloop>
								</ul>
							</div>
							<div id="taxonomyPanel" role="tabpanel" aria-labelledby="4" tabindex="-1" class="col-12 px-0 mx-0 #taxonomyTabActive# unfocus"  #taxonomyTabShow#>
								<h3 class="px-2">Browse by Higher Taxonomy</h3>
								<ul class="d-flex px-1 flex-wrap">
									<cfloop query="phyla">
										<li class="list-group-item col-2 px-1 float-left w-100 h-auto" style="word-wrap:break-word;"><a href="#specimenSearch#&phylum=#phylum#">#phylum#</a> (#ct#)</li>
									</cfloop>
									<cfloop query="notphyla">
										<li class="list-group-item col-2 px-1 float-left w-100 h-auto" style="word-wrap:break-word;"><a href="#specimenSearch#&phylum=NULL&kingdom=#kingdom#&phylorder=#phylorder#">#kingdom#:#phylorder#</a> (#ct#)</li>
									</cfloop>
									<cfloop query="notkingdoms">
										<li class="list-group-item col-2 px-1 float-left w-100 h-auto" style="word-wrap:break-word;"><a href="#specimenSearch#&phylum=NULL&kingdom=NULL&phylorder=NULL&scientific_name=#scientific_name#">#scientific_name#</a> (#ct#)</li>
									</cfloop>
								</ul>
							</div>
						</div>
					</div>
				</div>
			</main>
		</cfoutput>
	</div>
</div>
									
									
									
<script>
	/**
 * cbpFixedScrollLayout.js v1.0.0
 * http://www.codrops.com
 *
 * Licensed under the MIT license.
 * http://www.opensource.org/licenses/mit-license.php
 * 
 * Copyright 2013, Codrops
 * http://www.codrops.com
 */
var cbpFixedScrollLayout = (function() {

	// cache and initialize some values
	var config = {
		// the cbp-fbscroller´s sections
		$sections : $( '#cbp-scroller > section' ),
		// the navigation links
		$navlinks : $( '#cbp-scroller > nav:first > a' ),
		// index of current link / section
		currentLink : 0,
		// the body element
		$body : $( 'container-fluid' ),
		// the body animation speed
		animspeed : 650,
		// the body animation easing (jquery easing)
		animeasing : 'easeInOutExpo'
	};

	function init() {

		// click on a navigation link: the body is scrolled to the position of the respective section
		config.$navlinks.on( 'click', function() {
			scrollAnim( config.$sections.eq( $( this ).index() ).offset().top );
			return false;
		} );

		// 2 waypoints defined:
		// First one when we scroll down: the current navigation link gets updated. 
		// A `new section´ is reached when it occupies more than 70% of the viewport
		// Second one when we scroll up: the current navigation link gets updated. 
		// A `new section´ is reached when it occupies more than 70% of the viewport
		config.$sections.waypoint( function( direction ) {
			if( direction === 'down' ) { changeNav( $( this ) ); }
		}, { offset: '30%' } ).waypoint( function( direction ) {
			if( direction === 'up' ) { changeNav( $( this ) ); }
		}, { offset: '-30%' } );

		// on window resize: the body is scrolled to the position of the current section
		$( window ).on( 'debouncedresize', function() {
			scrollAnim( config.$sections.eq( config.currentLink ).offset().top );
		} );
		
	}

	// update the current navigation link
	function changeNav( $section ) {
		config.$navlinks.eq( config.currentLink ).removeClass( 'cbp-current' );
		config.currentLink = $section.index( 'section' );
		config.$navlinks.eq( config.currentLink ).addClass( 'cbp-current' );
	}

	// function to scroll / animate the body
	function scrollAnim( top ) {
		config.$body.stop().animate( { scrollTop : top }, config.animspeed, config.animeasing );
	}

	return { init : init };

})();
</script>



<cfinclude template = "/shared/_footer.cfm">
