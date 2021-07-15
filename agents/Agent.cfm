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
<cfinclude template="/agents/component/functions.cfc" runOnce="true">

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
		left join agent_name prefername on agent.preferred_agent_name_id = prefername.agent_name_id
		left join person on agent.agent_id = person.person_id
	WHERE
		agent.agent_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#agent_id#">
</cfquery>
<cfoutput>
	<div class="<cfif isdefined("session.roles") AND listfindnocase(session.roles,"coldfusion_user")>container-xl px-0<cfelse>container-xl px-0</cfif>">
		<div class="row mx-0">
			<cfloop query="getAgent">
				<cfset prefName = getAgent.preferred_agent_name>
				<div id="agentTopDiv" class="col-12 mt-2">
					<!--- agent name, biography, remarks as one wide section across top of page --->
					<div class="row mx-0">
						<div class="col-auto px-3">
							<cfset dates ="">
							<cfif getAgent.agent_type EQ "person">
								<cfif isdefined("session.roles") AND listfindnocase(session.roles,"coldfusion_user") OR len(getAgent.death_date) GT 0>
									<!--- add birth death dates --->
									<cfset dates = assembleYearRange(start_year="#getAgent.birth_date#",end_year="#getAgent.death_date#",year_only=false) >
								</cfif>
							<cfelse>
								<!--- add start and end years when implemented --->
								<cfset dates = assembleYearRange(start_year="#getAgent.start_date#",end_year="#getAgent.end_date#",year_only=true) >
							</cfif>
							<cfif getAgent.vetted EQ 1 ><cfset vetted_marker="*"><cfelse><cfset vetted_marker=""></cfif> 
							<h1 class="h2 mt-2 mb-2">#preferred_agent_name# #vetted_marker# #dates# <span class="small">#agent_type#</span></h1>
						</div>
						<div class="col-12 col-md-1 mt-0 mt-md-2 float-right">
							<!--- edit button at upper right for those authorized to edit agent records --->
							<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_agents")>
								<a href="/agents/editAgent.cfm?agent_id=#agent_id#" class="btn btn-primary btn-xs float-right">Edit</a>
							</cfif>
						</div>
					</div>
					<div class="row mx-0">
						<div class="col-10 px-3">
							<ul class="list-group py-0 list-unstyled px-0">
								<cfif len(agentguid) GT 0>
									<cfif len(ctguid_type_agent.resolver_regex) GT 0>
										<cfset guidLink = REReplace(agentguid,ctguid_type_agent.resolver_regex,ctguid_type_agent.resolver_replacement) >
									<cfelse>
										<cfset guidLink = agentguid >
									</cfif>
									<li class="list-group-item px-0 pt-0 pb-2">
										<a href="#guidLink#">#agentguid#</a>
									</li>
								</cfif>
							</ul>
						</div>
					</div>
					<!--- full width, biograhy and remarks, presented with no headings --->
					<div class="row mx-0">
						<div class="col-12 col-md-10 pl-0">
							<div class="col-12 px-3 mb-2">
								#biography#
							</div>
							<cfif oneOfUs EQ 1>
								<cfif len(agent_remarks) GT 0>
									<div class="col-12 px-2 my-1 mx-0 mx-md-1 mt-md-1 mb-md-2 internalRemarks card">
										<h3 class="h5 mb-0">Internal Remarks</h3>
										#agent_remarks#
									</div>
								</cfif>
							</cfif>

						</div>
					</div>
				</div>
				<!--- two columns of information about the agent gleaned from related tables --->
				<div class="col-12" id="agentBlocks">
					<div class="d-block mb-5 float-left px-0 px-md-1 col-12 col-md-3 col-xl-3 rounded rounded h-auto">
						<!--- agent names --->
							<section class="accordion">
								<div class="card mb-2 bg-light">
									<!--- always open, not a collapsable card --->
									<div class="card-header py-0">
										<h2 class="h4 my-1 mx-2">Names for this agent</h2>
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
									<div class="card-body pt-1 pb-2 bg-teal">
										<ul class="list-group">
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
	
							<cfif #getAgent.agent_type# IS "group" OR #getAgent.agent_type# IS "expedition" OR #getAgent.agent_type# IS "vessel">
								<!--- group members (members within this group agent) --->
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
											<h2 class="float-left btn-link h4 w-100 mx-2 my-0" data-toggle="collapse" data-target="##groupMembersCardBodyWrap" aria-expanded="#ariaExpanded#" aria-controls="groupMembersCardBodyWrap">
												Group Members (#groupMembers.recordcount#)
											</h2>
										</div>
										<div id="groupMembersCardBodyWrap" class="#bodyClass#" aria-labelledby="groupMembersHeader" data-parent="##groupMembersSection">
											<cfif groupMembers.recordcount GT 0>
												<h3 class="h4 px-3 mb-0">#prefName# consists of #groupMembers.recordcount# member#plural#</h3>
											</cfif>
											<div class="card-body py-1 mb-1">
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
									<cfquery name="getMedia" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getMedia_result">
										SELECT media.media_id,
											mczbase.get_media_descriptor(media.media_id) as descriptor,
											mczbase.get_medialabel(media.media_id,'subject') as subject,
											media.media_uri,
											media.media_type,
											CASE WHEN MCZBASE.is_mcz_media(media.media_id) = 1 THEN ctmedia_license.uri ELSE MCZBASE.get_media_dctermsrights(media.media_id) END as license_uri, 
											CASE WHEN MCZBASE.is_mcz_media(media.media_id) = 1 THEN ctmedia_license.display ELSE MCZBASE.get_media_dcrights(media.media_id) END as license_display, 
											MCZBASE.get_media_credit(media.media_id) as credit 
										FROM media_relations 
											left join media on media_relations.media_id = media.media_id
											left join ctmedia_license on media.media_license_id=ctmedia_license.media_license_id
										WHERE media_relationship like '% agent'
											and media_relationship <> 'created by agent'
											and related_primary_key=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
											and mczbase.is_media_encumbered(media.media_id) < 1
									</cfquery>
										<cfif getMedia.recordcount GT 20 OR getMedia.recordcount EQ 0>
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
										<h2 class="float-left btn-link h4 w-100 mx-2 my-0" data-toggle="collapse" data-target="##mediaCardBodyWrap" aria-expanded="#ariaExpanded#" aria-controls="mediaCardBodyWrap">
											Subject of #getMedia.recordcount# media record#plural#
										</h2>
									</div>
									<div id="mediaCardBodyWrap" class="#bodyClass#" aria-labelledby="mediaHeader" data-parent="##mediaSection">
										<cfif getMedia.recordcount eq 0>
											<cfset mediaLink = "No Media records">
										<cfelse>
											<cfset mediaLink = "<a href='/MediaSearch.cfm?action=search&related_primary_key__1=#agent_id#&relationship__1=agent' target='_blank'>#getMedia.recordcount# Media Record#plural#</a>">
										</cfif>
										<h3 class="h4 px-3 mb-0">#prefName# is the subject of #mediaLink#.</h3>
										<div class="card-body py-1 mb-1">
											<cfif getMedia.recordcount GT 0>
												<cfloop query="getMedia">
													<ul class="list-group list-group-horizontal-md border p-2 my-2">
													<cfif getMedia.media_type IS "image">
														<li class="col-auto px-0">
															<a class="d-block" href="/MediaSet.cfm?media_id=#getMedia.media_id#"><img src="#getMedia.media_uri#" alt="#getMedia.descriptor#" width="75"></a>
														</li>
														<li class="col-10 col-md-8 col-xl-10 px-0">
															<ul class="list-group small">
																<li class="list-group-item pt-0"><a href="/media/#getMedia.media_id#">Media Details</a></li>
																<li class="list-group-item pt-0">#getMedia.descriptor#</li>
																<li class="list-group-item pt-0">#getMedia.subject#</li>
																<li class="list-group-item pt-0"><a href="#getMedia.license_uri#">#getMedia.license_display#</a></li>
																<li class="list-group-item pt-0">#getMedia.credit#</li>
															</ul>
														
														</li>
													</cfif>
													</ul>
												</cfloop>
											</cfif>
										</div>
									</div><!--- end mediaCardBodyWrap --->
								</div>
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
											<h2 class="float-left btn-link h4 w-100 mx-2 my-0" data-toggle="collapse" data-target="##elecAddrCardBodyWrap" aria-expanded="true" aria-controls="elecAddrCardBodyWrap">
												Phone/Email
											</h2>
										</div>
										<div id="elecAddrCardBodyWrap" class="collapse show" aria-labelledby="elecAddrHeader" data-parent="##eaddressSection">
											<div class="card-body py-1 mb-1">
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
	
							<cfif oneOfUs EQ 1>
								<!--- mailing addresses --->
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
											<h2 class="float-left btn-link h4 w-100 mx-2 my-0" data-toggle="collapse" data-target="##addressCardBodyWrap" aria-expanded="true" aria-controls="addressCardBodyWrap">
												Postal Addresses
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
															<cfset listgroupclass="border-light">
														</cfif>
																
															<h3 class="h4 mb-1 mt-2"> <span class="caps">#addr_type#</span> Address &ndash;&nbsp;#addressCurrency##rem##addressUse#</h3>
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
										<h2 class="float-left btn-link h4 w-100 mx-2 my-0" data-toggle="collapse" data-target="##relationshipsCardBodyWrap" aria-expanded="#ariaExpanded#" aria-controls="relationshipsCardBodyWrap">
											Relationships with other agents (#totalRelCount#)
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
											<cfif oneOfUs EQ 1>
												<cfquery name="getRevAgentRel" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
													SELECT agent_relationship, agent_id as related_agent_id, MCZBASE.get_agentnameoftype(agent_id) as related_name,
														agent_remarks
													FROM agent_relations 
													WHERE
														related_agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
														and agent_relationship not like '% duplicate of'
													ORDER BY agent_relationship
												</cfquery>
												<cfif getRevAgentRel.recordcount EQ 0>
													<ul class="list-group">
														<li class="list-group-item">None from other agents</li>
													</ul>
												<cfelse>
													<ul class="list-group">
														<cfloop query="getRevAgentRel">
															<cfif len(getRevAgentRel.agent_remarks) GT 0><cfset rem=" [#getRevAgentRel.agent_remarks#]"><cfelse><cfset rem=""></cfif>
															<li class="list-group-item"><a href="/agents/Agent.cfm?agent_id=#related_agent_id#">#related_name#</a> #agent_relationship# #getAgent.preferred_agent_name##rem#</li>
														</cfloop>
													</ul>
												</cfif>
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
									left join preferred_agent_name on group_member.group_agent_id = preferred_agent_name.agent_id
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
											<h2 class="float-left btn-link h4 w-100 mx-2 my-0" data-toggle="collapse" data-target="##groupMembershipCardBodyWrap" aria-expanded="#ariaExpanded#" aria-controls="groupMembershipCardBodyWrap">
												Group Membership (#groupMembership.recordcount#)
											</h2>
										</div>
										<div id="groupMembershipCardBodyWrap" class="#bodyClass#" aria-labelledby="groupMembershipHeader" data-parent="##groupMembershipSection">
											<cfif groupMembership.recordcount GT 0>
												<h2 class="h4 px-3 mb-0">#prefName# is a member of #groupMembership.recordcount# group#plural#</h2>
											</cfif>
											<div class="card-body py-1 mb-1">
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
					<div class="d-block mb-5 float-left h-auto px-0 px-md-1 col-12 col-md-4 col-xl-4">
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
										<h2 class="float-left btn-link h4 w-100 mx-2 my-0" data-toggle="collapse" data-target="##collectorCardBodyWrap1" aria-expanded="#ariaExpanded#" aria-controls="collectorCardBodyWrap1">
											Collector (in #getAgentCollScope.recordcount# collection#plural#)
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
															<li class="list-group-item">#getAgentCollScope.collection_cde# (<a href="/SpecimenResults.cfm?collector_agent_id=#agent_id#&collection_id=#getAgentCollScope.collection_id#" target="_blank">#getAgentCollScope.ct# record#plural#</a>) #yearbit#</li>
														</cfif>
													</cfloop>
												</ul>
												<cfif len(earlyeststart) GT 0 AND len(latestend) GT 0>
													<cfif LSParseNumber(earlyeststart) +80 LT LSParseNumber(latestend)>
														<h3 class="h4">Range of years collected is greater that 80 (#earlyeststart#-#latestend#) </h3>
													</cfif>
												</cfif>
											</cfif><!--- getAgentCollScope.recordcount > 1 --->
										</div>
									</div><!--- end collectorCardBodyWrap --->
								</div>
							</section>
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
										<h2 class="float-left btn-link h4 w-100 mx-2 my-0" data-toggle="collapse" data-target="##collectorCardBodyWrap2" aria-expanded="#ariaExpanded#" aria-controls="collectorCardBodyWrap2">
											Collector (in #getAgentFamilyScope.recordcount# famil#fplural#)
										</h2>
									</div>
									<div id="collectorCardBodyWrap2" class="#bodyClass#" aria-labelledby="collectorHeader2" data-parent="##collectorSection2">
									<!---	<cfif getAgentFamilyScope2.recordcount GT 0>--->
										<div class="card-body py-1 mb-1">
											<div class="w-100"> 
												<!---<h3 class="h4 px-2 mb-0">Families Collected</h3>--->
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
																<li class="list-group-item">#getAgentFamilyScope.phylclass#: #getAgentFamilyScope.family# (<a href="/SpecimenResults.cfm?collector_agent_id=#agent_id#&family=#getAgentFamilyScope.family#" target="_blank">#getAgentFamilyScope.ct# record#plural#</a>) #yearbit#</li>
															</cfif>
													</cfloop>
												</ul>
											</div>
										</div>
							<!---			</cfif>--->
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
										<h2 class="float-left btn-link h4 w-100 mx-2 my-0" data-toggle="collapse" data-target="##preparatorCardBodyWrap" aria-expanded="#ariaExpanded#" aria-controls="preparatorCardBodyWrap">
											Preparator (of material in #getAgentPrepScope.recordcount# collection#plural#)
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
															<li class="list-group-item">#getAgentPrepScope.collection_cde# (<a href="/SpecimenResults.cfm?coll_role=p&coll=#encodeForURL(getAgent.preferred_agent_name)#&collection_id=#getAgentPrepScope.collection_id#" target="_blank">#getAgentPrepScope.ct# record#plural#</a>) #yearbit#</li>
														</cfif>
													</cfloop>
												</ul>
												<cfif len(earlyeststart) GT 0 AND len(latestend) GT 0>
													<cfif LSParseNumber(earlyeststart) +80 LT LSParseNumber(latestend)>
														<h3 class="h5 px-2 mb-0">Range of years collected is greater that 80 (#earlyeststart#-#latestend#) </h2>
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
										<h2 class="float-left btn-link h4 w-100 mx-2 my-0" data-toggle="collapse" data-target="##determinerCardBodyWrap" aria-expanded="#ariaExpanded#" aria-controls="determinerCardBodyWrap">
											Determiner (in #identification.recordcount# collection#plural#) 
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
															#cnt# identifications for <a href="/SpecimenResults.cfm?identified_agent_id=#agent_id#&collection_id=#collection_id#">
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
											attributes,
											cataloged_item,
											collection
										where
											cataloged_item.collection_object_id=attributes.collection_object_id and
											cataloged_item.collection_id=collection.collection_id and
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
										<h2 class="float-left btn-link h4 w-100 mx-2 my-0" data-toggle="collapse" data-target="##attributeCardBodyWrap" aria-expanded="#ariaExpanded#" aria-controls="attributeCardBodyWrap">
											Attribute Determiner (#attributes.recordcount#)
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
															<a href="/SpecimenResults.cfm?attributed_determiner_agent_id=#agent_id#&collection_id=#attributes.collection_id#">
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
							<section class="accordion" id="namedgroupSection"> 
								<div class="card mb-2 bg-light">
									<cfquery name="getNamedGroups" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
										select collection_name, underscore_collection_id, mask_fg
										from underscore_collection 
										WHERE
											underscore_agent_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#agent_id#">
										order by collection_name
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
										<h2 class="float-left btn-link h4 w-100 mx-2 my-0" data-toggle="collapse" data-target="##namedgroupCardBodyWrap" aria-expanded="#ariaExpanded#" aria-controls="namedgroupCardBodyWrap">
											Agent for Named Groups of cataloged items (#getNamedGroups.recordcount#)
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
															<li class="list-group-item"><a href="/grouping/showNamedCollection.cfm?underscore_collection_id=#underscore_collection_id#" target="_blank">#collection_name#</a></li>
														<cfelse>
															<li class="list-group-item">#collection_name#</li>
														</cfif>
													</cfloop>
												</ul>
											</cfif>
										</div>
									</div><!--- end namedgroupCardBodyWrap --->
								</div>
							</section>
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
										<cfif getLatLongDet.cnt GT 20 OR getLatLongDet.cnt eq 0>
											<!--- cardState = collapsed --->
											<cfset bodyClass = "collapse">
											<cfset ariaExpanded ="false">
										<cfelse>
											<!--- cardState = expanded --->
											<cfset bodyClass = "collapse show">
											<cfset ariaExpanded ="true">
										</cfif>
										<div class="card-header" id="georefHeader">
											<h2 class="float-left btn-link h4 w-100 mx-2 my-0" data-toggle="collapse" data-target="##georefCardBodyWrap" aria-expanded="#ariaExpanded#" aria-controls="georefCardBodyWrap">
												Georeferences (#getLatLongDet.cnt# determined)
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
											SELECT count(distinct media_id) ct,
												media_label
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
										<cfif #getMediaCreation.ct# EQ 1><cfset plural=""><cfelse><cfset plural="s"></cfif>#plural#
										<cfif #media_assd_relations.ct# EQ 1><cfset plural=""><cfelse><cfset plural="s"></cfif>
										<cfif totallabels EQ 1><cfset plural=""><cfelse><cfset plural="s"></cfif>
										<div class="card-header" id="mediametaHeader">
											<h2 class="float-left btn-link h4 w-100 mx-2 my-0" data-toggle="collapse" data-target="##mediametaCardBodyWrap" aria-expanded="#ariaExpanded#" aria-controls="mediametaCardBodyWrap">
												Media Records (#getMediaCreation.ct# record#plural#, #media_assd_relations.ct# relationship#plural#, #totallabels# label#plural# ) 
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
															<a href="/media/findMedia.cfm?execute=true&created_by_agent_name=#encodeForURL(prefName)#&created_by_agent_id=#agent_id#">Media Record#plural#</a>
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
					<div class="d-block mb-5 float-left h-auto col-12 col-md-5 col-xl-5 px-0 px-md-1">
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
											<h2 class="float-left btn-link h4 w-100 mx-2 my-0" data-toggle="collapse" data-target="##loanItemCardBodyWrap" aria-expanded="#ariaExpanded#" aria-controls="loanItemCardBodyWrap">
												Reconciled loan items (#loan_item.recordcount#)
											</h2>
										</div>
										<div id="loanItemCardBodyWrap" class="#bodyClass#" aria-labelledby="loanItemHeader" data-parent="##loanItemSection">
											<cfif loan_item.recordcount GT 0>
												<h3 class="h4 px-3 mt-2 mb-0">#prefName# reconciled #loan_item.recordcount# loan item#plural#</h3>
											</cfif>
											<div class="card-body py-1 mb-1">
												<ul class="list-group">
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
											<h2 class="float-left btn-link h4 w-100 mx-2 my-0" data-toggle="collapse" data-target="##shipmentsCardBodyWrap" aria-expanded="#ariaExpanded#" aria-controls="shipmentsCardBodyWrap">
												Roles in Shipment#plural# (#totalShipCount#)
											</h2>
										</div>
										<div id="shipmentsCardBodyWrap" class="#bodyClass#" aria-labelledby="shipmenstHeader" data-parent="##shipmentsSection">
											<cfif totalShipCount GT 0>
												<h3 class="h4 px-3 mb-0">#prefName# has some role in #totalShipCount# shipment#plural#</h3>
											</cfif>
											<div class="card-body py-1 mb-1">
												<ul class="list-group">
													<cfif packedBy.recordcount EQ 0>
														<li class="list-group-item">Packed no shipments for transactions</li>
													</cfif>
													<cfloop query="packedBy">
														<li class="list-group-item">
															Packed Shipment for #transaction_type#
															<a href="/Transactions.cfm?action=findAll&execute=true&collection_id=#collection_id#&number=#specific_number#">
																#collection# #specific_number#
															</a>
														</li>
													</cfloop>
													<cfif shippedTo.recordcount EQ 0>
														<li class="list-group-item">Recipient of no shipments for transactions</li>
													</cfif>
													<cfloop query="shippedFrom">
														<li class="list-group-item">
															Sender of shipment for #transaction_type#
															<a href="/Transactions.cfm?action=findAll&execute=true&collection_id=#collection_id#&number=#specific_number#">
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
											SELECT count(*) as ct,
												ENCUMBRANCE
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
										<cfif getEncumbCount.recordcount GT 20 OR getEncumbCount.recordcount eq 0>
											<!--- cardState = collapsed --->
											<cfset bodyClass = "collapse">
											<cfset ariaExpanded ="false">
										<cfelse>
											<!--- cardState = expanded --->
											<cfset bodyClass = "collapse show">
											<cfset ariaExpanded ="true">
										</cfif>
										<div class="card-header" id="encumbrancesHeader">
						<!---					<cfif getEncumbCount.ct GT 0>
												<cfset encumbCount = "(#getEncumbCount.ct#)">
											<cfelse>
												<cfset encumbCount = "">
											</cfif>--->
											<h2 class="float-left btn-link h4 w-100 mx-2 my-0" data-toggle="collapse" data-target="##encumbrancesCardBodyWrap" aria-expanded="#ariaExpanded#" aria-controls="encumbrancesCardBodyWrap">
												Encumbrances (#getEncumbCount.ct#)
											</h2>
										</div>
										<div id="encumbrancesCardBodyWrap" class="#bodyClass#" aria-labelledby="encumbrancesHeader" data-parent="##encumbrancesSection">
											<div class="card-body py-1 mb-1">
												<ul class="list-group">
													<cfif getEncumbCount.ct EQ 0>
														<li class="list-group-item">Owns No Encumbrances</li>
													<cfelse>
													<cfloop query="getEncumb">
															<li class="list-group-item">#getEncumb.ENCUMBRANCE# (#getEncumb.ct#)</li>
														</cfloop>
													</cfif>
													<cfloop query="coll_object_encumbrance">
														<li class="list-group-item">
															Encumbered 
															<a href="/SpecimenResults.cfm?encumbering_agent_id=#agent_id#&collection_id=#collection_id#">
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
											<h2 class="float-left btn-link h4 w-100 mx-2 my-0" data-toggle="collapse" data-target="##projectCardBodyWrap" aria-expanded="#ariaExpanded#" aria-controls="projectCardBodyWrap">
												Project Roles (#getProjRoles.recordcount#)
											</h2>
										</div>
										<div id="projectCardBodyWrap" class="#bodyClass#" aria-labelledby="projectHeader" data-parent="##projectSection">
											<div class="card-body py-1 mb-1">
												<cfif getProjRoles.recordcount EQ 0>
													<ul class="list-group"><li class="list-group-item">No project roles in MCZbase</li></ul>
												<cfelse>
													<ul class="list-group">
														<cfloop query="getProjRoles">
															<li class="list-group-item">#getProjRoles.role# for <a href="/ProjectDetail.cfm?project_id=#project_id#">#project_name#</a></li>
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
										<cfquery name="getTransCount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getTransactions_result">
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
											<cfquery name="getTransactions" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getTransactions_result">
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
											<cfquery name="getTransactions" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getTransactions_result">
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
											<h2 class="float-left btn-link h4 w-100 mx-2 my-0" data-toggle="collapse" data-target="##transactionsCardBodyWrap" aria-expanded="#ariaExpanded#" aria-controls="transactionsCardBodyWrap">
												Roles in Transaction#plural# (#totalTransCount#)
											</h2>
										</div>
										<div id="transactionsCardBodyWrap" class="#bodyClass#" aria-labelledby="transactionsHeader" data-parent="##transactionsSection">
											<cfif getTransCount.ct EQ 0>
												<h3 class="h4 px-3 mb-0">#prefName# has some role in #totalTransCount# transaction#plural#.</h3>
											<cfelse>
												<h3 class="h4 px-3 mb-0">
													#prefName# has some role in 
													<a href="/Transactions.cfm?action=findAll&execute=true&collection_id=-1&agent_1=#encodeForURL(prefName)#&agent_1_id=#agent_id#" >
													#getTransCount.ct# Transaction#plural#
													</a>
												</h3>
											</cfif>
											<div class="card-body py-1 mb-1">
												<cfif getTransactions.recordcount EQ 0>
													<ul class="list-group"><li class="list-group-item">Not a Transaction Agent in MCZbase</li></ul>
												<cfelse>
													<ul class="list-group">
														<cfset lastTrans ="">
														<cfset statusDate ="">
														<cfloop query="getTransactions">
															<cfif oversizeSet IS true>
																<li class="list-group-item">
																	<cfif transaction_type IS "deaccession">
																		<cfset targetStatus="deacc_status">
																	<cfelse>
																		<cfset targetStatus="#transaction_type#_status">
																	</cfif>
																	<a href="/Transactions.cfm?execute=true&action=find#transaction_type#&collection_id=#collection_id#&#targetStatus#=#status#&trans_agent_role_1=#trans_agent_role#&agent_1=#encodeForURL(prefName)#&agent_1_id=#agent_id#">
																		#getTransactions.ct# 
																	</a>
																	<span class="text-capitalize">#transaction_type#</span> 
																	#trans_agent_role#
																	#status# in #collection_cde#
																	<span><!-- workaround --></span>
																</li>
															<cfelse>
																<cfif lastTrans NEQ getTransactions.specific_number>
																	<cfif lastTrans NEQ "">
																		#statusDate#</li>
																	</cfif>
																	<li class="list-group-item">
																		<span class="text-capitalize">#transaction_type#</span> 
																		<a href="/Transactions.cfm?number=#specific_number#&action=findAll&execute=true">#specific_number#</a>
																		#trans_agent_role#
																		<cfset statusDate = "(#getTransactions.status# #trans_date#)">
																<cfelse>
																		, #trans_agent_role#
																</cfif>
																<cfset lastTrans ="#getTransactions.specific_number#">
															</cfif>
														</cfloop>
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
											<h2 class="float-left btn-link h4 w-100 mx-2 my-0" data-toggle="collapse" data-target="##permitsCardBodyWrap" aria-expanded="#ariaExpanded#" aria-controls="permitsCardBodyWrap">
												Roles in Permissions and Rights Document#plural# (#totalPermitCount#)
											</h2>
										</div>
										<div id="permitsCardBodyWrap" class="#bodyClass#" aria-labelledby="permitsHeader" data-parent="##permitAccord">
											<h3 class="h4 px-3 mb-0">#prefName# has some role in #totalPermitCount# permissions and rights document#plural#.</h3>
											<div class="card-body py-1 mb-1">
												<ul class="list-group">
													<cfif getPermitsTo.recordcount EQ 0>
														<li class="list-group-item">No recorded permissions and rights documents issued to #encodeForHtml(prefName)#</li>
													<cfelse>
														<li class="list-group-item">
															#getPermitsTo.recordcount# recorded
															<a href="/transactions/Permit.cfm?action=search&execute=true&IssuedToAgent=#encodeForURL(prefName)#&issued_to_agent_id=#agent_id#">
																permissions and rights documents issued to #encodeForHtml(prefName)#
															</a>
														</li>
														<cfloop query="getPermitsTo">
															<cfif len(permit_num) EQ 0><cfset pnrDoc = permit_title><cfelse><cfset pnrDoc=permit_num></cfif>
															<cfif len(pnrDoc) EQ 0><cfset pnrDoc=specific_type ></cfif>
															<li class="list-group-item">
																Document 
																<a href="/transactions/Permit.cfm?action=edit&permit_id=#permit_id#">
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
															#getPermitsTo.recordcount# recorded
															<a href="/transactions/Permit.cfm?action=search&execute=true&IssuedByAgent=#encodeForURL(prefName)#&issued_by_agent_id=#agent_id#">
																permissions and rights documents issued by #encodeForHtml(prefName)#
															</a>
														</li>
														<cfloop query="getPermitsFrom">
															<cfif len(permit_num) EQ 0><cfset pnrDoc = permit_title><cfelse><cfset pnrDoc=permit_num></cfif>
															<cfif len(pnrDoc) EQ 0><cfset pnrDoc=specific_type ></cfif>
															<li class="list-group-item">
																Document 
																<a href="/transactions/Permit.cfm?action=edit&permit_id=#permit_id#">
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
															#getPermitsTo.recordcount# recorded
															<a href="/transactions/Permit.cfm?action=search&execute=true&ContactAgent=#encodeForURL(prefName)#&contact_agent_id=#agent_id#">
																permissions and rights documents where #encodeForHtml(prefName)# is a contact
															</a>
														</li>
														<cfloop query="getPermitContacts">
															<cfif len(permit_num) EQ 0><cfset pnrDoc = permit_title><cfelse><cfset pnrDoc=permit_num></cfif>
															<cfif len(pnrDoc) EQ 0><cfset pnrDoc=specific_type ></cfif>
															<li class="list-group-item">
																#encodeForHtml(prefName)# is contact for 
																<a href="/transactions/Permit.cfm?action=edit&permit_id=#permit_id#">
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
							<!--- Author --->
							<section class="accordion" id="publicationSection"> 
								<div class="card mb-2 bg-light">
									<cfquery name="publicationAuthor" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="publicationAuthor_result">
										SELECT
											count(citation.collection_object_id) citation_count,
											formatted_publication.publication_id,
											formatted_publication.formatted_publication
										FROM
											agent_name 
											left join publication_author_name on agent_name.agent_name_id = publication_author_name.agent_name_id
											left join formatted_publication on publication_author_name.publication_id = formatted_publication.publication_id
											left join citation on formatted_publication.publication_id = citation.publication_id
										where
											formatted_publication.format_style = 'long' and
											agent_name.agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
										group by
											formatted_publication.publication_id,
											formatted_publication.formatted_publication
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
										<h2 class="float-left btn-link h4 w-100 mx-2 my-0" data-toggle="collapse" data-target="##publicationCardBodyWrap" aria-expanded="#ariaExpanded#" aria-controls="publicationCardBodyWrap">
											Publication#plural# (#publicationAuthor.recordcount#) [Those Citing MCZ material (#citedNumber#)]
										</h2>
									</div>
									<div id="publicationCardBodyWrap" class="#bodyClass#" aria-labelledby="publicationHeader" data-parent="##publicationSection">
										<div class="card-body py-1 mb-1">
											<cfif publicationAuthor.recordcount EQ 0>
												<ul class="list-group">
													<li class="list-group-item">No Publication Citing MCZ material</li>
												</ul>
											<cfelse>
												<ul class="list-group">
													<cfset i = 1>
													<cfloop query="publicationAuthor">
														<cfif citation_count EQ 1><cfset citplural =""><cfelse><cfset citplural="s"></cfif>
														<li class="border list-group-item d-flex justify-content-between align-items-center mt-1 pb-1">
															<a href="/SpecimenUsage.cfm?action=search&publication_id=#publication_id#">#formatted_publication#</a>
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
												coll_object,
												cataloged_item,
												collection
											where 
												coll_object.collection_object_id = cataloged_item.collection_object_id and
												cataloged_item.collection_id=collection.collection_id and
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
											<h2 class="float-left btn-link h4 w-100 mx-2 my-0" data-toggle="collapse" data-target="##enteredCardBodyWrap" aria-expanded="#ariaExpanded#" aria-controls="enteredCardBodyWrap">
												MCZbase Records Entered (in #entered.recordcount# collections)
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
												coll_object,
												cataloged_item,
												collection
											where 
												coll_object.collection_object_id = cataloged_item.collection_object_id and
												cataloged_item.collection_id=collection.collection_id and
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
											<h2 class="float-left btn-link h4 w-100 mx-2 my-0" data-toggle="collapse" data-target="##lastEditCardBodyWrap" aria-expanded="#ariaExpanded#" aria-controls="lastEditCardBodyWrap">
												MCZbase Records Last Edited By this agent (<cfif #lastEdit.cnt# gt 0>#lastEdit.cnt#<cfelse>0</cfif>)
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
																<a href="/SpecimenResults.cfm?edited_by_id=#agent_id#&collection_id=#collection_id#">#cnt# #collection#</a> specimens
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
											<h2 class="h4 my-1 mx-2 px-1">Agent Record Link Summary</h2>
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
													<!--- note, since preferred name is required, and can't be deleted, and agent_name fk agent_id fk delete rule is NO ACTION, this will never be enabled --->
													<cfset okToDelete = false>
													<cfset relatedTo["#getFkFields.table_name#.#getFkFields.column_name#"] = getRels.ct>
												</cfif>
											</cfif>
										</cfloop>
										<div class="card-body py-1 mb-1">
											<cfif okToDelete>
												<h3 class="h4 px-2 mb-0">This agent is not used and is eligible for deletion</h3>
											<cfelse>
												<h3 class="h4 px-2 mb-0">This agent record is linked to these other MCZbase tables:</h3>
											</cfif>
											<ul class="list-group">
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
			</cfloop><!--- getAgent --->
		</div>
	</div>
</cfoutput>

<cfinclude template = "/shared/_footer.cfm">
