<!---
/annotations/component/search.cfc

Copyright 2020-2026 President and Fellows of Harvard College

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
<cfcomponent>
<cf_rolecheck>
<cfinclude template="/shared/component/error_handler.cfc" runOnce="true">
<cfinclude template="/annotations/component/functions.cfc" runOnce="true">

<!---
 findAnnotations searches annotations by annotation metadata and optionally by properties of the annotation target.
 @param target_type optional target selector; accepts known aliases (collection_object|taxon_name|publication|project with *_id aliases) and any target_table value.
 @param state optional annotation state exact match.
 @param resolution optional annotation resolution exact match; pass "NULL" to find annotations with no resolution, "NOT NULL" to find annotations with any resolution.
 @param annotator optional username fragment (case-insensitive contains match).
 @param annotation_text optional annotation body fragment (case-insensitive contains match).
 @param motivation optional annotation motivation exact match.
 @param reviewed_fg optional review flag; accepts 1/0/true/false/yes/no.
 @param root_mode optional thread position filter; root (default) or response.
 @param visibility optional mask flag; accepts 1/0/true/false/yes/no.
 @param has_responses optional filter for root annotations by whether they have responses; accepts yes/no.
 @param collection optional exact collection name for specimen targets.
 @param specimen_guid optional specimen guid filter; supports single guid, comma-delimited list, or SQL wildcard pattern.
 @param collection_object_id optional numeric specimen primary key filter.
 @param family optional exact taxon family filter (case-insensitive).
 @param scientific_name optional taxon scientific name fragment (case-insensitive contains match).
 @param taxon_name_id optional numeric taxon primary key filter.
 @param publication_id optional numeric publication primary key filter; takes precedence over publication_text when both are provided.
 @param publication_text optional publication citation/title substring; used only when publication_id is not provided.
 @param project_id optional numeric project primary key filter; takes precedence over project_text when both are provided.
 @param project_text optional project name substring; used only when project_id is not provided.
 @return query of annotation rows with target context fields used by /annotations/Annotations.cfm result rendering.
--->
<cffunction name="findAnnotations" returntype="query" access="public">
	<cfargument name="target_type" type="string" required="no" default="">
	<cfargument name="state" type="string" required="no" default="">
	<cfargument name="resolution" type="string" required="no" default="">
	<cfargument name="annotator" type="string" required="no" default="">
	<cfargument name="annotation_text" type="string" required="no" default="">
	<cfargument name="motivation" type="string" required="no" default="">
	<cfargument name="reviewed_fg" type="string" required="no" default="">
	<cfargument name="root_mode" type="string" required="no" default="root">
	<cfargument name="visibility" type="string" required="no" default="">
	<cfargument name="collection" type="string" required="no" default="">
	<cfargument name="specimen_guid" type="string" required="no" default="">
	<cfargument name="collection_object_id" type="string" required="no" default="">
	<cfargument name="family" type="string" required="no" default="">
	<cfargument name="scientific_name" type="string" required="no" default="">
	<cfargument name="taxon_name_id" type="string" required="no" default="">
	<cfargument name="publication_id" type="string" required="no" default="">
	<cfargument name="publication_text" type="string" required="no" default="">
	<cfargument name="project_id" type="string" required="no" default="">
	<cfargument name="project_text" type="string" required="no" default="">
	<cfargument name="has_responses" type="string" required="no" default="">

	<cfset var targetTableFilter = "">
	<cfset var normalizedRootMode = "root">
	<cfset var normalizedReviewedFg = "">
	<cfset var normalizedVisibility = "">
	<cfset var annotationResults = QueryNew("")>

	<cftry>
	<cfswitch expression="#lcase(trim(arguments.target_type))#">
		<cfcase value="collection_object,collection_object_id">
			<cfset targetTableFilter = "COLLECTION_OBJECT">
		</cfcase>
		<cfcase value="taxon_name,taxon_name_id">
			<cfset targetTableFilter = "TAXON_NAME">
		</cfcase>
		<cfcase value="publication,publication_id">
			<cfset targetTableFilter = "PUBLICATION">
		</cfcase>
		<cfcase value="project,project_id">
			<cfset targetTableFilter = "PROJECT">
		</cfcase>
		<cfdefaultcase>
			<cfif len(trim(arguments.target_type)) GT 0>
				<cfset targetTableFilter = ucase(trim(arguments.target_type))>
			</cfif>
		</cfdefaultcase>
	</cfswitch>

	<cfif listFindNoCase("root,response", trim(arguments.root_mode))>
		<cfset normalizedRootMode = lcase(trim(arguments.root_mode))>
	</cfif>
	<cfif listFindNoCase("1,0,true,false,yes,no", lcase(trim(arguments.reviewed_fg)))>
		<cfif listFindNoCase("1,true,yes", lcase(trim(arguments.reviewed_fg)))>
			<cfset normalizedReviewedFg = "1">
		<cfelse>
			<cfset normalizedReviewedFg = "0">
		</cfif>
	</cfif>
	<cfif listFindNoCase("1,0,true,false,yes,no", lcase(trim(arguments.visibility)))>
		<cfif listFindNoCase("1,true,yes", lcase(trim(arguments.visibility)))>
			<cfset normalizedVisibility = "1">
		<cfelse>
			<cfset normalizedVisibility = "0">
		</cfif>
	</cfif>

	<cfquery name="annotationResults" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		SELECT
			annotations.annotation_id,
			annotations.annotate_date,
			annotations.cf_username,
			NVL(atb.body_value, annotations.annotation) annotation_display,
			annotations.reviewer_agent_id,
			preferred_agent_name.agent_name reviewer,
			annotations.reviewed_fg,
			annotations.state,
			annotations.resolution,
			annotations.reviewer_comment,
			annotations.motivation,
			annotations.mask_annotation_fg,
			CASE
				WHEN annotations.target_table = 'ANNOTATIONS' THEN parent_annotations.target_table
				ELSE annotations.target_table
			END target_table,
			CASE
				WHEN annotations.target_table = 'ANNOTATIONS' THEN annotations.target_primary_key
				ELSE NULL
			END parent_annotation_id,
			CASE
				WHEN (
					CASE
						WHEN annotations.target_table = 'ANNOTATIONS' THEN parent_annotations.target_table
						ELSE annotations.target_table
					END
				) = 'COLLECTION_OBJECT' THEN (
					CASE
						WHEN annotations.target_table = 'ANNOTATIONS' THEN parent_annotations.target_primary_key
						ELSE annotations.target_primary_key
					END
				)
				ELSE NULL
			END collection_object_id,
			CASE
				WHEN (
					CASE
						WHEN annotations.target_table = 'ANNOTATIONS' THEN parent_annotations.target_table
						ELSE annotations.target_table
					END
				) = 'TAXON_NAME' THEN (
					CASE
						WHEN annotations.target_table = 'ANNOTATIONS' THEN parent_annotations.target_primary_key
						ELSE annotations.target_primary_key
					END
				)
				ELSE NULL
			END taxon_name_id,
			CASE
				WHEN (
					CASE
						WHEN annotations.target_table = 'ANNOTATIONS' THEN parent_annotations.target_table
						ELSE annotations.target_table
					END
				) = 'PUBLICATION' THEN (
					CASE
						WHEN annotations.target_table = 'ANNOTATIONS' THEN parent_annotations.target_primary_key
						ELSE annotations.target_primary_key
					END
				)
				ELSE NULL
			END publication_id,
			CASE
				WHEN (
					CASE
						WHEN annotations.target_table = 'ANNOTATIONS' THEN parent_annotations.target_table
						ELSE annotations.target_table
					END
				) = 'PROJECT' THEN (
					CASE
						WHEN annotations.target_table = 'ANNOTATIONS' THEN parent_annotations.target_primary_key
						ELSE annotations.target_primary_key
					END
				)
				ELSE NULL
			END project_id,
			cf_user_data.email,
			collection.collection,
			collection.collection_cde,
			collection.institution_acronym,
			cataloged_item.cat_num,
			NVL(identification.scientific_name, '') scientific_name,
			NVL(geog_auth_rec.higher_geog, '') higher_geog,
			NVL(locality.spec_locality, '') spec_locality,
			taxonomy.scientific_name taxon_scientific_name,
			taxonomy.display_name taxon_display_name,
			taxonomy.family taxon_family,
			publication.publication_title,
			project.project_name,
			to_char(
				CASE
					WHEN annotations.target_table = 'ANNOTATIONS' THEN parent_annotations.target_primary_key
					ELSE annotations.target_primary_key
				END
			) target_primary_key
		FROM
			annotations
			LEFT OUTER JOIN annotations parent_annotations ON annotations.target_table = 'ANNOTATIONS'
				AND annotations.target_primary_key = parent_annotations.annotation_id
			LEFT OUTER JOIN cataloged_item ON (
					annotations.target_table = 'COLLECTION_OBJECT'
					AND annotations.target_primary_key = cataloged_item.collection_object_id
				) OR (
					annotations.target_table = 'ANNOTATIONS'
					AND parent_annotations.target_table = 'COLLECTION_OBJECT'
					AND parent_annotations.target_primary_key = cataloged_item.collection_object_id
				)
			LEFT OUTER JOIN collection ON cataloged_item.collection_id = collection.collection_id
			LEFT OUTER JOIN identification ON cataloged_item.collection_object_id = identification.collection_object_id
				AND identification.accepted_id_fg = 1
			LEFT OUTER JOIN collecting_event ON cataloged_item.collecting_event_id = collecting_event.collecting_event_id
			LEFT OUTER JOIN locality ON collecting_event.locality_id = locality.locality_id
			LEFT OUTER JOIN geog_auth_rec ON locality.geog_auth_rec_id = geog_auth_rec.geog_auth_rec_id
			LEFT OUTER JOIN taxonomy ON (
					annotations.target_table = 'TAXON_NAME'
					AND annotations.target_primary_key = taxonomy.taxon_name_id
				) OR (
					annotations.target_table = 'ANNOTATIONS'
					AND parent_annotations.target_table = 'TAXON_NAME'
					AND parent_annotations.target_primary_key = taxonomy.taxon_name_id
				)
			LEFT OUTER JOIN publication ON (
					annotations.target_table = 'PUBLICATION'
					AND annotations.target_primary_key = publication.publication_id
				) OR (
					annotations.target_table = 'ANNOTATIONS'
					AND parent_annotations.target_table = 'PUBLICATION'
					AND parent_annotations.target_primary_key = publication.publication_id
				)
			LEFT OUTER JOIN project ON (
					annotations.target_table = 'PROJECT'
					AND annotations.target_primary_key = project.project_id
				) OR (
					annotations.target_table = 'ANNOTATIONS'
					AND parent_annotations.target_table = 'PROJECT'
					AND parent_annotations.target_primary_key = project.project_id
				)
			LEFT OUTER JOIN cf_users ON annotations.cf_username = cf_users.username
			LEFT OUTER JOIN cf_user_data ON cf_users.user_id = cf_user_data.user_id
			LEFT OUTER JOIN preferred_agent_name ON annotations.reviewer_agent_id = preferred_agent_name.agent_id
			LEFT OUTER JOIN (
				<!--- Use earliest textual body for compatibility with existing annotation_display behavior on this page. --->
				SELECT annotation_id, body_value,
					ROW_NUMBER() OVER (PARTITION BY annotation_id ORDER BY created_date) rn
				FROM annotation_textualbody
			) atb ON annotations.annotation_id = atb.annotation_id AND atb.rn = 1
		WHERE
			1 = 1
			<cfif len(targetTableFilter) GT 0>
				AND (
					CASE
						WHEN annotations.target_table = 'ANNOTATIONS' THEN parent_annotations.target_table
						ELSE annotations.target_table
					END
				) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#targetTableFilter#">
			</cfif>
			<cfif normalizedRootMode EQ "root">
				AND annotations.target_table <> 'ANNOTATIONS'
			<cfelseif normalizedRootMode EQ "response">
				AND annotations.target_table = 'ANNOTATIONS'
			</cfif>
			<cfif len(trim(arguments.state)) GT 0>
				AND annotations.state = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(arguments.state)#">
			</cfif>
			<cfif trim(arguments.resolution) EQ "NULL">
				AND annotations.resolution IS NULL
			<cfelseif trim(arguments.resolution) EQ "NOT NULL">
				AND annotations.resolution IS NOT NULL
			<cfelseif len(trim(arguments.resolution)) GT 0>
				AND annotations.resolution = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(arguments.resolution)#">
			</cfif>
			<cfif len(trim(arguments.motivation)) GT 0>
				AND annotations.motivation = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(arguments.motivation)#">
			</cfif>
			<cfif len(normalizedReviewedFg) GT 0>
				AND annotations.reviewed_fg = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#normalizedReviewedFg#">
			</cfif>
			<cfif len(normalizedVisibility) GT 0>
				AND annotations.mask_annotation_fg = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#normalizedVisibility#">
			</cfif>
			<cfif len(trim(arguments.annotator)) GT 0>
				AND upper(annotations.cf_username) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(trim(arguments.annotator))#%">
			</cfif>
			<cfif len(trim(arguments.annotation_text)) GT 0>
				AND upper(NVL(atb.body_value, annotations.annotation)) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(trim(arguments.annotation_text))#%">
			</cfif>
			<cfif len(trim(arguments.collection)) GT 0>
				AND collection.collection = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(arguments.collection)#">
			</cfif>
			<cfif len(trim(arguments.collection_object_id)) GT 0 AND isNumeric(arguments.collection_object_id)>
				AND (
					CASE
						WHEN annotations.target_table = 'ANNOTATIONS' THEN parent_annotations.target_table
						ELSE annotations.target_table
					END
				) = 'COLLECTION_OBJECT'
				AND (
					CASE
						WHEN annotations.target_table = 'ANNOTATIONS' THEN parent_annotations.target_primary_key
						ELSE annotations.target_primary_key
					END
				) = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#trim(arguments.collection_object_id)#">
			</cfif>
			<cfif len(trim(arguments.specimen_guid)) GT 0>
				AND (
					CASE
						WHEN annotations.target_table = 'ANNOTATIONS' THEN parent_annotations.target_table
						ELSE annotations.target_table
					END
				) = 'COLLECTION_OBJECT'
				AND (
					CASE
						WHEN annotations.target_table = 'ANNOTATIONS' THEN parent_annotations.target_primary_key
						ELSE annotations.target_primary_key
					END
				) IN (
					SELECT collection_object_id
					FROM #session.flatTableName#
					<cfif trim(arguments.specimen_guid) contains ",">
						WHERE guid IN (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(arguments.specimen_guid)#" list="yes">)
					<cfelseif trim(arguments.specimen_guid) contains "%" OR trim(arguments.specimen_guid) contains "_">
						WHERE guid LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(arguments.specimen_guid)#">
					<cfelse>
						WHERE upper(guid) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(trim(arguments.specimen_guid))#">
					</cfif>
				)
			</cfif>
			<cfif len(trim(arguments.taxon_name_id)) GT 0 AND isNumeric(arguments.taxon_name_id)>
				AND (
					CASE
						WHEN annotations.target_table = 'ANNOTATIONS' THEN parent_annotations.target_table
						ELSE annotations.target_table
					END
				) = 'TAXON_NAME'
				AND (
					CASE
						WHEN annotations.target_table = 'ANNOTATIONS' THEN parent_annotations.target_primary_key
						ELSE annotations.target_primary_key
					END
				) = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#trim(arguments.taxon_name_id)#">
			</cfif>
			<cfif len(trim(arguments.family)) GT 0>
				AND upper(taxonomy.family) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(trim(arguments.family))#">
			</cfif>
			<cfif len(trim(arguments.scientific_name)) GT 0>
				AND upper(taxonomy.scientific_name) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(trim(arguments.scientific_name))#%">
			</cfif>
			<cfif len(trim(arguments.publication_id)) GT 0 AND isNumeric(arguments.publication_id)>
				AND (
					CASE
						WHEN annotations.target_table = 'ANNOTATIONS' THEN parent_annotations.target_table
						ELSE annotations.target_table
					END
				) = 'PUBLICATION'
				AND (
					CASE
						WHEN annotations.target_table = 'ANNOTATIONS' THEN parent_annotations.target_primary_key
						ELSE annotations.target_primary_key
					END
				) = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#trim(arguments.publication_id)#">
			<cfelseif len(trim(arguments.publication_text)) GT 0>
				AND (
					CASE
						WHEN annotations.target_table = 'ANNOTATIONS' THEN parent_annotations.target_table
						ELSE annotations.target_table
					END
				) = 'PUBLICATION'
				AND (
					CASE
						WHEN annotations.target_table = 'ANNOTATIONS' THEN parent_annotations.target_primary_key
						ELSE annotations.target_primary_key
					END
				) IN (
					SELECT publication_id
					FROM formatted_publication
					WHERE upper(formatted_publication) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(trim(arguments.publication_text))#%">
				)
			</cfif>
			<cfif len(trim(arguments.project_id)) GT 0 AND isNumeric(arguments.project_id)>
				AND (
					CASE
						WHEN annotations.target_table = 'ANNOTATIONS' THEN parent_annotations.target_table
						ELSE annotations.target_table
					END
				) = 'PROJECT'
				AND (
					CASE
						WHEN annotations.target_table = 'ANNOTATIONS' THEN parent_annotations.target_primary_key
						ELSE annotations.target_primary_key
					END
				) = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#trim(arguments.project_id)#">
			<cfelseif len(trim(arguments.project_text)) GT 0>
				AND (
					CASE
						WHEN annotations.target_table = 'ANNOTATIONS' THEN parent_annotations.target_table
						ELSE annotations.target_table
					END
				) = 'PROJECT'
				AND (
					CASE
						WHEN annotations.target_table = 'ANNOTATIONS' THEN parent_annotations.target_primary_key
						ELSE annotations.target_primary_key
					END
				) IN (
					SELECT project_id
					FROM project
					WHERE upper(project_name) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(trim(arguments.project_text))#%">
				)
			</cfif>
			<cfif normalizedRootMode EQ "root" AND listFindNoCase("yes,no", trim(arguments.has_responses))>
				<cfif lcase(trim(arguments.has_responses)) EQ "yes">
					AND EXISTS (
						SELECT 1 FROM annotations resp
						WHERE resp.target_table = 'ANNOTATIONS'
							AND resp.target_primary_key = annotations.annotation_id
					)
				<cfelseif lcase(trim(arguments.has_responses)) EQ "no">
					AND NOT EXISTS (
						SELECT 1 FROM annotations resp
						WHERE resp.target_table = 'ANNOTATIONS'
							AND resp.target_primary_key = annotations.annotation_id
					)
				</cfif>
			</cfif>
			<cfif NOT listcontainsnocase(session.roles, "coldfusion_user")>
				AND (
					(annotations.mask_annotation_fg = 0 AND NVL(parent_annotations.mask_annotation_fg, 0) = 0)
					OR annotations.cf_username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				)
			</cfif>
		ORDER BY
			CASE
				WHEN annotations.target_table = 'ANNOTATIONS' THEN parent_annotations.target_table
				ELSE annotations.target_table
			END,
			target_primary_key,
			annotations.annotate_date DESC
	</cfquery>
	<cfreturn annotationResults>
	<cfcatch>
		<cfset error_message = cfcatchToErrorMessage(cfcatch)>
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
</cffunction>

<!---
 renderAnnotationSearchResults renders annotation search results HTML for async and noscript loads.
 Works with findAnnotations query result structure and uses existing annotation render helpers to 
 maintain consistent display with other annotation sections.

 @param execute optional execution flag; accepted true values are true/1/yes/y/on.
 @param target_type optional target selector alias/value passed to findAnnotations.
 @param type optional legacy alias for target_type.
 @param state optional annotation state exact match.
 @param resolution optional annotation resolution exact match.
 @param annotator optional username fragment.
 @param annotation_text optional annotation body fragment.
 @param motivation optional annotation motivation exact match.
 @param reviewed_fg optional review flag value.
 @param root_mode optional root/response mode.
 @param visibility optional mask flag value.
 @param has_responses optional filter for whether root annotations have responses; accepts yes/no.
 @param collection optional exact collection filter.
 @param specimen_guid optional specimen guid filter.
 @param collection_object_id optional specimen id filter.
 @param id optional alias for collection_object_id; mapped to the appropriate id field based on target_type.
 @param family optional exact taxon family filter.
 @param taxon_family optional alias for family.
 @param scientific_name optional taxon scientific name contains filter.
 @param taxon_name_id optional taxon id filter.
 @param publication_id optional publication id filter; takes precedence over publication_text.
 @param publication_text optional publication citation/title substring; used only when publication_id is not provided.
 @param project_id optional project id filter; takes precedence over project_text.
 @param project_text optional project name substring; used only when project_id is not provided.
 @return HTML string for annotation search results section using existing annotation render helpers.
 @see findAnnotations 
--->
<cffunction name="renderAnnotationSearchResults" access="remote" returntype="string" returnformat="plain" output="false">
	<cfargument name="execute" type="string" required="no" default="">
	<cfargument name="target_type" type="string" required="no" default="">
	<cfargument name="type" type="string" required="no" default="">
	<cfargument name="state" type="string" required="no" default="">
	<cfargument name="resolution" type="string" required="no" default="">
	<cfargument name="annotator" type="string" required="no" default="">
	<cfargument name="annotation_text" type="string" required="no" default="">
	<cfargument name="motivation" type="string" required="no" default="">
	<cfargument name="reviewed_fg" type="string" required="no" default="">
	<cfargument name="root_mode" type="string" required="no" default="root">
	<cfargument name="visibility" type="string" required="no" default="">
	<cfargument name="collection" type="string" required="no" default="">
	<cfargument name="specimen_guid" type="string" required="no" default="">
	<cfargument name="collection_object_id" type="string" required="no" default="">
	<cfargument name="id" type="string" required="no" default="">
	<cfargument name="family" type="string" required="no" default="">
	<cfargument name="taxon_family" type="string" required="no" default="">
	<cfargument name="scientific_name" type="string" required="no" default="">
	<cfargument name="taxon_name_id" type="string" required="no" default="">
	<cfargument name="publication_id" type="string" required="no" default="">
	<cfargument name="publication_text" type="string" required="no" default="">
	<cfargument name="project_id" type="string" required="no" default="">
	<cfargument name="project_text" type="string" required="no" default="">
	<cfargument name="has_responses" type="string" required="no" default="">

	<cfset var normalizedTargetType = trim(arguments.target_type)>
	<cfset var normalizedCollectionObjectId = trim(arguments.collection_object_id)>
	<cfset var normalizedTaxonNameId = trim(arguments.taxon_name_id)>
	<cfset var normalizedPublicationId = trim(arguments.publication_id)>
	<cfset var normalizedProjectId = trim(arguments.project_id)>
	<cfset var normalizedFamily = trim(arguments.family)>
	<cfset var normalizedRootMode = lcase(trim(arguments.root_mode))>
	<cfset var runSearch = false>
	<cfset var searchResults = QueryNew("")>
	<cfset var childAnnotations = QueryNew("")>
	<cfset var rootAnnotationsInResults = QueryNew("")>
	<cfset var targets = QueryNew("")>
	<cfset var targetAnnotations = QueryNew("")>
	<cfset var targetCount = 0>
	<cfset var annotationLabel = "annotations">
	<cfset var targetLabel = "targets">
	<cfset var searchTermLabels = []>
	<cfset var searchedOn = "none (all annotations)">
	<cfset var targetTitle = "">
	<cfset var targetLink = "">
	<cfset var targetMeta = "">
	<cfset var targetTitleContainsHtml = false>
	<cfset var specimenGuid = "">
	<cfset var showReplyAction = false>
	<cfset var annoRowHTML = "">
	<cfset var result = "">

	<cfif len(normalizedTargetType) EQ 0>
		<cfset normalizedTargetType = trim(arguments.type)>
	</cfif>
	<cfswitch expression="#lcase(normalizedTargetType)#">
		<cfcase value="collection_object,collection_object_id"><cfset normalizedTargetType = "COLLECTION_OBJECT"></cfcase>
		<cfcase value="taxon_name,taxon_name_id"><cfset normalizedTargetType = "TAXON_NAME"></cfcase>
		<cfcase value="publication,publication_id"><cfset normalizedTargetType = "PUBLICATION"></cfcase>
		<cfcase value="project,project_id"><cfset normalizedTargetType = "PROJECT"></cfcase>
		<cfcase value="guid"><cfset normalizedTargetType = "COLLECTION_OBJECT"></cfcase>
		<cfdefaultcase>
			<cfif len(normalizedTargetType) GT 0>
				<cfset normalizedTargetType = ucase(normalizedTargetType)>
			</cfif>
		</cfdefaultcase>
	</cfswitch>
	<!--- Map the generic id parameter to the appropriate id field based on normalized target_type. --->
	<cfif len(trim(arguments.id)) GT 0>
		<cfswitch expression="#normalizedTargetType#">
			<cfcase value="TAXON_NAME">
				<cfif len(normalizedTaxonNameId) EQ 0><cfset normalizedTaxonNameId = trim(arguments.id)></cfif>
			</cfcase>
			<cfcase value="PUBLICATION">
				<cfif len(normalizedPublicationId) EQ 0><cfset normalizedPublicationId = trim(arguments.id)></cfif>
			</cfcase>
			<cfcase value="PROJECT">
				<cfif len(normalizedProjectId) EQ 0><cfset normalizedProjectId = trim(arguments.id)></cfif>
			</cfcase>
			<cfdefaultcase>
				<cfif len(normalizedCollectionObjectId) EQ 0><cfset normalizedCollectionObjectId = trim(arguments.id)></cfif>
			</cfdefaultcase>
		</cfswitch>
	</cfif>
	<cfif len(normalizedFamily) EQ 0>
		<cfset normalizedFamily = trim(arguments.taxon_family)>
	</cfif>
	<cfif NOT listFindNoCase("root,response", normalizedRootMode)>
		<cfset normalizedRootMode = "root">
	</cfif>
	<cfif listFindNoCase("true,1,yes,y,on", lcase(trim(arguments.execute)))>
		<cfset runSearch = true>
	</cfif>
	<cfif NOT runSearch AND (
		len(normalizedTargetType) GT 0 OR
		len(trim(arguments.specimen_guid)) GT 0 OR
		len(normalizedCollectionObjectId) GT 0 OR
		len(normalizedFamily) GT 0 OR
		len(normalizedTaxonNameId) GT 0 OR
		len(normalizedPublicationId) GT 0 OR
		len(trim(arguments.publication_text)) GT 0 OR
		len(normalizedProjectId) GT 0 OR
		len(trim(arguments.project_text)) GT 0
	)>
		<cfset runSearch = true>
	</cfif>

	<cfif runSearch>
		<cfset searchResults = findAnnotations(
			target_type = normalizedTargetType,
			state = trim(arguments.state),
			resolution = trim(arguments.resolution),
			annotator = trim(arguments.annotator),
			annotation_text = trim(arguments.annotation_text),
			motivation = trim(arguments.motivation),
			reviewed_fg = trim(arguments.reviewed_fg),
			root_mode = normalizedRootMode,
			visibility = trim(arguments.visibility),
			has_responses = lcase(trim(arguments.has_responses)),
			collection = trim(arguments.collection),
			specimen_guid = trim(arguments.specimen_guid),
			collection_object_id = normalizedCollectionObjectId,
			family = normalizedFamily,
			scientific_name = trim(arguments.scientific_name),
			taxon_name_id = normalizedTaxonNameId,
			publication_id = normalizedPublicationId,
			publication_text = trim(arguments.publication_text),
			project_id = normalizedProjectId,
			project_text = trim(arguments.project_text)
		)>
		<cfif searchResults.recordcount GT 0>
			<cfquery name="rootAnnotationsInResults" dbtype="query">
				SELECT annotation_id
				FROM searchResults
				WHERE parent_annotation_id IS NULL
			</cfquery>
			<cfif rootAnnotationsInResults.recordcount GT 0>
				<cfset childAnnotations = getChildAnnotationsForRoots(valueList(rootAnnotationsInResults.annotation_id))>
			</cfif>
		</cfif>
	</cfif>

	<cfsavecontent variable="result">
		<cftry>
		<cfoutput>
		<cfif runSearch>
			<cfif searchResults.recordcount GT 0>
				<cfquery name="targets" dbtype="query">
					SELECT target_table, target_primary_key, collection_object_id, institution_acronym, collection_cde, cat_num,
						scientific_name, higher_geog, spec_locality, taxon_name_id, taxon_scientific_name, taxon_display_name,
						publication_id, publication_title, project_id, project_name
					FROM searchResults
					GROUP BY target_table, target_primary_key, collection_object_id, institution_acronym, collection_cde, cat_num,
						scientific_name, higher_geog, spec_locality, taxon_name_id, taxon_scientific_name, taxon_display_name,
						publication_id, publication_title, project_id, project_name
					ORDER BY target_table, target_primary_key
				</cfquery>
				<cfset targetCount = targets.recordcount>
			</cfif>
			<cfif searchResults.recordcount EQ 1><cfset annotationLabel = "annotation"></cfif>
			<cfif targetCount EQ 1><cfset targetLabel = "target"></cfif>
			<cfif len(trim(arguments.state)) GT 0><cfset arrayAppend(searchTermLabels, "state")></cfif>
			<cfif len(trim(arguments.resolution)) GT 0><cfset arrayAppend(searchTermLabels, "resolution")></cfif>
			<cfif len(trim(arguments.motivation)) GT 0><cfset arrayAppend(searchTermLabels, "motivation")></cfif>
			<cfif len(trim(arguments.annotator)) GT 0><cfset arrayAppend(searchTermLabels, "annotator")></cfif>
			<cfif len(trim(arguments.annotation_text)) GT 0><cfset arrayAppend(searchTermLabels, "annotation text")></cfif>
			<cfif len(trim(arguments.reviewed_fg)) GT 0><cfset arrayAppend(searchTermLabels, "reviewed")></cfif>
			<cfif len(trim(arguments.visibility)) GT 0><cfset arrayAppend(searchTermLabels, "visibility")></cfif>
			<cfif len(normalizedTargetType) GT 0><cfset arrayAppend(searchTermLabels, "target type")></cfif>
			<cfif len(trim(arguments.collection)) GT 0><cfset arrayAppend(searchTermLabels, "collection")></cfif>
			<cfif len(trim(arguments.specimen_guid)) GT 0><cfset arrayAppend(searchTermLabels, "specimen guid")></cfif>
			<cfif len(normalizedCollectionObjectId) GT 0><cfset arrayAppend(searchTermLabels, "collection object id")></cfif>
			<cfif len(normalizedFamily) GT 0><cfset arrayAppend(searchTermLabels, "family")></cfif>
			<cfif len(trim(arguments.scientific_name)) GT 0><cfset arrayAppend(searchTermLabels, "scientific name")></cfif>
			<cfif len(normalizedTaxonNameId) GT 0><cfset arrayAppend(searchTermLabels, "taxon name id")></cfif>
			<cfif len(normalizedPublicationId) GT 0><cfset arrayAppend(searchTermLabels, "publication")></cfif>
			<cfif len(trim(arguments.publication_text)) GT 0><cfset arrayAppend(searchTermLabels, "publication text")></cfif>
			<cfif len(normalizedProjectId) GT 0><cfset arrayAppend(searchTermLabels, "project")></cfif>
			<cfif len(trim(arguments.project_text)) GT 0><cfset arrayAppend(searchTermLabels, "project text")></cfif>
			<cfif listFindNoCase("yes,no", trim(arguments.has_responses))><cfset arrayAppend(searchTermLabels, "has responses")></cfif>
			<cfif arrayLen(searchTermLabels) GT 0><cfset searchedOn = arrayToList(searchTermLabels, ", ")></cfif>
			<div class="d-flex flex-wrap align-items-end mt-3 pl-1" id="annotationSearchResultsHeading">
				<h2 class="h3 mb-0 mr-3">Annotation Results (#searchResults.recordcount# #annotationLabel# on #targetCount# #targetLabel#)</h2>
				<div class="text-muted mb-1">Searched on #encodeForHTML(searchedOn)#.</div>
			</div>
			<cfif searchResults.recordcount EQ 0>
				<p class="text-muted pl-1 mt-2">No annotations found matching the selected filters.</p>
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
							<cfset targetMeta = "Current Identification: #encodeForHTML(targets.scientific_name)#; Locality: #encodeForHTML(targets.higher_geog)#: #encodeForHTML(targets.spec_locality)#">
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
							<cfset targetTitle = "Target #encodeForHTML(targets.target_primary_key)#">
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
						<cfquery name="targetAnnotations" dbtype="query">
							SELECT annotation_id, annotation_display, cf_username, email, annotate_date, motivation, reviewed_fg,
								state, resolution, reviewer, reviewer_comment, mask_annotation_fg, parent_annotation_id
							FROM searchResults
							WHERE target_table = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#targets.target_table#">
								AND target_primary_key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#targets.target_primary_key#">
						</cfquery>
						<cfloop query="targetAnnotations">
							<cfset showReplyAction = false>
							<cfif NOT isNumeric(targetAnnotations.parent_annotation_id)>
								<cfset showReplyAction = true>
							</cfif>
							<div id="annotation-block-#targetAnnotations.annotation_id#">
							<cfset annoRowHTML = renderAnnotationReviewRow(
								annotation_id=targetAnnotations.annotation_id,
								annotation_display=targetAnnotations.annotation_display,
								cf_username=targetAnnotations.cf_username,
								email=targetAnnotations.email,
								annotate_date=targetAnnotations.annotate_date,
								motivation=targetAnnotations.motivation,
								reviewed_fg=targetAnnotations.reviewed_fg,
								state=targetAnnotations.state,
								resolution=targetAnnotations.resolution,
								reviewer=targetAnnotations.reviewer,
								reviewer_comment=targetAnnotations.reviewer_comment,
								mask_annotation_fg=targetAnnotations.mask_annotation_fg,
								show_reply_action=showReplyAction
							)>
							#annoRowHTML#
							<cfif showReplyAction>
								#renderAnnotationConversationSection(rootAnnotationId=targetAnnotations.annotation_id, childAnnotations=childAnnotations, root_mask_annotation_fg=targetAnnotations.mask_annotation_fg)#
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
		<cfcatch>
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cfsavecontent>

	<cfreturn result>
</cffunction>

</cfcomponent>
