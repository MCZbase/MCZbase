<!---
grouping/showNamedCollection.cfm
For read only public view of arbitrary groupings of collection objects and
added value html describing them.
Copyright 2021-2026 President and Fellows of Harvard College
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
<cfif not isdefined("debug")>
	<cfset debug ="">
</cfif>
<!--- if given url.underscore_collection_id redirect to /namedGroup/{link_name}, or /namedGroup/{underscore_collection_id} for a group without a link_name --->
<cfif isDefined("url.underscore_collection_id") AND len(url.underscore_collection_id) GT 0>
	<cfquery name="checkGroup" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="checkGroup_result" timeout="#Application.short_timeout#">
		SELECT underscore_collection_id, collection_name, link_name, mask_fg
		FROM underscore_collection
		WHERE underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#url.underscore_collection_id#">
			<cfif NOT isdefined("session.roles") OR listfindnocase(session.roles,"coldfusion_user") EQ 0>
				AND mask_fg = 0
			</cfif>
	</cfquery>
	<cfif checkGroup.recordcount is 1>
		<!--- As in errors/missing.cfm, a hidden group keeps its id address. --->
		<cfif len(trim(checkGroup.link_name)) GT 0 AND checkGroup.mask_fg EQ 0>
			<cfset redirectUrl = "/namedGroup/#EncodeForURL(trim(checkGroup.link_name))#">
		<cfelse>
			<cfset redirectUrl = "/namedGroup/#EncodeForURL(checkGroup.underscore_collection_id)#">
		</cfif>
		<cfif isDefined("url.format") AND len(trim(url.format)) GT 0>
			<cfset redirectUrl = "#redirectUrl#/#EncodeForURL(trim(url.format))#">
		</cfif>
		<cfheader statuscode="301" statustext="Moved permanently">
		<cfheader name="Location" value="#redirectUrl#">
		<cfabort>
	</cfif>
</cfif>
<!--- if target_underscore_collection_id is given in environment 
      (which errors/missing.cfm provides when /namedGroup/{target_underscore_collection_id is provided)
      then use that as the underscore_collection_id to show, otherwise fail over to form.underscore_collection_id
--->
<cfif isDefined("target_underscore_collection_id") AND len(target_underscore_collection_id) GT 0>
	<cfset underscore_collection_id = target_underscore_collection_id>
<cfelseif isDefined("form.underscore_collection_id") AND len(form.underscore_collection_id) GT 0>
	<cfset underscore_collection_id = form.underscore_collection_id>
</cfif>
<cfinclude template="/grouping/component/public.cfc" runOnce="true">
<!--- Blank lets the Accept header decide between the page and its linked data. --->
<cfif NOT isDefined("requestedFormat")>
	<cfset requestedFormat = "">
</cfif>
<cfif isDefined("url.format") AND len(trim(url.format)) GT 0>
	<cfset requestedFormat = trim(url.format)>
<cfelseif isDefined("form.format") AND len(trim(form.format)) GT 0>
	<cfset requestedFormat = trim(form.format)>
</cfif>
<cftry>
	<cfset acceptHeader = GetHttpRequestData().Headers["accept"]>
<cfcatch>
	<cfset acceptHeader = "">
</cfcatch>
</cftry>
<cfset exportFormat = resolveNamedGroupExportFormat(format=requestedFormat, acceptHeader=acceptHeader)>
<cfif len(trim(requestedFormat)) EQ 0>
	<cfheader name="Vary" value="Accept">
</cfif>
<cfif len(exportFormat) GT 0>
	<cfif NOT isDefined("underscore_collection_id") OR len(underscore_collection_id) EQ 0>
		<cfthrow message="No named group specified to show.">
	</cfif>
	<cfset namedGroupExport = getNamedGroupLatimerCoreExport(
		underscore_collection_id=underscore_collection_id,
		oneOfUs=oneOfUs,
		format=exportFormat
	)>
	<cfheader name="Content-Type" value="#namedGroupExport.contentType#">
	<cfoutput>#namedGroupExport.body#</cfoutput>
	<cfabort>
</cfif>
<cfif isDefined("underscore_collection_id") AND len(underscore_collection_id) GT 0>
	<cfquery name="getTitle" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getTitleGroup_result" timeout="#Application.short_timeout#">
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
<cfinclude template="/media/component/public.cfc" runOnce="true">
<cfinclude template="/grouping/component/search.cfc" runOnce="true">
<cfset otherImageTypes = 0>
<cfif not isDefined("underscore_collection_id") OR len(underscore_collection_id) EQ 0>
	<cfthrow message="No named group specified to show.">
</cfif>
<cfquery name="getNamedGroup" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getNamedGroup_result" timeout="#Application.short_timeout#">
	SELECT underscore_collection_id, collection_name, description, html_description,
		mask_fg,
		displayed_media_id,
		link_name
	FROM underscore_collection
	WHERE underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
</cfquery>
<cfoutput>
	<cfloop query="getNamedGroup">
		<cfif getNamedGroup.mask_fg EQ 1 AND (NOT isdefined("session.roles") OR listfindnocase(session.roles,"coldfusion_user") EQ 0)>
			<!--- mask_fg = 1 = Hidden --->
			<cflocation url="/errors/forbidden.cfm" addtoken="false">
		</cfif>
		<!--- Send the header so styles and scripts load while the queries run; this must follow the forbidden redirect above, which cannot come after a flush. --->
		<cfflush>
		<main class="py-3" id="content">
			<div class="row mx-0">
				<article class="col-12">
					<section class="feature">
						<!---  heading section with description of named group --->
						<div class="row mx-0">
							<div class="col-12 px-1 border-dark mt-4">
								<h1 class="pb-2 w-100 border-bottom-black">#getNamedGroup.collection_name#
									<div class="d-inline-block float-right">
										<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user") and len(trim(getNamedGroup.link_name)) GT 0>
											<a id="namedGroupPermalink" class="px-1 text-muted" target="_blank"
													href="#Application.serverRootUrl#/namedGroup/#encodeForUrl(getNamedGroup.link_name)#"
													aria-label="Permalink: #Application.serverRootUrl#/namedGroup/#encodeForHtml(getNamedGroup.link_name)#">
												<i class="fas fa-link" aria-hidden="true"></i>
											</a>
										</cfif>
										<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_specimens")>
											<a target="_blank" class="px-2 btn-xs btn-primary text-decoration-none" href="/grouping/NamedCollection.cfm?action=edit&underscore_collection_id=#underscore_collection_id#">Edit</a>
										</cfif>
									</div>
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
					<!--- Send the heading and description before running the slower queries below. --->
					<cfflush>
					<!--- count of specimen records for the grid; the grid loads its rows by ajax --->
					<cfquery name="specimenCount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" cachedwithin="#CreateTimespan(0,24,0,0)#" result="specimenCount_result" timeout="#Application.query_timeout#">
						SELECT count(*) AS specimen_count
						FROM (
							SELECT DISTINCT flat.guid, flat.scientific_name
							FROM
								underscore_relation
								LEFT JOIN <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat
									ON underscore_relation.collection_object_id = flat.collection_object_id
							WHERE underscore_relation.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
								AND flat.guid IS NOT NULL
						)
					</cfquery>
					<cfset otherimagetypes = 0>
					<cfquery name="directMedia_raw" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="directMedia_raw_result" timeout="#Application.query_timeout#" >
						SELECT distinct media.media_id, 
							media.media_uri, 
							MCZBASE.get_media_descriptor(media.media_id) as alt,
							MCZBASE.is_media_encumbered(media.media_id)  as encumb,
							media.media_type,
							media.mime_type,
							2 as topsort
						FROM
							underscore_collection
							join media_relations on underscore_collection.underscore_collection_id = media_relations.related_primary_key 
							join media on media_relations.media_id = media.media_id
						WHERE underscore_collection.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
							AND media_relations.media_relationship like '% underscore_collection'
					</cfquery>
					<!--- shared with getSpecimenImagesAt, which loads the rest of the carousel by position --->
					<cfset specimenImagesStart = getTickCount()>
					<cfset specimenImagesForCarousel = getSpecimenImagesForGroup(underscore_collection_id=underscore_collection_id, displayed_media_id=getNamedGroup.displayed_media_id)>
					<cfset specimenImagesForCarousel_ms = getTickCount() - specimenImagesStart>
					<cfset specimenNonImageMediaStart = getTickCount()>
					<cfset specimenMedia = getSpecimenMediaForGroup(underscore_collection_id=underscore_collection_id, displayed_media_id=getNamedGroup.displayed_media_id)>
					<cfquery name="specimenNonImageMedia" dbtype="query">
						SELECT media_id
						FROM specimenMedia
						WHERE encumb < 1
							AND media_type <> 'image' AND NOT (mime_type = 'image/jpeg' OR mime_type = 'image/png')
						ORDER BY media_id
					</cfquery>
					<cfset specimenNonImageMedia_ms = getTickCount() - specimenNonImageMediaStart>
					<cfset firstSpecimenImageAlt = "">
					<cfset firstSpecimenImageUri = "">
					<cfset firstSpecimenImageDetailsStart = getTickCount()>
					<cfif specimenImagesForCarousel.recordcount GT 0>
						<cfset firstSpecimenImageDetails = getCarouselMediaDetails(media_ids=specimenImagesForCarousel.media_id[1])>
						<cfset firstSpecimenImageAlt = firstSpecimenImageDetails.alt>
						<cfset firstSpecimenImageUri = firstSpecimenImageDetails.media_uri>
					</cfif>
					<cfset firstSpecimenImageDetails_ms = getTickCount() - firstSpecimenImageDetailsStart>
					<cfquery name="directMedia" dbtype="query">
						SELECT * 
						FROM directMedia_raw 
						WHERE encumb < 1
						ORDER BY media_id
					</cfquery>
					<cfif specimenImagesForCarousel.recordcount GT 0>
						<cfset otherImageTypes = 0>
					</cfif>
					<script>
						var specimenImageSetMetadata = JSON.parse('[]');
						var currentSpecimenImage = 1;
					</script>
					<cfquery name="agentImagesForCarousel_raw" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="agentImagesForCarousel_raw_result" cachedwithin="#CreateTimespan(0,24,0,0)#" timeout="#Application.query_timeout#">
						<!--- media functions in the outer select run once per media record, not once per specimen-collector row --->
						SELECT media.media_id, media.media_uri,
							MCZBASE.get_media_descriptor(media.media_id) as alt,
							MCZBASE.is_media_encumbered(media.media_id)  as encumb,
							media.media_type, media.mime_type, media.auto_host
						FROM media
						WHERE media.media_id IN (
							SELECT media_relations.media_id
							FROM
								underscore_relation
								join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat
									on underscore_relation.collection_object_id = flat.collection_object_id
								join collector on underscore_relation.collection_object_id = collector.collection_object_id
								join media_relations on collector.agent_id = media_relations.related_primary_key
							WHERE underscore_relation.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
								AND collector.collector_role = 'c'
								AND media_relations.media_relationship = 'shows agent'
								AND flat.guid IS NOT NULL
						)
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
					<cfquery name="collectingImagesForCarousel_raw" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="collectingImagesForCarousel_raw_result" cachedwithin="#CreateTimespan(0,24,0,0)#" timeout="#Application.query_timeout#">
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
					<!--- bounds and count of the georeferenced records the map shows; the map's points are loaded by ajax from getNamedGroupHeatmapPoints --->
					<cfquery name="mapBounds" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="mapBounds_result" cachedwithin="#CreateTimespan(0,24,0,0)#" timeout="#Application.query_timeout#">
						SELECT
							count(*) as georeferenced_count,
							min(flat.dec_lat) as minlat, min(flat.dec_long) as minlong,
							max(flat.dec_lat) as maxlat, max(flat.dec_long) as maxlong
						FROM
							underscore_relation
							join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat
								on underscore_relation.collection_object_id = flat.collection_object_id
						WHERE
							underscore_relation.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
							AND flat.guid IS NOT NULL
							AND flat.dec_lat IS NOT NULL
							AND flat.dec_lat BETWEEN -90 AND 90
							AND flat.dec_long BETWEEN -180 AND 180
					</cfquery>
					<section class="spec-table row mx-0">
						<!--- Specimen grid (code loads grid into id = "specimenjqxgrid" div) along with search handlers --->
						<script type="text/javascript">
							var cellsrenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
								if (value > 1) {
									return '<a href="/guid/'+value+'" target="_blank"><span style="margin: 4px; float: ' + columnproperties.cellsalign + '; color: ##0251a5;">' + value + '</span></a>';
								}
								else {
									return '<a href="/guid/'+value+'" target="_blank"><span style="margin: 4px; float: ' + columnproperties.cellsalign + '; color: color: ##0251a5;">' + value + '</span></a>';
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
									timeout: #Application.ajax_timeout#000,  // units not specified, miliseconds? 
									loadError: function(jqXHR, textStatus, error) { 
										handleFail(jqXHR,textStatus,error,"retrieving cataloged items in named group");
									},
									beforeprocessing: function (data) {
										source.totalrecords = #specimenCount.specimen_count#;
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
									selectionmode: 'text',  // special case display grid as small pageable table rather than full grid, leaving as selection mode text for clarity
									enablebrowserselection: true,
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
									<a href="/Specimens.cfm?execute=true&action=fixedSearch&underscore_collection_id=#encodeForURL(underscore_collection_id)#
&underscore_collection=#encodeForUrl(getNamedGroup.collection_name)#" target="_blank">#specimenCount.specimen_count#</a>
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

						<cfif specimenImagesForCarousel.recordcount GT 0 OR agentImagesForCarousel.recordcount GT 0 OR mapBounds.georeferenced_count GT 0 OR collectingImagesForCarousel.recordcount GT 0>
							<div class="col-12 col-md-6 float-left px-0 mt-4 mb-3">
								<!--- specimen images --->
								<cfif specimenImagesForCarousel.recordcount gt 0>
									<div class="hidden" id="max_img_count">#specimenImagesForCarousel.recordcount#</div>
									<section class="imagesLeft">
										<div class="col-12 float-left px-0">
											<div class="carousel_background border rounded float-left w-100 p-2 mb-4">
												<h3 class="mx-2 text-center">#specimenImagesForCarousel.recordcount# Specimen Images</h3>
												<div class="vslider w-100 float-left bg-light" id="vslider-base">
													<cfloop query="specimenImagesForCarousel" startRow="1" endRow="1">
														<cfset specimen_media_uri = firstSpecimenImageUri>
														<cfset specimen_media_id = specimenImagesForCarousel.media_id>
														<cfset specimen_alt = firstSpecimenImageAlt>
													</cfloop>
													<div class="inner w-100 bg-light float-left px-3 h-auto">
														<!---The href is determined by shared-scripts.js goImageByNumber function though a placeholder is here--->
														<a id="specimen_detail_a" class="d-block pt-2" href="/media/#specimen_media_id#">Media Details</a>
														<cfset sizeType='&width=1000&height=1000'>
														<a id="specimen_media_a" href="#encodeForHtmlAttribute(specimen_media_uri)#" class="d-block my-1 w-100 active" title="click to open full image">
															<img id="specimen_media_img" src="/media/rescaleImage.cfm?media_id=#specimen_media_id##sizeType#" class="mx-auto" alt="#encodeForHtmlAttribute(specimen_alt)#" height="100%" width="100%">
														</a>
														<p id="specimen_media_desc" class="mt-2 bg-light small caption-lg">#encodeForHtml(specimen_alt)#</p>
													</div>
												</div>
												<div class="custom-nav text-center small mb-0 bg-white pt-0 pb-1">
													<button type="button" class="border-0 btn-outline-primary rounded" id="previous_specimen_image" onclick="goPreviousSpecimen();">&lt;&nbsp;prev </button>
													<input type="number" id="specimen_image_number" class="custom-input border data-entry-input d-inline border-light" value="1" onchange="goSpecimen();">
													<button type="button" class="border-0 btn-outline-primary rounded" id="next_specimen_image" onclick="goNextSpecimen();"> next&nbsp;&gt;</button>
												</div>
												<div class="w-100 text-center smaller">of #specimenImagesForCarousel.recordcount#</div>
											</div>
										</div>
										<cfset namedGroupImagesVersion = "">
										<cfset namedGroupImagesPath = expandPath("/grouping/js/namedGroupImages.js")>
										<cfif fileExists(namedGroupImagesPath)>
											<cfset namedGroupImagesVersion = dateTimeFormat(getFileInfo(namedGroupImagesPath).lastModified, "yyyymmddHHnnss")>
										</cfif>
										<script src="/grouping/js/namedGroupImages.js?v=#encodeForUrl(namedGroupImagesVersion)#"></script>
										<script>
											specimenImageSetMetadata = makeNamedGroupImageSet(
												"#encodeForJavaScript(underscore_collection_id)#",
												#specimenImagesForCarousel.recordcount#,
												{
													media_id: "#encodeForJavaScript(specimen_media_id)#",
													media_uri: "#encodeForJavaScript(specimen_media_uri)#",
													alt: "#encodeForJavaScript(encodeForHtml(specimen_alt))#"
												},
												"#sizeType#"
											);
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
												specimenImageSetMetadata.prefetchAround(1);
											});
										</script>
									</section><!--- end specimen images --->
								</cfif>
                                                
                                                
								<!---  occurrence map --->

								<cfif mapBounds.georeferenced_count GT 0>
									<section class="heatmap mt-2 w-100">
										<!--- MCZ_BOUNDS and MCZ_HEATMAP_DATA are read by initMap() in /shared/js/mcz-heatmap-distMap.js --->
										<script>
											window.MCZ_BOUNDS = {
												minlat: #mapBounds.minlat#,
												minlong: #mapBounds.minlong#,
												maxlat: #mapBounds.maxlat#,
												maxlong: #mapBounds.maxlong#
											};
											/** Fetch the group's georeferenced localities, then draw the map with initMap() from mcz-heatmap-distMap.js.
											 * @param underscore_collection_id the named group whose localities to map.
											 * @param mapDivId the id of the map element, which shows a loading indicator until the map is drawn.
											 */
											function loadNamedGroupHeatmap(underscore_collection_id, mapDivId) {
												$.ajax({
													url: "/grouping/component/search.cfc",
													data: {
														method: "getNamedGroupHeatmapPoints",
														underscore_collection_id: underscore_collection_id,
														returnformat: "json"
													},
													dataType: "json",
													success: function (result) {
														window.MCZ_HEATMAP_DATA = result;
														if (typeof initMap === 'function') {
															initMap();
														} else {
															console.error("loadNamedGroupHeatmap: initMap is not defined");
														}
													},
													error: function (jqXHR, textStatus, error) {
														$("##" + mapDivId).html("Unable to load the map.");
														handleFail(jqXHR, textStatus, error, "loading map localities for named group");
													}
												});
											}
											window.onload = function () {
												loadNamedGroupHeatmap("#encodeForJavaScript(getNamedGroup.underscore_collection_id)#", "map");
											};
										</script>

                                    <div class="col-12 px-0">
                                      <div class="border float-left col-12 rounded px-2 pb-1">
                                        <h2 class="px-3 text-center pt-2">
                                          Map of Georeferenced Localities
                                        </h2>

                                        <!-- Map container -->
                                        <div id="map"
                                             class="w-100 rounded"
                                             style="height: 600px;"
                                             aria-label="Map of georeferenced specimen locations">
                                          <div class="my-2 text-center"><img src="/shared/images/indicator.gif" alt=""> Loading map...</div>
                                        </div>
                                        <!-- Controls: use the same IDs the shared JS expects -->
                                        <div id="floating-panel" class="w-100 mx-auto pt-1">
                                            <select id="view-mode"
                                                    class="mt-1 btn btn-xs btn-secondary text-left"
                                                    aria-label="Select map view mode">
                                              <option value="heatmap">Heatmap</option>
                                              <option value="points">Points</option>
                                            </select>

                                            <button id="change-gradient"
                                                    class="mt-1 btn btn-xs btn-secondary"
                                                    aria-label="Toggle heatmap color scheme">
                                              Color
                                            </button>
                                            <span id="view-description" class="ml-2 small text-muted">Specimen record density per locality</span>
                                        </div>
                                      </div>
                                    </div>
                                  </section>
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
													//	$(document).ready(function () {
														//	$inputAgent.addEventListener('change', function (e) {
//																goAgent()
//															}, false)
//															$prevAgent.addEventListener('click', function (e) {
//																goPreviousAgent()
//															}, false)
//															$nextAgent.addEventListener('click', function (e) {
//																goNextAgent()
//															}, false)
//															$("##agent_media_img").scrollTop(function (event) {
//																try {
//																	event.preventDefault();
//																} catch { }
//																var ya = event.scrollTop;
//																if (ya > $nextAgent) { 
//																	currentAgentImage = 0;
//																} else { 
//																	goPreviousAgent();
//																}
//                                                        
//															});
//														});
                                                        // looking to use this code instead (below) to eliminate warnings in console //
                                                          $(document).ready(function () {
                                                                $inputAgent.addEventListener('change', function () {
                                                                  goAgent();
                                                                }, false);

                                                                $prevAgent.addEventListener('click', function () {
                                                                  goPreviousAgent();
                                                                }, false);

                                                                $nextAgent.addEventListener('click', function () {
                                                                  goNextAgent();
                                                                }, false);
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
																try {
																	event.preventDefault();
																} catch { }
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
									<cfquery name="agentQuery" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="agentQuery_result" timeout="#Application.query_timeout#">
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
									<!--- one pass over the group's flat rows, cached, from which the taxa, type, ocean, geography and island lists are taken --->
									<cfquery name="summaryTerms_raw" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="summaryTerms_raw_result" cachedwithin="#CreateTimespan(0,24,0,0)#" timeout="#Application.query_timeout#">
										SELECT DISTINCT
											flat.phylclass, flat.phylorder, flat.family,
											flat.toptypestatus,
											CASE
												WHEN flat.toptypestatus IN ('Holotype','Lectotype','Neotype') THEN 1
												WHEN flat.toptypestatus IN ('Paratype','Syntype') THEN 2
												ELSE 3
											END as typesort,
											flat.continent_ocean, flat.country, flat.state_prov, flat.island
										FROM
											underscore_relation
											join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat
												on underscore_relation.collection_object_id = flat.collection_object_id
										WHERE underscore_relation.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
									</cfquery>
									<cfset taxonRank = "phylclass">
									<cfset taxonParent = "">
									<cfquery name="taxonQuery" dbtype="query">
										SELECT DISTINCT phylclass
										FROM summaryTerms_raw
										WHERE phylclass IS NOT NULL
										ORDER BY phylclass
									</cfquery>
									<cfif taxonQuery.recordcount GT 0 AND taxonQuery.recordcount LT 5 >
										<!--- try expanding to orders instead if very few classes --->
										<cfset taxonRank = "phylorder">
										<cfset taxonParent = "phylclass">
										<cfquery name="taxonQuery" dbtype="query">
											SELECT DISTINCT phylclass, phylorder
											FROM summaryTerms_raw
											WHERE phylclass IS NOT NULL
												AND phylorder IS NOT NULL
											ORDER BY phylclass, phylorder
										</cfquery>
									</cfif>
									<cfif taxonQuery.recordcount GT 0 AND taxonQuery.recordcount LT 5 >
										<!--- try expanding to families instead if very few orders --->
										<cfset taxonRank = "family">
										<cfset taxonParent = "phylorder">
										<cfquery name="taxonQuery" dbtype="query">
											SELECT DISTINCT phylorder, family
											FROM summaryTerms_raw
											WHERE phylclass IS NOT NULL
												AND family IS NOT NULL
											ORDER BY phylorder, family
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
																		<cfset taxonLink = taxonQuery[taxonRank][taxonQuery.currentRow]>
																		<cfset taxonLabel = taxonLink>
																		<cfif len(taxonParent) GT 0>
																			<cfset taxonLabel = "#taxonQuery[taxonParent][taxonQuery.currentRow]#: #taxonLink#">
																		</cfif>
																		<li class="list-group-item col-12 col-md-4 col-lg-3 float-left">
																			<a class="h4" target="_blank" href="/Specimens.cfm?execute=true&action=fixedSearch&#encodeForUrl(taxonRank)#=#encodeForUrl(taxonLink)#&underscore_coll_id=#encodeForUrl(getNamedGroup.underscore_collection_id)#&underscore_collection=#encodeForUrl(getNamedGroup.collection_name)#">#encodeForHtml(taxonLabel)#</a>
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
														<cfset taxonLink = taxonQuery[taxonRank][taxonQuery.currentRow]>
														<cfset taxonLabel = taxonLink>
														<cfif len(taxonParent) GT 0>
															<cfset taxonLabel = "#taxonQuery[taxonParent][taxonQuery.currentRow]#: #taxonLink#">
														</cfif>
														<li class="list-group-item col-12 col-md-4 col-lg-3 float-left">
															<a class="h4" target="_blank" href="/Specimens.cfm?execute=true&action=fixedSearch&#encodeForUrl(taxonRank)#=#encodeForUrl(taxonLink)#&underscore_coll_id=#encodeForUrl(getNamedGroup.underscore_collection_id)#&underscore_collection=#encodeForUrl(getNamedGroup.collection_name)#">#encodeForHtml(taxonLabel)#</a>
														</li>
													</cfloop>
												</ul>
											</cfif>
										</div>
									</cfif>
									<!--- typesort, from summaryTerms_raw, puts primary types first, then secondary types, then everything else --->
									<cfquery name="types" dbtype="query">
										SELECT DISTINCT toptypestatus, typesort
										FROM summaryTerms_raw
										WHERE toptypestatus IS NOT NULL
										ORDER BY typesort, toptypestatus
									</cfquery>

									<cfif types.recordcount GT 0>
										<div class="col-12 pb-3">
											<h3 class="px-2 pb-1 border-bottom border-dark">Specimens Cited in this Group</h3>
											
											<cfif types.recordcount gt 30>
												<div class="accordion col-12 px-0 mb-3" id="accordionForTypes">
													<div class="card mb-2 bg-light">
														<div class="card-header py-0" id="headingTypes">
															<h3 class="h4 my-0">
																<button type="button" class="headerLnk w-100 text-left" data-toggle="collapse" aria-expanded="true" data-target="##collapseTypes">
																#types.recordcount# Types
																</button>
															</h3>
														</div>
														<div class="card-body bg-white py-0">
															<div id="collapseTypes" aria-labelledby="headingTypes" data-parent="##accordionForTypes" class="collapse show">
																<ul class="list-group py-2 list-group-horizontal flex-wrap rounded-0">
																	<cfloop query="types">
																		<li class="list-group-item col-12 col-md-4 col-lg-3 float-left"> 
																			<a class="h4" target="_blank" href="/Specimens.cfm?execute=true&action=fixedSearch&type_status=%3D#encodeForUrl(types.TOPTYPESTATUS)#&underscore_collection_id=#encodeForUrl(getNamedGroup.underscore_collection_id)#&underscore_collection=#encodeForUrl(getNamedGroup.collection_name)#">#types.TOPTYPESTATUS#</a> 
																		</li>
																	</cfloop>
																</ul>
															</div>
														</div>
													</div>
												</div>
											<cfelse>
												<ul class="list-group py-2 list-group-horizontal flex-wrap rounded-0">
													<cfloop query="types">
														<li class="list-group-item col-12 col-md-4 col-lg-3 float-left"> 
															<a class="h4" target="_blank" href="/Specimens.cfm?execute=true&action=fixedSearch&type_status=%3D#encodeForUrl(types.TOPTYPESTATUS)#&underscore_collection_id=#encodeForUrl(getNamedGroup.underscore_collection_id)#&underscore_collection=#encodeForUrl(getNamedGroup.collection_name)#">#types.TOPTYPESTATUS#</a> 
														</li>
													</cfloop>
												</ul>
											</cfif>
										</div>
									</cfif>
									<cfquery name="marine" dbtype="query">
										SELECT DISTINCT continent_ocean
										FROM summaryTerms_raw
										WHERE continent_ocean LIKE '%Ocean%'
											AND continent_ocean NOT LIKE '%Oceania%'
										ORDER BY continent_ocean
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
																			<a class="h4" target="_blank" href="/Specimens.cfm?execute=true&action=fixedSearch&continent_ocean=%3D#encodeForUrl(marine.continent_ocean)#&underscore_collection_id=#encodeForUrl(getNamedGroup.underscore_collection_id)#&underscore_collection=#encodeForUrl(getNamedGroup.collection_name)#">#marine.continent_ocean#</a> 
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
															<a class="h4" target="_blank" href="/Specimens.cfm?execute=true&action=fixedSearch&continent_ocean=%3D#encodeForUrl(marine.continent_ocean)#&underscore_collection_id=#encodeForUrl(getNamedGroup.underscore_collection_id)#&underscore_collection=#encodeForUrl(getNamedGroup.collection_name)#">#marine.continent_ocean#</a> 
														</li>
													</cfloop>
												</ul>
											</cfif>
										</div>
									</cfif>
									<cfset geogRank = "Country">
									<cfset geogParent = "">
									<cfquery name="geogQuery" dbtype="query">
										SELECT DISTINCT country
										FROM summaryTerms_raw
										WHERE country IS NOT NULL
										ORDER BY country
									</cfquery>
									<cfif geogQuery.recordcount GT 0 AND geogQuery.recordcount LT 5 >
										<!--- try expanding to state province instead if very few countries --->
										<cfset geogRank = "state_prov">
										<cfset geogParent = "country">
										<cfquery name="geogQuery" dbtype="query">
											SELECT DISTINCT country, state_prov
											FROM summaryTerms_raw
											WHERE state_prov IS NOT NULL
											ORDER BY country, state_prov
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
																		<cfset geogLink = geogQuery[geogRank][geogQuery.currentRow]>
																		<cfset geogLabel = geogLink>
																		<cfif len(geogParent) GT 0>
																			<cfset geogLabel = "#geogQuery[geogParent][geogQuery.currentRow]#: #geogLink#">
																		</cfif>
																		<li class="list-group-item col-12 col-md-4 col-lg-3 float-left"> 
																			<a class="h4" target="_blank" href="/Specimens.cfm?execute=true&action=fixedSearch&#encodeForUrl(geogRank)#=#encodeForUrl(geogLink)#&underscore_coll_id=#encodeForUrl(getNamedGroup.underscore_collection_id)#&underscore_collection=#encodeForUrl(getNamedGroup.collection_name)#">#encodeForHtml(geogLabel)#</a> 
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
														<cfset geogLink = geogQuery[geogRank][geogQuery.currentRow]>
														<cfset geogLabel = geogLink>
														<cfif len(geogParent) GT 0>
															<cfset geogLabel = "#geogQuery[geogParent][geogQuery.currentRow]#: #geogLink#">
														</cfif>
														<li class="list-group-item col-12 col-md-4 col-lg-3 float-left"> 
															<a class="h4" target="_blank" href="/Specimens.cfm?execute=true&action=fixedSearch&#encodeForUrl(geogRank)#=#encodeForUrl(geogLink)#&underscore_coll_id=#encodeForUrl(getNamedGroup.underscore_collection_id)#&underscore_collection=#encodeForUrl(getNamedGroup.collection_name)#">#encodeForHtml(geogLabel)#</a> 
														</li>
													</cfloop>
												</ul>
											</cfif>
										</div>
									</cfif>
									<cfquery name="islandsQuery" dbtype="query">
										SELECT DISTINCT continent_ocean, island
										FROM summaryTerms_raw
										WHERE island IS NOT NULL
										ORDER BY continent_ocean, island
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
																			<a class="h4" target="_blank" href="/Specimens.cfm?execute=true&action=fixedSearch&current_id_only=any&island=%3D#encodeForUrl(islandsQuery.island)#&underscore_collection_id=#encodeForUrl(getNamedGroup.underscore_collection_id)#&underscore_collection=#encodeForUrl(getNamedGroup.collection_name)#"> #continent_ocean#: #islandsQuery.island# </a> 
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
															<a class="h4" target="_blank" href="/Specimens.cfm?execute=true&action=fixedSearch&island=%3D#encodeForUrl(islandsQuery.island)#&underscore_collection_id=#encodeForUrl(getNamedGroup.underscore_collection_id)#&underscore_collection=#encodeForUrl(getNamedGroup.collection_name)#">#islandsQuery.island#</a> 
														</li>
													</cfloop>
												</ul>
											</cfif>
										</div>
									</cfif>
									<cfquery name="collectors" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="collectors_result" cachedwithin="#CreateTimespan(0,24,0,0)#" timeout="#Application.query_timeout#">
										SELECT DISTINCT preferred_agent_name.agent_name, collector.agent_id, person.last_name
										FROM
											underscore_relation 
											join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat 
												on underscore_relation.collection_object_id = flat.collection_object_id
											join collector on underscore_relation.collection_object_id = collector.collection_object_id
											join preferred_agent_name on collector.agent_id = preferred_agent_name.agent_id
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
																<ul class="list-unstyled py-2 rounded-0" style="column-count: 3">
																<cfloop query="collectors">
																	<li class=""> 
																		<a class="h4" href="/agents/Agent.cfm?agent_id=#collectors.agent_id#">#collectors.agent_name# </a> 
																	</li>
																</cfloop>
																</ul>
															</div>
														</div>
													</div>
												</div>
											<cfelse>
												<ul class="list-unstyled py-2 rounded-0">
													<cfloop query="collectors">
														<li class=""> 
															<a class="h4" href="/agents/Agent.cfm?agent_id=#collectors.agent_id#">#collectors.agent_name#</a> 
														</li>
													</cfloop>
												</ul>
											</cfif>
										</div>
									</cfif>
									<cfset otherMediaCount = specimenNonImageMedia.recordcount + agentNonImageMedia.recordcount + collectingNonImageMedia.recordcount + directMedia.recordcount>
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
																<cfloop query="directMedia">
																	<!--- media directly linked to the named group --->
																	<cfif NOT ListContains(shownMedia,directMedia.media_id)>
																		<cfset shownMedia = ListAppend(shownMedia,directMedia.media_id)>
																		<li class="list-group-item col-12 col-sm-6 col-md-4 col-lg-3 float-left"> 
																			<cfset mediablock= getMediaBlockHtml(media_id="#directMedia.media_id#",displayAs="thumb",captionAs="textShort")>
																			<div id="mediaBlock#media_id#" class="border rounded pt-2 px-2">
																				#mediablock#
																			</div>
																		</li>
																	</cfif>
																</cfloop>
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
										<cfquery name="directCitations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="directCitations_result" timeout="#Application.query_timeout#">
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
										<cfquery name="citations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="citations_result" cachedwithin="#CreateTimespan(0,24,0,0)#" timeout="#Application.query_timeout#">
											SELECT DISTINCT
												formatted_publication.formatted_publication,
												formatted_publication.publication_id
											FROM
												underscore_relation
												join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat
													on underscore_relation.collection_object_id = flat.collection_object_id
												join citation on citation.collection_object_id = flat.collection_object_id
												join formatted_publication on formatted_publication.publication_id = citation.publication_id
											WHERE
												underscore_relation.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
												AND formatted_publication.format_style = 'long'
												AND formatted_publication.formatted_publication NOT LIKE '%Author not listed%'
											ORDER BY
												formatted_publication.formatted_publication
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
									<cfif 0 EQ 1>
									<div class="col-12 px-0">
										<!--- obtaining common names for families and classes works, but linking to search results won't find desired matches --->
										<!--- 
											SELECT DISTINCT common_name 
											FROM common_name
												join taxonomy f on common_name.taxon_name_id = f.taxon_name_id
												join taxonomy t on t.family = f.family
												join identification_taxonomy on t.taxon_name_id = identification_taxonomy.taxon_name_id
												join identification on identification_taxonomy.identification_id = identification.identification_id
												join underscore_relation on identification.collection_object_id = underscore_relation.collection_object_id
											WHERE f.genus IS NULL
												and underscore_relation.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
											UNION
											SELECT DISTINCT common_name 
											FROM common_name
												join taxonomy c on common_name.taxon_name_id = c.taxon_name_id
												join taxonomy t on t.phylclass = c.phylclass
												join identification_taxonomy on t.taxon_name_id = identification_taxonomy.taxon_name_id
												join identification on identification_taxonomy.identification_id = identification.identification_id
												join underscore_relation on identification.collection_object_id = underscore_relation.collection_object_id
											WHERE c.genus IS NULL and c.family IS NULL
												and underscore_relation.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
										--->
										<cfquery name="commonNamesHigher" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="commonNamesHigher_result" timeout="#Application.query_timeout#" >
											SELECT DISTINCT common_name 
											FROM common_name
												join taxonomy on common_name.taxon_name_id = taxonomy.taxon_name_id
												join identification_taxonomy on taxonomy.taxon_name_id = identification_taxonomy.taxon_name_id
												join identification on identification_taxonomy.identification_id = identification.identification_id
												join underscore_relation on identification.collection_object_id = underscore_relation.collection_object_id
											WHERE
												underscore_relation.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
										</cfquery>
										<cfif commonNamesHigher.recordcount GT 0>
											<div class="col-12 pb-3">
												<h3 class="border-bottom pb-1 border-dark px-2">Common Names</h3>
												<cfif commonNamesHigher.recordcount gt 50>
													<div class="accordion col-12 px-0 mb-3" id="accordionForcommonNamesHigher">
														<div class="card mb-2 bg-light">
															<div class="card-header py-0" id="headingcommonNamesHigher">
																<h3 class="h4 my-0">
																	<button type="button" class="headerLnk w-100 text-left" data-toggle="collapse" aria-expanded="true" data-target="##collapsecommonNamesHigher">
																	#commonNamesHigher.recordcount# Common Names:
																	</button>
																</h3>
															</div>
															<div class="card-body bg-white py-0">
																<div id="collapsecommonNamesHigher" aria-labelledby="headingcommonNamesHigher" data-parent="##accordionForcommonNamesHigher" class="collapse show">
																	<ul class="list-unstyled py-2 rounded-0" style="column-count: 3">
																	<cfloop query="commonNamesHigher">
																		<li class=""> 
																			<a class="h4" href="/Specimens.cfm?execute=true&action=fixedSearch&common_name=#commonNamesHigher.common_name#&underscore_coll_id=#encodeForUrl(getNamedGroup.underscore_collection_id)#&underscore_collection=#encodeForUrl(getNamedGroup.collection_name)#">#commonNamesHigher.common_name# </a> 
																		</li>
																	</cfloop>
																	</ul>
																</div>
															</div>
														</div>
													</div>
												<cfelse>
													<ul class="list-unstyled py-2 rounded-0">
														<cfloop query="commonNamesHigher">
															<li class=""> 
																<a class="h4" href="/agents/Agent.cfm?agent_id=#commonNamesHigher.agent_id#">#commonNamesHigher.common_name#</a> 
															</li>
														</cfloop>
													</ul>
												</cfif>
											</div>
										</cfif>
									</div>
									</cfif><!--- disabled comon names block --->
								</div>
							</div>
							<cfif oneOfUs EQ 1>
								<div id="activityDiv"></div>
								<script>
									$(document).ready(function () {
										loadNamedGroupActivityTable('#getNamedGroup.underscore_collection_id#','','','activityDiv'); 
									});
								</script>
							</cfif>
							<cfif debug EQ "true">
								<div><p>Query execution times, milliseconds.</p>
								<ul>
								<li>getTitleGroup=#getTitleGroup_result.ExecutionTime#</li>
								<li>getNamedGroup=#getNamedGroup_result.ExecutionTime#</li>
								<li>specimenCount=#specimenCount_result.ExecutionTime#</li>
								<li>specimenImagesForCarousel=#specimenImagesForCarousel_ms#</li>
								<li>firstSpecimenImageDetails=#firstSpecimenImageDetails_ms#</li>
								<li>specimenNonImageMedia=#specimenNonImageMedia_ms#</li>
								<li>agentImagesForCarousel_raw=#agentImagesForCarousel_raw_result.ExecutionTime#</li>
								<li>collectingImagesForCarousel_raw=#collectingImagesForCarousel_raw_result.ExecutionTime#</li>
								<li>mapBounds=#mapBounds_result.ExecutionTime#</li>
								<li>agentQuery=#agentQuery_result.ExecutionTime#</li>
								<li>summaryTerms_raw=#summaryTerms_raw_result.ExecutionTime#</li>
								<li>collectors=#collectors_result.ExecutionTime#</li>
								<li>directCitations=#directCitations_result.ExecutionTime#</li>
								<li>citations=#citations_result.ExecutionTime#</li>
								</ul>
								</div>
							</cfif>
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
