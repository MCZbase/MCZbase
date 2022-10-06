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
@param underscore_agent_id the agent associated with this arbitrary collection
@return json structure with status and id or http status 500
--->
		
			
<cffunction name="saveUndColl" access="remote" returntype="any" returnformat="json">
	<cfargument name="underscore_collection_id" type="string" required="yes">
	<cfargument name="underscore_collection_type" type="string" required="yes">
	<cfargument name="collection_name" type="string" required="yes">
	<cfargument name="description" type="string" required="no">
	<cfargument name="html_description" type="string" required="no">
	<cfargument name="underscore_agent_id" type="string" required="no">
	<cfargument name="displayed_media_id" type="string" required="no">
	<cfargument name="mask_fg" type="string" required="no">
	<cfset data = ArrayNew(1)>
	<cftry>
		<cfif len(trim(#collection_name#)) EQ 0>
			<cfthrow type="Application" message="Name of named group must contain a value.">
		</cfif>
		<cfquery name="save" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			update underscore_collection set
				collection_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#collection_name#">,
				underscore_collection_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#underscore_collection_type#">
				<cfif isdefined("description")>
					,description = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#description#">
				</cfif>
				<cfif isdefined("underscore_agent_id") and len(underscore_agent_id) GT 0>
					,underscore_agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_agent_id#">
				<cfelse>
					,underscore_agent_id = NULL
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
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
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
			<cfquery name="deleteQuery" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="deleteQuery_result">
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
			<cfquery name="find" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="find_result">
				select distinct 
					collection_object_id 
				from <cfif ucase(session.flatTableName) EQ "FLAT"> flat <cfelse> filtered_flat </cfif>
				where 
					guid in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#guids#" list="yes" >)
					and collection_object_id is not null
			</cfquery>
			<cfif find_result.recordcount GT 0>
				<cfloop query=find>
					<cfquery name="check" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="check_result">
						SELECT count(*) ct
						FROM underscore_relation
						WHERE
							underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
							and
							collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#find.collection_object_id#">
					</cfquery>
					<cfif check.ct EQ 0>
						<cfquery name="add" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="add_result">
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

<!--- Given the primary key value for underscore_coll_agent, remove that record of the relation
 between an agent and an underscore collection.
 @param underscore_coll_agent_id the primary key value of the row to remove.
 @return a structure with status deleted, count of rows deleted and the id of the deleted row, or an http 500
--->
<cffunction name="removeAgentFromUndColl" access="remote" returntype="any" returnformat="json">
	<cfargument name="underscore_coll_agent_id" type="numeric" required="yes">
	<cftry>
		<cftransaction>
			<cfquery name="deleteQuery" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="deleteQuery_result">
				delete from underscore_coll_agent 
				where underscore_coll_agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_coll_agent_id#" >
			</cfquery>
			<cfset rows = deleteQuery_result.recordcount>
			<cfif rows EQ 0>
				<cfthrow message="No matching underscore_relation found for underscore_coll_agent_id=[#underscore_coll_agent_id#].">
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
	<cfargument name="agent_id" type="string" required="yes">
	<cfargument name="role" type="string" required="yes">
	<cfargument name="remarks" type="string" required="yes">

	<cfset data = ArrayNew(1)>
	<cftransaction>
		<cftry>
			<cfquery name="creatingAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="creatingAgent_result">
				SELECT distinct(agent_id) 
				FROM agent_name 
				WHERE 
					agent_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
					AND agent_name_type = 'login'
			</cfquery>
			<cfquery name="add" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="add_result">
				insert into underscore_coll_agent
				( 
					underscore_collection_id, 
					agent_id,
					role,
					remarks,
					created_by_agent_id
				) values ( 
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#role#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#remarks#">,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#creatingAgent.agent_id#">,
				)
			</cfquery>
			<cftransaction action="commit">
			<cfset i = 1>
			<cfset row = StructNew()>
			<cfset row["status"] = "success">
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
<!--- Create an html form for creating a new relationship between an agent and a named group 
      @param underscore_collection_id the named group to link the agent to.
      @return an html form suitable for placement as the content of a jquery-ui dialog to create the new permit.
---> 
<cffunction name="getNewAgentRelationHtml" access="remote" returntype="string">
	<cfargument name="underscore_collection_id" type="string" required="yes">

	<cfthread name="getNewAgentRelationThread">
		<cftry>
			<cfquery name="getRoles" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getRoles_result">
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
							<label for="underscore_agent_name" id="underscore_agent_name_label" class="data-entry-label">Agent Associated with this Named Group
							<h5 id="underscore_agent_view" class="d-inline">&nbsp;&nbsp;&nbsp;&nbsp;</h5> 
							</label>
							<div class="input-group">
								<div class="input-group-prepend">
									<span class="input-group-text smaller bg-lightgreen" id="underscore_agent_name_icon"><i class="fa fa-user" aria-hidden="true"></i></span> 
								</div>
							<input type="text" name="underscore_agent_name" id="underscore_agent_name" class="form-control rounded-right data-entry-input form-control-sm" aria-label="Agent Name" aria-describedby="underscore_agent_name_label" value="">
							<input type="hidden" name="underscore_agent_id" id="underscore_agent_id" value="">
						</div>
						<div class="col-12 col-md-6">
							<label for="role" class="data-entry-label">Role</label>
							<select name="role" aria-label="role of this agent in this named group" id="role" class="data-entry-select">
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
	<cfthread action="join" name="getNewAgentRelationThread" />
	<cfreturn getNewAgentRelationThread.output>
</cffunction>

<cffunction name="getAgentDivHTML" access="remote" returntype="string">
	<cfargument name="underscore_collection_id" type="string" required="yes">

	<cfthread name="getAgentDivThread">
		<cftry>
			<cfoutput>
				<cfquery name="agents" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="agents_result">
					SELECT
						underscore_coll_agent_id,
						agent_id,
						MCZBASE.get_agentnameoftype(agent_id) agent_name,
						role,
						remarks,
						created_by_agent_id,
						MCZBASE.get_agentnameoftype(created_by_agent_id) creating_agent_name,
						to_char(date_created,'YYYY-MM-DD') date_created
					FROM
						underscore_collection_agent
					WHERE
						underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
				</cfquery>
				<ul>
					<cfloop query="agents">
						<li>
							<a href="/agents/#agents.agent_id#" target="_blank">#agents.agent_name#</a>
							(#agents.agent_role#) 
							<button id="removeAgentButton#agents.underscore_coll_agent_id#" class="btn btn-xs btn-warning" aria-label="remove the agent #agents.agent_name# from this named grouping">Remove</button>
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

</cfcomponent>
