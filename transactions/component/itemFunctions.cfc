<!---
transactions/itemFunctions.cfc
 
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
<cfcomponent>
<cf_rolecheck>
<cfinclude template="/shared/component/error_handler.cfc" runOnce="true">

<!---   Function addPartToDeacc add a part to a deaccession DEPRECATED
 @deprecated replace usages where retained with addPartToDeaccession
--->
<cffunction name="addPartToDeacc" access="remote" returntype="any" returnformat="json">
	<cfargument name="transaction_id" type="numeric" required="yes">
	<cfargument name="partID" type="numeric" required="yes">
	<cfargument name="remark" type="string" required="yes">
	<cfargument name="instructions" type="string" required="yes">
	<cfargument name="subsample" type="numeric" required="yes">
	<cfoutput>
	<cftransaction>
		<cftry>
			<cfquery name="n" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				select sq_collection_object_id.nextval n from dual
			</cfquery>
			<cfquery name="meta" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
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
			<cfquery name="parentData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
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
			<cfquery name="newCollObj" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
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
			<cfquery name="decrementParentLotCount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE coll_object set LOT_COUNT = LOT_COUNT -1,
					LAST_EDITED_PERSON_ID = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.myAgentId#">,
					LAST_EDIT_DATE = sysdate
				where COLLECTION_OBJECT_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#partID#">
					and LOT_COUNT > 1
			</cfquery>
			<cfquery name="newPart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
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
			<cfquery name="newRemark" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				INSERT INTO coll_object_remark (
					COLLECTION_OBJECT_ID,
 					COLL_OBJECT_REMARKS )
				VALUES (
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#n.n#">,
					'Deaccessioned Subsample')
			</cfquery>
		</cfif>
		<cfquery name="addDeaccItem" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
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

               <cfquery name="getDeaccType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
                       select deacc_type from deaccession where transaction_id = #TRANSACTION_ID#
               </cfquery>

               <cfset partDisp = getDeaccType.deacc_type>

               <cfif partDisp eq "exchange">
                       <cfset partDisp = "exchanged">
               </cfif>

		<cfquery name="setDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
         UPDATE coll_object 
			SET coll_obj_disposition = 'deaccessioned - ' || '#partDisp#'
			WHERE collection_object_id =
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

<cffunction name="getRemoveDeaccItemDialogContent" access="remote" returntype="string" returnformat="plain">
	<cfargument name="deacc_item_id" type="string" required="yes">
	<cfargument name="dialogId" type="string" required="yes">

	<cfthread name="getRemoveDeaccItemDialogContentThread" deacc_item_id="#arguments.deacc_item_id#" dialogId="#arguments.dialogId#" >
		<cfoutput>
			<cftry>
				<cfquery name="getItemInfo" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT 
						collection.institution_acronym,
						collection.collection_cde,
						cataloged_item.cat_num,
						specimen_part.part_name,
						specimen_part.preserve_method,
						coll_object.coll_obj_disposition
					FROM 
						deacc_item
						JOIN specimen_part ON deacc_item.collection_object_id = specimen_part.collection_object_id
						JOIN coll_object ON specimen_part.collection_object_id = coll_object.collection_object_id
						JOIN cataloged_item ON specimen_part.derived_from_cat_item = cataloged_item.collection_object_id
						JOIN collection ON cataloged_item.collection_id = collection.collection_id
					WHERE 
						deacc_item.deacc_item_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#deacc_item_id#">
				</cfquery>
				<cfquery name="ctDispo" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT coll_obj_disposition 
					FROM ctcoll_obj_disp
					ORDER BY 
						CASE 
							WHEN coll_obj_disposition = 'in collection' then 1
							ELSE 2
						END,
						coll_obj_disposition
				</cfquery>
				<cfset guid = "#getItemInfo.institution_acronym#:#getItemInfo.collection_cde#:#getItemInfo.cat_num#">
				<div class="form-row">
					<!--- provide a dialog asking if the user is sure they want to remove the part from the deaccession,
					     and a pick list of disposition values for the specimen part to be set to  --->
					<h5>Remove Part #guid# #getItemInfo.part_name# (#getItemInfo.preserve_method#) from Deaccession</h5>
					<p>Current disposition: <strong>#getItemInfo.coll_obj_disposition#</strong></p>
					<div class="col-12">
						<label for="" class="data-entry-label">Choose disposition to set part to upon removal from deaccession:</label>
						<select id="newDispositionSelect" class="data-entry-select">
							<cfset selected = "selected">
							<cfloop query="ctDispo">
								<option value="#ctDispo.coll_obj_disposition#" #selected#>#ctDispo.coll_obj_disposition#</option>
								<cfset selected = "">
							</cfloop>
						</select>
					</div>
					<div class="col-12">
						<p class="mt-2">Are you sure you want to remove this part from the deaccession?</p>
					</div>
					<div class="col-12">
						<!--- on submit, call removePartFromDeacc with the deacc_item_id and selected disposition, then close the dialog --->
						<button type="button" class="btn btn-xs btn-warning" 
							onclick="doDeaccItemRemoval();">
							Remove
						</button>
						<script>
							function closeDialogCallback() { 
								dialogId = "#dialogID#";
								$("##"+dialogId).dialog("close");
							}
							function doDeaccItemRemoval() { 
								deacc_item_id = "#deacc_item_id#";
								new_coll_obj_disposition = $("##newDispositionSelect").val();
								removePartFromDeacc(deacc_item_id,new_coll_obj_disposition,closeDialogCallback);
							}
						</script>
					</div>
				</div>
			<cfcatch>
				<cfset error_message = cfcatchToErrorMessage(cfcatch)>
				<cfset function_called = "#GetFunctionCalledName()#">
				<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
				<cfabort>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="getRemoveDeaccItemDialogContentThread" />
	<cfreturn getRemoveDeaccItemDialogContentThread.output>
</cffunction>

<!--- function removePartFromDeacc remove a part from a deaccession --->
<cffunction name="removePartFromDeacc" access="remote" returntype="any" returnformat="json">
	<cfargument name="deacc_item_id" type="numeric" required="yes">
	<cfargument name="coll_obj_disposition" type="string" required="yes">

	<cftransaction>
		<cftry>
			<cfquery name="getDeaccItem" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT collection_object_id, 
					transaction_id
				FROM deacc_item 
				WHERE deacc_item_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#deacc_item_id#">
			</cfquery>
			<cfif getDeaccItem.recordcount EQ 0>
				<cfthrow message="Could not find deaccession item with specified deacc_item_id">
			</cfif>
			<cfif getDeaccItem.recordcount GT 1>
				<cfthrow message="Multiple deaccession items found with specified deacc_item_id">
			</cfif>
			<cfset partID = getDeaccItem.collection_object_id>
			<cfset transaction_id = getDeaccItem.transaction_id>
			<!--- update the disposition of the collection object --->
			<cfquery name="upDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="upDisp_result">
				UPDATE coll_object 
				SET coll_obj_disposition = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#coll_obj_disposition#">
				where collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#partID#">
			</cfquery>
			<cfif upDisp_result.recordcount NEQ 1>
				<cfthrow message="Error updating collection object disposition to specified value [#encodeForHtml(coll_obj_disposition)#]">
			</cfif>
			<!--- delete the deacc_item record --->
			<cfquery name="deleDeaccItem" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="deleDeaccItem_result">
				DELETE FROM deacc_item 
				WHERE deacc_item_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#deacc_item_id#">
			</cfquery>
			<cfif deleDeaccItem_result.recordcount NEQ 1>
				<cfthrow message="Error deleting deaccession item record with specified deacc_item_id">
			<cfelse>
				<cfset theResult=queryNew("status, message")>
				<cfset t = queryaddrow(theResult,1)>
				<cfset t = QuerySetCell(theResult, "status", "1", 1)>
				<cfset t = QuerySetCell(theResult, "message", "deaccession item removed.", 1)>
			</cfif>
			<cftransaction action="commit">
		<cfcatch>
			<cftransaction action="rollback">
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn theResult>
</cffunction>

<!--- function updateLoanItem to update the condition, instructions, remarks, and disposition of an item in a loan.
 This is the backing function for the editable loan items grid and the edit loan item form.
 
 @param transaction_id the transaction the loan item is in
 @param part_id the part participating in the loan item, loan item is a weak enity, 
   it is keyed off of transaction_id and part_id 
   (as collection_object_id of the collection object for the part).

 TODO: use Primary Key loan_item_id instead of transaction_id and part_id to identify the loan item to update.
 
 @param condition the new value of the coll_object.condition to save.
 @param item_instructions the new value of the loan_item.item_instructions to save.
 @param loan_item_remarks the new value of the loan_item.item_remarks to save.
 @param coll_object_disposition the new value of the coll_object.coll_object_disposition to save.
 @param resolution_remarks optional, the new value of loan_item.resolution_remarks to save.
 @param item_descr the new value of loan_item.item_descr to save.
 @param loan_item_state optional, the new value of loan_item.loan_item_state to save, if 
   not provided, the value will not be changed, if provided, values of returned, consumed, or missing 
   will mark the loan item as resolved, values of in loan or unknown will clear any returned date and agent.
 @param loan_item_id optional, the loan_item_id of the loan item to update: TODO, switch to this pkey instead of transaction_id and part_id.
 @return a json structurre with status:1, or a http 500 response.
--->
<cffunction name="updateLoanItem" access="remote" returntype="any" returnformat="json">
	<cfargument name="transaction_id" type="numeric" required="yes">
	<cfargument name="part_id" type="numeric" required="yes">
	<cfargument name="condition" type="string" required="yes">
	<cfargument name="item_instructions" type="string" required="yes">
	<cfargument name="loan_item_remarks" type="string" required="yes">
	<cfargument name="coll_obj_disposition" type="string" required="yes">
	<cfargument name="resolution_remarks" type="string" required="no">
	<cfargument name="item_descr" type="string" required="yes">
	<cfargument name="loan_item_state" type="string" required="no" default="">
	<cfargument name="loan_item_id" type="string" required="no" default="">

	<cftransaction>
		<cftry>
			<cfquery name="confirmItem" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="confirmItem_result">
				select loan_item_id, loan_item_state from loan_item
				WHERE
					collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.part_id#"> AND
					transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.transaction_id#">
			</cfquery>
			<cfif confirmItem.recordcount EQ 0>
				<cfthrow message="specified collection object is not a loan item in the specified transaction">
			</cfif>
			<cfif arguments.loan_item_state is not "" AND arguments.loan_item_state NEQ confirmItem.loan_item_state>
				<cfif arguments.loan_item_state eq "returned">
					<cfquery name="setReturned" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						UPDATE loan_item 
						SET
							return_date = sysdate,
							resolution_recorded_by_agent_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.myAgentId#">
						WHERE
							loan_item_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#confirmItem.loan_item_id#">
					</cfquery>
					<!--- check if loan is open and has more than one outstanding loan item, if so, change to open-partially-returned --->
					<cfquery name="checkLoanStatus" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						SELECT 
							count(*) as outstanding_count
						FROM 
							loan_item
							join loan on loan_item.transaction_id = loan.transaction_id
						WHERE 
							loan_item.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.transaction_id#">
							AND (loan_item_state = 'in loan') 
							AND loan.loan_status = 'open'
					</cfquery>
					<cfif checkLoanStatus.outstanding_count GT 1>
						<cfquery name="setLoanPartiallyReturned" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							UPDATE loan 
							SET 
								loan_status = 'open partially returned'
							WHERE 
								transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.transaction_id#">
								and loan_status = 'open'
						</cfquery>
					</cfif>
 				<cfelseif arguments.loan_item_state eq "consumed" or arguments.loan_item_state eq "missing">
					<cfquery name="setReturned" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						UPDATE loan_item 
						SET
							return_date = null,
							resolution_recorded_by_agent_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.myAgentId#">
						WHERE
							loan_item_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#confirmItem.loan_item_id#">
					</cfquery>
				<cfelseif arguments.loan_item_state eq "in loan" or arguments.loan_item_state eq "unknown">
					<cfquery name="clearReturnData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						UPDATE loan_item 
						SET
							return_date = null,
							resolution_recorded_by_agent_id = null	
						WHERE
							loan_item_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#confirmItem.loan_item_id#">
					</cfquery>
				</cfif>
			</cfif>
			<cfquery name="upDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="upDisp_result">
				UPDATE coll_object 
				SET coll_obj_disposition = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.coll_obj_disposition#">,
					condition = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.condition#">
				WHERE collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.part_id#">
			</cfquery>
			<cfif upDisp_result.recordcount NEQ 1>
				<cfthrow message="Record not updated. #transaction_id# #part_id# #upDisp_result.sql#">
			</cfif>
			<cfquery name="upItem" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="upItem_result">
				UPDATE loan_item SET
					transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
					<cfif len(#item_instructions#) gt 0>
						,item_instructions = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.item_instructions#">
					<cfelse>
						,item_instructions = null
					</cfif>
					<cfif len(#loan_item_remarks#) gt 0>
						,loan_item_remarks = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.loan_item_remarks#">
					<cfelse>
						,loan_item_remarks = null
					</cfif>
					<cfif len(arguments.item_descr) GT 0>
						,item_descr = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.item_descr#">
					</cfif>
					<cfif len(loan_item_state) GT 0>
						,loan_item_state = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.loan_item_state#">
					</cfif>
					<cfif structKeyExists(arguments,"resolution_remarks")> 
						<cfif len(#arguments.resolution_remarks#) gt 0>
							,resolution_remarks = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.resolution_remarks#">
						<cfelse>
							,resolution_remarks = null
						</cfif>
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
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn theResult>
</cffunction>

<!--- markLoanItemResolved mark a loan item record as returned or consumed with return date of today and resolution recorded by agent as current user.
 @param loan_item_id the loan_item_id of the loan item to mark as resolved
 @param loan_item_state must be 'returned' or 'consumed' to mark item as resolved.
 @return a json structure with status:1, or a http 500 response.
--->
<cffunction name="markLoanItemResolved" access="remote" returntype="any" returnformat="json">
	<cfargument name="loan_item_id" type="numeric" required="yes">
	<cfargument name="loan_item_state" type="string" required="yes">

	<cftransaction>
		<cftry>
			<cfif NOT (arguments.loan_item_state EQ "returned" or arguments.loan_item_state EQ "consumed")>
				<cfthrow message="loan_item_state must be 'returned' or 'consumed' to mark item as resolved.">
			</cfif>
			<cfquery name="setReturned" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="setReturned_result">
				UPDATE loan_item 
				SET
					loan_item_state = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.loan_item_state#">,
					<cfif arguments.loan_item_state EQ "returned">
						return_date = sysdate,
					<cfelse>
						return_date = null,
					</cfif>
					resolution_recorded_by_agent_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.myAgentId#">
				WHERE
					loan_item_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.loan_item_id#">
			</cfquery>
			<cfset ok = false>
			<cfif setReturned_result.recordcount eq 1>
				<cfset ok = true>
			</cfif>
			<cfif ok AND arguments.loan_item_state EQ "returned">
				<!--- if loan item is not in any other open loans and is returned, change disposition to in collection --->
				<!--- find the collection object id for the loan item --->
				<cfquery name="getPartID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getPartID_result">
					SELECT collection_object_id, 
						transaction_id
					FROM loan_item
					WHERE loan_item_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.loan_item_id#">
				</cfquery>
				<cfif getPartID.recordcount EQ 0>
					<cfthrow message="could not find loan item with specified loan_item_id">
				</cfif>
				<cfset part_id = getPartID.collection_object_id>
				<!--- check if the part is in any other non-closed loans --->
				<cfquery name="checkOtherLoans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="checkOtherLoans_result">
					SELECT count(*) as open_loan_count 
					FROM loan_item
						JOIN loan on loan_item.transaction_id = loan.transaction_id
					WHERE
						loan_item.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#part_id#">
						AND loan.loan_status <> 'closed'
						AND loan.transaction_id <> <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getPartID.transaction_id#">
				</cfquery>
				<cfif checkOtherLoans.open_loan_count EQ 0>
					<!--- if not in any other open loans, update disposition to in collection if on loan --->
					<cfquery name="upDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="upDisp_result">
						UPDATE coll_object 
						SET coll_obj_disposition = 'in collection'
						WHERE collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#part_id#">
							and coll_obj_disposition = 'on loan'
					</cfquery>
				</cfif>
			</cfif>
			<cfif ok>
				<cfset theResult=queryNew("status, message")>
				<cfset t = queryaddrow(theResult,1)>
				<cfset t = QuerySetCell(theResult, "status", "1", 1)>
				<cfset t = QuerySetCell(theResult, "message", "loan item updated.", 1)>
			<cfelse>
				<cfthrow message="Record not updated. other than one record affected.">
			</cfif>
			<cftransaction action="commit">
		<cfcatch>
			<cftransaction action="rollback">
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
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
			<cfquery name="confirmItem" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="confirmItem_result">
				select * from loan_item
				WHERE
					collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#part_id#"> AND
					transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
			</cfquery>
			<cfif confirmItem.recordcount EQ 0>
				<cfthrow message="specified collection object is not a loan item in the specified transaction">
			</cfif>
			<cfquery name="upDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="upDisp_result">
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
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
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
		<cfquery name="getLoanItemsQuery" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getLoanItemsQuery_result" timeout="#Application.query_timeout#">
		SELECT 
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
			loan_item.loan_item_id,
			loan_item_remarks,
			reconciled_by_person_id,
			MCZBASE.getPreferredAgentName(reconciled_by_person_id) as reconciled_by_agent,
			to_char(reconciled_date,'YYYY-MM-DD') reconciled_date,
			to_char(loan_item.return_date,'YYYY-MM-DD') return_date,
			MCZBASE.getPreferredAgentName(loan_item.resolution_recorded_by_agent_id) as resolution_recorded_by_agent,
			loan_item.resolution_recorded_by_agent_id,
			loan_item.resolution_remarks,
			loan_item.loan_item_state,
			coll_obj_disposition,
			coll_obj_cont_hist.container_id,
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
			MCZBASE.get_storage_parentage(MCZBASE.get_previous_container_id(coll_obj_cont_hist.container_id)) as previous_location,
			loan_number,
			specimen_part.collection_object_id as part_id,
			concatSingleOtherId(cataloged_item.collection_object_id,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.CustomOtherIdentifier#">) AS customid,
			cataloged_item.collection_object_id as collection_object_id,
			'MCZ:' || collection.collection_cde || ':' || cat_num as guid,
			sovereign_nation
		from 
			loan
			left join loan_item on loan.transaction_id = loan_item.transaction_id
			join specimen_part on loan_item.collection_object_id = specimen_part.collection_object_id
			left join coll_obj_cont_hist on specimen_part.collection_object_id = coll_obj_cont_hist.collection_object_id 
				and coll_obj_cont_hist.current_container_fg = 1
			join cataloged_item on specimen_part.derived_from_cat_item = cataloged_item.collection_object_id 
			join coll_object on specimen_part.collection_object_id = coll_object.collection_object_id 
			join collection on cataloged_item.collection_id=collection.collection_id 
			join collecting_event on cataloged_item.collecting_event_id = collecting_event.collecting_event_id
			join locality on collecting_event.locality_id = locality.locality_id
		WHERE
			loan_item.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#" >
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
		<cfset error_message = cfcatchToErrorMessage(cfcatch)>
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
				<cfquery name="ctDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						select coll_obj_disposition from ctcoll_obj_disp 
				</cfquery>
				<cfquery name="lookupDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
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
						if (new_disposition!='in loan') { 
							$("##removeItemButton").removeAttr("disabled");
						}
					}
				</script>
				<cfquery name="getLoanItemDetails" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getLoanItemsQuery_result">
					select 
						item_descr
					from 
						loan_item
					WHERE
						loan_item.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#" >
						AND loan_item.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#part_id#">
				</cfquery>
				<h2 class="h3">Remove item #getLoanItemDetails.item_descr# from loan.</h2>
				<!--- see if it's a subsample --->
				<cfquery name="isSSP" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					select SAMPLED_FROM_OBJ_ID 
					from specimen_part 
					where collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#part_id#">
				</cfquery>
				<cfset mustChangeDisposition=false>
				<cfif #isSSP.SAMPLED_FROM_OBJ_ID# gt 0>
					<cfif onLoan>
						<cfset mustChangeDisposition=true>
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
						<cfset mustChangeDisposition=true>
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
				<script>
					function closeRemoveItemDialog() {
						$("##removeItemDialog").dialog("close"); 
					}
				</script>
				<cfif mustChangeDisposition>
					<cfset disabled="disabled">
				<cfelse>
					<cfset disabled="">
				</cfif>
				<button id="removeItemButton" class="btn btn-xs btn-warning" value="Remove Item from Loan" #disabled#
					onclick="removeLoanItemFromLoan(#part_id#, #transaction_id#,'updateStatus',closeRemoveItemDialog); ">Remove Item from Loan</button>
				<cfif #isSSP.SAMPLED_FROM_OBJ_ID# gt 0>
					<!--- deleting subsample not implemented, departs from MCZ practice --->
					<!---
					<p />
					<button class="btn btn-xs btn-danger"
						value="Delete Subsample From Database" disabled
						onclick="alert('not implemented');">Delete Subsample From Database</button> 
					--->
					<!--- older code for onclick: cC.action.value='killSS'; submit();"/> --->
				</cfif>
				<p />
			</cfoutput>
		<cfcatch>
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
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
			<cfquery name="deleLoanItem" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="deleLoanItem_result">
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
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
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
 @param append_part_condition if true append the part condition to the loan item description, optional default false.
  --->
<cffunction name="addPartToLoan" access="remote" returntype="any" returnformat="json">
	<cfargument name="transaction_id" type="numeric" required="yes">
	<cfargument name="part_id" type="numeric" required="yes">
	<cfargument name="remark" type="string" required="yes">
	<cfargument name="instructions" type="string" required="yes">
	<cfargument name="subsample" type="numeric" required="yes">
	<cfargument name="append_part_condtion" type="string" required="no" default="false">
	
	<cftransaction>
		<cftry>
			<cfquery name="checkIsLoan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT count(transaction_id) as ct
				FROM loan
				WHERE
					transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
			</cfquery>
			<cfif checkIsLoan.ct EQ 0>
				<cfthrow message="Provided transaction_id is not for a loan.">
			</cfif>
			<cfquery name="getLoan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT loan_number
				FROM loan
				WHERE
					transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
			</cfquery>
			<cfquery name="meta" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT cataloged_item.collection_object_id,
					cat_num,
					collection,part_name, 
					specimen_part.preserve_method,
					coll_object.condition
				FROM
					cataloged_item 
					LEFT JOIN collection on cataloged_item.collection_id=collection.collection_id
					LEFT JOIN specimen_part on cataloged_item.collection_object_id=specimen_part.derived_from_cat_item
					left join coll_object on specimen_part.collection_object_id = coll_object.collection_object_id
				WHERE
					specimen_part.collection_object_id= <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#part_id#">
			</cfquery>
			<cfset condition_to_append = "">
			<cfif isDefined("arguments.append_part_condition") AND arguments.append_part_condition EQ "true">
				<cfset condition_to_append = " #meta.condition#">
			</cfif>		
			<cfif subsample IS 1 >
				<!--- create a subsample and add it as an item to the loan --->
				<cfquery name="parentData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
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
				<cfquery name="n" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					select sq_collection_object_id.nextval n from dual
				</cfquery>
				<cfloop query="n">
					<cfset subsampleCollObjectID = n.n>
				</cfloop>
				<cfquery name="newCollObj" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
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
				<cfquery name="decrementParentLotCount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE coll_object 
					SET LOT_COUNT = LOT_COUNT -1,
						LAST_EDITED_PERSON_ID = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.myAgentId#">,
						LAST_EDIT_DATE = sysdate
					WHERE COLLECTION_OBJECT_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#part_id#">
						and LOT_COUNT > 1
				</cfquery>
				<cfquery name="newPart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
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
				<cfquery name="newRemark" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					INSERT INTO coll_object_remark (
						COLLECTION_OBJECT_ID,
 						COLL_OBJECT_REMARKS 
					) VALUES (
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#subsampleCollObjectID#">,
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="Subsample For Loan #getLoan.loan_number#">
					)
				</cfquery>
			</cfif><!--- End subsample --->

			<cfquery name="addLoanItem" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="addLoanItem_result">
				INSERT INTO LOAN_ITEM (
					TRANSACTION_ID
					,COLLECTION_OBJECT_ID
					,RECONCILED_BY_PERSON_ID
					,RECONCILED_DATE
					,ITEM_DESCR
					,loan_item_state
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
					,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#meta.collection# #meta.cat_num# #meta.part_name# (#meta.preserve_method#)#condition_to_append#">
					,'in loan'
					<cfif len(#instructions#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#instructions#">
					</cfif>
					<cfif len(#remark#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#remark#">
					</cfif>
				)
			</cfquery>
			<!--- Obtain loan_item_id for insert and return it in the result. --->
			<cfset rowid = addLoanItem_result.generatedkey>
			<cfif len(rowid) EQ 0>
				<cfthrow message="Could not obtain rowid of inserted loan item.">
			</cfif>
			<cfquery name="getLoanItemID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT loan_item_id
				FROM loan_item
				WHERE
					ROWIDTOCHAR(rowid) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#rowid#">
			</cfquery>
			<cfif getLoanItemID.recordcount NEQ 1>
				<cfthrow message="Could not obtain loan_item_id of inserted loan item.">
			</cfif>
			<cfif subsample IS 1 >
				<cfset targetObject = subsampleCollObjectId>
			<cfelse>
				<cfset targetObject = part_id>
			</cfif>
			<cfquery name="setDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE coll_object 
				SET coll_obj_disposition = 'on loan'
				WHERE 
					collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#targetObject#">
			</cfquery>
			<cfset theResult=queryNew("status, loan_item_id, message, subsample")>
			<cfset t = queryaddrow(theResult,1)>
			<cfset t = QuerySetCell(theResult, "status", "1", 1)>
			<cfset t = QuerySetCell(theResult, "loan_item_id", "#getLoanItemId.loan_item_id#", 1)>
			<cfset t = QuerySetCell(theResult, "message", "item added to loan.", 1)>
			<cfif subsample IS 1 >
				<cfset t = QuerySetCell(theResult, "subsample", "#subsampleCollObjectId#", 1)>
			<cfelse>
				<cfset t = QuerySetCell(theResult, "subsample", "", 1)>
			</cfif>
			<cftransaction action="commit">
		<cfcatch>
			<cftransaction action="rollback">
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
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
				<cfquery name="ctDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						select coll_obj_disposition from ctcoll_obj_disp 
				</cfquery>
				<cfif isdefined("guid") AND len(guid) GT 0>
					<cfquery name="lookupCollObjId" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						select collection_object_id 
						from flat
						where guid = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#guid#">
					</cfquery>
					<cfset collection_object_id = lookupCollObjId.collection_object_id>
				</cfif>
				<cfquery name="lookupCatalogedItem" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
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
					<cfquery name="lookupParts" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
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
										<cfif coll_obj_disposition EQ "unknown">
											<cfset dispositionClasses = "">
										<cfelse>
											<cfset dispositionClasses="font-weight-bold text-danger">
										</cfif>
										<div class="col-12 #dispositionClasses#">
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
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cfthread>
	<cfthread action="join" name="getAddLoanItemHtmlThread" />
	<cfreturn getAddLoanItemHtmlThread.output>
</cffunction>


<!--- obtain an html block to populate dialog for editing a loan item --->
<cffunction name="getLoanItemDialogHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="loan_item_id" type="string" required="yes">

	<cfthread name="getRemoveLoanItemHtmlThread" loan_item_id="#arguments.loan_item_id#">
		<cftry>
			<cfoutput>
				<cfquery name="ctDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						SELECT coll_obj_disposition 
						FROM ctcoll_obj_disp 
						ORDER BY coll_obj_disposition
				</cfquery>
				<cfquery name="ctLoanItemState" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						SELECT loan_item_state 
						FROM ctloan_item_state
						ORDER BY loan_item_state
				</cfquery>
				<cfquery name="lookupItem" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT 
						loan.loan_number,
						loan.transaction_id,
						loan.loan_type,
						loan.loan_status,
						collection.institution_acronym,
						cataloged_item.collection_cde, 
						cataloged_item.cat_num,
						coll_object.coll_obj_disposition,
						coll_object.condition,
						specimen_part.part_name,
						specimen_part.preserve_method,
						loan_item.loan_item_id,
						loan_item.collection_object_id part_id,
						loan_item.reconciled_by_person_id,
						MCZBASE.getPreferredAgentName(loan_item.reconciled_by_person_id) as reconciled_by_agent,
						to_char(loan_item.reconciled_date,'yyyy-mm-dd') reconciled_date,
						loan_item.item_descr,
						loan_item.item_instructions,
						loan_item.loan_item_remarks,
						to_char(loan_item.created_date, 'yyyy-mm-dd') created_date, 
						loan_item.created_by_agent_id,
						MCZBASE.getPreferredAgentName(loan_item.created_by_agent_id) as created_by_agent,
						loan_item.resolution_recorded_by_agent_id,
						MCZBASE.getPreferredAgentName(loan_item.resolution_recorded_by_agent_id) as resolution_recorded_by_agent,
						loan_item.resolution_remarks,
						loan_item.loan_item_state,
						to_char(loan_item.return_date,'yyyy-mm-dd') as return_date,
						specimen_part.sampled_from_obj_id,
						case when specimen_part.sampled_from_obj_id is not null then 'yes' else 'no' end as is_subsample,
						sampledFromCatItem.cat_num as sampled_from_cat_num,
						sampledFromCatItem.collection_cde as sampled_from_collection_cde,
						sampledFromPart.part_name as sampled_from_part_name,
						sampledFromPart.preserve_method as sampled_from_preserve_method
					FROM 
						loan_item
						join specimen_part on loan_item.collection_object_id = specimen_part.collection_object_id
						join coll_object on specimen_part.collection_object_id = coll_object.collection_object_id
						join cataloged_item on specimen_part.derived_from_cat_item = cataloged_item.collection_object_id
						join collection on cataloged_item.collection_id = collection.collection_id
						join loan on loan_item.transaction_id = loan.transaction_id
						left join coll_object sampledFrom on specimen_part.sampled_from_obj_id = sampledFrom.collection_object_id
						left join specimen_part sampledFromPart on sampledFrom.collection_object_id = sampledFromPart.collection_object_id
						left join cataloged_item sampledFromCatItem on sampledFromPart.derived_from_cat_item = sampledFromCatItem.collection_object_id
					WHERE loan_item.loan_item_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#loan_item_id#">
				</cfquery>
				<cfif lookupItem.recordcount NEQ 1>
					<cfthrow message="Unable to lookup loan item by loan_item_id=#encodeForHtml(loan_item_id)#">
				</cfif>
				<cfloop query="lookupItem">
					<cfset guid="#institution_acronym#:#collection_cde#:#cat_num#">
					<div id="loanItemEditorDiv">
						<div class="container-fluid">
							<div class="row">
								<div class="col-12">
									<div class="add-form mt-2">
										<div class="add-form-header pt-1 px-2">
											<h2 class="h2">
												Loan Item <a href="/guid/#guid#" target="_blank">#guid#</a> #part_name# (#preserve_method#) in #loan_number# #loan_type# #loan_status#
												<div class="smaller">[internal part collection_object_id: #lookupItem.part_id#]</div>
											</h2>
											<cfif is_subsample EQ "yes">
												<h3 class="h4">Loaned Part is a subsample of #sampled_from_part_name# (#sampled_from_preserve_method#)</h3>
											</cfif>
											<!--- lookup material sample id from guid_our_thing table --->
											<cfquery name="getMaterialSampleID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
												SELECT guid_our_thing_id, assembled_identifier, assembled_resolvable, local_identifier, internal_fg
												FROM guid_our_thing
												WHERE guid_is_a = 'materialSampleID'
											 		AND sp_collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#lookupItem.part_id#">
												ORDER BY internal_fg DESC, timestamp_created DESC
											</cfquery>
											<cfif getMaterialSampleID.recordcount GT 0>
												<div class="h4 mt-2">
													<cfloop query="getMaterialSampleID">
														<span class="font-italic">materialSampleID:</span> 
															<a href="#assembled_resolvable#" target="_blank">#assembled_identifier#</a>
															<cfif internal_fg EQ "1" AND left(assembled_identifier,9) EQ "urn:uuid:">
																<a href="/uuid/#local_identifier#/json" target="_blank" title="View RDF representation of this dwc:MaterialSample in a JSON-LD serialization">
																	<img src="/shared/images/json-ld-data-24.png" alt="JSON-LD">
																</a>
															</cfif>
														</span>
													</cfloop>
												</div>
											</cfif>
											<h3 class="h4">
												Added to Loan by <a href="/agents/Agent.cfm?agent_id=#reconciled_by_person_id#" target="_blank">#reconciled_by_agent#</a>
												on #reconciled_date#.  
												<cfif len(created_by_agent_id) GT 0 AND created_by_agent_id NEQ reconciled_by_person_id>
													Loan item record created by <a href="/agents/Agent.cfm?agent_id=#created_by_agent_id#" target="_blank">#created_by_agent#</a>
													on #loan_item.created_date#.
												</cfif>
											</h3>
										</div>
										<div class="card-body">
											<form name="editLoanItemForm" id="editLoanItemForm" class="mb-0">
												<input type="hidden" name="loan_item_id" value="#lookupItem.loan_item_id#">
												<input type="hidden" name="part_id" value="#lookupItem.part_id#">
												<input type="hidden" name="transaction_id" value="#lookupItem.transaction_id#">
												<input type="hidden" name="method" value="updateLoanItem">
												<div class="row mx-0 py-2">
													<div class="col-12 col-md-6 px-1">
														<cfif len(lookupItem.loan_item_state) EQ 0>
															<cfset state="">
														<cfelse>
															<cfset state="(#lookupItem.loan_item_state#)">
														</cfif>
														<label class="data-entry-label">Loan Item State #state#</label>
														<select name="loan_item_state" class="data-entry-select reqdClr" required>
															<option value=""></option>
															<cfloop query="ctLoanItemState">
																<cfset selected = "">
																<cfif ctLoanItemState.loan_item_state EQ lookupItem.loan_item_state>
																	<cfset selected="selected='selected'">
																</cfif>
																<option value="#ctLoanItemState.loan_item_state#" #selected#>
																	#ctLoanItemState.loan_item_state#
																</option>
															</cfloop>
														</select>
													</div>
													<div class="col-12 col-md-6 px-1">
														<label class="data-entry-label">Loan Item Description</label>
														<input type="text" name="item_descr" value="#encodeForHtml(lookupItem.item_descr)#" class="data-entry-input">
													</div>
													<div class="col-12 px-1">
														<label class="data-entry-label" for="item_instructions">Loan Item Instructions</label> 
														<input type="text" name="item_instructions" id="item_instructions" value="#encodeForHtml(lookupItem.item_instructions)#" class="data-entry-input">
													</div>
													<div class="col-12 px-1">
														<label class="data-entry-label" for="loan_item_remarks">Loan Item Remarks</label>
														<input type="text" name="loan_item_remarks" id="loan_item_remarks" value="#encodeForHtml(lookupItem.loan_item_remarks)#" class="data-entry-input">
													</div>
													<div class="col-12 px-1">
														<label class="data-entry-label" for="resolution_remarks">Resolution Remarks</label>
														<input type="text" name="resolution_remarks" id="resolution_remarks" value="#encodeForHtml(lookupItem.resolution_remarks)#" class="data-entry-input">
													</div>
													<div class="col-12 col-md-6 px-1">
														<label class="data-entry-label">Part Condition (#lookupItem.condition#)</label>
														<input type="text" name="condition" value="#encodeForHtml(lookupItem.condition)#" class="data-entry-input">
													</div>
													<div class="col-12 col-md-6 px-1">
														<label class="data-entry-label">Part Disposition (#lookupItem.coll_obj_disposition#)</label>
														<select name="coll_obj_disposition" class="data-entry-select reqdClr" required>
															<option value=""></option>
															<cfloop query="ctDisp">
																<cfset selected = "">
																<cfif ctDisp.coll_obj_disposition EQ lookupItem.coll_obj_disposition>
																	<cfset selected="selected='selected'">
																</cfif>
																<option value="#ctDisp.coll_obj_disposition#" #selected#>
																	#ctDisp.coll_obj_disposition#
																</option>
															</cfloop>
														</select>
													</div>
													<div class="col-12 px-1">
														<h3 class="h4 mt-3">
															<cfif resolution_recorded_by_agent_id NEQ "">
																Resolution recorded by 
																<a href="/agents/Agent.cfm?agent_id=#resolution_recorded_by_agent_id#" target="_blank">
																	#resolution_recorded_by_agent#
																</a>
																<cfif len(return_date) GT 0>
																	returned on #return_date#.
																</cfif>
															</cfif>
														</h3>
													</div>
													<div class="col-12 px-1">
														<button type="button" class="btn btn-primary btn-sm" 
															onclick="submitLoanItemEditForm('editLoanItemForm','loanItemEditStatusDiv');">
															Save
														</button>
														<output id="loanItemEditFormStatus">&nbsp;</output>
														<script>
															$(document).ready(function(){
																$("##editLoanItemForm").submit(function(evt){
																	evt.preventDefault();
																	submitLoanItemEditForm('editLoanItemForm','loanItemEditStatusDiv');
																});
															});
															function submitLoanItemEditForm(formId, statusDivId){
																setFeedbackControlState("loanItemEditStatusDiv","saving")
																var formData = $("##"+formId).serialize();
																$.ajax({
																	type: "POST",
																	url: "/transactions/component/itemFunctions.cfc",
																	data: formData,
																	dataType: "json",
																	success: function(response){
																		console.log(response);
																		var status = response.DATA[0][response.COLUMNS.indexOf("STATUS")];
																		if (status == "1") {
																			setFeedbackControlState("loanItemEditStatusDiv","saved")
																		} else {
																			setFeedbackControlState("loanItemEditStatusDiv","error")
																		}
																	},
																	error: function (jqXHR, status, message) {
																		handleFail(jqXHR,status,message,"updating loan item");
																	}
																});
															}
														</script>
													</div>
												</div>
											</form>
											<div id="loanItemEditStatusDiv"></div>
										</div>
									</div>
								</div>
								<div class="col-12">
									<ul>
										<!---  lookup accession --->
										<cfquery name="lookupAccession" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
											SELECT 
												accn.transaction_id,
												accn.accn_number,
												accn.accn_status,
												accn.accn_type,
												to_char(accn.received_date,'yyyy-mm-dd') as received_date, 
												concattransagent(accn.transaction_id,'received from') received_from
											FROM 
												specimen_part
												join cataloged_item on specimen_part.derived_from_cat_item = cataloged_item.collection_object_id
												join accn on cataloged_item.accn_id = accn.transaction_id
											WHERE 
												specimen_part.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#lookupItem.part_id#">
										</cfquery>
										<cfloop query="lookupAccession">
											<!--- should be one and only one accession --->
											<li>
												Accession:
												<a href="/transactions/Accession.cfm?action=edit&transaction_id=#lookupAccession.transaction_id#" target="_blank">#lookupAccession.accn_number#</a>
												#lookupAccession.accn_type# (#lookupAccession.accn_status#).
												Received: #lookupAccession.received_date#  
												From: #lookupAccession.received_from#.
											</li>
											<!--- lookup any permits associated with this accession that have use restrictions or required benefits --->
											<cfquery name="accnLimitations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
												SELECT 
													case when length(permit.restriction_summary) > 30 then substr(permit.restriction_summary,1,30) || '...' else permit.restriction_summary end as restriction_summary,
													permit.specific_type,
													permit.permit_num,
													permit.permit_title,
													permit.permit_id
												FROM permit_trans 
													join permit on permit_trans.permit_id = permit.permit_id
												WHERE 
													permit_trans.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#lookupAccession.transaction_id#">
													and permit.restriction_summary IS NOT NULL
											</cfquery>
											<cfquery name="accnBenefits" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
												SELECT 
													case when length(permit.benefits_summary) > 30 then substr(permit.benefits_summary,1,30) || '...' else permit.benefits_summary end as benefits_summary,
													case when length(permit.internal_benefits_summary) > 30 then substr(permit.internal_benefits_summary,1,30) || '...' else permit.internal_benefits_summary end as internal_benefits_summary,
													permit.specific_type,
													permit.permit_num,
													permit.permit_title,
													permit.permit_id
												FROM permit_trans 
													join permit on permit_trans.permit_id = permit.permit_id
												WHERE 
													permit_trans.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#lookupAccession.transaction_id#">
													AND (permit.benefits_summary IS NOT NULL OR permit.internal_benefits_summary IS NOT NULL)	
											</cfquery>
											<cfif accnLimitations.recordcount GT 0 or accnBenefits.recordcount GT 0>
												<li class="list-group-item py-0">
													<cfif accnLimitations.recordcount GT 0>
														<span class="font-weight-lessbold mb-0 d-inline-block">Permits with restrictions on use:</span>
														<ul class="pl-0">
															<cfloop query="accnLimitations">
																<li class="small90">
																	<a href="/transactions/Permit.cfm?action=view&permit_id=#accnLimitations.permit_id#" target="_blank">
																		#accnLimitations.specific_type# #accnLimitations.permit_num#
																	</a> 
																	#accnLimitations.restriction_summary#
																</li>
															</cfloop>
														</ul>
													</cfif>
													<cfif accnBenefits.recordcount GT 0>
														<span class="font-weight-lessbold mb-0 d-inline-block">Permits with required benefits:</span>
														<ul class="pl-0">
															<cfloop query="accnBenefits">
																<li class="small90">
																	<a href="/transactions/Permit.cfm?action=view&permit_id=#accnBenefits.permit_id#" target="_blank">
																		#accnBenefits.specific_type# #accnBenefits.permit_num#
																	</a> 
																	<cfif len(accnBenefits.benefits_summary) gt 0>
																		<strong>Apply to All:</strong> #accnBenefits.benefits_summary#
																	</cfif>
																	<cfif len(accnBenefits.internal_benefits_summary) gt 0>
																		<cfif len(accnBenefits.benefits_summary) gt 0>, </cfif>
																		<strong>Apply to Harvard:</strong> #accnBenefits.internal_benefits_summary#
																	</cfif>
																</li>
															</cfloop>
														</ul>
													</cfif>
												</li>
											</cfif>
										</cfloop>
									
										<!--- lookup other loans that this part is on, highlight any that are open --->
										<cfquery name="lookupOtherLoans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
											SELECT 
												loan_item.loan_item_state,
												loan.loan_number,
												loan.loan_type,
												loan.loan_status,
												loan.transaction_id,
												to_char(loan.return_due_date,'yyyy-mm-dd') as return_due_date,
												to_char(loan.closed_date,'yyyy-mm-dd') as closed_date
											FROM 
												loan_item
												join loan on loan_item.transaction_id = loan.transaction_id
											WHERE 
												loan_item.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#lookupItem.part_id#">
												and loan_item.loan_item_id <> <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#lookupItem.loan_item_id#">
										</cfquery>
										<cfif lookupOtherLoans.recordcount EQ 0>
												<li>This part is not currently in any other loans.</li>
										<cfelse>
											<cfloop query="lookupOtherLoans">
												<cfif loan_status EQ "open">
													<li>
														This part is also currently in open loan 
														<a href="/transactions/Loan.cfm?transaction_id=#transaction_id#" target="_blank">#loan_number#</a>
														#loan_type# (#loan_status#) due #return_due_date#.
														<cfif len(loan_item_state) GT 0>With loan item state #loan_item_state#.</cfif>
													</li>
												<cfelse>
													<li>
														This part is also in loan 
														<a href="/loans/Loan.cfm?transaction_id=#transaction_id#" target="_blank"> #loan_number# </a>
														#loan_type# (#loan_status#) 
														<cfif len(closed_date) GT 0 and loan_status EQ 'closed'>on #closed_date#</cfif>.
														<cfif len(loan_item_state) GT 0>With loan item state #loan_item_state#.</cfif>
													</li>
												</cfif>
											</cfloop>
										</cfif>
									</ul>
								</div>
							</div>
						</div>
				</cfloop>
			</cfoutput>
		<cfcatch>
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cfthread>
	<cfthread action="join" name="getRemoveLoanItemHtmlThread" />
	<cfreturn getRemoveLoanItemHtmlThread.output>
</cffunction>

<!--- getDispositionsList obtain an html list of distinct values of dispositions and loan item 
  states for items in a loan.
  @param transaction_id the id of the loan transaction for which to obtain the list of dispositions
  @return an html unordered list of dispositions and loan item states for items in the loan or an http 500 error if an error occurs.
--->
<cffunction name="getDispositionsList" returntype="string" access="remote" returnformat="plain">
	<cfargument name="transaction_id" type="string" required="yes">
	<cfthread name="getDispositionListThread" transaction_id="#arguments.transaction_id#">
		<cftry>
			<cfoutput>
				<cfquery name="countDispositions" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT count(*) as ct, 
						coll_obj_disposition, 
						nvl(loan_item.loan_item_state,'not set') as loan_item_state
					FROM loan_item 
						join coll_object on loan_item.collection_object_id = coll_object.collection_object_id
					WHERE 
						loan_item.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#" >
					GROUP BY coll_obj_disposition, loan_item.loan_item_state
					ORDER BY coll_obj_disposition, loan_item.loan_item_state
				</cfquery>
				<cfif countDispositions.recordcount EQ 0 >
					<span class="var-display">None</span>
				<cfelse>
					<ul>
						<cfloop query="countDispositions">
							<li>Part Dispostion: #encodeforHtml(coll_obj_disposition)#; Loan Item State: #encodeforHtml(loan_item_state)# (#ct#)</li>
						</cfloop>
					</ul>
				</cfif>
			</cfoutput>
		<cfcatch>
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cfthread>
	<cfthread action="join" name="getDispositionListThread" />
	<cfreturn getDispositionListThread.output>
</cffunction>

<cffunction name="getDispositionsTable" returntype="string" access="remote" returnformat="plain">
	<cfargument name="transaction_id" type="string" required="yes">
	<cfthread name="getDispositionTableThread" transaction_id="#arguments.transaction_id#">
		<cftry>
			<cfoutput>
				<cfquery name="getDispositions" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					select count(loan_item.collection_object_id) as pcount, coll_obj_disposition, deacc_number, deacc_type, deacc_status
					from loan 
						left join loan_item on loan.transaction_id = loan_item.transaction_id
						left join coll_object on loan_item.collection_object_id = coll_object.collection_object_id
						left join deacc_item on loan_item.collection_object_id = deacc_item.collection_object_id
						left join deaccession on deacc_item.transaction_id = deaccession.transaction_id
					where loan.transaction_id = <cfqueryparam CFSQLType="CF_SQL_DECIMAL" value="#transaction_id#">
						and coll_obj_disposition is not null
					group by coll_obj_disposition, deacc_number, deacc_type, deacc_status
				</cfquery>
				<cfif getDispositions.recordcount EQ 0 >
					<h4>There are no attached collection objects.</h4>
				<cfelse>
					<table class="table table-responsive">
						<thead class="thead-light">
							<tr>
								<th>Parts</th>
								<th>Disposition</th>
								<th>Deaccession</th>
							</tr>
						</thead>
						<tbody>
							<cfloop query="getDispositions">
								<tr>
									<cfif len(trim(getDispositions.deacc_number)) GT 0>
										<td>#pcount#</td>
										<td>#coll_obj_disposition#</td>
										<td><a href="/Transactions.cfm?action=findDeaccessions&execute=true&deacc_number=#encodeForURL(deacc_number)#">#deacc_number# (#deacc_status#)</a></td>
									<cfelse>
										<td>#pcount#</td>
										<td>#coll_obj_disposition#</td>
										<td>Not in a Deaccession</td>
									</cfif>
								</tr>
							</cfloop>
						</tbody>
					</table>
				</cfif>
			</cfoutput>
		<cfcatch>
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cfthread>
	<cfthread action="join" name="getDispositionTableThread" />
	<cfreturn getDispositionTableThread.output>
</cffunction>

<cffunction name="getPreservationsList" returntype="string" access="remote" returnformat="plain">
	<cfargument name="transaction_id" type="string" required="yes">
	<cfthread name="getPreservationListThread" transaction_id="#arguments.transaction_id#">
		<cftry>
			<cfoutput>
				<cfquery name="countPreserveMethods" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT count(*) as ct, specimen_part.preserve_method
					FROM loan_item 
						join specimen_part on loan_item.collection_object_id = specimen_part.collection_object_id
					WHERE 
						loan_item.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#" >
					GROUP BY specimen_part.preserve_method
					ORDER BY specimen_part.preserve_method
				</cfquery>
				<cfif countPreserveMethods.recordcount EQ 0>
					<span class="var-display">None</span>
				<cfelse>
					<ul>
						<cfloop query="countPreserveMethods">
							<li>#encodeforHtml(preserve_method)# (#ct#)</li>
						</cfloop>
					</ul>
				</cfif>
			</cfoutput>
		<cfcatch>
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cfthread>
	<cfthread action="join" name="getPreservationListThread" />
	<cfreturn getPreservationListThread.output>
</cffunction>

<cffunction name="getCountriesList" returntype="string" access="remote" returnformat="plain">
	<cfargument name="transaction_id" type="string" required="yes">
	<cfthread name="getCountriesListThread" transaction_id="#arguments.transaction_id#">
		<cftry>
			<cfoutput>
				<cfset sep="">
				<cfquery name="getSovereignNations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT count(*) as ct, sovereign_nation
					FROM loan_item 
						left join specimen_part on loan_item.collection_object_id = specimen_part.collection_object_id
						left join cataloged_item on specimen_part.derived_from_cat_item = cataloged_item.collection_object_id
						left join collecting_event on cataloged_item.collecting_event_id = collecting_event.collecting_event_id
						left join locality on collecting_event.locality_id = locality.locality_id
					WHERE 
						loan_item.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#" >
					GROUP BY sovereign_nation
				</cfquery>
				<cfif getSovereignNations.recordcount EQ 0>
					<span class="var-display">None</span>
				<cfelse>
					<cfloop query="getSovereignNations">
						<cfif len(sovereign_nation) eq 0><cfset sovereign_nation = '[no value set]'></cfif>
						<span>#sep##encodeforHtml(sovereign_nation)#&nbsp;(#ct#)</span>
						<cfset sep="; ">
					</cfloop>
				</cfif>
			</cfoutput>
		<cfcatch>
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cfthread>
	<cfthread action="join" name="getCountriesListThread" />
	<cfreturn getCountriesListThread.output>
</cffunction>

<!--- obtain an html summary block for a loan intent is to go on a page for reviewing/adding items to a loan.
 @param transaction_id the id of the loan for which to obtain the summary.
 @param show_buttons, one of review, add, both, none, optional, default review, determines which buttons are shown.
 @return an html block summarizing the loan or an http 500 error if an error occurs.
--->
<cffunction name="getLoanSummaryHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="transaction_id" type="string" required="yes">
	<cfargument name="show_buttons" type="string" required="no" default="review">

	<cfif not isDefined("arguments.show_buttons") OR len(arguments.show_buttons) EQ 0>
		<cfset show_buttons = "review">
	<cfelse>
		<cfset show_buttons = arguments.show_buttons>
	</cfif>

	<cfthread name="getLoanSummaryThread" transaction_id="#arguments.transaction_id#" show_buttons="#show_buttons#">
		<cftry>
			<cfoutput>
				<!--- lookup loan number and information about loan --->
				<cfquery name="getLoan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT l.loan_number, 
						c.collection_cde, 
						c.collection,
						l.loan_type, 
						l.loan_status, 
						to_char(l.return_due_date,'yyyy-mm-dd') as return_due_date, 
						to_char(l.closed_date,'yyyy-mm-dd') as closed_date,
						l.loan_instructions,
						trans.nature_of_material,
						to_char(trans.trans_date,'yyyy-mm-dd') as loan_date,
						concattransagent(trans.transaction_id,'recipient institution') recipient_institution
					FROM 
						trans
						join collection c on trans.collection_id = c.collection_id
						join loan l on trans.transaction_id = l.transaction_id
					WHERE trans.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#" >
				</cfquery>
				<cfif getLoan.recordcount NEQ 1>
					<cfthrow message="No loan found for transaction_id=[#encodeForHtml(transaction_id)#]">
				</cfif>
				<cfloop query="getLoan">
					<h2 class="h3"><a href="/transactions/Loan.cfm?action=editLoan&transaction_id=#encodeForUrl(transaction_id)#" target="_blank">#getLoan.loan_number#</a></h2>
					<div>#loan_type# #loan_status# #loan_date# to #recipient_institution# due #return_due_date#</div>
					<div>#nature_of_material#</div>
					<cfif show_buttons NEQ "none">
						<div>
							<cfif show_buttons EQ "review" OR show_buttons EQ "both">
								<a href="/transactions/reviewLoanItems.cfm?transaction_id=#encodeForUrl(transaction_id)#" target="_blank" class="btn btn-xs btn-secondary">Review Loan Items</a>
							</cfif>
							<cfif show_buttons EQ "add" OR show_buttons EQ "both">
								<a href="/Specimens.cfm?target_loan_id=#encodeForUrl(transaction_id)#" target="_blank" class="btn btn-xs btn-secondary">Add Items To Loan</a>
							</cfif>
						</div>
					</cfif>
				</cfloop>
			</cfoutput>
		<cfcatch>
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cfthread>
	<cfthread action="join" name="getLoanSummaryThread" />
	<cfreturn getLoanSummaryThread.output>
</cffunction>

<!---  getDeaccessionSummaryHtml obtain an html summary block for a deaccession
 intent is to go on a page for reviewing/adding items to a deacession.
 @param transaction_id the id of the deaccession for which to obtain the summary.
 @param show_buttons, one of review, add, both, none, optional, default review, determines which buttons are shown.
 @return an html block summarizing the deaccession or an http 500 error if an error occurs.
--->
<cffunction name="getDeaccessionSummaryHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="transaction_id" type="string" required="yes">
	<cfargument name="show_buttons" type="string" required="no" default="review">

	<cfif not isDefined("arguments.show_buttons") OR len(arguments.show_buttons) EQ 0>
		<cfset show_buttons = "review">
	<cfelse>
		<cfset show_buttons = arguments.show_buttons>
	</cfif>

	<cfthread name="getDeaccSummaryThread" transaction_id="#arguments.transaction_id#" show_buttons="#show_buttons#">
		<cftry>
			<cfoutput>
				<!--- lookup deaccession number and information about deaccession --->
				<cfquery name="getDeacc" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT 
						c.collection_cde, 
						c.collection,
						deaccession.deacc_type, 
						deaccession.deacc_status, 
						deaccession.deacc_number,
						deaccession.deacc_reason,
						deaccession.deacc_description,
						trans.nature_of_material,
						to_char(trans.trans_date,'yyyy-mm-dd') as deacc_date
					FROM 
						trans
						join collection c on trans.collection_id = c.collection_id
						join deaccession on trans.transaction_id = deaccession.transaction_id
					WHERE trans.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#" >
				</cfquery>
				<cfif getDeacc.recordcount NEQ 1>
					<cfthrow message="No deaccession found for transaction_id=[#encodeForHtml(transaction_id)#]">
				</cfif>
				<cfloop query="getDeacc">
					<h2 class="h3"><a href="/transactions/Deaccession.cfm?action=edit&transaction_id=#encodeForUrl(transaction_id)#" target="_blank">#getDeacc.deacc_number#</a></h2>
					<div>#deacc_type# #deacc_status# on #deacc_date# #deacc_reason# </div>
					<div>#nature_of_material#</div>
					<div>#deacc_description#</div>
					<cfif show_buttons NEQ "none">
						<div>
							<cfif show_buttons EQ "review" OR show_buttons EQ "both">
								<a href="/transactions/reviewDeaccItems.cfm?transaction_id=#encodeForUrl(transaction_id)#" target="_blank" class="btn btn-xs btn-secondary">Review Deaccession Items</a>
							</cfif>
							<cfif show_buttons EQ "add" OR show_buttons EQ "both">
								<a href="/Specimens.cfm?target_deacc_id=#encodeForUrl(transaction_id)#" target="_blank" class="btn btn-xs btn-secondary">Add Items To Deaccession</a>
							</cfif>
						</div>
					</cfif>
				</cfloop>
			</cfoutput>
		<cfcatch>
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cfthread>
	<cfthread action="join" name="getDeaccSummaryThread" />
	<cfreturn getDeaccSummaryThread.output>
</cffunction>


<!---   Function addPartToDeaccession add a part to a deaccession as a deacc item.
 @param transaction_id the deaccession to which to add the part as a deacc_item
 @param part_id the collection_object_id of the part to add as a deacc_item
 @param remark the deacc item remarks.
 @param instructions the deacc item instructions
 @param coll_obj_disposition the disposition to set on the specimen part being deaccessioned.
  --->
<cffunction name="addPartToDeaccession" access="remote" returntype="any" returnformat="json">
	<cfargument name="transaction_id" type="numeric" required="yes">
	<cfargument name="part_id" type="numeric" required="yes">
	<cfargument name="remark" type="string" required="yes">
	<cfargument name="instructions" type="string" required="yes">
	<cfargument name="coll_obj_disposition" type="string" required="yes">
	
	<cftransaction>
		<cftry>
			<cfquery name="checkIsDeaccession" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT count(transaction_id) as ct
				FROM deaccession
				WHERE
					transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
			</cfquery>
			<cfif checkIsDeaccession.ct EQ 0>
				<cfthrow message="Provided transaction_id is not for a deaccession.">
			</cfif>
			<cfquery name="getDeaccession" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT deacc_number
				FROM deaccession
				WHERE
					transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
			</cfquery>
			<cfquery name="meta" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT cataloged_item.collection_object_id,
					cat_num,
					collection,part_name, 
					specimen_part.preserve_method,
					coll_object.condition
				FROM
					cataloged_item 
					LEFT JOIN collection on cataloged_item.collection_id=collection.collection_id
					LEFT JOIN specimen_part on cataloged_item.collection_object_id=specimen_part.derived_from_cat_item
					left join coll_object on specimen_part.collection_object_id = coll_object.collection_object_id
				WHERE
					specimen_part.collection_object_id= <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#part_id#">
			</cfquery>

			<cfquery name="addDeaccItem" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="addDeaccItem_result">
				INSERT INTO DEACC_ITEM (
					TRANSACTION_ID
					,COLLECTION_OBJECT_ID
					,RECONCILED_BY_PERSON_ID
					,RECONCILED_DATE
					,ITEM_DESCR
					<cfif len(#instructions#) gt 0>
						,ITEM_INSTRUCTIONS
					</cfif>
					<cfif len(#remark#) gt 0>
						,deacc_ITEM_REMARKS
					</cfif>
				) VALUES (
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#TRANSACTION_ID#">
					,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#part_id#">
					,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#session.myagentid#">
					,sysdate
					,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#meta.collection# #meta.cat_num# #meta.part_name# (#meta.preserve_method#)">
					<cfif len(#instructions#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#instructions#">
					</cfif>
					<cfif len(#remark#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#remark#">
					</cfif>
				)
			</cfquery>
			<!--- Obtain deacc_item_id for insert and return it in the result. --->
			<cfset rowid = addDeaccItem_result.generatedkey>
			<cfif len(rowid) EQ 0>
				<cfthrow message="Could not obtain rowid of inserted deacc_item.">
			</cfif>
			<cfquery name="getDeaccItemID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT deacc_item_id
				FROM deacc_item
				WHERE
					ROWIDTOCHAR(rowid) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#rowid#">
			</cfquery>
			<cfif getDeaccItemID.recordcount NEQ 1>
				<cfthrow message="Could not obtain deacc_item_id of inserted deacc_item.">
			</cfif>
			<cfset targetObject = part_id>
			<cfquery name="setDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE coll_object 
				SET coll_obj_disposition = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.coll_obj_disposition#">
				WHERE 
					collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#targetObject#">
			</cfquery>
			<cfset theResult=queryNew("status, deacc_item_id, message")>
			<cfset t = queryaddrow(theResult,1)>
			<cfset t = QuerySetCell(theResult, "status", "1", 1)>
			<cfset t = QuerySetCell(theResult, "deacc_item_id", "#getDeaccItemID.deacc_item_id#", 1)>
			<cfset t = QuerySetCell(theResult, "message", "item added to deaccession.", 1)>
			<cftransaction action="commit">
		<cfcatch>
			<cftransaction action="rollback">
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
		<cfreturn theResult>
	</cftransaction>
</cffunction>

<!--- getDeaccItemDialogHtml obtain an html block to populate dialog for editing a deaccession item 
 @param deacc_item_id the id of the deaccession item for which to obtain the html.
 @return an html block for editing the deaccession item or an http 500 error if an error occurs.
--->
<cffunction name="getDeaccItemDialogHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="deacc_item_id" type="string" required="yes">

	<cfthread name="getRemoveLoanItemHtmlThread" deacc_item_id="#arguments.deacc_item_id#">
		<cftry>
			<cfoutput>
				<cfquery name="ctDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						SELECT coll_obj_disposition 
						FROM ctcoll_obj_disp 
						ORDER BY coll_obj_disposition
				</cfquery>
				<cfquery name="lookupItem" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT 
						deaccession.deacc_number,
						deaccession.transaction_id,
						deaccession.deacc_type,
						deaccession.deacc_status,
						collection.institution_acronym,
						cataloged_item.collection_cde, 
						cataloged_item.cat_num,
						coll_object.coll_obj_disposition,
						coll_object.condition,
						specimen_part.part_name,
						specimen_part.preserve_method,
						deacc_item.deacc_item_id,
						deacc_item.collection_object_id part_id,
						deacc_item.reconciled_by_person_id,
						MCZBASE.getPreferredAgentName(deacc_item.reconciled_by_person_id) as reconciled_by_agent,
						to_char(deacc_item.reconciled_date,'yyyy-mm-dd') reconciled_date,
						deacc_item.item_descr,
						deacc_item.item_instructions,
						deacc_item.deacc_item_remarks,
						specimen_part.sampled_from_obj_id,
						case when specimen_part.sampled_from_obj_id is not null then 'yes' else 'no' end as is_subsample,
						sampledFromCatItem.cat_num as sampled_from_cat_num,
						sampledFromCatItem.collection_cde as sampled_from_collection_cde,
						sampledFromPart.part_name as sampled_from_part_name,
						sampledFromPart.preserve_method as sampled_from_preserve_method
					FROM 
						deacc_item
						join specimen_part on deacc_item.collection_object_id = specimen_part.collection_object_id
						join coll_object on specimen_part.collection_object_id = coll_object.collection_object_id
						join cataloged_item on specimen_part.derived_from_cat_item = cataloged_item.collection_object_id
						join collection on cataloged_item.collection_id = collection.collection_id
						join deaccession on deacc_item.transaction_id = deaccession.transaction_id
						left join coll_object sampledFrom on specimen_part.sampled_from_obj_id = sampledFrom.collection_object_id
						left join specimen_part sampledFromPart on sampledFrom.collection_object_id = sampledFromPart.collection_object_id
						left join cataloged_item sampledFromCatItem on sampledFromPart.derived_from_cat_item = sampledFromCatItem.collection_object_id
					WHERE deacc_item.deacc_item_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#deacc_item_id#">
				</cfquery>
				<cfif lookupItem.recordcount NEQ 1>
					<cfthrow message="Unable to lookup deacc item by deacc_item_id=#encodeForHtml(deacc_item_id)#">
				</cfif>
				<cfloop query="lookupItem">
					<cfset guid="#institution_acronym#:#collection_cde#:#cat_num#">
					<div id="deaccItemEditorDiv">
						<div class="container-fluid">
							<div class="row">
								<div class="col-12">
									<div class="add-form mt-2">
										<div class="add-form-header pt-1 px-2">
											<h2 class="h2">
												Deaccession Item <a href="/guid/#guid#" target="_blank">#guid#</a> #part_name# (#preserve_method#) in #deacc_number# #deacc_type# #deacc_status# 
												<div class="smaller">[internal part collection_object_id: #lookupItem.part_id#]</div>
											</h2>
											<cfif is_subsample EQ "yes">
												<h3 class="h4">Part is a subsample of #sampled_from_part_name# (#sampled_from_preserve_method#)</h3>
											</cfif>
											<!--- lookup material sample id from guid_our_thing table --->
											<cfquery name="getMaterialSampleID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
												SELECT guid_our_thing_id, assembled_identifier, assembled_resolvable, local_identifier, internal_fg
												FROM guid_our_thing
												WHERE guid_is_a = 'materialSampleID'
											 		AND sp_collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#lookupItem.part_id#">
												ORDER BY internal_fg DESC, timestamp_created DESC
											</cfquery>
											<cfif getMaterialSampleID.recordcount GT 0>
												<div class="h4 mt-2">
													<cfloop query="getMaterialSampleID">
														<span class="font-italic">materialSampleID:</span> 
															<a href="#assembled_resolvable#" target="_blank">#assembled_identifier#</a>
															<cfif internal_fg EQ "1" AND left(assembled_identifier,9) EQ "urn:uuid:">
																<a href="/uuid/#local_identifier#/json" target="_blank" title="View RDF representation of this dwc:MaterialSample in a JSON-LD serialization">
																	<img src="/shared/images/json-ld-data-24.png" alt="JSON-LD">
																</a>
															</cfif>
														</span>
													</cfloop>
												</div>
											</cfif>
											<h3 class="h4">
												Added to Deaccession by <a href="/agents/Agent.cfm?agent_id=#reconciled_by_person_id#" target="_blank">#reconciled_by_agent#</a>
												on #reconciled_date#.  
											</h3>
										</div>
										<div class="card-body">
											<form name="editDeaccItemForm" id="editDeaccItemForm" class="mb-0">
												<input type="hidden" name="deacc_item_id" value="#lookupItem.deacc_item_id#">
												<input type="hidden" name="method" value="updateDeaccItem">
												<div class="row mx-0 py-2">
													<div class="col-12 col-md-6 px-1">
														<label class="data-entry-label">Deaccession Item Description</label>
														<input type="text" name="item_descr" value="#encodeForHtml(lookupItem.item_descr)#" class="data-entry-input">
													</div>
													<div class="col-12 px-1">
														<label class="data-entry-label" for="item_instructions">Deaccession Item Instructions</label> 
														<input type="text" name="item_instructions" id="item_instructions" value="#encodeForHtml(lookupItem.item_instructions)#" class="data-entry-input">
													</div>
													<div class="col-12 px-1">
														<label class="data-entry-label" for="deacc_item_remarks">Deaccession Item Remarks</label>
														<input type="text" name="deacc_item_remarks" id="deacc_item_remarks" value="#encodeForHtml(lookupItem.deacc_item_remarks)#" class="data-entry-input">
													</div>
													<div class="col-12 col-md-6 px-1">
														<label class="data-entry-label">Part Condition (#lookupItem.condition#)</label>
														<input type="text" name="condition" id="condition" value="#encodeForHtml(lookupItem.condition)#" class="data-entry-input">
													</div>
													<div class="col-12 col-md-6 px-1">
														<label class="data-entry-label">Part Disposition (#lookupItem.coll_obj_disposition#)</label>
														<select name="coll_obj_disposition" class="data-entry-select reqdClr" required>
															<option value=""></option>
															<cfloop query="ctDisp">
																<cfset selected = "">
																<cfif ctDisp.coll_obj_disposition EQ lookupItem.coll_obj_disposition>
																	<cfset selected="selected='selected'">
																</cfif>
																<option value="#ctDisp.coll_obj_disposition#" #selected#>
																	#ctDisp.coll_obj_disposition#
																</option>
															</cfloop>
														</select>
													</div>
													<div class="col-12 px-1">
														<button type="button" class="btn btn-primary btn-sm" 
															onclick="submitDeaccItemEditForm('editDeaccItemForm','deaccItemEditStatusDiv');">
															Save
														</button>
														<output id="deaccItemEditFormStatus">&nbsp;</output>
														<script>
															$(document).ready(function(){
																$("##editDeaccItemForm").submit(function(evt){
																	evt.preventDefault();
																	submitDeaccItemEditForm('editDeaccItemForm','deaccItemEditStatusDiv');
																});
															});
															function submitDeaccItemEditForm(formId, statusDivId){
																setFeedbackControlState("deaccItemEditStatusDiv","saving")
																var formData = $("##"+formId).serialize();
																$.ajax({
																	type: "POST",
																	url: "/transactions/component/itemFunctions.cfc",
																	data: formData,
																	dataType: "json",
																	success: function(response){
																		console.log(response);
																		var status = response.DATA[0][response.COLUMNS.indexOf("STATUS")];
																		if (status == "1") {
																			setFeedbackControlState("deaccItemEditStatusDiv","saved")
																		} else {
																			setFeedbackControlState("deaccItemEditStatusDiv","error")
																		}
																	},
																	error: function (jqXHR, status, message) {
																		handleFail(jqXHR,status,message,"updating deaccession item");
																	}
																});
															}
														</script>
													</div>
												</div>
											</form>
											<div id="deaccItemEditStatusDiv"></div>
										</div>
									</div>
								</div>
								<div class="col-12">
									<ul>
										<!---  lookup accession --->
										<cfquery name="lookupAccession" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
											SELECT 
												accn.transaction_id,
												accn.accn_number,
												accn.accn_status,
												accn.accn_type,
												to_char(accn.received_date,'yyyy-mm-dd') as received_date, 
												concattransagent(accn.transaction_id,'received from') received_from
											FROM 
												specimen_part
												join cataloged_item on specimen_part.derived_from_cat_item = cataloged_item.collection_object_id
												join accn on cataloged_item.accn_id = accn.transaction_id
											WHERE 
												specimen_part.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#lookupItem.part_id#">
										</cfquery>
										<cfloop query="lookupAccession">
											<!--- should be one and only one accession --->
											<li>
												Accession:
												<a href="/transactions/Accession.cfm?action=edit&transaction_id=#lookupAccession.transaction_id#" target="_blank">#lookupAccession.accn_number#</a>
												#lookupAccession.accn_type# (#lookupAccession.accn_status#).
												Received: #lookupAccession.received_date#  
												From: #lookupAccession.received_from#.
											</li>
											<!--- lookup any permits associated with this accession that have use restrictions or required benefits --->
											<cfquery name="accnLimitations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
												SELECT 
													case when length(permit.restriction_summary) > 30 then substr(permit.restriction_summary,1,30) || '...' else permit.restriction_summary end as restriction_summary,
													permit.specific_type,
													permit.permit_num,
													permit.permit_title,
													permit.permit_id
												FROM permit_trans 
													join permit on permit_trans.permit_id = permit.permit_id
												WHERE 
													permit_trans.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#lookupAccession.transaction_id#">
													and permit.restriction_summary IS NOT NULL
											</cfquery>
											<cfquery name="accnBenefits" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
												SELECT 
													case when length(permit.benefits_summary) > 30 then substr(permit.benefits_summary,1,30) || '...' else permit.benefits_summary end as benefits_summary,
													case when length(permit.internal_benefits_summary) > 30 then substr(permit.internal_benefits_summary,1,30) || '...' else permit.internal_benefits_summary end as internal_benefits_summary,
													permit.specific_type,
													permit.permit_num,
													permit.permit_title,
													permit.permit_id
												FROM permit_trans 
													join permit on permit_trans.permit_id = permit.permit_id
												WHERE 
													permit_trans.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#lookupAccession.transaction_id#">
													AND (permit.benefits_summary IS NOT NULL OR permit.internal_benefits_summary IS NOT NULL)	
											</cfquery>
											<cfif accnLimitations.recordcount GT 0 or accnBenefits.recordcount GT 0>
												<li class="list-group-item py-0">
													<cfif accnLimitations.recordcount GT 0>
														<span class="font-weight-lessbold mb-0 d-inline-block">Permits with restrictions on use:</span>
														<ul class="pl-0">
															<cfloop query="accnLimitations">
																<li class="small90">
																	<a href="/transactions/Permit.cfm?action=view&permit_id=#accnLimitations.permit_id#" target="_blank">
																		#accnLimitations.specific_type# #accnLimitations.permit_num#
																	</a> 
																	#accnLimitations.restriction_summary#
																</li>
															</cfloop>
														</ul>
													</cfif>
													<cfif accnBenefits.recordcount GT 0>
														<span class="font-weight-lessbold mb-0 d-inline-block">Permits with required benefits:</span>
														<ul class="pl-0">
															<cfloop query="accnBenefits">
																<li class="small90">
																	<a href="/transactions/Permit.cfm?action=view&permit_id=#accnBenefits.permit_id#" target="_blank">
																		#accnBenefits.specific_type# #accnBenefits.permit_num#
																	</a> 
																	<cfif len(accnBenefits.benefits_summary) gt 0>
																		<strong>Apply to All:</strong> #accnBenefits.benefits_summary#
																	</cfif>
																	<cfif len(accnBenefits.internal_benefits_summary) gt 0>
																		<cfif len(accnBenefits.benefits_summary) gt 0>, </cfif>
																		<strong>Apply to Harvard:</strong> #accnBenefits.internal_benefits_summary#
																	</cfif>
																</li>
															</cfloop>
														</ul>
													</cfif>
												</li>
											</cfif>
										</cfloop>
									
										<!--- lookup loans that this part is on, highlight any that are open --->
										<cfquery name="lookupLoans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
											SELECT 
												loan_item.loan_item_state,
												loan.loan_number,
												loan.loan_type,
												loan.loan_status,
												loan.transaction_id,
												to_char(loan.return_due_date,'yyyy-mm-dd') as return_due_date,
												to_char(loan.closed_date,'yyyy-mm-dd') as closed_date
											FROM 
												loan_item
												join loan on loan_item.transaction_id = loan.transaction_id
											WHERE 
												loan_item.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#lookupItem.part_id#">
										</cfquery>
										<cfif lookupLoans.recordcount EQ 0>
											<li>This part is not in any loans.</li>
										<cfelse>
											<cfloop query="lookupLoans">
												<cfif loan_status EQ "open">
													<li>
														This part is currently in open loan 
														<a href="/transactions/Loan.cfm?transaction_id=#transaction_id#" target="_blank">#loan_number#</a>
														#loan_type# (#loan_status#) due #return_due_date#.
														<cfif len(loan_item_state) GT 0>With loan item state #loan_item_state#.</cfif>
													</li>
												<cfelse>
													<li>
														This part is in loan 
														<a href="/loans/Loan.cfm?transaction_id=#transaction_id#" target="_blank"> #loan_number# </a>
														#loan_type# (#loan_status#) 
														<cfif len(closed_date) GT 0 and loan_status EQ 'closed'>on #closed_date#</cfif>.
														<cfif len(loan_item_state) GT 0>With loan item state #loan_item_state#.</cfif>
													</li>
												</cfif>
											</cfloop>
										</cfif>
		
										<!--- lookup any encumbrances this part is in --->
										<cfquery name="lookupEncumbrances" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
											SELECT 
												encumbrance.encumbrance_id,
												encumbrance.encumbrance,
												MCZBASE.getPreferredAgentName(encumbrance.encumbering_agent_id) as encumbering_agent,
												to_char(encumbrance.expiration_date,'yyyy-mm-dd') as expiration_date,
												encumbrance.expiration_event,
												encumbrance.remarks,
												encumbrance.encumbrance_action
											FROM
												specimen_part
												join coll_object_encumbrance on specimen_part.derived_from_cat_item = coll_object_encumbrance.collection_object_id
												join encumbrance on coll_object_encumbrance.encumbrance_id = encumbrance.encumbrance_id
											WHERE 
												coll_object_encumbrance.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#lookupItem.part_id#">
										</cfquery>
										<cfif lookupEncumbrances.recordcount EQ 0>
											<li>This part is not in any encumbrances.</li>
										<cfelse>
											<cfloop query="lookupEncumbrances">
												<li>
													Encumbrance #lookupEncumbrances.encumbrance_action#
													<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_collection")>
														<a href="/Encumbrances.cfm?action=listEncumbrances&encumbrance_id==#lookupEncumbrances.encumbrance_id#" target="_blank">
															#lookupEncumbrances.encumbrance#
														</a>
													<cfelse>
														#lookupEncumbrances.encumbrance#
													</cfif>
													set by #lookupEncumbrances.encumbering_agent#.
													<cfif len(lookupEncumbrances.expiration_date) GT 0>
														Expiring on #lookupEncumbrances.expiration_date# due to #lookupEncumbrances.expiration_event#.
													</cfif>
													<cfif len(lookupEncumbrances.remarks) GT 0>
														Remarks: #lookupEncumbrances.remarks#.
													</cfif>
												</li>
											</cfloop>
										</cfif>
									</ul>
								</div>
							</div>
						</div>
				</cfloop>
			</cfoutput>
		<cfcatch>
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cfthread>
	<cfthread action="join" name="getRemoveLoanItemHtmlThread" />
	<cfreturn getRemoveLoanItemHtmlThread.output>
</cffunction>

<!--- function updateDeaccItem to update the instructions, remarks, and description of an item in a deaccession.
 @param deacc_item_id the id of the deacc item to update. 
 @param item_instructions the new item instructions an empty value will set the field to null.
 @param deacc_item_remarks the new deacc item remarks, an empty value will set the field to null.
 @param coll_obj_disposition the new disposition of the collection object for the part being deaccessioned.
 @param condition the new condition of the part being deaccessioned, an empty value will set the field to null.
 @param item_descr the new item description, an empty value will be ignored.
 @return a json structurre with status:1, or a http 500 response.
--->
<cffunction name="updateDeaccItem" access="remote" returntype="any" returnformat="json">
	<cfargument name="deacc_item_id" type="numeric" required="yes">
	<cfargument name="item_instructions" type="string" required="yes">
	<cfargument name="deacc_item_remarks" type="string" required="yes">
	<cfargument name="coll_obj_disposition" type="string" required="yes">
	<cfargument name="condition" type="string" required="yes">
	<cfargument name="item_descr" type="string" required="yes">

	<cftransaction>
		<cftry>
			<cfquery name="getPartId" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT collection_object_id
				FROM deacc_item
				WHERE deacc_item_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.deacc_item_id#">
			</cfquery>
			<cfif getPartId.recordcount NEQ 1>
				<cfthrow message="Unable to obtain part_id for deacc_item_id=#encodeForHtml(arguments.deacc_item_id)#">
			</cfif>
			<cfset part_id = getPartId.collection_object_id>
			<cfquery name="upDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="upDisp_result">
				UPDATE coll_object 
				SET coll_obj_disposition = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.coll_obj_disposition#">,
					condition = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.condition#">
				WHERE collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#part_id#">
			</cfquery>
			<cfif upDisp_result.recordcount NEQ 1>
				<cfthrow message="Record not updated. #encodeForHtml(deacc_item_id)# #upDisp_result.sql#">
			</cfif>
			<cfquery name="upItem" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="upItem_result">
				UPDATE deacc_item SET
					<cfif len(#arguments.item_instructions#) gt 0>
						item_instructions = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.item_instructions#">
					<cfelse>
						item_instructions = null
					</cfif>
					<cfif len(#arguments.deacc_item_remarks#) gt 0>
						,deacc_item_remarks = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.deacc_item_remarks#">
					<cfelse>
						,deacc_item_remarks = null
					</cfif>
					<cfif len(arguments.item_descr) GT 0>
						,item_descr = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.item_descr#">
					</cfif>
				WHERE
					deacc_item_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#deacc_item_id#">
			</cfquery>
			<cfif upItem_result.recordcount NEQ 1>
				<cfthrow message="Record not updated. #encodeForHtml(deacc_item_id)# #upItem_result.sql#">
			</cfif>
			<cfif upItem_result.recordcount eq 1>
				<cfset theResult=queryNew("status, message")>
				<cfset t = queryaddrow(theResult,1)>
				<cfset t = QuerySetCell(theResult, "status", "1", 1)>
				<cfset t = QuerySetCell(theResult, "message", "deacc item updated.", 1)>
			</cfif>
			<cftransaction action="commit">
		<cfcatch>
			<cftransaction action="rollback">
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn theResult>
</cffunction>

<!--- getLoanCatItemHtml get a block of html for one or more cataloged items in a loan, listing
  all each cataloged items parts that are in the loan.
	@param transaction_id the id of the loan transaction.
	@param collection_object_id the id of the cataloged item for which to obtain the html
      if collection_object_id is an empty string, html for all cataloged items in the loan is returned.
 @return an html block representing the loan item(s) or an http 500 error if an error occurs.
--->
<cffunction name="getLoanCatItemHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="transaction_id" type="string" required="yes">
	<cfargument name="collection_object_id" type="string" required="yes">

	<cfset tn = REReplace(CreateUUID(), "[-]", "", "all") >
	<cfthread name="getLoanCatItemHtmlThread#tn#" transaction_id="#arguments.transaction_id#" collection_object_id="#arguments.collection_object_id#">
		<cfset otherIdOn = false>
		<cfif isdefined("showOtherId") and #showOtherID# is "true">
			<cfset otherIdOn = true>
		</cfif>
		<cfset showMultiple = false>
		<cfif len(trim(collection_object_id)) EQ 0 >
			<cfset showMultiple = true>
		</cfif>
		<cftry>
			<!--- Similar to getDeaccCatItemHtml but for loans instead of deaccessions --->
			<cfoutput>
				<cfquery name="lookupLoan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT 
						loan_number,
						loan_type,
						loan_status
					FROM 
						loan
					WHERE
						transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#" >
				</cfquery>
				<cfif lookupLoan.recordcount NEQ 1>
					<cfthrow message="Unable to lookup loan by transaction_id=#encodeForHtml(transaction_id)#">
				</cfif>
				<cfquery name="getCatItems" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT DISTINCT
						cataloged_item.collection_object_id,
						cataloged_item.collection_cde,
						cataloged_item.cat_num, 
						collection.institution_acronym,
						collection.collection,
						loan.loan_number,
						loan.loan_type,
						MCZBASE.get_scientific_name_auths(cataloged_item.collection_object_id) as scientific_name,
						collecting_event.began_date,
						collecting_event.ended_date,
						locality.spec_locality,
						locality.sovereign_nation,
						geog_auth_rec.higher_geog,
						concatSingleOtherId(cataloged_item.collection_object_id, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.CustomOtherIdentifier#">) AS CustomID,
						accn.accn_number,
						accn.transaction_id accn_id,
						get_top_typestatus(cataloged_item.collection_object_id) as type_status
					 FROM 
						loan	
						join loan_item on loan.transaction_id = loan_item.transaction_id
						join specimen_part on loan_item.collection_object_id = specimen_part.collection_object_id 
						join coll_object on specimen_part.collection_object_id = coll_object.collection_object_id
						join cataloged_item on specimen_part.derived_from_cat_item = cataloged_item.collection_object_id 
						join collecting_event on cataloged_item.collecting_event_id = collecting_event.collecting_event_id
						join locality on collecting_event.locality_id = locality.locality_id
						join geog_auth_rec on locality.geog_auth_rec_id = geog_auth_rec.geog_auth_rec_id
						join collection on cataloged_item.collection_id=collection.collection_id
						join accn on cataloged_item.accn_id = accn.transaction_id
					WHERE
						loan.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#" >
						<cfif NOT showMultiple>
							AND
							specimen_part.derived_from_cat_item = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
						</cfif>
					ORDER BY cataloged_item.collection_cde, cat_num
				</cfquery>
				<cfquery name="ctDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT coll_obj_disposition 
					FROM ctcoll_obj_disp
					ORDER BY coll_obj_disposition
				</cfquery>
				<cfloop query="getCatItems">
					<cfset catItemId = getCatItems.collection_object_id>

					<cfif showMultiple>
						<div class="row col-12 border m-1 pb-1" id="rowDiv#catItemId#">
					</cfif>

					<div class="col-12 col-md-4">
						<cfset guid = "#institution_acronym#:#collection_cde#:#cat_num#">
						<a href="/guid/#guid#" target="_blank">#guid#</a>  
						<cfif len(#CustomID#) gt 0 AND otherIdOn>
							Other ID: #CustomID#
						</cfif>
						#scientific_name#
						#type_status#
					</div>
					<div class="col-12 col-md-4">
						#higher_geog#; #spec_locality#; #sovereign_nation#
						#began_date#<cfif ended_date NEQ began_date>/#ended_date#</cfif>
						<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_transactions") >
							Accession: <a href="/transactions/Accession.cfm?action=edit&transaction_id=#accn_id#" target="_blank">#accn_number#</a>
						<cfelse>
							Accession: #accn_number#
						</cfif>
					</div>
					<div class="col-12 col-md-2">
						<cfquery name="getEncumbrance" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							SELECT 
								concatEncumbranceDetails(<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getCatItems.collection_object_id#">) encumbranceDetail
							FROM DUAL
						</cfquery>
						<cfif len(getEncumbrance.encumbranceDetail) GT 0>
							<strong>Encumbered:</strong>
							<cfloop query="getEncumbrance">
								<span>#getEncumbrance.encumbranceDetail#</span>
							</cfloop>
						</cfif>
					</div>
					<div class="col-12 col-md-2">
						<cfquery name="getRestrictions" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							SELECT DISTINCT permit.permit_id, permit.permit_num, permit.permit_title, permit.specific_type
							FROM cataloged_item ci
								JOIN accn on ci.accn_id = accn.transaction_id
								JOIN permit_trans on accn.transaction_id = permit_trans.transaction_id
								JOIN permit on permit_trans.permit_id = permit.permit_id
							WHERE ci.collection_object_id = <cfqueryparam CFSQLType="CF_SQL_DECIMAL" value="#getCatItems.collection_object_id#">
								and permit.restriction_summary is not null
						</cfquery>
						<cfif getRestrictions.recordcount GT 0>
							<strong>Has Restrictions On Use</strong> See:
							<cfloop query="getRestrictions">
								<cfset permitText = getRestrictions.permit_num>
								<cfif len(permitText ) EQ 0>
									<cfset permitText = getRestrictions.permit_title>
								</cfif>
								<cfif len(permitText ) EQ 0>
									<cfset permitText = getRestrictions.specific_type>
								</cfif>
								<a href='/transactions/Permit.cfm?action=view&permit_id=#getRestrictions.permit_id#' target="_blank">#permitText#</a>
							</cfloop>
						</cfif>
					</div>
					<cfquery name="getParts" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						SELECT DISTINCT
							specimen_part.collection_object_id as partID,
							specimen_part.part_name,
							specimen_part.preserve_method,
							specimen_part.sampled_from_obj_id,
							decode(sampled_from_obj_id,null,'no ','of ' || MCZbase.get_part_prep(sampled_from_obj_id)) as sampled_from_object,
							coll_object.condition,
							coll_object.lot_count,
							coll_object.lot_count_modifier,
							coll_object.coll_obj_disposition,
							loan_item.loan_item_id,
							loan_item.item_descr,
							loan_item.loan_item_remarks,
							loan_item.item_instructions,
							loan_item.loan_item_state,
							loan_item.resolution_remarks,
			reconciled_by_person_id,
			MCZBASE.getPreferredAgentName(reconciled_by_person_id) as reconciled_by_agent,
			to_char(reconciled_date,'YYYY-MM-DD') reconciled_date,
							to_char(loan_item.return_date,'YYYY-MM-DD') return_date,
			MCZBASE.getPreferredAgentName(loan_item.resolution_recorded_by_agent_id) as resolution_recorded_by_agent,
			loan_item.resolution_recorded_by_agent_id,
							loan.loan_number,
							loan.loan_type,
							identification.scientific_name as mixed_scientific_name,
			coll_obj_cont_hist.container_id,
							MCZBASE.concatlocation(MCZBASE.get_current_container_id(specimen_part.collection_object_id)) as location,
							MCZBASE.get_storage_parentage(MCZBASE.get_current_container_id(specimen_part.collection_object_id)) as short_location,
			MCZBASE.get_storage_parentatrank(MCZBASE.get_current_container_id(specimen_part.collection_object_id),'room') as location_room,
			MCZBASE.get_storage_parentatrank(MCZBASE.get_current_container_id(specimen_part.collection_object_id),'fixture') as location_fixture,
			MCZBASE.get_storage_parentatrank(MCZBASE.get_current_container_id(specimen_part.collection_object_id),'tank') as location_tank,
			MCZBASE.get_storage_parentatrank(MCZBASE.get_current_container_id(specimen_part.collection_object_id),'freezer') as location_freezer,
			MCZBASE.get_storage_parentatrank(MCZBASE.get_current_container_id(specimen_part.collection_object_id),'cryovat') as location_cryovat,
			MCZBASE.get_storage_parentatrank(MCZBASE.get_current_container_id(specimen_part.collection_object_id),'compartment') as location_compartment,
							mczbase.get_stored_as_id(cataloged_item.collection_object_id) as stored_as_name,
							MCZBASE.get_storage_parentage(MCZBASE.get_previous_container_id(coll_obj_cont_hist.container_id)) as previous_location
						FROM 
							loan
							join loan_item on loan.transaction_id = loan_item.transaction_id
							join specimen_part on loan_item.collection_object_id = specimen_part.collection_object_id 
							join coll_object on specimen_part.collection_object_id = coll_object.collection_object_id
							join cataloged_item on specimen_part.derived_from_cat_item = cataloged_item.collection_object_id 
							left join identification on specimen_part.collection_object_id = identification.collection_object_id AND identification.accepted_id_fg = 1
							left join coll_obj_cont_hist on specimen_part.collection_object_id = coll_obj_cont_hist.collection_object_id 
								and coll_obj_cont_hist.current_container_fg = 1
						WHERE
							loan.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#" >
							AND cataloged_item.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#catItemId#">
						ORDER BY 
							part_name, preserve_method
					</cfquery>
					<cfloop query="getParts">
						<cfset id = getParts.loan_item_id>
						<!--- Output each part row --->
						<div id="historyDialog_#getParts.partID#"></div>
						<div class="col-12 row border-top mx-1 mt-1 px-1">
							<cfset name="#guid# #part_name# (#preserve_method#)">
							<div class="col-12 col-md-4">
								Part Name: #part_name# (#preserve_method#) #lot_count_modifier# #lot_count#
								<cfif len(mixed_scientific_name) gt 0>
									<strong>Mixed Collection</strong>#mixed_scientific_name#
								</cfif>
								<cfif len(#sampled_from_obj_id#) gt 0> <strong>Subsample</strong> #sampled_from_object#</cfif>
								<div class="smaller">[internal part collection_object_id: #partId#]</div>
								<!--- lookup material sample id from guid_our_thing table --->
								<cfquery name="getMaterialSampleID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									SELECT guid_our_thing_id, assembled_identifier, assembled_resolvable, local_identifier, internal_fg
									FROM guid_our_thing
									WHERE guid_is_a = 'materialSampleID'
								 		AND sp_collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getParts.partId#">
									ORDER BY internal_fg DESC, timestamp_created DESC
								</cfquery>
								<cfif getMaterialSampleID.recordcount GT 0>
									<ul>
										<cfloop query="getMaterialSampleID">
											<li>
												<span class="font-italic">materialSampleID:</span> 
												<a href="#assembled_resolvable#" target="_blank">#assembled_identifier#</a>
												<cfif internal_fg EQ "1" AND left(assembled_identifier,9) EQ "urn:uuid:">
													<a href="/uuid/#local_identifier#/json" target="_blank" title="View RDF representation of this dwc:MaterialSample in a JSON-LD serialization">
														<img src="/shared/images/json-ld-data-24.png" alt="JSON-LD">
													</a>
												</cfif>
												</li>
										</cfloop>
									</ul>
								</cfif>
							</div>
							<div class="col-12 col-md-6">
								<strong>Storage Location:</strong> #getParts.short_location#
								<ul>
									<cfif len(previous_location) GT 0>
										<li>
											<strong>Previous Location:</strong> 
											<cfif getParts.short_location EQ getParts.previous_location>
												same
											<cfelse>
												#previous_location#
											</cfif>
										</li>
									</cfif>
									<cfif len(stored_as_name) GT 0>
										<li>
											<strong>Stored As:</strong> #stored_as_name#
										</li>
									</cfif>
								</ul>
							</div>
							<div class="col-12 col-md-2">
								#loan_item_state#
								#return_date#
							</div>
							<div class="col-12 col-md-2">
								<label for="item_descr_#id#" class="data-entry-label">
									Item Description:
								</label>
								<input type="text" name="item_descr" id="item_descr_#id#" value="#item_descr#" class="data-entry-text">
								<script>
									$(document).ready( function() {
										$("##item_descr_#id#").on("focusout", function(){  doDeaccItemUpdate("#id#"); } ); 
									});
								</script>
							</div>
							<div class="col-12 col-md-2">
								<label for="condition_#id#" class="data-entry-label">
									Part Condition:
									<a class="smaller" href="javascript:void(0)" aria-label="Condition/Preparation History" onclick=" openHistoryDialog(#partId#, 'historyDialog_#partId#');">History</a>
								</label>
								<input type="text" name="condition" id="condition_#id#" value="#condition#" class="data-entry-text">
								<script>
									$(document).ready( function() {
										$("##condition_#id#").on("focusout", function(){  doDeaccItemUpdate("#id#"); } ); 
									});
								</script>
							</div>
							<div class="col-12 col-md-2">
								<label for="coll_obj_disposition_#id#" class="data-entry-label">Part Disposition:</label>
								<select id="coll_obj_disposition_#id#" name="coll_obj_disposition" class="data-entry-select">
									<cfset curr_part_disposition = getParts.coll_obj_disposition>
									<cfloop query="ctDisp">
										<cfif ctDisp.coll_obj_disposition EQ curr_part_disposition>
											<cfset selected = "selected">
										<cfelse>
											<cfset selected = "">
										</cfif>
										<option value="#ctDisp.coll_obj_disposition#" #selected#>#ctDisp.coll_obj_disposition#</option>
									</cfloop>
								</select>
								<script>
									$(document).ready( function() {
										$("##coll_obj_disposition_#id#").on("focusout", function(){  doLoanItemUpdate("#id#"); } ); 
									});
								</script>
							</div>
							<div class="col-12 col-md-2">
								<label for="loan_item_remarks_#id#" class="data-entry-label">Item Remarks:</label>
								<input type="text" name="loan_item_remarks" id="loan_item_remarks_#id#" value="#loan_item_remarks#" class="data-entry-text">
								<script>
									$(document).ready( function() {
										$("##loan_item_remarks_#id#").on("focusout", function(){  doLoanItemUpdate("#id#"); } ); 
									});
								</script>
							</div>
							<div class="col-12 col-md-2">
								<label for="item_instructions" class="data-entry-label">Item Instructions:</label>
								<input type="text" id="item_instructions_#id#" name="item_instructions" value="#item_instructions#" class="data-entry-text">
								<script>
									$(document).ready( function() { 
										$("##item_instructions_#id#").on("focusout", function(){  doLoanItemUpdate("#id#"); } ); 
									});
								</script>
							</div>
							<div class="col-12 col-md-2 pt-3">
								<!--- determine action buttons to show based on loan status --->
								<cfif lookupLoan.loan_status EQ "in process">
									<button class="btn btn-xs btn-danger" aria-label="Remove part from loan" id="removeButton_#id#" onclick="removeLoanItem#catItemId#(#id#);">Remove</button>
								</cfif>
								<cfif lookupLoan.loan_status EQ "open">
									<cfif lookupLoan.loan_type EQ "consumable">
										<cfif getParts.loan_item_state NEQ "consumed">
											<button class="btn btn-xs btn-primary" aria-label="Reconcile part return" id="reconcileButton_#id#" onclick="returnLoanItem(#id#, refreshItems#catItemId#);">Consume</button>
										</cfif>
									<cfelse>
										<cfif getParts.loan_item_state NEQ "returned">
											<button class="btn btn-xs btn-primary" aria-label="Reconcile part return" id="reconcileButton_#id#" onclick="consumeLoanItem(#id#, refreshItems#catItemId#);">Return</button>
										</cfif>
									</cfif>
								</cfif>
								<button class="btn btn-xs btn-secondary" aria-label="Edit loan item" id="editButton_#id#" onclick="launchEditDialog#catItemId#(#id#,'#name#');">Edit</button>
								<output id="loanItemStatusDiv_#id#"></output>
							</div>
						</div>
					</cfloop>

					<cfif showMultiple>
						</div>
						<script>
							$(document).ready( function() {
								if (typeof window.removeLoanItem#catItemId# === 'function') {
									console.log("functions for #catItemId# already defined");
								} else {
									console.log("defining functions for #catItemId#");
									window.removeLoanItem#catItemId# = function removeLoanItem#catItemId#(loan_item_id) { 
										console.log(loan_item_id);
										// bring up a dialog to determine the new coll object disposition and confirm deletion
										openRemoveLoanItemDialog(loan_item_id, "loanItemRemoveDialogDiv" , refreshItems#catItemId#);
										loanModifiedHere();
									}
									window.launchEditDialg#catItemId# = function launchEditDialog#catItemId#(loan_item_id,name) { 
										console.log(loan_item_id);
										openLoanItemDialog(loan_item_id,"loanItemEditDialogDiv",name,refreshItems#catItemId#);
									}
									window.refreshItems#catItemId# = function refreshItems#catItemId#() { 
										console.log("refresh items invoked for #catItemId#");
										refreshLoanCatItem("#catItemId#");
									}
								}
							});
							function doLoanItemUpdate(loan_item_id) {
								console.log(loan_item_id);
								let loan_item_remarks = $("##loan_item_remarks_#id#").val();
								let item_instructions = $("##item_instructions_#id#").val();
								let condition = $("##condition_#id#").val();
								let coll_obj_disposition = $("##coll_obj_disposition_#id#").val();
								let item_descr = $("##item_descr_#id#").val();
								updateLoanItem(loan_item_id, item_instructions, loan_item_remarks, coll_obj_disposition, condition, item_descr);
							}
						</script>
					</cfif>
				</cfloop>
			</cfoutput>
		<cfcatch>
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cfthread>
	<cfthread action="join" name="getLoanCatItemHtmlThread#tn#" />
	<cfreturn cfthread["getLoanCatItemHtmlThread#tn#"].output>
</cffunction>

<!--- getDeaccCatItemHtml get a block of html for a cataloged item in a deaccession, listing
  all its parts in the deaccession, or for all the cataloged items in a deaccession
	@param transaction_id the id of the deaccession transaction.
	@param collection_object_id the id of the cataloged item for which to obtain the html
      if collection_object_id is an empty string, html for all cataloged items in the deaccession is returned.
 @return an html block representing the deaccession item or an http 500 error if an error occurs.
--->
<cffunction name="getDeaccCatItemHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="transaction_id" type="string" required="yes">
	<cfargument name="collection_object_id" type="string" required="yes">

	<cfset tn = REReplace(CreateUUID(), "[-]", "", "all") >
	<cfthread name="getDeaccCatItemHtmlThread#tn#" transaction_id="#arguments.transaction_id#" collection_object_id="#arguments.collection_object_id#">
		<cfset otherIdOn = false>
		<cfif isdefined("showOtherId") and #showOtherID# is "true">
			<cfset otherIdOn = true>
		</cfif>
		<cfset showMultiple = false>
		<cfif len(trim(collection_object_id)) EQ 0 >
			<cfset showMultiple = true>
		</cfif>
		<cftry>
			<cfoutput>
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
						concatSingleOtherId(cataloged_item.collection_object_id, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.CustomOtherIdentifier#">) AS CustomID,
						accn.accn_number,
						accn.transaction_id accn_id,
						get_top_typestatus(cataloged_item.collection_object_id) as type_status
					 from 
						deaccession
						join deacc_item on deaccession.transaction_id = deacc_item.transaction_id
						join specimen_part on deacc_item.collection_object_id = specimen_part.collection_object_id 
						join coll_object on specimen_part.collection_object_id = coll_object.collection_object_id
						join cataloged_item on specimen_part.derived_from_cat_item = cataloged_item.collection_object_id 
						join collecting_event on cataloged_item.collecting_event_id = collecting_event.collecting_event_id
						join locality on collecting_event.locality_id = locality.locality_id
						join geog_auth_rec on locality.geog_auth_rec_id = geog_auth_rec.geog_auth_rec_id
						left join identification on cataloged_item.collection_object_id = identification.collection_object_id AND identification.accepted_id_fg = 1
						join collection on cataloged_item.collection_id=collection.collection_id
						join accn on cataloged_item.accn_id = accn.transaction_id
					WHERE
						deaccession.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#" >
						<cfif NOT showMultiple>
							AND
							specimen_part.derived_from_cat_item = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
						</cfif>
					ORDER BY cataloged_item.collection_cde, cat_num
				</cfquery>
				<cfquery name="ctDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT coll_obj_disposition 
					FROM ctcoll_obj_disp
					ORDER BY coll_obj_disposition
				</cfquery>
				<cfloop query="getCatItems">
					<cfset catItemId = getCatItems.collection_object_id>
					<cfif showMultiple>
						<div class="row col-12 border m-1 pb-1" id="rowDiv#catItemId#">
					</cfif>
					<div class="col-12 col-md-4">
						<cfset guid = "#institution_acronym#:#collection_cde#:#cat_num#">
						<a href="/guid/#guid#" target="_blank">#guid#</a>  
						<cfif len(#CustomID#) gt 0 AND otherIdOn>
							Other ID: #CustomID#
						</cfif>
						#scientific_name#
						#type_status#
					</div>
					<div class="col-12 col-md-4">
						#higher_geog#; #spec_locality#; #sovereign_nation#
						#began_date#<cfif ended_date NEQ began_date>/#ended_date#</cfif>
						<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_transactions") >
							Accession: <a href="/transactions/Accession.cfm?action=edit&transaction_id=#accn_id#" target="_blank">#accn_number#</a>
						<cfelse>
							Accession: #accn_number#
						</cfif>
					</div>
					<div class="col-12 col-md-2">
						<cfquery name="getEncumbrance" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							SELECT 
								concatEncumbranceDetails(<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getCatItems.collection_object_id#">) encumbranceDetail
							FROM DUAL
						</cfquery>
						<cfif len(getEncumbrance.encumbranceDetail) GT 0>
							<strong>Encumbered:</strong>
							<cfloop query="getEncumbrance">
								<span>#getEncumbrance.encumbranceDetail#</span>
							</cfloop>
						</cfif>
					</div>
					<div class="col-12 col-md-2">
						<cfquery name="getRestrictions" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							SELECT DISTINCT permit.permit_id, permit.permit_num, permit.permit_title, permit.specific_type
							FROM cataloged_item ci
								JOIN accn on ci.accn_id = accn.transaction_id
								JOIN permit_trans on accn.transaction_id = permit_trans.transaction_id
								JOIN permit on permit_trans.permit_id = permit.permit_id
							WHERE ci.collection_object_id = <cfqueryparam CFSQLType="CF_SQL_DECIMAL" value="#getCatItems.collection_object_id#">
								and permit.restriction_summary is not null
						</cfquery>
						<cfif getRestrictions.recordcount GT 0>
							<strong>Has Restrictions On Use</strong> See:
							<cfloop query="getRestrictions">
								<cfset permitText = getRestrictions.permit_num>
								<cfif len(permitText ) EQ 0>
									<cfset permitText = getRestrictions.permit_title>
								</cfif>
								<cfif len(permitText ) EQ 0>
									<cfset permitText = getRestrictions.specific_type>
								</cfif>
								<a href='/transactions/Permit.cfm?action=view&permit_id=#getRestrictions.permit_id#' target="_blank">#permitText#</a>
							</cfloop>
						</cfif>
					</div>
					<cfquery name="getParts" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						SELECT DISTINCT
							specimen_part.collection_object_id as partID,
							specimen_part.part_name,
							specimen_part.preserve_method,
							specimen_part.sampled_from_obj_id,
							coll_object.condition,
							coll_object.lot_count,
							coll_object.lot_count_modifier,
							coll_object.coll_obj_disposition,
							deacc_item.deacc_item_id,
							deacc_item.item_descr,
							deacc_item.deacc_item_remarks,
							deacc_item.item_instructions,
							deaccession.deacc_number,
							deaccession.deacc_type,
							deaccession.deacc_reason,
							identification.scientific_name as mixed_scientific_name,
							encumbrance.Encumbrance,
							decode(encumbering_agent_id,NULL,'',MCZBASE.get_agentnameoftype(encumbering_agent_id)) agent_name
						FROM 
							deaccession
							join deacc_item on deaccession.transaction_id = deacc_item.transaction_id
							join specimen_part on deacc_item.collection_object_id = specimen_part.collection_object_id 
							join coll_object on specimen_part.collection_object_id = coll_object.collection_object_id
							join cataloged_item on specimen_part.derived_from_cat_item = cataloged_item.collection_object_id 
							left join coll_object_encumbrance on cataloged_item.collection_object_id = coll_object_encumbrance.collection_object_id
							left join encumbrance on coll_object_encumbrance.encumbrance_id = encumbrance.encumbrance_id
							left join identification on specimen_part.collection_object_id = identification.collection_object_id AND identification.accepted_id_fg = 1
						WHERE
							deaccession.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#" >
							AND cataloged_item.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#catItemId#">
						ORDER BY 
							part_name, preserve_method
					</cfquery>
					<cfloop query=getParts>
						<cfset id = getParts.deacc_item_id>
						<!--- Output each part row --->
						<div id="historyDialog_#getParts.partID#"></div>
						<div class="col-12 row border-top mx-1 mt-1 px-1">
							<cfset name="#guid# #part_name# (#preserve_method#)">
							<div class="col-12 col-md-2">
								Part Name: #part_name# (#preserve_method#) #lot_count_modifier# #lot_count#
								<cfif len(mixed_scientific_name) gt 0>
									<strong>Mixed Collection</strong>#mixed_scientific_name#
								</cfif>
								<cfif len(#sampled_from_obj_id#) gt 0> <strong>Subsample</strong></cfif>
								<div class="smaller">[internal part collection_object_id: #partId#]</div>
								<!--- lookup material sample id from guid_our_thing table --->
								<cfquery name="getMaterialSampleID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									SELECT guid_our_thing_id, assembled_identifier, assembled_resolvable, local_identifier, internal_fg
									FROM guid_our_thing
									WHERE guid_is_a = 'materialSampleID'
								 		AND sp_collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getParts.partId#">
									ORDER BY internal_fg DESC, timestamp_created DESC
								</cfquery>
								<cfif getMaterialSampleID.recordcount GT 0>
									<ul>
										<cfloop query="getMaterialSampleID">
											<li>
												<span class="font-italic">materialSampleID:</span> 
												<a href="#assembled_resolvable#" target="_blank">#assembled_identifier#</a>
												<cfif internal_fg EQ "1" AND left(assembled_identifier,9) EQ "urn:uuid:">
													<a href="/uuid/#local_identifier#/json" target="_blank" title="View RDF representation of this dwc:MaterialSample in a JSON-LD serialization">
														<img src="/shared/images/json-ld-data-24.png" alt="JSON-LD">
													</a>
												</cfif>
												</li>
										</cfloop>
									</ul>
								</cfif>
							</div>
							<div class="col-12 col-md-2">
								<label for="condition_#id#" class="data-entry-label">
									Part Condition:
									<a class="smaller" href="javascript:void(0)" aria-label="Condition/Preparation History" onclick=" openHistoryDialog(#partId#, 'historyDialog_#partId#');">History</a>
								</label>
								<input type="text" name="condition" id="condition_#id#" value="#condition#" class="data-entry-text">
								<script>
									$(document).ready( function() {
										$("##condition_#id#").on("focusout", function(){  doDeaccItemUpdate("#id#"); } ); 
									});
								</script>
							</div>
							<div class="col-12 col-md-2">
								<label for="coll_obj_disposition_#id#" class="data-entry-label">Part Disposition:</label>
								<select id="coll_obj_disposition_#id#" name="coll_obj_disposition" class="data-entry-select">
									<cfset curr_part_disposition = getParts.coll_obj_disposition>
									<cfloop query="ctDisp">
										<cfif ctDisp.coll_obj_disposition EQ curr_part_disposition>
											<cfset selected = "selected">
										<cfelse>
											<cfset selected = "">
										</cfif>
										<option value="#ctDisp.coll_obj_disposition#" #selected#>#ctDisp.coll_obj_disposition#</option>
									</cfloop>
								</select>
								<script>
									$(document).ready( function() {
										$("##coll_obj_disposition_#id#").on("focusout", function(){  doDeaccItemUpdate("#id#"); } ); 
									});
								</script>
							</div>
							<div class="col-12 col-md-2">
								<label for="deacc_item_remarks_#id#" class="data-entry-label">Item Remarks:</label>
								<input type="text" name="deacc_item_remarks" id="deacc_item_remarks_#id#" value="#deacc_item_remarks#" class="data-entry-text">
								<script>
									$(document).ready( function() {
										$("##deacc_item_remarks_#id#").on("focusout", function(){  doDeaccItemUpdate("#id#"); } ); 
									});
								</script>
							</div>
							<div class="col-12 col-md-2">
								<label for="item_instructions" class="data-entry-label">Item Instructions:</label>
								<input type="text" id="item_instructions_#id#" name="item_instructions" value="#item_instructions#" class="data-entry-text">
								<script>
									$(document).ready( function() { 
										$("##item_instructions_#id#").on("focusout", function(){  doDeaccItemUpdate("#id#"); } ); 
									});
								</script>
							</div>
							<div class="col-12 col-md-2 pt-3">
								<button class="btn btn-xs btn-danger" aria-label="Remove part from deaccession" id="removeButton_#id#" onclick="removeDeaccItem#catItemId#(#id#);">Remove</button>
								<button class="btn btn-xs btn-secondary" aria-label="Edit deaccession item" id="editButton_#id#" onclick="launchEditDialog#catItemId#(#id#,'#name#');">Edit</button>
								<output id="deaccItemStatusDiv_#id#"></output>
							</div>
						</div>
					</cfloop>
					<cfif showMultiple>
						</div>
						<script>
							if (typeof removeDeaccItem#catItemId# === 'function') {
								console.log("functions for #catItemId# already defined");
							} else {
								function removeDeaccItem#catItemId#(deacc_item_id) { 
									console.log(deacc_item_id);
									// bring up a dialog to determine the new coll object disposition and confirm deletion
									openRemoveDeaccItemDialog(deacc_item_id, "deaccItemRemoveDialogDiv" , refreshItems#catItemId#);
									deaccessionModifiedHere();
								};
								function launchEditDialog#catItemId#(deacc_item_id,name) { 
									console.log(deacc_item_id);
									openDeaccessionItemDialog(deacc_item_id,"deaccItemEditDialogDiv",name,refreshItems#catItemId#);
								}
								function doDeaccItemUpdate(deacc_item_id) {
									console.log(deacc_item_id);
									deacc_item_remarks = $("##deacc_item_remarks_#id#").val();
									item_instructions = $("##item_instructions_#id#").val();
									condition = $("##condition_#id#").val();
									coll_obj_disposition = $("##coll_obj_disposition_#id#").val();
									item_descr = ""; // not updating description here
									updateDeaccItem(deacc_item_id, item_instructions, deacc_item_remarks, coll_obj_disposition, condition, item_descr);
								}
								function refreshItems#catItemId#() { 
									console.log("refresh items invoked for #catItemId#");
									refreshDeaccCatItem("#catItemId#");
								}
							}
						</script>
					</cfif>
				</cfloop>
			</cfoutput>
		<cfcatch>
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cfthread>
	<cfthread action="join" name="getDeaccCatItemHtmlThread#tn#" />
	<cfreturn cfthread["getDeaccCatItemHtmlThread#tn#"].output>
</cffunction>

</cfcomponent>
