<cfset pageTitle="Media Viewer">

<cfinclude template="/shared/_header.cfm">
<script type='text/javascript' src='/media/js/media.js'></script>

<cfinclude template="/media/component/search.cfc" runOnce="true">
<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
	<cfset oneOfUs = 1>
<cfelse>
	<cfset oneOfUs = 0>
</cfif>
<cfset maxMedia = 8>
<cfoutput>

	<cfquery name="media" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select distinct 
			media.media_id,media.media_uri,media.mime_type,media.media_type,media.preview_uri, 
			MCZBASE.get_media_dctermsrights(media.media_id) as uri, 
			MCZBASE.get_media_dcrights(media.media_id) as display, 
			MCZBASE.is_media_encumbered(media.media_id) hideMedia,
			MCZBASE.get_media_credit(media.media_id) as credit, 
			MCZBASE.get_media_descriptor(media.media_id) as alttag,
			MCZBASE.get_media_owner(media.media_id) as owner
		From
			media
		WHERE 
			media.media_id IN <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#" list="yes">
			AND MCZBASE.is_media_encumbered(media_id)  < 1 
	</cfquery>
	<cfquery name="spec" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select citation.collection_object_id "PK", flat.guid as wlabel 
		from <cfif ucase(session.flatTableName) EQ "FLAT"> flat <cfelse> filtered_flat </cfif> flat
		left join citation on citation.collection_object_id = flat.collection_object_id 
		left join publication on publication.publication_id = citation.publication_id 
		left join media_relations on media_relations.RELATED_PRIMARY_KEY = publication.publication_id 
		left join mczbase.ctmedia_relationship on mczbase.ctmedia_relationship.media_relationship = media_relations.media_relationship 
		left join media on media.media_id = media_relations.media_id
		left join formatted_publication on formatted_publication.publication_id = publication.publication_id 
		where media.media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
		and formatted_publication.format_style='short' 
		and media.media_uri is not null 
		and mczbase.ctmedia_relationship.auto_table = 'cataloged_item'
		UNION
		select flat.collection_object_id "PK", flat.guid as wlabel
		from <cfif ucase(session.flatTableName) EQ "FLAT"> flat <cfelse> filtered_flat </cfif> flat
		left join media_relations on flat.collection_object_id =media_relations.related_primary_key
		left join mczbase.ctmedia_relationship on mczbase.ctmedia_relationship.media_relationship = media_relations.media_relationship
		left join media on media_relations.media_id = media.media_id
		where media.media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
		and mczbase.ctmedia_relationship.auto_table = 'cataloged_item'
		UNION
		(select collecting_event_id as pk, collecting_event.verbatim_locality as wlabel
		from media_relations
			left join collecting_event on related_primary_key = collecting_event_id
			left join mczbase.ctmedia_relationship on mczbase.ctmedia_relationship.media_relationship = media_relations.media_relationship
		 left join media on media_relations.media_id = media.media_id
		where media.media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
		and mczbase.ctmedia_relationship.auto_table = 'collecting_event'
		UNION
		select citation.publication_id as pk, formatted_publication.formatted_publication as wlabel
		from publication
		left join citation on publication.publication_id = citation.publication_id
		left join media_relations on media_relations.RELATED_PRIMARY_KEY = publication.PUBLICATION_ID
		left join formatted_publication on formatted_publication.publication_id = publication.publication_id
		left join mczbase.ctmedia_relationship on mczbase.ctmedia_relationship.media_relationship = media_relations.media_relationship
		left join media on media_relations.media_id = media.media_id
		where formatted_publication.format_style = 'short'
		and media.media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
		UNION
		select loan.transaction_id as pk, loan.loan_number as wlabel
		from loan
		left join trans on trans.transaction_id = loan.transaction_id
		left join media_relations on loan.transaction_id = media_relations.related_primary_key
		left join mczbase.ctmedia_relationship on mczbase.ctmedia_relationship.media_relationship = media_relations.media_relationship
		left join media on media_relations.media_id = media.media_id
		where media.media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
		UNION
		select locality.locality_id as pk, locality.spec_locality as wlabel
		from locality
		left join media_relations on locality.locality_id = media_relations.related_primary_key
		left join mczbase.ctmedia_relationship on mczbase.ctmedia_relationship.media_relationship = media_relations.media_relationship
		left join media on media_relations.media_id = media.media_id
		where media.media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
		and media_relations.MEDIA_RELATIONSHIP = 'shows locality'
		UNION
		select agent.agent_id as pk, agent_name.agent_name as wlabel
		from agent_name
		left join agent on agent_name.AGENT_ID = agent.agent_id
		left join media_relations on agent_name.agent_id = media_relations.related_primary_key
		left join mczbase.ctmedia_relationship on mczbase.ctmedia_relationship.media_relationship = media_relations.media_relationship
		left join media on media_relations.media_id = media.media_id
		where media.media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
		and mczbase.ctmedia_relationship.media_relationship = 'shows agent'
		and agent_name.agent_name_type = 'preferred'
		and media_relations.media_relationship <> 'created by agent'
		</cfquery>

<style>
.viewer {width: auto; height: auto;margin:auto;}
.viewer img {box-shadow: 8px 2px 20px black;margin-bottom: .5em;}
</style>
	<main class="container-fluid pb-5" id="content">
		<div class="row">
			<div class="col-12 pb-4 mb-5 pl-md-4">
<!---	LOOP---><cfloop query="media">
					<cfquery name="media_rel" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select distinct
						mr.media_relationship, ct.label, ct.auto_table, ct.description
					From
						media_relations mr, ctmedia_relationship ct
					WHERE 
						mr.media_relationship = ct.media_relationship 
					and
						mr.media_id IN <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media.media_id#" list="yes">
					and mr.media_relationship <> 'created by agent'
					ORDER BY mr.media_relationship
					</cfquery>
					<div class="row">
						<div class="col-12 my-3">
							<cfif len(media.media_id) gt 0>
								<div id="viewer targetarea" class="rounded highlight_media col-12 col-md-5 col-xl-2 float-left pt-2 my-2 pb-0">
									<cfset mediablock= getMediaBlockHtml(media_id="#media_id#",size="300",captionAs="textLinks")>
									<div class="viewer mx-auto text-center h3 pt-1" id="mediaBlock#media.media_id#"> 
										#mediablock# 
									</div>
									<h1 class="h2 mb-1 mt-0 col-12 float-left text-center">Media Viewer</h1>
									<p class="small90">Place cursor in top left corner of media and zoom in with mousewheel to see a larger version of the image. Pan to see different parts of image. </p>
								</div>
							</cfif>
							<div id="metadatatable" class="col-12 col-md-7 col-xl-10 float-left my-2 pt-0 pb-0">
								<cfset mediaMetadataBlock= getMediaMetadata(media_id="#media_id#")>
								<div id="mediaMetadataBlock#media_id#">
									#mediaMetadataBlock#
								</div>
							</div>
					<!---	specimen records relationships and other possible associations to media on those records--->
						<!---	<cfloop query = 'media_rel'>--->
						
								<div class="col-12 col-xl-12 px-0 float-left">
									<div class="search-box mt-2 w-100 mb-3">
										<div class="search-box-header px-2 mt-0 mediaTableHeader">
											<ul class="list-group list-group-horizontal text-white">
												<li class="col-12 px-1 list-group-item mb-0 h4 font-weight-lessbold">
													Related Media Records 
												</li>
											</ul>
										</div>
										<div class="row mx-0">
											<div class="col-12 p-1">
												<cfloop query="spec">
													<cfif len(spec.pk) gt 0>
														<cfquery name="relm" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
															select distinct media.media_id, mczbase.ctmedia_relationship.media_relationship as rel, label
															from media_relations 
															left join media on media_relations.media_id = media.media_id 
															left join mczbase.ctmedia_relationship on mczbase.ctmedia_relationship.media_relationship = media_relations.media_relationship
															where media_relations.related_primary_key = <cfqueryparam value=#spec.pk# >
														</cfquery>
													</cfif>
													<cfset i= 1>
													<!---thumbnails added below--->
													<cfloop query="relm">
														<div class="col-md-4 col-lg-3 col-xl-2 px-1 float-left">
															<cfif len(media.media_id) gt 0>
																<cfif relm.media_id eq '#media.media_id#'> 
																	<cfset activeimg = "highlight_media rounded px-1 pt-1">
																<cfelse>	
																	<cfset activeimg = "border-wide-ltgrey rounded bg-white px-1 py-1">
																</cfif>
																<ul class="list-group px-0">
																	<li class="list-group-item px-0 mx-1">
																	<cfset mediablock= getMediaBlockHtml(media_id="#relm.media_id#",displayAs="thumb",size='70',captionAs="textCaptionFull")>
																	<div class="#activeimg# image#i#" id="mediaBlock#relm.media_id#"  style="height: 200px;">
																		<div class="px-0"><span class="px-2 small90">media/#relm.media_id#: #spec.rel# </span> #mediablock#</div>
																	</div>
																	</li>
																</ul>
															</cfif>
														</div>
														<div id="targetDiv"></div>
														<cfset i=i+1>
													</cfloop>
												</cfloop>
											</div>
										</div>
									</div>
								</div>
<!---							<cfelse>
								<div class="col-auto px-2 float-left">
									<h3 class="h4 mt-3 w-100 px-4 font-italic">Related media records not displayed. Click related media IDs above to see.</h3>
								</div>--->
						
							<!---</cfloop>--->
						</div>
					</div>
				</cfloop>
			</div>
		</div>
	</main>
</cfoutput>
	
	
<cfinclude template="/shared/_footer.cfm">
