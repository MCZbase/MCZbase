<!---
/transactions/component/functions.cfc

Copyright 2020 President and Fellows of Harvard College

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
<cfset MAGIC_TTYPE_OTHER = 'other'><!--- Special Transaction type other, which can only be set by a sysadmin --->
<cfset MAGIC_DTYPE_TRANSFER = 'transfer'><!--- Deaccession type of Transfer --->
<cfset MAGIC_DTYPE_INTERNALTRANSFER = 'transfer (internal)'><!--- Deaccession type of Transfer (internal) --->

<cfinclude template = "/shared/functionLib.cfm" runOnce="true">
<cfinclude template="/shared/component/error_handler.cfc" runOnce="true">

<cffunction name="checkAgentFlag" access="remote">
	<cfargument name="agent_id" type="numeric" required="yes">
	<cfquery name="checkAgentQuery" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select MCZBASE.get_worstagentrank(<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">) as agentrank from dual
	</cfquery>
	<cfreturn checkAgentQuery>
</cffunction>
<!-------------------------------------------->

<!--- obtain counts of deaccession items --->
<cffunction name="getDeaccItemCounts" access="remote">
	<cfargument name="transaction_id" type="string" required="yes">
	
	<cfif listcontainsnocase(session.roles,"admin_transactions")>
		<cfquery name="rankCount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select
				1 as status,
				count(distinct cataloged_item.collection_object_id) catItemCount,
				count(distinct collection.collection_cde) as collectionCount,
				count(distinct preserve_method) as preserveCount,
				count(distinct specimen_part.collection_object_id) as partCount
			from
				deacc_item,
				deaccession,
				specimen_part,
				coll_object,
				cataloged_item,
				identification,
				collection
			WHERE
				deacc_item.collection_object_id = specimen_part.collection_object_id AND
				deaccession.transaction_id = deacc_item.transaction_id AND
				specimen_part.derived_from_cat_item = cataloged_item.collection_object_id AND
				specimen_part.collection_object_id = coll_object.collection_object_id AND
				cataloged_item.collection_object_id = identification.collection_object_id AND
				identification.accepted_id_fg = 1 AND
				cataloged_item.collection_id=collection.collection_id AND
				deacc_item.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
		</cfquery>
	<cfelse>
		<cfset rankCount=queryNew("status, message")>
		<cfset t = queryaddrow(rankCount,1)>
		<cfset t = QuerySetCell(rankCount, "status", "-1", 1)>
		<cfset t = QuerySetCell(rankCount, "message", "Not Authorized", 1)>
	</cfif>
	<cfreturn rankCount>
</cffunction>

<!--- obtain an html block containing dispositions of items in a deaccession --->
<cffunction name="getDeaccItemDispositions" returntype="string" access="remote" returnformat="plain">
	<cfargument name="transaction_id" type="string" required="yes">

	<cfthread name="getDeaccItemDispThread">
		<cftry>
			<cfoutput>
				<cftry>
				<cfquery name="transType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select transaction_type
					from trans
					where
						transaction_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
				</cfquery>
				<cfset transaction = transType.transaction_type>
				<h2 class="h3">Disposition of material in this #transaction#:</h2>
				<cfquery name="getDispositions" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select collection_cde, 
						count(distinct cataloged_item.collection_object_id) as cocount, 
						count(distinct specimen_part.collection_object_id) as pcount, 
						coll_obj_disposition, deacc_number, deacc_type, deacc_status
					from deaccession
						left join deacc_item on deaccession.transaction_id = deacc_item.transaction_id
						left join specimen_part on deacc_item.collection_object_id = specimen_part.collection_object_id
						left join coll_object on deacc_item.collection_object_id = coll_object.collection_object_id
						left join cataloged_item on specimen_part.derived_from_cat_item = cataloged_item.collection_object_id
					where deaccession.transaction_id = <cfqueryparam CFSQLType="CF_SQL_DECIMAL" value="#transaction_id#">
						and coll_obj_disposition is not null
					group by collection_cde, coll_obj_disposition, deacc_number, deacc_type, deacc_status
				</cfquery>
				<cfif getDispositions.RecordCount EQ 0 >
					<p>There are no attached collection objects.</p>
				<cfelse>
					<table class="table table-responsive">
						<thead class="thead-light">
							<tr>
								<th>Collection</th>
								<th>Cataloged Items</th>
								<th>Parts</th>
								<th>Disposition</th>
								<th>Deaccession</th>
							</tr>
						</thead>
						<tbody>
							<cfloop query="getDispositions">
								<tr>
									<cfif len(trim(getDispositions.deacc_number)) GT 0>
										<td>#collection_cde#</td>
										<td>#cocount#</td>
										<td>#pcount#</td>
										<td>#coll_obj_disposition#</td>
										<td><a href="/Transactions.cfm?action=findDeaccessions&execute=true&deacc_number=#deacc_number#">#deacc_number# (#deacc_status#)</a></td>
									<cfelse>
										<!--- we should never end up in this block, as all items in this deaccession should be in this deaccession... --->
										<td>#collection_cde#</td>
										<td>#cocount#</td>
										<td>#pcount#</td>
										<td>#coll_obj_disposition#</td>
										<td>Error: Not in a Deaccession</td>
									</cfif>
								</tr>
							</cfloop>
						</tbody>
					</table>
				</cfif>
				<cfcatch>
					<cfdump var="#cfcatch#">
				</cfcatch>
				</cftry>
			</cfoutput>
		<cfcatch>
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfoutput>
				<h2 class="h3">Error in #function_called#:</h2>
				<div>#error_message#</div>
			</cfoutput>
		</cfcatch>
		</cftry>
	</cfthread>
	<cfthread action="join" name="getDeaccItemDispThread" />
	<cfreturn getDeaccItemDispThread.output>
</cffunction>

<!--- obtain an html block containing restrictions imposed by permissions and rights documents on material in a deaccession 
  and benefits required for such material.
 @param transaction_id the primary key value for the deaccession transaction for which to return benefits and restrictions.
--->
<cffunction name="getDeaccLimitations" returntype="string" access="remote" returnformat="plain">
	<cfargument name="transaction_id" type="string" required="yes">

	<cfthread name="getDeaccLimitThread">
		<cftry>
			<cfoutput>
				<cfquery name="deaccLimitations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select count(distinct deacc_item.collection_object_id) as ct,
						permit.permit_id, permit.specific_type, permit.restriction_summary, permit.benefits_summary, permit.benefits_provided, 
						accn.transaction_id as accn_id, accn.accn_number
					from  
						deaccession 
						left join deacc_item on deaccession.transaction_id = deacc_item.transaction_id
						left join specimen_part on deacc_item.collection_object_id = specimen_part.collection_object_id
						left join cataloged_item on specimen_part.derived_from_cat_item = cataloged_item.collection_object_id
						left join accn on cataloged_item.accn_id = accn.transaction_id
						left join permit_trans on accn.transaction_id = permit_trans.transaction_id
						left join permit on permit_trans.permit_id = permit.permit_id
					where 
						deaccession.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
						and (permit.restriction_summary IS NOT NULL 
								or
							 permit.benefits_summary IS NOT NULL)
					group by
						permit.permit_id, permit.specific_type, permit.restriction_summary, permit.benefits_summary, permit.benefits_provided, 
						accn.transaction_id, accn.accn_number
				</cfquery>
				<cfif deaccLimitations.recordcount GT 0>
					<table class='table table-responsive d-md-table mb-0'>
						<thead class='thead-light'><th>Items</th><th>Accession</th><th>Document</th><th>Restrictions Summary</th><th>Agreed Benefits</th><th>Benefits Provided</th></thead>
						<tbody>
							<cfloop query="deaccLimitations">
								<tr>
									<td>#ct#</td>
									<td><a href='/transactions/Accession.cfm?Action=edit&transaction_id=#accn_id#'>#accn_number#</a></td>
									<td><a href='/transactions/Permit.cfm?Action=edit&permit_id=#permit_id#'>#specific_type#</a></td>
									<td>#restriction_summary#</td>
									<td>#benefits_summary#</td>
									<td>#benefits_provided#</td>
								</tr>
							</cfloop>
						</tbody>
					</table>
				<cfelse>
					None recorded.
				</cfif>
			</cfoutput>
		<cfcatch>
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfoutput>
				<h2 class="h3">Error in #function_called#:</h2>
				<div>#error_message#</div>
			</cfoutput>
		</cfcatch>
		</cftry>
	</cfthread>
	<cfthread action="join" name="getDeaccLimitThread" />
	<cfreturn getDeaccLimitThread.output>
</cffunction>

<!--- obtain an html block containing a list of loans on which any material in a deaccession had been sent --->
<cffunction name="getDeaccLoans" returntype="string" access="remote" returnformat="plain">
	<cfargument name="transaction_id" type="string" required="yes">

	<cfthread name="getDeaccLoanThread">
		<cftry>
			<cfoutput>
				<cfquery name="deaccLoans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select count(specimen_part.collection_object_id) as ct, 
						loan.transaction_id loan_id, loan_number, loan_status, 
						return_due_date, loan.closed_date, 
						loan.return_due_date - trunc(sysdate) dueindays
					from 
						deacc_item 
						left join specimen_part on deacc_item.collection_object_id = specimen_part.collection_object_id
						left join loan_item on specimen_part.collection_object_id = loan_item.collection_object_id
						left join loan on loan_item.transaction_id = loan.transaction_id
					where 
						loan.transaction_id is not null and
						deacc_item.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
					group by
						loan.transaction_id, loan_number, loan_status, 
						return_due_date, loan.closed_date, 
						loan.return_due_date
				</cfquery>
				<cfif deaccLoans.recordcount GT 0>
					<table class='table table-responsive d-md-table mb-0'>
						<thead class='thead-light'><th>Items</th><th>Loan</th><th>Status</th><th>Due Date</th><th>Closed Date</th></thead>
						<tbody>
							<cfloop query="deaccLoans">
								<tr>
									<td>#ct#</td>
									<cfif len(deaccLoans.closed_date) EQ 0 AND deaccLoans.dueindays LT 0>
										<cfset returndate = "<strong class='text-danger'>#dateformat(deaccLoans.return_due_date,'yyyy-mm-dd')#</strong>">
									<cfelse>
										<cfset returndate = "#dateformat(deaccLoans.return_due_date,'yyyy-mm-dd')#" >
									</cfif>
									<td><a href='/transactions/Loan.cfm?action=edit&transaction_id=#deaccLoans.loan_id#'>#deaccLoans.loan_number#</a></td>
									<td>#deaccLoans.loan_status#</td>
									<td>#returndate#</td>
									<td>#dateformat(deaccLoans.closed_date,'yyyy-mm-dd')#</td>
								</tr>
							</cfloop>
						</tbody>
					</table>
				<cfelse>
					None.
				</cfif>
			</cfoutput>
		<cfcatch>
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfoutput>
				<h2 class="h3">Error in #function_called#:</h2>
				<div>#error_message#</div>
			</cfoutput>
		</cfcatch>
		</cftry>
	</cfthread>
	<cfthread action="join" name="getDeaccLoanThread" />
	<cfreturn getDeaccLoanThread.output>
</cffunction>

<!------------------------------------------------------->
<cffunction name="saveDeaccession" access="remote" returntype="any" returnformat="json">
	<cfargument name="transaction_id" type="string" required="yes">
	<cfargument name="nature_of_material" type="string" required="yes">
	<cfargument name="trans_date" type="string" required="yes">
	<cfargument name="collection_id" type="string" required="yes">
	<cfargument name="trans_remarks" type="string" required="no">
	<cfargument name="deacc_type" type="string" required="yes">
	<cfargument name="deacc_number" type="string" required="yes">
	<cfargument name="deacc_status" type="string" required="yes">
	<cfargument name="deacc_reason" type="string" required="yes">
	<cfargument name="value" type="string" required="no">
	<cfargument name="methodoftransfer" type="string" required="no">

	<cfset data = ArrayNew(1)>
	<cftransaction>
		<cftry>
			<cfquery name="updateDeaccessionCheck" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="newDeaccessionCheck_result">
				SELECT count(*) as ct from trans
				WHERE  
					TRANSACTION_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value='#transaction_id#'>
					and transaction_type = 'deaccession'
			</cfquery>
			<cfif updateDeaccessionCheck.ct NEQ 1>
				<cfthrow message = "Unable to update transaction. Provided transaction_id does not match a record in the trans table with a type of accn.">
			</cfif>
			<cfquery name="updateDeaccessionTrans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="updateDeaccessionTrans_result">
				UPDATE trans SET
					collection_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_id#">,
					TRANS_DATE = <cfqueryparam cfsqltype="CF_SQL_TIMESTAMP" value="#dateformat(trans_date,'yyyy-mm-dd')#">,
					nature_of_material = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#nature_of_material#">
					<cfif isDefined("trans_remarks")>
						, trans_remarks = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trans_remarks#">
					</cfif>
				where
					transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
			</cfquery>
			<cfquery name="updateDeaccession" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="updateDeaccession_result">
				 UPDATE DEACCESSION SET
					DEACC_TYPE = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#deacc_type#">,
					DEACC_NUMBER = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#deacc_number#">,
					DEACC_STATUS = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#deacc_status#">,
					DEACC_REASON = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#deacc_reason#">
					<cfif isDefined("value")>
						, VALUE = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#value#">
					</cfif>
					<cfif isDefined("methodoftransfer")>
						, METHOD = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#methodoftransfer#">
					</cfif>
				where TRANSACTION_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#TRANSACTION_ID#">
			</cfquery>
			<cfloop from="1" to="#numAgents#" index="n">
				<cfif IsDefined("trans_agent_id_" & n) >
					<cfset trans_agent_id_ = evaluate("trans_agent_id_" & n)>
					<cfset agent_id_ = evaluate("agent_id_" & n)>
					<cfset trans_agent_role_ = evaluate("trans_agent_role_" & n)>
					<cftry>
						<cfset del_agnt_=evaluate("del_agnt_" & n)>
					<cfcatch>
						<cfset del_agnt_=0>
					</cfcatch>
					</cftry>
					<cfif del_agnt_ is "1" and isnumeric(trans_agent_id_) and trans_agent_id_ gt 0>
						<cfquery name="del" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							delete from trans_agent 
							where trans_agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#trans_agent_id_#">
						</cfquery>
					<cfelse>
						<cfif len(agent_id_) GT 0>
							<!--- don't try to add/update a blank row --->
							<cfif trans_agent_id_ is "new" and del_agnt_ is 0>
								<cfquery name="newTransAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
									insert into trans_agent (
										transaction_id,
										agent_id,
										trans_agent_role
									) values (
										<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">,
										<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id_#">,
										<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trans_agent_role_#">
									)
								</cfquery>
							<cfelseif del_agnt_ is 0>
								<cfquery name="upTransAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
									update trans_agent set
										agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id_#">,
										trans_agent_role = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trans_agent_role_#">
									where
										trans_agent_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#trans_agent_id_#">
								</cfquery>
							</cfif>
						</cfif>
					</cfif>
				</cfif>
			</cfloop>

			<cfset row = StructNew()>
			<cfset row["status"] = "saved">
			<cfset row["id"] = "#transaction_id#">
			<cfset data[1] = row>
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
	<cfreturn #serializeJSON(data)#>
</cffunction>

<!--- obtain counts of items cataloged within an accession --->
<cffunction name="getAccnItemCounts" access="remote">
	<cfargument name="transaction_id" type="string" required="yes">

	<cftry>
		<cfif listcontainsnocase(session.roles,"admin_transactions")>
			<cfquery name="rankCount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT
					1 as status,
					count(distinct cataloged_item.collection_object_id) catItemCount,
					count(distinct collection.collection_cde) as collectionCount,
					count(distinct preserve_method) as preserveCount,
					count(distinct specimen_part.collection_object_id) as partCount
				FROM
					cataloged_item 
					left join specimen_part on specimen_part.derived_from_cat_item = cataloged_item.collection_object_id
					left join collection on cataloged_item.collection_id=collection.collection_id 
				WHERE
					cataloged_item.accn_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
			</cfquery>
		<cfelse>
			<cfset rankCount=queryNew("status, message")>
			<cfset t = queryaddrow(rankCount,1)>
			<cfset t = QuerySetCell(rankCount, "status", "-1", 1)>
			<cfset t = QuerySetCell(rankCount, "message", "Not Authorized", 1)>
		</cfif>
	<cfcatch>
		<cfset error_message = cfcatchToErrorMessage(cfcatch)>
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn rankCount>
</cffunction>

<!--- obtain an html block containing dispositions of items in an accession --->
<cffunction name="getAccnItemDispositions" returntype="string" access="remote" returnformat="plain">
	<cfargument name="transaction_id" type="string" required="yes">

	<cfthread name="getAccnItemDispThread">
		<cftry>
			<cfoutput>
				<cfquery name="transType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select transaction_type
					from trans
					where
						transaction_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
				</cfquery>
				<cfset transaction = transType.transaction_type>
				<cfif transaction EQ 'accn'><cfset transaction='accession'></cfif>
				<h2 class="h3">Disposition of material in this #transaction#:</h2>
				<!--- TODO: Generalize to other transaction types --->
				<cfquery name="getDispositions" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select collection_cde, count(distinct specimen_part.collection_object_id) as pcount, coll_obj_disposition, 
							count(distinct cataloged_item.collection_object_id) as cocount,
							deacc_number, deacc_type, deacc_status
					from accn
						left join cataloged_item on accn.transaction_id = cataloged_item.accn_id
						left join specimen_part on specimen_part.derived_from_cat_item = cataloged_item.collection_object_id
						left join coll_object on specimen_part.collection_object_id = coll_object.collection_object_id
						left join deacc_item on specimen_part.collection_object_id = deacc_item.collection_object_id
						left join deaccession on deacc_item.transaction_id = deaccession.transaction_id
					where accn.transaction_id = <cfqueryparam CFSQLType="CF_SQL_DECIMAL" value="#transaction_id#">
						and coll_obj_disposition is not null
					group by collection_cde, coll_obj_disposition, deacc_number, deacc_type, deacc_status
				</cfquery>
				<cfif getDispositions.RecordCount EQ 0 >
					<h4>There are no attached collection objects.</h4>
				<cfelse>
					<table class="table table-responsive">
						<thead class="thead-light">
							<tr>
								<th>Collection</th>
								<th>Cataloged Items</th>
								<th>Parts</th>
								<th>Disposition</th>
								<th>Deaccession</th>
							</tr>
						</thead>
						<tbody>
							<cfloop query="getDispositions">
								<tr>
									<cfif len(trim(getDispositions.deacc_number)) GT 0>
										<td>#collection_cde#</td>
										<td>#cocount#</td>
										<td>#pcount#</td>
										<td>#coll_obj_disposition#</td>
										<td><a href="/Transactions.cfm?action=findDeaccessions&execute=true&deacc_number=#encodeForURL(deacc_number)#">#deacc_number# (#deacc_status#)</a></td>
									<cfelse>
										<td>#collection_cde#</td>
										<td>#cocount#</td>
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
			<cfoutput>
				<h2 class="h3">Error in #function_called#:</h2>
				<div>#error_message#</div>
			</cfoutput>
		</cfcatch>
		</cftry>
	</cfthread>
	<cfthread action="join" name="getAccnItemDispThread" />
	<cfreturn getAccnItemDispThread.output>
</cffunction>

<!---- function addCollObjectsDeaccession
  Given a transaction_id for a deaccession and a string delimited list of guids, 
  and a remark to apply to all items look up the collection object id 
  values for the guids and add the parts for this cataloged item as deaccesion items  
	@param transaction_id the pk of the deaccession to add the collection objects to.
	@param guid_list a comma delimited list of guids in the form MCZ:Col:catnum
	@param deacc_items_remarks a remark to apply to each deaccession item
	@return a json structure containing added=nummber of updated relations.
--->
<cffunction name="addCollObjectsDeaccession" access="remote" returntype="any" returnformat="json">
	<cfargument name="transaction_id" type="string" required="yes">
	<cfargument name="guid_list" type="string" required="yes">
	<cfargument name="deacc_items_remarks" type="string" required="no">
	<cfset guids = "">
	<cfif Find(',', guid_list) GT 0>
		<cfset guidArray = guid_list.Split(',')>
		<cfset separator ="">
		<cfloop array="#guidArray#" index=#idx#>
			<!--- skip any empty elements --->
			<cfif len(trim(idx)) GT 0>
				<!--- trim to prevent guid, guid from failing --->
				<cfset guids = guids & separator & trim(idx)>
				<cfset separator = ",">
			</cfif>
		</cfloop>
	<cfelse>
		<cfset guids = trim(guid_list)>
	</cfif>

	<cfset data = ArrayNew(1)>
	<cftry>
		<cfset rows = 0>
		<cftransaction>
			<cfquery name="updateDeaccessionCheck" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="updateDeaccessionCheck_result">
				SELECT count(*) as ct from trans
				WHERE  
					TRANSACTION_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value='#transaction_id#'>
					and transaction_type = 'deaccession'
			</cfquery>
			<cfif updateDeaccessionCheck.ct NEQ 1>
				<cfthrow message = "Unable to update transaction. Provided transaction_id does not match a record in the trans table with a type of deaccession.">
			</cfif>
			<cfquery name="find" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="find_result">
				select distinct
					specimen_part.collection_object_id as part_colobjid,
					fl.guid,
					mczbase.get_part_prep(specimen_part.collection_object_id) as part,
					coll_object.coll_obj_disposition,
					deacc_item.transaction_id as in_trans_id
				from
					<cfif #session.flatTableName# EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> fl
					left join specimen_part on fl.collection_object_id = specimen_part.derived_from_cat_item
					left join coll_object on specimen_part.collection_object_id = coll_object.collection_object_id
					left join deacc_item on specimen_part.collection_object_id = deacc_item.collection_object_id
				where 
					guid in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#guids#" list="yes" >)
					and specimen_part.collection_object_id is not null
			</cfquery>
			<cfif find_result.recordcount GT 0>
				<cfquery name="reconAgentID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select agent_id from agent_name 
					where agent_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cfloop query=find>
					<cfif coll_obj_disposition EQ 'on loan'>
						<cfthrow message="Unable to add items.  #guid# #part# has a disposition of 'on loan' and cannot be deaccessioned until this disposition is changed.">
					</cfif>
					<cfif len(in_trans_id) GT 0 >
						<cfthrow message="Unable to add items.  #guid# #part# is already in a deaccession and cannot be added to this deaccession.">
					</cfif>
					<cfquery name="add" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="add_result">
						insert into deacc_item
						(
							transaction_id,
							collection_object_id,
							reconciled_by_person_id,
							reconciled_date,
							item_descr
							<cfif isDefined("deacc_items_remarks")>
								,deacc_item_remarks
							</cfif>		
						) values (
							<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">,
							<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#part_colobjid#">,
							<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#reconAgentId.agent_id#">,
							sysdate,
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#guid# #part#">
							<cfif isDefined("deacc_items_remarks")>
								,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#deacc_items_remarks#">
							</cfif>		
						)
					</cfquery>
					<cfset rows = rows + add_result.recordcount>
				</cfloop>
			</cfif>
		</cftransaction>

		<cfset i = 1>
		<cfset row = StructNew()>
		<cfset row["status"] = "success">
		<cfset row["added"] = "#rows#">
		<cfset row["matches"] = "#find_result.recordcount#">
		<cfset row["findquery"] = "#rereplace(find_result.sql,'[\n\r\t]+',' ','ALL')#">
		<cfset data[i] = row>
		<cfreturn #serializeJSON(data)#>
	<cfcatch>
		<cfset error_message = cfcatchToErrorMessage(cfcatch)>
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>

</cffunction>
<!--- obtain an html block containing restrictions imposed by permissions and rights documents on material in an accession --->
<cffunction name="getAccnLimitations" returntype="string" access="remote" returnformat="plain">
	<cfargument name="transaction_id" type="string" required="yes">

	<cfthread name="getAccnLimitThread">
		<cftry>
			<cfoutput>
				<cfquery name="accnLimitations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select permit.permit_id, permit.specific_type, permit.restriction_summary, permit.benefits_summary, permit.benefits_provided
					from  permit_trans 
						left join permit on permit_trans.permit_id = permit.permit_id
					where 
						permit_trans.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
						and (permit.restriction_summary IS NOT NULL 
								or
							 permit.benefits_summary IS NOT NULL)
				</cfquery>
				<cfif accnLimitations.recordcount GT 0>
					<table class='table table-responsive d-md-table mb-0'>
						<thead class='thead-light'><th>Document</th><th>Restrictions Summary</th><th>Agreed Benefits</th><th>Benefits Provided</th></thead>
						<tbody>
							<cfloop query="accnLimitations">
								<tr>
									<td><a href='/transactions/Permit.cfm?Action=edit&permit_id=#permit_id#'>#specific_type#</a></td>
									<td>#restriction_summary#</td>
									<td>#benefits_summary#</td>
									<td>#benefits_provided#</td>
								</tr>
							</cfloop>
						</tbody>
					</table>
				<cfelse>
					None recorded.
				</cfif>
			</cfoutput>
		<cfcatch>
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfoutput>
				<h2 class="h3">Error in #function_called#:</h2>
				<div>#error_message#</div>
			</cfoutput>
		</cfcatch>
		</cftry>
	</cfthread>
	<cfthread action="join" name="getAccnLimitThread" />
	<cfreturn getAccnLimitThread.output>
</cffunction>

<!--- obtain an html block containing a list of loans on which any material in an accession has been sent --->
<cffunction name="getAccnLoans" returntype="string" access="remote" returnformat="plain">
	<cfargument name="transaction_id" type="string" required="yes">

	<cfthread name="getAccnLoanThread">
		<cftry>
			<cfoutput>
				<cfquery name="accnLoans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select distinct 
						loan.transaction_id loan_id, loan_number, loan_status, 
						return_due_date, loan.closed_date, 
						loan.return_due_date - trunc(sysdate) dueindays
					from cataloged_item
						left join specimen_part on cataloged_item.collection_object_id = specimen_part.derived_from_cat_item
						left join loan_item on specimen_part.collection_object_id = loan_item.collection_object_id
						left join loan on loan_item.transaction_id = loan.transaction_id
					where 
						loan.transaction_id is not null and
						cataloged_item.accn_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
				</cfquery>
				<cfif accnLoans.recordcount GT 0>
					<table class='table table-responsive d-md-table mb-0'>
						<thead class='thead-light'><th>Loan</th><th>Status</th><th>Due Date</th><th>Closed Date</th></thead>
						<tbody>
							<cfloop query="accnLoans">
								<tr>
									<cfif len(accnLoans.closed_date) EQ 0 AND accnLoans.dueindays LT 0>
										<cfset returndate = "<strong class='text-danger'>#dateformat(accnLoans.return_due_date,'yyyy-mm-dd')#</strong>">
									<cfelse>
										<cfset returndate = "#dateformat(accnLoans.return_due_date,'yyyy-mm-dd')#" >
									</cfif>
									<td><a href='/transactions/Loan.cfm?action=edit&transaction_id=#accnLoans.loan_id#'>#accnLoans.loan_number#</a></td>
									<td>#accnLoans.loan_status#</td>
									<td>#returndate#</td>
									<td>#dateformat(accnLoans.closed_date,'yyyy-mm-dd')#</td>
								</tr>
							</cfloop>
						</tbody>
					</table>
				<cfelse>
					None.
				</cfif>
			</cfoutput>
		<cfcatch>
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfoutput>
				<h2 class="h3">Error in #function_called#:</h2>
				<div>#error_message#</div>
			</cfoutput>
		</cfcatch>
		</cftry>
	</cfthread>
	<cfthread action="join" name="getAccnLoanThread" />
	<cfreturn getAccnLoanThread.output>
</cffunction>

<!--- obtain an html block containing countries of origin of items in a transaction --->
<cffunction name="getTransItemCountries" returntype="string" access="remote" returnformat="plain">
	<cfargument name="transaction_id" type="string" required="yes">

	<cfthread name="getTransItemCountryThread">
		<cftry>
			<cfoutput>
				<cfquery name="transType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select transaction_type
					from trans
					where
						transaction_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
				</cfquery>
				<cfset transaction = transType.transaction_type>
				<cfif transaction EQ 'accn'><cfset transaction='accession'></cfif>
				<h2 class="h3">Countries of Origin of cataloged items in this #transaction#</h2>
				<!--- TODO: Generalize to other transaction types --->
				<cfquery name="ctSovereignNation" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select count(*) as ct, sovereign_nation 
					from cataloged_item 
						left join specimen_part on cataloged_item.collection_object_id = specimen_part.collection_object_id
						left join cataloged_item on specimen_part.derived_from_cat_item = cataloged_item.collection_object_id
						left join collecting_event on cataloged_item.collecting_event_id = collecting_event.collecting_event_id
						left join locality on collecting_event.locality_id = locality.locality_id
					where
						cataloged_item.accn_id =  <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#" >
					group by sovereign_nation
				</cfquery>
				<cfset sep="">
				<cfif ctSovereignNation.recordcount EQ 0>
					<span class="var-display">None</span>
				<cfelse>
					<cfloop query=ctSovereignNation>
						<cfif len(sovereign_nation) eq 0>
							<cfset sovereign_nation = '[no value set]'>
						</cfif>
						<span class="var-display">#sep##sovereign_nation#&nbsp;(#ct#)</span>
						<cfset sep="; ">
					</cfloop>
				</cfif>
			</cfoutput>
		<cfcatch>
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfoutput>
				<h2 class="h3">Error in #function_called#:</h2>
				<div>#error_message#</div>
			</cfoutput>
		</cfcatch>
		</cftry>
	</cfthread>
	<cfthread action="join" name="getTransItemCountryThread" />
	<cfreturn getTransItemCountryThread.output>
</cffunction>

<!--- obtain counts of loan items --->
<cffunction name="getLoanItemCounts" access="remote">
	<cfargument name="transaction_id" type="string" required="yes">
	<cftry>
		<cfif listcontainsnocase(session.roles,"admin_transactions")>
			<cfquery name="rankCount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT
					1 as status,
					count(distinct cataloged_item.collection_object_id) catItemCount,
					count(distinct collection.collection_cde) as collectionCount,
					count(distinct preserve_method) as preserveCount,
					count(distinct specimen_part.collection_object_id) as partCount
				FROM
					loan_item,
					loan,
					specimen_part,
					coll_object,
					cataloged_item,
					coll_object_encumbrance,
					encumbrance,
					agent_name,
					identification,
					collection
				WHERE
					loan_item.collection_object_id = specimen_part.collection_object_id AND
					loan.transaction_id = loan_item.transaction_id AND
					specimen_part.derived_from_cat_item = cataloged_item.collection_object_id AND
					specimen_part.collection_object_id = coll_object.collection_object_id AND
					coll_object.collection_object_id = coll_object_encumbrance.collection_object_id (+) and
					coll_object_encumbrance.encumbrance_id = encumbrance.encumbrance_id (+) AND
					encumbrance.encumbering_agent_id = agent_name.agent_id (+) AND
					cataloged_item.collection_object_id = identification.collection_object_id AND
					identification.accepted_id_fg = 1 AND
					cataloged_item.collection_id=collection.collection_id AND
					loan_item.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
			</cfquery>
		<cfelse>
			<cfset rankCount=queryNew("status, message")>
			<cfset t = queryaddrow(rankCount,1)>
			<cfset t = QuerySetCell(rankCount, "status", "-1", 1)>
			<cfset t = QuerySetCell(rankCount, "message", "Not Authorized", 1)>
		</cfif>
	<cfcatch>
		<cfset error_message = cfcatchToErrorMessage(cfcatch)>
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn rankCount>
</cffunction>

<!--- ** removeSubloanFromParent removes a record from loan_relations of type Subloan.
  * @param parent_transaction_id the master exhibition loan from which to remove the subloan.
  * @param child_transaction_id the subloan to remove from the master exhibition loan.
--->
<cffunction name="removeSubloanFromParent" returntype="query" access="remote">
	<cfargument name="parent_transaction_id" type="string" required="yes">
	<cfargument name="child_transaction_id" type="string" required="yes">
	
	<cfset theResult=queryNew("status, message")>
	<cftry>
		<cfquery name="delete" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="deleteResult">
			delete from LOAN_RELATIONS 
			where transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#parent_transaction_id#">
			and related_transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#child_transaction_id#">
			and relation_type = 'Subloan'
		</cfquery>
		<cfif deleteResult.recordcount eq 0>
			<cfset t = queryaddrow(theResult,1)>
			<cfset t = QuerySetCell(theResult, "status", "0", 1)>
			<cfset t = QuerySetCell(theResult, "message", "No records deleted. #parent_transaction_id# #child_transaction_id# #deleteResult.sql#", 1)>
		</cfif>
		<cfif deleteResult.recordcount eq 1>
			<cfset t = queryaddrow(theResult,1)>
			<cfset t = QuerySetCell(theResult, "status", "1", 1)>
			<cfset t = QuerySetCell(theResult, "message", "Record deleted.", 1)>
		</cfif>
	<cfcatch>
		<cfset error_message = cfcatchToErrorMessage(cfcatch)>
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn theResult>
</cffunction>

<!---
  ** getSubloansForLoanHtml obtain an html block listing the subloans for an exhibition master loan
  * along with a pick list of available not-yet related to a parent subloans available to add.
  *
  * @param transaction_id the transaction_id of the parent exhibition loan.
--->
<cffunction name="getSubloansForLoanHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="transaction_id" type="string" required="yes">
	<cfthread name="getSubloanHtmlThread">
		<cfoutput>
			<cftry>

				<cfquery name="parentLoan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select loan_number from loan 
					where 
						transaction_id = <cfqueryparam value=#transaction_id# CFSQLType="CF_SQL_DECIMAL" >
				</cfquery>
				<cfset parent_loan_number = parentLoan.loan_number>
				<!--- Subloans of the current loan (used for exhibition-master/exhibition-subloans) --->
				<cfquery name="childLoans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select c.loan_number, c.transaction_id as child_transaction_id
					from loan p left join loan_relations lr on p.transaction_id = lr.transaction_id 
						left join loan c on lr.related_transaction_id = c.transaction_id 
					where lr.relation_type = 'Subloan'
						 and p.transaction_id = <cfqueryparam value=#transaction_id# CFSQLType="CF_SQL_DECIMAL" >
					order by c.loan_number
				</cfquery>
				<!---  Loans which are available to be used as subloans for an exhibition master loan (exhibition-subloans that are not allready children) --->
				<cfquery name="potentialChildLoans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select pc.loan_number, pc.transaction_id as potential_transaction_id
					from loan pc left join loan_relations lr on pc.transaction_id = lr.related_transaction_id
					where pc.loan_type = 'exhibition-subloan' 
						and (lr.transaction_id is null or lr.relation_type <> 'Subloan')
					order by pc.loan_number
				</cfquery>
	
				<div class="col-12">
					<h5 class="d-inline" id="subloan_list" tabindex="0">
						<cfif childLoans.RecordCount GT 0>
							<a href="/Transactions.cfm?action=findLoans&execute=true&parent_loan_number=#EncodeForURL(parent_loan_number)#" target="_blank">Exhibition-Subloans</a> (#childLoans.RecordCount#):
						<cfelse>
							<h3>No exhibition subloans are currently linked to this exhibtion master loan</h3>
						</cfif>
						<cfif childLoans.RecordCount GT 0>
							<cfset childLoanCounter = 0>
							<cfset childseparator = "">
							<cfloop query="childLoans">
								#childseparator#
	 							<a href="/transactions/Loan.cfm?action=editLoan&transaction_id=#childLoans.child_transaction_id#">#childLoans.loan_number#</a>
								<button type="button" class="btn btn-xs btn-warning py-0" id="button_remove_subloan_#childLoanCounter#" onclick=" removeSubloanFromParent(#transaction_id#,#childLoans.child_transaction_id#); ">-</button>
								<cfset childLoanCounter = childLoanCounter + 1 >
								<cfset childseparator = ";&nbsp;">
							</cfloop>
						</cfif>
					</h5>
				</div>
				<div class="col-12">
					<cfif potentialChildLoans.recordcount EQ 0>
						<p class="mt-1">No subloans available to add</p>
					<cfelse>
						<label for="possible_subloans">Subloans that can be added to this exhibition-master loan:</label>
						<div class="input-group">
							<select name="possible_subloans" id="possible_subloans" class="input-group-text">
								<cfloop query="potentialChildLoans">
									<option value="#potentialChildLoans.potential_transaction_id#">#potentialChildLoans.loan_number#</option>
								</cfloop>
							</select>
							<div class="input-group-append">
								<button type="button" class="btn btn-xs btn-secondary" id="button_add_subloans" onclick=" addSubloanToParent(#transaction_id#,$('##possible_subloans').val()); ">Add</button>
							</div>
						</div>
					</cfif>
				</div>
			<cfcatch>
				<cfset error_message = cfcatchToErrorMessage(cfcatch)>
				<cfset function_called = "#GetFunctionCalledName()#">
				<span>Error in #function_called#: #error_message#</span>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="getSubloanHtmlThread" />
	<cfreturn getSubloanHtmlThread.output>
</cffunction>

<!-------------------------------------------->
<!--- obtain an html block listing the media for a transaction  --->
<cffunction name="getMediaForTransHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="transaction_id" type="string" required="yes">
	<cfargument name="transaction_type" type="string" required="yes">
	<cfset relword="documents">
	<cfthread name="getMediaForTransHtmlThread">
		<cftry>
			<cfquery name="query" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select distinct
					media.media_id as media_id,
					preview_uri,
					media.media_uri,
					media.mime_type,
					media.media_type as media_type,
					MCZBASE.is_media_encumbered(media.media_id) as hideMedia,
					nvl(MCZBASE.get_medialabel(media.media_id,'description'),'[No Description]') as label_value
				from
					media_relations left join media on media_relations.media_id = media.media_id
				where
					media_relationship like <cfqueryparam value="% #transaction_type#" cfsqltype="CF_SQL_VARCHAR">
					and media_relations.related_primary_key = <cfqueryparam value="#transaction_id#" CFSQLType="CF_SQL_DECIMAL">
			</cfquery>
			<cfoutput>
				<cfif query.recordcount gt 0>
					<ul class='pl-4 pr-0 list-style-disc mt-2'>
					<cfloop query="query">
						<cfset puri=getMediaPreview(preview_uri,media_type) >
						<li class='mb-2'>
							<a href='#media_uri#' target='_blank' rel='noopener noreferrer'><img src='#puri#' height='15'></a> #mime_type# #media_type# #label_value# <a href='/media/#media_id#' target='_blank'>Media Details</a>  <a class='btn btn-xs btn-warning' onClick='  confirmDialog("Remove this media from this transaction?", "Confirm Unlink Media", function() { removeMediaFromTrans(#media_id#,#transaction_id#,"#relWord# #transaction_type#"); } ); '>Remove Media</a>
						</li>
					</cfloop>
					</ul>
				<cfelse>
					<p>None</p>
				</cfif>
			</cfoutput>
		<cfcatch>
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfoutput>
				<h2 class="h3">Error in #function_called#:</h2>
				<div>#error_message#</div>
			</cfoutput>
		</cfcatch>
		</cftry>
	</cfthread>
	<cfthread action="join" name="getMediaForTransHtmlThread" />
	<cfreturn getMediaForTransHtmlThread.output>
</cffunction>

<!---  Obtain the list of shipments and their permits for a transaction formatted in html for display on a transaction page --->
<!---  @param transaction_id  the transaction for which to obtain a list of shipments and their permits.  --->
<!---  @return html list of shipments and permits, including editing controls for adding/editing/removing shipments and permits. --->
<cffunction name="getShipmentsByTransHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="transaction_id" type="string" required="yes">
	<cfset r=1>
	<cfthread name="getSBTHtmlThread">
		<cfoutput>
			<cftry>
				 <cfquery name="theResult" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select 1 as status, shipment_id, packed_by_agent_id, shipped_carrier_method, shipped_date, package_weight, no_of_packages,
								hazmat_fg, insured_for_insured_value, shipment_remarks, contents, foreign_shipment_fg, shipped_to_addr_id, carriers_tracking_number,
								shipped_from_addr_id, fromaddr.formatted_addr, toaddr.formatted_addr,
								toaddr.country_cde tocountry, toaddr.institution toinst, toaddr.formatted_addr tofaddr,
								fromaddr.country_cde fromcountry, fromaddr.institution frominst, fromaddr.formatted_addr fromfaddr,
								shipment.print_flag
						 from shipment
								left join addr fromaddr on shipment.shipped_from_addr_id = fromaddr.addr_id
								left join addr toaddr on shipment.shipped_to_addr_id = toaddr.addr_id
						 where shipment.transaction_id =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
						 order by shipped_date
				</cfquery>
				<div id='shipments'>
				<cfloop query="theResult">
					<cfif print_flag eq "1">
						<cfset printedOnInvoice = "&##9745; Printed on invoice">
					<cfelse>
						<cfset printedOnInvoice = "<span class='infoLink' onClick=' setShipmentToPrint(#shipment_id#,#transaction_id#); ' >&##9744; Not Printed</span>">
					</cfif>
					<cfquery name="shippermit" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="shippermit_result">
							select permit.permit_id,
								issuedBy.agent_name as IssuedByAgent,
								issued_Date,
								renewed_Date,
								exp_Date,
								permit_Num,
								permit_Type
							from
								permit_shipment left join permit on permit_shipment.permit_id = permit.permit_id
								left join preferred_agent_name issuedBy on permit.issued_by_agent_id = issuedBy.agent_id
							where
								permit_shipment.shipment_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#theResult.shipment_id#">
					</cfquery>
					<script>
						function reloadShipments() { 
							console.log("reloadShipments()"); 
							loadShipments(#transaction_id#); 
							loadTransactionPermitMediaList(#transaction_id#) 
						} 
					</script>
						
					<div class='shipments bg-white border my-2'>
						<table class='table table-responsive d-md-table mb-0'>
							<thead class='thead-light'><th>Ship Date:</th><th>Method:</th><th>Packages:</th><th>Tracking Number:</th></thead>
							<tbody>
								<tr>
									<td>#dateformat(shipped_date,'yyyy-mm-dd')#&nbsp;</td>
									<td>#shipped_carrier_method#&nbsp;</td>
									<td>#no_of_packages#&nbsp;</td>
									<td>#carriers_tracking_number#</td>
								</tr>
								<cfif len(shipment_remarks) GT 0>
									<tr>
										<td colspan="4"><span class="font-weight-lessbold">Shipment Remarks:</span> #shipment_remarks#</td>
									</tr>
								</cfif>
								<cfif len(contents) GT 0>
									<tr>
										<td colspan="4"><span class="font-weight-lessbold">Contents:</span> #contents#</td>
									</tr>
								</cfif>
							</tbody>
						</table>
						<table class='table table-responsive d-md-table'>
							<thead class='thead-light'><tr><th>Shipped To:</th><th>Shipped From:</th></tr></thead>
							<tbody>
								<tr>
									<td>(#printedOnInvoice#) #tofaddr#</td>
									<td>#fromfaddr#</td>
								</tr>
							</tbody>
						</table>
						<div class='form-row'>
							<div class='col-12 col-md-3 col-xl-2 mb-2'>
								<input type='button' value='Edit this Shipment' class='btn btn-xs btn-secondary' onClick="$('##dialog-shipment').dialog('open'); loadShipment(#shipment_id#,'shipmentForm');">
							</div>
							<div id='addPermit_#shipment_id#' class='col-12 mt-2 mt-md-0 col-md-9 col-xl-10'>
								<input type='button' value='Add Permit to this Shipment' class='btn btn-xs btn-secondary' onClick=" openlinkpermitshipdialog('addPermitDlg_#shipment_id#','#shipment_id#','Shipment #carriers_tracking_number#',reloadShipments); " >
							</div>
							<div id='addPermitDlg_#shipment_id#'></div>
						</div>
						<div class='shippermitstyle' tabindex="0">
							<h4 class='font-weight-bold mb-0'>Permits:</h4>
							<div class='permitship pb-2'>
								<ul id='permits_ship_#shipment_id#' tabindex="0" class="list-style-disc pl-4 pr-0">
									<cfloop query="shippermit">
										<cfquery name="mediaQuery" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
											select media.media_id, media_uri, preview_uri, media_type,
												mczbase.get_media_descriptor(media.media_id) as media_descriptor
											from media_relations left join media on media_relations.media_id = media.media_id
											where media_relations.media_relationship = 'shows permit' 
												and media_relations.related_primary_key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value=#shippermit.permit_id#>
										</cfquery>
										<cfset mediaLink = "&##8855;"><!--- show (x) character if there are no permit media --->
										<cfloop query="mediaQuery">
											<cfset puri=getMediaPreview(preview_uri,media_type) >
											<cfif puri EQ "/images/noThumb.jpg">
												<!--- linked media, but no preview image --->
												<cfset altText = "Red X in a red square, with text, no preview image available">
											<cfelse>
												<!--- linked media with preview image --->
												<cfset altText = mediaQuery.media_descriptor>
											</cfif>
											<cfset mediaLink = "<a href='#media_uri#' target='_blank' rel='noopener noreferrer' ><img src='#puri#' height='20' alt='#altText#'></a>" >
										</cfloop>
											<li class="my-1">#mediaLink# #permit_type# #permit_Num# | Issued: #dateformat(issued_Date,'yyyy-mm-dd')# | By: #IssuedByAgent#
														<button type='button' class='btn btn-xs btn-secondary' onClick=' window.open("/transactions/Permit.cfm?Action=edit&permit_id=#permit_id#")' target='_blank' value='Edit'>Edit</button>
													<button type='button' 
														class='btn btn-xs btn-warning ml-1' 
														onClick='confirmDialog("Remove this permit from this shipment (#permit_type# #permit_Num#)?", "Confirm Remove Permit", function() { deletePermitFromShipment(#theResult.shipment_id#,#permit_id#,#transaction_id#); reloadShipments(#transaction_id#); } ); '
														value='Remove Permit'>Remove Permit</button>
													<cfif theResult.recordcount GT 1>
													<!--- add the option to copy/move the permit if there is more than one shipment --->
														<button type='button' 
															onClick=' openMovePermitDialog(#transaction_id#,#theResult.shipment_id#,#permit_id#,"movePermitDlg_#theResult.shipment_id##permit_id#");' 
															class='btn btn-xs btn-warning' value='Move'>Move</button>
														<span id='movePermitDlg_#theResult.shipment_id##permit_id#'></span>
													</cfif>
											</li>
									</cfloop>
									</ul>
									<cfif shippermit.recordcount eq 0>
										<p class="mt-2">None</p>
									</cfif>
								</span>
							</div>
						</div> <!--- span#permit_ships_, div.permitship div.shippermitsstyle --->
						<cfif shippermit.recordcount eq 0>
							 <div class='deletestyle mb-0' id='removeShipment_#shipment_id#'>
								<input type='button' value='Delete this Shipment' class='delBtn btn btn-xs btn-danger' onClick=" confirmDialog('Delete this shipment (#theResult.shipped_carrier_method# #theResult.carriers_tracking_number#)?', 'Confirm Delete Shipment', function() { deleteShipment(#shipment_id#,#transaction_id#); }  ); " >
							</div>
						<cfelse>
							<div class='deletestyle pb-1'>
								<input type='button' class='disBtn btn btn-xs btn-secondary' value='Delete this Shipment'>
							</div>
						</cfif>
					</div> <!--- shipment div --->
				</cfloop> <!--- theResult --->
							
				<cfif theResult.recordcount eq 0>
					<p class="mt-2">No shipments found for this transaction.</p>
				</cfif>
					</div><!--- shipments div --->
			<cfcatch>
				<cfset error_message = cfcatchToErrorMessage(cfcatch)>
				<cfset function_called = "#GetFunctionCalledName()#">
				<p class="mt-2 text-danger">Error in #function_called#: #error_message#</p>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="getSBTHtmlThread" />
	<cfreturn getSBTHtmlThread.output>
</cffunction>


<!--- 
 ** method movePermitHtml populates a dialog to move a permit from one shipment to another shipment in the same transaction 
 * Or to copy (add another link for) a permit from one shipment to another shipment in the same transaction
 ---> 
<cffunction name="movePermitHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="permit_id" type="string" required="yes">
	<cfargument name="current_shipment_id" type="string" required="yes">
	<cfargument name="transaction_id" type="string" required="yes">

	<cfset feedbackId = "queryMovePermit#permit_id##current_shipment_id#">
 
	<cfthread name="getMovePermitHtmlThread">
		<cftry>
			<cfquery name="queryPermit" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select distinct permit_num, permit_type, issued_date, permit.permit_id,
					issuedBy.agent_name as IssuedByAgent
				from permit left join preferred_agent_name issuedBy on permit.issued_by_agent_id = issuedBy.agent_id
				where permit_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value=#permit_id#>
			</cfquery>
			<cfoutput>
				<cfloop query="queryPermit">
					<h3>Move/Copy Permit #permit_type# #permit_num# Issued By: #IssuedByAgent#</h3><p><strong><span id='#feedbackId#'></span></strong></p>
				</cfloop>
				<cfquery name="queryShip" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select 1 as status, shipment_id,
						packed_by_agent_id, mczbase.get_agentnameoftype(packed_by_agent_id,'preferred') packed_by_agent, carriers_tracking_number,
						shipped_carrier_method, to_char(shipped_date, 'yyyy-mm-dd') as shipped_date, package_weight, no_of_packages,
						hazmat_fg, insured_for_insured_value, shipment_remarks, contents, foreign_shipment_fg, shipped_to_addr_id,
						shipped_from_addr_id, fromaddr.formatted_addr as shipped_from_address, toaddr.formatted_addr as shipped_to_address
					from shipment
						left join addr fromaddr on shipment.shipped_from_addr_id = fromaddr.addr_id
						left join addr toaddr on shipment.shipped_to_addr_id = toaddr.addr_id
					where transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#"> and
						shipment_id <> <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#current_shipment_id#">
				</cfquery>
				<cfif queryShip.recordcount gt 0>
					<ul class="list-style-disc pl-4 pr-0">
						<cfloop query="queryShip">
							<li class="my-1">
								<script>
									function moveClickCallback(status) { 
										if (status == 1) { 
											$('##' + '#feedbackId#').html('Moved.  Click the Close Dialog button.'); 
										} else { 
											$('##' + '#feedbackId#').html('Error.'); 
										}
									}; 
									function moveClickHandler() { 
										 movePermitFromShipmentCB(#current_shipment_id#,#shipment_id#,#permit_id#,#transaction_id#, moveClickCallback); 
									};
									function addClickCallback(status) { 
										if (status == 1) { 
											$('##' + '#feedbackId#').html('Added.  Click the Close Dialog button.'); 
										} else { 
											$('##' + '#feedbackId#').html('Error.'); 
										}
									}; 
									function addClickHandler() { 
										addPermitToShipmentCB(#shipment_id#,#permit_id#,#transaction_id#, moveClickCallback); 
									}; 
								</script>
								<input type='button' style='margin-left: 30px;' value='Move To' class='btn btn-xs btn-warning' 
									onClick=" moveClickHandler(); ">
								<input type='button' style='margin-left: 30px;' value='Copy To' class='btn btn-xs btn-secondary'
									 onClick=" addClickHandler(); ">
								#shipped_carrier_method# #shipped_date# #carriers_tracking_number#
						</li>
						</cfloop>
					</ul>
				<cfelse>
					<h3>There are no other shipments in this transaction, you must create a new shipment to move this permit to.</h3>
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
	<cfthread action="join" name="getMovePermitHtmlThread" />
	<cfreturn getMovePermitHtmlThread.output>

</cffunction>


<!---
  ** method getShipments returns a details of shipments matching a provided list of shipmentIDs,
  * this method is used to populate the shipment dialog for transactions to edit a shipment, where
  * it is provided with a single shipment_id in shipmentIdList 
  * 
  * @param a comma separated list of one or more shipment_id values for which to look up the shipment details.
  * @return a serialization of a query object
--->
<cffunction name="getShipments" returntype="query" access="remote">
	<cfargument name="shipmentidList" type="string" required="yes">
	<cftry>
		<cfquery name="theResult" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select 1 as status, shipment_id, transaction_id,
				packed_by_agent_id, 
				mczbase.get_agentnameoftype(packed_by_agent_id,'preferred') packed_by_agent, 
				carriers_tracking_number,
				shipped_carrier_method, to_char(shipped_date, 'yyyy-mm-dd') as shipped_date, 
				package_weight, no_of_packages,
				hazmat_fg, insured_for_insured_value, shipment_remarks, contents, foreign_shipment_fg, shipped_to_addr_id,
				shipped_from_addr_id, 
				fromaddr.formatted_addr as shipped_from_address, 
				toaddr.formatted_addr as shipped_to_address,
				shipment.print_flag
			from shipment
				left join addr fromaddr on shipment.shipped_from_addr_id = fromaddr.addr_id
				left join addr toaddr on shipment.shipped_to_addr_id = toaddr.addr_id
			where 
				shipment_id in (<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#shipmentIdList#" list="yes">)
		</cfquery>
		<cfif theResult.recordcount eq 0>
			<cfset theResult=queryNew("status, message")>
			<cfset t = queryaddrow(theResult,1)>
			<cfset t = QuerySetCell(theResult, "status", "0", 1)>
			<cfset t = QuerySetCell(theResult, "message", "No shipments found.", 1)>
		</cfif>
	<cfcatch>
		<cfset error_message = cfcatchToErrorMessage(cfcatch)>
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn theResult>
</cffunction>

<!---  Given a shipment_id, set only that shipment out of the set of shipments in that transaction to print. --->
<cffunction name="setShipmentToPrint" access="remote">
	<cfargument name="shipment_id" type="numeric" required="yes">
	<cftry>
		<cftransaction action="begin">
		<!--- First set the print flag off for all shipments on this transaction. --->
		<cfquery name="clearResult" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="clearResultRes">
			update shipment set print_flag = 0 where transaction_id in (
				select transaction_id from shipment where shipment_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#shipment_id#">
			)
		</cfquery>
		<!--- Then set the print flag on for the provided shipments. --->
		<cfif clearResultRes.recordcount GT 0 >
			<cfquery name="updateResult" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="updateResultRes">
				 update shipment set print_flag = 1 where shipment_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#shipment_id#">
			</cfquery>

			<cfif updateResultRes.recordcount eq 0>
				<cftransaction action="rollback"/>
				<cfset theResult=queryNew("status, message")>
				<cfset t = queryaddrow(theResult,1)>
				<cfset t = QuerySetCell(theResult, "status", "0", 1)>
				<cfset t = QuerySetCell(theResult, "message", "Shipment not updated. #shipment_id# #updateResultRes.sql#", 1)>
			</cfif>
			<cfif updateResultRes.recordcount eq 1>
				<cftransaction action="commit"/>
				<cfset theResult=queryNew("status, message")>
				<cfset t = queryaddrow(theResult,1)>
				<cfset t = QuerySetCell(theResult, "status", "1", 1)>
				<cfset t = QuerySetCell(theResult, "message", "Shipment updated to print.", 1)>
			</cfif>
		<cfelse>
				<cftransaction action="rollback"/>
				<cfset theResult=queryNew("status, message")>
				<cfset t = queryaddrow(theResult,1)>
				<cfset t = QuerySetCell(theResult, "status", "0", 1)>
				<cfset t = QuerySetCell(theResult, "message", "Shipment not found. #shipment_id# #clearResultRes.sql#", 1)>
		</cfif>
		</cftransaction>
	<cfcatch>
		<cfset error_message = cfcatchToErrorMessage(cfcatch)>
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn theResult>
</cffunction>


<!--- 
 ** method removePermitFromShipment deletes a relationship between a permit and a shipment.
 *  @param permit_id the permissions and rights document the shipment is linked to.
 *  @param shipment_id the id of the shipment to from which to unlink the permit_id.
--->
<cffunction name="removePermitFromShipment" returntype="query" access="remote">
	<cfargument name="permit_id" type="string" required="yes">
	<cfargument name="shipment_id" type="string" required="yes">
	
	<cfset theResult=queryNew("status, message")>
	<cftry>
		<cfquery name="delete" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="deleteResultRes">
			delete from permit_shipment
			where permit_id =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#permit_id#">
			and shipment_id =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#shipment_id#">
		</cfquery>
		<cfif deleteResultRes.recordcount eq 0>
			<cfset t = queryaddrow(theResult,1)>
			<cfset t = QuerySetCell(theResult, "status", "0", 1)>
			<cfset t = QuerySetCell(theResult, "message", "No records deleted. #permit_id# #shipment_id# #deleteResult.sql#", 1)>
		</cfif>
		<cfif deleteResultRes.recordcount eq 1>
			<cfset t = queryaddrow(theResult,1)>
			<cfset t = QuerySetCell(theResult, "status", "1", 1)>
			<cfset t = QuerySetCell(theResult, "message", "Record deleted.", 1)>
		</cfif>
	<cfcatch>
		<cfset error_message = cfcatchToErrorMessage(cfcatch)>
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn theResult>
</cffunction>

<!--- 
 ** method removeShipment deletes a shipment record.
 *  @param transaction_id the id of the transaction thie shipment is part of.
 *  @param shipment_id the id of the shipment to delete.
--->
<cffunction name="removeShipment" returntype="query" access="remote">
	<cfargument name="shipment_id" type="string" required="yes">
	<cfargument name="transaction_id" type="string" required="yes">
	<cfset r=1>
	<cftransaction>
		<cftry>
			<cfquery name="countPermits" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="countPermits_result">
				select count(*) as ct 
				from permit_shipment
			 	where shipment_id =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#shipment_id#">
			</cfquery>
			<cfif countPermits.ct EQ 0 >
				<cfquery name="delete" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="delete_result">
					delete from shipment
					where transaction_id =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
					and shipment_id =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#shipment_id#">
				</cfquery>
				<cfif delete_result.recordcount eq 0>
					<cfset theResult=queryNew("status, message")>
					<cfset t = queryaddrow(theResult,1)>
					<cfset t = QuerySetCell(theResult, "status", "0", 1)>
					<cfset t = QuerySetCell(theResult, "message", "No records deleted. #shipment_id# #delete_result.sql#", 1)>
				</cfif>
				<cfif delete_result.recordcount eq 1>
					<cfset theResult=queryNew("status, message")>
					<cfset t = queryaddrow(theResult,1)>
					<cfset t = QuerySetCell(theResult, "status", "1", 1)>
					<cfset t = QuerySetCell(theResult, "message", "Record deleted.", 1)>
				</cfif>
			<cfelse>
				<cfset theResult=queryNew("status, message")>
				<cfset t = queryaddrow(theResult,1)>
				<cfset t = QuerySetCell(theResult, "status", "0", 1)>
				<cfset t = QuerySetCell(theResult, "message", "Can't delete shipment with attached permits.", 1)>
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

<!--- Given a transaction_id and a permit_id, remove the relationship between the permit and the transaction.
--->
<cffunction name="removePermitFromTransaction" returntype="query" access="remote">
	<cfargument name="permit_id" type="string" required="yes">
	<cfargument name="transaction_id" type="string" required="yes">

	<cfset r=1>
	<cftry>
		<cfquery name="deleteResult" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="deleteResultRes">
			delete from permit_trans
			where permit_id =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#permit_id#">
				and transaction_id =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
		</cfquery>
		<cfif deleteResultRes.recordcount eq 0>
			<cfset theResult=queryNew("status, message")>
			<cfset t = queryaddrow(theResult,1)>
			<cfset t = QuerySetCell(theResult, "status", "0", 1)>
			<cfset t = QuerySetCell(theResult, "message", "No records deleted. #permit_id# #transaction_id# #deleteResult.sql#", 1)>
		</cfif>
		<cfif deleteResultRes.recordcount eq 1>
			<cfset theResult=queryNew("status, message")>
			<cfset t = queryaddrow(theResult,1)>
			<cfset t = QuerySetCell(theResult, "status", "1", 1)>
			<cfset t = QuerySetCell(theResult, "message", "Record deleted.", 1)>
		</cfif>
	<cfcatch>
		<cfset error_message = cfcatchToErrorMessage(cfcatch)>
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>

	<cfreturn theResult>
</cffunction>

<!---  Given a transaction_id, return a block of html code for a permit picking dialog to pick permissions and rights
	documents for the given transaction.
	@param transaction_id the transaction to which selected permissions and rights documents are to be related.
	@return html content for a permit picker dialog for transaction permits or an error message if an exception was raised.

	@see linkPermitToTrans 
	@see findPermitSearchResults
--->
<cffunction name="transPermitPickerHtml" returntype="string" access="remote">
	<cfargument name="transaction_id" type="string" required="yes">
	<cfargument name="transaction_label" type="string" required="yes">
	
	<cfthread name="transPermitThread">
		<cfoutput>
			<cftry>
				<cfquery name="ctPermitType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select ct.permit_type, count(p.permit_id) uses 
					from ctpermit_type ct left join permit p on ct.permit_type = p.permit_type 
					group by ct.permit_type
					order by ct.permit_type
				</cfquery>
				<cfquery name="ctSpecificPermitType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select ct.specific_type, count(p.permit_id) uses 
					from ctspecific_permit_type ct left join permit p on ct.specific_type = p.specific_type
					group by ct.specific_type
					order by ct.specific_type
				</cfquery>

				<h3>Search for Permissions &amp; Rights documents. <span class="smaller d-block mt-1">Any part of dates and names accepted, case isn't important.</span></h3>
				<form id='findPermitForm' onsubmit='searchforpermits(event);'>
					<input type='hidden' name='method' value='findPermitSearchResults'>
					<input type='hidden' name='returnformat' value='plain'>
					<input type='hidden' name='transaction_id' value='#transaction_id#'>
					<input type='hidden' name='transaction_label' value='#transaction_label#'>
					<div class="form-row">
						<div class="col-12 col-md-3 mt-1">
							<label for="pf_issuedByAgent" class="data-entry-label">Issued By</label>
							<input type="text" name="IssuedByAgent" id="pf_issuedByAgent" class="data-entry-input">
						</div>
						<div class="col-12 col-md-3 mt-1">
							<label for="pf_issuedToAgent" class="data-entry-label">Issued To</label>
							<input type="text" name="IssuedToAgent" id="pf_issuedToAgent" class="data-entry-input">
						</div>
						<div class="col-6 col-md-3 mt-1">
							<label for="pf_issued_date" class="data-entry-label">Issued Date</label>
							<input type="text" name="issued_Date" id="pf_issued_date" class="data-entry-input">
						</div>
						<div class="col-6 col-md-3 mt-1">
							<label for="pf_renewed_date" class="data-entry-label">Renewed Date</label>
							<input type="text" name="renewed_Date" id="pf_renewed_date" class="data-entry-input">
						</div>
					</div>
					<div class="form-row">
						<div class="col-12 col-md-3 mt-1">
							<label class="data-entry-label" for="pf_exp_date">Expiration Date</label>
							<input type="text" name="exp_Date" class="data-entry-input" id="pf_exp_date">
						</div>
						<div class="col-12 col-md-3 mt-1">
							<label class="data-entry-label" for="permit_Num">Permit Number</label>
							<input type="text" name="permit_num" id="search_permit_num" class="data-entry-input">
							<input type="hidden" name="permit_id" id="search_permit_id" class="data-entry-input">
						</div>
						<script>
							$(document).ready(function() {
								$(makePermitPicker('search_permit_num','search_permit_id'));
								$('##search_permit_num').blur( function () {
									// prevent an invisible permit_id from being included in the search.
									if ($('##search_permit_num').val().trim() == "") { 
										$('##search_permit_id').val("");
									}
								});
							});
						</script>
						<div class="col-12 col-md-3 mt-1">
							<label class="data-entry-label" for="pf_permit_type">Permit Type</label>
							<select name="permit_Type" size="1" class="data-entry-select" id="pf_permit_type">
								<option value=""></option>
								<cfloop query="ctPermitType">
									<option value = "#ctPermitType.permit_type#">#ctPermitType.permit_type# (#ctPermitType.uses#)</option>
								</cfloop>
							</select>
						</div>
						<div class="col-12 col-md-3 mt-1">
							<label class="data-entry-label" for="pf_permit_remarks">Remarks</label>
							<input type="text" name="permit_remarks" id="pf_permit_remarks" class="data-entry-input">
						</div>
					</div>
					<div class="form-row">
						<div class="col-12 col-md-6 mt-1">
							<label class="data-entry-label" for="pf_specific_type">Specific Type</label>
							<select name="specific_type" size="1" id="pf_specific_type" class="data-entry-select">
								<option value=""></option>
								<cfloop query="ctSpecificPermitType">
									<option value="#ctSpecificPermitType.specific_type#" >#ctSpecificPermitType.specific_type# (#ctSpecificPermitType.uses#)</option>
								</cfloop>
							</select>
						</div>
						<div class="col-12 col-md-6 mt-1">
							<label class="data-entry-label" for="pf_permit_title">Permit Title</label>
							<input type="text" name="permit_title" id="pf_permit_title" class="data-entry-input">
						</div>
					</div>
					<div class="form-row mb-2">
						<div class="col-6 col-md-6 mt-1">
							<input type="button" value="Search" class="btn btn-xs btn-primary mr-2" onclick="$('##findPermitForm').submit()">	
							<script>
								function createPermitDialogDone () { 
									$("##permit_Num").val($("##permit_number_passon").val()); 
								};
							</script>
							<input type="reset" value="Clear" class="btn btn-xs btn-warning mr-4">
						</div>
						<div class="col-6 col-md-6 mt-1">
							<span id='createPermit_#transaction_id#_span'>
								<input type='button' value='New Permit' class='btn btn-xs btn-secondary mt-2' onClick='opencreatepermitdialog("createPermitDlg_#transaction_id#","#transaction_label#", #transaction_id#, "transaction", createPermitDialogDone);' >
							</span>
							<div id='createPermitDlg_#transaction_id#'></div>
						</div>
					</div>
				</form>
				<script language='javascript' type='text/javascript'>
					function searchforpermits(event) { 
						event.preventDefault();
						// to debug ajax call on component getting entire page redirected to blank page uncomment to create submission
						// alert($('##findPermitForm').serialize());
						jQuery.ajax({
							url: '/transactions/component/functions.cfc',
							type: 'post',
							data: $('##findPermitForm').serialize(),
							success: function (data) {
								$('##permitSearchResults').html(data);
							},
							error: function (jqXHR, textStatus, error) {
								handleFail(jqXHR,textStatus,error,"searching for permissions and rights documents.");
							}
						});
						return false; 
					};
				</script>
				<div id='permitSearchResults'></div>
			<cfcatch>
				<cfset error_message = cfcatchToErrorMessage(cfcatch)>
				<cfset function_called = "#GetFunctionCalledName()#">
				Error in #function_called# #error_message#
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="transPermitThread" />
	<cfreturn transPermitThread.output>
</cffunction>

<!----------------------------------------------------------------------------------------------------------------->
<!--- Given a transaction_id and a list of permissions and rights documents search criteria return an html list 
	of permissions and rights documents records matching the search criteria, along with controls allowing selected 
	permissions and rights documents to be linked to the specified transaction.

	@see transPermitPickerHtml
	@see linkPermitToTrans 
--->
<cffunction name="findPermitSearchResults" access="remote" returntype="string">
	<cfargument name="transaction_id" type="string" required="yes">
	<cfargument name="transaction_label" type="string" required="yes">
	<cfargument name="IssuedByAgent" type="string" required="no">
	<cfargument name="IssuedToAgent" type="string" required="no">
	<cfargument name="issued_Date" type="string" required="no">
	<cfargument name="renewed_Date" type="string" required="no">
	<cfargument name="exp_Date" type="string" required="no">
	<cfargument name="permit_num" type="string" required="no">
	<cfargument name="permit_id" type="string" required="no">
	<cfargument name="specific_type" type="string" required="no">
	<cfargument name="permit_Type" type="string" required="no">
	<cfargument name="permit_title" type="string" required="no">
	<cfargument name="permit_remarks" type="string" required="no">

	<cfthread name="findPermitSearchThread">
		<cfoutput>
			<cftry>
				<cfif NOT isdefined('IssuedByAgent')><cfset IssuedByAgent=''></cfif>
				<cfif NOT isdefined('IssuedToAgent')><cfset IssuedToAgent=''></cfif>
				<cfif NOT isdefined('issued_Date')><cfset issued_Date=''></cfif>
				<cfif NOT isdefined('renewed_Date')><cfset renewed_Date=''></cfif>
				<cfif NOT isdefined('exp_Date')><cfset exp_Date=''></cfif>
				<cfif NOT isdefined('permit_num')><cfset permit_Num=''></cfif>
				<cfif NOT isdefined('permit_id')><cfset permit_id=''></cfif>
				<cfif NOT isdefined('specific_type')><cfset specific_type=''></cfif>
				<cfif NOT isdefined('permit_Type')><cfset permit_Type=''></cfif>
				<cfif NOT isdefined('permit_title')><cfset permit_title=''></cfif>
				<cfif NOT isdefined('permit_remarks')><cfset permit_remarks=''></cfif>

				<cfif len(IssuedByAgent) EQ 0 AND len(IssuedToAgent) EQ 0 AND len(issued_Date) EQ 0 AND 
					len(renewed_Date) EQ 0 AND len(exp_Date) EQ 0 AND len(permit_Num) EQ 0 AND 
					len(specific_type) EQ 0 AND len(permit_Type) EQ 0 AND len(permit_title) EQ 0 AND 
					len(permit_remarks) EQ 0 >
					<cfthrow type="noQueryParameters" message="No search criteria provided." >
				</cfif>

				<cfquery name="matchPermit" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" timeout="#Application.query_timeout#">
					select distinct permit.permit_id,
						issuedByPref.agent_name IssuedByAgent,
						issuedToPref.agent_name IssuedToAgent,
						issued_Date,
						renewed_Date,
						exp_Date,
						permit_Num,
						permit_Type,
						permit_title,
						specific_type,
						permit_remarks,
						(select count(*) from permit_trans 
							where permit_trans.permit_id = permit.permit_id
								and permit_trans.transaction_id = <cfqueryparam cfsqltype='CF_SQL_DECIMAL' value='#transaction_id#'>
						) as linkcount
					from 
						permit 
						left join preferred_agent_name issuedToPref on permit.issued_to_agent_id = issuedToPref.agent_id 
						left join preferred_agent_name issuedByPref on permit.issued_by_agent_id = issuedByPref.agent_id 
						left join agent_name issuedTo on permit.issued_to_agent_id = issuedTo.agent_id
						left join agent_name issuedBy on permit.issued_by_agent_id = issuedBy.agent_id 
						left join permit_trans on permit.permit_id = permit_trans.permit_id 
					where 
						permit.permit_id is not null
						<cfif len(#IssuedByAgent#) gt 0>
							 AND upper(issuedBy.agent_name) like <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='%#ucase(IssuedByAgent)#%'>
						</cfif>
						<cfif len(#IssuedToAgent#) gt 0>
							 AND upper(issuedTo.agent_name) like <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='%#ucase(IssuedToAgent)#%'>
						</cfif>
						<cfif len(#issued_Date#) gt 0>
							 AND upper(issued_Date) like <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='%#ucase(issued_Date)#%'>
						</cfif>
						<cfif len(#renewed_Date#) gt 0>
							 AND upper(renewed_Date) like <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='%#ucase(renewed_Date)#%'>
						</cfif>
						<cfif len(#exp_Date#) gt 0>
							 AND upper(exp_Date) like <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='%#ucase(exp_Date)#%'>
						</cfif>
						<cfif len(#permit_id#) GT 0>
							AND permit.permit_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#permit_id#"> 
						</cfif>
						<cfif len(#permit_num#) GT 0 and len(#permit_id#) EQ 0 >
							<cfif left(permit_num,1) IS "=">
								AND permit_num = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(permit_num,len(permit_num)-1)#"> 
							<cfelseif permit_num IS "NULL">
								AND permit_num IS NULL
							<cfelseif permit_num IS "NOT NULL">
								AND permit_num IS NOT NULL
							<cfelse>
								AND permit_Num like <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='%#permit_Num#%'>
							</cfif>
						</cfif>
						<cfif len(#specific_type#) gt 0>
							 AND specific_type = <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#specific_type#'>
						</cfif>
						<cfif len(#permit_Type#) gt 0>
							 AND permit_Type = <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#permit_Type#'>
						</cfif>
						<cfif len(#permit_title#) gt 0>
							 AND upper(permit_title) like <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='%#ucase(permit_title)#%'>
						</cfif>
						<cfif len(#permit_remarks#) gt 0>
							 AND upper(permit_remarks) like <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='%#ucase(permit_remarks)#%'>
						</cfif>
					ORDER BY permit_id
				</cfquery>
				<cfset i=1>

				<h2>Find permits to link to #transaction_label#</h2>
				<cfloop query="matchPermit" >
					<hr>
					<cfif (i MOD 2) EQ 0> 
						<cfset divclass = "class='evenRow'"> 
					<cfelse> 
						<cfset divclass = "class='oddRow'"> 
					</cfif>
					<div #divclass# >
						<form id='pp_#permit_id#_#transaction_id#_#i#' >
							Document Number #matchPermit.permit_Num# (#matchPermit.permit_Type#:#matchPermit.specific_type#) 
							issued to #matchPermit.IssuedToAgent# by #matchPermit.IssuedByAgent# on #dateformat(matchPermit.issued_Date,'yyyy-mm-dd')# 
							<cfif len(#matchPermit.renewed_Date#) gt 0>
								 (renewed #dateformat(matchPermit.renewed_Date,'yyyy-mm-dd')#)
							</cfif>
							. Expires #dateformat(matchPermit.exp_Date,'yyyy-mm-dd')#.
							<cfif len(#matchPermit.permit_remarks#) gt 0>
								Remarks: #matchPermit.permit_remarks# 
							</cfif> 
							(ID## #matchPermit.permit_id#) #matchPermit.permit_title#
							<div id='pickResponse#transaction_id#_#i#'>
								<cfif matchPermit.linkcount GT 0>
									This Permissions and Rights Document is already linked to #transaction_label# 
								<cfelse>
								<input type='button' class='picBtn'
									onclick='linkpermit(#matchPermit.permit_id#,#transaction_id#,"#transaction_label#","pickResponse#transaction_id#_#i#");' 
									value='Add this permit'>
								</cfif>
							</div>
 						</form>
						<script language='javascript' type='text/javascript'>
							$('##pp_#permit_id#_#transaction_id#_#i#').removeClass('ui-widget-content');
							function linkpermit(permit_id, transaction_id, transaction_label, div_id) { 
								jQuery.ajax({
									url: '/transactions/component/functions.cfc',
									type: 'post',
									data: {
										method: 'linkPermitToTrans',
										returnformat: 'plain',
										permit_id: permit_id,
										transaction_id: transaction_id,
										transaction_label: transaction_label
									},
									success: function (data) {
										$('##'+div_id).html(data);
									},
									error: function (jqXHR, textStatus, error) {
										handleFail(jqXHR,textStatus,error,"linking permissions and rights document to transaction.");
									}
								});
							};
						</script>
					</div>
					<cfset i=i+1>
				</cfloop>
			<cfcatch>
				<cfset error_message = cfcatchToErrorMessage(cfcatch)>
				<cfset function_called = "#GetFunctionCalledName()#">
				<cfset result = "Error in #function_called#: #error_message#">
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="findPermitSearchThread" />
	<cfreturn findPermitSearchThread.output>
</cffunction>

<!----------------------------------------------------------------------------------------------------------------->
<!---  Given a transaction_id and a permit_id, create a permit_trans record to link the permissions and rights 
	document record to the transaction.

	@param transaction_id the transaction to link
	@param permit_id the permit to link
	@param transaction_label a human readable descriptor of the transaction identified by transaction_id
	@return html message indicating success, or an error message on failure.

	@see transPermitPickerHtml
	@see findPermitSearchResults
--->
<cffunction name="linkPermitToTrans" access="remote" returntype="string">
	<cfargument name="transaction_id" type="string" required="yes">
	<cfargument name="transaction_label" type="string" required="yes">
	<cfargument name="permit_id" type="string" required="yes">

	<cfset result = "">
		<cftry>
			<cfquery name="addPermit" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				INSERT INTO permit_trans (permit_id, transaction_id) VALUES (#permit_id#, #transaction_id#)
			</cfquery>
		
			<cfset result = "Added this permit (#permit_id#) to transaction #transaction_label#. ">

		<cfcatch>
			<cfif cfcatch.detail CONTAINS "ORA-00001: unique constraint (MCZBASE.PKEY_PERMIT_TRANS">
				<cfset result = "Error: This permit is already linked to #transaction_label#">
			<cfelse>
				<cfset error_message = cfcatchToErrorMessage(cfcatch)>
				<cfset function_called = "#GetFunctionCalledName()#">
				<cfset result = "Error in #function_called#: #error_message#">
			</cfif>
		</cfcatch>
		</cftry>
	<cfreturn result>
</cffunction>


<!----------------------------------------------------------------------------------------------------------------->

<cffunction name="getPermitsForTransHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="transaction_id" type="string" required="yes">

	<cfthread name="getPermitsHtmlThread">
		<cfquery name="query" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select distinct permit_num, permit_type, issued_date, permit.permit_id,
				issuedBy.agent_name as IssuedByAgent
			from permit left join permit_trans on permit.permit_id = permit_trans.permit_id
				left join preferred_agent_name issuedBy on permit.issued_by_agent_id = issuedBy.agent_id
			where permit_trans.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value=#transaction_id#>
			order by permit_type, issued_date
		</cfquery>

		<cfoutput>
			<div class='permittrans'>
				<span id='permits_tr_#transaction_id#' class="pb-2">
					<cfloop query="query">
						<cfquery name="mediaQuery" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" timeout="#Application.query_timeout#">
							select media.media_id, media_uri, preview_uri, media_type, mczbase.get_media_descriptor(media.media_id) as media_descriptor
							from media_relations left join media on media_relations.media_id = media.media_id
							where media_relations.media_relationship = 'shows permit'
								and media_relations.related_primary_key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value=#permit_id#>
						</cfquery>
						<cfset mediaLink = "&##8855;">
						<cfloop query="mediaQuery">
							<cfset puri=getMediaPreview(preview_uri,media_type) >
							<cfif puri EQ "/images/noThumb.jpg">
								<cfset altText = "Red X in a red square, with text, no preview image available">
							<cfelse>
								<cfset altText = mediaQuery.media_descriptor>
							</cfif>
							<cfset mediaLink = "<a href='#media_uri#'target='_blank' rel='noopener noreferrer'><img src='#puri#' height='15' alt='#altText#'></a>" >
						</cfloop>
						<ul class='list-style-disc pl-4 pr-0'>
							<li class="my-1">
								#mediaLink# #permit_type# #permit_Num#
								| Issued: #dateformat(issued_Date,'yyyy-mm-dd')# | By: #IssuedByAgent#
								<input type='button' 
									class='btn btn-xs btn-secondary mr-1' 
									onClick=' window.open("/transactions/Permit.cfm?action=edit&permit_id=#permit_id#")' 
									target='_blank' value='Edit'>
								<input type='button' class='btn btn-xs btn-warning mr-1' 
									onClick='confirmDialog("Remove this permit from this Transaction (#permit_type# #permit_Num#)?", "Confirm Remove Permit", function() { deletePermitFromTransaction(#permit_id#,#transaction_id#); } ); ' 
									value='Remove Permit'>
							</li>
						</ul>
					</cfloop>
					<cfif query.recordcount eq 0>
				 		None
					</cfif>
				</span>
			</div> <!--- span#permit_tr_, div.permittrans --->
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="getPermitsHtmlThread" />
	<cfreturn getPermitsHtmlThread.output>
</cffunction>

<!----------------------------------------------------------------------------------------------------------------->
<cffunction name="getPermitsForShipment" returntype="string" access="remote" returnformat="plain">
	<cfargument name="shipment_id" type="string" required="yes">
	<cfset result="">
	<cfquery name="query" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" timeout="#Application.query_timeout#">
		select distinct permit_num, permit_type, issued_date, permit.permit_id,
			issuedBy.agent_name as IssuedByAgent
		from permit_shipment left join permit on permit_shipment.permit_id = permit.permit_id
			left join preferred_agent_name issuedBy on permit.issued_by_agent_id = issuedBy.agent_id
		where permit_shipment.shipment_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value=#shipment_id#>
		order by permit_type, issued_date
	</cfquery>
	<cfif query.recordcount gt 0>
		<cfset result="<ul class='list-style-disc pl-4 pr-2 mt-2 mb-0'>">
		<cfloop query="query">
			<cfquery name="mediaQuery" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select media.media_id, media_uri, preview_uri, media_type
				from media_relations left join media on media_relations.media_id = media.media_id
				where media_relations.media_relationship = 'shows permit'
					and media_relations.related_primary_key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value=#query.permit_id#>
			</cfquery>
		 	<cfset mediaLink = "&##8855;">
			<cfloop query="mediaQuery">
				<cfset mediaLink = "<a href='#media_uri#' target='_blank' rel='noopener noreferrer'><img src='#getMediaPreview(preview_uri,media_type)#' height='15'></a>" >
			</cfloop>
			<cfset result = result & "<li class='my-1'><span>#mediaLink# #permit_type# #permit_num# Issued:#dateformat(issued_date,'yyyy-mm-dd')# #IssuedByAgent#</span></li>">
		</cfloop>
		<cfset result= result & "</ul>">
	</cfif>
	<cfreturn result>
</cffunction>

<!----------------------------------------------------------------------------------------------------------------->
<!--- backing for a permit autocomplete control --->
<cffunction name="getPermitAutocomplete" access="remote" returntype="any" returnformat="json">
	<cfargument name="term" type="string" required="yes">
	<cfset data = ArrayNew(1)>

	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result" timeout="#Application.query_timeout#">
			select distinct permit_num, permit_type, specific_type, permit_title, to_char(issued_date,'YYYY-MM-DD') as issued_date, permit.permit_id,
				issuedBy.agent_name as IssuedByAgent
			from permit left join permit_shipment on permit.permit_id = permit_shipment.permit_id
				left join preferred_agent_name issuedBy on permit.issued_by_agent_id = issuedBy.agent_id
			where upper(permit_num) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(term)#%">
					OR upper(permit_title) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(term)#%">
			order by permit_num, specific_type, issued_date
		</cfquery>
		<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfset row["id"] = "#search.permit_id#">
			<cfif len(search.issued_date) gt 0><cfset i_date= ", " & search.issued_date><cfelse><cfset i_date=""></cfif>
			<cfset row["value"] = "#search.permit_num# #search.permit_title#" >
			<cfset row["meta"] = "#search.permit_num# #search.permit_title# (#search.specific_type##i_date#)" >
			<cfset data[i] = row>
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
<!--- backing for a permit number autocomplete control --->
<cffunction name="getPermitNumberAutocomplete" access="remote" returntype="any" returnformat="json">
	<cfargument name="term" type="string" required="yes">
	<cfset data = ArrayNew(1)>
	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			select distinct permit_num, permit_id
			from permit 
			where upper(permit_num) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(term)#%">
			order by permit_num
		</cfquery>
		<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfset row["id"] = "#search.permit_id#">
			<cfset row["value"] = "#search.permit_num#">
			<cfset data[i] = row>
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
<!--- backing for a permit title autocomplete control --->
<cffunction name="getPermitTitleAutocomplete" access="remote" returntype="any" returnformat="json">
	<cfargument name="term" type="string" required="yes">
	<cfset data = ArrayNew(1)>
	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			select distinct permit_title, permit_id
			from permit 
			where upper(permit_title) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(term)#%">
			order by permit_title
		</cfquery>
		<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfset row["id"] = "#search.permit_id#">
			<cfset row["value"] = "#search.permit_title#">
			<cfset data[i] = row>
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


<!--- obtain an html block for picking permits for a permit text control and permit_id control --->
<cffunction name="queryPermitPickerHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="valuecontrol" type="string" required="yes">
	<cfargument name="idcontrol" type="string" required="yes">
	<cfargument name="dialog" type="string" required="yes">

	<cfthread name="getPermitPickerThread">
		<cftry>
			<cfquery name="ctPermitType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select ct.permit_type, count(p.permit_id) uses from ctpermit_type ct left join permit p on ct.permit_type = p.permit_type
					group by ct.permit_type
					order by ct.permit_type
			</cfquery>
			<cfquery name="ctSpecificPermitType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select ct.specific_type, count(p.permit_id) uses from ctspecific_permit_type ct left join permit p on ct.specific_type = p.specific_type
					group by ct.specific_type
					order by ct.specific_type
			</cfquery>
			<cfoutput>
			<div class="container-fluid">
				<div class="row">
					<div class="col-12">
						<div class="search-box px-3 py-2">
						<h1 class="h3 mt-2">Search for Permits</h1>
						<form id="findPermitSearchForm" name="findPermit">
							<input type="hidden" name="method" value="getPermitsJSON" class="keeponclear">
							<div class="form-row mb-2">
								<div class="col-12 col-sm-6">
									<label for="issuedByAgent" class="data-entry-label mb-0">Issued By</label>
									<input type="text" name="issuedByAgent" id="issuedByAgent" class="data-entry-input">
								</div>
								<div class="col-12 col-sm-6">
									<label for="issuedToAgent"class="data-entry-label mb-0">Issued To</label>
									<input type="text" name="issuedToAgent" id="issuedToAgent" class="data-entry-input">
								</div>
							</div>
							<div class="form-row mb-2">
								<div class="col-12 col-sm-6">
									<label for="issued_date" class="data-entry-label mb-0">Issued Date</label>
									<input type="text" name="issued_date" id="issued_date" class="data-entry-input">
								</div>
								<div class="col-12 col-sm-6">
									<label for="renewed_date" class="data-entry-label mb-0">Renewed Date</label>
									<input type="text" name="renewed_date" id="renewed_date" class="data-entry-input">
								</div>
							</div>
							<div class="form-row mb-2">
								<div class="col-12 col-sm-6">
									<label for="exp_date" class="data-entry-label mb-0">Expiration Date</label>
									<input type="text" name="exp_date" id="exp_date" class="data-entry-input">
								</div>
								<div class="col-12 col-sm-6">
									<label for="permit_num_search" class="data-entry-label">Permit Number</label>
									<input type="text" name="permit_num" id="permit_num_search" class="data-entry-input">
								</div>
							</div>
							<div class="form-row mb-2">
								<div class="col-12 col-md-6">
									<label for="permit_type" class="data-entry-label mb-0">Permit Type</label>
									<select name="permit_Type" id="permit_type" class="data-entry-select w-75">
										<option value=""></option>
										<cfloop query="ctPermitType">
											<option value = "#ctPermitType.permit_type#">#ctPermitType.permit_type# (#ctPermitType.uses#)</option>
										</cfloop>
									</select>
								</div>
								<div class="col-12 col-md-6">
									<label for="permit_remarks" class="data-entry-label mb-0">Remarks</label>
									<input type="text" name="permit_remarks" class="data-entry-input">
								</div>
							</div>
							<div class="form-row mb-2">
								<div class="col-12 col-md-6">
									<label for="specific_type" class="data-entry-label mb-0">Specific Type</label>
									<select name="specific_type" class="data-entry-select w-75">
										<option value=""></option>
										<cfloop query="ctSpecificPermitType">
											<option value = "#ctSpecificPermitType.specific_type#">#ctSpecificPermitType.specific_type# (#ctSpecificPermitType.uses#)</option>
										</cfloop>
									</select>
								</div>
								<div class="col-12 col-md-6">
									<label for="permit_title" class="data-entry-label mb-0">Permit Title</label>
									<input type="text" name="permit_title" class="data-entry-input">
								</div>
							</div>
							<div class="form-row mb-2">
								<div class="col-12 col-md-6">
									<button type="submit" aria-label="Search for Permits" class="btn btn-xs btn-primary">Search<span class="fa fa-search pl-1"></span></button>
								</div>
							</div>
						</form>
						</div>
						<div class="row mt-3 mb-0 pb-0 jqx-widget-header border px-2">
							<h4>Results: </h4>
							<span class="d-block px-3 p-2" id="permitPickResultCount"></span> <span id="permitPickResultLink" class="d-block p-2"></span>
						</div>
						
						<div class="row mt-0">
							<div id="permitPickSearchText"></div>
							<div id="permitPickResultsGrid" class="jqxGrid"></div>
							<div id="enableselection"></div>
						</div>
						<script>
							$("##findPermitSearchForm").bind("submit", function(evt){
								evt.preventDefault();
								$("##permitPickResultsGrid").replaceWith("<div id='permitPickResultsGrid' class='jqxGrid'></div>");
								$("##permitPickResultCount").html("");
								$("##permitPickResultLink").html("");
								$("##permitPickSearchText").jqxGrid("showloadelement");

								var permitSearch = {
									datatype: "json",
									datafields: [
										{ name: "permit_id", type: "string" },
										{ name: "permit_num", type: "string" }, 
										{ name: "permit_type", type: "string" }, 
										{ name: "specific_type", type: "string" }, 
										{ name: "permit_title", type: "string" }, 
										{ name: "issued_date", type: "string" }, 
										{ name: "renewed_date", type: "string" },
										{ name: "exp_date", type: "string" },
										{ name: "permit_remarks", type: "string" },
										{ name: "IssuedByAgent", type: "string" },
										{ name: "IssuedToAgent", type: "string" }
									],
									root: "permitRecord",
									id: "permit_id",
									url: "/transactions/component/functions.cfc?" + $("##findPermitSearchForm").serialize()
								};

								var dataAdapter = new $.jqx.dataAdapter(permitSearch);

								var linkcellrenderer = function (index, datafield, value, defaultvalue, column, rowdata) { 
									var pvalue = rowdata.permit_num + " " + rowdata.permit_title + " (" + $.trim(rowdata.specific_type + " " + rowdata.issued_date) + ")";
									var result = "<button class=\"btn btn-xs btn-primary\" onclick=\" $('###idcontrol#').val( '" + value + "'); $('###valuecontrol#').val('" + pvalue + "'); $('###dialog#').dialog('close'); \">Select</button>";
									return result;
								};

								$("##permitPickResultsGrid").jqxGrid({
									width: "100%",
									autoheight: "true",
									source: dataAdapter,
									filterable: true,
									sortable: true,
									pageable: true,
									editable: false,
									pagesize: "5",
									pagesizeoptions: ["5","50","100"],
									showaggregates: false,
									columnsresize: true,
									autoshowfiltericon: true,
									autoshowcolumnsmenubutton: false,
									columnsreorder: true,
									groupable: false,
									selectionmode: 'singlerow',  // simple pick grid selection mode singlerow
									altrows: true,
									showtoolbar: false,
									ready: function () {
										$("##permitPickResultsGrid").jqxGrid('selectrow', 0);
									},
									columns: [
										{text: "Select", datafield: "permit_id", width: 100, hideable: false, hidden: false, cellsrenderer: linkcellrenderer }, 
										{text: "permit_num", datafield: "permit_num", width: 100, hideable: true, hidden: false }, 
										{text: "permit_type", datafield: "permit_type", width: 100, hideable: true, hidden: false }, 
										{text: "specific_type", datafield: "specific_type", width: 100, hideable: true, hidden: false }, 
										{text: "permit_title", datafield: "permit_title", width: 100, hideable: true, hidden: false }, 
										{text: "issued_date", datafield: "issued_date", width: 100, hideable: true, hidden: false }, 
										{text: "renewed_date", datafield: "renewed_date", width: 100, hideable: true, hidden: false },
										{text: "exp_date", datafield: "exp_date", width: 100, hideable: true, hidden: false },
										{text: "permit_remarks", datafield: "permit_remarks", width: 100, hideable: true, hidden: false }, 
										{text: "IssuedByAgent", datafield: "IssuedByAgent", width: 100, hideable: true, hidden: false },
										{text: "IssuedToAgent", datafield: "IssuedToAgent", width: 100, hideable: true, hidden: false }
									]
								});
							});
						</script>
					</div>
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
	<cfthread action="join" name="getPermitPickerThread" />
	<cfreturn getPermitPickerThread.output>
</cffunction>

<!---  Given a shipment_id, return a block of html code for a permit picking dialog to pick permits for the given
       shipment.
       @param shipment_id the shipment to which selected permits are to be related.
       @return html content for a permit picker dialog for transaction permits or an error message if an exception was raised.

       @see setShipmentForPermit 
       @see findPermitShipSearchResults  
--->
<cffunction name="shipmentPermitPickerHtml" returntype="string" access="remote">
	<cfargument name="shipment_id" type="string" required="yes">
	<cfargument name="shipment_label" type="string" required="yes">
   
	<cfthread name="getSPPHtmlThread">
 	<cftry>
		<cfquery name="ctPermitType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" timeout="#Application.short_timeout#">
			select ct.permit_type, count(p.permit_id) uses 
			from ctpermit_type ct left join permit p on ct.permit_type = p.permit_type 
			group by ct.permit_type
			order by ct.permit_type
		</cfquery>
		<cfquery name="ctSpecificPermitType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" timeout="#Application.short_timeout#">
			select ct.specific_type, count(p.permit_id) uses 
			from ctspecific_permit_type ct left join permit p on ct.specific_type = p.specific_type
			group by ct.specific_type
			order by ct.specific_type
		</cfquery>
		<cfoutput>
			<div class="container-fluid">
				<div class="row">
					<div class="col-12">
						<div class="search-box px-3 py-2">
						<h1 class="h3 mt-2">Search for Permissions &amp; Rights Documents
								<span class="smaller d-block mt-1">Any part of dates and names accepted, case isn't important</span>
						</h1>							
						<form id="findPermitForm" onsubmit="searchforpermits(event);">
								<input type="hidden" name="method" value="findPermitShipSearchResults">
								<input type="hidden" name="returnformat" value="plain">
								<input type="hidden" name="shipment_id" value="#shipment_id#">
								<input type="hidden" name="shipment_label" value="#shipment_label#">
								<div class="form-row">
									<div class="col-12 col-md-3 mt-1">
										<label for="pf_issuedByAgent" class="data-entry-label">Issued By</label>
										<input type="text" name="IssuedByAgent" id="pf_issuedByAgent" class="data-entry-input">
									</div>
									<div class="col-12 col-md-3 mt-1">
										<label for="pf_issuedToAgent" class="data-entry-label">Issued To</label>
										<input type="text" name="IssuedToAgent" id="pf_issuedToAgent" class="data-entry-input">
									</div>
									<div class="col-6 col-md-3 mt-1">
										<label for="pf_issued_date" class="data-entry-label">Issued Date</label>
										<input type="text" name="issued_Date" id="pf_issued_date" class="data-entry-input">
									</div>
									<div class="col-6 col-md-3 mt-1">
										<label for="pf_renewed_date" class="data-entry-label">Renewed Date</label>
										<input type="text" name="renewed_Date" id="pf_renewed_date" class="data-entry-input">
									</div>
								</div>
								<div class="form-row">
									<div class="col-12 col-md-3 mt-1">
										<label class="data-entry-label" for="pf_exp_date">Expiration Date</label>
										<input type="text" name="exp_Date" class="data-entry-input" id="pf_exp_date">
									</div>
									<div class="col-12 col-md-3 mt-1">
										<label class="data-entry-label" for="search_permit_num">Permit Number</label>
										<input type="text" name="permit_Num" id="search_permit_num" class="data-entry-input">
										<input type="hidden" name="permit_id" id="search_permit_id">
									</div>
									<script>
										$(document).ready(function() {
											$(makePermitPicker('search_permit_num','search_permit_id'));
											$('##search_permit_num').blur( function () {
												// prevent an invisible permit_id from being included in the search.
												if ($('##search_permit_num').val().trim() == "") { 
													$('##search_permit_id').val("");
												}
											});
										});
									</script>
									<div class="col-12 col-md-3 mt-1">
										<label class="data-entry-label" for="pf_permit_type">Permit Type</label>
										<select name="permit_Type" size="1" class="data-entry-select" id="pf_permit_type">
											<option value=""></option>
											<cfloop query="ctPermitType">
												<option value = "#ctPermitType.permit_type#">#ctPermitType.permit_type# (#ctPermitType.uses#)</option>
											</cfloop>
										</select>
									</div>
									<div class="col-12 col-md-3 mt-1">
										<label class="data-entry-label" for="pf_permit_remarks">Remarks</label>
										<input type="text" name="permit_remarks" id="pf_permit_remarks" class="data-entry-input">
									</div>
								</div>
								<div class="form-row">
									<div class="col-12 col-md-6 mt-1">
										<label class="data-entry-label" for="pf_specific_type">Specific Type</label>
										<select name="specific_type" size="1" id="pf_specific_type" class="data-entry-select">
											<option value=""></option>
											<cfloop query="ctSpecificPermitType">
												<option value="#ctSpecificPermitType.specific_type#" >#ctSpecificPermitType.specific_type# (#ctSpecificPermitType.uses#)</option>
											</cfloop>
										</select>
									</div>
									<div class="col-12 col-md-6 mt-1">
										<label class="data-entry-label" for="pf_permit_title">Permit Title</label>
										<input type="text" name="permit_title" id="pf_permit_title" class="data-entry-input">
									</div>
								</div>
								<div class="form-row">
									<div class="col-6 col-md-6 mt-1 mb-2">
										<input type="button" value="Search" class="btn btn-xs btn-primary mt-1 mr-2" onclick="$('##findPermitForm').submit()">	
										<script>
											function createPermitDialogDone () { 
												$("##permit_Num").val($("##permit_number_passon").val()); 
											};
										</script>
										<input type="reset" value="Clear" class="btn btn-xs btn-warning mt-1 mr-4">
									</div>
									<div class="col-6 col-md-6 mt-1 mb-2">
										<span id="createPermit_#shipment_id#_span">
											<input type='button' value='New Permit' class='btn btn-xs btn-secondary mt-1' onClick='opencreatepermitdialog("createPermitDlg_#shipment_id#","#shipment_label#", #shipment_id#, "shipment", createPermitDialogDone);' >
										</span>
										<div id="createPermitDlg_#shipment_id#"></div>
									</div>
								</div>
							</form>
							<script>
								function searchforpermits(event) { 
									event.preventDefault();
									// to debug ajax call on component getting entire page redirected to blank page uncomment to create submission
									// console.log($('##findPermitForm').serialize());
									jQuery.ajax({
										url: '/transactions/component/functions.cfc',
										type: 'post',
										data: $('##findPermitForm').serialize(),
										success: function (data) {
											$('##permitSearchResults').html(data);
										},
										error: function (jqXHR, textStatus, error) {
											handleFail(jqXHR,textStatus,error,'removing project from transaction record');
											$('##permitSearchResults').html('Error:' + textStatus);
										}
									});
									return false; 
								};
							</script>
						</div>
					
							<div id="permitSearchResults"></div>
					
					</div>
				</div>
			</div>
		</cfoutput>
	<cfcatch>
		<cfset error_message = cfcatchToErrorMessage(cfcatch)>
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfoutput>
			<h2 class="h3">Error in #function_called#:</h2>
			<div>#error_message#</div>
		</cfoutput>
	</cfcatch>
	</cftry>
	</cfthread>
	<cfthread action="join" name="getSPPHtmlThread" />
	<cfreturn getSPPHtmlThread.output>
</cffunction>

<!----------------------------------------------------------------------------------------------------------------->
<!--- Given a shipment_id and a list of permit search criteria return an html list of permits matching the
      search criteria, along with controls allowing selected permits to be linked to the specified shipment.

      @see shipmentPermitPickerHtml
      @see setShipmentForPermit 
--->
<cffunction name="findPermitShipSearchResults" access="remote" returntype="string">
	<cfargument name="shipment_id" type="string" required="yes">
	<cfargument name="shipment_label" type="string" required="yes">
	<cfargument name="IssuedByAgent" type="string" required="no">
	<cfargument name="IssuedToAgent" type="string" required="no">
	<cfargument name="issued_Date" type="string" required="no">
	<cfargument name="renewed_Date" type="string" required="no">
	<cfargument name="exp_Date" type="string" required="no">
	<cfargument name="permit_Num" type="string" required="no">
	<cfargument name="permit_id" type="string" required="no">
	<cfargument name="specific_type" type="string" required="no">
	<cfargument name="permit_Type" type="string" required="no">
	<cfargument name="permit_title" type="string" required="no">
	<cfargument name="permit_remarks" type="string" required="no">
	<cfset result = "">
	<cftry>
		<cfif NOT isdefined('IssuedByAgent')><cfset IssuedByAgent=''></cfif>
		<cfif NOT isdefined('IssuedToAgent')><cfset IssuedToAgent=''></cfif>
		<cfif NOT isdefined('issued_Date')><cfset issued_Date=''></cfif>
		<cfif NOT isdefined('renewed_Date')><cfset renewed_Date=''></cfif>
		<cfif NOT isdefined('exp_Date')><cfset exp_Date=''></cfif>
		<cfif NOT isdefined('permit_Num')><cfset permit_Num=''></cfif>
		<cfif NOT isdefined('permit_id')><cfset permit_id=''></cfif>
		<cfif NOT isdefined('specific_type')><cfset specific_type=''></cfif>
		<cfif NOT isdefined('permit_Type')><cfset permit_Type=''></cfif>
		<cfif NOT isdefined('permit_title')><cfset permit_title=''></cfif>
		<cfif NOT isdefined('permit_remarks')><cfset permit_remarks=''></cfif>
		<cfif len(IssuedByAgent) EQ 0 AND len(IssuedToAgent) EQ 0 AND len(issued_Date) EQ 0 AND 
				len(renewed_Date) EQ 0 AND len(exp_Date) EQ 0 AND len(permit_Num) EQ 0 AND 
				len(specific_type) EQ 0 AND len(permit_Type) EQ 0 AND len(permit_title) EQ 0 AND 
				len(permit_remarks) EQ 0 >
			<cfthrow type="noQueryParameters" message="No search criteria provided." >
		</cfif>

		<cfquery name="matchPermit" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" timeout="#Application.query_timeout#">
			select distinct permit.permit_id,
				issuedByPref.agent_name IssuedByAgent,
				issuedToPref.agent_name IssuedToAgent,
				issued_Date,
				renewed_Date,
				exp_Date,
				permit_Num,
				permit_Type,
				permit_title,
				specific_type,
				permit_remarks,
				(select count(*) from permit_shipment
					where permit_shipment.permit_id = permit.permit_id
					and permit_shipment.shipment_id = <cfqueryparam cfsqltype='CF_SQL_DECIMAL' value='#shipment_id#'>
				) as linkcount
			from 
				permit 
				left join preferred_agent_name issuedToPref on permit.issued_to_agent_id = issuedToPref.agent_id 
				left join preferred_agent_name issuedByPref on permit.issued_by_agent_id = issuedByPref.agent_id 
				left join agent_name issuedTo on permit.issued_to_agent_id = issuedTo.agent_id
				left join agent_name issuedBy on permit.issued_by_agent_id = issuedBy.agent_id 
				left join permit_trans on permit.permit_id = permit_trans.permit_id 
			where
				permit.permit_id is not null
				<cfif len(#permit_id#) gt 0>
					AND permit.permit_id = <cfqueryparam cfsqltype='CF_SQL_DECIMAL' value='#permit_id#'>
				</cfif>
				<cfif len(#IssuedByAgent#) gt 0>
					AND upper(issuedBy.agent_name) like <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='%#ucase(IssuedByAgent)#%'>
				</cfif>
				<cfif len(#IssuedToAgent#) gt 0>
					AND upper(issuedTo.agent_name) like <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='%#ucase(IssuedToAgent)#%'>
				</cfif>
				<cfif len(#issued_Date#) gt 0>
					AND upper(issued_Date) like <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='%#ucase(issued_Date)#%'>
				</cfif>
				<cfif len(#renewed_Date#) gt 0>
					AND upper(renewed_Date) like <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='%#ucase(renewed_Date)#%'>
				</cfif>
				<cfif len(#exp_Date#) gt 0>
					AND upper(exp_Date) like <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='%#ucase(exp_Date)#%'>
				</cfif>
				<cfif len(#permit_Num#) gt 0 and len(#permit_id#) EQ 0>
					AND permit_Num = <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#trim(permit_Num)#'>
				</cfif>
				<cfif len(#specific_type#) gt 0>
					AND specific_type = <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#specific_type#'>
				</cfif>
				<cfif len(#permit_Type#) gt 0>
					AND permit_Type = <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#permit_Type#'>
				</cfif>
				<cfif len(#permit_title#) gt 0>
					AND upper(permit_title) like <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='%#ucase(permit_title)#%'>
				</cfif>
				<cfif len(#permit_remarks#) gt 0>
					AND upper(permit_remarks) like <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='%#ucase(permit_remarks)#%'>
				</cfif>
			ORDER BY permit_id
		</cfquery>
		<cfset i=1>
		<cfset result = result & "<div class='border rounded px-0 bg-blue-gray pt-2 pb-3 mt-3'><h2 class='h4 font-weight-bold pl-3 my-2'>Find Permits to Link to #shipment_label#</h2>">
		<cfloop query="matchPermit" >
			<cfset result = result & "<div">
			<cfif (i MOD 2) EQ 0> 
				<cfset result = result & " class='list-even px-3'"> 
			<cfelse> 
				<cfset result = result & " class='list-odd px-3'"> 
			</cfif>
			<cfset result = result & "> ">
			<cfset result = result & "
		<form id='pp_#permit_id#_#shipment_id#_#i#' >
			Permit Number #matchPermit.permit_Num# (#matchPermit.permit_Type#:#matchPermit.specific_type#) 
			issued to #matchPermit.IssuedToAgent# by #matchPermit.IssuedByAgent# on #dateformat(matchPermit.issued_Date,'yyyy-mm-dd')# ">
			<cfif len(#matchPermit.renewed_Date#) gt 0><cfset result = result & " (renewed #dateformat(matchPermit.renewed_Date,'yyyy-mm-dd')#)"></cfif>
			<cfset result = result & ". Expires #dateformat(matchPermit.exp_Date,'yyyy-mm-dd')#.  ">
			<cfif len(#matchPermit.permit_remarks#) gt 0><cfset result = result & "Remarks: #matchPermit.permit_remarks# "></cfif> 
			<cfset result = result & " (ID## #matchPermit.permit_id#) #matchPermit.permit_title#
			<div id='pickResponse#shipment_id#_#i#'>">
				<cfif matchPermit.linkcount GT 0>
					<cfset result = result & "<span class='text-success'> This Permit is already linked to #shipment_label# </span>">
				<cfelse>
			<cfset result = result & "
				<input type='button' class='btn btn-xs mt-2 mb-2 btn-secondary'
				onclick='linkpermittoship(#matchPermit.permit_id#,#shipment_id#,""#shipment_label#"",""pickResponse#shipment_id#_#i#"");' value='Add this permit'>
			">
			</cfif>
					<cfset result = result & "</div></form></div>
		<script language='javascript' type='text/javascript'>
		$('##pp_#permit_id#_#shipment_id#_#i#').removeClass('ui-widget-content');
		function linkpermittoship(permit_id, shipment_id, shipment_label, div_id) { 
			jQuery.ajax({
				url: '/transactions/component/functions.cfc',
				type: 'post',
				data: {
					method: 'setShipmentForPermit',
					permit_id: permit_id,
					shipment_id: shipment_id,
					returnformat: 'json',
					queryformat: 'column'
				},
				success: function (data) {
					var dataobj = JSON.parse(data)
					$('##'+div_id).html(dataobj.DATA.MESSAGE);
				},
				error: function (jqXHR, textStatus) {
					$('##'+div_id).html('Error:' + textStatus);
				}
			});
		};
		</script>">
			<cfset i=i+1>
		</cfloop>
				<cfset result = result & "</div>	">
	<cfcatch>
		<cfset error_message = cfcatchToErrorMessage(cfcatch)>
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfset result = "Error in #function_called#: #error_message#">
	</cfcatch>
	</cftry>
	<cfreturn result>
</cffunction>

<!---  
	** function setShipmentForPermit Given a permit_id and a shipment_id, link the permit to the shipment 
	*
	* @param shipment_id the shipment to which to link the permit.
	* @param permit_id the permit to link to the shipment
	* @return a query containing status and message, status of 1 means success, 0 failure to insert, or 
	* if an exception was raised, an http response with http statuscode of 500.
	*
	* @see shipmentPermitPickerHtml
	* @see setShipmentForPermit 
--->
<cffunction name="setShipmentForPermit" access="remote">
	<cfargument name="shipment_id" type="numeric" required="yes">
	<cfargument name="permit_id" type="numeric" required="yes">
	<cftry>
		<cfquery name="insertResult" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="insertResultRes">
			insert into permit_shipment (permit_id, shipment_id)
			values ( <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#permit_id#">, <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#shipment_id#">)
		</cfquery>
		<cfif insertResultRes.recordcount eq 0>
			<cfset theResult=queryNew("status, message")>
			<cfset t = queryaddrow(theResult,1)>
			<cfset t = QuerySetCell(theResult, "status", "0", 1)>
			<cfset t = QuerySetCell(theResult, "message", "Record not added. #permit_id# #shipment_id# #deleteResult.sql#", 1)>
		</cfif>
		<cfif insertResultRes.recordcount eq 1>
			<cfset theResult=queryNew("status, message")>
			<cfset t = queryaddrow(theResult,1)>
			<cfset t = QuerySetCell(theResult, "status", "1", 1)>
			<cfset t = QuerySetCell(theResult, "message", "<span class='text-success'>Permit added to shipment</span>", 1)>
		</cfif>
	<cfcatch>
		<cfset error_message = cfcatchToErrorMessage(cfcatch)>
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn theResult>
</cffunction>

<!--- 
  ** function movePermitToShipment move a permit from one shippment to another 
  * @param permit_id the permit to move.
  * @source_shipment_id the shipment to move the permit from.
  * @target_shipment_id the shipment to move the permit to.
--->
<cffunction name="movePermitToShipment" access="remote">
	<cfargument name="source_shipment_id" type="numeric" required="yes">
	<cfargument name="target_shipment_id" type="numeric" required="yes">
	<cfargument name="permit_id" type="numeric" required="yes">
	<cftransaction>
		<cftry>
			<cfquery name="delete" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="deleteResultRes">
				delete from permit_shipment
				where permit_id =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#permit_id#">
					and shipment_id =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#source_shipment_id#">
			</cfquery>
			<cfif deleteResultRes.recordcount NEQ 1>
				<cfthrow message="Failed to properly delete old permit_shipment record">
			</cfif>
			<cfquery name="insertResult" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="insertResultRes">
				insert into permit_shipment (permit_id, shipment_id)
				values ( 
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#permit_id#">,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#target_shipment_id#">
				)
			</cfquery>
			<cfif insertResultRes.recordcount eq 0>
				<cfthrow message="Failed to properly insert new permit_shipment record">
			</cfif>
			<cfif insertResultRes.recordcount eq 1>
				<cfset theResult=queryNew("status, message")>
				<cfset t = queryaddrow(theResult,1)>
				<cfset t = QuerySetCell(theResult, "status", "1", 1)>
				<cfset t = QuerySetCell(theResult, "message", "<span class='text-success'>Permit added to shipment</span>", 1)>
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

<!--- backing for a permit lookup method returning json for permit table --->
<cffunction name="getPermitsJSON" access="remote" returntype="any" returnformat="json">
	<cfargument name="issuedByAgent" type="string" required="no">
	<cfargument name="issuedToAgent" type="string" required="no">
	<cfargument name="issued_date" type="string" required="no">
	<cfargument name="renewed_date" type="string" required="no">
	<cfargument name="exp_date" type="string" required="no">
	<cfargument name="permit_num" type="string" required="no">
	<cfargument name="permit_type" type="string" required="no">
	<cfargument name="specific_type" type="string" required="no">
	<cfargument name="permit_title" type="string" required="no">
	<cfargument name="permit_remarks" type="string" required="no">
	<cfset data = ArrayNew(1)>

	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result" timeout="#Application.query_timeout#">
			select distinct 
				permit.permit_id,
				permit_num, 
				permit_type, 
				specific_type, 
				permit_title, 
				to_char(issued_date,'YYYY-MM-DD') as issued_date, 
				to_char(renewed_date,'YYYY-MM-DD') as renewed_date,
				to_char(exp_date,'YYYY-MM-DD') as exp_date,
   			permit_remarks,
				issuedBy.agent_name as IssuedByAgent,
				issuedTo.agent_name as IssuedToAgent
			from permit left join permit_shipment on permit.permit_id = permit_shipment.permit_id
				left join preferred_agent_name issuedBy on permit.issued_by_agent_id = issuedBy.agent_id
				left join preferred_agent_name issuedTo on permit.issued_to_agent_id = issuedTo.agent_id
			where permit.permit_id is not null
				<cfif isdefined("issuedByAgent") AND len(#issuedByAgent#) gt 0>
					AND upper(issuedBy.agent_name) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(issuedByAgent)#%">
				</cfif>
				<cfif isdefined("issuedToAgent") AND len(#issuedToAgent#) gt 0>
					AND upper(issuedTo.agent_name) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(issuedToAgent)#%">
				</cfif>
				<cfif isdefined("issued_date") AND len(#issued_date#) gt 0>
					AND upper(issued_date) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(issued_date)#%">
				</cfif>
				<cfif isdefined("renewed_date") AND len(#renewed_date#) gt 0>
					AND upper(renewed_date) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(renewed_date)#%">
				</cfif>
				<cfif isdefined("exp_date") AND len(#exp_date#) gt 0>
					AND upper(exp_date) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(exp_date)#%">
				</cfif>
				<cfif isdefined("permit_num") AND len(#permit_num#) gt 0>
					AND upper(permit_num) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(permit_num)#%">
				</cfif>
				<cfif isdefined("specific_type") AND len(#specific_type#) gt 0>
					AND upper(specific_type) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(specific_type)#%">
				</cfif>
				<cfif isdefined("permit_type") AND len(#permit_type#) gt 0>
					AND upper(permit_type) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(permit_type)#%">
				</cfif>
				<cfif isdefined("permit_title") AND len(#permit_title#) gt 0>
					AND upper(permit_title) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(permit_title)#%">
				</cfif>
				<cfif isdefined("permit_remarks") AND len(#permit_remarks#) gt 0>
					AND upper(permit_remarks) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(permit_remarks)#%">
				</cfif>
			order by permit_num, specific_type, issued_date
		</cfquery>

		<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfset row["id"] = "#search.permit_id#">
			<cfset row["permit_id"] = "#search.permit_id#">
			<cfset row["permit_num"] = "#search.permit_num#">
			<cfset row["permit_type"] = "#search.permit_type#">
			<cfset row["specific_type"] = "#search.specific_type#">
			<cfset row["permit_title"] = "#search.permit_title#">
			<cfset row["permit_remarks"] = "#search.permit_remarks#">
			<cfset row["issued_date"] = "#search.issued_date#">
			<cfset row["renewed_date"] = "#search.renewed_date#">
			<cfset row["exp_date"] = "#search.exp_date#">
			<cfset row["issuedByAgent"] = "#search.issuedByAgent#">
			<cfset row["issuedToAgent"] = "#search.issuedToAgent#">
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


<cffunction name="getTransPermitMediaList" access="remote" returntype="string" returnformat="plain">
	<cfargument name="transaction_id" type="string" required="yes">

	<cfthread name="getPermitMediaListThread">
		<cftry>
			<cfquery name="transType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select transaction_type
				from trans
				where
					transaction_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
			</cfquery>
			<cfset transaction = transType.transaction_type>
			<cfquery name="getPermitMedia" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" timeout="#Application.query_timeout#">
				select distinct media_id, uri, permit_type, specific_type, permit_num, permit_title, show_on_shipment 
				from (
					select 
						mczbase.get_media_id_for_relation(p.permit_id, 'shows permit','application/pdf') as media_id,
						mczbase.get_media_uri_for_relation(p.permit_id, 'shows permit','application/pdf') as uri,
						p.permit_type, p.permit_num, p.permit_title, p.specific_type,
						ctspecific_permit_type.accn_show_on_shipment as show_on_shipment
					from
						<cfif transaction EQ "loan"> 
							loan_item li
						<cfelseif transaction EQ "deaccession">
							deacc_item li
						<cfelseif transaction EQ "borrow">
							borrow_item li
						<cfelseif transaction EQ "accn">
							cataloged_item li
						</cfif>
						<cfif transaction EQ "borrow">
							left join permit_trans on li.transaction_id = permit_trans.transaction_id
						<cfelse>
							left join specimen_part sp on li.collection_object_id = sp.collection_object_id
							left join cataloged_item ci on sp.derived_from_cat_item = ci.collection_object_id
							left join accn on ci.accn_id = accn.transaction_id
							left join permit_trans on accn.transaction_id = permit_trans.transaction_id
						</cfif>
						left join permit p on permit_trans.permit_id = p.permit_id
						left join ctspecific_permit_type on p.specific_type = ctspecific_permit_type.specific_type
					where 
						<cfif transaction EQ "accn">
							li.accn_id = <cfqueryparam CFSQLType="CF_SQL_DECIMAL" value="#transaction_id#">
						<cfelse>
							li.transaction_id = <cfqueryparam CFSQLType="CF_SQL_DECIMAL" value="#transaction_id#">
						</cfif>
					union
					select 
						mczbase.get_media_id_for_relation(p.permit_id, 'shows permit','application/pdf') as media_id, 
						mczbase.get_media_uri_for_relation(p.permit_id, 'shows permit','application/pdf') as uri,
						p.permit_type, p.permit_num, p.permit_title, p.specific_type, 1 as show_on_shipment
					from shipment s
						left join permit_shipment ps on s.shipment_id = ps.shipment_id
						left join permit p on ps.permit_id = p.permit_id
					where s.transaction_id = <cfqueryparam CFSQLType="CF_SQL_DECIMAL" value="#transaction_id#">
				) where permit_type is not null
			</cfquery>
			<cfoutput>
					<cfset uriList = ''>
					<ul class="list-style-disc pl-4 pr-0">
						<cfloop query="getPermitMedia">
							<cfif media_id is ''>
								<li class="">#permit_type# #specific_type# #permit_num# #permit_title# (no pdf)</li>
							<cfelse>
								<cfif show_on_shipment EQ 1>
									<li class=""><a href="#uri#">#permit_type# #permit_num#</a> #permit_title#</li>
									<cfset uriList = ListAppend(uriList,uri)>
								<cfelse>
									<li class=""><a href="#uri#">#permit_type# #permit_num#</a> #permit_title# (not included in PDF of All)</li>
								</cfif>
							</cfif>
						</cfloop>
					</ul>
			</cfoutput>
		<cfcatch>
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cfthread>
	<cfthread action="join" name="getPermitMediaListThread" />
	<cfreturn getPermitMediaListThread.output>
</cffunction>

<!----------------------------------------------------------------------------------------------------------------->
<!--- Create an html form for entering a new permit and linking it to a transaction or shipment.   
      @param related_id the transaction or shipment ID to link the new permit to.
      @param related_label a human readable description of the transaction or shipment to link the new permit to.
      @param relation_type 'transaction' to relate the new permit to a transaction, 'shipment' to relate to a shipment.
      @return an html form suitable for placement as the content of a jquery-ui dialog to create the new permit.

      @see createNewPermitForTrans
---> 
<cffunction name="getNewPermitForTransHtml" access="remote" returntype="string">
	<cfargument name="related_id" type="string" required="yes">
	<cfargument name="related_label" type="string" required="yes">
	<cfargument name="relation_type" type="string" required="yes">

	<cfthread name="getPermitTransDialogThread">

		<cftry>
			<cfif relation_type EQ "transaction">
				<cfset transaction_id = related_id>
			<cfelse>
				<cfset shipment_id = related_id>
			</cfif>
		
			<cfquery name="ctSpecificPermitType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select ct.specific_type, ct.permit_type, count(p.permit_id) uses 
				from ctspecific_permit_type ct left join permit p on ct.specific_type = p.specific_type
				group by ct.specific_type, ct.permit_type
				order by ct.specific_type
			</cfquery>
			<cfoutput>
				<h2>Create New Permissions &amp; Rights Document</h2>
				<p>Enter a new record for a permit or similar document related to permissions and rights (access benefit sharing agreements,
				material transfer agreements, collecting permits, salvage permits, etc.)  This record will be linked to #related_label#</p>
				<form id='newPermitForm' onsubmit='addnewpermit'>
					<input type='hidden' name='method' value='createNewPermitForTrans'>
					<input type='hidden' name='returnformat' value='plain'>
					<input type='hidden' name='related_id' value='#related_id#'>
					<input type='hidden' name='related_label' value='#related_label#'>
					<input type='hidden' name='relation_type' value='#relation_type#'>
					<div class="form-row">
						<div class="col-12 col-md-4">
							<span class="my-1 data-entry-label">
								<label for="npf_issued_by">Issued By</label>
								<span id="npf_issued_by_view_link" class="px-2">&nbsp;</span>
							</span>
							<input type="hidden" name="IssuedByAgentID" id="npf_IssuedByAgentId" value=""
									onchange=" updateAgentLink($('##npf_IssuedByAgentId').val(),'npf_issued_by_view_link'); ">
							<div class="input-group">
								<div class="input-group-prepend">
									<span class="input-group-text smaller" id="npf_issuedbyagent_icon"><i class="fa fa-user" aria-hidden="true"></i></span> 
								</div>
								<input type="text" name="IssuedByAgent" id="npf_issued_by" required class="form-control form-control-sm data-entry-input reqdClr">
							</div>
							<script>
								$(document).ready(function() {
									$(makeRichTransAgentPicker('npf_issued_by','npf_IssuedByAgentId','npf_issuedbyagent_icon','npf_issued_by_view_link',null)); 
								});
							</script>
						</div>
						<div class="col-12 col-md-4">
							<span class="my-1 data-entry-label">
								<label for="npf_issued_to">Issued To:</label>
								<span id="npf_issued_to_view_link" class="px-2">&nbsp;</span>
							</span>
							<input type="hidden" name="IssuedToAgentID" id="npf_IssuedToAgentId" value=""
									onchange=" updateAgentLink($('##npf_IssuedToAgentId').val(),'npf_issued_to_view_link'); ">
							<div class="input-group">
								<div class="input-group-prepend">
									<span class="input-group-text smaller" id="npf_issuedtoagent_icon"><i class="fa fa-user" aria-hidden="true"></i></span> 
								</div>
								<input type="text" name="IssuedToAgent" id="npf_issued_to" required class="form-control form-control-sm data-entry-input reqdClr">
							</div>
							<script>
								$(document).ready(function() {
									$(makeRichTransAgentPicker('npf_issued_to','npf_IssuedToAgentId','npf_issuedtoagent_icon','npf_issued_to_view_link',null)); 
								});
							</script>
						</div>
						<div class="col-12 col-md-4">
							<span class="my-1 data-entry-label">
								<label for="npf_contact">Contact Person</label>
								<span id="npf_contact_view_link" class="px-2">&nbsp;</span>
							</span>
							<input type="hidden" name="contact_agent_id" id="npf_ContactAgentId" value=""
									onchange=" updateAgentLink($('##npf_ContactAgentId').val(),'npf_contact_view_link'); ">
							<div class="input-group">
								<div class="input-group-prepend">
									<span class="input-group-text smaller" id="npf_contactagent_icon"><i class="fa fa-user" aria-hidden="true"></i></span> 
								</div>
								<input type="text" name="ContactAgent" id="npf_contact" class="form-control form-control-sm data-entry-input">
							</div>
							<script>
								$(document).ready(function() {
									$(makeRichTransAgentPicker('npf_contact','npf_ContactAgentId','npf_contactagent_icon','npf_contact_view_link',null)); 
								});
							</script>
						</div>
					</div>
					<div class="form-row">
						<div class="col-12 col-md-4">
							<label for="npf_issued_date" class="data-entry-label">Issued Date</label>
							<input type="text" name="issued_date" id="npf_issued_date" class="data-entry-input">
						</div>
						<div class="col-12 col-md-4">
							<label for="npf_renewed_date" class="data-entry-label">Renewed Date</label>
							<input type='text' name='renewed_Date'id="npf_renewed_date" class="data-entry-input" >
						</div>
						<div class="col-12 col-md-4">
							<label for="npf_exp_date" class="data-entry-label">Expiration Date</label>
							<input type="text" name="exp_Date" id="npf_exp_date" class="data-entry-input">
						</div>
					</div>
					<div class="form-row">
						<div class="col-12 col-md-6">
							<label for="npf_permit_num" class="data-entry-label">Permit/Document Number</label>
							<input type='text' name='permit_Num'id="npf_permit_num" class="data-entry-input" >
						</div>
						<div class="col-12 col-md-6">
							<label for="specific_type" class="data-entry-label">Specific Document Type</label>
							<select name='specific_type' id='specific_type' size='1' class='reqdClr data-entry-select' required='yes' >
								<option value=''></option>
								<cfloop query="ctSpecificPermitType">
									<option value = '#ctSpecificPermitType.specific_type#'>#ctSpecificPermitType.specific_type# (#ctSpecificPermitType.permit_type#)</option>
								</cfloop>
							</select>
							<cfif isdefined("session.roles") and listfindnocase(session.roles,"admin_permits")>
								<button id='addSpecificTypeButton' onclick='openAddSpecificTypeDialog(); event.preventDefault();' class="btn btn-xs btn-secondary">+</button>
								<div id='newPermitASTDialog'></div>
							</cfif>
						</div>
					</div>
					<div class="form-row">
						<div class="col-12 col-md-6">
							<label for="npf_permit_title" class="data-entry-label">Document Title</label>
							<input type="text" name="permit_title" id="npf_permit_title" class="data-entry-input">
						</div>
						<div class="col-12 col-md-6">
							<label for="npf_permit_remarks" class="data-entry-label">Remarks</label>
							<input type="text" name="permit_remarks" id="npf_permit_remarks" class="data-entry-input">
						</div>
					</div>
					<div class="form-row">
						<div class="col-12">
							<label for="npf_restriction_summary" class="data-entry-label">Summary of Restrictions on use</label>
							<textarea cols='80' rows='3' name='restriction_summary' id="npf_restriction_summary" class="form-control autogrow"></textarea>
						</div>
					</div>
					<div class="form-row">
						<div class="col-12">
							<label for="npf_benefits_summary" class="data-entry-label">Summary of Agreed Benefits</label>
							<textarea cols='80' rows='3' name='benefits_summary' id="npf_benefits_summary" class="form-control autogrow"></textarea>
						</div>
					</div>
					<div class="form-row">
						<div class="col-12">
							<label for="npf_benefits_provided" class="data-entry-label">Benefits Provided</label>
							<textarea cols='80' rows='3' name='benefits_provided' id="npf_benefits_provided" class="form-control autogrow"></textarea>
						</div>
					</div>
					<!--- Note: Save Permit Record button is created on containing dialog by opencreatepermitdialog() js function. --->
					<script language='javascript' type='text/javascript'>
						$("textarea.autogrow").keyup(autogrow);
						function addnewpermit(event) { 
							event.preventDefault();
							return false; 
						};
					</script>
				</form> 
				<div id='permitAddResults'></div>
			</cfoutput>
		<cfcatch>
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfoutput>
				<h2 class="h3">Error in #function_called#:</h2>
				<div>#error_message#</div>
			</cfoutput>
		</cfcatch>
		</cftry>
	</cfthread>
	<cfthread action="join" name="getPermitTransDialogThread" />
	<cfreturn getPermitTransDialogThread.output>
</cffunction>
<!--------------------------------------------------------------------------------------------------->
<!--- Given information about a new permissions/rights document record, create that record, and
      link it to a provided transaction or shipment.

      @param related_id the transaction_id or shipment_id to link the new permit to.
      @param related_label a human readable descriptor of the transaction or shipment to link to.
      @param relation_type the value "tranasction" to link the new permit to a transaction, "shipment"
            to link it to a shipment.

      @see getNewPermitForTransHtml
--->
<cffunction name="createNewPermitForTrans" returntype="string" access="remote">
	<cfargument name="related_id" type="string" required="yes">
	<cfargument name="related_label" type="string" required="yes">
	<cfargument name="relation_type" type="string" required="yes">
	<cfargument name="specific_type" type="string" required="yes">
	<cfargument name="issuedByAgentId" type="string" required="yes">
	<cfargument name="issuedToAgentId" type="string" required="yes">
	<cfargument name="issued_date" type="string" required="no">
	<cfargument name="renewed_date" type="string" required="no">
	<cfargument name="exp_date" type="string" required="no">
	<cfargument name="permit_num" type="string" required="no">
	<cfargument name="permit_title" type="string" required="no">
	<cfargument name="permit_remarks" type="string" required="no">
	<cfargument name="restriction_summary" type="string" required="no">
	<cfargument name="benefits_summary" type="string" required="no">
	<cfargument name="benefits_provided" type="string" required="no">
	<cfargument name="contact_agent_id" type="string" required="no">

	<cfset result = "">

	<cftransaction action="begin">
	<cftry>
		<cfif NOT isdefined('issued_date')><cfset issued_date=''></cfif>
		<cfif NOT isdefined('renewed_date')><cfset renewed_date=''></cfif>
		<cfif NOT isdefined('exp_date')><cfset exp_date=''></cfif>
		<cfif NOT isdefined('permit_num')><cfset permit_num=''></cfif>
		<cfif NOT isdefined('permit_title')><cfset permit_title=''></cfif>
		<cfif NOT isdefined('permit_remarks')><cfset permit_remarks=''></cfif>
		<cfif NOT isdefined('restriction_summary')><cfset restriction_summary=''></cfif>
		<cfif NOT isdefined('benefits_summary')><cfset benefits_summary=''></cfif>
		<cfif NOT isdefined('benefits_provided')><cfset benefits_provided=''></cfif>
		<cfif NOT isdefined('contact_agent_id')><cfset contact_agent_id=''></cfif>

		<cfif relation_type EQ "transaction">
			 <cfset transaction_id = related_id>
		 <cfelse>
			 <cfset shipment_id = related_id>
		 </cfif>

		<cfquery name="ptype" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		   select permit_type from ctspecific_permit_type where specific_type = <cfqueryparam CFSQLTYPE="CF_SQL_VARCHAR" value="#specific_type#">
		</cfquery>
		<cfset permit_type = #ptype.permit_type#>
		<cfquery name="nextPermit" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select sq_permit_id.nextval nextPermit from dual
		</cfquery>
		<cfif isdefined("specific_type") and len(#specific_type#) is 0 and ( not isdefined("permit_type") OR len(#permit_type#) is 0 )>
			<cfthrow message="Error: There was an error selecting the permit type for the specific document type.  Please file a bug report.">
		</cfif>
		<cfquery name="newPermit" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="newPermitResult">
			INSERT INTO permit (
				PERMIT_ID,
				ISSUED_BY_AGENT_ID
				<cfif len(#ISSUED_DATE#) gt 0>
					,ISSUED_DATE
				</cfif>
				,ISSUED_TO_AGENT_ID
				<cfif len(#RENEWED_DATE#) gt 0>
					,RENEWED_DATE
				</cfif>
				<cfif len(#EXP_DATE#) gt 0>
					,EXP_DATE
				</cfif>
				<cfif len(#PERMIT_NUM#) gt 0>
					,PERMIT_NUM
				</cfif>
				,PERMIT_TYPE
				,SPECIFIC_TYPE
				<cfif len(#PERMIT_TITLE#) gt 0>
					,PERMIT_TITLE
				</cfif>
				<cfif len(#PERMIT_REMARKS#) gt 0>
					,PERMIT_REMARKS
				</cfif>
				<cfif len(#restriction_summary#) gt 0>
					,restriction_summary
				</cfif>
				<cfif len(#benefits_summary#) gt 0>
					,benefits_summary
				</cfif>
				<cfif len(#benefits_provided#) gt 0>
					,benefits_provided
				</cfif>
				<cfif len(#contact_agent_id#) gt 0>
					,contact_agent_id
				</cfif>)
			VALUES (
				#nextPermit.nextPermit#
				, <cfqueryparam CFSQLTYPE="CF_SQL_DECIMAL" value="#IssuedByAgentId#">
				<cfif len(#ISSUED_DATE#) gt 0>
					,<cfqueryparam CFSQLTYPE="CF_SQL_TIMESTAMP" value="#dateformat(ISSUED_DATE,"yyyy-mm-dd")#">
				</cfif>
				, <cfqueryparam CFSQLTYPE="CF_SQL_DECIMAL" value="#IssuedToAgentId#">
				<cfif len(#RENEWED_DATE#) gt 0>
					,<cfqueryparam CFSQLTYPE="CF_SQL_TIMESTAMP" value="#dateformat(RENEWED_DATE,"yyyy-mm-dd")#">
				</cfif>
				<cfif len(#EXP_DATE#) gt 0>
					,<cfqueryparam CFSQLTYPE="CF_SQL_TIMESTAMP" value="#dateformat(EXP_DATE,"yyyy-mm-dd")#">
				</cfif>
				<cfif len(#PERMIT_NUM#) gt 0>
					, <cfqueryparam CFSQLTYPE="CF_SQL_VARCHAR" value="#permit_num#">
				</cfif>
				, <cfqueryparam CFSQLTYPE="CF_SQL_VARCHAR" value="#permit_type#">
				, <cfqueryparam CFSQLTYPE="CF_SQL_VARCHAR" value="#specific_type#">
				<cfif len(#PERMIT_TITLE#) gt 0>
					, <cfqueryparam CFSQLTYPE="CF_SQL_VARCHAR" value="#permit_title#">
				</cfif>
				<cfif len(#PERMIT_REMARKS#) gt 0>
					, <cfqueryparam CFSQLTYPE="CF_SQL_VARCHAR" value="#permit_remarks#">
				</cfif>
				<cfif len(#restriction_summary#) gt 0>
					, <cfqueryparam CFSQLTYPE="CF_SQL_VARCHAR" value="#restriction_summary#">
				</cfif>
				<cfif len(#benefits_summary#) gt 0>
					, <cfqueryparam CFSQLTYPE="CF_SQL_VARCHAR" value="#benefits_summary#">
				</cfif>
				<cfif len(#benefits_provided#) gt 0>
					, <cfqueryparam CFSQLTYPE="CF_SQL_VARCHAR" value="#benefits_provided#">
				</cfif>
				<cfif len(#contact_agent_id#) gt 0>
					, <cfqueryparam CFSQLTYPE="CF_SQL_DECIMAL" value="#contact_agent_id#">
				</cfif>)
		</cfquery>
		<cfif newPermitResult.recordcount eq 1>
			<cfset result = result & "<span>Created new Permissons/Rights record. ">
			<cfset result = result & "<a id='permitEditLink' href='/transactions/Permit.cfm?permit_id=#nextPermit.nextPermit#&action=edit' target='_blank'>Edit</a></span>">
			<cfset result = result & "<form><input type='hidden' value='#permit_num#' id='permit_number_passon'></form>">
			<cfset result = result & "<script>$('##permitEditLink).removeClass(ui-widget-content);'</script>">
		</cfif>
		<cfquery name="newPermitLink" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="newPermitLinkResult">
			<cfif relation_type EQ "transaction">
				INSERT into permit_trans (permit_id, transaction_id)
			<cfelse>
				INSERT into permit_shipment (permit_id, shipment_id)
			</cfif>
			VALUES
				(<cfqueryparam CFSQLTYPE="CF_SQL_DECIMAL" value="#nextPermit.nextPermit#">,
				<cfqueryparam CFSQLTYPE="CF_SQL_DECIMAL" value="#related_id#">)
		</cfquery>
		<cfif newPermitLinkResult.recordcount eq 1>
			<cfset result = result & "Linked to #related_label#">
		</cfif>
		<cftransaction action="commit">
	<cfcatch>
		<cftransaction action="rollback">
		<cfset error_message = cfcatchToErrorMessage(cfcatch)>
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfset result = "Error in #function_called#: #error_message#">
	</cfcatch>
	</cftry>
	</cftransaction>
	<cfreturn result >
</cffunction>
<!------------------------------------------------------->
<cffunction name="getTrans_agent_role" access="remote">
	<!---  obtain the list of transaction agent roles, used to populate agent role picklist for new agent rows in edit transaction forms --->
	<cfargument name="transaction_type" type="string" required="no">

	<cfif isDefined("transaction_type") AND len(transaction_type) GT 0 >
		<cfif transaction_type EQ 'accn'><cfset transaction_type = 'Accn'></cfif>
		<cfif transaction_type EQ 'accession'><cfset transaction_type = 'Accn'></cfif>
		<cfif transaction_type EQ 'borrow'><cfset transaction_type = 'Borrow'></cfif>
		<cfif transaction_type EQ 'deacc'><cfset transaction_type = 'Deaccn'></cfif>
		<cfif transaction_type EQ 'deaccession'><cfset transaction_type = 'Deaccn'></cfif>
		<cfif transaction_type EQ 'loan'><cfset transaction_type = 'Loan'></cfif>
		<cfquery name="k" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select distinct(cttrans_agent_role.trans_agent_role) 
			from cttrans_agent_role  
				left join trans_agent_role_allowed on cttrans_agent_role.trans_agent_role = trans_agent_role_allowed.trans_agent_role
			where 
				trans_agent_role_allowed.transaction_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#transaction_type#">
			order by cttrans_agent_role.trans_agent_role
		</cfquery>
		<cfif k.recordcount EQ 0>
			<cfthrow message="getTrans_agent_role invoked with unknown transaction type (must match trans_agent_role_allowed.transaction_type values).">
		</cfif>
	<cfelse>
		<cfquery name="k" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select trans_agent_role from cttrans_agent_role where trans_agent_role != 'entered by' order by trans_agent_role
		</cfquery>
	</cfif>
	<cfreturn k>
</cffunction>

<!---- function addCollObjectsAccn
  Given a transaction_id for an accession and a string delimited list of guids, look up the collection object id 
  values for the guids and update the accn_id values of the cataloged item records.  
	@param transaction_id the pk of the accession to add the collection objects to.
	@param guid_list a comma delimited list of guids in the form MCZ:Col:catnum
	@return a json structure containing added=nummber of updated relations.
--->
<cffunction name="addCollObjectsAccn" access="remote" returntype="any" returnformat="json">
	<cfargument name="transaction_id" type="string" required="yes">
	<cfargument name="guid_list" type="string" required="yes">
	<cfset guids = "">
	<cfif Find(',', guid_list) GT 0>
		<cfset guidArray = guid_list.Split(',')>
		<cfset separator ="">
		<cfloop array="#guidArray#" index=#idx#>
			<!--- skip any empty elements --->
			<cfif len(trim(idx)) GT 0>
				<!--- trim to prevent guid, guid from failing --->
				<cfset guids = guids & separator & trim(idx)>
				<cfset separator = ",">
			</cfif>
		</cfloop>
	<cfelse>
		<cfset guids = trim(guid_list)>
	</cfif>

	<cfset data = ArrayNew(1)>
	<cftry>
		<cfset rows = 0>
		<cftransaction>
			<cfquery name="updateAccnCheck" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="updateAccnCheck_result">
				SELECT count(*) as ct from trans
				WHERE  
					TRANSACTION_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value='#transaction_id#'>
					and transaction_type = 'accn'
			</cfquery>
			<cfif updateAccnCheck.ct NEQ 1>
				<cfthrow message = "Unable to update transaction. Provided transaction_id does not match a record in the trans table with a type of accn.">
			</cfif>
			<cfquery name="find" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="find_result">
				select distinct 
					collection_object_id from #session.flatTableName# 
				where 
					guid in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#guids#" list="yes" >)
			</cfquery>
			<cfif find_result.recordcount GT 0>
				<cfloop query=find>
					<cfquery name="add" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="add_result">
						update cataloged_item 
						set accn_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
						where collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#find.collection_object_id#">
					</cfquery>
					<cfset rows = rows + add_result.recordcount>
				</cfloop>
			</cfif>
		</cftransaction>

		<cfset i = 1>
		<cfset row = StructNew()>
		<cfset row["status"] = "success">
		<cfset row["added"] = "#rows#">
		<cfset row["matches"] = "#find_result.recordcount#">
		<cfset row["findquery"] = "#rereplace(find_result.sql,'[\n\r\t]+',' ','ALL')#">
		<cfset data[i] = row>
		<cfreturn #serializeJSON(data)#>
	<cfcatch>
		<cfset error_message = cfcatchToErrorMessage(cfcatch)>
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>

</cffunction>

<!------------------------------------------------------->
<cffunction name="saveAccn" access="remote" returntype="any" returnformat="json">
	<cfargument name="transaction_id" type="string" required="yes">
	<cfargument name="accession_date" type="string" required="no">
	<cfargument name="nature_of_material" type="string" required="yes">
	<cfargument name="collection_id" type="string" required="yes">
	<cfargument name="trans_remarks" type="string" required="no">
	<cfargument name="accn_type" type="string" required="yes">
	<cfargument name="accn_number" type="string" required="yes">
	<cfargument name="received_date" type="string" required="yes">
	<cfargument name="accn_status" type="string" required="yes">
	<cfargument name="estimated_count" type="string" required="no">

	<cfif isdefined("trans_remarks") AND len(trans_remarks) GT 0 >
		<cfset trans_remarks = replace(trans_remarks,"#CHR(13)##CHR(10)#",CHR(13),"All")>
	</cfif>
	<cfif isdefined("nature_of_material") AND len(nature_of_material) GT 0 >
		<cfset nature_of_material = replace(nature_of_material,"#CHR(13)##CHR(10)#",CHR(13),"All")>
	</cfif>

	<cfset data = ArrayNew(1)>
	<cftransaction>
		<cftry>
			<cfquery name="updateAccnCheck" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="newAccnCheck_result">
				SELECT count(*) as ct from trans
				WHERE  
					TRANSACTION_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value='#transaction_id#'>
					and transaction_type = 'accn'
			</cfquery>
			<cfif updateAccnCheck.ct NEQ 1>
				<cfthrow message = "Unable to update transaction. Provided transaction_id does not match a record in the trans table with a type of accn.">
			</cfif>
			<cfquery name="updateAccnTrans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="updateAccnTrans_result">
				UPDATE trans set
					<cfif isdefined("accession_date") AND len(#accession_date#) gt 0 >
						TRANS_DATE = <cfqueryparam cfsqltype="CF_SQL_TIMESTAMP" value="#dateformat(accession_date,'yyyy-mm-dd')#">,
					</cfif>
					NATURE_OF_MATERIAL = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#nature_of_material#">,
					collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_id#">
					<cfif isdefined("trans_remarks") >
						, trans_remarks = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trans_remarks#">
					</cfif>
				WHERE
					TRANSACTION_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value='#transaction_id#'>
			</cfquery>
			<cfquery name="updateAccn" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="updateAccn_result">
				UPDATE accn set
					ACCN_TYPE = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value='#accn_type#'>,
					accn_number = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value='#accn_number#'>,
					RECEIVED_DATE = <cfqueryparam cfsqltype="CF_SQL_TIMESTAMP" value='#dateformat(received_date,"yyyy-mm-dd")#'>,
					ACCN_STATUS = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value='#accn_status#'>,
					<cfif isdefined("estimated_count") AND len(estimated_count) gt 0 >
						estimated_count = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value='#estimated_count#'>
					<cfelse>
						estimated_count = null
					</cfif>
				WHERE
					TRANSACTION_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value='#transaction_id#'>
			</cfquery>
			<cfloop from="1" to="#numAgents#" index="n">
				<cfif IsDefined("trans_agent_id_" & n) >
					<cfset trans_agent_id_ = evaluate("trans_agent_id_" & n)>
					<cfset agent_id_ = evaluate("agent_id_" & n)>
					<cfset trans_agent_role_ = evaluate("trans_agent_role_" & n)>
					<cftry>
						<cfset del_agnt_=evaluate("del_agnt_" & n)>
					<cfcatch>
						<cfset del_agnt_=0>
					</cfcatch>
					</cftry>
					<cfif del_agnt_ is "1" and isnumeric(trans_agent_id_) and trans_agent_id_ gt 0>
						<cfquery name="del" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							delete from trans_agent 
							where trans_agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#trans_agent_id_#">
						</cfquery>
					<cfelse>
						<cfif len(agent_id_) GT 0>
							<!--- don't try to add/update a blank row --->
							<cfif trans_agent_id_ is "new" and del_agnt_ is 0>
								<cfquery name="newTransAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
									insert into trans_agent (
										transaction_id,
										agent_id,
										trans_agent_role
									) values (
										<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">,
										<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id_#">,
										<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trans_agent_role_#">
									)
								</cfquery>
							<cfelseif del_agnt_ is 0>
								<cfquery name="upTransAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
									update trans_agent set
										agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id_#">,
										trans_agent_role = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trans_agent_role_#">
									where
										trans_agent_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#trans_agent_id_#">
								</cfquery>
							</cfif>
						</cfif>
					</cfif>
				</cfif>
			</cfloop>

			<cfset row = StructNew()>
			<cfset row["status"] = "saved">
			<cfset row["id"] = "#transaction_id#">
			<cfset data[1] = row>
			<cftransaction action="commit">
		<cfcatch>
			<cftransaction action="rollback">
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfif find("ORA-01461",error_message) GT 0>
				<cfset error_message = "You may be entering more characters in a field than it can hold. #error_message#">
			</cfif>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn #serializeJSON(data)#>
</cffunction>

<!--- obtain an html block containing restrictions imposed by permissions and rights documents on material (borrow items) in a borrow 
 @param transaction_id identifying the borrow for which to lookup restrictions and agreeed benefits
 @return a block of html listing restrictions and benefits from permissions and rights documents on the borrow.
--->
<cffunction name="getBorrowLimitations" returntype="string" access="remote" returnformat="plain">
	<cfargument name="transaction_id" type="string" required="yes">

	<cfthread name="getBorrowLimitThread">
		<cftry>
			<cfoutput>
				<cfquery name="borrowLimitations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" timeout="#Application.query_timeout#">
					select count(distinct borrow_item.borrow_item_id) as ct,
						permit.permit_id, permit.specific_type, permit.restriction_summary, permit.benefits_summary, permit.benefits_provided, 
						borrow.transaction_id as borrow_id, borrow.borrow_number
					from  
						borrow
						left join permit_trans on borrow.transaction_id = permit_trans.transaction_id
						left join permit on permit_trans.permit_id = permit.permit_id
						left join borrow_item on borrow.transaction_id = borrow_item.transaction_id
					where 
						borrow.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
						and (permit.restriction_summary IS NOT NULL
								or
							 permit.benefits_summary IS NOT NULL)
					group by
						permit.permit_id, permit.specific_type, permit.restriction_summary, permit.benefits_summary, permit.benefits_provided, 
						borrow.transaction_id, borrow.borrow_number
					union
					select count(distinct borrow_item.borrow_item_id) as ct,
						permit.permit_id, permit.specific_type, permit.restriction_summary, permit.benefits_summary, permit.benefits_provided, 
						borrow.transaction_id as borrow_id, borrow.borrow_number
					from 
						borrow
						left join shipment on borrow.transaction_id = shipment.transaction_id
						left join permit_shipment on shipment.shipment_id = permit_shipment.shipment_id
						left join permit on permit_shipment.permit_id = permit.permit_id
						left join borrow_item on borrow.transaction_id = borrow_item.transaction_id
					where 
						borrow.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
						and (permit.restriction_summary IS NOT NULL
								or
							 permit.benefits_summary IS NOT NULL)
					group by
						permit.permit_id, permit.specific_type, permit.restriction_summary, permit.benefits_summary, permit.benefits_provided, 
						borrow.transaction_id, borrow.borrow_number
				</cfquery>
				<cfif borrowLimitations.recordcount GT 0>
					<table class='table table-responsive d-md-table mb-0'>
						<thead class='thead-light'><th>Items</th><th>Document</th><th>Restrictions Summary</th><th>Agreed Benefits</th><th>Benefits Provided</th></thead>
						<tbody>
							<cfloop query="borrowLimitations">
								<tr>
									<td>#ct#</td>
									<td><a href='/transactions/Permit.cfm?Action=edit&permit_id=#permit_id#'>#specific_type#</a></td>
									<td>#restriction_summary#</td>
									<td>#benefits_summary#</td>
									<td>#benefits_provided#</td>
								</tr>
							</cfloop>
						</tbody>
					</table>
				<cfelse>
					None recorded.
				</cfif>
			</cfoutput>
		<cfcatch>
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfoutput>
				<h2 class="h3">Error in #function_called#:</h2>
				<div>#error_message#</div>
			</cfoutput>
		</cfcatch>
		</cftry>
	</cfthread>
	<cfthread action="join" name="getBorrowLimitThread" />
	<cfreturn getBorrowLimitThread.output>
</cffunction>

<!--- method saveBorrow given a transaction_id and additional fields, update a borrow record --->
<cffunction name="saveBorrow" access="remote" returntype="any" returnformat="json">
	<cfargument name="transaction_id" type="string" required="yes">
	<cfargument name="lenders_invoice_returned_fg" type="string" required="no">
	<cfargument name="lenders_trans_num_cde" type="string" required="no">
	<cfargument name="lender_loan_type" type="string" required="no">
	<cfargument name="received_date" type="string" required="no">
	<cfargument name="return_acknowledged_date" type="string" required="no">
	<cfargument name="due_date" type="string" required="no">
	<cfargument name="lenders_loan_date" type="string" required="no">
	<cfargument name="lenders_instructions" type="string" required="no">
	<cfargument name="description_of_borrow" type="string" required="yes">
	<cfargument name="no_of_specimens" type="string" required="no">
	<cfargument name="borrow_status" type="string" required="yes">
	<cfargument name="nature_of_material" type="string" required="yes">
	<cfargument name="trans_remarks" type="string" required="no">
	<cfargument name="numagents" type="string" required="no">

	<cfset data = ArrayNew(1)>
	<cftransaction>
		<cftry>
			<cfquery name="setBorrow" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE borrow SET
					LENDERS_INVOICE_RETURNED_FG = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#LENDERS_INVOICE_RETURNED_FG#">,
					LENDERS_TRANS_NUM_CDE = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#LENDERS_TRANS_NUM_CDE#">,
					LENDER_LOAN_TYPE = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#LENDER_LOAN_TYPE#">,
					<cfif isdefined("received_date") AND len(received_date) GT 0>
						RECEIVED_DATE = <cfqueryparam CFSQLTYPE="CF_SQL_TIMESTAMP" value="#dateformat(RECEIVED_DATE,"yyyy-mm-dd")#">,
					</cfif>
					<cfif isdefined("due_date") AND len(due_date) GT 0>
						DUE_DATE = <cfqueryparam CFSQLTYPE="CF_SQL_TIMESTAMP" value="#dateformat(DUE_DATE,"yyyy-mm-dd")#">,
					</cfif>
					<cfif isdefined("lenders_loan_date") AND len(lenders_loan_date) GT 0>
						LENDERS_LOAN_DATE = <cfqueryparam CFSQLTYPE="CF_SQL_TIMESTAMP" value="#dateformat(LENDERS_LOAN_DATE,"yyyy-mm-dd")#">,
					</cfif>
					<cfif isdefined("return_acknowldeged_date") AND len(return_acknowldeged_date) GT 0>
						return_acknowldeged_date = <cfqueryparam CFSQLTYPE="CF_SQL_TIMESTAMP" value="#dateformat(return_acknowldeged_date,"yyyy-mm-dd")#">,
					</cfif>
					LENDERS_INSTRUCTIONS = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#LENDERS_INSTRUCTIONS#">,
					DESCRIPTION_OF_BORROW = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#DESCRIPTION_OF_BORROW#">,
					NO_OF_SPECIMENS = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#NO_OF_SPECIMENS#">,
					BORROW_STATUS = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#BORROW_STATUS#">
				WHERE
					TRANSACTION_ID=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#TRANSACTION_ID#">
			</cfquery>
			<cfquery name="setTrans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE trans SET
					collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_id#">,
					<cfif isdefined("trans_date") AND len(trans_date) GT 0>
						TRANS_DATE = <cfqueryparam cfsqltype="CF_SQL_TIMESTAMP" value="#dateformat(trans_date,"yyyy-mm-dd")#">,
					</cfif>
					NATURE_OF_MATERIAL = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#NATURE_OF_MATERIAL#">
					<cfif isDefined("trans_remarks")>
						,TRANS_REMARKS = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#TRANS_REMARKS#">
					</cfif>
				WHERE
					TRANSACTION_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#TRANSACTION_ID#">
			</cfquery>
			<cfloop from="1" to="#numAgents#" index="n">
				<cfif IsDefined("trans_agent_id_" & n) >
					<cfset trans_agent_id_ = evaluate("trans_agent_id_" & n)>
					<cfset agent_id_ = evaluate("agent_id_" & n)>
					<cfset trans_agent_role_ = evaluate("trans_agent_role_" & n)>
					<cftry>
						<cfset del_agnt_=evaluate("del_agnt_" & n)>
					<cfcatch>
						<cfset del_agnt_=0>
					</cfcatch>
					</cftry>
					<cfif del_agnt_ is "1" and isnumeric(trans_agent_id_) and trans_agent_id_ gt 0>
						<cfquery name="del" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							delete from trans_agent 
							where trans_agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#trans_agent_id_#">
						</cfquery>
					<cfelse>
						<cfif len(agent_id_) GT 0>
							<!--- don't try to add/update a blank row --->
							<cfif trans_agent_id_ is "new" and del_agnt_ is 0>
								<cfquery name="newTransAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
									insert into trans_agent (
										transaction_id,
										agent_id,
										trans_agent_role
									) values (
										<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">,
										<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id_#">,
										<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trans_agent_role_#">
									)
								</cfquery>
							<cfelseif del_agnt_ is 0>
								<cfquery name="upTransAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
									update trans_agent set
										agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id_#">,
										trans_agent_role = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trans_agent_role_#">
									where
										trans_agent_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#trans_agent_id_#">
								</cfquery>
							</cfif>
						</cfif>
					</cfif>
				</cfif>
			</cfloop>

			<cfset row = StructNew()>
			<cfset row["status"] = "saved">
			<cfset row["id"] = "#transaction_id#">
			<cfset data[1] = row>
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
	<cfreturn #serializeJSON(data)#>
</cffunction>

<!------------------------------------------------------->
<cffunction name="saveLoan" access="remote" returntype="any" returnformat="json">
	<cfargument name="transaction_id" type="string" required="yes">
	<cfargument name="loan_number" type="string" required="yes">
	<cfargument name="loan_type" type="string" required="yes">
	<cfargument name="loan_status" type="string" required="yes">
	<cfargument name="collection_id" type="string" required="yes">
	<cfargument name="initiating_date" type="string" required="yes">
	<cfargument name="nature_of_material" type="string" required="yes">
	<!--- return_due_date is required, but not for exhibition subloans --->
	<cfargument name="return_due_date" type="string" required="no">
	<cfargument name="trans_remarks" type="string" required="no">
	<cfargument name="loan_description" type="string" required="no">
	<cfargument name="loan_instructions" type="string" required="no">
	<cfargument name="insurance_value" type="string" required="no">
	<cfargument name="insurance_maintained_by" type="string" required="no">
	<cfargument name="numagents" type="string" required="no">
	<!--- closed_date is not passed as it is set by TU_CLOSED_DATE on change of loan status to closed from some other value --->
	<cfset data = ArrayNew(1)>
	<cftransaction>
		<cftry>
			<cfquery name="updateLoanCheck" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="updateLoanCheck_result">
				SELECT count(*) as ct from trans
				WHERE  
					TRANSACTION_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value='#transaction_id#'>
					and transaction_type = 'loan'
			</cfquery>
			<cfif updateLoanCheck.ct NEQ 1>
				<cfthrow message = "Unable to update transaction. Provided transaction_id does not match a record in the trans table with a type of loan.">
			</cfif>
			<cfquery name="upTrans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE trans SET
					collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_id#">,
					TRANS_DATE = <cfqueryparam cfsqltype="CF_SQL_TIMESTAMP" value="#dateformat(initiating_date,"yyyy-mm-dd")#">,
					NATURE_OF_MATERIAL = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#NATURE_OF_MATERIAL#">
					<cfif isDefined("trans_remarks")>
						,trans_remarks = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trans_remarks#">
					</cfif>
				where
					transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
			</cfquery>
			<cfif not isdefined("return_due_date") or len(return_due_date) eq 0 >
				<!--- If there is no value set for return_due_date, don't overwrite an existing value.  ---> 
				<!--- This prevents edits to exhibition-subloans from wiping out an existing date value --->
				<cfquery name="upLoan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					UPDATE loan SET
						LOAN_TYPE = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#LOAN_TYPE#">,
						LOAN_NUMBER = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#loan_number#">,
						loan_status = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#loan_status#">,
						loan_description = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#loan_description#">,
						LOAN_INSTRUCTIONS = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#LOAN_INSTRUCTIONS#">,
						insurance_value = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#INSURANCE_VALUE#">,
						insurance_maintained_by = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#INSURANCE_MAINTAINED_BY#">
					where 
						transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
				</cfquery>
			<cfelse>
				<cfquery name="upLoan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					UPDATE loan SET
						return_due_date = <cfqueryparam cfsqltype="CF_SQL_TIMESTAMP" value="#dateformat(return_due_date,"yyyy-mm-dd")#">,
						LOAN_TYPE = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#LOAN_TYPE#">,
						LOAN_NUMBER = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#loan_number#">,
						loan_status = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#loan_status#">,
						loan_description = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#loan_description#">,
						LOAN_INSTRUCTIONS = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#LOAN_INSTRUCTIONS#">,
						insurance_value = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#INSURANCE_VALUE#">,
						insurance_maintained_by = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#INSURANCE_MAINTAINED_BY#">
					where 
						transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
				</cfquery>
			</cfif>
			<cfif isdefined("loan_type") and loan_type EQ 'exhibition-master' >
				<!--- Propagate due date to child exhibition-subloans --->
				<cfset formatted_due_date = dateformat(return_due_date,"yyyy-mm-dd")>
				<cfquery name="upChildLoans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					UPDATE loan SET
						return_due_date = <cfqueryparam value = "#formatted_due_date#" CFSQLType="CF_SQL_TIMESTAMP">
					WHERE 
						loan_type = 'exhibition-subloan' AND
 						transaction_id in (select lr.related_transaction_id from loan_relations lr where
						lr.relation_type = 'Subloan' AND
						lr.transaction_id = <cfqueryparam value = "#TRANSACTION_ID#" CFSQLType="CF_SQL_DECIMAL">)
				</cfquery>
			</cfif>
			<cfloop from="1" to="#numAgents#" index="n">
				<cfif IsDefined("trans_agent_id_" & n) >
					<cfset trans_agent_id_ = evaluate("trans_agent_id_" & n)>
					<cfset agent_id_ = evaluate("agent_id_" & n)>
					<cfset trans_agent_role_ = evaluate("trans_agent_role_" & n)>
					<cftry>
						<cfset del_agnt_=evaluate("del_agnt_" & n)>
					<cfcatch>
						<cfset del_agnt_=0>
					</cfcatch>
					</cftry>
					<cfif del_agnt_ is "1" and isnumeric(trans_agent_id_) and trans_agent_id_ gt 0>
						<cfquery name="del" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							delete from trans_agent 
							where trans_agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#trans_agent_id_#">
						</cfquery>
					<cfelse>
						<cfif len(agent_id_) GT 0>
							<!--- don't try to add/update a blank row --->
							<cfif trans_agent_id_ is "new" and del_agnt_ is 0>
								<cfquery name="newTransAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
									insert into trans_agent (
										transaction_id,
										agent_id,
										trans_agent_role
									) values (
										<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">,
										<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id_#">,
										<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trans_agent_role_#">
									)
								</cfquery>
							<cfelseif del_agnt_ is 0>
								<cfquery name="upTransAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
									update trans_agent set
										agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id_#">,
										trans_agent_role = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trans_agent_role_#">
									where
										trans_agent_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#trans_agent_id_#">
								</cfquery>
							</cfif>
						</cfif>
					</cfif>
				</cfif>
			</cfloop>
			<cfset row = StructNew()>
			<cfset row["status"] = "saved">
			<cfset row["id"] = "#transaction_id#">
			<cfset data[1] = row>
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
	<cfreturn #serializeJSON(data)#>
</cffunction>

<cffunction name="okToPrintLoan" returntype="any" access="remote" returnformat="json">
	<cfargument name="transaction_id" type="string" required="yes">
	
	<cfset data = ArrayNew(1)>
	<cftry>
		<cfquery name="transAgents" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select agent_id, trans_agent_role
			from trans_agent
			where
				trans_agent.transaction_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
		</cfquery>
		<cfquery name="inhouse" dbtype="query">
			select count(distinct(agent_id)) c from transAgents where trans_agent_role='in-house contact'
		</cfquery>
		<cfquery name="outside" dbtype="query">
			select count(distinct(agent_id)) c from transAgents where trans_agent_role='received by'
		</cfquery>
		<cfquery name="authorized" dbtype="query">
			select count(distinct(agent_id)) c from transAgents where trans_agent_role='in-house authorized by'
		</cfquery>
		<cfquery name="recipientinstitution" dbtype="query">
			select count(distinct(agent_id)) c from transAgents where trans_agent_role='recipient institution'
		</cfquery>
		<cfif inhouse.c is 1 and outside.c is 1 and authorized.c GT 0 and recipientinstitution.c GT 0 >
			<cfset okToPrint = true>
			<cfset okToPrintMessage = "">
		<cfelse>
			<cfset okToPrint = false>
			<cfset okToPrintMessage = 'One "in-house authorized by", one "in-house contact", one "received by", and one "recipient institution" are required to print loan forms. '>
		</cfif>
		<cfset row = StructNew()>
		<cfset row["okToPrint"] = "#okToPrint#">
		<cfset row["message"] = "#okToPrintMessage#">
		<cfset row["id"] = "#transaction_id#">
		<cfset data[1] = row>
	<cfcatch>
		<cfset error_message = cfcatchToErrorMessage(cfcatch)>
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
		
	<cfreturn #serializeJSON(data)#>
</cffunction>

<!--- obtain an html block to populate a print list dialog for an accession --->
<cffunction name="getAccnPrintListDialogContent" returntype="string" access="remote" returnformat="plain">
	<cfargument name="transaction_id" type="string" required="yes">

	<cfthread name="getAccnPrintHtmlThread">
		<cftry>
			<cfoutput>
				<h2 class="h2">Print Accession Paperwork</h2> 
				<p>Links to available reports:</p>
				<ul>
					<li><a href="/Reports/report_printer.cfm?transaction_id=#transaction_id#&report=mcz_files_accn_header" target="_blank">Header Copy for MCZ Files</a></li>
				</ul>
			</cfoutput>
		<cfcatch>
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfoutput>
				<h2 class="h3">Error in #function_called#:</h2>
				<div>#error_message#</div>
			</cfoutput>
		</cfcatch>
		</cftry>
	</cfthread>
	<cfthread action="join" name="getAccnPrintHtmlThread" />
	<cfreturn getAccnPrintHtmlThread.output>
</cffunction>

<!--- obtain an html block to populate a print list dialog for an accession --->
<cffunction name="getDeaccnPrintListDialogContent" returntype="string" access="remote" returnformat="plain">
	<cfargument name="transaction_id" type="string" required="yes">

	<cfthread name="getAccnPrintHtmlThread">
		<cftry>
			<cfquery name="deaccDetails" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select deacc_type
				from deaccession
				where
					deaccession.transaction_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
			</cfquery>
			<cfquery name="transAgents" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select agent_id, trans_agent_role
				from trans_agent
				where
					trans_agent.transaction_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
			</cfquery>
			<cfquery name="inhouse" dbtype="query">
				select count(distinct(agent_id)) c from transAgents where trans_agent_role='in-house contact'
			</cfquery>
			<cfquery name="authorized" dbtype="query">
				select count(distinct(agent_id)) c from transAgents where trans_agent_role='in-house authorized by'
			</cfquery>
			<cfoutput>
				<h2 class="h2">Print Deaccession Paperwork</h2> 
				<p>Links to available reports:</p>
				<ul>
					<cfif inhouse.c is 1 and authorized.c GT 0 >
						<li><a href="/Reports/report_printer.cfm?transaction_id=#transaction_id#&report=mcz_deaccession_header" target="_blank">MCZ Gift/Exchange Deaccession Header</a></li>
					</cfif>
					<li><a href="/Reports/report_printer.cfm?transaction_id=#transaction_id#&report=mcz_files_deaccession_header" target="_blank">Header Copy for MCZ Files</a></li>
					<cfif inhouse.c is 1 and authorized.c GT 0 >
						<li><a href="/Reports/report_printer.cfm?transaction_id=#transaction_id#&report=mcz_deaccession_discarded_header" target="_blank">MCZ Discarded Deaccession Header</a></li>
						<li><a href="/Reports/report_printer.cfm?transaction_id=#transaction_id#&report=mcz_deaccession_items" target="_blank">MCZ Deaccession Items</a></li>
						<!--- only show Object header if deaccession is of type other or transfer or internal transfer--->
						<cfif deaccDetails.deacc_type EQ "#MAGIC_TTYPE_OTHER#" OR deaccDetails.deacc_type EQ "#MAGIC_DTYPE_TRANSFER#" OR deaccDetails.deacc_type EQ "#MAGIC_DTYPE_INTERNALTRANSFER#" >
							<!--- report is actually the same as the gift/exchange header, it is a general purpose deaccession report (except for discards).  --->
							<li><a href="/Reports/report_printer.cfm?transaction_id=#transaction_id#&report=mcz_deaccession_header" target="_blank">MCZ Object Deaccession Header</a></li>
						</cfif>
					</cfif>
					<li><a href="/edecView.cfm?transaction_id=#transaction_id#">USFWS eDec</a></li>
				</ul>
			</cfoutput>
		<cfcatch>
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfoutput>
				<h2 class="h3">Error in #function_called#:</h2>
				<div>#error_message#</div>
			</cfoutput>
		</cfcatch>
		</cftry>
	</cfthread>
	<cfthread action="join" name="getAccnPrintHtmlThread" />
	<cfreturn getAccnPrintHtmlThread.output>
</cffunction>

<!--- obtain an html block to populate a print list dialog for an accession --->
<cffunction name="getBorrowPrintListDialogContent" returntype="string" access="remote" returnformat="plain">
	<cfargument name="transaction_id" type="string" required="yes">

	<cfthread name="getAccnPrintHtmlThread">
		<cftry>
			<cfoutput>
				<h2 class="h2">Print Borrow Paperwork</h2> 
				<p>Links to available reports:</p>
				<ul>
					<li><a href="/Reports/report_printer.cfm?transaction_id=#transaction_id#&report=mcz_borrower_header" target="_blank">MCZ Return Receipt Header</a></li>
					<li><a href="/Reports/report_printer.cfm?transaction_id=#transaction_id#&report=mcz_files_borrow_header" target="_blank">Header for MCZ Files</a></li>
            	<li><a href="/Reports/report_printer.cfm?transaction_id=#transaction_id#&report=mcz_borrow_items" target="_blank">MCZ Return Receipt Items</a></li>
				</ul>
   			<div class="p-1 border border-warning" style="width: 25rem;">
					<strong>The return shipment must be entered and marked 'Printed on invoice' (make sure that you don't have the shipment to the MCZ marked as 'Printed on invoice', or else the addresses will show up in the wrong places on the return receipt header).</strong>
				</div>
				</ul>
			</cfoutput>
		<cfcatch>
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfoutput>
				<h2 class="h3">Error in #function_called#:</h2>
				<div>#error_message#</div>
			</cfoutput>
		</cfcatch>
		</cftry>
	</cfthread>
	<cfthread action="join" name="getAccnPrintHtmlThread" />
	<cfreturn getAccnPrintHtmlThread.output>
</cffunction>

<!--- obtain an html block to populate a print list dialog for a loan --->
<cffunction name="getLoanPrintListDialogContent" returntype="string" access="remote" returnformat="plain">
	<cfargument name="transaction_id" type="string" required="yes">

	<cfthread name="getLoanPrintHtmlThread">
		<cftry>
			<cfset notOKMessage = "">
			<cfquery name="loanDetails" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select loan_type 
				from loan
				where
					loan.transaction_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
			</cfquery>
			<cfquery name="transAgents" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select agent_id, trans_agent_role
				from trans_agent
				where
					trans_agent.transaction_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
			</cfquery>
			<cfquery name="inhouse" dbtype="query">
				select count(distinct(agent_id)) c from transAgents where trans_agent_role='in-house contact'
			</cfquery>
			<cfquery name="outside" dbtype="query">
				select count(distinct(agent_id)) c from transAgents where trans_agent_role='received by'
			</cfquery>
			<cfquery name="authorized" dbtype="query">
				select count(distinct(agent_id)) c from transAgents where trans_agent_role='in-house authorized by'
			</cfquery>
			<cfquery name="recipientinstitution" dbtype="query">
				select count(distinct(agent_id)) c from transAgents where trans_agent_role='recipient institution'
			</cfquery>
			<cfif inhouse.c is 1 and outside.c is 1 and authorized.c GT 0 and recipientinstitution.c GT 0 >
				<cfset okToPrint = true>
			<cfelse>
				<cfif inhouse.c GT 1>
					<cfset notOKMessage = "there can be only one in-house contact.">
				<cfelseif outside.c GT 1>
					<cfset notOKMessage = "there can be only one received by agent.">
				<cfelse>
					<cfset notOKMessage = "a required agent role is missing.">
				</cfif>
				<cfset okToPrint = false>
			</cfif>
	
			<cfoutput>
				<h2 class="h2">Print Loan Paperwork</h2> 
				<p>Links to available reports:</p>
				<ul>
					<!--- report_printer.cfm takes parameters transaction_id, report, and sort, where
					sort={a field name that is in the select portion of the query specified in the custom tag}, or
					sort={cat_num_pre_int}, which is interpreted as order by cat_num_prefix, cat_num_integer.
					--->
					<cfif okToPrint  >
						<li><a href="/Reports/report_printer.cfm?transaction_id=#transaction_id#&report=mcz_loan_header" target="_blank">MCZ Invoice Header</a></li>
					<cfelse>
						<li>Invoice unavailable: #notOKMessage#</li>
					</cfif>
					<li><a href="/Reports/report_printer.cfm?transaction_id=#transaction_id#&report=mcz_files_loan_header" target="_blank">Header Copy for MCZ Files</a></li>
					<cfif inhouse.c is 1 and outside.c is 1 and loanDetails.loan_type eq 'exhibition-master' and recipientinstitution.c GT 0 >
						<li><a href="/Reports/report_printer.cfm?transaction_id=#transaction_id#&report=mcz_exhibition_loan_header" target="_blank">MCZ Exhibition Loan Header</a></li>
					</cfif>
					<cfif inhouse.c is 1 and outside.c is 1 and loanDetails.loan_type eq 'exhibition-master' and recipientinstitution.c GT 0 >
						<li><a href="/Reports/report_printer.cfm?transaction_id=#transaction_id#&report=mcz_exhib_loan_header_five_plus" target="_blank">MCZ Exhibition Loan Header Long</a></li>
					</cfif>
					<cfif inhouse.c is 1 and outside.c is 1 >
						<li><a href="/Reports/report_printer.cfm?transaction_id=#transaction_id#&report=mcz_loan_legacy" target="_blank">MCZ Legacy Invoice Header</a></li>
					</cfif>
					<cfif okToPrint >
						<li><a href="/Reports/report_printer.cfm?transaction_id=#transaction_id#&report=mcz_loan_items&sort=cat_num" target="_blank">MCZ Item Invoice</a></li>
						<li><a href="/Reports/report_printer.cfm?transaction_id=#transaction_id#&report=mcz_loan_items&sort=cat_num_pre_int" target="_blank">MCZ Item Invoice (cat num sort)</a></li>
						<li><a href="/Reports/report_printer.cfm?transaction_id=#transaction_id#&report=mcz_loan_items&sort=scientific_name" target="_blank">MCZ Item Invoice (taxon sort)</a></li>
						<li><a href="/Reports/report_printer.cfm?transaction_id=#transaction_id#&report=mcz_loan_items_parts&sort=cat_num" target="_blank">MCZ Item Parts Grouped Invoice</a></li>
						<li><a href="/Reports/report_printer.cfm?transaction_id=#transaction_id#&report=mcz_loan_items_parts&sort=cat_num_pre_int" target="_blank">MCZ Item Parts Grouped Invoice (cat num sort)</a></li>
						<li><a href="/Reports/report_printer.cfm?transaction_id=#transaction_id#&report=mcz_loan_items_parts&sort=scientific_name" target="_blank">MCZ Item Parts Grouped Invoice (taxon sort)</a></li>
					</cfif>
					<cfif inhouse.c is 1 and outside.c is 1 >
						<li><a href="/Reports/report_printer.cfm?transaction_id=#transaction_id#&report=mcz_loan_summary" target="_blank">MCZ Loan Summary Report</a></li>
					</cfif>
					<li><a href="/Reports/MCZDrawerTags.cfm?transaction_id=#transaction_id#&Action=itemLabels&format=Malacology" target="_blank">MCZ Drawer Tags</a></li>
					<li><a href="/edecView.cfm?transaction_id=#transaction_id#" target="_blank">USFWS eDec</a></li>
					<cfif (isdefined("session.roles") and listfindnocase(session.roles,"collops")) OR (isdefined("session.username") AND ucase(session.username) EQ "CWANGCLAYPOOL")  >
						<li><a href="/Reports/loan.cfm?transaction_id=#transaction_id#" target="_blank">DRAFT Combined Loan Paperwork</a></li>
					</cfif>
				</ul>
			</cfoutput>
		<cfcatch>
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfoutput>
				<h2 class="h3">Error in #function_called#:</h2>
				<div>#error_message#</div>
			</cfoutput>
		</cfcatch>
		</cftry>
	</cfthread>
	<cfthread action="join" name="getLoanPrintHtmlThread" />
	<cfreturn getLoanPrintHtmlThread.output>
</cffunction>

<!--- obtain an html block for agents for a transaction  --->
<cffunction name="agentTableHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="transaction_id" type="string" required="yes">
	<cfargument name="containing_form_id" type="string" required="yes">

	<cfthread name="getAgentHtmlThread">
		<cftry>
			<cfquery name="transType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select transaction_type
				from trans
				where
					transaction_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
			</cfquery>
			<cfset transaction = transType.transaction_type>
			<cfquery name="transAgents" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select
					trans_agent_id,
					trans_agent.agent_id,
					agent_name,
					trans_agent_role,
					MCZBASE.get_worstagentrank(trans_agent.agent_id) worstagentrank
				from
					trans_agent,
					preferred_agent_name
				where
					trans_agent.agent_id = preferred_agent_name.agent_id and
					trans_agent_role != 'entered by' and
					trans_agent.transaction_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
				order by
					trans_agent_role,
					agent_name
			</cfquery>
			<cfswitch expression="#transaction#">
				<cfcase value="loan">
					<cfset transLabel = 'Loan'>
					<!--- Obtain list of transaction agent roles relevant to loan editing to use for piclists for loan agent controls --->
					<cfquery name="cttrans_agent_role" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select distinct(cttrans_agent_role.trans_agent_role) 
						from cttrans_agent_role  
							left join trans_agent_role_allowed on cttrans_agent_role.trans_agent_role = trans_agent_role_allowed.trans_agent_role
						where trans_agent_role_allowed.transaction_type = 'Loan'
						order by cttrans_agent_role.trans_agent_role
					</cfquery>
					<cfquery name="requiredRoles" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select trans_agent_role 
						from trans_agent_role_allowed 
						where transaction_type = 'Loan' and required_to_print = 1
							and trans_agent_role not in (
								select trans_agent_role_allowed.trans_agent_role 
								from trans_agent_role_allowed left join trans_agent on trans_agent_role_allowed.trans_agent_role = trans_agent.trans_agent_role
								where transaction_type = 'Loan' and required_to_print = 1
									and trans_agent.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
								group by trans_agent_role_allowed.trans_agent_role
								having count(trans_agent_id) >0
							)
					</cfquery>
					<cfif requiredRoles.recordcount EQ 0  >
						<cfset okToPrint = true>
						<cfset okToPrintMessage = "">
					<cfelse>
						<cfset okToPrint = false>
						<cfset missingRoles="">
						<cfset sep="">
						<cfloop query="requiredRoles">
							<cfset missingRoles = "#missingRoles##sep#'<i>#requiredRoles.trans_agent_role#</i>'">
							<cfset sep=" ">
						</cfloop>
						<cfif requiredRoles.recordcount EQ 1>
							<cfset okToPrintMessage = 'An agent in the #missingRoles# role is required to print #transLabel# paperwork. '>
						<cfelse>
							<cfset okToPrintMessage = 'Agents in the #missingRoles# roles are required to print #transLabel# paperwork. '>
						</cfif>
					</cfif>
				</cfcase>
				<cfcase value="accn">
					<cfset transLabel = 'Accession'>
					<!--- Obtain list of transaction agent roles relevant to Accession editing --->
					<cfquery name="cttrans_agent_role" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select distinct(cttrans_agent_role.trans_agent_role) 
						from cttrans_agent_role  
							left join trans_agent_role_allowed on cttrans_agent_role.trans_agent_role = trans_agent_role_allowed.trans_agent_role
						where trans_agent_role_allowed.transaction_type = 'Accn'
						order by cttrans_agent_role.trans_agent_role
					</cfquery>
					<cfquery name="requiredRoles" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select trans_agent_role 
						from trans_agent_role_allowed 
						where transaction_type = 'Accn' and required_to_print = 1
							and trans_agent_role not in (
								select trans_agent_role_allowed.trans_agent_role 
								from trans_agent_role_allowed left join trans_agent on trans_agent_role_allowed.trans_agent_role = trans_agent.trans_agent_role
								where transaction_type = 'Accn' and required_to_print = 1
									and trans_agent.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
								group by trans_agent_role_allowed.trans_agent_role
								having count(trans_agent_id) >0
							)
					</cfquery>
					<cfif requiredRoles.recordcount EQ 0  >
						<cfset okToPrint = true>
						<cfset okToPrintMessage = "">
					<cfelse>
						<cfset okToPrint = false>
						<cfset missingRoles="">
						<cfset sep="">
						<cfloop query="requiredRoles">
							<cfset missingRoles = "#missingRoles##sep#'<i>#requiredRoles.trans_agent_role#</i>'">
							<cfset sep=" ">
						</cfloop>
						<cfif requiredRoles.recordcount EQ 1>
							<cfset okToPrintMessage = 'An agent in the #missingRoles# role is required to print #transLabel# paperwork. '>
						<cfelse>
							<cfset okToPrintMessage = 'Agents in the #missingRoles# roles are required to print #transLabel# paperwork. '>
						</cfif>
					</cfif>
				</cfcase>
				<cfcase value="deaccession">
					<cfset transLabel = 'Deaccession'>
					<!--- Obtain list of transaction agent roles relevant to Accession editing --->
					<cfquery name="cttrans_agent_role" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select distinct(cttrans_agent_role.trans_agent_role) 
						from cttrans_agent_role  
							left join trans_agent_role_allowed on cttrans_agent_role.trans_agent_role = trans_agent_role_allowed.trans_agent_role
						where trans_agent_role_allowed.transaction_type = 'Deaccn'
						order by cttrans_agent_role.trans_agent_role
					</cfquery>
					<cfquery name="requiredRoles" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select trans_agent_role 
						from trans_agent_role_allowed 
						where transaction_type = 'Deaccn' and required_to_print = 1
							and trans_agent_role not in (
								select trans_agent_role_allowed.trans_agent_role 
								from trans_agent_role_allowed left join trans_agent on trans_agent_role_allowed.trans_agent_role = trans_agent.trans_agent_role
								where transaction_type = 'Deaccn' and required_to_print = 1
									and trans_agent.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
								group by trans_agent_role_allowed.trans_agent_role
								having count(trans_agent_id) >0
							)
					</cfquery>
					<cfif requiredRoles.recordcount EQ 0  >
						<cfset okToPrint = true>
						<cfset okToPrintMessage = "">
					<cfelse>
						<cfset okToPrint = false>
						<cfset missingRoles="">
						<cfset sep="">
						<cfloop query="requiredRoles">
							<cfset missingRoles = "#missingRoles##sep#'<i>#requiredRoles.trans_agent_role#</i>'">
							<cfset sep=" ">
						</cfloop>
						<cfif requiredRoles.recordcount EQ 1>
							<cfset okToPrintMessage = 'An agent in the #missingRoles# role is required to print #transLabel# paperwork. '>
						<cfelse>
							<cfset okToPrintMessage = 'Agents in the #missingRoles# roles are required to print #transLabel# paperwork. '>
						</cfif>
					</cfif>
				</cfcase>
				<cfcase value="borrow">
					<cfset transLabel = 'Borrow'>
					<!--- Obtain list of transaction agent roles relevant to Accession editing --->
					<cfquery name="cttrans_agent_role" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select distinct(cttrans_agent_role.trans_agent_role) 
						from cttrans_agent_role  
							left join trans_agent_role_allowed on cttrans_agent_role.trans_agent_role = trans_agent_role_allowed.trans_agent_role
						where trans_agent_role_allowed.transaction_type = 'Borrow'
						order by cttrans_agent_role.trans_agent_role
					</cfquery>
					<cfquery name="requiredRoles" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select trans_agent_role 
						from trans_agent_role_allowed 
						where transaction_type = 'Borrow' and required_to_print = 1
							and trans_agent_role not in (
								select trans_agent_role_allowed.trans_agent_role 
								from trans_agent_role_allowed left join trans_agent on trans_agent_role_allowed.trans_agent_role = trans_agent.trans_agent_role
								where transaction_type = 'Borrow' and required_to_print = 1
									and trans_agent.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
								group by trans_agent_role_allowed.trans_agent_role
								having count(trans_agent_id) >0
							)
					</cfquery>
					<cfif requiredRoles.recordcount EQ 0  >
						<cfset okToPrint = true>
						<cfset okToPrintMessage = "">
					<cfelse>
						<cfset okToPrint = false>
						<cfset missingRoles="">
						<cfset sep="">
						<cfloop query="requiredRoles">
							<cfset missingRoles = "#missingRoles##sep#'<i>#requiredRoles.trans_agent_role#</i>'">
							<cfset sep=" ">
						</cfloop>
						<cfif requiredRoles.recordcount EQ 1>
							<cfset okToPrintMessage = 'An agent in the #missingRoles# role is required to print #transLabel# paperwork. '>
						<cfelse>
							<cfset okToPrintMessage = 'Agents in the #missingRoles# roles are required to print #transLabel# paperwork. '>
						</cfif>
					</cfif>
				</cfcase>
				<cfdefaultcase>
					<cfthrow message="unknown transaction type [#transaction#]">
				</cfdefaultcase>
			</cfswitch>
			<cfoutput>
				<section id="transactionAgentsTableSection" tabindex="0" aria-label="Agent Names participating in functional roles in this transaction" class="container">
					<div class="row my-1 bg-grayish pb-1 border rounded">
						<div class="w-100 text-center m-0 p-0" tabindex="0">
							<cfif okToPrint >
								<div id="printStatus" aria-label="This record has the minimum requirements to print" class="alert alert-success text-center small rounded-0 p-1 m-0 mx-0 mt-0 mb-2">OK to print</div>
							<cfelse>
								<div class="alert alert-danger small rounded-0 p-1 mb-2 m-0" aria-label="needs additional agent roles filled to print record">#okToPrintMessage#</div>
							</cfif>
						</div>
						<div class="col-12 mt-0" id="transactionAgentsTable">
							<h2 class="h4 pl-3" tabindex="0">#transLabel# Agents 
								<button type="button" class="btn btn-secondary btn-xs ui-widget ml-2 ui-corner-all" id="button_add_trans_agent" onclick=" addTransAgentToForm('','','','#containing_form_id#','#transaction#'); handleChange();" class="col-5"> Add Agent</button>		
		
							</h2>		  
							<cfset i=1>
							<cfloop query="transAgents">
								<cfset rowstyle = "list-odd">
								<cfif (i MOD 2) EQ 0> 
									<cfset rowstyle = "list-even">
								</cfif>
								<div class="row #rowstyle# my-0 py-1 border-top border-bottom">
									<div class="col-12 col-md-4 mt-2 mt-md-0 pr-md-0">
										<input type="hidden" name="agent_id_#i#" id="agent_id_#i#" value="#agent_id#"
												onchange="updateAgentLink($('##agent_id_#i#').val(),'agentViewLink_#i#'); ">
										<input type="hidden" name="trans_agent_id_#i#" id="trans_agent_id_#i#" value="#trans_agent_id#">
										<div class="input-group">
											<div class="input-group-prepend">
												<span class="input-group-text smaller" id="agent_icon_#i#"><i class="fa fa-user" aria-hidden="true"></i></span> 
											</div>
											<input type="text" name="trans_agent_#i#" id="trans_agent_#i#" required class="goodPick form-control form-control-sm data-entry-input" value="#agent_name#">
										</div>
										<script>
											$(document).ready(function() {
												$(makeRichTransAgentPicker('trans_agent_#i#','agent_id_#i#','agent_icon_#i#','agentViewLink_#i#',#agent_id#)); 
											});
										</script>
									</div>							
									<div class="col-12 col-md-1 px-md-0">
										<label class="data-entry-label"> 						
											<span id="agentViewLink_#i#" class="px-2 d-inline-block mt-1"><a href="/agents/Agent.cfm?agent_id=#agent_id#" class="" aria-label="View details of this agent" target="_blank">View</a>
												<cfif transAgents.worstagentrank EQ 'A'>
													&nbsp;
												<cfelseif transAgents.worstagentrank EQ 'F'>
													<img src='/shared/images/flag-red.svg.png' width='16' alt="flag-red">
												<cfelse>
													<img src='/shared/images/flag-yellow.svg.png' width='16' alt="flag-yellow">
												</cfif>
											</span>
										</label>
									</div>
									<div class="col-12 col-md-4">
										<select name="trans_agent_role_#i#" aria-label="role of this agent in this #transLabel#" id="trans_agent_role_#i#" class="data-entry-select">
											<cfloop query="cttrans_agent_role">
												<cfif cttrans_agent_role.trans_agent_role is transAgents.trans_agent_role>
													<cfset sel = 'selected="selected"'>
												<cfelse>
													<cfset sel = ''>
												</cfif>
												<option #sel# value="#trans_agent_role#">#trans_agent_role#</option>
											</cfloop>
										</select>
									</div>
									<div class="col-12 col-md-3">
										<button type="button" 
											class="btn btn-xs btn-warning float-left mt-2 mt-md-0 mb-1 mr-2" 
											onClick=' confirmDialog("Remove #agent_name# as #transAgents.trans_agent_role# from this #transLabel# ?", "Confirm Unlink Agent", function() { deleteTransAgent(#trans_agent_id#); } ); '
											>Remove</button>
										<button type="button" 
											class="btn btn-xs btn-secondary mt-2 mt-md-0 mb-1 float-left" 
											onClick="cloneAgentOnTrans(#agent_id#,'#agent_name#','#transAgents.trans_agent_role#');"
											>Clone</button>
									</div>
									<cfset i=i+1>	
								</div>
							</cfloop>
							<cfset na=i-1>
							<input type="hidden" id="numAgents" name="numAgents" value="#na#">
					</div>
				</section>
				<script>
					function cloneAgentOnTrans(agent_id,agent_name,current_role) { 
						// add trans_agent record
						addTransAgentToForm(agent_id,agent_name,current_role,'#containing_form_id#','#transaction#');
						// trigger save needed
						handleChange();
					}
				</script>
			</cfoutput>
		<cfcatch>
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfoutput>
				<h2 class="h3">Error in #function_called#:</h2>
				<div>#error_message#</div>
			</cfoutput>
		</cfcatch>
		</cftry>
	</cfthread>
	<cfthread action="join" name="getAgentHtmlThread" />
	<cfreturn getAgentHtmlThread.output>
</cffunction>

<!------------------------------------->
<!--- 
  * method addSubLoanToLoan given two transaction ids add one transaction as the subloan of another. 
  * @param transaction_id the parent transaction
  * @param subloan_transaction_id the child transaction
--->
<cffunction name="addSubLoanToLoan" access="remote">
	<cfargument name="transaction_id" type="string" required="yes">
	<cfargument name="subloan_transaction_id" type="string" required="yes">

	<cftry>
		<cfquery name="addChildLoan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			insert into loan_relations 
				(transaction_id, related_transaction_id, relation_type)
			values (
				<cfqueryparam value = "#transaction_id#" CFSQLType="CF_SQL_DECIMAL">,
				<cfqueryparam value = "#subloan_transaction_id#" CFSQLType="CF_SQL_DECIMAL">,
				'Subloan'
			)
		</cfquery>
		<cfquery name="childLoans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select l.loan_number, l.transaction_id 
			from loan_relations lr left join loan l on lr.related_transaction_id = l.transaction_id
			where lr.transaction_id = <cfqueryparam value = "#transaction_id#" CFSQLType="CF_SQL_DECIMAL">
			order by l.loan_number
		</cfquery>
	<cfcatch>
		<cfset error_message = cfcatchToErrorMessage(cfcatch)>
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn childLoans>
</cffunction>

<!--- 
  * method removeTransAgent given a trans_agent_id remove a trans_agent record linking
  *  a transaction to an agent in a role in that transaction.
  * @param trans_agent_id the trans_agent row to remove.
--->
<cffunction name="removeTransAgent" access="remote">
	<cfargument name="trans_agent_id" type="string" required="yes">

	<cftry>
		<cfquery name="delete" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="deleteResult">
			delete from trans_agent 
			where trans_agent_id = <cfqueryparam value = "#trans_agent_id#" CFSQLType="CF_SQL_DECIMAL"> 
		</cfquery>
		<cfif deleteResult.recordcount eq 0>
			<cfset theResult = queryNew("status, message")>
			<cfset t = queryaddrow(theResult,1)>
			<cfset t = QuerySetCell(theResult, "status", "0", 1)>
			<cfset t = QuerySetCell(theResult, "message", "No records deleted. #trans_agent_id# #deleteResult.sql#", 1)>
		</cfif>
		<cfif deleteResult.recordcount eq 1>
			<cfset theResult=queryNew("status, message")>
			<cfset t = queryaddrow(theResult,1)>
			<cfset t = QuerySetCell(theResult, "status", "1", 1)>
			<cfset t = QuerySetCell(theResult, "message", "Record deleted.", 1)>
		</cfif>
		<cfif deleteResult.recordcount GT 1>
			<cfthrow message="More than one (#deleteResult.recordcount#) deleted.">
		</cfif>
	<cfcatch>
		<cfset error_message = cfcatchToErrorMessage(cfcatch)>
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn theResult>
</cffunction>

<!--- 
  * method removeSubLoan given two transaction ids remove one as the child of the other
  * @param transaction_id the parent transaction
  * @param subloan_transaction_id the child transaction to unlink from the parent
--->
<cffunction name="removeSubLoan" access="remote">
	<cfargument name="transaction_id" type="string" required="yes">
	<cfargument name="subloan_transaction_id" type="string" required="yes">

	<cfquery name="removeChildLoan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		delete from loan_relations
		where transaction_id = <cfqueryparam value = "#transaction_id#" CFSQLType="CF_SQL_DECIMAL"> and
		related_transaction_id = <cfqueryparam value = "#subloan_transaction_id#" CFSQLType="CF_SQL_DECIMAL"> and
		relation_type = 'Subloan'
	</cfquery>
	<cfquery name="childLoans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select l.loan_number, l.transaction_id from loan_relations lr left join loan l on lr.related_transaction_id = l.transaction_id
		where lr.transaction_id = <cfqueryparam value = "#transaction_id#" CFSQLType="CF_SQL_DECIMAL">
		order by l.loan_number
	</cfquery>
	<cfreturn childLoans>
</cffunction>

<!--- 
 ** method getProjectListHtml obtains an html block listing the projects related to a transaction 
 * 
 * @param transaction_id the id of the transaction for which to look up projects.
 * @return html to replace the html content of a div.
--->
<cffunction name="getProjectListHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="transaction_id" type="string" required="yes">

	<cfthread name="getProjectListThread">
		<cftry>
			<cfquery name="projs" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select project_name, project.project_id, 
					project_trans_remarks,
					to_char(start_date,'YYYY-MM-DD') as start_date,
					to_char(end_date,'YYYY-MM-DD') as end_date
				from project_trans left join project on project_trans.project_id =  project.project_id
				where
					transaction_id= <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
			</cfquery>
			<cfoutput>
			
					<cfif projs.recordcount gt 0>
						<ul class="pl-4 pr-0 list-style-disc">
						<cfloop query="projs">
							<li class="my-1">
								<a href="/Project.cfm?Action=editProject&project_id=#project_id#" target="_blank"><strong>#project_name#</strong></a> 
								(#start_date#/#end_date#) #project_trans_remarks#
								<a class='btn btn-xs btn-warning' onClick='  confirmDialog("Remove this project from this transaction?", "Confirm Unlink Project", function() { removeProjectFromTrans(#project_id#,#transaction_id#); } ); '>Remove</a>
							</li>
						</cfloop>
						</ul>
					<cfelse>
						<p class="mt-2">None</p>
					</cfif>
			</cfoutput>
		<cfcatch>
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfoutput>
				<h2 class="h3">Error in #function_called#:</h2>
				<div>#error_message#</div>
			</cfoutput>
		</cfcatch>
		</cftry>
	</cfthread>
	<cfthread action="join" name="getProjectListThread" />
	<cfreturn getProjectListThread.output>
</cffunction>

<!--- 
 ** method getlinkProjectDialogHtml obtains the html content for a dialog to pick a project to add to a transaction.
 * 
 * @param transaction_id the id of the transaction to which to add selected projects
 * @return html to populate a dialog
--->
<cffunction name="getLinkProjectDialogHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="transaction_id" type="string" required="yes">

	<cfthread name="linkProjectDialogThread">
		<cftry>
			<cfquery name="lookupTrans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select transaction_type, specific_number
				from transaction_view
				where
					transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
			</cfquery>
			<cfoutput>
				<div class="container-fluid">
					<div class="row">
						<div class="col-12">
				<form id="project_picker_form">
					<label for="pick_project_name">Pick a Project to associate with <br><strong>#lookupTrans.transaction_type# #lookupTrans.specific_number#</strong> (%% lists all projects)</label>
					<input type="hidden" name="pick_project_id" id="pick_project_id" value="">
					<input type="text" name="pick_project_name" id="pick_project_name" class="data-entry-input mb-2 reqdClr" >
					<label for="project_trans_remarks">Project-Transaction Remarks</label>
					<input type="text" name="project_trans_remarks" id="project_trans_remarks" class="data-entry-input mb-2" >
					<script>
						$(document).ready( makeProjectPicker('pick_project_name','pick_project_id') );
						function saveProjectLink() {
							var id = $('##pick_project_id').val();
							var remarks = $('##project_trans_remarks').val();
							if (id) { 
								jQuery.getJSON("/transactions/component/functions.cfc",
									{
										method : "linkProjectToTransaction",
										project_id : id,
										transaction_id : #transaction_id#,
										project_trans_remarks: remarks,
										returnformat : "json",
										queryformat : 'column'
									},
									function (result) {
										if (result.DATA.STATUS[0]=='1') { 
											$('##project_picker_form').html('Relationship to project saved.');
										} else {
											messageDialog('Error linking project to transaction record: '+result.DATA.MESSAGE[0], 'Error saving project-transaction relation.');
										}
									}
								).fail(function(jqXHR,textStatus,error){
									var message = "";
									if (error == 'timeout') {
										message = ' Server took too long to respond.';
									} else if (error && error.toString().startsWith('Syntax Error: "JSON.parse:')) {
										message = ' Backing method did not return JSON.';
									} else {
										message = jqXHR.responseText;
									}
									if (!error) { error = ""; } 
									messageDialog('Error linking project to transaction record: '+message, 'Error: '+error.substring(0,50));
								});
							} else { 
								messageDialog('You must pick a project from the picklist)','Error: No project picked to link');
							}
						};
					</script>
					<button type="button" class="btn btn-xs btn-primary" onClick="saveProjectLink();">Save</button>
				</form>
						</div>
					</div>
				</div>
			</cfoutput>
		<cfcatch>
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfoutput>
				<h2 class="h3">Error in #function_called#:</h2>
				<div>#error_message#</div>
			</cfoutput>
		</cfcatch>
		</cftry>
	</cfthread>
	<cfthread action="join" name="linkProjectDialogThread" />
	<cfreturn linkProjectDialogThread.output>
</cffunction>


<!--- 
 ** method getlinkProjectDialogHtml obtains the html content for a dialog to create a project to add to a transaction.
 * 
 * @param transaction_id the id of the transaction to which to add the new project
 * @return html to populate a dialog 
--->
<cffunction name="getAddProjectDialogHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="transaction_id" type="string" required="yes">

	<cfthread name="getProjectDialogThread">
		<cftry>
			<cfquery name="lookupTrans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select transaction_type, specific_number, trans_date, trans_remarks
				from transaction_view
				where
					transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
			</cfquery>
			<cfoutput>
				<div class="container-fluid">
					<div class="row">
						<div class="col-12">
						<h1 class="h4" for="create_project">Create a New Project linked to <br><strong>#lookupTrans.transaction_type# #lookupTrans.specific_number#</strong></h1>
						<form id="create_project">
					<input type="hidden" name="transaction_id" value="#transaction_id#">
					<input type="hidden" name="method" value="createProjectLinkToTrans">
					<input type="hidden" name="returnformat" value="json">
					<input type="hidden" name="queryformat" value="column">
					<div class="form-row mt-2">
						<div class="col-12 px-0">
							<span class="my-1 data-entry-label">
								<label for="newAgent_name">Project Agent Name</label>
								<span id="newAgentViewLink" class="px-2">&nbsp;</span>
							</span>
							<div class="input-group">
								<div class="input-group-prepend">
									<span class="input-group-text smaller" id="project_agent_icon"><i class="fa fa-user" aria-hidden="true"></i></span> 
								</div>
								<input type="text" name="newAgent_name" id="newAgent_name" required class="form-control form-control-sm data-entry-input reqdClr" value="">
							</div>
							<input type="hidden" name="newAgent_name_id" id="newAgent_name_id" value=""
								onchange=" updateAgentLink($('##newAgent_name_id').val(),'newAgentViewLink'); ">
							<script>
								$(document).ready(function() {
									$(makeRichTransAgentPicker('newAgent_name','newAgent_name_id','project_agent_icon','newAgentViewLink',null)); 
								});
							</script>
						</div>
					</div>
					<div class="form-row mt-2">
						<div class="col-12 px-0">
							<cfquery name="ctProjAgRole" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
								select project_agent_role from ctproject_agent_role order by project_agent_role
							</cfquery>
							<label for="project_agent_role" class="data-entry-label">Project Agent Role</label>
							<select name="project_agent_role" id="project_agent_role" size="1" class="reqdClr data-entry-select" required>
								<option value=""></option>
								<cfloop query="ctProjAgRole">
								<option value="#ctProjAgRole.project_agent_role#">#ctProjAgRole.project_agent_role#</option>
								</cfloop>
							</select>
						</div>
					</div>
					<div class="form-row mt-2">
						<div class="col-6 px-0">
							<label for="start_date" class="data-entry-label">Project Start Date</label>
							<input type="text" name="start_date" id="start_date" value="#dateformat(lookupTrans.trans_date,"yyyy-mm-dd")#" class="data-entry-input">
						</div>
						<div class="col-6 px-0">
							<label for="end_date" class="data-entry-label">Project End Date</label>
							<input type="text" name="end_date" id="end_date" class="data-entry-input">
						</div>
					</div>
					<div class="form-row mt-2">
						<div class="col-12 px-0">
							<label for="project_name" class="data-entry-label">Project Title</label>
							<textarea name="project_name" id="project_name" cols="50" rows="2" class="reqdClr form-control autogrow" required></textarea>
						</div>
					</div>
					<div class="form-row mt-2">
						<div class="col-12 px-0">
							<label for="project_description" class="data-entry-label">Project Description</label>
							<textarea name="project_description" id="project_description" class="form-control autogrow"
								id="project_description" cols="50" rows="2"></textarea>
						</div>
					</div>
					<div class="form-row mt-2">
						<div class="col-12 px-0">
							<label for="project_remarks" class="data-entry-label">Project Remarks</label>
							<textarea name="project_remarks" id="project_remarks" cols="50" rows="2" class="form-control autogrow">#lookupTrans.trans_remarks#</textarea>
						</div>
					</div>
					<div class="form-row mt-2">
						<div class="col-12 px-0">
							<label for="project_trans_remarks" class="data-entry-label">Project-Transaction Remarks</label>
							<textarea name="project_trans_remarks" id="project_trans_remarks" cols="50" rows="2" class="form-control autogrow"></textarea>
						</div>
					</div>
					<div class="form-row mt-2">
						<div class="col-12 px-0">
						<div class="form-group mt-2">
							<input type="button" value="Create Project" aria-label="Create Project" class="btn btn-xs btn-primary"
								onClick="if (checkFormValidity($('##create_project')[0])) { createProject();  } ">
						</div>
						</div>
					</div>
					<script>
						$(document).ready(function() { 
							$("textarea.autogrow").keyup(autogrow);  
							$('textarea.autogrow').keyup();
						});
						function createProject(){
							$.ajax({
								url : "/transactions/component/functions.cfc",
								type : "post",
								dataType : "json",
								data: $("##create_project").serialize(),
								success: function (result) {
									if (result.DATA.STATUS[0]=='1') { 
										$('##create_project').html('New project saved. ['+result.DATA.ID[0]+']');
									} else {
										messageDialog('Error creating project to link to transaction record: '+result.DATA.MESSAGE[0], 'Error saving project-transaction relation.');
									}
								},
								error: function(jqXHR,textStatus,error){
									handleFail(jqXHR,textStatus,error,"creating project to link to transaction record");
								}
							});
						};
					</script>
				</form>
						</div>
					</div>
			
			</cfoutput>
		<cfcatch>
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfoutput>
				<h2 class="h3">Error in #function_called#:</h2>
				<div>#error_message#</div>
			</cfoutput>
		</cfcatch>
		</cftry>
	</cfthread>
	<cfthread action="join" name="getProjectDialogThread" />
	<cfreturn getProjectDialogThread.output>
</cffunction>

<!--- 
 ** method removeMediaFromTransaction unlink a media record from a transaction.
 *
 * @param transaction_id the transaction id that is the related_primary_key of the media_relations record to delate.
 * @parem media_id the media id of the media_relations record to delete
 * @param media_relationship the media relationship of the media_relations record to delete.
--->
<cffunction name="removeMediaFromTransaction" returntype="any" access="remote" returnformat="json">
	<cfargument name="transaction_id" type="string" required="yes">
	<cfargument name="media_id" type="string" required="yes">
	<cfargument name="media_relationship" type="string" required="yes">
	<cfset r=1>
	<cftry>
		<cfquery name="delete" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="deleteResult">
			delete from media_relations
			where related_primary_key =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
				and media_id =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
				and media_relationship=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#media_relationship#">
		</cfquery>
		<cfif deleteResult.recordcount eq 0>
			<cfset theResult=queryNew("status, message")>
			<cfset t = queryaddrow(theResult,1)>
			<cfset t = QuerySetCell(theResult, "status", "0", 1)>
			<cfset t = QuerySetCell(theResult, "message", "No records deleted. #media_id# #media_relationship# #transaction_id# #deleteResult.sql#", 1)>
		</cfif>
		<cfif deleteResult.recordcount eq 1>
			<cfset theResult=queryNew("status, message")>
			<cfset t = queryaddrow(theResult,1)>
			<cfset t = QuerySetCell(theResult, "status", "1", 1)>
			<cfset t = QuerySetCell(theResult, "message", "Record deleted.", 1)>
		</cfif>
		<cfif deleteResult.recordcount GT 1>
			<cfthrow message="More than one (#deleteResult.recordcount#) deleted.">
		</cfif>
	<cfcatch>
		<cfset error_message = cfcatchToErrorMessage(cfcatch)>
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfif isDefined("asTable") AND asTable eq "true">
		<cfreturn resulthtml>
	<cfelse>
		<cfreturn theResult>
	</cfif>
</cffunction>

<!--- 
 ** method linkProjectToTransaction unlink a media record from a transaction.
 *
 * @param transaction_id the transaction id that is the related_primary_key of the media_relations record to delate.
 * @parem media_id the media id of the media_relations record to delete
 * @param media_relationship the media relationship of the media_relations record to delete.
--->
<cffunction name="linkProjectToTransaction" returntype="any" access="remote" returnformat="json">
	<cfargument name="transaction_id" type="string" required="yes">
	<cfargument name="project_id" type="string" required="yes">
	<cfargument name="project_trans_remarks" type="string" required="no">
	<cfset r=1>
	<cftry>
		<cfquery name="add" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="add_result">
			insert into project_trans (
				transaction_id
				,project_id
				<cfif isDefined("project_trans_remarks") AND len(project_trans_remarks) GT 0>
					,project_trans_remarks
				</cfif>
			) values (
				<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
			 	,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#project_id#">
				<cfif isDefined("project_trans_remarks") AND len(project_trans_remarks) GT 0>
					,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#project_trans_remarks#">
				</cfif>
			)
		</cfquery>
		<cfif add_result.recordcount eq 0>
			<cfset theResult=queryNew("status, message")>
			<cfset t = queryaddrow(theResult,1)>
			<cfset t = QuerySetCell(theResult, "status", "0", 1)>
			<cfset t = QuerySetCell(theResult, "message", "No record added. #transaction_id# #project_id# #add.sql#", 1)>
		</cfif>
		<cfif add_result.recordcount eq 1>
			<cfset theResult=queryNew("status, message")>
			<cfset t = queryaddrow(theResult,1)>
			<cfset t = QuerySetCell(theResult, "status", "1", 1)>
			<cfset t = QuerySetCell(theResult, "message", "Record Added.", 1)>
		</cfif>
	<cfcatch>
		<cfset error_message = cfcatchToErrorMessage(cfcatch)>
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn theResult>
</cffunction>


<cffunction name="createProjectLinkToTrans" returntype="any" access="remote" returnformat="json">
	<cfargument name="transaction_id" type="string" required="yes">
	<cfargument name="project_name" type="string" required="yes">
	<cfargument name="start_date" type="string" required="no">
	<cfargument name="end_date" type="string" required="no">
	<cfargument name="project_description" type="string" required="no">
	<cfargument name="project_remarks" type="string" required="no">
	<cfargument name="newAgent_name_id" type="string" required="yes">
	<cfargument name="project_agent_role" type="string" required="yes">
	<cfargument name="project_trans_remarks" type="string" required="no">
	<cfset r=1>
	<cftransaction>
		<cftry>
			<cfquery name="newProjSeq" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select sq_project_id.nextval as id from dual
			</cfquery>
			<cfset project_id_new = newProjSeq.id>
			<cfquery name="newProj" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				INSERT INTO project (
					PROJECT_ID
					,PROJECT_NAME
					<cfif len(#START_DATE#) gt 0>
						,START_DATE
					</cfif>
					<cfif len(#END_DATE#) gt 0>
						,END_DATE
					</cfif>
					<cfif len(#PROJECT_DESCRIPTION#) gt 0>
						,PROJECT_DESCRIPTION
					</cfif>
					<cfif len(#PROJECT_REMARKS#) gt 0>
						,PROJECT_REMARKS
					</cfif>
				)
				VALUES 
				(
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#project_id_new#">
					,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#PROJECT_NAME#">
					<cfif len(#START_DATE#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_TIMESTAMP" value="#dateformat(START_DATE,"yyyy-mm-dd")#">
					</cfif>
					<cfif len(#END_DATE#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_TIMESTAMP" value="#dateformat(END_DATE,"yyyy-mm-dd")#">
					</cfif>
					<cfif len(#PROJECT_DESCRIPTION#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#PROJECT_DESCRIPTION#">
					</cfif>
					<cfif len(#PROJECT_REMARKS#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#PROJECT_REMARKS#">
					</cfif>
				)
			</cfquery>
			<cfquery name="newProjAgnt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				INSERT INTO project_agent (
					PROJECT_ID,
					AGENT_NAME_ID,
					PROJECT_AGENT_ROLE,
					AGENT_POSITION )
				VALUES (
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#project_id_new#">
					,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#newAgent_name_id#">
					,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#project_agent_role#">
					,1 )
			</cfquery>
			<cfquery name="newTrans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				INSERT INTO project_trans (
					project_id
					, transaction_id
					<cfif isDefined("project_trans_remarks") AND len(project_trans_remarks) GT 0>
						,project_trans_remarks
					</cfif>
				) 
				values (
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#project_id_new#">
					,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
					<cfif isDefined("project_trans_remarks") AND len(project_trans_remarks) GT 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#project_trans_remarks#">
					</cfif>
				)
			</cfquery>
			<cfset data=queryNew("status, message, id")>
			<cfset t = queryaddrow(data,1)>
			<cfset t = QuerySetCell(data, "status", "1", 1)>
			<cfset t = QuerySetCell(data, "message", "Record Added.", 1)>
			<cfset t = QuerySetCell(data, "id", "#project_id_new#", 1)>
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
	<cfreturn #data#>
</cffunction>

<!--- 
 ** method removeProjectFromTransaction unlink a project record from a transaction (weak entity, 
 *  primary key comprised of foreign keys transaction_id and project_id.
 *
 * @param transaction_id the transaction id of the project_trans record to delate.
 * @parem project_id the project id of the project_trans record to delete
--->
<cffunction name="removeProjectFromTransaction" returntype="any" access="remote" returnformat="json">
	<cfargument name="transaction_id" type="string" required="yes">
	<cfargument name="project_id" type="string" required="yes">
	<cfset r=1>
	<cftry>
		<cfquery name="delete" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="deleteResult">
			delete from project_trans
			where transaction_id =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
				and project_id =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#project_id#">
		</cfquery>
		<cfif deleteResult.recordcount eq 0>
			<cfset theResult=queryNew("status, message")>
			<cfset t = queryaddrow(theResult,1)>
			<cfset t = QuerySetCell(theResult, "status", "0", 1)>
			<cfset t = QuerySetCell(theResult, "message", "No records deleted. #project_id# #transaction_id# #deleteResult.sql#", 1)>
		</cfif>
		<cfif deleteResult.recordcount eq 1>
			<cfset theResult=queryNew("status, message")>
			<cfset t = queryaddrow(theResult,1)>
			<cfset t = QuerySetCell(theResult, "status", "1", 1)>
			<cfset t = QuerySetCell(theResult, "message", "Record deleted.", 1)>
		</cfif>
	<cfcatch>
		<cfset error_message = cfcatchToErrorMessage(cfcatch)>
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfif isDefined("asTable") AND asTable eq "true">
		<cfreturn resulthtml>
	<cfelse>
		<cfreturn theResult>
	</cfif>
</cffunction>



<!--- 
  ** obtain an html block for picking addresses for a shipment using an address text control and address_id control 
  *  with a specified dialog.
  *
 --->
<cffunction name="getAddressPickerHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="valuecontrol" type="string" required="yes">
	<cfargument name="idcontrol" type="string" required="yes">
	<cfargument name="dialog" type="string" required="yes">
	<cfargument name="transaction_id" type="string" required="yes">

	<cfthread name="getAddressPickerThread">

	<cftry>
		<cfquery name="lookupTrans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" timeout="#Application.short_timeout#">
			select transaction_type, specific_number, trans_date, trans_remarks
			from transaction_view
			where
				transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
		</cfquery>
		<cfif lookupTrans.transaction_type EQ "accn"> 
			<!--- Temporary addresses for agents can be created for accessions, where an agent working at the MCZ is shipping from a temporary address on an expedition --->
			<cfset includeTemporary = "true">
		<cfelse>
			<cfset includeTemporary = "">
		</cfif>
		<cfoutput>
			<h1 class="h3">Search for Addresses</h1>
   		<form id="findAddressSearchForm" name="findAddress" class="mb-4">
				<input type="hidden" name="method" value="getAddressesJSON" class="keeponclear">
				<input type="hidden" name="include_temporary" value="#includeTemporary#" class="keeponclear">


				<div class="row col-12">
					<div class="col-12 col-md-4 mt-1">
						<span class="my-1 data-entry-label">
							<label for="shipment_agent_name">Agent Name</label>
							<span id="shipment_agent_view_link" class="px-2 infoLink">&nbsp;</span>
						</span>
						<div class="input-group">
							<div class="input-group-prepend">
								<span class="input-group-text smaller bg-light" id="shipment_agent_icon"><i class="fa fa-user" aria-hidden="true"></i></span> 
							</div>
							<input type="text" name="shipment_agent_name" id="shipment_agent_name" class="form-control form-control-sm data-entry-input" value="">
						</div>
						<input type="hidden" name="shipment_agent_id" id="shipment_agent_id" value=""
							onchange=" updateAgentLink($('##shipment_agent_id').val(),'shipment_agent_view_link'); ">
						<script>
							$(document).ready(function() {
								$(makeRichTransAgentPicker('shipment_agent_name','shipment_agent_id','shipment_agent_icon','shipment_agent_view_link',null)); 
							});
						</script>
					</div>
					<div class="col-12 col-md-4 mt-1">
						<label for="formatted_address" class="data-entry-label">Address</label>
						<input type="text" name="formatted_address" id="search_formatted_address" value="" class="form-control data-entry-input">
					</div>
					<div class="col-12 col-md-4 mt-0 mt-md-1">
						<label for="searchButton" class="data-entry-label invisible">search for shipping addresses</label>
						<button class="btn btn-xs btn-primary px-3" id="searchButton"
							type="submit">Search<span class="fa fa-search pl-1"></span></button>
						<cfif includeTemporary EQ "true">
							<script>
								function addTempAddrCallback() { 
									$('##findAddressSearchForm').submit();			
								}
							</script>
							<button type="button" class="btn btn-xs ml-1 btn-secondary" id="addTempAddressButton"
								onclick="addTemporaryAddressForAgent('shipment_agent_id','shipment_agent_id','search_formatted_address','#transaction_id#',addTempAddrCallback); " 
								aria-label="Create a temporary address" 
								style="display: none;"
								value="Create Temporary Address">Create Temporary Address</button>
							<!--- note, make sure classes added to either of addTempAddressButton or addTempAddressLabel don't override display:none --->
							<span id="addTempAddressLabel">Select agent to add temporary address.</span>
							<div id="tempAddressDialog"></div>
							<script>
								function updateOfShipmentAgentID() { 
									if ($('##shipment_agent_id').val().length > 0 ) { 
										$('##addTempAddressButton').show();
										$('##addTempAddressLabel').hide();
									} else { 
										$('##addTempAddressButton').hide();
										$('##addTempAddressLabel').show();
									}
								}
								$('##shipment_agent_view_link').bind('DOMSubtreeModified', function(){
									updateOfShipmentAgentID();
								})
							</script>
						</cfif>
					</div>
				</div>
			</form>
<div class="container-fluid">
	<div class="row">
		<div class="col-12">
			<div class="row mt-1 mb-0 pb-0 jqx-widget-header border px-2">
				<h4>Results: </h4>
				<div class="px-3 p-2" id="addressPickResultCount"></div> 
				<div id="addressPickResultLink" class="p-2"></div>
			</div>
			<div class="row mt-0">
				<div id="addressPickSearchText"></div>
				<div id="addressPickResultsGrid" class="jqxGrid"></div>
				<div id="enableselection"></div>
			</div>
			<script>
				$("##findAddressSearchForm").bind("submit", function(evt){
					evt.preventDefault();
					$("##addressPickResultsGrid").replaceWith('<div id="addressPickResultsGrid" class="jqxGrid"></div>');
					$("##addressPickResultCount").html("");
					$("##addressPickResultLink").html("");
					$("##addressPickSearchText").jqxGrid("showloadelement");

					var addressSearch = {
						datatype: "json",
						datafields: [
							{ name: "addr_id", type: "string" },
							{ name: "agent_name", type: "string" },
							{ name: "agent_id", type: "string" },
							{ name: "formatted_addr", type: "string" },
							{ name: "valid_addr_fg", type: "string" },
							{ name: "addr_type", type: "string" }
						],
						root: "addressRecord",
						id: "address_id",
						url: "/transactions/component/functions.cfc?" + $("##findAddressSearchForm").serialize()
					};

					var dataAdapter = new $.jqx.dataAdapter(addressSearch);

					// TODO: Implement agentcellrenderer, bind to agent id to create view link for agent

					var linkcellrenderer = function (index, datafield, value, defaultvalue, column, rowdata) { 
						var pvalue = rowdata.formatted_addr;
						var result = "<button class=\"btn btn-xs btn-outline-primary mx-2 mt-1\" onclick=\" $('###idcontrol#').val( '" + value + "'); $('###valuecontrol#').val('" + pvalue + "'); $('###dialog#').dialog('close'); \">Select</button>";
						return result;
					};
					var addrcellrenderer = function (index, datafield, value, defaultvalue, column, rowdata) { 
						var lines = (rowdata.formatted_addr.match(/\\n/g) || []).length;
						if (lines==0) { lines = 2; }
						var pvalue = rowdata.formatted_addr.replaceAll('\\n','<br>');
						var result = "<div style='height: " + lines*1.05 + "rem;' class='p-1' >" + pvalue + "</div>";
						return result;
					};


					$("##addressPickResultsGrid").jqxGrid({
						width: "100%",
						autoheight: "true",
						autorowheight: "true",
						source: dataAdapter,
						filterable: true,
						sortable: true,
						pageable: true,
						editable: false,
						pagesize: "5",
						pagesizeoptions: ["5","50","100"],
						showaggregates: false,
						columnsresize: true,
						autoshowfiltericon: true,
						autoshowcolumnsmenubutton: false,
						columnsreorder: true,
						groupable: false,
						selectionmode: 'singlerow',  // small pick grid, selection mode singlerow
						altrows: true,
						showtoolbar: false,
						ready: function () {
							$("##addressPickResultsGrid").jqxGrid('selectrow', 0);
						},
						columns: [
							{text: "Select", datafield: "addr_id", width: 100, hideable: false, hidden: false, cellsrenderer: linkcellrenderer }, 
							{text: "Agent", datafield: "agent_name", width: 150, hideable: true, hidden: false }, 
							{text: "agent_id", datafield: "agent_id", width: 50, hideable: true, hidden: true }, 
							{text: "Valid", datafield: "valid_addr_fg", width: 80, hideable: true, hidden: false },
							{text: "Type", datafield: "addr_type", width: 150, hideable: true, hidden: false },
							{text: "Address", datafield: "formatted_addr", hideable: true, hidden: false, cellsrenderer: addrcellrenderer }
						]
					});
				});
			</script>
		</div>
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
	<cfthread action="join" name="getAddressPickerThread" />
	<cfreturn getAddressPickerThread.output>
</cffunction>


<cffunction name="getAddressesJSON" access="remote" returntype="any" returnformat="json">
	<cfargument name="shipment_agent_id" type="string" required="no">
	<cfargument name="formatted_address" type="string" required="no">
	<cfargument name="include_temporary" type="string" required="no">
	<cfif isdefined("include_temporary") and #include_temporary# IS "true">
		<cfset showTemp = TRUE>
	<cfelse>
		<cfset showTemp = FALSE>
	</cfif>

	<cfset data = ArrayNew(1)>
	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result" timeout="#Application.query_timeout#">
			SELECT agent_name, preferred_agent_name.agent_id, formatted_addr, addr_id,VALID_ADDR_FG, addr_type
			FROM preferred_agent_name left join addr on preferred_agent_name.agent_id = addr.agent_id
			WHERE
				formatted_addr is not null
			<cfif showTemp EQ FALSE >
				AND addr_type <> 'temporary'
			</cfif >
			<cfif isdefined("shipment_agent_id") AND len(shipment_agent_id) gt 0>
				AND addr.agent_id = <cfqueryparam value="#shipment_agent_id#" cfsqltype="CF_SQL_DECIMAL">
			<cfelseif isdefined("formatted_address") AND len(formatted_address) gt 0>
				AND upper(formatted_addr) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(formatted_address)#%" >
			</cfif>
			ORDER BY valid_addr_fg desc, agent_name asc
		</cfquery>
		<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfset row["agent_name"] = "#search.agent_name#">
			<cfset row["agent_id"] = "#search.agent_id#">
			<!--- Note: JSStringFormat is needed to escape \n characters in the formatted_addr before calling serializeJSON,
 				but this ends up with " characters being double escaped and breaking javascript downstream, so 
				working around this by replacing " with ' in the json.  This is not a general solution but a workaround
				for this particular setting.  See BugID: 5464. --->
			<cfset row["formatted_addr"] = "#JSStringFormat(replace(search.formatted_addr,'"',"'","all"))#">
			<cfset row["addr_id"] = "#search.addr_id#">
			<cfset row["valid_addr_fg"] = "#search.valid_addr_fg#">
			<cfset row["addr_type"] = "#search.addr_type#">
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

<!---
   Function to create or save a shipment from a ajax post
   @param shipment_id the shipment_id of the shipment to save, if null, then create a new shipment.
   @param transaction_id the transaction with which this shipment is associated.
   @return json query structure with STATUS = 0|1 and MESSAGE, status = 0 on a failure.
 --->
<cffunction name="saveShipment" returntype="query" access="remote">
   <cfargument name="shipment_id" required="no">
   <cfargument name="transaction_id" type="numeric" required="yes">
   <cfargument name="packed_by_agent_id" type="numeric" required="no">
   <cfargument name="shipped_carrier_method" type="string" required="no">
   <cfargument name="carriers_tracking_number" type="string" required="no">
   <cfargument name="shipped_date" type="string" required="no">
   <cfargument name="package_weight" type="string" required="no">
   <cfargument name="no_of_packages" type="string" required="no">
   <cfargument name="hazmat_fg" type="numeric" required="no">
   <cfargument name="insured_for_insured_value" type="string" required="no">
   <cfargument name="shipment_remarks" type="string" required="no">
   <cfargument name="contents" type="string" required="no">
   <cfargument name="foreign_shipment_fg" type="numeric" required="no">
   <cfargument name="shipped_to_addr_id" type="string" required="no">
   <cfargument name="shipped_from_addr_id" type="string" required="no">
   <cfset theResult=queryNew("status, message")>
   <cftry>
      <cfset debug = shipment_id >
      <!---  Try to obtain a numeric value for no_of_packages, if this fails, set no_of_packages to empty string to not include --->
      <cfset noofpackages = val(#no_of_packages#) >
      <cfif noofpackages EQ 0>
          <cfset no_of_packages = "">
      </cfif>
      <cfif NOT IsDefined("shipment_id") OR shipment_id EQ "">
         <!---  Determine how many shipments there are in this transaction, if none, set the print_flag on the new shipment --->
         <cfquery name="countShipments" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
             select count(*) ct from shipment
                where transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
         </cfquery>
         <cfif countShipments.ct EQ 0>
             <cfset printFlag = 1>
         <cfelse>
             <cfset printFlag = 0>
         </cfif>
         <cfset debug = shipment_id & "Insert" >
         <cfquery name="query" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
             insert into shipment (
                transaction_id, packed_by_agent_id, shipped_carrier_method, carriers_tracking_number, shipped_date, package_weight,
                <cfif isdefined("no_of_packages") and len(#no_of_packages#) gt 0>
                  no_of_packages,
                </cfif>
                <cfif isdefined("insured_for_insured_value") and len(#insured_for_insured_value#) gt 0>
                  insured_for_insured_value,
                </cfif>
                hazmat_fg, shipment_remarks, contents, foreign_shipment_fg,
                shipped_to_addr_id, shipped_from_addr_id,
                print_flag
             )
             values (
                <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">,
                <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#packed_by_agent_id#">,
                <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#shipped_carrier_method#">,
                <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#carriers_tracking_number#">,
                <cfqueryparam cfsqltype="CF_SQL_DATE" value="#shipped_date#">,
                <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#package_weight#">,
                <cfif isdefined("no_of_packages") and len(#no_of_packages#) gt 0>
                   <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#noofpackages#">,
                </cfif>
                <cfif isdefined("insured_for_insured_value") and len(#insured_for_insured_value#) gt 0>
                   <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#insured_for_insured_value#" null="yes">,
                </cfif>
                <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#hazmat_fg#">,
                <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#shipment_remarks#">,
                <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#contents#">,
                <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#foreign_shipment_fg#">,
                <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#shipped_to_addr_id#">,
                <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#shipped_from_addr_id#">,
                <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#printFlag#">
             )
         </cfquery>
      <cfelse>
         <cfset debug = shipment_id & "Update" >
         <cfquery name="query" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
             update shipment set
                packed_by_agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#packed_by_agent_id#">,
                shipped_carrier_method = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#shipped_carrier_method#">,
                carriers_tracking_number = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#carriers_tracking_number#">,
                shipped_date = <cfqueryparam cfsqltype="CF_SQL_DATE" value="#shipped_date#">,
                package_weight = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#package_weight#">,
                <cfif isdefined("no_of_packages") and len(#no_of_packages#) gt 0>
                   no_of_packages = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#noofpackages#" >,
                <cfelse>
                   no_of_packages = <cfqueryparam cfsqltype="CF_SQL_NULL" null="yes" value="" >,
                </cfif>
                <cfif isdefined("insured_for_insured_value") and len(#insured_for_insured_value#) gt 0>
                   insured_for_insured_value = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#insured_for_insured_value#">,
                </cfif>
                hazmat_fg = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#hazmat_fg#">,
                shipment_remarks = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#shipment_remarks#">,
                contents = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#contents#">,
                foreign_shipment_fg = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#foreign_shipment_fg#">,
                shipped_to_addr_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#shipped_to_addr_id#">,
                shipped_from_addr_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#shipped_from_addr_id#">
             where
                shipment_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#shipment_id#"> and
                transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
          </cfquery>
      </cfif>
      <cfset t = queryaddrow(theResult,1)>
      <cfset t = QuerySetCell(theResult, "status", "1", 1)>
      <cfset t = QuerySetCell(theResult, "message", "Saved.", 1)>
	<cfcatch>
		<cfset error_message = cfcatchToErrorMessage(cfcatch)>
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn theResult>
</cffunction>

<cffunction name="savePermit" access="remote" returntype="any" returnformat="json">
	<cfargument name="permit_id" type="string" required="yes">
	<cfargument name="issued_to_agent_id" type="string" required="yes">
	<cfargument name="issued_by_agent_id" type="string" required="yes">
	<cfargument name="specific_type" type="string" required="yes">
	<cfargument name="contact_agent_id" type="string" required="no">
	<cfargument name="issued_date" type="string" required="no">
	<cfargument name="renewed_date" type="string" required="no">
	<cfargument name="exp_date" type="string" required="no">
	<cfargument name="permit_num" type="string" required="no">
	<cfargument name="permit_title" type="string" required="no">
	<cfargument name="permit_remarks" type="string" required="no">
	<cfargument name="restriction_summary" type="string" required="no">
	<cfargument name="benefits_summary" type="string" required="no">
	<cfargument name="benefits_provided" type="string" required="no">

	<cfset data = ArrayNew(1)>
	<cftransaction>
		<cftry>
			<cfquery name="ptype" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select permit_type 
				from ctspecific_permit_type 
				where specific_type = <cfqueryparam CFSQLTYPE="CF_SQL_VARCHAR" value="#specific_type#">
			</cfquery>
			<cfset permit_type = #ptype.permit_type#>
			<cfoutput>
				<cfquery name="updatePermit" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					UPDATE permit SET
						permit_id = <cfqueryparam CFSQLTYPE="CF_SQL_DECIMAL" value="#permit_id#">
						,ISSUED_BY_AGENT_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#issued_by_agent_id#">
						,ISSUED_TO_AGENT_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#issued_to_agent_id#">
						,SPECIFIC_TYPE = <cfqueryparam CFSQLTYPE="CF_SQL_VARCHAR" value="#specific_type#">
						,PERMIT_TYPE = <cfqueryparam CFSQLTYPE="CF_SQL_VARCHAR" value="#permit_type#">
						<cfif isdefined("contact_agent_id") and len(#contact_agent_id#) gt 0>
							,contact_agent_id = <cfqueryparam cfsqltype="cf_sql_decimal" value="#contact_agent_id#">
						<cfelse>
							,contact_agent_id = null
						</cfif>
						<cfif isdefined("issued_date") AND len(#issued_date#) GT 0 >
							,ISSUED_DATE = <cfqueryparam cfsqltype="CF_SQL_TIMESTAMP" value="#issued_date#">
						<cfelse>
							,ISSUED_DATE = null
						</cfif>
						<cfif isdefined("renewed_date") and len(#renewed_date#) GT 0 >
							,RENEWED_DATE = <cfqueryparam cfsqltype="CF_SQL_TIMESTAMP" value="#renewed_date#">
						<cfelse>
							,RENEWED_DATE = null
						</cfif>
						<cfif isdefined("exp_date") and len(#exp_date#) GT 0>
							,EXP_DATE = <cfqueryparam cfsqltype="CF_SQL_TIMESTAMP" value="#exp_date#">
						<cfelse>
							,EXP_DATE = null
						</cfif>
						<cfif isdefined("PERMIT_NUM")>
							,PERMIT_NUM = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#permit_num#">
						</cfif>
						<cfif isdefined("PERMIT_TITLE")>
							,PERMIT_TITLE = <cfqueryparam CFSQLTYPE="CF_SQL_VARCHAR" value="#permit_title#">
						</cfif>
						<cfif isdefined("PERMIT_REMARKS")>
							,PERMIT_REMARKS = <cfqueryparam CFSQLTYPE="CF_SQL_VARCHAR" value="#permit_remarks#">
						</cfif>
						<cfif isdefined("restriction_summary")>
							,restriction_summary = <cfqueryparam CFSQLTYPE="CF_SQL_VARCHAR" value="#restriction_summary#">
						</cfif>
						<cfif isdefined("benefits_summary")>
							,benefits_summary = <cfqueryparam CFSQLTYPE="CF_SQL_VARCHAR" value="#benefits_summary#">
						</cfif>
						<cfif isdefined("benefits_provided")>
							,benefits_provided = <cfqueryparam CFSQLTYPE="CF_SQL_VARCHAR" value="#benefits_provided#">
						</cfif>
					where  permit_id =  <cfqueryparam cfsqltype="cf_sql_decimal" value="#permit_id#">
				</cfquery>
			</cfoutput>
			<cfset row = StructNew()>
			<cfset row["status"] = "saved">
			<cfset row["id"] = "#permit_id#">
			<cfset data[1] = row>
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
	<cfreturn #serializeJSON(data)#>
</cffunction>


<!----------------------------------------------------------------------------------------------------------------->
<!--- getPermitMediaHtml return a block of html listing media for a permission and rights document
  @param permit_id the primary key value to look up
  @param correspondence, if non-empty value is provided, show additional documentation rather than 
   media for the permit itself.
  @editable if false, then do not include the edit controls, if not specified, default is true.
--->
<cffunction name="getPermitMediaHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="permit_id" type="string" required="yes">
	<cfargument name="correspondence" type="string" required="no">
	<cfargument name="editable" type="string" required="no" default="true">

	<cfif isdefined("correspondence") and len(#correspondence#) gt 0>
		<cfset relation = "document for permit">
		<cfset heading = "Additional Documents">
	<cfelse>
		<cfset relation = "shows permit">
		<cfset heading = "The Document (copy of the actual permit)">
	</cfif>
	<cfset rel = left(relation,3)>
	
	<cfif not isDefined("editable") OR editable NEQ "false">
		<cfset variables.editable = "true">
	<cfelse>
		<cfset variables.editable = "false">
	</cfif>

	<cfthread name="getPermitMediaThread">
		<cftry>
			<cfquery name="permitInfo" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select permit.permit_id,
					issuedBy.agent_name as IssuedByAgent,
					issued_Date,
					permit_Num,
			 		permit_Type
				from
					permit,
					preferred_agent_name issuedBy
				where
					permit.issued_by_agent_id = issuedBy.agent_id (+)
					and permit_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#permit_id#">
			</cfquery>
			<cfquery name="query" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select distinct media.media_id as media_id, preview_uri, media.media_uri, media.mime_type, media.media_type as media_type,
					MCZBASE.is_media_encumbered(media.media_id) as hideMedia,
	  				MCZBASE.get_media_descriptor(media.media_id) as media_descriptor,
					label_value
				from media_relations left join media on media_relations.media_id = media.media_id
					left join media_labels on media.media_id = media_labels.media_id
				where media_relations.media_relationship = <cfqueryparam value="#relation#" CFSQLType="CF_SQL_VARCHAR">
					and (media_label = 'description' or media_label is null )
					and media_relations.related_primary_key = <cfqueryparam value="#permit_id#" CFSQLType="CF_SQL_DECIMAL">
			</cfquery>
			<cfoutput>
				<h2 class="h3">#heading# Media</h2>
				<cfif query.recordcount gt 0>
					<ul class="col-12 mx-0 pl-4 pr-0 list-style-disc">
					<cfloop query="query">
						<cfset puri=getMediaPreview(preview_uri,media_type) >
						<cfif puri EQ "/images/noThumb.jpg">
							<cfset altText = "Red X in a red square, with text, no preview image available">
						<cfelse>
							<cfset altText = query.media_descriptor>
						</cfif>
						<li class="my-1">
							<a href='#media_uri#' class="w-auto mr-2"><img src='#puri#' height='40' width='28' alt='#media_descriptor#'></a>
							<span class="d-inline">#mime_type#</span> | <span class="d-inline"> #media_type# </span> |  <span class="d-inline">#label_value#</span>
							<a href='/media/#media_id#' target='_blank'>Media Details</a>
							<cfif editable EQ "true">
								<input class='btn btn-xs btn-warning'
									onClick=' confirmDialog("Remove this media from this permit (#relation#)?", "Confirm Unlink Media", function() { deleteMediaFromPermit(#media_id#,#permit_id#,"#relation#"); } ); event.preventDefault(); ' 
									value='Remove' style='width: 5em; text-align: center; padding: .15em .25em;' >
							</cfif>
						</li>
					</cfloop>
					</ul>
				<cfelseif query.recordcount EQ 0 AND editable EQ "false">
					<ul class="col-12 mx-0 pl-4 pr-0 list-style-disc">
						<li class="my-1">None</li>
					</ul>
				</cfif>
				<span>
					<cfif editable EQ "true" AND (query.recordcount EQ 0 or relation IS 'document for permit')>
						<input type='button' onClick="opencreatemediadialog('addMediaDlg_#permit_id#_#rel#','permissions/rights document #permitInfo.permit_Type# - #jsescape(permitInfo.IssuedByAgent)# - #permitInfo.permit_Num#','#permit_id#','#relation#',reloadPermitMedia);" 
							value='Create Media' class='btn btn-xs btn-secondary'>&nbsp;
						<span id='addPermit_#permit_id#'>
							<input type='button' value='Link Media' class='btn btn-xs btn-secondary' 
								onClick="openlinkmediadialog('addPermitDlg_#permit_id#_#rel#','Pick Media for Permit #permitInfo.permit_Type# - #jsescape(permitInfo.IssuedByAgent)# - #permitInfo.permit_Num#','#permit_id#','#relation#',reloadPermitMedia); " >
						</span>
					</cfif>
				</span>
				<cfif editable EQ "true">
					<div id='addMediaDlg_#permit_id#_#rel#'></div>
					<div id='addPermitDlg_#permit_id#_#rel#'></div>
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
	<cfthread action="join" name="getPermitMediaThread" />
	<cfreturn getPermitMediaThread.output>
</cffunction>

<!----------------------------------------------------------------------------------------------------------------->
<cffunction name="removeMediaFromPermit" returntype="query" access="remote">
	 <cfargument name="permit_id" type="string" required="yes">
	 <cfargument name="media_id" type="string" required="yes">
	 <cfargument name="media_relationship" type="string" required="yes">
	 <cfset r=1>
	 <cftry>
	 	<cfquery name="delete" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="deleteResult">
			delete from media_relations
			where related_primary_key =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#permit_id#">
			and media_id =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">
			and media_relationship=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#media_relationship#">
		</cfquery>
		<cfif deleteResult.recordcount eq 0>
			<cfset theResult=queryNew("status, message")>
			<cfset t = queryaddrow(theResult,1)>
			<cfset t = QuerySetCell(theResult, "status", "0", 1)>
			<cfset t = QuerySetCell(theResult, "message", "No records deleted. #media_id# #media_relationship# #permit_id# #deleteResult.sql#", 1)>
		</cfif>
		<cfif deleteResult.recordcount eq 1>
			<cfset theResult=queryNew("status, message")>
			<cfset t = queryaddrow(theResult,1)>
			<cfset t = QuerySetCell(theResult, "status", "1", 1)>
			<cfset t = QuerySetCell(theResult, "message", "Record deleted.", 1)>
		</cfif>
	 <cfcatch>
		<cfset error_message = cfcatchToErrorMessage(cfcatch)>
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	 </cfcatch>
	 </cftry>
	 <cfreturn theResult>
</cffunction>


<cffunction name="getUseReportJSON" access="remote" returntype="any" returnformat="json">
	<cfargument name="permit_id" type="string" required="no">
	<cfset data = ArrayNew(1)>
	<cftry>
		<cfset rows = 0>
		<cfquery name="use" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="use_result" timeout="#Application.query_timeout#">
					select 'accession' as ontype, accn_number as tnumber, accn_type as ttype, trans.transaction_type, trans.trans_date, collection.guid_prefix,
						concat('/transactions/Accession.cfm?action=edit&transaction_id=',trans.transaction_id) as uri,
						locality.sovereign_nation,
						flat.country, flat.state_prov, flat.county, flat.island, flat.scientific_name, flat.guid,
						(case when flat.began_date > '1700-01-01' then 
     						 ( case when flat.began_date = flat.ended_date then flat.began_date else flat.began_date || '/' || flat.ended_date end)
    					else '' end) as eventDate,
						GET_TRANS_SOLE_SHIP_DATE(permit_trans.transaction_id) as shipped_date,
						'Museum of Comparative Zoology' as toinstitution, ' ' as frominstitution, flat.parts,
						decode(mczbase.concatcommonname(taxon_name_id),null,'none recorded',mczbase.concatcommonname(taxon_name_id)) as common_name
					from permit_trans left join trans on permit_trans.transaction_id = trans.transaction_id
						left join collection on trans.collection_id = collection.collection_id
						left join accn on trans.transaction_id = accn.transaction_id
						left join cataloged_item on accn.transaction_id = cataloged_item.accn_id
						left join flat on cataloged_item.collection_object_id = flat.collection_object_id
						left join locality on flat.locality_id = locality.locality_id
						left join taxonomy on flat.scientific_name = taxonomy.scientific_name
						where trans.transaction_type = 'accn'
							and permit_trans.permit_id = <cfqueryparam cfsqltype="cf_sql_decimal" value="#permit_id#">
					union
					select 'accession shipment' as ontype, accn_number as tnumber, accn_type as ttype, trans.transaction_type, trans.trans_date, collection.guid_prefix,
						concat('/transactions/Accession.cfm?action=edit&transaction_id=',trans.transaction_id) as uri,
						locality.sovereign_nation,
						flat.country, flat.state_prov, flat.county, flat.island, flat.scientific_name, flat.guid,
						(case when flat.began_date > '1700-01-01' then 
     						 ( case when flat.began_date = flat.ended_date then flat.began_date else flat.began_date || '/' || flat.ended_date end)
    					else '' end) as eventDate,
						shipped_date, toaddr.institution toinstitution, fromaddr.institution frominstitution, flat.parts,
						decode(mczbase.concatcommonname(taxon_name_id),null,'none recorded',mczbase.concatcommonname(taxon_name_id)) as common_name
					from permit_shipment left join shipment on permit_shipment.shipment_id = shipment.shipment_id
						left join addr toaddr on shipped_to_addr_id = toaddr.addr_id
						left join addr fromaddr on shipped_from_addr_id = fromaddr.addr_id
						left join trans on shipment.transaction_id = trans.transaction_id
						left join collection on trans.collection_id = collection.collection_id
						left join accn on trans.transaction_id = accn.transaction_id
						left join cataloged_item on accn.transaction_id = cataloged_item.accn_id
						left join flat on cataloged_item.collection_object_id = flat.collection_object_id
						left join locality on flat.locality_id = locality.locality_id
						left join taxonomy on flat.scientific_name = taxonomy.scientific_name
						where trans.transaction_type = 'accn'
							and permit_shipment.permit_id = <cfqueryparam cfsqltype="cf_sql_decimal" value="#permit_id#">
					union
					select 'loan' as ontype, loan_number as tnumber, loan_type as ttype, trans.transaction_type, trans.trans_date, collection.guid_prefix,
						concat('/transactions/Loan.cfm?Action=editLoan&transaction_id=',trans.transaction_id) as uri,
						locality.sovereign_nation,
						flat.country, flat.state_prov, flat.county, flat.island, flat.scientific_name, flat.guid,
						(case when flat.began_date > '1700-01-01' then 
     						 ( case when flat.began_date = flat.ended_date then flat.began_date else flat.began_date || '/' || flat.ended_date end)
    					else '' end) as eventDate,
						TO_DATE(null) as shipped_date, ' ' as toinstitution, ' ' as frominstitution, flat.parts,
						decode(mczbase.concatcommonname(taxon_name_id),null,'none recorded',mczbase.concatcommonname(taxon_name_id)) as common_name
					from permit_trans left join trans on permit_trans.transaction_id = trans.transaction_id
						left join collection on trans.collection_id = collection.collection_id
						left join loan on trans.transaction_id = loan.transaction_id
						left join loan_item on loan.transaction_id = loan_item.transaction_id
						left join specimen_part on loan_item.collection_object_id = specimen_part.collection_object_id
						left join flat on specimen_part.derived_from_cat_item = flat.collection_object_id
						left join locality on flat.locality_id = locality.locality_id
						left join taxonomy on flat.scientific_name = taxonomy.scientific_name
						where trans.transaction_type = 'loan'
							and permit_trans.permit_id = <cfqueryparam cfsqltype="cf_sql_decimal" value="#permit_id#">
					union
					select 'loan shipment' as ontype, loan_number as tnumber, loan_type as ttype, trans.transaction_type, trans.trans_date, collection.guid_prefix,
						concat('/transactions/Loan.cfm?Action=editLoan&transaction_id=',trans.transaction_id) as uri,
						locality.sovereign_nation,
						flat.country, flat.state_prov, flat.county, flat.island, flat.scientific_name, flat.guid,
						(case when flat.began_date > '1700-01-01' then 
     						 ( case when flat.began_date = flat.ended_date then flat.began_date else flat.began_date || '/' || flat.ended_date end)
    					else '' end) as eventDate,
						shipped_date, toaddr.institution toinstitution, fromaddr.institution frominstitution, flat.parts,
						decode(mczbase.concatcommonname(taxon_name_id),null,'none recorded',mczbase.concatcommonname(taxon_name_id)) as common_name
					from permit_shipment left join shipment on permit_shipment.shipment_id = shipment.shipment_id
						left join addr toaddr on shipped_to_addr_id = toaddr.addr_id
						left join addr fromaddr on shipped_from_addr_id = fromaddr.addr_id
						left join trans on shipment.transaction_id = trans.transaction_id
						left join collection on trans.collection_id = collection.collection_id
						left join loan on trans.transaction_id = loan.transaction_id
						left join loan_item on loan.transaction_id = loan_item.transaction_id
						left join specimen_part on loan_item.collection_object_id = specimen_part.collection_object_id
						left join flat on specimen_part.derived_from_cat_item = flat.collection_object_id
						left join locality on flat.locality_id = locality.locality_id
						left join taxonomy on flat.scientific_name = taxonomy.scientific_name
						where trans.transaction_type = 'loan'
							and permit_shipment.permit_id = <cfqueryparam cfsqltype="cf_sql_decimal" value="#permit_id#">
					union
					select 'deaccession' as ontype, deacc_number as tnumber, deacc_type as ttype, trans.transaction_type, trans.trans_date, collection.guid_prefix,
						concat('/transactions/Deaccession.cfm?action=edit&transaction_id=',trans.transaction_id) as uri,
						locality.sovereign_nation,
						flat.country, flat.state_prov, flat.county, flat.island, flat.scientific_name, flat.guid,
						(case when flat.began_date > '1700-01-01' then 
     						 ( case when flat.began_date = flat.ended_date then flat.began_date else flat.began_date || '/' || flat.ended_date end)
    					else '' end) as eventDate,
						GET_TRANS_SOLE_SHIP_DATE(permit_trans.transaction_id) as shipped_date,
						' ' as toinstitution, 'Museum of Comparative Zoology' as frominstitution, flat.parts,
						decode(mczbase.concatcommonname(taxon_name_id),null,'none recorded',mczbase.concatcommonname(taxon_name_id)) as common_name
					from permit_trans left join trans on permit_trans.transaction_id = trans.transaction_id
						left join collection on trans.collection_id = collection.collection_id
						left join deaccession on trans.transaction_id = deaccession.transaction_id
						left join deacc_item on deaccession.transaction_id = deacc_item.transaction_id
						left join flat on deacc_item.collection_object_id = flat.collection_object_id
						left join locality on flat.locality_id = locality.locality_id
						left join taxonomy on flat.scientific_name = taxonomy.scientific_name
						where trans.transaction_type = 'deaccession'
							and permit_trans.permit_id = <cfqueryparam cfsqltype="cf_sql_decimal" value="#permit_id#">
					union
					select 'deaccession shipment' as ontype, deacc_number as tnumber, deacc_type as ttype, trans.transaction_type, trans.trans_date, collection.guid_prefix,
						concat('/transactions/Deaccession.cfm?action=edit&transaction_id=',trans.transaction_id) as uri,
						locality.sovereign_nation,
						flat.country, flat.state_prov, flat.county, flat.island, flat.scientific_name, flat.guid,
						(case when flat.began_date > '1700-01-01' then 
     						 ( case when flat.began_date = flat.ended_date then flat.began_date else flat.began_date || '/' || flat.ended_date end)
    					else '' end) as eventDate,
						shipped_date, toaddr.institution toinstitution, fromaddr.institution frominstitution, flat.parts,
						decode(mczbase.concatcommonname(taxon_name_id),null,'none recorded',mczbase.concatcommonname(taxon_name_id)) as common_name
					from permit_shipment left join shipment on permit_shipment.shipment_id = shipment.shipment_id
						left join addr toaddr on shipped_to_addr_id = toaddr.addr_id
						left join addr fromaddr on shipped_from_addr_id = fromaddr.addr_id
						left join trans on shipment.transaction_id = trans.transaction_id
						left join collection on trans.collection_id = collection.collection_id
						left join deaccession on trans.transaction_id = deaccession.transaction_id
						left join deacc_item on deaccession.transaction_id = deacc_item.transaction_id
						left join flat on deacc_item.collection_object_id = flat.collection_object_id
						left join locality on flat.locality_id = locality.locality_id
						left join taxonomy on flat.scientific_name = taxonomy.scientific_name
						where trans.transaction_type = 'deaccession'
							and permit_shipment.permit_id = <cfqueryparam cfsqltype="cf_sql_decimal" value="#permit_id#">
					union
					select 'borrow' as ontype, lenders_trans_num_cde as tnumber, lender_loan_type as ttype, trans.transaction_type, trans.trans_date, collection.guid_prefix,
						concat('/transactions/Borrow.cfm?action=edit&transaction_id=',trans.transaction_id) as uri,
						borrow_item.country_of_origin as sovereign_nation,
						borrow_item.country_of_origin as country, '' as state_prov, '' as county, '' as island, borrow_item.sci_name as scientific_name, borrow_item.catalog_number as guid,
						'' as eventDate,
						TO_DATE(null) as shipped_date,'Museum of Comparative Zoology' as toinstitution, '' as frominstitution, borrow_item.spec_prep as parts,
						' ' as common_name
					from permit_trans left join trans on permit_trans.transaction_id = trans.transaction_id
						left join collection on trans.collection_id = collection.collection_id
						left join borrow on trans.transaction_id = borrow.transaction_id
						left join borrow_item on borrow.transaction_id = borrow_item.transaction_id
						where trans.transaction_type = 'borrow'
							and permit_trans.permit_id = <cfqueryparam cfsqltype="cf_sql_decimal" value="#permit_id#">
					union
					select 'borrow shipment' as ontype, lenders_trans_num_cde as tnumber, lender_loan_type as ttype, trans.transaction_type, trans.trans_date, collection.guid_prefix,
						concat('/transactions/Borrow.cfm?action=edit&transaction_id=',trans.transaction_id) as uri,
						borrow_item.country_of_origin as sovereign_nation,
						borrow_item.country_of_origin as country, '' as state_prov, '' as county, '' as island, borrow_item.sci_name as scientific_name, borrow_item.catalog_number as guid,
						'' as eventDate,
						shipped_date, toaddr.institution toinstitution, fromaddr.institution frominstitution, borrow_item.spec_prep as parts,
						' ' as common_name
					from permit_shipment left join shipment on permit_shipment.shipment_id = shipment.shipment_id
						left join addr toaddr on shipped_to_addr_id = toaddr.addr_id
						left join addr fromaddr on shipped_from_addr_id = fromaddr.addr_id
						left join trans on shipment.transaction_id = trans.transaction_id
						left join collection on trans.collection_id = collection.collection_id
						left join borrow on trans.transaction_id = borrow.transaction_id
						left join borrow_item on borrow.transaction_id = borrow_item.transaction_id
						where trans.transaction_type = 'borrow'
							and permit_shipment.permit_id = <cfqueryparam cfsqltype="cf_sql_decimal" value="#permit_id#">
		</cfquery>
		<cfset rows = use_result.recordcount>
		<cfset i = 1>
		<cfloop query="use">
			<cfset row = StructNew()>
			<cfset row["id_link"] = "<a href='#use.uri#'>#use.transaction_type# #use.tnumber#">
			<cfset row["ontype"] = "#use.ontype#">
			<cfset row["tnumber"] = "#use.tnumber#">
			<cfset row["ttype"] = "#use.ttype#">
			<cfset row["transaction_type"] = "#use.transaction_type#">
			<cfset row["trans_date"] = "#dateformat(use.trans_date,'yyyy-mm-dd')#">
			<cfset row["shipped_date"] = "#dateformat(use.shipped_date,'yyyy-mm-dd')#">
			<cfset row["guid_prefix"] = "#use.guid_prefix#">
			<cfset row["uri"] = "#use.uri#">
			<cfset row["sovereign_nation"] = "#use.sovereign_nation#">
			<cfset row["country"] = "#use.country#">
			<cfset row["state_prov"] = "#use.state_prov#">
			<cfset row["county"] = "#use.county#">
			<cfset row["island"] = "#use.island#">
			<cfset row["scientific_name"] = "#use.scientific_name#">
			<cfset row["guid"] = "#use.guid#">
			<cfset row["eventdate"] = "#use.eventDate#">
			<cfset row["toinstitution"] = "#use.toinstitution#">
			<cfset row["frominstitution"] = "#use.frominstitution#">
			<cfset row["parts"] = "#use.parts#">
			<cfset row["common_name"] = "#use.common_name#">
			<cfset row["row_number"] = "#i#">
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

<!----------------------------------------------------------------------------------------------------------------->
<cffunction name="addNewctSpecificType" access="remote" returnformat="json">
	<cfargument name="new_specific_type" type="string" required="yes">

	<cfset result = structNew()>
	<cftry>
		<cfset new_specific_type = trim(new_specific_type) >
		<cfquery name="addSpecificType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			insert into ctspecific_permit_type (specific_type)
			values ( <cfqueryparam value = "#new_specific_type#" CFSQLType="CF_SQL_VARCHAR"> )
		</cfquery>
		<cfset result["message"] = "Added #new_specific_type#.">
	<cfcatch>
		<cfif cfcatch.queryError contains 'ORA-00001'>
			<cfset result["message"] = "Error: That value is already a specific type of permit.">
		<cfelse>
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfset result["message"] = "Error in #function_called#: #error_message#">
		</cfif>
	</cfcatch>
	</cftry>
	<cfreturn result>
</cffunction>


<!--- getRestrictionsHtml get a block of html listing restrictions inherited from permits for items
  involved in a transaction. 
  @param transaction_id the transaction for which to lookup transitive restrictions.
  @return a block of html
--->
<cffunction name="getRestrictionsHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="transaction_id" type="string" required="yes">
	
	<cfthread name="getRestrictionsThread">
		<cftry>
			<cfquery name="getType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT transaction_type 
				FROM trans
				WHERE
					transaction_id = <cfqueryparam CFSQLType="CF_SQL_DECIMAL" value="#transaction_id#">
			</cfquery>
				
			<cfif getType.transaction_type EQ "loan">
				<cfquery name="getRestrictions" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT distinct restriction_summary, permit_id, permit_num from (
					select permit.restriction_summary, permit.permit_id, permit.permit_num
					from loan_item li 
						join specimen_part sp on li.collection_object_id = sp.collection_object_id
						join cataloged_item ci on sp.derived_from_cat_item = ci.collection_object_id
						join accn on ci.accn_id = accn.transaction_id
						join permit_trans on accn.transaction_id = permit_trans.transaction_id
						join permit on permit_trans.permit_id = permit.permit_id
					where li.transaction_id = <cfqueryparam CFSQLType="CF_SQL_DECIMAL" value="#transaction_id#">
						and permit.restriction_summary is not null
					UNION
					select permit.restriction_summary, permit.permit_id, permit.permit_num
					from loan
						join shipment on loan.transaction_id = shipment.transaction_id
						join permit_shipment on shipment.shipment_id = permit_shipment.shipment_id
						join permit on permit_shipment.permit_id = permit.permit_id
					where loan.transaction_id = <cfqueryparam CFSQLType="CF_SQL_DECIMAL" value="#transaction_id#">
						and permit.restriction_summary is not null
					)
				</cfquery>
			<cfelseif getType.transaction_type EQ "deaccession">
				<cfquery name="getRestrictions" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT distinct restriction_summary, permit_id, permit_num from (
					select permit.restriction_summary, permit.permit_id, permit.permit_num
					from deacc_item li 
						join specimen_part sp on li.collection_object_id = sp.collection_object_id
						join cataloged_item ci on sp.derived_from_cat_item = ci.collection_object_id
						join accn on ci.accn_id = accn.transaction_id
						join permit_trans on accn.transaction_id = permit_trans.transaction_id
						join permit on permit_trans.permit_id = permit.permit_id
					where li.transaction_id = <cfqueryparam CFSQLType="CF_SQL_DECIMAL" value="#transaction_id#">
						and permit.restriction_summary is not null
					UNION
					select permit.restriction_summary, permit.permit_id, permit.permit_num
					from deaccession
						join shipment on deaccession.transaction_id = shipment.transaction_id
						join permit_shipment on shipment.shipment_id = permit_shipment.shipment_id
						join permit on permit_shipment.permit_id = permit.permit_id
					where deaccession.transaction_id = <cfqueryparam CFSQLType="CF_SQL_DECIMAL" value="#transaction_id#">
						and permit.restriction_summary is not null
					)
				</cfquery>
			<cfelse>
				<cfthrow message="No transaction found for specified transaction_id">
			</cfif>
			<cfif isDefined("getRestrictions") AND getRestrictions.recordCount GT 0>
				<cfoutput>
					<div class="col-12 pb-0 px-0">
						<h2 class="h3 px-3">Restrictions on Use</h2>
						<p class="px-3">Restrictions on use from one or more permissions and rights document apply to one or more items in this loan.</p>
						<ul>
							<cfloop query="getRestrictions">
								<li><a href="/transactions/Permit.cfm?action=view&permit_id=#getRestrictions.permit_id#" target="_blank">#getRestrictions.permit_num#</a>#getRestrictions.restriction_summary#</li>
							</cfloop>
						</ul>
					</div>
				</cfoutput>
			<cfelse>
				<cfoutput></cfoutput>
			</cfif>
		<cfcatch>
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cfthread>
	<cfthread action="join" name="getRestrictionsThread" />
	<cfreturn getRestrictionsThread.output>
</cffunction>

</cfcomponent>
