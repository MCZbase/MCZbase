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
Function getContainerTypeMetadataQuery.  Returns container-type role metadata from
ctcontainer_type for use by the redesigned container browse/search/view code.

TODO: Consider extending ctcontainer_type with columns such as browse_grouping_mode,
allow_create_child, contents_display_mode, and explore_visibility so the redesign can
stop inferring these UI behaviors from role and expects_leaf_child_count alone.
--->
<cffunction name="getContainerTypeMetadataQuery" access="public" returntype="query" output="false">
	<cfquery name="local.ctContainerType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
		SELECT
			container_type,
			role,
			NVL(expects_leaf_child_count, 0) AS expects_leaf_child_count
		FROM
			ctcontainer_type
		ORDER BY
			container_type
	</cfquery>
	<cfreturn local.ctContainerType>
</cffunction>

<!---
Function getContainerTypeMetadata.  Returns container-type role metadata as JSON for
client-side use.
--->
<cffunction name="getContainerTypeMetadata" access="remote" returntype="any" returnformat="json" output="false">
	<cfset local.retval = StructNew()>
	<cftry>
		<cfset local.ctContainerType = getContainerTypeMetadataQuery()>
		<cfset local.rows = ArrayNew(1)>
		<cfset local.byType = StructNew()>
		<cfset local.i = 1>
		<cfloop query="local.ctContainerType">
			<cfset local.row = StructNew()>
			<cfset local.row["container_type"] = local.ctContainerType.container_type>
			<cfset local.row["role"] = lCase(trim(local.ctContainerType.role))>
			<cfset local.row["expects_leaf_child_count"] = val(local.ctContainerType.expects_leaf_child_count)>
			<cfset local.rows[local.i] = local.row>
			<cfset local.byType[lCase(local.ctContainerType.container_type)] = local.row>
			<cfset local.i = local.i + 1>
		</cfloop>
		<cfset local.retval["rows"] = local.rows>
		<cfset local.retval["byType"] = local.byType>
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
  cat_num, collection_cde, institution_acronym, part_name, preserve_method,
  scientific_name.
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
				cat_num, collection_cde, institution_acronym, part_name, preserve_method, scientific_name
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
					preserve_method,
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
						spec.preserve_method,
						spec.scientific_name
					FROM container c
					LEFT JOIN (
						SELECT
							coch.container_id,
							MAX(ci.cat_num) AS cat_num,
							MAX(ci.collection_cde) AS collection_cde,
							MAX(col.institution_acronym) AS institution_acronym,
							MAX(sp.part_name) AS part_name,
							MAX(sp.preserve_method) AS preserve_method,
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
			<cfset local.row["preserve_method"] = queryGetLeaf.preserve_method>
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
  orphaned_structural_count      - count of non-campus structural nodes that are direct children of institutions.
  orphaned_leaf_count            - count of collection-object nodes that are direct children of institutions.
  orphaned_single_occupant_count - count of pin/slide/cryovial/envelope/glass vial containers at institution or root level.
  top_level_other                - array of root-level containers that are not of type institution
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
		<!--- Count orphaned structural nodes: structural-role containers that are either direct
		      children of institution nodes OR are at root level (parent_container_id = 0), excluding
		      institution and campus which anchor the normal top-level hierarchy. --->
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
					AND container_type IN (
						SELECT container_type
						FROM ctcontainer_type
						WHERE role = 'structural'
					)
					AND container_type <> 'campus'
				UNION ALL
				SELECT container_id
				FROM container
				WHERE parent_container_id = 0
					AND container_type IN (
						SELECT container_type
						FROM ctcontainer_type
						WHERE role = 'structural'
					)
					AND container_type NOT IN ('institution', 'campus')
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
		<!--- Count orphaned empty proxy containers at institution or root level. --->
		<cfquery name="queryGetOrphanEmptyProxy" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
			SELECT COUNT(*) AS cnt
			FROM container c
			WHERE (
				c.parent_container_id IN (
					SELECT container_id
					FROM container
					WHERE parent_container_id = 0
						AND container_type = 'institution'
				)
				OR c.parent_container_id = 0
			)
			AND c.container_type IN (
				SELECT container_type
				FROM ctcontainer_type
				WHERE role = 'proxy'
					AND NVL(expects_leaf_child_count, 0) = 1
			)
			AND NOT EXISTS (
				SELECT 1
				FROM container occ
				WHERE occ.parent_container_id = c.container_id
					AND occ.container_type = 'collection object'
			)
		</cfquery>
		<!--- Count orphaned single-occupant proxy containers at institution or root level. --->
		<cfquery name="queryGetOrphanSingleOccupant" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
			SELECT COUNT(*) AS cnt
			FROM container c
			WHERE (
				c.parent_container_id IN (
					SELECT container_id
					FROM container
					WHERE parent_container_id = 0
						AND container_type = 'institution'
				)
				OR c.parent_container_id = 0
			)
			AND c.container_type IN (
				SELECT container_type
				FROM ctcontainer_type
				WHERE role = 'proxy'
					AND NVL(expects_leaf_child_count, 0) = 1
			)
			AND EXISTS (
				SELECT 1
				FROM container occ
				WHERE occ.parent_container_id = c.container_id
					AND occ.container_type = 'collection object'
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
		<cfset local.retval["orphaned_empty_proxy_count"] = queryGetOrphanEmptyProxy.cnt>
		<cfset local.retval["orphaned_single_occupant_count"] = queryGetOrphanSingleOccupant.cnt>
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
Function getOrphanedTopLevelStructural.  Returns structural-role containers that are direct
children of institution nodes or placed at root level outside the institution/campus hierarchy.
These are nodes such as buildings, rooms, or freezers placed directly under an institution
instead of under a campus.  Returned in the same structure as getDirectStructuralChildren so
that renderTreeNodes can render them unchanged.

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
								AND container_type IN (
									SELECT container_type
									FROM ctcontainer_type
									WHERE role = 'structural'
								)
								AND container_type NOT IN ('institution', 'campus')
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
				AND c.container_type IN (
					SELECT container_type
					FROM ctcontainer_type
					WHERE role = 'structural'
				)
				AND c.container_type NOT IN ('institution', 'campus')
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
object container leaves at any depth in its subtree, including the current container when
it is itself a collection object container.  Uses a hierarchical traversal
via CONNECT BY, but is called only on-demand (when the Specimens button is clicked for a
container with no direct leaf children), keeping page-load performance fast.

@param container_id the container_id to check.
@return a JSON object with key has_leaf_descendants (1 if any collection object leaf
  exists at any depth in the subtree, 0 otherwise).
--->
<cffunction name="checkHasLeafDescendants" access="remote" returntype="any" returnformat="json">
	<cfargument name="container_id" type="numeric" required="yes">

	<cfset local.retval = StructNew()>
	<cftry>
		<cfquery name="queryGetCheck" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
			SELECT CASE WHEN EXISTS (
				SELECT 1
				FROM (
					SELECT
						container_type
					FROM
						container
					START WITH
						container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.container_id#">
					CONNECT BY NOCYCLE PRIOR
						container_id = parent_container_id
				) subtree
				WHERE
					subtree.container_type = 'collection object'
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

<!---
Function getContainerForEdit.  Returns all editable fields for a single container record,
plus the parent container's label and barcode for pre-populating the parent picker.
Used to populate the Container.cfm edit form via AJAX or direct CFC call.

@param container_id the container_id to load.
@return a JSON object with all container fields plus parent_label and parent_barcode.
--->
<cffunction name="getContainerForEdit" access="remote" returntype="any" returnformat="json">
	<cfargument name="container_id" type="numeric" required="yes">

	<cfset local.retval = StructNew()>
	<cftry>
		<cfquery name="queryGetContainer" datasource="user_login" username="#session.dbuser#"  password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
			SELECT
				c.container_id,
				c.parent_container_id,
				c.container_type,
				c.label,
				c.description,
				c.parent_install_date,
				c.container_remarks,
				c.barcode,
				c.print_fg,
				c.width,
				c.height,
				c.length,
				c.number_positions,
				c.locked_position,
				c.institution_acronym,
				p.label AS parent_label,
				p.barcode AS parent_barcode
			FROM
				container c
				LEFT JOIN container p ON c.parent_container_id = p.container_id
			WHERE
				c.container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.container_id#">
		</cfquery>
		<cfif queryGetContainer.recordcount EQ 0>
			<cfset local.retval["container_id"] = "">
			<cfset local.retval["error"] = "Container not found.">
		<cfelse>
			<cfset local.retval["container_id"] = queryGetContainer.container_id>
			<cfset local.retval["parent_container_id"] = queryGetContainer.parent_container_id>
			<cfset local.retval["container_type"] = queryGetContainer.container_type>
			<cfset local.retval["label"] = queryGetContainer.label>
			<cfset local.retval["description"] = queryGetContainer.description>
			<cfif isDate(queryGetContainer.parent_install_date)>
				<cfset local.retval["parent_install_date"] = dateFormat(queryGetContainer.parent_install_date, "yyyy-mm-dd")>
			<cfelse>
				<cfset local.retval["parent_install_date"] = "">
			</cfif>
			<cfset local.retval["container_remarks"] = queryGetContainer.container_remarks>
			<cfset local.retval["barcode"] = queryGetContainer.barcode>
			<cfset local.retval["print_fg"] = queryGetContainer.print_fg>
			<cfset local.retval["width"] = queryGetContainer.width>
			<cfset local.retval["height"] = queryGetContainer.height>
			<cfset local.retval["length"] = queryGetContainer.length>
			<cfset local.retval["number_positions"] = queryGetContainer.number_positions>
			<cfset local.retval["locked_position"] = queryGetContainer.locked_position>
			<cfset local.retval["institution_acronym"] = queryGetContainer.institution_acronym>
			<cfset local.retval["parent_label"] = queryGetContainer.parent_label>
			<cfset local.retval["parent_barcode"] = queryGetContainer.parent_barcode>
		</cfif>
	<cfcatch>
		<cfset local.error_message = cfcatchToErrorMessage(cfcatch)>
		<cfset local.function_called = "#GetFunctionCalledName()#">
		<cfscript>reportError(function_called="#local.function_called#", error_message="#local.error_message#");</cfscript>
		<cfset local.retval = StructNew()>
		<cfset local.retval["container_id"] = "">
		<cfset local.retval["error"] = cfcatch.message>
	</cfcatch>
	</cftry>
	<cfreturn serializeJSON(local.retval)>
</cffunction>

<!---
Function createContainer.  Creates a new container record.

@return JSON object with status and container_id on success.
--->
<cffunction name="createContainer" access="remote" returntype="any" returnformat="json">
	<cfargument name="container_type" type="string" required="yes">
	<cfargument name="label" type="string" required="yes">
	<cfargument name="parent_container_id" type="string" required="yes">
	<cfargument name="barcode" type="string" required="no" default="">
	<cfargument name="description" type="string" required="no" default="">
	<cfargument name="parent_install_date" type="string" required="no" default="">
	<cfargument name="container_remarks" type="string" required="no" default="">
	<cfargument name="width" type="string" required="no" default="">
	<cfargument name="height" type="string" required="no" default="">
	<cfargument name="length" type="string" required="no" default="">
	<cfargument name="number_positions" type="string" required="no" default="">
	<cfargument name="institution_acronym" type="string" required="no" default="MCZ">

	<cfset local.retval = StructNew()>
	<cfif len(trim(arguments.container_type)) EQ 0 OR len(trim(arguments.label)) EQ 0 OR len(trim(arguments.parent_container_id)) EQ 0>
		<cfset local.retval["status"] = "error">
		<cfset local.retval["message"] = "Container type, label, and parent container are required.">
		<cfreturn serializeJSON(local.retval)>
	</cfif>
	<cfif NOT isNumeric(arguments.parent_container_id)>
		<cfset local.retval["status"] = "error">
		<cfset local.retval["message"] = "Parent container must be numeric.">
		<cfreturn serializeJSON(local.retval)>
	</cfif>
	<cfif len(trim(arguments.parent_install_date)) GT 0 AND NOT isDate(arguments.parent_install_date)>
		<cfset local.retval["status"] = "error">
		<cfset local.retval["message"] = "Placement date must be a valid date in yyyy-mm-dd format.">
		<cfreturn serializeJSON(local.retval)>
	</cfif>
	<cfif (len(trim(arguments.width)) GT 0 AND NOT isNumeric(arguments.width))
			OR (len(trim(arguments.height)) GT 0 AND NOT isNumeric(arguments.height))
			OR (len(trim(arguments.length)) GT 0 AND NOT isNumeric(arguments.length))
			OR (len(trim(arguments.number_positions)) GT 0 AND NOT isNumeric(arguments.number_positions))>
		<cfset local.retval["status"] = "error">
		<cfset local.retval["message"] = "Width, height, length, and number of positions must be numeric when provided.">
		<cfreturn serializeJSON(local.retval)>
	</cfif>
	<cfif len(trim(arguments.institution_acronym)) EQ 0>
		<cfset arguments.institution_acronym = "MCZ">
	</cfif>

	<cftry>
		<cfquery name="queryNextId" datasource="user_login" username="#session.dbuser#"  password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
			SELECT
				sq_container_id.nextval AS next_container_id
			FROM
				dual
		</cfquery>
		<cfquery name="queryInsertContainer" datasource="user_login" username="#session.dbuser#"  password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
			INSERT INTO container (
				container_id,
				parent_container_id,
				container_type,
				label,
				description,
				parent_install_date,
				container_remarks,
				barcode,
				width,
				height,
				length,
				number_positions,
				locked_position,
				institution_acronym
			) VALUES (
				<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#queryNextId.next_container_id#">,
				<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.parent_container_id#">,
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(arguments.container_type)#">,
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(arguments.label)#">,
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(arguments.description)#" null="#len(trim(arguments.description)) EQ 0#">,
				<cfif len(trim(arguments.parent_install_date)) GT 0>
					<cfqueryparam cfsqltype="CF_SQL_DATE" value="#createODBCDate(parseDateTime(arguments.parent_install_date))#">
				<cfelse>
					<cfqueryparam cfsqltype="CF_SQL_DATE" value="" null="yes">
				</cfif>,
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(arguments.container_remarks)#" null="#len(trim(arguments.container_remarks)) EQ 0#">,
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(arguments.barcode)#" null="#len(trim(arguments.barcode)) EQ 0#">,
				<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#trim(arguments.width)#" null="#len(trim(arguments.width)) EQ 0#">,
				<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#trim(arguments.height)#" null="#len(trim(arguments.height)) EQ 0#">,
				<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#trim(arguments.length)#" null="#len(trim(arguments.length)) EQ 0#">,
				<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#trim(arguments.number_positions)#" null="#len(trim(arguments.number_positions)) EQ 0#">,
				<cfqueryparam cfsqltype="CF_SQL_INTEGER" value="0">,
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(arguments.institution_acronym)#">
			)
		</cfquery>
		<cfset local.retval["status"] = "created">
		<cfset local.retval["container_id"] = queryNextId.next_container_id>
	<cfcatch>
		<cfset local.error_message = cfcatchToErrorMessage(cfcatch)>
		<cfset local.function_called = "#GetFunctionCalledName()#">
		<cfscript>reportError(function_called="#local.function_called#", error_message="#local.error_message#");</cfscript>
		<cfset local.retval = StructNew()>
		<cfset local.retval["status"] = "error">
		<cfset local.retval["message"] = cfcatch.message>
	</cfcatch>
	</cftry>
	<cfreturn serializeJSON(local.retval)>
</cffunction>

<!---
Function saveContainer.  Updates an existing container record.
--->
<cffunction name="saveContainer" access="remote" returntype="any" returnformat="json">
	<cfargument name="container_id" type="string" required="yes">
	<cfargument name="container_type" type="string" required="yes">
	<cfargument name="label" type="string" required="yes">
	<cfargument name="parent_container_id" type="string" required="yes">
	<cfargument name="barcode" type="string" required="no" default="">
	<cfargument name="description" type="string" required="no" default="">
	<cfargument name="parent_install_date" type="string" required="no" default="">
	<cfargument name="container_remarks" type="string" required="no" default="">
	<cfargument name="width" type="string" required="no" default="">
	<cfargument name="height" type="string" required="no" default="">
	<cfargument name="length" type="string" required="no" default="">
	<cfargument name="number_positions" type="string" required="no" default="">
	<cfargument name="institution_acronym" type="string" required="no" default="MCZ">

	<cfset local.retval = StructNew()>
	<cfif len(trim(arguments.container_id)) EQ 0 OR NOT isNumeric(arguments.container_id)>
		<cfset local.retval["status"] = "error">
		<cfset local.retval["message"] = "Container id is required.">
		<cfreturn serializeJSON(local.retval)>
	</cfif>
	<cfif len(trim(arguments.container_type)) EQ 0 OR len(trim(arguments.label)) EQ 0 OR len(trim(arguments.parent_container_id)) EQ 0>
		<cfset local.retval["status"] = "error">
		<cfset local.retval["message"] = "Container type, label, and parent container are required.">
		<cfreturn serializeJSON(local.retval)>
	</cfif>
	<cfif NOT isNumeric(arguments.parent_container_id)>
		<cfset local.retval["status"] = "error">
		<cfset local.retval["message"] = "Parent container must be numeric.">
		<cfreturn serializeJSON(local.retval)>
	</cfif>
	<cfif len(trim(arguments.parent_install_date)) GT 0 AND NOT isDate(arguments.parent_install_date)>
		<cfset local.retval["status"] = "error">
		<cfset local.retval["message"] = "Placement date must be a valid date in yyyy-mm-dd format.">
		<cfreturn serializeJSON(local.retval)>
	</cfif>
	<cfif (len(trim(arguments.width)) GT 0 AND NOT isNumeric(arguments.width))
			OR (len(trim(arguments.height)) GT 0 AND NOT isNumeric(arguments.height))
			OR (len(trim(arguments.length)) GT 0 AND NOT isNumeric(arguments.length))
			OR (len(trim(arguments.number_positions)) GT 0 AND NOT isNumeric(arguments.number_positions))>
		<cfset local.retval["status"] = "error">
		<cfset local.retval["message"] = "Width, height, length, and number of positions must be numeric when provided.">
		<cfreturn serializeJSON(local.retval)>
	</cfif>
	<cfif len(trim(arguments.institution_acronym)) EQ 0>
		<cfset arguments.institution_acronym = "MCZ">
	</cfif>

	<cftry>
		<cfquery name="queryGetExisting" datasource="user_login" username="#session.dbuser#"  password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
			SELECT
				parent_container_id
			FROM
				container
			WHERE
				container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.container_id#">
		</cfquery>
		<cfif queryGetExisting.recordcount EQ 0>
			<cfset local.retval["status"] = "error">
			<cfset local.retval["message"] = "Container not found.">
			<cfreturn serializeJSON(local.retval)>
		</cfif>
		<cfquery name="queryUpdateContainer" datasource="user_login" username="#session.dbuser#"  password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
			UPDATE
				container
			SET
				parent_container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.parent_container_id#">,
				container_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(arguments.container_type)#">,
				label = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(arguments.label)#">,
				description = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(arguments.description)#" null="#len(trim(arguments.description)) EQ 0#">,
				parent_install_date =
					<cfif len(trim(arguments.parent_install_date)) GT 0>
						<cfqueryparam cfsqltype="CF_SQL_DATE" value="#createODBCDate(parseDateTime(arguments.parent_install_date))#">
					<cfelse>
						<cfqueryparam cfsqltype="CF_SQL_DATE" value="" null="yes">
					</cfif>,
				container_remarks = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(arguments.container_remarks)#" null="#len(trim(arguments.container_remarks)) EQ 0#">,
				barcode = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(arguments.barcode)#" null="#len(trim(arguments.barcode)) EQ 0#">,
				width = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#trim(arguments.width)#" null="#len(trim(arguments.width)) EQ 0#">,
				height = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#trim(arguments.height)#" null="#len(trim(arguments.height)) EQ 0#">,
				length = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#trim(arguments.length)#" null="#len(trim(arguments.length)) EQ 0#">,
				number_positions = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#trim(arguments.number_positions)#" null="#len(trim(arguments.number_positions)) EQ 0#">,
				institution_acronym = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(arguments.institution_acronym)#">
			WHERE
				container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.container_id#">
		</cfquery>
		<cfif val(queryGetExisting.parent_container_id) NEQ val(arguments.parent_container_id)>
			<cfquery name="queryInsertHistory" datasource="user_login" username="#session.dbuser#"  password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
				INSERT INTO container_history (
					container_id,
					parent_container_id,
					install_date
				) VALUES (
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.container_id#">,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#queryGetExisting.parent_container_id#">,
					SYSDATE
				)
			</cfquery>
		</cfif>
		<cfset local.retval["status"] = "saved">
		<cfset local.retval["container_id"] = arguments.container_id>
	<cfcatch>
		<cfset local.error_message = cfcatchToErrorMessage(cfcatch)>
		<cfset local.function_called = "#GetFunctionCalledName()#">
		<cfscript>reportError(function_called="#local.function_called#", error_message="#local.error_message#");</cfscript>
		<cfset local.retval = StructNew()>
		<cfset local.retval["status"] = "error">
		<cfset local.retval["message"] = cfcatch.message>
	</cfcatch>
	</cftry>
	<cfreturn serializeJSON(local.retval)>
</cffunction>

<!---
Function deleteContainer.  Deletes a container record.
--->
<cffunction name="deleteContainer" access="remote" returntype="any" returnformat="json">
	<cfargument name="container_id" type="string" required="yes">

	<cfset local.retval = StructNew()>
	<cfif len(trim(arguments.container_id)) EQ 0 OR NOT isNumeric(arguments.container_id)>
		<cfset local.retval["status"] = "error">
		<cfset local.retval["message"] = "Container id is required.">
		<cfreturn serializeJSON(local.retval)>
	</cfif>

	<cftry>
		<cfquery name="queryCheckChildren" datasource="user_login" username="#session.dbuser#"  password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
			SELECT
				COUNT(*) AS child_count
			FROM
				container
			WHERE
				parent_container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.container_id#">
		</cfquery>
		<cfif queryCheckChildren.child_count GT 0>
			<cfset local.retval["status"] = "error">
			<cfset local.retval["message"] = "Container cannot be deleted because it has children.">
			<cfreturn serializeJSON(local.retval)>
		</cfif>
		<cfquery name="queryDeleteContainer" datasource="user_login" username="#session.dbuser#"  password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
			DELETE FROM
				container
			WHERE
				container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.container_id#">
		</cfquery>
		<cfset local.retval["status"] = "deleted">
	<cfcatch>
		<cfset local.error_message = cfcatchToErrorMessage(cfcatch)>
		<cfset local.function_called = "#GetFunctionCalledName()#">
		<cfscript>reportError(function_called="#local.function_called#", error_message="#local.error_message#");</cfscript>
		<cfset local.retval = StructNew()>
		<cfset local.retval["status"] = "error">
		<cfset local.retval["message"] = cfcatch.message>
	</cfcatch>
	</cftry>
	<cfreturn serializeJSON(local.retval)>
</cffunction>

<!---
Function getContainerDetailsHtml.  Returns an HTML fragment with the read-only
details of a container for use in dialogs and page components.
--->
<cffunction name="getContainerDetailsHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="container_id" type="numeric" required="yes">
	<cfargument name="displayMode" type="string" required="no" default="page">
	<cfargument name="idSuffix" type="string" required="no" default="">
	<cfargument name="showBrowseAction" type="string" required="no" default="true">

	<cfset local.tn = REReplace(createUUID(), "-", "", "all")>
	<cfset local.safeDisplayMode = lCase(trim(arguments.displayMode))>
	<cfif local.safeDisplayMode NEQ "dialog">
		<cfset local.safeDisplayMode = "page">
	</cfif>
	<cfset local.safeIdSuffix = REReplace(arguments.idSuffix, "[^A-Za-z0-9_-]", "", "all")>
	<cfset local.safeIdSuffix = REReplace(local.safeIdSuffix, "^_+", "", "all")>
	<cfset local.showBrowseAction = true>
	<cfif isBoolean(arguments.showBrowseAction)>
		<cfset local.showBrowseAction = javacast("boolean", arguments.showBrowseAction)>
	<cfelseif listFindNoCase("0,false,no", trim(arguments.showBrowseAction))>
		<cfset local.showBrowseAction = false>
	</cfif>
	<cfthread
		name="getContainerDetailsHtmlThread#local.tn#"
		container_id="#arguments.container_id#"
		safeDisplayMode="#local.safeDisplayMode#"
		safeIdSuffix="#local.safeIdSuffix#"
		showBrowseAction="#local.showBrowseAction#"
	>
		<cfoutput>
			<cftry>
				<cfquery name="getContainerDetail" datasource="user_login" username="#session.dbuser#"  password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
					SELECT
						c.container_id,
						c.parent_container_id,
						c.container_type,
						c.label,
						c.description,
						c.parent_install_date,
						c.container_remarks,
						c.barcode,
						c.width,
						c.height,
						c.length,
						c.number_positions,
						c.locked_position,
						c.institution_acronym,
						ct.role AS container_role,
						NVL(ch.direct_structural_children, 0) AS direct_structural_children,
						NVL(ch.direct_leaf_children, 0) AS direct_leaf_children,
						p.container_type AS parent_container_type,
						p.label AS parent_label,
						p.barcode AS parent_barcode
					FROM
						container c
						LEFT JOIN (
							SELECT
								parent_container_id,
								SUM(CASE WHEN container_type <> 'collection object' THEN 1 ELSE 0 END) AS direct_structural_children,
								SUM(CASE WHEN container_type = 'collection object' THEN 1 ELSE 0 END) AS direct_leaf_children
							FROM
								container
							GROUP BY
								parent_container_id
						) ch ON ch.parent_container_id = c.container_id
						LEFT JOIN ctcontainer_type ct ON ct.container_type = c.container_type
						LEFT JOIN container p ON c.parent_container_id = p.container_id
					WHERE
						c.container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#container_id#">
				</cfquery>
				<cfif getContainerDetail.recordcount EQ 0>
					<p class="text-danger">Container not found.</p>
				<cfelse>
					<cfquery name="queryCountCOChildren" datasource="user_login" username="#session.dbuser#"  password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
						SELECT
							COUNT(*) AS leaf_descendants
						FROM (
							SELECT
								container_type
							FROM
								container
							START WITH
								container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getContainerDetail.container_id#">
							CONNECT BY NOCYCLE PRIOR
								container_id = parent_container_id
						) subtree
						WHERE
							subtree.container_type = 'collection object'
					</cfquery>
					<cfset formattedIdSuffix = "">
					<cfif len(trim(safeIdSuffix)) GT 0>
						<cfset formattedIdSuffix = "_#safeIdSuffix#">
					</cfif>
					<cfset breadcrumbNavId = "container_breadcrumb_nav#formattedIdSuffix#">
					<cfset breadcrumbFeedbackId = "container_breadcrumb_feedback#formattedIdSuffix#">
					<cfset contextHeadingId = "containerContextHeading#formattedIdSuffix#">
					<cfset detailsHeadingId = "containerDetailsHeading#formattedIdSuffix#">
					<cfset contentsHeadingId = "containerContentsSummaryHeading#formattedIdSuffix#">
					<cfset positionsHeadingId = "containerPositionsHeading#formattedIdSuffix#">
					<cfset positionsTargetId = "containerPositionsGrid#formattedIdSuffix#">
					<cfset roleBadgeId = "containerRoleBadge#formattedIdSuffix#">
					<cfset viewContainerUrl = "/containers/viewContainer.cfm?container_id=#encodeForURL(getContainerDetail.container_id)#">
					<cfset editContainerUrl = "/containers/Container.cfm?action=edit&container_id=#encodeForURL(getContainerDetail.container_id)#">
					<cfset createChildContainerUrl = "/containers/Container.cfm?action=new&parent_container_id=#encodeForURL(getContainerDetail.container_id)#">
					<cfset browseTreeUrl = "/containers/Containers.cfm?container_id=#encodeForURL(getContainerDetail.container_id)#&execute=true">
					<cfset leafNodesUrl = "/containers/allContainerLeafNodes.cfm?container_id=#encodeForURL(getContainerDetail.container_id)#">
					<cfset specimenSearchUrl = "">
					<cfif len(trim(getContainerDetail.barcode)) GT 0>
						<cfset specimenSearchUrl = "/Specimens.cfm?action=fixedSearch&execute=true&root_container_barcode=%3D#encodeForURL(getContainerDetail.barcode)#">
					</cfif>
					<cfset isProxyOrLeafType = listFindNoCase("proxy,leaf", getContainerDetail.container_role) GT 0>
					<cfset parentDisplay = "Unnamed container">
					<cfif len(trim(getContainerDetail.parent_label)) GT 0>
						<cfset parentDisplay = getContainerDetail.parent_label>
					</cfif>
					<cfif len(trim(getContainerDetail.parent_barcode)) GT 0>
						<cfset parentDisplay = getContainerDetail.parent_barcode>
						<cfif getContainerDetail.parent_barcode NEQ getContainerDetail.parent_label AND len(trim(getContainerDetail.parent_label)) GT 0>
							<cfset parentDisplay = "#parentDisplay# (#getContainerDetail.parent_label#)">
						</cfif>
					</cfif>
					<cfset lockedPositionText = "No">
					<cfif val(getContainerDetail.locked_position) EQ 1>
						<cfset lockedPositionText = "Yes">
					</cfif>
					<cfif queryCountCOChildren.leaf_descendants GT 0 AND queryCountCOChildren.leaf_descendants LTE 5>
						<cfquery name="queryCollectionObjectDetails" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
							SELECT
								c.container_id,
								c.barcode AS container_barcode,
								c.label AS container_label,
								spec.cat_num,
								spec.collection_cde,
								spec.institution_acronym,
								spec.scientific_name,
								spec.part_name,
								spec.preserve_method
							FROM container c
							LEFT JOIN (
								SELECT
									coch.container_id,
									MAX(ci.cat_num) AS cat_num,
									MAX(ci.collection_cde) AS collection_cde,
									MAX(col.institution_acronym) AS institution_acronym,
									MIN(id_sub.scientific_name) AS scientific_name,
									MAX(sp.part_name) AS part_name,
									MAX(sp.preserve_method) AS preserve_method
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
							WHERE c.container_id IN (
								SELECT container_id
								FROM container
								START WITH container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getContainerDetail.container_id#">
								CONNECT BY NOCYCLE PRIOR container_id = parent_container_id
							)
							AND c.container_type = 'collection object'
							AND c.container_id <> <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getContainerDetail.container_id#">
							ORDER BY c.label
						</cfquery>
					</cfif>
					<section class="mb-3" aria-labelledby="#encodeForHtmlAttribute(contextHeadingId)#">
						<div class="row">
							<div class="col-12">
								<div class="row">
									<div class="col-12 col-lg-6 mb-2 mb-lg-0">
										<h2 class="h4 mb-0" id="#encodeForHtmlAttribute(contextHeadingId)#">Context</h2>
									</div>
									<cfif safeDisplayMode EQ "dialog">
										<div class="col-12 col-lg-6">
											<div class="text-lg-right">
												<div class="btn-toolbar justify-content-lg-end" role="toolbar" aria-label="Container quick actions">
													<cfif NOT isProxyOrLeafType>
														<a href="#createChildContainerUrl#" class="btn btn-xs btn-success mr-1 mb-1" target="_blank" rel="noopener noreferrer">Create Child of this Container</a>
													</cfif>
													<a href="#viewContainerUrl#" class="btn btn-xs btn-primary mr-1 mb-1" target="_blank" rel="noopener noreferrer">View</a>
													<a href="#editContainerUrl#" class="btn btn-xs btn-secondary mr-1 mb-1" target="_blank" rel="noopener noreferrer">Edit</a>
													<cfif showBrowseAction>
														<a href="#browseTreeUrl#" class="btn btn-xs btn-info mb-1" target="_blank" rel="noopener noreferrer">Browse in Hierarchy</a>
													</cfif>
												</div>
											</div>
										</div>
									</cfif>
								</div>
							</div>
							<div class="col-12">
								<nav aria-label="Container breadcrumb" class="mb-2" id="#encodeForHtmlAttribute(breadcrumbNavId)#"></nav>
								<output id="#encodeForHtmlAttribute(breadcrumbFeedbackId)#"></output>
							</div>
						</div>
						<script>
							$(document).ready(function() {
								var roleBadgeTarget = document.getElementById('#encodeForJavaScript(roleBadgeId)#');
								showContainerBreadcrumb("#encodeForJavaScript(getContainerDetail.container_id)#", "#encodeForJavaScript(breadcrumbFeedbackId)#", "#encodeForJavaScript(breadcrumbNavId)#");
								ensureContainerTypeMetadata(function() {
									if (roleBadgeTarget) {
										roleBadgeTarget.innerHTML = getContainerRoleBadgeHtml("#encodeForJavaScript(getContainerDetail.container_type)#");
									}
									<cfif val(getContainerDetail.number_positions) GT 0>
										loadPositionsGrid(#getContainerDetail.container_id#, #getContainerDetail.number_positions#, "#encodeForJavaScript(positionsTargetId)#", "#encodeForJavaScript(breadcrumbFeedbackId)#");
									</cfif>
								});
							});
						</script>
					</section>
					<section class="mb-3 border rounded bg-light p-3" aria-labelledby="#encodeForHtmlAttribute(detailsHeadingId)#">
						<h2 class="h5" id="#encodeForHtmlAttribute(detailsHeadingId)#">Details</h2>
						<div class="form-row">
							<div class="col-12 col-md-6 col-xl-4 mb-2">
								<strong>Container Type:</strong> #encodeForHtml(getContainerDetail.container_type)# <span id="#encodeForHtmlAttribute(roleBadgeId)#"></span>
							</div>
							<div class="col-12 col-md-6 col-xl-4 mb-2">
								<strong>Label:</strong> #encodeForHtml(getContainerDetail.label)#
							</div>
							<cfif len(trim(getContainerDetail.barcode)) GT 0>
								<div class="col-12 col-md-6 col-xl-4 mb-2">
									<strong>Barcode:</strong> #encodeForHtml(getContainerDetail.barcode)#
								</div>
							</cfif>
							<cfif len(trim(getContainerDetail.description)) GT 0>
								<div class="col-12 col-md-6 col-xl-4 mb-2">
									<strong>Description:</strong> #encodeForHtml(getContainerDetail.description)#
								</div>
							</cfif>
							<cfif len(trim(getContainerDetail.container_remarks)) GT 0>
								<div class="col-12 col-md-6 col-xl-4 mb-2">
									<strong>Container Remarks:</strong> #encodeForHtml(getContainerDetail.container_remarks)#
								</div>
							</cfif>
							<cfif len(trim(getContainerDetail.width)) GT 0 OR len(trim(getContainerDetail.height)) GT 0 OR len(trim(getContainerDetail.length)) GT 0>
								<div class="col-12 col-md-6 col-xl-4 mb-2">
									<strong>Width × Height × Length (cm):</strong>
									#encodeForHtml(getContainerDetail.width)# × #encodeForHtml(getContainerDetail.height)# × #encodeForHtml(getContainerDetail.length)#
								</div>
							</cfif>
							<cfif len(trim(getContainerDetail.number_positions)) GT 0>
								<div class="col-12 col-md-6 col-xl-4 mb-2">
									<strong>Number of Positions:</strong> #encodeForHtml(getContainerDetail.number_positions)#
								</div>
							</cfif>
							<div class="col-12 col-md-6 col-xl-4 mb-2">
								<strong>Locked Position:</strong> #encodeForHtml(lockedPositionText)#
							</div>
							<div class="col-12 col-md-6 col-xl-4 mb-2">
								<strong>Institution Acronym:</strong> #encodeForHtml(getContainerDetail.institution_acronym)#
							</div>
							<div class="col-12 col-md-6 col-xl-4 mb-2">
								<strong>Placement Date:</strong>
								<cfif isDate(getContainerDetail.parent_install_date)>
									#encodeForHtml(dateFormat(getContainerDetail.parent_install_date, "yyyy-mm-dd"))#
								</cfif>
							</div>
							<div class="col-12 mb-2">
								<strong>Current Parent:</strong>
								<cfif val(getContainerDetail.parent_container_id) GT 0>
									#encodeForHtml(getContainerDetail.parent_container_type)#:
									<a href="/containers/viewContainer.cfm?container_id=#encodeForURL(getContainerDetail.parent_container_id)#">#encodeForHtml(parentDisplay)#</a>
								<cfelse>
									<span class="text-muted">This container has no current parent container record.</span>
								</cfif>
							</div>
						</div>
					</section>
					<section class="mb-3" aria-labelledby="#encodeForHtmlAttribute(contentsHeadingId)#">
						<h2 class="h4" id="#encodeForHtmlAttribute(contentsHeadingId)#">Contents</h2>
						<div class="form-row mb-1">
							<div class="col-12 col-lg-4 mb-1">
								<h3 class="h4">Structural Contents:</h3>
								<cfif val(getContainerDetail.direct_structural_children) GT 0>
									<a href="#browseTreeUrl#">
										Browse #encodeForHtml(getContainerDetail.direct_structural_children)# structural children in the tree
									</a>
								<cfelse>
									<span class="text-muted">0 structural children</span>
								</cfif>
							</div>
							<div class="col-12 col-lg-4 mb-1">
								<h3 class="h4">Object Contents:</h3>
								<cfif val(getContainerDetail.direct_leaf_children) GT 0>
									<a href="#leafNodesUrl#">
										Browse #encodeForHtml(getContainerDetail.direct_leaf_children)# direct leaf children
									</a>
								<cfelse>
									<span class="text-muted">0 direct leaf children</span>
								</cfif>
							</div>
							<div class="col-12 col-lg-4 mb-1">
								<h3 class="h4">Collection Objects:</h3>
								<cfif queryCountCOChildren.leaf_descendants EQ 0>
									<span class="text-muted">No Collection Objects in this container or its children</span>
								<cfelse>
									<span class="text-muted">#encodeForHtml(queryCountCOChildren.leaf_descendants)# contained</span>
									<cfif len(specimenSearchUrl) GT 0>
										<a href="#specimenSearchUrl#" class="btn btn-xs btn-outline-info ml-1" target="_blank" rel="noopener noreferrer">Specimens</a>
									</cfif>
								</cfif>
							</div>
						</div>
						<cfif queryCountCOChildren.leaf_descendants GT 0 AND queryCountCOChildren.leaf_descendants LTE 5>
							<div class="table-responsive mt-2">
								<table class="table table-sm table-striped">
									<thead>
										<tr>
											<th scope="col">GUID</th>
											<th scope="col">Current Identification</th>
											<th scope="col">Part Type</th>
											<th scope="col">Preservation</th>
										</tr>
									</thead>
									<tbody>
										<cfloop query="queryCollectionObjectDetails">
											<cfset coGuidText = "">
											<cfset coGuidUrl = "">
											<cfif len(trim(institution_acronym)) GT 0 AND len(trim(collection_cde)) GT 0 AND len(trim(cat_num)) GT 0>
												<cfset coGuidText = "#institution_acronym#:#collection_cde#:#cat_num#">
												<cfset coGuidUrl = "/guid/#encodeForURL(institution_acronym)#:#encodeForURL(collection_cde)#:#encodeForURL(cat_num)#">
											</cfif>
											<tr>
												<td>
													<cfif len(coGuidText) GT 0>
														<a href="#coGuidUrl#" target="_blank" rel="noopener noreferrer">#encodeForHtml(coGuidText)#</a>
													<cfelse>
														<span class="text-muted">No specimen linked</span>
													</cfif>
												</td>
												<td>
													<cfif len(trim(scientific_name)) GT 0>
														<em>#encodeForHtml(scientific_name)#</em>
													<cfelse>
														<span class="text-muted">—</span>
													</cfif>
												</td>
												<td>
													<cfif len(trim(part_name)) GT 0>
														#encodeForHtml(part_name)#
													<cfelse>
														<span class="text-muted">—</span>
													</cfif>
												</td>
												<td>
													<cfif len(trim(preserve_method)) GT 0>
														#encodeForHtml(preserve_method)#
													<cfelse>
														<span class="text-muted">—</span>
													</cfif>
												</td>
											</tr>
										</cfloop>
									</tbody>
								</table>
							</div>
						</cfif>
					</section>
					<cfif val(getContainerDetail.number_positions) GT 0>
						<section class="mb-3" aria-labelledby="#encodeForHtmlAttribute(positionsHeadingId)#">
							<h2 class="h4" id="#encodeForHtmlAttribute(positionsHeadingId)#">Positions</h2>
							<div id="#encodeForHtmlAttribute(positionsTargetId)#"><div class="my-2 text-center"><img src="/shared/images/indicator.gif"> Loading...</div></div>
						</section>
					</cfif>
				</cfif>
			<cfcatch>
				<cfset error_message = cfcatchToErrorMessage(cfcatch)>
				<cfset function_called = "#GetFunctionCalledName()#">
				<cfscript>reportError(function_called="#function_called#", error_message="#error_message#");</cfscript>
				<p class="text-danger">Unable to load container details.</p>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="getContainerDetailsHtmlThread#local.tn#" />
	<cfreturn cfthread["getContainerDetailsHtmlThread#local.tn#"].output>
</cffunction>

<!---
Function getContainerEditHtml.  Returns an HTML fragment containing the container
edit form suitable for rendering in a dialog box or embedded in another page.
--->
<cffunction name="getContainerEditHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="container_id" type="numeric" required="yes">
	<cfargument name="idSuffix" type="string" required="no" default="">

	<cfset local.tn = REReplace(createUUID(), "-", "", "all")>
	<cfset local.safeIdSuffix = REReplace(arguments.idSuffix, "[^A-Za-z0-9_-]", "", "all")>
	<cfthread name="getContainerEditHtmlThread#local.tn#" container_id="#arguments.container_id#" idSuffix="#local.safeIdSuffix#">
		<cfoutput>
			<cftry>
				<cfquery name="ctContainerType" datasource="user_login" username="#session.dbuser#"  password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
					SELECT
						container_type
					FROM
						ctcontainer_type
					ORDER BY
						container_type
				</cfquery>
				<cfquery name="getContainerEdit" datasource="user_login" username="#session.dbuser#"  password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
					SELECT
						c.container_id,
						c.parent_container_id,
						c.container_type,
						c.label,
						c.description,
						c.parent_install_date,
						c.container_remarks,
						c.barcode,
						c.width,
						c.height,
						c.length,
						c.number_positions,
						c.institution_acronym,
						p.label AS parent_label,
						p.barcode AS parent_barcode
					FROM
						container c
						LEFT JOIN container p ON c.parent_container_id = p.container_id
					WHERE
						c.container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#container_id#">
				</cfquery>
				<cfif getContainerEdit.recordcount EQ 0>
					<p class="text-danger">Container not found.</p>
				<cfelse>
					<cfset parentContainerText = "">
					<cfif len(trim(getContainerEdit.parent_barcode)) GT 0>
						<cfset parentContainerText = getContainerEdit.parent_barcode>
					<cfelseif len(trim(getContainerEdit.parent_label)) GT 0>
						<cfset parentContainerText = getContainerEdit.parent_label>
					</cfif>
					<cfset installDate = "">
					<cfif isDate(getContainerEdit.parent_install_date)>
						<cfset installDate = dateFormat(getContainerEdit.parent_install_date, "yyyy-mm-dd")>
					</cfif>
					<section class="row mx-0 border rounded my-2 pt-2 mb-4" aria-labelledby="containerDialogFormHeading#encodeForHtml(idSuffix)#">
						<div class="col-12">
							<h2 class="h4 ml-3 mb-1" id="containerDialogFormHeading#encodeForHtml(idSuffix)#">Edit Container</h2>
							<div class="mb-2" role="status" aria-live="polite">
								<output id="containerSaveStatus#encodeForHtml(idSuffix)#">&nbsp;</output>
							</div>
							<form class="col-12 px-0" id="containerForm#encodeForHtml(idSuffix)#" name="containerForm#encodeForHtml(idSuffix)#" method="post" novalidate>
								<input type="hidden" name="container_id" id="container_id#encodeForHtml(idSuffix)#" value="#encodeForHtml(getContainerEdit.container_id)#">
								<div class="form-row">
									<div class="col-12 col-md-6 col-xl-4 mb-2">
										<label for="container_type#encodeForHtml(idSuffix)#" class="data-entry-label">Container Type</label>
										<select name="container_type" id="container_type#encodeForHtml(idSuffix)#" class="data-entry-select reqdClr col-12" required aria-required="true">
											<option value=""></option>
											<cfloop query="ctContainerType">
												<cfset selectedType = "">
												<cfif ctContainerType.container_type EQ getContainerEdit.container_type>
													<cfset selectedType = " selected">
												</cfif>
												<option value="#encodeForHtml(ctContainerType.container_type)#"#selectedType#>#encodeForHtml(ctContainerType.container_type)#</option>
											</cfloop>
										</select>
									</div>
									<div class="col-12 col-md-6 col-xl-4 mb-2">
										<label for="label#encodeForHtml(idSuffix)#" class="data-entry-label">Label</label>
										<input type="text" name="label" id="label#encodeForHtml(idSuffix)#" class="data-entry-input col-12 reqdClr" required aria-required="true" value="#encodeForHtml(getContainerEdit.label)#">
									</div>
									<div class="col-12 col-md-6 col-xl-4 mb-2">
										<label for="barcode#encodeForHtml(idSuffix)#" class="data-entry-label">Barcode</label>
										<input type="text" name="barcode" id="barcode#encodeForHtml(idSuffix)#" class="data-entry-input col-12" value="#encodeForHtml(getContainerEdit.barcode)#">
									</div>
								</div>
								<div class="form-row">
									<div class="col-12 col-md-6 col-xl-4 mb-2">
										<label for="parentContainerText#encodeForHtml(idSuffix)#" class="data-entry-label">Parent Container</label>
										<input type="hidden" name="parent_container_id" id="parent_container_id#encodeForHtml(idSuffix)#" value="#encodeForHtml(getContainerEdit.parent_container_id)#">
										<input type="text" name="parentContainerText" id="parentContainerText#encodeForHtml(idSuffix)#" class="data-entry-input col-12 reqdClr" required aria-required="true" value="#encodeForHtml(parentContainerText)#">
									</div>
									<div class="col-12 col-md-6 col-xl-4 mb-2">
										<label for="parent_install_date#encodeForHtml(idSuffix)#" class="data-entry-label">Placement Date</label>
										<input type="text" name="parent_install_date" id="parent_install_date#encodeForHtml(idSuffix)#" class="data-entry-input col-12" value="#encodeForHtml(installDate)#">
									</div>
									<div class="col-12 col-md-6 col-xl-4 mb-2">
										<label for="description#encodeForHtml(idSuffix)#" class="data-entry-label">Description</label>
										<input type="text" name="description" id="description#encodeForHtml(idSuffix)#" class="data-entry-input col-12" value="#encodeForHtml(getContainerEdit.description)#">
									</div>
								</div>
								<div class="form-row">
									<div class="col-12 mb-2">
										<label for="container_remarks#encodeForHtml(idSuffix)#" class="data-entry-label">Container Remarks</label>
										<textarea name="container_remarks" id="container_remarks#encodeForHtml(idSuffix)#" rows="3" class="data-entry-input col-12">#encodeForHtml(getContainerEdit.container_remarks)#</textarea>
									</div>
								</div>
								<div class="form-row">
									<div class="col-12 col-md-6 col-xl-4 mb-2">
										<label for="width#encodeForHtml(idSuffix)#" class="data-entry-label">Width (cm)</label>
										<input type="text" name="width" id="width#encodeForHtml(idSuffix)#" class="data-entry-input col-12" value="#encodeForHtml(getContainerEdit.width)#">
									</div>
									<div class="col-12 col-md-6 col-xl-4 mb-2">
										<label for="height#encodeForHtml(idSuffix)#" class="data-entry-label">Height (cm)</label>
										<input type="text" name="height" id="height#encodeForHtml(idSuffix)#" class="data-entry-input col-12" value="#encodeForHtml(getContainerEdit.height)#">
									</div>
									<div class="col-12 col-md-6 col-xl-4 mb-2">
										<label for="length#encodeForHtml(idSuffix)#" class="data-entry-label">Length (cm)</label>
										<input type="text" name="length" id="length#encodeForHtml(idSuffix)#" class="data-entry-input col-12" value="#encodeForHtml(getContainerEdit.length)#">
									</div>
								</div>
								<div class="form-row">
									<div class="col-12 col-md-6 col-xl-4 mb-2">
										<label for="number_positions#encodeForHtml(idSuffix)#" class="data-entry-label">Number of Positions</label>
										<input type="text" name="number_positions" id="number_positions#encodeForHtml(idSuffix)#" class="data-entry-input col-12" value="#encodeForHtml(getContainerEdit.number_positions)#">
									</div>
									<div class="col-12 col-md-6 col-xl-4 mb-2">
										<label for="institution_acronym#encodeForHtml(idSuffix)#" class="data-entry-label">Institution Acronym</label>
										<input type="text" name="institution_acronym" id="institution_acronym#encodeForHtml(idSuffix)#" class="data-entry-input col-12" value="#encodeForHtml(getContainerEdit.institution_acronym)#">
									</div>
								</div>
								<div class="form-row mb-4 mt-1">
									<div class="col-12">
										<button type="button" class="btn btn-xs btn-primary" onclick="saveContainerForm('containerForm#encodeForHtml(idSuffix)#', 'saveContainer', 'containerSaveStatus#encodeForHtml(idSuffix)#')">Save Changes</button>
									</div>
								</div>
							</form>
						</div>
					</section>
				</cfif>
			<cfcatch>
				<cfset error_message = cfcatchToErrorMessage(cfcatch)>
				<cfset function_called = "#GetFunctionCalledName()#">
				<cfscript>reportError(function_called="#function_called#", error_message="#error_message#");</cfscript>
				<p class="text-danger">Unable to load container edit form.</p>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="getContainerEditHtmlThread#local.tn#" />
	<cfreturn cfthread["getContainerEditHtmlThread#local.tn#"].output>
</cffunction>


<!---
Function getOrphanedEmptyProxyContainers.  Returns a paginated list of empty proxy-role
containers located at institution or root level.

@param page the page number to return (1-based), defaults to 1.
@param pageSize the number of rows per page, defaults to 50.
@return a JSON object with keys rows (array), page, pageSize, totalRows.
--->
<cffunction name="getOrphanedEmptyProxyContainers" access="remote" returntype="any" returnformat="json">
	<cfargument name="page" type="numeric" required="no" default="1">
	<cfargument name="pageSize" type="numeric" required="no" default="50">

	<cfset local.retval = StructNew()>
	<cftry>
		<cfset local.offset = (arguments.page - 1) * arguments.pageSize>
		<cfquery name="queryGetCount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
			SELECT COUNT(*) AS total_rows
			FROM container c
			WHERE (
				c.parent_container_id IN (
					SELECT container_id
					FROM container
					WHERE parent_container_id = 0
						AND container_type = 'institution'
				)
				OR c.parent_container_id = 0
			)
			AND c.container_type IN (
				SELECT container_type
				FROM ctcontainer_type
				WHERE role = 'proxy'
					AND NVL(expects_leaf_child_count, 0) = 1
			)
			AND NOT EXISTS (
				SELECT 1
				FROM container occ
				WHERE occ.parent_container_id = c.container_id
					AND occ.container_type = 'collection object'
			)
		</cfquery>
		<cfset local.totalRows = queryGetCount.total_rows>
		<cfquery name="queryGetRows" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
			SELECT container_id, container_type, label, barcode, description
			FROM (
				SELECT
					inner_query.*,
					ROWNUM AS rn
				FROM (
					SELECT
						c.container_id,
						c.container_type,
						c.label,
						c.barcode,
						c.description
					FROM container c
					WHERE (
						c.parent_container_id IN (
							SELECT container_id
							FROM container
							WHERE parent_container_id = 0
								AND container_type = 'institution'
						)
						OR c.parent_container_id = 0
					)
					AND c.container_type IN (
						SELECT container_type
						FROM ctcontainer_type
						WHERE role = 'proxy'
							AND NVL(expects_leaf_child_count, 0) = 1
					)
					AND NOT EXISTS (
						SELECT 1
						FROM container occ
						WHERE occ.parent_container_id = c.container_id
							AND occ.container_type = 'collection object'
					)
					ORDER BY c.container_type, c.label, c.barcode, c.container_id
				) inner_query
				WHERE ROWNUM <= <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#local.offset + arguments.pageSize#">
			)
			WHERE rn > <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#local.offset#">
		</cfquery>
		<cfset local.rows = ArrayNew(1)>
		<cfset local.i = 1>
		<cfloop query="queryGetRows">
			<cfset local.row = StructNew()>
			<cfset local.row["container_id"] = queryGetRows.container_id>
			<cfset local.row["container_type"] = queryGetRows.container_type>
			<cfset local.row["label"] = queryGetRows.label>
			<cfset local.row["barcode"] = queryGetRows.barcode>
			<cfset local.row["description"] = queryGetRows.description>
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
Function getOrphanedSingleOccupantContainers.  Returns a paginated list of proxy-role
single-occupant containers located at institution or root level that have at least one
contained collection-object child, along with linked specimen data from the first such child.

@param page the page number to return (1-based), defaults to 1.
@param pageSize the number of rows per page, defaults to 50.
@return a JSON object with keys rows (array), page, pageSize, totalRows.
--->
<cffunction name="getOrphanedSingleOccupantContainers" access="remote" returntype="any" returnformat="json">
	<cfargument name="page" type="numeric" required="no" default="1">
	<cfargument name="pageSize" type="numeric" required="no" default="50">

	<cfset local.retval = StructNew()>
	<cftry>
		<cfset local.offset = (arguments.page - 1) * arguments.pageSize>
		<cfquery name="queryGetCount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
			SELECT COUNT(*) AS total_rows
			FROM container c
			WHERE (
				c.parent_container_id IN (
					SELECT container_id
					FROM container
					WHERE parent_container_id = 0
						AND container_type = 'institution'
				)
				OR c.parent_container_id = 0
			)
			AND c.container_type IN (
				SELECT container_type
				FROM ctcontainer_type
				WHERE role = 'proxy'
					AND NVL(expects_leaf_child_count, 0) = 1
			)
			AND EXISTS (
				SELECT 1
				FROM container occ
				WHERE occ.parent_container_id = c.container_id
					AND occ.container_type = 'collection object'
			)
		</cfquery>
		<cfset local.totalRows = queryGetCount.total_rows>
		<cfquery name="queryGetRows" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
			SELECT container_id, container_type, label, barcode, description,
				occupant_container_id, occupant_label, occupant_barcode,
				cat_num, collection_cde, institution_acronym, part_name, scientific_name
			FROM (
				SELECT
					inner_query.*,
					ROWNUM AS rn
				FROM (
					SELECT
						c.container_id,
						c.container_type,
						c.label,
						c.barcode,
						c.description,
						occ.container_id AS occupant_container_id,
						occ.label AS occupant_label,
						occ.barcode AS occupant_barcode,
						spec.cat_num,
						spec.collection_cde,
						spec.institution_acronym,
						spec.part_name,
						spec.scientific_name
					FROM container c
					LEFT JOIN (
						SELECT parent_container_id, container_id, label, barcode
						FROM (
							SELECT
								parent_container_id,
								container_id,
								label,
								barcode,
								ROW_NUMBER() OVER (PARTITION BY parent_container_id ORDER BY label, barcode, container_id) AS rn
							FROM container
							WHERE container_type = 'collection object'
						)
						WHERE rn = 1
					) occ ON occ.parent_container_id = c.container_id
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
					) spec ON spec.container_id = occ.container_id
					WHERE (
						c.parent_container_id IN (
							SELECT container_id
							FROM container
							WHERE parent_container_id = 0
								AND container_type = 'institution'
						)
						OR c.parent_container_id = 0
					)
					AND c.container_type IN (
						SELECT container_type
						FROM ctcontainer_type
						WHERE role = 'proxy'
							AND NVL(expects_leaf_child_count, 0) = 1
					)
					AND EXISTS (
						SELECT 1
						FROM container occ_check
						WHERE occ_check.parent_container_id = c.container_id
							AND occ_check.container_type = 'collection object'
					)
					ORDER BY c.container_type, c.label, c.barcode, c.container_id
				) inner_query
				WHERE ROWNUM <= <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#local.offset + arguments.pageSize#">
			)
			WHERE rn > <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#local.offset#">
		</cfquery>
		<cfset local.rows = ArrayNew(1)>
		<cfset local.i = 1>
		<cfloop query="queryGetRows">
			<cfset local.row = StructNew()>
			<cfset local.row["container_id"] = queryGetRows.container_id>
			<cfset local.row["container_type"] = queryGetRows.container_type>
			<cfset local.row["label"] = queryGetRows.label>
			<cfset local.row["barcode"] = queryGetRows.barcode>
			<cfset local.row["description"] = queryGetRows.description>
			<cfset local.row["occupant_container_id"] = queryGetRows.occupant_container_id>
			<cfset local.row["occupant_label"] = queryGetRows.occupant_label>
			<cfset local.row["occupant_barcode"] = queryGetRows.occupant_barcode>
			<cfset local.row["cat_num"] = queryGetRows.cat_num>
			<cfset local.row["collection_cde"] = queryGetRows.collection_cde>
			<cfset local.row["institution_acronym"] = queryGetRows.institution_acronym>
			<cfset local.row["part_name"] = queryGetRows.part_name>
			<cfset local.row["scientific_name"] = queryGetRows.scientific_name>
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
Function getContainerPositionsGrid.  Returns the position children of a container and the first
contained occupant of each position for rendering a read-only grid.

@param container_id the container_id whose position children are returned.
@return a JSON object with keys container_id, number_positions, positions.
--->
<cffunction name="getContainerPositionsGrid" access="remote" returntype="any" returnformat="json">
	<cfargument name="container_id" type="numeric" required="yes">

	<cfset local.retval = StructNew()>
	<cftry>
		<cfquery name="queryGetContainer" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
			SELECT container_id, number_positions
			FROM container
			WHERE container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.container_id#">
		</cfquery>
		<cfset local.retval["container_id"] = arguments.container_id>
		<cfset local.retval["number_positions"] = 0>
		<cfset local.retval["positions"] = ArrayNew(1)>
		<cfif queryGetContainer.recordcount EQ 1>
			<cfset local.retval["number_positions"] = queryGetContainer.number_positions>
			<cfquery name="queryGetPositions" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
				SELECT
					pos.container_id AS position_id,
					pos.label AS position_label,
					occ.container_id AS content_container_id,
					occ.container_type AS content_container_type,
					occ.label AS content_label,
					occ.barcode AS content_barcode
				FROM container pos
				LEFT JOIN (
					SELECT parent_container_id, container_id, container_type, label, barcode
					FROM (
						SELECT
							parent_container_id,
							container_id,
							container_type,
							label,
							barcode,
							ROW_NUMBER() OVER (PARTITION BY parent_container_id ORDER BY label, barcode, container_id) AS rn
						FROM container
					)
					WHERE rn = 1
				) occ ON occ.parent_container_id = pos.container_id
				WHERE pos.parent_container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.container_id#">
					AND pos.container_type = 'position'
				ORDER BY
					CASE WHEN REGEXP_LIKE(pos.label, '^[0-9]+$') THEN TO_NUMBER(pos.label) END NULLS LAST,
					pos.label,
					pos.container_id
			</cfquery>
			<cfset local.positions = ArrayNew(1)>
			<cfset local.i = 1>
			<cfloop query="queryGetPositions">
				<cfset local.position = StructNew()>
				<cfset local.position["position_id"] = queryGetPositions.position_id>
				<cfset local.position["position_label"] = queryGetPositions.position_label>
				<cfset local.position["content_container_id"] = queryGetPositions.content_container_id>
				<cfset local.position["content_container_type"] = queryGetPositions.content_container_type>
				<cfset local.position["content_label"] = queryGetPositions.content_label>
				<cfset local.position["content_barcode"] = queryGetPositions.content_barcode>
				<cfset local.positions[local.i] = local.position>
				<cfset local.i = local.i + 1>
			</cfloop>
			<cfset local.retval["positions"] = local.positions>
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

</cfcomponent>
