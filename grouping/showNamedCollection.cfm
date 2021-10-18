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
	<cfelse>
		<!--- either no such group, or user does not have access rights --->
		<cfthrow message="Named group not recognized.">
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
	border-radius: 5px;
	padding: 0 0 3px 0;
	position: relative;
	line-height: 20px;
	float:left;
	width: auto;
	margin: 0 auto;
	z-index: 5;
}
#map button {
	border: 1px solid transparent;
	outline: 1px solid transparent;
}
#map button:focus {
	outline: 2px solid rgb(0 123 255 / 75%);
}
.vslider {
	position: relative;
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

@media screen and (max-width: 1199px) {
	#map {
		height: 400px;
	}
}
@media screen and (max-width: 480px) {
	#map {
		height: 350px;
	}
}
@media screen and (min-width: 1200px) {
	#map {
		height: 600px;
	}
}
</style>
<cfset maxSpecimens = 11000>
<cfset maxRandomSpecimenImages = 300>
<cfset maxRandomOtherImages = 300>
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
		<cfquery name="specimens" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#CreateTimespan(24,0,0,0)#">
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
		<cfset otherimagetypes = 0>
		<cfquery name="specimenImagesForCarousel_raw" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="specimenImagesForCarousel_result" cachedwithin="#CreateTimespan(24,0,0,0)#">
			SELECT distinct media.media_id, 
				media.media_uri, 
				MCZBASE.get_media_descriptor(media.media_id) as alt,
				MCZBASE.is_media_encumbered(media.media_id)  as encumb
			FROM
				underscore_collection
				left join underscore_relation on underscore_collection.underscore_collection_id = underscore_relation.underscore_collection_id
				left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat 
					on underscore_relation.collection_object_id = flat.collection_object_id
				left join media_relations
					on media_relations.related_primary_key = underscore_relation.collection_object_id
				left join media on media_relations.media_id = media.media_id							
			WHERE underscore_collection.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
				AND media_relations.media_relationship = 'shows cataloged_item'
				AND media.media_type = 'image'
				AND (media.mime_type = 'image/jpeg' OR media.mime_type = 'image/png')
				AND flat.guid is not null
		</cfquery>
		<cfquery name="specimenImagesForCarousel" dbtype="query">
			SELECT * 
			FROM specimenImagesForCarousel_raw 
			WHERE encumb < 1
		</cfquery>
		<cfset imageSetMetadata = "[]">
		<cfif specimenImagesForCarousel.recordcount GT 0>
			<cfset otherImageTypes = 0>
			<cfset imageSetMetadata = "[">
			<cfset comma = "">
			<cfloop query="specimenImagesForCarousel">
				<cfset altEscaped = replace(replace(alt,"'","&##8217;","all"),'"',"&quot;","all") >
				<cfset imageSetMetadata = '#imageSetMetadata##comma#{"media_id":"#media_id#","media_uri":"#media_uri#","alt":"#altEscaped#"}'>
				<cfset comma = ",">
			</cfloop>
			<cfset imageSetMetadata = "#imageSetMetadata#]">
		</cfif>
		<script>
			var specimenImageSetMetadata = JSON.parse('#imageSetMetadata#');
			var currentSpecimenImage = 1;
		</script>
		<cfquery name="agentImagesForCarousel_raw" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="agentImagesForCarousel_result" cachedwithin="#CreateTimespan(24,0,0,0)#">
			SELECT DISTINCT media.media_id, media.media_uri, 
				MCZBASE.get_media_descriptor(media.media_id) as alt,
				MCZBASE.is_media_encumbered(media.media_id)  as encumb
			FROM
				underscore_collection
				left join underscore_relation on underscore_collection.underscore_collection_id = underscore_relation.underscore_collection_id
				left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat 
					on underscore_relation.collection_object_id = flat.collection_object_id
				left join collector on underscore_relation.collection_object_id = collector.collection_object_id
				left join media_relations on collector.agent_id = media_relations.related_primary_key
				left join media on media_relations.media_id = media.media_id
			WHERE underscore_collection.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
				AND collector.collector_role = 'c'
				AND media_relations.media_relationship = 'shows agent'
				AND media.media_type = 'image'
				AND (media.mime_type = 'image/jpeg' OR media.mime_type = 'image/png')
				AND media.auto_host = 'mczbase.mcz.harvard.edu'
				AND flat.guid IS NOT NULL
		</cfquery>
		<cfquery name="agentImagesForCarousel" dbtype="query">
			SELECT * 
			FROM agentImagesForCarousel_raw 
			WHERE encumb < 1
		</cfquery>
		<cfset imageSetMetadata = "[]">
		<cfif agentImagesForCarousel.recordcount GT 0>
			<cfset otherImageTypes = otherImageTypes + 1>
			<cfset imageSetMetadata = "[">
			<cfset comma = "">
			<cfloop query="agentImagesForCarousel">
				<cfset altEscaped = replace(replace(alt,"'","&##8217;","all"),'"',"&quot;","all") >
				<cfset imageSetMetadata = '#imageSetMetadata##comma#{"media_id":"#media_id#","media_uri":"#media_uri#","alt":"#altEscaped#"}'>
				<cfset comma = ",">
			</cfloop>
			<cfset imageSetMetadata = "#imageSetMetadata#]">
		</cfif>
		<script>
			var agentImageSetMetadata = JSON.parse('#imageSetMetadata#');
			var currentAgentImage = 1;
		</script>
		<cfquery name="collectingImagesForCarousel_raw" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="collectingImagesForCarousel_result" cachedwithin="#CreateTimespan(24,0,0,0)#">
			SELECT DISTINCT media_uri, media.media_id,
				MCZBASE.get_media_descriptor(media.media_id) as alt,
				MCZBASE.is_media_encumbered(media.media_id)  as encumb
			FROM
				underscore_collection
				left join underscore_relation on underscore_collection.underscore_collection_id = underscore_relation.underscore_collection_id
				left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat 
					on underscore_relation.collection_object_id = flat.collection_object_id
				left join collecting_event 
					on flat.collecting_event_id = collecting_event.collecting_event_id 
				left join media_relations 
					on collecting_event.collecting_event_id = media_relations.related_primary_key 
				left join media on media_relations.media_id = media.media_id 
			WHERE underscore_collection.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
				AND (media_relations.media_relationship = 'shows collecting_event' or media_relations.media_relationship = 'locality')
				AND media.media_type = 'image'
				AND (media.mime_type = 'image/jpeg' OR media.mime_type = 'image/png')
				AND media.auto_host = 'mczbase.mcz.harvard.edu'
		</cfquery>
		<cfquery name="collectingImagesForCarousel" dbtype="query">
			SELECT * 
			FROM collectingImagesForCarousel_raw 
			WHERE encumb < 1
		</cfquery>
		<cfset imageSetMetadata = "[]">
		<cfif collectingImagesForCarousel.recordcount GT 0>
			<cfset otherImageTypes = otherImageTypes + 1>
			<cfset imageSetMetadata = "[">
			<cfset comma = "">
			<cfloop query="collectingImagesForCarousel">
				<cfset altEscaped = replace(replace(alt,"'","&##8217;","all"),'"',"&quot;","all") >
				<cfset imageSetMetadata = '#imageSetMetadata##comma#{"media_id":"#media_id#","media_uri":"#media_uri#","alt":"#altEscaped#"}'>
				<cfset comma = ",">
			</cfloop>
			<cfset imageSetMetadata = "#imageSetMetadata#]">
		</cfif>
		<script>
			var collectingImageSetMetadata = JSON.parse('#imageSetMetadata#');
			var currentCollectingImage = 1;
		</script>

		<cfquery name="points" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="points_result" cachedwithin="#CreateTimespan(24,0,0,0)#">
			SELECT distinct lat_long.locality_id,lat_long.dec_lat as Latitude, lat_long.DEC_LONG as Longitude 
			FROM locality
				left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat
					on flat.locality_id = locality.locality_id
				left join lat_long on lat_long.locality_id = flat.locality_id
				left join underscore_relation on underscore_relation.collection_object_id = flat.collection_object_id
				left join underscore_collection on underscore_relation.underscore_collection_id = underscore_collection.underscore_collection_id
			WHERE 
				underscore_collection.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
				and flat.guid IS NOT NULL
				and lat_long.dec_lat is not null
				and lat_long.accepted_lat_long_fg = 1
		</cfquery>

		<main class="py-3" id="content">
			<div class="row mx-0">
				<article class="col-12">
					<section class="feature">
						<!---  heading section with description of named group --->
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
						<!--- Specimen grid (code loads grid into id = "specimenjqxgrid" div) along with search handlers --->
						<script type="text/javascript">
							var cellsrenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
								if (value > 1) {
									return '<a href="/guid/'+value+'" target="_blank"><span style="margin: 4px; float: ' + columnproperties.cellsalign + '; color: ##0000ff;">' + value + '</span></a>';
								}
								else {
									return '<a href="/guid/'+value+'" target="_blank"><span style="margin: 4px; float: ' + columnproperties.cellsalign + '; color: ##007bff;">' + value + '</span></a>';
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
									},
									beforeprocessing: function (data) {
										source.totalrecords = #specimens.recordcount#;
										//if (data != null && data.length > 0) {
										//	source.totalrecords = data[0].recordcount;
										//}
									},
									sort: function () {
										$("##specimenjqxgrid").jqxGrid('updatebounddata','sort');
									},
									filter: function () {
										$("##specimenjqxgrid").jqxGrid('updatebounddata','filter');
									}
								};
								var dataAdapter = new $.jqx.dataAdapter(source);
								// initialize jqxGrid
								$("##specimenjqxgrid").jqxGrid(
								{
									width: '100%',
									autoheight: 'true',
									source: dataAdapter,
									filterable: true,
									showfilterrow: true,
									sortable: true,
									pageable: true,
									virtualmode: true,
									editable: false,
									pagesize: '5',
									pagesizeoptions: ['5','10','15','20','50','100'],
									columnsresize: false,
									autoshowfiltericon: false,
									autoshowcolumnsmenubutton: false,
									altrows: true,
									showtoolbar: false,
									enabletooltips: true,
									selectionmode: 'multiplecelladvanced',
									pageable: true,
									columns: [
										{ text: 'GUID', datafield: 'guid', width:'180', filtertype: 'input', cellsalign: 'left',cellsrenderer: cellsrenderer },
										{ text: 'Scientific Name', datafield: 'scientific_name', width:'250', filtertype: 'input' },
										{ text: 'Date Collected', datafield: 'verbatim_date', width:'150', filtertype: 'input' },
										{ text: 'Higher Geography', datafield: 'higher_geog', width:'350', filtertype: 'input' },
										{ text: 'Locality', datafield: 'spec_locality',width:'350', filtertype: 'input' },
										{ text: 'Other Catalog Numbers', datafield: 'othercatalognumbers',width:'250', filtertype: 'input' },
										{ text: 'Taxonomy', datafield: 'full_taxon_name', width:'350', filtertype: 'input' }
									],
									rendergridrows: function (obj) {
										return obj.data;
									}
								});
								var now = new Date();
								var nowstring = now.toISOString().replace(/[^0-9TZ]/g,'_');
								var filename = 'NamedGroup_results_' + nowstring + '.csv';
								$('##btnContainer').html('<a id="namedgroupcsvbutton" class="btn btn-xs btn-secondary px-3 py-1 m-0" aria-label="Export results to csv" href="/grouping/component/search.cfc?method=getSpecimensInGroupCSV&smallerfieldlist=true&underscore_collection_id=#underscore_collection_id#" >Export to CSV</a>');
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
										<div id="specimenjqxgrid"></div>
									</div>
								</div>
							</div>
						</div>
						<!---end specimen grid---> 
					</section>
					<div class="row mx-0">

						<cfif specimenImagesForCarousel.recordcount GT 0 OR agentImagesForCarousel.recordcount GT 0 OR points.recordcount GT 0 OR collectingImagesForCarousel.recordcount GT 0>
							<div class="col-12 col-md-6 float-left px-0 mt-4 mb-3">	
						<style>
							##vslider-base {
								margin: 0; 
								padding: 0;
								height: 100%; 
								overflow: hidden; 
							}

							section {
								height: 0%;
								box-sizing: border-box;
								transition: 0.5s;
								overflow: hidden; 
							}
							##vslider-base section.active { 
								height: 100%; 
							}

						</style>	
								<!--- specimen images --->
								<cfif specimenImagesForCarousel.recordcount gt 0>
									<section class="imagesLeft">
										<div class="col-12 px-1">
											<div class="carousel_background border rounded float-left w-100 p-2 mb-4">
												<h3 class="mx-2 text-center">#specimenImagesForCarousel.recordcount# Specimen Images</h3>
												<div class="vslider w-100 float-left bg-light" id="vslider-base">
											
													<cfloop query="specimenImagesForCarousel" startRow="1" endRow="1">
														<cfset specimen_media_uri = specimenImagesForCarousel.media_uri>
														<cfset specimen_media_id = specimenImagesForCarousel.media_id>
														<cfset specimen_alt = specimenImagesForCarousel.alt>
													</cfloop>
													
													<div class="w-100 bg-light float-left px-3 h-auto">
														<a id="specimen_detail_a" class="d-block pt-2" target="_blank" href="/MediaSet.cfm?media_id=#specimen_media_id#">Media Details</a>
														<cfset sizeType='&width=800&height=800'>
														<a id="specimen_media_a" href="#specimen_media_uri#" target="_blank" class="d-block my-1 w-100 active" title="click to open full image">
															<img id="specimen_media_img" src="/media/rescaleImage.cfm?media_id=#specimen_media_id##sizeType#" class="mx-auto" alt="#specimen_alt#" height="100%" width="100%">
														</a>
														<p id="specimen_media_desc" class="mt-2 bg-light small" style="height: 2rem;">#specimen_alt#</p>
													</div>
										
												</div>
												<div class="custom-nav text-center small mb-1 bg-white pt-0 pb-1">
													<button type="button" class="border-0 btn-outline-primary rounded" id="previous_specimen_image" > << prev </button>
													<input type="number" id="specimen_image_number" class="custom-input border data-entry-input d-inline border-light" value="1">
													<button type="button" class="border-0 btn-outline-primary rounded" id="next_specimen_image"> next &nbsp; >> </button>
												</div>
										
											</div>
										</div>
										<script>
											var lastSpecimenScrollTop = 0;
											function goPreviousSpecimen() { 
												currentSpecimenImage = goPreviousImage(currentSpecimenImage, specimenImageSetMetadata, "specimen_media_img", "specimen_media_desc", "specimen_detail_a", "specimen_media_a", "specimen_image_number","#sizeType#"); 
											}
											function goNextSpecimen() { 
												currentSpecimenImage = goNextImage(currentSpecimenImage, specimenImageSetMetadata, "specimen_media_img", "specimen_media_desc", "specimen_detail_a", "specimen_media_a", "specimen_image_number","#sizeType#"); 
											}
											function goSpecimen() { 
												currentSpecimenImage = goImage(currentSpecimenImage, targetSpecimenImage, specimenImageSetMetadata, "specimen_media_img", "specimen_media_desc", "specimen_detail_a", "specimen_media_a", "specimen_image_number","#sizeType#"); 
											}
											$(document).ready(function () {
												$("##previous_specimen_image").click(goPreviousSpecimen);
												$("##next_specimen_image").click(goNextSpecimen);
												$("##specimen_image_number").on("change",goSpecimen);
												$("##specimen_media_img").wheel(function(event) {
													event.preventDefault();
													var y = event.scrollTop;
													if (y>lastSpecimenScrollTop) { 
														goNextSpecimen();
													} else { 
														goPreviousSpecimen();
 													}
													lastSpecimenScrollTop = y; 
												});
											});
																	// jQuery Next or First / Prev or Last plugin

											$.fn.nextOrFirst = function(selector){
												var next = this.next(selector);
												return (next.length) ? next : this.prevAll(selector).last();
											};

											$.fn.prevOrLast = function(selector){
												var prev = this.prev(selector);
												return (prev.length) ? prev : this.nextAll(selector).last();
											};

											// Scroll Functions

											function scrollSection(parent, dir) {
												var active = "active",
													div = parent.find("."+active);
											  if (dir == "prev") {
												div.removeClass(active).prevOrLast().addClass(active);
											  } else {
												div.removeClass(active).nextOrFirst().addClass(active);
											  }
											}

											// Bind Scroll function to mouse wheel event

											$('##vslider-base').on('mousewheel wheel', function(e){
											  if (e.originalEvent.wheelDelta /120 > 0) { // scroll up event
												scrollSection($(this), "prev");
											  } else { // scroll down event
												scrollSection($(this));
											  }
											});
								
										</script>
									</section><!--- end specimen images ---> 	
								</cfif>	


								<!---  occurrence map --->
								<cfquery name="points2" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="points_result">
									SELECT median(lat_long.dec_lat) as mylat, median(lat_long.dec_long) as mylng 
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
								</cfquery>							
								<cfif points.recordcount gt 0>
									<script src="https://polyfill.io/v3/polyfill.min.js?features=default"></script>
									<section class="heatmap mt-2 float-left w-100">
										<script src="https://maps.googleapis.com/maps/api/js?key=#application.gmap_api_key#&callback=initMap&libraries=visualization" async></script>
										<script>
											let map, heatmap;
											function initMap() {
												var Cambridge = new google.maps.LatLng(#points2.mylat#, #points2.mylng#);
												map = new google.maps.Map(document.getElementById('map'), {
													center: Cambridge,
													zoom: 2,
													mapTypeControl: true,
													mapTypeControlOptions: {
														style: google.maps.MapTypeControlStyle.DROPDOWN_MENU,
														mapTypeIds: ["satellite", "terrain"],
													},
													mapTypeId: 'satellite'
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
											function toggleHeatmap(){
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
											function getPoints(){
												return [
												<cfloop query="points">
													new google.maps.LatLng(<cfif len(points.Latitude)gt 0>#points.Latitude#,#points.Longitude#<cfelse>42.378765,-71.115540</cfif>),
												</cfloop>
												]
											}
											//end InitMap
										</script>
										
										<div class="col-12 px-0 float-left">
											<div class="border rounded px-1 mx-1 pb-1">
												<h2 class="px-3 text-center pt-2">Heat Map of Georeferenced Specimen Locations</h2>
												<div id="map" class="w-100 rounded"></div>
												<div id="floating-panel" class="w-100 mx-auto">
													<button id="toggle-heatmap" class="mt-1 border-info rounded">Toggle Heatmap</button>
													<button id="change-gradient" class="mt-1 border-info rounded">Change gradient</button>
													<button id="change-radius" class="mt-1 border-info rounded">Change radius</button>
													<button id="change-opacity" class="mt-1 border-info rounded">Change opacity</button>
												</div>
											</div>
										</div>
										<!-- Async script executes immediately and must be after any DOM elements used in callback. -->
									</section><!--- end heat map---> 	
								</cfif>
				
								<section class="otherImages float-left w-100 mt-4">
									<div class="other-images">
										<!--- figure out widths of sub blocks, adapt to number of blocks --->
										<cfswitch expression="#otherImageTypes#">
											<cfcase value="1">
												<cfset colClass = "col-xl-12 mx-auto float-none">
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
													<cfloop query="agentImagesForCarousel" startRow="1" endRow="1">
														<cfset agent_media_uri = agentImagesForCarousel.media_uri>
														<cfset agent_media_id = agentImagesForCarousel.media_id>
														<cfset agent_alt = agentImagesForCarousel.alt>
													</cfloop>
													<div class="col-12 px-1 #colClass# mx-md-auto my-3"><!---just for agent block--->
														<div class="carousel_background border rounded float-left w-100 p-2">
															<h3 class="mx-2 text-center">#agentCt.recordcount# Agent Images </h3>
															<div class="vslider w-100 float-left bg-light" id="vslider-base1">
																<cfset i=1>
																<div class="w-100 float-left px-3 h-auto">
																	<a id="agent_detail_a" class="d-block pt-2" target="_blank" href="/MediaSet.cfm?media_id=#agent_media_id#">Media Details</a>
																	<a id="agent_media_a" href="#agent_media_uri#" target="_blank" class="d-block my-1 w-100" title="click to open full image">
																		<img id="agent_media_img" src="/media/rescaleImage.cfm?media_id=#agent_media_id##sizeType#" class="mx-auto" alt="#agent_alt#" height="100%" width="100%">
																	</a>
																	<p id="agent_media_desc" class="mt-2 small bg-light">#agent_alt#</p>
																</div>
															</div>
															<div class="custom-nav text-center small bg-white mb-1 pt-0 pb-1">
																<button id="previous_agent_image" type="button" class="border-0 btn-outline-primary rounded"> << prev </button>
																<input id="agent_image_number" type="number" class="custom-input data-entry-input d-inline border border-light" value="1">
																<button id="next_agent_image" type="button" class="border-0 btn-outline-primary rounded" > next &nbsp; >> </button>
															</div>
														</div>
													</div>
													<script>
														var lastAgentScrollTop = 0;
														function goPreviousAgent() { 
															currentAgentImage = goPreviousImage(currentAgentImage, agentImageSetMetadata, "agent_media_img", "agent_media_desc", "agent_detail_a", "agent_media_a", "agent_image_number","#sizeType#"); 
														}
														function goNextAgent() { 
															currentAgentImage = goNextImage(currentAgentImage, agentImageSetMetadata, "agent_media_img", "agent_media_desc", "agent_detail_a", "agent_media_a", "agent_image_number","#sizeType#"); 
														}
														function goAgent() { 
															currentAgentImage = goImage(currentAgentImage, targetAgentImage, agentImageSetMetadata, "agent_media_img", "agent_media_desc", "agent_detail_a", "agent_media_a", "agent_image_number","#sizeType#");
														}
														$(document).ready(function () {
															$("##previous_agent_image").click(goPreviousAgent);
															$("##next_agent_image").click(goNextAgent);
															$("##agent_image_number").on("change",goAgent);
															$("##agent_media_img").scroll(function(event) {
																event.preventDefault();
																var y = event.scrollTop;
																if (y>lastAgentScrollTop) { 
																	goNextAgent();
																} else { 
																	goPreviousAgent();
			 													}
																lastAgentScrollTop = y; 
															});
														});
													</script>
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
													<cfloop query="collectingImagesForCarousel" startRow="1" endRow="1">
														<cfset collecting_media_uri = collectingImagesForCarousel.media_uri>
														<cfset collecting_media_id = collectingImagesForCarousel.media_id>
														<cfset collecting_alt = collectingImagesForCarousel.alt>
													</cfloop>
													<div class="col-12 px-1 #colClass# mx-md-auto my-3">
														<div class="carousel_background border rounded float-left w-100 p-2">
														<h3 class="mx-2 text-center">#collectingCt.recordcount# Collecting Images
														</h3>
															<div class="vslider w-100 float-left bg-light" id="vslider-base2">
																<div class="w-100 float-left px-3 h-auto">
																	<a id="collecting_detail_a" class="d-block pt-2" target="_blank" href="/MediaSet.cfm?media_id=#collecting_media_id#">Media Details</a>
																	<a id="collecting_media_a" href="#collecting_media_uri#" target="_blank" class="d-block my-1 w-100" title="click to open full image">
																		<img id="collecting_media_img" src="/media/rescaleImage.cfm?media_id=#collecting_media_id##sizeType#" class="mx-auto" alt="#collecting_alt#" height="100%" width="100%">
																	</a>
																	<p id="collecting_media_desc" class="mt-2 small bg-light">#collecting_alt#</p>
																</div>
															</div>
															<div class="custom-nav small text-center bg-white mb-1 pt-0 pb-1">
																<button id="previous_collecting_image" type="button" class="border-0 btn-outline-primary rounded"> << prev </button>
																<input id="collecting_image_number" type="number" id="custom-input2" class="custom-input data-entry-input d-inline border border-light" value="1">
																<button id="next_collecting_image" type="button" class="border-0 btn-outline-primary rounded"> next &nbsp; >> </button>
															</div>
														</div>
													</div>
													<script>
														var lastCollectingScrollTop = 0;
														function goPreviousCollecting() { 
															currentCollectingImage = goPreviousImage(currentCollectingImage, collectingImageSetMetadata, "collecting_media_img", "collecting_media_desc", "collecting_detail_a", "collecting_media_a", "collecting_image_number","#sizeType#"); 
														}
														function goNextCollecting() { 
															currentCollectingImage = goNextImage(currentCollectingImage, collectingImageSetMetadata, "collecting_media_img", "collecting_media_desc", "collecting_detail_a", "collecting_media_a", "collecting_image_number","#sizeType#"); 
														}
														function goCollecting() { 
															currentCollectingImage = goImage(currentCollectingImage, targetCollectingImage, collectingImageSetMetadata, "collecting_media_img", "collecting_media_desc", "collecting_detail_a", "collecting_media_a", "collecting_image_number","#sizeType#");
														}
														$(document).ready(function () {
															$("##previous_collecting_image").click(goPreviousCollecting);
															$("##next_collecting_image").click(goNextCollecting);
															$("##collecting_image_number").on("change",goCollecting);
															$("##collecting_media_img").scroll(function(event) {
																event.preventDefault();
																var y = event.scrollTop;
																if (y>lastCollectingScrollTop) { 
																	goNextCollecting();
																} else { 
																	goPreviousCollecting();
			 													}
																lastCollectingScrollTop = y; 
															});
														});
													</script>
												</cfif>
											</div>
										</div>
									</div>
								</section>
							</div>	
						</cfif><!--- end of has images or has coordinates for map --->

						<section class="overview-links col mt-4 float-left">
							<div class=""> 
								<!--- This is either a full width or half width col, depending on presence/absence of has any kind of image col --->
								<div class="mb-2 pb-3 border-bottom-black">
									<h2 class="px-2">Overview</h2>
									<cfif len(getNamedGroup.description) GT 0 >
										<p class="px-2">#getNamedGroup.description#</p>
									</cfif>
								</div>
								<div class="row pb-4">
									<cfif len(underscore_agent_id) GT 0 >
										<cfif getNamedGroup.agent_name NEQ "[No Agent]" >
											<div class="col-12 pt-3 pb-2">
												<h3 class="px-2 pb-1 border-bottom border-dark">
												Associated Agent
												</h3>
												<p class="rounded-0"> 
													<a class="h4 px-2 py-2 d-block" target="_blank" href="/agents/Agent.cfm?agent_id=#underscore_agent_id#">#getNamedGroup.agent_name#</a> </p>
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
										<div class="col-12 pb-3">
											<h3 class="px-2 pb-1 border-bottom border-dark">Taxa</h3>
											<cfif taxonQuery.recordcount gt 30>
												<div class="accordion col-12 px-0 mb-3" id="accordionForTaxa">
													<div class="card mb-2 bg-light">
														<div class="card-header py-0" id="headingTax">
															<h3 class="h4 my-0">
																<button type="button" class="headerLnk w-100 text-left" data-toggle="collapse" aria-expanded="true" data-target="##collapseTax">
																#taxonQuery.recordcount# Taxa
																</button>
															</h3>
														</div>
														<div class="card-body pl-2 pr-0 py-0">
															<div id="collapseTax" aria-labelledby="headingTax" data-parent="##accordionForTaxa" class="collapse show">
																<ul class="list-group py-2 list-group-horizontal flex-wrap rounded-0">
																	<cfloop query="taxonQuery">
																		<li class="list-group-item col-12 col-md-3 float-left"> <a class="h4" target="_blank" href="/SpecimenResults.cfm?#encodeForUrl(taxonQuery.rank)#=#encodeForUrl(taxonQuery.taxonlink)#&underscore_coll_id=#getNamedGroup.underscore_collection_id#">#taxonQuery.taxon#</a> </li>
																	</cfloop>
																</ul>
															</div>
														</div>
													</div>
												</div>
											<cfelse>
												<ul class="list-group py-2 list-group-horizontal flex-wrap rounded-0">
													<cfloop query="taxonQuery">
														<li class="list-group-item col-12 col-md-3 float-left"> <a class="h4" target="_blank" href="/SpecimenResults.cfm?#encodeForUrl(taxonQuery.rank)#=#encodeForUrl(taxonQuery.taxonlink)#&underscore_coll_id=#getNamedGroup.underscore_collection_id#">#taxonQuery.taxon#</a> </li>
													</cfloop>
												</ul>
											</cfif>
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
										<div class="col-12 pb-3">
											<h3 class="px-2 pb-1 border-bottom border-dark">Oceans</h3>
											<cfif marine.recordcount gt 30>
												<div class="accordion col-12 px-0 mb-3" id="accordionForMarine">
													<div class="card mb-2 bg-light">
														<div class="card-header py-0" id="headingMar">
															<h3 class="h4 my-0">
																<button type="button" class="headerLnk w-100 text-left" data-toggle="collapse" aria-expanded="true" data-target="##collapseMar">
																#marine.recordcount# Oceans
																</button>
															</h3>
														</div>
														<div class="card-body pl-2 pr-0 py-0">
															<div id="collapseMar" aria-labelledby="headingMar" data-parent="##accordionForMarine" class="collapse show">
																<ul class="list-group py-2 list-group-horizontal flex-wrap rounded-0">
																	<cfloop query="marine">
																		<li class="list-group-item col-12 col-md-3 float-left"> <a class="h4" target="_blank" href="/SpecimenResults.cfm?continent_ocean=#encodeForURL(marine.ocean)#&underscore_coll_id=#getNamedGroup.underscore_collection_id#">#marine.ocean#</a> </li>
																	</cfloop>
																</ul>
															</div>
														</div>
													</div>
												</div>
											<cfelse>
												<ul class="list-group py-2 list-group-horizontal flex-wrap rounded-0">
													<cfloop query="marine">
														<li class="list-group-item col-12 col-md-3 float-left"> <a class="h4" target="_blank" href="/SpecimenResults.cfm?continent_ocean=#encodeForURL(marine.ocean)#&underscore_coll_id=#getNamedGroup.underscore_collection_id#">#marine.ocean#</a> </li>
													</cfloop>
												</ul>
											</cfif>
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
										<div class="col-12 pb-3">
											<h3 class="px-2 pb-1 border-bottom border-dark">Geography</h3>
											<cfif geogQuery.recordcount gt 30>
												<div class="accordion col-12 px-0 mb-3" id="accordionForGeog">
													<div class="card mb-2 bg-light">
														<div class="card-header py-0" id="headingGeog">
															<h3 class="h4 my-0">
																<button type="button" class="headerLnk w-100 text-left" data-toggle="collapse" aria-expanded="true" data-target="##collapseGeog">
																#geogQuery.recordcount# Higher Geography Records
																</button>
															</h3>
														</div>
														<div class="card-body pl-2 pr-0 py-0">
															<div id="collapseGeog" aria-labelledby="headingGeog" data-parent="##accordionForGeog" class="collapse show">
																<ul class="list-group py-2 list-group-horizontal flex-wrap rounded-0">
																	<cfloop query="geogQuery">
																		<li class="list-group-item col-12 col-md-3 float-left"> 
																			<a class="h4" target="_blank" href="/SpecimenResults.cfm?#encodeForUrl(geogQuery.rank)#=#encodeForUrl(geogQuery.geoglink)#&underscore_coll_id=#getNamedGroup.underscore_collection_id#">#geogQuery.geog#</a> 
																		</li>
																	</cfloop>
																</ul>
															</div>
														</div>
													</div>
												</div>
											<cfelse>
												<ul class="list-group py-2 list-group-horizontal flex-wrap rounded-0">
													<cfloop query="geogQuery">
														<li class="list-group-item col-12 col-md-3 float-left"> 
															<a class="h4" target="_blank" href="/SpecimenResults.cfm?#encodeForUrl(geogQuery.rank)#=#encodeForUrl(geogQuery.geoglink)#&underscore_coll_id=#getNamedGroup.underscore_collection_id#">#geogQuery.geog#</a> 
														</li>
													</cfloop>
												</ul>
											</cfif>
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
										<div class="col-12 pb-3">
											<h3 class="px-2 pb-1 border-bottom border-dark">Islands</h3>
											<cfif islandsQuery.recordcount gt 30>
												<div class="accordion col-12 px-0 mb-3" id="accordionForIslands">
													<div class="card mb-2 bg-light">
														<div class="card-header py-0" id="headingIS">
															<h3 class="h4 my-0">
																<button type="button" class="headerLnk w-100 text-left" data-toggle="collapse" aria-expanded="true" data-target="##collapseIS">
																#islandsQuery.recordcount# Islands
																</button>
															</h3>
														</div>
														<div class="card-body pl-2 pr-0 py-0">
															<div id="collapseIS" aria-labelledby="headingIS" data-parent="##accordionForIslands" class="collapse show">
																<ul class="list-group py-2 list-group-horizontal flex-wrap rounded-0">
																	<cfloop query="islandsQuery">
																		<li class="list-group-item col-12 col-md-3 float-left"> <a class="h4" target="_blank" href="/SpecimenResults.cfm?island=#encodeForUrl(islandsQuery.island)#&underscore_coll_id=#getNamedGroup.underscore_collection_id#"> #continent_ocean#: #islandsQuery.island# </a> </li>
																	</cfloop>
																</ul>
															</div>
														</div>
													</div>
												</div>
											<cfelse>
												<ul class="list-group py-2 list-group-horizontal flex-wrap rounded-0">
													<cfloop query="islandsQuery">
														<li class="list-group-item col-12 col-md-3 float-left"> 
															<a class="h4" target="_blank" href="/SpecimenResults.cfm?island=#encodeForUrl(islandsQuery.island)#&underscore_coll_id=#getNamedGroup.underscore_collection_id#">#islandsQuery.island#</a> 
														</li>
													</cfloop>
												</ul>
											</cfif>
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
										<div class="col-12 pb-3">
											<h3 class="border-bottom pb-1 border-dark px-2">Collectors</h3>
											<cfif collectors.recordcount gt 50>
												<div class="accordion col-12 px-0 mb-3" id="accordionForCollectors">
													<div class="card mb-2 bg-light">
														<div class="card-header py-0" id="headingCollectors">
															<h3 class="h4 my-0">
																<button type="button" class="headerLnk w-100 text-left" data-toggle="collapse" aria-expanded="true" data-target="##collapseCollectors">
																#collectors.recordcount# Collectors
																</button>
															</h3>
														</div>
														<div class="card-body pl-2 pr-0 py-0">
															<div id="collapseCollectors" aria-labelledby="headingCollectors" data-parent="##accordionForCollectors" class="collapse show">
																<ul class="list-group py-2 list-group-horizontal flex-wrap rounded-0">
																<cfloop query="collectors">
																	<li class="list-group-item col-12 col-md-3 float-left"> <a class="h4" href="/agents/Agent.cfm?agent_id=#collectors.agent_id#" target="_blank">#collectors.agent_name# Collectors</a> </li>
																</cfloop>
																</ul>
															</div>
														</div>
													</div>
												</div>
											<cfelse>
												<ul class="list-group py-2 list-group-horizontal flex-wrap rounded-0">
													<cfloop query="collectors">
														<li class="list-group-item col-12 col-md-3 float-left"> <a class="h4" href="/agents/Agent.cfm?agent_id=#collectors.agent_id#" target="_blank">#collectors.agent_name#</a> </li>
													</cfloop>
												</ul>
											</cfif>
										</div>
									</cfif>
						
<!---- TODO: Cleanup indentation from here --->
									<div class="col-12 px-0">
									<cfquery name="citations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="citations">
										SELECT
											distinct 
											formatted_publication.formatted_publication, 
											formatted_publication.publication_id
										FROM
											underscore_collection
											left join underscore_relation on underscore_collection.underscore_collection_id = underscore_relation.underscore_collection_id
											left join cataloged_item on underscore_relation.collection_object_id = cataloged_item.collection_object_id
											left join citation on citation.collection_object_id = cataloged_item.collection_object_id
											left join taxonomy on citation.cited_taxon_name_id = taxonomy.taxon_name_id
											left join formatted_publication on formatted_publication.publication_id =citation.publication_id
										WHERE
											format_style='long' and
											underscore_collection.underscore_collection_id = <cfqueryparam value="#underscore_collection_id#" cfsqltype="CF_SQL_DECIMAL">
											and formatted_publication not like '%Author not listed%'
										ORDER BY
											formatted_publication
									</cfquery>
									<cfif citations.recordcount GT 0>
										<div class="col-12 pb-3">
											<h3 class="border-bottom pb-1 border-dark px-2">Citations</h3>
											<cfif citations.recordcount gt 50>
												<div class="accordion col-12 px-0 mb-3" id="accordionForCitations">
													<div class="card mb-2 bg-light">
														<div class="card-header py-0" id="headingCitations">
															<h3 class="h4 my-0">
																<button type="button" class="headerLnk w-100 text-left" data-toggle="collapse" aria-expanded="true" data-target="##collapseCitations">
																#citations.recordcount# Citations
																</button>
															</h3>
														</div>
														<div class="card-body pl-2 pr-0 py-0">
															<div id="collapseCitations" aria-labelledby="headingCitations" class="collapse show" data-parent="##accordionForCitations">
																<ul class="list-group py-2 list-group-horizontal flex-wrap rounded-0">
																<cfloop query="citations">
																	<li class="list-group-item col-12 col-md-12 float-left py-2"> 
																		<a class="h4" href="/SpecimenUsage.cfm?action=search&publication_id=#citations.publication_id#" target="_blank">#citations.formatted_publication#</a>
																	</li>
																</cfloop>
																</ul>
															</div>
														</div>
													</div>
												</div>
											<cfelse>
												<ul class="list-group py-2 list-group-horizontal flex-wrap rounded-0">
													<cfloop query="citations">
														<li class="list-group-item col-12 col-md-12 float-left py-2"> <a class="h4" href="/SpecimenUsage.cfm?action=search&publication_id=#citations.publication_id#" target="_blank">#citations.formatted_publication#, </a> </li>
													</cfloop>
												</ul>
											</cfif>
										</div>
									</cfif>
									</div>
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
	</script>
</cfoutput>
<cfinclude template = "/shared/_footer.cfm">
