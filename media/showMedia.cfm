<cfset pageTitle="Media">
<!--- WARNING: Major work needed.  This is not a redesigned document yet.  See todo notes below --->

<!--- TODO: The old MediaSearch.cfm provides both search results (which should be handled by the media search), and individual media records.  This does not fit the design intent for /media/showMedia.cfm which following redesign conventions would show one and only one media record.  This file needs to be restarted from scratch with a redesign template to show only single media records.  (it should be pretty simple, just header, relevant management links for the user's permission level,  an invocation of getMediaBlockHtml for the single record, and the footer). --->

<!--- TODO: Any api call for more than one image needs to be redirected to either the media search, to show the list of matching images there, or to a new redesigned media gallery which would allow the display of multiple images in larger than thumbnail size along with their metadata --->
<cfinclude template="/shared/_header.cfm">
<script type='text/javascript' src='/shared/js/media.js'></script>
<cfoutput>
<main class="container border-danger" id="content">
	<div class="row">
		<div class="col-12 mt-4 border-success">
		<h1 class="h4 mt-4">Media Record</h1>
			<cfquery name="findIDs" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select distinct 
						media.media_id,media.media_uri,media.mime_type,media.media_type,media.preview_uri, 
						MCZBASE.is_media_encumbered(media.media_id) hideMedia,
						MCZBASE.get_media_credit(media.media_id) as credit 
					From
						media
					WHERE 
						media.media_id = '1333'

			</cfquery>
			<cfloop query="findIDs">
			#media_id#
						</cfloop>
							</div>
					</div>
				</cfif>
				<cfset rownum=rownum+1>
			</cfloop>
		</div>
	</div>
</main>
</cfoutput>
<cfinclude template="/shared/_footer.cfm">
