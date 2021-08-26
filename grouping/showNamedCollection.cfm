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
<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
	<cfset oneOfUs = 1>
	<cfelse>
	<cfset oneOfUs = 0>
</cfif>
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
/* Parent wrapper to carousel. Width can be changed as needed. */
.carousel-wrapper, .carousel-wrapper1, .carousel-wrapper2, .carousel-wrapper3 {
	overflow: hidden;
	width: 100%;
	width:100%;
	margin: auto;
}
/* Apply 'border-box' to 'box-sizing' so border and padding is included in the width and height. */
.carousel-wrapper *, .carousel-wrapper1 *, .carousel-wrapper2 *, .carousel-wrapper3 * {
	box-sizing: border-box;
}
/* We'll be using the 'transform' property to move the carousel's items, so setting the 'transform-style' to 'preserve-3d' will make sure our nested elements are rendered properly in the 3D space. */
.carousel, .carousel1, .carousel2, .carousel3 {
	-webkit-transform-style: preserve-3d;
	-moz-transform-style: preserve-3d;
	transform-style: preserve-3d;
}
/* By default we're hiding items (except the initial one) until the JS initiates. Elements are absolutely positioned with a width of 100% (as we're styling for mobile first), letting the content's height dictate the height of the carousel. Our magic property here for all our animation needs is 'transition', taking the properties we wish to animate 'transform' and 'opacity', along with the length of time in seconds. */
.carousel__photo,.carousel__photo1,.carousel__photo2,.carousel__photo3 {
	opacity: 0;
	position: absolute;
	top:0;
	width: 100%;
	margin: auto;
	padding: 1rem 2rem;/*changed to 2 from 4*/
	z-index: 100;
	transition: transform .5s, opacity .5s, z-index .5s;
	border: 1px solid ##bac5c6;
	
}
.carousel_background {
	background-color: ##f8f9fa;
	border:1px solid ##e8e8e8;
	border: .5rem solid ##fff;
}
/* Display the initial item and bring it to the front using 'z-index'. These styles also apply to the 'active' item. */
.carousel__photo.initial,.carousel__photo1.initial,.carousel__photo2.initial,.carousel__photo3.initial,
.carousel__photo.active,.carousel__photo1.active,.carousel__photo2.active,.carousel__photo3.active {
	opacity: 1;
	position: relative;
	z-index: 900;
}
/* Set 'z-index' to sit behind our '.active' item. */
.carousel__photo.prev,.carousel__photo1.prev,.carousel__photo2.prev,.carousel__photo3.prev,
.carousel__photo.next,.carousel__photo1.next,.carousel__photo2.next,.carousel__photo3.next {
	z-index: 800;
}
/* Translate previous item to the left */
.carousel__photo.prev,.carousel__photo1.prev,.carousel__photo2.prev,.carousel__photo3.prev {
  transform: translateX(-100%);
}
/* Translate next item to the right */
.carousel__photo.next,.carousel__photo1.next,.carousel__photo2.next,.carousel__photo3.next {
	transform: translateX(100%);
}
/* Style navigation buttons to sit in the middle, either side of the carousel. */
.carousel__button--prev,.carousel__button1--prev,.carousel__button2--prev,.carousel__button3--prev,
.carousel__button--next,.carousel__button1--next,.carousel__button2--next,.carousel__button3--next {
	position: absolute;
	top:50%;
	width: 2rem; /*changed from 3 to 2*/
	height: 40rem;
	background-color: transparent;
	transform: translateY(-50%);
	border-radius: 50%;
	cursor: pointer; 
	z-index: 1001; /* Sit on top of everything */
	border:1px solid tranparent;
/*  opacity: 0;  Hide buttons until carousel is initialised transition:opacity 1s;*/
}
.carousel__button--prev,.carousel__button1--prev,.carousel__button2--prev,.carousel__button3--prev {
	left:4px;/*changed from 15 to 9*/
}
.carousel__button--next,.carousel__button1--next,.carousel__button2--next,.carousel__button3--next {
	right:-4px;
}
/* Use pseudo elements to insert arrows inside of navigation buttons */
.carousel__button--prev::after,.carousel__button1--prev::after,.carousel__button2--prev::after,.carousel__button3--prev::after,
.carousel__button--next::after,.carousel__button1--next::after,.carousel__button2--next::after,.carousel__button3--next::after {
	content: " ";
	position: absolute;
	width: 15px;
	height: 15px;
	top: 50%;
	left: 54%;
	border-right: 2px solid ##007bff;
	border-bottom: 2px solid ##007bff;
	transform: translate(-50%, -50%) rotate(135deg);
}

.carousel__button--next::after,.carousel__button1--next::after,.carousel__button2--next::after,.carousel__button3--next::after {
	left: 47%;
	transform: translate(-50%, -50%) rotate(-45deg);
	
	left: 20%;
	transform: translate(-50%, -50%) rotate(-45deg);
}
.current {
	width: 300px;
	height: 300px; 
	border: .5rem solid ##fff;;
	background-color: ##f8f9fa;
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
		<main class="py-3">
			<div class="row mx-0">
			<article class="w-100">
				<div class="col-12">
					<div class="row mx-0">
						<div class="col-12 border-dark mt-4">
							<h1 class="pb-2 w-100 border-bottom-black">#getNamedGroup.collection_name#
								<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_specimens")>
									<div class="d-inline-block float-right"> <a target="_blank" class="px-2 btn-xs btn-primary text-decoration-none" href="/grouping/NamedCollection.cfm?action=edit&underscore_collection_id=#underscore_collection_id#">Edit</a> </div>
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
						<cfif specimenImgs.recordcount GT 0>
							<cfset hasSpecImages = true>
							<cfset specimenImgsCt = specimenImgs.recordcount>
							<cfset otherimagetypes = 0>
						</cfif>
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
									var now = new Date();
									var nowstring = now.toISOString().replace(/[^0-9TZ]/g,'_');
									var filename = 'NamedGroup_results_' + nowstring + '.csv';
									$('##btnContainer').html('<button id="namedgroupcsvbutton" class="btn-xs btn-secondary px-3 py-1 m-0" aria-label="Export results to csv" onclick=" exportGridToCSV(\'jqxgrid\', \''+filename+'\'); " >Export to CSV</button>');
									});
						</script>
						<div class="col-12 my-2">
							<h2 class="float-left">Specimen Records <span class="small">
								<cfif oneOfUs eq 1>
									<a href="/SpecimenResults.cfm?underscore_coll_id=#encodeForURL(underscore_collection_id)#" target="_blank">(Link to manage
								</cfif>
								#specimens.recordcount# records
								<cfif oneOfUs eq 1>
									)</a>
								</cfif>
								</span></h2>
							<div id="btnContainer" class="ml-3 float-left"></div>
						</div>
						<section class="container-fluid">
							<div class="row">
								<div class="col-12 mb-3">
									<div class="row mt-0 mx-0"> 
										<!--- Grid Related code is below along with search handlers --->
										<div id="jqxgrid"></div>
									</div>
								</div>
							</div>
						</section>
					</div>
					<!---end specimen grid---> 
				</div>
				<cfset otherImageTypes = 0>
				<!--- obtain a random set of specimen images, limited to a small number --->
				
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
					WHERE   Rownum  < 26
				</cfquery>
				<!---							<cfif specimenImgs.recordcount GT 0>
								<cfset hasSpecImages = true>
							</cfif>--->
				<cfif specimenImagesForCarousel.recordcount GT 0>
					<cfset otherImageTypes = otherImageTypes + 1>
				</cfif>
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
					WHERE Rownum < 26
				</cfquery>
				<cfquery name="agentCt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="agentCt">
					SELECT DISTINCT media.media_id
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
				</cfquery>
				<cfif agentImagesForCarousel.recordcount GT 0>
					<cfset otherImageTypes = otherImageTypes + 1>
				</cfif>
				<cfquery name="collectingImagesForCarousel" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="collectingImagesForCarousel_result">  
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
								left join collecting_event 
								on collecting_event.collecting_event_id = flat.collecting_event_id 
								left join media_relations 
								on collecting_event.collecting_event_id = media_relations.related_primary_key 
							left join media on media_relations.media_id = media.media_id
						WHERE underscore_collection.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
							AND flat.guid IS NOT NULL
							AND media_relations.media_relationship = 'shows collecting_event'
							AND media.media_type = 'image'
							AND (media.mime_type = 'image/jpeg' OR media.mime_type = 'image/png')
							AND media.media_uri LIKE '%mczbase.mcz.harvard.edu%'
						ORDER BY DBMS_RANDOM.RANDOM
					) 
					WHERE Rownum < 26
				</cfquery>
				<cfquery name="collectingCt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="collectingImagesForCarousel_result">  
					SELECT DISTINCT media.media_id
					FROM
						underscore_collection
						left join underscore_relation on underscore_collection.underscore_collection_id = underscore_relation.underscore_collection_id
						left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat 
							on underscore_relation.collection_object_id = flat.collection_object_id
							left join collecting_event 
							on collecting_event.collecting_event_id = flat.collecting_event_id 
							left join media_relations 
							on collecting_event.collecting_event_id = media_relations.related_primary_key 
						left join media on media_relations.media_id = media.media_id
					WHERE underscore_collection.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
						AND flat.guid IS NOT NULL
						AND media_relations.media_relationship = 'shows collecting_event'
						AND media.media_type = 'image'
						AND (media.mime_type = 'image/jpeg' OR media.mime_type = 'image/png')
						AND media.media_uri LIKE '%mczbase.mcz.harvard.edu%'
				</cfquery>
				<cfif collectingCt.recordcount GT 0>
					<cfset otherImageTypes = otherImageTypes + 1>
				</cfif>
				<cfquery name="localityCt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="localityCt"> 
						SELECT DISTINCT media.media_id
						FROM
							underscore_collection
							left join underscore_relation on underscore_collection.underscore_collection_id = underscore_relation.underscore_collection_id
							left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat 
								on underscore_relation.collection_object_id = flat.collection_object_id
								left join locality
								on locality.locality_id = flat.locality_id 
								left join media_relations 
								on locality.locality_id = media_relations.related_primary_key 
							left join media on media_relations.media_id = media.media_id
						WHERE underscore_collection.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
							AND flat.guid IS NOT NULL
							AND media_relations.media_relationship = 'shows locality'
							AND media.media_type = 'image'
							AND (media.mime_type = 'image/jpeg' OR media.mime_type = 'image/png')
							AND media.media_uri LIKE '%mczbase.mcz.harvard.edu%'
				</cfquery>
				<cfquery name="localityImagesForCarousel" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="localityImagesForCarousel_result">  
					SELECT * FROM (
						SELECT DISTINCT media_uri, preview_uri,media_type, media.media_id,
							MCZBASE.get_media_descriptor(media.media_id) as alt,
							MCZBASE.get_medialabel(media.media_id,'width') as width,
							MCZBASE.get_media_credit(media.media_id) as credit
						FROM
							underscore_collection
							left join underscore_relation 
								on underscore_collection.underscore_collection_id = underscore_relation.underscore_collection_id
							left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat 
								on underscore_relation.collection_object_id = flat.collection_object_id
							left join locality
								on locality.locality_id = flat.locality_id 
							left join media_relations 
								on locality.locality_id = media_relations.related_primary_key 
							left join media 
								on media_relations.media_id = media.media_id
						WHERE underscore_collection.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
							AND flat.guid IS NOT NULL
							AND media_relations.media_relationship = 'shows locality'
							AND media.media_type = 'image'
							AND (media.mime_type = 'image/jpeg' OR media.mime_type = 'image/png')
							AND media.media_uri LIKE '%mczbase.mcz.harvard.edu%'
						ORDER BY DBMS_RANDOM.RANDOM
					) 
					WHERE Rownum < 26
				</cfquery>
				<cfquery name="coordinatesHeatMap" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="coordinatesHeatMap_result">  
					select lat_long.dec_lat, lat_long.DEC_LONG 
					from locality
					left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat 
					on flat.locality_id = locality.locality_id
					left join lat_long
					on lat_long.locality_id = flat.locality_id
					left join underscore_relation
					on underscore_relation.collection_object_id = flat.collection_object_id
					left join underscore_collection
					on underscore_relation.underscore_collection_id = underscore_collection.underscore_collection_id
					WHERE underscore_collection.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
					and flat.guid IS NOT NULL
				</cfquery>
				<cfif localityCt.recordcount GT 0>
					<cfset otherImageTypes = otherImageTypes + 1>
				</cfif>
				<cfoutput>
					<div class="row mx-3 mt-3">
					<div class="col-12 col-md-6 float-left">
					<cfif specimenImagesForCarousel.recordcount GT 0 OR localityImagesForCarousel.recordcount GT 0 OR collectingImagesForCarousel.recordcount GT 0 OR agentImagesForCarousel.recordcount GT 0>
						<!---	<cfset leftHandColumnOn = true>---> 
						<!---	<cfset hasSpecImages = false>--->
						<h2 class="mt-3">Images <span class="small">(25 max. shown per category) </span></h2>
						<div class="row">
							<cfif specimenImagesForCarousel.recordcount gt 1>
								<div class="col-12 px-md-2">
									<h3 class="h4 px-2">Specimen Images (#specimenImgsCt# images)</h3>
									<div class="carousel-wrapper">
										<div class="carousel carousel_background">
											<cfset i=1>
											<cfloop query="specimenImagesForCarousel">
												<!---	<img class="carousel__photo <cfif #i# eq 1>active</cfif>" src="#specimenImagesforCarousel['media_uri'][i]#">--->
												<div class="carousel__photo border <cfif #i# eq 1>active</cfif>"> <img src="#specimenImagesForCarousel['media_uri'][i]#" class="w-100">
													<p>#specimenImagesForCarousel['alt'][i]# <br>
														<a href="/MediaSet.cfm?media_id=#agentImagesForCarousel['media_id'][i]#">Media Details</a></p>
												</div>
												<cfset i=i+1>
											</cfloop>
											<div class="carousel__button--next"></div>
											<div class="carousel__button--prev"></div>
										</div>
									</div>
								</div>
								<cfelseif specimenImagesForCarousel.recordcount eq 1>
								<div class="col-12 px-md-2">
									<h3 class="h4 px-2">Specimen Images (#specimenImgsCt# images)</h3>
									<div class="carousel-wrapper">
										<div class="carousel carousel_background">
											<cfset i=1>
											<cfloop query="specimenImagesForCarousel">
												<!---	<img class="carousel__photo <cfif #i# eq 1>active</cfif>" src="#specimenImagesforCarousel['media_uri'][i]#">--->
												<div class="px-4 py-3 border <cfif #i# eq 1>active</cfif>"> <img src="#specimenImagesForCarousel['media_uri'][i]#" class="w-100">
													<p>#specimenImagesForCarousel['alt'][i]# <br>
														<a href="/MediaSet.cfm?media_id=#agentImagesForCarousel['media_id'][i]#">Media Details</a></p>
												</div>
												<cfset i=i+1>
											</cfloop>
											<div class="carousel__button--next"></div>
											<div class="carousel__button--prev"></div>
										</div>
									</div>
								</div>
								<cfelse>
								<!---no images--->
							</cfif>
						</div>
						<!--- figure out widths of sub blocks, adapt to number of blocks --->
						<cfswitch expression="#otherImageTypes#">
							<cfcase value="1">
							<cfset colClass = "col-md-12 mx-auto float-none">
							<cfset imgWidth = 600>
							</cfcase>
							<cfcase value="2">
							<cfset colClass = "col-md-12 mx-auto float-none">
							<cfset imgWidth = 600>
							</cfcase>
							<cfcase value="3">
							<cfset colClass = "col-md-6 float-left">
							<cfset imgWidth = 400>
							</cfcase>
							<cfcase value="4">
							<cfset colClass = "col-md-12 col-xl-4 float-left">
							<cfset imgWidth = 300>
							</cfcase>
							<cfdefaultcase>
							<cfset colClass = "col-md-12 col-xl-3 float-left">
							</cfdefaultcase>
						</cfswitch>
						<div class="row">
							<div class="col-12 px-2">
								<cfif agentImagesForCarousel.recordcount gte 2>
									<cfset imagePlural = 'images'>
									<cfelse>
									<cfset imagePlural = 'image'>
								</cfif>
								<cfif agentImagesForCarousel.recordcount gt 1>
									<div class="col-12 #colClass# mx-md-auto px-md-0 mt-3">
										<h3 class="h4 px-2">Agent (#agentCt.recordcount# images)</h3>
										<div class="carousel-wrapper1">
											<div class="carousel1 carousel_background">
												<cfset i=1>
												<cfloop query="agentImagesForCarousel">
													<div class="carousel__photo1 border <cfif #i# eq 1>active initial</cfif>"> <img src="#agentImagesForCarousel['media_uri'][i]#" class="w-100">
														<p>#agentImagesForCarousel['alt'][i]# <br>
															<a href="/MediaSet.cfm?media_id=#agentImagesForCarousel['media_id'][i]#">Media Details</a></p>
													</div>
													<cfset i=i+1>
												</cfloop>
												<div class="carousel__button1--next"></div>
												<div class="carousel__button1--prev"></div>
											</div>
										</div>
									</div>
									<cfelseif agentImagesForCarousel.recordcount eq 1>
									<div class="col-12 #colClass# px-md-0 mt-3">
										<h3 class="h4 px-2">Agent (#agentCt.recordcount# #imagePlural#)</h3>
										<div class="carousel-wrapper1">
											<div class="carousel1 carousel_background">
												<cfset i=1>
												<cfloop query="agentImagesForCarousel">
													<!---	<img class="carousel__photo2 <cfif #i# eq 1>active</cfif>" src="#collectingImagesForCarousel['media_uri'][i]#">--->
													<div class="px-4 py-3 border <cfif #i# eq 1>active initial</cfif>"> <img src="#agentImagesForCarousel['media_uri'][i]#" class="w-100 <cfif #i# eq 1>active</cfif>">
														<p>#agentImagesForCarousel['alt'][i]# <br>
															<a href="/MediaSet.cfm?media_id=#agentImagesForCarousel['media_id'][i]#">Media Details</a></p>
													</div>
													<cfset i=i+1>
												</cfloop>
											</div>
										</div>
									</div>
									<cfelse>
									<!---no images--->
								</cfif>
								<cfif collectingImagesForCarousel.recordcount gte 2>
									<cfset imagePlural = 'images'>
									<cfelse>
									<cfset imagePlural = 'image'>
								</cfif>
								<cfif collectingImagesForCarousel.recordcount gt 1>
									<div class="col-12 #colClass# px-md-0 mt-3">
										<h3 class="h4 px-2">Collecting Event (#collectingCt.recordcount# #imagePlural#)</h3>
										<div class="carousel-wrapper2">
											<div class="carousel2 carousel_background">
												<cfset i=1>
												<cfloop query="collectingImagesForCarousel">
													<!---	<img class="carousel__photo2 <cfif #i# eq 1>active</cfif>" src="#collectingImagesForCarousel['media_uri'][i]#">--->
													<div class="carousel__photo2 border <cfif #i# eq 1>active initial</cfif>"> <img src="#collectingImagesForCarousel['media_uri'][i]#" class="w-100 <cfif #i# eq 1>active</cfif>">
														<p>#collectingImagesForCarousel['alt'][i]# <br>
															<a href="/MediaSet.cfm?media_id=#agentImagesForCarousel['media_id'][i]#">Media Details</a></p>
													</div>
													<cfset i=i+1>
												</cfloop>
												<div class="carousel__button2--next"></div>
												<div class="carousel__button2--prev"></div>
											</div>
										</div>
									</div>
									<cfelseif collectingImagesForCarousel.recordcount eq 1>
									<div class="col-12 #colClass# px-md-0 mt-3">
										<h3 class="h4 px-2">Collecting Event (#collectingCt.recordcount# #imagePlural#)</h3>
										<div class="carousel-wrapper2">
											<div class="carousel2 carousel_background">
												<cfset i=1>
												<cfloop query="collectingImagesForCarousel">
													<!---	<img class="carousel__photo2 <cfif #i# eq 1>active</cfif>" src="#collectingImagesForCarousel['media_uri'][i]#">--->
													<div class="px-4 py-3 border <cfif #i# eq 1>active initial</cfif>"> <img src="#collectingImagesForCarousel['media_uri'][i]#" class="w-100 <cfif #i# eq 1>active</cfif>">
														<p>#collectingImagesForCarousel['alt'][i]# <br>
															<a href="/MediaSet.cfm?media_id=#agentImagesForCarousel['media_id'][i]#">Media Details</a></p>
													</div>
													<cfset i=i+1>
												</cfloop>
											</div>
										</div>
									</div>
									<cfelse>
									<!---no images--->
								</cfif>
								<cfif localityImagesForCarousel.recordcount gte 2>
									<cfset imagePlural = 'images'>
									<cfelse>
									<cfset imagePlural = 'image'>
								</cfif>
								<cfif localityImagesForCarousel.recordcount gt 1>
									<div class="col-12 #colClass# px-md-0 mt-3">
										<h3 class="h4 px-2">Locality (#localityImagesForCarousel.recordcount# #imagePlural#)</h3>
										<div class="carousel-wrapper3">
											<div class="carousel3 carousel_background">
												<cfset i=1>
												<cfloop query="localityImagesForCarousel">
													<div class="carousel__photo3 border <cfif #i# eq 1>active</cfif>"> <img src="#localityImagesForCarousel['media_uri'][i]#" class="w-100 <cfif #i# eq 1>active</cfif>">
														<p>#localityImagesForCarousel['alt'][i]# <br>
															<a href="/MediaSet.cfm?media_id=#agentImagesForCarousel['media_id'][i]#">Media Details</a></p>
													</div>
													<cfset i=i+1>
												</cfloop>
												<div class="carousel__button3--next"></div>
												<div class="carousel__button3--prev"></div>
											</div>
										</div>
									</div>
									<cfelseif localityImagesForCarousel.recordcount eq 1>
									<div class="col-12 #colClass# px-md-0 mt-3">
										<h3 class="h4 px-2">Locality (#localityImagesForCarousel.recordcount# #imagePlural#)</h3>
										<div class="carousel-wrapper3">
											<div class="carousel3 carousel_background">
												<cfset i=1>
												<cfloop query="localityImagesForCarousel">
													<div class="px-4 py-3 border <cfif #i# eq 1>active</cfif>"> <img src="#localityImagesForCarousel['media_uri'][i]#" class="w-100 <cfif #i# eq 1>active</cfif>">
														<p>#localityImagesForCarousel['alt'][i]# <br>
															<a href="/MediaSet.cfm?media_id=#agentImagesForCarousel['media_id'][i]#">Media Details</a></p>
													</div>
													<cfset i=i+1>
												</cfloop>
											</div>
										</div>
									</div>
									<cfelse>
									<!---no images--->
								</cfif>
							</div>
						</div>
					</cfif>
				</cfoutput> 
										
				<cfoutput>
					<div class="row">
						<div id="mapper" class="col-12 h-100 px-0">
							<h2 class="mt-4">Heat Map Example</h2>
							<style>
									##map {
									  height: 100%;
										width: 100%;
									}
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


	 <script>

		function initMap() {
		map = new google.maps.Map(document.getElementById("map"), {
		zoom: 4,
		center: { lat: 42.3785136, lng: -71.117796 },
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
	<script src="https://polyfill.io/v3/polyfill.min.js?features=default"></script>
	<div id="floating-panel" class="mt-2">
		<button id="toggle-heatmap">Toggle Heatmap</button>
		<button id="change-gradient">Change gradient</button>
		<button id="change-radius">Change radius</button>
		<button id="change-opacity">Change opacity</button>
	</div>
	<div id="map" class="col-12" style="height: 900px;"></div>
	<script async src="https://maps.googleapis.com/maps/api/js?key=#application.gmap_api_key#&libraries=visualization&callback=initMap"></script>

						</div>
					</div>
				</cfoutput>
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
									<h3>
									Associated Agent
									</h2>
									<p class="rounded-0 border-top border-dark"> <a class="h4 px-2 pt-3 d-block" href="/agents/Agent.cfm?agent_id=#underscore_agent_id#">#getNamedGroup.agent_name#</a> </p>
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
										<li class="list-group-item col-12 col-md-3 float-left"> <a class="h4" href="/SpecimenResults.cfm?#encodeForUrl(taxonQuery.rank)#=#encodeForUrl(taxonQuery.taxonlink)#&underscore_coll_id=#getNamedGroup.underscore_collection_id#">#taxonQuery.taxon#</a> </li>
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
										<li class="list-group-item col-12 col-md-3 float-left"> <a class="h4" href="/SpecimenResults.cfm?continent_ocean=#encodeForURL(marine.ocean)#&underscore_coll_id=#getNamedGroup.underscore_collection_id#">#marine.ocean#</a> </li>
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
										<li class="list-group-item col-12 col-md-3 float-left"> <a class="h4" href="/SpecimenResults.cfm?#encodeForUrl(geogQuery.rank)#=#encodeForUrl(geogQuery.geoglink)#&underscore_coll_id=#getNamedGroup.underscore_collection_id#">#geogQuery.geog#</a> </li>
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
										<li class="list-group-item col-12 col-md-3 float-left"> <a class="h4" href="/SpecimenResults.cfm?island=#encodeForUrl(islandsQuery.island)#&underscore_coll_id=#getNamedGroup.underscore_collection_id#"> #continent_ocean#: #islandsQuery.island# </a> </li>
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
										<li class="list-group-item col-12 col-md-3 float-left"> <a class="h4" href="/agents/Agent.cfm?agent_id=#collectors.agent_id#" target="_blank">#collectors.agent_name#</a> </li>
									</cfloop>
								</ul>
							</div>
						</cfif>
					</div>
				</div>
				</div>
				<!--- end rowEverythihngElse---> 
			</article>
			</div>
		</main>
	</cfloop>
	<script>

!(function(d){
	// Variables to target our base class,  get carousel items, count how many carousel items there are, set the slide to 0 (which is the number that tells us the frame we're on), and set motion to true which disables interactivity.
	var itemClassName = "carousel__photo";
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
		var next = d.getElementsByClassName('carousel__button--next')[0],
			prev = d.getElementsByClassName('carousel__button--prev')[0];

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
		if ((totalItems - 1) > 1) {

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
/////////////////
!(function(e){
	// Variables to target our base class,  get carousel items, count how many carousel items there are, set the slide to 0 (which is the number that tells us the frame we're on), and set motion to true which disables interactivity.
	var itemClassName1 = "carousel__photo1";
		items1 = e.getElementsByClassName(itemClassName1),
			totalItems1 = items1.length,
			slide1 = 0,
			moving1 = true; 

	// To initialise the carousel we'll want to update the DOM with our own classes
	function setInitialClasses1() {
		// Target the last, initial, and next items and give them the relevant class.
		// This assumes there are three or more items.
		items1[totalItems1 - 1].classList.add("prev");
		items1[0].classList.add("active");
		items1[1].classList.add("next");
	}
	// Set click events to navigation buttons

	function setEventListeners1() {
		var next = e.getElementsByClassName('carousel__button1--next')[0],
			prev = e.getElementsByClassName('carousel__button1--prev')[0];

		next.addEventListener('click', moveNext1);
		prev.addEventListener('click', movePrev1);
	}

	// Disable interaction by setting 'moving' to true for the same duration as our transition (0.5s = 500ms)
	function disableInteraction1() {
		moving1 = true;

		setTimeout(function(){
			moving1 = false
		}, 500);
	}

	function moveCarouselTo1(slide1) {
		// Check if carousel is moving, if not, allow interaction
		if(!moving1) {
			// temporarily disable interactivity
			disableInteraction1();
			// Preemptively set variables for the current next and previous slide, as well as the potential next or previous slide.
			var newPrevious = slide1 - 1,
				newNext = slide1 + 1,
				oldPrevious = slide1 - 2,
				oldNext = slide1 + 2;
			// Test if carousel has more than three items
			if ((totalItems1 - 1) > 1) {

				// Checks if the new potential slide is out of bounds and sets slide numbers
				if (newPrevious <= 0) {
					oldPrevious = (totalItems1 - 1);
				} else if (newNext >= (totalItems1 - 1)){
					oldNext = 0;
				}

				// Check if current slide is at the beginning or end and sets slide numbers
				if (slide1 === 0) {
					newPrevious = (totalItems1 - 1);
					oldPrevious = (totalItems1 - 2);
					oldNext = (slide1 + 1);
				} else if (slide1 === (totalItems1 -1)) {
					newPrevious = (slide1 - 1);
					newNext = 0;
					oldNext = 1;
				}

				// Now we've worked out where we are and where we're going, by adding and removing classes, we'll be triggering the carousel's transitions.

				// Based on the current slide, reset to default classes.
				items1[oldPrevious].className = itemClassName1;
				items1[oldNext].className = itemClassName1;

				// Add the new classes
				items1[newPrevious].className = itemClassName1 + " prev";
				items1[slide1].className = itemClassName1 + " active";
				items1[newNext].className = itemClassName1 + " next";
			}
		}
	}

	// Next navigation handler
	function moveNext1() {
		// Check if moving
		if (!moving1) {
			// If it's the last slide, reset to 0, else +1
			if (slide1 === (totalItems1 - 1)) {
				slide1 = 0;
			} else {
				slide1++;
			}
			// Move carousel to updated slide
			moveCarouselTo1(slide1);
		}
	}
	// Previous navigation handler
	function movePrev1() {
		// Check if moving
		if (!moving1) {
			// If it's the first slide, set as the last slide, else -1
			if (slide1 === 0) {
				slide1 = (totalItems1 - 1);
			} else {
				slide1--;
			}
			// Move carousel to updated slide
			moveCarouselTo1(slide1);
		}
	}
	// Initialise carousel
	function initCarousel1() {
		setInitialClasses1();
		setEventListeners1();
		// Set moving to false now that the carousel is ready
		moving1 = false;
	}
	// make it rain
	initCarousel1();

}(document));
/////////////////
!(function(f){
	// Variables to target our base class,  get carousel items, count how many carousel items there are, set the slide to 0 (which is the number that tells us the frame we're on), and set motion to true which disables interactivity.
	var itemClassName2 = "carousel__photo2";
		items2 = f.getElementsByClassName(itemClassName2),
			totalItems2 = items2.length,
			slide2 = 0,
			moving2 = true; 

	// To initialise the carousel we'll want to update the DOM with our own classes
	function setInitialClasses2() {
		// Target the last, initial, and next items and give them the relevant class.
		// This assumes there are three or more items.
		items2[totalItems2 - 1].classList.add("prev");
		items2[0].classList.add("active");
		items2[1].classList.add("next");
	}

	// Set click events to navigation buttons
	function setEventListeners2() {
		var next = f.getElementsByClassName('carousel__button2--next')[0],
			prev = f.getElementsByClassName('carousel__button2--prev')[0];

		next.addEventListener('click', moveNext2);
		prev.addEventListener('click', movePrev2);
	}

	// Disable interaction by setting 'moving' to true for the same duration as our transition (0.5s = 500ms)
	function disableInteraction2() {
		moving2 = true;

		setTimeout(function(){
			moving2 = false
		}, 500);
	}

	function moveCarouselTo2(slide2) {
		// Check if carousel is moving, if not, allow interaction
		if(!moving2) {
			// temporarily disable interactivity
			disableInteraction2();
			// Preemptively set variables for the current next and previous slide, as well as the potential next or previous slide.
			var newPrevious = slide2 - 1,
				newNext = slide2 + 1, 
				oldPrevious = slide2 - 2, 
				oldNext = slide2 + 2; 

			// Test if carousel has more than one item
			if ((totalItems2 - 1) > 1) {

				// Checks if the new potential slide is out of bounds and sets slide numbers
				if (newPrevious <= 0) {
					oldPrevious = (totalItems2 - 1);
				} else if (newNext >= (totalItems2 - 1)){
					oldNext = 0; 
				}

				// Check if current slide is at the beginning or end and sets slide numbers
				if (slide2 === 0) {
					newPrevious = (totalItems2 - 1);
					oldPrevious = (totalItems2 - 2);
					oldNext = (slide + 1);
				} else if (slide2 === (totalItems2 -1)) {
					newPrevious = (slide2 - 1);
					newNext = 0;
					oldNext = 1;
				} else {
					current;
				}
			// Now we've worked out where we are and where we're going, by adding and removing classes, we'll be triggering the carousel's transitions.
				// Based on the current slide, reset to default classes.
				items2[oldPrevious].className = itemClassName2;
				items2[oldNext].className = itemClassName2;

				// Add the new classes
				items2[newPrevious].className = itemClassName2 + " prev";
				items2[slide2].className = itemClassName2 + " active";
				items2[newNext].className = itemClassName2 + " next";
				items2[current].className = itemClassName2 + " active";
			}
		}
	}

	// Next navigation handler
	function moveNext2() {
		// Check if moving
		if (!moving2) {
			// If it's the last slide, reset to 0, else +1
			if (slide2 === (totalItems2 - 1)) {
				slide2 = 0;
			} else {
				slide2++;
			}
			// Move carousel to updated slide
			moveCarouselTo2(slide2);
		}
	}

	// Previous navigation handler
	function movePrev2() {
		// Check if moving
		if (!moving2) {
			// If it's the first slide, set as the last slide, else -1
			if (slide2 === 0) {
				slide2 = (totalItems2 - 1);
			} else {
				slide2--;
			}
			// Move carousel to updated slide
			moveCarouselTo2(slide2);
		}
	}

	// Initialise carousel
	function initCarousel2() {
		setInitialClasses2();
		setEventListeners2();
		// Set moving to false now that the carousel is ready
		moving2 = false;
	}
	// make it rain
	initCarousel2();

}(document));
/////////////////
!(function(s){
	// Variables to target our base class,  get carousel items, count how many carousel items there are, set the slide to 0 (which is the number that tells us the frame we're on), and set motion to true which disables interactivity.
	var itemClassName3 = "carousel__photo3";
		items3 = s.getElementsByClassName(itemClassName3),
			totalItems3 = items3.length,
			slide3 = 0,
			moving3 = true; 

	// To initialise the carousel we'll want to update the DOM with our own classes
	function setInitialClasses3() {
		// Target the last, initial, and next items and give them the relevant class.
		// This assumes there are three or more items.
		items3[totalItems3 - 1].classList.add("prev");
		items3[0].classList.add("active");
		items3[1].classList.add("next");
	}
	// Set click events to navigation buttons

	function setEventListeners3() {
		var next = s.getElementsByClassName('carousel__button3--next')[0],
			prev = s.getElementsByClassName('carousel__button3--prev')[0];

		next.addEventListener('click', moveNext3);
		prev.addEventListener('click', movePrev3);
	}

	// Disable interaction by setting 'moving' to true for the same duration as our transition (0.5s = 500ms)
	function disableInteraction3() {
		moving3 = true;

		setTimeout(function(){
			moving3 = false
		}, 500);
	}

	function moveCarouselTo3(slide3) {
		// Check if carousel is moving, if not, allow interaction
		if(!moving3) {
			// temporarily disable interactivity
			disableInteraction3();
			// Preemptively set variables for the current next and previous slide, as well as the potential next or previous slide.
			var newPrevious = slide3 - 1,
				newNext = slide3 + 1,
				oldPrevious = slide3 - 2,
				oldNext = slide3 + 2;
			
			// Test if carousel has more than three items
			if ((totalItems3 - 1) > 1) {

				// Checks if the new potential slide is out of bounds and sets slide numbers
				if (newPrevious <= 0) {
					oldPrevious = (totalItems3 - 1);
				} else if (newNext >= (totalItems3 - 1)){
					oldNext = 0;
				}

				// Check if current slide is at the beginning or end and sets slide numbers
				if (slide3 === 0) {
					newPrevious = (totalItems3 - 1);
					oldPrevious = (totalItems3 - 2);
					oldNext = (slide3 + 1);
				} else if (slide3 === (totalItems3 -1)) {
					newPrevious = (slide3 - 1);
					newNext = 0;
					oldNext = 1;
				}
				
			// Now we've worked out where we are and where we're going, by adding and removing classes, we'll be triggering the carousel's transitions.
				// Based on the current slide, reset to default classes.
				items3[oldPrevious].className = itemClassName3;
				items3[oldNext].className = itemClassName3;

				// Add the new classes
				items3[newPrevious].className = itemClassName3 + " prev";
				items3[slide3].className = itemClassName3 + " active";
				items3[newNext].className = itemClassName3 + " next";
			} 
		}
	}

	// Next navigation handler
	function moveNext3() {
		// Check if moving
		if (!moving3) {
			// If it's the last slide, reset to 0, else +1
			if (slide3 === (totalItems3 - 1)) {
				slide3 = 0;
			} else {
				slide3++;
			}
			// Move carousel to updated slide
			moveCarouselTo3(slide3);
		}
	}
	// Previous navigation handler
	function movePrev3() {
		// Check if moving
		if (!moving3) {
			// If it's the first slide, set as the last slide, else -1
			if (slide3 === 0) {
				slide3 = (totalItems3 - 1);
			} else {
				slide3--;
			}
			// Move carousel to updated slide
			moveCarouselTo3(slide3);
		}
	}
	// Initialise carousel
	function initCarousel3() {
		setInitialClasses3();
		setEventListeners3();
		// Set moving to false now that the carousel is ready
		moving3 = false;
	}
	// make it rain
	initCarousel3();

}(document));
</script>
</cfoutput>
<cfinclude template = "/shared/_footer.cfm">
