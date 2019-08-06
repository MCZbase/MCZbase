<cfcomponent>
<!---   Function getDataTable  --->
<cffunction name="getDataTable" access="remote" returntype="any" returnformat="json">
    <cfargument name="searchText" type="string" required="no">
	<cfif isDefined("searchText") and len(searchText) gt 0>
	    <cfquery name="qryLoc" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	    select  ff.collection_object_id, ff.collection, ff.cat_num, ff.scientific_name, ff.spec_locality, 
	            ff.higher_geog, ff.collectors, ff.verbatim_date, ff.coll_obj_disposition, ff.othercatalognumbers
	    from #session.flatTableName# ff 
	         left join FLAT_TEXT ft on ff.collection_object_id = ft.collection_object_id
	    WHERE 
             CONTAINS(ft.lithostratigraphicterms, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#searchText#">, 1) > 0 OR
             CONTAINS(ft.verbatimlocality, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#searchText#">, 2) > 0 OR
             CONTAINS(ft.cat_num, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#searchText#">, 3) > 0 OR
             CONTAINS(ft.collectors, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#searchText#">, 4) > 0 OR
             CONTAINS(ft.preparators, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#searchText#">, 5) > 0 OR
             CONTAINS(ft.othercatalognumbers, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#searchText#">, 6) > 0 OR
             CONTAINS(ft.typestatusplain, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#searchText#">, 7) > 0 OR
             CONTAINS(ft.sex, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#searchText#">, 8) > 0 OR
             CONTAINS(ft.partdetail, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#searchText#">, 9) > 0 OR
             CONTAINS(ft.verbatimdate, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#searchText#">, 10) > 0 OR
             CONTAINS(ft.higher_geog, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#searchText#">, 11) > 0 OR
             CONTAINS(ft.spec_locality, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#searchText#">, 12) > 0 OR
             CONTAINS(ft.scientific_name, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#searchText#">, 13) > 0 
	    </cfquery>
	<cfelse>
	    <cfquery name="qryLoc" datasource="uam_god">
	    select  ff.collection_object_id, ff.collection, ff.cat_num, ff.scientific_name, ff.spec_locality, 
	            ff.higher_geog, ff.collectors, ff.verbatim_date, ff.coll_obj_disposition, ff.othercatalognumbers
	    from FILTERED_FLAT ff
	            where rownum <= 50 and spec_locality like '%Massachusetts%'
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
