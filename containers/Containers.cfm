<!---
/containers/Containers.cfm
	Browse and search the container hierarchy.

Copyright 2008-2017 Contributors to Arctos
Copyright 2008-2026 President and Fellows of Harvard College

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
<cf_rolecheck>
<cfparam name="url.action" default="">
<cfparam name="url.container_id" default="">
<cfparam name="url.search_term" default="">
<cfparam name="url.container_type" default="">
<cfparam name="url.barcode" default="">
<cfparam name="url.description" default="">
<cfparam name="url.department" default="">
<cfparam name="url.tree_property" default="">
<cfparam name="url.execute" default="">
<cfset pageTitle = "Containers">
<cfset pageHasContainers = true>
<cfquery name="ctcontainer_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	SELECT container_type
	FROM ctcontainer_type
	ORDER BY container_type
</cfquery>
<cfinclude template="/shared/_header.cfm">
<link rel="stylesheet" href="/containers/css/containers.css">

<main id="content" class="container-fluid">
	<section class="container-fluid" role="search">
		<div class="row mx-0 mb-2">
			<div class="search-box col-12 px-0">
				<div class="search-box-header">
					<h1 class="h3 text-white">Find Containers</h1>
				</div>
				<div class="col-12 px-3 py-3">
					<cfoutput>
					<form id="containerSearchForm" name="containerSearch"
						method="get" action="Containers.cfm">
						<div class="form-row">
							<div class="col-12 col-md-4 col-xl-3 mb-2">
								<label for="container_type" class="data-entry-label">Container Type</label>
								<select id="container_type" name="container_type" class="data-entry-select col-12">
									<option value=""></option>
									<cfloop query="ctcontainer_type">
										<cfset variables.selectedType = "">
										<cfif ctcontainer_type.container_type EQ url.container_type>
											<cfset variables.selectedType = " selected">
										</cfif>
										<option value="#encodeForHtml(ctcontainer_type.container_type)#"#variables.selectedType#>#encodeForHtml(ctcontainer_type.container_type)#</option>
									</cfloop>
								</select>
							</div>
							<div class="col-12 col-md-4 col-xl-3 mb-2">
								<label for="search_term" class="data-entry-label">Name (label or barcode)</label>
								<input type="text" id="search_term" name="search_term"
									class="data-entry-input col-12"
									placeholder="Label or barcode"
									value="#encodeForHtml(url.search_term)#">
								<input type="hidden" id="container_id" name="container_id"
									value="#encodeForHtml(url.container_id)#">
							</div>
							<div class="col-12 col-md-4 col-xl-3 mb-2">
								<label for="barcode" class="data-entry-label">Unique Identifier (barcode)</label>
								<input type="text" id="barcode" name="barcode"
									class="data-entry-input col-12"
									placeholder="Barcode substring"
									value="#encodeForHtml(url.barcode)#">
							</div>
						</div>
						<div class="form-row">
							<div class="col-12 col-md-4 col-xl-3 mb-2">
								<label for="description" class="data-entry-label">Description / Remarks</label>
								<input type="text" id="description" name="description"
									class="data-entry-input col-12"
									placeholder="Description or remarks"
									value="#encodeForHtml(url.description)#">
							</div>
							<div class="col-12 col-md-4 col-xl-3 mb-2">
								<label for="department" class="data-entry-label">Department (label prefix, e.g. IZ, Ent)</label>
								<input type="text" id="department" name="department"
									class="data-entry-input col-12"
									placeholder="e.g. IZ, Ent, Mala"
									value="#encodeForHtml(url.department)#">
							</div>
							<div class="col-12 col-md-4 col-xl-3 mb-2">
								<label for="tree_property" class="data-entry-label">Tree Property</label>
								<cfset variables.selEmpty = "">
								<cfset variables.selMisplaced = "">
								<cfset variables.selMixed = "">
								<cfset variables.selUnplacedLeaf = "">
								<cfif url.tree_property EQ "empty">
									<cfset variables.selEmpty = " selected">
								<cfelseif url.tree_property EQ "misplaced">
									<cfset variables.selMisplaced = " selected">
								<cfelseif url.tree_property EQ "mixed">
									<cfset variables.selMixed = " selected">
								<cfelseif url.tree_property EQ "unplaced_leaf">
									<cfset variables.selUnplacedLeaf = " selected">
								</cfif>
								<select id="tree_property" name="tree_property" class="data-entry-select col-12">
									<option value="">(any)</option>
									<option value="empty"#variables.selEmpty#>Empty (no children)</option>
									<option value="misplaced"#variables.selMisplaced#>Misplaced (single-occupant with &gt;1 object)</option>
									<option value="mixed"#variables.selMixed#>AB Mixed (structural + object children)</option>
									<option value="unplaced_leaf"#variables.selUnplacedLeaf#>Unplaced object (no parent container)</option>
								</select>
							</div>
						</div>
						<div class="form-row">
							<div class="col-12 mb-2">
								<button type="submit" class="btn btn-xs btn-primary">Search</button>
								<button type="reset" class="btn btn-xs btn-warning">Reset</button>
								<a href="containerDiagnostics.cfm" class="btn btn-xs btn-secondary">Diagnostics</a>
							</div>
						</div>
					</form>
					</cfoutput>
				</div>
			</div>
		</div>
	</section>

	<section>
		<h2 class="h4">Container Hierarchy</h2>
		<p id="containerBrowseContext" class="text-muted small mb-2"></p>
		<div id="containerBrowsePanel">
			<div class="my-2 text-center"><img src="/shared/images/indicator.gif"> Loading...</div>
		</div>
		<div id="containerLeafPanel" class="d-none container-leaf-panel mt-2"></div>
	</section>

	<section class="mb-4">
		<output id="containerBrowseFeedback">&nbsp;</output>
	</section>
</main>

<cfoutput>
<script>
$(document).ready(function() {
	makeContainerAutocompleteMeta('search_term', 'container_id');

	$('##containerSearchForm').on('submit', function(e) {
		e.preventDefault();
		executeContainerSearch('containerBrowsePanel', 'containerLeafPanel', 'containerBrowseFeedback', 1);
	});

	<cfset variables.hasSearchParams = (
		len(trim(url.search_term)) GT 0 OR
		len(trim(url.container_type)) GT 0 OR
		len(trim(url.barcode)) GT 0 OR
		len(trim(url.description)) GT 0 OR
		len(trim(url.department)) GT 0 OR
		len(trim(url.tree_property)) GT 0 OR
		url.execute EQ "true"
	)>
	<cfif variables.hasSearchParams>
		executeContainerSearch('containerBrowsePanel', 'containerLeafPanel', 'containerBrowseFeedback', 1);
	<cfelse>
		initContainerBrowse("containerBrowsePanel", "containerLeafPanel", "containerBrowseFeedback");
	</cfif>
});
</script>
</cfoutput>

<cfinclude template="/shared/_footer.cfm">
