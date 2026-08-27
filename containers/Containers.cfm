<!---
/containers/Containers.cfm
	Browse and search the container hierarchy.

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

<!--- 

This file relies heavily on containers/js/containers.js.

containers/js/containers.js coordinates the redesigned container browse/search experience.
It loads container-type metadata first, then renders either the top-level hierarchy tree or
search-result, orphan, and contents tables from the same server payload conventions. Tree
helpers build structural nodes, hide large placed-child groups behind toggle sections, and
expand breadcrumb paths for Explore so the selected node opens in context. Table helpers
render the paged orphan, contents, and search views and reuse the same action-button
builders and details-dialog loader so browsing, viewing, editing, specimen lookup, and
create-child actions stay consistent across all container presentations.

/containers/js/containers.js contains javascript functions to implement the redesigned
container browse and search experience, tying together server-side metadata, AJAX calls,
and client-side rendering into a consistent UI for working with containers. It is
responsible for loading container-type metadata, building and navigating the hierarchical
container tree, rendering a variety of paged result tables (contents, orphans, search
results), and coordinating common actions such as viewing details, editing, exploring in
context, and launching specimen searches.

Core **autocomplete helpers** (for example, functions that create "container picker"
controls) turn a paired visible text input and hidden container_id field into an
autocomplete widget that shows container metadata in the picklist and records a selected
container. Variants support restricting results by type or excluding collection-object
containers, and optionally clear inputs when the user types non-matching values. These
helpers provide a standard pattern for container selection across forms.

A set of **container type metadata and role utilities** manage the in-memory map of
container types and their functional roles (structural, proxy, leafbearer, leaf). These
functions normalize type keys, apply metadata returned from the server (with a built-in
fallback map), rebuild the list of single-occupant container types, and expose simple
lookups to determine type roles, whether a container can have children, and how its role
should be displayed in the UI (including role badges).

The **browsing and navigation functions** orchestrate the top-level hierarchy view and
tree navigation. They initialize the browse panel, load and render structural children on
demand, expand breadcrumb paths so that a searched-for container is opened in context,
and handle special cases such as unplaced containers or structural orphan sections hidden
behind toggles. Supporting helpers manage selection and highlighting, ensure that grouped
sections are visible when needed, and split child nodes into structural and placed groups
for more efficient display.

On the tabular side, **table and action rendering helpers** build the paged tables that
back search results, orphan listings, and leaf-level contents. They construct standard
action buttons and links (View, Edit, Details, Add Child), apply shared CSS styling, and
generate navigation controls for paging. Complementary functions format container display
strings, attach role and shape badges, and render specimen-related cells that link
containers to fixed specimen searches, including lazy checks for the presence of
descendant specimens.

Finally, **details, CRUD, and layout utilities** tie the module into the rest of the
application workflow. They load container details into a shared modal dialog, submit
create and edit forms via AJAX with appropriate feedback and redirect handling, confirm
and execute container deletions, and render container position layouts (grids or fallback
tables) for containers with defined positions. Together, these categories of functions
provide a cohesive client-side layer that keeps container browsing, searching, and
editing behavior consistent across the application.

--->


<cfparam name="url.action" default="">
<cfparam name="url.container_id" default="">
<cfparam name="url.search_term" default="">
<cfparam name="url.container_type" default="">
<cfparam name="url.barcode" default="">
<cfparam name="url.description" default="">
<cfparam name="url.department" default="">
<cfparam name="url.tree_property" default="">
<cfparam name="url.has_positions" default="">
<cfparam name="url.position_filter" default="">
<!--- Legacy params retained for old saved search links; mapped into position_filter below. --->
<cfparam name="url.in_position" default="">
<cfparam name="url.position_value" default="">
<cfparam name="url.contains_guids" default="">
<cfparam name="url.contains_result_id" default="">
<cfparam name="url.contains_collection_object_ids" default="">
<!--- resolved to contains_guids/contains_result_id/contains_collection_object_ids below, not handled as their own search fields --->
<cfparam name="url.collection_object_id" default="">
<cfparam name="url.result_id" default="">
<cfparam name="url.loan_number" default="">
<cfparam name="url.accn_number" default="">
<cfparam name="url.deacc_number" default="">
<cfparam name="url.transaction_id" default="">
<cfparam name="url.execute" default="">
<cfparam name="url.container_id" default="">
<!--- Resolve search params: form (POST) takes priority over url (GET) --->
<cfif isDefined("form.search_term")>
	<cfset variables.search_term = trim(form.search_term)>
<cfelse>
	<cfset variables.search_term = trim(url.search_term)>
</cfif>
<cfif isDefined("form.container_id")>
	<cfset variables.container_id = trim(form.container_id)>
<cfelse>
	<cfset variables.container_id = trim(url.container_id)>
</cfif>
<cfif isDefined("form.container_type")>
	<cfset variables.container_type = trim(form.container_type)>
<cfelse>
	<cfset variables.container_type = trim(url.container_type)>
</cfif>
<!--- a comma-list container_type (e.g. arriving from browseContainers.cfm's department
	picker) can't be represented as a single selected <option>, so the search form shows
	it as an editable text field instead of the picklist in that case. --->
<cfset variables.containerTypeIsList = (listLen(variables.container_type) GT 1)>
<cfif isDefined("form.barcode")>
	<cfset variables.barcode = trim(form.barcode)>
<cfelse>
	<cfset variables.barcode = trim(url.barcode)>
</cfif>
<cfif isDefined("form.description")>
	<cfset variables.description = trim(form.description)>
<cfelse>
	<cfset variables.description = trim(url.description)>
</cfif>
<cfif isDefined("form.department")>
	<cfset variables.department = trim(form.department)>
<cfelse>
	<cfset variables.department = trim(url.department)>
</cfif>
<cfif isDefined("form.tree_property")>
	<cfset variables.tree_property = trim(form.tree_property)>
<cfelse>
	<cfset variables.tree_property = trim(url.tree_property)>
</cfif>
<cfif isDefined("form.has_positions")>
	<cfset variables.has_positions = trim(form.has_positions)>
<cfelse>
	<cfset variables.has_positions = trim(url.has_positions)>
</cfif>
<cfif isDefined("form.position_filter")>
	<cfset variables.position_filter = trim(form.position_filter)>
<cfelseif len(trim(url.position_filter)) GT 0>
	<cfset variables.position_filter = trim(url.position_filter)>
<cfelseif lcase(trim(url.in_position)) EQ "any">
	<cfset variables.position_filter = "NOT NULL">
<cfelseif lcase(trim(url.in_position)) EQ "none">
	<cfset variables.position_filter = "NULL">
<cfelseif lcase(trim(url.in_position)) EQ "specific" AND len(trim(url.position_value)) GT 0>
	<cfset variables.position_filter = trim(url.position_value)>
<cfelseif len(trim(url.position_value)) GT 0>
	<cfset variables.position_filter = trim(url.position_value)>
<cfelse>
	<cfset variables.position_filter = "">
</cfif>
<cfif isDefined("form.execute")>
	<cfset variables.execute = trim(form.execute)>
<cfelse>
	<cfset variables.execute = trim(url.execute)>
</cfif>
<cfif isDefined("form.container_id")>
	<cfset variables.container_id = trim(form.container_id)>
<cfelse>
	<cfset variables.container_id = trim(url.container_id)>
</cfif>
<cfif isDefined("form.contains_guids")>
	<cfset variables.contains_guids = trim(form.contains_guids)>
<cfelse>
	<cfset variables.contains_guids = trim(url.contains_guids)>
</cfif>
<cfif isDefined("form.contains_result_id")>
	<cfset variables.contains_result_id = trim(form.contains_result_id)>
<cfelse>
	<cfset variables.contains_result_id = trim(url.contains_result_id)>
</cfif>
<cfif isDefined("form.contains_collection_object_ids")>
	<cfset variables.contains_collection_object_ids = trim(form.contains_collection_object_ids)>
<cfelse>
	<cfset variables.contains_collection_object_ids = trim(url.contains_collection_object_ids)>
</cfif>
<cfif isDefined("form.loan_number")>
	<cfset variables.loan_number = trim(form.loan_number)>
<cfelse>
	<cfset variables.loan_number = trim(url.loan_number)>
</cfif>
<cfif isDefined("form.accn_number")>
	<cfset variables.accn_number = trim(form.accn_number)>
<cfelse>
	<cfset variables.accn_number = trim(url.accn_number)>
</cfif>
<cfif isDefined("form.deacc_number")>
	<cfset variables.deacc_number = trim(form.deacc_number)>
<cfelse>
	<cfset variables.deacc_number = trim(url.deacc_number)>
</cfif>
<cfif isDefined("form.transaction_id")>
	<cfset variables.transaction_id = trim(form.transaction_id)>
<cfelse>
	<cfset variables.transaction_id = trim(url.transaction_id)>
</cfif>
<cfset variables.canEditContainers = isdefined("session.roles") AND listfindnocase(session.roles,"manage_container")>
<cfset variables.containsSummaryText = "">
<cfset variables.containsReadonly = false>
<cfset variables.transactionSummaryText = "">
<cfset variables.transactionReadonly = false>
<cfset variables.CONTAINS_RESULT_ID_DISPLAY_THRESHOLD = 25>

<cfset pageTitle = "Containers">
<cfset pageHasContainers = true>
<cfinclude template="/shared/_header.cfm">
<link rel="stylesheet" href="/containers/css/containers.css">

<cfquery name="ctcontainer_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	SELECT container_type
	FROM ctcontainer_type
	ORDER BY container_type
</cfquery>
<cfquery name="positionCountOptions" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
	SELECT DISTINCT
		number_positions
	FROM
		container
	WHERE
		number_positions IS NOT NULL
		AND number_positions > 0
	ORDER BY
		number_positions
</cfquery>

<!--- if given a container_id lookup the container label and barcode and set the search_term and barcode to that label or barcode --->
<cfif len(variables.container_id) GT 0>
	<cfquery name="containerLookup" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		SELECT label, barcode
		FROM container
		WHERE container_id = <cfqueryparam value="#variables.container_id#" cfsqltype="cf_sql_integer">
	</cfquery>
	<cfif containerLookup.recordcount EQ 1>
		<cfset variables.search_term = containerLookup.label>
		<cfif len(containerLookup.barcode) GT 0>
			<cfset variables.barcode = "=#containerLookup.barcode#">
		<cfelse>
			<cfset variables.barcode = "">
		</cfif>
	</cfif>
</cfif>

<!--- given one or more raw collection_object_ids (each may be a part or a cataloged item, and
	there may be hundreds of them, e.g. from a classic specimen search results page), resolve to
	distinct cataloged items and
	populate Contains directly when there are few enough to be a readable/editable list; otherwise
	pass the raw id list through as its own search argument, the same threshold pattern used below
	for a saved search's result_id. --->
<cfif len(url.collection_object_id) GT 0>
	<cfset variables.cleanedContainsIds = "">
	<cfloop list="#url.collection_object_id#" index="variables.oneRawContainsId">
		<cfif isNumeric(trim(variables.oneRawContainsId))>
			<cfset variables.cleanedContainsIds = listAppend(variables.cleanedContainsIds, trim(variables.oneRawContainsId))>
		</cfif>
	</cfloop>
	<cfif len(variables.cleanedContainsIds) GT 0>
		<cfquery name="resolveContainsIdListParts" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			SELECT collection_object_id, derived_from_cat_item
			FROM specimen_part
			WHERE collection_object_id IN (<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.cleanedContainsIds#" list="true">)
		</cfquery>
		<cfset variables.resolvedContainsCatalogedItemIds = "">
		<cfset variables.containsIdListFoundAsPart = "">
		<cfloop query="resolveContainsIdListParts">
			<cfset variables.containsIdListFoundAsPart = listAppend(variables.containsIdListFoundAsPart, resolveContainsIdListParts.collection_object_id)>
			<cfif NOT listFind(variables.resolvedContainsCatalogedItemIds, resolveContainsIdListParts.derived_from_cat_item)>
				<cfset variables.resolvedContainsCatalogedItemIds = listAppend(variables.resolvedContainsCatalogedItemIds, resolveContainsIdListParts.derived_from_cat_item)>
			</cfif>
		</cfloop>
		<cfloop list="#variables.cleanedContainsIds#" index="variables.oneRawContainsId">
			<cfif NOT listFind(variables.containsIdListFoundAsPart, variables.oneRawContainsId) AND NOT listFind(variables.resolvedContainsCatalogedItemIds, variables.oneRawContainsId)>
				<cfset variables.resolvedContainsCatalogedItemIds = listAppend(variables.resolvedContainsCatalogedItemIds, variables.oneRawContainsId)>
			</cfif>
		</cfloop>
		<cfif listLen(variables.resolvedContainsCatalogedItemIds) GT 0 AND listLen(variables.resolvedContainsCatalogedItemIds) LTE variables.CONTAINS_RESULT_ID_DISPLAY_THRESHOLD>
			<cfquery name="resolveContainsIdListGuids" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT guid
				FROM <cfif ucase(session.flatTableName) EQ "FLAT">flat<cfelse>filtered_flat</cfif>
				WHERE collection_object_id IN (<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.resolvedContainsCatalogedItemIds#" list="true">)
			</cfquery>
			<cfset variables.contains_guids = valueList(resolveContainsIdListGuids.guid)>
			<cfset variables.execute = "true">
		<cfelseif listLen(variables.resolvedContainsCatalogedItemIds) GT variables.CONTAINS_RESULT_ID_DISPLAY_THRESHOLD>
			<cfset variables.contains_collection_object_ids = variables.cleanedContainsIds>
			<cfset variables.containsReadonly = true>
			<cfset variables.containsSummaryText = "#listLen(variables.resolvedContainsCatalogedItemIds)# items from a Search">
			<cfset variables.execute = "true">
		</cfif>
	</cfif>
</cfif>

<!--- given a saved search's result_id (a mix of part and/or cataloged item ids), resolve to
	distinct cataloged items and populate Contains directly when there are few enough to be a
	readable/editable list; otherwise pass contains_result_id through as its own search argument,
	so the search query joins user_search_table directly instead of materializing a large list. --->
<cfif len(url.result_id) GT 0>
	<cfquery name="resolveContainsResultItems" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		SELECT DISTINCT NVL(sp.derived_from_cat_item, ust.collection_object_id) AS cataloged_item_id
		FROM user_search_table ust
			LEFT JOIN specimen_part sp ON sp.collection_object_id = ust.collection_object_id
		WHERE ust.result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#url.result_id#">
	</cfquery>
	<cfif resolveContainsResultItems.recordcount GT 0 AND resolveContainsResultItems.recordcount LTE variables.CONTAINS_RESULT_ID_DISPLAY_THRESHOLD>
		<cfquery name="resolveContainsResultGuids" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			SELECT guid
			FROM <cfif ucase(session.flatTableName) EQ "FLAT">flat<cfelse>filtered_flat</cfif>
			WHERE collection_object_id IN (<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#valueList(resolveContainsResultItems.cataloged_item_id)#" list="true">)
		</cfquery>
		<cfset variables.contains_guids = valueList(resolveContainsResultGuids.guid)>
		<cfset variables.execute = "true">
	<cfelseif resolveContainsResultItems.recordcount GT variables.CONTAINS_RESULT_ID_DISPLAY_THRESHOLD>
		<cfset variables.contains_result_id = url.result_id>
		<cfset variables.containsReadonly = true>
		<cfset variables.containsSummaryText = "#resolveContainsResultItems.recordcount# items from a Search (via Manage)">
		<cfset variables.execute = "true">
	</cfif>
</cfif>


<!--- given one or more transaction_ids (a loan/accession/deaccession deep link, from an edit
	page, item list, or search results), show a read-only summary in place of the Loan/Accession/
	Deaccession Number fields -- there's no friendly way to type a raw transaction_id, so unlike
	Contains this never falls back to populating an editable field. --->
<cfif len(url.transaction_id) GT 0>
	<cfquery name="resolveTransactionSummary" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		SELECT t.transaction_id, t.transaction_type,
			CASE t.transaction_type
				WHEN 'loan' THEN l.loan_number
				WHEN 'accn' THEN a.accn_number
				WHEN 'deaccession' THEN d.deacc_number
			END AS transaction_number
		FROM trans t
			LEFT JOIN loan l ON l.transaction_id = t.transaction_id AND t.transaction_type = 'loan'
			LEFT JOIN accn a ON a.transaction_id = t.transaction_id AND t.transaction_type = 'accn'
			LEFT JOIN deaccession d ON d.transaction_id = t.transaction_id AND t.transaction_type = 'deaccession'
		WHERE t.transaction_id IN (<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#url.transaction_id#" list="true">)
	</cfquery>
	<cfset variables.transaction_id = url.transaction_id>
	<cfset variables.transactionReadonly = true>
	<cfset variables.execute = "true">
	<cfif resolveTransactionSummary.recordcount EQ 1>
		<cfset variables.transactionTypeLabel = "">
		<cfif resolveTransactionSummary.transaction_type EQ "loan">
			<cfset variables.transactionTypeLabel = "Loan">
		<cfelseif resolveTransactionSummary.transaction_type EQ "accn">
			<cfset variables.transactionTypeLabel = "Accession">
		<cfelseif resolveTransactionSummary.transaction_type EQ "deaccession">
			<cfset variables.transactionTypeLabel = "Deaccession">
		</cfif>
		<cfset variables.transactionSummaryText = "#variables.transactionTypeLabel# #resolveTransactionSummary.transaction_number#">
	<cfelseif resolveTransactionSummary.recordcount GT 1>
		<cfset variables.transactionSummaryText = "#resolveTransactionSummary.recordcount# transactions from a Search">
	<cfelse>
		<cfset variables.transactionSummaryText = "Unknown transaction">
	</cfif>
</cfif>
<main id="content" class="container-fluid">
	<section class="container-fluid" role="search">
		<div class="row mx-0 mb-2">
			<div class="search-box col-12 px-0">
				<div class="search-box-header">
					<h1 class="h3 text-white">Find Containers</h1>
				</div>
				<div class="col-12 px-3 py-3">
					<cfoutput>
					<form id="containerSearchForm" name="containerSearch" method="get" action="/containers/Containers.cfm">
						<fieldset class="bg-light border-default field-set rounded px-2 pt-1 pb-2 mt-2 mx-2">
							<legend class="h6 mb-0 px-3 border-default field-set-legend py-0 w-auto bg-teal font-weight-bold">Container</legend>
							<div class="form-row">
								<div class="col-12 col-md-4 col-xl-3 mb-2">
									<label for="container_type" id="container_type_label" class="data-entry-label">Container Type</label>
									<cfif variables.containerTypeIsList>
										<cfset variables.containerTypeSelectClass = "data-entry-select col-12 d-none">
										<cfset variables.containerTypeSelectDisabled = " disabled">
										<cfset variables.containerTypeRowClass = "d-flex align-items-center form-row">
										<cfset variables.containerTypeInputDisabled = "">
									<cfelse>
										<cfset variables.containerTypeSelectClass = "data-entry-select col-12">
										<cfset variables.containerTypeSelectDisabled = "">
										<cfset variables.containerTypeRowClass = "d-flex align-items-center form-row d-none">
										<cfset variables.containerTypeInputDisabled = " disabled">
									</cfif>
									<select id="container_type" name="container_type" class="#variables.containerTypeSelectClass#"#variables.containerTypeSelectDisabled#>
										<option value=""></option>
										<cfloop query="ctcontainer_type">
											<cfset variables.selectedType = "">
											<cfif ctcontainer_type.container_type EQ variables.container_type>
												<cfset variables.selectedType = " selected">
											</cfif>
											<option value="#encodeForHtml(ctcontainer_type.container_type)#"#variables.selectedType#>#encodeForHtml(ctcontainer_type.container_type)#</option>
										</cfloop>
										<cfloop query="ctcontainer_type">
											<cfset variables.selectedType = "">
											<cfif variables.container_type EQ "!#ctcontainer_type.container_type#">
												<cfset variables.selectedType = " selected">
											</cfif>
											<option value="!#encodeForHtml(ctcontainer_type.container_type)#"#variables.selectedType#>not #encodeForHtml(ctcontainer_type.container_type)#</option>
										</cfloop>
									</select>
									<div id="container_type_list_group" class="#variables.containerTypeRowClass#">
										<div class="col-12 col-md-8 col-lg-9 pr-md-0">
											<input type="text" id="container_type_list" name="container_type"
												class="data-entry-input col-12" aria-labelledby="container_type_label"
												value="#encodeForHtml(variables.container_type)#"#variables.containerTypeInputDisabled#>
										</div>
										<div class="col-12 col-md-4 col-lg-3 pl-md-0 mt-1 mt-md-0">
											<button type="button" id="clearContainerTypeListBtn" class="btn btn-xs btn-warning ml-1" onclick="clearContainerTypeList('container_type', 'container_type_list', 'container_type_list_group')">Clear</button>
										</div>
									</div>
								</div>
								<div class="col-12 col-md-4 col-xl-3 mb-2">
									<label for="search_term" class="data-entry-label">Name (label or barcode)</label>
									<div class="parent-container-picker-row d-flex align-items-center form-row">
										<div class="col-12 col-md-8 col-lg-9 pr-md-0">
											<input type="text" id="search_term" name="search_term"
												class="data-entry-input col-12"
												placeholder="Label or barcode"
												value="#encodeForHtml(variables.search_term)#">
										</div>
										<div class="col-12 col-md-4 col-lg-3 pl-md-0 mt-1 mt-md-0">
											<button type="button" id="chooseSearchContainerBtn" class="btn btn-xs btn-secondary ml-1">Choose…</button>
										</div>
									</div>
									<input type="hidden" id="container_id" name="container_id"
										value="#encodeForHtml(variables.container_id)#">
								</div>
								<div class="col-12 col-md-4 col-xl-3 mb-2">
									<label for="barcode" class="data-entry-label">Unique Identifier (barcode)</label>
									<input type="text" id="barcode" name="barcode"
										class="data-entry-input col-12"
										placeholder="Barcode substring"
										value="#encodeForHtml(variables.barcode)#">
								</div>
								<div class="col-12 col-md-4 col-xl-3 mb-2">
									<label for="description" class="data-entry-label">Description / Remarks</label>
									<input type="text" id="description" name="description"
										class="data-entry-input col-12"
										placeholder="Description or remarks"
										value="#encodeForHtml(variables.description)#">
								</div>
								<div class="col-12 col-md-4 col-xl-3 mb-2">
									<!--- obtain a list of department prefixes from the container labels predecated on convention for naming containers --->
									<cfquery name="fixturePrefixes" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" cachedwithin="#createtimespan(7,0,0,0)#">
										SELECT count(*) as ct, nvl(nvl(substr(label,0, instr(label,'_')-1),substr(label,0, instr(label,'-')-1)),substr(label,0, 4)) as prefix 
										FROM container 
										WHERE container_type = 'fixture' or container_type like '%freezer' or container_type = 'cryovat' 
										GROUP BY nvl(nvl(substr(label,0, instr(label,'_')-1),substr(label,0, instr(label,'-')-1)),substr(label,0, 4))
									</cfquery>
									<label for="department" class="data-entry-label">Department (label prefix, e.g. IZ, Ent)</label>
									<select id="department" name="department" class="data-entry-select col-12">
										<option value=""></option>
										<cfloop query="fixturePrefixes">
											<cfset variables.selectedPrefix = "">
											<cfif fixturePrefixes.prefix EQ variables.department>
												<cfset variables.selectedPrefix = " selected">
											</cfif>
											<option value="#encodeForHtml(fixturePrefixes.prefix)#"#variables.selectedPrefix#>#encodeForHtml(fixturePrefixes.prefix)#</option>
										</cfloop>
									</select>
								</div>
								<div class="col-12 col-md-4 col-xl-3 mb-2">
									<label for="tree_property" class="data-entry-label">Tree Property</label>
									<cfset variables.selEmpty = "">
									<cfset variables.selMisplaced = "">
									<cfset variables.selMixed = "">
									<cfset variables.selUnplacedLeaf = "">
									<cfif variables.tree_property EQ "empty">
										<cfset variables.selEmpty = " selected">
									<cfelseif variables.tree_property EQ "misplaced">
										<cfset variables.selMisplaced = " selected">
									<cfelseif variables.tree_property EQ "mixed">
										<cfset variables.selMixed = " selected">
									<cfelseif variables.tree_property EQ "unplaced_leaf">
										<cfset variables.selUnplacedLeaf = " selected">
									</cfif>
									<select id="tree_property" name="tree_property" class="data-entry-select col-12">
										<option value="">(any)</option>
										<option value="empty"#variables.selEmpty#>Empty (no children)</option>
										<option value="misplaced"#variables.selMisplaced#>Misplaced (single-occupant with &gt;1 object)</option>
										<option value="mixed"#variables.selMixed#>AB Mixed (structural + object children)</option>
										<option value="unplaced_leaf"#variables.selUnplacedLeaf#>Unplaced object (no parent container)</option>
									</select>
								</div>
								<div class="col-12 col-md-4 col-xl-3 mb-2">
									<label for="has_positions" class="data-entry-label">Has Positions</label>
									<select id="has_positions" name="has_positions" class="data-entry-select col-12">
										<option value=""></option>
										<option value="none"<cfif variables.has_positions EQ "none"> selected</cfif>>No positions</option>
										<option value="any"<cfif variables.has_positions EQ "any"> selected</cfif>>Any number of positions</option>
										<option value="has_empty"<cfif variables.has_positions EQ "has_empty"> selected</cfif>>Has empty positions</option>
										<cfloop query="positionCountOptions">
											<cfset variables.selectedPositionCount = "">
											<cfif val(positionCountOptions.number_positions) EQ val(variables.has_positions)>
												<cfset variables.selectedPositionCount = " selected">
											</cfif>
											<option value="#encodeForHtml(positionCountOptions.number_positions)#"#variables.selectedPositionCount#>#encodeForHtml(positionCountOptions.number_positions)#</option>
										</cfloop>
									</select>
								</div>
								<div class="col-12 col-md-4 col-xl-3 mb-2">
									<label for="position_filter" class="data-entry-label">
										Container in Position
										<span class="small ml-1">
											<a href="javascript:void(0);" id="positionFilterAny">any</a>
											|
											<a href="javascript:void(0);" id="positionFilterNone">none</a>
										</span>
									</label>
									<input type="text" id="position_filter" name="position_filter"
										class="data-entry-input col-12"
										placeholder="NULL, NOT NULL, position number, label, or barcode"
										value="#encodeForHtml(variables.position_filter)#">
								</div>
							</div>
						</fieldset>
						<fieldset class="bg-light border-default field-set rounded px-2 pt-1 pb-2 mt-2 mx-2">
							<legend class="h6 mb-0 px-3 border-default field-set-legend py-0 w-auto bg-teal font-weight-bold">Related Cataloged Items</legend>
							<div class="form-row">
								<div class="col-12 col-md-4 col-xl-3 mb-2">
									<label for="contains_guids" class="data-entry-label<cfif variables.containsReadonly> d-none</cfif>" id="contains_guids_label">Contains (specimen GUID)</label>
									<input type="text" id="contains_guids" name="contains_guids"
										class="data-entry-input col-12<cfif variables.containsReadonly> d-none</cfif>"
										placeholder="GUID, or a comma-separated list"
										value="#encodeForHtml(variables.contains_guids)#">
									<div id="containsResultSummary" class="data-entry-label<cfif NOT variables.containsReadonly> d-none</cfif>">
										<span id="containsResultSummaryText">#encodeForHtml(variables.containsSummaryText)#</span>
										(<button type="button" class="btn-link p-0 border-0" onclick="clearContainsResultSummary('contains_guids',['contains_result_id','contains_collection_object_ids'],'containsResultSummary','contains_guids_label')">change</button>)
									</div>
									<input type="hidden" id="contains_id" value="">
									<input type="hidden" id="contains_result_id" name="contains_result_id" value="#encodeForHtml(variables.contains_result_id)#">
									<input type="hidden" id="contains_collection_object_ids" name="contains_collection_object_ids" value="#encodeForHtml(variables.contains_collection_object_ids)#">
								</div>
								<div class="col-12 col-md-8 col-xl-9 mb-2<cfif variables.transactionReadonly> d-none</cfif>" id="transactionNumberFields">
									<div class="form-row">
										<div class="col-12 col-md-4">
											<label for="loan_number" class="data-entry-label">Loan Number</label>
											<input type="text" id="loan_number" name="loan_number" class="data-entry-input col-12" placeholder="Loan number" value="#encodeForHtml(variables.loan_number)#">
										</div>
										<div class="col-12 col-md-4">
											<label for="accn_number" class="data-entry-label">Accession Number</label>
											<input type="text" id="accn_number" name="accn_number" class="data-entry-input col-12" placeholder="Accession number" value="#encodeForHtml(variables.accn_number)#">
										</div>
										<div class="col-12 col-md-4">
											<label for="deacc_number" class="data-entry-label">Deaccession Number</label>
											<input type="text" id="deacc_number" name="deacc_number" class="data-entry-input col-12" placeholder="Deaccession number" value="#encodeForHtml(variables.deacc_number)#">
										</div>
									</div>
								</div>
								<div class="col-12 col-md-8 col-xl-9 mb-2<cfif NOT variables.transactionReadonly> d-none</cfif>" id="transactionSummary">
									<span class="data-entry-label">
										<span id="transactionSummaryText">#encodeForHtml(variables.transactionSummaryText)#</span>
										(<button type="button" class="btn-link p-0 border-0" onclick="clearTransactionSummary('transactionNumberFields','transaction_id','transactionSummary')">change</button>)
									</span>
								</div>
								<input type="hidden" id="transaction_id" name="transaction_id" value="#encodeForHtml(variables.transaction_id)#">
							</div>
						</fieldset>
						<div class="form-row">
							<div class="col-12 mb-2 mt-2 d-flex flex-wrap align-items-center">
								<div>
									<button type="submit" class="btn btn-xs btn-primary">Search</button>
									<a href="Containers.cfm" class="btn btn-xs btn-warning">New Search</a>
									<a href="containerDiagnostics.cfm" class="btn btn-xs btn-secondary">Diagnostics</a>
									<a href="/containers/moveContainer.cfm" class="btn btn-xs btn-secondary ml-1">Move Container</a>
								</div>
								<button type="button" class="btn btn-xs btn-warning ml-auto"
									title="Abandon this search and browse the container hierarchy instead"
									onclick="browseContainerHierarchy('containerBrowsePanel','containerLeafPanel','containerBrowseFeedback')">⌂ Browse Hierarchy</button>
							</div>
						</div>
					</form>
					</cfoutput>
				</div>
			</div>
		</div>
	</section>
	<div class="container-fluid">
		<div class="row">
			<div class="col-12">
				<section>
					<div class="d-flex align-items-center flex-wrap mb-1">
						<h2 class="h4 mr-2 mb-0">Containers/Storage Locations</h2>
					</div>
					<p id="containerBrowseContext" class="text-muted small mb-2"></p>
					<div id="containerBrowsePanel">
						<!--- if no search, this will be populated by initContainerBrowse() --->
						<!--- if executing a search, this will be populated by executeContainerSearch() --->
						<div class="my-2 text-center"><img src="/shared/images/indicator.gif"> Loading...</div>
					</div>
					<div id="containerLeafPanel" class="d-none container-leaf-panel mt-2"></div>
				</section>

				<section class="mb-4">
					<output id="containerBrowseFeedback">&nbsp;</output>
				</section>
			</div>
		</div>
	</div>
</main>

<div id="containerDetailsDialog"></div>

<cfoutput>
<script>
canEditContainers = <cfif variables.canEditContainers>true<cfelse>false</cfif>;
$(document).ready(function() {
	makeContainerAutocompleteMeta('search_term', 'container_id');
	makeCatalogedItemAutocompleteMeta('contains_guids', 'contains_id');
	$('##contains_guids').on('input', function() {
		$('##contains_result_id').val('');
		$('##contains_collection_object_ids').val('');
	});
	$('##chooseSearchContainerBtn').on('click', function() {
		openContainerPickerDialog({
			mode: 'find',
			dialogTitle: 'Select Container',
			onSelect: function(selectedId, selectedLabel, wrapper) {
				$('##container_id').val(selectedId);
				$('##search_term').val(selectedLabel);
				wrapper.dialog('close');
			}
		});
	});

	$('##containerSearchForm').on('submit', function(e) {
		e.preventDefault();
		executeContainerSearch('containerBrowsePanel', 'containerLeafPanel', 'containerBrowseFeedback', 1);
	});
	$('##positionFilterAny').on('click', function() {
		$('##position_filter').val('NOT NULL').focus();
	});
	$('##positionFilterNone').on('click', function() {
		$('##position_filter').val('NULL').focus();
	});

	<cfset variables.hasSearchParams = (
		len(variables.search_term) GT 0 OR
		len(variables.container_type) GT 0 OR
		len(variables.barcode) GT 0 OR
		len(variables.description) GT 0 OR
		len(variables.department) GT 0 OR
		len(variables.tree_property) GT 0 OR
		len(variables.has_positions) GT 0 OR
		len(variables.position_filter) GT 0 OR
		len(variables.contains_guids) GT 0 OR
		len(variables.contains_result_id) GT 0 OR
		len(variables.contains_collection_object_ids) GT 0 OR
		len(variables.loan_number) GT 0 OR
		len(variables.accn_number) GT 0 OR
		len(variables.deacc_number) GT 0 OR
		len(variables.transaction_id) GT 0 OR
		variables.execute EQ "true"
	)>
	<cfif variables.hasSearchParams>
		executeContainerSearch('containerBrowsePanel', 'containerLeafPanel', 'containerBrowseFeedback', 1);
	<cfelse>
		initContainerBrowse("containerBrowsePanel", "containerLeafPanel", "containerBrowseFeedback");
	</cfif>
});
</script>
</cfoutput>

<cfinclude template="/shared/_footer.cfm">
