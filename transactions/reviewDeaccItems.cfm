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
<cfset pageTitle="Review Deaccession Items">
<cfinclude template="/shared/_header.cfm">

<cfinclude template="/transactions/component/itemFunctions.cfc" runonce="true">

<script type='text/javascript' src='/transactions/js/reviewDeaccItems.js'></script>

<cfquery name="ctDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	select coll_obj_disposition from ctcoll_obj_disp
</cfquery>
<cfquery name="ctdeacc_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	select deacc_type from ctdeacc_type
</cfquery>

<cfif not isdefined("transaction_id")>
	<cfthrow message="No transaction specified.">
</cfif>
<cfif not isdefined("action")>
	<cfset action="entryPoint">
</cfif>
<!-------------------------------------------------------------------------------->
<cfif #Action# is "killSS">
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
		<cfquery name="getCollObjId" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			select collection_object_id 
			FROM deacc_item 
			where transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
		</cfquery>
		<cfloop query="getCollObjId">
			<cfquery name="upDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE coll_object 
				SET coll_obj_disposition = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#coll_obj_disposition#">
				where collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
			</cfquery>
		</cfloop>
	<cflocation url="a_deaccItemReview.cfm?transaction_id=#transaction_id#">
	</cfoutput>
</cfif>
<!-------------------------------------------------------------------------------->

<cfif #Action# is "BulkUpdatePres">
	<cfoutput>
		<cfquery name="getCollObjId" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			select collection_object_id 
			FROM deacc_item 
			where transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
		</cfquery>
		<cfloop query="getCollObjId">
			<cfquery name="upDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			UPDATE specimen_part 
			SET preserve_method = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#part_preserve_method#">
			where collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
			</cfquery>
		</cfloop>
	<cflocation url="a_deaccItemReview.cfm?transaction_id=#transaction_id#">
	</cfoutput>
</cfif>
<!-------------------------------------------------------------------------------->

<cfif #Action# is "saveDisp">
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
				<cftransaction action="commit">
			</cfcatch>
			</cftry>
		</cftransaction>
		<cfif isdefined("spRedirAction") and len(#spRedirAction#) gt 0>
			<cfset action=#spRedirAction#>
		<cfelse>
			<cfset action="entryPoint">
		</cfif>
		<cflocation url="a_deaccItemReview.cfm?transaction_id=#transaction_id#&partID=#partID#&deacc_item_remarks=#deacc_item_remarks#&action=#action#">
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
	<main class="container-fluid mx-2" id="content">
		<cfoutput>
			<script>
				var bc = new BroadcastChannel('deaccession_channel');
				function deaccessionModifiedHere() { 
					bc.postMessage({"source":"reviewitems","transaction_id":"#transaction_id#"});
				}
				bc.onmessage = function (message) { 
					console.log(message);
					if (message.data.source == "deaccession" && message.data.transaction_id == "#transaction_id#") { 
						 reloadSummary();
					}
					if (message.data.source == "adddeaccessionitems" && message.data.transaction_id == "#transaction_id#") { 
						console.log("reloading data from adddeaccessionitems message");
						reloadDataNoBroadcast();
					}
					if (message.data.source == "reviewitems" && message.data.transaction_id == "#transaction_id#") { 
						console.log("reloading grid from reviewitems message");
						reloadDataNoBroadcast();
					}
				}
				function reloadSummary() { 
					// TODO: Implement
				}
			</script>
			<cfif isdefined("Ijustwannadownload") and #Ijustwannadownload# is "yep">
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
				<cfset fileName = "/download/ArctosLoanData_#getPartDeaccRequests.deacc_number#.csv">
				<cfset ac=getPartDeaccRequests.columnlist>
				<cfset header=#trim(ac)#>
				<cffile action="write" file="#Application.webDirectory##fileName#" addnewline="yes" output="#header#">
				<cfloop query="getPartDeaccRequests">
					<cfset oneLine = "">
					<cfloop list="#ac#" index="c">
						<cfset thisData = evaluate(c)>
						<cfif len(oneLine) is 0>
							<cfset oneLine = '"#thisData#"'>
						<cfelse>
							<cfset oneLine = '#oneLine#,"#thisData#"'>
						</cfif>
					</cfloop>
					<cfset oneLine = trim(oneLine)>
					<cffile action="append" file="#Application.webDirectory##fileName#" addnewline="yes" output="#oneLine#">
				</cfloop>
				<section class="row">
					<h2 class="h3">Download items</h2>
					<a href="#Application.ServerRootUrl#/#fileName#">Right-click to save your download.</a>
				</section>
				<cfabort>
			</cfif>
		
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
					<a href="a_deaccItemReview.cfm?action=nothing&transaction_id=#transaction_id#&Ijustwannadownload=yep" class="btn btn-xs btn-secondary">Download (csv)</a>
				</div>
				<div class="col-12">
					<div class="add-form mt-2">
						<div class="add-form-header pt-1 px-2">
							<h2 class="h4 mb-0 pb-0">Actions on each item</h2>
						</div>
						<div class="card-body form-row my-1">
							<div class="col-12 col-md-6">
								<form name="BulkUpdateDisp" method="post" action="a_deaccItemReview.cfm">
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
									<form name="BulkUpdatePres" method="post" action="a_deaccItemReview.cfm">
										<br>Change preservation method of all these items to:
										<input type="hidden" name="Action" value="BulkUpdatePres">
										<input type="hidden" name="transaction_id" value="#transaction_id#" id="transaction_id">
										<select name="part_preserve_method" size="1">
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
					</script>
				</div>
			</section>
		</cfoutput>
	</main>
</cfif>

<cfinclude template="/shared/_footer.cfm">
