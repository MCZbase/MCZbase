<!---
/media/rescaleImage.cfm

Media image rescaling on the fly 

Copyright 2021 President and Fellows of Harvard College

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

Streams directly to response without use of CFFileServelet

--->
<!--- 

Expectations: Will always deliver an image file, unless debug=true is specified, in which case html may be delivered.

API

*** planned, not yet implemented ***

@param media_id  required, the media id to display, if none is given, returns an error icon image.

@param display = {media|preview}, default media
	if media: tries to use the media_uri, if this is not displayable, falls back to (a) 
		preview_uri if the requested size is small, if requested size is not small
		or no preview_uri is available, then (b) falls back to a generic icon based on the media_type.
	if preview: uses the preview_uri, if this is not specified, then falls back to
		a generic icon based on the media type.

@param width width of the image to return in pixels, height depends on the value of aspectRatio.

@param aspectRatio {original|square} default square
	if square, returns an image where width=height={pixels specified in width parameter} and 
		the the original image (media_uri, preview_uri, or fallback icon) is placed within that 
		square filling its entire height or width, with extra space on top/bottom or left right
		filled with the background color specified in background.
	if original, returns an image where width={pixels specified in width parameter} and height=
		height of the original image scaled by the ratio of its width to the specified width 
		(retaining the aspect ratio of the original image (media_uri, preview_uri, or fallback icon)

@param background = {grey|white} default grey
	the background color to fill a square image outside the bounds of the aspect ratio of the
	original image (media_uri, preview_uri, or fallback icon).
	the background parameter is ignored if aspect ratio is original. 

@param debug, if true, will dump exceptions as html instead of returning an error image.

---->
<!--- Setup default conditions --->
<cfset fitHeight = "">
<cfif isdefined("width") AND len(width) GT 0 and IsNumeric(width)>
	<cfset fitWidth = width>
	<cfif isdefined("height") AND len(height) GT 0 and IsNumeric(height)>
		<cfset fitHeight = height>
	<cfelse>
		<cfset fitHeight = "">
	</cfif>
<cfelse>
	<cfset fitWidth = 500>
</cfif>
<cfset mimeType = "image/png">
<cfif NOT isdefined("use_thumb") OR len(use_thumb) EQ 0>
	<cfset use_thumb = "false">
</cfif>
<cfif NOT isdefined("background_color") OR len(background_color) EQ 0>
	<cfset background_color = "grey">
</cfif>


<cfif NOT isdefined("media_id") OR len(media_id) EQ 0>
	<!---
		Bad request to rescaleImage.cfm, media_id is required, but rather than throwing an exception, as rescaleImage.cfm is 
      expected to be invoked from within an img tag as the src, fail gracefully by returning an image.
	--->
	<cfset imageSrc = "/shared/images/broken_image_icon_211476.png">
	<cflocation URL="#Application.serverRootUrl##imageSrc#">
	<cfabort>
<cfelse>
	<cfquery name="media" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="media_result">
		SELECT
			media_type, mime_type, media_uri, preview_uri,
			MCZBASE.get_medialabel(media.media_id,'width') as width
		FROM media
		WHERE
			media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
			AND MCZBASE.is_media_encumbered(media_id)  < 1 
	</cfquery>
	<cfif media.recordcount EQ 1>
		<cfset media_type = media.media_type>
		<cfloop query="media">
			<cfif mime_type EQ 'image/jpeg' OR mime_type EQ 'image/png'>
				<cfif len(media.width) GT 0 and media.width GT 0 AND fitWidth GT media.width AND len(fitHeight) EQ 0 >
					<!--- just deliver the image --->
					<cflocation URL="#media.media_uri#">
					<cfabort>
				<cfelse>
					<cfif use_thumb EQ "true">
						<cfset source = replace(preview_uri,'http://mczbase.mcz.harvard.edu','https://mczbase.mcz.harvard.edu') >
						<cfset mimeType = "#mime_type#">
					<cfelse>
						<!--- setup to rescale --->
						<cfset source = replace(media_uri,'http://mczbase.mcz.harvard.edu','https://mczbase.mcz.harvard.edu') >
						<cfset mimeType = "#mime_type#">
					</cfif>
				</cfif>
			<cfelse>
				<cfif media_type EQ 'image' AND len(media.width) GT 0 AND media.width GT 0 AND fitWidth GT media.width>
					<!--- just deliver the image --->
					<cflocation URL="#media.media_uri#">
					<cfabort>
				<cfelse>
					<!--- not an image file --->
					<cfset source = "">
					<cfif use_thumb EQ "true">
						<cfif len(media.preview_uri) GT 0>
							<cfset source = replace(preview_uri,'http://mczbase.mcz.harvard.edu','https://mczbase.mcz.harvard.edu') >
						</cfif>
					</cfif>
					<cfif len(source) EQ 0>
						<!--- icons for other media types --->
						<cfif media_type is "audio">
							<cfset source =  "#Application.webDirectory#/shared/images/Gnome-audio-volume-medium.svg">
						<cfelseif media_type IS "video">
							<cfset source =  "#Application.webDirectory#/shared/images/Gnome-media-playback-start.svg">
						<cfelseif media_type is "text">
							<cfset source =  "#Application.webDirectory#/shared/images/Gnome-text-x-generic.svg">
						<cfelseif media_type is "3D model">
							<cfset source =  "#Application.webDirectory#/shared/images/model_3d.svg">
						<cfelseif media_type is "spectrometer data">
							<cfset source = "#Application.webDirectory#/shared/images/Sine_waves_different_frequencies.svg">
						<cfelse>
							<cfset source = "#Application.webDirectory#/shared/images/noThumbDoc.png">
						</cfif>
					</cfif>
				</cfif>
			</cfif>
		</cfloop>
	<cfelse>
		<cfset media_type = "none">
		<!--- no matching media file found --->
		<cfset source = "#Application.webDirectory#/shared/images/missing_image_icon_298822.png">
	</cfif>
</cfif>

<!--- 
	NOTE WEll:  
	source is the original image file from media_uri, or its thumbnail from preview_uri or its replacement generic icon.
	targetImage is a square grey or white image that is the target into which source is pasted to obtain a square or other specified aspect ratio return image.
--->


<cftry>
	<cfif len(fitHeight) GT 0>
		<!--- Rescale the image to fit an image of the specified fitWidth and fitHeight, preserving the original aspect ratio of the image within the fit height/width image with a background where the aspect ratio of the original and fit targets differ --->
		<cfif lcase(background_color) EQ "white">
			<cfimage name="targetImage" source="#Application.webDirectory#/shared/images/white_background.png">
		<cfelse>
			<cfimage name="targetImage" source="#Application.webDirectory#/shared/images/grey_background.jpg">
		</cfif>
		<cfset ImageResize(targetImage,#fitWidth#,#fitHeight#,"highestPerformance") >
		<cftry>
			<cfimage name="sourceImage" source="#source#">
		<cfcatch>
			<!--- Fail gracefully --->
			<cfset failed = true>
			<cfif findNoCase("javax.net.ssl.SSLHandshakeException",cfcatch.detail) GT 0>
				<!--- cfimage source likely an https with a certificate authority too new for coldfusion --->
				<!--- obtain with curl, using -k option for insecure download --->
				<cftry>
					<!--- download resource, if we haven't allready --->
					<cfset filename= "cache_#media_id#_preview_uri.img">
					<cfif NOT FileExists("#Application.webDirectory#/temp/#filename#")>
						<cfexecute name="curl" arguments="-L -k -o #Application.webDirectory#/temp/#filename# #source#" timeout="10" variable="filestream">
					</cfif>
					<cftry>
						<cfimage name="sourceImage" source="#Application.webDirectory#/temp/#filename#">
						<cfset failed = false>
					<cfcatch>
						<!--- that didn't work, clean up --->
						<cffile action="delete" file="#Application.webDirectory#/temp/#filename#">
					</cfcatch>
					</cftry>
				<cfcatch>
					<!--- unable to retrieve and use --->
					<cfif isDefined("debug") AND len(debug) GT 0>
						<cfdump var="#cfcatch#">
						<cfabort>
					</cfif>
				</cfcatch>
				</cftry>
			</cfif>

			<cfif failed>
				<cfif media_type is "image">
					<cfset source = "#Application.webDirectory#/shared/images/generic_img_mtns.png">
				<cfelseif media_type is "audio">
					<cfset source =  "#Application.webDirectory#/shared/images/Gnome-audio-volume-medium.png">
				<cfelseif media_type IS "video">
					<cfset source =  "#Application.webDirectory#/shared/images/Gnome-media-playback-start.png">
				<cfelseif media_type is "text">
					<cfset source =  "#Application.webDirectory#/shared/images/Gnome-text-x-generic.png">
				<cfelseif media_type is "3D model">
					<cfset source =  "#Application.webDirectory#/shared/images/model_3d.png">
				<cfelseif media_type is "spectrometer data">
					<cfset source = "#Application.webDirectory#/shared/images/Sine_waves_different_frequencies.png">
				<cfelse>
					<cfset source =  "#Application.webDirectory#/shared/images/generic_img_mtns.png">
				</cfif>
				<cfimage name="sourceImage" source="#source#">
			</cfif>
		</cfcatch>
		</cftry>
		<cfset ImageSetAntialiasing(sourceImage,"on")>
		<cfset ImageScaleToFit(sourceImage,#fitWidth#,#fitHeight#,"highestPerformance")>
		<cfset sourceWidth = ImageGetWidth(sourceImage)>
		<cfset ulx = (fitWidth - sourceWidth)/2>
		<cfif ulx LT 1 ><cfset ulx = 1></cfif>
		<cfset sourceHeight = ImageGetHeight(sourceImage)>
		<cfif #fitHeight# lt '300'>
			<!--- place the sourceImage(thumbnail) at the top of the targetImage(background square) --->
			<cfset uly = 1>
		<cfelse>
			<!--- vertically center the sourceImage(thumbnail) in the targetImage(background square) --->
			<cfset uly = (fitHeight - sourceHeight)/2>
		</cfif>
		<cfif uly LT 1 >
			<!--- place the sourceImage(thumbnail) at the top of the targetImage(background square) --->
			<cfset uly = 1>
		</cfif>
		<cfset ImagePaste(targetImage,sourceImage,ulx,uly)>
		<cfset response = getPageContext().getFusionContext().getResponse()>
		<cfheader name="Content-Type" value="image/jpeg">
		<cfset response.getOutputStream().writeThrough(ImageGetBlob(targetImage))>
		<cfabort>
	<cfelse>
		<!--- Rescale the image to fit the provided width --->
		<cftry>
			<cfimage source="#source#" name="targetImage">
		<cfcatch>
			<!--- Fail gracefully --->
			<cfif lcase(background_color) EQ "white">
				<cfimage name="targetImage" source="#Application.webDirectory#/shared/images/white_background.png">
			<cfelse>
				<cfimage name="targetImage" source="#Application.webDirectory#/shared/images/grey_background.jpg">
			</cfif>
			<cfset ImageResize(targetImage,#fitWidth#,#fitHeight#,"highestPerformance") >
			<cfif media_type is "image">
				<cfset source = "#Application.webDirectory#/shared/images/generic_img_mtns.png">
			<cfelseif media_type is "audio">
				<cfset source =  "#Application.webDirectory#/shared/images/Gnome-audio-volume-medium.png">
			<cfelseif media_type IS "video">
				<cfset source =  "#Application.webDirectory#/shared/images/Gnome-media-playback-start.png">
			<cfelseif media_type is "text">
				<cfset source =  "#Application.webDirectory#/shared/images/Gnome-text-x-generic.png">
			<cfelseif media_type is "3D model">
				<cfset source =  "#Application.webDirectory#/shared/images/model_3d.png">
			<cfelseif media_type is "spectrometer data">
				<cfset source = "#Application.webDirectory#/shared/images/Sine_waves_different_frequencies.png">
			<cfelse>
				<cfset source =  "#Application.webDirectory#/shared/images/generic_img_mtns.png">
			</cfif>
			<cfimage name="sourceImage" source="#source#">
			<cfset sourceWidth = ImageGetWidth(sourceImage)>
			<cfset ulx = (fitWidth - sourceWidth)/2>
			<cfif ulx LT 1 ><cfset ulx = 1></cfif>
			<cfset sourceHeight = ImageGetHeight(sourceImage)>
			<cfif #fitHeight# lt '300'>
				<!--- place the sourceImage(thumbnail) at the top of the targetImage(background square) --->
				<cfset uly = 1>
			<cfelse>
				<cfset uly = (fitHeight - sourceHeight)/2>
				<!--- vertically center the sourceImage(thumbnail) in the targetImage(background square) --->
			</cfif>
			<cfif uly LT 1 >
				<!--- place the sourceImage(thumbnail) at the top of the targetImage(background square) --->
				<cfset uly = 1>
			</cfif>
			<cfset ImagePaste(targetImage,sourceImage,ulx,uly)>
		</cfcatch>
		</cftry>
		<cfset ImageSetAntialiasing(targetImage,"on")>
		<cfset ImageScaleToFit(targetImage,#fitWidth#,"","highestPerformance")>
		<cfset response = getPageContext().getFusionContext().getResponse()>
		<cfheader name="Content-Type" value="#mimeType#">
		<cfset response.getOutputStream().writeThrough(ImageGetBlob(targetImage))>
		<cfabort>
	</cfif>
<cfcatch>
	<cfif isDefined("debug") AND len(debug) GT 0>
		<cfdump var="#cfcatch#">
		<cfif isDefined("source")>
			<cfdump var="#source#">
		</cfif>
		<cfdump var="#GetReadableImageFormats()#">
		<cfabort>
	</cfif>
	<cfset imageSrc = "/shared/images/broken_image_icon_211476.png">
	<cflocation URL="#Application.serverRootUrl##imageSrc#">
</cfcatch>
</cftry>

