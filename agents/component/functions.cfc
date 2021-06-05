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
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
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
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
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
					order by valid_addr_fg DESC
				</cfquery>
				<h3 class="h3">Addresses</h3>
				<ul>
					<cfif agentAddrs.recordcount EQ 0>
						<li>None</li>
					</cfif>
					<cfset i=0>
					<cfloop query="agentAddrs">
						<cfset i=i+1>
						<cfif len(addr_remarks) GT 0><cfset rem="[#addr_remarks#]"><cfelse><cfset rem=""></cfif>
						<li>
							#addr_type#:
							#formatted_addr#
							#rem#
							<button type="button" id="editAddrButton_#i#" value="Edit" class="btn btn-xs btn-secondary">Edit</button>
							<button type="button" id="deleteAddrButton_#i#" value="Delete" class="btn btn-xs btn-danger">Delete</button>
							<script>
								$(document).ready(function () {
									$("##editAddrButton_#i#").click(function(evt) { 
										editAddressForAgent(#agentAddrs.addr_id#,"addressDialogDiv",reloadAddresses);
									});
									$("##deleteAddrButton_#i#").click(function(evt) { 
										deleteAgentAddress(#agentAddrs.addr_id#,reloadAddresses);
									});
								});
							</script>
						</li>
					</cfloop>
				</ul>

				<div id="addressDialogDiv"></div>

				<h3 class="h3">Add new Address</h3>
				<div class="form-row">
					<div class="col-12 col-md-4">
						<label for="new_address_type">Address Type</label>
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
					<div class="col-12 col-md-8">
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
            select formatted_addr from addr 
            where addr_id = <cfqueryparam value='#pk#' cfsqltype="CF_SQL_DECIMAL">
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
			<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
			<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
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

	<cfset theResult=queryNew("status, message")>
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
				<cfset t = queryaddrow(theResult,1)>
				<cfset t = QuerySetCell(theResult, "status", "1", 1)>
				<cfset t = QuerySetCell(theResult, "message", "Address updated.", 1)>
			<cfelse>
				<cfthrow message="Unable to update address, other than one [#updateAddr_result.recordcount#] address would be updated.">
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
			<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
			<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
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
				<h3 class="h3">Relationships to other agents</h3>
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
				<ul>
					<cfif relations.recordcount EQ 0 >
						<li>None</li>
					</cfif>
					<cfset i=0>
					<cfloop query="relations">
						<cfset i=i+1>
						<li>#currAgent# 
							<select name="relation_type" id="relation_type_#i#">
								<cfloop query="ctagent_relationship">
									<cfif relations.agent_relationship EQ ctagent_relationship.agent_relationship><cfset selected="selected"><cfelse><cfset selected=""></cfif>
									<option value="#ctagent_relationship.agent_relationship#" #selected#>#ctagent_relationship.agent_relationship#</option>
								</cfloop>
							</select>
							<input type="text" name="related_agent" id="related_agent_#i#" value="#agent_name#">
							<input type="hidden" name="related_agent" id="related_agent_id_#i#" value="#related_agent_id#">
							<input type="hidden" name="related_agent" id="old_related_agent_id_#i#" value="#related_agent_id#">
							<input type="hidden" name="related_agent" id="old_relationship_#i#" value="#relations.agent_relationship#">
							<a id="view_rel_#i#" href="/agents/editAgent.cfm?agent_id=#related_agent_id#">View</a> 
							<input type="text" name="agent_remarks" id="agent_remarks_#i#" value="#agent_remarks#" placeholder="remarks">
							#date_to_merge# #on_hold# #held_by#
							<button type="button" id="updateRelationshipButton_#i#" value="Add" class="btn btn-xs btn-secondary">Save</button>
							<button type="button" id="deleteRelationshipButton_#i#" value="Add" class="btn btn-xs btn-warning">Remove</button>
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
						</li>
					</cfloop>
				</ul>

				<div id="newRelationshipDiv" class="col-12">
					<label for="new_relation">Add Relationship</label>
					<div class="form-row">
						<div class="col-12 col-md-2">
							<label class="data-entry-label">&nbsp;</label>
							<input type="text" name="current_agent" value="#currAgent#" class="data-entry-input" disabled >
						</div>
						<div class="col-12 col-md-3">
							<label for="new_relation_type" class="data-entry-label">Relationship</label>
							<select name="relation_type" id="new_relation_type" class="data-entry-select reqdClr">
								<option value""></option>
								<cfloop query="ctagent_relationship">
									<option value="#ctagent_relationship.agent_relationship#">#ctagent_relationship.agent_relationship#</option>
								</cfloop>
							</select>
						</div>
						<div class="col-12 col-md-3">
							<label for="new_related_agent">To Related Agent</label>
							<input type="text" name="related_agent" id="new_related_agent" value="" class="data-entry-input reqdClr">
							<input type="hidden" name="related_agent" id="new_related_agent_id" value="">
						</div>
						<div class="col-12 col-md-3">
							<label for="new_relation">Remarks</label>
							<input type="text" name="agent_remarks" id="new_agent_remarks" value="" class="data-entry-input">
						</div>
						<div class="col-12 col-md-1">
							<label class="data-entry-label">&nbsp;</label>
							<button type="button" id="addRelationshipButton" value="Add" class="btn btn-xs btn-secondary">Add</button>
						</div>
					</div>
					<script>
						$(document).ready(function () {
							makeAgentAutocompleteMeta("new_related_agent", "new_related_agent_id");
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

				<h3 class="h3">Relationships from other agents</h3>
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
				<ul>
					<cfif revRelations.recordcount EQ 0 >
						<li>None</li>
					</cfif>
					<cfloop query="revRelations">
						<li>
							<a href="/agents/editAgent.cfm?agent_id=#from_agent_id#">#agent_name#</a> 
							#agent_relationship# 
							#currAgent#
							#agent_remarks# 
							#date_to_merge# #on_hold# #held_by#
						</li>
					</cfloop>
				</ul>
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
					AGENT_RELATIONSHIP)
				VALUES (
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#related_agent_id#">,
					<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#relationship#'>)
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
			<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
			<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
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
			<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
			<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
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
			<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
			<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
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
				<ul>
					<cfif electAgentAddrs.recordcount EQ 0 >
						<li>None</li>
					</cfif>
					<cfset i=0>
					<cfloop query="electAgentAddrs">
						<cfset i=i+1>
						<li class="form-row">
							<div class="col-12 col-md-4">
								<select name="address_type" id="eaddress_type_#i#" class="data-entry-select">
									<cfloop query="ctElecAddrType">
										<cfif #electAgentAddrs.address_type# is "#ctElecAddrType.address_type#"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
										<option value="#ctElecAddrType.address_type#" #selected#>#ctElecAddrType.address_type#</option>
									</cfloop>
								</select>
							</div>
							<div class="col-12 col-md-4">
								<input type="text" name="address" id="address_#i#" value="#encodeForHtml(address)#" class="data-entry-input">
								<input type="hidden" name="electronic_address_id" id="electronic_address_id_#i#" value="#electAgentAddrs.electronic_address_id#">
							</div>
							<div class="col-12 col-md-4">
								<button type="button" id="agentEAddrU#i#Button" value="Update" class="btn btn-xs btn-secondary">Update</button>
								<button type="button" id="agentEAddrDel#i#Button" value="Delete" class="btn btn-xs btn-danger">Delete</button>
								<span id="electronicAddressFeedback#i#"></span>
							</div>
						</li>
						<script>
							$(document).ready(function () {
								$('##agentEAddrU#i#Button').click(function(evt){
									evt.preventDefault;
									updateElectronicAddress(#agent_id#, 'electronic_address_id_#i#','address_#i#','eaddress_type_#i#','electronicAddressFeedback#i#');
								});
							});
							$(document).ready(function () {
								$('##agentEAddrDel#i#Button').click(function(evt){
									evt.preventDefault;
									deleteElectronicAddress('electronic_address_id_#i#',reloadElectronicAddresses);
								});
							});
						</script>
					</cfloop>
				</ul>
				<div id="newEaddrDiv" class="col-12">
					<label for="new_eaddress">Add Phone or Email</label>
					<div class="form-row">
						<div class="col-12 col-md-5">
							<select name="eaddress_type" id="new_eaddress_type" class="data-entry-select">
								<cfloop query="ctElecAddrType">
									<option value="#ctElecAddrType.address_type#">#ctElecAddrType.address_type#</option>
								</cfloop>
							</select>
						</div>
						<div class="col-12 col-md-5">
							<input type="text" name="address" id="new_eaddress" value="" class="data-entry-input">
						</div>
						<div class="col-12 col-md-2">
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
			<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
			<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
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
			<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
			<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
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
			<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
			<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
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
				<cfquery name="namesForAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="namesForAgent_result">
					SELECT
						agent_name_id,
						agent_id,
						agent_name_type,
						agent_name
					FROM agent_name
					WHERE agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
				</cfquery>
				<cfquery name="pname" dbtype="query">
					select * from namesForAgent where agent_name_type = 'preferred'
				</cfquery>
				<cfquery name="npname" dbtype="query">
					select * from namesForAgent where agent_name_type != 'preferred'
				</cfquery>
				<cfset i=1>
				<ul>
					<li>
						<form id="preferredNameForm">
							<input type="hidden" name="agent_name_id" id="preferred_name_agent_name_id" value="#pname.agent_name_id#">
							<input type="hidden" name="agent_name_type" id="preferred_name_agent_name_type" value="#pname.agent_name_type#">
							<label for="preferred_name" class="">Preferred Name</label>
							<input type="text" value="#pname.agent_name#" name="agent_name" id="preferred_name" class=""> 
							<button type="button" id="preferredUpdateButton" value="preferredUpdateButton" class="btn btn-xs btn-secondary">Update</button>
							<span id="prefAgentNameFeedback"></span>
						</form>
					</li>
					<script>
						$(document).ready(function () {
							$('##preferredUpdateButton').click(function(evt){
								evt.preventDefault;
								saveAgentName(#agent_id#, 'preferred_name_agent_name_id','preferred_name','preferred_name_agent_name_type','prefAgentNameFeedback');
							});
						});
					</script>
				</ul>

				<cfset i=0>
				<label>Other Names</label>
				<span class="hints" style="color: green;">(add a space between initials for all forms with two initials)</span>
				<cfquery name="ctNameType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select agent_name_type 
					from ctagent_name_type 
					where agent_name_type != 'preferred' 
					order by agent_name_type
				</cfquery>
				<ul>
					<cfif npname.recordcount EQ 0 >
						<li>No other names</li>
					</cfif>
					<cfloop query="npname">
						<cfset i=i+1>
						<li>
							<form id="agentNameForm_#i#">
								<input type="hidden" name="agent_name_id" value="#npname.agent_name_id#" id="agent_name_id_#i#">
								<input type="hidden" name="agent_id" value="#npname.agent_id#">
								<select name="agent_name_type" id="agent_name_type_#i#">
									<cfloop query="ctNameType">
										<option  <cfif ctNameType.agent_name_type is npname.agent_name_type> selected="selected" </cfif>
											value="#ctNameType.agent_name_type#">#ctNameType.agent_name_type#</option>
									</cfloop>
								</select>
								<input type="text" value="#npname.agent_name#" name="agent_name" id="agent_name_#i#">
								<button type="button" id="agentNameU#i#Button" value="Update" class="btn btn-xs btn-secondary" >Update</button>
								<button type="button" id="agentNameDel#i#Button" value="Delete" class="btn btn-xs btn-danger">Delete</button>
								<span id="agentNameFeedback#i#"></span>
							</form>
						</li>
						<script>
							$(document).ready(function () {
								$('##agentNameU#i#Button').click(function(evt){
									evt.preventDefault;
									saveAgentName(#agent_id#, 'agent_name_id_#i#','agent_name_#i#','agent_name_type_#i#','agentNameFeedback#i#');
								});
							});
							$(document).ready(function () {
								$('##agentNameDel#i#Button').click(function(evt){
									evt.preventDefault;
									deleteAgentName('agent_name_id_#i#',reloadAgentNames);
								});
							});
						</script>
					</cfloop>
				</ul>
				<div id="newAgentNameDiv" class="col-12">
					<label for="new_agent_name">Add agent name</label>
					<form id="newNameForm">
						<input type="hidden" name="agent_id" id="new_agent_name_agent_id" value="#agent_id#">
						<select name="agent_name_type" onchange="suggestName(this.value,'new_agent_name');" id="new_agent_name_type">
							<cfloop query="ctNameType">
								<option value="#ctNameType.agent_name_type#">#ctNameType.agent_name_type#</option>
							</cfloop>
						</select>
						<input type="text" name="agent_name" id="new_agent_name" readonly autocomplete="off" onfocus="this.removeAttribute('readonly');">
						<button type="button" id="addAgentButton" class="btn btn-xs btn-secondary" value="Add Name">Add Name</button>
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

	<cfset theResult=queryNew("status, message")>
	<cftransaction>
		<cftry>
			<cfquery name="updateName" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="updateName_result">
				INSERT INTO agent_name (
					agent_name_id,
					agent_id,
					agent_name_type,
					agent_name)
				VALUES (
					sq_agent_name_id.nextval,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">,
					<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#agent_name_type#'>,
					<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#agent_name#'>)
			</cfquery>
			<cfif updateName_result.recordcount eq 1>
				<cfset t = queryaddrow(theResult,1)>
				<cfset t = QuerySetCell(theResult, "status", "1", 1)>
				<cfset t = QuerySetCell(theResult, "message", "Name added to Agent.", 1)>
			<cfelse>
				<cfthrow message="Error adding name to agent.">
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
				<cfset t = QuerySetCell(theResult, "message", "Name added to Agent.", 1)>
			<cfelse>
				<cfthrow message="Error adding name to agent.">
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
			<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
			<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
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
							<ul><li>None</li></ul>
						<cfelse>
							<ul>
								<cfset yearRange = assembleYearRange(start_year="#groupMembers.birth_date#",end_year="#groupMembers.death_date#",year_only=true)>
								<cfset i = 0>
								<cfloop query="groupMembers">
									<cfset i = i + 1>
									<li>
										<a href="/agents/Agent.cfm?agent_id=#groupMembers.member_agent_id#">#groupMembers.agent_name#</a>
										#vetted# #yearRange# #collections_scope#
										<a class="btn btn-xs btn-warning" type="button" id="removeAgentFromGroup_#i#" 
											onclick=' confirmDialog("Remove this agent from this group?", "Confirm Remove Group Member", function() { removeAgentFromGroupCB(#groupMembers.group_agent_id#,#groupMembers.member_agent_id#,reloadGroupMembers); } ); '>Remove</a>
										<cfif groupMembers.recordcount GT 1>
											<cfif i EQ 1>
												<button class="btn btn-xs btn-light" type="button" id="moveGroupAgentUp_#i#" disabled>Move Up</button>
											<cfelse>
												<a class="btn btn-xs btn-secondary" type="button" id="moveGroupAgentUp_#i#" 
													onclick="moveAgentInGroupCB(#groupMembers.group_agent_id#,#groupMembers.member_agent_id#,'decrement',reloadGroupMembers);">Move Up</a>
											</cfif>
											<cfif i EQ groupMembers.recordcount>
												<button class="btn btn-xs btn-light" type="button" id="moveGroupAgentDown_#i#" disabled>Move Down</button>
											<cfelse>
												<a class="btn btn-xs btn-secondary" type="button" id="moveGroupAgentDown_#i#" 
													onclick="moveAgentInGroupCB(#groupMembers.group_agent_id#,#groupMembers.member_agent_id#,'increment',reloadGroupMembers);">Move Down</a>
											</cfif>
										</cfif>
									</li>
								</cfloop>
							</ul>
						</cfif>
						<div>
							<form name="newGroupMember">
								<label for="new_group_agent_name" id="new_group_agent_name_label" class="data-entry-label">Add Member To Group
									<h5 id="new_group_agent_view" class="d-inline">&nbsp;&nbsp;&nbsp;&nbsp;</h5> 
								</label>
								<div class="input-group">
									<div class="input-group-prepend">
										<span class="input-group-text smaller bg-lightgreen" id="new_group_agent_name_icon"><i class="fa fa-user" aria-hidden="true"></i></span> 
									</div>
									<input type="text" name="new_group_agent_name" id="new_group_agent_name" class="form-control rounded-right data-entry-input form-control-sm" aria-label="Agent Name" aria-describedby="new_group_agent_name_label" value="">
									<input type="hidden" name="new_member_agent_id" id="new_member_agent_id" value="">
								</div>
								<script>
									$(document).ready(function() {
										$(makeRichAgentPicker('new_group_agent_name', 'new_member_agent_id', 'new_group_agent_name_icon', 'new_group_agent_view', null));
									});
								</script>
								<button type="button" id="addMemberButton" class="btn btn-xs btn-secondary" value="Add Group Member">Add Group Member</button>
							</form>
							<script>
								$(document).ready(function() {
									$('##addMemberButton').click(function (evt) {
										evt.preventDefault();
										addAgentToGroupCB(#lookupAgent.agent_id#,$('##new_member_agent_id').val(),null,reloadGroupMembers);
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

	<cfset theResult=queryNew("status, message")>
	<cftry>
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
			<cfset t = queryaddrow(theResult,1)>
			<cfset t = QuerySetCell(theResult, "status", "1", 1)>
			<cfset t = QuerySetCell(theResult, "message", "Agent Removed From Group.", 1)>
		</cfif>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
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
			<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
			<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
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
				<cfthrow message="Unable to move agent position in group.">
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
							addr_remarks
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
					<div>
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
								<div class='col-12 col-md-6'>
		 							<strong>Address Type:</strong> #ctAddrType.addr_type#
								</div>
								<div class='col-12 col-md-6'>
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
									<div class='col-12 col-md-6'>
										<label for="valid_addr_fg">Valid?</label>
											<select name="valid_addr_fg" id="valid_addr_fg" class="data-entry-select">
												<cfif valid_addr_fg EQ 1><cfset selected="selected"><cfelse><cfset selected=""></cfif>
												<option value="1" #selected#>yes</option>
												<cfif valid_addr_fg EQ 0><cfset selected="selected"><cfelse><cfset selected=""></cfif>
												<option value="0" #selected#>no</option>
										</select>
									</div>
									<div class='col-12 col-md-6'>
										<label for="job_title" class="data_entry_label">Job Title</label>
										<input type="text" name="job_title" id="job_title" class="data-entry-input" value="#job_title#">
									</div>
								</div>
							</cfif>
							<div class='form-row'>
								<div class='col-12 col-md-6'>
									<label for='institution' class="data-entry-label">Institution</label>
									<input type='text' name='institution' id='institution'class="form-control data-entry-input" value="#institution#" >
								</div>
								<div class='col-12 col-md-6'>
									<label for='department' class="data-entry-label">Department</label>
									<input type='text' name='department' id='department' class="form-control data-entry-input" value="#department#" >
								</div>
							</div>
							<div class='form-row'>
								<div class='col-12'>
									<label for='street_addr1' class="data-entry-label">Street Address 1</label>
									<input type='text' name='street_addr1' id='street_addr1' class='reqdClr form-control data-entry-input' value="#street_addr1#" required>
								</div>
							</div>
							<div class='form-row'>
								<div class='col-12'>
									<label for='street_addr2'>Street Address 2</label>
									<input type='text' name='street_addr2' id='street_addr2' class="form-control data-entry-input" value="#street_addr2#">
								</div>
							</div>
							<div class='form-row'>
								<div class='col-12 col-md-6'>
									<label for='city' class="data-entry-label">City</label>
									<input type='text' name='city' id='city' class='reqdClr form-control data-entry-input' value="#city#" required>
								</div>
								<div class='col-12 col-md-6'>
									<label for='state' class="data-entry-label">State/Province</label>
									<input type='text' name='state' id='state' class='reqdClr form-control data-entry-input' value="#state#" required>
								</div>
							</div>
							<div class='form-row'>
								<div class='col-12 col-md-4'>
									<label for='zip' class="data-entry-label">Zip/Postcode</label>
									<input type='text' name='zip' id='zip' class='reqdClr form-control data-entry-input' value="#zip#" required>
								</div>
								<div class='col-12 col-md-8'>
									<script>
										function handleCountrySelect(){
										   var countrySelection =  $('input:radio[name=country]:checked').val();
										   if (countrySelection == 'USA') {
										      $("##textUS").css({"color": "black", "font-weight":"bold" });
										      $("##other_country_cde").toggle("false");
										      $("##country_cde").val("USA");
									   	   $("##other_country_cde").removeClass("reqdClr");
												$('##other_country_cde').removeAttr('required');
										   } else {
										      $("##textUS").css({"color": "##999999", "font-weight": "normal" });
										      $("##other_country_cde").toggle("true");
										      $("##country_cde").val($("##other_country_cde").val());
										      $("##other_country_cde").addClass("reqdClr");
												$('##other_country_cde').prop('required',true);
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
										<input type="radio" name="country" value="USA" onclick="handleCountrySelect();" #checked# ><span id="textUS" style="color: black; font-weight: bold">USA</span>
										<cfif country_cde NEQ "USA"><cfset checked='checked="checked"'><cfelse><cfset checked=""></cfif>
										<input type="radio" name="country" value="other" onclick="handleCountrySelect();" #checked#><span id="textOther">Other</span>
										<input type="text" name="other_country_cde" id="other_country_cde" onblur=" $('##country_cde').val($('##other_country_cde').val());" style="display: none;"  value="#country_cde#">
									<span>
								</div>
							</div>
							<div class='form-row'>
								<div class='col-12 col-md-6'>
									<label for='mail_stop' class="data-entry-label">Mail Stop</label>
									<input type='text' name='mail_stop' id='mail_stop'class="form-control data-entry-input" value="#mail_stop#">
								</div>
								<div class='col-12 col-md-6'>
									<label for='addr_remarks' class="data-entry-label">Address Remark</label>
									<input type='text' name='addr_remarks' id='addr_remarks' class="form-control data-entry-input" value="#addr_remarks#">
								</div>
							</div>
							<div class='form-row'>
								<div class='col-12 col-md-6'>
									<cfif isdefined("addr_id") and len(#addr_id#) GT 0>
										<input type='submit' class='btn btn-xs btn-primary' value='Save Changes' >
										<cfset errmsg = "updating an address for an agent">
									<cfelse>
										<input type='submit' class='btn btn-xs btn-primary' value='Create Address' >
										<cfset errmsg = "adding an address to an agent">
									</cfif>
								</div>
								<div class='col-12 col-md-6'>
									<div id='newAddressStatus'></div>
								</div>
							</div>
							<script>
								$('##newAddressForm').submit( function (e) { 
									$.ajax({
										url: '/agents/component/functions.cfc',
										data : $('##newAddressForm').serialize(),
										success: function (result) {
											if (result[0].STATUS=='success') { 
												$('##newAddressStatus').html(result[0].MESSAGE);
												$('##new_address_id').val(result[0].ADDRESS_ID);
												$('##new_address').val(result[0].ADDRESS);
												$('##tempAddressDialog').dialog('close');
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
			<cfset updateAgent = true>
			<cfset updatePerson = false>
			<cfset insertPerson = false>
			<cfset removePerson = false>
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
			<cfelse>
				<!--- TODO: Support changing a person to a non-person --->
				<cfthrow message="conversion of a non-person agent to a person is not supported yet">
				<cfset updateAgent = true>
				<cfset removePerson = true>
			</cfif>
			<cfif updateAgent>
				<cfquery name="updateAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					UPDATE agent SET
						edited=<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#vetted#'>
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
			<cfif removePerson>
				<!~--- needs enforced foreign keys on coll_object.entered_by_person_id, last_edited_person_id, loan_item.reconciled_by_person_id and deacc_item.reconciled_by_person_id --->
				<!--- TODO: Support changing a person to a non-person --->
				<cfthrow message="conversion of a non-person agent to a person is not supported yet">
				<cfquery name="deletePerson" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="deletePerson_result">
					delete from person
					where
						person_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
				</cfquery>
			</cfif>

			<cfset row = StructNew()>
			<cfset row["status"] = "saved">
			<cfset row["id"] = "#agent_id#">
			<cfset data[1] = row>
	
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
	<cfreturn #serializeJSON(data)#>
</cffunction>

</cfcomponent>
