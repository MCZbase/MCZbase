<cfset pageTitle="Media Viewer">
	
<cfset usealternatehead="image" />
<cfinclude template="/shared/_header.cfm">
<!---  Displays an image and other images in a set related by the relationship shows cataloged_item --->
	<link rel="stylesheet" href="/includes/js/multizoom/multizoom.css" type="text/css"/>
	<link rel="stylesheet" href="/includes/css/mediacontain.css"/>
	<script type="text/javascript" src="/includes/js/multizoom/multizoom.js"></script>
<cfif NOT isDefined("media_id")>
  <cfoutput>
    <h2>No Media Object Specified</h2>
  </cfoutput>
  <cfelse>

	  <!--- Find the requested media object --->
	  <cfquery name="m" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select media_uri, mime_type, media_type, media_id,
			   get_medialabel(media_id,'height') height, get_medialabel(media_id,'width') width,
			   nvl(MCZBASE.GET_MAXHEIGHTMEDIASET(media_id), get_medialabel(media_id,'height')) maxheightinset,
			   nvl(
				  MCZBASE.GET_MEDIA_REL_SUMMARY(media_id, 'shows cataloged_item') ||
				  MCZBASE.GET_MEDIA_REL_SUMMARY(media_id, 'shows publication') ||
				  MCZBASE.GET_MEDIA_REL_SUMMARY(media_id, 'shows collecting_event') ||
				  MCZBASE.GET_MEDIA_REL_SUMMARY(media_id, 'shows agent') ||
				  MCZBASE.GET_MEDIA_REL_SUMMARY(media_id, 'shows locality')
			   , 'Unrelated image') mrstr
		from MEDIA
			where media_id= <cfqueryparam value=#media_id# CFSQLType="CF_SQL_DECIMAL" >
				  AND MCZBASE.is_media_encumbered(media.media_id)  < 1
	</cfquery>
  <cfloop query="m" endrow="1">
	<cfquery name="alt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select mczbase.get_media_descriptor(media_id) media_descriptor 
		from media 
		where media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL"value="#media_id#"> 
	</cfquery> 
	<cfquery name="mcrguid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" >
		select distinct 'MCZ:'||collection_cde||':'||cat_num as relatedGuid 
		from media_relations
			left join cataloged_item on related_primary_key = collection_object_id
		where media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
			and media_relationship = 'shows cataloged_item'
	</cfquery>

    <cfoutput>
      <div id="mediacontain">
		<div class="media_head">
		<h3>Selected image related to #relatedItemA##relatedItem##relatedItemEndA#</h3>
		</div>
		<div class="layoutbox">
			<div class="targetarea media_image" style="height:500px; width:500px;">
				<img id="multizoom1" border="0" src='#m.media_uri#' width="500" height="500" alt="image">
			</div>
		</div>
	</cfoutput>
  </cfloop>
  <!--- on m, loop to get single media record with given media_id  --->
</cfif>
<!--- media_id is defined --->
<cfinclude template="/shared/_footer.cfm">

<!---<cfinclude template="/shared/_header.cfm">
<script type='text/javascript' src='/media/js/media.js'></script>
<cfinclude template="/media/component/search.cfc" runOnce="true">
<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
	<cfset oneOfUs = 1>
<cfelse>
	<cfset oneOfUs = 0>
</cfif>
<cfset maxMedia = 8>
<cfoutput>
	
	<cfquery name="media" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select distinct 
		media.media_id,media.media_uri,media.mime_type,media.media_type,media.preview_uri, 
		MCZBASE.get_media_dctermsrights(media.media_id) as uri, 
		MCZBASE.get_media_dcrights(media.media_id) as display, 
		MCZBASE.is_media_encumbered(media.media_id) hideMedia,
		MCZBASE.get_media_credit(media.media_id) as credit, 
		MCZBASE.get_media_descriptor(media.media_id) as alttag,
		MCZBASE.get_media_owner(media.media_id) as owner
	From
		media
	WHERE 
		media.media_id IN <cfqueryparam cfsqltype="CF_SQL_DECiMAL" value="#media_id#" list="yes">
		AND MCZBASE.is_media_encumbered(media_id)  < 1 
	</cfquery>
		<style>
			.viewer {width: auto; height: auto;margin:auto;}
			.viewer img {box-shadow: 8px 2px 30px black;margin-bottom: .5em;}
			.slider {height: auto;}
		</style>

	<main class="container-fluid" id="content">
		<div class="row">
			<div class="col-12 pb-4">
			<cfloop query="media">
				<div class="row">
					<div class="col-12 my-3">
						<h1 class="h2 my-4 col-12 float-left text-center">Media Viewer</h1>
						<div class="viewer">
							<cfif len(media.media_id) gt 0>
								<div class="rounded border bg-light col-12 col-md-6 col-lg-7 col-xl-7 float-left mb-2 pt-3 pb-0">
									<cfset mediablock= getMediaBlockHtml(media_id="#media_id#",size="900",captionAs="textLinks")>
									<div class="mx-auto text-center h2 pt-1" id="mediaBlock#media.media_id#"> #mediablock# </div>
								</div>
							</cfif>
							<div class="col-12 col-md-6 col-lg-5 col-xl-5 float-left mb-2 pt-0 pb-0">
								<cfset mediaMetadataBlock= getMediaMetadata(media_id="#media_id#")>
								<div id="mediaMetadataBlock#media_id#">
									#mediaMetadataBlock#
								</div>
							</div>
						</div>
						<!---specimen records relationships and other possible associations to media on those records--->
						<cfquery name="spec" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select distinct media_id,flat.collection_object_id as pk, flat.collectors as agent, collecting_event.verbatim_locality as collecting_event
						from media_relations
							left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat on related_primary_key = collection_object_id
							left join collecting_event on flat.collecting_event_id = collecting_event.collecting_event_id
						where media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media.media_id#"> 
								and (media_relations.media_relationship like '%cataloged_item%' OR media_relations.media_relationship like '%collecting_event%')
						</cfquery>
						<cfif len(spec.pk) gt 0>
							<div class="col-12 col-xl-12 px-0 float-left">
								<div class="search-box mt-4 w-100">
									<div class="search-box-header px-2 mt-0 mediaTableHeader">
										<ul class="list-group list-group-horizontal text-white">
											<li class="col-12 px-1 list-group-item mb-0 h4">Related Media Record(s) </li>
										</ul>
									</div>
									<div class="row mx-0">
										<div class="col-12 p-1">
											<cfquery name="relm" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
												select distinct media.media_id, preview_uri, media.media_uri,
													get_medialabel(media.media_id,'height') height, get_medialabel(media.media_id,'width') width,
													media.mime_type, media.media_type, media.auto_protocol, media.auto_host
												from media_relations
													 left join media on media_relations.media_id = media.media_id
													 left join ctmedia_license on media.media_license_id = ctmedia_license.media_license_id
												where (media_relationship like '%cataloged_item%' OR media_relationship like '%collecting_event%' OR media_relationship like '%agent%')
													AND related_primary_key = <cfqueryparam value=#spec.pk# CFSQLType="CF_SQL_DECIMAL" >
													AND MCZBASE.is_media_encumbered(media.media_id)  < 1
											</cfquery>
											<cfset i= 1>
											<cfloop query="relm">
												<div class="border-light col-md-3 col-lg-2 col-xl-2 float-left">
													<cfif len(media.media_id) gt 0>
														<cfif relm.media_id eq '#media.media_id#'> 
															<cfset activeimg = "border-warning bg-white border-left px-1 pt-2 border-right border-bottom border-top">
														<cfelse>	
															<cfset activeimg = "border-lt-gray bg-white px-1 pt-2">
														</cfif>
													<ul class="list-group px-0">
														<li class="list-group-item px-0 mx-1">
														<cfset mediablock= getMediaBlockHtml(media_id="#relm.media_id#",displayAs="thumb",size='70',captionAs="textCaptionFull")>
														<div class="#activeimg# image#i#" id="mediaBlock#relm.media_id#">
															<!---Media Zoom/Related link should populate the area at the top with its image and metadata. Need something new on search.cfc? --->
															<div class="bg-white px-0" style="min-height: 135px;"> #mediablock#</div>
														</div>
														</li>
													</ul>
													</cfif>
												</div>
												<cfset i=i+1>
											</cfloop>
											<div id="targetDiv"></div>
										</div>
									</div>
								</div>
							</div>
						<cfelse>
							<div class="col-auto px-2 float-left">
								<h3 class="h4 mt-3 w-100 px-4 font-italic">Not associated with Specimen Records</h3>
							</div>
						</cfif>
					</div>
				</div>
			</cfloop>
			</div>
			</div>
		</div>
	</main>
</cfoutput>
	
	
<cfinclude template="/shared/_footer.cfm">
--->