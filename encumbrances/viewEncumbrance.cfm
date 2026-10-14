<!---
encumbrances/viewEncumbrance.cfm

Read-only detail view for a single encumbrance.  Displays all encumbrance metadata
and a tabbed panel listing encumbered objects (currently specimens only; a Localities
tab stub is included to support the planned locality_encumbrance extension).

Architecture note on extending to localities:
When the locality_encumbrance junction table is implemented, the Localities tab
below can be activated by changing its "not yet implemented" placeholder to a call
to loadEncumberedObjects(encumbrance_id, 'locality').  The JS function is already
parameterised to handle this.  A locality_count column should also be added to the
summary badge beside the Localities tab header once that table exists.

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

<cfparam name="url.encumbrance_id" default="">

<cfif len(trim(url.encumbrance_id)) EQ 0>
	<cfinclude template="/errors/404.cfm">
	<cfabort>
</cfif>
<cfset variables.encumbrance_id = trim(url.encumbrance_id)>

<!--- Load the encumbrance record --->
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
		-- TODO: locality_encumbrance -- add count(locality_encumbrance.locality_id) AS locality_count
		--       once the locality_encumbrance junction table is created.
	FROM
		encumbrance
		JOIN preferred_agent_name
			ON encumbrance.encumbering_agent_id = preferred_agent_name.agent_id
		LEFT JOIN coll_object_encumbrance
			ON encumbrance.encumbrance_id = coll_object_encumbrance.encumbrance_id
		-- TODO: locality_encumbrance -- add:
		--       LEFT JOIN locality_encumbrance
		--           ON encumbrance.encumbrance_id = locality_encumbrance.encumbrance_id
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

<cfset pageTitle = "Encumbrance: " & encDetails.encumbrance>
<cfinclude template="/shared/_header.cfm">

<cfoutput>
<main class="container py-3" id="content">

	<div class="row ml-0 mb-1">
		<h1 class="h2 mb-1 col-12 pl-0">
			#encodeForHTML(encDetails.encumbrance)#
			<i class="fas fa-info-circle" onClick="getMCZDocs('encumbrance','encumbrance')" aria-label="help link"></i>
		</h1>
	</div>

	<!--- Navigation and action buttons --->
	<div class="row ml-0 mb-2">
		<div class="col-12 pl-0">
			<a href="/encumbrances/Encumbrances.cfm" class="btn btn-xs btn-secondary">
				<i class="fa fa-arrow-left" aria-hidden="true"></i> Find Encumbrances
			</a>
			<a href="/Specimens.cfm?execute=true&builderMaxRows=1&action=builderSearch&openParens1=0&field1=ENCUMBRANCE%3AENCUMBRANCE&searchText1=#encodeForUrl(encDetails.encumbrance)#&closeParens1=0#encodeForURL(variables.encumbrance_id)#"
				class="btn btn-xs btn-secondary ml-1">
				See Specimens
			</a>
			<cfif isDefined("session.roles") AND listFindNoCase(session.roles,"manage_collection") GT 0>
				<a href="/encumbrances/Encumbrance.cfm?action=edit&encumbrance_id=#encodeForURL(variables.encumbrance_id)#"
					class="btn btn-xs btn-primary ml-1">
					<i class="fa fa-pencil" aria-hidden="true"></i> Edit
				</a>
			</cfif>
		</div>
	</div>

	<!--- Summary metadata card --->
	<section class="row mx-0 border rounded my-2 pt-2" aria-labelledby="encSummaryHeading">
		<h2 id="encSummaryHeading" class="sr-only">Encumbrance Summary</h2>
		<div class="col-12 col-md-4">
			<dl class="row">
				<dt class="col-5 data-entry-label">Encumbrance&nbsp;ID</dt>
				<dd class="col-7">#encodeForHTML(encDetails.encumbrance_id)#</dd>
				<dt class="col-5 data-entry-label">Encumbrance</dt>
				<dd class="col-7">#encodeForHTML(encDetails.encumbrance)#</dd>
				<dt class="col-5 data-entry-label">Action</dt>
				<dd class="col-7">#encodeForHTML(encDetails.encumbrance_action)#</dd>
			</dl>
		</div>
		<div class="col-12 col-md-4">
			<dl class="row">
				<dt class="col-5 data-entry-label">Encumbering Agent</dt>
				<dd class="col-7">
					<a href="/agents/Agent.cfm?agent_id=#encodeForURL(encDetails.encumbering_agent_id)#">
						#encodeForHTML(encDetails.agent_name)#
					</a>
				</dd>
				<dt class="col-5 data-entry-label">Made Date</dt>
				<dd class="col-7">
					<cfif isDate(encDetails.made_date)>
						#dateformat(encDetails.made_date,"yyyy-mm-dd")#
					</cfif>
				</dd>
				<dt class="col-5 data-entry-label">Expiration Date</dt>
				<dd class="col-7">
					<cfif isDate(encDetails.expiration_date)>
						#dateformat(encDetails.expiration_date,"yyyy-mm-dd")#
					</cfif>
				</dd>
				<dt class="col-5 data-entry-label">Expiration Event</dt>
				<dd class="col-7">#encodeForHTML(encDetails.expiration_event)#</dd>
			</dl>
		</div>
		<div class="col-12 col-md-4">
			<dl class="row">
				<dt class="col-5 data-entry-label">Remarks</dt>
				<dd class="col-7">#encodeForHTML(encDetails.remarks)#</dd>
			</dl>
		</div>
	</section>

	<!--- Encumbered objects tabs --->
	<!---
		Architecture note on extending to localities:
		The "Localities" tab below is a stub.  When the locality_encumbrance junction table
		is implemented, change the placeholder inside #encumbered-locality-container# to the
		call loadEncumberedObjects(encumbrance_id, 'locality').  Also update the badge in the
		tab header from a hard-coded 'ndash;' to a live locality_count value once that column
		is available from the summary query above.  No further structural changes are needed.
	--->
	<section class="row mx-0 border rounded my-2" aria-labelledby="encObjectsHeading">
		<h2 id="encObjectsHeading" class="sr-only">Encumbered Objects</h2>
		<div class="col-12 p-0">
			<ul class="nav nav-tabs px-2 pt-2" id="encObjectsTabs" role="tablist">
				<li class="nav-item" role="presentation">
					<a class="nav-link active" id="tab-specimens" data-toggle="tab"
						href="##pane-specimens" role="tab"
						aria-controls="pane-specimens" aria-selected="true"
						onclick="loadEncumberedObjects('#encodeForHTML(variables.encumbrance_id)#','specimen')">
						Specimens
						<span class="badge badge-secondary">#encodeForHTML(encDetails.specimen_count)#</span>
					</a>
				</li>
				<!---
					Localities tab stub.
					TODO: locality_encumbrance -- activate this tab and replace the placeholder below
					with loadEncumberedObjects(encumbranceId, 'locality') when locality_encumbrance is added.
					Also replace the ndash badge with a live locality_count.
				--->
				<li class="nav-item" role="presentation">
					<a class="nav-link" id="tab-localities" data-toggle="tab"
						href="##pane-localities" role="tab"
						aria-controls="pane-localities" aria-selected="false">
						Localities
						<span class="badge badge-secondary">&ndash;</span>
					</a>
				</li>
			</ul>
			<div class="tab-content p-2" id="encObjectsTabContent">

				<!--- Specimens tab pane --->
				<div class="tab-pane fade show active" id="pane-specimens"
					role="tabpanel" aria-labelledby="tab-specimens">
					<div id="encumbered-specimen-container">
						<p class="text-muted">Click the Specimens tab to load encumbered specimens.</p>
					</div>
				</div>

				<!--- Localities tab pane (stub) --->
				<!---
					TODO: locality_encumbrance -- remove the 'not yet implemented' paragraph and call
					loadEncumberedObjects(encumbrance_id, 'locality') via the tab onclick (or the show.bs.tab
					event handler in encumbrances.js) when locality_encumbrance is implemented.
				--->
				<div class="tab-pane fade" id="pane-localities"
					role="tabpanel" aria-labelledby="tab-localities">
					<div id="encumbered-locality-container">
						<p class="text-muted">Locality encumbrances are not yet implemented.</p>
					</div>
				</div>

			</div><!--- /tab-content --->
		</div>
	</section>

</main>
</cfoutput>

<script>
	$(document).ready(function () {
		// Auto-load the specimens tab on page load.
		loadEncumberedObjects('<cfoutput>#encodeForHTML(variables.encumbrance_id)#</cfoutput>', 'specimen');
	});
</script>
<script src="/encumbrances/js/encumbrances.js"></script>

<cfinclude template="/shared/_footer.cfm">
