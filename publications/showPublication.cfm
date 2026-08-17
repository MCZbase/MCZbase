<!---
publications/showPublication.cfm

Copyright 2022 President and Fellows of Harvard College

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
<cfparam name="url.publication_id" default="">

<cfset shortCitation = "">
<cfif len(url.publication_id) GT 0 and isNumeric(url.publication_id)>
	<cfquery name="lookupShort" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		SELECT
			formatted_publication as citation
		FROM
			formatted_publication
		WHERE
			publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#url.publication_id#">
			and format_style = 'short'
	</cfquery>
	<cfif lookupShort.recordcount EQ 1>
		<cfset shortCitation = ": #lookupShort.citation#">
	</cfif>
</cfif>
<cfset pageTitle = "#shortCitation# | Publication Details">
<cfinclude template = "/shared/_header.cfm">
<cfinclude template="/media/component/public.cfc" runOnce="true"><!--- for getMediaBlockHtml() --->
<cfinclude template="/shared/component/functions.cfc" runOnce="true"><!--- for getGuidLink() --->
<cfinclude template="/annotations/component/public.cfc" runOnce="true"><!--- for getPublicationAnnotationCardBodyHtml() --->

<cfset canManagePublications = false>
<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_publications")>
	<cfset canManagePublications = true>
</cfif>

<main class="container py-3" id="content">

	<cftry>
		<cfif len(url.publication_id) EQ 0 OR NOT isnumeric(url.publication_id)>
			<cfthrow message="No publication_id provided">
		</cfif>
		<cfquery name="check" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="check_result">
			select count(*) ct
			from publication
			where publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#url.publication_id#">
		</cfquery>
		<cfif check.ct NEQ 1>
			<cfthrow message="No publication record found for provided publication_id [#encodeForHTML(url.publication_id)#]" >
		</cfif>
	<cfcatch>
		<cfinclude template="/errors/404.cfm">
		<cfinclude template = "/shared/_footer.cfm">
		<cfabort>
	</cfcatch>
	</cftry>

	<cfquery name="getDetails" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getDetails_result">
		SELECT
			PUBLICATION_ID ,
			PUBLISHED_YEAR ,
			PUBLICATION_TYPE ,
			PUBLICATION_LOC ,
			PUBLICATION_TITLE ,
			PUBLICATION_REMARKS ,
			IS_PEER_REVIEWED_FG ,
			DOI,
			mczbase.getshortcitation(publication_id) as short_citation,
			mczbase.getfullcitation(publication_id) as full_citation
		FROM publication
		WHERE
			publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#url.publication_id#">
	</cfquery>
	<cfquery name="getAgents" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getAgents_result">
		SELECT
			agent_name.agent_id,
			author_role,
			MCZBASE.get_agentnameoftype(agent_name.agent_id,'author') as name,
			agentguid,
			agentguid_guid_type
		FROM
			publication_author_name
			join agent_name on publication_author_name.agent_name_id = agent_name.agent_name_id
			join agent on agent_name.agent_id = agent.agent_id
		WHERE
			publication_author_name.publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#url.publication_id#">
		ORDER BY
			author_role asc, author_position asc
	</cfquery>
	<cfquery name="getAttributes" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getAttributes_result">
		SELECT
			PUBLICATION_ATTRIBUTE_ID ,
			PUBLICATION_ID ,
			PUBLICATION_ATTRIBUTE ,
			PUB_ATT_VALUE
		FROM publication_attributes
		WHERE
			publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#url.publication_id#">
	</cfquery>
	<cfquery name="citedSpecimens" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="citedSpecimens_result">
		SELECT
			type_status,
			occurs_page_number,
			citation_remarks,
			citation_page_uri,
			publication_id,
			'MCZ:' || collection_cde || ':' || cat_num as guid,
			cited_taxon_name_id,
			display_name,
			author_text,
			scientific_name,
			taxonomy.taxonid,
			taxonid_guid_type
		FROM citation
			JOIN cataloged_item on CITATION.COLLECTION_OBJECT_ID = CATALOGED_ITEM.COLLECTION_OBJECT_ID
			JOIN taxonomy on citation.cited_taxon_name_id = taxonomy.taxon_name_id
		WHERE
			publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#url.publication_id#">
		ORDER BY
			occurs_page_number asc, scientific_name
	</cfquery>
	<cfquery name="taxonPublications" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="taxonPublications_result">
		SELECT distinct
			taxonomy.taxon_name_id,
			taxonomy.display_name,
			taxonomy.scientific_name,
			taxonomy.author_text,
			taxonomy.phylclass,
			taxonomy.family,
			taxonomy.taxonid,
			taxonomy.taxonid_guid_type
		FROM
			taxonomy_publication
			JOIN taxonomy on taxonomy_publication.taxon_name_id=taxonomy.taxon_name_id
		WHERE
			taxonomy_publication.publication_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#url.publication_id#">
		ORDER BY
			taxonomy.phylclass, taxonomy.family, taxonomy.scientific_name
	</cfquery>
	<cfquery name="citedNamedGroups" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="citedNamedGroups_result">
		SELECT collection_name, type, pages, remarks, mask_fg, underscore_collection.underscore_collection_id
		FROM
			underscore_collection_citation
			JOIN underscore_collection on underscore_collection_citation.underscore_collection_id = underscore_collection.underscore_collection_id
		WHERE
			underscore_collection_citation.publication_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#url.publication_id#">
			<cfif NOT canManagePublications>
				and mask_fg = 0
			</cfif>
	</cfquery>
	<cfquery name="pubMedia" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="pubMedia_result">
		SELECT
			media_id
		FROM media_relations
		WHERE
			media_relationship = 'shows publication'
			AND related_primary_key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#url.publication_id#">
	</cfquery>

	<cfoutput query="getDetails">

	<!--- Publication card: always open, no collapse toggle. --->
	<section class="row mx-0 mb-2">
		<div class="col-12 px-0">
			<div class="card mb-2">
				<div class="card-header py-2">
					<cfif canManagePublications>
						<div class="float-right ml-2 d-flex flex-column">
							<a class="btn btn-xs btn-primary mb-1" href="/publications/Publication.cfm?action=edit&publication_id=#getDetails.publication_id#">Edit Publication Record</a>
							<a class="btn btn-xs btn-primary" href="/Citation.cfm?publication_id=#getDetails.publication_id#">Manage Citations</a>
						</div>
					</cfif>
					<h1 class="h2 mt-0 mb-1">#getDetails.full_citation#</h1>
				</div>
				<div class="card-body px-3 py-2">
					<ul>
						<li><strong>Short Citation: </strong> #getDetails.short_citation#</li>
						<li><strong>Year Published: </strong> #getDetails.published_year#</li>
						<cfloop query="getAgents">
							<cfset agentLinkOut = "">
							<cfif len(getAgents.agentguid) GT 0>
								<cfset agentLinkOut = getGuidLink(guid=#getAgents.agentguid#,guid_type=#getAgents.agentguid_guid_type#)>
							</cfif>
							<li>
								<strong>#getAgents.author_role#: </strong>
								<a href="/agents/Agent.cfm?agent_id=#getAgents.agent_id#">#getAgents.name#</a>
								#agentLinkOut#
							</li>
						</cfloop>
						<li><strong>Title: </strong> #getDetails.publication_title#</li>
						<li><strong>Publication Type: </strong> #getDetails.publication_type#</li>
						<li><strong>DOI: </strong>
							<cfif len(getDetails.doi) GT 0>
								<a target="_blank" href='https://doi.org/#getDetails.doi#'>
									#getDetails.doi#
									<img src="/shared/images/linked_data.png" height="15" width="15" alt="linked data icon">
								</a>
							</cfif>
						</li>
						<cfif getDetails.is_peer_reviewed_fg EQ 0>
							<li><strong>Peer Reviewed: </strong> No</li>
						</cfif>
						<cfif len(getDetails.publication_remarks) GT 0>
							<li><strong>Remarks: </strong> #getDetails.publication_remarks#</li>
						</cfif>
						<cfif canManagePublications>
							<li><strong>Location: </strong> #getDetails.publication_loc#</li>
						</cfif>
					</ul>

					<cfif getAttributes.recordcount GT 0>
						<ul>
							<cfloop query="getAttributes">
								<li><strong>#getAttributes.publication_attribute#: </strong> #getAttributes.pub_att_value#</li>
							</cfloop>
						</ul>
					</cfif>

					<cfif citedNamedGroups.recordcount GT 0>
						<h2 class="h5">Named Groups Related to #getDetails.short_citation#:</h2>
						<ul>
							<cfloop query="citedNamedGroups">
								<li>
									<a href="/grouping/showNamedCollection.cfm?underscore_collection_id=#citedNamedGroups.underscore_collection_id#">
										#citedNamedGroups.collection_name#
										<span class='small90'>
											#citedNamedGroups.type#
											<cfif len(citedNamedGroups.pages) GT 0>pp. #citedNamedGroups.pages#</cfif>
										</span>
									</a>
								</li>
							</cfloop>
						</ul>
					</cfif>
				</div>
			</div>
		</div>
	</section>

	<!--- Media card: closable, open by default. --->
	<section class="row mx-0 mb-2">
		<div class="col-12 px-0 accordion" id="pubMediaSectionAccordion">
			<div class="card">
				<div class="card-header py-0" id="pubMediaCardHeader">
					<h2 class="h4 my-0">
						<button type="button" class="headerLnk text-left w-100 h-100" data-toggle="collapse" data-target="##pubMediaCardBodyWrap" aria-expanded="true" aria-controls="pubMediaCardBodyWrap">
							Media &mdash; #pubMedia.recordcount# item<cfif pubMedia.recordcount NEQ 1>s</cfif>
						</button>
					</h2>
				</div>
				<div id="pubMediaCardBodyWrap" class="collapse show" aria-labelledby="pubMediaCardHeader" data-parent="##pubMediaSectionAccordion">
					<div class="card-body">
						<cfif pubMedia.recordcount EQ 0>
							<p class="mb-0">No Media for this publication.</p>
						<cfelse>
							<ul class="list-group py-2 list-group-horizontal flex-wrap rounded-0">
								<cfloop query="pubMedia">
									<li class="list-group-item col-12 col-sm-6 col-md-4 col-lg-3 float-left">
										<cfset mediablock = getMediaBlockHtml(media_id="#pubMedia.media_id#",displayAs="thumb",captionAs="textShort")>
										<div id="mediaBlock#media_id#" class="border rounded pt-2 px-2">
											#mediablock#
										</div>
									</li>
								</cfloop>
							</ul>
						</cfif>
					</div>
				</div>
			</div>
		</div>
	</section>

	<!--- Cited Specimens card: closable, open by default. --->
	<cfif citedSpecimens.recordcount is 0>
		<cfset specCount = "">
	<cfelse>
		<cfset target="/Specimens.cfm?execute=true&builderMaxRows=1&action=builderSearch&nestdepth1=1&field1=CITATION%3ACITATIONS_PUBLICATION_ID&searchText1=#encodeForURL(getDetails.short_citation)#&searchId1=#getDetails.publication_id#">
		<cfset specCount = " <a href='#target#'>(#citedSpecimens.recordCount#)</a>" >
	</cfif>
	<section class="row mx-0 mb-2">
		<div class="col-12 px-0 accordion" id="citedSpecimensSectionAccordion">
			<div class="card">
				<div class="card-header py-0" id="citedSpecimensCardHeader">
					<h2 class="h4 my-0">
						<button type="button" class="headerLnk text-left w-100 h-100" data-toggle="collapse" data-target="##citedSpecimensCardBodyWrap" aria-expanded="true" aria-controls="citedSpecimensCardBodyWrap">
							Cited MCZ Specimens#specCount# in #getDetails.short_citation#
						</button>
					</h2>
				</div>
				<div id="citedSpecimensCardBodyWrap" class="collapse show" aria-labelledby="citedSpecimensCardHeader" data-parent="##citedSpecimensSectionAccordion">
					<div class="card-body">
						<cfif citedSpecimens.recordcount is 0>
							<p class="mb-0"><b>No cited MCZ specimens.</b></p>
						<cfelse>
							<div class="table-responsive">
								<table class="table table-sm table-striped mb-0">
									<caption class="sr-only">Specimens cited in #getDetails.short_citation#</caption>
									<thead>
										<tr>
											<th scope="col">GUID</th>
											<th scope="col">Taxon</th>
											<th scope="col">Type Status</th>
											<th scope="col">Page</th>
											<th scope="col">Remarks</th>
										</tr>
									</thead>
									<tbody>
										<cfloop query="citedSpecimens">
											<cfif len(citedSpecimens.occurs_page_number) GT 0>
												<cfif len(citedSpecimens.citation_page_uri) GT 0>
													<cfset page = "p. <a href='#citation_page_uri#'>#occurs_page_number#</a>" >
												<cfelse>
													<cfset page = "p. #occurs_page_number#">
												</cfif>
											<cfelse>
												<cfif len(citedSpecimens.citation_page_uri) GT 0>
													<cfset page = "<a href=#citation_page_uri#>[page link]</a>" >
												<cfelse>
													<cfset page = "">
												</cfif>
											</cfif>
											<cfset taxonidLink ="">
											<cfif len(citedSpecimens.taxonid) gt 0>
												<cfset link = getGuidLink(guid=#citedSpecimens.taxonid#,guid_type=#citedSpecimens.taxonid_guid_type#)>
												<cfset taxonidLink = " <span>#link#</span>" >
											</cfif>
											<tr>
												<td><a href="/guid/#guid#">#guid#</a></td>
												<td><a href="/name/#encodeForURL(scientific_name)#">#display_name#</a> <span class="sm-caps">#author_text#</span>#taxonidLink#</td>
												<td>#type_status#</td>
												<td>#page#</td>
												<td>#citedSpecimens.citation_remarks#</td>
											</tr>
										</cfloop>
									</tbody>
								</table>
							</div>
						</cfif>
					</div>
				</div>
			</div>
		</div>
	</section>

	<!--- Taxa Related card: closable, open by default. --->
	<section class="row mx-0 mb-2">
		<div class="col-12 px-0 accordion" id="taxaRelatedSectionAccordion">
			<div class="card">
				<div class="card-header py-0" id="taxaRelatedCardHeader">
					<h2 class="h4 my-0">
						<button type="button" class="headerLnk text-left w-100 h-100" data-toggle="collapse" data-target="##taxaRelatedCardBodyWrap" aria-expanded="true" aria-controls="taxaRelatedCardBodyWrap">
							Taxa Related to #getDetails.short_citation# &mdash; #taxonPublications.recordcount# <cfif taxonPublications.recordcount EQ 1>taxon<cfelse>taxa</cfif>
						</button>
					</h2>
				</div>
				<div id="taxaRelatedCardBodyWrap" class="collapse show" aria-labelledby="taxaRelatedCardHeader" data-parent="##taxaRelatedSectionAccordion">
					<div class="card-body">
						<cfif taxonPublications.recordcount EQ 0>
							<p class="mb-0">None.</p>
						<cfelse>
							<ul class="list-group">
								<cfloop query="taxonPublications">
									<cfset taxonidLink = "">
									<cfif len(taxonPublications.taxonid) gt 0>
										<cfset link = getGuidLink(guid=#taxonPublications.taxonid#,guid_type=#taxonPublications.taxonid_guid_type#)>
										<cfset taxonidLink = " #link#" >
									</cfif>
									<li class="list-group-item text-nowrap">
										<cfif len(trim(taxonPublications.phylclass)) GT 0>#encodeForHtml(trim(taxonPublications.phylclass))# : </cfif><cfif len(trim(taxonPublications.family)) GT 0>#encodeForHtml(trim(taxonPublications.family))# : </cfif><a href="/taxonomy/showTaxonomy.cfm?taxon_name_id=#taxonPublications.taxon_name_id#">#taxonPublications.display_name#</a> <span class="sm-caps d-inline">#taxonPublications.author_text#</span>#taxonidLink#
									</li>
								</cfloop>
							</ul>
						</cfif>
					</div>
				</div>
			</div>
		</div>
	</section>

	<cfif isdefined("session.username") and len(session.username) gt 0>
		<!--- Annotations card: same accordion pattern as taxonomy/showTaxonomy.cfm and
		      projects/showProject.cfm. --->
		<cfquery name="existingAnnotations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="existingAnnotations_result">
			SELECT
				COUNT(*) AS cnt
			FROM
				annotations
			WHERE
				target_table = 'PUBLICATION'
				AND target_primary_key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getDetails.publication_id#">
				<cfif NOT canManagePublications>
					AND (mask_annotation_fg = 0 OR cf_username = <cfqueryparam value="#session.username#" cfsqltype="CF_SQL_VARCHAR">)
				</cfif>
		</cfquery>
		<div id="publicationAnnotationDialog"></div>
		<script type="text/javascript">
			function reloadPublicationAnnotationCardBody() {
				$.ajax({
					url: '/annotations/component/public.cfc',
					data: { method: 'getPublicationAnnotationCardBodyHtml', publication_id: #getDetails.publication_id# },
					success: function(result) { $('##publicationAnnotationsCardBodyWrap').html(result); },
					error: function(jqXHR, textStatus, error) { handleFail(jqXHR, textStatus, error, 'reloading publication annotations'); },
					dataType: 'html'
				});
			}
		</script>
		<section class="accordion" id="publicationAnnotationsSection">
			<div class="card mb-2 bg-light">
				<div class="card-header" id="publicationAnnotationsHeader">
					<h2 class="h4 my-0">
						<button type="button" class="headerLnk text-left w-100 h-100" data-toggle="collapse" data-target="##publicationAnnotationsCardBodyWrap" aria-expanded="true" aria-controls="publicationAnnotationsCardBodyWrap">
							Annotations (#existingAnnotations.cnt#)
						</button>
						<cfif canManagePublications AND existingAnnotations.cnt GT 0>
							<a href="javascript:void(0)" role="button" aria-label="Edit Annotations" class="btn btn-xs small py-0 anchorFocus" onclick="openAnnotationsDialog('publicationAnnotationDialog','PUBLICATION',#getDetails.publication_id#,reloadPublicationAnnotationCardBody);">
								Edit Annotations
							</a>
						<cfelse>
							<a href="javascript:void(0)" role="button" class="btn btn-xs small py-0 anchorFocus" onclick="openAnnotationsDialog('publicationAnnotationDialog','PUBLICATION',#getDetails.publication_id#,reloadPublicationAnnotationCardBody);">
								Annotate
							</a>
						</cfif>
					</h2>
				</div>
				<div id="publicationAnnotationsCardBodyWrap" class="collapse show" aria-labelledby="publicationAnnotationsHeader" data-parent="##publicationAnnotationsSection">
					#getPublicationAnnotationCardBodyHtml(publication_id=val(getDetails.publication_id))#
				</div>
			</div>
		</section>
	</cfif>

	</cfoutput>
</main><!--- class="container" --->
<cfinclude template = "/shared/_footer.cfm">
