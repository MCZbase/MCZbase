<cfset pageTitle = "Review Pending Agent Merges">
<!---
/Admin/agentMergeReview.cfm

Copyright 2008-2017 Contributors to Arctos
Copyright 2008-2021 President and Fellows of Harvard College

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
<!--- Manage scheduled merges of agents --->
<cfinclude template="/shared/_header.cfm">
<cfif not isDefined("action") OR len(action) EQ 0>
	<cfset action="nothing">
</cfif>
<cfinclude template="/shared/component/error_handler.cfc" runOnce="true">

<cfswitch expression="#action#">
	<cfcase value="nothing">
		<script src="/lib/misc/sorttable.js"></script>
		<main class="container py-3" id="content" >
			<section class="row my-2">
				<h1 class="h2 px-4">Review Pending Duplicate Agent Merges</h1>

				<!--- make privileged users able to force the change read the list before pushing the button! ---->

				<cfquery name="bads" datasource="uam_god">
					SELECT distinct
						agent_relations.agent_id,
						badname.agent_name bad_name,
						badagent.edited bad_edited,
						related_agent_id,
						goodname.agent_name good_name,
						goodagent.edited good_edited,
						to_char(date_to_merge, 'YYYY-MM-DD') merge_date,
						date_to_merge,
						DECODE(on_hold, 1, 'X', '') on_hold, 
						held_by held_by,
						created_by created_by
					FROM
						agent_relations
						left join preferred_agent_name badname on agent_relations.agent_id = badname.agent_id
						left join agent badagent on agent_relations.agent_id = badagent.agent_id
						left join preferred_agent_name goodname on agent_relations.related_agent_id = goodname.agent_id
						left join agent goodagent on agent_relations.related_agent_id = goodagent.agent_id
					WHERE
						agent_relationship = 'bad duplicate of'
					ORDER BY
						 date_to_merge desc
				</cfquery>
				<form class="col-12" name="go" method="post" action="/Admin/agentMergeReview.cfm">
					<table border id="mergeTable" class="sortable table table-responsive d-xl-table">
						<tr>
							<th>Bad Name</th>
							<th>Good Name</th>
							<th>Hold</th>
							<th>Date to be Merged</th>
							<th>On Hold</th>
							<th>Held By</th>
							<th>Created By</th>
						</tr>
						<cfoutput>
							<cfloop query="bads">
								<cfif bad_edited EQ 1 ><cfset badedited_marker=" <span class='text-danger font-weight-bold' style='font-size: larger;'>*</span>"><cfelse><cfset badedited_marker=""></cfif> 
								<cfif good_edited EQ 1 ><cfset goodedited_marker=" *"><cfelse><cfset goodedited_marker=""></cfif> 
								<tr>
									<td>
										<a href="/agents/Agent.cfm?agent_id=#bads.agent_id#" target="_blank">#bad_name#</a>#badedited_marker#
									</td>
									<td>
										<a href="/agents/Agent.cfm?agent_id=#bads.related_agent_id#" target="_blank">#good_name#</a>#goodedited_marker#
									</td>
									<td>
										<input type=checkbox name=holdMerge value=#agent_id#_#related_agent_id#></input>
									</td>
									<td>
										#merge_date#
									</td>
									<td align=center>
										<strong>#on_hold#</strong>
									</td>
									<td>#held_by#</td>
									<td>#created_by#</td>
								</tr>
							</cfloop>
						</cfoutput>
					</table>
					<input type="hidden" name="action" value="doIt">
					<input type="submit" class="btn btn-xs btn-primary" value="Put selected records on Hold" >
				</form>
				<!---
				<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"global_admin")>
					<div class="col-12">
						<h2 class="h3 text-danger">Force all merges now</h2> 
						<p>Before you even THINK about pushing this button, read through the list above, look at the individual 
						agent records for anything that's even a little bit ambiguous, then do it again. You will be changing 
						agent IDs in a big pile-O-tables; make sure you really want to first!</p>
						<form name="go" method="post" action="killBadAgentDups.cfm">
							<input type="hidden" name="action" value="doIt">
							<input type="submit" value="Make the Changes" class="btn btn-xs btn-warning">
						</form>
					</div>
				</cfif>
				--->
			</section>
		</main>
	</cfcase>
	<cfcase value="doIt">
		<!-------------------------hold agents on submit--->
		<cfparam name="form.holdMerge" default="" />
		<cftransaction>
			<cftry>
				<cfloop list="#form.holdMerge#" index="i">
					<cfquery name="upOnHold" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						update agent_relations set on_hold = 1, held_by = '#session.dbuser#' where
						agent_id = #ListGetAt(i, 1, '_')# and
						related_agent_id = #ListGetAt(i, 2, '_')# and
						agent_relationship = 'bad duplicate of'
					</cfquery>
				</cfloop>
				<cftransaction action="commit">
				<cflocation url="/Admin/agentMergeReview.cfm">
			<cfcatch>
				<cftransaction action="rollback">
				<cfset error_message = cfcatchToErrorMessage(cfcatch)>
				<cfthrow message="#error_message#">
			</cfcatch>
			</cftry>
		</cftransaction>
	</cfcase>
</cfswitch>

<cfinclude template = "/shared/_footer.cfm">
