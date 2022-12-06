<cfset pageTitle="Media">
<!--- WARNING: Major work needed.  This is not a redesigned document yet.  See todo notes below --->

<!--- TODO: The old MediaSearch.cfm provides both search results (which should be handled by the media search), and individual media records.  This does not fit the design intent for /media/showMedia.cfm which following redesign conventions would show one and only one media record.  This file needs to be restarted from scratch with a redesign template to show only single media records.  (it should be pretty simple, just header, relevant management links for the user's permission level,  an invocation of getMediaBlockHtml for the single record, and the footer). --->

<!--- TODO: Any api call for more than one image needs to be redirected to either the media search, to show the list of matching images there, or to a new redesigned media gallery which would allow the display of multiple images in larger than thumbnail size along with their metadata --->
<cfinclude template="/shared/_header.cfm">
<script type='text/javascript' src='/media/js/media.js'></script>
<cfinclude template="/media/component/search.cfc" runOnce="true">
<cfset maxMedia = 4>
<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
	<cfset oneOfUs = 1>
<cfelse>
	<cfset oneOfUs = 0>
</cfif>
<cfoutput>
<cfquery name="media" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select distinct 
		media.media_id,media.media_uri,media.mime_type,media.media_type,media.preview_uri, 
		MCZBASE.get_media_dctermsrights(media.media_id) as uri, 
		MCZBASE.get_media_dcrights(media.media_id) as display, 
		MCZBASE.is_media_encumbered(media.media_id) hideMedia,
		MCZBASE.get_media_credit(media.media_id) as credit, 
		mczbase.get_media_descriptor(media_id) as alttag,
		MCZBASE.get_media_owner(media.media_id) as owner,
		nvl(MCZBASE.GET_MEDIA_REL_SUMMARY(media_id, 'shows cataloged_item') ||
			MCZBASE.GET_MEDIA_REL_SUMMARY(media_id, 'shows publication') ||
			MCZBASE.GET_MEDIA_REL_SUMMARY(media_id, 'shows collecting_event') ||
			MCZBASE.GET_MEDIA_REL_SUMMARY(media_id, 'shows agent') ||
			MCZBASE.GET_MEDIA_REL_SUMMARY(media_id, 'shows permit') ||
			MCZBASE.GET_MEDIA_REL_SUMMARY(media_id, 'documents borrow') ||
			MCZBASE.GET_MEDIA_REL_SUMMARY(media_id, 'documents loan') ||
			MCZBASE.GET_MEDIA_REL_SUMMARY(media_id, 'shows locality')
			, 'Unrelated image') mrstr
	From
		media
	WHERE 
		media.media_id IN <cfqueryparam cfsqltype="CF_SQL_DECiMAL" value="#media_id#" list="yes">
		AND MCZBASE.is_media_encumbered(media_id)  < 1 
</cfquery>
<cfquery name="spec" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select distinct collection_object_id as pk, guid, typestatus, SCIENTIFIC_NAME name, specimendetailurl, media_relationship
	from media_relations
		left join flat on related_primary_key = collection_object_id
	where media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media.media_id#">
			and media_relations.media_relationship like '%cataloged_item%'
	order by guid
</cfquery>
<cfquery name="permit" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select permit.permit_id, permit.issued_by_agent_id, permit.issued_date, permit.issued_to_agent_id, permit.renewed_date,media_relations.media_id,permit.exp_date,permit.permit_num,permit.permit_type,permit.permit_remarks,permit.contact_agent_id,permit.parent_permit_id,permit.restriction_summary,permit.benefits_provided,permit.specific_type,permit.permit_title
	from permit
		left join media_relations on media_relations.related_primary_key = permit.permit_id
	where media_relations.media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
		and (media_relations.media_relationship = 'shows permit' OR media_relations.media_relationship = 'documents for permit')
</cfquery>
	<cfloop query="media">
		<cfquery name="media_rel" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select distinct
				media_relationship
			From
				media_relations
			WHERE 
				media_id IN <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media.media_id#" list="yes">
				and media_relations.media_relationship <> 'created by agent'
			ORDER BY media_relationship
		</cfquery>
		<div class="container-fluid">
			<div class="row">
				<div class="col-12 pb-4">
					<main class="content">
						<div class="row mx-0">
							<div class="col-12 px-0 px-xl-5 mt-3">
								<h1 class="h2 mt-2 pb-1 mb-2 pb-2 border-bottom border-dark"> Media Record 	
									<button class="btn float-right btn-xs btn-primary" onClick="location.href='/MediaSet.cfm?media_id=#media_id#'">Media Viewer</button>
								</h1>
								<div class="h4 px-0 mt-0">Media ID = media/#media.media_id#</div>
							</div>
							<div class="col-12 px-0 px-xl-5 mt-2 mb-2">
								<cfquery name="labels" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
								SELECT
									media_label,
									label_value,
									agent_name,
									media_label_id 
								FROM
									media_labels
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
								SELECT
									media_keywords.media_id,
									keywords
								FROM
									media_keywords
								WHERE
									media_keywords.media_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
								</cfquery>
								<cfquery name="mediaRelations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
									SELECT source_media.media_id source_media_id, 
										source_media.auto_filename source_filename,
										source_media.media_uri source_media_uri,
										media_relations.media_relationship
									FROM
										media_relations
										left join media source_media on media_relations.media_id = source_media.media_id
									WHERE
										media_relations.related_primary_key=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
								</cfquery>
								<cfquery name="thisguid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" >
									select distinct 'MCZ:'||cataloged_item.collection_cde||':'||cataloged_item.cat_num as specGuid, identification.scientific_name, flat.higher_geog,flat.spec_locality,flat.imageurl
									from media_relations
										left join cataloged_item on media_relations.related_primary_key = cataloged_item.collection_object_id
										left join identification on identification.collection_object_id = cataloged_item.collection_object_id
										left join flat on cataloged_item.collection_object_id = flat.collection_object_id
										left join media media1 on media1.media_id = media_relations.media_id
									where media_relations.media_relations_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
										and (media_relationship = 'shows cataloged_item')
									and identification.accepted_id_fg = 1		
								</cfquery>
								<cfif len(media.media_id) gt 0>
									<div class="rounded border bg-light col-12 col-sm-8 col-md-6 col-xl-3 float-left mb-2 pt-3 pb-0">
										<cfset mediablock= getMediaBlockHtml(media_id="#media_id#",size="400",captionAs="textFull")>
										<div class="mx-auto text-center pt-1" id="mediaBlock#media.media_id#"> #mediablock# </div>
									</div>
								</cfif>
								<div class="float-left col-12 px-0 col-xl-9 pl-xl-4">
									<h3 class="mx-2 h4 mt-0 border-dark w-auto float-left">Metadata</h3>
									<table class="table border-none">
										<thead class="thead-light">
											<tr>
												<th scope="col">Label</th>
												<th scope="col">Value</th>
											</tr>
										</thead>
										<tbody>
											<tr>
												<th scope="row">Media Type:</th><td>#media.media_type#</td>
											</tr>
											<tr>
												<th scope="row">MIME Type:</th><td>#media.mime_type#</td>
											</tr>
											<cfloop query="labels">
												<tr>
													<th scope="row"><span class="text-capitalize">#labels.media_label#</span>:</th><td>#labels.label_value#</td>
												</tr>
											</cfloop>
											<cfif len(credit) gt 0>
												<tr>
													<th scope="row">Credit:</th><td>#credit#</td>
												</tr>
											</cfif>
											<cfif len(owner) gt 0>
												<tr>
													<th scope="row">Copyright:</th><td>#owner#</td>
												</tr>
											</cfif>
											<cfif len(display) gt 0>
												<tr>
													<th scope="row">License:</th><td><a href="#uri#" target="_blank" class="external">#display#</a></td>
												</tr>
											</cfif>
											<cfquery name="relations"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
											select media_relationship as mr_label, MCZBASE.MEDIA_RELATION_SUMMARY(media_relations_id) as mr_value
												from media_relations
											where media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media.media_id#">
												and media_relationship like '%cataloged_item%'
											</cfquery>
											<cfloop query="relations">
												<cfif not (not listcontainsnocase(session.roles,"coldfusion_user") and #mr_label# eq "created by agent")>
													<cfset labellist = "<th scope='row'><span class='text-uppercase'>#mr_label#:</span></th><td> #mr_value#</td>">
												</cfif>
											</cfloop>
											<cfif len(keywords.keywords) gt 0>
											<tr>
												<th scope="row">Keywords: </span></th><td>#keywords.keywords#</td>
											</tr>
											<cfelse>
											</cfif>
											<cfif listcontainsnocase(session.roles,"manage_media")>
											<tr class="border mt-2 p-2">
												<th scope="row">Alt Text:</th><td>#media.alttag#</td>
											</tr>
											</cfif>
											<cfif len(media_rel.media_relationship) gt 0>
												<cfif media_rel.recordcount GT 1>
													<cfset plural = "s">
												<cfelse>
													<cfset plural = "">
												</cfif>
											<tr>
												<th scope="row">Relationship#plural#:&nbsp; </span></th>
												<td>	
													<cfloop query="media_rel">#media_rel.media_relationship#
														<cfif media_rel.media_relationship contains 'cataloged_item'>:
														<cfloop query="spec">
															<cfquery name="relm" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
																select distinct media.media_id, preview_uri, media.media_uri, media.auto_protocol, media.auto_host,
																	MCZBASE.is_media_encumbered(media.media_id) as hideMedia,
																from media_relations
																	 left join media on media_relations.media_id = media.media_id
																	 left join ctmedia_license on media.media_license_id = ctmedia_license.media_license_id
																where related_primary_key = <cfqueryparam value=#spec.pk# CFSQLType="CF_SQL_DECIMAL" >
																	AND MCZBASE.is_media_encumbered(media.media_id)  < 1
															</cfquery> &nbsp;<a class="small90 font-weight-lessbold" href="#relm.auto_protocol#/#relm.auto_host#/guid/#spec.guid#">#spec.guid#</a>
														</cfloop> 
													</cfif>
													<cfif media_rel.recordcount GT 1><span> | </span></cfif>
													</cfloop> 
												</td>
											</tr>
											<cfelse>
											</cfif>
										</tbody>
									</table>
								<!---TO DO  Create external media relationship table for additional renderings and query that for conditional around display--->
									<cfif media.media_uri contains 'slide-atlas' AND media.media_uri contains 'morphosource'>
										<cfset plural = "s">
									<cfelse>
										<cfset plural = "">
									</cfif>
									<cfif media.media_uri contains 'slide-atlas' OR media.media_uri contains 'morphosource'>
										<div class="row my-2">
											<h3 class="h4 px-3 mb-1 pt-0">See additional rendering#plural# </h3>
											<ul class="list-group list-group-horizontal col-12 px-3">
											<cfif media.media_uri contains 'slide-atlas'>
												<li class="list-unstyled col-3 px-0 border bg-light text-center">
													<div id="content">
														<div class="flip-card">
															<div class="flip-card-inner">
																<a href="##" id="flip-card-inner">
																	<div class="flip-card-front">
																		<div class="heightFlip font-weight-lessbold bg-white text-dark"><img src="/images/slideatlas.jpg" class="mx-1" height="35" width="35" alt="slideatlas logo"><span class="h3 font-weight-bold text-black d-inline">Slide Atlas </span>Viewer</div>
																	</div>
																</a>
																<div class="flip-card-back">
																	<a class="link-color px-0 text-center" href="https://images.slide-atlas.org/##item/5915d8d0dd98b578723a09bf">SlideAtlas 
																		<img src="/shared/images/linked_data.png" height="15" width="15" alt="linked data icon">
																	</a>
																	<div class="small">created: 2017-05-12, name: HEC-1606 (free-tailed bat), <br/>2.694 GB, ID: 5915d8d0dd98b578723a09bf</div>
																</div>
															</div>
														</div>
													</div>
												</li>
											</cfif>
											<cfif media.media_uri contains 'morphosource'>
												<li class="list-unstyled col-3 px-0 border bg-light text-center">
													<div id="content">
														<div class="flip-card">
															<div class="flip-card-inner">
																<a href="##" id="flip-card-inner">
																	<div class="flip-card-front">
																		<div class="heightFlip font-weight-lessbold">Morphosource</div>
																	</div>
																</a>
																<div class="flip-card-back">
																	<a class="link-color px-0 text-center" href="http://www.google.com">Morphosource logo </a>
																	<div class="">slide metadata</div>
																</div>
															</div>
														</div>
													</div>
												</li>
											</cfif>
											</ul>
										</div>
									</cfif>
								</div>
							</div>
						</div>
					</main>
				</div>
			
			</div>
				</div>
	</cfloop>
</cfoutput>
<cfinclude template="/shared/_footer.cfm">
