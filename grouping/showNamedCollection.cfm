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
<cfinclude template="/media/component/search.cfc" runOnce="true">
<cfset otherImageTypes = 0>
<cfif not isDefined("underscore_collection_id") OR len(underscore_collection_id) EQ 0>
	<cfthrow message="No named group specified to show.">
</cfif>
<cfquery name="getNamedGroup" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getNamedGroup_result">
	SELECT underscore_collection_id, collection_name, description, html_description,
		mask_fg,
		displayed_media_id
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
		</cfquery>
		<cfset otherimagetypes = 0>
		<cfquery name="specimenMedia_raw" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="specimenImagesForCarousel_result" cachedwithin="#CreateTimespan(24,0,0,0)#">
			<cfif len(displayed_media_id) GT 0>
			SELECT distinct media.media_id, 
				media.media_uri, 
				MCZBASE.get_media_descriptor(media.media_id) as alt,
				MCZBASE.is_media_encumbered(media.media_id)  as encumb,
				media.media_type,
				media.mime_type,
				1 as topsort
			FROM media
			WHERE
				media.media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#displayed_media_id#">
			UNION
			</cfif>
			SELECT distinct media.media_id, 
				media.media_uri, 
				MCZBASE.get_media_descriptor(media.media_id) as alt,
				MCZBASE.is_media_encumbered(media.media_id)  as encumb,
				media.media_type,
				media.mime_type,
				2 as topsort
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
				AND flat.guid is not null
			<cfif len(displayed_media_id) GT 0>
				AND media.media_id <> <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#displayed_media_id#">
			</cfif>
		</cfquery>
		<cfquery name="specimenImagesForCarousel" dbtype="query">
			SELECT * 
			FROM specimenMedia_raw 
			WHERE encumb < 1
				AND media_type = 'image'
				AND (mime_type = 'image/jpeg' OR mime_type = 'image/png')
			ORDER BY topsort asc, media_id
		</cfquery>
		<cfquery name="specimenNonImageMedia" dbtype="query">
			SELECT * 
			FROM specimenMedia_raw 
			WHERE encumb < 1
				AND media_type <> 'image' AND NOT (mime_type = 'image/jpeg' OR mime_type = 'image/png')
			ORDER BY media_id
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
				MCZBASE.is_media_encumbered(media.media_id)  as encumb,
				media_type, mime_type, auto_host
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
				AND flat.guid IS NOT NULL
		</cfquery>
		<cfquery name="agentImagesForCarousel" dbtype="query">
			SELECT * 
			FROM agentImagesForCarousel_raw 
			WHERE encumb < 1
				AND media_type = 'image'
				AND (mime_type = 'image/jpeg' OR mime_type = 'image/png')
				AND auto_host = 'mczbase.mcz.harvard.edu'
		</cfquery>
		<cfquery name="agentNonImageMedia" dbtype="query">
			SELECT * 
			FROM agentImagesForCarousel_raw 
			WHERE encumb < 1
				AND (
					media_type <> 'image' 
					OR NOT (mime_type =  'image/jpeg' OR mime_type = 'image/png')
					OR auto_host <> 'mczbase.mcz.harvard.edu'
				)
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
				MCZBASE.is_media_encumbered(media.media_id)  as encumb,
				media_type, mime_type, auto_host
			FROM
				underscore_collection
				join underscore_relation on underscore_collection.underscore_collection_id = underscore_relation.underscore_collection_id
				join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat 
					on underscore_relation.collection_object_id = flat.collection_object_id
				join media_relations 
					on flat.collecting_event_id = media_relations.related_primary_key 
				join media on media_relations.media_id = media.media_id 
			WHERE underscore_collection.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
				AND media_relations.media_relationship = 'shows collecting_event'
			UNION
			SELECT DISTINCT media_uri, media.media_id,
				MCZBASE.get_media_descriptor(media.media_id) as alt,
				MCZBASE.is_media_encumbered(media.media_id)  as encumb,
				media_type, mime_type, auto_host
			FROM
				underscore_collection
				join underscore_relation on underscore_collection.underscore_collection_id = underscore_relation.underscore_collection_id
				join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat 
					on underscore_relation.collection_object_id = flat.collection_object_id
				join media_relations 
					on flat.locality_id = media_relations.related_primary_key 
				join media on media_relations.media_id = media.media_id 
			WHERE underscore_collection.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
				AND media_relations.media_relationship = 'shows locality'
		</cfquery>
		<cfquery name="collectingImagesForCarousel" dbtype="query">
			SELECT * 
			FROM collectingImagesForCarousel_raw 
			WHERE encumb < 1
				AND media_type = 'image'
				AND (mime_type = 'image/jpeg' OR mime_type = 'image/png')
				AND auto_host = 'mczbase.mcz.harvard.edu'
		</cfquery>
		<cfquery name="collectingNonImageMedia" dbtype="query">
			SELECT * 
			FROM collectingImagesForCarousel_raw 
			WHERE encumb < 1
				AND (
					media_type <> 'image'
					OR NOT (mime_type = 'image/jpeg' OR mime_type = 'image/png')
					OR auto_host <> 'mczbase.mcz.harvard.edu'
				)
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
			SELECT distinct flat.locality_id,flat.dec_lat as Latitude, flat.DEC_LONG as Longitude 
			FROM <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat
				left join underscore_relation on underscore_relation.collection_object_id = flat.collection_object_id
				left join underscore_collection on underscore_relation.underscore_collection_id = underscore_collection.underscore_collection_id
			WHERE 
				underscore_collection.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
				and flat.dec_lat is not null
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
										<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_specimens")>
											 { name: 'cabinets', type: 'string' },
										</cfif>
										{ name: 'full_taxon_name', type: 'string' }
									],
									url: '/grouping/component/search.cfc?method=getSpecimensInGroup&smallerfieldlist=true&underscore_collection_id=#underscore_collection_id#',
									timeout: 30000,  // units not specified, miliseconds? 
									loadError: function(jqXHR, textStatus, error) { 
										handleFail(jqXHR,textStatus,error,"retrieving cataloged items in named group");
									},
									beforeprocessing: function (data) {
										source.totalrecords = #specimens.recordcount#;
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
										<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_specimens")>
											{ text: 'Cabinet/Freezer', datafield: 'cabinets',width:'200', filtertype: 'input' },
										</cfif>
										{ text: 'Taxonomy', datafield: 'full_taxon_name', width:'350', filtertype: 'input' }
									],
									rendergridrows: function (obj) {
										return obj.data;
									}
								});
								var now = new Date();
								var nowstring = now.toISOString().replace(/[^0-9TZ]/g,'_');
								var namestring = "#pageTitle#";
								namestring = namestring.replace(/[^A-Za-z]/g,'');
								var filename = 'MCZbase_' + namestring + '_' + nowstring + '.csv';
								$('##btnContainer').html('<a id="namedgroupcsvbutton" class="btn btn-xs btn-secondary px-3 py-1 m-0" aria-label="Export results to csv" href="/grouping/component/search.cfc?method=getSpecimensInGroupCSV&smallerfieldlist=true&underscore_collection_id=#underscore_collection_id#" download="'+filename+'" >Export to CSV</a>');
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
								<!--- specimen images --->
								<cfif specimenImagesForCarousel.recordcount gt 0>
									<div class="hidden" id="max_img_count">#specimenImagesForCarousel.recordcount#</div>
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
													<div class="inner w-100 bg-light float-left px-3 h-auto">
														<!---The href is determined by shared-scripts.js goImageByNumber function though a placeholder is here--->
														<a id="specimen_detail_a" class="d-block pt-2" href="/media/#specimen_media_id#">Media Details</a>
														<cfset sizeType='&width=1000&height=1000'>
														<a id="specimen_media_a" href="#specimen_media_uri#" class="d-block my-1 w-100 active" title="click to open full image">
															<img id="specimen_media_img" src="/media/rescaleImage.cfm?media_id=#specimen_media_id##sizeType#" class="mx-auto" alt="#specimen_alt#" height="100%" width="100%">
														</a>
														<p id="specimen_media_desc" class="mt-2 bg-light small caption-lg">#specimen_alt#</p>
													</div>
												</div>
												<div class="custom-nav text-center small mb-0 bg-white pt-0 pb-1">
													<button type="button" class="border-0 btn-outline-primary rounded" id="previous_specimen_image" >&lt;&nbsp;prev </button>
													<input type="number" id="specimen_image_number" class="custom-input border data-entry-input d-inline border-light" value="1">
													<button type="button" class="border-0 btn-outline-primary rounded" id="next_specimen_image"> next&nbsp;&gt;</button>
												</div>
												<div class="w-100 text-center smaller">of #specimenImagesForCarousel.recordcount#</div>
											</div>
										</div>
										<script>
											var $inputSpec = document.getElementById('specimen_image_number');
											var $prevSpec = document.getElementById('previous_specimen_image');
											var $nextSpec = document.getElementById('next_specimen_image');
											var $scrollerSpec = document.getElementById('specimen_media_img');
											function goPreviousSpecimen() { 
												currentSpecimenImage = goPreviousImage(currentSpecimenImage, specimenImageSetMetadata, "specimen_media_img", "specimen_media_desc", "specimen_detail_a", "specimen_media_a", "specimen_image_number","#sizeType#"); 
											}
											function goNextSpecimen() { 
												currentSpecimenImage = goNextImage(currentSpecimenImage, specimenImageSetMetadata, "specimen_media_img", "specimen_media_desc", "specimen_detail_a", "specimen_media_a", "specimen_image_number","#sizeType#"); 
											}
											function goSpecimen() { 
												currentSpecimenImage = goImageByNumber(currentSpecimenImage, specimenImageSetMetadata, "specimen_media_img", "specimen_media_desc", "specimen_detail_a", "specimen_media_a", "specimen_image_number","#sizeType#"); 
											}
											$(document).ready(function () {
												$inputSpec.addEventListener('change', function (e) {
													goSpecimen()
												}, false)
												$prevSpec.addEventListener('click', function (e) {
													goPreviousSpecimen()
												}, false)
												$nextSpec.addEventListener('click', function (e) {
													goNextSpecimen()
												}, false)
												
												$("##specimen_media_img").scrollTop(function (event) {
													event.preventDefault();
													var ys = event.scrollTop;
													if (ys > $nextSpec) { 
														currentSpecimenImage = 0;
													} else { 
														goPreviousSpecimen();
													}
												});
											});
										</script>
									</section><!--- end specimen images ---> 	
								</cfif>
								<!---  occurrence map --->
								<cfquery name="points2" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="points_result">
									SELECT median(flat.dec_lat) as mylat, median(flat.dec_long) as mylng, min(flat.dec_lat) as minlat, 
									min(flat.dec_long) as minlong, max(flat.dec_lat) as maxlat, max(flat.dec_long) as maxlong
									from <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat
									join underscore_relation u on u.collection_object_id = flat.collection_object_id
									where u.underscore_Collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
								</cfquery>							
								<cfif points.recordcount gt 0>
									<script src="https://polyfill.io/v3/polyfill.min.js?features=default"></script>
									<section class="heatmap mt-2 float-left w-100">
										<script src="https://maps.googleapis.com/maps/api/js?key=#application.gmap_api_key#&callback=initMap&libraries=visualization" async></script>
										<script>
										let map, heatmap;
										function initMap() {
											var ne = new google.maps.LatLng(#points2.maxlat#, #points2.maxlong#);
											var sw = new google.maps.LatLng(#points2.minlat# ,#points2.minlong#);
											var bounds = new google.maps.LatLngBounds(sw, ne);
											var centerpoint = new google.maps.LatLng(#points2.mylat#,#points2.mylng#);
											var mapOptions = {
												zoom: 1,
												minZoom: 1,
												maxZoom: 13,
												center: centerpoint,
												controlSize: 20,
												mapTypeId: "hybrid",
											};
											map = new google.maps.Map(document.getElementById('map'), mapOptions);
										
											if (bounds.getNorthEast().equals(bounds.getSouthWest())) {
												var extendPoint1 = new google.maps.LatLng(bounds.getNorthEast().lat(), bounds.getNorthEast().lng());
												var extendPoint2 = new google.maps.LatLng(bounds.getNorthEast().lat(), bounds.getNorthEast().lng());
												bounds.extend(extendPoint1);
												bounds.extend(extendPoint2);
											} else {
												google.maps.event.addListener(map,'bounds_changed',function(){
												//var bounds = map.getBounds();
												var extendPoint3=new google.maps.LatLng(bounds.getNorthEast().lat(), bounds.getNorthEast().lng());
												var extendPoint4=new google.maps.LatLng(bounds.getSouthWest().lat(), bounds.getSouthWest().lng());
												bounds.extend(extendPoint3);
												bounds.extend(extendPoint4);
												});
											}
											map.fitBounds(bounds);
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
										function getPoints() {
											return [
											
												<cfloop query="points">
												new google.maps.LatLng(#points.Latitude#,#points.Longitude#),
												
											</cfloop>
											]
										}
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
												<cfset colClass = "col-xl-6 mx-auto float-none">
											</cfcase>
											<cfcase value="2">
												<cfset colClass = "col-md-12 col-lg-6 mx-auto float-left">
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
													<cfset agentCt = agentImagesForCarousel.recordcount>
													<cfloop query="agentImagesForCarousel" startRow="1" endRow="1">
														<cfset agent_media_uri = agentImagesForCarousel.media_uri>
														<cfset agent_media_id = agentImagesForCarousel.media_id>
														<cfset agent_alt = agentImagesForCarousel.alt>
													</cfloop>
													<div class="col-12 px-1 #colClass# mx-md-auto my-3"><!---just for agent block--->
														<div class="carousel_background border rounded float-left w-100 p-2">
															<h3 class="h4 mx-2 text-center">#agentCt# Agent Images </h3>
															<div class="vslider w-100 float-left bg-light" id="vslider-base1">
																<cfset i=1>
																<div class="w-100 float-left px-3 h-auto">
																	<!---The href is determined by shared-scripts.js goImageByNumber function --placeholder is here--->
																	<cfset sizeType='&width=1000&height=1000'>
																	<a id="agent_detail_a" class="d-block pt-2" href="/media/#agent_media_id#">Media Details</a>
																	<a id="agent_media_a" href="#agent_media_uri#" class="d-block my-1 w-100" title="click to open full image">
																		<img id="agent_media_img" src="/media/rescaleImage.cfm?media_id=#agent_media_id##sizeType#" class="mx-auto" alt="#agent_alt#" height="100%" width="100%">
																	</a>
																	<p id="agent_media_desc" class="mt-2 small bg-light caption-sm">#agent_alt#</p>
																</div>
															</div>
															<div class="custom-nav text-center small bg-white mb-0 pt-0 pb-1">
																<button id="previous_agent_image" type="button" class="border-0 btn-outline-primary rounded">&lt;&nbsp;prev </button>
																<input id="agent_image_number" type="number" class="custom-input data-entry-input d-inline border border-light" value="1">
																<button id="next_agent_image" type="button" class="border-0 btn-outline-primary rounded"> next&nbsp;&gt;</button>
															</div>
															<div class="w-100 text-center smaller">of #agentCt#</div>
														</div>
													</div>
													<script>
														var $inputAgent = document.getElementById('agent_image_number');
														var $prevAgent = document.getElementById('previous_agent_image');
														var $nextAgent = document.getElementById('next_agent_image');
														function goPreviousAgent() { 
															currentAgentImage = goPreviousImage(currentAgentImage, agentImageSetMetadata, "agent_media_img", "agent_media_desc", "agent_detail_a", "agent_media_a", "agent_image_number","#sizeType#"); 
														}
														function goNextAgent() { 
															currentAgentImage = goNextImage(currentAgentImage, agentImageSetMetadata, "agent_media_img", "agent_media_desc", "agent_detail_a", "agent_media_a", "agent_image_number","#sizeType#"); 
														}
														function goAgent() { 
															currentAgentImage = goImageByNumber(currentAgentImage, agentImageSetMetadata, "agent_media_img", "agent_media_desc", "agent_detail_a", "agent_media_a", "agent_image_number","#sizeType#");
														}
														$(document).ready(function () {
															$inputAgent.addEventListener('change', function (e) {
																goAgent()
															}, false)
															$prevAgent.addEventListener('click', function (e) {
																goPreviousAgent()
															}, false)
															$nextAgent.addEventListener('click', function (e) {
																goNextAgent()
															}, false)
															$("##agent_media_img").scrollTop(function (event) {
																event.preventDefault();
																var ya = event.scrollTop;
																if (ya > $nextAgent) { 
																	currentAgentImage = 0;
																} else { 
																	goPreviousAgent();
																}
															});
														});
													</script>
												</cfif>
												<cfif collectingImagesForCarousel.recordcount gt 0>
													<cfset collectingCt = collectingImagesForCarousel.recordcount>
													<Cfif collectingCt GT 0>
														<cfset otherImageTypes = otherImageTypes + 1>
													</cfif>	
													<cfloop query="collectingImagesForCarousel" startRow="1" endRow="1">
														<cfset collecting_media_uri = collectingImagesForCarousel.media_uri>
														<cfset collecting_media_id = collectingImagesForCarousel.media_id>
														<cfset collecting_alt = collectingImagesForCarousel.alt>
													</cfloop>
													<div class="col-12 px-1 #colClass# mx-md-auto my-3">
														<div class="carousel_background border rounded float-left w-100 p-2">
														<h3 class="h4 mx-2 text-center">#collectingCt# Collecting/Locality Images
														</h3>
															<div class="vslider w-100 float-left bg-light" id="vslider-base2">
																<div class="w-100 float-left px-3 h-auto">
																	<!---The href is determined by shared-scripts.js goImageByNumber function though a placeholder is here--->
																	<cfset sizeType='&width=1000&height=1000'>
																	<a id="collecting_detail_a" class="d-block pt-2" target="_blank" href="/media/#collecting_media_id#">Media Details</a>
																	<a id="collecting_media_a" href="#collecting_media_uri#" target="_blank" class="d-block my-1 w-100" title="click to open full image">
																		<img id="collecting_media_img" src="/media/rescaleImage.cfm?media_id=#collecting_media_id##sizeType#" class="mx-auto" alt="#collecting_alt#" height="100%" width="100%">
																	</a>
																	<p id="collecting_media_desc" class="mt-2 small bg-light caption-sm">#collecting_alt#</p>
																</div>
															</div>
															<div class="custom-nav small text-center bg-white mb-0 pt-0 pb-1">
																<button id="previous_collecting_image" type="button" class="border-0 btn-outline-primary rounded"><&nbsp;prev </button>
																<input id="collecting_image_number" type="number" class="custom-input data-entry-input d-inline border border-light" value="1">
																<button id="next_collecting_image" type="button" class="border-0 btn-outline-primary rounded"> next&nbsp;&gt;</button>
															</div>
															<div class="w-100 text-center smaller">of #collectingCt#</div>
														</div>
													</div>
													<script>
														var $inputCollecting = document.getElementById('collecting_image_number');
														var $prevCollecting = document.getElementById('previous_collecting_image');
														var $nextCollecting = document.getElementById('next_collecting_image');
														function goPreviousCollecting() { 
															currentCollectingImage = goPreviousImage(currentCollectingImage, collectingImageSetMetadata, "collecting_media_img", "collecting_media_desc", "collecting_detail_a", "collecting_media_a", "collecting_image_number","#sizeType#"); 
														}
														function goNextCollecting() { 
															currentCollectingImage = goNextImage(currentCollectingImage, collectingImageSetMetadata, "collecting_media_img", "collecting_media_desc", "collecting_detail_a", "collecting_media_a", "collecting_image_number","#sizeType#"); 
														}
														function goCollecting() { 
															currentCollectingImage = goImageByNumber(currentCollectingImage, collectingImageSetMetadata, "collecting_media_img", "collecting_media_desc", "collecting_detail_a", "collecting_media_a", "collecting_image_number","#sizeType#");
														}
														$(document).ready(function () {
															$inputCollecting.addEventListener('change', function (e) {
																goCollecting()
															}, false)
															$prevCollecting.addEventListener('click', function (e) {
																goPreviousCollecting()
															}, false)
															$nextCollecting.addEventListener('click', function (e) {
																goNextCollecting()
															}, false)
															$("##collecting_media_img").scrollTop(function (event) {
																event.preventDefault();
																var yc = event.scrollTop;
																if (yc > $nextCollecting) { 
																	currentCollectingImage = 0;
																} else { 
																	goPreviousCollecting();
																}
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
									<cfquery name="agentQuery" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="agentQuery_result">
										SELECT DISTINCT 
											agent_id, 
											MCZBASE.get_agentnameoftype(agent_id) agent_name,
											remarks,
											ctunderscore_coll_agent_role.label,
											ctunderscore_coll_agent_role.ordinal
										FROM
											underscore_collection_agent
											left join ctunderscore_coll_agent_role on underscore_collection_agent.role = ctunderscore_coll_agent_role.role
										WHERE underscore_collection_agent.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
										ORDER BY ctunderscore_coll_agent_role.ordinal asc 
									</cfquery>
									<cfif agentQuery.recordcount GT 0>
										<div class="col-12 pt-3 pb-2">
											<h3 class="px-2 pb-1 border-bottom border-dark">
												Associated Agents
											</h3>
											<ul>
												<cfloop query="agentQuery">
													<li>
														<span>
															#agentQuery.label# 
															<a class="h4 px-2 py-2" href="/agents/Agent.cfm?agent_id=#agentQuery.agent_id#">#agentQuery.agent_name#</a> 
															#agentQuery.remarks#
														</span>
													</li>
												</cfloop>
											</ul>
										</div>
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
														<div class="card-body bg-white py-0">
															<div id="collapseTax" aria-labelledby="headingTax" data-parent="##accordionForTaxa" class="collapse show">
																<ul class="list-group py-2 list-group-horizontal flex-wrap rounded-0">
																	<cfloop query="taxonQuery">
																		<li class="list-group-item col-12 col-md-4 col-lg-3 float-left"> 
																			<a class="h4" target="_blank" href="/SpecimenResults.cfm?#encodeForUrl(taxonQuery.rank)#=#encodeForUrl(taxonQuery.taxonlink)#&underscore_coll_id=#getNamedGroup.underscore_collection_id#">#taxonQuery.taxon#</a> 
																		</li>
																	</cfloop>
																</ul>
															</div>
														</div>
													</div>
												</div>
											<cfelse>
												<ul class="list-group py-2 list-group-horizontal flex-wrap rounded-0">
													<cfloop query="taxonQuery">
														<li class="list-group-item col-12 col-md-4 col-lg-3 float-left"> <a class="h4" target="_blank" href="/SpecimenResults.cfm?#encodeForUrl(taxonQuery.rank)#=#encodeForUrl(taxonQuery.taxonlink)#&underscore_coll_id=#getNamedGroup.underscore_collection_id#">#taxonQuery.taxon#</a> </li>
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
											and flat.continent_ocean <> 'Oceania'
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
														<div class="card-body bg-white py-0">
															<div id="collapseMar" aria-labelledby="headingMar" data-parent="##accordionForMarine" class="collapse show">
																<ul class="list-group py-2 list-group-horizontal flex-wrap rounded-0">
																	<cfloop query="marine">
																		<li class="list-group-item col-12 col-md-4 col-lg-3 float-left"> 
																			<a class="h4" target="_blank" href="/SpecimenResults.cfm?continent_ocean=#encodeForURL(marine.ocean)#&underscore_coll_id=#getNamedGroup.underscore_collection_id#">#marine.ocean#</a> 
																		</li>
																	</cfloop>
																</ul>
															</div>
														</div>
													</div>
												</div>
											<cfelse>
												<ul class="list-group py-2 list-group-horizontal flex-wrap rounded-0">
													<cfloop query="marine">
														<li class="list-group-item col-12 col-md-4 col-lg-3 float-left"> 
															<a class="h4" target="_blank" href="/SpecimenResults.cfm?continent_ocean=#encodeForURL(marine.ocean)#&underscore_coll_id=#getNamedGroup.underscore_collection_id#">#marine.ocean#</a> 
														</li>
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
														<div class="card-body bg-white py-0">
															<div id="collapseGeog" aria-labelledby="headingGeog" data-parent="##accordionForGeog" class="collapse show">
																<ul class="list-group py-2 list-group-horizontal flex-wrap rounded-0">
																	<cfloop query="geogQuery">
																		<li class="list-group-item col-12 col-md-4 col-lg-3 float-left"> 
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
														<li class="list-group-item col-12 col-md-4 col-lg-3 float-left"> 
															<a target="_blank" class="h4" href="/SpecimenResults.cfm?#encodeForUrl(geogQuery.rank)#=#encodeForUrl(geogQuery.geoglink)#&underscore_coll_id=#getNamedGroup.underscore_collection_id#">#geogQuery.geog#</a> 
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
														<div class="card-body bg-white py-0">
															<div id="collapseIS" aria-labelledby="headingIS" data-parent="##accordionForIslands" class="collapse show">
																<ul class="list-group py-2 list-group-horizontal flex-wrap rounded-0">
																	<cfloop query="islandsQuery">
																		<li class="list-group-item col-12 col-md-4 col-lg-3 float-left"> 
																			<a class="h4" target="_blank" href="/SpecimenResults.cfm?island=#encodeForUrl(islandsQuery.island)#&underscore_coll_id=#getNamedGroup.underscore_collection_id#"> #continent_ocean#: #islandsQuery.island# </a> 
																		</li>
																	</cfloop>
																</ul>
															</div>
														</div>
													</div>
												</div>
											<cfelse>
												<ul class="list-group py-2 list-group-horizontal flex-wrap rounded-0">
													<cfloop query="islandsQuery">
														<li class="list-group-item col-12 col-md-4 col-lg-3 float-left"> 
															<a target="_blank" class="h4" href="/SpecimenResults.cfm?island=#encodeForUrl(islandsQuery.island)#&underscore_coll_id=#getNamedGroup.underscore_collection_id#">#islandsQuery.island#</a> 
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
														<div class="card-body bg-white py-0">
															<div id="collapseCollectors" aria-labelledby="headingCollectors" data-parent="##accordionForCollectors" class="collapse show">
																<ul class="list-group py-2 list-group-horizontal flex-wrap rounded-0">
																<cfloop query="collectors">
																	<li class="list-group-item col-12 col-md-4 col-lg-3 float-left"> 
																		<a class="h4" href="/agents/Agent.cfm?agent_id=#collectors.agent_id#">#collectors.agent_name# </a> 
																	</li>
																</cfloop>
																</ul>
															</div>
														</div>
													</div>
												</div>
											<cfelse>
												<ul class="list-group py-2 list-group-horizontal flex-wrap rounded-0">
													<cfloop query="collectors">
														<li class="list-group-item col-12 col-md-4 col-lg-3 float-left"> 
															<a class="h4" href="/agents/Agent.cfm?agent_id=#collectors.agent_id#">#collectors.agent_name#</a> 
														</li>
													</cfloop>
												</ul>
											</cfif>
										</div>
									</cfif>
									<cfset otherMediaCount = specimenNonImageMedia.recordcount + agentNonImageMedia.recordcount + collectingNonImageMedia.recordcount>
									<cfif otherMediaCount GT 0>
										<cfset shownMedia = "">
										<div class="col-12 pb-3">
											<h3 class="border-bottom pb-1 border-dark px-2">Other Media</h3>
											<cfif otherMediaCount gt 12>
												<cfif otherMediaCount GT 24>
													<!--- cardState = collapsed --->
													<cfset bodyClass = "collapse">
													<cfset ariaExpanded ="false">
												<cfelse>
													<!--- cardState = expanded --->
													<cfset bodyClass = "collapse show">
													<cfset ariaExpanded ="true">
												</cfif>
												<div class="accordion col-12 px-0 mb-3" id="accordionForOtherMedia">
													<div class="card mb-2 bg-light">
														<div class="card-header py-0" id="headingOtherMedia">
															<h3 class="h4 my-0">
																<button type="button" class="headerLnk w-100 text-left" data-toggle="collapse" aria-expanded="#ariaExpanded#" data-target="##collapseOtherMedia">
																#otherMediaCount# Other Media
																</button>
															</h3>
														</div>
														<div class="card-body bg-white py-0">
															<div id="collapseOtherMedia" aria-labelledby="headingOtherMedia" data-parent="##accordionForOtherMedia" class="#bodyClass#">
																<ul class="list-group py-2 list-group-horizontal flex-wrap rounded-0">
																<cfloop query="specimenNonImageMedia">
																	<cfif NOT ListContains(shownMedia,specimenNonImageMedia.media_id)>
																		<cfset shownMedia = ListAppend(shownMedia,specimenNonImageMedia.media_id)>
																		<li class="list-group-item col-12 col-sm-6 col-md-4 col-lg-3 float-left"> 
																			<cfset mediablock= getMediaBlockHtml(media_id="#specimenNonImageMedia.media_id#",displayAs="thumb",captionAs="textShort")>
																			<div id="mediaBlock#media_id#" class="border rounded pt-2 px-2">
																				#mediablock#
																			</div>
																		</li>
																	</cfif>
																</cfloop>
																<cfloop query="agentNonImageMedia">
																	<cfif NOT ListContains(shownMedia,agentNonImageMedia.media_id)>
																		<cfset shownMedia = ListAppend(shownMedia,agentNonImageMedia.media_id)>
																		<li class="list-group-item col-12 col-sm-6 col-md-4 col-lg-3 float-left"> 
																			<cfset mediablock= getMediaBlockHtml(media_id="#agentNonImageMedia.media_id#",displayAs="thumb",captionAs="textShort")>
																			<div id="mediaBlock#media_id#" class="border rounded pt-2 px-2">
																				#mediablock#
																			</div>
																		</li>
																	</cfif>
																</cfloop>
																<cfloop query="collectingNonImageMedia">
																	<cfif NOT ListContains(shownMedia,agentNonImageMedia.media_id)>
																		<cfset shownMedia = ListAppend(shownMedia,collectingNonImageMedia.media_id)>
																		<li class="list-group-item col-12 col-sm-6 col-md-4 col-lg-3 float-left"> 
																			<cfset mediablock= getMediaBlockHtml(media_id="#collectingNonImageMedia.media_id#",displayAs="thumb",captionAs="textShort")>
																			<div id="mediaBlock#media_id#" class="border rounded pt-2 px-2">
																				#mediablock#
																			</div>
																		</li>
																	</cfif>
																</cfloop>
																</ul>
															</div>
														</div>
													</div>
												</div>
											<cfelse>
												<ul class="list-group py-2 list-group-horizontal flex-wrap rounded-0">
													<cfloop query="specimenNonImageMedia">
														<cfif NOT ListContains(shownMedia,specimenNonImageMedia.media_id)>
															<cfset shownMedia = ListAppend(shownMedia,specimenNonImageMedia.media_id)>
															<li class="list-group-item col-12 col-sm-6 col-md-4 col-lg-3 float-left"> 
																<cfset mediablock= getMediaBlockHtml(media_id="#specimenNonImageMedia.media_id#",displayAs="thumb",captionAs="textShort")>
																<div id="mediaBlock#media_id#" class="border rounded pt-2 px-2">
																	#mediablock#
																</div>
															</li>
														</cfif>
													</cfloop>
													<cfloop query="agentNonImageMedia">
														<cfif NOT ListContains(shownMedia,agentNonImageMedia.media_id)>
															<cfset shownMedia = ListAppend(shownMedia,agentNonImageMedia.media_id)>
															<li class="list-group-item col-12 col-sm-6 col-md-4 col-lg-3 float-left"> 
																<cfset mediablock= getMediaBlockHtml(media_id="#agentNonImageMedia.media_id#",displayAs="thumb",captionAs="textShort")>
																<div id="mediaBlock#media_id#" class="border rounded pt-2 px-2">
																	#mediablock#
																</div>
															</li>
														</cfif>
													</cfloop>
													<cfloop query="collectingNonImageMedia">
														<cfif NOT ListContains(shownMedia,collectingNonImageMedia.media_id)>
															<cfset shownMedia = ListAppend(shownMedia,collectingNonImageMedia.media_id)>
															<li class="list-group-item col-12 col-sm-6 col-md-4 col-lg-3 float-left"> 
																<cfset mediablock= getMediaBlockHtml(media_id="#collectingNonImageMedia.media_id#",displayAs="thumb",captionAs="textShort")>
																<div id="mediaBlock#media_id#" class="border rounded pt-2 px-2">
																	#mediablock#
																</div>
															</li>
														</cfif>
													</cfloop>
												</ul>
											</cfif>
										</div>
									</cfif>
									<div class="col-12 px-0">
										<cfquery name="directCitations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="directCitations_result">
											SELECT
												publication_id,
												MCZBASE.getfullcitation(publication_id) formatted_publication,
												MCZBASE.getshortcitation(publication_id) short_publication,
												type,
												pages,
												remarks,
												citation_page_uri
											FROM
												underscore_collection_citation
												join underscore_collection on underscore_collection_citation.underscore_collection_id = underscore_collection.underscore_collection_id
											WHERE
												underscore_collection_citation.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
											ORDER BY
												type, MCZBASE.getshortcitation(publication_id)
										</cfquery>
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
										<cfif citations.recordcount GT 0 OR directCitations.recordcount GT 0>
											<cfset totalCitations = citations.recordcount + directCitations.recordcount>
											<div class="col-12 pb-3">
												<h3 class="border-bottom pb-1 border-dark px-2">Citations</h3>
												<cfif totalCitations GT 50>
													<div class="accordion col-12 px-0 mb-3" id="accordionForCitations">
														<div class="card mb-2 bg-light">
															<div class="card-header py-0" id="headingCitations">
																<h3 class="h4 my-0">
																	<button type="button" class="headerLnk w-100 text-left" data-toggle="collapse" aria-expanded="true" data-target="##collapseCitations">
																	#totalCitations# Citations
																	</button>
																</h3>
															</div>
															<div class="card-body bg-white pb-0 pt-2">
																<div id="collapseCitations" aria-labelledby="headingCitations" class="collapse show" data-parent="##accordionForCitations">
																	<cfif directCitations.recordCount GT 0>
																		<h4 class="mb-0 px-2 pt-2">Citations about the #collection_name#</h4>
																		<ul class="list-group py-2 list-group-horizontal flex-wrap rounded-0">
																			<cfloop query="directCitations">
																				<li class="list-group-item col-12 col-md-12 float-left py-2"><span class="border-bottom mr-2">#directCitations.type#</span> <a class="h4" href="/publications/showPublication.cfm?publication_id=#directCitations.publication_id#">#directCitations.formatted_publication#</a> <span class="small">#directCitations.remarks#</span></li>
																			</cfloop>
																		</ul>
																	</cfif>
																	<h4 class="mb-0 px-2 pt-2">Citations of cataloged items</h4>
																	<ul class="list-group py-2 list-group-horizontal flex-wrap rounded-0">
																		<cfloop query="citations">
																			<li class="list-group-item col-12 col-md-12 float-left py-2"> 
																				<a class="h4" href="/publications/showPublication.cfm?publication_id=#citations.publication_id#">#citations.formatted_publication#</a>
																			</li>
																		</cfloop>
																	</ul>
																</div>
															</div>
														</div>
													</div>
												<cfelse>
													<cfif directCitations.recordCount GT 0>
														<h4 class="px-2 mb-0 pt-0">Citations about the #collection_name#</h4>
														<ul class="list-group py-2 list-group-horizontal flex-wrap rounded-0">
															<cfloop query="directCitations">
																<li class="list-group-item col-12 col-md-12 float-left py-2"><span class="border-bottom mr-2">#directCitations.type#</span> <a class="h4" href="/publications/showPublication.cfm?publication_id=#directCitations.publication_id#">#directCitations.formatted_publication#</a> <span class="small">#directCitations.remarks#</span></li>
															</cfloop>
														</ul>
													</cfif>
													<h4 class="px-2 mb-0 pt-2">Citations of cataloged items</h4>
													<ul class="list-group py-2 list-group-horizontal flex-wrap rounded-0">
														<cfloop query="citations">
															<li class="list-group-item col-12 col-md-12 float-left py-2"> <a class="h4" href="/publications/showPublication.cfm?publication_id=#citations.publication_id#">#citations.formatted_publication#</a> </li>
														</cfloop>
													</ul>
												</cfif>
											</div>
										</cfif>
									</div>
								</div>
							</div>
							<cfif oneOfUs EQ 1>
								<div id="activityDiv"></div>
								<script>
									$(document).ready(function () {
										loadNamedGroupActivityTable('#getNamedGroup.underscore_collection_id#','','','activityDiv'); 
									});
								</script>
							<cfif>
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
