<!---
Projects.cfm

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
Search-with-results page for Projects, replacing the project-search half of
SpecimenUsage.cfm (publication search there is served by /Publications.cfm).

View/Edit links below point at the existing ProjectDetail.cfm/Project.cfm; those will be
replaced by /projects/showProject.cfm and /projects/Project.cfm, which don't exist yet.
--->
<cfset pageTitle = "Search Projects">
<cfset action = "search">

<cfparam name="url.p_title" default="">
<cfparam name="url.participant_agent_id" default="">
<cfparam name="url.participant_agent_name" default="">
<cfparam name="url.sponsor_agent_id" default="">
<cfparam name="url.sponsor_agent_name" default="">
<cfparam name="url.project_type" default="">
<cfparam name="url.year" default="">
<cfparam name="url.descr_len" default="">
<cfparam name="url.publication_id" default="">
<cfparam name="url.project_id" default="">
<cfparam name="url.execute" default="">

<cfset variables.p_title = url.p_title>
<cfset variables.participant_agent_id = url.participant_agent_id>
<cfset variables.participant_agent_name = url.participant_agent_name>
<cfset variables.sponsor_agent_id = url.sponsor_agent_id>
<cfset variables.sponsor_agent_name = url.sponsor_agent_name>
<cfset variables.project_type = url.project_type>
<cfset variables.year = url.year>
<cfset variables.descr_len = url.descr_len>
<cfset variables.publication_id = url.publication_id>
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

<cfset canManageProjectsJs = "false">
<cfif canManageProjects>
	<cfset canManageProjectsJs = "true">
</cfif>

<cfset oneOfUsJs = "false">
<cfif oneOfUs EQ 1>
	<cfset oneOfUsJs = "true">
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
<script src="/lib/Tabulator/tabulator_ver6.5.2/js/tabulator.min.js"></script>
<script src="/shared/js/tabulator-common.js"></script>
<script src="/projects/js/projects.js"></script>

<div id="overlaycontainer" style="position: relative;">
	<main id="content">
		<section class="container-fluid" role="search">
			<cftry>
				<cfoutput>#renderWikiButtons(buttonClass="btn btn-xs btn-dark mr-4 border-0")#</cfoutput>
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
								<fieldset class="bg-light border-default field-set rounded px-2 pt-1 pb-2 mt-2 mx-2">
									<legend class="h6 mb-0 px-3 border-default field-set-legend py-0 w-auto bg-teal font-weight-bold">Project</legend>
									<div class="form-row">
										<div class="col-12 col-md-6">
											<label for="p_title" class="data-entry-label">Title</label>
											<input type="text" id="p_title" name="p_title" class="data-entry-input" value="#encodeForHtml(variables.p_title)#">
											<script>
												$(document).ready(function () {
													makeProjectTitleSearchAutocomplete("p_title");
												});
											</script>
										</div>
										<div class="col-12 col-md-6">
											<label for="descr_len" class="data-entry-label">Description Min. Length</label>
											<input type="text" id="descr_len" name="descr_len" class="data-entry-input" value="#encodeForHtml(variables.descr_len)#">
										</div>
									</div>
								</fieldset>
								<fieldset class="bg-light border-default field-set rounded px-2 pt-1 pb-2 mt-2 mx-2">
									<legend class="h6 mb-0 px-3 border-default field-set-legend py-0 w-auto bg-teal font-weight-bold">Participants &amp; Sponsor</legend>
									<div class="form-row">
										<div class="col-12 col-md-6">
											<div class="form-row mx-0 my-0 py-0">
												<label for="participant_agent_name" id="participant_agent_name_label" class="data-entry-label mb-0 pb-0">Participant
													<span id="participant_agent_view" class="ml-2"></span>
												</label>
												<div class="input-group">
													<div class="input-group-prepend">
														<span class="input-group-text smaller bg-lightgreen" id="participant_agent_name_icon"><i class="fa fa-user" aria-hidden="true"></i></span>
													</div>
													<input type="text" name="participant_agent_name" id="participant_agent_name" class="w-auto h-auto form-control rounded-right data-entry-input form-control-sm" aria-label="Participant agent name" value="#encodeForHtml(variables.participant_agent_name)#">
													<input type="hidden" name="participant_agent_id" id="participant_agent_id" value="#encodeForHtml(variables.participant_agent_id)#">
												</div>
											</div>
											<script>
												$(document).ready(function () {
													makeConstrainedRichAgentPickerConfig("participant_agent_name", "participant_agent_id", "participant_agent_name_icon", "participant_agent_view", "#variables.participant_agent_id#", "project_agent", false);
												});
											</script>
										</div>
										<div class="col-12 col-md-6">
											<div class="form-row mx-0 my-0 py-0">
												<label for="sponsor_agent_name" id="sponsor_agent_name_label" class="data-entry-label mb-0 pb-0">Sponsor
													<span id="sponsor_agent_view" class="ml-2"></span>
												</label>
												<div class="input-group">
													<div class="input-group-prepend">
														<span class="input-group-text smaller bg-lightgreen" id="sponsor_agent_name_icon"><i class="fa fa-user" aria-hidden="true"></i></span>
													</div>
													<input type="text" name="sponsor_agent_name" id="sponsor_agent_name" class="w-auto h-auto form-control rounded-right data-entry-input form-control-sm" aria-label="Sponsor agent name" value="#encodeForHtml(variables.sponsor_agent_name)#">
													<input type="hidden" name="sponsor_agent_id" id="sponsor_agent_id" value="#encodeForHtml(variables.sponsor_agent_id)#">
												</div>
											</div>
											<script>
												$(document).ready(function () {
													makeConstrainedRichAgentPickerConfig("sponsor_agent_name", "sponsor_agent_id", "sponsor_agent_name_icon", "sponsor_agent_view", "#variables.sponsor_agent_id#", "project_sponsor", false);
												});
											</script>
										</div>
									</div>
								</fieldset>
								<fieldset class="bg-light border-default field-set rounded px-2 pt-1 pb-2 mt-2 mx-2">
									<legend class="h6 mb-0 px-3 border-default field-set-legend py-0 w-auto bg-teal font-weight-bold">Type &amp; Year</legend>
									<div class="form-row">
										<div class="col-12 col-md-6">
											<label for="project_type" class="data-entry-label">Type</label>
											<cfset selected = "">
											<cfif variables.project_type EQ ""><cfset selected = "selected"></cfif>
											<select id="project_type" name="project_type" class="data-entry-select">
												<option value="" #selected#></option>
												<cfset selected = "">
												<cfif variables.project_type EQ "loan"><cfset selected = "selected"></cfif>
												<option value="loan" #selected#>Uses Specimens</option>
												<cfset selected = "">
												<cfif variables.project_type EQ "loan_no_pub"><cfset selected = "selected"></cfif>
												<option value="loan_no_pub" #selected#>Uses Specimens, no publication</option>
												<cfset selected = "">
												<cfif variables.project_type EQ "accn"><cfset selected = "selected"></cfif>
												<option value="accn" #selected#>Contributes Specimens</option>
												<cfset selected = "">
												<cfif variables.project_type EQ "both"><cfset selected = "selected"></cfif>
												<option value="both" #selected#>Uses and Contributes</option>
												<cfset selected = "">
												<cfif variables.project_type EQ "neither"><cfset selected = "selected"></cfif>
												<option value="neither" #selected#>Neither Uses nor Contributes</option>
											</select>
										</div>
										<div class="col-12 col-md-6">
											<label for="year" class="data-entry-label">Year</label>
											<input type="text" id="year" name="year" class="data-entry-input" value="#encodeForHtml(variables.year)#">
										</div>
									</div>
								</fieldset>
							</div>
							<div class="col-12 px-3 py-2 float-left">
								<button type="submit" class="btn btn-xs btn-primary mr-2 my-1" id="searchButton">Search<span class="fa fa-search pl-1" aria-hidden="true"></span></button>
								<button type="reset" class="btn btn-xs btn-warning mr-2 my-1">Reset</button>
								<button type="button" class="btn btn-xs btn-warning mr-2 my-1" onclick="window.location.href='#Application.serverRootUrl#/Projects.cfm';">New Search</button>
								<cfif canManageProjects>
									<button type="button" class="btn btn-xs btn-secondary my-1" onclick="window.location.href='#Application.serverRootUrl#/Project.cfm?action=makeNew';">Create New Project</button>
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
					<div class="row mt-1 mb-0 border px-2 pt-2 mx-0 align-items-center" style="background-color:#deebec;">
						<h1 class="h4 ml-2 ml-md-1 mt-1 mb-1 px-2 mb-xl-2">
							<span tabindex="0">Results: </span>
							<span id="resultsMeta" style="display:none;">
								<span class="pr-2 font-weight-normal" id="resultCount"></span>
								<span id="resultLink" class="pr-2 font-weight-normal"></span>
							</span>
						</h1>
						<div id="resultsToolbarControls" style="display:none;">
							<!--- The flex layout lives on this inner div rather than resultsToolbarControls
							      itself -- Bootstrap's d-flex utility is !important, which beats a plain
							      (non-!important) inline display:none on the same element, so the outer
							      hide/show wrapper must carry no competing display-affecting class. --->
							<div class="d-flex flex-wrap align-items-center">
								<div id="showhide"></div>
								<button type="button" class="btn btn-xs btn-secondary mx-1" onclick="$('#columnChooserDialog').dialog('open');">Select Columns</button>
								<div id="columnChooserDialog" title="Show/Hide Columns" style="display:none;">
									<div id="columnChooserList" class="px-1"></div>
								</div>
								<button type="button" class="btn btn-xs btn-secondary mx-1" onclick="togglePinProjectColumn();">Pin Project Column</button>
								<button type="button" class="btn btn-xs btn-secondary mx-1" onclick="downloadProjectsCsv();">Export to CSV</button>
								<div class="d-inline-flex align-items-center flex-wrap mx-1 pb-1">
									<label for="selectionMode" class="mb-0 mr-1">Grid Select:</label>
									<select id="selectionMode" class="data-entry-select d-inline w-auto" title="In Multiple Rows mode, hold Shift while clicking and dragging to select a range of rows." aria-describedby="selectionModeHelp">
										<option value="text">Text</option>
										<option value="cell">Cell(s)</option>
										<option value="singlerow" selected>Single Row</option>
										<option value="multiplerows">Multiple Rows</option>
									</select>
									<span id="selectionModeHelp" class="sr-only">In Multiple Rows mode, hold Shift while clicking and dragging to select a range of rows.</span>
								</div>
								<button type="button" id="copySelectionButton" class="btn btn-xs btn-info mx-1" title="Copy selection to clipboard" onclick="mczCopySelectedFromAllInstances();"><i class="fas fa-copy" aria-hidden="true"></i></button>
								<cfif oneOfUs EQ 1>
									<button type="button" class="btn btn-xs btn-secondary mx-1 mb-1" onclick="populateSaveSearchDialog(); $('#saveSearchDialog').dialog('open');">Save Search</button>
									<div id="saveSearchDialog" title="Save Search" style="display:none;"></div>
								</cfif>
								<output id="actionFeedback" class="mx-1 my-0 h5"></output>
							</div>
						</div>
					</div>
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
	var oneOfUs = #oneOfUsJs#;
	var canManageProjects = #canManageProjectsJs#;
	var pageFilePath = "#cgi.script_name#";
	var savedColumnVisibility = {};
	var projectColumnPinned = true;
	/* Preserved across a selection-mode rebuild the same way projectColumnPinned is --
	   a user's chosen page size is a preference, not something a fresh table build (or a
	   fresh search) should silently reset back to the default. */
	var currentPageSize = 50;
	/* Base page-size choices offered below the largest total seen so far -- a fixed
	   choice larger than the actual result set is redundant with (and more confusing
	   than) the "All" choice already covering that case. mczAdjustProjectsPageSizeOptions
	   filters this list down per search once the real total is known. */
	var PROJECTS_PAGE_SIZE_BASE_OPTIONS = [5, 50, 100];
	/* Started once, up front, rather than inside ensureProjectsTableBuilt -- a
	   coldfusion_user's persisted column choices should be in flight from page load, not
	   only once the user's first search kicks off the fetch. Resolves immediately for
	   everyone else, since there is nothing to fetch. */
	var columnVisibilityPromise = oneOfUs
		? mczFetchColumnVisibility(pageFilePath, "Default").then(function (settings) {
			savedColumnVisibility = settings;
		})
		: $.when();

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

		var columns = [
			{
				title: "Project",
				field: "project_name",
				frozen: projectColumnPinned,
				widthGrow: 3,
				formatter: mczSafeLinkFormatter("project_name", function (d) {
					return "/ProjectDetail.cfm?project_id=" + encodeURIComponent(d.project_id);
				}, "text-primary"),
				/* CSV export gets the plain project name, not the rendered <a> markup. */
				accessorDownload: function (value, data) {
					return data.project_name;
				}
			},
			{ title: "Participants", field: "participants", widthGrow: 2, formatter: mczSafeTextFormatter },
			{ title: "Sponsor(s)", field: "sponsors", widthGrow: 2, formatter: mczSafeTextFormatter },
			{ title: "Start Date", field: "start_date", width: 110, formatter: mczSafeTextFormatter },
			{ title: "End Date", field: "end_date", width: 110, formatter: mczSafeTextFormatter }
		];

		if (canManageProjects) {
			columns.push({
				title: "Edit",
				field: "project_id",
				width: 80,
				headerSort: false,
				download: false,
				formatter: function (cell) {
					var d = cell.getRow().getData();
					var a = document.createElement("a");
					a.className = "btn-xs btn-outline-primary";
					a.href = "/Project.cfm?Action=editProject&project_id=" + encodeURIComponent(d.project_id);
					a.textContent = "Edit";
					return a;
				}
			});
		}

		/* Apply any persisted show/hide choices (see columnVisibilityPromise above, which
		   ensureProjectsTableBuilt waits on before the first call here) up front, rather
		   than building with defaults and correcting afterward. */
		columns.forEach(function (col) {
			if (savedColumnVisibility.hasOwnProperty(col.field)) {
				col.visible = !savedColumnVisibility[col.field];
			}
		});

		var options = {
			/* No height set -- an explicit height (or Tabulator's own default) gives the
			   grid its own internal scrollbar. Paging below means a "page" is always a
			   small, fixed number of rows, so the table can size to its content and let
			   the browser's own page scroll handle anything taller than the viewport. */
			layout: "fitColumns",
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
			paginationSize: currentPageSize,
			paginationSizeSelector: PROJECTS_PAGE_SIZE_BASE_OPTIONS.concat([true]),
			/* Tabulator's own built-in "rows" counter preset ("Showing 1-50 of 173
			   rows"), rather than a custom one -- this app has no existing convention of
			   its own to match here. */
			paginationCounter: "rows"
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
		}
		/* mode === "text": no selection module enabled. Native text selection needs the
		   mcz-text-select-mode class below too -- see tabulator_overrides.css. */

		$("##projectsGridDiv").toggleClass("mcz-text-select-mode", mode === "text");
		$("##projectsGridDiv").toggleClass("mcz-row-select-mode", mode === "singlerow" || mode === "multiplerows");
		/* Copy Selection has nothing to do in "text" mode -- native selection/copy
		   already works there on its own (once selected), with no Tabulator-tracked
		   row or range selection for this button to act on. */
		$("##copySelectionButton").toggle(mode !== "text");
		projectsTable = new Tabulator("##projectsGridDiv", options);
		mczRegisterTabulatorInstance(projectsTable);
		mczPreventSelectRangeNativeSelection(projectsTable);
		projectsTable.on("tableBuilt", populateColumnChooser);
		projectsTable.on("pageSizeChanged", function (size) {
			currentPageSize = size;
		});
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
	 * @return a Promise resolving to {data, last_page, last_row} on success.
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
		return $.ajax({
			url: url,
			data: requestData,
			dataType: "json"
		}).done(function (response) {
			$("##overlay").hide();
			mczHandleProjectsSearchResponse(response);
		}).fail(function (jqXHR, status, error) {
			$("##overlay").hide();
			handleFail(jqXHR, status, error, "searching for projects");
		});
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
		$("##resultsToolbarControls").show();
		mczAdjustProjectsPageSizeOptions(totalRows);
	}

	/**
	 * mczAdjustProjectsPageSizeOptions drops any fixed page-size choice larger than the
	 * current result set, so the dropdown never offers e.g. "500" alongside "All" when
	 * there are only 173 matching rows -- confusing, since picking either shows the same
	 * thing. Reaches into table.modules.page directly (confirmed against source): there
	 * is no public method for changing paginationSizeSelector after construction.
	 *
	 * @param totalRows total matching row count from the most recent response.
	 */
	function mczAdjustProjectsPageSizeOptions(totalRows) {
		if (!projectsTable || !projectsTable.modules || !projectsTable.modules.page) {
			return;
		}
		var visibleSizes = PROJECTS_PAGE_SIZE_BASE_OPTIONS.filter(function (size) {
			return size <= totalRows;
		});
		visibleSizes.push(true);
		projectsTable.options.paginationSizeSelector = visibleSizes;
		projectsTable.modules.page.generatePageSizeSelectList();
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
			if (!def.title) { return; }
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
		var column = projectsTable.getColumn("project_name");
		column.updateDefinition({ frozen: projectColumnPinned });
	}

	function downloadProjectsCsv() {
		if (projectsTable) {
			projectsTable.download("csv", "projects.csv");
		}
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
		return columnVisibilityPromise.then(function () {
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
		ensureProjectsTableBuilt().then(function () {
			if (tableAlreadyExisted) {
				projectsTable.setPage(1);
			}
		});
	}

	$(document).ready(function () {
		mczEnableClipboardCopy();

		$("##showhide").html(
			'<button class="my-0 border rounded" title="hide search form" ' +
			'onclick="toggleAnySearchForm(\'searchFormDiv\',\'searchFormToggleIcon\');">' +
			'<i id="searchFormToggleIcon" class="fas fa-eye-slash"></i></button>'
		);

		$("##columnChooserDialog").dialog({
			autoOpen: false,
			modal: true,
			width: "auto",
			buttons: (function () {
				var buttons = [];
				if (oneOfUs) {
					buttons.push({
						text: "Defaults",
						click: function () {
							projectsTable.getColumns().forEach(function (column) {
								if (column.getDefinition().title) { column.show(); }
							});
							savedColumnVisibility = {};
							saveColumnVisibilities(pageFilePath, {}, "Default", "actionFeedback");
							populateColumnChooser();
						}
					});
				}
				buttons.push({
					text: "Ok",
					click: function () {
						var hidden = {};
						$("##columnChooserList .columnChooserCheckbox").each(function () {
							var field = $(this).data("field");
							var checked = $(this).is(":checked");
							var column = projectsTable.getColumn(field);
							if (checked) { column.show(); } else { column.hide(); }
							hidden[field] = !checked;
						});
						if (oneOfUs) {
							savedColumnVisibility = hidden;
							saveColumnVisibilities(pageFilePath, hidden, "Default", "actionFeedback");
						}
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
<cfset targetWikiPage = "Search_Projects">
<cfoutput>#renderWikiDrawer(action, targetWikiPage)#</cfoutput>

<cfinclude template = "/shared/_footer.cfm">
