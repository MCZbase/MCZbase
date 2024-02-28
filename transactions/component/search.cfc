<!---
/transactions/component/search.cfc

Copyright 2019 President and Fellows of Harvard College

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

<!---   Function getTransactions  --->
<cffunction name="getTransactions" access="remote" returntype="any" returnformat="json">
	<cfargument name="number" type="string" required="no">
	<cfargument name="status" type="string" required="no">
	<cfargument name="collection_id" type="numeric" required="no">
	<cfargument name="agent_1" type="string" required="no">
	<cfargument name="agent_1_id" type="string" required="no">
	<cfargument name="trans_agent_role_1" type="string" required="no">
	<cfargument name="agent_2" type="string" required="no">
	<cfargument name="agent_2_id" type="string" required="no">
	<cfargument name="trans_agent_role_2" type="string" required="no">
	<cfargument name="agent_3" type="string" required="no">
	<cfargument name="agent_3_id" type="string" required="no">
	<cfargument name="trans_agent_role_3" type="string" required="no">
	<cfargument name="trans_date" type="string" required="no">
	<cfargument name="to_trans_date" type="string" required="no">
	<cfargument name="date_entered" type="string" required="no">
	<cfargument name="to_date_entered" type="string" required="no">
	<cfargument name="trans_remarks" type="string" required="no">
	<cfargument name="permit_id" type="string" required="no">
	<cfargument name="permit_type" type="string" required="no">
	<cfargument name="permit_specific_type" type="string" required="no">
	<cfargument name="shipment_count" type="string" required="no">
	<cfargument name="foreign_shipments" type="string" required="no">
	<cfargument name="nature_of_material" type="string" required="no">

	<!--- set start/end date range terms to same if only one is specified --->
	<cfif isdefined("trans_date") and len(#trans_date#) gt 0>
		<cfif not isdefined("to_trans_date") or len(to_trans_date) is 0>
			<cfset to_trans_date=trans_date>
		</cfif>
		<!--- support search on just a year or pair of years --->
		<cfif len(#trans_date#) EQ 4>
			<cfset trans_date = "#trans_date#-01-01">
		</cfif>
		<cfif len(#to_trans_date#) EQ 4>
			<cfset to_trans_date = "#to_trans_date#-12-31">
		</cfif>
	</cfif>
	<cfif isdefined("date_entered") and len(#date_entered#) gt 0>
		<cfif not isdefined("to_date_entered") or len(to_date_entered) is 0>
			<cfset to_date_entered=date_entered>
		</cfif>
		<!--- support search on just a year or pair of years --->
		<cfif len(#date_entered#) EQ 4>
			<cfset date_entered = "#date_entered#-01-01">
		</cfif>
		<cfif len(#to_date_entered#) EQ 4>
			<cfset to_date_entered = "#to_date_entered#-12-31">
		</cfif>
	</cfif>


	<cfset data = ArrayNew(1)>
	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result" timeout="#Application.query_timeout#">
			SELECT DISTINCT
				transaction_view.transaction_id, 
				transaction_view.transaction_type,
				to_char(trans_date,'YYYY-MM-DD') trans_date,
				to_char(date_entered,'YYYY-MM-DD') date_entered,
				transaction_view.nature_of_material, 
				transaction_view.trans_remarks,
				collection_cde, 
				collection,
				transaction_view.specific_number as specific_number, 
				transaction_view.specific_type as type, 
				transaction_view.status, 
				MCZBASE.COUNT_SHIPMENTS_FOR_TRANS(transaction_view.transaction_id) as shipment_count,
				COUNT_FOREIGNSHIP_FOR_TRANS(transaction_view.transaction_id) as foreign_shipments,
				concattransagent(transaction_view.transaction_id,'entered by') as entered_by,
				concattransagent(transaction_view.transaction_id,'in-house authorized by') authorized_by,
				concattransagent(transaction_view.transaction_id,'outside authorized by') outside_authorized_by,
				concattransagent(transaction_view.transaction_id,'received by') received_by,
				concattransagent(transaction_view.transaction_id,'for use by') for_use_by,
				concattransagent(transaction_view.transaction_id,'in-house contact') inhouse_contact,
				concattransagent(transaction_view.transaction_id,'additional in-house contact') additional_inhouse_contact,
				concattransagent(transaction_view.transaction_id,'additional outside contact') additional_outside_contact,
				concattransagent(transaction_view.transaction_id,'recipient institution') recipient_institution
			FROM 
				MCZBASE.transaction_view
				left join collection on transaction_view.collection_id = collection.collection_id
				<cfif (isdefined("trans_agent_role_1") AND len(trans_agent_role_1) gt 0) OR (isdefined("agent_1") AND len(agent_1) gt 0) >
					left join trans_agent trans_agent_1 on transaction_view.transaction_id = trans_agent_1.transaction_id
				</cfif>
				<cfif not isdefined("agent_1_id") OR len(agent_1_id) eq 0 >
					<cfif isdefined("agent_1") AND len(agent_1) gt 0 >
						left join preferred_agent_name trans_agent_name_1 on trans_agent_1.agent_id = trans_agent_name_1.agent_id
					</cfif>
				</cfif>
				<cfif (isdefined("trans_agent_role_2") AND len(trans_agent_role_2) gt 0) OR (isdefined("agent_2") AND len(agent_2) gt 0) >
					left join trans_agent trans_agent_2 on transaction_view.transaction_id = trans_agent_2.transaction_id
				</cfif>
				<cfif not isdefined("agent_2_id") OR len(agent_2_id) eq 0 >
					<cfif isdefined("agent_2") AND len(agent_2) gt 0 >
						left join preferred_agent_name trans_agent_name_2 on trans_agent_2.agent_id = trans_agent_name_2.agent_id
					</cfif>
				</cfif>
				<cfif (isdefined("trans_agent_role_3") AND len(trans_agent_role_3) gt 0) OR (isdefined("agent_3") AND len(agent_3) gt 0) >
					left join trans_agent trans_agent_3 on transaction_view.transaction_id = trans_agent_3.transaction_id
				</cfif>
				<cfif not isdefined("agent_3_id") OR len(agent_3_id) eq 0 >
					<cfif isdefined("agent_3") AND len(agent_3) gt 0 >
						left join preferred_agent_name trans_agent_name_3 on trans_agent_3.agent_id = trans_agent_name_3.agent_id
					</cfif>
				</cfif>
				<cfif (isdefined("permit_id") AND len(#permit_id#) gt 0) OR (isdefined("permit_type") AND len(#permit_type#) gt 0) OR (isdefined("permit_specific_type") AND len(#permit_specific_type#) gt 0) >
					left join shipment on transaction_view.transaction_id = shipment.transaction_id
					left join permit_shipment on shipment.shipment_id = permit_shipment.shipment_id
					left join permit_trans on transaction_view.transaction_id = permit_trans.transaction_id
				</cfif>
				<cfif (isdefined("permit_type") AND len(#permit_type#) gt 0) OR (isdefined("permit_specific_type") AND len(#permit_specific_type#) gt 0) >
					left join permit on permit_trans.permit_id = permit.permit_id 
					left join permit s_permit on permit_shipment.permit_id = s_permit.permit_id 
				</cfif>
			WHERE
				transaction_view.transaction_id > 0
				<cfif isDefined("number") and len(number) gt 0>
					and specific_number like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#number#%">
				</cfif>
				<cfif isDefined("status") and len(status) gt 0>
					and status like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#status#">
				</cfif>
				<cfif isdefined("trans_remarks") AND len(#trans_remarks#) gt 0>
					AND upper(trans_remarks) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value='%#ucase(trans_remarks)#%'>
				</cfif>
				<cfif isDefined("nature_of_material") and len(nature_of_material) gt 0>
					and upper(nature_of_material) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(nature_of_material)#%">
				</cfif>
				<cfif isDefined("collection_id") and collection_id gt 0>
					and collection.collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_id#">
				</cfif>
				<cfif isdefined("trans_agent_role_1") AND len(trans_agent_role_1) gt 0>
					<cfif isdefined("agent_1") AND agent_1 EQ "NULL">
						AND transaction_view.transaction_id NOT IN (select transaction_id from trans_agent where trans_agent_role = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trans_agent_role_1#">)
					<cfelse>
						AND trans_agent_1.trans_agent_role = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trans_agent_role_1#">
					</cfif>
				</cfif>
				<cfif isdefined("agent_1_id") AND len(agent_1_id) gt 0>
					AND upper(trans_agent_1.agent_id) like <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_1_id#">
				<cfelseif isdefined("agent_1") AND agent_1 EQ "NOT NULL">
					<!--- not need to add not null clause, just skip adding match on name --->
				<cfelseif isdefined("agent_1") AND agent_1 EQ "NULL">
					<!--- need to exclude or query clauses will be contradictory --->
				<cfelseif isdefined("agent_1") AND len(agent_1) gt 0>
					AND upper(trans_agent_name_1.agent_name) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(agent_1)#%" >
				</cfif>
				<cfif isdefined("trans_agent_role_2") AND len(trans_agent_role_2) gt 0>
					<cfif isdefined("agent_2") AND agent_2 EQ "NULL">
						AND transaction_view.transaction_id NOT IN (select transaction_id from trans_agent where trans_agent_role = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trans_agent_role_2#">)
					<cfelse>
						AND trans_agent_2.trans_agent_role = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trans_agent_role_2#">
					</cfif>
				</cfif>
				<cfif isdefined("agent_2_id") AND len(agent_2_id) gt 0>
					AND upper(trans_agent_2.agent_id) like <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_2_id#">
				<cfelseif isdefined("agent_2") AND agent_2 EQ "NOT NULL">
					<!--- not need to add not null clause, just skip adding match on name --->
				<cfelseif isdefined("agent_2") AND agent_2 EQ "NULL">
					<!--- need to exclude or query clauses will be contradictory --->
				<cfelseif isdefined("agent_2") AND len(agent_2) gt 0>
					AND upper(trans_agent_name_2.agent_name) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(agent_2)#%" >
				</cfif>
				<cfif isdefined("trans_agent_role_3") AND len(trans_agent_role_3) gt 0>
					<cfif isdefined("agent_3") AND agent_3 EQ "NULL">
						AND transaction_view.transaction_id NOT IN (select transaction_id from trans_agent where trans_agent_role = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trans_agent_role_3#">)
					<cfelse>
						AND trans_agent_3.trans_agent_role = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trans_agent_role_3#">
					</cfif>
				</cfif>
				<cfif isdefined("agent_3_id") AND len(agent_3_id) gt 0>
					AND upper(trans_agent_3.agent_id) like <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_3_id#">
				<cfelseif isdefined("agent_3") AND agent_3 EQ "NOT NULL">
					<!--- not need to add not null clause, just skip adding match on name --->
				<cfelseif isdefined("agent_3") AND agent_3 EQ "NULL">
					<!--- need to exclude or query clauses will be contradictory --->
				<cfelseif isdefined("agent_3") AND len(agent_3) gt 0>
					AND upper(trans_agent_name_3.agent_name) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(agent_3)#%" >
				</cfif>
				<cfif isdefined("trans_date") and len(trans_date) gt 0>
					AND trans_date between 
						to_date(<cfqueryparam cfsqltype="CF_SQL_DATE" value='#dateformat(trans_date, "yyyy-mm-dd")#'>) and
						(to_date(<cfqueryparam cfsqltype="CF_SQL_DATE" value='#dateformat(to_trans_date, "yyyy-mm-dd")#'>) + (86399/86400) )
				</cfif>
				<cfif isdefined("date_entered") and len(date_entered) gt 0>
					AND date_entered between 
						to_date(<cfqueryparam cfsqltype="CF_SQL_DATE" value='#dateformat(date_entered, "yyyy-mm-dd")#'>) and
						(to_date(<cfqueryparam cfsqltype="CF_SQL_DATE" value='#dateformat(to_date_entered, "yyyy-mm-dd")#'>) + (86399/86400) )
				</cfif>
				<cfif isdefined("permit_id") AND len(#permit_id#) gt 0>
					AND ( 
						permit_trans.permit_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#permit_id#">
						OR
						permit_shipment.permit_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#permit_id#">
					)
				</cfif>
				<cfif  isdefined("permit_type") and len(#permit_type#) gt 0>
					AND (permit.permit_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#permit_type#">
						OR s_permit.permit_Type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#permit_type#">)
				</cfif>
				<cfif  isdefined("permit_specific_type") and len(#permit_specific_type#) gt 0>
					AND (permit.specific_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#permit_specific_type#">
						OR s_permit.specific_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#permit_specific_type#">)
				</cfif>
				<cfif  isdefined("shipment_count") and len(#shipment_count#) gt 0>
					<cfif shipment_count IS "0">
						AND transaction_view.transaction_id NOT IN
							(select transaction_id from shipment)
					<cfelseif shipment_count IS "1">
						AND MCZBASE.COUNT_SHIPMENTS_FOR_TRANS(transaction_view.transaction_id) = 1
					<cfelseif shipment_count IS "1+">
						AND transaction_view.transaction_id IN
							(select transaction_id from shipment)
					<cfelseif shipment_count IS "2+">
						AND MCZBASE.COUNT_SHIPMENTS_FOR_TRANS(transaction_view.transaction_id) > 1
					<cfelseif shipment_count IS "3+">
						AND MCZBASE.COUNT_SHIPMENTS_FOR_TRANS(transaction_view.transaction_id) > 2
					</cfif>
				</cfif>
				<cfif  isdefined("foreign_shipments") and len(#foreign_shipments#) gt 0>
					<cfif foreign_shipments IS "0">
						AND transaction_view.transaction_id NOT IN
							(select transaction_id from shipment where foreign_shipment_fg = 1)
					<cfelseif foreign_shipments IS "1+">
						AND transaction_view.transaction_id IN
							(select transaction_id from shipment where foreign_shipment_fg = 1)
					</cfif>
				</cfif>
			ORDER BY transaction_view.transaction_type, collection_cde, trans_date
		</cfquery>
		<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfswitch expression="#search.transaction_type#">
				<!--- NOTE: Leading / is included below in id_link assembly --->
				<cfcase value="loan"><cfset targetform = "transactions/Loan.cfm?action=editLoan&"></cfcase>
				<cfcase value="accn"><cfset targetform = "transactions/Accession.cfm?action=edit&"></cfcase>
				<cfcase value="borrow"><cfset targetform = "transactions/Borrow.cfm?action=edit&"></cfcase>
				<cfcase value="deaccession"><cfset targetform = "transactions/Deaccession.cfm?action=edit&"></cfcase>
			</cfswitch>
			<cfset row = StructNew()>
			<cfloop list="#ArrayToList(search.getColumnNames())#" index="col" >
				<cfset row["#lcase(col)#"] = "#search[col][currentRow]#">
			</cfloop>
			<cfset row["id_link"] = "<a href='/#targetform#transaction_id=#search.transaction_id#' target='_blank'>#search.specific_number#</a>">
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
	<cfreturn #serializeJSON(data)#>
</cffunction>


<!---   Function getLoans  --->
<cffunction name="getLoans" access="remote" returntype="any" returnformat="json">
	<cfargument name="number" type="string" required="no">
	<cfargument name="loan_type" type="string" required="no">
	<cfargument name="loan_status" type="string" required="no">
	<cfargument name="loan_instructions" type="string" required="no">
	<cfargument name="loan_description" type="string" required="no">
	<cfargument name="trans_remarks" type="string" required="no">
	<cfargument name="nature_of_material" type="string" required="no">
	<cfargument name="collection_id" type="numeric" required="no">
	<cfargument name="permit_type" type="string" required="no">
	<cfargument name="permit_specific_type" type="string" required="no">
	<cfargument name="permit_num" type="string" required="no">
	<cfargument name="permit_id" type="string" required="no">
	<cfargument name="return_due_date" type="string" required="no">
	<cfargument name="to_return_due_date" type="string" required="no">
	<cfargument name="closed_date" type="string" required="no">
	<cfargument name="to_closed_date" type="string" required="no">
	<cfargument name="trans_date" type="string" required="no">
	<cfargument name="to_trans_date" type="string" required="no">
	<cfargument name="date_entered" type="string" required="no">
	<cfargument name="to_date_entered" type="string" required="no">
	<cfargument name="trans_agent_role_1" type="string" required="no">
	<cfargument name="agent_1" type="string" required="no">
	<cfargument name="agent_1_id" type="string" required="no">
	<cfargument name="trans_agent_role_2" type="string" required="no">
	<cfargument name="agent_2" type="string" required="no">
	<cfargument name="agent_2_id" type="string" required="no">
	<cfargument name="trans_agent_role_3" type="string" required="no">
	<cfargument name="agent_3" type="string" required="no">
	<cfargument name="agent_3_id" type="string" required="no">
	<cfargument name="collection_object_id" type="string" required="no">
	<cfargument name="specimen_guid" type="string" required="no">
	<cfargument name="parent_loan_number" type="string" required="no">
	<cfargument name="insurance_value" type="string" required="no">
	<cfargument name="insurance_maintained_by" type="string" required="no">
	<cfargument name="shipment_count" type="string" required="no">
	<cfargument name="foreign_shipments" type="string" required="no">
	<!--- in original API, no longer supported --->
	<!--- notClosed=1 use loan_status = 'not closed' --->
	<!--- in original API, not yet supported --->
	<!--- rec_agent, searching by substring on agent name --->
	<!--- ent_agent, searching by substring on agent name --->
	<!--- auth_agent, searching by substring on agent name --->

	<!--- If provided with sppecimen guids, look up part collection object ids for lookup --->
	<cfif not isdefined("collection_object_id") ><cfset collection_object_id = ""></cfif>
	<cfif (isdefined("specimen_guid") AND len(#specimen_guid#) gt 0) >
		<cfquery name="guidSearch" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="guidSearch_result" timeout="#Application.query_timeout#">
			select specimen_part.collection_object_id as part_coll_obj_id 
			from 
				#session.flatTableName# flat left join specimen_part on flat.collection_object_id = specimen_part.derived_from_cat_item
			where
				flat.guid in ( <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#specimen_guid#" list="yes"> )
		</cfquery>
		<cfif guidSearch.recordcount EQ 0 and len(collection_object_id) EQ 0>
			<!--- handle case of a search for a guid which does not exist --->
			<!--- this collection object id won't exist, so including it will include an AND clause with no match, preventing all records from being returned. --->
			<cfset collection_object_id = "-1">
		</cfif>
		<cfloop query="guidSearch">
			<cfif not listContains(collection_object_id,guidSearch.part_coll_obj_id)>
				<cfif len(collection_object_id) EQ 0>
					<cfset collection_object_id = guidSearch.part_coll_obj_id>
				<cfelse>
					<cfset collection_object_id = collection_object_id & "," & guidSearch.part_coll_obj_id>
				</cfif>
			</cfif>
		</cfloop>
	</cfif>

	<!--- set start/end date range terms to same if only one is specified --->
	<cfif isdefined("return_due_date") and len(return_due_date) gt 0>
		<cfif not isdefined("to_return_due_date") or len(to_return_due_date) is 0>
			<cfset to_return_due_date=return_due_date>
		</cfif>
		<!--- support search on just a year or pair of years --->
		<cfif len(#return_due_date#) EQ 4>
			<cfset return_due_date = "#return_due_date#-01-01">
		</cfif>
		<cfif len(#to_return_due_date#) EQ 4>
			<cfset to_return_due_date = "#to_return_due_date#-12-31">
		</cfif>
	</cfif>
	<cfif isdefined("closed_date") and len(closed_date) gt 0>
		<cfif not isdefined("to_closed_date") or len(to_closed_date) is 0>
			<cfset to_closed_date=closed_date>
		</cfif>
		<!--- support search on just a year or pair of years --->
		<cfif len(#closed_date#) EQ 4>
			<cfset closed_date = "#closed_date#-01-01">
		</cfif>
		<cfif len(#to_closed_date#) EQ 4>
			<cfset to_closed_date = "#to_closed_date#-12-31">
		</cfif>
	</cfif>
	<cfif isdefined("trans_date") and len(#trans_date#) gt 0>
		<cfif not isdefined("to_trans_date") or len(to_trans_date) is 0>
			<cfset to_trans_date=trans_date>
		</cfif>
		<!--- support search on just a year or pair of years --->
		<cfif len(#trans_date#) EQ 4>
			<cfset trans_date = "#trans_date#-01-01">
		</cfif>
		<cfif len(#to_trans_date#) EQ 4>
			<cfset to_trans_date = "#to_trans_date#-12-31">
		</cfif>
	</cfif>
	<cfif isdefined("date_entered") and len(#date_entered#) gt 0>
		<cfif not isdefined("to_date_entered") or len(to_date_entered) is 0>
			<cfset to_date_entered=date_entered>
		</cfif>
		<!--- support search on just a year or pair of years --->
		<cfif len(#date_entered#) EQ 4>
			<cfset date_entered = "#date_entered#-01-01">
		</cfif>
		<cfif len(#to_date_entered#) EQ 4>
			<cfset to_date_entered = "#to_date_entered#-12-31">
		</cfif>
	</cfif>

	<!--- do the search --->
	<cfset data = ArrayNew(1)>
	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result" timeout="#Application.query_timeout#">
			select distinct
				trans.transaction_id,
				to_char(trans_date,'YYYY-MM-DD') trans_date,
				to_char(date_entered,'YYYY-MM-DD') date_entered,
				trans_remarks,
				loan.loan_number,
				loan.loan_type loan_type,
				ctloan_type.scope loan_type_scope,
				loan.loan_status,
				loan.loan_instructions,
				loan.loan_description,
				MCZBASE.COUNT_SHIPMENTS_FOR_TRANS(loan.transaction_id) as shipment_count,
				COUNT_FOREIGNSHIP_FOR_TRANS(loan.transaction_id) as foreign_shipments,
				concattransagent(trans.transaction_id,'in-house authorized by') auth_agent,
				concattransagent(trans.transaction_id,'entered by') ent_agent,
				concattransagent(trans.transaction_id,'received by') rec_agent,
				concattransagent(trans.transaction_id,'for use by') foruseby_agent,
				concattransagent(trans.transaction_id,'in-house contact') inHouse_agent,
				concattransagent(trans.transaction_id,'additional in-house contact') addInhouse_agent,
				concattransagent(trans.transaction_id,'additional outside contact') addOutside_agent,
				concattransagent(trans.transaction_id,'recipient institution') recip_inst,
				nature_of_material,
				to_char(loan.return_due_date,'YYYY-MM-DD') return_due_date,
				loan.return_due_date - trunc(sysdate) dueindays,
				to_char(loan.closed_date, 'YYYY-MM-DD') closed_date,
				project_name,
				project.project_id pid,
				collection.collection,
				collection.collection_cde,
				MCZBASE.count_catitems_for_loan(trans.transaction_id) as item_count,
				MCZBASE.count_citations_for_loan(trans.transaction_id) as citation_count
			from
				loan
				left join trans on loan.transaction_id = trans.transaction_id
				left join collection on trans.collection_id = collection.collection_id
				left join project_trans on trans.transaction_id = project_trans.transaction_id
				left join project on project_trans.project_id = project.project_id
				left join permit_trans on loan.transaction_id = permit_trans.transaction_id
				left join permit on permit_trans.permit_id = permit.permit_id 
				left join ctloan_type on loan.loan_type= ctloan_type.loan_type
				<cfif (isdefined("trans_agent_role_1") AND len(trans_agent_role_1) gt 0) OR (isdefined("agent_1") AND len(agent_1) gt 0) >
					left join trans_agent trans_agent_1 on trans.transaction_id = trans_agent_1.transaction_id
				</cfif>
				<cfif not isdefined("agent_1_id") OR len(agent_1_id) eq 0 >
					<cfif isdefined("agent_1") AND len(agent_1) gt 0 >
						left join preferred_agent_name trans_agent_name_1 on trans_agent_1.agent_id = trans_agent_name_1.agent_id
					</cfif>
				</cfif>
				<cfif (isdefined("trans_agent_role_2") AND len(trans_agent_role_2) gt 0) OR (isdefined("agent_2") AND len(agent_2) gt 0) >
					left join trans_agent trans_agent_2 on trans.transaction_id = trans_agent_2.transaction_id
				</cfif>
				<cfif not isdefined("agent_2_id") OR len(agent_2_id) eq 0 >
					<cfif isdefined("agent_2") AND len(agent_2) gt 0 >
						left join preferred_agent_name trans_agent_name_2 on trans_agent_2.agent_id = trans_agent_name_2.agent_id
					</cfif>
				</cfif>
				<cfif (isdefined("trans_agent_role_3") AND len(trans_agent_role_3) gt 0) OR (isdefined("agent_3") AND len(agent_3) gt 0) >
					left join trans_agent trans_agent_3 on trans.transaction_id = trans_agent_3.transaction_id
				</cfif>
				<cfif not isdefined("agent_3_id") OR len(agent_3_id) eq 0 >
					<cfif isdefined("agent_3") AND len(agent_3) gt 0 >
						left join preferred_agent_name trans_agent_name_3 on trans_agent_3.agent_id = trans_agent_name_3.agent_id
					</cfif>
				</cfif>
				<cfif (isdefined("collection_object_id") AND len(#collection_object_id#) gt 0) OR (isdefined("part_name") AND len(part_name) gt 0) or (isdefined("coll_obj_disposition") AND len(coll_obj_disposition) gt 0) OR (isdefined("sovereign_nation") AND len(#sovereign_nation#) gt 0) >
					left join loan_item on loan.transaction_id = loan_item.transaction_id
				</cfif>
				<cfif (isdefined("part_name") AND len(part_name) gt 0) or (isdefined("coll_obj_disposition") AND len(coll_obj_disposition) gt 0) OR (isdefined("sovereign_nation") AND len(#sovereign_nation#) gt 0) >
					left join loan_item on loan.transaction_id=loan_item.transaction_id 
					left join coll_object on loan_item.collection_object_id=coll_object.collection_object_id
					left join specimen_part on coll_object.collection_object_id = specimen_part.collection_object_id 
					<cfif isdefined("sovereign_nation") AND len(#sovereign_nation#) gt 0 >
						left join cataloged_item cat_coll_object on specimen_part.derived_from_cat_item = cat_coll_object.collection_object_id
						left join collecting_event on cat_coll_object.collecting_event_id = collecting_event.collecting_event_id
						left join locality on collecting_event.locality_id = locality.locality_id
					</cfif>
				</cfif>
				<cfif (isdefined("permit_id") AND len(#permit_id#) gt 0) OR (isdefined("permit_type") AND len(#permit_type#) GT 0) OR (isdefined("permit_specific_type") AND len(#permit_specific_type#) GT 0) >
					left join shipment on loan.transaction_id = shipment.transaction_id
					left join permit_shipment on shipment.shipment_id = permit_shipment.shipment_id
					left join permit permit_from_shipment on  permit_shipment.permit_id = permit_from_shipment.permit_id
				</cfif>
				<cfif isdefined("parent_loan_number") AND len(parent_loan_number) gt 0 >
					left join loan_relations on loan.transaction_id = loan_relations.related_transaction_id
					left join loan parent_loan on loan_relations.transaction_id = parent_loan.transaction_id
				</cfif>
				<cfif (isdefined("country_cde") AND len(country_cde) gt 0) OR (isdefined("formatted_addr") AND len(formatted_addr) gt 0) >
					left join shipment on trans.transaction_id = shipment.transaction_id
					left join addr on shipment.shipped_to_addr_id = addr.addr_id
				</cfif>
			where
				trans.transaction_id is not null
				<cfif isdefined("loan_number") AND len(#loan_number#) gt 0>
					AND upper(loan.loan_number) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(loan_number)#%">
				</cfif>
				<cfif isdefined("collection_id") AND collection_id gt 0>
					AND trans.collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_id#">
				</cfif>
				<cfif isdefined("permit_id") AND len(#permit_id#) gt 0>
					AND ( 
						permit.permit_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#permit_id#">
						OR
						permit_shipment.permit_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#permit_id#">
					)
				</cfif>
				<cfif  isdefined("permit_type") and len(#permit_type#) gt 0>
					AND ( 
						permit.permit_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#permit_type#">
						OR
						permit_from_shipment.permit_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#permit_type#">
					)
				</cfif>
				<cfif  isdefined("permit_specific_type") and len(#permit_specific_type#) gt 0>
					AND ( 
						permit.specific_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#permit_specific_type#">
						OR
						permit_from_shipment.specific_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#permit_specific_type#">
					)
				</cfif>
				<cfif isdefined("loan_type") AND len(#loan_type#) gt 0>
					AND loan.loan_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value='#loan_type#'>
				</cfif>
				<cfif isdefined("loan_status") AND len(#loan_status#) gt 0>
					<cfif loan_status eq "not closed">
						AND loan.loan_status <> 'closed'
					<cfelse>
						 AND loan.loan_status = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value='#loan_status#'>
					</cfif>
				</cfif>
				<cfif isdefined("loan_instructions") AND len(#loan_instructions#) gt 0>
					AND upper(loan.loan_instructions) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value='%#ucase(loan_instructions)#%'>
				</cfif>
				<cfif isdefined("trans_remarks") AND len(#trans_remarks#) gt 0>
					AND upper(trans_remarks) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value='%#ucase(trans_remarks)#%'>
				</cfif>
				<cfif isdefined("loan_description") AND len(#loan_description#) gt 0>
					AND upper(loan.loan_description) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value='%#ucase(loan_description)#%'>
				</cfif>
				<cfif isdefined("nature_of_material") AND len(#nature_of_material#) gt 0>
					AND upper(nature_of_material) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value='%#ucase(nature_of_material)#%'>
				</cfif>
				<cfif isdefined("return_due_date") and len(return_due_date) gt 0>
					AND loan.return_due_date between 
						to_date(<cfqueryparam cfsqltype="CF_SQL_DATE" value='#dateformat(return_due_date, "yyyy-mm-dd")#'>) and
						(to_date(<cfqueryparam cfsqltype="CF_SQL_DATE" value='#dateformat(to_return_due_date, "yyyy-mm-dd")#'>) + (86399/86400) )
				</cfif>
				<cfif isdefined("closed_date") and len(closed_date) gt 0>
					AND loan.closed_date between 
						to_date(<cfqueryparam cfsqltype="CF_SQL_DATE" value='#dateformat(closed_date, "yyyy-mm-dd")#'>) and
						(to_date(<cfqueryparam cfsqltype="CF_SQL_DATE" value='#dateformat(to_closed_date, "yyyy-mm-dd")#'>) + (86399/86400) )
				</cfif>
				<cfif isdefined("trans_date") and len(trans_date) gt 0>
					AND trans_date between 
						to_date(<cfqueryparam cfsqltype="CF_SQL_DATE" value='#dateformat(trans_date, "yyyy-mm-dd")#'>) and
						(to_date(<cfqueryparam cfsqltype="CF_SQL_DATE" value='#dateformat(to_trans_date, "yyyy-mm-dd")#'>) + (86399/86400) )
				</cfif>
				<cfif isdefined("date_entered") and len(date_entered) gt 0>
					AND date_entered between 
						to_date(<cfqueryparam cfsqltype="CF_SQL_DATE" value='#dateformat(date_entered, "yyyy-mm-dd")#'>) and
						(to_date(<cfqueryparam cfsqltype="CF_SQL_DATE" value='#dateformat(to_date_entered, "yyyy-mm-dd")#'>) + (86399/86400) )
				</cfif>
				<cfif isdefined("trans_agent_role_1") AND len(trans_agent_role_1) gt 0>
					<cfif isdefined("agent_1") AND agent_1 EQ "NULL">
						AND trans.transaction_id NOT IN (select transaction_id from trans_agent where trans_agent_role = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trans_agent_role_1#">)
					<cfelse>
						AND trans_agent_1.trans_agent_role = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trans_agent_role_1#">
					</cfif>
				</cfif>
				<cfif isdefined("agent_1_id") AND len(agent_1_id) gt 0>
					AND upper(trans_agent_1.agent_id) like <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_1_id#">
				<cfelseif isdefined("agent_1") AND agent_1 EQ "NOT NULL">
					<!--- not need to add not null clause, just skip adding match on name --->
				<cfelseif isdefined("agent_1") AND agent_1 EQ "NULL">
					<!--- need to exclude or query clauses will be contradictory --->
				<cfelseif isdefined("agent_1") AND len(agent_1) gt 0>
					AND upper(trans_agent_name_1.agent_name) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(agent_1)#%" >
				</cfif>
				<cfif isdefined("trans_agent_role_2") AND len(trans_agent_role_2) gt 0>
					<cfif isdefined("agent_2") AND agent_2 EQ "NULL">
						AND trans.transaction_id NOT IN (select transaction_id from trans_agent where trans_agent_role = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trans_agent_role_2#">)
					<cfelse>
						AND trans_agent_2.trans_agent_role = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trans_agent_role_2#">
					</cfif>
				</cfif>
				<cfif isdefined("agent_2_id") AND len(agent_2_id) gt 0>
					AND upper(trans_agent_2.agent_id) like <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_2_id#">
				<cfelseif isdefined("agent_2") AND agent_2 EQ "NOT NULL">
					<!--- not need to add not null clause, just skip adding match on name --->
				<cfelseif isdefined("agent_2") AND agent_2 EQ "NULL">
					<!--- need to exclude or query clauses will be contradictory --->
				<cfelseif isdefined("agent_2") AND len(agent_2) gt 0>
					AND upper(trans_agent_name_2.agent_name) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(agent_2)#%" >
				</cfif>
				<cfif isdefined("trans_agent_role_3") AND len(trans_agent_role_3) gt 0>
					<cfif isdefined("agent_3") AND agent_3 EQ "NULL">
						AND trans.transaction_id NOT IN (select transaction_id from trans_agent where trans_agent_role = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trans_agent_role_3#">)
					<cfelse>
						AND trans_agent_3.trans_agent_role = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trans_agent_role_3#">
					</cfif>
				</cfif>
				<cfif isdefined("agent_3_id") AND len(agent_3_id) gt 0>
					AND upper(trans_agent_3.agent_id) like <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_3_id#">
				<cfelseif isdefined("agent_3") AND agent_3 EQ "NOT NULL">
					<!--- not need to add not null clause, just skip adding match on name --->
				<cfelseif isdefined("agent_3") AND agent_3 EQ "NULL">
					<!--- need to exclude or query clauses will be contradictory --->
				<cfelseif isdefined("agent_3") AND len(agent_3) gt 0>
					AND upper(trans_agent_name_3.agent_name) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(agent_3)#%" >
				</cfif>
				<cfif (isdefined("part_name") AND len(part_name) gt 0) or (isdefined("coll_obj_disposition") AND len(coll_obj_disposition) gt 0)>
					<cfif isdefined("part_name") AND len(part_name) gt 0>
						<cfif not isdefined("part_name_oper")><cfset part_name_oper='is'></cfif>
						<cfif part_name_oper is "is">
							AND specimen_part.part_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#part_name#">
						<cfelse>
							AND upper(specimen_part.part_name) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(part_name)#%">
						</cfif>
					</cfif>
					<cfif isdefined("coll_obj_disposition") AND len(coll_obj_disposition) gt 0>
						<cfif not isdefined("part_disp_oper")><cfset part_disp_oper='is'></cfif>
						<cfif part_disp_oper is "is">
							and coll_object.coll_obj_disposition IN ( <cfqueryparam list="yes" cfsqltype="CF_SQL_VARCHAR" value="#coll_obj_disposition#" > )
						<cfelse>
							and coll_object.coll_obj_disposition NOT IN ( <cfqueryparam list="yes" cfsqltype="CF_SQL_VARCHAR" value="#coll_obj_disposition#" > )
						</cfif>
					</cfif>
				</cfif>
				<cfif isdefined("collection_object_id") AND len(#collection_object_id#) gt 0 >
					and loan_item.collection_object_id IN ( <cfqueryparam list="yes" cfsqltype="CF_SQL_VARCHAR" value="#collection_object_id#" > )
				</cfif>
				<cfif isdefined("parent_loan_number") AND len(parent_loan_number) gt 0 >
					AND loan_relations.relation_type = 'Subloan'
					AND parent_loan.loan_number like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#parent_loan_number#">
				</cfif>
				<cfif isdefined("insurance_value") AND len(#insurance_value#) gt 0>
					<cfif insurance_value EQ 'NULL'>
						AND loan.insurance_value is NULL
					<cfelseif insurance_value EQ 'NOT NULL'>
						AND loan.insurance_value is NOT NULL
					<cfelse>
						AND upper(loan.insurance_value) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(insurance_value)#%">
					</cfif>
				</cfif>
				<cfif isdefined("insurance_maintained_by") AND len(#insurance_maintained_by#) gt 0>
					<cfif insurance_maintained_by EQ 'NULL'>
						AND loan.insurance_maintained_by is NULL
					<cfelseif insurance_maintained_by EQ 'NOT NULL'>
						AND loan.insurance_maintained_by is NOT NULL
					<cfelse>
						AND upper(loan.insurance_maintained_by) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(insurance_maintained_by)#%">
					</cfif>
				</cfif>
				<cfif  isdefined("shipment_count") and len(#shipment_count#) gt 0>
					<cfif shipment_count IS "0">
						AND loan.transaction_id NOT IN
							(select transaction_id from shipment)
					<cfelseif shipment_count IS "1">
						AND MCZBASE.COUNT_SHIPMENTS_FOR_TRANS(loan.transaction_id) = 1
					<cfelseif shipment_count IS "1+">
						AND loan.transaction_id IN
							(select transaction_id from shipment)
					<cfelseif shipment_count IS "2+">
						AND MCZBASE.COUNT_SHIPMENTS_FOR_TRANS(loan.transaction_id) > 1
					<cfelseif shipment_count IS "3+">
						AND MCZBASE.COUNT_SHIPMENTS_FOR_TRANS(loan.transaction_id) > 2
					</cfif>
				</cfif>
				<cfif  isdefined("foreign_shipments") and len(#foreign_shipments#) gt 0>
					<cfif foreign_shipments IS "0">
						AND loan.transaction_id NOT IN
							(select transaction_id from shipment where foreign_shipment_fg = 1)
					<cfelseif foreign_shipments IS "1+">
						AND loan.transaction_id IN
							(select transaction_id from shipment where foreign_shipment_fg = 1)
					</cfif>
				</cfif>
				<cfif isdefined("sovereign_nation") AND len(#sovereign_nation#) gt 0 >
					<cfif left(sovereign_nation,1) is "=">
						AND upper(locality.sovereign_nation) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(sovereign_nation,len(sovereign_nation)-1))#">
					<cfelseif left(sovereign_nation,1) is "$">
						AND soundex(locality.sovereign_nation) = soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(sovereign_nation,len(sovereign_nation)-1))#">)
					<cfelseif left(sovereign_nation,2) is "!$">
						AND soundex(locality.sovereign_nation) <> soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(sovereign_nation,len(sovereign_nation)-2))#">)
					<cfelseif left(sovereign_nation,1) is "!">
						AND upper(locality.sovereign_nation) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(sovereign_nation,len(sovereign_nation)-1))#">
					<cfelse>
						<cfif find(',',sovereign_nation) GT 0>
							AND upper(locality.sovereign_nation) in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(sovereign_nation)#" list="yes"> )
						<cfelse>
							AND upper(locality.sovereign_nation) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(sovereign_nation)#%">
						</cfif>
					</cfif>
				</cfif>
				<cfif isdefined("country_cde") AND len(country_cde) gt 0 >
					<cfif left(country_cde,1) is "=">
						AND upper(addr.country_cde) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(country_cde,len(country_cde)-1))#">
					<cfelseif left(country_cde,1) is "$">
						AND soundex(addr.country_cde) = soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(country_cde,len(country_cde)-1))#">)
					<cfelseif left(country_cde,2) is "!$">
						AND soundex(addr.country_cde) <> soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(country_cde,len(country_cde)-2))#">)
					<cfelseif left(country_cde,1) is "!">
						AND upper(addr.country_cde) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(country_cde,len(country_cde)-1))#">
					<cfelseif country_cde EQ 'NULL'>
						AND addr.country_cde IS NULL
					<cfelseif country_cde EQ 'NOT NULL'>
						AND addr.country_cde IS NOT NULL
					<cfelse>
						<cfif find(',',country_cde) GT 0>
							AND upper(addr.country_cde) in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(country_cde)#" list="yes"> )
						<cfelse>
							AND upper(addr.country_cde) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(country_cde)#%">
						</cfif>
					</cfif>
				</cfif>
				<cfif isdefined("formatted_addr") AND len(formatted_addr) gt 0 >
					AND upper(addr.formatted_addr) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(formatted_addr)#%">
				</cfif>
			ORDER BY to_number(regexp_substr (loan.loan_number, '^[0-9]+', 1, 1)), to_number(regexp_substr (loan.loan_number, '[0-9]+', 1, 2)), loan.loan_number
		</cfquery>

<!--- in original API, not yet supported, could be added, replaced by autocomplete on agent name filling in agent id for arbitrary roles. 

	<cfif isdefined("rec_agent") AND len(#rec_agent#) gt 0>
		<cfset sql = "#sql# AND upper(recAgnt.agent_name) LIKE '%#ucase(escapeQuotes(rec_agent))#%'">
	</cfif>
	changed to in-house authorized by
	<cfif isdefined("auth_agent") AND len(#auth_agent#) gt 0>
		<cfset sql = "#sql# AND upper(authAgnt.agent_name) LIKE '%#ucase(escapeQuotes(auth_agent))#%'">
	</cfif>
	<cfif isdefined("ent_agent") AND len(#ent_agent#) gt 0>
		<cfset sql = "#sql# AND upper(entAgnt.agent_name) LIKE '%#ucase(escapeQuotes(ent_agent))#%'">
	</cfif>

--->

	<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfloop list="#ArrayToList(search.getColumnNames())#" index="col" >
				<cfset row["#lcase(col)#"] = "#search[col][currentRow]#">
			</cfloop>
			<cfset row["id_link"] = "<a href='/transactions/Loan.cfm?action=editLoan&transaction_id=#search.transaction_id#' target='_blank'>#search.loan_number#</a>">
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
	<cfreturn #serializeJSON(data)#>
</cffunction>

<cffunction name="getPermits" access="remote" returntype="any" returnformat="json">
	<cfargument name="IssuedByAgent" default="">
	<cfargument name="IssuedToAgent" default="">
	<cfargument name="issued_Date" default="">
	<cfargument name="renewed_Date" default="">
	<cfargument name="exp_Date" default="">
	<cfargument name="permit_Num" default="">
	<cfargument name="permit_Type" default="">
	<cfargument name="specific_type" default="">
	<cfargument name="permit_title" default="">
	<cfargument name="permit_remarks" default="">
	<cfargument name="permit_id" default="">
	<cfargument name="ContactAgent" default="">
	<cfargument name="restriction_summary" default="">
	<cfargument name="benefits_summary" default="">
	<cfargument name="benefits_provided" default="">

	<cfset data = ArrayNew(1)>
	<cftry>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result" timeout="#Application.query_timeout#">
			select distinct permit.permit_id,
				issuedBy.agent_name as IssuedByAgent,
				issuedTo.agent_name as IssuedToAgent,
				Contact.agent_name as ContactAgent,
				issued_Date,
				renewed_Date,
				exp_Date,
				permit_Num,
				permit_Type,
				specific_type,
				permit_title,
				permit_remarks,
				MCZBASE.get_media_URI_for_relation(permit.permit_id, 'shows permit','application/pdf') as pdf
			from
				permit  
				left join preferred_agent_name issuedTo on permit.issued_to_agent_id = issuedTo.agent_id
				left join preferred_agent_name issuedBy on permit.issued_by_agent_id = issuedBy.agent_id
				left join preferred_agent_name Contact on permit.contact_agent_id = Contact.agent_id
			where
				permit.permit_id is not null 
				<cfif isdefined("ISSUED_BY_AGENT_ID") and len(#ISSUED_BY_AGENT_ID#) gt 0>
					AND ISSUED_BY_AGENT_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#ISSUED_BY_AGENT_ID#">
				<cfelseif isdefined("IssuedByAgent") AND len(#IssuedByAgent#) gt 0>
					AND upper(issuedBy.agent_name) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(IssuedByAgent)#%">
				</cfif>
				<cfif isdefined("ISSUED_TO_AGENT_ID") and len(#ISSUED_TO_AGENT_ID#) gt 0>
					AND ISSUED_TO_AGENT_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#ISSUED_TO_AGENT_ID#">
				<cfelseif isdefined("IssuedToAgent") AND len(#IssuedToAgent#) gt 0>
					AND upper(issuedTo.agent_name) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(IssuedToAgent)#%">
				</cfif>
				<cfif isdefined("CONTACT_AGENT_ID") and len(#CONTACT_AGENT_ID#) gt 0>
					AND CONTACT_AGENT_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#CONTACT_AGENT_ID#">
				<cfelseif isdefined("ContactAgent") AND len(#ContactAgent#) gt 0>
					AND upper(Contact.agent_name) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(ContactAgent)#%">
				</cfif>
				<cfif isdefined("issued_date") AND len(#issued_date#) gt 0>
					<cfif len(#issued_date#) EQ 4>
						<cfif NOT isdefined("issued_until_date") OR len(#issued_until_date#) EQ 0>
							<cfset issued_until_date = "#issued_date#-12-31">
						</cfif>
						<cfset issued_date = "#issued_date#-01-01">
						<cfif isdefined("issued_until_date") AND  len(#issued_until_date#) EQ 4>
							<cfset issued_until_date = "#issued_until_date#-12-31">
						</cfif>
					</cfif>
					<cfif isdefined("issued_until_date") AND len(#issued_until_date#) gt 0>
						AND upper(issued_date) 
							between to_date(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#issued_date#">, 'yyyy-mm-dd')
							and (to_date(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#issued_until_date#">, 'yyyy-mm-dd') + (86399/86400) )
					<cfelse>
						AND upper(issued_date) like to_date(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#issued_date#">, 'yyyy-mm-dd')
					</cfif>
				<cfelse>
					<cfif isdefined("issued_until_date") AND len(#issued_until_date#) gt 0>
						AND issued_date <= to_date(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#issued_until_date#">, 'yyyy-mm-dd')
					</cfif>
				</cfif>
				<cfif isdefined("renewed_date") AND len(#renewed_date#) gt 0>
					<cfif len(#renewed_date#) EQ 4>
						<cfif NOT isdefined("renwewed_until_date") OR len(#renewed_until_date#) EQ 0>
							<cfset renewed_until_date = "#renewed_date#-12-31">
						</cfif>
						<cfset renewed_date = "#renewed_date#-01-01">
						<cfif ifdefined("renewed_until_date") AND len(#renewed_until_date#) EQ 4>
							<cfset renewed_until_date = "#renewed_until_date#-12-31">
						</cfif>
					</cfif>
					<cfif isdefined("renewed_until_date") OR len(#renewed_until_date#) gt 0>
						AND upper(renewed_date)
							between to_date(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#renewed_date#">, 'yyyy-mm-dd')
							and (to_date(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#renewed_until_date#">, 'yyyy-mm-dd') + (86399/86400) )
					<cfelse>
						AND upper(renewed_date) like to_date(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#renewed_date#">, 'yyyy-mm-dd')
					</cfif>
				<cfelse>
					<cfif isdefined("renewed_until_date") AND len(#renewed_until_date#) gt 0>
						AND renewed_date <= to_date(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#renewed_until_date#">, 'yyyy-mm-dd')
					</cfif>
				</cfif>
				<cfif isdefined("exp_date") AND len(#exp_date#) gt 0>
					<cfif len(#exp_date#) EQ 4>
						<cfif NOT isdefined("exp_until_date") OR len(#exp_until_date#) EQ 0>
							<cfset exp_until_date = "#exp_date#-12-31">
						</cfif>
						<cfset exp_date = "#exp_date#-01-01">
						<cfif isdefined("exp_until_date") AND len(#exp_until_date#) EQ 4>
							<cfset exp_until_date = "#exp_until_date#-12-31">
						</cfif>
					</cfif>
					<cfif isdefined("exp_until_date") AND len(#exp_until_date#) gt 0>
						AND upper(exp_date) 
							between to_date(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#exp_date#">, 'yyyy-mm-dd')
							and (to_date(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#exp_until_date#">, 'yyyy-mm-dd') + (86399/86400) )
					<cfelse>
						AND upper(exp_date) like to_date(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#exp_date#">, 'yyyy-mm-dd')
					</cfif>
				<cfelse>
					<cfif isdefined("exp_until_date") AND len(#exp_until_date#) gt 0>
						AND exp_date <= to_date(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#exp_until_date#">, 'yyyy-mm-dd')
					</cfif>
				</cfif>
				<cfif isdefined("permit_Num") AND len(#permit_Num#) gt 0>
					AND upper(permit_Num) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(permit_Num)#%">
				</cfif>
				<cfif isdefined("permit_type") AND  len(#permit_type#) gt 0>
					AND permit_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#permit_type#">
				</cfif>
				<cfif isdefined("permit_title") AND len(#permit_title#) gt 0>
					AND upper(permit_title) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(permit_title)#%">
				</cfif>
				<cfif isdefined("specific_type") AND len(#specific_type#) gt 0>
					AND specific_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#specific_type#">
				</cfif>
				<cfif isdefined("permit_remarks") AND len(#permit_remarks#) gt 0>
					AND upper(permit_remarks) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(permit_remarks)#%">
				</cfif>
				<cfif isdefined("permit_id") AND len(#permit_id#) gt 0>
					AND permit_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#permit_id#">
				</cfif>
				<cfif isdefined("restriction_summary") AND len(#restriction_summary#) gt 0>
					<cfif isdefined("restriction_summary") AND restriction_summary EQ "NULL">
						and restriction_summary IS NULL
					<cfelseif isdefined("restriction_summary") AND restriction_summary EQ "NOT NULL">
						and restriction_summary IS NOT NULL
					<cfelse>
						AND upper(restriction_summary) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(restriction_summary)#%">
					</cfif>
				</cfif>
				<cfif isdefined("benefits_summary") AND len(#benefits_summary#) gt 0>
					<cfif isdefined("benefits_summary") AND benefits_summary EQ "NULL">
						and benefits_summary IS NULL
					<cfelseif isdefined("benefits_summary") AND benefits_summary EQ "NOT NULL">
						and benefits_summary IS NOT NULL
					<cfelse>
						AND upper(benefits_summary) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(benefits_summary)#%">
					</cfif>
				</cfif>
				<cfif isdefined("benefits_provided") AND len(#benefits_provided#) gt 0>
					<cfif isdefined("benefits_provided") AND benefits_provided EQ "NULL">
						and benefits_provided IS NULL
					<cfelseif isdefined("benefits_provided") AND benefits_provided EQ "NOT NULL">
						and benefits_provided IS NOT NULL
					<cfelse>
						AND upper(benefits_provided) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(benefits_provided)#%">
					</cfif>
				</cfif>
		</cfquery>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfloop list="#ArrayToList(search.getColumnNames())#" index="col" >
				<cfset row["#lcase(col)#"] = "#search[col][currentRow]#">
			</cfloop>
			<cfset label = trim(search.permit_num)>
			<cfif len(label) EQ 0>
				<cfset label = trim(search.permit_title)>
			</cfif>
			<cfif len(label) EQ 0>
				<cfset label = trim(search.specific_type)>
			</cfif>
			<cfset row["id_link"] = "<a href='/transactions/Permit.cfm?action=edit&permit_id=#search.permit_id#' target='_blank'>#label#</a>">
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
	<cfreturn #serializeJSON(data)#>
</cffunction>

<!--- backing for a accession autocomplete control --->
<cffunction name="getAccessionAutocomplete" access="remote" returntype="any" returnformat="json">
	<cfargument name="term" type="string" required="yes">
	<cfargument name="collection_id" type="string" required="no">
	<cfset data = ArrayNew(1)>

	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result" timeout="#Application.query_timeout#">
			select distinct
				trans.transaction_id,
				to_char(trans_date,'YYYY-MM-DD') trans_date,
				accn_number,
				accn_status,
				concattransagent(trans.transaction_id,'received from') rec_agent,
				collection.collection_cde
			from 
				accn left join trans on accn.transaction_id = trans.transaction_id
				left join collection on trans.collection_id = collection.collection_id
			where 
				upper(accn_number) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(term)#%">
				<cfif isDefined("collection_id") and len(collection_id) GT 0>
					and trans.collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_id#">
				</cfif>
			order by accn_number
		</cfquery>
		<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfset row["id"] = "#search.transaction_id#">
			<cfset row["value"] = "#search.accn_number#" >
			<cfset row["meta"] = "#search.accn_number# (#search.collection_cde# #search.accn_status# #search.trans_date# #search.rec_agent#)" >
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
	<cfreturn #serializeJSON(data)#>
</cffunction>

<!--- backing for a loan autocomplete control --->
<cffunction name="getLoanAutocomplete" access="remote" returntype="any" returnformat="json">
	<cfargument name="term" type="string" required="yes">
	<cfset data = ArrayNew(1)>

	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			SELECT distinct
				trans.transaction_id,
				to_char(trans_date,'YYYY-MM-DD') trans_date,
				loan_number,
				loan_status,
				concattransagent(trans.transaction_id,'received by') rec_agent
			FROM
				loan left join trans on loan.transaction_id = trans.transaction_id
			WHERE 
				upper(loan_number) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(term)#%">
			ORDER BY loan_number
				to_number(regexp_substr (loan.loan_number, '^[0-9]+', 1, 1)), to_number(regexp_substr (loan.loan_number, '[0-9]+', 1, 2)), loan.loan_number
		</cfquery>
		<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfset row["id"] = "#search.transaction_id#">
			<cfset row["value"] = "#search.loan_number#" >
			<cfset row["meta"] = "#search.loan_number# (#search.loan_status# #search.trans_date# #search.rec_agent#)" >
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
	<cfreturn #serializeJSON(data)#>
</cffunction>

<!--- backing for a borrow autocomplete control --->
<cffunction name="getBorrowAutocomplete" access="remote" returntype="any" returnformat="json">
	<cfargument name="term" type="string" required="yes">
	<cfset data = ArrayNew(1)>

	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			select distinct
				trans.transaction_id,
				to_char(trans_date,'YYYY-MM-DD') trans_date,
				borrow_number,
				borrow_status,
				lenders_trans_num_cde,
				concattransagent(trans.transaction_id,'received from') rec_agent
			from 
				borrow left join trans on borrow.transaction_id = trans.transaction_id
			where upper(borrow_number) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(term)#%">
				OR upper(lenders_trans_num_cde) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(term)#%">
			order by 
				regexp_substr(borrow_number,'^[B0-9]+-'), 
				to_number(replace(regexp_substr(borrow_number,'-[0-9]+-'),'-','')), 
				borrow_number
		</cfquery>
		<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfset row["id"] = "#search.transaction_id#">
			<cfset row["value"] = "#search.borrow_number#" >
			<cfset row["meta"] = "#search.borrow_number# (#search.borrow_status# #search.trans_date# #search.rec_agent# #search.lenders_trans_num_cde#)" >
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
	<cfreturn #serializeJSON(data)#>
</cffunction>


<!--- backing for a deaccession autocomplete control --->
<cffunction name="getDeaccessionAutocomplete" access="remote" returntype="any" returnformat="json">
	<cfargument name="term" type="string" required="yes">
	<cfset data = ArrayNew(1)>

	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			select distinct
				trans.transaction_id,
				to_char(trans_date,'YYYY-MM-DD') trans_date,
				deacc_number,
				deacc_status,
				deacc_reason
			from 
				deaccession left join trans on deaccession.transaction_id = trans.transaction_id
			where upper(deacc_number) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(term)#%">
			order by 
				regexp_substr(deacc_number,'^[D0-9]+-'), 
				to_number(replace(regexp_substr(deacc_number,'-[0-9]+-'),'-','')), 
				deacc_number
		</cfquery>
		<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfset row["id"] = "#search.transaction_id#">
			<cfset row["value"] = "#search.deacc_number#" >
			<cfset row["meta"] = "#search.deacc_number# (#search.deacc_status# #search.trans_date# #search.deacc_reason#)" >
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
	<cfreturn #serializeJSON(data)#>
</cffunction>

<!---   Function getAccessions  --->
<cffunction name="getAccessions" access="remote" returntype="any" returnformat="json">
	<cfargument name="accn_number" type="string" required="no">
	<cfargument name="accn_type" type="string" required="no">
	<cfargument name="accn_status" type="string" required="no">
	<cfargument name="trans_remarks" type="string" required="no">
	<cfargument name="nature_of_material" type="string" required="no">
	<cfargument name="collection_id" type="numeric" required="no">
	<cfargument name="permit_num" type="string" required="no">
	<cfargument name="permit_id" type="string" required="no">
	<cfargument name="permit_type" type="string" required="no">
	<cfargument name="permit_specific_type" type="string" required="no">
	<cfargument name="rec_date" type="string" required="no">
	<cfargument name="to_rec_date" type="string" required="no">
	<cfargument name="trans_date" type="string" required="no">
	<cfargument name="to_trans_date" type="string" required="no">
	<cfargument name="date_entered" type="string" required="no">
	<cfargument name="to_date_entered" type="string" required="no">
	<cfargument name="trans_agent_role_1" type="string" required="no">
	<cfargument name="agent_1" type="string" required="no">
	<cfargument name="agent_1_id" type="string" required="no">
	<cfargument name="trans_agent_role_2" type="string" required="no">
	<cfargument name="agent_2" type="string" required="no">
	<cfargument name="agent_2_id" type="string" required="no">
	<cfargument name="trans_agent_role_3" type="string" required="no">
	<cfargument name="agent_3" type="string" required="no">
	<cfargument name="agent_3_id" type="string" required="no">
	<cfargument name="collection_object_id" type="string" required="no">
	<cfargument name="specimen_guid" type="string" required="no">
	<cfargument name="part_name" type="string" required="no">
	<cfargument name="coll_obj_disposition" type="string" required="no">
	<cfargument name="restriction_summary" type="string" required="no">
	<cfargument name="benefits_summary" type="string" required="no">
	<cfargument name="benefits_provided" type="string" required="no">
	<cfargument name="issued_by_id" type="string" required="no">
	<cfargument name="issued_to_id" type="string" required="no">
	<cfargument name="permit_contact_id" type="string" required="no">
	<cfargument name="permit_remarks" type="string" required="no">
	<cfargument name="estimated_count" type="string" required="no">
	<cfargument name="shipment_count" type="string" required="no">
	<cfargument name="foreign_shipments" type="string" required="no">

	<!--- If provided with sppecimen guids, look up part collection object ids for lookup --->
	<cfif not isdefined("collection_object_id") ><cfset collection_object_id = ""></cfif>
	<cfif (isdefined("specimen_guid") AND len(#specimen_guid#) gt 0) >
		<cfquery name="guidSearch" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="guidSearch_result" timeout="#Application.query_timeout#">
			select specimen_part.collection_object_id as part_coll_obj_id 
			from 
				#session.flatTableName# flat left join specimen_part on flat.collection_object_id = specimen_part.derived_from_cat_item
			where
				flat.guid in ( <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#specimen_guid#" list="yes"> )
		</cfquery>
		<cfloop query="guidSearch">
			<cfif not listContains(collection_object_id,guidSearch.part_coll_obj_id)>
				<cfif len(collection_object_id) EQ 0>
					<cfset collection_object_id = guidSearch.part_coll_obj_id>
				<cfelse>
					<cfset collection_object_id = collection_object_id & "," & guidSearch.part_coll_obj_id>
				</cfif>
			</cfif>
		</cfloop>
	</cfif>

	<!--- set start/end date range terms to same if only one is specified --->
	<cfif isdefined("trans_date") and len(#trans_date#) gt 0>
		<cfif not isdefined("to_trans_date") or len(to_trans_date) is 0>
			<cfset to_trans_date=trans_date>
		</cfif>
		<!--- support search on just a year or pair of years --->
		<cfif len(#trans_date#) EQ 4>
			<cfset trans_date = "#trans_date#-01-01">
		</cfif>
		<cfif len(#to_trans_date#) EQ 4>
			<cfset to_trans_date = "#to_trans_date#-12-31">
		</cfif>
	</cfif>
	<cfif isdefined("rec_date") and len(#rec_date#) gt 0>
		<cfif not isdefined("to_rec_date") or len(to_rec_date) is 0>
			<cfset to_rec_date=rec_date>
		</cfif>
		<!--- support search on just a year or pair of years --->
		<cfif len(#rec_date#) EQ 4>
			<cfset rec_date = "#rec_date#-01-01">
		</cfif>
		<cfif len(#to_rec_date#) EQ 4>
			<cfset to_rec_date = "#to_rec_date#-12-31">
		</cfif>
	</cfif>
	<cfif isdefined("date_entered") and len(#date_entered#) gt 0>
		<cfif not isdefined("to_date_entered") or len(to_date_entered) is 0>
			<cfset to_date_entered=date_entered>
		</cfif>
		<!--- support search on just a year or pair of years --->
		<cfif len(#date_entered#) EQ 4>
			<cfset date_entered = "#date_entered#-01-01">
		</cfif>
		<cfif len(#to_date_entered#) EQ 4>
			<cfset to_date_entered = "#to_date_entered#-12-31">
		</cfif>
	</cfif>

	<!--- do the search --->
	<cfset data = ArrayNew(1)>
	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result" timeout="#Application.query_timeout#">
			SELECT distinct
				trans.transaction_id,
				accn_number,
				accn_type,
				nature_of_material,
				to_char(received_date,'YYYY-MM-DD') as received_date,
				to_char(trans_date,'YYYY-MM-DD') as accession_date,
				to_char(date_entered,'YYYY-MM-DD') as date_entered,
				accn_status,
				trans_remarks,
				collection,
				collection.collection_cde,
				project_name,
				project.project_id pid,
				estimated_count,
				MCZBASE.get_permits_for_trans(trans.transaction_id) permits,
				MCZBASE.count_shipments_for_trans(trans.transaction_id) shipment_count,
				COUNT_FOREIGNSHIP_FOR_TRANS(trans.transaction_id) as foreign_shipments,
				MCZBASE.count_catitems_for_accn(trans.transaction_id) item_count,
				concattransagent(trans.transaction_id,'entered by') ent_agent,
				concattransagent(trans.transaction_id,'received from') rec_from_agent,
				concattransagent(trans.transaction_id,'in-house authorized by') auth_agent,
				concattransagent(trans.transaction_id,'outside authorized by') outside_auth_agent,
				concattransagent(trans.transaction_id,'received by') rec_agent,
				concattransagent(trans.transaction_id,'in-house contact') inHouse_agent,
				concattransagent(trans.transaction_id,'additional in-house contact') addInhouse_agent,
				concattransagent(trans.transaction_id,'outside contact') outside_agent,
				concattransagent(trans.transaction_id,'additional outside contact') addOutside_agent
			FROM
			 	accn left join trans on accn.transaction_id = trans.transaction_id
				left join permit_trans on trans.transaction_id = permit_trans.transaction_id
				left join permit on permit_trans.permit_id = permit.permit_id
				left join collection on trans.collection_id=collection.collection_id
				left join project_trans on trans.transaction_id = project_trans.transaction_id
				left join project on project_trans.project_id = project.project_id
				<cfif (isdefined("trans_agent_role_1") AND len(trans_agent_role_1) gt 0) OR (isdefined("agent_1") AND len(agent_1) gt 0) >
					left join trans_agent trans_agent_1 on trans.transaction_id = trans_agent_1.transaction_id
				</cfif>
				<cfif not isdefined("agent_1_id") OR len(agent_1_id) eq 0 >
					<cfif isdefined("agent_1") AND len(agent_1) gt 0 >
						left join preferred_agent_name trans_agent_name_1 on trans_agent_1.agent_id = trans_agent_name_1.agent_id
					</cfif>
				</cfif>
				<cfif (isdefined("trans_agent_role_2") AND len(trans_agent_role_2) gt 0) OR (isdefined("agent_2") AND len(agent_2) gt 0) >
					left join trans_agent trans_agent_2 on trans.transaction_id = trans_agent_2.transaction_id
				</cfif>
				<cfif not isdefined("agent_2_id") OR len(agent_2_id) eq 0 >
					<cfif isdefined("agent_2") AND len(agent_2) gt 0 >
						left join preferred_agent_name trans_agent_name_2 on trans_agent_2.agent_id = trans_agent_name_2.agent_id
					</cfif>
				</cfif>
				<cfif (isdefined("trans_agent_role_3") AND len(trans_agent_role_3) gt 0) OR (isdefined("agent_3") AND len(agent_3) gt 0) >
					left join trans_agent trans_agent_3 on trans.transaction_id = trans_agent_3.transaction_id
				</cfif>
				<cfif not isdefined("agent_3_id") OR len(agent_3_id) eq 0 >
					<cfif isdefined("agent_3") AND len(agent_3) gt 0 >
						left join preferred_agent_name trans_agent_name_3 on trans_agent_3.agent_id = trans_agent_name_3.agent_id
					</cfif>
				</cfif>
				<cfif (isdefined("permit_id") AND len(#permit_id#) gt 0) OR (isdefined("permit_type") AND len(#permit_type#) GT 0) OR (isdefined("permit_specific_type") AND len(#permit_specific_type#) GT 0) >
					left join shipment on accn.transaction_id = shipment.transaction_id
					left join permit_shipment on shipment.shipment_id = permit_shipment.shipment_id
					left join permit permit_from_shipment on  permit_shipment.permit_id = permit_from_shipment.permit_id
				</cfif>
				<cfif (isdefined("part_name") AND len(part_name) gt 0) or (isdefined("coll_obj_disposition") AND len(coll_obj_disposition) gt 0) or isdefined("collection_object_id") AND len(#collection_object_id#) gt 0 >
					left join cataloged_item on accn.transaction_id=cataloged_item.accn_id
					left join specimen_part on cataloged_item.collection_object_id = specimen_part.derived_from_cat_item
					left join coll_object on specimen_part.collection_object_id = coll_object.collection_object_id
				</cfif>
				<cfif isdefined("IssuedByAgent") and len(#IssuedByAgent#) gt 0>
					<cfif not isdefined("issued_by_id") or len(#issued_by_id#) EQ 0>
						left join preferred_agent_name issuedBy on permit.issued_by_agent_id = issuedBy.agent_id
					</cfif>
				</cfif>
				<cfif isdefined("IssuedToAgent") and len(#IssuedToAgent#) gt 0>
					<cfif not isdefined("issued_to_id") or len(#issued_to_id#) EQ 0>
						left join preferred_agent_name issuedTo on permit.issued_to_agent_id = issuedTo.agent_id
					</cfif>
				</cfif>
			WHERE 
				accn.transaction_id is not null
				<cfif isDefined("accn_number") and len(accn_number) gt 0>
					<cfif left(accn_number,1) is "=">
						AND accn_number = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(accn_number,len(accn_number)-1)#">
					<cfelse>
						<cfif find(',',accn_number) GT 0>
							AND accn_number in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#accn_number#" list="yes"> )
						<cfelse>
							AND accn_number LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#accn_number#%">
						</cfif>
					</cfif>
				</cfif>
				<cfif isDefined("accn_status") and len(accn_status) gt 0>
					<cfif left(accn_status,1) is "!">
						AND upper(accn_status) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(accn_status,len(accn_status)-1))#"> 
					<cfelse>
						AND accn_status like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#accn_status#">
					</cfif>
				</cfif>
				<cfif isDefined("collection_id") and collection_id gt 0>
					AND collection.collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_id#">
				</cfif>
				<cfif isdefined("trans_agent_role_1") AND len(trans_agent_role_1) gt 0>
					<cfif isdefined("agent_1") AND agent_1 EQ "NULL">
						AND trans.transaction_id NOT IN (select transaction_id from trans_agent where trans_agent_role = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trans_agent_role_1#">)
					<cfelse>
						AND trans_agent_1.trans_agent_role = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trans_agent_role_1#">
					</cfif>
				</cfif>
				<cfif isdefined("agent_1_id") AND len(agent_1_id) gt 0>
					AND upper(trans_agent_1.agent_id) like <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_1_id#">
				<cfelseif isdefined("agent_1") AND agent_1 EQ "NOT NULL">
					<!--- not need to add not null clause, just skip adding match on name --->
				<cfelseif isdefined("agent_1") AND agent_1 EQ "NULL">
					<!--- need to exclude or query clauses will be contradictory --->
				<cfelseif isdefined("agent_1") AND len(agent_1) gt 0>
					AND upper(trans_agent_name_1.agent_name) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(agent_1)#%" >
				</cfif>
				<cfif isdefined("trans_agent_role_2") AND len(trans_agent_role_2) gt 0>
					<cfif isdefined("agent_2") AND agent_2 EQ "NULL">
						AND trans.transaction_id NOT IN (select transaction_id from trans_agent where trans_agent_role = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trans_agent_role_2#">)
					<cfelse>
						AND trans_agent_2.trans_agent_role = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trans_agent_role_2#">
					</cfif>
				</cfif>
				<cfif isdefined("agent_2_id") AND len(agent_2_id) gt 0>
					AND upper(trans_agent_2.agent_id) like <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_2_id#">
				<cfelseif isdefined("agent_2") AND agent_2 EQ "NOT NULL">
					<!--- not need to add not null clause, just skip adding match on name --->
				<cfelseif isdefined("agent_2") AND agent_2 EQ "NULL">
					<!--- need to exclude or query clauses will be contradictory --->
				<cfelseif isdefined("agent_2") AND len(agent_2) gt 0>
					AND upper(trans_agent_name_2.agent_name) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(agent_2)#%" >
				</cfif>
				<cfif isdefined("trans_agent_role_3") AND len(trans_agent_role_3) gt 0>
					<cfif isdefined("agent_3") AND agent_3 EQ "NULL">
						AND trans.transaction_id NOT IN (select transaction_id from trans_agent where trans_agent_role = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trans_agent_role_3#">)
					<cfelse>
						AND trans_agent_3.trans_agent_role = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trans_agent_role_3#">
					</cfif>
				</cfif>
				<cfif isdefined("agent_3_id") AND len(agent_3_id) gt 0>
					AND upper(trans_agent_3.agent_id) like <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_3_id#">
				<cfelseif isdefined("agent_3") AND agent_3 EQ "NOT NULL">
					<!--- not need to add not null clause, just skip adding match on name --->
				<cfelseif isdefined("agent_3") AND agent_3 EQ "NULL">
					<!--- need to exclude or query clauses will be contradictory --->
				<cfelseif isdefined("agent_3") AND len(agent_3) gt 0>
					AND upper(trans_agent_name_3.agent_name) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(agent_3)#%" >
				</cfif>
				<cfif isdefined("trans_date") and len(trans_date) gt 0>
					AND trans_date between 
						to_date(<cfqueryparam cfsqltype="CF_SQL_DATE" value='#dateformat(trans_date, "yyyy-mm-dd")#'>) and
						(to_date(<cfqueryparam cfsqltype="CF_SQL_DATE" value='#dateformat(to_trans_date, "yyyy-mm-dd")#'>) + (86399/86400) )
				</cfif>
				<cfif isdefined("date_entered") and len(date_entered) gt 0>
					AND date_entered between 
						to_date(<cfqueryparam cfsqltype="CF_SQL_DATE" value='#dateformat(date_entered, "yyyy-mm-dd")#'>) and
						(to_date(<cfqueryparam cfsqltype="CF_SQL_DATE" value='#dateformat(to_date_entered, "yyyy-mm-dd")#'>) + (86399/86400) )
				</cfif>
				<cfif isdefined("rec_date") and len(rec_date) gt 0>
					AND accn.received_date between 
						to_date(<cfqueryparam cfsqltype="CF_SQL_DATE" value='#dateformat(rec_date, "yyyy-mm-dd")#'>) and
						(to_date(<cfqueryparam cfsqltype="CF_SQL_DATE" value='#dateformat(to_rec_date, "yyyy-mm-dd")#'>) + (86399/86400) )
				</cfif>
				<cfif isdefined("nature_of_material") AND len(#nature_of_material#) gt 0>
					AND upper(nature_of_material) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value='%#ucase(nature_of_material)#%'>
				</cfif>

				<cfif isdefined("collection_object_id") AND len(#collection_object_id#) gt 0 >
					AND specimen_part.collection_object_id IN ( <cfqueryparam list="yes" cfsqltype="CF_SQL_VARCHAR" value="#collection_object_id#" > )
				</cfif>
				<cfif  isdefined("accn_type") and len(#accn_type#) gt 0>
					<cfif left(accn_type,1) is "!">
						AND upper(accn_type) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(accn_type,len(accn_type)-1))#"> 
					<cfelse>
						AND accn_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#accn_type#">
					</cfif>
				</cfif>
				<cfif isdefined("trans_remarks") AND len(#trans_remarks#) gt 0>
					AND upper(trans_remarks) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value='%#ucase(trans_remarks)#%'>
				</cfif>
				<cfif isdefined("permit_id") AND len(#permit_id#) gt 0>
					AND ( 
						permit.permit_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#permit_id#">
						OR
						permit_shipment.permit_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#permit_id#">
					)
				</cfif>
				<cfif  isdefined("permit_type") and len(#permit_type#) gt 0>
					<cfif left(permit_type,1) is "!">
						AND has_permitoftype(trans.transaction_id,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(permit_type,len(permit_type)-1)#">) = 0
					<cfelse>
						AND ( 
							permit.permit_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#permit_type#">
							OR
							permit_from_shipment.permit_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#permit_type#">
						)
					</cfif>
				</cfif>
				<cfif  isdefined("permit_specific_type") and len(#permit_specific_type#) gt 0>
					<cfif left(permit_specific_type,1) is "!">
						AND has_permitofspectype(trans.transaction_id,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(permit_specific_type,len(permit_specific_type)-1)#">) = 0
					<cfelse>
						AND ( 
							permit.specific_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#permit_specific_type#">
							OR
							permit_from_shipment.specific_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#permit_specific_type#">
						)
					</cfif>
				</cfif>
				<cfif (isdefined("part_name") AND len(part_name) gt 0) or (isdefined("coll_obj_disposition") AND len(coll_obj_disposition) gt 0)>
					<cfif isdefined("part_name") AND len(part_name) gt 0>
						<cfif not isdefined("part_name_oper")><cfset part_name_oper='is'></cfif>
						<cfif part_name_oper is "is">
							AND specimen_part.part_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#part_name#">
						<cfelse>
							AND upper(specimen_part.part_name) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(part_name)#%">
						</cfif>
					</cfif>
					<cfif isdefined("coll_obj_disposition") AND len(coll_obj_disposition) gt 0>
						<cfif not isdefined("part_disp_oper")><cfset part_disp_oper='is'></cfif>
						<cfif part_disp_oper is "is">
							AND coll_object.coll_obj_disposition IN ( <cfqueryparam list="yes" cfsqltype="CF_SQL_VARCHAR" value="#coll_obj_disposition#" > )
						<cfelse>
							AND coll_object.coll_obj_disposition NOT IN ( <cfqueryparam list="yes" cfsqltype="CF_SQL_VARCHAR" value="#coll_obj_disposition#" > )
						</cfif>
					</cfif>
				</cfif>
				<cfif isdefined("collection_id") AND collection_id gt 0>
					AND trans.collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_id#">
				</cfif>
				<cfif isdefined("issued_by_id") and len(#issued_by_id#) gt 0>
					AND upper(permit.issued_by_agent_id) = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#issued_by_id#">
				<cfelse>
					<cfif isdefined("IssuedByAgent") and len(#IssuedByAgent#) gt 0>
						AND upper(issuedBy.agent_name) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(IssuedByAgent)#%">
					</cfif>
				</cfif>
				<cfif isdefined("issued_to_id") and len(#issued_to_id#) gt 0>
					AND upper(permit.issued_to_agent_id) = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#issued_to_id#">
				<cfelse>
					<cfif isdefined("IssuedToAgent") and len(#IssuedToAgent#) gt 0>
						AND upper(issuedTo.agent_name) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(IssuedToAgent)#%">
					</cfif>
				</cfif>
				<cfif isdefined("permit_contact_id") and len(#permit_contact_id#) gt 0>
					AND upper(permit.contact_agent_id) = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#permit_contact_id#">
				</cfif>
				<cfif isdefined("restriction_summary") and len(#restriction_summary#) gt 0>
					<cfif restriction_summary EQ 'NULL'>
						AND upper(permit.restriction_summary) is NULL
					<cfelseif restriction_summary EQ 'NOT NULL'>
						AND upper(permit.restriction_summary) is NOT NULL
					<cfelse>
						AND upper(permit.restriction_summary) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(restriction_summary)#%">
					</cfif>
				</cfif>
				<cfif isdefined("benefits_summary") and len(#benefits_summary#) gt 0>
					<cfif benefits_summary EQ 'NULL'>
						AND upper(permit.benefits_summary) is NULL
					<cfelseif benefits_summary EQ 'NOT NULL'>
						AND upper(permit.benefits_summary) is NOT NULL
					<cfelse>
						AND upper(permit.benefits_summary) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(benefits_summary)#%">
					</cfif>
				</cfif>
				<cfif isdefined("benefits_provided") and len(#benefits_provided#) gt 0>
					<cfif benefits_provided EQ 'NULL'>
						AND upper(permit.benefits_provided) is NULL
					<cfelseif benefits_provided EQ 'NOT NULL'>
						AND upper(permit.benefits_provided) is NOT NULL
					<cfelse>
						AND upper(permit.benefits_provided) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(benefits_provided)#%">
					</cfif>
				</cfif>
				<cfif  isdefined("permit_remarks") and len(#permit_remarks#) gt 0>
					AND upper(permit_remarks) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(permit_remarks)#%">
				</cfif>
				<cfif isDefined("estimated_count") and len(estimated_count) gt 0>
					<cfif left(estimated_count,1) is "<">
						AND estimated_count < <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#right(estimated_count,len(estimated_count)-1)#"> 
					<cfelseif left(estimated_count,1) is ">">
						AND estimated_count > <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#right(estimated_count,len(estimated_count)-1)#"> 
						AND estimated_count IS NOT NULL
					<cfelseif left(estimated_count,1) is "!">
						AND (estimated_count <> <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#right(estimated_count,len(estimated_count)-1)#"> 
							OR estimated_count IS NULL)
					<cfelseif left(estimated_count,1) is "=">
						AND estimated_count = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#right(estimated_count,len(estimated_count)-1)#"> 
					<cfelseif estimated_count is "NULL">
						AND estimated_count IS NULL
					<cfelseif estimated_count is "NOT NULL">
						AND estimated_count IS NOT NULL
					<cfelse>
						AND estimated_count = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#estimated_count#"> 
					</cfif>
				</cfif>
				<cfif  isdefined("shipment_count") and len(#shipment_count#) gt 0>
					<cfif shipment_count IS "0">
						AND trans.transaction_id NOT IN
							(select transaction_id from shipment)
					<cfelseif shipment_count IS "1">
						AND MCZBASE.COUNT_SHIPMENTS_FOR_TRANS(trans.transaction_id) = 1
					<cfelseif shipment_count IS "1+">
						AND trans.transaction_id IN
							(select transaction_id from shipment)
					<cfelseif shipment_count IS "2+">
						AND MCZBASE.COUNT_SHIPMENTS_FOR_TRANS(trans.transaction_id) > 1
					<cfelseif shipment_count IS "3+">
						AND MCZBASE.COUNT_SHIPMENTS_FOR_TRANS(trans.transaction_id) > 2
					</cfif>
				</cfif>
				<cfif  isdefined("foreign_shipments") and len(#foreign_shipments#) gt 0>
					<cfif foreign_shipments IS "0">
						AND trans.transaction_id NOT IN
							(select transaction_id from shipment where foreign_shipment_fg = 1)
					<cfelseif foreign_shipments IS "1+">
						AND trans.transaction_id IN
							(select transaction_id from shipment where foreign_shipment_fg = 1)
					</cfif>
				</cfif>
			ORDER BY accn_number
		</cfquery>
		<!---
			 replaced with leading = 
			 <cfif isdefined("exactAccnNumMatch") and #exactAccnNumMatch# is 1>
			 replaced with trans_date/to_trans_date
			 AND TRANS_DATE #entDateOper# '#ucase(dateformat(stripQuotes(ent_date),"yyyy-mm-dd"))#">
			 replaced with permit picker
			 <cfif isdefined("permit_Num") and len(#permit_Num#) gt 0>
				<cfset sql = "#sql# AND permit_Num = '#escapeQuotes(permit_Num)#'">
			 </cfif>
		
	 		 not implemented	
			 <cfif  isdefined("rec_agent") and len(#rec_agent#) gt 0>
				<cfset frm = "#frm#,agent_name">
				<cfset sql = "#sql# AND upper(agent_name.agent_name) like '%#escapeQuotes(ucase(rec_agent))#%'
					AND trans.received_agent_id = agent_name.agent_id">
			 </cfif>
		    <cfif  isdefined("trans_agency") and len(#trans_agency#) gt 0>
		  		<cfset sql = "#sql# AND upper(transAgent.agent_name) LIKE  '%#escapeQuotes(ucase(trans_agency))#%'">
			 </cfif>
			<cfif  isdefined("issued_date") and len(#issued_date#) gt 0>
				<cfset sql = "#sql# AND upper(issued_date) like '%#stripQuotes(ucase(issued_date))#%'">
			</cfif>
			<cfif  isdefined("renewed_date") and len(#renewed_date#) gt 0>
				<cfset sql = "#sql# AND upper(renewed_date) like '%#stripQuotes(ucase(renewed_date))#%'">
			</cfif>
			<cfif isdefined("exp_date") and  len(#exp_date#) gt 0>
				<cfset sql = "#sql# AND upper(exp_date) like '%#stripQuotes(ucase(exp_date))#%'">
			</cfif>

	--->

	<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfloop list="#ArrayToList(search.getColumnNames())#" index="col" >
				<cfset row["#lcase(col)#"] = "#search[col][currentRow]#">
			</cfloop>
			<cfset row["id_link"] = "<a href='/transactions/Accession.cfm?action=edit&transaction_id=#search.transaction_id#' target='_blank'>#search.accn_number#</a>">
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
	<cfreturn #serializeJSON(data)#>
</cffunction>

<!---   Function getDeccessions  --->
<cffunction name="getDeaccessions" access="remote" returntype="any" returnformat="json">
	<cfargument name="deacc_number" type="string" required="no">
	<cfargument name="deacc_type" type="string" required="no">
	<cfargument name="deacc_status" type="string" required="no">
	<cfargument name="deacc_reason" type="string" required="no">
	<cfargument name="deacc_description" type="string" required="no">
	<cfargument name="trans_remarks" type="string" required="no">
	<cfargument name="deacc_remarks" type="string" required="no">
	<cfargument name="nature_of_material" type="string" required="no">
	<cfargument name="collection_id" type="numeric" required="no">
	<cfargument name="permit_num" type="string" required="no">
	<cfargument name="permit_id" type="string" required="no">
	<cfargument name="permit_type" type="string" required="no">
	<cfargument name="permit_specific_type" type="string" required="no">
	<cfargument name="trans_date" type="string" required="no">
	<cfargument name="to_trans_date" type="string" required="no">
	<cfargument name="date_entered" type="string" required="no">
	<cfargument name="to_date_entered" type="string" required="no">
	<cfargument name="trans_agent_role_1" type="string" required="no">
	<cfargument name="agent_1" type="string" required="no">
	<cfargument name="agent_1_id" type="string" required="no">
	<cfargument name="trans_agent_role_2" type="string" required="no">
	<cfargument name="agent_2" type="string" required="no">
	<cfargument name="agent_2_id" type="string" required="no">
	<cfargument name="trans_agent_role_3" type="string" required="no">
	<cfargument name="agent_3" type="string" required="no">
	<cfargument name="agent_3_id" type="string" required="no">
	<cfargument name="collection_object_id" type="string" required="no">
	<cfargument name="specimen_guid" type="string" required="no">
	<cfargument name="part_name" type="string" required="no">
	<cfargument name="coll_obj_disposition" type="string" required="no">
	<cfargument name="restriction_summary" type="string" required="no">
	<cfargument name="benefits_summary" type="string" required="no">
	<cfargument name="benefits_provided" type="string" required="no">
	<cfargument name="issued_by_id" type="string" required="no">
	<cfargument name="issued_to_id" type="string" required="no">
	<cfargument name="permit_contact_id" type="string" required="no">
	<cfargument name="permit_remarks" type="string" required="no">
	<cfargument name="value" type="string" required="no">
	<cfargument name="deacc_method" type="string" required="no">
	<cfargument name="shipment_count" type="string" required="no">
	<cfargument name="foreign_shipments" type="string" required="no">

	<!--- If provided with sppecimen guids, look up part collection object ids for lookup --->
	<cfif not isdefined("collection_object_id") ><cfset collection_object_id = ""></cfif>
	<cfif (isdefined("specimen_guid") AND len(#specimen_guid#) gt 0) >
		<cfquery name="guidSearch" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="guidSearch_result" timeout="#Application.query_timeout#">
			select specimen_part.collection_object_id as part_coll_obj_id 
			from 
				#session.flatTableName# flat left join specimen_part on flat.collection_object_id = specimen_part.derived_from_cat_item
			where
				flat.guid in ( <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#specimen_guid#" list="yes"> )
		</cfquery>
		<cfloop query="guidSearch">
			<cfif not listContains(collection_object_id,guidSearch.part_coll_obj_id)>
				<cfif len(collection_object_id) EQ 0>
					<cfset collection_object_id = guidSearch.part_coll_obj_id>
				<cfelse>
					<cfset collection_object_id = collection_object_id & "," & guidSearch.part_coll_obj_id>
				</cfif>
			</cfif>
		</cfloop>
	</cfif>

	<!--- set start/end date range terms to same if only one is specified --->
	<cfif isdefined("trans_date") and len(#trans_date#) gt 0>
		<cfif not isdefined("to_trans_date") or len(to_trans_date) is 0>
			<cfset to_trans_date=trans_date>
		</cfif>
		<!--- support search on just a year or pair of years --->
		<cfif len(#trans_date#) EQ 4>
			<cfset trans_date = "#trans_date#-01-01">
		</cfif>
		<cfif len(#to_trans_date#) EQ 4>
			<cfset to_trans_date = "#to_trans_date#-12-31">
		</cfif>
	</cfif>
	<cfif isdefined("date_entered") and len(#date_entered#) gt 0>
		<cfif not isdefined("to_date_entered") or len(to_date_entered) is 0>
			<cfset to_date_entered=date_entered>
		</cfif>
		<!--- support search on just a year or pair of years --->
		<cfif len(#date_entered#) EQ 4>
			<cfset date_entered = "#date_entered#-01-01">
		</cfif>
		<cfif len(#to_date_entered#) EQ 4>
			<cfset to_date_entered = "#to_date_entered#-12-31">
		</cfif>
	</cfif>

	<!--- do the search --->
	<cfset data = ArrayNew(1)>
	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result" timeout="#Application.query_timeout#">
			SELECT distinct
				trans.transaction_id,
				deacc_number,
				deacc_type,
				nature_of_material,
				to_char(trans_date,'YYYY-MM-DD') as deaccession_date,
				to_char(date_entered,'YYYY-MM-DD') as date_entered,
				deacc_status,
				deacc_reason,
				deacc_description,
				value,
				method,
				trans_remarks,
				deacc_remarks,
				collection,
				collection.collection_cde,
				project_name,
				project.project_id pid,
				MCZBASE.get_permits_for_trans(trans.transaction_id) permits,
				MCZBASE.count_shipments_for_trans(trans.transaction_id) shipment_count,
				COUNT_FOREIGNSHIP_FOR_TRANS(trans.transaction_id) as foreign_shipments,
				MCZBASE.count_catitems_for_deacc(trans.transaction_id) item_count,
				concattransagent(trans.transaction_id,'entered by') ent_agent,
				concattransagent(trans.transaction_id,'in-house authorized by') auth_agent,
				concattransagent(trans.transaction_id,'recipient institution') recipient_institution_agent,
				concattransagent(trans.transaction_id,'received by') rec_agent,
				concattransagent(trans.transaction_id,'in-house contact') inHouse_agent,
				concattransagent(trans.transaction_id,'additional in-house contact') addInhouse_agent,
				concattransagent(trans.transaction_id,'outside contact') outside_agent,
				concattransagent(trans.transaction_id,'additional outside contact') addOutside_agent
			FROM
			 	deaccession left join trans on deaccession.transaction_id = trans.transaction_id
				left join permit_trans on trans.transaction_id = permit_trans.transaction_id
				left join permit on permit_trans.permit_id = permit.permit_id
				left join collection on trans.collection_id=collection.collection_id
				left join project_trans on trans.transaction_id = project_trans.transaction_id
				left join project on project_trans.project_id = project.project_id
				<cfif (isdefined("trans_agent_role_1") AND len(trans_agent_role_1) gt 0) OR (isdefined("agent_1") AND len(agent_1) gt 0) >
					left join trans_agent trans_agent_1 on trans.transaction_id = trans_agent_1.transaction_id
				</cfif>
				<cfif not isdefined("agent_1_id") OR len(agent_1_id) eq 0 >
					<cfif isdefined("agent_1") AND len(agent_1) gt 0 >
						left join preferred_agent_name trans_agent_name_1 on trans_agent_1.agent_id = trans_agent_name_1.agent_id
					</cfif>
				</cfif>
				<cfif (isdefined("trans_agent_role_2") AND len(trans_agent_role_2) gt 0) OR (isdefined("agent_2") AND len(agent_2) gt 0) >
					left join trans_agent trans_agent_2 on trans.transaction_id = trans_agent_2.transaction_id
				</cfif>
				<cfif not isdefined("agent_2_id") OR len(agent_2_id) eq 0 >
					<cfif isdefined("agent_2") AND len(agent_2) gt 0 >
						left join preferred_agent_name trans_agent_name_2 on trans_agent_2.agent_id = trans_agent_name_2.agent_id
					</cfif>
				</cfif>
				<cfif (isdefined("trans_agent_role_3") AND len(trans_agent_role_3) gt 0) OR (isdefined("agent_3") AND len(agent_3) gt 0) >
					left join trans_agent trans_agent_3 on trans.transaction_id = trans_agent_3.transaction_id
				</cfif>
				<cfif not isdefined("agent_3_id") OR len(agent_3_id) eq 0 >
					<cfif isdefined("agent_3") AND len(agent_3) gt 0 >
						left join preferred_agent_name trans_agent_name_3 on trans_agent_3.agent_id = trans_agent_name_3.agent_id
					</cfif>
				</cfif>
				<cfif (isdefined("permit_id") AND len(#permit_id#) gt 0) OR (isdefined("permit_type") AND len(#permit_type#) GT 0) OR (isdefined("permit_specific_type") AND len(#permit_specific_type#) GT 0) >
					left join shipment on deaccession.transaction_id = shipment.transaction_id
					left join permit_shipment on shipment.shipment_id = permit_shipment.shipment_id
					left join permit permit_from_shipment on  permit_shipment.permit_id = permit_from_shipment.permit_id
				</cfif>
				<cfif (isdefined("part_name") AND len(part_name) gt 0) or (isdefined("coll_obj_disposition") AND len(coll_obj_disposition) gt 0) or isdefined("collection_object_id") AND len(#collection_object_id#) gt 0 >
					left join deacc_item on deaccession.transaction_id = deacc_item.transaction_id
					left join coll_object on deacc_item.collection_object_id = coll_object.collection_object_id
					left join specimen_part on coll_object.collection_object_id = specimen_part.collection_object_id
				</cfif>
				<cfif isdefined("IssuedByAgent") and len(#IssuedByAgent#) gt 0>
					<cfif not isdefined("issued_by_id") or len(#issued_by_id#) EQ 0>
						left join preferred_agent_name issuedBy on permit.issued_by_agent_id = issuedBy.agent_id
					</cfif>
				</cfif>
				<cfif isdefined("IssuedToAgent") and len(#IssuedToAgent#) gt 0>
					<cfif not isdefined("issued_to_id") or len(#issued_to_id#) EQ 0>
						left join preferred_agent_name issuedTo on permit.issued_to_agent_id = issuedTo.agent_id
					</cfif>
				</cfif>
			WHERE 
				deaccession.transaction_id is not null
				<cfif isDefined("deacc_number") and len(deacc_number) gt 0>
					<cfif left(deacc_number,1) is "=">
						AND deacc_number = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(deacc_number,len(deacc_number)-1)#">
					<cfelse>
						<cfif find(',',deacc_number) GT 0>
							AND deacc_number in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#deacc_number#" list="yes"> )
						<cfelse>
							AND deacc_number LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#deacc_number#%">
						</cfif>
					</cfif>
				</cfif>
				<cfif isDefined("deacc_status") and len(deacc_status) gt 0>
					<cfif left(deacc_status,1) is "!">
						AND upper(deacc_status) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(deacc_status,len(deacc_status)-1))#"> 
					<cfelse>
						AND deacc_status like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#deacc_status#">
					</cfif>
				</cfif>
				<cfif isDefined("collection_id") and collection_id gt 0>
					AND collection.collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_id#">
				</cfif>
				<cfif isdefined("trans_agent_role_1") AND len(trans_agent_role_1) gt 0>
					<cfif isdefined("agent_1") AND agent_1 EQ "NULL">
						AND trans.transaction_id NOT IN (select transaction_id from trans_agent where trans_agent_role = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trans_agent_role_1#">)
					<cfelse>
						AND trans_agent_1.trans_agent_role = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trans_agent_role_1#">
					</cfif>
				</cfif>
				<cfif isdefined("agent_1_id") AND len(agent_1_id) gt 0>
					AND upper(trans_agent_1.agent_id) like <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_1_id#">
				<cfelseif isdefined("agent_1") AND agent_1 EQ "NOT NULL">
					<!--- not need to add not null clause, just skip adding match on name --->
				<cfelseif isdefined("agent_1") AND agent_1 EQ "NULL">
					<!--- need to exclude or query clauses will be contradictory --->
				<cfelseif isdefined("agent_1") AND len(agent_1) gt 0>
					AND upper(trans_agent_name_1.agent_name) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(agent_1)#%" >
				</cfif>
				<cfif isdefined("trans_agent_role_2") AND len(trans_agent_role_2) gt 0>
					<cfif isdefined("agent_2") AND agent_2 EQ "NULL">
						AND trans.transaction_id NOT IN (select transaction_id from trans_agent where trans_agent_role = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trans_agent_role_2#">)
					<cfelse>
						AND trans_agent_2.trans_agent_role = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trans_agent_role_2#">
					</cfif>
				</cfif>
				<cfif isdefined("agent_2_id") AND len(agent_2_id) gt 0>
					AND upper(trans_agent_2.agent_id) like <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_2_id#">
				<cfelseif isdefined("agent_2") AND agent_2 EQ "NOT NULL">
					<!--- not need to add not null clause, just skip adding match on name --->
				<cfelseif isdefined("agent_2") AND agent_2 EQ "NULL">
					<!--- need to exclude or query clauses will be contradictory --->
				<cfelseif isdefined("agent_2") AND len(agent_2) gt 0>
					AND upper(trans_agent_name_2.agent_name) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(agent_2)#%" >
				</cfif>
				<cfif isdefined("trans_agent_role_3") AND len(trans_agent_role_3) gt 0>
					<cfif isdefined("agent_3") AND agent_3 EQ "NULL">
						AND trans.transaction_id NOT IN (select transaction_id from trans_agent where trans_agent_role = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trans_agent_role_3#">)
					<cfelse>
						AND trans_agent_3.trans_agent_role = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trans_agent_role_3#">
					</cfif>
				</cfif>
				<cfif isdefined("agent_3_id") AND len(agent_3_id) gt 0>
					AND upper(trans_agent_3.agent_id) like <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_3_id#">
				<cfelseif isdefined("agent_3") AND agent_3 EQ "NOT NULL">
					<!--- not need to add not null clause, just skip adding match on name --->
				<cfelseif isdefined("agent_3") AND agent_3 EQ "NULL">
					<!--- need to exclude or query clauses will be contradictory --->
				<cfelseif isdefined("agent_3") AND len(agent_3) gt 0>
					AND upper(trans_agent_name_3.agent_name) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(agent_3)#%" >
				</cfif>
				<cfif isdefined("trans_date") and len(trans_date) gt 0>
					AND trans_date between 
						to_date(<cfqueryparam cfsqltype="CF_SQL_DATE" value='#dateformat(trans_date, "yyyy-mm-dd")#'>) and
						(to_date(<cfqueryparam cfsqltype="CF_SQL_DATE" value='#dateformat(to_trans_date, "yyyy-mm-dd")#'>) + (86399/86400) )
				</cfif>
				<cfif isdefined("date_entered") and len(date_entered) gt 0>
					AND date_entered between 
						to_date(<cfqueryparam cfsqltype="CF_SQL_DATE" value='#dateformat(date_entered, "yyyy-mm-dd")#'>) and
						(to_date(<cfqueryparam cfsqltype="CF_SQL_DATE" value='#dateformat(to_date_entered, "yyyy-mm-dd")#'>) + (86399/86400) )
				</cfif>
				<cfif isdefined("nature_of_material") AND len(#nature_of_material#) gt 0>
					AND upper(nature_of_material) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value='%#ucase(nature_of_material)#%'>
				</cfif>

				<cfif isdefined("collection_object_id") AND len(#collection_object_id#) gt 0 >
					AND specimen_part.collection_object_id IN ( <cfqueryparam list="yes" cfsqltype="CF_SQL_VARCHAR" value="#collection_object_id#" > )
				</cfif>
				<cfif  isdefined("deacc_type") and len(#deacc_type#) gt 0>
					<cfif left(deacc_type,1) is "!">
						AND upper(deacc_type) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(deacc_type,len(deacc_type)-1))#"> 
					<cfelse>
						AND deacc_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#deacc_type#">
					</cfif>
				</cfif>
				<cfif isdefined("deacc_method") and len(#deacc_method#) gt 0>
					<cfif deacc_method EQ 'NULL'>
						AND upper(deaccession.method) is NULL
					<cfelseif deacc_method EQ 'NOT NULL'>
						AND upper(deaccession.method) is NOT NULL
					<cfelse>
						AND upper(deaccession.method) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(deacc_method)#%">
					</cfif>
				</cfif>
				<cfif isdefined("value") and len(#value#) gt 0>
					<cfif value EQ 'NULL'>
						AND upper(deaccession.value) is NULL
					<cfelseif value EQ 'NOT NULL'>
						AND upper(deaccession.value) is NOT NULL
					<cfelse>
						AND upper(deaccession.value) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(value)#%">
					</cfif>
				</cfif>
				<cfif isdefined("trans_remarks") AND len(#trans_remarks#) gt 0>
					AND upper(trans_remarks) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value='%#ucase(trans_remarks)#%'>
				</cfif>
				<cfif isdefined("permit_id") AND len(#permit_id#) gt 0>
					AND ( 
						permit.permit_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#permit_id#">
						OR
						permit_from_shipment.permit_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#permit_id#">
					)
				</cfif>
				<cfif  isdefined("permit_type") and len(#permit_type#) gt 0>
					AND ( 
						permit.permit_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#permit_type#">
						OR
						permit_from_shipment.permit_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#permit_type#">
					)
				</cfif>
				<cfif  isdefined("permit_specific_type") and len(#permit_specific_type#) gt 0>
					AND ( 
						permit.specific_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#permit_specific_type#">
						OR
						permit_from_shipment.specific_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#permit_specific_type#">
					)
				</cfif>
				<cfif (isdefined("part_name") AND len(part_name) gt 0) or (isdefined("coll_obj_disposition") AND len(coll_obj_disposition) gt 0)>
					<cfif isdefined("part_name") AND len(part_name) gt 0>
						<cfif not isdefined("part_name_oper")><cfset part_name_oper='is'></cfif>
						<cfif part_name_oper is "is">
							AND specimen_part.part_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#part_name#">
						<cfelse>
							AND upper(specimen_part.part_name) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(part_name)#%">
						</cfif>
					</cfif>
					<cfif isdefined("coll_obj_disposition") AND len(coll_obj_disposition) gt 0>
						<cfif not isdefined("part_disp_oper")><cfset part_disp_oper='is'></cfif>
						<cfif part_disp_oper is "is">
							AND coll_object.coll_obj_disposition IN ( <cfqueryparam list="yes" cfsqltype="CF_SQL_VARCHAR" value="#coll_obj_disposition#" > )
						<cfelse>
							AND coll_object.coll_obj_disposition NOT IN ( <cfqueryparam list="yes" cfsqltype="CF_SQL_VARCHAR" value="#coll_obj_disposition#" > )
						</cfif>
					</cfif>
				</cfif>
				<cfif isdefined("collection_id") AND collection_id gt 0>
					AND trans.collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_id#">
				</cfif>
				<cfif isdefined("issued_by_id") and len(#issued_by_id#) gt 0>
					AND upper(permit.issued_by_agent_id) = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#issued_by_id#">
				<cfelse>
					<cfif isdefined("IssuedByAgent") and len(#IssuedByAgent#) gt 0>
						AND upper(issuedBy.agent_name) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(IssuedByAgent)#%">
					</cfif>
				</cfif>
				<cfif isdefined("issued_to_id") and len(#issued_to_id#) gt 0>
					AND upper(permit.issued_to_agent_id) = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#issued_to_id#">
				<cfelse>
					<cfif isdefined("IssuedToAgent") and len(#IssuedToAgent#) gt 0>
						AND upper(issuedTo.agent_name) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(IssuedToAgent)#%">
					</cfif>
				</cfif>
				<cfif isdefined("permit_contact_id") and len(#permit_contact_id#) gt 0>
					AND upper(permit.contact_agent_id) = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#permit_contact_id#">
				</cfif>
				<cfif isdefined("restriction_summary") and len(#restriction_summary#) gt 0>
					<cfif restriction_summary EQ 'NULL'>
						AND upper(permit.restriction_summary) is NULL
					<cfelseif restriction_summary EQ 'NOT NULL'>
						AND upper(permit.restriction_summary) is NOT NULL
					<cfelse>
						AND upper(permit.restriction_summary) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(restriction_summary)#%">
					</cfif>
				</cfif>
				<cfif isdefined("benefits_summary") and len(#benefits_summary#) gt 0>
					<cfif benefits_summary EQ 'NULL'>
						AND upper(permit.benefits_summary) is NULL
					<cfelseif benefits_summary EQ 'NOT NULL'>
						AND upper(permit.benefits_summary) is NOT NULL
					<cfelse>
						AND upper(permit.benefits_summary) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(benefits_summary)#%">
					</cfif>
				</cfif>
				<cfif isdefined("benefits_provided") and len(#benefits_provided#) gt 0>
					<cfif benefits_provided EQ 'NULL'>
						AND upper(permit.benefits_provided) is NULL
					<cfelseif benefits_provided EQ 'NOT NULL'>
						AND upper(permit.benefits_provided) is NOT NULL
					<cfelse>
						AND upper(permit.benefits_provided) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(benefits_provided)#%">
					</cfif>
				</cfif>
				<cfif  isdefined("permit_remarks") and len(#permit_remarks#) gt 0>
					AND upper(permit_remarks) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(permit_remarks)#%">
				</cfif>
				<cfif isDefined("estimated_count") and len(estimated_count) gt 0>
					<cfif left(estimated_count,1) is "<">
						AND estimated_count < <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#right(estimated_count,len(estimated_count)-1)#"> 
					<cfelseif left(estimated_count,1) is ">">
						AND estimated_count > <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#right(estimated_count,len(estimated_count)-1)#"> 
						AND estimated_count IS NOT NULL
					<cfelseif left(estimated_count,1) is "!">
						AND (estimated_count <> <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#right(estimated_count,len(estimated_count)-1)#"> 
							OR estimated_count IS NULL)
					<cfelseif left(estimated_count,1) is "=">
						AND estimated_count = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#right(estimated_count,len(estimated_count)-1)#"> 
					<cfelseif estimated_count is "NULL">
						AND estimated_count IS NULL
					<cfelseif estimated_count is "NOT NULL">
						AND estimated_count IS NOT NULL
					<cfelse>
						AND estimated_count = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#estimated_count#"> 
					</cfif>
				</cfif>
				<cfif  isdefined("shipment_count") and len(#shipment_count#) gt 0>
					<cfif shipment_count IS "0">
						AND trans.transaction_id NOT IN
							(select transaction_id from shipment)
					<cfelseif shipment_count IS "1">
						AND MCZBASE.COUNT_SHIPMENTS_FOR_TRANS(trans.transaction_id) = 1
					<cfelseif shipment_count IS "1+">
						AND trans.transaction_id IN
							(select transaction_id from shipment)
					<cfelseif shipment_count IS "2+">
						AND MCZBASE.COUNT_SHIPMENTS_FOR_TRANS(trans.transaction_id) > 1
					<cfelseif shipment_count IS "3+">
						AND MCZBASE.COUNT_SHIPMENTS_FOR_TRANS(trans.transaction_id) > 2
					</cfif>
				</cfif>
				<cfif  isdefined("foreign_shipments") and len(#foreign_shipments#) gt 0>
					<cfif foreign_shipments IS "0">
						AND trans.transaction_id NOT IN
							(select transaction_id from shipment where foreign_shipment_fg = 1)
					<cfelseif foreign_shipments IS "1+">
						AND trans.transaction_id IN
							(select transaction_id from shipment where foreign_shipment_fg = 1)
					</cfif>
				</cfif>
			ORDER BY 
				regexp_substr(deacc_number,'^[D0-9]+-'), 
				to_number(replace(regexp_substr(deacc_number,'-[0-9]+-'),'-','')), 
				deacc_number
		</cfquery>
		<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfloop list="#ArrayToList(search.getColumnNames())#" index="col" >
				<cfset row["#lcase(col)#"] = "#search[col][currentRow]#">
			</cfloop>
			<cfif findNoCase('redesign',Session.gitBranch) GT 0>
				<cfset row["id_link"] = "<a href='/transactions/Deaccession.cfm?action=edit&transaction_id=#search.transaction_id#' target='_blank'>#search.deacc_number#</a>">
			<cfelse>
				<cfset row["id_link"] = "<a href='/transactions/Deaccession.cfm?action=edit&transaction_id=#search.transaction_id#' target='_blank'>#search.deacc_number#</a>">
			</cfif>
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
	<cfreturn #serializeJSON(data)#>
</cffunction>

<cffunction name="getBorrows" access="remote" returntype="any" returnformat="json">
	<cfargument name="borrow_number" type="string" required="no">
	<cfargument name="lenders_trans_num_cde" type="string" required="no">
	<cfargument name="lender_loan_type" type="string" required="no">
	<cfargument name="borrow_status" type="string" required="no">
	<cfargument name="borrow_sci_name" type="string" required="no">
	<cfargument name="borrow_catalog_number" type="string" required="no">
	<cfargument name="borrow_spec_prep" type="string" required="no">
	<cfargument name="borrow_type_status" type="string" required="no">
	<cfargument name="trans_date" type="string" required="no">
	<cfargument name="to_trans_date" type="string" required="no">
	<cfargument name="date_entered" type="string" required="no">
	<cfargument name="to_date_entered" type="string" required="no">
	<cfargument name="received_date" type="string" required="no">
	<cfargument name="to_received_date" type="string" required="no">
	<cfargument name="due_date" type="string" required="no">
	<cfargument name="to_due_date" type="string" required="no">
	<cfargument name="lenders_loan_date" type="string" required="no">
	<cfargument name="to_lenders_loan_date" type="string" required="no">
	<cfargument name="return_acknowledged_date" type="string" required="no">
	<cfargument name="to_return_acknowledged_date" type="string" required="no">
	<cfargument name="lenders_invoice_returned" type="string" required="no">
	<cfargument name="shipment_count" type="string" required="no">
	<cfargument name="foreign_shipments" type="string" required="no">

	<!--- set start/end date range terms to same if only one is specified --->
	<cfif isdefined("trans_date") and len(#trans_date#) gt 0>
		<cfif not isdefined("to_trans_date") or len(to_trans_date) is 0>
			<cfset to_trans_date=trans_date>
		</cfif>
		<!--- support search on just a year or pair of years --->
		<cfif len(#trans_date#) EQ 4>
			<cfset trans_date = "#trans_date#-01-01">
		</cfif>
		<cfif len(#to_trans_date#) EQ 4>
			<cfset to_trans_date = "#to_trans_date#-12-31">
		</cfif>
	</cfif>
	<cfif isdefined("date_entered") and len(#date_entered#) gt 0>
		<cfif not isdefined("to_date_entered") or len(to_date_entered) is 0>
			<cfset to_date_entered=date_entered>
		</cfif>
		<!--- support search on just a year or pair of years --->
		<cfif len(#date_entered#) EQ 4>
			<cfset date_entered = "#date_entered#-01-01">
		</cfif>
		<cfif len(#to_date_entered#) EQ 4>
			<cfset to_date_entered = "#to_date_entered#-12-31">
		</cfif>
	</cfif>
	<cfif isdefined("received_date") and len(#received_date#) gt 0>
		<cfif not isdefined("to_received_date") or len(to_received_date) is 0>
			<cfset to_received_date=received_date>
		</cfif>
		<!--- support search on just a year or pair of years --->
		<cfif len(#received_date#) EQ 4>
			<cfset received_date = "#received_date#-01-01">
		</cfif>
		<cfif len(#to_received_date#) EQ 4>
			<cfset to_received_date = "#to_received_date#-12-31">
		</cfif>
	</cfif>
	<cfif isdefined("due_date") and len(#due_date#) gt 0>
		<cfif not isdefined("to_due_date") or len(to_due_date) is 0>
			<cfset to_due_date=due_date>
		</cfif>
		<!--- support search on just a year or pair of years --->
		<cfif len(#due_date#) EQ 4>
			<cfset due_date = "#due_date#-01-01">
		</cfif>
		<cfif len(#to_due_date#) EQ 4>
			<cfset to_due_date = "#to_due_date#-12-31">
		</cfif>
	</cfif>
	<cfif isdefined("return_acknowledged_date") and len(#return_acknowledged_date#) gt 0>
		<cfif not isdefined("to_return_acknowledged_date") or len(to_return_acknowledged_date) is 0>
			<cfset to_return_acknowledged_date=return_acknowledged_date>
		</cfif>
		<!--- support search on just a year or pair of years --->
		<cfif len(#return_acknowledged_date#) EQ 4>
			<cfset return_acknowledged_date = "#return_acknowledged_date#-01-01">
		</cfif>
		<cfif len(#to_return_acknowledged_date#) EQ 4>
			<cfset to_return_acknowledged_date = "#to_return_acknowledged_date#-12-31">
		</cfif>
	</cfif>
	<cfif isdefined("lenders_loan_date") and len(#lenders_loan_date#) gt 0>
		<cfif not isdefined("to_lenders_loan_date") or len(to_lenders_loan_date) is 0>
			<cfset to_lenders_loan_date=lenders_loan_date>
		</cfif>
		<!--- support search on just a year or pair of years --->
		<cfif len(#lenders_loan_date#) EQ 4>
			<cfset lenders_loan_date = "#lenders_loan_date#-01-01">
		</cfif>
		<cfif len(#to_lenders_loan_date#) EQ 4>
			<cfset to_lenders_loan_date = "#to_lenders_loan_date#-12-31">
		</cfif>
	</cfif>

	<!--- do the search --->
	<cfset data = ArrayNew(1)>
	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result" timeout="#Application.query_timeout#">
			SELECT distinct
				trans.transaction_id,
				borrow_number,
				lender_loan_type,
				lenders_trans_num_cde,
				lenders_invoice_returned_fg,
				decode(lenders_invoice_returned_fg,1,'Yes','No') as lenders_invoice_returned,
				lenders_instructions,
				nature_of_material,
				no_of_specimens,
				ret_acknowledged_by,
				to_char(due_date,'YYYY-MM-DD') as due_date,
				to_char(received_date,'YYYY-MM-DD') as received_date,
				to_char(return_acknowledged_date,'YYYY-MM-DD') as return_acknowledged_date,
				to_char(trans_date,'YYYY-MM-DD') as borrow_date,
				to_char(date_entered,'YYYY-MM-DD') as date_entered,
				to_char(lenders_loan_date,'YYYY-MM-DD') as lenders_loan_datedate,
				borrow_status,
				description_of_borrow,
				trans_remarks,
				collection,
				collection.collection_cde,
				project_name,
				project.project_id pid,
				MCZBASE.get_permits_for_trans(trans.transaction_id) permits,
				MCZBASE.count_shipments_for_trans(trans.transaction_id) shipment_count,
				COUNT_FOREIGNSHIP_FOR_TRANS(trans.transaction_id) as foreign_shipments,
				(select count(*) from borrow_item where borrow_item.transaction_id = trans.transaction_id) as item_count, 
				concattransagent(trans.transaction_id,'entered by') ent_agent,
				concattransagent(trans.transaction_id,'in-house authorized by') auth_agent,
				concattransagent(trans.transaction_id,'outside authorized by') outside_auth_agent,
				concattransagent(trans.transaction_id,'lending institution') lending_institution_agent,
				concattransagent(trans.transaction_id,'received by') rec_agent,
				concattransagent(trans.transaction_id,'borrow overseen by') borrowoverseenby_agent,
				concattransagent(trans.transaction_id,'for use by') foruseby_agent,
				concattransagent(trans.transaction_id,'received from') recfrom_agent,
				concattransagent(trans.transaction_id,'in-house contact') inHouse_agent,
				concattransagent(trans.transaction_id,'additional in-house contact') addInhouse_agent,
				concattransagent(trans.transaction_id,'outside contact') outside_agent,
				concattransagent(trans.transaction_id,'additional outside contact') addOutside_agent
			FROM
			 	borrow left join trans on borrow.transaction_id = trans.transaction_id
				left join permit_trans on trans.transaction_id = permit_trans.transaction_id
				left join permit on permit_trans.permit_id = permit.permit_id
				left join collection on trans.collection_id=collection.collection_id
				left join project_trans on trans.transaction_id = project_trans.transaction_id
				left join project on project_trans.project_id = project.project_id
				<cfif (isdefined("trans_agent_role_1") AND len(trans_agent_role_1) gt 0) OR (isdefined("agent_1") AND len(agent_1) gt 0) >
					left join trans_agent trans_agent_1 on trans.transaction_id = trans_agent_1.transaction_id
				</cfif>
				<cfif not isdefined("agent_1_id") OR len(agent_1_id) eq 0 >
					<cfif isdefined("agent_1") AND len(agent_1) gt 0 >
						left join preferred_agent_name trans_agent_name_1 on trans_agent_1.agent_id = trans_agent_name_1.agent_id
					</cfif>
				</cfif>
				<cfif (isdefined("trans_agent_role_2") AND len(trans_agent_role_2) gt 0) OR (isdefined("agent_2") AND len(agent_2) gt 0) >
					left join trans_agent trans_agent_2 on trans.transaction_id = trans_agent_2.transaction_id
				</cfif>
				<cfif not isdefined("agent_2_id") OR len(agent_2_id) eq 0 >
					<cfif isdefined("agent_2") AND len(agent_2) gt 0 >
						left join preferred_agent_name trans_agent_name_2 on trans_agent_2.agent_id = trans_agent_name_2.agent_id
					</cfif>
				</cfif>
				<cfif (isdefined("trans_agent_role_3") AND len(trans_agent_role_3) gt 0) OR (isdefined("agent_3") AND len(agent_3) gt 0) >
					left join trans_agent trans_agent_3 on trans.transaction_id = trans_agent_3.transaction_id
				</cfif>
				<cfif not isdefined("agent_3_id") OR len(agent_3_id) eq 0 >
					<cfif isdefined("agent_3") AND len(agent_3) gt 0 >
						left join preferred_agent_name trans_agent_name_3 on trans_agent_3.agent_id = trans_agent_name_3.agent_id
					</cfif>
				</cfif>
				<cfif (isdefined("permit_id") AND len(#permit_id#) gt 0) OR (isdefined("permit_type") AND len(#permit_type#) GT 0) OR (isdefined("permit_specific_type") AND len(#permit_specific_type#) GT 0) >
					left join shipment on borrow.transaction_id = shipment.transaction_id
					left join permit_shipment on shipment.shipment_id = permit_shipment.shipment_id
					left join permit permit_from_shipment on  permit_shipment.permit_id = permit_from_shipment.permit_id
				</cfif>
				<cfif (isdefined("borrow_catalog_number") AND len(borrow_catalog_number) gt 0) 
						or (isdefined("borrow_sci_name") AND len(borrow_sci_name) gt 0) 
						or (isdefined("borrow_spec_prep") AND len(borrow_spec_prep) gt 0) 
						or (isdefined("borrow_type_status") AND len(borrow_type_status) gt 0) 
				>
					left join borrow_item on borrow.transaction_id = borrow_item.transaction_id
				</cfif>
				<cfif isdefined("IssuedByAgent") and len(#IssuedByAgent#) gt 0>
					<cfif not isdefined("issued_by_id") or len(#issued_by_id#) EQ 0>
						left join preferred_agent_name issuedBy on permit.issued_by_agent_id = issuedBy.agent_id
					</cfif>
				</cfif>
				<cfif isdefined("IssuedToAgent") and len(#IssuedToAgent#) gt 0>
					<cfif not isdefined("issued_to_id") or len(#issued_to_id#) EQ 0>
						left join preferred_agent_name issuedTo on permit.issued_to_agent_id = issuedTo.agent_id
					</cfif>
				</cfif>
			WHERE 
				borrow.transaction_id is not null
				<cfif isDefined("borrow_number") and len(borrow_number) gt 0>
					<cfif left(borrow_number,1) is "=">
						AND borrow_number = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(borrow_number,len(borrow_number)-1)#">
					<cfelse>
						<cfif find(',',borrow_number) GT 0>
							AND borrow_number in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#borrow_number#" list="yes"> )
						<cfelse>
							AND borrow_number LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#borrow_number#%">
						</cfif>
					</cfif>
				</cfif>
				<cfif isDefined("lenders_trans_num_cde") and len(lenders_trans_num_cde) gt 0>
					<cfif left(lenders_trans_num_cde,1) is "=">
						AND lenders_trans_num_cde = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(lenders_trans_num_cde,len(lenders_trans_num_cde)-1)#">
					<cfelse>
						<cfif find(',',lenders_trans_num_cde) GT 0>
							AND lenders_trans_num_cde in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#lenders_trans_num_cde#" list="yes"> )
						<cfelse>
							AND lenders_trans_num_cde LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#lenders_trans_num_cde#%">
						</cfif>
					</cfif>
				</cfif>
				<cfif isDefined("borrow_status") and len(borrow_status) gt 0>
					<cfif left(borrow_status,1) is "!">
						AND upper(borrow_status) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(borrow_status,len(borrow_status)-1))#"> 
					<cfelse>
						AND borrow_status like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#borrow_status#">
					</cfif>
				</cfif>
				<cfif isDefined("collection_id") and collection_id gt 0>
					AND collection.collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_id#">
				</cfif>
				<cfif isdefined("trans_agent_role_1") AND len(trans_agent_role_1) gt 0>
					<cfif isdefined("agent_1") AND agent_1 EQ "NULL">
						AND trans.transaction_id NOT IN (select transaction_id from trans_agent where trans_agent_role = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trans_agent_role_1#">)
					<cfelse>
						AND trans_agent_1.trans_agent_role = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trans_agent_role_1#">
					</cfif>
				</cfif>
				<cfif isdefined("agent_1_id") AND len(agent_1_id) gt 0>
					AND upper(trans_agent_1.agent_id) like <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_1_id#">
				<cfelseif isdefined("agent_1") AND agent_1 EQ "NOT NULL">
					<!--- not need to add not null clause, just skip adding match on name --->
				<cfelseif isdefined("agent_1") AND agent_1 EQ "NULL">
					<!--- need to exclude or query clauses will be contradictory --->
				<cfelseif isdefined("agent_1") AND len(agent_1) gt 0>
					AND upper(trans_agent_name_1.agent_name) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(agent_1)#%" >
				</cfif>
				<cfif isdefined("trans_agent_role_2") AND len(trans_agent_role_2) gt 0>
					<cfif isdefined("agent_2") AND agent_2 EQ "NULL">
						AND trans.transaction_id NOT IN (select transaction_id from trans_agent where trans_agent_role = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trans_agent_role_2#">)
					<cfelse>
						AND trans_agent_2.trans_agent_role = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trans_agent_role_2#">
					</cfif>
				</cfif>
				<cfif isdefined("agent_2_id") AND len(agent_2_id) gt 0>
					AND upper(trans_agent_2.agent_id) like <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_2_id#">
				<cfelseif isdefined("agent_2") AND agent_2 EQ "NOT NULL">
					<!--- not need to add not null clause, just skip adding match on name --->
				<cfelseif isdefined("agent_2") AND agent_2 EQ "NULL">
					<!--- need to exclude or query clauses will be contradictory --->
				<cfelseif isdefined("agent_2") AND len(agent_2) gt 0>
					AND upper(trans_agent_name_2.agent_name) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(agent_2)#%" >
				</cfif>
				<cfif isdefined("trans_agent_role_3") AND len(trans_agent_role_3) gt 0>
					<cfif isdefined("agent_3") AND agent_3 EQ "NULL">
						AND trans.transaction_id NOT IN (select transaction_id from trans_agent where trans_agent_role = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trans_agent_role_3#">)
					<cfelse>
						AND trans_agent_3.trans_agent_role = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trans_agent_role_3#">
					</cfif>
				</cfif>
				<cfif isdefined("agent_3_id") AND len(agent_3_id) gt 0>
					AND upper(trans_agent_3.agent_id) like <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_3_id#">
				<cfelseif isdefined("agent_3") AND agent_3 EQ "NOT NULL">
					<!--- not need to add not null clause, just skip adding match on name --->
				<cfelseif isdefined("agent_3") AND agent_3 EQ "NULL">
					<!--- need to exclude or query clauses will be contradictory --->
				<cfelseif isdefined("agent_3") AND len(agent_3) gt 0>
					AND upper(trans_agent_name_3.agent_name) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(agent_3)#%" >
				</cfif>
				<cfif isdefined("trans_date") and len(trans_date) gt 0>
					AND trans_date between 
						to_date(<cfqueryparam cfsqltype="CF_SQL_DATE" value='#dateformat(trans_date, "yyyy-mm-dd")#'>) and
						(to_date(<cfqueryparam cfsqltype="CF_SQL_DATE" value='#dateformat(to_trans_date, "yyyy-mm-dd")#'>) + (86399/86400) )
				</cfif>
				<cfif isdefined("date_entered") and len(date_entered) gt 0>
					AND date_entered between 
						to_date(<cfqueryparam cfsqltype="CF_SQL_DATE" value='#dateformat(date_entered, "yyyy-mm-dd")#'>) and
						(to_date(<cfqueryparam cfsqltype="CF_SQL_DATE" value='#dateformat(to_date_entered, "yyyy-mm-dd")#'>) + (86399/86400) )
				</cfif>
				<cfif isdefined("received_date") and len(received_date) gt 0>
					AND borrow.received_date between 
						to_date(<cfqueryparam cfsqltype="CF_SQL_DATE" value='#dateformat(received_date, "yyyy-mm-dd")#'>) and
						(to_date(<cfqueryparam cfsqltype="CF_SQL_DATE" value='#dateformat(to_received_date, "yyyy-mm-dd")#'>) + (86399/86400) )
				</cfif>
				<cfif isdefined("due_date") and len(due_date) gt 0>
					AND due_date between 
						to_date(<cfqueryparam cfsqltype="CF_SQL_DATE" value='#dateformat(due_date, "yyyy-mm-dd")#'>) and
						(to_date(<cfqueryparam cfsqltype="CF_SQL_DATE" value='#dateformat(to_due_date, "yyyy-mm-dd")#'>) + (86399/86400) )
				</cfif>
				<cfif isdefined("lenders_loan_date") and len(lenders_loan_date) gt 0>
					AND lenders_loan_date between 
						to_date(<cfqueryparam cfsqltype="CF_SQL_DATE" value='#dateformat(lenders_loan_date, "yyyy-mm-dd")#'>) and
						(to_date(<cfqueryparam cfsqltype="CF_SQL_DATE" value='#dateformat(to_lenders_loan_date, "yyyy-mm-dd")#'>) + (86399/86400) )
				</cfif>
				<cfif isdefined("return_acknowledged_date") and len(return_acknowledged_date) gt 0>
					AND return_acknowledged_date between 
						to_date(<cfqueryparam cfsqltype="CF_SQL_DATE" value='#dateformat(return_acknowledged_date, "yyyy-mm-dd")#'>) and
						(to_date(<cfqueryparam cfsqltype="CF_SQL_DATE" value='#dateformat(to_return_acknowledged_date, "yyyy-mm-dd")#'>) + (86399/86400) )
				</cfif>
				<cfif isdefined("nature_of_material") AND len(#nature_of_material#) gt 0>
					AND upper(nature_of_material) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value='%#ucase(nature_of_material)#%'>
				</cfif>
				<cfif isdefined("lenders_invoice_returned") AND len(#lenders_invoice_returned#) gt 0 >
					AND borrow.lenders_invoice_returned_fg = <cfqueryparam  cfsqltype="CF_SQL_DECIMAL" value="#lenders_invoice_returned#" >
				</cfif>
				<cfif isdefined("borrow_catalog_number") AND len(#borrow_catalog_number#) gt 0 >
					AND borrow_item.catalog_number like <cfqueryparam  cfsqltype="CF_SQL_VARCHAR" value="%#borrow_catalog_number#%" >
				</cfif>
				<cfif isdefined("borrow_sci_name") AND len(#borrow_sci_name#) gt 0 >
					AND borrow_item.sci_name like <cfqueryparam  cfsqltype="CF_SQL_VARCHAR" value="%#borrow_sci_name#%" >
				</cfif>
				<cfif isdefined("no_of_spec") AND len(#no_of_spec#) gt 0 >
					AND borrow_item.no_of_spec = <cfqueryparam  cfsqltype="CF_SQL_VARCHAR" value="#no_of_spec#" >
				</cfif>
				<cfif isdefined("borrow_spec_prep") AND len(#borrow_spec_prep#) gt 0 >
					AND borrow_item.spec_prep like <cfqueryparam  cfsqltype="CF_SQL_VARCHAR" value="%#borrow_spec_prep#%" >
				</cfif>
				<cfif isdefined("borrow_type_status") AND len(#borrow_type_status#) gt 0 >
					<cfif borrow_type_status EQ 'NULL'>
						AND borrow_item.type_status is NULL
					<cfelseif borrow_type_status EQ 'NOT NULL'>
						AND borrow_item.type_status is NOT NULL
					<cfelse>
						AND borrow_item.type_status like <cfqueryparam  cfsqltype="CF_SQL_VARCHAR" value="%#borrow_type_status#%" > 
					</cfif>
				</cfif>
				<cfif isdefined("country_of_origin") AND len(#country_of_origin#) gt 0 >
					AND borrow_item.country_of_origin = <cfqueryparam  cfsqltype="CF_SQL_VARCHAR" value="#country_of_origin#" > 
				</cfif>
				<cfif  isdefined("lenders_loan_type") and len(#lenders_loan_type#) gt 0>
					<cfif left(lenders_loan_type,1) is "!">
						AND upper(lenders_loan_type) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(lenders_loan_type,len(lenders_loan_type)-1))#"> 
					<cfelse>
						AND lenders_loan_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#lenders_loan_type#">
					</cfif>
				</cfif>
				<cfif isdefined("trans_remarks") AND len(#trans_remarks#) gt 0>
					AND upper(trans_remarks) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value='%#ucase(trans_remarks)#%'>
				</cfif>
				<cfif isdefined("permit_id") AND len(#permit_id#) gt 0>
					AND ( 
						permit.permit_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#permit_id#">
						OR
						permit_from_shipment.permit_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#permit_id#">
					)
				</cfif>
				<cfif  isdefined("permit_type") and len(#permit_type#) gt 0>
					AND ( 
						permit.permit_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#permit_type#">
						OR
						permit_from_shipment.permit_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#permit_type#">
					)
				</cfif>
				<cfif  isdefined("permit_specific_type") and len(#permit_specific_type#) gt 0>
					AND ( 
						permit.specific_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#permit_specific_type#">
						OR
						permit_from_shipment.specific_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#permit_specific_type#">
					)
				</cfif>
				<cfif isdefined("collection_id") AND collection_id gt 0>
					AND trans.collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_id#">
				</cfif>
				<cfif isdefined("issued_by_id") and len(#issued_by_id#) gt 0>
					AND upper(permit.issued_by_agent_id) = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#issued_by_id#">
				<cfelse>
					<cfif isdefined("IssuedByAgent") and len(#IssuedByAgent#) gt 0>
						AND upper(issuedBy.agent_name) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(IssuedByAgent)#%">
					</cfif>
				</cfif>
				<cfif isdefined("issued_to_id") and len(#issued_to_id#) gt 0>
					AND upper(permit.issued_to_agent_id) = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#issued_to_id#">
				<cfelse>
					<cfif isdefined("IssuedToAgent") and len(#IssuedToAgent#) gt 0>
						AND upper(issuedTo.agent_name) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(IssuedToAgent)#%">
					</cfif>
				</cfif>
				<cfif isdefined("permit_contact_id") and len(#permit_contact_id#) gt 0>
					AND upper(permit.contact_agent_id) = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#permit_contact_id#">
				</cfif>
				<cfif isdefined("restriction_summary") and len(#restriction_summary#) gt 0>
					<cfif restriction_summary EQ 'NULL'>
						AND upper(permit.restriction_summary) is NULL
					<cfelseif restriction_summary EQ 'NOT NULL'>
						AND upper(permit.restriction_summary) is NOT NULL
					<cfelse>
						AND upper(permit.restriction_summary) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(restriction_summary)#%">
					</cfif>
				</cfif>
				<cfif isdefined("benefits_summary") and len(#benefits_summary#) gt 0>
					<cfif benefits_summary EQ 'NULL'>
						AND upper(permit.benefits_summary) is NULL
					<cfelseif benefits_summary EQ 'NOT NULL'>
						AND upper(permit.benefits_summary) is NOT NULL
					<cfelse>
						AND upper(permit.benefits_summary) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(benefits_summary)#%">
					</cfif>
				</cfif>
				<cfif isdefined("benefits_provided") and len(#benefits_provided#) gt 0>
					<cfif benefits_provided EQ 'NULL'>
						AND upper(permit.benefits_provided) is NULL
					<cfelseif benefits_provided EQ 'NOT NULL'>
						AND upper(permit.benefits_provided) is NOT NULL
					<cfelse>
						AND upper(permit.benefits_provided) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(benefits_provided)#%">
					</cfif>
				</cfif>
				<cfif  isdefined("permit_remarks") and len(#permit_remarks#) gt 0>
					AND upper(permit_remarks) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(permit_remarks)#%">
				</cfif>
				<cfif  isdefined("shipment_count") and len(#shipment_count#) gt 0>
					<cfif shipment_count IS "0">
						AND trans.transaction_id NOT IN
							(select transaction_id from shipment)
					<cfelseif shipment_count IS "1">
						AND MCZBASE.COUNT_SHIPMENTS_FOR_TRANS(trans.transaction_id) = 1
					<cfelseif shipment_count IS "1+">
						AND trans.transaction_id IN
							(select transaction_id from shipment)
					<cfelseif shipment_count IS "2+">
						AND MCZBASE.COUNT_SHIPMENTS_FOR_TRANS(trans.transaction_id) > 1
					<cfelseif shipment_count IS "3+">
						AND MCZBASE.COUNT_SHIPMENTS_FOR_TRANS(trans.transaction_id) > 2
					</cfif>
				</cfif>
				<cfif  isdefined("foreign_shipments") and len(#foreign_shipments#) gt 0>
					<cfif foreign_shipments IS "0">
						AND trans.transaction_id NOT IN
							(select transaction_id from shipment where foreign_shipment_fg = 1)
					<cfelseif foreign_shipments IS "1+">
						AND trans.transaction_id IN
							(select transaction_id from shipment where foreign_shipment_fg = 1)
					</cfif>
				</cfif>
			ORDER BY 
				regexp_substr(borrow_number,'^[B0-9]+-'), 
				to_number(replace(regexp_substr(borrow_number,'-[0-9]+-'),'-','')), 
				borrow_number
		</cfquery>
		<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfloop list="#ArrayToList(search.getColumnNames())#" index="col" >
				<cfset row["#lcase(col)#"] = "#search[col][currentRow]#">
			</cfloop>
			<cfset row["id_link"] = "<a href='/transactions/Borrow.cfm?Action=edit&transaction_id=#search.transaction_id#' target='_blank'>#search.borrow_number#</a>">
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
	<cfreturn #serializeJSON(data)#>
</cffunction>

</cfcomponent>
