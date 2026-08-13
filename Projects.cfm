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
<cfparam name="url.author" default="">
<cfparam name="url.sponsor" default="">
<cfparam name="url.project_type" default="">
<cfparam name="url.year" default="">
<cfparam name="url.descr_len" default="">
<cfparam name="url.publication_id" default="">
<cfparam name="url.project_id" default="">
<cfparam name="url.execute" default="">

<cfset variables.p_title = url.p_title>
<cfset variables.author = url.author>
<cfset variables.sponsor = url.sponsor>
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

<div id="overlaycontainer" style="position: relative;">
	<main id="content">
		<section class="container-fluid" role="search">
			<cftry>
				<cfoutput>#renderWikiButtons(buttonClass="btn btn-xs btn-dark mr-4 border-0")#</cfoutput>
				<cfcatch><cfoutput>Error calling renderWikiButtons: #cfcatch.message#</cfoutput></cfcatch>
			</cftry>
			<div class="row mx-0 mb-3">
				<div class="d-flex flex-wrap mb-0 mx-0 mr-md-3 mr-xl-4 ml-xl-3">
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
												<label for="author" class="data-entry-label">Participant</label>
												<input type="text" id="author" name="author" class="data-entry-input" value="#encodeForHtml(variables.author)#">
											</div>
											<div class="col-12 col-md-6">
												<label for="sponsor" class="data-entry-label">Sponsor</label>
												<input type="text" id="sponsor" name="sponsor" class="data-entry-input" value="#encodeForHtml(variables.sponsor)#">
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
			</div>
		</section>
		<!--- Results table as a Tabulator grid. --->
		<section class="container-fluid">
			<div class="row mx-0">
				<div class="col-12 mb-5 px-0 pr-md-3 pr-xl-4 pl-xl-3">
					<div class="row mt-1 mb-0 border px-2 pt-2 mx-0" style="background-color:#deebec;">
						<h1 class="h4 ml-2 ml-md-1 mt-1 mb-1 px-2 mb-xl-2">
							<span tabindex="0">Results: </span>
							<span class="pr-2 font-weight-normal" id="resultCount"></span>
							<span id="resultLink" class="pr-2 font-weight-normal"></span>
						</h1>
						<div class="col-12 col-md-auto ml-md-auto pb-1">
							<label for="selectionMode" class="mb-0">Selection mode</label>
							<select id="selectionMode" class="data-entry-select">
								<option value="text">Text select</option>
								<option value="singlecell">Single cell</option>
								<option value="singlerow" selected>Single row</option>
								<option value="multiplerows">Multiple rows</option>
								<option value="multiplecells">Multiple cells</option>
							</select>
							<button type="button" class="btn btn-xs btn-info" onclick="downloadProjectsCsv();">Download CSV</button>
						</div>
					</div>
					<div id="projectsGridDiv">
						<div class="my-2 text-center"><img src="/shared/images/indicator.gif" alt=""> Loading...</div>
					</div>
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
	var canManageProjects = #canManageProjectsJs#;

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
	 * @param mode one of "text", "singlecell", "singlerow", "multiplerows", "multiplecells".
	 */
	function buildProjectsTable(mode) {
		if (projectsTable) {
			projectsTable.destroy();
			projectsTable = null;
		}

		var columns = [
			{
				title: "Project",
				field: "project_name",
				frozen: true,
				widthGrow: 3,
				formatter: mczSafeLinkFormatter("project_name", function (d) {
					return "/ProjectDetail.cfm?project_id=" + encodeURIComponent(d.project_id);
				}, "text-primary"),
				/* CSV export gets the plain project name, not the rendered <a> markup. */
				accessorDownload: function (value, data) {
					return data.project_name;
				},
				headerMenu: function (e, column) {
					return mczColumnVisibilityMenu(column.getTable());
				}
			},
			{ title: "Participants", field: "participants", widthGrow: 2, formatter: mczSafeTextFormatter },
			{ title: "Sponsor(s)", field: "sponsors", widthGrow: 2, formatter: mczSafeTextFormatter },
			{ title: "Start Date", field: "start_date", width: 110, formatter: mczSafeTextFormatter },
			{ title: "End Date", field: "end_date", width: 110, formatter: mczSafeTextFormatter }
		];

		/* Only given a column definition at all when canManageProjects -- getColumns()
		   (which the headerMenu column-visibility chooser above calls) returns every
		   column regardless of its visible setting, so a column merely hidden with
		   visible:false is still listed there and can be toggled back on by anyone. */
		if (canManageProjects) {
			columns.push({
				title: "Edit",
				field: "project_id",
				width: 80,
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

		var options = {
			height: "500px",
			layout: "fitColumns",
			persistence: { columns: true, sort: true },
			persistenceID: "projectsSearchGrid_v1",
			placeholder: "No projects matched your search.",
			data: [],
			/* Frozen column listed first -- Tabulator logs a warning if a frozen column
			   isn't at index 0 when range-select is enabled. */
			columns: columns
		};

		if (mode === "singlecell" || mode === "multiplecells") {
			options.selectableRangeColumns = true;
			options.selectableRangeRows = true;
			/* selectableRange is a max-concurrent-ranges count, not a max-cells-per-range
			   limit -- "single cell" here means "one range at a time" (a user can still drag
			   that one range across multiple cells). */
			options.selectableRange = (mode === "singlecell") ? 1 : true;
		} else if (mode === "singlerow" || mode === "multiplerows") {
			options.selectableRows = (mode === "multiplerows") ? true : 1;
		}
		/* mode === "text": no selection module enabled, native text selection works normally. */

		projectsTable = new Tabulator("##projectsGridDiv", options);
		mczRegisterTabulatorInstance(projectsTable);
	}

	function downloadProjectsCsv() {
		if (projectsTable) {
			projectsTable.download("csv", "projects.csv");
		}
	}

	/** searchProjects submits #searchForm via ajax to projects/component/search.cfc and
	 * replaces the grid's data with the response.
	 */
	function searchProjects() {
		$("##overlay").show();
		$.ajax({
			url: "/projects/component/search.cfc",
			data: $("##searchForm").serialize(),
			dataType: "json",
			success: function (data) {
				$("##overlay").hide();
				projectsTable.setData(data);
				$("##resultCount").text(data.length + " result(s)");
				$("##resultLink").html('<a href="/Projects.cfm?execute=true&' +
					$("##searchForm :input").filter(function (index, element) { return $(element).val() != ""; })
						.not(".excludeFromLink").serialize() + '">Link to this search</a>');
			},
			error: function (jqXHR, status, error) {
				$("##overlay").hide();
				handleFail(jqXHR, status, error, "searching for projects");
			}
		});
	}

	$(document).ready(function () {
		buildProjectsTable($("##selectionMode").val());
		$("##selectionMode").on("change", function () {
			buildProjectsTable($(this).val());
			searchProjects();
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
