<!---
vocabularies/component/functions.cfc
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

<!--- function saveUndColl 
Update an existing arbitrary collection record (underscore_collection).
@param underscore_collection_id primary key of record to update
@param collection_name the brief uman readable description of the arbitrary collection, must not be blank.
@param description description of the collection
@return json structure with status and id or http status 500
--->
		
			
<cffunction name="saveUndColl" access="remote" returntype="any" returnformat="json">
	<cfargument name="underscore_collection_id" type="string" required="yes">
	<cfargument name="underscore_collection_type" type="string" required="yes">
	<cfargument name="collection_name" type="string" required="yes">
	<cfargument name="description" type="string" required="no">
	<cfargument name="html_description" type="string" required="no">
	<cfargument name="displayed_media_id" type="string" required="no">
	<cfargument name="mask_fg" type="string" required="no">
	<cfset data = ArrayNew(1)>
	<cftry>
		<cfif len(trim(#collection_name#)) EQ 0>
			<cfthrow type="Application" message="Name of named group must contain a value.">
		</cfif>
		<cfquery name="save" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			update underscore_collection set
				collection_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#collection_name#">,
				underscore_collection_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#underscore_collection_type#">
				<cfif isdefined("description")>
					,description = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#description#">
				</cfif>
				<cfif isdefined("displayed_media_id") and len(displayed_media_id) GT 0>
					,displayed_media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#displayed_media_id#">
				<cfelse>
					,displayed_media_id = NULL
				</cfif>
				<cfif isdefined("mask_fg")>
					,mask_fg = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#mask_fg#">
				</cfif>
				<cfif isdefined("html_description")>
					,html_description = <cfqueryparam cfsqltype="CF_SQL_CLOB" value="#html_description#">
				</cfif>
			where 
				underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
		</cfquery>
		<cfset row = StructNew()>
		<cfset row["status"] = "saved">
		<cfset row["id"] = "#underscore_collection_id#">
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

<!---
Function getUndCollList.  Search for arbitrary collections returning json suitable for a dataadaptor.
@param collection_name name of the underscore collection (arbitrary grouping) to search for.
@return a json structure containing matching named groups.
--->
<cffunction name="getUndCollList" access="remote" returntype="any" returnformat="json">
	<cfargument name="collection_name" type="string" required="yes">
	<!--- perform wildcard search anywhere in underscore_collection.collection_name --->
	<cfset collection_name = "%#collection_name#%"> 

	<cfset data = ArrayNew(1)>
	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="search_result" timeout="#Application.query_timeout#">
			SELECT 
				underscore_collection_id, 
				collection_name, 
				underscore_collection_type,
				description,
				underscore_agent_id,
				case 
					when underscore_agent_id is null then '[No Agent]'
					else MCZBASE.get_agentnameoftype(underscore_agent_id, 'preferred')
					end
				as agentname,
				displayed_media_id,
				html_description
			FROM 
				underscore_collection
			WHERE
				collection_name like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#collection_name#">
		</cfquery>
	<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfif search.edited EQ 1 ><cfset edited_marker="*"><cfelse><cfset edited_marker=""></cfif> 
			<cfset row["coll_event_num_series_id"] = "#search.coll_event_num_series_id#">
			<cfset row["collection_name"] = "#search.collection_name#">
			<cfset row["underscore_collection_type"] = "#search.underscore_collection_type#">
			<cfset row["description"] = "#search.description#">
			<cfset row["agent_name"] = "#search.agent_name#">
			<cfset row["id_link"] = "<a href='/grouping/NamedCollection.cfm?method=edit&underscore_collection_id#search.underscore_collection_id#' target='_blank'>#search.collection_name#</a>">
			<cfset row["html_description"] = "#search.html_description#">
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

<!--- Given the primary key value for underscore_relations, remove that record of the relation
 between a collection object and an underscore collection.
 @param underscore_relation_id the primary key value of the row to remove.
 @return a structure with status deleted, count of rows deleted and the id of the deleted row, or an http 500
--->
<cffunction name="removeObjectFromUndColl" access="remote" returntype="any" returnformat="json">
	<cfargument name="underscore_relation_id" type="numeric" required="yes">
	<cftry>
		<cftransaction>
			<cfquery name="deleteQuery" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="deleteQuery_result">
				delete from underscore_relation 
				where underscore_relation_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_relation_id#" >
			</cfquery>
			<cfset rows = deleteQuery_result.recordcount>
			<cfif rows EQ 0>
				<cfthrow message="No matching underscore_relation found for underscore_relation_id=[#underscore_relation_id#].">
			<cfelseif rows GT 1>
				<cfthrow message="More than one match found for underscore_relation_id=[#underscore_relation_id#].">
				<cftransaction action="rollback">
			</cfif>
			<cfset row = StructNew()>
			<cfset row = StructNew()>
			<cfset row["status"] = "deleted">
			<cfset row["count"] = rows>
			<cfset row["id"] = "#underscore_relation_id#">
			<cfset data[1] = row>
		</cftransaction>
	<cfcatch>
		<cfset error_message = cfcatchToErrorMessage(cfcatch)>
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn #serializeJSON(data)#>
</cffunction>

<!---- function addOIbjectToUndColl 
  Given an underscore_collection_id and a string delimited list of guids, look up the collection object id 
  values for the guids and insert the underscore_collection_id - collection_object_id relationships into
  underscore_relation.  
	@param underscore_collection_id the pk of the collection to add the collection objects to.
	@param guid_list a comma delimited list of guids in the form MCZ:Col:catnum
	@return a json structure containing added=nummber of added relations.
--->
<cffunction name="addObjectsToUndColl" access="remote" returntype="any" returnformat="json">
	<cfargument name="underscore_collection_id" type="string" required="yes">
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
			<cfquery name="find" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="find_result">
				select distinct 
					collection_object_id 
				from <cfif ucase(session.flatTableName) EQ "FLAT"> flat <cfelse> filtered_flat </cfif>
				where 
					guid in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#guids#" list="yes" >)
					and collection_object_id is not null
			</cfquery>
			<cfif find_result.recordcount GT 0>
				<cfloop query=find>
					<cfquery name="check" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="check_result">
						SELECT count(*) ct
						FROM underscore_relation
						WHERE
							underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
							and
							collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#find.collection_object_id#">
					</cfquery>
					<cfif check.ct EQ 0>
						<cfquery name="add" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="add_result">
							insert into underscore_relation
							( 
								underscore_collection_id, 
								collection_object_id
							) values ( 
								<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">,
								<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#find.collection_object_id#">
							)
						</cfquery>
						<cfset rows = rows + add_result.recordcount>
					</cfif>
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

<!--- ------------------------------------------------------------------------------------ --->

<!--- Given the primary key value for underscore_collection_agent, remove that record of the relation
 between an agent and an underscore collection.
 @param underscore_coll_agent_id the primary key value of the row to remove.
 @return a structure with status deleted, count of rows deleted and the id of the deleted row, or an http 500
--->
<cffunction name="removeAgentFromUndColl" access="remote" returntype="any" returnformat="json">
	<cfargument name="underscore_coll_agent_id" type="numeric" required="yes">
	<cftry>
		<cftransaction>
			<cfquery name="deleteQuery" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="deleteQuery_result">
				delete from underscore_collection_agent 
				where underscore_coll_agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_coll_agent_id#" >
			</cfquery>
			<cfset rows = deleteQuery_result.recordcount>
			<cfif rows EQ 0>
				<cfthrow message="No matching underscore_collection_agent found for underscore_coll_agent_id=[#underscore_coll_agent_id#].">
			<cfelseif rows GT 1>
				<cfthrow message="More than one match found for underscore_coll_agent_id=[#underscore_coll_agent_id#].">
				<cftransaction action="rollback">
			</cfif>
			<cfset row = StructNew()>
			<cfset row = StructNew()>
			<cfset row["status"] = "deleted">
			<cfset row["count"] = rows>
			<cfset row["id"] = "#underscore_coll_agent_id#">
			<cfset data[1] = row>
		</cftransaction>
	<cfcatch>
		<cfset error_message = cfcatchToErrorMessage(cfcatch)>
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn #serializeJSON(data)#>
</cffunction>

<!---- function addAgentToUndColl 
  Given an underscore_collection_id, an agent_id and a role, add the agent in that
  role to the named group.  
	@param underscore_collection_id the pk of the named group to add the agent to.
	@param agent_id the agent to link.
   @param role the role in which to add that agent.
   @param remarks text concerning the relationship of this agent to the named group.
	@return a json structure containing status=success or an http 500.
--->
<cffunction name="addAgentToUndColl" access="remote" returntype="any" returnformat="json">
	<cfargument name="underscore_collection_id" type="string" required="yes">
	<cfargument name="underscore_agent_id" type="string" required="yes">
	<cfargument name="role" type="string" required="yes">
	<cfargument name="remarks" type="string" required="yes">

	<cfset data = ArrayNew(1)>
	<cftransaction>
		<cftry>
			<cfquery name="creatingAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="creatingAgent_result">
				SELECT distinct(agent_id) 
				FROM agent_name 
				WHERE 
					agent_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
					AND agent_name_type = 'login'
			</cfquery>
			<cfquery name="add" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="add_result">
				insert into underscore_collection_agent
				( 
					underscore_collection_id, 
					agent_id,
					role,
					remarks,
					created_by_agent_id
				) values ( 
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_agent_id#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#role#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#remarks#">,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#creatingAgent.agent_id#">
				)
			</cfquery>
			<cfset rowid = add_result.generatedkey>
			<cftransaction action="commit">
			<cfquery name="report" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="report_result">
				SELECT role,
					mczbase.get_agentnameoftype(agent_id) as agent_name
				FROM 
					underscore_collection_agent
				WHERE
					ROWIDTOCHAR(rowid) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#rowid#">
			</cfquery>
			<cfset i = 1>
			<cfset row = StructNew()>
			<cfset row["status"] = "success">
			<cfset row["agent_name"] = "#report.agent_name#">
			<cfset row["role"] = "#report.role#">
			<cfset data[i] = row>
			<cfreturn #serializeJSON(data)#>
		<cfcatch>
			<cftransaction action="rollback">
			<cfif cfcatch.detail CONTAINS "ORA-00001: unique constraint (MCZBASE.IDX_UCA_UNIQUE">
				<cfset error_message = "Error: That agent already has the same role in this named grouping.  The combination of Agent + Role + NamedGroup must be unique.">
			<cfelse>
				<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			</cfif>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cftransaction>
</cffunction>

<!--- Create an html form for creating a new relationship between an agent and a named group 
	@param underscore_collection_id the named group to link the agent to.
	@return an html form suitable for placement as the content of a jquery-ui dialog to create 
		the new agent-named group relation.
---> 
<cffunction name="getNewAgentRelationHtml" access="remote" returntype="string">
	<cfargument name="underscore_collection_id" type="string" required="yes">

	<cfset tn = REReplace(CreateUUID(), "[-]", "", "all") >
	<cfthread name="getNewAgentRelationThread#tn#">
		<cftry>
			<cfquery name="getRoles" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getRoles_result" timeout="#Application.short_timeout#">
				SELECT 
					role, description
				FROM
					CTUNDERSCORE_COLL_AGENT_ROLE
			</cfquery>
			<cfoutput>
				<h2>Link an Agent to this named group.</h2>
				<form id='newAgentRelationForm' onsubmit='addnewagentrel'>
					<input type='hidden' name='method' value='addAgentToUndColl'>
					<input type='hidden' name='returnformat' value='plain'>
					<input type='hidden' name='underscore_collection_id' value='#underscore_collection_id#'>
					<div class="form-row">
						<div class="col-12 col-md-6">
							<label for="underscore_agent_name#tn#" id="underscore_agent_name_label" class="data-entry-label">Agent Associated with this Named Group
							<h5 id="underscore_agent_view#tn#" class="d-inline">&nbsp;&nbsp;&nbsp;&nbsp;</h5> 
							</label>
							<div class="input-group">
								<div class="input-group-prepend">
									<span class="input-group-text smaller bg-lightgreen" id="underscore_agent_name_icon#tn#"><i class="fa fa-user" aria-hidden="true"></i></span> 
								</div>
								<input type="text" name="underscore_agent_name" id="underscore_agent_name#tn#" class="form-control rounded-right data-entry-input form-control-sm reqdClr" aria-label="Agent Name" aria-describedby="underscore_agent_name_label" value="" required>
								<input type="hidden" name="underscore_agent_id" id="underscore_agent_id#tn#" value="">
							</div>
						</div>
						<div class="col-12 col-md-6">
							<label for="role" class="data-entry-label">Role</label>
							<select name="role" aria-label="role of this agent in this named group" id="role" class="data-entry-select reqdClr" required>
								<option value=""></option>
								<cfloop query="getRoles">
									<option value="#role#">#role# (#description#)</option>
								</cfloop>
							</select>
						</div>
						<div class="col-12">
							<label for="remarks" class="data-entry-label">Remarks</label>
							<input type='text' name='remarks'id="remarks" class="data-entry-input" >
						</div>
					</div>
					<!--- Note: Save Record button is created on containing dialog by openlinkagenttogroupingdialog() js function. --->
					<script language='javascript' type='text/javascript'>
						function addagentrel(event) { 
							event.preventDefault();
							return false; 
						};
						$(document).ready(function() {
							makeRichAgentPicker('underscore_agent_name#tn#', 'underscore_agent_id#tn#', 'underscore_agent_name_icon#tn#', 'underscore_agent_view#tn#', null);
						});
					</script>
				</form> 
				<div id='agentAddResults'></div>
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
	<cfthread action="join" name="getNewAgentRelationThread#tn#" />
	<cfreturn cfthread["getNewAgentRelationThread#tn#"].output>
</cffunction>

<!--- getAgentDivHTML obtain a block of html listing agents in their roles in a named group
  including controls for editing the information. 
	@param underscore_collection_id the primary key of the named group for which to list 
    agents in their roles.
	@return a block of html.
--->
<cffunction name="getAgentDivHTML" access="remote" returntype="string" returnformat="plain">
	<cfargument name="underscore_collection_id" type="string" required="yes">

	<cfthread name="getAgentDivThread">
		<cftry>
			<cfoutput>
				<cfquery name="agents" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="agents_result" timeout="#Application.query_timeout#">
					SELECT
						underscore_coll_agent_id,
						agent_id,
						MCZBASE.get_agentnameoftype(agent_id) agent_name,
						role,
						remarks,
						created_by_agent_id,
						MCZBASE.get_agentnameoftype(created_by_agent_id) creating_agent_name,
						to_char(date_created,'YYYY-MM-DD') date_created,
						collection_name
					FROM
						underscore_collection_agent
						join underscore_collection on underscore_collection_agent.underscore_collection_id = underscore_collection.underscore_collection_id
					WHERE
						underscore_collection_agent.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
				</cfquery>
				<ul>
					<cfif agents.recordcount EQ 0>
						<li>None.</li>
					</cfif>
					<cfloop query="agents">
						<li>
							#agents.role#
							<a href="/agents/Agent.cfm?#agents.agent_id#" target="_blank">#agents.agent_name#</a>
							#remarks#
							<button id="editAgentButton#agents.underscore_coll_agent_id#" class="btn btn-xs btn-secondary" 
								onclick="openeditagenttogroupingdialog('agentDialogDiv', '#underscore_coll_agent_id#', '#collection_name#', reloadAgentBlock);" 
								aria-label="edit the agent #agents.agent_name# named grouping relationship">Edit</button>
							<button id="removeAgentButton#agents.underscore_coll_agent_id#" class="btn btn-xs btn-warning" 
								onclick="confirmDialog('Remove this agent from this named grouping?','Confirm Remove', function(){ removeUndColAgent('#underscore_coll_agent_id#', reloadAgentBlock);})"
								aria-label="remove the agent #agents.agent_name# from this named grouping">Remove</button>
						</li>
					</cfloop>
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
	<cfthread action="join" name="getAgentDivThread" />
	<cfreturn getAgentDivThread.output>
</cffunction>

<!---- function updateAgentToUndColl 
  Update the relationship between a named group and an agent.  
	@param underscore_coll_agent_id the pk of the agent-named group relationship to
     update.
	@param underscore_collection_id the pk of the named group the agent is related to.
	@param agent_id the agent to link.
   @param role the role of the agent in the named group.
   @param remarks text concerning the relationship of this agent to the named group.
	@return a json structure containing status=success or an http 500.
--->
<cffunction name="updateAgentToUndColl" access="remote" returntype="any" returnformat="json">
	<cfargument name="underscore_coll_agent_id" type="string" required="yes">
	<cfargument name="underscore_collection_id" type="string" required="yes">
	<cfargument name="underscore_agent_id" type="string" required="yes">
	<cfargument name="role" type="string" required="yes">
	<cfargument name="remarks" type="string" required="yes">

	<cfset data = ArrayNew(1)>
	<cftransaction>
		<cftry>
			<cfquery name="update" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="update_result">
				update underscore_collection_agent
				SET
					underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">,
					agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_agent_id#">,
					role = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#role#">, 
					remarks = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#remarks#">
				WHERE 
					underscore_coll_agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_coll_agent_id#">
			</cfquery>
			<cftransaction action="commit">
			<cfquery name="report" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="report_result">
				SELECT role,
					mczbase.get_agentnameoftype(agent_id) as agent_name
				FROM 
					underscore_collection_agent
				WHERE
					underscore_coll_agent_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#underscore_coll_agent_id#">
			</cfquery>
			<cfset i = 1>
			<cfset row = StructNew()>
			<cfset row["status"] = "success">
			<cfset row["agent_name"] = "#report.agent_name#">
			<cfset row["role"] = "#report.role#">
			<cfset data[i] = row>
			<cfreturn #serializeJSON(data)#>
		<cfcatch>
			<cftransaction action="rollback">
			<cfif cfcatch.detail CONTAINS "ORA-00001: unique constraint (MCZBASE.IDX_UCA_UNIQUE">
				<cfset error_message = "Error: That agent already has the same role in this named grouping.  The combination of Agent + Role + NamedGroup must be unique.">
			<cfelse>
				<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			</cfif>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cftransaction>
</cffunction>

<!----------------------------------------------------------------------------------------------------------------->
<!--- Create an html form for editing a relationship between an agent and a named group 
	@param underscore_coll_agent_id the agent-named group relationship to be edited.
	@return an html form suitable for placement as the content of a jquery-ui dialog to create the
		new agent-named group relationship.
---> 
<cffunction name="updateAgentRelationHtml" access="remote" returntype="string">
	<cfargument name="underscore_coll_agent_id" type="string" required="yes">

	<cfset tn = REReplace(CreateUUID(), "[-]", "", "all") >
	<cfthread name="updateAgentRelationThread#tn#">
		<cftry>
			<cfquery name="getData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getData_result" timeout="#Application.query_timeout#">
				SELECT 
					underscore_collection_id,
					agent_id,
					MCZBASE.get_agentnameoftype(agent_id) agent_name,
					role,
					remarks,
					created_by_agent_id,
					MCZBASE.get_agentnameoftype(created_by_agent_id) created_by_name,
					to_char(date_created,'YYYY-MM-DD') date_created
				FROM
					underscore_collection_agent
				WHERE
					underscore_coll_agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_coll_agent_id#">
			</cfquery>
			<cfquery name="getRoles" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getRoles_result" timeout="#Application.short_timeout#">
				SELECT 
					role, description
				FROM
					CTUNDERSCORE_COLL_AGENT_ROLE
			</cfquery>
			<cfoutput query="getData">
				<h2>Edit Link from #agent_name# to this named group.</h2>
				<form id='editAgentRelationForm' onsubmit='updateagentrel'>
					<input type='hidden' name='method' value='updateAgentToUndColl'>
					<input type='hidden' name='returnformat' value='plain'>
					<input type='hidden' name='underscore_coll_agent_id' value='#underscore_coll_agent_id#'>
					<input type='hidden' name='underscore_collection_id' value='#underscore_collection_id#'>
					<div class="form-row">
						<div class="col-12 col-md-6">
							<label for="underscore_agent_name#tn#" id="underscore_agent_name_label" class="data-entry-label">Agent Associated with this Named Group
							<h5 id="underscore_agent_view#tn#" class="d-inline">&nbsp;&nbsp;&nbsp;&nbsp;</h5> 
							</label>
							<div class="input-group">
								<div class="input-group-prepend">
									<span class="input-group-text smaller bg-lightgreen" id="underscore_agent_name_icon#tn#"><i class="fa fa-user" aria-hidden="true"></i></span> 
								</div>
								<input type="text" name="underscore_agent_name" id="underscore_agent_name#tn#" class="form-control rounded-right data-entry-input form-control-sm reqdClr" aria-label="Agent Name" aria-describedby="underscore_agent_name_label" value="#agent_name#" required>
								<input type="hidden" name="underscore_agent_id" id="underscore_agent_id#tn#" value="#agent_id#">
							</div>
						</div>
						<div class="col-12 col-md-6">
							<label for="role" class="data-entry-label">Role</label>
							<select name="role" aria-label="role of this agent in this named group" id="role" class="data-entry-select reqdClr" required>
								<cfloop query="getRoles">
									<cfif getData.role EQ getRoles.role><cfset selected="selected"><cfelse><cfset selected=""></cfif>
									<option value="#getRoles.role#" #selected#>#getRoles.role# (#getRoles.description#)</option>
								</cfloop>
							</select>
						</div>
						<div class="col-12">
							<label for="remarks" class="data-entry-label">Remarks</label>
							<input type='text' name='remarks'id="remarks" class="data-entry-input" value="#remarks#" >
						</div>
						<div class="col-12">
							Record Created By <a href="/agents/#created_by_agent_id#" target="_blank">#created_by_name#</a> on #date_created#
						</div>
					</div>
					<!--- Note: Save Record button is created on containing dialog by openlinkagenttogroupingdialog() js function. --->
					<script language='javascript' type='text/javascript'>
						function updateagentrel(event) { 
							event.preventDefault();
							return false; 
						};
						$(document).ready(function() {
							makeRichAgentPicker('underscore_agent_name#tn#', 'underscore_agent_id#tn#', 'underscore_agent_name_icon#tn#', 'underscore_agent_view#tn#', '#agent_id#');
						});
					</script>
				</form> 
				<div id='agentUpdateResults'></div>
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
	<cfthread action="join" name="updateAgentRelationThread#tn#" />
	<cfreturn cfthread["updateAgentRelationThread#tn#"].output>
</cffunction>

<!--- ------------------------------------------------------------------------------------ --->

<!--- Given the primary key value for underscore_collection_citation, remove that record of the relation
 between a publication and an underscore collection.
 @param underscore_coll_citation_id the primary key value of the row to remove.
 @return a structure with status deleted, count of rows deleted and the id of the deleted row, or an http 500
--->
<cffunction name="removeCitationFromUndColl" access="remote" returntype="any" returnformat="json">
	<cfargument name="underscore_coll_citation_id" type="numeric" required="yes">
	<cftry>
		<cftransaction>
			<cfquery name="deleteQuery" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="deleteQuery_result">
				delete from underscore_collection_citation 
				where underscore_coll_citation_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_coll_citation_id#" >
			</cfquery>
			<cfset rows = deleteQuery_result.recordcount>
			<cfif rows EQ 0>
				<cfthrow message="No matching underscore collection citation found for underscore_coll_citation_id=[#underscore_coll_citation_id#].">
			<cfelseif rows GT 1>
				<cfthrow message="More than one match found for underscore_coll_agent_id=[#underscore_coll_citation_id#].">
				<cftransaction action="rollback">
			</cfif>
			<cfset row = StructNew()>
			<cfset row = StructNew()>
			<cfset row["status"] = "deleted">
			<cfset row["count"] = rows>
			<cfset row["id"] = "#underscore_coll_citation_id#">
			<cfset data[1] = row>
		</cftransaction>
	<cfcatch>
		<cfset error_message = cfcatchToErrorMessage(cfcatch)>
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn #serializeJSON(data)#>
</cffunction>

<!---- function addCitationToUndColl 
  Given an underscore_collection_id, a publication_id, page range, and a type, 
   add the publication as a citation to the named group.  
	@param underscore_collection_id the pk of the named group to add the citation to.
	@param publication_id the publication to cite.
   @param type the type of citation of the publication.
   @param pages the page ranges for the of citation of the publication, if any.
   @param remarks text concerning the relationship of this publication to the named group.
	@return a json structure containing status=success or an http 500.
--->
<cffunction name="addCitationToUndColl" access="remote" returntype="any" returnformat="json">
	<cfargument name="underscore_collection_id" type="string" required="yes">
	<cfargument name="publication" type="string" required="yes">
	<cfargument name="type" type="string" required="yes">
	<cfargument name="pages" type="string" required="yes">
	<cfargument name="citation_page_uri" type="string" required="yes">
	<cfargument name="remarks" type="string" required="yes">

	<cfset data = ArrayNew(1)>
	<cftransaction>
		<cftry>
			<cfquery name="creatingAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="creatingAgent_result">
				SELECT distinct(agent_id) 
				FROM agent_name 
				WHERE 
					agent_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
					AND agent_name_type = 'login'
			</cfquery>
			<cfquery name="add" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="add_result">
				insert into underscore_collection_citation
				( 
					underscore_collection_id, 
					publication_id,
					type,
					pages,
					remarks,
					citation_page_uri,
					created_by_agent_id
				) values ( 
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#type#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#pages#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#remarks#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#citation_page_uri#">,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#creatingAgent.agent_id#">
				)
			</cfquery>
			<cfset rowid = add_result.generatedkey>
			<cftransaction action="commit">
			<cfquery name="report" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="report_result">
				SELECT 
					type,
					mczbase.getshortcitation(publication_id) as publication
				FROM 
					underscore_collection_citation
				WHERE
					ROWIDTOCHAR(rowid) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#rowid#">
			</cfquery>
			<cfset i = 1>
			<cfset row = StructNew()>
			<cfset row["status"] = "success">
			<cfset row["publication"] = "#report.publication#">
			<cfset row["type"] = "#report.type#">
			<cfset data[i] = row>
			<cfreturn #serializeJSON(data)#>
		<cfcatch>
			<cftransaction action="rollback">
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cftransaction>
</cffunction>


<!--- Create an html form for creating a new citation of a publication for a named group 
	@param underscore_collection_id the named group to link the publication to.
	@return an html form suitable for placement as the content of a jquery-ui dialog to create 
		the new publication-named group relation.
---> 
<cffunction name="getNewUndCollCitationHtml" access="remote" returntype="string">
	<cfargument name="underscore_collection_id" type="string" required="yes">

	<cfset tn = REReplace(CreateUUID(), "[-]", "", "all") >
	<cfthread name="getNewUndCollCitationThread#tn#">
		<cftry>
			<cfquery name="getTypes" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getTypes_result" timeout="#Application.short_timeout#">
				SELECT 
					type, description
				FROM
					CTUNDERSCORE_COLL_CIT_TYPE
			</cfquery>
			<cfoutput>
				<h2>Link a publication to this named group.</h2>
				<form id='newCitationForm' onsubmit='addNewUndCollCitation'>
					<input type='hidden' name='method' value='addCitationToUndColl'>
					<input type='hidden' name='returnformat' value='plain'>
					<input type='hidden' name='underscore_collection_id' value='#underscore_collection_id#'>
					<div class="form-row">
						<div class="col-12 col-md-6">
							<label for="underscore_agent_name#tn#" id="underscore_agent_name_label" class="data-entry-label">
								Publication Associated with this Named Group
							</label>
							<input type="hidden" name="publication_id" id="publication_id">
							<input type="text" id="publication" name="publication" class="data-entry-input mb-1 reqdClr" required >
						</div>
						<div class="col-12 col-md-4">
							<label for="type" class="data-entry-label">Type of Citation</label>
							<select name="type" aria-label="how this publication is related to the named group" id="type" class="data-entry-select reqdClr" required >
								<option value=""></option>
								<cfloop query="getTypes">
									<option value="#type#">#type# (#description#)</option>
								</cfloop>
							</select>
						</div>
						<div class="col-12 col-md-2">
							<label for="remarks" class="data-entry-label">Page(s)</label>
							<input type='text' name='pages'id="pages" class="data-entry-input" >
						</div>
						<div class="col-12">
							<label for="citation_page_uri" class="data-entry-label">URI for first page of citation</label>
							<input type='text' name='citation_page_uri'id="citation_page_uri" class="data-entry-input" >
						</div>
						<div class="col-12">
							<label for="remarks" class="data-entry-label">Remarks</label>
							<input type='text' name='remarks'id="remarks" class="data-entry-input" >
						</div>
					</div>
					<!--- Note: Save Record button is created on containing dialog by the create dialog js function. --->
					<script language='javascript' type='text/javascript'>
						function addNewUndCollCitation(event) { 
							event.preventDefault();
							return false; 
						};
						$(document).ready(function() {
							makePublicationAutocompleteMeta('publication', 'publication_id'); 
						});
					</script>
				</form> 
				<div id='citationAddResults'></div>
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
	<cfthread action="join" name="getNewUndCollCitationThread#tn#" />
	<cfreturn cfthread["getNewUndCollCitationThread#tn#"].output>
</cffunction>

<!--- getCitationDivHTML obtain a block of html listing publication citations of a named group
  including controls for editing the information. 
	@param underscore_collection_id the primary key of the named group for which to list 
    citations.
	@return a block of html.
--->
<cffunction name="getCitationDivHTML" access="remote" returntype="string" returnformat="plain">
	<cfargument name="underscore_collection_id" type="string" required="yes">

	<cfthread name="getCitationDivThread">
		<cftry>
			<cfoutput>
				<cfquery name="citations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="citations_result" timeout="#Application.query_timeout#">
					SELECT
						underscore_coll_citation_id,
						publication_id,
						MCZBASE.getfullcitation(publication_id) publication,
						MCZBASE.getshortcitation(publication_id) short_publication,
						type,
						pages,
						remarks,
						citation_page_uri,
						created_by_agent_id,
						MCZBASE.get_agentnameoftype(created_by_agent_id) creating_agent_name,
						to_char(date_created,'YYYY-MM-DD') date_created,
						collection_name
					FROM
						underscore_collection_citation
						join underscore_collection on underscore_collection_citation.underscore_collection_id = underscore_collection.underscore_collection_id
					WHERE
						underscore_collection_citation.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
				</cfquery>
				<ul>
					<cfif citations.recordcount EQ 0>
						<li>None.</li>
					</cfif>
					<cfloop query="citations">
						<li>
							#citations.type#
							<a href="/publications/showPublication.cfm?publication_id=#citations.publication_id#" target="_blank">#citations.publication#</a>
							<cfif len(citation_page_uri) GT 0>
								<cfif len(pages) EQ 0>
									<a href="#citation_page_uri#" target="_blank">[Link]</a>
								<cfelse>
									<a href="#citation_page_uri#" target="_blank">#pages#</a>
								</cfif>
							<cfelse>
								#pages#
							</cfif>
							#remarks#
							<span class="small">[Created #date_created# by <a href="/agents/created_by_agent_id" target="_blank">#creating_agent_name#</a>]</span>
							<button id="editGroupingCiteButton#citations.underscore_coll_citation_id#" class="btn btn-xs btn-secondary" 
								onclick="openeditgroupingcitationdialog('citationDialogDiv', '#underscore_coll_citation_id#', '#collection_name#', reloadCitationBlock);" 
								aria-label="edit the publication #citations.short_publication# named grouping relationship">Edit</button>
							<button id="removeGroupingCiteButton#citations.underscore_coll_citation_id#" class="btn btn-xs btn-warning" 
								onclick="confirmDialog('Remove the citation of #citations.short_publication# from this named grouping (#collection_name#)?','Confirm Remove', function(){ removeUndCollCitation('#underscore_coll_citation_id#', reloadCitationBlock);})"
								aria-label="remove the citation of #citations.short_publication# from this named grouping">Remove</button>
						</li>
					</cfloop>
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
	<cfthread action="join" name="getCitationDivThread" />
	<cfreturn getCitationDivThread.output>
</cffunction>


<!---- function updateUndCollCitation 
  Update the relationship between a named group and a publication.  
	@param underscore_coll_citation_id the pk of the named group citation to
     update.
	@param underscore_collection_id the pk of the named group the citation is related to.
	@param publication_id the cited publication.
   @param type the type of the citation the named group.
   @param remarks text concerning the citation.
	@param pages cited.
	@param citation_page_uri uri for the first cited page
	@return a json structure containing status=success or an http 500.
--->
<cffunction name="updateUndCollCitation" access="remote" returntype="any" returnformat="json">
	<cfargument name="underscore_coll_citation_id" type="string" required="yes">
	<cfargument name="underscore_collection_id" type="string" required="yes">
	<cfargument name="publication_id" type="string" required="yes">
	<cfargument name="type" type="string" required="yes">
	<cfargument name="remarks" type="string" required="yes">
	<cfargument name="pages" type="string" required="yes">
	<cfargument name="citation_page_uri" type="string" required="yes">

	<cfset data = ArrayNew(1)>
	<cftransaction>
		<cftry>
			<cfquery name="update" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="update_result">
				update underscore_collection_citation
				SET
					underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">,
					publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">,
					type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#type#">, 
					remarks = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#remarks#">,
					pages = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#pages#">,
					citation_page_uri = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#citation_page_uri#">
				WHERE 
					underscore_coll_citation_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_coll_citation_id#">
			</cfquery>
			<cftransaction action="commit">
			<cfquery name="report" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="report_result">
				SELECT 
					type,
					mczbase.getshortcitation(publication_id) as publication
				FROM 
					underscore_collection_citation
				WHERE
					underscore_coll_citation_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#underscore_coll_citation_id#">
			</cfquery>
			<cfset i = 1>
			<cfset row = StructNew()>
			<cfset row["status"] = "success">
			<cfset row["publication"] = "#report.publication#">
			<cfset row["type"] = "#report.type#">
			<cfset data[i] = row>
			<cfreturn #serializeJSON(data)#>
		<cfcatch>
			<cftransaction action="rollback">
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cftransaction>
</cffunction>

<!----------------------------------------------------------------------------------------------------------------->
<!--- Create an html form for editing a citation of a publication in a named group 
      @param underscore_coll_citation_id the citation of the named group to update.
      @return an html form suitable for placement as the content of a jquery-ui dialog to create the new citation.
---> 
<cffunction name="updateCitationHtml" access="remote" returntype="string">
	<cfargument name="underscore_coll_citation_id" type="string" required="yes">

	<cfset tn = REReplace(CreateUUID(), "[-]", "", "all") >
	<cfthread name="updateUndCollCitationThread#tn#">
		<cftry>
			<cfquery name="getData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getData_result" timeout="#Application.query_timeout#">
				SELECT 
					underscore_collection_id,
					publication_id,
					MCZBASE.getshortcitation(publication_id) short_citation,
					MCZBASE.getfullcitation(publication_id) long_citation,
					type,
					remarks,
					pages,
					citation_page_uri,
					created_by_agent_id,
					MCZBASE.get_agentnameoftype(created_by_agent_id) created_by_name,
					to_char(date_created,'YYYY-MM-DD') date_created
				FROM
					underscore_collection_citation
				WHERE
					underscore_coll_citation_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_coll_citation_id#">
			</cfquery>
			<cfquery name="getTypes" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getTypes_result" timeout="#Application.short_timeout#">
				SELECT 
					type, description
				FROM
					CTUNDERSCORE_COLL_CIT_TYPE
			</cfquery>
			<cfoutput query="getData">
				<h2>Edit citation of #short_citation# for this named group.</h2>
				<form id='editUndCollCitationForm' onsubmit='updatecitation'>
					<input type='hidden' name='method' value='updateUndCollCitation'>
					<input type='hidden' name='returnformat' value='plain'>
					<input type='hidden' name='underscore_coll_citation_id' value='#underscore_coll_citation_id#'>
					<input type='hidden' name='underscore_collection_id' value='#underscore_collection_id#'>
					<div class="form-row">
						<div class="col-12 col-md-6">
							<label for="publication#tn#" id="publication_label" class="data-entry-label">Publication</label>
							<input type="text" name="publication" id="publication#tn#" class="data-entry-input" value="#long_citation#" >
							<input type='hidden' name='publication_id' id="publication_id#tn#" value='#publication_id#'>
						</div>
						<div class="col-12 col-md-6">
							<label for="type" class="data-entry-label">Type</label>
							<select name="type" aria-label="type of citation of this named group" id="type" class="data-entry-select reqdClr" required>
								<cfloop query="getTypes">
									<cfif getData.type EQ getTypes.type><cfset selected="selected"><cfelse><cfset selected=""></cfif>
									<option value="#getTypes.type#" #selected#>#getTypes.type# (#getTypes.description#)</option>
								</cfloop>
							</select>
						</div>
						<div class="col-12 col-md-6">
							<label for="pages" class="data-entry-label">Page(s)</label>
							<input type="text" name="pages" id="pages" class="data-entry-input" value="#pages#" >
						</div>
						<div class="col-12 col-md-6">
							<label for="citation_page_uri" class="data-entry-label">URI for first page of citation</label>
							<input type="text" name="citation_page_uri" id="citation_page_uri" class="data-entry-input" value="#citation_page_uri#" >
						</div>
						<div class="col-12">
							<label for="remarks" class="data-entry-label">Remarks</label>
							<input type="text" name="remarks" id="remarks" class="data-entry-input" value="#remarks#" >
						</div>
						<div class="col-12">
							Record Created By <a href="/agents/#created_by_agent_id#" target="_blank">#created_by_name#</a> on #date_created#
						</div>
					</div>
					<!--- Note: Save Record button is created on containing dialog by openeditgroupingcitationdialog() js function. --->
					<script language='javascript' type='text/javascript'>
						function updatecitation(event) { 
							event.preventDefault();
							return false; 
						};
						$(document).ready(function() {
							function makePublicationAutocompleteMeta("publication#tn#", "publication_id#tn#") { 
						});
					</script>
				</form> 
				<div id="citationUpdateResults"></div>
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
	<cfthread action="join" name="updateUndCollCitationThread#tn#" />
	<cfreturn cfthread["updateUndCollCitationThread#tn#"].output>
</cffunction>

</cfcomponent>
