<cfset pageTitle="Media">
<!--- WARNING: Major work needed.  This is not a redesigned document yet.  See todo notes below --->

<!--- TODO: The old MediaSearch.cfm provides both search results (which should be handled by the media search), and individual media records.  This does not fit the design intent for /media/showMedia.cfm which following redesign conventions would show one and only one media record.  This file needs to be restarted from scratch with a redesign template to show only single media records.  (it should be pretty simple, just header, relevant management links for the user's permission level,  an invocation of getMediaBlockHtml for the single record, and the footer). --->

<!--- TODO: Any api call for more than one image needs to be redirected to either the media search, to show the list of matching images there, or to a new redesigned media gallery which would allow the display of multiple images in larger than thumbnail size along with their metadata --->
<cfinclude template="/shared/_header.cfm">
<script type='text/javascript' src='/media/js/media.js'></script>
<cfinclude template="/media/component/search.cfc" runOnce="true">

<cfoutput>
	<cfquery name="media" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select distinct 
		media.media_id,media.media_uri,media.mime_type,media.media_type,media.preview_uri, 
		MCZBASE.is_media_encumbered(media.media_id) hideMedia,
		MCZBASE.get_media_credit(media.media_id) as credit, 
		mczbase.get_media_descriptor(media_id) as alttag,
		nvl(MCZBASE.GET_MEDIA_REL_SUMMARY(media_id, 'shows cataloged_item') ||
			MCZBASE.GET_MEDIA_REL_SUMMARY(media_id, 'shows publication') ||
			MCZBASE.GET_MEDIA_REL_SUMMARY(media_id, 'shows collecting_event') ||
			MCZBASE.GET_MEDIA_REL_SUMMARY(media_id, 'shows agent') ||
			MCZBASE.GET_MEDIA_REL_SUMMARY(media_id, 'shows locality')
			, 'Unrelated image') mrstr
	From
		media
	WHERE 
		media.media_id IN <cfqueryparam cfsqltype="CF_SQL_DECiMAL" value="#media_id#" list="yes">
		AND MCZBASE.is_media_encumbered(media_id)  < 1 
	</cfquery>
	<main class="container-xl" id="content">
		<div class="row mx-0">
			<div class="col-12 pb-4">
			<cfloop query="media">
				<div class="row">
					<div class="col-12 mt-4">
						<h1 class="h2 mt-4 pb-1 mb-3 pb-3 border-bottom"> Media Record
							<button class="btn float-right btn-xs btn-primary" onClick="location.href='/MediaSet.cfm?media_id=#media_id#'">Viewer</button>
						</h1>
					</div>
					<div class="col-12 mt-2">
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
						<div class="border-light float-left px-2 pt-2" style="width:402px;">
							<cfset mediablock= getMediaBlockHtml(media_id="#media.media_id#",size="400",captionAs="textFull")>
							<div class="float-left bg-light h-100" id="mediaBlock#media.media_id#"> #mediablock# </div>
						</div>
						</cfif>
						<div class="float-left col-12 px-0 col-xl-6 px-xl-4">
							<h2 class="h3 px-2">Media ID = #media.media_id#</h2>
							<h3 class="text-decoration-underline px-2">Metadata</h3>
							<ul class="list-group">
								<cfloop query="labels">
									<li class="list-group-item"><span class="text-uppercase">#labels.media_label#:</span> #labels.label_value#</li>
								</cfloop>
								<cfquery name="relations"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
								select media_relationship as mr_label, MCZBASE.MEDIA_RELATION_SUMMARY(media_relations_id) as mr_value
									from media_relations
								where media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media.media_id#">
									and media_relationship in ('created by agent', 'shows cataloged_item')
							</cfquery>
								<cfloop query="relations">
									<cfif not (not listcontainsnocase(session.roles,"coldfusion_user") and #mr_label# eq "created by agent")>
										<cfset labellist = "<li>#mr_label#: #mr_value#</li>">
									</cfif>
								</cfloop>
								<li class="list-group-item"><span class="text-uppercase">Keywords: </span> #keywords.keywords#</li>
								<li class="list-group-item border p-2"><span class="text-uppercase">Alt Text: </span>#media.alttag#</li>
							</ul>
						</div>
					</div>
				</div>
				<!---specimen records--->
				<div class="row mx-0">
				<cfquery name="ff" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select distinct collection_object_id as pk, guid, typestatus, SCIENTIFIC_NAME name,
					decode(continent_ocean, null,'',' '|| continent_ocean) || decode(country, null,'',': '|| country) || decode(state_prov, null, '',': '|| state_prov) || decode(county, null, '',': '|| county)||decode(spec_locality, null,'',': '|| spec_locality) as geography,
					trim(MCZBASE.GET_CHRONOSTRATIGRAPHY(locality_id) || ' ' || MCZBASE.GET_LITHOSTRATIGRAPHY(locality_id)) as geology,
					trim( decode(collectors, null, '',''|| collectors) || decode(field_num, null, '','  '|| field_num) || decode(verbatim_date, null, '','  '|| verbatim_date))as coll,
					specimendetailurl, media_relationship
				from media_relations
					left join flat on related_primary_key = collection_object_id
				where media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
						and (media_relations.media_relationship = 'shows cataloged_item')
				</cfquery>
				<cfif len(ff.guid) gt 0>
					<h1 class="h3 w-100 mt-4 mb-0 px-2">Specimen Records with this Media</h1>
					<cfquery name="relm" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select distinct media.media_id, preview_uri, media.media_uri,
							get_medialabel(media.media_id,'height') height, get_medialabel(media.media_id,'width') width,
							media.mime_type, media.media_type, media.auto_protocol, media.auto_host,
							CASE WHEN MCZBASE.is_mcz_media(media.media_id) = 1 THEN ctmedia_license.display ELSE MCZBASE.get_media_dcrights(media.media_id) END as license,
								ctmedia_license.uri as license_uri,
								mczbase.get_media_credit(media.media_id) as credit,
								MCZBASE.is_media_encumbered(media.media_id) as hideMedia
						from media_relations
							 left join media on media_relations.media_id = media.media_id
							 left join ctmedia_license on media.media_license_id = ctmedia_license.media_license_id
						where (media_relationship = 'shows cataloged_item' or media_relationship = 'shows agent')
							AND related_primary_key = <cfqueryparam value=#ff.pk# CFSQLType="CF_SQL_DECIMAL" >
							AND MCZBASE.is_media_encumbered(media.media_id)  < 1
					</cfquery>
					<table class="search-box table table-responsive mt-1 w-100">
						<thead class="search-box-header mt-1">
							<tr class="text-white">
								<th>Catalog&nbsp;Item</th>
								<th>Type&nbsp;Status&nbsp;&amp;&nbsp;Citation</th>
								<th>Scientific&nbsp;Name</th>
								<th>Location&nbsp;Data</th>
								<th>Image&nbsp;Thumbnail(s)</th>
							</tr>
						</thead>
						<tbody>
							<cfloop query="ff">
								<tr>
									<td style="width: 10%;"><a href="#relm.auto_protocol#/#relm.auto_host#/guid/#ff.guid#">#ff.guid#</a></td>
									<cfif len(ff.typestatus) gt 0>
										<td>#ff.typestatus#</td>
										<cfelse>
										<td>None</td>
									</cfif>
									<td>#ff.name#</td>
									<td style="min-width: 120px;">#ff.geography#</td>
									<td style="width:60%;">
										<cfloop query="relm">
											<div class="border-light float-left px-2 pt-2" style="width:112px;height:170px;">
											<cfif len(media.media_id) gt 0>
												<cfif relm.media_id eq '#media.media_id#'> 
													<cfset activeimg = "border-warning border-left border-right border-bottom border-top">
												<cfelse>	
													<cfset activeimg = "border-light">
												</cfif>
												<cfset mediablock= getMediaBlockHtml(media_id="#relm.media_id#",displayAs="thumb",size='100',captionAs="textShort")>
												<div class="float-left #activeimg#" id="mediaBlock#relm.media_id#"> #mediablock# </div>
											</cfif>
											</div>
										</cfloop>
									</td>
								</tr>
							</cfloop>
						</tbody>
					</table>
				<cfelse>
					<h3 class="h4 mt-5 w-100 font-italic">Not associated with Specimen Records</h3>
				</cfif>
				</div>
				<!--- accn records --->
				<div class="row mx-0">
					<cfquery name="tt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							select 
								accn.transaction_id, accn.received_date, accn.accn_type, accn.estimated_count, accn.accn_number, accn.accn_num_suffix,accn.accn_status,trans_agent.agent_id,get_transAgents(agent_id,1 ,'preferred') as received_agent
							from
								accn
								left join media_relations on media_relations.related_primary_key = accn.transaction_id
								left join trans_agent on accn.transaction_ID = trans_agent.transaction_id
							where 
								media_relations.media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
								and media_relations.media_relationship = 'documents accn'
								and trans_agent.trans_agent_role = 'received from'
					</cfquery>
					<cfif len(tt.transaction_id) gt 0>
						<h1 class="h3 w-100 mb-0 px-2">Accn Records with this Media</h1>
						<div class="col-12 px-0">
						<cfquery name="relm2" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select distinct media.media_id, preview_uri, media.media_uri,
							media.mime_type, media.media_type, media.auto_protocol, media.auto_host
						from media_relations
							 left join media on media_relations.media_id = media.media_id
						where related_primary_key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#tt.transaction_id#">
						</cfquery>
							<table class="search-box table table-responsive mt-1 w-100">
								<thead class="search-box-header mt-1">
									<tr class="text-white">
										<th>Accession&nbsp;ID</th>
										<th>Collection</th>
										<th>Accession&nbsp;Type</th>
										<th>Accession&nbsp;Number</th>
										<th>Accession&nbsp;Status</th>
										<th>Agents&nbsp;Involved</th>
										<th>Image&nbsp;Thumbnail(s)</th>
									</tr>
								</thead>
								<tbody>
									<tr>
										<td>#tt.transaction_id#</td>
										<td>#tt.accn_num_suffix#</td>
										<td>#tt.accn_type#</td>
										<td>#tt.accn_number#</td>
										<td>#tt.accn_status#</td>
										<td style="width:10%">#tt.received_agent#</td>
										<td style="width:60%;">
											<cfloop query="relm2">
												<div class="border-light float-left px-2 pt-2" style="width:112px;">
												<cfif len(tt.transaction_id) gt 0>
													<cfif relm2.media_id eq '#media.media_id#'> 
														<cfset activeimg = "border-warning border-left border-right border-bottom border-top">
													<cfelse>	
														<cfset activeimg = "border-light">
													</cfif>
													<cfset mediablock= getMediaBlockHtml(media_id="#relm2.media_id#",displayAs="thumb",size='100',captionAs="textShort")>
													<div class="float-left #activeimg#" id="mediaBlock#relm2.media_id#"> #mediablock# </div>
												</cfif>
												</div>
											</cfloop>
										</td>
									</tr>
								</tbody>
							</table>
						</div>
					<cfelse>						
					</cfif>
				</div>
				<!--- collecting event records --->
				<div class="row mx-0">
					<cfquery name="ce" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select collecting_event.collecting_event_id, collecting_event.locality_id, collecting_event.verbatim_date, collecting_event.verbatim_locality, collecting_event.collecting_source
						from collecting_event 
							left join media_relations on media_relations.related_primary_key = collecting_event.collecting_event_id
						where media_relations.media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
							and media_relations.media_relationship = 'shows collecting_event'
					</cfquery>
					<cfif len(ce.collecting_event_id) gt 0>
						<h1 class="h3 w-100 mb-0 px-2">Collecting Event Records with this Media</h1>
						<div class="col-12 px-0">
						<cfquery name="relm3" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select distinct media.media_id, preview_uri, media.media_uri, media.mime_type, media.media_type, media.auto_protocol, media.auto_host
						from media_relations
							 left join media on media_relations.media_id = media.media_id
						where related_primary_key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#ce.collecting_event_id#">
						</cfquery>
							<table class="search-box table table-responsive mt-1 w-100">
								<thead class="search-box-header mt-1">
									<tr class="text-white">
										<th>Collecting&nbsp;Event&nbsp;ID</th>
										<th>Locality&nbsp;ID</th>
										<th>Verbatim&nbsp;Date</th>
										<th>Verbatim&nbsp;Locality</th>
										<th>Collecting&nbsp;Source</th>
										<th>Image&nbsp;Thumbnail(s)</th>
										
									</tr>
								</thead>
								<tbody>
									<tr>
										<td>#ce.collecting_event_id#</td>
										<td>#ce.locality_id#</td>
										<td>#ce.verbatim_date#</td>
										<td>#ce.verbatim_locality#</td>
										<td>#ce.collecting_source#</td>
										<td style="width:60%;">
											<cfloop query="relm3">
												<div class="border-light float-left px-2 pt-2" style="width:112px;">
												<cfif len(ce.collecting_event_id) gt 0>
													<cfif relm3.media_id eq '#media.media_id#'> 
														<cfset activeimg = "border-warning border-left border-right border-bottom border-top">
													<cfelse>	
														<cfset activeimg = "border-light">
													</cfif>
													<cfset mediablock= getMediaBlockHtml(media_id="#relm3.media_id#",displayAs="thumb",size='100',captionAs="textShort")>
													<div class="float-left #activeimg#" id="mediaBlock#relm3.media_id#"> #mediablock# </div>
												</cfif>
												</div>
											</cfloop>
										</td>
									</tr>
								</tbody>
							</table>
						</div>
					<cfelse>						
					</cfif>
				</div>
				<!---Permit records--->
				<div class="row mx-0">
					<cfquery name="permit" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select permit.permit_id, permit.issued_date, permit.permit_num, permit.permit_type, permit.permit_remarks
						from permit
							left join media_relations on media_relations.related_primary_key = permit.permit_id
						where media_relations.media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
							and (media_relations.media_relationship = 'shows permit' OR media_relations.media_relationship = 'documents for permit')
					</cfquery>
					<cfif len(permit.permit_id) gt 0>
						<h1 class="h3 w-100 mb-0 px-2">Permit Records with this Media</h1>
						<div class="col-12 px-0">
						<cfquery name="relm4" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select distinct media.media_id, preview_uri, media.media_uri, media.mime_type, media.media_type, media.auto_protocol, media.auto_host
						from media_relations
							 left join media on media_relations.media_id = media.media_id
						where related_primary_key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#permit.permit_id#">
						</cfquery>
							<table class="search-box table table-responsive mt-1 w-100">
								<thead class="search-box-header mt-1">
									<tr class="text-white">
										<th>Permit&nbsp;ID</th>
										<th>Issued&nbsp;Date</th>
										<th>Permit&nbsp;Number</th>
										<th>Permit&nbsp;Type</th>
										<th>Permit&nbsp;Remarks</th>
										<th>Image Thumbnail(s)</th>
									</tr>
								</thead>
								<tbody>
									<tr>
										<td>#permit.permit_id#</td>
										<td>#permit.issued_date#</td>
										<td>#permit.permit_num#</td>
										<td>#permit.permit_type#</td>
										<td>#permit.permit_remarks#</td>
										<td style="width:60%;">
											<cfloop query="relm4">
												<div class="border-light float-left px-2 pt-2" style="width:112px;">
												<cfif len(permit.permit_id) gt 0>
													<cfif relm4.media_id eq '#media.media_id#'> 
														<cfset activeimg = "border-warning border-left border-right border-bottom border-top px-1">
													<cfelse>	
														<cfset activeimg = "border-light">
													</cfif>
													<cfset mediablock= getMediaBlockHtml(media_id="#relm4.media_id#",displayAs="thumb",size='100',captionAs="textShort")>
													<div class="float-left #activeimg#" id="mediaBlock#relm4.media_id#"> #mediablock# </div>
												</cfif>
												</div>
											</cfloop>
										</td>
									</tr>
								</tbody>
							</table>
						</div>
					<cfelse>						
					</cfif>
				</div>
				<!---Borrow records--->			
				<div class="row mx-0">
					<cfquery name="borrow" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select borrow.transaction_id, borrow.lenders_trans_num_cde, borrow.received_date, borrow.due_date, borrow.lenders_loan_date, borrow.borrow_status
						from borrow 
							left join media_relations on media_relations.related_primary_key = borrow.transaction_id
						where media_relations.media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
							and media_relations.media_relationship = 'documents borrow'
					</cfquery>
					<cfif len(borrow.transaction_id) gt 0>
						<h1 class="h3 w-100 mb-0 px-2">Borrow Records with this Media</h1>
						<div class="col-12 px-0">
						<cfquery name="relm5" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select distinct media.media_id, preview_uri, media.media_uri, media.mime_type, media.media_type, media.auto_protocol, media.auto_host
						from media_relations
							 left join media on media_relations.media_id = media.media_id
						where related_primary_key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#borrow.transaction_id#">
						</cfquery>
							<table class="search-box table table-responsive mt-1 w-100">
								<thead class="search-box-header mt-1">
									<tr class="text-white">
										<th>Collecting&nbsp;Event&nbsp;ID</th>
										<th>Locality&nbsp;ID</th>
										<th>Verbatim&nbsp;Date</th>
										<th>Verbatim&nbsp;Locality</th>
										<th>Collecting&nbsp;Source</th>
										<th>Image&nbsp;Thumbnail(s)</th>
										
									</tr>
								</thead>
								<tbody>
									<tr>
										<td>#borrow.transaction_id#</td>
										<td>#borrow.lenders_trans_num_cde#</td>
										<td>#borrow.received_date#</td>
										<td>#borrow.due_date#</td>
										<td>#borrow.lenders_loan_date#</td>
										<td>#borrow.borrow_status#</td>
										<td style="width:60%;">
											<cfloop query="relm5">
												<div class="border-light float-left px-2 pt-2" style="width:112px;">
												<cfif len(borrow.transaction_id) gt 0>
													<cfif relm5.media_id eq '#media.media_id#'> 
														<cfset activeimg = "border-warning border-left border-right border-bottom border-top px-1">
													<cfelse>	
														<cfset activeimg = "border-light">
													</cfif>
													<cfset mediablock= getMediaBlockHtml(media_id="#relm5.media_id#",displayAs="thumb",size='100',captionAs="textShort")>
													<div class="float-left #activeimg#" id="mediaBlock#relm5.media_id#"> #mediablock# </div>
												</cfif>
												</div>
											</cfloop>
										</td>
									</tr>
								</tbody>
							</table>
						</div>
					<cfelse>						
					</cfif>
				</div>
				<!---Deaccession records--->			
				<div class="row mx-0">
					<cfquery name="deaccession" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select collecting_event.collecting_event_id, collecting_event.locality_id, collecting_event.verbatim_date, collecting_event.verbatim_locality, collecting_event.collecting_source
						from collecting_event 
							left join media_relations on media_relations.related_primary_key = collecting_event.collecting_event_id
						where media_relations.media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
							and (media_relations.media_relationship = 'shows collecting_event' OR media_relations.media_relationship= 'shows handwriting of agent')
					</cfquery>
					<cfif len(deaccession.collecting_event_id) gt 0>
						<h1 class="h3 w-100 mb-0 px-2">Collecting Event Records with this Media</h1>
						<div class="col-12 px-0">
						<cfquery name="relm3" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select distinct media.media_id, preview_uri, media.media_uri, media.mime_type, media.media_type, media.auto_protocol, media.auto_host
						from media_relations
							 left join media on media_relations.media_id = media.media_id
						where related_primary_key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#ce.collecting_event_id#">
						</cfquery>
							<table class="search-box table table-responsive mt-1 w-100">
								<thead class="search-box-header mt-1">
									<tr class="text-white">
										<th>Collecting&nbsp;Event&nbsp;ID</th>
										<th>Locality&nbsp;ID</th>
										<th>Verbatim&nbsp;Date</th>
										<th>Verbatim&nbsp;Locality</th>
										<th>Collecting&nbsp;Source</th>
										<th>Image&nbsp;Thumbnail(s)</th>
										
									</tr>
								</thead>
								<tbody>
									<tr>
										<td>#ce.collecting_event_id#</td>
										<td>#ce.locality_id#</td>
										<td>#ce.verbatim_date#</td>
										<td>#ce.verbatim_locality#</td>
										<td>#ce.collecting_source#</td>
										<td style="width:60%;">
											<cfloop query="relm3">
												<div class="border-light float-left px-2 pt-2" style="width:112px;">
												<cfif len(ce.collecting_event_id) gt 0>
													<cfif relm3.media_id eq '#media.media_id#'> 
														<cfset activeimg = "border-warning border-left border-right border-bottom border-top">
													<cfelse>	
														<cfset activeimg = "border-light">
													</cfif>
													<cfset mediablock= getMediaBlockHtml(media_id="#relm3.media_id#",displayAs="thumb",size='100',captionAs="textMid")>
													<div class="float-left #activeimg#" id="mediaBlock#relm3.media_id#"> #mediablock# </div>
												</cfif>
												</div>
											</cfloop>
										</td>
									</tr>
								</tbody>
							</table>
						</div>
					<cfelse>						
					</cfif>
				</div>
			</cfloop>
			</div>
			</div>
		</div>
	</main>
</cfoutput>
<cfinclude template="/shared/_footer.cfm">
