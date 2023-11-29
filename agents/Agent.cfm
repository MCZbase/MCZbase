<cfset pageTitle = "Agent Details">
<!--
agents/Agent.cfm

Form for displaying agent details, editing agent details, and creating new agents.

Copyright 2020 President and Fellows of Harvard College

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

-->

<cfif isdefined("agent_id")>
	<cfif len(agent_id) GT 0 and REFind("^[0-9]*$",agent_id) EQ 0>
		<cfinclude template="/errors/autoblacklist.cfm">
		<cfabort>
	</cfif>
<cfelse>
	<!--- if no agent_id was given, then assume we want agent search. --->
	<cflocation url="/Agents.cfm">
</cfif>
<cfinclude template = "/shared/_header.cfm">
<cfinclude template="/media/component/search.cfc" runOnce="true"><!--- ? unused ? remove ? --->
<cfinclude template="/media/component/public.cfc" runOnce="true"><!--- for getMediaBlockHtml ---><!--- ? unused ? remove ? --->
<cfinclude template="/agents/component/functions.cfc" runOnce="true">
<cfif not isdefined("session.sdmapclass") or len(session.sdmapclass) is 0>
	<cfset session.sdmapclass='tinymap'>
</cfif>
<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
	<cfset oneOfUs = 1>
<cfelse>
	<cfset oneOfUs = 0>
</cfif>
<cfquery name="ctguid_type_agent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	SELECT guid_type, placeholder, pattern_regex, resolver_regex, resolver_replacement, search_uri
	FROM ctguid_type 
	WHERE applies_to like '%agent.agentguid%'
</cfquery>
<cfif len(agent_id) EQ 0>
	<cfthrow message="No Agent specified to show agent details for.  No Agent ID was provided.">
</cfif>
<cfquery name="getAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	SELECT 
		agent.agent_id,
		agent.agent_type, 
		agent.edited as vetted, 
		agent_remarks, 
		biography,
		agentguid_guid_type, agentguid,
		prefername.agent_name as preferred_agent_name,
		person.prefix,
		person.suffix,
		person.first_name,
		person.last_name,
		person.middle_name,
		person.birth_date,
		person.death_date,
		null as start_date,
		null as end_date,
		MCZBASE.get_collectorscope(agent.agent_id,'all') as collections_scope
	FROM 
		agent
		join agent_name prefername on agent.preferred_agent_name_id = prefername.agent_name_id
		left join person on agent.agent_id = person.person_id
	WHERE
		agent.agent_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#agent_id#">
</cfquery>
<cfquery name="points" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="points_result" cachedwithin="#CreateTimespan(0,24,0,0)#" timeout="#Application.query_timeout#">
	SELECT distinct flat.locality_id,flat.dec_lat as Latitude,flat.DEC_LONG as Longitude 
	FROM <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat
		left join collector on collector.collection_object_id = flat.collection_object_id
		left join agent on agent.agent_id = collector.agent_id
	WHERE 
		collector.agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
		and collector.collector_role = 'c'
		and flat.guid IS NOT NULL
		and flat.dec_lat is not null
	and collector.collector_role = 'c'
		
</cfquery>

<cfoutput>
	<cfquery name="getMedia" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getMedia_result" cachedwithin="#CreateTimespan(0,24,0,0)#" timeout="#Application.query_timeout#">
	SELECT media.media_id,
		mczbase.get_media_descriptor(media.media_id) as alt,
		mczbase.get_medialabel(media.media_id,'subject') as subject,
		media.media_uri,
		media.preview_uri,
		media.media_type,
		MCZBASE.get_media_dctermsrights(media.media_id) as license_uri, 
		MCZBASE.get_media_dcrights(media.media_id) as license_display, 
		MCZBASE.get_media_credit(media.media_id) as credit 
	FROM media_relations 
		left join media on media_relations.media_id = media.media_id
		left join ctmedia_license on media.media_license_id=ctmedia_license.media_license_id
	WHERE media_relationship like 'shows agent'
		and media.auto_host = 'mczbase.mcz.harvard.edu'
		and related_primary_key=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
		and mczbase.is_media_encumbered(media.media_id) < 1
</cfquery>
<cfset imageSetMetadata = "[]">
<cfif getMedia.recordcount GT 0>
	<cfset imageSetMetadata = "[">
	<cfset comma = "">
	<cfloop query="getMedia">
		<cfset altEscaped = replace(replace(alt,"'","&##8217;","all"),'"',"&quot;","all") >
		<cfset imageSetMetadata = '#imageSetMetadata##comma#{"media_id":"#getMedia.media_id#","media_uri":"#getMedia.media_uri#","alt":"#altEscaped#"}'>
		<cfset comma = ",">
	</cfloop>
	<cfset imageSetMetadata = "#imageSetMetadata#]">
</cfif>
<script>
	var agentImageSetMetadata = JSON.parse('#imageSetMetadata#');
	var currentAgentImage = 1;
</script>
	<main class="container-xl px-0" id="content">
		<div class="row mx-0">
			<cfloop query="getAgent">
				<cfset prefName = getAgent.preferred_agent_name>
				<div id="agentTopDiv" class="col-12 mt-3">
					<!--- agent name, biography, remarks as one wide section across top of page --->
					<div class="row mx-0">
						<div class="col-12 col-md-12 px-3">
							<cfset dates ="">
							<cfif getAgent.agent_type EQ "person">
								<cfif oneOfUs EQ 1 OR len(getAgent.death_date) GT 0>
									<!--- add birth death dates --->
									<cfset dates = assembleYearRange(start_year="#getAgent.birth_date#",end_year="#getAgent.death_date#",year_only=false) >
								</cfif>
							<cfelse>
								<!--- add start and end years when implemented --->
								<cfset dates = assembleYearRange(start_year="#getAgent.start_date#",end_year="#getAgent.end_date#",year_only=true) >
							</cfif>
							<cfif getAgent.vetted EQ 1 ><cfset vetted_marker="*"><cfelse><cfset vetted_marker=""></cfif> 
							<cfif oneOfUs EQ 1><cfset agent_id_bit = " [Agent ID: #getAgent.agent_id#]"><cfelse><cfset agent_id_bit=""></cfif>
							<cfset rankBit ="">
 							<cfif listcontainsnocase(session.roles, "manage_transactions")>
								<cfquery name="rank" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
									SELECT count(*) || ' ' || agent_rank agent_rank
									FROM agent_rank
									WHERE agent_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
									group by agent_rank
								</cfquery>
								<cfif rank.recordcount gt 0>
									<cfset rankBit= ' <span id="agentRankSummary" style="font-size: 13px;margin: 1em 0;">'><!--- ' --->
									<cfset rankBit = '#rankBit#Ranking: #valuelist(rank.agent_rank,"; ")#'>
									<cfif #valuelist(rank.agent_rank,"; ")# contains 'F'>
										<cfset rankBit = "#rankBit#<img src='/agents/images/flag-red.svg.png' width='16'>"><!--- " --->
									<cfelseif #valuelist(rank.agent_rank,"; ")# contains 'D'>
										<cfset rankBit = "#rankBit#<img src='/agents/images/flag-yellow.svg.png' width='16'>"><!--- " --->
									<cfelseif #valuelist(rank.agent_rank,"; ")# contains 'C'>
										<cfset rankBit = "#rankBit#<img src='/agents/images/flag-yellow.svg.png' width='16'>"><!--- " --->
									<cfelseif #valuelist(rank.agent_rank,"; ")# contains 'B'>
										<cfset rankBit = "#rankBit#<img src='/agents/images/flag-yellow.svg.png' width='16'>"><!--- " --->
									</cfif>
									<cfset rankBit = '#rankBit#</span>'><!--- ' --->
								</cfif>
							</cfif>
							<h1 class="h2 mt-2 mb-2">#preferred_agent_name##vetted_marker# <span class="h4 my-0"> #dates# #agent_type# #agent_id_bit##rankBit#</span> 
								<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_agents")>
								<a href="/agents/editAgent.cfm?agent_id=#agent_id#" class="btn btn-primary btn-xs float-right">Edit</a>
								</cfif>
							</h1>
							<ul class="list-group py-0 list-unstyled px-0">
								<cfif len(agentguid) GT 0>
									<cfif len(ctguid_type_agent.resolver_regex) GT 0>
										<cfset guidLink = REReplace(agentguid,ctguid_type_agent.resolver_regex,ctguid_type_agent.resolver_replacement) >
									<cfelse>
										<cfset guidLink = agentguid >
									</cfif>
									<cfset icon="">
									<cfif agentguid_guid_type EQ 'ORCiD'>
										<cfset icon="<img src='/shared/images/ORCIDiD_icon.svg' height='15' width='15' class='mr-1' alt='ORCID iD icon'>"><!--- " --->
									</cfif>
									<li class="list-group-item border-bottom-0 px-0 pt-0 pb-2">
										<a href="#guidLink#">#icon##agentguid#</a>
									</li>
								</cfif>
							</ul>
							<div class="col-12 col-md-11 px-0 mb-0">
								#biography#
							</div>
						</div>
					</div>
					<cfif oneOfUs EQ 1>
						<cfquery name="getDupAgentRel" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getDupAgentRel_result">
							SELECT agent_relationship, related_agent_id, MCZBASE.get_agentnameoftype(related_agent_id) as related_name,
								agent_remarks,
								date_to_merge, on_hold, held_by
							FROM agent_relations 
								WHERE
									agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
									and agent_relationship like '% duplicate of'
								ORDER BY agent_relationship
						</cfquery>
						<cfquery name="getDupAgentRelRev" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getDupAgentRel_result">
							SELECT agent_relationship, agent_id as related_agent_id, MCZBASE.get_agentnameoftype(agent_id) as related_name,
								agent_remarks,
								date_to_merge, on_hold, held_by
							FROM agent_relations 
								WHERE
									related_agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
									and agent_relationship like '% duplicate of'
								ORDER BY agent_relationship
						</cfquery>
						<cfif getDupAgentRel.recordcount GT 0 OR getDupAgentRelRev.recordcount GT 0>
							<div class="row mx-0">
								<cfif getDupAgentRel.recordcount GT 0>
									<ul class="px-3 list-inline">
										<cfloop query="getDupAgentRel">
											<cfif len(on_hold) GT 0><cfset hold="put on hold by"><cfelse><cfset hold=""></cfif>
											<li class="list-inline-item">
												#prefName# is a #getDupAgentRel.agent_relationship# 
												<a href="/agents/Agent.cfm?agent_id=#getDupAgentRel.related_agent_id#">#getDupAgentRel.related_name#</a>
												<cfif len(date_to_merge) GT 0>
													set to merge: #dateformat(date_to_merge,"yyyy-mm-dd")#
												</cfif>
												#hold# #held_by#
											</li>
										</cfloop>
									</ul>
								</cfif>
								<cfif getDupAgentRelRev.recordcount GT 0>
									<ul class="px-3 list-inline">
										<cfloop query="getDupAgentRelRev">
											<cfif len(on_hold) GT 0><cfset hold="put on hold by"><cfelse><cfset hold=""></cfif>
											<li class="list-inline-item">
												<a href="/agents/Agent.cfm?agent_id=#getDupAgentRelRev.related_agent_id#">#getDupAgentRelRev.related_name#</a>
												is a #getDupAgentRelRev.agent_relationship# #prefName#
												<cfif len(date_to_merge) GT 0>
													set to merge into this record: #dateformat(date_to_merge,"yyyy-mm-dd")# 
												</cfif>
												#hold# #held_by#
											</li>
										</cfloop>
									</ul>
								</cfif>
							</div>
						</cfif>
					</cfif>
					<!--- full width, biograhy and remarks, presented with no headings --->
					<div class="row mx-0">
						<cfif oneOfUs EQ 1>
							<cfif len(agent_remarks) GT 0>
								<section class="accordion w-100 mx-1 mt-2" id="internalSection">
								<div class="col-12 card bg-light mb-0 px-0">
									<div class="card-header py-0" id="internalHeader">
										<h2 class="h4 my-0">
											<button type="button" class="headerLnk text-left w-100 h-100 collapsed" data-toggle="collapse" data-target="##internalCardBodyWrap" aria-expanded="false" aria-controls="internalCardBodyWrap">Internal Remarks
											</button>
										</h2>
									</div>
									<div class="card-body px-3 py-2 collapse" id="internalCardBodyWrap" aria-controls="internalCardBodyWrap">
										<span class="small90">#agent_remarks#</span>
									</div>
								</div>
								</section>
							</cfif>
						</cfif>
					</div>
				</div>
				<!--- three columns of information about the agent gleaned from related tables --->
				<div class="col-12 mt-2" id="agentBlocks">
					<div class="row mx-0">
						<div class="d-block mb-0 mb-xl-5 float-left px-0 px-md-1 col-12 col-md-3 col-xl-3 rounded rounded h-auto">
							<!--- agent names --->
							<section class="accordion">
								<div class="card mb-2 bg-light">
									<!--- always open, not a collapsable card --->
									<div class="card-header py-0">
										<h2 class="h4 my-1 text-dark-gray mx-2 px-2">Names for this agent</h2>
									</div>
									<cfquery name="preferredNames" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="preferredNames_result">
										SELECT
											agent_name_id,
											agent_id,
											agent_name_type,
											agent_name
										FROM agent_name
										WHERE agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
											AND agent_name_type = 'preferred'
									</cfquery>
									<cfquery name="notPrefNames" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="notPrefNames_result">
										SELECT
											agent_name_id,
											agent_id,
											agent_name_type,
											agent_name
										FROM agent_name
										WHERE agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
											AND agent_name_type <> 'preferred'
									</cfquery>
									<div class="card-body py-2 bg-teal">	
										<ul class="list-group">
											<!--- person name --->
											<cfif getAgent.agent_type EQ "person">
												<li class="list-group-item" >#getAgent.prefix# #getAgent.first_name# #getAgent.middle_name# #getAgent.last_name# #getAgent.suffix#</li>
											</cfif>
											<!--- preferred name --->
											<cfloop query="preferredNames">
												<li class="list-group-item" >#preferredNames.agent_name# (#preferredNames.agent_name_type#)</li>
											</cfloop>
											<cfloop query="notPrefNames">
												<cfif isdefined("session.roles") and listfindnocase(session.roles,"global_admin")>
													<li class="list-group-item">#notPrefNames.agent_name# (#notPrefNames.agent_name_type#)</li>
												<cfelse>
													<!--- don't display login name to non-admin users --->
													<cfif notPrefNames.agent_name_type NEQ "login">
														<li class="list-group-item">#notPrefNames.agent_name# (#notPrefNames.agent_name_type#)</li>
													</cfif>
												</cfif>
											</cfloop>
										</ul>
									</div>
								</div>
							</section>
							<!--- group members (members within this group agent) --->
							<cfif #getAgent.agent_type# IS "group" OR #getAgent.agent_type# IS "expedition" OR #getAgent.agent_type# IS "vessel">
								<section class="accordion" id="groupMembersSection">
									<div class="card mb-2 bg-light">
										<cfquery name="groupMembers" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="groupMembers_result">
											SELECT
												member_agent_id,
												member_order,
												agent_name,
												MCZBASE.get_collectorscope(member_agent_id,'all') member_scope
											FROM
												group_member 
												left join preferred_agent_name on group_member.MEMBER_AGENT_ID = preferred_agent_name.agent_id
											WHERE
												group_agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
											ORDER BY
												member_order
										</cfquery>
										<cfif groupMembers.recordcount GT 20 OR groupMembers.recordcount eq 0>
											<!--- cardState = collapsed --->
											<cfset bodyClass = "collapse">
											<cfset ariaExpanded ="false">
										<cfelse>
											<!--- cardState = expanded --->
											<cfset bodyClass = "collapse show">
											<cfset ariaExpanded ="true">
										</cfif>
										<cfif groupMembers.recordcount EQ 1><cfset plural=""><cfelse><cfset plural="s"></cfif>
										<div class="card-header" id="groupMembersHeader">
											<h2 class="h4 my-0">
												<button type="button" class="headerLnk text-left w-100 h-100" data-toggle="collapse" data-target="##groupMembersCardBodyWrap" aria-expanded="#ariaExpanded#" aria-controls="groupMembersCardBodyWrap">
												Group Members (#groupMembers.recordcount#)
												</button>
											</h2>
										</div>
										<div id="groupMembersCardBodyWrap" class="#bodyClass#" aria-labelledby="groupMembersHeader" data-parent="##groupMembersSection">
											<cfif groupMembers.recordcount GT 0>
												<h3 class="small95 mt-2 px-3 mb-0">#prefName# consists of #groupMembers.recordcount# member#plural#</h3>
											</cfif>
											<div class="card-body pb-1 mb-1">
												<cfif groupMembers.recordcount EQ 0>
													<ul class="list-group">
														<li class="list-group-item">None</li>
													</ul>
												<cfelse>
													<ul class="list-group">
														<cfloop query="groupMembers">
															<li class="list-group-item">
																<a href="/agents/Agent.cfm?agent_id=#groupMembers.member_agent_id#">#groupMembers.agent_name#</a>
																#member_scope#
															</li>
														</cfloop>
													</ul>
												</cfif>
											</div>
										</div>
									</div>
								</section>
							</cfif>
							<!--- Media --->
							<section class="accordion" id="mediaSection"> 
								<div class="card mb-2 bg-light">
									
									<cfif getMedia.recordcount LT 1>
										<!--- cardState = collapsed --->
										<cfset bodyClass = "collapse">
										<cfset ariaExpanded ="false">
									<cfelse>
										<!--- cardState = expanded --->
										<cfset bodyClass = "collapse show">
										<cfset ariaExpanded ="true">
									</cfif>
									<div class="card-header" id="mediaHeader">
										<cfif getMedia.recordcount EQ 1><cfset plural =""><cfelse><cfset plural="s"></cfif>
										<h2 class="h4 my-0">
											<button type="button" class="headerLnk text-left w-100 h-100" data-toggle="collapse" data-target="##mediaCardBodyWrap" aria-expanded="#ariaExpanded#" aria-controls="mediaCardBodyWrap">
												Subject of #getMedia.recordcount# Media Record#plural#
											</button>
										</h2>
									</div>
									<div id="mediaCardBodyWrap" class="#bodyClass# px-2" aria-labelledby="mediaHeader" data-parent="##mediaSection">
										<cfif getMedia.recordcount eq 0>
											<ul class="list-group">
												<li class="list-group-item py-2">No media showing this agent</li>
											</ul>
										<cfelse>
											<!---For getMediaBlockHtml variables: use size that expands img to container with max-width: 350px so it look good on desktop and phone; --without displayAs-- captionAs="textCaption" (truncated to 50 characters) --->
											<cfif getMedia.recordcount GT 0>
													<cfset agentCt = getMedia.recordcount>
													<cfloop query="getMedia" startRow="1" endRow="1">
														<cfset agent_media_uri = getMedia.media_uri>
														<cfset agent_media_id = getMedia.media_id>
														<cfset agent_alt = getMedia.alt>
													</cfloop>
													<div class="col-12 px-0 mx-md-auto my-2"><!---just for agent block--->
														<div class="carousel_background border rounded">
															<div class="vslider w-100 float-left bg-light" id="vslider-base1">
																<cfset i=1>
																<div class="w-100 float-left px-2 h-auto">
																	<!---The href is determined by shared-scripts.js goImageByNumber function --placeholder is here--->
																	<cfset sizeType='&width=1000&height=1000'>
																	<a id="agent_detail_a" class="d-block pt-2" href="/media/#agent_media_id#">Media Details</a>
																	<a id="agent_media_a" href="#agent_media_uri#" class="d-block my-1 w-100" title="click to open full image">
																		<img id="agent_media_img" src="/media/rescaleImage.cfm?media_id=#agent_media_id##sizeType#" class="mx-auto" alt="#agent_alt#" height="100%" width="100%">
																	</a>
																	<p id="agent_media_desc" class="mt-2 small bg-light">#agent_alt#</p>
																</div>
															</div>
															<div class="custom-nav text-center small bg-white mb-0 pt-0 pb-1">
																<button id="previous_agent_image" type="button" class="border-0 btn-outline-primary rounded">&lt;&nbsp;prev </button>
																<input id="agent_image_number" type="number" class="custom-input data-entry-input d-inline border border-light" value="1">
																<button id="next_agent_image" type="button" class="border-0 btn-outline-primary rounded"> next&nbsp;&gt;</button>
															</div>
															<div class="w-100 text-center smaller pb-1">of #agentCt#</div>
															<script>
																var $inputAgent = document.getElementById('agent_image_number');
																var $prevAgent = document.getElementById('previous_agent_image');
																var $nextAgent = document.getElementById('next_agent_image');
																function goPreviousAgent() { 
																	currentAgentImage = goPreviousImage(currentAgentImage, agentImageSetMetadata, "agent_media_img", "agent_media_desc", "agent_detail_a", "agent_media_a", "agent_image_number","#sizeType#"); 
																}
																function goNextAgent() { 
																	currentAgentImage = goNextImage(currentAgentImage, agentImageSetMetadata, "agent_media_img", "agent_media_desc", "agent_detail_a", "agent_media_a", "agent_image_number","#sizeType#"); 
																}
																function goAgent() { 
																	currentAgentImage = goImageByNumber(currentAgentImage, agentImageSetMetadata, "agent_media_img", "agent_media_desc", "agent_detail_a", "agent_media_a", "agent_image_number","#sizeType#");
																}
																$(document).ready(function () {
																	$inputAgent.addEventListener('change', function (e) {
																		goAgent()
																	}, false)
																	$prevAgent.addEventListener('click', function (e) {
																		goPreviousAgent()
																	}, false)
																	$nextAgent.addEventListener('click', function (e) {
																		goNextAgent()
																	}, false)
																	$("##agent_media_img").scrollTop(function (event) {
																		event.preventDefault();
																		var ya = event.scrollTop;
																		if (ya > $nextAgent) { 
																			currentAgentImage = 0;
																		} else { 
																			goPreviousAgent();
																		}
																	});
																});
															</script>
														</div>
													</div>
											
												</cfif>
										</cfif>
									</div><!--- end mediaCardBodyWrap --->
								</div>
								<script>
								//  carousel fix for specimen images on small screens below.  I tried to fix this with the ratio select added to the query but that only works if there are a lot of images to choose from; for small images pools, where the most common ratio cannot be selected, this may still help.	
								$(window).on('load resize', function () {
									var w = $(window).width();
									$("##vslider-item")
										.css('max-height', w > 1280 ? 685 : w > 480 ? 400 : 315);
								});
								</script>
							</section>
							<!--- emails/phone numbers --->
							<cfif oneOfUs EQ 1>
								<section class="accordion" id="eaddressSection"> 
									<div class="card mb-2 bg-light">
										<cfquery name="getAgentElecAddr" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
											select address_type, address 
											from electronic_address 
											WHERE
												electronic_address.agent_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#agent_id#">
											order by address_type
										</cfquery>
										<div class="card-header" id="elecAddrHeader">
											<h2 class="h4 my-0">
												<button type="button" class="headerLnk text-left w-100 h-100" data-toggle="collapse" data-target="##elecAddrCardBodyWrap" aria-expanded="true" aria-controls="elecAddrCardBodyWrap">
												Phone/Email
												</button>
											</h2>
										</div>
										<div id="elecAddrCardBodyWrap" class="collapse show" aria-labelledby="elecAddrHeader" data-parent="##eaddressSection">
											<div class="card-body pb-1 mb-1">
												<cfif getAgentElecAddr.recordcount EQ 0>
													<ul class="list-group">
														<li class="list-group-item">None</li>
													</ul>
												<cfelse>
													<ul class="list-group">
														<cfloop query="getAgentElecAddr">
															<li class="list-group-item">#address_type#: #address#</li>
														</cfloop>
													</ul>
												</cfif>
											</div>
										</div><!--- end elecAddrCardBodyWrap --->
									</div>
								</section>
							</cfif>
							<!--- mailing addresses --->
							<cfif oneOfUs EQ 1>
								<section class="accordion" id="addressSection"> 
									<div class="card mb-2 bg-light">
										<cfquery name="getAgentAddr" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
											select addr_type, 
												REPLACE(formatted_addr, CHR(10),'<br>') FORMATTED_ADDR,
												valid_addr_fg,
												addr_remarks,
												addr_id
											from addr
											WHERE
												addr.agent_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#agent_id#">
											order by addr_type, valid_addr_fg desc
										</cfquery>
										<div class="card-header" id="addressHeader">
											<h2 class="h4 my-0">
												<button type="button" class="headerLnk text-left w-100 h-100" data-toggle="collapse" data-target="##addressCardBodyWrap" aria-expanded="true" aria-controls="addressCardBodyWrap">
												Postal Addresses
												</button>
											</h2>
										</div>
										<div id="addressCardBodyWrap" class="collapse show" aria-labelledby="addressHeader" data-parent="##addressSection">
											<div class="card-body py-1 mb-1 small90">
												<cfif getAgentAddr.recordcount EQ 0>
													<ul class="list-group">
														<li class="list-group-item">None</li>
													</ul>
												<cfelse>
													<cfloop query="getAgentAddr">
														<cfset addressUse="">
														<cfif listcontainsnocase(session.roles, "manage_transactions")>
															<cfquery name="getShipmentCount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getShipmentCount_result">
																SELECT count(shipment_id) ct
																FROM shipment
																WHERE shipped_to_addr_id = <cfqueryparam value="#getAgentAddr.addr_id#" cfsqltype="CF_SQL_DECIMAL">
																	OR shipped_from_addr_id = <cfqueryparam value="#getAgentAddr.addr_id#" cfsqltype="CF_SQL_DECIMAL">
															</cfquery>
															<cfif getShipmentCount.ct GT 0>
																<cfif getShipmentCount.ct EQ 1><cfset splural=""><cfelse><cfset splural="s"></cfif>
																<cfset addressUse=" (used in #getShipmentCount.ct# shipment#splural#)">
															</cfif>
														</cfif>
														<cfif len(addr_remarks) GT 0><cfset rem=" [#addr_remarks#]"><cfelse><cfset rem=""></cfif>
														<cfif valid_addr_fg EQ 1>
															<cfset addressCurrency="Valid">
																<cfset listgroupclass="bg-verylightgreen border-green">
															<cfelse>
																<cfset addressCurrency="Invalid">
															<cfset listgroupclass="bg-light border">
														</cfif>
															<h3 class="small95 my-1 px-2"> <span class="caps">#addr_type#</span> Address &ndash;&nbsp;#addressCurrency##rem##addressUse#</h3>
														<div class="#listgroupclass# p-2 rounded w-100">#formatted_addr#</div>
													</cfloop>
												</cfif>
											</div>
										</div><!--- end addressCardBodyWrap --->
									</div>
								</section>
							</cfif>
							<!--- relationships --->
							<section class="accordion" id="relationshipsSection"> 
								<div class="card mb-2 bg-light">
									<cfquery name="getAgentRel" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
											SELECT agent_relationship, related_agent_id, MCZBASE.get_agentnameoftype(related_agent_id) as related_name,
												agent_remarks
											FROM agent_relations 
											WHERE
												agent_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#agent_id#">
												and agent_relationship not like '% duplicate of'
											ORDER BY agent_relationship
										</cfquery>
									<cfset totalRelCount = getAgentRel.recordcount>
									<cfquery name="getRevAgentRel" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
										SELECT agent_relationship, agent_id as related_agent_id, MCZBASE.get_agentnameoftype(agent_id) as related_name,
											agent_remarks
										FROM agent_relations 
										WHERE
											related_agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
											and agent_relationship not like '% duplicate of'
										ORDER BY agent_relationship
									</cfquery>
									<cfif totalRelCount GT 20 OR totalRelCount eq 0>
										<!--- cardState = collapsed --->
										<cfset bodyClass = "collapse">
										<cfset ariaExpanded ="false">
									<cfelse>
										<!--- cardState = expanded --->
										<cfset bodyClass = "collapse show">
										<cfset ariaExpanded ="true">
									</cfif>
									<cfset totalRelCount = totalRelCount + getRevAgentRel.recordcount>
									<div class="card-header" id="relationshipsHeader">
										<h2 class="h4 my-0">
											<button type="button" class="headerLnk text-left w-100 h-100" data-toggle="collapse" data-target="##relationshipsCardBodyWrap" aria-expanded="#ariaExpanded#" aria-controls="relationshipsCardBodyWrap">
											Relationships with other agents (#totalRelCount#)
											</button>
										</h2>
									</div>
									<div id="relationshipsCardBodyWrap" class="#bodyClass#" aria-labelledby="relationshipsHeader" data-parent="##relationshipsSection">
										<div class="card-body py-1 mb-1">
											<cfif getAgentRel.recordcount EQ 0>
												<ul class="list-group">
													<li class="list-group-item">None to other agents</li>
												</ul>
											<cfelse>
												<ul class="list-group">
													<cfloop query="getAgentRel">
														<cfif len(getAgentRel.agent_remarks) GT 0><cfset rem=" [#getAgentRel.agent_remarks#]"><cfelse><cfset rem=""></cfif>
														<li class="list-group-item">#agent_relationship# <a href="/agents/Agent.cfm?agent_id=#related_agent_id#">#related_name#</a>#rem#</li>
													</cfloop>
												</ul>
											</cfif>
											<cfquery name="getRevAgentRel" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
												SELECT agent_relationship, agent_id as related_agent_id, MCZBASE.get_agentnameoftype(agent_id) as related_name,
													agent_remarks
												FROM agent_relations 
												WHERE
													related_agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
													and agent_relationship not like '% duplicate of'
												ORDER BY agent_relationship
											</cfquery>
											<cfif totalRelCount EQ 0>
												<ul class="list-group">
													<li class="list-group-item">None from other agents</li>
												</ul>
											<cfelse>
												<ul class="list-group">
													<cfloop query="getRevAgentRel">
														<cfif len(getRevAgentRel.agent_remarks) GT 0>
															<cfset rem=" [#getRevAgentRel.agent_remarks#]">
																<cfelse>
															<cfset rem="">
														</cfif>
														<li class="list-group-item">
															<a href="/agents/Agent.cfm?agent_id=#related_agent_id#">#related_name#</a> #agent_relationship# #getAgent.preferred_agent_name##rem#</li>
													</cfloop>
												</ul>
											</cfif>
										</div>
									</div><!--- end relationshipsCardBodyWrap --->
								</div>
							</section>
							<!--- group membership (other agents of which this agent is a group member) --->
							<cfquery name="groupMembership" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="groupMembership_result">
									SELECT
										group_agent_id,
										member_order,
										agent_name
									FROM
										group_member 
										join preferred_agent_name on group_member.group_agent_id = preferred_agent_name.agent_id
									WHERE
										member_agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
										<cfif oneOfUs NEQ 1>
											AND agent_name not like 'MCZ%Data%'
										</cfif>
									ORDER BY
										agent_name
								</cfquery>
							<cfif groupMembership.recordcount GT 20 OR groupMembership.recordcount EQ 0>
									<!--- cardState = collapsed --->
									<cfset bodyClass = "collapse">
									<cfset ariaExpanded ="false">
								<cfelse>
									<!--- cardState = expanded --->
									<cfset bodyClass = "collapse show">
									<cfset ariaExpanded ="true">
								</cfif>
							<cfif groupMembership.recordcount GT 0 >
								<section class="accordion" id="groupMembershipSection">
									<div class="card mb-2 bg-light">
										<cfif groupMembership.recordcount EQ 1><cfset plural=""><cfelse><cfset plural="s"></cfif>
										<div class="card-header" id="groupMembershipHeader">
											<h2 class="h4 my-0">
												<button type="button" class="headerLnk text-left w-100 h-100" data-toggle="collapse" data-target="##groupMembershipCardBodyWrap" aria-expanded="#ariaExpanded#" aria-controls="groupMembershipCardBodyWrap">
													Group Membership (#groupMembership.recordcount#)
												</button>
											</h2>
										</div>
										<div id="groupMembershipCardBodyWrap" class="#bodyClass#" aria-labelledby="groupMembershipHeader" data-parent="##groupMembershipSection">
											<cfif groupMembership.recordcount GT 0>
												<h3 class="small95 mt-2 px-3 mb-0">#prefName# is a member of #groupMembership.recordcount# group#plural#</h3>
											</cfif>
											<div class="card-body pt-0 pb-1 mb-1">
												<cfif groupMembership.recordcount EQ 0>
													<!--- which won't be reached, as we hide the entire section if this is the case --->
													<ul class="list-group">
														<li class="list-group-item">None</li>
													</ul>
												<cfelse>
													<ul class="list-group">
														<cfloop query="groupMembership">
															<li class="list-group-item">
																<a href="/agents/Agent.cfm?agent_id=#groupMembership.group_agent_id#">#groupMembership.agent_name#</a>
															</li>
														</cfloop>
													</ul>
												</cfif>
											</div>
										</div>
									</div>
								</section>
							</cfif>
						</div>
						<div class="d-block mb-0 mb-xl-5 float-left h-auto px-0 px-md-1 col-12 col-md-4 col-xl-4">
							<!--- Collector in collections--->
							<section class="accordion" id="collectorSection1">
								<div class="card mb-2 bg-light">
									<cfquery name="getAgentCollScope" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getAgentCollScope_result">
										select sum(ct) as ct, collection_cde, collection_id, sum(st) as startyear, sum(en) as endyear 
										from (
											select count(*) ct, flat.collection_cde, flat.collection_id, to_number(min(substr(flat.began_date,0,4))) st, to_number(max(substr(flat.ended_date,0,4))) en
											from agent
												left join collector on agent.agent_id = collector.AGENT_ID
												left join <cfif session.flatTableName EQ "flat">flat<cfelse>filtered_flat</cfif> flat
													on collector.COLLECTION_OBJECT_ID = flat.collection_object_id
											where collector.COLLECTOR_ROLE = 'c'
												and substr(flat.began_date,0,4) = substr(flat.ENDED_DATE,0,4)
												and agent.agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
											group by flat.collection_cde, flat.collection_id
											union
											select count(*) ct, flat.collection_cde, flat.collection_id, 0 as st, 0 as en
											from agent
												left join collector on agent.agent_id = collector.AGENT_ID
												left join <cfif session.flatTableName EQ "flat">flat<cfelse>filtered_flat</cfif> flat
													on collector.COLLECTION_OBJECT_ID = flat.collection_object_id
											where collector.COLLECTOR_ROLE = 'c'
												and (flat.began_date is null or substr(flat.began_date,0,4) <> substr(flat.ENDED_DATE,0,4))
												and agent.agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
											group by flat.collection_cde, flat.collection_id, 0
											) 
										group by collection_cde, collection_id
										order by ct desc
									</cfquery>
									<cfif getAgentCollScope.recordcount EQ 1><cfset plural=""><cfelse><cfset plural="s"></cfif>
									<cfif getAgentCollScope.recordcount gt 600 OR getAgentCollScope.recordcount EQ 0>
										<!--- cardState = collapsed --->
										<cfset bodyClass = "collapse">
										<cfset ariaExpanded ="false">
									<cfelse>
										<!--- cardState = expanded --->
										<cfset bodyClass = "collapse show">
										<cfset ariaExpanded ="true">
									</cfif>
									<div class="card-header" id="collectorHeader1">
										<h2 class="h4 my-0">
											<button class="headerLnk text-left w-100 h-100" type="button" data-toggle="collapse" data-target="##collectorCardBodyWrap1" aria-expanded="#ariaExpanded#" aria-controls="collectorCardBodyWrap1">Collector (in #getAgentCollScope.recordcount# collection#plural#)</button>
										</h2>
									</div>
									<div id="collectorCardBodyWrap1" class="#bodyClass#" aria-labelledby="collectorHeader1" data-parent="##collectorSection1">
										<div class="card-body py-1 mb-1">
											<cfif getAgentCollScope.recordcount EQ 0>
												<ul class="list-group"><li class="list-group-item">Not a collector of any material in MCZbase</li></ul>
											<cfelse>
												<ul class="list-group">
													<cfset earlyeststart = "">
													<cfset latestend = "">
													<cfloop query="getAgentCollScope">
														<cfif len(earlyeststart) EQ 0 AND NOT getAgentCollScope.startyear IS "0" ><cfset earlyeststart = getAgentCollScope.startyear></cfif>
														<cfif len(latestend) EQ 0 AND NOT getAgentCollScope.endyear IS "0"><cfset latestend = getAgentCollScope.endyear></cfif>
														<cfif len(getAgentCollScope.startyear) GT 0 and NOT getAgentCollScope.startyear IS "0">
															<cfif compare(getAgentCollScope.startyear,earlyeststart) LT 0><cfset earlyeststart=getAgentCollScope.startyear></cfif>
														</cfif>
														<cfif compare(getAgentCollScope.endyear,latestend) GT 0><cfset latestend=getAgentCollScope.endyear></cfif>
														<cfif getAgentCollScope.ct EQ 1><cfset plural=""><cfelse><cfset plural="s"></cfif>
														<cfif getAgentCollScope.startyear IS getAgentCollScope.endyear>
															<cfif len(getAgentCollScope.startyear) EQ 0 or getAgentCollScope.startyear IS "0">
																<cfset yearbit=" none known to year">
															<cfelse>
																<cfset yearbit=" in year #getAgentCollScope.startyear#">
															</cfif>
														<cfelse>
															<cfset yearbit=" in years #getAgentCollScope.startyear#-#getAgentCollScope.endyear#">
														</cfif>
														<cfif len(getAgentCollScope.collection_cde) GT 0>
															<li class="list-group-item">#getAgentCollScope.collection_cde# (<a href="/Specimens.cfm?execute=true&action=fixedSearch&collector_agent_id=#agent_id#&collection_id=#getAgentCollScope.collection_id#" target="_blank">#getAgentCollScope.ct# record#plural#</a>) #yearbit#</li>
														</cfif>
													</cfloop>
													<cfif getAgentCollScope.recordcount GT 1>
														<li class="list-group-item"><a href="/Specimens.cfm?execute=true&action=fixedSearch&collector_agent_id=#agent_id#" target="_blank">All</a></li>
													</cfif>
												</ul>
												<cfif len(earlyeststart) GT 0 AND len(latestend) GT 0>
													<cfif LSParseNumber(earlyeststart) +80 LT LSParseNumber(latestend)>
														<h3 class="small95 mt-1 px-2 mb-0">Range of years collected is greater than 80 (#earlyeststart#-#latestend#) </h3>
													</cfif>
												</cfif>
											</cfif><!--- getAgentCollScope.recordcount > 0 --->
										</div>
									</div><!--- end collectorCardBodyWrap --->
								</div>
							</section>
							<cfquery name="points2" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="points2_result">
								SELECT median(flat.dec_lat) as mylat, median(flat.dec_long) as mylng, min(flat.dec_lat) as minlat, 
									min(flat.dec_long) as minlong, max(flat.dec_lat) as maxlat, max(flat.dec_long) as maxlong
								FROM <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat 
									left join collector on collector.collection_object_id = flat.collection_object_id
									left join agent on agent.agent_id = collector.agent_id
								WHERE collector.agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
								and collector_role='c'
							</cfquery>
							<cfif points.recordcount gt 0>
							<section class="accordion" id="collectorSection1">
								<div class="card mb-2 py-1 bg-light">		
									<script src="https://polyfill.io/v3/polyfill.min.js?features=default"></script>
									<div class="heatmap">
									<script src="https://maps.googleapis.com/maps/api/js?key=#application.gmap_api_key#&callback=initMap&libraries=visualization" async></script>
									<script>
										let map, heatmap;
										function initMap() {
											var ne = new google.maps.LatLng(#points2.maxlat#, #points2.maxlong#);
											var sw = new google.maps.LatLng(#points2.minlat#,#points2.minlong#);
											var bounds = new google.maps.LatLngBounds(sw, ne);
											var centerpoint = new google.maps.LatLng(#points2.mylat#,#points2.mylng#);
											var mapOptions = {
												zoom: 1,
												minZoom: 1,
												maxZoom: 13,
												center: centerpoint,
												controlSize: 20,
												mapTypeId: "hybrid",
											};
											map = new google.maps.Map(document.getElementById('map'), mapOptions);
										
											if (bounds.getNorthEast().equals(bounds.getSouthWest())) {
												var extendPoint1 = new google.maps.LatLng(bounds.getNorthEast().lat(), bounds.getNorthEast().lng());
												var extendPoint2 = new google.maps.LatLng(bounds.getNorthEast().lat(), bounds.getNorthEast().lng());
												bounds.extend(extendPoint1);
												bounds.extend(extendPoint2);
											} else {
												google.maps.event.addListener(map,'bounds_changed',function(){
												//var bounds = map.getBounds();
												var extendPoint3=new google.maps.LatLng(bounds.getNorthEast().lat(), bounds.getNorthEast().lng());
												var extendPoint4=new google.maps.LatLng(bounds.getSouthWest().lat(), bounds.getSouthWest().lng());
												bounds.extend(extendPoint3);
												bounds.extend(extendPoint4);
												});
											}
											map.fitBounds(bounds);
											heatmap = new google.maps.visualization.HeatmapLayer({
												data: getPoints(),
												map: map,
											});
											document
												.getElementById("change-gradient")
												.addEventListener("click", changeGradient);
											}
										function toggleHeatmap(){
											heatmap.setMap(heatmap.getMap() ? null : map);
										}
										function changeGradient() {
											const gradient = [
												"rgba(0, 255, 255, 0)",
												"rgba(0, 255, 255, 1)",
												"rgba(0, 191, 255, 1)",
												"rgba(0, 127, 255, 1)",
												"rgba(0, 63, 255, 1)",
												"rgba(0, 0, 255, 1)",
												"rgba(0, 0, 223, 1)",
												"rgba(0, 0, 191, 1)",
												"rgba(0, 0, 159, 1)",
												"rgba(0, 0, 127, 1)",
												"rgba(63, 0, 91, 1)",
												"rgba(127, 0, 63, 1)",
												"rgba(191, 0, 31, 1)",
												"rgba(255, 0, 0, 1)",
											];
											heatmap.set("gradient", heatmap.get("gradient") ? null : gradient);
										}
										function getPoints() {
											return [
											<cfloop query="points">
												new google.maps.LatLng(#points.Latitude#,#points.Longitude#),
											</cfloop>
											]
										}
									</script>
									<div class="p-0 mx-1">
										<div id="map" class="w-100 py-1 rounded" style="height: 300px;" aria-label="Google Map of Collecting Events"></div>
										<div id="floating-panel" class="w-100 mx-auto">
											<span class="text-left d-block float-left">Collecting Event Map</span>
											<button id="change-gradient" class="border mt-2 py-0 rounded btn-xs btn small float-right">Toggle Marker Color</button>
										</div>
									</div>
									<!--Async script executes immediately and must be after any DOM elements used in callback.-->
								</div>
							</section>
							</cfif>

							<!--- Collector of families --->
							<section class="accordion" id="collectorSection2">
								<div class="card mb-2 bg-light">
									<cfquery name="getAgentFamilyScope" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getAgentFamilyScope_result">
										select sum(ct) as ct, phylclass, family, sum(st) as startyear, sum(en) as endyear 
										from (
											select count(*) ct, flat.phylclass as phylclass, flat.family as family, 
												to_number(min(substr(flat.began_date,0,4))) st, to_number(max(substr(flat.ended_date,0,4))) en
											from agent
												left join collector on agent.agent_id = collector.AGENT_ID
												left join <cfif session.flatTableName EQ "flat">flat<cfelse>filtered_flat</cfif> flat
													on collector.COLLECTION_OBJECT_ID = flat.collection_object_id
												where collector.COLLECTOR_ROLE = 'c'
												and substr(flat.began_date,0,4) = substr(flat.ENDED_DATE,0,4)
												and agent.agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
											group by flat.phylclass, flat.family
											union
											select count(*) ct, flat.phylclass, flat.family as family, 
												0 as st, 0 as en
											from agent
												left join collector on agent.agent_id = collector.AGENT_ID
												left join <cfif session.flatTableName EQ "flat">flat<cfelse>filtered_flat</cfif> flat
													on collector.COLLECTION_OBJECT_ID = flat.collection_object_id
											where collector.COLLECTOR_ROLE = 'c'
												and (flat.began_date is null or substr(flat.began_date,0,4) <> substr(flat.ENDED_DATE,0,4))
												and agent.agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
											group by flat.phylclass, flat.family, 0
										) 
										group by phylclass, family
										order by phylclass, family
									</cfquery>
									<cfif getAgentFamilyScope.recordcount EQ 1><cfset fplural="y"><cfelse><cfset fplural="ies"></cfif>
									<cfif getAgentFamilyScope.recordcount GT 20 OR getAgentFamilyScope.recordcount eq 0>
										<!--- cardState = collapsed --->
										<cfset bodyClass = "collapse">
										<cfset ariaExpanded ="false">
									<cfelse>
										<!--- cardState = expanded --->
										<cfset bodyClass = "collapse show">
										<cfset ariaExpanded ="true">
									</cfif>
									<div class="card-header" id="collectorHeader2">
										<h2 class="h4 my-0">
											<button class="headerLnk text-left w-100 h-100" type="button" data-toggle="collapse" data-target="##collectorCardBodyWrap2" aria-expanded="#ariaExpanded#" aria-controls="collectorCardBodyWrap2">
											Collector (in #getAgentFamilyScope.recordcount# famil#fplural#)
											</button>
										</h2>
									</div>
									<div id="collectorCardBodyWrap2" class="#bodyClass#" aria-labelledby="collectorHeader2" data-parent="##collectorSection2">
										<!---	<cfif getAgentFamilyScope2.recordcount GT 0>--->
										<div class="card-body py-1 mb-1">
											<div class="w-100"> 
												<cfif getAgentCollScope.recordcount EQ 0>
													<ul class="list-group"><li class="list-group-item">Not a collector of any material in MCZbase</li></ul>
												<cfelse>
													<ul class="list-group">
														<cfset earlyeststart = "">
														<cfset latestend = "">
														<cfloop query="getAgentFamilyScope">
															<cfif len(earlyeststart) EQ 0 AND NOT getAgentFamilyScope.startyear IS "0" ><cfset earlyeststart = getAgentFamilyScope.startyear></cfif>
															<cfif len(latestend) EQ 0 AND NOT getAgentFamilyScope.endyear IS "0"><cfset latestend = getAgentFamilyScope.endyear></cfif>
															<cfif len(getAgentFamilyScope.startyear) GT 0 and NOT getAgentFamilyScope.startyear IS "0">
																<cfif compare(getAgentFamilyScope.startyear,earlyeststart) LT 0><cfset earlyeststart=getAgentFamilyScope.startyear></cfif>
															</cfif>
															<cfif compare(getAgentFamilyScope.endyear,latestend) GT 0><cfset latestend=getAgentFamilyScope.endyear></cfif>
															<cfif getAgentFamilyScope.ct EQ 1><cfset plural=""><cfelse><cfset plural="s"></cfif>
															<cfif getAgentFamilyScope.startyear IS getAgentFamilyScope.endyear>
																<cfif len(getAgentFamilyScope.startyear) EQ 0 or getAgentFamilyScope.startyear IS "0">
																	<cfset yearbit=" none known to year">
																<cfelse>
																	<cfset yearbit=" in year #getAgentFamilyScope.startyear#">
																</cfif>
															<cfelse>
																<cfset yearbit=" in years #getAgentFamilyScope.startyear#-#getAgentFamilyScope.endyear#">
															</cfif>
															<cfif len(getAgentFamilyScope.family) GT 0>
																<!--- TODO: Until redesigned specimen search is public, pick which search to link to --->
																<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"coldfusion_user")>
																	<li class="list-group-item">#getAgentFamilyScope.phylclass#: #getAgentFamilyScope.family# (<a href="/Specimens.cfm?execute=true&action=fixedSearch&collector_agent_id=#agent_id#&family=#getAgentFamilyScope.family#" target="_blank">#getAgentFamilyScope.ct# record#plural#</a>) #yearbit#</li>
																<cfelse>
																	<li class="list-group-item">#getAgentFamilyScope.phylclass#: #getAgentFamilyScope.family# (<a href="/SpecimenResults.cfm?collector_agent_id=#agent_id#&family=#getAgentFamilyScope.family#" target="_blank">#getAgentFamilyScope.ct# record#plural#</a>) #yearbit#</li>
																</cfif>
															<cfelse>
																<!--- TODO: Until redesigned specimen search is public, pick which search to link to --->
																<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"coldfusion_user")>
																	<cfif len(getAgentFamilyScope.phylclass) GT 0>
																		<cfset classSearch=getAgentFamilyScope.phylclass>
																	<cfelse>
																		<cfset classSearch="NULL">
																	</cfif>
																	<li class="list-group-item">#getAgentFamilyScope.phylclass#: [no family] (<a href="/Specimens.cfm?execute=true&action=fixedSearch&collector_agent_id=#agent_id#&family=NULL&phylclass=#classSearch#" target="_blank">#getAgentFamilyScope.ct# record#plural#</a>) #yearbit#</li>
																<cfelse>
																	<!--- old search does not support nulls, just show values --->
																	<li class="list-group-item">#getAgentFamilyScope.phylclass#: [no family] (#getAgentFamilyScope.ct# record#plural#) #yearbit#</li>
																</cfif>
															</cfif>
														</cfloop>
													</ul>
												</cfif>
											</div>
										</div>
									</div><!--- end collectorCardBodyWrap --->
								</div>
							</section>
							<!--- Preparator--->
							<section class="accordion" id="preparatorSection"> 
								<div class="card mb-2 bg-light">
									<cfquery name="getAgentPrepScope" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getAgentCollScope_result">
											select sum(ct) as ct, collection_cde, collection_id, sum(st) as startyear, sum(en) as endyear 
											from (
												select count(*) ct, flat.collection_cde, flat.collection_id, to_number(min(substr(flat.began_date,0,4))) st, to_number(max(substr(flat.ended_date,0,4))) en
												from agent
													left join collector on agent.agent_id = collector.AGENT_ID
													left join <cfif session.flatTableName EQ "flat">flat<cfelse>filtered_flat</cfif> flat
														on collector.COLLECTION_OBJECT_ID = flat.collection_object_id
												where collector.COLLECTOR_ROLE = 'p'
													and substr(flat.began_date,0,4) = substr(flat.ENDED_DATE,0,4)
													and agent.agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
												group by flat.collection_cde, flat.collection_id
												union
												select count(*) ct, flat.collection_cde, flat.collection_id, 0 as st, 0 as en
												from agent
													left join collector on agent.agent_id = collector.AGENT_ID
													left join <cfif session.flatTableName EQ "flat">flat<cfelse>filtered_flat</cfif> flat
														on collector.COLLECTION_OBJECT_ID = flat.collection_object_id
												where collector.COLLECTOR_ROLE = 'p'
													and (flat.began_date is null or substr(flat.began_date,0,4) <> substr(flat.ENDED_DATE,0,4))
													and agent.agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
												group by flat.collection_cde, flat.collection_id, 0
											) 
											group by collection_cde, collection_id
										</cfquery>
									<cfif getAgentPrepScope.recordcount GT 20 OR getAgentPrepScope.recordcount eq 0>
										<!--- cardState = collapsed --->
										<cfset bodyClass = "collapse">
										<cfset ariaExpanded ="false">
									<cfelse>
										<!--- cardState = expanded --->
										<cfset bodyClass = "collapse show">
										<cfset ariaExpanded ="true">
									</cfif>
									<cfif getAgentPrepScope.recordcount EQ 1><cfset plural =""><cfelse><cfset plural="s"></cfif>
									<div class="card-header" id="preparatorHeader">
										<h2 class="h4 my-0">
											<button type="button" class="headerLnk text-left w-100 h-100" data-toggle="collapse" data-target="##preparatorCardBodyWrap" aria-expanded="#ariaExpanded#" aria-controls="preparatorCardBodyWrap">
											Preparator (of material in #getAgentPrepScope.recordcount# collection#plural#)
											</button>
										</h2>
									</div>
									<div id="preparatorCardBodyWrap" class="#bodyClass#" aria-labelledby="preparatorHeader" data-parent="##preparatorSection">
										<div class="card-body py-1 mb-1">
											<cfif getAgentPrepScope.recordcount EQ 0>
												<ul class="list-group"><li class="list-group-item">Not a preparator of any material in MCZbase</li></ul>
											<cfelse>
												<ul class="list-group">
													<cfset earlyeststart = "">
													<cfset latestend = "">
													<cfloop query="getAgentPrepScope">
														<cfif len(earlyeststart) EQ 0 AND NOT getAgentPrepScope.startyear IS "0" ><cfset earlyeststart = getAgentPrepScope.startyear></cfif>
														<cfif len(latestend) EQ 0 AND NOT getAgentPrepScope.endyear IS "0"><cfset latestend = getAgentPrepScope.endyear></cfif>
														<cfif len(getAgentPrepScope.startyear) GT 0 and NOT getAgentPrepScope.startyear IS "0">
															<cfif compare(getAgentPrepScope.startyear,earlyeststart) LT 0><cfset earlyeststart=getAgentPrepScope.startyear></cfif>
														</cfif>
														<cfif compare(getAgentPrepScope.endyear,latestend) GT 0><cfset latestend=getAgentPrepScope.endyear></cfif>
														<cfif getAgentPrepScope.ct EQ 1><cfset plural=""><cfelse><cfset plural="s"></cfif>
														<cfif getAgentPrepScope.startyear IS getAgentPrepScope.endyear>
															<cfif len(getAgentPrepScope.startyear) EQ 0 or getAgentPrepScope.startyear IS "0">
																<cfset yearbit=" none known to year">
															<cfelse>
																<cfset yearbit=" in year #getAgentPrepScope.startyear#">
															</cfif>
														<cfelse>
															<cfset yearbit=" in years #getAgentPrepScope.startyear#-#getAgentPrepScope.endyear#">
														</cfif>
														<cfif len(getAgentPrepScope.collection_cde) GT 0>
															<!--- TODO: Until redesigned specimen search is public, pick which search to link to --->
															<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"coldfusion_user")>
																<li class="list-group-item">#getAgentPrepScope.collection_cde# (<a href="/Specimens.cfm?execute=true&builderMaxRows=3&action=builderSearch&nestdepth1=0&field1=AGENT%3ACOLLECTORS_AGENT_ID&searchText1=#encodeForURL(getAgent.preferred_agent_name)#&searchId1=#getAgent.agent_id#&JoinOperator2=and&field2=COLLECTOR%3ACOLLECTOR_ROLE&searchText2=%3Dp&JoinOperator3=and&field3=CATALOGED_ITEM%3ACATALOGED ITEM_COLLECTION_ID&searchText3=#getAgentPrepScope.collection_id#" target="_blank">#getAgentPrepScope.ct# record#plural#</a>) #yearbit#</li>
															<cfelse>
																<li class="list-group-item">#getAgentPrepScope.collection_cde# (<a href="/SpecimenResults.cfm?coll_role=p&coll=#encodeForURL(getAgent.preferred_agent_name)#&collection_id=#getAgentPrepScope.collection_id#" target="_blank">#getAgentPrepScope.ct# record#plural#</a>) #yearbit#</li>
															</cfif>
														</cfif>
													</cfloop>
												</ul>
												<cfif len(earlyeststart) GT 0 AND len(latestend) GT 0>
													<cfif LSParseNumber(earlyeststart) +80 LT LSParseNumber(latestend)>
														<h3 class="small95 mt-2 px-2 mb-0">Range of years collected is greater than 80 (#earlyeststart#-#latestend#) </h3>
													</cfif>
												</cfif>
											</cfif>
										</div>
									</div><!--- end preparatorCardBodyWrap --->
								</div>
							</section>
							<!--- Determiner --->
							<section class="accordion" id="determinerSection"> 
									<div class="card mb-2 bg-light">
										<cfquery name="identification" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="identification_result">
											SELECT
												count(*) cnt, 
												count(distinct(identification.collection_object_id)) specs,
												collection.collection_id,
												collection.collection
											FROM
												identification
												left join identification_agent on identification.identification_id=identification_agent.identification_id
												left join cataloged_item on identification.collection_object_id = cataloged_item.collection_object_id
												left join collection on cataloged_item.collection_id = collection.collection_id
											WHERE
												identification_agent.agent_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
											GROUP BY
												collection.collection_id,
												collection.collection
										</cfquery>
											<cfif identification.recordcount GT 20 OR identification.recordcount EQ 0>
												<!--- cardState = collapsed --->
												<cfset bodyClass = "collapse">
												<cfset ariaExpanded ="false">
											<cfelse>
												<!--- cardState = expanded --->
												<cfset bodyClass = "collapse show">
												<cfset ariaExpanded ="true">
											</cfif>
										<cfif identification.recordcount EQ 1><cfset plural=""><cfelse><cfset plural="s"></cfif>
										<div class="card-header" id="determinerHeader">
											<h2 class="h4 my-0">
												<button type="button" class="headerLnk text-left w-100 h-100" data-toggle="collapse" data-target="##determinerCardBodyWrap" aria-expanded="#ariaExpanded#" aria-controls="determinerCardBodyWrap">
												Determiner (in #identification.recordcount# collection#plural#) 
												</button>
											</h2>
										</div>
										<div id="determinerCardBodyWrap" class="#bodyClass#" aria-labelledby="determinerHeader" data-parent="##determinerSection">
											<div class="card-body py-1 mb-1">
												<cfif identification.recordcount EQ 0>
													<ul class="list-group">
														<li class="list-group-item">None</li>
													</ul>
												<cfelse>
													<ul class="list-group">
														<cfloop query="identification">
															<li class="list-group-item">
																#cnt# identifications for <a href="/SpecimenResults.cfm?identified_agent_id=#agent_id#&collection_id=#collection_id#" target="_blank">
																#specs# #collection#</a> cataloged items
															</li>
														</cfloop>
													</ul>
												</cfif>
											</div>
										</div><!--- end determinerCardBodyWrap --->
									</div>
								</section>
							<!--- attribute determinations --->
							<section class="accordion" id="attributeSection"> 
								<div class="card mb-2 bg-light">
									<cfquery name="attributes" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="lastEdit_result">
										select 
											count(distinct(cataloged_item.collection_object_id)) colObjCount,
											collection.collection_id,
											collection,
											attribute_type
										from
											attributes
											left join cataloged_item on attributes.collection_object_id = cataloged_item.collection_object_id
											left join collection on cataloged_item.collection_id=collection.collection_id
										where
											determined_by_agent_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
										group by
											collection.collection_id,
											collection,
											attribute_type
									</cfquery>
									<cfif attributes.recordcount GT 20 OR attributes.recordcount EQ 0>
										<!--- cardState = collapsed --->
										<cfset bodyClass = "collapse">
										<cfset ariaExpanded ="false">
									<cfelse>
										<!--- cardState = expanded --->
										<cfset bodyClass = "collapse show">
										<cfset ariaExpanded ="true">
									</cfif>
									<div class="card-header" id="attributeHeader">
										<h2 class="h4 my-0">
											<button type="button" class="headerLnk text-left w-100 h-100" data-toggle="collapse" data-target="##attributeCardBodyWrap" aria-expanded="#ariaExpanded#" aria-controls="attributeCardBodyWrap">
											Attribute Determiner (#attributes.recordcount# categories)
											</button>
										</h2>
									</div>
									<div id="attributeCardBodyWrap" class="#bodyClass#" aria-labelledby="attributeHeader" data-parent="##attributeSection">
										<div class="card-body py-1 mb-1">
											<cfif attributes.recordcount EQ 0>
												<ul class="list-group">
													<li class="list-group-item">None</li>
												</ul>
											<cfelse>
												<ul class="list-group">
													<cfloop query="attributes">
														<li class="list-group-item">
															#attributes.attribute_type# for #attributes.colObjCount#
															<a href="/SpecimenResults.cfm?attributed_determiner_agent_id=#agent_id#&collection_id=#attributes.collection_id#" target="_blank">
																#attributes.collection#</a> specimens
														</li>
													</cfloop>
												</ul>
											</cfif>
										</div>
									</div><!--- end attributeCardBodyWrap --->
								</div>
							</section>
							<!--- named groups --->
							<cfif oneOfUs eq 1>	
								<section class="accordion" id="namedgroupSection"> 
									<div class="card mb-2 bg-light">
										<cfquery name="getNamedGroups" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
											select collection_name, 
												underscore_collection.underscore_collection_id, 
												mask_fg,
												inverse_label
											from underscore_collection_agent
												join underscore_collection on underscore_collection_agent.underscore_collection_id = underscore_collection.underscore_collection_id
												join ctunderscore_coll_agent_role on underscore_collection_agent.role = ctunderscore_coll_agent_role.role
											WHERE
												underscore_collection_agent.agent_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#agent_id#">
											order by collection_name, ordinal asc
										</cfquery>
										<cfif getnamedGroups.recordcount GT 20 OR getnamedGroups.recordcount eq 0>
											<!--- cardState = collapsed --->
											<cfset bodyClass = "collapse">
											<cfset ariaExpanded ="false">
										<cfelse>
											<!--- cardState = expanded --->
											<cfset bodyClass = "collapse show">
											<cfset ariaExpanded ="true">
										</cfif>
										<div class="card-header" id="namedgroupHeader">
											<h2 class="h4 my-0">
												<button type="button" class="headerLnk text-left w-100 h-100" data-toggle="collapse" data-target="##namedgroupCardBodyWrap" aria-expanded="#ariaExpanded#" aria-controls="namedgroupCardBodyWrap">
												Associated Agent for Named Groups (#getNamedGroups.recordcount#)
												</button>
											</h2>
										</div>
										<div id="namedgroupCardBodyWrap" class="#bodyClass#" aria-labelledby="namedgroupHeader" data-parent="##namedgroupSection">
											<div class="card-body py-1 mb-1">
												<cfif getnamedGroups.recordcount EQ 0>
													<ul class="list-group">
														<li class="list-group-item">None</li>
													</ul>
												<cfelse>
													<ul class="list-group">
														<cfloop query="getNamedGroups">
															<cfif getNamedGroups.mask_fg EQ 0 OR  oneOfUs EQ 1>
																<li class="list-group-item">#inverse_label# <a href="/grouping/showNamedCollection.cfm?underscore_collection_id=#underscore_collection_id#" target="_blank">#collection_name#</a></li>
															<cfelse>
																<li class="list-group-item">#inverse_label# #collection_name#</li>
															</cfif>
														</cfloop>
													</ul>
												</cfif>
											</div>
										</div><!--- end namedgroupCardBodyWrap --->
									</div>
								</section>
							</cfif>
							<!--- Georeferences --->
							<cfif oneOfUs EQ 1>
								<section class="accordion" id="georefSection"> 
									<div class="card mb-2 bg-light">
										<cfquery name="getLatLongDet" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getLatLongDet_result">
											select 
												count(*) cnt,
												count(distinct(locality_id)) locs 
											from lat_long 
											where determined_by_agent_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
										</cfquery>
										<cfquery name="getLatLongVer" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getLatLongVer_result">
											select 
												count(*) cnt,
												count(distinct(locality_id)) locs 
											from lat_long 
											where determined_by_agent_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
										</cfquery>
										<cfif #getLatLongDet.cnt# gt 0><cfset GeoDet = 1><cfelse><cfset GeoDet = 0></cfif>
										<cfif #getLatLongVer.cnt# gt 0><cfset GeoVer = 1><cfelse><cfset GeoVer = 0></cfif>
										<cfset totalRoles = #GeoDet# + #GeoVer#>
										<cfif totalRoles eq 0>
											<!--- cardState = collapsed --->
											<cfset bodyClass = "collapse">
											<cfset ariaExpanded ="false">
										<cfelse>
											<!--- cardState = expanded --->
											<cfset bodyClass = "collapse show">
											<cfset ariaExpanded ="true">
										</cfif>
										<div class="card-header" id="georefHeader">
											<h2 class="h4 my-0">
												<button type="button" class="headerLnk text-left w-100 h-100" data-toggle="collapse" data-target="##georefCardBodyWrap" aria-expanded="#ariaExpanded#" aria-controls="georefCardBodyWrap">
													Georeferences (#getLatLongDet.cnt# determined, #getLatLongVer.cnt# verified)
												</button>
											</h2>
										</div>
										<div id="georefCardBodyWrap" class="#bodyClass#" aria-labelledby="georefHeader" data-parent="##georefSection">
											<div class="card-body py-1 mb-1">
												<cfif getLatLongDet.recordcount EQ 0>
													<ul class="list-group">
														<li class="list-group-item">Determiner for No Coordinates</li>
													</ul>
												<cfelse>
													<ul class="list-group">
														<li class="list-group-item">Determined #getLatLongDet.cnt# coordinates for #getLatLongDet.locs# localities</li>
													</ul>
												</cfif>
												<cfif getLatLongVer.recordcount EQ 0>
													<ul class="list-group">
														<li class="list-group-item">Verified No Coordinates</li>
													</ul>
												<cfelse>
													<ul class="list-group">
														<li class="list-group-item">Verified #getLatLongVer.cnt# coordinates for #getLatLongVer.locs# localities</li>
													</ul>
												</cfif>
											</div>
										</div>
									</div>
								</section>
							</cfif>
							<!--- media relationships and labels --->
							<cfif oneOfUs EQ 1>
								<section class="accordion" id="mediametaSection"> 
									<div class="card mb-2 bg-light">
										<cfquery name="getMediaCreation" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getMediaCreation_result">
											SELECT count(distinct media_id) as ct
											FROM media_relations 
											WHERE related_primary_key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
												and media_relationship = 'created by agent'
										</cfquery>
										<cfquery name="media_assd_relations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="media_assd_relations_result">
											SELECT count(distinct media_id) as ct
											FROM media_relations 
											WHERE CREATED_BY_AGENT_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
										</cfquery>
										<cfquery name="media_labels" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="media_labels_result">
											SELECT count(distinct media_id) ct, media_label
											FROM media_labels 
											WHERE ASSIGNED_BY_AGENT_ID=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
											GROUP BY media_label
										</cfquery>
										<cfset i = 0> 
										<cfloop query="media_labels">

											<cfset i = i+ #media_labels.ct#>
										</cfloop>
										<cfset totallabels = #i#>
										<cfif #getMediaCreation.ct# gt 0><cfset mediaCreationRole = 1><cfelse><cfset mediaCreationRole = 0></cfif>
										<cfif #media_labels.ct# gt 0><cfset mediaLabelRole = 1><cfelse><cfset mediaLabelRole = 0></cfif>
										<cfif #media_assd_relations.ct# gt 0><cfset mediaRelationRole = 1><cfelse><cfset mediaRelationRole = 0></cfif>
										<cfset mediaRoles = #mediaCreationRole# + #mediaLabelRole# + #MediaRelationRole#>
										<cfif #mediaRoles# GT 20 OR #mediaRoles# eq 0>
											<!--- cardState = collapsed --->
											<cfset bodyClass = "collapse">
											<cfset ariaExpanded ="false">
										<cfelse>
											<!--- cardState = expanded --->
											<cfset bodyClass = "collapse show">
											<cfset ariaExpanded ="true">
										</cfif>
										<cfif #getMediaCreation.ct# EQ 1><cfset plural=""><cfelse><cfset plural="s"></cfif>
										<cfif #media_assd_relations.ct# EQ 1><cfset plural2=""><cfelse><cfset plural2="s"></cfif>
										<cfif totallabels EQ 1><cfset plural3=""><cfelse><cfset plural3="s"></cfif>
										<div class="card-header" id="mediametaHeader">
											<h2 class="h4 my-0">
												<button type="button" class="headerLnk text-left w-100 h-100" data-toggle="collapse" data-target="##mediametaCardBodyWrap" aria-expanded="#ariaExpanded#" aria-controls="mediametaCardBodyWrap">
												Media Records (#getMediaCreation.ct# record#plural#, #media_assd_relations.ct# relationship#plural2#, #totallabels# label#plural3#) 
												</button>
											</h2>
										</div>
										<div id="mediametaCardBodyWrap" class="#bodyClass#" aria-labelledby="mediametaHeader" data-parent="##mediametaSection">
											<div class="card-body py-1 mb-1">
												<ul class="list-group">
													<cfif getMediaCreation.ct EQ 0>
														<li class="list-group-item">Created No Media Records</li>
													<cfelse>
														<li class="list-group-item">
															Created #getMediaCreation.ct# 
															<a href="/media/findMedia.cfm?execute=true&created_by_agent_name=#encodeForURL(prefName)#&created_by_agent_id=#agent_id#" target="_blank">Media Record#plural#</a>
														</li>
													</cfif>
													<cfif media_assd_relations.ct EQ 0>
														<li class="list-group-item">Created No Media Relationships</li>
													<cfelse>
														<li class="list-group-item">Created #media_assd_relations.ct# Media Relationships</li>
													</cfif>
													<cfif media_labels.recordcount EQ 0>
														<li class="list-group-item">Assigned no media label values</li>
													<cfelse>
														<cfloop query="media_labels">
															<li class="list-group-item">Assigned labels: #media_labels.media_label# (#media_labels.ct#)</li>
														</cfloop>
													</cfif>
												</ul>
											</div>
										</div><!--- end mediametaCardBodyWrap --->
									</div>
								</section>
							</cfif>
						</div>
						<div class="d-block mb-0 mb-xl-5 float-left h-auto col-12 col-md-5 col-xl-5 px-0 px-md-1">
							<!--- loan item reconciliation --->
							<cfif listcontainsnocase(session.roles, "manage_transactions")>
								<section class="accordion" id="loanItemSection"> 
									<div class="card mb-2 bg-light" id="loanItemsCard">
										<cfquery name="loan_item" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getTransactions_result">
											SELECT
												count(*) cnt,
												trans.transaction_id,
												loan_number,
												collection
											FROM
												trans
												left join loan on trans.transaction_id=loan.transaction_id
												left join loan_item on loan.transaction_id=loan_item.transaction_id
												left join collection on trans.collection_id=collection.collection_id
											WHERE
												RECONCILED_BY_PERSON_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
											GROUP BY
												trans.transaction_id,
												loan_number,
												collection
										</cfquery>
										<cfif loan_item.recordcount EQ 1><cfset plural=""><cfelse><cfset plural="s"></cfif>
										<cfif loan_item.recordcount GT 20 OR loan_item.recordcount EQ 0>
											<!--- cardState = collapsed --->
											<cfset bodyClass = "collapse">
											<cfset ariaExpanded ="false">
										<cfelse>
											<!--- cardState = expanded --->
											<cfset bodyClass = "collapse show">
											<cfset ariaExpanded ="true">
										</cfif>
										<div class="card-header" id="loanItemHeader">
											<h2 class="h4 my-0">
												<button type="button" class="headerLnk text-left w-100 h-100" data-toggle="collapse" data-target="##loanItemCardBodyWrap" aria-expanded="#ariaExpanded#" aria-controls="loanItemCardBodyWrap">
												Reconciled loan items (#loan_item.recordcount#)
												</button>
											</h2>
										</div>
										<div id="loanItemCardBodyWrap" class="#bodyClass#" aria-labelledby="loanItemHeader" data-parent="##loanItemSection">
												<cfif loan_item.recordcount GT 0>
													<h3 class="small95 px-3 mt-2 mb-0">#prefName# reconciled #loan_item.recordcount# loan item#plural#</h3>
												</cfif>
												<div class="card-body pt-0 pb-1 mb-1">
													<ul class="list-group mt-0">
														<cfif loan_item.recordcount EQ 0>
															<li class="list-group-item">None</li>
														<cfelse>
															<cfloop query="loan_item">
																<li class="list-group-item">Reconciled #cnt# items for Loan 
																	<a href="/transactions/Loan.cfm?action=editLoan&transaction_id=#transaction_id#">#collection# #loan_number#</a>
																</li>		
															</cfloop>
														</cfif>
													</ul>
												</div>
											</div>
									</div><!--- end loanItemsCard --->
								</section>
							</cfif>
							<!--- shipments --->
							<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_transactions")>
								<section class="accordion" id="shipmentsSection">
									<div class="card mb-2 bg-light" id="shipmentsCard">
										<cfquery name="packedBy" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="packedBy_result">
											SELECT
												transaction_view.transaction_id, 
												transaction_view.transaction_type,
												to_char(shipped_date,'YYYY-MM-DD') trans_date,
												transaction_view.specific_number,
												transaction_view.collection_id,
												collection
											FROM
												shipment
												left join transaction_view on shipment.transaction_id=transaction_view.transaction_id
												left join collection on transaction_view.collection_id=collection.collection_id
											WHERE
												PACKED_BY_AGENT_ID=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
										</cfquery>
										<cfquery name="shippedTo" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="shippedTo_result">
											SELECT
												transaction_view.transaction_id, 
												transaction_view.transaction_type,
												to_char(shipped_date,'YYYY-MM-DD') trans_date,
												transaction_view.specific_number,
												transaction_view.collection_id,
												collection
											FROM
												shipment
												left join transaction_view on shipment.transaction_id=transaction_view.transaction_id
												left join collection on transaction_view.collection_id=collection.collection_id
												left join addr on shipment.shipped_to_addr_id = addr.addr_id
											WHERE
												addr.agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
										</cfquery>
										<cfquery name="shippedFrom" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="shippedFrom_result">
											SELECT
												transaction_view.transaction_id, 
												transaction_view.transaction_type,
												to_char(shipped_date,'YYYY-MM-DD') trans_date,
												transaction_view.specific_number,
												transaction_view.collection_id,
												collection
											FROM
												shipment
												left join transaction_view on shipment.transaction_id=transaction_view.transaction_id
												left join collection on transaction_view.collection_id=collection.collection_id
												left join addr on shipment.shipped_from_addr_id = addr.addr_id
											WHERE
												addr.agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
										</cfquery>
										<cfset totalShipCount = packedBy.recordcount + shippedTo.recordcount + shippedFrom.recordcount>
										<cfif totalShipCount EQ 1><cfset plural=""><cfelse><cfset plural="s"></cfif>
										<cfif totalShipCount GT 20 OR totalShipCount eq 0>
											<!--- cardState = collapsed --->
											<cfset bodyClass = "collapse">
											<cfset ariaExpanded ="false">
										<cfelse>
											<!--- cardState = expanded --->
											<cfset bodyClass = "collapse show">
											<cfset ariaExpanded ="true">
										</cfif>
										<div class="card-header" id="shipmentsHeader">
											<h2 class="h4 my-0">
												<button class="headerLnk text-left w-100 h-100" type="button" data-toggle="collapse" data-target="##shipmentsCardBodyWrap" aria-expanded="#ariaExpanded#" aria-controls="shipmentsCardBodyWrap">
													Roles in Shipment#plural# (#totalShipCount#)
												</button>
											</h2>
										</div>
										<div id="shipmentsCardBodyWrap" class="#bodyClass#" aria-labelledby="shipmenstHeader" data-parent="##shipmentsSection">
												<cfif totalShipCount GT 0>
													<h3 class="small95 mt-2 px-3 mb-0">#prefName# has some role in #totalShipCount# shipment#plural#</h3>
												</cfif>
												<div class="card-body pt-0 pb-1 mb-1">
													<ul class="list-group">
														<cfif packedBy.recordcount EQ 0>
															<li class="list-group-item">Packed no shipments for transactions</li>
														</cfif>
														<cfloop query="packedBy">
															<li class="list-group-item">
																Packed shipment for #transaction_type#
																<a href="/Transactions.cfm?action=findAll&execute=true&collection_id=#collection_id#&number=#specific_number#" target="_blank">
																	#collection# #specific_number#
																</a>
															</li>
														</cfloop>
														<cfif shippedTo.recordcount EQ 0>
															<li class="list-group-item">Recipient of no shipments for transactions</li>
														</cfif>
														<cfloop query="shippedTo">
															<li class="list-group-item">
																Recipient of shipment for #transaction_type#
																<a href="/Transactions.cfm?action=findAll&execute=true&collection_id=#collection_id#&number=#specific_number#" target="_blank">
																	#collection# #specific_number#
																</a>
															</li>
														</cfloop>
														<cfif shippedFrom.recordcount EQ 0>
															<li class="list-group-item">Sender of no shipments for transactions</li>
														</cfif>
														<cfloop query="shippedFrom">
															<li class="list-group-item">
																Sender of shipment for #transaction_type#
																<a href="/Transactions.cfm?action=findAll&execute=true&collection_id=#collection_id#&number=#specific_number#" target="_blank">
																	#collection# #specific_number#
																</a>
															</li>
														</cfloop>
													</ul>
												</div>
											</div>
									</div><!--- end shipmentsCard --->
								</section>
							</cfif>
							<!--- encumbrances --->
							<cfif oneOfUs EQ 1>
								<section class="accordion" id="encumbrancesSection"> 
									<div class="card mb-2 bg-light">
										<cfquery name="getEncumbCount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getEncumbCount_result">
											SELECT count(*) as ct
											FROM encumbrance 
											WHERE encumbering_agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
										</cfquery>
										<cfquery name="getEncumb" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getEncumb_result">
											SELECT count(*) as ct, ENCUMBRANCE
											FROM encumbrance 
											WHERE encumbering_agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
											GROUP BY ENCUMBRANCE
										</cfquery>
										<cfquery name="coll_object_encumbrance" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getEncumb_result">
											SELECT 
												count(distinct(coll_object_encumbrance.collection_object_id)) specs,
												collection,
												collection.collection_id
											FROM
												encumbrance
												left join coll_object_encumbrance on encumbrance.encumbrance_id = coll_object_encumbrance.encumbrance_id
												left join cataloged_item on coll_object_encumbrance.collection_object_id=cataloged_item.collection_object_id
												left join collection on cataloged_item.collection_id=collection.collection_id
											WHERE
												encumbering_agent_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#"> and collection is not null
											GROUP BY
												collection,
												collection.collection_id
										</cfquery>
										<cfquery name="inEnc" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="inEnc_result">
											SELECT 
												count(distinct(coll_object_encumbrance.collection_object_id)) specs, encumbrance.encumbrance_id
											FROM
												encumbrance
												left join coll_object_encumbrance on encumbrance.encumbrance_id = coll_object_encumbrance.encumbrance_id
												left join cataloged_item on coll_object_encumbrance.collection_object_id=cataloged_item.collection_object_id
												left join collection on cataloged_item.collection_id=collection.collection_id
											WHERE
												encumbering_agent_id=3359 and collection is not null
											GROUP BY
												encumbrance.encumbrance_id
										</cfquery>
										<cfset i = 0> 
										<cfloop query="coll_object_encumbrance">
											<cfset i = i+ #coll_object_encumbrance.specs#>
										</cfloop>
										<cfset totalSpecEnc = #i#>
										<cfif getEncumbCount.recordcount GT 20 OR getEncumb.recordcount eq 0>
											<!--- cardState = collapsed --->
											<cfset bodyClass = "collapse">
											<cfset ariaExpanded ="false">
										<cfelse>
											<!--- cardState = expanded --->
											<cfset bodyClass = "collapse show">
											<cfset ariaExpanded ="true">
										</cfif>
										<div class="card-header" id="encumbrancesHeader">
											<h2 class="h4 my-0">
												<button type="button" class="headerLnk text-left w-100 h-100" data-toggle="collapse" data-target="##encumbrancesCardBodyWrap" aria-expanded="#ariaExpanded#" aria-controls="encumbrancesCardBodyWrap">
												Encumbrances (Owns #getEncumbCount.ct#, Encumbered #totalSpecEnc# in #coll_object_encumbrance.recordcount# Collections)
												</button>
											</h2>
										</div>
										<div id="encumbrancesCardBodyWrap" class="#bodyClass#" aria-labelledby="encumbrancesHeader" data-parent="##encumbrancesSection">
											<div class="card-body py-1 mb-1">
												<ul class="list-group">
													<cfif getEncumbCount.ct EQ 0>
														<li class="list-group-item">Owns No Encumbrances</li>
													<cfelse>
													<cfloop query="getEncumb">
															<li class="list-group-item">#getEncumb.ENCUMBRANCE# </li>
														</cfloop>
													</cfif>
													<cfloop query="coll_object_encumbrance">
														<li class="list-group-item">
															Encumbered 
															<a href="/SpecimenResults.cfm?encumbering_agent_id=#agent_id#&collection_id=#collection_id#" target="_blank">
															#specs# #collection#</a> records
														</li>
													</cfloop>
												</ul>
											</div>
										</div><!--- end encumbrancesCardBodyWrap --->
									</div>
								</section>
							</cfif>
							<!--- Project sponsor and other project roles --->
							<cfif oneOfUs EQ 1>
								<section class="accordion" id="projectSection"> 
									<div class="card mb-2 bg-light">
										<cfquery name="getProjRoles" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getProjRoles_result">
											SELECT distinct
												'sponsor' as role,
												project_name,
												project.project_id
											FROM
												project_sponsor 
												left join project on project.project_id=project_sponsor.project_id
												left join agent_name on project_sponsor.agent_name_id = agent_name.agent_name_id
											WHERE
												 agent_name.agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
											UNION
											SELECT distinct
												project_agent_role as role, 
												project_name,
												project.project_id
											FROM
												project_agent
												left join project on project.project_id=project_agent.project_id
												left join agent_name on project_agent.agent_name_id = agent_name.agent_name_id
											WHERE
												 agent_name.agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
										</cfquery>
										<cfif getProjRoles.recordcount GT 20 OR getProjRoles.recordcount eq 0>
											<!--- cardState = collapsed --->
											<cfset bodyClass = "collapse">
											<cfset ariaExpanded ="false">
										<cfelse>
											<!--- cardState = expanded--->
											<cfset bodyClass = "collapse show">
											<cfset ariaExpanded ="true">
										</cfif>
										<div class="card-header">
											<h2 class="h4 my-0">
												<button type="button" class="headerLnk text-left w-100 h-100" data-toggle="collapse" data-target="##projectCardBodyWrap" aria-expanded="#ariaExpanded#" aria-controls="projectCardBodyWrap">
												Project Roles (#getProjRoles.recordcount#)
												</button>
											</h2>
										</div>
										<div id="projectCardBodyWrap" class="#bodyClass#" aria-labelledby="projectHeader" data-parent="##projectSection">
											<div class="card-body py-1 mb-1">
												<cfif getProjRoles.recordcount EQ 0>
													<ul class="list-group"><li class="list-group-item">No project roles in MCZbase</li></ul>
												<cfelse>
													<ul class="list-group">
														<cfloop query="getProjRoles">
															<li class="list-group-item">#getProjRoles.role# for <a href="/ProjectDetail.cfm?project_id=#project_id#" target="_blank">#project_name#</a></li>
														</cfloop>
													</ul>
												</cfif>
											</div>
										</div><!--- end projectCardBodyWrap --->
									</div>
								</section>
							</cfif>
							<!--- transactions roles --->
							<cfif listcontainsnocase(session.roles, "manage_transactions")>
								<section class="accordion" id="transactionsSection">
									<div class="card mb-2 bg-light" id="transactionsCard">
										<!--- user may not be in vpn to see collection.collection_cde 
										<cfquery name="getTransCount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getTransactions_result">
										--->
										<cfquery name="getTransCount" datasource="uam_god">
											SELECT count(distinct transaction_view.transaction_id) ct
											FROM trans_agent
												left outer join transaction_view on trans_agent.transaction_id = transaction_view.transaction_id
											WHERE
												trans_agent.agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
										</cfquery>
										<cfset oversizeSet = false>
										<cfif getTransCount.ct GT 50>
											<!--- started as handle Brendan without crashing page with limit of 5000, but grouping looks useful at much smaller sizes, using default search page limit of 50 --->
											<cfset oversizeSet = true>
											<!--- user may not be in vpn to see collection.collection_cde. 
											<cfquery name="getTransactions" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getTransactions_result">
											--->
											<cfquery name="getTransactions" datasource="uam_god">
												SELECT
													count(transaction_view.transaction_id) as ct, 
													transaction_view.transaction_type,
													transaction_view.status,
													collection.collection_cde,
													collection.collection_id,
													trans_agent_role
												FROM trans_agent
													left outer join transaction_view on trans_agent.transaction_id = transaction_view.transaction_id
													left outer join collection on transaction_view.collection_id = collection.collection_id
												WHERE
													trans_agent.agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
												GROUP BY
													transaction_view.transaction_type,
													transaction_view.status,
													collection.collection_cde,
													collection.collection_id,
													trans_agent_role
												ORDER BY transaction_view.transaction_type, collection.collection_cde 
											</cfquery>
										<cfelse>
											<!--- user may not be in vpn to see collection.collection_cde. 
											<cfquery name="getTransactions" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getTransactions_result">
											--->
											<cfquery name="getTransactions" datasource="uam_god">
												SELECT
													transaction_view.transaction_id, 
													transaction_view.transaction_type,
													to_char(trans_date,'YYYY-MM-DD') trans_date,
													transaction_view.specific_number,
													transaction_view.status,
													collection.collection_cde,
													trans_agent_role
												FROM trans_agent
													left outer join transaction_view on trans_agent.transaction_id = transaction_view.transaction_id
													left outer join collection on transaction_view.collection_id = collection.collection_id
												WHERE
													trans_agent.agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
												ORDER BY transaction_view.transaction_type, transaction_view.specific_number
											</cfquery>
										</cfif>
										<cfset totalTransCount = getTransCount.ct>
										<cfif totalTransCount EQ 1><cfset plural=""><cfelse><cfset plural="s"></cfif>
										<cfif totalTransCount GT 20 OR getTransactions.recordcount EQ 0>
											<!--- cardState = collapsed --->
											<cfset bodyClass = "collapse">
											<cfset ariaExpanded ="false">
										<cfelse>
											<!--- cardState = expanded--->
											<cfset bodyClass = "collapse show">
											<cfset ariaExpanded ="true">
										</cfif>
										<div class="card-header" id="transactionsHeader">
											<h2 class="h4 my-0">
												<button type="button" class="headerLnk text-left w-100 h-100" data-toggle="collapse" data-target="##transactionsCardBodyWrap" aria-expanded="#ariaExpanded#" aria-controls="transactionsCardBodyWrap">
												Roles in Transaction#plural# (#totalTransCount#)
												</button>
											</h2>
										</div>
										<div id="transactionsCardBodyWrap" class="#bodyClass#" aria-labelledby="transactionsHeader" data-parent="##transactionsSection">
											<cfif getTransCount.ct EQ 0>
												<h3 class="small95 mt-2 px-3 mb-0">#prefName# has some role in #totalTransCount# transaction#plural#.</h3>
											<cfelse>
												<h3 class="small95 mt-2 px-3 mb-1">
													#prefName# has some role in 
													<a href="/Transactions.cfm?action=findAll&execute=true&collection_id=-1&agent_1=#encodeForURL(prefName)#&agent_1_id=#agent_id#" target="_blank">
													#getTransCount.ct# Transaction#plural#
													</a>
												</h3>
											</cfif>
											<div class="card-body pt-0 pb-1 mb-1">
												<cfif getTransactions.recordcount EQ 0>
													<ul class="list-group"><li class="list-group-item">Not a Transaction Agent in MCZbase</li></ul>
												<cfelse>
													<ul class="list-group mt-0">
														<!--- lastTrans, statusDate, liOpen handle repeating rows in getTransactions for this agent in several roles in one transaction --->
														<cfset lastTrans ="">
														<cfset statusDate ="">
														<cfset liOpen = false>
														<cfloop query="getTransactions">
															<cfif oversizeSet IS true>
																<li class="">
																	<cfquery name="collVisible" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="collVisible_result">
																		SELECT count(*) ct
																		FROM vpd_collection_cde
																		WHERE collection_cde = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#collection_cde#">
																	</cfquery>
																	<cfif collVisible.ct EQ 1>
																		<cfset collIsVisible = true>
																	<cfelse>
																		<cfset collIsVisible = false>
																	</cfif>
																	<cfif transaction_type IS "deaccession">
																		<cfset targetStatus="deacc_status">
																	<cfelse>
																		<cfset targetStatus="#transaction_type#_status">
																	</cfif>
																	<cfif collIsVisible>
																		<a href="/Transactions.cfm?execute=true&action=find#transaction_type#&collection_id=#collection_id#&#targetStatus#=#status#&trans_agent_role_1=#trans_agent_role#&agent_1=#encodeForURL(prefName)#&agent_1_id=#agent_id#" target="_blank">
																	</cfif>
																			#getTransactions.ct# 
																	<cfif collIsVisible>
																		</a>
																	</cfif>
																	<span class="text-capitalize">#transaction_type#</span> 
																	#trans_agent_role#
																	#status# in #collection_cde#
																	<span><!-- workaround --></span>
																</li>
															<cfelse>
																<cfif lastTrans NEQ getTransactions.specific_number>
																	<!--- encountered a new transaction (or the first)--->
																	<cfif lastTrans NEQ "">
																		<!--- not the first transaction, so show status/date and close the list from the previous transaction --->
																		#statusDate#
																		</li>
																		<cfset liOpen = false>
																	</cfif>
																	<li class="">
																		<cfset liOpen = true>
																		<cfset statusDate = "(#trans_date# #getTransactions.status#)">
																		<span class="text-capitalize">#transaction_type#</span> 
																		<a href="/Transactions.cfm?number=#specific_number#&action=findAll&execute=true" target="_blank">#specific_number#</a>
																		#trans_agent_role#
																	<!--- /li added in cfif either above or below --->
																<cfelse>
																	<!--- accumulate transaction agents, rows in getTransactions repeat for different roles by this agent in the same transaction --->
																	, #trans_agent_role#
																</cfif>
																<cfset lastTrans ="#getTransactions.specific_number#">
															</cfif>
														</cfloop>
														<cfif liOpen >
															<!--- clean up at end of oversizeSet IS false block --->
															#statusDate#
															</li>
														</cfif>
													</ul>
												</cfif>
											</div>
										</div>
									</div>
								</section>
							</cfif>
							<!--- permissions and rights roles --->
							<cfif listcontainsnocase(session.roles, "manage_transactions")>
								<section class="accordion" id="permitAccord">
									<div class="card mb-2 bg-light" id="permitsCard">
										<cfquery name="getPermitsTo" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getPermitsTo_result">
											SELECT distinct
												permit_num,
												permit_title,
												permit_type,
												specific_type,
												permit_id
											FROM
												permit 
											WHERE 
												ISSUED_TO_AGENT_ID=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
										</cfquery>
										<cfquery name="getPermitsFrom" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getPermitsFrom_result">
											SELECT distinct
												permit_num,
												permit_title,
												permit_type,
												specific_type,
												permit_id
											FROM
												permit 
											WHERE 
												ISSUED_BY_AGENT_ID=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
										</cfquery>
										<cfquery name="getPermitContacts" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getPermitContacts_result">
											SELECT distinct
												permit_num,
												permit_title,
												permit_type,
												specific_type,
												permit_id
											FROM
												permit 
											WHERE 
												CONTACT_AGENT_ID=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
										</cfquery>
										<cfset totalPermitCount = getPermitsTo.recordcount + getPermitsFrom.recordCount + getPermitContacts.recordcount>
										<cfif totalPermitCount EQ 1><cfset plural=""><cfelse><cfset plural="s"></cfif>
										<cfif totalPermitCount GT 20 OR totalPermitCount eq 0>
											<!--- cardState = collapsed --->
											<cfset bodyClass = "collapse">
											<cfset ariaExpanded ="false">
										<cfelse>
											<!--- cardState = expanded--->
											<cfset bodyClass = "collapse show">
											<cfset ariaExpanded ="true">
										</cfif>
										<div class="card-header" id="permitsHeader">
											<h2 class="h4 my-0">
												<button type="button" class="headerLnk text-left w-100 h-100" data-toggle="collapse" data-target="##permitsCardBodyWrap" aria-expanded="#ariaExpanded#" aria-controls="permitsCardBodyWrap">
												Roles in Permissions and Rights Document#plural# (#totalPermitCount#)
												</button>
											</h2>
										</div>
										<div id="permitsCardBodyWrap" class="#bodyClass#" aria-labelledby="permitsHeader" data-parent="##permitAccord">
											<h3 class="small95 mt-2 px-3 mb-0">#prefName# has some role in #totalPermitCount# permissions and rights document#plural#.</h3>
											<div class="card-body pt-0 pb-1 mb-1">
												<ul class="list-group">
													<cfif getPermitsTo.recordcount EQ 0>
														<li class="list-group-item">No recorded permissions and rights documents issued to #encodeForHtml(prefName)#</li>
													<cfelse>
														<li class="list-group-item">
															#getPermitsTo.recordcount# recorded
															<a href="/transactions/Permit.cfm?action=search&execute=true&IssuedToAgent=#encodeForURL(prefName)#&issued_to_agent_id=#agent_id#" target="_blank">
																permissions and rights documents issued to #encodeForHtml(prefName)#
															</a>
														</li>
														<cfloop query="getPermitsTo">
															<cfif len(permit_num) EQ 0><cfset pnrDoc = permit_title><cfelse><cfset pnrDoc=permit_num></cfif>
															<cfif len(pnrDoc) EQ 0><cfset pnrDoc=specific_type ></cfif>
															<li class="list-group-item">
																Document 
																<a href="/transactions/Permit.cfm?action=edit&permit_id=#permit_id#" target="_blank">
																	#pnrDoc#
																</a> (#permit_type#:#specific_type#)
																was issued to #encodeForHtml(prefName)#
															</li>
														</cfloop>
													</cfif>
													<cfif getPermitsFrom.recordcount EQ 0>
														<li class="list-group-item">No recorded permissions and rights documents issued by #encodeForHtml(prefName)#</li>
													<cfelse>
														<li class="list-group-item">
															#getPermitsFrom.recordcount# recorded
															<a href="/transactions/Permit.cfm?action=search&execute=true&IssuedByAgent=#encodeForURL(prefName)#&issued_by_agent_id=#agent_id#" target="_blank">
																permissions and rights documents issued by #encodeForHtml(prefName)#
															</a>
														</li>
														<cfloop query="getPermitsFrom">
															<cfif len(permit_num) EQ 0><cfset pnrDoc = permit_title><cfelse><cfset pnrDoc=permit_num></cfif>
															<cfif len(pnrDoc) EQ 0><cfset pnrDoc=specific_type ></cfif>
															<li class="list-group-item">
																Document 
																<a href="/transactions/Permit.cfm?action=edit&permit_id=#permit_id#" target="_blank">
																	#pnrDoc#
																</a> (#permit_type#:#specific_type#)
																was issued by #encodeForHtml(prefName)#
															</li>
														</cfloop>
													</cfif>
													<cfif getPermitContacts.recordcount EQ 0>
														<li class="list-group-item">#encodeForHtml(prefName)# is the contact for no recorded permissions and rights documents</li>
													<cfelse>
														<li class="list-group-item">
															#getPermitContacts.recordcount# recorded
															<a href="/transactions/Permit.cfm?action=search&execute=true&ContactAgent=#encodeForURL(prefName)#&contact_agent_id=#agent_id#" target="_blank">
																permissions and rights documents where #encodeForHtml(prefName)# is a contact
															</a>
														</li>
														<cfloop query="getPermitContacts">
															<cfif len(permit_num) EQ 0><cfset pnrDoc = permit_title><cfelse><cfset pnrDoc=permit_num></cfif>
															<cfif len(pnrDoc) EQ 0><cfset pnrDoc=specific_type ></cfif>
															<li class="list-group-item">
																#encodeForHtml(prefName)# is contact for 
																<a href="/transactions/Permit.cfm?action=edit&permit_id=#permit_id#" target="_blank">
																	#pnrDoc#
																</a> (#permit_type#:#specific_type#)
															</li>
														</cfloop>
													</cfif>
												</ul>
											</div>
										</div>
									</div>
								</section>
							</cfif>
							<!--- Author of Publications--->
							<section class="accordion" id="publicationSection"> 
								<div class="card mb-2 bg-light">
									<cfquery name="publicationAuthor" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="publicationAuthor_result">
										SELECT distinct
											<cfif ucase(#session.flatTableName#) EQ 'FLAT'>
												MCZBASE.get_publication_citation_count(publication_author_name.publication_id,1) citation_count,
											<cfelse>
												MCZBASE.get_publication_citation_count(publication_author_name.publication_id,0) citation_count,
											</cfif> 
											formatted_publication.publication_id,
											formatted_publication.formatted_publication
										FROM
											agent_name 
											left join publication_author_name on agent_name.agent_name_id = publication_author_name.agent_name_id
											left join formatted_publication on publication_author_name.publication_id = formatted_publication.publication_id
										where
											formatted_publication.format_style = 'long' and
											agent_name.agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
									</cfquery>
									<cfif publicationAuthor.recordcount EQ 1><cfset plural =""><cfelse><cfset plural="s"></cfif>
									<cfif publicationAuthor.recordcount eq 0 and #oneofus# eq 1>
										<!--- cardState = collapsed --->
										<cfset bodyClass = "collapse">
										<cfset ariaExpanded ="false">
									<cfelse>
										<!--- cardState = expanded --->
										<cfset bodyClass = "collapse show">
										<cfset ariaExpanded ="true">
									</cfif>
									<cfset i = 0>
									<cfloop query="publicationAuthor">
										<cfif citation_count eq 0>
											<cfset i = i + 1>
										</cfif>
									</cfloop>
									<cfset citedNumber = (#publicationAuthor.recordcount#-#i#)>
									<div class="card-header">
										<h2 class="h4 my-0">
											<button type="button" class="headerLnk text-left w-100 h-100" data-toggle="collapse" data-target="##publicationCardBodyWrap" aria-expanded="#ariaExpanded#" aria-controls="publicationCardBodyWrap">
											Publication#plural# (#publicationAuthor.recordcount#) [Those Citing MCZ material (#citedNumber#)]
											</button>
										</h2>
									</div>
									<div id="publicationCardBodyWrap" class="#bodyClass# <cfif oneOfUs EQ 1>publicationWrap<cfelse></cfif>" aria-labelledby="publicationHeader" data-parent="##publicationSection">
										<div class="card-body py-1 mb-1">
											<cfif publicationAuthor.recordcount eq 0>
												<ul class="list-group">
													<li class="list-group-item">No publications</li>
												</ul>
											<cfelse>
												<ul class="list-group">
													<cfset i = 1>
													<cfloop query="publicationAuthor">
														<cfif citation_count EQ 1><cfset citplural =""><cfelse><cfset citplural="s"></cfif>
														<li class="border bg-white list-group-item d-flex justify-content-between align-items-center mt-1">
															<a href="/publications/showPublication.cfm?publication_id=#publication_id#" target="_blank">#formatted_publication#</a>
															<cfif citation_count eq 0>
																<cfelse>
																<span class="badge badge-primary badge-pill pb-1">
																#citation_count# citation#citplural#
																</span>
															</cfif>
														</li>
														<cfset i = i + 1>
													</cfloop>
												</ul>
											</cfif>
										</div>
									</div>
								</div>
							</section>
							<!--- records entered --->
							<cfif oneOfUs EQ 1>
								<section class="accordion" id="enteredSection"> 
									<div class="card mb-2 bg-light">
										<cfquery name="entered" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="entered_result">
											select
												count(*) cnt,
												collection,
												collection.collection_id
											from 
												coll_object
												join cataloged_item on coll_object.collection_object_id = cataloged_item.collection_object_id
												left join collection on cataloged_item.collection_id=collection.collection_id
											where
												ENTERED_PERSON_ID=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
											group by
												collection,
												collection.collection_id
										</cfquery>
										<cfif entered.recordcount GT 15 OR entered.recordcount eq 0>
											<!--- cardState = collapsed --->
											<cfset bodyClass = "collapse">
											<cfset ariaExpanded ="false">
										<cfelse>
											<!--- cardState = expanded --->
											<cfset bodyClass = "collapse show">
											<cfset ariaExpanded ="true">
										</cfif>
										<div class="card-header" id="enteredHeader">
											<h2 class="h4 my-0">
												<button type="button" class="headerLnk text-left w-100 h-100" data-toggle="collapse" data-target="##enteredCardBodyWrap" aria-expanded="#ariaExpanded#" aria-controls="enteredCardBodyWrap">
												MCZbase Records Entered (in #entered.recordcount# collections)
												</button>
											</h2>
										</div>
										<div id="enteredCardBodyWrap" class="#bodyClass#" aria-labelledby="enteredHeader" data-parent="##enteredSection">
											<div class="card-body py-1 mb-1">
												<cfif entered.recordcount EQ 0>
													<ul class="list-group">
														<li class="list-group-item">None</li>
													</ul>
												<cfelse>
													<ul class="list-group">
														<cfloop query="entered">
															<li class="list-group-item">
																<a href="/SpecimenResults.cfm?entered_by_id=#agent_id#&collection_id=#collection_id#" target="_blank">#cnt# #collection#</a> specimens
															</li>
														</cfloop>
													</ul>
												</cfif>
											</div>
										</div><!--- end enteredCardBodyWrap --->
									</div>
								</section>
							</cfif>
							<!--- records last edited by --->
							<cfif oneOfUs EQ 1>
								<section class="accordion" id="lastEditSection"> 
									<div class="card mb-2 bg-light">
										<cfquery name="lastEdit" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="lastEdit_result">
											select 
												count(*) cnt,
												collection,
												collection.collection_id
											from 
												coll_object
												join cataloged_item on coll_object.collection_object_id = cataloged_item.collection_object_id
												left join collection on cataloged_item.collection_id=collection.collection_id
											where 
												LAST_EDITED_PERSON_ID=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
											group by
												collection,
												collection.collection_id
										</cfquery>
										<cfif lastEdit.recordcount GT 15 OR lastEdit.recordcount eq 0>
											<!--- cardState = collapsed --->
											<cfset bodyClass = "collapse">
											<cfset ariaExpanded ="false">
										<cfelse>
											<!--- cardState = expanded --->
											<cfset bodyClass = "collapse show">
											<cfset ariaExpanded ="true">
										</cfif>
										<div class="card-header" id="lastEditHeader">
											<h2 class="h4 my-0">
												<button type="button" class="headerLnk text-left w-100 h-100" data-toggle="collapse" data-target="##lastEditCardBodyWrap" aria-expanded="#ariaExpanded#" aria-controls="lastEditCardBodyWrap">
												MCZbase Records Last Edited By this agent (<cfif #lastEdit.cnt# gt 0>#lastEdit.cnt#<cfelse>0</cfif>)
												</button>
											</h2>
										</div>
										<div id="lastEditCardBodyWrap" class="#bodyClass#" aria-labelledby="lastEditHeader" data-parent="##lastEditSection">
											<div class="card-body py-1 mb-1">
												<cfif lastEdit.recordcount EQ 0>
													<ul class="list-group">
														<li class="list-group-item">None</li>
													</ul>
												<cfelse>
													<ul class="list-group">
														<cfloop query="lastEdit">
															<li class="list-group-item">
																<a href="/SpecimenResults.cfm?edited_by_id=#agent_id#&collection_id=#collection_id#" target="_blank">#cnt# #collection#</a> specimens
															</li>
														</cfloop>
													</ul>
												</cfif>
											</div>
										</div><!--- end lastEditCardBodyWrap --->
									</div>
								</section>
							</cfif>
							<!--- foreign key relationships to other tables --->
							<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_agents")>
								<section class="card mb-2 bg-light">
									<!--- always open, not a collapsable card --->
									<cftry>
										<cfquery name="getFKFields" datasource="uam_god">
											SELECT dba_constraints.table_name, column_name, delete_rule 
											FROM dba_constraints
												left join dba_cons_columns on dba_constraints.constraint_name = dba_cons_columns.constraint_name and dba_constraints.owner = dba_cons_columns.owner
											WHERE r_constraint_name in (select constraint_name from dba_constraints where table_name='AGENT')
											ORDER BY dba_constraints.table_name
										</cfquery>
										<div class="accordion card-header py-0"><!---accordion class needs to be there for the break-inside:avoid attribute--->
											<h2 class="h4 py-1 text-dark-gray w-100 my-0 px-2">Agent Record Link Summary</h2>
										</div>
										<cfset relatedTo = StructNew() >
										<cfset okToDelete = true>
										<cfloop query="getFKFields">
											<cfif getFKFields.delete_rule EQ "NO ACTION">
												<cfquery name="getRels" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getRels_result">
													SELECT count(*) as ct 
													FROM #getFKFields.table_name#
													WHERE #getFKFields.column_name# = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#agent_id#">
												</cfquery>
												<cfif getRels.ct GT 0>
													<!--- note, since preferred name is required, and can not be deleted, and agent_name fk agent_id fk delete rule is NO ACTION, this will never be enabled --->
													<cfset okToDelete = false>
													<cfset relatedTo["#getFkFields.table_name#.#getFkFields.column_name#"] = getRels.ct>
												</cfif>
											</cfif>
										</cfloop>
										<div class="card-body py-1 mt-1 mb-1">
											<cfif okToDelete>
												<h3 class="small95 px-2 mb-0">This agent is not used and is eligible for deletion</h3>
											<cfelse>
												<h3 class="small95 px-2 mb-0">This agent record is linked to these other MCZbase tables:</h3>
											</cfif>
											<ul class="list-group mt-0">
												<cfloop collection="#relatedTo#" item="key">
													<li class="list-group-item">#key# (#relatedTo[key]#)</li>
												</cfloop>
											</ul>
										</div>
									<cfcatch>
										<!--- some issue with user access to metadata tables --->
									</cfcatch>
									</cftry>
								</section>
							</cfif>
						</div>
					</div>
				</div>
			</cfloop><!--- getAgent --->
		</div>
	</main>
</cfoutput>
<cfinclude template = "/shared/_footer.cfm">
