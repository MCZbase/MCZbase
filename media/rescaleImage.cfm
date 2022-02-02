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
		<cfloop query="media">
			<cfif mime_type EQ 'image/jpeg' OR mime_type EQ 'image/png'>
				<cfif len(media.width) GT 0 and media.width GT 0 AND fitWidth GT media.width AND len(fitHeight) EQ 0 >
					<!--- just deliver the image --->
					<cflocation URL="#media.media_uri#">
					<cfabort>
				<cfelse>
					<cfif use_thumb EQ "true">
						<cfset source = replace(preview_uri,'https://mczbase.mcz.harvard.edu','#Application.webDirectory#') >
						<cfset source = replace(preview_uri,'http://mczbase.mcz.harvard.edu','#Application.webDirectory#') >
						<!--- TODO: identify mime type from preview.  --->
						<cfset mimeType = "#mime_type#">
					<cfelse>
						<!--- setup to rescale --->
						<cfset source = replace(media_uri,'https://mczbase.mcz.harvard.edu','#Application.webDirectory#') >
						<cfset source = replace(media_uri,'http://mczbase.mcz.harvard.edu','#Application.webDirectory#') >
						<cfset mimeType = "#mime_type#">
					</cfif>
				</cfif>
			<cfelse>
				<cfif media_type EQ 'image'>
					<cfif len(media.width) GT 0 and media.width GT 0 AND fitWidth GT media.width>
						<!--- just deliver the image --->
						<cflocation URL="#media.media_uri#">
						<cfabort>
					<cfelse>
						<cfset source = "#Application.webDirectory#/shared/images/noExternalImage.png">
					</cfif>
				<cfelse>
					<!--- not an image file --->
					<cfset source = "">
					<cfif use_thumb EQ "true">
						<cfif len(media.preview_uri) GT 0>
							<cfset source = replace(preview_uri,'https://mczbase.mcz.harvard.edu','#Application.webDirectory#') >
							<cfset source = replace(preview_uri,'http://mczbase.mcz.harvard.edu','#Application.webDirectory#') >
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
		<!--- no matching media file found --->
		<cfset source = "#Application.webDirectory#/shared/images/missing_image_icon_298822.png">
	</cfif>
</cfif>

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
			<cfif media_type is "image">
				<cfset displayImage = "#Application.webDirectory#/shared/images/Image-x-generic.png">
			<cfelseif media_type is "audio">
				<cfset displayImage =  "#Application.webDirectory#/shared/images/Gnome-audio-volume-medium.png">
			<cfelseif media_type IS "video">
				<cfset displayImage =  "#Application.webDirectory#/shared/images/Gnome-media-playback-start.png">
			<cfelseif media_type is "text">
				<cfset displayImage =  "#Application.webDirectory#/shared/images/Gnome-text-x-generic.png">
			<cfelseif media_type is "3D model">
				<cfset displayImage =  "#Application.webDirectory#/shared/images/model_3d.png">
			<cfelseif media_type is "spectrometer data">
				<cfset displayImage = "#Application.webDirectory#/shared/images/Sine_waves_different_frequencies.png">
			<cfelse>
				<cfset displayImage =  "#Application.webDirectory#/shared/images/Image-x-generic.png">
			</cfif>
			<cfimage name="sourceImage" source="#source#">
		</cfcatch>
		</cftry>
		<cfset ImageSetAntialiasing(sourceImage,"on")>
		<cfset ImageScaleToFit(sourceImage,#fitWidth#,#fitHeight#,"highestPerformance")>
		<cfset sourceWidth = ImageGetWidth(sourceImage)>
		<cfset ulx = (fitWidth - sourceWidth)/2>
		<cfif ulx LT 1 ><cfset ulx = 1></cfif>
		<cfset sourceHeight = ImageGetHeight(sourceImage)>
		<cfif #fitHeight# lt '500'>
			<cfset uly = 1>
		<cfelse>
			<cfset uly = (fitHeight - sourceHeight)/2>
		</cfif>
		<cfif uly LT 1 >
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
			<cfif media_type is "image">
				<cfset displayImage = "#Application.webDirectory#/shared/images/Image-x-generic.png">
			<cfelseif media_type is "audio">
				<cfset displayImage =  "#Application.webDirectory#/shared/images/Gnome-audio-volume-medium.png">
			<cfelseif media_type IS "video">
				<cfset displayImage =  "#Application.webDirectory#/shared/images/Gnome-media-playback-start.png">
			<cfelseif media_type is "text">
				<cfset displayImage =  "#Application.webDirectory#/shared/images/Gnome-text-x-generic.png">
			<cfelseif media_type is "3D model">
				<cfset displayImage =  "#Application.webDirectory#/shared/images/model_3d.png">
			<cfelseif media_type is "spectrometer data">
				<cfset displayImage = "#Application.webDirectory#/shared/images/Sine_waves_different_frequencies.png">
			<cfelse>
				<cfset displayImage =  "#Application.webDirectory#/shared/images/Image-x-generic.png">
			</cfif>
			<cfimage name="sourceImage" source="#source#">
		</cfcatch>
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
		<cfdump var="#GetReadableImageFormats()#">
		<cfabort>
	</cfif>
	<cfset imageSrc = "/shared/images/broken_image_icon_211476.png">
	<cflocation URL="#Application.serverRootUrl##imageSrc#">
</cfcatch>
</cftry>

