<!---
annotations/Annotations.cfm

Review annotations page. Provides a search interface for annotations, with filters on annotation metadata and on properties of the annotation target.

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
<cfset pageTitle = "Review Annotations">
<cfinclude template="/shared/_header.cfm">

<!--- URL parameter declarations: expose all supported search parameters from URL scope. --->
<cfparam name="url.execute" default="">
<cfparam name="url.target_type" default="">
<cfparam name="url.type" default="">
<cfparam name="url.state" default="">
<cfparam name="url.resolution" default="">
<cfparam name="url.annotator" default="">
<cfparam name="url.annotation_text" default="">
<cfparam name="url.motivation" default="">
<cfparam name="url.reviewed_fg" default="">
<cfparam name="url.root_mode" default="root">
<cfparam name="url.visibility" default="">
<cfparam name="url.collection" default="">
<cfparam name="url.specimen_guid" default="">
<cfparam name="url.collection_object_id" default="">
<cfparam name="url.id" default="">
<cfparam name="url.family" default="">
<cfparam name="url.taxon_family" default="">
<cfparam name="url.scientific_name" default="">
<cfparam name="url.taxon_name_id" default="">
<cfparam name="url.publication_id" default="">
<cfparam name="url.project_id" default="">

<cfset variables.execute = lcase(trim(url.execute))>
<cfset variables.target_type = trim(url.target_type)>
<cfif len(variables.target_type) EQ 0><cfset variables.target_type = trim(url.type)></cfif>
<cfset variables.state = trim(url.state)>
<cfset variables.resolution = trim(url.resolution)>
<cfset variables.annotator = trim(url.annotator)>
<cfset variables.annotation_text = trim(url.annotation_text)>
<cfset variables.motivation = trim(url.motivation)>
<cfset variables.reviewed_fg = trim(url.reviewed_fg)>
<cfset variables.root_mode = lcase(trim(url.root_mode))>
<cfset variables.visibility = trim(url.visibility)>
<cfset variables.collection = trim(url.collection)>
<cfset variables.specimen_guid = trim(url.specimen_guid)>
<cfset variables.collection_object_id = trim(url.collection_object_id)>
<cfif len(variables.collection_object_id) EQ 0 AND len(trim(url.id)) GT 0>
	<cfset variables.collection_object_id = trim(url.id)>
</cfif>
<cfset variables.family = trim(url.family)>
<cfif len(variables.family) EQ 0><cfset variables.family = trim(url.taxon_family)></cfif>
<cfset variables.scientific_name = trim(url.scientific_name)>
<cfset variables.taxon_name_id = trim(url.taxon_name_id)>
<cfset variables.publication_id = trim(url.publication_id)>
<cfset variables.project_id = trim(url.project_id)>
<cfset variables.publication_lookup = "">
<cfset variables.project_lookup = "">

<!--- Normalize target_type aliases and validate root_mode. --->
<cfswitch expression="#lcase(variables.target_type)#">
	<cfcase value="collection_object,collection_object_id"><cfset variables.target_type = "COLLECTION_OBJECT"></cfcase>
	<cfcase value="taxon_name,taxon_name_id"><cfset variables.target_type = "TAXON_NAME"></cfcase>
	<cfcase value="publication,publication_id"><cfset variables.target_type = "PUBLICATION"></cfcase>
	<cfcase value="project,project_id"><cfset variables.target_type = "PROJECT"></cfcase>
	<cfdefaultcase>
		<cfif len(variables.target_type) GT 0>
			<cfset variables.target_type = ucase(variables.target_type)>
		</cfif>
	</cfdefaultcase>
</cfswitch>
<cfif NOT listFindNoCase("root,response", variables.root_mode)>
	<cfset variables.root_mode = "root">
</cfif>

<cfset runSearch = false>
<cfif listFindNoCase("true,1,yes,y,on", variables.execute)>
	<cfset runSearch = true>
</cfif>
<cfif NOT runSearch AND (
	len(variables.target_type) GT 0 OR
	len(variables.specimen_guid) GT 0 OR
	len(variables.collection_object_id) GT 0 OR
	len(variables.family) GT 0 OR
	len(variables.taxon_name_id) GT 0 OR
	len(variables.publication_id) GT 0 OR
	len(variables.project_id) GT 0
)>
	<cfset runSearch = true>
</cfif>

<cfset variables.queryDatasource = "user_login">
<cfset variables.queryUsername = session.dbuser>
<cfset variables.queryPassword = decrypt(session.epw,cookie.cfid)>

<!--- Code-table and filter option queries: populate select controls and count badges. --->
<cfquery name="ctstate" datasource="#variables.queryDatasource#" username="#variables.queryUsername#" password="#variables.queryPassword#">
	SELECT
		count(annotations.state) AS ct,
		ctstate.state
	FROM ctstate
		LEFT JOIN annotations ON ctstate.state = annotations.state
	GROUP BY ctstate.state
	ORDER BY ctstate.state
</cfquery>
<cfquery name="ctresolution" datasource="#variables.queryDatasource#" username="#variables.queryUsername#" password="#variables.queryPassword#">
	SELECT
		count(annotations.resolution) AS ct,
		ctresolution.resolution
	FROM ctresolution
		LEFT JOIN annotations ON ctresolution.resolution = annotations.resolution
	GROUP BY ctresolution.resolution
	ORDER BY ctresolution.resolution
</cfquery>
<cfquery name="ctmotivation" datasource="#variables.queryDatasource#" username="#variables.queryUsername#" password="#variables.queryPassword#">
	SELECT
		count(annotations.motivation) AS ct,
		ctmotivation.motivation
	FROM ctmotivation
		LEFT JOIN annotations ON ctmotivation.motivation = annotations.motivation
	GROUP BY ctmotivation.motivation
	ORDER BY ctmotivation.motivation
</cfquery>
<cfquery name="getAnnotatedTargetTypes" datasource="#variables.queryDatasource#" username="#variables.queryUsername#" password="#variables.queryPassword#">
	SELECT
		resolved_targets.target_table,
		count(*) ct
	FROM (
		SELECT
			CASE
				WHEN annotations.target_table = 'ANNOTATIONS' THEN parent_annotations.target_table
				ELSE annotations.target_table
			END target_table
		FROM
			annotations
			LEFT OUTER JOIN annotations parent_annotations ON annotations.target_table = 'ANNOTATIONS'
				AND annotations.target_primary_key = parent_annotations.annotation_id
	) resolved_targets
	WHERE resolved_targets.target_table IS NOT NULL
	GROUP BY resolved_targets.target_table
	ORDER BY resolved_targets.target_table
</cfquery>
<cfquery name="getAnnotatedCollections" datasource="#variables.queryDatasource#" username="#variables.queryUsername#" password="#variables.queryPassword#">
	SELECT
		count(annotations.annotation_id) ct,
		collection.collection
	FROM collection
		JOIN cataloged_item ON collection.collection_id = cataloged_item.collection_id
		JOIN annotations ON annotations.target_table = 'COLLECTION_OBJECT'
			AND annotations.target_primary_key = cataloged_item.collection_object_id
	GROUP BY collection.collection
	ORDER BY collection.collection
</cfquery>
<cfquery name="getAnnotatedFamilies" datasource="#variables.queryDatasource#" username="#variables.queryUsername#" password="#variables.queryPassword#">
	SELECT
		count(annotations.annotation_id) ct,
		taxonomy.family
	FROM annotations
		INNER JOIN taxonomy ON annotations.target_table = 'TAXON_NAME'
			AND annotations.target_primary_key = taxonomy.taxon_name_id
	WHERE taxonomy.family IS NOT NULL
	GROUP BY taxonomy.family
	ORDER BY taxonomy.family
</cfquery>
<cfquery name="reviewedCounts" datasource="#variables.queryDatasource#" username="#variables.queryUsername#" password="#variables.queryPassword#">
	SELECT reviewed_fg, count(annotation_id) ct
	FROM annotations
	WHERE reviewed_fg IN (0,1)
	GROUP BY reviewed_fg
</cfquery>
<cfquery name="visibilityCounts" datasource="#variables.queryDatasource#" username="#variables.queryUsername#" password="#variables.queryPassword#">
	SELECT mask_annotation_fg, count(annotation_id) ct
	FROM annotations
	WHERE mask_annotation_fg IN (0,1)
	GROUP BY mask_annotation_fg
</cfquery>
<cfset variables.reviewedCountReviewed = 0>
<cfset variables.reviewedCountNotReviewed = 0>
<cfloop query="reviewedCounts">
	<cfif reviewedCounts.reviewed_fg IS 1>
		<cfset variables.reviewedCountReviewed = reviewedCounts.ct>
	<cfelseif reviewedCounts.reviewed_fg IS 0>
		<cfset variables.reviewedCountNotReviewed = reviewedCounts.ct>
	</cfif>
</cfloop>
<cfset variables.visibilityCountVisible = 0>
<cfset variables.visibilityCountMasked = 0>
<cfloop query="visibilityCounts">
	<cfif visibilityCounts.mask_annotation_fg IS 0>
		<cfset variables.visibilityCountVisible = visibilityCounts.ct>
	<cfelseif visibilityCounts.mask_annotation_fg IS 1>
		<cfset variables.visibilityCountMasked = visibilityCounts.ct>
	</cfif>
</cfloop>
<cfif len(variables.publication_id) GT 0 AND isNumeric(variables.publication_id)>
	<cfquery name="getPublicationDisplay" datasource="#variables.queryDatasource#" username="#variables.queryUsername#" password="#variables.queryPassword#">
		SELECT MCZbase.getshortcitation(publication_id) short_citation
		FROM publication
		WHERE publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.publication_id#">
	</cfquery>
	<cfif getPublicationDisplay.recordcount GT 0>
		<cfset variables.publication_lookup = getPublicationDisplay.short_citation>
	</cfif>
</cfif>
<cfif len(variables.project_id) GT 0 AND isNumeric(variables.project_id)>
	<cfquery name="getProjectDisplay" datasource="#variables.queryDatasource#" username="#variables.queryUsername#" password="#variables.queryPassword#">
		SELECT project_name
		FROM project
		WHERE project_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.project_id#">
	</cfquery>
	<cfif getProjectDisplay.recordcount GT 0>
		<cfset variables.project_lookup = getProjectDisplay.project_name>
	</cfif>
</cfif>

<!--- Search form: annotation metadata filters, target type, and target-specific context filters. --->
<main class="container-fluid" id="content">
	<section role="search">
		<div class="row mx-0 mb-2">
			<div class="search-box col-12 px-0">
				<div class="search-box-header">
					<h1 class="h3 text-white">Review Annotations</h1>
				</div>
				<cfoutput>
				<div class="col-12 px-3 py-3">
					<form id="annotationSearchForm" method="get" action="/annotations/Annotations.cfm" class="row">
						<input type="hidden" name="execute" value="true">
						<div class="col-12 col-md-6 col-xl-2 mb-3 d-flex flex-column">
							<h2 class="h5 mb-2">Annotation Metadata Filters</h2>
							<div class="form-group mb-2">
								<label for="state" class="data-entry-label">State</label>
								<select name="state" id="state" class="data-entry-select col-12">
									<option value="">Any State</option>
									<cfloop query="ctstate">
										<cfif variables.state EQ state><cfset local.selected = "selected"><cfelse><cfset local.selected = ""></cfif>
										<option value="#encodeForHTML(state)#" #local.selected#>#encodeForHTML(state)# (#ct#)</option>
									</cfloop>
								</select>
							</div>
							<div class="form-group mb-2">
								<label for="resolution" class="data-entry-label">Resolution</label>
								<select name="resolution" id="resolution" class="data-entry-select col-12">
									<option value="">Any Resolution</option>
									<cfloop query="ctresolution">
										<cfif variables.resolution EQ resolution><cfset local.selected = "selected"><cfelse><cfset local.selected = ""></cfif>
										<option value="#encodeForHTML(resolution)#" #local.selected#>#encodeForHTML(resolution)# (#ct#)</option>
									</cfloop>
								</select>
							</div>
							<div class="form-group mb-2">
								<label for="motivation" class="data-entry-label">Motivation</label>
								<select name="motivation" id="motivation" class="data-entry-select col-12">
									<option value="">Any Motivation</option>
									<cfloop query="ctmotivation">
										<cfif variables.motivation EQ motivation><cfset local.selected = "selected"><cfelse><cfset local.selected = ""></cfif>
										<option value="#encodeForHTML(motivation)#" #local.selected#>#encodeForHTML(motivation)# (#ct#)</option>
									</cfloop>
								</select>
							</div>
							<div class="mt-auto pt-2">
								<button type="submit" class="btn btn-xs btn-primary">Search</button>
								<a href="/annotations/Annotations.cfm" class="btn btn-xs btn-warning">Reset</a>
							</div>
						</div>

						<div class="col-12 col-md-6 col-xl-2 mb-3">
							<h2 class="h5 mb-2">Annotation Text and Review Filters</h2>
							<div class="form-group mb-2">
								<label for="annotator" class="data-entry-label">Annotator Username</label>
								<input type="text" name="annotator" id="annotator" value="#encodeForHTML(variables.annotator)#" class="data-entry-input col-12">
							</div>
							<div class="form-group mb-2">
								<label for="annotation_text" class="data-entry-label">Annotation Body Text</label>
								<input type="text" name="annotation_text" id="annotation_text" value="#encodeForHTML(variables.annotation_text)#" class="data-entry-input col-12">
							</div>
							<div class="form-group mb-2">
								<label for="reviewed_fg" class="data-entry-label">Reviewed</label>
								<select name="reviewed_fg" id="reviewed_fg" class="data-entry-select col-12">
									<option value="">Any</option>
									<cfif variables.reviewed_fg EQ "1"><cfset local.selected = "selected"><cfelse><cfset local.selected = ""></cfif>
									<option value="1" #local.selected#>Reviewed (#variables.reviewedCountReviewed#)</option>
									<cfif variables.reviewed_fg EQ "0"><cfset local.selected = "selected"><cfelse><cfset local.selected = ""></cfif>
									<option value="0" #local.selected#>Not Reviewed (#variables.reviewedCountNotReviewed#)</option>
								</select>
							</div>
							<div class="form-group mb-2">
								<label for="visibility" class="data-entry-label">Visibility</label>
								<select name="visibility" id="visibility" class="data-entry-select col-12">
									<option value="">Any</option>
									<cfif variables.visibility EQ "0"><cfset local.selected = "selected"><cfelse><cfset local.selected = ""></cfif>
									<option value="0" #local.selected#>Visible (#variables.visibilityCountVisible#)</option>
									<cfif variables.visibility EQ "1"><cfset local.selected = "selected"><cfelse><cfset local.selected = ""></cfif>
									<option value="1" #local.selected#>Masked (#variables.visibilityCountMasked#)</option>
								</select>
							</div>
						</div>

						<div class="col-12 col-md-6 col-xl-3 mb-3">
							<div class="form-group mb-2">
								<label for="target_type" class="data-entry-label">Target Type</label>
								<select name="target_type" id="target_type" class="data-entry-select col-12">
									<option value="">All Target Types</option>
									<cfloop query="getAnnotatedTargetTypes">
										<cfset target_type_label = "">
										<cfswitch expression="#target_table#">
											<cfcase value="COLLECTION_OBJECT"><cfset target_type_label = "Specimen"></cfcase>
											<cfcase value="TAXON_NAME"><cfset target_type_label = "Taxon"></cfcase>
											<cfcase value="PUBLICATION"><cfset target_type_label = "Publication"></cfcase>
											<cfcase value="PROJECT"><cfset target_type_label = "Project"></cfcase>
											<cfdefaultcase><cfset target_type_label = rereplace(lcase(target_table), "_", " ", "all")></cfdefaultcase>
										</cfswitch>
										<cfif variables.target_type EQ target_table><cfset local.selected = "selected"><cfelse><cfset local.selected = ""></cfif>
										<option value="#encodeForHTML(target_table)#" #local.selected#>#encodeForHTML(target_type_label)# (#ct#)</option>
									</cfloop>
								</select>
							</div>
							<h2 class="h5 mb-2">Target-Specific Context Filters</h2>
							<h3 class="h6 mb-2">Specimen Filters</h3>
							<div class="form-group mb-2" data-target-group="specimen">
								<label for="collection" class="data-entry-label">Collection</label>
								<select name="collection" id="collection" class="data-entry-select col-12">
									<option value="">Any Collection</option>
									<cfloop query="getAnnotatedCollections">
										<cfif variables.collection EQ collection><cfset local.selected = "selected"><cfelse><cfset local.selected = ""></cfif>
										<option value="#encodeForHTML(collection)#" #local.selected#>#encodeForHTML(collection)# (#ct#)</option>
									</cfloop>
								</select>
							</div>
							<div class="form-group mb-2" data-target-group="specimen">
								<label for="specimen_guid" class="data-entry-label">Specimen GUID</label>
								<input type="text" name="specimen_guid" id="specimen_guid" value="#encodeForHTML(variables.specimen_guid)#" class="data-entry-input col-12" placeholder="MCZ:Herp:A-12345">
							</div>
							<div class="form-group mb-2" data-target-group="specimen">
								<label for="collection_object_id" class="data-entry-label">Collection Object ID</label>
								<input type="text" name="collection_object_id" id="collection_object_id" value="#encodeForHTML(variables.collection_object_id)#" class="data-entry-input col-12">
							</div>
						</div>
						<div class="col-12 col-md-6 col-xl-2 mb-3">
							<h3 class="h6 mb-2">Taxon Filters</h3>
							<div class="form-group mb-2" data-target-group="taxon">
								<label for="family" class="data-entry-label">Family</label>
								<select name="family" id="family" class="data-entry-select col-12">
									<option value="">Any Family</option>
									<cfloop query="getAnnotatedFamilies">
										<cfif variables.family EQ family><cfset local.selected = "selected"><cfelse><cfset local.selected = ""></cfif>
										<option value="#encodeForHTML(family)#" #local.selected#>#encodeForHTML(family)# (#ct#)</option>
									</cfloop>
								</select>
							</div>
							<div class="form-group mb-2" data-target-group="taxon">
								<label for="scientific_name" class="data-entry-label">Scientific Name Contains</label>
								<input type="text" name="scientific_name" id="scientific_name" value="#encodeForHTML(variables.scientific_name)#" class="data-entry-input col-12">
							</div>
							<div class="form-group mb-2" data-target-group="taxon">
								<label for="taxon_name_id" class="data-entry-label">Taxon Name ID</label>
								<input type="text" name="taxon_name_id" id="taxon_name_id" value="#encodeForHTML(variables.taxon_name_id)#" class="data-entry-input col-12">
							</div>
						</div>

						<div class="col-12 col-md-6 col-xl-3 mb-3">
							<h2 class="h5 mb-2">Publication and Project Filters</h2>
							<div class="form-group mb-2" data-target-group="publication">
								<label for="publication_lookup" class="data-entry-label">Publication Citation or Title</label>
								<input type="hidden" name="publication_id" id="publication_id" value="#encodeForHTML(variables.publication_id)#">
								<input type="text" name="publication_lookup" id="publication_lookup" value="#encodeForHTML(variables.publication_lookup)#" class="data-entry-input col-12">
							</div>
							<div class="form-group mb-3" data-target-group="project">
								<label for="project_lookup" class="data-entry-label">Project Title</label>
								<input type="hidden" name="project_id" id="project_id" value="#encodeForHTML(variables.project_id)#">
								<input type="text" name="project_lookup" id="project_lookup" value="#encodeForHTML(variables.project_lookup)#" class="data-entry-input col-12">
							</div>
						</div>
					</form>
					<script>
						(function () {
							var form = document.getElementById('annotationSearchForm');
							if (!form) { return; }
							var targetTypeInput = document.getElementById('target_type');
							// Single config object: add new target types here only.
							var groupConfig = {
								specimen:    { targetType: 'COLLECTION_OBJECT', fields: ['collection', 'specimen_guid', 'collection_object_id'] },
								taxon:       { targetType: 'TAXON_NAME',        fields: ['family', 'scientific_name', 'taxon_name_id'] },
								publication: { targetType: 'PUBLICATION',       fields: ['publication_lookup', 'publication_id'] },
								project:     { targetType: 'PROJECT',           fields: ['project_lookup', 'project_id'] }
							};
							// Derived lookups — no manual update needed when groupConfig is extended.
							var allGroups = Object.keys(groupConfig);
							var targetTypeToGroup = {};
							allGroups.forEach(function (groupName) {
								targetTypeToGroup[groupConfig[groupName].targetType] = [groupName];
							});
							function clearGroup(groupName) {
								groupConfig[groupName].fields.forEach(function (fieldId) {
									var field = document.getElementById(fieldId);
									if (field) { field.value = ''; }
								});
							}
							function setGroupState(activeGroups, clearInconsistentValues) {
								allGroups.forEach(function (groupName) {
									var active = activeGroups.indexOf(groupName) !== -1;
									var groupBlocks = form.querySelectorAll('[data-target-group="' + groupName + '"]');
									groupBlocks.forEach(function (block) {
										block.classList.toggle('opacity-50', !active);
										block.classList.toggle('text-muted', !active);
									});
									groupConfig[groupName].fields.forEach(function (fieldId) {
										var field = document.getElementById(fieldId);
										if (field) {
											field.disabled = !active;
											field.classList.toggle('bg-light', !active);
											field.classList.toggle('text-muted', !active);
										}
									});
									if (!active && clearInconsistentValues) {
										clearGroup(groupName);
									}
								});
							}
							function inferTargetType() {
								var filledGroups = [];
								allGroups.forEach(function (groupName) {
									var groupHasValue = groupConfig[groupName].fields.some(function (fieldId) {
										var field = document.getElementById(fieldId);
										return field && String(field.value).trim().length > 0;
									});
									if (groupHasValue) { filledGroups.push(groupName); }
								});
								if (filledGroups.length === 1) {
									targetTypeInput.value = groupConfig[filledGroups[0]].targetType;
								}
								if (filledGroups.length > 1) {
									// Deterministic precedence for conflicts: use order from groupConfig.
									var selectedGroup = allGroups.find(function (groupName) {
										return filledGroups.indexOf(groupName) !== -1;
									}) || allGroups[0];
									targetTypeInput.value = groupConfig[selectedGroup].targetType;
								}
							}
							function applyTargetTypeState(clearInconsistentValues) {
								var selectedTargetType = targetTypeInput.value ? targetTypeInput.value.toUpperCase() : '';
								var activeGroups = targetTypeToGroup[selectedTargetType] || allGroups;
								setGroupState(activeGroups, clearInconsistentValues);
							}
							targetTypeInput.addEventListener('change', function () {
								applyTargetTypeState(true);
							});
							if (typeof makePublicationAutocompleteMeta === 'function') {
								makePublicationAutocompleteMeta('publication_lookup', 'publication_id');
							} else {
								console.warn('Publication autocomplete unavailable. Use publication_id in URL parameters for publication filtering.');
							}
							if (typeof makeProjectAutocompleteMeta === 'function') {
								makeProjectAutocompleteMeta('project_lookup', 'project_id');
							} else {
								console.warn('Project autocomplete unavailable. Use project_id in URL parameters for project filtering.');
							}
							var publicationLookupInput = document.getElementById('publication_lookup');
							var publicationIdInput = document.getElementById('publication_id');
							if (publicationLookupInput && publicationIdInput) {
								publicationLookupInput.addEventListener('input', function () {
									if (this.value.trim().length === 0) {
										publicationIdInput.value = '';
									}
								});
							}
							var projectLookupInput = document.getElementById('project_lookup');
							var projectIdInput = document.getElementById('project_id');
							if (projectLookupInput && projectIdInput) {
								projectLookupInput.addEventListener('input', function () {
									if (this.value.trim().length === 0) {
										projectIdInput.value = '';
									}
								});
							}
							function showSearchingMarker() {
								var resultsContainer = document.getElementById('annotationSearchResultsContainer');
								if (!resultsContainer) { return; }
								resultsContainer.innerHTML = '<p class="mt-3 text-muted pl-1">Searching...</p>';
							}
							function buildSearchQueryString() {
								var params = new URLSearchParams();
								params.set('execute', 'true');
								Array.prototype.forEach.call(form.elements, function (field) {
									if (!field || !field.name || field.disabled || field.name === 'execute') { return; }
									var fieldType = (field.type || '').toLowerCase();
									if (fieldType === 'submit' || fieldType === 'button' || fieldType === 'reset' || fieldType === 'file') { return; }
									if ((fieldType === 'checkbox' || fieldType === 'radio') && !field.checked) { return; }
									var value = String(field.value || '').trim();
									if (value.length > 0) {
										params.append(field.name, value);
									}
								});
								return params.toString();
							}
							function loadResults(queryString) {
								var resultsContainer = document.getElementById('annotationSearchResultsContainer');
								if (!resultsContainer) { return; }
								showSearchingMarker();
								fetch('/annotations/component/search.cfc?method=renderAnnotationSearchResults&returnformat=plain&' + queryString, { credentials: 'same-origin' })
									.then(function (response) {
										if (!response.ok) {
											throw new Error('Failed to load annotation results');
										}
										return response.text();
									})
									.then(function (html) {
										resultsContainer.innerHTML = html;
									})
									.catch(function (error) {
										console.error(error);
										resultsContainer.innerHTML = '<p class="mt-3 text-danger pl-1">Unable to load search results.</p>';
									});
							}
							form.addEventListener('submit', function (event) {
								event.preventDefault();
								inferTargetType();
								applyTargetTypeState(true);
								var queryString = buildSearchQueryString();
								history.replaceState({}, '', window.location.pathname + '?' + queryString);
								loadResults(queryString);
							});
							applyTargetTypeState(false);
							<cfif runSearch>
								var initialParams = new URLSearchParams(window.location.search);
								initialParams.set('execute', 'true');
								loadResults(initialParams.toString());
							</cfif>
						})();
					</script>
				</div>
				</cfoutput>
			</div>
		</div>
	</section>

	<!--- Results container: AJAX-loaded by JavaScript; noscript fallback renders server-side. --->
	<section class="row mx-0 mb-4">
		<div class="col-12">
			<div id="annotationSearchResultsContainer">
				<cfif runSearch>
					<p class="mt-3 text-muted pl-1">Searching...</p>
				<cfelse>
					<p class="mt-3 text-muted pl-1">Set filters and click Search.</p>
				</cfif>
			</div>
			<noscript>
				<cfset variables.noscriptResultsHtml = "">
				<cfinvoke component="/annotations/component/search" method="renderAnnotationSearchResults" returnvariable="variables.noscriptResultsHtml"
					execute="#runSearch#"
					target_type="#variables.target_type#"
					state="#variables.state#"
					resolution="#variables.resolution#"
					annotator="#variables.annotator#"
					annotation_text="#variables.annotation_text#"
					motivation="#variables.motivation#"
					reviewed_fg="#variables.reviewed_fg#"
					root_mode="#variables.root_mode#"
					visibility="#variables.visibility#"
					collection="#variables.collection#"
					specimen_guid="#variables.specimen_guid#"
					collection_object_id="#variables.collection_object_id#"
					family="#variables.family#"
					scientific_name="#variables.scientific_name#"
					taxon_name_id="#variables.taxon_name_id#"
					publication_id="#variables.publication_id#"
					project_id="#variables.project_id#">
				<cfoutput>#variables.noscriptResultsHtml#</cfoutput>
			</noscript>
		</div>
	</section>
</main>
<cfinclude template="/shared/_footer.cfm">
