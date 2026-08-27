<!---
/containers/partLocations.cfm

Reports each part of a search result, loan, or deaccession alongside its current storage
location, broken into columns for a caller-chosen, ordered list of container_type names --
configurable rather than a single fixed column set, since different storage hierarchies (e.g.
Freezer/Rack/Box/Tube vs. Room/Fixture/Compartment for dry collections) don't share one shape.

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
<cfparam name="url.result_id" default="">
<cfparam name="url.loan_number" default="">
<cfparam name="url.deacc_number" default="">
<cfparam name="url.transaction_id" default="">
<cfparam name="url.location_types" default="">
<cfparam name="url.execute" default="">
<cfparam name="url.action" default="">


<cfset variables.result_id = trim(url.result_id)>
<cfset variables.loan_number = trim(url.loan_number)>
<cfset variables.deacc_number = trim(url.deacc_number)>
<cfset variables.transaction_id = trim(url.transaction_id)>
<cfset variables.location_types = trim(url.location_types)>
<cfif len(variables.location_types) EQ 0>
	<cfset variables.location_types = "freezer,freezer rack,rack slot,freezer box,cryovial">
</cfif>
<cfset variables.hasInput = (
	len(variables.result_id) GT 0 OR
	len(variables.loan_number) GT 0 OR
	len(variables.deacc_number) GT 0 OR
	len(variables.transaction_id) GT 0
)>

<cfif trim(url.action) EQ "csvDump">
	<!--- csvDump (below) streams a file before the shared header runs, so needs its own <cf_rolecheck> --->
	<cf_rolecheck>
	<cfinclude template="/containers/component/public.cfc" runOnce="true">
	<cfset variables.report = deserializeJSON(getPartLocationsReport(
		result_id = variables.result_id,
		loan_number = variables.loan_number,
		deacc_number = variables.deacc_number,
		transaction_id = variables.transaction_id,
		location_types = variables.location_types
	))>
	<cfset variables.csvColumnNames = "GUID,Part Name,Preserve Method,Lot Count">
	<cfloop array="#variables.report.columns#" index="variables.oneColumnName">
		<cfset variables.csvColumnNames = listAppend(variables.csvColumnNames, variables.oneColumnName)>
	</cfloop>
	<cfset variables.csvQuery = queryNew(variables.csvColumnNames)>
	<cfloop array="#variables.report.rows#" index="variables.oneReportRow">
		<cfset variables.csvRowIndex = queryAddRow(variables.csvQuery)>
		<cfset querySetCell(variables.csvQuery, "GUID", variables.oneReportRow.guid, variables.csvRowIndex)>
		<cfset querySetCell(variables.csvQuery, "Part Name", variables.oneReportRow.part_name, variables.csvRowIndex)>
		<cfset querySetCell(variables.csvQuery, "Preserve Method", variables.oneReportRow.preserve_method, variables.csvRowIndex)>
		<cfset querySetCell(variables.csvQuery, "Lot Count", variables.oneReportRow.display_lot_count, variables.csvRowIndex)>
		<cfloop array="#variables.report.columns#" index="variables.oneColumnName">
			<cfset querySetCell(variables.csvQuery, variables.oneColumnName, variables.oneReportRow[variables.oneColumnName], variables.csvRowIndex)>
		</cfloop>
	</cfloop>
	<cfinclude template="/shared/component/functions.cfc">
	<cfset variables.csv = queryToCSV(variables.csvQuery)>
	<cfheader name="Content-Type" value="text/csv">
	<cfheader name="Content-Disposition" value="attachment; filename=PartLocations.csv">
	<cfoutput>#variables.csv#</cfoutput>
	<cfabort>
</cfif>

<cfset pageTitle = "Containers | Part Locations">
<cfset pageHasContainers = true>
<cfinclude template="/shared/_header.cfm">
<link rel="stylesheet" href="/containers/css/containers.css">

<main id="content" class="container py-3">
	<cfoutput>
	<h1 class="h3">Part Storage Locations</h1>
	<div class="row">
		<div class="col-12">
			<p>
				Reports each part of a search result, loan, or deaccession alongside its current
				storage location. The location columns below are an editable, ordered list of
				container types (root-most first) -- adjust them to match how a given part of the
				collection is actually organized.
			</p>
		</div>
	</div>
	<div class="row">
		<div class="col-12">
			<output id="partLocationsSummary" class="d-block mb-2">&nbsp;</output>
			<div class="form-row align-items-end">
				<div class="col-12 col-md-8 col-lg-9 mb-2">
					<label for="location_types" class="data-entry-label">Location Columns (comma separated, root-most first)</label>
					<input type="text" id="location_types" name="location_types" class="data-entry-input col-12" value="#encodeForHtml(variables.location_types)#">
					<div class="mt-1">
						<button type="button" class="btn btn-xs btn-secondary" onclick="fillLocationTypes('freezer,freezer rack,rack slot,freezer box,cryovial')">Freezer/Rack/Box</button>
						<button type="button" class="btn btn-xs btn-secondary" onclick="fillLocationTypes('freezer,freezer box,cryovial')">Freezer/Box (no rack)</button>
						<button type="button" class="btn btn-xs btn-secondary" onclick="fillLocationTypes('grouping,fixture,compartment')">Dry Storage (Fixture/Compartment)</button>
					</div>
				</div>
				<div class="col-12 col-md-4 col-lg-3 mb-2">
					<button type="button" id="updateReportBtn" class="btn btn-xs btn-primary" onclick="loadPartLocationsReport()">Update</button>
					<a id="downloadCsvLink" class="btn btn-xs btn-secondary" href="##" target="_blank">Download as CSV</a>
				</div>
			</div>
			<div id="partLocationsTableArea">
				<cfif variables.hasInput>
					<div class="my-2 text-center"><img src="/shared/images/indicator.gif"> Loading...</div>
				<cfelse>
					<p class="text-muted">No search, loan, or deaccession specified. Reach this report from a search's Manage page, or a Loan/Deaccession's Storage Locations section.</p>
				</cfif>
			</div>
		</div>
	</div>
	<script>
		/** Sets the Location Columns field to a preset value and reloads the report.
		 * @param {string} value - comma-separated, ordered container_type list.
		 * @returns {void}
		 */
		function fillLocationTypes(value) {
			$('##location_types').val(value);
			loadPartLocationsReport();
		}

		/** Reloads the part-locations report and the Download as CSV link from the current
		 * Location Columns field value.
		 * @returns {void}
		 */
		function loadPartLocationsReport() {
			$('##partLocationsTableArea').html('<div class="my-2 text-center"><img src="/shared/images/indicator.gif"> Loading...</div>');
			var locationTypes = $('##location_types').val();
			$('##downloadCsvLink').attr('href', '/containers/partLocations.cfm?action=csvDump'
				+ '&result_id=' + encodeURIComponent('#encodeForJavaScript(variables.result_id)#')
				+ '&loan_number=' + encodeURIComponent('#encodeForJavaScript(variables.loan_number)#')
				+ '&deacc_number=' + encodeURIComponent('#encodeForJavaScript(variables.deacc_number)#')
				+ '&transaction_id=' + encodeURIComponent('#encodeForJavaScript(variables.transaction_id)#')
				+ '&location_types=' + encodeURIComponent(locationTypes));
			$.ajax({
				url: '/containers/component/public.cfc',
				data: {
					method: 'getPartLocationsReport',
					result_id: '#encodeForJavaScript(variables.result_id)#',
					loan_number: '#encodeForJavaScript(variables.loan_number)#',
					deacc_number: '#encodeForJavaScript(variables.deacc_number)#',
					transaction_id: '#encodeForJavaScript(variables.transaction_id)#',
					location_types: locationTypes
				},
				dataType: 'json',
				success: function(data) {
					renderPartLocationsTable(data);
				},
				error: function(jqXHR, textStatus, error) {
					$('##partLocationsTableArea').html('<p class="text-danger">Unable to load report.</p>');
					handleFail(jqXHR, textStatus, error, 'loading part locations report');
				}
			});
		}

		/** Renders the part-locations report table from getPartLocationsReport's JSON response.
		 * @param {Object} data - {summary, columns, rows} as returned by getPartLocationsReport.
		 * @returns {void}
		 */
		function renderPartLocationsTable(data) {
			$('##partLocationsSummary').text(data.summary);
			if (!data.rows || data.rows.length === 0) {
				$('##partLocationsTableArea').html('<p class="text-muted">No parts to show.</p>');
				return;
			}
			var table = $('<table class="table table-striped table-sm sortable" id="partLocationsTable"></table>');
			var headRow = $('<tr></tr>');
			headRow.append($('<th></th>').text('GUID'));
			headRow.append($('<th></th>').text('Part Name'));
			headRow.append($('<th></th>').text('Preserve Method'));
			headRow.append($('<th></th>').text('Lot Count'));
			$.each(data.columns, function(i, columnName) {
				headRow.append($('<th></th>').text(titleCaseContainerType(columnName)));
			});
			table.append($('<thead></thead>').append(headRow));
			var tbody = $('<tbody></tbody>');
			$.each(data.rows, function(i, row) {
				var tr = $('<tr></tr>');
				var guidCell = $('<td></td>');
				if (row.guid) {
					guidCell.append($('<a target="_blank"></a>').attr('href', row.guid_url).text(row.guid));
				}
				tr.append(guidCell);
				tr.append($('<td></td>').text(row.part_name || ''));
				tr.append($('<td></td>').text(row.preserve_method || ''));
				tr.append($('<td></td>').text(row.display_lot_count || ''));
				$.each(data.columns, function(j, columnName) {
					tr.append($('<td></td>').text(row[columnName] || ''));
				});
				tbody.append(tr);
			});
			table.append(tbody);
			$('##partLocationsTableArea').empty().append(table);
			ts_makeSortable(document.getElementById('partLocationsTable'));
		}

		/** Title-cases a container_type name for display as a column header.
		 * @param {string} value - a container_type name, e.g. "freezer rack".
		 * @returns {string} the title-cased name, e.g. "Freezer Rack".
		 */
		function titleCaseContainerType(value) {
			return value.replace(/\w\S*/g, function(word) {
				return word.charAt(0).toUpperCase() + word.substr(1).toLowerCase();
			});
		}

		$(document).ready(function() {
			<cfif variables.hasInput OR url.execute EQ "true">
				loadPartLocationsReport();
			</cfif>
		});
	</script>
	</cfoutput>
</main>
<cfinclude template="/shared/_footer.cfm">
