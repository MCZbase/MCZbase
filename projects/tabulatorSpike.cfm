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
TEMPORARY compatibility-verification page for Redmine 1023 (jqxGrid -> Tabulator).

Not a production page, and deliberately not named per the search/details/edit
conventions in documentation/README.md for that reason. Exercises, in one place,
every capability the Projects search grid (and every future concept's redesigned
grid) needs from Tabulator before the shared foundation in /shared/js/ is built
on top of these assumptions:

  - runtime switch between 5 selection modes: text select (native) / single cell /
    single row / multiple rows / multiple cells (range)
  - a frozen (pinned) column
  - persisted column visibility (Persistence module)
  - a column whose on-screen display (formatter) differs from its CSV export
    value (accessorDownload) -- proves combined-column cell renderers don't leak
    into the CSV download
  - responsive redraw triggered by the real wiki-help sidebar drawer toggling
    width, not just page load

Delete this file once the shared foundation (Phase 2 of the Project/Tabulator
redesign) lands and its findings are folded into /shared/js/.
--->
<cfset action = "search">
<cfinclude template = "/shared/_header.cfm">
<cfif not (isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user"))>
	<cfinclude template="/errors/404.cfm">
	<cfabort>
</cfif>
<link rel="stylesheet" href="/lib/Tabulator/tabulator_ver6.5.2/css/tabulator_bootstrap4.min.css">
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
	 * buildSpikeTable creates (or recreates) the spike Tabulator instance for a given selection mode.
	 * Recreation via destroy()+new Tabulator(...) is used instead of mutating a live table's options,
	 * since Tabulator's selection modules are documented as init-time configuration -- this is the
	 * one property of the spike this page exists to confirm is actually necessary versus a nicer
	 * live-mutation approach; don't assume the nicer path works without checking here first.
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
			columns: [
				{ title: "ID", field: "id", width: 60 },
				{ title: "Project", field: "project_name", frozen: true, widthGrow: 3 },
				{
					title: "Participant",
					field: "agent_name",
					widthGrow: 2,
					/* on-screen: combines agent_name + role into one styled cell, matching the
					   jqxGrid cellsrenderer pattern used for the same data today. */
					formatter: function (cell) {
						var d = cell.getRow().getData();
						return "<span class=\"font-weight-bold\">" + d.agent_name + "</span> " +
							"<span class=\"text-secondary small\">(" + d.role + ")</span>";
					},
					/* CSV export: plain "Name (Role)" text, not the rendered HTML -- this is the
					   divergence being verified. */
					accessorDownload: function (value, data) {
						return data.agent_name + " (" + data.role + ")";
					}
				},
				{ title: "Start Date", field: "start_date" }
			]
		};

		if (mode === "singlecell" || mode === "multiplecells") {
			options.selectableRange = true;
			options.selectableRangeColumns = true;
			options.selectableRangeRows = true;
			options.selectableRangeMode = "click";
			if (mode === "singlecell") {
				options.selectableRangeMaxRows = 1;
				options.selectableRangeMaxColumns = 1;
			}
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
