<!---
collections/CollectionPanel.cfm

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
<!--- Status widgets about one collection for curatorial associates.  Which collection a curatorial
	associate manages isn't recorded, so the page starts with no collection unless one is given in the
	url or was chosen before in this browser.
	Each widget is a card whose body is loaded by loadCollectionWidget (collections/js/collections.js)
	from a get...Html method of collections/component/functions.cfc; add a widget by adding a card, a
	method, and a line in loadCollectionPanel. --->
<cfparam name="url.collection_id" default="">
<cfset pageTitle = "Collection Panel">
<cfinclude template="/shared/_header.cfm">
<cfif NOT ( isdefined("session.roles") AND listfindnocase(session.roles,"curatorial_associate") ) >
	<cflocation url="/errors/forbidden.cfm" addtoken="false">
</cfif>
<cfquery name="collections" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="collections_result">
	SELECT collection_id, collection
	FROM collection
	ORDER BY collection
</cfquery>
<cfset variables.fromUrl = "false">
<cfif isNumeric(url.collection_id)>
	<cfset variables.fromUrl = "true">
</cfif>
<main class="container-fluid py-3" id="content">
	<cfoutput>
		<div class="d-flex flex-wrap align-items-end mb-2">
			<h1 class="h2 mb-0 mr-4">Collection Panel</h1>
			<div>
				<label for="collection_id" class="data-entry-label">Collection</label>
				<select id="collection_id" class="data-entry-select w-auto" data-from-url="#variables.fromUrl#" onchange="loadCollectionPanel(this.value, true);">
					<option value="">Choose a collection</option>
					<cfloop query="collections">
						<cfset selected = "">
						<cfif variables.fromUrl AND collections.collection_id EQ url.collection_id>
							<cfset selected = "selected">
						</cfif>
						<option value="#collections.collection_id#" #selected#>#encodeForHtml(collections.collection)#</option>
					</cfloop>
				</select>
			</div>
		</div>
	</cfoutput>
	<section class="row mb-4 d-none" id="collectionWidgets">
		<div class="col-12 col-xl-6 mb-3">
			<div class="card h-100">
				<div class="card-header">
					<h2 class="h4 mb-0">Loans</h2>
				</div>
				<div class="card-body" id="loansWidget">
					<div class="my-2 text-center"><img src="/shared/images/indicator.gif" alt=""> Loading...</div>
				</div>
			</div>
		</div>
		<div class="col-12 col-xl-6 mb-3">
			<div class="card h-100">
				<div class="card-header">
					<h2 class="h4 mb-0">Borrows</h2>
				</div>
				<div class="card-body" id="borrowsWidget">
					<div class="my-2 text-center"><img src="/shared/images/indicator.gif" alt=""> Loading...</div>
				</div>
			</div>
		</div>
		<div class="col-12 col-xl-6 mb-3">
			<div class="card h-100">
				<div class="card-header">
					<h2 class="h4 mb-0">Specimen Bulkloader</h2>
				</div>
				<div class="card-body" id="specimenBulkloaderWidget">
					<div class="my-2 text-center"><img src="/shared/images/indicator.gif" alt=""> Loading...</div>
				</div>
			</div>
		</div>
		<div class="col-12 col-xl-6 mb-3">
			<div class="card h-100">
				<div class="card-header">
					<h2 class="h4 mb-0">Recently Bulkloaded</h2>
				</div>
				<div class="card-body" id="recentlyBulkloadedWidget">
					<div class="my-2 text-center"><img src="/shared/images/indicator.gif" alt=""> Loading...</div>
				</div>
			</div>
		</div>
		<div class="col-12 col-xl-6 mb-3">
			<div class="card h-100">
				<div class="card-header">
					<h2 class="h4 mb-0">Deaccessions</h2>
				</div>
				<div class="card-body" id="deaccessionsWidget">
					<div class="my-2 text-center"><img src="/shared/images/indicator.gif" alt=""> Loading...</div>
				</div>
			</div>
		</div>
		<div class="col-12 col-xl-6 mb-3">
			<div class="card h-100">
				<div class="card-header">
					<h2 class="h4 mb-0">Permits Expiring</h2>
				</div>
				<div class="card-body" id="permitsWidget">
					<div class="my-2 text-center"><img src="/shared/images/indicator.gif" alt=""> Loading...</div>
				</div>
			</div>
		</div>
		<div class="col-12 col-xl-6 mb-3">
			<div class="card h-100">
				<div class="card-header">
					<h2 class="h4 mb-0">Encumbrances Expiring</h2>
				</div>
				<div class="card-body" id="encumbrancesWidget">
					<div class="my-2 text-center"><img src="/shared/images/indicator.gif" alt=""> Loading...</div>
				</div>
			</div>
		</div>
		<div class="col-12 col-xl-6 mb-3">
			<div class="card h-100">
				<div class="card-header">
					<h2 class="h4 mb-0">Recent Edits</h2>
				</div>
				<div class="card-body" id="recentEditsWidget">
					<div class="my-2 text-center"><img src="/shared/images/indicator.gif" alt=""> Loading...</div>
				</div>
			</div>
		</div>
	</section>
</main>
<script>
	/** Load every widget for a collection.
	 *  @param collectionId the collection_id to report on; none hides the widgets.
	 *  @param remember true to remember the choice in this browser for the next visit.
	 */
	function loadCollectionPanel(collectionId, remember) {
		if (!collectionId) {
			$('#collectionWidgets').addClass('d-none');
			return;
		}
		$('#collectionWidgets').removeClass('d-none');
		if (remember) {
			try { localStorage.setItem("collectionPanelCollectionId", collectionId); } catch (e) { }
		}
		loadCollectionWidget('loansWidget', 'getLoansHtml', collectionId);
		loadCollectionWidget('borrowsWidget', 'getBorrowsHtml', collectionId);
		loadCollectionWidget('specimenBulkloaderWidget', 'getSpecimenBulkloaderHtml', collectionId);
		loadCollectionWidget('recentlyBulkloadedWidget', 'getRecentlyBulkloadedHtml', collectionId);
		loadCollectionWidget('deaccessionsWidget', 'getDeaccessionsHtml', collectionId);
		loadCollectionWidget('permitsWidget', 'getPermitsHtml', collectionId);
		loadCollectionWidget('encumbrancesWidget', 'getEncumbrancesHtml', collectionId);
		loadCollectionWidget('recentEditsWidget', 'getRecentEditsHtml', collectionId);
	}
	$(document).ready(function() {
		var remembered = null;
		if ($('#collection_id').data('fromUrl') !== true) {
			try { remembered = localStorage.getItem("collectionPanelCollectionId"); } catch (e) { }
			if (remembered && $('#collection_id option[value="' + remembered + '"]').length > 0) {
				$('#collection_id').val(remembered);
			}
		}
		loadCollectionPanel($('#collection_id').val(), false);
	});
</script>
<cfinclude template="/shared/_footer.cfm">
