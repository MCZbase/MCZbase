<cfinclude template="/media/component/search.cfc" runOnce="true">
<cfset pageTitle = "Media Record">
<cfinclude template = "/shared/_header.cfm">
<cfset media_id = 1333>
<cfquery name="findMedia" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
	select distinct 
		media.media_id,media.media_uri,media.mime_type,media.media_type,media.preview_uri, 
	WHERE media.media_id = '#media_id#'

</cfquery>	

<main id="content" class="container mt-5">
	<section class="row">
		<div class="col-12">
			<div class="col-3"><h1>Media</h1></div>
			<div class="col-9 text-left"><button class="btn btn-xs btn-primary ml-auto">Media Viewer</button></div>
			
		</div>
		<div class="col-12 col-md-6">
			<cfloop query="findMedia">
				<cfquery name="images" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT media_id,related_primary_key, collection_object_id 
					FROM media_relations, flat 
					WHERE media_relationship = 'shows cataloged_item' 
					AND flat.collection_object_id = media_relations.RELATED_PRIMARY_KEY
					AND media_id = '#findMedia.media_id#'
				</cfquery>
				<cfif len(#findMedia.description#)gt 0>
					<div class="col-12 col-md-3 px-1 float-left my-1">
						<div class="border rounded bg-white p-2 col-12 float-left">
							<div class="row mx-0">
								<cfif len(images.media_id) gt 0>
									<cfset mediablock= getMediaBlockHtml(media_id="#images.media_id#",displayAs="full",size="400",captionAs="textFull")>
										<div class="float-left" id="mediaBlock#images.media_id#">
											#mediablock#
										</div>
								</cfif>
							</div>
						</div>
					</div>
				</cfif>
			</cfloop>
		</div>
		</div>
		<div class="col-12 col-md-6">
		metadata
		</div>
	</section>

	<section class="row">
		<div class="col-12">
			<h3 class="h4">In catalog records</h3>
			<div class="col-12 px-0">
				Grid search results (like showNamedCollection)
			</div>
		</div>
		<div class="col-12">
			<h3 class="h4">In transaction records</h3>
			<div class="col-12 px-0">
				Grid search results (like showNamedCollection)
			</div>
		</div>
	</section>
</main>
	
	
<cfinclude template = "/shared/_footer.cfm">