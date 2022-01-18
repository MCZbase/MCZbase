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
</cfquery>

<cfif findNoCase('redesign',Session.gitBranch) GT 0>
	<cfset specimenSearch="/Specimens.cfm?execute=true&action=fixedSearch">
<cfelse>
	<cfset specimenSearch="/SpecimenResults.cfm?ShowObservations=true">
</cfif>
<style>
/* Set all parents to full height */
.container-fluid, 
.container,
.cbp-scroller,
.cbp-scroller section { 
	height: 100%; 
}

/* The nav is fixed on the right side  and we center it by translating it 50% 
(we don't know it's height so we can't use the negative margin trick) */
.cbp-scroller > nav {
	position: fixed;
	z-index: 9999;
	right: 100px;
	top: 50%;
	-webkit-transform: translateY(-50%);
	-moz-transform: translateY(-50%);
	-ms-transform: translateY(-50%);
	transform: translateY(-50%);
}

.cbp-scroller > nav a {
	display: block;
	position: relative;
	color: transparent;
	height: 50px;
}

.cbp-scroller > nav a:after {
	content: '';
	position: absolute;
	width: 24px;
	height: 24px;
	border-radius: 50%;
	border: 4px solid ##fff;
}

.cbp-scroller > nav a:hover:after {
	background: rgba(255,255,255,0.6);
}

.cbp-scroller > nav a.cbp-current:after {
	background: ##fff;
}

/* background-attachment does the trick */
.cbp-scroller section {
	position: relative;
	background-position: top center;
	background-repeat: no-repeat;
	background-size: cover;
	background-attachment: fixed;
}

##section1 {
	background-image: url(../images/1.jpg);
	background-color: yellow;
}

##section2 {
	background-image: url(../images/2.jpg);
	background-color: green;
}

##section3 {
	background-image: url(../images/3.jpg);
	background-color: red;
}

##section4 {
	background-image: url(../images/4.jpg);
	background-color: blue;
}
</style>
<cfoutput>
	<h1 class="text-center mt-5 mb-3">Browse Specimens by Category</h1>
	<main class="container-fluid bg-light px-2 border rounded">
		<a name="top" id="top" class="hidden">Top</a>
		<div class="row">
			<nav class="col-3 my-2">
				<ul class="list-unstyled text-right px-0 pr-xl-0 pl-xl-3 mb-3 mt-4 bg-light">
					<li class="my-3">
						<h2 class="h3 mb-0 w-75 float-right"><a href="##section1" class="text-dark cbp-current">Primary Types</a></h2>
						<p class="small90 text-muted w-75 float-right">description</p>
					</li>
					<li class="my-3">
						<h2 class="h3 mb-0 w-75 float-right"><a href="##section2" class="text-dark">MCZ Featured Collections of Cataloged Items</a></h2>
						<p class="small90 text-muted w-75 float-right">description</p>
					</li>
					<li class="my-3">
						<h2 class="h3 mb-0 w-75 float-right"><a href="##section3" class="text-dark">Browse by Higher Geography</a></h2>
						<p class="small90 text-muted w-75 float-right">description</p>
					</li>
					<li class="my-3">
						<h2 class="h3 mb-0 w-75 float-right"><a href="##section4" class="text-dark">Browse by Higher Taxonomy</a></h2>
						<p class="small90 text-muted w-75 float-right">description</p>
					</li>
					<div class="input-group w-auto float-right mt-2">
						<div class="form-outline">
							<input type="search" id="form1" class="data-entry-input py-1" />
						</div>
						<button type="button" class="btn btn-xs btn-primary py-1"><i class="fas fa-search"></i></button>
					</div>
				</ul>
			</nav>
			<div class="col-9 my-2">
			
				<section class="col-12 mt-2" id="section1">
					<h2 class="h3 px-3">Primary Types</h2>
					<ul class="d-flex flex-wrap px-2">
						<cfset typeStatusColor = "text-white">
						<cfloop query="primaryTypes">
							<cfif #primaryTypes.toptypestatus# eq "Holotype">
								<cfset #typeStatusColor# eq "text-danger">
							<cfelseif #primaryTypes.toptypestatus# eq "Syntype">
								<cfset #typeStatusColor# eq "text-info">
							<cfelse>
								<cfset #typeStatusColor# eq "text-white">
							</cfif>
							#toptypestatus#
							<li class="list-group-item col-2"><i class="fa fa-square #typeStatusColor#" aria-hidden="true"></i> <a href="#specimenSearch#&collection_id=#primaryTypes.collection_id#&type_status=#toptypestatus#"> #collection# #toptypestatus#</a> (#ct#)</li>
						</cfloop>
					</ul>
				</section>
				<section class="col-12 mt-3" id="section2">
					<h2 class="h3 px-3">MCZ Featured Collections of Cataloged Items</h2>
					<ul class="d-flex flex-wrap px-2">
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
								<div class="col-12 col-md-3 px-1 float-right my-2">
									<div class="border rounded bg-white py-2 col-12 px-2 float-left">
										<div class="row mx-0">
											<cfif len(images.media_id) gt 0>
												<cfset mediablock= getMediaBlockHtml(media_id="#images.media_id#",size="105",displayAs="thumbTiny")>
													<div class="px-1 float-left py-2 bg-light border rounded" style="width: 100px;" id="mediaBlock#images.media_id#">
														#mediablock#
													</div>
											</cfif>
											<div class="col float-left mt-2">
												<h3 class="h5">
													<a href="/grouping/showNamedCollection.cfm?underscore_collection_id=#namedGroups2.underscore_collection_id#">#namedGroups2.collection_name#</a>
												</h3>
												<p class="mb-2 small">Includes #namedGroups2.ct# Cataloged Items</p>
												<p class="font-italic text-capitalize mb-0 small">Collection Type: #namedGroups2.underscore_collection_type#</p>
											</div>
										</div>
									</div>
								</div>
							</cfif>
						</cfloop>
					</ul>
						<a href="##top" class="px-2">top</a>
				</section>
				<section class="col-12 mt-3" id="section3">
					<h2 class="h3 px-3">Browse by higher geography</h2>
					<ul class="d-flex px-2 flex-wrap">
						<cfloop query="countries">
							<li class="list-group-item col-2"><a href="#specimenSearch#&country=#country#">#country#</a> (#ct#)</li>
						</cfloop>
						<cfloop query="notcountries">
							<li class="list-group-item col-2"><a href="#specimenSearch#&country=NULL&continent_ocean=#continent_ocean#">#continent_ocean#</a> (#ct#)</li>
						</cfloop>
					</ul>
				</section>
				<section class="col-12 mt-3" id="section4">
					<h2 class="h3 px-3">Browse by higher taxonomy</h2>
					<ul class="d-flex px-2 flex-wrap">
						<cfloop query="phyla">
							<li class="list-group-item col-2"><a href="#specimenSearch#&phylum=#phylum#">#phylum#</a> (#ct#)</li>
						</cfloop>
						<cfloop query="notphyla">
							<li class="list-group-item col-2"><a href="#specimenSearch#&phylum=NULL&kingdom=#kingdom#&phylorder=#phylorder#">#kingdom#:#phylorder#</a> (#ct#)</li>
						</cfloop>
						<cfloop query="notkingdoms">
							<li class="list-group-item col-2"><a href="#specimenSearch#&phylum=NULL&kingdom=NULL&phylorder=NULL&scientific_name=#scientific_name#">#scientific_name#</a> (#ct#)</li>
						</cfloop>
					</ul>
				</section>
			</div>
		</div>
	</main>
</cfoutput>
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
