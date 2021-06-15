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

<!--- TODO: Add full implementation of agent details. --->
<cfquery name="getAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	SELECT 
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
		MCZBASE.get_collectorscope(agent.agent_id,'collections') as collections_scope
	FROM 
		agent
		left join agent_name prefername on agent.preferred_agent_name_id = prefername.agent_name_id
		left join person on agent.agent_id = person.person_id
	WHERE
		agent.agent_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#agent_id#">
</cfquery>

<cfoutput>
	<div class="container-fluid">
		<div class="row">
			<cfloop query="getAgent">
				<cfset prefName = getAgent.preferred_agent_name>
				<div id="agentTopDiv" class="col-12 mt-3">
					<div class="row mx-0 px-0 px-md-4">
						<div class="col-12 col-sm-12 col-xl-6 float-left">
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
							<h2>#preferred_agent_name# #vetted_marker# #dates#</h2>
						</div>
						<cfif oneOfUs EQ 1>
							<div class="col-12 col-sm-12 col-xl-6 float-left">
								<a href="/agents/editAgent.cfm?agent_id=#agent_id#" class="btn btn-primary btn-xs float-right">Edit</a>
							</div>
						</cfif>
					</div>
					<div class="row mx-0 px-0 px-md-4">
						<div class="col-12">
							<ul class="list-group mb-2 py-0 list-unstyled">
								<li class="list-group-item">#agent_type# </li>
								<cfif len(agentguid) GT 0>
									<cfif len(ctguid_type_agent.resolver_regex) GT 0>
										<cfset guidLink = REReplace(agentguid,ctguid_type_agent.resolver_regex,ctguid_type_agent.resolver_replacement) >
									<cfelse>
										<cfset guidLink = agentguid >
									</cfif>
									<li class="list-group-item"><a href="#guidLink#">#agentguid#</a></li>
								</cfif>
							</ul>
						<div>#biography#</div>
						<cfif oneOfUs EQ 1>
							<div>#agent_remarks#</div>
						</cfif>
						</div>
					</div>
				<div class="col-12 form-row mt-2" id="agentTwoCollsWrapper">
					<div class="col-12 col-md-4 float-left" id="leftAgentColl">
						<section class="accordion" id="accordionB">
							<div class="card mb-2 bg-light">
							<div class="card-header" id="heading1">

								<h3 class="h4 my-0 float-left collapsed btn-link">
									<a href="##" role="button" data-toggle="collapse" data-target="##namesPane">Names for this Agent</a>
								</h3>

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
							<div id="namesPane" class="collapse show" aria-labelledby="heading1" data-parent="##accordionB">
								<div class="card-body py-1 mb-1 float-left" id="namesCardBody">
									<ul class="list-group">
										<!--- preferred name --->
										<cfloop query="preferredNames">
											<li class="list-group-item">#preferredNames.agent_name# (#preferredNames.agent_name_type#)</li>
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
						<section class="accordion" id="accordionB">
							<div class="card mb-2 bg-light">
							<div class="card-header" id="heading1">
								 <!--- group members --->
								<h3 class="h4 my-0 float-left collapsed btn-link">
								Group Members
								</h3>
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
							<div class="card-body py-1 mb-1 float-left">
								<cfif groupMembers.recordcount EQ 0>
									<ul class="list-group"><li class="list-group-item">None</li></ul>
								<cfelse>
									<ul class="list-group">
										<cfloop query="groupMembers">
											<li class="list-group-item"><a href="/agents/Agent.cfm?agent_id=#groupMembers.member_agent_id#">#groupMembers.agent_name#</a></li>
										</cfloop>
									</ul>
								</cfif>
							</div>
						</section>
					</cfif>

						<cfif oneOfUs EQ 1>
							<!--- emails/phone numbers --->
							<section  class="accordion" id="accordionC">
								<div class="card mb-2 bg-light">
									<div class="card-header" id="heading3">
										<!--- Phone/Email --->
										<h3 class="h4 my-0 float-left collapsed btn-link">
											<a href="##" role="button" data-toggle="collapse" data-target="##electronicPane">Phone/Email</a>
										</h3>
									</div>
									<cfquery name="getAgentElecAddr" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
										select address_type, address 
										from electronic_address 
										WHERE
											electronic_address.agent_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#agent_id#">
										order by address_type
									</cfquery>
									<div id="electronicPane" class="collapse show" aria-labelledby="heading3" data-parent="##accordionC">
										<div class="card-body py-1 mb-1 float-left" id="electronicCardBody">
											<cfif getAgentElecAddr.recordcount EQ 0>
												<ul class="list-group"><li class="list-group-item">None</li></ul>
											<cfelse>
												<ul class="list-group">
													<cfloop query="getAgentElecAddr">
														<li class="list-group-item">#address_type#: #address#</li>
													</cfloop>
												</ul>
											</cfif>
										</div>
									</div>
								</div>
							</section>
						</cfif>

						<cfif oneOfUs EQ 1>
							<!--- emails/phone numbers --->
								<section  class="accordion" id="accordionD">
								<div class="card mb-2 bg-light">
									<div class="card-header" id="heading4">
										<!--- Phone/Email --->
										<h3 class="h4 my-0 float-left collapsed btn-link">
											<a href="##" role="button" data-toggle="collapse" data-target="##postalPane">Postal Addresses</a>
										</h3>
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
								<div id="postalPane" class="collapse show" aria-labelledby="heading3" data-parent="##accordionD">
									<div class="card-body pt-1 pb-2 pl-3 mb-1 float-left" id="postalCardBody">
										<cfif getAgentAddr.recordcount EQ 0>
											<ul class="list-group"><li class="list-group-item">None</li></ul>
										<cfelse>
											<cfloop query="getAgentAddr">
												<cfif len(addr_remarks) GT 0><cfset rem="[#addr_remarks#]"><cfelse><cfset rem=""></cfif>
												<cfif valid_addr_fg EQ 1>
													<cfset addressCurrency="Valid">
														<cfset listgroupclass="bg-verylightgreen rounded p-2 border-green w-100">
													<cfelse>
														<cfset addressCurrency="Invalid">
													<cfset listgroupclass="w-100 p-2 rounded border border-light">
												</cfif>
												<h3 class="h4 mt-2">#addr_type# address &ndash;&nbsp;#addressCurrency# &nbsp;#rem#</h3>
												<div class="#listgroupclass# w-100">#formatted_addr#</div>
											</cfloop>
										</cfif>
									</div>
								</div>
							</section>
						</cfif>

						<!--- relationships --->
						<section  class="accordion" id="accordionE">
								<div class="card mb-2 bg-light">
									<div class="card-header" id="heading4">
										<!--- Phone/Email --->
										<h3 class="h4 my-0 float-left collapsed btn-link">
											<a href="##" role="button" data-toggle="collapse" data-target="##relationsPane">Relationships with Other Agents</a>
										</h3>
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
								<div id="relationsPane" class="collapse show" aria-labelledby="heading4" data-parent="##accordionE">
									<div class="card-body py-1 mb-1 float-left" id="relationsCardBody">
										<cfif getAgentRel.recordcount EQ 0>
											<ul class="list-group"><li class="list-group-item">None to other agents</li></ul>
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
												<ul class="list-group"><li class="list-group-item">None from other agents</li></ul>
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
								</div>
						</section>
					</div>
					<div class="col-12 col-md-4 float-left">
						<!--- Collector --->
						<section  class="accordion" id="accordionF">
								<div class="card mb-2 bg-light">
									<div class="card-header" id="heading5">
										<!--- Phone/Email --->
										<h3 class="h4 my-0 float-left collapsed btn-link">
											<a href="##" role="button" data-toggle="collapse" data-target="##collectorsPane">Collectors</a>
										</h3>
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
							<div id="collectorsPane" class="collapse show" aria-labelledby="heading5" data-parent="##accordionF">
								<div class="card-body py-1 mb-1 float-left" id="collectorsCardBody">
								<h4 class="card-title mt-2 mb-0">#getAgent.collections_scope#</h3>
								<cfif getAgentCollScope.recordcount EQ 0>
									<h4 class="card-title mt-2 mb-0">Not a collector of any material in MCZbase</h2>
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
											<h4 class="card-title mt-2 mb-0">Range of years collected is greater that 80 (#earlyeststart#-#latestend#). </h4>
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
											<h4 class="card-title mt-2 mb-0">Families Collected</h4>
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
									</cfif><!--- getAgentFamilyScope.recordcount > 0 --->
								</cfif><!--- getAgentCollScope.recordcount > 1 --->
								</div>
							</div>
						</section>
						<!--- Determiner --->
						<section  class="accordion" id="accordionG">
						<div class="card mb-2 bg-light">
							<div class="card-header" id="heading6">
								<!--- Phone/Email --->
								<h3 class="h4 my-0 float-left collapsed btn-link">
									<a href="##" role="button" data-toggle="collapse" data-target="##determinersPane">Determiner</a>
								</h3>
							</div>
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
							<div id="determinersPane" class="collapse show" aria-labelledby="heading6" data-parent="##accordionG">
								<div class="card-body py-1 mb-1 float-left" id="determinersCardBody">
								<cfif identification.recordcount EQ 0>
									<ul class="list-group"><li class="list-group-item">None</li></ul>
								<cfelse>
									<ul class="list-group">
										<cfloop query="identification">
											<li class="list-group-item">
												#cnt# identification(s) for <a href="/SpecimenResults.cfm?identified_agent_id=#agent_id#&collection_id=#collection_id#">
												#specs# #collection#</a> cataloged items
											</li>
										</cfloop>
									</ul>
								</cfif>
								</div>
							</div>
						</section>
						<!--- Author --->
						<section  class="accordion" id="accordionN">
							<div class="card mb-2 bg-light">
								<div class="card-header" id="headingPub">
									<!--- publication --->
									<h3 class="h4 my-0 float-left collapsed btn-link">
										<a href="##" role="button" data-toggle="collapse" data-target="##pubPane">Publication Citing MCZ Material</a>
									</h3>
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
								<div id="pubPane" class="collapse show" aria-labelledby="headingPub" data-parent="##accordionN">
									<div class="card-body py-1 mb-1 float-left" id="pubCardBody">
									<cfif publicationAuthor.recordcount EQ 0>
										<ul class="list-group"><li class="list-group-item">No Publication Citing MCZ material</li></ul>
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
								</div>
							</div>
						</section>
							<!--- Projects --->
						<cfif oneOfUs EQ 1>
							<!--- Project sponsor and other project roles --->
							<section  class="accordion" id="accordionL">
							<div class="card mb-2 bg-light">
								<div class="card-header" id="heading11">
									<!--- Phone/Email --->
									<h3 class="h4 my-0 float-left collapsed btn-link">
										<a href="##" role="button" data-toggle="collapse" data-target="##projPane">Projects</a>
									</h3>
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
								<div id="projPane" class="collapse show" aria-labelledby="heading11" data-parent="##accordionL">
									<div class="card-body py-1 mb-1 float-left" id="projCardBody">
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
							</div>
							</section>
						</cfif>
						<cfif oneOfUs EQ 1>
							<!--- records entered --->
						<section  class="accordion" id="accordionI">
							<div class="card mb-2 bg-light">
								<div class="card-header" id="heading8">
									<!--- Phone/Email --->
									<h3 class="h4 my-0 float-left collapsed btn-link">
										<a href="##" role="button" data-toggle="collapse" data-target="##enteredPane">MCZbase Records Entered</a>
									</h3>
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
								<div id="enteredPane" class="collapse show" aria-labelledby="heading8" data-parent="##accordionI">
									<div class="card-body py-1 mb-1 float-left" id="enteredCardBody">
										<cfif entered.recordcount EQ 0>
											<ul class="list-group"><li class="list-group-item">None</li></ul>
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
								</div>
							</section>
						</cfif>
								
						<cfif oneOfUs EQ 1>
							<!--- Georeferences --->
						<section  class="accordion" id="accordionR">
							<div class="card mb-2 bg-light">
								<div class="card-header" id="headingGeo">
									<!--- Phone/Email --->
									<h3 class="h4 my-0 float-left collapsed btn-link">
										<a href="##" role="button" data-toggle="collapse" data-target="##geoPane">Georeferences</a>
									</h3>
								</div>
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
								<div id="geoPane" class="collapse show" aria-labelledby="headingGeo" data-parent="##accordionR">
									<div class="card-body py-1 mb-1 float-left" id="geoCardBody">
										<cfif getLatLongDet.recordcount EQ 0>
											<ul class="list-group"><li class="list-group-item">Determiner for No Coordinates</li></ul>
										<cfelse>
											<ul class="list-group">
												<li class="list-group-item">Determined #getLatLongDet.cnt# coordinates for #getLatLongDet.locs# localities</li>
											</ul>
										</cfif>
										<cfif getLatLongVer.recordcount EQ 0>
											<ul class="list-group"><li class="list-group-item">Verified No Coordinates</li></ul>
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
						<!--- Preparator--->
						<section  class="accordion" id="accordionK">
							<div class="card mb-2 bg-light">
								<div class="card-header" id="heading10">
									<!--- Phone/Email --->
									<h3 class="h4 my-0 float-left collapsed btn-link">
										<a href="##" role="button" data-toggle="collapse" data-target="##prepPane">Preparator</a>
									</h3>
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
								<div id="prepPane" class="collapse show" aria-labelledby="heading10" data-parent="##accordionK">
									<div class="card-body py-1 mb-1 float-left" id="prepCardBody">
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
												<h3 class="h3">Range of years collected is greater that 80 (#earlyeststart#-#latestend#). </h3>
											</cfif>
										</cfif>
									</cfif>
								</div>
								</div>
							</div>
						</section>
						<cfif oneOfUs EQ 1>
							<!--- records last edited by --->
							<section  class="accordion" id="accordionH">
								<div class="card mb-2 bg-light">
									<div class="card-header" id="heading7">
										<!--- Phone/Email --->
										<h3 class="h4 my-0 float-left collapsed btn-link">
											<a href="##" role="button" data-toggle="collapse" data-target="##recordsPane">MCZbase Records Last Edited By This Agent</a>
										</h3>
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
										<div id="recordsPane" class="collapse show" aria-labelledby="heading7" data-parent="##accordionH">
											<div class="card-body py-1 mb-1 float-left" id="recordsCardBody">
												<cfif lastEdit.recordcount EQ 0>
													<ul class="list-group"><li class="list-group-item">None</li></ul>
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
										</div>
								</div>
							</section>
						</cfif>
						<section  class="accordion" id="accordionJ">
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
							<div class="card mb-2 bg-light">
								<div class="card-header" id="heading9">
									<!--- Phone/Email --->
									<h3 class="h4 my-0 float-left collapsed btn-link">
										<a href="##" role="button" data-toggle="collapse" data-target="##media_subjectPane">Media Record Subject</a>
									</h3>
								</div>
							<cfif getMedia.recordcount eq 0>
								<cfset mediaLink = "No Media records">
							<cfelse>
								<cfset mediaLink = "<a href='/MediaSearch.cfm?action=search&related_primary_key__1=#agent_id#&relationship__1=agent' target='_blank'>#getMedia.recordcount# Media Record#plural#</a>">
							</cfif>
								<div id="media_subjectPane" class="collapse show" aria-labelledby="heading9" data-parent="##accordionJ">
									<div class="card-body py-1 mb-1 float-left" id="media_subjectCardBody">
								<cfif getMedia.recordcount EQ 0>
									<ul class="list-group"><li class="list-group-item">#prefName# is the subject of #mediaLink#</li></ul>
								<cfelse>
									<ul class="list-group">
										<cfloop query="getMedia">
											<cfif getMedia.media_type IS "image">
												<li class="border list-group-item d-flex justify-content-between align-items-center">
													<a href="/media/#getMedia.media_id#"><img src="#getMedia.media_uri#" alt="#getMedia.descriptor#" style="max-width:300px;max-height:300px;"></a>
													<span>#getMedia.descriptor#</span>
													<span>#getMedia.subject#</span>
													<span><a href="#getMedia.license_uri#">#getMedia.license_display#</a></span>
													<span>#getMedia.credit#</span>
													<span>&nbsp;</span>
												</li>
											</cfif>
										</cfloop>
									</ul>
								</cfif>
							</div>
						</section>
						<cfif oneOfUs EQ 1>
							<!--- media relationships and labels --->
							<section  class="accordion" id="accordionQ">
								<div class="card mb-2 bg-light">
								<div class="card-header" id="headingMedrec">
								<!--- Phone/Email --->
								<h3 class="h4 my-0 float-left collapsed btn-link">
									<a href="##" role="button" data-toggle="collapse" data-target="##mediarecPane">Media Records Edited</a>
								</h3>
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
								<div id="mediarecPane" class="collapse show" aria-labelledby="headingMedrec" data-parent="##accordionQ">
									<div class="card-body py-1 mb-1 float-left" id="mediarecCardBody">
									<ul class="list-group">
										<cfif getMediaCreation.ct EQ 0>
											<li class="list-group-item">Created No Media Records.</li>
										<cfelse>
											<li>
												Created #getMediaCreation.ct# 
												<a href="/media/findMedia.cfm?execute=true&created_by_agent_name=#encodeForURL(prefName)#&created_by_agent_id=#agent_id#">Media Records</a>
											</li>
										</cfif>
										<cfif media_assd_relations.ct EQ 0>
											<li class="list-group-item">Created No Media Relationships.</li>
										<cfelse>
											<li class="list-group-item">Created #media_assd_relations.ct# Media Relationships.</li>
										</cfif>
										<cfif media_labels.recordcount EQ 0>
											<li class="list-group-item">Assigned no media label values.</li>
										<cfelse>
											<cfloop query="media_labels">
												<li class="list-group-item">#media_labels.media_label# (#media_labels.ct#)</li>
											</cfloop>
										</cfif>
									</ul>
								</div>
								</div>
								</div>
							</section>
						</cfif>
					</div>
					<div class="col-12 col-md-4 float-left">
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
									<ul class="list-group"><li class="list-group-item">None</li></ul>
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
						</section>





						<cfif oneOfUs EQ 1>
							<!--- records last edited by --->
							<section  class="accordion" id="accordionP">
							<cfquery name="getEncumbCount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getEncumbCount_result">
									SELECT count(*) as ct
									FROM encumbrance 
									WHERE encumbering_agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
								</cfquery>
							<cfif getEncumbCount.ct GT 0>
								<cfset encumbCount = "(#getEncumbCount.ct#)">
							<cfelse>
								<cfset encumbCount = "">
							</cfif>
							<div class="card mb-2 bg-light">
								<div class="card-header" id="headingEnc">
									<!---  --->
									<h3 class="h4 my-0 float-left collapsed btn-link">
										<a href="##" role="button" data-toggle="collapse" data-target="##encumbrancePane">Encumbrances #encumbCount#</a>
									</h3>
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
								<div id="encumbrancePane" class="collapse show" aria-labelledby="headingEnc" data-parent="##accordionP">
									<div class="card-body py-1 mb-1 float-left" id="encumbranceCardBody">
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
								</div>
							</div>
							</section>
						</cfif>

						<!--- loan item reconciliation --->
						<cfif listcontainsnocase(session.roles, "manage_transactions")>
							<section class="card mb-2 bg-light">
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
								<cfif loan_item.recordcount GT 10>
									<!--- cardState = collapsed --->
									<cfset headerClass = "btn-link-collapsed">
									<cfset bodyClass = "collapse">
									<cfset ariaExpanded ="false">
								<cfelse>
									<!--- cardState = expanded --->
									<cfset headerClass = "btn-link">
									<cfset bodyClass = "collapse show">
									<cfset ariaExpanded ="true">
								</cfif>
								<div class="card-header" id="loanItemHeader">
									<h2 class="h3">
										<button class="btn #headerClass#" data-toggle="collapse" data-target="##loanItemCardBody" aria-expanded="#ariaExpanded#" aria-controls="loanItemCardBody">
											Reconciled loan items (#loan_item.recordcount#):
										</button>
									</h2>
								</div>
								<div>
								<div id="loanItemCardBody" class="#bodyClass#" aria-labelledby="loanItemHeader" data-parent="##leftAgentColl">
									<cfif loan_item.recordcount GT 0>
										<h3 class="h5 mb-0 card-title">#prefName# reconciled #loan_item.recordcount# loan item#plural#</h3>
									</cfif>
									<div class="card-body">
										<ul class="list-group">
											<cfif loan_item.recordcount EQ 0>
												<li class="list-group-item">None.</li>
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
							</section>
						</cfif>

						<!--- shipments --->
						<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_transactions")>
						
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
								<cfif totalShipCount GT 10>
									<cfset cardState = "collapsed">
									<cfset headerClass = "btn-link-collapsed">
									<cfset bodyClass = "collapse">
									<cfset ariaExpanded ="false">
								<cfelse>
									<cfset cardState = "expanded">
									<cfset headerClass = "btn-link">
									<cfset bodyClass = "collapse show">
									<cfset ariaExpanded ="true">
								</cfif>
									
						<section  class="accordion" id="accordionO">
							<div class="card mb-2 bg-light">
								<div class="card-header" id="heading15">
									<!---  --->
									<h3 class="h4 my-0 float-left collapsed btn-link">
										<a href="##" role="button" data-toggle="collapse" data-target="##shipPane">Roles in Shipment#plural# (#totalShipCount#)</a>
									</h3>
								</div>
								<div id="shipPane" class="collapse show" aria-labelledby="heading15" data-parent="##accordionO">
									<div class="card-body py-1 mb-1 float-left" id="shipCardBody">
										<cfif totalShipCount GT 0>
											<h3 class="h5 card-title mb-0">#prefName# has some role in #totalShipCount# shipment#plural#</h3>
										</cfif>
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
							</div>
						</section>
						</cfif>
										
												<!--- foreign key relationships to other tables --->
						<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_agents")>
							<cftry>
							<section  class="accordion" id="accordionS">
							<cfquery name="getFKFields" datasource="uam_god">
								SELECT dba_constraints.table_name, column_name, delete_rule 
								FROM dba_constraints
									left join dba_cons_columns on dba_constraints.constraint_name = dba_cons_columns.constraint_name and dba_constraints.owner = dba_cons_columns.owner
								WHERE r_constraint_name in (select constraint_name from dba_constraints where table_name='AGENT')
								ORDER BY dba_constraints.table_name
							</cfquery>
							<div class="card mb-2 bg-light">
								<div class="card-header" id="heading16">
									<!---  --->
									<h3 class="h4 my-0 float-left collapsed btn-link">
										<a href="##" role="button" data-toggle="collapse" data-target="##linedtoPane">This agent record is linked to:</a>
									</h3>
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
								<div id="linkedtoPane" class="collapse show" aria-labelledby="heading16" data-parent="##accordionS">
									<div class="card-body py-1 mb-1 float-left" id="linkedtoCardBody">
										<cfif okToDelete>
											<h3 class="h4">This Agent is not used and is eligible for deletion</h3>
										<cfelse>
											<h3 class="h4">This Agent record is linked to these other MCZbase tables</h3>
										</cfif>
										<ul class="list-group">
											<cfloop collection="#relatedTo#" item="key">
												<li class="list-group-item">#key# (#relatedTo[key]#)</li>
											</cfloop>
										</ul>
									</div>
								</div>
							</div>
								<cfcatch>
									<!--- some issue with user access to metadata tables --->
								</cfcatch>
								</cftry>
							</section>
						</cfif>
					</div>
					
									
									
									
									
									
					<!--- split between left and right agent columns ****************************************************************** --->
					<div class="col-12 float-left" id="rightAgentColl">
					



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
								<cfset totalTransCount = getTransCount.ct>
								<cfif totalTransCount EQ 1><cfset plural=""><cfelse><cfset plural="s"></cfif>
								<cfif totalTransCount GT 10>
									<!--- cardState = collapsed --->
									<cfset headerClass = "btn-link-collapsed">
									<cfset bodyClass = "collapse">
									<cfset ariaExpanded ="false">
								<cfelse>
									<!--- cardState = expanded--->
									<cfset headerClass = "btn-link">
									<cfset bodyClass = "collapse show">
									<cfset ariaExpanded ="true">
								</cfif>
								<div class="card-header" id="transactionsHeader">
									<h2 class="h3">
										<button class="btn #headerClass#" data-toggle="collapse" data-target="##transactionsCardBody" aria-expanded="#ariaExpanded#" aria-controls="transactionsCardBody">
											Roles in Transaction#plural# (#totalTransCount#)
										</button>
									</h2>
								</div>
								<div id="transactionsCardBody" class="#bodyClass#" aria-labelledby="transactionsHeader" data-parent="##rightAgentColl">
									<cfif getTransCount.ct EQ 0>
										<h3 class="h5 mb-0 card-title">#prefName# has some role in #totalTransCount# transaction#plural#.</h3>
									<cfelse>
										<h3 class="h5 mb-0 card-title">
											#prefName# has some role in 
											<a href="/Transactions.cfm?action=findAll&execute=true&collection_id=-1&agent_1=#encodeForURL(prefName)#&agent_1_id=#agent_id#" >
											#getTransCount.ct# Transaction#plural#
											</a>:
										</h3>
									</cfif>
									<div class="card-body">
										<cfif getTransactions.recordcount EQ 0>
											<p>Not a Transaction Agent in MCZbase</p>
										<cfelse>
											<ul class="list-group">
												<cfset lastTrans ="">
												<cfset statusDate ="">
												<cfloop query="getTransactions">
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
												</cfloop>
											</ul>
										</cfif>
									</div>
								</div>
							</section>
						</cfif>


						<!--- permissions and rights roles --->
						<cfif listcontainsnocase(session.roles, "manage_transactions")>
							<section class="card mb-2 bg-light">
								<cfquery name="getPermitsTo" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getPermitsTo_result">
									SELECT
										permit_num,
										permit_title,
										permit_type,
										specific_type
									FROM
										permit 
									WHERE 
										ISSUED_TO_AGENT_ID=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
								</cfquery>
								<cfquery name="getPermitsFrom" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getPermitsFrom_result">
									SELECT
										permit_num,
										permit_title,
										permit_type,
										specific_type
									FROM
										permit 
									WHERE 
										ISSUED_BY_AGENT_ID=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
								</cfquery>
								<cfquery name="getPermitContacts" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getPermitContacts_result">
									SELECT
										permit_num,
										permit_title,
										permit_type,
										specific_type
									FROM
										permit 
									WHERE 
										CONTACT_AGENT_ID=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
								</cfquery>
								<cfset totalPermitCount = getPermitsTo.recordcount + getPermitsFrom.recordCount + getPermitContacts.recordcount>
								<cfif totalPermitCount EQ 1><cfset plural=""><cfelse><cfset plural="s"></cfif>
								<cfif totalPermitCount GT 10>
									<!--- cardState = collapsed --->
									<cfset headerClass = "btn-link-collapsed">
									<cfset bodyClass = "collapse">
									<cfset ariaExpanded ="false">
								<cfelse>
									<!--- cardState = expanded--->
									<cfset headerClass = "btn-link">
									<cfset bodyClass = "collapse show">
									<cfset ariaExpanded ="true">
								</cfif>
								<div class="card-header" id="permitsHeader">
									<h2 class="h3">
										<button class="btn #headerClass#" data-toggle="collapse" data-target="##permitsCardBody" aria-expanded="#ariaExpanded#" aria-controls="permitsCardBody">
											Roles in Permissions and Rights Document#plural# (#totalPermitCount#)
										</button>
									</h2>
								</div>
								<div id="permitsCardBody" class="#bodyClass#" aria-labelledby="permitsHeader" data-parent="##rightAgentColl">
									<h3 class="h4 card-title">#prefName# has some role in #totalPermitCount# permissions and rights document#plural#.</h3>
									<div class="card-body">
										<ul class="list-group">
											<cfif getPermitsTo.recordcount EQ 0>
												<li class="list-group-item">No recorded permissions and rights documents issued to #encodeForHtml(prefName)#</li>
											<cfelse>
												<cfloop query="getPermitsTo">
													<cfif len(permit_num) EQ 0><cfset pnrDoc = permit_title><cfelse><cfset pnrDoc=permit_num></cfif>
													<cfif len(pnrDoc) EQ 0><cfset pnrDoc=specific_type ></cfif>
													<li class="list-group-item">
														Document 
														<a href="/transactions/Permit.cfm?action=search&execute=true&IssuedToaAgent=#encodeForURL(prefName)#&issued_by_agent_id=#agent_id#">
															#pnrDoc#
														</a> (#permit_type#:#specific_type#)
														was issued to #encodeForHtml(prefName)#
													</li>
												</cfloop>
											</cfif>
											<cfif getPermitsFrom.recordcount EQ 0>
												<li class="list-group-item">No recorded permissions and rights documents issued by #encodeForHtml(prefName)#</li>
											<cfelse>
												<cfloop query="getPermitsFrom">
													<cfif len(permit_num) EQ 0><cfset pnrDoc = permit_title><cfelse><cfset pnrDoc=permit_num></cfif>
													<cfif len(pnrDoc) EQ 0><cfset pnrDoc=specific_type ></cfif>
													<li class="list-group-item">
														Document 
														<a href="/transactions/Permit.cfm?action=search&execute=true&IssuedByAgent=#encodeForURL(prefName)#&issued_to_agent_id=#agent_id#">
															#pnrDoc#
														</a> (#permit_type#:#specific_type#)
														was issued by #encodeForHtml(prefName)#
													</li>
												</cfloop>
											</cfif>
											<cfif getPermitContacts.recordcount EQ 0>
												<li class="list-group-item">#encodeForHtml(prefName)# is the contact for no recorded permissions and rights documents</li>
											<cfelse>
												<cfloop query="getPermitContacts">
													<cfif len(permit_num) EQ 0><cfset pnrDoc = permit_title><cfelse><cfset pnrDoc=permit_num></cfif>
													<cfif len(pnrDoc) EQ 0><cfset pnrDoc=specific_type ></cfif>
													<li class="list-group-item">
														#encodeForHtml(prefName)# is contact for 
														<a href="/transactions/Permit.cfm?action=search&execute=true&ContactAgent=#encodeForURL(prefName)#&contact_agent_id=#agent_id#">
															#pnrDoc#
														</a> (#permit_type#:#specific_type#)
													</li>
												</cfloop>
											</cfif>
										</ul>
									</div>
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
