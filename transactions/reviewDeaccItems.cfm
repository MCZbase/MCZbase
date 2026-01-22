<!---
transactions/reviewDeaccItems.cfm

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
<cfif isDefined("url.action") AND len(url.action) GT 0>
	<cfset action = url.action>
<cfelseif isDefined("form.action") AND len(form.action) GT 0>
	<cfset action = form.action>
<cfelse>
	<cfset action = "entryPoint">
</cfif>

<cfif isDefined("url.transaction_id") AND len(url.transaction_id) GT 0>
	<cfset transaction_id = url.transaction_id>
<cfelseif isDefined("form.transaction_id") AND len(form.transaction_id) GT 0>
	<cfset transaction_id = form.transaction_id>
<cfelse>
	<cfthrow message="No transaction specified.">
</cfif>

<!--- feedback message from actions other than entry point to show in entry point --->
<cfif isDefined("url.resultMessage") AND len(url.resultMessage) GT 0>
	<cfset resultMessage = url.resultMessage>
<cfelseif isDefined("form.resultMessage") AND len(form.resultMessage) GT 0>
	<cfset resultMessage = form.resultMessage>
<cfelse>
	<cfset resultMessage = "">
</cfif>

<!--- special case handling to dump deaccession items as csv --->
<cfif isDefined("action") AND variables.action is "download">
	<cfquery name="getDeaccNumber" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		select deacc_number 
		from deaccession 
		where transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#" >
	</cfquery>
	<cfif getDeaccNumber.recordCount eq 0>
		<cfthrow message="No such deaccession transaction as #encodeForHtml(transaction_id)#">
	</cfif>
	<cfset today = dateFormat(now(),"yyyymmdd")>
	<cfset fileName = "deaccession_items_#getDeaccNumber.deacc_number#_#today#.csv">
	<cfquery name="getPartDeaccRequests" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		select distinct
			cataloged_item.collection_object_id,
			cataloged_item.collection_cde,
			cataloged_item.cat_num, 
			collection.institution_acronym,
			collection.collection,
			specimen_part.collection_object_id as partID,
			specimen_part.part_name,
			specimen_part.preserve_method,
			specimen_part.sampled_from_obj_id,
			coll_object.condition,
			coll_object.lot_count,
			coll_object.lot_count_modifier,
			coll_object.coll_obj_disposition,
			deacc_item.item_descr,
			deacc_item.deacc_item_remarks,
			deacc_item.item_instructions,
			deaccession.deacc_number,
			deaccession.deacc_type,
			deaccession.deacc_reason,
			identification.scientific_name,
			collecting_event.began_date,
			collecting_event.ended_date,
			locality.spec_locality,
			locality.sovereign_nation,
			geog_auth_rec.higher_geog,
			encumbrance.Encumbrance,
			decode(encumbering_agent_id,NULL,'',MCZBASE.get_agentnameoftype(encumbering_agent_id)) agent_name,
			concatSingleOtherId(cataloged_item.collection_object_id, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.CustomOtherIdentifier#">) AS CustomID,
			accn.accn_number,
			accn.transaction_id accn_id
		 from 
			deaccession
			join deacc_item on deaccession.transaction_id = deacc_item.transaction_id
			join specimen_part on deacc_item.collection_object_id = specimen_part.collection_object_id 
			join coll_object on specimen_part.collection_object_id = coll_object.collection_object_id
			join cataloged_item on specimen_part.derived_from_cat_item = cataloged_item.collection_object_id 
			join collecting_event on cataloged_item.collecting_event_id = collecting_event.collecting_event_id
			join locality on collecting_event.locality_id = locality.locality_id
			join geog_auth_rec on locality.geog_auth_rec_id = geog_auth_rec.geog_auth_rec_id
			left join coll_object_encumbrance on cataloged_item.collection_object_id = coll_object_encumbrance.collection_object_id
			left join encumbrance on coll_object_encumbrance.encumbrance_id = encumbrance.encumbrance_id
			left join identification on cataloged_item.collection_object_id = identification.collection_object_id AND identification.accepted_id_fg = 1
			join collection on cataloged_item.collection_id=collection.collection_id
			join accn on cataloged_item.accn_id = accn.transaction_id
		WHERE
			deaccession.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#" >
		ORDER BY cat_num
	</cfquery>
	<cfinclude template="/shared/component/functions.cfc">
	<cfset csv = queryToCSV(getPartDeaccRequests)>
	<cfheader name="Content-Type" value="text/csv">
	<cfheader name="Content-Disposition" value="attachment; filename=#fileName#">
	<cfheader name="Content-Length" value="#len(csv)#">
	<cfheader name="Pragma" value="no-cache">
	<cfheader name="Expires" value="0">
	<cfoutput>#csv#</cfoutput>
	<cfabort>
</cfif>

<cfset pageTitle="Review Deaccession Items">
<cfinclude template="/shared/_header.cfm">

<cfinclude template="/transactions/component/itemFunctions.cfc" runonce="true">

<script type='text/javascript' src='/transactions/js/reviewDeaccItems.js'></script>
<script type='text/javascript' src='/specimens/js/public.js'></script><!--- for openHistoryDialog() for parts --->

<cfif not isdefined("transaction_id")>
	<cfthrow message="No transaction specified.">
</cfif>
<cfif not isdefined("action")>
	<cfset action="entryPoint">
</cfif>
<!-------------------------------------------------------------------------------->
<cfif #Action# is "killSS">
	<!--- TODO: Replace with a backing method and ajax update --->
	<cfoutput>
<cftransaction>
	<cfquery name="deleDeacc" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		DELETE FROM deacc_item 
		WHERE collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#partID#">
		and transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
	</cfquery>
	<cfquery name="delePart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		DELETE FROM specimen_part 
		WHERE collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#partID#">
	</cfquery>
	<cfquery name="delePartCollObj" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		DELETE FROM coll_object 
		WHERE collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#partID#">
	</cfquery>
	<cfquery name="delePartRemark" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		DELETE FROM coll_object_remark 
		WHERE collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#partID#">
	</cfquery>

	<cfquery name="getContID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		select container_id 
		from coll_obj_cont_hist 
		where
		collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#partID#">
	</cfquery>
	<cfquery name="deleCollCont" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		DELETE FROM coll_obj_cont_hist 
		WHERE collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#partID#">
	</cfquery>
	<cfquery name="deleCont" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		DELETE FROM container_history 
		WHERE container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getContID.container_id#">
	</cfquery>
	<cfquery name="deleCont" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		DELETE FROM container 
		WHERE container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getContID.container_id#">
	</cfquery>
</cftransaction>
	<cflocation url="a_deaccItemReview.cfm?transaction_id=#transaction_id#">
	</cfoutput>

</cfif>
<!-------------------------------------------------------------------------------->

<cfif #Action# is "BulkUpdateDisp">
	<cfoutput>
		<cftry>
			<cfquery name="getCollObjId" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT collection_object_id 
				FROM deacc_item 
				WHERE transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
			</cfquery>
			<cfset counter = 0>
			<cfloop query="getCollObjId">
				<cfquery name="upDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="upDisp_result">
					UPDATE coll_object 
					SET coll_obj_disposition = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#coll_obj_disposition#">
					WHERE collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
				</cfquery>
				<cfset counter = counter + upDisp_result.recordCount>
			</cfloop>
			<cfset message = "Updated dispositions for #counter# items.">
			<cflocation url="/transactions/reviewDeaccItems.cfm?transaction_id=#transaction_id#&resultMessage=#urlEncodedFormat(message)#">
		<cfcatch>
			<!--- handle error --->
			<cfset errorMessage = "Error updating dispositions: #cfcatch.message#">
			<cflocation url="/transactions/reviewDeaccItems.cfm?transaction_id=#transaction_id#&resultMessage=#urlEncodedFormat(errorMessage)#">
		</cfcatch>
		</cftry>
	</cfoutput>
</cfif>
<!-------------------------------------------------------------------------------->

<cfif #Action# is "BulkUpdatePres">
	<cfoutput>
		<cftry>
			<cfquery name="getCollObjId" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT collection_object_id 
				FROM deacc_item 
				WHERE transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
			</cfquery>
			<cfloop query="getCollObjId">
				<cfquery name="upDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="upDisp_result">
					UPDATE specimen_part 
					SET preserve_method = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#part_preserve_method#">
					WHERE collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
				</cfquery>
				<cfif upDisp_result.recordCount NEQ 1>
					<cfthrow message="Update failed for for collection_object_id #collection_object_id#">
				</cfif>
			</cfloop>
			<cfset message = "Updated preservation method for all items.">
			<cflocation url="/transactions/reviewDeaccItems.cfm?transaction_id=#transaction_id#&resultMessage=#urlEncodedFormat(message)#">
		<cfcatch>
			<!--- handle error --->
			<cfset errorMessage = "Error updating preservation methods: #cfcatch.message#">
			<cflocation url="/transactions/reviewDeaccItems.cfm?transaction_id=#transaction_id#&resultMessage=#urlEncodedFormat(errorMessage)#">
		</cfcatch>
		</cftry>	
	</cfoutput>
</cfif>
<!-------------------------------------------------------------------------------->

<cfif #Action# is "saveDisp">
	<!--- TODO: Replace with a backing method and ajax update --->
	<cfoutput>
		<cftransaction>
			<cftry>
				<cfquery name="upDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE coll_object 
					SET coll_obj_disposition = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#coll_obj_disposition#">
					where collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#partID#">
				</cfquery>
				<cfquery name="upItem" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE deacc_item SET
						transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
						<cfif len(#deacc_item_remarks#) gt 0>
							,deacc_item_remarks = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#deacc_item_remarks#">
						<cfelse>
							,deacc_item_remarks = null
						</cfif>
					WHERE
						collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#partID#">
						AND
						transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
				</cfquery>
				<cftransaction action="commit">
			<cfcatch>
				<cftransaction action="rollback">
				<cfset message = "Error updating deaccession item: #cfcatch.message#">
				<cflocation url="/transactions/reviewDeaccItems.cfm?transaction_id=#transaction_id#&resultMessage=#urlEncodedFormat(message)#">
			</cfcatch>
			</cftry>
		</cftransaction>
		<cfset message = "Deaccession item updated.">
		<cfset action="entryPoint">
		<cflocation url="/transactions/reviewDeaccItems.cfm?transaction_id=#transaction_id#&resultMessage=#urlEncodedFormat(message)#">
	</cfoutput>
</cfif>

<!-------------------------------------------------------------------------------->

<cfif #action# is "entryPoint">
	<cfquery name="getCatItems" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		select distinct
			cataloged_item.collection_object_id,
			cataloged_item.collection_cde,
			cataloged_item.cat_num, 
			collection.institution_acronym,
			collection.collection,
			deaccession.deacc_number,
			deaccession.deacc_type,
			deaccession.deacc_reason,
			identification.scientific_name,
			collecting_event.began_date,
			collecting_event.ended_date,
			locality.spec_locality,
			locality.sovereign_nation,
			geog_auth_rec.higher_geog,
			encumbrance.Encumbrance,
			decode(encumbering_agent_id,NULL,'',MCZBASE.get_agentnameoftype(encumbering_agent_id)) agent_name,
			concatSingleOtherId(cataloged_item.collection_object_id, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.CustomOtherIdentifier#">) AS CustomID,
			accn.accn_number,
			accn.transaction_id accn_id
		 from 
			deaccession
			join deacc_item on deaccession.transaction_id = deacc_item.transaction_id
			join specimen_part on deacc_item.collection_object_id = specimen_part.collection_object_id 
			join coll_object on specimen_part.collection_object_id = coll_object.collection_object_id
			join cataloged_item on specimen_part.derived_from_cat_item = cataloged_item.collection_object_id 
			join collecting_event on cataloged_item.collecting_event_id = collecting_event.collecting_event_id
			join locality on collecting_event.locality_id = locality.locality_id
			join geog_auth_rec on locality.geog_auth_rec_id = geog_auth_rec.geog_auth_rec_id
			left join coll_object_encumbrance on cataloged_item.collection_object_id = coll_object_encumbrance.collection_object_id
			left join encumbrance on coll_object_encumbrance.encumbrance_id = encumbrance.encumbrance_id
			left join identification on cataloged_item.collection_object_id = identification.collection_object_id AND identification.accepted_id_fg = 1
			join collection on cataloged_item.collection_id=collection.collection_id
			join accn on cataloged_item.accn_id = accn.transaction_id
		WHERE
			deaccession.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#" >
		ORDER BY cat_num
	</cfquery>
	<cfquery name="getAllPartsCount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		SELECT count(distinct(deacc_item.collection_object_id)) as part_count
		FROM 
			deaccession
			join deacc_item on deaccession.transaction_id = deacc_item.transaction_id
		WHERE
			deaccession.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#" >
	</cfquery>
	<!--- Obtain list of preserve_method values for the collection that this deaccession is from --->
	<cfquery name="ctPreserveMethod" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		select ct.preserve_method, c.collection_cde 
		from ctspecimen_preserv_method ct 
			left join collection c on ct.collection_cde = c.collection_cde
			left join trans t on c.collection_id = t.collection_id 
		where t.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#" >
	</cfquery>
	<cfquery name="getAboutDeacc" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		select d.deacc_number, c.collection_cde, c.collection
		from collection c 
			left join trans t on c.collection_id = t.collection_id 
			left join deaccession d on t.transaction_id = d.transaction_id
		where t.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#" >
	</cfquery>
	<cfquery name="ctDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		select coll_obj_disposition from ctcoll_obj_disp
	</cfquery>
	<main class="container-fluid mx-2" id="content">
		<cfoutput>
			<script>
				var bc = new BroadcastChannel('deaccession_channel');
				function deaccessionModifiedHere() { 
					bc.postMessage({"source":"reviewdeaccitems","transaction_id":"#transaction_id#"});
				}
				bc.onmessage = function (message) { 
					console.log(message);
					if (message.data.source == "deaccession" && message.data.transaction_id == "#transaction_id#") { 
						console.log("reloading summary from deaccession message");
						reloadSummary();
					}
					if (message.data.source == "adddeaccitems" && message.data.transaction_id == "#transaction_id#") { 
						console.log("reloading data from adddeaccitems message");
						reloadDataNoBroadcast();
					}
				}
				function reloadSummary() { 
					console.log("TODO: reloading deaccession summary");
					// TODO: Implement
				}
			</script>
		
			<cfquery name="catCnt" dbtype="query">
				select count(distinct(collection_object_id)) c from getCatItems
			</cfquery>
			<cfif catCnt.c eq ''><cfset catCount = 'no'><cfelse><cfset catCount = catCnt.c></cfif>
			<cfif getAllPartsCount.part_count eq 0><cfset partCount = 'no'><cfelse><cfset partCount = getAllPartsCount.part_count></cfif>
			<cfset otherIdOn = false>
			<cfif isdefined("showOtherId") and #showOtherID# is "true">
				<cfset otherIdOn = true>
			</cfif>
		
			<section class="row">
				<cfif len(resultMessage) gt 0>
					<h2 class="h3 w-100 mx-3 my-1 p-1 alert alert-info">
						#resultMessage#
					</h2>
				</cfif>
				<h2 class="h3 w-100 mb-0 pb-0 ml-3"> Review items in deaccession </h2>
				<div class="col-12 col-md-4">
					<div id="deaccDetails">
						<!--- lookup information about deaccession via backing function, includes link to deaccession --->
						<cfset deaccessionMetadata = getDeaccessionSummaryHtml(transaction_id=transaction_id,show_buttons='add')>
						#deaccessionMetadata#
					</div>
				</div>
				<div class="col-12 col-md-4 pt-1">
					There are #partCount# items from #catCount# specimens in this deaccession.
					<a href="/transactions/reviewDeaccItems.cfm?action=download&transaction_id=#transaction_id#" target="_blank" class="btn btn-xs btn-secondary">Download (csv)</a>
				</div>
				<div class="col-12">
					<div class="add-form mt-2">
						<div class="add-form-header pt-1 px-2">
							<h2 class="h4 mb-0 pb-0">Actions on each item</h2>
						</div>
						<div class="card-body form-row my-1">
							<div class="col-12 col-md-6">
								<form name="BulkUpdateDisp" method="post" action="/transactions/reviewDeaccItems.cfm">
									<label for="coll_obj_disposition" class="data-entry-label">
										Change disposition of all these items to:
									</label>
									<input type="hidden" name="Action" value="BulkUpdateDisp">
									<input type="hidden" name="transaction_id" value="#transaction_id#" id="transaction_id">
									<select name="coll_obj_disposition" id="coll_obj_disposition" class="data-entry-select">
										<cfloop query="ctDisp">
											<option value="#coll_obj_disposition#">#ctDisp.coll_obj_disposition#</option>
										</cfloop>
									</select>
									<input type="submit" value="Update Dispositions" class="btn btn-xs btn-primary">
								</form>
							</div>
							<cfset padding = "pt-3">
						 	<cfif getAboutDeacc.collection EQ 'Cryogenic'>
								<cfset padding = "p-1">
								<div class="col-12 col-md-6">
									<form name="BulkUpdatePres" method="post" action="/transactions/reviewDeaccItems.cfm">
										<label for="part_preserve_method_bulk" class="data-entry-label">
											Change preservation method of all these items to:
										</label>
										<input type="hidden" name="Action" value="BulkUpdatePres">
										<input type="hidden" name="transaction_id" value="#transaction_id#" id="transaction_id">
										<select name="part_preserve_method" id="part_preserve_method_bulk" class="data-entry-select">
											<cfloop query="ctPreserveMethod">
												<option value="#ctPreserveMethod.preserve_method#">#ctPreserveMethod.preserve_method#</option>
											</cfloop>				
										</select>
										<input type="submit" value="Update Preservation method" class="btn btn-xs btn-primary">
									</form>
								</div>
							</cfif>
							<div class="col-12 col-md-6 border #padding#">
								Note: Edit part counts (particularly for subsamples) in the cataloged item.
							</div>
						</div>
					</div>
				</div>
				<div class="col-12" id="allCatItemsDiv">
					<cfset catItemBlock = getDeaccCatItemHtml(transaction_id=transaction_id,collection_object_id="")>
					#catItemBlock#
				</div>
				<div id="deaccItemEditDialogDiv"></div>
				<div id="deaccItemRemoveDialogDiv"></div>
				<script>
					function refreshDeaccCatItem(catItemId) {
						$.ajax({
							url: '/transactions/component/itemFunctions.cfc',
							type: 'POST',
							data: {
								method: 'getDeaccCatItemHtml',
								collection_object_id: catItemId,
								transaction_id: '#transaction_id#'
							},
							success: function(data) {
								$("##rowDiv"+catItemId).html(data);
							},
      					error: function (jqXHR, textStatus, error) {
         					handleFail(jqXHR,textStatus,error,"reloading deaccession item");
							}
						});
					}
					function reloadDataNoBroadcast() { 
						// call getDeaccCatItemHtml and update allCatItemsDiv
						$.ajax({
							url: '/transactions/component/itemFunctions.cfc',
							type: 'POST',
							data: {
								method: 'getDeaccCatItemHtml',
								collection_object_id: "",
								transaction_id: '#transaction_id#'
							},
							success: function(data) {
								$("##allCatItemsDiv").html(data);
							},
							error: function (jqXHR, textStatus, error) {
								handleFail(jqXHR,textStatus,error,"reloading deaccession items list");
							}
						});
					}
					function updateDeaccItem(deacc_item_id, item_instructions, deacc_item_remarks, coll_obj_disposition, condition, item_descr) {
						setFeedbackControlState( "deaccItemStatusDiv_"+ deacc_item_id, "saving");
						$.ajax({
							url: '/transactions/component/itemFunctions.cfc',
							type: 'POST',
							dataType: 'json',
							data: {
								method: 'updateDeaccItem',
								deacc_item_id: deacc_item_id,
								item_instructions: item_instructions,
								condition: condition,
								deacc_item_remarks: deacc_item_remarks,
								coll_obj_disposition: coll_obj_disposition,
								item_descr: item_descr
							},
							success: function(data) {
								deaccessionModifiedHere();
								setFeedbackControlState( "deaccItemStatusDiv_"+ deacc_item_id, "saved");
							},
							error: function (jqXHR, textStatus, error) {
								handleFail(jqXHR,textStatus,error,"updating deaccession item");
								setFeedbackControlState( "deaccItemStatusDiv_"+ deacc_item_id, "error");
							}
						});
					}
				</script>
			</section>
		</cfoutput>
	</main>
</cfif>

<cfinclude template="/shared/_footer.cfm">
