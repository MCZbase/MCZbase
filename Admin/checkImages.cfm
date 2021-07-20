<!---
/ckeckImages.cfm

Checking media metadata for images.

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
<cfset pageTitle = "Image Check">
<cfinclude template = "/shared/_header.cfm">
<cfquery name="agent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="agent_result">
	SELECT agent_id 
	FROM agent_name
	WHERE agent_name = 'MCZbase Tools'
</cfquery>

<cfquery name="paths" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="paths_result">
	SELECT distinct auto_path
	FROM media
	WHERE
		media_type = 'image'
		AND auto_host = 'mczbase.mcz.harvard.edu'
		AND (mime_type = 'image/png' OR mime_type = 'image/jpeg')
</cfquery>

<main class="container" id="content">
	<section class="row">
		<h1 class="h2">Check Images for Height/Width</h1>
		<div class="col-12">

			<cfloop query="paths">
				<cfquery name="media" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="media_result">
					SELECT
						auto_path, auto_filename, auto_extension,
						mime_type, media_uri,
						MCZBASE.get_medialabel(media.media_id,'width') as width,
						MCZBASE.get_medialabel(media.media_id,'height') as height
					FROM media
					WHERE
						media_type = 'image'
						AND auto_host = 'mczbase.mcz.harvard.edu'
						AND (mime_type = 'image/png' OR mime_type = 'image/jpeg')
						AND auto_path = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#paths.auto_path#">
				</cfquery>
				<cfset files=media.recordcount>
				<cfset hwadded=0>
				<cfloop query="media">
					<cfif len(width) EQ 0 OR len(height) EQ 0>
						<cftry>
							<cfset somethingadded = 0>
							<cfset info = imageInfo(targetImage)>
							<cfif len(media.width) EQ 0 OR media.width EQ 0 >
								<cfquery name="mediawidth" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="mediawidth_result">
									SELECT label_value 
									FROM media_label
									WHERE
										media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
										AND media_label='width'
								</cfquery>
								<cfif mediawidth.recordcount EQ 0>
									<cfquery name="addmediawidth" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="addmediawidth_result">
										INSERT INTO media_label 
											(media_label,label_value,assigned_by_agent_id) 
										VALUES (
											'width',
											<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#info.width#">,
											<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent.agent_id#">
										)
									</cfquery>
									<cfset somethingadded = 1>
								</cfif>
							</cfif>
							<cfif len(media.height) EQ 0 OR media.height EQ 0 >
								<cfquery name="mediaheight" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="mediaheight_result">
									SELECT label_value 
									FROM media_label
									WHERE
										media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
										AND media_label='height'
								</cfquery>
								<cfif mediaheight.recordcount EQ 0>
									<cfquery name="addmediaheight" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="addmediaheight_result">
										INSERT INTO media_label 
											(media_label,label_value,assigned_by_agent_id) 
										VALUES (
											'height',
											<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#info.height#">,
											<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent.agent_id#">
										)
									</cfquery>
									<cfset somethingadded = 1>
								</cfif>
							</cfif>
							<cfif somethingadded EQ 1>
								<cfset hwadded = hwadded + 1>
							</cfif>
						<cfcatch>
						</cfcatch>
						</cftry>
					</cfif>
					<cfoutput>
						<p>#encodeForHtml(paths.auto_path#: #media.recordcount# files, added height or width to #hwadded#</p>
					</cfoutput>
				</cfloop>
			</cfloop>
		</div>
	</section>
</main>
<cfinclude template = "/shared/_footer.cfm">
