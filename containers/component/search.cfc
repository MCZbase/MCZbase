<!---
containers/component/search.cfc

Functions supporting searching and reporting on containers.

Copyright 2023-2026 President and Fellows of Harvard College

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

<!--- getContainerShapeSummary obtain a summary of counts of containers by type and role, 
	for use in the container shape report. 
	@return query with columns: metric, metric_value
--->
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

<!--- getContainerShapeByDepth obtain a summary of counts of containers by depth below root, 
	for use in the container shape report. 
	@return query with columns: depth_below, node_count
--->
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

<!--- getContainerShapeHotspots obtain a list of containers that are "hotspots" in the container tree, 
	defined as either:
	- containers with 1000 or more direct collection-object children and no structural children (shape class B)
	- containers with 200 or more direct collection-object children and at least one structural child (shape class AB)
	- containers with at least one direct collection-object child and at least one structural child (shape class AB)
	@return query with columns: container_id, container_type, label, direct_children, direct_leaf_children, direct_structural_children, shape_class
--->
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
child distribution against the expected role metadata for each type from ctcontainer_type.

@return query with one row per container_type, showing the expected role, whether the type expects leaf children,
Columns returned:
  container_type, expected_role, expects_leaf_child_count, total_count,
  with_coll_obj_children, with_structural_children, with_both_types, leaf_nodes

--->
<cffunction name="getContainerTypeRoleFit" access="remote" returntype="query" output="false">
	<cfquery name="qTypeFit" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		SELECT
			container_type,
			expected_role,
			expects_leaf_child_count,
			COUNT(*) AS total_count,
			SUM(CASE WHEN has_coll_obj_child = 1 THEN 1 ELSE 0 END)
				AS with_coll_obj_children,
			SUM(CASE WHEN has_struct_child = 1 THEN 1 ELSE 0 END)
				AS with_structural_children,
			SUM(CASE WHEN has_coll_obj_child = 1 AND has_struct_child = 1 THEN 1 ELSE 0 END)
				AS with_both_types,
			SUM(CASE WHEN child_count = 0 THEN 1 ELSE 0 END)
				AS leaf_nodes
		FROM (
			SELECT
				c.container_type,
				NVL(ct.role, 'unknown') AS expected_role,
				NVL(ct.expects_leaf_child_count, 0) AS expects_leaf_child_count,
				NVL(ch.has_coll_obj_child,0) AS has_coll_obj_child,
				NVL(ch.has_struct_child,0) AS has_struct_child,
				NVL(ch.child_count,0) AS child_count
			FROM container c
			LEFT JOIN ctcontainer_type ct ON ct.container_type = c.container_type
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
		)
		GROUP BY container_type, expected_role, expects_leaf_child_count
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
		SELECT container_id, container_type, label, barcode, child_count, coll_obj_count
		FROM (
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
			) ch ON ch.parent_container_id = c.container_id
			WHERE c.container_type IN ('pin', 'slide', 'cryovial')
		)
		WHERE coll_obj_count <> 1
		ORDER BY container_type, child_count DESC
	</cfquery>
	<cfreturn qViolations>
</cffunction>

<!--- getCollObjContHistAnomalies returns collection objects that have more than one current container in the coll_obj_cont_hist table.
	@return query with columns: collection_object_id, ct (count of current containers)
--->
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


<!---
Function getContainerBreadcrumb.  Returns the ancestor chain for container_id as a JSON array
ordered from root to the given node, for use in breadcrumb display.
Uses Oracle CONNECT BY PRIOR walking upward from the given node to the root.

@param container_id the container_id whose ancestor chain is to be returned.
@return a JSON array of objects with keys: container_id, container_type, label, barcode;
  ordered from root (highest level) to the given node.
--->
<cffunction name="getContainerBreadcrumb" access="remote" returntype="any" returnformat="json">
	<cfargument name="container_id" type="numeric" required="yes">

	<cfset local.retval = ArrayNew(1)>
	<cftry>
		<cfquery name="queryGetBreadcrumb" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
			SELECT
				container_id,
				container_type,
				label,
				barcode
			FROM
				container
			START WITH
				container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.container_id#">
			CONNECT BY PRIOR
				parent_container_id = container_id
			ORDER BY LEVEL DESC
		</cfquery>
		<cfset local.i = 1>
		<cfloop query="queryGetBreadcrumb">
			<cfset local.row = StructNew()>
			<cfset local.row["container_id"] = queryGetBreadcrumb.container_id>
			<cfset local.row["container_type"] = queryGetBreadcrumb.container_type>
			<cfset local.row["label"] = queryGetBreadcrumb.label>
			<cfset local.row["barcode"] = queryGetBreadcrumb.barcode>
			<cfset local.retval[local.i] = local.row>
			<cfset local.i = local.i + 1>
		</cfloop>
	<cfcatch>
		<cfset local.error_message = cfcatchToErrorMessage(cfcatch)>
		<cfset local.function_called = "#GetFunctionCalledName()#">
		<cfscript>reportError(function_called="#local.function_called#", error_message="#local.error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn serializeJSON(local.retval)>
</cffunction>


<!---
Function searchContainers.  Searches containers by one or more criteria and returns
a paginated JSON result for display in the browse panel.

@param search_term optional substring to match against label OR barcode (case-insensitive).
@param container_type optional exact match on container_type.
@param barcode optional substring to match against barcode (case-insensitive).
@param description optional substring to match against description OR container_remarks (case-insensitive).
@param department optional prefix to match against label (case-insensitive, appends % wildcard).
@param tree_property optional filter by tree shape property:
  empty         - no structural or leaf children (excludes collection objects)
  misplaced     - container type with expects_leaf_child_count = 1 and more than one leaf child
  mixed         - has both structural children and collection-object children (AB shape)
  unplaced_leaf - collection object with no parent container
@param page page number (1-based), default 1.
@param pageSize rows per page, default 50.
@return JSON object: { rows: [...], page, pageSize, totalRows }
	Each row: container_id, container_type, label, barcode, description, container_remarks,
	direct_structural_children, direct_leaf_children, shape_class
--->
<cffunction name="searchContainers" access="remote" returntype="any" returnformat="json">
	<cfargument name="search_term" type="string" required="no" default="">
	<cfargument name="container_type" type="string" required="no" default="">
	<cfargument name="barcode" type="string" required="no" default="">
	<cfargument name="description" type="string" required="no" default="">
	<cfargument name="department" type="string" required="no" default="">
	<cfargument name="tree_property" type="string" required="no" default="">
	<cfargument name="page" type="numeric" required="no" default="1">
	<cfargument name="pageSize" type="numeric" required="no" default="50">

	<cfset local.retval = StructNew()>
	<cftry>
		<cfset local.offset = (arguments.page - 1) * arguments.pageSize>
		<cfset local.searchUpper = ucase(trim(arguments.search_term))>
		<cfset local.barcodeUpper = ucase(trim(arguments.barcode))>
		<cfset local.descUpper = ucase(trim(arguments.description))>
		<cfset local.deptUpper = ucase(trim(arguments.department))>
		<cfset local.treeProperty = trim(arguments.tree_property)>
		<!--- Determine whether tree_property requires a child-count JOIN in the COUNT query --->
		<cfset local.needsChildJoin = listFindNoCase("empty,misplaced,mixed", local.treeProperty) GT 0>
		<!--- Total row count --->
		<cfquery name="queryGetCount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
			SELECT COUNT(*) AS total_rows
			FROM container c
			<cfif local.needsChildJoin>
				LEFT JOIN (
					SELECT
						parent_container_id,
						SUM(CASE WHEN container_type = 'collection object' THEN 1 ELSE 0 END) AS direct_leaf_children,
						SUM(CASE WHEN container_type <> 'collection object' THEN 1 ELSE 0 END) AS direct_structural_children
					FROM container
					GROUP BY parent_container_id
				) ch ON ch.parent_container_id = c.container_id
			</cfif>
			WHERE 1=1
			<cfif len(local.searchUpper) GT 0>
				<cfif left(local.searchUpper,1) EQ "=">
					AND (
						UPPER(c.label) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#RemoveChars(local.searchUpper, 1, 1)#">
						OR UPPER(c.barcode) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#RemoveChars(local.searchUpper, 1, 1)#">
					)
				<cfelse>
					AND (
						UPPER(c.label) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#local.searchUpper#%">
						OR UPPER(c.barcode) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#local.searchUpper#%">
					)
				</cfif>
			</cfif>
			<cfif len(arguments.container_type) GT 0>
				AND c.container_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.container_type#">
			</cfif>
			<cfif len(local.barcodeUpper) GT 0>
				<cfif left(local.barcodeUpper,1) EQ "=">
					AND UPPER(c.barcode) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#RemoveChars(local.barcodeUpper, 1, 1)#">
				<cfelse>
					AND UPPER(c.barcode) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#local.barcodeUpper#%">
				</cfif>
			</cfif>
			<cfif len(local.descUpper) GT 0>
				AND (
					UPPER(c.description) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#local.descUpper#%">
					OR UPPER(c.container_remarks) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#local.descUpper#%">
				)
			</cfif>
			<cfif len(local.deptUpper) GT 0>
				AND UPPER(c.label) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#local.deptUpper#%">
			</cfif>
			<cfif local.treeProperty EQ "empty">
				AND c.container_type <> 'collection object'
				AND NVL(ch.direct_structural_children, 0) = 0
				AND NVL(ch.direct_leaf_children, 0) = 0
			<cfelseif local.treeProperty EQ "misplaced">
				AND c.container_type IN (
					SELECT container_type
					FROM ctcontainer_type
					WHERE NVL(expects_leaf_child_count, 0) = 1
				)
				AND NVL(ch.direct_leaf_children, 0) > 1
			<cfelseif local.treeProperty EQ "mixed">
				AND NVL(ch.direct_structural_children, 0) > 0
				AND NVL(ch.direct_leaf_children, 0) > 0
			<cfelseif local.treeProperty EQ "unplaced_leaf">
				AND c.container_type = 'collection object'
				AND c.parent_container_id IS NULL
			</cfif>
		</cfquery>
		<cfset local.totalRows = queryGetCount.total_rows>
		<!--- Paginated rows using Oracle ROWNUM two-level subquery --->
		<cfquery name="queryGetSearch" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
			SELECT container_id, parent_container_id, parent_container_type, container_type, label, barcode, description,
				container_remarks, direct_structural_children, direct_leaf_children, shape_class
			FROM (
				SELECT
					container_id, parent_container_id, parent_container_type, container_type, label, barcode, description,
					container_remarks, direct_structural_children, direct_leaf_children, shape_class,
					ROWNUM AS rn
				FROM (
					SELECT
						c.container_id,
						c.parent_container_id,
						p.container_type AS parent_container_type,
						c.container_type,
						c.label,
						c.barcode,
						c.description,
						c.container_remarks,
						NVL(ch.direct_structural_children, 0) AS direct_structural_children,
						NVL(ch.direct_leaf_children, 0) AS direct_leaf_children,
						<!--- Shape classification mirrors getContainerShapeHotspots:
						  B = dense leaf-only node (>=1000 direct collection objects, no structural children)
						  AB = mixed node (both structural children and collection objects present)
						  A = all other cases (structural only, or sparse leaf-only) --->
						CASE
							WHEN NVL(ch.direct_leaf_children, 0) >= 1000 AND NVL(ch.direct_structural_children, 0) = 0 THEN 'B'
							WHEN NVL(ch.direct_leaf_children, 0) > 0 AND NVL(ch.direct_structural_children, 0) > 0 THEN 'AB'
							ELSE 'A'
						END AS shape_class
					FROM container c
					LEFT JOIN container p ON p.container_id = c.parent_container_id
					LEFT JOIN (
						SELECT
							parent_container_id,
							SUM(CASE WHEN container_type = 'collection object' THEN 1 ELSE 0 END) AS direct_leaf_children,
							SUM(CASE WHEN container_type <> 'collection object' THEN 1 ELSE 0 END) AS direct_structural_children
						FROM container
						GROUP BY parent_container_id
					) ch ON ch.parent_container_id = c.container_id
					WHERE 1=1
					<cfif len(local.searchUpper) GT 0>
						<cfif left(local.searchUpper,1) EQ "=">
							AND (
								UPPER(c.label) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#RemoveChars(local.searchUpper, 1, 1)#">
								OR UPPER(c.barcode) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#RemoveChars(local.searchUpper, 1, 1)#">
							)
						<cfelse>
							AND (
								UPPER(c.label) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#local.searchUpper#%">
								OR UPPER(c.barcode) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#local.searchUpper#%">
							)
						</cfif>
					</cfif>
					<cfif len(arguments.container_type) GT 0>
						AND c.container_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.container_type#">
					</cfif>
					<cfif len(local.barcodeUpper) GT 0>
						<cfif left(local.barcodeUpper,1) EQ "=">
							AND UPPER(c.barcode) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#RemoveChars(local.barcodeUpper, 1, 1)#">
						<cfelse>
							AND UPPER(c.barcode) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#local.barcodeUpper#%">
						</cfif>
					</cfif>
					<cfif len(local.descUpper) GT 0>
						AND (
							UPPER(c.description) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#local.descUpper#%">
							OR UPPER(c.container_remarks) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#local.descUpper#%">
						)
					</cfif>
					<cfif len(local.deptUpper) GT 0>
						AND UPPER(c.label) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#local.deptUpper#%">
					</cfif>
					<cfif local.treeProperty EQ "empty">
						AND c.container_type <> 'collection object'
						AND NVL(ch.direct_structural_children, 0) = 0
						AND NVL(ch.direct_leaf_children, 0) = 0
					<cfelseif local.treeProperty EQ "misplaced">
						AND c.container_type IN (
							SELECT container_type
							FROM ctcontainer_type
							WHERE NVL(expects_leaf_child_count, 0) = 1
						)
						AND NVL(ch.direct_leaf_children, 0) > 1
					<cfelseif local.treeProperty EQ "mixed">
						AND NVL(ch.direct_structural_children, 0) > 0
						AND NVL(ch.direct_leaf_children, 0) > 0
					<cfelseif local.treeProperty EQ "unplaced_leaf">
						AND c.container_type = 'collection object'
						AND c.parent_container_id IS NULL
					</cfif>
					ORDER BY c.label, c.barcode
				)
				WHERE ROWNUM <= <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#local.offset + arguments.pageSize#">
			)
			WHERE rn > <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#local.offset#">
		</cfquery>
		<cfset local.rows = ArrayNew(1)>
		<cfset local.i = 1>
		<cfloop query="queryGetSearch">
			<cfset local.row = StructNew()>
			<cfset local.row["container_id"] = queryGetSearch.container_id>
			<cfset local.row["parent_container_id"] = queryGetSearch.parent_container_id>
			<cfset local.row["parent_container_type"] = queryGetSearch.parent_container_type>
			<cfset local.row["container_type"] = queryGetSearch.container_type>
			<cfset local.row["label"] = queryGetSearch.label>
			<cfset local.row["barcode"] = queryGetSearch.barcode>
			<cfset local.row["description"] = queryGetSearch.description>
			<cfset local.row["container_remarks"] = queryGetSearch.container_remarks>
			<cfset local.row["direct_structural_children"] = queryGetSearch.direct_structural_children>
			<cfset local.row["direct_leaf_children"] = queryGetSearch.direct_leaf_children>
			<cfset local.row["shape_class"] = queryGetSearch.shape_class>
			<cfset local.rows[local.i] = local.row>
			<cfset local.i = local.i + 1>
		</cfloop>
		<cfset local.retval["rows"] = local.rows>
		<cfset local.retval["page"] = arguments.page>
		<cfset local.retval["pageSize"] = arguments.pageSize>
		<cfset local.retval["totalRows"] = local.totalRows>
	<cfcatch>
		<cfset local.error_message = cfcatchToErrorMessage(cfcatch)>
		<cfset local.function_called = "#GetFunctionCalledName()#">
		<cfscript>reportError(function_called="#local.function_called#", error_message="#local.error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn serializeJSON(local.retval)>
</cffunction>


<!---
Function getContainerTypeMetadata. Returns ctcontainer_type metadata for client-side placement logic.
--->
<cffunction name="getContainerTypeMetadata" access="remote" returntype="any" returnformat="json" output="false">
	<cfset local.rows = ArrayNew(1)>
	<cfset local.i = 1>
	<cfquery name="queryCtContainerType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
		SELECT
			container_type,
			role,
			expects_leaf_child_count,
			expected_parent_types,
			force_expected_parent_type,
			rank_order,
			variable_rank,
			description
		FROM
			ctcontainer_type
		ORDER BY
			rank_order,
			container_type
	</cfquery>
	<cfloop query="queryCtContainerType">
		<cfset local.row = StructNew()>
		<cfset local.row["container_type"] = queryCtContainerType.container_type>
		<cfset local.row["role"] = queryCtContainerType.role>
		<cfset local.row["expects_leaf_child_count"] = queryCtContainerType.expects_leaf_child_count>
		<cfset local.row["expected_parent_types"] = queryCtContainerType.expected_parent_types>
		<cfset local.row["force_expected_parent_type"] = queryCtContainerType.force_expected_parent_type>
		<cfset local.row["rank_order"] = queryCtContainerType.rank_order>
		<cfset local.row["variable_rank"] = queryCtContainerType.variable_rank>
		<cfset local.row["description"] = queryCtContainerType.description>
		<cfset local.rows[local.i] = local.row>
		<cfset local.i = local.i + 1>
	</cfloop>
	<cfreturn serializeJSON(local.rows)>
</cffunction>

<!---
Function pickContainerDialogHtml. Returns the placement dialog HTML fragment for parent-container picking.
--->
<cffunction name="pickContainerDialogHtml" access="remote" returntype="string" returnformat="plain" output="false">
	<cfargument name="child_container_id" type="string" required="no" default="">
	<cfargument name="preselect_type" type="string" required="no" default="">
	<cfargument name="ancestor_container_id" type="string" required="no" default="">
	<cfargument name="institution_acronym" type="string" required="no" default="">
	<cfargument name="id_suffix" type="string" required="no" default="">

	<cfset local.safeSuffix = REReplace(arguments.id_suffix, "[^A-Za-z0-9_-]", "", "all")>
	<cfset local.typeControlId = "pickContainerType#local.safeSuffix#">
	<cfset local.ancestorControlId = "pickContainerAncestor#local.safeSuffix#">
	<cfset local.ancestorIdControlId = "pickContainerAncestorId#local.safeSuffix#">
	<cfset local.searchControlId = "pickContainerSearch#local.safeSuffix#">
	<cfset local.searchIdControlId = "pickContainerSearchId#local.safeSuffix#">
	<cfset local.validationControlId = "pickContainerValidation#local.safeSuffix#">
	<cfset local.confirmControlId = "pickContainerConfirm#local.safeSuffix#">
	<cfset local.cancelControlId = "pickContainerCancel#local.safeSuffix#">
	<cfset local.statusControlId = "pickContainerStatus#local.safeSuffix#">
	<cfset local.selectedType = trim(arguments.preselect_type)>

	<cfquery name="queryAllowedTypes" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
		SELECT
			container_type,
			rank_order
		FROM
			ctcontainer_type
		WHERE
			role IN ('structural', 'leafbearer')
		ORDER BY
			rank_order,
			container_type
	</cfquery>

	<cfif len(trim(arguments.child_container_id)) GT 0 AND isNumeric(arguments.child_container_id)>
		<cfquery name="queryChildExpected" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
			SELECT
				NVL(ct.expected_parent_types, 'any') AS expected_parent_types
			FROM
				container c
				LEFT JOIN ctcontainer_type ct ON ct.container_type = c.container_type
			WHERE
				c.container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.child_container_id#">
		</cfquery>
		<cfif queryChildExpected.recordcount EQ 1 AND len(trim(local.selectedType)) EQ 0>
			<cfset local.expectedTypeList = trim(queryChildExpected.expected_parent_types)>
			<cfif local.expectedTypeList NEQ "" AND lCase(local.expectedTypeList) NEQ "any" AND lCase(local.expectedTypeList) NEQ "none">
				<cfset local.selectedType = trim(listFirst(local.expectedTypeList, ","))>
			</cfif>
		</cfif>
	</cfif>

	<cfsavecontent variable="local.htmlFragment"><cfoutput>
		<div class="form-row mb-2">
			<div class="col-12 col-md-6 mb-1">
				<label for="#encodeForHtml(local.typeControlId)#" class="data-entry-label">Container Type</label>
				<select id="#encodeForHtml(local.typeControlId)#" class="data-entry-select col-12">
					<option value=""></option>
					<cfloop query="queryAllowedTypes">
						<cfset local.selectedFlag = "">
						<cfif queryAllowedTypes.container_type EQ local.selectedType>
							<cfset local.selectedFlag = " selected">
						</cfif>
						<option value="#encodeForHtml(queryAllowedTypes.container_type)#"#local.selectedFlag#>#encodeForHtml(queryAllowedTypes.container_type)#</option>
					</cfloop>
				</select>
			</div>
			<div class="col-12 col-md-6 mb-1">
				<label for="#encodeForHtml(local.ancestorControlId)#" class="data-entry-label">Limit to subtree (optional)</label>
				<input type="text" id="#encodeForHtml(local.ancestorControlId)#" class="data-entry-input col-12" value="">
				<input type="hidden" id="#encodeForHtml(local.ancestorIdControlId)#" value="#encodeForHtml(arguments.ancestor_container_id)#">
			</div>
		</div>
		<div class="form-row mb-2">
			<div class="col-12 mb-1">
				<label for="#encodeForHtml(local.searchControlId)#" class="data-entry-label">Container</label>
				<input type="text" id="#encodeForHtml(local.searchControlId)#" class="data-entry-input col-12" value="">
				<input type="hidden" id="#encodeForHtml(local.searchIdControlId)#" value="">
			</div>
		</div>
		<cfif len(trim(arguments.institution_acronym)) GT 0>
			<div class="small text-muted mb-2">Search limited to institution: #encodeForHtml(arguments.institution_acronym)#</div>
		</cfif>
		<div id="#encodeForHtml(local.validationControlId)#" role="status" aria-live="polite" class="mb-2"></div>
		<div class="form-row">
			<div class="col-12">
				<button type="button" id="#encodeForHtml(local.confirmControlId)#" class="btn btn-xs btn-primary" disabled="disabled">Confirm</button>
				<button type="button" id="#encodeForHtml(local.cancelControlId)#" class="btn btn-xs btn-warning ml-1">Cancel</button>
				<output id="#encodeForHtml(local.statusControlId)#" class="ml-2"></output>
			</div>
		</div>
	</cfoutput></cfsavecontent>

	<cfreturn local.htmlFragment>
</cffunction>

</cfcomponent>
