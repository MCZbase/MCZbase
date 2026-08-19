<!---
/containers/bulkModifyContainers.cfm

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

Bulk-retypes (and optionally updates the description/remark/dimensions of) a series of existing
containers identified by a shared barcode prefix and a contiguous integer range. Replaces
/labels2containers.cfm. A five-step self-posting flow: entryPoint (pick the range) -> preview
(report what's actually in the range) -> dataEntry (choose the changes) -> test (optional dry run,
validated per container) -> apply (commit, skipping any container whose retype is blocked).
--->
<cf_rolecheck>
<cfparam name="form.formAction" default="">
<cfparam name="form.origContType" default="">
<cfparam name="form.barcode_prefix" default="">
<cfparam name="form.begin_barcode" default="">
<cfparam name="form.end_barcode" default="">
<cfparam name="form.newContType" default="">
<cfparam name="form.description" default="">
<cfparam name="form.description_mode" default="overwrite">
<cfparam name="form.container_remarks" default="">
<cfparam name="form.container_remarks_mode" default="overwrite">
<cfparam name="form.height" default="">
<cfparam name="form.length" default="">
<cfparam name="form.width" default="">
<cfparam name="form.number_positions" default="">

<cfset variables.action = "entryPoint">
<cfif len(form.formAction) GT 0>
	<cfset variables.action = form.formAction>
</cfif>

<cfset variables.containerFunctions = createObject("component", "containers.component.functions")>

<!--- Validated below, not just used for the dropdowns -- these values later get embedded
	unescaped into an inline <script> block, and serializeJSON won't neutralize a literal
	"</script>" in a tampered form field. --->
<cfset variables.qAllowedTypes = variables.containerFunctions.getBulkRetypeableContainerTypes()>
<cfset variables.allowedTypesList = ValueList(variables.qAllowedTypes.container_type)>

<cfset variables.rangeError = "">
<cfif listFindNoCase("preview,dataEntry,test,apply", variables.action) GT 0>
	<cfif len(trim(form.barcode_prefix)) EQ 0>
		<cfset variables.rangeError = "A Unique ID Prefix is required.">
	<cfelseif NOT isNumeric(form.begin_barcode) OR NOT isNumeric(form.end_barcode)>
		<cfset variables.rangeError = "Low and High Unique ID must both be numbers.">
	<cfelseif val(form.begin_barcode) GT val(form.end_barcode)>
		<cfset variables.rangeError = "Low Unique ID must not be greater than High Unique ID.">
	<cfelseif len(trim(form.origContType)) EQ 0>
		<cfset variables.rangeError = "An Original Container Type is required.">
	<cfelseif NOT listFindNoCase(variables.allowedTypesList, form.origContType)>
		<cfset variables.rangeError = "Original Container Type is not a valid, retypeable container type.">
	</cfif>
	<cfif len(variables.rangeError) EQ 0 AND listFindNoCase("test,apply", variables.action) GT 0>
		<cfif len(trim(form.newContType)) EQ 0>
			<cfset variables.rangeError = "A New Container Type is required.">
		<cfelseif NOT listFindNoCase(variables.allowedTypesList, form.newContType)>
			<cfset variables.rangeError = "New Container Type is not a valid, retypeable container type.">
		</cfif>
	</cfif>
	<cfif len(variables.rangeError) GT 0>
		<cfset variables.action = "entryPoint">
	</cfif>
</cfif>

<cfset pageTitle = "Bulk Modify Containers">
<cfset pageHasContainers = true>
<cfinclude template="/shared/_header.cfm">
<link rel="stylesheet" href="/containers/css/containers.css">

<main id="content" class="container py-3">
	<cfoutput>

	<script>
		/** Render a read-only containers table for the bulk retype tool -- used by both the Enter
		 * Changes page's candidate list and the report page's modified-containers list, which are
		 * two separate page loads, so this is defined unconditionally here rather than inside either
		 * action's own branch below. Styled and using the same per-row action buttons as the Find
		 * Containers search results (containers.js's executeContainerSearch), plus Remarks and a
		 * combined H×L×W Dimensions column that search doesn't show. Not a call into that function
		 * directly -- it's tightly coupled to its own search inputs, panel ids, and tree-browsing
		 * actions (Explore/Browse/Locate) that don't apply to this static review list -- but reuses
		 * its exact button/badge builders.
		 * @param {Array<Object>} rows - containers as returned by getContainersInRange (or the
		 *   resulting-state fields returned by applyBulkRetypeContainer).
		 * @param {string} targetSelector - jQuery selector for the element to render the table into.
		 * @param {string} feedbackId - id of an <output> element for the Details dialog's AJAX status.
		 * @returns {void}
		 */
		function renderBulkModifyCandidateTable(rows, targetSelector, feedbackId) {
			var target = $(targetSelector);
			if (!rows || rows.length === 0) {
				target.html('<p class="text-muted my-2">No containers.</p>');
				return;
			}
			/** A dimension of 0 means "not recorded" for this data, same as blank/null -- not a
			 * real zero-size dimension. An en dash stands in for a missing dimension within the
			 * combined H×L×W column so the position of the one that IS set stays clear. */
			var displayOrBlank = function(value) {
				return (value === null || value === undefined || Number(value) === 0) ? '' : value;
			};
			var formatDimensions = function(row) {
				var h = displayOrBlank(row.height);
				var l = displayOrBlank(row.length);
				var w = displayOrBlank(row.width);
				if (h === '' && l === '' && w === '') {
					return '';
				}
				var partOrDash = function(v) { return v === '' ? '–' : v; };
				return partOrDash(h) + ' × ' + partOrDash(l) + ' × ' + partOrDash(w);
			};
			var table = $('<table class="table table-sm table-striped table-responsive-md"></table>');
			table.append('<thead><tr><th>Type</th><th>Name / Barcode</th><th>Description</th><th>Remarks</th><th>Dimensions (H&times;L&times;W, cm)</th><th>Actions</th></tr></thead>');
			var tbody = $('<tbody></tbody>');
			$.each(rows, function(i, row) {
				var displayName = formatContainerDisplay(row.barcode, row.label);
				var typeTd = $('<td></td>').text(row.container_type || '');
				typeTd.append(' ');
				typeTd.append($(getContainerRoleBadgeHtml(row.container_type)));
				var actionCell = $('<td></td>');
				actionCell.append(buildContainerDetailsActionButton(row.container_id, displayName, feedbackId));
				actionCell.append(buildContainerViewLink(row.container_id));
				actionCell.append(buildContainerEditLink(row.container_id));
				var tr = $('<tr></tr>');
				tr.append(typeTd);
				tr.append($('<td></td>').text(displayName));
				tr.append($('<td></td>').text(row.description || ''));
				tr.append($('<td></td>').text(row.container_remarks || ''));
				tr.append($('<td></td>').text(formatDimensions(row)));
				tr.append(actionCell);
				tbody.append(tr);
			});
			table.append(tbody);
			target.empty().append(table);
		}
	</script>

	<cfif len(variables.rangeError) GT 0>
		<section class="row mx-0">
			<div class="col-12">
				<div class="alert alert-danger" role="alert">#encodeForHtml(variables.rangeError)#</div>
			</div>
		</section>
	</cfif>

	<cfif variables.action EQ "entryPoint">
		<section class="row mx-0 border rounded my-2 pt-2 mb-4" aria-labelledby="bulkModifyHeading">
			<div class="col-12">
				<h1 class="h2 ml-1 mb-1" id="bulkModifyHeading">Bulk Modify Containers</h1>
				<p class="small text-muted">
					Retype (and optionally update the description, remark, or dimensions of) a series of
					existing containers whose unique identifiers share one literal prefix and a contiguous
					integer range &mdash; for example barcodes <code>MCZ-ENT1001</code> through
					<code>MCZ-ENT1250</code>. This tool does not create containers, and it can't be used
					for an arbitrary or non-sequential list of barcodes; for that, edit containers
					individually, or use one of the bulkloaders under Tools. Each container is checked
					and updated individually, so a request covering more than a few hundred containers
					at once risks hitting the page's request timeout before finishing &mdash; split a
					larger range into a few hundred at a time.
				</p>
				<form class="col-12 px-0" name="bulkModifyEntry" id="bulkModifyEntry" method="post" action="/containers/bulkModifyContainers.cfm">
					<input type="hidden" name="formAction" value="preview">
					<div class="form-row">
						<div class="col-12 col-md-4 mb-2">
							<label for="origContType" class="data-entry-label">Original Container Type</label>
							<select name="origContType" id="origContType" class="data-entry-select col-12 reqdClr" required aria-required="true">
								<option value=""></option>
								<cfloop query="variables.qAllowedTypes">
									<cfset variables.selected = "">
									<cfif variables.qAllowedTypes.container_type EQ form.origContType>
										<cfset variables.selected = "selected">
									</cfif>
									<option value="#encodeForHtml(variables.qAllowedTypes.container_type)#" #variables.selected#>#encodeForHtml(variables.qAllowedTypes.container_type)#</option>
								</cfloop>
							</select>
						</div>
						<div class="col-12 col-md-3 mb-2">
							<label for="barcode_prefix" class="data-entry-label">Unique ID Prefix</label>
							<input type="text" name="barcode_prefix" id="barcode_prefix" class="data-entry-input col-12" aria-describedby="barcodePrefixHelp" value="#encodeForHtml(form.barcode_prefix)#">
							<small id="barcodePrefixHelp" class="text-muted">Include spaces or leading zeros if they are part of every identifier in the range.</small>
						</div>
						<div class="col-6 col-md-2 mb-2">
							<label for="begin_barcode" class="data-entry-label">Low Unique ID</label>
							<input type="number" name="begin_barcode" id="begin_barcode" class="data-entry-input col-12 reqdClr" required aria-required="true" value="#encodeForHtml(form.begin_barcode)#">
						</div>
						<div class="col-6 col-md-2 mb-2">
							<label for="end_barcode" class="data-entry-label">High Unique ID</label>
							<input type="number" name="end_barcode" id="end_barcode" class="data-entry-input col-12 reqdClr" required aria-required="true" value="#encodeForHtml(form.end_barcode)#">
						</div>
					</div>
					<div class="form-row mb-2">
						<div class="col-12">
							<button type="submit" class="btn btn-xs btn-primary">Analyze Range</button>
						</div>
					</div>
				</form>
			</div>
		</section>

	<cfelseif variables.action EQ "preview">
		<cfset variables.preview = variables.containerFunctions.previewBulkRetypeRange(barcode_prefix=form.barcode_prefix, begin_barcode=val(form.begin_barcode), end_barcode=val(form.end_barcode))>
		<cfset variables.matchingOrigTypeCount = 0>
		<cfset variables.otherTypesCount = 0>
		<cfloop array="#variables.preview.typeCounts#" index="variables.typeRow">
			<cfif variables.typeRow.container_type EQ form.origContType>
				<cfset variables.matchingOrigTypeCount = variables.typeRow.type_count>
			<cfelse>
				<cfset variables.otherTypesCount = variables.otherTypesCount + variables.typeRow.type_count>
			</cfif>
		</cfloop>
		<cfset variables.eligibleContainers = variables.containerFunctions.getContainersInRange(barcode_prefix=form.barcode_prefix, begin_barcode=val(form.begin_barcode), end_barcode=val(form.end_barcode), orig_container_type=form.origContType)>
		<cfset variables.propertySummary = variables.containerFunctions.summarizeContainerProperties(variables.eligibleContainers)>
		<cfset variables.descriptionPlural = "">
		<cfif variables.propertySummary.descriptionDistinctCount NEQ 1>
			<cfset variables.descriptionPlural = "s">
		</cfif>
		<cfset variables.descriptionExampleText = ":">
		<cfif variables.propertySummary.descriptionDistinctCount GT ArrayLen(variables.propertySummary.descriptionExamples)>
			<cfset variables.descriptionExampleText = "; for example:">
		</cfif>
		<cfset variables.remarksPlural = "">
		<cfif variables.propertySummary.remarksDistinctCount NEQ 1>
			<cfset variables.remarksPlural = "s">
		</cfif>
		<cfset variables.remarksExampleText = ":">
		<cfif variables.propertySummary.remarksDistinctCount GT ArrayLen(variables.propertySummary.remarksExamples)>
			<cfset variables.remarksExampleText = "; for example:">
		</cfif>
		<section class="row mx-0 border rounded my-2 py-2 mb-4" aria-labelledby="previewHeading">
			<div class="col-12">
				<h1 class="h2 ml-1 mb-1" id="previewHeading">Range Analysis</h1>
				<p>
					Range <strong>#encodeForHtml(form.barcode_prefix)##encodeForHtml(form.begin_barcode)#</strong>
					through <strong>#encodeForHtml(form.barcode_prefix)##encodeForHtml(form.end_barcode)#</strong>
					(#variables.preview.rangeSize# unique identifiers).
				</p>
				<ul>
					<li><strong>#variables.matchingOrigTypeCount#</strong> container(s) match the declared Original Container Type (#encodeForHtml(form.origContType)#) and are eligible to be changed.</li>
					<li><strong>#variables.preview.missingCount#</strong> of the generated unique identifiers have no matching container at all.</li>
					<li><strong>#variables.otherTypesCount#</strong> container(s) exist in this range but are a different type than declared.</li>
				</ul>
				<cfif ArrayLen(variables.preview.typeCounts) GT 1>
					<div class="alert alert-warning" role="alert">
						This range is not made up of a single container type. Breakdown of what was actually found:
						<ul class="mb-0">
							<cfloop array="#variables.preview.typeCounts#" index="variables.typeRow">
								<li>#encodeForHtml(variables.typeRow.container_type)#: #variables.typeRow.type_count#</li>
							</cfloop>
						</ul>
					</div>
				</cfif>
				<cfif variables.preview.missingCount GT 0 AND ArrayLen(variables.preview.missingBarcodes) GT 0>
					<div class="alert alert-secondary" role="alert">
						Unique identifiers with no matching container:
						#encodeForHtml(ArrayToList(variables.preview.missingBarcodes, ", "))#
						<cfif variables.preview.missingBarcodesTruncated> (showing the first 100)</cfif>
					</div>
				</cfif>
				<cfif variables.matchingOrigTypeCount GT 0>
					<div class="mb-3">
						<h2 class="h5 mb-1">Properties of the Matched Container(s)</h2>
						<ul class="mb-0">
							<li>#variables.propertySummary.heightCount# of #variables.propertySummary.totalCount# have a height</li>
							<li>#variables.propertySummary.widthCount# of #variables.propertySummary.totalCount# have a width</li>
							<li>#variables.propertySummary.lengthCount# of #variables.propertySummary.totalCount# have a length</li>
							<li>
								#variables.propertySummary.descriptionCount# of #variables.propertySummary.totalCount# have a description
								<cfif variables.propertySummary.descriptionCount GT 0>
									(#variables.propertySummary.descriptionDistinctCount# distinct value#variables.descriptionPlural##variables.descriptionExampleText#
									<cfloop from="1" to="#ArrayLen(variables.propertySummary.descriptionExamples)#" index="variables.exIdx">
										"#encodeForHtml(variables.propertySummary.descriptionExamples[variables.exIdx])#"
										<cfif variables.exIdx LT ArrayLen(variables.propertySummary.descriptionExamples)>,</cfif>
									</cfloop>)
								</cfif>
							</li>
							<li>
								#variables.propertySummary.remarksCount# of #variables.propertySummary.totalCount# have a remark
								<cfif variables.propertySummary.remarksCount GT 0>
									(#variables.propertySummary.remarksDistinctCount# distinct value#variables.remarksPlural##variables.remarksExampleText#
									<cfloop from="1" to="#ArrayLen(variables.propertySummary.remarksExamples)#" index="variables.exIdx">
										"#encodeForHtml(variables.propertySummary.remarksExamples[variables.exIdx])#"
										<cfif variables.exIdx LT ArrayLen(variables.propertySummary.remarksExamples)>,</cfif>
									</cfloop>)
								</cfif>
							</li>
							<li>#variables.propertySummary.positionsCount# of #variables.propertySummary.totalCount# have a number of positions set</li>
						</ul>
					</div>
				</cfif>
				<form method="post" action="/containers/bulkModifyContainers.cfm">
					<input type="hidden" name="origContType" value="#encodeForHtml(form.origContType)#">
					<input type="hidden" name="barcode_prefix" value="#encodeForHtml(form.barcode_prefix)#">
					<input type="hidden" name="begin_barcode" value="#encodeForHtml(form.begin_barcode)#">
					<input type="hidden" name="end_barcode" value="#encodeForHtml(form.end_barcode)#">
					<cfif variables.matchingOrigTypeCount GT 0>
						<button type="submit" name="formAction" value="dataEntry" class="btn btn-xs btn-primary">Continue</button>
					<cfelse>
						<p class="text-danger">No containers in this range currently match the declared Original Container Type. Adjust the range or type and try again.</p>
					</cfif>
					<button type="submit" name="formAction" value="entryPoint" class="btn btn-xs btn-warning ml-1">Start Over</button>
				</form>
			</div>
		</section>

	<cfelseif variables.action EQ "dataEntry">
		<cfset variables.MAX_LISTED_CANDIDATES = 200>
		<cfset variables.eligibleContainers = variables.containerFunctions.getContainersInRange(barcode_prefix=form.barcode_prefix, begin_barcode=val(form.begin_barcode), end_barcode=val(form.end_barcode), orig_container_type=form.origContType)>
		<cfset variables.propertySummary = variables.containerFunctions.summarizeContainerProperties(variables.eligibleContainers)>
		<cfset variables.descriptionPlural = "">
		<cfif variables.propertySummary.descriptionDistinctCount NEQ 1>
			<cfset variables.descriptionPlural = "s">
		</cfif>
		<cfset variables.descriptionExampleText = ":">
		<cfif variables.propertySummary.descriptionDistinctCount GT ArrayLen(variables.propertySummary.descriptionExamples)>
			<cfset variables.descriptionExampleText = "; for example:">
		</cfif>
		<cfset variables.remarksPlural = "">
		<cfif variables.propertySummary.remarksDistinctCount NEQ 1>
			<cfset variables.remarksPlural = "s">
		</cfif>
		<cfset variables.remarksExampleText = ":">
		<cfif variables.propertySummary.remarksDistinctCount GT ArrayLen(variables.propertySummary.remarksExamples)>
			<cfset variables.remarksExampleText = "; for example:">
		</cfif>
		<cfset variables.candidateRowsForDisplay = ArrayNew(1)>
		<cfloop from="1" to="#min(ArrayLen(variables.eligibleContainers), variables.MAX_LISTED_CANDIDATES)#" index="variables.j">
			<cfset ArrayAppend(variables.candidateRowsForDisplay, variables.eligibleContainers[variables.j])>
		</cfloop>
		<section class="row mx-0 border rounded my-2 pt-2 mb-4" aria-labelledby="dataEntryHeading">
			<div class="col-12">
				<h1 class="h2 ml-1 mb-1" id="dataEntryHeading">Enter Changes</h1>
				<p class="small text-muted">Changing #ArrayLen(variables.eligibleContainers)# container(s) of type #encodeForHtml(form.origContType)# in range #encodeForHtml(form.barcode_prefix)##encodeForHtml(form.begin_barcode)#&ndash;#encodeForHtml(form.end_barcode)#.</p>
				<div class="mb-3">
					<h2 class="h5 mb-1">Properties of the Matched Container(s)</h2>
					<ul class="mb-0">
						<li>#variables.propertySummary.heightCount# of #variables.propertySummary.totalCount# have a height</li>
						<li>#variables.propertySummary.widthCount# of #variables.propertySummary.totalCount# have a width</li>
						<li>#variables.propertySummary.lengthCount# of #variables.propertySummary.totalCount# have a length</li>
						<li>
							#variables.propertySummary.descriptionCount# of #variables.propertySummary.totalCount# have a description
							<cfif variables.propertySummary.descriptionCount GT 0>
								(#variables.propertySummary.descriptionDistinctCount# distinct value#variables.descriptionPlural##variables.descriptionExampleText#
								<cfloop from="1" to="#ArrayLen(variables.propertySummary.descriptionExamples)#" index="variables.exIdx">
									"#encodeForHtml(variables.propertySummary.descriptionExamples[variables.exIdx])#"<cfif variables.exIdx LT ArrayLen(variables.propertySummary.descriptionExamples)>,</cfif>
								</cfloop>)
							</cfif>
						</li>
						<li>
							#variables.propertySummary.remarksCount# of #variables.propertySummary.totalCount# have a remark
							<cfif variables.propertySummary.remarksCount GT 0>
								(#variables.propertySummary.remarksDistinctCount# distinct value#variables.remarksPlural##variables.remarksExampleText#
								<cfloop from="1" to="#ArrayLen(variables.propertySummary.remarksExamples)#" index="variables.exIdx">
									"#encodeForHtml(variables.propertySummary.remarksExamples[variables.exIdx])#"<cfif variables.exIdx LT ArrayLen(variables.propertySummary.remarksExamples)>,</cfif>
								</cfloop>)
							</cfif>
						</li>
						<li>#variables.propertySummary.positionsCount# of #variables.propertySummary.totalCount# have a number of positions set</li>
					</ul>
				</div>
				<form method="post" action="/containers/bulkModifyContainers.cfm" id="bulkModifyDataEntry">
					<input type="hidden" name="origContType" value="#encodeForHtml(form.origContType)#">
					<input type="hidden" name="barcode_prefix" value="#encodeForHtml(form.barcode_prefix)#">
					<input type="hidden" name="begin_barcode" value="#encodeForHtml(form.begin_barcode)#">
					<input type="hidden" name="end_barcode" value="#encodeForHtml(form.end_barcode)#">
					<div class="form-row">
						<div class="col-12 col-md-4 mb-2">
							<label for="newContType" class="data-entry-label">New Container Type</label>
							<select name="newContType" id="newContType" class="data-entry-select col-12 reqdClr" required aria-required="true">
								<option value=""></option>
								<cfloop query="variables.qAllowedTypes">
									<cfset variables.newTypeSelected = "">
									<cfif variables.qAllowedTypes.container_type EQ form.origContType>
										<cfset variables.newTypeSelected = "selected">
									</cfif>
									<option value="#encodeForHtml(variables.qAllowedTypes.container_type)#" #variables.newTypeSelected#>#encodeForHtml(variables.qAllowedTypes.container_type)#</option>
								</cfloop>
							</select>
						</div>
					</div>
					<fieldset class="my-2 px-2 pb-1 border-top border-right border-bottom border-left field-set">
						<legend class="h6 mb-0 px-3 border-top border-right border-bottom border-left field-set-legend bg-teal font-weight-bold w-auto">Description</legend>
						<div class="form-row pt-2">
							<div class="col-12 col-md-8 mb-2">
								<label for="description" class="data-entry-label">New Description Text (optional)</label>
								<input type="text" name="description" id="description" class="data-entry-input col-12">
								<small class="text-muted">Enter NULL with Overwrite selected to clear the description.</small>
							</div>
							<div class="col-12 col-md-4 mb-2">
								<span class="data-entry-label" id="descriptionModeLabel">If a value is given</span>
								<div role="radiogroup" aria-labelledby="descriptionModeLabel">
									<div>
										<input type="radio" name="description_mode" id="description_mode_append" value="append" checked>
										<label for="description_mode_append">Append to existing text</label>
									</div>
									<div>
										<input type="radio" name="description_mode" id="description_mode_overwrite" value="overwrite">
										<label for="description_mode_overwrite">Overwrite existing text</label>
									</div>
								</div>
							</div>
						</div>
					</fieldset>
					<fieldset class="my-2 px-2 pb-1 border-top border-right border-bottom border-left field-set">
						<legend class="h6 mb-0 px-3 border-top border-right border-bottom border-left field-set-legend bg-teal font-weight-bold w-auto">Remark</legend>
						<div class="form-row pt-2">
							<div class="col-12 col-md-8 mb-2">
								<label for="container_remarks" class="data-entry-label">New Remark Text (optional)</label>
								<input type="text" name="container_remarks" id="container_remarks" class="data-entry-input col-12">
								<small class="text-muted">Enter NULL with Overwrite selected to clear the remark.</small>
							</div>
							<div class="col-12 col-md-4 mb-2">
								<span class="data-entry-label" id="remarksModeLabel">If a value is given</span>
								<div role="radiogroup" aria-labelledby="remarksModeLabel">
									<div>
										<input type="radio" name="container_remarks_mode" id="container_remarks_mode_append" value="append" checked>
										<label for="container_remarks_mode_append">Append to existing text</label>
									</div>
									<div>
										<input type="radio" name="container_remarks_mode" id="container_remarks_mode_overwrite" value="overwrite">
										<label for="container_remarks_mode_overwrite">Overwrite existing text</label>
									</div>
								</div>
							</div>
						</div>
					</fieldset>
					<div class="form-row">
						<div class="col-6 col-md-3 mb-2">
							<label for="height" class="data-entry-label">New Height (cm, optional)</label>
							<input type="text" name="height" id="height" class="data-entry-input col-12">
							<small class="text-muted">Enter NULL to clear.</small>
						</div>
						<div class="col-6 col-md-3 mb-2">
							<label for="length" class="data-entry-label">New Length (cm, optional)</label>
							<input type="text" name="length" id="length" class="data-entry-input col-12">
							<small class="text-muted">Enter NULL to clear.</small>
						</div>
						<div class="col-6 col-md-3 mb-2">
							<label for="width" class="data-entry-label">New Width (cm, optional)</label>
							<input type="text" name="width" id="width" class="data-entry-input col-12">
							<small class="text-muted">Enter NULL to clear.</small>
						</div>
						<div class="col-6 col-md-3 mb-2">
							<label for="number_positions" class="data-entry-label">New Number of Positions (optional)</label>
							<input type="text" name="number_positions" id="number_positions" class="data-entry-input col-12">
							<small class="text-muted">Enter NULL to clear.</small>
						</div>
					</div>
					<div class="form-row mb-2">
						<div class="col-12">
							<button type="submit" name="formAction" value="test" class="btn btn-xs btn-info">Dry Run</button>
							<button type="submit" name="formAction" value="apply" class="btn btn-xs btn-primary ml-1">Apply Changes</button>
							<button type="submit" name="formAction" value="entryPoint" formnovalidate class="btn btn-xs btn-warning ml-1">Start Over</button>
						</div>
					</div>
				</form>
				<div class="mb-3 mt-3">
					<h2 class="h5 mb-1">Candidate Containers</h2>
					<output id="bulkModifyCandidateFeedback">&nbsp;</output>
					<div id="bulkModifyCandidateList" class="table-responsive">
						<div class="my-2 text-center"><img src="/shared/images/indicator.gif"> Loading&hellip;</div>
					</div>
					<cfif ArrayLen(variables.eligibleContainers) GT variables.MAX_LISTED_CANDIDATES>
						<p class="text-muted small mb-0">Showing the first #variables.MAX_LISTED_CANDIDATES# of #ArrayLen(variables.eligibleContainers)#.</p>
					</cfif>
				</div>
			</div>
		</section>
		<script>
			$(document).ready(function() {
				renderBulkModifyCandidateTable(#serializeJSON(variables.candidateRowsForDisplay)#, '##bulkModifyCandidateList', 'bulkModifyCandidateFeedback');
			});
		</script>

	<cfelseif variables.action EQ "test" OR variables.action EQ "apply">
		<cfset variables.MAX_DETAILED_ROWS = 200>
		<cfset variables.containers = variables.containerFunctions.getContainersInRange(barcode_prefix=form.barcode_prefix, begin_barcode=val(form.begin_barcode), end_barcode=val(form.end_barcode), orig_container_type=form.origContType)>
		<cfset variables.okCount = 0>
		<cfset variables.warnCount = 0>
		<cfset variables.blockCount = 0>
		<cfset variables.updatedCount = 0>
		<cfset variables.failedCount = 0>
		<cfset variables.blockedDetails = ArrayNew(1)>
		<cfset variables.failedDetails = ArrayNew(1)>
		<cfset variables.updatedContainerRows = ArrayNew(1)>

		<cfloop from="1" to="#ArrayLen(variables.containers)#" index="variables.i">
			<cfset variables.validationJson = variables.containerFunctions.validateContainerRetype(container_id=variables.containers[variables.i].container_id, new_container_type=form.newContType)>
			<cfset variables.containers[variables.i]["validationJson"] = variables.validationJson>
			<cfset variables.validation = deserializeJSON(variables.validationJson)>
			<cfset variables.containers[variables.i]["outcome"] = variables.validation.severity>

			<cfif variables.validation.severity EQ "ok">
				<cfset variables.okCount = variables.okCount + 1>
			<cfelseif variables.validation.severity EQ "warn">
				<cfset variables.warnCount = variables.warnCount + 1>
			<cfelse>
				<cfset variables.blockCount = variables.blockCount + 1>
				<cfset variables.blockedDetail = StructNew()>
				<cfset variables.blockedDetail["barcode"] = variables.containers[variables.i].barcode>
				<cfset variables.blockedDetail["reason"] = ArrayToList(variables.validation.blocks, " ")>
				<cfset ArrayAppend(variables.blockedDetails, variables.blockedDetail)>
			</cfif>

			<cfif variables.action EQ "apply" AND variables.validation.allowed>
				<cfset variables.applyResultJson = variables.containerFunctions.applyBulkRetypeContainer(
					container_id=variables.containers[variables.i].container_id,
					new_container_type=form.newContType,
					description_value=form.description,
					description_mode=form.description_mode,
					container_remarks_value=form.container_remarks,
					container_remarks_mode=form.container_remarks_mode,
					height_value=form.height,
					length_value=form.length,
					width_value=form.width,
					number_positions_value=form.number_positions
				)>
				<cfset variables.applyResult = deserializeJSON(variables.applyResultJson)>
				<cfif variables.applyResult.status EQ "updated">
					<cfset variables.updatedCount = variables.updatedCount + 1>
					<cfset ArrayAppend(variables.updatedContainerRows, variables.applyResult)>
				<cfelse>
					<cfset variables.failedCount = variables.failedCount + 1>
					<cfset variables.failedDetail = StructNew()>
					<cfset variables.failedDetail["barcode"] = variables.containers[variables.i].barcode>
					<cfset variables.failedDetail["reason"] = variables.applyResult.message>
					<cfset ArrayAppend(variables.failedDetails, variables.failedDetail)>
				</cfif>
			</cfif>
		</cfloop>

		<cfset variables.clearDescriptionPreview = false>
		<cfif form.description_mode EQ "overwrite" AND UCase(trim(form.description)) EQ "NULL">
			<cfset variables.clearDescriptionPreview = true>
		</cfif>
		<cfset variables.clearRemarksPreview = false>
		<cfif form.container_remarks_mode EQ "overwrite" AND UCase(trim(form.container_remarks)) EQ "NULL">
			<cfset variables.clearRemarksPreview = true>
		</cfif>
		<cfset variables.clearHeightPreview = false>
		<cfif UCase(trim(form.height)) EQ "NULL">
			<cfset variables.clearHeightPreview = true>
		</cfif>
		<cfset variables.clearLengthPreview = false>
		<cfif UCase(trim(form.length)) EQ "NULL">
			<cfset variables.clearLengthPreview = true>
		</cfif>
		<cfset variables.clearWidthPreview = false>
		<cfif UCase(trim(form.width)) EQ "NULL">
			<cfset variables.clearWidthPreview = true>
		</cfif>
		<cfset variables.clearNumberPositionsPreview = false>
		<cfif UCase(trim(form.number_positions)) EQ "NULL">
			<cfset variables.clearNumberPositionsPreview = true>
		</cfif>

		<cfif variables.action EQ "test">
			<cfset variables.detailedRowCount = ArrayLen(variables.containers)>
			<cfif variables.detailedRowCount GT variables.MAX_DETAILED_ROWS>
				<cfset variables.detailedRowCount = variables.MAX_DETAILED_ROWS>
			</cfif>
			<section class="row mx-0 border rounded my-2 py-2 mb-4" aria-labelledby="dryRunHeading">
				<div class="col-12">
					<h1 class="h2 ml-1 mb-1" id="dryRunHeading">Dry Run Results</h1>
					<p>
						Nothing has been changed. #ArrayLen(variables.containers)# container(s) checked:
						<strong>#variables.okCount#</strong> ready to change,
						<strong>#variables.warnCount#</strong> need review (see below),
						<strong>#variables.blockCount#</strong> blocked (Apply Changes will skip these).
					</p>
					<div class="mb-3">
						<h2 class="h5 mb-1">Proposed Changes</h2>
						<ul class="mb-0">
							<li>
								Container Type:
								<cfif form.newContType NEQ form.origContType>
									#encodeForHtml(form.origContType)# &rarr; #encodeForHtml(form.newContType)#
								<cfelse>
									no change (#encodeForHtml(form.origContType)#)
								</cfif>
							</li>
							<li>
								Description:
								<cfif variables.clearDescriptionPreview>
									cleared
								<cfelseif len(trim(form.description)) GT 0>
									#encodeForHtml(form.description_mode)# &ndash; "#encodeForHtml(form.description)#"
								<cfelse>
									no change
								</cfif>
							</li>
							<li>
								Remark:
								<cfif variables.clearRemarksPreview>
									cleared
								<cfelseif len(trim(form.container_remarks)) GT 0>
									#encodeForHtml(form.container_remarks_mode)# &ndash; "#encodeForHtml(form.container_remarks)#"
								<cfelse>
									no change
								</cfif>
							</li>
							<li>
								Height (cm):
								<cfif variables.clearHeightPreview>
									cleared
								<cfelseif len(trim(form.height)) GT 0>
									set to #encodeForHtml(form.height)#
								<cfelse>
									no change
								</cfif>
							</li>
							<li>
								Length (cm):
								<cfif variables.clearLengthPreview>
									cleared
								<cfelseif len(trim(form.length)) GT 0>
									set to #encodeForHtml(form.length)#
								<cfelse>
									no change
								</cfif>
							</li>
							<li>
								Width (cm):
								<cfif variables.clearWidthPreview>
									cleared
								<cfelseif len(trim(form.width)) GT 0>
									set to #encodeForHtml(form.width)#
								<cfelse>
									no change
								</cfif>
							</li>
							<li>
								Number of Positions:
								<cfif variables.clearNumberPositionsPreview>
									cleared
								<cfelseif len(trim(form.number_positions)) GT 0>
									set to #encodeForHtml(form.number_positions)#
								<cfelse>
									no change
								</cfif>
							</li>
						</ul>
					</div>
					<div class="positions-grid positions-grid-autofill" id="dryRunGrid">
						<cfloop from="1" to="#variables.detailedRowCount#" index="variables.i">
							<div class="positions-grid-cell positions-grid-cell-empty">
								<label class="positions-grid-label">#encodeForHtml(variables.containers[variables.i].barcode)#</label>
								<div class="positions-grid-barcode-status small" id="dryRunBadge_#variables.containers[variables.i].container_id#" role="status"></div>
								<cfif variables.containers[variables.i].outcome NEQ "ok">
									<button type="button" class="btn btn-xs btn-outline-secondary mt-1 dry-run-details-btn" data-container-id="#variables.containers[variables.i].container_id#" data-display-name="#encodeForHtml(variables.containers[variables.i].barcode)#">Details</button>
								</cfif>
							</div>
						</cfloop>
					</div>
					<cfif ArrayLen(variables.containers) GT variables.detailedRowCount>
						<p class="text-muted small mt-2">Showing details for the first #variables.detailedRowCount# of #ArrayLen(variables.containers)#; the rest were also checked and are included in the counts above.</p>
					</cfif>
					<form method="post" action="/containers/bulkModifyContainers.cfm" class="mt-3">
						<input type="hidden" name="origContType" value="#encodeForHtml(form.origContType)#">
						<input type="hidden" name="barcode_prefix" value="#encodeForHtml(form.barcode_prefix)#">
						<input type="hidden" name="begin_barcode" value="#encodeForHtml(form.begin_barcode)#">
						<input type="hidden" name="end_barcode" value="#encodeForHtml(form.end_barcode)#">
						<input type="hidden" name="newContType" value="#encodeForHtml(form.newContType)#">
						<input type="hidden" name="description" value="#encodeForHtml(form.description)#">
						<input type="hidden" name="description_mode" value="#encodeForHtml(form.description_mode)#">
						<input type="hidden" name="container_remarks" value="#encodeForHtml(form.container_remarks)#">
						<input type="hidden" name="container_remarks_mode" value="#encodeForHtml(form.container_remarks_mode)#">
						<input type="hidden" name="height" value="#encodeForHtml(form.height)#">
						<input type="hidden" name="length" value="#encodeForHtml(form.length)#">
						<input type="hidden" name="width" value="#encodeForHtml(form.width)#">
						<input type="hidden" name="number_positions" value="#encodeForHtml(form.number_positions)#">
						<button type="submit" name="formAction" value="apply" class="btn btn-xs btn-primary">Apply Changes</button>
						<button type="submit" name="formAction" value="entryPoint" formnovalidate class="btn btn-xs btn-warning ml-1">Start Over</button>
					</form>
				</div>
			</section>
			<script>
				$(document).ready(function() {
					<cfloop from="1" to="#variables.detailedRowCount#" index="variables.i">
						renderPlacementWarningBadge(#variables.containers[variables.i].validationJson#, 'dryRunBadge_#variables.containers[variables.i].container_id#');
					</cfloop>
					$('.dry-run-details-btn').on('click', function() {
						var btn = $(this);
						openContainerDetailsDialog(btn.data('containerId'), btn.data('displayName'), null, false);
					});
				});
			</script>

		<cfelse>
			<cfset variables.descriptionWord = "overwritten">
			<cfif form.description_mode EQ "append">
				<cfset variables.descriptionWord = "appended">
			</cfif>
			<cfset variables.remarksWord = "overwritten">
			<cfif form.container_remarks_mode EQ "append">
				<cfset variables.remarksWord = "appended">
			</cfif>
			<cfset variables.MAX_LISTED_UPDATED = 200>
			<cfset variables.updatedRowsForDisplay = ArrayNew(1)>
			<cfloop from="1" to="#min(ArrayLen(variables.updatedContainerRows), variables.MAX_LISTED_UPDATED)#" index="variables.j">
				<cfset ArrayAppend(variables.updatedRowsForDisplay, variables.updatedContainerRows[variables.j])>
			</cfloop>
			<section class="row mx-0 border rounded my-2 pt-2 mb-4" aria-labelledby="reportHeading">
				<div class="col-12">
					<h1 class="h2 ml-1 mb-1" id="reportHeading">Bulk Modify Report</h1>
					<ul>
						<li><strong>#variables.updatedCount#</strong> container(s) updated: retyped from #encodeForHtml(form.origContType)# to #encodeForHtml(form.newContType)#<cfif len(trim(form.description)) GT 0>, description #variables.descriptionWord#</cfif><cfif len(trim(form.container_remarks)) GT 0>, remark #variables.remarksWord#</cfif>.</li>
						<li><strong>#variables.blockCount#</strong> container(s) skipped because the retype was not allowed.</li>
						<li><strong>#variables.failedCount#</strong> container(s) failed to update due to an error.</li>
					</ul>
					<cfif ArrayLen(variables.blockedDetails) GT 0>
						<div class="alert alert-warning" role="alert">
							Skipped (blocked):
							<ul class="mb-0">
								<cfloop array="#variables.blockedDetails#" index="variables.detail">
									<li>#encodeForHtml(variables.detail.barcode)#: #encodeForHtml(variables.detail.reason)#</li>
								</cfloop>
							</ul>
						</div>
					</cfif>
					<cfif ArrayLen(variables.failedDetails) GT 0>
						<div class="alert alert-danger" role="alert">
							Failed:
							<ul class="mb-0">
								<cfloop array="#variables.failedDetails#" index="variables.detail">
									<li>#encodeForHtml(variables.detail.barcode)#: #encodeForHtml(variables.detail.reason)#</li>
								</cfloop>
							</ul>
						</div>
					</cfif>
					<cfif ArrayLen(variables.updatedContainerRows) GT 0>
						<div class="mb-3">
							<h2 class="h5 mb-1">Modified Containers</h2>
							<output id="bulkModifyReportFeedback">&nbsp;</output>
							<div id="bulkModifyReportList" class="table-responsive">
								<div class="my-2 text-center"><img src="/shared/images/indicator.gif"> Loading&hellip;</div>
							</div>
							<cfif ArrayLen(variables.updatedContainerRows) GT variables.MAX_LISTED_UPDATED>
								<p class="text-muted small mb-0">Showing the first #variables.MAX_LISTED_UPDATED# of #ArrayLen(variables.updatedContainerRows)#.</p>
							</cfif>
						</div>
					</cfif>
					<form method="post" action="/containers/bulkModifyContainers.cfm" class="mt-3">
						<input type="hidden" name="barcode_prefix" value="#encodeForHtml(form.barcode_prefix)#">
						<input type="hidden" name="begin_barcode" value="#encodeForHtml(form.begin_barcode)#">
						<input type="hidden" name="end_barcode" value="#encodeForHtml(form.end_barcode)#">
						<button type="submit" name="formAction" value="entryPoint" formnovalidate class="btn btn-xs btn-warning">Start a New Bulk Modify</button>
						<button type="submit" name="formAction" value="preview" formnovalidate class="btn btn-xs btn-secondary ml-1" onclick="$('##reportOrigContType').val(#JSStringFormat(form.newContType)#);">Revisit This Batch</button>
						<input type="hidden" name="origContType" id="reportOrigContType" value="#encodeForHtml(form.origContType)#">
					</form>
				</div>
			</section>
			<script>
				$(document).ready(function() {
					renderBulkModifyCandidateTable(#serializeJSON(variables.updatedRowsForDisplay)#, '##bulkModifyReportList', 'bulkModifyReportFeedback');
				});
			</script>
		</cfif>
	</cfif>

	</cfoutput>
</main>

<cfinclude template="/shared/_footer.cfm">
