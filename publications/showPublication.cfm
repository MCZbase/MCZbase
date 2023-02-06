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
<cfset shortCitation = "">
<cfif isdefined("publication_id") and len(publication_id) GT 0 and isNumeric(publication_id) >
	<!--- lookup the short form of the citation to display in the page title. --->
	<cfquery name="lookupShort" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		SELECT
			formatted_publication as citation
		FROM
			formatted_publication
		WHERE
			publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
			and format_style = 'short'
	</cfquery>
	<cfif lookupShort.recordcount EQ 1>
		<cfset shortCitation = ": #lookupShort.citation#">
	</cfif>
</cfif>
<cfset pageTitle = "Publication Details#shortCitation#">
<cfinclude template = "/shared/_header.cfm">
<cfinclude template="/media/component/search.cfc" runOnce="true"><!--- for getMediaBlockHtml() --->
<cfinclude template="/specimens/component/public.cfc" runOnce="true"><!--- for getGuidLink() --->

<main class="container py-3">
	
	<cftry>
		<cfif isdefined("publication_id") and len(publication_id) GT 0 >
			<cfquery name="check" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="check_result">
				select count(*) ct
				from publication 
				where publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
			</cfquery>
			<cfif check.ct NEQ 1>
				<cfthrow message="No publication record found for provided publication_id [#encodeForHTML(publication_id)#]" >
			</cfif>
		<cfelse>
			<cfthrow message="No publication_id provided">
		</cfif>
	<cfcatch>
		<cfoutput>
			<h1 class="h2 mt-3">Error looking up publication record.</h1>
			<p>#cfcatch.Message#</p>
			<cfif isdefined("session.roles") and listfindnocase(session.roles,"global_admin") >
				<p>#cfcatch.Detail#</p>
			</cfif>
		</cfoutput>
		<cfinclude template = "/shared/_footer.cfm">
		<cfabort>
	</cfcatch>
	</cftry>
	
	<cfquery name="getDetails" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getDetails_result">
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
			publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
	</cfquery>
	<cfquery name="getAgents" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getAgents_result">
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
			publication_author_name.publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
		ORDER BY
			author_role asc, author_position asc
	</cfquery>
	<cfquery name="getAttributes" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getAttributes_result">
		SELECT
			PUBLICATION_ATTRIBUTE_ID ,
			PUBLICATION_ID ,
			PUBLICATION_ATTRIBUTE ,
			PUB_ATT_VALUE  
		FROM publication_attributes
		WHERE
			publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
	</cfquery>
	<cfquery name="citedSpecimens" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="citedSpecimens_result">
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
			publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
		ORDER BY
			occurs_page_number asc, scientific_name
	</cfquery>
	<cfquery name="taxonPublications" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="taxonPublications_result">
		SELECT distinct
			taxonomy.taxon_name_id,
			taxonomy.display_name,
			taxonomy.author_text
		FROM
			taxonomy_publication
			JOIN taxonomy on taxonomy_publication.taxon_name_id=taxonomy.taxon_name_id
		WHERE
			taxonomy_publication.publication_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
	</cfquery>
	<cfquery name="citedNamedGroups" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="citedNamedGroups_result">
		SELECT collection_name, type, pages, remarks, mask_fg, underscore_collection.underscore_collection_id 
		FROM
			underscore_collection_citation
			JOIN underscore_collection on underscore_collection_citation.underscore_collection_id = underscore_collection.underscore_collection_id
		WHERE
			underscore_collection_citation.publication_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
			<cfif NOT isdefined("session.roles") OR listfindnocase(session.roles,"coldfusion_user") EQ 0>
				and mask_fg = 0
			</cfif>
	</cfquery>

	<section class="row">
		<div class="col-12 mb-5"> 
			<cfoutput query="getDetails"> 

				<div class="pb-2">
					<h1 class="h2 mt-3">#getDetails.full_citation#</h1>
				</div>
			
				<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_publications")>
					<p> 
						<a class="btn btn-xs btn-primary" href="/publications/Publication.cfm?action=edit&publication_id=#getDetails.publication_id#">Edit Publication Record</a>
						<a class="btn btn-xs btn-primary" href="/Citation.cfm?publication_id=#getDetails.publication_id#">Manage Citations</a>
					</p>
				</cfif>
				
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
					<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_publications")>
						<li><strong>Location: </strong> #getDetails.publication_loc#</li>
					</cfif>
				</ul>

				<ul>
					<cfloop query="getAttributes">
						<li><strong>#getAttributes.publication_attribute#: </strong> #getAttributes.pub_att_value#</li>
					</cfloop>
				</ul>

				<div id="pubMediaDiv">
					<cfquery name="media" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="media_result">
						SELECT
							media_id
						FROM media_relations
						WHERE
							media_relationship = 'shows publication'
							AND related_primary_key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
					</cfquery>
					<div class="row" id="pubMediaRow">
						<div class="col-12">
							<h2 class="h4">Media:</h2>
							<cfif media.recordcount EQ 0>
								<p>No Media for this publication</p>
							<cfelse>
								<ul class="list-group py-2 list-group-horizontal flex-wrap rounded-0">
								<cfloop query="media">
									<li class="list-group-item col-12 col-sm-6 col-md-4 col-lg-3 float-left"> 
										<cfset mediablock= getMediaBlockHtml(media_id="#media.media_id#",displayAs="thumb",captionAs="textShort")>
										<div id="mediaBlock#media_id#" class="border rounded pt-2 px-2">
											#mediablock#
										</div>
									</li>
								</cfloop>
							</cfif>
						</div>
					</div>
				</div>
								
				<cfif citedSpecimens.recordcount is 0>
					<cfset specCount = "">
				<cfelse>
					<cfset target="/Specimens.cfm?execute=true&builderMaxRows=1&action=builderSearch&nestdepth1=1&field1=CITATION%3ACITATIONS_PUBLICATION_ID&searchText1=#encodeForURL(getDetails.short_citation)#&searchId1=#getDetails.publication_id#">
					<cfset specCount = " <a href='#target#'>(#citedSpecimens.recordCount#)</a>" >
				</cfif>
				<h2 class="h4">Cited MCZ Specimens#specCount# in #getDetails.short_citation#:</h2>
				<ul>
					<cfif citedSpecimens.recordcount is 0>
						<li><b>No cited MCZ specimens.</b></li>
					<cfelse>
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
								<cfset taxonidLink = "<span>#link#</span> " >
							</cfif>
							<li> 
								<a href="/guid/#guid#">#guid#</a> 
								<a href="/name/#encodeForURL(scientific_name)#">#display_name#</a> <span class="sm-caps">#author_text#</span> 
								#taxonidLink##type_status# #page# #citedSpecimens.citation_remarks#
							</li>
						</cfloop>
					</cfif>
				</ul>

				<cfif citedNamedGroups.recordcount GT 0>
					<h2 class="h4">Named Groups Related to #getDetails.short_citation#:</h2>
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

				<cfif taxonPublications.recordcount GT 0>
					<h2 class="h4">Taxa Related to #getDetails.short_citation#:</h2>
					<ul>
						<cfloop query="taxonPublications">
							<li>
								<a href="/taxonomy/showTaxonomy.cfm?taxon_name_id=#taxonPublications.taxon_name_id#">
									#taxonPublications.display_name# <span class='sm-caps font-weight-normal small90'>#taxonPublications.author_text#</span>
								</a>
							</li>
						</cfloop>
					</ul>
				</cfif>
				
				<cfif isdefined("session.username") and len(#session.username#) gt 0>
					<div class="row">
						<div class="col-12">
							<h2 class="h4">Annotations:</h2>
							<cfquery name="existingAnnotations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
								select count(*) cnt from annotations
								where publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
							</cfquery>
							<cfif #existingAnnotations.cnt# GT 0>
								<button type="button" aria-label="Annotate" id="annotationDialogLauncher"
									class="btn btn-xs btn-info" value="Annotate this record and view existing annotations"
									onClick=" openAnnotationsDialog('annotationDialog','publication',#publication_id#,null);">Annotate/View Annotations</button>
							<cfelse>
								<button type="button" aria-label="Annotate" id="annotationDialogLauncher"
									class="btn btn-xs btn-info" value="Annotate this record"
									onClick=" openAnnotationsDialog('annotationDialog','publication',#publication_id#,null);">Annotate</button>
							</cfif>
							<div id="annotationDialog"></div>
							<cfif #existingAnnotations.cnt# gt 0>
								<cfif #existingAnnotations.cnt# EQ 1>
									<cfset are = "is">
									<cfset s = "">
								<cfelse>
									<cfset are = "are">
									<cfset s = "s">
								</cfif>
								<p>There #are# #existingAnnotations.cnt# annotation#s# on this taxon record</p>
								<cfquery name="AnnotationStates" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
									select count(*) statecount, state from annotations
									where publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
									group by state
								</cfquery>
								<ul>
									<cfloop query="AnnotationStates">
										<li>#state#: #statecount#</li>
									</cfloop>
								</ul>
							<cfelse>
								<p class="my-2">There are no annotations on this publication record</p>
							</cfif>
						</div>
					</div>
				</cfif>
		
			</cfoutput> 
		</div> <!--- col --->
	</section><!-- row --->
</main><!--- class="container" --->
<cfinclude template = "/shared/_footer.cfm">
