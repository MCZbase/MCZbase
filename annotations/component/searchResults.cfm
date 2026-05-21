<!---
annotations/component/searchResults.cfm

AJAX endpoint to render annotation search results for annotations/Annotations.cfm.
--->
<cfsetting showdebugoutput="false">

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

<cfset variables.runSearch = false>
<cfif listFindNoCase("true,1,yes,y,on", variables.execute)>
	<cfset variables.runSearch = true>
</cfif>
<cfif NOT variables.runSearch AND (
	len(variables.target_type) GT 0 OR
	len(variables.specimen_guid) GT 0 OR
	len(variables.collection_object_id) GT 0 OR
	len(variables.family) GT 0 OR
	len(variables.taxon_name_id) GT 0 OR
	len(variables.publication_id) GT 0 OR
	len(variables.project_id) GT 0
)>
	<cfset variables.runSearch = true>
</cfif>

<cfset annotationFunctions = CreateObject("component","annotations.component.functions")>
<cfset annotationSearch = CreateObject("component","annotations.component.search")>
<cfset variables.searchResults = QueryNew("")>
<cfset variables.childAnnotations = QueryNew("")>

<cfif variables.runSearch>
	<cfset variables.searchResults = annotationSearch.findAnnotations(
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
	<cfif variables.searchResults.recordcount GT 0>
		<cfquery name="rootAnnotationsInResults" dbtype="query">
			SELECT annotation_id
			FROM searchResults
			WHERE parent_annotation_id IS NULL
		</cfquery>
		<cfif rootAnnotationsInResults.recordcount GT 0>
			<cfset variables.childAnnotations = annotationFunctions.getChildAnnotationsForRoots(valueList(rootAnnotationsInResults.annotation_id))>
		</cfif>
	</cfif>
</cfif>

<cfoutput>
<cfif variables.runSearch>
	<cfset variables.targetCount = 0>
	<cfset variables.annotationLabel = "annotations">
	<cfset variables.targetLabel = "targets">
	<cfset variables.searchTermLabels = []>
	<cfif variables.searchResults.recordcount GT 0>
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
		<cfset variables.targetCount = targets.recordcount>
	</cfif>
	<cfif variables.searchResults.recordcount EQ 1><cfset variables.annotationLabel = "annotation"></cfif>
	<cfif variables.targetCount EQ 1><cfset variables.targetLabel = "target"></cfif>
	<cfif len(variables.state) GT 0><cfset arrayAppend(variables.searchTermLabels, "state")></cfif>
	<cfif len(variables.resolution) GT 0><cfset arrayAppend(variables.searchTermLabels, "resolution")></cfif>
	<cfif len(variables.motivation) GT 0><cfset arrayAppend(variables.searchTermLabels, "motivation")></cfif>
	<cfif len(variables.annotator) GT 0><cfset arrayAppend(variables.searchTermLabels, "annotator")></cfif>
	<cfif len(variables.annotation_text) GT 0><cfset arrayAppend(variables.searchTermLabels, "annotation text")></cfif>
	<cfif len(variables.reviewed_fg) GT 0><cfset arrayAppend(variables.searchTermLabels, "reviewed")></cfif>
	<cfif len(variables.visibility) GT 0><cfset arrayAppend(variables.searchTermLabels, "visibility")></cfif>
	<cfif len(variables.target_type) GT 0><cfset arrayAppend(variables.searchTermLabels, "target type")></cfif>
	<cfif len(variables.collection) GT 0><cfset arrayAppend(variables.searchTermLabels, "collection")></cfif>
	<cfif len(variables.specimen_guid) GT 0><cfset arrayAppend(variables.searchTermLabels, "specimen guid")></cfif>
	<cfif len(variables.collection_object_id) GT 0><cfset arrayAppend(variables.searchTermLabels, "collection object id")></cfif>
	<cfif len(variables.family) GT 0><cfset arrayAppend(variables.searchTermLabels, "family")></cfif>
	<cfif len(variables.scientific_name) GT 0><cfset arrayAppend(variables.searchTermLabels, "scientific name")></cfif>
	<cfif len(variables.taxon_name_id) GT 0><cfset arrayAppend(variables.searchTermLabels, "taxon name id")></cfif>
	<cfif len(variables.publication_id) GT 0><cfset arrayAppend(variables.searchTermLabels, "publication")></cfif>
	<cfif len(variables.project_id) GT 0><cfset arrayAppend(variables.searchTermLabels, "project")></cfif>
	<cfset variables.searchedOn = "none (all annotations)">
	<cfif arrayLen(variables.searchTermLabels) GT 0><cfset variables.searchedOn = arrayToList(variables.searchTermLabels, ", ")></cfif>
	<div class="d-flex flex-wrap align-items-end mt-3 pl-1" id="annotationSearchResultsHeading">
		<h2 class="h3 mb-0 mr-3">Annotation Results (#variables.searchResults.recordcount# #variables.annotationLabel# on #variables.targetCount# #variables.targetLabel#)</h2>
		<div class="text-muted mb-1">Searched on #encodeForHTML(variables.searchedOn)#.</div>
	</div>
	<cfif variables.searchResults.recordcount EQ 0>
		<p class="text-muted pl-1 mt-2">No annotations found matching the selected filters.</p>
	<cfelse>
		<cfloop query="targets">
			<cfset variables.targetTitle = "">
			<cfset variables.targetLink = "">
			<cfset variables.targetMeta = "">
			<cfset variables.targetTitleContainsHtml = false>
			<cfswitch expression="#ucase(targets.target_table)#">
				<cfcase value="COLLECTION_OBJECT">
					<cfset variables.specimenGuid = "#targets.institution_acronym#:#targets.collection_cde#:#targets.cat_num#">
					<cfset variables.targetTitle = variables.specimenGuid>
					<cfset variables.targetLink = "/guid/#encodeForURL(variables.specimenGuid)#">
					<cfset variables.targetMeta = "Current Identification: #encodeForHTML(targets.idAs)#; Locality: #encodeForHTML(targets.higher_geog)#: #encodeForHTML(targets.spec_locality)#">
				</cfcase>
				<cfcase value="TAXON_NAME">
					<cfset variables.targetTitle = targets.taxon_display_name>
					<cfset variables.targetLink = "/name/#encodeForURL(targets.taxon_scientific_name)#">
					<cfset variables.targetTitleContainsHtml = true>
				</cfcase>
				<cfcase value="PUBLICATION">
					<cfset variables.targetTitle = targets.publication_title>
					<cfset variables.targetLink = "/publications/showPublication.cfm?publication_id=#encodeForURL(targets.publication_id)#">
				</cfcase>
				<cfcase value="PROJECT">
					<cfset variables.targetTitle = targets.project_name>
					<cfset variables.targetLink = "/ProjectDetail?project_id=#encodeForURL(targets.project_id)#">
				</cfcase>
				<cfdefaultcase>
					<cfset variables.targetTitle = "Target #encodeForHTML(targets.target_key)#">
				</cfdefaultcase>
			</cfswitch>
			<div class="col-12 px-0 my-2 card border-bottom-0">
				<div class="card-header bg-box-header-gray">
					<h3 class="h4 mb-0">
						<cfif len(variables.targetLink) GT 0>
							<a href="#variables.targetLink#" target="_blank"><cfif variables.targetTitleContainsHtml>#variables.targetTitle#<cfelse>#encodeForHTML(variables.targetTitle)#</cfif></a>
						<cfelse>
							<cfif variables.targetTitleContainsHtml>#variables.targetTitle#<cfelse>#encodeForHTML(variables.targetTitle)#</cfif>
						</cfif>
						<cfif len(variables.targetMeta) GT 0><span class="ml-2 small">#variables.targetMeta#</span></cfif>
					</h3>
				</div>
				<cfquery name="targetAnnotations" dbtype="query">
					SELECT annotation_id, annotation_display, cf_username, email, annotate_date, motivation, reviewed_fg,
						state, resolution, reviewer, reviewer_comment, mask_annotation_fg, parent_annotation_id
					FROM searchResults
					WHERE target_table = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#targets.target_table#">
						AND target_key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#targets.target_key#">
				</cfquery>
				<cfloop query="targetAnnotations">
					<cfset variables.showReplyAction = false>
					<cfif NOT isNumeric(targetAnnotations.parent_annotation_id)>
						<cfset variables.showReplyAction = true>
					</cfif>
					<div id="annotation-block-#targetAnnotations.annotation_id#">
					<cfinvoke component="/annotations/component/functions" method="renderAnnotationReviewRow" returnvariable="variables.annoRowHTML"
						annotation_id="#targetAnnotations.annotation_id#"
						annotation_display="#targetAnnotations.annotation_display#"
						cf_username="#targetAnnotations.cf_username#"
						email="#targetAnnotations.email#"
						annotate_date="#targetAnnotations.annotate_date#"
						motivation="#targetAnnotations.motivation#"
						reviewed_fg="#targetAnnotations.reviewed_fg#"
						state="#targetAnnotations.state#"
						resolution="#targetAnnotations.resolution#"
						reviewer="#targetAnnotations.reviewer#"
						reviewer_comment="#targetAnnotations.reviewer_comment#"
						mask_annotation_fg="#targetAnnotations.mask_annotation_fg#"
						show_reply_action="#variables.showReplyAction#">
					#variables.annoRowHTML#
					<cfif variables.showReplyAction>
						#annotationFunctions.renderAnnotationConversationSection(rootAnnotationId=targetAnnotations.annotation_id, childAnnotations=variables.childAnnotations, root_mask_annotation_fg=targetAnnotations.mask_annotation_fg)#
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
