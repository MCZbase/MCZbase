<!---
/containers/Container.cfm

Edit or create a container record.

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
<cfparam name="url.action" default="new">
<cfparam name="url.container_id" default=""><!--- container_id for container to edit --->
<cfparam name="url.barcode" default=""><!--- barcode is optional, but if provided and container_id is not, it will be used to look up the container_id for editing --->
<cfparam name="url.parent_container_id" default="">
<cfparam name="url.clone_from" default=""><!--- action=new only: container_id to pre-fill reusable fields from -->
<cf_rolecheck>

<cfset variables.action = lCase(trim(url.action))>
<cfif NOT listFind("new,edit", variables.action)>
	<cfset variables.action = "new">
</cfif>
<cfset variables.containerId = trim(url.container_id)>
<cfset variables.parentContainerId = trim(url.parent_container_id)>

<cfif variables.action EQ "edit" AND (NOT isNumeric(variables.containerId) OR len(variables.containerId) EQ 0)>
	<cfif len(url.barcode) GT 0>
		<cfquery name="getContainerId" datasource="user_login" username="#session.dbuser#"  password="#decrypt(session.epw,cookie.cfid)#">
			SELECT
				container_id
			FROM
				container
			WHERE
				barcode = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.barcode#">
		</cfquery>
		<cfif getContainerId.recordcount EQ 1>
			<cfset variables.containerId = getContainerId.container_id>
		<cfelse>
			<cfinclude template="/errors/404.cfm">
			<cfabort>
		</cfif>
	<cfelse>
		<cflocation url="/containers/Containers.cfm" addtoken="false">
	</cfif>
</cfif>
<cfif len(variables.parentContainerId) GT 0 AND NOT isNumeric(variables.parentContainerId)>
	<cfset variables.parentContainerId = "">
</cfif>

<cfquery name="ctcontainer_type" datasource="user_login" username="#session.dbuser#"  password="#decrypt(session.epw,cookie.cfid)#">
	SELECT
		container_type,
		rank_order,
		variable_rank
	FROM
		ctcontainer_type
	ORDER BY
		rank_order,
		container_type
</cfquery>
<cfquery name="getInstitutionAcronyms" datasource="user_login" username="#session.dbuser#"  password="#decrypt(session.epw,cookie.cfid)#">
	SELECT distinct institution_acronym
	FROM collection
	WHERE institution_acronym IS NOT NULL
</cfquery>

<cfset variables.formData = StructNew()>
<cfset variables.formData["container_id"] = variables.containerId>
<cfset variables.formData["container_type"] = "">
<cfset variables.formData["label"] = "">
<cfset variables.formData["barcode"] = "">
<cfset variables.formData["parent_container_id"] = variables.parentContainerId>
<cfset variables.formData["parent_install_date"] = "">
<cfset variables.formData["description"] = "">
<cfset variables.formData["container_remarks"] = "">
<cfset variables.formData["width"] = "">
<cfset variables.formData["height"] = "">
<cfset variables.formData["length"] = "">
<cfset variables.formData["number_positions"] = "">
<cfset variables.formData["locked_position"] = 0>
<cfset variables.formData["institution_acronym"] = "MCZ">
<cfset variables.parentContainerText = "">
<cfset variables.parent_container_type = "">
<cfset variables.parentRankOrder = "">
<cfset variables.hasChildren = false>
<cfset variables.positionRecordCount = 0>
<cfset variables.positionOccupiedCount = 0>
<cfset variables.canEditContainers = isdefined("session.roles") AND listfindnocase(session.roles,"manage_container")>

<!--- Clone: pre-fills a subset of the New Container form's fields from an existing container,
	reached via a "Clone" button on that container's own edit page. Deliberately excludes label
	and barcode (shown as a "Cloned from" note instead of populating the inputs -- both must be
	unique, so blindly copying either would guarantee a save failure) and parent_install_date
	(defaults fresh, as any new container's does). Unlike the legacy editContainer.cfm's Clone,
	which didn't carry a parent at all (its own edit form had no parent_container_id field to
	resubmit, so every clone landed unplaced at root), this one does default into the same
	parent as the source, since that's the common case and action=new already supports
	parent_container_id cleanly. Runs before the parent-preset lookup below so a clone-inherited
	parent still gets that lookup's display text/type-limiting treatment. --->
<cfset variables.cloneFromId = trim(url.clone_from)>
<cfif len(variables.cloneFromId) GT 0 AND NOT isNumeric(variables.cloneFromId)>
	<cfset variables.cloneFromId = "">
</cfif>
<cfset variables.cloneFromDisplay = "">
<cfif variables.action EQ "new" AND len(variables.cloneFromId) GT 0>
	<cfquery name="getCloneSource" datasource="user_login" username="#session.dbuser#"  password="#decrypt(session.epw,cookie.cfid)#">
		SELECT
			container_type,
			institution_acronym,
			width,
			height,
			length,
			number_positions,
			container_remarks,
			parent_container_id,
			label,
			barcode
		FROM
			container
		WHERE
			container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.cloneFromId#">
	</cfquery>
	<cfif getCloneSource.recordcount EQ 1>
		<cfset variables.formData["container_type"] = getCloneSource.container_type>
		<cfset variables.formData["width"] = getCloneSource.width>
		<cfset variables.formData["height"] = getCloneSource.height>
		<cfset variables.formData["length"] = getCloneSource.length>
		<cfset variables.formData["number_positions"] = getCloneSource.number_positions>
		<cfset variables.formData["container_remarks"] = getCloneSource.container_remarks>
		<cfif len(trim(getCloneSource.institution_acronym)) GT 0>
			<cfset variables.formData["institution_acronym"] = getCloneSource.institution_acronym>
		</cfif>
		<cfif len(trim(getCloneSource.barcode)) GT 0>
			<cfset variables.cloneFromDisplay = getCloneSource.barcode>
		<cfelseif len(trim(getCloneSource.label)) GT 0>
			<cfset variables.cloneFromDisplay = getCloneSource.label>
		</cfif>
		<cfif len(variables.parentContainerId) EQ 0 AND val(getCloneSource.parent_container_id) GT 0>
			<cfset variables.parentContainerId = getCloneSource.parent_container_id>
			<cfset variables.formData["parent_container_id"] = variables.parentContainerId>
		</cfif>
	</cfif>
</cfif>

<cfif variables.action EQ "edit">
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
			c.width,
			c.height,
			c.length,
			c.number_positions,
			c.institution_acronym,
			c.locked_position,
			p.label AS parent_label,
			p.barcode AS parent_barcode,
			p.container_type AS parent_container_type
		FROM
			container c
			LEFT JOIN container p ON c.parent_container_id = p.container_id
		WHERE
			c.container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.containerId#">
	</cfquery>
	<cfif getContainer.recordcount EQ 0>
		<cfinclude template="/errors/404.cfm">
		<cfabort>
	</cfif>
	<cfquery name="getChildCount" datasource="user_login" username="#session.dbuser#"  password="#decrypt(session.epw,cookie.cfid)#">
		SELECT
			COUNT(*) AS child_count
		FROM
			container
		WHERE
			parent_container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.containerId#">
	</cfquery>
	<!--- status only, for the read-only Positions summary below -- the editable grid itself lives
		exclusively on viewContainer.cfm --->
	<cfquery name="getPositionStatus" datasource="user_login" username="#session.dbuser#"  password="#decrypt(session.epw,cookie.cfid)#">
		SELECT
			COUNT(*) AS position_count,
			SUM(CASE WHEN EXISTS (SELECT 1 FROM container occ WHERE occ.parent_container_id = pos.container_id) THEN 1 ELSE 0 END) AS occupied_count
		FROM container pos
		WHERE pos.parent_container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.containerId#">
			AND pos.container_type = 'position'
	</cfquery>
	<cfset variables.positionRecordCount = val(getPositionStatus.position_count)>
	<cfset variables.positionOccupiedCount = val(getPositionStatus.occupied_count)>
	<cfquery name="getHistory" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
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
			ch.container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.containerId#">
		ORDER BY
			ch.install_date DESC NULLS LAST
	</cfquery>
	<cfset variables.hasChildren = (getChildCount.child_count GT 0)>
	<cfset variables.formData["container_id"] = getContainer.container_id>
	<cfset variables.formData["container_type"] = getContainer.container_type>
	<cfset variables.formData["label"] = getContainer.label>
	<cfset variables.formData["barcode"] = getContainer.barcode>
	<cfset variables.formData["parent_container_id"] = getContainer.parent_container_id>
	<cfif isDate(getContainer.parent_install_date)>
		<cfset variables.formData["parent_install_date"] = dateFormat(getContainer.parent_install_date, "yyyy-mm-dd")>
	</cfif>
	<cfset variables.formData["description"] = getContainer.description>
	<cfset variables.formData["container_remarks"] = getContainer.container_remarks>
	<cfset variables.formData["width"] = getContainer.width>
	<cfset variables.formData["height"] = getContainer.height>
	<cfset variables.formData["length"] = getContainer.length>
	<cfset variables.formData["number_positions"] = getContainer.number_positions>
	<cfset variables.formData["locked_position"] = getContainer.locked_position>
	<cfif len(trim(getContainer.institution_acronym)) GT 0>
		<cfset variables.formData["institution_acronym"] = getContainer.institution_acronym>
	</cfif>
	<cfset variables.parent_container_type = getContainer.parent_container_type>
	<cfif len(trim(getContainer.parent_barcode)) GT 0>
		<cfset variables.parentContainerText = getContainer.parent_barcode>
	<cfelseif len(trim(getContainer.parent_label)) GT 0>
		<cfset variables.parentContainerText = getContainer.parent_label>
	</cfif>
	<cfif len(getContainer.barcode) GT 0>
		<cfset variables.container_name = getContainer.barcode>
	<cfelseif len(getContainer.label) GT 0>
		<cfset variables.container_name = getContainer.label>
	<cfelse>
		<!--- This should not be possible from rules on the container table --->
		<cfset variables.container_name = "Unnamed Container [#getContainer.container_id#]">
	</cfif>
<cfelseif len(variables.parentContainerId) GT 0>
	<cfquery name="getPresetParent" datasource="user_login" username="#session.dbuser#"  password="#decrypt(session.epw,cookie.cfid)#">
		SELECT
			label,
			barcode,
			container_type
		FROM
			container
		WHERE
			container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.parentContainerId#">
	</cfquery>
	<cfif getPresetParent.recordcount EQ 1>
		<cfif len(trim(getPresetParent.barcode)) GT 0>
			<cfset variables.parentContainerText = getPresetParent.barcode>
		<cfelse>
			<cfset variables.parentContainerText = getPresetParent.label>
		</cfif>
		<cfset variables.parent_container_type = getPresetParent.container_type>
	</cfif>
</cfif>
<cfif variables.action EQ "new" AND len(trim(variables.parent_container_type)) GT 0>
	<cfloop query="ctcontainer_type">
		<cfif ctcontainer_type.container_type EQ variables.parent_container_type>
			<cfset variables.parentRankOrder = val(ctcontainer_type.rank_order)>
			<cfbreak>
		</cfif>
	</cfloop>
</cfif>
<cfset variables.limitTypesByParent = (variables.action EQ "new" AND isNumeric(variables.parentContainerId) AND val(variables.parentRankOrder) GT 0)>

<cfif variables.action EQ "edit">
	<cfset pageTitle = "Edit Container">
<cfelse>
	<cfset pageTitle = "Create Container">
</cfif>

<cfset pageHasContainers = true>
<cfinclude template="/shared/_header.cfm">
<link rel="stylesheet" href="/containers/css/containers.css">
<main id="content" class="container py-3">

<!--- mirrors the inline-styled #overlay pattern search pages like /Taxa.cfm already use (see
	developer's guide, Search-Pages) -- this isn't a search page, so it doesn't use that pattern's
	jqxgrid-specific classes, but the same "position:fixed, semi-transparent, spinner+text" shape
	is reused here for the same reason: block interaction while a background AJAX step (applying a
	queued Grow/Shrink before reloading, see applyPendingPositionsAction in containers.js) runs. --->
<div id="containerSavingOverlay" class="d-none" style="position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0,0,0,0.5); z-index: 2000;">
	<div class="d-flex align-items-center justify-content-center h-100">
		<div class="bg-white rounded p-3 text-center shadow">
			<img src="/shared/images/indicator.gif"> Saving changes&hellip;
		</div>
	</div>
</div>

<cfoutput>
	<section class="row mx-0 border rounded my-2 pt-2 mb-4" aria-labelledby="containerFormHeading">
		<div class="col-12">
			<div class="d-flex justify-content-between align-items-center flex-wrap">
				<cfif variables.action EQ "edit">
					<h1 class="h2 ml-1 mb-1" id="containerFormHeading">Edit Container: #encodeForHtml(container_name)# <span id="container_role_badge"></span></h1>
					<script>
						$(document).ready(function () {
							$("##container_role_badge").html( getContainerRoleBadgeHtml('#variables.formData.container_type#') );
						});
					</script>
					<!--- unlike viewContainer.cfm's toolbar, no canEditContainers check is needed here --
						loading this page at all already requires manage_container via cf_rolecheck, so
						there's no broader-audience case to gate against. Create Child/Place Child are
						deliberately left off this toolbar -- unlike viewContainer.cfm, this page never
						shows what the container currently contains, so there isn't enough context here
						for either action, even though both are logically edit-ish actions. --->
					<div class="btn-toolbar pt-1" role="toolbar" aria-label="Container actions">
						<a class="btn btn-xs btn-info mr-1 mb-1" href="/containers/Containers.cfm?container_id=#encodeForURL(variables.formData.container_id)#&amp;execute=true">Browse in Hierarchy</a>
						<a class="btn btn-xs btn-info mb-1" href="/containers/viewContainer.cfm?container_id=#encodeForURL(variables.formData.container_id)#">View Container</a>
					</div>
				<cfelse>
					<h1 class="h2 ml-1 mb-1" id="containerFormHeading">Create Container</h1>
				</cfif>
			</div>
			<cfif variables.action EQ "new" AND len(variables.cloneFromDisplay) GT 0>
				<p class="small text-muted ml-1 mb-2">Cloned from #encodeForHtml(variables.cloneFromDisplay)# -- Unique Identifier and Container Name are left blank below; enter new values for this container.</p>
			</cfif>
			<cfif variables.action EQ "edit">
				<!--- This section is populated via an ajax call to the showContainerBreadcrumb() function in the script below as the backing method returns json --->
				<section class="mb-0" aria-label="Container breadcrumb trail">
					<nav aria-label="Container breadcrumb" class="mb-2" id="containerEditBreadcrumbNav"></nav>
					<output id="containerEditBreadcrumbFeedback"></output>
				</section>
			</cfif>

			<form class="col-12 px-0" id="containerForm" name="containerForm" method="post" novalidate>
				<cfif variables.action EQ "edit">
					<input type="hidden" name="container_id" id="container_id" value="#encodeForHtml(variables.formData.container_id)#">
				</cfif>

				<!--- lock type institution and "Deaccesioned" root containers from some edits --->
				<!--- NOTE: This block disables form controls for users, the authoritative check is in the saveContainer function --->
				<!--- NOTE: Hidden fields are used as saveContainer requires these arguments, it just ignores them it determines lockedRoot --->
				<cfset lockedRoot = false>
				<cfif variables.formData.container_type EQ "institution">
					<cfset lockedRoot = true>
				<cfelseif variables.formData.label EQ "Deaccessioned">
					<cfset lockedRoot = true>
				</cfif>

				<div class="form-row">
					<div class="col-12 col-md-6 col-xl-3 mb-2">
						<label for="container_type" class="data-entry-label">Container Type</label>
						<cfif lockedRoot>
							<input type="hidden" name="container_type" id="container_type" value="#encodeForHtml(variables.formData.container_type)#">
							<input type="text" class="data-entry-input col-12 bg-lt-gray" value="#encodeForHtml(variables.formData.container_type)#" readonly>
						<cfelse>
							<select name="container_type" id="container_type" class="data-entry-select reqdClr col-12" required aria-required="true">
								<option value=""></option>
								<cfloop query="ctcontainer_type">
									<cfset variables.selectedType = "">
									<cfset variables.typeVisibilityClass = "">
									<cfset variables.isVariableRankType = (val(ctcontainer_type.variable_rank) EQ 1)>
									<cfset variables.hasLowerRankOrderThanParent = (val(ctcontainer_type.rank_order) LT val(variables.parentRankOrder))>
									<!--- variable_rank=1 types may be placed at any rank and remain visible in the constrained list. --->
									<cfif variables.limitTypesByParent AND NOT variables.isVariableRankType AND variables.hasLowerRankOrderThanParent>
										<cfset variables.typeVisibilityClass = "ct-all-option d-none">
									</cfif>
									<cfif ctcontainer_type.container_type EQ variables.formData.container_type>
										<cfset variables.selectedType = " selected">
									</cfif>
									<option class="#variables.typeVisibilityClass#" value="#encodeForHtml(ctcontainer_type.container_type)#"#variables.selectedType#>#encodeForHtml(ctcontainer_type.container_type)#</option>
								</cfloop>
							</select>
							<cfif variables.limitTypesByParent>
								<button type="button" class="btn btn-xs btn-secondary mt-1" id="showAllContainerTypesButton">Show all container types</button>
							</cfif>
						</cfif>
					</div>
					<div class="col-12 col-md-6 col-xl-3 mb-2">
						<label for="label" class="data-entry-label">Label</label>
						<cfif lockedRoot>
							<input type="hidden" name="label" id="label" value="#encodeForHtml(variables.formData.label)#">
							<input type="text" class="data-entry-input col-12 bg-lt-gray" value="#encodeForHtml(variables.formData.label)#" readonly>
						<cfelse>
							<input type="text" name="label" id="label" class="data-entry-input col-12 reqdClr" required aria-required="true" value="#encodeForHtml(variables.formData.label)#">
						</cfif>
					</div>
					<div class="col-12 col-md-6 col-xl-3 mb-2">
						<label for="barcode" class="data-entry-label">Barcode</label>
						<cfif lockedRoot>
							<input type="hidden" name="barcode" id="barcode" value="#encodeForHtml(variables.formData.barcode)#">
							<input type="text" class="data-entry-input col-12 bg-lt-gray" value="#encodeForHtml(variables.formData.barcode)#" readonly>
						<cfelse>
							<input type="text" name="barcode" id="barcode" class="data-entry-input col-12" value="#encodeForHtml(variables.formData.barcode)#">
						</cfif>
					</div>
					<div class="col-12 col-md-6 col-xl-3 mb-2">
						<label for="description" class="data-entry-label">Description</label>
						<input type="text" name="description" id="description" class="data-entry-input col-12" value="#encodeForHtml(variables.formData.description)#">
					</div>
				</div>

				<div class="form-row">
					<div class="col-12 col-md-6 col-xl-4 mb-2">
						<label for="institution_acronym" class="data-entry-label">Institution Acronym</label>
						<select name="institution_acronym" id="institution_acronym" class="data-entry-select col-12 reqdClr">
							<cfloop query="getInstitutionAcronyms">
								<cfset variables.selectedInst = "">
								<cfif getInstitutionAcronyms.institution_acronym EQ variables.formData.institution_acronym>
									<cfset variables.selectedInst = " selected">
								</cfif>
								<option value="#encodeForHtml(getInstitutionAcronyms.institution_acronym)#"#variables.selectedInst#>#encodeForHtml(getInstitutionAcronyms.institution_acronym)#</option>
							</cfloop>
						</select>
					</div>
					<div class="col-12 col-md-6 col-xl-4 mb-2">
						<label for="parentContainerText" class="data-entry-label">
							Parent Container
							<cfif isDefined("variables.parent_container_type") AND variables.parent_container_type neq "">
								<small class="text-muted">#variables.parentContainerText# (#encodeForHtml(variables.parent_container_type)#)</small>
							</cfif>
						</label>
						<cfif lockedRoot OR variables.formData.locked_position EQ 1>
							<input type="hidden" name="parent_container_id" id="parent_container_id" value="#encodeForHtml(variables.formData.parent_container_id)#">
							<input type="text" class="data-entry-input col-12 bg-lt-gray" value="#encodeForHtml(variables.parentContainerText)#" readonly>
						<cfelse>
							<input type="hidden" name="parent_container_id" id="parent_container_id" value="#encodeForHtml(variables.formData.parent_container_id)#">
							<div class="parent-container-picker-row d-flex align-items-start">
								<input type="text" name="parentContainerText" id="parentContainerText" class="data-entry-input reqdClr flex-grow-1" required aria-required="true" value="#encodeForHtml(variables.parentContainerText)#">
							</div>
							<div id="parentPlacementValidation" class="mt-1"></div>
						</cfif>
					</div>
					<div class="col-12 col-md-6 col-xl-4 mb-2">
						<label for="parent_install_date" class="data-entry-label">Placement Date</label>
						<input type="text" name="parent_install_date" id="parent_install_date" class="data-entry-input col-12" value="#encodeForHtml(variables.formData.parent_install_date)#">
					</div>
				</div>

				<div class="form-row">
					<div class="col-12 mb-2">
						<label for="container_remarks" class="data-entry-label">Container Remarks</label>
						<textarea name="container_remarks" id="container_remarks" rows="3" class="data-entry-input col-12">#encodeForHtml(variables.formData.container_remarks)#</textarea>
					</div>
				</div>

				<div class="form-row">
					<div class="col-12 col-md-3 mb-2">
						<label for="width" class="data-entry-label">Width (cm)</label>
						<input type="text" name="width" id="width" class="data-entry-input col-12" value="#encodeForHtml(variables.formData.width)#">
					</div>
					<div class="col-12 col-md-3 mb-2">
						<label for="height" class="data-entry-label">Height (cm)</label>
						<input type="text" name="height" id="height" class="data-entry-input col-12" value="#encodeForHtml(variables.formData.height)#">
					</div>
					<div class="col-12 col-md-3 mb-2">
						<label for="length" class="data-entry-label">Length (cm)</label>
						<input type="text" name="length" id="length" class="data-entry-input col-12" value="#encodeForHtml(variables.formData.length)#">
					</div>
					<div class="col-12 col-md-3 mb-2">
						<label for="number_positions" class="data-entry-label">Number of Positions</label>
						<cfif lockedRoot>
							<input type="hidden" name="number_positions" id="number_positions" autocomplete="off" value="#encodeForHtml(variables.formData.number_positions)#">
							<input type="text" class="data-entry-input col-12 bg-lt-gray" autocomplete="off" value="#encodeForHtml(variables.formData.number_positions)#" readonly>
						<cfelseif variables.action EQ "edit" AND variables.positionRecordCount GT 0>
							<input type="hidden" name="number_positions" id="number_positions" autocomplete="off" value="#encodeForHtml(variables.formData.number_positions)#">
							<div class="d-flex align-items-center">
								<input type="text" id="number_positions_display" class="data-entry-input flex-grow-1 bg-lt-gray" autocomplete="off" value="#encodeForHtml(variables.formData.number_positions)#" readonly aria-label="Number of Positions">
								<button type="button" class="btn btn-xs btn-secondary ml-1" id="changePositionsBtn">Change...</button>
							</div>
						<cfelse>
							<input type="text" name="number_positions" id="number_positions" autocomplete="off" class="data-entry-input col-12" value="#encodeForHtml(variables.formData.number_positions)#">
						</cfif>
					</div>
				</div>

				<cfif variables.action EQ "edit">
					<!--- always rendered (visibility toggled by saveContainerForm's success handler when
						Number of Positions changes from/to zero on save) so it can be revealed without a
						page reload; the accurate created/occupied counts below only reflect the values as
						of this page load, though, so they go stale if positions are added/removed elsewhere
						while this form stays open --->
					<cfset variables.positionsSummaryClass = "">
					<cfif val(variables.formData.number_positions) LTE 0>
						<cfset variables.positionsSummaryClass = " d-none">
					</cfif>
					<div class="form-row mb-2#variables.positionsSummaryClass#" id="containerPositionsSummary">
						<div class="col-12 border rounded bg-light py-2">
							<h2 class="h6 mb-1">Positions</h2>
							<cfset variables.positionsWord = "positions">
							<cfif val(variables.formData.number_positions) EQ 1><cfset variables.positionsWord = "position"></cfif>
							<p class="small mb-1" id="containerPositionsSummaryText">
								<cfif variables.positionRecordCount EQ 0>
									This container declares #variables.formData.number_positions# #variables.positionsWord#, but none have been created yet.
								<cfelseif variables.positionRecordCount LT val(variables.formData.number_positions)>
									This container declares #variables.formData.number_positions# #variables.positionsWord#; #variables.positionRecordCount# have been created (#variables.positionOccupiedCount# occupied).
								<cfelse>
									This container declares #variables.formData.number_positions# #variables.positionsWord#; all have been created (#variables.positionOccupiedCount# occupied).
								</cfif>
							</p>
							<div id="containerPositionsCreateArea" class="mb-2"></div>
							<cfset variables.positionsLinkClass = "">
							<cfif variables.positionRecordCount EQ 0>
								<cfset variables.positionsLinkClass = " d-none">
							</cfif>
							<a class="btn btn-xs btn-secondary#variables.positionsLinkClass#" id="containerPositionsLink" href="/containers/viewContainer.cfm?container_id=#encodeForURL(variables.formData.container_id)###containerPositionsHeading_page">View/Edit Positions</a>
						</div>
					</div>
				</cfif>

				<div class="form-row mb-4 mt-1">
					<div class="col-12">
						<cfif variables.action EQ "edit">
							<button type="button" class="btn btn-xs btn-primary" id="containerSaveActionButton" onclick="saveContainerForm('containerForm', 'saveContainer', 'containerSaveStatus', '', 'containerEditBreadcrumbFeedback', 'containerEditBreadcrumbNav')">Save Changes</button>
							<a class="btn btn-xs btn-secondary ml-1" href="/containers/Container.cfm?action=new&amp;clone_from=#encodeForURL(variables.formData.container_id)#">Clone</a>
							<cfif NOT variables.hasChildren>
								<button type="button" class="btn btn-xs btn-danger ml-1" onclick="confirmDeleteContainer(#encodeForHtml(variables.formData.container_id)#, 'containerSaveStatus')">Delete</button>
							</cfif>
						<cfelse>
							<button type="button" class="btn btn-xs btn-primary" id="containerSaveActionButton" onclick="saveContainerForm('containerForm', 'createContainer', 'containerSaveStatus')">Create Container</button>
							<a class="btn btn-xs btn-warning ml-1" href="/containers/Containers.cfm">Cancel</a>
						</cfif>
						<output id="containerSaveStatus"></output>
					</div>
				</div>
			</form>
		</div>
	</section>
	<cfif variables.action EQ "edit">
		<section class="row mx-0 border rounded my-2 pt-2 mb-4" aria-labelledby="containerHistoryHeading">
			<div class="col-12">
				<h2 class="h4 ml-1 mb-2" id="containerHistoryHeading">Placement History</h2>
				<cfif getHistory.recordcount EQ 0>
					<p class="text-muted mb-2">No placement history found.</p>
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
									<cfset variables.historyBadgeId = "editContainerHistoryBadge_#getHistory.currentRow#">
									<cfset variables.historyLocateRowId = "editContainerHistoryLocate_#getHistory.currentRow#">
									<cfset variables.historyParentExists = (variables.historyParentId GT 0 AND len(trim(getHistory.container_type)) GT 0)>
									<cfset variables.historyParentIsCurrent = (variables.historyParentId EQ val(variables.formData.parent_container_id))>
									<cfset variables.historyParentIsInstitutionType = (variables.historyParentExists AND listFindNoCase("institution", getHistory.container_type) GT 0)>
									<cfset variables.currentContainerCanBeInInstitution = (listFindNoCase("building,campus", variables.formData.container_type) GT 0)>
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
													<button type="button" class="btn btn-xs btn-secondary" onclick="putContainerBackFromHistory(#val(variables.formData.container_id)#, #val(variables.historyParentId)#, '#encodeForJavaScript(variables.historyDisplay)#', 'containerSaveStatus', function(){ window.location.reload(); });">Put Back Here</button>
												</cfif>
											</cfif>
										</td>
									</tr>
								</cfloop>
							</tbody>
						</table>
					</div>
				</cfif>
			</div>
		</section>
	</cfif>
</cfoutput>

<script>
	function changed() {
		$('#containerSaveStatus').html('Unsaved changes.');
		$('#containerSaveStatus').addClass('text-danger');
		$('#containerSaveStatus').removeClass('text-success');
		$('#containerSaveStatus').removeClass('text-warning');
	}
	// a Grow/Shrink queued via the "Change Positions" dialog, not yet applied -- see
	// applyPendingPositionsAction (containers.js), run from saveContainerForm's success handler
	// once Save Changes is pressed. Declared unconditionally (not just for action=edit) so
	// saveContainerForm's typeof check always finds a real variable rather than throwing.
	var pendingPositionsAction = null;
	$(document).ready(function () {
		makeContainerAutocompleteMetaExcludeCO('parentContainerText', 'parent_container_id');
		$('#parent_install_date').datepicker({ dateFormat: 'yy-mm-dd' });
		<cfoutput>
		var placementChildContainerId = '#encodeForJavaScript(variables.formData.container_id)#';
		var placementChildContainerType = '#encodeForJavaScript(variables.formData.container_type)#';
		var placementChildInstitution = '#encodeForJavaScript(variables.formData.institution_acronym)#';
		<cfif lockedRoot OR variables.formData.locked_position EQ 1>
			var parentLocked = 1;
		<cfelse>
			var parentLocked = 0;
		</cfif>
		</cfoutput>
		if (!parentLocked) {
			loadContainerTypeMetadata(function() {
				addPlacementDialogButton('parentContainerText', 'parent_container_id', placementChildContainerId, placementChildContainerType, placementChildInstitution, 'containerSaveStatus');
			});

			var runParentPlacementValidation = function() {
				var parentId = $('#parent_container_id').val() || 0;
				if ($('#parentPlacementValidation').length > 0 && parentId) {
					checkAndRenderPlacementValidation(placementChildContainerId, parentId, 'parentPlacementValidation', 'containerSaveActionButton');
				}
			};
			$('#parentContainerText').on('autocompleteselect change', function() {
				// allow autocomplete selection handlers to populate parent_container_id before validation runs.
				window.setTimeout(runParentPlacementValidation, 10);
			});
			runParentPlacementValidation();
		}
		<cfif variables.limitTypesByParent>
			$('#showAllContainerTypesButton').on('click', function () {
				$('#container_type .ct-all-option').removeClass('d-none');
				$(this).addClass('d-none');
			});
		</cfif>

		<cfif variables.action EQ "edit">
			<cfoutput>
			showContainerBreadcrumb("#encodeForJavaScript(variables.formData.container_id)#", 'containerEditBreadcrumbFeedback', 'containerEditBreadcrumbNav');
			<cfloop query="getHistory">
				<cfif val(getHistory.parent_container_id) GT 0>
					loadPlacementWarningBadge(#val(variables.formData.container_id)#, #val(getHistory.parent_container_id)#, '#encodeForJavaScript("editContainerHistoryBadge_#getHistory.currentRow#")#');
				</cfif>
			</cfloop>
			var positionRecordCount = #val(variables.positionRecordCount)#;
			</cfoutput>
			<cfif len(trim(variables.formData.number_positions)) GT 0>
				<!--- some browsers restore a form field's own prior live value across a reload
					rather than the freshly server-rendered one -- most visibly here, since the
					Number of Positions field switches between a plain input and this locked
					display+Change button pair depending on positionRecordCount, so the field a
					browser thinks it's restoring isn't necessarily the one now in this DOM
					position. Reassert the actual value explicitly rather than trust the browser. --->
				<cfoutput>
				$('##number_positions').val(#val(variables.formData.number_positions)#);
				$('##number_positions_display').val(#val(variables.formData.number_positions)#);
				</cfoutput>
			</cfif>
			$('#number_positions').on('change', function() {
				var $field = $(this);
				var newValue = $.trim($field.val());
				if (positionRecordCount === 0 && newValue.length > 0 && parseInt(newValue, 10) > 0) {
					confirmDialog(
						'Positions are individually trackable slots inside this container (e.g. spots in a freezer box or rack). Setting Number of Positions here does not create them yet -- you\'ll create the actual position records afterward from this container\'s own page. Continue with ' + newValue + ' position(s)?',
						'Create Positions?',
						function() {
							changed();
						},
						function() {
							$field.val('');
						}
					);
				}
			});
			<cfif variables.positionRecordCount GT 0>
				<cfoutput>
				$('##changePositionsBtn').on('click', function() {
					openPositionsChangeDialog(#val(variables.formData.container_id)#, function(data) {
						if (data.action === 'reset') {
							// Reset already committed from within the dialog and flips this field
							// back to freely editable, dropping the Change button -- only the
							// server-rendered markup knows how to redraw that, so reload outright.
							window.location.reload();
							return;
						}
						// Grow/Shrink -- not applied yet. Queue it and preview the resulting count,
						// but leave ##number_positions (the value this form actually submits) at its
						// real current value, so pressing Save Changes doesn't trip saveContainer's
						// own guard against a manually-changed Number of Positions once position
						// records exist. Applying the queue happens in saveContainerForm's success
						// handler, after the rest of this save has gone through.
						pendingPositionsAction = data;
						$('##number_positions_display').val(data.previewCount);
						$('##changePositionsBtn').prop('disabled', true);
						updateContainerPositionsSummary(#val(variables.formData.container_id)#, data.previewCount, true);
						$('##containerPositionsSummaryText').append(' <span class="text-warning">(pending -- applies on Save)</span>');
						changed();
					});
				});
				</cfoutput>
			<cfelseif val(variables.formData.number_positions) GT 0>
				<!--- no position records exist yet, but a count is already declared (either from page
					load, or set moments ago and saved) -- render the same "Create N Positions" prompt
					this container's own summary box would show after a plain save, so a page load
					doesn't require one first --->
				<cfoutput>
				renderCreatePositionsPrompt(#val(variables.formData.number_positions)#, 'containerPositionsCreateArea', null, #val(variables.formData.container_id)#, true, null, function() {
					// reload rather than updating the summary in place -- position records now
					// exist, so the Number of Positions field needs to switch to its locked
					// display + Change button, which only the server-rendered markup knows how to do.
					window.location.reload();
				});
				</cfoutput>
			</cfif>
			$('#containerForm input[type=text]').on('change', changed);
			$('#containerForm select').on('change', changed);
			$('#containerForm textarea').on('change', changed);
		</cfif>
	});
</script>

</main>
<cfinclude template="/shared/_footer.cfm">
