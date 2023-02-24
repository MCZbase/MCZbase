<cfset pageTitle="Related Media">

<cfinclude template="/shared/_header.cfm">
<script type='text/javascript' src='/media/js/media.js'></script>

<cfinclude template="/media/component/public.cfc" runOnce="true">
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
			MCZBASE.get_media_owner(media.media_id) as owner,
			MCZBASE.get_MCZ_PUBS_LINKS(media.media_id) as publinks
		From
			media
		WHERE 
			media.media_id IN <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#" list="yes">
			AND MCZBASE.is_media_encumbered(media_id)  < 1 
	</cfquery>

	<cfquery name="pub" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select distinct p.publication_id as pk, ct.media_relationship as rel, ct.label as label, ct.auto_table as at
		from publication p
		left join media_relations mr on mr.related_primary_key = p.publication_id 
		left join mczbase.ctmedia_relationship ct on mr.media_relationship = ct.media_relationship
		where mr.media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
		and ct.auto_table = 'publication'
	</cfquery>
	

	<cfquery name="spec" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		<cfif pub.recordcount gt 0>
		select distinct c.collection_object_id as pk, cmr.media_relationship as rel, 'Cited Specimen' as label, ct.auto_table as at
		from media_relations cmr 
		join cataloged_item ci on cmr.related_primary_key = ci.collection_object_id 
		and cmr.media_relationship = 'shows cataloged_item'
		join citation c on c.collection_object_id = ci.collection_object_id
		join publication p on p.publication_id = c.publication_id
		and p.publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#pub.pk#">
		left join media_relations mr on mr.related_primary_key = p.publication_id 
		left join mczbase.ctmedia_relationship ct on mr.media_relationship = ct.media_relationship
		where ct.auto_table = 'publication'
		UNION
		</cfif>
		select distinct  ci.collection_object_id as pk, ct.media_relationship as rel, ct.label as label, ct.auto_table as at
		from cataloged_item ci
		left join media_relations mr on ci.collection_object_id = mr.related_primary_key
		left join mczbase.ctmedia_relationship ct on mr.media_relationship = ct.media_relationship
		where mr.media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
		and ct.media_relationship = 'shows cataloged_item'
		UNION
		select distinct  ci.collection_object_id as pk, ct.media_relationship as rel, ct.label as label, ct.auto_table as at
		from cataloged_item ci
		left join media_relations mr on ci.collection_object_id = mr.related_primary_key
		left join mczbase.ctmedia_relationship ct on mr.media_relationship = ct.media_relationship
		where mr.media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
		and ct.media_relationship = 'ledger entry for cataloged_item'
		UNION
		select distinct ce.collecting_event_id as pk, ct.media_relationship as rel, ct.label as label, ct.auto_table as at
		from media_relations mr
		left join collecting_event ce on mr.related_primary_key = ce.collecting_event_id
		left join mczbase.ctmedia_relationship ct on mr.media_relationship = ct.media_relationship
		where mr.media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
		and ct.auto_table = 'collecting_event'
		UNION
		select distinct loan.transaction_id as pk, ct.media_relationship as rel, ct.label as label, ct.auto_table as at
		from loan
		left join trans on trans.transaction_id = loan.transaction_id
		left join media_relations mr on loan.transaction_id = mr.related_primary_key
		left join mczbase.ctmedia_relationship ct on mr.media_relationship = ct.media_relationship
		where mr.media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
		and ct.auto_table = 'loan'
		UNION
		select distinct accn.transaction_id as pk, ct.media_relationship as rel, ct.label as label, ct.auto_table as at
		from accn
		left join trans on trans.transaction_id = accn.transaction_id
		left join media_relations mr on accn.transaction_id = mr.related_primary_key
		left join mczbase.ctmedia_relationship ct on mr.media_relationship = ct.media_relationship
		where mr.media_id= <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
		and ct.auto_table = 'accn'
		UNION
		select distinct deaccession.transaction_id as pk, ct.media_relationship as rel, ct.label as label, ct.auto_table as at
		from deaccession
		left join trans on trans.transaction_id = deaccession.transaction_id
		left join media_relations mr on deaccession.transaction_id = mr.related_primary_key
		left join mczbase.ctmedia_relationship ct on mr.media_relationship = ct.media_relationship
		where mr.media_id= <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
		and ct.auto_table = 'deaccession'
		UNION
		select distinct borrow.transaction_id as pk, ct.media_relationship as rel, ct.label as label, ct.auto_table as at
		from borrow
		left join trans on trans.transaction_id = borrow.transaction_id
		left join media_relations mr on borrow.transaction_id = mr.related_primary_key
		left join mczbase.ctmedia_relationship ct on mr.media_relationship = ct.media_relationship
		where mr.media_id= <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
		and ct.auto_table = 'borrow'
		UNION
		select distinct m.media_id as pk, m.media_uri as rel, ct.label as label, ct.auto_table as at
		from media_relations mr
		left join media m on m.media_id = mr.media_id
		left join mczbase.ctmedia_relationship ct on mr.media_relationship = ct.media_relationship
		where m.media_id= <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
		and ct.auto_table = 'media'
		UNION
		select distinct permit.permit_id as pk, ct.media_relationship as rel, ct.label as label, ct.auto_table as at
		from permit
		left join media_relations mr on permit.permit_id = mr.related_primary_key
		left join mczbase.ctmedia_relationship ct on mr.media_relationship = ct.media_relationship
		where mr.media_id= <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
		and ct.auto_table = 'permit'
		UNION
		select distinct project.project_id as pk, ct.media_relationship as rel, ct.label as label, ct.auto_table as at
		from project
		left join media_relations mr on project.project_id = mr.related_primary_key
		left join mczbase.ctmedia_relationship ct on mr.media_relationship = ct.media_relationship
		where mr.media_id= <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
		and ct.auto_table = 'project'
		UNION
		select distinct specimen_part.collection_object_id as pk, ct.media_relationship as rel, ct.label as label, ct.auto_table as at
		from specimen_part
		left join media_relations mr on specimen_part.collection_object_id = mr.related_primary_key
		left join mczbase.ctmedia_relationship ct on mr.media_relationship = ct.media_relationship
		where mr.media_id= <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
		and ct.auto_table = 'specimen_part'
		UNION
		select distinct mr.media_id as pk, ct.media_relationship as rel, ct.label as label, ct.auto_table as at
		from mczbase.ctmedia_relationship ct
		left join media_relations mr on mr.media_relationship = ct.media_relationship
		where mr.media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
		and ct.media_relationship like '%media' 
		UNION
		select distinct locality.locality_id as pk, ct.media_relationship as rel, ct.label as label, ct.auto_table as at
		from locality
		left join media_relations mr on locality.locality_id = mr.related_primary_key
		left join mczbase.ctmedia_relationship ct on mr.media_relationship = ct.media_relationship
		where mr.media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
		and ct.auto_table = 'locality' 
		UNION
		select distinct pan.agent_id as pk, ct.media_relationship as rel, ct.label as label, ct.auto_table as at
		from preferred_agent_name pan
		left join media_relations mr on pan.agent_id = mr.related_primary_key
		left join mczbase.ctmedia_relationship ct on mr.media_relationship = ct.media_relationship
		where mr.media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
		and mr.media_relationship <> 'created by agent'
		and ct.media_relationship like '% agent'  

	</cfquery>
	<main class="container-fluid pb-5" id="content">
		<div class="row">
			<div class="col-12 pb-4 mb-5 pl-md-4">
				<cfloop query="media">
					<div class="row">
						<div class="col-12 my-3">
							<h1 class="h3 px-4 mb-0">Media Related to:</h1>
							<cfif len(media.media_id) gt 0>
								<div class="col-12 col-md-5 col-xl-2 pt-0 pb-2 float-left">
									<div id="zoom" class="rounded highlight_media float-left pt-2 px-2 mt-3 mb-0 pb-1">
										<cfset mediablock= getMediaBlockHtml(media_id="#media_id#",size="300",captionAs="textCaptionLong")>
										<div class="mx-auto text-center h4 mb-0 pb-1 pt-1" id="mediaBlock#media.media_id#"> 
											#mediablock# 
										</div>
										<cfif media.media_type eq 'image'>
											<div class="col-11 float-right mr-4"> 
												<button class="btn btn-xs btn-dark help-btn border-0" style="right: -31px; top:-17px;transform:none; z-index: 500;" type="button" data-toggle="collapse" data-target="##collapseFixed" aria-expanded="false" aria-controls="collapseFixed">
													Zoom
												</button>
												<aside class="collapse collapseStyle mt-0 border-warning rounded border-top border-right border-bottom border-left" id="collapseFixed" style="z-index: 5;">
													<div class="card card-body p-3">
														<h3 class="h5 mb-1">Media Zoom </h3>
														<p class="d-none d-md-block mb-0 small85 line90">Hover over the image to show a larger version at zoom level 2. Place cursor in top left corner of media and zoom in with mousewheel or touchpad to see a larger version of the image (up to zoom level 10).  Click on different parts of image if it goes beyond your screen size. Use the related link on media below to switch images.</p><p class="d-block d-md-none mb-0 small85 line90"> Tap the image and swipe left to see larger version. Place two fingers on the touchpad and pinch in or stretch out to zoom in on the image. Tap area off the image to close.  </p>
													</div>
												</aside>
											</div>
										</cfif>
									</div>
								</div>
							</cfif>
							<div id="metadatatable" class="col-12 col-md-7 col-xl-10 float-left my-0 pt-3 pb-0">
								<cfset mediaMetadataBlock= getMediaMetadata(media_id="#media_id#")>
								<div id="mediaMetadataBlock#media_id#">
									#mediaMetadataBlock#
								</div>
							</div>	#spec.pk#
							<cfif spec.recordcount gt 0> 
								<cfquery name="media_rel" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
									select distinct mr.media_relationship
									from media_relations mr
									left join mczbase.ctmedia_relationship ct on mr.media_relationship = ct.media_relationship
									where mr.media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
									and mr.related_primary_key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#spec.pk#">
								</cfquery>
								<!---specimen records relationships and other possible associations to media on those records--->
								<div class="col-12 px-0 float-left">
									<div class="search-box mt-3 w-100 mb-3">
										<div class="search-box-header px-2 mt-0 mediaTableHeader">
											<ul class="list-group list-group-horizontal text-white">
												<li class="col-12 px-1 list-group-item mb-0 h4 font-weight-lessbold comma2">
													Related Media Records 
												</li>
											</ul>
										</div>
										
										<div class="row mx-0">
											<div class="col-12 p-1">
												<cfif media_rel.recordcount gt 0>
													<!---If media relations are show or document cataloged_item, accn, ledger, deaccession, etc.--->
													<cfloop query="spec">
														<cfquery name="relm" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
															select distinct <cfif spec.at neq 'media'>m.media_id<cfelse>mr.related_primary_key</cfif></cfif>,ct.media_relationship,ct.label
														from media_relations mr 
														left join media m on mr.media_id = m.media_id
														left join mczbase.ctmedia_relationship ct on mr.media_relationship = ct.media_relationship
														where mr.related_primary_key = <cfqueryparam  value="#spec.pk#">
														<cfif spec.at neq 'media'>and m.media_id <> <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media.media_id#"></cfif>
														and mr.media_relationship <> 'created by agent'
														and MCZBASE.is_media_encumbered(m.media_id)  < 1 
														<cfif spec.pk gt 1 and spec.label neq 'Shows Cataloged Item'>and ct.media_relationship <> 'ledger entry for cataloged_item'</cfif>
														</cfquery>
														<!---Some of the ledgers have the same primary key as the agent_ids. I haven't found it on other types of relationships. We may need a different fix if it is more widespread.--->
														<cfif relm.recordcount gt 0>
															<cfset i = 1>
															<cfloop query="relm">
																<div class="col-md-4 col-lg-3 col-xl-2 px-1 float-left multizoom thumbs">
																	<ul class="list-group px-0">
																		<li class="list-group-item px-0 mx-1">
																			<cfset mediablock= getMediaBlockHtml(media_id="#relm.media_id#",displayAs="thumb",size='70',captionAs="textCaptionLong")>
																			<div class="border-wide-ltgrey rounded bg-white px-1 py-1 image#i#" id="mediaBlock#relm.media_id#" style="height:250px;">
																				<div class="px-0">
																					<span class="px-2 d-block mt-1 small90 font-weight-lessbold text-center">
																						#relm.label# 
																					<cfif spec.at eq 'cataloged_item' and relm.recordcount gt 0>
																						<cfquery name="guidi" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
																						select guid from <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat, media_relations mr where mr.related_primary_key = flat.collection_object_id and mr.related_primary_key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#spec.pk#" >
																						</cfquery>
																						#guidi.guid#
																					<cfelse>
																					#spec.pk#
																					</cfif>
																					<br>(media/#relm.media_id#)
																					</span> 
																					#mediablock#
																				</div>
																			</div>
																		</li>
																	</ul>
																</div>
																<cfset i=i+1>
															</cfloop>
														<cfelse>
															<h3 class="h4 px-2 ml-1 pt-2">#relm.media_id#</h3>
														</cfif>
													</cfloop>
												<cfelse>
													<h3 class="h4 px-2 ml-1 pt-2 onlyfirst"><span class="one">No Relationships to Other Records</span></h3>
												</cfif>
											</div>
										</div>
									</div>
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
