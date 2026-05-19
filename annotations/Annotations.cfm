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

<cfswitch expression="#lcase(variables.target_type)#">
	<cfcase value="collection_object_id"><cfset variables.target_type = "collection_object"></cfcase>
	<cfcase value="taxon_name_id"><cfset variables.target_type = "taxon_name"></cfcase>
	<cfcase value="publication_id"><cfset variables.target_type = "publication"></cfcase>
	<cfcase value="project_id"><cfset variables.target_type = "project"></cfcase>
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
<cfset filterData = annotationSearch.getAnnotationSearchFilters()>
<cfset ctstate = filterData.ctstate>
<cfset ctresolution = filterData.ctresolution>
<cfset ctmotivation = filterData.ctmotivation>
<cfset getAnnotatedCollections = filterData.collections>
<cfset getAnnotatedFamilies = filterData.families>
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
						<div class="col-12 col-md-6 col-xl-3 mb-3">
							<h2 class="h5 mb-2">Annotation Filters</h2>
							<div class="form-group mb-2">
								<label for="target_type" class="data-entry-label">Target Type</label>
								<select name="target_type" id="target_type" class="data-entry-select col-12">
									<option value="">All Supported Targets</option>
									<option value="collection_object" <cfif variables.target_type EQ "collection_object">selected="selected"</cfif>>Specimen</option>
									<option value="taxon_name" <cfif variables.target_type EQ "taxon_name">selected="selected"</cfif>>Taxon</option>
									<option value="publication" <cfif variables.target_type EQ "publication">selected="selected"</cfif>>Publication</option>
									<option value="project" <cfif variables.target_type EQ "project">selected="selected"</cfif>>Project</option>
								</select>
							</div>
							<div class="form-group mb-2">
								<label for="state" class="data-entry-label">State</label>
								<select name="state" id="state" class="data-entry-select col-12">
									<option value="">Any State</option>
									<cfloop query="ctstate">
										<option value="#encodeForHTML(state)#" <cfif variables.state EQ state>selected="selected"</cfif>>#encodeForHTML(state)#</option>
									</cfloop>
								</select>
							</div>
							<div class="form-group mb-2">
								<label for="resolution" class="data-entry-label">Resolution</label>
								<select name="resolution" id="resolution" class="data-entry-select col-12">
									<option value="">Any Resolution</option>
									<cfloop query="ctresolution">
										<option value="#encodeForHTML(resolution)#" <cfif variables.resolution EQ resolution>selected="selected"</cfif>>#encodeForHTML(resolution)#</option>
									</cfloop>
								</select>
							</div>
							<div class="form-group mb-2">
								<label for="motivation" class="data-entry-label">Motivation</label>
								<select name="motivation" id="motivation" class="data-entry-select col-12">
									<option value="">Any Motivation</option>
									<cfloop query="ctmotivation">
										<option value="#encodeForHTML(motivation)#" <cfif variables.motivation EQ motivation>selected="selected"</cfif>>#encodeForHTML(motivation)#</option>
									</cfloop>
								</select>
							</div>
						</div>

						<div class="col-12 col-md-6 col-xl-3 mb-3">
							<h2 class="h5 mb-2">Annotation Metadata</h2>
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
									<option value="1" <cfif variables.reviewed_fg EQ "1">selected="selected"</cfif>>Reviewed</option>
									<option value="0" <cfif variables.reviewed_fg EQ "0">selected="selected"</cfif>>Not Reviewed</option>
								</select>
							</div>
							<div class="form-group mb-2">
								<label for="root_mode" class="data-entry-label">Root vs Response</label>
								<select name="root_mode" id="root_mode" class="data-entry-select col-12">
									<option value="root" <cfif variables.root_mode EQ "root">selected="selected"</cfif>>Roots Only</option>
									<option value="response" <cfif variables.root_mode EQ "response">selected="selected"</cfif>>Responses Only</option>
								</select>
							</div>
							<div class="form-group mb-2">
								<label for="visibility" class="data-entry-label">Visibility</label>
								<select name="visibility" id="visibility" class="data-entry-select col-12">
									<option value="">Any</option>
									<option value="0" <cfif variables.visibility EQ "0">selected="selected"</cfif>>Visible</option>
									<option value="1" <cfif variables.visibility EQ "1">selected="selected"</cfif>>Masked</option>
								</select>
							</div>
						</div>

						<div class="col-12 col-md-6 col-xl-3 mb-3">
							<h2 class="h5 mb-2">Specimen and Taxon Context</h2>
							<div class="form-group mb-2">
								<label for="collection" class="data-entry-label">Collection</label>
								<select name="collection" id="collection" class="data-entry-select col-12">
									<option value="">Any Collection</option>
									<cfloop query="getAnnotatedCollections">
										<option value="#encodeForHTML(collection)#" <cfif variables.collection EQ collection>selected="selected"</cfif>>#encodeForHTML(collection)# (#ct#)</option>
									</cfloop>
								</select>
							</div>
							<div class="form-group mb-2">
								<label for="specimen_guid" class="data-entry-label">Specimen GUID</label>
								<input type="text" name="specimen_guid" id="specimen_guid" value="#encodeForHTML(variables.specimen_guid)#" class="data-entry-input col-12" placeholder="MCZ:Herp:A-12345">
							</div>
							<div class="form-group mb-2">
								<label for="collection_object_id" class="data-entry-label">Collection Object ID</label>
								<input type="text" name="collection_object_id" id="collection_object_id" value="#encodeForHTML(variables.collection_object_id)#" class="data-entry-input col-12">
							</div>
							<div class="form-group mb-2">
								<label for="family" class="data-entry-label">Family</label>
								<select name="family" id="family" class="data-entry-select col-12">
									<option value="">Any Family</option>
									<cfloop query="getAnnotatedFamilies">
										<option value="#encodeForHTML(family)#" <cfif variables.family EQ family>selected="selected"</cfif>>#encodeForHTML(family)# (#ct#)</option>
									</cfloop>
								</select>
							</div>
							<div class="form-group mb-2">
								<label for="scientific_name" class="data-entry-label">Scientific Name Contains</label>
								<input type="text" name="scientific_name" id="scientific_name" value="#encodeForHTML(variables.scientific_name)#" class="data-entry-input col-12">
							</div>
							<div class="form-group mb-2">
								<label for="taxon_name_id" class="data-entry-label">Taxon Name ID</label>
								<input type="text" name="taxon_name_id" id="taxon_name_id" value="#encodeForHTML(variables.taxon_name_id)#" class="data-entry-input col-12">
							</div>
						</div>

						<div class="col-12 col-md-6 col-xl-3 mb-3">
							<h2 class="h5 mb-2">Publication and Project Context</h2>
							<div class="form-group mb-2">
								<label for="publication_id" class="data-entry-label">Publication ID</label>
								<input type="text" name="publication_id" id="publication_id" value="#encodeForHTML(variables.publication_id)#" class="data-entry-input col-12">
							</div>
							<div class="form-group mb-3">
								<label for="project_id" class="data-entry-label">Project ID</label>
								<input type="text" name="project_id" id="project_id" value="#encodeForHTML(variables.project_id)#" class="data-entry-input col-12">
							</div>
							<button type="submit" class="btn btn-xs btn-primary">Search</button>
							<a href="/annotations/Annotations.cfm" class="btn btn-xs btn-warning">Reset</a>
							<div class="small text-muted mt-2">URL-driven links can populate this form and execute with <code>execute=true</code>.</div>
						</div>
					</form>
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
										<a href="#targetLink#" target="_blank">#encodeForHTML(targetTitle)#</a>
									<cfelse>
										#encodeForHTML(targetTitle)#
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
								<cfset showReplyAction = "false">
								<cfif NOT isNumeric(parent_annotation_id)>
									<cfset showReplyAction = "true">
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
								<cfif showReplyAction EQ "true">
									#annotationFunctions.renderAnnotationConversationSection(rootAnnotationId=annotation_id, childAnnotations=childAnnotations, root_mask_annotation_fg=mask_annotation_fg)#
								</cfif>
								</div>
							</cfloop>
						</div>
					</cfloop>
				</cfif>
			<cfelse>
				<p class="mt-3 text-muted pl-1">Set filters and click Search, or provide URL parameters with <code>execute=true</code> for direct contextual links.</p>
			</cfif>
			</cfoutput>
		</div>
	</section>
</main>
<cfinclude template="/shared/_footer.cfm">
