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
	text-align: center;
	font-family: "Roboto", "sans-serif";
	line-height: 30px;
	background-color: #fff;
	border: 1px solid #999;
	left: 25%;
	left: 0;
	padding: 5px;
	padding-left: 10px;
	position: relative;
	top: 10px;
	z-index: 5;
}
.vslider {
  	position: relative;
/*	overflow: auto;*/
	width: 100%;
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
	resize: vertical;
	overflow:auto;
	font-size: 1rem;
}
div.vslider-item[aria-hidden='false'] {
  	z-index: 30;
  	opacity: 1.0;
  	transform: translateX(0);
}
div.vslider-item[aria-hidden="true"]{
	display:block;
}
.vslider-before {
 	z-index: 10;
  	opacity: 0;
  	transform: translateX(0%);
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
	color: #000;
	background: #000;
	border: 0.1em solid #fff;
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
	background: blue;
  opacity: 0.6;
	opacity: 0.3;
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
}
/* some basic style */
.vslider {
  color: #191717;
  background-color: #fff;
  font-weight: 600;
  text-align: center;
  margin-bottom: .75rem;
}
/* custom status and navigation */
.vslider-customstatus .vslider-status > li {
  color: #fff;
  padding: 0.25em;
  border-radius: 0.25em;
}
.vslider-customstatus .vslider-prev,
.vslider-customstatus .vslider-next {
  color: transparent;
  width: 0;
  height: 0;
  border-top: 0.5em solid transparent;
  border-bottom: 0.5em solid transparent;
}
.vslider-customstatus .vslider-prev {
  border-right: 1em solid #000;
}
.vslider-customstatus .vslider-next {
  border-left: 1em solid #000;
}
.custom-input {
	text-align: center;
	width:53px; 
}
/* custom animation */
.vslider-trans {
  min-height: 50vh;
  background-color: transparent;
}
.vslider-trans .vslider-item {
  background: no-repeat center;
  background-size: cover;
  transition: z-index 0s,
  transform 1s ease-in-out;
  opacity: 1;
  transform: rotateY(90deg);
}
.vslider-trans .vslider-active, .vslider-trans .vslider-item[aria-hidden='false'] {
  transform: rotateY(0deg);
}
.vslider-trans .vslider-before  {
  transform: rotateY(-90deg);
}
.message { 
	padding-top: 25%;
	padding-bottom: 25%;
	font-size: 2rem;
}
.vslider::-webkit-scrollbar, .vslider-item::-webkit-scrollbar {
    width: 10px;
}
.vslider::-webkit-scrollbar-track, .vslider-item::-webkit-scrollbar-track {
    -webkit-box-shadow: inset 0 0 4px rgba(0,0,0,0.3);
	background: aliceblue;
}
.vslider::-webkit-scrollbar-thumb, .vslider-item::-webkit-scrollbar-thumb {
	background-color: lightgrey;
	border-radius: 10px;
}
</style>
	<cfset maxSpecimens = 11000>
	<cfset maxRandomSpecimenImages = 12>
	<cfset maxRandomOtherImages = 10>
	<cfset otherImageTypes = 0>
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
		<!---for specimen record grid--->
		<cfquery name="specimens" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			SELECT * FROM (
				SELECT DISTINCT flat.guid, flat.scientific_name
				FROM
					underscore_relation 
					left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat 
						on underscore_relation.collection_object_id = flat.collection_object_id
				WHERE underscore_relation.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
					and flat.guid is not null
				ORDER BY flat.guid asc
				) 
			WHERE rownum <= <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#maxSpecimens#">
		</cfquery>
		<!---for specimen image count--->
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
			<cfset otherimagetypes = 0>
		</cfif>
		<!--- obtain a random set of specimen images, limited to a small number/for carousel --->
		<cfquery name="specimenImagesForCarousel" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="specimenImagesForCarousel_result">
			SELECT * FROM (
				SELECT distinct media.media_id, media.media_uri, 
					MCZBASE.get_media_descriptor(media.media_id) as alt, 
					MCZBASE.get_medialabel(media.media_id,'width')/(sum(MCZBASE.get_medialabel(media.media_id,'width')) over (partition by MCZBASE.get_medialabel(media.media_id,'height'))) as Ratio
				FROM
					underscore_collection
					left join underscore_relation on underscore_collection.underscore_collection_id = underscore_relation.underscore_collection_id
					left join cataloged_item
						on underscore_relation.collection_object_id = cataloged_item.collection_object_id
					left join media_relations
						on media_relations.related_primary_key = underscore_relation.collection_object_id
					left join media on media_relations.media_id = media.media_id							
				WHERE underscore_collection.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
					AND media_relations.media_relationship = 'shows cataloged_item'
					AND media.media_type = 'image'
					AND (media.mime_type = 'image/jpeg' OR media.mime_type = 'image/png')
				ORDER BY Ratio asc, DBMS_RANDOM.RANDOM
				) 
			WHERE rownum <= <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#maxRandomSpecimenImages#">
		</cfquery>
		<cfif specimenImagesForCarousel.recordcount GT 0>
			<cfset otherImageTypes = 0>
		</cfif>
		<cfquery name="agentImagesForCarousel" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="agentImagesForCarousel_result">
			SELECT * FROM (
				SELECT DISTINCT media.media_id, media.media_uri, 
					MCZBASE.get_media_descriptor(media.media_id) as alt, 
					MCZBASE.get_medialabel(media.media_id,'width')/(sum(MCZBASE.get_medialabel(media.media_id,'width')) over (partition by MCZBASE.get_medialabel(media.media_id,'height'))) as Ratio
				FROM
					underscore_collection
					left join underscore_relation on underscore_collection.underscore_collection_id = underscore_relation.underscore_collection_id
					left join cataloged_item 
						on underscore_relation.collection_object_id = cataloged_item.collection_object_id
					left join collector on underscore_relation.collection_object_id = collector.collection_object_id
					left join media_relations on collector.agent_id = media_relations.related_primary_key
					left join media on media_relations.media_id = media.media_id
				WHERE underscore_collection.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
					AND collector.collector_role = 'c'
					AND media_relations.media_relationship = 'shows agent'
					AND media.media_type = 'image'
					AND (media.mime_type = 'image/jpeg' OR media.mime_type = 'image/png')
					AND media.auto_host = 'mczbase.mcz.harvard.edu'
				ORDER BY Ratio asc, DBMS_RANDOM.RANDOM
			) 
			WHERE rownum <= <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#maxRandomOtherImages#">
			<!---PUT IN SAMPLE(99) and Took off DBMS_RANDOM.RANDOM until a large number of images are related with "show agent" since it slows query down--->
		</cfquery>
		<cfif agentImagesForCarousel.recordcount GT 0>
			<cfset otherImageTypes = otherImageTypes + 1>
		</cfif>
		<cfquery name="collectingImagesForCarousel" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="collectingImagesForCarousel_result">  
			SELECT * FROM (
				SELECT DISTINCT media_uri, media.media_id,
					MCZBASE.get_media_descriptor(media.media_id) as alt, 
					MCZBASE.get_medialabel(media.media_id,'width')/(sum(MCZBASE.get_medialabel(media.media_id,'width')) over (partition by MCZBASE.get_medialabel(media.media_id,'height'))) as Ratio	
				FROM
					underscore_collection
					left join underscore_relation on underscore_collection.underscore_collection_id = underscore_relation.underscore_collection_id
					left join cataloged_item 
						on underscore_relation.collection_object_id = cataloged_item.collection_object_id
					left join collecting_event 
						on collecting_event.collecting_event_id = cataloged_item.collecting_event_id 
					left join media_relations 
						on collecting_event.collecting_event_id = media_relations.related_primary_key 
					left join media on media_relations.media_id = media.media_id 
				WHERE underscore_collection.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
					AND (media_relations.media_relationship = 'shows collecting_event' or media_relations.media_relationship = 'locality')
					AND media.media_type = 'image'
					AND (media.mime_type = 'image/jpeg' OR media.mime_type = 'image/png')
					AND media.auto_host = 'mczbase.mcz.harvard.edu'
				ORDER BY Ratio asc, DBMS_RANDOM.RANDOM
			) 
			WHERE rownum <= <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#maxRandomOtherImages#">
			<!---Took off DBMS_RANDOM.RANDOM until a large number of images are related with "show agent" since it slows query down--->
		</cfquery>
		<cfif collectingImagesForCarousel.recordcount GT 0>
			<cfset otherImageTypes = otherImageTypes + 1>
		</cfif>

		<main class="py-3" id="content">
			<div class="row mx-0">
				<article class="col-12">
					<section class="feature">
						<div class="row mx-0">
							<div class="col-12 px-1 border-dark mt-4">
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
					</section>
					<section class="spec-table row mx-0">
					<!--- Grid Related code is in section above (fills into id = "jqxgrid" div) along with search handlers --->
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
								<h2 class="float-left">Specimen Records 
									<span class="small">
										<a href="/SpecimenResults.cfm?underscore_coll_id=#encodeForURL(underscore_collection_id)#" target="_blank">#specimens.recordcount#</a>
									</span>
								</h2>
								<div id="btnContainer" class="ml-3 float-left"></div>
							</div>
							<div class="container-fluid">
								<div class="row">
									<div class="col-12 px-1 mb-3">
										<div class="row mt-0 mx-0"> 
											<div id="jqxgrid"></div>
										</div>
									</div>
								</div>
							</div>
					<!---end specimen grid---> 
					</section>
					<div class="row mx-0">
					<cfif specimenImagesForCarousel.recordcount gt 0 or agentImagesForCarousel.recordcount gt 0 OR points.recordcount gt 0>
					<div class="mt-1 col-12 col-md-6 float-left px-0 mt-3 mb-3">	
							<section class="imagesLeft">
							<h2 class="mt-3 mx-3">Images <span class="smaller">(a small sample of total is shown&mdash;click refresh to see more images here or visit specimen records) </span></h2>
								<cfif specimenImagesForCarousel.recordcount gt 0>
									<div class="col-12 px-1">
										<div class="carousel_background border rounded float-left w-100 p-2">
											<h3 class="mx-2 text-center">#specimenImgs.recordcount# Specimens</h3>
											<div class="vslider w-100 float-left bg-light" id="vslider-base">
												<cfset i=1>
												<cfloop query="specimenImagesForCarousel">
													<cfset alttext = specimenImagesForCarousel['alt'][i]>
													<cfset alttextTrunc = rereplace(alttext, "[[:space:]]+", " ", "all")>
													<cfif len(alttextTrunc) gt 140>
														<cfset trimmedAltText = left(alttextTrunc, 140)>
														<cfset trimmedAltText &= "...">
													<cfelse>
														<cfset trimmedAltText = altTextTrunc>
													</cfif>
													<div class="w-100 bg-light float-left px-3 h-auto">
														<a class="d-block pt-2" href="/MediaSet.cfm?media_id=#specimenImagesForCarousel['media_id'][i]#">Media Details</a>
														<cfset src=specimenImagesForCarousel['media_uri'][i]>
														<cfif fileExists(#src#)>
															<a href="#media_uri#" target="_blank" class="d-block my-1 w-100" title="click to open full image">
																<img src="#src#" class="mx-auto" alt="#trimmedAltText#" height="100%" width="100%">
															</a>
															<p class="mt-2 bg-light small">#trimmedAltText#</p>
														<cfelse>
															<ul class="bg-dark px-0 list-unstyled">
																<li>
																	<h3 class="text-white mx-auto message">
																		No image is stored
																	</h3>
																</li>
															</ul>
														</cfif>
													</div>
												<cfset i=i+1>
												</cfloop>
											</div>
											<div class="custom-nav text-center small mb-1 bg-white pt-0 pb-1">
												<button type="button" class="border-0 btn-outline-primary rounded" id="custom-prev"> << prev </button>
												<input type="number" id="custom-input" class="custom-input border data-entry-input d-inline border-light" placeholder="index">
												<button type="button" class="border-0 btn-outline-primary rounded" id="custom-next"> next &nbsp; >> </button>
											</div>
										</div>
									</div>
								</cfif>	
								<div class="other-images">
									<!--- figure out widths of sub blocks, adapt to number of blocks --->
									<cfswitch expression="#otherImageTypes#">
										<cfcase value="1">
											<cfset colClass = "col-md-12 mx-auto float-none">
										</cfcase>
										<cfcase value="2">
											<cfset colClass = "col-md-6 mx-auto float-left">
										</cfcase>
										<cfcase value="3">
											<cfset colClass = "col-md-12 col-xl-4 float-left">
										</cfcase>
										<cfdefaultcase>
											<cfset colClass = "col-md-12 col-xl-4 float-left">
										</cfdefaultcase>
									</cfswitch>
									<div class="row bottom px-3"><!---for all three other image blocks--->
										<div class="col-12 px-0 mt-2 mb-3"><!---for all three other image blocks--->
											<cfif agentImagesForCarousel.recordcount GT 0>
												<cfquery name="agentCt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="agentCt">
													SELECT DISTINCT media.media_id
													FROM
														underscore_collection
														left join underscore_relation on underscore_collection.underscore_collection_id = underscore_relation.underscore_collection_id
														left join cataloged_item
															on underscore_relation.collection_object_id = cataloged_item.collection_object_id
														left join collector on underscore_relation.collection_object_id = collector.collection_object_id
														left join media_relations on collector.agent_id = media_relations.related_primary_key
														left join media on media_relations.media_id = media.media_id
													WHERE underscore_collection.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
														AND collector.collector_role = 'c'
														AND media_relations.media_relationship = 'shows agent'
														AND media.media_type = 'image'
														AND (media.mime_type = 'image/jpeg' OR media.mime_type = 'image/png')
														AND media.auto_host = 'mczbase.mcz.harvard.edu'
												</cfquery>													
												<div class="col-12 px-1 #colClass# mx-md-auto my-3"><!---just for agent block--->
													<div class="carousel_background border rounded float-left w-100 p-2">
														<h3 class="mx-2 text-center">#agentCt.recordcount# Agents </h3>
														<div class="vslider w-100 float-left bg-light" id="vslider-base1">
															<cfset i=1>
															<cfloop query="agentImagesForCarousel">
																<cfset alttext = agentImagesForCarousel['alt'][i]>
																<cfset alttextTrunc = rereplace(alttext, "[[:space:]]+", " ", "all")>
																<cfif len(alttextTrunc) gt 100>
																	<cfset trimmedAltText = left(alttextTrunc, 100)>
																	<cfset trimmedAltText &= "...">
																<cfelse>
																	<cfset trimmedAltText = altTextTrunc>
																</cfif>
																<div class="w-100 float-left px-3 h-auto">
																	<a class="d-block pt-2" href="/MediaSet.cfm?media_id=#agentImagesForCarousel['media_id'][i]#">Media Details</a>
																	<cfset src=agentImagesForCarousel['media_uri'][i]>
																	<cfif fileExists(#src#)>
																		<a href="#media_uri#" target="_blank" class="d-block my-1 w-100" title="click to open full image">
																			<img src="#src#" class="mx-auto" alt="#trimmedAltText#" height="100%" width="100%">
																		</a>
																		<p class="mt-2 small bg-light">#trimmedAltText#</p>
																	<cfelse>
																		<ul class="bg-dark px-0 list-unstyled">
																			<li>
																				<h3 class="text-white mx-auto" style="padding-top: 25%;padding-bottom: 25%;font-size: 2rem;">
																					No image is stored
																				</h3>
																			</li>
																		</ul>
																	</cfif>
																</div>
																<cfset i=i+1>
															</cfloop>
														</div>
														<div class="custom-nav text-center small bg-white mb-1 pt-0 pb-1">
															<button type="button" class="border-0 btn-outline-primary rounded" id="custom-prev1"> << prev </button>
															<input type="number" id="custom-input1" class="custom-input data-entry-input d-inline border border-light" placeholder="index">
															<button type="button" class="border-0 btn-outline-primary rounded" id="custom-next1"> next &nbsp; >> </button>
														</div>
													</div>
												</div>
											</cfif>
											<cfif collectingImagesForCarousel.recordcount gt 0>
												<cfquery name="collectingCt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="collectingImagesForCarousel_result">  
													SELECT DISTINCT media.media_id
													FROM
														underscore_collection
														left join underscore_relation on underscore_collection.underscore_collection_id = underscore_relation.underscore_collection_id
														left join cataloged_item
															on underscore_relation.collection_object_id = cataloged_item.collection_object_id
															left join collecting_event 
															on collecting_event.collecting_event_id = cataloged_item.collecting_event_id 
															left join media_relations 
															on collecting_event.collecting_event_id = media_relations.related_primary_key 
														left join media on media_relations.media_id = media.media_id
													WHERE underscore_collection.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
														AND media_relations.media_relationship = 'shows collecting_event'
														AND media.media_type = 'image'
														AND (media.mime_type = 'image/jpeg' OR media.mime_type = 'image/png')
														AND media.media_uri LIKE '%mczbase.mcz.harvard.edu%'
												</cfquery>
												<cfif collectingCt.recordcount GT 0>
													<cfset otherImageTypes = otherImageTypes + 1>
												</cfif>	
												<div class="col-12 px-1 #colClass# mx-md-auto my-3">
													<div class="carousel_background border rounded float-left w-100 p-2">
													<h3 class="mx-2 text-center">#collectingCt.recordcount# Collecting
													</h3>
														<div class="vslider w-100 float-left bg-light" id="vslider-base2">
															<cfset i=1>
															<cfloop query="collectingImagesForCarousel">
																<cfset alttext = collectingImagesForCarousel['alt'][i]>
																<cfset alttextTrunc = rereplace(alttext, "[[:space:]]+", " ", "all")>
																<cfif len(alttextTrunc) gt 100>
																	<cfset trimmedAltText = left(alttextTrunc, 100)>
																	<cfset trimmedAltText &= "...">
																<cfelse>
																	<cfset trimmedAltText = altTextTrunc>
																</cfif>
																<div class="w-100 float-left px-3 h-auto">
																	<a class="d-block pt-2" href="/MediaSet.cfm?media_id=#collectingImagesForCarousel['media_id'][i]#">Media Details</a>
																	<cfset src=collectingImagesForCarousel['media_uri'][i]>
																	<cfif fileExists(#src#)>
																		<a href="#media_uri#" target="_blank" class="d-block my-1 w-100" title="click to open full image">
																			<img src="#src#" class="mx-auto" alt="#trimmedAltText#" height="100%" width="100%">
																		</a>
																		<p class="mt-2 small bg-light">#trimmedAltText#</p>
																	<cfelse>
																		<ul class="bg-dark px-0 list-unstyled">
																			<li>
																				<h3 class="text-white mx-auto message">
																					No image is stored
																				</h3>
																			</li>
																		</ul>
																	</cfif>
																</div>
																<cfset i=i+1>
															</cfloop>
														</div>
														<div class="custom-nav small text-center bg-white mb-1 pt-0 pb-1">
															<button type="button" class="border-0 btn-outline-primary rounded" id="custom-prev2"> << prev </button>
															<input type="number" id="custom-input2" class="custom-input data-entry-input d-inline border border-light" placeholder="index">
															<button type="button" class="border-0 btn-outline-primary rounded" id="custom-next2"> next &nbsp; >> </button>
														</div>
													</div>
												</div>
											</cfif>
										</div>
									</div>
								</div>
							</section>
																
							<!---///////////////////////////////--->
							<!---/// HIDE HEAT MAP FOR NOW ///// --->
							<!---///////////////////////////////--->
							<!---////////// BELOW //////////////--->
							<!---///////////////////////////////--->									
							<section class="heatmap">
								<cfquery name="points" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="points_result">
									SELECT Distinct lat_long.locality_id,lat_long.dec_lat as Latitude, lat_long.DEC_LONG as Longitude 
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
								<h2 class="mt-4 text-left">Heat Map Example</h2>
								<script>
									function initMap() {
										var heatmapData = [
										<cfloop query="points">
											new google.maps.LatLng(#points.Latitude#,#points.Longitude#),
										</cfloop>
										];
										var Cambridge = new google.maps.LatLng(42.378765, -71.115540);
										map = new google.maps.Map(document.getElementById('map'), {
											center: Cambridge,
											zoom: 4,
											mapTypeId: 'satellite'
										});
										var heatmap = new google.maps.visualization.HeatmapLayer({
											data: heatmapData
										});
										heatmap.setMap(map);
									}//end InitMap
								</script>

								<div id="map" class="h-100"></div>
								<!-- Async script executes immediately and must be after any DOM elements used in callback. -->
								<script src="https://maps.googleapis.com/maps/api/js?key=#application.gmap_api_key#&callback=initMap&libraries=visualization" async></script>

							</section><!--- end images & heat map---> 	
						<!---///////////////////////////////--->
						<!---/// HIDE HEAT MAP FOR NOW ///// --->
						<!---///////////////////////////////--->
						<!---/////////// ABOVE /////////////--->
						<!---///////////////////////////////--->	
					</div>	
					</cfif>
																

					<section class="overview-links col mt-4 float-left">
						<div class=""> 
							<!--- This is either a full width or half width col, depending on presence/absence of has any kind of image col --->
							<div class="my-2 py-3 border-bottom-black">
							
									<h2 class="mt-3">Overview</h2>
								<cfif len(getNamedGroup.description) GT 0 >
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
					</section>
					</div>
				</article>
			</div>
		</main>
	</cfloop>
<script>
//  carousel fix for specimen images on small screens below.  I tried to fix this with the ratio select added to the query but that only works if there are a lot of images to choose from; for small images pools, where the most common ratio cannot be selected, this may still help.	
$(window).on('load resize', function () {
  var w = $(window).width();
  $("##vslider-item")
    .css('max-height', w > 1280 ? 685 : w > 480 ? 400 : 315);
});
	
//  carousel for specimen images below with custom-input, vslider-base, etc.
(function () {
  "use strict";
  function init() {
    var $input = document.getElementById('custom-input')
    var baseSlider = vanillaSlider(
      document.getElementById('vslider-base'), {
        autoplay: false,
        navigation: false,
        keyboardnavigation: false,
        swipenavigation: false,
        wheelnavigation: true,
		height: '100%', // setting height to null leaves it free to be calculated (line 1348);  need max height code for $slider there;
        status: false,
        after: function (index, length) {
          $input.value = index
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
  }
  document.addEventListener('DOMContentLoaded', init, false);
}());
	
	
//  carousel for agent images below with custom-input1, vslider-base1, etc.
(function () {
  "use strict";
  function init() {
    var $input = document.getElementById('custom-input1')
    var baseSlider = vanillaSlider(
      document.getElementById('vslider-base1'), {
        autoplay: false,
        navigation: false,
        keyboardnavigation: false,
        swipenavigation: false,
        wheelnavigation: true,
		height: '100%', // setting height to null leaves it free to be calculated (line 1348)
        status: false,
        after: function (index, length) {
          $input.value = index
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
  }
  document.addEventListener('DOMContentLoaded', init, false);
}());
	
//  carousel for collecting and locality images below with custom-input2, vslider-base2, etc. [There aren't many connected to specimen records right now so I lumped them together. It made for a better presentation.  We can change it later if we have more media relationships.]
(function () {
  "use strict";
  function init() {
    var $input = document.getElementById('custom-input2')
    var baseSlider = vanillaSlider(
      document.getElementById('vslider-base2'), {
        autoplay: false,
        navigation: false,
        keyboardnavigation: false,
        swipenavigation: false,
        wheelnavigation: true,
        status: false,
		height: null, // setting height to null leaves it free to be calculated (line 1348)
        after: function (index, length) {
          	$input.value = index
			
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
  }
  document.addEventListener('DOMContentLoaded', init, false);
}());
	
	
//  carousel for javascript main code below	
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
      height: null,  // setting height to null leaves it free to be calculated (line 1348)
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
      status: false,
      statusContent: function (index, length) {
        return '•';
      },
      i18n: {
        title: 'carousel for images',
        navigation: 'carousel navigation',
        next: 'next',
        prev: 'previous'
      },
      after: function (index, length) {}
    }, options);
    this._$slides = $slider.querySelectorAll(settings.itemSelector)
    this._$status
    this._active = 0
    this._timer = null

    var MAX = this._MAX = this._$slides.length

	if (typeof settings.height === 'number') {
      settings.height = settings.height + 'px'
    } 
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
        $slider.style.height = settings.height || getComputedStyle($slider).height //this is where max height should be found or within line 1344 {} (MHK)
      })
    })
    // start
    if (MAX > 1) {
      $slider.setAttribute('tabindex', '0')
      $slider.setAttribute('aria-label', settings.i18n.title)
      $slider.setAttribute('aria-live', 'polite')
      $slider.style.height = settings.height || getComputedStyle($slider).height;
		
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
</cfoutput>
<cfinclude template = "/shared/_footer.cfm">
