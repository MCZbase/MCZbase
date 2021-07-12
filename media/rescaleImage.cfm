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

--->
<cfif NOT isdefined("fitWidth") OR len(fitWidth) EQ 0>
	<cfset fitWidth = 300>
</cfif>
<cfif NOT isdefined("media_id") OR len(media_id) EQ 0>
	<cfset target = "/shared/images/missing_image_icon_298822.png">
<cfelse>
	<cfquery name="media" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="media_result">
		SELECT
			media_type, mime_type, media_uri
		FROM media
		WHERE
			media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="media_id">
	</cfquery>
	<cfif media.recordcount EQ 1>
		<cfloop query="media">
			<cfif mime_type EQ 'image/jpeg' OR mime_type EQ 'image/png'>
				<cfset target = replace(media_uri,'https://mczbase.mcz.harvard.edu','') >
				<cfset target = replace(media_uri,'http://mczbase.mcz.harvard.edu','') >
			<cfelse>
				<cfif media_type EQ 'image'>
					<cfset target = "/shared/images/noExternalImage.png">
				<cfelse>
					<!--- TODO: icons for other media types --->
					<cfset target = "/shared/images/noThumbDoc.png">
				</cfif>
			</cfif>
		</cfloop>
	<cfelse>
		<cfset target = "/shared/images/missing_image_icon_298822.png">
	<cfif>
</cfif>

<cfif isImageFile(target)>
	<cfimage source="#target#" name="targetImage">
	<cfset ImageSetAntialiasing(targetImage,"on")>
	<cfset ImageScaleToFit(targetImage,100,"","lanczos")>
	<cfimage source="#targetImage#" action="writeToBrowser">
<cfelse>
	<cfset target = "/shared/images/missing_image_icon_298822.png">
	<cfimage source="#target#" name="targetImage">
	<cfimage source="#targetImage#" action="writeToBrowser">
</cfif>
