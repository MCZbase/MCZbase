<!---
/Admin/killBadAgentDups.cfm

Copyright 2008-2017 Contributors to Arctos
Copyright 2008-2026 President and Fellows of Harvard College

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
<cfset pageTitle = "Agent Merge">
<cfinclude template="/shared/_header.cfm">

<cfif isDefined("url.action")><cfset local.action = url.action></cfif>
<cfif isDefined("form.action")><cfset local.action = form.action></cfif>
<cfif NOT isDefined("local.action") OR len(local.action) EQ 0>
	<cfset local.action = "entryPoint">
</cfif>

<main class="container py-3" id="content">
	<cfswitch expression="#local.action#">
		<cfcase value="entryPoint">
			<section class="row my-2">
				<div class="col-12">
					<h1 class="h2 px-4">Merge Bad Duplicate Agents</h1>
					<p class="alert alert-danger px-4" role="alert">
						Before you even THINK about pushing this button, read through the list below, inspect individual
						agent records for anything ambiguous, then do it again. This will change agent IDs in many tables.
						Make sure you really want to proceed.
					</p>
				</div>
				<div class="col-12">
					<cfquery name="bads" datasource="uam_god">
						SELECT
							agent_relations.agent_id,
							badname.agent_name AS bad_name,
							related_agent_id,
							goodname.agent_name AS good_name,
							TO_CHAR(date_to_merge, 'YYYY-MM-DD') AS merge_date,
							DECODE(on_hold, 1, 'X', '') AS on_hold,
							held_by
						FROM
							agent_relations,
							preferred_agent_name badname,
							preferred_agent_name goodname
						WHERE
							agent_relationship = 'bad duplicate of'
							AND agent_relations.agent_id = badname.agent_id
							AND agent_relations.related_agent_id = goodname.agent_id
						ORDER BY
							date_to_merge DESC
					</cfquery>
					<cfoutput>
						<table class="table table-responsive d-lg-table">
							<thead class="thead-light">
								<tr>
									<th scope="col">Bad Name</th>
									<th scope="col">Good Name</th>
									<th scope="col">Date to be Merged</th>
									<th scope="col">On Hold</th>
								</tr>
							</thead>
							<tbody>
								<cfloop query="bads">
									<tr>
										<td>
											<a href="/agents/Agent.cfm?agent_id=#encodeForUrl(bads.agent_id)#" target="_blank">#encodeForHtml(bad_name)#</a>
										</td>
										<td>
											<a href="/agents/Agent.cfm?agent_id=#encodeForUrl(bads.related_agent_id)#" target="_blank">#encodeForHtml(good_name)#</a>
										</td>
										<td>#encodeForHtml(merge_date)#</td>
										<td class="text-center"><strong>#encodeForHtml(on_hold)#</strong></td>
									</tr>
								</cfloop>
							</tbody>
						</table>
						<form name="go" method="post" action="killBadAgentDups.cfm">
							<input type="hidden" name="action" value="doIt">
							<input type="submit" value="Make the Changes" class="btn btn-danger">
						</form>
					</cfoutput>
				</div>
			</section>
		</cfcase>
		<cfcase value="doIt">
			<section class="row my-2">
				<div class="col-12">
					<h1 class="h2 px-4">Execute Merge of Bad Duplicate Agents</h1>
					<p class="alert alert-danger px-4" role="alert">
						This is a destructive administrative operation. Review output carefully for skipped records and follow-up actions.
					</p>
				</div>
				<div class="col-12">
					<cfoutput>
						<cfquery name="bads" datasource="uam_god">
							SELECT
								agent_id,
								related_agent_id
							FROM
								agent_relations
							WHERE
								agent_relationship = 'bad duplicate of'
								AND (on_hold IS NULL OR on_hold <> 1)
								AND date_to_merge < SYSDATE
						</cfquery>

						<cfloop query="bads">
							<div class="border rounded p-2 my-2 bg-light">
								<strong>---#encodeForHtml(agent_id)#-----#encodeForHtml(related_agent_id)#----</strong><br>
								<cfflush>
								<cftransaction>
									<cfquery name="disableTrig" datasource="uam_god">
										ALTER TRIGGER TR_AGENT_NAME_BIUD DISABLE
									</cfquery>

									<cfset local.nogo = false>
									<cfset local.names = "">

									<cfquery name="name" datasource="uam_god">
										SELECT
											agent_name_id
										FROM
											agent_name
										WHERE
											agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#bads.agent_id#">
									</cfquery>

									<cfloop query="name">
										<cfset local.names = listAppend(local.names, agent_name_id)>
									</cfloop>

									<cfif len(local.names) EQ 0>
										There are no names for <a href="/agents/Agent.cfm?agent_id=#encodeForUrl(bads.agent_id)#">Agent ID #encodeForHtml(bads.agent_id)#</a>. It's probably a bad earlier deletion. Add a (fake) name and try again.<br>
										<cfset local.nogo = true>
									</cfif>

									<cfquery name="isGoodRelated" datasource="uam_god">
										SELECT
											agent_type
										FROM
											agent
										WHERE
											agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#bads.related_agent_id#">
									</cfquery>
									<cfif isGoodRelated.recordCount NEQ 1>
										<a href="/agents/Agent.cfm?agent_id=#encodeForUrl(bads.related_agent_id)#">Agent ID #encodeForHtml(bads.related_agent_id)#</a> isn&apos;t a viable replacement for #encodeForHtml(bads.agent_id)#.<br>
										<cfset local.nogo = true>
									</cfif>

									<cfif len(local.names) GT 0>
										<cfquery name="project_agent" datasource="uam_god">
											SELECT
												COUNT(*) AS cnt
											FROM
												project_agent
											WHERE
												agent_name_id IN (
													<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#local.names#" list="true">
												)
										</cfquery>
										<cfif project_agent.cnt GT 0>
											Agent ID #encodeForHtml(bads.agent_id)# is a project agent. I can't deal with that here.<br>
											<cfset local.nogo = true>
										</cfif>

										<cfquery name="publication_author_name" datasource="uam_god">
											SELECT
												COUNT(*) AS cnt
											FROM
												publication_author_name
											WHERE
												agent_name_id IN (
													<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#local.names#" list="true">
												)
										</cfquery>
										<cfif publication_author_name.cnt GT 0>
											<a href="/agents/Agent.cfm?agent_id=#encodeForUrl(bads.agent_id)#">Agent ID #encodeForHtml(bads.agent_id)#</a> is a publication agent. I can&apos;t deal with that here.<br>
											<cfset local.nogo = true>
										</cfif>
									</cfif>

									<cfquery name="agent_relations" datasource="uam_god">
										SELECT
											COUNT(*) AS cnt
										FROM
											agent_relations
										WHERE
											(agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#bads.agent_id#"> OR related_agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#bads.agent_id#">)
											AND NOT (
												(related_agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#bads.related_agent_id#"> AND agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#bads.agent_id#"> AND agent_relationship = 'bad duplicate of')
												OR (related_agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#bads.agent_id#"> AND agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#bads.related_agent_id#"> AND agent_relationship = 'good duplicate of')
											)
									</cfquery>
									<cfif agent_relations.cnt GT 0>
										<a href="/agents/Agent.cfm?agent_id=#encodeForUrl(bads.agent_id)#">Agent ID #encodeForHtml(bads.agent_id)#</a> is involved in relationships. I can&apos;t deal with that here.<br>
										<a href="/agents/Agent.cfm?agent_id=#encodeForUrl(bads.related_agent_id)#">Agent ID #encodeForHtml(bads.related_agent_id)# (good agent)</a><br>
										<cfquery name="relAgent" datasource="uam_god">
											SELECT
												agent_id,
												related_agent_id,
												agent_relationship
											FROM
												agent_relations
											WHERE
												agent_relationship <> 'bad duplicate of'
												AND (agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#bads.agent_id#"> OR related_agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#bads.agent_id#">)
										</cfquery>
										Relationships:
										<table class="table table-sm table-responsive d-lg-table">
											<thead class="thead-light">
												<tr>
													<th scope="col">ID</th>
													<th scope="col">Related ID</th>
													<th scope="col">Relationship</th>
												</tr>
											</thead>
											<tbody>
												<cfloop query="relAgent">
													<tr>
														<td><a href="/agents/Agent.cfm?agent_id=#encodeForUrl(agent_id)#">#encodeForHtml(agent_id)#</a></td>
														<td><a href="/agents/Agent.cfm?agent_id=#encodeForUrl(related_agent_id)#">#encodeForHtml(related_agent_id)#</a></td>
														<td>#encodeForHtml(agent_relationship)#</td>
													</tr>
												</cfloop>
											</tbody>
										</table>
										<cfset local.nogo = true>
									</cfif>

									<cfquery name="addr" datasource="uam_god">
										SELECT
											COUNT(*) AS cnt
										FROM
											addr
										WHERE
											agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#bads.agent_id#">
									</cfquery>
									<cfif addr.cnt GT 0>
										<a href="/agents/Agent.cfm?agent_id=#encodeForUrl(bads.agent_id)#">Agent ID #encodeForHtml(bads.agent_id)#</a> has addresses. I can&apos;t deal with that here.<br>
										<cfset local.nogo = true>
									</cfif>

									<cfquery name="electronic_address" datasource="uam_god">
										SELECT
											COUNT(*) AS cnt
										FROM
											electronic_address
										WHERE
											agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#bads.agent_id#">
									</cfquery>
									<cfif electronic_address.cnt GT 0>
										<a href="/agents/Agent.cfm?agent_id=#encodeForUrl(bads.agent_id)#">Agent ID #encodeForHtml(bads.agent_id)#</a> has electronic addresses. I can&apos;t deal with that here.<br>
										<cfset local.nogo = true>
									</cfif>

									<cfif NOT local.nogo>
										going--<br>
										good id: #encodeForHtml(bads.related_agent_id)#<br>
										bad id: #encodeForHtml(bads.agent_id)#<br>
										<cfflush>

										<cfquery name="collector" datasource="uam_god">
											UPDATE collector
											SET agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#bads.related_agent_id#">
											WHERE
												agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#bads.agent_id#">
										</cfquery>
										got collector<br><cfflush>
										<cfquery name="attributes" datasource="uam_god">
											UPDATE attributes
											SET determined_by_agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#bads.related_agent_id#">
											WHERE
												determined_by_agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#bads.agent_id#">
										</cfquery>
										got attributes<br><cfflush>
										<cfquery name="mediarc" datasource="uam_god">
											UPDATE media_relations
											SET CREATED_BY_AGENT_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#bads.related_agent_id#">
											WHERE
												CREATED_BY_AGENT_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#bads.agent_id#">
										</cfquery>
										got media 1<br><cfflush>
										<cfquery name="mediard" datasource="uam_god">
											UPDATE media_relations
											SET RELATED_PRIMARY_KEY = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#bads.related_agent_id#">
											WHERE
												RELATED_PRIMARY_KEY = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#bads.agent_id#">
												AND UPPER(SUBSTR(media_relationship, INSTR(media_relationship, ' ', -1) + 1)) = 'AGENT'
										</cfquery>
										got media 2<br><cfflush>
										<cfquery name="medialbl" datasource="uam_god">
											UPDATE media_labels
											SET ASSIGNED_BY_AGENT_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#bads.related_agent_id#">
											WHERE
												ASSIGNED_BY_AGENT_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#bads.agent_id#">
										</cfquery>
										got media label<br><cfflush>
										<cfquery name="encumbrance" datasource="uam_god">
											UPDATE encumbrance
											SET encumbering_agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#bads.related_agent_id#">
											WHERE
												encumbering_agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#bads.agent_id#">
										</cfquery>
										got encumbrance<br><cfflush>
										<cfquery name="identification_agent" datasource="uam_god">
											UPDATE identification_agent
											SET agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#bads.related_agent_id#">
											WHERE
												agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#bads.agent_id#">
										</cfquery>
										got ID agnt<br><cfflush>
										<cfquery name="disableLLTrig" datasource="uam_god">
											ALTER TRIGGER TR_LATLONG_ACCEPTED_BIUPA DISABLE
										</cfquery>
										<cfquery name="lat_long" datasource="uam_god">
											UPDATE lat_long
											SET determined_by_agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#bads.related_agent_id#">
											WHERE
												determined_by_agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#bads.agent_id#">
										</cfquery>
										<cfquery name="enableLLTrig" datasource="uam_god">
											ALTER TRIGGER TR_LATLONG_ACCEPTED_BIUPA ENABLE
										</cfquery>
										got latlong<br><cfflush>
										<cfquery name="permit_to" datasource="uam_god">
											UPDATE permit
											SET ISSUED_TO_AGENT_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#bads.related_agent_id#">
											WHERE
												ISSUED_TO_AGENT_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#bads.agent_id#">
										</cfquery>
										<cfquery name="trans_agent" datasource="uam_god">
											UPDATE trans_agent
											SET AGENT_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#bads.related_agent_id#">
											WHERE
												AGENT_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#bads.agent_id#">
										</cfquery>
										got tagent<br><cfflush>
										<cfquery name="permit_by" datasource="uam_god">
											UPDATE permit
											SET ISSUED_by_AGENT_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#bads.related_agent_id#">
											WHERE
												ISSUED_by_AGENT_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#bads.agent_id#">
										</cfquery>
										<cfquery name="permit_contact" datasource="uam_god">
											UPDATE permit
											SET CONTACT_AGENT_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#bads.related_agent_id#">
											WHERE
												CONTACT_AGENT_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#bads.agent_id#">
										</cfquery>
										got permit<br><cfflush>
										<cfquery name="shipment" datasource="uam_god">
											UPDATE shipment
											SET PACKED_BY_AGENT_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#bads.related_agent_id#">
											WHERE
												PACKED_BY_AGENT_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#bads.agent_id#">
										</cfquery>
										got shipment<br><cfflush>
										<cfquery name="entered" datasource="uam_god">
											UPDATE coll_object
											SET ENTERED_PERSON_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#bads.related_agent_id#">
											WHERE
												ENTERED_PERSON_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#bads.agent_id#">
										</cfquery>
										got collobject<br><cfflush>
										<cfquery name="last_edit" datasource="uam_god">
											UPDATE coll_object
											SET LAST_EDITED_PERSON_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#bads.related_agent_id#">
											WHERE
												LAST_EDITED_PERSON_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#bads.agent_id#">
										</cfquery>
										got collobjed<br><cfflush>
										<cfquery name="loan_item" datasource="uam_god">
											UPDATE loan_item
											SET RECONCILED_BY_PERSON_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#bads.related_agent_id#">
											WHERE
												RECONCILED_BY_PERSON_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#bads.agent_id#">
										</cfquery>
										<cfquery name="media_relations" datasource="uam_god">
											UPDATE media_relations
											SET RELATED_PRIMARY_KEY = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#bads.related_agent_id#">
											WHERE
												RELATED_PRIMARY_KEY = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#bads.agent_id#">
												AND MEDIA_RELATIONSHIP LIKE '% agent'
										</cfquery>
										<cfquery name="media_relations_creator" datasource="uam_god">
											UPDATE media_relations
											SET CREATED_BY_AGENT_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#bads.related_agent_id#">
											WHERE
												CREATED_BY_AGENT_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#bads.agent_id#">
										</cfquery>
										<cfquery name="media_labels" datasource="uam_god">
											UPDATE media_labels
											SET ASSIGNED_BY_AGENT_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#bads.related_agent_id#">
											WHERE
												ASSIGNED_BY_AGENT_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#bads.agent_id#">
										</cfquery>
										got media labels<br><cfflush>
										<cfquery name="group_member" datasource="uam_god">
											UPDATE group_member
											SET MEMBER_AGENT_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#bads.related_agent_id#">
											WHERE
												MEMBER_AGENT_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#bads.agent_id#">
										</cfquery>
										got group_member<br><cfflush>
										<cfquery name="object_condition" datasource="uam_god">
											UPDATE object_condition
											SET DETERMINED_AGENT_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#bads.related_agent_id#">
											WHERE
												DETERMINED_AGENT_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#bads.agent_id#">
										</cfquery>
										got object_condition<br><cfflush>
										<cfquery name="collection_contacts" datasource="uam_god">
											UPDATE collection_contacts
											SET CONTACT_AGENT_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#bads.related_agent_id#">
											WHERE
												CONTACT_AGENT_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#bads.agent_id#">
										</cfquery>
										got collection_contacts<br><cfflush>
										<cfquery name="annotated_agents" datasource="uam_god">
											UPDATE annotations
											SET target_primary_key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#bads.related_agent_id#">
											WHERE
												target_primary_key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#bads.agent_id#">
												AND UPPER(target_table) = 'AGENT'
										</cfquery>
										<cfquery name="annotation_reviewer_agents" datasource="uam_god">
											UPDATE annotations
											SET reviewer_agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#bads.related_agent_id#">
											WHERE
												reviewer_agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#bads.agent_id#">
										</cfquery>
										<cfquery name="annotating_agents" datasource="uam_god">
											UPDATE annotations
											SET annotator_agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#bads.related_agent_id#">
											WHERE
												annotator_agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#bads.agent_id#">
										</cfquery>
										<cfquery name="annotation_updating_agents" datasource="uam_god">
											UPDATE annotations
											SET last_updated_by_agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#bads.related_agent_id#">
											WHERE
												last_updated_by_agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#bads.agent_id#">
										</cfquery>
										got annotations<br><cfflush>
										<cfquery name="taxon_author" datasource="uam_god">
											UPDATE taxon_author
											SET agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#bads.related_agent_id#">
											WHERE
												agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#bads.agent_id#">
										</cfquery>
										got taxon authors<br><cfflush>
										<cfquery name="related" datasource="uam_god">
											DELETE FROM agent_relations
											WHERE
												agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#bads.agent_id#">
												OR related_agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#bads.agent_id#">
										</cfquery>
										del agntreln<br><cfflush>
										<cfquery name="killnames" datasource="uam_god">
											DELETE FROM agent_name
											WHERE
												agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#bads.agent_id#">
										</cfquery>
										del agntname<br><cfflush>
										<cfquery name="killperson" datasource="uam_god">
											DELETE FROM person
											WHERE
												person_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#bads.agent_id#">
										</cfquery>
										del person<br><cfflush>
										<cfquery name="killagent" datasource="uam_god">
											DELETE FROM agent
											WHERE
												agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#bads.agent_id#">
										</cfquery>
										del agnt<br><cfflush>
									</cfif>

									<cfquery name="enableTrig" datasource="uam_god">
										ALTER TRIGGER TR_AGENT_NAME_BIUD ENABLE
									</cfquery>
								</cftransaction>
							</div>
						</cfloop>
						<p>Anything linked above was missed and needs your attention. Otherwise, it&apos;s all cleaned up!</p>
					</cfoutput>
				</div>
			</section>
		</cfcase>
		<cfdefaultcase>
			<cflocation url="/Admin/killBadAgentDups.cfm" addtoken="false">
		</cfdefaultcase>
	</cfswitch>
</main>

<cfinclude template="/shared/_footer.cfm">
