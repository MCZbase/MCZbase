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
<!---   Function getDataTable  --->
<cffunction name="getDataTable" access="remote" returntype="any" returnformat="json">
    <cfargument name="searchText" type="string" required="no">
	<cfif isDefined("searchText") and len(searchText) gt 0>
	    <!---<cfquery name="qryLoc" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">--->
		<!---TODO:Permission for flat text search--->
		<cfquery name="qryLoc" datasource="uam_god">
	    SELECT 
			substr(imageurl, 1, instr(imageurl, '|')-1) imageurl,ff.collection_object_id, ff.collection, ff.cat_num, ff.began_date, ff.ended_date, ff.scientific_name, ff.spec_locality, ff.locality_id, ff.higher_geog, ff.collectors, ff.verbatim_date, ff.coll_obj_disposition, ff.othercatalognumbers
	    FROM 
			#session.flatTableName# ff 
	         left join FLAT_TEXT ft on ff.collection_object_id = ft.collection_object_id
		<!--- FROM filtered_flat ff --->
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
			substr(imageurl, 1, instr(imageurl, '|')-1) imageurl,ff.collection_object_id, ff.collection, ff.cat_num, ff.began_date, ff.ended_date, ff.scientific_name, ff.spec_locality, ff.locality_id, ff.higher_geog, ff.collectors, ff.verbatim_date, ff.coll_obj_disposition, ff.othercatalognumbers
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
			<cfset data[i]  = row>
			<cfset i = i + 1>
		</cfloop>
	<cfoutput>
	</cfoutput>
		<cfreturn #serializeJSON(data)#>
	</cfoutput>
</cffunction>
</cfcomponent>
