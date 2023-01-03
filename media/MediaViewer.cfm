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
		media.media_id IN <cfqueryparam cfsqltype="CF_SQL_DECiMAL" value="#media_id#" list="yes">
		AND MCZBASE.is_media_encumbered(media_id)  < 1 
	</cfquery>
		<style>
			.viewer {width: auto; height: auto;margin:auto;}
			.viewer img {box-shadow: 8px 2px 30px black;margin-bottom: .5em;}
			.slider {height: auto;}
		</style>

	<main class="container-fluid" id="content">
		<div class="row mx-0">
			<div class="col-12 pb-4">
			<cfloop query="media">
				<div class="row mx-0">
					<div class="col-12 px-2 mt-3">
						<h1 class="h2 mt-4 col-7 float-left px-0 text-center pb-0 mb-0">Media Viewer</h1>
					</div>
					<div class="col-12 px-0 px-xl-2 my-2">
						<div class="viewer">
						<cfif len(media.media_id) gt 0>
							<div class="rounded border bg-light col-12 col-sm-8 col-md-6 col-xl-7 float-left mb-2 px-4 pt-3 pb-0">
								<cfset mediablock= getMediaBlockHtml(media_id="#media_id#",size="900",captionAs="textLinks")>
								<div class="mx-auto text-center pt-1" id="mediaBlock#media.media_id#"> #mediablock# </div>
							</div>
						</cfif>
						</div>
						<div class="col-12 col-sm-8 col-md-6 col-xl-5 px-4 float-left mb-2 pt-0 pb-0">
							<cfset mediaMetadataBlock= getMediaMetadata(media_id="#media_id#")>
							<div id="mediaMetadataBlock#media_id#">
								#mediaMetadataBlock#
							</div>
						</div>
							
						<!---specimen records--->
						<cfquery name="spec" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select distinct media_id,flat.collection_object_id as pk, flat.collectors as agent, collecting_event.verbatim_locality as collecting_event
						from media_relations
							left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat on related_primary_key = collection_object_id
							left join collecting_event on flat.collecting_event_id = collecting_event.collecting_event_id
						where media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media.media_id#"> 
								and (media_relations.media_relationship like '%cataloged_item%' OR media_relations.media_relationship like '%collecting_event%')
						</cfquery>
						<cfif len(spec.pk) gt 0>
							<div class="col-12 col-xl-12 px-0 float-left">
								<div class="search-box mt-4 w-100">
									<div class="search-box-header px-2 mt-0 mediaTableHeader">
										<ul class="list-group list-group-horizontal text-white">
											<li class="col-12 px-1 list-group-item mb-0 h4">Related Media Record(s) </li>
										</ul>
									</div>
									<div>
										<!---<cfloop query="spec">--->
											<div class="row mx-0 border-bottom border-gray">
												<div class="col-12 p-1">
														<cfquery name="relm" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
															select distinct media.media_id, preview_uri, media.media_uri,
																get_medialabel(media.media_id,'height') height, get_medialabel(media.media_id,'width') width,
																media.mime_type, media.media_type, media.auto_protocol, media.auto_host
															from media_relations
																 left join media on media_relations.media_id = media.media_id
																 left join ctmedia_license on media.media_license_id = ctmedia_license.media_license_id
															where (media_relationship like '%cataloged_item%' OR media_relationship like '%collecting_event%' OR media_relationship like '%agent%')
																AND related_primary_key = <cfqueryparam value=#spec.pk# CFSQLType="CF_SQL_DECIMAL" >
																AND MCZBASE.is_media_encumbered(media.media_id)  < 1
														</cfquery>
															<cfset i= 1>
															<cfloop query="relm">
															<div class="border-light w-100 col-md-3 col-lg-2 col-xl-2 px-1 float-left">
																<cfif len(media.media_id) gt 0>
																	<cfif relm.media_id eq '#media.media_id#'> 
																		<cfset activeimg = "border-warning bg-white float-left border-left px-1 pt-2 border-right border-bottom border-top">
																	<cfelse>	
																		<cfset activeimg = "border-lt-gray bg-white float-left px-1 pt-2">
																	</cfif>
																<ul class="list-group px-0">
																	<li class="list-group-item px-0 mx-1">
																	<cfset mediablock= getMediaBlockHtml(media_id="#relm.media_id#",displayAs="thumb",size='70',captionAs="textCaptionFull")>
																	<div class="#activeimg# image#i#" id="mediaBlock#relm.media_id#">
																		<div class="bg-white px-0 float-left" style="min-height: 135px;"> #mediablock#</div>
																	</div>
																	</li>
																</ul>
																</cfif>
															</div>
															<cfset i=i+1>
															</cfloop>
													<div id="targetDiv"></div>
												</div>
											</div>
								<!---		</cfloop>--->
									</div>
								</div>
							</div>
						<cfelse>
							<div class="col-auto px-2 float-left">
								<h3 class="h4 mt-3 w-100 px-4 font-italic">Not associated with Specimen Records</h3>
							</div>
						</cfif>
					</div>
							
				</div>

				
				<!--- accn records --->
	<!---			<div class="row mx-0">
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
							media.mime_type, media.media_type, media.auto_protocol, media.auto_host
						from media_relations
							 left join media on media_relations.media_id = media.media_id
						where related_primary_key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#accn.transaction_id#">
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
										<td><a href="##">#accn.transaction_id#</a></td>
										<td>#accn.accn_num_suffix#</td>
										<td>#accn.accn_type#</td>
										<td>#accn.accn_number#</td>
										<td>#accn.accn_status#</td>
										<td style="width:10%">#accn.received_agent#</td>
										<td style="width:57%; padding-left:0.75rem;">
											<cfloop query="relm2">
												<div class="border-light float-left mx-1 px-0 py-1" style="width:112px;height: 202px">
												<cfif len(accn.transaction_id) gt 0>
													<cfif relm2.media_id eq '#media.media_id#'> 
														<cfset activeimg = "border-warning border-left px-1 pt-2 border-right border-bottom border-top">
													<cfelse>	
														<cfset activeimg = "border-light px-1 pt-2">
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
				</div>--->
				<!--- collecting event records --->
			<!---	<div class="row mx-0">
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
						select distinct media.media_id, preview_uri, media.media_uri, media.mime_type, media.media_type, media.auto_protocol, media.auto_host
						from media_relations
							 left join media on media_relations.media_id = media.media_id
						where related_primary_key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collecting_event.collecting_event_id#">
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
										<td>#collecting_event.collecting_event_id#</td>
										<td>#collecting_event.locality_id#</td>
										<td>#collecting_event.verbatim_date#</td>
										<td>#collecting_event.verbatim_locality#</td>
										<td>#collecting_event.collecting_source#</td>
										<td style="width:57%;padding-left: .5rem;">
											<cfloop query="relm3">
												<div class="border-light float-left mx-1 px-0 py-1" style="width:112px;height: 202px">
												<cfif len(collecting_event.collecting_event_id) gt 0>
													<cfif relm3.media_id eq '#media.media_id#'> 
														<cfset activeimg = "border-warning border-left border-right border-bottom pt-1 px-1 border-top">
													<cfelse>	
														<cfset activeimg = "border-light px-1">
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
				</div>--->
				<!---Permit records--->
			<!---	<div class="row mx-0">
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
				</div>--->
				<!---Borrow records--->			
		<!---		<div class="row mx-0">
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
				</div>--->
				<!---Deaccession records--->			
				<!---<div class="row mx-0">
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
				</div>--->
				<!---Loan records--->			
			<!---	<div class="row mx-0">
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
				</div>--->
			</cfloop>
			</div>
			</div>
		</div>
	</main>
</cfoutput>
	
	
<cfinclude template="/shared/_footer.cfm">
