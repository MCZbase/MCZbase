<!---
annotations/Annotations.cfm

Review annotations page. Provides a unified annotation-first search interface with target-aware contextual filters.

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

<!--- Explicit URL scope declarations for URL-driven population/execution. --->
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

<cfset annotationFunctions = CreateObject("component","annotations.component.functions")>
<cfset annotationSearch = CreateObject("component","annotations.component.search")>
<cfset variables.queryDatasource = "user_login">
<cfset variables.queryUsername = session.dbuser>
<cfset variables.queryPassword = decrypt(session.epw,cookie.cfid)>
<cfquery name="ctstate" datasource="#variables.queryDatasource#" username="#variables.queryUsername#" password="#variables.queryPassword#">
	SELECT
		ctstate.state,
		NVL(annotation_counts.ct, 0) ct
	FROM ctstate
		LEFT OUTER JOIN (
			SELECT state, count(annotation_id) ct
			FROM annotations
			WHERE state IS NOT NULL
			GROUP BY state
		) annotation_counts ON ctstate.state = annotation_counts.state
	ORDER BY ctstate.state
</cfquery>
<cfquery name="ctresolution" datasource="#variables.queryDatasource#" username="#variables.queryUsername#" password="#variables.queryPassword#">
	SELECT
		ctresolution.resolution,
		NVL(annotation_counts.ct, 0) ct
	FROM ctresolution
		LEFT OUTER JOIN (
			SELECT resolution, count(annotation_id) ct
			FROM annotations
			WHERE resolution IS NOT NULL
			GROUP BY resolution
		) annotation_counts ON ctresolution.resolution = annotation_counts.resolution
	ORDER BY ctresolution.resolution
</cfquery>
<cfquery name="ctmotivation" datasource="#variables.queryDatasource#" username="#variables.queryUsername#" password="#variables.queryPassword#">
	SELECT
		ctmotivation.motivation,
		NVL(annotation_counts.ct, 0) ct
	FROM ctmotivation
		LEFT OUTER JOIN (
			SELECT motivation, count(annotation_id) ct
			FROM annotations
			WHERE motivation IS NOT NULL
			GROUP BY motivation
		) annotation_counts ON ctmotivation.motivation = annotation_counts.motivation
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
<cfset searchResults = QueryNew("")>
<cfset childAnnotations = QueryNew("")>

<cfif runSearch>
	<cfset searchResults = annotationSearch.findAnnotations(
		target_type = variables.target_type,
		state = variables.state,
		resolution = variables.resolution,
		annotator = variables.annotator,
		annotation_text = variables.annotation_text,
		motivation = variables.motivation,
		reviewed_fg = variables.reviewed_fg,
		root_mode = variables.root_mode,
		visibility = variables.visibility,
		collection = variables.collection,
		specimen_guid = variables.specimen_guid,
		collection_object_id = variables.collection_object_id,
		family = variables.family,
		scientific_name = variables.scientific_name,
		taxon_name_id = variables.taxon_name_id,
		publication_id = variables.publication_id,
		project_id = variables.project_id
	)>
	<cfif searchResults.recordcount GT 0>
		<cfquery name="rootAnnotationsInResults" dbtype="query">
			SELECT annotation_id
			FROM searchResults
			WHERE parent_annotation_id IS NULL
		</cfquery>
		<cfif rootAnnotationsInResults.recordcount GT 0>
			<cfset childAnnotations = annotationFunctions.getChildAnnotationsForRoots(valueList(rootAnnotationsInResults.annotation_id))>
		</cfif>
	</cfif>
</cfif>

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
										<option value="#encodeForHTML(state)#" <cfif variables.state EQ state>selected="selected"</cfif>>#encodeForHTML(state)# (#ct#)</option>
									</cfloop>
								</select>
							</div>
							<div class="form-group mb-2">
								<label for="resolution" class="data-entry-label">Resolution</label>
								<select name="resolution" id="resolution" class="data-entry-select col-12">
									<option value="">Any Resolution</option>
									<cfloop query="ctresolution">
										<option value="#encodeForHTML(resolution)#" <cfif variables.resolution EQ resolution>selected="selected"</cfif>>#encodeForHTML(resolution)# (#ct#)</option>
									</cfloop>
								</select>
							</div>
							<div class="form-group mb-2">
								<label for="motivation" class="data-entry-label">Motivation</label>
								<select name="motivation" id="motivation" class="data-entry-select col-12">
									<option value="">Any Motivation</option>
									<cfloop query="ctmotivation">
										<option value="#encodeForHTML(motivation)#" <cfif variables.motivation EQ motivation>selected="selected"</cfif>>#encodeForHTML(motivation)# (#ct#)</option>
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
									<option value="1" <cfif variables.reviewed_fg EQ "1">selected="selected"</cfif>>Reviewed (#variables.reviewedCountReviewed#)</option>
									<option value="0" <cfif variables.reviewed_fg EQ "0">selected="selected"</cfif>>Not Reviewed (#variables.reviewedCountNotReviewed#)</option>
								</select>
							</div>
							<div class="form-group mb-2">
								<label for="visibility" class="data-entry-label">Visibility</label>
								<select name="visibility" id="visibility" class="data-entry-select col-12">
									<option value="">Any</option>
									<option value="0" <cfif variables.visibility EQ "0">selected="selected"</cfif>>Visible (#variables.visibilityCountVisible#)</option>
									<option value="1" <cfif variables.visibility EQ "1">selected="selected"</cfif>>Masked (#variables.visibilityCountMasked#)</option>
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
										<option value="#encodeForHTML(target_table)#" <cfif variables.target_type EQ target_table>selected="selected"</cfif>>#encodeForHTML(target_type_label)# (#ct#)</option>
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
										<option value="#encodeForHTML(collection)#" <cfif variables.collection EQ collection>selected="selected"</cfif>>#encodeForHTML(collection)# (#ct#)</option>
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
										<option value="#encodeForHTML(family)#" <cfif variables.family EQ family>selected="selected"</cfif>>#encodeForHTML(family)# (#ct#)</option>
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
							var groupFields = {
								specimen: ['collection', 'specimen_guid', 'collection_object_id'],
								taxon: ['family', 'scientific_name', 'taxon_name_id'],
								publication: ['publication_lookup', 'publication_id'],
								project: ['project_lookup', 'project_id']
							};
							var groupToTargetType = {
								specimen: 'COLLECTION_OBJECT',
								taxon: 'TAXON_NAME',
								publication: 'PUBLICATION',
								project: 'PROJECT'
							};
							var targetTypeToGroup = {
								COLLECTION_OBJECT: ['specimen'],
								TAXON_NAME: ['taxon'],
								PUBLICATION: ['publication'],
								PROJECT: ['project']
							};
							function clearGroup(groupName) {
								groupFields[groupName].forEach(function (fieldId) {
									var field = document.getElementById(fieldId);
									if (field) { field.value = ''; }
								});
							}
							function setGroupState(activeGroups, clearInconsistentValues) {
								var allGroups = ['specimen', 'taxon', 'publication', 'project'];
								allGroups.forEach(function (groupName) {
									var active = activeGroups.indexOf(groupName) !== -1;
									groupFields[groupName].forEach(function (fieldId) {
										var field = document.getElementById(fieldId);
										if (field) { field.disabled = !active; }
									});
									if (!active && clearInconsistentValues) {
										clearGroup(groupName);
									}
								});
							}
							function inferTargetType() {
								var filledGroups = [];
								Object.keys(groupFields).forEach(function (groupName) {
									var groupHasValue = groupFields[groupName].some(function (fieldId) {
										var field = document.getElementById(fieldId);
										return field && String(field.value).trim().length > 0;
									});
									if (groupHasValue) { filledGroups.push(groupName); }
								});
								if (filledGroups.length === 1) {
									targetTypeInput.value = groupToTargetType[filledGroups[0]];
								}
								if (filledGroups.length > 1) {
									var orderedGroups = ['specimen', 'taxon', 'publication', 'project'];
									// Deterministic precedence for conflicts: specimen, then taxon, then publication, then project.
									var selectedGroup = orderedGroups.find(function (groupName) {
										return filledGroups.indexOf(groupName) !== -1;
									}) || orderedGroups[0];
									targetTypeInput.value = groupToTargetType[selectedGroup];
								}
							}
							function applyTargetTypeState(clearInconsistentValues) {
								var selectedTargetType = targetTypeInput.value ? targetTypeInput.value.toUpperCase() : '';
								var activeGroups = targetTypeToGroup[selectedTargetType] || ['specimen', 'taxon', 'publication', 'project'];
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
							form.addEventListener('submit', function () {
								inferTargetType();
								applyTargetTypeState(true);
							});
							applyTargetTypeState(false);
						})();
					</script>
				</div>
				</cfoutput>
			</div>
		</div>
	</section>

	<section class="row mx-0 mb-4">
		<div class="col-12">
			<cfoutput>
			<cfif runSearch>
				<cfset targetCount = 0>
				<cfif searchResults.recordcount GT 0>
					<cfquery name="targets" dbtype="query">
						SELECT target_table, target_key, collection_object_id, institution_acronym, collection_cde, cat_num,
							idAs, higher_geog, spec_locality, taxon_name_id, taxon_scientific_name, taxon_display_name,
							publication_id, publication_title, project_id, project_name
						FROM searchResults
						GROUP BY target_table, target_key, collection_object_id, institution_acronym, collection_cde, cat_num,
							idAs, higher_geog, spec_locality, taxon_name_id, taxon_scientific_name, taxon_display_name,
							publication_id, publication_title, project_id, project_name
						ORDER BY target_table, target_key
					</cfquery>
					<cfset targetCount = targets.recordcount>
				</cfif>
				<h2 class="h3 mt-3 pl-1">Annotation Results (#searchResults.recordcount# annotations on #targetCount# targets)</h2>
				<cfif searchResults.recordcount EQ 0>
					<p class="text-muted pl-1">No annotations found matching the selected filters.</p>
				<cfelse>
					<cfloop query="targets">
						<cfset targetTitle = "">
						<cfset targetLink = "">
						<cfset targetMeta = "">
						<cfset targetTitleContainsHtml = false>
						<cfswitch expression="#ucase(targets.target_table)#">
							<cfcase value="COLLECTION_OBJECT">
								<cfset specimenGuid = "#targets.institution_acronym#:#targets.collection_cde#:#targets.cat_num#">
								<cfset targetTitle = specimenGuid>
								<cfset targetLink = "/guid/#encodeForURL(specimenGuid)#">
								<cfset targetMeta = "Current Identification: #encodeForHTML(targets.idAs)#; Locality: #encodeForHTML(targets.higher_geog)#: #encodeForHTML(targets.spec_locality)#">
							</cfcase>
							<cfcase value="TAXON_NAME">
								<cfset targetTitle = targets.taxon_display_name>
								<cfset targetLink = "/name/#encodeForURL(targets.taxon_scientific_name)#">
								<cfset targetTitleContainsHtml = true>
							</cfcase>
							<cfcase value="PUBLICATION">
								<cfset targetTitle = targets.publication_title>
								<cfset targetLink = "/publications/showPublication.cfm?publication_id=#encodeForURL(targets.publication_id)#">
							</cfcase>
							<cfcase value="PROJECT">
								<cfset targetTitle = targets.project_name>
								<cfset targetLink = "/ProjectDetail?project_id=#encodeForURL(targets.project_id)#">
							</cfcase>
							<cfdefaultcase>
								<cfset targetTitle = "Target #encodeForHTML(targets.target_key)#">
							</cfdefaultcase>
						</cfswitch>

						<div class="col-12 px-0 my-2 card border-bottom-0">
							<div class="card-header bg-box-header-gray">
								<h3 class="h4 mb-0">
									<cfif len(targetLink) GT 0>
										<a href="#targetLink#" target="_blank"><cfif targetTitleContainsHtml>#targetTitle#<cfelse>#encodeForHTML(targetTitle)#</cfif></a>
									<cfelse>
										<cfif targetTitleContainsHtml>#targetTitle#<cfelse>#encodeForHTML(targetTitle)#</cfif>
									</cfif>
									<cfif len(targetMeta) GT 0><span class="ml-2 small">#targetMeta#</span></cfif>
								</h3>
							</div>
							<cfquery name="itemAnno" dbtype="query">
								SELECT annotation_id, annotation_display, cf_username, email, annotate_date, motivation, reviewed_fg,
									state, resolution, reviewer, reviewer_comment, mask_annotation_fg, parent_annotation_id
								FROM searchResults
								WHERE target_table = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#targets.target_table#">
									AND target_key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#targets.target_key#">
							</cfquery>
							<cfloop query="itemAnno">
								<cfset showReplyAction = false>
								<cfif NOT isNumeric(parent_annotation_id)>
									<cfset showReplyAction = true>
								</cfif>
								<div id="annotation-block-#annotation_id#">
								<cfinvoke component="/annotations/component/functions" method="renderAnnotationReviewRow" returnvariable="annoRowHTML"
									annotation_id="#annotation_id#"
									annotation_display="#annotation_display#"
									cf_username="#cf_username#"
									email="#email#"
									annotate_date="#annotate_date#"
									motivation="#motivation#"
									reviewed_fg="#reviewed_fg#"
									state="#state#"
									resolution="#resolution#"
									reviewer="#reviewer#"
									reviewer_comment="#reviewer_comment#"
									mask_annotation_fg="#mask_annotation_fg#"
									show_reply_action="#showReplyAction#">
								#annoRowHTML#
								<cfif showReplyAction>
									#annotationFunctions.renderAnnotationConversationSection(rootAnnotationId=annotation_id, childAnnotations=childAnnotations, root_mask_annotation_fg=mask_annotation_fg)#
								</cfif>
								</div>
							</cfloop>
						</div>
					</cfloop>
				</cfif>
			<cfelse>
				<p class="mt-3 text-muted pl-1">Set filters and click Search.</p>
			</cfif>
			</cfoutput>
		</div>
	</section>
</main>
<cfinclude template="/shared/_footer.cfm">
