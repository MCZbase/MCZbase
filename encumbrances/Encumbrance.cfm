<!---
encumbrances/Encumbrance.cfm

Create and edit encumbrance records.  Supports action=new (default) and action=edit.
For action=edit an encumbrance_id must be supplied; the record is loaded from the
database and the form is pre-populated.

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

<!--- URL parameter declarations --->
<cfparam name="url.action" default="new">
<cfparam name="url.encumbrance_id" default="">

<!--- Resolve action --->
<cfif isDefined("form.action") AND len(trim(form.action)) GT 0>
	<cfset variables.action = trim(form.action)>
<cfelseif len(trim(url.action)) GT 0>
	<cfset variables.action = trim(url.action)>
<cfelse>
	<cfset variables.action = "new">
</cfif>
<cfif NOT listFind("new,edit", variables.action)>
	<cfset variables.action = "new">
</cfif>

<!--- Resolve encumbrance_id --->
<cfif isDefined("form.encumbrance_id") AND len(trim(form.encumbrance_id)) GT 0>
	<cfset variables.encumbrance_id = trim(form.encumbrance_id)>
<cfelseif len(trim(url.encumbrance_id)) GT 0>
	<cfset variables.encumbrance_id = trim(url.encumbrance_id)>
<cfelse>
	<cfset variables.encumbrance_id = "">
</cfif>

<cfif variables.action EQ "edit" AND len(variables.encumbrance_id) EQ 0>
	<cfset variables.action = "new">
</cfif>

<!--- Set page title before header include --->
<cfif variables.action EQ "edit">
	<cfset pageTitle = "Edit Encumbrance">
<cfelse>
	<cfset pageTitle = "Create Encumbrance">
</cfif>

<cfinclude template="/shared/_header.cfm">

<!--- Load controlled vocabulary for encumbrance_action select --->
<cfquery name="getCtEncumbranceAction" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	SELECT ctencumbrance_action.encumbrance_action, count(encumbrance.encumbrance_id) ct
	FROM ctencumbrance_action
		left join encumbrance on ctencumbrance_action.encumbrance_action = encumbrance.encumbrance_action
	GROUP BY ctencumbrance_action.encumbrance_action
	ORDER BY ctencumbrance_action.encumbrance_action
</cfquery>

<!--- For edit mode, load the existing encumbrance record --->
<cfif variables.action EQ "edit">
	<cfquery name="encDetails" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		SELECT
			encumbrance.encumbrance_id,
			encumbrance.encumbering_agent_id,
			encumbrance.encumbrance,
			encumbrance.encumbrance_action,
			encumbrance.made_date,
			encumbrance.expiration_date,
			encumbrance.expiration_event,
			encumbrance.remarks,
			preferred_agent_name.agent_name,
			count(coll_object_encumbrance.collection_object_id) AS specimen_count
		FROM
			encumbrance
			JOIN preferred_agent_name
				ON encumbrance.encumbering_agent_id = preferred_agent_name.agent_id
			LEFT JOIN coll_object_encumbrance
				ON encumbrance.encumbrance_id = coll_object_encumbrance.encumbrance_id
		WHERE
			encumbrance.encumbrance_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.encumbrance_id#">
		GROUP BY
			encumbrance.encumbrance_id,
			encumbrance.encumbering_agent_id,
			encumbrance.encumbrance,
			encumbrance.encumbrance_action,
			encumbrance.made_date,
			encumbrance.expiration_date,
			encumbrance.expiration_event,
			encumbrance.remarks,
			preferred_agent_name.agent_name
	</cfquery>
	<cfif encDetails.recordcount EQ 0>
		<cfinclude template="/errors/404.cfm">
		<cfabort>
	</cfif>
	<!--- Pre-format dates; isDate() guards against null database values --->
	<cfset variables.editMadeDate = "">
	<cfif isDate(encDetails.made_date)>
		<cfset variables.editMadeDate = dateformat(encDetails.made_date,"yyyy-mm-dd")>
	</cfif>
	<cfset variables.editExpDate = "">
	<cfif isDate(encDetails.expiration_date)>
		<cfset variables.editExpDate = dateformat(encDetails.expiration_date,"yyyy-mm-dd")>
	</cfif>
	<!--- Deletability: mirrors the rule used in renderEncumbranceSearchResults (search.cfc).
	     An encumbrance is deletable when remarks does not contain "DO NOT DELETE" AND at least
	     one of: no specimens linked, has an expiration event, or has an expiration date.
	     TODO: locality_encumbrance - also require locality count EQ 0 when that table exists. --->
	<cfset variables.isDeletable = false>
	<cfif NOT findNoCase("DO NOT DELETE", encDetails.remarks)>
		<cfif encDetails.specimen_count EQ 0
				OR len(trim(encDetails.expiration_event)) GT 0
				OR (len(variables.editExpDate) GT 0 AND dateCompare(parseDateTime(variables.editExpDate),now(),"d"))>
			<cfset variables.isDeletable = true>
		</cfif>
	</cfif>
</cfif>

<cfinclude template="/encumbrances/component/functions.cfc" runOnce="true">

<cfoutput>
<main class="container py-3" id="content">

	<cfif variables.action EQ "edit">
		<h1 class="h2 ml-3 mb-1">Edit Encumbrance:
			<a href="/encumbrances/viewEncumbrance.cfm?encumbrance_id=#encodeForURL(encDetails.encumbrance_id)#"><span id="headingEncumbranceName">#encodeForHTML(encDetails.encumbrance)#</span></a>
			<i class="fas fa-info-circle" onClick="getMCZDocs('encumbrance','encumbrance')" aria-label="help link"></i>
		</h1>
	<cfelse>
		<h1 class="h2 ml-3 mb-1">Create Encumbrance
			<i class="fas fa-info-circle" onClick="getMCZDocs('encumbrance','encumbrance')" aria-label="help link"></i>
		</h1>
	</cfif>

	<!--- Status/output region populated by JavaScript after AJAX save --->
	<div id="encumbranceSaveStatus" class="mb-2" role="status" aria-live="polite"></div>

	<section class="row mx-0 border rounded my-2 pt-2" aria-labelledby="encFormHeading">
		<form class="col-12" id="encumbranceForm"
			name="encumbranceForm" method="post" novalidate>
			<input type="hidden" name="encumbrance_id" value="#encodeForHTML(variables.encumbrance_id)#">

			<div class="form-row">
				<!--- Encumbering Agent --->
				<div class="col-12 col-md-4 mb-2">
					<span class="d-block" style="margin-top:-2px;">
						<label for="encumberingAgent" class="data-entry-label w-auto d-inline">Encumbering Agent</label>
						<span id="agentViewEnc" class="d-inline ml-1">&nbsp;&nbsp;&nbsp;&nbsp;</span>
					</span>
					<div class="input-group">
						<div class="input-group-prepend">
							<span class="input-group-text smaller" id="agentIconEnc">
								<i class="fa fa-user" aria-hidden="true"></i>
							</span>
						</div>
						<input type="text" name="encumberingAgent" id="encumberingAgent"
							required aria-required="true"
							class="form-control form-control-sm data-entry-input reqdClr rounded-right"
							aria-describedby="agentIconEnc"
							<cfif variables.action EQ "edit">value="#encodeForHTML(encDetails.agent_name)#"</cfif>>
						<input type="hidden" name="encumberingAgentId" id="encumberingAgentId"
							<cfif variables.action EQ "edit">value="#encodeForHTML(encDetails.encumbering_agent_id)#"</cfif>>
					</div>
				</div>

				<!--- Encumbrance Name --->
				<div class="col-12 col-md-5 mb-2">
					<label for="encumbranceName" class="data-entry-label">Encumbrance Name</label>
					<input type="text" name="encumbrance" id="encumbranceName"
						required aria-required="true"
						class="data-entry-input col-12 reqdClr"
						<cfif variables.action EQ "edit">value="#encodeForHTML(encDetails.encumbrance)#"</cfif>>
				</div>

				<!--- Made Date --->
				<div class="col-12 col-md-3 mb-2">
					<label for="made_date" class="data-entry-label">Made Date</label>
					<input type="text" name="made_date" id="made_date"
						<cfif variables.action EQ "new">required aria-required="true" class="data-entry-input col-12 reqdClr"</cfif>
						<cfif variables.action EQ "edit">class="data-entry-input col-12" value="#encodeForHTML(variables.editMadeDate)#"</cfif>>
				</div>
			</div>

			<div class="form-row">
				<!--- Expiration Date --->
				<div class="col-12 col-md-3 mb-2">
					<label for="expiration_date" class="data-entry-label">Expiration Date</label>
					<input type="text" name="expiration_date" id="expiration_date"
						class="data-entry-input col-12"
						<cfif variables.action EQ "edit">value="#encodeForHTML(variables.editExpDate)#"</cfif>>
				</div>

				<!--- Expiration Event --->
				<div class="col-12 col-md-3 mb-2">
					<label for="expiration_event" class="data-entry-label">Expiration Event</label>
					<input type="text" name="expiration_event" id="expiration_event"
						class="data-entry-input col-12"
						<cfif variables.action EQ "edit">value="#encodeForHTML(encDetails.expiration_event)#"</cfif>>
				</div>

				<!--- Encumbrance Action --->
				<div class="col-12 col-md-3 mb-2">
					<label for="encumbrance_action" class="data-entry-label">Encumbrance Action</label>
					<select name="encumbrance_action" id="encumbrance_action"
						required aria-required="true"
						class="data-entry-select col-12 reqdClr">
						<cfif variables.action EQ "new"><option value=""></option></cfif>
						<cfloop query="getCtEncumbranceAction">
							<cfif variables.action EQ "edit" AND getCtEncumbranceAction.encumbrance_action EQ encDetails.encumbrance_action>
								<cfset variables.encActSelected = "selected">
							<cfelse>
								<cfset variables.encActSelected = "">
							</cfif>
							<option value="#encodeForHTML(getCtEncumbranceAction.encumbrance_action)#" #variables.encActSelected#>
								#encodeForHTML(getCtEncumbranceAction.encumbrance_action)#
							</option>
						</cfloop>
					</select>
				</div>
			</div>

			<div class="form-row">
				<!--- Remarks --->
				<div class="col-12 mb-2">
					<label for="remarks" class="data-entry-label">Remarks</label>
					<textarea name="remarks" id="remarks" rows="3"
						class="data-entry-input col-12"><cfif variables.action EQ "edit">#encodeForHTML(encDetails.remarks)#</cfif></textarea>
				</div>
			</div>

			<div class="form-row mb-4 mt-1">
				<div class="col-12">
					<cfif variables.action EQ "edit">
						<button type="button" class="btn btn-xs btn-primary"
							onclick="if (validateEncumbranceForm('encumberingAgentId','expiration_date','expiration_event')) { submitEncumbranceForm('encumbranceForm','saveEncumbrance','/encumbrances/viewEncumbrance.cfm?encumbrance_id=#encodeForURL(encDetails.encumbrance_id)#'); }">
							Save Changes
						</button>
						<a href="/Specimens.cfm?execute=true&builderMaxRows=1&action=builderSearch&openParens1=0&field1=ENCUMBRANCE%3AENCUMBRANCE&searchText1=#encodeForUrl(encDetails.encumbrance)#&closeParens1=0#encodeForURL(encDetails.encumbrance_id)#" class="btn btn-xs btn-secondary ml-1" target="_blank">
							See Specimens
						</a>
						<cfif variables.isDeletable>
							<button type="button" class="btn btn-xs btn-danger ml-2" onclick="confirmDeleteEncumbranceFromEditPage('#encodeForHTML(encDetails.encumbrance_id)#');">
								Delete
							</button>
						</cfif>
						<output id="saveResultDiv" class="ml-2">&nbsp;</output>
					<cfelse>
						<button type="button" class="btn btn-xs btn-primary"
							onclick="if (validateEncumbranceForm('encumberingAgentId','expiration_date','expiration_event')) { submitEncumbranceForm('encumbranceForm','createEncumbrance','/encumbrances/viewEncumbrance.cfm?encumbrance_id={encumbrance_id}'); }">
							Create Encumbrance
						</button>
						<a href="/encumbrances/Encumbrances.cfm" class="btn btn-xs btn-warning ml-1">Cancel</a>
					</cfif>
				</div>
			</div>
		</form>
	</section>

	<cfif variables.action EQ "edit">
		<!--- ================================================================
		     "Encumber Cataloged Items" section — edit mode only.
		     Allows curators to add cataloged items to this encumbrance by
		     catalog number (using the makeCatalogedItemAutocompleteMeta picker)
		     and to remove existing items with a Remove button.
		     ================================================================ --->
		<section class="row m-1 pt-2" aria-labelledby="addByCatNumHeading">
			<div class="col-12">
				<div class="add-form mt-2">
					<div class="add-form-header pt-1 px-2">
						<h2 class="h4 mb-0 pb-0" id="addByCatNumHeading">Encumbered Specimens</h2>
					</div>
					<div class="card-body form-row my-1 align-items-end">
						<div class="col-12 col-md-4">
							<label class="data-entry-label" for="guid">Add by catalog number (MCZ:Dept:number)</label>
							<input type="text" id="guid" name="guid" class="data-entry-input" value="" placeholder="MCZ:Dept:1111">
							<input type="hidden" id="collection_object_id" name="collection_object_id" value="">
						</div>
						<div class="col-12 col-md-8">
							<label class="data-entry-label">&nbsp;</label>
							<button type="button" class="btn btn-xs btn-secondary"
								aria-label="Add the selected cataloged item to this encumbrance"
								onclick="addSpecimenToEncumbrance('#encodeForHTML(variables.encumbrance_id)#')">Add to Encumbrance</button>
							<span id="addToEncStatusDiv" class="ml-2"></span>
						</div>
					</div>
					<div class="card-body pt-0">
						<div id="encumbered-specimen-edit-container">
							<p class="text-muted">Loading encumbered specimens&hellip;</p>
						</div>
					</div>
				</div>
			</div>
		</section>
	</cfif>

</main>
</cfoutput>

<script>
	$(document).ready(function () {
		$('#made_date').datepicker({ dateFormat: 'yy-mm-dd' });
		$('#expiration_date').datepicker({ dateFormat: 'yy-mm-dd' });
		makeRichAgentPicker(
			'encumberingAgent',
			'encumberingAgentId',
			'agentIconEnc',
			'agentViewEnc',
			'<cfoutput><cfif variables.action EQ "edit">#val(encDetails.encumbering_agent_id)#</cfif></cfoutput>'
		);
		// Unsaved changes monitor — only active in edit mode (the indicator is not present for create)
		if ($('#saveResultDiv').length) {
			function changed() {
				$('#saveResultDiv').html('Unsaved changes.');
				$('#saveResultDiv').addClass('text-danger');
				$('#saveResultDiv').removeClass('text-success');
				$('#saveResultDiv').removeClass('text-warning');
			}
			$('#encumbranceForm input[type=text]').on('change', changed);
			$('#encumbranceForm select').on('change', changed);
			$('#encumbranceForm textarea').on('change', changed);
		}
		// Catalog-number autocomplete and initial specimens list — edit mode only
		if ($('#encumbered-specimen-edit-container').length) {
			makeCatalogedItemAutocompleteMeta('guid', 'collection_object_id');
			loadEncumberedObjectsEdit('<cfoutput>#encodeForHTML(variables.encumbrance_id)#</cfoutput>');
		}
	});
</script>
<script src="/encumbrances/js/encumbrances.js"></script>

<cfinclude template="/shared/_footer.cfm">
