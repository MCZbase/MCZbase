<!---
transactions/addDeaccItemsByBarcode.cfm
 
Copyright 2008-2017 Contributors to Arctos
Copyright 2008-2021 President and Fellows of Harvard College

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
<cfcomponent>
<cf_rolecheck>
<cfinclude template="/shared/component/error_handler.cfc" runOnce="true">

<!---   Function addPartToDeacc add a part to a deaccession --->
<cffunction name="addPartToDeacc" access="remote" returntype="any" returnformat="json">
	<cfargument name="transaction_id" type="numeric" required="yes">
	<cfargument name="partID" type="numeric" required="yes">
	<cfargument name="remark" type="string" required="yes">
	<cfargument name="instructions" type="string" required="yes">
	<cfargument name="subsample" type="numeric" required="yes">
	<cfoutput>
	<cftransaction>
		<cftry>
			<cfquery name="n" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select sq_collection_object_id.nextval n from dual
			</cfquery>
			<cfquery name="meta" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select cataloged_item.collection_object_id,
				cat_num,collection,part_name, preserve_method
				from
				cataloged_item,
				collection,
				specimen_part
				where
				cataloged_item.collection_id=collection.collection_id and
				cataloged_item.collection_object_id=specimen_part.derived_from_cat_item and
				specimen_part.collection_object_id= <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#partID#">
			</cfquery>
			<cfif #subsample# is 1>
			<cfquery name="parentData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT
					coll_obj_disposition,
					condition,
					part_name,
					preserve_method,
					derived_from_cat_item
				FROM
					coll_object, specimen_part
				WHERE
					coll_object.collection_object_id = specimen_part.collection_object_id AND
					coll_object.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#partID#">
			</cfquery>
			<cfquery name="newCollObj" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				INSERT INTO coll_object (
					COLLECTION_OBJECT_ID,
					COLL_OBJECT_TYPE,
					ENTERED_PERSON_ID,
					COLL_OBJECT_ENTERED_DATE,
					LAST_EDITED_PERSON_ID,
					LAST_EDIT_DATE,
					COLL_OBJ_DISPOSITION,
					LOT_COUNT,
					CONDITION)
				VALUES
					(
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#n.n#">,
					'SS',
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.myAgentId#">,
					sysdate,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.myAgentId#">,
					sysdate,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#parentData.coll_obj_disposition#">,
					1,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#parentData.condition#">)
			</cfquery>
			<cfquery name="decrementParentLotCount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE coll_object set LOT_COUNT = LOT_COUNT -1,
					LAST_EDITED_PERSON_ID = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.myAgentId#">,
					LAST_EDIT_DATE = sysdate
				where COLLECTION_OBJECT_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#partID#">
					and LOT_COUNT > 1
			</cfquery>
			<cfquery name="newPart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				INSERT INTO specimen_part (
					COLLECTION_OBJECT_ID
					,PART_NAME
					,PRESERVE_METHOD
					,SAMPLED_FROM_OBJ_ID
					,DERIVED_FROM_CAT_ITEM)
				VALUES (
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#n.n#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#parentData.part_name#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#parentData.preserve_method#">,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#partID#">,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#parentData.derived_from_cat_item#">)
			</cfquery>
			<cfquery name="newRemark" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				INSERT INTO coll_object_remark (
					COLLECTION_OBJECT_ID,
 					COLL_OBJECT_REMARKS )
				VALUES (
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#n.n#">,
					'Deaccessioned Subsample')
			</cfquery>
		</cfif>
		<cfquery name="addDeaccItem" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			INSERT INTO DEACC_ITEM (
				TRANSACTION_ID,
				COLLECTION_OBJECT_ID,
				RECONCILED_BY_PERSON_ID,
				RECONCILED_DATE
				,ITEM_DESCR
				<cfif len(#instructions#) gt 0>
					,ITEM_INSTRUCTIONS
				</cfif>
				<cfif len(#remark#) gt 0>
					,DEACC_ITEM_REMARKS
				</cfif>
				       )
			VALUES (
				#TRANSACTION_ID#,
				<cfif #subsample# is 1>
					#n.n#,
				<cfelse>
					#partID#,
				</cfif>
				#session.myagentid#,
				sysdate
				,'#meta.collection# #meta.cat_num# #meta.part_name#(#meta.preserve_method#)'
				<cfif len(#instructions#) gt 0>
					,'#instructions#'
				</cfif>
				<cfif len(#remark#) gt 0>
					,'#remark#'
				</cfif>
				)
		</cfquery>

               <cfquery name="getDeaccType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
                       select deacc_type from deaccession where transaction_id = #TRANSACTION_ID#
               </cfquery>

               <cfset partDisp = getDeaccType.deacc_type>

               <cfif partDisp eq "exchange">
                       <cfset partDisp = "exchanged">
               </cfif>

		<cfquery name="setDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
                       UPDATE coll_object SET coll_obj_disposition = 'deaccessioned - ' || '#partDisp#'
			where collection_object_id =
		<cfif #subsample# is 1>
				#n.n#
			<cfelse>
				#partID#
			</cfif>
		</cfquery>
	<cfcatch>
		<cfset result = "0|#cfcatch.message# #cfcatch.detail#">
		<cfreturn result>
	</cfcatch>
	</cftry>
	<cfreturn "1|#partID#">
	</cftransaction>
	</cfoutput>

</cffunction>

<!--- function removePartFromDeacc remove a part from a deaccession --->
<cffunction name="removePartFromDeacc" access="remote" returntype="string" returnformat="plain">
	<cfargument name="transaction_id" type="numeric" required="yes">
	<cfargument name="partID" type="numeric" required="yes">
	<cfoutput>
	<cfif isdefined("coll_obj_disposition") AND coll_obj_disposition is not "in collection">
		<!--- see if it's a subsample --->
		<cfquery name="isSSP" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select SAMPLED_FROM_OBJ_ID from 
			specimen_part 
			where collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#partID#">
		</cfquery>
		<cfif #isSSP.SAMPLED_FROM_OBJ_ID# gt 0>
					You cannot remove this item from a loan while it's disposition is "on loan." 
			<br />Use the form below if you'd like to change the disposition and remove the item 
			from the deaccession, or to delete the item from the database completely.
			
			<form name="cC" method="post" action="a_deaccItemReview.cfm">
				<input type="hidden" name="action" />
				<input type="hidden" name="transaction_id" value="#transaction_id#" />
				<input type="hidden" name="deacc_item_remarks" value="#deacc_item_remarks#" />
				<input type="hidden" name="partID" value="#partID#" />
				<input type="hidden" name="spRedirAction" value="delete" />
				Change disposition to: <select name="coll_obj_disposition" size="1">
					<cfloop query="ctdeacc_type">
						<option value="#deacc_type#">#ctdeacc_type.deacc_type#</option>
					</cfloop>				
				</select>
				<p />
				<input type="button" 
					class="delBtn"
					onmouseover="this.className='delBtn btnhov'"
					onmouseout="this.className='delBtn'"
					value="Remove Item from Deaccession" 
					onclick="cC.action.value='saveDisp'; submit();" />
				
				<p /><input type="button" 
					class="delBtn"
					onmouseover="this.className='delBtn btnhov'"
					onmouseout="this.className='delBtn'"
					value="Delete Subsample From Database" 
					onclick="cC.action.value='killSS'; submit();"/>
					<p /><input type="button" 
					class="qutBtn"
					onmouseover="this.className='qutBtn btnhov'"
					onmouseout="this.className='qutBtn'"
					value="Discard Changes" 
					onclick="cC.action.value='nothing'; submit();"/>
			</form>
			<cfabort>
			<cfabort>
		<cfelse>
			You cannot remove this item from a loan while it's disposition is "deaccessioned." 
			<br />Use the form below if you'd like to change the disposition and remove the item 
			from the loan.
			
			<form name="cC" method="post" action="a_deaccItemReview.cfm">
				<input type="hidden" name="action" />
				<input type="hidden" name="transaction_id" value="#transaction_id#" />
				<input type="hidden" name="deacc_item_remarks" value="#deacc_item_remarks#" />
				<input type="hidden" name="partID" id="partID" value="#partID#" />
				<input type="hidden" name="spRedirAction" value="delete" />
				<br />Change disposition to: <select name="coll_obj_disposition" size="1">
					<cfloop query="ctDisp">
						<option value="#coll_obj_disposition#">#ctDisp.coll_obj_disposition#</option>
					</cfloop>				
				</select>
				<br /><input type="button" 
					class="delBtn"
					onmouseover="this.className='delBtn btnhov'"
					onmouseout="this.className='delBtn'"
					value="Remove Item from Deaccession" 
					onclick="cC.action.value='saveDisp'; submit();" />
				<br /><input type="button" 
					class="qutBtn"
					onmouseover="this.className='qutBtn btnhov'"
					onmouseout="this.className='qutBtn'"
					value="Discard Changes" 
					onclick="cC.action.value='nothing'; submit();"/>
			</form>
			<cfabort>
		</cfif>
	</cfif>
	<cfquery name="deleDeaccItem" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		DELETE FROM deacc_item 
		where collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#partID#">
		and transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
	</cfquery>
		<cflocation url="a_deaccItemReview.cfm?transaction_id=#transaction_id#">
	</cfoutput>
</cffunction>

<!--- function updateLoanItem to update the condition, instructions, remarks, and disposition of an item in a loan.
 This is the backing function for the editable loan items grid. 
 @param transaction_id the transaction the loan item is in
 @param part_id the part participating in the loan item, loan item is a weak enity, it is keyed off of transaction_id and part_id 
   (as collection_object_id of the collection object for the part).
 @param condition the new value of the coll_object.condition to save.
 @param item_instructions the new value of the loan_item.item_instructions to save.
 @param loan_item_remarks the new value of the loan_item.item_remarks to save.
 @param coll_object_disposition the new value of the coll_object.coll_object_disposition to save.
 @return a json structurre with status:1, or a http 500 response.
--->
<cffunction name="updateLoanItem" access="remote" returntype="any" returnformat="json">
	<cfargument name="transaction_id" type="numeric" required="yes">
	<cfargument name="part_id" type="numeric" required="yes">
	<cfargument name="condition" type="string" required="yes">
	<cfargument name="item_instructions" type="string" required="yes">
	<cfargument name="loan_item_remarks" type="string" required="yes">
	<cfargument name="coll_obj_disposition" type="string" required="yes">

	<cftransaction>
		<cftry>
			<cfquery name="confirmItem" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="confirmItem_result">
				select * from loan_item
				WHERE
					collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#part_id#"> AND
					transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
			</cfquery>
			<cfif confirmItem.recordcount EQ 0>
				<cfthrow message="specified collection object is not a loan item in the specified transaction">
			</cfif>
			<cfquery name="upDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="upDisp_result">
				UPDATE coll_object 
				SET coll_obj_disposition = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#coll_obj_disposition#">,
					condition = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#condition#">
				where collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#part_id#">
			</cfquery>
			<cfif upDisp_result.recordcount NEQ 1>
				<cfthrow message="Record not updated. #transaction_id# #part_id# #upDisp_result.sql#">
			</cfif>
			<cfquery name="upItem" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="upItem_result">
				UPDATE loan_item SET
					transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
					<cfif len(#item_instructions#) gt 0>
						,item_instructions = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#item_instructions#">
					<cfelse>
						,item_instructions = null
					</cfif>
					<cfif len(#loan_item_remarks#) gt 0>
						,loan_item_remarks = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#loan_item_remarks#">
					<cfelse>
						,loan_item_remarks = null
					</cfif>
				WHERE
					collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#part_id#"> AND
					transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
			</cfquery>
			<cfif upItem_result.recordcount NEQ 1>
				<cfthrow message="Record not updated. #transaction_id# #part_id# #upItem_result.sql#">
			</cfif>
			<cfif upItem_result.recordcount eq 1>
				<cfset theResult=queryNew("status, message")>
				<cfset t = queryaddrow(theResult,1)>
				<cfset t = QuerySetCell(theResult, "status", "1", 1)>
				<cfset t = QuerySetCell(theResult, "message", "loan item updated.", 1)>
			</cfif>
			<cftransaction action="commit">
		<cfcatch>
			<cftransaction action="rollback">
			<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
			<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn theResult>
</cffunction>


<!--- function updateLoanItemDisposition to update the disposition of an item in a loan.
 @param transaction_id the transaction the loan item is in
 @param part_id the part participating in the loan item, loan item is a weak enity, it is keyed off of transaction_id and part_id 
   (as collection_object_id of the collection object for the part).
 @param coll_object_disposition the new value of the coll_object.coll_object_disposition to save.
 @return a json structure with status:1, or a http 500 response.
--->
<cffunction name="updateLoanItemDisposition" access="remote">
	<cfargument name="transaction_id" type="numeric" required="yes">
	<cfargument name="part_id" type="numeric" required="yes">
	<cfargument name="coll_obj_disposition" type="string" required="yes">

	<cftransaction>
		<cftry>
			<cfquery name="confirmItem" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="confirmItem_result">
				select * from loan_item
				WHERE
					collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#part_id#"> AND
					transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
			</cfquery>
			<cfif confirmItem.recordcount EQ 0>
				<cfthrow message="specified collection object is not a loan item in the specified transaction">
			</cfif>
			<cfquery name="upDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="upDisp_result">
				UPDATE coll_object 
				SET coll_obj_disposition = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#coll_obj_disposition#">
				where collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#part_id#">
			</cfquery>
			<cfif upDisp_result.recordcount eq 1>
				<cfset theResult=queryNew("status, message")>
				<cfset t = queryaddrow(theResult,1)>
				<cfset t = QuerySetCell(theResult, "status", "1", 1)>
				<cfset t = QuerySetCell(theResult, "message", "loan item disposition updated to #coll_obj_disposition#.", 1)>
			<cfelse>
				<cfthrow message="Record not updated. #transaction_id# #part_id# #upDisp_result.sql#">
			</cfif>
			<cftransaction action="commit">
		<cfcatch>
			<cftransaction action="rollback">
			<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
			<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn theResult>
</cffunction>

<!--- function getLoanItemsData return a json structure containing data to display in a grid listing the items in a loan.
 @param transaction_id the transaction_id of the loan for which to return loan items 
 @return a json structure suitable for populating a jqxgrid or an http 500 on an error.
--->
<cffunction name="getLoanItemsData" access="remote" returntype="any" returnformat="json">
	<cfargument name="transaction_id" type="numeric" required="yes">

	<cfset data = ArrayNew(1)>
	<cftry>
		<cfquery name="getLoanItemsQuery" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getLoanItemsQuery_result">
		select 
			loan.transaction_id,
			cat_num as catalog_number, 
			collection,
			collection.collection_cde,
			part_name,
			preserve_method,
			condition,
			decode(sampled_from_obj_id,null,'no ','of ' || MCZbase.get_part_prep(sampled_from_obj_id)) as sampled_from_obj_id,
			item_descr,
			item_instructions,
			loan_item_remarks,
			reconciled_by_person_id,
			MCZBASE.getPreferredAgentName(reconciled_by_person_id) as reconciled_by_agent,
			to_char(reconciled_date,'YYYY-MM-DD') reconciled_date,
			coll_obj_disposition,
			MCZBASE.get_scientific_name_auths(cataloged_item.collection_object_id) as scientific_name,
			MCZBASE.CONCATENCUMBRANCES(cataloged_item.collection_object_id) as encumbrance,
			MCZBASE.CONCATENCUMBAGENTS(cataloged_item.collection_object_id) as encumbering_agent_name,
			MCZBASE.concatlocation(MCZBASE.get_current_container_id(specimen_part.collection_object_id)) as location,
			MCZBASE.get_storage_parentage(MCZBASE.get_current_container_id(specimen_part.collection_object_id)) as short_location,
			MCZBASE.get_storage_parentatrank(MCZBASE.get_current_container_id(specimen_part.collection_object_id),'room') as location_room,
			MCZBASE.get_storage_parentatrank(MCZBASE.get_current_container_id(specimen_part.collection_object_id),'fixture') as location_fixture,
			MCZBASE.get_storage_parentatrank(MCZBASE.get_current_container_id(specimen_part.collection_object_id),'tank') as location_tank,
			MCZBASE.get_storage_parentatrank(MCZBASE.get_current_container_id(specimen_part.collection_object_id),'freezer') as location_freezer,
			MCZBASE.get_storage_parentatrank(MCZBASE.get_current_container_id(specimen_part.collection_object_id),'cryovat') as location_cryovat,
			MCZBASE.get_storage_parentatrank(MCZBASE.get_current_container_id(specimen_part.collection_object_id),'compartment') as location_compartment,
			mczbase.get_stored_as_id(cataloged_item.collection_object_id) as stored_as_name,
			loan_number,
			specimen_part.collection_object_id as part_id,
			concatSingleOtherId(cataloged_item.collection_object_id,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.CustomOtherIdentifier#">) AS customid,
			cataloged_item.collection_object_id as collection_object_id,
			'MCZ:' || collection.collection_cde || ':' || cat_num as guid,
			sovereign_nation
		from 
			loan
			left join loan_item on loan.transaction_id = loan_item.transaction_id
			left join specimen_part on loan_item.collection_object_id = specimen_part.collection_object_id
			left join cataloged_item on specimen_part.derived_from_cat_item = cataloged_item.collection_object_id 
			left join coll_object on specimen_part.collection_object_id = coll_object.collection_object_id 
			left join collection on cataloged_item.collection_id=collection.collection_id 
			left join collecting_event on cataloged_item.collecting_event_id = collecting_event.collecting_event_id
			left join locality on collecting_event.locality_id = locality.locality_id
		WHERE
			loan_item.transaction_id = <cfqueryparam cfsqltype="cf_sql_number" value="#transaction_id#" >
		ORDER BY cat_num
		</cfquery>
		<cfset rows = getLoanItemsQuery_result.recordcount>
		<cfset i = 1>
		<cfloop query="getLoanItemsQuery">
			<cfset row = StructNew()>
			<cfloop list="#ArrayToList(getLoanItemsQuery.getColumnNames())#" index="col" >
				<cfset row["#lcase(col)#"] = "#getLoanItemsQuery[col][currentRow]#">
			</cfloop>
			<cfset data[i]  = row>
			<cfset i = i + 1>
		</cfloop>
		<cfreturn #serializeJSON(data)#>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
</cffunction>


<!--- obtain an html block to populate dialog for removing loan items from a loan --->
<cffunction name="getRemoveLoanItemDialogContent" returntype="string" access="remote" returnformat="plain">
	<cfargument name="transaction_id" type="string" required="yes">
	<cfargument name="part_id" type="string" required="yes">

	<cfthread name="getRemoveLoanItemHtmlThread">
		<cftry>
			<cfoutput>
				<cfquery name="ctDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select coll_obj_disposition from ctcoll_obj_disp 
				</cfquery>
				<cfquery name="lookupDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT coll_obj_disposition 
					from coll_object 
					where collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#part_id#">
				</cfquery>
				<cfset currentDisposition = lookupDisp.coll_obj_disposition>
				<cfset onLoan=false>
				<cfif currentDisposition is "on loan">
					<cfset onLoan=true>
				</cfif>
				<div id="updateStatus"></div>
				<script>
					function updateDisp(new_disposition) { 
						updateLoanItemDisposition(#part_id#, #transaction_id#, new_disposition,'updateStatus');
					}
				</script>
				<cfquery name="getLoanItemDetails" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getLoanItemsQuery_result">
					select 
						item_descr
					from 
						loan_item
					WHERE
						loan_item.transaction_id = <cfqueryparam cfsqltype="cf_sql_number" value="#transaction_id#" >
						AND loan_item.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#part_id#">
				</cfquery>
				<h2 class="h3">Remove item #getLoanItemDetails.item_descr# from loan.</h2>
				<!--- see if it's a subsample --->
				<cfquery name="isSSP" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select SAMPLED_FROM_OBJ_ID 
					from specimen_part 
					where collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#part_id#">
				</cfquery>
				<cfif #isSSP.SAMPLED_FROM_OBJ_ID# gt 0>
					<cfif onLoan>
						<h3 class="h4">This subsample currently has a dispostion of "on loan."</h3>
						<p>You must change the disposition to remove the item from the loan, 
						or as this is a subsample, you may delete the item from the database completely.</p>
					<cfelse>
						<h3 class="h4">This subsample currently has a dispostion of "#lookupDisp.coll_obj_disposition#"</h3>
						<p>You may change the disposition and remove the item from the loan, 
						or, as this is a subsample, you may delete the item from the database completely.</p>
					</cfif>
				<cfelse>
					<cfif onLoan>
						<h3 class="h4">This item currently has a dispostion of "on loan"</h3>
						<p>You must change the disposition to remove the item from the loan</p>
					<cfelse>
						<h3 class="h4">This item currently has a dispostion of "#lookupDisp.coll_obj_disposition#"</h3>
						<p>You may change the disposition and remove the item from this loan</p>
					</cfif> 
				</cfif> 
				<label for="updateDispositionSelect" class="data-entry-label">Change disposition to:</label>
				<select name="coll_obj_disposition" size="1" class="data-entry-select" onchange="updateDisp(this.value);" id="updateDispositionSelect" >
					<cfloop query="ctDisp">
						<cfset selected = "">
						<cfif ctDisp.coll_obj_disposition EQ currentDisposition><cfset selected="selected='selected'"></cfif>
						<option value="#coll_obj_disposition#" #selected#>#ctDisp.coll_obj_disposition#</option>
					</cfloop>				
				</select>
				<p />
				<button class="btn btn-xs btn-warning" value="Remove Item from Loan" 
					onclick="removeLoanItemFromLoan(#part_id#, #transaction_id#,'updateStatus'); ">Remove Item from Loan</button>
				<cfif #isSSP.SAMPLED_FROM_OBJ_ID# gt 0>
					<p />
					<button class="btn btn-xs btn-danger"
						value="Delete Subsample From Database" 
						onclick="alert('not yet implemented');">Delete Subsample From Database</button> <!--- cC.action.value='killSS'; submit();"/> --->
				</cfif>
				<p />
			</cfoutput>
		<cfcatch>
			<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
			<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cfthread>
	<cfthread action="join" name="getRemoveLoanItemHtmlThread" />
	<cfreturn getRemoveLoanItemHtmlThread.output>
</cffunction>

<!--- delete an entry from the loan item table. 
	@param transaction_id the transaction_id of the loan from which to remove the loan item.
	@param partID the collection_object_id of the part to be removed as as an item from the specified loan.
	@return a json structure including status: 1 or an http 500 with an error message
--->
<cffunction name="removePartFromLoan" access="remote">
	<cfargument name="transaction_id" type="numeric" required="yes">
	<cfargument name="part_id" type="numeric" required="yes">

	<cftransaction>
		<cftry>
			<cfquery name="deleLoanItem" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="deleLoanItem_result">
				DELETE FROM loan_item 
				where collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#part_id#">
					and transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
			</cfquery>
			<cfif deleLoanItem_result.recordcount eq 1>
				<cfset theResult=queryNew("status, message")>
				<cfset t = queryaddrow(theResult,1)>
				<cfset t = QuerySetCell(theResult, "status", "1", 1)>
				<cfset t = QuerySetCell(theResult, "message", "loan item removed from loan.", 1)>
			</cfif>
			<cftransaction action="commit">
		<cfcatch>
			<cftransaction action="rollback">
			<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
			<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn theResult>
</cffunction>


<!---   Function addPartToLoan add a part to a loan as a loan item.
 @param transaction_id the loan to which to add the part as a loan item
 @param part_id the collection_object_id of the part to add as a loan item
 @param remark the loan item remarks.
 @param instructions the loan item instructions
 @param subsample, if value is one, then create a subsample from the specified part and add the subsample as
  a loan item to the loan, otherwise, add the part without creating a subsample.
--->
<cffunction name="addPartToLoan" access="remote" returntype="any" returnformat="json">
	<cfargument name="transaction_id" type="numeric" required="yes">
	<cfargument name="part_id" type="numeric" required="yes">
	<cfargument name="remark" type="string" required="yes">
	<cfargument name="instructions" type="string" required="yes">
	<cfargument name="subsample" type="numeric" required="yes">
	
	<cftransaction>
		<cftry>
			<cfquery name="checkIsLoan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT count(transaction_id) as ct
				FROM loan
				WHERE
					transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
			</cfquery>
			<cfif checkIsLoan.ct EQ 0>
				<cfthrow message="Provided transaction_id is not for a loan.">
			</cfif>
			<cfquery name="getLoan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT loan_number
				FROM loan
				WHERE
					transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
			</cfquery>
			<cfquery name="meta" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT cataloged_item.collection_object_id,
					cat_num,collection,part_name, preserve_method
				FROM
					cataloged_item 
					LEFT JOIN collection on cataloged_item.collection_id=collection.collection_id
					LEFT JOIN specimen_part on cataloged_item.collection_object_id=specimen_part.derived_from_cat_item
				WHERE
					specimen_part.collection_object_id= <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#part_id#">
			</cfquery>
			<cfif subsample IS 1 >
				<!--- create a subsample and add it as an item to the loan --->
				<cfquery name="parentData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT
						coll_obj_disposition,
						condition,
						part_name,
						preserve_method,
						derived_from_cat_item
					FROM
						coll_object, specimen_part
					WHERE
						coll_object.collection_object_id = specimen_part.collection_object_id AND
						coll_object.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#part_id#">
				</cfquery>
				<cfquery name="n" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select sq_collection_object_id.nextval n from dual
				</cfquery>
				<cfloop query="n">
					<cfset subsampleCollObjectID = n.n>
				</cfloop>
				<cfquery name="newCollObj" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					INSERT INTO coll_object (
						COLLECTION_OBJECT_ID,
						COLL_OBJECT_TYPE,
						ENTERED_PERSON_ID,
						COLL_OBJECT_ENTERED_DATE,
						LAST_EDITED_PERSON_ID,
						LAST_EDIT_DATE,
						COLL_OBJ_DISPOSITION,
						LOT_COUNT,
						CONDITION
					) VALUES (
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#subsampleCollObjectID#">,
						'SS',
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.myAgentId#">,
						sysdate,
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.myAgentId#">,
						sysdate,
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#parentData.coll_obj_disposition#">,
						1,
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#parentData.condition#">
					)
				</cfquery>
				<cfquery name="decrementParentLotCount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					UPDATE coll_object 
					SET LOT_COUNT = LOT_COUNT -1,
						LAST_EDITED_PERSON_ID = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.myAgentId#">,
						LAST_EDIT_DATE = sysdate
					WHERE COLLECTION_OBJECT_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#part_id#">
						and LOT_COUNT > 1
				</cfquery>
				<cfquery name="newPart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					INSERT INTO specimen_part (
						COLLECTION_OBJECT_ID
						,PART_NAME
						,PRESERVE_METHOD
						,SAMPLED_FROM_OBJ_ID
						,DERIVED_FROM_CAT_ITEM
					) VALUES (
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#subsampleCollObjectID#">,
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#parentData.part_name#">,
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#parentData.preserve_method#">,
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#part_id#">,
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#parentData.derived_from_cat_item#">
					)
				</cfquery>
				<cfquery name="newRemark" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					INSERT INTO coll_object_remark (
						COLLECTION_OBJECT_ID,
 						COLL_OBJECT_REMARKS 
					) VALUES (
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#subsampleCollObjectID#">,
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="Subsample For Loan #getLoan.loan_number#">
					)
				</cfquery>
			</cfif><!--- End subsample --->

			<cfquery name="addLoanItem" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				INSERT INTO LOAN_ITEM (
					TRANSACTION_ID
					,COLLECTION_OBJECT_ID
					,RECONCILED_BY_PERSON_ID
					,RECONCILED_DATE
					,ITEM_DESCR
					<cfif len(#instructions#) gt 0>
						,ITEM_INSTRUCTIONS
					</cfif>
					<cfif len(#remark#) gt 0>
						,LOAN_ITEM_REMARKS
					</cfif>
				) VALUES (
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#TRANSACTION_ID#">
					<cfif subsample IS 1 >
						,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#subsampleCollObjectId#">
					<cfelse>
						,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#part_id#">
					</cfif>
					,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#session.myagentid#">
					,sysdate
					,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#meta.collection# #meta.cat_num# #meta.part_name#(#meta.preserve_method#)">
					<cfif len(#instructions#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#instructions#">
					</cfif>
					<cfif len(#remark#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#remark#">
					</cfif>
				)
			</cfquery>

			<cfif subsample IS 1 >
				<cfset targetObject = subsampleCollObjectId>
			<cfelse>
				<cfset targetObject = part_id>
			</cfif>
			<cfquery name="setDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE coll_object 
				SET coll_obj_disposition = 'on loan'
				WHERE 
					collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#targetObject#">
			</cfquery>
			<cfset theResult=queryNew("status, message, subsample")>
			<cfset t = queryaddrow(theResult,1)>
			<cfset t = QuerySetCell(theResult, "status", "1", 1)>
			<cfset t = QuerySetCell(theResult, "message", "item added loan.", 1)>
			<cfif subsample IS 1 >
				<cfset t = QuerySetCell(theResult, "subsample", "#subsampleCollObjectId#", 1)>
			<cfelse>
				<cfset t = QuerySetCell(theResult, "subsample", "", 1)>
			</cfif>
			<cftransaction action="commit">
		<cfcatch>
			<cftransaction action="rollback">
			<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
			<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
		<cfreturn theResult>
	</cftransaction>
</cffunction>

<!--- obtain an html block to populate dialog for adding an item to a loan 
@param collection_object_id the collection object id of the cataloged item parts of which to list in dialog to add to loan
@param guid the guid of the cataloged item parts of which to list in dialog to add to loan, takes priority over collection_object_id.
@param transaction_id the id of the loan to which to add items.
@return an block of html suitable for populating a dialog for adding parts from a cataloged item to a loan.
--->
<cffunction name="getAddLoanItemDialogHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfargument name="guid" type="string" required="yes">
	<cfargument name="transaction_id" type="string" required="yes">

	<cfthread name="getAddLoanItemHtmlThread">
		<cftry>
			<cfif (not isdefined("collection_object_id") OR len(collection_object_id) EQ 0) AND (NOT isdefined("guid") OR len(guid) EQ 0)>
				<cfthrow message="Unable to look up cataloged item.  Either guid or collection_object_id must have a value.">
			</cfif>
			<cfoutput>
				<cfquery name="ctDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select coll_obj_disposition from ctcoll_obj_disp 
				</cfquery>
				<cfif isdefined("guid") AND len(guid) GT 0>
					<cfquery name="lookupCollObjId" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select collection_object_id 
						from flat
						where guid = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#guid#">
					</cfquery>
					<cfset collection_object_id = lookupCollObjId.collection_object_id>
				</cfif>
				<cfquery name="lookupCatalogedItem" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT distinct
						flat.guid, 
						mczbase.get_numparts(cataloged_item.collection_object_id) as num_parts,
						mczbase.GET_SCIENTIFIC_NAME_AUTHS(cataloged_item.collection_object_id) as current_ident,
						collectors,
						verbatim_date,
						higher_geog,
						spec_locality,
						typestatusplain as type_status_plain
					FROM cataloged_item 
						left join flat on cataloged_item.collection_object_id = flat.collection_object_id
					WHERE
						cataloged_item.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
				</cfquery>
				<h2 class="h3">Add parts to loan from cataloged item #guid#</h2>
				<div>
					<div>
						<ul>
							<cfloop query="lookupCatalogedItem">
								<li>#current_ident#</li>
								<cfif len(type_status_plain) GT 0>
									<li>#type_status_plain#</li>
								</cfif>
								<li>#higher_geog#</li>
								<li>#spec_locality#</li>
								<li>#collectors#</li>
								<li>#verbatim_date#</li>
							</cfloop>
						</ul>
					</div>
					<cfquery name="lookupParts" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						SELECT
							specimen_part.collection_object_id as part_id,
							part_name, part_modifier, preserve_method,
							coll_obj_disposition, lot_count, lot_count_modifier,
							condition
						FROM cataloged_item
							left join specimen_part on cataloged_item.collection_object_id = specimen_part.derived_from_cat_item
							left join coll_object on specimen_part.collection_object_id = coll_object.collection_object_id
						WHERE
							cataloged_item.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
					</cfquery>
					<div>
						<h2 class="h3">Parts/Preparations to add</h2>
						<cfset i=0>
						<cfloop query="lookupParts">
							<cfset i= i+1>
							<form id="addPart_#i#">
								<div class="form-row border">
									<div class="col-12">
										<label class="data-entry-label">
											#part_name##part_modifier# (#preserve_method#) #lot_count# #lot_count_modifier#
										</label>
										<input disabled type="text" value="#coll_obj_disposition# #condition#" class="data-entry-input w-100">
									</div>
									<cfif coll_obj_disposition NEQ "in collection">
										<div class="col-12">
											This part may not be available for loan, it has a current disposition of #coll_obj_disposition#.
										</div>
									</cfif>
									<div class="col-12 col-md-3">
										<label class="data-entry-label">Remark</label>
										<input type="text" id="addPart_#i#_remark" value="" class="data-entry-input">
									</div>
									<div class="col-12 col-md-3">
										<label class="data-entry-label">Instructions</label>
										<input type="text" id="addPart_#i#_instructions" value="" class="data-entry-input">
									</div>
									<div class="col-12 col-md-3">
										<label class="data-entry-label">Subsample</label>
										<input type="checkbox" id="addPart_#i#_subsample" class="data-entry-checkbox" value="1">
									</div>
									<div class="col-12 col-md-3">
										<label class="data-entry-label"><output id="addPart_#i#_feedback">&nbsp;</output></label>
										<button type="submit" id="buttonAddPart_#i#" class="btn btn-primary btn-xs">Add Part</button>
										<script>
											$(document).ready(function(){
												$("##buttonAddPart_#i#").click(function(evt) { 
													evt.preventDefault();
													addItemToLoan(#lookupParts.part_id#,#transaction_id#,$("##addPart_#i#_remark").val(),$("##addPart_#i#_instructions").val(),$("##addPart_#i#_subsample").prop("checked"),"addPart_#i#_feedback");
												});
											});
										</script>
									</div>
								</div>
							</form>
						</cfloop>
					</div>
				</div>
			</cfoutput>
		<cfcatch>
			<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
			<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cfthread>
	<cfthread action="join" name="getAddLoanItemHtmlThread" />
	<cfreturn getAddLoanItemHtmlThread.output>
</cffunction>

</cfcomponent>
