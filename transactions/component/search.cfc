<!---
specimens/component/records_search.cfc

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

	<cfset data = ArrayNew(1)>
	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			SELECT 
				transaction_view.transaction_id, 
				transaction_view.transaction_type,
				to_char(trans_date,'YYYY-MM-DD') trans_date,
				transaction_view.nature_of_material, 
				transaction_view.trans_remarks,
				collection_cde, 
				collection,
				transaction_view.specific_number, 
				transaction_view.specific_type, 
				transaction_view.status, 
				concattransagent(transaction_view.transaction_id,'entered by') as entered_by_agent,
				concattransagent(transaction_view.transaction_id,'authorized by') auth_agent,
				concattransagent(transaction_view.transaction_id,'received by') rec_agent,
				concattransagent(transaction_view.transaction_id,'for use by') foruseby_agent,
				concattransagent(transaction_view.transaction_id,'in-house contact') inHouse_agent,
				concattransagent(transaction_view.transaction_id,'additional in-house contact') addInhouse_agent,
				concattransagent(transaction_view.transaction_id,'additional outside contact') addOutside_agent,
				concattransagent(transaction_view.transaction_id,'recipient institution') recip_inst
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
			WHERE
				transaction_view.transaction_id > 0
				<cfif isDefined("number") and len(number) gt 0>
					and specific_number like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#number#%">
				</cfif>
				<cfif isDefined("status") and len(status) gt 0>
					and status like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#status#">
				</cfif>
				<cfif isDefined("collection_id") and collection_id gt 0>
					and collection.collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_id#">
				</cfif>
				<cfif isdefined("trans_agent_role_1") AND len(trans_agent_role_1) gt 0>
					AND trans_agent_1.trans_agent_role = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trans_agent_role_1#">
				</cfif>
				<cfif isdefined("agent_1_id") AND len(agent_1_id) gt 0>
					AND upper(trans_agent_1.agent_id) like <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_1_id#">
				<cfelseif isdefined("agent_1") AND len(agent_1) gt 0>
					AND upper(trans_agent_name_1.agent_name) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(agent_1)#%" >
				</cfif>
				<cfif isdefined("trans_agent_role_2") AND len(trans_agent_role_2) gt 0>
					AND trans_agent_2.trans_agent_role = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trans_agent_role_2#">
				</cfif>
				<cfif isdefined("agent_2_id") AND len(agent_2_id) gt 0>
					AND upper(trans_agent_2.agent_id) like <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_2_id#">
				<cfelseif isdefined("agent_2") AND len(agent_2) gt 0>
					AND upper(trans_agent_name_2.agent_name) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(agent_2)#%" >
				</cfif>
				<cfif isdefined("trans_agent_role_3") AND len(trans_agent_role_3) gt 0>
					AND trans_agent_3.trans_agent_role = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trans_agent_role_3#">
				</cfif>
				<cfif isdefined("agent_3_id") AND len(agent_3_id) gt 0>
					AND upper(trans_agent_3.agent_id) like <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_3_id#">
				<cfelseif isdefined("agent_3") AND len(agent_3) gt 0>
					AND upper(trans_agent_name_3.agent_name) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(agent_3)#%" >
				</cfif>
		</cfquery>
		<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfif isdefined("Application.header_image")>
				<!--- Links for integration on production --->
				<cfswitch expression="#search.transaction_type#">
					<cfcase value="loan"><cfset targetform = "Loan.cfm?action=editLoan&"></cfcase>
					<cfcase value="accn"><cfset targetform = "editAccn.cfm?action=edit&"></cfcase>
					<cfcase value="borrow"><cfset targetform = "Borrow.cfm?action=edit&"></cfcase>
					<cfcase value="deaccession"><cfset targetform = "Deaccession.cfm?action=editDeacc&"></cfcase>
				</cfswitch>
			<cfelse>
				<!--- Links for redesign --->
				<cfswitch expression="#search.transaction_type#">
					<cfcase value="loan"><cfset targetform = "Loan.cfm?action=editLoan&"></cfcase>
					<cfdefaultcase ><cfset targetform = "transaction.cfm?"></cfdefaultcase>
				</cfswitch>
			</cfif>
			<cfset row = StructNew()>
			<cfset row["transaction_id"] = "#search.transaction_id#">
			<cfset row["trans_date"] = "#search.trans_date#">
			<cfset row["transaction_type"] = "#search.transaction_type#">
			<cfset row["nature_of_material"] = "#search.nature_of_material#">
			<cfset row["trans_remarks"] = "#search.trans_remarks#">
			<cfset row["collection_cde"] = "#search.collection_cde#">
			<cfset row["collection"] = "#search.collection#">
			<cfset row["number"] = "#search.specific_number#">
			<cfset row["type"] = "#search.specific_type#">
			<cfset row["status"] = "#search.status#">
			<cfset row["entered_by"] = "#search.entered_by_agent#">
			<cfset row["authorized_by"] = "#search.auth_agent#">
			<cfset row["received_by"] = "#search.rec_agent#">
			<cfset row["for_use_by"] = "#search.foruseby_agent#">
			<cfset row["in-house_contact"] = "#search.inHouse_agent#">
			<cfset row["additional_inhouse_contact"] = "#search.addInHouse_agent#">
			<cfset row["additional_outside_contact"] = "#search.addOutside_agent#">
			<cfset row["recipient_institution"] = "#search.recip_inst#">
			<cfif isdefined("Application.header_image")>
				<!--- Links for integration on production --->
				<cfset row["id_link"] = "<a href='/#targetform#transaction_id=#search.transaction_id#' target='_blank'>#search.specific_number#</a>">
			<cfelse>
				<!--- Links for redesign --->
				<cfset row["id_link"] = "<a href='/transactions/#targetform#transaction_id=#search.transaction_id#' target='_blank'>#search.specific_number#</a>">
			</cfif>
			<cfset data[i]  = row>
			<cfset i = i + 1>
		</cfloop>
		<cfreturn #serializeJSON(data)#>
	<cfcatch>
      <cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset message = trim("Error processing #GetFunctionCalledName()#: " & cfcatch.message & " " & cfcatch.detail & " " & queryError)  >
      <cfheader statusCode="500" statusText="#message#">
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
    <cfargument name="permit_num" type="string" required="no">
    <cfargument name="permit_id" type="string" required="no">
    <cfargument name="return_due_date" type="string" required="no">
    <cfargument name="to_return_due_date" type="string" required="no">
    <cfargument name="closed_date" type="string" required="no">
    <cfargument name="to_closed_date" type="string" required="no">
    <cfargument name="trans_date" type="string" required="no">
    <cfargument name="to_trans_date" type="string" required="no">
    <cfargument name="trans_agent_role_1" type="string" required="no">
    <cfargument name="agent_1" type="string" required="no">
    <cfargument name="agent_1_id" type="string" required="no">
    <cfargument name="trans_agent_role_2" type="string" required="no">
    <cfargument name="agent_2" type="string" required="no">
    <cfargument name="agent_2_id" type="string" required="no">
    <cfargument name="trans_agent_role_3" type="string" required="no">
    <cfargument name="agent_3" type="string" required="no">
    <cfargument name="agent_3_id" type="string" required="no">
    <cfargument name="parent_loan_number" type="string" required="no">

	<cfif isdefined("return_due_date") and len(return_due_date) gt 0>
		<cfif not isdefined("to_return_due_date") or len(to_return_due_date) is 0>
			<cfset to_return_due_date=return_due_date>
		</cfif>
	</cfif>
	<cfif isdefined("closed_date") and len(closed_date) gt 0>
		<cfif not isdefined("to_closed_date") or len(to_closed_date) is 0>
			<cfset to_closed_date=closed_date>
		</cfif>
	</cfif>
	<cfif isdefined("trans_date") and len(#trans_date#) gt 0>
		<cfif not isdefined("to_trans_date") or len(to_trans_date) is 0>
			<cfset to_trans_date=trans_date>
		</cfif>
	</cfif>
	<cfset data = ArrayNew(1)>
	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			select distinct
				trans.transaction_id,
				to_char(trans_date,'YYYY-MM-DD') trans_date,
				trans_remarks,
				loan.loan_number,
				loan.loan_type loan_type,
				ctloan_type.scope loan_type_scope,
				loan.loan_status,
				loan.loan_instructions,
				loan.loan_description,
				concattransagent(trans.transaction_id,'authorized by') auth_agent,
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
				collection.collection_cde
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
				<cfif (isdefined("part_name") AND len(part_name) gt 0) or (isdefined("coll_obj_disposition") AND len(coll_obj_disposition) gt 0)>
					left join loan_item on loan.transaction_id=loan_item.transaction_id 
					left join coll_object on loan_item.collection_object_id=coll_object.collection_object_id
					left join specimen_part on coll_object.collection_object_id = specimen_part.collection_object_id 
				</cfif>
				<cfif isdefined("permit_id") AND len(#permit_id#) gt 0>
					left join shipment on loan.transaction_id = shipment.transaction_id
					left join permit_shipment on shipment.shipment_id = permit_shipment.shipment_id
				</cfif>
				<cfif isdefined("parent_loan_number") AND len(parent_loan_number) gt 0 >
					left join loan_relations on loan.transaction_id = loan_relations.related_transaction_id
					left join loan parent_loan on loan_relations.transaction_id = parent_loan.transaction_id
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
						to_date(<cfqueryparam cfsqltype="CF_SQL_DATE" value='#dateformat(to_return_due_date, "yyyy-mm-dd")#'>)
				</cfif>
				<cfif isdefined("closed_date") and len(closed_date) gt 0>
					AND loan.closed_date between 
						to_date(<cfqueryparam cfsqltype="CF_SQL_DATE" value='#dateformat(closed_date, "yyyy-mm-dd")#'>) and
						to_date(<cfqueryparam cfsqltype="CF_SQL_DATE" value='#dateformat(to_closed_date, "yyyy-mm-dd")#'>)
				</cfif>
				<cfif isdefined("trans_date") and len(trans_date) gt 0>
					AND trans_date between 
						to_date(<cfqueryparam cfsqltype="CF_SQL_DATE" value='#dateformat(trans_date, "yyyy-mm-dd")#'>) and
						to_date(<cfqueryparam cfsqltype="CF_SQL_DATE" value='#dateformat(to_trans_date, "yyyy-mm-dd")#'>)
				</cfif>
				<cfif isdefined("trans_agent_role_1") AND len(trans_agent_role_1) gt 0>
					AND trans_agent_1.trans_agent_role = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trans_agent_role_1#">
				</cfif>
				<cfif isdefined("agent_1_id") AND len(agent_1_id) gt 0>
					AND upper(trans_agent_1.agent_id) like <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_1_id#">
				<cfelseif isdefined("agent_1") AND len(agent_1) gt 0>
					AND upper(trans_agent_name_1.agent_name) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(agent_1)#%" >
				</cfif>
				<cfif isdefined("trans_agent_role_2") AND len(trans_agent_role_2) gt 0>
					AND trans_agent_2.trans_agent_role = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trans_agent_role_2#">
				</cfif>
				<cfif isdefined("agent_2_id") AND len(agent_2_id) gt 0>
					AND upper(trans_agent_2.agent_id) like <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_2_id#">
				<cfelseif isdefined("agent_2") AND len(agent_2) gt 0>
					AND upper(trans_agent_name_2.agent_name) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(agent_2)#%" >
				</cfif>
				<cfif isdefined("trans_agent_role_3") AND len(trans_agent_role_3) gt 0>
					AND trans_agent_3.trans_agent_role = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trans_agent_role_3#">
				</cfif>
				<cfif isdefined("agent_3_id") AND len(agent_3_id) gt 0>
					AND upper(trans_agent_3.agent_id) like <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_3_id#">
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
				<cfif isdefined("parent_loan_number") AND len(parent_loan_number) gt 0 >
					AND loan_relations.relation_type = 'Subloan'
					AND parent_loan.loan_number like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#parent_loan_number#">
				</cfif>
			ORDER BY to_number(regexp_substr (loan.loan_number, '^[0-9]+', 1, 1)), to_number(regexp_substr (loan.loan_number, '[0-9]+', 1, 2)), loan.loan_number
		</cfquery>

<!--- 

	<cfif isdefined("rec_agent") AND len(#rec_agent#) gt 0>
		<cfset sql = "#sql# AND upper(recAgnt.agent_name) LIKE '%#ucase(escapeQuotes(rec_agent))#%'">
	</cfif>
	<cfif isdefined("auth_agent") AND len(#auth_agent#) gt 0>
		<cfset sql = "#sql# AND upper(authAgnt.agent_name) LIKE '%#ucase(escapeQuotes(auth_agent))#%'">
	</cfif>
	<cfif isdefined("ent_agent") AND len(#ent_agent#) gt 0>
		<cfset sql = "#sql# AND upper(entAgnt.agent_name) LIKE '%#ucase(escapeQuotes(ent_agent))#%'">
	</cfif>
	<cfif isdefined("collection_object_id") AND len(#collection_object_id#) gt 0>
		<cfset frm="#frm#, loan_item">
		<cfset sql = "#sql# AND loan.transaction_id=loan_item.transaction_id AND loan_item.collection_object_id IN (#collection_object_id#)">
	</cfif>
	<cfif isdefined("notClosed") AND len(#notClosed#) gt 0>
		<cfset sql = "#sql# AND loan_status <> 'closed'">
	</cfif>


--->

      <cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset targetform = "Loan.cfm?action=editLoan&">
			<cfset row = StructNew()>
			<cfloop list="#ArrayToList(search.getColumnNames())#" index="col" >
				<cfset row["#lcase(col)#"] = "#search[col][currentRow]#">
			</cfloop>
			<cfif isdefined("Application.header_image")>
				<!--- Link for integration on production --->
				<cfset row["id_link"] = "<a href='/#targetform#transaction_id=#search.transaction_id#' target='_blank'>#search.loan_number#</a>">
			<cfelse>
				<!--- Link for redesign --->
				<cfset row["id_link"] = "<a href='/transactions/#targetform#transaction_id=#search.transaction_id#' target='_blank'>#search.loan_number#</a>">
			</cfif>
			<cfset data[i]  = row>
			<cfset i = i + 1>
		</cfloop>
		<cfreturn #serializeJSON(data)#>
	<cfcatch>
      <cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset message = trim("Error processing #GetFunctionCalledName()#: " & cfcatch.message & " " & cfcatch.detail & " " & queryError)  >
      <cfheader statusCode="500" statusText="#message#">
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

	<cfset data = ArrayNew(1)>
	<cftry>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			select permit.permit_id,
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
				permit_remarks
			from
				permit  
				left join preferred_agent_name issuedTo on permit.issued_by_agent_id = issuedTo.agent_id
				left join preferred_agent_name issuedBy on permit.issued_to_agent_id = issuedBy.agent_id
				left join preferred_agent_name Contact on permit.contact_agent_id = Contact.agent_id
			where
				permit.permit_id is not null 
				<cfif isdefined("IssuedByAgent") AND len(#IssuedByAgent#) gt 0>
					AND upper(issuedBy.agent_name) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#escapequotes(ucase(IssuedByAgent))#%">
				</cfif>
				<cfif isdefined("ISSUED_BY_AGENT_ID") and len(#ISSUED_BY_AGENT_ID#) gt 0>
					AND ISSUED_BY_AGENT_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#ISSUED_BY_AGENT_ID#">
				</cfif>
				<cfif isdefined("IssuedToAgent") AND len(#IssuedToAgent#) gt 0>
					AND upper(issuedTo.agent_name) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#escapequotes(ucase(IssuedToAgent))#%">
				</cfif>
				<cfif isdefined("ISSUED_TO_AGENT_ID") and len(#ISSUED_TO_AGENT_ID#) gt 0>
					AND ISSUED_TO_AGENT_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#ISSUED_TO_AGENT_ID#">
				</cfif>
				<cfif isdefined("ContactAgent") AND len(#ContactAgent#) gt 0>
					AND upper(Contact.agent_name) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(ContactAgent)#%">
				</cfif>
				<cfif isdefined("CONTACT_AGENT_ID") and len(#CONTACT_AGENT_ID#) gt 0>
					AND CONTACT_AGENT_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#CONTACT_AGENT_ID#">
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
							and to_date(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#issued_until_date#">, 'yyyy-mm-dd')
					<cfelse>
						AND upper(issued_date) like to_date(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#issued_date#">, 'yyyy-mm-dd')
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
							and to_date(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#renewed_until_date#">, 'yyyy-mm-dd')
					<cfelse>
						AND upper(renewed_date) like to_date(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#renewed_date#">, 'yyyy-mm-dd')
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
							and to_date(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#exp_until_date#">, 'yyyy-mm-dd')
					<cfelse>
						AND upper(exp_date) like to_date(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#exp_date#">, 'yyyy-mm-dd')
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
		</cfquery>
		<cfset i = 1>
		<cfloop query="search">
			<cfset targetform = "Permit.cfm?action=edit&">
			<cfset row = StructNew()>
			<cfloop list="#ArrayToList(search.getColumnNames())#" index="col" >
				<cfset row["#lcase(col)#"] = "#search[col][currentRow]#">
			</cfloop>
			<cfif isdefined("Application.header_image")>
				<!--- Link for integration on production --->
				<cfset row["id_link"] = "<a href='/#targetform#permit_id=#search.permit_id#' target='_blank'>#search.permit_number#</a>">
			<cfelse>
				<!--- Link for redesign --->
				<cfset row["id_link"] = "<a href='/transactions/#targetform#permit_id=#search.permit_id#' target='_blank'>#search.permit_number#</a>">
			</cfif>
			<cfset data[i]  = row>
			<cfset i = i + 1>
		</cfloop>
		<cfreturn #serializeJSON(data)#>
	<cfcatch>
      <cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset message = trim("Error processing #GetFunctionCalledName()#: " & cfcatch.message & " " & cfcatch.detail & " " & queryError)  >
      <cfheader statusCode="500" statusText="#message#">
	   <cfabort>
	</cfcatch>
	</cftry>
	<cfreturn #serializeJSON(data)#>
</cffunction>


</cfcomponent>
