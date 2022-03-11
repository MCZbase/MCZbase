<cfset pageTitle="Media">
<!--- WARNING: Major work needed.  This is not a redesigned document yet.  See todo notes below --->

<!--- TODO: The old MediaSearch.cfm provides both search results (which should be handled by the media search), and individual media records.  This does not fit the design intent for /media/showMedia.cfm which following redesign conventions would show one and only one media record.  This file needs to be restarted from scratch with a redesign template to show only single media records.  (it should be pretty simple, just header, relevant management links for the user's permission level,  an invocation of getMediaBlockHtml for the single record, and the footer). --->

<!--- TODO: Any api call for more than one image needs to be redirected to either the media search, to show the list of matching images there, or to a new redesigned media gallery which would allow the display of multiple images in larger than thumbnail size along with their metadata --->
<cfinclude template="/shared/_header.cfm">
<script type='text/javascript' src='/media/js/media.js'></script>
<cfinclude template="/media/component/search.cfc" runOnce="true">
<cfoutput>
	<cfquery name="media" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select distinct 
		media.media_id,media.media_uri,media.mime_type,media.media_type,media.preview_uri, 
		MCZBASE.is_media_encumbered(media.media_id) hideMedia,
		MCZBASE.get_media_credit(media.media_id) as credit, 
		mczbase.get_media_descriptor(media_id) as alttag,
		nvl(MCZBASE.GET_MEDIA_REL_SUMMARY(media_id, 'shows cataloged_item') ||
			MCZBASE.GET_MEDIA_REL_SUMMARY(media_id, 'shows publication') ||
			MCZBASE.GET_MEDIA_REL_SUMMARY(media_id, 'shows collecting_event') ||
			MCZBASE.GET_MEDIA_REL_SUMMARY(media_id, 'shows agent') ||
			MCZBASE.GET_MEDIA_REL_SUMMARY(media_id, 'shows locality')
			, 'Unrelated image') mrstr
	From
		media
	WHERE 
		media.media_id IN <cfqueryparam cfsqltype="CF_SQL_DECiMAL" value="#media_id#" list="yes">
		AND MCZBASE.is_media_encumbered(media_id)  < 1 
	</cfquery>
	<main class="container" id="content">
		<div class="row">
			<div class="col-12 mt-4">
				<h1 class="h2 mt-4 pb-1 mb-3 pb-3 border-bottom">
					Media Record 
					<button class="btn float-right btn-xs btn-primary" onClick="location.href='/MediaSet.cfm?media_id=#media_id#'">Viewer</button>
				</h1>
			</div>
			<div class="col-12 mt-4">
				<cfquery name="labels" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT
						media_label,
						label_value,
						agent_name,
						media_label_id 
					FROM
						media_labels
						left join preferred_agent_name on media_labels.assigned_by_agent_id=preferred_agent_name.agent_id
					WHERE
						media_labels.media_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
				</cfquery>
				<cfquery name="keywords" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT
						media_keywords.media_id,
						keywords
					FROM
						media_keywords
					WHERE
						media_keywords.media_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
				</cfquery>
				<cfquery name="mediaRelations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT source_media.media_id source_media_id, 
						source_media.auto_filename source_filename,
						source_media.media_uri source_media_uri,
						media_relations.media_relationship
					FROM
						media_relations
						left join media source_media on media_relations.media_id = source_media.media_id
					WHERE
						media_relations.related_primary_key=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
				</cfquery>
				<cfloop query="media">
					<cfquery name="thisguid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" >
						select distinct 'MCZ:'||cataloged_item.collection_cde||':'||cataloged_item.cat_num as specGuid, identification.scientific_name, flat.higher_geog,flat.spec_locality,
						MCZBASE.get_media_descriptor(media1.media_id) alttag2
						from media_relations
							left join cataloged_item on media_relations.related_primary_key = cataloged_item.collection_object_id
							left join identification on identification.collection_object_id = cataloged_item.collection_object_id
							left join flat on cataloged_item.collection_object_id = flat.collection_object_id
							left join media media1 on media1.media_id = media_relations.media_id
						where media_relations.media_relations_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media.media_id#">
							and media_relationship = 'shows cataloged_item'
						and identification.accepted_id_fg = 1
					</cfquery>

					<cfif len(media.media_id) gt 0>
						<cfset mediablock= getMediaBlockHtml(media_id="#media.media_id#",size="400",captionAs="textLinks")>
						<div class="float-left" id="mediaBlock#media.media_id#">
							#mediablock#
						</div>
					</cfif>
					<div class="float-left col-6">
						<h2 class="h3 px-2">Media ID = #media.media_id#</h2>
						<h3 class="text-decoration-underline px-2">Metadata</h3>
						<ul class="list-group">
							<cfloop query="labels">
								<li class="list-group-item"><span class="text-uppercase">#labels.media_label#:</span> #labels.label_value#</li>
							</cfloop>
							 <cfquery name="relations"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
								select media_relationship as mr_label, MCZBASE.MEDIA_RELATION_SUMMARY(media_relations_id) as mr_value
									from media_relations
								where media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media.media_id#">
									and media_relationship in ('created by agent', 'shows cataloged_item')
							</cfquery>
							<cfloop query="relations">
								<cfif not (not listcontainsnocase(session.roles,"coldfusion_user") and #mr_label# eq "created by agent")>
									<cfset labellist = "<li>#mr_label#: #mr_value#</li>">
								</cfif>
							</cfloop>
							<li class="list-group-item"><span class="text-uppercase">Keywords: </span> #keywords.keywords#</li>
							<li class="list-group-item border p-2"><span class="text-uppercase">Alt Text: </span>#media.alttag#</li>
						</ul>
					</div>
				</cfloop>
			</div>
		</div>
		<div class="row">
			<cfquery name="ff" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select distinct collection_object_id as pk, guid, typestatus, SCIENTIFIC_NAME name,
				decode(continent_ocean, null,'',' '|| continent_ocean) || decode(country, null,'',': '|| country) || decode(state_prov, null, '',': '|| state_prov) || decode(county, null, '',': '|| county)||decode(spec_locality, null,'',': '|| spec_locality) as geography,
				trim(MCZBASE.GET_CHRONOSTRATIGRAPHY(locality_id) || ' ' || MCZBASE.GET_LITHOSTRATIGRAPHY(locality_id)) as geology,
				trim( decode(collectors, null, '',''|| collectors) || decode(field_num, null, '','  '|| field_num) || decode(verbatim_date, null, '','  '|| verbatim_date))as coll,
				specimendetailurl, media_relationship
			from media_relations
				left join flat on related_primary_key = collection_object_id
			where media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media.media_id#">
					and (media_relations.media_relationship = 'shows cataloged_item')
		</cfquery>
				<div class="col-12 mt-4 pb-3"><p class="mb-0">CATALOG NUMBER: #ff.guid#</p>
					<p class="mb-0">TYPE STATUS: #ff.typestatus#</p>
					<p class="mb-0">SCIENTIFIC NAME: #ff.name#</p>
					<p class="mb-0">LOCATION COLLECTED: #ff.geography#</p> 
				</div>
		</div>
			
		<div class="row">
		  <!--- Obtain the list of related media objects, construct a list of thumbnails--->
			<cfquery name="relm" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select distinct media.media_id, preview_uri, media.media_uri,
				get_medialabel(media.media_id,'height') height, get_medialabel(media.media_id,'width') width,
				media.mime_type, media.media_type,
				CASE WHEN MCZBASE.is_mcz_media(media.media_id) = 1 THEN ctmedia_license.display ELSE MCZBASE.get_media_dcrights(media.media_id) END as license,
					ctmedia_license.uri as license_uri,
					mczbase.get_media_credit(media.media_id) as credit,
					MCZBASE.is_media_encumbered(media.media_id) as hideMedia
			from media_relations
				 left join media on media_relations.media_id = media.media_id
				 left join ctmedia_license on media.media_license_id = ctmedia_license.media_license_id
			where (media_relationship = 'shows cataloged_item' or media_relationship = 'shows agent')
			   AND related_primary_key = <cfqueryparam value=#ff.pk# CFSQLType="CF_SQL_DECIMAL" >
				AND MCZBASE.is_media_encumbered(media.media_id)  < 1
			</cfquery>
		</div>
		<section>
			
				<section class="spec-table row mx-0">
					<div class="container-fluid">
						<h2 class="h3">Specimen Records</h2>
							<div class="row">
								<div class="col-12 px-0 mb-5">
									<div class="row mt-0 mx-0"> 
										<div id="specimenjqxgrid"></div>
									</div>
								</div>
							</div>
						</div>
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
										{ name: 'media_id', type: 'string' },
										{ name: 'full_taxon_name', type: 'string' }
									],
									url: '/media/component/search.cfc?method=getSpecimensInMedia&smallerfieldlist=true&collection_object_id=#ff.pk#&media_id=#media.media_id#',
									timeout: 30000,  // units not specified, miliseconds? 
									loadError: function(jqXHR, textStatus, error) { 
										handleFail(jqXHR,textStatus,error,"retrieving cataloged items in named group");
									},
									beforeprocessing: function (data) {
										source.totalrecords = #ff.recordcount#;
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
										{ text: 'Verbatim Date', datafield: 'verbatim_date', width:'150', filtertype: 'input' },
										{ text: 'Higher Geography', datafield: 'higher_geog', width:'350', filtertype: 'input' },
										{ text: 'Full Taxon Name', datafield: 'full_taxon_name', width:'350', filtertype: 'input' },
										{ text: 'Media ID', datafield: 'media_id', width:'350', filtertype: 'input' }
									],
									rendergridrows: function (obj) {
										return obj.data;
									}
								});
								var now = new Date();
								var nowstring = now.toISOString().replace(/[^0-9TZ]/g,'_');
								var namestring = "#pageTitle#";
								namestring = namestring.replace(/[^A-Za-z]/g,'');
							});
						</script>

						<!---end specimen grid---> 
					</section>	
				
		</section>
	</main>
</cfoutput>
<cfinclude template="/shared/_footer.cfm">
