<!--- 
  specimens/changeQueryPartContainers.cfm manage placement of parts in a container in bulk.

Copyright 2008-2017 Contributors to Arctos
Copyright 2008-2025 President and Fellows of Harvard College

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
<cfset pageTitle="Bulk Move Parts">
<cfset pageHasTabs="true">
<cfinclude template="/shared/_header.cfm">
<cfinclude template="/shared/component/error_handler.cfc" runOnce="true">
<cfinclude template="/containers/component/public.cfc" runOnce="true"><!--- for resolvePartCurrentContainer, used to detect a proxy parent below --->
<!--------------------------------------------------------------------->
<cfif isDefined("result_id") and len(result_id) GT 0>
	<cfset table_name="user_search_table">
</cfif>
<cfif not isDefined("action")>
	<cfset action="entryPoint">
</cfif>
<!--- the part-selection filter criteria, needed again by a destination-fitness block page (see
	checkDestinationFitness/renderDestinationBlockedHtml below) to offer a way back to movePart with
	the same parts already selected, without forcing the whole filter step to be redone. --->
<cfparam name="exist_part_name" default="">
<cfparam name="exist_preserve_method" default="">
<cfparam name="existing_lot_count" default="">
<cfparam name="existing_coll_obj_disposition" default="">

<!--- container types that cannot be used in this tool at all -- unlike a proxy-role container (pin/slide/
	cryovial/envelope/glass vial, handled below by moving the proxy instead of the leaf, with the user's
	explicit confirmation), a jar can hold multiple specimens or glass vials, so this tool can't safely
	auto-move it the same way; moving a jar's contents has to be done deliberately, one container at a time,
	elsewhere (containers/moveContainer.cfm or containers/placePartInContainer.cfm). --->
<cfset DISALLOWED_CONTAINER_TYPES = "jar">

<!--- container_types with ctcontainer_type.role='proxy' -- single-occupant containers (pin/slide/cryovial/
	envelope/glass vial) that can only ever hold one leaf. When a part's own leaf container's immediate
	parent is one of these, moving the part actually means moving the proxy, not the leaf trapped inside
	it -- the same authoritative classification validateContainerPlacement's own CT3 rule already uses,
	looked up live rather than hand-maintained as a second copy of that list. --->
<cfquery name="qProxyContainerTypes" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	SELECT container_type
	FROM ctcontainer_type
	WHERE role = 'proxy'
</cfquery>
<cfset PROXY_CONTAINER_TYPES = valueList(qProxyContainerTypes.container_type)>

<!---
Function commitPartMove. Moves each listed part's actual current container (its own leaf, or a
proxy-role parent when one exists -- see resolvePartCurrentContainer) into a new parent container.
Re-resolves every part's move-target itself rather than trusting a value passed in from an earlier
step, since a client-supplied resolution can't be trusted for a mutating action -- the same
defense-in-depth principle used throughout the containers redesign. Shared by movePartConfirm (when
no part resolves to a proxy, so no confirmation step is needed before committing) and movePart2 (the
actual commit once the user has confirmed a proxy-involving move).
@param partIDs comma-separated list of specimen_part.collection_object_id values to move.
@param target_container_id the destination container_id.
@return a struct: {moved_count}.
--->
<cffunction name="commitPartMove" access="private" returntype="struct" output="false">
	<cfargument name="partIDs" type="string" required="yes">
	<cfargument name="target_container_id" type="numeric" required="yes">

	<cfset var local = StructNew()>
	<cfset local.movedCount = 0>
	<cftransaction>
		<cfloop list="#arguments.partIDs#" index="local.onePartID">
			<cfset local.partContainer = resolvePartCurrentContainer(local.onePartID)>
			<cfif local.partContainer.found>
				<cfquery name="local.moveOne" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="local.moveOne_result">
					UPDATE container
					SET parent_container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.target_container_id#">
					WHERE container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#local.partContainer.move_container_id#">
				</cfquery>
				<cfset local.movedCount = local.movedCount + 1>
			</cfif>
		</cfloop>
	</cftransaction>
	<cfset local.retval = StructNew()>
	<cfset local.retval["moved_count"] = local.movedCount>
	<cfreturn local.retval>
</cffunction>

<!---
Function renderMoveSuccessHtml. Builds the "Successfully moved..." confirmation HTML shared by
movePartConfirm's zero-friction (no proxy involved) path and movePart2's confirmed-commit path, so
both show identical results for identical outcomes.
@param target_container_id the destination container_id parts were just moved into.
@param moved_count how many parts were actually moved.
@param result_id the originating search result_id, to build the "return to move parts" link.
@return an HTML string.
--->
<cffunction name="renderMoveSuccessHtml" access="private" returntype="string" output="false">
	<cfargument name="target_container_id" type="numeric" required="yes">
	<cfargument name="moved_count" type="numeric" required="yes">
	<cfargument name="result_id" type="string" required="yes">

	<cfset var local = StructNew()>
	<cfquery name="local.getTarget" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		SELECT barcode, label, container_type
		FROM container
		WHERE container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.target_container_id#">
	</cfquery>
	<cfsavecontent variable="local.html">
		<cfoutput>
			<div class="row mx-0">
				<div class="col-12 mt-2">
					<h2>Successfully moved #arguments.moved_count# part(s) into #local.getTarget.container_type# #local.getTarget.label# </h2>
					<h4 class="mt-2"><a href="/specimens/changeQueryPartContainers.cfm?result_id=#arguments.result_id#">Return to move parts in bulk</a></h4>
					<h4 class="mt-2"><a href="/containers/Containers.cfm?barcode=#encodeForUrl('=' & local.getTarget.barcode)#&execute=true">View Container</a></h4>
				</div>
			</div>
		</cfoutput>
	</cfsavecontent>
	<cfreturn local.html>
</cffunction>

<!---
Function checkDestinationFitness. Checks a proposed target container against every distinct
container_type actually being moved in this batch (a batch can mix plain "collection object" leaves
with several different proxy types once proxy substitution is involved, so a single representative
check is no longer enough) via validateContainerPlacement, one call per distinct type rather than one
per part. Also separately checks for batch-internal single-occupant overfill -- several plain,
non-proxy parts from this same batch landing together in one container whose type expects exactly one
collection object -- since validateContainerPlacement's own occupancy check only ever sees what's
already in the database, not this batch's other pending moves. Called both from movePartConfirm (to
review before committing) and movePart2 (to gate the actual commit -- never trusting an earlier step's
check alone for a mutating action).
@param partIDs comma-separated list of specimen_part.collection_object_id values to move.
@param target_container_id the destination container_id under consideration.
@return a struct: {blocks: array of "type: message" strings, warnings: array of "type: message" strings}.
--->
<cffunction name="checkDestinationFitness" access="private" returntype="struct" output="false">
	<cfargument name="partIDs" type="string" required="yes">
	<cfargument name="target_container_id" type="numeric" required="yes">

	<cfset var local = StructNew()>
	<cfset local.distinctTypeRepresentative = StructNew()>
	<cfset local.leafPartCount = 0>
	<cfloop list="#arguments.partIDs#" index="local.onePartID">
		<cfset local.partContainer = resolvePartCurrentContainer(local.onePartID)>
		<cfif local.partContainer.found>
			<cfif NOT local.partContainer.is_proxy>
				<cfset local.leafPartCount = local.leafPartCount + 1>
			</cfif>
			<cfif NOT structKeyExists(local.distinctTypeRepresentative, local.partContainer.move_type)>
				<cfset local.distinctTypeRepresentative[local.partContainer.move_type] = local.partContainer.move_container_id>
			</cfif>
		</cfif>
	</cfloop>
	<cfset local.blocks = ArrayNew(1)>
	<cfset local.warnings = ArrayNew(1)>
	<cfloop collection="#local.distinctTypeRepresentative#" item="local.oneType">
		<cfset local.placementResult = validateContainerPlacement(child_container_id=local.distinctTypeRepresentative[local.oneType], proposed_parent_container_id=arguments.target_container_id)>
		<cfif isSimpleValue(local.placementResult)>
			<cfset local.placementResult = deserializeJSON(local.placementResult)>
		</cfif>
		<cfif local.placementResult.severity EQ "block">
			<cfloop array="#local.placementResult.blocks#" index="local.oneMsg">
				<cfset ArrayAppend(local.blocks, "#local.oneType#: #local.oneMsg#")>
			</cfloop>
		<cfelseif local.placementResult.severity EQ "warn">
			<cfloop array="#local.placementResult.warnings#" index="local.oneMsg">
				<cfset ArrayAppend(local.warnings, "#local.oneType#: #local.oneMsg#")>
			</cfloop>
		</cfif>
	</cfloop>

	<!--- validateContainerPlacement's single-occupant-target check (CT5) only ever compares
		against containers ALREADY parented under the target in the database -- none of this
		batch's OTHER parts have moved yet at check time, so it can never by itself catch several
		new, plain (non-proxy) collection objects from the SAME batch all landing in one
		single-occupant target together. Check that batch-internal case directly here. --->
	<cfif local.leafPartCount GT 1>
		<cfquery name="local.queryTargetType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
			SELECT c.container_type, NVL(ct.expects_leaf_child_count, 0) AS expects_leaf_child_count
			FROM container c
				JOIN ctcontainer_type ct ON c.container_type = ct.container_type
			WHERE c.container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.target_container_id#">
		</cfquery>
		<cfif local.queryTargetType.recordcount GT 0 AND val(local.queryTargetType.expects_leaf_child_count) EQ 1>
			<cfset ArrayAppend(local.warnings, "#local.queryTargetType.container_type#: This batch places #local.leafPartCount# collection objects directly into this container at once, but a #local.queryTargetType.container_type# is expected to hold exactly one.")>
		</cfif>
	</cfif>

	<cfset local.retval = StructNew()>
	<cfset local.retval["blocks"] = local.blocks>
	<cfset local.retval["warnings"] = local.warnings>
	<cfreturn local.retval>
</cffunction>

<!---
Function renderDestinationBlockedHtml. Renders the hard-stop page shown when checkDestinationFitness
finds the chosen target unsuitable for at least one type in the batch -- no "Yes" option is offered,
only two ways back: re-filter which parts to move (entryPoint), or keep the same parts and pick a
different container (back to movePart with the original filter criteria, so the part list doesn't
have to be rebuilt from scratch).
@param blocks array of "type: message" block strings from checkDestinationFitness.
@param result_id the originating search result_id.
@param exist_part_name, exist_preserve_method, existing_lot_count, existing_coll_obj_disposition the
	original movePart filter criteria, carried forward so "choose a different container" can return
	to the same part list.
@return an HTML string.
--->
<cffunction name="renderDestinationBlockedHtml" access="private" returntype="string" output="false">
	<cfargument name="blocks" type="array" required="yes">
	<cfargument name="result_id" type="string" required="yes">
	<cfargument name="exist_part_name" type="string" required="no" default="">
	<cfargument name="exist_preserve_method" type="string" required="no" default="">
	<cfargument name="existing_lot_count" type="string" required="no" default="">
	<cfargument name="existing_coll_obj_disposition" type="string" required="no" default="">

	<cfset var local = StructNew()>
	<cfsavecontent variable="local.html">
		<cfoutput>
			<div class="row mx-0">
				<div class="col-12 mt-2">
					<h1 class="h2 mt-1">Container Not Suitable</h1>
					<div class="alert alert-danger">
						<strong>This move cannot proceed -- the chosen container is not a suitable destination:</strong>
						<ul class="mb-0">
							<cfloop array="#arguments.blocks#" index="local.oneMsg">
								<li>#local.oneMsg#</li>
							</cfloop>
						</ul>
					</div>
					<a href="/specimens/changeQueryPartContainers.cfm?result_id=#arguments.result_id#" class="btn btn-xs btn-warning">Choose different parts to move</a>
					<form name="chooseDifferentContainerForm" method="post" action="/specimens/changeQueryPartContainers.cfm" class="d-inline">
						<input type="hidden" name="action" value="movePart">
						<input type="hidden" name="result_id" value="#arguments.result_id#">
						<input type="hidden" name="exist_part_name" value="#encodeForHtml(arguments.exist_part_name)#">
						<input type="hidden" name="exist_preserve_method" value="#encodeForHtml(arguments.exist_preserve_method)#">
						<input type="hidden" name="existing_lot_count" value="#encodeForHtml(arguments.existing_lot_count)#">
						<input type="hidden" name="existing_coll_obj_disposition" value="#encodeForHtml(arguments.existing_coll_obj_disposition)#">
						<button type="submit" class="btn btn-xs btn-secondary">Choose a different container for these parts</button>
					</form>
				</div>
			</div>
		</cfoutput>
	</cfsavecontent>
	<cfreturn local.html>
</cffunction>

<main class="container-fluid px-4 py-3" id="content">
<cftry>
	<cfswitch expression="#action#">
	<cfcase value="entryPoint">
		<cfoutput>
			<cfif isDefined("result_id") and len(result_id) GT 0>
				<cfquery name="getCount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT count(*) ct
					FROM 
						user_search_table
					WHERE
						user_search_table.result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
				</cfquery>
			<cfelse>
				<cfthrow message="Unable to identify parts to work on, required parameter result_id missing.">
			</cfif>
			<script>
				var bc = new BroadcastChannel('resultset_channel');
				bc.onmessage = function (message) { 
					console.log(message);
					if (message.data.result_id == "#result_id#") { 
						messageDialog("Warning: You have removed one or more records from this result set, you must reload this page to see the current list of records this page affects.", "Result Set Changed Warning");
						$(".makeChangeButton").prop("disabled",true);
						$(".makeChangeButton").addClass("disabled");
						$(".tabChangeButton").prop("disabled",true);
						$(".tabChangeButton").addClass("disabled");
					}  
				} 
			</script>
			<div class="row mx-0">
				<div class="col-12">
					<h1 class="h2 px-2">Bulk Part Container Change</h1>
					<p class="px-2 mb-1">Move parts on #getCount.ct# cataloged items from specimen search result [#result_id#]</p>
					<ul>
						<li>Step 1: (This step) Filter a selected set of parts of the cataloged items in the search result that are to be moved.</li>
						<li>Step 2: Review the selected parts and identify the container into which to move them.</li>
						<li>Step 3: Move all the selected parts into the specified container.</li>
						<li>
							<strong>Note on proxy containers:</strong>
							When a part's own collection object container sits directly inside a single-occupant proxy container (a pin, slide, cryovial, envelope, or glass vial), this tool automatically moves that proxy container instead of the collection object trapped inside it, since the proxy is what you actually want relocated in those cases. Step 2 will show you which parts this applies to, and you'll be asked to confirm before anything moves.
						</li>
						<li>
							<strong>Note on jars:</strong>
							You cannot use this tool to move parts currently inside a <strong>jar</strong> -- unlike a proxy container, a jar can hold multiple specimens or glass vials, so this tool can't safely move it as a stand-in for just one part's contents. Step 2 will flag any such parts rather than moving them. To move one of these by hand instead: place the specimen's own part container (or the glass vial it's in, if applicable) individually via <a href="/containers/placePartInContainer.cfm" target="_blank">Place Part into Container</a>, or move the jar itself -- taking everything inside it along -- via <a href="/containers/moveContainer.cfm" target="_blank">Move Container</a>.
						</li>
					</ul>
					<cfif getCount.ct gte 1000>
						<cfthrow message="You can only use this form on up to 1000 specimens at a time. Please <a href='/Specimens.cfm'>revise your search</a>."><!--- " --->
					</cfif>

					<cfset numParts=3>
					<cfquery name="colcde" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						SELECT distinct(collection_cde) 
						FROM 
							user_search_table
							JOIN cataloged_item ON user_search_table.collection_object_id = cataloged_item.collection_object_id
						WHERE
							user_search_table.result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
					</cfquery>
					<cfset colcdes = valuelist(colcde.collection_cde)>
					<cfif listlen(colcdes) is not 1>
						<cfthrow message="You can only use this form on one collection at a time. Please revise your search.">
					</cfif>

					<cfquery name="ctDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						SELECT coll_obj_disposition
						FROM ctcoll_obj_disp
					</cfquery>
					<cfquery name="ctNumericModifiers" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						SELECT modifier 
						FROM ctnumeric_modifiers
					</cfquery>
					<cfquery name="ctPreserveMethod" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						SELECT preserve_method 
						FROM ctspecimen_preserv_method 
						WHERE collection_cde = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#colcdes#">
					</cfquery>

					<!--- queries used for picklists on form  --->
					<cfquery name="existParts" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						SELECT
							count(specimen_part.collection_object_id) partcount,
							specimen_part.part_name
						FROM
							specimen_part
							JOIN user_search_table on specimen_part.derived_from_cat_item = user_search_table.collection_object_id
						WHERE
							user_search_table.result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
						GROUP BY specimen_part.part_name
						ORDER BY specimen_part.part_name
					</cfquery>
					<cfquery name="existPreserve" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						SELECT
							count(specimen_part.collection_object_id) partcount,
							specimen_part.preserve_method
						FROM
							specimen_part
							JOIN user_search_table on specimen_part.derived_from_cat_item = user_search_table.collection_object_id
						WHERE
							user_search_table.result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
						GROUP BY specimen_part.preserve_method
						ORDER BY specimen_part.preserve_method
					</cfquery>
					<cfquery name="existCO" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						SELECT
							coll_object.lot_count_modifier,
							coll_object.lot_count,
							coll_object.coll_obj_disposition
						FROM
							specimen_part
							JOIN coll_object on specimen_part.collection_object_id=coll_object.collection_object_id
							JOIN user_search_table on specimen_part.derived_from_cat_item = user_search_table.collection_object_id
						WHERE
							user_search_table.result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
						GROUP BY 
							coll_object.lot_count_modifier,
							coll_object.lot_count,
							coll_object.coll_obj_disposition
					</cfquery>
					<cfquery name="existLotCountModifier" dbtype="query">
						SELECT lot_count_modifier
						FROM existCO
						GROUP BY lot_count_modifier
						ORDER BY lot_count_modifier
					</cfquery>
					<cfquery name="existLotCount" dbtype="query">
						SELECT lot_count 
						FROM existCO
						GROUP BY lot_count 
						ORDER BY lot_count
					</cfquery>
					<cfquery name="existDisp" dbtype="query">
						SELECT coll_obj_disposition 
						FROM existCO 
						GROUP BY coll_obj_disposition 
						ORDER BY coll_obj_disposition
					</cfquery>

					<div class="col-12 border border-rounded pb-2"> 
						<h2 class="h3 card-title">Move Selected Parts</h2>
						<p class="px-2">Identify existing parts to be moved from all the #getCount.ct# cataloged items.  You must provide at least one filter condition for parts to move.  You will be able to select the destination container, review, and confirm on the next screen.</p>
						<h3 class="h4 px-2">Select values to identify the existing parts to be moved.</h3>
						<form name="movePart" id="movePartForm" method="post" action="/specimens/changeQueryPartContainers.cfm">
							<input type="hidden" name="action" value="movePart">
							<input type="hidden" name="table_name" value="#table_name#">
							<cfif isDefined("result_id") and len(result_id) GT 0>
								<input type="hidden" name="result_id" value="#result_id#">
							</cfif>
							<div class="form-row mx-0">
								<div class="col-12 col-md-3 pt-1">
									<label for="exist_part_name" class="data-entry-label">Part Name</label>
									<select name="exist_part_name" id="exist_part_name" size="1" class="data-entry-select one_must_be_filled_in">
										<option selected="selected" value=""></option>
										<cfloop query="existParts">
											<option value="#Part_Name#">#Part_Name# (#existParts.partCount# parts)</option>
										</cfloop>
										<cfloop query="existParts">
											<option value="!#Part_Name#">NOT #Part_Name#</option>
										</cfloop>
									</select>
								</div>
								<div class="col-12 col-md-3 pt-1">
									<label for="exist_preserve_method" class="data-entry-label">Preserve Method</label>
									<select name="exist_preserve_method" id="exist_preserve_method" size="1" class="data-entry-select one_must_be_filled_in">
										<option selected="selected" value=""></option>
										<cfloop query="existPreserve">
											<option value="#preserve_method#">#preserve_method# (#existPreserve.partCount# parts)</option>
										</cfloop>
										<cfloop query="existPreserve">
											<option value="!#preserve_method#">NOT #preserve_method#</option>
										</cfloop>
									</select>
								</div>
								<div class="col-12 col-md-3 pt-1">
									<label for="existing_lot_count" class="data-entry-label">Lot Count</label>
									<select name="existing_lot_count" id="existing_lot_count" size="1" class="data-entry-select one_must_be_filled_in">
										<option selected="selected" value=""></option>
										<cfloop query="existLotCount">
											<option value="#lot_count#">#lot_count#</option>
										</cfloop>
										<cfloop query="existLotCount">
											<option value="!#lot_count#">NOT #lot_count#</option>
										</cfloop>
									</select>
								</div>
								<div class="col-12 col-md-3 pt-1">
									<label for="existing_coll_obj_disposition" class="data-entry-label">Disposition</label>
									<select name="existing_coll_obj_disposition" id="existing_coll_obj_disposition" size="1" class="data-entry-select one_must_be_filled_in">
										<option selected="selected" value=""></option>
										<cfloop query="existDisp">
											<option value="#coll_obj_disposition#">#coll_obj_disposition#</option>
										</cfloop>
										<cfloop query="existDisp">
											<option value="!#coll_obj_disposition#">NOT #coll_obj_disposition#</option>
										</cfloop>
									</select>
								</div>
							</div>
							<div class="form-row mx-0">
								<div class="col-12 pt-2">
									<script>
										function updateMakeChangeButtonState() {
											var valuesArray = $('##movePartForm .one_must_be_filled_in').get().map(e => e.value);
											$('##makeChangeButton').prop('disabled', valuesArray.every(element => element == ""));
										}
										$(document).ready(function () {
											updateMakeChangeButtonState();
											$('##movePartForm .one_must_be_filled_in').on('change', updateMakeChangeButtonState);
											$("##movePartForm").on("submit",function(e) {
												var valuesArray = $('##movePartForm .one_must_be_filled_in').get().map(e => e.value);
												if (valuesArray.every(element => element == "")){
													e.preventDefault();
													messageDialog("Error: You must specify at least one value to specify which parts to move.","No Move Criteria Provided.");
												}
											});
										});
									</script>
									<input type="submit" value="Select Parts To Move" class="btn btn-xs btn-danger" id="makeChangeButton" disabled>
								</div>
							</div>
						</form>
					</div>

					<cfquery name="getCollObjList" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						SELECT
							cataloged_item.collection_object_id,
							collection.collection,
							collection.collection_cde,
							collection.institution_acronym,
							cataloged_item.cat_num,
							identification.scientific_name,
							specimen_part.part_name,
							specimen_part.preserve_method,
							coll_object.condition,
							coll_object.lot_count_modifier,
							coll_object.lot_count,
							coll_object.coll_obj_disposition,
							coll_object_remark.coll_object_remarks,
							parent_container.container_type,
							parent_container.label
						FROM
							cataloged_item
							join collection on cataloged_item.collection_id=collection.collection_id
							join specimen_part on cataloged_item.collection_object_id=specimen_part.derived_from_cat_item
							join coll_object on specimen_part.collection_object_id=coll_object.collection_object_id
							join identification on cataloged_item.collection_object_id=identification.collection_object_id and accepted_id_fg = 1
							left join coll_object_remark on specimen_part.collection_object_id=coll_object_remark.collection_object_id
							join user_search_table on cataloged_item.collection_object_id=user_search_table.collection_object_id
							JOIN coll_obj_cont_hist ON specimen_part.collection_object_id = coll_obj_cont_hist.collection_object_id AND CURRENT_CONTAINER_FG = 1
							LEFT JOIN container ON coll_obj_cont_hist.container_id = container.container_id
							LEFT JOIN container parent_container ON container.parent_container_id = parent_container.container_id
						WHERE
							user_search_table.result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
						ORDER BY
							collection.collection,cataloged_item.cat_num
					</cfquery>
					<cfquery name="getCatItems" dbtype="query">
						SELECT 
							collection_object_id,collection,cat_num,scientific_name,institution_acronym,collection_cde
						FROM getCollObjList
						GROUP BY
							 collection_object_id,collection,cat_num,scientific_name,institution_acronym,collection_cde
					</cfquery>
					<cfquery name="getContainerTypes" dbtype="query">
						SELECT count(collection_object_id) ct, container_type
						FROM getCollObjList
						WHERE container_type IS NOT NULL
						GROUP BY container_type
						ORDER BY container_type
					</cfquery>
					<h2 class="h3">Current Parent Container Types for the parts in this result set</h2>
					<p>The collection object containers for the parts would be moved out of these containers.  Specimen parts are all in containers of type collection object, this tool moves these collection object containers from their current parent into a new parent.  In some cases (such as a part which is an insect on a pin), the desirable move is of the parent container (the pin, a proxy for the insect) into a new location, rather than moving the part, (the insect) off of its current parent container (the pin), this page handles these cases. </p>
					<cfset hasMovable = false>
					<ul>
						<cfloop query="getContainerTypes">
							<li>
								<cfif listContains(DISALLOWED_CONTAINER_TYPES, container_type)>
									<span class="text-danger">#container_type#</span> [Cannot be moved with this tool]
								<cfelse>
									#container_type# 
									<cfset hasMovable = true>
								</cfif>
								(#ct# parts)
							</li>
						</cfloop>
					</ul>
					<cfif not hasMovable>
						<p class="text-danger">No parts in this result set are in containers that can be moved with this tool.</p>
						<script>
							$(document).ready(function () { 
								$("##makeChangeButton").prop("disabled",true);
								$("##makeChangeButton").addClass("disabled");
							});
						</script>
					</cfif>
					<p>View the current <a href="/containers/Containers.cfm?result_id=#encodeForUrl(result_id)#&execute=true" target="_blank">Container Placement</a> of these parts.</p>
					<h2 class="h3">Specimens for which selected parts are to be moved</h2>
					<table class="table table-responsive table-striped d-xl-table">
						<thead class="thead-light"
							<tr>
								<th>Specimen</th>
								<th>ID</th>
								<th>Parts</th>
							</tr>
						</thead>
						<tbody>
						<cfloop query="getCatItems">
							<tr>
								<td><a href="/guid/#institution_acronym#:#collection_cde#:#cat_num#">#collection# #cat_num#</a></td>
								<td>#scientific_name#</td>
								<cfquery name="getParts" dbtype="query">
									SELECT
										part_name,
										preserve_method,
										condition,
										lot_count_modifier,
										lot_count,
										coll_obj_disposition,
										coll_object_remarks,
										container_type,
										label
									FROM
										getCollObjList
									WHERE
										collection_object_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#collection_object_id#">
									ORDER BY
										part_name, preserve_method, lot_count
								</cfquery>
								<td>
									<table class="table table">
										<thead class="thead-dark">
											<th colspan="1">Part</th>
											<th colspan="1">Preserve Method</th>
											<th colspan="1">Current Placement</th>
											<th colspan="1">Condition</th>
											<th colspan="1">Count</th>
											<th colspan="1">Disposition</th>
											<th colspan="4">Remark</th>
										</thead>
										<tbody>
											<cfloop query="getParts">
												<tr>
													<td colspan="1">#part_name#</td>
													<td colspan="1">#preserve_method#</td>
													<td colspan="1">#label# (#container_type#)</td>
													<td colspan="1">#condition#</td>
													<td colspan="1">#lot_count# #lot_count_modifier#</td>
													<td colspan="1">#coll_obj_disposition#</td>
													<td colspan="4">#coll_object_remarks#</td>
												</tr>
											</cfloop>
										</tbody>
									</table>
								</td>
							</tr>
						</cfloop>
						</tbody>
					</table>
				</div>
			</div>
		</cfoutput>
	</cfcase>
	<!---------------------------------------------------------------------------->
	<cfcase value="movePartConfirm">
		<cfoutput>
			<!--- Resolve every eligible part's actual move-target server-side (never trusting the
				movePart listing's own display as authoritative) to find out whether any of them
				will actually move a proxy container instead of the collection object container
				specified, and check the chosen target's fitness for every distinct type actually
				being moved. A block on the target's fitness hard-stops here -- no "Yes" option --
				since that's not something the user can simply choose to proceed past. Otherwise,
				when nothing needs review, commit immediately -- no added friction for the common
				case. When a proxy substitution or a destination-fitness warning applies, show
				exactly what's affected and require an explicit Yes before anything is written;
				that Yes re-posts to movePart2, which re-checks and re-resolves everything itself
				rather than trusting this confirmation blindly. --->
			<cfset local.proxyRows = ArrayNew(1)>
			<cfloop list="#partIDs#" index="local.onePartID">
				<cfset local.partContainer = resolvePartCurrentContainer(local.onePartID)>
				<cfif local.partContainer.found AND local.partContainer.is_proxy>
					<cfset local.oneProxyRow = StructNew()>
					<cfset local.oneProxyRow["move_type"] = local.partContainer.move_type>
					<cfset local.oneProxyRow["move_label"] = local.partContainer.move_label>
					<cfset local.oneProxyRow["move_barcode"] = local.partContainer.move_barcode>
					<cfset ArrayAppend(local.proxyRows, local.oneProxyRow)>
				</cfif>
			</cfloop>
			<cfset local.destinationFitness = checkDestinationFitness(partIDs=partIDs, target_container_id=target_container_id)>
			<cfif arrayLen(local.destinationFitness.blocks) GT 0>
				#renderDestinationBlockedHtml(blocks=local.destinationFitness.blocks, result_id=result_id, exist_part_name=exist_part_name, exist_preserve_method=exist_preserve_method, existing_lot_count=existing_lot_count, existing_coll_obj_disposition=existing_coll_obj_disposition)#
			<cfelseif arrayLen(local.proxyRows) EQ 0 AND arrayLen(local.destinationFitness.warnings) EQ 0>
				<cfset local.commitResult = commitPartMove(partIDs=partIDs, target_container_id=target_container_id)>
				#renderMoveSuccessHtml(target_container_id=target_container_id, moved_count=local.commitResult.moved_count, result_id=result_id)#
			<cfelse>
				<cfquery name="local.getTarget" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT barcode, label, container_type
					FROM container
					WHERE container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#target_container_id#">
				</cfquery>
				<div class="row mx-0">
					<div class="col-12 mt-2">
						<h1 class="h2 mt-1">Review Container Move</h1>
						<p>Moving into: <strong>#local.getTarget.label#</strong> (#local.getTarget.barcode#), a #local.getTarget.container_type#.</p>
						<cfif arrayLen(local.destinationFitness.warnings) GT 0>
							<div class="alert alert-warning">
								<strong>The chosen container may not be a typical destination for these part(s):</strong>
								<ul class="mb-0">
									<cfloop array="#local.destinationFitness.warnings#" index="local.oneMsg">
										<li>#local.oneMsg#</li>
									</cfloop>
								</ul>
							</div>
						</cfif>
						<cfif arrayLen(local.proxyRows) GT 0>
							<div class="alert alert-warning">
								<cfif arrayLen(local.proxyRows) EQ 1>
									<strong>1 of #listLen(partIDs)# part is inside a single-occupant proxy container.</strong>
									Moving it will move that proxy container, not just the collection object container specified. Please review before continuing:
								<cfelse>
									<strong>#arrayLen(local.proxyRows)# of #listLen(partIDs)# parts are inside single-occupant proxy containers.</strong>
									Moving them will move those proxy containers, not just the collection object containers specified. Please review before continuing:
								</cfif>
								<ul class="mb-0">
									<cfloop array="#local.proxyRows#" index="local.oneProxyRow">
										<li>#local.oneProxyRow.move_type# #local.oneProxyRow.move_label# (#local.oneProxyRow.move_barcode#)</li>
									</cfloop>
								</ul>
							</div>
						</cfif>
						<form name="movePartConfirmForm" method="post" action="/specimens/changeQueryPartContainers.cfm">
							<input type="hidden" name="action" value="movePart2">
							<input type="hidden" name="result_id" value="#result_id#">
							<input type="hidden" name="partIDs" value="#partIDs#">
							<input type="hidden" name="target_container_id" value="#target_container_id#">
							<input type="hidden" name="exist_part_name" value="#encodeForHtml(exist_part_name)#">
							<input type="hidden" name="exist_preserve_method" value="#encodeForHtml(exist_preserve_method)#">
							<input type="hidden" name="existing_lot_count" value="#encodeForHtml(existing_lot_count)#">
							<input type="hidden" name="existing_coll_obj_disposition" value="#encodeForHtml(existing_coll_obj_disposition)#">
							<button type="submit" class="btn btn-xs btn-primary">Yes, move these parts</button>
							<a href="/specimens/changeQueryPartContainers.cfm?result_id=#result_id#" class="btn btn-xs btn-warning">Cancel</a>
						</form>
					</div>
				</div>
			</cfif>
		</cfoutput>
	</cfcase>
	<!---------------------------------------------------------------------------->
	<cfcase value="movePart2">
		<cfoutput>
			<!--- Re-checks destination fitness itself rather than trusting movePartConfirm's own
				check -- a mutating action must never rely solely on an earlier step's validation. --->
			<cfset local.destinationFitness = checkDestinationFitness(partIDs=partIDs, target_container_id=target_container_id)>
			<cfif arrayLen(local.destinationFitness.blocks) GT 0>
				#renderDestinationBlockedHtml(blocks=local.destinationFitness.blocks, result_id=result_id, exist_part_name=exist_part_name, exist_preserve_method=exist_preserve_method, existing_lot_count=existing_lot_count, existing_coll_obj_disposition=existing_coll_obj_disposition)#
			<cfelse>
				<cfset local.commitResult = commitPartMove(partIDs=partIDs, target_container_id=target_container_id)>
				#renderMoveSuccessHtml(target_container_id=target_container_id, moved_count=local.commitResult.moved_count, result_id=result_id)#
			</cfif>
		</cfoutput>
	</cfcase>
	<!---------------------------------------------------------------------------->
	<cfcase value="movePart">
		<cfoutput>
			<script type="text/javascript" src="/containers/js/containers.js"></script>
			<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT
					specimen_part.collection_object_id partID,
					collection.collection,
					cataloged_item.cat_num,
					identification.scientific_name,
					specimen_part.part_name,
					specimen_part.preserve_method,
					coll_object.condition,
					coll_object.lot_count_modifier,
					coll_object.lot_count,
					coll_object.coll_obj_disposition,
					coll_object_remark.coll_object_remarks,
					parent_container.container_type,
					parent_container.label
				FROM
					cataloged_item 
					join collection on cataloged_item.collection_id=collection.collection_id
					join specimen_part on cataloged_item.collection_object_id=specimen_part.derived_from_cat_item 
					join coll_object on specimen_part.collection_object_id=coll_object.collection_object_id
					join identification on cataloged_item.collection_object_id=identification.collection_object_id
					join user_search_table on cataloged_item.collection_object_id=user_search_table.collection_object_id 
					left join coll_object_remark on specimen_part.collection_object_id=coll_object_remark.collection_object_id
					join coll_obj_cont_hist on specimen_part.collection_object_id = coll_obj_cont_hist.collection_object_id AND CURRENT_CONTAINER_FG = 1
					join container on coll_obj_cont_hist.container_id = container.container_id
					left join container parent_container on container.parent_container_id = parent_container.container_id
				WHERE
					user_search_table.result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#"> and
					accepted_id_fg=1 
					<cfif len(exist_part_name) gt 0>
						<cfif left(exist_part_name,1) EQ "!">
							and part_name != <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(exist_part_name,len(exist_part_name)-1)#">
						<cfelse>
						and part_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#exist_part_name#">
						</cfif>
					</cfif>
					<cfif len(exist_preserve_method) gt 0>
						<cfif left(exist_preserve_method,1) EQ "!">
							and preserve_method != <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(exist_preserve_method,len(exist_preserve_method)-1)#">
						<cfelse>
							and preserve_method = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#exist_preserve_method#">
						</cfif>
					</cfif>
					<cfif len(existing_lot_count) gt 0>
						<cfif left(existing_lot_count,1) EQ "!">
							and lot_count != <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#right(existing_lot_count,len(existing_lot_count)-1)#">
						<cfelse>
							and lot_count = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#existing_lot_count#">
						</cfif>
					</cfif>
					<cfif len(existing_coll_obj_disposition) gt 0>
						<cfif left(existing_coll_obj_disposition,1) EQ "!">
							and coll_obj_disposition != <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(existing_coll_obj_disposition,len(existing_coll_obj_disposition)-1)#">
						<cfelse>
							and coll_obj_disposition = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#existing_coll_obj_disposition#">
						</cfif>
					</cfif>
					<cfif len(exist_part_name) EQ 0 AND len(exist_preserve_method) EQ 0 AND len(existing_lot_count) EQ 0 AND len(existing_coll_obj_disposition) EQ 0>
						and 0=1
					</cfif>
				ORDER BY
					collection.collection,cataloged_item.cat_num
			</cfquery>
			<!--- Resolve each part's actual move-target (its own leaf container, or a proxy-role parent
				when one exists -- see resolvePartCurrentContainer) once, up front, so the exact same
				resolution is what's shown in the listing below and what gets carried forward to
				movePartConfirm, rather than the client re-deriving or merely trusting the display.
				A part whose current container is an outright disallowed type (jar, which -- unlike a
				proxy -- can hold multiple specimens or glass vials, so this tool can't safely move it
				as a stand-in for its contents) is flagged for visibility here but left out of what
				"Move these Parts" actually submits, rather than refusing the whole batch outright. --->
			<cfset local.rowInfo = StructNew()>
			<cfset local.eligiblePartIDs = "">
			<cfset local.blockedCount = 0>
			<cfset local.proxyCount = 0>
			<cfloop query="d">
				<cfset local.oneInfo = StructNew()>
				<cfset local.oneInfo["is_blocked"] = (listFindNoCase(DISALLOWED_CONTAINER_TYPES, d.container_type) GT 0)>
				<cfset local.oneInfo["is_proxy"] = false>
				<cfset local.oneInfo["move_type"] = "">
				<cfset local.oneInfo["move_label"] = "">
				<cfset local.oneInfo["proxy_parent_label"] = "">
				<cfset local.oneInfo["proxy_parent_type"] = "">
				<cfif local.oneInfo["is_blocked"]>
					<cfset local.blockedCount = local.blockedCount + 1>
				<cfelse>
					<cfset local.partContainer = resolvePartCurrentContainer(d.partID)>
					<cfif local.partContainer.found AND local.partContainer.is_proxy>
						<cfset local.oneInfo["is_proxy"] = true>
						<cfset local.oneInfo["move_type"] = local.partContainer.move_type>
						<cfset local.oneInfo["move_label"] = local.partContainer.move_label>
						<!--- what the proxy itself is in, not just what the leaf collection object is in
							(the proxy) -- otherwise this row would look identical to a row with no
							proxy at all except for the badge. --->
						<cfset local.oneInfo["proxy_parent_label"] = local.partContainer.current_parent_label>
						<cfset local.oneInfo["proxy_parent_type"] = local.partContainer.current_parent_type>
						<cfset local.proxyCount = local.proxyCount + 1>
					</cfif>
					<cfset local.eligiblePartIDs = listAppend(local.eligiblePartIDs, d.partID)>
				</cfif>
				<cfset local.rowInfo[d.partID] = local.oneInfo>
			</cfloop>

			<section class="row mx-0">
				<div class="col-12 pt-3">
					<h1 class="h2 mt-1">Bulk move parts into a container</h1>
					<h2 class="h3 mt-">Found #d.recordcount# parts to move</h2>
					<cfif local.blockedCount GT 0>
						<p class="text-danger mb-1">
							<cfif local.blockedCount EQ 1>
								<strong>1 of #d.recordcount# part is currently in a jar and cannot be moved with this tool</strong> --
							<cfelse>
								<strong>#local.blockedCount# of #d.recordcount# parts are currently in a jar and cannot be moved with this tool</strong> --
							</cfif>
							a jar can hold multiple specimens or glass vials, so this tool can't safely move it as a stand-in for one part's contents.
							See the CURRENTLY IN column below. To move these, place the specimen's own part container (or its containing glass vial,
							if it's in one) individually via <a href="/containers/placePartInContainer.cfm" target="_blank">Place Part into Container</a>,
							or move the jar itself (taking everything in it along) via <a href="/containers/moveContainer.cfm" target="_blank">Move Container</a>.
						</p>
					</cfif>
					<cfif local.proxyCount GT 0>
						<p class="mb-1">
							<span class="badge badge-warning mr-1">Will move proxy</span>
							<cfif local.proxyCount EQ 1>
								<strong>1 of #d.recordcount# part is inside a single-occupant proxy container</strong> (pin, slide,
								cryovial, envelope, or glass vial) -- moving it will move that proxy container, not just the collection object
								container specified. See the CURRENTLY IN column below; you'll be asked to confirm before anything moves.
							<cfelse>
								<strong>#local.proxyCount# of #d.recordcount# parts are inside single-occupant proxy containers</strong> (pin, slide,
								cryovial, envelope, or glass vial) -- moving them will move those proxy containers, not just the collection object
								containers specified. See the CURRENTLY IN column below; you'll be asked to confirm before anything moves.
							</cfif>
						</p>
					</cfif>
					<cfset targeturl="/specimens/changeQueryPartContainers.cfm?result_id=#result_id#">
					<cfif d.recordcount EQ 0>
						<h3 class="h4 mt-2">
							Return to the Bulk Part Move tool <a href="#targeturl#">to change your criteria of which parts to move</a>.
						</h3>
					<cfelse>
						<div class="p-2 border border-rounded">
							<form name="movePartForm" method="post" action="/specimens/changeQueryPartContainers.cfm">
								<input type="hidden" name="action" value="movePartConfirm">
								<input type="hidden" name="result_id" value="#result_id#">
								<input type="hidden" name="partIDs" value="#local.eligiblePartIDs#">
								<!--- carried forward so a later destination-fitness block page can offer a way
									back to this same part list without re-filtering from scratch. --->
								<input type="hidden" name="exist_part_name" value="#encodeForHtml(exist_part_name)#">
								<input type="hidden" name="exist_preserve_method" value="#encodeForHtml(exist_preserve_method)#">
								<input type="hidden" name="existing_lot_count" value="#encodeForHtml(existing_lot_count)#">
								<input type="hidden" name="existing_coll_obj_disposition" value="#encodeForHtml(existing_coll_obj_disposition)#">

								<input type="hidden" name="target_container_id" id="target_container_id" value="">
								<div class="form-row mb-2">
									<div class="col-12 col-md-6">
										<!--- plain container autocomplete, plus the "Choose..." picker dialog for the
											same purpose -- room/type limit selects were removed here since the
											picker dialog already covers narrowing the search by type/ancestor. --->
										<label for="container" class="data-entry-label">Container to put parts into:</label>
										<div class="d-flex align-items-center">
											<input type="text" name="container" id="container" class="data-entry-input reqdClr flex-grow-1" placeholder="Container Name or Barcode">
											<button type="button" id="chooseTargetContainerBtn" class="btn btn-xs btn-secondary ml-1">Choose...</button>
										</div>
										<script>
											function updateMoveButtonState() {
												var hasTarget = $('##target_container_id').val().length > 0;
												$('##submitButton').prop('disabled', !hasTarget);
											}
											$(document).ready(function () {
												makeContainerAutocompleteMeta("container", "target_container_id", true);
												$('##container').on('autocompleteselect autocompletechange', function() {
													// allow the autocomplete widget's own select/change handlers to populate target_container_id first.
													window.setTimeout(updateMoveButtonState, 10);
												});
												$('##chooseTargetContainerBtn').on('click', function() {
													openContainerPickerDialog({
														mode: 'find',
														dialogTitle: 'Select Container to Put Parts Into',
														onSelect: function(selectedId, selectedLabel, wrapper) {
															$('##target_container_id').val(selectedId);
															$('##container').val(selectedLabel);
															wrapper.dialog('close');
															updateMoveButtonState();
														}
													});
												});
											});
										</script>
									</div>
									<div class="col-12 col-md-6">
										<label class="data-entry-label">Then...</label>
										<div>
											<cfif len(local.eligiblePartIDs) EQ 0>
												<button type="button" class="btn btn-xs btn-secondary" disabled>Move these Parts</button>
												<div class="small text-danger">No eligible parts to move -- all are blocked (see above).</div>
											<cfelse>
												<input type="submit" id="submitButton" value="Move these Parts" class="btn btn-xs btn-secondary" disabled>
												<div class="small text-muted">Choose a container first.</div>
											</cfif>
										</div>
									</div>
								</div>
							</form>
							<h3 class="h4 mt-2">
								Or return to the Bulk Part Management tool <a href="#targeturl#">to change your criteria of which parts to move</a>.
							</h3>
							<table class="table table-responsive table-striped d-xl-table">
								<thead class="thead-light">
								<tr>
									<th>Specimen</th>
									<th>ID</th>
									<th>PartToBeMoved</th>
									<th>PreserveMethod</th>
									<th>CurrentlyIn</th>
									<th>Condition</th>
									<th>CntMod</th>
									<th>Cnt</th>
									<th>Dispn</th>
									<th>Remark</th>
								</tr>
								</thead>
								<tbody>
									<cfloop query="d">
										<cfset local.oneInfo = local.rowInfo[d.partID]>
										<tr>
											<td>#collection# #cat_num#</td>
											<td>#scientific_name#</td>
											<td>#part_name#</td>
											<td>#preserve_method#</td>
											<td>
												#label# (#container_type#)
												<cfif local.oneInfo.is_proxy AND len(local.oneInfo.proxy_parent_label) GT 0>
													in #local.oneInfo.proxy_parent_label# (#local.oneInfo.proxy_parent_type#)
												</cfif>
												<cfif local.oneInfo.is_blocked>
													<br><span class="badge badge-danger">Blocked</span> a jar can't be auto-moved by this tool
												<cfelseif local.oneInfo.is_proxy>
													<br><span class="badge badge-warning">Will move #local.oneInfo.move_type#</span> #local.oneInfo.move_label#
												</cfif>
											</td>
											<td>#condition#</td>
											<td>#lot_count_modifier#</td>
											<td>#lot_count#</td>
											<td>#coll_obj_disposition#</td>
											<td>#coll_object_remarks#</td>
										</tr>
									</cfloop>
								</tbody>
							</table>
						</div>
					</cfif>
				</div>
			</section>
		</cfoutput>
	</cfcase>
	<!---------------------------------------------------------------------------->
	</cfswitch>
<cfcatch>
	<h2 class="h3 px-2 mt-1">Error</h2>
	<cfoutput>
		<cfset error_message = cfcatchToErrorMessage(cfcatch)>
		<p class="px-2">#error_message#</p>
	</cfoutput>
</cfcatch>
</cftry>
</main>

<cfinclude template="/shared/_footer.cfm">
