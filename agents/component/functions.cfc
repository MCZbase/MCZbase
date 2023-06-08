<!---
/agents/component/functions.cfc

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
<cfinclude template="/shared/component/error_handler.cfc" runOnce="true">

<!--- given a start year and end year, return a string representing the 
 range of years with unknown for start/end years with no value)
--->
<cffunction name="assembleYearRange">
	<cfargument name="start_year" type="string" required="yes">
	<cfargument name="end_year" type="string" required="yes">
	<cfargument name="year_only" type="string" required="no" default=false>
	<cfset yearStr = "">
	<cfif year_only>
		<cfif len(start_year) GT 4>
			<cfset start_year = left(start_year,4)>
		</cfif>
		<cfif len(end_year) GT 4>
			<cfset end_year = left(end_year,4)>
		</cfif>
	</cfif>
	<cfif len(start_year) gt 0>
		<cfset yearStr="#yearStr# (#start_year#">
	<cfelse>
		<cfset yearStr="#yearStr# (unknown">
	</cfif>
	<cfif len(end_year) gt 0>
		<cfset yearStr="#yearStr# - #end_year#)">
	<cfelse>
		<cfif len(start_year) gt 0 and val(start_year) LT 1920 >
			<cfset yearStr="#yearStr# - unknown)">
		<cfelse>
			<cfset yearStr="#yearStr# - &nbsp;)">
		</cfif>
	</cfif>
	<cfreturn yearStr>
</cffunction>

<!--- check if there is a case sensitive exact match to a specified preferred agent name 
 @param pref_name the name to check 
 @param not_agent_id if specified, the current agent to exclude from the check
--->
<cffunction name="checkPrefNameExists" returntype="any" access="remote" returnformat="json">
	<cfargument name="pref_name" type="string" required="yes">
	<cfargument name="not_agent_id" type="string" required="no">

	<cfset data = ArrayNew(1)>
	<cftry>
		<cfquery name="dupPref" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="dupPref_result">
			SELECT agent.agent_type, preferred_agent_name.agent_id, preferred_agent_name.agent_name
			FROM preferred_agent_name
				left join agent on preferred_agent_name.agent_id = agent.agent_id
			WHERE
				preferred_agent_name.agent_name = <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#pref_name#'>
				<cfif isdefined("not_agent_id") and len(not_agent_id) GT 0>
					AND preferred_agent_name.agent_id <> <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#not_agent_id#">
				</cfif>
		</cfquery>
		<cfset matchcount = dupPref.recordcount>
		<cfset i = 1>
		<cfloop query="dupPref">
			<cfset row = StructNew()>
			<cfset columnNames = ListToArray(dupPref.columnList)>
			<cfloop array="#columnNames#" index="columnName">
				<cfset row["#columnName#"] = "#dupPref[columnName][currentrow]#">
			</cfloop>
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
</cffunction>

<!--- check if there is a case-insensitive match to a specified agent name 
 @param pref_name the name to check 
 @param not_agent_id if specified, the current agent to exclude from the check
--->
<cffunction name="checkNameExists" returntype="any" access="remote" returnformat="json">
	<cfargument name="pref_name" type="string" required="yes">
	<cfargument name="not_agent_id" type="string" required="no">

	<cfset data = ArrayNew(1)>
	<cftry>
		<cfquery name="dupPref" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="dupPref_result">
			SELECT agent.agent_type,agent_name.agent_id,agent_name.agent_name
			FROM 
				agent_name
				left join agent on agent_name.agent_id = agent.agent_id
			WHERE 
				upper(agent_name.agent_name) = <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#ucase(pref_name)#'>
				<cfif isdefined("not_agent_id") and len(not_agent_id) GT 0>
					AND preferred_agent_name.agent_id <> <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#not_agent_id#">
				</cfif>
		</cfquery>
		<cfset matchcount = dupPref.recordcount>
		<cfset i = 1>
		<cfloop query="dupPref">
			<cfset row = StructNew()>
			<cfset columnNames = ListToArray(dupPref.columnList)>
			<cfloop array="#columnNames#" index="columnName">
				<cfset row["#columnName#"] = "#dupPref[columnName][currentrow]#">
			</cfloop>
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
</cffunction>

<!--- obtain a block of html for displaying and editing addresses of an agent
 @param agent_id the agent for which to lookup addresses
 @return a block of html containing a list of addresses for an agent with controls to insert/update/delete addresses
  assuming this block will go within a section with a heading.
--->
<cffunction name="getAgentAddressesHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="agent_id" type="string" required="yes">
	<cfthread name="addressesThread">
		<cfoutput>
			<cftry>
				<cfquery name="ctAddrType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT addr_type 
					fROM ctaddr_type
					WHERE addr_type <> 'temporary'
				</cfquery>
				<cfquery name="agentAddrs" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT
						addr_id,
						addr_type,
						formatted_addr,
						valid_addr_fg,
						addr_remarks
					FROM addr
					WHERE 
						agent_id = <cfqueryparam value="#agent_id#" cfsqltype="CF_SQL_DECIMAL">
						and addr.addr_type <> 'temporary'
					order by valid_addr_fg DESC, addr_type
				</cfquery>
				<h3 class="h4 sr-only">Addresses</h3>
				<cfif agentAddrs.recordcount EQ 0>
					<ul class="list-group list-group-horizontal">
						<li class="list-group-item">None</li>
					</ul>
				<cfelse>
					<cfset i=0>
					<ul class="list-group form-row mx-0 pr-2">
						<cfloop query="agentAddrs">
							<cfquery name="countUses" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result=countUses_result>
								SELECT count(shipment_id) ct 
								FROM shipment 
								WHERE shipped_to_addr_id = <cfqueryparam value="#agentAddrs.addr_id#" cfsqltype="CF_SQL_DECIMAL">
									OR shipped_from_addr_id = <cfqueryparam value="#agentAddrs.addr_id#" cfsqltype="CF_SQL_DECIMAL">
							</cfquery>
							<cfset i=i+1>
							<cfif len(addr_remarks) GT 0><cfset rem="[#addr_remarks#]"><cfelse><cfset rem=""></cfif>
							<cfif valid_addr_fg EQ 1>
								<cfset addressCurrency="Valid">
								<cfset listgroupclass="border-green bg-verylightgreen">
							<cfelse>
								<cfset addressCurrency="Invalid">
								<cfset listgroupclass="border-wide-grey">
							</cfif>
							<li class="list-group-item #listgroupclass# w-100 px-2 py-1">
								<div class="form-row">
									<div class="col-12 col-md-6 col-xl-3">
										<span class="font-weight-bold text-capitalize">#addr_type#:</span>
										<span class="">(#addressCurrency#)</span>
									</div>
									<div class="col-12 col-md-6 col-xl-5">
										#replace(formatted_addr,chr(10),"<br>","All")#
									</div>
									<div class="col-12 col-md-6 col-xl-2">
										#rem#
									</div>
									<div class="col-12 col-md-6 col-xl-2">
										<button type="button" id="editAddrButton_#i#" value="Edit" class="btn btn-xs btn-secondary my-1">Edit</button>
										<cfif countUses.ct GT 0>
											<span>Used in #countUses.ct# Shipments</span>
										<cfelse>
											<button type="button" id="deleteAddrButton_#i#" value="Delete" class="btn btn-xs btn-danger my-1">Delete</button>
										</cfif>
									</div>
								</div>
								<script>
									function doDeleteAddr_#i#() { 
										deleteAgentAddress(#agentAddrs.addr_id#,reloadAddresses);
									}
									$(document).ready(function () {
										$("##editAddrButton_#i#").click(function(evt) { 
											editAddressForAgent(#agentAddrs.addr_id#,"addressDialogDiv",reloadAddresses);
										});
										$("##deleteAddrButton_#i#").click(function(evt) { 
											confirmWarningDialog("Delete This #addr_type# Address?", "Confirm Delete?", doDeleteAddr_#i#);
										});
									});
								</script>
							</li>
						</cfloop>
					</cfif>
				</ul>

				<div id="addressDialogDiv"></div>

				<h3 class="h4 mt-2 pt-1">Add New Address</h3>
				<div class="form-row">
					<div class="col-12 col-md-4">
						<label for="new_address_type" class="data-entry-label mb-0">Address Type</label>
						<select name="address_type" id="new_address_type" class="data-entry-select">
							<cfset i=0>
							<cfloop query="ctAddrType">
								<cfif i EQ 0><cfset selected="selected"><cfelse><cfset selected=""></cfif>
								<option value="#ctAddrType.addr_type#" #selected#>#ctAddrType.addr_type#</option>
								<cfset i=i+1>
							</cfloop>
						</select>
						<input type="hidden" id="newAddrAgentId" value="#agent_id#">
					</div>
					<div class="col-12 col-md-8 pt-1 pt-md-0">
						<label for="addAddrButton" class="data-entry-label">&nbsp;</label>
						<button type="button" id="addAddrButton" value="Add" class="btn btn-xs btn-secondary">Add</button>
						<script>
							$(document).ready(function () {
								$("##addAddrButton").click(function(evt) { 
									evt.preventDefault();
									addAddressForAgent("newAddrAgentId","new_address_type","addressDialogDiv",reloadAddresses);
								});
							});
						</script>
					</div>
				</div>
			<cfcatch>
				<h2>Error: #cfcatch.type# #cfcatch.message#</h2> 
				<div>#cfcatch.detail#</div>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="addressesThread" />
	<cfreturn addressesThread.output>
</cffunction>

<!--- given an agent and details for an address, add the address to the agent.
 @param agent_id the agent for which to add the address.
 @return a json result containing status=1 and a message on success, otherwise a http 500 status with message.
--->
<cffunction name="addNewAddress" returntype="any" access="remote" returnformat="json">
	<cfargument name="agent_id" type="string" required="yes">
	<cfargument name="addr_type" type="string" required="yes">
	<cfargument name="valid_addr_fg" type="string" required="yes">
	<cfargument name="street_addr1" type="string" required="yes">
	<cfargument name="street_addr2" type="string" required="yes">
	<cfargument name="institution" type="string" required="yes">
	<cfargument name="department" type="string" required="yes">
	<cfargument name="city" type="string" required="yes">
	<cfargument name="state" type="string" required="yes">
	<cfargument name="country_cde" type="string" required="yes">
	<cfargument name="zip" type="string" required="yes">
	<cfargument name="mail_stop" type="string" required="yes">
	<cfargument name="job_title" type="string" required="yes">
	<cfargument name="addr_remarks" type="string" required="yes">

	<cfset theResult=queryNew("status, message,address_id, address")>
	<cftransaction>
		<cftry>
			<cfquery name="addrNextId" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select sq_addr_id.nextval as id from dual
			</cfquery>
			<cfset pk = addrNextId.id>
			<cfquery name="newAddr" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="newAddr_result">
				INSERT INTO addr (
					ADDR_ID
					,STREET_ADDR1
					,STREET_ADDR2
					,institution
					,department
					,CITY
					,state
					,ZIP
					,COUNTRY_CDE
					,MAIL_STOP
					,agent_id
					,addr_type
					,job_title
					,valid_addr_fg
					,addr_remarks
				) VALUES (
					<cfqueryparam cfsqltype='CF_SQL_DECIMAL' value='#pk#'>
					,<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#street_addr1#'>
					,<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#street_addr2#'>
					,<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#institution#'>
					,<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#department#'>
					,<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#city#'>
					,<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#state#'>
					,<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#zip#'>
					,<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#country_cde#'>
					,<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#mail_stop#'>
					,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
					,<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#addr_type#'>
					,<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#job_title#'>
					,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#valid_addr_fg#">
					,<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#addr_remarks#'>
				)
			</cfquery>
			<cfquery name="newAddr" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="addrResult"> 
				SELECT formatted_addr
				FROM addr 
				WHERE addr_id = <cfqueryparam value='#pk#' cfsqltype="CF_SQL_DECIMAL">
			</cfquery>
			<cfif newAddr_result.recordcount EQ 1>
				<cfset t = queryaddrow(theResult,1)>
				<cfset t = QuerySetCell(theResult, "status", "1", 1)>
				<cfset t = QuerySetCell(theResult, "message", "Address added.", 1)>
				<cfset t = QuerySetCell(theResult, "address_id", "#pk#", 1)>
				<cfset t = QuerySetCell(theResult, "address", "#newAddr.formatted_addr#", 1)>
			<cfelse>
				<cfthrow message="Unable to insert address, other than one [#newAddr_result.recordcount#] address would be created.">
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
	<cfreturn #theResult#>
</cffunction>


<!--- update an existing address
 @param addr_id the address to update.
 @param agent_id the agent for which this is an address
 @return a json result containing status=1 and a message on success, otherwise a http 500 status with message.
--->
<cffunction name="updateAddress" returntype="any" access="remote" returnformat="json">
	<cfargument name="addr_id" type="string" required="yes">
	<cfargument name="agent_id" type="string" required="yes">
	<cfargument name="addr_type" type="string" required="yes">
	<cfargument name="valid_addr_fg" type="string" required="yes">
	<cfargument name="street_addr1" type="string" required="yes">
	<cfargument name="street_addr2" type="string" required="yes">
	<cfargument name="institution" type="string" required="yes">
	<cfargument name="department" type="string" required="yes">
	<cfargument name="city" type="string" required="yes">
	<cfargument name="state" type="string" required="yes">
	<cfargument name="country_cde" type="string" required="yes">
	<cfargument name="zip" type="string" required="yes">
	<cfargument name="mail_stop" type="string" required="yes">
	<cfargument name="job_title" type="string" required="yes">
	<cfargument name="addr_remarks" type="string" required="yes">

	<cfset theResult=queryNew("status, message, address")>
	<cftransaction>
		<cftry>
			<cfquery name="updateAddr" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="updateAddr_result">
				UPDATE addr 
				SET
					AGENT_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#AGENT_ID#">
					,STREET_ADDR1 = <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#STREET_ADDR1#'>
					,STREET_ADDR2 = <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#STREET_ADDR2#'>
					,department = <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#department#'>
					,institution = <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#institution#'>
					,CITY = <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#CITY#'>
					,STATE = <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#STATE#'>
					,ZIP = <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#ZIP#'>
					,COUNTRY_CDE = <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#COUNTRY_CDE#'>
					,MAIL_STOP = <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#MAIL_STOP#'>
					,ADDR_TYPE = <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#ADDR_TYPE#'>
					,JOB_TITLE = <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#JOB_TITLE#'>
					,VALID_ADDR_FG = <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#VALID_ADDR_FG#'>
					,ADDR_REMARKS = <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#ADDR_REMARKS#'>
				WHERE addr_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#addr_id#">
			</cfquery>
			<cfif updateAddr_result.recordcount EQ 1>
				<cfquery name="getUpdatedAddr" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getUpdatedAddr_result">
					SELECT formatted_addr 
					FROM addr
					WHERE addr_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#addr_id#">
				</cfquery>
				<cfset t = queryaddrow(theResult,1)>
				<cfset t = QuerySetCell(theResult, "status", "1", 1)>
				<cfset t = QuerySetCell(theResult, "message", "Address updated.", 1)>
				<cfset t = QuerySetCell(theResult, "address", "#getUpdatedAddr.formatted_addr#", 1)>
			<cfelse>
				<cfthrow message="Unable to update address, other than one [#updateAddr_result.recordcount#] address would be updated.">
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
	<cfreturn #theResult#>
</cffunction>

<!--- delete an address
 @param addr_id the address to delete
 @return a json result containing status=1 and a message on success, otherwise a http 500 status with message.
--->
<cffunction name="deleteAddress" returntype="any" access="remote" returnformat="json">
	<cfargument name="addr_id" type="string" required="yes">

	<cfset theResult=queryNew("status, message")>
	<cftransaction>
		<cftry>
			<cfquery name="deleteAddr" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="deleteAddr_result">
				DELETE FROM addr 
				WHERE addr_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#addr_id#">
			</cfquery>
			<cfif deleteAddr_result.recordcount EQ 1>
				<cfset t = queryaddrow(theResult,1)>
				<cfset t = QuerySetCell(theResult, "status", "1", 1)>
				<cfset t = QuerySetCell(theResult, "message", "Address deleted.", 1)>
			<cfelse>
				<cfthrow message="Unable to delete address, other than one [#deleteAddr_result.recordcount#] address would be deleted.">
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
	<cfreturn #theResult#>
</cffunction>


<!--- obtain a block of html for displaying and editing relationships of an agent
 @param agent_id the agent for which to lookup relationships
 @return a block of html containing a list of relationships for an agent with controls to insert/update/delete relationships
  assuming this block will go within a section with a heading.
--->
<cffunction name="getAgentRelationshipsHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="agent_id" type="string" required="yes">
	<cfthread name="arelationThread">
		<cfoutput>
			<cftry>
				<cfquery name="agent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="agent_result">
					SELECT agent_name, edited
					FROM agent left join preferred_agent_name on agent.agent_id = preferred_agent_name.agent_id
					WHERE agent.agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
				</cfquery>
				<cfset currAgent = agent.agent_name>
				<cfquery name="ctagent_relationship" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT agent_relationship
					FROM ctagent_relationship 
					ORDER BY agent_relationship
				</cfquery>
					<h3 class="h4">Relationships of <span class="text-secondary">#currAgent#</span> to other agents</h3>
				<cfquery name="relations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="relations_result">
					select
						preferred_agent_name.agent_name,
						agent_relationship, 
						agent_relations.agent_id, 
						related_agent_id,
						date_to_merge, on_hold, held_by,
						agent_remarks, 
						created_by
					from agent_relations
						left join preferred_agent_name on agent_relations.related_agent_id = preferred_agent_name.agent_id
					where
						agent_relations.agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
				</cfquery>
				<cfif relations.recordcount EQ 0 >
					<ul class="list-group list-group-horizontal form-row mx-0">
						<li class="list-group-item">None</li>
					</ul>
				<cfelse>
					<cfset i=0>
					<cfloop query="relations">
						<cfset i=i+1>
						<ul class="list-group list-group-horizontal form-row mx-0">
							<li class="list-group-item px-0">
								<label class="border sr-only">#currAgent#</label> 
								<select name="relation_type" id="relation_type_#i#" class="data-entry-select">
									<cfloop query="ctagent_relationship">
										<cfif relations.agent_relationship EQ ctagent_relationship.agent_relationship><cfset selected="selected"><cfelse><cfset selected=""></cfif>
										<option value="#ctagent_relationship.agent_relationship#" #selected#>#ctagent_relationship.agent_relationship#</option>
									</cfloop>
								</select>
							</li>
							<li class="list-group-item px-0">
								<input type="text" name="related_agent" id="related_agent_#i#" value="#agent_name#" class="data-entry-input">
							</li>
								<input type="hidden" name="related_agent" id="related_agent_id_#i#" value="#related_agent_id#">
								<input type="hidden" name="related_agent" id="old_related_agent_id_#i#" value="#related_agent_id#">
								<input type="hidden" name="related_agent" id="old_relationship_#i#" value="#relations.agent_relationship#">
							<li class="list-group-item">
								<div id="view_rel_#i#" class="mt-1" <!---href="/agents/editAgent.cfm?agent_id=#related_agent_id#"--->>View</div> 
							</li>
							<li class="list-group-item px-0">
								<input type="text" name="agent_remarks" id="agent_remarks_#i#" value="#agent_remarks#" placeholder="remarks" class="data-entry-input">
							</li>
								<cfif len(on_hold) GT 0><cfset hold="put on hold by"><cfelse><cfset hold=""></cfif>
								#dateformat(date_to_merge,"yyyy-mm-dd")# #hold# #held_by#
							<li class="list-group-item px-1">
								<button type="button" id="updateRelationshipButton_#i#" value="Add" class="btn btn-xs mt-0 btn-secondary">Save</button>
							</li>
							<li class="list-group-item px-0">
								<button type="button" id="deleteRelationshipButton_#i#" value="Add" class="btn btn-xs mt-0 btn-warning">Remove</button>
							</li>
							<output id="relationfeedback_#i#"></output>
							<script>
								$(document).ready(function () {
									makeRichAgentPicker("related_agent_#i#", "related_agent_id_#i#", "related_agent_#i#", "view_rel_#i#", #related_agent_id#);
									$("##updateRelationshipButton_#i#").click(function(evt){
										evt.preventDefault;
										updateAgentRelationship(#agent_id#,"related_agent_id_#i#","relation_type_#i#","agent_remarks_#i#", "old_related_agent_id_#i#", "old_relationship_#i#","relationfeedback_#i#");
									});
									$("##deleteRelationshipButton_#i#").click(function(evt){
										evt.preventDefault;
										deleteAgentRelationship(#agent_id#,"related_agent_id_#i#","relation_type_#i#",reloadRelationships);
									});
								});
							</script>
						</ul>
					</cfloop>
				</cfif>
				<div id="newRelationshipDiv" class="col-12 px-0 mb-3">
					<label for="new_relation" class="data-entry-label mb-0 sr-only">Add Relationship</label>
					<h3 class="h4 pt-1 mt-2">Add Relationship</h3>
					<div class="form-row">
						<div class="col-12 col-md-2">
							<label class="data-entry-label mb-0 px-0">&nbsp;Current Agent</label>
							<input type="text" name="current_agent" value="#currAgent#" class="data-entry-input" disabled >
						</div>
						<div class="col-12 col-md-3">
							<label for="new_relation_type" class="data-entry-label mb-0">Relationship</label>
							<select name="relation_type" id="new_relation_type" class="data-entry-select reqdClr">
								<option value""></option>
								<cfloop query="ctagent_relationship">
									<option value="#ctagent_relationship.agent_relationship#">#ctagent_relationship.agent_relationship#</option>
								</cfloop>
							</select>
						</div>
						<div class="col-12 col-md-3">
							<label for="new_related_agent" class="data-entry-label mb-0">To Related Agent</label>
							<input type="text" name="related_agent" id="new_related_agent" value="" class="data-entry-input reqdClr">
							<input type="hidden" name="related_agent" id="new_related_agent_id" value="">
						</div>
						<div class="col-12 col-md-3">
							<label for="new_relation" class="data-entry-label mb-0">Remarks</label>
							<input type="text" name="agent_remarks" id="new_agent_remarks" value="" class="data-entry-input">
						</div>
						<div class="col-12 col-md-1 px-1 pt-1 pt-md-0">
							<label class="data-entry-label">&nbsp;</label>
							<button type="button" id="addRelationshipButton" value="Add" class="btn btn-xs btn-secondary">Add</button>
						</div>
					</div>
					<script>
						$(document).ready(function () {
							makeAgentAutocompleteMetaID("new_related_agent", "new_related_agent_id");
							function addRel () { 
								 addRelationshipToAgent(#agent_id#,"new_related_agent_id","new_relation_type","new_agent_remarks",reloadRelationships);
							}
							$("##addRelationshipButton").click(function(evt){
								evt.preventDefault;
								<cfif agent.edited EQ 1>
									if ($('##new_relation_type').val() == 'bad duplicate of') { 
										confirmDialog("This agent is marked as vetted *, do you really want to mark it as a bad duplicate of another agent?", "Confirm Bad Duplicate for Vetted Agent?", addRel);
									} else { 
										addRel();
									}
								<cfelse>
									addRel();
								</cfif>
							});
						});
					</script>
				</div>
				<h3 class="h4">Relationships from Other Agents</h3>
				<cfquery name="revRelations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="revRelations_result">
					select
						preferred_agent_name.agent_name,
						agent_relationship, 
						agent_relations.agent_id as from_agent_id, 
						related_agent_id,
						date_to_merge, on_hold, held_by,
						agent_remarks, 
						created_by
					from agent_relations
						left join preferred_agent_name on agent_relations.agent_id = preferred_agent_name.agent_id
					where
						agent_relations.related_agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
				</cfquery>
				<cfif revRelations.recordcount EQ 0 >
					<ul class="list-group list-group-horizontal form-row mb-0">
						<li class="list-group-item">None</li>
					</ul>
				<cfelse>
					<cfloop query="revRelations">
						<ul class="list-group list-group-horizontal form-row mb-0">
							<li class="list-group-item">
								<a href="/agents/editAgent.cfm?agent_id=#from_agent_id#">#agent_name#</a> 
								#agent_relationship# 
								#currAgent#
								#agent_remarks# 
								<cfif len(on_hold) GT 0><cfset hold="put on hold by"><cfelse><cfset hold=""></cfif>
								#dateformat(date_to_merge,"yyyy-mm-dd")# #hold# #held_by#
							</li>
						</ul>
					</cfloop>
				</cfif>
			<cfcatch>
				<h2>Error: #cfcatch.type# #cfcatch.message#</h2> 
				<div>#cfcatch.detail#</div>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="arelationThread" />
	<cfreturn arelationThread.output>
</cffunction>

<!--- given an agent and a second agent, create a relationship between the two. 
 @param agent_id the agent for which to add the relationship
 @param related_agent_id the agent to be related to
 @param relationship the nature of the relationship
 @return a json result containing status=1 and a message on success, otherwise a http 500 status with message.
--->
<cffunction name="addRelationshipToAgent" returntype="any" access="remote" returnformat="json">
	<cfargument name="agent_id" type="string" required="yes">
	<cfargument name="related_agent_id" type="string" required="yes">
	<cfargument name="relationship" type="string" required="yes">
	<cfargument name="agent_remarks" type="string" required="no">

	<cfset theResult=queryNew("status, message")>
	<cftransaction>
		<cftry>
			<cfif NOT isdefined("related_agent_id") OR len(related_agent_id) EQ 0>
				<cfthrow message="Unable to insert relationship, no related agent specified.  You must pick a related agent from the pick list.">
			</cfif>
			<cfif related_agent_id EQ agent_id>
				<cfthrow message="Unable to insert relationship, an agent cannot be related to itself.">
			</cfif>
			<cfif NOT isdefined("relationship") OR len(relationship) EQ 0 OR ucase(relationship) EQ ucase("Select a Relationship")>
				<cfthrow message="Unable to insert relationship, no relationship type selected.  You must pick a relationship.">
			</cfif>
			<cfquery name="newRelationship" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="newRelationship_result">
				INSERT INTO agent_relations (
					AGENT_ID,
					RELATED_AGENT_ID,
					AGENT_RELATIONSHIP
					<cfif isdefined("agent_remarks") AND len(agent_remarks) GT 0>
						,AGENT_REMARKS
					</cfif>
				)
				VALUES (
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#related_agent_id#">,
					<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#relationship#'>
					<cfif isdefined("agent_remarks") AND len(agent_remarks) GT 0>
						,<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#agent_remarks#'>
					</cfif>
				)
			</cfquery>
			<cfif newRelationship_result.recordcount EQ 1>
				<cfset t = queryaddrow(theResult,1)>
				<cfset t = QuerySetCell(theResult, "status", "1", 1)>
				<cfset t = QuerySetCell(theResult, "message", "Relationship [#encodeForHtml(relationship)#] added.", 1)>
			<cfelse>
				<cfthrow message="Unable to insert relationship, other than one [#newRelationship_result.recordcount#] relation would be created.">
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
	<cfreturn #theResult#>
</cffunction>

<!--- delete a relationship between two agents. 
 @param agent_id the agent for which to delete the relationship
 @param related_agent_id the agent in the relationship
 @param relationship the nature of the relationship
 @return a json result containing status=1 and a message on success, otherwise a http 500 status with message.
--->
<cffunction name="deleteAgentRelationship" returntype="any" access="remote" returnformat="json">
	<cfargument name="agent_id" type="string" required="yes">
	<cfargument name="related_agent_id" type="string" required="yes">
	<cfargument name="relationship" type="string" required="yes">

	<cfset theResult=queryNew("status, message")>
	<cftransaction>
		<cftry>
			<cfquery name="deleteRelationship" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="deleteRelationship_result">
				DELETE FROM agent_relations 
				WHERE
				agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
				and related_agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#related_agent_id#">
				and agent_relationship = <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#relationship#'>
			</cfquery>
			<cfif deleteRelationship_result.recordcount EQ 1>
				<cfset t = queryaddrow(theResult,1)>
				<cfset t = QuerySetCell(theResult, "status", "1", 1)>
				<cfset t = QuerySetCell(theResult, "message", "Relationship [#encodeForHtml(relationship)#] deleted.", 1)>
			<cfelse>
				<cfthrow message="Unable to delete relationship, other than one [#deleteRelationship_result.recordcount#] relation would be deleted.">
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
	<cfreturn #theResult#>
</cffunction>

<!--- update an existing relationship between two agents, a relationship a weak entinty and
 * is identified by a  primary key consisting of agent_id, related_agent_id, and relationship.
 @param agent_id the agent for the relationship
 @param related_agent_id the new value for the related agent in the relationship
 @param relationship the new value for the nature of the relationship
 @param agent_remarks
 @param old_related_agent_id the current value for the related agent
 @param old_relationship the current value for the nature of the relationship
 @return a json result containing status=1 and a message on success, otherwise a http 500 status with message.
--->
<cffunction name="updateAgentRelationship" returntype="any" access="remote" returnformat="json">
	<cfargument name="agent_id" type="string" required="yes">
	<cfargument name="old_related_agent_id" type="string" required="yes">
	<cfargument name="old_relationship" type="string" required="yes">
	<cfargument name="related_agent_id" type="string" required="yes">
	<cfargument name="relationship" type="string" required="yes">
	<cfargument name="agent_remarks" type="string" required="no">

	<cfset theResult=queryNew("status, message")>
	<cftransaction>
		<cftry>
			<cfif NOT isdefined("related_agent_id") OR len(related_agent_id) EQ 0>
				<cfthrow message="Unable to insert relationship, no related agent specified.  You must pick a related agent from the pick list..">
			</cfif>
			<cfquery name="updateRelationship" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="updateRelationship_result">
				UPDATE agent_relations SET
					related_agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#related_agent_id#">
					, agent_relationship=<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#relationship#'>
					<cfif isdefined("agent_remarks") and len(agent_remarks) GT 0>
						, agent_remarks=<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#agent_remarks#'>
					</cfif>
				WHERE agent_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
					AND related_agent_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#old_related_agent_id#">
					AND agent_relationship=<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#old_relationship#'>
			</cfquery>
			<cfif updateRelationship_result.recordcount EQ 1>
				<cfset t = queryaddrow(theResult,1)>
				<cfset t = QuerySetCell(theResult, "status", "1", 1)>
				<cfset t = QuerySetCell(theResult, "message", "Relationship [#encodeForHtml(relationship)#] updated.", 1)>
			<cfelse>
				<cfthrow message="Unable to update relationship, other than one [#updateRelationship_result.recordcount#] relation would be updated.">
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
	<cfreturn #theResult#>
</cffunction>

<!--- obtain a block of html for displaying and editing phones/emails of an agent
 @param agent_id the agent for which to lookup electronic addresses
 @return a block of html containing a list of names with controls to remove or add electronic addresses
  assuming this block will go within a section with a heading.
--->
<cffunction name="getElectronicAddressesHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="agent_id" type="string" required="yes">
	<cfthread name="eaddrThread">
		<cfoutput>
			<cftry>
				<cfquery name="ctElecAddrType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select address_type from ctelectronic_addr_type
				</cfquery>
				<cfquery name="electAgentAddrs" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="electAgentAddrs_result">
					SELECT 
						electronic_address_id,
						agent_id, 
						address_type, 
						address
					FROM electronic_address
					WHERE
					agent_id = <cfqueryparam value="#agent_id#" cfsqltype="CF_SQL_DECIMAL">
				</cfquery>
				<cfif electAgentAddrs.recordcount EQ 0 >
					<ul class="list-group list-unstyled list-group-horizontal">
						<li class="list-group-item">None</li>
					</ul>
				<cfelse>
					<cfset i=0>
					<cfloop query="electAgentAddrs">
						<cfset i=i+1>
						<ul class="list-group list-unstyled list-group-horizontal form-row mx-0">
							<li class="list-group-item border-bottom-0 px-0">
								<select name="address_type" id="eaddress_type_#i#" class="data-entry-select">
									<cfloop query="ctElecAddrType">
										<cfif #electAgentAddrs.address_type# is "#ctElecAddrType.address_type#"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
										<option value="#ctElecAddrType.address_type#" #selected#>#ctElecAddrType.address_type#</option>
									</cfloop>
								</select>
							</li>
							<li class="list-group-item border-bottom-0 px-0">
								<input type="text" name="address" id="address_#i#" value="#encodeForHtml(address)#" class="data-entry-input">
								<input type="hidden" name="electronic_address_id" id="electronic_address_id_#i#" value="#electAgentAddrs.electronic_address_id#">
							</li>
							<li class="list-group-item border-bottom-0 px-1">
								<button type="button" id="agentEAddrU#i#Button" value="Update" class="btn btn-xs btn-secondary">Update</button>
							</li>
							<li class="list-group-item border-bottom-0 px-0">
								<button type="button" id="agentEAddrDel#i#Button" value="Delete" class="btn btn-xs btn-danger">Delete</button>
								<span id="electronicAddressFeedback#i#"></span>
							</li>
							<script>
								function doDeleteEA_#i#() { 
									deleteElectronicAddress('electronic_address_id_#i#',reloadElectronicAddresses);
								};
								$(document).ready(function () {
									$('##agentEAddrU#i#Button').click(function(evt){
										evt.preventDefault;
										updateElectronicAddress(#agent_id#, 'electronic_address_id_#i#','address_#i#','eaddress_type_#i#','electronicAddressFeedback#i#');
									});
								});
								$(document).ready(function () {
									$('##agentEAddrDel#i#Button').click(function(evt){
										evt.preventDefault;
										confirmWarningDialog("Delete the #encodeForHTML(address)# #address_type#?", "Confirm Delete?", doDeleteEA_#i#);
									});
								});
							</script>
						</ul>
					</cfloop>
				</cfif>
				<div id="newEaddrDiv" class="col-12 pt-2 px-0">
				<label for="new_eaddress" class="pt-1 h4">Add Phone or Email</label>
					<div class="form-row">
						<div class="col-12 col-md-5">
							<select name="eaddress_type" id="new_eaddress_type" class="data-entry-select">
								<cfloop query="ctElecAddrType">
									<option value="#ctElecAddrType.address_type#">#ctElecAddrType.address_type#</option>
								</cfloop>
							</select>
						</div>
						<div class="col-12 col-md-5">
							<input type="text" name="address" id="new_eaddress" value="" class="data-entry-input reqdClr" required>
						</div>
						<div class="col-12 col-md-2 pt-1 pt-md-0">
							<button type="button" id="addElectronicAddressButton" value="Add" class="btn btn-xs btn-secondary">Add</button>
						</div>
					</div>
					<script>
						$(document).ready(function () {
							$('##addElectronicAddressButton').click(function(evt){
								evt.preventDefault;
								addElectronicAddressToAgent(#agent_id#,'new_eaddress','new_eaddress_type',reloadElectronicAddresses);
							});
						});
					</script>
				</div>
			<cfcatch>
				<h2>Error: #cfcatch.type# #cfcatch.message#</h2> 
				<div>#cfcatch.detail#</div>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="eaddrThread" />
	<cfreturn eaddrThread.output>
</cffunction>

<!--- given an agent and an email/phone, add the electronic address to the agent
 @param agent_id the agent for which to add the electronic address.
 @param address_typ the value for the type of electronic address to add.
 @param address the value for the electronic address to add.
 @return a json result containing status=1 and a message on success, otherwise a http 500 status with message.
--->
<cffunction name="addElectronicAddressToAgent" returntype="any" access="remote" returnformat="json">
	<cfargument name="agent_id" type="string" required="yes">
	<cfargument name="address_type" type="string" required="yes">
	<cfargument name="address" type="string" required="yes">

	<cfset theResult=queryNew("status, message")>
	<cftransaction>
		<cftry>
			<cfquery name="newElectronicAddress" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="newElectronicAddress_result" >
				INSERT INTO electronic_address (
					agent_id
					,address_type
				 	,address
				 ) VALUES (
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
					,<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#address_type#'>
				 	,<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#address#'>
				)
			</cfquery>
			<cfif newElectronicAddress_result.recordcount EQ 1>
				<cfset t = queryaddrow(theResult,1)>
				<cfset t = QuerySetCell(theResult, "status", "1", 1)>
				<cfset t = QuerySetCell(theResult, "message", "Electronic Address added.", 1)>
			<cfelse>
				<cfthrow message="Unable to insert electronic address, other than one [#newElectronicAddress_result.recordcount#] address would be created.">
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
	<cfreturn #theResult#>
</cffunction>

<!--- given an agent and an update to an email/phone, update the electronic address to the agent
 @param electronic_address_id the electronic address to update
 @param address_type the new value for the type of electronic address
 @param address the new value for the electronic address
 @return a json result containing status=1 and a message on success, otherwise a http 500 status with message.
--->
<cffunction name="updateElectronicAddress" returntype="any" access="remote" returnformat="json">
	<cfargument name="electronic_address_id" type="string" required="yes">
	<cfargument name="address_type" type="string" required="yes">
	<cfargument name="address" type="string" required="yes">

	<cfset theResult=queryNew("status, message")>
	<cftransaction>
		<cftry>
			<cfquery name="updateElectronicAddress" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="updateElectronicAddress_result">
				UPDATE electronic_address SET
					address_type = <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#address_type#'>,
					address = <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#address#'>
				where
					electronic_address_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#electronic_address_id#">
			</cfquery>
			<cfif updateElectronicAddress_result.recordcount EQ 1>
				<cfset t = queryaddrow(theResult,1)>
				<cfset t = QuerySetCell(theResult, "status", "1", 1)>
				<cfset t = QuerySetCell(theResult, "message", "Electronic Address updated.", 1)>
			<cfelse>
				<cfthrow message="Unable to delete electronic address, other than one [#updateElectronicAddress_result.recordcount#] address would be affected.">
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
	<cfreturn #theResult#>
</cffunction>

<!--- given an agent and an electronic address, delete the electronic address.
 @param agent_id the agent for which to delete the electronic address.
 @param address the value for the electronic address to be deleted.
 @param address_type the value for the type of electronic address to be deleted.
 @return a json result containing status=1 and a message on success, otherwise a http 500 status with message.
--->
<cffunction name="deleteElectronicAddress" returntype="any" access="remote" returnformat="json">
	<cfargument name="electronic_address_id" type="string" required="yes">

	<cfset theResult=queryNew("status, message")>
	<cftransaction>
		<cftry>
			<cfquery name="deleteElectronicAddress" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="deleteElectronicAddress_result">
				delete from electronic_address 
				where
					electronic_address_id=<cfqueryparam cfsqltype='CF_SQL_DECIMAL' value='#electronic_address_id#'>
			</cfquery>
			<cfif deleteElectronicAddress_result.recordcount EQ 1>
				<cfset t = queryaddrow(theResult,1)>
				<cfset t = QuerySetCell(theResult, "status", "1", 1)>
				<cfset t = QuerySetCell(theResult, "message", "Address deleted.", 1)>
			<cfelse>
				<cfthrow message="Unable to delete electronic address, other than one [#deleteElectronicAddress_result.recordcount#] address would be affected.">
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
	<cfreturn #theResult#>
</cffunction>

<!--- obtain a block of html for displaying and editing names of an agent
 @param agent_id the agent for which to lookup names
 @return a block of html containing a list of names with controls to remove or add names
  assuming this block will go within a section with a heading.
--->
<cffunction name="getAgentNamesHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="agent_id" type="string" required="yes">
	<cfthread name="namesThread">
		<cfoutput>
			<cftry>
				<!--- preferred name --->
				<cfquery name="preferredName" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="preferredName_result">
					SELECT
						agent_name.agent_name_id,
						agent_id,
						agent_name_type,
						agent_name,
						count(publication_id) as publication_count
					FROM agent_name
						left outer join publication_author_name on agent_name.agent_name_id = publication_author_name.agent_name_id
					WHERE agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
						and  agent_name_type = 'preferred'
					GROUP BY
						agent_name.agent_name_id,
						agent_id,
						agent_name_type,
						agent_name
				</cfquery>
				<form id="preferredNameForm">
					<!--- edit preferred name only in single place above, where edit field is tied to duplicate check --->
					<ul class="list-group list-group-horizontal form-row mx-0">
						<input type="hidden" name="agent_name_id" id="preferred_name_agent_name_id" value="#preferredName.agent_name_id#">
						<input type="hidden" name="agent_name_type" id="preferred_name_agent_name_type" value="#preferredName.agent_name_type#">
						<li class="list-group-item px-0">
							<label for="preferred_name_display" class="data-entry-label mb-0 mt-1 font-weight-bold">Preferred Name</label>
						</li>
						<li class="list-group-item px-0 col-12 col-md-7">	
							<div class="col-12 bg-light border non-field-text">
								<span id="preferred_name_display">#encodeForHtml(preferredName.agent_name)#</span>
							</div>
						</li>
						<li class="list-group-item px-1">
							<span id="prefAgentNameFeedback"></span>
						</li>
					</ul>
				</form>
				<!--- other names --->
				<cfquery name="notPrefName" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="notPrefName_result">
					SELECT distinct
						agent_name.agent_name_id,
						agent_id,
						agent_name_type,
						agent_name,
						count(publication_id) as publication_count
					FROM agent_name
						left outer join publication_author_name on agent_name.agent_name_id = publication_author_name.agent_name_id
					WHERE agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
						and  agent_name_type <> 'preferred'
					GROUP BY
						agent_name.agent_name_id,
						agent_id,
						agent_name_type,
						agent_name
				</cfquery>
				<h3 class="h4 mt-2 mb-0">Other Names</h3>
				<label class="data-entry-label mb-0 sr-only">Other Names</label>
				<span class="hints text-success small px-1">(add a space between initials for all forms with two initials)</span>
				<cfquery name="ctNameType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select agent_name_type 
					from ctagent_name_type 
					where agent_name_type != 'preferred' 
					order by agent_name_type
				</cfquery>
				<cfif notPrefName.recordcount EQ 0 >
					<ul class="list-group list-unstyled list-group-horizontal mx-0 form-row">
						<li class="list-group-item">No other names</li>
					</ul>
				<cfelse>
					<cfset i=0>
					<cfloop query="notPrefName">
						<cfset i=i+1>
						<form id="agentNameForm_#i#">
							<ul class="list-group list-group-horizontal mx-0 form-row">
								<li class="list-group-item px-0">
									<input type="hidden" name="agent_name_id" value="#notPrefName.agent_name_id#" id="agent_name_id_#i#">
									<input type="hidden" name="agent_id" value="#notPrefName.agent_id#">
									<select name="agent_name_type" id="agent_name_type_#i#" class="data-entry-select">
										<cfloop query="ctNameType">
											<option  <cfif ctNameType.agent_name_type IS "#notPrefName.agent_name_type#"> selected="selected" </cfif>
												value="#ctNameType.agent_name_type#">#ctNameType.agent_name_type#</option>
										</cfloop>
									</select>
								</li>
								<li class="list-group-item px-0">
									<input type="text" value="#notPrefName.agent_name#" name="agent_name" id="agent_name_#i#" class="data-entry-input">
								</li>
								<li class="list-group-item px-1">
									<button type="button" id="agentNameU#i#Button" value="Update" class="btn btn-xs btn-secondary" >Update</button>
								</li>
								<li class="list-group-item px-0">
									<cfif notPrefName.publication_count GT 0 >
										<span>Publication Author</span>
									<cfelse>
										<button type="button" id="agentNameDel#i#Button" value="Delete" class="btn btn-xs btn-danger">Delete</button>
									</cfif>
									<span id="agentNameFeedback#i#"></span>
								</li>
							</ul>
						</form>
						<script>
							function doDeleteAgentName_#i#() { 
								deleteAgentName('agent_name_id_#i#',reloadAgentNames);
							};
							$(document).ready(function () {
								$('##agentNameU#i#Button').click(function(evt){
									evt.preventDefault;
									saveAgentName(#agent_id#, 'agent_name_id_#i#','agent_name_#i#','agent_name_type_#i#','agentNameFeedback#i#');
								});
							});
							$(document).ready(function () {
								$('##agentNameDel#i#Button').click(function(evt){
									evt.preventDefault;
									confirmWarningDialog("Delete the name #encodeForHTML(notPrefName.agent_name)# ?", "Confirm Delete?", doDeleteAgentName_#i#);
								});
							});
						</script>
					</cfloop>
				</cfif>
				<div class="row">
					<div id="newAgentNameDiv" class="col-12">
						<label for="new_agent_name" class="h4 pt-1">Add agent name</label>
						<form id="newNameForm" class="form-row">
							<input type="hidden" name="agent_id" id="new_agent_name_agent_id" value="#agent_id#">
							<div class="col-12 col-md-4">
								<select name="agent_name_type" onchange="suggestName(this.value,'new_agent_name');" id="new_agent_name_type" class="data-entry-select">
									<cfloop query="ctNameType">
										<option value="#ctNameType.agent_name_type#">#ctNameType.agent_name_type#</option>
									</cfloop>
								</select>
							</div>
							<div class="col-12 col-md-5">
								<input type="text" name="agent_name" id="new_agent_name" readonly autocomplete="off" onfocus="this.removeAttribute('readonly');" class="data-entry-input">
							</div>
							<div class="col-12 col-md-3 mt-1 mt-md-0">
								<button type="button" id="addAgentButton" class="btn btn-xs btn-secondary" value="Add Name">Add Name</button>
							</div>
						</form>
						<script>
							$(document).ready(function () {
								$('##addAgentButton').click(function(evt){
									evt.preventDefault;
									addNameToAgent(#agent_id#,'new_agent_name','new_agent_name_type',reloadAgentNames);
								});
							});
						</script>
					</div>
				</div>
			<cfcatch>
				<h2>Error: #cfcatch.type# #cfcatch.message#</h2> 
				<div>#cfcatch.detail#</div>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="namesThread" />
	<cfreturn namesThread.output>
</cffunction>

<!--- given an agent and a name, add the name to the agent
 @param agent_id the agent to which to add the name.
 @param agent_name the name to add to the agent
 @param agent_name_type the type of name to add.
 @return a json result containing status=1 and a message on success, otherwise a http 500 status with message.
--->
<cffunction name="addNameToAgent" returntype="any" access="remote" returnformat="json">
	<cfargument name="agent_id" type="string" required="yes">
	<cfargument name="agent_name" type="string" required="yes">
	<cfargument name="agent_name_type" type="string" required="yes">

	<cfset theResult=queryNew("status, message, agent_name_id")>
	<cftransaction>
		<cftry>
			<cfquery name="newId" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="newId_result">
				SELECT sq_agent_name_id.nextval as id FROM dual
			</cfquery>
			<cfset new_agent_name_id = newId.id>
			<cfquery name="updateName" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="updateName_result">
				INSERT INTO agent_name (
					agent_name_id,
					agent_id,
					agent_name_type,
					agent_name)
				VALUES (
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#new_agent_name_id#">,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">,
					<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#agent_name_type#'>,
					<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#agent_name#'>)
			</cfquery>
			<cfif updateName_result.recordcount eq 1>
				<cfset t = queryaddrow(theResult,1)>
				<cfset t = QuerySetCell(theResult, "status", "1", 1)>
				<cfset t = QuerySetCell(theResult, "message", "Name added to Agent.", 1)>
				<cfset t = QuerySetCell(theResult, "agent_name_id", "#new_agent_name_id#", 1)>
			<cfelse>
				<cfthrow message="Error adding name to agent.">
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
	<cfreturn #theResult#>
</cffunction>

<!--- given an agent name, update the name of the agent
 @param agent_name_id the name to update.
 @param agent_name the new value of the agent name
 @param agent_name_type the new value of the agent name type
 @return a json result containing status=1 and a message on success, otherwise a http 500 status with message.
--->

<cffunction name="updateAgentName" returntype="any" access="remote" returnformat="json">
	<cfargument name="agent_name_id" type="string" required="yes">
	<cfargument name="agent_name" type="string" required="yes">
	<cfargument name="agent_name_type" type="string" required="yes">

	<cfset theResult=queryNew("status, message")>
	<cftransaction>
		<cftry>
			<cfset provided_agent_name_type = agent_name_type>
			<cfquery name="checkName" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT agent_name_type 
				FROM agent_name 
				WHERE
					agent_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_name_id#">
			</cfquery>
			<cfif provided_agent_name_type EQ 'preferred' and checkName.agent_name_type NEQ 'preferred'>
				<cfthrow message="you can't change a preferred name to a different name type.">
			</cfif>
			<cfquery name="updateName" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="updateName_result">
				UPDATE agent_name
				SET
					agent_name = <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#agent_name#'>,
					agent_name_type=<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#agent_name_type#'>
				WHERE
					agent_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_name_id#">
			</cfquery>
			<cfif updateName_result.recordcount eq 1>
				<cfset t = queryaddrow(theResult,1)>
				<cfset t = QuerySetCell(theResult, "status", "1", 1)>
				<cfset t = QuerySetCell(theResult, "message", "Name updated for Agent.", 1)>
			<cfelse>
				<cfthrow message="Error updating agent name.">
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
	<cfreturn #theResult#>
</cffunction>

<!--- given an agent name, delete the agent name.
 @param agent_name_id the name to delete
 @return a json result containing status=1 and a message on success, otherwise a http 500 status with message.
--->
<cffunction name="deleteAgentName" returntype="any" access="remote" returnformat="json">
	<cfargument name="agent_name_id" type="string" required="yes">

	<cfset theResult=queryNew("status, message")>
	<cftransaction>
		<cftry>
			<cfquery name="checkName" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT agent_name_type 
				FROM agent_name 
				WHERE
					agent_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_name_id#">
			</cfquery>
			<cfif checkName.agent_name_type EQ 'preferred'>
				<cfthrow message="the preferred name for an agent cannot be deleted.">
			</cfif>
			<!--- Check if this name is in use by any tables that link to an agent_name. --->
			<!--- TODO: This should be enforced by foreign keys --->
			<cfquery name="delId" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT
					PROJECT_AGENT.AGENT_NAME_ID,
					PUBLICATION_AUTHOR_NAME.AGENT_NAME_ID,
					project_sponsor.AGENT_NAME_ID
				FROM
					PROJECT_AGENT,
					PUBLICATION_AUTHOR_NAME,
					project_sponsor,
					agent_name
				WHERE
					agent_name.agent_name_id = PROJECT_AGENT.AGENT_NAME_ID (+) and
					agent_name.agent_name_id = PUBLICATION_AUTHOR_NAME.AGENT_NAME_ID (+) and
					agent_name.agent_name_id = project_sponsor.AGENT_NAME_ID (+) and
					agent_name.agent_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_name_id#">
			</cfquery>
			<cfif #delId.recordcount# gt 1>
				<cfthrow message="The agent name you are trying to delete is active in a project or publication.">
			</cfif>
			<cfquery name="deleteAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="deleteAgent_result">
				DELETE FROM agent_name
				WHERE 
					agent_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_name_id#">
			</cfquery>
			<cfif deleteAgent_result.recordcount eq 1>
				<cfset t = queryaddrow(theResult,1)>
				<cfset t = QuerySetCell(theResult, "status", "1", 1)>
				<cfset t = QuerySetCell(theResult, "message", "Name deleted.", 1)>
			<cfelse>
				<cfthrow message="Error deleting agent name.">
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
	<cfreturn #theResult#>
</cffunction>


<!--- obtain a block of html for displaying and editing members of a group agent 
 @param agent_id the agent for which to lookup group information 
 @return a block of html containing a list of group members with controls to remove or add members 
  assuming this block will go within a section with a heading.
--->
<cffunction name="getGroupMembersHTML" returntype="string" access="remote" returnformat="plain">
	<cfargument name="agent_id" type="string" required="yes">
	<cfthread name="groupMembersThread">
		<cfoutput>
			<cftry>
				<cfquery name="lookupAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="lookupAgent_result">
					SELECT agent_type, agent_id
					FROM agent
					WHERE agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
				</cfquery>
				<cfloop query="lookupAgent">
					<cfif #lookupAgent.agent_type# IS "group" OR #lookupAgent.agent_type# IS "expedition" OR #lookupAgent.agent_type# IS "vessel">
						<cfquery name="groupMembers" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="groupMembers_result">
							SELECT
								group_agent_id,
								member_agent_id,
								member_order,
								preferred_agent_name.agent_name,
								substr(birth_date,0,4) as birth_date,
								substr(death_date,0,4) as death_date,
								MCZBASE.get_collectorscope(agent.agent_id,'collections') as collections_scope,
								decode(agent.edited,1,'*',null) as vetted
							FROM
								group_member 
								left join preferred_agent_name on group_member.MEMBER_AGENT_ID = preferred_agent_name.agent_id
								left join agent on group_member.member_agent_id = agent.agent_id
								left join person on group_member.member_agent_id = person.person_id
							WHERE
								group_agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
							ORDER BY
								member_order
						</cfquery>
						<cfif groupMembers.recordcount EQ 0>
							<ul class="list-group list-group-horizontal">
								<li class="list-group-item">None</li>
							</ul>
						<cfelse>
							<cfset yearRange = assembleYearRange(start_year="#groupMembers.birth_date#",end_year="#groupMembers.death_date#",year_only=true)>
							<cfset i = 0>
							<cfloop query="groupMembers">
								<cfset i = i + 1>
								<ul class="list-group list-group-horizontal form-row mx-0">
									<li class="list-group-item px-0">
										<a href="/agents/Agent.cfm?agent_id=#groupMembers.member_agent_id#">#groupMembers.agent_name#</a>
										#vetted# #yearRange# #collections_scope#
										<a class="btn btn-xs btn-warning ml-2" type="button" id="removeAgentFromGroup_#i#" 
											onclick=' confirmDialog("Remove this agent from this group?", "Confirm Remove Group Member", function() { removeAgentFromGroupCB(#groupMembers.group_agent_id#,#groupMembers.member_agent_id#,reloadGroupMembers); } ); '>Remove</a>
										<cfif groupMembers.recordcount GT 1>
											<cfif i EQ 1>
												<button class="btn btn-xs btn-secondary disabled" type="button" id="moveGroupAgentUp_#i#" disabled>Move Up</button>
											<cfelse>
												<a class="btn btn-xs btn-secondary" type="button" id="moveGroupAgentUp_#i#" 
													onclick="moveAgentInGroupCB(#groupMembers.group_agent_id#,#groupMembers.member_agent_id#,'decrement',reloadGroupMembers);">Move Up</a>
											</cfif>
											<cfif i EQ groupMembers.recordcount>
												<button class="btn btn-xs btn-secondary disabled" type="button" id="moveGroupAgentDown_#i#" disabled>Move Down</button>
											<cfelse>
												<a class="btn btn-xs btn-secondary" type="button" id="moveGroupAgentDown_#i#" 
													onclick="moveAgentInGroupCB(#groupMembers.group_agent_id#,#groupMembers.member_agent_id#,'increment',reloadGroupMembers);">Move Down</a>
											</cfif>
										</cfif>
									</li>
								</ul>
							</cfloop>
						</cfif>
						<div>
						<div class="row">
							<div class="col-12">
								<form name="newGroupMember" class="form-row">
									<div class="col-12 col-md-12">
										<label for="new_group_agent_name" id="new_group_agent_name_label" class="h4">Add Member To Group
											<h5 id="new_group_agent_view" class="d-inline">&nbsp;&nbsp;&nbsp;&nbsp;</h5> 
										</label>
									</div>
									<div class="col-12 col-md-6">
										<div class="input-group">
											<div class="input-group-prepend">
												<span class="input-group-text smaller bg-lightgreen" id="new_group_agent_name_icon"><i class="fa fa-user" aria-hidden="true"></i></span> 
											</div>
											<input type="text" name="new_group_agent_name" id="new_group_agent_name" class="reqdClr form-control rounded-right data-entry-input form-control-sm" aria-label="Agent Name" aria-describedby="new_group_agent_name_label" value="" >
											<input type="hidden" name="new_member_agent_id" id="new_member_agent_id" value="">
										</div>
									</div>
									<script>
										$(document).ready(function() {
											$(makeRichAgentPicker('new_group_agent_name', 'new_member_agent_id', 'new_group_agent_name_icon', 'new_group_agent_view', null));
										});
									</script>
									<div class="col-12 col-md-5 pt-2 pt-md-0">
										<button type="button" id="addMemberButton" class="btn btn-xs btn-secondary" value="Add Group Member">Add Group Member</button>
									</div>
								</form>
							</div>
							<script>
								$(document).ready(function() {
									$('##addMemberButton').click(function (evt) {
										evt.preventDefault();
										if ($("##new_member_agent_id").val() == "") { 
											messageDialog("Unable to save.  You must pick an agent name from the picklist.", "Unable to add group member.");
										} else {
											addAgentToGroupCB(#lookupAgent.agent_id#,$('##new_member_agent_id').val(),null,reloadGroupMembers);
										}
									});
								});
							</script>
						</div>
					</cfif>
				</cfloop>
			<cfcatch>
				<h2>Error: #cfcatch.type# #cfcatch.message#</h2> 
				<div>#cfcatch.detail#</div>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="groupMembersThread" />
	<cfreturn groupMembersThread.output>
</cffunction>

<!--- given a group and an agent, remove the agent from the group 
 @param agent_id the group agent from which to remove the member.
 @param member_agent_id the member agent to remove from the group 
 @return a json result containing status=1 and a message on success, otherwise a http 500 status with message.
--->
<cffunction name="removeAgentFromGroup" returntype="any" access="remote" returnformat="json">
	<cfargument name="agent_id" type="string" required="yes"><!--- the group agent --->
	<cfargument name="member_agent_id" type="string" required="yes"><!--- the member agent to remove from the group  --->

	<cfset theResult=queryNew("status, message, renumbered")>
	<cftransaction>
		<cftry>
			<cfquery name="getCurrentNum" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getCurrentNum_result">
				SELECT member_order
				FROM group_member
				WHERE
					GROUP_AGENT_ID =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
					AND
					MEMBER_AGENT_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#MEMBER_AGENT_ID#">
			</cfquery>
			<cfset removedMemberOrder = getCurrentNum.member_order>
			<cfquery name="removeGroupMember" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="removeGroupMember_result">
				DELETE FROM group_member
				WHERE
					GROUP_AGENT_ID =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
					AND
					MEMBER_AGENT_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#MEMBER_AGENT_ID#">
			</cfquery>
			<cfif removeGroupMember_result.recordcount eq 0>
				<cfthrow message="No agent removed from group. Group:[#encodeForHTML(agent_id)#] Member:[#encodeForHTML(member_agent_id)#] #removeGroupMember_result.sql#" >
			</cfif>
			<cfif removeGroupMember_result.recordcount eq 1>
				<cfquery name="moveDown" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="moveDown_result">
					UPDATE group_member
					SET member_order = member_order - 1
					WHERE
						GROUP_AGENT_ID =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
						AND
						MEMBER_ORDER > <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#removedMemberOrder#">
				</cfquery>
				<cfset t = queryaddrow(theResult,1)>
				<cfset t = QuerySetCell(theResult, "status", "1", 1)>
				<cfset t = QuerySetCell(theResult, "message", "Agent Removed From Group.", 1)>
				<cfset t = QuerySetCell(theResult, "renumbered", "#moveDown_result.recordcount#", 1)>
				<cftransaction action="commit">
			</cfif>
		<cfcatch>
			<cftransaction action="rollback">
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	<cftransaction>
	<cfreturn #theResult#>
</cffunction>

<!--- given a group and an agent, add the agent from the group as a member
 @param agent_id the group agent from which to remove the member.
 @param member_agent_id the member agent to remove from the group 
 @return a json result containing status=1 and a message on success, otherwise a http 500 status with message.
--->
<cffunction name="addAgentToGroup" returntype="any" access="remote" returnformat="json">
	<cfargument name="agent_id" type="string" required="yes"><!--- the group agent --->
	<cfargument name="member_agent_id" type="string" required="yes"><!--- the member agent to add to the group  --->
	<cfargument name="member_order" type="string" required="no">

	<cfset theResult=queryNew("status, message")>
	<cftransaction>
		<cftry>
			<cfif NOT isdefined("member_order") OR len(member_order) EQ 0>
				<cfquery name="getMaxOrder" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getMaxOrder_result">
					SELECT nvl(max(member_order),0) as max_order
					FROM group_member
					WHERE
						GROUP_AGENT_ID =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
				</cfquery>
				<cfset currentMax = 0 >
				<cfloop query="getMaxOrder">
					<cfset currentMax = getMaxOrder.max_order >
				</cfloop>
				<cfset member_order = currentMax + 1>
			</cfif>
			<cfquery name="getAgentType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getAgentType_result">
				SELECT agent_type 
				FROM agent
				WHERE
					agent_id =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
			</cfquery>
			<!--- Test that group agent specfied is an agent type that allows members --->
			<cfif getAgentType.recordcount NEQ 1>
				<cfthrow message="Group agent (agent_id=[#encodeForHTML(agent_id)#] not found, unable to add members.">
			</cfif>
			<cfloop query="getAgentType">
				<cfif #getAgentType.agent_type# IS "group" OR #getAgentType.agent_type# IS "expedition" OR #getAgentType.agent_type# IS "vessel">
					<cfquery name="addGroupMember" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="addGroupMember_result">
						INSERT INTO group_member
							(GROUP_AGENT_ID,
							MEMBER_AGENT_ID,
							MEMBER_ORDER)
						values
							(<cfqueryparam cfsqltype='CF_SQL_DECIMAL' value='#agent_id#'>,
							<cfqueryparam cfsqltype='CF_SQL_DECIMAL' value='#member_agent_id#'>,
							<cfqueryparam cfsqltype='CF_SQL_DECIMAL' value='#member_order#'>
						)
					</cfquery>
				<cfelse>
					<cfthrow message="Unable to add member, provided group agent (agent_id=[#encodeForHTML(agent_id)#] is a #getAgentType.agent_type#, but it must be a group, expedition, or vessel to take members.">
				</cfif>
				<cfif addGroupMember_result.recordcount eq 0>
					<cfthrow message="No agent added to group. Group:[#encodeForHTML(agent_id)#] Member:[#encodeForHTML(member_agent_id)#] #removeGroupMember_result.sql#" >
				</cfif>
				<cfif addGroupMember_result.recordcount eq 1>
					<cfset t = queryaddrow(theResult,1)>
					<cfset t = QuerySetCell(theResult, "status", "1", 1)>
					<cfset t = QuerySetCell(theResult, "message", "Agent Added To Group.", 1)>
				</cfif>
			</cfloop>
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
	<cfreturn #theResult#>
</cffunction>

<!--- given a group and an agent, move the agent in ordered position in a specified direction.
 @param agent_id the group agent from which to remove the member.
 @param member_agent_id the member agent to remove from the group 
 @param direction decrement to move to next lowest number, increment to move to next highest number
 @return a json result containing status=1 and a message on success, otherwise a http 500 status with message.
--->
<cffunction name="moveAgentInGroup" returntype="any" access="remote" returnformat="json">
	<cfargument name="agent_id" type="string" required="yes">
	<cfargument name="member_agent_id" type="string" required="yes">
	<cfargument name="direction" type="string" required="yes">

	<cfset theResult=queryNew("status, message")>
	<cftransaction>
		<cftry>
			<cfquery name="getMaxOrder" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getMaxOrder_result">
				SELECT max(member_order) as max_order
				FROM group_member
				WHERE
					GROUP_AGENT_ID =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
			</cfquery>
			<cfset maxPos = 0>
			<cfloop query="getMaxOrder">
				<cfset maxPos = getMaxOrder.max_order >
			</cfloop>
			<cfquery name="getCurrentPosition" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getCurrentPosition_result">
				SELECT member_order
				FROM group_member
				WHERE
					GROUP_AGENT_ID =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
					AND
					MEMBER_AGENT_ID =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#member_agent_id#">
			</cfquery>
			<cfloop query="getCurrentPosition">
				<cfset currentPos = getCurrentPosition.member_order >
			</cfloop>
			<cfif direction EQ "decrement">
				<cfset targetPos = currentPos-1>
				<cfif targetPos LT 1>
					<cfset targetPos = maxPos>
				</cfif>
			<cfelseif direction EQ "increment">
				<cfset targetPos = currentPos+1>
				<cfif targetPos GT maxPos>
					<cfset targetPos = 1>
				</cfif>
			<cfelse>
				<cfthrow message="unknown direction [#encodeForHTML(direction)#]">
			</cfif>
			<cfquery name="moveAgentTwo" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="moveAgentTwo_result">
				UPDATE group_member
				SET MEMBER_ORDER = <cfqueryparam cfsqltype='CF_SQL_DECIMAL' value='#currentPos#'>
				WHERE
					GROUP_AGENT_ID =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
					AND
					MEMBER_ORDER = <cfqueryparam cfsqltype='CF_SQL_DECIMAL' value='#targetPos#'>
			</cfquery>
			<cfquery name="moveAgentOne" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="moveAgentOne_result">
				UPDATE group_member
				SET MEMBER_ORDER = <cfqueryparam cfsqltype='CF_SQL_DECIMAL' value='#targetPos#'>
				WHERE
					GROUP_AGENT_ID =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
					AND
					MEMBER_AGENT_ID =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#member_agent_id#">
			</cfquery>
			<cfif moveAgentOne_result.recordcount EQ 1 AND moveAgentTwo_result.recordcount EQ 1>
				<cfset t = queryaddrow(theResult,1)>
				<cfset t = QuerySetCell(theResult, "status", "1", 1)>
				<cfset t = QuerySetCell(theResult, "message", "Agent Moved in Group.", 1)>
			<cfelse>
				<cfthrow message="Unable to move agent position in group.  Error switching positions [#currentPos#][#targetPos#].">
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
	<cfreturn #theResult#>
</cffunction>

<!--- Given various information create dialog to create a new address or edit an existing address, 
 when creating a new address, by default a temporary address.
 @param agent_id if given, the agent for whom this is an address
 @param shipment_id if given, the shipment for which this address is to be used for
 @param create_from_address_id, if given, used to lookup the agent_id for whom this is an address for
 @param address_type shipping, mailing, or temporary, defaults to temporary if not provided.
 @param addr_id if provided, the address to edit, overrides other parameters if provided.
 @return html to populate a dialog
--->
<cffunction name="addAddressHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="agent_id" type="string" required="no"><!--- if given, the agent for whom this is an address, if not, select --->
	<cfargument name="shipment_id" type="string" required="no"><!--- if given, the address is used for this shipment --->
	<cfargument name="create_from_address_id" type="string" required="no"><!--- if given, use this address's agent for this address --->
	<cfargument name="address_type" type="string" required="no"><!--- use temporary to create a temporary address, otherwise shipping or mailing --->
	<cfargument name="addr_id" type="string" required="no">

	<cfthread name="createAddressThread">
		<cfoutput>
			<cftry>
				<cfif NOT isdefined("address_type") OR NOT len(#address_type#) GT 0>
					<cfset address_type = "temporary">
				</cfif>
				<cfif isdefined("create_from_address_id") AND (not isdefined("agent_id") AND len(agent_id) GT 0) >
					<!--- look up agent id from address --->
					<cfquery name="qAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select agent_id from addr where addr_id = <cfqueryparam value="#create_from_address_id#" CFSQLTYPE="CF_SQL_VARCHAR">
					</cfquery>
					<cfset agent_id = qAgent.agent_id >
				</cfif>
				<cfif isdefined("addr_id") and len(#addr_id#) GT 0>
					<cfquery name="lookupAddress" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="lookupAddress_result">
						SELECT 
							addr_id,
							street_addr1,
							street_addr2,
							institution,
							department,
							city,
							state,
							zip,
							country_cde,
							mail_stop,
							agent_id,
							addr_type,
							job_title,
							valid_addr_fg,
							addr_remarks,
							formatted_addr
						FROM addr
						WHERE
							addr_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#addr_id#">
					</cfquery>
					<cfif lookupAddress.recordcount NEQ 1>
						<cfthrow message="No address found for provided addr_id [#encodeForHTML(addr_id)#].">
					</cfif>
					<cfloop query="lookupAddress">
						<cfset addr_id = lookupAddress.addr_id>
						<cfset street_addr1 = lookupAddress.street_addr1>
						<cfset street_addr2 = lookupAddress.street_addr2>
						<cfset institution = lookupAddress.institution>
						<cfset department = lookupAddress.department>
						<cfset city = lookupAddress.city>
						<cfset state = lookupAddress.state>
						<cfset zip = lookupAddress.zip>
						<cfset country_cde = lookupAddress.country_cde>
						<cfset mail_stop = lookupAddress.mail_stop>
						<cfset agent_id = lookupAddress.agent_id>
						<cfset address_type = lookupAddress.addr_type>
						<cfset job_title = lookupAddress.job_title>
						<cfset valid_addr_fg = lookupAddress.valid_addr_fg>
						<cfset addr_remarks = lookupAddress.addr_remarks>
						<cfset formatted_addr = replace(lookupAddress.formatted_addr,CHR(10),"<br>","All")>
						<cfset method = "updateAddress">
					</cfloop>
				<cfelse>
						<cfset addr_id = "">
						<cfset street_addr1 = "">
						<cfset street_addr2 = "">
						<cfset institution = "">
						<cfset department = "">
						<cfset city = "">
						<cfset state = "">
						<cfset zip = "">
						<cfset country_cde = "">
						<cfset mail_stop = "">
						<cfset job_title = "">
						<cfset valid_addr_fg = 0>
						<cfset addr_remarks = "">
						<cfset formatted_addr = "">
						<cfset method = "addNewAddress">
				</cfif>
				<cfquery name="ctAddrType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select addr_type from ctaddr_type where addr_type = <cfqueryparam value="#address_type#" CFSQLTYPE="CF_SQL_VARCHAR">
				</cfquery>
				<cfif ctAddrType.addr_type IS ''>
					<cfthrow message="Provided address type [#encodeForHTML(address_type)#] is unknown.">
				<cfelse>
					<cfset agent_name ="">
					<cfif isdefined("agent_id") AND len(agent_id) GT 0 >
						<cfquery name="query" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							SELECT agent_name 
							FROM preferred_agent_name 
							WHERE
							agent_id = <cfqueryparam value="#agent_id#" cfsqltype="CF_SQL_DECIMAL">
						</cfquery>
						<cfif query.recordcount gt 0>
							<cfset agent_name = query.agent_name>
						</cfif>
					</cfif>
					<div class="form-row mx-0 my-1">
						<div class="col-12 border p-2 rounded bg-light" id="formattedAddressDisplayDiv">#formatted_addr#</div>
					</div>
					<div class="form-row">
						<div class="col-12">
							<form name='newAddress' id='newAddressForm'>
								<cfif not isdefined("agent_id")><cfset agent_id = ""></cfif>
								<input type='hidden' name='method' value='#method#'>
								<input type='hidden' name='returnformat' value='json'>
								<input type='hidden' name='queryformat' value='struct'>
								<input type='hidden' name='addr_type' value='#address_type#'>
								<cfif len(addr_id) GT 0>
									<input type='hidden' name='addr_id' value='#addr_id#'>
								</cfif>
								<div class='form-row'>
									<div class='col-12 col-md-6 my-1'>
										<strong>Address Type:</strong> #ctAddrType.addr_type#
									</div>
									<div class='col-12 col-md-6 my-1'>
										<cfif len(agent_name) GT 0 >
											<strong>Address For:</strong> #agent_name#
											<input type="hidden" name="agent_id" id="addr_agent_id" value="#agent_id#" >
										<cfelse>
											<span>
												<label for="addr_agent_name" class="data-entry-label">Address For:</label>
												<span id="addr_agent_view">&nbsp;&nbsp;&nbsp;&nbsp;</span>
											</span>
											<div class="input-group">
												<div class="input-group-prepend">
													<span class="input-group-text smaller bg-lightgreen" id="addr_agent_icon"><i class="fa fa-user" aria-hidden="true"></i></span> 
												</div>
												<input name="agent_name" id="addr_agent_name" class="reqdClr form-control form-control-sm data-entry-input" required style="z-index: 120; position: relative;" >
											</div>
											<input type="hidden" name="agent_id" id="addr_agent_id" >
											<script>
												$(makeRichTransAgentPicker('addr_agent_name', 'addr_agent_id','addr_agent_icon','addr_agent_view',null))
											</script> 
										</cfif>
									</div>
								</div>
								<cfif address_type EQ "temporary">
									<input type='hidden' name='valid_addr_fg' id='valid_addr_fg' value='0'>
									<input type="hidden" name="job_title" id="job_title" class="data-entry-input" value="">
								<cfelse>
									<div class='form-row'>
										<div class='col-12 col-md-6 my-1'>
											<label for="valid_addr_fg">Valid?</label>
												<select name="valid_addr_fg" id="valid_addr_fg" class="data-entry-select">
													<cfif valid_addr_fg EQ 1><cfset selected="selected"><cfelse><cfset selected=""></cfif>
													<option value="1" #selected#>yes</option>
													<cfif valid_addr_fg EQ 0><cfset selected="selected"><cfelse><cfset selected=""></cfif>
													<option value="0" #selected#>no</option>
											</select>
										</div>
										<div class='col-12 col-md-6 my-1'>
											<label for="job_title" class="data_entry_label">Job Title</label>
											<input type="text" name="job_title" id="job_title" class="data-entry-input" value="#job_title#">
										</div>
									</div>
								</cfif>
								<div class='form-row'>
									<div class='col-12 col-md-6 my-1'>
										<label for='institution' class="data-entry-label">Institution</label>
										<input type='text' name='institution' id='institution'class="form-control data-entry-input" value="#institution#" >
									</div>
									<div class='col-12 col-md-6 my-1'>
										<label for='department' class="data-entry-label">Department</label>
										<input type='text' name='department' id='department' class="form-control data-entry-input" value="#department#" >
									</div>
								</div>
								<div class='form-row'>
									<div class='col-12 my-1'>
										<label for='street_addr1' class="data-entry-label">Street Address 1</label>
										<input type='text' name='street_addr1' id='street_addr1' class='reqdClr form-control data-entry-input' value="#street_addr1#" required>
									</div>
								</div>
								<div class='form-row'>
									<div class='col-12 my-1'>
										<label for='street_addr2'>Street Address 2</label>
										<input type='text' name='street_addr2' id='street_addr2' class="form-control data-entry-input" value="#street_addr2#">
									</div>
								</div>
								<div class='form-row'>
									<div class='col-12 col-md-6 my-2'>
										<label for='city' class="data-entry-label">City</label>
										<input type='text' name='city' id='city' class='reqdClr form-control data-entry-input' value="#city#" required>
									</div>
									<div class='col-12 col-md-6 my-2'>
										<label for='state' class="data-entry-label">State/Province</label>
										<input type='text' name='state' id='state' class='form-control data-entry-input' value="#state#">
									</div>
								</div>
								<div class='form-row'>
									<div class='col-12 col-md-4 my-1'>
										<label for='zip' class="data-entry-label">Zip/Postcode</label>
										<input type='text' name='zip' id='zip' class='form-control data-entry-input' value="#zip#" >
									</div>
									<div class='col-12 col-md-8 my-1'>
										<script>
											function handleCountrySelect(){
												var countrySelection = $('input:radio[name=country]:checked').val();
												if (countrySelection == 'USA') {
													$("##textUS").css({"color": "black", "font-weight":"bold" });
													$("##other_country_cde").toggle(false);
													$("##country_cde").val("USA");
													$("##other_country_cde").removeClass("reqdClr");
													$('##other_country_cde').removeAttr('required');
													$("##state").addClass("reqdClr");
													$('##state').prop('required',true);
													$("##zip").addClass("reqdClr");
													$('##zip').prop('required',true);
												} else {
													$("##textUS").css({"color": "##999999", "font-weight": "normal" });
													$("##other_country_cde").toggle(true);
													$("##country_cde").val($("##other_country_cde").val());
													$("##other_country_cde").addClass("reqdClr");
													$('##other_country_cde').prop('required',true);
													$("##state").removeClass("reqdClr");
													$('##state').removeAttr('required');
													$("##zip").removeClass("reqdClr");
													$('##zip').removeAttr('required');
												}
											}
										</script>
										<label for="country_cde" class="data-entry-label">
											Country 
											<img src="/images/icon_info.gif" border="0" onclick="getMCZDocs('Country_Name_List')" style="margin-top: -10px;" alt="[ help ]">
										</label>
										<span class="data-entry-input form-control">
											<input type="hidden" name="country_cde" id="country_cde" value="USA" value="#country_cde#">
											<cfif country_cde EQ "USA"><cfset checked='checked="checked"'><cfelse><cfset checked=""></cfif>
											<input type="radio" name="country" value="USA" onclick="handleCountrySelect();" #checked# ><span id="textUS" style="color: black; font-weight: bold">&nbsp;USA</span>
											<cfif country_cde NEQ "USA"><cfset checked='checked="checked"'><cfelse><cfset checked=""></cfif>
											<input type="radio" name="country" value="other" onclick="handleCountrySelect();" #checked#><span id="textOther">&nbsp;Other</span>
											<input type="text" name="other_country_cde" id="other_country_cde" onblur=" $('##country_cde').val($('##other_country_cde').val());" style="display: none;"  value="#country_cde#">
										<span>
										<script>
											$(document).ready(function () {
												handleCountrySelect();
											});
										</script>
									</div>
								</div>
								<div class='form-row'>
									<div class='col-12 col-md-6 my-1'>
										<label for='mail_stop' class="data-entry-label">Mail Stop</label>
										<input type='text' name='mail_stop' id='mail_stop'class="form-control data-entry-input" value="#mail_stop#">
									</div>
									<div class='col-12 col-md-6 my-1'>
										<label for='addr_remarks' class="data-entry-label">Address Remark</label>
										<input type='text' name='addr_remarks' id='addr_remarks' class="form-control data-entry-input" value="#addr_remarks#">
									</div>
								</div>
								<div class='form-row'>
									<div class='col-12 col-md-6 my-2'>
										<cfif isdefined("addr_id") and len(#addr_id#) GT 0>
											<input type='submit' class='btn btn-xs btn-primary' value='Save Changes' >
											<cfset errmsg = "updating an address for an agent">
										<cfelse>
											<input type='submit' class='btn btn-xs btn-primary' value='Create Address' >
											<cfset errmsg = "adding an address to an agent">
										</cfif>
									</div>
									<div class='col-12 col-md-6 my-2'>
										<div id='newAddressStatus'></div>
									</div>
								</div>
								<script>
									$('##newAddressForm').submit( function (e) { 
										$.ajax({
											url: '/agents/component/functions.cfc',
											data : $('##newAddressForm').serialize(),
											success: function (result) {
												if (result[0].STATUS==1) { 
													$('##newAddressStatus').html(result[0].MESSAGE);
													$('##new_address_id').val(result[0].ADDRESS_ID);
													$('##new_address').val(result[0].ADDRESS);
													$('##tempAddressDialog').dialog('close');
													$('##formattedAddressDisplayDiv').html(result[0].ADDRESS.replace(/\n/g, "<br>"));
												} else { 
													$('##newAddressStatus').html(result[0].MESSAGE);
												}
											},
											error: function (jqXHR, textStatus, error) {
												handleFail(jqXHR,textStatus,error,"#errmsg#");
											},
											dataType: 'json'
										});
										e.preventDefault();
									});
								</script>
								<input type='hidden' name='new_address_id' id='new_address_id' value=''>
								<input type='hidden' name='new_address' id='new_address' value=''>
							</form>
						</div>
					</div>
				</cfif> <!--- known address type provided --->
			<cfcatch>
				<h2>Error: #cfcatch.type# #cfcatch.message#</h2> 
				<div>#cfcatch.detail#</div>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="createAddressThread" />
	<cfreturn createAddressThread.output>
</cffunction>


<cffunction name="saveAgent" access="remote" returntype="any" returnformat="json">
	<cfargument name="agent_id" type="string" required="yes">
	<cfargument name="agent_type" type="string" required="yes">
	<cfargument name="pref_name" type="string" required="no">

	<cfset data = ArrayNew(1)>
	<cfset provided_agent_type = agent_type >

	<cftransaction>
		<cftry>
			<cfquery name="lookupType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select agent_type as existing_agent_type
				from agent
				where agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
			</cfquery>
			<cfif lookupType.recordcount NEQ 1>
				<cfthrow message="Unable to lookup agent_type from provided agent_id [#encodeForHTML(agent_id)#]">
			</cfif>
			<cfquery name="lookupGroupMembers" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select count(*) as count_of_group_members
				from group_member
				where group_agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
			</cfquery>
			<cfif lookupType.existing_agent_type IS "group" OR lookupType.existing_agent_type IS "expedition" OR lookupType.existing_agent_type IS "vessel">
				<cfif lookupGroupMembers.count_of_group_members GT 0 AND NOT (provided_agent_type IS "group" OR provided_agent_type is "expedition" OR provided_agent_type IS "vessel")>
					<cfthrow message="Unable to convert agent type, agent has #lookupGroupMembers.count_of_group_members# group members and new type  [#encodeForHTML(provided_agent_type)#] does not support group members.">
				</cfif>
			</cfif>
			<cfset updateAgent = true>
			<cfset updatePerson = false>
			<cfset insertPerson = false>
			<cfset removePerson = false>
			<cfset convertFromPerson = false>
			<cfif lookupType.existing_agent_type IS "person" and provided_agent_type IS "person">
				<!--- update existing person and agent records --->
				<cfset updateAgent = true>
				<cfset updatePerson = true>
				<cfset insertPerson = false>
			<cfelseif lookupType.existing_agent_type IS NOT "person" and provided_agent_type IS NOT "person">
				<!--- update existing agent record --->
				<cfset updateAgent = true>
				<cfset updatePerson = false>
				<cfset insertPerson = false>
			<cfelseif lookupType.existing_agent_type IS NOT "person" and provided_agent_type IS "person">
				<!--- change a non-person to a person update existing agent record and insert a person record --->
				<cfset updateAgent = true>
				<cfset updatePerson = false>
				<cfset insertPerson = true>
			<cfelseif lookupType.existing_agent_type IS "person" and provided_agent_type IS NOT "person">
				<cfset updateAgent = true>
				<cfset updatePerson = true>
				<cfset convertFromPerson = true>
				<cfset removePerson = true>
				<cfif not isDefined("start_date")><cfset start_date=""></cfif>
				<cfif not isDefined("end_date")><cfset end_date=""></cfif>
			<cfelse>
				<!--- Catch errors --->
				<cfthrow message="unknown/unsupported conversion types">
			</cfif>
			<cfif convertFromPerson>
				<!--- check that a person record exists to be converted from --->
				<cfquery name="checkForPerson" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT count(*) ct
					FROM person 
					WHERE
						person_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
				</cfquery>
				<!--- gracefully handle error case of an agent typed as a person without a person record  --->
				<cfif checkForPerson.ct EQ 0>
					<cfset updatePerson = false>
				</cfif>
			</cfif>
			<!--- Note order of clauses for change from person: save any changes made to the person before extracting to store as remarks --->
			<cfif updatePerson>
				<!--- update existing person record --->
				<cfquery name="editPerson" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					UPDATE person SET
						person_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
				<cfif len(#first_name#) gt 0>
					,first_name=<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#first_name#'>
				<cfelse>
					,first_name=null
				</cfif>
				<cfif len(#prefix#) gt 0>
					,prefix=<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#prefix#'>
				<cfelse>
					,prefix=null
				</cfif>
				<cfif len(#middle_name#) gt 0>
					,middle_name=<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#middle_name#'>
				<cfelse>
					,middle_name=null
				</cfif>
				<cfif len(#last_name#) gt 0>
					,last_name=<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#last_name#'>
				<cfelse>
					,last_name=null
				</cfif>
				<cfif len(#suffix#) gt 0>
					,suffix=<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#suffix#'>
				<cfelse>
					,suffix=null
				</cfif>
				<cfif len(#start_date#) gt 0>
					,birth_date=<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#start_date#'>
				<cfelse>
					,birth_date=null
				</cfif>
				<cfif len(#end_date#) gt 0>
					,death_date=<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#end_date#'>
				<cfelse>
					,death_date=null
				</cfif>
					WHERE
						person_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
				</cfquery>
			</cfif>
			<cfif convertFromPerson>
				<!--- obtain person record, append name and birth/death to remarks --->
				<cfquery name="getPerson" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getPerson_result">
					SELECT
						PREFIX,
						LAST_NAME,
						FIRST_NAME,
						MIDDLE_NAME,
						SUFFIX,
						nvl(birth_date,to_char(BIRTH_DATE_DATE,'yyyy-mm-dd')) as birth,
						nvl(death_date,to_char(DEATH_DATE_DATE,'yyyy-mm-dd')) as death
					FROM person
					WHERE person_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
				</cfquery>
				<cfloop query="getPerson">
					<cfset name = "#prefix# #first_name# #middle_name# #last_name# #suffix#">
					<cfset name = trim(replace(name,"  "," ", "all"))>
					<cfset remark = "Agent converted from agent of type person with name [#name#]">
					<cfif len(birth) GT 0>
						<cfset remark = "#remark# Birth Date [#birth#]">
					</cfif>
					<cfif len(death) GT 0>
						<cfset remark = "#remark# Death Date [#death#]">
					</cfif>
					<cfset remark="#remark#.">
					<cfif len(agent_remarks) EQ 0>
						<cfset agent_remarks = remark>
					<cfelse>
						<cfset agent_remarks = "#agent_remarks#; #remark#">
					</cfif>
					<!--- if name doesn't exist as an AKA, add it. --->
					<cfquery name="checkForName" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="checkForName_result">
						SELECT count(*) ct 
						FROM agent_name
						WHERE
							agent_name_type = 'aka'
							and agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
							and agent_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#name#">
					</cfquery>
					<cfif checkForName.ct EQ 0>
						<cfquery name="addName" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="addName_result">
							INSERT into agent_name (
								agent_id, 
								agent_name_type,
								agent_name,
								agent_name_id
							) values (
								<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">,
								'aka',
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#name#">,
								SQ_AGENT_NAME_ID.nextval
							)
						</cfquery>
					</cfif>
				</cfloop>
			</cfif>
			<cfif updateAgent>
				<cfquery name="updateAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					UPDATE agent SET
						edited=<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#vetted#'>
						,agent_type=<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#provided_agent_type#'>
						<cfif len(#biography#) gt 0>
							, biography = <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#biography#'>
						<cfelse>
							, biography = null
						</cfif>
						<cfif len(#agent_remarks#) gt 0>
							, agent_remarks = <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#agent_remarks#'>
						<cfelse>
							, agent_remarks = null
						</cfif>
						<cfif len(#agentguid_guid_type#) gt 0>
							, agentguid_guid_type = <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#agentguid_guid_type#'>
						<cfelse>
							, agentguid_guid_type = null
						</cfif>
						<cfif len(#agentguid#) gt 0>
							, agentguid = <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#agentguid#'>
						<cfelse>
							, agentguid = null
						</cfif>
					WHERE
						agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
				</cfquery>
			</cfif>
			<cfif insertPerson>
				<!--- add a person record linked to existing agent record--->
				<cfquery name="insPerson" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					INSERT INTO person (
						PERSON_ID
						<cfif isdefined("prefix") AND len(#prefix#) gt 0>
							,prefix
						</cfif>
						<cfif isdefined("LAST_NAME") AND len(#LAST_NAME#) gt 0>
							,LAST_NAME
						</cfif>
						<cfif isdefined("FIRST_NAME") AND len(#FIRST_NAME#) gt 0>
							,FIRST_NAME
						</cfif>
						<cfif isdefined("MIDDLE_NAME") AND len(#MIDDLE_NAME#) gt 0>
							,MIDDLE_NAME
						</cfif>
						<cfif isdefined("SUFFIX") AND len(#SUFFIX#) gt 0>
							,SUFFIX
						</cfif>
						<cfif isdefined("start_date") AND len(#start_date#) gt 0>
							,birth_date
						</cfif>
						<cfif isdefined("end_date") AND len(#end_date#) gt 0>
							,death_date
						</cfif>
					) VALUES (
						<cfqueryparam cfsqltype='CF_SQL_DECIMAL' value="#agent_id#">
						<cfif isdefined("prefix") AND len(#prefix#) gt 0>
							,<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#prefix#'>
						</cfif>
						<cfif isdefined("LAST_NAME") AND len(#LAST_NAME#) gt 0>
							,<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#LAST_NAME#'>
						</cfif>
						<cfif isdefined("FIRST_NAME") AND len(#FIRST_NAME#) gt 0>
							,<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#FIRST_NAME#'>
						</cfif>
						<cfif isdefined("MIDDLE_NAME") AND len(#MIDDLE_NAME#) gt 0>
							,<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#MIDDLE_NAME#'>
						</cfif>
						<cfif isdefined("SUFFIX") AND len(#SUFFIX#) gt 0>
							,<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#SUFFIX#'>
						</cfif>
						<cfif isdefined("start_date") AND len(#start_date#) gt 0>
							,<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#start_date#'>
						</cfif>
						<cfif isdefined("end_date") AND len(#end_date#) gt 0>
							,<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#end_date#'>
						</cfif>
					)
				</cfquery>
			</cfif>
			<cfif removePerson>
				<!--- Note: Various _by_person_id fields have foreign key contraints on agent.agent_id, as person.person_id is actually a foreign key to agent.agent_id --->
				<cfquery name="deletePerson" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="deletePerson_result">
					delete from person
					where
						person_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
				</cfquery>
			</cfif>
			<cfif isdefined("pref_name") and len(pref_name) GT 0>
				<!--- update the preferred name, if one was provided, and the provided value is different from the current value --->
				<cfquery name="checkName" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="checkName_result">
					SELECT agent_name_id
					FROM agent_name 
					WHERE
						agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
						and agent_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#pref_name#">
						and agent_name_type = 'preferred'
				</cfquery>
				<cfif checkName.recordcount EQ 0>
					<!--- current preferred name is differrent, update --->
					<cfquery name="getNameID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getNameID_result">
						SELECT agent_name_id
						FROM agent_name 
						WHERE
							agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
							and agent_name_type = 'preferred'
					</cfquery>
					<cfloop query="getNameID">
						<cfquery name="updateName" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="updateName_result">
							UPDATE agent_name
							SET
								agent_name = <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#pref_name#'>
							WHERE
								agent_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_name_id#">
								and agent_name_type = 'preferred'
						</cfquery>
					</cfloop>
				</cfif>
			</cfif>

			<cfset row = StructNew()>
			<cfset row["status"] = "saved">
			<cfset row["id"] = "#agent_id#">
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

<!--- Convert a person agent into a non-person agent
 @param agent_id the agent for whom to add an agent ranking
 @param new_agent_type the agent_type to convert the person to
 @return json structure with status=changed and id=agent_id of the agent, 
   or http 500 status on an error.
--->
<cffunction name="convertFromPerson" access="remote">
	<cfargument name="agent_id" type="numeric" required="yes">
	<cfargument name="new_agent_type" type="string" required="yes">

	<cfset data = ArrayNew(1)>
	<cftransaction>
		<cftry>
			<cfif NOT listcontainsnocase(session.roles,"manage_agents")>
				<cfthrow message="Not Authorized">
			</cfif>
			<cfquery name="checkType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="checkType_result">
				SELECT agent_type 
				FROM agent
				WHERE agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
			</cfquery>
			<cfif checkType.recordcount NEQ 1 OR checkType.agent_type NEQ "person" >
				<cfthrow message="Unable to convert, agent not found or already not a person.">
			</cfif>
			<cfquery name="getPerson" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getPerson_result">
				SELECT
					PREFIX,
					LAST_NAME,
					FIRST_NAME,
					MIDDLE_NAME,
					SUFFIX,
					nvl(birth_date,to_char(BIRTH_DATE_DATE,'yyyy-mm-dd')) as birth,
					nvl(death_date,to_char(DEATH_DATE_DATE,'yyyy-mm-dd')) as death
				FROM person
				WHERE person_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
			</cfquery>
			<cfif getPerson.recordcount EQ 0 >
				<!--- error case, agent typed as person, but with no person record, allow change --->					
				<cfquery name="updateType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="updateType_result">
					UPDATE agent 
					SET agent_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#new_agent_type#">
					WHERE agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
				</cfquery>
			<cfelse>
				<!--- normal case extract data from person table, store in agent, then change agent type --->
				<cfloop query="getPerson">
					<cfset name = "#prefix# #first_name# #middle_name# #last_name# #suffix#">
					<cfset name = trim(replace(name,"  "," ", "all"))>
					<!--- add the assembled parts of the name in the person record as an aka agent name --->
					<cfquery name="addName" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="addName_result">
						INSERT into agent_name (
							agent_id, 
							agent_name_type,
							agent_name,
							agent_name_id
						) values (
							<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">,
							'aka',
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#name#">,
							SQ_AGENT_NAME_ID.nextval
						)
					</cfquery>
					<!--- store birth/death dates in remarks, with indication of comversion from person record ---->
					<cfset remark = "Agent converted from agent of type person with name [#name#]">
					<cfif len(birth) GT 0>
						<cfset remark = "#remark# Birth Date [#birth#]">
					</cfif>
					<cfif len(death) GT 0>
						<cfset remark = "#remark# Death Date [#death#]">
					</cfif>
					<cfset remark="#remark#.">
					<cfquery name="updateAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="updateAgent_result">
						UPDATE agent
						SET agent_remarks = nvl2(agent_remarks, agent_remarks||'; ' , '') || <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#remark#">>
						WHERE agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
					</cfquery>
				</cfloop>
				<cfquery name="updateType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="updateType_result">
					UPDATE agent 
					SET agent_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#new_agent_type#">
					WHERE agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
				</cfquery>
				<cfif updateType_result.recordcount NEQ 1>
					<cfthrow message="Error setting new type on agent.">
				</cfif>
				<cfquery name="removePerson" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="removePerson_result">
					DELETE from person
					WHERE agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
				</cfquery>
				<cfif removePerson_result.recordcount NEQ 1>
					<cfthrow message="Error deleting person record for agent.">
				</cfif>
			</cfif>
			<cftransaction action="commit">
			<cfset row = StructNew()>
			<cfset row["status"] = "changed">
			<cfset row["id"] = "#agent_id#">
			<cfset data[1] = row>
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

<!--- Obtain the ranks for an agent 
 @param agent_id the agent for whom to retrieve the ranks
 @return data structure containing ct, agent_rank, and status (1 on success) (count of that rank for the agent and the rank)
    or http 500 status on an error.
--->
<cffunction name="getAgentRanks" access="remote" returntype="any" returnformat="json">
	<cfargument name="agent_id" type="string" required="yes">

	<cftry>
		<cfif listcontainsnocase(session.roles,"admin_transactions")>
			<cfquery name="rankCount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select count(*) ct, agent_rank agent_rank, 1 as status from agent_rank
				where agent_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
				group by agent_rank
			</cfquery>
			<cfreturn rankCount>
		<cfelse>
			<cfthrow message="Not Authorized">
		</cfif>
	<cfcatch>
		<cfset error_message = cfcatchToErrorMessage(cfcatch)>
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
</cffunction>

<!--- Add an agent ranking for an agent 
 @param agent_id the agent for whom to add an agent ranking
 @param agent_rank the rank asserted for this agent
 @param remark a remark about this ranking.
 @param transaction_type the transaction type to which this ranking applies
 @return the agent_id of the agent, or http 500 status on an error.
--->
<cffunction name="saveAgentRank" access="remote">
	<cfargument name="agent_id" type="numeric" required="yes">
	<cfargument name="agent_rank" type="string" required="yes">
	<cfargument name="remark" type="string" required="no">
	<cfargument name="transaction_type" type="string" required="yes">

	<cftry>
		<cfif NOT listcontainsnocase(session.roles,"admin_transactions")>
			<cfthrow message="Not Authorized">
		</cfif>
		<cfquery name="addRanking" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="addRankingResult">
			insert into agent_rank (
				agent_id,
				agent_rank,
				ranked_by_agent_id,
				remark,
				transaction_type
			) values (
				<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">,
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#agent_rank#">,
				<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#session.myAgentId#">,
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#remark#">,
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#transaction_type#">
			)
		</cfquery>
		<cfif addRankingResult.recordcount NEQ 1>
			<cfthrow message="Unable to add ranking, other than one [#addRanking_result.recordcount#] ranking would be added.">
		</cfif>
		<cfreturn agent_id>
	<cfcatch>
		<cfset error_message = cfcatchToErrorMessage(cfcatch)>
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
</cffunction>

<!--- ** return an html to populate an agent ranking dialog for an agent.
 * @param agent_id the agent for which to look up agent rankings and create the dialgo content.
 * @return a block of html suitable for populating a dialog, or html containing an error message.
--->
<cffunction name="getAgentRankDialogHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="agent_id" type="string" required="no">

	<cfthread name="agentRankDialogThread">
		<cfoutput>
			<cftry>
				<cfif NOT listcontainsnocase(session.roles,"manage_transactions")>
				 	<cfthrow message="Not Authorized">
				</cfif>

				<cfquery name="getAgentName" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getAgentName_result">
					SELECT agent_name 
					FROM preferred_agent_name 
					WHERE agent_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#"> 
				</cfquery>
				<cfif getAgentName.recordcount EQ 0>
				 	<cfthrow message="specified agent [#encodeForHtml(agent_id)#] not found">
				</cfif>
				<h2 class="h2">Agent Rankings for #getAgentName.agent_name#</h2>
				<cfquery name="getRankDetails" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getRankDetails_result">
					SELECT 
						agent_rank,
						transaction_type,
						rank_date,
						agent_name ranker, 
						remark
					FROM 
						agent_rank
						left join preferred_agent_name on ranked_by_agent_id=preferred_agent_name.agent_id
					WHERE 
						agent_rank.agent_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#"> 
					ORDER BY
						agent_rank, rank_date
				</cfquery>
				<cfif listcontainsnocase(session.roles,"admin_agent_ranking")>
					<cfquery name="ctagent_rank" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select agent_rank from ctagent_rank order by agent_rank
					</cfquery>
				<cfelse>
					<cfquery name="ctagent_rank" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select agent_rank from ctagent_rank where agent_rank <> 'F' order by agent_rank
					</cfquery>
				</cfif>
				<cfquery name="cttransaction_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select transaction_type from cttransaction_type order by transaction_type
				</cfquery>
				<h3 class="h3">
					<strong><a href='/agents/Agent.cfm?agent_id=#agent_id#' target='_blank'>#getAgentName.agent_name#</a></strong> 
					has been ranked #getRankDetails.recordcount# times.
				</h3>
				<cfif getRankDetails.recordcount gt 0>
					<cfquery name="getRankSummary" dbtype="query">
						SELECT agent_rank, count(*) ct 
						FROM getRankDetails
						GROUP BY agent_rank
					</cfquery>
					<table border class="table table-responsive d-sm-table">
						<tr>
							<th>Rank</th>
							<th>Number of Rankings</th>
							<th>% of Rankings</th>
						</tr>
						<cfloop query="getRankSummary">
							<cfset portion=round((getRankSummary.ct/getRankDetails.recordcount) * 100)>
							<tr>
								<td>#getRankSummary.agent_rank#</td>
								<td>#getRankSummary.ct#</td>
								<td>#portion#</td>
							</tr>
						</cfloop>
					</table>
					<span class="btn btn-xs btn-info" id="t_agentRankDetails" onclick="tog_AgentRankDetail(1)">Show Details</span>
					<div id="agentRankDetails" style="display:none">
						<table border class="table table-responsive d-xx-table">
							<tr>
								<th>Rank</th>
								<th>Trans</th>
								<th>Date</th>
								<th>Ranker</th>
								<th>Remark</th>
							</tr>
							<cfloop query="getRankDetails">
								<tr>
									<td>#agent_rank#</td>
									<td>#transaction_type#</td>
									<td nowrap="nowrap">#dateformat(rank_date,"yyyy-mm-dd")#</td>
									<td nowrap="nowrap">#replace(ranker," ", "&nbsp;","all")#</td>
									<td>#remark#</td>
								</tr>					 
							</cfloop>
						</table>
						<cfif listcontainsnocase(session.roles,"admin_agent_ranking") >
							<!--- TODO: Implement edit agent rankings for role admin_agent_ranking --->
							<p>If there is a need to edit an existing agent ranking, please 
								<a href="/info/bugs.cfm" aria-label="bug_report_link" target="_blank">file a bug report</a>
							</p>
						</cfif>
					</div>
				</cfif><!--- has any rankings --->
				<div class="form-row">
					<h4 class="h5">
						Key to Rankings
						<i class="fas fas-info fa-info-circle" onClick="getMCZDocs('Agent_Ranking')" aria-label="help link"></i>
					</h4>
					<ul>
						<li><strong>F</strong> Director has become involved due to overdue loans; This ranking is not available for general use; Director use only</li>
						<li><strong>D</strong> Loans past due for multiple years, does not respond when contacted by any means -OR- Department must be consulted, detail in Rank Remarks</li>
						<li><strong>C</strong> Loans past due; Agent has previously been in contact but no response in over a year, detail in Rank Remarks</li>
						<li><strong>B</strong> Does not respond to automated loan notification; Responds if contacted personally</li>
						<li><strong>A</strong> If there isn't any ranking, the assumption is that they return loans and would get an "A"</li>
					</ul>
				</div>

				<cfif listcontainsnocase(session.roles,"manage_agent_ranking") OR listcontainsnocase(session.roles,"admin_agent_ranking") >
					<span class="btn btn-xs btn-secondary" id="t_agentRankDetails" onclick=" $('##agentRankCreate').show(); ">Add Rank</span>
					<form name="addAgentRankForm" id="addAgentRankForm">
						<div id="agentRankCreate" class="form-row">
							<div class="col-12">
							</div>
							<div class="col-12">
								<input type="hidden" name="agent_id" id="agent_id" value="#agent_id#">
								<input type="hidden" name="action" id="action" value="saveRank">
								<label class="data-entry-label" for="agent_rank">Add Rank of:</label>
								<select name="agent_rank" id="agent_rank" class="data-entry-select reqdClr" required>
									<option value=""></option>
									<cfloop query="ctagent_rank">
										<option value="#agent_rank#">#agent_rank#</option>
									</cfloop>
								</select>
							</div>
							<div class="col-12">
								<label class="data-entry-label" for="transaction_type">for Transaction Type:</label>
								<select name="transaction_type" id="transaction_type" class="data-entry-select reqdClr" required>
									<option value=""></option>
									<cfloop query="cttransaction_type">
										<option value="#transaction_type#">#transaction_type#</option>
									</cfloop>
								</select>
							</div>
							<div class="col-12">
								<label class="data-entry-label" for="remark">Remark: (required for unsatisfactory rankings; encouraged for all)</label>
								<textarea name="remark" id="remark" rows="4" cols="60" class="data-entry-textarea"></textarea>
							</div>
							<div class="col-12">
								<input type="submit" class="btn btn-xs btn-secondary" value="Save" id="addRankingButton">
								<input type="button" class="btn btn-xs btn-warning" value="Cancel" onclick=" $('##agentRankCreate').hide(); ">
							</div>
						</div>
					</form>
					<output id="saveAgentRankFeedback"></output>
					<script>
						$(document).ready(function () {
							$('##agentRankCreate').hide(); 
							$("##addAgentRankForm").submit(function(evt) { 
								evt.preventDefault();
							});
	
							$("##addRankingButton").click(function(evt) { 
								evt.preventDefault();
								var okToSave = true;
								if ($('##agent_rank').val()=="") {
									okToSave = false;
									messageDialog("You must select a rank to rank the agent.","Rank Required");
								}
								if ($('##transaction_type').val()=="") {
									okToSave = false;
									messageDialog("You must select the transaction type from which the reason for the ranking arose.","Transaction Type Required");
								}
								if ($('##remark').val()=="" && ($('##agent_rank').val()=='C' || $('##agent_rank').val()=='D' || $('##agent_rank').val()=='F')) {
									okToSave = false;
									messageDialog("A remark is required for unsatisfactory rankings.","Remark Required");
								}
								if (okToSave) { 
									var agent_id = $('##agent_id').val();
									var agent_rank = $('##agent_rank').val();
									var remark = $('##remark').val();
									var transaction_type = $('##transaction_type').val();
									saveAgentRank(agent_id, agent_rank, remark, transaction_type,"saveAgentRankFeedback");
								}
							});
						});
					</script>
				</cfif>
			<cfcatch>
				<h2>Error: #cfcatch.type# #cfcatch.message#</h2> 
				<div>#cfcatch.detail#</div>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="agentRankDialogThread" />
	<cfreturn agentRankDialogThread.output>
</cffunction>

</cfcomponent>
