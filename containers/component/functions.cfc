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
	<cfset variables.data = ArrayNew(1)>
	<cftry>
		<cfquery name="variables.qChildren" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
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
		<cfset variables.i = 1>
		<cfloop query="variables.qChildren">
			<cfset variables.row = StructNew()>
			<cfset variables.row["container_id"] = variables.qChildren.container_id>
			<cfset variables.row["parent_container_id"] = variables.qChildren.parent_container_id>
			<cfset variables.row["container_type"] = variables.qChildren.container_type>
			<cfset variables.row["label"] = variables.qChildren.label>
			<cfset variables.row["barcode"] = variables.qChildren.barcode>
			<cfset variables.row["description"] = variables.qChildren.description>
			<cfset variables.row["direct_structural_children"] = variables.qChildren.direct_structural_children>
			<cfset variables.row["direct_leaf_children"] = variables.qChildren.direct_leaf_children>
			<cfset variables.row["single_child_barcode"] = variables.qChildren.single_child_barcode>
			<cfset variables.row["single_child_label"] = variables.qChildren.single_child_label>
			<cfset variables.row["has_leaf_descendants"] = variables.qChildren.has_leaf_descendants>
			<cfset variables.data[variables.i] = variables.row>
			<cfset variables.i = variables.i + 1>
		</cfloop>
		<cfreturn serializeJSON(variables.data)>
	<cfcatch>
		<cfset variables.error_message = cfcatchToErrorMessage(cfcatch)>
		<cfset variables.function_called = "#GetFunctionCalledName()#">
		<cfscript>reportError(function_called="#variables.function_called#", error_message="#variables.error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn serializeJSON(variables.data)>
</cffunction>

<!---
Function getDirectLeafChildren.  Returns a paginated list of direct collection-object children
of the given container, for use in the leaf browser panel.

@param container_id the container_id whose direct leaf (collection object) children are returned.
@param page the page number to return (1-based), defaults to 1.
@param pageSize the number of rows per page, defaults to 50.
@return a JSON object with keys: rows (array), page, pageSize, totalRows.
--->
<cffunction name="getDirectLeafChildren" access="remote" returntype="any" returnformat="json">
	<cfargument name="container_id" type="numeric" required="yes">
	<cfargument name="page" type="numeric" required="no" default="1">
	<cfargument name="pageSize" type="numeric" required="no" default="50">
	<cfset variables.result = StructNew()>
	<cftry>
		<cfset variables.offset = (arguments.page - 1) * arguments.pageSize>
		<!--- Total row count --->
		<cfquery name="variables.qCount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
			SELECT COUNT(*) AS total_rows
			FROM container
			WHERE
				parent_container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.container_id#">
				AND container_type = 'collection object'
		</cfquery>
		<cfset variables.totalRows = variables.qCount.total_rows>
		<!--- Paginated rows using Oracle ROWNUM subquery --->
		<cfquery name="variables.qLeaf" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
			SELECT container_id, label, barcode, description
			FROM (
				SELECT
					container_id,
					label,
					barcode,
					description,
					ROWNUM AS rn
				FROM (
					SELECT
						container_id,
						label,
						barcode,
						description
					FROM container
					WHERE
						parent_container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.container_id#">
						AND container_type = 'collection object'
					ORDER BY label
				)
				WHERE ROWNUM <= <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#variables.offset + arguments.pageSize#">
			)
			WHERE rn > <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#variables.offset#">
		</cfquery>
		<cfset variables.rows = ArrayNew(1)>
		<cfset variables.i = 1>
		<cfloop query="variables.qLeaf">
			<cfset variables.row = StructNew()>
			<cfset variables.row["container_id"] = variables.qLeaf.container_id>
			<cfset variables.row["label"] = variables.qLeaf.label>
			<cfset variables.row["barcode"] = variables.qLeaf.barcode>
			<cfset variables.row["description"] = variables.qLeaf.description>
			<cfset variables.rows[variables.i] = variables.row>
			<cfset variables.i = variables.i + 1>
		</cfloop>
		<cfset variables.result["rows"] = variables.rows>
		<cfset variables.result["page"] = arguments.page>
		<cfset variables.result["pageSize"] = arguments.pageSize>
		<cfset variables.result["totalRows"] = variables.totalRows>
		<cfreturn serializeJSON(variables.result)>
	<cfcatch>
		<cfset variables.error_message = cfcatchToErrorMessage(cfcatch)>
		<cfset variables.function_called = "#GetFunctionCalledName()#">
		<cfscript>reportError(function_called="#variables.function_called#", error_message="#variables.error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn serializeJSON(variables.result)>
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
	<cfset variables.result = StructNew()>
	<cftry>
		<cfquery name="variables.qNode" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
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
		<cfif variables.qNode.recordcount EQ 0>
			<cfset variables.result["container_id"] = arguments.container_id>
			<cfset variables.result["shape"] = "">
			<cfset variables.result["direct_children"] = 0>
			<cfset variables.result["direct_leaf_children"] = 0>
			<cfset variables.result["direct_structural_children"] = 0>
		<cfelse>
			<cfset variables.result["container_id"] = variables.qNode.container_id>
			<cfset variables.result["direct_children"] = variables.qNode.direct_children>
			<cfset variables.result["direct_leaf_children"] = variables.qNode.direct_leaf_children>
			<cfset variables.result["direct_structural_children"] = variables.qNode.direct_structural_children>
			<cfif variables.qNode.container_type EQ "collection object">
				<cfset variables.result["shape"] = "leaf">
			<cfelseif variables.qNode.direct_leaf_children GTE 1000 AND variables.qNode.direct_structural_children EQ 0>
				<cfset variables.result["shape"] = "B">
			<cfelseif variables.qNode.direct_leaf_children GT 0 AND variables.qNode.direct_structural_children GT 0>
				<cfset variables.result["shape"] = "AB">
			<cfelse>
				<cfset variables.result["shape"] = "A">
			</cfif>
		</cfif>
		<cfreturn serializeJSON(variables.result)>
	<cfcatch>
		<cfset variables.error_message = cfcatchToErrorMessage(cfcatch)>
		<cfset variables.function_called = "#GetFunctionCalledName()#">
		<cfscript>reportError(function_called="#variables.function_called#", error_message="#variables.error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn serializeJSON(variables.result)>
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
	<cfset variables.result = StructNew()>
	<cftry>
		<!--- Institution nodes at root level (parent_container_id = 0) with child counts --->
		<cfquery name="variables.qInstitutions" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
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
		<cfquery name="variables.qCampuses" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
			SELECT
				c.container_id,
				c.parent_container_id,
				c.container_type,
				c.label,
				c.barcode,
				c.description,
				NVL(ch.direct_structural_children, 0) AS direct_structural_children,
				NVL(ch.direct_leaf_children, 0) AS direct_leaf_children,
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
			WHERE c.parent_container_id IN (
				SELECT container_id
				FROM container
				WHERE parent_container_id = 0
					AND container_type = 'institution'
			)
				AND c.container_type = 'campus'
			ORDER BY c.parent_container_id, c.label
		</cfquery>
		<!--- Root-level non-institution containers (e.g., a Deaccessioned campus at root level) --->
		<cfquery name="variables.qRootOther" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
			SELECT
				c.container_id,
				c.container_type,
				c.label,
				c.barcode,
				c.description,
				NVL(ch.direct_structural_children, 0) AS direct_structural_children,
				NVL(ch.direct_leaf_children, 0) AS direct_leaf_children,
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
			WHERE c.parent_container_id = 0
				AND c.container_type <> 'institution'
			ORDER BY c.label
		</cfquery>
		<!--- Count orphaned structural nodes: non-institution structural nodes at root level --->
		<cfquery name="variables.qOrphanStruct" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
			SELECT COUNT(*) AS cnt
			FROM container
			WHERE parent_container_id IN (
				SELECT container_id
				FROM container
				WHERE parent_container_id = 0
					AND container_type = 'institution'
			)
				AND container_type <> 'campus'
				AND container_type <> 'collection object'
		</cfquery>
		<!--- Count orphaned leaf nodes: collection-object nodes at root level --->
		<cfquery name="variables.qOrphanLeaf" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
			SELECT COUNT(*) AS cnt
			FROM container
			WHERE parent_container_id IN (
				SELECT container_id
				FROM container
				WHERE parent_container_id = 0
					AND container_type = 'institution'
			)
				AND container_type = 'collection object'
		</cfquery>
		<!--- Build institution array with embedded campus children --->
		<cfset variables.institutions = ArrayNew(1)>
		<cfset variables.instIdx = 1>
		<cfloop query="variables.qInstitutions">
			<cfset variables.inst = StructNew()>
			<cfset variables.inst["container_id"] = variables.qInstitutions.container_id>
			<cfset variables.inst["container_type"] = variables.qInstitutions.container_type>
			<cfset variables.inst["label"] = variables.qInstitutions.label>
			<cfset variables.inst["barcode"] = variables.qInstitutions.barcode>
			<cfset variables.inst["description"] = variables.qInstitutions.description>
			<cfset variables.inst["direct_structural_children"] = variables.qInstitutions.direct_structural_children>
			<cfset variables.inst["direct_leaf_children"] = variables.qInstitutions.direct_leaf_children>
			<cfset variables.campusArr = ArrayNew(1)>
			<cfset variables.campusIdx = 1>
			<cfloop query="variables.qCampuses">
				<cfif variables.qCampuses.parent_container_id EQ variables.qInstitutions.container_id>
					<cfset variables.campus = StructNew()>
					<cfset variables.campus["container_id"] = variables.qCampuses.container_id>
					<cfset variables.campus["parent_container_id"] = variables.qCampuses.parent_container_id>
					<cfset variables.campus["container_type"] = variables.qCampuses.container_type>
					<cfset variables.campus["label"] = variables.qCampuses.label>
					<cfset variables.campus["barcode"] = variables.qCampuses.barcode>
					<cfset variables.campus["description"] = variables.qCampuses.description>
					<cfset variables.campus["direct_structural_children"] = variables.qCampuses.direct_structural_children>
					<cfset variables.campus["direct_leaf_children"] = variables.qCampuses.direct_leaf_children>
					<cfset variables.campus["has_leaf_descendants"] = variables.qCampuses.has_leaf_descendants>
					<cfset variables.campusArr[variables.campusIdx] = variables.campus>
					<cfset variables.campusIdx = variables.campusIdx + 1>
				</cfif>
			</cfloop>
			<cfset variables.inst["campus_children"] = variables.campusArr>
			<cfset variables.institutions[variables.instIdx] = variables.inst>
			<cfset variables.instIdx = variables.instIdx + 1>
		</cfloop>
		<cfset variables.result["institutions"] = variables.institutions>
		<cfset variables.result["orphaned_structural_count"] = variables.qOrphanStruct.cnt>
		<cfset variables.result["orphaned_leaf_count"] = variables.qOrphanLeaf.cnt>
		<!--- Build root-level non-institution nodes array --->
		<cfset variables.rootOtherArr = ArrayNew(1)>
		<cfset variables.rootOtherIdx = 1>
		<cfloop query="variables.qRootOther">
			<cfset variables.rootOther = StructNew()>
			<cfset variables.rootOther["container_id"] = variables.qRootOther.container_id>
			<cfset variables.rootOther["container_type"] = variables.qRootOther.container_type>
			<cfset variables.rootOther["label"] = variables.qRootOther.label>
			<cfset variables.rootOther["barcode"] = variables.qRootOther.barcode>
			<cfset variables.rootOther["description"] = variables.qRootOther.description>
			<cfset variables.rootOther["direct_structural_children"] = variables.qRootOther.direct_structural_children>
			<cfset variables.rootOther["direct_leaf_children"] = variables.qRootOther.direct_leaf_children>
			<cfset variables.rootOther["has_leaf_descendants"] = variables.qRootOther.has_leaf_descendants>
			<cfset variables.rootOtherArr[variables.rootOtherIdx] = variables.rootOther>
			<cfset variables.rootOtherIdx = variables.rootOtherIdx + 1>
		</cfloop>
		<cfset variables.result["top_level_other"] = variables.rootOtherArr>
		<cfreturn serializeJSON(variables.result)>
	<cfcatch>
		<cfset variables.error_message = cfcatchToErrorMessage(cfcatch)>
		<cfset variables.function_called = "#GetFunctionCalledName()#">
		<cfscript>reportError(function_called="#variables.function_called#", error_message="#variables.error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn serializeJSON(variables.result)>
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
	<cfset variables.data = ArrayNew(1)>
	<cftry>
		<cfquery name="variables.qOrphans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
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
							WHERE parent_container_id IN (
								SELECT container_id
								FROM container
								WHERE parent_container_id = 0
									AND container_type = 'institution'
							)
								AND container_type <> 'campus'
								AND container_type <> 'collection object'
						)
				)
				WHERE rn = 1
			) sc ON sc.parent_container_id = c.container_id
			WHERE c.parent_container_id IN (
				SELECT container_id
				FROM container
				WHERE parent_container_id = 0
					AND container_type = 'institution'
			)
				AND c.container_type <> 'campus'
				AND c.container_type <> 'collection object'
			ORDER BY
				CASE WHEN NVL(ch.direct_structural_children, 0) > 0 THEN 0 ELSE 1 END,
				c.container_type,
				c.label
		</cfquery>
		<cfset variables.i = 1>
		<cfloop query="variables.qOrphans">
			<cfset variables.row = StructNew()>
			<cfset variables.row["container_id"] = variables.qOrphans.container_id>
			<cfset variables.row["parent_container_id"] = variables.qOrphans.parent_container_id>
			<cfset variables.row["container_type"] = variables.qOrphans.container_type>
			<cfset variables.row["label"] = variables.qOrphans.label>
			<cfset variables.row["barcode"] = variables.qOrphans.barcode>
			<cfset variables.row["description"] = variables.qOrphans.description>
			<cfset variables.row["direct_structural_children"] = variables.qOrphans.direct_structural_children>
			<cfset variables.row["direct_leaf_children"] = variables.qOrphans.direct_leaf_children>
			<cfset variables.row["single_child_barcode"] = variables.qOrphans.single_child_barcode>
			<cfset variables.row["single_child_label"] = variables.qOrphans.single_child_label>
			<cfset variables.row["has_leaf_descendants"] = variables.qOrphans.has_leaf_descendants>
			<cfset variables.data[variables.i] = variables.row>
			<cfset variables.i = variables.i + 1>
		</cfloop>
		<cfreturn serializeJSON(variables.data)>
	<cfcatch>
		<cfset variables.error_message = cfcatchToErrorMessage(cfcatch)>
		<cfset variables.function_called = "#GetFunctionCalledName()#">
		<cfscript>reportError(function_called="#variables.function_called#", error_message="#variables.error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn serializeJSON(variables.data)>
</cffunction>

</cfcomponent>
