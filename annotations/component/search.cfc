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
<cfinclude template="/shared/component/error_handler.cfc" runOnce="true">

<!---
 getAnnotationSearchFilters builds filter select lists to support the search form.
 @return struct containing query objects used to populate annotation search controls:
   ctstate, ctresolution, ctmotivation, collections, families.
  Called by /annotations/Annotations.cfm to build filter select lists before rendering the form.
--->
<cffunction name="getAnnotationSearchFilters" returntype="struct" access="public">
	<cfset var filterData = StructNew()>
	<cfset var ctstate = QueryNew("")>
	<cfset var ctresolution = QueryNew("")>
	<cfset var ctmotivation = QueryNew("")>
	<cfset var collections = QueryNew("")>
	<cfset var families = QueryNew("")>

	<cfquery name="ctstate" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		SELECT state
		FROM ctstate
		ORDER BY state
	</cfquery>
	<cfquery name="ctresolution" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		SELECT resolution
		FROM ctresolution
		ORDER BY resolution
	</cfquery>
	<cfquery name="ctmotivation" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		SELECT motivation
		FROM ctmotivation
		ORDER BY motivation
	</cfquery>
	<cfquery name="collections" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
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
	<cfquery name="families" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
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

	<cfset filterData.ctstate = ctstate>
	<cfset filterData.ctresolution = ctresolution>
	<cfset filterData.ctmotivation = ctmotivation>
	<cfset filterData.collections = collections>
	<cfset filterData.families = families>
	<cfreturn filterData>
</cffunction>

<!---
 findAnnotations performs generalized annotation-first search with optional target-aware filtering.
 @param target_type optional target selector: collection_object|taxon_name|publication|project (aliases with *_id are accepted).
 @param state optional annotation state exact match.
 @param resolution optional annotation resolution exact match.
 @param annotator optional username fragment (case-insensitive contains match).
 @param annotation_text optional annotation body fragment (case-insensitive contains match).
 @param motivation optional annotation motivation exact match.
 @param reviewed_fg optional review flag; accepts 1/0/true/false/yes/no.
 @param root_mode optional thread position filter; root (default) or response.
 @param visibility optional mask flag; accepts 1/0/true/false/yes/no.
 @param collection optional exact collection name for specimen targets.
 @param specimen_guid optional specimen guid filter; supports single guid, comma-delimited list, or SQL wildcard pattern.
 @param collection_object_id optional numeric specimen primary key filter.
 @param family optional exact taxon family filter (case-insensitive).
 @param scientific_name optional taxon scientific name fragment (case-insensitive contains match).
 @param taxon_name_id optional numeric taxon primary key filter.
 @param publication_id optional numeric publication primary key filter.
 @param project_id optional numeric project primary key filter.
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
	<cfargument name="project_id" type="string" required="no" default="">

	<cfset var targetTableFilter = "">
	<cfset var normalizedRootMode = "root">
	<cfset var normalizedReviewedFg = "">
	<cfset var normalizedVisibility = "">
	<cfset var annotationResults = QueryNew("")>

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
	</cfswitch>
	<cfif len(targetTableFilter) GT 0>
		<cfset targetTableFilter = ucase(targetTableFilter)>
	</cfif>

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
			annotations.target_table,
			annotations.target_primary_key,
			annotations.parent_annotation_id,
			CASE
				WHEN annotations.target_table = 'COLLECTION_OBJECT' THEN annotations.target_primary_key
				ELSE NULL
			END collection_object_id,
			CASE
				WHEN annotations.target_table = 'TAXON_NAME' THEN annotations.target_primary_key
				ELSE NULL
			END taxon_name_id,
			CASE
				WHEN annotations.target_table = 'PUBLICATION' THEN annotations.target_primary_key
				ELSE NULL
			END publication_id,
			CASE
				WHEN annotations.target_table = 'PROJECT' THEN annotations.target_primary_key
				ELSE NULL
			END project_id,
			cf_user_data.email,
			collection.collection,
			collection.collection_cde,
			collection.institution_acronym,
			cataloged_item.cat_num,
			NVL(identification.scientific_name, '') idAs,
			NVL(geog_auth_rec.higher_geog, '') higher_geog,
			NVL(locality.spec_locality, '') spec_locality,
			taxonomy.scientific_name taxon_scientific_name,
			taxonomy.display_name taxon_display_name,
			taxonomy.family taxon_family,
			publication.publication_title,
			project.project_name,
			to_char(annotations.target_primary_key) target_key
		FROM
			annotations
			LEFT OUTER JOIN cataloged_item ON annotations.target_table = 'COLLECTION_OBJECT'
				AND annotations.target_primary_key = cataloged_item.collection_object_id
			LEFT OUTER JOIN collection ON cataloged_item.collection_id = collection.collection_id
			LEFT OUTER JOIN identification ON cataloged_item.collection_object_id = identification.collection_object_id
				AND identification.accepted_id_fg = 1
			LEFT OUTER JOIN collecting_event ON cataloged_item.collecting_event_id = collecting_event.collecting_event_id
			LEFT OUTER JOIN locality ON collecting_event.locality_id = locality.locality_id
			LEFT OUTER JOIN geog_auth_rec ON locality.geog_auth_rec_id = geog_auth_rec.geog_auth_rec_id
			LEFT OUTER JOIN taxonomy ON annotations.target_table = 'TAXON_NAME'
				AND annotations.target_primary_key = taxonomy.taxon_name_id
			LEFT OUTER JOIN publication ON annotations.target_table = 'PUBLICATION'
				AND annotations.target_primary_key = publication.publication_id
			LEFT OUTER JOIN project ON annotations.target_table = 'PROJECT'
				AND annotations.target_primary_key = project.project_id
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
				AND annotations.target_table = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#targetTableFilter#">
			<cfelse>
				AND annotations.target_table IN ('COLLECTION_OBJECT','TAXON_NAME','PUBLICATION','PROJECT')
			</cfif>
			<cfif normalizedRootMode EQ "root">
				AND annotations.parent_annotation_id IS NULL
			<cfelseif normalizedRootMode EQ "response">
				AND annotations.parent_annotation_id IS NOT NULL
			</cfif>
			<cfif len(trim(arguments.state)) GT 0>
				AND annotations.state = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(arguments.state)#">
			</cfif>
			<cfif len(trim(arguments.resolution)) GT 0>
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
				AND annotations.target_table = 'COLLECTION_OBJECT'
				AND annotations.target_primary_key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#trim(arguments.collection_object_id)#">
			</cfif>
			<cfif len(trim(arguments.specimen_guid)) GT 0>
				AND annotations.target_table = 'COLLECTION_OBJECT'
				AND annotations.target_primary_key IN (
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
				AND annotations.target_table = 'TAXON_NAME'
				AND annotations.target_primary_key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#trim(arguments.taxon_name_id)#">
			</cfif>
			<cfif len(trim(arguments.family)) GT 0>
				AND upper(taxonomy.family) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(trim(arguments.family))#">
			</cfif>
			<cfif len(trim(arguments.scientific_name)) GT 0>
				AND upper(taxonomy.scientific_name) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(trim(arguments.scientific_name))#%">
			</cfif>
			<cfif len(trim(arguments.publication_id)) GT 0 AND isNumeric(arguments.publication_id)>
				AND annotations.target_table = 'PUBLICATION'
				AND annotations.target_primary_key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#trim(arguments.publication_id)#">
			</cfif>
			<cfif len(trim(arguments.project_id)) GT 0 AND isNumeric(arguments.project_id)>
				AND annotations.target_table = 'PROJECT'
				AND annotations.target_primary_key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#trim(arguments.project_id)#">
			</cfif>
		ORDER BY
			annotations.target_table,
			target_key,
			annotations.annotate_date DESC
	</cfquery>
	<cfreturn annotationResults>
</cffunction>

</cfcomponent>
