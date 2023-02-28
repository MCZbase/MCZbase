<cfset pageTitle="Media Record">

<cfinclude template="/shared/_header.cfm">
<script type='text/javascript' src='/media/js/media.js'></script>
<cfinclude template="/media/component/public.cfc" runOnce="true">
<cfset maxMedia = 4>
<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
	<cfset oneOfUs = 1>
<cfelse>
	<cfset oneOfUs = 0>
</cfif>
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
	<div class="container-fluid container-xl px-0 py-1">
		<div class="row">
			<div class="col-10 mx-auto px-1 px-md-0 pb-4">
				<main class="content">
					<div class="row mx-0">
						<div class="col-12 px-0 border-bottom border-dark my-3">
							<h1 class="h2 my-2 py-2 px-2"> Media Record 	
							<cfif media.media_uri contains 'mczbase'>
								<cfif media.recordcount gt 0>
								<button class="btn float-right btn-xs btn-primary" onclick="location.href='/media/RelatedMedia.cfm?media_id=#media_id#'">Related Media</button>
								</cfif>
							<cfelse>
								<button class="btn float-right btn-xs btn-primary" onclick="location.href='/media/RelatedMedia.cfm?media_id=#media_id#'">Related Media</button>
								<a class="btn float-right btn-xs btn-primary mx-2" href="#media.media_uri#>">External Viewer <img src="/images/linkOut.gif" alt="arrow out"></a>
							</cfif>
							</h1>
						</div>
						<div class="col-12 px-0 my-0">
							<cfif len(media.media_id) gt 0>
								<div class="rounded border bg-light col-12 col-md-3 float-left my-2 pt-3 pb-0">
									<cfset mediablock= getMediaBlockHtml(media_id="#media_id#",size="400",captionAs="textCaptionFull")>
									<div class="mx-auto text-center h3 pt-1" id="mediaBlock#media.media_id#"> #mediablock# </div>
								</div>
							</cfif>
							<div class="float-left col-12 col-md-9 px-0 mt-2 pl-md-4">
								<cfset mediaMetadataBlock= getMediaMetadata(media_id="#media_id#")>
								<div id="mediaMetadataBlock#media_id#">
									#mediaMetadataBlock#
								</div>
							</div>
						</div>
					</div>
				</main>
			</div>
		</div>
	</div>
</cfoutput>
<cfinclude template="/shared/_footer.cfm">
