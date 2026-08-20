<!---
/containers/placePartInContainer.cfm

Find a cataloged item's specimen parts and place one (or two together) into a parent container by
barcode, optionally retyping that parent container. Replaces /part2container.cfm and its "New Part"
popup /form/newPart.cfm.

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
<cf_rolecheck>
<cfparam name="url.collection_id" default="">
<cfparam name="url.other_id_type" default="catalog_number">
<cfparam name="url.oidnum" default="">
<cfparam name="url.guid" default="">
<cfparam name="url.execute" default="">

<cfset variables.prefillCollectionId = url.collection_id>
<cfset variables.prefillOtherIdType = url.other_id_type>
<cfset variables.prefillOidnum = url.oidnum>
<cfset variables.prefillExecute = url.execute>

<!--- A guid is a friendlier deep-link than the raw collection_id/other_id_type/oidnum triple --
	resolve it to those same prefill values the same way the real /guid/ route resolves one
	(guid/handler.cfm), via the flat/filtered_flat view chosen per session.flatTableName, rather
	than re-deriving a match by splitting and joining on institution_acronym/collection_cde. --->
<cfif len(trim(url.guid)) GT 0>
	<cfquery name="variables.qGuidLookup" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		SELECT collection_object_id
		FROM <cfif ucase(session.flatTableName) EQ "FLAT">flat<cfelse>filtered_flat</cfif>
		WHERE guid = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(url.guid)#">
	</cfquery>
	<cfif variables.qGuidLookup.recordcount EQ 1>
		<cfquery name="variables.qGuidCatItem" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			SELECT collection_id, cat_num
			FROM cataloged_item
			WHERE collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.qGuidLookup.collection_object_id#">
		</cfquery>
		<cfif variables.qGuidCatItem.recordcount EQ 1>
			<cfset variables.prefillCollectionId = variables.qGuidCatItem.collection_id>
			<cfset variables.prefillOtherIdType = "catalog_number">
			<cfset variables.prefillOidnum = variables.qGuidCatItem.cat_num>
			<cfset variables.prefillExecute = "true">
		</cfif>
	</cfif>
</cfif>

<cfquery name="variables.qCollections" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	SELECT collection, collection_id FROM collection ORDER BY collection
</cfquery>
<cfquery name="variables.qOtherIdTypes" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	SELECT DISTINCT other_id_type FROM ctcoll_other_id_type ORDER BY other_id_type
</cfquery>

<cfset pageTitle = "Put Parts in Containers">
<cfset pageHasContainers = true>
<cfinclude template="/shared/_header.cfm">
<link rel="stylesheet" href="/containers/css/containers.css">

<main id="content" class="container py-3">
	<cfoutput>
	<section class="row mx-0 border rounded my-2 pt-2 mb-4" aria-labelledby="placePartHeading">
		<div class="col-12">
			<h1 class="h2 ml-1 mb-1" id="placePartHeading">Put Parts in Containers</h1>
			<p class="small text-muted">
				Find a cataloged item&#39;s specimen parts, check off any that need to move, then place
				them into a container together by barcode. Each part shows its current placement, so
				parts already accounted for can be left unchecked.
			</p>

			<div class="row border rounded bg-light mx-0 my-2 pt-2 pb-1 px-2">
				<div class="col-12 col-md-4 mb-2">
					<label for="collection_id" class="data-entry-label">Collection</label>
					<select name="collection_id" id="collection_id" class="data-entry-select reqdClr" required aria-required="true" onchange="searchSpecimenParts();">
						<option value=""></option>
						<cfloop query="variables.qCollections">
							<cfset variables.collectionSelected = "">
							<cfif ToString(variables.qCollections.collection_id) EQ variables.prefillCollectionId>
								<cfset variables.collectionSelected = "selected">
							</cfif>
							<option value="#variables.qCollections.collection_id#" #variables.collectionSelected#>#encodeForHtml(variables.qCollections.collection)#</option>
						</cfloop>
					</select>
				</div>
				<div class="col-12 col-md-3 mb-2">
					<label for="other_id_type" class="data-entry-label">ID Type</label>
					<select name="other_id_type" id="other_id_type" class="data-entry-select" onchange="searchSpecimenParts();">
						<cfset variables.catalogSelected = "">
						<cfif variables.prefillOtherIdType EQ "catalog_number">
							<cfset variables.catalogSelected = "selected">
						</cfif>
						<option value="catalog_number" #variables.catalogSelected#>Catalog Number</option>
						<cfloop query="variables.qOtherIdTypes">
							<cfset variables.otherIdSelected = "">
							<cfif variables.qOtherIdTypes.other_id_type EQ variables.prefillOtherIdType>
								<cfset variables.otherIdSelected = "selected">
							</cfif>
							<option value="#encodeForHtml(variables.qOtherIdTypes.other_id_type)#" #variables.otherIdSelected#>#encodeForHtml(variables.qOtherIdTypes.other_id_type)#</option>
						</cfloop>
					</select>
				</div>
				<div class="col-12 col-md-3 mb-2">
					<label for="oidnum" class="data-entry-label">ID Number</label>
					<input type="text" name="oidnum" id="oidnum" class="data-entry-input reqdClr" required aria-required="true" value="#encodeForHtml(variables.prefillOidnum)#" onchange="searchSpecimenParts();">
				</div>
				<div class="col-12 col-md-2 mb-2 d-flex align-items-end">
					<button type="button" id="findPartsBtn" class="btn btn-xs btn-primary" onclick="searchSpecimenParts();">Find Parts</button>
				</div>
				<div class="col-12">
					<div class="form-check form-check-inline">
						<input type="checkbox" class="form-check-input" id="noBarcode" onchange="searchSpecimenParts();">
						<label class="form-check-label" for="noBarcode">Filter for un-barcoded parts</label>
					</div>
					<div class="form-check form-check-inline">
						<input type="checkbox" class="form-check-input" id="noSubsample" onchange="searchSpecimenParts();">
						<label class="form-check-label" for="noSubsample">Exclude subsamples</label>
					</div>
				</div>
			</div>

			<div id="specimenResultsArea" class="my-2"></div>

			<div id="moveLog" class="small"></div>
		</div>
	</section>

	<div id="newPartDialog" title="New Part" style="display:none;">
		<div class="p-3 border bg-light" id="newPartFormArea"></div>
	</div>

	<script>
		$(document).ready(function() {
			<cfif len(trim(variables.prefillCollectionId)) GT 0 AND len(trim(variables.prefillOidnum)) GT 0 AND variables.prefillExecute EQ "true">
				searchSpecimenParts();
			</cfif>
		});
	</script>
	</cfoutput>
</main>
<cfinclude template="/shared/_footer.cfm">
