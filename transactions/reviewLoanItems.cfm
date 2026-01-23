<!---
transactions/reviewLoanItems.cfm

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
<cfset DISALLOWED_CONTAINER_TYPES = "pin,slide,cryovial,jar,envelope,glass vial">

<cfif isDefined("url.transaction_id") and len(url.transaction_id) GT 0>
	<cfset transaction_id = url.transaction_id>
<cfelseif isDefined("form.transaction_id") and len(form.transaction_id) GT 0>
	<cfset transaction_id = form.transaction_id>
</cfif>
<cfif NOT isdefined("transaction_id") OR len(transaction_id) EQ 0>
	<cfthrow message="No transaction specified">
</cfif>
<cfquery name="checkForLoan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="checkForLoan_result">
	SELECT count(*) ct
	FROM
		loan
		left join trans on loan.transaction_id = trans.transaction_id
	WHERE
		trans.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
		AND trans.transaction_type='loan'
		AND loan.transaction_id is not null
</cfquery> 
<cfif checkForLoan.ct NEQ 1>
	<cfthrow message="Provided transaction_id [#encodeForHtml(transaction_id)#] does not specify a loan">
</cfif>
<cfif isdefined("url.action") and len(url.action) GT 0>
	<cfset action = url.action>
<cfelseif isdefined("form.action") and len(form.action) GT 0>
	<cfset action = form.action>
</cfif>
<cfif NOT isdefined("action")><cfset action=""></cfif>
<cfif isdefined("url.message") and len(url.message) GT 0>
	<cfset message = url.message>
<cfelseif isdefined("form.message") and len(form.message) GT 0>
	<cfset message = form.message>
</cfif>
<cfif NOT isdefined("message")><cfset message=""></cfif>

<!--- special case handling to dump loan items as csv --->
<cfif isDefined("action") AND action is "download">
	<cfquery name="getLoanNumber" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		select loan_number 
		from loan 
		where transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#" >
	</cfquery>
	<cfif getLoanNumber.recordCount eq 0>
		<cfthrow message="No such loan transaction as #encodeForHtml(transaction_id)#">
	</cfif>
	<cfset today = dateFormat(now(),"yyyymmdd")>
	<cfset fileName = "loan_items_#getLoanNumber.loan_number#_#today#.csv">
	<cfquery name="getLoanItems" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		SELECT DISTINCT
			loan_number,
			'MCZ:' || collection.collection_cde || ':' || cat_num as guid,
			cat_num as catalog_number, 
			collection,
			collection.collection_cde,
			part_name,
			preserve_method,
			lot_count,
			lot_count_modifier,
			condition,
			decode(sampled_from_obj_id,null,'no ','of ' || MCZbase.get_part_prep(sampled_from_obj_id)) as subsample,
			loan_item.loan_item_state,
			item_descr as loan_item_description,
			item_instructions as loan_item_instructions,
			loan_item_remarks,
			MCZBASE.getPreferredAgentName(reconciled_by_person_id) as added_to_loan_by,
			to_char(reconciled_date,'YYYY-MM-DD') as added_to_loan_date,
			to_char(loan_item.return_date,'YYYY-MM-DD') item_return_date,
			MCZBASE.getPreferredAgentName(loan_item.resolution_recorded_by_agent_id) as resolution_recorded_by_agent,
			loan_item.resolution_remarks,
			coll_obj_disposition,
			MCZBASE.get_top_typestatus(cataloged_item.collection_object_id) as type_status,
			MCZBASE.get_scientific_name_auths_pl(cataloged_item.collection_object_id) as scientific_name,
			collecting_event.began_date,
			collecting_event.ended_date,
			locality.spec_locality,
			locality.sovereign_nation,
			geog_auth_rec.higher_geog,
			MCZBASE.CONCATENCUMBRANCES(cataloged_item.collection_object_id) as encumbrance,
			MCZBASE.CONCATENCUMBAGENTS(cataloged_item.collection_object_id) as encumbering_agent_name,
			decode(MCZBASE.IS_ACCN_BENEFITS(cataloged_item.collection_object_id),1,'yes','') as has_required_benefits,
			decode(MCZBASE.IS_ACCN_RESTRICTED(cataloged_item.collection_object_id),1,'yes','') as has_use_restrictions,
			MCZBASE.concatlocation(MCZBASE.get_current_container_id(specimen_part.collection_object_id)) as location,
			MCZBASE.get_storage_parentage(MCZBASE.get_current_container_id(specimen_part.collection_object_id)) as short_location,
			MCZBASE.get_storage_parentatrank(MCZBASE.get_current_container_id(specimen_part.collection_object_id),'room') as location_room,
			MCZBASE.get_storage_parentatrank(MCZBASE.get_current_container_id(specimen_part.collection_object_id),'fixture') as location_fixture,
			MCZBASE.get_storage_parentatrank(MCZBASE.get_current_container_id(specimen_part.collection_object_id),'tank') as location_tank,
			MCZBASE.get_storage_parentatrank(MCZBASE.get_current_container_id(specimen_part.collection_object_id),'freezer') as location_freezer,
			MCZBASE.get_storage_parentatrank(MCZBASE.get_current_container_id(specimen_part.collection_object_id),'cryovat') as location_cryovat,
			MCZBASE.get_storage_parentatrank(MCZBASE.get_current_container_id(specimen_part.collection_object_id),'compartment') as location_compartment,
			mczbase.get_stored_as_id(cataloged_item.collection_object_id) as stored_as_name,
			MCZBASE.get_storage_parentage(MCZBASE.get_previous_container_id(coll_obj_cont_hist.container_id)) as previous_location,
			concatSingleOtherId(cataloged_item.collection_object_id,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.CustomOtherIdentifier#">) AS customid,
			specimen_part.collection_object_id as internal_part_id,
			sovereign_nation
		from 
			loan
			join loan_item on loan.transaction_id = loan_item.transaction_id
			join specimen_part on loan_item.collection_object_id = specimen_part.collection_object_id
			left join coll_obj_cont_hist on specimen_part.collection_object_id = coll_obj_cont_hist.collection_object_id 
				and coll_obj_cont_hist.current_container_fg = 1
			join cataloged_item on specimen_part.derived_from_cat_item = cataloged_item.collection_object_id 
			join coll_object on specimen_part.collection_object_id = coll_object.collection_object_id 
			join collection on cataloged_item.collection_id=collection.collection_id 
			join collecting_event on cataloged_item.collecting_event_id = collecting_event.collecting_event_id
			join locality on collecting_event.locality_id = locality.locality_id
			join geog_auth_rec on locality.geog_auth_rec_id = geog_auth_rec.geog_auth_rec_id
		WHERE
			loan.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#" >
		ORDER BY cat_num
	</cfquery>
	<cfinclude template="/shared/component/functions.cfc">
	<cfset csv = queryToCSV(getLoanItems)>
	<cfheader name="Content-Type" value="text/csv">
	<cfheader name="Content-Disposition" value="attachment; filename=#fileName#">
	<cfheader name="Content-Length" value="#len(csv)#">
	<cfheader name="Pragma" value="no-cache">
	<cfheader name="Expires" value="0">
	<cfoutput>#csv#</cfoutput>
	<cfabort>
</cfif>

<!--- begin main page action handling and display ------------------------------- --->

<cfset pageTitle="Review Loan Items">
<cfinclude template="/shared/_header.cfm">
<cfinclude template="/transactions/component/itemFunctions.cfc" runOnce="true">

<script type='text/javascript' src='/transactions/js/reviewLoanItems.js'></script>
<script type='text/javascript' src='/specimens/js/specimens.js'></script>
<script type='text/javascript' src='/specimens/js/public.js'></script>

<style>
	.jqx-grid-cell {
		background-color: #E9EDECd6;
	}
	.jqx-grid-cell-alt {
		background-color: #f5f5f5;
	}
	}
</style>

<cfquery name="ctDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	select coll_obj_disposition from ctcoll_obj_disp
</cfquery>
<!--- set up a json source for a jqxDropDownList --->
<cfset ctDispSource = "[">
<cfset sep="">
<cfloop query="ctDisp">
	<cfset ctDispSource = "#ctDispSource##sep#'#ctDisp.coll_obj_disposition#'">
	<cfset sep=",">
</cfloop>
<cfset ctDispSource = "#ctDispSource#]">

<cfswitch expression="#action#">
	<cfcase value="BulkUpdateDisp">
		<cfset message="">
		<cfset countAffected = 0>
		<cfoutput>
			<!--- optionally, if specified, add these loan items to a deaccession --->
			<cfif isDefined("form.deaccession_transaction_id") AND len(form.deaccession_transaction_id) GT 0>
				<!--- do so in a separate transaction, as MCZBASE.COLL_OBJECT_DEACC_CHECK prevents collection objects from having a disposition of deaccessioned unless in a deaccession --->
				<cftransaction>
					<cftry>
						<!--- lookup loan, confirm that it is consumable --->
						<cfquery name="getLoanType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							SELECT loan_type, loan_number
							FROM loan
							WHERE transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#form.transaction_id#">
						</cfquery>
						<cfif getLoanType.loan_type NEQ 'consumable'>
							<cfthrow message="Can't bulk add items from a loan type other than consumable to a deaccession.">
						</cfif>
						<!--- lookup deaccession --->
						<cfquery name="checkDeaccession" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							SELECT count(*) ct from deaccession
							WHERE transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#form.deaccession_transaction_id#">
						</cfquery>
						<cfif checkDeaccession.ct NEQ 1>
							<cfthrow message="No such deaccession transaction with id #encodeForHtml(form.deaccession_transaction_id)# found.">
						</cfif>
						<!--- lookup items to add to the deaccession --->
						<cfquery name="getCollObjId" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							SELECT 
								collection_object_id, 
								item_descr
							FROM loan_item 
							WHERE transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#form.transaction_id#">
						</cfquery>
						<cfloop query="getCollObjId">
							<!--- check if loan item is also in this deaccession, if not, add it --->
							<cfquery name="checkDeaccessionItem" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
								SELECT count(*) ct from deacc_item
								WHERE transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#form.deaccession_transaction_id#">
									AND collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getCollObjId.collection_object_id#">
							</cfquery>
							<cfif checkDeaccessionItem.ct EQ 0>
								<cfquery name="checkDeaccessionItem2" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									SELECT count(*) ct from deacc_item
									WHERE transaction_id <> <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#form.deaccession_transaction_id#">
										AND collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getCollObjId.collection_object_id#">
								</cfquery>
								<cfif checkDeaccessionItem2.ct EQ 0>
									<cfquery name="linkDeaccession" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
										INSERT INTO deacc_item (
											transaction_id, 
											collection_object_id, 
											reconciled_by_person_id,
											reconciled_date,
											item_descr,
											deacc_item_remarks
										) VALUES (
											<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#form.deaccession_transaction_id#">,
											<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getCollObjId.collection_object_id#">,
											<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#session.myAgentId#">,
											current_timestamp,
											<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getCollObjId.item_descr#">,
											'Added from #getLoanType.loan_type# loan #getLoanType.loan_number#.'
										)
									</cfquery>
								</cfif>
							</cfif>
						</cfloop>
						<cftransaction action="commit">
					<cfcatch>
						<cftransaction action="rollback">
						<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
						<cfset message = "Bulk update of dispositions failed. " & cfcatch.message & " " & cfcatch.detail & " " & queryError >
					</cfcatch>
					</cftry>
				</cftransaction>
			</cfif>
			<cftransaction>
				<cftry>
					<cfquery name="getCollObjId" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						SELECT 
							collection_object_id
						FROM loan_item 
						WHERE transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#form.transaction_id#">
					</cfquery>
					<cfloop query="getCollObjId">
						<cfquery name="upDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="upDisp_result">
							UPDATE coll_object 
							SET coll_obj_disposition = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.coll_obj_disposition#">
							where collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getCollObjId.collection_object_id#">
						</cfquery>
						<cfset countAffected = countAffected + upDisp_result.recordcount>
					</cfloop>
					<cftransaction action="commit">
				<cfcatch>
					<cftransaction action="rollback">
					<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
					<cfset message = "Bulk update of dispositions failed. " & cfcatch.message & " " & cfcatch.detail & " " & queryError >
				</cfcatch>
				</cftry>
			</cftransaction>
			<cfif len(message) EQ 0>
				<cfset message = "Bulk update of dispositions successful. Updated #countAffected# specimen parts.">
			</cfif>
			<cfset message = "&message=#encodeForUrl(message)#">
			<cflocation url="/transactions/reviewLoanItems.cfm?transaction_id=#transaction_id##message#" addtoken="false">
		</cfoutput>
	</cfcase>
	<cfcase value="BulkSetReturnDates">
		<cfset message="">
		<cfset countAffected = 0>
		<cfoutput>
			<cftransaction>
				<cftry>
					<cfquery name="getClosedDate" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getClosedDate_result">
						SELECT
							closed_date, loan_type, loan_status
						FROM loan 
						WHERE transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
					</cfquery>
					<cfif getClosedDate.closed_date EQ ''>
						<cfthrow message="Cannot set return due date on a loan without a closed date.">
					</cfif>
					<cfquery name="setClosedDate" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="setClosedDate_result">
						UPDATE
							loan_item
						SET
							return_date = <cfqueryparam cfsqltype="CF_SQL_DATE" value="#getClosedDate.closed_date#">,
							loan_item_state = 'returned',
							resolution_recorded_by_agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#session.myAgentId#">
						WHERE transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
							and return_date is null
					</cfquery>
					<cfset countAffected = setClosedDate_result.recordcount>
					<cftransaction action="commit">
				<cfcatch>
					<cftransaction action="rollback">
					<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
					<cfset message = "Bulk update of dispositions failed. " & cfcatch.message & " " & cfcatch.detail & " " & queryError >
				</cfcatch>
				</cftry>
			</cftransaction>
			<cfif len(message) EQ 0>
				<cfset message = "Bulk update of return dates successful, updated #countAffected# items.">
			</cfif>
			<cfset message = "&message=#encodeForUrl(message)#">
			<cflocation url="/transactions/reviewLoanItems.cfm?transaction_id=#transaction_id##message#" addtoken="false">
		</cfoutput>
	</cfcase>
	<cfcase value="BulkMarkItemsReturned">
		<cfset message="">
		<cfset countAffected = 0>
		<cfoutput>
			<cftransaction>
				<cftry>
					<cfquery name="setClosedDate" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="setClosedDate_result">
						UPDATE
							loan_item
						SET
							return_date = <cfqueryparam cfsqltype="CF_SQL_DATE" value="#dateFormat(now(),'yyyy-mm-dd')#">,
							loan_item_state = 'returned',
							resolution_recorded_by_agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#session.myAgentId#">
						WHERE transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
							and return_date is null
							and (loan_item_state is null OR loan_item_state IN ('in loan','missing'))
					</cfquery>
					<cfset countAffected = setClosedDate_result.recordcount>
					<cftransaction action="commit">
				<cfcatch>
					<cftransaction action="rollback">
					<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
					<cfset message = "Bulk return failed. " & cfcatch.message & " " & cfcatch.detail & " " & queryError >
				</cfcatch>
				</cftry>
			</cftransaction>
			<cfif len(message) EQ 0>
				<cfset message = "Bulk mark items returned successful, updated #countAffected# items.">
			</cfif>
			<cfset message = "&message=#encodeForUrl(message)#">
			<cflocation url="/transactions/reviewLoanItems.cfm?transaction_id=#transaction_id##message#" addtoken="false">
		</cfoutput>
	</cfcase>
	<cfcase value="BulkMarkItemsConsumed">
		<cfset message="">
		<cfset countAffected = 0>
		<cfoutput>
			<cftransaction>
				<cftry>
					<cfquery name="setConsumed" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="setConsumed_result">
						UPDATE
							loan_item
						SET
							loan_item_state = 'consumed',
							resolution_recorded_by_agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#session.myAgentId#">
						WHERE transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
							and return_date is null
							and loan_item_state = 'in loan'
					</cfquery>
					<cfset countAffected = setConsumed_result.recordcount>
					<cftransaction action="commit">
				<cfcatch>
					<cftransaction action="rollback">
					<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
					<cfset message = "Bulk update of state failed. " & cfcatch.message & " " & cfcatch.detail & " " & queryError >
				</cfcatch>
				</cftry>
			</cftransaction>
			<cfif len(message) EQ 0>
				<cfset message = "Bulk mark items consumed successful. Updated #countAffected# items.">
			</cfif>
			<cfset message = "&message=#encodeForUrl(message)#">
			<cflocation url="/transactions/reviewLoanItems.cfm?transaction_id=#transaction_id##message#" addtoken="false">
		</cfoutput>
	</cfcase>
	<cfcase value="BulkUpdateContainers">
		<cfset message="">
		<cfset countAffected = 0>
		<cfoutput>
			<cftransaction>
				<cftry>
					<cfquery name="getCollObjId" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						select collection_object_id 
						FROM loan_item 
						where transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
					</cfquery>
					<cfquery name="getTargetParentContainerID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						SELECT container_id 
						FROM container 
						WHERE barcode = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#new_parent_barcode#">
					</cfquery>
					<cfif getTargetParentContainerID.recordcount EQ 0>
						<cfthrow message="No such container with barcode #new_parent_barcode# found.">
					<cfelseif getTargetParentContainerID.recordcount GT 1>
						<cfthrow message="Multiple containers with barcode #new_parent_barcode# found. Cannot continue.">
					</cfif>
					<cfset targetParentContainerID = getTargetParentContainerID.container_id>
					<cfloop query="getCollObjId">
						<cfquery name="getContainerToMove" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							SELECT c.container_id, p.container_type
							FROM coll_obj_cont_hist coll_obj_cont_hist
								JOIN container c on coll_obj_cont_hist.container_id = c.container_id
								join container p on c.parent_container_id = p.container_id
							WHERE coll_obj_cont_hist.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
								AND coll_obj_cont_hist.current_container_fg = 1
						</cfquery>
						<cfif getContainerToMove.recordcount EQ 0>
							<cfthrow message="No current container found for collection_object_id #collection_object_id#. Cannot continue.">
						<cfelseif getContainerToMove.recordcount GT 1>
							<cfthrow message="Multiple current containers found for collection_object_id #collection_object_id#. Cannot continue.">
						</cfif>
						<cfif listfindnocase(DISALLOWED_CONTAINER_TYPES,getContainerToMove.container_type) GT 0>
							<cfthrow message="Containers of type #getContainerToMove.container_type# cannot be moved. Aborting operation.">
						</cfif>
						<cfset containerToMoveID = getContainerToMove.container_id>
						<cfquery name="changeParentContainer" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="changeParentContainer_result">
							UPDATE container 
							SET parent_container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#targetParentContainerID#">
							WHERE container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#containerToMoveId#">
						</cfquery>
						<cfif changeParentContainer_result.recordcount NEQ 1>
							<cfthrow message="Failed to move container #containerToMoveID# to new parent container #targetParentContainerID#.">
						</cfif>
						<cfset countAffected = countAffected + changeParentContainer_result.recordcount>
					</cfloop>
					<cftransaction action="commit">
				<cfcatch>
					<cftransaction action="rollback">
					<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
					<cfset message = "Bulk update of dispositions failed. " & cfcatch.message & " " & cfcatch.detail & " " & queryError >
				</cfcatch>
				</cftry>
			</cftransaction>
			<cfif len(message) EQ 0>
				<cfset message = "Bulk update of containers successful. Updated #countAffected# specimen parts.">
			</cfif>
			<cfset message = "&message=#encodeForUrl(message)#">
			<cflocation url="/transactions/reviewLoanItems.cfm?transaction_id=#transaction_id##message#" addtoken="false">
		</cfoutput>
	</cfcase>
	<!-------------------------------------------------------------------------------->
	<cfcase value="BulkUpdatePres">
		<cfset message="">
		<cfset countAffected = 0>
		<cfoutput>
			<cftransaction>
				<cftry>
					<cfquery name="getCollObjId" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						select collection_object_id 
						FROM loan_item 
						WHERE transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
					</cfquery>
					<cfloop query="getCollObjId">
						<cfquery name="upDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="upDisp_result">
							UPDATE specimen_part 
							SET preserve_method  = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#part_preserve_method#">
							WHERE collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
						</cfquery>
						<cfset countAffected = countAffected + upDisp_result.recordcount>
					</cfloop>
					<cftransaction action="commit">
				<cfcatch>
					<cftransaction action="rollback">
					<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
					<cfset message = "Bulk update of preservation methods failed. " & cfcatch.message & " " & cfcatch.detail & " " & queryError >
				</cfcatch>
				</cftry>
			</cftransaction>
			<cfif len(message) EQ 0>
				<cfset message = "Bulk update of preservation methods successful. Updated #countAffected# specimen parts.">
			</cfif>
			<cfset message = "&message=#encodeForUrl(message)#">
			<cflocation url="/transactions/reviewLoanItems.cfm?transaction_id=#transaction_id##message#" addtoken="false">
		</cfoutput>
	</cfcase>
	<cfcase value="BulkSetDescription">
		<!--- append the value of coll_object.condition to loan_item.item_descr if not already there. --->
		<cfset message="">
		<cfset countAffected = 0>
		<cfoutput>
			<cftransaction>
				<cftry>
					<cfquery name="getCollObjId" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						select collection_object_id 
						FROM loan_item 
						where transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
					</cfquery>
					<cfloop query="getCollObjId">
						<cfquery name="getCondition" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							SELECT condition
							FROM coll_object
							WHERE collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getCollObjId.collection_object_id#">
						</cfquery>
						<cfif getCondition.recordcount GT 0 AND len(getCondition.condition) GT 0>
							<cfquery name="upDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="upDisp_result">
								UPDATE loan_item 
								SET item_descr  = 
   								TRIM(
  								      CASE WHEN item_descr IS NULL OR TRIM(item_descr) = '' THEN
  							            <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getCondition.condition#">
  							   	   ELSE
      	     				   	  item_descr || '; ' || <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getCondition.condition#">
   	     							END
	    							)
								WHERE collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getCollObjId.collection_object_id#">
									AND (
										item_descr IS NULL OR 
										item_descr NOT LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#getCondition.condition#%">
									)
							</cfquery>
							<cfset countAffected = countAffected + upDisp_result.recordcount>
						</cfif>
					</cfloop>
					<cftransaction action="commit">
				<cfcatch>
					<cftransaction action="rollback">
					<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
					<cfset message = "Bulk update of item descriptions failed. " & cfcatch.message & " " & cfcatch.detail & " " & queryError >
				</cfcatch>
				</cftry>
			</cftransaction>
			<cfif len(message) EQ 0>
				<cfset message = "Bulk update of item descriptions successful. Updated #countAffected# specimen parts.">
			</cfif>
			<cfset message = "&message=#encodeForUrl(message)#">
			<cflocation url="/transactions/reviewLoanItems.cfm?transaction_id=#transaction_id##message#" addtoken="false">
		</cfoutput>
	</cfcase>
	<cfcase value="BulkSetInstructions">
		<!--- append a provided value to loan_item.item_instructions if not already there. --->
		<cfset message="">
		<cfset countAffected = 0>
		<cfoutput>
			<cfif isDefined("form.item_instructions") AND len(trim(form.item_instructions)) GT 0>
				<cftransaction>
					<cftry>
						<cfquery name="getCollObjId" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getCollObjId_result">
							UPDATE loan_item 
							SET item_instructions =
   							TRIM(
  							      CASE WHEN item_instructions IS NULL OR TRIM(item_instructions) = '' THEN
  						            <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.item_instructions#">
  						   	   ELSE
           				   	  item_instructions || '; ' || <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.item_instructions#">
        							END
    							)
							WHERE transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#form.transaction_id#">
								AND (
									item_instructions IS NULL OR
									item_instructions NOT LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#form.item_instructions#%">
								)
						</cfquery>
						<cfset countAffected = getCollObjId_result.recordcount>
						<cftransaction action="commit">
					<cfcatch>
						<cftransaction action="rollback">
						<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
						<cfset message = "Bulk update of item instructions failed. " & cfcatch.message & " " & cfcatch.detail & " " & queryError >
					</cfcatch>
					</cftry>
				</cftransaction>
			</cfif>
			<cfif len(message) EQ 0>
				<cfset message = "Bulk update of item instructions successful. Updated #countAffected# items.">
			</cfif>
			<cfset message = "&message=#encodeForUrl(message)#">
			<cflocation url="/transactions/reviewLoanItems.cfm?transaction_id=#transaction_id##message#" addtoken="false">
		</cfoutput>
	</cfcase>
	<cfcase value="BulkMoveBackContainers">
		<cfset message="">
		<cfset countAffected = 0>
		<cfoutput>
			<cftransaction>
				<cftry>
					<cfquery name="getItems" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						SELECT collection_object_id
						FROM loan_item
						WHERE
							loan_item.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#" >
					</cfquery>
					<cfloop query="getItems">
						<cfquery name="getPreviousContainer" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							SELECT
								container_history.install_date,
								container.container_type,
								current_parent.container_type current_parent_container_type,
								container.container_id part_container_id,
								old_parent.container_type old_parent_container_type,
								old_parent.label,
								old_parent.barcode,
								old_parent.container_id old_parent_container_id
							 FROM 
								specimen_part 
								join coll_obj_cont_hist on specimen_part.collection_object_id = coll_obj_cont_hist.collection_object_id
									and coll_obj_cont_hist.current_container_fg = 1
								join container on coll_obj_cont_hist.container_id = container.container_id
								join container_history on container.container_id = container_history.container_id
								join container old_parent on container_history.parent_container_id = old_parent.container_id
								join container current_parent on container.parent_container_id = current_parent.container_id
							 WHERE 
								specimen_part.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getItems.collection_object_id#">
								and old_parent.container_type <> 'campus' 
								and old_parent.container_type <> 'institution'
								and old_parent.parent_container_id is not null 
							ORDER BY install_date DESC NULLS LAST
							FETCH FIRST 1 ROWS ONLY
						</cfquery>
						<cfif getPreviousContainer.recordcount EQ 1>
							<!--- confirm that container is not of a disallowed type --->
							<cfif listfindnocase(DISALLOWED_CONTAINER_TYPES,getPreviousContainer.current_parent_container_type) GT 0>
								<cfthrow message="Containers of type #getPreviousContainer.curreent_parent_container_type# cannot be moved. Aborting operation.">
							</cfif>
							<cfquery name="changeParentContainer" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="changeParentContainer_result">
								UPDATE container 
								SET parent_container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getPreviousContainer.old_parent_container_id#">
								WHERE container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getPreviousContainer.part_container_id#">
							</cfquery>
							<cfset countAffected = countAffected + changeParentContainer_result.recordcount>
						<cfelse>
							<cfthrow message="No previous container found for collection_object_id #getItems.collection_object_id#. Cannot continue.">
						</cfif>
					</cfloop>
					<cftransaction action="commit">
				<cfcatch>
					<cftransaction action="rollback">
					<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
					<cfset message = "Bulk update of containers failed. " & cfcatch.message & " " & cfcatch.detail & " " & queryError >
				</cfcatch>
				</cftry>
			</cftransaction>
			<cfif len(message) EQ 0>
				<cfset message = "Bulk update of containers successful. Updated #countAffected# specimen parts.">
			</cfif>
			<cfset message = "&message=#encodeForUrl(message)#">
			<cflocation url="/transactions/reviewLoanItems.cfm?transaction_id=#transaction_id##message#" addtoken="false">
		</cfoutput>
	</cfcase>
	<!-------------------------------------------------------------------------------->
	<cfdefaultcase>
		<cfquery name="getCollections" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getCollections_result">
			select count(*) as ct, collection.collection_cde 
			from 
				loan_item
				left join specimen_part on loan_item.collection_object_id = specimen_part.collection_object_id
				left join cataloged_item on specimen_part.derived_from_cat_item = cataloged_item.collection_object_id
				left join collection on cataloged_item.collection_id=collection.collection_id
			WHERE
				loan_item.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#" >
			GROUP BY collection.collection_cde
		</cfquery>
		<cfset collectionCount = getCollections.recordcount>
		<cfif collectionCount EQ 1 OR collectionCount EQ 0>
			<!--- Obtain list of preserve_method values for the collection that this loan is from --->
			<cfquery name="ctPreserveMethod" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				select distinct ct.preserve_method
				from ctspecimen_preserv_method ct 
					left join collection c on ct.collection_cde = c.collection_cde
					left join trans t on c.collection_id = t.collection_id 
				where t.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#" >
			</cfquery>
		<cfelse>
			<!--- Obtain list of preserve_method values that apply to all of collection for material in this loan--->
			<cfset intersect = "">
			<cfquery name="ctPreserveMethod" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				select distinct preserve_method from (
					<cfloop query="getCollections" >
						<cfif len(intersect) GT 0>#intersect#</cfif>
						select preserve_method 
						from ctspecimen_preserv_method
						where collection_cde = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getCollections.collection_cde#">
						<cfset intersect = "INTERSECT">
					</cfloop>
				)
			</cfquery>
		</cfif>

		<cfoutput>
			<script>
				var bc = new BroadcastChannel('loan_channel');
				function loanModifiedHere() { 
					bc.postMessage({"source":"reviewitems","transaction_id":"#transaction_id#"});
				}
				bc.onmessage = function (message) { 
					console.log(message);
					if (message.data.source == "loan" && message.data.transaction_id == "#transaction_id#") { 
						 reloadSummary();
					}
					if (message.data.source == "addloanitems" && message.data.transaction_id == "#transaction_id#") { 
						console.log("reloading grid from addloanitems message");
						reloadGridNoBroadcast();
					}
					if (message.data.source == "reviewitems" && message.data.transaction_id == "#transaction_id#") { 
						console.log("reloading grid from reviewitems message");
						reloadGridNoBroadcast();
					}
				}
				function reloadSummary() { 
					// TODO: Implement
					// If the loan has changed state (in process to open, any open to closed), put up a dialog to reload the page.
				}
			</script>
		</cfoutput>
		<main class="container-fluid" id="content">
			<cfoutput>
				<cfif isdefined("message") AND len(message) GT 0>
					<h1 class=h2>#encodeForHtml(message)#</h2>
				</cfif>
				<cfset isClosed = false>
				<cfset isInProcess = false>
				<cfset isOpen = false>
				<cfquery name="aboutLoan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT l.loan_number, 
						c.collection_cde, 
						c.collection,
						l.loan_type, 
						l.loan_status, 
						to_char(l.return_due_date,'yyyy-mm-dd') as return_due_date, 
						to_char(l.closed_date,'yyyy-mm-dd') as closed_date,
						l.loan_instructions,
						trans.nature_of_material,
						to_char(trans.trans_date,'yyyy-mm-dd') as loan_date
					FROM 
						trans
						left join collection c on trans.collection_id = c.collection_id
						left join loan l on trans.transaction_id = l.transaction_id
					WHERE trans.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#" >
				</cfquery>
				<cfif aboutLoan.recordcount EQ 0>
					<cfthrow message="No such transaction found.">
				</cfif>
				<cfif aboutLoan.loan_number IS "">
					<cfthrow message="Transaction with this transaction_id is not a loan.">
				</cfif>
				<cfif aboutLoan.loan_status EQ 'closed'>
					<cfset isClosed = true>
				</cfif>
				<cfif aboutLoan.loan_status EQ 'in process'>
					<cfset isInProcess = true>
				</cfif>
				<cfif Find("open",aboutLoan.loan_status) EQ 1>
					<cfset isOpen = true>
				</cfif>
				<cfset multipleCollectionsText = "">
				<cfif collectionCount GT 1>
					<cfset multipleCollectionsText = "Contains Material from #collectionCount# Collections: ">
					<cfloop query="getCollections" >
						<cfset multipleCollectionsText = "#multipleCollectionsText# #getCollections.collection_cde# (#getCollections.ct#) " >
					</cfloop>
				</cfif>
				<!--- Parent exhibition-master loan of the current exhibition-subloan loan, if applicable--->
				<cfquery name="parentLoan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT p.loan_number, p.transaction_id, p.loan_type
					FROM loan c left join loan_relations lr on c.transaction_id = lr.related_transaction_id 
						left join loan p on lr.transaction_id = p.transaction_id 
					WHERE lr.relation_type = 'Subloan' 
						and c.transaction_id = <cfqueryparam value="#transaction_id#" cfsqltype="CF_SQL_DECIMAL">
				</cfquery>
	
				<!--- count cataloged items and parts in the loan --->
				<cfquery name="catCnt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					select count(distinct(derived_from_cat_item)) c 
					from loan_item
						left join specimen_part on loan_item.collection_object_id = specimen_part.collection_object_id
					where
						loan_item.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#" >
				</cfquery>
				<cfif catCnt.c eq ''>
					<cfset catCount = 'no'>
				<cfelse>
					<cfset catCount = catCnt.c>
				</cfif>
				<cfquery name="prtItemCnt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					select count(distinct(collection_object_id)) c 
					from loan_item
					where
						loan_item.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#" >
				</cfquery>
				<cfif prtItemCnt.c eq ''>
					<cfset partCount = 'no'>
				<cfelse>
					<cfset partCount = prtItemCnt.c>
				</cfif>
				<cfset containersCanMove = true>
				<cfquery name="checkContainers" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT count(distinct p.container_type) ct, p.container_type
					FROM loan_item
						join coll_obj_cont_hist on loan_item.collection_object_id = coll_obj_cont_hist.collection_object_id
						join container c on coll_obj_cont_hist.container_id = c.container_id
						join container p on c.parent_container_id = p.container_id
					WHERE
						loan_item.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#" >
						and coll_obj_cont_hist.current_container_fg = 1
					GROUP BY p.container_type
				</cfquery>
				<cfloop query="checkContainers">
					<cfif listfindnocase(DISALLOWED_CONTAINER_TYPES,checkContainers.container_type) GT 0>
						<cfset containersCanMove = false>
					</cfif>
				</cfloop>
				<cfif containersCanMove>
					<cfquery name="getItems" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						SELECT collection_object_id
						FROM loan_item
						WHERE
							loan_item.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#" >
					</cfquery>
					<cfset itemCount = getItems.recordcount>
					<cfset moveableItemCount = 0>
					<cfset bulkMoveBackPossible=false>
					<!--- check to see if all parts have a container history they can move to --->
					<cfloop query="getItems">
						<cfquery name="checkHistories" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							SELECT
								container.container_id part_container_id,
								container_history.install_date,
								container.container_type,
								current_parent.container_type current_parent_container_type,
								old_parent.container_type old_parent_container_type,
								old_parent.label,
								old_parent.barcode,
								old_parent.container_id old_parent_container_id
							 FROM 
								specimen_part 
								join coll_obj_cont_hist on specimen_part.collection_object_id = coll_obj_cont_hist.collection_object_id
									and coll_obj_cont_hist.current_container_fg = 1
								join container on coll_obj_cont_hist.container_id = container.container_id
								join container_history on container.container_id = container_history.container_id
								join container old_parent on container_history.parent_container_id = old_parent.container_id
								join container current_parent on container.parent_container_id = current_parent.container_id
							 WHERE 
								specimen_part.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getItems.collection_object_id#">
								and old_parent.container_type <> 'campus' 
								and old_parent.container_type <> 'institution'
								and old_parent.parent_container_id is not null 
							ORDER BY install_date DESC NULLS LAST
							FETCH FIRST 1 ROWS ONLY
						</cfquery>
						<cfif checkHistories.recordcount EQ 1>
							<cfset moveableItemCount = moveableItemCount + 1>
						</cfif>
					</cfloop>
					<cfif itemCount EQ moveableItemCount>
						<cfset bulkMoveBackPossible = true>
					</cfif>
				</cfif>

				<section class="row my-2 pt-2" title="Review Loan Items" >
					<div class="col-12">
						<div class="container-fluid">
							<div class="row">
								<div class="col-12 mb-3">
									<div class="row mt-1 mb-0 pb-0 px-2 mx-0">
										<div class="col-12 col-xl-6">
											<h1 class="h3 mb-0 pb-0">
												Review items in loan
												<a href="/transactions/Loan.cfm?action=editLoan&transaction_id=#transaction_id#">#encodeForHtml(aboutLoan.loan_number)#</a>
											</h1>
											<cfif collectionCount GT 1 >
												<p class="font-weight-normal mb-1 pb-0">#multipleCollectionsText#</p>
											</cfif>
											<h2 class="h4 d-inline font-weight-normal">Type: <span class="font-weight-lessbold">#aboutLoan.loan_type#</span> </h2>
											<cfif isClosed>
												<cfset statusWeight = "bold">
											<cfelse>
												<cfset statusWeight = "lessbold">
											</cfif>
											<h2 class="h4 d-inline font-weight-normal"> &bull; Status: <span class="text-capitalize font-weight-#statusWeight#">#aboutLoan.loan_status#</span> </h2>
											<h2 class="h4 d-inline font-weight-normal"> &bull; Loan Date: <span class="text-capitalize font-weight-lessbold">#aboutLoan.loan_date#</span> </h2>
											<cfif aboutLoan.return_due_date NEQ ''>
												<h2 class="h4 d-inline font-weight-normal">
													&bull; Due Date: <span class="font-weight-lessbold">#aboutLoan.return_due_date#</span>
												</h2>
											</cfif>
											<cfif aboutLoan.closed_date NEQ ''>
												<h2 class="h4 d-inline font-weight-normal">
													&bull; Closed Date: <span class="font-weight-lessbold">#aboutLoan.closed_date#</span> 
												</h2>
											</cfif>
											<cfif aboutLoan.nature_of_material NEQ ''>
												<div class="p-1">
													#aboutLoan.nature_of_material#
												</div>
											</cfif>
											<cfif parentLoan.recordcount GT 0>
												<h2 class="h4 font-weight-normal">
													Subloan of #parentLoan.loan_type#: 
													<a href="/transactions/Loan.cfm?action=editLoan&transaction_id=#parentLoan.transaction_id#">
														#encodeForHtml(parentLoan.loan_number)#
													</a>
												</h2>
											</cfif>
											<p class="font-weight-normal mb-1 pb-0">
												There are <span class="itemCountSpan">#partCount#</span> items from <a href="/Specimens.cfm?execute=true&action=fixedSearch&loan_number=#encodeForUrl(aboutLoan.loan_number)#" target="_blank"><span class="catnumCountSpan">#catCount#</span> specimens</a> in this loan.  View <a href="/findContainer.cfm?loan_trans_id=#transaction_id#" target="_blank">Part Locations</a>
											</p>
											<cfif aboutLoan.loan_type EQ 'exhibition-master'>
												<cfquery name="childLoans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
													SELECT c.loan_number, c.transaction_id, count(loan_item.collection_object_id) as part_count
													FROM loan p left join loan_relations lr on p.transaction_id = lr.transaction_id 
														join loan c on lr.related_transaction_id = c.transaction_id 
														left join loan_item on c.transaction_id = loan_item.transaction_id
													WHERE lr.relation_type = 'Subloan'
														 and p.transaction_id = <cfqueryparam value=#transaction_id# cfsqltype="CF_SQL_DECIMAL" >
													GROUP BY c.loan_number, c.transaction_id
													ORDER BY c.loan_number
												</cfquery>
												<cfif childLoans.recordcount GT 0>
													<p class="font-weight-normal mb-1 pb-0">
														Exhibition Subloans:
														<ul>
															<cfloop query="childLoans">
																<li>
																	<a href="/transactions/Loan.cfm?action=editLoan&transaction_id=#childLoans.transaction_id#">#encodeForHtml(childLoans.loan_number)#</a>:
																	<a href="/transactions/reviewLoanItems.cfm?transaction_id=#childLoans.transaction_id#">Review items (#childLoans.part_count#)</a>
																</li>
															</cfloop>
															</ul>
														</p>
												<cfelse>
													<p class="font-weight-normal mb-1 pb-0">
														No subloans associated with this exhibition-master loan.
													</p>
												</cfif>
											</cfif>
										</div>
										<div class="col-12 col-xl-6 pt-3">
											<h3 class="h4 mb-1">Countries of Origin</h3>
											<div id="countriesDiv">
												<cfset countries = getCountriesList(transaction_id=transaction_id)>
												#countries#
											</div>
										</div>
										<div class="col-12 col-xl-6 pt-3">
											<h3 class="h4 mb-1">Part Dispositions (current) and Loan Item States (this loan)</h3>
											<div id="dispositionsDiv">
												<cfset dispositions = getDispositionsList(transaction_id=transaction_id)>
												#dispositions#
											</div>
										</div>
										<div class="col-12 col-xl-6 pt-3">
											<h3 class="h4 mb-1">Preservation Methods</h3>
											<div id="preservationDiv">
												<cfset preservations = getPreservationsList(transaction_id=transaction_id)>
												#preservations#
											</div>
										</div>
										<cfif isInProcess AND aboutLoan.loan_type NEQ 'exhibition-master'>
											<div class="col-12">
												<div class="add-form mt-2">
													<div class="add-form-header pt-1 px-2">
														<h2 class="h4 mb-0 pb-0">Add Parts To Loan</h2>
													</div>
													<div class="card-body form-row my-1">
														<div class="col-12 col-md-4">
															<label class="data-entry-label" for="guid">Cataloged item (MCZ:Dept:number)</label>
															<input type="text" id="guid" name="guid" class="data-entry-input" value="" placeholder="MCZ:Dept:1111" >
															<input type="hidden" id="collection_object_id" name="collection_object_id" value="">
														</div>
														<div class="col-12 col-md-8">
															<label class="data-entry-label">&nbsp;</label>
															<button id="addloanitembutton" class="btn btn-xs btn-secondary" 
																aria-label="Add an item to loan by catalog number" >Add Part To Loan</button>
															<script>
																$(document).ready(function() {
																	$('##addloanitembutton').click(function(evt) { 
																		evt.preventDefault();
																		if ($('##guid').val() != "") { 
																			openAddLoanItemDialog($('##guid').val(),#transaction_id#, 'addLoanItemDialogDiv', reloadGrid);
																		} else {
																			messageDialog("Enter the guid for a cataloged item from which to add a part in the field provided.","No cataloged item provided"); 
																		};
																	});
																});
															</script>
															<!---  script>
																$(document).ready(function() {
																	makeCatalogedItemAutocompleteMeta('guid', 'collection_object_id');
																});
																// if added, validate that collection_object_id is set before submitting
															</script --->
														</div>
													</div>
												</div>
											</div>
										</cfif>
										<div id="addLoanItemDialogDiv"></div>
									</div>
									<cfset editVisibility = "">
									<cfif isClosed>
										<cfset editVisibility = "d-none">
										<div class="row mb-0 pb-0 px-2 mx-0">
											<div class="col-12">
												<h3 class="h4 text-danger">This loan is closed; edit functions are disabled.</h3>
												<span class="btn btn-xs btn-secondary" id="enableEditControlsBtn"
													onclick=" enableEditControls(); "
													aria-label="Enable bulk editing">Enable Editing</span>
												<span class="btn btn-xs btn-secondary d-none"
													onclick=" disableEditControls(); " id="disableEditControlsBtn"
													aria-label="Disable bulk editing">Disable Editing</span>
											</div>
										</div>
										<script>
											function enableEditControls() { 
												$('##bulkEditControlsDiv').removeClass('d-none');
												$('##searchResultsGrid').jqxGrid({editable:true});
												$('##enableEditControlsBtn').addClass('d-none');
												$('##disableEditControlsBtn').removeClass('d-none');
												$('.flag-editable-cell').addClass('bg-light');
												$('.flag-editable-cell').addClass('editable-cell');
												$('##searchResultsGrid').jqxGrid('showcolumn', 'EditRow');
											};
											function disableEditControls() { 
												$('##bulkEditControlsDiv').addClass('d-none');
												$('##searchResultsGrid').jqxGrid({editable:false});
												$('##enableEditControlsBtn').removeClass('d-none');
												$('##disableEditControlsBtn').addClass('d-none');
												$('.flag-editable-cell').removeClass('bg-light');
												$('.flag-editable-cell').removeClass('editable-cell');
												$('##searchResultsGrid').jqxGrid('hidecolumn', 'EditRow');
											};
										</script>
									</cfif>
									<div class="row #editVisibility#" id="bulkEditControlsDiv">
										<div class="col-12">
											<div class="add-form mt-2">
												<div class="add-form-header pt-1 px-2">
													<h2 class="h4 mb-0 pb-0">Edit All Loan Items</h2>
												</div>
												<div class="card-body">
													<div class="row mb-0 pb-0 px-2 mx-0">
														<div class="col-12 col-xl-6 border p-1">
															<form name="BulkUpdateDisp" method="post" action="/transactions/reviewLoanItems.cfm" class="form-row">
																<input type="hidden" name="Action" value="BulkUpdateDisp">
																<input type="hidden" name="transaction_id" value="#transaction_id#" id="transaction_id">
																<div class="col-12 col-md-6">
																	<label class="data-entry-label" for="coll_obj_disposition">Change disposition of all these <span class="itemCountSpan">#partCount#</span> items to:</label>
																	<select name="coll_obj_disposition" id="coll_obj_disposition" class="data-entry-select" size="1">
																		<option value=""></option>
																		<cfloop query="ctDisp">
																			<option value="#coll_obj_disposition#">#ctDisp.coll_obj_disposition#</option>
																		</cfloop>				
																	</select>
																</div>
																<!--- enable the submit button only if a value is selected --->
																<script>
																	$(document).ready(function() {
																		$('##coll_obj_disposition').change(function() {
																			if ($('##coll_obj_disposition').val() != "") {
																				$('##coll_obj_disposition_submit').prop('disabled', false);
																			} else {
																				$('##coll_obj_disposition_submit').prop('disabled', true);
																			}
																		});
																	});
																</script>
																<cfif aboutLoan.loan_type NEQ 'consumable'>
																	<div class="col-12 col-md-6">
																		<input type="submit" id="coll_obj_disposition_submit" value="Update Dispositions" class="btn btn-xs btn-primary mt-3" disabled>
																	</div>
																<cfelse>
																	<div class="col-12" id="deaccessionDiv">
																		<input type="hidden" name="deaccession_transaction_id" value="" id="deaccession_transaction_id">
																		<label class="data-entry-label" for="deaccession_number">Also add all these #partCount# items to deaccession:</label>
																		<input type="text" name="deaccession_number" id="deaccession_number" class="data-entry-input col-6 d-inline" placeholder="Dyyyy-n-Coll" disabled >
																		<output id="deaccessionFeedback" class="ml-2"></output>
																	</div>
																	<!--- if a disposition containing 'deaccessioned' is selected, enable deaccession_number control --->
																	<script>
																		$(document).ready(function() {
																			makeDeaccessionAutocompleteMeta("deaccession_number", "deaccession_transaction_id"); 
																			$("##deaccessionDiv").hide();
																			$('##coll_obj_disposition').change(function() {
																				var selectedDisp = $('##coll_obj_disposition').val().toLowerCase();
																				if (selectedDisp.includes('deaccessioned')) {
																					$("##deaccessionDiv").show();
																					$('##deaccession_number').prop('disabled', false);
																				} else {
																					$("##deaccessionDiv").hide();
																					$('##deaccession_number').prop('disabled', true);
																				}
																			});
																		});
																	</script>
																	<div class="col-12">
																		<input type="submit" id="coll_obj_disposition_submit" value="Update Dispositions" class="btn btn-xs btn-primary" disabled>
																	</div>
																</cfif>
															</form>
														</div>
														<cfif containersCanMove AND NOT isInProcess>
															<div class="col-12 col-xl-6 border p-1">
																<cfquery name="getTreatmentContainers" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
																	SELECT barcode, label
																	FROM container
																	WHERE label LIKE '%chamber'
																		and container_type = 'fixture'
																	ORDER BY label
																</cfquery>
																<form name="moveContainers" method="post" action="/transactions/reviewLoanItems.cfm">
																	Move all containers for all these #partCount# items to:
																	<input type="hidden" name="Action" value="BulkUpdateContainers">
																	<input type="hidden" name="transaction_id" value="#transaction_id#" id="transaction_id">
																	<select name="new_parent_barcode" id="new_parent_barcode" class="data-entry-select col-3 d-inline" size="1">
																		<option value=""></option>
																		<cfloop query="getTreatmentContainers">
																			<option value="#getTreatmentContainers.barcode#">#getTreatmentContainers.label# (#getTreatmentContainers.barcode#)</option>
																		</cfloop>
																	</select>
																	<input type="submit" id="new_parent_barcode_submit" value="Move Containers" class="btn btn-xs btn-primary" disabled>
																	<!--- enable the button only if a value is selected --->
																	<script>
																		$(document).ready(function() {
																			$('##new_parent_barcode').change(function() {
																				if ($('##new_parent_barcode').val() != "") {
																					$('##new_parent_barcode_submit').prop('disabled', false);
																				} else {
																					$('##new_parent_barcode_submit').prop('disabled', true);
																				}
																			});
																		});
																	</script>
																</form>
															</div>
															<div class="col-12 col-xl-6 border p-1">
																<h3 class="h3">#moveableItemCount# of #itemCount# parts could be placed back in their previous containers</h3>
																<cfif bulkMoveBackPossible>
																	<form name="BulkMoveBackContainers" method="post" action="/transactions/reviewLoanItems.cfm">
																		<br>Move all containers for all these #partCount# items back to their previous containers:
																		<input type="hidden" name="Action" value="BulkMoveBackContainers">
																		<input type="hidden" name="transaction_id" value="#transaction_id#" id="transaction_id">
																		<input type="submit" value="Move Containers Back" class="btn btn-xs btn-primary"> 
																	</form>
																</cfif>
															</div>
														<cfelse>
															<div class="col-12 col-xl-6 border p-1">
																<cfif isInProcess>
																	<h3 class="h4">Containers cannot be moved while the loan is in process.</h3>
																<cfelseif NOT containersCanMove>
																	<h3 class="h4 text-danger">Some or all containers for parts in this loan are of a type that cannot be moved automatically.</h3>
																</cfif>
															</div>
														</cfif>
														<cfif aboutLoan.collection EQ 'Cryogenic'>
															<div class="col-12 col-xl-6 border p-1">
																<form name="BulkUpdatePres" method="post" action="/transactions/reviewLoanItems.cfm">
																	Change preservation method of all these items to:
																	<input type="hidden" name="Action" value="BulkUpdatePres">
																	<input type="hidden" name="transaction_id" value="#transaction_id#" id="transaction_id">
																	<select name="part_preserve_method" class="data-entry-select col-3 d-inline" size="1">
																		<option></option>
																		<cfloop query="ctPreserveMethod">
																			<option value="#ctPreserveMethod.preserve_method#">#ctPreserveMethod.preserve_method#</option>
																		</cfloop>				
																	</select>
																	<input type="submit" value="Update Preservation methods" class="btn btn-xs btn-primary" disabled> 
																	<!--- disable submit button until a value is selected --->
																	<script>
																		$(document).ready(function() {
																			$('select[name="part_preserve_method"]').change(function() {
																				if ($(this).val() != "") {
																					$(this).siblings('input[type="submit"]').prop('disabled', false);
																				} else {
																					$(this).siblings('input[type="submit"]').prop('disabled', true);
																				}
																			});
																		});
																	</script>
																</form>
															</div>
														</cfif>
														<cfif isClosed>
															<!--- if loan is returnable, and all loan items have no return date, show button to set return date to loan closed date --->
															<cfquery name="ctReturnableItems" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
																SELECT count(*) as ct
																FROM loan_item
																WHERE
																	loan_item.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#" >
																	and loan_item.return_date is null
															</cfquery>
															<cfif (aboutLoan.loan_type EQ 'returnable' OR aboutLoan.loan_type contains 'exhibition' ) AND ctReturnableItems.ct EQ partCount>
																<div class="col-12 col-xl-6 border p-1">
																	<form name="BulkSetReturnDates" method="post" action="/transactions/reviewLoanItems.cfm">
																		Set return date for all these #partCount# items to loan closed date of #dateFormat(aboutLoan.closed_date,'yyyy-mm-dd')#:
																		<input type="hidden" name="Action" value="BulkSetReturnDates">
																		<input type="hidden" name="transaction_id" value="#transaction_id#" id="transaction_id">
																		<input type="submit" value="Set Return Dates" class="btn btn-xs btn-primary"> 
																	</form>
																</div>
															</cfif>
														</cfif>
														<cfif isOpen>
															<!--- if loan is open and returnable, show button to set return date on loan items to today and mark items as returned --->
															<cfif aboutLoan.loan_type EQ 'returnable' or aboutLoan.loan_type contains 'exhibition'>
																<div class="col-12 col-xl-6 border p-1">
																	<form name="BulkMarkItemsReturned" method="post" action="/transactions/reviewLoanItems.cfm">
																		Mark all these #partCount# items as returned today (#dateFormat(now(),'yyyy-mm-dd')#):
																		<input type="hidden" name="Action" value="BulkMarkItemsReturned">
																		<input type="hidden" name="transaction_id" value="#transaction_id#" id="transaction_id">
																		<input type="submit" value="Mark Items Returned" class="btn btn-xs btn-primary"> 
																	</form>
																</div>
															</cfif>
															<cfif aboutLoan.loan_type EQ 'consumable'>
																<cfquery name="countConsumableItems" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
																	SELECT count(*) as ct
																	FROM loan_item
																	WHERE
																		loan_item.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#" >
																		and (loan_item.loan_item_state <> 'consumed' or loan_item.loan_item_state is NULL)
																</cfquery>
																<div class="col-12 col-xl-6 border p-1">
																	<cfif countConsumableItems.ct GT 0>
																		<form name="BulkMarkItemsConsumed" method="post" action="/transactions/reviewLoanItems.cfm">
																			Mark all these #partCount# items as consumed.
																			<input type="hidden" name="Action" value="BulkMarkItemsConsumed">
																			<input type="hidden" name="transaction_id" value="#transaction_id#" id="transaction_id">
																			<input type="submit" value="Mark Items Consumed" class="btn btn-xs btn-primary"> 
																		</form>
																	<cfelse>
																		<h3 class="h3">All items in this consumable loan are marked as consumed.</h3>
																	</cfif>
																</div>
															</cfif>
														</cfif>
														<cfif isInProcess>
															<!--- if loan is in process, stamp the part condition values into the item description --->
															<div class="col-12 col-xl-6 border p-1">
																<form name="BulkSetDescription" method="post" action="/transactions/reviewLoanItems.cfm">
																	Append the part condition to each loan item description:
																	<input type="hidden" name="action" value="BulkSetDescription">
																	<input type="hidden" name="transaction_id" value="#transaction_id#" id="transaction_id">
																	<input type="submit" value="Paste Descriptions" class="btn btn-xs btn-primary"> 
																</form>
															</div>
															<div class="col-12 col-xl-6 border p-1">
																<form name="BulkSetInstructions" method="post" action="/transactions/reviewLoanItems.cfm">
																	Add instructions to each loan item:
																	<input type="hidden" name="action" value="BulkSetInstructions">
																	<input type="hidden" name="transaction_id" value="#transaction_id#" id="transaction_id">
																	<input type="text" name="item_instructions" id="item_instructions" value="">
																	<input type="submit" value="Append Item Instructions" class="btn btn-xs btn-primary"> 
																</form>
															</div>
														</cfif>
													</div>
												</div>
											</div>
										</div>
									</div>
								</div>
							</div>
						</div>
					</div>
	
					<!--- TODO: Replace grid --->
					<div class="col-12" id="allCatItemsDiv">
						<cfset catItemBlock = getLoanCatItemHtml(transaction_id=transaction_id,collection_object_id="")>
						#catItemBlock#
					</div>
					<div id="deaccItemEditDialogDiv"></div>
					<div id="deaccItemRemoveDialogDiv"></div>

					<div class="col-12">
						<div class="container-fluid">
							<div class="row">
								<div class="col-12 mb-3">
									<div class="row mt-1 mb-0 pb-0 jqx-widget-header border px-2 mx-0">
									<h1 class="h4">Loan Items <span class="px-1 font-weight-normal text-success" id="resultCount" tabindex="0"><span class="alert alert-warning py-1 mb-0 d-inline-block"><a class="messageResults" tabindex="0" aria-label="search results"></a></span></span> </h1><span id="resultLink" class="d-inline-block px-1 pt-2"></span>
										<div id="columnPickDialog" class="row pick-column-width">
											<div class="row">
												<div class="col-12 col-md-6">
													<div id="columnPick" class="px-1"></div>
												</div>
												<div class="col-12 col-md-6 px-0">
													<div id="columnPick1" class="px-1"></div>
												</div>
											</div>
										</div>
										<div id="columnPickDialogButton"></div>
										<div id="resultDownloadButtonContainer"></div>
										<div id="locationButtonContainer"></div>
										<div id="freezerLocationButtonContainer"></div>
										<output id="gridActionFeedbackDiv"></output>
									</div>
									<div class="row mt-0 mx-0">
										<!--- Grid Related code is below along with search handlers --->
										<div id="searchResultsGrid" class="jqxGrid" role="table" aria-label="Search Results Table"></div>
										<div id="enableselection"></div>
									</div>
								</div>
							</div>
						</div>
						<div id="itemConditionHistoryDialog"></div>
						<div id="removeItemDialog"></div>
						<div id="editItemDialog"></div>
						<cfset cellRenderClasses = "ml-1"><!--- for cell renderers to match default --->
						<script>
							var gotRunOnLoad = false;

							function removeLoanItem(item_collection_object_id) { 
								openRemoveLoanItemDialog(item_collection_object_id, #transaction_id#,'removeItemDialog',reloadGrid);
							};

							window.columnHiddenSettings = new Object();
							<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
								lookupColumnVisibilities ('#cgi.script_name#','Default');
							</cfif>

							$(document).ready(function() {
								$("##searchResultsGrid").replaceWith('<div id="searchResultsGrid" class="jqxGrid" style="z-index: 1;"></div>');
								$('##resultCount').html('');
								$('##resultLink').html('');
							});
		
							function gridLoaded(gridId, searchType) { 
								if (Object.keys(window.columnHiddenSettings).length == 0) { 
									lookupColumnVisibilities ('#cgi.script_name#','Default');
									<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
										saveColumnVisibilities('#cgi.script_name#',window.columnHiddenSettings,'Default');
									</cfif>
								}
								setColumnVisibilities(window.columnHiddenSettings,gridId);
								$("##overlay").hide();
								var now = new Date();
								var nowstring = now.toISOString().replace(/[^0-9TZ]/g,'_');
								var filename = searchType + '_results_' + nowstring + '.csv';
								// display the number of rows found
								var datainformation = $('##' + gridId).jqxGrid('getdatainformation');
								var rowcount = datainformation.rowscount;
								var items = "."
								if (rowcount > 0) {
									items = ". Click on conditions, instructions, remarks, or disposition cell to edit. ";
								}
								if (rowcount == 1) {
									$('##resultCount').html('Found ' + rowcount + ' ' + searchType + items);
								} else { 
									$('##resultCount').html('Found ' + rowcount + ' ' + searchType + 's' + items);
								}
								// set maximum page size
								if (rowcount > 100) { 
									$('##' + gridId).jqxGrid({ pagesizeoptions: ['5','10','50', '100', rowcount], pagesize: 50});
								} else if (rowcount > 50) { 
									$('##' + gridId).jqxGrid({ pagesizeoptions: ['5','10','50', rowcount], pagesize: 50});
								} else if (rowcount > 10) { 
									$('##' + gridId).jqxGrid({ pagesizeoptions: ['5','10', rowcount], pagesize: 50});
								} else { 
									$('##' + gridId).jqxGrid({ pageable: false });
								}
								// add a control to show/hide columns
								var columns = $('##' + gridId).jqxGrid('columns').records;
								var halfColumns = Math.round(columns.length/2);
		
								var columnListSource = [];
								for (i = 1; i < halfColumns; i++) {
									try {
										var text = columns[i].text;
										var datafield = columns[i].datafield;
										var hideable = columns[i].hideable;
										var hidden = columns[i].hidden;
										var show = ! hidden;
										if (hideable == true) { 
											var listRow = { label: text, value: datafield, checked: show };
											columnListSource.push(listRow);
										}
									} catch (e) {
										console.log("Caught exception: " + e.message);
									}
								} 
								$("##columnPick").jqxListBox({ source: columnListSource, autoHeight: true, width: '260px', checkboxes: true });
								$("##columnPick").on('checkChange', function (event) {
									$("##" + gridId).jqxGrid('beginupdate');
									if (event.args.checked) {
										$("##" + gridId).jqxGrid('showcolumn', event.args.value);
									} else {
										$("##" + gridId).jqxGrid('hidecolumn', event.args.value);
									}
									$("##" + gridId).jqxGrid('endupdate');
								});
		
								var columnListSource1 = [];
								for (i = halfColumns; i < (halfColumns*2); i++) {
									try {
										var text = columns[i].text;
										var datafield = columns[i].datafield;
										var hideable = columns[i].hideable;
										var hidden = columns[i].hidden;
										var show = ! hidden;
										if (hideable == true) { 
											var listRow = { label: text, value: datafield, checked: show };
											columnListSource1.push(listRow);
										}
									} catch (e) {
										console.log("Caught exception: " + e.message);
									}
								} 
								$("##columnPick1").jqxListBox({ source: columnListSource1, autoHeight: true, width: '260px', checkboxes: true });
								$("##columnPick1").on('checkChange', function (event) {
									$("##" + gridId).jqxGrid('beginupdate');
									if (event.args.checked) {
										$("##" + gridId).jqxGrid('showcolumn', event.args.value);
									} else {
										$("##" + gridId).jqxGrid('hidecolumn', event.args.value);
									}
									$("##" + gridId).jqxGrid('endupdate');
								});
		
								$("##columnPickDialog").dialog({ 
									height: 'auto', 
									width: 'auto',
									adaptivewidth: true,
									title: 'Show/Hide Columns',
									autoOpen: false,
									modal: true, 
									reszable: true, 
									buttons: { 
										Ok: function(){ 
											window.columnHiddenSettings = getColumnVisibilities('searchResultsGrid');		
											<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
												saveColumnVisibilities('#cgi.script_name#',window.columnHiddenSettings,'Default');
											</cfif>
											$(this).dialog("close");
										}
									},
									open: function (event, ui) { 
										var maxZIndex = getMaxZIndex();
										// force to lie above the jqx-grid-cell and related elements, see z-index workaround below
										$('.ui-dialog').css({'z-index': maxZIndex + 4 });
										$('.ui-widget-overlay').css({'z-index': maxZIndex + 3 }); 
									} 
								});
								$("##columnPickDialogButton").html(
									"<button id='columnPickDialogOpener' onclick=\" $('##columnPickDialog').dialog('open'); \" class='btn-xs btn-secondary px-3 py-1 my-2 mx-3' >Show/Hide Columns</button>"
								);
								// workaround for menu z-index being below grid cell z-index when grid is created by a loan search.
								// likewise for the popup menu for searching/filtering columns, ends up below the grid cells.
								var maxZIndex = getMaxZIndex();
								$('.jqx-grid-cell').css({'z-index': maxZIndex + 1});
								$('.jqx-grid-group-cell').css({'z-index': maxZIndex + 1});
								$('.jqx-menu-wrapper').css({'z-index': maxZIndex + 2});
								$('##resultDownloadButtonContainer').html('<button id="loancsvbutton" class="btn-xs btn-secondary px-3 py-1 my-2 mx-0" aria-label="Export results to csv" onclick=" exportGridToCSV(\'searchResultsGrid\', \''+filename+'\'); " >Export to CSV</button>');
								$('##locationButtonContainer').html('<a id="locationbutton" class="btn-xs btn-secondary px-3 py-1 my-2 mx-1" aria-label="View part locations in storage heirarchy" href="/findContainer.cfm?loan_trans_id=#transaction_id#" target="_blank" >View Part Locations</a>');
								<cfif isClosed>
									// onstartup disable edit controls
									if (gotRunOnLoad == false) {
										disableEditControls();
										$("##" + gridId).jqxGrid('setcolumnproperty', 'EditRow', 'hidden', true);
										gotRunOnLoad = true;
									}
								</cfif>
							};
		
							// Cell renderers
							var specimenCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
								var rowData = jQuery("##searchResultsGrid").jqxGrid('getrowdata',row);
								var result = "";
								result = '<span class="#cellRenderClasses#" style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; "><a target="_blank" href="/guid/' + rowData['guid'] + '">'+value+'</a></span>';
								return result;
							};
							var deleteCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
								var rowData = jQuery("##searchResultsGrid").jqxGrid('getrowdata',row);
								var result = "";
								var itemid = rowData['part_id'];
								<cfif isClosed>
									result = '<span class="#cellRenderClasses#" style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; ">'+value+'</span>';
								<cfelse>
									if (itemid) {
										result = '<span class="#cellRenderClasses# float-left mt-1"' + columnproperties.cellsalign + '; "><a name="removeLoanItem" type="button" value="Delete" onclick="removeLoanItem(' + itemid+ ');" class="btn btn-xs btn-warning">Remove</a></span>';
									} else { 
										result = '<span class="#cellRenderClasses#" style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; ">'+value+'</span>';
									}
								</cfif>
								return result;
							};
							var editCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
								// Display a button to launch an edit dialog
								var rowData = jQuery("##searchResultsGrid").jqxGrid('getrowdata',row);
								var loan_item_id = rowData['loan_item_id'];
								return '<span style="margin-top: 4px; margin-left: 4px; float: ' + columnproperties.cellsalign + '; "><input type="button" onClick=" openLoanItemDialog('+loan_item_id+',\'editItemDialog\',\'Loan Item\',reloadGrid); " class="p-1 btn btn-xs btn-warning" value="Edit" aria-label="Edit"/></span>';
							};
							var returnCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
								// Display a button to mark a loan item as returned
								var rowData = jQuery("##searchResultsGrid").jqxGrid('getrowdata',row);
								var loan_item_id = rowData['loan_item_id'];
								return '<span style="margin-top: 4px; margin-left: 4px; float: ' + columnproperties.cellsalign + '; "><input type="button" onClick=" resolveLoanItem('+loan_item_id+',\'gridActionFeedbackDiv\',\'returned\',reloadGrid); " class="p-1 btn btn-xs btn-warning" value="Return" aria-label="Mark Item as Returned"/></span>';
							};
							var consumedCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
								// Display a button to mark a loan item as consumed
								var rowData = jQuery("##searchResultsGrid").jqxGrid('getrowdata',row);
								var loan_item_id = rowData['loan_item_id'];
								return '<span style="margin-top: 4px; margin-left: 4px; float: ' + columnproperties.cellsalign + '; "><input type="button" onClick=" resolveLoanItem('+loan_item_id+',\'gridActionFeedbackDiv\',\'returned\',reloadGrid); " class="p-1 btn btn-xs btn-warning" value="Consume" aria-label="Mark Item as Consumed"/></span>';
							};
							var historyCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
								return 'History';
							};
							var editableCellClass = function (row, columnfield, value) {
								<cfif isClosed>
									return 'flag-editable-cell';
								<cfelse>
									return 'bg-light editable-cell';
								</cfif>
							};
							var historyButtonClick = function(row) {
								var rowData = jQuery("##searchResultsGrid").jqxGrid('getrowdata',row);
								var itemid = rowData['part_id'];
								openItemConditionHistoryDialog(itemid,'itemConditionHistoryDialog');
							};
		
							var search = {
								datatype: "json",
								datafields:
									[
										{ name: 'transaction_id', type: 'string' },
										{ name: 'loan_item_id', type: 'string' },
										{ name: 'part_id', type: 'string' },
										{ name: 'catalog_number', type: 'string' },
										{ name: 'scientific_name', type: 'string' },
										{ name: 'collection', type: 'string' },
										{ name: 'collection_cde', type: 'string' },
										{ name: 'part_name', type: 'string' },
										{ name: 'preserve_method', type: 'string' },
										{ name: 'condition', type: 'string' },
										{ name: 'sampled_from_obj_id', type: 'string' },
										{ name: 'item_descr', type: 'string' },
										{ name: 'item_instructions', type: 'string' },
										{ name: 'loan_item_remarks', type: 'string' },
										{ name: 'reconciled_by_person_id', type: 'string' },
										{ name: 'reconciled_by_agent', type: 'string' },
										{ name: 'reconciled_date', type: 'string' },
										{ name: 'return_date', type: 'string' },
										{ name: 'resolution_recorded_by_agent', type: 'string' },
										{ name: 'resolution_date', type: 'string' },
										{ name: 'resolution_remarks', type: 'string' },
										{ name: 'loan_item_state', type: 'string' },
										{ name: 'coll_obj_disposition', type: 'string' },
										{ name: 'encumbrance', type: 'string' },
										{ name: 'encumbering_agent_name', type: 'string' },
										{ name: 'location', type: 'string' },
										{ name: 'short_location', type: 'string' },
										{ name: 'location_room', type: 'string' },
										{ name: 'location_compartment', type: 'string' },
										{ name: 'location_freezer', type: 'string' },
										{ name: 'location_fixture', type: 'string' },
										{ name: 'location_tank', type: 'string' },
										{ name: 'location_cryovat', type: 'string' },
										{ name: 'previous_location', type: 'string' },
										{ name: 'stored_as_name', type: 'string' },
										{ name: 'sovereign_nation', type: 'string' },
										{ name: 'loan_number', type: 'string' },
										{ name: 'guid', type: 'string' },
										{ name: 'collection_object_id', type: 'string' },
										{ name: 'custom_id', type: 'string' }
									],
								updaterow: function (rowid, rowdata, commit) {
									var data = "method=updateLoanItem";
									data = data + "&transaction_id=" + rowdata.transaction_id;
									data = data + "&part_id=" + rowdata.part_id;
									data = data + "&condition=" + encodeURIComponent(rowdata.condition);
									data = data + "&item_instructions=" + encodeURIComponent(rowdata.item_instructions);
									data = data + "&coll_obj_disposition=" + encodeURIComponent(rowdata.coll_obj_disposition);
									data = data + "&loan_item_remarks=" + encodeURIComponent(rowdata.loan_item_remarks);
									data = data + "&resolution_remarks=" + encodeURIComponent(rowdata.resolution_remarks);
									data = data + "&item_descr=" + encodeURIComponent(rowdata.item_descr);
									$.ajax({
										dataType: 'json',
										url: '/transactions/component/itemFunctions.cfc',
										data: data,
										success: function (data, status, xhr) {
											commit(true);
										},
										error: function (jqXHR,textStatus,error) {
											commit(false);
											handleFail(jqXHR,textStatus,error,"saving loan item");
										}
									});
								},
								root: 'loanItemRecord',
								id: 'itemId',
								url: '/transactions/component/itemFunctions.cfc?method=getLoanItemsData&transaction_id=#transaction_id#',
								timeout: #Application.ajax_timeout#000, // units not specified, miliseconds? 
								loadError: function(jqXHR, textStatus, error) { 
									handleFail(jqXHR,textStatus,error,"loading loan items");
								},
								async: true
							};
		
							function reloadGridNoBroadcast() { 
								var dataAdapter = new $.jqx.dataAdapter(search);
								$("##searchResultsGrid").jqxGrid({ source: dataAdapter });
								// refresh summary data 
								reloadLoanSummaryData();
							}
							function reloadGrid() { 
								reloadGridNoBroadcast();
								// Broadcast that a change has happened to the loan items
								bc.postMessage({"source":"reviewitems","transaction_id":"#transaction_id#"});
							};
							function reloadLoanSummaryData(){ 
								// reload dispositions of loan items
								$.ajax({
									dataType: 'html',
									url: '/transactions/component/itemFunctions.cfc?method=getDispositionsList&transaction_id=#transaction_id#',
									success: function (data, status, xhr) {
										$('##dispositionsDiv').html(data);
									},
									error: function (jqXHR,textStatus,error) {
										handleFail(jqXHR,textStatus,error,"loading loan summary data, dispositions");
									}
								});
								// reload preservation types of loan items
								$.ajax({
									dataType: 'html',
									url: '/transactions/component/itemFunctions.cfc?method=getPreservationsList&transaction_id=#transaction_id#',
									success: function (data, status, xhr) {
										$('##preservationDiv').html(data);
									},
									error: function (jqXHR,textStatus,error) {
										handleFail(jqXHR,textStatus,error,"loading loan summary data, preservations");
									}
								});
								// reload countries of origin of loan items
								$.ajax({
									dataType: 'html',
									url: '/transactions/component/itemFunctions.cfc?method=getCountriesList&transaction_id=#transaction_id#',
									success: function (data, status, xhr) {
										$('##countriesDiv').html(data);
									},
									error: function (jqXHR,textStatus,error) {
										handleFail(jqXHR,textStatus,error,"loading loan summary data, preservations");
									}
								});
								// update numeric values in loan item count spans 
								$.ajax({
									dataType: "json",
									url: "/transactions/component/functions.cfc",
									data: { 
										method : "getLoanItemCounts",
										transaction_id : #transaction_id#,
										returnformat : "json",
										queryformat : 'column'
									},
									error: function (jqXHR, status, message) {
										messageDialog("Error updating item count: " + status + " " + jqXHR.responseText ,'Error: '+ status);
									},
									success: function (result) {
										if (result.DATA.STATUS[0]==1) {
											$(".itemCountSpan").html(result.DATA.PARTCOUNT[0]);
											$(".catnumCountSpan").html(result.DATA.PARTCOUNT[0]);
											var message  = "There are " + result.DATA.PARTCOUNT[0];
											message += " parts from " + result.DATA.CATITEMCOUNT[0];
											message += " catalog numbers in " + result.DATA.COLLECTIONCOUNT[0];
											message += " collections with " + result.DATA.PRESERVECOUNT[0] +  " preservation types in this loan.";
											console.log(message);
										}
									}
								});
							}
		
							function loadGrid() { 
								var dataAdapter = new $.jqx.dataAdapter(search);
								var initRowDetails = function (index, parentElement, gridElement, datarecord) {
									// could create a dialog here, but need to locate it later to hide/show it on row details opening/closing and not destroy it.
									var details = $($(parentElement).children()[0]);
									details.html("<div id='rowDetailsTarget" + index + "'></div>");
									createRowDetailsDialog('searchResultsGrid','rowDetailsTarget',datarecord,index);
									// Workaround, expansion sits below row in zindex.
									var maxZIndex = getMaxZIndex();
									$(parentElement).css('z-index',maxZIndex - 1); // will sit just behind dialog
								};
								$("##searchResultsGrid").jqxGrid({
									width: '100%',
									autoheight: 'true',
									source: dataAdapter,
									filterable: true,
									sortable: true,
									pageable: true,
									<cfif isClosed>
										editable: false,
									<cfelse>
										editable: true,
									</cfif>
									enablemousewheel: #session.gridenablemousewheel#,
									pagesize: 50,
									pagesizeoptions: ['5','10','50','100'],
									showaggregates: true,
									columnsresize: true,
									autoshowfiltericon: true,
									autoshowcolumnsmenubutton: false,
									autoshowloadelement: false, // overlay acts as load element for form+results
									columnsreorder: true,
									groupable: true,
									selectionmode: 'singlerow',  // editable grid leaving as selection mode singlerow
									altrows: true,
									showtoolbar: false,
									ready: function () {
										$("##searchResultsGrid").jqxGrid('selectrow', 0);
									},
									columns: [
										<cfif isClosed>
											{text: 'Edit', datafield: 'EditRow', cellsrenderer:editCellRenderer, width: 40, hidable:true, hidden: true, editable: false },
										<cfelseif isInProcess>
											{text: 'Edit', datafield: 'EditRow', cellsrenderer:editCellRenderer, width: 40, hidable:false, hidden: false, editable: false },
											{text: 'Remove', datafield: 'RemoveRow', width: 78, hideable: false, hidden: false, cellsrenderer: deleteCellRenderer, editable: false },
										<cfelse>
											{text: 'Edit', datafield: 'EditRow', cellsrenderer:editCellRenderer, width: 40, hidable:true, hidden: false, editable: false },
											<cfif aboutLoan.loan_type EQ 'returnable'>
												{text: 'Return', datafield: 'ReturnRow', width: 78, hideable: true, hidden: false, cellsrenderer: returnCellRenderer, editable: false },
											<cfelseif aboutLoan.loan_type EQ 'consumable'>
												{text: 'Consume', datafield: 'ConsumeRow', width: 80, hideable: true, hidden: false, cellsrenderer: consumedCellRenderer, editable: false },
											</cfif>
										</cfif>
										{text: 'Loan Item State', datafield: 'loan_item_state', width:110, hideable: true, hidden: getColHidProp('loan_item_state', false), editable: false },
										{text: 'transactionID', datafield: 'transaction_id', width: 50, hideable: true, hidden: getColHidProp('transaction_id', true), editable: false },
										{text: 'PartID', datafield: 'part_id', width: 80, hideable: true, hidden: getColHidProp('part_id', true), editable: false },
										{text: 'Loan Number', datafield: 'loan_number', hideable: true, hidden: getColHidProp('loan_number', true), editable: false },
										{text: 'Collection', datafield: 'collection', width:80, hideable: true, hidden: getColHidProp('collection', true), editable: false  },
										{text: 'Collection Code', datafield: 'collection_cde', width:60, hideable: true, hidden: getColHidProp('collection_cde', false), editable: false  },
										{text: 'Catalog Number', datafield: 'catalog_number', width:80, hideable: true, hidden: getColHidProp('catalog_number', false), editable: false, cellsrenderer: specimenCellRenderer },
										{text: 'GUID', datafield: 'guid', width:80, hideable: true, hidden: getColHidProp('guid', true), editable: false  },
										{text: '#session.CustomOtherIdentifier#', width: 100, datafield: 'custom_id', hideable: true, hidden: getColHidProp('#session.CustomOtherIdentifier#', true), editable: false },
										{text: 'Scientific Name', datafield: 'scientific_name', width:210, hideable: true, hidden: getColHidProp('scientific_name', false), editable: false },
										{text: 'Stored As', datafield: 'stored_as_name', width:210, hideable: true, hidden: getColHidProp('stored_as_name', true), editable: false },
										{text: 'Storage Location', datafield: 'short_location', width:210, hideable: true, hidden: getColHidProp('short_location', true), editable: false },
										{text: 'Previous Location', datafield: 'previous_location', width:210, hideable: true, hidden: getColHidProp('previous_location', true), editable: false },
										{text: 'Full Storage Location', datafield: 'location', width:210, hideable: true, hidden: getColHidProp('location', true), editable: false },
										{text: 'Room', datafield: 'location_room', width:90, hideable: true, hidden: getColHidProp('location_room', true), editable: false },
										{text: 'Fixture', datafield: 'location_fixture', width:90, hideable: true, hidden: getColHidProp('location_fixture', true), editable: false },
										{text: 'Tank', datafield: 'location_tank', width:90, hideable: true, hidden: getColHidProp('location_tank', true), editable: false },
										{text: 'Freezer', datafield: 'location_freezer', width:90, hideable: true, hidden: getColHidProp('location_freezer', true), editable: false },
										{text: 'Cryovat', datafield: 'location_cryovat', width:90, hideable: true, hidden: getColHidProp('location_cryovat', true), editable: false },
										{text: 'Compartment', datafield: 'location_compartment', width:90, hideable: true, hidden: getColHidProp('location_compartment', true), editable: false },
										{text: 'Part Name', datafield: 'part_name', width:110, hideable: true, hidden: getColHidProp('part_name', false), editable: false },
										{text: 'Preserve Method', datafield: 'preserve_method', width:100, hideable: true, hidden: getColHidProp('preserve_method', false), editable: false },
										{text: 'Subsample', datafield: 'sampled_from_obj_id', width:80, hideable: false, hidden: getColHidProp('sampled_from_obj_id', false), editable: false },
										{text: 'Part Condition', datafield: 'condition', width:180, hideable: false, hidden: getColHidProp('condition', false), editable: true, cellclassname: editableCellClass },
										{text: 'Item Descr', datafield: 'item_descr', width:200, hideable: false, hidden: getColHidProp('item_descr', false), editable: true, cellclassname: editableCellClass },
										{text: 'History', datafield: 'History', width:80, columntype: 'button', hideable: true, hidden: getColHidProp('History', true), editable: false, 
											cellsrenderer: historyCellRenderer, buttonclick: historyButtonClick
										},
										{text: 'Item Instructions', datafield: 'item_instructions', width:180, hideable: false, hidden: getColHidProp('item_instructions', false), editable: true, cellclassname: editableCellClass },
										{text: 'Item Remarks', datafield: 'loan_item_remarks', width:180, hideable: false, hidden: getColHidProp('loan_item_remarks', false), editable: true, cellclassname: editableCellClass },
										{text: 'Disposition', datafield: 'coll_obj_disposition', width:180, hideable: false, hidden: getColHidProp('coll_obj_disposition', false), editable: true, 
											cellclassname: editableCellClass, 
											columntype: 'dropdownlist',
											initEditor: function(row, cellvalue, editor) { editor.jqxDropDownList({ source: #ctDispSource# }).jqxDropDownList('selectItem', cellvalue ); }
										},
										{text: 'Added By', datafield: 'reconciled_by_agent', width:110, hideable: true, hidden: getColHidProp('reconciled_by_agent', true), editable: false },
										{text: 'Added Date', datafield: 'reconciled_date', width:110, hideable: true, hidden: getColHidProp('reconciled_date', false), editable: false },
										{text: 'Return Date', datafield: 'return_date', width:110, hideable: true, hidden: getColHidProp('return_date', true), editable: false },
										{text: 'Resolution By', datafield: 'resolution_recorded_by_agent', width:110, hideable: true, hidden: getColHidProp('resolution_recorded_by_agent', true), editable: false },
										{text: 'Resolution Remarks', datafield: 'resolution_remarks', width:180, hideable: true, hidden: getColHidProp('resolution_remarks', true), editable: true, cellclassname: editableCellClass },	
										{text: 'Encumbrance', datafield: 'encumbrance', width:100, hideable: true, hidden: getColHidProp('encumbrance', false), editable: false },
										{text: 'Encumbered By', datafield: 'encumbering_agent_name', width:100, hideable: true, hidden: getColHidProp('encumbring_agent_id', true), editable: false },
										{text: 'Country of Origin', datafield: 'sovereign_nation', hideable: true, hidden: getColHidProp('sovereign_nation', false), editable: false }
									],
									rowdetails: true,
									rowdetailstemplate: {
										rowdetails: "<div style='margin: 10px;'>Row Details</div>",
										rowdetailsheight: 1 // row details will be placed in popup dialog
									},
									initrowdetails: initRowDetails
								});
								$("##searchResultsGrid").on("bindingcomplete", function(event) {
									gridLoaded('searchResultsGrid','loan item');
								});
								$('##searchResultsGrid').on('rowexpand', function (event) {
									// Create a content div, add it to the detail row, and make it into a dialog.
									var args = event.args;
									var rowIndex = args.rowindex;
									var datarecord = args.owner.source.records[rowIndex];
									createRowDetailsDialog('searchResultsGrid','rowDetailsTarget',datarecord,rowIndex);
								});
								$('##searchResultsGrid').on('rowcollapse', function (event) {
									// remove the dialog holding the row details
									var args = event.args;
									var rowIndex = args.rowindex;
									$("##searchResultsGridRowDetailsDialog" + rowIndex ).dialog("destroy");
								});
							};
							$(document).ready(function() {
								loadGrid();
							});
						</script>
	
					</div>
				</section>
			</cfoutput>
		</main>
	</cfdefaultcase>
</cfswitch>

<cfinclude template="/shared/_footer.cfm">
