<!---
containers/component/search.cfc

Copyright 2023-2025 President and Fellows of Harvard College

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
<cf_rolecheck><!--- restricted role access --->
<cfinclude template="/shared/component/error_handler.cfc" runOnce="true">

<!---
Function getContainerAutocomplete.  Search for containers by name with a substring match on label or barcode, returning json suitable for jquery-ui autocomplete.

@param term container label or barcode to search for.
@return a json structure containing id and value, with matching container with matched type, label, and barcode in value and container_id in id.
--->
<cffunction name="getContainerAutocomplete" access="remote" returntype="any" returnformat="json">
	<cfargument name="term" type="string" required="yes">
	<!--- perform wildcard search anywhere in barcode or label --->
	<cfset name = "%#term#%"> 

	<cfset data = ArrayNew(1)>
	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="search_result" timeout="#Application.query_timeout#">
			SELECT 
				container_id, label, barcode, container_type
			FROM 
				container
			WHERE
				upper(label) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(name)#">
				OR
				upper(barcode) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(name)#">
				<cfif REFind('^[0-9]+$',term) GT 0>
					OR
					upper(container_id) <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#term#">
				</cfif>
		</cfquery>
	<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfset row["id"] = "#search.container_id#" >
			<cfset row["value"] = "#search.container_type#: #search.label# (#search.barcode#)" >
			<cfset data[i]  = row>
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

<!---
Function getContainerAutocompleteMeta.  Search for containers by name with a substring match on label or barcode, 
  or exact match on container_id, returning json suitable for jquery-ui autocomplete.

@param term container label or barcode or container_id to search for.
@return a json structure containing id and value, with matching container with matched barcode in value and  
  type, label, and barcode in meta and container_id in id.
--->
<cffunction name="getContainerAutocompleteMeta" access="remote" returntype="any" returnformat="json">
	<cfargument name="term" type="string" required="yes">
	<cfargument name="exclude_coll_objects" type="string" required="no">
	<!--- perform wildcard search anywhere in barcode or label --->
	<cfset name = "%#term#%"> 

	<cfif not isDefined("exclude_coll_objects") OR len(exclude_coll_objects) EQ 0>
		<cfset exclude_coll_objects = "false">
	</cfif>	
	
	<cfset data = ArrayNew(1)>
	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="search_result" timeout="#Application.query_timeout#">
			SELECT 
				container_id, label, barcode, container_type
			FROM 
				container
			WHERE
				<cfif exclude_coll_objects EQ "true">
					container_type <> 'collection object'
					AND
					(
				</cfif>
				upper(label) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(name)#">
				OR
				upper(barcode) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(name)#">
				<cfif REFind('^[0-9]+$',term) GT 0>
					OR
					upper(container_id) = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#term#">
				</cfif>
				<cfif exclude_coll_objects EQ "true">
					)
				</cfif>
		</cfquery>
	<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfset row["id"] = "#search.container_id#" >
			<cfset row["meta"] = "#search.container_type#: #search.label# (#search.barcode#)" >
			<cfset row["value"] = "#search.barcode#" >
			<cfset data[i]  = row>
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

<!---
Function getContainerAutocompleteLimited.  Search for containers by name with a substring match on label or barcode, limited by type and optionally by parentage, returning json suitable for jquery-ui autocomplete.

@param term container label or barcode to search for.
@param type container type to limit search to.
@param ancestor_container_id optional ancestor container_id to limit search to.
@return a json structure containing id and value, with matching container with matched type, label, and barcode in value and container_id in id.
--->
<cffunction name="getContainerAutocompleteLimited" access="remote" returntype="any" returnformat="json">
	<cfargument name="term" type="string" required="yes">
	<cfargument name="type" type="string" required="no" default="">
	<cfargument name="ancestor_container_id" type="string" required="no" default="">

	<!--- perform wildcard search anywhere in barcode or label --->
	<cfset name = "%#term#%"> 

	<cfset data = ArrayNew(1)>
	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="search_result" timeout="#Application.query_timeout#">
			SELECT 
				container_id, label, barcode, container_type
			FROM (
				SELECT container_id, label, barcode, container_type
				FROM 
				container
				<cfif len(arguments.ancestor_container_id) GT 0>
					START WITH container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.ancestor_container_id#">
					CONNECT BY PRIOR container_id = parent_container_id
				</cfif>
				)
			WHERE
				(
				upper(label) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(name)#">
				OR
				upper(barcode) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(name)#">
				<cfif REFind('^[0-9]+$',term) GT 0>
					OR
					upper(container_id) = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#term#">
				</cfif>
				) 
				<cfif isDefined("arguments.type") AND len(arguments.type) GT 0>
					AND container_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.type#">
				<cfelse>
					AND rownum < 100
				</cfif>
		</cfquery>
	<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfset row["id"] = "#search.container_id#" >
			<cfset row["meta"] = "#search.container_type#: #search.label# (#search.barcode#)" >
			<cfset row["value"] = "#search.barcode#" >
			<cfset data[i]  = row>
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

<cffunction name="getContainerShapeSummary" access="remote" returntype="query" output="false">
	<cfquery name="qSummary" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		SELECT 'TOTAL_CONTAINERS' AS metric, TO_CHAR(COUNT(*)) AS metric_value FROM container
		UNION ALL
		SELECT 'TOTAL_COLLECTION_OBJECT_CONTAINERS' AS metric, TO_CHAR(COUNT(*)) AS metric_value
		FROM container
		WHERE container_type = 'collection object'
		UNION ALL
		SELECT 'TOTAL_STRUCTURAL_CONTAINERS' AS metric, TO_CHAR(COUNT(*)) AS metric_value
		FROM container
		WHERE container_type <> 'collection object'
	</cfquery>
	<cfreturn qSummary>
</cffunction>

<cffunction name="getContainerShapeByDepth" access="remote" returntype="query" output="false">
	<cfquery name="qDepth" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		SELECT
			max_depth_below AS depth_below,
			COUNT(*) AS node_count
		FROM (
			SELECT
				root_id,
				MAX(lvl) - 1 AS max_depth_below
			FROM (
				SELECT
					CONNECT_BY_ROOT container_id AS root_id,
					LEVEL AS lvl
				FROM container
				CONNECT BY PRIOR container_id = parent_container_id
			)
			GROUP BY root_id
		)
		GROUP BY max_depth_below
		ORDER BY max_depth_below
	</cfquery>
	<cfreturn qDepth>
</cffunction>

<cffunction name="getContainerShapeHotspots" access="remote" returntype="query" output="false">
	<cfquery name="qHotspots" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		SELECT
			c.container_id,
			c.container_type,
			c.label,
			NVL(cc.direct_children,0) AS direct_children,
			NVL(cc.direct_leaf_children,0) AS direct_leaf_children,
			NVL(cc.direct_structural_children,0) AS direct_structural_children,
			CASE
				WHEN NVL(cc.direct_leaf_children,0) >= 1000 AND NVL(cc.direct_structural_children,0) = 0 THEN 'B'
				WHEN NVL(cc.direct_leaf_children,0) >= 200 AND NVL(cc.direct_structural_children,0) > 0 THEN 'AB'
				WHEN NVL(cc.direct_leaf_children,0) > 0 AND NVL(cc.direct_structural_children,0) > 0 THEN 'AB'
				ELSE 'A'
			END AS shape_class
		FROM container c
		LEFT JOIN (
			SELECT
				parent_container_id,
				COUNT(*) AS direct_children,
				SUM(CASE WHEN container_type = 'collection object' THEN 1 ELSE 0 END) AS direct_leaf_children,
				SUM(CASE WHEN container_type = 'collection object' THEN 0 ELSE 1 END) AS direct_structural_children
			FROM container
			GROUP BY parent_container_id
		) cc
			ON cc.parent_container_id = c.container_id
		WHERE NVL(cc.direct_leaf_children,0) >= 200
			OR (NVL(cc.direct_leaf_children,0) > 0 AND NVL(cc.direct_structural_children,0) > 0)
		ORDER BY NVL(cc.direct_leaf_children,0) DESC
	</cfquery>
	<cfreturn qHotspots>
</cffunction>

<!---
Function getContainerTypeRoleFit.  Returns per-container-type statistics comparing the actual
child distribution against the expected role for each type, based on CTCONTAINER_TYPE:
  C  = expected to contain only structural (non-collection-object) containers
       (institution, campus, cryovat, building, floor, room, freezer, freezer rack,
        grouping, set, fixture, rack slot, position)
  S  = expected to contain only collection-object containers (leaf nodes)
       (cryovial, tank, jar, glass vial, envelope, slide, pin)
  SC = may contain both structural containers and collection objects
       (freezer box, compartment)
  leaf = collection object; should never have children

Columns returned:
  container_type, expected_role, total_count,
  with_coll_obj_children, with_structural_children, with_both_types, leaf_nodes

--->
<cffunction name="getContainerTypeRoleFit" access="remote" returntype="query" output="false">
	<cfquery name="qTypeFit" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		SELECT
			c.container_type,
			CASE
				WHEN c.container_type IN (
					'institution','campus','cryovat','building','floor','room',
					'freezer','freezer rack','grouping','set','fixture',
					'rack slot','position'
				) THEN 'C'
				WHEN c.container_type IN (
					'cryovial','tank','jar','glass vial','envelope','slide','pin'
				) THEN 'S'
				WHEN c.container_type IN ('freezer box','compartment') THEN 'SC'
				WHEN c.container_type = 'collection object' THEN 'leaf'
				ELSE 'unknown'
			END AS expected_role,
			COUNT(*) AS total_count,
			SUM(CASE WHEN NVL(ch.has_coll_obj_child,0) = 1 THEN 1 ELSE 0 END)
				AS with_coll_obj_children,
			SUM(CASE WHEN NVL(ch.has_struct_child,0) = 1 THEN 1 ELSE 0 END)
				AS with_structural_children,
			SUM(CASE WHEN NVL(ch.has_coll_obj_child,0) = 1 AND NVL(ch.has_struct_child,0) = 1 THEN 1 ELSE 0 END)
				AS with_both_types,
			SUM(CASE WHEN NVL(ch.child_count,0) = 0 THEN 1 ELSE 0 END)
				AS leaf_nodes
		FROM container c
		LEFT JOIN (
			SELECT
				parent_container_id,
				COUNT(*) AS child_count,
				MAX(CASE WHEN container_type = 'collection object' THEN 1 ELSE 0 END)
					AS has_coll_obj_child,
				MAX(CASE WHEN container_type <> 'collection object' THEN 1 ELSE 0 END)
					AS has_struct_child
			FROM container
			GROUP BY parent_container_id
		) ch ON ch.parent_container_id = c.container_id
		GROUP BY
			c.container_type,
			CASE
				WHEN c.container_type IN (
					'institution','campus','cryovat','building','floor','room',
					'freezer','freezer rack','grouping','set','fixture',
					'rack slot','position'
				) THEN 'C'
				WHEN c.container_type IN (
					'cryovial','tank','jar','glass vial','envelope','slide','pin'
				) THEN 'S'
				WHEN c.container_type IN ('freezer box','compartment') THEN 'SC'
				WHEN c.container_type = 'collection object' THEN 'leaf'
				ELSE 'unknown'
			END
		ORDER BY total_count DESC
	</cfquery>
	<cfreturn qTypeFit>
</cffunction>

<!---
Function getSingleOccupantViolations.  Returns containers of type pin, slide, or cryovial
that do not hold exactly one collection-object child.  These types are expected to contain
exactly one collection object; zero or two-or-more children both represent anomalies.

@return query with container_id, container_type, label, barcode, child_count, coll_obj_count
--->
<cffunction name="getSingleOccupantViolations" access="remote" returntype="query" output="false">
	<cfquery name="qViolations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		SELECT
			c.container_id,
			c.container_type,
			c.label,
			c.barcode,
			ch.child_count,
			ch.coll_obj_count
		FROM container c
		JOIN (
			SELECT
				parent_container_id,
				COUNT(*) AS child_count,
				SUM(CASE WHEN container_type = 'collection object' THEN 1 ELSE 0 END)
					AS coll_obj_count
			FROM container
			GROUP BY parent_container_id
			HAVING SUM(CASE WHEN container_type = 'collection object' THEN 1 ELSE 0 END) <> 1
		) ch ON ch.parent_container_id = c.container_id
		WHERE c.container_type IN ('pin', 'slide', 'cryovial')
		ORDER BY c.container_type, ch.child_count DESC
	</cfquery>
	<cfreturn qViolations>
</cffunction>

<cffunction name="getCollObjContHistAnomalies" access="remote" returntype="query" output="false">
	<cfquery name="qAnom" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		SELECT
			collection_object_id,
			COUNT(*) AS ct
		FROM coll_obj_cont_hist
		WHERE current_container_fg = 1
		GROUP BY collection_object_id
		HAVING COUNT(*) > 1
		ORDER BY collection_object_id
	</cfquery>
	<cfreturn qAnom>
</cffunction>

</cfcomponent>
