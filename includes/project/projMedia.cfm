<cfinclude template = "/includes/functionLib.cfm">
	<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
		<cfset oneOfUs = 1>
		<cfset isClicky = "likeLink">
	<cfelse>
		<cfset oneOfUs = 0>
		<cfset isClicky = "">
	</cfif>
<cfoutput>
	<cfquery name="media" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	    select distinct
	        media.media_id,
	        media.media_uri,
	        media.mime_type,
	        media.media_type,
	        media.preview_uri
	     from
	         media,
	         media_relations,
	         media_labels
	     where
	         media.media_id=media_relations.media_id and
	         media.media_id=media_labels.media_id (+) and
	         media_relations.media_relationship like '% project' and
	         media_relations.related_primary_key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#project_id#">
	</cfquery>
	<cfif #media.recordcount# gt 0>
    	<h2>Media</h2>
		<div><div class="thumb_spcr">&nbsp;</div>
			<cfloop query="media">
            	<cfquery name="labels"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					select
						media_label,
						label_value
					from
						media_labels
					where
						media_id=#media_id#
						<cfif oneOfUs EQ 0>
							and media_labels.media_label <> 'internal remarks'
						</cfif>
				</cfquery>
				<cfquery name="desc" dbtype="query">
					select label_value from labels where media_label='description'
				</cfquery>
				<cfset alt="Media Preview Image">
				<cfif desc.recordcount is 1>
					<cfset alt=desc.label_value>
				</cfif>
                <cfset mrel=getMediaRelations(#media_id#)>
				<div class="bigThumbDiv">
					<a href="#media_uri#" target="_blank">
						<img class="bigImgPrev" src="#getMediaPreview(preview_uri,media_type)#" alt="#alt#">
					</a>
                   	<div class="imgCaptionDiv">
						#media_type# (#mime_type#)
	               		<br><a href="/media/#media_id#">Media Details</a>
		            	<cfloop query="mrel">
			            	<div class="smallPaddedIndent">
			            		#media_relationship#:
								<cfif len(link) gt 0>
						    		<a href="#link#" target="_blank">#summary#</a>
							    <cfelse>
									#summary#
								</cfif>
							</div>
						</cfloop>
						<cfloop query="labels">
							<div class="indent">#media_label#: #label_value#</div>
						</cfloop>
					</div>
				</div>
			</cfloop>
		<div class="thumb_spcr">&nbsp;</div></div>
	</cfif>
</cfoutput>
