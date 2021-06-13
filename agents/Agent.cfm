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
	<cflocation url="/agents/Agents.cfm">
</cfif>

<cfinclude template = "/shared/_header.cfm">

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

<!--- TODO: Add full implementation of agent details. --->
<cfquery name="getAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	SELECT 
		agent.agent_type, 
		agent.edited as vetted, 
		agent_remarks, 
		biography,
		agentguid_guid_type, agentguid,
		prefername.agent_name as preferred_agent_name
	FROM 
		agent
		left join agent_name prefername on agent.preferred_agent_name_id = prefername.agent_name_id
	WHERE
		agent.agent_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#agent_id#">
</cfquery>

<cfoutput>
	<div class="container">
		<div class="row">
			<cfloop query="getAgent">
				<cfset prefName = getAgent.preferred_agent_name>
				<div id="agentTopDiv" class="col-12 my-4">
					<div class="row">
						<div class="col-12 col-sm-10">
							<cfif getAgent.vetted EQ 1 ><cfset vetted_marker="*"><cfelse><cfset vetted_marker=""></cfif> 
							<h2>#preferred_agent_name# #vetted_marker#</h2>
						</div>
						<div class="col-12 col-sm-2">
							<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_agents")>
								<a href="/agents.cfm?agent_id=#agent_id#" class="btn btn-primary btn-xs float-right">Edit</a>
							</cfif>
						</div>
					</div>
					<ul class="mt-3 list-unstyled">
						<li>#agent_type#</li>
						<cfif len(agentguid) GT 0>
							<cfif len(ctguid_type_agent.resolver_regex) GT 0>
								<cfset guidLink = REReplace(agentguid,ctguid_type_agent.resolver_regex,ctguid_type_agent.resolver_replacement) >
							<cfelse>
								<cfset guidLink = agentguid >
							</cfif>
							<li><a href="#guidLink#">#agentguid#</a></li>
						</cfif>
					</ul>
					<div>#biography#</div>
					<cfif oneOfUs EQ 1>
						<div>#agent_remarks#</div>
					</cfif>
				</div>
				<div class="col-12 mb-2 clearfix float-left" id="agentTwoCollsWrapper">
					<div class="col-12 col-md-6 px-1 float-left" id="leftAgentColl">
					
						<!--- agent names --->
						<section class="card mb-2 bg-light">
							<div class="card-header">
								<h2 class="h3">Names for this agent</h2>
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
							<div class="card-body">
								<ul>
									<!--- preferred name --->
									<cfloop query="preferredNames">
										<li>#preferredNames.agent_name# (#preferredNames.agent_name_type#)</li>
									</cfloop>
									<cfloop query="notPrefNames">
										<cfif isdefined("session.roles") and listfindnocase(session.roles,"global_admin")>
											<li>#notPrefNames.agent_name# (#notPrefNames.agent_name_type#)</li>
										<cfelse>
											<!--- don't display login name to non-admin users --->
											<cfif notPrefNames.agent_name_type NEQ "login">
												<li>#notPrefNames.agent_name# (#notPrefNames.agent_name_type#)</li>
											</cfif>
										</cfif>
									</cfloop>
								</ul>
							</div>
						</section>

						<cfif #getAgent.agent_type# IS "group" OR #getAgent.agent_type# IS "expedition" OR #getAgent.agent_type# IS "vessel">
							<!--- group members --->
							<section class="card mb-2 bg-light">
								<div class="card-header">
									<h2 class="h3">Group Members</h2>
								</div>
								<cfquery name="groupMembers" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="groupMembers_result">
									SELECT
										member_agent_id,
										member_order,
										agent_name
									FROM
										group_member 
										left join preferred_agent_name on group_member.MEMBER_AGENT_ID = preferred_agent_name.agent_id
									WHERE
										group_agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
									ORDER BY
										member_order
								</cfquery>
								<div class="card-body">
									<cfif groupMembers.recordcount EQ 0>
										<ul><li>None</li></ul>
									<cfelse>
										<ul>
											<cfloop query="groupMembers">
												<li><a href="/agents/Agent.cfm?agent_id=#groupMembers.member_agent_id#">#groupMembers.agent_name#</a></li>
											</cfloop>
										</ul>
									</cfif>
								</div>
							</section>
						</cfif>

						<cfif oneOfUs EQ 1>
							<!--- emails/phone numbers --->
							<section class="card mb-2 bg-light">
								<div class="card-header">
									<h2 class="h3">Phone/Email</h2>
								</div>
								<cfquery name="getAgentElecAddr" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
									select address_type, address 
									from electronic_address 
									WHERE
										electronic_address.agent_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#agent_id#">
									order by address_type
								</cfquery>
								<div class="card-body">
									<cfif getAgentElecAddr.recordcount EQ 0>
										<ul><li>None</li></ul>
									<cfelse>
										<ul>
											<cfloop query="getAgentElecAddr">
												<li>#address_type#: #address#</li>
											</cfloop>
										</ul>
									</cfif>
								</div>
							</section>
						</cfif>

						<cfif oneOfUs EQ 1>
							<!--- emails/phone numbers --->
							<section class="card mb-2 bg-light">
								<div class="card-header">
									<h2 class="h3">Postal Addresses</h2>
								</div>
								<cfquery name="getAgentAddr" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
									select addr_type, 
										REPLACE(formatted_addr, CHR(10),'<br>') FORMATTED_ADDR,
										valid_addr_fg,
										addr_remarks
									from addr
									WHERE
										addr.agent_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#agent_id#">
									order by addr_type, valid_addr_fg desc
								</cfquery>
								<div class="card-body">
									<cfif getAgentAddr.recordcount EQ 0>
										<ul><li>None</li></ul>
									<cfelse>
										<cfloop query="getAgentAddr">
											<cfif len(addr_remarks) GT 0><cfset rem="[#addr_remarks#]"><cfelse><cfset rem=""></cfif>
											<cfif valid_addr_fg EQ 1>
												<cfset addressCurrency="Valid">
													<cfset listgroupclass="bg-verylightgreen">
												<cfelse>
													<cfset addressCurrency="Invalid">
												<cfset listgroupclass="">
											</cfif>
											<h3 class="h4">#addr_type# address #addressCurrency##rem#</h3>
											<div class="#listgroupclass# w-100">#formatted_addr#</div>
										</cfloop>
									</cfif>
								</div>
							</section>
						</cfif>

						<!--- relationships --->
						<section class="card mb-2 bg-light">
							<div class="card-header">
								<h2 class="h3">Relationships with other agents</h2>
							</div>
							<cfquery name="getAgentRel" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
								SELECT agent_relationship, related_agent_id, MCZBASE.get_agentnameoftype(related_agent_id) as related_name,
									agent_remarks
								FROM agent_relations 
								WHERE
									agent_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#agent_id#">
									and agent_relationship not like '% duplicate of'
								ORDER BY agent_relationship
							</cfquery>
							<div class="card-body">
								<cfif getAgentRel.recordcount EQ 0>
									<ul><li>None to other agents</li></ul>
								<cfelse>
									<ul>
										<cfloop query="getAgentRel">
											<cfif len(getAgentRel.agent_remarks) GT 0><cfset rem=" [#getAgentRel.agent_remarks#]"><cfelse><cfset rem=""></cfif>
											<li>#agent_relationship# <a href="/agents/Agent.cfm?agent_id=#related_agent_id#">#related_name#</a>#rem#</li>
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
										<ul><li>None from other agents</li></ul>
									<cfelse>
										<ul>
											<cfloop query="getRevAgentRel">
												<cfif len(getRevAgentRel.agent_remarks) GT 0><cfset rem=" [#getRevAgentRel.agent_remarks#]"><cfelse><cfset rem=""></cfif>
												<li><a href="/agents/Agent.cfm?agent_id=#related_agent_id#">#related_name#</a> #agent_relationship# #getAgent.preferred_agent_name##rem#</li>
											</cfloop>
										</ul>
									</cfif>
								</cfif>
							</div>
						</section>

						<!--- Collector --->
						<section class="card mb-2 bg-light">
							<div class="card-header">
								<h2 class="h3">Collector</h2>
							</div>
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
							<div class="card-body">
								<cfif getAgentCollScope.recordcount EQ 0>
									<h2 class="h3">Not a collector of any material in MCZbase</h2>
								<cfelse>
									<ul>
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
												<li>#getAgentCollScope.collection_cde# (<a href="/SpecimenResults.cfm?collector_agent_id=#agent_id#&collection_id=#getAgentCollScope.collection_id#" target="_blank">#getAgentCollScope.ct# record#plural#</a>) #yearbit#</li>
											</cfif>
										</cfloop>
									</ul>
									<cfif len(earlyeststart) GT 0 AND len(latestend) GT 0>
										<cfif LSParseNumber(earlyeststart) +80 LT LSParseNumber(latestend)>
											<h3 class="h3">Range of years collected is greater that 80 (#earlyeststart#-#latestend#). </h3>
										</cfif>
									</cfif>

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
										order by ct desc
									</cfquery>
									<cfif getAgentFamilyScope.recordcount GT 0>
										<div class="w-100"> 
											<h3 class="h3">Families Collected</h3>
											<ul>
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
														<li>#getAgentFamilyScope.phylclass#: #getAgentFamilyScope.family# (<a href="/SpecimenResults.cfm?collector_agent_id=#agent_id#&family=#getAgentFamilyScope.family#" target="_blank">#getAgentFamilyScope.ct# record#plural#</a>) #yearbit#</li>
													</cfif>
												</cfloop>
											</ul>
										</div>
									</cfif><!--- getAgentFamilyScope.recordcount > 0 --->
								</cfif><!--- getAgentCollScope.recordcount > 1 --->
							</div>
						</section>

						
						<cfif oneOfUs EQ 1>
							<!--- records entered --->
							<section class="card mb-2 bg-light">
								<div class="card-header">
									<h2 class="h3">MCZbase Records Entered</h2>
								</div>
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
								<div class="card-body">
									<cfif entered.recordcount EQ 0>
										<ul><li>None</li></ul>
									<cfelse>
										<ul>
											<cfloop query="entered">
												<li>
													<a href="/SpecimenResults.cfm?entered_by_id=#agent_id#&collection_id=#collection_id#" target="_blank">#cnt# #collection#</a> specimens
												</li>
											</cfloop>
										</ul>
									</cfif>
								</div>
							</section>
						</cfif>

						<cfif oneOfUs EQ 1>
							<!--- records last edited by --->
							<section class="card mb-2 bg-light">
								<div class="card-header">
									<h2 class="h3">MCZbase Records Last Edited By this agent</h2>
								</div>
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
								<div class="card-body">
									<cfif lastEdit.recordcount EQ 0>
										<ul><li>None</li></ul>
									<cfelse>
										<ul>
											<cfloop query="lastEdit">
												<li>
													<a href="/SpecimenResults.cfm?edited_by_id=#agent_id#&collection_id=#collection_id#">#cnt# #collection#</a> specimens
												</li>
											</cfloop>
										</ul>
									</cfif>
								</div>
							</section>
						</cfif>

						<!--- attribute determinations --->
						<section class="card mb-2 bg-light">
							<div class="card-header">
								<h2 class="h3">Attribute Determiner</h2>
							</div>
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
							<div class="card-body">
								<cfif attributes.recordcount EQ 0>
									<ul><li>None</li></ul>
								<cfelse>
									<ul>
										<cfloop query="attributes">
											<li>
												#attributes.attribute_type# for #attributes.colObjCount#
												<a href="/SpecimenResults.cfm?attributed_determiner_agent_id=#agent_id#&collection_id=#attributes.collection_id#">
													#attributes.collection#</a> specimens
											</li>
										</cfloop>
									</ul>
								</cfif>
							</div>
						</section>

						<cfif oneOfUs EQ 1>
							<!--- media relationships and labels --->
							<section class="card mb-2 bg-light">
								<div class="card-header">
									<h2 class="h3">Media Records Edited</h2>
								</div>
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
								<div class="card-body">
									<ul>
										<cfif getMediaCreation.ct EQ 0>
											<li>Created No Media Relationships.</li>
										<cfelse>
											<li>
												Created #getMediaCreation.ct# 
												<a href="/media/findMedia.cfm?execute=true&created_by_agent_name=#encodeForURI(prefName)#&created_by_agent_id=#agent_id#">Media Records</a>
											</li>
										</cfif>
										<cfif media_assd_relations.ct EQ 0>
											<li>Created No Media Relationships.</li>
										<cfelse>
											<li>Created #media_assd_relations.ct# Media Relationships.</li>
										</cfif>
										<cfif media_labels.recordcount EQ 0>
											<li>Assigned no media label values.</li>
										<cfelse>
											<cfloop query="media_labels">
												<li>#media_labels.media_label# (#media_labels.ct#)</li>
											</cfloop>
										</cfif>
									</ul>
								</div>
							</section>
						</cfif>

						<cfif oneOfUs EQ 1>
							<!--- records last edited by --->
							<section class="card mb-2 bg-light">
								<cfquery name="getEncumbCount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getEncumbCount_result">
									SELECT count(*) as ct,
									FROM encumbrance 
									WHERE encumbering_agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
								</cfquery>
								<div class="card-header">
									<cfif getEncumbCount.ct GT 0>
										<cfset encumbCount = "(#getEncumbCount.ct#)">
									<cfelse>
										<cfset encumbCount = "">
									</cfif>
									<h2 class="h3">Encumbrances #encumbCount#</h2>
								</div>
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
										encumbering_agent_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
									GROUP BY
										collection,
										collection.collection_id
								</cfquery>
								<div class="card-body">
									<ul>
										<cfif getEncumbCount.ct EQ 0>
											<li>Owns No Encumbrances</li>
										<cfelse>
											<cfloop query="getEncumb">
												<li>#getEncumb.ENCUMBRANCE# (#getEncumb.ct#)</li>
											</cfloop>
										</cfif>
										<cfloop query="coll_object_encumbrance">
											<li>
												Encumbered 
												<a href="/SpecimenResults.cfm?encumbering_agent_id=#agent_id#&collection_id=#collection_id#">
												#specs# #collection#</a> records
											</li>
										</cfloop>
									</ul>
								</div>
							</section>
						</cfif>

					</div>
					<!--- split between left and right agent columns --->
					<div class="col-12 col-md-6 px-1 float-left" id="rightAgentColl">

						<!--- Media --->
						<section class="card mb-2 bg-light">
							<cfquery name="getMedia" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getMedia_result">
								SELECT media.media_id,
									mczbase.get_media_descriptor(media.media_id) as descriptor,
									media.media_uri,
									media.media_type
								FROM media_relations 
									left join media on media_relations.related_primary_key = media.media_id
								WHERE media_relationship like '% agent'
									and related_primary_key=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
									and mczbase.is_media_encumbered(media.media_id) < 1
							</cfquery>
							<cfif getMedia.recordcount eq 0>
								<cfset mediaLink = "">
							<cfelse>
								<cfset mediaLink = "<a href='/MediaSearch.cfm?action=search&related_primary_key__1=#agent_id#&relationship__1=agent'>#getMedia.recordcount#</a>">
							</cfif>
							<div class="card-header">
								<h2 class="h3">Subject of Media #mediaLink# records.</h2>
							</div>
							<div class="card-body">
								<cfif getMedia.recordcount EQ 0>
									<ul><li>None</li></ul>
								<cfelse>
									<ul class="list-group">
										<cfloop query="getMedia">
											<cfif getMedia.media_type EQ "image">
												<li class="border list-group-item d-flex justify-content-between align-items-center">
													<img src="#getMedia.media_uri#" alt="#getMedia.descriptor#" style="max-width:300px;max-height:300px;">
													<span>#getMedia.descriptor#</span>
													<span>&nbsp;</span>
												</li>
											</cfif>
										</cfloop>
									<ul>
								</cfif>
							</div>
						</section>

						<!--- Preparator--->
						<section class="card mb-2 bg-light">
							<div class="card-header">
								<h2 class="h3">Preparator</h2>
							</div>
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
							<div class="card-body">
								<cfif getAgentPrepScope.recordcount EQ 0>
									<h2 class="h3">Not a preparator of any material in MCZbase</h2>
								<cfelse>
									<ul>
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
												<li>#getAgentPrepScope.collection_cde# (<a href="/SpecimenResults.cfm?coll_role=p&coll=#encodeForURL(getAgent.preferred_agent_name)#&collection_id=#getAgentPrepScope.collection_id#" target="_blank">#getAgentPrepScope.ct# record#plural#</a>) #yearbit#</li>
											</cfif>
										</cfloop>
									</ul>
									<cfif len(earlyeststart) GT 0 AND len(latestend) GT 0>
										<cfif LSParseNumber(earlyeststart) +80 LT LSParseNumber(latestend)>
											<h3 class="h3">Range of years collected is greater that 80 (#earlyeststart#-#latestend#). </h3>
										</cfif>
									</cfif>
								</cfif>
							</div>
						</section>

						<cfif oneOfUs EQ 1>
							<!--- Project sponsor and other project roles --->
							<section class="card mb-2 bg-light">
								<div class="card-header">
									<h2 class="h3">Project Roles</h2>
								</div>
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
								<div class="card-body">
									<cfif getProjRoles.recordcount EQ 0>
										<h2 class="h3">No project roles in MCZbase</h2>
									<cfelse>
										<ul>
											<cfloop query="getProjRoles">
												<li>#getProjRoles.role# for <a href="/ProjectDetail.cfm?project_id=#project_id#">#project_name#</a></li>
											</cfloop>
										</ul>
									</cfif>
								</div>
							</section>
						</cfif>

						<!--- Author --->
						<section class="card mb-2 bg-light">
							<div class="card-header">
								<h2 class="h3">Publications Citing MCZ material</h2>
							</div>
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
							<div class="card-body">
								<cfif publicationAuthor.recordcount EQ 0>
									<h3 class="h3">No Publication Citing MCZ material</h3>
								<cfelse>
									<ul class="list-group">
										<cfloop query="publicationAuthor">
											<li class="border list-group-item d-flex justify-content-between align-items-center">
												<a href="/SpecimenUsage.cfm?action=search&publication_id=#publication_id#">#formatted_publication#</a>
												<span class="badge badge-primary badge-pill">#citation_count# citations</span>
												<span>&nbsp;</span><!--- custom_styles.css sets display: none on last item in a li in a card. --->
											</li>
										</cfloop>
									</ul>
								</cfif>
							</div>
						</section>

						<!--- transactions roles --->
						<cfif listcontainsnocase(session.roles, "manage_transactions")>
							<section class="card mb-2 bg-light">
								<cfquery name="getTransCount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getTransactions_result">
									SELECT count(distinct transaction_view.transaction_id) ct
									FROM trans_agent
										left outer join transaction_view on trans_agent.transaction_id = transaction_view.transaction_id
									WHERE
										trans_agent.agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
								</cfquery>
								<div class="card-header">
									<cfif getTransCount.ct EQ 0>
										<h2 class="h3">Roles in Transactions:</h2>
									<cfelse>
										<h2 class="h3">
											Roles in 
											<a href="/Transactions.cfm?action=findAll&execute=true&collection_id=-1&agent_1=#encodeForURL(prefName)#&agent_1_id=#agent_id#" >
											#getTransCount.ct# Transactions
											</a>:
										</h2>
									</cfif>
								</div>
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
								<div class="card-body">
									<cfif getTransactions.recordcount EQ 0>
										<h2 class="h3">Not a Transaction Agent in MCZbase</h2>
									<cfelse>
										<ul>
											<cfset lastTrans ="">
											<cfset statusDate ="">
											<cfloop query="getTransactions">
												<cfif lastTrans NEQ getTransactions.specific_number>
													<cfif lastTrans NEQ "">
														#statusDate#</li>
													</cfif>
													<li>
														<span class="text-capitalize">#transaction_type#</span> 
														<a href="/Transactions.cfm?number=#specific_number#&action=findAll&execute=true">#specific_number#</a>
														#trans_agent_role#
														<cfset statusDate = "(#getTransactions.status# #trans_date#)">
												<cfelse>
														, #trans_agent_role#
												</cfif>
												<cfset lastTrans ="#getTransactions.specific_number#">
											</cfloop>
										</ul>
									</cfif>
								</div>
							</section>
						</cfif>

						<!--- foreign key relationships to other tables --->
						<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_agents")>
							<section class="card mb-2 bg-light">
								<div class="card-header">
									<h2 class="h3">This Agent record is linked to:</h2>
								</div>
								<cfquery name="getFKFields" datasource="uam_god">
									SELECT all_constraints.table_name, column_name, delete_rule 
									FROM all_constraints
										left join all_cons_columns on all_constraints.constraint_name = all_cons_columns.constraint_name and all_constraints.owner = all_cons_columns.owner
									WHERE r_constraint_name in (select constraint_name from all_constraints where table_name='AGENT')
									ORDER BY all_constraints.table_name
								</cfquery>
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
								<div class="card-body">
									<cfif okToDelete>
										<h3 class="h4">This Agent is not used and is eligible for deletion</h3>
									<cfelse>
										<h3 class="h4">This Agent record is linked to these other MCZbase tables</h3>
									</cfif>
									<ul>
										<cfloop collection="#relatedTo#" item="key">
											<li>#key# (#relatedTo[key]#)</li>
										</cfloop>
									</ul>
								</div>
							</section>
						</cfif>

					</div><!--- end of right column --->

				</div><!--- end of agentTwoCollsWrapper --->
			</cfloop><!--- getAgent --->
		</div>
	</div>
</cfoutput>

<cfinclude template = "/shared/_footer.cfm">
