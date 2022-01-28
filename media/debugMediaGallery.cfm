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
			<div class="container-fluid"><h4> Background light gray.  These examples are set with a size attribute (e.g., <strong>size="400"</strong>) and a captionAs attribute (e.g., <strong>textMid</strong>) to getMediaBlockHtml(). The image is sized to 400px wide and high and has a gray background where it doesn't fit the square. The preview_URI will be shown as is (sizewise).  The placeholder images are given a maximum width, which keeps them thumbnail size of 125px even if the container is larger and the size of the shared drive images are 400px. The thumbnail for spectrometer data (an SVG) could be better.  I couldn't find many public domain SVGs. Shrinking the container will shrink the caption and should be done with the "size". It is possible to allow these placeholder images to fill the container they are in by increasing the max-width (<cfset l_styles = "max-width:150px;max-height:auto;">--auto is need here because the text img is portrait size -- svg files so it shouldn't matter too much) on line 1121 of media/components/search.cfc. I figured out that italics cannot be in the description label or it breaks the html.</h4></div>
			<cfloop query="examples">
				<div class="col-12 col-sm-6 col-md-4 px-1 col-xl-3 mt-5 bg-light">
					<cfset mediablock= getMediaBlockHtml(media_id="#media_id#",size="400",captionAs="textMid")>
					<div id="mediaBlock#media_id#" class="border rounded mb-1">
					#mediablock#
					</div>
				</div>
			</cfloop>
		</div>

		<div class="row">
			<div class="container-fluid mt-5"><h4 class="mb-0"> Background teal.  These examples are set with displayAs set to "thumb" and a captionAs as "textMid" in getMediaBlockHtml(). The placeholder images are given a maximum width, which keeps them thumbnail size (max of 150px) even if the container is larger and the size of the shared-drive images are their intrinsic sizes.  It is possible to allow these placeholder images to fill their container by increasing the max-width (See <cfset l_styles = "max-width:150px;max-height:auto;"> on line 1121 of media/components/search.cfc.) </h4></div>
			<cfloop query="examples">
				<div class="col-12 col-sm-4 col-md-2 px-1 col-xl-2 mt-5" style="background-color:aquamarine">
					<cfset mediablock= getMediaBlockHtml(media_id="#media_id#",displayAs="thumb",captionAs="textShort")>
					<div id="mediaBlock#media_id#" class="border rounded mb-1">
						#mediablock#
					</div>
				</div>
			</cfloop>
		</div>

		<div class="row">
			<div class="container-fluid mt-5"><h4 class="mb-0"> Background blue.  These examples are set with size="600" captionAs="textFull" (still truncated to 250 chars)in getMediaBlockHtml(). Includes license info. </h4></div>
			<cfloop query="examples">
				<div class="col-12 col-md-6 col-xl-4 px-1 mt-5" style="background-color:aliceblue">
					<cfset mediablock= getMediaBlockHtml(media_id="#media_id#",size="600",captionAs="textFull")>
					<div id="mediaBlock#media_id#" class="border rounded mb-1">
					#mediablock#
					</div>
				</div>
			</cfloop>
		</div>
		
		<div class="row">
			<div class="col-10 float-left mt-5 px-1" style="background-color:lemonchiffon">
			<cfset media_id = "1333">
				<cfset mediablock= getMediaBlockHtml(media_id="#media_id#",displayAs="full",size="1000",captionAs="textFull")>
				<div id="mediaFullBlock#media_id#" class="border rounded mb-1">
					#mediablock#
				</div>
			</div>
		</div>
		<div class="row">
		<div class="container-fluid my-5"><h4 class="mb-0"> Background peach.  This example is the intrinsic size of the thumbnail (displayAs="thumb") with only the links --captionAs="textLinks".  </h4></div>
			<div class="col-1 px-0 float-left mt-5 px-1" style="background-color:peachpuff">
			<cfset media_id = "90914">
				<cfset mediablock= getMediaBlockHtml(media_id="#media_id#",displayAs="thumb",captionAs="textLinks")>
				<div id="mediaThumbBlock#media_id#" class="border rounded mb-1">
					#mediablock#
				</div>
			</div>	
		</div>

	</div>
</cfoutput>

<cfinclude template = "/shared/_footer.cfm">
