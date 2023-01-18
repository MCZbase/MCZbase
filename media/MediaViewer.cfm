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
<style>
	.theviewer {width: auto; height: auto;margin:auto;}
	.tviewer img {box-shadow: 8px 2px 20px black;margin-bottom: .5em;}
</style>
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
			media.media_id IN <cfqueryparam cfsqltype="CF_SQL_DECiMAL" value="#media_id#" list="yes">
			AND MCZBASE.is_media_encumbered(media_id)  < 1 
	</cfquery>
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
	<cfquery name="spec" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select distinct collection_object_id as pk, mczbase.ctmedia_relationship.auto_table as tab,mczbase.ctmedia_relationship.media_relationship as rel
		from media_relations
			left join cataloged_item on related_primary_key = collection_object_id
			left join mczbase.ctmedia_relationship on mczbase.ctmedia_relationship.media_relationship = media_relations.media_relationship
		where media_relations.media_id = <cfqueryparam cfsqltype="CF_SQL_DECiMAL" value="#media_id#">
		and #media_rel.auto_table# = mczbase.ctmedia_relationship.auto_table
	</cfquery>
	<cfquery name="agents" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select agent_name.agent_name, mczbase.ctmedia_relationship.auto_table as tab,mczbase.ctmedia_relationship.media_relationship as rel
		from media_relations
			left join agent on media_relations.related_primary_key = agent.agent_id
			left join agent_name on agent_name.agent_id = agent.agent_id
			left join mczbase.ctmedia_relationship on mczbase.ctmedia_relationship.media_relationship = media_relations.media_relationship
		where media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media.media_id#">
			and mczbase.ctmedia_relationship.auto_table = 'agent'
			and agent_name_type = 'preferred'
			and media_relations.media_relationship <> 'created by agent'
		order by agent_name.agent_name
	</cfquery>
	<cfquery name="coll" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select distinct collecting_event_id as pk, mczbase.ctmedia_relationship.auto_table as tab,mczbase.ctmedia_relationship.media_relationship as rel
		from media_relations
			left join collecting_event on related_primary_key = collecting_event_id
			left join mczbase.ctmedia_relationship on mczbase.ctmedia_relationship.media_relationship = media_relations.media_relationship
		where media_relations.media_id = <cfqueryparam cfsqltype="CF_SQL_DECiMAL" value="#media_id#">
		and mczbase.ctmedia_relationship.auto_table = 'collecting_event'
	</cfquery>

	<main class="container-fluid pb-5" id="content">
		<div class="row">
			<div class="col-12 pb-4 mb-5 pl-md-4">
			<cfloop query="media">
				<div class="row">
					<div class="col-12 my-3">
						<cfif len(media.media_id) gt 0>
							<div id="viewer targetarea" class="theviewer rounded highlight_media col-12 col-md-5 col-xl-2 float-left pt-2 my-2 pb-0">
								<cfset mediablock= getMediaBlockHtml(media_id="#media_id#",size="300",captionAs="textLinks")>
								<div class="mx-auto text-center h3 pt-1" id="mediaBlock#media.media_id#"> 
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
						<!---specimen records relationships and other possible associations to media on those records--->
							<cfif len(media_rel.media_relationship) gt 0>
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
										<cfloop query="media_rel">
											<cfif len(media.media_id) gt 0>
												<cfif media_rel.auto_table eq 'agent'>
													<cfloop query="agents">
														<cfquery name="relm" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
															select distinct m.media_id
															from agent_name an 
															left join media_relations m on an.agent_id=m.related_primary_key 
															left join mczbase.ctmedia_relationship ct on ct.media_relationship = m.media_relationship
															where an.agent_name=<cfqueryparam cfsqltype="cf_sql_varchar" value="#agents.agent_name#" /> 
															and ct.media_relationship <> 'created by agent'
															and ct.auto_table = 'agent'
														</cfquery>
													</cfloop>
												<cfelseif media_rel.auto_table eq 'collecting_event'>
													<cfloop query="spec">
														<cfif len(spec.pk) gt 0>
														<cfquery name="relm" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
															select distinct media.media_id, mczbase.ctmedia_relationship.media_relationship as rel
															from media_relations 
															left join media on media_relations.media_id = media.media_id 
															left join mczbase.ctmedia_relationship on mczbase.ctmedia_relationship.media_relationship = media_relations.media_relationship
															where media_relations.related_primary_key = <cfqueryparam value=#spec.pk# >					
														</cfquery>
														</cfif>
													</cfloop>
												<cfelse>
													<cfloop query="coll">
														<cfif len(spec.pk) gt 0>
														<cfquery name="relm" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
															select distinct media.media_id, mczbase.ctmedia_relationship.media_relationship as rel
															from media_relations 
															left join media on media_relations.media_id = media.media_id 
															left join mczbase.ctmedia_relationship on mczbase.ctmedia_relationship.media_relationship = media_relations.media_relationship
															where media_relations.related_primary_key = <cfqueryparam value=#coll.pk# >					
														</cfquery>
														</cfif>
													</cfloop>
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
																	<div class="px-0"><span class="px-2 smaller">media/#relm.media_id#: #media_rel.media_relationship# </span> #mediablock#</div>
																</div>
																</li>
															</ul>
														</cfif>
													</div>
													<cfset i=i+1>
												</cfloop>
												<div id="targetDiv"></div>
												
											</cfif>
										</cfloop>
											</div>
										</div>
									</div>
								</div>
							<cfelse>
								<div class="col-auto px-2 float-left">
									<h3 class="h4 mt-3 w-100 px-4 font-italic">Related media records not displayed. Click related media IDs above to see.</h3>
								</div>
							</cfif>
					</div>
				</div>
			</cfloop>
			</div>
			</div>
		</div>
	</main>
</cfoutput>
	
	
<cfinclude template="/shared/_footer.cfm">
