<!---
media/component/public.cfc

Copyright 2020 President and Fellows of Harvard College

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

--->
<cfcomponent>
<cf_rolecheck>
<cfif NOT isDefined("reportError")>
	<cfinclude template="/shared/component/error_handler.cfc" runOnce="true">
</cfif>


<!--- function getMediaBlockHtml safely (with use of is_media_encumbered) display an html block
 serving as an arbitrary media display widget on any MCZbase page in a conistent manner.
 Appropriately handles media objects of all types, displaying appropriate metadata and thumbnail
 or larger image for the requested context.   Responsibility for delivering the desired image is
 split between this function, and where it is invoked by this function in an img tag, 
 /media/rescaleImage.cfm?media_id=.

 Threaded wrapper for getMediaBlockHtmlUnthreaded, use getMediaBlockHtml when invoked directly in
 an ajax call, use getMediaBlockHtmlUnthreaded when calling from another thread.  

 WARNING: Do not make copies of this function and use elsewhere, include this function and use it.

*** current API ***

 @param media_id the media_id of the media record to display a media widget for.
 @param size the size, an integer for pixel size of the image tag to include in the widget, image tags are
   always square (except for thumb), with the image fitted into this square preserving its aspect ratio within this 
   square, so size specifies both the height and width of the img tag in the returned html block,
   default is 600.
 @param displayAs the mode in which to display this media block, default is full, allowed values are
   full, fixedSmallThumb (which always returns a square image fitted to the specified size), and thumb
   (which returns a thumbnail with its original aspect ratio). 
 @param captionAs the caption which should be shown, allowed values are textFull, textNone (no caption
   shown, image is linked to media record instead of the media_uri resource), textLinks (caption is 
   limited to links without descriptive text, image is linked to the media_uri resource).
 @param background_class a value for the class of the image tag, <img class="{background}", intended
   for setting the background color for transparent images.
 @param background_color white or grey, the background color of the non-transparent image produced in 
   displayAs fixedSmallThumb, only applies to fixedSmallTnumb
 @parm styles a css value to use for style="" in the image tag, probably required if thumb is specified.


*** planned, not yet implemented, API ***

getMediaBlockHtml returns a block of html with an img tag appropriate to the requested media object 
enclosing anchor, divs, and optionally a caption for the image, these together comprise a media widget. 

<div>
...
<a href={media_uri or media/media_id, depending on value of caption}>
  <img src={*?? always rescaleImage.cfm?media_id=media_id&width={width}&... ??*} 
		height={depend on values of widthAs and width} 
		width={depends on values of widthAs and width} 
		class={imgStyleClass}
	>
</a>
...
Caption here
...
</div>

@param media_id  required, the media_id of the media record for which to display a media widget.

caption={full,links,none}
	if full a caption with metadata is provided for the image.
	if links, only links to metadata are provided for the image.
	if none, only the image is shown linked to the metadata record for the media object.

@param display = {media|preview}, default media

@param width width of the image to return in pixels, height depends on the value of aspectRatio.
	parameter passed on to rescaleImage.cfm?width

@param widthAs {auto,100pct,pixels}
	how the width parameter is used in the image tag (??? and surrounding html ???).
	if auto or 100pct, then img height=auto/100% width=auto/100pct
	if pixels, and aspectRatio=square then img height={width} width={width}
	if pixels and aspectRatio=original *** behavior not yet defined, may be invalid ***

@param aspectRatio {original|square} default square
	** to work out, if square, img src will be media/rescaleImage.cfm?aspectRatio.square
	** if orginal, might the media_uri or preview uri be used instead of rescaleImage.cfm
	** perhaps media block always uses rescaleImage.cfm, which should be then called
   ** deliverAsImage.cfm....
   // *** we need to think about this, perhaps always use  rescaleImage.cfm ??? ****

@param background = {grey|white} default grey
	parameter passed on to rescaleImage.cfm?background.  
   the background color to fill a square image outside the bounds of the aspect ratio of the
   original image (media_uri, preview_uri, or fallback icon).
   the background parameter is ignored if aspect ratio is original. 

imgStyleClass=value 
	where value is passed to img class="{value}"


---> 
<cffunction name="getMediaBlockHtml" access="remote" returntype="string" returnformat="plain">
	<cfargument name="media_id" type="string" required="yes">
	<cfargument name="size" type="string" required="no" default="600">
	<cfargument name="displayAs" type="string" required="no" default="full">
	<cfargument name="captionAs" type="string" required="no" default="textFull">
	<cfargument name="background_class" type="string" required="no" default="bg-light">
	<cfargument name="background_color" type="string" required="no" default="grey">
	<cfargument name="styles" type="string" required="no" default="max-width:100%;max-height:100%">
	<!--- argument scope isn't available within the cfthread, so creating explicit local variables to bring optional arguments into scope within the thread --->
	<cfset l_media_id= #arguments.media_id#>
	<cfset l_displayAs = #arguments.displayAs#>
	<cfset l_size = #arguments.size#>
	<cfset l_styles = #arguments.styles#>
	<cfset l_captionAs = #arguments.captionAs#>
	<cfset l_background_class = #arguments.background_class#>
	<cfset l_background_color = #arguments.background_color#>
	<cfset tn = REReplace(CreateUUID(), "[-]", "", "all") >	
	<cfthread name="mediaWidgetThread#tn#" threadName="mediaWidgetThread#tn#">
		<cfoutput>
			<cfset output = getMediaBlockHtmlUnthreaded(media_id="#l_media_id#",displayAs="#l_displayAs#",size="#l_size#",styles="#l_styles#",captionAs="#l_captionAs#",background_class="#l_background_class#",background_color="#l_background_color#")>
				
			#output#
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="mediaWidgetThread#tn#" />
	<cfreturn cfthread["mediaWidgetThread#tn#"].output>
</cffunction>

<!--- implementation for getMediaBlockHtml without creating a new thread 
 @see getMediaBlockHtml for API documentation.  
 WARNING: Do not make copies of this function and use elsewhere, include this function and use it.
  --->
<cffunction name="getMediaBlockHtmlUnthreaded" access="remote" returntype="string" returnformat="plain">
	<cfargument name="media_id" type="string" required="yes">
	<cfargument name="size" type="string" required="no" default="600">
	<cfargument name="box" type="string" required="no" default="">
	<cfargument name="displayAs" type="string" required="no" default="full">
	<cfargument name="captionAs" type="string" required="no" default="textFull">
	<cfargument name="background_class" type="string" required="no" default="bg-light">
	<cfargument name="background_color" type="string" required="no" default="##f8f9fa !important;">
	<cfargument name="styles" type="string" required="no" default="height: 76px;margin: 0 auto;width:auto;">
	<cfargument name="minheight" type="string" required="no" default="min-height:100px;">
	<cfif displayAs EQ "fixedSmallThumb">
		<cfif size lte 200>
			<cfset size = 75>
		</cfif>
	</cfif>
	<cfset output = "">
	<cfoutput>
		<cftry>
			<cfquery name="media" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="media_result">
				SELECT media_id, 
					preview_uri, media_uri, 
					mime_type, media_type,
					auto_extension as extension,
					auto_host as host,
					auto_path as path,
					auto_filename as filename,
					MCZBASE.get_media_dctermsrights(media.media_id) as license_uri, 
					MCZBASE.get_media_dcrights(media.media_id) as license_display, 
					MCZBASE.get_media_credit(media.media_id) as credit,
					MCZBASE.get_media_owner(media.media_id) as owner,
					MCZBASE.get_media_creator(media.media_id) as creator,
					MCZBASE.GET_MEDIA_COPYRIGHT(media.media_id) as copyright_statement,
					MCZBASE.get_medialabel(media.media_id,'aspect') as aspect,
					MCZBASE.get_medialabel(media.media_id,'description') as description,
					MCZBASE.get_medialabel(media.media_id,'made date') as made_date,
					MCZBASE.get_medialabel(media.media_id,'subject') as subject,
					MCZBASE.get_medialabel(media.media_id,'height') as height,
					MCZBASE.get_medialabel(media.media_id,'width') as width,
					MCZBASE.get_media_descriptor(media.media_id) as alt,
					MCZBASE.get_media_title(media.media_id) as title
				FROM 
					media
					left join ctmedia_license on media.media_license_id=ctmedia_license.media_license_id
				WHERE 
					media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
					AND MCZBASE.is_media_encumbered(media.media_id)  < 1 
				ORDER BY LENGTH(MCZBASE.get_media_title(media.media_id)) DESC
			</cfquery>
			<cfif media.recordcount EQ 1>
				<cfset i= 1>
				<cfloop query="media">
					<!--- to turn on rewriting to deliver media via iiif server, set enableIIIF to true, to turn of, set to false --->
					<cfset enableIIIF = true>
					<cfset iiifFull = "">
					<cfif host EQ "mczbase.mcz.harvard.edu" AND enableIIIF>
						<cfif media_type EQ 'image' AND left(media.mime_type,6) EQ 'image/'>
							<cfset iiifSchemeServerPrefix = "#Application.protocol#://iiif.mcz.harvard.edu/iiif/3/">
							<cfset iiifIdentifier = "#encodeForURL(replace(path,'/specimen_images/',''))##encodeForURL(filename)#">
							<!---cfset iiifFull = "#iiifSchemeServerPrefix##iiifIdentifier#/full/max/0/default.jpg"--->
							<!---Temporarily limiting the max size of the returned images to avoid overloading the iiif server--->
							<cfset iiifFull = "#iiifSchemeServerPrefix##iiifIdentifier#/full/!2000,2000/0/default.jpg">
							<cfset iiifSize = "#iiifSchemeServerPrefix##iiifIdentifier#/full/^#size#,/0/default.jpg">
							<cfset iiifThumb = "#iiifSchemeServerPrefix##iiifIdentifier#/full/,70/0/default.jpg">
						</cfif>
					</cfif>
					<cfset isDisplayable = false>
					<cfif media_type EQ 'image' AND (media.mime_type EQ 'image/jpeg' OR media.mime_type EQ 'image/png' OR (media.mime_type EQ 'image/tiff' AND enableIIIF))>
						<cfset isDisplayable = true>
					</cfif>
					<cfif media_type EQ '3D model'>
						<cfset isDisplayable = false>
					</cfif>
					<cfset altEscaped = replace(replace(alt,"'","&##8217;","all"),'"',"&quot;","all") >
					<cfset hw = 'height="auto"'>
					<cfif isDisplayable>
						<!--- the resource specified by media_uri should be an image that can be displayed in a browser with img src=media_uri --->
						<cfif #displayAs# EQ "fixedSmallThumb">
							<cfset hw = 'height="#size#" width="#size#"'>
							<cfset sizeParameters='&width=#size#&height=#size#'>
							<cfset displayImage = "/media/rescaleImage.cfm?use_thumb=true&media_id=#media.media_id##sizeParameters#&background_color=#background_color#">
						<cfelseif #displayAs# EQ "thumb">
							<cfset displayImage = preview_uri>
							<cfset hw = 'width="auto" height="auto"'>
							<cfset styles = "max-height:70px;">
							<cfif host EQ "mczbase.mcz.harvard.edu" AND enableIIIF >
								<cfset displayImage = iiifThumb>
							</cfif>
						<cfelse>
							<cfif host EQ "mczbase.mcz.harvard.edu" AND enableIIIF>
								<cfset sizeParameters='&width=#size#&height=#size#'>
								<!--- cfset displayImage = "/media/rescaleImage.cfm?media_id=#media.media_id##sizeParameters#" --->
								<cfset displayImage = iiifSize>
							<cfelse>
								<cfset displayImage = media_uri>
									<cfset styles = "height: 123px;margin: 0 auto;width: auto">
							</cfif>
						</cfif>
					<cfelse>
						<!--- the resource specified by media_uri is not one that can be used in an image tag as img src="media_uri", we need to provide an alternative --->
						<cfif len(preview_uri) GT 0>
						 	<!--- there is a preview_uri, use that --->
							<cfif #displayAs# EQ "fixedSmallThumb">
								<cfset hw = 'height="#size#" width="#size#"'>
								<cfset sizeParameters='&width=#size#&height=#size#'>
								<cfset displayImage = "/media/rescaleImage.cfm?use_thumb=true&media_id=#media.media_id##sizeParameters#&background_color=#background_color#">
								<cfset styles = "height: 76px;margin: 0 auto;width: auto">
							<cfelse>
								<!--- use a preview_uri, if one was specified --->
								<!--- TODO: change test to regex on http... with some sort of is this an image test --->
								<cfset displayImage = preview_uri>
								<cfif #displayAs# eq "thumb">
									<cfset hw = 'width="auto" height="auto"'>
									<cfset styles = "height: 76px;margin: 0 auto;width: auto;">
								<cfelse>
									<!---for shared drive images when the displayAs=thumb attribute is not used and a size is used instead. Since most of our intrinsic thumbnails in "preview_uri" field are around 150px or smaller, I will use that as the width. Height is "auto" for landscape and portrait.  --[changed from 100 to auto-3/14/22 MK ledgers were too tall--need to check other types--it was changed at some point] ---->
									<!---Just making a note that it was this when it worked: <cfif #media_uri# CONTAINS "nrs" OR #media_URI# CONTAINS "morphosource">--->
									<cfif host EQ "nrs.harvard.edu" OR host EQ "www.morphosource.org">
										<cfset hw = 'width="95" height="auto"'>
										<cfset styles = "height: auto;margin: 0 auto;width: auto">
										<cfset minheight = "min-height: auto">
					
									<cfelse>
											<cfset hw = 'width="auto" height="auto"'>
											<cfset styles = "height: 74px;margin: 0 auto;width: auto">
											<cfset minheight = "min-height: auto">
									</cfif>
								</cfif>
							</cfif>
						<cfelse>
							<cfif #displayAs# EQ "fixedSmallThumb">
								<!--- leave it to logic in media/rescaleImage.cfm to work out correct icon and rescale it to fit desired size --->
								<cfset hw = 'height="#size#px;" width="#size#px;"'>
								<cfset sizeParameters='&width=#size#&height=#size#'>
								<cfset displayImage = "/media/rescaleImage.cfm?use_thumb=true&media_id=#media.media_id##sizeParameters#&background_color=#background_color#">
							<cfelse>
								<!--- fall back on an svg image of an appropriate generic icon --->
								<cfif CGI.script_name CONTAINS "/RelatedMedia.cfm">
									<cfset size = "90"><!---was 200--->
										<cfset styles = "max-height:;width:auto;">
								<cfelse>
									<cfset size = "90">
								</cfif>
								
								<!---auto is need here because the text img is portrait size -- svg files so it shouldn't matter too much.--->
								<cfset hw = 'height="#size#" width="#size#"'>
								<!--- pick placeholder --->
								<cfif media_type is "image">
									<cfset displayImage = "/shared/images/tag-placeholder.png">
								<cfelseif media_type is "audio">
									<cfset displayImage =  "/shared/images/Gnome-audio-volume-medium.svg">
								<cfelseif media_type IS "video">
									<cfset displayImage =  "/shared/images/Gnome-media-playback-start.svg">
								<cfelseif media_type is "text">
									<cfset displayImage =  "/shared/images/Gnome-text-x-generic.svg">
								<cfelseif media_type is "3D model">
									<cfset displayImage =  "/shared/images/model_3d.svg">
								<cfelseif media_type is "spectrometer data">
									<cfset displayImage = "/shared/images/Sine_waves_different_frequencies.svg">
								<cfelse>
									<cfset displayImage =  "/shared/images/tag-placeholder.svg">
									<!--- media_type is not on the known list --->
								</cfif>
							</cfif>
						</cfif>
					</cfif>
					<!--- prepare output --->

					<cfset output='#output#<div class="media_widget p-1" style="#minheight#">'>	
					<!--- WARNING: if no caption text is shown, the image MUST link to the media metadata record, not the media object, otherwise rights information and other essential metadata are not shown to or reachable by the user. --->
					<cfif #captionAs# EQ "textNone">
						<cfset linkTarget = "/media/#media.media_id#">
					<cfelse>
						<cfset linkTarget = "#media.media_uri#">
					</cfif>
					<cfif host EQ "mczbase.mcz.harvard.edu" AND enableIIIF AND isDefined("iiifFull") AND len(iiifFull) GT 0>
						<cfset linkTarget = iiifFull>
					</cfif>
						<!---Removed on 1/20/23 from <img...> tag: class="#background_class#"--->
					<cfset output='#output#<a href="#linkTarget#" class="d-block mb-1 w-100 active text-center" title="click to access media">'>
					<cfset output='#output#<img id="MID#media.media_id#" src="#displayImage#" alt="#alt#" #hw# style="#styles#" title="Click for full image">'>
					<cfset output='#output#</a>'>
							<cfif isDisplayable><cfset output='#output#<script type="text/javascript">jQuery(document).ready(function($){$("##MID#media.media_id#").addimagezoom({zoomrange: [2,12],magnifiersize:["100%","100%"],magnifierpos:"right",cursorshadecolor:"##fdffd5",imagevertcenter:"true",cursorshade:true,largeimage:"#iiifFull#"})})</script>'></cfif>
					<cfif #captionAs# EQ "textNone">
						<!---textNone is used when we don't want any text (including links) below the thumbnail. This is used on Featured Collections of cataloged items on the specimenBrowse.cfm and grouping/index.cfm pages--->
					<cfelseif #captionAs# EQ "textLinks">
						<!--- textLinks is used when only the links are desired under the thumbnail--->
						<cfset output='#output#<div class="mt-0 col-12 pb-1 px-0">'>
						<cfset output='#output#<p class="text-center px-1 pb-1 mb-0 small col-12">'>
						<cfif listcontainsnocase(session.roles,"manage_specimens")>
							<cfset output='#output#<span class="d-inline">(<a href="/media.cfm?action=edit&media_id=#media_id#">edit</a>) </span>'>
						</cfif>
						<cfset output='#output#(<a class="" href="/media/#media_id#">Media Record</a>)'>
						<cfif NOT isDisplayable>
							<cfif listcontainsnocase(session.roles,"manage_publications")> <span class="sr-only">#media_type# (#mime_type#)</span></cfif>
								<cfset output='#output#(<a class="" href="#media_uri#">media file</a>)'>
							<cfelse>
								<cfif CGI.script_name CONTAINS "/RelatedMedia.cfm">
									<!---If on the zoom/related page, i.e. RelatedMedia.cfm, we don't need a link to it.--->
									
								<cfelse><!---Changed else on 1/20/23 to make it easier to test--->
									<!---<cfset output='#output#(<a class="" href="/MediaSet.cfm?media_id=#media_id#">zoom/related</a>)'>---><!-- should make it show on spec details--->
									<cfset output='#output#<span class="d-none d-md-inline-block">(<a class="" href="/media/RelatedMedia.cfm?media_id=#media_id#">zoom/related</a>)</span>'>
								</cfif>
								<cfif len(iiifFull) GT 0>
									<cfset output='#output#(<a class="" href="#iiifFull#">full</a>)'>
								<cfelse>
									<cfset output='#output#(<a class="" href="#media_uri#">full</a>)'>
								</cfif>
							</cfif>
							<cfset output='#output#</p>'>
						<cfset output='#output#</div>'>
					<cfelse>
						<cfset output='#output#<div class="mt-0 col-12 pb-2 px-0">'>
						<cfset output='#output#<p class="text-center px-1 pb-0 mb-0 small col-12">'>
						<cfif listcontainsnocase(session.roles,"manage_specimens")>
							<cfset output='#output#<span class="d-inline">(<a href="/media.cfm?action=edit&media_id=#media_id#">Edit</a>) </span>'>
						</cfif>
						<cfset output='#output#(<a class="" href="/media/#media_id#">Media Record</a>) '>
						<cfif NOT isDisplayable>
							<cfif listcontainsnocase(session.roles,"manage_publications")><span class="sr-only">#media_type# (#mime_type#)</span></cfif>
							<cfset output='#output#(<a class="" href="/media/RelatedMedia.cfm?media_id=#media_id#">Related</a>) '>
							<cfset output='#output#(<a class="" href="#media_uri#">File</a>)'>
							
						<cfelse>
							<cfif CGI.script_name CONTAINS "/RelatedMedia.cfm">
								<cfset output='#output#(<a class="" href="/media/RelatedMedia.cfm?media_id=#media_id#">Related</a>) '>
							<cfelse>
								<!---<cfset output='#output#(<a class="" href="/MediaSet.cfm?media_id=#media_id#">zoom/related</a>)'>--->
								<cfset output='#output#(<a class="" href="/media/RelatedMedia.cfm?media_id=#media_id#">Related</a>) '>
							</cfif>
							<cfif len(iiifFull) GT 0>
								<cfset output='#output#(<a class="" href="#iiifFull#">Full</a>)'>
							<cfelse>
								<cfset output='#output#(<a class="" href="#media_uri#">Full</a>)'>
							</cfif>
						</cfif>
						<cfset output='#output#</p>'>
						<cfset output='#output#<div class="py-1">'>
						<cfset showTitleText = trim(title)>
						<cfif len(showTitleText) EQ 0>
							<cfset showTitleText = trim(subject)>
						</cfif>
						<cfif len(showTitleText) EQ 0>
							<cfset showTitleText = "Externally Sourced Media Object">
						</cfif>
						<cfif #captionAs# EQ "textCaption"><!---This is for use when a caption of 197 characters is needed --->
							<cfif len(showTitleText) GT 197>
								<cfset showTitleText = "#left(showTitleText,197)#..." >
							</cfif>
						</cfif>
						<cfif #captionAs# EQ "textCaptionLong"><!---This is for use when a caption of 197 characters is needed --->
							<cfif len(showTitleText) GT 232>
								<cfset showTitleText = "#left(showTitleText,200)#..." >
							</cfif>
						</cfif>
						<cfif #captionAs# EQ "textCaptionFull"><!---This is for use when a full caption (or close to it) is needed. Related media (media viewer) --->
							<cfif len(showTitleText) GT 500>
								<cfset showTitleText = "#left(showTitleText,500)#..." >
							</cfif>
						</cfif>
						<cfif #captionAs# EQ "textShort"><!---This is for use with a small size or with "thumb" so that the caption will be short (e.g., specimen details page)--->
							<cfif len(showTitleText) GT 100>
								<cfset showTitleText = "#left(showTitleText,100)#..." >
							</cfif>
						</cfif>
						<cfif #captionAs# EQ "textFull"><!---This is for use with a size and the caption is 250 characters with links and copyright information--The images will fill the container (gray square present) and have a full caption (e.g., edit media page)--->
							<cfif len(showTitleText) GT 250>
								<cfset showTitleText = "#left(showTitleText,250)#..." >
							</cfif>
						</cfif>
						<!--- clean up broken html tags resulting from truncation of scientific names with <i></i> tags --->
						<cfif refind("<$",showTitleText) GT 0>
							<cfset showTitleText = left(showTitleText,len(showTitleText-1))>
						</cfif>
						<cfif refind("<i$",showTitleText) GT 0>
							<cfset showTitleText = left(showTitleText,len(showTitleText-2))>
						</cfif>
						<cfif refind("</$",showTitleText) GT 0>
							<cfset showTitleText = left(showTitleText,len(showTitleText-2))>
						</cfif>
						<cfif refind("</i$",showTitleText) GT 0>
							<cfset showTitleText = "#showTitleText#>">
						</cfif>
						<cfif refind("<i>[^<]+$",showTitleText) GT 0 >
							<!--- close an unclosed italic tag resulting from truncation --->
							<cfset showTitleText = "#showTitleText#</i>">
						</cfif>

						<cfset output='#output#<p class="text-center col-12 my-0 p-0 small" > #showTitleText# </p>'>
						<!---Was this meant to be something else? It currently duplicates the license display--->
					<!---<cfif len(#copyright_statement#) gt 0>
							<cfif #captionAs# EQ "TextFull">
								<cfset output='#output#<p class="text-center col-12 p-0 my-0 small">'>
								<cfset output='#output##copyright_statement#'>
								<cfset output='#output#</p>'>
							</cfif>
						</cfif>--->
						<cfif len(#license_uri#) gt 0>
							<cfif #captionAs# EQ "TextFull">
								<!---height is needed on the caption within the <p> or the media will not flow well--the above comment works but may not work on other, non specimen detail pages--->
								<cfset output='#output#<p class="text-center col-12 p-0 my-0 small">'>
								<cfset output='#output#<a href="#license_uri#">#license_display#</a>'>
								<cfset output='#output#</p>'>
							</cfif>
						</cfif>
						<cfset output='#output#</div>'>
						<cfset output='#output#</div>'>
					</cfif>
					<cfset output='#output#</div>'>
				<cfset i= i+1>
				</cfloop>

			</cfif>
		<cfcatch>
			<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
			<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
		#output#
	</cfoutput>
</cffunction>

<!--- Media Metadata Table using media_id --->		
<cffunction name="getMediaMetadata"  access="remote" returntype="string" returnformat="plain">
	<cfargument name="media_id" type="string" required="yes">
	<!---
	NOTE: When using threads, cfarguments are out of scope for the thread, place copies of them
	   into the variables scope.    See: https://gist.github.com/bennadel/9760037 for more examples of
   	scope issues related to cfthread 
	--->
	<cfset variables.media_id = arguments.media_id>
<cfset tn = REReplace(CreateUUID(), "[-]", "", "all") >	
	<cfthread name="mediaMetadataThread#tn#" threadName="mediaMetadataThread#tn#">
<cfoutput>
	<cftry>
		<cfquery name="media" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select distinct 
				media.media_id,media.media_uri,media.mime_type,media.media_type,media.preview_uri, 
				MCZBASE.get_media_dctermsrights(media.media_id) as uri, 
				MCZBASE.get_media_dcrights(media.media_id) as display, 
				MCZBASE.is_media_encumbered(media.media_id) hideMedia,
				MCZBASE.get_media_credit(media.media_id) as credit, 
				MCZBASE.get_media_descriptor(media.media_id) as alttag,
				MCZBASE.get_media_owner(media.media_id) as owner,
				MCZBASE.get_media_title(media.media_id) as title
			From
				media
			WHERE 
				media.media_id IN <cfqueryparam cfsqltype="CF_SQL_DECiMAL" value="#media_id#" list="yes">
				AND MCZBASE.is_media_encumbered(media_id)  < 1 
		</cfquery>
		<cfif media.recordcount EQ 0>
			<cfthrow message="No media records matching media_id [#encodeForHtml(media_id)#]">
		</cfif>
		<cfquery name="spec" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select distinct p.publication_id as pk, ct.media_relationship as rel, ct.label as label, ct.auto_table as at
		from publication p
		left join media_relations mr on mr.RELATED_PRIMARY_KEY = p.publication_id 
		left join mczbase.ctmedia_relationship ct on mr.media_relationship = ct.media_relationship
		where mr.media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
		and ct.auto_table = 'publication'
		UNION
		select distinct c.collection_object_id as pk, cmr.media_relationship as rel, 'Cited Specimen' as label, ct.auto_table as at
		from media_relations cmr 
		join citation c on cmr.related_primary_key = c.publication_id and cmr.media_relationship = 'shows cataloged_item'
		join publication p on c.publication_id = p.publication_id
		left join media_relations mr on mr.RELATED_PRIMARY_KEY = p.publication_id 
		left join mczbase.ctmedia_relationship ct on mr.media_relationship = ct.media_relationship
		where mr.media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
		and ct.auto_table = 'publication'
		UNION
		select distinct  ci.collection_object_id as pk, ct.media_relationship as rel, ct.label as label, ct.auto_table as at
		from cataloged_item ci
		left join media_relations mr on ci.collection_object_id = mr.related_primary_key
		left join mczbase.ctmedia_relationship ct on mr.media_relationship = ct.media_relationship
		where mr.media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
		and ct.auto_table = 'cataloged_item'
		UNION
		select distinct ce.collecting_event_id as pk, ct.media_relationship as rel, ct.label as label, ct.auto_table as at
		from media_relations mr
		left join collecting_event ce on mr.related_primary_key = ce.collecting_event_id
		left join mczbase.ctmedia_relationship ct on mr.media_relationship = ct.media_relationship
		where mr.media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
		and ct.auto_table = 'collecting_event'
		UNION
		select distinct loan.transaction_id as pk, ct.media_relationship as rel, ct.label as label, ct.auto_table as at
		from loan
		left join trans on trans.transaction_id = loan.transaction_id
		left join media_relations mr on loan.transaction_id = mr.related_primary_key
		left join mczbase.ctmedia_relationship ct on mr.media_relationship = ct.media_relationship
		where mr.media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
		and ct.auto_table = 'loan'
		UNION
		select distinct accn.transaction_id as pk, ct.media_relationship as rel, ct.label as label, ct.auto_table as at
		from accn
		left join trans on trans.transaction_id = accn.transaction_id
		left join media_relations mr on accn.transaction_id = mr.related_primary_key
		left join mczbase.ctmedia_relationship ct on mr.media_relationship = ct.media_relationship
		where mr.media_id= <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
		and ct.auto_table = 'accn'
		UNION
		select distinct deaccession.transaction_id as pk, ct.media_relationship as rel, ct.label as label, ct.auto_table as at
		from deaccession
		left join trans on trans.transaction_id = deaccession.transaction_id
		left join media_relations mr on deaccession.transaction_id = mr.related_primary_key
		left join mczbase.ctmedia_relationship ct on mr.media_relationship = ct.media_relationship
		where mr.media_id= <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
		and ct.auto_table = 'deaccession'
		UNION
		select distinct borrow.transaction_id as pk, ct.media_relationship as rel, ct.label as label, ct.auto_table as at
		from borrow
		left join trans on trans.transaction_id = borrow.transaction_id
		left join media_relations mr on borrow.transaction_id = mr.related_primary_key
		left join mczbase.ctmedia_relationship ct on mr.media_relationship = ct.media_relationship
		where mr.media_id= <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
		and ct.auto_table = 'borrow'
		UNION
		select distinct media.media_id as pk, ct.media_relationship as rel, ct.label as label, ct.auto_table as at
		from media
		left join media_relations mr on media.media_id = mr.related_primary_key
		left join mczbase.ctmedia_relationship ct on mr.media_relationship = ct.media_relationship
		where mr.media_id= <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
		and ct.auto_table = 'media'
		UNION
		select distinct permit.permit_id as pk, ct.media_relationship as rel, ct.label as label, ct.auto_table as at
		from permit
		left join media_relations mr on permit.permit_id = mr.related_primary_key
		left join mczbase.ctmedia_relationship ct on mr.media_relationship = ct.media_relationship
		where mr.media_id= <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
		and ct.auto_table = 'permit'
		UNION
		select distinct project.project_id as pk, ct.media_relationship as rel, ct.label as label, ct.auto_table as at
		from project
		left join media_relations mr on project.project_id = mr.related_primary_key
		left join mczbase.ctmedia_relationship ct on mr.media_relationship = ct.media_relationship
		where mr.media_id= <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
		and ct.auto_table = 'project'
		UNION
		select distinct specimen_part.collection_object_id as pk, ct.media_relationship as rel, ct.label as label, ct.auto_table as at
		from specimen_part
		left join media_relations mr on specimen_part.collection_object_id = mr.related_primary_key
		left join mczbase.ctmedia_relationship ct on mr.media_relationship = ct.media_relationship
		where mr.media_id= <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
		and ct.auto_table = 'specimen_part'
		UNION
		select distinct m.media_id as pk, ct.media_relationship as rel, ct.label as label, ct.auto_table as at
		from media m
		left join media_relations mr on m.media_id = mr.related_primary_key
		left join mczbase.ctmedia_relationship ct on mr.media_relationship = ct.media_relationship
		where mr.media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
		and ct.auto_table = 'media' 
		UNION
		select distinct locality.locality_id as pk, ct.media_relationship as rel, ct.label as label, ct.auto_table as at
		from locality
		left join media_relations mr on locality.locality_id = mr.related_primary_key
		left join mczbase.ctmedia_relationship ct on mr.media_relationship = ct.media_relationship
		where mr.media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
		and ct.auto_table = 'locality' 
		UNION
		select distinct agent.agent_id as pk, ct.media_relationship as rel, ct.label as label, an.agent_name as at
		from agent_name an
		left join agent on an.AGENT_name_ID = agent.preferred_agent_name_id
		left join media_relations mr on agent.agent_id = mr.related_primary_key
		left join mczbase.ctmedia_relationship ct on mr.media_relationship = ct.media_relationship
		where mr.media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
		and an.agent_name_type = 'preferred'
		and mr.media_relationship <> 'created by agent'
		and ct.auto_table = 'agent' 
	</cfquery>
		<!---<cfquery name="spec" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select distinct collection_object_id as pk, guid
			from media_relations
				left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat on related_primary_key = collection_object_id
				left join mczbase.ctmedia_relationship on mczbase.ctmedia_relationship.media_relationship = media_relations.media_relationship
			where media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media.media_id#">
				and mczbase.ctmedia_relationship.auto_table = 'cataloged_item'
			order by guid
		</cfquery>
		<cfquery name="underscore" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select cataloged_item.collection_object_id
			from underscore_collection
			left join underscore_relation on underscore_collection.underscore_collection_id = underscore_relation.underscore_collection_id
			left join cataloged_item on underscore_relation.COLLECTION_OBJECT_ID = cataloged_item.collection_object_id
			left join media_relations on underscore_relation.collection_object_id = media_relations.related_primary_key
			and media_relations.media_relationship = 'shows underscore_collection'
			and media_relations.media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media.media_id#">
		</cfquery>
		<cfquery name="agents1" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select distinct agent_name.agent_name, agent.agent_id
			from media_relations
				left join agent on media_relations.related_primary_key = agent.agent_id
				left join agent_name on agent_name.agent_id = agent.agent_id
				left join mczbase.ctmedia_relationship on mczbase.ctmedia_relationship.media_relationship = media_relations.media_relationship
			where media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media.media_id#">
			and media_relations.media_relationship = 'created by agent'
				and agent_name_type = 'preferred'
			order by agent_name.agent_name
		</cfquery>
		<cfquery name="agents2" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select distinct agent_name.agent_name, agent.agent_id
			from media_relations
				left join agent on media_relations.related_primary_key = agent.agent_id
				left join agent_name on agent_name.agent_id = agent.agent_id
				left join mczbase.ctmedia_relationship on mczbase.ctmedia_relationship.media_relationship = media_relations.media_relationship
			where media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media.media_id#">
				and mczbase.ctmedia_relationship.media_relationship = 'shows agent'
			and media_relations.media_relationship <> 'created by agent'
				and agent_name_type = 'preferred'
			order by agent_name.agent_name
		</cfquery>
		<cfquery name="agents3" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select distinct agent_name.agent_name, agent.agent_id
			from media_relations
				left join agent on media_relations.related_primary_key = agent.agent_id
				left join agent_name on agent_name.agent_id = agent.agent_id
				left join mczbase.ctmedia_relationship on mczbase.ctmedia_relationship.media_relationship = media_relations.media_relationship
			where media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media.media_id#">
				and mczbase.ctmedia_relationship.media_relationship= 'documents agent'
			and media_relations.media_relationship <> 'created by agent'
				and agent_name_type = 'preferred'
			order by agent_name.agent_name
		</cfquery>
		<cfquery name="agents4" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select distinct agent_name.agent_name, agent.agent_id
			from media_relations
				left join agent on media_relations.related_primary_key = agent.agent_id
				left join agent_name on agent_name.agent_id = agent.agent_id
				left join mczbase.ctmedia_relationship on mczbase.ctmedia_relationship.media_relationship = media_relations.media_relationship
			where media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media.media_id#">
				and mczbase.ctmedia_relationship.media_relationship= 'shows handwriting of agent'
			and media_relations.media_relationship <> 'created by agent'
				and agent_name_type = 'preferred'
			order by agent_name.agent_name
		</cfquery>
		<cfquery name="agents5" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select distinct agent_name.agent_name, agent.agent_id
			from media_relations
				left join agent on media_relations.related_primary_key = agent.agent_id
				left join agent_name on agent_name.agent_id = agent.agent_id
				left join mczbase.ctmedia_relationship on mczbase.ctmedia_relationship.media_relationship = media_relations.media_relationship
			where media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media.media_id#">
				and mczbase.ctmedia_relationship.media_relationship= 'physical object created by agent'
			and media_relations.media_relationship <> 'created by agent'
				and agent_name_type = 'preferred'
			order by agent_name.agent_name
		</cfquery>
		<cfquery name="collecting_eventRel" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select distinct collecting_event.verbatim_locality,collecting_event.COLLECTING_EVENT_ID, collecting_event.VERBATIM_DATE, collecting_event.ended_date, collecting_event.collecting_source
			from media_relations
				left join collecting_event on media_relations.related_primary_key = collecting_event.collecting_event_id
			where media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media.media_id#">
				and media_relations.media_relationship like '% collecting_event'
		</cfquery>
		<cfquery name="locali" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select distinct locality.spec_locality,locality.locality_ID, lat_long.dec_lat, lat_long.dec_long, lat_long.datum, lat_long.max_error_distance as error, lat_long.max_error_units as units
			from media_relations
				left join locality on media_relations.related_primary_key = locality.locality_id
				left join lat_long on lat_long.locality_id = locality.locality_id
			where media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media.media_id#">
				and media_relations.media_relationship like '% locality'
				and lat_long.accepted_lat_long_fg = 1
		</cfquery>
		<cfquery name="loan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select distinct transaction_id, loan.loan_number
			from media_relations
				left join loan on media_relations.related_primary_key = loan.transaction_id
				left join mczbase.ctmedia_relationship on mczbase.ctmedia_relationship.media_relationship = media_relations.media_relationship
			where media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media.media_id#">
				and mczbase.ctmedia_relationship.auto_table = 'loan'
		</cfquery>
		<cfquery name="accns" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select distinct transaction_id
			from media_relations
				left join accn on media_relations.related_primary_key = accn.transaction_id
				left join mczbase.ctmedia_relationship on mczbase.ctmedia_relationship.media_relationship = media_relations.media_relationship
				left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat on accn.transaction_id = flat.accn_id
			where media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media.media_id#">
				and mczbase.ctmedia_relationship.auto_table = 'accn'
		</cfquery>
		<cfquery name="daccns" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select distinct transaction_id
			from media_relations
				left join deaccession on media_relations.related_primary_key = deaccession.transaction_id
				left join mczbase.ctmedia_relationship on mczbase.ctmedia_relationship.media_relationship = media_relations.media_relationship
			where media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media.media_id#">
				and mczbase.ctmedia_relationship.auto_table = 'deaccession'
		</cfquery>
		<cfquery name="publication" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select distinct p.publication_id as pk, mr.media_id
			from publication p
				left join media_relations mr on mr.RELATED_PRIMARY_KEY = p.publication_id 
				left join media m on m.media_id = mr.media_id
				left join citation c on c.publication_id = p.publication_id
				left join formatted_publication fp on fp.publication_id = p.publication_id
				left join mczbase.ctmedia_relationship ct on mr.media_relationship = ct.media_relationship
			where m.media_id =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media.media_id#">
				and ct.media_relationship = 'shows publication'
		</cfquery>
		<cfquery name="media1" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select distinct m.media_id
			from media m
				left join media_relations mr on mr.media_id = m.media_id 
				left join mczbase.ctmedia_relationship ct on mr.media_relationship = ct.media_relationship
			where m.media_id =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media.media_id#">
				and ct.media_relationship = 'related to media'
		</cfquery>
		<cfquery name="media2" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select distinct mr.related_primary_key
			from media m
				left join media_relations mr on mr.media_id = m.media_id 
				left join mczbase.ctmedia_relationship ct on mr.media_relationship = ct.media_relationship
			where m.media_id =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media.media_id#">
				and ct.media_relationship = 'transcript for audio media'
		</cfquery>
		<cfquery name="namedGroup" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select underscore_collection.collection_name, underscore_relation.collection_object_id from underscore_collection
			left join underscore_relation on underscore_collection.underscore_collection_id = underscore_relation.underscore_collection_id
			left join cataloged_item on underscore_relation.COLLECTION_OBJECT_ID = cataloged_item.collection_object_id
			left join media_relations on underscore_relation.collection_object_id = media_relations.related_primary_key
			where media_relations.media_id =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media.media_id#">
		</cfquery>--->
		<cfloop query="media">
			<cfquery name="labels" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			SELECT
				media_label, label_value, agent_name, media_label_id
			FROM
				media_labels
				left join preferred_agent_name on media_labels.assigned_by_agent_id=preferred_agent_name.agent_id
			WHERE
				media_labels.media_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
				and media_label <> 'credit'  -- obtained in the findIDs query.
				and media_label <> 'owner'  -- obtained in the findIDs query.
				<cfif oneOfUs EQ 0>
					and media_label <> 'internal remarks'
				</cfif>
			</cfquery>
			<cfquery name="keywords" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT
					media_keywords.media_id, keywords
				FROM
					media_keywords
				WHERE
					media_keywords.media_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
			</cfquery>
			<cfquery name="media_rel" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select distinct mr.media_relationship,ct.Label as label, ct.auto_table
				from media_relations mr
				left join mczbase.ctmedia_relationship ct on mr.media_relationship = ct.media_relationship
				where mr.media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
			</cfquery>
				<h3 class="mx-2 h4 float-left">
					Metadata 
					<span class="mb-0">(Media ID: <a href="/media/#media_id#">media/#media_id#</a>)</span>
				</h3>
				<table class="table table-responsive-sm mb-3 border-none small90">
					<thead class="thead-dark">
						<tr>
							<th scope="col">Label</th>
							<th scope="col">Value</th>
						</tr>
					</thead>
					<tbody>
						<tr><th scope="row">Media Type:</th><td>#media.media_type#</td></tr>
						<tr><th scope="row">MIME Type:</th><td>#media.mime_type#</td></tr>
						<cfloop query="labels">
							<tr><th scope="row"><span class="text-capitalize">#labels.media_label#</span>:</th><td>#labels.label_value#</td></tr>
						</cfloop>
						<cfif len(credit) gt 0>
							<tr><th scope="row">Credit:</th><td>#credit#</td></tr>
						</cfif>
						<cfif len(owner) gt 0>
							<tr><th scope="row">Copyright:</th><td>#owner#</td></tr>
						</cfif>
						<cfif len(display) gt 0>
							<tr><th scope="row">License:</th><td> <a href="#uri#" target="_blank" class="external"> #display#</a></td></tr>
						</cfif>
						<cfif len(keywords.keywords) gt 0>
							<tr><th scope="row">Keywords: </span></th><td> #keywords.keywords#</td></tr>
						<cfelse>
						</cfif>
						<cfif listcontainsnocase(session.roles,"manage_media")>
							<tr class="border mt-2 p-2"><th scope="row">Alt Text: </th><td>#media.alttag#</td></tr>
						</cfif>
						<cfif len(media_rel.media_relationship) gt 0>
							<cfif media_rel.recordcount GT 1>
								<cfset plural = "s">
							<cfelse>
								<cfset plural = "">
							</cfif>
						<tr>
							<th scope="row">Relationship#plural#:&nbsp; </span></th>
							<td>
							<cfloop query="spec"><span class="text-capitalize">#spec.label#</span>
								<div class="comma2 d-inline">
									<cfquery name="relm" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#"> 
									select distinct an.agent_id as pk, '/agents/Agent.cfm?agent_id=' as href, an.agent_name as display, mr.media_relationship as rel
									from media_relations mr
									left join agent_name an on an.agent_id=mr.related_primary_key
									left join mczbase.ctmedia_relationship ct on ct.media_relationship = mr.media_relationship
									where mr.media_relationship like '%agent'
									and an.agent_name=<cfqueryparam cfsqltype="cf_sql_varchar" value="#spec.at#" />
									and mr.media_id = <cfqueryparam value=#media.media_id# CFSQLType="CF_SQL_decimal">
									UNION
									select distinct ac.transaction_id as pk, '/transactions/Accession.cfm?action=edit&transaction_id=' as href, ac.accn_number as display, mr.media_relationship as rel
									from media_relations mr
									left join accn ac on ac.transaction_id = mr.related_primary_key
									left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat on ac.transaction_id = flat.accn_id 
									where mr.media_relationship like '%accn' 
									and ac.transaction_id=<cfqueryparam cfsqltype="cf_sql_decimal" value="#spec.pk#" />
									and mr.media_id = <cfqueryparam value=#media.media_id# CFSQLType="CF_SQL_decimal">
									UNION
									select distinct dac.transaction_id as pk, '/transactions/Deaccession.cfm?action=edit&transaction_id=' as href,  dac.deacc_number as display, mr.media_relationship as rel 
									from media_relations mr
									left join deaccession dac on dac.transaction_id = mr.related_primary_key 
									where mr.media_relationship like '%deaccession' 
									and dac.transaction_id=<cfqueryparam cfsqltype="cf_sql_decimal" value="#spec.pk#" /> 
									and mr.media_id = <cfqueryparam value=#media.media_id# CFSQLType="CF_SQL_decimal">
									UNION
									select distinct l.transaction_id as pk, '/transactions/Loan.cfm?action=editLoan&transaction_id=' as href, l.loan_number as display, mr.media_relationship as rel 
									from media_relations mr 
									left join loan l on l.transaction_id = mr.related_primary_key 
									where mr.media_relationship like '%loan' 
									and l.transaction_id=<cfqueryparam cfsqltype="cf_sql_decimal" value="#spec.pk#" /> 
									and mr.media_id = <cfqueryparam value=#media.media_id# CFSQLType="CF_SQL_decimal">
									UNION
									select distinct mr.related_primary_key as pk, '/media/' as href, m.media_type as display, mr.media_relationship as rel
									from media m
									left join media_relations mr on mr.media_id = m.media_id 
									where mr.media_relationship like '%media' 
									and m.media_id = <cfqueryparam cfsqltype="cf_sql_decimal" value="#spec.pk#" />
									and mr.media_id = <cfqueryparam value=#media.media_id# CFSQLType="CF_SQL_decimal">
									UNION
									select distinct p.publication_id as pk,'/publications/showPublication.cfm?publication_id=' as href,  fp.formatted_publication as display, mr.media_relationship as rel
									from media_relations mr
									left join publication p on mr.related_primary_key = p.publication_id
									left join formatted_publication fp on fp.publication_id = p.publication_id
									where p.publication_id = <cfqueryparam cfsqltype="cf_sql_decimal" value="#spec.pk#" />
									and fp.format_style = 'short' 
									and mr.media_relationship like '%publication'
									and mr.media_id = <cfqueryparam value=#media.media_id# CFSQLType="CF_SQL_decimal">
									UNION
									select distinct  uc.underscore_collection_id as pk, '/grouping/showNamedCollection.cfm?underscore_collection_id=' as href, uc.collection_name as display, mr.media_relationship as rel
									from media_relations mr 
									left join underscore_relation ur on ur.underscore_collection_id = mr.related_primary_key
									left join underscore_collection uc on uc.underscore_collection_id = ur.underscore_collection_id
									where mr.media_relationship like '%underscore_collection'
									and ur.collection_object_id=<cfqueryparam cfsqltype="cf_sql_varchar" value="#spec.pk#" />
									UNION
									select distinct ce.collecting_event_id as pk, '/showLocality.cfm?action=srch&collecting_event_id=' as href,  ce.verbatim_locality as display, mr.media_relationship as rel
									from media_relations mr
									left join collecting_event ce on ce.collecting_event_id = mr.related_primary_key
									where mr.media_relationship like '%collecting_event'
									and ce.collecting_event_id=<cfqueryparam cfsqltype="cf_sql_varchar" value="#spec.pk#" />
									UNION
									select distinct flat.collection_object_id as pk, '/guid/' as href,  flat.guid as display, mr.media_relationship as rel
									from media_relations mr
									left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat on mr.related_primary_key = flat.collection_object_id 
									where mr.media_relationship like '%cataloged_item'
									and flat.collection_object_id=<cfqueryparam cfsqltype="cf_sql_varchar" value="#spec.pk#" />
									</cfquery>
									: <a class="font-weight-lessbold" href="#relm.href##relm.display#">#relm.display#</a><span>, </span>
								</div>
<!---								<cfloop query="loan"><a class="font-weight-lessbold" href="/transactions/Loan.cfm?action=editLoan&transaction_id=#loan.transaction_id#"> #loan.loan_number#</a><span>, </span></cfloop>
								<cfloop query="collecting_eventRel">
									<a class="font-weight-lessbold" href="/showLocality.cfm?action=srch&collecting_event_id=#collecting_eventRel.collecting_event_id#">#collecting_eventRel.verbatim_locality#  #collecting_eventRel.collecting_source# #collecting_eventRel.verbatim_date# <cfif collecting_eventRel.ended_date gt 0>(#collecting_eventRel.ended_date#)</cfif>  </a><span>, </span></cfloop>
									</cfif>
									<cfif media_rel.media_relationship eq 'related to media'>: <cfloop query="media1"><cfquery name="relm8" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">select mr.related_primary_key, m.media_id from media m, media_relations mr where mr.media_id = m.media_id and mr.media_relationship = 'related to media' and m.media_id = #media1.media_id#</cfquery><a class="font-weight-lessbold" href="/media/#relm8.related_primary_key#"> #relm8.related_primary_key#</a><span>, </span></cfloop>
									</cfif>
									<cfif media_rel.media_relationship eq 'transcript for audio media'>: <cfloop query="media2"><cfquery name="relm9" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">select m.media_id from media m, media_relations mr where mr.media_id = m.media_id and m.media_id = #media2.related_primary_key#</cfquery><a class="font-weight-lessbold" href="/media/#relm9.media_id#"> #relm9.media_id#</a><span>, </span></cfloop>
									</cfif>
									<cfif media_rel.media_relationship eq 'shows locality'>: <cfloop query="locali"><a class="font-weight-lessbold" href="/showLocality.cfm?action=srch&locality_id=#locali.locality_id#">#locali.spec_locality# #NumberFormat(locali.dec_lat,'00.00')#, #NumberFormat(locali.dec_long,'00.00')# (datum: <cfif len(locali.datum)gt 0>#locali.datum#<cfelse>none listed</cfif>) error: #locali.error##locali.units#</a><span>, </span></cfloop>
									</cfif>
									<cfif media_rel.media_relationship eq 'shows publication'>: 
									<cfloop query="publication"><cfquery name="relm7" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#"></cfquery><a class="font-weight-lessbold" href="/publications/showPublication.cfm?publication_id=#publication.pk#">#relm7.pub_short#, #relm7.publication_title# </a><span> &##8226;&##8226; </span> </cfloop>
									</cfif>
									<cfif media_rel.media_relationship eq 'shows underscore_collection'>:<cfloop query="underscore"><cfquery name="relm12" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#"> </cfquery><a class="font-weight-lessbold" href="/agents/Agent.cfm?agent_id=#relm12.agent_id#"> #underscore.collection_name#</a><span>, </span></cfloop>
									</cfif>--->
	<!---								<cfif media_rel.media_relationship eq 'ledger entry for cataloged_item'> 
										<cfloop query="spec">
											<a class="font-weight-lessbold" href="/guid/#spec.guid#">#spec.guid#</a><span>, </span>
										</cfloop>
									</cfif>--->
								</div>
								<cfif media_rel.recordcount GT 1><span class="px-1"> | </span></cfif>
							</cfloop> 
							</td>
						</tr>
					<cfelse>
					</cfif>
				</tbody>
			</table>
		</cfloop>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
</cfoutput>
	</cfthread>
	<cfthread action="join" name="mediaMetadataThread#tn#" />
	<cfreturn cfthread["mediaMetadataThread#tn#"].output>
</cffunction>

			
	
			
			
			
			
			
			
<!---BELOW:::FUNCTIONS FOR RELATIONSHIPS and LABELS on EDIT MEDIA AND FUNCTION FOR SHOWING THUMBNAILS FOR showMedia.cfc -- Michelle--->	
<cffunction name="getMediaRelationsHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="media_id" type="string" required="yes">
	<!---
	NOTE: When using threads, cfarguments are out of scope for the thread, place copies of them
	   into the variables scope.    See: https://gist.github.com/bennadel/9760037 for more examples of
   	scope issues related to cfthread 
	--->
	<cfset variables.media_id = arguments.media_id>
	<!--- 
	NOTE: If this cffunction is invoked more than once in a request (e.g. when called directly as a function
		within a loop in coldfusion in a coldfusion page) then the thread name must be unique for each invocation,
		so generate a highly likely to be unique thread name as follows:	
	<cfset tn = REReplace(CreateUUID(), "[-]", "", "all") >	
	<cfthread name="getCounterThread#tn#" threadName="mediaWidgetThread#tn#">
	Likewise, include #tn# in the names of the thread in all the other cfthread tags within this cffunction 
	If the cffunction is called only once in a request (e.g. only from a javascript ajax handler, then the thread name
		does not need to be unique.
	--->
<cfthread name="getMediaRelationsHtmlThread">
	<cftry>
		<cfoutput>
			<cfquery name="getRelationships1" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT 
					media_relationship, media_id, media_relations_id, related_primary_key
				FROM
					media_relations
				WHERE media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
				
			</cfquery>
			<cfquery name="ctmedia_relationship" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
				select media_relationship from ctmedia_relationship order by media_relationship
			</cfquery>
			<cfquery name="ctmedia_label" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
				select media_label from ctmedia_label order by media_label
			</cfquery>
			<cfquery name="ctmedia_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
				select media_type from ctmedia_type order by media_type
			</cfquery>
			<cfquery name="ctmime_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
				select mime_type from ctmime_type order by mime_type
			</cfquery>
			<cfquery name="ctmedia_license" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select media_license_id,display media_license from ctmedia_license order by media_license_id
			</cfquery>
				
				<cfif getRelationships1.recordcount GT 0>
			<div class="col-12 px-0 float-left">

				<cfif getRelationships1.recordcount is 0>
				<script>
					console.log("relns cfif");
				</script> 
					<div id="seedMedia" style="display:none">
						<input type="hidden" id="media_relations_id__0" name="media_relations_id__0">
						<cfset d="">
						<select name="relationship__0" id="relationship__0" class="data-entry-select  col-5" size="1"  onchange="pickedRelationship(this.id)">
							<cfloop query="ctmedia_relationship">
								<option <cfif #d# is #media_relationship#> selected="selected" </cfif>value="#media_relationship#">#media_relationship#</option>
							</cfloop>
						</select>
						<input type="text" name="related_value__0" id="related_value__0" class="data-entry-input col-6">
						<input type="hidden" name="related_id__0" id="related_id__0">
						<script>
							console.log("seed media");
						</script> 
					</div>
				</cfif>
				<cfset i=1>
				<cfloop query="getRelationships1">
					<cfset d=media_relationship>
						<div class="form-row col-12 mb-2 mb-md-0 px-0 mx-0">	
							<input type="hidden" id="media_relations_id__#i#" name="media_relations_id__#i#" value="#media_relations_id#">
							<label for="relationship__#i#"  class="sr-only">Relationship</label>
							<select name="relationship__#i#" id="relationship__#i#" size="1"  onchange="pickedRelationship(this.id)" class="data-entry-select col-12 col-md-3 float-left">
								<cfloop query="ctmedia_relationship">
									<option <cfif #d# is #media_relationship#> selected="selected" </cfif>value="#media_relationship#">#media_relationship#</option>
								</cfloop>
							</select>
							<input type="text" name="related_value__#i#" id="related_value__#i#" value="#encodeForHTML(related_primary_key)#" class="data-entry-input col-12 col-md-5 col-xl-6  float-left px-1 float-left">
							<input type="hidden" name="related_id" id="related_id" value="#related_primary_key#">
							<button id="relationsDiv__#i#" class="btn btn-warning btn-xs float-left small" onClick="deleteRelationship(#media_relations_id#,#getRelationships1.media_id#,relationshipDiv__#i#)"> Remove </button>
							<!---onclick="enable_disable()"--->
							<input class="btn btn-secondary btn-xs mx-0 small float-left slide-toggle__#i#" type="button" value="Edit" style="width:60px;"></input>
		
						<script>
							console.log("relns");
						</script> 
						</div>
					<cfset i=i+1>
				</cfloop>
			</div>
					<script>
						(function () {
							var previous;
							$("select").on('focus', function () {
								previous = this.value;
							}).change(function() {
								previous = this.value;
							});
						})();
					</script>
				<cfelse>
					<h3 class="h3">No Entries</h3>
					<ul><li>#encodeForHtml(variables.media_id)#</li></ul>
				</cfif>
			</cfoutput>
		<cfcatch>
			<!--- For functions that return html blocks to be embedded in a page, the error can be included in the output --->
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfoutput>
				<h2 class="h3">Error in #function_called#:</h2>
				<div>#error_message#</div>
			</cfoutput>
		</cfcatch>
		</cftry>
	</cfthread>
	<cfthread action="join" name="getMediaRelationsHtmlThread" />
	<cfreturn getMediaRelationsHtmlThread.output>
</cffunction>
	
<cffunction name="updateMediaRelationship" access="remote" returntype="any" returnformat="json">
	<cfargument name="media_id" type="string" required="yes">
	<cfargument name="media_relationship" type="string" required="yes">
	<cfargument name="related_primary_key" type="string" required="yes">
	<cfset data = ArrayNew(1)>
	<cftransaction>
		<cftry>
			<cfquery name="makeMedia" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				update media_relations set
				media_relationship=<cfqueryparam cfsqltype="cf_sql_varchar" value="#media_relationship#" /> ,
				related_primary_key=<cfqueryparam cfsqltype="cf_sql_number" value="#related_primary_key#" /> ,
				where media_id=<cfqueryparam cfsqltype="cf_sql_number" value="#media_id#" />
			</cfquery>
			<cfloop from="1" to="#number_of_relations#" index="n">
				<cfset failure=0>
				<cftry>
				<cfset thisRelationship = #evaluate("relationship__" & n)#>
				<cfcatch>
					<cfset failure=1>
				</cfcatch>
				</cftry>
				<cftry>
					<cfset thisRelatedId = #evaluate("related_id__" & n)#>
					<cfcatch>
						<cfset failure=1>
					</cfcatch>
				</cftry>
				<cfif isdefined("media_relations_id__#n#")>
					<cfset thisRelationID=#evaluate("media_relations_id__" & n)#>
				<cfelse>
					<cfset thisRelationID=-1>
				</cfif>
				<cfif thisRelationID is -1>
					<cfquery name="makeRelation" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						insert into media_relations (
							media_id,media_relationship,related_primary_key
						) values (
							#media_id#,'#thisRelationship#',#thisRelatedId#)
					</cfquery>
				<cfelse>
						fail to make relationship
				</cfif><!--- relation exists ---> 
			</cfloop>
			<cftransaction action="commit"> 
			<cfset row = StructNew()>
			<cfset row["status"] = "saved">
			<cfset row["media_relations_id"] = "#encodeForHTML(media_relations_id)#">
			<cfset data[1] = row>
		<cfcatch>
			<cftransaction action="rollback"> 
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfif error_message CONTAINS "ORA-00001: unique constraint">
				<cfset error_message = "Update Relationship">
			</cfif>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn #serializeJSON(data)#>
</cffunction>	
			
<cffunction name="getLabelsHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="media_id" type="string" required="yes">
	<!---
	NOTE: When using threads, cfarguments are out of scope for the thread, place copies of them
	   into the variables scope.    See: https://gist.github.com/bennadel/9760037 for more examples of
   	scope issues related to cfthread 
	--->
	<cfset variables.media_id = arguments.media_id>
	<!--- 
	NOTE: If this cffunction is invoked more than once in a request (e.g. when called directly as a function
		within a loop in coldfusion in a coldfusion page) then the thread name must be unique for each invocation,
		so generate a highly likely to be unique thread name as follows:	
	<cfset tn = REReplace(CreateUUID(), "[-]", "", "all") >	
	<cfthread name="getCounterThread#tn#" threadName="mediaWidgetThread#tn#">
	Likewise, include #tn# in the names of the thread in all the other cfthread tags within this cffunction 
	If the cffunction is called only once in a request (e.g. only from a javascript ajax handler, then the thread name
		does not need to be unique.
	--->
	<cfthread name="getLabelsThread">
		<cftry>
			<cfoutput>
				<cfquery name="getLabels"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select
						media_label,
						label_value,
						agent_name,
						media_label_id
					from
						media_labels,
						preferred_agent_name
					where
						media_labels.assigned_by_agent_id=preferred_agent_name.agent_id (+) and
						media_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
				</cfquery>
				<cfif getLabels.recordcount GT 0>
					<div id="labels">
						<cfset i=1>
						<cfif labels.recordcount is 0>
							<!--- seed --->
							<div id="seedLabel" style="display:none;">
								<input type="hidden" id="media_label_id__0" name="media_label_id__0">
								<cfset d="">
								<label for="label__#i#" class='sr-only'>Media Label</label>
								<select name="label__0" id="label__0" size="1" class="data-entry-select float-left col-5">
									<cfloop query="ctmedia_label">
										<option <cfif #d# is #media_label#> selected="selected" </cfif>value="#media_label#">#media_label#</option>
									</cfloop>
								</select>
								<input type="text" name="label_value__0" id="label_value__0" class="col-7 float-left data-entry-input">
							</div>
							<!--- end labels seed --->
						</cfif>
						<cfloop query="labels">
							<cfset d=media_label>
							<div class="row" id="labelDiv__#i#" >		
								<input type="hidden" id="media_label_id__#i#" name="media_label_id__#i#" value="#media_label_id#">
								<label class="pt-0 pb-1 sr-only" for="label__#i#">Media Label</label>
								<form name="labelForm" class="col-12 px-0" method="post" action="/Media.cfm">
									<div class="newRec col-12 px-0">
										<div class="col-12 col-md-3 px-0 float-left">
											<input type="hidden" name="action" value="addLabel" />
											<input type="hidden" name="username" value="#getLabels.media_label_id#" />
											<select name="label__#i#" id="label__#i#" size="1" class="inputDisabled data-entry-select float-left">
												<cfloop query="ctmedia_label">
													<option <cfif #d# is #media_label#> selected="selected" </cfif>value="#media_label#">#media_label#</option>
												</cfloop>
											</select>
										</div>
										<div class="col-12 col-md-5 col-xl-6 px-0 float-left">
											<input type="text" name="label_value__#i#" id="label_value__#i#" value="#encodeForHTML(label_value)#"  class="data-entry-input inputDisabled float-left px-1">
										</div>
										<div class="col-12 col-md-4 col-xl-3 px-0 mb-2 mb-md-0 float-left">
											<button class="btn btn-danger btn-xs float-left small" id="deleteLabel" onClick="deleteLabel(media_id)"> Delete </button>
											<input class="btn btn-secondary btn-xs mx-0 small float-left edit-toggle__#i#" type="button" value="Edit"></input>
											<input type="submit" value="Save" class="savBtn btn-xs btn-primary">
										</div>
									</div>
								</form>
							</div>
							<cfset i=i+1>
						</cfloop>
						<div class="row">
							<div class="col-12 px-0 mt-2">
								<input class="btn btn-xs btn-primary float-left" type="button" value="Save New Label">
							</div>
						</div>
					
						
					<!---	<span class="infoLink h5 box-shadow-0 col-12 col-md-6 float-right d-block text-right my-1" id="addLabel" onclick="addLabelTo(#i#,'labels','addLabel');">Add Label (+)</span> --->
					</div><!---end id labels--->
				
					<script>
						(function () {
							var previous;
							$("select").on('focus', function () {
								previous = this.value;
							}).change(function() {
								alert(previous);
								previous = this.value;
							});
						})();
					</script>
				<cfelse>
					<h3 class="h3">No Entries</h3>
					<ul><li>#encodeForHtml(variables.media_id)#</li></ul>
				</cfif>
			</cfoutput>
		<cfcatch>
			<!--- For functions that return html blocks to be embedded in a page, the error can be included in the output --->
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfoutput>
				<h2 class="h3">Error in #function_called#:</h2>
				<div>#error_message#</div>
			</cfoutput>
		</cfcatch>
		</cftry>
	</cfthread>
	<cfthread action="join" name="getLabelsThread" />
	<cfreturn getLabelsThread.output>
</cffunction>

<!--- 
getCounterHtml returns a block of html displaying information from the cf_helloworld table.

@param parameter some arbitrary value, displayed in the returned html.
@param other_parameter some arbitrary value, displayed in the returned html.
@param id_for_counter the id to use for the html element that displays the current value 
  of the counter, must be unique on the page.
@param id_for_dialog the id to use for the html element into which the edit text dialog 
  can be loaded, must be unique on the page.

@return block of html text with data from cf_helloworld.
--->
<cffunction name="getCounterHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="parameter" type="string" required="yes">
	<cfargument name="other_parameter" type="string" required="yes">
	<cfargument name="id_for_counter" type="string" required="yes">
	<cfargument name="id_for_dialog" type="string" required="yes">

	<!---
	NOTE: When using threads, cfarguments are out of scope for the thread, place copies of them
	   into the variables scope.    See: https://gist.github.com/bennadel/9760037 for more examples of
   	scope issues related to cfthread 
	--->
	<cfset variables.parameter = arguments.parameter>
	<cfset variables.other_parameter = arguments.other_parameter>
	<cfset variables.id_for_counter = arguments.id_for_counter>
	<cfset variables.id_for_dialog = arguments.id_for_dialog>

	<!--- 

	NOTE: If this cffunction is invoked more than once in a request (e.g. when called directly as a function
		within a loop in coldfusion in a coldfusion page) then the thread name must be unique for each invocation,
		so generate a highly likely to be unique thread name as follows:	

	<cfset tn = REReplace(CreateUUID(), "[-]", "", "all") >	
	<cfthread name="getCounterThread#tn#" threadName="mediaWidgetThread#tn#">

	Likewise, include #tn# in the names of the thread in all the other cfthread tags within this cffunction 

	If the cffunction is called only once in a request (e.g. only from a javascript ajax handler, then the thread name
		does not need to be unique.

	--->
	<cfthread name="getCounterThread">
		<cftry>
			<cfoutput>
				<cfquery name="getCounter" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT 
						text, counter, helloworld_id
					FROM
						MCZBASE.cf_helloworld
					WHERE rownum < 2
				</cfquery>
				<cfif getCounter.recordcount GT 0>
					<h3 class="h3">#getCounter.text#</h3>
					<!--- id_for_counter allows the calling code to specify, and thus know a value to pass to other functions, the id for the counter element in the dom --->
					<!--- see the use of this in the invocation of the javascript updateCounterElement() function --->
					<ul><li id="#encodeForHtml(variables.id_for_counter)#">#getCounter.counter#</li></ul>
					<ul><li><button onClick=" incrementCounterUpdate('#variables.id_for_counter#','#getCounter.helloworld_id#')" class="btn btn-xs btn-secondary" >Increment</button></li></ul>
					<ul><li>#encodeForHtml(variables.parameter)#</li></ul>
					<ul><li>#encodeForHtml(variables.other_parameter)#</li></ul>
					<!--- id_for_dialog allows the calling code to specify the div for the dialog, 
							and thus the potential reuse of this function in different contexts and the 
							elimination of a hardcoded value for the id of this div in more than one place.
					 --->
					 <ul><li><button onClick=" openUpdateTextDialog('#getCounter.helloworld_id#','#variables.id_for_dialog#');" class="btn btn-xs btn-primary">Edit</button></li></ul>
				<cfelse>
					<h3 class="h3">No Entries</h3>
					<ul><li>#encodeForHtml(variables.parameter)#</li></ul>
					<ul><li>#encodeForHtml(variables.other_parameter)#</li></ul>
				</cfif>
			</cfoutput>
		<cfcatch>
			<!--- For functions that return html blocks to be embedded in a page, the error can be included in the output --->
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfoutput>
				<h2 class="h3">Error in #function_called#:</h2>
				<div>#error_message#</div>
			</cfoutput>
		</cfcatch>
		</cftry>
	</cfthread>
	<cfthread action="join" name="getCounterThread" />
	<cfreturn getCounterThread.output>
</cffunction>

<!--- incrementCounter, increment the hello world counter (for all rows in cf_helloworld).
  @return json containing status(=saved), counter, and text.
  @throws returns error using reportError() and rollsback transaction
--->
<cffunction name="incrementAllCounters" access="remote" returntype="any" returnformat="json">
	<cfset data = ArrayNew(1)>
	<cftransaction>
		<cftry>
			<cfquery name="setCounter" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE 
					MCZBASE.cf_helloworld
				SET
					counter = counter + 1 
			</cfquery>
			<cfquery name="getCounter" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT 
					text, counter 
				FROM
					MCZBASE.cf_helloworld
				WHERE rownum < 2
			</cfquery>
			<cfset row = StructNew()>
			<cfset row["status"] = "saved">
			<cfset row["counter"] = "#getCounter.counter#">
			<cfset row["text"] = "#getCounter.text#">
			<cfset data[1] = row>
			<cftransaction action="commit">
		<cfcatch>
			<!--- For functions that return structured data, use reportError to produce an error dialog --->
			<!--- the calling jquery.ajax function should include: 
				error: function (jqXHR, textStatus, error) {
					handleFail(jqXHR,textStatus,error,"incrementing hello world counter (1)");
				}
			--->
			<cftransaction action="rollback">
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn #serializeJSON(data)#>
</cffunction>


<!--- incrementCounter, update the hello world counter for a specified cf_helloworld record.
  @param helloworld_id the primary key value of the row to update.
  @return json containing status(=saved), counter, and text.
  @throws returns error using reportError() and rollsback transaction
--->
<cffunction name="incrementCounter" access="remote" returntype="any" returnformat="json">
	<cfargument name="helloworld_id" type="string" required="yes">
	<cfset data = ArrayNew(1)>
	<cftransaction>
		<cftry>
			<cfquery name="setCounter" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE 
					MCZBASE.cf_helloworld
				SET
					counter = counter + 1 
				WHERE
					helloworld_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#helloworld_id#">
			</cfquery>
			<cfquery name="getCounter" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT 
					text, counter 
				FROM
					MCZBASE.cf_helloworld
				WHERE
					helloworld_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#helloworld_id#">
			</cfquery>
			<cfset row = StructNew()>
			<cfset row["status"] = "saved">
			<cfset row["counter"] = "#getCounter.counter#">
			<cfset row["text"] = "#getCounter.text#">
			<cfset data[1] = row>
			<cftransaction action="commit">
		<cfcatch>
			<cftransaction action="rollback">
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn #serializeJSON(data)#>
</cffunction>

<!--- updateText, update the hello world text field for a specified cf_helloworld record,
  without updating the cunter.
  @param helloworld_id the primary key value of the row to update.
  @param text the new value for cf_helloworld.text
  @return json containing status(=saved), counter, and text.
  @throws returns error using reportError() and rollsback transaction
--->
<cffunction name="updateText" access="remote" returntype="any" returnformat="json">
	<cfargument name="helloworld_id" type="string" required="yes">
	<cfargument name="text" type="string" required="yes">
	<cfset data = ArrayNew(1)>
	<cftransaction>
		<cftry>
			<cfquery name="setText" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE 
					MCZBASE.cf_helloworld
				SET
					text = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#text#">
				WHERE
					helloworld_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#helloworld_id#">
			</cfquery>
			<cfquery name="getCounter" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT 
					text, counter 
				FROM
					MCZBASE.cf_helloworld
				WHERE
					helloworld_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#helloworld_id#">
			</cfquery>
			<cfset row = StructNew()>
			<cfset row["status"] = "saved">
			<cfset row["counter"] = "#getCounter.counter#">
			<cfset row["text"] = "#getCounter.text#">
			<cfset data[1] = row>
			<cftransaction action="commit">
		<cfcatch>
			<cftransaction action="rollback">
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn #serializeJSON(data)#>
</cffunction>

<!--- 
 ** method gettextDialogHtml obtains the html content for a dialog to update the value of cf_helloworld.text
 * 
 * @param helloworld_id the id of the row for which to update the text
 * @return html to populate a dialog
--->
<cffunction name="getTextDialogHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="helloworld_id" type="string" required="yes">

	<cfthread name="textDialogThread">
		<cftry>
			<cfquery name="lookupRow" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="lookupRow_result">
				select helloworld_id, text, counter
				from MCZBASE.cf_helloworld
				where
					helloworld_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#helloworld_id#">
			</cfquery>
			<cfif lookupRow.recordcount NEQ 1>
				<cfthrow message="Error looking up cf_helloworld row with helloworld_id=#encodeForHtml(helloworld_id)# Query:[#lookupRow_result.SQL#]">
			</cfif>
			<cfoutput query="lookupRow">
				<div class="container-fluid">
					<div class="row">
						<div class="col-12">
							<form id="text_form">
								<input type="hidden" name="helloworld_id" id="helloworld_id" value="#helloworld_id#">
								<label for="text_control" class="data-entry-label">Hello World Text</label>
								<input type="text" name="text" id="text_control" class="data-entry-input mb-2" value="#lookupRow.text#" >
								<script>
									function saveText() {
										var id = $('##helloworld_id').val();
										var text = $('##text_control').val();
										jQuery.getJSON("/media/component/search.cfc", { 
											method : "updateText",
											helloworld_id : id,
											text: text
										},
										function (result) {
											console.log(result);
											console.log(result[0].status);
											$("##helloworldtextdialogfeedback").html(result[0].status);
											var responseStatus = result[0].status;
											if (responseStatus == "saved") { 
												$('##helloworldtextdialogfeedback').removeClass('text-danger');
												$('##helloworldtextdialogfeedback').addClass('text-success');
												$('##helloworldtextdialogfeedback').removeClass('text-warning');
											};
											console.log(result[0].counter);
											console.log(result[0].text);
										}
										).fail(function(jqXHR,textStatus,error){ handleFail(jqXHR,textStatus,error,"incrementing hello world counter (1)"); });
									};
									function changed(){
										$('##helloworldtextdialogfeedback').html('Unsaved changes.');
										$('##helloworldtextdialogfeedback').addClass('text-danger');
										$('##helloworldtextdialogfeedback').removeClass('text-success');
										$('##helloworldtextdialogfeedback').removeClass('text-warning');
									};
									$(document).ready(function() {
										console.log("document.ready in returned dialog html");
										$('##text_form [type=text]').on("change",changed);
									});
								</script>
								<button type="button" class="btn btn-xs btn-primary" onClick="saveText();">Save</button>
								<output id="helloworldtextdialogfeedback"><output>
							</form>
						</div>
					</div>
				</div>
			</cfoutput>
		<cfcatch>
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfoutput>
				<h2 class="h3">Error in #function_called#:</h2>
				<div>#error_message#</div>
			</cfoutput>
		</cfcatch>
		</cftry>
	</cfthread>
	<cfthread action="join" name="textDialogThread" />
	<cfreturn textDialogThread.output>
</cffunction>
				
				
<!---
Function getLicenseAutocompleteMeta.  Search for media licenses by name with a substring match on display, returning json suitable for jquery-ui autocomplete
 with a _renderItem overriden to display more detail on the picklist, and just the license display as the selected value.

@param term media_license.display value to search for.
@return a json structure containing id and value, with matching license with matched display in value and media_license_id in id, and 
   description for matched display in meta.
--->
<cffunction name="getLicenseAutocompleteMeta" access="remote" returntype="any" returnformat="json">
	<cfargument name="term" type="string" required="yes">
	<!--- perform wildcard search anywhere in publication_name.publication_name --->
	<cfset name = "%#term#%"> 

	<cfset data = ArrayNew(1)>
	<cftry>
      <cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			SELECT 
				media_license_id, display, description 
			FROM 
				ctmedia_license
			WHERE
				upper(display) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(name)#">
		</cfquery>
	<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfset row["id"] = "#search.media_license_id#">
			<cfset row["value"] = "#search.display#" >
			<cfset row["meta"] = "#search.display# (#search.description#)" >
			<cfset data[i]  = row>
			<cfset i = i + 1>
		</cfloop>
		<cfreturn #serializeJSON(data)#>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn #serializeJSON(data)#>
</cffunction>


<!--- function getRichMediaAutocomplete backing for a media lookup autocomplete returns metadata 
  and a media_id 
  @param term search term value for finding media records, checks filename.
  @param type limitation on media.media_type for returned values (type=image for just image files).
  @return json structure containing id, value, and meta suitable for use with an autocomplete.
--->
<cffunction name="getRichMediaAutocomplete" access="remote" returntype="any" returnformat="json">
	<cfargument name="term" type="string" required="yes">
	<cfargument name="type" type="string" required="no">
	<cfset data = ArrayNew(1)>

	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			select distinct 
				media.media_id,
				auto_filename,
				media_type,
				mime_type
			from 
				media
			where 
				MCZBASE.is_media_encumbered(media.media_id)  < 1 
				and upper(auto_filename) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(term)#%">
				and media_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#type#">
			order by auto_filename
		</cfquery>
		<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfset row["id"] = "#search.media_id#">
			<cfset row["value"] = "#search.auto_filename#" >
			<cfset row["meta"] = "#search.media_id# #search.auto_filename# (#search.media_type#:#search.mime_type#)" >
			<cfset data[i]  = row>
			<cfset i = i + 1>
		</cfloop>
		<cfreturn #serializeJSON(data)#>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn #serializeJSON(data)#>
</cffunction>

<!--- function getMediaFilePath backing for a media file lookup to support delegate for 
  cantaloupe, given a media_id, return the path below specimen_images and the filename.
  @param media_id the media record to look up
  @return json structure containing 
--->
<cffunction name="getMediaFilePath" access="remote" returntype="any" returnformat="json">
	<cfargument name="media_id" type="string" required="yes">
	<cfset data = ArrayNew(1)>

	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="cf_dbuser" result="search_result">
			select distinct 
				media_id,
				auto_path,
				auto_filename
			from 
				media
			where 
				media_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#media_id#">
				and auto_host = 'mczbase.mcz.harvard.edu'
				and media_type = 'image'
				and is_media_encumbered(media_id) = 0
			order by auto_filename
		</cfquery>
		<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfset row["id"] = "#search.media_id#">
			<cfset row["filename"] = "#search.auto_filename#" >
			<cfset row["path"] = "#search.auto_path#" >
			<cfset data[i]  = row>
			<cfset i = i + 1>
		</cfloop>
		<cfreturn #serializeJSON(data)#>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn #serializeJSON(data)#>
</cffunction>

</cfcomponent>
