<!---
/media/component/functions.cfc

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

Backing methods for managing media

--->
<cfcomponent>

<cfinclude template = "/shared/functionLib.cfm">


<!--- ** method createMedia creates a new media record. 
  * @param media_uri the media_uri to create, must be unique, will produce error if a media record 
  *  with the provided media_uri exists.
  * @param media_type media type for the media record to create, required.
  * @param mime_type mime type for the record to create, required.
  * other parameters are optional, including an arbitrary number of relationship and label parameter sets.
  ** --->
<cffunction name="createMedia" access="remote" returntype="string" returnformat="plain">
	<cfargument name="media_uri" type="string" required="yes">
	<cfargument name="media_type" type="string" required="yes">
	<cfargument name="mime_type" type="string" required="yes">
	<cfargument name="description" type="string" required="yes">
	<cfargument name="preview_uri" type="string" required="no">
	<cfargument name="media_license_id" type="string" required="no">
	<cfargument name="number_of_relations" type="string" required="no">
	<cfargument name="number_of_labels" type="string" required="no">
	<cfargument name="mask_media_fg" type="string" required="no">

	<cfoutput>
		<cftransaction>
			<cftry>
				<cfquery name="mid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select sq_media_id.nextval nv from dual
				</cfquery>
				<cfset media_id=mid.nv>
				<cfquery name="makeMedia" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					insert into media (
							media_id,
							media_uri,
							mime_type,
							media_type,
							preview_uri,
							mask_media_fg
						 	<cfif len(media_license_id) gt 0>
								,media_license_id
							</cfif>
						) values (
							<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">,
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#media_uri#">,
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#mime_type#">,
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#media_type#">,
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#preview_uri#">
						 	<cfif len(mask_media_fg) gt 0>
								,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#mask_media_fg#">
							<cfelse>
								,0
							</cfif>
							<cfif len(media_license_id) gt 0>
								,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_license_id#">
							</cfif>
						)
				</cfquery>
				<cfquery name="makeDescriptionRelation" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					insert into media_labels (
						media_id,
						media_label,
						label_value
					) values (
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">,
						'description',
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#description#">
					)
				</cfquery>
				<cfloop from="1" to="#number_of_relations#" index="n">
					<cfset thisRelationship = #evaluate("relationship__" & n)#>
					<cfset thisRelatedId = #evaluate("related_id__" & n)#>
					<cfset thisTableName=ListLast(thisRelationship," ")>
					<cfif len(#thisRelationship#) gt 0 and len(#thisRelatedId#) gt 0>
						<cfquery name="makeRelation" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							insert into media_relations (
								media_id,
								media_relationship,
								related_primary_key
							) values (
								<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">,
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#thisRelationship#">,
								<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#thisRelatedId#">
							)
						</cfquery>
					</cfif>
				</cfloop>
				<cfloop from="1" to="#number_of_labels#" index="n">
					<cfset thisLabel = #evaluate("label__" & n)#>
					<cfset thisLabelValue = #evaluate("label_value__" & n)#>
					<cfif len(#thisLabel#) gt 0 and len(#thisLabelValue#) gt 0>
						<cfquery name="makeRelation" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							insert into media_labels (
								media_id,
								media_label,
								label_value
							) values (
								<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">,
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#thisLabel#">,
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#thisLabelValue#">
							)
						</cfquery>
					</cfif>
				</cfloop>
			<cfcatch>
				<cftransaction action="rollback">
				<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ""></cfif>
				<cfset message = trim("Error processing #GetFunctionCalledName()#: " & cfcatch.message & " " & cfcatch.detail & " " & queryError) >
				<cfheader statusCode="500" statusText="#message#">
				<cfoutput>
					<div class="container">
						<div class="row">
							<div class="alert alert-danger" role="alert">
								<img src="/shared/images/Process-stop.png" alt="[ error ]" style="float:left; width: 50px;margin-right: 1em;">
								<cfif cfcatch.detail contains "ORA-00001: unique constraint (MCZBASE.U_MEDIA_URI)" >
									<h2>A media record for that resource already exists in MCZbase.</h2>
								<cfelse>
									<h2>Internal Server Error.</h2>
								</cfif>
								<p>#message#</p>
								<p><a href="/info/bugs.cfm">“Feedback/Report Errors”</a></p>
							</div>
						</div>
					</div>
				</cfoutput>
				<cfabort>
			</cfcatch>
			</cftry>
		</cftransaction>
		<h2>New Media Record Saved</h2>
		<div id='savedLinkDiv'>
			<a href='/media/#media_id#' target='_blank'>Media Details</a>
		</div>
		<cfif len(#thisRelationship#) gt 0 and len(#thisRelatedId#) gt 0>
			<div>Created with relationship: #thisRelationship#</div>
		</cfif>
		<script language='javascript' type='text/javascript'>
			$('##savedLinkDiv').removeClass('ui-widget-content');
		</script>
	</cfoutput>
</cffunction>

<!--- backing for a media autocomplete control --->
<cffunction name="getMediaAutocomplete" access="remote" returntype="any" returnformat="json">
	<cfargument name="term" type="string" required="yes">
	<cfset data = ArrayNew(1)>

	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			select distinct
				media.media_id,
				mime_type,
				media_type,
				substr(media_uri,instr(media_uri,'/',-1)) as filename
				mczbase.get_medialabel(media.media_id,'description') as description
			from 
				media left join media_label on media.media_id = media_label.media_id
			where upper(deacc_number) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(term)#%">
				or media_label.label_value like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#term#%">
			order by media_uri
		</cfquery>
		<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfset row["id"] = "#search.media_id#">
			<cfset row["value"] = "#search.filename#" >
			<cfset row["meta"] = "#search.filename# (#search.mime_type# #search.media_type# #search.description#)" >
			<cfset data[i]  = row>
			<cfset i = i + 1>
		</cfloop>
		<cfreturn #serializeJSON(data)#>
	<cfcatch>
		<cfset error_message = cfcatchToErrorMessage(cfcatch)>
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
	   <cfabort>
	</cfcatch>
	</cftry>
	<cfreturn #serializeJSON(data)#>
</cffunction>
<cffunction name="getMediaBlockHtml" access="remote" returntype="string" returnformat="plain">
	<cfargument name="media_id" type="string" required="yes">
	<cfargument name="size" type="string" required="no" default="600">
	<cfargument name="displayAs" type="string" required="no" default="full">

	<!--- argument scope isn't available within the cfthread, so creating explicit local variables to bring optional arguments into scope within the thread --->
	<cfset l_media_id= #arguments.media_id#>
	<cfset l_displayAs = #arguments.displayAs#>
	<cfset l_size = #arguments.size#>

	<cfthread name="mediaWidgetThread">
		<cfoutput>
			<cftry>
				<cfquery name="media" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="media_result">
					SELECT media_id, 
						preview_uri, media_uri, 
						mime_type, media_type,
						auto_extension as extension,
						auto_host as host,
						CASE WHEN MCZBASE.is_mcz_media(media.media_id) = 1 THEN ctmedia_license.uri ELSE MCZBASE.get_media_dctermsrights(media.media_id) END as license_uri, 
						CASE WHEN MCZBASE.is_mcz_media(media.media_id) = 1 THEN ctmedia_license.display ELSE MCZBASE.get_media_dcrights(media.media_id) END as license_display, 
						MCZBASE.get_media_dcrights(media.media_id) as dc_rights,
						MCZBASE.get_media_credit(media.media_id) as credit,
						MCZBASE.get_media_owner(media.media_id) as owner,
						MCZBASE.get_media_creator(media.media_id) as creator,
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
						media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#l_media_id#">
						AND MCZBASE.is_media_encumbered(media.media_id)  < 1 
				</cfquery>
				<cfif media.recordcount EQ 1>
					<cfloop query="media">
						<cfset isDisplayable = false>
						<cfif media_type EQ 'image' AND (media.mime_type EQ 'image/jpeg' OR media.mime_type EQ 'image/png')>
							<cfset isDisplayable = true>
						</cfif>
						<cfset altEscaped = replace(replace(alt,"'","&##8217;","all"),'"',"&quot;","all") >
						<cfif isDisplayable>
							<cfif #l_displayAs# EQ "thumb">
								<cfset displayImage = preview_uri>
							<cfelse>
								<cfif host EQ "mczbase.mcz.harvard.edu">
									<cfset sizeType='&width=#l_size#&height=#l_size#'>
									<cfset displayImage = "/media/rescaleImage.cfm?media_id=#media.media_id##sizeType#">
								<cfelse>
									<cfset displayImage = media_uri>
								</cfif>
							</cfif>
						<cfelse>
							<!--- pick placeholder --->
							<cfif media_type is "image">
								<cfset displayImage = "/shared/images/noThumbnailImage.png">
							<cfelseif media_type is "audio">
								<cfset displayImage =  "/shared/images/noThumbnailAudio.png">
							<cfelseif media_type IS "audio">
								<cfset displayImage =  "/shared/images/noThumbnailVideo.png">
							<cfelseif media_type is "text">
								<cfset displayImage =  "/shared/images/noThumbDoc.png">
							<cfelseif media_type is "3D model">
								<cfset displayImage =  "/shared/images/3dmodel.png">
							<cfelse>
								<cfset displayImage =  "/shared/images/noThumbnailImage.png"><!---nothing was working for mime type--->
							</cfif>
						</cfif>
						<div class="media_widget" style="width: #l_size#;">	
							<a href="#media.media_uri#" target="_blank" class="d-block my-1 w-100 active" title="click to open full image">
								<img src="#displayImage#" class="mx-auto" alt="#alt#" height="100%" width="100%">
							</a>
							<p class="mt-2 bg-light small caption-lg">
								(<a class="" target="_blank" href="/media/#media_id#">Media Record</a>)
								<cfif NOT isDisplayable>
									#media_type# (#mime_type#)
									(<a class="" target="_blank" href="#media_uri#">media file</a>)
								<cfelse>
									(<a class="" target="_blank" href="/MediaSet.cfm?media_id=#media_id#">zoom/related</a>)
									(<a class="" target="_blank" href="#media_uri#">full</a>)
								</cfif>
							</p>
							<p class="mt-2 bg-light small caption-lg">#title#</p>
							<p class="mt-2 bg-light small caption-lg"><a href="#license_uri#">#license_display#</a></p>
						</div>
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
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="mediaWidgetThread" />
	<cfreturn mediaWidgetThread.output>
</cffunction>

		

</cfcomponent>
