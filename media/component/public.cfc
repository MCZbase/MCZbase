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

<!---Implementation for getMediaBlockHtml without creating a new thread 
@see getMediaBlockHtml for API documentation. 
WARNING: Do not make copies of this function and use elsewhere, 
include this function and use it.
--->
<!---Note: Need to remove any links to similar code on /media/component/search.cfc (moved code here)--->
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
					media.mask_media_fg,
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
					<cfif media.mask_media_fg NEQ 0>
						<!--- do not use IIIF for hidden media, it can't determine the context to know if the media should be delivered or not, so does not deliver hidden media --->
						<cfset enableIIIF = false>
					</cfif>
					<cfset iiifFull = "">
					<cfset xzoom = "">
					<cfif host EQ "mczbase.mcz.harvard.edu" AND enableIIIF>
						<cfif media_type EQ 'image' AND left(media.mime_type,6) EQ 'image/' AND media.mime_type NEQ 'image/x-nikon-nef'>
							<cfset iiifSchemeServerPrefix = "#Application.protocol#://iiif.mcz.harvard.edu/iiif/3/">
							<cfset iiifIdentifier = "#encodeForURL(media_id)#">
							<!---cfset iiifFull = "#iiifSchemeServerPrefix##iiifIdentifier#/full/max/0/default.jpg"--->
							<!---Temporarily limiting the max size of the returned images to avoid overloading the iiif server. See https://iiif.io/api/image/3.0/#42-size for iiifFull.--->
							<cfif media.height EQ "" OR media.width EQ "">
								<!--- see if the IIIF server knows the height and width --->
								<cftry>
									<cfset lookupInfo = "#iiifSchemeServerPrefix##iiifIdentifier#/info.json">
									<cfhttp url="#lookupInfo#" method="GET" result="info_json" redirect="yes" throwOnError="yes" timeout="3"> 
									<cfif isJSON(info_json.Filecontent)>
										<cfset info = deserializeJSON(info_json.Filecontent)>
										<cfset infoHeight = info.height>
										<cfset infoWidth = info.width>
										<cfif media.height EQ "">
											<cfquery name="addh" datasource="uam_god" timeout="2">
												INSERT INTO media_labels (
													media_id,
													media_label,
													label_value,
													assigned_by_agent_id
												) VALUES (
													<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">,
													'height',
													<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#infoHeight#">,
													0
												)
											</cfquery>
										</cfif>
										<cfif media.width EQ "">
											<cfquery name="addw" datasource="uam_god" timeout="2">
												INSERT INTO media_labels (
													media_id,
													media_label,
													label_value,
													assigned_by_agent_id
												) VALUES (
													<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">,
													'width',
													<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#infoWidth#">,
													0
												)
											</cfquery>
										</cfif>
									</cfif>
								<cfcatch>
									<!--- cfdump var="#cfcatch.message#" --->
								</cfcatch>
								</cftry>
							</cfif>
							<cfif media.height NEQ '' AND (media.height LT 2000 OR media.width LT 2000)>
								<cfset iiifFull = "#iiifSchemeServerPrefix##iiifIdentifier#/full/max/0/default.jpg">
							<cfelseif media.height EQ '' AND isDefined("infoHeight") AND (infoHeight LT 2000 OR infoWidth LT 2000)>
								<cfset iiifFull = "#iiifSchemeServerPrefix##iiifIdentifier#/full/max/0/default.jpg">
							<cfelse>
								<cfset iiifFull = "#iiifSchemeServerPrefix##iiifIdentifier#/full/!2000,2000/0/default.jpg">
							</cfif>
							<cfif #displayAs# EQ "fixedSmallThumb">
								<!--- workaround for zoom on fixed small thumb having aspect ratio of square not that of image delivered by iiif server --->
								<cfif media.height NEQ '' AND (media.height LT 2000 OR media.width LT 2000)>
									<cfset iiifSquare = "#iiifSchemeServerPrefix##iiifIdentifier#/square/max/0/default.jpg">
								<cfelseif media.height EQ '' AND isDefined("infoHeight") AND (infoHeight LT 2000 OR infoWidth LT 2000)>
									<cfset iiifSquare = "#iiifSchemeServerPrefix##iiifIdentifier#/square/max/0/default.jpg">
								<cfelse>
									<cfset iiifSquare = "#iiifSchemeServerPrefix##iiifIdentifier#/square/!2000,2000/0/default.jpg">
								</cfif>
							<cfelse>
								<!--- graceful failure, making sure iiifSquare is defined, shouldn't be used --->
								<cfset iiifSquare = iiifFull>
							</cfif>
							<cfset iiifSize = "#iiifSchemeServerPrefix##iiifIdentifier#/full/^#size#,/0/default.jpg">
							<cfset iiifThumb = "#iiifSchemeServerPrefix##iiifIdentifier#/full/,70/0/default.jpg">
							<cfset xzoom = 'class = "zoom"'>
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
								<cfset displayImage = iiifSize>
							<cfelse>
								<cfset displayImage = media_uri>
									<cfset styles = "height: 123px;margin: 0 auto;width: auto">
							</cfif>
						</cfif>
					<cfelse>
						<!---Resource specified by media_uri is not one that can be used in an image tag as img src="media_uri", we need to provide an alternative --->
						<cfif len(preview_uri) GT 0>
						 	<!--- there is a preview_uri, use that --->
							<cfif #displayAs# EQ "fixedSmallThumb">
								<cfset hw = 'height="#size#" width="#size#"'>
								<cfset sizeParameters='&width=#size#&height=#size#'>
								<cfset styles = "height: 76px;margin: 0 auto;width: auto">
								<cfset displayImage = "/media/rescaleImage.cfm?use_thumb=true&media_id=#media.media_id##sizeParameters##styles#&background_color=#background_color#">
							<cfelse>
								<!--- use a preview_uri, if one was specified --->
								<!--- TODO: change test to regex on http... with some sort of is this an image test --->
								<cfset displayImage = preview_uri>
								<cfif #displayAs# eq "thumb">
									<cfset hw = 'width="auto" height="auto"'>
									<cfset styles = "height: 76px;margin: 0 auto;width: auto;">
								<cfelse>
									<!---for shared drive images when the displayAs=thumb attribute is not used and a size is used instead. Since most of our intrinsic thumbnails in "preview_uri" field are around 150px or smaller, I will use that as the width. Height is "auto" for landscape and portrait.--->
									<!---Note: no difference between the two right now--->
									<cfif host EQ "nrs.harvard.edu" OR host EQ "www.morphosource.org">
											<cfset hw = 'width="auto" height="auto"'>
											<cfset styles = "height: 74px;margin: 0 auto;width: auto">
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
									<cfset size = "90">
									<cfset styles = "max-height:;width:auto;">
								<cfelse>
									<cfset size = "90">
								</cfif>
								
								<!--- svg files so size shouldn't matter too much.--->
								<cfset hw = 'height="#size#" width="#size#"'>
								<!--- pick placeholder --->
								<cfif media_type is "image">
									<cfset displayImage = "/shared/images/Image-x-generic.svg">
								<cfelseif media_type is "audio">
									<cfset displayImage =  "/shared/images/Gnome-audio-volume-medium.svg">
								<cfelseif media_type IS "video">
									<cfset displayImage =  "/shared/images/Gnome-video-x-generic.svg">
								<cfelseif media_type is "text">
									<cfset displayImage =  "/shared/images/Gnome-text-x-generic.svg">
								<cfelseif media_type is "3D model">
									<cfset displayImage =  "/shared/images/Dual_Cube-Octahedron.svg">
								<cfelseif media_type is "spectrometer data">
									<cfset displayImage = "/shared/images/Sine_waves_different_frequencies.svg">
								<cfelse>
									<cfset displayImage =  "/shared/images/placeholderGeneric.png">
									<!--- media_type is not on list from ctmedia_type --->
								</cfif>
							</cfif>
						</cfif>
					</cfif>
					<!--- prepare output --->

					<cfset output='#output#<div class="media_widget p-1" style="#minheight#">'>
					<!--- WARNING: if no caption text is shown, the image MUST link to the media metadata record, not the media object, otherwise rights information and other essential metadata are not shown to or reachable by the user. ' --->
					<cfif #captionAs# EQ "textNone">
						<cfset linkTarget = "/media/#media.media_id#">
					<cfelse>
						<cfset linkTarget = "#media.media_uri#">
					</cfif>
					<cfif host EQ "mczbase.mcz.harvard.edu" AND enableIIIF AND isDefined("iiifFull") AND len(iiifFull) GT 0>
						<cfset linkTarget = iiifFull>
					</cfif>
					<cfset unique = REReplace(CreateUUID(), "[-]", "", "all") >
					<cfset elementID = "MID_#media.media_id#_#unique#">
					<cfset output='#output#<a href="#linkTarget#" class="d-block mb-1 w-100 active text-center" title="click to access media">'>
					<cfset output='#output#<img id="#elementID#" src="#displayImage#" alt="#alt#" #hw# style="#styles#" title="Click for full image">'>
					<cfset output='#output#</a>'>
					<!--- multizoom library for zoom on hover ' --->
					<cfif isDisplayable>
						<cfif host EQ "mczbase.mcz.harvard.edu" AND enableIIIF AND isDefined("iiifFull") AND len(iiifFull) GT 0>
							<cfset displayTarget = iiifFull>
							<cfset squareDisplayTarget = iiifSquare>
						<cfelse>
							<cfset displayTarget = "#media.media_uri#">
							<cfset squareDisplayTarget = "#media.media_uri#">
						</cfif>
						<cfset minzoom="2">
						<cfif displayAs EQ "thumb">
							<!--- probably uses default size value of 600, but want larger zoom --->
							<cfset minzoom="4">
						</cfif>
						<cfif size LT 155>
							<cfset minzoom="4">
						</cfif>
						<cfif size LT 105>
							<cfset minzoom="5">
						</cfif>
						<cfif #displayAs# EQ "fixedSmallThumb">
							<cfset output='#output#<script type="text/javascript">jQuery(document).ready(function($){$("###elementId#").addimagezoom("###elementId#",{zoomrange: [#minzoom#,12],magnifiersize:["100%","100%"],magnifierpos:"right",cursorshadecolor:"##fdffd5",imagevertcenter:"true",cursorshade:true,largeimage:"#squareDisplayTarget#"})})</script>'>
						<cfelse>
							<cfset output='#output#<script type="text/javascript">jQuery(document).ready(function($){$("###elementId#").addimagezoom("###elementId#",{zoomrange: [#minzoom#,12],magnifiersize:["100%","100%"],magnifierpos:"right",cursorshadecolor:"##fdffd5",imagevertcenter:"true",cursorshade:true,largeimage:"#displayTarget#"})})</script>'>
						</cfif>
					</cfif>
					<cfif #captionAs# EQ "textNone">
						<!---textNone is used when we don't want any text (including links) below the thumbnail. This is used on Featured Collections of cataloged items on the specimenBrowse.cfm and grouping/index.cfm pages--->
					<cfelseif #captionAs# EQ "textLinks">
						<!--- textLinks is used when only the links are desired under the thumbnail--->
						<cfset output='#output#<div class="mt-0 col-12 pb-1 px-0">'>
						<cfset output='#output#<p class="col-12 text-center px-1 pb-1 mb-0 small">'>>!--- ' --->
						<cfif listcontainsnocase(session.roles,"manage_specimens")>
							<cfset output='#output#<span class="d-inline">(<a href="/media.cfm?action=edit&media_id=#media_id#">edit</a>) </span>'>
						</cfif>
						<cfset output='#output#(<a class="" href="/media/#media_id#">Media Record</a>)'><!--- ' --->
						<cfif NOT isDisplayable>
							<cfif listcontainsnocase(session.roles,"manage_publications")> <span class="sr-only">#media_type# (#mime_type#)</span></cfif>
								<cfset output='#output#(<a class="" href="#media_uri#">media file</a>)'><!--- ' --->
							<cfelse>
								<cfif CGI.script_name CONTAINS "/RelatedMedia.cfm">
									<!---If on the zoom/related page, i.e. RelatedMedia.cfm, we do not need a link to it.--->
								<cfelse>
									<cfset output='#output#<span class="d-none d-md-inline-block">(<a class="" href="/media/RelatedMedia.cfm?media_id=#media_id#">related</a>)</span>'>
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
							<cfif media_uri contains "www.morphosource.org">
								<cfset output='#output#(<a class="" href="#media_uri#">File</a>&nbsp;<img src="/images/linkOut.gif" class="m-0 p-0">)'>
							<cfelse>
								<cfset output='#output#(<a class="" href="#media_uri#">File</a>)'>
							</cfif>
						<cfelse>
							<cfif CGI.script_name CONTAINS "/RelatedMedia.cfm">
								<!---If on the zoom/related page, i.e. RelatedMedia.cfm, we do not need a link to it.--->
							<cfelse>
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
						<cfif title contains 'ledger entry for'>
							<cfset textAlign = "text-left">
						<cfelse>
							<cfset textAlign = "text-center">
						</cfif>
						<cfif len(showTitleText) EQ 0>
							<cfset showTitleText = trim(subject)>
						</cfif>
						<cfif #captionAs# EQ "textCaption"><!---This is for use when a caption of 197 characters is needed --->
							<cfif len(showTitleText) GT 197>
								<cfset showTitleText = "#left(showTitleText,197)#..." >
							</cfif>
						</cfif>
						<cfif #captionAs# EQ "textCaptionLong"><!---This is for use when a caption of 197 characters is needed --->
							<cfif len(showTitleText) GT 170>
								<cfset showTitleText = "#left(showTitleText,170)#..." >
							</cfif>
						</cfif>
						<cfif #captionAs# EQ "textCaptionFull"><!---This is for use when a full caption (or close to it) is needed. Related media (media viewer) --->
							<cfif len(showTitleText) GT 3999>
								<cfset showTitleText = "#left(showTitleText,3999)#..." >
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
						<cfset output='#output#<p class="#textAlign# col-12 my-0 py-0 px-1 smaller">#showTitleText#</p>'>
						<cfif len(#license_uri#) gt 0>
							<cfif #captionAs# EQ "TextFull">
								<!---height is needed on the caption within the <p> or the media will not flow well--the above comment works but may not work on other, non specimen detail pages--->
								<cfset output='#output#<p class="textAlign col-12 p-0 my-0 small">'>
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
						media.auto_host, media.auto_path, media.auto_filename,
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
				<cfset oneOfUs = 0>
				<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
					<cfset oneOfUs = 1>
				</cfif>
				<cfset manageTransactions = 0>
				<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_transactions")>
					<cfset manageTransactions=1>
				</cfif>
				<!--- The queries to specific relationships below provide the variables for displaying the links within the id=relatedLinks div --->
				<cfif manageTransactions EQ 1>
					<cfquery name="accns" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select distinct transaction_id, accn.accn_number
						from media_relations
							left join accn on media_relations.related_primary_key = accn.transaction_id
							left join mczbase.ctmedia_relationship on mczbase.ctmedia_relationship.media_relationship = media_relations.media_relationship
							left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat on accn.transaction_id = flat.accn_id
						where media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media.media_id#">
							and mczbase.ctmedia_relationship.auto_table = 'accn'
					</cfquery>
				<cfelse>
					<cfquery name="accns" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select null as transaction_id, null as accn_number from dual where 0=1
					</cfquery>
				</cfif>
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
				<cfif manageTransactions EQ 1>
					<cfquery name="borrow" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">	
						select b.transaction_id, b.lenders_trans_num_cde, b.borrow_number
						from media_relations mr
						left join borrow b on b.transaction_id = mr.related_primary_key
						left join mczbase.ctmedia_relationship ct on mr.media_relationship = ct.media_relationship
						where mr.media_id =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media.media_id#">
						and ct.media_relationship like '%borrow'
					</cfquery>
				<cfelse>
					<cfquery name="borrow" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">	
						select null as transaction_id, null as lenders_trans_num_cde, null as borrow_number from dual where 0=1
					</cfquery>
				</cfif>
				<cfquery name="collecting_events" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select distinct collecting_event.verbatim_locality,collecting_event.collecting_event_id, collecting_event.verbatim_date, collecting_event.ended_date, collecting_event.collecting_source
					from media_relations
						left join collecting_event on media_relations.related_primary_key = collecting_event.collecting_event_id
					where media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media.media_id#">
						and media_relations.media_relationship like '% collecting_event'
				</cfquery>
				<cfif manageTransactions EQ 1>
					<cfquery name="daccns" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select distinct transaction_id, deaccession.deacc_number
						from media_relations
							left join deaccession on media_relations.related_primary_key = deaccession.transaction_id
							left join mczbase.ctmedia_relationship on mczbase.ctmedia_relationship.media_relationship = media_relations.media_relationship
						where media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media.media_id#">
							and mczbase.ctmedia_relationship.auto_table = 'deaccession'
					</cfquery>
				<cfelse>
					<cfquery name="daccns" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select null as transaction_id, null as deacc_number from dual where 0=1
					</cfquery>
				</cfif>
				<cfif manageTransactions EQ 1>
					<cfquery name="loan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select distinct transaction_id, loan.loan_number
						from media_relations
							left join loan on media_relations.related_primary_key = loan.transaction_id
							left join mczbase.ctmedia_relationship on mczbase.ctmedia_relationship.media_relationship = media_relations.media_relationship
						where media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media.media_id#">
							and mczbase.ctmedia_relationship.auto_table = 'loan'
					</cfquery>
				<cfelse>
					<cfquery name="loan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select null as transaction_id, null as loan_number from dual where 0=1
					</cfquery>
				</cfif>
				<cfquery name="locali" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select distinct locality.spec_locality,locality.locality_ID, lat_long.dec_lat, lat_long.dec_long, lat_long.datum, lat_long.max_error_distance as error, lat_long.max_error_units as units
					from media_relations
						left join locality on media_relations.related_primary_key = locality.locality_id
						left join lat_long on lat_long.locality_id = locality.locality_id
					where media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media.media_id#">
						and media_relations.media_relationship = 'shows locality'
						and lat_long.accepted_lat_long_fg = 1
				</cfquery>
				<cfquery name="media1" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select distinct mr.related_primary_key as pk, m.media_uri
					from media m
						left join media_relations mr on mr.media_id = m.media_id 
						left join mczbase.ctmedia_relationship ct on mr.media_relationship = ct.media_relationship
					where m.media_id =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media.media_id#">
						and ct.media_relationship = 'related to media'
				</cfquery>
				<cfquery name="media2" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select distinct mr.related_primary_key as pk, m.media_uri
					from media m
						left join media_relations mr on mr.media_id = m.media_id 
						left join mczbase.ctmedia_relationship ct on mr.media_relationship = ct.media_relationship
					where m.media_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media.media_id#">
						and ct.media_relationship = 'transcript for audio media'
				</cfquery>
				<cfif manageTransactions EQ 1>
					<cfquery name="permit"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select distinct permit.permit_id, permit.permit_type,permit.permit_title
						from permit
						left join media_relations mr on permit.permit_id = mr.related_primary_key
						left join mczbase.ctmedia_relationship ct on mr.media_relationship = ct.media_relationship
						where mr.media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media.media_id#">
						and ct.auto_table = 'permit'
					</cfquery>
				<cfelse>
					<cfquery name="permit"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select null as permit_id, null as permit_type, null as permit_title from dual where 0=1
					</cfquery>
				</cfif>
				<cfquery name="publication" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select distinct p.publication_id as pk, fp.formatted_publication as pub_long
					from publication p
						left join media_relations mr on mr.RELATED_PRIMARY_KEY = p.publication_id 
						left join media m on m.media_id = mr.media_id
						left join citation c on c.publication_id = p.publication_id
						left join formatted_publication fp on fp.publication_id = p.publication_id
						left join mczbase.ctmedia_relationship ct on mr.media_relationship = ct.media_relationship
					where m.media_id =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media.media_id#">
						and ct.media_relationship = 'shows publication'
						and fp.format_style = 'long'
				</cfquery>
				<cfquery name="spec" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select distinct collection_object_id as pk, guid
					from media_relations
						left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat on related_primary_key = collection_object_id
						left join mczbase.ctmedia_relationship on mczbase.ctmedia_relationship.media_relationship = media_relations.media_relationship
					where media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media.media_id#">
						and mczbase.ctmedia_relationship.auto_table = 'cataloged_item'
						and mczbase.ctmedia_relationship.auto_table <> 'agent'
					order by guid
				</cfquery>
				<cfquery name="specpart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select distinct specimen_part.part_name
					from media_relations
						left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat on related_primary_key = collection_object_id
						left join specimen_part on specimen_part.derived_from_cat_item = flat.collection_object_id
						left join mczbase.ctmedia_relationship on mczbase.ctmedia_relationship.media_relationship = media_relations.media_relationship
					where media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media.media_id#">
						and mczbase.ctmedia_relationship.auto_table <> 'agent'
					order by part_name
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
		
				<!---Loop through the media to see what the metadata is for the featured image on the page--->
				<cfloop query="media">
					<cfquery name="labels" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT media_label, label_value, agent_name, media_label_id
					FROM media_labels
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
						SELECT media_keywords.media_id, keywords
						FROM media_keywords
						WHERE media_keywords.media_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
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
							<cfif listcontainsnocase(session.roles,"manage_media")>
								<tr class="border mt-2 p-2"><th scope="row">Media URI </th><td><a target="_blank" href="#media.media_uri#">#media.media_uri#</a></td></tr>
							</cfif>
							<cfif listcontainsnocase(session.roles,"manage_media")>
								<cfset thumbText = "None. Default Thumbnail for media type used.">
								<cfif len(media.preview_uri) GT 0>
									<cfset thumbText = "<a target='_blank' href='#media.preview_uri#'>#media.preview_uri#</a>">
								</cfif>
								<tr class="border mt-2 p-2"><th scope="row">Preview URI: </th><td>#thumbText#</td></tr>
							</cfif>
							<cfif listcontainsnocase(session.roles,"manage_media")>
								<cfif media.auto_host EQ "mczbase.mcz.harvard.edu">
									<!--- check if file exists --->
									<cfset size = "">
									<cfset sizein = "">
									<cfset filefull = "#Application.webDirectory#/#media.auto_path##media.auto_filename#">
									<cfset directory = "#Application.webDirectory#/#media.auto_path#">
									<cfif fileExists("#filefull#")>
										<cfset found = "[Found]">
										<cfset info = GetFileInfo("#filefull#")>
										<cfset size = info.size>
										<cfset sizein = "bytes">
										<cfif size GT 1024><cfset size=Int(size/1024)><cfset sizein="kb"></cfif>
										<cfif size GT 1024><cfset size=Int(size/1024)><cfset sizein="mb"></cfif>
										<tr class="border mt-2 p-2"><th scope="row">Directory: </th><td>#media.auto_path#</td></tr>
									<cfelse>
										<cfset found = "[Not Found]">
										<cfif NOT directoryExists("#directory#")><cfset found = "#found# [Directory Not Found]"></cfif>
										<cfset found = "<span class='strong text-danger'>#found#</span>"><!--- " --->
									</cfif>
									<tr class="border mt-2 p-2"><th scope="row">File: </th><td>#media.auto_filename# #found# #size# #sizein#</td></tr>
								</cfif>
							</cfif>
							<cfif len(media_rel.media_relationship) gt 0>
								<cfif media_rel.recordcount GT 1>
									<cfset plural = "s">
								<cfelse>
									<cfset plural = "">
								</cfif>
								<tr>
									<th scope="row">Relationship#plural#:&nbsp; </span></th>
									<td class="w-80">
									<!---Loops through the media relationships (query = media_rel) and specific relationship queries above (queries=accn, agents1-5,collecting_events, daccns,loan, locali, media1-2,publication, spec, underscore) to find related media to the featured image on the page. Displays Media Relationship even if the links are not provided within the relatedLinks div (due to permissions or not being set up yet). It is somewhat scalable with regards to new relationship type entries on the code table--->
									<cfset relationSeparator = "">
				
									<cfloop query="media_rel">
										#relationSeparator#
										<!---The links within the div with id = "relatedLinks" provides access to the pages linked to the featured media (media_id of the page)--->
										#media_rel.label#<cfif len(media_rel.label) gt 0>:</cfif>
										<div id = "relatedLinks" class="comma2 d-inline">
											<!---Display Accn: documents accn--->
											<cfif media_rel.media_relationship eq 'documents accn'>
												<cfif oneofus eq 1>
													<cfloop query="accns">
														<a href="/transactions/Accession.cfm?action=edit&transaction_id=#accns.transaction_id#" class="font-weight-lessbold">#accns.accn_number#</a><cfif accns.recordcount gt 1><span>, </span></cfif>
													</cfloop>
												<cfelse>
													<span class="d-inline font-italic">Hidden</span>
												</cfif>
											</cfif>
											<!---Display Agent: created by agent query--->
											<cfif media_rel.media_relationship eq 'created by agent'>
												<cfloop query="agents1">
													<a class="font-weight-lessbold" href="/agents/Agent.cfm?agent_id=#agents1.agent_id#"> #agents1.agent_name#</a><cfif agents1.recordcount gt 1><span>, </span></cfif>
												</cfloop>
											</cfif>
											<!---Display Agent: shows agent query--->
											<cfif media_rel.media_relationship eq 'shows agent'>
												<cfloop query="agents2">
													<a class="font-weight-lessbold" href="/agents/Agent.cfm?agent_id=#agents2.agent_id#"> #agents2.agent_name#</a><cfif agents2.recordcount gt 1><span>, </span></cfif>
												</cfloop>
											</cfif>
											<!---Display Agent: documents agent query--->
											<cfif media_rel.media_relationship eq 'documents agent'>
												<cfloop query="agents3">
													<a class="font-weight-lessbold" href="/agents/Agent.cfm?agent_id=#agents3.agent_id#"> #agents3.agent_name#</a><cfif agents3.recordcount gt 1><span>, </span></cfif>
												</cfloop>
											</cfif>
											<!---Display Agent: shows handwriting of agent query--->
											<cfif media_rel.media_relationship eq 'shows handwriting of agent'>
												<cfloop query="agents4">
													<a class="font-weight-lessbold" href="/agents/Agent.cfm?agent_id=#agents4.agent_id#"> #agents4.agent_name#</a><cfif agents4.recordcount gt 1><span>, </span></cfif>
												</cfloop>
											</cfif>
											<!---Display Agent: physical object created by agent query--->
											<cfif media_rel.media_relationship eq 'physical object created by agent'>
												<cfloop query="agents5">
													<a class="font-weight-lessbold" href="/agents/Agent.cfm?agent_id=#agents5.agent_id#"> #agents5.agent_name#</a><cfif agents5.recordcount gt 1><span>, </span></cfif>
												</cfloop>
											</cfif>
											<!---Display Borrow--->
											<cfif media_rel.media_relationship contains 'borrow'>
												<cfif oneofus eq 1>
													<cfloop query="borrow">
														<a class="font-weight-lessbold" href="/borrow/Borrow.cfm?transaction_id=#borrow.transaction_id#"> #borrow.borrow_number#</a><cfif borrow.recordcount gt 1><span>, </span></cfif>
													</cfloop>
												<cfelse>
													<span class="d-inline font-italic">Hidden</span>
												</cfif>
											</cfif>
											<!---Display Collecting Event: relationship = %collecting event--->
											<cfif media_rel.media_relationship contains 'collecting_event'>
												<cfloop query="collecting_events">
													<a class="font-weight-lessbold" href="/showLocality.cfm?action=srch&collecting_event_id=#collecting_events.collecting_event_id#">#collecting_events.verbatim_locality#  #collecting_events.collecting_source# #collecting_events.verbatim_date# 
													<cfif collecting_events.ended_date gt 0>(#collecting_events.ended_date#)</cfif></a><cfif collecting_events.recordcount gt 1><span>, </span></cfif>
												</cfloop>
											</cfif>
											<!---Display Deaccession: relationship = documents deaccession--->
											<cfif media_rel.media_relationship eq 'documents deaccession'>
												<cfif oneofus eq 1>
													<cfloop query="daccns">
														<a href="/transactions/Deaccession.cfm?action=edit&transaction_id=#daccns.transaction_id#" class="font-weight-lessbold">#daccns.deacc_number#</a><cfif daccns.recordcount gt 1><span>, </span></cfif>
													</cfloop>
												<cfelse>
													<span class="d-inline font-italic">Hidden</span>
												</cfif>
											</cfif>
											<!---Display loan: relationship = documents loan--->
											<cfif media_rel.media_relationship eq 'documents loan'>
												<cfif oneofus eq 1>
													<cfloop query="loan">
														<a class="font-weight-lessbold" href="/transactions/Loan.cfm?action=editLoan&transaction_id=#loan.transaction_id#"> #loan.loan_number#</a><cfif loan.recordcount gt 1><span>, </span></cfif>
													</cfloop>
												<cfelse>
													<span class="d-inline font-italic">Hidden</span>
												</cfif>
											</cfif>
											<!---Display Permit: relationship like %permit--->
											<cfif media_rel.media_relationship contains 'permit'>
												<cfif oneofus eq 1>
													<cfloop query="permit">
														<a class="font-weight-lessbold" href="/transactions/Permit.cfm?action=edit&permit_id=#permit.permit_id#"> Permit ID: #permit.permit_id#/#permit.permit_type#</a><cfif permit.recordcount gt 1><span>, </span></cfif>
													</cfloop>
												<cfelse>
													<span class="d-inline font-italic">Hidden</span>
												</cfif>
											</cfif>
											<!---Display Locality: relationship = shows locality--->
											<cfif media_rel.media_relationship eq 'shows locality'>
												<cfloop query="locali">
													<a class="font-weight-lessbold" href="/showLocality.cfm?action=srch&locality_id=#locali.locality_id#">#locali.spec_locality# #NumberFormat(locali.dec_lat,'00.00')#, #NumberFormat(locali.dec_long,'00.00')# (datum: 
													<cfif len(locali.datum)gt 0>#locali.datum#<cfelse>none listed</cfif>) error: #locali.error##locali.units#</a><cfif locali.recordcount gt 1><span>, </span></cfif>
												</cfloop>
											</cfif>
											<!---Display Media: relationship = related to media--->
											<cfif media_rel.media_relationship eq 'related to media'> 
												<cfloop query="media1">
													<a class="font-weight-lessbold" href="/media/#media1.pk#"> /media/#media1.pk#</a>
													<cfif media1.recordcount gt 1><span>, </span></cfif>
												</cfloop>
											</cfif>
											<!---Display Media: relationship = transcript for audio media--->
											<cfif media_rel.media_relationship eq 'transcript for audio media'>
												<cfloop query="media2">
													<a class="font-weight-lessbold" href="/media/#media2.pk#"> /media/#media2.pk#</a>
													<cfif media2.recordcount gt 1><span>, </span></cfif>
												</cfloop>
											</cfif>
											<!---Display shows publication--->
											<cfif media_rel.media_relationship eq 'shows publication'> 
												<cfloop query="publication">
													<a class="font-weight-lessbold" href="/publications/showPublication.cfm?publication_id=#publication.pk#">#publication.pub_long# </a>
													<cfif publication.recordcount gt 1><span> &##8226;&##8226; </span></cfif>
												</cfloop>
											</cfif>
											<!---Display Specimens and Ledgers: relationship = %cataloged_item--->
											<cfif media_rel.auto_table eq 'cataloged_item'> 
												<cfloop query="spec">
													<a class="font-weight-lessbold" href="/guid/#spec.guid#">#spec.guid#</a><cfif spec.recordcount gt 1><span>, </span></cfif>
												</cfloop>
											</cfif>
											<!---Display Specimens parts--->
											<cfif media_rel.auto_table eq 'specimen_part'> 
												<cfloop query="specpart">
													<span class="font-weight-lessbold">#specpart.part_name# </span>
												</cfloop>
											</cfif>
											<!---Display underscore_collection--->
											<cfif media_rel.media_relationship eq 'shows underscore_collection'>:
												<cfloop query="underscore">
													<a class="font-weight-lessbold" href="/grouping/showNamedCollection.cfm?underscore_collection_id=#underscore.underscore_collection_id#"> #underscore.collection_name#</a><cfif underscore.recordcount gt 1><span>, </span></cfif>
												</cfloop>
											</cfif>
										</div>
										<cfset relationSeparator='<span class="px-1"> | </span>'><!--- ' --->
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

					
<!--- Edit Media Metadata Table using media_id --->		
<cffunction name="editMediaMetadata"  access="remote" returntype="string" returnformat="plain">
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
						media.auto_host, media.auto_path, media.auto_filename,
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
				<cfset oneOfUs = 0>
				<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
					<cfset oneOfUs = 1>
				</cfif>
				<cfset manageTransactions = 0>
				<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_transactions")>
					<cfset manageTransactions=1>
				</cfif>
				<!--- The queries to specific relationships below provide the variables for displaying the links within the id=relatedLinks div --->
				<cfif manageTransactions EQ 1>
					<cfquery name="accns" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select distinct transaction_id, accn.accn_number
						from media_relations
							left join accn on media_relations.related_primary_key = accn.transaction_id
							left join mczbase.ctmedia_relationship on mczbase.ctmedia_relationship.media_relationship = media_relations.media_relationship
							left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat on accn.transaction_id = flat.accn_id
						where media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media.media_id#">
							and mczbase.ctmedia_relationship.auto_table = 'accn'
					</cfquery>
				<cfelse>
					<cfquery name="accns" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select null as transaction_id, null as accn_number from dual where 0=1
					</cfquery>
				</cfif>
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
				<cfif manageTransactions EQ 1>
					<cfquery name="borrow" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">	
						select b.transaction_id, b.lenders_trans_num_cde, b.borrow_number
						from media_relations mr
						left join borrow b on b.transaction_id = mr.related_primary_key
						left join mczbase.ctmedia_relationship ct on mr.media_relationship = ct.media_relationship
						where mr.media_id =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media.media_id#">
						and ct.media_relationship like '%borrow'
					</cfquery>
				<cfelse>
					<cfquery name="borrow" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">	
						select null as transaction_id, null as lenders_trans_num_cde, null as borrow_number from dual where 0=1
					</cfquery>
				</cfif>
				<cfquery name="collecting_events" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select distinct collecting_event.verbatim_locality,collecting_event.collecting_event_id, collecting_event.verbatim_date, collecting_event.ended_date, collecting_event.collecting_source
					from media_relations
						left join collecting_event on media_relations.related_primary_key = collecting_event.collecting_event_id
					where media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media.media_id#">
						and media_relations.media_relationship like '% collecting_event'
				</cfquery>
				<cfif manageTransactions EQ 1>
					<cfquery name="daccns" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select distinct transaction_id, deaccession.deacc_number
						from media_relations
							left join deaccession on media_relations.related_primary_key = deaccession.transaction_id
							left join mczbase.ctmedia_relationship on mczbase.ctmedia_relationship.media_relationship = media_relations.media_relationship
						where media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media.media_id#">
							and mczbase.ctmedia_relationship.auto_table = 'deaccession'
					</cfquery>
				<cfelse>
					<cfquery name="daccns" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select null as transaction_id, null as deacc_number from dual where 0=1
					</cfquery>
				</cfif>
				<cfif manageTransactions EQ 1>
					<cfquery name="loan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select distinct transaction_id, loan.loan_number
						from media_relations
							left join loan on media_relations.related_primary_key = loan.transaction_id
							left join mczbase.ctmedia_relationship on mczbase.ctmedia_relationship.media_relationship = media_relations.media_relationship
						where media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media.media_id#">
							and mczbase.ctmedia_relationship.auto_table = 'loan'
					</cfquery>
				<cfelse>
					<cfquery name="loan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select null as transaction_id, null as loan_number from dual where 0=1
					</cfquery>
				</cfif>
				<cfquery name="locali" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select distinct locality.spec_locality,locality.locality_ID, lat_long.dec_lat, lat_long.dec_long, lat_long.datum, lat_long.max_error_distance as error, lat_long.max_error_units as units
					from media_relations
						left join locality on media_relations.related_primary_key = locality.locality_id
						left join lat_long on lat_long.locality_id = locality.locality_id
					where media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media.media_id#">
						and media_relations.media_relationship = 'shows locality'
						and lat_long.accepted_lat_long_fg = 1
				</cfquery>
				<cfquery name="media1" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select distinct mr.related_primary_key as pk, m.media_uri
					from media m
						left join media_relations mr on mr.media_id = m.media_id 
						left join mczbase.ctmedia_relationship ct on mr.media_relationship = ct.media_relationship
					where m.media_id =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media.media_id#">
						and ct.media_relationship = 'related to media'
				</cfquery>
				<cfquery name="media2" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select distinct mr.related_primary_key as pk, m.media_uri
					from media m
						left join media_relations mr on mr.media_id = m.media_id 
						left join mczbase.ctmedia_relationship ct on mr.media_relationship = ct.media_relationship
					where m.media_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media.media_id#">
						and ct.media_relationship = 'transcript for audio media'

				</cfquery>
				<cfif manageTransactions EQ 1>
					<cfquery name="permit"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select distinct permit.permit_id, permit.permit_type,permit.permit_title
						from permit
						left join media_relations mr on permit.permit_id = mr.related_primary_key
						left join mczbase.ctmedia_relationship ct on mr.media_relationship = ct.media_relationship
						where mr.media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media.media_id#">
						and ct.auto_table = 'permit'
					</cfquery>
				<cfelse>
					<cfquery name="permit"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select null as permit_id, null as permit_type, null as permit_title from dual where 0=1
					</cfquery>
				</cfif>
				<cfquery name="publication" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select distinct p.publication_id as pk, fp.formatted_publication as pub_long
					from publication p
						left join media_relations mr on mr.RELATED_PRIMARY_KEY = p.publication_id 
						left join media m on m.media_id = mr.media_id
						left join citation c on c.publication_id = p.publication_id
						left join formatted_publication fp on fp.publication_id = p.publication_id
						left join mczbase.ctmedia_relationship ct on mr.media_relationship = ct.media_relationship
					where m.media_id =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media.media_id#">
						and ct.media_relationship = 'shows publication'
						and fp.format_style = 'long'
				</cfquery>
				<cfquery name="spec" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select distinct collection_object_id as pk, guid
					from media_relations
						left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat on related_primary_key = collection_object_id
						left join mczbase.ctmedia_relationship on mczbase.ctmedia_relationship.media_relationship = media_relations.media_relationship
					where media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media.media_id#">
						and mczbase.ctmedia_relationship.auto_table = 'cataloged_item'
						and mczbase.ctmedia_relationship.auto_table <> 'agent'
					order by guid
				</cfquery>
				<cfquery name="specpart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select distinct specimen_part.part_name
					from media_relations
						left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat on related_primary_key = collection_object_id
						left join specimen_part on specimen_part.derived_from_cat_item = flat.collection_object_id
						left join mczbase.ctmedia_relationship on mczbase.ctmedia_relationship.media_relationship = media_relations.media_relationship
					where media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media.media_id#">
						and mczbase.ctmedia_relationship.auto_table <> 'agent'
					order by part_name
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
		
				<!---Loop through the media to see what the metadata is for the featured image on the page--->
				<cfloop query="media">
					<cfquery name="labels" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT media_label, label_value, agent_name, media_label_id
					FROM media_labels
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
						SELECT media_keywords.media_id, keywords
						FROM media_keywords
						WHERE media_keywords.media_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
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
							<cfif listcontainsnocase(session.roles,"manage_media")>
								<tr class="border mt-2 p-2"><th scope="row">Media URI </th><td><a target="_blank" href="#media.media_uri#">#media.media_uri#</a></td></tr>
							</cfif>
							<cfif listcontainsnocase(session.roles,"manage_media")>
								<cfset thumbText = "None. Default Thumnail for media type used.">
								<cfif len(media.preview_uri) GT 0>
									<cfset thumbText = "<a target='_blank' href='#media.preview_uri#'>#media.preview_uri#</a>">
								</cfif>
								<tr class="border mt-2 p-2"><th scope="row">Preview URI: </th><td>#thumbText#</td></tr>
							</cfif>
							<cfif listcontainsnocase(session.roles,"manage_media")>
								<cfif media.auto_host EQ "mczbase.mcz.harvard.edu">
									<!--- check if file exists --->
									<cfset size = "">
									<cfset sizein = "">
									<cfset filefull = "#Application.webDirectory#/#media.auto_path##media.auto_filename#">
									<cfset directory = "#Application.webDirectory#/#media.auto_path#">
									<cfif fileExists("#filefull#")>
										<cfset found = "[Found]">
										<cfset info = GetFileInfo("#filefull#")>
										<cfset size = info.size>
										<cfset sizein = "bytes">
										<cfif size GT 1024><cfset size=Int(size/1024)><cfset sizein="kb"></cfif>
										<cfif size GT 1024><cfset size=Int(size/1024)><cfset sizein="mb"></cfif>
										<tr class="border mt-2 p-2"><th scope="row">Directory: </th><td>#media.auto_path#</td></tr>
									<cfelse>
										<cfset found = "[Not Found]">
										<cfif NOT directoryExists("#directory#")><cfset found = "#found# [Directory Not Found]"></cfif>
										<cfset found = "<span class='strong text-danger'>#found#</span>"><!--- " --->
									</cfif>
									<tr class="border mt-2 p-2"><th scope="row">File: </th><td>#media.auto_filename# #found# #size# #sizein#</td></tr>
								</cfif>
							</cfif>
							<cfif len(media_rel.media_relationship) gt 0>
								<cfif media_rel.recordcount GT 1>
									<cfset plural = "s">
								<cfelse>
									<cfset plural = "">
								</cfif>
								<tr>
									<th scope="row">Relationship#plural#:&nbsp; </span></th>
									<td class="w-80">
									<!---Loops through the media relationships (query = media_rel) and specific relationship queries above (queries=accn, agents1-5,collecting_events, daccns,loan, locali, media1-2,publication, spec, underscore) to find related media to the featured image on the page. Displays Media Relationship even if the links are not provided within the relatedLinks div (due to permissions or not being set up yet). It is somewhat scalable with regards to new relationship type entries on the code table--->
									<cfset relationSeparator = "">
				
									<cfloop query="media_rel">
										#relationSeparator#
										<!---The links within the div with id = "relatedLinks" provides access to the pages linked to the featured media (media_id of the page)--->
										#media_rel.label#<cfif len(media_rel.label) gt 0>:</cfif>
										<div id = "relatedLinks" class="comma2 d-inline">
											<!---Display Accn: documents accn--->
											<cfif media_rel.media_relationship eq 'documents accn'>
												<cfif oneofus eq 1>
													<cfloop query="accns">
														<a href="/transactions/Accession.cfm?action=edit&transaction_id=#accns.transaction_id#" class="font-weight-lessbold">#accns.accn_number#</a><cfif accns.recordcount gt 1><span>, </span></cfif>
													</cfloop>
												<cfelse>
													<span class="d-inline font-italic">Hidden</span>
												</cfif>
											</cfif>
											<!---Display Agent: created by agent query--->
											<cfif media_rel.media_relationship eq 'created by agent'>
												<cfloop query="agents1">
													<a class="font-weight-lessbold" href="/agents/Agent.cfm?agent_id=#agents1.agent_id#"> #agents1.agent_name#</a><cfif agents1.recordcount gt 1><span>, </span></cfif>
												</cfloop>
											</cfif>
											<!---Display Agent: shows agent query--->
											<cfif media_rel.media_relationship eq 'shows agent'>
												<cfloop query="agents2">
													<a class="font-weight-lessbold" href="/agents/Agent.cfm?agent_id=#agents2.agent_id#"> #agents2.agent_name#</a><cfif agents2.recordcount gt 1><span>, </span></cfif>
												</cfloop>
											</cfif>
											<!---Display Agent: documents agent query--->
											<cfif media_rel.media_relationship eq 'documents agent'>
												<cfloop query="agents3">
													<a class="font-weight-lessbold" href="/agents/Agent.cfm?agent_id=#agents3.agent_id#"> #agents3.agent_name#</a><cfif agents3.recordcount gt 1><span>, </span></cfif>
												</cfloop>
											</cfif>
											<!---Display Agent: shows handwriting of agent query--->
											<cfif media_rel.media_relationship eq 'shows handwriting of agent'>
												<cfloop query="agents4">
													<a class="font-weight-lessbold" href="/agents/Agent.cfm?agent_id=#agents4.agent_id#"> #agents4.agent_name#</a><cfif agents4.recordcount gt 1><span>, </span></cfif>
												</cfloop>
											</cfif>
											<!---Display Agent: physical object created by agent query--->
											<cfif media_rel.media_relationship eq 'physical object created by agent'>
												<cfloop query="agents5">
													<a class="font-weight-lessbold" href="/agents/Agent.cfm?agent_id=#agents5.agent_id#"> #agents5.agent_name#</a><cfif agents5.recordcount gt 1><span>, </span></cfif>
												</cfloop>
											</cfif>
											<!---Display Borrow--->
											<cfif media_rel.media_relationship contains 'borrow'>
												<cfif oneofus eq 1>
													<cfloop query="borrow">
														<a class="font-weight-lessbold" href="/borrow/Borrow.cfm?transaction_id=#borrow.transaction_id#"> #borrow.borrow_number#</a><cfif borrow.recordcount gt 1><span>, </span></cfif>
													</cfloop>
												<cfelse>
													<span class="d-inline font-italic">Hidden</span>
												</cfif>
											</cfif>
											<!---Display Collecting Event: relationship = %collecting event--->
											<cfif media_rel.media_relationship contains 'collecting_event'>
												<cfloop query="collecting_events">
													<a class="font-weight-lessbold" href="/showLocality.cfm?action=srch&collecting_event_id=#collecting_events.collecting_event_id#">#collecting_events.verbatim_locality#  #collecting_events.collecting_source# #collecting_events.verbatim_date# 
													<cfif collecting_events.ended_date gt 0>(#collecting_events.ended_date#)</cfif></a><cfif collecting_events.recordcount gt 1><span>, </span></cfif>
												</cfloop>
											</cfif>
											<!---Display Deaccession: relationship = documents deaccession--->
											<cfif media_rel.media_relationship eq 'documents deaccession'>
												<cfif oneofus eq 1>
													<cfloop query="daccns">
														<a href="/transactions/Deaccession.cfm?action=edit&transaction_id=#daccns.transaction_id#" class="font-weight-lessbold">#daccns.deacc_number#</a><cfif daccns.recordcount gt 1><span>, </span></cfif>
													</cfloop>
												<cfelse>
													<span class="d-inline font-italic">Hidden</span>
												</cfif>
											</cfif>
											<!---Display loan: relationship = documents loan--->
											<cfif media_rel.media_relationship eq 'documents loan'>
												<cfif oneofus eq 1>
													<cfloop query="loan">
														<a class="font-weight-lessbold" href="/transactions/Loan.cfm?action=editLoan&transaction_id=#loan.transaction_id#"> #loan.loan_number#</a><cfif loan.recordcount gt 1><span>, </span></cfif>
													</cfloop>
												<cfelse>
													<span class="d-inline font-italic">Hidden</span>
												</cfif>
											</cfif>
											<!---Display Permit: relationship like %permit--->
											<cfif media_rel.media_relationship contains 'permit'>
												<cfif oneofus eq 1>
													<cfloop query="permit">
														<a class="font-weight-lessbold" href="/transactions/Permit.cfm?action=edit&permit_id=#permit.permit_id#"> Permit ID: #permit.permit_id#/#permit.permit_type#</a><cfif permit.recordcount gt 1><span>, </span></cfif>
													</cfloop>
												<cfelse>
													<span class="d-inline font-italic">Hidden</span>
												</cfif>
											</cfif>
											<!---Display Locality: relationship = shows locality--->
											<cfif media_rel.media_relationship eq 'shows locality'>
												<cfloop query="locali">
													<a class="font-weight-lessbold" href="/showLocality.cfm?action=srch&locality_id=#locali.locality_id#">#locali.spec_locality# #NumberFormat(locali.dec_lat,'00.00')#, #NumberFormat(locali.dec_long,'00.00')# (datum: 
													<cfif len(locali.datum)gt 0>#locali.datum#<cfelse>none listed</cfif>) error: #locali.error##locali.units#</a><cfif locali.recordcount gt 1><span>, </span></cfif>
												</cfloop>
											</cfif>
											<!---Display Media: relationship = related to media--->
											<cfif media_rel.media_relationship eq 'related to media'> 
												<cfloop query="media1">
													<a class="font-weight-lessbold" href="/media/#media1.pk#"> /media/#media1.pk#</a>
													<cfif media1.recordcount gt 1><span>, </span></cfif>
												</cfloop>
											</cfif>
											<!---Display Media: relationship = transcript for audio media--->
											<cfif media_rel.media_relationship eq 'transcript for audio media'>
												<cfloop query="media2">
													<a class="font-weight-lessbold" href="/media/#media2.pk#"> /media/#media2.pk#</a>
													<cfif media2.recordcount gt 1><span>, </span></cfif>
												</cfloop>
											</cfif>
											<!---Display shows publication--->
											<cfif media_rel.media_relationship eq 'shows publication'> 
												<cfloop query="publication">
													<a class="font-weight-lessbold" href="/publications/showPublication.cfm?publication_id=#publication.pk#">#publication.pub_long# </a>
													<cfif publication.recordcount gt 1><span> &##8226;&##8226; </span></cfif>
												</cfloop>
											</cfif>
											<!---Display Specimens and Ledgers: relationship = %cataloged_item--->
											<cfif media_rel.auto_table eq 'cataloged_item'> 
												<cfloop query="spec">
													<a class="font-weight-lessbold" href="/guid/#spec.guid#">#spec.guid#</a><cfif spec.recordcount gt 1><span>, </span></cfif>
												</cfloop>
											</cfif>
											<!---Display Specimens parts--->
											<cfif media_rel.auto_table eq 'specimen_part'> 
												<cfloop query="specpart">
													<span class="font-weight-lessbold">#specpart.part_name# </span>
												</cfloop>
											</cfif>
											<!---Display underscore_collection--->
											<cfif media_rel.media_relationship eq 'shows underscore_collection'>:
												<cfloop query="underscore">
													<a class="font-weight-lessbold" href="/grouping/showNamedCollection.cfm?underscore_collection_id=#underscore.underscore_collection_id#"> #underscore.collection_name#</a><cfif underscore.recordcount gt 1><span>, </span></cfif>
												</cfloop>
											</cfif>
										</div>
										<cfset relationSeparator='<span class="px-1"> | </span>'><!--- ' --->
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
</cfcomponent>
