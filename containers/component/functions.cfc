<!---
containers/component/functions.cfc
Functions supporting the use of containers.

Copyright 2026 President and Fellows of Harvard College

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

<!---
Function getDirectStructuralChildren.  Returns the direct structural (non-collection-object)
children of the given container, suitable for rendering a tree node.

@param container_id the container_id whose direct structural children are to be returned.
@return a JSON array of objects with keys: container_id, parent_container_id, container_type, label, barcode, description.
--->
<cffunction name="getDirectStructuralChildren" access="remote" returntype="any" returnformat="json">
	<cfargument name="container_id" type="numeric" required="yes">

	<cfset local.retval = ArrayNew(1)>
	<cftry>
		<cfquery name="qChildren" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
			SELECT
				c.container_id,
				c.parent_container_id,
				c.container_type,
				c.label,
				c.barcode,
				c.description,
				NVL(ch.direct_structural_children, 0) AS direct_structural_children,
				NVL(ch.direct_leaf_children, 0) AS direct_leaf_children,
				sc.single_child_barcode,
				sc.single_child_label,
				CASE WHEN NVL(ch.direct_structural_children, 0) > 0 OR NVL(ch.direct_leaf_children, 0) > 0 THEN 1 ELSE 0 END AS has_leaf_descendants
			FROM
				container c
				LEFT JOIN (
					SELECT
						parent_container_id,
						SUM(CASE WHEN container_type <> 'collection object' THEN 1 ELSE 0 END) AS direct_structural_children,
						SUM(CASE WHEN container_type = 'collection object' THEN 1 ELSE 0 END) AS direct_leaf_children
					FROM container
					GROUP BY parent_container_id
				) ch ON ch.parent_container_id = c.container_id
				LEFT JOIN (
					SELECT parent_container_id, barcode AS single_child_barcode, label AS single_child_label
					FROM (
						SELECT
							parent_container_id,
							barcode,
							label,
							ROW_NUMBER() OVER (PARTITION BY parent_container_id ORDER BY label) AS rn
						FROM container
						WHERE container_type = 'collection object'
							AND parent_container_id IN (
								SELECT container_id
								FROM container
								WHERE parent_container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.container_id#">
									AND container_type <> 'collection object'
							)
					)
					WHERE rn = 1
				) sc ON sc.parent_container_id = c.container_id
			WHERE
				c.parent_container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.container_id#">
				AND c.container_type <> 'collection object'
			ORDER BY
				CASE WHEN NVL(ch.direct_structural_children, 0) > 0 THEN 0 ELSE 1 END,
				c.container_type,
				c.label
		</cfquery>
		<cfset local.i = 1>
		<cfloop query="qChildren">
			<cfset local.row = StructNew()>
			<cfset local.row["container_id"] = qChildren.container_id>
			<cfset local.row["parent_container_id"] = qChildren.parent_container_id>
			<cfset local.row["container_type"] = qChildren.container_type>
			<cfset local.row["label"] = qChildren.label>
			<cfset local.row["barcode"] = qChildren.barcode>
			<cfset local.row["description"] = qChildren.description>
			<cfset local.row["direct_structural_children"] = qChildren.direct_structural_children>
			<cfset local.row["direct_leaf_children"] = qChildren.direct_leaf_children>
			<cfset local.row["single_child_barcode"] = qChildren.single_child_barcode>
			<cfset local.row["single_child_label"] = qChildren.single_child_label>
			<cfset local.row["has_leaf_descendants"] = qChildren.has_leaf_descendants>
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
Function getDirectLeafChildren.  Returns a paginated list of direct collection-object children
of the given container, for use in the leaf browser panel.

@param container_id the container_id whose direct leaf (collection object) children are returned.
@param page the page number to return (1-based), defaults to 1.
@param pageSize the number of rows per page, defaults to 50.
@return a JSON object with keys: rows (array), page, pageSize, totalRows.
  Each row object contains: container_id, label, barcode, description,
  cat_num, collection_cde, institution_acronym, part_name, scientific_name.
  The specimen fields are NULL when the collection object container has no linked specimen.
--->
<cffunction name="getDirectLeafChildren" access="remote" returntype="any" returnformat="json">
	<cfargument name="container_id" type="numeric" required="yes">
	<cfargument name="page" type="numeric" required="no" default="1">
	<cfargument name="pageSize" type="numeric" required="no" default="50">

	<cfset local.retval = StructNew()>
	<cftry>
		<cfset local.offset = (arguments.page - 1) * arguments.pageSize>
		<!--- Total row count --->
		<cfquery name="queryGetCount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
			SELECT COUNT(*) AS total_rows
			FROM container
			WHERE
				parent_container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.container_id#">
				AND container_type = 'collection object'
		</cfquery>
		<cfset local.totalRows = queryGetCount.total_rows>
				<!--- Paginated rows with specimen info via LEFT JOIN.
		      The spec subquery uses GROUP BY on container_id to guarantee one row per container
		      even if coll_obj_cont_hist has anomalous duplicate current entries. --->
		<cfquery name="queryGetLeaf" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
			SELECT container_id, label, barcode, description,
				cat_num, collection_cde, institution_acronym, part_name, scientific_name
			FROM (
				SELECT
					container_id,
					label,
					barcode,
					description,
					cat_num,
					collection_cde,
					institution_acronym,
					part_name,
					scientific_name,
					ROWNUM AS rn
				FROM (
					SELECT
						c.container_id,
						c.label,
						c.barcode,
						c.description,
						spec.cat_num,
						spec.collection_cde,
						spec.institution_acronym,
						spec.part_name,
						spec.scientific_name
					FROM container c
					LEFT JOIN (
						SELECT
							coch.container_id,
							MAX(ci.cat_num) AS cat_num,
							MAX(ci.collection_cde) AS collection_cde,
							MAX(col.institution_acronym) AS institution_acronym,
							MAX(sp.part_name) AS part_name,
							MAX(id_sub.scientific_name) AS scientific_name
						FROM coll_obj_cont_hist coch
						LEFT JOIN specimen_part sp ON sp.collection_object_id = coch.collection_object_id
						LEFT JOIN cataloged_item ci ON ci.collection_object_id = sp.derived_from_cat_item
						LEFT JOIN collection col ON col.collection_id = ci.collection_id
						LEFT JOIN (
							SELECT collection_object_id, MIN(scientific_name) AS scientific_name
							FROM identification
							WHERE accepted_id_fg = 1
							GROUP BY collection_object_id
						) id_sub ON id_sub.collection_object_id = ci.collection_object_id
						WHERE coch.current_container_fg = 1
						GROUP BY coch.container_id
					) spec ON spec.container_id = c.container_id
					WHERE c.parent_container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.container_id#">
						AND c.container_type = 'collection object'
					ORDER BY c.label
				)
				WHERE ROWNUM <= <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#local.offset + arguments.pageSize#">
			)
			WHERE rn > <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#local.offset#">
		</cfquery>
		<cfset local.rows = ArrayNew(1)>
		<cfset local.i = 1>
		<cfloop query="queryGetLeaf">
			<cfset local.row = StructNew()>
			<cfset local.row["container_id"] = queryGetLeaf.container_id>
			<cfset local.row["label"] = queryGetLeaf.label>
			<cfset local.row["barcode"] = queryGetLeaf.barcode>
			<cfset local.row["description"] = queryGetLeaf.description>
			<cfset local.row["cat_num"] = queryGetLeaf.cat_num>
			<cfset local.row["collection_cde"] = queryGetLeaf.collection_cde>
			<cfset local.row["institution_acronym"] = queryGetLeaf.institution_acronym>
			<cfset local.row["part_name"] = queryGetLeaf.part_name>
			<cfset local.row["scientific_name"] = queryGetLeaf.scientific_name>
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
Function getNodeShape.  Returns the shape classification for a single container node: A, B, AB, or leaf.
Shape logic mirrors getContainerShapeHotspots in search.cfc:
  leaf - container_type is 'collection object'
  B    - direct_leaf_children >= 1000 AND direct_structural_children = 0
  AB   - direct_leaf_children > 0 AND direct_structural_children > 0
  A    - all other cases (structural only, or fewer than 1000 leaf-only)

@param container_id the container_id to classify.
@return a JSON object with keys: container_id, shape, direct_children, direct_leaf_children, direct_structural_children.
--->
<cffunction name="getNodeShape" access="remote" returntype="any" returnformat="json">
	<cfargument name="container_id" type="numeric" required="yes">

	<cfset local.retval = StructNew()>
	<cftry>
		<cfquery name="queryGetNode" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
			SELECT
				c.container_id,
				c.container_type,
				NVL(ch.direct_children, 0) AS direct_children,
				NVL(ch.direct_leaf_children, 0) AS direct_leaf_children,
				NVL(ch.direct_structural_children, 0) AS direct_structural_children
			FROM container c
			LEFT JOIN (
				SELECT
					parent_container_id,
					COUNT(*) AS direct_children,
					SUM(CASE WHEN container_type = 'collection object' THEN 1 ELSE 0 END) AS direct_leaf_children,
					SUM(CASE WHEN container_type <> 'collection object' THEN 1 ELSE 0 END) AS direct_structural_children
				FROM container
				GROUP BY parent_container_id
			) ch ON ch.parent_container_id = c.container_id
			WHERE c.container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.container_id#">
		</cfquery>
		<cfif queryGetNode.recordcount EQ 0>
			<cfset local.retval["container_id"] = arguments.container_id>
			<cfset local.retval["shape"] = "">
			<cfset local.retval["direct_children"] = 0>
			<cfset local.retval["direct_leaf_children"] = 0>
			<cfset local.retval["direct_structural_children"] = 0>
		<cfelse>
			<cfset local.retval["container_id"] = queryGetNode.container_id>
			<cfset local.retval["direct_children"] = queryGetNode.direct_children>
			<cfset local.retval["direct_leaf_children"] = queryGetNode.direct_leaf_children>
			<cfset local.retval["direct_structural_children"] = queryGetNode.direct_structural_children>
			<cfif queryGetNode.container_type EQ "collection object">
				<cfset local.retval["shape"] = "leaf">
			<cfelseif queryGetNode.direct_leaf_children GTE 1000 AND queryGetNode.direct_structural_children EQ 0>
				<cfset local.retval["shape"] = "B">
			<cfelseif queryGetNode.direct_leaf_children GT 0 AND queryGetNode.direct_structural_children GT 0>
				<cfset local.retval["shape"] = "AB">
			<cfelse>
				<cfset local.retval["shape"] = "A">
			</cfif>
		</cfif>
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
Function getTopLevelBrowse.  Returns the data needed to render the initial container browse view:
institution nodes (containers with parent_container_id = 0 and container_type = 'institution')
with their direct campus children embedded, plus counts of orphaned nodes that are direct
children of institution nodes but are not campus nodes.

In the MCZbase container hierarchy, root containers have parent_container_id = 0.  Institution
nodes are at root level.  Campus nodes are direct children of institutions.  Orphaned structural
nodes are non-campus structural containers placed directly under an institution instead of under
a campus.  Orphaned leaf nodes are collection-object containers placed directly under an institution.

@return a JSON object with keys:
  institutions - array of institution node objects, each having a campus_children array.
    Each node has: container_id, container_type, label, barcode, description,
    direct_structural_children, direct_leaf_children.
    Each campus child also has: has_leaf_descendants.
  orphaned_structural_count - count of non-campus structural nodes that are direct children of institutions.
  orphaned_leaf_count       - count of collection-object nodes that are direct children of institutions.
  top_level_other           - array of root-level containers that are not of type institution
    (e.g., a Deaccessioned campus placed at root level).  Each node has: container_id,
    container_type, label, barcode, description, direct_structural_children,
    direct_leaf_children, has_leaf_descendants.
--->
<cffunction name="getTopLevelBrowse" access="remote" returntype="any" returnformat="json">

	<cfset local.retval = StructNew()>
	<cftry>
		<!--- Institution nodes at root level (parent_container_id = 0) with child counts --->
		<cfquery name="queryGetInstitutions" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
			SELECT
				c.container_id,
				c.container_type,
				c.label,
				c.barcode,
				c.description,
				NVL(ch.direct_structural_children, 0) AS direct_structural_children,
				NVL(ch.direct_leaf_children, 0) AS direct_leaf_children
			FROM container c
			LEFT JOIN (
				SELECT
					parent_container_id,
					SUM(CASE WHEN container_type <> 'collection object' THEN 1 ELSE 0 END) AS direct_structural_children,
					SUM(CASE WHEN container_type = 'collection object' THEN 1 ELSE 0 END) AS direct_leaf_children
				FROM container
				GROUP BY parent_container_id
			) ch ON ch.parent_container_id = c.container_id
			WHERE c.parent_container_id = 0
				AND c.container_type = 'institution'
			ORDER BY c.label
		</cfquery>
		<!--- Campus children of all institutions with child counts --->
		<cfquery name="queryGetCampuses" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
			SELECT
				c.container_id,
				c.parent_container_id,
				c.container_type,
				c.label,
				c.barcode,
				c.description,
				NVL(ch.direct_structural_children, 0) AS direct_structural_children,
				NVL(ch.direct_leaf_children, 0) AS direct_leaf_children
			FROM container c
			LEFT JOIN (
				SELECT
					parent_container_id,
					SUM(CASE WHEN container_type <> 'collection object' THEN 1 ELSE 0 END) AS direct_structural_children,
					SUM(CASE WHEN container_type = 'collection object' THEN 1 ELSE 0 END) AS direct_leaf_children
				FROM container
				GROUP BY parent_container_id
			) ch ON ch.parent_container_id = c.container_id
			WHERE c.parent_container_id IN (
				SELECT container_id
				FROM container
				WHERE parent_container_id = 0
					AND container_type = 'institution'
			)
				AND c.container_type = 'campus'
			ORDER BY c.parent_container_id, c.label
		</cfquery>
		<!--- Root-level campus containers (e.g., Deaccessioned campus at root level).
		      Only campus-type containers are shown separately; other non-institution root-level
		      containers are subsumed into the orphaned structural / leaf count buttons. --->
		<cfquery name="queryGetRootOther" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
			SELECT
				c.container_id,
				c.container_type,
				c.label,
				c.barcode,
				c.description,
				NVL(ch.direct_structural_children, 0) AS direct_structural_children,
				NVL(ch.direct_leaf_children, 0) AS direct_leaf_children
			FROM container c
			LEFT JOIN (
				SELECT
					parent_container_id,
					SUM(CASE WHEN container_type <> 'collection object' THEN 1 ELSE 0 END) AS direct_structural_children,
					SUM(CASE WHEN container_type = 'collection object' THEN 1 ELSE 0 END) AS direct_leaf_children
				FROM container
				GROUP BY parent_container_id
			) ch ON ch.parent_container_id = c.container_id
			WHERE c.parent_container_id = 0
				AND c.container_type = 'campus'
			ORDER BY c.label
		</cfquery>
		<!--- Count orphaned structural nodes: non-campus structural containers that are either
		      direct children of institution nodes OR are at root level (parent_container_id = 0)
		      but are not institution or campus type. --->
		<cfquery name="queryGetOrphanStruct" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
			SELECT COUNT(*) AS cnt
			FROM (
				SELECT container_id
				FROM container
				WHERE parent_container_id IN (
					SELECT container_id
					FROM container
					WHERE parent_container_id = 0
						AND container_type = 'institution'
				)
					AND container_type <> 'campus'
					AND container_type <> 'collection object'
				UNION ALL
				SELECT container_id
				FROM container
				WHERE parent_container_id = 0
					AND container_type NOT IN ('institution', 'campus', 'collection object')
			)
		</cfquery>
		<!--- Count orphaned leaf nodes: collection-object containers that are either direct
		      children of institution nodes OR are at root level (parent_container_id = 0). --->
		<cfquery name="queryGetOrphanLeaf" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
			SELECT COUNT(*) AS cnt
			FROM (
				SELECT container_id
				FROM container
				WHERE parent_container_id IN (
					SELECT container_id
					FROM container
					WHERE parent_container_id = 0
						AND container_type = 'institution'
				)
					AND container_type = 'collection object'
				UNION ALL
				SELECT container_id
				FROM container
				WHERE parent_container_id = 0
					AND container_type = 'collection object'
			)
		</cfquery>
		<!--- Build institution array with embedded campus children --->
		<cfset local.institutions = ArrayNew(1)>
		<cfset local.instIdx = 1>
		<cfloop query="queryGetInstitutions">
			<cfset local.inst = StructNew()>
			<cfset local.inst["container_id"] = queryGetInstitutions.container_id>
			<cfset local.inst["container_type"] = queryGetInstitutions.container_type>
			<cfset local.inst["label"] = queryGetInstitutions.label>
			<cfset local.inst["barcode"] = queryGetInstitutions.barcode>
			<cfset local.inst["description"] = queryGetInstitutions.description>
			<cfset local.inst["direct_structural_children"] = queryGetInstitutions.direct_structural_children>
			<cfset local.inst["direct_leaf_children"] = queryGetInstitutions.direct_leaf_children>
			<cfset local.campusArr = ArrayNew(1)>
			<cfset local.campusIdx = 1>
			<cfloop query="queryGetCampuses">
				<cfif queryGetCampuses.parent_container_id EQ queryGetInstitutions.container_id>
					<cfset local.campus = StructNew()>
					<cfset local.campus["container_id"] = queryGetCampuses.container_id>
					<cfset local.campus["parent_container_id"] = queryGetCampuses.parent_container_id>
					<cfset local.campus["container_type"] = queryGetCampuses.container_type>
					<cfset local.campus["label"] = queryGetCampuses.label>
					<cfset local.campus["barcode"] = queryGetCampuses.barcode>
					<cfset local.campus["description"] = queryGetCampuses.description>
					<cfset local.campus["direct_structural_children"] = queryGetCampuses.direct_structural_children>
					<cfset local.campus["direct_leaf_children"] = queryGetCampuses.direct_leaf_children>
					<cfset local.campus["has_leaf_descendants"] = (queryGetCampuses.direct_structural_children GT 0 OR queryGetCampuses.direct_leaf_children GT 0) ? 1 : 0>
					<cfset local.campusArr[local.campusIdx] = local.campus>
					<cfset local.campusIdx = local.campusIdx + 1>
				</cfif>
			</cfloop>
			<cfset local.inst["campus_children"] = local.campusArr>
			<cfset local.institutions[local.instIdx] = local.inst>
			<cfset local.instIdx = local.instIdx + 1>
		</cfloop>
		<cfset local.retval["institutions"] = local.institutions>
		<cfset local.retval["orphaned_structural_count"] = queryGetOrphanStruct.cnt>
		<cfset local.retval["orphaned_leaf_count"] = queryGetOrphanLeaf.cnt>
		<!--- Build root-level non-institution nodes array --->
		<cfset local.rootOtherArr = ArrayNew(1)>
		<cfset local.rootOtherIdx = 1>
		<cfloop query="queryGetRootOther">
			<cfset local.rootOther = StructNew()>
			<cfset local.rootOther["container_id"] = queryGetRootOther.container_id>
			<cfset local.rootOther["container_type"] = queryGetRootOther.container_type>
			<cfset local.rootOther["label"] = queryGetRootOther.label>
			<cfset local.rootOther["barcode"] = queryGetRootOther.barcode>
			<cfset local.rootOther["description"] = queryGetRootOther.description>
			<cfset local.rootOther["direct_structural_children"] = queryGetRootOther.direct_structural_children>
			<cfset local.rootOther["direct_leaf_children"] = queryGetRootOther.direct_leaf_children>
			<cfset local.rootOther["has_leaf_descendants"] = (queryGetRootOther.direct_structural_children GT 0 OR queryGetRootOther.direct_leaf_children GT 0) ? 1 : 0>
			<cfset local.rootOtherArr[local.rootOtherIdx] = local.rootOther>
			<cfset local.rootOtherIdx = local.rootOtherIdx + 1>
		</cfloop>
		<cfset local.retval["top_level_other"] = local.rootOtherArr>
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
Function getOrphanedTopLevelStructural.  Returns non-campus structural containers that are
direct children of institution nodes.  These are nodes such as buildings, rooms, or freezers
placed directly under an institution instead of under a campus.  Returned in the same structure
as getDirectStructuralChildren so that renderTreeNodes can render them unchanged.

@return a JSON array of objects with keys: container_id, parent_container_id, container_type,
  label, barcode, description, direct_structural_children, direct_leaf_children,
  single_child_barcode, single_child_label, has_leaf_descendants.
--->
<cffunction name="getOrphanedTopLevelStructural" access="remote" returntype="any" returnformat="json">

	<cfset local.retval = ArrayNew(1)>
	<cftry>
		<cfquery name="queryGetOrphans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
			SELECT
				c.container_id,
				c.parent_container_id,
				c.container_type,
				c.label,
				c.barcode,
				c.description,
				NVL(ch.direct_structural_children, 0) AS direct_structural_children,
				NVL(ch.direct_leaf_children, 0) AS direct_leaf_children,
				sc.single_child_barcode,
				sc.single_child_label,
				CASE WHEN NVL(ch.direct_structural_children, 0) > 0 OR NVL(ch.direct_leaf_children, 0) > 0 THEN 1 ELSE 0 END AS has_leaf_descendants
			FROM container c
			LEFT JOIN (
				SELECT
					parent_container_id,
					SUM(CASE WHEN container_type <> 'collection object' THEN 1 ELSE 0 END) AS direct_structural_children,
					SUM(CASE WHEN container_type = 'collection object' THEN 1 ELSE 0 END) AS direct_leaf_children
				FROM container
				GROUP BY parent_container_id
			) ch ON ch.parent_container_id = c.container_id
			LEFT JOIN (
				SELECT parent_container_id, barcode AS single_child_barcode, label AS single_child_label
				FROM (
					SELECT
						parent_container_id,
						barcode,
						label,
						ROW_NUMBER() OVER (PARTITION BY parent_container_id ORDER BY label) AS rn
					FROM container
					WHERE container_type = 'collection object'
						AND parent_container_id IN (
							SELECT container_id
							FROM container
							WHERE (
								parent_container_id IN (
									SELECT container_id
									FROM container
									WHERE parent_container_id = 0
										AND container_type = 'institution'
								)
								OR parent_container_id = 0
							)
								AND container_type NOT IN ('institution', 'campus', 'collection object')
						)
				)
				WHERE rn = 1
			) sc ON sc.parent_container_id = c.container_id
			WHERE (
				c.parent_container_id IN (
					SELECT container_id
					FROM container
					WHERE parent_container_id = 0
						AND container_type = 'institution'
				)
				OR c.parent_container_id = 0
			)
				AND c.container_type NOT IN ('institution', 'campus', 'collection object')
			ORDER BY
				CASE WHEN NVL(ch.direct_structural_children, 0) > 0 THEN 0 ELSE 1 END,
				c.container_type,
				c.label
		</cfquery>
		<cfset local.i = 1>
		<cfloop query="queryGetOrphans">
			<cfset local.row = StructNew()>
			<cfset local.row["container_id"] = queryGetOrphans.container_id>
			<cfset local.row["parent_container_id"] = queryGetOrphans.parent_container_id>
			<cfset local.row["container_type"] = queryGetOrphans.container_type>
			<cfset local.row["label"] = queryGetOrphans.label>
			<cfset local.row["barcode"] = queryGetOrphans.barcode>
			<cfset local.row["description"] = queryGetOrphans.description>
			<cfset local.row["direct_structural_children"] = queryGetOrphans.direct_structural_children>
			<cfset local.row["direct_leaf_children"] = queryGetOrphans.direct_leaf_children>
			<cfset local.row["single_child_barcode"] = queryGetOrphans.single_child_barcode>
			<cfset local.row["single_child_label"] = queryGetOrphans.single_child_label>
			<cfset local.row["has_leaf_descendants"] = queryGetOrphans.has_leaf_descendants>
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
Function checkHasLeafDescendants.  Returns whether the given container has any collection
object container descendants at any depth in its subtree.  Uses a hierarchical traversal
via CONNECT BY, but is called only on-demand (when the Specimens button is clicked for a
container with no direct leaf children), keeping page-load performance fast.

@param container_id the container_id to check.
@return a JSON object with key has_leaf_descendants (1 if any collection object descendant
  exists at any depth, 0 otherwise).
--->
<cffunction name="checkHasLeafDescendants" access="remote" returntype="any" returnformat="json">
	<cfargument name="container_id" type="numeric" required="yes">

	<cfset local.retval = StructNew()>
	<cftry>
		<cfquery name="queryGetCheck" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
			SELECT CASE WHEN EXISTS (
				SELECT 1
				FROM container
				WHERE container_type = 'collection object'
				START WITH parent_container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.container_id#">
				CONNECT BY NOCYCLE PRIOR container_id = parent_container_id
			) THEN 1 ELSE 0 END AS has_leaf_descendants
			FROM DUAL
		</cfquery>
		<cfset local.retval["has_leaf_descendants"] = queryGetCheck.has_leaf_descendants>
	<cfcatch>
		<cfset local.error_message = cfcatchToErrorMessage(cfcatch)>
		<cfset local.function_called = "#GetFunctionCalledName()#">
		<cfscript>reportError(function_called="#local.function_called#", error_message="#local.error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn serializeJSON(local.retval)>
</cffunction>

</cfcomponent>
