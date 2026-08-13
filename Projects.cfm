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

<cfset oneOfUsJs = "false">
<cfif oneOfUs EQ 1>
	<cfset oneOfUsJs = "true">
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
											<label for="author" class="data-entry-label">Participant</label>
											<input type="text" id="author" name="author" class="data-entry-input" value="#encodeForHtml(variables.author)#">
											<script>
												$(document).ready(function () {
													makeProjectParticipantSearchAutocomplete("author");
												});
											</script>
										</div>
										<div class="col-12 col-md-6">
											<label for="sponsor" class="data-entry-label">Sponsor</label>
											<input type="text" id="sponsor" name="sponsor" class="data-entry-input" value="#encodeForHtml(variables.sponsor)#">
											<script>
												$(document).ready(function () {
													makeProjectSponsorSearchAutocomplete("sponsor");
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
					<div class="row mt-1 mb-0 border px-2 pt-2 mx-0 align-items-center" style="background-color:##deebec;">
						<h1 class="h4 ml-2 ml-md-1 mt-1 mb-1 px-2 mb-xl-2">
							<span tabindex="0">Results: </span>
							<span class="pr-2 font-weight-normal" id="resultCount"></span>
							<span id="resultLink" class="pr-2 font-weight-normal"></span>
						</h1>
						<div id="showhide"></div>
						<button type="button" class="btn btn-xs btn-secondary mx-1" onclick="$('##columnChooserDialog').dialog('open');">Select Columns</button>
						<div id="columnChooserDialog" title="Show/Hide Columns" style="display:none;">
							<div id="columnChooserList" class="px-1"></div>
						</div>
						<button type="button" class="btn btn-xs btn-secondary mx-1" onclick="togglePinProjectColumn();">Pin Project Column</button>
						<button type="button" class="btn btn-xs btn-info mx-1" onclick="downloadProjectsCsv();">Export to CSV</button>
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
							<button type="button" class="btn btn-xs btn-secondary mx-1 mb-1" onclick="populateSaveSearchDialog(); $('##saveSearchDialog').dialog('open');">Save Search</button>
							<div id="saveSearchDialog" title="Save Search" style="display:none;"></div>
						</cfif>
						<output id="actionFeedback" class="mx-1 my-0 h5"></output>
					</div>
					<div id="projectsGridDiv">
						<div class="my-2 text-center"><img src="/shared/images/indicator.gif" alt=""> Loading...</div>
					</div>
				</div>
			</div>
		</section>
	</main>

	<div id="overlay" style="position: absolute; top:0px; left:0px; width: 100%; height: 100%; background: rgba(0,0,0,0.5); border-color: transparent; opacity: 0.99; display: none; z-index: 2;">
		<div style="position: absolute; left: 50%; top: 25%; width: 10em; padding: 5px; background-color: ##fff; border: 1px solid ##898989; border-radius: 4px; margin-left: -5em;">
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
	/* Distinguishes "no search attempted yet" from "search ran, found nothing" -- the
	   grid's placeholder text below should stay blank until a search has actually run,
	   rather than claiming "no projects matched" before the user has searched at all. */
	var searchHasRun = false;

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

		/* Apply any persisted show/hide choices (see mczFetchColumnVisibility, called
		   before the first build in $(document).ready below) up front, rather than
		   building with defaults and correcting afterward. */
		columns.forEach(function (col) {
			if (savedColumnVisibility.hasOwnProperty(col.field)) {
				col.visible = !savedColumnVisibility[col.field];
			}
		});

		var options = {
			height: "500px",
			layout: "fitColumns",
			persistence: { sort: true },
			persistenceID: "projectsSearchGrid_v1",
			placeholder: searchHasRun ? "No projects matched your search." : "",
			data: [],
			/* Frozen column listed first -- Tabulator logs a warning if a frozen column
			   isn't at index 0 when range-select is enabled. */
			columns: columns
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

	/** searchProjects submits searchForm via ajax to projects/component/search.cfc and
	 * replaces the grid's data with the response.
	 */
	function searchProjects() {
		searchHasRun = true;
		$("##overlay").show();
		$("##actionFeedback").html("");
		$.ajax({
			url: "/projects/component/search.cfc",
			data: $("##searchForm").serialize(),
			dataType: "json",
			success: function (data) {
				$("##overlay").hide();
				projectsTable.setData(data);
				$("##resultCount").text("Found " + data.length + " project record" + (data.length === 1 ? "" : "s") + ".");
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

		function buildInitialTable() {
			var $selectionMode = $("##selectionMode");
			buildProjectsTable($selectionMode.length ? $selectionMode.val() : "text");
			<cfif len(url.execute) GT 0>
				$("##searchForm").submit();
			</cfif>
		}

		if (oneOfUs) {
			mczFetchColumnVisibility(pageFilePath, "Default").then(function (settings) {
				savedColumnVisibility = settings;
				buildInitialTable();
			});
		} else {
			buildInitialTable();
		}

		$("##selectionMode").on("change", function () {
			buildProjectsTable($(this).val());
			searchProjects();
		});
		$("##searchForm").on("submit", function (e) {
			e.preventDefault();
			searchProjects();
		});
	});
</script>
</cfoutput>

<script src="/shared/js/wikiDrawer.js"></script>
<cfset targetWikiPage = "Search_Projects">
<cfoutput>#renderWikiDrawer(action, targetWikiPage)#</cfoutput>

<cfinclude template = "/shared/_footer.cfm">
