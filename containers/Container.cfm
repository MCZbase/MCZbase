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
		container_type
	FROM
		ctcontainer_type
	ORDER BY
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
<cfset variables.formData["institution_acronym"] = "MCZ">
<cfset variables.parentContainerText = "">
<cfset variables.hasChildren = false>

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

<cfif variables.action EQ "edit">
	<cfset pageTitle = "Edit Container">
<cfelse>
	<cfset pageTitle = "Create Container">
</cfif>

<cfset pageHasContainers = true>
<cfinclude template="/shared/_header.cfm">
<link rel="stylesheet" href="/containers/css/containers.css">
<main id="content" class="container py-3">

<cfoutput>
	<section class="row mx-0 border rounded my-2 pt-2 mb-4" aria-labelledby="containerFormHeading">
		<div class="col-12">
			<cfif variables.action EQ "edit">
				<h1 class="h2 ml-1 mb-1" id="containerFormHeading">Edit Container: #encodeForHtml(container_name)#</h1>
			<cfelse>
				<h1 class="h2 ml-1 mb-1" id="containerFormHeading">Create Container</h1>
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
					<cfset lockedRoot EQ true>
				<cfelseif variables.formData.label EQ "Deaccessioned">
					<cfset lockedRoot EQ true>
				</cfif>

				<div class="form-row">
					<div class="col-12 col-md-6 col-xl-3 mb-2">
						<label for="container_type" class="data-entry-label">Container Type</label>
						<cfif lockedRoot>
							<input type="hidden" name="container_type" id="container_type" value="#encodeForHtml(variables.formData.container_type)#">
							<input type="text" class="data-entry-input col-12" value="#encodeForHtml(variables.formData.container_type)#" readonly>
						<cfelse>
							<select name="container_type" id="container_type" class="data-entry-select reqdClr col-12" required aria-required="true">
								<option value=""></option>
								<cfloop query="ctcontainer_type">
									<cfset variables.selectedType = "">
									<cfif ctcontainer_type.container_type EQ variables.formData.container_type>
										<cfset variables.selectedType = " selected">
									</cfif>
									<option value="#encodeForHtml(ctcontainer_type.container_type)#"#variables.selectedType#>#encodeForHtml(ctcontainer_type.container_type)#</option>
								</cfloop>
							</select>
						</cfif>
					</div>
					<div class="col-12 col-md-6 col-xl-3 mb-2">
						<label for="label" class="data-entry-label">Label</label>
						<cfif lockedRoot>
							<input type="hidden" name="label" id="label" value="#encodeForHtml(variables.formData.label)#">
							<input type="text" class="data-entry-input col-12" value="#encodeForHtml(variables.formData.label)#" readonly>
						<cfelse>
							<input type="text" name="label" id="label" class="data-entry-input col-12 reqdClr" required aria-required="true" value="#encodeForHtml(variables.formData.label)#">
						</cfif>
					</div>
					<div class="col-12 col-md-6 col-xl-3 mb-2">
						<label for="barcode" class="data-entry-label">Barcode</label>
						<cfif lockedRoot>
							<input type="hidden" name="barcode" id="barcode" value="#encodeForHtml(variables.formData.barcode)#">
							<input type="text" class="data-entry-input col-12" value="#encodeForHtml(variables.formData.barcode)#" readonly>
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
							<cfif variables.parent_container_type neq "">
								<small class="text-muted">#variables.parentContainerText# (#encodeForHtml(variables.parent_container_type)#)</small>
							</cfif>
						</label>
						<cfif lockedRoot>
							<input type="hidden" name="parent_container_id" id="parent_container_id" value="#encodeForHtml(variables.formData.parent_container_id)#">
							<input type="text" class="data-entry-input col-12" value="#encodeForHtml(variables.parentContainerText)#" readonly>
						<cfelse>
							<input type="hidden" name="parent_container_id" id="parent_container_id" value="#encodeForHtml(variables.formData.parent_container_id)#">
							<input type="text" name="parentContainerText" id="parentContainerText" class="data-entry-input col-12 reqdClr" required aria-required="true" value="#encodeForHtml(variables.parentContainerText)#">
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
							<input type="hidden" name="number_positions" id="number_positions" value="#encodeForHtml(variables.formData.number_positions)#">
							<input type="text" class="data-entry-input col-12" value="#encodeForHtml(variables.formData.number_positions)#" readonly>
						<cfelse>
							<input type="text" name="number_positions" id="number_positions" class="data-entry-input col-12" value="#encodeForHtml(variables.formData.number_positions)#">
						</cfif>
					</div>
				</div>

				<div class="form-row mb-4 mt-1">
					<div class="col-12">
						<cfif variables.action EQ "edit">
							<button type="button" class="btn btn-xs btn-primary" onclick="saveContainerForm('containerForm', 'saveContainer', 'containerSaveStatus', '', 'containerEditBreadcrumbFeedback', 'containerEditBreadcrumbNav')">Save Changes</button>
							<a class="btn btn-xs btn-info ml-1" href="/containers/viewContainer.cfm?container_id=#encodeForURL(variables.formData.container_id)#">View Container</a>
							<cfif NOT variables.hasChildren>
								<button type="button" class="btn btn-xs btn-danger ml-1" onclick="confirmDeleteContainer(#encodeForHtml(variables.formData.container_id)#, 'containerSaveStatus')">Delete</button>
							</cfif>
						<cfelse>
							<button type="button" class="btn btn-xs btn-primary" onclick="saveContainerForm('containerForm', 'createContainer', 'containerSaveStatus')">Create Container</button>
							<a class="btn btn-xs btn-warning ml-1" href="/containers/Containers.cfm">Cancel</a>
						</cfif>
						<output id="containerSaveStatus"></output>
					</div>
				</div>
			</form>
		</div>
	</section>
</cfoutput>

<script>
	function changed() {
		$('#containerSaveStatus').html('Unsaved changes.');
		$('#containerSaveStatus').addClass('text-danger');
		$('#containerSaveStatus').removeClass('text-success');
		$('#containerSaveStatus').removeClass('text-warning');
	}
	$(document).ready(function () {
		makeContainerAutocompleteMetaExcludeCO('parentContainerText', 'parent_container_id');
		$('#parent_install_date').datepicker({ dateFormat: 'yy-mm-dd' });
		<cfif variables.action EQ "edit">
			<cfoutput>
			showContainerBreadcrumb("#encodeForJavaScript(variables.formData.container_id)#", 'containerEditBreadcrumbFeedback', 'containerEditBreadcrumbNav');
			</cfoutput>
			$('#containerForm input[type=text]').on('change', changed);
			$('#containerForm select').on('change', changed);
			$('#containerForm textarea').on('change', changed);
		</cfif>
	});
</script>

</main>
<cfinclude template="/shared/_footer.cfm">
