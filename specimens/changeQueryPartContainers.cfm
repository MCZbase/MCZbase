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
<!--------------------------------------------------------------------->
<cfif isDefined("result_id") and len(result_id) GT 0>
	<cfset table_name="user_search_table">
</cfif>
<cfif not isDefined("action")>
	<cfset action="entryPoint">
</cfif>

<!--- container types that cannot be used in this tool, violate user expectations of what container is being moved --->
<cfset DISALLOWED_CONTAINER_TYPES = "pin,slide,cryovial,jar,envelope,glass vial,freezer box">

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
							<strong>Note:</strong> 
							You cannot use this tool to move parts which have a container of type collection object that are within are in a <strong>#DISALLOWED_CONTAINER_TYPES#</strong>.
							Please use the <a href="/tools/BulkloadContEditParent.cfm">Container Parent Edit Bulkloader</a> to move such parts.
							You can build a csv file for this bulkloader using Manage-><a href='/tools/downloadParts.cfm?result_id=#result_id#' target='_blank'>Parts Report/Download</a>
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
									</select>
								</div>
								<div class="col-12 col-md-3 pt-1">
									<label for="exist_preserve_method" class="data-entry-label">Preserve Method</label>
									<select name="exist_preserve_method" id="exist_preserve_method" size="1" class="data-entry-select one_must_be_filled_in">
										<option selected="selected" value=""></option>
										<cfloop query="existPreserve">
											<option value="#preserve_method#">#preserve_method# (#existPreserve.partCount# parts)</option>
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
									</select>
								</div>
								<div class="col-12 col-md-3 pt-1">
									<label for="existing_coll_obj_disposition" class="data-entry-label">Disposition</label>
									<select name="existing_coll_obj_disposition" id="existing_coll_obj_disposition" size="1" class="data-entry-select one_must_be_filled_in">
										<option selected="selected" value=""></option>
										<cfloop query="existDisp">
											<option value="#coll_obj_disposition#">#coll_obj_disposition#</option>
										</cfloop>
									</select>
								</div>
							</div>
							<div class="form-row mx-0">
								<div class="col-12 pt-2">
									<script>
										$(document).ready(function () { 
											$("##movePartForm").on("submit",function(e) { 
												var valuesArray = $('##movePartForm .one_must_be_filled_in').get().map(e => e.value);
												if (valuesArray.every(element => element == "")){ 
													e.preventDefault();
													messageDialog("Error: You must specify at least one value to specify which parts to move.","No Move Criteria Provided.");
												}
											});
										});
									</script>
									<input type="submit" value="Select Parts To Move" class="btn btn-xs btn-danger" id="makeChangeButton">
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
					<p>The collection object containers for the parts would be moved out of these containers.  Specimen parts are all in containers of type collection object, this tool moves these collection object containers from their current parent into a new parent.  In some cases (such as a part which is an insect on a pin), the desirable move is of the parent container (the pin) into a new location, rather than moving the part, (the insect) off of its current parent container (the pin). </p>
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
	<cfcase value="movePart2">
		<cfoutput>
			<!--- TODO: Support bulk move of parts that are in pins, moving the parent pin container rather than the collection object container --->

			<!--- move parts into specified container --->
			<cfquery name="move" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="move_result">
				UPDATE container
				SET 
					parent_container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#target_container_id#">
				WHERE
					container_id in ( 
						SELECT container_id 
						FROM COLL_OBJ_CONT_HIST
						WHERE 
							collection_object_id IN (<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#partIDs#" list="yes"> )
							and current_container_fg = 1
					)
			</cfquery>
			<cfquery name="getTarget" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getTarget_result">
				SELECT 
					barcode, label, container_type
				FROM 
					container
				WHERE
					container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#target_container_id#">
			</cfquery>
			<div class="row mx-0">
				<div class="col-12 mt-2">
					<h2>Successfully moved #move_result.recordcount# parts into #getTarget.container_type# #getTarget.label# </h2>
					<cfset targeturl="/specimens/changeQueryPartContainers.cfm?result_id=#result_id#">
					<h4 class="mt-2"><a href="#targeturl#">Return to move parts in bulk</a></h4>
					<cfset targeturl="/findContainer.cfm?barcode=#getTarget.barcode#">
					<h4 class="mt-2"><a href="#targeturl#">View Container</a></h4>
				</div>
			</div>
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
						and part_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#exist_part_name#">
					</cfif>
					<cfif len(exist_preserve_method) gt 0>
						and preserve_method = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#exist_preserve_method#">
					</cfif>
					<cfif len(existing_lot_count) gt 0>
						and lot_count = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#existing_lot_count#">
					</cfif>
					<cfif len(existing_coll_obj_disposition) gt 0>
						and coll_obj_disposition = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#existing_coll_obj_disposition#">
					</cfif>
					<cfif len(exist_part_name) EQ 0 AND len(exist_preserve_method) EQ 0 AND len(existing_lot_count) EQ 0 AND len(existing_coll_obj_disposition) EQ 0>
						and 0=1
					</cfif>
				ORDER BY
					collection.collection,cataloged_item.cat_num
			</cfquery>
			<cfquery name="checkTypes" dbtype="query">
				SELECT distinct container_type 
				FROM d
				WHERE container_type IN ( 
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#DISALLOWED_CONTAINER_TYPES#" list="yes" separator=",">
				)
			</cfquery>
			<!--- check for types of parent container that shouldn't be moved  --->
			<cfif checkTypes.recordcount GT 0>
				<cfset error_message = "You cannot use this tool to move parts that are in a #DISALLOWED_CONTAINER_TYPES# . Please use the <a href='/tools/BulkloadContEditParent.cfm' target='_blank'>Container Parent Edit Bulkloader</a> to move these parts.  You can build a csv file for this bulkloader using Manage-><a href='/tools/downloadParts.cfm?result_id=#result_id#' target='_blank'>Parts Report/Download</a>"><!--- " --->
				<cfthrow message="#error_message#">
			</cfif>

			<section class="row mx-0">
				<div class="col-12 pt-3">
					<h1 class="h2 mt-1">Bulk move parts into a container</h1>
					<h2 class="h3 mt-">Found #d.recordcount# parts to move</h2>
					<cfset targeturl="/specimens/changeQueryPartContainers.cfm?result_id=#result_id#">
					<cfif d.recordcount EQ 0>
						<h3 class="h4 mt-2">
							Return to the Bulk Part Move tool <a href="#targeturl#">to change your criteria of which parts to move</a>.
						</h3>
					<cfelse>
						<div class="p-2 border border-rounded">
							<form name="movePartForm" method="post" action="/specimens/changeQueryPartContainers.cfm">
								<input type="hidden" name="action" value="movePart2">
								<input type="hidden" name="result_id" value="#result_id#">
								<input type="hidden" name="partIDs" value="#valuelist(d.partID)#">

								<input type="hidden" name="target_container_id" id="target_container_id" value="">
								<div class="form-row mb-2">
									<div class="col-12 col-md-3">
										<label for="room" class="data-entry-label">Limit search to Room:</label>
										<select name="room" id="room" class="data-entry-select">
											<option value=""></option>
											<cfquery name="rooms" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
												SELECT container_id, label, barcode
												FROM container
												WHERE container_type = 'room'
												ORDER BY label, barcode
											</cfquery>
											<cfloop query="rooms">
												<cfif label NEQ barcode>
													<cfset displaylabel = label & " (" & barcode & ")">
												<cfelse>
													<cfset displaylabel = label>
												</cfif>
												<option value="#container_id#">#displaylabel#</option>
											</cfloop>
										</select>
									</div>
									<div class="col-12 col-md-3">
										<label for="type" class="data-entry-label">Limit search to container Type:</label>
										<select name="type" id="type" class="data-entry-select">
											<option value=""></option>
											<cfquery name="types" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
												SELECT container_type
												FROM ctcontainer_type
												ORDER BY container_type
											</cfquery>
											<cfloop query="types">
												<option value="#container_type#">#container_type#</option>
											</cfloop>
										</select>
									</div>
									<div class="col-12 col-md-3">
										<!--- container autocomplete, limited by type and parent room --->
										<label for="container" class="data-entry-label">Container to put parts into:</label>
										<input type="text" name="container" id="container" class="data-entry-input reqdClr" placeholder="Container Name or Barcode" aria-label="Container Name or Barcode">
										<script>
											$(document).ready(function () { 
												makeContainerAutocompleteLimitedMeta("container", "target_container_id","type","room",true);
											});
										</script>
									</div>
									<div class="col-12 col-md-3">
										<input type="submit" id="submitButton" value="Move these Parts" class="btn btn-xs btn-secondary mt-3">
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
										<tr>
											<td>#collection# #cat_num#</td>
											<td>#scientific_name#</td>
											<td>#part_name#</td>
											<td>#preserve_method#</td>
											<td>#label#</td>
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
