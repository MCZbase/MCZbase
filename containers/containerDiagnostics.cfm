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

<!--- role gate: internal operations diagnostics --->
<cfif NOT isdefined("session.roles") OR NOT listFindNoCase(session.roles, "collops")>
	<cfthrow message="You do not have permission to access Container Diagnostics.">
</cfif>

<cfparam name="url.action" default="summary" type="string">

<cfobject component="containers.component.search" name="containerSearch">


<main id="content" class="container-fluid">
	<section class="row">
		<div class="col-12 mb-2">
			<h1 class="h2">Container Diagnostics</h1>
			<p>
				Diagnostics for container hierarchy shape and potential data anomalies.
				This page does not modify data.
			</p>
		</div>
	</section>

	<section class="row">
		<cfset variables.summary = containerSearch.getContainerShapeSummary()>
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
		<cfflush>

		<cfset variables.depth = containerSearch.getContainerShapeByDepth()>
		<div class="col-12 col-xl-6 mb-2">
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
		<cfflush>
	</section>

	<section class="row">
		<cfset variables.hotspots = containerSearch.getContainerShapeHotspots()>
		<div class="col-12 mb-2">
			<div class="border rounded bg-light p-2">
				<h2 class="h4">A/B/AB Hotspots</h2>
				<p class="mb-1">
					A = structural, B = flat leaf-heavy, AB = mixed.
				</p>
				<table class="table table-sm table-striped d-xl-table">
					<thead>
						<tr>
							<th>Container ID</th>
							<th>Type</th>
							<th>Label</th>
							<th>Direct Children</th>
							<th>Direct Leaf Children</th>
							<th>Direct Structural Children</th>
							<th>Shape Class</th>
						</tr>
					</thead>
					<tbody>
						<cfoutput query="variables.hotspots">
							<tr>
								<td>
									<a href="/findContainer.cfm?container_id=#encodeForUrl(container_id)#" target="_blank">
										#encodeForHtml(container_id)#
									</a>
								</td>
								<td>#encodeForHtml(container_type)#</td>
								<td>#encodeForHtml(label)#</td>
								<td>#encodeForHtml(direct_children)#</td>
								<td>#encodeForHtml(direct_leaf_children)#</td>
								<td>#encodeForHtml(direct_structural_children)#</td>
								<td>#encodeForHtml(shape_class)#</td>
							</tr>
						</cfoutput>
					</tbody>
				</table>
			</div>
		</div>
	</section>
	<cfflush>

	<cfset variables.collObjAnomalies = containerSearch.getCollObjContHistAnomalies()>
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
