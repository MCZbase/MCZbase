<!---
vocabularies/component/search.cfc

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
<cfinclude template="/shared/component/error_handler.cfc" runOnce="true">

<!---   Function getCollEventNumberSeries  --->
<cffunction name="getCollEventNumberSeries" access="remote" returntype="any" returnformat="json">
	<cfargument name="number_series" type="string" required="no">
	<cfargument name="collector_agent_id" type="string" required="no">
	<cfargument name="number" type="string" required="no">
	<cfargument name="pattern" type="string" required="no">
	<cfargument name="remarks" type="string" required="no">

	<cfset data = ArrayNew(1)>
	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			select count(coll_event_number_id) as number_count, number_series, coll_event_num_series.coll_event_num_series_id as id, pattern, remarks,
				collector_agent_id,
				case 
					when collector_agent_id is null then '[No Agent]'
					else MCZBASE.get_agentnameoftype(collector_agent_id, 'preferred')
					end
				as agentname
			from coll_event_num_series
					left join coll_event_number on coll_event_number.coll_event_num_series_id = coll_event_num_series.coll_event_num_series_id
			WHERE
				coll_event_num_series.coll_event_num_series_id is not null
				<cfif isDefined("number_series") and len(number_series) gt 0>
					and number_series like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#number_series#%">
				</cfif>
				<cfif isDefined("number") and len(number) gt 0>
					and coll_event_number like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#number#">
				</cfif>
				<cfif isDefined("pattern") and len(pattern) gt 0>
					and pattern like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#pattern#">
				</cfif>
				<cfif isDefined("remarks") and len(remarks) gt 0>
					and remarks like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#remarks#">
				</cfif>
			group by 
				number_series, coll_event_num_series.coll_event_num_series_id, pattern, remarks,
				collector_agent_id,
				case 
					when collector_agent_id is null then '[No Agent]'
					else MCZBASE.get_agentnameoftype(collector_agent_id, 'preferred')
					end
		</cfquery>
		<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfset row["coll_event_num_series_id"] = "#search.id#">
			<cfset row["number_series"] = "#search.number_series#">
			<cfset row["pattern"] = "#search.pattern#">
			<cfset row["remarks"] = "#search.remarks#">
			<cfset row["agentname"] = "#search.agentname#">
			<cfset row["collector_agent_id"] = "#search.collector_agent_id#">
			<cfset row["number_count"] = "#search.number_count#">
			<cfset row["id_link"] = "<a href='/vocabularies/CollEventNumberSeries.cfm?action=edit&coll_event_num_series_id=#search.id#' target='_blank'>#search.number_series#</a>">
			<cfset data[i]  = row>
			<cfset i = i + 1>
		</cfloop>
		<cfreturn #serializeJSON(data)#>
	<cfcatch>
      <cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
      <cfset message = trim("Error processing getTransactions: " & cfcatch.message & " " & cfcatch.detail & " " & queryError)  >
      <cfheader statusCode="500" statusText="#message#">
	   <cfabort>
	</cfcatch>
	</cftry>
	<cfreturn #serializeJSON(data)#>
</cffunction>

<!---
Function getJournalAutocomplete.  Search for journals by name with a substring match on any name, 
   returning json suitable for jquery-ui autocomplete.

@param term journal name to search for.
@return a json structure containing id and value, with matching journals with matched name in both value and id.
--->
<cffunction name="getJournalAutocomplete" access="remote" returntype="any" returnformat="json">
	<cfargument name="term" type="string" required="yes">
	<!--- perform wildcard search anywhere in journal_name.journal_name --->
	<cfset name = "%#term#%"> 

	<cfset data = ArrayNew(1)>
	<cftry>
      <cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			SELECT 
				journal_name as id, journal_name as value
			FROM 
				ctjournal_name
			WHERE
				upper(journal_name) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(name)#">
		</cfquery>
		<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfset row["id"] = "#search.id#">
			<cfset row["value"] = "#search.value#" >
			<cfset data[i]  = row>
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
	<cfreturn #serializeJSON(data)#>
</cffunction>

<!---
Function getCTAutocomplete.  Search for values in code tables, returning json suitable for jquery-ui autocomplete.

@param term to search for.
@param codetable the name of the codetable to search for, without the leading CT.
@return a json structure containing id and value, with matching with matched value in both value and id.
--->
<cffunction name="getCTAutocomplete" access="remote" returntype="any" returnformat="json">
	<cfargument name="term" type="string" required="yes">
	<cfargument name="codetable" type="string" required="yes">

	<!--- perform wildcard search anywhere in target field --->
	<cfset name = "%#term#%"> 

	<cfset data = ArrayNew(1)>
	<cftry>
		<cfquery name="getCTField" datasource="uam_god">
			SELECT
				table_name, column_name
			FROM
				sys.all_tab_columns
			WHERE
				table_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="CT#ucase(codetable)#"> and
				column_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(codetable)#"> and
				data_type = 'VARCHAR2' and
				owner = 'MCZBASE'
		</cfquery>
		<cfif getCTField.recordcount NEQ 1>
			<cfif len(codetable) EQ 0>
				<cfthrow message="Error, cf_spec_search_cols.ui_function is incorrectly configured, no value for codetable passed to lookup CT{codetable}.{codetable}.  Configuration should be in the form makeCTFieldSearchAutocomplete(searchText:,COLLECTING_SOURCE)">
			<cfelse>
				<cfthrow message="Error, unsupported code table for this autocomplete, CT{codetable} must have PK field {codetable}. [#getCTField.recordcount#]">
			</cfif>
		</cfif>
		<cfloop query="getCTField">
   	   <cfset rows = 0>
			<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
				SELECT 
					#getCTField.column_name# value
				FROM 
					#getCTField.table_name#
				WHERE
					upper(#getCTField.column_name#) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(name)#">
			</cfquery>
			<cfset rows = search_result.recordcount>
			<cfset i = 1>
			<cfloop query="search">
				<cfset row = StructNew()>
				<cfset row["id"] = "#search.value#">
				<cfset row["value"] = "#search.value#" >
				<cfset data[i]  = row>
				<cfset i = i + 1>
			</cfloop>
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
	<cfreturn #serializeJSON(data)#>
</cffunction>


<!---
Function getBiolIndivRelationshipAutocompleteMeta.  Search for ctbiol_relations.biol_indiv_relationship values, 
 returning json suitable for jquery-ui autocomplete with a _renderItem overriden to display more detail on the 
  picklist, and minimal details for the selected value.

@param term information to search for.
@return a json structure containing id and value, with biol_indiv_relationship in id and value, with relationship,
  relationship type, and counts in meta.
--->
<cffunction name="getBiolIndivRelationshipAutocompleteMeta" access="remote" returntype="any" returnformat="json">
	<cfargument name="term" type="string" required="yes">
	<cfset data = ArrayNew(1)>
	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			SELECT 
				count(distinct f.collection_object_id) ct,
				ctbiol_relations.biol_indiv_relationship,
				ctbiol_relations.rel_type
			FROM
				#session.flatTableName# f
				left join biol_indiv_relations on f.collection_object_id = biol_indiv_relations.collection_object_id
				left join ctbiol_relations on biol_indiv_relations.biol_indiv_relationship = ctbiol_relations.biol_indiv_relationship
			WHERE
				f.collection_object_id IS NOT NULL
				AND ctbiol_relations.biol_indiv_relationship like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#term#%">
			GROUP BY
				ctbiol_relations.biol_indiv_relationship, ctbiol_relations.rel_type
			ORDER BY
				ctbiol_relations.biol_indiv_relationship, ctbiol_relations.rel_type
		</cfquery>
		<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfset row["id"] = "#search.biol_indiv_relationship#">
			<cfset row["value"] = "#search.biol_indiv_relationship#" >
			<cfset row["meta"] = "#search.biol_indiv_relationship#: #search.rel_type# (#search.ct#)" >
			<cfset data[i]  = row>
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
	<cfreturn #serializeJSON(data)#>
</cffunction>

</cfcomponent>
