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
<cfif isdefined("width") AND len(width) GT 0 and IsNumeric(width)>
	<cfset fitWidth = width>
<cfelse>
	<cfset fitWidth = 300>
</cfif>
<cfset mimeType = "image/png">
<cfif NOT isdefined("media_id") OR len(media_id) EQ 0>
	<cfset target = "#Application.webDirectory#/shared/images/missing_image_icon_298822.png">
<cfelse>
	<cfquery name="media" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="media_result">
		SELECT
			media_type, mime_type, media_uri,
			MCZBASE.get_medialabel(media.media_id,'width') as width,
		FROM media
		WHERE
			media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
			AND MCZBASE.is_media_encumbered(media_id)  < 1 
	</cfquery>
	<cfif media.recordcount EQ 1>
		<cfloop query="media">
			<cfif mime_type EQ 'image/jpeg' OR mime_type EQ 'image/png'>
				<cfset target = replace(media_uri,'https://mczbase.mcz.harvard.edu','#Application.webDirectory#') >
				<cfset target = replace(media_uri,'http://mczbase.mcz.harvard.edu','#Application.webDirectory#') >
				<cfset mimeType = "#mime_type#">
			<cfelse>
				<cfif media_type EQ 'image'>
					<cfif fitWidth GT media.width >
						<!--- just deliver the image --->
						<cflocation URL="#media.media_uri#">
						<cfabort>
					<cfelse>
						<!--- setup to rescale --->
						<cfset target = "#Application.webDirectory#/shared/images/noExternalImage.png">
					</cfif>
				<cfelse>
					<!--- not an image file --->
					<!--- TODO: icons for other media types --->
					<cfset target = "#Application.webDirectory#/shared/images/noThumbDoc.png">
				</cfif>
			</cfif>
		</cfloop>
	<cfelse>
		<!--- no matching media file found --->
		<cfset target = "#Application.webDirectory#/shared/images/missing_image_icon_298822.png">
	</cfif>
</cfif>

<cftry>
	<cfimage source="#target#" name="targetImage">
	<cfset ImageSetAntialiasing(targetImage,"on")>
	<cfset ImageScaleToFit(targetImage,#fitWidth#,"","highestPerformance")>
	<cfset response = getPageContext().getFusionContext().getResponse()>
	<cfheader name="Content-Type" value="#mimeType#">
	<cfset response.getOutputStream().writeThrough(ImageGetBlob(targetImage))>
	<cfabort>
<cfcatch>
	<cfset imageSrc = "/shared/images/missing_image_icon_298822.png">
	<cflocation URL="#Application.serverRootUrl##imageSrc#">
</cfcatch>
</cftry>
