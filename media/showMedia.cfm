<cfset pageTitle="Media">
<!--- WARNING: Major work needed.  This is not a redesigned document yet.  See todo notes below --->

<!--- TODO: The old MediaSearch.cfm provides both search results (which should be handled by the media search), and individual media records.  This does not fit the design intent for /media/showMedia.cfm which following redesign conventions would show one and only one media record.  This file needs to be restarted from scratch with a redesign template to show only single media records.  (it should be pretty simple, just header, relevant management links for the user's permission level,  an invocation of getMediaBlockHtml for the single record, and the footer). --->

<!--- TODO: Any api call for more than one image needs to be redirected to either the media search, to show the list of matching images there, or to a new redesigned media gallery which would allow the display of multiple images in larger than thumbnail size along with their metadata --->
<cfinclude template="/shared/_header.cfm">
<script type='text/javascript' src='/media/js/media.js'></script>
<cfinclude template="/media/component/search.cfc" runOnce="true">

<cfset maxMedia = 4>
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
	<main class="container-fluid" id="content">
		<div class="row mx-0">
			<div class="col-12 pb-4">
			<cfloop query="media">
				<div class="row mx-0">
					<div class="col-12 px-0 px-xl-5 mt-4">
						<h1 class="h2 mt-4 pb-1 mb-3 pb-3 border-bottom"> Media Record 	<span class="h3 px-2 mt-0">(Media ID = #media.media_id#)</span>
							<button class="btn float-right btn-xs btn-primary" onClick="location.href='/MediaSet.cfm?media_id=#media_id#'">Media Viewer</button>
						</h1>
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
						<div class="rounded border bg-light col-12 col-sm-6 col-md-3 col-xl-2 float-left mb-3 pt-3 pb-2">
							<cfset mediablock= getMediaBlockHtml(media_id="#media.media_id#",size="400",captionAs="textFull")>
							<div class="mx-auto text-center pt-1" id="mediaBlock#media.media_id#"> #mediablock# </div>
						</div>
						</cfif>

						<div class="float-left col-12 px-0 col-md-9 pl-md-4 col-xl-10 pl-xl-4">
						
							<h3 class="mx-2 h4 mb-1 mt-0 border-dark w-auto float-left">Metadata</h3>
							<table class="table border-none">
								<thead class="thead-light">
									<tr>
										<th scope="col">Label</th>
										<th scope="col">Value</th>
									</tr>
								</thead>
								<tbody>
									<tr>
										<th scope="row"><span class="text-uppercase">MEDIA TYPE:</span></th><td> #media.media_type#</td>
									</tr>
									<cfloop query="labels">
									<tr>
										<th scope="row"><span class="text-uppercase">#labels.media_label#:</span></th><td> #labels.label_value#</td>
									</tr>
									</cfloop>
									<cfquery name="relations"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
									select media_relationship as mr_label, MCZBASE.MEDIA_RELATION_SUMMARY(media_relations_id) as mr_value
										from media_relations
									where media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media.media_id#">
										and media_relationship in ('created by agent', 'shows cataloged_item')
									</cfquery>
									<cfloop query="relations">
										<cfif not (not listcontainsnocase(session.roles,"coldfusion_user") and #mr_label# eq "created by agent")>
											<cfset labellist = "<th scope='row'><span class='text-uppercase'>#mr_label#:</span></th><td> #mr_value#</td>">
										</cfif>
									</cfloop>
									<cfif len(keywords.keywords) gt 0>
									<tr>
										<th scope="row"><span class="text-uppercase">Keywords: </span></th><td> #keywords.keywords#</td>
									</tr>
									<cfelse>
									</cfif>
									<cfif listcontainsnocase(session.roles,"manage_media")>
									<tr class="border mt-2 p-2">
										<th scope="row"><span class="text-uppercase">Alt Text: </span></th><td>#media.alttag#</td>
									</tr>
									</cfif>
								</tbody>
							</table>
						</div>
					</div>
				</div>
				<!---specimen records--->
				<div class="row mx-0 mb-3">
				<cfquery name="spec" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select distinct collection_object_id as pk, guid, typestatus, SCIENTIFIC_NAME name,
					decode(continent_ocean, null,'',' '|| continent_ocean) || decode(country, null,'',': '|| country) || decode(state_prov, null, '',': '|| state_prov) || decode(county, null, '',': '|| county)||decode(spec_locality, null,'',': '|| spec_locality) as geography,
					trim(MCZBASE.GET_CHRONOSTRATIGRAPHY(locality_id) || ' ' || MCZBASE.GET_LITHOSTRATIGRAPHY(locality_id)) as geology,
					trim( decode(collectors, null, '',''|| collectors) || decode(field_num, null, '','  '|| field_num) || decode(verbatim_date, null, '','  '|| verbatim_date))as coll,
					specimendetailurl, media_relationship
				from media_relations
					left join flat on related_primary_key = collection_object_id
				where media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media.media_id#">
						and (media_relations.media_relationship = 'shows cataloged_item')
				</cfquery>
				<cfif len(spec.guid) gt 0>
					<h1 class="h3 w-100 my-0 px-2">Specimen Records with this Media</h1>
					<cfquery name="relm" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select distinct media.media_id, preview_uri, media.media_uri,
							get_medialabel(media.media_id,'height') height, get_medialabel(media.media_id,'width') width,
							media.mime_type, media.media_type, media.auto_protocol, media.auto_host,
							CASE WHEN MCZBASE.is_mcz_media(media.media_id) = 1 THEN ctmedia_license.display ELSE MCZBASE.get_media_dcrights(media.media_id) END as license,
							ctmedia_license.uri as license_uri,
							mczbase.get_media_credit(media.media_id) as credit,
							MCZBASE.is_media_encumbered(media.media_id) as hideMedia,
							MCZBASE.get_media_title(media.media_id) as title1
						from media_relations
							 left join media on media_relations.media_id = media.media_id
							 left join ctmedia_license on media.media_license_id = ctmedia_license.media_license_id
						where (media_relationship = 'shows cataloged_item' or media_relationship = 'shows agent')
							AND related_primary_key = <cfqueryparam value=#spec.pk# CFSQLType="CF_SQL_DECIMAL" >
							AND MCZBASE.is_media_encumbered(media.media_id)  < 1
					</cfquery>
					<div class="search-box mt-1 pb-0 w-100">
						<div class="search-box-header px-2 mt-0">
							<ul class="list-group list-group-horizontal text-white">
								<li class="col-2 col-xl-1  px-1 list-group-item"><span class="font-weight-lessbold">Catalog&nbsp;Item<span class="d-inline d-lg-none">s </span></span></li>
								<li class="col-3 col-xl-3 px-1 list-group-item d-none d-lg-block"><span class="font-weight-lessbold">Details</span></li>
								<li class="col-7 col-xl-8 px-1 list-group-item d-none d-lg-block"><span class="font-weight-lessbold">Image&nbsp;Thumbnail(s)</span></li>
							</ul>
						</div>
						<cfloop query="spec">
							<div class="row mx-0 py-0 border-top-teal">
								<div class="col-12 col-lg-2 col-xl-1 py-2 border-right small90">
									<span class="d-inline d-lg-none font-weight-lessbold">Catalog Number: </span><a href="#relm.auto_protocol#/#relm.auto_host#/guid/#spec.guid#">#spec.guid#</a>
								</div>
								<div class="col-12 col-lg-3 col-xl-3 pt-2 pb-1 border-right small">
									<div class="row mx-0">
										<h3 class="h5 mb-0">Type Status &amp; Citation</h3>
										<cfif len(spec.typestatus) gt 0>

											<div class="col-12 pt-0 pb-1">#spec.typestatus#</div>
										<cfelse>
											<div class="col-12 pt-0 pb-1">None</div>
										</cfif>
									</div>
									<div class="row mx-0">
										<h3 class="h5 mb-0">Scientific&nbsp;Name</h3>
										<div class="col-12 pt-0 pb-1">#spec.name#</div>
									</div>
									<div class="row mx-0">
										<h3 class="h5 mb-0">Location&nbsp;Data</h3>
										<div class="col-12 pt-0 pb-1">#spec.geography#</div>
									</div>
								</div>
								<div class="col-12 col-lg-7 col-xl-8 p-1">
									<cfif relm.recordcount lte #maxMedia#>
										<cfloop query="relm">
											<div class="border-light col-12 col-md-6 col-lg-4 col-xl-3 p-1 float-left"> 
												<cfif len(media.media_id) gt 0>
													<cfif relm.media_id eq '#media.media_id#'> 
														<cfset activeimg = "border-warning bg-white w-100 float-left border-left px-1 py-2 border-right border-bottom border-top">
													<cfelse>	
														<cfset activeimg = "border-lt-gray bg-white w-100 float-left px-1 py-2">
													</cfif>
													<cfset mediablock= getMediaBlockHtml(media_id="#relm.media_id#",displayAs="fixedSmallThumb",size="75",captionAs="textLinks",background_color="white")>
													<div class="#activeimg#" id="mediaBlock#relm.media_id#">
														<div class="col-5 bg-white px-1 float-left"> #mediablock# </div>
														<cfset showTitleText1 = trim(title1)>
															<cfif len(showTitleText1) gt 150><cfset showTitleText1 = "#left(showTitleText1,150)#..." ><cfelse><cfset showTitleText1 = "#showTitleText1#" ></cfif>
														<div class="col-7 bg-white px-2 smaller float-left" style="line-height: .89rem;">#showTitleText1#</div>
													</div>
												</cfif>
											</div>
										</cfloop>
									<cfelse>
										<cfloop query="relm">
											<div class="border-light col-12 col-md-6 col-lg-4 col-xl-3 p-1 float-left"> 
												<cfif len(media.media_id) gt 0>
													<cfif relm.media_id eq '#media.media_id#'> 
														<cfset activeimg = "border-warning w-100 bg-white float-left border-left px-1 pt-2 border-right border-bottom border-top">
													<cfelse>	
														<cfset activeimg = "border-lt-gray w-100 bg-white float-left px-1 pt-2">
													</cfif>
													<div class="#activeimg#" id="mediaBlock#relm.media_id#">
														<div class="col-5 bg-white px-1 float-left">
															<cfset mediablock= getMediaBlockHtml(media_id="#relm.media_id#",displayAs="fixedSmallThumb",size="50",captionAs="textLinks",background_color="white")>#mediablock#
														</div>
														<cfset showTitleText1 = trim(title1)>
															<cfif len(title1) gt 150><cfset showTitleText = "#left(showTitleText1,150)#..." ></cfif>
														<div class="col-7 bg-white px-2 pb-2 smaller float-left" style="line-height: .89rem;">#showTitleText1#</div>
													</div>
												</cfif>
											</div>
										</cfloop>
									</cfif>
									<div id="targetDiv"></div>
								</div>
							</div>
						</cfloop>
					</div>
				<cfelse>
					<h3 class="h4 mt-3 w-100 px-2 font-italic">Not associated with Specimen Records</h3>
				</cfif>
				</div>
				<!--- accn records --->
				<div class="row mx-0">
					<cfquery name="accn" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
					<cfif len(accn.transaction_id) gt 0>
						<h1 class="h3 w-100 my-0 px-2">Accn Records with this Media</h1>
						<div class="col-12 px-0">
						<cfquery name="relm2" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select distinct media.media_id, preview_uri, media.media_uri,
							media.mime_type, media.media_type, media.auto_protocol, media.auto_host,MCZBASE.get_media_title(media.media_id) as title1
						from media_relations
							 left join media on media_relations.media_id = media.media_id
						where related_primary_key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#accn.transaction_id#">
						</cfquery>
						<div class="search-box mt-1 w-100">
							<div class="search-box-header px-2 mt-0 mediaTableHeader">
								<ul class="list-group list-group-horizontal text-white">
									<li class="col-2 col-xl-1  px-1 list-group-item"><span class="font-weight-lessbold">Accession&nbsp;ID<span class="d-inline d-lg-none">s </span></span></li>
									<li class="col-3 col-xl-1 px-1 list-group-item d-none d-lg-block"><span class="font-weight-lessbold">Accession&nbsp;Number<span class="d-inline d-lg-none">s </span></span>
									<li class="col-3 col-xl-3 px-1 list-group-item d-none d-lg-block"><span class="font-weight-lessbold">Details</span></li>
									<li class="col-7 col-xl-7 px-1 list-group-item d-none d-lg-block"><span class="font-weight-lessbold">Image&nbsp;Thumbnail(s)</span></li>
								</ul>
							</div>
								<cfloop query="accn">
									<div class="row mx-0 border-top py-0 border-gray">
										<div class="col-12 col-md-1 col-xl-1 py-2 border-right small90">
											<a href="#relm2.auto_protocol#/#relm2.auto_host#/guid/#accn.transaction_id#">
												#accn.transaction_id#</a>
										</div>
										<div class="col-12 col-md-1 col-xl-1 py-2 border-right small90">
											<a href="#relm2.auto_protocol#/#relm2.auto_host#/guid/#accn.accn_number#">
												#accn.accn_number#</a>
										</div>
										<div class="col-12 col-md-4 col-xl-1 py-2 border-right small">
											<div class="row mx-0">
												<h3 class="h5 mb-0">Accession Type</h3>
												<div class="col-12 pt-1 pb-2">#accn.accn_type#</div>
											</div>
											<div class="row mx-0">
												<h3 class="h5 mb-0">Accession Status</h3>
												<div class="col-12 pt-1 pb-2">#accn.accn_status#</div>
											</div>
											<div class="row mx-0">
												<h3 class="h5 mb-0">Agents Involved</h3>
												<div class="col-12 pt-1 pb-2">#accn.received_agent#</div>
											</div>
										</div>
										<div class="col-12 col-md-6 col-xl-9 p-1">
											<cfif relm2.recordcount lte #maxMedia#>
												<cfloop query="relm2">
													<div class="border-light col-md-6 col-lg-4 col-xl-4 p-1 float-left"> 
														<cfif len(accn.transaction_id) gt 0>
															<cfif relm2.media_id eq '#media.media_id#'> 
																<cfset activeimg = "border-warning bg-white float-left border-left px-1 py-2 border-right border-bottom border-top">
															<cfelse>	
																<cfset activeimg = "border-lt-gray bg-white float-left px-1 py-2">
															</cfif>
															<cfset mediablock= getMediaBlockHtml(media_id="#relm2.media_id#",displayAs="fixedSmallThumb",size="75",captionAs="textLinks",background_color="white")>
															<div class="#activeimg#" id="mediaBlock#relm2.media_id#">
																<div class="col-5 bg-white px-1 float-left"> #mediablock# </div>
																<cfset showTitleText1 = trim(title1)>
																	<cfif len(showTitleText1) gt 170><cfset showTitleText1 = "#left(showTitleText1,170)#..." ><cfelse><cfset showTitleText1 = "#showTitleText1#" ></cfif>
																<div class="col-7 bg-white px-2 smaller float-left" style="line-height: .89rem;">#showTitleText1#</div>
															</div>
														</cfif>
													</div>
												</cfloop>
											<cfelse>
												<cfloop query="relm2">
													<div class="border-light col-md-6 col-lg-4 col-xl-3 p-1 float-left"> 
														<cfif len(accn.transaction_id) gt 0>
															<cfif relm2.media_id eq '#media.media_id#'> 
																<cfset activeimg = "border-warning bg-white float-left border-left px-1 py-2 border-right border-bottom border-top">
															<cfelse>	
																<cfset activeimg = "border-lt-gray bg-white float-left px-1 py-2">
															</cfif>
															<div class="#activeimg#" id="mediaBlock#relm2.media_id#">
																<div class="col-5 bg-white px-1 float-left">
																	<cfset mediablock= getMediaBlockHtml(media_id="#relm2.media_id#",displayAs="fixedSmallThumb",size="85",captionAs="textLinks",background_color="white")>#mediablock#
																</div>
																<cfset showTitleText1 = trim(title1)>
																<cfif len(showTitleText1) gt 170>
																	<cfset showTitleText1 = "#left(showTitleText1,170)#..." >
																<cfelse>
																	<cfset showTitleText1 = "#showTitleText1#" >
																</cfif>
																<div class="col-7 bg-white px-2 smaller float-left" style="line-height: .89rem;">
																	#showTitleText1#
																</div>
															</div>
														</cfif>
													</div>
												</cfloop>
											</cfif>
										<div id="targetDiv"></div>
										</div>
									</div>
								</cfloop>
						</div>
					<cfelse>
							<h3 class="h4 mt-3 w-100 px-2 font-italic">Not associated with Accessions</h3>
					</cfif>
				</div>
				<!--- collecting event records --->
				<div class="row mx-0">
					<cfquery name="collecting_event" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select collecting_event.collecting_event_id, collecting_event.locality_id, collecting_event.verbatim_date, collecting_event.verbatim_locality, collecting_event.collecting_source
						from collecting_event 
							left join media_relations on media_relations.related_primary_key = collecting_event.collecting_event_id
						where media_relations.media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
							and media_relations.media_relationship = 'shows collecting_event'
					</cfquery>
					<cfif len(collecting_event.collecting_event_id) gt 0>
						<h1 class="h3 w-100 my-0 px-2">Collecting Event Records with this Media</h1>
						<div class="col-12 px-0">
						<cfquery name="relm3" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select distinct media.media_id, preview_uri, media.media_uri, media.mime_type, media.media_type, media.auto_protocol, media.auto_host, MCZBASE.get_media_title(media.media_id) as title1
						from media_relations
							 left join media on media_relations.media_id = media.media_id
						where related_primary_key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collecting_event.collecting_event_id#">
						</cfquery>
						<div class="search-box mt-1 w-100">
							<div class="search-box-header px-2 mt-0 mediaTableHeader">
								<ul class="list-group list-group-horizontal text-white">
									<li class="col-1 px-1 list-group-item"><span class="font-weight-lessbold">Collecting&nbsp;Event</span></li>
									<li class="col-1 px-1 list-group-item"><span class="font-weight-lessbold">Locality&nbsp;ID</span></li>
									<li class="col-4 px-1 list-group-item"><span class="font-weight-lessbold">Details</span></li>
									<li class="col-6 px-1 list-group-item"><span class="font-weight-lessbold">Image&nbsp;Thumbnail(s)</span></li>
								</ul>
							</div>
							<cfloop query="collecting_event">
								<div class="row mx-0 border-top py-2 border-gray" style="border">
									<div class="col-12 col-md-1 py-2 border-right small90">
										<a href="#relm3.auto_protocol#/#relm3.auto_host#/guid/#collecting_event.collecting_event_id#">
											#collecting_event.collecting_event_id#</a>
									</div>
									<div class="col-12 col-md-1 py-2 border-right small90">
										<a href="#relm3.auto_protocol#/#relm3.auto_host#/guid/#collecting_event.locality_id#">
											#collecting_event.locality_id#</a>
									</div>
									<div class="col-12 col-md-4 py-2 border-right small">
										<div class="row mx-0">
											<h3 class="h5 mb-0">Verbatim Date</h3>
											<div class="col-12 pt-1 pb-2">#collecting_event.verbatim_date#</div>
										</div>
										<div class="row mx-0">
											<h3 class="h5 mb-0">Verbatim Locality</h3>
											<div class="col-12 pt-1 pb-2">#collecting_event.verbatim_locality#</div>
										</div>
										<div class="row mx-0">
											<h3 class="h5 mb-0">Collecting Source</h3>
											<div class="col-12 pt-1 pb-2">#collecting_event.collecting_source#</div>
										</div>
									</div>
									<div class="col-12 col-md-6 p-1">
										<cfif relm3.recordcount lte #maxMedia#>
											<cfloop query="relm3">
												<div class="border-light col-md-6 col-lg-4 col-xl-4 p-1 float-left"> 
													<cfif len(collecting_event.collecting_event_id) gt 0>
														<cfif relm3.media_id eq '#media.media_id#'> 
															<cfset activeimg = "border-warning bg-white float-left border-left px-1 pt-2 border-right border-bottom border-top">
														<cfelse>	
															<cfset activeimg = "border-lt-gray bg-white float-left px-1 pt-2">
														</cfif>
														<cfset mediablock= getMediaBlockHtml(media_id="#relm3.media_id#",displayAs="fixedSmallThumb",size="75",captionAs="textLinks",background_color="white")>
														<div class="#activeimg#" id="mediaBlock#relm.media_id#">
															<div class="col-5 bg-white px-1 float-left"> #mediablock# </div>
															<cfset showTitleText1 = trim(title1)>
																<cfif len(showTitleText1) gt 100><cfset showTitleText1 = "#left(showTitleText1,100)#..." ><cfelse><cfset showTitleText1 = "#showTitleText1#" ></cfif>
															<div class="col-7 bg-white px-2 pb-2 smaller float-left" style="line-height: .89rem;">#showTitleText1#</div>
														</div>
													</cfif>
												</div>
											</cfloop>
										<cfelse>
											<cfloop query="relm3">
												<div class="border-light col-md-6 col-lg-4 col-xl-3 p-1 float-left"> 
													<cfif len(collecting_event.collecting_event_id) gt 0>
														<cfif relm3.media_id eq '#media.media_id#'> 
															<cfset activeimg = "border-warning bg-white float-left border-left px-1 pt-2 border-right border-bottom border-top">
														<cfelse>	
															<cfset activeimg = "border-lt-gray bg-white float-left px-1 pt-2">
														</cfif>
														<div class="#activeimg#" id="mediaBlock#relm3.media_id#">
															<div class="col-5 bg-white px-1 float-left">
																<cfset mediablock= getMediaBlockHtml(media_id="#relm3.media_id#",displayAs="fixedSmallThumb",size="40",captionAs="textLinks",background_color="white")>#mediablock#
															</div>
															<cfset showTitleText1 = trim(title1)>
															<cfif len(showTitleText1) gt 100>
																<cfset showTitleText1 = "#left(showTitleText1,100)#..." >
															<cfelse>
																<cfset showTitleText1 = "#showTitleText1#" >
															</cfif>
															<div class="col-7 bg-white px-2 pb-2 smaller float-left" style="line-height: .89rem;">
																#showTitleText1#
															</div>
														</div>
													</cfif>
												</div>
											</cfloop>
										</cfif>
									<div id="targetDiv"></div>
								</div>
							</div>
						</cfloop>
					</div>
				<cfelse>
					<h3 class="h4 mt-3 w-100 px-2 font-italic">Not associated with Collecting Events</h3>
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
						<h1 class="h3 w-100 my-0 px-2">Permit Records with this Media</h1>
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
										<td style="width:57%; padding-left: .5rem;">
											<cfloop query="relm4">
												<div class="border-light float-left mx-1 px-0 py-1" style="width:112px;height: 202px">
												<cfif len(permit.permit_id) gt 0>
													<cfif relm4.media_id eq '#media.media_id#'> 
														<cfset activeimg = "border-warning border-left pt-2 border-right border-bottom border-top px-1">
													<cfelse>	
														<cfset activeimg = "border-light pt-2">
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
						<h1 class="h3 w-100 my-0 px-2">Borrow Records with this Media</h1>
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
										<td style="width:60%;padding-left: .5rem;">
											<cfloop query="relm5">
												<div class="border-light float-left mx-1 px-0 py-1" style="width:112px;height: 202px">
												<cfif len(borrow.transaction_id) gt 0>
													<cfif relm5.media_id eq '#media.media_id#'> 
														<cfset activeimg = "border-warning border-left border-right pt-2 border-bottom border-top px-1">
													<cfelse>	
														<cfset activeimg = "border-light pt-2">
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
						select *
						from deaccession 
							left join media_relations on media_relations.related_primary_key = deaccession.transaction_id
						where media_relations.media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
							and (media_relations.media_relationship = 'documents deaccession')
					</cfquery>
					<cfif len(deaccession.transaction_id) gt 0>
						<h1 class="h3 w-100 my-0 px-2">Deaccession Records with this Media</h1>
						<div class="col-12 px-0">
						<cfquery name="relm6" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select distinct media.media_id, preview_uri, media.media_uri, media.mime_type, media.media_type, media.auto_protocol, media.auto_host
						from media_relations
							 left join media on media_relations.media_id = media.media_id
						where related_primary_key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#deaccession.transaction_id#">
						</cfquery>
							<table class="search-box table table-responsive mt-1 w-100">
								<thead class="search-box-header mt-1">
									<tr class="text-white">
										<th>Deaccession&nbsp;Number</th>
										<th>Deaccesion&nbsp;Type</th>
										<th>Deaccession&nbsp;Status</th>
										<th>Deaccession&nbsp;Reason</th>
										<th>Method</th>
										<th>Image&nbsp;Thumbnail(s)</th>
										
									</tr>
								</thead>
								<tbody>
									<tr>
										<td>#deaccession.transaction_id#</td>
										<td>#deaccession.deacc_number#</td>
										<td>#deaccession.deacc_type#</td>
										<td>#deaccession.deacc_status#</td>
										<td>#deaccession.deacc_reason#</td>
										<td>#deaccession.method#</td>
										<td style="width:57%; padding-left: 0.5rem;">
											<cfloop query="relm6">
												<div class="border-light float-left mx-1 px-0 py-1" style="width:112px;height: 202px">
												<cfif len(deaccession.transaction_id) gt 0>
													<cfif relm6.media_id eq '#media.media_id#'> 
														<cfset activeimg = "border-warning border-left border-right px-1 border-bottom border-top">
													<cfelse>	
														<cfset activeimg = "border-light px-1">
													</cfif>
													<cfset mediablock= getMediaBlockHtml(media_id="#relm6.media_id#",displayAs="thumb",size='100',captionAs="textMid")>
													<div class="float-left #activeimg#" id="mediaBlock#relm6.media_id#"> #mediablock# </div>
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
				<!---Loan records--->			
				<div class="row mx-0">
					<cfquery name="loan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select *
						from loan 
							left join media_relations on media_relations.related_primary_key = loan.transaction_id
						where media_relations.media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
							and (media_relations.media_relationship = 'documents loan')
					</cfquery>
					<cfif len(loan.transaction_id) gt 0>
						<h1 class="h3 w-100 my-0 px-2">Loan Records with this Media</h1>
						<div class="col-12 px-0">
						<cfquery name="relm7" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select distinct media.media_id, preview_uri, media.media_uri, media.mime_type, media.media_type, media.auto_protocol, media.auto_host
						from media_relations
							 left join media on media_relations.media_id = media.media_id
						where related_primary_key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#loan.transaction_id#">
						</cfquery>
							<table class="search-box table table-responsive mt-1 w-100">
								<thead class="search-box-header mt-1">
									<tr class="text-white">
										<th>Loan&nbsp;Number</th>
										<th>Loan&nbsp;Type</th>
										<th>Loan&nbsp;Status</th>
										<th>Loan&nbsp;Description</th>
										<th>Loan&nbsp;Instructions</th>
										<th>Image&nbsp;Thumbnail(s)</th>
										
									</tr>
								</thead>
								<tbody>
									<tr>
										<td>#loan.transaction_id#</td>
										<td>#loan.loan_number#</td>
										<td>#loan.loan_type#</td>
										<td>#loan.loan_status#</td>
										<td>#loan.loan_description#</td>
										<td>#loan.instructions#</td>
										<td style="width:57%; padding-left: 0.5rem;">
											<cfloop query="relm7">
												<div class="border-light float-left mx-1 px-0 py-1" style="width:112px;height: 202px">
												<cfif len(loan.transaction_id) gt 0>
													<cfif relm7.media_id eq '#media.media_id#'> 
														<cfset activeimg = "border-warning border-left border-right px-1 border-bottom border-top">
													<cfelse>	
														<cfset activeimg = "border-light px-1">
													</cfif>
													<cfset mediablock= getMediaBlockHtml(media_id="#relm7.media_id#",displayAs="thumb",size='100',captionAs="textMid")>
													<div class="float-left #activeimg#" id="mediaBlock#relm7.media_id#"> #mediablock# </div>
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
