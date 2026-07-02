<!---
/containers/viewContainer.cfm

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
<cfparam name="url.container_id" default="">
<cfparam name="url.mode" default="">
<cf_rolecheck>

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
		c.container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#url.container_id#">
</cfquery>

<cfif getContainer.recordcount EQ 0>
	<cfinclude template="/errors/404.cfm">
	<cfabort>
</cfif>

<cfquery name="getParent" datasource="user_login" username="#session.dbuser#"  password="#decrypt(session.epw,cookie.cfid)#">
	SELECT
		container_id,
		parent_container_id,
		container_type,
		label,
		description,
		barcode,
		institution_acronym
	FROM
		container
	WHERE
		container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getContainer.parent_container_id#">
</cfquery>

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
		ch.container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#url.container_id#">
	ORDER BY
		ch.install_date DESC NULLS LAST
</cfquery>

<cfset variables.containerSearch = createObject("component", "containers.component.search")>
<cfset variables.breadcrumb = deserializeJSON(variables.containerSearch.getContainerBreadcrumb(container_id=val(url.container_id)))>
<cfset variables.pageHeading = getContainer.label>
<cfif len(trim(getContainer.barcode)) GT 0 AND getContainer.barcode NEQ getContainer.label>
	<cfset variables.pageHeading = "#variables.pageHeading# (#getContainer.barcode#)">
</cfif>

<cfif url.mode NEQ "fragment">
	<cfset pageTitle = "Container: #getContainer.label#">
	<cfset pageHasContainers = true>
	<cfinclude template="/shared/_header.cfm">
	<link rel="stylesheet" href="/containers/css/containers.css">
	<main id="content" class="container-fluid">
</cfif>

<cfoutput>
	<nav aria-label="Container breadcrumb" class="mb-3">
		<cfif arrayLen(variables.breadcrumb) GT 0>
			<cfloop from="1" to="#arrayLen(variables.breadcrumb)#" index="variables.i">
				<cfset variables.crumb = variables.breadcrumb[variables.i]>
				<a href="/containers/viewContainer.cfm?container_id=#encodeForURL(variables.crumb.container_id)#">
					#encodeForHtml(variables.crumb.container_type)#: #encodeForHtml(variables.crumb.label)#
				</a><cfif variables.i LT arrayLen(variables.breadcrumb)> &gt; </cfif>
			</cfloop>
		</cfif>
	</nav>

	<h1 class="h2">#encodeForHtml(variables.pageHeading)#</h1>

	<section class="mb-3" aria-labelledby="containerDetailsHeading">
		<h2 class="h4" id="containerDetailsHeading">Details</h2>
		<div class="form-row">
			<div class="col-12 col-md-6 col-xl-4 mb-2">
				<strong>Container Type:</strong> #encodeForHtml(getContainer.container_type)#
			</div>
			<div class="col-12 col-md-6 col-xl-4 mb-2">
				<strong>Label:</strong> #encodeForHtml(getContainer.label)#
			</div>
			<cfif len(trim(getContainer.barcode)) GT 0>
				<div class="col-12 col-md-6 col-xl-4 mb-2">
					<strong>Barcode:</strong> #encodeForHtml(getContainer.barcode)#
				</div>
			</cfif>
			<cfif len(trim(getContainer.description)) GT 0>
				<div class="col-12 col-md-6 col-xl-4 mb-2">
					<strong>Description:</strong> #encodeForHtml(getContainer.description)#
				</div>
			</cfif>
			<cfif len(trim(getContainer.container_remarks)) GT 0>
				<div class="col-12 col-md-6 col-xl-4 mb-2">
					<strong>Container Remarks:</strong> #encodeForHtml(getContainer.container_remarks)#
				</div>
			</cfif>
			<cfif len(trim(getContainer.width)) GT 0 OR len(trim(getContainer.height)) GT 0 OR len(trim(getContainer.length)) GT 0>
				<div class="col-12 col-md-6 col-xl-4 mb-2">
					<strong>Width × Height × Length (cm):</strong>
					#encodeForHtml(getContainer.width)# × #encodeForHtml(getContainer.height)# × #encodeForHtml(getContainer.length)#
				</div>
			</cfif>
			<cfif len(trim(getContainer.number_positions)) GT 0>
				<div class="col-12 col-md-6 col-xl-4 mb-2">
					<strong>Number of Positions:</strong> #encodeForHtml(getContainer.number_positions)#
				</div>
			</cfif>
			<div class="col-12 col-md-6 col-xl-4 mb-2">
				<strong>Locked Position:</strong> <cfif val(getContainer.locked_position) EQ 1>Yes<cfelse>No</cfif>
			</div>
			<div class="col-12 col-md-6 col-xl-4 mb-2">
				<strong>Institution Acronym:</strong> #encodeForHtml(getContainer.institution_acronym)#
			</div>
			<div class="col-12 col-md-6 col-xl-4 mb-2">
				<strong>Placement Date:</strong>
				<cfif isDate(getContainer.parent_install_date)>
					#encodeForHtml(dateFormat(getContainer.parent_install_date, "yyyy-mm-dd"))#
				</cfif>
			</div>
			<div class="col-12 col-md-6 col-xl-4 mb-2">
				<strong>Direct Structural Children:</strong>
				<a href="/containers/Containers.cfm?container_id=#encodeForURL(getContainer.container_id)#&amp;execute=true">
					Browse #encodeForHtml(getContainer.direct_structural_children)# structural children
				</a>
			</div>
			<div class="col-12 col-md-6 col-xl-4 mb-2">
				<strong>Direct Leaf Children:</strong>
				<a href="/containers/Containers.cfm?container_id=#encodeForURL(getContainer.container_id)#&amp;execute=true">
					Browse #encodeForHtml(getContainer.direct_leaf_children)# leaf children
				</a>
			</div>
		</div>
	</section>

	<section class="mb-3" aria-labelledby="currentParentHeading">
		<h2 class="h4" id="currentParentHeading">Current Parent</h2>
		<cfif getParent.recordcount EQ 1>
			<p>
				<a href="/containers/viewContainer.cfm?container_id=#encodeForURL(getParent.container_id)#">
					#encodeForHtml(getParent.container_type)#: #encodeForHtml(getParent.label)#
					<cfif len(trim(getParent.barcode)) GT 0 AND getParent.barcode NEQ getParent.label>
						(#encodeForHtml(getParent.barcode)#)
					</cfif>
				</a>
			</p>
		<cfelse>
			<p class="text-muted">This container has no current parent container record.</p>
		</cfif>
	</section>

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
											<cfif len(trim(getHistory.label)) GT 0>
												#encodeForHtml(getHistory.label)#
											<cfelse>
												Container #encodeForHtml(getHistory.parent_container_id)#
											</cfif>
											<cfif len(trim(getHistory.barcode)) GT 0 AND getHistory.barcode NEQ getHistory.label>
												(#encodeForHtml(getHistory.barcode)#)
											</cfif>
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
			<a class="btn btn-xs btn-primary mr-1 mb-1" href="/containers/Container.cfm?action=edit&amp;container_id=#encodeForURL(getContainer.container_id)#">Edit Container</a>
			<a class="btn btn-xs btn-info mr-1 mb-1" href="/containers/Containers.cfm?container_id=#encodeForURL(getContainer.container_id)#&amp;execute=true">Browse in Hierarchy</a>
			<a class="btn btn-xs btn-secondary mr-1 mb-1" href="/containers/allContainerLeafNodes.cfm?container_id=#encodeForURL(getContainer.container_id)#">Leaf Nodes</a>
			<a class="btn btn-xs btn-secondary mb-1" href="/findContainer.cfm?container_id=#encodeForURL(getContainer.container_id)#" target="_blank" rel="noopener noreferrer">Legacy Details</a>
		</div>
	</section>
</cfoutput>

<cfif url.mode NEQ "fragment">
	</main>
	<cfinclude template="/shared/_footer.cfm">
</cfif>
