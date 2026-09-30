<!---
/Projects.cfm

Projects search/results 

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
Search-with-results page for Projects.
--->
<cfset pageTitle = "Search Projects">
<cfset action = "search">

<cfparam name="url.p_title" default="">
<cfparam name="url.participant_agent_id" default="">
<cfparam name="url.participant_agent_name" default="">
<cfparam name="url.sponsor_agent_id" default="">
<cfparam name="url.sponsor_agent_name" default="">
<cfparam name="url.transaction_agent_id" default="">
<cfparam name="url.transaction_agent_name" default="">
<cfparam name="url.project_type" default="">
<cfparam name="url.year" default="">
<cfparam name="url.start_year" default="">
<cfparam name="url.end_year" default="">
<cfparam name="url.descr_len" default="">
<cfparam name="url.project_description" default="">
<cfparam name="url.project_remarks" default="">
<cfparam name="url.mask_project_fg" default="">
<cfparam name="url.publication_id" default="">
<cfparam name="url.guid" default="">
<cfparam name="url.collection_object_id" default="">
<cfparam name="url.loan_number" default="">
<cfparam name="url.accn_number" default="">
<cfparam name="url.accn_transaction_id" default="">
<cfparam name="url.project_id" default="">
<cfparam name="url.execute" default="">

<cfset variables.p_title = url.p_title>
<cfset variables.participant_agent_id = url.participant_agent_id>
<cfset variables.participant_agent_name = url.participant_agent_name>
<cfset variables.sponsor_agent_id = url.sponsor_agent_id>
<cfset variables.sponsor_agent_name = url.sponsor_agent_name>
<cfset variables.transaction_agent_id = url.transaction_agent_id>
<cfset variables.transaction_agent_name = url.transaction_agent_name>
<cfset variables.project_type = url.project_type>
<cfset variables.year = url.year>
<cfset variables.start_year = url.start_year>
<cfset variables.end_year = url.end_year>
<cfset variables.descr_len = url.descr_len>
<cfset variables.project_description = url.project_description>
<cfset variables.project_remarks = url.project_remarks>
<cfset variables.mask_project_fg = url.mask_project_fg>
<cfset variables.publication_id = url.publication_id>
<cfset variables.guid = url.guid>
<cfset variables.collection_object_id = url.collection_object_id>
<cfset variables.loan_number = url.loan_number>
<cfset variables.accn_number = url.accn_number>
<cfset variables.accn_transaction_id = url.accn_transaction_id>
<cfset variables.project_id = url.project_id>

<cfinclude template = "/shared/_header.cfm">

<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
	<cfset oneOfUs = 1>
<cfelse>
	<cfset oneOfUs = 0>
</cfif>

<cfset canManageProjects = false>
<cfif oneOfUs EQ 1 and listfindnocase(session.roles,"manage_projects")>
	<cfset canManageProjects = true>
</cfif>

<cfset canManageTransactions = false>
<cfif oneOfUs EQ 1 and listfindnocase(session.roles,"manage_transactions")>
	<cfset canManageTransactions = true>
</cfif>

<cfset canManageProjectsJs = "false">
<cfif canManageProjects>
	<cfset canManageProjectsJs = "true">
</cfif>

<cfset oneOfUsJs = "false">
<cfif oneOfUs EQ 1>
	<cfset oneOfUsJs = "true">
</cfif>

<!--- cf_grid_properties.username is NOT NULL, and Oracle reads an empty string as NULL.
      A session can hold coldfusion_user with an empty session.username, so the saved
      column choices are gated on the username itself, as Specimens.cfm and Agents.cfm do,
      not on oneOfUs. --->
<cfset canSaveGridPropertiesJs = "false">
<cfif isdefined("session.username") and len(session.username) GT 0>
	<cfset canSaveGridPropertiesJs = "true">
</cfif>

<!--- Min. Len. and Accession are curator-only; the field to the left of each takes
      the vacated space so a public user gets no gap in the row. --->
<cfset descrWidth = 5>
<cfset guidWidth = 6>
<cfif oneOfUs NEQ 1>
	<cfset descrWidth = 7>
	<cfset guidWidth = 12>
</cfif>

<!---
GET-param API: an agent id alone (no name) must still populate the search box with that
agent's name, so a "link to this search" URL that only carries the id (as this page's own
links do) redisplays correctly.
--->
<cfif len(variables.participant_agent_id) GT 0 AND isnumeric(variables.participant_agent_id) AND len(variables.participant_agent_name) EQ 0>
	<cfquery name="getParticipantAgentName" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		SELECT
			agent_name.agent_name
		FROM
			agent
			JOIN agent_name ON agent.preferred_agent_name_id = agent_name.agent_name_id
		WHERE
			agent.agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.participant_agent_id#">
	</cfquery>
	<cfif getParticipantAgentName.recordcount GT 0>
		<cfset variables.participant_agent_name = getParticipantAgentName.agent_name>
	</cfif>
</cfif>

<cfif len(variables.sponsor_agent_id) GT 0 AND isnumeric(variables.sponsor_agent_id) AND len(variables.sponsor_agent_name) EQ 0>
	<cfquery name="getSponsorAgentName" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		SELECT
			agent_name.agent_name
		FROM
			agent
			JOIN agent_name ON agent.preferred_agent_name_id = agent_name.agent_name_id
		WHERE
			agent.agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.sponsor_agent_id#">
	</cfquery>
	<cfif getSponsorAgentName.recordcount GT 0>
		<cfset variables.sponsor_agent_name = getSponsorAgentName.agent_name>
	</cfif>
</cfif>

<cfif len(variables.transaction_agent_id) GT 0 AND isnumeric(variables.transaction_agent_id) AND len(variables.transaction_agent_name) EQ 0>
	<cfquery name="getTransactionAgentName" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		SELECT
			agent_name.agent_name
		FROM
			agent
			JOIN agent_name ON agent.preferred_agent_name_id = agent_name.agent_name_id
		WHERE
			agent.agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.transaction_agent_id#">
	</cfquery>
	<cfif getTransactionAgentName.recordcount GT 0>
		<cfset variables.transaction_agent_name = getTransactionAgentName.agent_name>
	</cfif>
</cfif>

<cfif len(variables.collection_object_id) GT 0 AND isnumeric(variables.collection_object_id) AND len(variables.guid) EQ 0>
	<cfquery name="getGuid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		SELECT
			guid
		FROM
			<cfif ucase(session.flatTableName) EQ "FLAT">FLAT<cfelse>FILTERED_FLAT</cfif>
		WHERE
			collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.collection_object_id#">
	</cfquery>
	<cfif getGuid.recordcount GT 0>
		<cfset variables.guid = getGuid.guid>
	</cfif>
</cfif>

<cfif len(variables.accn_transaction_id) GT 0 AND isnumeric(variables.accn_transaction_id) AND len(variables.accn_number) EQ 0>
	<cfquery name="getAccnNumber" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		SELECT
			accn_number
		FROM
			accn
		WHERE
			transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.accn_transaction_id#">
	</cfquery>
	<cfif getAccnNumber.recordcount GT 0>
		<cfset variables.accn_number = getAccnNumber.accn_number>
	</cfif>
</cfif>

<cfquery name="getCount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	SELECT
		COUNT(*) AS cnt
	FROM
		project
	WHERE
		project.project_id IS NOT NULL
		<cfif oneOfUs NEQ 1>
			AND project.mask_project_fg = 0
		</cfif>
</cfquery>

<link rel="stylesheet" href="/lib/Tabulator/tabulator_ver6.5.2/css/tabulator_bootstrap4.min.css">
<link rel="stylesheet" href="/shared/css/tabulator_overrides.css">
<!---
Results-toolbar layout, scoped to .mcz-results-toolbar. Inline rather than in
shared/css/ -- a styleguide deviation -- while the arrangement is still being settled on
this pilot page; move to tabulator_overrides.css, keeping the scope, once it is. Control
heights are not here: see .mcz-app-controls in bootstrap_override.css.
--->
<style>
	/* Controls that belong together sit in a .mcz-toolbar-group, and a thin rule marks
	   where one group ends and the next begins -- whitespace alone left "Selected rows
	   only" reading as part of "Grid Select:". The first group needs no rule; the bar's
	   own edge does that. rgba, not a hex colour, so this block stays free of "#", which
	   ColdFusion would try to evaluate if it ever moved inside a cfoutput. */
	.mcz-results-toolbar .mcz-toolbar-group {
		display: inline-flex;
		align-items: center;
		flex-wrap: wrap;
	}

	/* row-gap applies between wrapped flex lines and nowhere else, so controls that fall
	   to a second line get space to be clicked while a single-line bar stays tight. */
	.mcz-results-toolbar .d-flex,
	.mcz-results-toolbar .mcz-toolbar-group {
		row-gap: .35rem;
	}

	.mcz-results-toolbar .mcz-toolbar-group + .mcz-toolbar-group {
		margin-left: .5rem;
		padding-left: .75rem;
		border-left: 1px solid rgba(0, 0, 0, .18);
	}

	/* Below xl (Bootstrap's 1200px), give each group its own full-width line, so the row
	   controls start at the left edge instead of trailing the column controls mid-line.
	   Bootstrap 4 has no responsive width utility to do this with -- w-md-* and w-xl-*
	   arrived in Bootstrap 5 -- which is why it is a media query here. The dividing rule
	   goes with it: a left border separates neighbours, not stacked rows. */
	@media (max-width: 1199.98px) {
		.mcz-results-toolbar .mcz-toolbar-group {
			flex: 0 0 100%;
		}

		.mcz-results-toolbar .mcz-toolbar-group + .mcz-toolbar-group {
			margin-left: 0;
			padding-left: 0;
			border-left: 0;
		}
	}
</style>
<script src="/lib/Tabulator/tabulator_ver6.5.2/js/tabulator.min.js"></script>
<script src="/projects/js/projects.js"></script>

<!--- mcz-app-controls: one height and text size for every input, select and .btn-xs on
      this page. See bootstrap_override.css. --->
<div id="overlaycontainer" class="mcz-app-controls" style="position: relative;">
	<main id="content">
		<section class="container-fluid" role="search">
			<cftry>
				<cfoutput>#renderWikiButtons(buttonClass="btn btn-xs btn-dark help-btnSp-SearchWiki btnSp-shim mr-4 border-0")#</cfoutput>
				<cfcatch><cfoutput>Error calling renderWikiButtons: #cfcatch.message#</cfoutput></cfcatch>
			</cftry>
			<div class="d-flex flex-wrap mb-3 mx-0 mr-md-3 mr-xl-4 ml-xl-3">
				<div class="search-box mt-4">
					<div class="search-box-header">
						<cfoutput>
							<h1 class="h3 text-white" tabindex="0">Search Projects <span class="count font-italic text-grayish mx-0"><small>(#getCount.cnt# records)</small></span></h1>
						</cfoutput>
					</div>
					<div id="searchFormDiv">
						<cfoutput>
						<form name="searchForm" id="searchForm">
							<input type="hidden" name="method" value="search" class="keeponclear">
							<input type="hidden" name="publication_id" id="publication_id" value="#encodeForHtml(variables.publication_id)#" class="excludeFromLink">
							<input type="hidden" name="project_id" id="project_id" value="#encodeForHtml(variables.project_id)#" class="excludeFromLink">
							<div class="col-12 px-2">
								<!--- Three columns from xl up. Project needs half the width for its six fields,
								      Agents' three pickers take a name fragment in a narrow one, and Related needs
								      four units to fit the longest Nature of Contributions option. At md Project
								      takes the full row with Agents and Related side by side beneath it; all three
								      stack below that. --->
								<div class="form-row">
									<div class="col-12 col-xl-6 d-flex">
										<fieldset class="bg-light border-default field-set rounded flex-fill px-2 pt-1 pb-2 mt-2 mx-2 mr-xl-0">
											<legend class="h6 mb-0 px-3 border-default field-set-legend py-0 w-auto bg-teal font-weight-lessbold">Project</legend>
											<div class="form-row">
												<div class="col-12 col-md-5">
													<label for="p_title" class="data-entry-label">Title</label>
													<input type="text" id="p_title" name="p_title" class="data-entry-input" value="#encodeForHtml(variables.p_title)#">
													<script>
														$(document).ready(function () {
															makeProjectTitleSearchAutocomplete("p_title");
														});
													</script>
												</div>
												<div class="col-12 col-md-#descrWidth#">
													<label for="project_description" class="data-entry-label">Description</label>
													<input type="text" id="project_description" name="project_description" class="data-entry-input" value="#encodeForHtml(variables.project_description)#">
												</div>
												<cfif oneOfUs EQ 1>
													<div class="col-12 col-md-2">
														<label for="descr_len" class="data-entry-label">Min. Len.</label>
														<input type="text" id="descr_len" name="descr_len" class="data-entry-input" value="#encodeForHtml(variables.descr_len)#">
													</div>
												</cfif>
												<!--- One group, so the grid cannot separate the two ends of the range. "Active in
												      Year" was removed from here: it asked whether a project was running in a given
												      year, which is the same question as a range whose two ends are that year, so
												      the range subsumes it. Its BETWEEN was also broken -- see the year clauses in
												      projects/component/search.cfc. The year argument is still accepted there, so
												      saved searches carrying it keep working. --->
												<div class="col-12">
													<div class="d-flex align-items-end">
														<span class="flex-fill">
															<label for="start_year" class="data-entry-label mb-0">Start Year</label>
															<input type="text" id="start_year" name="start_year" class="data-entry-input" value="#encodeForHtml(variables.start_year)#">
														</span>
														<span class="text-secondary px-1 pb-1">&ndash;</span>
														<span class="flex-fill">
															<label for="end_year" class="data-entry-label d-inline w-auto mb-0">End Year</label>
															<span class="text-secondary small">(</span><button type="button" class="rules bg-transparent" onclick="var e=document.getElementById('end_year');e.value='NULL';" aria-label="set end year to NULL to find active projects with no end date">Active</button>, <button type="button" class="rules bg-transparent" onclick="var e=document.getElementById('end_year');e.value='NOT NULL';" aria-label="set end year to NOT NULL to find finished projects with a defined end date">Finished</button><span class="text-secondary small">)</span>
															<input type="text" id="end_year" name="end_year" class="data-entry-input" value="#encodeForHtml(variables.end_year)#">
														</span>
													</div>
												</div>
												<cfif oneOfUs EQ 1>
													<div class="col-12 col-md-9">
														<label for="project_remarks" class="data-entry-label">Remarks</label>
														<input type="text" id="project_remarks" name="project_remarks" class="data-entry-input" value="#encodeForHtml(variables.project_remarks)#">
													</div>
													<div class="col-12 col-md-3">
														<label for="mask_project_fg" class="data-entry-label">Visibility</label>
														<cfset selected = "">
														<cfif variables.mask_project_fg EQ ""><cfset selected = "selected"></cfif>
														<select id="mask_project_fg" name="mask_project_fg" class="data-entry-select">
															<option value="" #selected#></option>
															<cfset selected = "">
															<cfif variables.mask_project_fg EQ "0"><cfset selected = "selected"></cfif>
															<option value="0" #selected#>Public</option>
															<cfset selected = "">
															<cfif variables.mask_project_fg EQ "1"><cfset selected = "selected"></cfif>
															<option value="1" #selected#>Hidden</option>
														</select>
													</div>
												</cfif>
											</div>
										</fieldset>
									</div>
									<div class="col-12 col-md-6 col-xl-2 d-flex">
										<fieldset class="bg-light border-default field-set rounded flex-fill px-2 pt-1 pb-2 mt-2 mx-2 mr-md-0 ml-xl-0">
											<legend class="h6 mb-0 px-3 border-default field-set-legend py-0 w-auto bg-teal font-weight-lessbold">Agents</legend>
											<div class="form-row">
												<div class="col-12">
													<div class="form-row mx-0 my-0 py-0">
														<label for="participant_agent_name" id="participant_agent_name_label" class="data-entry-label mb-0 pb-0">Participant
															<span id="participant_agent_view" class="ml-2"></span>
														</label>
														<div class="input-group">
															<div class="input-group-prepend">
																<span class="input-group-text smaller bg-lightgreen" id="participant_agent_name_icon"><i class="fa fa-user" aria-hidden="true"></i></span>
															</div>
															<input type="text" name="participant_agent_name" id="participant_agent_name" class="form-control rounded-right data-entry-input form-control-sm" aria-label="Participant agent name" value="#encodeForHtml(variables.participant_agent_name)#">
															<input type="hidden" name="participant_agent_id" id="participant_agent_id" value="#encodeForHtml(variables.participant_agent_id)#">
														</div>
													</div>
													<script>
														$(document).ready(function () {
															makeConstrainedRichAgentPickerConfig("participant_agent_name", "participant_agent_id", "participant_agent_name_icon", "participant_agent_view", "#variables.participant_agent_id#", "project_agent", false);
														});
													</script>
												</div>
												<div class="col-12">
													<div class="form-row mx-0 my-0 py-0">
														<label for="sponsor_agent_name" id="sponsor_agent_name_label" class="data-entry-label mb-0 pb-0">Sponsor
															<span id="sponsor_agent_view" class="ml-2"></span>
														</label>
														<div class="input-group">
															<div class="input-group-prepend">
																<span class="input-group-text smaller bg-lightgreen" id="sponsor_agent_name_icon"><i class="fa fa-user" aria-hidden="true"></i></span>
															</div>
															<input type="text" name="sponsor_agent_name" id="sponsor_agent_name" class="form-control rounded-right data-entry-input form-control-sm" aria-label="Sponsor agent name" value="#encodeForHtml(variables.sponsor_agent_name)#">
															<input type="hidden" name="sponsor_agent_id" id="sponsor_agent_id" value="#encodeForHtml(variables.sponsor_agent_id)#">
														</div>
													</div>
													<script>
														$(document).ready(function () {
															makeConstrainedRichAgentPickerConfig("sponsor_agent_name", "sponsor_agent_id", "sponsor_agent_name_icon", "sponsor_agent_view", "#variables.sponsor_agent_id#", "project_sponsor", false);
														});
													</script>
												</div>
												<cfif canManageTransactions>
													<div class="col-12">
														<div class="form-row mx-0 my-0 py-0">
															<label for="transaction_agent_name" id="transaction_agent_name_label" class="data-entry-label mb-0 pb-0">Transaction Agent
																<span id="transaction_agent_view" class="ml-2"></span>
															</label>
															<div class="input-group">
																<div class="input-group-prepend">
																	<span class="input-group-text smaller bg-lightgreen" id="transaction_agent_name_icon"><i class="fa fa-user" aria-hidden="true"></i></span>
																</div>
																<input type="text" name="transaction_agent_name" id="transaction_agent_name" class="form-control rounded-right data-entry-input form-control-sm" aria-label="Transaction agent name" value="#encodeForHtml(variables.transaction_agent_name)#">
																<input type="hidden" name="transaction_agent_id" id="transaction_agent_id" value="#encodeForHtml(variables.transaction_agent_id)#">
															</div>
														</div>
														<script>
															$(document).ready(function () {
																makeConstrainedRichAgentPickerConfig("transaction_agent_name", "transaction_agent_id", "transaction_agent_name_icon", "transaction_agent_view", "#variables.transaction_agent_id#", "transaction_agent", false);
															});
														</script>
													</div>
												</cfif>
											</div>
										</fieldset>
									</div>
									<div class="col-12 col-md-6 col-xl-4 d-flex">
										<fieldset class="bg-light border-default field-set rounded flex-fill px-2 pt-1 pb-2 mt-2 mx-2 ml-md-0">
											<legend class="h6 mb-0 px-3 border-default field-set-legend py-0 w-auto bg-teal font-weight-lessbold">Related</legend>
											<div class="form-row">
												<div class="col-12 col-md-#guidWidth#">
													<label for="guid" class="data-entry-label d-inline w-auto">Cataloged Item</label>
													<span class="text-secondary small">(</span><button type="button" class="rules" onclick="document.getElementById('guid').value='NULL';" aria-label="set cataloged item to NULL to find projects related to no cataloged item">None</button>, <button type="button" class="rules" onclick="document.getElementById('guid').value='NOT NULL';" aria-label="set cataloged item to NOT NULL to find projects related to any cataloged item">Any</button><span class="text-secondary small">)</span>
													<input type="text" id="guid" name="guid" class="data-entry-input" placeholder="MCZ:Coll:nnnnn" value="#encodeForHtml(variables.guid)#" onchange="document.getElementById('collection_object_id').value='';">
													<input type="hidden" id="collection_object_id" name="collection_object_id" value="#encodeForHtml(variables.collection_object_id)#">
													<script>
														$(document).ready(function () {
															makeCatalogedItemAutocompleteMeta("guid", "collection_object_id");
														});
													</script>
												</div>
												<cfif oneOfUs EQ 1>
													<div class="col-12 col-md-6">
														<label for="accn_number" class="data-entry-label d-inline w-auto">Accession</label>
														<span class="text-secondary small">(</span><button type="button" class="rules" onclick="document.getElementById('accn_number').value='NULL';" aria-label="set accession to NULL to find projects with no accession">None</button>, <button type="button" class="rules" onclick="document.getElementById('accn_number').value='NOT NULL';" aria-label="set accession to NOT NULL to find projects with any accession">Any</button><span class="text-secondary small">)</span>
														<input type="text" id="accn_number" name="accn_number" class="data-entry-input" placeholder="99999999" value="#encodeForHtml(variables.accn_number)#" onchange="document.getElementById('accn_transaction_id').value='';">
														<input type="hidden" id="accn_transaction_id" name="accn_transaction_id" value="#encodeForHtml(variables.accn_transaction_id)#">
														<script>
															$(document).ready(function () {
																makeAccessionAutocompleteMeta("accn_number", "accn_transaction_id");
															});
														</script>
													</div>
												</cfif>
												<div class="col-12">
													<label for="project_type" class="data-entry-label">Nature of Contributions</label>
													<cfset selected = "">
													<cfif variables.project_type EQ ""><cfset selected = "selected"></cfif>
													<cfset loanText = "">
													<cfset accessionText="">
													<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
														<cfset loanText = " (in loans)">
														<cfset accessionText = " (in accessions)">
													</cfif>
													<select id="project_type" name="project_type" class="data-entry-select">
														<option value="" #selected#></option>
														<cfset selected = "">
														<cfif variables.project_type EQ "loan"><cfset selected = "selected"></cfif>
														<option value="loan" #selected#>Uses Specimens#loanText#</option>
														<cfset selected = "">
														<cfif variables.project_type EQ "loan_no_pub"><cfset selected = "selected"></cfif>
														<option value="loan_no_pub" #selected#>Uses Specimens, no publication</option>
														<cfset selected = "">
														<cfif variables.project_type EQ "accn"><cfset selected = "selected"></cfif>
														<option value="accn" #selected#>Contributes Specimens#accessionText#</option>
														<cfset selected = "">
														<cfif variables.project_type EQ "both"><cfset selected = "selected"></cfif>
														<option value="both" #selected#>Uses and Contributes</option>
														<cfset selected = "">
														<cfif variables.project_type EQ "neither"><cfset selected = "selected"></cfif>
														<option value="neither" #selected#>Neither Uses nor Contributes</option>
													</select>
												</div>
												<cfif oneOfUs EQ 1>
													<div class="col-12">
														<label for="loan_number" class="data-entry-label d-inline w-auto">Loan Number</label>
														<span class="text-secondary small">(</span><button type="button" class="rules" onclick="var e=document.getElementById('loan_number');e.value='='+e.value;" title="Exact match: prefix the loan number with =" aria-label="prefix with equals sign for an exact loan number match">=</button>, <button type="button" class="rules" onclick="var e=document.getElementById('loan_number');e.value='!'+e.value;" title="Exclude: prefix the loan number with !" aria-label="prefix with exclamation point to exclude an exact loan number">!</button>, <button type="button" class="rules" onclick="document.getElementById('loan_number').value='NULL';" title="Projects with no loan" aria-label="set loan number to NULL to find projects with no loan">None</button>, <button type="button" class="rules" onclick="document.getElementById('loan_number').value='NOT NULL';" title="Projects with any loan" aria-label="set loan number to NOT NULL to find projects with any loan">Any</button><span class="text-secondary small">)</span> <input type="text" id="loan_number" name="loan_number" class="data-entry-input" placeholder="yyyy-n-Coll" value="#encodeForHtml(variables.loan_number)#">
														<script>
															$(document).ready(function () {
																makeLoanPickerSearch("loan_number");
															});
														</script>
													</div>
												</cfif>
											</div>
										</fieldset>
									</div>
								</div>
							</div>
							<div class="col-12 px-3 py-2 float-left">
								<button type="submit" class="btn btn-xs btn-primary mr-2 my-1" id="searchButton">Search<span class="fa fa-search pl-1" aria-hidden="true"></span></button>
								<button type="reset" class="btn btn-xs btn-warning mr-2 my-1">Reset</button>
								<button type="button" class="btn btn-xs btn-warning mr-2 my-1" onclick="window.location.href='#Application.serverRootUrl#/Projects.cfm';">New Search</button>
								<cfif canManageProjects>
									<button type="button" class="btn btn-xs btn-secondary my-1" onclick="window.location.href='#Application.serverRootUrl#/projects/Project.cfm?action=makeNew';">Create New Project</button>
								</cfif>
							</div>
						</form>
						</cfoutput>
					</div>
				</div>
			</div>
		</section>
		<!--- Results table as a Tabulator grid. --->
		<section class="container-fluid">
			<div class="row mx-0">
				<div class="col-12 mb-5 px-0 pr-md-3 pr-xl-4 pl-xl-3">
					<!--- Symmetric padding, with align-items-center to centre the heading and the
					      buttons on each other within it. --->
					<div class="row mt-1 mb-0 border px-2 py-1 mx-0 align-items-center mcz-results-toolbar" style="background-color:#deebec;">
						<!--- my-0: the bar's padding sets the vertical space; a margin here would add
						      height and pull the heading off the centre line. --->
						<h1 class="h4 ml-2 ml-md-1 my-0 px-2">
							<span tabindex="0">Results: </span>
							<span id="resultsMeta" style="display:none;">
								<span class="pr-2 font-weight-normal" id="resultCount"></span>
								<span id="resultLink" class="pr-2 font-weight-normal"></span>
							</span>
						</h1>
						<!--- Line one, beside the heading: the search-form toggle, Save Search and the
						      feedback Save Search writes. These belong with "Found N records" and "Link to
						      this search" rather than with the grid's own controls below. --->
						<!--- mr-md-auto absorbs the free space, so the grid's controls sit right of the
						      heading rather than crowding it. A margin utility, safe on a hide/show
						      wrapper -- unlike a display one, which would beat the inline display:none. --->
						<div id="resultsHeadingControls" class="mr-md-auto" style="display:none;">
							<!--- The flex class sits on this inner div, never on the hide/show wrapper above:
							      Bootstrap's d-flex is !important and would beat a plain inline display:none. --->
							<div class="d-flex flex-wrap align-items-center">
								<div id="showhide"></div>
								<cfif oneOfUs EQ 1>
									<button type="button" class="btn btn-xs btn-secondary mx-1" onclick="populateSaveSearchDialog(); $('#saveSearchDialog').dialog('open');">Save Search</button>
									<div id="saveSearchDialog" title="Save Search" style="display:none;"></div>
								</cfif>
								<output id="actionFeedback" class="ml-1 my-0 small text-nowrap"></output>
							</div>
						</div>
						<!--- Width left alone: the row's own flex-wrap drops these onto a second line
						      when they don't fit, and Bootstrap 4 has no responsive width utility that
						      could undo a w-100 on a wide monitor. --->
						<div id="resultsToolbarControls" style="display:none;">
							<div class="d-flex flex-wrap align-items-center">
								<!--- Columns: what the grid shows. --->
								<span class="mcz-toolbar-group">
									<button type="button" class="btn btn-xs btn-secondary mx-1" onclick="openProjectsColumnChooser('columnChooserDialog');">Select Columns</button>
									<div id="columnChooserDialog" title="Show/Hide Columns" style="display:none;">
										<div id="columnChooserList" class="px-1"></div>
									</div>
									<button type="button" class="btn btn-xs btn-secondary mx-1" onclick="togglePinProjectColumn();">Pin Project Column</button>
									<!--- Hidden until a column actually is hidden; mczRefreshShowHiddenColumnsButton
									      sets the label and reveals it. btn-warning to match Clear Column Filters,
									      the other reset-style control here. --->
									<button type="button" id="showHiddenColumnsButton" class="btn btn-xs btn-warning mx-1" style="display:none;" onclick="showAllProjectsColumns();">Show Hidden Columns</button>
									<button type="button" id="clearHeaderFiltersButton" class="btn btn-xs btn-warning mx-1" style="display:none;" onclick="clearProjectsHeaderFilters();">Clear Column Filters</button>
									<div class="d-inline-flex align-items-center flex-wrap ml-3 mr-1">
										<label for="groupByColumn" class="mb-0 mr-1 small90">Group by:</label>
										<select id="groupByColumn" class="data-entry-select d-inline w-auto" onchange="setProjectsGrouping(this.value);" aria-describedby="groupByColumnHelp"></select>
										<span id="groupByColumnHelp" class="sr-only">Grouping loads every matching row, so the counts describe the whole result set rather than one page.</span>
									</div>
								</span>
								<!--- Rows: selecting them, and getting them out. --->
								<span class="mcz-toolbar-group">
									<button type="button" class="btn btn-xs btn-secondary mx-1" onclick="exportProjects('csv', 'exportSelectedOnly', 'overlay');">Export to CSV</button>
									<button type="button" class="btn btn-xs btn-secondary mx-1" onclick="exportProjects('xlsx', 'exportSelectedOnly', 'overlay');">Export to Excel</button>
									<!--- Outer span carries the show/hide; the flex class sits on the inner one
									      (d-inline-flex is !important and would beat display:none). --->
									<span id="exportSelectedOnlyContainer" style="display:none;">
										<span class="d-inline-flex align-items-center mx-1">
											<input type="checkbox" id="exportSelectedOnly" class="mr-1">
											<label for="exportSelectedOnly" class="mb-0 small90">Selected rows only</label>
										</span>
									</span>
									<div class="d-inline-flex align-items-center flex-wrap ml-3 mr-1">
										<label for="selectionMode" class="mb-0 mr-1 small90">Grid Select:</label>
										<select id="selectionMode" class="data-entry-select d-inline w-auto" title="In Multiple Rows mode, hold Shift while clicking and dragging to select a range of rows." aria-describedby="selectionModeHelp">
											<option value="text">Text</option>
											<option value="cell">Cell(s)</option>
											<option value="singlerow" selected>Single Row</option>
											<option value="multiplerows">Multiple Rows</option>
										</select>
										<span id="selectionModeHelp" class="sr-only">In Multiple Rows mode, hold Shift while clicking and dragging to select a range of rows.</span>
									</div>
									<button type="button" id="copySelectionButton" class="btn btn-xs btn-info mx-1" title="Copy selection to clipboard" onclick="mczCopySelectedFromAllInstances();"><i class="fas fa-copy" aria-hidden="true"></i></button>
									<!--- text-nowrap: last in a wrapping flex row, so a two-word value would
									      otherwise break onto a line of its own. --->
									<output id="selectionCount" class="ml-1 my-0 small text-muted text-nowrap"></output>
								</span>
							</div>
						</div>
					</div>
					<div id="groupChipBar" class="px-1 pb-1" style="display:none;"></div>
					<div id="projectsGridDiv"></div>
				</div>
			</div>
		</section>
	</main>

	<div id="overlay" style="position: absolute; top:0px; left:0px; width: 100%; height: 100%; background: rgba(0,0,0,0.5); border-color: transparent; opacity: 0.99; display: none; z-index: 2;">
		<div style="position: absolute; left: 50%; top: 25%; width: 10em; padding: 5px; background-color: #fff; border: 1px solid #898989; border-radius: 4px; margin-left: -5em;">
			<img src="/shared/images/indicator.gif" alt=""> Searching...
		</div>
	</div>
</div>

<cfoutput>
<script>
	var projectsTable = null;
	/* Selected rows, keyed by project_id, held here rather than left to Tabulator --
	   see mczAttachSelectionStore for why remote paging makes its own selection
	   unreliable. In memory only: a reload clears it. */
	var projectsSelection = new Map();
	var oneOfUs = #oneOfUsJs#;
	var canSaveGridProperties = #canSaveGridPropertiesJs#;
	var canManageProjects = #canManageProjectsJs#;
	var pageFilePath = "#cgi.script_name#";
	var savedColumnVisibility = {};
	var projectColumnPinned = true;
	/* Frozen columns have to be contiguous from the left, so this order is load-bearing,
	   not cosmetic. Assigned in buildProjectsTable, where canManageProjects is known. */
	var projectsPinnedFields = [];
	/* Preserved across a selection-mode rebuild the same way projectColumnPinned is --
	   a user's chosen page size is a preference, not something a fresh table build (or a
	   fresh search) should silently reset back to the default. */
	/* The page size the user last chose (true means "All"). Kept separately from the
	   size actually in effect: a search with fewer matches than this shows them all on
	   one page, and a later, larger result (e.g. after clearing a column filter) goes
	   back to this size -- see mczAdjustProjectsPageSizeOptions. */
	var preferredPageSize = 25;
	/* Base page-size choices offered below the largest total seen so far -- a fixed
	   choice larger than the actual result set is redundant with (and more confusing
	   than) the "All" choice already covering that case. mczAdjustProjectsPageSizeOptions
	   filters this list down per search once the real total is known. */
	var PROJECTS_PAGE_SIZE_BASE_OPTIONS = [5, 10, 25, 50, 100];
	/* Tabulator groups the rows it holds, and with remote paging that is one page. So
	   grouping switches the page size to All and is refused above this many rows, rather
	   than showing per-page counts that read as whole-result-set counts. */
	var PROJECTS_GROUP_MAX_ROWS = 2000;
	var projectsGroupField = null;
	/* The size to return to when the grouping is removed. preferredPageSize cannot serve:
	   switching to All fires pageSizeChanged, which would overwrite it with true. */
	var projectsSizeBeforeGrouping = null;
	var projectsTotalRows = 0;
	/* Set around a programmatic setPageSize so pageSizeChanged does not read it as the
	   user's own choice. */
	var projectsIgnoreNextPageSizeChange = false;
	/* Fields search.cfc accepts a column header filter for, as filter_{field}. */
	var projectsFilterFields = ["project_name", "participants", "sponsors", "start_date", "end_date"];
	/* Shared ⋮ menu on each column header: sort, hide this column (saved like the
	   Select Columns dialog), and open Select Columns. */
	var projectsHeaderMenu = mczStandardHeaderMenu({
		onColumnHidden: function () { saveProjectsColumnVisibility("actionFeedback", "showHiddenColumnsButton"); },
		onChooseColumns: function () { openProjectsColumnChooser("columnChooserDialog"); }
	});
	/* Started once, up front, rather than inside ensureProjectsTableBuilt -- a
	   coldfusion_user's persisted column choices should be in flight from page load, not
	   only once the user's first search kicks off the fetch. Resolves immediately for
	   everyone else, since there is nothing to fetch. */
	var columnVisibilityPromise = canSaveGridProperties
		? mczFetchColumnVisibility(pageFilePath, "Default").then(function (settings) {
			savedColumnVisibility = settings;
		})
		: $.when();
	/* A coldfusion_user's saved column order (drag a column header to move it), stored in
	   the same cf_grid_properties.column_order field and [field, position] format that
	   the jqxGrid pages use. Fetched up front alongside the visibility settings. */
	var savedColumnOrder = {};
	var columnOrderPromise = canSaveGridProperties
		? mczFetchColumnOrder(pageFilePath, "Default").then(function (order) {
			savedColumnOrder = order;
		})
		: Promise.resolve();

	/**
	 * buildProjectsTable creates (or recreates) the Tabulator instance for the results grid,
	 * configured for a given row/cell selection mode. Tabulator reads its selection options
	 * only at initialization and does not react to later changes, so switching modes means
	 * building a new instance rather than updating an existing one.
	 *
	 * Tabulator's SelectRange (cell/range selection) and row-selection are mutually
	 * exclusive on one instance -- enabling both logs a warning and leaves SelectRange
	 * uninitialized -- so each mode below sets only one of the two.
	 *
	 * @param mode one of "text", "cell", "singlerow", "multiplerows".
	 */
	function buildProjectsTable(mode) {
		if (projectsTable) {
			projectsTable.destroy();
			projectsTable = null;
		}
		/* A mode change builds a new instance, and the modes disagree about what a selection
		   means, so a carried-over count would describe rows nothing can show. */
		mczClearSelectionStore(null, projectsSelection, function (map) {
			mczRefreshSelectionCount(map, "selectionCount");
		});
		/* Root cause of "text mode's native drag-selection stops working after visiting
		   a range-selection mode, until a full page reload" (confirmed against source):
		   Tabulator's SelectRange module adds a "tabulator-ranges" class to the container
		   element on init and never removes it again, not even on destroy(). The bundled
		   theme CSS disables user-select on cells whenever that class is present, at
		   higher specificity than this app's own text-mode override -- see
		   mczClearStaleRangeSelectionClass's doc comment for the full trace. */
		mczClearStaleRangeSelectionClass("##projectsGridDiv");
		if (window.getSelection) {
			window.getSelection().removeAllRanges();
		}

		/* Details sits first, beside the row-selection checkboxes and ahead of Project, and
		   freezes and unfreezes with Project so the two travel together under Pin Project
		   Column. Frozen columns have to be contiguous at the left edge, so their order here
		   is also the order they must keep. */
		var detailsColumn = mczDetailsButtonColumn("Project Details");

		var columns = [
			detailsColumn,
			{
				title: "Project",
				field: "project_name",
				widthGrow: 3,
				formatter: mczSafeLinkFormatter("project_name", function (d) {
					return "/projects/showProject.cfm?project_id=" + encodeURIComponent(d.project_id);
				}, "text-primary"),
				/* CSV export gets the plain project name, not the rendered <a> markup. */
				accessorDownload: function (value, data) {
					return data.project_name;
				},
				headerFilter: "input",
				headerFilterPlaceholder: "filter...",
				headerFilterParams: mczHeaderFilterLabel("Project"),
				headerMenu: projectsHeaderMenu
			},
			{ title: "Participants", field: "participants", widthGrow: 2, formatter: mczSafeTextFormatter, headerFilter: "input", headerFilterPlaceholder: "filter...", headerFilterParams: mczHeaderFilterLabel("Participants"), headerMenu: projectsHeaderMenu },
			{ title: "Sponsor(s)", field: "sponsors", widthGrow: 2, formatter: mczSafeTextFormatter, headerFilter: "input", headerFilterPlaceholder: "filter...", headerFilterParams: mczHeaderFilterLabel("Sponsor(s)"), headerMenu: projectsHeaderMenu },
			{ title: "Start Date", field: "start_date", width: 130, formatter: mczSafeTextFormatter, headerFilter: "input", headerFilterPlaceholder: "yyyy-mm-dd", headerFilterParams: mczHeaderFilterLabel("Start Date"), headerMenu: projectsHeaderMenu },
			{ title: "End Date", field: "end_date", width: 130, formatter: mczSafeTextFormatter, headerFilter: "input", headerFilterPlaceholder: "yyyy-mm-dd", headerFilterParams: mczHeaderFilterLabel("End Date"), headerMenu: projectsHeaderMenu }
		];

		if (canManageProjects) {
			/* Third column overall -- after the selection checkbox and Details, ahead of
			   Project -- and inside the pinned group: an edit control that has to be scrolled
			   to is no more use than a details button that has to be scrolled to. */
			columns.splice(1, 0, {
				title: "Edit",
				/* A control column, not data -- "_mcz"-prefixed so mczIsDataColumn() keeps it
				   out of the row details dialog. Binding it to project_id would also have a
				   second column claim a field it never displays; the formatter reads
				   project_id from the row data itself. */
				field: "_mczEdit",
				width: 80,
				headerSort: false,
				download: false,
				formatter: function (cell) {
					var d = cell.getRow().getData();
					var a = document.createElement("a");
					a.className = "btn-xs btn-outline-primary";
					a.href = "/projects/Project.cfm?action=edit&project_id=" + encodeURIComponent(d.project_id);
					a.textContent = "Edit";
					return a;
				}
			});
		}

		projectsPinnedFields = canManageProjects
			? ["_mczDetails", "_mczEdit", "project_name"]
			: ["_mczDetails", "project_name"];
		/* Freeze the group together, and mark only its last column, so the heavier divider
		   draws once where the pinned block ends rather than after every column in it. */
		columns.forEach(function (col) {
			if (projectsPinnedFields.indexOf(col.field) !== -1) {
				col.frozen = projectColumnPinned;
				if (col.field === projectsPinnedFields[projectsPinnedFields.length - 1]) {
					col.cssClass = "mcz-pin-edge";
				}
			}
		});

		/* Apply any persisted show/hide choices (see columnVisibilityPromise above, which
		   ensureProjectsTableBuilt waits on before the first call here) up front, rather
		   than building with defaults and correcting afterward. */
		columns.forEach(function (col) {
			if (savedColumnVisibility.hasOwnProperty(col.field)) {
				col.visible = !savedColumnVisibility[col.field];
			}
		});
		/* Minus the pinned group: mczApplyColumnOrder honours saved positions within the
		   frozen columns, and a position saved before Details and Edit moved up would
		   shuffle them. A pinned group's order belongs to this page, not the user. */
		var orderForColumns = $.extend({}, savedColumnOrder);
		(projectColumnPinned ? projectsPinnedFields : ["_mczDetails", "_mczEdit"]).forEach(function (field) {
			delete orderForColumns[field];
		});
		mczApplyColumnOrder(columns, orderForColumns);

		var options = {
			/* No height set -- an explicit height (or Tabulator's own default) gives the
			   grid its own internal scrollbar. Paging below means a "page" is always a
			   small, fixed number of rows, so the table can size to its content and let
			   the browser's own page scroll handle anything taller than the viewport. */
			layout: "fitColumns",
			/* Drag a column header to reorder. Frozen (pinned) columns can't be dragged,
			   and nothing can be dropped ahead of them (confirmed against source), so a
			   pinned Project column stays first. */
			movableColumns: true,
			/* Column header filters run on the server, like paging and sorting: Tabulator
			   passes the active header filters to mczProjectsAjaxRequest as params.filter,
			   which converts them to the filter_* arguments search.cfc accepts. A short
			   delay keeps typing from sending a request per keystroke. */
			filterMode: "remote",
			headerFilterLiveFilterDelay: 600,
			/* Tabulator's index defaults to "id", which search() does not return, leaving
			   every row's identity undefined. */
			index: "project_id",
			persistence: { sort: true },
			persistenceID: "projectsSearchGrid_v1",
			placeholder: "No projects matched your search.",
			/* No `data` -- omitting it (rather than seeding an empty array) is what makes
			   Tabulator fetch page 1 through ajaxRequestFunc immediately on construction,
			   which is exactly the "build the grid" moment this page treats as "run a
			   search" (see ensureProjectsTableBuilt/searchProjects below). */
			/* Frozen column listed first -- Tabulator logs a warning if a frozen column
			   isn't at index 0 when range-select is enabled. */
			columns: columns,
			/* Paging and sorting both happen server-side -- projects/component/search.cfc's
			   search() takes page/size/sort_field/sort_dir and returns only one page's
			   rows plus last_page/last_row, rather than this page fetching and holding
			   every matching row in the browser (which would work poorly for a large
			   result set). mczProjectsAjaxRequest is this app's own $.ajax()-based
			   request function, not Tabulator's own networking layer, matching how every
			   other search page here talks to its backing .cfc. */
			ajaxURL: "/projects/component/search.cfc",
			ajaxRequestFunc: mczProjectsAjaxRequest,
			ajaxParams: mczProjectsAjaxParams,
			paginationMode: "remote",
			sortMode: "remote",
			pagination: true,
			/* Changing selection mode rebuilds the table. An active grouping has to come
			   back on All, or its counts would describe one page of preferredPageSize. */
			paginationSize: projectsGroupField ? true : preferredPageSize,
			paginationSizeSelector: PROJECTS_PAGE_SIZE_BASE_OPTIONS.concat([true]),
			/* Tabulator's own built-in "rows" counter preset ("Showing 1-50 of 173
			   rows"), rather than a custom one -- this app has no existing convention of
			   its own to match here. */
			paginationCounter: "rows",
			/* Groups start closed: the reason to group is to read the counts, and 2000
			   rows expanded is not a view anyone wants first. */
			groupStartOpen: false,
			groupHeader: function (value, count, data, group) {
				return mczGroupHeaderElement(projectsTable, group, value, count);
			}
		};

		if (mode !== "text") {
			/* Copy-only (no clipboardPasteAction use). Not enabled in "text" mode at
			   all -- that mode wants pure native browser copy with zero Tabulator
			   clipboard-module involvement, one less thing that could interfere with it. */
			options.clipboard = "copy";
		}

		if (mode === "cell") {
			/* Deliberately NOT setting selectableRangeColumns/selectableRangeRows --
			   those enable a separate feature (clicking a header selects the whole
			   column/row) not wanted here, and as a side effect (confirmed against
			   source) designate the first visible column as a specially-styled
			   "range row header" -- which was the cause of the pinned Project column
			   showing grey/dark-blue instead of the normal range highlight color. */
			/* Tabulator has no native single-cell-only selection mode -- selectableRange
			   is a max-concurrent-ranges count, not a max-cells-per-range limit, so a range
			   can always span more than one cell regardless of this setting. One "Cell(s)"
			   mode covering both is offered rather than a "Single Cell" mode that can't
			   actually be enforced. */
			options.selectableRange = true;
		} else if (mode === "singlerow" || mode === "multiplerows") {
			options.selectableRows = (mode === "multiplerows") ? true : 1;
			/* A checkbox column, in both row modes: row selection is otherwise invisible until
			   a row is already selected. In Single Row these behave like radio buttons, so a
			   select-all header would have nothing valid to do. */
			options.rowHeader = {
				formatter: "rowSelection",
				headerSort: false,
				resizable: false,
				frozen: true,
				width: 40,
				hozAlign: "center",
				headerHozAlign: "center",
				download: false
			};
			if (mode === "multiplerows") {
				/* Select-all / deselect-all for the rows on the current page. */
				options.rowHeader.titleFormatter = "rowSelection";
			}
		}
		/* mode === "text": no selection module enabled. Native text selection needs the
		   mcz-text-select-mode class below too -- see tabulator_overrides.css. */

		$("##projectsGridDiv").toggleClass("mcz-text-select-mode", mode === "text");
		$("##projectsGridDiv").toggleClass("mcz-row-select-mode", mode === "singlerow" || mode === "multiplerows");
		/* Copy Selection has nothing to do in "text" mode -- native selection/copy
		   already works there on its own (once selected), with no Tabulator-tracked
		   row or range selection for this button to act on. */
		$("##copySelectionButton").toggle(mode !== "text");
		/* Exporting selected rows only makes sense where rows can be selected. */
		$("##exportSelectedOnlyContainer").toggle(mode === "singlerow" || mode === "multiplerows");
		if (!(mode === "singlerow" || mode === "multiplerows")) {
			$("##exportSelectedOnly").prop("checked", false);
		}
		projectsTable = new Tabulator("##projectsGridDiv", options);
		mczRegisterTabulatorInstance(projectsTable);
		mczPreventSelectRangeNativeSelection(projectsTable);
		mczAddPageJumpControl(projectsTable, "projectsPageJump");
		/* Only Multiple Rows gathers a selection across pages. Tabulator can hold Single
		   Row's limit of one only among the rows it currently has loaded, so the honest
		   reading of that mode is "the row on screen": the store is told not to persist, and
		   the count and the export then both describe just this page. */
		mczAttachSelectionStore(projectsTable, projectsSelection, "project_id", mode === "multiplerows", function (map) {
			mczRefreshSelectionCount(map, "selectionCount");
		});
		projectsTable.on("tableBuilt", populateColumnChooser);
		projectsTable.on("tableBuilt", function () {
			mczPopulateGroupByPicker(projectsTable, "groupByColumn", projectsGroupField);
			/* Changing selection mode rebuilds the table, which drops groupBy with it. */
			if (projectsGroupField) {
				projectsTable.setGroupBy(projectsGroupField);
			}
		});
		projectsTable.on("tableBuilt", function () {
			mczRefreshShowHiddenColumnsButton(projectsTable, "showHiddenColumnsButton");
		});
		projectsTable.on("tableBuilt", function () {
			mczMakeHeaderMenuButtonsAccessible(projectsTable);
		});
		projectsTable.on("pageSizeChanged", function (size) {
			if (projectsIgnoreNextPageSizeChange) {
				projectsIgnoreNextPageSizeChange = false;
				return;
			}
			preferredPageSize = size;
			/* Grouping outside All would count one page while presenting a whole-result-set
			   total, so moving off All ends the grouping rather than quietly misreporting. */
			if (projectsGroupField && size !== true) {
				clearProjectsGrouping("Grouping removed: it needs every row loaded.");
			}
		});
		projectsTable.on("columnMoved", function () {
			if (canSaveGridProperties) {
				mczSaveTableColumnOrder(projectsTable, pageFilePath, "Default", "actionFeedback");
			}
		});
	}

	/**
	 * setProjectsGrouping groups the grid by a column, loading every matching row first
	 * so the group counts describe the whole result set and not the current page.
	 *
	 * @param field column field to group by, or "" to remove the grouping.
	 */
	function setProjectsGrouping(field) {
		if (!projectsTable) {
			return;
		}
		if (!field) {
			clearProjectsGrouping();
			return;
		}
		if (projectsTotalRows > PROJECTS_GROUP_MAX_ROWS) {
			$("##actionFeedback").html('<span class="text-danger">Too many rows to group (' +
				projectsTotalRows + '); narrow the search first.</span>');
			$("##groupByColumn").val(projectsGroupField || "");
			return;
		}
		if (projectsGroupField === null) {
			projectsSizeBeforeGrouping = projectsTable.getPageSize();
		}
		projectsGroupField = field;
		if (projectsTable.getPageSize() !== true) {
			projectsIgnoreNextPageSizeChange = true;
			projectsTable.setPageSize(true);
		}
		projectsTable.setGroupBy(field);
		mczRenderGroupChip("groupChipBar", mczColumnTitle(projectsTable, field), function () {
			clearProjectsGrouping();
		});
		$("##groupByColumn").val(field);
	}

	/**
	 * clearProjectsGrouping removes the grouping and returns the page size to whatever was
	 * in effect before grouping started.
	 *
	 * @param message optional note for the feedback output, for a grouping this page
	 *   removed on the user's behalf rather than at their request.
	 */
	function clearProjectsGrouping(message) {
		projectsGroupField = null;
		mczRenderGroupChip("groupChipBar", null, null);
		$("##groupByColumn").val("");
		if (!projectsTable) {
			return;
		}
		projectsTable.setGroupBy(false);
		if (projectsSizeBeforeGrouping !== null && projectsTable.getPageSize() !== projectsSizeBeforeGrouping) {
			projectsIgnoreNextPageSizeChange = true;
			projectsTable.setPageSize(projectsSizeBeforeGrouping);
		}
		projectsSizeBeforeGrouping = null;
		if (message) {
			$("##actionFeedback").html('<span class="text-muted">' + message + '</span>');
		}
	}

	/**
	 * mczProjectsAjaxParams supplies the current search form's field values as the
	 * request body for every page/size/sort-triggered reload Tabulator makes on its
	 * own (not just the ones this page's own code triggers) -- Tabulator calls this
	 * itself immediately before each request, so it always reflects the form's current
	 * state, not whatever it held when the table was last built.
	 *
	 * @return a plain object of form field name/value pairs.
	 */
	function mczProjectsAjaxParams() {
		var params = {};
		$("##searchForm").serializeArray().forEach(function (field) {
			params[field.name] = field.value;
		});
		return params;
	}

	/**
	 * mczProjectsAjaxRequest is this page's `ajaxRequestFunc` -- Tabulator calls this
	 * itself (with page/size/sort merged into params by its pagination/sort modules,
	 * confirmed against source) instead of using its own built-in networking, so the
	 * request goes through this app's usual $.ajax()/handleFail() convention.
	 *
	 * @param url the configured ajaxURL (projects/component/search.cfc).
	 * @param config request config (unused; this app's own $.ajax() call needs none of
	 *   Tabulator's own request-building options).
	 * @param params request body: mczProjectsAjaxParams' fields plus page, size, and
	 *   sort (an array of {field, dir}, at most one entry -- multi-column sort isn't
	 *   enabled on this grid).
	 * @return a native Promise resolving to {data, last_page, last_row} on success. The
	 *   jqXHR is wrapped with mczToNativePromise() because Tabulator chains .finally()
	 *   onto this result, and jQuery 3.x Deferreds have no finally(): returning the bare
	 *   jqXHR throws inside Tabulator's initial load, so "tableBuilt" never fires (leaving
	 *   the column chooser empty) even though the rows still render.
	 */
	function mczProjectsAjaxRequest(url, config, params) {
		$("##overlay").show();
		$("##actionFeedback").html("");
		var sorter = (params.sort && params.sort[0]) || {};
		var requestData = $.extend({}, params, {
			sort_field: sorter.field || "",
			sort_dir: sorter.dir || ""
		});
		delete requestData.sort;
		$.extend(requestData, mczHeaderFilterParams(params.filter, projectsFilterFields, "filter_"));
		delete requestData.filter;
		/* Every reload comes through here, so this keeps Clear Column Filters showing
		   exactly when a header filter is active. The button id is named directly because
		   Tabulator fixes this function's signature, leaving no way to pass it in. */
		$("##clearHeaderFiltersButton").toggle(Object.keys(mczHeaderFilterParams(params.filter, projectsFilterFields, "filter_")).length > 0);
		return mczToNativePromise($.ajax({
			url: url,
			data: requestData,
			dataType: "json"
		}).done(function (response) {
			$("##overlay").hide();
			mczHandleProjectsSearchResponse(response);
		}).fail(function (jqXHR, status, error) {
			$("##overlay").hide();
			handleFail(jqXHR, status, error, "searching for projects");
		}));
	}

	/**
	 * mczHandleProjectsSearchResponse applies the side effects of a completed search --
	 * shared by the first page load and every later page/size/sort change, since all of
	 * them go through mczProjectsAjaxRequest above.
	 *
	 * @param response {data, last_page, last_row} as returned by search().
	 */
	function mczHandleProjectsSearchResponse(response) {
		var totalRows = response.last_row || 0;
		$("##resultCount").text("Found " + totalRows + " project record" + (totalRows === 1 ? "" : "s") + ".");
		$("##resultLink").html('<a href="/Projects.cfm?execute=true&' +
			$("##searchForm :input").filter(function (index, element) { return $(element).val() != ""; })
				.not(".excludeFromLink").serialize() + '">Link to this search</a>');
		/* First successful search: reveal the toolbar controls and the results
		   count/link, none of which should be visible before this point. Calling show()
		   again on every later response is harmless. */
		$("##resultsMeta").show();
		$("##resultsHeadingControls").show();
		$("##resultsToolbarControls").show();
		projectsTotalRows = totalRows;
		if (projectsGroupField && totalRows > PROJECTS_GROUP_MAX_ROWS) {
			clearProjectsGrouping("Grouping removed: " + totalRows + " rows is too many to group.");
		}
		mczAdjustProjectsPageSizeOptions(totalRows);
	}

	/**
	 * mczAdjustProjectsPageSizeOptions drops any fixed page-size choice larger than the
	 * current result set, so the dropdown never offers e.g. "500" alongside "All" when
	 * there are only 173 matching rows -- confusing, since picking either shows the same
	 * thing. Reaches into table.modules.page directly (confirmed against source): there
	 * is no public method for changing paginationSizeSelector after construction.
	 *
	 * Also corrects the *active* size the same way if needed: generatePageSizeSelectList
	 * always re-adds the current size to the list if it isn't already there (confirmed
	 * against source), which would otherwise silently defeat the filtering above whenever
	 * the active size (e.g. the default 50) is itself larger than a later, smaller
	 * search's total. Setting modules.page.size directly, rather than calling the public
	 * setPageSize(), avoids the reload that method would trigger -- this response already
	 * holds every matching row, so there is nothing new to fetch.
	 *
	 * @param totalRows total matching row count from the most recent response.
	 */
	function mczAdjustProjectsPageSizeOptions(totalRows) {
		if (!projectsTable || !projectsTable.modules || !projectsTable.modules.page) {
			return;
		}
		var pageModule = projectsTable.modules.page;
		var visibleSizes = PROJECTS_PAGE_SIZE_BASE_OPTIONS.filter(function (size) {
			return size <= totalRows;
		});
		visibleSizes.push(true);
		if (pageModule.size !== true && pageModule.size > totalRows) {
			pageModule.size = true;
		} else if (!projectsGroupField && pageModule.size === true && preferredPageSize !== true && totalRows > preferredPageSize) {
			/* Showing "All" only because an earlier result was small: return to the
			   user's chosen size. setPageSize() reloads, so defer it until Tabulator has
			   finished handling the response now in progress. */
			setTimeout(function () {
				if (projectsTable) {
					projectsTable.setPageSize(preferredPageSize);
				}
			}, 0);
		}
		projectsTable.options.paginationSizeSelector = visibleSizes;
		pageModule.generatePageSizeSelectList();
	}

	/**
	 * populateColumnChooser rebuilds the columnChooserList checkbox markup from the
	 * current table's columns. Column titles/fields come from this page's own column
	 * definitions, not user-supplied data, so plain string concatenation is used here
	 * (contrast mczSafeTextFormatter/mczSafeLinkFormatter, which exist for cell values).
	 */
	function populateColumnChooser() {
		var html = "";
		projectsTable.getColumns().forEach(function (column) {
			var def = column.getDefinition();
			if (!mczIsDataColumn(def)) { return; }
			html += "<div class='d-flex align-items-center mb-1'>" +
				"<input type='checkbox' class='columnChooserCheckbox mr-2' id='colChoice_" + def.field + "' data-field='" + def.field + "'" +
				(column.isVisible() ? " checked" : "") + ">" +
				"<label class='mb-0' for='colChoice_" + def.field + "'>" + def.title + "</label>" +
				"</div>";
		});
		$("##columnChooserList").html(html);
	}

	/**
	 * togglePinProjectColumn flips the Project column's frozen state, both on the live
	 * table (via updateDefinition, which re-runs Tabulator's column initialization so
	 * the frozen-columns module picks the change up) and in projectColumnPinned, so a
	 * later selection-mode change -- which rebuilds the table from scratch -- doesn't
	 * silently revert the choice.
	 */
	function togglePinProjectColumn() {
		projectColumnPinned = !projectColumnPinned;
		/* Details and Project pin together. Once unpinned, Project can be dragged elsewhere,
		   and a frozen column that follows an unfrozen one freezes to the right edge rather
		   than the left -- so both have to be back at the left, Details first, before either
		   is frozen again. */
		if (projectColumnPinned) {
			/* Skip the checkbox column the row-selection modes add, which has no field. */
			var firstField = projectsTable.getColumns().map(function (column) {
				return column.getField();
			}).filter(function (field) { return field; })[0];
			if (firstField && firstField !== projectsPinnedFields[0]) {
				projectsTable.moveColumn(projectsPinnedFields[0], firstField, false);
			}
			/* Then line the rest of the group up behind it, in order. */
			for (var i = 1; i < projectsPinnedFields.length; i++) {
				projectsTable.moveColumn(projectsPinnedFields[i], projectsPinnedFields[i - 1], true);
			}
		}
		/* Sequentially, not in parallel: each updateDefinition re-runs Tabulator's column
		   initialization and rebuilds the header, and the frozen-columns module reads the
		   whole column list as it goes. Re-apply the header menu buttons' keyboard access
		   once at the end, since the rebuilds discard it. */
		var pinning = Promise.resolve();
		projectsPinnedFields.forEach(function (field) {
			pinning = pinning.then(function () {
				return projectsTable.getColumn(field).updateDefinition({ frozen: projectColumnPinned });
			});
		});
		pinning.then(function () {
			mczMakeHeaderMenuButtonsAccessible(projectsTable);
		});
	}

	/**
	 * exportProjects downloads the current search as CSV or Excel.
	 *
	 * Exports every project matching the current search, not just the page on screen:
	 * in remote pagination mode the table only holds the current page, so
	 * table.download() would export that page alone. Instead this asks search.cfc for
	 * every matching row (size "true", the same value the "All" page-size choice sends)
	 * with the grid's current sort and column header filters. Hidden columns are
	 * included, matching the jqxGrid pages' exportGridToCSV().
	 *
	 * When "Selected rows only" is checked (offered in the row selection modes), exports
	 * just the selected rows instead, with no server request.
	 *
	 * @param format "csv" or "xlsx".
	 * @param selectedOnlyCheckboxId id (no leading ##) of the "Selected rows only" checkbox.
	 * @param overlayId id (no leading ##) of the loading overlay to show while working.
	 */
	function exportProjects(format, selectedOnlyCheckboxId, overlayId) {
		if (!projectsTable) {
			return;
		}
		var filename = mczExportFilename("project", format);
		function writeRows(rows) {
			if (format === "xlsx") {
				$("##" + overlayId).show();
				return mczExportRowsToExcel(projectsTable, rows, true, filename, "Projects").then(function () {
					$("##" + overlayId).hide();
				}, function (error) {
					$("##" + overlayId).hide();
					messageDialog("Could not create the Excel file: " + error.message, "Export to Excel");
				});
			}
			exportToCSV(mczBuildCsv(projectsTable, rows, true), filename);
		}
		if ($("##" + selectedOnlyCheckboxId).is(":checked")) {
			/* From the store, not getSelectedData(): only the store holds rows from pages the
			   browser has since replaced. */
			var selected = Array.from(projectsSelection.values());
			if (!selected.length) {
				messageDialog("No rows are selected. Select one or more rows, or uncheck Selected rows only to export every result.", "Export");
				return;
			}
			writeRows(selected);
			return;
		}
		var sorter = projectsTable.getSorters()[0] || {};
		var requestData = $.extend({}, mczProjectsAjaxParams(), {
			page: 1,
			size: "true",
			sort_field: sorter.field || "",
			sort_dir: sorter.dir || ""
		}, mczHeaderFilterParams(projectsTable.getHeaderFilters(), projectsFilterFields, "filter_"));
		$("##" + overlayId).show();
		$.ajax({
			url: "/projects/component/search.cfc",
			data: requestData,
			dataType: "json"
		}).done(function (response) {
			$("##" + overlayId).hide();
			writeRows((response && response.data) || []);
		}).fail(function (jqXHR, status, error) {
			$("##" + overlayId).hide();
			handleFail(jqXHR, status, error, "exporting projects");
		});
	}

	/**
	 * clearProjectsHeaderFilters removes every column header filter; the table reloads
	 * from the server on its own.
	 */
	function clearProjectsHeaderFilters() {
		if (projectsTable) {
			projectsTable.clearHeaderFilter();
		}
	}

	/**
	 * openProjectsColumnChooser refreshes the Select Columns checkbox list from the
	 * table's current state and opens the dialog.
	 *
	 * @param dialogId id (no leading ##) of the Select Columns dialog.
	 */
	function openProjectsColumnChooser(dialogId) {
		populateColumnChooser();
		$("##" + dialogId).dialog("open");
	}

	/**
	 * saveProjectsColumnVisibility records which columns are hidden, and for a
	 * coldfusion_user saves that to the server (the same settings the Select Columns
	 * dialog saves), so a column hidden from its header menu stays hidden next time.
	 *
	 * @param feedbackDivId id (no leading ##) of the element that shows save feedback.
	 * @param hiddenColumnsButtonId id (no leading ##) of the "show hidden columns"
	 *   button to bring back into step. Refreshed here rather than at each call site so
	 *   a future caller cannot leave the button showing a stale count.
	 */
	function saveProjectsColumnVisibility(feedbackDivId, hiddenColumnsButtonId) {
		var hidden = {};
		projectsTable.getColumns().forEach(function (column) {
			var def = column.getDefinition();
			if (mczIsDataColumn(def)) {
				hidden[def.field] = !column.isVisible();
			}
		});
		savedColumnVisibility = hidden;
		if (hiddenColumnsButtonId) {
			mczRefreshShowHiddenColumnsButton(projectsTable, hiddenColumnsButtonId);
		}
		if (canSaveGridProperties) {
			saveColumnVisibilities(pageFilePath, hidden, "Default", feedbackDivId);
		}
	}

	/**
	 * showAllProjectsColumns brings back every hidden column and persists the change.
	 *
	 * @see mczShowAllColumns for why this is a control of its own rather than something
	 *   reachable from the header menu that hid the column.
	 */
	function showAllProjectsColumns() {
		mczShowAllColumns(projectsTable);
		saveProjectsColumnVisibility("actionFeedback", "showHiddenColumnsButton");
	}

	/**
	 * populateSaveSearchDialog fills saveSearchDialog with a form capturing the
	 * current search as a URL, a name, and whether to run it immediately when opened
	 * later -- saveSearch() (loaded from /users/js/internal.js for coldfusion_user
	 * sessions) posts this to /users/component/functions.cfc.
	 */
	function populateSaveSearchDialog() {
		var uri = "/Projects.cfm?execute=true&" +
			$("##searchForm :input").filter(function (index, element) { return $(element).val() != ""; })
				.not(".excludeFromLink").serialize();
		$("##saveSearchDialog").html(
			"<form id='saveSearchForm'>" +
			"<input type='hidden' name='url' value='" + uri + "'>" +
			"<div class='form-group'><label for='search_name_input'>Search Name</label>" +
			"<input type='text' id='search_name_input' name='search_name' class='data-entry-input' maxlength='60' required></div>" +
			"<div class='form-group'><label for='execute_input'>Execute Immediately</label> " +
			"<input id='execute_input' type='checkbox' name='execute' checked></div>" +
			"</form>"
		);
	}

	/**
	 * ensureProjectsTableBuilt builds the Tabulator instance the first time it's needed
	 * (a search actually running), rather than at page load -- the grid, including its
	 * header, must not appear until then. Waits on columnVisibilityPromise first so a
	 * coldfusion_user's persisted show/hide choices are already in savedColumnVisibility
	 * by the time buildProjectsTable reads it, matching the ordering the old unconditional
	 * page-load build relied on.
	 *
	 * @return a Promise resolved once projectsTable exists.
	 */
	function ensureProjectsTableBuilt() {
		if (projectsTable) {
			return $.when();
		}
		return Promise.all([columnVisibilityPromise, columnOrderPromise]).then(function () {
			if (!projectsTable) {
				var $selectionMode = $("##selectionMode");
				buildProjectsTable($selectionMode.length ? $selectionMode.val() : "text");
			}
		});
	}

	/**
	 * searchProjects starts a new search (as opposed to a page/size/sort change, which
	 * Tabulator triggers on its own): builds the grid if this is the very first search
	 * (which fetches page 1 itself, on construction, through mczProjectsAjaxRequest --
	 * see buildProjectsTable), otherwise forces a reload of the now-current search form
	 * criteria by jumping back to page 1.
	 */
	function searchProjects() {
		var tableAlreadyExisted = !!projectsTable;
		/* New results, so any held selection described the old ones. */
		mczClearSelectionStore(projectsTable, projectsSelection, function (map) {
			mczRefreshSelectionCount(map, "selectionCount");
		});
		ensureProjectsTableBuilt().then(function () {
			if (tableAlreadyExisted) {
				projectsTable.setPage(1);
			}
		});
	}

	$(document).ready(function () {
		mczEnableClipboardCopy();

		$("##showhide").html(
			/* btn btn-xs btn-secondary, like every other control in this toolbar -- the
			   legacy "border rounded" spelling rendered it at the browser's default button
			   size, noticeably taller than its neighbours. */
			'<button type="button" class="btn btn-xs btn-secondary mx-1 my-0" title="hide search form" ' +
			'onclick="toggleAnySearchForm(\'searchFormDiv\',\'searchFormToggleIcon\');">' +
			'<i id="searchFormToggleIcon" class="fas fa-eye-slash"></i></button>'
		);

		$("##columnChooserDialog").dialog({
			autoOpen: false,
			modal: true,
			width: "auto",
			buttons: (function () {
				var buttons = [];
				if (canSaveGridProperties) {
					buttons.push({
						text: "Defaults",
						click: function () {
							projectsTable.getColumns().forEach(function (column) {
								if (mczIsDataColumn(column.getDefinition())) { column.show(); }
							});
							savedColumnVisibility = {};
							saveColumnVisibilities(pageFilePath, {}, "Default", "actionFeedback");
							/* Also restore the default column order. Rebuilding is the simplest
							   way to put every column back in its defined position; the rebuild
							   reloads page 1 and repopulates this list on "tableBuilt". */
							savedColumnOrder = {};
							saveColumnOrder(pageFilePath, null, "Default", "actionFeedback");
							buildProjectsTable($("##selectionMode").val());
						}
					});
				}
				buttons.push({
					text: "Ok",
					click: function () {
						$("##columnChooserList .columnChooserCheckbox").each(function () {
							var field = $(this).data("field");
							var checked = $(this).is(":checked");
							var column = projectsTable.getColumn(field);
							if (checked) { column.show(); } else { column.hide(); }
						});
						saveProjectsColumnVisibility("actionFeedback", "showHiddenColumnsButton");
						$(this).dialog("close");
					}
				});
				return buttons;
			})()
		});

		$("##saveSearchDialog").dialog({
			autoOpen: false,
			modal: true,
			title: "Save Search",
			buttons: [
				{
					text: "Save",
					click: function () {
						var url = $("##saveSearchForm :input[name=url]").val();
						var execute = $("##saveSearchForm :input[name=execute]").is(":checked");
						var search_name = $("##saveSearchForm :input[name=search_name]").val();
						saveSearch(url, execute, search_name, "actionFeedback");
						$(this).dialog("close");
					}
				},
				{
					text: "Cancel",
					click: function () { $(this).dialog("close"); }
				}
			]
		});

		/* Both bound before the execute=true auto-submit below -- calling .submit()
		   before the searchForm handler exists falls through to a native (non-AJAX)
		   form submission instead of triggering searchProjects(). */
		/* Rebuilding alone is enough here -- buildProjectsTable's own construction
		   fetches page 1 itself (see its options.ajaxURL/ajaxRequestFunc comment), so
		   calling searchProjects() too would fire a redundant second request. */
		$("##selectionMode").on("change", function () {
			buildProjectsTable($(this).val());
		});
		$("##searchForm").on("submit", function (e) {
			e.preventDefault();
			searchProjects();
		});

		<cfif len(url.execute) GT 0>
			$("##searchForm").submit();
		</cfif>
	});
</script>
</cfoutput>

<script src="/shared/js/wikiDrawer.js"></script>
<cfset targetWikiPage = "Project_Search">
<cfoutput>#renderWikiDrawer(action, targetWikiPage)#</cfoutput>

<cfinclude template = "/shared/_footer.cfm">
