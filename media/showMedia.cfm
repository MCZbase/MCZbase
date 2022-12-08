<cfset pageTitle="Media">
<!--- WARNING: Major work needed.  This is not a redesigned document yet.  See todo notes below --->

<!--- TODO: The old MediaSearch.cfm provides both search results (which should be handled by the media search), and individual media records.  This does not fit the design intent for /media/showMedia.cfm which following redesign conventions would show one and only one media record.  This file needs to be restarted from scratch with a redesign template to show only single media records.  (it should be pretty simple, just header, relevant management links for the user's permission level,  an invocation of getMediaBlockHtml for the single record, and the footer). --->

<!--- TODO: Any api call for more than one image needs to be redirected to either the media search, to show the list of matching images there, or to a new redesigned media gallery which would allow the display of multiple images in larger than thumbnail size along with their metadata --->
<cfinclude template="/shared/_header.cfm">
<script type='text/javascript' src='/media/js/media.js'></script>
<cfinclude template="/media/component/search.cfc" runOnce="true">
<cfset maxMedia = 4>
<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
	<cfset oneOfUs = 1>
<cfelse>
	<cfset oneOfUs = 0>
</cfif>
<cfoutput>
<cfquery name="media" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select distinct 
		media.media_id,media.media_uri,media.mime_type,media.media_type,media.preview_uri 
	From
		media
	WHERE 
		media.media_id IN <cfqueryparam cfsqltype="CF_SQL_DECiMAL" value="#media_id#" list="yes">
		AND MCZBASE.is_media_encumbered(media_id)  < 1 
</cfquery>

	<cfloop query="media">
		<div class="container-fluid">
			<div class="row">
				<div class="col-12 pb-4">
					<main class="content">
						<div class="row mx-0">
							<div class="col-12 px-0 px-xl-5 mt-3">
								<h1 class="h2 mt-2 pb-1 mb-2 pb-2 border-bottom border-dark"> Media Record 	
									<button class="btn float-right btn-xs btn-primary" onClick="location.href='/MediaSet.cfm?media_id=#media_id#'">Media Viewer</button>
								</h1>
								<div class="h4 px-0 mt-0">Media ID = media/#media.media_id#</div>
							</div>
							<div class="col-12 px-0 px-xl-5 mt-2 mb-2">
								<cfif len(media.media_id) gt 0>
									<div class="rounded border bg-light col-12 col-sm-8 col-md-6 col-xl-3 float-left mb-2 pt-3 pb-0">
										<cfset mediablock= getMediaBlockHtml(media_id="#media_id#",size="400",captionAs="textFull")>
										<div class="mx-auto text-center pt-1" id="mediaBlock#media.media_id#"> #mediablock# </div>
									</div>
								</cfif>
								<cfset mediaMetadataBlock= getMediaMetadata(media_id="#media_id#")>
									<div id="mediaMetadataBlock#media.media_id#">
										#mediaMetadataBlock#
									</div>
								<!---to do -- make a table to support external renderings--->
								<!---<h3 class="h4 px-3 mb-1 pt-0">See additional rendering#plural# </h3>
								<ul class="list-group list-group-horizontal col-12 px-3">
									<cfif media.media_uri contains 'slide-atlas'>
										<li class="list-unstyled col-3 px-0 border bg-light text-center">
											<div id="content">
												<div class="flip-card">
													<div class="flip-card-inner">
														<a href="##" id="flip-card-inner">
															<div class="flip-card-front">
																<div class="heightFlip font-weight-lessbold bg-white text-dark"><img src="/images/slideatlas.jpg" class="mx-1" height="35" width="35" alt="slideatlas logo"><span class="h3 font-weight-bold text-black d-inline">Slide Atlas </span>Viewer</div>
															</div>
														</a>
														<div class="flip-card-back">
															<a class="link-color px-0 text-center" href="https://images.slide-atlas.org/##item/5915d8d0dd98b578723a09bf">SlideAtlas 
																<img src="/shared/images/linked_data.png" height="15" width="15" alt="linked data icon">
															</a>
															<div class="small">created: 2017-05-12, name: HEC-1606 (free-tailed bat), <br/>2.694 GB, ID: 5915d8d0dd98b578723a09bf</div>
														</div>
													</div>
												</div>
											</div>
										</li>
									</cfif>
									<cfif media.media_uri contains 'morphosource'>
										<li class="list-unstyled col-3 px-0 border bg-light text-center">
											<div id="content">
												<div class="flip-card">
													<div class="flip-card-inner">
														<a href="##" id="flip-card-inner">
															<div class="flip-card-front">
																<div class="heightFlip font-weight-lessbold">Morphosource</div>
															</div>
														</a>
														<div class="flip-card-back">
															<a class="link-color px-0 text-center" href="http://www.google.com">Morphosource logo </a>
															<div class="">slide metadata</div>
														</div>
													</div>
												</div>
											</div>
										</li>
									</cfif>
									<cfif media.media_uri contains 'slide-atlas' AND media.media_uri contains 'morphosource'>
										<cfset plural = "s">
									<cfelse>
										<cfset plural = "">
									</cfif>
									<cfif media.media_uri contains 'slide-atlas' OR media.media_uri contains 'morphosource'>
										<div class="row my-2">
										</div>
									</cfif>
								</ul>--->
							</div>
						</div>
					</main>
				</div>
			
			</div>
				</div>
	</cfloop>
</cfoutput>
<cfinclude template="/shared/_footer.cfm">
