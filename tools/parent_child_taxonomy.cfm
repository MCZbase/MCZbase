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
<cfparam name="form.selected_pair" default="">

<cfset variables.allowedRelationships = "parent of,embryo of,offspring of,littermate of,sibling of,egg of,same individual organism as,part to counterpart,cast of">
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
		collection = 'All'
		AND (
			lower(biol_indiv_relationship) IN (
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" list="yes" value="#variables.allowedRelationships#">
			)
			OR lower(inverse_relation) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="parent of">
		)
	ORDER BY
		biol_indiv_relationship
</cfquery>

<cfset variables.relationshipOptions = "">
<cfloop query="ctRelationships">
	<cfif listFindNoCase(variables.allowedRelationships, ctRelationships.biol_indiv_relationship) AND NOT listFindNoCase(variables.relationshipOptions, ctRelationships.biol_indiv_relationship)>
		<cfset variables.relationshipOptions = listAppend(variables.relationshipOptions, lcase(ctRelationships.biol_indiv_relationship))>
	</cfif>
</cfloop>
<cfif len(variables.relationshipOptions) EQ 0>
	<cfset variables.relationshipOptions = variables.allowedRelationships>
</cfif>

<cfif NOT listFindNoCase(variables.relationshipOptions, variables.relationshipType)>
	<cfset variables.invalidRelationship = true>
	<cfset variables.relationshipType = "parent of">
</cfif>

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

<cfif variables.action EQ "syncSelected">
	<cfif len(trim(form.selected_pair)) EQ 0>
		<cfset variables.statusClass = "text-warning">
		<cfset variables.statusMessage = "No rows were selected. Select one or more rows to add/sync accepted identifications.">
	<cfelse>
		<cfloop list="#form.selected_pair#" index="variables.selectedPair">
			<cfset variables.attemptedCount = variables.attemptedCount + 1>
			<cfset variables.sourceCollectionObjectId = listFirst(variables.selectedPair, ":")>
			<cfset variables.relatedCollectionObjectId = listLast(variables.selectedPair, ":")>
			<cfif NOT isValid("integer", variables.sourceCollectionObjectId) OR NOT isValid("integer", variables.relatedCollectionObjectId)>
				<cfset variables.invalidCount = variables.invalidCount + 1>
			<cfelse>
				<cftransaction>
					<cfquery name="getSourceIdentification" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						SELECT
							sourceId.identification_id,
							sourceId.taxa_formula,
							sourceId.scientific_name
						FROM
							biol_indiv_relations bir
							JOIN identification sourceId ON bir.collection_object_id = sourceId.collection_object_id
							JOIN identification relatedId ON bir.related_coll_object_id = relatedId.collection_object_id
						WHERE
							bir.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.sourceCollectionObjectId#">
							AND bir.related_coll_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.relatedCollectionObjectId#">
							AND lower(bir.biol_indiv_relationship) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.relationshipType#">
							AND sourceId.accepted_id_fg = 1
							AND relatedId.accepted_id_fg = 1
							AND sourceId.scientific_name <> relatedId.scientific_name
							AND nvl(sourceId.taxa_formula,'A') <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="A x B">
							AND nvl(relatedId.taxa_formula,'A') <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="A x B">
					</cfquery>
					<cfif getSourceIdentification.recordcount EQ 1>
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
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="ID of kin">,
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
					<cfelse>
						<cfset variables.skippedCount = variables.skippedCount + 1>
					</cfif>
				</cftransaction>
			</cfif>
		</cfloop>
		<cfset variables.statusClass = "text-info">
		<cfset variables.statusMessage = "Processed #variables.attemptedCount# row(s): #variables.updatedCount# updated, #variables.skippedCount# skipped, #variables.invalidCount# invalid selections.">
	</cfif>
</cfif>

<cfif variables.shouldQuery>
	<cfquery name="relationshipPairs" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		WITH identificationCounts AS (
			SELECT
				collection_object_id,
				count(*) AS total_identification_count
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
			greatest(nvl(sourceIdCount.total_identification_count, 0) - 1, 0) AS source_other_identification_count,
			greatest(nvl(relatedIdCount.total_identification_count, 0) - 1, 0) AS related_other_identification_count,
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

<main class="container-fluid py-3 px-xl-5" id="content">
	<section class="row">
		<div class="col-12">
			<h1 class="h2">Relationship Taxonomy Consistency Checks and Sync</h1>
			<p class="mb-1">This tool lists cataloged item pairs linked by one biological relationship type at a time where both items are expected to have the same taxon identification.</p>
			<p class="mb-1">Use this to examine accepted identifications and add/sync accepted IDs from the listed relationship source item to the related item.</p>
			<p class="text-warning mb-3">Hybrid taxa (taxon formula <em>A x B</em>) are excluded from this actionable list.</p>
		</div>
	</section>

	<section class="row" aria-labelledby="relationshipFiltersHeading">
		<div class="col-12">
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
			<h2 class="h4" id="resultsHeading">Actionable relationship records</h2>
			<cfoutput>
			<output id="statusMessage" class="#encodeForHtmlAttribute(variables.statusClass)#" aria-live="polite">#encodeForHtml(variables.statusMessage)#</output>
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
										<th scope="col"><label for="selectAllRows" class="mb-0">Select</label><br><input type="checkbox" id="selectAllRows"></th>
										<th scope="col">Relationship Source Item</th>
										<th scope="col">Source Accepted Identification</th>
										<th scope="col">Related Item</th>
										<th scope="col">Related Accepted Identification</th>
									</tr>
								</thead>
								<tbody>
									<cfloop query="relationshipPairs">
										<cfset variables.rowValue = "#relationshipPairs.collection_object_id#:#relationshipPairs.related_coll_object_id#">
										<tr>
											<td>
												<input type="checkbox" class="relationship-row-check" name="selected_pair" value="#encodeForHtmlAttribute(variables.rowValue)#" aria-label="Select row for #encodeForHtmlAttribute(variables.rowValue)#">
											</td>
											<td>
												<a href="/specimens/Specimen.cfm?collection_object_id=#encodeForUrl(relationshipPairs.collection_object_id)#">#encodeForHtml(relationshipPairs.source_institution_acronym)# #encodeForHtml(relationshipPairs.source_collection_cde)# #encodeForHtml(relationshipPairs.source_cat_num)#</a>
												<cfif len(trim(relationshipPairs.source_custom_id)) GT 0>
													<br><span class="small">#encodeForHtml(session.CustomOtherIdentifier)# = #encodeForHtml(relationshipPairs.source_custom_id)#</span>
												</cfif>
											</td>
											<td>
												#encodeForHtml(relationshipPairs.source_scientific_name)#
												<br><span class="small text-muted">Determiner: #encodeForHtml(relationshipPairs.source_determiner)#</span>
												<br><span class="small text-muted">Date identified: <cfif len(trim(relationshipPairs.source_identification_date)) GT 0>#dateFormat(relationshipPairs.source_identification_date, 'yyyy-mm-dd')#<cfelse>[no date]</cfif></span>
												<br><span class="small text-muted">Type of identification: #encodeForHtml(relationshipPairs.source_identification_type)#</span>
												<br><span class="small text-muted">#encodeForHtml(relationshipPairs.source_other_identification_count)# other identification<cfif relationshipPairs.source_other_identification_count NEQ 1>s</cfif></span>
											</td>
											<td>
												<a href="/specimens/Specimen.cfm?collection_object_id=#encodeForUrl(relationshipPairs.related_coll_object_id)#">#encodeForHtml(relationshipPairs.related_institution_acronym)# #encodeForHtml(relationshipPairs.related_collection_cde)# #encodeForHtml(relationshipPairs.related_cat_num)#</a>
												<cfif len(trim(relationshipPairs.related_custom_id)) GT 0>
													<br><span class="small">#encodeForHtml(session.CustomOtherIdentifier)# = #encodeForHtml(relationshipPairs.related_custom_id)#</span>
												</cfif>
											</td>
											<td>
												#encodeForHtml(relationshipPairs.related_scientific_name)#
												<br><span class="small text-muted">Determiner: #encodeForHtml(relationshipPairs.related_determiner)#</span>
												<br><span class="small text-muted">Date identified: <cfif len(trim(relationshipPairs.related_identification_date)) GT 0>#dateFormat(relationshipPairs.related_identification_date, 'yyyy-mm-dd')#<cfelse>[no date]</cfif></span>
												<br><span class="small text-muted">Type of identification: #encodeForHtml(relationshipPairs.related_identification_type)#</span>
												<br><span class="small text-muted">#encodeForHtml(relationshipPairs.related_other_identification_count)# other identification<cfif relationshipPairs.related_other_identification_count NEQ 1>s</cfif></span>
											</td>
										</tr>
									</cfloop>
								</tbody>
							</table>
						</div>
						<div class="d-flex align-items-center gap-2 mt-2">
							<input type="submit" id="bulkSyncBtn" class="btn btn-primary" value="Add/Sync Accepted IDs for Selected Rows" disabled>
							<span id="selectedCount" aria-live="polite" class="small text-muted">0 selected</span>
						</div>
						<p class="small mt-2 mb-0">Action updates related items by adding a new accepted identification copied from the selected relationship source item.</p>
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
