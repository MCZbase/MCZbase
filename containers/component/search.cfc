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
Function getContainerAutocompleteMeta.  Search for containers by name with a substring match on label or barcode,
  or exact match on container_id, returning json suitable for jquery-ui autocomplete.

@param term container label or barcode or container_id to search for.
@return a json structure containing id and value fields. The value contains the matched barcode,
  meta contains type/label/barcode, id contains container_id, and label/barcode contain raw values.
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
			<cfset row["label"] = "#search.label#" >
			<cfset row["barcode"] = "#search.barcode#" >
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
@param label_contains optional case-insensitive substring filter on label.
@param description_contains optional case-insensitive substring filter on description/container remarks.
@return a json structure containing id and value fields. The value contains matched barcode,
  meta contains type/label/barcode, id contains container_id, label/barcode/type contain raw
  values (type lets the picker dialog flag proxy-role candidates in its dropdown).
--->
<cffunction name="getContainerAutocompleteLimited" access="remote" returntype="any" returnformat="json">
	<cfargument name="term" type="string" required="yes">
	<cfargument name="type" type="string" required="no" default="">
	<cfargument name="ancestor_container_id" type="string" required="no" default="">
	<cfargument name="label_contains" type="string" required="no" default="">
	<cfargument name="description_contains" type="string" required="no" default="">

	<!--- perform wildcard search anywhere in barcode or label --->
	<cfset name = "%#term#%"> 

	<cfset data = ArrayNew(1)>
	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="search_result" timeout="#Application.query_timeout#">
			SELECT 
				container_id, label, barcode, container_type
			FROM (
				SELECT container_id, label, barcode, container_type, description, container_remarks
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
				<cfif len(trim(arguments.label_contains)) GT 0>
					AND upper(label) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(trim(arguments.label_contains))#%">
				</cfif>
				<cfif len(trim(arguments.description_contains)) GT 0>
					AND (
						upper(description) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(trim(arguments.description_contains))#%">
						OR upper(container_remarks) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(trim(arguments.description_contains))#%">
					)
				</cfif>
		</cfquery>
		<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfset row["id"] = "#search.container_id#" >
			<cfset row["label"] = "#search.label#" >
			<cfset row["barcode"] = "#search.barcode#" >
			<cfset row["type"] = "#search.container_type#" >
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
@return a JSON array of objects with keys: container_id, parent_container_id, container_type, label,
  barcode, description; ordered from root (highest level) to the given node.
--->
<cffunction name="getContainerBreadcrumb" access="remote" returntype="any" returnformat="json">
	<cfargument name="container_id" type="numeric" required="yes">

	<cfset local.retval = ArrayNew(1)>
	<cftry>
		<cfquery name="queryGetBreadcrumb" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
			SELECT
				container_id,
				parent_container_id,
				container_type,
				label,
				barcode,
				description
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
			<cfset local.row["parent_container_id"] = queryGetBreadcrumb.parent_container_id>
			<cfset local.row["container_type"] = queryGetBreadcrumb.container_type>
			<cfset local.row["label"] = queryGetBreadcrumb.label>
			<cfset local.row["barcode"] = queryGetBreadcrumb.barcode>
			<cfset local.row["description"] = queryGetBreadcrumb.description>
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
Function chunkNumericList.  Splits a comma-separated list of numeric ids into an array of
  sub-lists, each capped below Oracle's 1000-expression IN-list limit, so a caller can OR
  together one parameterized IN-list per chunk instead of building a single IN-list that can
  exceed that cap (ORA-01795) when the source list is large (e.g. a saved search result set).

@param idList comma-separated list of numeric ids; may be blank.
@return array of comma-separated sub-lists (empty array if idList is blank).
--->
<cffunction name="chunkNumericList" access="private" returntype="array" output="false">
	<cfargument name="idList" type="string" required="yes">

	<cfset var local = StructNew()>
	<cfset local.chunks = ArrayNew(1)>
	<cfset local.chunkSize = 999>
	<cfset local.currentChunk = "">
	<cfset local.currentChunkLen = 0>
	<cfloop list="#arguments.idList#" index="local.oneId">
		<cfset local.currentChunk = listAppend(local.currentChunk, local.oneId)>
		<cfset local.currentChunkLen = local.currentChunkLen + 1>
		<cfif local.currentChunkLen EQ local.chunkSize>
			<cfset ArrayAppend(local.chunks, local.currentChunk)>
			<cfset local.currentChunk = "">
			<cfset local.currentChunkLen = 0>
		</cfif>
	</cfloop>
	<cfif local.currentChunkLen GT 0>
		<cfset ArrayAppend(local.chunks, local.currentChunk)>
	</cfif>
	<cfreturn local.chunks>
</cffunction>


<!---
Function searchContainers.  Searches containers by one or more criteria and returns
a paginated JSON result for display in the browse panel.

@param search_term optional substring to match against label OR barcode (case-insensitive).
@param container_type optional match on container_type -- a single exact value, a leading "!"
	for NOT, and/or a comma-separated list of values OR'd together (NOT-ed together if negated).
@param barcode optional substring to match against barcode (case-insensitive).
@param description optional substring to match against description OR container_remarks (case-insensitive).
@param department optional prefix to match against label (case-insensitive, appends % wildcard).
@param parent_container_type optional match on the searched container's parent's container_type --
  same "!"/comma-list syntax as container_type, applied against the parentcontainer alias.
@param parent_search_term optional substring to match against the parent's label OR barcode
  (case-insensitive), same "=text" exact-match convention as search_term.
@param parent_barcode optional substring to match against the parent's barcode alone
  (case-insensitive), same "=text" exact-match convention as barcode.
@param parent_description optional substring to match against the parent's description OR
  container_remarks (case-insensitive).
@param tree_property optional filter by tree shape property:
  empty         - no structural or leaf children (excludes collection objects)
  misplaced     - container type with expects_leaf_child_count = 1 and more than one leaf child
  mixed         - has both structural children and collection-object children (AB shape)
  unplaced_leaf - collection object with no parent container
@param has_positions optional number_positions filter:
  none          - number_positions is null or 0
  any           - number_positions > 0
  has_empty     - has positions where at least one position is unoccupied
  [numeric]     - exact number_positions match
@param position_filter optional position-membership filter:
  NOT NULL      - parent container is of type position
  NULL          - parent container is not a position
  [numeric]     - parent position with exact numeric label/barcode match
  [text]        - parent position label/barcode contains text (case-insensitive)
  [=text]       - parent position label/barcode exact text match (case-insensitive)
@param contains_guids optional comma/semicolon-separated list of specimen GUIDs; restricts results to
  containers currently holding a part of any of the named cataloged items.
@param contains_result_id optional saved search result_id (user_search_table); resolved the same way as
  contains_guids, against that search's distinct cataloged items.
@param contains_collection_object_ids optional comma-separated list of raw collection_object_id values
  (each may be a part or a cataloged item); resolved the same way as contains_guids and
  contains_result_id.
@param loan_number optional filter:
  NULL          - no part currently held by this container is checked out on any loan
  NOT NULL      - some part currently held by this container is checked out on some loan
  [text]        - substring match against loan.loan_number (case-insensitive); restricts results to
                  containers currently holding a part checked out on any matching loan
  [=text]       - exact loan.loan_number match (case-insensitive)
@param accn_number optional substring to match against accn.accn_number (case-insensitive); restricts
  results to containers linked to any matching accession via trans_container.
@param deacc_number optional filter, same NULL/NOT NULL/text/=text convention as loan_number, against
  deaccession.deacc_number -- resolved the same way as loan_number, since deaccession items relate to
  parts exactly like loan items.
@param transaction_id optional comma-separated list of transaction_ids (a loan/accession/deaccession
  deep link); each is looked up by its own transaction_type and resolved the same way as the matching
  loan_number/accn_number/deacc_number case.
@param page page number (1-based), default 1.
@param pageSize rows per page, default 50.
@return JSON object: { rows: [...], page, pageSize, totalRows }
	Each row: container_id, parent_container_id, parent_container_type, container_type, label,
	barcode, description, container_remarks, direct_structural_children, direct_leaf_children,
	shape_class
--->
<cffunction name="searchContainers" access="remote" returntype="any" returnformat="json">
	<cfargument name="search_term" type="string" required="no" default="">
	<cfargument name="container_type" type="string" required="no" default="">
	<cfargument name="barcode" type="string" required="no" default="">
	<cfargument name="description" type="string" required="no" default="">
	<cfargument name="department" type="string" required="no" default="">
	<cfargument name="parent_container_type" type="string" required="no" default="">
	<cfargument name="parent_search_term" type="string" required="no" default="">
	<cfargument name="parent_barcode" type="string" required="no" default="">
	<cfargument name="parent_description" type="string" required="no" default="">
	<cfargument name="tree_property" type="string" required="no" default="">
	<cfargument name="has_positions" type="string" required="no" default="">
	<cfargument name="position_filter" type="string" required="no" default="">
	<cfargument name="contains_guids" type="string" required="no" default="">
	<cfargument name="contains_result_id" type="string" required="no" default="">
	<cfargument name="contains_collection_object_ids" type="string" required="no" default="">
	<cfargument name="loan_number" type="string" required="no" default="">
	<cfargument name="accn_number" type="string" required="no" default="">
	<cfargument name="deacc_number" type="string" required="no" default="">
	<cfargument name="transaction_id" type="string" required="no" default="">
	<cfargument name="page" type="numeric" required="no" default="1">
	<cfargument name="pageSize" type="numeric" required="no" default="50">

	<cfset local.retval = StructNew()>
	<cftry>
		<cfset local.offset = (arguments.page - 1) * arguments.pageSize>
		<cfset local.searchUpper = ucase(trim(arguments.search_term))>
		<cfset local.barcodeUpper = ucase(trim(arguments.barcode))>
		<cfset local.descUpper = ucase(trim(arguments.description))>
		<cfset local.deptUpper = ucase(trim(arguments.department))>
		<!--- container_type supports: a single exact type (unchanged); a leading "!" for NOT;
			and/or a comma-separated list of types OR'd together (NOT-ed together if negated) --
			e.g. "fixture,cryovat,tank" or "!collection object". Parsed once, used by both the
			count query and the paginated results query below. --->
		<cfset local.containerTypeNegated = false>
		<cfset local.containerType = trim(arguments.container_type)>
		<cfif left(local.containerType, 1) EQ "!">
			<cfset local.containerTypeNegated = true>
			<cfset local.containerType = trim(right(local.containerType, len(local.containerType) - 1))>
		</cfif>
		<cfset local.containerTypeIsList = (listLen(local.containerType) GT 1)>
		<!--- parent_container_type supports the same "!"/comma-list syntax as container_type,
			parsed identically, but applied against the parentcontainer alias below. --->
		<cfset local.parentContainerTypeNegated = false>
		<cfset local.parentContainerType = trim(arguments.parent_container_type)>
		<cfif left(local.parentContainerType, 1) EQ "!">
			<cfset local.parentContainerTypeNegated = true>
			<cfset local.parentContainerType = trim(right(local.parentContainerType, len(local.parentContainerType) - 1))>
		</cfif>
		<cfset local.parentContainerTypeIsList = (listLen(local.parentContainerType) GT 1)>
		<cfset local.parentSearchUpper = ucase(trim(arguments.parent_search_term))>
		<cfset local.parentBarcodeUpper = ucase(trim(arguments.parent_barcode))>
		<cfset local.parentDescUpper = ucase(trim(arguments.parent_description))>
		<cfset local.treeProperty = trim(arguments.tree_property)>
		<cfset local.hasPositionsFilter = lcase(trim(arguments.has_positions))>
		<cfset local.positionFilter = trim(arguments.position_filter)>
		<cfset local.positionFilterUpper = ucase(local.positionFilter)>
		<cfset local.containsResultId = trim(arguments.contains_result_id)>
		<!--- "Contains" resolves each GUID directly to its cataloged item's collection_object_id via
			the flat view (a GUID always identifies a cataloged item, never a part, so no part/cataloged-
			item ambiguity here) -- collects into a comma list for a parameterized IN-list below. Blank
			(not zero) when nothing resolves, so the eventual filter can tell "no Contains value given"
			apart from "Contains value given but resolved to nothing" (the latter should return zero
			results, not silently ignore the filter). --->
		<cfset local.containsCatalogedItemIds = "">
		<cfif len(trim(arguments.contains_guids)) GT 0>
			<cfloop list="#arguments.contains_guids#" delimiters=",;" index="local.oneGuid">
				<cfset local.oneGuid = trim(local.oneGuid)>
				<cfif len(local.oneGuid) GT 0>
					<cfquery name="local.queryGuidLookup" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
						SELECT collection_object_id
						FROM <cfif ucase(session.flatTableName) EQ "FLAT">flat<cfelse>filtered_flat</cfif>
						WHERE guid = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#local.oneGuid#">
					</cfquery>
					<cfloop query="local.queryGuidLookup">
						<cfset local.containsCatalogedItemIds = listAppend(local.containsCatalogedItemIds, local.queryGuidLookup.collection_object_id)>
					</cfloop>
				</cfif>
			</cfloop>
		</cfif>
		<!--- Resolve a saved search's result_id to distinct cataloged items here, eagerly, and fold
			them into the same containsCatalogedItemIds list as the GUID path above, rather than
			embedding this lookup as a live subquery inside the Contains filter below -- that filter
			already joins the two largest tables in the schema (coll_obj_cont_hist, specimen_part), and
			the optimizer can't push a selective predicate through a subquery wrapped in NVL() nearly as
			well as it can a plain parameterized IN-list. --->
		<cfif len(local.containsResultId) GT 0>
			<cfquery name="local.queryContainsResultItems" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
				SELECT DISTINCT NVL(sp2.derived_from_cat_item, ust.collection_object_id) AS cataloged_item_id
				FROM user_search_table ust
					LEFT JOIN specimen_part sp2 ON sp2.collection_object_id = ust.collection_object_id
				WHERE ust.result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#local.containsResultId#">
			</cfquery>
			<cfloop query="local.queryContainsResultItems">
				<cfif NOT listFind(local.containsCatalogedItemIds, local.queryContainsResultItems.cataloged_item_id)>
					<cfset local.containsCatalogedItemIds = listAppend(local.containsCatalogedItemIds, local.queryContainsResultItems.cataloged_item_id)>
				</cfif>
			</cfloop>
		</cfif>
		<!--- Resolve a raw list of collection_object_ids (each id may be a part or a cataloged item)
			the same way: one bulk lookup against specimen_part rather than a query per id, since
			this list can run to hundreds of ids. Any
			id not found there is assumed to already be a cataloged item's own id. Looked up in
			chunks (chunkNumericList) rather than one IN-list, since this raw list can itself
			exceed Oracle's 1000-item IN-list cap. --->
		<cfset local.containsCollectionObjectIds = trim(arguments.contains_collection_object_ids)>
		<cfif len(local.containsCollectionObjectIds) GT 0>
			<cfset local.containsIdListFoundAsPart = "">
			<cfloop array="#chunkNumericList(local.containsCollectionObjectIds)#" index="local.oneIdChunk">
				<cfquery name="local.queryContainsIdListParts" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
					SELECT collection_object_id, derived_from_cat_item
					FROM specimen_part
					WHERE collection_object_id IN (<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#local.oneIdChunk#" list="true">)
				</cfquery>
				<cfloop query="local.queryContainsIdListParts">
					<cfset local.containsIdListFoundAsPart = listAppend(local.containsIdListFoundAsPart, local.queryContainsIdListParts.collection_object_id)>
					<cfif NOT listFind(local.containsCatalogedItemIds, local.queryContainsIdListParts.derived_from_cat_item)>
						<cfset local.containsCatalogedItemIds = listAppend(local.containsCatalogedItemIds, local.queryContainsIdListParts.derived_from_cat_item)>
					</cfif>
				</cfloop>
			</cfloop>
			<cfloop list="#local.containsCollectionObjectIds#" index="local.oneRawId">
				<cfif NOT listFind(local.containsIdListFoundAsPart, local.oneRawId) AND NOT listFind(local.containsCatalogedItemIds, local.oneRawId)>
					<cfset local.containsCatalogedItemIds = listAppend(local.containsCatalogedItemIds, local.oneRawId)>
				</cfif>
			</cfloop>
		</cfif>
		<!--- Chunked once here (not per usage site below) since containsCatalogedItemIds itself can
			exceed Oracle's 1000-item IN-list cap, most commonly via a large saved search result_id. --->
		<cfset local.containsCatalogedItemIdsChunks = chunkNumericList(local.containsCatalogedItemIds)>
		<!--- Transaction search: loan_number/deacc_number resolve directly against
			coll_obj_cont_hist via loan_item/deacc_item.collection_object_id (both relate to
			specimen parts, not cataloged items, so no derived_from_cat_item hop is needed, unlike
			the GUID/result_id/collection_object_id Contains paths above); accn_number resolves via
			trans_container (the only transaction<->container link table in the schema, populated
			only for accessions). transaction_id is the deep-link case -- each id is looked up by
			its own transaction_type and dispatched to whichever of the two resolution paths
			applies. All three contribute container_ids directly, not cataloged item ids, so this
			is its own filter, independent of containsCatalogedItemIds. Unlike the Contains filter
			above, this is NOT pre-resolved into a CF list here -- a loan/deaccession/search can
			easily span more than Oracle's 1000-item literal-IN-list cap, so each active filter
			contributes its own UNION'd branch directly inside a subquery at the two usage sites
			below (the count query and the paginated results query), never materializing an id
			list in ColdFusion. Only the plain filter-values themselves (loan_number, etc.) are
			resolved here, to drive which branches those subqueries include. --->
		<cfset local.loanNumberUpper = ucase(trim(arguments.loan_number))>
		<cfset local.accnNumberUpper = ucase(trim(arguments.accn_number))>
		<cfset local.deaccNumberUpper = ucase(trim(arguments.deacc_number))>
		<cfset local.transactionIdList = trim(arguments.transaction_id)>
		<!--- loan_number/deacc_number each independently support NULL ("no part currently on any
			loan/deaccession") and NOT NULL ("a part currently on some loan/deaccession"), mirroring
			position_filter's own NULL/NOT NULL/text convention above. These are existence checks
			unrelated to any specific number, so each is applied as its own standalone AND'd
			EXISTS/NOT EXISTS clause below rather than folded into the OR'd UNION text search uses --
			ANDing a NULL/NOT NULL check into that same OR'd union would produce results with no
			sensible meaning once combined with whichever other transaction filters are also active. --->
		<cfset local.loanNumberIsNull = (local.loanNumberUpper EQ "NULL")>
		<cfset local.loanNumberIsNotNull = (local.loanNumberUpper EQ "NOT NULL")>
		<cfset local.loanNumberIsText = (len(local.loanNumberUpper) GT 0 AND NOT local.loanNumberIsNull AND NOT local.loanNumberIsNotNull)>
		<cfset local.deaccNumberIsNull = (local.deaccNumberUpper EQ "NULL")>
		<cfset local.deaccNumberIsNotNull = (local.deaccNumberUpper EQ "NOT NULL")>
		<cfset local.deaccNumberIsText = (len(local.deaccNumberUpper) GT 0 AND NOT local.deaccNumberIsNull AND NOT local.deaccNumberIsNotNull)>
		<cfset local.transactionFilterGiven = (
			local.loanNumberIsText OR
			len(local.accnNumberUpper) GT 0 OR
			local.deaccNumberIsText OR
			len(local.transactionIdList) GT 0
		)>
		<!--- Determine whether tree_property requires a child-count JOIN in the COUNT query --->
		<cfset local.needsChildJoin = listFindNoCase("empty,misplaced,mixed", local.treeProperty) GT 0>
		<cfset local.needsParentJoin = (
			len(local.positionFilterUpper) GT 0 OR
			len(local.parentContainerType) GT 0 OR
			len(local.parentSearchUpper) GT 0 OR
			len(local.parentBarcodeUpper) GT 0 OR
			len(local.parentDescUpper) GT 0
		)>
		<!--- Total row count --->
		<cfquery name="queryGetCount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
			SELECT COUNT(*) AS total_rows
			FROM container c
			<cfif local.needsParentJoin>
				LEFT JOIN container p ON p.container_id = c.parent_container_id
				LEFT JOIN container parentcontainer ON parentcontainer.container_id = c.parent_container_id
			</cfif>
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
			<cfif len(local.containerType) GT 0>
				<cfif local.containerTypeIsList>
					AND c.container_type <cfif local.containerTypeNegated>NOT </cfif>IN (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#local.containerType#" list="true">)
				<cfelseif local.containerTypeNegated>
					AND c.container_type <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#local.containerType#">
				<cfelse>
					AND c.container_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#local.containerType#">
				</cfif>
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
			<cfif len(local.parentContainerType) GT 0>
				<cfif local.parentContainerTypeIsList>
					AND parentcontainer.container_type <cfif local.parentContainerTypeNegated>NOT </cfif>IN (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#local.parentContainerType#" list="true">)
				<cfelseif local.parentContainerTypeNegated>
					AND parentcontainer.container_type <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#local.parentContainerType#">
				<cfelse>
					AND parentcontainer.container_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#local.parentContainerType#">
				</cfif>
			</cfif>
			<cfif len(local.parentSearchUpper) GT 0>
				<cfif left(local.parentSearchUpper,1) EQ "=">
					AND (
						UPPER(parentcontainer.label) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#RemoveChars(local.parentSearchUpper, 1, 1)#">
						OR UPPER(parentcontainer.barcode) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#RemoveChars(local.parentSearchUpper, 1, 1)#">
					)
				<cfelse>
					AND (
						UPPER(parentcontainer.label) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#local.parentSearchUpper#%">
						OR UPPER(parentcontainer.barcode) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#local.parentSearchUpper#%">
					)
				</cfif>
			</cfif>
			<cfif len(local.parentBarcodeUpper) GT 0>
				<cfif left(local.parentBarcodeUpper,1) EQ "=">
					AND UPPER(parentcontainer.barcode) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#RemoveChars(local.parentBarcodeUpper, 1, 1)#">
				<cfelse>
					AND UPPER(parentcontainer.barcode) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#local.parentBarcodeUpper#%">
				</cfif>
			</cfif>
			<cfif len(local.parentDescUpper) GT 0>
				AND (
					UPPER(parentcontainer.description) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#local.parentDescUpper#%">
					OR UPPER(parentcontainer.container_remarks) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#local.parentDescUpper#%">
				)
			</cfif>
			<cfif local.hasPositionsFilter EQ "none">
				AND NVL(c.number_positions, 0) = 0
			<cfelseif local.hasPositionsFilter EQ "any">
				AND NVL(c.number_positions, 0) > 0
			<cfelseif local.hasPositionsFilter EQ "has_empty">
				AND NVL(c.number_positions, 0) > 0
				AND EXISTS (
					SELECT 1
					FROM container pos
					WHERE pos.parent_container_id = c.container_id
						AND pos.container_type = 'position'
						AND NOT EXISTS (
							SELECT 1
							FROM container occ
							WHERE occ.parent_container_id = pos.container_id
						)
				)
			<cfelseif isNumeric(local.hasPositionsFilter)>
				AND c.number_positions = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#local.hasPositionsFilter#">
			</cfif>
			<cfif len(local.positionFilterUpper) GT 0>
				<cfif local.positionFilterUpper EQ "NOT NULL">
					AND p.container_type = 'position'
				<cfelseif local.positionFilterUpper EQ "NULL">
					AND NVL(p.container_type, ' ') <> 'position'
				<cfelse>
					AND p.container_type = 'position'
					<cfif isNumeric(local.positionFilter)>
						AND (
							p.label = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#local.positionFilter#">
							OR p.barcode = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#local.positionFilter#">
						)
					<cfelseif left(local.positionFilterUpper,1) EQ "=">
						AND (
							UPPER(p.label) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#RemoveChars(local.positionFilterUpper, 1, 1)#">
							OR UPPER(p.barcode) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#RemoveChars(local.positionFilterUpper, 1, 1)#">
						)
					<cfelse>
						AND (
							UPPER(p.label) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#local.positionFilterUpper#%">
							OR UPPER(p.barcode) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#local.positionFilterUpper#%">
						)
					</cfif>
				</cfif>
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
			<!--- Contains: restrict to containers that are the *current* container of some part
				derived from a given cataloged item (by GUID list, or by a saved search's result_id --
				both are resolved above into the same containsCatalogedItemIds list, since a GUID always
				names a cataloged item and a saved search's rows may be either parts or cataloged items,
				resolved the same way -- part's own id falls back to its derived_from_cat_item, a
				cataloged item's own id is used as-is). Chunked (containsCatalogedItemIdsChunks) and
				OR'd rather than a single IN-list, since this list can exceed Oracle's 1000-item cap. --->
			<cfif len(local.containsCatalogedItemIds) GT 0>
				AND c.container_id IN (
					SELECT coch.container_id
					FROM coll_obj_cont_hist coch
						JOIN specimen_part sp ON sp.collection_object_id = coch.collection_object_id
					WHERE coch.current_container_fg = 1
						AND (
							<cfloop from="1" to="#arrayLen(local.containsCatalogedItemIdsChunks)#" index="local.containsChunkIdx">
								<cfif local.containsChunkIdx GT 1>OR</cfif>
								sp.derived_from_cat_item IN (<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#local.containsCatalogedItemIdsChunks[local.containsChunkIdx]#" list="true">)
							</cfloop>
						)
				)
			<cfelseif len(trim(arguments.contains_guids)) GT 0 OR len(local.containsResultId) GT 0 OR len(local.containsCollectionObjectIds) GT 0>
				<!--- Contains was given but nothing resolved -- force zero results rather than
					silently ignoring the filter and returning an unfiltered search. --->
				AND 1=0
			</cfif>
			<!--- Transaction search: loan/accession/deaccession number or transaction_id -- each
				active filter contributes its own UNION'd branch inside this subquery (never a
				materialized id list, since a loan/deaccession/search can span more than Oracle's
				1000-item literal-IN-list cap); an empty/no-match subquery naturally excludes
				everything on its own, so no separate "resolved to nothing" 1=0 fallback is needed
				here the way the Contains filter above still requires one. --->
			<cfif local.transactionFilterGiven>
				AND c.container_id IN (
					<cfset local.transactionUnionStarted = false>
					<cfif local.loanNumberIsText>
						SELECT DISTINCT coch.container_id
						FROM loan l
							JOIN loan_item li ON li.transaction_id = l.transaction_id
							JOIN coll_obj_cont_hist coch ON coch.collection_object_id = li.collection_object_id
						WHERE coch.current_container_fg = 1
							<cfif left(local.loanNumberUpper,1) EQ "=">
								AND UPPER(l.loan_number) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#RemoveChars(local.loanNumberUpper,1,1)#">
							<cfelse>
								AND UPPER(l.loan_number) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#local.loanNumberUpper#%">
							</cfif>
						<cfset local.transactionUnionStarted = true>
					</cfif>
					<cfif local.deaccNumberIsText>
						<cfif local.transactionUnionStarted>UNION</cfif>
						SELECT DISTINCT coch.container_id
						FROM deaccession d
							JOIN deacc_item di ON di.transaction_id = d.transaction_id
							JOIN coll_obj_cont_hist coch ON coch.collection_object_id = di.collection_object_id
						WHERE coch.current_container_fg = 1
							<cfif left(local.deaccNumberUpper,1) EQ "=">
								AND UPPER(d.deacc_number) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#RemoveChars(local.deaccNumberUpper,1,1)#">
							<cfelse>
								AND UPPER(d.deacc_number) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#local.deaccNumberUpper#%">
							</cfif>
						<cfset local.transactionUnionStarted = true>
					</cfif>
					<cfif len(local.accnNumberUpper) GT 0>
						<cfif local.transactionUnionStarted>UNION</cfif>
						SELECT DISTINCT tc.container_id
						FROM accn a
							JOIN trans_container tc ON tc.transaction_id = a.transaction_id
						WHERE
							<cfif left(local.accnNumberUpper,1) EQ "=">
								UPPER(a.accn_number) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#RemoveChars(local.accnNumberUpper,1,1)#">
							<cfelse>
								UPPER(a.accn_number) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#local.accnNumberUpper#%">
							</cfif>
						UNION
						SELECT DISTINCT coch.container_id
						FROM accn a
							JOIN cataloged_item ci ON ci.accn_id = a.transaction_id
							JOIN specimen_part sp ON sp.derived_from_cat_item = ci.collection_object_id
							JOIN coll_obj_cont_hist coch ON coch.collection_object_id = sp.collection_object_id
						WHERE coch.current_container_fg = 1
							AND <cfif left(local.accnNumberUpper,1) EQ "=">
								UPPER(a.accn_number) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#RemoveChars(local.accnNumberUpper,1,1)#">
							<cfelse>
								UPPER(a.accn_number) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#local.accnNumberUpper#%">
							</cfif>
						<cfset local.transactionUnionStarted = true>
					</cfif>
					<cfif len(local.transactionIdList) GT 0>
						<cfif local.transactionUnionStarted>UNION</cfif>
						SELECT DISTINCT container_id
						FROM trans_container
						WHERE transaction_id IN (
							SELECT transaction_id FROM trans
							WHERE transaction_type = 'accn'
								AND transaction_id IN (<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#local.transactionIdList#" list="true">)
						)
						UNION
						SELECT DISTINCT coch.container_id
						FROM cataloged_item ci
							JOIN specimen_part sp ON sp.derived_from_cat_item = ci.collection_object_id
							JOIN coll_obj_cont_hist coch ON coch.collection_object_id = sp.collection_object_id
						WHERE coch.current_container_fg = 1
							AND ci.accn_id IN (
								SELECT transaction_id FROM trans
								WHERE transaction_type = 'accn'
									AND transaction_id IN (<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#local.transactionIdList#" list="true">)
							)
						UNION
						SELECT DISTINCT coch.container_id
						FROM coll_obj_cont_hist coch
						WHERE coch.current_container_fg = 1
							AND coch.collection_object_id IN (
								SELECT collection_object_id FROM loan_item
								WHERE transaction_id IN (
									SELECT transaction_id FROM trans
									WHERE transaction_type IN ('loan','deaccession')
										AND transaction_id IN (<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#local.transactionIdList#" list="true">)
								)
								UNION
								SELECT collection_object_id FROM deacc_item
								WHERE transaction_id IN (
									SELECT transaction_id FROM trans
									WHERE transaction_type IN ('loan','deaccession')
										AND transaction_id IN (<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#local.transactionIdList#" list="true">)
								)
							)
					</cfif>
				)
			</cfif>
			<!--- loan_number/deacc_number NULL/NOT NULL: existence checks against the container's
				own current parts, independent of the OR'd text-search union above. --->
			<cfif local.loanNumberIsNotNull>
				AND EXISTS (
					SELECT 1
					FROM loan_item li
						JOIN coll_obj_cont_hist coch ON coch.collection_object_id = li.collection_object_id
					WHERE coch.current_container_fg = 1
						AND coch.container_id = c.container_id
				)
			<cfelseif local.loanNumberIsNull>
				AND NOT EXISTS (
					SELECT 1
					FROM loan_item li
						JOIN coll_obj_cont_hist coch ON coch.collection_object_id = li.collection_object_id
					WHERE coch.current_container_fg = 1
						AND coch.container_id = c.container_id
				)
			</cfif>
			<cfif local.deaccNumberIsNotNull>
				AND EXISTS (
					SELECT 1
					FROM deacc_item di
						JOIN coll_obj_cont_hist coch ON coch.collection_object_id = di.collection_object_id
					WHERE coch.current_container_fg = 1
						AND coch.container_id = c.container_id
				)
			<cfelseif local.deaccNumberIsNull>
				AND NOT EXISTS (
					SELECT 1
					FROM deacc_item di
						JOIN coll_obj_cont_hist coch ON coch.collection_object_id = di.collection_object_id
					WHERE coch.current_container_fg = 1
						AND coch.container_id = c.container_id
				)
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
					LEFT JOIN container parentcontainer ON parentcontainer.container_id = c.parent_container_id
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
					<cfif len(local.containerType) GT 0>
						<cfif local.containerTypeIsList>
							AND c.container_type <cfif local.containerTypeNegated>NOT </cfif>IN (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#local.containerType#" list="true">)
						<cfelseif local.containerTypeNegated>
							AND c.container_type <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#local.containerType#">
						<cfelse>
							AND c.container_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#local.containerType#">
						</cfif>
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
					<cfif len(local.parentContainerType) GT 0>
						<cfif local.parentContainerTypeIsList>
							AND parentcontainer.container_type <cfif local.parentContainerTypeNegated>NOT </cfif>IN (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#local.parentContainerType#" list="true">)
						<cfelseif local.parentContainerTypeNegated>
							AND parentcontainer.container_type <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#local.parentContainerType#">
						<cfelse>
							AND parentcontainer.container_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#local.parentContainerType#">
						</cfif>
					</cfif>
					<cfif len(local.parentSearchUpper) GT 0>
						<cfif left(local.parentSearchUpper,1) EQ "=">
							AND (
								UPPER(parentcontainer.label) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#RemoveChars(local.parentSearchUpper, 1, 1)#">
								OR UPPER(parentcontainer.barcode) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#RemoveChars(local.parentSearchUpper, 1, 1)#">
							)
						<cfelse>
							AND (
								UPPER(parentcontainer.label) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#local.parentSearchUpper#%">
								OR UPPER(parentcontainer.barcode) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#local.parentSearchUpper#%">
							)
						</cfif>
					</cfif>
					<cfif len(local.parentBarcodeUpper) GT 0>
						<cfif left(local.parentBarcodeUpper,1) EQ "=">
							AND UPPER(parentcontainer.barcode) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#RemoveChars(local.parentBarcodeUpper, 1, 1)#">
						<cfelse>
							AND UPPER(parentcontainer.barcode) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#local.parentBarcodeUpper#%">
						</cfif>
					</cfif>
					<cfif len(local.parentDescUpper) GT 0>
						AND (
							UPPER(parentcontainer.description) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#local.parentDescUpper#%">
							OR UPPER(parentcontainer.container_remarks) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#local.parentDescUpper#%">
						)
					</cfif>
					<cfif local.hasPositionsFilter EQ "none">
						AND NVL(c.number_positions, 0) = 0
					<cfelseif local.hasPositionsFilter EQ "any">
						AND NVL(c.number_positions, 0) > 0
					<cfelseif local.hasPositionsFilter EQ "has_empty">
						AND NVL(c.number_positions, 0) > 0
						AND EXISTS (
							SELECT 1
							FROM container pos
							WHERE pos.parent_container_id = c.container_id
								AND pos.container_type = 'position'
								AND NOT EXISTS (
									SELECT 1
									FROM container occ
									WHERE occ.parent_container_id = pos.container_id
								)
						)
					<cfelseif isNumeric(local.hasPositionsFilter)>
						AND c.number_positions = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#local.hasPositionsFilter#">
					</cfif>
					<cfif len(local.positionFilterUpper) GT 0>
						<cfif local.positionFilterUpper EQ "NOT NULL">
							AND p.container_type = 'position'
						<cfelseif local.positionFilterUpper EQ "NULL">
							AND NVL(p.container_type, ' ') <> 'position'
						<cfelse>
							AND p.container_type = 'position'
							<cfif isNumeric(local.positionFilter)>
								AND (
									p.label = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#local.positionFilter#">
									OR p.barcode = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#local.positionFilter#">
								)
							<cfelseif left(local.positionFilterUpper,1) EQ "=">
								AND (
									UPPER(p.label) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#RemoveChars(local.positionFilterUpper, 1, 1)#">
									OR UPPER(p.barcode) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#RemoveChars(local.positionFilterUpper, 1, 1)#">
								)
							<cfelse>
								AND (
									UPPER(p.label) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#local.positionFilterUpper#%">
									OR UPPER(p.barcode) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#local.positionFilterUpper#%">
								)
							</cfif>
						</cfif>
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
					<cfif len(local.containsCatalogedItemIds) GT 0>
						AND c.container_id IN (
							SELECT coch.container_id
							FROM coll_obj_cont_hist coch
								JOIN specimen_part sp ON sp.collection_object_id = coch.collection_object_id
							WHERE coch.current_container_fg = 1
								AND (
									<cfloop from="1" to="#arrayLen(local.containsCatalogedItemIdsChunks)#" index="local.containsChunkIdx">
										<cfif local.containsChunkIdx GT 1>OR</cfif>
										sp.derived_from_cat_item IN (<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#local.containsCatalogedItemIdsChunks[local.containsChunkIdx]#" list="true">)
									</cfloop>
								)
						)
					<cfelseif len(trim(arguments.contains_guids)) GT 0 OR len(local.containsResultId) GT 0 OR len(local.containsCollectionObjectIds) GT 0>
						AND 1=0
					</cfif>
					<!--- Transaction search: loan/accession/deaccession number or transaction_id -- each
						active filter contributes its own UNION'd branch inside this subquery (never a
						materialized id list, since a loan/deaccession/search can span more than Oracle's
						1000-item literal-IN-list cap); an empty/no-match subquery naturally excludes
						everything on its own, so no separate "resolved to nothing" 1=0 fallback is needed
						here the way the Contains filter above still requires one. --->
					<cfif local.transactionFilterGiven>
						AND c.container_id IN (
							<cfset local.transactionUnionStarted = false>
							<cfif local.loanNumberIsText>
								SELECT DISTINCT coch.container_id
								FROM loan l
									JOIN loan_item li ON li.transaction_id = l.transaction_id
									JOIN coll_obj_cont_hist coch ON coch.collection_object_id = li.collection_object_id
								WHERE coch.current_container_fg = 1
									<cfif left(local.loanNumberUpper,1) EQ "=">
										AND UPPER(l.loan_number) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#RemoveChars(local.loanNumberUpper,1,1)#">
									<cfelse>
										AND UPPER(l.loan_number) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#local.loanNumberUpper#%">
									</cfif>
								<cfset local.transactionUnionStarted = true>
							</cfif>
							<cfif local.deaccNumberIsText>
								<cfif local.transactionUnionStarted>UNION</cfif>
								SELECT DISTINCT coch.container_id
								FROM deaccession d
									JOIN deacc_item di ON di.transaction_id = d.transaction_id
									JOIN coll_obj_cont_hist coch ON coch.collection_object_id = di.collection_object_id
								WHERE coch.current_container_fg = 1
									<cfif left(local.deaccNumberUpper,1) EQ "=">
										AND UPPER(d.deacc_number) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#RemoveChars(local.deaccNumberUpper,1,1)#">
									<cfelse>
										AND UPPER(d.deacc_number) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#local.deaccNumberUpper#%">
									</cfif>
								<cfset local.transactionUnionStarted = true>
							</cfif>
							<cfif len(local.accnNumberUpper) GT 0>
								<cfif local.transactionUnionStarted>UNION</cfif>
								SELECT DISTINCT tc.container_id
								FROM accn a
									JOIN trans_container tc ON tc.transaction_id = a.transaction_id
								WHERE
									<cfif left(local.accnNumberUpper,1) EQ "=">
										UPPER(a.accn_number) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#RemoveChars(local.accnNumberUpper,1,1)#">
									<cfelse>
										UPPER(a.accn_number) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#local.accnNumberUpper#%">
									</cfif>
								UNION
								SELECT DISTINCT coch.container_id
								FROM accn a
									JOIN cataloged_item ci ON ci.accn_id = a.transaction_id
									JOIN specimen_part sp ON sp.derived_from_cat_item = ci.collection_object_id
									JOIN coll_obj_cont_hist coch ON coch.collection_object_id = sp.collection_object_id
								WHERE coch.current_container_fg = 1
									AND <cfif left(local.accnNumberUpper,1) EQ "=">
										UPPER(a.accn_number) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#RemoveChars(local.accnNumberUpper,1,1)#">
									<cfelse>
										UPPER(a.accn_number) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#local.accnNumberUpper#%">
									</cfif>
								<cfset local.transactionUnionStarted = true>
							</cfif>
							<cfif len(local.transactionIdList) GT 0>
								<cfif local.transactionUnionStarted>UNION</cfif>
								SELECT DISTINCT container_id
								FROM trans_container
								WHERE transaction_id IN (
									SELECT transaction_id FROM trans
									WHERE transaction_type = 'accn'
										AND transaction_id IN (<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#local.transactionIdList#" list="true">)
								)
								UNION
								SELECT DISTINCT coch.container_id
								FROM cataloged_item ci
									JOIN specimen_part sp ON sp.derived_from_cat_item = ci.collection_object_id
									JOIN coll_obj_cont_hist coch ON coch.collection_object_id = sp.collection_object_id
								WHERE coch.current_container_fg = 1
									AND ci.accn_id IN (
										SELECT transaction_id FROM trans
										WHERE transaction_type = 'accn'
											AND transaction_id IN (<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#local.transactionIdList#" list="true">)
									)
								UNION
								SELECT DISTINCT coch.container_id
								FROM coll_obj_cont_hist coch
								WHERE coch.current_container_fg = 1
									AND coch.collection_object_id IN (
										SELECT collection_object_id FROM loan_item
										WHERE transaction_id IN (
											SELECT transaction_id FROM trans
											WHERE transaction_type IN ('loan','deaccession')
												AND transaction_id IN (<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#local.transactionIdList#" list="true">)
										)
										UNION
										SELECT collection_object_id FROM deacc_item
										WHERE transaction_id IN (
											SELECT transaction_id FROM trans
											WHERE transaction_type IN ('loan','deaccession')
												AND transaction_id IN (<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#local.transactionIdList#" list="true">)
										)
									)
							</cfif>
						)
					</cfif>
					<!--- loan_number/deacc_number NULL/NOT NULL: existence checks against the container's
						own current parts, independent of the OR'd text-search union above. --->
					<cfif local.loanNumberIsNotNull>
						AND EXISTS (
							SELECT 1
							FROM loan_item li
								JOIN coll_obj_cont_hist coch ON coch.collection_object_id = li.collection_object_id
							WHERE coch.current_container_fg = 1
								AND coch.container_id = c.container_id
						)
					<cfelseif local.loanNumberIsNull>
						AND NOT EXISTS (
							SELECT 1
							FROM loan_item li
								JOIN coll_obj_cont_hist coch ON coch.collection_object_id = li.collection_object_id
							WHERE coch.current_container_fg = 1
								AND coch.container_id = c.container_id
						)
					</cfif>
					<cfif local.deaccNumberIsNotNull>
						AND EXISTS (
							SELECT 1
							FROM deacc_item di
								JOIN coll_obj_cont_hist coch ON coch.collection_object_id = di.collection_object_id
							WHERE coch.current_container_fg = 1
								AND coch.container_id = c.container_id
						)
					<cfelseif local.deaccNumberIsNull>
						AND NOT EXISTS (
							SELECT 1
							FROM deacc_item di
								JOIN coll_obj_cont_hist coch ON coch.collection_object_id = di.collection_object_id
							WHERE coch.current_container_fg = 1
								AND coch.container_id = c.container_id
						)
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
@return a JSON array of ctcontainer_type metadata objects with keys: container_type, role,
	expects_leaf_child_count, expected_parent_types, force_expected_parent_type, rank_order,
	variable_rank, description.
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
Function pickContainerDialogHtml. Returns the shared rich picker dialog HTML fragment.
@param dialog_mode picker mode: parent, child, or find.
@param child_container_id optional child container_id used to preselect expected parent type in parent mode.
@param preselect_type optional container_type value to preselect in the type control.
@param pick_leaves when true, preselect collection object as the child container type.
@param ancestor_container_id optional ancestor container_id to constrain subtree search.
@param institution_acronym optional institution acronym to constrain dialog searches.
@param id_suffix optional suffix applied to generated control ids for uniqueness.
@return HTML fragment string for context-aware container picker dialog controls.
--->
<cffunction name="pickContainerDialogHtml" access="remote" returntype="string" returnformat="plain" output="false">
	<cfargument name="dialog_mode" type="string" required="no" default="parent">
	<cfargument name="child_container_id" type="string" required="no" default="">
	<cfargument name="preselect_type" type="string" required="no" default="">
	<cfargument name="pick_leaves" type="string" required="no" default="0">
	<cfargument name="ancestor_container_id" type="string" required="no" default="">
	<cfargument name="institution_acronym" type="string" required="no" default="">
	<cfargument name="id_suffix" type="string" required="no" default="">

	<cfset local.safeSuffix = REReplace(arguments.id_suffix, "[^A-Za-z0-9_-]", "", "all")>
	<cfset local.typeControlId = "pickContainerType#local.safeSuffix#">
	<cfset local.ancestorControlId = "pickContainerAncestor#local.safeSuffix#">
	<cfset local.ancestorIdControlId = "pickContainerAncestorId#local.safeSuffix#">
	<cfset local.searchControlId = "pickContainerSearch#local.safeSuffix#">
	<cfset local.searchIdControlId = "pickContainerSearchId#local.safeSuffix#">
	<cfset local.labelContainsControlId = "pickContainerLabelContains#local.safeSuffix#">
	<cfset local.descriptionContainsControlId = "pickContainerDescriptionContains#local.safeSuffix#">
	<cfset local.validationControlId = "pickContainerValidation#local.safeSuffix#">
	<cfset local.confirmControlId = "pickContainerConfirm#local.safeSuffix#">
	<cfset local.cancelControlId = "pickContainerCancel#local.safeSuffix#">
	<cfset local.searchOpenControlId = "pickContainerSearchOpen#local.safeSuffix#">
	<cfset local.statusControlId = "pickContainerStatus#local.safeSuffix#">
	<cfset local.selectedType = trim(arguments.preselect_type)>
	<cfset local.pickLeaves = listFindNoCase("1,true,yes,on", trim(arguments.pick_leaves)) GT 0>
	<cfset local.dialogMode = lCase(trim(arguments.dialog_mode))>
	<cfif NOT listFindNoCase("parent,child,find", local.dialogMode)>
		<cfset local.dialogMode = "find">
	</cfif>
	<cfset local.filterLegend = "Filter containers">
	<cfset local.selectLegend = "Select container">
	<cfif local.dialogMode EQ "parent">
		<cfset local.filterLegend = "Filter parent candidates">
		<cfset local.selectLegend = "Select parent container">
	<cfelseif local.dialogMode EQ "child">
		<cfset local.filterLegend = "Filter child candidates">
		<cfset local.selectLegend = "Select child container">
	</cfif>

	<cfquery name="queryAllowedTypes" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
		SELECT
			container_type,
			rank_order
		FROM
			ctcontainer_type
		<cfif local.dialogMode EQ "parent">
			WHERE
				role IN ('structural', 'leafbearer')
		</cfif>
		ORDER BY
			rank_order,
			container_type
	</cfquery>

	<cfif local.dialogMode EQ "parent" AND len(trim(arguments.child_container_id)) GT 0 AND isNumeric(arguments.child_container_id)>
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
	<cfif local.dialogMode EQ "child" AND local.pickLeaves AND len(trim(local.selectedType)) EQ 0>
		<cfset local.selectedType = "collection object">
	</cfif>

	<cfsavecontent variable="local.htmlFragment"><cfoutput>
		<fieldset class="border rounded bg-light p-2 mb-2">
			<legend class="small font-weight-bold text-uppercase w-auto px-1 mb-1">#encodeForHtml(local.filterLegend)#</legend>
			<div class="form-row mb-2">
				<div class="col-12 col-md-6 mb-1">
					<label for="#encodeForHtml(local.typeControlId)#" class="data-entry-label">Container Type</label>
					<select id="#encodeForHtml(local.typeControlId)#" class="data-entry-select col-12 pick-container-filter-control">
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
					<label for="#encodeForHtml(local.ancestorControlId)#" class="data-entry-label">Limit to subtree</label>
					<input type="text" id="#encodeForHtml(local.ancestorControlId)#" class="data-entry-input col-12 pick-container-filter-control" value="">
					<input type="hidden" id="#encodeForHtml(local.ancestorIdControlId)#" value="#encodeForHtml(arguments.ancestor_container_id)#">
				</div>
			</div>
			<div class="form-row">
				<div class="col-12 col-md-6 mb-1">
					<label for="#encodeForHtml(local.labelContainsControlId)#" class="data-entry-label">Label contains</label>
					<input type="text" id="#encodeForHtml(local.labelContainsControlId)#" class="data-entry-input col-12 pick-container-filter-control" value="">
				</div>
				<div class="col-12 col-md-6 mb-1">
					<label for="#encodeForHtml(local.descriptionContainsControlId)#" class="data-entry-label">Description contains</label>
					<input type="text" id="#encodeForHtml(local.descriptionContainsControlId)#" class="data-entry-input col-12 pick-container-filter-control" value="">
				</div>
			</div>
		</fieldset>
		<fieldset class="border rounded p-2 mb-2">
			<legend class="small font-weight-bold text-uppercase w-auto px-1 mb-1">#encodeForHtml(local.selectLegend)#</legend>
			<div class="form-row">
				<div class="col-12 mb-1">
					<label for="#encodeForHtml(local.searchControlId)#" class="data-entry-label mb-0">Container autocomplete
						<a href="javascript:void(0)" role="button" id="#encodeForHtml(local.searchOpenControlId)#" class="btn-link disabled ml-1" aria-disabled="true" tabindex="-1">&##8595;<span class="sr-only"> Open filtered autocomplete suggestions</span></a>
					</label>
					<input type="text" id="#encodeForHtml(local.searchControlId)#" class="data-entry-input col-12 reqdClr" value="">
					<input type="hidden" id="#encodeForHtml(local.searchIdControlId)#" value="">
				</div>
			</div>
		</fieldset>
		<div class="form-row mb-2">
			<div class="col-12">
				<div class="small text-muted">Pick from the autocomplete list above after setting any filters.</div>
			</div>
		</div>
		<div class="form-row mb-2">
			<div class="col-12">
				<cfif len(trim(arguments.institution_acronym)) GT 0>
					<div class="small text-muted mb-2">Search limited to institution: #encodeForHtml(arguments.institution_acronym)#</div>
				</cfif>
			</div>
		</div>
		<div id="#encodeForHtml(local.validationControlId)#" role="status" aria-live="polite" class="mb-2"></div>
		<div class="form-row">
			<div class="col-12">
				<button type="button" id="#encodeForHtml(local.confirmControlId)#" class="btn btn-xs btn-outline-secondary pick-container-select-btn" disabled="disabled">Select</button>
				<button type="button" id="#encodeForHtml(local.cancelControlId)#" class="btn btn-xs btn-warning ml-1">Cancel</button>
				<output id="#encodeForHtml(local.statusControlId)#" class="ml-2"></output>
			</div>
		</div>
	</cfoutput></cfsavecontent>

	<cfreturn local.htmlFragment>
</cffunction>

</cfcomponent>
