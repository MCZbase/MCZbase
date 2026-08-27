<!---
containers/browseContainers.cfm

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
<cfparam name="url.action" default="">
<cfset variables.action = trim(url.action)>

<cfset pageTitle="Browse Containers">
<cfinclude template="/shared/_header.cfm">
<link rel="stylesheet" href="/containers/css/containers.css">

<!--- viewable by this page's own manage_specimens role (enforced by /shared/_header.cfm above);
	the qc action's placement-problem list additionally requires manage_container below, since
	every link in that section leads straight to editing a container. --->
<cfset variables.canEditContainers = isdefined("session.roles") AND listfindnocase(session.roles,"manage_container")>

<!--- gates the qc action's mention of Container Diagnostics -- that page is itself only on the
	admin menu (shared/_header.cfm, includes/_header.cfm) for collops, so pointing someone
	without collops at it would be a dead end. --->
<cfset variables.canSeeContainerDiagnostics = isdefined("session.roles") AND listfindnocase(session.roles,"collops")>

<!--- the fixture-equivalent container types (fixture, the various freezer subtypes, cryovat,
	tank) used both by the qc-adjacent department-prefix picker below and by the links it
	produces into Containers.cfm's container_type search field. Resolved from ctcontainer_type
	rather than hardcoded, since there is more than one freezer subtype. --->
<cfquery name="fixtureTypes" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	SELECT container_type
	FROM ctcontainer_type
	WHERE
		container_type = 'fixture'
		OR container_type LIKE '%freezer'
		OR container_type = 'cryovat'
		OR container_type = 'tank'
	ORDER BY container_type
</cfquery>
<cfset variables.fixtureEquivalentTypes = valueList(fixtureTypes.container_type)>

<!--- department-prefix labels (e.g. "Mala", "Herp") often, but not always, coincide with a
	collection_cde -- looked up here so the department picker below can say which of its
	prefixes are actually collections vs. incidental label-prefix matches. --->
<cfquery name="ctcollection" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	SELECT collection_cde, institution_acronym, collection
	FROM collection
</cfquery>
<cfset variables.collectionByCde = structNew()>
<cfloop query="ctcollection">
	<cfset variables.collectionByCde[ucase(ctcollection.collection_cde)] = ctcollection.institution_acronym & ":" & ctcollection.collection>
</cfloop>

<cfoutput>
	<main class="container" id="content">
		<h1 class="h3">Browse Containers</h1>
		<div class="row">
			<div class="col-12">
				<p>
					Look up storage locations such as fixtures, freezers, cryovats, and tanks by
					department, or (if you have permission) review a short list of containers that
					still need to be placed.
				</p>
			</div>
		</div>
		<cfswitch expression="#variables.action#">
			<cfcase value="qc">
				<cfif variables.canEditContainers>
					<h2 class="h4">Container placement problems</h2>
					<div class="row">
						<div class="col-12">
							<p>
								A short, curated list of containers that sit directly under the Museum
								or a campus root without being placed in a proper parent container --
								specific, already-known placement problems worth fixing by hand.
								<cfif variables.canSeeContainerDiagnostics>
									This is not an exhaustive report; see
									<a href="/containers/containerDiagnostics.cfm">Container Diagnostics</a>
									for that.
								</cfif>
							</p>
							<p>
								Individual containers are listed below only when fewer than 100 exist for
								a type; types with 100 or more are linked to a search instead.
							</p>
							<!---  parent_container_id = 0 are root containers, these should just be The Museum of Comparative Zoology and Deaccessioned (type = external).
							parent_container_id = 1 are containers within The Museum of Comparative Zoology (target is just the MCZ-campus and CFS-campus). Institutions are
							also expected to sit at the root the same way campus/external containers do, and are excluded here for the same reason. --->
							<cfquery name="parentlessNodes" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
								SELECT count(*) ct, container_type
								FROM container
								WHERE parent_container_id < 2 and container_type not in ('campus','external','institution')
								GROUP BY container_type
							</cfquery>
							<ul>
								<cfloop query="parentlessNodes">
									<cfif parentlessNodes.ct LT 100>
										<cfquery name="plNode" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
											SELECT container_id, label, container_type
											FROM container
											WHERE parent_container_id < 2 and container_type not in ('campus','external','institution')
												and container_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#parentlessNodes.container_type#">
										</cfquery>
										<li>
											#encodeForHtml(parentlessNodes.container_type)# (#parentlessNodes.ct#)
											<ul>
												<cfloop query="plNode">
													<li><a href="/containers/Container.cfm?action=edit&amp;container_id=#encodeForUrl(plNode.container_id)#">#encodeForHtml(plNode.label)#</a></li>
												</cfloop>
											</ul>
										</li>
									<cfelse>
										<li>
											#encodeForHtml(parentlessNodes.container_type)# (#parentlessNodes.ct#) --
											<a href="/containers/Containers.cfm?container_type=#encodeForUrl(parentlessNodes.container_type)#&amp;execute=true">search</a>
										</li>
									</cfif>
								</cfloop>
							</ul>
						</div>
					</div>
				</cfif>
			</cfcase>
			<cfdefaultcase>
				<!--- find list of departments (first few characters of fixture-equivalent container labels) --->
				<cfquery name="fixturePrefixes" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT count(*) as ct, nvl(nvl(substr(label,0, instr(label,'_')-1),substr(label,0, instr(label,'-')-1)),substr(label,0, 4)) as prefix
					FROM container
					WHERE container_type IN (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.fixtureEquivalentTypes#" list="true">)
					GROUP BY nvl(nvl(substr(label,0, instr(label,'_')-1),substr(label,0, instr(label,'-')-1)),substr(label,0, 4))
				</cfquery>
				<div class="row">
					<div class="col-12">
						<ul>
							<cfif variables.canEditContainers>
								<li><a href="/containers/browseContainers.cfm?action=qc">Container placement problems</a></li>
							</cfif>
							<li>List fixtures, freezers, cryovats, and tanks starting with:</li>
							<ul class="department-prefix-list">
								<cfloop query="fixturePrefixes">
									<cfset variables.matchedCollection = "">
									<cfif structKeyExists(variables.collectionByCde, ucase(fixturePrefixes.prefix))>
										<cfset variables.matchedCollection = variables.collectionByCde[ucase(fixturePrefixes.prefix)]>
									</cfif>
									<li>
										<a href="/containers/Containers.cfm?department=#encodeForUrl(fixturePrefixes.prefix)#&amp;container_type=#encodeForUrl(variables.fixtureEquivalentTypes)#&amp;execute=true">#encodeForHtml(fixturePrefixes.prefix)# (#fixturePrefixes.ct#)</a>
										<cfif len(variables.matchedCollection) GT 0>
											#encodeForHtml(variables.matchedCollection)#
										<cfelse>
											<strong>Not a collection</strong>
										</cfif>
									</li>
								</cfloop>
							</ul>
						</ul>
					</div>
				</div>
			</cfdefaultcase>
		</cfswitch>
	</main>
</cfoutput>
<cfinclude template="/shared/_footer.cfm">
