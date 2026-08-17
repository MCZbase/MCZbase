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
Details page for a single project, replacing ProjectDetail.cfm.
--->
<cfparam name="url.project_id" default="">

<!--- errors/missing.cfm's /project/{name} route sets niceProjName (unscoped), matching
      taxonomy/showTaxonomy.cfm's scientific_name convention for /name/{name}, then
      includes this page. niceURL() (shared/functionLib.cfm) is a CF UDF, not an Oracle
      function, and can't run as inline SQL text inside a query -- resolve by reversing
      its space-to-dash substitution instead, and matching project_name exactly. --->
<cfif len(url.project_id) EQ 0 AND isdefined("niceProjName") AND len(niceProjName) GT 0>
	<cfset earlyCanManageProjects = false>
	<cfif isdefined("session.roles") AND listfindnocase(session.roles,"coldfusion_user")>
		<cfset earlyCanManageProjects = true>
	</cfif>
	<cfset decodedProjName = replace(URLDecode(niceProjName),"-"," ","all")>
	<cfquery name="resolveNiceProjName" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		SELECT project_id
		FROM project
		WHERE LOWER(project_name) = LOWER(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#decodedProjName#">)
		<cfif NOT earlyCanManageProjects>
			AND mask_project_fg = 0
		</cfif>
	</cfquery>
	<cfif resolveNiceProjName.recordcount EQ 1>
		<cfset url.project_id = resolveNiceProjName.project_id>
	</cfif>
</cfif>

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
<cfinclude template="/annotations/component/public.cfc" runOnce="true"><!--- for getProjectAnnotationCardBodyHtml() --->
<cfinclude template="/shared/component/functions.cfc" runOnce="true"><!--- for getGuidLink() --->

<cfset canManageProjects = false>
<cfset canManageTransactions = false>
<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
	<cfset oneOfUs = 1>
	<cfif listfindnocase(session.roles,"manage_projects")>
		<cfset canManageProjects = true>
	</cfif>
	<cfif listfindnocase(session.roles,"manage_transactions")>
		<cfset canManageTransactions = true>
	</cfif>
<cfelse>
	<cfset oneOfUs = 0>
</cfif>

<!---
Builds a /Specimens.cfm search-builder URL: an OR-group across orValues (each matched
against orField), optionally AND-ed with an exact-match CATALOGED_ITEM:COLLECTION_CDE
clause. Parens are only emitted around the OR-group when it has more than one member --
the builder needs them to keep that group scoped against the collection clause that
follows, but a single term needs no grouping.
--->
<cffunction name="buildSpecimenBuilderSearchUrl" returntype="string">
	<cfargument name="orField" type="string" required="yes">
	<cfargument name="orValues" type="array" required="yes">
	<cfargument name="collectionCde" type="string" required="no" default="">
	<cfset var orCount = ArrayLen(arguments.orValues)>
	<cfset var totalRows = orCount>
	<cfif len(arguments.collectionCde) GT 0>
		<cfset totalRows = totalRows + 1>
	</cfif>
	<cfset var searchUrl = "/Specimens.cfm?execute=true&action=builderSearch&builderMaxRows=#totalRows#">
	<cfset var i = 0>
	<cfloop array="#arguments.orValues#" index="orValue">
		<cfset i = i + 1>
		<cfset var openParen = 0>
		<cfset var closeParen = 0>
		<cfif orCount GT 1 AND i EQ 1>
			<cfset openParen = 1>
		</cfif>
		<cfif orCount GT 1 AND i EQ orCount>
			<cfset closeParen = 1>
		</cfif>
		<cfif i GT 1>
			<cfset searchUrl = searchUrl & "&JoinOperator#i#=or">
		</cfif>
		<cfset searchUrl = searchUrl & "&openParens#i#=#openParen#&field#i#=#EncodeForUrl(arguments.orField)#&searchText#i#=#EncodeForUrl(orValue)#&closeParens#i#=#closeParen#">
	</cfloop>
	<cfif len(arguments.collectionCde) GT 0>
		<cfset i = i + 1>
		<cfset searchUrl = searchUrl & "&JoinOperator#i#=and&openParens#i#=0&field#i#=#EncodeForUrl('CATALOGED_ITEM:COLLECTION_CDE')#&searchText#i#=#EncodeForUrl('=' & arguments.collectionCde)#&closeParens#i#=0">
	</cfif>
	<cfreturn searchUrl>
</cffunction>

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
				project_remarks,
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

	<cfset projectNameForSearch = ArrayNew(1)>
	<cfset ArrayAppend(projectNameForSearch, getProject.project_name)>

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

	<!--- Specimens used: specimens on loan to this project, either directly or as a
	      sub-part derived from a loaned item. --->
	<cfquery name="getSpecimensUsed" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getSpecimensUsed_result">
		SELECT
			collection.collection,
			collection.collection_id,
			collection.collection_cde,
			COUNT(DISTINCT(cataloged_item.collection_object_id)) AS c
		FROM
			cataloged_item
			join collection on cataloged_item.collection_id = collection.collection_id
			join specimen_part on specimen_part.derived_from_cat_item = cataloged_item.collection_object_id
			join loan_item on specimen_part.collection_object_id = loan_item.collection_object_id
			join project_trans on loan_item.transaction_id = project_trans.transaction_id
		WHERE
			project_trans.project_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#url.project_id#">
		GROUP BY
			collection.collection,
			collection.collection_id,
			collection.collection_cde
		UNION
		SELECT
			collection.collection,
			collection.collection_id,
			collection.collection_cde,
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
			collection.collection_id,
			collection.collection_cde
	</cfquery>
	<cfquery name="specUsedTotal" dbtype="query">
		SELECT SUM(c) AS totspec FROM getSpecimensUsed
	</cfquery>
	<cfquery name="specUsedCollections" dbtype="query">
		SELECT collection FROM getSpecimensUsed GROUP BY collection
	</cfquery>

	<!--- Individual specimen guids, only rendered per-collection below when that
	      collection's count is small enough to list individually. --->
	<cfquery name="getSpecimensUsedGuids" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getSpecimensUsedGuids_result">
		SELECT DISTINCT
			collection.collection_id,
			flatTableName.guid
		FROM
			cataloged_item
			join collection on cataloged_item.collection_id = collection.collection_id
			join <cfif ucase(session.flatTableName) EQ 'FLAT'>flat<cfelse>filtered_flat</cfif> flatTableName on cataloged_item.collection_object_id = flatTableName.collection_object_id
			join specimen_part on specimen_part.derived_from_cat_item = cataloged_item.collection_object_id
			join loan_item on specimen_part.collection_object_id = loan_item.collection_object_id
			join project_trans on loan_item.transaction_id = project_trans.transaction_id
		WHERE
			project_trans.project_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#url.project_id#">
		UNION
		SELECT DISTINCT
			collection.collection_id,
			flatTableName.guid
		FROM
			cataloged_item
			join collection on cataloged_item.collection_id = collection.collection_id
			join <cfif ucase(session.flatTableName) EQ 'FLAT'>flat<cfelse>filtered_flat</cfif> flatTableName on cataloged_item.collection_object_id = flatTableName.collection_object_id
			join loan_item on cataloged_item.collection_object_id = loan_item.collection_object_id
			join project_trans on loan_item.transaction_id = project_trans.transaction_id
		WHERE
			project_trans.project_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#url.project_id#">
	</cfquery>

	<!--- Loan numbers this project is linked to, needed (regardless of role) to build
	      Specimens Used search-builder links; the Loans card itself, with full detail,
	      stays manage_transactions-gated below. --->
	<cfquery name="getLoanNumbersForSearch" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getLoanNumbersForSearch_result">
		SELECT DISTINCT
			loan.loan_number
		FROM
			project_trans
			join loan_item on project_trans.transaction_id = loan_item.transaction_id
			join loan on loan_item.transaction_id = loan.transaction_id
		WHERE
			project_trans.project_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#url.project_id#">
		ORDER BY
			loan.loan_number
	</cfquery>
	<cfset loanNumbersForSearch = ValueArray(getLoanNumbersForSearch, "loan_number")>

	<!--- Specimens contributed: specimens accessioned through this project. --->
	<cfquery name="getSpecimensContributed" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getSpecimensContributed_result">
		SELECT
			collection,
			collection.collection_id,
			collection.collection_cde,
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
			collection.collection_id,
			collection.collection_cde
	</cfquery>
	<cfquery name="specContTotal" dbtype="query">
		SELECT SUM(c) AS totspec FROM getSpecimensContributed
	</cfquery>
	<cfquery name="specContCollections" dbtype="query">
		SELECT collection FROM getSpecimensContributed GROUP BY collection
	</cfquery>

	<!--- Individual specimen guids, only rendered per-collection below when that
	      collection's count is small enough to list individually. --->
	<cfquery name="getSpecimensContributedGuids" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getSpecimensContributedGuids_result">
		SELECT DISTINCT
			collection.collection_id,
			flatTableName.guid
		FROM
			project
			join project_trans on project.project_id = project_trans.project_id
			join accn on project_trans.transaction_id = accn.transaction_id
			join cataloged_item on accn.transaction_id = cataloged_item.accn_id
			join collection on cataloged_item.collection_id = collection.collection_id
			join <cfif ucase(session.flatTableName) EQ 'FLAT'>flat<cfelse>filtered_flat</cfif> flatTableName on cataloged_item.collection_object_id = flatTableName.collection_object_id
		WHERE
			project.project_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#url.project_id#">
	</cfquery>

	<cfif canManageTransactions>
		<!--- Loans through which this project used specimens, directly or via a derived
		      part. --->
		<cfquery name="getLoans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getLoans_result">
			SELECT DISTINCT
				loan.transaction_id,
				loan.loan_number,
				loan.loan_status,
				TO_CHAR(trans.trans_date,'YYYY-MM-DD') AS trans_date,
				concattransagent(loan.transaction_id,'recipient institution') AS recipient_agent,
				project_trans.project_trans_remarks
			FROM
				project_trans
				join loan_item on project_trans.transaction_id = loan_item.transaction_id
				join loan on loan_item.transaction_id = loan.transaction_id
				left join trans on loan.transaction_id = trans.transaction_id
			WHERE
				project_trans.project_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#url.project_id#">
			ORDER BY
				loan.loan_number
		</cfquery>

		<!--- Accessions through which this project contributed specimens. --->
		<cfquery name="getAccessions" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getAccessions_result">
			SELECT DISTINCT
				accn.transaction_id,
				accn.accn_number,
				accn.accn_status,
				TO_CHAR(trans.trans_date,'YYYY-MM-DD') AS trans_date,
				concattransagent(accn.transaction_id,'received from') AS rec_agent,
				project_trans.project_trans_remarks
			FROM
				project_trans
				join accn on project_trans.transaction_id = accn.transaction_id
				left join trans on accn.transaction_id = trans.transaction_id
			WHERE
				project_trans.project_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#url.project_id#">
			ORDER BY
				accn.accn_number
		</cfquery>
	</cfif>

	<!--- Other projects whose contributed specimens this project's loans derive parts
	      from. --->
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
							join project_trans on project.project_id = project_trans.project_id
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

	<!--- Other projects that borrowed parts derived from specimens this project
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

	<cfquery name="getTaxa" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getTaxa_result">
		SELECT
			taxonomy.taxon_name_id,
			scientific_name,
			display_name,
			author_text,
			phylclass,
			family,
			taxonid,
			taxonid_guid_type
		FROM
			project_taxonomy
			join taxonomy on project_taxonomy.taxon_name_id = taxonomy.taxon_name_id
		WHERE
			project_taxonomy.project_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#url.project_id#">
	</cfquery>

	<cfoutput>
	<div class="row mx-0">
		<div class="col-12 px-1">
			<div class="d-flex align-items-start justify-content-between flex-wrap">
				<div>
					<h1 class="h2 mt-3">#encodeForHtml(getProject.project_name)#</h1>
				</div>
				<cfif canManageProjects>
					<div class="mt-2 ml-2 flex-shrink-0">
						<a class="btn btn-xs btn-primary" href="/projects/Project.cfm?action=edit&project_id=#getProject.project_id#">Edit Project</a>
					</div>
				</cfif>
			</div>

			<cfif getSponsors.recordcount GT 0>
				<p class="h5">
					Sponsored by
					<cfloop query="getSponsors">
						#encodeForHtml(agent_name)#<cfif len(acknowledgement) GT 0>: #encodeForHtml(acknowledgement)#</cfif><cfif getSponsors.currentRow LT getSponsors.recordcount>; </cfif>
					</cfloop>
				</p>
			</cfif>

			<p>#encodeForHtml(getProject.project_description)#</p>

			<cfif oneOfUs EQ 1 AND len(getProject.project_remarks) GT 0>
				<div class="card mb-2 bg-light">
					<div class="card-header py-0">
						<h2 class="h4 my-1 mx-2 px-2">Remarks</h2>
					</div>
					<div class="card-body py-2">
						<p class="mb-0">#encodeForHtml(getProject.project_remarks)#</p>
					</div>
				</div>
			</cfif>

			<cfif getPublications.recordcount GT 0>
				<div class="card mb-2 bg-light">
					<div class="card-header py-0">
						<h2 class="h4 my-1 mx-2 px-2">Publications</h2>
					</div>
					<div class="card-body py-2">
						<p>This project produced #getPublications.recordcount# publication<cfif getPublications.recordcount NEQ 1>s</cfif>.</p>
						<ul class="list-group">
							<cfloop query="getPublications">
								<li class="list-group-item">
									#encodeForHtml(formatted_publication)#
									<cfif numCit GT 0>
										&mdash; <a href="/SpecimenResults.cfm?publication_id=#publication_id#">#numCit# cited specimen<cfif numCit NEQ 1>s</cfif></a>
									</cfif>
									&mdash; <a href="/publications/showPublication.cfm?publication_id=#publication_id#">Details</a>
								</li>
							</cfloop>
						</ul>
					</div>
				</div>
			</cfif>
		</div>
	</div>

	<div class="row mx-0 mt-2">
		<div class="col-12 col-md-6 px-0 px-md-1">
			<div class="card mb-2 bg-light">
				<div class="card-header py-0">
					<h2 class="h4 my-1 mx-2 px-2">Agents</h2>
				</div>
				<div class="card-body py-2">
					<cfif getParticipants.recordcount GT 0>
						<ul class="list-group">
							<cfloop query="getParticipants">
								<li class="list-group-item"><strong>#encodeForHtml(project_agent_role)#: </strong> <a href="/agents/Agent.cfm?agent_id=#agent_id#">#encodeForHtml(agent_name)#</a></li>
							</cfloop>
						</ul>
					<cfelse>
						<p class="mb-0">None.</p>
					</cfif>
				</div>
			</div>

			<div class="card mb-2 bg-light">
				<div class="card-header py-0">
					<h2 class="h4 my-1 mx-2 px-2">Duration</h2>
				</div>
				<div class="card-body py-2">
					<p class="mb-0">#dateformat(getProject.start_date,"yyyy-mm-dd")# to #dateformat(getProject.end_date,"yyyy-mm-dd")#</p>
				</div>
			</div>

			<cfif oneOfUs EQ 1>
				<cfif getProject.mask_project_fg EQ 1>
					<cfset visibility = "Hidden">
				<cfelse>
					<cfset visibility = "Public">
				</cfif>
				<div class="card mb-2 bg-light">
					<div class="card-header py-0">
						<h2 class="h4 my-1 mx-2 px-2">Visibility</h2>
					</div>
					<div class="card-body py-2">
						<p class="mb-0">#visibility#</p>
					</div>
				</div>
			</cfif>

			<div class="card mb-2 bg-light">
				<div class="card-header py-0">
					<h2 class="h4 my-1 mx-2 px-2">Taxa linked to this Project</h2>
				</div>
				<div class="card-body py-2">
					<cfif getTaxa.recordcount GT 0>
						<ul class="list-group">
							<cfloop query="getTaxa">
								<cfset taxonidLink = "">
								<cfif len(getTaxa.taxonid) gt 0>
									<cfset link = getGuidLink(guid=#getTaxa.taxonid#,guid_type=#getTaxa.taxonid_guid_type#)>
									<cfset taxonidLink = " #link#" >
								</cfif>
								<li class="list-group-item text-nowrap">
									<cfif len(trim(getTaxa.phylclass)) GT 0>#encodeForHtml(trim(getTaxa.phylclass))# : </cfif><cfif len(trim(getTaxa.family)) GT 0>#encodeForHtml(trim(getTaxa.family))# : </cfif><a href="/name/#EncodeForURL(scientific_name)#">#getTaxa.display_name#</a> <span class="sm-caps d-inline">#encodeForHtml(author_text)#</span>#taxonidLink#
								</li>
							</cfloop>
						</ul>
					<cfelse>
						<p class="mb-0">None.</p>
					</cfif>
				</div>
			</div>

			<cfif len(session.username) GT 0>
				<cfquery name="existingAnnotations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="existingAnnotations_result">
					SELECT
						COUNT(*) AS cnt
					FROM
						annotations
					WHERE
						target_table = 'PROJECT'
						AND target_primary_key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#url.project_id#">
						<cfif NOT canManageProjects>
							AND (mask_annotation_fg = 0 OR cf_username = <cfqueryparam value="#session.username#" cfsqltype="CF_SQL_VARCHAR">)
						</cfif>
				</cfquery>
				<div id="projectAnnotationDialog"></div>
				<script type="text/javascript">
					function reloadProjectAnnotationCardBody() {
						$.ajax({
							url: '/annotations/component/public.cfc',
							data: { method: 'getProjectAnnotationCardBodyHtml', project_id: #url.project_id# },
							success: function(result) { $('##projectAnnotationsCardBodyWrap').html(result); },
							error: function(jqXHR, textStatus, error) { handleFail(jqXHR, textStatus, error, 'reloading project annotations'); },
							dataType: 'html'
						});
					}
				</script>
				<section class="accordion" id="projectAnnotationsSection">
					<div class="card mb-2 bg-light">
						<div class="card-header" id="projectAnnotationsHeader">
							<h2 class="h4 my-0">
								<button type="button" class="headerLnk text-left w-100 h-100" data-toggle="collapse" data-target="##projectAnnotationsCardBodyWrap" aria-expanded="true" aria-controls="projectAnnotationsCardBodyWrap">
									Annotations (#existingAnnotations.cnt#)
								</button>
								<cfif canManageProjects AND existingAnnotations.cnt GT 0>
									<a href="javascript:void(0)" role="button" aria-label="Edit Annotations" class="btn btn-xs small py-0 anchorFocus" onclick="openAnnotationsDialog('projectAnnotationDialog','PROJECT',#url.project_id#,reloadProjectAnnotationCardBody);">
										Edit Annotations
									</a>
								<cfelse>
									<a href="javascript:void(0)" role="button" class="btn btn-xs small py-0 anchorFocus" onclick="openAnnotationsDialog('projectAnnotationDialog','PROJECT',#url.project_id#,reloadProjectAnnotationCardBody);">
										Annotate
									</a>
								</cfif>
							</h2>
						</div>
						<div id="projectAnnotationsCardBodyWrap" class="collapse show" aria-labelledby="projectAnnotationsHeader" data-parent="##projectAnnotationsSection">
							#getProjectAnnotationCardBodyHtml(project_id=val(url.project_id))#
						</div>
					</div>
				</section>
			</cfif>
		</div>

		<div class="col-12 col-md-6 px-0 px-md-1">
			<cfif canManageTransactions>
				<div class="card mb-2 bg-light">
					<div class="card-header py-0">
						<h2 class="h4 my-1 mx-2 px-2">Loans</h2>
					</div>
					<div class="card-body py-2">
						<cfif getLoans.recordcount GT 0>
							<ul class="list-group">
								<cfloop query="getLoans">
									<li class="list-group-item">
										<a href="/transactions/Loan.cfm?action=editLoan&transaction_id=#transaction_id#" target="_blank">#encodeForHtml(loan_number)#</a>
										&mdash; #encodeForHtml(loan_status)#<cfif len(trans_date) GT 0>, #trans_date#</cfif><cfif len(recipient_agent) GT 0>, loaned to #encodeForHtml(recipient_agent)#</cfif>
										<cfif oneOfUs EQ 1 AND len(project_trans_remarks) GT 0><span class="d-block small mb-0">#encodeForHtml(project_trans_remarks)#</span></cfif>
									</li>
								</cfloop>
							</ul>
						<cfelse>
							<p class="mb-0">None.</p>
						</cfif>
					</div>
				</div>
			</cfif>

			<div class="card mb-2 bg-light">
				<div class="card-header py-0">
					<h2 class="h4 my-1 mx-2 px-2">Specimens Used</h2>
				</div>
				<div class="card-body py-2">
					<cfif getSpecimensUsed.recordcount GT 0>
						<ul class="list-group">
							<cfloop query="getSpecimensUsed">
								<li class="list-group-item">
									<a href="#buildSpecimenBuilderSearchUrl(orField='LOAN:LOAN_NUMBER', orValues=loanNumbersForSearch, collectionCde=collection_cde)#">#c# #encodeForHtml(collection)# specimen<cfif c NEQ 1>s</cfif></a>
									<a href="/bnhmMaps/bnhmMapData.cfm?loan_project_id=#url.project_id#&collection_id=#collection_id#">[ BerkeleyMapper ]</a>
									<cfif c LT 11>
										<cfquery name="theseUsedGuids" dbtype="query">
											SELECT guid FROM getSpecimensUsedGuids WHERE collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_id#">
										</cfquery>
										<ul class="list-group mt-1">
											<cfloop query="theseUsedGuids">
												<li class="list-group-item py-1"><a href="/guid/#EncodeForURL(guid)#" target="_blank">#encodeForHtml(guid)#</a></li>
											</cfloop>
										</ul>
									</cfif>
								</li>
							</cfloop>
							<cfif specUsedCollections.recordcount GT 1>
								<li class="list-group-item">
									<a href="#buildSpecimenBuilderSearchUrl(orField='LOAN:LOAN_NUMBER', orValues=loanNumbersForSearch)#">#specUsedTotal.totspec# total specimens</a>
									<a href="/bnhmMaps/bnhmMapData.cfm?loan_project_id=#url.project_id#">[ BerkeleyMapper ]</a>
								</li>
							</cfif>
						</ul>
					<cfelse>
						<p class="mb-0">None.</p>
					</cfif>
				</div>
			</div>

			<cfif canManageTransactions>
				<div class="card mb-2 bg-light">
					<div class="card-header py-0">
						<h2 class="h4 my-1 mx-2 px-2">Accessions</h2>
					</div>
					<div class="card-body py-2">
						<cfif getAccessions.recordcount GT 0>
							<ul class="list-group">
								<cfloop query="getAccessions">
									<li class="list-group-item">
										<a href="/transactions/Accession.cfm?action=edit&transaction_id=#transaction_id#" target="_blank">#encodeForHtml(accn_number)#</a>
										&mdash; #encodeForHtml(accn_status)#<cfif len(trans_date) GT 0>, #trans_date#</cfif><cfif len(rec_agent) GT 0>, received from #encodeForHtml(rec_agent)#</cfif>
										<cfif oneOfUs EQ 1 AND len(project_trans_remarks) GT 0><span class="d-block small mb-0">#encodeForHtml(project_trans_remarks)#</span></cfif>
									</li>
								</cfloop>
							</ul>
						<cfelse>
							<p class="mb-0">None.</p>
						</cfif>
					</div>
				</div>
			</cfif>

			<div class="card mb-2 bg-light">
				<div class="card-header py-0">
					<h2 class="h4 my-1 mx-2 px-2">Specimens Contributed</h2>
				</div>
				<div class="card-body py-2">
					<cfif getSpecimensContributed.recordcount GT 0>
						<ul class="list-group">
							<cfloop query="getSpecimensContributed">
								<li class="list-group-item">
									<a href="#buildSpecimenBuilderSearchUrl(orField='VIEW_CI_PROJECT:PROJECT_NAME', orValues=projectNameForSearch, collectionCde=collection_cde)#">#c# #encodeForHtml(collection)# specimen<cfif c NEQ 1>s</cfif></a>
									<a href="/bnhmMaps/bnhmMapData.cfm?project_id=#url.project_id#&collection_id=#collection_id#">[ BerkeleyMapper ]</a>
									<cfif c LT 11>
										<cfquery name="theseContGuids" dbtype="query">
											SELECT guid FROM getSpecimensContributedGuids WHERE collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_id#">
										</cfquery>
										<ul class="list-group mt-1">
											<cfloop query="theseContGuids">
												<li class="list-group-item py-1"><a href="/guid/#EncodeForURL(guid)#" target="_blank">#encodeForHtml(guid)#</a></li>
											</cfloop>
										</ul>
									</cfif>
								</li>
							</cfloop>
							<cfif specContCollections.recordcount GT 1>
								<li class="list-group-item">
									<a href="#buildSpecimenBuilderSearchUrl(orField='VIEW_CI_PROJECT:PROJECT_NAME', orValues=projectNameForSearch)#">#specContTotal.totspec# total specimens</a>
									<a href="/bnhmMaps/bnhmMapData.cfm?project_id=#url.project_id#">[ BerkeleyMapper ]</a>
								</li>
							</cfif>
						</ul>
					<cfelse>
						<p class="mb-0">None.</p>
					</cfif>
				</div>
			</div>

			<div class="card mb-2 bg-light">
				<div class="card-header py-0">
					<h2 class="h4 my-1 mx-2 px-2">Related Projects Contributing Specimens</h2>
				</div>
				<div class="card-body py-2">
					<cfif getContributingProjects.recordcount GT 0>
						<ul class="list-group">
							<cfloop query="getContributingProjects">
								<li class="list-group-item"><a href="/projects/showProject.cfm?project_id=#project_id#">#encodeForHtml(project_name)#</a></li>
							</cfloop>
						</ul>
					<cfelse>
						<p class="mb-0">None.</p>
					</cfif>
				</div>
			</div>

			<div class="card mb-2 bg-light">
				<div class="card-header py-0">
					<h2 class="h4 my-1 mx-2 px-2">Related Projects Using Contributed Specimens</h2>
				</div>
				<div class="card-body py-2">
					<cfif getUsingProjects.recordcount GT 0>
						<ul class="list-group">
							<cfloop query="getUsingProjects">
								<li class="list-group-item"><a href="/projects/showProject.cfm?project_id=#project_id#">#encodeForHtml(project_name)#</a></li>
							</cfloop>
						</ul>
					<cfelse>
						<p class="mb-0">None.</p>
					</cfif>
				</div>
			</div>

			<div class="card mb-2 bg-light">
				<div class="card-header py-0">
					<h2 class="h4 my-1 mx-2 px-2">Media</h2>
				</div>
				<div class="card-body py-2">
					<cfif getMedia.recordcount GT 0>
						<div class="row">
							<cfloop query="getMedia">
								<div class="col-12 col-sm-6 mb-3">
									#getMediaBlockHtml(media_id=media_id, displayAs="thumb", captionAs="textShort")#
								</div>
							</cfloop>
						</div>
					<cfelse>
						<p class="mb-0">None.</p>
					</cfif>
				</div>
			</div>

		</div>
	</div>
	</cfoutput>
</main>

<cfinclude template = "/shared/_footer.cfm">
