<!---
/containers/viewContainer.cfm

View container details and placement history for a container.

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
<cfparam name="url.container_id" default=""><!--- container_id is the surrogate numeric identifier for the container to view --->
<cfparam name="url.barcode" default=""><!--- barcode uniquely identifies a container, if given has priority over container_id --->
<cf_rolecheck>
<cfinclude template="/containers/component/functions.cfc" runonce="true">

<cfif NOT isNumeric(url.container_id)>
	<cflocation url="/containers/Containers.cfm" addtoken="false">
</cfif>

<cfquery name="getContainer" datasource="user_login" username="#session.dbuser#"  password="#decrypt(session.epw,cookie.cfid)#">
	SELECT
		c.container_id,
		c.parent_container_id,
		c.container_type,
		c.label,
		c.description,
		c.parent_install_date,
		c.container_remarks,
		c.barcode,
		c.print_fg,
		c.width,
		c.height,
		c.length,
		c.number_positions,
		c.locked_position,
		c.institution_acronym,
		NVL(ch.direct_structural_children, 0) AS direct_structural_children,
		NVL(ch.direct_leaf_children, 0) AS direct_leaf_children
	FROM
		container c
		LEFT JOIN (
			SELECT
				parent_container_id,
				SUM(CASE WHEN container_type <> 'collection object' THEN 1 ELSE 0 END) AS direct_structural_children,
				SUM(CASE WHEN container_type = 'collection object' THEN 1 ELSE 0 END) AS direct_leaf_children
			FROM
				container
			GROUP BY
				parent_container_id
		) ch ON ch.parent_container_id = c.container_id
	WHERE
		<cfif len(trim(url.barcode)) GT 0>
			c.barcode = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#url.barcode#">
		<cfelse>
			c.container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#url.container_id#">
		</cfif>
</cfquery>

<cfif getContainer.recordcount EQ 0>
	<cfinclude template="/errors/404.cfm">
	<cfabort>
</cfif>

<cfquery name="getHistory" datasource="user_login" username="#session.dbuser#"  password="#decrypt(session.epw,cookie.cfid)#">
	SELECT
		ch.install_date,
		ch.parent_container_id,
		p.container_type,
		p.label,
		p.barcode
	FROM
		container_history ch
		LEFT JOIN container p ON ch.parent_container_id = p.container_id
	WHERE
		ch.container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getContainer.container_id#">
	ORDER BY
		ch.install_date DESC NULLS LAST
</cfquery>

<cfset variables.pageTitleDisplay = "Unnamed container">
<cfif len(trim(getContainer.label)) GT 0>
	<cfset variables.pageTitleDisplay = getContainer.label>
</cfif>
<cfif len(trim(getContainer.barcode)) GT 0>
	<cfset variables.pageTitleDisplay = getContainer.barcode>
	<cfif getContainer.barcode NEQ getContainer.label AND len(trim(getContainer.label)) GT 0>
		<cfset variables.pageTitleDisplay = "#variables.pageTitleDisplay# (#getContainer.label#)">
	</cfif>
</cfif>

<cfset pageTitle = "Container: #variables.pageTitleDisplay#">
<cfset pageHasContainers = true>
<cfinclude template="/shared/_header.cfm">
<link rel="stylesheet" href="/containers/css/containers.css">
<main id="content" class="container-fluid">

<cfoutput>
	<h1 class="h2">Container: #encodeForHtml(variables.pageTitleDisplay)#</h1>

	#getContainerDetailsHtml(container_id=val(getContainer.container_id), displayMode="page", idSuffix="page")#

	<section class="mb-3" aria-labelledby="placementHistoryHeading">
		<h2 class="h4" id="placementHistoryHeading">Placement History</h2>
		<cfif getHistory.recordcount EQ 0>
			<p class="text-muted">No placement history found.</p>
		<cfelse>
			<div class="table-responsive">
				<table class="table table-sm table-striped">
					<thead>
						<tr>
							<th scope="col">Date</th>
							<th scope="col">Parent Container</th>
							<th scope="col">Type</th>
						</tr>
					</thead>
					<tbody>
						<cfloop query="getHistory">
							<cfset variables.historyDisplay = "Unnamed container">
							<cfif len(trim(getHistory.label)) GT 0>
								<cfset variables.historyDisplay = getHistory.label>
							</cfif>
							<cfif len(trim(getHistory.barcode)) GT 0>
								<cfset variables.historyDisplay = getHistory.barcode>
								<cfif getHistory.barcode NEQ getHistory.label AND len(trim(getHistory.label)) GT 0>
									<cfset variables.historyDisplay = "#variables.historyDisplay# (#getHistory.label#)">
								</cfif>
							</cfif>
							<tr>
								<td>
									<cfif isDate(getHistory.install_date)>
										#encodeForHtml(dateFormat(getHistory.install_date, "yyyy-mm-dd"))#
									<cfelse>
										Unknown
									</cfif>
								</td>
								<td>
									<cfif len(trim(getHistory.parent_container_id)) GT 0>
										<a href="/containers/viewContainer.cfm?container_id=#encodeForURL(getHistory.parent_container_id)#">
											#encodeForHtml(variables.historyDisplay)#
										</a>
									<cfelse>
										Unknown
									</cfif>
								</td>
								<td>
									<cfif len(trim(getHistory.container_type)) GT 0>
										#encodeForHtml(getHistory.container_type)#
									<cfelse>
										Unknown
									</cfif>
								</td>
							</tr>
						</cfloop>
					</tbody>
				</table>
			</div>
		</cfif>
	</section>

	<section class="mb-4" aria-labelledby="containerActionsHeading">
		<h2 class="h4" id="containerActionsHeading">Actions</h2>
		<div class="btn-toolbar" role="toolbar" aria-label="Container actions">
			<button type="button" class="btn btn-xs btn-outline-primary mr-1 mb-1" onclick="openContainerDetailsDialog(#encodeForJavaScript(getContainer.container_id)#, '#encodeForJavaScript(variables.pageTitleDisplay)#', 'containerViewFeedback', false);">Details</button>
			<a class="btn btn-xs btn-primary mr-1 mb-1" href="/containers/Container.cfm?action=edit&amp;container_id=#encodeForURL(getContainer.container_id)#">Edit Container</a>
			<a class="btn btn-xs btn-info mr-1 mb-1" href="/containers/Containers.cfm?container_id=#encodeForURL(getContainer.container_id)#&amp;execute=true">Browse in Hierarchy</a>
			<a class="btn btn-xs btn-secondary mr-1 mb-1" href="/containers/allContainerLeafNodes.cfm?container_id=#encodeForURL(getContainer.container_id)#">Leaf Nodes</a>
			<a class="btn btn-xs btn-secondary mb-1" href="/findContainer.cfm?container_id=#encodeForURL(getContainer.container_id)#" target="_blank" rel="noopener noreferrer">Legacy Details</a>
		</div>
	</section>

	<section class="mb-4">
		<output id="containerViewFeedback" aria-live="polite"></output>
	</section>
</cfoutput>

</main>
<div id="containerDetailsDialog"></div>
<cfinclude template="/shared/_footer.cfm">
