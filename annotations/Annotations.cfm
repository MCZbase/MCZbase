<!---
Annotations.cfm

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

Review annotations page.  Provides a filter form for browsing annotations
by specimen (collection / GUID), taxonomy (family), project, or publication,
and renders results with ajax-based review update controls.
--->
<cfset pageTitle = "Review Annotations">
<cfinclude template="/shared/_header.cfm">

<!--- Explicit URL scope declarations --->
<cfif isDefined("url.action")><cfset variables.action = url.action></cfif>
<cfif NOT isDefined("variables.action") OR len(variables.action) EQ 0><cfset variables.action = ""></cfif>

<cfif isDefined("url.type")><cfset variables.type = url.type></cfif>
<cfif NOT isDefined("variables.type") OR len(variables.type) EQ 0><cfset variables.type = ""></cfif>

<cfif isDefined("url.collection")><cfset variables.collection = url.collection></cfif>
<cfif NOT isDefined("variables.collection")><cfset variables.collection = ""></cfif>

<cfif isDefined("url.specimen_guid")><cfset variables.specimen_guid = trim(url.specimen_guid)></cfif>
<cfif NOT isDefined("variables.specimen_guid")><cfset variables.specimen_guid = ""></cfif>

<cfif isDefined("url.taxon_family")><cfset variables.taxon_family = url.taxon_family></cfif>
<cfif NOT isDefined("variables.taxon_family")><cfset variables.taxon_family = ""></cfif>

<cfif isDefined("url.taxon_name_id")><cfset variables.taxon_name_id = url.taxon_name_id></cfif>
<cfif NOT isDefined("variables.taxon_name_id")><cfset variables.taxon_name_id = ""></cfif>

<cfif isDefined("url.publication_id")><cfset variables.publication_id = url.publication_id></cfif>
<cfif NOT isDefined("variables.publication_id")><cfset variables.publication_id = ""></cfif>

<cfif isDefined("url.project_id")><cfset variables.project_id = url.project_id></cfif>
<cfif NOT isDefined("variables.project_id")><cfset variables.project_id = ""></cfif>

<!--- id parameter is used when linking directly to a specific specimen's annotations --->
<cfif isDefined("url.id")><cfset variables.id = url.id></cfif>
<cfif NOT isDefined("variables.id")><cfset variables.id = ""></cfif>

<!--- Data queries for filter picklists --->
<cfquery name="getCollections" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	SELECT collection cln FROM collection ORDER BY collection
</cfquery>

<cfquery name="getAnnotatedFamilies" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	SELECT DISTINCT taxonomy.family
	FROM annotations
	INNER JOIN taxonomy ON annotations.taxon_name_id = taxonomy.taxon_name_id
	WHERE taxonomy.family IS NOT NULL
	ORDER BY taxonomy.family
</cfquery>

<main class="container-fluid" id="content">
	<section role="search">
		<div class="row mx-0 mb-2">
			<div class="search-box col-12">
				<div class="search-box-header">
					<h1 class="h3 text-white">Review Annotations</h1>
				</div>
				<cfoutput>
				<div class="col-12 px-2 py-2">
					<div class="form-row">

						<!--- Specimens filter --->
						<div class="col-12 col-md-4 px-2 mb-2 border-right">
							<h2 class="h5 mb-2">Specimens</h2>
							<form id="filterSpecimens" method="get" action="/annotations/Annotations.cfm">
								<input type="hidden" name="action" value="show">
								<input type="hidden" name="type" value="collection_object_id">
								<div class="form-group mb-2">
									<label for="collection" class="data-entry-label">By Collection</label>
									<select name="collection" id="collection" class="data-entry-select col-12">
										<option value="">All Collections</option>
										<cfloop query="getCollections">
											<option value="#encodeForHTML(cln)#" <cfif variables.collection EQ cln>selected="selected"</cfif>>#encodeForHTML(cln)#</option>
										</cfloop>
									</select>
								</div>
								<div class="form-group mb-2">
									<label for="specimen_guid" class="data-entry-label">By Specimen GUID</label>
									<input type="text" name="specimen_guid" id="specimen_guid"
										value="#encodeForHTML(variables.specimen_guid)#"
										placeholder="e.g. MCZ:Herp:12345"
										class="data-entry-input col-12">
								</div>
								<button type="submit" class="btn btn-xs btn-primary">Filter</button>
								<a href="/annotations/Annotations.cfm" class="btn btn-xs btn-warning">Reset</a>
							</form>
						</div>

						<!--- Taxonomy filter --->
						<div class="col-12 col-md-4 px-2 mb-2 border-right">
							<h2 class="h5 mb-2">Taxonomy</h2>
							<form id="filterTaxonomy" method="get" action="/annotations/Annotations.cfm">
								<input type="hidden" name="action" value="show">
								<input type="hidden" name="type" value="taxon_name_id">
								<div class="form-group mb-2">
									<label for="taxon_family" class="data-entry-label">By Family</label>
									<select name="taxon_family" id="taxon_family" class="data-entry-select col-12">
										<option value="">All Annotated Families</option>
										<cfloop query="getAnnotatedFamilies">
											<option value="#encodeForHTML(family)#" <cfif variables.taxon_family EQ family>selected="selected"</cfif>>#encodeForHTML(family)#</option>
										</cfloop>
									</select>
								</div>
								<button type="submit" class="btn btn-xs btn-primary">Filter</button>
								<a href="/annotations/Annotations.cfm" class="btn btn-xs btn-warning">Reset</a>
							</form>
						</div>

						<!--- Other types filter --->
						<div class="col-12 col-md-4 px-2 mb-2">
							<h2 class="h5 mb-2">Other Types</h2>
							<form id="filterOther" method="get" action="/annotations/Annotations.cfm">
								<input type="hidden" name="action" value="show">
								<div class="form-group mb-2">
									<label for="otherType" class="data-entry-label">By Type</label>
									<select name="type" id="otherType" class="data-entry-select col-12">
										<option value="">Select a type</option>
										<option value="project_id" <cfif variables.type EQ "project_id">selected="selected"</cfif>>Project</option>
										<option value="publication_id" <cfif variables.type EQ "publication_id">selected="selected"</cfif>>Publication</option>
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

	<cfif variables.action EQ "show">
		<section class="row mx-0 mb-4">
			<div class="col-12">
				<cfoutput>

				<!--- ============================================================
				     Specimen annotations (type = collection_object_id)
				     ============================================================ --->
				<cfif variables.type EQ "collection_object_id">
					<cfquery name="ci" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
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
						WHERE 1=1
						<cfif len(variables.id) GT 0 AND isNumeric(variables.id)>
							AND annotations.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.id#">
						</cfif>
						<cfif len(variables.collection) GT 0>
							AND collection.collection = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.collection#">
						</cfif>
						<cfif len(variables.specimen_guid) GT 0>
							AND annotations.COLLECTION_OBJECT_ID IN (
								SELECT collection_object_id
								FROM #session.flatTableName#
								WHERE upper(guid) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(variables.specimen_guid)#">
							)
						</cfif>
					</cfquery>
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
						FROM ci
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
					<h2 class="h3 mt-3 pl-1">Specimen Annotations</h2>
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
									FROM ci WHERE collection_object_id = #val(collection_object_id)#
								</cfquery>
								<cfloop query="itemAnno">
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
										mask_annotation_fg="#mask_annotation_fg#">
									#annoRowHTML#
								</cfloop>
							</div>
						</cfloop>
					</cfif>

				<!--- ============================================================
				     Taxonomy annotations (type = taxon_name_id)
				     ============================================================ --->
				<cfelseif variables.type EQ "taxon_name_id">
					<cfquery name="tax" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
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
						WHERE 1=1
						<cfif len(variables.taxon_name_id) GT 0 AND isNumeric(variables.taxon_name_id)>
							AND annotations.taxon_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.taxon_name_id#">
						</cfif>
						<cfif len(variables.taxon_family) GT 0>
							AND upper(taxonomy.family) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(variables.taxon_family)#">
						</cfif>
					</cfquery>
					<cfquery name="t" dbtype="query">
						SELECT taxon_name_id, scientific_name, display_name
						FROM tax
						GROUP BY taxon_name_id, scientific_name, display_name
					</cfquery>
					<h2 class="h3 mt-3 pl-1">Taxonomic Annotations</h2>
					<cfif t.recordcount EQ 0>
						<p class="text-muted pl-1">No annotations found matching the selected filters.</p>
					<cfelse>
						<cfloop query="t">
							<div class="col-12 px-0 my-2 card border-bottom-0">
								<div class="card-header bg-box-header-gray">
									<h3 class="h4 mb-0">
										<a href="/name/#encodeForURL(scientific_name)#">#encodeForHTML(display_name)#</a>
									</h3>
								</div>
								<cfquery name="itemAnno" dbtype="query">
									SELECT
										ANNOTATION_ID, annotation_display, CF_USERNAME, email,
										ANNOTATE_DATE, motivation, reviewed_fg, reviewer,
										reviewer_comment, mask_annotation_fg
									FROM tax WHERE taxon_name_id = #val(taxon_name_id)#
								</cfquery>
								<cfloop query="itemAnno">
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
										mask_annotation_fg="#mask_annotation_fg#">
									#annoRowHTML#
								</cfloop>
							</div>
						</cfloop>
					</cfif>

				<!--- ============================================================
				     Publication annotations (type = publication_id)
				     ============================================================ --->
				<cfelseif variables.type EQ "publication_id">
					<cfquery name="tax" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
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
						WHERE 1=1
						<cfif len(variables.publication_id) GT 0 AND isNumeric(variables.publication_id)>
							AND annotations.publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.publication_id#">
						</cfif>
					</cfquery>
					<cfquery name="t" dbtype="query">
						SELECT publication_title, publication_id
						FROM tax
						GROUP BY publication_title, publication_id
					</cfquery>
					<h2 class="h3 mt-3 pl-1">Publication Annotations</h2>
					<cfif t.recordcount EQ 0>
						<p class="text-muted pl-1">No annotations found matching the selected filters.</p>
					<cfelse>
						<cfloop query="t">
							<div class="col-12 px-0 my-2 card border-bottom-0">
								<div class="card-header bg-box-header-gray">
									<h3 class="h4 mb-0">
										<a href="/publications/showPublication.cfm?publication_id=#encodeForURL(publication_id)#">#encodeForHTML(publication_title)#</a>
									</h3>
								</div>
								<cfquery name="itemAnno" dbtype="query">
									SELECT
										ANNOTATION_ID, annotation_display, CF_USERNAME, email,
										ANNOTATE_DATE, motivation, reviewed_fg, reviewer,
										reviewer_comment, mask_annotation_fg
									FROM tax WHERE publication_id = #val(publication_id)#
								</cfquery>
								<cfloop query="itemAnno">
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
										mask_annotation_fg="#mask_annotation_fg#">
									#annoRowHTML#
								</cfloop>
							</div>
						</cfloop>
					</cfif>

				<!--- ============================================================
				     Project annotations (type = project_id)
				     ============================================================ --->
				<cfelseif variables.type EQ "project_id">
					<cfquery name="tax" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
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
						WHERE 1=1
						<cfif len(variables.project_id) GT 0 AND isNumeric(variables.project_id)>
							AND annotations.project_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.project_id#">
						</cfif>
					</cfquery>
					<cfquery name="t" dbtype="query">
						SELECT project_name, project_id
						FROM tax
						GROUP BY project_name, project_id
					</cfquery>
					<h2 class="h3 mt-3 pl-1">Project Annotations</h2>
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
									FROM tax WHERE project_id = #val(project_id)#
								</cfquery>
								<cfloop query="itemAnno">
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
										mask_annotation_fg="#mask_annotation_fg#">
									#annoRowHTML#
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
	</cfif>

</main>
<cfinclude template="/shared/_footer.cfm">
