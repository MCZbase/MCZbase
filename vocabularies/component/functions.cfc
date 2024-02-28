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

<!--- *****  Geological attribute management functions *****  --->

<!--- 
Function addGeologicalAttribute add a record to the geology_attribute_heirarchy table providing a controlled 
	vocabulary for geological attributes.
--->
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

<!--- 
Function updateGeologicalAttribute update a record in the geology_attribute_heirarchy table providing a controlled 
	vocabulary for geological attributes.
--->
<cffunction name="updateGeologicalAttribute" access="remote" returntype="any" returnformat="json">
	<cfargument name="geology_attribute_hierarchy_id" type="string" required="yes">
	<cfargument name="attribute" type="string" required="no">
	<cfargument name="attribute_value" type="string" required="no">
	<cfargument name="usable_value_fg" type="string" required="yes">
	<cfargument name="description" type="string" required="yes">

	<cfif not isDefined("attribute")><cfset attribute=""></cfif>
	<cfif not isDefined("attribute_value")><cfset attribute_value=""></cfif>
	<cfset theResult=queryNew("status, message")>
	<cftransaction>
		<cftry>
			<cfif len(attribute) GT 0 AND len(attribute_value) EQ 0>
				<cfthrow message = "Unable to update.  If an attribute is provided, attribute value must also be provided">
			</cfif>
			<cfif len(attribute) EQ 0 AND len(attribute_value) GT 0>
				<cfthrow message = "Unable to update.  If an attribute value is provided, attribute must also be provided">
			</cfif>
			<cfif len(attribute) GT 0>
				<!--- Prevent duplication of an existing attribute --->
				<cfquery name="check" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT count(*) ct 
					FROM geology_attribute_hierarchy
					WHERE
						attribute = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#attribute#">
						AND
						attribute_value = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#attribute_value#">
						AND
						geology_attribute_hierarchy_id <> <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geology_attribute_hierarchy_id#">
				</cfquery>
				<cfloop query="check">
					<cfif check.ct NEQ 0>
						<cfthrow message="Unable to insert. A geological attribute of type=[#encodeForHTML(attribute)#] and value=[#encodeForHTML(attribute_value)#] already exists.">
					</cfif>
				</cfloop>
			</cfif>
			<cfquery name="updateGeog" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="updateGeog_result">
				UPDATE geology_attribute_hierarchy 
				SET
					<cfif len(attribute) GT 0>
						attribute = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#attribute#">,
					</cfif>
					<cfif len(attribute_value) GT 0>
						attribute_value = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#attribute_value#">,
					</cfif>
					usable_value_fg = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#usable_value_fg#">,
					description = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#description#">
				WHERE
					geology_attribute_hierarchy_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geology_attribute_hierarchy_id#">
			</cfquery>
			<cfif updateGeog_result.recordcount eq 1>
				<cfquery name="reportGeog" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="reportGeog_result">
					SELECT attribute, attribute_value 
					FROM 
						geology_attribute_hierarchy
					WHERE
						geology_attribute_hierarchy_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geology_attribute_hierarchy_id#">
				</cfquery>
				<cfset t = queryaddrow(theResult,1)>
				<cfset t = QuerySetCell(theResult, "status", "1", 1)>
				<cfset t = QuerySetCell(theResult, "message", "Updated #encodeForHTML(reportGeog.attribute)#:#encodeForHTML(reportGeog.attribute_value)#", 1)>
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

<!--- ** unlinkChildGeologicalAttribute unlink a node in the geological attribute hierarchy 
  * from a tree into which it is placed by setting its parent_id to null, this does not alter
  * the relationship of children of the node to be unlinked, they remain as children of the unlinked node.
  * @param child the geology_attribute_hierarchy_id of the node that is to be unlinked.
  * @return json containing status=1 and message on success, http 500 response on an error.
--->
<cffunction name="unlinkChildGeologicalAttribute" access="remote" returntype="any" returnformat="json">
	<cfargument name="child" type="string" required="yes">

	<cfset theResult=queryNew("status, message")>
	<cftransaction>
		<cftry>
			<cfquery name="removeLink" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="removeLink_result">
				UPDATE geology_attribute_hierarchy 
				SET parent_id = NULL 
				WHERE 
					geology_attribute_hierarchy_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#child#">
			</cfquery>
			<cfif removeLink_result.recordcount eq 1>
				<cfset t = queryaddrow(theResult,1)>
				<cfset t = QuerySetCell(theResult, "status", "1", 1)>
				<cfset t = QuerySetCell(theResult, "message", "Unlinked child from parent.", 1)>
			<cfelse>
				<cfthrow message="Error removing a parent:child relationship.">
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

<!--- ** mergeGeologicalAttributes merge one node in the geological hierarchy tree into another, 
  * updating all related geology_attribute values to reflect the attribute/attribute value of the 
  * merge target, this will also move child nodes of the nodeToMerge to be child nodes of mergeTarget.
  * @param nodeToMerge the geology_attribute_hierarchy_id of the node that is to be merged into the mergeTarget
  * @param mergeTarget the geology_attribute_hierarchy_id of the node into which nodeToMerge is to be merged
  * @return json containing status=1 and message on success, http 500 response on an error.
--->
<cffunction name="mergeGeologicalAttributes" access="remote" returntype="any" returnformat="json">
	<cfargument name="nodeToMerge" type="string" required="yes">
	<cfargument name="mergeTarget" type="string" required="yes">

	<cfset theResult=queryNew("status, message")>
	<cftransaction>
		<cftry>
			<!--- confirm that both nodes exist --->
			<cfquery name="toMerge" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="toMergeLink_result">
				SELECT
					attribute_value, attribute, usable_value_fg
				FROM 
					geology_attribute_hierarchy
				WHERE 
					geology_attribute_hierarchy_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#nodeToMerge#">
			</cfquery>
			<cfif toMerge.recordcount NEQ 1>
				<cfthrow message="Node to merge not found.">
			</cfif>
			<cfquery name="mergeInto" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="mergeIntoLink_result">
				SELECT
					attribute_value, attribute, usable_value_fg
				FROM 
					geology_attribute_hierarchy
				WHERE 
					geology_attribute_hierarchy_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#mergeTarget#">
			</cfquery>
			<cfif mergeInto.recordcount NEQ 1>
				<cfthrow message="Node to merge into not found.">
			</cfif>
			<cfif toMerge.usable_value_fg EQ 1 AND mergeInto.usable_value_fg EQ 0>
				<cfthrow message="A node which is valid for data entry can not be merged into a node which is not valid for data entry.">
			</cfif>
			<!--- unlink the node to be removed from its parent --->
			<cfquery name="removeLink" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="removeLink_result">
				UPDATE geology_attribute_hierarchy 
				SET parent_id = NULL 
				WHERE 
					geology_attribute_hierarchy_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#nodeToMerge#">
			</cfquery>
			<!--- move any child nodes of the node to be merged to be children of the merge target --->
			<cfquery name="updateLinks" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="updateLinks_result">
				UPDATE geology_attribute_hierarchy 
				SET parent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#mergeTarget#">
				WHERE 
					parent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#nodeToMerge#">
			</cfquery>
			<!--- move all geology_attributes to the merge target --->
			<cfquery name="updateAttributes" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="updateAttributes_result">
				UPDATE geology_attributes
				SET
					geology_attribute = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#mergeInto.attribute#">,
					geo_att_value = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#mergeInto.attribute_value#">,
					geo_att_remark = trim(geo_att_remark || ' Previous value:' || <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#toMerge.attribute_value#">)
				WHERE
					geology_attribute = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#toMerge.attribute#"> AND
					geo_att_value = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#toMerge.attribute_value#">
			</cfquery>
			<!--- merge complete, remove the merged node from the tree --->
			<cfquery name="removeNode" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="removeNode_result">
				DELETE FROM geology_attribute_hierarchy 
				WHERE 
					geology_attribute_hierarchy_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#nodeToMerge#">
			</cfquery>
			<cfif removeNode_result.recordcount NEQ 1>
				<cfthrow message="Error removing node.">
			</cfif>
			<cfset t = queryaddrow(theResult,1)>
			<cfset t = QuerySetCell(theResult, "status", "1", 1)>
			<cfset t = QuerySetCell(theResult, "message", "Merged #toMerge.attribute_value# into #mergeInto.attribute_value#", 1)>
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

<!--- ** linkGeologicalAttribute link two nodes in the geological hierarchy tree into a parent-child relationship.
  * @param child the geology_attribute_hierarchy_id of the node that is to be the child
  * @param parent the geology_attribute_hierarchy_id of the node that is to be the parent
  * @return json containing status=1 and message on success, http 500 response on an error.
--->
<cffunction name="linkGeologicalAttributes" access="remote" returntype="any" returnformat="json">
	<cfargument name="child" type="string" required="yes">
	<cfargument name="parent" type="string" required="yes">

	<cfset theResult=queryNew("status, message")>
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
						geology_attribute_hierarchy_id
					FROM
						geology_attribute_hierarchy
					START WITH geology_attribute_hierarchy_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#child#">
		       	CONNECT BY PRIOR geology_attribute_hierarchy_id = parent_id
	   	 		ORDER SIBLINGS BY attribute_value
				)
				WHERE
					geology_attribute_hierarchy_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#parent#">
			</cfquery>
			<cfloop query="checkCycle">
				<cfif checkCycle.ct GT 0 >
					<cfthrow message="Unable to link, the new relationship would be cyclial, creating a map instead of a tree.  The child node can't point to a parent which is nested beneath it in the tree.">
				</cfif>
			</cfloop>

			<cfquery name="changeLink" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="changeLink_result">
				UPDATE geology_attribute_hierarchy 
				SET parent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#parent#">
				WHERE 
					geology_attribute_hierarchy_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#child#">
			</cfquery>
			<cfif changeLink_result.recordcount eq 1>
				<cfquery name="getNames" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getNames_result">
					SELECT p.attribute patt, p.attribute_value pattval, c.attribute catt, c.attribute_value cattval
					FROM
						geology_attribute_hierarchy c
						left join geology_attribute_hierarchy p on c.parent_id = p.geology_attribute_hierarchy_id
					WHERE 
						c.geology_attribute_hierarchy_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#child#">
				</cfquery>
				<cfset t = queryaddrow(theResult,1)>
				<cfset t = QuerySetCell(theResult, "status", "1", 1)>
				<cfset t = QuerySetCell(theResult, "message", "Updated parent:child relationship #getNames.pattval#(#getNames.patt#):#getNames.cattval#(#getNames.catt#).", 1)>
			<cfelse>
				<cfthrow message="Error updating a parent:child relationship.">
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


<!--- Obtain html for adding a geological attribute, includes javascript that will invoke a javascript 
  * function named reload() which must exist on the page.
  * @return a block of html with an add form and supporting javascript.
--->
<cffunction name="getAddGeologyAttributeHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="type" type="string" required="no">

	<cfthread name="geoAddThread">
		<cfquery name="ctgeology_attribute"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			SELECT geology_attribute, type, description 
			FROM ctgeology_attribute
			<cfif isdefined("type") AND len(type) GT 0 AND type NEQ 'all'>
				WHERE 
					ctgeology_attribute.type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#type#">
			</cfif>
			ORDER BY ordinal
		</cfquery>
		<cfoutput>
			<section class="col-12 border-bottom border-right border-left rounded border-top" title="Add Geological Atribute">
				<h2 class="h3">Add New Geological Attribute Value:</h2>
				<form name="insertGeolAttrForm" id="insertGeolAttrForm" onsubmit="return noenter(event);" >
					<div class="form-row mb-2">
						<div class="col-12 col-sm-12 col-xl-4">
							<label for="attribute" class="data-entry-label">Attribute ("Formation")</label>
							<select name="attribute" id="attribute" class="data-entry-select reqdClr">
								<cfloop query="ctgeology_attribute">
									<option value="#ctgeology_attribute.geology_attribute#" >#ctgeology_attribute.geology_attribute# (#ctgeology_attribute.type#)</option>
								</cfloop>
							</select>
						</div>
						<div class="col-12 col-sm-12 col-xl-4">
							<label for="attribute_value" class="data-entry-label">Value ("Prince Creek")</label>
							<input type="text" name="attribute_value" id="attribute_value" class="data-entry-input reqdClr" required>
						</div>
						<div class="col-12 col-sm-12 col-xl-4">
							<label for="usable_value_fg" class="data-entry-label">Attribute valid for Data Entry?</label>
							<select name="usable_value_fg" id="usable_value_fg" class="data-entry-select reqdClr">
								<option value="0">no</option>
								<option value="1">yes</option>
							</select>
						</div>
						<div class="col-12 my-2">
							<label for="description" class="data-entry-label">Description</label>
							<input type="text" name="description" id="description" class="data-entry-input">
						</div>
						<div class="col-12 mb-2">
							<input type="submit" value="Insert Term" class="btn btn-xs btn-primary">
							<div id="addFeedbackDiv"></div>
						</div>
					</div>
				</form>
				<script>
					function saveNew(){ 
						addGeologicalAttribute($("##attribute").val(), $("##attribute_value").val(), $("##usable_value_fg").val(), $("##description").val(), "addFeedbackDiv", reload);
					}
					$(document).ready(function(){
						$("##insertGeolAttrForm").submit(function(event) {
							event.preventDefault();
							if (checkFormValidity($('##insertGeolAttrForm')[0])) { 
								saveNew();  
							}
						});
					});
				</script>
			</section>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="geoAddThread" />
	<cfreturn geoAddThread.output>
</cffunction>


<!--- Obtain html for a geological tree navigation control. --->
<cffunction name="getGeologyNavigationHtml" returntype="string" access="remote" returnformat="plain">
	<cfthread name="geoNavThread">
		<cfquery name="types"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="types_result">
			SELECT distinct type 
			FROM ctgeology_attribute
		</cfquery>
		<cfoutput>

				<ul class="nav nav-tabs" role="tablist" id="geol-tabs">
					<cfloop query="types">
						<li class="nav-item border mr-2 rounded" role="presentation">
							<a class="nav-link px-2 py-1 d-block text-capitalize btn-xs btn-secondary" role="button" href="/vocabularies/GeologicalHierarchies.cfm?action=list&type=#types.type#">#types.type# Terms</a>
						</li>
					</cfloop>
				
					<li class="nav-item mr-2 border rounded" role="presentation">
						<a class="nav-link px-2 py-1 d-block btn-xs btn-secondary" role="button" href="/vocabularies/GeologicalHierarchies.cfm?action=list">List/Edit All Terms</a>
					</li>
					<li class="nav-item border mr-2 rounded" role="presentation">
						<a class="nav-link btn-xs btn-secondary px-2 py-1 d-block" role="button" href="/vocabularies/GeologicalHierarchies.cfm?action=addNew">Add New Term</a>
					</li>
					<li class="nav-item border mr-2 rounded" role="presentation">
						<a class="nav-link btn-xs btn-secondary px-2 py-1 d-block" role="button" href="/vocabularies/GeologicalHierarchies.cfm?action=organize">Organize Hierarchically</a>
					</li>
					<li class="nav-item border mr-2 rounded" role="presentation">
						<a class="nav-link btn-xs px-2 py-1 btn-secondary d-block" role="button" href="/CodeTableEditor.cfm?action=edit&tbl=CTGEOLOGY_ATTRIBUTES">Manage types and categories</a>
					</li>
				</ul>
		
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="geoNavThread" />
	<cfreturn geoNavThread.output>
</cffunction>

<!--- ** Obtain html for controls to link geological tree nodes in parent-child relationships. 
 * assumes the existence of a javascript reload() function which is invoked on save of a new relationship.
 * @param type if present, restricts which types of nodes are listed as available to merge.
 * @return html with a form for adding relationships between pairs of nodes.
--->
<cffunction name="getGeologyMakeTreeHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="type" type="string" required="no">

	<cfthread name="geoOrganizeThread">
		<cfif NOT isDefined("type") OR len(type) EQ 0>
			<cfset type = "all">
		</cfif>
		<cfquery name="terms"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select geology_attribute_hierarchy_id,
				attribute_value,
				attribute,
				decode(usable_value_fg,1,'*','') uflag
			FROM geology_attribute_hierarchy
				LEFT JOIN ctgeology_attribute on attribute = geology_attribute
			<cfif NOT type IS "all">
				WHERE
					ctgeology_attribute.type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#type#">
			</cfif>  
			ORDER BY ordinal, attribute, attribute_value
		</cfquery>
		<cfoutput>
			<section class="col-12 border-top border-right border-left border-bottom rounded" title="Relate Geological Attributes">
				<h2 class="h3">Link terms into Hierarchies</h2>
				<form name="rel" id="newRelationshipForm" onsubmit="return noenter(event);">
					<div class="form-row mb-2">
						<div class="col-12 col-md-6 col-xl-6">
							<label for="parent" class="data-entry-label">Parent Term</label>
							<select name="parent" class="data-entry-select reqdClr" id="parent" required>
								<option value=""></option>
								<option value="NULL">Unlink from Parent</option>
								<cfloop query="terms">
									<option value="#geology_attribute_hierarchy_id#">#attribute_value# (#attribute#) #uflag#</option>
								</cfloop>
							</select>
						</div>
						<div class="col-12 col-md-6 col-xl-6">
							<label for="child" class="data-entry-label">Child Term</label>
							<select name="child" id="child" class="data-entry-select reqdClr" required>
								<option value=""></option>
								<cfloop query="terms">
									<option value="#geology_attribute_hierarchy_id#">#attribute_value# (#attribute#) #uflag#</option>
								</cfloop>
							</select>
						</div>
						<div class="col-12 mt-2 pb-2">
							<input type="submit" id="addRelationshipButton" value="Create Relationship" class="btn btn-xs btn-primary">
							<div id="addRelationshipFeedback"></div>
						</div>
					</div>
				</form>
				<script>
					function addRelationship() { 
						var newParent = $('select[name=parent] option').filter(':selected').val();
						var newChild = $('select[name=child] option').filter(':selected').val();
						if (newChild && newParent) { 
							changeGeologicalAttributeLink(newParent,newChild, "addRelationshipFeedback", reload);
						} else { 
							messageDialog("Error: No value selected.");
						}
					};
					$(document).ready(function(){
						$("##newRelationshipForm").on('submit',function(event){
							event.preventDefault();
							if (checkFormValidity($('##newRelationshipForm')[0])) { 
						 		addRelationship();
							};
						});
					});
				</script>
			</section>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="geoOrganizeThread" />
	<cfreturn geoOrganizeThread.output>
</cffunction>

<!--- Obtain html for a geological tree navigation control. --->
<cffunction name="getGeologyAttributeTreeHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="type" type="string" required="no">

	<cfthread name="geoTreeThread">
		<cfif NOT isDefined("type") OR len(type) EQ 0>
			<cfset type = "all">
		</cfif>
		<cfquery name="cData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			SELECT  
				level,
				geology_attribute_hierarchy_id,
				parent_id,
				usable_value_fg,
				attribute_value,
				attribute,
				geology_attribute_hierarchy.description
			FROM
				geology_attribute_hierarchy
				LEFT JOIN ctgeology_attribute on attribute = geology_attribute
			<cfif NOT type IS "all">
			WHERE
				ctgeology_attribute.type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#type#">
			</cfif>  
			START WITH parent_id is null
			CONNECT BY PRIOR geology_attribute_hierarchy_id = parent_id
			ORDER SIBLINGS BY ordinal, attribute_value
		</cfquery>
		<cfoutput>
			<cfset typetext = "">
			<cfif type NEQ "all">
				<cfset typetext = ": #encodeForHtml(type)#">
			</cfif>
			<h2 class="h3">Geological Attributes#typetext#</h2> 
			<div>Values in red are not available for data entry but may be used in searches</div>
			<cfset levelList = "">
			<cfloop query="cData">
				<cfquery name="locCount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT count(locality_id) ct
					FROM geology_attributes
					WHERE
						geology_attribute = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#cData.attribute#"> and
						geo_att_value = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#cData.attribute_value#">
				</cfquery>
				<cfset localityCount = locCount.ct>
				<cfif listLast(levelList,",") IS NOT level>
					<cfset levelListIndex = listFind(levelList,cData.level,",")>
					<cfif levelListIndex IS NOT 0>
						<cfset numberOfLevelsToRemove = listLen(levelList,",") - levelListIndex>
						<cfloop from="1" to="#numberOfLevelsToRemove#" index="i">
							<cfset levelList = listDeleteAt(levelList,listLen(levelList,","))>
						</cfloop>
						#repeatString("</ul>",numberOfLevelsToRemove)#
					<cfelse>
						<cfset levelList = listAppend(levelList,cData.level)>
						<ul>
					</cfif>
				</cfif>
				<cfset class="">
				<cfif usable_value_fg is 0><cfset class="text-danger"></cfif>
				<li>
					<span class="font-weight-bold #class#">
						#attribute_value# (#attribute#)
						<cfif usable_value_fg IS 1>*</cfif>
					</span>
					<a class="text-primary" href="/vocabularies/GeologicalHierarchies.cfm?action=edit&geology_attribute_hierarchy_id=#geology_attribute_hierarchy_id#">edit</a>
					Used in #localityCount# Localities
					<span class="font-italic">#description#</span>
				</li>
				<cfif cData.currentRow IS cData.recordCount>
					#repeatString("</ul>",listLen(levelList,","))#
				</cfif>
			</cfloop>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="geoTreeThread" />
	<cfreturn geoTreeThread.output>
</cffunction>

<!--- ** getNodeInGeologyTreeHtml obtain an html representation of the location of a node within its tree, including 
  * the path from the node to root, the specified node highlighted, and all nodes that are children of the specified
  * node. 
  * @param geology_attribute_hierarchy_id the surrogate numeric primary key value of the node to return tree placement
  *   information about
  * @returns html representation of the tree as nested unordered lists.
--->
<cffunction name="getNodeInGeologyTreeHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="geology_attribute_hierarchy_id" type="string" required="yes">

	<cfthread name="listNodeInGeoTreeThread">
		<cfoutput>
			<!--- lookup path from root to specified node, leaving out the specified node --->
			<cfquery name="parents" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="parents_result">
				SELECT * FROM (
					SELECT 
						level as parentagelevel,
						connect_by_root attribute as attribute,
						connect_by_root attribute_value as attribute_value,
						connect_by_root geology_attribute_hierarchy_id as geology_attribute_hierarchy_id,
						connect_by_root PARENT_ID as parent_id,
						connect_by_root USABLE_VALUE_FG as USABLE_VALUE_FG,
						connect_by_root DESCRIPTION as description
					FROM geology_attribute_hierarchy 
					WHERE
						geology_attribute_hierarchy_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geology_attribute_hierarchy_id#">
					CONNECT BY PRIOR geology_attribute_hierarchy_id = parent_id
					ORDER BY level desc
				) WHERE parentagelevel > 1
			</cfquery>
			<cfset parentnesting = 0>
			<cfloop query="parents">
				<!--- parentage down to, but not including the current node, we'll get that from the children query --->
				<ul>
					<cfset parentnesting = parentnesting + 1>
					<li>
						<cfset nodeclass = "">
						<cfset marker = "*">
						<cfif parents.usable_value_fg is 0>
							<cfset nodeclass="text-danger">
							<cfset marker="">
						</cfif>
						<span class="#nodeclass#">#parents.attribute_value# (#parents.attribute#)#marker#</span>
						<a class="infoLink" href="/vocabularies/GeologicalHierarchies.cfm?action=edit&geology_attribute_hierarchy_id=#parents.geology_attribute_hierarchy_id#">edit</a>
					</li>
			</cfloop>
			<!--- look up the tree from the current node down to all included leaves, including the current node --->
			<cfquery name="children" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="children_result">
				SELECT
					level,
					geology_attribute_hierarchy_id,
					parent_id,
					usable_value_fg,
					attribute_value,
					attribute
				FROM
					geology_attribute_hierarchy
					LEFT JOIN ctgeology_attributes on attribute = geology_attribute
				START WITH geology_attribute_hierarchy.geology_attribute_hierarchy_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geology_attribute_hierarchy_id#">
				CONNECT BY PRIOR geology_attribute_hierarchy_id = parent_id
				ORDER SIBLINGS BY ordinal, attribute_value
			</cfquery>
			<cfif children.recordcount EQ 1>
				<ul>
					<cfset parentnesting = parentnesting + 1>
					<cfset nodeclass = "">
					<cfset marker = "*">
					<cfif children.usable_value_fg is 0>
						<cfset nodeclass="text-danger">
						<cfset marker="">
					</cfif>
					<li><h3 class="h4 #nodeclass#">#children.attribute_value# (#children.attribute#)#marker#</h3></li>
			<cfelse>
				<cfset levelList = "">
				<cfset firstNode = true>
				<cfloop query="children">
					<cfif firstNode>
						<ul>
							<cfset nodeclass = "">
							<cfset marker = "*">
							<cfif children.usable_value_fg is 0>
								<cfset nodeclass="text-danger">
								<cfset marker="">
							</cfif>
							<li><h3 class="h4 #nodeclass#">#children.attribute_value# (#children.attribute#)#marker#</h3></li>
							<cfset firstNode = false>
					<cfelse>
						<cfif listLast(levelList,",") IS NOT children.level>
							<cfset levelListIndex = listFind(levelList,children.level,",")>
							<cfif levelListIndex IS NOT 0>
								<cfset numberOfLevelsToRemove = listLen(levelList,",") - levelListIndex>
								<cfloop from="1" to="#numberOfLevelsToRemove#" index="i">
									<cfset levelList = listDeleteAt(levelList,listLen(levelList,","))>
								</cfloop>
								#repeatString("</ul>",numberOfLevelsToRemove)#
							<cfelse>
								<cfset levelList = listAppend(levelList,children.level)>
								<ul>
							</cfif>
						</cfif>
						<li>
							<cfset nodeclass = "">
							<cfset marker = "*">
							<cfif children.usable_value_fg is 0>
								<cfset nodeclass="text-danger">
								<cfset marker="">
							</cfif>
							<span class="#nodeclass#">#children.attribute_value# (#children.attribute#)</span>#marker#
							<a class="infoLink" href="/vocabularies/GeologicalHierarchies.cfm?action=edit&geology_attribute_hierarchy_id=#children.geology_attribute_hierarchy_id#">edit</a>
						</li>
						<cfif children.currentRow IS children.recordCount>
							#repeatString("</ul>",listLen(levelList,","))#
						</cfif>
					</cfif>
				</cfloop>
			</cfif>
			</ul><!--- for first node of children = current node --->
			<cfloop from="1" to="#parentnesting#" index="i">
				<!--- for parentage of current node to root --->
				</ul>
			</cfloop>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="listNodeInGeoTreeThread" />
	<cfreturn listNodeInGeoTreeThread.output>
</cffunction>

<!--- ** getNodeToRootGeologyTreeHtml obtain an html representation of the path of node within its tree to root, 
  * excluding the node iteslf and excluding children of the specified node.
  *
  * @param geology_attribute_hierarchy_id the surrogate numeric primary key value of the node to return tree placement
  *   information about
  * @returns html representation of the tree as nested unordered lists.
--->
<cffunction name="getNodeToRootGeologyTreeHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="geology_attribute_hierarchy_id" type="string" required="yes">

	<cfthread name="listNodePathInGeoTreeThread">
		<cfoutput>
			<!--- lookup path from root to specified node, leaving out the specified node --->
			<cfquery name="parents" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="parents_result">
				SELECT * FROM (
					SELECT 
						level as parentagelevel,
						connect_by_root attribute as attribute,
						connect_by_root attribute_value as attribute_value,
						connect_by_root geology_attribute_hierarchy_id as geology_attribute_hierarchy_id,
						connect_by_root PARENT_ID as parent_id,
						connect_by_root USABLE_VALUE_FG as USABLE_VALUE_FG,
						connect_by_root DESCRIPTION as description
					FROM geology_attribute_hierarchy 
					WHERE
						geology_attribute_hierarchy_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geology_attribute_hierarchy_id#">
					CONNECT BY PRIOR geology_attribute_hierarchy_id = parent_id
					ORDER BY level desc
				) WHERE parentagelevel > 1
			</cfquery>
			<cfif parents.recordcount EQ 0>
				<ul><li>[None]</li></ul>
			<cfelse> 
				<cfset parentnesting = 0>
				<cfloop query="parents">
					<!--- parentage down to, but not including the current node, we'll get that from the children query --->
					<ul>
						<cfset parentnesting = parentnesting + 1>
						<li>
							<cfset nodeclass = "">
							<cfset marker = "*">
							<cfif parents.usable_value_fg is 0>
								<cfset nodeclass="text-danger">
								<cfset marker="">
							</cfif>
							<span class="#nodeclass#">#parents.attribute_value# (#parents.attribute#)#marker#</span>
						</li>
				</cfloop>
				<cfloop from="1" to="#parentnesting#" index="i">
					<!--- close tags for parentage of current node to root --->
					</ul>
				</cfloop>
			</cfif>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="listNodePathInGeoTreeThread" />
	<cfreturn listNodePathInGeoTreeThread.output>
</cffunction>
</cfcomponent>
