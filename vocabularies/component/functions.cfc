<!---
vocabularies/component/functions.cfc

Copyright 2020-2021 President and Fellows of Harvard College

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

<!--- function saveNumSeries 
Update an existing collecting event number series record.

@param coll_event_num_series_id primary key of record to update
@param number_series the brief human readable description of the number series, must not be blank.
@param pattern pattern expected of values in the number series
@param remarks remarks about the number series
@param collector_agent_id the collector for whom this is a number series
@return json structure with status and id or http status 500
--->
<cffunction name="saveNumSeries" access="remote" returntype="any" returnformat="json">
	<cfargument name="coll_event_num_series_id" type="string" required="yes">
	<cfargument name="number_series" type="string" required="yes">
	<cfargument name="pattern" type="string" required="no">
	<cfargument name="remarks" type="string" required="no">
	<cfargument name="collector_agent_id" type="string" required="no">

	<cfset data = ArrayNew(1)>
	<cftry>
		<cfif len(trim(#number_series#)) EQ 0>
			<cfthrow type="Application" message="Number Series must contain a value.">
		</cfif>
		<cfquery name="save" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			update coll_event_num_series set
				number_series = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#number_series#">
				<cfif isdefined("pattern")>
					,pattern = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#pattern#">
				</cfif>
				<cfif isdefined("remarks")>
					,remarks = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#remarks#">
				</cfif>
				<cfif isdefined("collector_agent_id")>
					,collector_agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collector_agent_id#">
				</cfif>
			where 
				coll_event_num_series_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#coll_event_num_series_id#">
		</cfquery>
		<cfset row = StructNew()>
		<cfset row["status"] = "saved">
		<cfset row["id"] = "#coll_event_num_series_id#">
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
Function getNumSeriesList.  Search for collector number series returning json suitable for a dataadaptor.

@param number_series name of the number series to search for.
@return a json structure containing matching coll event number series.
--->
<cffunction name="getNumSeriesList" access="remote" returntype="any" returnformat="json">
	<cfargument name="number_series" type="string" required="yes">
	<!--- perform wildcard search anywhere in coll_event_number_series.number_series --->
	<cfset number_series = "%#number_series#%"> 

	<cfset data = ArrayNew(1)>
	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			SELECT 
				coll_event_number_series_id, number_series, pattern, remarks,
				collector_agent_id, 
				case 
					when collector_agent_id is null then '[No Agent]'
					else MCZBASE.get_agentnameoftype(collector_agent_id, 'preferred')
					end
				as agentname
			FROM 
				coll_event_number_series
			WHERE
				number_series like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#number_series#">
		</cfquery>
	<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfif search.edited EQ 1 ><cfset edited_marker="*"><cfelse><cfset edited_marker=""></cfif> 
			<cfset row["coll_event_num_series_id"] = "#search.coll_event_num_series_id#">
			<cfset row["number_series"] = "#search.number_series#">
			<cfset row["pattern"] = "#search.pattern#">
			<cfset row["remarks"] = "#search.remarks#">
			<cfset row["agentname"] = "#search.agentname#">
			<cfset row["id_link"] = "<a href='/vocabularies/CollEventNumberSeries.cfm?method=edit&coll_event_num_series_id#search.coll_event_num_series_id#' target='_blank'>#search.number_series#</a>">
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

/**  Geological attribute management functions **/

/** addGeologicalAttribute add a record to the geology_attribute_heirarchy table providing a 
 * controlled vocabulary for geological attributes.
 */
<cffunction name="addGeologicalAttribute" access="remote" returntype="any" returnformat="json">
	<cfargument name="attribute" type="string" required="yes">
	<cfargument name="attribute_value" type="string" required="yes">
	<cfargument name="usable_value_fg" type="string" required="yes">
	<cfargument name="description" type="string" required="yes">

	<cfset theResult=queryNew("status, message")>
	<cftransaction>
		<cftry>
			<cfquery name="check" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT count(*) ct 
				FROM geology_attribute_hierarchy
				WHERE
					attribute = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#attribute#">
					AND
					attribute_value = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#attribute_value#">
			</cfquery>
			<cfloop query="check">
				<cfif check.ct NEQ 0>
					<cfthrow message="Unable to insert. A geological attribute of type=[#encodeForHTML(attribute)#] and value=[#encodeForHTML(attribute_value)#] already exists.">
				</cfif>
			</cfloop>
			<cfquery name="addGeog" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="addGeog_result">
				insert into geology_attribute_hierarchy 
					(attribute,
					attribute_value,
					usable_value_fg,
					description) 
				values
					(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#attribute#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#attribute_value#">,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#usable_value_fg#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#description#">)
			</cfquery>
			<cfif addGeog_result.recordcount eq 1>
				<cfset t = queryaddrow(theResult,1)>
				<cfset t = QuerySetCell(theResult, "status", "1", 1)>
				<cfset t = QuerySetCell(theResult, "message", "Added #encodeForHTML(attribute)#:#encodeForHTML(attribute_value)#", 1)>
			<cfelse>
				<cfthrow message="Error adding a geological attribute value.">
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

<cffunction name="unlinkChildGeologicalAttribute" access="remote" returntype="any" returnformat="json">
	<cfargument name="child" type="string" required="yes">

	<cftransaction>
		<cftry>
			<cfquery name="removeLink" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE geology_attribute_hierarchy 
				SET parent_id = NULL 
				WHERE 
					geology_attribute_hierarchy_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#child#">
			</cfquery>
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

<cffunction name="linkGeologicalAttributes" access="remote" returntype="any" returnformat="json">
	<cfargument name="child" type="string" required="yes">
	<cfargument name="parent" type="string" required="yes">

	<cftransaction>
		<cftry>
			<cfif parent EQ child>
				<cfthrow message="Unable to link a node to itself.">
			</cfif>
			<!--- Check to make sure that the parent and child attributes are of the same type --->
			<cfquery name="checkLink" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT count(distinct type) ct FROM (
					SELECT type
					FROM
						geology_attribute_hierarchy p
						left join ctgeology_attribute pct on p.attribute = pct.geology_attribute
					WHERE
						geology_attribute_hierarchy_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#parent#">
					UNION
					SELECT type
					FROM
						geology_attribute_hierarchy c
						left join ctgeology_attribute cct on c.attribute = cct.geology_attribute
					WHERE
						geology_attribute_hierarchy_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#child#">
				)
			</cfquery>
			<cfloop query="checkLink">
				<cfif checkLink.ct NEQ 1>
					<cfthrow message="Unable to link. The Parent and Child attributes must be of the same type (e.g. a lithologic attribute can't be a parent of a chronostratigraphic attribute).">
				</cfif>
			</cfloop>
			<cfquery name="checkCycle" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT count(*) ct FROM (
					SELECT
						geology_attribute_hierarchy_id,
					FROM
						geology_attribute_hierarchy
					START WITH geology_attribute_hierarchy_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#child#">
		       	CONNECT BY PRIOR geology_attribute_hierarchy_id = parent_id
	   	 		ORDER SIBLINGS BY ordinal, attribute_value
				)
				WHERE
					geology_attribute_hierarchy_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#parent#">
			</cfquery>
			<cfloop query="checkCycle">
				<cfif checkCycle.ct GT 0 >
					<cfthrow message="Unable to link, the new relationship would be cyclial, creating a map instead of a tree.  The child node can't point to a parent which is nested beneath it in the tree.">
				</cfif>
			</cfloop>

			<cfquery name="changeLink" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE geology_attribute_hierarchy 
				SET parent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#parent#">
				WHERE 
					geology_attribute_hierarchy_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#child#">
			</cfquery>
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

</cfcomponent>
