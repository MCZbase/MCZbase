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
<cfinclude template="/containers/component/public.cfc" runonce="true">

<!--- check validity of input values, if not valid, redirect to container search --->
<!--- either container_id or barcode must be provided --->
<cfif len(url.container_id) EQ 0 AND len(url.barcode) EQ 0>
	<cflocation url="/containers/Containers.cfm" addtoken="false">
</cfif>
<!--- if container_id is provided it must be numeric --->
<cfif len(url.container_id) GT 0 AND NOT isNumeric(url.container_id)>
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
		ct.role AS container_role,
		NVL(ch.direct_structural_children, 0) AS direct_structural_children,
		NVL(ch.direct_leaf_children, 0) AS direct_leaf_children
	FROM
		container c
		LEFT JOIN ctcontainer_type ct ON ct.container_type = c.container_type
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
<cfset variables.canEditContainers = isdefined("session.roles") AND listfindnocase(session.roles,"manage_container")>

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
	<div class="d-flex justify-content-between align-items-center flex-wrap">
		<h1 class="h2 mt-1">Container: #encodeForHtml(variables.pageTitleDisplay)#</h1>
		<cfset variables.isProxyOrLeafType = listFindNoCase("proxy,leaf", getContainer.container_role) GT 0>
		<cfset variables.isProxyOrBearerType = listFindNoCase("proxy,leafbearer", getContainer.container_role) GT 0>
		<cfset variables.currentContainerIsEmpty = (val(getContainer.direct_structural_children) + val(getContainer.direct_leaf_children)) EQ 0>
		<div class="btn-toolbar pt-1" role="toolbar" aria-label="Container actions">
			<a class="btn btn-xs btn-info mr-1 mb-1" href="/containers/Containers.cfm?container_id=#encodeForURL(getContainer.container_id)#&amp;execute=true">Browse in Hierarchy</a>
			<a class="btn btn-xs btn-secondary mr-1 mb-1" href="/containers/allContainerLeafNodes.cfm?container_id=#encodeForURL(getContainer.container_id)#">Leaf Nodes</a>
			<cfif variables.canEditContainers>
				<cfif NOT variables.isProxyOrLeafType>
					<a class="btn btn-xs btn-secondary mr-1 mb-1" href="/containers/Container.cfm?action=new&amp;parent_container_id=#encodeForURL(getContainer.container_id)#" target="_blank" rel="noopener noreferrer">Create Child of this Container</a>
					<a href="##" class="btn btn-xs btn-secondary mr-1 mb-1" onclick="event.preventDefault(); openPlaceChildIntoContainerDialog(#val(getContainer.container_id)#, '#encodeForJavaScript(variables.pageTitleDisplay)#', '#encodeForJavaScript(getContainer.institution_acronym)#', 'containerViewFeedback', 'containerContentsSection_page');">Place Child into this Container</a>
				</cfif>
				<cfif variables.isProxyOrBearerType>
					<cfset disabledClass = "">
					<cfif NOT variables.currentContainerIsEmpty>
						<cfset disabledClass = " disabled">
					</cfif>
					<a href="##" class="btn btn-xs btn-secondary mr-1 mb-1 #disabledClass#"
						<cfif NOT variables.currentContainerIsEmpty>
							aria-disabled="true"
							tabindex="-1"
						<cfelse>
							onclick="event.preventDefault(); openPlaceLeafIntoContainerDialog(#val(getContainer.container_id)#, '#encodeForJavaScript(variables.pageTitleDisplay)#', '#encodeForJavaScript(getContainer.institution_acronym)#', 'containerViewFeedback', 'containerContentsSection_page');"
						</cfif>
					>Place Part into this Container</a>
				</cfif>
				<a class="btn btn-xs btn-primary mb-1" href="/containers/Container.cfm?action=edit&amp;container_id=#encodeForURL(getContainer.container_id)#">Edit Container</a>
			</cfif>
		</div>
	</div>

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
							<th scope="col">Placement Check</th>
							<th scope="col">Actions</th>
						</tr>
					</thead>
					<tbody>
						<cfloop query="getHistory">
							<cfset variables.historyDisplay = "Unnamed container">
							<cfset variables.historyParentId = val(getHistory.parent_container_id)>
							<cfset variables.historyBadgeId = "viewContainerHistoryBadge_#getHistory.currentRow#">
							<cfset variables.historyLocateRowId = "viewContainerHistoryLocate_#getHistory.currentRow#">
							<cfset variables.historyParentExists = (variables.historyParentId GT 0 AND len(trim(getHistory.container_type)) GT 0)>
							<cfset variables.historyParentIsCurrent = (variables.historyParentId EQ val(getContainer.parent_container_id))>
							<cfset variables.historyParentIsInstitutionType = (variables.historyParentExists AND listFindNoCase("institution", getHistory.container_type) GT 0)>
							<cfset variables.currentContainerCanBeInInstitution = (listFindNoCase("building,campus", getContainer.container_type) GT 0)>
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
									<cfif variables.historyParentId GT 0>
										<a href="/containers/viewContainer.cfm?container_id=#encodeForURL(getHistory.parent_container_id)#">
											#encodeForHtml(variables.historyDisplay)#
										</a>
									<cfelse>
										<span class="text-muted">Root or unplaced</span>
									</cfif>
								</td>
								<td>
									<cfif len(trim(getHistory.container_type)) GT 0>
										#encodeForHtml(getHistory.container_type)#
									<cfelse>
										Unknown
									</cfif>
								</td>
								<td>
									<cfif variables.historyParentId GT 0>
										<div id="#encodeForHtmlAttribute(variables.historyBadgeId)#" class="small text-muted">Checking…</div>
									<cfelse>
										<span class="text-muted">n/a</span>
									</cfif>
								</td>
								<td>
									<cfif variables.historyParentExists>
										<button type="button" class="btn btn-xs btn-outline-secondary mr-1 mb-1" aria-expanded="false" onclick="toggleHistoryParentLocate(this, #val(variables.historyParentId)#, '#encodeForJavaScript(variables.historyLocateRowId)#');">Locate</button>
									</cfif>
									<cfif variables.canEditContainers>
										<cfif variables.historyParentId LTE 0>
											<span class="text-muted">n/a</span>
										<cfelseif NOT variables.historyParentExists>
											<span class="badge badge-warning">Deleted</span>
										<cfelseif variables.historyParentIsCurrent>
											<span class="badge badge-success">Current Parent</span>
										<cfelseif variables.historyParentIsInstitutionType AND NOT variables.currentContainerCanBeInInstitution>
											<span class="badge badge-light border text-muted">Not Eligible</span>
										<cfelse>
											<button type="button" class="btn btn-xs btn-secondary" onclick="putContainerBackFromHistory(#val(getContainer.container_id)#, #val(variables.historyParentId)#, '#encodeForJavaScript(variables.historyDisplay)#', 'containerViewFeedback', function(){ window.location.reload(); });">Put Back Here</button>
										</cfif>
									</cfif>
								</td>
							</tr>
						</cfloop>
					</tbody>
				</table>
			</div>
		</cfif>
	</section>

	<cfif variables.canEditContainers>
		<!--- read-only here -- logging a new check is only offered on the edit page
			(Container.cfm), which this shares getContainerCheckHistoryHtml/
			loadContainerCheckHistory with. --->
		<section class="mb-3" aria-labelledby="containerCheckHeading">
			<h2 class="h4" id="containerCheckHeading">Container Check Log</h2>
			<div id="containerCheckHistory"><div class="my-2 text-center"><img src="/shared/images/indicator.gif"> Loading...</div></div>
		</section>
	</cfif>

	<section class="mb-4">
		<output id="containerViewFeedback" aria-live="polite"></output>
	</section>

</cfoutput>

</main>
<div id="containerDetailsDialog"></div>
<cfoutput>
<script>
	$(document).ready(function() {
		<cfloop query="getHistory">
			<cfif val(getHistory.parent_container_id) GT 0>
				loadPlacementWarningBadge(#val(getContainer.container_id)#, #val(getHistory.parent_container_id)#, '#encodeForJavaScript("viewContainerHistoryBadge_#getHistory.currentRow#")#');
			</cfif>
		</cfloop>
		<cfif variables.canEditContainers>
			loadContainerCheckHistory(#val(getContainer.container_id)#);
		</cfif>
	});
</script>
</cfoutput>
<cfinclude template="/shared/_footer.cfm">
