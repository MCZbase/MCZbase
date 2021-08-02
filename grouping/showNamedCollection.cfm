<!---
grouping/showNamedCollection.cfm

For read only public view of arbitrary groupings of collection objects and
added value html describing them.

Copyright 2021 President and Fellows of Harvard College

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

--->
<cfset pageTitle = "Named Group">
<cfif isDefined("underscore_collection_id") AND len(underscore_collection_id) GT 0>
	<cfquery name="getTitle" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getNamedGroup_result">
		SELECT collection_name
		FROM underscore_collection
		WHERE underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
		<cfif NOT isdefined("session.roles") OR listfindnocase(session.roles,"coldfusion_user") EQ 0>
			AND mask_fg = 0
		</cfif>
	</cfquery>
	<cfif getTitle.recordcount EQ 1>
		<cfset pageTitle = getTitle.collection_name>
	</cfif>
</cfif>
<cfinclude template="/shared/_header.cfm">
<cfoutput>
<style>
.carousel-wrapperX {
	overflow: hidden;
	width: 100%;
	margin: 0;
	position: relative;
	height: auto;
}
.carousel-wrapperX * {
	box-sizing: border-box;
}
.carouselX {
	-webkit-transform-style: preserve-3d;
	-moz-transform-style: preserve-3d;
	transform-style: preserve-3d;
}
.carouselImageX {
	opacity: 0;
	position: absolute;
	top: 0;
	width: 100%;
	margin: auto;
	padding: 0rem;
	z-index: 100;
	transition: transform .5s, opacity .5s, z-index .5s;
}
.carouselImageX.initial, .carouselImageX.active {
	opacity: 1;
	position: relative;
	z-index: 900;
}
.carouselImageX.prev, .carouselImageX.next {
	z-index: 800;
}
.carouselImageX.prev {
	transform: translateX(-100%); /* go to previous item */
}
.carouselImageX.next {
	transform: translateX(100%); /* go to next item */
}
.carousel__buttonX--prev, .carousel__buttonX--next {
	position: absolute;
	top: 48%;
	width: 3.5rem;
	height: 100%;
	background-color: transparent;
	transform: translateY(-50%);
	border-radius: 8%;
	cursor: pointer;
	z-index: 1001; /* sit on top of everything */
	border: none;
}
.carousel__buttonX--prev {
	left: 0;
}
.carousel__buttonX--next {
	right: 0;
}
.carousel__buttonX--prev::after, 
.carousel__buttonX--next::after {
	content: " ";
	position: absolute;
	width: 15px;
	height: 15px;
	top: 50%;
	left: 80%;
	border-right: 3px solid ##007bff;
	border-bottom: 3px solid ##007bff;
	transform: translate(-50%, -50%) rotate(135deg);
}
.carousel__buttonX--next::after {
	left: 20%;
	transform: translate(-50%, -50%) rotate(-45deg);
}
</style>
	<cfif not isDefined("underscore_collection_id") OR len(underscore_collection_id) EQ 0>
		<cfthrow message="No named group specified to show.">
	</cfif>
	<cfquery name="getNamedGroup" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getNamedGroup_result">
		SELECT underscore_collection_id, collection_name, description, underscore_agent_id, html_description,
			case 
				when underscore_agent_id is null then '[No Agent]'
			else 
				MCZBASE.get_agentnameoftype(underscore_agent_id, 'preferred')
			end
			as agent_name,
			mask_fg
		FROM underscore_collection
		WHERE underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
	</cfquery>
	<cfloop query="getNamedGroup">
		<cfif getNamedGroup.mask_fg EQ 1 AND (NOT isdefined("session.roles") OR listfindnocase(session.roles,"coldfusion_user") EQ 0)>
			<!--- mask_fg = 1 = Hidden --->
			<cflocation url="/errors/forbidden.cfm" addtoken="false">
		</cfif> 
		<main class="container-fluid py-3">
			<div class="row mx-0">
				<article class="w-100">
					<div class="col-12">
						<div class="row mx-0">
							<div class="col-12 border-dark mt-4">
								<h1 class="pb-2 w-100 border-bottom-black">#getNamedGroup.collection_name# 
									<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_specimens")>
										<div class="d-inline-block float-right">
											<a target="_blank" class="px-2 btn-xs btn-primary text-decoration-none" href="/grouping/NamedCollection.cfm?action=edit&underscore_collection_id=#underscore_collection_id#">Edit</a>
										</div>
									</cfif>
								</h1>
							</div>
						</div>
						<div class="row mx-0">
							<div class="col-12 px-3 mt-0">
								<!--- arbitrary html clob, could be empty, could be tens of thousands of characters plus rich media content --->
								<!--- WARNING: This section MUST go at the top, and must be allowed the full width of the page --->
								<cfif len(html_description)gt 0>
									<div class="pb-0">#getNamedGroup.html_description# </div>
								</cfif>
							</div>
						</div>	
						<div class="row mx-0">
							<cfquery name="specimens" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
								SELECT DISTINCT flat.guid, flat.scientific_name
								FROM
									underscore_relation 
									left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat 
										on underscore_relation.collection_object_id = flat.collection_object_id
								WHERE underscore_relation.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
									and flat.guid is not null
								ORDER BY flat.guid asc
							</cfquery>
							<cfquery name="specimenImgs" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
								SELECT DISTINCT media.media_uri
								FROM
									underscore_collection
									left join underscore_relation on underscore_collection.underscore_collection_id = underscore_relation.underscore_collection_id
									left join cataloged_item
										on underscore_relation.collection_object_id = cataloged_item.collection_object_id
									left join media_relations
										on media_relations.related_primary_key = underscore_relation.collection_object_id
									left join media on media_relations.media_id = media.media_id
								WHERE underscore_collection.underscore_collection_id =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
									AND media_relations.media_relationship = 'shows cataloged_item'
									AND media.media_type = 'image'
									AND (media.mime_type = 'image/jpeg' OR media.mime_type = 'image/png')
							</cfquery>
							<script type="text/javascript">
								var cellsrenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
									if (value > 1) {
										return '<a href="/guid/'+value+'"><span style="margin: 4px; float: ' + columnproperties.cellsalign + '; color: ##0000ff;">' + value + '</span></a>';
									}
									else {
										return '<a href="/guid/'+value+'"><span style="margin: 4px; float: ' + columnproperties.cellsalign + '; color: ##007bff;">' + value + '</span></a>';
									}
								}
								$(document).ready(function () {
									var source =
									{
										datatype: "json",
										datafields:
										[
											{ name: 'guid', type: 'string' },
											{ name: 'scientific_name', type: 'string' },
											{ name: 'verbatim_date', type: 'string' },
											{ name: 'higher_geog', type: 'string' },
											{ name: 'spec_locality', type: 'string' },
											{ name: 'othercatalognumbers', type: 'string' },
											{ name: 'full_taxon_name', type: 'string' }
										],
										url: '/grouping/component/search.cfc?method=getSpecimensInGroup&smallerfieldlist=true&underscore_collection_id=#underscore_collection_id#',
										timeout: 30000,  // units not specified, miliseconds? 
										loadError: function(jqXHR, textStatus, error) { 
											handleFail(jqXHR,textStatus,error,"retrieving cataloged items in named group");
										}
									};

									var dataAdapter = new $.jqx.dataAdapter(source);
									// initialize jqxGrid
									$("##jqxgrid").jqxGrid(
									{
										width: '100%',
										autoheight: 'true',
										source: dataAdapter,
										filterable: true,
										showfilterrow: true,
										sortable: true,
										pageable: true,
										editable: false,
										pagesize: '5',
										pagesizeoptions: ['5','50','100'],
										columnsresize: false,
										autoshowfiltericon: false,
										autoshowcolumnsmenubutton: false,
										altrows: true,
										showtoolbar: false,
										enabletooltips: true,
										pageable: true,
										columns: [
											{ text: 'GUID', datafield: 'guid', width:'180',cellsalign: 'left',cellsrenderer: cellsrenderer },
											{ text: 'Scientific Name', datafield: 'scientific_name', width:'250' },
											{ text: 'Date Collected', datafield: 'verbatim_date', width:'150'},
											{ text: 'Higher Geography', datafield: 'higher_geog', width:'350'},
											{ text: 'Locality', datafield: 'spec_locality',width:'350' },
											{ text: 'Other Catalog Numbers', datafield: 'othercatalognumbers',width:'350' },
											{ text: 'Taxonomy', datafield: 'full_taxon_name', width:'350'}
										]
									});
								});
							</script>
							<div class="col-12 mt-2">
								<h2 class="">Specimen Records <a href="/SpecimenResults.cfm?underscore_coll_id=#encodeForURL(underscore_collection_id)#" target="_blank">(#specimens.recordcount#)</a></h2>
								<div id="jqxgrid"></div>
							</div>
						</div>
						<!---end specimen grid--->						
					</div>		
								
					<div class="row mx-3">	
						<div class="col-12 col-md-6 float-left">
						<!--- obtain a random set of specimen images, limited to a small number --->
						<cfif specimenImgs.media_uri gt 0>
							<cfquery name="specimenImagesForCarousel" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="specimenImagesForCarousel_result">                                    		
								SELECT * FROM (
								SELECT DISTINCT media.media_uri, MCZBASE.get_media_descriptor(media.media_id) as alt, MCZBASE.get_medialabel(media.media_id,'width') as width, MCZBASE.get_media_credit(media.media_id) as credit
								FROM
									underscore_collection
									left join underscore_relation on underscore_collection.underscore_collection_id = underscore_relation.underscore_collection_id
									left join cataloged_item
										on underscore_relation.collection_object_id = cataloged_item.collection_object_id
									left join media_relations
										on media_relations.related_primary_key = underscore_relation.collection_object_id
									left join media on media_relations.media_id = media.media_id
								WHERE underscore_collection.underscore_collection_id =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
									AND media_relations.media_relationship = 'shows cataloged_item'
									AND media.media_type = 'image'
									AND (media.mime_type = 'image/jpeg' OR media.mime_type = 'image/png')
									ORDER BY DBMS_RANDOM.RANDOM
								) 
								WHERE   Rownum  <= 15
							</cfquery>
							<cfquery name="agentImagesForCarousel" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="agentImagesForCarousel_result">  
								SELECT * FROM (
									SELECT DISTINCT media_uri, preview_uri,media_type, media.media_id,
										MCZBASE.get_media_descriptor(media.media_id) as alt,
										MCZBASE.get_medialabel(media.media_id,'width') as width,
										MCZBASE.get_media_credit(media.media_id) as credit
									FROM
										underscore_collection
										left join underscore_relation on underscore_collection.underscore_collection_id = underscore_relation.underscore_collection_id
										left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat 
											on underscore_relation.collection_object_id = flat.collection_object_id
										left join collector on underscore_relation.collection_object_id = collector.collection_object_id
										left join media_relations on collector.agent_id = media_relations.related_primary_key
										left join media on media_relations.media_id = media.media_id
									WHERE underscore_collection.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
										AND flat.guid IS NOT NULL
										AND collector.collector_role = 'c'
										AND media_relations.media_relationship = 'shows agent'
										AND media.media_type = 'image'
										AND (media.mime_type = 'image/jpeg' OR media.mime_type = 'image/png')
										AND media.media_uri LIKE '%mczbase.mcz.harvard.edu%'
									ORDER BY DBMS_RANDOM.RANDOM
								) 
								WHERE Rownum <= 26
							</cfquery>
						
							<!---The encumbrance line was slowing it down too much--->
							<h2 class="mt-3">Images (shows 15)</h2>
							<p class="small">Specimen Images (#specimenImgs.recordcount#), Agent Images (#agentImagesForCarousel.recordcount#). Refresh page to show a different 15 images.</p>
							<div class="carousel-wrapperX">
								<cfoutput>
									<div class="carouselX">
										<div class="carouselImageX initial"><img class="w-100" src="#specimenImagesforCarousel['media_uri'][1]#"/><p>#specimenImagesforCarousel['alt'][1]#</p></div>									
										<div class="carouselImageX"><img class="w-100" src="#specimenImagesforCarousel['media_uri'][2]#"/><p>#specimenImagesforCarousel['alt'][2]#</p></div>
										<div class="carouselImageX"><img class="w-100" src="#specimenImagesforCarousel['media_uri'][3]#"/><p>#specimenImagesforCarousel['alt'][3]#</p></div>
										<div class="carouselImageX"><img class="w-100" src="#specimenImagesforCarousel['media_uri'][4]#"/><p>#specimenImagesforCarousel['alt'][4]#</p></div>
										<div class="carouselImageX"><img class="w-100" src="#specimenImagesforCarousel['media_uri'][5]#"/><p>#specimenImagesforCarousel['alt'][5]#</p></div>
										<div class="carouselImageX"><img class="w-100" src="#specimenImagesforCarousel['media_uri'][6]#"/><p>#specimenImagesforCarousel['alt'][6]#</p></div>
										<div class="carouselImageX"><img class="w-100" src="#specimenImagesforCarousel['media_uri'][7]#"/><p>#specimenImagesforCarousel['alt'][7]#</p></div>
										<div class="carouselImageX"><img class="w-100" src="#specimenImagesforCarousel['media_uri'][8]#"/><p>#specimenImagesforCarousel['alt'][8]#</p></div>
										<div class="carouselImageX"><img class="w-100" src="#specimenImagesforCarousel['media_uri'][9]#"/><p>#specimenImagesforCarousel['alt'][9]#</p></div>
										<div class="carouselImageX"><img class="w-100" src="#specimenImagesforCarousel['media_uri'][10]#"/><p>#specimenImagesforCarousel['alt'][10]#</p></div>
										<div class="carouselImageX"><img class="w-100" src="#specimenImagesforCarousel['media_uri'][11]#"/><p>#specimenImagesforCarousel['alt'][11]#</p></div>
										<div class="carouselImageX"><img class="w-100" src="#specimenImagesforCarousel['media_uri'][12]#"/><p>#specimenImagesforCarousel['alt'][12]#</p></div>
										<div class="carouselImageX"><img class="w-100" src="#specimenImagesforCarousel['media_uri'][13]#"/><p>#specimenImagesforCarousel['alt'][13]#</p></div>
										<div class="carouselImageX"><img class="w-100" src="#specimenImagesforCarousel['media_uri'][14]#"/><p>#specimenImagesforCarousel['alt'][14]#</p></div>
										<div class="carouselImageX"><img class="w-100" src="#specimenImagesforCarousel['media_uri'][15]#"/><p>#specimenImagesforCarousel['alt'][15]#</p></div>
										<div class="carouselImageX"><img class="w-100" src="#agentImagesforCarousel['media_uri'][16]#"/><p>#agentImagesforCarousel['alt'][16]#</p></div>
										<div class="carouselImageX"><img class="w-100" src="#agentImagesforCarousel['media_uri'][17]#"/><p>#agentImagesforCarousel['alt'][17]#</p></div>
										<div class="carouselImageX"><img class="w-100" src="#agentImagesforCarousel['media_uri'][18]#"/><p>#agentImagesforCarousel['alt'][18]#</p></div>
										<div class="carouselImageX"><img class="w-100" src="#agentImagesforCarousel['media_uri'][19]#"/><p>#agentImagesforCarousel['alt'][19]#</p></div>
										<div class="carouselImageX"><img class="w-100" src="#agentImagesforCarousel['media_uri'][20]#"/><p>#agentImagesforCarousel['alt'][20]#</p></div>
										<div class="carouselImageX"><img class="w-100" src="#agentImagesforCarousel['media_uri'][21]#"/><p>#agentImagesforCarousel['alt'][21]#</p></div>
										<div class="carouselImageX"><img class="w-100" src="#agentImagesforCarousel['media_uri'][22]#"/><p>#agentImagesforCarousel['alt'][22]#</p></div>
										<div class="carouselImageX"><img class="w-100" src="#agentImagesforCarousel['media_uri'][23]#"/><p>#agentImagesforCarousel['alt'][23]#</p></div>
										<div class="carouselImageX"><img class="w-100" src="#agentImagesforCarousel['media_uri'][24]#"/><p>#agentImagesforCarousel['alt'][24]#</p></div>
										<div class="carouselImageX"><img class="w-100" src="#agentImagesforCarousel['media_uri'][25]#"/><p>#agentImagesforCarousel['alt'][25]#</p></div>
									</div>
									<div class="carousel__buttonX--next"></div>
									<div class="carousel__buttonX--prev"></div>
								</cfoutput>
							</div>
							</cfif>
<div id="mapper" class="col-6">
    <script src="https://polyfill.io/v3/polyfill.min.js?features=default"></script>
    <!-- jsFiddle will insert css and js -->
<script>
// This example requires the Visualization library. Include the libraries=visualization
// parameter when you first load the API. For example:
// <script src="https://maps.googleapis.com/maps/api/js?key=AIzaSyB41DRUbKWJHPxaFjMAwdrzWzbVKartNGg&libraries=visualization">
let map, heatmap;

function initMap() {
  map = new google.maps.Map(document.getElementById("map"), {
    zoom: 13,
    center: { lat: 37.775, lng: -122.434 },
    mapTypeId: "satellite",
  });
  heatmap = new google.maps.visualization.HeatmapLayer({
    data: getPoints(),
    map: map,
  });
  document
    .getElementById("toggle-heatmap")
    .addEventListener("click", toggleHeatmap);
  document
    .getElementById("change-gradient")
    .addEventListener("click", changeGradient);
  document
    .getElementById("change-opacity")
    .addEventListener("click", changeOpacity);
  document
    .getElementById("change-radius")
    .addEventListener("click", changeRadius);
}

function toggleHeatmap() {
  heatmap.setMap(heatmap.getMap() ? null : map);
}

function changeGradient() {
  const gradient = [
    "rgba(0, 255, 255, 0)",
    "rgba(0, 255, 255, 1)",
    "rgba(0, 191, 255, 1)",
    "rgba(0, 127, 255, 1)",
    "rgba(0, 63, 255, 1)",
    "rgba(0, 0, 255, 1)",
    "rgba(0, 0, 223, 1)",
    "rgba(0, 0, 191, 1)",
    "rgba(0, 0, 159, 1)",
    "rgba(0, 0, 127, 1)",
    "rgba(63, 0, 91, 1)",
    "rgba(127, 0, 63, 1)",
    "rgba(191, 0, 31, 1)",
    "rgba(255, 0, 0, 1)",
  ];
  heatmap.set("gradient", heatmap.get("gradient") ? null : gradient);
}

function changeRadius() {
  heatmap.set("radius", heatmap.get("radius") ? null : 20);
}

function changeOpacity() {
  heatmap.set("opacity", heatmap.get("opacity") ? null : 0.2);
}

// Heatmap data: 500 Points
function getPoints() {
  return [
    new google.maps.LatLng(37.782551, -122.445368),
    new google.maps.LatLng(37.782745, -122.444586),
    new google.maps.LatLng(37.782842, -122.443688),
    new google.maps.LatLng(37.782919, -122.442815),
    new google.maps.LatLng(37.782992, -122.442112),
    new google.maps.LatLng(37.7831, -122.441461),
    new google.maps.LatLng(37.783206, -122.440829),
    new google.maps.LatLng(37.783273, -122.440324),
    new google.maps.LatLng(37.783316, -122.440023),
    new google.maps.LatLng(37.783357, -122.439794),
    new google.maps.LatLng(37.783371, -122.439687),
    new google.maps.LatLng(37.783368, -122.439666),
    new google.maps.LatLng(37.783383, -122.439594),
    new google.maps.LatLng(37.783508, -122.439525),
    new google.maps.LatLng(37.783842, -122.439591),
    new google.maps.LatLng(37.784147, -122.439668),
    new google.maps.LatLng(37.784206, -122.439686),
    new google.maps.LatLng(37.784386, -122.43979),
    new google.maps.LatLng(37.784701, -122.439902),
    new google.maps.LatLng(37.784965, -122.439938),
    new google.maps.LatLng(37.78501, -122.439947),
    new google.maps.LatLng(37.78536, -122.439952),
    new google.maps.LatLng(37.785715, -122.44003),
    new google.maps.LatLng(37.786117, -122.440119),
    new google.maps.LatLng(37.786564, -122.440209),
    new google.maps.LatLng(37.786905, -122.44027),
    new google.maps.LatLng(37.786956, -122.440279),
    new google.maps.LatLng(37.800224, -122.43352),
    new google.maps.LatLng(37.800155, -122.434101),
    new google.maps.LatLng(37.80016, -122.43443),
    new google.maps.LatLng(37.800378, -122.434527),
    new google.maps.LatLng(37.800738, -122.434598),
    new google.maps.LatLng(37.800938, -122.43465),
    new google.maps.LatLng(37.801024, -122.434889),
    new google.maps.LatLng(37.800955, -122.435392),
    new google.maps.LatLng(37.800886, -122.435959),
    new google.maps.LatLng(37.800811, -122.436275),
    new google.maps.LatLng(37.800788, -122.436299),
    new google.maps.LatLng(37.800719, -122.436302),
    new google.maps.LatLng(37.800702, -122.436298),
    new google.maps.LatLng(37.800661, -122.436273),
    new google.maps.LatLng(37.800395, -122.436172),
    new google.maps.LatLng(37.800228, -122.436116),
    new google.maps.LatLng(37.800169, -122.43613),
    new google.maps.LatLng(37.800066, -122.436167),
    new google.maps.LatLng(37.784345, -122.422922),
    new google.maps.LatLng(37.784389, -122.422926),
    new google.maps.LatLng(37.784437, -122.422924),
    new google.maps.LatLng(37.784746, -122.422818),
    new google.maps.LatLng(37.785436, -122.422959),
    new google.maps.LatLng(37.78612, -122.423112),
    new google.maps.LatLng(37.786433, -122.423029),
    new google.maps.LatLng(37.786631, -122.421213),
    new google.maps.LatLng(37.78666, -122.421033),
    new google.maps.LatLng(37.786801, -122.420141),
    new google.maps.LatLng(37.786823, -122.420034),
    new google.maps.LatLng(37.786831, -122.419916),
    new google.maps.LatLng(37.787034, -122.418208),
    new google.maps.LatLng(37.787056, -122.418034),
    new google.maps.LatLng(37.787169, -122.417145),
    new google.maps.LatLng(37.787217, -122.416715),
    new google.maps.LatLng(37.786144, -122.416403),
    new google.maps.LatLng(37.785292, -122.416257),
    new google.maps.LatLng(37.780666, -122.390374),
    new google.maps.LatLng(37.780501, -122.391281),
    new google.maps.LatLng(37.780148, -122.392052),
    new google.maps.LatLng(37.780173, -122.391148),
    new google.maps.LatLng(37.780693, -122.390592),
    new google.maps.LatLng(37.781261, -122.391142),
    new google.maps.LatLng(37.781808, -122.39173),
    new google.maps.LatLng(37.78234, -122.392341),
    new google.maps.LatLng(37.782812, -122.393022),
    new google.maps.LatLng(37.7833, -122.393672),
    new google.maps.LatLng(37.783809, -122.394275),
    new google.maps.LatLng(37.784246, -122.394979),
    new google.maps.LatLng(37.784791, -122.395958),
    new google.maps.LatLng(37.785675, -122.396746),
    new google.maps.LatLng(37.786262, -122.39578),
    new google.maps.LatLng(37.786776, -122.395093),
    new google.maps.LatLng(37.787282, -122.394426),
    new google.maps.LatLng(37.787783, -122.393767),
    new google.maps.LatLng(37.788343, -122.393184),
    new google.maps.LatLng(37.788895, -122.392506),
    new google.maps.LatLng(37.789371, -122.391701),
    new google.maps.LatLng(37.789722, -122.390952),
    new google.maps.LatLng(37.790315, -122.390305),
    new google.maps.LatLng(37.790738, -122.389616),
    new google.maps.LatLng(37.779448, -122.438702),
    new google.maps.LatLng(37.779023, -122.438585),
    new google.maps.LatLng(37.778542, -122.438492),
    new google.maps.LatLng(37.7781, -122.438411),
    new google.maps.LatLng(37.777986, -122.438376),
    new google.maps.LatLng(37.77768, -122.438313),
    new google.maps.LatLng(37.777316, -122.438273),
    new google.maps.LatLng(37.777135, -122.438254),
    new google.maps.LatLng(37.776987, -122.438303),
    new google.maps.LatLng(37.776946, -122.438404),
    new google.maps.LatLng(37.776944, -122.438467),
    new google.maps.LatLng(37.776892, -122.438459),
    new google.maps.LatLng(37.776842, -122.438442),
    new google.maps.LatLng(37.776822, -122.438391),
    new google.maps.LatLng(37.776814, -122.438412),
    new google.maps.LatLng(37.776787, -122.438628),
    new google.maps.LatLng(37.776729, -122.43865),
    new google.maps.LatLng(37.776759, -122.438677),
    new google.maps.LatLng(37.776772, -122.438498),
    new google.maps.LatLng(37.776787, -122.438389),
    new google.maps.LatLng(37.776848, -122.438283),
    new google.maps.LatLng(37.77687, -122.438239),
    new google.maps.LatLng(37.777015, -122.438198),
    new google.maps.LatLng(37.777333, -122.438256),
    new google.maps.LatLng(37.777595, -122.438308),
    new google.maps.LatLng(37.777797, -122.438344),
    new google.maps.LatLng(37.77816, -122.438442),
    new google.maps.LatLng(37.778414, -122.438508),
    new google.maps.LatLng(37.778445, -122.438516),
    new google.maps.LatLng(37.778503, -122.438529),
    new google.maps.LatLng(37.778607, -122.438549),
    new google.maps.LatLng(37.77867, -122.438644),
    new google.maps.LatLng(37.778847, -122.438706),
    new google.maps.LatLng(37.77924, -122.438744),
    new google.maps.LatLng(37.779738, -122.438822),
    new google.maps.LatLng(37.780201, -122.438882),
    new google.maps.LatLng(37.7804, -122.438905),
    new google.maps.LatLng(37.780501, -122.438921),
    new google.maps.LatLng(37.780892, -122.438986),
    new google.maps.LatLng(37.781446, -122.439087),
    new google.maps.LatLng(37.781985, -122.439199),
    new google.maps.LatLng(37.782239, -122.439249),
    new google.maps.LatLng(37.782286, -122.439266),
    new google.maps.LatLng(37.797847, -122.429388),
    new google.maps.LatLng(37.797874, -122.42918),
    new google.maps.LatLng(37.797885, -122.429069),
    new google.maps.LatLng(37.797887, -122.42905),
    new google.maps.LatLng(37.797933, -122.428954),
    new google.maps.LatLng(37.798242, -122.42899),
    new google.maps.LatLng(37.798617, -122.429075),
    new google.maps.LatLng(37.798719, -122.429092),
    new google.maps.LatLng(37.798944, -122.429145),
    new google.maps.LatLng(37.79932, -122.429251),
    new google.maps.LatLng(37.79959, -122.429309),
    new google.maps.LatLng(37.799677, -122.429324),
    new google.maps.LatLng(37.799966, -122.42936),
    new google.maps.LatLng(37.800288, -122.42943),
    new google.maps.LatLng(37.800443, -122.429461),
    new google.maps.LatLng(37.800465, -122.429474),
    new google.maps.LatLng(37.800644, -122.42954),
    new google.maps.LatLng(37.800948, -122.42962),
    new google.maps.LatLng(37.801242, -122.429685),
    new google.maps.LatLng(37.801375, -122.429702),
    new google.maps.LatLng(37.8014, -122.429703),
    new google.maps.LatLng(37.801453, -122.429707),
    new google.maps.LatLng(37.801473, -122.429709),
    new google.maps.LatLng(37.801532, -122.429707),
    new google.maps.LatLng(37.801852, -122.429729),
    new google.maps.LatLng(37.802173, -122.429789),
    new google.maps.LatLng(37.802459, -122.429847),
    new google.maps.LatLng(37.802554, -122.429825),
    new google.maps.LatLng(37.802647, -122.429549),
    new google.maps.LatLng(37.802693, -122.429179),
    new google.maps.LatLng(37.802729, -122.428751),
    new google.maps.LatLng(37.766104, -122.409291),
    new google.maps.LatLng(37.766103, -122.409268),
    new google.maps.LatLng(37.766138, -122.409229),
    new google.maps.LatLng(37.766183, -122.409231),
    new google.maps.LatLng(37.766153, -122.409276),
    new google.maps.LatLng(37.766005, -122.409365),
    new google.maps.LatLng(37.765897, -122.40957),
    new google.maps.LatLng(37.765767, -122.409739),
    new google.maps.LatLng(37.765693, -122.410389),
    new google.maps.LatLng(37.765615, -122.411201),
    new google.maps.LatLng(37.765533, -122.412121),
    new google.maps.LatLng(37.765467, -122.412939),
    new google.maps.LatLng(37.765444, -122.414821),
    new google.maps.LatLng(37.765444, -122.414964),
    new google.maps.LatLng(37.765318, -122.415424),
    new google.maps.LatLng(37.763961, -122.415296),
    new google.maps.LatLng(37.763115, -122.415196),
    new google.maps.LatLng(37.762967, -122.415183),
    new google.maps.LatLng(37.762278, -122.415127),
    new google.maps.LatLng(37.761675, -122.415055),
    new google.maps.LatLng(37.760932, -122.414988),
    new google.maps.LatLng(37.759337, -122.414862),
    new google.maps.LatLng(37.773187, -122.421922),
    new google.maps.LatLng(37.773043, -122.422118),
    new google.maps.LatLng(37.773007, -122.422165),
    new google.maps.LatLng(37.772979, -122.422219),
    new google.maps.LatLng(37.772865, -122.422394),
    new google.maps.LatLng(37.772779, -122.422503),
    new google.maps.LatLng(37.772676, -122.422701),
    new google.maps.LatLng(37.772606, -122.422806),
    new google.maps.LatLng(37.772566, -122.42284),
    new google.maps.LatLng(37.772508, -122.422852),
    new google.maps.LatLng(37.772387, -122.423011),
    new google.maps.LatLng(37.772099, -122.423328),
    new google.maps.LatLng(37.771704, -122.423783),
    new google.maps.LatLng(37.771481, -122.424081),
    new google.maps.LatLng(37.7714, -122.424179),

    new google.maps.LatLng(37.771352, -122.42422),
    new google.maps.LatLng(37.771248, -122.424327),
    new google.maps.LatLng(37.770904, -122.424781),
    new google.maps.LatLng(37.77052, -122.425283),
    new google.maps.LatLng(37.770337, -122.425553),
    new google.maps.LatLng(37.770128, -122.425832),
    new google.maps.LatLng(37.769756, -122.426331),
    new google.maps.LatLng(37.7693, -122.426902),
    new google.maps.LatLng(37.769132, -122.427065),
    new google.maps.LatLng(37.769092, -122.427103),
    new google.maps.LatLng(37.768979, -122.427172),
    new google.maps.LatLng(37.768595, -122.427634),
    new google.maps.LatLng(37.768372, -122.427913),
    new google.maps.LatLng(37.768337, -122.427961),
    new google.maps.LatLng(37.768244, -122.428138),
    new google.maps.LatLng(37.767942, -122.428581),
    new google.maps.LatLng(37.767482, -122.429094),
    new google.maps.LatLng(37.767031, -122.429606),
    new google.maps.LatLng(37.766732, -122.429986),
    new google.maps.LatLng(37.76668, -122.430058),
    new google.maps.LatLng(37.766633, -122.430109),
    new google.maps.LatLng(37.76658, -122.430211),
    new google.maps.LatLng(37.766367, -122.430594),
    new google.maps.LatLng(37.76591, -122.431137),
    new google.maps.LatLng(37.765353, -122.431806),
    new google.maps.LatLng(37.764962, -122.432298),
    new google.maps.LatLng(37.764868, -122.432486),
    new google.maps.LatLng(37.764518, -122.432913),
    new google.maps.LatLng(37.763435, -122.434173),
    new google.maps.LatLng(37.762847, -122.434953),
    new google.maps.LatLng(37.762291, -122.435935),
    new google.maps.LatLng(37.762224, -122.436074),
    new google.maps.LatLng(37.761957, -122.436892),
    new google.maps.LatLng(37.761652, -122.438886),
    new google.maps.LatLng(37.761284, -122.439955),
    new google.maps.LatLng(37.76121, -122.440068),
    new google.maps.LatLng(37.761064, -122.44072),
    new google.maps.LatLng(37.76104, -122.441411),
    new google.maps.LatLng(37.761048, -122.442324),
    new google.maps.LatLng(37.760851, -122.443118),
    new google.maps.LatLng(37.759977, -122.444591),
    new google.maps.LatLng(37.759913, -122.444698),
    new google.maps.LatLng(37.759623, -122.445065),
    new google.maps.LatLng(37.758902, -122.445158),
    new google.maps.LatLng(37.758428, -122.44457),
    new google.maps.LatLng(37.757687, -122.44334),
    new google.maps.LatLng(37.757583, -122.44324),
    new google.maps.LatLng(37.757019, -122.442787),
    new google.maps.LatLng(37.756603, -122.442322),
    new google.maps.LatLng(37.75638, -122.441602),
    new google.maps.LatLng(37.75579, -122.441382),
    new google.maps.LatLng(37.754493, -122.442133),
    new google.maps.LatLng(37.754361, -122.442206),
    new google.maps.LatLng(37.753719, -122.44265),
    new google.maps.LatLng(37.753096, -122.442915),
    new google.maps.LatLng(37.751617, -122.443211),
    new google.maps.LatLng(37.751496, -122.443246),
    new google.maps.LatLng(37.750733, -122.443428),
    new google.maps.LatLng(37.750126, -122.443536),
    new google.maps.LatLng(37.750103, -122.443784),
    new google.maps.LatLng(37.75039, -122.44401),
    new google.maps.LatLng(37.750448, -122.444013),
    new google.maps.LatLng(37.750536, -122.44404),
    new google.maps.LatLng(37.750493, -122.444141),
    new google.maps.LatLng(37.790859, -122.402808),
    new google.maps.LatLng(37.790864, -122.402768),
    new google.maps.LatLng(37.790995, -122.402539),
    new google.maps.LatLng(37.791148, -122.402172),
    new google.maps.LatLng(37.791385, -122.401312),
    new google.maps.LatLng(37.791405, -122.400776),
    new google.maps.LatLng(37.791288, -122.400528),
    new google.maps.LatLng(37.791113, -122.400441),
    new google.maps.LatLng(37.791027, -122.400395),
    new google.maps.LatLng(37.791094, -122.400311),
    new google.maps.LatLng(37.791211, -122.400183),
    new google.maps.LatLng(37.79106, -122.399334),
    new google.maps.LatLng(37.790538, -122.398718),
    new google.maps.LatLng(37.790095, -122.398086),
    new google.maps.LatLng(37.789644, -122.39736),
    new google.maps.LatLng(37.789254, -122.396844),
    new google.maps.LatLng(37.788855, -122.396397),
    new google.maps.LatLng(37.788483, -122.395963),
    new google.maps.LatLng(37.788015, -122.395365),
    new google.maps.LatLng(37.787558, -122.394735),
    new google.maps.LatLng(37.787472, -122.394323),
    new google.maps.LatLng(37.78763, -122.394025),
    new google.maps.LatLng(37.787767, -122.393987),
    new google.maps.LatLng(37.787486, -122.394452),
    new google.maps.LatLng(37.786977, -122.395043),
    new google.maps.LatLng(37.786583, -122.395552),
    new google.maps.LatLng(37.78654, -122.39561),
    new google.maps.LatLng(37.786516, -122.395659),
    new google.maps.LatLng(37.786378, -122.395707),
    new google.maps.LatLng(37.786044, -122.395362),
    new google.maps.LatLng(37.785598, -122.394715),
    new google.maps.LatLng(37.785321, -122.394361),
    new google.maps.LatLng(37.785207, -122.394236),
    new google.maps.LatLng(37.785751, -122.394062),
    new google.maps.LatLng(37.785996, -122.393881),
    new google.maps.LatLng(37.786092, -122.39383),
    new google.maps.LatLng(37.785998, -122.393899),
    new google.maps.LatLng(37.785114, -122.394365),
    new google.maps.LatLng(37.785022, -122.394441),
    new google.maps.LatLng(37.784823, -122.394635),
    new google.maps.LatLng(37.784719, -122.394629),
    new google.maps.LatLng(37.785069, -122.394176),
    new google.maps.LatLng(37.7855, -122.39365),
    new google.maps.LatLng(37.78577, -122.393291),
    new google.maps.LatLng(37.785839, -122.393159),
    new google.maps.LatLng(37.782651, -122.400628),
    new google.maps.LatLng(37.782616, -122.400599),
    new google.maps.LatLng(37.782702, -122.40047),
    new google.maps.LatLng(37.782915, -122.400192),
    new google.maps.LatLng(37.783137, -122.399887),
    new google.maps.LatLng(37.783414, -122.399519),
    new google.maps.LatLng(37.783629, -122.399237),
    new google.maps.LatLng(37.783688, -122.399157),
    new google.maps.LatLng(37.783716, -122.399106),
    new google.maps.LatLng(37.783798, -122.399072),
    new google.maps.LatLng(37.783997, -122.399186),
    new google.maps.LatLng(37.784271, -122.399538),
    new google.maps.LatLng(37.784577, -122.399948),
    new google.maps.LatLng(37.784828, -122.40026),
    new google.maps.LatLng(37.784999, -122.400477),
    new google.maps.LatLng(37.785113, -122.400651),
    new google.maps.LatLng(37.785155, -122.400703),
    new google.maps.LatLng(37.785192, -122.400749),
    new google.maps.LatLng(37.785278, -122.400839),
    new google.maps.LatLng(37.785387, -122.400857),
    new google.maps.LatLng(37.785478, -122.40089),
    new google.maps.LatLng(37.785526, -122.401022),
    new google.maps.LatLng(37.785598, -122.401148),
    new google.maps.LatLng(37.785631, -122.401202),
    new google.maps.LatLng(37.78566, -122.401267),
    new google.maps.LatLng(37.803986, -122.426035),
    new google.maps.LatLng(37.804102, -122.425089),
    new google.maps.LatLng(37.804211, -122.424156),
    new google.maps.LatLng(37.803861, -122.423385),
    new google.maps.LatLng(37.803151, -122.423214),
    new google.maps.LatLng(37.802439, -122.423077),
    new google.maps.LatLng(37.80174, -122.422905),
    new google.maps.LatLng(37.801069, -122.422785),
    new google.maps.LatLng(37.800345, -122.422649),
    new google.maps.LatLng(37.799633, -122.422603),
    new google.maps.LatLng(37.79975, -122.4217),
    new google.maps.LatLng(37.799885, -122.420854),
    new google.maps.LatLng(37.799209, -122.420607),
    new google.maps.LatLng(37.795656, -122.400395),
    new google.maps.LatLng(37.795203, -122.400304),
    new google.maps.LatLng(37.778738, -122.415584),
    new google.maps.LatLng(37.778812, -122.415189),
    new google.maps.LatLng(37.778824, -122.415092),
    new google.maps.LatLng(37.778833, -122.414932),
    new google.maps.LatLng(37.778834, -122.414898),
    new google.maps.LatLng(37.77874, -122.414757),
    new google.maps.LatLng(37.778501, -122.414433),
    new google.maps.LatLng(37.778182, -122.414026),
    new google.maps.LatLng(37.777851, -122.413623),
    new google.maps.LatLng(37.777486, -122.413166),
    new google.maps.LatLng(37.777109, -122.412674),
    new google.maps.LatLng(37.776743, -122.412186),
    new google.maps.LatLng(37.77644, -122.4118),
    new google.maps.LatLng(37.776295, -122.411614),
    new google.maps.LatLng(37.776158, -122.41144),
    new google.maps.LatLng(37.775806, -122.410997),
    new google.maps.LatLng(37.775422, -122.410484),
    new google.maps.LatLng(37.775126, -122.410087),
    new google.maps.LatLng(37.775012, -122.409854),
    new google.maps.LatLng(37.775164, -122.409573),
    new google.maps.LatLng(37.775498, -122.40918),
    new google.maps.LatLng(37.775868, -122.40873),
    new google.maps.LatLng(37.776256, -122.40824),
    new google.maps.LatLng(37.776519, -122.407928),
    new google.maps.LatLng(37.776539, -122.407904),
    new google.maps.LatLng(37.776595, -122.407854),
    new google.maps.LatLng(37.776853, -122.407547),
    new google.maps.LatLng(37.777234, -122.407087),
    new google.maps.LatLng(37.777644, -122.406558),
    new google.maps.LatLng(37.778066, -122.406017),
    new google.maps.LatLng(37.778468, -122.405499),
    new google.maps.LatLng(37.778866, -122.404995),
    new google.maps.LatLng(37.779295, -122.404455),
    new google.maps.LatLng(37.779695, -122.40395),
    new google.maps.LatLng(37.779982, -122.403584),
    new google.maps.LatLng(37.780295, -122.403223),
    new google.maps.LatLng(37.780664, -122.402766),
    new google.maps.LatLng(37.781043, -122.402288),
    new google.maps.LatLng(37.781399, -122.401823),
    new google.maps.LatLng(37.781727, -122.401407),
    new google.maps.LatLng(37.781853, -122.401247),
    new google.maps.LatLng(37.781894, -122.401195),
    new google.maps.LatLng(37.782076, -122.400977),
    new google.maps.LatLng(37.782338, -122.400603),
    new google.maps.LatLng(37.782666, -122.400133),
    new google.maps.LatLng(37.783048, -122.399634),
    new google.maps.LatLng(37.78345, -122.399198),
    new google.maps.LatLng(37.783791, -122.398998),
    new google.maps.LatLng(37.784177, -122.398959),
    new google.maps.LatLng(37.784388, -122.398971),
    new google.maps.LatLng(37.784404, -122.399128),
    new google.maps.LatLng(37.784586, -122.399524),
    new google.maps.LatLng(37.784835, -122.399927),
    new google.maps.LatLng(37.785116, -122.400307),
    new google.maps.LatLng(37.785282, -122.400539),
    new google.maps.LatLng(37.785346, -122.400692),
    new google.maps.LatLng(37.765769, -122.407201),
    new google.maps.LatLng(37.76579, -122.407414),
    new google.maps.LatLng(37.765802, -122.407755),
    new google.maps.LatLng(37.765791, -122.408219),
    new google.maps.LatLng(37.765763, -122.408759),
    new google.maps.LatLng(37.765726, -122.409348),
    new google.maps.LatLng(37.765716, -122.409882),
    new google.maps.LatLng(37.765708, -122.410202),
    new google.maps.LatLng(37.765705, -122.410253),
    new google.maps.LatLng(37.765707, -122.410369),
    new google.maps.LatLng(37.765692, -122.41072),
    new google.maps.LatLng(37.765699, -122.411215),
    new google.maps.LatLng(37.765687, -122.411789),
    new google.maps.LatLng(37.765666, -122.412373),
    new google.maps.LatLng(37.765598, -122.412883),
    new google.maps.LatLng(37.765543, -122.413039),
    new google.maps.LatLng(37.765532, -122.413125),
    new google.maps.LatLng(37.7655, -122.413553),
    new google.maps.LatLng(37.765448, -122.414053),
    new google.maps.LatLng(37.765388, -122.414645),
    new google.maps.LatLng(37.765323, -122.41525),
    new google.maps.LatLng(37.765303, -122.415847),
    new google.maps.LatLng(37.765251, -122.416439),
    new google.maps.LatLng(37.765204, -122.41702),
    new google.maps.LatLng(37.765172, -122.417556),
    new google.maps.LatLng(37.765164, -122.418075),
    new google.maps.LatLng(37.765153, -122.418618),
    new google.maps.LatLng(37.765136, -122.419112),
    new google.maps.LatLng(37.765129, -122.419378),
    new google.maps.LatLng(37.765119, -122.419481),
    new google.maps.LatLng(37.7651, -122.419852),
    new google.maps.LatLng(37.765083, -122.420349),
    new google.maps.LatLng(37.765045, -122.42093),
    new google.maps.LatLng(37.764992, -122.421481),
    new google.maps.LatLng(37.76498, -122.421695),
    new google.maps.LatLng(37.764993, -122.421843),
    new google.maps.LatLng(37.764986, -122.422255),
    new google.maps.LatLng(37.764975, -122.422823),
    new google.maps.LatLng(37.764939, -122.423411),
    new google.maps.LatLng(37.764902, -122.424014),
    new google.maps.LatLng(37.764853, -122.424576),
    new google.maps.LatLng(37.764826, -122.424922),
    new google.maps.LatLng(37.764796, -122.425375),
    new google.maps.LatLng(37.764782, -122.425869),
    new google.maps.LatLng(37.764768, -122.426089),
    new google.maps.LatLng(37.764766, -122.426117),
    new google.maps.LatLng(37.764723, -122.426276),
    new google.maps.LatLng(37.764681, -122.426649),
    new google.maps.LatLng(37.782012, -122.4042),
    new google.maps.LatLng(37.781574, -122.404911),
    new google.maps.LatLng(37.781055, -122.405597),
    new google.maps.LatLng(37.780479, -122.406341),
    new google.maps.LatLng(37.779996, -122.406939),
    new google.maps.LatLng(37.779459, -122.407613),
    new google.maps.LatLng(37.778953, -122.408228),
    new google.maps.LatLng(37.778409, -122.408839),
    new google.maps.LatLng(37.777842, -122.409501),
    new google.maps.LatLng(37.777334, -122.410181),
    new google.maps.LatLng(37.776809, -122.410836),
    new google.maps.LatLng(37.77624, -122.411514),
    new google.maps.LatLng(37.775725, -122.412145),
    new google.maps.LatLng(37.77519, -122.412805),
    new google.maps.LatLng(37.774672, -122.413464),
    new google.maps.LatLng(37.774084, -122.414186),
    new google.maps.LatLng(37.773533, -122.413636),
    new google.maps.LatLng(37.773021, -122.413009),
    new google.maps.LatLng(37.772501, -122.412371),
    new google.maps.LatLng(37.771964, -122.411681),
    new google.maps.LatLng(37.771479, -122.411078),
    new google.maps.LatLng(37.770992, -122.410477),
    new google.maps.LatLng(37.770467, -122.409801),
    new google.maps.LatLng(37.77009, -122.408904),
    new google.maps.LatLng(37.769657, -122.408103),
    new google.maps.LatLng(37.769132, -122.407276),
    new google.maps.LatLng(37.768564, -122.406469),
    new google.maps.LatLng(37.76798, -122.405745),
    new google.maps.LatLng(37.76738, -122.405299),
    new google.maps.LatLng(37.766604, -122.405297),
    new google.maps.LatLng(37.765838, -122.4052),
    new google.maps.LatLng(37.765139, -122.405139),
    new google.maps.LatLng(37.764457, -122.405094),
    new google.maps.LatLng(37.763716, -122.405142),
    new google.maps.LatLng(37.762932, -122.405398),
    new google.maps.LatLng(37.762126, -122.405813),
    new google.maps.LatLng(37.761344, -122.406215),
    new google.maps.LatLng(37.760556, -122.406495),
    new google.maps.LatLng(37.759732, -122.406484),
    new google.maps.LatLng(37.75891, -122.406228),
    new google.maps.LatLng(37.758182, -122.405695),
    new google.maps.LatLng(37.757676, -122.405118),
    new google.maps.LatLng(37.757039, -122.404346),
    new google.maps.LatLng(37.756335, -122.403719),
    new google.maps.LatLng(37.755503, -122.403406),
    new google.maps.LatLng(37.754665, -122.403242),
    new google.maps.LatLng(37.753837, -122.403172),
    new google.maps.LatLng(37.752986, -122.403112),
    new google.maps.LatLng(37.751266, -122.403355),
  ];
}	
</script>
<style>
/* Always set the map height explicitly to define the size of the div
       * element that contains the map. */
##map {
  height: 100%;
}

/* Optional: Makes the sample page fill the window. */

##floating-panel {
  position: absolute;
  top: 10px;
  left: 25%;
  z-index: 5;
  background-color: ##fff;
  padding: 5px;
  border: 1px solid ##999;
  text-align: center;
  font-family: "Roboto", "sans-serif";
  line-height: 30px;
  padding-left: 10px;
}

##floating-panel {
  background-color: ##fff;
  border: 1px solid ##999;
  left: 25%;
  padding: 5px;
  position: absolute;
  top: 10px;
  z-index: 5;
}
</style>
    <div id="floating-panel">
      <button id="toggle-heatmap">Toggle Heatmap</button>
      <button id="change-gradient">Change gradient</button>
      <button id="change-radius">Change radius</button>
      <button id="change-opacity">Change opacity</button>
    </div>
    <div id="map"></div>

    <!-- Async script executes immediately and must be after any DOM elements used in callback. -->
    <script src="https://maps.googleapis.com/maps/api/js?key=AIzaSyC9WEpUv8c2Hu59LE_nwfGg-YhZUkEu4IY&libraries=&libraries=visualization"
      async></script>
</div><!---end map--->
								
								</div>

						<div class="col mt-4 float-left">
							<!--- This is either a full width or half width col, depending on presence/absence of has any kind of image col --->
							<div class="my-2 py-3 border-bottom-black">
								<cfif len(getNamedGroup.description) GT 0 >
									<h2 class="mt-3">Overview</h2>
									<p>#getNamedGroup.description#</p>
								</cfif>
							</div>
							<div class="row pb-4">
								<cfif len(underscore_agent_id) GT 0 >
									<cfif getNamedGroup.agent_name NEQ "[No Agent]" >
										<div class="col-12 pt-3">
											<h3>Associated Agent</h2>
											<p class="rounded-0 border-top border-dark">
												<a class="h4 px-2 pt-3 d-block" href="/agents/Agent.cfm?agent_id=#underscore_agent_id#">#getNamedGroup.agent_name#</a>
											</p>
										</div>
									</cfif>
								</cfif>
								<cfquery name="taxonQuery" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="taxonQuery_result">
									SELECT DISTINCT flat.phylclass as taxon, flat.phylclass as taxonlink, 'phylclass' as rank
									FROM
										underscore_relation 
										left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat 
											on underscore_relation.collection_object_id = flat.collection_object_id
									WHERE underscore_relation.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
										and flat.PHYLCLASS is not null
									ORDER BY flat.phylclass asc
								</cfquery>
								<cfif taxonQuery.recordcount GT 0 AND taxonQuery.recordcount LT 5 >
									<!--- try expanding to orders instead if very few classes --->
									<cfquery name="taxonQuery" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="taxonQuery_result">
										SELECT DISTINCT flat.phylclass || ': ' || flat.phylorder as taxon, flat.phylorder as taxonlink, 'phylorder' as rank,
											flat.phylclass, flat.phylorder
										FROM
											underscore_relation 
											left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat 
												on underscore_relation.collection_object_id = flat.collection_object_id
										WHERE underscore_relation.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
											and flat.PHYLCLASS is not null and flat.phylorder is not null
										ORDER BY flat.phylclass asc, flat.phylorder asc
									</cfquery>
								</cfif>
								<cfif taxonQuery.recordcount GT 0 AND taxonQuery.recordcount LT 5 >
									<!--- try expanding to families instead if very few orders --->
									<cfquery name="taxonQuery" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="taxonQuery_result">
										SELECT DISTINCT flat.phylorder || ': ' || flat.family as taxon, flat.family as taxonlink, 'family' as rank,
											flat.phylorder, flat.family
										FROM
											underscore_relation 
											left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat 
												on underscore_relation.collection_object_id = flat.collection_object_id
										WHERE underscore_relation.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
											and flat.PHYLCLASS is not null and flat.family is not null
										ORDER BY flat.phylorder asc, flat.family asc
									</cfquery>
								</cfif>
								<cfif taxonQuery.recordcount GT 0>
									<div class="col-12">
										<h3>Taxa</h3>
										<ul class="list-group py-3 list-group-horizontal flex-wrap rounded-0 border-top border-dark">
											<cfloop query="taxonQuery">
												<li class="list-group-item col-12 col-md-3 float-left">
													<a class="h4" href="/SpecimenResults.cfm?#encodeForUrl(taxonQuery.rank)#=#encodeForUrl(taxonQuery.taxonlink)#&underscore_coll_id=#getNamedGroup.underscore_collection_id#">#taxonQuery.taxon#</a>
												</li>
											</cfloop>
										</ul>
									</div>
								</cfif>
								<cfquery name="marine" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="marine_result">
									SELECT DISTINCT flat.continent_ocean as ocean
									FROM
										underscore_relation 
										left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat 
											on underscore_relation.collection_object_id = flat.collection_object_id
									WHERE underscore_relation.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
										and flat.continent_ocean like '%Ocean%'
									ORDER BY flat.continent_ocean asc
								</cfquery>
								<cfif marine.recordcount GT 0>
									<div class="col-12">
										<h3 class="px-2">Oceans</h3>
										<ul class="list-group py-3 list-group-horizontal flex-wrap border-top rounded-0 border-dark">
											<cfloop query="marine">
												<li class="list-group-item col-12 col-md-3 float-left">
													<a class="h4" href="/SpecimenResults.cfm?continent_ocean=#encodeForURL(marine.ocean)#&underscore_coll_id=#getNamedGroup.underscore_collection_id#">#marine.ocean#</a>
												</li>
											</cfloop>
										</ul>
									</div>
								</cfif>
								<cfquery name="geogQuery" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="geogQuery_result">
									SELECT DISTINCT flat.country as geog, flat.country as geoglink, 'Country' as rank
									FROM
										underscore_relation 
										left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat 
											on underscore_relation.collection_object_id = flat.collection_object_id
									WHERE underscore_relation.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
										and flat.country is not null
									ORDER BY flat.country asc
								</cfquery>
								<cfif geogQuery.recordcount GT 0 AND geogQuery.recordcount LT 5 >
									<!--- try expanding to families instead if very few orders --->
									<cfquery name="geogQuery" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="geogQuery_result">
										SELECT DISTINCT flat.country || ': ' || flat.state_prov as geog, flat.state_prov as geoglink, 'state_prov' as rank,
											flat.country, flat.state_prov
										FROM
											underscore_relation 
											left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat 
												on underscore_relation.collection_object_id = flat.collection_object_id
										WHERE underscore_relation.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
											and flat.state_prov is not null
										ORDER BY flat.country asc, flat.state_prov asc
									</cfquery>
								</cfif>
								<cfif geogQuery.recordcount GT 0>
									<div class="col-12">
										<h3>Geography</h3>
										<ul class="list-group py-3 border-top list-group-horizontal flex-wrap rounded-0 border-dark">
											<cfloop query="geogQuery">
												<li class="list-group-item col-12 col-md-3 float-left">
													<a class="h4" href="/SpecimenResults.cfm?#encodeForUrl(geogQuery.rank)#=#encodeForUrl(geogQuery.geoglink)#&underscore_coll_id=#getNamedGroup.underscore_collection_id#">#geogQuery.geog#</a>
												</li>
											</cfloop>
										</ul>
									</div>
								</cfif>

								<cfquery name="islandsQuery" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="islandsQuery_result">
									SELECT DISTINCT flat.continent_ocean, flat.island as island
									FROM
										underscore_relation 
										left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat 
											on underscore_relation.collection_object_id = flat.collection_object_id
									WHERE underscore_relation.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
										and flat.island is not null
									ORDER BY flat.continent_ocean, flat.island asc
								</cfquery>
								<cfif islandsQuery.recordcount GT 0>
									<div class="col-12">
										<h3>Islands</h3>
										<ul class="list-group py-3 border-top list-group-horizontal flex-wrap rounded-0 border-dark">
											<cfloop query="islandsQuery">
												<li class="list-group-item col-12 col-md-3 float-left">
													<a class="h4" href="/SpecimenResults.cfm?island=#encodeForUrl(islandsQuery.island)#&underscore_coll_id=#getNamedGroup.underscore_collection_id#">
														#continent_ocean#:
														#islandsQuery.island#
													</a>
												</li>
											</cfloop>
										</ul>
									</div>
								</cfif>

								<cfquery name="collectors" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="collectors_result">
									SELECT DISTINCT preferred_agent_name.agent_name, collector.agent_id, person.last_name
									FROM
										underscore_relation 
										left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat 
											on underscore_relation.collection_object_id = flat.collection_object_id
										left join collector on underscore_relation.collection_object_id = collector.collection_object_id
										left join preferred_agent_name on collector.agent_id = preferred_agent_name.agent_id
										left join person on preferred_agent_name.agent_id = person.person_id
									WHERE underscore_relation.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
										and flat.collectors is not null
										and collector.collector_role = 'c'
									ORDER BY person.last_name, preferred_agent_name.agent_name asc
								</cfquery>
								<cfif collectors.recordcount GT 0>
									<div class="col-12">
										<h3>Collectors</h3>
										<ul class="list-group py-3 border-top list-group-horizontal flex-wrap rounded-0 border-dark">
											<cfloop query="collectors">
												<li class="list-group-item col-12 col-md-3 float-left">
													<a class="h4" href="/agents/Agent.cfm?agent_id=#collectors.agent_id#" target="_blank">#collectors.agent_name#</a>
												</li>
											</cfloop>
										</ul>
									</div>
								</cfif>
							</div>
						</div>
					</div><!--- end rowEverythihngElse--->
				</article>
			</div>
		</main>
	</cfloop>
<script>
!(function (d){
// Variables to target our base class,  get carousel items, count how many carousel items there are, set the slide to 0 (which is the number that tells us the frame we're on), and set motion to true which disables interactivity.
var itemClassName = "carouselImageX";
	items = d.getElementsByClassName(itemClassName),
	totalItems = items.length,
	slide = 0,
	moving = true; 

// To initialise the carousel we'll want to update the DOM with our own classes
function setInitialClasses() {

	// Target the last, initial, and next items and give them the relevant class.
	// This assumes there are three or more items.
	items[totalItems - 1].classList.add("prev");
	items[0].classList.add("active");
	items[1].classList.add("next");
}

// Set click events to navigation buttons

function setEventListeners() {
	var next = d.getElementsByClassName('carousel__buttonX--next')[0],
		prev = d.getElementsByClassName('carousel__buttonX--prev')[0];

	next.addEventListener('click', moveNext);
	prev.addEventListener('click', movePrev);
}

// Disable interaction by setting 'moving' to true for the same duration as our transition (0.5s = 500ms)
function disableInteraction() {
	moving = true;

	setTimeout(function(){
		moving = false
	}, 500);
}

function moveCarouselTo(slide) {

	// Check if carousel is moving, if not, allow interaction
	if(!moving) {

	// temporarily disable interactivity
	disableInteraction();

	// Preemptively set variables for the current next and previous slide, as well as the potential next or previous slide.
	var newPrevious = slide - 1,
		newNext = slide + 1,
		oldPrevious = slide - 2,
		oldNext = slide + 2;

	// Test if carousel has more than three items
	if ((totalItems - 1) > 3) {

		// Checks if the new potential slide is out of bounds and sets slide numbers
		if (newPrevious <= 0) {
			oldPrevious = (totalItems - 1);
		} else if (newNext >= (totalItems - 1)){
			oldNext = 0;
		}

		// Check if current slide is at the beginning or end and sets slide numbers
		if (slide === 0) {
			newPrevious = (totalItems - 1);
			oldPrevious = (totalItems - 2);
			oldNext = (slide + 1);
		} else if (slide === (totalItems -1)) {
			newPrevious = (slide - 1);
			newNext = 0;
			oldNext = 1;
		}

		// Now we've worked out where we are and where we're going, by adding and removing classes, we'll be triggering the carousel's transitions.

		// Based on the current slide, reset to default classes.
		items[oldPrevious].className = itemClassName;
		items[oldNext].className = itemClassName;

		// Add the new classes
		items[newPrevious].className = itemClassName + " prev";
		items[slide].className = itemClassName + " active";
		items[newNext].className = itemClassName + " next";
		}
	}
}

// Next navigation handler
function moveNext() {

	// Check if moving
	if (!moving) {

	// If it's the last slide, reset to 0, else +1
	if (slide === (totalItems - 1)) {
		slide = 0;
	} else {
		slide++;
	}

	// Move carousel to updated slide
		moveCarouselTo(slide);
	}
}

// Previous navigation handler
function movePrev() {

	// Check if moving
	if (!moving) {

	// If it's the first slide, set as the last slide, else -1
	if (slide === 0) {
		slide = (totalItems - 1);
	} else {
		slide--;
	}

	// Move carousel to updated slide
		moveCarouselTo(slide);
	}
}

// Initialise carousel
function initCarousel() {
	setInitialClasses();
	setEventListeners();

	// Set moving to false now that the carousel is ready
	moving = false;
}

// make it rain
	initCarousel();

}(document));

</script>
</cfoutput> 

<cfinclude template = "/shared/_footer.cfm">
