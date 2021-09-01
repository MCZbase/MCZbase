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


<style>
/* Parent wrapper to carousel. Width can be changed as needed. */
.carousel-wrapper, .carousel-wrapper1, .carousel-wrapper2, .carousel-wrapper3 {
	/*overflow: hidden;*/
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
	border: 1px solid #bac5c6;
	
}
.carousel_background {
	background-color: #f8f9fa;
	border:1px solid #e8e8e8;
	border: .5rem solid #fff;
}
/* Display the initial item and bring it to the front using 'z-index'. These styles also apply to the 'active' item. */
.carousel__photo.initial,.carousel__photo1.initial,.carousel__photo2.initial,.carousel__photo3.initial,
.carousel__photo.active,.carousel__photo1.active,.carousel__photo2.active,.carousel__photo3.active {
	opacity: 1;
	position: relative;
	z-index: 900;
	top: 0;
}
.carousel__photo.active img:focus, .carousel__photo1.active img:focus,.carousel__photo2.active img:focus, .carousel__photo3.active img:focus {
	border: 1px solid rgb(0 123 255 / 25%);
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
	/*border-radius: 50%;*/
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
	border-right: 2px solid #007bff;
	border-bottom: 2px solid #007bff;
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
	border: .5rem solid #fff;;
	background-color: #f8f9fa;
}
#map {
	height: 100%;
	width: 100%;
}
#floating-panel {
	position: absolute;
	top: 10px;
	left: 25%;
	z-index: 5;
	background-color: #fff;
	padding: 5px;
	border: 1px solid #999;
	text-align: center;
	font-family: "Roboto", "sans-serif";
	line-height: 30px;
	padding-left: 10px;
}
#floating-panel {
	background-color: #fff;
	border: 1px solid #999;
	left: 25%;
	padding: 5px;
	position: absolute;
	top: 10px;
	z-index: 5;
}

.vslider {
  position: relative;
  overflow: hidden;
}

.vslider > * {
  display: block;
  position: relative;
}

.vslider > * + * {
  display: none;
  position: absolute;
}

.vslider-item {
  display: block;
  width: 100%;
  height: 100%;
  top: 0;
  bottom: 0;
  -ms-touch-action: none;
  touch-action: none;
  transition: z-index 0s,
  opacity .8s ease-in-out,
  transform .4s ease-in-out;
  z-index: 20;
  opacity: 0;
  transform: translateX(-10%);
}

.vslider-item[aria-hidden='false'] {
  z-index: 30;
  opacity: 1.0;
  transform: translateX(0);
}

.vslider-before {
  z-index: 10;
  opacity: 0;
  transform: translateX(10%);
}

.vslider-direct {
  transition: none;
}

.vslider-status {
  display: block;
  list-style: none;
  z-index: 110;
  position: absolute;
  left: 0;
  bottom: 0;
  width: 100%;
  text-align: center;
  padding: 0;
  margin: 0;
}

.vslider-status-item {
  cursor: pointer;
  display: inline-block;
  font-size: 0.5em;
  width: 1em;
  height: 1em;
  line-height: 1;
  color: ##000;
  background: ##000;
  border: 0.1em solid ##fff;
  border-radius: 100%;
  margin: 0 0.5em;
  transition: 0.3s;
  opacity: 0.3;
}

.vslider-status-item:hover,
.vslider-status-item:focus,
.vslider-status-item[aria-selected='true'] {
  opacity: 0.6;
}

.vslider-nav {
  display: block;
  z-index: 100;
  position: absolute;
  top: 0;
  bottom: 0;
  left: 0;
  right: 0;
}

.vslider-prev,
.vslider-next {
  cursor: pointer;
  display: block;
  position: absolute;
  top: 50%;
  left: 0;
  transform: translateY(-50%);
  line-height: 1;
  font-size: 1em;
  border: none;
  color: currentColor;
  background: none;
  opacity: 0.6;
}

.vslider-prev:hover,
.vslider-prev:focus,
.vslider-next:hover,
.vslider-next:focus {
  opacity: 1;
}

.vslider-next {
  left: auto;
  right: 0;
}

.vslider-prev:after {
  content: '<';
}

.vslider-next:after {
  content: '>';
}</style>
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
<cfoutput>
	<cfloop query="getNamedGroup">
		<cfif getNamedGroup.mask_fg EQ 1 AND (NOT isdefined("session.roles") OR listfindnocase(session.roles,"coldfusion_user") EQ 0)>
			<!--- mask_fg = 1 = Hidden --->
			<cflocation url="/errors/forbidden.cfm" addtoken="false">
		</cfif>
		<main class="py-3" id="content">
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
									selectionmode: 'multiplecelladvanced',
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
						SELECT DISTINCT media.media_id,media.media_uri, MCZBASE.get_media_descriptor(media.media_id) as alt, MCZBASE.get_medialabel(media.media_id,'width') as width, MCZBASE.get_medialabel(media.media_id,'height') as first_height,MCZBASE.get_media_credit(media.media_id) as credit
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
				<cfif specimenImagesForCarousel.recordcount GT 0>
					<cfset otherImageTypes = otherImageTypes + 1>
				</cfif>
				<cfquery name="agentImagesForCarousel" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="agentImagesForCarousel_result">
					SELECT * FROM (
						SELECT DISTINCT media.media_id,media_uri, preview_uri,media_type, 
							MCZBASE.get_media_descriptor(media.media_id) as alt,
							MCZBASE.get_medialabel(media.media_id,'width') as width,
							MCZBASE.get_medialabel(media.media_id,'height') as first_height,
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
							MCZBASE.get_medialabel(media.media_id,'height') as first_height,
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
							MCZBASE.get_medialabel(media.media_id,'height') as first_height,
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
					<cfquery name="localityImagesDesc" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="localityImagesForCarousel_result">  
					SELECT * FROM (
						SELECT DISTINCT media.media_id,
							MCZBASE.get_media_descriptor(media.media_id) as alt,
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
				<cfquery name="states" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="states_result">
					SELECT Distinct lat_long.locality_id,lat_long.dec_lat, lat_long.DEC_LONG 
					FROM locality
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
						and lat_long.dec_lat is not null
					
				</cfquery>
				<cfif localityCt.recordcount GT 0>
					<cfset otherImageTypes = otherImageTypes + 1>
				</cfif>
					<div class="row mx-3 mt-3">
					<div class="col-12 col-md-6 float-left">
					<cfif specimenImagesForCarousel.recordcount GT 0 OR localityImagesForCarousel.recordcount GT 0 OR collectingImagesForCarousel.recordcount GT 0 OR agentImagesForCarousel.recordcount GT 0>
						<h2 class="mt-3">Images <span class="small">(25 max. shown per category) </span></h2>
						<div class="">
							<cfif specimenImagesForCarousel.recordcount gt 0>
							<div class="carousel_background border float-left w-100 p-3">
								<h3 class="mx-2">Specimens</h3>
								  <div class="vslider w-100 float-left h-auto" id="vslider-base">
									 <cfset i=1>
									<cfloop query="specimenImagesForCarousel">
										<div class="small95 my-1 px-2 py-1">#specimenImagesForCarousel['alt'][i]# <br><a href="/MediaSet.cfm?media_id=#specimenImagesForCarousel['media_id'][i]#">Media Details</a><br><a href="#media_uri#" target="_blank" title="click to open full image"><img src="#specimenImagesForCarousel['media_uri'][i]#" class="w-100 float-left mx-auto" height="auto" width="100%"></a></div>
										<cfset i=i+1>
									</cfloop>
								  </div>
								<div class="custom-nav text-center border mb-1 bg-white px-1 pt-0 pb-1">
									<button type="button" class="border-0 btn-outline-primary" id="custom-prev"> << previous image </button>
									<input type="number" id="custom-input" class="border border-light mx-5 w-50 py-1 px-2 mt-1 text-center" placeholder="index">
									<button type="button" class="border-0 btn-outline-primary" id="custom-next"> next image >> </button>
								  </div>
							</div>
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
							<div class="col-12 px-0">
								<cfif agentImagesForCarousel.recordcount gte 2>
									<cfset imagePlural = 'images'>
									<cfelse>
									<cfset imagePlural = 'image'>
								</cfif>
								<cfif agentImagesForCarousel.recordcount gt 0>
								<div class="col-12 #colClass# mx-md-auto mt-3 mb-3">
									<div class="carousel_background border float-left w-100 p-3">
										<h3 class="mx-2">Agents <span class="small">(#agentCt.recordcount# images)</span></h3>
										<div class="custom-nav text-center bg-white border-right border-left border-top border-bottom mb-1 px-1 pt-0 pb-1">
											<button type="button" class="border-0 btn-outline-primary" id="custom-prev1"> << previous </button>
											<input type="number" id="custom-input1" class="border border-light w-25 py-1 px-2 mt-1 text-center" placeholder="index">
											<button type="button" class="border-0 btn-outline-primary" id="custom-next1"> next >> </button>
										</div>
										<div class="vslider float-left w-100"  style="height: #agentImagesForCarousel.first_height#" id="vslider-base1">
											<cfset i=1>
											<cfloop query="agentImagesForCarousel">
												<cfset alttext = agentImagesForCarousel['alt'][i]>
												<div class="small95 my-1">
													<cfif len(agentImagesForCarousel['alt'][i]) gt 100>
														<cfset trimmedQuote = left(alttext, 100)>
														<cfset trimmedQuote &= "...">
													<cfelse>
														<cfset trimmedQuote = agentImagesForCarousel['alt'][i]>
													</cfif>
													
													#agentImagesForCarousel['alt'][i]# 
													
													<br><a href="/MediaSet.cfm?media_id=#agentImagesForCarousel['media_id'][i]#">Media Details</a><br><a href="#media_uri#" target="_blank" title="click to open full image"><img src="#agentImagesForCarousel['media_uri'][i]#" class="w-100 float-left h-auto mx-auto"></a></div>
												<cfset i=i+1>
											</cfloop>
										</div>
									</div>
								</div>
								</cfif>
								<cfif collectingImagesForCarousel.recordcount gte 2>
									<cfset imagePlural = 'images'>
									<cfelse>
									<cfset imagePlural = 'image'>
								</cfif>
								<cfif collectingImagesForCarousel.recordcount gt 0>
								<div class="col-12 #colClass# mx-md-auto mt-3">
								<div class="carousel_background border float-left w-100 p-3">
									<h3 class="mx-2">Collecting Event <span class="small">(#collectingCt.recordcount# images)</span></h3>
									 <div class="custom-nav text-center bg-white border-right border-left border-top border-bottom mb-1 px-1 pt-0 pb-1">
										<button type="button" class="border-0 btn-outline-primary" id="custom-prev2"> << previous </button>
										<input type="number" id="custom-input2" class="border border-light w-25 py-1 px-2 mt-1 text-center" placeholder="index">
										<button type="button" class="border-0 btn-outline-primary" id="custom-next2"> next >> </button>
									 </div>
									<div class="vslider float-left w-100"  style="height: #collectingImagesForCarousel.first_height#" id="vslider-base2">
										<cfset i=1>
										<cfloop query="collectingImagesForCarousel">
											<div class="small95 my-1">#collectingImagesForCarousel['alt'][i]# <br><a href="/MediaSet.cfm?media_id=#collectingImagesForCarousel['media_id'][i]#">Media Details</a><br><a href="#media_uri#" target="_blank" title="click to open full image"><img src="#collectingImagesForCarousel['media_uri'][i]#" class="w-100 float-left h-auto mx-auto"></a></div>
											<cfset i=i+1>
										</cfloop>
									</div>
								</div>
									</div>
								</cfif>
								<cfif localityImagesForCarousel.recordcount gte 2>
									<cfset imagePlural = 'images'>
									<cfelse>
									<cfset imagePlural = 'image'>
								</cfif>
								<cfif localityImagesForCarousel.recordcount gt 0>
									<div class="col-12 #colClass# mx-md-auto mt-3">
										<div class="carousel_background border float-left w-100 p-3">
										<h3 class="mx-2">Locality  <span class="small">(#localityCt.recordcount#)</span></h3>
										 <div class="custom-nav text-center bg-white border-right border-left border-top border-bottom mb-1 px-1 pt-0 pb-1">
											<button type="button" class="border-0  btn-outline-primary" id="custom-prev3"> << previous </button>
											<input type="number" id="custom-input3" class="border border-light w-25 py-1 px-2 mt-1 text-center" placeholder="index">
											<button type="button" class="border-0 btn-outline-primary" id="custom-next3"> next >> </button>
										  </div>
										<div class="vslider w-100 float-left"  style="height: #localityImagesForCarousel.first_height#" id="vslider-base3">
											<cfset i=1>
											<cfloop query="localityImagesForCarousel">
												<div class="small95 my-1">#localityImagesForCarousel['alt'][i]# <br><a href="/MediaSet.cfm?media_id=#localityImagesForCarousel['media_id'][i]#">Media Details</a><br><a href="#media_uri#" target="_blank" title="click to open full image"><img src="#localityImagesForCarousel['media_uri'][i]#" class="mx-auto w-100 float-left h-auto"></a></div>
												<cfset i=i+1>
											</cfloop>
										</div>
									</div>
								</div>
								</cfif>
							</div>
						</div>
					</cfif>
											
 

		
<script>
(function () {
  "use strict";
  // example script
  function init() {
    // multiple
    window.defaultSliders = vanillaSlider(
      document.querySelectorAll('.vslider-default')
    )
    console.log('window.defaultSliders:', window.defaultSliders)
    var $input = document.getElementById('custom-input')
    var baseSlider = vanillaSlider(
      document.getElementById('vslider-base'), {
        autoplay: false,
        navigation: false,
        keyboardnavigation: false,
        swipenavigation: false,
        wheelnavigation: true,
        status: false,
        after: function (index, length) {
          $input.value = index +1
        }
      }
    )
    window.baseSlider = baseSlider
    // custom controls
    $input.addEventListener('change', function (e) {
      baseSlider.next(
        parseInt(e.target.value)
      )
    }, false)
    document.getElementById('custom-prev').addEventListener('click', function (e) {
      baseSlider.prev()
    }, false)
    document.getElementById('custom-next').addEventListener('click', function (e) {
      baseSlider.next()
    }, false)

    vanillaSlider(
      document.getElementById('vslider-custom'), {
        height: '20em',
        statusContent: function (i, all) {
          return i + 1
        },
      }
    )
  }
  document.addEventListener('DOMContentLoaded', init, false);
	}());	
	
(function () {
  "use strict";
  // example script
  function init() {
    // multiple
    window.defaultSliders = vanillaSlider(
      document.querySelectorAll('.vslider-default')
    )
    console.log('window.defaultSliders:', window.defaultSliders)
    var $input = document.getElementById('custom-input1')
    var baseSlider = vanillaSlider(
      document.getElementById('vslider-base1'), {
        autoplay: false,
        navigation: false,
        keyboardnavigation: false,
        swipenavigation: false,
        wheelnavigation: true,
        status: false,
        after: function (index, length) {
          $input.value = index +1
        }
      }
    )
    window.baseSlider = baseSlider
    // custom controls
    $input.addEventListener('change', function (e) {
      baseSlider.next(
        parseInt(e.target.value)
      )
    }, false)
    document.getElementById('custom-prev1').addEventListener('click', function (e) {
      baseSlider.prev()
    }, false)
    document.getElementById('custom-next1').addEventListener('click', function (e) {
      baseSlider.next()
    }, false)

    vanillaSlider(
      document.getElementById('vslider-custom1'), {
        height: '20em',
        statusContent: function (i, all) {
          return i + 1
        },
      }
    )
  }
  document.addEventListener('DOMContentLoaded', init, false);
	}());	
	
(function () {
  "use strict";
  // example script
  function init() {
    // multiple
    window.defaultSliders = vanillaSlider(
      document.querySelectorAll('.vslider-default')
    )
    console.log('window.defaultSliders:', window.defaultSliders)
    var $input = document.getElementById('custom-input2')
    var baseSlider = vanillaSlider(
      document.getElementById('vslider-base2'), {
        autoplay: false,
        navigation: false,
        keyboardnavigation: false,
        swipenavigation: false,
        wheelnavigation: true,
        status: false,
        after: function (index, length) {
          $input.value = index +1
        }
      }
    )
    window.baseSlider = baseSlider
    // custom controls
    $input.addEventListener('change', function (e) {
      baseSlider.next(
        parseInt(e.target.value)
      )
    }, false)
    document.getElementById('custom-prev2').addEventListener('click', function (e) {
      baseSlider.prev()
    }, false)
    document.getElementById('custom-next2').addEventListener('click', function (e) {
      baseSlider.next()
    }, false)

    vanillaSlider(
      document.getElementById('vslider-custom2'), {
        height: '20em',
        statusContent: function (i, all) {
          return i + 1
        },
      }
    )
  }
  document.addEventListener('DOMContentLoaded', init, false);
	}());
	
(function () {
  "use strict";
  // example script
  function init() {
    // multiple
    window.defaultSliders = vanillaSlider(
      document.querySelectorAll('.vslider-default')
    )
    console.log('window.defaultSliders:', window.defaultSliders)
    var $input = document.getElementById('custom-input3')
    var baseSlider = vanillaSlider(
      document.getElementById('vslider-base3'), {
        autoplay: false,
        navigation: false,
        keyboardnavigation: false,
        swipenavigation: false,
        wheelnavigation: true,
        status: false,
        after: function (index, length) {
          $input.value = index +1
        }
      }
    )
    window.baseSlider = baseSlider
    // custom controls
    $input.addEventListener('change', function (e) {
      baseSlider.next(
        parseInt(e.target.value)
      )
    }, false)
    document.getElementById('custom-prev3').addEventListener('click', function (e) {
      baseSlider.prev()
    }, false)
    document.getElementById('custom-next3').addEventListener('click', function (e) {
      baseSlider.next()
    }, false)

    vanillaSlider(
      document.getElementById('vslider-custom3'), {
        height: '20em',
        statusContent: function (i, all) {
          return i + 1
        },
      }
    )
  }
  document.addEventListener('DOMContentLoaded', init, false);
	}());	
/*!
/*!
/*!
 * vanillaSlider
 */
;
(function () {
  "use strict";

  // Polyfill for e.g. IE
  if (typeof Object.assign != 'function') {
    // Must be writable: true, enumerable: false, configurable: true
    Object.defineProperty(Object, "assign", {
      value: function assign(target, varArgs) { // .length of function is 2
        'use strict';
        if (target == null) { // TypeError if undefined or null
          throw new TypeError('Cannot convert undefined or null to object');
        }

        var to = Object(target);

        for (var index = 1; index < arguments.length; index++) {
          var nextSource = arguments[index];

          if (nextSource != null) { // Skip over if undefined or null
            for (var nextKey in nextSource) {
              // Avoid bugs when hasOwnProperty is shadowed
              if (Object.prototype.hasOwnProperty.call(nextSource, nextKey)) {
                to[nextKey] = nextSource[nextKey];
              }
            }
          }
        }
        return to;
      },
      writable: true,
      configurable: true
    });
  }

  function initSwipe($e, handler) {
    var POINTER_EVENTS = window.PointerEvent ? true : false
    var start = {};
    var end = {};
    var tracking = false;
    var thresholdTime = 500;
    var thresholdDistance = 100;

    function startHandler(e) {
      tracking = true;
      /* Hack - e.timeStamp is whack in Fx/Android */
      start.t = new Date().getTime();
      start.x = POINTER_EVENTS ? e.clientX : e.touches[0].clientX;
      start.y = POINTER_EVENTS ? e.clientY : e.touches[0].clientY;
    };

    function moveHandler(e) {
      if (tracking) {
        e.preventDefault();
        end.x = POINTER_EVENTS ? e.clientX : e.touches[0].clientX;
        end.y = POINTER_EVENTS ? e.clientY : e.touches[0].clientY;
      }
    }

    function endEvent(e) {
      if (tracking) {
        tracking = false;
        var now = new Date().getTime();
        var deltaTime = now - start.t;
        var deltaX = end.x - start.x;
        var deltaY = end.y - start.y;
        // if not too slow work out what the movement was
        if (deltaTime < thresholdTime) {
          if ((deltaX > thresholdDistance) && (Math.abs(deltaY) < thresholdDistance)) {
            handler('left')
          }
          else if ((-deltaX > thresholdDistance) && (Math.abs(deltaY) < thresholdDistance)) {
            handler('right')
          }
          else if ((deltaY > thresholdDistance) && (Math.abs(deltaX) < thresholdDistance)) {
            handler('up')
          }
          else if ((-deltaY > thresholdDistance) && (Math.abs(deltaX) < thresholdDistance)) {
            handler('down')
          }
        }
      }
    }
    if (POINTER_EVENTS) {
      $e.addEventListener('pointerdown', startHandler, false);
      $e.addEventListener('pointermove', moveHandler, false);
      $e.addEventListener('pointerup', endEvent, false);
      $e.addEventListener('pointerleave', endEvent, false);
      $e.addEventListener('pointercancel', endEvent, false);
    }
    else if (window.TouchEvent) {
      $e.addEventListener('touchstart', startHandler, false);
      $e.addEventListener('touchmove', moveHandler, false);
      $e.addEventListener('touchend', endEvent, false);
    }
  }


  var VanillaSlider = function ($slider, options) {
    var self = this
    var settings = this._settings = Object.assign({
      itemSelector: 'div',
      prefix: 'vslider-',

      // if null set height automatically else use height
      // number (=px) or explicit like "3em"
      height: null,

      rotation: true,
      autoplay: options.rotation === false ? false : true,
      initialTimeout: 4000,
      timeout: 8000,

      navigation: true,
      keyboardnavigation: true,
      // needs Hammer
      swipenavigation: true,
      swipedirection: 'h', // h or v
      wheelnavigation: false,
      onSwipeWheel: null,

      status: true,
      statusContent: function (index, length) {
        return '•';
      },
      i18n: {
        title: 'Carousel',
        navigation: 'Carousel navigation',
        next: 'next',
        prev: 'previous'
      },

      after: function (index, length) {}
    }, options);
    this._$slides = $slider.querySelectorAll(settings.itemSelector)
    this._$status
    this._active = 0
    this._timer = null

    if (typeof settings.height === 'number') {
      settings.height = settings.height + 'px'
    }


    var MAX = this._MAX = this._$slides.length

    // status
    if (settings.status) {
      this._$status = document.createElement('ol')
      this._$status.classList.add(settings.prefix + 'status')
      // not accessible as keyboard and button nav
      this._$status.setAttribute('role', 'tablist')

      for (var i = 0, upto = MAX; i < upto; i++) {
        (function (index) {
          var $i = document.createElement('li')

          if (index === 0) {
            $i.setAttribute('tabindex', '0')
          }
          $i.setAttribute('id', settings.prefix + 'tab$' + index)
          $i.setAttribute('role', 'tab')
          $i.setAttribute('aria-label', index)
          $i.setAttribute('aria-controls', settings.prefix + 'tabpanel$' + index)
          $i.classList.add(settings.prefix + 'status-item')

          if (i === 0) {
            $i.classList.add(settings.prefix + 'status-item-active')
          }

          $i.textContent = settings.statusContent(i, MAX)
          $i.addEventListener('click', function (e) {
            self.next(index)
          }, false)
          $i.addEventListener('keydown', function (e) {
            console.log(e.keyCode)
            if (e.keyCode === 13) {
              self.next(index)
            }
          }, false)
          self._$status.appendChild($i)
        }(i));
      }
      $slider.appendChild(self._$status)
    }


    // NAVIGATION

    if (settings.navigation) {
      var _$navigation = document.createElement('div')
      var _$prev = document.createElement('button')
      var _$next = document.createElement('button')

      if (!$slider.id) {
        $slider.id = this._settings.prefix + sliderIndex + '$' + Date.now();
      }
      _$navigation.setAttribute('aria-label', settings.i18n.navigation)
      _$navigation.setAttribute('aria-controls', $slider.id)
      _$navigation.classList.add(this._settings.prefix + 'nav')
      _$navigation.appendChild(_$prev)
      _$navigation.appendChild(_$next)

      _$prev.setAttribute('aria-label', settings.i18n.prev)
      _$prev.classList.add(this._settings.prefix + 'prev')
      _$prev.addEventListener('click', function (e) {
        self.prev()
      }, true)

      _$next.setAttribute('aria-label', settings.i18n.next)
      _$next.classList.add(this._settings.prefix + 'next')
      _$next.addEventListener('click', function (e) {
        self.next()
      }, true)

      $slider.appendChild(_$navigation)
    }

    if (settings.keyboardnavigation) {
      $slider.addEventListener('keydown', function (e) {
        var keyCode = e.keyCode

        switch (keyCode) {
          case 39:
          case 40:
            self.next()
            break
          case 37:
          case 38:
            self.prev()
            break
        }
      })
    }

    if (settings.swipenavigation) {
      $slider.style.touchAction = settings.swipedirection === 'h' ?
        'pan-y' : 'pan-x';

      initSwipe($slider, function (direction) {
        if (settings.swipedirection === 'h') {
          if (direction === 'left') {
            self.prev()
          }
          if (direction === 'right') {
            self.next()
          }
        }
        if (settings.swipedirection === 'v') {
          if (direction === 'up') {
            self.prev()
          }
          if (direction === 'down') {
            self.next()
          }
        }
      })
    }

    if (settings.wheelnavigation) {
      $slider.addEventListener('wheel', function (e) {
        requestAnimationFrame(function () {
          var next = e.deltaY > 0

          self[next ? 'next' : 'prev']()
          settings.onSwipeWheel && settings.onSwipeWheel(self._active, MAX, !next)
        })
        e.preventDefault()
      }, false)
    }

    window.addEventListener('resize', function (e) {
      requestAnimationFrame(function () {
        $slider.style.height = 'auto'
        $slider.style.height = settings.height || getComputedStyle($slider).height
      })
    })

    // start
    if (MAX > 1) {
      $slider.setAttribute('tabindex', '0')
      $slider.setAttribute('aria-label', settings.i18n.title)
      $slider.setAttribute('aria-live', 'polite')
      $slider.style.height = settings.height || getComputedStyle($slider).height
      ;
      [].forEach.call(this._$slides, function ($slide, i) {
        $slide.setAttribute('id', settings.prefix + 'tabpanel$' + i)
        $slide.setAttribute('role', 'tabpanel')
        $slide.setAttribute('aria-labelledby', settings.prefix + 'tab$' + i)
        if (i == 0) {
          $slide.setAttribute('aria-hidden', 'false')
        }
        else {
          $slide.setAttribute('aria-hidden', 'true')
        }
        $slide.classList.add(settings.prefix + 'item')
      })

      if (settings.autoplay) {
        setTimeout(function () {
          this._timer = setTimeout(
            function () {
              this.next()
            }.bind(this),
            settings.initialTimeout)
        }.bind(this), 100)
      }
    }
  }

  VanillaSlider.prototype._updateStatus = function () {
    if (this._settings.status) {
      var activeClass = this._settings.prefix + 'status-item-active'
      var $prevActive = this._$status.querySelector('.' + activeClass)
      var $active = this._$status.querySelector('li:nth-child(' + (this._active + 1) + ')')

      $prevActive.classList.remove(activeClass)
      $active.classList.add(activeClass)
      $prevActive.setAttribute('aria-selected', 'false')
      $active.setAttribute('aria-selected', 'true')
    }
  }

  VanillaSlider.prototype._getActive = function (back, index) {
    clearTimeout(this._timer)

    this._$slides[this._active].setAttribute('aria-hidden', 'true')

    if (index !== undefined) {
      this._active = index >= 0 && index < this._MAX ?
        index : this._MAX - 1
    }
    else {
      if (!back) {
        this._active = (this._active === this._$slides.length - 1) ? 0 : this._active + 1
      }
      else {
        this._active = (this._active === 0) ? this._$slides.length - 1 : this._active - 1
      }
    }
    return this._$slides[this._active]
  }

  VanillaSlider.prototype._finishAction = function ($active) {
    this._updateStatus()
    this._settings.after(this._active, this._MAX)
    if (this._settings.autoplay) {
      this._timer = setTimeout(function () {
        this.next()
      }.bind(this),
        this._settings.timeout)
    }
  }

  VanillaSlider.prototype.prev = function (index) {
    var prefix = this._settings.prefix

    if (index !== undefined && index === this._active) {
      return true
    }
    else if (index === undefined && !this._settings.rotation && this._active === 0) {
      return true
    }

    this._$slides[this._active].classList.add(prefix + 'before')

    var $active = this._getActive(true, index)

    $active.setAttribute('aria-hidden', 'true')
    $active.classList.add(prefix + 'direct')
    $active.classList.remove(prefix + 'before')
    getComputedStyle($active).opacity // DO IT!
    $active.setAttribute('aria-hidden', 'false')
    $active.classList.remove(prefix + 'direct')

    this._finishAction()
  }

  VanillaSlider.prototype.next = function (index) {
    var prefix = this._settings.prefix

    if (index !== undefined && index === this._active) {
      return true
    }
    else if (index === undefined && !this._settings.rotation && this._active === this._$slides.length - 1) {
      return true
    }

    var $active = this._getActive(false, index)

    $active.setAttribute('aria-hidden', 'true')
    $active.classList.add(prefix + 'direct')
    $active.classList.add(prefix + 'before')
    getComputedStyle($active).opacity // DO IT!
    $active.setAttribute('aria-hidden', 'false')
    $active.classList.remove(prefix + 'direct')
    $active.classList.remove(prefix + 'before')

    this._finishAction()
  }


  // used to generate slider ID
  var sliderIndex = 0

  function vanillaSlider($sliders, options) {
    var sliders = [];

    if ($sliders instanceof Node) {
      $sliders = [$sliders]
    }

    [].forEach.call($sliders, function ($slider, i) {
      sliders.push(
        new VanillaSlider($slider, options || {})
      )
      sliderIndex++;
    })
    return sliders.length > 1 ? sliders : sliders[0]
  }
  vanillaSlider.VERSION = 2.0

  window.vanillaSlider = vanillaSlider
}());											
</script>						
					<div class="row">
						<div id="mapper" class="col-12 h-100">
							<h2 class="mt-4">Heat Map Example</h2>


		
<script>
	let map, heatmap;

function initMap() {
  map = new google.maps.Map(document.getElementById("map"), {
    zoom: 4,
    center: { lat: 42.378765, lng: -71.115540 },
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
	<cfset arr = ArrayNew(1)>
	<cfloop query="states">new google.maps.LatLng(#states.dec_lat#,#states.dec_long#),
	</cfloop>
		return #serializeJson#;
		}
</script>

<div id="floating-panel">
	<button id="toggle-heatmap">Toggle Heatmap</button>
	<button id="change-gradient">Change gradient</button>
	<button id="change-radius">Change radius</button>
	<button id="change-opacity">Change opacity</button>
</div>
<div id="map"></div>

<!-- Async script executes immediately and must be after any DOM elements used in callback. -->
<script src="https://maps.googleapis.com/maps/api/js?key=#application.gmap_api_key#&callback=initMap&libraries=visualization&v=weekly" async></script>
						</div>
					</div>

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