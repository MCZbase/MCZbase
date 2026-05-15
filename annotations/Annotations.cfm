<!---
annotations/Annotations.cfm

Review annotations page.  Provides a filter form for browsing annotations by target.

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

<!--- Explicit URL scope declarations --->

<cfif isDefined("url.type")><cfset variables.type = url.type></cfif>
<cfif NOT isDefined("variables.type") OR len(variables.type) EQ 0><cfset variables.type = ""></cfif>

<cfif isDefined("url.collection")><cfset variables.collection = url.collection></cfif>
<cfif NOT isDefined("variables.collection")><cfset variables.collection = ""></cfif>

<cfif isDefined("url.specimen_guid")><cfset variables.specimen_guid = trim(url.specimen_guid)></cfif>
<cfif NOT isDefined("variables.specimen_guid")><cfset variables.specimen_guid = ""></cfif>

<cfif isDefined("url.collection_object_id")>
	<cfset variables.collection_object_id = url.collection_object_id>
	<cfif len(variables.specimen_guid) EQ 0 AND isNumeric(variables.collection_object_id)>
		<!--- If a collection_object_id is provided but not a specimen_guid, attempt to look up the GUID --->
		<cfquery name="getGuidForCollectionObject" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			SELECT guid
			FROM #session.flatTableName#
			WHERE collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.collection_object_id#">
		</cfquery>
		<cfif getGuidForCollectionObject.recordcount EQ 1>
			<cfset variables.specimen_guid = getGuidForCollectionObject.guid>
		</cfif>
	</cfif>
</cfif>

<cfif isDefined("url.taxon_family")><cfset variables.taxon_family = url.taxon_family></cfif>
<cfif NOT isDefined("variables.taxon_family")><cfset variables.taxon_family = ""></cfif>

<cfif isDefined("url.scientific_name")><cfset variables.scientific_name = url.scientific_name></cfif>
<cfif NOT isDefined("variables.scientific_name")><cfset variables.scientific_name = ""></cfif>

<cfif isDefined("url.taxon_name_id")><cfset variables.taxon_name_id = url.taxon_name_id></cfif>
<cfif NOT isDefined("variables.taxon_name_id")><cfset variables.taxon_name_id = ""></cfif>

<cfif isDefined("url.publication_id")><cfset variables.publication_id = url.publication_id></cfif>
<cfif NOT isDefined("variables.publication_id")><cfset variables.publication_id = ""></cfif>

<cfif isDefined("url.project_id")><cfset variables.project_id = url.project_id></cfif>
<cfif NOT isDefined("variables.project_id")><cfset variables.project_id = ""></cfif>

<!--- id parameter is used when linking directly to a specific specimen's annotations --->
<cfif isDefined("url.id")><cfset variables.id = url.id></cfif>
<cfif NOT isDefined("variables.id")><cfset variables.id = ""></cfif>

<cfset annotationFunctions = CreateObject("component","annotations.component.functions")>

<!--- Data queries for filter picklists --->
<cfquery name="getAnnotatedCollections" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	SELECT 
      count(annotation_id) as ct, collection.collection
   FROM collection 
      JOIN cataloged_item ON collection.collection_id = cataloged_item.collection_id
      JOIN annotations ON cataloged_item.collection_object_id = annotations.collection_object_id
   GROUP BY collection.collection
   ORDER BY collection
</cfquery>

<cfquery name="getAnnotatedFamilies" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	SELECT count(annotation_id) as ct, taxonomy.family
	FROM annotations
		INNER JOIN taxonomy ON annotations.taxon_name_id = taxonomy.taxon_name_id
	WHERE taxonomy.family IS NOT NULL
   GROUP BY taxonomy.family
	ORDER BY taxonomy.family
</cfquery>
<main class="container-fluid" id="content">
	<section role="search">
		<div class="row mx-0 mb-2">
			<div class="search-box col-12 px-0">
				<div class="search-box-header">
					<h1 class="h3 text-white">Review Annotations</h1>
				</div>
				<cfoutput>
				<div class="col-12 px-2 py-2">
					<div class="form-row">

						<!--- Specimens filter --->
						<div class="col-12 col-md-4 px-2 mb-2 border-right">
							<h2 class="h5 mb-2">Annotations on Specimens</h2>
							<form id="filterSpecimens" method="get" action="/annotations/Annotations.cfm">
								<input type="hidden" name="type" value="collection_object_id">
								<div class="form-group mb-2">
									<label for="collection" class="data-entry-label">By Collection</label>
									<select name="collection" id="collection" class="data-entry-select col-12">
										<option value="">All Collections</option>
										<cfloop query="getAnnotatedCollections">
											<cfif variables.collection EQ getAnnotatedCollections.collection><cfset selected="selected='selected'"><cfelse><cfset selected=""></cfif>
											<option value="#encodeForHTML(getAnnotatedCollections.collection)#" #selected#>#encodeForHTML(getAnnotatedCollections.collection)# (#getAnnotatedCollections.ct#)</option>
										</cfloop>
									</select>
									<script>
										$(document).ready(function() {
											$("##collection").change(function() {
												$("##specimen_guid").val("");
											});
										});
									</script>
								</div>
								<div class="form-group mb-2">
									<label for="specimen_guid" class="data-entry-label">By Specimen GUID</label>
									<input type="text" name="specimen_guid" id="specimen_guid"
										value="#encodeForHTML(variables.specimen_guid)#"
										placeholder="e.g. MCZ:Herp:A-12345"
										class="data-entry-input col-12">
								</div>
								<button type="submit" class="btn btn-xs btn-primary">Filter</button>
								<a href="/annotations/Annotations.cfm" class="btn btn-xs btn-warning">Reset</a>
							</form>
						</div>

						<!--- Taxonomy filter --->
						<div class="col-12 col-md-4 px-2 mb-2 border-right">
							<h2 class="h5 mb-2">Annotations on Taxon Records</h2>
							<form id="filterTaxonomy" method="get" action="/annotations/Annotations.cfm">
								<input type="hidden" name="type" value="taxon_name_id">
								<div class="form-group mb-2">
									<label for="taxon_family" class="data-entry-label">By Family</label>
									<select name="taxon_family" id="taxon_family" class="data-entry-select col-12">
										<option value="">All Annotated Families</option>
										<cfloop query="getAnnotatedFamilies">
											<cfif variables.taxon_family EQ getAnnotatedFamilies.family><cfset selected="selected='selected'"><cfelse><cfset selected=""></cfif>
											<option value="#encodeForHTML(family)#" #selected#>#encodeForHTML(family)# (#getAnnotatedFamilies.ct#)</option>
										</cfloop>
									</select>
									<script>
										$(document).ready(function() {
											$("##taxon_family").change(function() {
												$("##scientific_name").val("");
											});
										});
									</script>
								</div>
								<div class="form-group mb-2">
									<label for="scientific_name" class="data-entry-label">By any part of Scientific Name</label>
									<input type="text" name="scientific_name" id="scientific_name"
										value="#encodeForHTML(variables.scientific_name)#"
										class="data-entry-input col-12">
								</div>
								<button type="submit" class="btn btn-xs btn-primary">Filter</button>
								<a href="/annotations/Annotations.cfm" class="btn btn-xs btn-warning">Reset</a>
							</form>
						</div>

						<!--- Other types filter --->
						<cfquery name="countProjectAnnotations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							SELECT COUNT(DISTINCT project_id) AS ct
							FROM annotations
							WHERE project_id IS NOT NULL
						</cfquery>
						<cfquery name="countPublicationAnnotations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							SELECT COUNT(DISTINCT publication_id) AS ct
							FROM annotations
							WHERE publication_id IS NOT NULL
						</cfquery>
						<div class="col-12 col-md-4 px-2 mb-2">
							<h2 class="h5 mb-2">Other Annotation Targets</h2>
							<form id="filterOther" method="get" action="/annotations/Annotations.cfm">
								<div class="form-group mb-2">
									<label for="otherType" class="data-entry-label">By Type</label>
									<select name="type" id="otherType" class="data-entry-select col-12">
										<option value="">Select a type</option>
										<cfif variables.type EQ "project_id"><cfset selected="selected='selected'"><cfelse><cfset selected=""></cfif>
										<option value="project_id" #selected#>Project (#countProjectAnnotations.ct#)</option>
										<cfif variables.type EQ "publication_id"><cfset selected="selected='selected'"><cfelse><cfset selected=""></cfif>
										<option value="publication_id" #selected#>Publication (#countPublicationAnnotations.ct#)</option>
									</select>
								</div>
								<button type="submit" class="btn btn-xs btn-primary">Filter</button>
								<a href="/annotations/Annotations.cfm" class="btn btn-xs btn-warning">Reset</a>
							</form>
						</div>

					</div>
				</div>
				</cfoutput>
			</div>
		</div>
	</section>

	<section class="row mx-0 mb-4">
		<div class="col-12">
			<cfoutput>

			<!--- ============================================================
			     Specimen annotations (type = collection_object_id)
			     ============================================================ --->
			<cfif variables.type EQ "collection_object_id">
				<cfquery name="getSpecimenAnnotations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT
						annotations.ANNOTATION_ID,
						annotations.ANNOTATE_DATE,
						annotations.CF_USERNAME,
						annotations.COLLECTION_OBJECT_ID,
						annotations.annotation,
						NVL(atb.body_value, annotations.annotation) annotation_display,
						annotations.reviewer_agent_id,
						preferred_agent_name.agent_name reviewer,
						annotations.reviewed_fg,
						annotations.reviewer_comment,
						annotations.motivation,
						annotations.mask_annotation_fg,
						collection.collection,
						collection.collection_cde,
						collection.institution_acronym,
						cataloged_item.cat_num,
						identification.scientific_name idAs,
						geog_auth_rec.higher_geog,
						locality.spec_locality,
						cf_user_data.email
					FROM
						annotations
						INNER JOIN cataloged_item ON annotations.COLLECTION_OBJECT_ID = cataloged_item.COLLECTION_OBJECT_ID
						INNER JOIN collection ON cataloged_item.collection_id = collection.collection_id
						INNER JOIN identification ON cataloged_item.collection_object_id = identification.collection_object_id AND identification.accepted_id_fg = 1
						INNER JOIN collecting_event ON cataloged_item.collecting_event_id = collecting_event.collecting_event_id
						INNER JOIN locality ON collecting_event.locality_id = locality.locality_id
						INNER JOIN geog_auth_rec ON locality.geog_auth_rec_id = geog_auth_rec.geog_auth_rec_id
						LEFT OUTER JOIN cf_users ON annotations.CF_USERNAME = cf_users.username
						LEFT OUTER JOIN cf_user_data ON cf_users.user_id = cf_user_data.user_id
						LEFT OUTER JOIN preferred_agent_name ON annotations.reviewer_agent_id = preferred_agent_name.agent_id
						LEFT OUTER JOIN (
							SELECT annotation_id, body_value,
								ROW_NUMBER() OVER (PARTITION BY annotation_id ORDER BY created_date) rn
							FROM annotation_textualbody
						) atb ON annotations.annotation_id = atb.annotation_id AND atb.rn = 1
					WHERE upper(annotations.target_table) = 'COLLECTION_OBJECT'
						<cfif isDefined("variables.id") AND len(variables.id) GT 0>
							AND annotations.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.id#">
						</cfif>
						<cfif len(variables.collection) GT 0>
							AND collection.collection = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.collection#">
						</cfif>
						<cfif len(variables.specimen_guid) GT 0>
							AND annotations.COLLECTION_OBJECT_ID IN (
								SELECT collection_object_id
								FROM #session.flatTableName#
								<cfif variables.specimen_guid contains ",">
									WHERE guid IN (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.specimen_guid#" list="yes">)
								<cfelseif variables.specimen_guid contains "%" OR variables.specimen_guid contains "_">
									WHERE guid LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.specimen_guid#">
								<cfelse>
									WHERE upper(guid) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(variables.specimen_guid)#">
								</cfif>
							)
						</cfif>
				</cfquery>
				<cfset specimenChildAnno = annotationFunctions.getChildAnnotationsForRoots(valueList(getSpecimenAnnotations.annotation_id))>
				<cfquery name="catitem" dbtype="query">
					SELECT
						COLLECTION_OBJECT_ID,
						collection,
						collection_cde,
						institution_acronym,
						cat_num,
						idAs,
						higher_geog,
						spec_locality
					FROM getSpecimenAnnotations
					GROUP BY
						COLLECTION_OBJECT_ID,
						collection,
						collection_cde,
						institution_acronym,
						cat_num,
						idAs,
						higher_geog,
						spec_locality
				</cfquery>
				<cfset plural = "s">
				<cfif catitem.recordcount EQ 1><cfset plural = ""></cfif>
				<h2 class="h3 mt-3 pl-1">Specimen Annotations (#catitem.recordcount# specimen#plural#)</h2>
				<cfif catitem.recordcount EQ 0>
					<p class="text-muted pl-1">No annotations found matching the selected filters.</p>
				<cfelse>
					<cfloop query="catitem">
						<cfset specimenGuid = "#institution_acronym#:#collection_cde#:#cat_num#">
						<div class="col-12 px-0 my-2 card border-bottom-0">
							<div class="card-header bg-box-header-gray">
								<h3 class="h4 mb-0">
									<a href="/guid/#specimenGuid#" target="_blank">#encodeForHTML(specimenGuid)#</a>
									<span class="mx-2 small">&nbsp;Current Identification: <em>#encodeForHTML(idAs)#</em></span>
									<span class="ml-1 small">Locality: #encodeForHTML(higher_geog)#: #encodeForHTML(spec_locality)#</span>
								</h3>
							</div>
							<cfquery name="itemAnno" dbtype="query">
								SELECT
									ANNOTATION_ID, annotation_display, CF_USERNAME, email,
									ANNOTATE_DATE, motivation, reviewed_fg, reviewer,
									reviewer_comment, mask_annotation_fg
								FROM getSpecimenAnnotations 
								WHERE collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#val(collection_object_id)#">
							</cfquery>
							<cfloop query="itemAnno">
								<div id="annotation-block-#annotation_id#">
								<cfinvoke component="/annotations/component/functions" method="renderAnnotationReviewRow" returnvariable="annoRowHTML"
									annotation_id="#annotation_id#"
									annotation_display="#annotation_display#"
									cf_username="#CF_USERNAME#"
									email="#email#"
									annotate_date="#ANNOTATE_DATE#"
									motivation="#motivation#"
									reviewed_fg="#reviewed_fg#"
									reviewer="#reviewer#"
									reviewer_comment="#reviewer_comment#"
									mask_annotation_fg="#mask_annotation_fg#"
									show_reply_action="true">
								#annoRowHTML#
								#annotationFunctions.renderAnnotationConversationSection(rootAnnotationId=annotation_id, childAnnotations=specimenChildAnno)#
								</div>
							</cfloop>
						</div>
					</cfloop>
				</cfif>

			<!--- ============================================================
			     Taxonomy annotations (type = taxon_name_id)
			     ============================================================ --->
			<cfelseif variables.type EQ "taxon_name_id">
				<cfquery name="getTaxonAnnotations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT
						taxonomy.scientific_name,
						taxonomy.display_name,
						taxonomy.family,
						annotations.ANNOTATION_ID,
						annotations.ANNOTATE_DATE,
						annotations.CF_USERNAME,
						annotations.annotation,
						NVL(atb.body_value, annotations.annotation) annotation_display,
						annotations.reviewer_agent_id,
						preferred_agent_name.agent_name reviewer,
						annotations.reviewed_fg,
						annotations.reviewer_comment,
						annotations.motivation,
						annotations.mask_annotation_fg,
						cf_user_data.email,
						annotations.taxon_name_id
					FROM
						annotations
						INNER JOIN taxonomy ON annotations.taxon_name_id = taxonomy.taxon_name_id
						LEFT OUTER JOIN cf_users ON annotations.CF_USERNAME = cf_users.username
						LEFT OUTER JOIN cf_user_data ON cf_users.user_id = cf_user_data.user_id
						LEFT OUTER JOIN preferred_agent_name ON annotations.reviewer_agent_id = preferred_agent_name.agent_id
						LEFT OUTER JOIN (
							SELECT annotation_id, body_value,
								ROW_NUMBER() OVER (PARTITION BY annotation_id ORDER BY created_date) rn
							FROM annotation_textualbody
						) atb ON annotations.annotation_id = atb.annotation_id AND atb.rn = 1
					WHERE upper(annotations.target_table) = 'TAXON_NAME'
						<cfif isDefined("variables.taxon_name_id") AND len(variables.taxon_name_id) GT 0>
							AND annotations.taxon_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.taxon_name_id#">
						</cfif>
						<cfif len(variables.taxon_family) GT 0>
							AND upper(taxonomy.family) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(variables.taxon_family)#">
						</cfif>
						<cfif len(variables.scientific_name) GT 0>
							AND upper(taxonomy.scientific_name) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(variables.scientific_name)#%">
						</cfif>
				</cfquery>
				<cfset taxonChildAnno = annotationFunctions.getChildAnnotationsForRoots(valueList(getTaxonAnnotations.annotation_id))>
				<cfquery name="t" dbtype="query">
					SELECT taxon_name_id, scientific_name, display_name
					FROM getTaxonAnnotations
					GROUP BY taxon_name_id, scientific_name, display_name
				</cfquery>
				<cfset taxaword = "taxa">
				<cfif t.recordcount EQ 1><cfset taxaword = "taxon"></cfif>
				<h2 class="h3 mt-3 pl-1">Taxonomic Annotations (#t.recordcount# #taxaword#)</h2>
				<cfif t.recordcount EQ 0>
					<p class="text-muted pl-1">No annotations found matching the selected filters.</p>
				<cfelse>
					<cfloop query="t">
						<div class="col-12 px-0 my-2 card border-bottom-0">
							<div class="card-header bg-box-header-gray">
								<h3 class="h4 mb-0">
									<a href="/name/#encodeForURL(scientific_name)#">#display_name#</a>
								</h3>
							</div>
							<cfquery name="itemAnno" dbtype="query">
								SELECT
									ANNOTATION_ID, annotation_display, CF_USERNAME, email,
									ANNOTATE_DATE, motivation, reviewed_fg, reviewer,
									reviewer_comment, mask_annotation_fg
								FROM getTaxonAnnotations 
								WHERE taxon_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#val(taxon_name_id)#">
							</cfquery>
							<cfloop query="itemAnno">
								<div id="annotation-block-#annotation_id#">
								<cfinvoke component="/annotations/component/functions" method="renderAnnotationReviewRow" returnvariable="annoRowHTML"
									annotation_id="#annotation_id#"
									annotation_display="#annotation_display#"
									cf_username="#CF_USERNAME#"
									email="#email#"
									annotate_date="#ANNOTATE_DATE#"
									motivation="#motivation#"
									reviewed_fg="#reviewed_fg#"
									reviewer="#reviewer#"
									reviewer_comment="#reviewer_comment#"
									mask_annotation_fg="#mask_annotation_fg#"
									show_reply_action="true">
								#annoRowHTML#
								#annotationFunctions.renderAnnotationConversationSection(rootAnnotationId=annotation_id, childAnnotations=taxonChildAnno)#
								</div>
							</cfloop>
						</div>
					</cfloop>
				</cfif>

			<!--- ============================================================
			     Publication annotations (type = publication_id)
			     ============================================================ --->
			<cfelseif variables.type EQ "publication_id">
				<cfquery name="getPubAnnotations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT
						publication.publication_title,
						annotations.ANNOTATION_ID,
						annotations.ANNOTATE_DATE,
						annotations.CF_USERNAME,
						annotations.annotation,
						NVL(atb.body_value, annotations.annotation) annotation_display,
						annotations.reviewer_agent_id,
						preferred_agent_name.agent_name reviewer,
						annotations.reviewed_fg,
						annotations.reviewer_comment,
						annotations.motivation,
						annotations.mask_annotation_fg,
						cf_user_data.email,
						annotations.publication_id
					FROM
						annotations
						INNER JOIN publication ON annotations.publication_id = publication.publication_id
						LEFT OUTER JOIN cf_users ON annotations.CF_USERNAME = cf_users.username
						LEFT OUTER JOIN cf_user_data ON cf_users.user_id = cf_user_data.user_id
						LEFT OUTER JOIN preferred_agent_name ON annotations.reviewer_agent_id = preferred_agent_name.agent_id
						LEFT OUTER JOIN (
							SELECT annotation_id, body_value,
								ROW_NUMBER() OVER (PARTITION BY annotation_id ORDER BY created_date) rn
							FROM annotation_textualbody
						) atb ON annotations.annotation_id = atb.annotation_id AND atb.rn = 1
					WHERE upper(annotations.target_table) = 'PUBLICATION'
						<cfif isDefined("variables.publication_id") AND len(variables.publication_id) GT 0>
							AND annotations.publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.publication_id#">
						</cfif>
				</cfquery>
				<cfset publicationChildAnno = annotationFunctions.getChildAnnotationsForRoots(valueList(getPubAnnotations.annotation_id))>
				<cfquery name="getPublicationAnnotations" dbtype="query">
					SELECT publication_title, publication_id
					FROM getPubAnnotations
					GROUP BY publication_title, publication_id
				</cfquery>
				<cfset plural = "s">
				<cfif getPublicationAnnotations.recordcount EQ 1><cfset plural = ""></cfif>
				<h2 class="h3 mt-3 pl-1">Publication Annotations (#getPublicationAnnotations.recordcount# publication#plural#)</h2>
				<cfif getPublicationAnnotations.recordcount EQ 0>
					<p class="text-muted pl-1">No annotations found matching the selected filters.</p>
				<cfelse>
					<cfloop query="getPublicationAnnotations">
						<div class="col-12 px-0 my-2 card border-bottom-0">
							<div class="card-header bg-box-header-gray">
								<h3 class="h4 mb-0">
									<a href="/publications/showPublication.cfm?publication_id=#encodeForURL(publication_id)#">#publication_title#</a>
								</h3>
							</div>
							<cfquery name="itemAnno" dbtype="query">
								SELECT
									ANNOTATION_ID, annotation_display, CF_USERNAME, email,
									ANNOTATE_DATE, motivation, reviewed_fg, reviewer,
									reviewer_comment, mask_annotation_fg
								FROM getPubAnnotations 
								WHERE publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#val(publication_id)#">
							</cfquery>
							<cfloop query="itemAnno">
								<div id="annotation-block-#annotation_id#">
								<cfinvoke component="/annotations/component/functions" method="renderAnnotationReviewRow" returnvariable="annoRowHTML"
									annotation_id="#annotation_id#"
									annotation_display="#annotation_display#"
									cf_username="#CF_USERNAME#"
									email="#email#"
									annotate_date="#ANNOTATE_DATE#"
									motivation="#motivation#"
									reviewed_fg="#reviewed_fg#"
									reviewer="#reviewer#"
									reviewer_comment="#reviewer_comment#"
									mask_annotation_fg="#mask_annotation_fg#"
									show_reply_action="true">
								#annoRowHTML#
								#annotationFunctions.renderAnnotationConversationSection(rootAnnotationId=annotation_id, childAnnotations=publicationChildAnno)#
								</div>
							</cfloop>
						</div>
					</cfloop>
				</cfif>

			<!--- ============================================================
			     Project annotations (type = project_id)
			     ============================================================ --->
			<cfelseif variables.type EQ "project_id">
				<cfquery name="getProjectAnnotations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT
						project.project_name,
						annotations.ANNOTATION_ID,
						annotations.ANNOTATE_DATE,
						annotations.CF_USERNAME,
						annotations.annotation,
						NVL(atb.body_value, annotations.annotation) annotation_display,
						annotations.reviewer_agent_id,
						preferred_agent_name.agent_name reviewer,
						annotations.reviewed_fg,
						annotations.reviewer_comment,
						annotations.motivation,
						annotations.mask_annotation_fg,
						cf_user_data.email,
						annotations.project_id
					FROM
						annotations
						INNER JOIN project ON annotations.project_id = project.project_id
						LEFT OUTER JOIN cf_users ON annotations.CF_USERNAME = cf_users.username
						LEFT OUTER JOIN cf_user_data ON cf_users.user_id = cf_user_data.user_id
						LEFT OUTER JOIN preferred_agent_name ON annotations.reviewer_agent_id = preferred_agent_name.agent_id
						LEFT OUTER JOIN (
							SELECT annotation_id, body_value,
								ROW_NUMBER() OVER (PARTITION BY annotation_id ORDER BY created_date) rn
							FROM annotation_textualbody
						) atb ON annotations.annotation_id = atb.annotation_id AND atb.rn = 1
					WHERE upper(annotations.target_table) = 'PROJECT'
						<cfif isDefined("variables.project_id") AND len(variables.project_id) GT 0>
							AND annotations.project_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.project_id#">
						</cfif>
				</cfquery>
				<cfset projectChildAnno = annotationFunctions.getChildAnnotationsForRoots(valueList(getProjectAnnotations.annotation_id))>
				<cfquery name="t" dbtype="query">
					SELECT project_name, project_id
					FROM getProjectAnnotations
					GROUP BY project_name, project_id
				</cfquery>
				<cfset plural = "s">
				<cfif t.recordcount EQ 1><cfset plural = ""></cfif>
				<h2 class="h3 mt-3 pl-1">Project Annotations (#t.recordcount# project#plural#)</h2>
				<cfif t.recordcount EQ 0>
					<p class="text-muted pl-1">No annotations found matching the selected filters.</p>
				<cfelse>
					<cfloop query="t">
						<div class="col-12 px-0 my-2 card border-bottom-0">
							<div class="card-header bg-box-header-gray">
								<h3 class="h4 mb-0">
									<a href="/ProjectDetail?project_id=#encodeForURL(project_id)#">#encodeForHTML(project_name)#</a>
								</h3>
							</div>
							<cfquery name="itemAnno" dbtype="query">
								SELECT
									ANNOTATION_ID, annotation_display, CF_USERNAME, email,
									ANNOTATE_DATE, motivation, reviewed_fg, reviewer,
									reviewer_comment, mask_annotation_fg
								FROM getProjectAnnotations 
								WHERE project_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#val(project_id)#">
							</cfquery>
							<cfloop query="itemAnno">
								<div id="annotation-block-#annotation_id#">
								<cfinvoke component="/annotations/component/functions" method="renderAnnotationReviewRow" returnvariable="annoRowHTML"
									annotation_id="#annotation_id#"
									annotation_display="#annotation_display#"
									cf_username="#CF_USERNAME#"
									email="#email#"
									annotate_date="#ANNOTATE_DATE#"
									motivation="#motivation#"
									reviewed_fg="#reviewed_fg#"
									reviewer="#reviewer#"
									reviewer_comment="#reviewer_comment#"
									mask_annotation_fg="#mask_annotation_fg#"
									show_reply_action="true">
								#annoRowHTML#
								#annotationFunctions.renderAnnotationConversationSection(rootAnnotationId=annotation_id, childAnnotations=projectChildAnno)#
								</div>
							</cfloop>
						</div>
					</cfloop>
				</cfif>

			<cfelse>
				<p class="mt-3 text-muted pl-1">Please select a filter above and click Filter to view annotations.</p>
			</cfif>

			</cfoutput>
		</div>
	</section>
</main>
<cfinclude template="/shared/_footer.cfm">
