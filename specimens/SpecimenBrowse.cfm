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
<cfinclude template = "/shared/_header.cfm">
<cfinclude template="/grouping/component/search.cfc" runOnce="true">
<cfinclude template="/media/component/search.cfc" runOnce="true">
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
		LEFT JOIN<cfif ucase(session.flatTableName) EQ "FLAT"> flat <cfelse> filtered_flat </cfif>
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
<cfquery name="notcountries" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#CreateTimespan(24,0,0,0)#" >
	select count(*) ct, continent_ocean
	from
		<cfif ucase(session.flatTableName) EQ "FLAT"> flat <cfelse> filtered_flat </cfif>
	where country is null
	group by continent_ocean
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
<div class="w-100">
<style>
	.nav-tabs .nav-link {background-color: #fff;border-color: #fff;border-bottom: 1px solid #f5f5f5;font-weight: 450;}	
	.nav-tabs .nav-link.active {background-color: #f5f5f5;border-color: #f5f5f5; font-weight:550;}
</style>

<h1 class="px-2 mt-4 mb-2 text-center">Browse Specimens by Category</h1>		
</div>
<div class="container-fluid">
	<div class="row mx-0 mb-4">
		<p class="font-italic text-dark w-75 mt-3 text-center">Placeholder text for overview of page....</p>
		<cfoutput>
			<main class="col-12 col-md-12 px-2 py-2 mb-3 float-left mt-1">
				<div class="container mt-2">
					<div class="tabs card-header tab-card-header px-2 pt-3">
						<!-- Nav tabs -->
						<ul class="nav nav-tabs">
							<li class="nav-item mr-1">
							<a class="nav-link show active" href="##home">Primary Types</a>
							</li>
							<li class="nav-item mx-1">
							<a class="nav-link" href="##menu1">MCZ Featured Collections of Cataloged Items</a>
							</li>
							<li class="nav-item mx-1">
							<a class="nav-link" href="##menu2">Browse by Higher Geography</a>
							</li>
							<li class="nav-item mx-1">
							<a class="nav-link" href="##menu3">Browse by Higher Taxonomy</a>
							</li>
						</ul>
						<!-- Tab panes -->
						<div class="tab-content border flex-wrap d-flex mb-1">
							<div id="home" class="container-fluid tab-pane active"><br>
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
							<div id="menu1" class="container tab-pane fade"><br>
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
										<div class="col-12 col-md-3 px-1 float-right my-1">
											<div class="border rounded bg-white p-2 col-12 float-left" style="min-height: 116px;">
												<div class="row mx-0">
													<cfif len(images.media_id) gt 0>
														<cfset mediablock= getMediaBlockHtml(media_id="#images.media_id#",size="105",displayAs="thumbTiny")>
															<div class="float-left bg-light border rounded" style="width: 100px;" id="mediaBlock#images.media_id#">
																#mediablock#
															</div>
													</cfif>
													<div class="col float-left px-2 mt-2">
														<h3 class="h5 mt-0 px-0">
															<a href="/grouping/showNamedCollection.cfm?underscore_collection_id=#namedGroups2.underscore_collection_id#">#namedGroups2.collection_name#</a>
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
							<div id="menu2" class="container tab-pane fade"><br>
								<h3 class="px-2">Browse by Higher Geography</h3>
								<ul class="d-flex px-1 flex-wrap">
									<cfloop query="countries">
										<li class="list-group-item col-3 px-1 float-left w-100 h-auto" style="word-wrap:break-word;"><a href="#specimenSearch#&country=#country#">#country#</a> (#ct#)</li>
									</cfloop>
									<cfloop query="notcountries">
										<li class="list-group-item col-3 px-1 float-left w-100 h-auto" style="word-wrap:break-word;"><a href="#specimenSearch#&country=NULL&continent_ocean=#continent_ocean#">#continent_ocean#</a> (#ct#)</li>
									</cfloop>
								</ul>
							</div>
							<div id="menu3" class="container tab-pane fade"><br>
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
			<script>
				$(document).ready(function(){
				  $(".nav-tabs a").click(function(){
					$(this).tab('show');
				  });
				  $('.nav-tabs a').on('shown.bs.tab', function(event){
					var x = $(event.target).text();         // active tab
					var y = $(event.relatedTarget).text();  // previous tab
					$(".act span").text(x);
					$(".prev span").text(y);
				  });
				});
			</script>
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
<script>
//Get the button
var mybutton = document.getElementById("myBtn");

// When the user scrolls down 20px from the top of the document, show the button
window.onscroll = function() {scrollFunction()};

function scrollFunction() {
  if (document.body.scrollTop > 20 || document.documentElement.scrollTop > 20) {
    mybutton.style.display = "block";
  } else {
    mybutton.style.display = "none";
  }
}

// When the user clicks on the button, scroll to the top of the document
function topFunction() {
  document.body.scrollTop = 0;
  document.documentElement.scrollTop = 0;
}
</script>


<cfinclude template = "/shared/_footer.cfm">
