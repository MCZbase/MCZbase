<cfset pageTitle="Media Viewer">

<cfinclude template="/shared/_header.cfm">
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
			.viewer img {box-shadow: 8px 2px 20px black;margin-bottom: .5em;}
		</style>

	<main class="container-fluid pb-5" id="content">
		<div class="row">
			<div class="col-12 pb-4 mb-5 pl-md-4">
			<cfloop query="media">
				<div class="row">
					<div class="col-12 my-3">
						<cfif len(media.media_id) gt 0>
							<div id="viewer targetarea" class="rounded highlight_media col-12 col-md-5 col-xl-2 float-left pt-2 my-2 pb-0">
								<cfset mediablock= getMediaBlockHtml(media_id="#media_id#",size="300",captionAs="textLinks")>
								<div class="mx-auto text-center h3 pt-1" id="mediaBlock#media.media_id#"> #mediablock# </div>
									<h1 class="h2 mb-1 mt-0 col-12 float-left text-center">Media Viewer</h1>
									<p class="small90">Place cursor in top left corner of media and zoom in with mousewheel to see a larger version of the image. Pan to see different parts of image. </p>
							</div>
						</cfif>
						<div id="metadatatable" class="col-12 col-md-7 col-xl-10 float-left my-2 pt-0 pb-0">
							<cfset mediaMetadataBlock= getMediaMetadata(media_id="#media_id#")>
							<div id="mediaMetadataBlock#media_id#">
								#mediaMetadataBlock#
							</div>
						</div>
						<cfquery name="media_rel" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							select distinct
								mr.media_relationship, ct.label, mr.media_relations_id
							From
								media_relations mr, ctmedia_relationship ct
							WHERE 
								mr.media_relationship = ct.media_relationship 
							and
								mr.media_id IN <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media.media_id#" list="yes">
							ORDER BY mr.media_relationship
						</cfquery>
						<cfloop query="media_rel">
						<!---specimen records relationships and other possible associations to media on those records--->						
							<cfif len(media.media_id) gt 0>
								<cfquery name="spec" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
								SELECT distinct media_id,flat.collection_object_id as pk, media_relations.related_primary_key as rpk,media_relations.media_relationship,collecting_event.collecting_event_id,collecting_event.verbatim_locality as collecting_event
								FROM media_relations
									left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat on related_primary_key = collection_object_id
									left join collecting_event on flat.collecting_event_id = collecting_event.collecting_event_id
									left join MCZBASE.ctmedia_relationship on media_relations.media_relationship = mczbase.ctmedia_relationship.media_relationship 
								WHERE media_relations.media_relationship = <cfqueryparam value="#media_rel.media_relationship#" cfsqltype="CF_SQL_VARCHAR" list="yes">
								AND media_relations.media_relations_id = <cfqueryparam value="#media_rel.media_relations_id#" cfsqltype="CF_SQL_VARCHAR">
								</cfquery>
							</cfif>
							<cfloop query="spec">
							<cfif len(media_rel.media_relationship) gt 0>
								<div class="col-12 col-xl-12 px-0 float-left">
									<div class="search-box mt-2 w-100 mb-5">
										<div class="search-box-header px-2 mt-0 mediaTableHeader">
											<ul class="list-group list-group-horizontal text-white">
												<li class="col-12 px-1 list-group-item mb-0 h4 font-weight-lessbold">Related Media Records (
											#spec.media_relationship#: #spec.pk#
												)</li>
											</ul>
										</div>
										<div class="row mx-0">
											<div class="col-12 p-1">
												<cfquery name="relm" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
													select distinct media.media_id, preview_uri, media.media_uri,media_relations.related_primary_key,
														get_medialabel(media.media_id,'height') height, get_medialabel(media.media_id,'width') width,
														media.mime_type, media.media_type, media.auto_protocol, media.auto_host
													from media_relations
														 left join media on media_relations.media_id = media.media_id
														 left join ctmedia_license on media.media_license_id = ctmedia_license.media_license_id
													left join MCZBASE.ctmedia_relationship on media_relations.media_relationship = mczbase.ctmedia_relationship.media_relationship 
													where media_relations.related_primary_key = <cfqueryparam value=#spec.rpk#>
													and mczbase.ctmedia_relationship.description = any('shows', 'ledger','documents','transcript','related','created')
													and 
													AND MCZBASE.is_media_encumbered(media.media_id)  < 1
													ORDER BY media.media_type asc
												</cfquery>
												<cfset i= 1>
												<cfloop query="relm">
													<div class="col-md-4 col-lg-3 col-xl-2 px-1 float-left multizoom thumbs">
														<cfif len(media.media_id) gt 0>
															<cfif relm.media_id eq '#media.media_id#'> 
																<cfset activeimg = "highlight_media rounded px-1 pt-2 ">
															<cfelse>	
																<cfset activeimg = "border-wide-ltgrey rounded bg-white px-1 pt-2">
															</cfif>

															<ul class="list-group px-0">
																<li class="list-group-item px-0 mx-1">
																<cfset mediablock= getMediaBlockHtml(media_id="#relm.media_id#",displayAs="thumb",size='70',captionAs="textCaptionFull")>
																<div class="#activeimg# image#i#" id="mediaBlock#relm.media_id#">
																	<!---Media Zoom/Related link should populate the area at the top with its image and metadata. Need something new on search.cfc? --->
																	<div class=" px-0"> #mediablock#</div>
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
									<h3 class="h4 mt-3 w-100 px-4 font-italic">Related media records not displayed. Click related media IDs above to see.</h3>
								</div>
							</cfif>
							</cfloop>
						</cfloop>
					</div>
				</div>
			</cfloop>
			</div>
			</div>
		</div>
	</main>
</cfoutput>
	
	
<cfinclude template="/shared/_footer.cfm">
