<cfset pageTitle="Media Record">
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
		media.media_id, MCZBASE.is_media_encumbered(media.media_id) hideMedia, media.media_uri
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
								<cfif media.media_uri contains 'mczbase'>
									<button class="btn float-right btn-xs btn-primary" onclick="location.href='/media/MediaViewer.cfm?media_id=#media_id#'">Media Viewer</button>
								<cfelse>
									<a class="btn float-right btn-xs btn-primary" href="#media.media_uri#>">Media Viewer</a>
								</cfif>
								</h1>
								<div class="h4 px-0 mt-0">Media ID = media/#media.media_id#</div>
							</div>
							<div class="col-12 px-0 px-xl-5 mt-2 mb-2">
								<cfif len(media.media_id) gt 0>
									<div class="rounded border bg-light col-12 col-sm-8 col-md-6 col-xl-3 float-left mb-2 pt-3 pb-0">
										<cfset mediablock= getMediaBlockHtml(media_id="#media_id#",size="400",captionAs="textLinks")>
										<div class="mx-auto text-center pt-1" id="mediaBlock#media.media_id#"> #mediablock# </div>
									</div>
								</cfif>
								<div class="float-left col-12 px-0 col-xl-9 pl-xl-4">
								<cfset mediaMetadataBlock= getMediaMetadata(media_id="#media_id#")>
									<div id="mediaMetadataBlock#media_id#">
										#mediaMetadataBlock#
									</div>
								</div>
									
									<cfset mediaRelStr= get_media_relations_string(media_id="#media_id#")>
									<div id="mediaRelStr#media_id#">
										#mediaRelStr#
									</div>
								</div>
							</div>
						</div>
					</main>
				</div>
			</div>
		</div>
	</cfloop>
</cfoutput>
<cfinclude template="/shared/_footer.cfm">
