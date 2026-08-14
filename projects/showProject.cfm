<!---
projects/showProject.cfm

Copyright 2026 President and Fellows of Harvard College

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
<!---
Details page for a single project.

TODO: Cleanup, this replaces ProjectDetail.cfm. when cone cleanup the seven
/includes/project/*.cfm fragments that page ajax-loaded (pubs, specUsed, specCont,
projCont, projUseCont, projMedia, projTaxa) are folded in below as inline section.
--->
<cfparam name="url.project_id" default="">

<cfset pageTitle = "Project Details">
<cfif len(url.project_id) GT 0 AND isnumeric(url.project_id)>
	<cfquery name="lookupTitle" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		SELECT
			project_name
		FROM
			project
		WHERE
			project_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#url.project_id#">
	</cfquery>
	<cfif lookupTitle.recordcount EQ 1>
		<cfset pageTitle = "Project Details: #encodeForHtml(lookupTitle.project_name)#">
	</cfif>
</cfif>

<cfinclude template = "/shared/_header.cfm">
<cfinclude template="/media/component/public.cfc" runOnce="true"><!--- for getMediaBlockHtml() --->

<!--- store relevant session role information into variables for use in this page --->
<cfset canManageProjects = false>
<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
	<cfset oneOfUs = 1>
	<cfif listfindnocase(session.roles,"manage_projects")>
		<cfset canManageProjects = true>
	</cfif>
<cfelse>
	<cfset oneOfUs = 0>
</cfif>

<main class="container py-3" id="content">
	<cftry>
		<cfif len(url.project_id) EQ 0 OR NOT isnumeric(url.project_id)>
			<cfthrow message="No project_id provided.">
		</cfif>
		<cfquery name="getProject" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getProject_result">
			SELECT
				project_id,
				project_name,
				mask_project_fg,
				project_description,
				start_date,
				end_date
			FROM
				project
			WHERE
				project_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#url.project_id#">
				<cfif oneOfUs NEQ 1>
					AND mask_project_fg = 0
				</cfif>
		</cfquery>
		<cfif getProject.recordcount EQ 0>
			<cfthrow message="No project found for the given project_id.">
		</cfif>
	<cfcatch>
		<cfinclude template="/errors/404.cfm">
		<cfabort>
	</cfcatch>
	</cftry>

	<cfquery name="getParticipants" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getParticipants_result">
		SELECT
			agent_name.agent_id,
			agent_name.agent_name,
			project_agent.project_agent_role
		FROM
			project_agent
			JOIN agent_name ON project_agent.agent_name_id = agent_name.agent_name_id
		WHERE
			project_agent.project_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#url.project_id#">
		ORDER BY
			project_agent.agent_position
	</cfquery>

	<cfquery name="getSponsors" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getSponsors_result">
		SELECT
			agent_name.agent_name,
			project_sponsor.acknowledgement
		FROM
			project_sponsor
			JOIN agent_name ON project_sponsor.agent_name_id = agent_name.agent_name_id
		WHERE
			project_sponsor.project_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#url.project_id#">
	</cfquery>

	<cfquery name="getPublications" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getPublications_result">
		SELECT
			formatted_publication.publication_id,
			formatted_publication,
			COUNT(citation.collection_object_id) AS numCit
		FROM
			project_publication 
			join formatted_publication on project_publication.publication_id = formatted_publication.publication_id
			left join citation on formatted_publication.publication_id = citation.publication_id
		WHERE
			format_style = 'long' AND
			project_publication.project_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#url.project_id#">
		GROUP BY
			formatted_publication.publication_id,
			formatted_publication
		ORDER BY
			formatted_publication
	</cfquery>

	<!--- Specimens used specimens on loan to this project, either directly or as a sub-part derived from a loaned item. --->
	<cfquery name="getSpecimensUsed" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getSpecimensUsed_result">
		SELECT
			collection.collection,
			collection.collection_id,
			COUNT(DISTINCT(cataloged_item.collection_object_id)) AS c
		FROM
			cataloged_item
			join collection on cataloged_item.collection_id = collection.collection_id
			join specimen_part on specimen_part.derived_from_cat_item = cataloged_item.collection_object_id
			join loan_item on specimen_part.collection_object_id = loan_item.collection_object_id
			join project_trans on loan_item.transaction_id = project_trans.transaction
		WHERE
			project_trans.project_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#url.project_id#">
		GROUP BY
			collection.collection,
			collection.collection_id
		UNION
		SELECT
			collection.collection,
			collection.collection_id,
			COUNT(DISTINCT(cataloged_item.collection_object_id)) AS c
		FROM
			cataloged_item
			join collection on cataloged_item.collection_id = collection.collection_id
			join loan_item on cataloged_item.collection_object_id = loan_item.collection_object_id
			join project_trans on loan_item.transaction_id = project_trans.transaction_id
		WHERE
			project_trans.project_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#url.project_id#">
		GROUP BY
			collection.collection,
			collection.collection_id
	</cfquery>
	<cfquery name="specUsedTotal" dbtype="query">
		SELECT SUM(c) AS totspec FROM getSpecimensUsed
	</cfquery>
	<cfquery name="specUsedCollections" dbtype="query">
		SELECT collection FROM getSpecimensUsed GROUP BY collection
	</cfquery>

	<!--- Specimens contributed: specimens accessioned through this project. --->
	<cfquery name="getSpecimensContributed" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getSpecimensContributed_result">
		SELECT
			collection,
			collection.collection_id,
			COUNT(*) AS c
		FROM
			project 
			join project_trans on project.project_id = project_trans.project_id
			join accn on project_trans.transaction_id = accn.transaction_id
			join cataloged_item on accn.transaction_id = cataloged_item.accn_id 
			join collection on cataloged_item.collection_id = collection.collection_id 
		WHERE
			project.project_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#url.project_id#">
		GROUP BY
			collection,
			collection.collection_id
	</cfquery>
	<cfquery name="specContTotal" dbtype="query">
		SELECT SUM(c) AS totspec FROM getSpecimensContributed
	</cfquery>
	<cfquery name="specContCollections" dbtype="query">
		SELECT collection FROM getSpecimensContributed GROUP BY collection
	</cfquery>

	<!--- Projects contributing specimens (was includes/project/projCont.cfm): other
	      projects whose contributed specimens this project's loans derive parts from. --->
	<cfquery name="getContributingProjects" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getContributingProjects_result">
		SELECT
			project.project_id,
			project_name
		FROM
			project
		WHERE
			project.project_id IN (
				SELECT
					project_trans.project_id
				FROM
					project
					join project_trans on project.project_id = project_trans.project_id
					join accn on project_trans.transaction_id = accn.transaction_id 
					join cataloged_item on accn.transaction_id = cataloged_item.accn_id
				WHERE
					cataloged_item.collection_object_id IN (
						SELECT
							cataloged_item.collection_object_id
						FROM
							project
							join project_trans on project.project_id = project_trans.project
							join loan_item on project_trans.transaction_id = loan_item.transaction_id
							join specimen_part on loan_item.collection_object_id = specimen_part.collection_object_id 
							join cataloged_item on specimen_part.derived_from_cat_item = cataloged_item.collection_object_id 
						WHERE
							project.project_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#url.project_id#">
					)
			)
		ORDER BY
			project_name
	</cfquery>

	<!--- Projects using contributed specimens (was includes/project/projUseCont.cfm):
	      other projects that borrowed parts derived from specimens this project
	      contributed. --->
	<cfquery name="getUsingProjects" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getUsingProjects_result">
		SELECT
			project.project_id,
			project_name
		FROM
			project
		WHERE
			project.project_id IN (
				SELECT
					project_trans.project_id
				FROM
					project
					join project_trans on project.project_id = project_trans.project_id
					join loan_item on project_trans.transaction_id = loan_item.transaction_id
					join specimen_part on loan_item.collection_object_id = specimen_part.collection_object_id
					join cataloged_item on specimen_part.derived_from_cat_item = cataloged_item.collection_object_id
				WHERE
					cataloged_item.collection_object_id IN (
						SELECT
							cataloged_item.collection_object_id
						FROM
							project
							join project_trans on project.project_id = project_trans.project_id
							join accn on project_trans.transaction_id = accn.transaction_id
							join cataloged_item on accn.transaction_id = cataloged_item.accn_id
						WHERE
							project.project_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#url.project_id#">
					)
			)
		GROUP BY
			project.project_id,
			project_name
		ORDER BY
			project_name
	</cfquery>

	<!--- Media (was includes/project/projMedia.cfm) --->
	<cfquery name="getMedia" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getMedia_result">
		SELECT DISTINCT
			media.media_id
		FROM
			media
			join media_relations on media.media_id = media_relations.media_id
		WHERE
			media_relations.media_relationship LIKE '% project' AND
			media_relations.related_primary_key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#url.project_id#">
	</cfquery>

	<!--- Taxonomy (was includes/project/projTaxa.cfm) --->
	<cfquery name="getTaxa" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getTaxa_result">
		SELECT
			taxonomy.taxon_name_id,
			scientific_name
		FROM
			project_taxonomy
			join taxonomy on project_taxonomy.taxon_name_id = taxonomy.taxon_name_id
		WHERE
			project_taxonomy.project_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#url.project_id#">
	</cfquery>

	<cfoutput>
	<section class="row border rounded my-2">
		<div class="col-12 py-2">
			<h1 class="h2 mt-3">#encodeForHtml(getProject.project_name)#</h1>

			<cfif getSponsors.recordcount GT 0>
				<p class="h5">
					Sponsored by
					<cfloop query="getSponsors">
						#encodeForHtml(agent_name)#<cfif len(acknowledgement) GT 0>: #encodeForHtml(acknowledgement)#</cfif><cfif getSponsors.currentRow LT getSponsors.recordcount>; </cfif>
					</cfloop>
				</p>
			</cfif>

			<cfif canManageProjects>
				<p>
					<!--- publications/showPublication.cfm's own equivalent link uses
					      btn-primary; that appears to be a pre-existing deviation from
					      this app's documented button convention (Edit -> btn-secondary),
					      not a precedent to repeat, so this uses btn-secondary instead. --->
					<a class="btn btn-xs btn-secondary" href="/Project.cfm?Action=editProject&project_id=#getProject.project_id#">Edit Project</a>
				</p>
			</cfif>

			<ul>
				<cfloop query="getParticipants">
					<li><strong>#encodeForHtml(project_agent_role)#: </strong> <a href="/agents/Agent.cfm?agent_id=#agent_id#">#encodeForHtml(agent_name)#</a></li>
				</cfloop>
				<li><strong>Duration: </strong> #dateformat(getProject.start_date,"yyyy-mm-dd")# to #dateformat(getProject.end_date,"yyyy-mm-dd")#</li>
				<cfif oneOfUs EQ 1>
					<cfif getProject.mask_project_fg EQ 1>
						<cfset visibility = "Hidden">
					<cfelse>
						<cfset visibility = "Public">
					</cfif>
					<li><strong>Visibility: </strong> #visibility#</li>
				</cfif>
			</ul>

			<h2 class="h4">Description</h2>
			<p>#encodeForHtml(getProject.project_description)#</p>

			<cfif getPublications.recordcount GT 0>
				<h2 class="h4">Publications</h2>
				<p>This project produced #getPublications.recordcount# publication<cfif getPublications.recordcount NEQ 1>s</cfif>.</p>
				<ul>
					<cfloop query="getPublications">
						<li>
							#encodeForHtml(formatted_publication)#
							<cfif numCit GT 0>
								&mdash; <a href="/SpecimenResults.cfm?publication_id=#publication_id#">#numCit# cited specimen<cfif numCit NEQ 1>s</cfif></a>
							</cfif>
							&mdash; <a href="/publications/showPublication.cfm?publication_id=#publication_id#">Details</a>
						</li>
					</cfloop>
				</ul>
			</cfif>

			<cfif getSpecimensUsed.recordcount GT 0>
				<h2 class="h4">Specimens Used</h2>
				<ul>
					<cfloop query="getSpecimensUsed">
						<li>
							<a href="/SpecimenResults.cfm?loan_project_id=#url.project_id#&collection_id=#collection_id#">#c# #encodeForHtml(collection)# specimen<cfif c NEQ 1>s</cfif></a>
							<a href="/bnhmMaps/bnhmMapData.cfm?loan_project_id=#url.project_id#&collection_id=#collection_id#">[ BerkeleyMapper ]</a>
						</li>
					</cfloop>
					<cfif specUsedCollections.recordcount GT 1>
						<li>
							<a href="/SpecimenResults.cfm?loan_project_id=#url.project_id#">#specUsedTotal.totspec# total specimens</a>
							<a href="/bnhmMaps/bnhmMapData.cfm?loan_project_id=#url.project_id#">[ BerkeleyMapper ]</a>
						</li>
					</cfif>
				</ul>
			</cfif>

			<cfif getSpecimensContributed.recordcount GT 0>
				<h2 class="h4">Specimens Contributed</h2>
				<ul>
					<cfloop query="getSpecimensContributed">
						<li>
							<a href="/SpecimenResults.cfm?project_id=#url.project_id#&collection_id=#collection_id#">#c# #encodeForHtml(collection)# specimen<cfif c NEQ 1>s</cfif></a>
							<a href="/bnhmMaps/bnhmMapData.cfm?project_id=#url.project_id#&collection_id=#collection_id#">[ BerkeleyMapper ]</a>
						</li>
					</cfloop>
					<cfif specContCollections.recordcount GT 1>
						<li>
							<a href="/SpecimenResults.cfm?project_id=#url.project_id#">#specContTotal.totspec# total specimens</a>
							<a href="/bnhmMaps/bnhmMapData.cfm?project_id=#url.project_id#">[ BerkeleyMapper ]</a>
						</li>
					</cfif>
				</ul>
			</cfif>

			<cfif getContributingProjects.recordcount GT 0>
				<h2 class="h4">Projects Contributing Specimens</h2>
				<p>#getContributingProjects.recordcount# project<cfif getContributingProjects.recordcount NEQ 1>s</cfif> contributed specimens used by this project.</p>
				<ul>
					<cfloop query="getContributingProjects">
						<li><a href="/projects/showProject.cfm?project_id=#project_id#">#encodeForHtml(project_name)#</a></li>
					</cfloop>
				</ul>
			</cfif>

			<cfif getUsingProjects.recordcount GT 0>
				<h2 class="h4">Projects Using Contributed Specimens</h2>
				<p>#getUsingProjects.recordcount# project<cfif getUsingProjects.recordcount NEQ 1>s</cfif> used specimens contributed by this project.</p>
				<ul>
					<cfloop query="getUsingProjects">
						<li><a href="/projects/showProject.cfm?project_id=#project_id#">#encodeForHtml(project_name)#</a></li>
					</cfloop>
				</ul>
			</cfif>

			<cfif getMedia.recordcount GT 0>
				<h2 class="h4">Media</h2>
				<div class="row">
					<cfloop query="getMedia">
						<div class="col-12 col-sm-6 col-md-4 col-lg-3 mb-3">
							#getMediaBlockHtml(media_id=media_id, displayAs="thumb", captionAs="textShort")#
						</div>
					</cfloop>
				</div>
			</cfif>

			<cfif getTaxa.recordcount GT 0>
				<h2 class="h4">Taxonomy</h2>
				<ul>
					<cfloop query="getTaxa">
						<li><a href="/name/#EncodeForURL(scientific_name)#">#encodeForHtml(scientific_name)#</a></li>
					</cfloop>
				</ul>
			</cfif>

			<cfif len(session.username) GT 0>
				<h2 class="h4">Annotations</h2>
				<cfquery name="existingAnnotations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="existingAnnotations_result">
					SELECT
						COUNT(*) AS cnt
					FROM
						annotations
					WHERE
						project_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#url.project_id#">
				</cfquery>
				<cfif existingAnnotations.cnt GT 0>
					<button type="button" aria-label="Annotate" id="annotationDialogLauncher"
						class="btn btn-xs btn-info" title="Annotate this record and view existing annotations"
						onclick="openAnnotationsDialog('annotationDialog','PROJECT',#url.project_id#,null);">Annotate/View Annotations</button>
					<p>There <cfif existingAnnotations.cnt EQ 1>is<cfelse>are</cfif> #existingAnnotations.cnt# annotation<cfif existingAnnotations.cnt NEQ 1>s</cfif> on this project record.</p>
				<cfelse>
					<button type="button" aria-label="Annotate" id="annotationDialogLauncher"
						class="btn btn-xs btn-info" title="Annotate this record"
						onclick="openAnnotationsDialog('annotationDialog','PROJECT',#url.project_id#,null);">Annotate</button>
					<p>There are no annotations on this project record.</p>
				</cfif>
				<div id="annotationDialog"></div>
			</cfif>
		</div>
	</section>
	</cfoutput>
</main>

<cfinclude template = "/shared/_footer.cfm">
