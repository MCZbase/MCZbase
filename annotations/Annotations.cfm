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
<cfparam name="url.action" default="">
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
<cfparam name="url.GUID" default="">
<cfparam name="url.collection_object_id" default="">
<cfparam name="url.id" default="">
<cfparam name="url.family" default="">
<cfparam name="url.taxon_family" default="">
<cfparam name="url.scientific_name" default="">
<cfparam name="url.taxon_name_id" default="">
<cfparam name="url.publication_id" default="">
<cfparam name="url.publication_text" default="">
<cfparam name="url.project_id" default="">
<cfparam name="url.project_text" default="">
<cfparam name="url.agent_id" default="">
<cfparam name="url.agent_name" default="">
<cfparam name="url.has_responses" default="">

<cfset variables.execute = lcase(trim(url.execute))>
<cfset variables.action = lcase(trim(url.action))>
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
<cfset variables.family = trim(url.family)>
<cfif len(variables.family) EQ 0><cfset variables.family = trim(url.taxon_family)></cfif>
<cfset variables.scientific_name = trim(url.scientific_name)>
<cfset variables.taxon_name_id = trim(url.taxon_name_id)>
<cfset variables.publication_id = trim(url.publication_id)>
<cfset variables.publication_text = trim(url.publication_text)>
<cfset variables.project_id = trim(url.project_id)>
<cfset variables.project_text = trim(url.project_text)>
<cfset variables.agent_id = trim(url.agent_id)>
<cfset variables.agent_name = trim(url.agent_name)>
<cfset variables.has_responses = trim(url.has_responses)>
<cfset variables.publication_lookup = "">
<cfset variables.project_lookup = "">

<!--- Normalize target_type aliases and validate root_mode. --->
<cfswitch expression="#lcase(variables.target_type)#">
	<cfcase value="collection_object,collection_object_id"><cfset variables.target_type = "COLL_OBJECT"></cfcase>
	<cfcase value="taxon_name,taxon_name_id"><cfset variables.target_type = "TAXONOMY"></cfcase>
	<cfcase value="publication,publication_id"><cfset variables.target_type = "PUBLICATION"></cfcase>
	<cfcase value="project,project_id"><cfset variables.target_type = "PROJECT"></cfcase>
	<cfcase value="agent,agent_id"><cfset variables.target_type = "AGENT"></cfcase>
	<cfcase value="guid"><cfset variables.target_type = "COLL_OBJECT"></cfcase>
	<cfdefaultcase>
		<cfif len(variables.target_type) GT 0>
			<cfset variables.target_type = ucase(variables.target_type)>
		</cfif>
	</cfdefaultcase>
</cfswitch>

<!--- Map the generic url.id parameter to the appropriate id field based on normalized target_type. --->
<cfif len(trim(url.id)) GT 0>
	<cfswitch expression="#variables.target_type#">
		<cfcase value="TAXONOMY">
			<cfif len(variables.taxon_name_id) EQ 0><cfset variables.taxon_name_id = trim(url.id)></cfif>
		</cfcase>
		<cfcase value="PUBLICATION">
			<cfif len(variables.publication_id) EQ 0><cfset variables.publication_id = trim(url.id)></cfif>
		</cfcase>
		<cfcase value="PROJECT">
			<cfif len(variables.project_id) EQ 0><cfset variables.project_id = trim(url.id)></cfif>
		</cfcase>
		<cfcase value="AGENT">
			<cfif len(variables.agent_id) EQ 0><cfset variables.agent_id = trim(url.id)></cfif>
		</cfcase>
		<cfdefaultcase>
			<cfif len(variables.collection_object_id) EQ 0><cfset variables.collection_object_id = trim(url.id)></cfif>
		</cfdefaultcase>
	</cfswitch>
</cfif>
<!--- Map url.GUID to specimen_guid for API compatibility. --->
<cfif len(variables.specimen_guid) EQ 0 AND len(trim(url.GUID)) GT 0>
	<cfset variables.specimen_guid = trim(url.GUID)>
</cfif>
<cfif NOT listFindNoCase("root,response", variables.root_mode)>
	<cfset variables.root_mode = "root">
</cfif>

<cfset runSearch = false>
<cfif listFindNoCase("true,1,yes,y,on", variables.execute) OR variables.action EQ "show">
	<cfset runSearch = true>
</cfif>
<cfif NOT runSearch AND (
	len(variables.target_type) GT 0 OR
	len(variables.specimen_guid) GT 0 OR
	len(variables.collection_object_id) GT 0 OR
	len(variables.family) GT 0 OR
	len(variables.taxon_name_id) GT 0 OR
	len(variables.publication_id) GT 0 OR
	len(variables.publication_text) GT 0 OR
	len(variables.project_id) GT 0 OR
	len(variables.project_text) GT 0 OR
	len(variables.agent_id) GT 0 OR
	len(variables.agent_name) GT 0
)>
	<cfset runSearch = true>
</cfif>

<!--- Code-table and filter option queries: populate select controls and count badges. --->
<cfquery name="ctstate" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	SELECT
		count(annotations.state) AS ct,
		ctstate.state
	FROM ctstate
		LEFT JOIN annotations ON ctstate.state = annotations.state
	GROUP BY ctstate.state
	ORDER BY ctstate.state
</cfquery>
<cfquery name="ctresolution" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	SELECT
		count(annotations.resolution) AS ct,
		ctresolution.resolution
	FROM ctresolution
		LEFT JOIN annotations ON ctresolution.resolution = annotations.resolution
	GROUP BY ctresolution.resolution
	ORDER BY ctresolution.resolution
</cfquery>
<cfquery name="ctmotivation" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	SELECT
		count(annotations.motivation) AS ct,
		ctmotivation.motivation
	FROM ctmotivation
		LEFT JOIN annotations ON ctmotivation.motivation = annotations.motivation
	GROUP BY ctmotivation.motivation
	ORDER BY ctmotivation.motivation
</cfquery>
<cfquery name="getAnnotatedTargetTypes" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
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
<cfquery name="getAnnotatedCollections" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	SELECT
		count(annotations.annotation_id) ct,
		collection.collection
	FROM collection
		JOIN cataloged_item ON collection.collection_id = cataloged_item.collection_id
		JOIN annotations ON annotations.target_table = 'COLL_OBJECT'
			AND annotations.target_primary_key = cataloged_item.collection_object_id
	GROUP BY collection.collection
	ORDER BY collection.collection
</cfquery>
<cfquery name="getAnnotatedFamilies" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	SELECT
		count(annotations.annotation_id) ct,
		taxonomy.family
	FROM annotations
		INNER JOIN taxonomy ON annotations.target_table = 'TAXONOMY'
			AND annotations.target_primary_key = taxonomy.taxon_name_id
	WHERE taxonomy.family IS NOT NULL
	GROUP BY taxonomy.family
	ORDER BY taxonomy.family
</cfquery>
<cfquery name="reviewedCounts" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	SELECT reviewed_fg, count(annotation_id) ct
	FROM annotations
	WHERE reviewed_fg IN (0,1)
	GROUP BY reviewed_fg
</cfquery>
<cfquery name="visibilityCounts" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
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
	<cfquery name="getPublicationDisplay" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		SELECT MCZbase.getshortcitation(publication_id) short_citation
		FROM publication
		WHERE publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.publication_id#">
	</cfquery>
	<cfif getPublicationDisplay.recordcount GT 0>
		<cfset variables.publication_lookup = getPublicationDisplay.short_citation>
	</cfif>
<cfelseif len(variables.publication_text) GT 0>
	<!--- When a publication text search is provided (no id), show the text in the lookup display field. --->
	<cfset variables.publication_lookup = variables.publication_text>
</cfif>
<cfif len(variables.project_id) GT 0 AND isNumeric(variables.project_id)>
	<cfquery name="getProjectDisplay" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		SELECT project_name
		FROM project
		WHERE project_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.project_id#">
	</cfquery>
	<cfif getProjectDisplay.recordcount GT 0>
		<cfset variables.project_lookup = getProjectDisplay.project_name>
	</cfif>
<cfelseif len(variables.project_text) GT 0>
	<!--- When a project text search is provided (no id), show the text in the lookup display field. --->
	<cfset variables.project_lookup = variables.project_text>
</cfif>
<cfif len(variables.agent_id) GT 0 AND isNumeric(variables.agent_id) AND len(variables.agent_name) EQ 0>
	<cfquery name="getAgentDisplay" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		SELECT agent_name
		FROM preferred_agent_name
		WHERE agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.agent_id#">
	</cfquery>
	<cfif getAgentDisplay.recordcount GT 0>
		<cfset variables.agent_name = getAgentDisplay.agent_name>
	</cfif>
</cfif>
<cfif len(variables.collection_object_id) GT 0 AND isNumeric(variables.collection_object_id) and len(variables.specimen_guid) EQ 0>
	<cfquery name="getGuidDisplay" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		SELECT GUID
		FROM <cfif session.flatTableName EQ "FLAT">FLAT<cfelse>FLTERED_FLAT</cfif> flatTableName
		WHERE collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.collection_object_id#">
	</cfquery>
	<cfif getGuidDisplay.recordcount GT 0>
		<cfset variables.specimen_guid = getGuidDisplay.GUID>
	</cfif>
</cfif>
<cfif len(variables.taxon_name_id) GT 0 AND isNumeric(variables.taxon_name_id) AND len(variables.scientific_name) EQ 0>
	<cfquery name="getTaxonDisplay" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		SELECT scientific_name
		FROM taxonomy
		WHERE taxon_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.taxon_name_id#">
	</cfquery>
	<cfif getTaxonDisplay.recordcount GT 0>
		<cfset variables.scientific_name = getTaxonDisplay.scientific_name>
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
					<div class="col-12">
						<form id="annotationSearchForm" method="get" action="/annotations/Annotations.cfm">
						<input type="hidden" name="execute" value="true">
						<fieldset class="my-0 px-2 pb-1 border-top border-right border-bottom border-left field-set">
							<legend class="h6 mb-0 px-3 border-top border-right border-bottom border-left field-set-legend bg-teal font-weight-bold w-auto" aria-level="2">
								Annotation Metadata
							</legend>
							<div class="form-row">
								<div class="col-12 col-md-3">
									<label for="state" class="">State</label>
									<select name="state" id="state" class="">
										<option value=""></option>
										<cfloop query="ctstate">
											<cfif variables.state EQ state><cfset local.selected = "selected"><cfelse><cfset local.selected = ""></cfif>
											<option value="#encodeForHTML(state)#" #local.selected#>#encodeForHTML(state)# (#ct#)</option>
										</cfloop>
									</select>
								</div>
								<div class="col-12 col-md-3">
									<label for="resolution" class="data-entry-label">Resolution</label>
									<select name="resolution" id="resolution" class="data-entry-select col-12">
										<option value=""></option>
										<cfif variables.resolution EQ "NULL"><cfset local.selected = "selected"><cfelse><cfset local.selected = ""></cfif>
										<option value="NULL" #local.selected#>No Resolution</option>
										<cfif variables.resolution EQ "NOT NULL"><cfset local.selected = "selected"><cfelse><cfset local.selected = ""></cfif>
										<option value="NOT NULL" #local.selected#>Any Resolution</option>
										<cfloop query="ctresolution">
											<cfif variables.resolution EQ resolution><cfset local.selected = "selected"><cfelse><cfset local.selected = ""></cfif>
											<option value="#encodeForHTML(resolution)#" #local.selected#>#encodeForHTML(resolution)# (#ct#)</option>
										</cfloop>
									</select>
								</div>
								<div class="col-12 col-md-3">
									<label for="motivation" class="data-entry-label">Motivation</label>
									<select name="motivation" id="motivation" class="data-entry-select col-12">
										<option value=""></option>
										<cfloop query="ctmotivation">
											<cfif variables.motivation EQ motivation><cfset local.selected = "selected"><cfelse><cfset local.selected = ""></cfif>
											<option value="#encodeForHTML(motivation)#" #local.selected#>#encodeForHTML(motivation)# (#ct#)</option>
										</cfloop>
									</select>
								</div>
								<div class="col-12 col-md-3">
									<label for="has_responses" class="data-entry-label">Has Responses</label>
									<select name="has_responses" id="has_responses" class="data-entry-select col-12">
										<option value=""></option>
										<cfif variables.has_responses EQ "yes"><cfset local.selected = "selected"><cfelse><cfset local.selected = ""></cfif>
										<option value="yes" #local.selected#>Yes</option>
										<cfif variables.has_responses EQ "no"><cfset local.selected = "selected"><cfelse><cfset local.selected = ""></cfif>
										<option value="no" #local.selected#>No</option>
									</select>
								</div>
					
							</div>
						</fieldset>
							
						<fieldset class="my-2 px-2 pb-1 border-top border-right border-bottom border-left field-set">
							<legend class="h6 mb-0 px-3 border-top border-right border-bottom border-left field-set-legend bg-teal font-weight-bold w-auto" aria-level="2">
								Annotation Text and Review
							</legend>
							<div class="form-row">
								<div class="col-12 col-md-3">
									<label for="annotator" class="">Annotator Username</label>
									<input type="text" name="annotator" id="annotator" value="#encodeForHTML(variables.annotator)#" class="" placeholder="Type annotator name or username">
								</div>
								<div class="col-12 col-md-3">
									<label for="annotation_text" class="">Annotation Body Text</label>
									<input type="text" name="annotation_text" id="annotation_text" value="#encodeForHTML(variables.annotation_text)#" class="">
								</div>
								<div class="col-12 col-md-3 col-xl-2">
									<label for="reviewed_fg" class="">Reviewed</label>
									<select name="reviewed_fg" id="reviewed_fg" class="">
										<option value=""></option>
										<cfif variables.reviewed_fg EQ "1"><cfset local.selected = "selected"><cfelse><cfset local.selected = ""></cfif>
										<option value="1" #local.selected#>Reviewed (#variables.reviewedCountReviewed#)</option>
										<cfif variables.reviewed_fg EQ "0"><cfset local.selected = "selected"><cfelse><cfset local.selected = ""></cfif>
										<option value="0" #local.selected#>Not Reviewed (#variables.reviewedCountNotReviewed#)</option>
									</select>
								</div>
								<div class="col-12 col-md-4 col-xl-2">
									<label for="visibility" class="">Visibility</label>
									<select name="visibility" id="visibility" class="">
										<option value=""></option>
										<cfif variables.visibility EQ "0"><cfset local.selected = "selected"><cfelse><cfset local.selected = ""></cfif>
										<option value="0" #local.selected#>Visible (#variables.visibilityCountVisible#)</option>
										<cfif variables.visibility EQ "1"><cfset local.selected = "selected"><cfelse><cfset local.selected = ""></cfif>
										<option value="1" #local.selected#>Masked (#variables.visibilityCountMasked#)</option>
									</select>
								</div>
								<div class="col-12 col-md-4 col-xl-2">
									<label for="target_type_select" class="">Target Type</label>
									<select name="target_type" id="target_type_select" class="">
										<option value="">All Target Types</option>
										<cfloop query="getAnnotatedTargetTypes">
											<cfset target_type_label = "">
											<cfswitch expression="#target_table#">
												<cfcase value="COLL_OBJECT"><cfset target_type_label = "Specimen"></cfcase>
												<cfcase value="TAXONOMY"><cfset target_type_label = "Taxon"></cfcase>
												<cfcase value="PUBLICATION"><cfset target_type_label = "Publication"></cfcase>
												<cfcase value="PROJECT"><cfset target_type_label = "Project"></cfcase>
												<cfcase value="AGENT"><cfset target_type_label = "Agent"></cfcase>
												<cfdefaultcase><cfset target_type_label = rereplace(lcase(target_table), "_", " ", "all")></cfdefaultcase>
											</cfswitch>
											<cfif ucase(target_table) NEQ "ANNOTATIONS">
												<cfif variables.target_type EQ target_table><cfset local.selected = "selected"><cfelse><cfset local.selected = ""></cfif>
												<option value="#encodeForHTML(target_table)#" #local.selected#>#encodeForHTML(target_type_label)# (#ct#)</option>
											</cfif>
										</cfloop>
									</select>
								</div>
							</div>
						</fieldset>
					
						<fieldset class="my-2 px-2 pb-1 border-top border-right border-bottom border-left field-set">
							<legend class="h6 mb-0 px-3 border-top border-right border-bottom border-left field-set-legend bg-teal font-weight-bold w-auto" aria-level="2">
								Target-Specific Context
							</legend>
							
							<div class="form-row">
								<div class="col-12 col-xl-4">
									<div class="form-row">
										<h3 class="h6 mb-0 px-2 mt-2 w-90 mx-1 font-weight-bold bg-light border ">Specimen</h3>
										<div class="col-12 col-xl-6" data-target-group="specimen">
											<label for="collection" class="">Collection</label>
											<select name="collection" id="collection" class="">
												<option value="">Any Collection</option>
												<cfloop query="getAnnotatedCollections">
													<cfif variables.collection EQ collection><cfset local.selected = "selected"><cfelse><cfset local.selected = ""></cfif>
													<option value="#encodeForHTML(collection)#" #local.selected#>#encodeForHTML(collection)# (#ct#)</option>
												</cfloop>
											</select>
										</div>
										<div class="col-12 col-xl-6" data-target-group="specimen">
											<label for="specimen_guid" class="">Specimen GUID</label>
											<input type="text" name="specimen_guid" id="specimen_guid" value="#encodeForHTML(variables.specimen_guid)#" class="" placeholder="MCZ:Herp:A-12345">
										</div>
									</div>
								</div>
								<div class="col-12 col-xl-4">
									<input type="hidden" name="collection_object_id" id="collection_object_id" value="#encodeForHTML(variables.collection_object_id)#">
									<div class="form-row">
										<h3 class="h6 mb-0 px-2 mt-2 w-auto font-weight-bold bg-light border">Taxon</h3>
										<div class="col-12 col-xl-6" data-target-group="taxon">
											<label for="family" class="">Family</label>
											<select name="family" id="family" class="">
												<option value="">Any Family</option>
												<cfloop query="getAnnotatedFamilies">
													<cfif variables.family EQ family><cfset local.selected = "selected"><cfelse><cfset local.selected = ""></cfif>
													<option value="#encodeForHTML(family)#" #local.selected#>#encodeForHTML(family)# (#ct#)</option>
												</cfloop>
											</select>
										</div>
										<div class="col-12 col-xl-6" data-target-group="taxon">
											<label for="scientific_name" class="">Scientific Name Contains</label>
											<input type="text" name="scientific_name" id="scientific_name" value="#encodeForHTML(variables.scientific_name)#" class="">
										</div>
									</div>
								</div>
								<div class="col-12 col-xl-4">
									<input type="hidden" name="taxon_name_id" id="taxon_name_id" value="#encodeForHTML(variables.taxon_name_id)#">
									<div class="form-row">
										<h3 class="h6 mb-0 px-2 mt-2 w-auto font-weight-bold bg-light border">Agent</h3>
										<div class="col-12" data-target-group="agent">
											<label for="agent_name" class="">Agent Name</label>
											<input type="text" name="agent_name" id="agent_name" value="#encodeForHTML(variables.agent_name)#" class="" placeholder="Type to search by name or pick an agent">
											<input type="hidden" name="agent_id" id="agent_id" value="#encodeForHTML(variables.agent_id)#">
										</div>
									</div>
								</div>
								<div class="col-12">
									<div class="form-row">
										<h3 class="h6 px-2 mt-2 mb-0 font-weight-bold w-auto bg-light border">Publication and Project</h3>
										<div class="col-12 col-md-6" data-target-group="publication">
											<label for="publication_lookup" class="">Publication Citation or Title</label>
											<input type="hidden" name="publication_id" id="publication_id" value="#encodeForHTML(variables.publication_id)#">
											<input type="hidden" name="publication_text" id="publication_text" value="#encodeForHTML(variables.publication_text)#">
											<input type="text" id="publication_lookup" value="#encodeForHTML(variables.publication_lookup)#" class="" placeholder="Type to search by text or select from list">
										</div>
										<div class="col-12 col-md-6" data-target-group="project">
											<label for="project_lookup" class="">Project Title</label>
											<input type="hidden" name="project_id" id="project_id" value="#encodeForHTML(variables.project_id)#">
											<input type="hidden" name="project_text" id="project_text" value="#encodeForHTML(variables.project_text)#">
											<input type="text" id="project_lookup" value="#encodeForHTML(variables.project_lookup)#" class="" placeholder="Type to search by text or select from list">
										</div>
									</div>
								</div>
							</div>
						</fieldset>
							<div class="mt-auto pt-2">
								<button type="submit" class="btn btn-xs btn-primary">Search</button>
								<a href="/annotations/Annotations.cfm" class="btn btn-xs btn-warning">Reset</a>
							</div>
						</form>
						<script>
							var $form = $('##annotationSearchForm');
							var $targetTypeSelect = $('##target_type_select');
							// Single config object: add new target types here only.
							// fields: search parameter inputs (drives inference, disable/clear, query string).
							// displayFields: display-only inputs (cleared/disabled with group but not in query string).
							var groupConfig = {
								specimen:    { targetType: 'COLL_OBJECT', fields: ['collection', 'specimen_guid', 'collection_object_id'] },
								taxon:       { targetType: 'TAXONOMY',        fields: ['family', 'scientific_name', 'taxon_name_id'] },
								publication: { targetType: 'PUBLICATION',       fields: ['publication_id', 'publication_text'], displayFields: ['publication_lookup'] },
								project:     { targetType: 'PROJECT',           fields: ['project_id', 'project_text'],         displayFields: ['project_lookup'] },
								agent:       { targetType: 'AGENT',             fields: ['agent_id', 'agent_name'] }
							};
							// Derived lookups — no manual update needed when groupConfig is extended.
							var allGroups = Object.keys(groupConfig);
							var targetTypeToGroup = {};
							$.each(allGroups, function (i, groupName) {
								targetTypeToGroup[groupConfig[groupName].targetType] = [groupName];
							});
							function clearGroup(groupName) {
								$.each(groupConfig[groupName].fields, function (i, fieldId) {
									$('##' + fieldId).val('');
								});
								$.each(groupConfig[groupName].displayFields || [], function (i, fieldId) {
									$('##' + fieldId).val('');
								});
							}
							function setGroupState(activeGroups, clearInconsistentValues) {
								$.each(allGroups, function (i, groupName) {
									var active = $.inArray(groupName, activeGroups) !== -1;
									$form.find('[data-target-group="' + groupName + '"]')
										.toggleClass('opacity-50', !active)
										.toggleClass('text-muted', !active);
									$.each(groupConfig[groupName].fields, function (j, fieldId) {
										$('##' + fieldId)
											.prop('disabled', !active)
											.toggleClass('bg-light', !active)
											.toggleClass('text-muted', !active);
									});
									$.each(groupConfig[groupName].displayFields || [], function (j, fieldId) {
										$('##' + fieldId)
											.prop('disabled', !active)
											.toggleClass('bg-light', !active)
											.toggleClass('text-muted', !active);
									});
									if (!active && clearInconsistentValues) {
										clearGroup(groupName);
									}
								});
							}
							function inferTargetType() {
								var filledGroups = [];
								$.each(allGroups, function (i, groupName) {
									var groupHasValue = false;
									$.each(groupConfig[groupName].fields, function (j, fieldId) {
										if ($.trim($('##' + fieldId).val()).length > 0) {
											groupHasValue = true;
											return false;
										}
									});
									if (groupHasValue) { filledGroups.push(groupName); }
								});
								if (filledGroups.length === 1) {
									$targetTypeSelect.val(groupConfig[filledGroups[0]].targetType);
								}
								if (filledGroups.length > 1) {
									// Deterministic precedence for conflicts: use order from groupConfig.
									var selectedGroup = null;
									$.each(allGroups, function (i, groupName) {
										if ($.inArray(groupName, filledGroups) !== -1) {
											selectedGroup = groupName;
											return false;
										}
									});
									$targetTypeSelect.val(groupConfig[selectedGroup || allGroups[0]].targetType);
								}
							}
							function applyTargetTypeState(clearInconsistentValues) {
								var selectedTargetType = $targetTypeSelect.val() ? $targetTypeSelect.val().toUpperCase() : '';
								var activeGroups = targetTypeToGroup[selectedTargetType] || allGroups;
								setGroupState(activeGroups, clearInconsistentValues);
							}
							function syncTextSearchFields() {
								// When publication_id is not set, populate publication_text from the lookup display field.
								// When publication_id is set (autocomplete selected), clear publication_text so only the id is sent.
								if ($.trim($('##publication_id').val()).length > 0) {
									$('##publication_text').val('');
								} else {
									$('##publication_text').val($.trim($('##publication_lookup').val()));
								}
								// Same for project.
								if ($.trim($('##project_id').val()).length > 0) {
									$('##project_text').val('');
								} else {
									$('##project_text').val($.trim($('##project_lookup').val()));
								}
							}
							function showSearchingMarker() {
								$('##annotationSearchResultsContainer').html('<p class="mt-3 text-muted pl-1">Searching...</p>');
							}
							function buildSearchQueryString() {
								syncTextSearchFields();
								var params = [{ name: 'execute', value: 'true' }];
								$form.find(':input').not(':disabled').each(function () {
									var $field = $(this);
									var name = $field.attr('name');
									if (!name || name === 'execute') { return; }
									var type = ($field.attr('type') || '').toLowerCase();
									if (type === 'submit' || type === 'button' || type === 'reset' || type === 'file') { return; }
									if ((type === 'checkbox' || type === 'radio') && !$field.prop('checked')) { return; }
									var value = $.trim($field.val() || '');
									if (value.length > 0) {
										params.push({ name: name, value: value });
									}
								});
								return $.param(params);
							}
							function loadResults(queryString) {
								showSearchingMarker();
								$.ajax({
									url: '/annotations/component/search.cfc?method=renderAnnotationSearchResults&returnformat=plain&' + queryString,
									type: 'get',
									success: function (data) {
										$('##annotationSearchResultsContainer').html(data);
									},
									error: function (jqXHR, textStatus, error) {
										console.error(error);
										$('##annotationSearchResultsContainer').html('<p class="mt-3 text-danger pl-1">Unable to load search results.</p>');
									}
								});
							}
							$(document).ready(function () {
								$('##target_type_select').on('change', function () {
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
								if (typeof makeConstrainedAgentPicker === 'function') {
									makeConstrainedAgentPicker('agent_name', 'agent_id', 'annotated');
								} else {
									console.warn('Agent autocomplete unavailable. Use agent_id in URL parameters for agent filtering.');
								}
								if (typeof makeAnnotationParticipantLoginAutocomplete === 'function') {
									makeAnnotationParticipantLoginAutocomplete('annotator');
								} else {
									console.warn('Annotator autocomplete unavailable. Annotator searches will use typed login fragments.');
								}
								// Clear the stored publication_id whenever the user edits the lookup display field manually.
								$('##publication_lookup').on('input', function () {
									$('##publication_id').val('');
									$('##publication_text').val('');
								});
								// Clear the stored project_id whenever the user edits the lookup display field manually.
								$('##project_lookup').on('input', function () {
									$('##project_id').val('');
									$('##project_text').val('');
								});
								$('##agent_name').on('input', function () {
									$('##agent_id').val('');
								});
								// Clear taxon_name_id whenever the user types in the scientific name field.
								$('##scientific_name').on('input', function () {
									$('##taxon_name_id').val('');
								});
								// Clear dependent hidden/surrogate values when target-specific search values change.
								$('##specimen_guid').on('input change', function () {
									$('##collection_object_id').val('');
								});
								$('##collection').on('change', function () {
									$('##specimen_guid').val('');
									$('##collection_object_id').val('');
								});
								$('##family').on('change', function () {
									$('##taxon_name_id').val('');
								});
								$('##publication_lookup').on('change', function () {
									if ($.trim($('##publication_id').val()).length === 0) {
										$('##publication_text').val($.trim($(this).val()));
									}
								});
								$('##project_lookup').on('change', function () {
									if ($.trim($('##project_id').val()).length === 0) {
										$('##project_text').val($.trim($(this).val()));
									}
								});
								$('##annotationSearchForm').on('submit', function (event) {
									event.preventDefault();
									inferTargetType();
									applyTargetTypeState(true);
									var queryString = buildSearchQueryString();
									history.replaceState({}, '', window.location.pathname + '?' + queryString);
									loadResults(queryString);
								});
								applyTargetTypeState(false);
								<cfif runSearch>
									loadResults(buildSearchQueryString());
								</cfif>
							});
						</script>
					</div>
				</cfoutput>
			</div>
		</div>
	</section>

	<!--- Results container: AJAX-loaded by JavaScript --->
	<section class="row mx-0 mb-4">
		<div class="col-12">
			<div id="annotationSearchResultsContainer">
				<cfif runSearch>
					<p class="mt-3 text-muted pl-1">Searching...</p>
				<cfelse>
					<p class="mt-3 text-muted pl-1">Add desired search terms and click Search.</p>
				</cfif>
			</div>
		</div>
	</section>
</main>
<cfinclude template="/shared/_footer.cfm">
