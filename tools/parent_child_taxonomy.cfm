<!---
/tools/parent_child_taxonomy.cfm

Review and synchronize accepted identifications across selected biological
relationships where related cataloged items are expected to share taxonomy.

Copyright 2008-2017 Contributors to Arctos
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
<cfset pageTitle = "Relationship Identification Consistency Sync">
<cfinclude template="/shared/_header.cfm">
<script src="/lib/misc/sorttable.js"></script>
<script src="/tools/js/parentChildTaxonomy.js"></script>

<cfparam name="url.action" default="">
<cfparam name="form.action" default="">
<cfparam name="url.relationship_type" default="">
<cfparam name="form.relationship_type" default="">
<cfparam name="url.execute" default="false">
<cfparam name="form.execute" default="">
<cfparam name="url.collection_object_id" default="">
<cfparam name="form.collection_object_id" default="">
<!--- selected_pair serves to identify one sync action with source id, target id, and direction separated by a delimiter, it can be a list. --->
<cfparam name="form.selected_pair" default="">

<cfset variables.ALLOWED_RELATIONSHIPS = "parent of,embryo of,offspring of,littermate of,sibling of,egg of,same individual organism as,part to counterpart,cast of">
<cfset variables.SELECTED_PAIR_DELIMITER = ":"><!--- NOTE: Can not be a comma, as delimited pairs are composed into a comma separated list --->

<cfset variables.action = "entryPoint">
<cfif len(trim(url.action)) GT 0><cfset variables.action = trim(url.action)></cfif>
<cfif len(trim(form.action)) GT 0><cfset variables.action = trim(form.action)></cfif>

<cfset variables.relationshipType = "parent of">
<cfif len(trim(url.relationship_type)) GT 0><cfset variables.relationshipType = lcase(trim(url.relationship_type))></cfif>
<cfif len(trim(form.relationship_type)) GT 0><cfset variables.relationshipType = lcase(trim(form.relationship_type))></cfif>

<cfset variables.execute = false>
<cfif isBoolean(url.execute)><cfset variables.execute = url.execute></cfif>
<cfif isBoolean(form.execute)><cfset variables.execute = form.execute></cfif>

<cfset variables.collectionObjectIdFilter = "">
<cfif len(trim(url.collection_object_id)) GT 0><cfset variables.collectionObjectIdFilter = trim(url.collection_object_id)></cfif>
<cfif len(trim(form.collection_object_id)) GT 0><cfset variables.collectionObjectIdFilter = trim(form.collection_object_id)></cfif>

<cfset variables.statusClass = "text-info">
<cfset variables.statusMessage = "Select a biological relationship and run the check.">
<cfset variables.invalidRelationship = false>
<cfset variables.invalidCollectionObjectId = false>

<cfquery name="ctRelationships" datasource="cf_dbuser" cachedwithin="#createTimeSpan(0,2,0,0)#">
	SELECT
		biol_indiv_relationship
	FROM
		ctbiol_relations
	WHERE
		rel_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="biological" />
		AND (
			lower(biol_indiv_relationship) IN (
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" list="yes" value="#variables.ALLOWED_RELATIONSHIPS#">
			)
			OR lower(inverse_relation) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="parent of">
		)
	ORDER BY
		biol_indiv_relationship
</cfquery>

<cfset variables.relationshipOptions = "">
<cfloop query="ctRelationships">
	<cfif listFindNoCase(variables.ALLOWED_RELATIONSHIPS, ctRelationships.biol_indiv_relationship) AND NOT listFindNoCase(variables.relationshipOptions, ctRelationships.biol_indiv_relationship)>
		<cfset variables.relationshipOptions = listAppend(variables.relationshipOptions, lcase(ctRelationships.biol_indiv_relationship))>
	</cfif>
</cfloop>
<cfif len(variables.relationshipOptions) EQ 0>
	<cfset variables.relationshipOptions = variables.ALLOWED_RELATIONSHIPS>
</cfif>

<cfif NOT listFindNoCase(variables.relationshipOptions, variables.relationshipType)>
	<cfset variables.invalidRelationship = true>
	<cfset variables.relationshipType = "parent of">
</cfif>
<cfset variables.inverseRelationshipType = "">
<cfquery name="getInverseRelationship" datasource="cf_dbuser" cachedwithin="#createTimeSpan(0,2,0,0)#">
	SELECT
		lower(inverse_relation) AS inverse_relationship
	FROM
		ctbiol_relations
	WHERE
		rel_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="biological" />
		AND lower(biol_indiv_relationship) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.relationshipType#">
</cfquery>
<cfif getInverseRelationship.recordcount EQ 1 AND len(trim(getInverseRelationship.inverse_relationship)) GT 0>
	<cfset variables.inverseRelationshipType = trim(getInverseRelationship.inverse_relationship)>
<cfelse>
	<cfset variables.inverseRelationshipType = variables.relationshipType>
</cfif>
<cfset variables.isSelfReciprocalRelationship = variables.relationshipType EQ variables.inverseRelationshipType>

<cfif len(variables.collectionObjectIdFilter) GT 0 AND NOT isValid("integer", variables.collectionObjectIdFilter)>
	<cfset variables.invalidCollectionObjectId = true>
	<cfset variables.collectionObjectIdFilter = "">
</cfif>

<cfset variables.shouldQuery = variables.execute OR variables.action EQ "syncSelected">
<cfif variables.invalidRelationship>
	<cfset variables.statusClass = "text-danger">
	<cfset variables.statusMessage = "Requested relationship type was invalid. Showing parent of.">
<cfelseif variables.invalidCollectionObjectId>
	<cfset variables.statusClass = "text-danger">
	<cfset variables.statusMessage = "Collection object filter must be numeric.">
</cfif>

<cfset variables.attemptedCount = 0>
<cfset variables.updatedCount = 0>
<cfset variables.skippedCount = 0>
<cfset variables.invalidCount = 0>
<cfset variables.updatedSelectionList = "">
<cfset variables.noDeterminerText = "[no determiner]">
<cfset variables.guidUnavailableText = "[GUID unavailable]">
<cfset variables.updatedSummaryColumns = "source_collection_object_id,related_collection_object_id,source_guid,related_guid,scientific_name,nature_of_id,determiner,made_date">
<cfset variables.updatedSummaryTypes = "varchar,varchar,varchar,varchar,varchar,varchar,varchar,varchar">
<cfset variables.updatedSummaryRows = queryNew(variables.updatedSummaryColumns, variables.updatedSummaryTypes)>

<cfif variables.action EQ "syncSelected">
	<cfif len(trim(form.selected_pair)) EQ 0>
		<cfset variables.statusClass = "text-warning">
		<cfset variables.statusMessage = "No copy actions were selected. Select one or more copy actions to add/sync accepted identifications.">
	<cfelse>
		<cfset variables.syncDeterminer = variables.noDeterminerText>
		<cfset variables.syncIdentifiedDate = dateFormat(now(), "yyyy-MM-dd")>
		<cfquery name="getSyncDeterminer" datasource="cf_dbuser">
			SELECT
				nvl(agent_name, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.noDeterminerText#">) AS agent_name
			FROM
				preferred_agent_name
			WHERE
				agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#session.myAgentId#">
		</cfquery>
		<cfif getSyncDeterminer.recordcount EQ 1>
			<cfset variables.syncDeterminer = getSyncDeterminer.agent_name>
		</cfif>
		<cfset variables.selectedCollectionObjectIds = "">
		<cfset variables.selectedGuidMap = structNew()>
		<cfloop list="#form.selected_pair#" index="variables.selectedPair">
			<cfset variables.selectedPairSourceCollectionObjectId = listGetAt(variables.selectedPair, 1, variables.SELECTED_PAIR_DELIMITER)>
			<cfset variables.selectedPairRelatedCollectionObjectId = listGetAt(variables.selectedPair, 2, variables.SELECTED_PAIR_DELIMITER)>
			<cfif isValid("integer", variables.selectedPairSourceCollectionObjectId) AND isValid("integer", variables.selectedPairRelatedCollectionObjectId)>
				<cfif NOT listFind(variables.selectedCollectionObjectIds, variables.selectedPairSourceCollectionObjectId)>
					<cfset variables.selectedCollectionObjectIds = listAppend(variables.selectedCollectionObjectIds, variables.selectedPairSourceCollectionObjectId)>
				</cfif>
				<cfif NOT listFind(variables.selectedCollectionObjectIds, variables.selectedPairRelatedCollectionObjectId)>
					<cfset variables.selectedCollectionObjectIds = listAppend(variables.selectedCollectionObjectIds, variables.selectedPairRelatedCollectionObjectId)>
				</cfif>
			</cfif>
		</cfloop>
		<cfif len(variables.selectedCollectionObjectIds) GT 0>
			<cfquery name="getSelectedGuids" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT
					flat.collection_object_id,
					nvl(flat.guid, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.guidUnavailableText#">) AS guid
				FROM
					#session.flatTableName# flat
				WHERE
					flat.collection_object_id IN (<cfqueryparam cfsqltype="CF_SQL_DECIMAL" list="yes" value="#variables.selectedCollectionObjectIds#">)
			</cfquery>
			<cfloop query="getSelectedGuids">
				<cfset variables.selectedGuidMap[getSelectedGuids.collection_object_id] = getSelectedGuids.guid>
			</cfloop>
		</cfif>
		<cfloop list="#form.selected_pair#" index="variables.selectedPair">
			<cfset variables.attemptedCount = variables.attemptedCount + 1>
			<cfset variables.pairSourceCollectionObjectId = listGetAt(variables.selectedPair, 1, variables.SELECTED_PAIR_DELIMITER)>
			<cfset variables.pairRelatedCollectionObjectId = listGetAt(variables.selectedPair, 2, variables.SELECTED_PAIR_DELIMITER)>
			<cfset variables.copyDirection = "source_to_related">
			<cfset variables.validCopyDirection = true>
			<cfif listLen(variables.selectedPair, variables.SELECTED_PAIR_DELIMITER) GTE 3>
				<cfset variables.selectedDirection = lcase(trim(listGetAt(variables.selectedPair, 3, variables.SELECTED_PAIR_DELIMITER)))>
				<cfif variables.selectedDirection EQ "r2s">
					<cfset variables.copyDirection = "related_to_source">
				<cfelseif variables.selectedDirection EQ "s2r">
					<cfset variables.copyDirection = "source_to_related">
				<cfelse>
					<cfset variables.validCopyDirection = false>
				</cfif>
			</cfif>
			<cfset variables.sourceCollectionObjectId = variables.pairSourceCollectionObjectId>
			<cfset variables.relatedCollectionObjectId = variables.pairRelatedCollectionObjectId>
			<cfif variables.copyDirection EQ "related_to_source">
				<cfset variables.sourceCollectionObjectId = variables.pairRelatedCollectionObjectId>
				<cfset variables.relatedCollectionObjectId = variables.pairSourceCollectionObjectId>
			</cfif>
			<cfif NOT variables.validCopyDirection OR NOT isValid("integer", variables.sourceCollectionObjectId) OR NOT isValid("integer", variables.relatedCollectionObjectId)>
				<cfset variables.invalidCount = variables.invalidCount + 1>
			<cfelse>
				<cftransaction>
					<cfquery name="getSourceIdentification" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						SELECT
							sourceId.identification_id,
							sourceId.nature_of_id,
							sourceId.taxa_formula,
							sourceId.scientific_name
						FROM
							identification sourceId
							JOIN identification relatedId ON relatedId.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.relatedCollectionObjectId#">
						WHERE
							sourceId.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.sourceCollectionObjectId#">
							AND sourceId.accepted_id_fg = 1
							AND relatedId.accepted_id_fg = 1
							AND sourceId.scientific_name <> relatedId.scientific_name
							AND nvl(sourceId.taxa_formula,'A') <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="A x B">
							AND nvl(relatedId.taxa_formula,'A') <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="A x B">
							AND EXISTS (
								SELECT
									1
								FROM
									biol_indiv_relations bir
								WHERE
									lower(bir.biol_indiv_relationship) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.relationshipType#">
									AND (
										(
											bir.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.sourceCollectionObjectId#">
											AND bir.related_coll_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.relatedCollectionObjectId#">
										)
										OR (
											bir.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.relatedCollectionObjectId#">
											AND bir.related_coll_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.sourceCollectionObjectId#">
										)
									)
							)
					</cfquery>
					<cfif getSourceIdentification.recordcount EQ 1>
						<cfset variables.newNatureOfId = "ID of kin">
						<cfif variables.relationshipType EQ "part to counterpart">
							<cfset variables.newNatureOfId = getSourceIdentification.nature_of_id>
						</cfif>
						<cfquery name="unsetCurrentId" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							UPDATE identification
							SET accepted_id_fg = 0
							WHERE
								collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.relatedCollectionObjectId#">
								AND accepted_id_fg = 1
						</cfquery>
						<cfquery name="insertNewIdentification" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							INSERT INTO identification (
								IDENTIFICATION_ID,
								COLLECTION_OBJECT_ID,
								MADE_DATE,
								NATURE_OF_ID,
								ACCEPTED_ID_FG,
								TAXA_FORMULA,
								SCIENTIFIC_NAME
							) VALUES (
								sq_identification_id.nextval,
								<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.relatedCollectionObjectId#">,
								sysdate,
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.newNatureOfId#">,
								1,
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getSourceIdentification.taxa_formula#">,
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getSourceIdentification.scientific_name#">
							)
						</cfquery>
						<cfquery name="copyTaxonomyRows" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							INSERT INTO identification_taxonomy (
								identification_id,
								taxon_name_id,
								variable
							)
							SELECT
								sq_identification_id.currval,
								taxon_name_id,
								variable
							FROM
								identification_taxonomy
							WHERE
								identification_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getSourceIdentification.identification_id#">
						</cfquery>
						<cfquery name="insertIdentifierAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							INSERT INTO identification_agent (
								IDENTIFICATION_ID,
								AGENT_ID,
								IDENTIFIER_ORDER
							) VALUES (
								sq_identification_id.currval,
								<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#session.myAgentId#">,
								1
							)
						</cfquery>
						<cfset variables.updatedCount = variables.updatedCount + 1>
						<cfset variables.updatedSelectionList = listAppend(variables.updatedSelectionList, "#variables.sourceCollectionObjectId##variables.SELECTED_PAIR_DELIMITER##variables.relatedCollectionObjectId#")>
						<cfset variables.updatedSummaryRowIndex = queryAddRow(variables.updatedSummaryRows, 1)>
						<cfset querySetCell(variables.updatedSummaryRows, "source_collection_object_id", variables.sourceCollectionObjectId, variables.updatedSummaryRowIndex)>
						<cfset querySetCell(variables.updatedSummaryRows, "related_collection_object_id", variables.relatedCollectionObjectId, variables.updatedSummaryRowIndex)>
						<cfset variables.updatedSourceGuid = variables.guidUnavailableText>
						<cfset variables.updatedRelatedGuid = variables.guidUnavailableText>
						<cfif structKeyExists(variables.selectedGuidMap, variables.sourceCollectionObjectId)>
							<cfset variables.updatedSourceGuid = variables.selectedGuidMap[variables.sourceCollectionObjectId]>
						</cfif>
						<cfif structKeyExists(variables.selectedGuidMap, variables.relatedCollectionObjectId)>
							<cfset variables.updatedRelatedGuid = variables.selectedGuidMap[variables.relatedCollectionObjectId]>
						</cfif>
						<cfset querySetCell(variables.updatedSummaryRows, "source_guid", variables.updatedSourceGuid, variables.updatedSummaryRowIndex)>
						<cfset querySetCell(variables.updatedSummaryRows, "related_guid", variables.updatedRelatedGuid, variables.updatedSummaryRowIndex)>
						<cfset querySetCell(variables.updatedSummaryRows, "scientific_name", getSourceIdentification.scientific_name, variables.updatedSummaryRowIndex)>
						<cfset querySetCell(variables.updatedSummaryRows, "nature_of_id", variables.newNatureOfId, variables.updatedSummaryRowIndex)>
						<cfset querySetCell(variables.updatedSummaryRows, "determiner", variables.syncDeterminer, variables.updatedSummaryRowIndex)>
						<cfset querySetCell(variables.updatedSummaryRows, "made_date", variables.syncIdentifiedDate, variables.updatedSummaryRowIndex)>
					<cfelse>
						<cfset variables.skippedCount = variables.skippedCount + 1>
					</cfif>
				</cftransaction>
			</cfif>
		</cfloop>
		<cfset variables.statusClass = "text-info">
		<cfset variables.statusMessage = "Processed #variables.attemptedCount# selected action(s): #variables.updatedCount# updated, #variables.skippedCount# skipped, #variables.invalidCount# invalid selections.">
	</cfif>
</cfif>

<cfif variables.shouldQuery>
	<cfquery name="relationshipPairs" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		WITH identificationCounts AS (
			SELECT
				collection_object_id,
				sum(CASE WHEN accepted_id_fg = 0 THEN 1 ELSE 0 END) AS other_identification_count
			FROM
				identification
			GROUP BY
				collection_object_id
		)
		SELECT
			bir.collection_object_id,
			bir.related_coll_object_id,
			sourceId.identification_id AS source_identification_id,
			sourceId.scientific_name AS source_scientific_name,
			sourceId.nature_of_id AS source_identification_type,
			sourceId.made_date AS source_identification_date,
			nvl(sourcePAN.agent_name, '[no determiner]') AS source_determiner,
			relatedId.identification_id AS related_identification_id,
			relatedId.scientific_name AS related_scientific_name,
			relatedId.nature_of_id AS related_identification_type,
			relatedId.made_date AS related_identification_date,
			nvl(relatedPAN.agent_name, '[no determiner]') AS related_determiner,
			sourceCat.cat_num AS source_cat_num,
			relatedCat.cat_num AS related_cat_num,
			sourceColl.collection_cde AS source_collection_cde,
			relatedColl.collection_cde AS related_collection_cde,
			sourceColl.institution_acronym AS source_institution_acronym,
			relatedColl.institution_acronym AS related_institution_acronym,
			nvl(sourceIdCount.other_identification_count, 0) AS source_other_identification_count,
			nvl(relatedIdCount.other_identification_count, 0) AS related_other_identification_count,
			concatSingleOtherId(sourceCat.collection_object_id, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.CustomOtherIdentifier#" null="#NOT isDefined('session.CustomOtherIdentifier') OR len(session.CustomOtherIdentifier) EQ 0#">) AS source_custom_id,
			concatSingleOtherId(relatedCat.collection_object_id, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.CustomOtherIdentifier#" null="#NOT isDefined('session.CustomOtherIdentifier') OR len(session.CustomOtherIdentifier) EQ 0#">) AS related_custom_id
		FROM
			biol_indiv_relations bir
			JOIN cataloged_item sourceCat ON bir.collection_object_id = sourceCat.collection_object_id
			JOIN cataloged_item relatedCat ON bir.related_coll_object_id = relatedCat.collection_object_id
			JOIN collection sourceColl ON sourceCat.collection_id = sourceColl.collection_id
			JOIN collection relatedColl ON relatedCat.collection_id = relatedColl.collection_id
			JOIN identification sourceId ON sourceCat.collection_object_id = sourceId.collection_object_id
			LEFT JOIN identification_agent sourceIA ON sourceId.identification_id = sourceIA.identification_id AND sourceIA.identifier_order = 1
			LEFT JOIN preferred_agent_name sourcePAN ON sourceIA.agent_id = sourcePAN.agent_id
			LEFT JOIN identificationCounts sourceIdCount ON sourceCat.collection_object_id = sourceIdCount.collection_object_id
			JOIN identification relatedId ON relatedCat.collection_object_id = relatedId.collection_object_id
			LEFT JOIN identification_agent relatedIA ON relatedId.identification_id = relatedIA.identification_id AND relatedIA.identifier_order = 1
			LEFT JOIN preferred_agent_name relatedPAN ON relatedIA.agent_id = relatedPAN.agent_id
			LEFT JOIN identificationCounts relatedIdCount ON relatedCat.collection_object_id = relatedIdCount.collection_object_id
		WHERE
			lower(bir.biol_indiv_relationship) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.relationshipType#">
			<cfif variables.isSelfReciprocalRelationship>
				AND bir.collection_object_id < bir.related_coll_object_id
			</cfif>
			AND sourceId.accepted_id_fg = 1
			AND relatedId.accepted_id_fg = 1
			AND sourceId.scientific_name <> relatedId.scientific_name
			AND nvl(sourceId.taxa_formula,'A') <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="A x B">
			AND nvl(relatedId.taxa_formula,'A') <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="A x B">
			<cfif len(variables.collectionObjectIdFilter) GT 0>
				AND bir.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.collectionObjectIdFilter#">
			</cfif>
		ORDER BY
			sourceColl.collection_cde,
			sourceCat.cat_num,
			relatedColl.collection_cde,
			relatedCat.cat_num
	</cfquery>
	<cfif relationshipPairs.recordcount EQ 0 AND variables.action NEQ "syncSelected" AND NOT variables.invalidRelationship AND NOT variables.invalidCollectionObjectId>
		<cfset variables.statusClass = "text-info">
		<cfset variables.statusMessage = "No eligible #variables.relationshipType# taxonomy mismatches found (hybrids excluded).">
	</cfif>
</cfif>
<cfset variables.natureOfIdGuidance = "Nature of ID on the new accepted identification is set to ID of kin for this relationship type.">
<cfif variables.relationshipType EQ "part to counterpart">
	<cfset variables.natureOfIdGuidance = "Nature of ID on the new accepted identification is copied from the selected source accepted identification for part to counterpart.">
</cfif>

<main class="container-fluid py-3 px-xl-5" id="content">
	<section class="row">
		<div class="col-12">
			<h1 class="h2">Relationship Taxonomy Consistency Checks and Sync</h1>
			<p class="mb-1">This tool lists cataloged item pairs linked by one biological relationship type at a time where both items are expected to have the same taxon identification.</p>
			<p class="mb-1">Use this to examine accepted identifications and add/sync accepted IDs from the listed relationship source item to the related item.  Evaluate each record with care, before using this form to add identifications, the relationship may be in error, or there may be a good reason why the identifications are different.</p>
			<p class="mb-3">Hybrid taxa (taxon formula <em>A x B</em>) are excluded from this actionable list.</p>
		</div>
	</section>

	<section class="row" aria-labelledby="relationshipFiltersHeading">
		<div class="col-12 border border-rounded py-2 ">
			<h2 class="h4" id="relationshipFiltersHeading">Find mismatches by relationship type</h2>
			<cfoutput>
			<form method="get" action="/tools/parent_child_taxonomy.cfm" class="form-row align-items-end g-2">
				<input type="hidden" name="execute" value="true">
				<div class="col-auto">
					<label for="relationship_type" class="d-block">Biological Relationship (same-taxon expected)</label>
					<select name="relationship_type" id="relationship_type" class="data-entry-select reqdClr">
						<cfloop list="#variables.relationshipOptions#" index="variables.relationshipOption">
							<cfset variables.relationshipSelected = "">
							<cfif variables.relationshipOption EQ variables.relationshipType><cfset variables.relationshipSelected = 'selected="selected"'></cfif>
							<option #variables.relationshipSelected# value="#encodeForHtmlAttribute(variables.relationshipOption)#">#encodeForHtml(variables.relationshipOption)#</option>
						</cfloop>
					</select>
				</div>
				<div class="col-auto">
					<label for="collection_object_id" class="d-block">Optional source collection_object_id</label>
					<input type="text" id="collection_object_id" name="collection_object_id" class="data-entry-input" value="#encodeForHtmlAttribute(variables.collectionObjectIdFilter)#">
				</div>
				<div class="col-auto">
					<input type="submit" class="btn btn-primary" value="Find Taxonomy Mismatches for Selected Relationship">
				</div>
			</form>
			</cfoutput>
		</div>
	</section>

	<section class="row mt-3" aria-labelledby="resultsHeading">
		<div class="col-12">
			<cfoutput>
			<output id="statusMessage" class="#encodeForHtmlAttribute(variables.statusClass)#" aria-live="polite">#encodeForHtml(variables.statusMessage)#</output>
			<cfif variables.action EQ "syncSelected" AND variables.updatedCount GT 0>
				<div class="mt-2">
					<p class="mb-1">Added accepted identifications for:</p>
					<ul class="mb-0">
						<cfloop query="variables.updatedSummaryRows">
							<li>
								added #encodeForHtml(variables.updatedSummaryRows.scientific_name)# as an accepted identification to the related specimen
								<cfif trim(variables.updatedSummaryRows.related_guid) EQ variables.guidUnavailableText>
									#encodeForHtml(variables.updatedSummaryRows.related_guid)#
								<cfelse>
									<a href="/guid/#encodeForUrl(variables.updatedSummaryRows.related_guid)#">#encodeForHtml(variables.updatedSummaryRows.related_guid)#</a>
								</cfif>
								from source
								<cfif trim(variables.updatedSummaryRows.source_guid) EQ variables.guidUnavailableText>
									#encodeForHtml(variables.updatedSummaryRows.source_guid)#
								<cfelse>
									<a href="/guid/#encodeForUrl(variables.updatedSummaryRows.source_guid)#">#encodeForHtml(variables.updatedSummaryRows.source_guid)#</a>
								</cfif>;
								type of id: #encodeForHtml(variables.updatedSummaryRows.nature_of_id)#;
								determiner: #encodeForHtml(variables.updatedSummaryRows.determiner)#;
								date identified: #encodeForHtml(variables.updatedSummaryRows.made_date)#
							</li>
						</cfloop>
					</ul>
				</div>
			</cfif>
			<h2 class="h4 mt-3" id="resultsHeading">Actionable relationship records<cfif isDefined("relationshipPairs")> (#relationshipPairs.recordcount#)</cfif></h2>
			</cfoutput>
		</div>

		<cfif isDefined("relationshipPairs")>
			<div class="col-12 mt-2">
				<cfif relationshipPairs.recordcount GT 0>
					<cfoutput>
					<form method="post" action="/tools/parent_child_taxonomy.cfm" id="bulkSyncForm">
						<input type="hidden" name="action" value="syncSelected">
						<input type="hidden" name="execute" value="true">
						<input type="hidden" name="relationship_type" value="#encodeForHtmlAttribute(variables.relationshipType)#">
						<input type="hidden" name="collection_object_id" value="#encodeForHtmlAttribute(variables.collectionObjectIdFilter)#">
						<div class="table-responsive">
							<table class="sortable table table-responsive d-xl-table table-striped table-sm">
								<thead>
									<tr>
										<th scope="col">Relationship Source Item</th>
										<th scope="col">Source Accepted Identification</th>
										<th scope="col">Copy ID</th>
										<th scope="col">Related Item</th>
										<th scope="col">Related Accepted Identification</th>
									</tr>
								</thead>
								<tbody>
									<cfloop query="relationshipPairs">
										<!--- identify the row to be updated with a pair of collection object ids, one source, one target (related) separated by a delimiter --->
										<cfset variables.rowValue = "#relationshipPairs.collection_object_id##variables.SELECTED_PAIR_DELIMITER##relationshipPairs.related_coll_object_id#">
										<cfset variables.sourceSpecimenLabel = "#relationshipPairs.source_institution_acronym# #relationshipPairs.source_collection_cde# #relationshipPairs.source_cat_num#">
										<cfset variables.relatedSpecimenLabel = "#relationshipPairs.related_institution_acronym# #relationshipPairs.related_collection_cde# #relationshipPairs.related_cat_num#">
										<tr>
											<td>
												<a href="/specimens/Specimen.cfm?collection_object_id=#encodeForUrl(relationshipPairs.collection_object_id)#">#encodeForHtml(relationshipPairs.source_institution_acronym)# #encodeForHtml(relationshipPairs.source_collection_cde)# #encodeForHtml(relationshipPairs.source_cat_num)#</a>
												<cfif len(trim(relationshipPairs.source_custom_id)) GT 0>
													<br><span class="small">#encodeForHtml(session.CustomOtherIdentifier)# = #encodeForHtml(relationshipPairs.source_custom_id)#</span>
												</cfif>
											</td>
											<td>
												#encodeForHtml(relationshipPairs.source_scientific_name)#
												<cfif len(trim(relationshipPairs.source_determiner)) GT 0 AND relationshipPairs.source_determiner NEQ '[no determiner]'>
													<br><span class="small text-muted">Determiner: #encodeForHtml(relationshipPairs.source_determiner)#</span>
												</cfif>
												<cfif len(trim(relationshipPairs.source_identification_date)) GT 0>
													<br><span class="small text-muted">Date identified: #dateFormat(relationshipPairs.source_identification_date, 'yyyy-mm-dd')#</span>
												</cfif>
												<cfif len(trim(relationshipPairs.source_identification_type)) GT 0>
													<br><span class="small text-muted">Type of identification: #encodeForHtml(relationshipPairs.source_identification_type)#</span>
												</cfif>
												<cfif relationshipPairs.source_other_identification_count GT 0>
													<br><span class="small text-muted">#encodeForHtml(relationshipPairs.source_other_identification_count)# other identification<cfif relationshipPairs.source_other_identification_count NEQ 1>s</cfif></span>
												</cfif>
											</td>
											<td>
												<input type="checkbox" class="relationship-row-check" name="selected_pair" value="#encodeForHtmlAttribute(variables.rowValue & variables.SELECTED_PAIR_DELIMITER & 's2r')#" aria-label="Copy accepted identification from #encodeForHtmlAttribute(variables.sourceSpecimenLabel)# to #encodeForHtmlAttribute(variables.relatedSpecimenLabel)#">
												<span class="small" aria-hidden="true">copy id &#8594;</span>
												<br>
												<input type="checkbox" class="relationship-row-check" name="selected_pair" value="#encodeForHtmlAttribute(variables.rowValue & variables.SELECTED_PAIR_DELIMITER & 'r2s')#" aria-label="Copy accepted identification from #encodeForHtmlAttribute(variables.relatedSpecimenLabel)# to #encodeForHtmlAttribute(variables.sourceSpecimenLabel)#">
												<span class="small" aria-hidden="true">&#8592; copy id</span>
											</td>
											<td>
												<a href="/specimens/Specimen.cfm?collection_object_id=#encodeForUrl(relationshipPairs.related_coll_object_id)#">#encodeForHtml(relationshipPairs.related_institution_acronym)# #encodeForHtml(relationshipPairs.related_collection_cde)# #encodeForHtml(relationshipPairs.related_cat_num)#</a>
												<cfif len(trim(relationshipPairs.related_custom_id)) GT 0>
													<br><span class="small">#encodeForHtml(session.CustomOtherIdentifier)# = #encodeForHtml(relationshipPairs.related_custom_id)#</span>
												</cfif>
											</td>
											<td>
												#encodeForHtml(relationshipPairs.related_scientific_name)#
												<cfif len(trim(relationshipPairs.related_determiner)) GT 0 AND relationshipPairs.related_determiner NEQ '[no determiner]'>
													<br><span class="small text-muted">Determiner: #encodeForHtml(relationshipPairs.related_determiner)#</span>
												</cfif>
												<cfif len(trim(relationshipPairs.related_identification_date)) GT 0>
													<br><span class="small text-muted">Date identified: #dateFormat(relationshipPairs.related_identification_date, 'yyyy-mm-dd')#</span>
												</cfif>
												<cfif len(trim(relationshipPairs.related_identification_type)) GT 0>
													<br><span class="small text-muted">Type of identification: #encodeForHtml(relationshipPairs.related_identification_type)#</span>
												</cfif>
												<cfif relationshipPairs.related_other_identification_count GT 0>
													<br><span class="small text-muted">#encodeForHtml(relationshipPairs.related_other_identification_count)# other identification<cfif relationshipPairs.related_other_identification_count NEQ 1>s</cfif></span>
												</cfif>
											</td>
										</tr>
									</cfloop>
								</tbody>
							</table>
						</div>
						<div class="d-flex align-items-center gap-2 mt-2">
							<input type="submit" id="bulkSyncBtn" class="btn btn-primary" value="Add/Sync Accepted IDs for Selected Copy Actions" disabled>
							<span id="selectedCount" aria-live="polite" class="text-muted">0 actions selected</span>
						</div>
						<p class="mt-2 mb-0">Action adds a new accepted identification in the selected direction for each checked copy action. Determiner is recorded as the currently logged in user, date identified is set to today, and #encodeForHtml(variables.natureOfIdGuidance)#</p>
					</form>
					</cfoutput>
				<cfelse>
					<p>No eligible records were found for the selected relationship type. Hybrids are excluded.</p>
				</cfif>
			</div>
		</cfif>
	</section>
</main>

<cfinclude template="/shared/_footer.cfm">
