<cfset pageTitle = "Tabulator Compatibility Spike">
<!---
projects/tabulatorSpike.cfm

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
TEMPORARY compatibility-verification page (jqxGrid -> Tabulator).

Not a production page, and deliberately not named per the search/details/edit
conventions in documentation/README.md for that reason. Exercises, in one place, the
following Tabulator capabilities the Projects search grid needs:

  - runtime switch between 5 selection modes: text select (native) / single cell /
    single row / multiple rows / multiple cells (range)
  - a frozen (pinned) column
  - persisted column visibility (Persistence module)
  - a column whose on-screen display (formatter) differs from its CSV export
    value (accessorDownload)
  - responsive redraw triggered by the wiki-help sidebar drawer toggling width

Delete this file once its findings are folded into /shared/js/.
--->
<cfset action = "search">
<cfinclude template = "/shared/_header.cfm">
<cfif not (isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user"))>
	<cfinclude template="/errors/404.cfm">
	<cfabort>
</cfif>
<link rel="stylesheet" href="/lib/Tabulator/tabulator_ver6.5.2/css/tabulator_bootstrap4.min.css">
<link rel="stylesheet" href="/shared/css/tabulator_overrides.css">
<script src="/lib/Tabulator/tabulator_ver6.5.2/js/tabulator.min.js"></script>
<script src="/shared/js/tabulator-common.js"></script>

<main class="container py-3" id="content">
	<section class="row border rounded my-2">
		<div class="col-12 d-flex justify-content-between align-items-center">
			<h1 class="h2">Tabulator compatibility spike <small class="text-danger">(temporary, coldfusion_user only, not linked from navigation)</small></h1>
			<cfoutput>#renderWikiButtons(buttonClass="btn btn-xs btn-info")#</cfoutput>
		</div>
		<div class="col-12">
			<fieldset class="my-0 px-2 pb-1 border-top border-right border-bottom border-left field-set">
				<legend class="h6 mb-0 px-3 border-top border-right border-bottom border-left field-set-legend bg-teal font-weight-bold w-auto">Selection mode</legend>
				<div class="form-row pt-2">
					<div class="col-12 col-md-6">
						<label for="selectionMode">Mode</label>
						<select id="selectionMode" name="selectionMode" class="data-entry-select mb-2">
							<option value="text">Text select (native browser selection, no grid interception)</option>
							<option value="singlecell">Single cell</option>
							<option value="singlerow" selected>Single row</option>
							<option value="multiplerows">Multiple rows</option>
							<option value="multiplecells">Multiple cells (range)</option>
						</select>
					</div>
					<div class="col-12 col-md-6">
						<button type="button" class="btn btn-xs btn-secondary" onclick="downloadSpikeCsv();">Download CSV (verify formatter vs. accessorDownload)</button>
					</div>
				</div>
			</fieldset>
			<p class="text-secondary small mt-2">
				Use the "Show Help" button above to open the wiki-help drawer -- this is the real
				<code>shared/js/wikiDrawer.js</code> drawer, not a simulation. Opening/closing it must
				trigger <code>resizeAllGridsToContent()</code> and the grid below must redraw at the
				new width without a manual page reload.
			</p>
			<div class="col-12" id="spikeTableDiv"></div>
		</div>
	</section>
</main>

<cfoutput>
<script>
	var spikeTable = null;

	/**
	 * buildSpikeTable creates (or recreates) the Tabulator instance for a given selection mode.
	 * Tabulator reads its selection options only at initialization and does not react to
	 * later changes, so switching modes means building a new instance rather than updating
	 * an existing one.
	 *
	 * Tabulator's SelectRange (cell/range selection) and row-selection are mutually
	 * exclusive on one instance -- enabling both logs a warning and leaves SelectRange
	 * uninitialized -- so each mode below sets only one of the two.
	 *
	 * @param mode one of "text", "singlecell", "singlerow", "multiplerows", "multiplecells".
	 */
	function buildSpikeTable(mode) {
		if (spikeTable) {
			spikeTable.destroy();
			spikeTable = null;
		}

		var options = {
			height: "260px",
			layout: "fitColumns",
			persistence: { columns: true, sort: true },
			persistenceID: "tabulatorSpike_v1",
			data: [
				{ id: 1, project_name: "Deep Sea Isopoda Systematics", agent_name: "Jane Doe", role: "PI", start_date: "2020-01-01" },
				{ id: 2, project_name: "Amazonian Herpetofauna Survey", agent_name: "John Smith", role: "Co-PI", start_date: "2021-06-15" },
				{ id: 3, project_name: "Arctic Bird Migration Tracking", agent_name: "A. Lee", role: "Collaborator", start_date: "2019-09-01" },
				{ id: 4, project_name: "Coral Reef Biodiversity", agent_name: "M. Alvarez", role: "PI", start_date: "2022-03-10" }
			],
			/* Frozen column is listed FIRST -- Tabulator warns of "unpredictable behavior"
			   if a frozen column isn't at index 0 when range-select is enabled. */
			columns: [
				{ title: "Project", field: "project_name", frozen: true, widthGrow: 3, formatter: mczSafeTextFormatter },
				{
					title: "ID",
					field: "id",
					width: 60,
					/* Column-visibility chooser lives on one column via the built-in headerMenu
					   API -- a per-column function, invoked fresh each time the menu opens,
					   returning {label, action(e, column)} items. */
					headerMenu: function (e, column) {
						return mczColumnVisibilityMenu(column.getTable());
					}
				},
				{
					title: "Participant",
					field: "agent_name",
					widthGrow: 2,
					/* Combines agent_name + role into one styled cell, matching the jqxGrid
					   cellsrenderer pattern used for the same data today -- built as DOM nodes
					   with textContent rather than an HTML string, since Tabulator's string-
					   formatter path sets innerHTML directly (see mczSafeTextFormatter in
					   tabulator-common.js). */
					formatter: function (cell) {
						var d = cell.getRow().getData();
						var wrap = document.createElement("span");
						var name = document.createElement("span");
						name.className = "font-weight-bold";
						name.textContent = d.agent_name;
						var role = document.createElement("span");
						role.className = "text-secondary small";
						role.textContent = " (" + d.role + ")";
						wrap.appendChild(name);
						wrap.appendChild(role);
						return wrap;
					},
					/* CSV export: plain "Name (Role)" text, not the rendered HTML -- this is the
					   divergence being verified. */
					accessorDownload: function (value, data) {
						return data.agent_name + " (" + data.role + ")";
					}
				},
				{ title: "Start Date", field: "start_date", formatter: mczSafeTextFormatter }
			]
		};

		if (mode === "singlecell" || mode === "multiplecells") {
			options.selectableRangeColumns = true;
			options.selectableRangeRows = true;
			/* selectableRange means "max concurrent ranges", not "max cells per range" --
			   there is no built-in option to cap a single range at exactly one cell, so
			   "single cell" here means "one range at a time", and a user can still drag
			   that one range across multiple cells. True single-cell-only selection would
			   need a range-changed handler to clamp the drag; not built here. */
			options.selectableRange = (mode === "singlecell") ? 1 : true;
		} else if (mode === "singlerow" || mode === "multiplerows") {
			options.selectableRows = (mode === "multiplerows") ? true : 1;
		}
		/* mode === "text": no selection module enabled at all, so mousedown/drag is never
		   intercepted by Tabulator and native text selection inside a cell works normally. */

		spikeTable = new Tabulator("##spikeTableDiv", options);
		mczRegisterTabulatorInstance(spikeTable);
	}

	function downloadSpikeCsv() {
		if (spikeTable) {
			spikeTable.download("csv", "tabulator_spike.csv");
		}
	}

	$(document).ready(function () {
		buildSpikeTable($("##selectionMode").val());
		$("##selectionMode").on("change", function () {
			buildSpikeTable($(this).val());
		});
	});
</script>
</cfoutput>

<script src="/shared/js/wikiDrawer.js"></script>
<cfset targetWikiPage = "Tabulator_Spike">
<cfoutput>#renderWikiDrawer(action, targetWikiPage)#</cfoutput>

<cfinclude template = "/shared/_footer.cfm">
