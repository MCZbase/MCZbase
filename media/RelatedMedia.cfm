<!---
media/RelatedMedia.cfm

Show gallery of media related to a specifed media object.

Copyright 2023 President and Fellows of Harvard College

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
<cfif not isdefined('media_id') OR  len(media_id) EQ 0>
	<!--- redirect to media search page --->
	<cflocation url="/media/findMedia.cfm">
</cfif>

<cfset pageTitle="Related Media">
<cfinclude template="/shared/_header.cfm">

<script type='text/javascript' src='/media/js/media.js'></script>

<cfinclude template="/media/component/public.cfc" runOnce="true">
<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
	<cfset oneOfUs = 1>
<cfelse>
	<cfset oneOfUs = 0>
</cfif>
<cfoutput>
	<cfquery name="media" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
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
	<cfif media.recordcount EQ 0>
		<cfthrow message="Media record with media_id=[#encodeForHtml(media_id)#] not found.">
	</cfif>
	<!--- query to get a publication_id based on the media_id if the media record shows publication.
			The publication_id is fed to the getRelatedThings query to get the collection_object_id (i.e., citation) 
	--->
	<cfquery name="pub" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
		select distinct p.publication_id as pk, ct.media_relationship as rel, ct.label as label, ct.auto_table as at
		from publication p
		left join media_relations mr on mr.related_primary_key = p.publication_id 
		left join mczbase.ctmedia_relationship ct on mr.media_relationship = ct.media_relationship
		where mr.media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
		and ct.auto_table = 'publication'
	</cfquery>
	<cfquery name="getRelatedThings" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getRelatedThings_result" timeout="#Application.query_timeout#">
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
		and ct.media_relationship = 'documents cataloged_item'
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
		<cfif oneOfUs eq 1 and listcontainsnocase(session.roles,"manage_transactions")>
		select distinct loan.transaction_id as pk, ct.media_relationship as rel, ct.label as label, ct.auto_table as at
		from loan
		left join trans on trans.transaction_id = loan.transaction_id
		left join media_relations mr on loan.transaction_id = mr.related_primary_key
		left join mczbase.ctmedia_relationship ct on mr.media_relationship = ct.media_relationship
		where mr.media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
		and ct.auto_table = 'loan'
		UNION
		</cfif>
		<cfif oneOfUs eq 1 and listcontainsnocase(session.roles,"manage_transactions")>
		select distinct accn.transaction_id as pk, ct.media_relationship as rel, ct.label as label, ct.auto_table as at
		from accn
		left join trans on trans.transaction_id = accn.transaction_id
		left join media_relations mr on accn.transaction_id = mr.related_primary_key
		left join mczbase.ctmedia_relationship ct on mr.media_relationship = ct.media_relationship
		where mr.media_id= <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
		and ct.auto_table = 'accn'
		UNION
		</cfif>
		<cfif oneOfUs eq 1 and listcontainsnocase(session.roles,"manage_transactions")>
		select distinct deaccession.transaction_id as pk, ct.media_relationship as rel, ct.label as label, ct.auto_table as at
		from deaccession
		left join trans on trans.transaction_id = deaccession.transaction_id
		left join media_relations mr on deaccession.transaction_id = mr.related_primary_key
		left join mczbase.ctmedia_relationship ct on mr.media_relationship = ct.media_relationship
		where mr.media_id= <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
		and ct.auto_table = 'deaccession'
		UNION
		</cfif>
		<cfif oneOfUs eq 1 and listcontainsnocase(session.roles,"manage_transactions")>
		select distinct borrow.transaction_id as pk, ct.media_relationship as rel, ct.label as label, ct.auto_table as at
		from borrow
		left join trans on trans.transaction_id = borrow.transaction_id
		left join media_relations mr on borrow.transaction_id = mr.related_primary_key
		left join mczbase.ctmedia_relationship ct on mr.media_relationship = ct.media_relationship
		where mr.media_id= <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
		and ct.auto_table = 'borrow'
		UNION
		</cfif>
		select distinct mr.related_primary_key as pk, m.media_uri as rel, ct.label as label, ct.auto_table as at
		from media_relations mr
		join media m on m.media_id = mr.media_id
		join mczbase.ctmedia_relationship ct on mr.media_relationship = ct.media_relationship
		where m.media_id= <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
		and ct.auto_table = 'media'
		UNION
		select distinct m.media_id as pk, ct.media_relationship as rel, ct.label as label, ct.auto_table as at
		from media_relations mr
		join media m on m.media_id = mr.media_id
		join mczbase.ctmedia_relationship ct on mr.media_relationship = ct.media_relationship
		where mr.related_primary_key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
		and ct.media_relationship like '%media'
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
		select distinct mr.related_primary_key as pk, ct.media_relationship as rel, ct.label as label, ct.auto_table as at
		from media_relations mr
		join media m on m.media_id = mr.media_id
		join mczbase.ctmedia_relationship ct on mr.media_relationship = ct.media_relationship
		where m.media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
		and ct.media_relationship like '%media' 
		UNION
		select distinct locality.locality_id as pk, ct.media_relationship as rel, ct.label as label, ct.auto_table as at
		from locality
		left join media_relations mr on locality.locality_id = mr.related_primary_key
		left join mczbase.ctmedia_relationship ct on mr.media_relationship = ct.media_relationship
		where mr.media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
		and ct.auto_table = 'locality' 
		UNION
		select distinct ce.collecting_event_id as pk, ct.media_relationship as rel, ct.label as label, ct.auto_table as at 
		from media_relations mr
		left join collecting_event ce on mr.related_primary_key = ce.collecting_event_id
		left join mczbase.ctmedia_relationship ct on mr.media_relationship = ct.media_relationship
		where mr.media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
		and ct.auto_table = 'collecting_event'
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
								<div class="col-12 col-md-5 col-xl-3 pt-0 pb-2 float-left">
									<div id="zoom" class="rounded highlight_media pt-3 px-2 mt-3 mb-0 pb-1">
										<cfset mediablock= getMediaBlockHtml(media_id="#media_id#",size="300",captionAs="textCaptionFull")>
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
														<p class="d-none d-md-block mb-0 small85 line90">Hover over the image to show a larger version. Place cursor in top left corner of media and zoom in with mousewheel or touchpad to zoom in to a larger version of the image.  Click on different parts of image if it goes beyond your screen size.</p><p class="d-block d-md-none mb-0 small85 line90"> Tap the image and swipe left to see larger version. Place two fingers on the touchpad/screen and pinch in or stretch out to zoom in on the image. Tap area off the image to close.  </p>
													</div>
												</aside>
											</div>
										</cfif>
									</div>
								</div>
							</cfif>
							<div id="metadatatable" class="col-12 col-md-7 col-xl-9 float-left my-0 pt-3 pb-0">
								<cfset mediaMetadataBlock= getMediaMetadata(media_id="#media_id#")>
								<div id="mediaMetadataBlock#media_id#">
									#mediaMetadataBlock#
								</div>
							</div>
							<cfif getRelatedThings.recordcount gt 0> 
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
												<cfif getRelatedThings.recordcount EQ 0>
													<h3 class="h4 px-2 ml-1 pt-2 onlyfirst"><span class="one">No Relationships to Other Records</span></h3>
												<cfelse>
													<!---If media relations exist for show or document cataloged_item, accn, ledger, deaccession, etc.--->
													<cfset hasMedia = false>
													<cfloop query="getRelatedThings">
														<cfquery name="getMediaForRelated" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
															SELECT distinct 
																m.media_id,
																ct.media_relationship,
																ct.label
															FROM media_relations mr 
																left join media m on mr.media_id = m.media_id
																left join mczbase.ctmedia_relationship ct on mr.media_relationship = ct.media_relationship
															WHERE
																 mr.related_primary_key = <cfqueryparam  value="#getRelatedThings.pk#">
																<cfif NOT ( getRelatedThings.pk eq '#media.media_id#' and getRelatedThings.at eq 'media' )>
																	and m.media_id <> <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media.media_id#">
																</cfif>
																and mr.media_relationship <> 'created by agent'
																and MCZBASE.is_media_encumbered(m.media_id)  < 1 
																<cfif getRelatedThings.pk gt 1 and getRelatedThings.label neq 'Shows Cataloged Item'>
																	and ct.media_relationship <> 'ledger entry for cataloged_item'
																</cfif>
														</cfquery>
														<!---Some of the ledgers have the same primary key as the agent_ids. I haven't found it on other types of relationships. We may need a different fix if it is more widespread.--->
														<!---Loops through only getRelatedThings query to get media images and captions for the white card in Related Media section for media relationships like "audio transcript for media" and "related to media"--->
														<cfif getRelatedThings.rel contains 'media'>
															<cfset hasMedia = true>
															<div class="col-md-4 col-lg-3 col-xl-2 px-1 pt-1 float-left multizoom thumbs">
																<ul class="list-group px-0">
																	<li class="list-group-item px-0 mx-1">
																		<cfset mediablock= getMediaBlockHtml(media_id="#getRelatedThings.pk#",displayAs="thumb",size='70',captionAs="textCaptionLong")>
																		<div class="border-wide-ltgrey rounded bg-white px-1 py-1 variedHeight" id="mediaBlock#getRelatedThings.pk#">
																			<div class="px-0">
																				<span class="px-2 d-block mt-1 small90 font-weight-lessbold text-center">
																				#getRelatedThings.label# <br>
																				#getRelatedThings.pk#
																				(media/#getRelatedThings.pk#)
																				</span> 
																				#mediablock#
																			</div>
																		</div>
																	</li>
																</ul>
															</div>
														</cfif>
														<!---Loops through getMediaForRelated & getRelatedThings queries to get media images and captions for the white card in Related Media section--->
														<cfif getMediaForRelated.recordcount gt 0>
															<cfset i = 1>
															<cfloop query="getMediaForRelated">
																<cfset hasMedia = true>
																<div class="col-md-4 col-lg-3 col-xl-2 px-1 pt-1 float-left multizoom thumbs">
																	<ul class="list-group px-0">
																		<li class="list-group-item px-0 mx-1">
																			<cfset mediablock= getMediaBlockHtml(media_id="#getMediaForRelated.media_id#",displayAs="thumb",size='70',captionAs="textCaptionLong")>
																			<div class="border-wide-ltgrey rounded bg-white px-1 py-1 image#i# variedHeight" id="mediaBlock#getMediaForRelated.media_id#">
																				<div class="px-0">
																					<span class="px-2 d-block mt-1 small90 font-weight-lessbold text-center">
																						#getMediaForRelated.label# <br>
																						<cfif getRelatedThings.at eq 'cataloged_item' and getMediaForRelated.recordcount gt 0>
																							<cfquery name="guidi" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
																								SELECT guid 
																								FROM <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat
																									join media_relations mr on flat.collection_object_id = mr.related_primary_key
																								WHERE 
																									mr.related_primary_key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getRelatedThings.pk#" >
																						</cfquery>
																						#guidi.guid#
																					<cfelse>
																					#getRelatedThings.pk#
																					</cfif>
																					(media/#getMediaForRelated.media_id#)
																					</span> 
																					#mediablock#
																				</div>
																			</div>
																		</li>
																	</ul>
																</div>
																<cfset i=i+1>
															</cfloop>
														</cfif>
													</cfloop>
													<cfif NOT hasMedia>
														<h3 class="h4 px-2 ml-1 pt-2">
															<span>No Related Media Records</span>
														</h3>
													</cfif>
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
