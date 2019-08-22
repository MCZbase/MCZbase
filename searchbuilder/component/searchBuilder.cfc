<!---
searchbuilder/component/searchBuilder.cfc

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
<cffunction name=”getSearchBuilderData” displayname="Get Search Field Data" access="remote" returntype="any" returnformat="json" >
<cfargument name="testing" required="true" type="numeric" default="1" />
<cfargument name="qry" required="true" type="numeric" />
<cfset username="#session.dbuser#" />
<cfset password="#decrypt(session.epw,cfid)#">





<cfset listColumns ="ff.collection_object_id,ff.collection,ff.cat_num,ff.scientific_name,ff.spec_locality,ff.higher_geog,ff.collectors,ff.verbatim_date,ff.coll_obj_disposition,ff.othercatalognumbers" />
<cfif isDefined("searchText") and len(searchText) gt 0>
<cfquery name="qryLoc" datasource="uam_god">
select #listColumns# from #session.flatTableName# ff, FLAT_text ft 
WHERE CONTAINS(ft.cat_num, <cfqueryparam cfsqltype="CF_SQL_TEXT" value="#searchText#">, 1) > 0 and ft.collection_object_id = ff.collection_object_id
</cfquery>
<cfelse>
<cfquery name="qryLoc" datasource="user_login" username="#username#" password="#password#">
select #listColumns# from #session.flatTableName# ff where rownum <= 50 and spec_locality like '%Massachusetts%'
</cfquery>
</cfif>
<cfoutput>
	<cfset i = 1>
	<cfset data = ArrayNew(1)>
	<cfloop query="qryLoc">
		<cfset row = StructNew()>
	    <cfset row["collection_object_id"] = "#qryLoc.collection_object_id#">
		<cfset row["collection"] = "#qryLoc.collection#">
		<cfset row["cat_num"] = "#qryLoc.cat_num#">
		<cfset row["scientific_name"] = "#qryLoc.scientific_name#">
		<cfset row["spec_locality"] = "#qryLoc.spec_locality#">
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
