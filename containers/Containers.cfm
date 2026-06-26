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
<cfset pageTitle = "Containers">
<cfset pageHasContainers = true>
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
						method="get" onsubmit="return false;">
						<div class="form-row">
							<div class="col-12 col-md-5 col-xl-4 mb-2">
								<label for="search_term" class="data-entry-label">Label, barcode, or container ID</label>
								<input type="text" id="search_term" name="search_term"
									class="data-entry-input col-12"
									placeholder="Label, barcode, or container ID"
									value="#encodeForHtml(url.search_term)#">
								<input type="hidden" id="container_id" name="container_id"
									value="#encodeForHtml(url.container_id)#">
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

<script>
$(document).ready(function() {
	initContainerBrowse("containerBrowsePanel", "containerLeafPanel", "containerBrowseFeedback");
});
</script>

<cfinclude template="/shared/_footer.cfm">
