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

<!---   Function getDataTable  --->
<cffunction name="getDataTable" access="remote" returntype="any" returnformat="json">
	<cfargument name="searchText" type="string" required="no">
	<cfif isDefined("searchText") and len(searchText) gt 0>
		<!---<cfquery name="qryLoc" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">--->
		<!---TODO:Permission for flat text search--->
		<cfquery name="qryLoc" datasource="uam_god">
			SELECT 
				substr(imageurl, 1, instr(imageurl, '|')-1) imageurl,
				ff.collection_object_id, ff.collection, ff.cat_num, 
				ff.began_date, ff.ended_date, ff.scientific_name, 
				ff.spec_locality, ff.locality_id, ff.higher_geog, ff.collectors, ff.verbatim_date, 
				ff.coll_obj_disposition, ff.othercatalognumbers
			FROM 
				#session.flatTableName# ff 
				left join FLAT_TEXT ft on ff.collection_object_id = ft.collection_object_id
			WHERE 
				ff.collectors = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#searchText#">
				<!---OR
				 CONTAINS(ft.lithostratigraphicterms, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#searchText#">, 1) > 0 OR
				CONTAINS(ft.verbatUimlocality, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#searchText#">, 2) > 0 OR
				CONTAINS(ft.cat_num, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#searchText#">, 3) > 0 OR
				CONTAINS(ft.preparators, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#searchText#">, 5) > 0 OR
				CONTAINS(ft.othercatalognumbers, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#searchText#">, 6) > 0 OR
				CONTAINS(ft.typestatusplain, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#searchText#">, 7) > 0 OR
				CONTAINS(ft.sex, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#searchText#">, 8) > 0 OR
				CONTAINS(ft.partdetail, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#searchText#">, 9) > 0 OR
				CONTAINS(ft.verbatimdate, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#searchText#">, 10) > 0 OR
				CONTAINS(ft.higher_geog, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#searchText#">, 11) > 0 OR
				CONTAINS(ft.spec_locality, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#searchText#">, 12) > 0 OR
				CONTAINS(ft.scientific_name, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#searchText#">, 13) > 0 --->
		</cfquery>
	<cfelse>
		<cfquery name="qryLoc" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			SELECT  
				substr(imageurl, 1, instr(imageurl, '|')-1) imageurl,
				ff.collection_object_id, ff.collection, ff.cat_num, 
				ff.began_date, ff.ended_date, ff.scientific_name, 
				ff.spec_locality, ff.locality_id, ff.higher_geog, ff.collectors, ff.verbatim_date, 
				ff.coll_obj_disposition, ff.othercatalognumbers
			FROM
				FILTERED_FLAT ff
			WHERE
				rownum <= 50 and spec_locality like '%Massachusetts%'
		</cfquery>
	</cfif>
	<cfoutput>
		<cfset i = 1>
		<cfset data = ArrayNew(1)>
		<cfloop query="qryLoc">
			<cfset row = StructNew()>
			<cfset row["imageurl"] = "#qryLoc.imageurl#">
			<cfset row["collection_object_id"] = "#qryLoc.collection_object_id#">
			<cfset row["collection"] = "#qryLoc.collection#">
			<cfset row["cat_num"] = "#qryLoc.cat_num#">
			<cfset row["began_date"] = "#qryLoc.began_date#">
			<cfset row["ended_date"] = "#qryLoc.ended_date#">
			<cfset row["scientific_name"] = "#qryLoc.scientific_name#">
			<cfset row["spec_locality"] = "#qryLoc.spec_locality#">
			<cfset row["locality_id"] = "#qryLoc.locality_id#">
			<cfset row["higher_geog"] = "#qryLoc.higher_geog#">
			<cfset row["collectors"] = "#qryLoc.collectors#">
			<cfset row["verbatim_date"] = "#qryLoc.verbatim_date#">
			<cfset row["coll_obj_disposition"] = "#qryLoc.coll_obj_disposition#">
			<cfset row["othercatalognumbers"] = "#qryLoc.othercatalognumbers#">
			<cfset data[i] = row>
			<cfset i = i + 1>
		</cfloop>
	<cfoutput>
	</cfoutput>
		<cfreturn #serializeJSON(data)#>
	</cfoutput>
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
							<p><a href="/info/bugs.cfm">“Feedback/Report Errors”</a></p>
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
							<p><a href="/info/bugs.cfm">“Feedback/Report Errors”</a></p>
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
							<p><a href="/info/bugs.cfm">“Feedback/Report Errors”</a></p>
						</div>
					</div>
				</div>
			</cfoutput>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn #serializeJSON(data)#>
</cffunction>

<!--- getTypes get type names and other information about type specimens by collection
 @param collection collection code for the collection for which to look up types
 @param kind jind of type status, Primary, Secondary, Voucher, Voucher Not of types to return
 @return json suitable for a jqx grid
--->
<cffunction name="getTypes" access="remote" returntype="any" returnformat="json">
	<cfargument name="collection" type="string" required="yes">
	<cfargument name="kind" type="string" required="yes">

	<cftry>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			SELECT DISTINCT
				flat.guid, 
				flat.cat_num,
				toptypestatuskind, 
				mczbase.get_top_typestatus(flat.collection_object_id) as toptypestatus, 
				taxonomy.family,
				taxonomy.genus as typegenus, 
				taxonomy.species as typespecies, 
				taxonomy.subspecies as typesubspecies, 
				decode(taxonomy.subspecies, null, taxonomy.species, taxonomy.subspecies) as typeepithet,
				typestatusplain, 
				mczbase.get_typestatusname(flat.collection_object_id, mczbase.get_top_typestatus(flat.collection_object_id),0) as typename,  
				mczbase.get_typestatusauthor(flat.collection_object_id, mczbase.get_top_typestatus(flat.collection_object_id)) as typeauthorship,  
				flat.scientific_name as currentname, 
				flat.author_text as currentauthorship, 
				CONCATATTRIBUTEVALUE(flat.collection_object_id,'associated grant') as associatedgrant, 
				CONCATUNDERSCORECOLS(flat.collection_object_id) as namedgroups,
				flat.country,
				flat.spec_locality 
			FROM <cfif ucase(session.flatTableName) EQ "FLAT"> flat <cfelse> filtered_flat </cfif> flat
				, taxonomy 
			WHERE collection_cde = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#collection#"> 
				and toptypestatuskind = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#kind#"> 
				and taxonomy.taxon_name_id = mczbase.GET_TYPESTATUSTAXON(flat.collection_object_id,mczbase.get_top_typestatus(flat.collection_object_id))
			ORDER BY
				taxonomy.family, taxonomy.genus, decode(taxonomy.subspecies, null, taxonomy.species, taxonomy.subspecies)
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

</cfcomponent>
