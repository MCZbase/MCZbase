<!--- /containers/containerDiagnostics.cfm
	Read-only diagnostics for container hierarchy shape and data integrity.

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

<cfset pageTitle = "Containers | Diagnostics">
<cfset pageHasContainers = true>
<cfinclude template="/shared/_header.cfm">

<cfset variables.allowedActions = "entryPoint,singleOccupantViolations">
<cfset variables.action = "entryPoint">
<cfif isDefined("url.action") AND len(trim(url.action)) GT 0>
	<cfset variables.action = trim(url.action)>
</cfif>
<cfif NOT listFindNoCase(variables.allowedActions, variables.action)>
	<cfset variables.action = "entryPoint">
</cfif>

<cfobject component="containers.component.search" name="containerSearch">

<!---
	singleOccupantViolations action: handle entirely here and exit.
	Keeping this action in its own short block (with cfabort) means the
	entryPoint content below is never wrapped in a cfif, which keeps
	cfflush unobstructed for incremental rendering.
--->
<cfif variables.action EQ "singleOccupantViolations">
	<main id="content" class="container-fluid">
		<section class="row">
			<div class="col-12 mb-2">
				<h1 class="h2">Container Diagnostics</h1>
			</div>
		</section>
		<section class="row">
			<div class="col-12 mb-2">
				<h2 class="h4">Single-Occupant Container Violations</h2>
				<p class="mb-1">
					Containers of type <em>pin</em>, <em>slide</em>, or <em>cryovial</em> are each
					expected to hold exactly one collection-object child.
					The rows below have zero or two-or-more collection-object children.
				</p>
				<div id="diag_loading_single" class="py-2 text-secondary"><em>Computing, please wait&hellip;</em></div>
			</div>
		</section>
		<cfflush>

		<cfset variables.singleOccViolations = containerSearch.getSingleOccupantViolations()>
		<script>document.getElementById('diag_loading_single').style.display='none';</script>
		<section class="row mb-4">
			<div class="col-12">
				<div class="border rounded bg-light p-2">
					<cfif variables.singleOccViolations.recordcount EQ 0>
						<p>No single-occupant violations detected.</p>
					<cfelse>
						<table class="table table-sm table-striped d-xl-table">
							<thead>
								<tr>
									<th>Container ID</th>
									<th>Type</th>
									<th>Label</th>
									<th>Barcode</th>
									<th>Total Children</th>
									<th>Coll Obj Children</th>
								</tr>
							</thead>
							<tbody>
								<cfoutput query="variables.singleOccViolations">
									<tr>
										<td>
											<a href="/findContainer.cfm?container_id=#encodeForUrl(container_id)#" target="_blank">
												#encodeForHtml(container_id)#
											</a>
										</td>
										<td>#encodeForHtml(container_type)#</td>
										<td>#encodeForHtml(label)#</td>
										<td>#encodeForHtml(barcode)#</td>
										<td>#encodeForHtml(child_count)#</td>
										<td>#encodeForHtml(coll_obj_count)#</td>
									</tr>
								</cfoutput>
							</tbody>
						</table>
					</cfif>
				</div>
			</div>
		</section>
		<section class="row mb-2">
			<div class="col-12">
				<cfoutput>
				<a href="containerDiagnostics.cfm" class="btn btn-secondary">
					&larr; Back to Diagnostics Summary
				</a>
				</cfoutput>
			</div>
		</section>
		<cfflush>
	</main>
	<cfinclude template="/shared/_footer.cfm">
	<cfabort>
</cfif>

<!---
	entryPoint: default action.  No cfif wrapper around the cfflush sequence
	so that ColdFusion can flush each section to the browser incrementally.
	Each loading indicator is flushed BEFORE its corresponding query runs
	so the browser shows feedback immediately.
--->
<main id="content" class="container-fluid">
	<section class="row">
		<div class="col-12 mb-2">
			<h1 class="h2">Container Diagnostics</h1>
			<p>
				Diagnostics for container hierarchy shape and potential data anomalies.
				This page does not modify data.
			</p>
			<cfoutput>
			<a href="containerDiagnostics.cfm?action=singleOccupantViolations" class="btn btn-secondary mb-2">
				Check Single-Occupant Container Violations
			</a>
			</cfoutput>
		</div>
	</section>
	<div id="diag_loading_1" class="row"><div class="col-12 py-2 text-secondary"><em>Loading Summary&hellip;</em></div></div>
	<cfflush>

	<cfset variables.summary = containerSearch.getContainerShapeSummary()>
	<script>document.getElementById('diag_loading_1').style.display='none';</script>
	<section class="row">
		<div class="col-12 col-xl-6 mb-2">
			<div class="border rounded bg-light p-2">
				<h2 class="h4">Summary</h2>
				<table class="table table-sm table-striped d-xl-table">
					<thead>
						<tr>
							<th>Metric</th>
							<th>Value</th>
						</tr>
					</thead>
					<tbody>
						<cfoutput query="variables.summary">
							<tr>
								<td>#encodeForHtml(metric)#</td>
								<td>#encodeForHtml(metric_value)#</td>
							</tr>
						</cfoutput>
					</tbody>
				</table>
			</div>
		</div>
		<div class="col-12 col-xl-6 mb-2">
			<div id="diag_loading_2" class="py-2 text-secondary"><em>Loading Depth Distribution&hellip;</em></div>
			<cfflush>

			<cfset variables.depth = containerSearch.getContainerShapeByDepth()>
			<script>document.getElementById('diag_loading_2').style.display='none';</script>
			<div class="border rounded bg-light p-2">
				<h2 class="h4">Depth Distribution</h2>
				<table class="table table-sm table-striped d-xl-table">
					<thead>
						<tr>
							<th>Depth Below Node</th>
							<th>Nodes</th>
						</tr>
					</thead>
					<tbody>
						<cfoutput query="variables.depth">
							<tr>
								<td>#encodeForHtml(depth_below)#</td>
								<td>#encodeForHtml(node_count)#</td>
							</tr>
						</cfoutput>
					</tbody>
				</table>
			</div>
		</div>
	</section>
	<div id="diag_loading_3" class="row"><div class="col-12 py-2 text-secondary"><em>Loading A/B/AB Hotspots&hellip;</em></div></div>
	<cfflush>

	<cfset variables.hotspots = containerSearch.getContainerShapeHotspots()>
	<script>document.getElementById('diag_loading_3').style.display='none';</script>
	<!--- Container type classification lists, shared by both hotspots and role fit sections --->
	<cfset variables.ctypeC  = "institution,campus,cryovat,building,floor,room,freezer,freezer rack,grouping,set,fixture,rack slot,position">
	<cfset variables.ctypeS  = "cryovial,tank,jar,glass vial,envelope,slide,pin">
	<cfset variables.ctypeSC = "freezer box,compartment">
	<!--- Reusable accessibility indicator snippets --->
	<cfset variables.violationIndicator = " <span aria-hidden=""true"">&##x2717;</span><span class=""sr-only""> violation</span>">
	<cfset variables.anomalyIndicator   = " <span aria-hidden=""true"">&##x26A0;</span><span class=""sr-only""> anomaly</span>">
	<cfset variables.emptyIndicator     = " <span class=""text-muted"">(empty)</span>">
	<section class="row">
		<div class="col-12 mb-2">
			<div class="border rounded bg-light p-2">
				<h2 class="h4">A/B/AB Hotspots</h2>
				<p class="mb-1">
					This table lists containers with an unusually large number of direct collection-object
					children or with a mix of child types.  A container is included if it has
					<strong>200 or more direct collection-object children</strong>, or if it has
					<strong>both collection-object and structural children simultaneously</strong>.
					Containers with only structural children (no direct collection objects) are not shown.
				</p>
				<p class="mb-1">
					<strong>Shape class</strong> describes the direct-child distribution:
					<strong>A</strong> = 200&ndash;999 direct collection-object children with no structural children;
					<strong>B</strong> = 1,000 or more direct collection-object children with no structural children;
					<strong>AB</strong> = has both collection-object and structural direct children (regardless of count).
				</p>
				<p class="mb-1">
					<strong>Expected Role</strong> shows the role the container type is designed to fill:
					<strong>C</strong> = structural only (should not hold collection objects directly);
					<strong>S</strong> = specimen holder (should hold only collection objects);
					<strong>SC</strong> = may hold both.
					Rows highlighted in <span class="badge badge-danger">red</span> are
					<strong>violations</strong> (a C-type holding collection-object children).
					Rows highlighted in <span class="badge badge-warning">yellow</span> are
					<strong>anomalies</strong> (an S-type holding structural children).
					A &#x2717; or &#x26A0; in the Status column provides a non-color indicator.
				</p>
				<table class="table table-sm table-striped d-xl-table">
					<thead>
						<tr>
							<th>Container ID</th>
							<th>Type</th>
							<th>Expected Role</th>
							<th>Label</th>
							<th>Direct Children</th>
							<th>Direct Leaf Children</th>
							<th>Direct Structural Children</th>
							<th>Shape Class</th>
							<th>Status</th>
						</tr>
					</thead>
					<tbody>
						<cfoutput query="variables.hotspots">
							<cfset variables.hotspotRole = "unknown">
							<cfif listFindNoCase(variables.ctypeC, container_type)>
								<cfset variables.hotspotRole = "C">
							<cfelseif listFindNoCase(variables.ctypeS, container_type)>
								<cfset variables.hotspotRole = "S">
							<cfelseif listFindNoCase(variables.ctypeSC, container_type)>
								<cfset variables.hotspotRole = "SC">
							<cfelseif container_type EQ "collection object">
								<cfset variables.hotspotRole = "leaf">
							</cfif>
							<cfset variables.hotspotRowClass = "">
							<cfset variables.hotspotStatusIndicator = "">
							<cfif variables.hotspotRole EQ "C">
								<!--- C types should hold no collection-object children; any are violations --->
								<cfset variables.hotspotRowClass = " table-danger">
								<cfset variables.hotspotStatusIndicator = variables.violationIndicator>
							<cfelseif variables.hotspotRole EQ "S" AND shape_class EQ "AB">
								<!--- S types with structural children are anomalies --->
								<cfset variables.hotspotRowClass = " table-warning">
								<cfset variables.hotspotStatusIndicator = variables.anomalyIndicator>
							</cfif>
							<tr class="#trim(variables.hotspotRowClass)#">
								<td>
									<a href="/findContainer.cfm?container_id=#encodeForUrl(container_id)#" target="_blank">
										#encodeForHtml(container_id)#
									</a>
								</td>
								<td>#encodeForHtml(container_type)#</td>
								<td>#encodeForHtml(variables.hotspotRole)#</td>
								<td>#encodeForHtml(label)#</td>
								<td>#encodeForHtml(direct_children)#</td>
								<td>#encodeForHtml(direct_leaf_children)#</td>
								<td>#encodeForHtml(direct_structural_children)#</td>
								<td>#encodeForHtml(shape_class)#</td>
								<td>#variables.hotspotStatusIndicator#</td>
							</tr>
						</cfoutput>
					</tbody>
				</table>
			</div>
		</div>
	</section>
	<div id="diag_loading_4" class="row"><div class="col-12 py-2 text-secondary"><em>Loading Container Type Role Fit&hellip;</em></div></div>
	<cfflush>

	<cfset variables.typeRoleFit = containerSearch.getContainerTypeRoleFit()>
	<script>document.getElementById('diag_loading_4').style.display='none';</script>
	<section class="row">
		<div class="col-12 mb-2">
			<div class="border rounded bg-light p-2">
				<h2 class="h4">Container Type Role Fit</h2>
				<p class="mb-1">
					Compares the actual child distribution against the expected role for each container type (per CTCONTAINER_TYPE).
					<strong>C</strong> = expected to contain only other (structural) containers
					(institution, campus, cryovat, building, floor, room, freezer, freezer rack, grouping, set, fixture, rack slot, position);
					<strong>S</strong> = expected to contain only collection-object containers, one per container
					(cryovial, tank, jar, glass vial, envelope, slide, pin);
					<strong>SC</strong> = may contain both structural containers and collection objects
					(freezer box, compartment);
					<strong>leaf</strong> = collection object, should never have children.
				</p>
				<p class="mb-1">
					Cell highlighting key (color + symbol for accessibility):
					<strong>&#x2717; Violation</strong> (red) &mdash; clearly incorrect data:
						non-zero <em>With Coll&nbsp;Obj Children</em> for C types;
						non-zero <em>With Structural Children</em> for S types;
						any children for leaf types;
						non-zero <em>Leaf&nbsp;Nodes</em> for S types (empty specimen holders that should each contain one collection object).
					<strong>&#x26A0; Anomaly</strong> (yellow) &mdash; unusual but may require investigation:
						non-zero <em>With Both Types</em> for S or C types.
					<em>(empty)</em> (plain text) &mdash; informational:
						non-zero <em>Leaf&nbsp;Nodes</em> for C or SC types indicates containers whose placement has not yet been recorded.
				</p>
				<table class="table table-sm table-striped d-xl-table">
					<thead>
						<tr>
							<th>Container Type</th>
							<th>Expected Role</th>
							<th>Total Count</th>
							<th>With Coll Obj Children</th>
							<th>With Structural Children</th>
							<th>With Both Types</th>
							<th>Leaf Nodes (no children)</th>
						</tr>
					</thead>
					<tbody>
						<cfoutput query="variables.typeRoleFit">
							<cfset variables.colObjClass = "">
							<cfset variables.colObjSuffix = "">
							<cfset variables.structClass = "">
							<cfset variables.structSuffix = "">
							<cfset variables.bothClass = "">
							<cfset variables.bothSuffix = "">
							<cfset variables.leafClass = "">
							<cfset variables.leafSuffix = "">
							<!--- Violation: C type with collection-object children --->
							<cfif expected_role EQ "C" AND val(with_coll_obj_children) GT 0>
								<cfset variables.colObjClass = " table-danger">
								<cfset variables.colObjSuffix = variables.violationIndicator>
							</cfif>
							<!--- Violation: S type with structural children --->
							<cfif expected_role EQ "S" AND val(with_structural_children) GT 0>
								<cfset variables.structClass = " table-danger">
								<cfset variables.structSuffix = variables.violationIndicator>
							</cfif>
							<!--- Violation: leaf type (collection object) with any children --->
							<cfif expected_role EQ "leaf" AND (val(with_coll_obj_children) GT 0 OR val(with_structural_children) GT 0)>
								<cfset variables.colObjClass = " table-danger">
								<cfset variables.colObjSuffix = variables.violationIndicator>
								<cfset variables.structClass = " table-danger">
								<cfset variables.structSuffix = variables.violationIndicator>
							</cfif>
							<!--- Anomaly: S or C with children of both types --->
							<cfif (expected_role EQ "S" OR expected_role EQ "C") AND val(with_both_types) GT 0>
								<cfset variables.bothClass = " table-warning">
								<cfset variables.bothSuffix = variables.anomalyIndicator>
							</cfif>
							<!--- Violation: S type with empty containers (leaf nodes with no collection-object child) --->
							<cfif expected_role EQ "S" AND val(leaf_nodes) GT 0>
								<cfset variables.leafClass = " table-danger">
								<cfset variables.leafSuffix = variables.violationIndicator>
							</cfif>
							<!--- Informational: C or SC type with empty containers (not yet placed in hierarchy) --->
							<cfif (expected_role EQ "C" OR expected_role EQ "SC") AND val(leaf_nodes) GT 0>
								<cfset variables.leafSuffix = variables.emptyIndicator>
							</cfif>
							<tr>
								<td>#encodeForHtml(container_type)#</td>
								<td>#encodeForHtml(expected_role)#</td>
								<td>#encodeForHtml(total_count)#</td>
								<td class="#variables.colObjClass#">#encodeForHtml(with_coll_obj_children)##variables.colObjSuffix#</td>
								<td class="#variables.structClass#">#encodeForHtml(with_structural_children)##variables.structSuffix#</td>
								<td class="#variables.bothClass#">#encodeForHtml(with_both_types)##variables.bothSuffix#</td>
								<td class="#variables.leafClass#">#encodeForHtml(leaf_nodes)##variables.leafSuffix#</td>
							</tr>
						</cfoutput>
					</tbody>
				</table>
			</div>
		</div>
	</section>
	<div id="diag_loading_5" class="row"><div class="col-12 py-2 text-secondary"><em>Loading coll_obj_cont_hist Anomalies&hellip;</em></div></div>
	<cfflush>

	<cfset variables.collObjAnomalies = containerSearch.getCollObjContHistAnomalies()>
	<script>document.getElementById('diag_loading_5').style.display='none';</script>
	<section class="row mb-4">
		<div class="col-12">
			<div class="border rounded bg-light p-2">
				<h2 class="h4">coll_obj_cont_hist Anomalies</h2>
				<p class="mb-1">Objects with more than one row where current_container_fg=1.</p>
				<cfif variables.collObjAnomalies.recordcount EQ 0>
					<p>No anomalies detected.</p>
				<cfelse>
					<table class="table table-sm table-striped d-xl-table">
						<thead>
							<tr>
								<th>Collection Object ID</th>
								<th>Count</th>
							</tr>
						</thead>
						<tbody>
							<cfoutput query="variables.collObjAnomalies">
								<tr>
									<td>#encodeForHtml(collection_object_id)#</td>
									<td>#encodeForHtml(ct)#</td>
								</tr>
							</cfoutput>
						</tbody>
					</table>
				</cfif>
			</div>
		</div>
	</section>
	<cfflush>
</main>

<cfinclude template="/shared/_footer.cfm">
