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
		<cfset yearStr="#yearStr# - unknown)">
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
					SELECT agent_type 
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
												<button class="btn btn-xs btn-light" type="button" id="moveGroupAgentDown_#i#" disabled>Move Down</buttona>
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
										addAgentToGroupCB(#getAgent.agent_id#,$('##new_member_agent_id').val(),null,reloadGroupMembers);
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
			<cfquery name="moveAgentTwo" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="moveAgentOne_result">
				UPDATE group_member
				SET MEMBER_ORDER = <cfqueryparam cfsqltype='CF_SQL_DECIMAL' value='#currentPos#'>
				WHERE
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

<!--- Given various information create dialog to create a new address, by default a temporary address.
 @param agent_id if given, the agent for whom this is an address
 @param shipment_id if given, the shipment for which this address is to be used for
 @param create_from_address_id, if given, used to lookup the agent_id for whom this is an address for
 @param address_type shipping, mailing, or temporary, defaults to temporary if not provided.
 @return html to populate a dialog
--->
<cffunction name="addAddressHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="agent_id" type="string" required="no"><!--- if given, the agent for whom this is an address, if not, select --->
	<cfargument name="shipment_id" type="string" required="no"><!--- if given, the address is used for this shipment --->
	<cfargument name="create_from_address_id" type="string" required="no"><!--- if given, use this address's agent for this address --->
	<cfargument name="address_type" type="string" required="no"><!--- use temporary to create a temporary address, otherwise shipping or mailing --->

	<cfthread name="createAddressThread">
		<cfoutput>
			<cftry>
				<cfif not isdefined("address_type") or len(#address_type#) gt 0>
					<cfset address_type = "temporary">
				</cfif>
				<cfif isdefined("create_from_address_id") AND (not isdefined("agent_id") AND len(agent_id) GT 0) >
					<!--- look up agent id from address --->
					<cfquery name="qAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select agent_id from addr where addr_id = <cfqueryparam value="#create_from_address_id#" CFSQLTYPE="CF_SQL_VARCHAR">
					</cfquery>
					<cfset agent_id = qAgent.agent_id >
				</cfif>
				<cfquery name="ctAddrType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select addr_type from ctaddr_type where addr_type = <cfqueryparam value="#address_type#" CFSQLTYPE="CF_SQL_VARCHAR">
				</cfquery>
				<cfif ctAddrType.addr_type IS ''>
					<ul><li>Provided address type is unknown.</li></ul>
				<cfelse>
					<cfset agent_name ="">
					<cfif isdefined("agent_id") AND len(agent_id) GT 0 >
						<cfquery name="query" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							select agent_name 
							from agent a left join agent_name on a.preferred_agent_name_id = agent_name.agent_name_id
							where
							a.agent_id = <cfqueryparam value="#agent_id#" CFSQLType="CF_SQL_DECIMAL">
							and rownum < 2
						</cfquery>
						<cfif query.recordcount gt 0>
							<cfset agent_name = query.agent_name>
						</cfif>
					</cfif>
					<div>
						<div id='newAddressStatus'></div>
						<form name='newAddress' id='newAddressForm'>
							<cfif not isdefined("agent_id")><cfset agent_id = ""></cfif>
							<input type='hidden' name='method' value='addNewAddress'>
							<input type='hidden' name='returnformat' value='json'>
							<input type='hidden' name='queryformat' value='column'>
							<input type='hidden' name='addr_type' value='#address_type#'>
							<input type='hidden' name='valid_addr_fg' id='valid_addr_fg' value='0'>
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
							<div class='form-row'>
								<div class='col-12 col-md-6'>
									<label for='institution' class="data-entry-label">Institution</label>
									<input type='text' name='institution' id='institution'class="form-control data-entry-input". >
								</div>
								<div class='col-12 col-md-6'>
									<label for='department' class="data-entry-label">Department</label>
									<input type='text' name='department' id='department' class="form-control data-entry-input". >
								</div>
							</div>
							<div class='form-row'>
								<div class='col-12'>
									<label for='street_addr1' class="data-entry-label">Street Address 1</label>
									<input type='text' name='street_addr1' id='street_addr1' class='reqdClr form-control data-entry-input'>
								</div>
							</div>
							<div class='form-row'>
								<div class='col-12'>
									<label for='street_addr2'>Street Address 2</label>
									<input type='text' name='street_addr2' id='street_addr2' class="form-control data-entry-input">
								</div>
							</div>
							<div class='form-row'>
								<div class='col-12 col-md-6'>
									<label for='city' class="data-entry-label">City</label>
									<input type='text' name='city' id='city' class='reqdClr form-control data-entry-input'>
								</div>
								<div class='col-12 col-md-6'>
									<label for='state' class="data-entry-label">State</label>
									<input type='text' name='state' id='state' class='reqdClr form-control data-entry-input'>
								</div>
							</div>
							<div class='form-row'>
								<div class='col-12 col-md-6'>
									<label for='zip' class="data-entry-label">Zip</label>
									<input type='text' name='zip' id='zip' class='reqdClr form-control data-entry-input'>
								</div>
								<div class='col-12 col-md-6'>
									<label for='country_cde' class="data-entry-label">Country</label>
									<input type='text' name='country_cde' id='country_cde' class='reqdClr form-control data-entry-input'>
								</div>
							</div>
							<div class='form-row'>
								<div class='col-12 col-md-6'>
									<label for='mail_stop' class="data-entry-label">Mail Stop</label>
									<input type='text' name='mail_stop' id='mail_stop'class="form-control data-entry-input">
								</div>
								<div class='col-12 col-md-6'>
									<label for='addr_remarks' class="data-entry-label">Address Remark</label>
									<input type='text' name='addr_remarks' id='addr_remarks' class="form-control data-entry-input">
								</div>
							</div>
							<input type='submit' class='insBtn' value='Create Address' >
							<script>
								$('##newAddressForm').submit( function (e) { 
									$.ajax({
										url: '/agents/component/functions.cfc',
										data : $('##newAddressForm').serialize(),
										success: function (result) {
											if (result.DATA.STATUS[0]=='success') { 
												$('##newAddressStatus').html('New Address Added');
												$('##new_address_id').val(result.DATA.ADDRESS_ID[0]);
												$('##new_address').val(result.DATA.ADDRESS[0]);
												$('##tempAddressDialog').dialog('close');
											} else { 
												$('##newAddressStatus').html(result.DATA.MESSAGE[0]);
											}
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

<!--- given address parameters, create a new address record for a given agent --->
<cffunction name="addNewAddress" access="remote" returntype="query">
	<cftransaction>
    <cftry>
        <cfquery name="prefName" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
            select agent_name from preferred_agent_name 
            where agent_id= <cfqueryparam value='#agent_id#' cfsqltype='CF_SQL_DECIMAL'>
        </cfquery>
        <cfquery name="addrNextId" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
            select sq_addr_id.nextval as id from dual
        </cfquery>
        <cfset pk = addrNextId.id>
        <cfquery name="addr" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="addrResult"> 
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
                                ,valid_addr_fg
                                ,addr_remarks
                        ) VALUES (
                                 <cfqueryparam value='#pk#' cfsqltype='CF_SQL_DECIMAL'>
                                ,<cfqueryparam value='#STREET_ADDR1#' cfsqltype='CF_SQL_VARCHAR'>
                                ,<cfqueryparam value='#STREET_ADDR2#' cfsqltype='CF_SQL_VARCHAR'>
                                ,<cfqueryparam value='#institution#' cfsqltype='CF_SQL_VARCHAR'>
                                ,<cfqueryparam value='#department#' cfsqltype='CF_SQL_VARCHAR'>
                                ,<cfqueryparam value='#CITY#' cfsqltype='CF_SQL_VARCHAR'>
                                ,<cfqueryparam value='#state#' cfsqltype='CF_SQL_VARCHAR'>
                                ,<cfqueryparam value='#ZIP#' cfsqltype='CF_SQL_VARCHAR'>
                                ,<cfqueryparam value='#COUNTRY_CDE#' cfsqltype='CF_SQL_VARCHAR'>
                                ,<cfqueryparam value='#MAIL_STOP#' cfsqltype='CF_SQL_VARCHAR'>
                                ,<cfqueryparam value='#agent_id#' cfsqltype='CF_SQL_DECIMAL'>
                                ,<cfqueryparam value='#addr_type#' cfsqltype='CF_SQL_VARCHAR'>
                                ,<cfqueryparam value='#valid_addr_fg#' cfsqltype='CF_SQL_DECIMAL'>
                                ,<cfqueryparam value='#addr_remarks#' cfsqltype='CF_SQL_VARCHAR'>
                        )
        </cfquery>
        <cfquery name="newAddr" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="addrResult"> 
            select formatted_addr from addr 
            where addr_id = <cfqueryparam value='#pk#' cfsqltype="CF_SQL_DECIMAL">
        </cfquery>
		<cfset q=queryNew("STATUS,ADDRESS_ID,ADDRESS,MESSAGE")>
		<cfset t = queryaddrow(q,1)>
		<cfset t = QuerySetCell(q, "STATUS", "success", 1)>
		<cfset t = QuerySetCell(q, "ADDRESS_ID", "#pk#", 1)>
		<cfset t = QuerySetCell(q, "ADDRESS", "#newAddr.formatted_addr#", 1)>
		<cfset t = QuerySetCell(q, "MESSAGE", "", 1)>
     <cfcatch>
        <cftransaction action="rollback"/>
		<cfset q=queryNew("STATUS,ADDRESS_ID,ADDRESS,MESSAGE")>
		<cfset t = queryaddrow(q,1)>
		<cfset t = QuerySetCell(q, "STATUS", "error", 1)>
		<cfset t = QuerySetCell(q, "ADDRESS_ID", "", 1)>
		<cfset t = QuerySetCell(q, "ADDRESS", "", 1)>
		<cfset t = QuerySetCell(q, "MESSAGE", "Error: #cfcatch.message# #cfcatch.detail#", 1)>
     </cfcatch>
     </cftry>
	</cftransaction>
     <cfreturn q>
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
