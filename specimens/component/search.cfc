<!---
specimens/component/search.cfc

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
<cf_rolecheck>
<cfinclude template="/shared/component/error_handler.cfc" runOnce="true">

<!---   Function getSpecimens backing method for specimen search --->
<cffunction name="getSpecimens" access="remote" returntype="any" returnformat="json">
	<cfargument name="searchText" type="string" required="no">
	<cfargument name="collmultiselect" type="string" required="no">

	<cftry>
		<!---change this to create a table of collection_object_ids, then a query to get preferred columns for user using the coll object table--->

		<!---conditional to handle different search methods keyword/querybuilder&fixed--->
		<cfif isDefined("searchText") and len(searchText) gt 0>
			<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
				SELECT
					f.guid,
					f.imageurl, f.collection_object_id,f.collection,f.cat_num,f.began_date, f.ended_date,
					f.scientific_name,f.spec_locality,f.locality_id, f.higher_geog, f.collectors, f.verbatim_date,f.coll_obj_disposition,f.othercatalognumbers
				FROM <cfif ucase(session.flatTableName) EQ "FLAT"> flat <cfelse> filtered_flat </cfif> F
					left join FLAT_TEXT FT ON f.COLLECTION_OBJECT_ID = FT.COLLECTION_OBJECT_ID
				WHERE contains(ft.cat_num, <cfqueryparam value="#searchText#" CFSQLType="CF_SQL_VARCHAR">, 1) > 0
					<cfif isDefined("collmultiselect") and len(collmultiselect) gt 0>
						and f.collection_id in (<cfqueryparam value="#collmultiselect#" cfsqltype="cf_sql_integer" list="true">)
					</cfif>
			</cfquery>
		<!---cfelse querybuilder handler goes here--->
		</cfif>
		<!---query for returning selected columns here--->

		<cfset rows = 0>
		<cfset data = ArrayNew(1)>

		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfloop list="#ArrayToList(search.getColumnNames())#" index="col" >
				<cfset row["#ucase(col)#"] = "#search[col][currentRow]#">
			</cfloop>
			<cfset data[i]  = row>
			<cfset i = i + 1>
		</cfloop>
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

<!---   Function executeFixedSearch backing method for specimen search
	@param result_id a uuid which identifies this search.
--->
<cffunction name="executeFixedSearch" access="remote" returntype="any" returnformat="json">
	<cfargument name="result_id" type="string" required="yes">
	<cfargument name="genus" type="string" required="no">
	<cfargument name="family" type="string" required="no">
	<cfargument name="collector" type="string" required="no">
	<cfargument name="collector_agent_id" type="string" required="no">
	<cfargument name="debug" type="string" required="no">

	<cfset result_id = CreateUUID()>
	<cfset search_json = "[">
	<cfset separator = "">
	<cfset join = ''>

	<cfif isDefined("genus") AND len(genus) GT 0>
		<cfset field = 'field: "genus"'>
		<cfif left(genus,1) is "=">
			<cfset value="#ucase(right(genus,len(genus)-1))#">
			<cfset comparator = 'comparator: "equals"'>
		<cfelseif left(genus,1) IS "!">
			<cfset value="#ucase(right(genus,len(genus)-1))#">
			<cfset comparator = 'comparator: "not like"'>
		<cfelse>
			<cfset comparator = 'comparator: "like"'>
			<cfset value = encodeForJavaScript(genus)>
		</cfif>
		<cfset search_json = '#search_json##separator#{#join##field#,#comparator#,value: "#value#"}'>
		<cfset separator = ",">
		<cfset join='join="and",'>
	</cfif>
	<cfif isDefined("family") AND len(family) GT 0>
		<cfset field = 'field: "family"'>
		<cfif left(family,1) is "=">
			<cfset value="#ucase(right(family,len(family)-1))#">
			<cfset comparator = 'comparator: "equals"'>
		<cfelseif left(family,1) IS "!">
			<cfset value="#ucase(right(family,len(family)-1))#">
			<cfset comparator = 'comparator: "not like"'>
		<cfelse>
			<cfset comparator = 'comparator: "like"'>
			<cfset value = encodeForJavaScript(family)>
		</cfif>
		<cfset search_json = '#search_json##separator#{#join##field#,#comparator#,value: "#value#"}'>
		<cfset separator = ",">
		<cfset join='join="and",'>
	</cfif>
	<cfif isDefined("collector_agent_id") AND len(collector_agent_id) GT 0>
		<cfset field = 'field: "collector_agent_id"'>
		<cfset comparator = 'comparator: "equals"'>
		<cfset value = encodeForJavaScript(collector_agent_id)>
		<cfset search_json = '#search_json##separator#{#join##field#,#comparator#,value: "#value#"}'>
		<cfset separator = ",">
		<cfset join='join="and",'>
	<cfelse>
		<cfif isDefined("collector") AND len(collector) GT 0>
			<cfset field = 'field: "collector"'>
			<cfif left(collector,1) is "=">
				<cfset value="#ucase(right(collector,len(collector)-1))#">
				<cfset comparator = 'comparator: "equals"'>
			<cfelseif left(collector,1) IS "!">
				<cfset value="#ucase(right(collector,len(collector)-1))#">
				<cfset comparator = 'comparator: "not like"'>
			<cfelse>
				<cfset comparator = 'comparator: "like"'>
				<cfset value = encodeForJavaScript(collector)>
			</cfif>
			<cfset search_json = '#search_json##separator#{#join##field#,#comparator#,value: "#value#"}'>
			<cfset separator = ",">
			<cfset join='join="and",'>
		</cfif>
	</cfif>

	<cfset search_json = "#search_json#]">
	<cfif isdefined("debug") AND len(debug) GT 0>
		<cfdump var="#search_json#">
		<cfdump var="#session.dbuser#">
		<cfabort>
	</cfif>

	<cftry>
		<cfset username = session.dbuser>
		<!--- TODO: Impllement returnCode from build_query, 0=success, non zero error condition. --->
		<!--- cfstoredproc procedure="build_query" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="prepareSearch_result" returnCode="yes" --->
		<cfstoredproc procedure="build_query" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="prepareSearch_result">
			<cfprocparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
			<cfprocparam cfsqltype="CF_SQL_VARCHAR" value="#session.dbuser#">
			<cfprocparam cfsqltype="CF_SQL_CLOB" value="#search_json#">
			<cfprocresult name="search">
		</cfstoredproc>
		<!--- TODO implement return code in build_query and check return code for error value here. --->
		<!---
		<cfdump var="#prepareSearch_result#">
		<cfabort>
		<cfif prepareSearch_result NEQ 0>
			<cfthrow message = "failed to run search, build_query returned a non zero status code">
		</cfif>
		--->
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			SELECT *
			FROM <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat
				left join user_search_table on user_search_table.collection_object_id = flat.collection_object_id
			WHERE
				user_search_table.result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
		</cfquery>

		<cfset rows = 0>
		<cfset data = ArrayNew(1)>

		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfloop list="#ArrayToList(search.getColumnNames())#" index="col" >
				<cfset row["#ucase(col)#"] = "#search[col][currentRow]#">
			</cfloop>
			<cfset data[i]  = row>
			<cfset i = i + 1>
		</cfloop>
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
Function getCatalogedItemAutocompleteMeta.  Search for specimens with a substring match on guid, returning json suitable for jquery-ui autocomplete
 with a _renderItem overriden to display more detail on the picklist, and just the guid as the selected value.

@param term information to search for.
@return a json structure containing id and value, with guid in value and collection_object_id in id, and guid with more data in meta.
--->
<cffunction name="getCatalogedItemAutocompleteMeta" access="remote" returntype="any" returnformat="json">
	<cfargument name="term" type="string" required="yes">
	<cfset data = ArrayNew(1)>
	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			SELECT distinct
				f.collection_object_id, f.guid,
				f.scientific_name, f.spec_locality
			FROM
				#session.flatTableName# f
			WHERE
				f.guid like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#term#%">
				OR
				f.scientific_name like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#term#%">
				OR
				f.spec_locality like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#term#%">
		</cfquery>
		<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfset row["id"] = "#search.collection_object_id#">
			<cfset row["value"] = "#search.guid#" >
			<cfset row["meta"] = "#search.guid# (#search.scientific_name# #search.spec_locality#)" >
			<cfset data[i]  = row>
			<cfset i = i + 1>
		</cfloop>
		<cfreturn #serializeJSON(data)#>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset message = trim("Error processing #GetFunctionCalledName()#: " & cfcatch.message & " " & cfcatch.detail & " " & queryError)  >
		<cfheader statusCode="500" statusText="#message#">
			<cfoutput>
				<div class="container">
					<div class="row">
						<div class="alert alert-danger" role="alert">
							<img src="/shared/images/Process-stop.png" alt="[ unauthorized access ]" style="float:left; width: 50px;margin-right: 1em;">
							<h2>Internal Server Error.</h2>
							<p>#message#</p>
							<p><a href="/info/bugs.cfm">â€œFeedback/Report Errorsâ€�</a></p>
						</div>
					</div>
				</div>
			</cfoutput>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn #serializeJSON(data)#>
</cffunction>

<!---
Function getLocalityAutocompleteMeta.  Search for localities with a substring match on specific locality, returning json suitable for jquery-ui autocomplete
 with a _renderItem overriden to display more detail on the picklist, and just spec_locality and locality id as the selected value.

@param term information to search for.
@return a json structure containing id and value, with spec_locality and locality_id in value and locality_id in id, and more data in meta.
--->
<cffunction name="getLocalityAutocompleteMeta" access="remote" returntype="any" returnformat="json">
	<cfargument name="term" type="string" required="yes">
	<cfset data = ArrayNew(1)>
	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			SELECT distinct
				f.locality_id,
				f.spec_locality,
				f.higher_geog
			FROM
				#session.flatTableName# f
			WHERE
				f.spec_locality like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#term#%">
		</cfquery>
		<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfset row["id"] = "#search.locality_id#">
			<cfset row["value"] = "#search.spec_locality# (#search.locality_id#)" >
			<cfset row["meta"] = "#search.spec_locality# #search.higher_geog# (#search.locality_id#)" >
			<cfset data[i]  = row>
			<cfset i = i + 1>
		</cfloop>
		<cfreturn #serializeJSON(data)#>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset message = trim("Error processing #GetFunctionCalledName()#: " & cfcatch.message & " " & cfcatch.detail & " " & queryError)  >
		<cfheader statusCode="500" statusText="#message#">
			<cfoutput>
				<div class="container">
					<div class="row">
						<div class="alert alert-danger" role="alert">
							<img src="/shared/images/Process-stop.png" alt="[ unauthorized access ]" style="float:left; width: 50px;margin-right: 1em;">
							<h2>Internal Server Error.</h2>
							<p>#message#</p>
							<p><a href="/info/bugs.cfm">â€œFeedback/Report Errorsâ€�</a></p>
						</div>
					</div>
				</div>
			</cfoutput>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn #serializeJSON(data)#>
</cffunction>

<!---
Function getCollectingEventAutocompleteMeta.  Search for collecting events, returning json suitable for jquery-ui autocomplete
 with a _renderItem overriden to display more detail on the picklist, and minimal details for the selected value.

@param term information to search for.
@return a json structure containing id and value, with guid in value and collection_object_id in id, and guid with more data in meta.
--->
<cffunction name="getCollectingEventAutocompleteMeta" access="remote" returntype="any" returnformat="json">
	<cfargument name="term" type="string" required="yes">
	<cfset data = ArrayNew(1)>
	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			SELECT distinct
				f.collecting_event_id,
				f.began_date, f.ended_date,
				f.collecting_source, f.collecting_method,
				f.verbatimlocality,
				f.spec_locality
			FROM
				#session.flatTableName# f
			WHERE
				f.spec_locality like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#term#%">
				OR
				f.collecting_source like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#term#%">
				OR
				f.collecting_method like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#term#%">
				OR
				f.began_date like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#term#%">
		</cfquery>
		<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfset row["id"] = "#search.collecting_event_id#">
			<cfset row["value"] = "#search.spec_locality# #search.began_date#/#search.ended_date# (#search.collecting_event_id#)" >
			<cfset row["meta"] = "#search.spec_locality# #search.began_date#/#search.ended_date# #search.collecting_source# #search.collecting_method# (#search.collecting_event_id#)" >
			<cfset data[i]  = row>
			<cfset i = i + 1>
		</cfloop>
		<cfreturn #serializeJSON(data)#>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset message = trim("Error processing #GetFunctionCalledName()#: " & cfcatch.message & " " & cfcatch.detail & " " & queryError)  >
		<cfheader statusCode="500" statusText="#message#">
			<cfoutput>
				<div class="container">
					<div class="row">
						<div class="alert alert-danger" role="alert">
							<img src="/shared/images/Process-stop.png" alt="[ unauthorized access ]" style="float:left; width: 50px;margin-right: 1em;">
							<h2>Internal Server Error.</h2>
							<p>#message#</p>
							<p><a href="/info/bugs.cfm">â€œFeedback/Report Errorsâ€�</a></p>
						</div>
					</div>
				</div>
			</cfoutput>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn #serializeJSON(data)#>
</cffunction>

</cfcomponent>
