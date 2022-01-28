<cfset pageTitle = "Media Gallery">
<cfinclude template = "/shared/_header.cfm">
<cfinclude template="/media/component/search.cfc" runOnce="true">

<cfoutput>
	<div class="container-fluid my-3">

		<h1 class="h2">Gallery of images for testing/debugging the media widget.</h1>

		<cfquery name="examples" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select distinct media_id from (
				select max(media_id) media_id from media
				group by mime_type, media_type
				union
				select max(media_id) media_id from media_relations
				group by media_relationship
				union
				select max(media_id) media_id from media
				group by media.auto_host
				having count(*) > 50
				union
				select max(media_id) from media_labels
				where media_label = 'height'
				group by label_value
				having count(*) > 1000
			)
		</cfquery>
		<div class="row">
			<cfloop query="examples">
				<div class="col-12 col-sm-6 col-md-4 col-xl-3 mt-5 bg-light">
					<cfset mediablock= getMediaBlockHtml(media_id="#media_id#",size="400", displayAs="full",captionAs="textMid")>
					<div id="mediaBlock#media_id#">
					#mediablock#
					</div>
				</div>
			</cfloop>
		</div>

		<div class="row">
			<cfloop query="examples">
				<div class="col-12 col-sm-4 col-md-2 col-xl-2 mt-5 bg-secondary">
					<cfset mediablock= getMediaBlockHtml(media_id="#media_id#",displayAs="thumb",captionAs="textShort")>
					<div id="mediaBlock#media_id#">
						#mediablock#
					</div>
				</div>
			</cfloop>
		</div>

		<div class="row">
			<cfloop query="examples">
				<div class="col-12 col-md-6 col-xl-4 mt-5 bg-dark">
					<cfset mediablock= getMediaBlockHtml(media_id="#media_id#",size="600",captionAs="textFull")>
					<div id="mediaBlock#media_id#">
					#mediablock#
					</div>
				</div>
			</cfloop>
		</div>
		
		<div class="row">
			<div class="col-10 float-left mt-5 border">
			<cfset media_id = "1333">
				<cfset mediablock= getMediaBlockHtml(media_id="#media_id#",displayAs="full",size="1000")>
				<div id="mediaFullBlock#media_id#">
					#mediablock#
				</div>
			</div>
			<div class="col-1 px-0 float-left mt-5 bg-warning">
			<cfset media_id = "90914">
				<cfset mediablock= getMediaBlockHtml(media_id="#media_id#",displayAs="thumb",size="100",captionAs="textLinks")>
				<div id="mediaThumbBlock#media_id#">
					#mediablock#
				</div>
			</div>	
		</div>

	</div>
</cfoutput>

<cfinclude template = "/shared/_footer.cfm">
