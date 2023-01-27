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
	.viewer {width: auto; height: auto;margin:auto;}
	.viewer img {box-shadow: 8px 2px 20px black;margin-bottom: .5em;}
</style>
	<cfquery name="media" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select distinct 
			media.media_id,media.media_uri,media.mime_type,media.media_type,media.preview_uri, 
			MCZBASE.get_media_dctermsrights(media.media_id) as uri, 
			MCZBASE.get_media_dcrights(media.media_id) as display, 
			MCZBASE.is_media_encumbered(media.media_id) hideMedia,
			MCZBASE.get_media_credit(media.media_id) as credit, 
			MCZBASE.get_media_descriptor(media.media_id) as alttag,
			MCZBASE.get_media_owner(media.media_id) as owner,
			MCZBASE.get_MCZ_PUBS_LINKS(media.media_id) as publinks
		From
			media
		WHERE 
			media.media_id IN <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#" list="yes">
			AND MCZBASE.is_media_encumbered(media_id)  < 1 
	</cfquery>
	<cfquery name = "collid" datasource= "user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select distinct ci.collection_object_id
		from  cataloged_item ci
		left join media_relations mr on ci.collection_object_id = mr.related_primary_key
		left join media m on mr.media_id = m.media_id
		left join mczbase.ctmedia_relationship ct on mr.media_relationship = ct.media_relationship
		where m.media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
		and ct.auto_table = 'cataloged_item'
	</cfquery>
	<cfquery name="spec" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select p.publication_id as pk, ct.media_relationship as wlabel, ct.label as label
		from publication p
		left join media_relations mr on mr.RELATED_PRIMARY_KEY = p.publication_id 
		left join media m on m.media_id = mr.media_id
		left join citation c on c.publication_id = p.publication_id
		left join mczbase.ctmedia_relationship ct on mr.media_relationship = ct.media_relationship
		where c.collection_object_id =<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#collid.collection_object_id#">
		and ct.description = 'publication'
		and ct.description <> 'ledger'
		and m.media_URI not like '%nrs%'
		UNION
		select ci.collection_object_id as pk, ct.auto_table as wlabel, ct.label as label
		from cataloged_item ci
		left join media_relations mr on ci.collection_object_id = mr.related_primary_key
		left join mczbase.ctmedia_relationship ct on mr.media_relationship = ct.media_relationship
		where mr.media_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#media_id#">
		and ct.auto_table = 'cataloged_item'
		UNION
		select ce.collecting_event_id as pk, ct.auto_table as wlabel, ct.label as label
		from media_relations mr
		left join collecting_event ce on mr.related_primary_key = ce.collecting_event_id
		left join mczbase.ctmedia_relationship ct on mr.media_relationship = ct.media_relationship
		where mr.media_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#media_id#">
		and ct.auto_table = 'collecting_event'
		UNION
		select loan.transaction_id as pk, ct.auto_table as wlabel, ct.label as label
		from loan
		left join trans on trans.transaction_id = loan.transaction_id
		left join media_relations mr on loan.transaction_id = mr.related_primary_key
		left join mczbase.ctmedia_relationship ct on mr.media_relationship = ct.media_relationship
		where mr.media_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#media_id#">
		and ct.auto_table = 'loan'
		UNION
		select accn.transaction_id as pk, ct.auto_table as wlabel, ct.label as label
		from accn
		left join trans on trans.transaction_id = accn.transaction_id
		left join media_relations mr on accn.transaction_id = mr.related_primary_key
		left join mczbase.ctmedia_relationship ct on mr.media_relationship = ct.media_relationship
		where mr.media_id= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#media_id#">
		and ct.auto_table = 'accn'
		UNION
		select locality.locality_id as pk, ct.auto_table as wlabel, ct.label as label
		from locality
		left join media_relations mr on locality.locality_id = mr.related_primary_key
		left join mczbase.ctmedia_relationship ct on mr.media_relationship = ct.media_relationship
		where mr.media_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#media_id#">
		and ct.auto_table = 'locality' 
		UNION
		select agent.agent_id as pk, ct.auto_table as wlabel, ct.label as label
		from agent_name an
		left join agent on an.AGENT_name_ID = agent.preferred_agent_name_id
		left join media_relations mr on agent.agent_id = mr.related_primary_key
		left join mczbase.ctmedia_relationship ct on mr.media_relationship = ct.media_relationship
		where mr.media_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#media_id#">
		and an.agent_name_type = 'preferred'
		and ct.auto_table = 'agent'
		and ct.description <> 'ledger'
		and mr.media_relationship <> 'created by agent'
	</cfquery>	
	<main class="container-fluid pb-5" id="content">
		<div class="row">
			<div class="col-12 pb-4 mb-5 pl-md-4">
			<cfloop query="media">
				<cfquery name="media_rel" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT media_relationship 
					FROM media_relations
					WHERE media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media.media_id#">
					and media_relationship <> 'created by agent'
					ORDER BY media_relationship
				</cfquery>
					<div class="row">
						<div class="col-12 my-3">
							<cfif len(media.media_id) gt 0>
								<div id="viewer targetarea" class="viewer rounded highlight_media col-12 col-md-5 col-xl-2 float-left pt-2 my-2 pb-0">
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
							<cfif media_rel.RecordCount gt 0>
								<div class="col-12 px-0 float-left">
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
														<cfif spec.wlabel eq 'shows publication'> 
															<cfquery name="relm" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
															select distinct media.media_id
															from media_relations mr
															left join media on mr.media_id = media.media_id
															left join ctmedia_relationship ct on mr.media_relationship = ct.media_relationship
															where mr.related_primary_key = <cfqueryparam value=#spec.pk# >
															and mr.media_relationship <> 'created by agent'
																and mr.media_relationship = 'shows publication'
															</cfquery>
														<cfelse>
															<cfquery name="relm" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
															select distinct media.media_id
															from media_relations mr
															left join media on mr.media_id = media.media_id
															left join ctmedia_relationship ct on mr.media_relationship = ct.media_relationship
															where mr.related_primary_key = <cfqueryparam value=#spec.pk# >
															and mr.media_relationship <> 'created by agent'
															</cfquery>
														</cfif>
											
													</cfif>
													<cfset i= 1>
													<!---thumbnails added below--->
													<cfif relm.RecordCount gt 0>
													<cfloop query="relm">
														<div class="col-md-4 col-lg-3 col-xl-2 px-1 float-left multizoom thumbs">
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
																			<div class="px-0">
																				<span class="px-2 small90 font-weight-lessbold"> #spec.wlabel# (media/#relm.media_id#)
																				</span> 
																				#mediablock#
																			</div>
																		</div>
																	</li>
																</ul>
															</cfif>
														</div>
														<cfset i=i+1>
													</cfloop>
													</cfif>
													<div id="targetDiv"></div>
												</cfloop>
											</div>
										</div>
									</div>
								</div>
							<cfelse>
								<div class="col-auto px-2 float-left">
									<h3 class="h4 mt-3 w-100 px-4 font-italic">Not related to other media records </h3>
								</div>
							</cfif>
						</div>
					</div>
				</cfloop>
			</div>
		</div>
	</main>
</cfoutput>
	
	
<cfinclude template="/shared/_footer.cfm">
