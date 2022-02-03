<cfset pageTitle="Media">
<!--- WARNING: Major work needed.  This is not a redesigned document yet.  See todo notes below --->

<!--- TODO: The old MediaSearch.cfm provides both search results (which should be handled by the media search), and individual media records.  This does not fit the design intent for /media/showMedia.cfm which following redesign conventions would show one and only one media record.  This file needs to be restarted from scratch with a redesign template to show only single media records.  (it should be pretty simple, just header, relevant management links for the user's permission level,  an invocation of getMediaBlockHtml for the single record, and the footer). --->

<!--- TODO: Any api call for more than one image needs to be redirected to either the media search, to show the list of matching images there, or to a new redesigned media gallery which would allow the display of multiple images in larger than thumbnail size along with their metadata --->
<cfinclude template="/shared/_header.cfm">
<script type='text/javascript' src='/shared/js/media.js'></script>
<cfoutput>
<main class="container border-danger" id="content">
	<div class="row">
		<div class="col-12 mt-4 border-success">
		<h1 class="h4 mt-4">Media Record</h1>
			<cfquery name="findIDs" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
					select distinct 
						media.media_id,media.media_uri,media.mime_type,media.media_type,media.preview_uri, 
						CASE WHEN MCZBASE.is_mcz_media(media.media_id) = 1 THEN ctmedia_license.uri ELSE MCZBASE.get_media_dctermsrights(media.media_id) END as uri, 
						CASE WHEN MCZBASE.is_mcz_media(media.media_id) = 1 THEN ctmedia_license.display ELSE MCZBASE.get_media_dcrights(media.media_id) END as display, 
						MCZBASE.is_media_encumbered(media.media_id) hideMedia,
						MCZBASE.get_media_credit(media.media_id) as credit 
					From
						media
					WHERE 
						media.media_id = "1333"

			</cfquery>
			<cfloop query="findIDs" startrow="#URL.offset#" endrow="#limit#">
				<cfquery name="labels_raw"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select
						media_label,
						label_value,
						agent_name
					from
						media_labels
						left join preferred_agent_name on media_labels.assigned_by_agent_id=preferred_agent_name.agent_id
					where
						media_id= <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
						and media_label <> 'credit'
					<cfif oneOfUs EQ 0>
						and media_label <> 'internal remarks'
					</cfif>
				</cfquery>
				<cfquery name="labels" dbtype="query">
					select media_label,label_value 
					from labels_raw 
					where media_label != 'description'
				</cfquery>
				<cfquery name="desc" dbtype="query">
					select label_value 
					from labels_raw 
					where media_label='description'
				</cfquery>
				<cfif isdefined("findIDs.keywords")>
					<cfquery name="kw" dbtype="query">
						select keywords 
						from findIDs 
						where media_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
					</cfquery>
				</cfif>
				<cfset alt="#media_uri#">
				<cfquery name="alt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select mczbase.get_media_descriptor(media_id) media_descriptor from media 
					where media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL"value="#media_id#"> 
				</cfquery> 
				<cfset altText = alt.media_descriptor>
				<cfif desc.recordcount is 1>
					<cfif findIDs.recordcount is 1>
						<cfset title = desc.label_value>
						<cfset metaDesc = "#desc.label_value# for #media_type# (#mime_type#)">
					</cfif>
					<cfset alt=desc.label_value>
				</cfif>
				<div class="row striped">	
				<cfset mp=getMediaPreview(preview_uri,media_type)>
				<div class="row image_metadata"
					<a href="#media_uri#" target="_blank"><img src="#mp#" alt="#altText#" style="max-width:250px;max-height:250px;"></a>
					<span style='font-size:small'>#media_type#&nbsp;(#mime_type#)</span>
					<cfif len(display) gt 0>
						<br><span style='font-size:small'>License: <a href="#uri#" target="_blank" class="external">#display#</a></span>
					<cfelse>
						<br><span style='font-size:small'>unlicensed</span>
					</cfif>
					<cfif #media_type# eq "image">
						<span style='font-size:small'><a href="/MediaSet.cfm?media_id=#media_id#">Related images</a></span>
					</cfif>
					<cfif #media_type# eq "audio">
						<!--- check for a transcript, link if present --->
						<cfquery name="checkForTranscript" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							SELECT
								transcript.media_uri as transcript_uri,
								transcript.media_id as trainscript_media_id
							FROM
								media_relations
								left join media transcript on media_relations.related_primary_key = transcript.media_id
							WHERE
								media_relations.media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL"value="#media_id#"> 
								and media_relationship = 'transcript for audio media'
								and MCZBASE.is_media_encumbered(transcript.media_id) < 1
						</cfquery>
						<cfif checkforTranscript.recordcount GT 0>
							<cfloop query="checkForTranscript">
								<br><span style='font-size:small'><a href="#transcript_uri#">View Transcript</a></span>
							</cfloop>
						</cfif>
					</cfif>
					<cfif len(desc.label_value) gt 0>
						<ul><li>#desc.label_value#</li></ul>
					</cfif>
					<cfif labels.recordcount gt 0>
						<ul>
							<cfloop query="labels">
								<li>
									#media_label#: #label_value#
								</li>
							</cfloop>
							<cfif len(credit) gt 0>
								<li>credit: #credit#</li>
							</cfif>
						</ul>
					</cfif>
					<cfset mrel=getMediaRelations(#media_id#)>
					<cfif mrel.recordcount gt 0>
						<ul>
						<cfloop query="mrel">
							<li>#media_relationship#
								<cfif len(#link#) gt 0>
									<a href="#link#" target="_blank">#link_text#</a>
								<cfelse>
									#link_text#
								</cfif>
							</li>
						</cfloop>
						</ul>
					</cfif>
							<cfif isdefined("kw.keywords") and len(kw.keywords) gt 0>
								<cfif isdefined("keyword") and len(keyword) gt 0>
									<cfset kwds=kw.keywords>
									<cfloop list="#keyword#" index="k" delimiters=",;: ">
										<cfset kwds=highlight(kwds,k)>
									</cfloop>
								<cfelse>
									<cfset kwds=kw.keywords>
								</cfif>
								<div style="font-size:small;max-width:55em;margin-left:0em;margin-top:1em;border:1px solid black;padding:4px;">
									<strong>Keywords:</strong> #kwds#
								</div>
							</cfif>
					</div>
				</div>
				<cfif media_type is "multi-page document">
					<a href="/document.cfm?media_id=#media_id#">[ view as document ]</a>
				</cfif>
				<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_media")>
					<div class="mediaEdit"><a href="/media.cfm?action=edit&media_id=#media_id#">[ edit ]</a>
				</cfif>
				<cfquery name="relM" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select
						media.media_id,
						media.media_type,
						media.mime_type,
						media.preview_uri,
						media.media_uri
					from
						media,
						media_relations
					where
						media.media_id=media_relations.related_primary_key and
						media_relationship like '% media'
						and media_relations.media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
						and media.media_id != <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
					UNION
					select media.media_id, media.media_type,
						media.mime_type, media.preview_uri, media.media_uri
					from media, media_relations
					where
						media.media_id=media_relations.media_id and
						media_relationship like '% media' and
						media_relations.related_primary_key=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
						 and media.media_id != <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
				</cfquery>
				<cfif relM.recordcount gt 0>
					<br>Related Media ()
					<div class="thumbs">
						<div class="thumb_spcr">&nbsp;</div>
						<cfloop query="relM">
							<cfset puri=getMediaPreview(preview_uri,media_type)>
							<cfquery name="labels"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
								select
									media_label,
									label_value
								from
									media_labels
								where
									media_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
							</cfquery>
							<cfquery name="desc" dbtype="query">
								select label_value from labels where media_label='description'
							</cfquery>
							<cfset alt="Media Preview Image">
							<cfif desc.recordcount is 1>
								<cfset alt=desc.label_value>
							</cfif>
							<div class="one_thumb bg-info">
								<a href="#media_uri#" target="_blank"><img src="#getMediaPreview(preview_uri,media_type)#" alt="#altText#" class="theThumb"></a>
								<p>
									#media_type# (#mime_type#)
									<br><a href="/media/#media_id#">Media Details</a>
									<br>#alt#
								</p>
							</div>
						</cfloop>
						<div class="thumb_spcr">&nbsp;</div>
					</div>
				</cfif>
				<cfset rownum=rownum+1>
			</cfloop>
		</div>
	</div>
</main>
</cfoutput>
<cfinclude template="/shared/_footer.cfm">
