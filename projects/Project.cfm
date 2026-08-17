<!---
projects/Project.cfm

Copyright 2026 President and Fellows of Harvard College

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
<!---
Create/edit page for a project. "makeNew" (default) shows a bare create form; "create"
handles its POST and redirects to "edit"; "edit" is the full page.
--->
<cfparam name="url.action" default="">
<cfparam name="form.action" default="">
<cfparam name="url.project_id" default="">
<cfparam name="form.project_id" default="">

<cfset variables.project_id = url.project_id>
<cfif len(form.project_id) GT 0><cfset variables.project_id = form.project_id></cfif>

<cfset variables.action = url.action>
<cfif len(form.action) GT 0><cfset variables.action = form.action></cfif>
<cfif len(variables.action) EQ 0>
	<cfif len(variables.project_id) GT 0>
		<cfset variables.action = "edit">
	<cfelse>
		<cfset variables.action = "makeNew">
	</cfif>
</cfif>

<cfset pageTitle = "Edit Project">
<cfif variables.action EQ "makeNew">
	<cfset pageTitle = "New Project">
</cfif>

<cfinclude template = "/shared/_header.cfm">
<cfinclude template="/projects/component/functions.cfc" runOnce="true">

<cfif NOT (isdefined("session.roles") AND listfindnocase(session.roles,"manage_projects"))>
	<main class="container py-3" id="content">
		<cfinclude template="/errors/403.cfm">
	</main>
	<cfinclude template = "/shared/_footer.cfm">
	<cfabort>
</cfif>

<script src="/projects/js/projects.js"></script>

<cfif variables.action EQ "create">
	<cfparam name="form.project_name" default="">
	<cfparam name="form.start_date" default="">
	<cfparam name="form.end_date" default="">
	<cfparam name="form.project_description" default="">
	<cfparam name="form.project_remarks" default="">
	<cfparam name="form.mask_project_fg" default="0">
	<cfquery name="nextId" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		SELECT sq_project_id.nextval AS nextid FROM dual
	</cfquery>
	<cfquery name="newProj" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="newProj_result">
		INSERT INTO project (
			PROJECT_ID,
			PROJECT_NAME,
			MASK_PROJECT_FG
			<cfif len(form.start_date) GT 0>,START_DATE</cfif>
			<cfif len(form.end_date) GT 0>,END_DATE</cfif>
			<cfif len(form.project_description) GT 0>,PROJECT_DESCRIPTION</cfif>
			<cfif len(form.project_remarks) GT 0>,PROJECT_REMARKS</cfif>
		) VALUES (
			<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#nextId.nextid#">,
			<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.project_name#">,
			<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#form.mask_project_fg#">
			<cfif len(form.start_date) GT 0>,<cfqueryparam cfsqltype="CF_SQL_TIMESTAMP" value="#form.start_date#"></cfif>
			<cfif len(form.end_date) GT 0>,<cfqueryparam cfsqltype="CF_SQL_TIMESTAMP" value="#form.end_date#"></cfif>
			<cfif len(form.project_description) GT 0>,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.project_description#"></cfif>
			<cfif len(form.project_remarks) GT 0>,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.project_remarks#"></cfif>
		)
	</cfquery>
	<cflocation url="/projects/Project.cfm?action=edit&project_id=#nextId.nextid#" addtoken="false">

<cfelseif variables.action EQ "delete">
	<cfif len(variables.project_id) EQ 0 OR NOT isnumeric(variables.project_id)>
		<cfthrow message="No project_id provided.">
	</cfif>
	<main class="container py-3" id="content">
		<cftry>
			<cfquery name="isAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT agent_name_id FROM project_agent WHERE project_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.project_id#">
			</cfquery>
			<cfquery name="isTrans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT project_id FROM project_trans WHERE project_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.project_id#">
			</cfquery>
			<cfquery name="isPub" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT project_id FROM project_publication WHERE project_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.project_id#">
			</cfquery>
			<cfif isAgent.recordcount GT 0 OR isTrans.recordcount GT 0 OR isPub.recordcount GT 0>
				<cfoutput>
					<h1 class="h2">Unable to Delete Project</h1>
					<p>This project still has
						<cfif isAgent.recordcount GT 0>agents<cfif isTrans.recordcount GT 0 OR isPub.recordcount GT 0>, </cfif></cfif>
						<cfif isTrans.recordcount GT 0>linked transactions<cfif isPub.recordcount GT 0>, </cfif></cfif>
						<cfif isPub.recordcount GT 0>publications</cfif>
						linked to it. Remove those first, then delete the project.</p>
					<a class="btn btn-xs btn-secondary" href="/projects/Project.cfm?action=edit&project_id=#variables.project_id#">Back to Edit Project</a>
				</cfoutput>
			<cfelse>
				<cfquery name="killProj" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="killProj_result">
					DELETE FROM project WHERE project_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.project_id#">
				</cfquery>
				<cflocation url="/Projects.cfm" addtoken="false">
			</cfif>
		<cfcatch>
			<cfinclude template="/errors/404.cfm">
			<cfabort>
		</cfcatch>
		</cftry>
	</main>

<cfelseif variables.action EQ "edit">
	<cftry>
		<cfif len(variables.project_id) EQ 0 OR NOT isnumeric(variables.project_id)>
			<cfthrow message="No project_id provided.">
		</cfif>
		<cfquery name="getProject" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getProject_result">
			SELECT
				project_id,
				project_name,
				TO_CHAR(start_date,'YYYY-MM-DD') AS start_date,
				TO_CHAR(end_date,'YYYY-MM-DD') AS end_date,
				project_description,
				project_remarks,
				mask_project_fg
			FROM
				project
			WHERE
				project_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.project_id#">
		</cfquery>
		<cfif getProject.recordcount EQ 0>
			<cfthrow message="No project found for the given project_id.">
		</cfif>
	<cfcatch>
		<cfinclude template="/errors/404.cfm">
		<cfabort>
	</cfcatch>
	</cftry>

	<!--- the Delete button is only offered when nothing is linked to the project, matching
	      the "delete" action's own blocking rule below --->
	<cfquery name="checkRelated" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="checkRelated_result">
		SELECT project_id FROM project_agent WHERE project_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.project_id#">
		UNION ALL
		SELECT project_id FROM project_sponsor WHERE project_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.project_id#">
		UNION ALL
		SELECT project_id FROM project_trans WHERE project_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.project_id#">
		UNION ALL
		SELECT project_id FROM project_publication WHERE project_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.project_id#">
		UNION ALL
		SELECT project_id FROM project_taxonomy WHERE project_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.project_id#">
	</cfquery>
	<cfset variables.showDeleteButton = false>
	<cfif checkRelated.recordcount EQ 0>
		<cfset variables.showDeleteButton = true>
	</cfif>

	<main class="container py-3" id="content">
		<cfoutput>
		<section class="row border rounded my-2">
			<div class="col-12 pb-3">
				<div class="d-flex align-items-start justify-content-between flex-wrap">
					<div>
						<h1 class="h2 mt-3">Edit Project: <span id="projectNameHeading">#encodeForHtml(getProject.project_name)#</span></h1>
					</div>
					<div class="mt-2 ml-2 flex-shrink-0">
						<a class="btn btn-xs btn-info" href="/projects/showProject.cfm?project_id=#getProject.project_id#">View Details Page</a>
					</div>
				</div>
				<form id="projectForm" name="projectForm" action="/projects/Project.cfm" method="post">
					<input type="hidden" name="action" id="action" value="save">
					<input type="hidden" name="method" value="saveProject">
					<input type="hidden" name="project_id" id="project_id" value="#getProject.project_id#">
					<div class="form-row">
						<div class="col-12 col-md-6">
							<label for="project_name" class="data-entry-label">Project Title</label>
							<textarea name="project_name" id="project_name" class="data-entry-input" rows="2" required>#encodeForHtml(getProject.project_name)#</textarea>
						</div>
						<div class="col-6 col-md-3">
							<label for="start_date" class="data-entry-label">Start Date</label>
							<input type="text" name="start_date" id="start_date" class="data-entry-input" value="#getProject.start_date#" placeholder="yyyy-mm-dd">
						</div>
						<div class="col-6 col-md-3">
							<label for="end_date" class="data-entry-label">End Date</label>
							<input type="text" name="end_date" id="end_date" class="data-entry-input" value="#getProject.end_date#" placeholder="yyyy-mm-dd">
						</div>
					</div>
					<div class="form-row">
						<div class="col-12 col-md-6">
							<label for="project_description" class="data-entry-label">Description</label>
							<textarea name="project_description" id="project_description" class="data-entry-input" rows="5">#encodeForHtml(getProject.project_description)#</textarea>
						</div>
						<div class="col-12 col-md-6">
							<label for="project_remarks" class="data-entry-label">Remarks</label>
							<textarea name="project_remarks" id="project_remarks" class="data-entry-input" rows="5">#encodeForHtml(getProject.project_remarks)#</textarea>
						</div>
					</div>
					<div class="form-row">
						<div class="col-12 col-md-3">
							<label for="mask_project_fg" class="data-entry-label">Visibility</label>
							<cfset selected0 = "">
							<cfset selected1 = "">
							<cfif getProject.mask_project_fg EQ 1><cfset selected1 = "selected"><cfelse><cfset selected0 = "selected"></cfif>
							<select name="mask_project_fg" id="mask_project_fg" class="data-entry-select">
								<option value="0" #selected0#>Public</option>
								<option value="1" #selected1#>Hidden</option>
							</select>
						</div>
					</div>
					<div class="form-row mt-2">
						<div class="col-12">
							<input type="button" value="Save" class="btn btn-xs btn-primary"
								onclick="if (checkFormValidity($('##projectForm')[0])) { saveEdits(); }">
							<cfif variables.showDeleteButton>
								<input type="button" value="Delete Project" class="btn btn-xs btn-danger"
									onclick="confirmDialog('Delete this project?','Confirm Delete Project', function() { $('##action').val('delete'); $('##projectForm').submit(); });">
							</cfif>
							<output id="saveResultDiv"></output>
						</div>
					</div>
				</form>
			</div>
		</section>

		<section class="row">
			<div class="col-12 mt-3 mb-4 border rounded px-2 pb-2">
				<h2 class="h3">Agents</h2>
				<div id="agentsDiv">#getAgentsHtml(project_id="#getProject.project_id#")#</div>
			</div>
		</section>

		<section class="row">
			<div class="col-12 mt-3 mb-4 border rounded px-2 pb-2">
				<h2 class="h3">Sponsors</h2>
				<div id="sponsorsDiv">#getSponsorsHtml(project_id="#getProject.project_id#")#</div>
			</div>
		</section>

		<section class="row">
			<div class="col-12 mt-3 mb-4 border rounded px-2 pb-2">
				<h2 class="h3">Loans</h2>
				<div id="loansDiv">#getLoansHtml(project_id="#getProject.project_id#")#</div>
			</div>
		</section>

		<section class="row">
			<div class="col-12 mt-3 mb-4 border rounded px-2 pb-2">
				<h2 class="h3">Accessions</h2>
				<div id="accessionsDiv">#getAccessionsHtml(project_id="#getProject.project_id#")#</div>
			</div>
		</section>

		<section class="row">
			<div class="col-12 mt-3 mb-4 border rounded px-2 pb-2">
				<h2 class="h3">Publications</h2>
				<div id="publicationsDiv">#getPublicationsHtml(project_id="#getProject.project_id#")#</div>
			</div>
		</section>

		<section class="row">
			<div class="col-12 mt-3 mb-4 border rounded px-2 pb-2">
				<h2 class="h3">Taxonomy</h2>
				<div id="taxonomyDiv">#getTaxonomyHtml(project_id="#getProject.project_id#")#</div>
			</div>
		</section>
		</cfoutput>
	</main>

	<script>
		$(document).ready(function () {
			monitorForChangesGeneric('projectForm', handleChange);
			$('#start_date').datepicker({ dateFormat: 'yy-mm-dd' });
			$('#end_date').datepicker({ dateFormat: 'yy-mm-dd' });
		});
	</script>

<cfelse>
	<main class="container py-3" id="content">
		<cfoutput>
		<section class="row border rounded my-2">
			<div class="col-12">
				<h1 class="h2 mt-3">Create New Project</h1>
				<form id="projectForm" name="projectForm" action="/projects/Project.cfm" method="post">
					<input type="hidden" name="action" value="create">
					<div class="form-row">
						<div class="col-12 col-md-6">
							<label for="project_name" class="data-entry-label">Project Title</label>
							<textarea name="project_name" id="project_name" class="data-entry-input" rows="2" required></textarea>
						</div>
						<div class="col-6 col-md-3">
							<label for="start_date" class="data-entry-label">Start Date</label>
							<input type="text" name="start_date" id="start_date" class="data-entry-input" placeholder="yyyy-mm-dd">
						</div>
						<div class="col-6 col-md-3">
							<label for="end_date" class="data-entry-label">End Date</label>
							<input type="text" name="end_date" id="end_date" class="data-entry-input" placeholder="yyyy-mm-dd">
						</div>
					</div>
					<div class="form-row">
						<div class="col-12 col-md-6">
							<label for="project_description" class="data-entry-label">Description</label>
							<textarea name="project_description" id="project_description" class="data-entry-input" rows="5"></textarea>
						</div>
						<div class="col-12 col-md-6">
							<label for="project_remarks" class="data-entry-label">Remarks</label>
							<textarea name="project_remarks" id="project_remarks" class="data-entry-input" rows="5"></textarea>
						</div>
					</div>
					<div class="form-row">
						<div class="col-12 col-md-3">
							<label for="mask_project_fg" class="data-entry-label">Visibility</label>
							<select name="mask_project_fg" id="mask_project_fg" class="data-entry-select">
								<option value="0" selected>Public</option>
								<option value="1">Hidden</option>
							</select>
						</div>
					</div>
					<div class="form-row mt-2">
						<div class="col-12">
							<input type="submit" value="Create Project" class="btn btn-xs btn-primary">
						</div>
					</div>
					<p class="mt-2 text-secondary">You can add Agents, Sponsors, Loans, Accessions, Publications, and Taxonomy after creating the project.</p>
				</form>
			</div>
		</section>
		</cfoutput>
	</main>

	<script>
		$(document).ready(function () {
			$('#start_date').datepicker({ dateFormat: 'yy-mm-dd' });
			$('#end_date').datepicker({ dateFormat: 'yy-mm-dd' });
		});
	</script>

</cfif>

<cfinclude template = "/shared/_footer.cfm">
