<!---
projects/component/functions.cfc

Copyright 2020-2026 President and Fellows of Harvard College

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
<cfcomponent>

<cfinclude template = "/shared/functionLib.cfm">
<cfinclude template="/shared/component/error_handler.cfc" runOnce="true">

<!--- backing for a project autocomplete control --->
<cffunction name="getProjectAutocomplete" access="remote" returntype="any" returnformat="json">
	<cfargument name="term" type="string" required="yes">
	<cfset data = ArrayNew(1)>

	<cftry>
		<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
			<cfset oneOfUs = 1>
		<cfelse>
			<cfset oneOfUs = 0>
		</cfif>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="search_result">
			select distinct project_name, project_id,
				to_char(start_date,'YYYY-MM-DD') as start_date,
				to_char(end_date,'YYYY-MM-DD') as end_date
			from project
			where
				upper(project_name) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(term)#%">
				<cfif oneOfUs NEQ 1>
					AND project.mask_project_fg = 0
				</cfif>
			order by project_name
		</cfquery>
		<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfset row["id"] = "#search.project_id#">
			<cfset row["value"] = "#search.project_name#" >
			<cfset row["meta"] = "#search.project_name# (#search.start_date#/#search.end_date#)" >
			<cfset data[i]  = row>
			<cfset i = i + 1>
		</cfloop>
		<cfreturn #serializeJSON(data)#>
	<cfcatch>
		<cfset error_message = cfcatchToErrorMessage(cfcatch)>
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn #serializeJSON(data)#>
</cffunction>

<!---
requireManageProjects aborts with a "Not Authorized" message unless the session has the
manage_projects role. Called at the top of every mutating method below.
--->
<cffunction name="requireManageProjects" access="private" returntype="void">
	<cfif NOT (isdefined("session.roles") AND listfindnocase(session.roles,"manage_projects"))>
		<cfthrow message="Not Authorized: manage_projects role is required.">
	</cfif>
</cffunction>

<!---
Function saveProject. Update a project's own fields (not its related records).

@param project_id the project to update.
@param project_name new project name.
@param start_date new start date, 'yyyy-mm-dd', or blank to clear.
@param end_date new end date, 'yyyy-mm-dd', or blank to clear.
@param project_description new description, or blank to clear.
@param project_remarks new remarks, or blank to clear.
@param mask_project_fg "0" (public) or "1" (hidden).
@return a struct: status (1 on success), message.
--->
<cffunction name="saveProject" access="remote" returntype="any" returnformat="json">
	<cfargument name="project_id" type="string" required="yes">
	<cfargument name="project_name" type="string" required="yes">
	<cfargument name="start_date" type="string" required="no" default="">
	<cfargument name="end_date" type="string" required="no" default="">
	<cfargument name="project_description" type="string" required="no" default="">
	<cfargument name="project_remarks" type="string" required="no" default="">
	<cfargument name="mask_project_fg" type="string" required="no" default="0">

	<cfset requireManageProjects()>
	<cfset theResult = queryNew("status, message")>
	<cftransaction>
		<cftry>
			<cfquery name="upProject" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="upProject_result">
				UPDATE project
				SET
					project_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.project_name#">,
					mask_project_fg = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.mask_project_fg#">
					<cfif len(arguments.start_date) GT 0>
						,start_date = <cfqueryparam cfsqltype="CF_SQL_TIMESTAMP" value="#arguments.start_date#">
					<cfelse>
						,start_date = NULL
					</cfif>
					<cfif len(arguments.end_date) GT 0>
						,end_date = <cfqueryparam cfsqltype="CF_SQL_TIMESTAMP" value="#arguments.end_date#">
					<cfelse>
						,end_date = NULL
					</cfif>
					<cfif len(arguments.project_description) GT 0>
						,project_description = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.project_description#">
					<cfelse>
						,project_description = NULL
					</cfif>
					<cfif len(arguments.project_remarks) GT 0>
						,project_remarks = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.project_remarks#">
					<cfelse>
						,project_remarks = NULL
					</cfif>
				WHERE project_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.project_id#">
			</cfquery>
			<cfset t = queryaddrow(theResult,1)>
			<cfset t = QuerySetCell(theResult, "status", "1", 1)>
			<cfset t = QuerySetCell(theResult, "message", "Project saved.", 1)>
			<cftransaction action="commit">
		<cfcatch>
			<cftransaction action="rollback">
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn #theResult#>
</cffunction>

<!---
Function getAgentsHtml. Render the Agents section (project_agent) as an HTML fragment:
existing agents with editable role/position and a Remove button, followed by an
add-agent row using the rich agent picker (project_agent constraint).

@param project_id the project to render agents for.
@return an HTML fragment.
--->
<cffunction name="getAgentsHtml" access="remote" returntype="string" returnformat="plain">
	<cfargument name="project_id" type="string" required="yes">
	<cfthread name="agentsThread">
		<cfoutput>
			<cftry>
				<cfquery name="ctRole" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT project_agent_role FROM ctproject_agent_role ORDER BY project_agent_role
				</cfquery>
				<cfquery name="agents" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="agents_result">
					SELECT
						agent_name.agent_id,
						agent_name.agent_name,
						project_agent.agent_name_id,
						project_agent.project_agent_role,
						project_agent.agent_position
					FROM
						project_agent
						JOIN agent_name ON project_agent.agent_name_id = agent_name.agent_name_id
					WHERE
						project_agent.project_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#project_id#">
					ORDER BY
						project_agent.agent_position
				</cfquery>
				<cfquery name="maxPos" dbtype="query">
					SELECT MAX(agent_position) AS agent_position FROM agents
				</cfquery>
				<cfset numPositions = 1>
				<cfif len(maxPos.agent_position) GT 0>
					<cfset numPositions = maxPos.agent_position + 1>
				</cfif>
				<cfif agents.recordcount EQ 0>
					<p>None.</p>
				<cfelse>
					<ul class="list-group mb-2">
						<cfloop query="agents">
							<li class="list-group-item">
								<div class="form-row align-items-end">
									<div class="col-12 col-md-4">
										<label class="data-entry-label mb-0" for="agent_role_#agent_name_id#">
											<a href="/agents/Agent.cfm?agent_id=#agent_id#">#encodeForHtml(agent_name)#</a>
										</label>
										<select id="agent_role_#agent_name_id#" class="data-entry-select">
											<cfloop query="ctRole">
												<cfif ctRole.project_agent_role EQ agents.project_agent_role><cfset selected="selected"><cfelse><cfset selected=""></cfif>
												<option value="#ctRole.project_agent_role#" #selected#>#ctRole.project_agent_role#</option>
											</cfloop>
										</select>
									</div>
									<div class="col-6 col-md-2">
										<label class="data-entry-label mb-0" for="agent_position_#agent_name_id#">Position</label>
										<select id="agent_position_#agent_name_id#" class="data-entry-select">
											<cfloop from="1" to="#numPositions#" index="p">
												<cfif p EQ agent_position><cfset selected="selected"><cfelse><cfset selected=""></cfif>
												<option value="#p#" #selected#>#p#</option>
											</cfloop>
										</select>
									</div>
									<div class="col-3 col-md-2">
										<button type="button" class="btn btn-xs btn-secondary" onclick="saveProjectAgent(#project_id#,#agent_name_id#,'agent_role_#agent_name_id#','agent_position_#agent_name_id#');">Save</button>
									</div>
									<div class="col-3 col-md-2">
										<button type="button" class="btn btn-xs btn-warning" onclick="removeProjectAgent(#project_id#,#agent_name_id#);">Remove</button>
									</div>
								</div>
							</li>
						</cfloop>
					</ul>
				</cfif>
				<div class="form-row align-items-end">
					<div class="col-12 col-md-4">
						<label class="data-entry-label mb-0" for="new_agent_name">Add Agent</label>
						<div class="input-group">
							<div class="input-group-prepend">
								<span class="input-group-text smaller bg-lightgreen" id="new_agent_icon"><i class="fa fa-user" aria-hidden="true"></i></span>
							</div>
							<input type="text" id="new_agent_name" class="w-auto h-auto form-control rounded-right data-entry-input form-control-sm" aria-label="New agent name">
							<input type="hidden" id="new_agent_id">
						</div>
					</div>
					<div class="col-6 col-md-2">
						<label class="data-entry-label mb-0" for="new_agent_role">Role</label>
						<select id="new_agent_role" class="data-entry-select">
							<cfloop query="ctRole">
								<option value="#ctRole.project_agent_role#">#ctRole.project_agent_role#</option>
							</cfloop>
						</select>
					</div>
					<div class="col-6 col-md-2">
						<label class="data-entry-label mb-0" for="new_agent_position">Position</label>
						<select id="new_agent_position" class="data-entry-select">
							<cfloop from="1" to="#numPositions#" index="p">
								<cfif p EQ numPositions><cfset selected="selected"><cfelse><cfset selected=""></cfif>
								<option value="#p#" #selected#>#p#</option>
							</cfloop>
						</select>
					</div>
					<div class="col-12 col-md-2">
						<button type="button" class="btn btn-xs btn-secondary" onclick="addProjectAgent(#project_id#);">Add</button>
					</div>
				</div>
				<script>
					$(document).ready(function () {
						makeConstrainedRichAgentPickerConfig("new_agent_name", "new_agent_id", "new_agent_icon", null, "", "project_agent", false);
					});
				</script>
			<cfcatch>
				<p class="text-danger">Error: #cfcatch.message#</p>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="agentsThread" />
	<cfreturn agentsThread.output>
</cffunction>

<!---
Function addProjectAgent. Insert a project_agent row.

@param project_id the project.
@param agent_name_id the agent to add (a specific name/spelling, not a bare agent_id).
@param project_agent_role the agent's role on the project.
@param agent_position display position among the project's other agents.
@return a struct: status (1 on success), message.
--->
<cffunction name="addProjectAgent" access="remote" returntype="any" returnformat="json">
	<cfargument name="project_id" type="string" required="yes">
	<cfargument name="agent_name_id" type="string" required="yes">
	<cfargument name="project_agent_role" type="string" required="yes">
	<cfargument name="agent_position" type="string" required="no" default="1">

	<cfset requireManageProjects()>
	<cfset theResult = queryNew("status, message")>
	<cftransaction>
		<cftry>
			<cfif len(arguments.agent_name_id) EQ 0>
				<cfthrow message="Unable to add agent, no agent selected. You must pick an agent from the pick list.">
			</cfif>
			<cfquery name="newAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="newAgent_result">
				INSERT INTO project_agent (
					PROJECT_ID,
					AGENT_NAME_ID,
					PROJECT_AGENT_ROLE,
					AGENT_POSITION
				) VALUES (
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.project_id#">,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.agent_name_id#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.project_agent_role#">,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.agent_position#">
				)
			</cfquery>
			<cfset t = queryaddrow(theResult,1)>
			<cfset t = QuerySetCell(theResult, "status", "1", 1)>
			<cfset t = QuerySetCell(theResult, "message", "Agent added.", 1)>
			<cftransaction action="commit">
		<cfcatch>
			<cftransaction action="rollback">
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn #theResult#>
</cffunction>

<!---
Function saveProjectAgent. Update an existing project_agent row's role/position.
--->
<cffunction name="saveProjectAgent" access="remote" returntype="any" returnformat="json">
	<cfargument name="project_id" type="string" required="yes">
	<cfargument name="agent_name_id" type="string" required="yes">
	<cfargument name="project_agent_role" type="string" required="yes">
	<cfargument name="agent_position" type="string" required="no" default="1">

	<cfset requireManageProjects()>
	<cfset theResult = queryNew("status, message")>
	<cftransaction>
		<cftry>
			<cfquery name="upAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="upAgent_result">
				UPDATE project_agent
				SET
					project_agent_role = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.project_agent_role#">,
					agent_position = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.agent_position#">
				WHERE
					project_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.project_id#">
					AND agent_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.agent_name_id#">
			</cfquery>
			<cfset t = queryaddrow(theResult,1)>
			<cfset t = QuerySetCell(theResult, "status", "1", 1)>
			<cfset t = QuerySetCell(theResult, "message", "Agent updated.", 1)>
			<cftransaction action="commit">
		<cfcatch>
			<cftransaction action="rollback">
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn #theResult#>
</cffunction>

<!---
Function removeProjectAgent. Delete a project_agent row.
--->
<cffunction name="removeProjectAgent" access="remote" returntype="any" returnformat="json">
	<cfargument name="project_id" type="string" required="yes">
	<cfargument name="agent_name_id" type="string" required="yes">

	<cfset requireManageProjects()>
	<cfset theResult = queryNew("status, message")>
	<cftransaction>
		<cftry>
			<cfquery name="delAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="delAgent_result">
				DELETE FROM project_agent
				WHERE
					project_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.project_id#">
					AND agent_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.agent_name_id#">
			</cfquery>
			<cfset t = queryaddrow(theResult,1)>
			<cfset t = QuerySetCell(theResult, "status", "1", 1)>
			<cfset t = QuerySetCell(theResult, "message", "Agent removed.", 1)>
			<cftransaction action="commit">
		<cfcatch>
			<cftransaction action="rollback">
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn #theResult#>
</cffunction>

<!---
Function getSponsorsHtml. Render the Sponsors section (project_sponsor) as an HTML
fragment: existing sponsors with an editable acknowledgement and a Remove button,
followed by an add-sponsor row using the rich agent picker (project_sponsor constraint).
--->
<cffunction name="getSponsorsHtml" access="remote" returntype="string" returnformat="plain">
	<cfargument name="project_id" type="string" required="yes">
	<cfthread name="sponsorsThread">
		<cfoutput>
			<cftry>
				<cfquery name="sponsors" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="sponsors_result">
					SELECT
						project_sponsor.project_sponsor_id,
						agent_name.agent_id,
						agent_name.agent_name,
						project_sponsor.acknowledgement
					FROM
						project_sponsor
						JOIN agent_name ON project_sponsor.agent_name_id = agent_name.agent_name_id
					WHERE
						project_sponsor.project_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#project_id#">
					ORDER BY
						agent_name.agent_name
				</cfquery>
				<cfif sponsors.recordcount EQ 0>
					<p>None.</p>
				<cfelse>
					<ul class="list-group mb-2">
						<cfloop query="sponsors">
							<li class="list-group-item">
								<div class="form-row align-items-end">
									<div class="col-12 col-md-4">
										<label class="data-entry-label mb-0" for="sponsor_ack_#project_sponsor_id#"><a href="/agents/Agent.cfm?agent_id=#agent_id#">#encodeForHtml(agent_name)#</a></label>
									</div>
									<div class="col-12 col-md-4">
										<label class="data-entry-label mb-0" for="sponsor_ack_#project_sponsor_id#">Acknowledgement</label>
										<input type="text" id="sponsor_ack_#project_sponsor_id#" class="data-entry-input" value="#encodeForHtml(acknowledgement)#">
									</div>
									<div class="col-6 col-md-2">
										<button type="button" class="btn btn-xs btn-secondary" onclick="saveProjectSponsor(#project_sponsor_id#,'sponsor_ack_#project_sponsor_id#');">Save</button>
									</div>
									<div class="col-6 col-md-2">
										<button type="button" class="btn btn-xs btn-warning" onclick="removeProjectSponsor(#project_id#,#project_sponsor_id#);">Remove</button>
									</div>
								</div>
							</li>
						</cfloop>
					</ul>
				</cfif>
				<div class="form-row align-items-end">
					<div class="col-12 col-md-4">
						<label class="data-entry-label mb-0" for="new_sponsor_name">Add Sponsor</label>
						<div class="input-group">
							<div class="input-group-prepend">
								<span class="input-group-text smaller bg-lightgreen" id="new_sponsor_icon"><i class="fa fa-user" aria-hidden="true"></i></span>
							</div>
							<input type="text" id="new_sponsor_name" class="w-auto h-auto form-control rounded-right data-entry-input form-control-sm" aria-label="New sponsor name">
							<input type="hidden" id="new_sponsor_id">
						</div>
					</div>
					<div class="col-12 col-md-4">
						<label class="data-entry-label mb-0" for="new_sponsor_ack">Acknowledgement</label>
						<input type="text" id="new_sponsor_ack" class="data-entry-input">
					</div>
					<div class="col-12 col-md-2">
						<button type="button" class="btn btn-xs btn-secondary" onclick="addProjectSponsor(#project_id#);">Add</button>
					</div>
				</div>
				<script>
					$(document).ready(function () {
						makeConstrainedRichAgentPickerConfig("new_sponsor_name", "new_sponsor_id", "new_sponsor_icon", null, "", "project_sponsor", false);
					});
				</script>
			<cfcatch>
				<p class="text-danger">Error: #cfcatch.message#</p>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="sponsorsThread" />
	<cfreturn sponsorsThread.output>
</cffunction>

<!---
Function addProjectSponsor. Insert a project_sponsor row.
--->
<cffunction name="addProjectSponsor" access="remote" returntype="any" returnformat="json">
	<cfargument name="project_id" type="string" required="yes">
	<cfargument name="agent_name_id" type="string" required="yes">
	<cfargument name="acknowledgement" type="string" required="no" default="">

	<cfset requireManageProjects()>
	<cfset theResult = queryNew("status, message")>
	<cftransaction>
		<cftry>
			<cfif len(arguments.agent_name_id) EQ 0>
				<cfthrow message="Unable to add sponsor, no agent selected. You must pick an agent from the pick list.">
			</cfif>
			<cfquery name="newSponsor" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="newSponsor_result">
				INSERT INTO project_sponsor (
					PROJECT_ID,
					AGENT_NAME_ID,
					ACKNOWLEDGEMENT
				) VALUES (
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.project_id#">,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.agent_name_id#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.acknowledgement#">
				)
			</cfquery>
			<cfset t = queryaddrow(theResult,1)>
			<cfset t = QuerySetCell(theResult, "status", "1", 1)>
			<cfset t = QuerySetCell(theResult, "message", "Sponsor added.", 1)>
			<cftransaction action="commit">
		<cfcatch>
			<cftransaction action="rollback">
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn #theResult#>
</cffunction>

<!---
Function saveProjectSponsor. Update an existing project_sponsor row's acknowledgement.
--->
<cffunction name="saveProjectSponsor" access="remote" returntype="any" returnformat="json">
	<cfargument name="project_sponsor_id" type="string" required="yes">
	<cfargument name="acknowledgement" type="string" required="no" default="">

	<cfset requireManageProjects()>
	<cfset theResult = queryNew("status, message")>
	<cftransaction>
		<cftry>
			<cfquery name="upSponsor" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="upSponsor_result">
				UPDATE project_sponsor
				SET
					acknowledgement = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.acknowledgement#">
				WHERE
					project_sponsor_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.project_sponsor_id#">
			</cfquery>
			<cfset t = queryaddrow(theResult,1)>
			<cfset t = QuerySetCell(theResult, "status", "1", 1)>
			<cfset t = QuerySetCell(theResult, "message", "Sponsor updated.", 1)>
			<cftransaction action="commit">
		<cfcatch>
			<cftransaction action="rollback">
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn #theResult#>
</cffunction>

<!---
Function removeProjectSponsor. Delete a project_sponsor row.
--->
<cffunction name="removeProjectSponsor" access="remote" returntype="any" returnformat="json">
	<cfargument name="project_id" type="string" required="yes">
	<cfargument name="project_sponsor_id" type="string" required="yes">

	<cfset requireManageProjects()>
	<cfset theResult = queryNew("status, message")>
	<cftransaction>
		<cftry>
			<cfquery name="delSponsor" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="delSponsor_result">
				DELETE FROM project_sponsor
				WHERE project_sponsor_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.project_sponsor_id#">
			</cfquery>
			<cfset t = queryaddrow(theResult,1)>
			<cfset t = QuerySetCell(theResult, "status", "1", 1)>
			<cfset t = QuerySetCell(theResult, "message", "Sponsor removed.", 1)>
			<cftransaction action="commit">
		<cfcatch>
			<cftransaction action="rollback">
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn #theResult#>
</cffunction>

<!---
Function getLoansHtml. Render the Loans section (project_trans/loan) as an HTML fragment:
existing loans linked to this project with a Remove button, followed by an add-loan row
using the existing loan-number picker.
--->
<cffunction name="getLoansHtml" access="remote" returntype="string" returnformat="plain">
	<cfargument name="project_id" type="string" required="yes">
	<cfthread name="loansThread">
		<cfoutput>
			<cftry>
				<cfquery name="loans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="loans_result">
					SELECT
						collection.collection,
						loan.loan_number,
						loan.transaction_id,
						trans.nature_of_material,
						project_trans.project_trans_remarks
					FROM
						project_trans
						JOIN loan ON project_trans.transaction_id = loan.transaction_id
						JOIN trans ON loan.transaction_id = trans.transaction_id
						JOIN collection ON trans.collection_id = collection.collection_id
					WHERE
						project_trans.project_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#project_id#">
					ORDER BY
						collection.collection, loan.loan_number
				</cfquery>
				<cfif loans.recordcount EQ 0>
					<p>None.</p>
				<cfelse>
					<ul class="list-group mb-2">
						<cfloop query="loans">
							<li class="list-group-item">
								<a href="/transactions/Loan.cfm?action=editLoan&transaction_id=#transaction_id#" target="_blank">#encodeForHtml(collection)# #encodeForHtml(loan_number)#</a>
								<cfif len(project_trans_remarks) GT 0> -- #encodeForHtml(project_trans_remarks)#</cfif>
								<button type="button" class="btn btn-xs btn-warning float-right" onclick="removeProjectTransaction(#project_id#,#transaction_id#);">Remove</button>
							</li>
						</cfloop>
					</ul>
				</cfif>
				<div class="form-row align-items-end">
					<div class="col-12 col-md-5">
						<label class="data-entry-label mb-0" for="new_loan_number">Add Loan (by loan number)</label>
						<input type="text" id="new_loan_number" class="data-entry-input" placeholder="yyyy-n-Coll">
						<input type="hidden" id="new_loan_transaction_id">
					</div>
					<div class="col-12 col-md-4">
						<label class="data-entry-label mb-0" for="new_loan_remarks">Remarks</label>
						<input type="text" id="new_loan_remarks" class="data-entry-input">
					</div>
					<div class="col-12 col-md-2">
						<button type="button" class="btn btn-xs btn-secondary" onclick="addProjectLoan(#project_id#);">Add</button>
					</div>
				</div>
				<script>
					$(document).ready(function () {
						makeLoanPicker("new_loan_number", "new_loan_transaction_id");
					});
				</script>
			<cfcatch>
				<p class="text-danger">Error: #cfcatch.message#</p>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="loansThread" />
	<cfreturn loansThread.output>
</cffunction>

<!---
Function getAccessionsHtml. Render the Accessions section (project_trans/accn) as an HTML
fragment: existing accessions linked to this project with a Remove button, followed by an
add-accession row using an accession-number picker.
--->
<cffunction name="getAccessionsHtml" access="remote" returntype="string" returnformat="plain">
	<cfargument name="project_id" type="string" required="yes">
	<cfthread name="accessionsThread">
		<cfoutput>
			<cftry>
				<cfquery name="accns" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="accns_result">
					SELECT
						collection.collection,
						accn.accn_number,
						accn.transaction_id,
						trans.nature_of_material,
						project_trans.project_trans_remarks
					FROM
						project_trans
						JOIN accn ON project_trans.transaction_id = accn.transaction_id
						JOIN trans ON accn.transaction_id = trans.transaction_id
						JOIN collection ON trans.collection_id = collection.collection_id
					WHERE
						project_trans.project_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#project_id#">
					ORDER BY
						collection.collection, accn.accn_number
				</cfquery>
				<cfif accns.recordcount EQ 0>
					<p>None.</p>
				<cfelse>
					<ul class="list-group mb-2">
						<cfloop query="accns">
							<li class="list-group-item">
								<a href="/transactions/Accession.cfm?action=edit&transaction_id=#transaction_id#" target="_blank">#encodeForHtml(collection)# #encodeForHtml(accn_number)#</a>
								<cfif len(project_trans_remarks) GT 0> -- #encodeForHtml(project_trans_remarks)#</cfif>
								<button type="button" class="btn btn-xs btn-warning float-right" onclick="removeProjectTransaction(#project_id#,#transaction_id#);">Remove</button>
							</li>
						</cfloop>
					</ul>
				</cfif>
				<div class="form-row align-items-end">
					<div class="col-12 col-md-5">
						<label class="data-entry-label mb-0" for="new_accn_number">Add Accession (by accession number)</label>
						<input type="text" id="new_accn_number" class="data-entry-input" placeholder="99999999">
						<input type="hidden" id="new_accn_transaction_id">
					</div>
					<div class="col-12 col-md-4">
						<label class="data-entry-label mb-0" for="new_accn_remarks">Remarks</label>
						<input type="text" id="new_accn_remarks" class="data-entry-input">
					</div>
					<div class="col-12 col-md-2">
						<button type="button" class="btn btn-xs btn-secondary" onclick="addProjectAccession(#project_id#);">Add</button>
					</div>
				</div>
				<script>
					$(document).ready(function () {
						makeAccessionAutocompleteMeta("new_accn_number", "new_accn_transaction_id");
					});
				</script>
			<cfcatch>
				<p class="text-danger">Error: #cfcatch.message#</p>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="accessionsThread" />
	<cfreturn accessionsThread.output>
</cffunction>

<!---
Function addProjectTransaction. Link a transaction (loan or accession) to a project.
Shared by both the Loans and Accessions sections, since project_trans doesn't
distinguish transaction type.

@param project_id the project.
@param transaction_id the transaction to link (a loan or accession's transaction_id).
@param project_trans_remarks optional remarks specific to this project/transaction link.
@return a struct: status (1 on success), message.
--->
<cffunction name="addProjectTransaction" access="remote" returntype="any" returnformat="json">
	<cfargument name="project_id" type="string" required="yes">
	<cfargument name="transaction_id" type="string" required="yes">
	<cfargument name="project_trans_remarks" type="string" required="no" default="">

	<cfset requireManageProjects()>
	<cfset theResult = queryNew("status, message")>
	<cftransaction>
		<cftry>
			<cfif len(arguments.transaction_id) EQ 0>
				<cfthrow message="Unable to link transaction, none selected. You must pick one from the pick list.">
			</cfif>
			<cfquery name="newProjTrans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="newProjTrans_result">
				INSERT INTO project_trans (
					PROJECT_ID,
					TRANSACTION_ID
					<cfif len(arguments.project_trans_remarks) GT 0>
						,PROJECT_TRANS_REMARKS
					</cfif>
				) VALUES (
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.project_id#">,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.transaction_id#">
					<cfif len(arguments.project_trans_remarks) GT 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.project_trans_remarks#">
					</cfif>
				)
			</cfquery>
			<cfset t = queryaddrow(theResult,1)>
			<cfset t = QuerySetCell(theResult, "status", "1", 1)>
			<cfset t = QuerySetCell(theResult, "message", "Transaction linked.", 1)>
			<cftransaction action="commit">
		<cfcatch>
			<cftransaction action="rollback">
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn #theResult#>
</cffunction>

<!---
Function removeProjectTransaction. Unlink a transaction (loan or accession) from a
project. Shared by both the Loans and Accessions sections.
--->
<cffunction name="removeProjectTransaction" access="remote" returntype="any" returnformat="json">
	<cfargument name="project_id" type="string" required="yes">
	<cfargument name="transaction_id" type="string" required="yes">

	<cfset requireManageProjects()>
	<cfset theResult = queryNew("status, message")>
	<cftransaction>
		<cftry>
			<cfquery name="delProjTrans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="delProjTrans_result">
				DELETE FROM project_trans
				WHERE
					project_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.project_id#">
					AND transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.transaction_id#">
			</cfquery>
			<cfset t = queryaddrow(theResult,1)>
			<cfset t = QuerySetCell(theResult, "status", "1", 1)>
			<cfset t = QuerySetCell(theResult, "message", "Transaction unlinked.", 1)>
			<cftransaction action="commit">
		<cfcatch>
			<cftransaction action="rollback">
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn #theResult#>
</cffunction>

<!---
Function getPublicationsHtml. Render the Publications section (project_publication) as an
HTML fragment: existing publications with a Remove button, followed by an add-publication
row using the existing publication picker.
--->
<cffunction name="getPublicationsHtml" access="remote" returntype="string" returnformat="plain">
	<cfargument name="project_id" type="string" required="yes">
	<cfthread name="publicationsThread">
		<cfoutput>
			<cftry>
				<cfquery name="pubs" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="pubs_result">
					SELECT
						formatted_publication.publication_id,
						formatted_publication
					FROM
						project_publication
						JOIN formatted_publication ON project_publication.publication_id = formatted_publication.publication_id
					WHERE
						format_style = 'long' AND
						project_publication.project_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#project_id#">
					ORDER BY
						formatted_publication
				</cfquery>
				<cfif pubs.recordcount EQ 0>
					<p>None.</p>
				<cfelse>
					<ul class="list-group mb-2">
						<cfloop query="pubs">
							<li class="list-group-item">
								#encodeForHtml(formatted_publication)#
								<a href="/publications/showPublication.cfm?publication_id=#publication_id#">Details</a>
								<button type="button" class="btn btn-xs btn-warning float-right" onclick="removeProjectPublication(#project_id#,#publication_id#);">Remove</button>
							</li>
						</cfloop>
					</ul>
				</cfif>
				<div class="form-row align-items-end">
					<div class="col-12 col-md-8">
						<label class="data-entry-label mb-0" for="new_publication">Add Publication</label>
						<input type="text" id="new_publication" class="data-entry-input">
						<input type="hidden" id="new_publication_id">
					</div>
					<div class="col-12 col-md-2">
						<button type="button" class="btn btn-xs btn-secondary" onclick="addProjectPublication(#project_id#);">Add</button>
					</div>
				</div>
				<script>
					$(document).ready(function () {
						makePublicationAutocompleteMeta("new_publication", "new_publication_id");
					});
				</script>
			<cfcatch>
				<p class="text-danger">Error: #cfcatch.message#</p>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="publicationsThread" />
	<cfreturn publicationsThread.output>
</cffunction>

<!---
Function addProjectPublication. Link a publication to a project.
--->
<cffunction name="addProjectPublication" access="remote" returntype="any" returnformat="json">
	<cfargument name="project_id" type="string" required="yes">
	<cfargument name="publication_id" type="string" required="yes">

	<cfset requireManageProjects()>
	<cfset theResult = queryNew("status, message")>
	<cftransaction>
		<cftry>
			<cfif len(arguments.publication_id) EQ 0>
				<cfthrow message="Unable to add publication, none selected. You must pick one from the pick list.">
			</cfif>
			<cfquery name="newPub" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="newPub_result">
				INSERT INTO project_publication (
					PROJECT_ID,
					PUBLICATION_ID
				) VALUES (
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.project_id#">,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.publication_id#">
				)
			</cfquery>
			<cfset t = queryaddrow(theResult,1)>
			<cfset t = QuerySetCell(theResult, "status", "1", 1)>
			<cfset t = QuerySetCell(theResult, "message", "Publication added.", 1)>
			<cftransaction action="commit">
		<cfcatch>
			<cftransaction action="rollback">
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn #theResult#>
</cffunction>

<!---
Function removeProjectPublication. Unlink a publication from a project.
--->
<cffunction name="removeProjectPublication" access="remote" returntype="any" returnformat="json">
	<cfargument name="project_id" type="string" required="yes">
	<cfargument name="publication_id" type="string" required="yes">

	<cfset requireManageProjects()>
	<cfset theResult = queryNew("status, message")>
	<cftransaction>
		<cftry>
			<cfquery name="delPub" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="delPub_result">
				DELETE FROM project_publication
				WHERE
					project_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.project_id#">
					AND publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.publication_id#">
			</cfquery>
			<cfset t = queryaddrow(theResult,1)>
			<cfset t = QuerySetCell(theResult, "status", "1", 1)>
			<cfset t = QuerySetCell(theResult, "message", "Publication removed.", 1)>
			<cftransaction action="commit">
		<cfcatch>
			<cftransaction action="rollback">
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn #theResult#>
</cffunction>

<!---
Function getTaxonomyHtml. Render the Taxonomy section (project_taxonomy) as an HTML
fragment: existing taxa with a Remove button, followed by an add-taxon row using a
scientific-name picker.
--->
<cffunction name="getTaxonomyHtml" access="remote" returntype="string" returnformat="plain">
	<cfargument name="project_id" type="string" required="yes">
	<cfthread name="taxonomyThread">
		<cfoutput>
			<cftry>
				<cfquery name="taxa" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="taxa_result">
					SELECT
						taxonomy.taxon_name_id,
						scientific_name
					FROM
						project_taxonomy
						JOIN taxonomy ON project_taxonomy.taxon_name_id = taxonomy.taxon_name_id
					WHERE
						project_taxonomy.project_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#project_id#">
					ORDER BY
						scientific_name
				</cfquery>
				<cfif taxa.recordcount EQ 0>
					<p>None.</p>
				<cfelse>
					<ul class="list-group mb-2">
						<cfloop query="taxa">
							<li class="list-group-item">
								<a href="/name/#EncodeForURL(scientific_name)#">#encodeForHtml(scientific_name)#</a>
								<button type="button" class="btn btn-xs btn-warning float-right" onclick="removeProjectTaxon(#project_id#,#taxon_name_id#);">Remove</button>
							</li>
						</cfloop>
					</ul>
				</cfif>
				<div class="form-row align-items-end">
					<div class="col-12 col-md-8">
						<label class="data-entry-label mb-0" for="new_taxon_name">Add Taxon</label>
						<input type="text" id="new_taxon_name" class="data-entry-input">
						<input type="hidden" id="new_taxon_name_id">
					</div>
					<div class="col-12 col-md-2">
						<button type="button" class="btn btn-xs btn-secondary" onclick="addProjectTaxon(#project_id#);">Add</button>
					</div>
				</div>
				<script>
					$(document).ready(function () {
						makeScientificNameAutocompleteMeta("new_taxon_name", "new_taxon_name_id");
					});
				</script>
			<cfcatch>
				<p class="text-danger">Error: #cfcatch.message#</p>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="taxonomyThread" />
	<cfreturn taxonomyThread.output>
</cffunction>

<!---
Function addProjectTaxon. Link a taxon to a project.
--->
<cffunction name="addProjectTaxon" access="remote" returntype="any" returnformat="json">
	<cfargument name="project_id" type="string" required="yes">
	<cfargument name="taxon_name_id" type="string" required="yes">

	<cfset requireManageProjects()>
	<cfset theResult = queryNew("status, message")>
	<cftransaction>
		<cftry>
			<cfif len(arguments.taxon_name_id) EQ 0>
				<cfthrow message="Unable to add taxon, none selected. You must pick one from the pick list.">
			</cfif>
			<cfquery name="newTaxon" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="newTaxon_result">
				INSERT INTO project_taxonomy (
					PROJECT_ID,
					TAXON_NAME_ID
				) VALUES (
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.project_id#">,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.taxon_name_id#">
				)
			</cfquery>
			<cfset t = queryaddrow(theResult,1)>
			<cfset t = QuerySetCell(theResult, "status", "1", 1)>
			<cfset t = QuerySetCell(theResult, "message", "Taxon added.", 1)>
			<cftransaction action="commit">
		<cfcatch>
			<cftransaction action="rollback">
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn #theResult#>
</cffunction>

<!---
Function removeProjectTaxon. Unlink a taxon from a project.
--->
<cffunction name="removeProjectTaxon" access="remote" returntype="any" returnformat="json">
	<cfargument name="project_id" type="string" required="yes">
	<cfargument name="taxon_name_id" type="string" required="yes">

	<cfset requireManageProjects()>
	<cfset theResult = queryNew("status, message")>
	<cftransaction>
		<cftry>
			<cfquery name="delTaxon" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="delTaxon_result">
				DELETE FROM project_taxonomy
				WHERE
					project_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.project_id#">
					AND taxon_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.taxon_name_id#">
			</cfquery>
			<cfset t = queryaddrow(theResult,1)>
			<cfset t = QuerySetCell(theResult, "status", "1", 1)>
			<cfset t = QuerySetCell(theResult, "message", "Taxon removed.", 1)>
			<cftransaction action="commit">
		<cfcatch>
			<cftransaction action="rollback">
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn #theResult#>
</cffunction>

</cfcomponent>
