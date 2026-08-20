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
				sc.single_child_container_id,
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
					SELECT parent_container_id, container_id AS single_child_container_id, barcode AS single_child_barcode, label AS single_child_label
					FROM (
						SELECT
							container_id,
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
			<cfset local.row["single_child_container_id"] = qChildren.single_child_container_id>
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
			even if coll_obj_cont_hist has anomalous duplicate current entries. 
		--->
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
		<!--- Root-level external containers (e.g., Deaccessioned external container at root level).
			Only external-type containers are shown separately; other non-institution root-level
			containers are subsumed into the orphaned structural / leaf count buttons. 
		--->
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
				AND c.container_type = 'external'
			ORDER BY c.label
		</cfquery>
		<!--- Count orphaned structural nodes: structural-role containers that are either direct
			children of institution nodes OR are at root level (parent_container_id = 0), excluding
			institution and campus which anchor the normal top-level hierarchy. 
		--->
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
			children of institution nodes OR are at root level (parent_container_id = 0). 
		--->
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
				sc.single_child_container_id,
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
				SELECT parent_container_id, container_id AS single_child_container_id, barcode AS single_child_barcode, label AS single_child_label
				FROM (
					SELECT
						container_id,
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
			<cfset local.row["single_child_container_id"] = queryGetOrphans.single_child_container_id>
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

	<cftransaction>
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
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" scale="4" value="#trim(arguments.width)#" null="#len(trim(arguments.width)) EQ 0#">,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" scale="4" value="#trim(arguments.height)#" null="#len(trim(arguments.height)) EQ 0#">,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" scale="4" value="#trim(arguments.length)#" null="#len(trim(arguments.length)) EQ 0#">,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#trim(arguments.number_positions)#" null="#len(trim(arguments.number_positions)) EQ 0#">,
					<cfqueryparam cfsqltype="CF_SQL_INTEGER" value="0">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(arguments.institution_acronym)#">
				)
			</cfquery>
			<cfset local.retval["status"] = "created">
			<cfset local.retval["container_id"] = queryNextId.next_container_id>
			<cftransaction action="commit">
		<cfcatch>
			<cftransaction action="rollback">
			<cfset local.error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset local.function_called = "#GetFunctionCalledName()#">
			<cfscript>reportError(function_called="#local.function_called#", error_message="#local.error_message#");</cfscript>
			<cfset local.retval = StructNew()>
			<cfset local.retval["status"] = "error">
			<cfset local.retval["message"] = cfcatch.message>
		</cfcatch>
		</cftry>
	</cftransaction>
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

	<cftransaction>
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
			<!--- lock type institution, external, and "Deaccesioned" root containers from some edits --->
			<cfset lockedRoot = false>
			<cfif arguments.container_type EQ "institution">
				<cfset lockedRoot = true>
			<cfelseif arguments.container_type EQ "external">
				<cfset lockedRoot = true>
			<cfelseif arguments.label EQ "Deaccessioned"><!--- deprecated special case, rule is now based on container_type of external for deaccessioned --->
				<cfset lockedRoot = true>
			</cfif>

			<cfquery name="queryUpdateContainer" datasource="user_login" username="#session.dbuser#"  password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
				UPDATE
					container
				SET
					<cfif NOT lockedRoot>
						parent_container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.parent_container_id#">,
						container_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(arguments.container_type)#">,
						label = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(arguments.label)#">,
						number_positions = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#trim(arguments.number_positions)#" null="#len(trim(arguments.number_positions)) EQ 0#">,
						barcode = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(arguments.barcode)#" null="#len(trim(arguments.barcode)) EQ 0#">,
					</cfif>
					description = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(arguments.description)#" null="#len(trim(arguments.description)) EQ 0#">,
					parent_install_date =
						<cfif len(trim(arguments.parent_install_date)) GT 0>
							<cfqueryparam cfsqltype="CF_SQL_DATE" value="#createODBCDate(parseDateTime(arguments.parent_install_date))#">
						<cfelse>
							<cfqueryparam cfsqltype="CF_SQL_DATE" value="" null="yes">
						</cfif>,
					container_remarks = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(arguments.container_remarks)#" null="#len(trim(arguments.container_remarks)) EQ 0#">,
					width = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" scale="4" value="#trim(arguments.width)#" null="#len(trim(arguments.width)) EQ 0#">,
					height = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" scale="4" value="#trim(arguments.height)#" null="#len(trim(arguments.height)) EQ 0#">,
					length = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" scale="4" value="#trim(arguments.length)#" null="#len(trim(arguments.length)) EQ 0#">,
					institution_acronym = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(arguments.institution_acronym)#">
				WHERE
					container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.container_id#">
			</cfquery>
			<!--- provided by trigger MCZBASE.GET_CONTAINER_HISTORY --->
			<!---
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
			--->
			<cfset local.retval["status"] = "saved">
			<cfset local.retval["container_id"] = arguments.container_id>
			<cftransaction action="commit">
		<cfcatch>
			<cftransaction action="rollback">
			<cfset local.error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset local.function_called = "#GetFunctionCalledName()#">
			<cfscript>reportError(function_called="#local.function_called#", error_message="#local.error_message#");</cfscript>
			<cfset local.retval = StructNew()>
			<cfset local.retval["status"] = "error">
			<cfset local.retval["message"] = cfcatch.message>
		</cfcatch>
		</cftry>
	</cftransaction>
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

	<cftransaction>
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
			<cftransaction action="commit">
		<cfcatch>
			<cftransaction action="rollback">
			<cfset local.error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset local.function_called = "#GetFunctionCalledName()#">
			<cfscript>reportError(function_called="#local.function_called#", error_message="#local.error_message#");</cfscript>
			<cfset local.retval = StructNew()>
			<cfset local.retval["status"] = "error">
			<cfset local.retval["message"] = cfcatch.message>
		</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn serializeJSON(local.retval)>
</cffunction>

<!---
Function getContainerContentsHtml. Returns the HTML fragment for the Contents section
of container details, loaded separately to avoid delaying initial details render.

@param container_id the container_id whose contents summary should be rendered.
@return HTML fragment string for the Contents section body, including subtree object summary and optional collection object detail rows.
--->
<cffunction name="getContainerContentsHtml" returntype="string" access="remote" returnformat="plain" output="false">
	<cfargument name="container_id" type="numeric" required="yes">

	<cfset local.htmlFragment = "">
	<cftry>
		<cfset local.maxCollectionObjectDetailRows = 5>
		<cfquery name="getContainerSummary" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
			SELECT
				c.container_id,
				c.container_type,
				c.label,
				c.barcode,
				NVL(ch.direct_structural_children, 0) AS direct_structural_children,
				NVL(ch.direct_leaf_children, 0) AS direct_leaf_children
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
			WHERE
				c.container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.container_id#">
		</cfquery>
		<cfif getContainerSummary.recordcount EQ 0>
			<cfreturn '<p class="text-muted mb-0">Container contents could not be loaded.</p>'>
		</cfif>
		<cfquery name="queryCountCOChildren" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
			SELECT
				COUNT(*) AS leaf_descendants
			FROM (
				SELECT
					container_type
				FROM
					container
				START WITH
					container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getContainerSummary.container_id#">
				CONNECT BY NOCYCLE PRIOR
					container_id = parent_container_id
			) subtree
			WHERE
				subtree.container_type = 'collection object'
		</cfquery>
		<cfset local.browseTreeUrl = "/containers/Containers.cfm?container_id=#encodeForURL(getContainerSummary.container_id)#&execute=true">
		<cfset local.leafNodesBaseUrl = "/containers/allContainerLeafNodes.cfm?container_id=#encodeForURL(getContainerSummary.container_id)#">
		<cfset local.specimenSearchUrl = "">
		<cfif len(trim(getContainerSummary.barcode)) GT 0>
			<cfset local.specimenSearchUrl = "/Specimens.cfm?action=fixedSearch&execute=true&root_container_barcode=%3D#encodeForURL(getContainerSummary.barcode)#">
		</cfif>
		<cfif queryCountCOChildren.leaf_descendants GT 0 AND queryCountCOChildren.leaf_descendants LTE local.maxCollectionObjectDetailRows>
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
					spec.part_count,
					spec.part_count_modifier,
					spec.part_remarks,
					spec.preserve_method
				FROM container c
				LEFT JOIN (
					SELECT
						current_co.container_id,
						ci.cat_num,
						ci.collection_cde,
						col.institution_acronym,
						id_sub.scientific_name,
						sp.part_name,
						/* coll_object stores count on lot_* columns; expose as part_* to match container details UI labels. */
						co.lot_count AS part_count,
						co.lot_count_modifier AS part_count_modifier,
						cor.coll_object_remarks AS part_remarks,
						sp.preserve_method
					FROM (
						SELECT
							coch.container_id,
							coch.collection_object_id,
							ROW_NUMBER() OVER (
								PARTITION BY coch.container_id
								/* Defensive tie-breaker: current_container_fg should be unique, but if legacy data has duplicates, prefer latest install_date then lowest collection_object_id. */
								ORDER BY coch.installed_date DESC NULLS LAST, coch.collection_object_id ASC
							) AS rn
						FROM coll_obj_cont_hist coch
						WHERE coch.current_container_fg = 1
					) current_co
					LEFT JOIN specimen_part sp ON sp.collection_object_id = current_co.collection_object_id
					LEFT JOIN coll_object co ON co.collection_object_id = current_co.collection_object_id
					LEFT JOIN (
						SELECT
							collection_object_id,
							coll_object_remarks
						FROM (
							SELECT
								collection_object_id,
								coll_object_remarks,
								ROW_NUMBER() OVER (
									PARTITION BY collection_object_id
									/* Remarks table lacks chronology/priority metadata; lexical ASC is arbitrary but deterministic, not recency-based. */
									ORDER BY coll_object_remarks ASC
								) AS rn
							FROM coll_object_remark
						)
						WHERE rn = 1
					) cor ON cor.collection_object_id = co.collection_object_id
					LEFT JOIN cataloged_item ci ON ci.collection_object_id = sp.derived_from_cat_item
					LEFT JOIN collection col ON col.collection_id = ci.collection_id
					LEFT JOIN (
						SELECT collection_object_id, MIN(scientific_name) AS scientific_name
						FROM identification
						WHERE accepted_id_fg = 1
						GROUP BY collection_object_id
					) id_sub ON id_sub.collection_object_id = ci.collection_object_id
					WHERE current_co.rn = 1
				) spec ON spec.container_id = c.container_id
				WHERE c.container_id IN (
					SELECT container_id
					FROM container
					START WITH container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getContainerSummary.container_id#">
					CONNECT BY NOCYCLE PRIOR container_id = parent_container_id
				)
				AND c.container_type = 'collection object'
				ORDER BY c.label
			</cfquery>
		</cfif>
		<cfsavecontent variable="local.htmlFragment"><cfoutput>
			<div class="form-row mb-1">
				<div class="col-12 col-lg-4 mb-1">
					<h3 class="h4">Structural Contents:</h3>
					<cfif val(getContainerSummary.direct_structural_children) GT 0>
						<a href="#local.browseTreeUrl#">
							<cfif getContainerSummary.direct_structural_children EQ 1>
								Browse 1 structural child in the tree
							<cfelse>
								Browse #encodeForHtml(getContainerSummary.direct_structural_children)# structural children in the tree
							</cfif>
						</a>
					<cfelse>
						<span class="text-muted">0 structural children</span>
					</cfif>
				</div>
				<div class="col-12 col-lg-4 mb-1">
					<h3 class="h4">Object Contents:</h3>
					<cfif val(getContainerSummary.direct_leaf_children) GT 0>
						<a href="#local.leafNodesBaseUrl#&show=immediate">
							<cfif getContainerSummary.direct_leaf_children EQ 1>
								Browse 1 direct leaf child
							<cfelse>
								Browse #encodeForHtml(getContainerSummary.direct_leaf_children)# direct leaf children
							</cfif>
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
						<span class="text-muted">
							#encodeForHtml(queryCountCOChildren.leaf_descendants)#
							<cfif getContainerSummary.container_type NEQ "collection object">
								contained
							</cfif>
						</span>
						<cfif len(local.specimenSearchUrl) GT 0>
							<a href="#local.specimenSearchUrl#" class="btn btn-xs btn-outline-info ml-1" target="_blank" rel="noopener noreferrer">Specimens</a>
						</cfif>
						<a href="#local.leafNodesBaseUrl#" class="btn btn-xs btn-outline-info ml-1" target="_blank" rel="noopener noreferrer">Leaf Node List</a>
					</cfif>
				</div>
			</div>
			<cfif queryCountCOChildren.leaf_descendants GT 0 AND queryCountCOChildren.leaf_descendants LTE local.maxCollectionObjectDetailRows>
				<div class="table-responsive mt-2">
					<table class="table table-sm table-striped">
						<thead>
							<tr>
								<th scope="col">Container</th>
								<th scope="col">GUID</th>
								<th scope="col">Current Identification</th>
								<th scope="col">Part Type</th>
								<th scope="col">Part Count</th>
								<th scope="col">Part Count Modifier</th>
								<th scope="col">Part Remarks</th>
								<th scope="col">Preservation</th>
							</tr>
						</thead>
						<tbody>
							<cfloop query="queryCollectionObjectDetails">
								<cfset coGuidText = "">
								<cfset coGuidUrl = "">
								<cfset hasLeafLabel = (len(trim(queryCollectionObjectDetails.container_label)) GT 0)>
								<cfset leafContainerDisplay = "Unnamed container">
								<cfif hasLeafLabel>
									<cfset leafContainerDisplay = queryCollectionObjectDetails.container_label>
								</cfif>
								<cfif len(trim(queryCollectionObjectDetails.container_barcode)) GT 0>
									<cfset leafContainerDisplay = queryCollectionObjectDetails.container_barcode>
									<cfif queryCollectionObjectDetails.container_barcode NEQ queryCollectionObjectDetails.container_label AND hasLeafLabel>
										<cfset leafContainerDisplay = "#leafContainerDisplay# (#queryCollectionObjectDetails.container_label#)">
									</cfif>
								</cfif>
								<cfif len(trim(institution_acronym)) GT 0 AND len(trim(collection_cde)) GT 0 AND len(trim(cat_num)) GT 0>
									<cfset coGuidText = "#institution_acronym#:#collection_cde#:#cat_num#">
									<cfset coGuidUrl = "/guid/#encodeForURL(institution_acronym)#:#encodeForURL(collection_cde)#:#encodeForURL(cat_num)#">
								</cfif>
								<tr>
									<td>
										<a href="/containers/viewContainer.cfm?container_id=#encodeForURL(queryCollectionObjectDetails.container_id)#" target="_blank" rel="noopener noreferrer">
											#encodeForHtml(leafContainerDisplay)#
										</a>
									</td>
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
										<cfif isNumeric(part_count)>
											#encodeForHtml(part_count)#
										<cfelse>
											<span class="text-muted">—</span>
										</cfif>
									</td>
									<td>
										<cfif len(trim(part_count_modifier)) GT 0>
											#encodeForHtml(part_count_modifier)#
										<cfelse>
											<span class="text-muted">—</span>
										</cfif>
									</td>
									<td>
										<cfif len(trim(part_remarks)) GT 0>
											#encodeForHtml(part_remarks)#
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
		</cfoutput></cfsavecontent>
	<cfcatch>
		<cfset local.error_message = cfcatchToErrorMessage(cfcatch)>
		<cfset local.function_called = "#GetFunctionCalledName()#">
		<cfscript>reportError(function_called="#local.function_called#", error_message="#local.error_message#");</cfscript>
		<cfset local.htmlFragment = '<p class="text-danger mb-0">Unable to load container contents.</p>'>
	</cfcatch>
	</cftry>
	<cfreturn local.htmlFragment>
</cffunction>

<!---
Function getContainerDetailsHtml.  Returns an HTML fragment with the read-only
details of a container for use in dialogs and page components.

@param container_id the container_id whose details should be rendered.
@param displayMode optional string, either "page" (default) or "dialog", to 
  control the layout and styling of the returned HTML fragment.
@param idSuffix optional string to append to the IDs of elements in the returned 
  HTML fragment, to avoid collisions when multiple container details are 
  rendered on the same page.
@param showBrowseAction optional boolean (or string "true"/"false") to control 
  whether the "Browse" action is shown in the returned HTML fragment. Defaults to true.
@return HTML fragment string for the container details section, including
  breadcrumb navigation, container information, and contents summary.
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
	<!--- position scan-to-place inputs are only ever offered on the full page, and only when this
		session itself holds manage_container rights --->
	<cfset local.canEditPositions = false>
	<cfif local.safeDisplayMode EQ "page" AND isdefined("session.roles") AND listfindnocase(session.roles, "manage_container") GT 0>
		<cfset local.canEditPositions = true>
	</cfif>
	<cfthread
		name="getContainerDetailsHtmlThread#local.tn#"
		container_id="#arguments.container_id#"
		safeDisplayMode="#local.safeDisplayMode#"
		safeIdSuffix="#local.safeIdSuffix#"
		showBrowseAction="#local.showBrowseAction#"
		canEditPositions="#local.canEditPositions#"
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
					<cfset formattedIdSuffix = "">
					<cfif len(trim(safeIdSuffix)) GT 0>
						<cfset formattedIdSuffix = "_#safeIdSuffix#">
					</cfif>
					<cfset breadcrumbNavId = "container_breadcrumb_nav#formattedIdSuffix#">
					<cfset breadcrumbFeedbackId = "container_breadcrumb_feedback#formattedIdSuffix#">
					<cfset contextHeadingId = "containerContextHeading#formattedIdSuffix#">
					<cfset detailsHeadingId = "containerDetailsHeading#formattedIdSuffix#">
					<cfset contentsHeadingId = "containerContentsSummaryHeading#formattedIdSuffix#">
					<cfset contentsTargetId = "containerContentsSection#formattedIdSuffix#">
					<cfset positionsHeadingId = "containerPositionsHeading#formattedIdSuffix#">
					<cfset positionsTargetId = "containerPositionsGrid#formattedIdSuffix#">
					<cfset roleBadgeId = "containerRoleBadge#formattedIdSuffix#">
					<cfset canEditPositionsJs = "false">
					<cfif canEditPositions>
						<cfset canEditPositionsJs = "true">
					</cfif>
					<cfset viewContainerUrl = "/containers/viewContainer.cfm?container_id=#encodeForURL(getContainerDetail.container_id)#">
					<cfset editContainerUrl = "/containers/Container.cfm?action=edit&container_id=#encodeForURL(getContainerDetail.container_id)#">
					<cfset createChildContainerUrl = "/containers/Container.cfm?action=new&parent_container_id=#encodeForURL(getContainerDetail.container_id)#">
					<cfset browseTreeUrl = "/containers/Containers.cfm?container_id=#encodeForURL(getContainerDetail.container_id)#&execute=true">
					<cfset isProxyOrLeafType = listFindNoCase("proxy,leaf", getContainerDetail.container_role) GT 0>
					<cfset isProxyOrBearerType = listFindNoCase("proxy,leafbearer", getContainerDetail.container_role) GT 0>
					<cfset currentContainerIsEmpty = (val(getContainerDetail.direct_structural_children) + val(getContainerDetail.direct_leaf_children)) EQ 0>
					<cfset currentDisplay = "Unnamed container">
					<cfif len(trim(getContainerDetail.label)) GT 0>
						<cfset currentDisplay = getContainerDetail.label>
					</cfif>
					<cfif len(trim(getContainerDetail.barcode)) GT 0>
						<cfset currentDisplay = getContainerDetail.barcode>
						<cfif getContainerDetail.barcode NEQ getContainerDetail.label AND len(trim(getContainerDetail.label)) GT 0>
							<cfset currentDisplay = "#currentDisplay# (#getContainerDetail.label#)">
						</cfif>
					</cfif>
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
					<section class="mb-3" aria-labelledby="#encodeForHtmlAttribute(contextHeadingId)#">
						<div class="row">
							<cfif safeDisplayMode EQ "dialog">
								<div class="col-12">
									<div class="row">
										<div class="col-12 col-lg-6 mb-2 mb-lg-0">
											<cfset name = "Container"> 
											<cfif len(getContainerDetail.label) GT 0>
												<cfset name = "#name# #getContainerDetail.label#">
											<cfelseif len(getContainerDetail.barcode) GT 0>
												<cfset name = "#name# #getContainerDetail.barcode#">
											<cfelse>
												<cfset name = "#name# [#getContainerDetail.container_id#]">
											</cfif>
											<h2 class="h4 mb-0" id="#encodeForHtmlAttribute(contextHeadingId)#">#name# (#getContainerDetail.container_type#)</h2>
										</div>
										<div class="col-12 col-lg-6">
											<div class="text-lg-right">
												<div class="btn-toolbar justify-content-lg-end" role="toolbar" aria-label="Container quick actions">
													<cfif NOT isProxyOrLeafType>
														<a href="#createChildContainerUrl#" class="btn btn-xs btn-secondary mr-1 mb-1" target="_blank" rel="noopener noreferrer">Create Child of this Container</a>
														<a href="##" class="btn btn-xs btn-secondary mr-1 mb-1" onclick="event.preventDefault(); openPlaceChildIntoContainerDialog(#val(getContainerDetail.container_id)#, '#encodeForJavaScript(currentDisplay)#', '#encodeForJavaScript(getContainerDetail.institution_acronym)#', '#encodeForJavaScript(breadcrumbFeedbackId)#', '#encodeForJavaScript(contentsTargetId)#');">Place Child into this Container</a>
													</cfif>
													<cfif NOT currentContainerIsEmpty><cfset disabledClass="disabled"><cfelse><cfset disabledClass=""></cfif>
													<cfif isProxyOrBearerType>
														<a href="##" class="btn btn-xs btn-secondary mr-1 mb-1 #disabledClass#"
															<cfif NOT currentContainerIsEmpty>
																aria-disabled="true"
																tabindex="-1"
															<cfelse>
																onclick="event.preventDefault(); openPlaceLeafIntoContainerDialog(#val(getContainerDetail.container_id)#, '#encodeForJavaScript(currentDisplay)#', '#encodeForJavaScript(getContainerDetail.institution_acronym)#', '#encodeForJavaScript(breadcrumbFeedbackId)#', '#encodeForJavaScript(contentsTargetId)#');"
															</cfif>
														>Place Part into this Container</a>
													</cfif>
													<a href="#viewContainerUrl#" class="btn btn-xs btn-primary mr-1 mb-1" target="_blank" rel="noopener noreferrer">View</a>
													<a href="#editContainerUrl#" class="btn btn-xs btn-secondary mr-1 mb-1" target="_blank" rel="noopener noreferrer">Edit</a>
													<cfif showBrowseAction>
														<a href="#browseTreeUrl#" class="btn btn-xs btn-info mb-1" target="_blank" rel="noopener noreferrer">Browse in Hierarchy</a>
													</cfif>
												</div>
											</div>
										</div>
									</div>
								</div>
							</cfif>
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
										loadPositionsGrid(#getContainerDetail.container_id#, #getContainerDetail.number_positions#, "#encodeForJavaScript(positionsTargetId)#", "#encodeForJavaScript(breadcrumbFeedbackId)#", #canEditPositionsJs#, "#encodeForJavaScript(positionsHeadingId)#");
									</cfif>
									loadContainerContentsSection(#getContainerDetail.container_id#, "#encodeForJavaScript(contentsTargetId)#", "#encodeForJavaScript(breadcrumbFeedbackId)#");
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
						<div id="#encodeForHtmlAttribute(contentsTargetId)#"><div class="my-2 text-center"><img src="/shared/images/indicator.gif"> Loading...</div></div>
					</section>
					<cfif val(getContainerDetail.number_positions) GT 0>
						<section class="mb-3" aria-labelledby="#encodeForHtmlAttribute(positionsHeadingId)#">
							<h2 class="h4" id="#encodeForHtmlAttribute(positionsHeadingId)#" tabindex="-1">Positions</h2>
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

@param container_id the container_id whose details should be rendered for editing.
@param idSuffix optional string to append to the IDs of elements in the returned 
  HTML fragment, to avoid collisions when multiple container edit forms are 
  rendered on the same page.
@return HTML fragment string for the container edit form, including 
  container type, label, barcode, and other editable fields.
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


<!---
Function validateContainerPlacement. Performs pre-flight placement validation for container moves.
Returns a JSON structure with allow/block state, messages, and contextual metadata.
@param child_container_id the container_id for the child container being moved.
@param proposed_parent_container_id the target parent container_id (use 0 for root placement).
@return a JSON object with keys: allowed, severity, warnings, blocks, child_type, child_role,
	child_institution_acronym, child_rank_order, child_variable_rank, parent_type, parent_role,
	parent_institution_acronym, parent_rank_order, expected_parent_types, force_expected_parent_type,
	is_root_placement.
--->
<cffunction name="validateContainerPlacement" access="remote" returntype="any" returnformat="json" output="false">
	<cfargument name="child_container_id" type="numeric" required="yes">
	<cfargument name="proposed_parent_container_id" type="numeric" required="yes">

	<cfset local.retval = StructNew()>
	<cfset local.retval["allowed"] = true>
	<cfset local.retval["severity"] = "ok">
	<cfset local.retval["warnings"] = ArrayNew(1)>
	<cfset local.retval["blocks"] = ArrayNew(1)>
	<cfset local.retval["child_type"] = "">
	<cfset local.retval["child_role"] = "">
	<cfset local.retval["child_institution_acronym"] = "">
	<cfset local.retval["child_rank_order"] = "">
	<cfset local.retval["child_variable_rank"] = 0>
	<cfset local.retval["parent_type"] = "">
	<cfset local.retval["parent_role"] = "">
	<cfset local.retval["parent_institution_acronym"] = "">
	<cfset local.retval["parent_rank_order"] = "">
	<cfset local.retval["expected_parent_types"] = "any">
	<cfset local.retval["force_expected_parent_type"] = 0>
	<cfset local.retval["is_root_placement"] = (val(arguments.proposed_parent_container_id) EQ 0)>

	<cftry>
		<cfquery name="queryChild" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
			SELECT
				c.container_id,
				c.container_type,
				c.height,
				c.length,
				c.width,
				c.locked_position,
				c.institution_acronym,
				ct.role,
				NVL(ct.expects_leaf_child_count, 0) AS expects_leaf_child_count,
				NVL(ct.expected_parent_types, 'any') AS expected_parent_types,
				NVL(ct.force_expected_parent_type, 0) AS force_expected_parent_type,
				ct.rank_order,
				NVL(ct.variable_rank, 0) AS variable_rank
			FROM
				container c
				LEFT JOIN ctcontainer_type ct ON ct.container_type = c.container_type
			WHERE
				c.container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.child_container_id#">
		</cfquery>

		<cfif queryChild.recordcount EQ 0>
			<cfset local.retval["allowed"] = false>
			<cfset local.retval["severity"] = "block">
			<cfset ArrayAppend(local.retval["blocks"], "Child container was not found.")>
			<cfreturn serializeJSON(local.retval)>
		</cfif>

		<cfset local.childType = queryChild.container_type>
		<cfset local.childRole = lCase(trim(queryChild.role))>
		<cfset local.childInst = queryChild.institution_acronym>
		<cfset local.childRank = queryChild.rank_order>
		<cfset local.childVariableRank = val(queryChild.variable_rank)>
		<cfset local.expectedParentTypes = lCase(trim(queryChild.expected_parent_types))>
		<cfset local.forceExpectedParentType = val(queryChild.force_expected_parent_type)>
		<cfset local.isRootPlacement = (val(arguments.proposed_parent_container_id) EQ 0)>

		<cfset local.parentType = "">
		<cfset local.parentRole = "">
		<cfset local.parentInst = "">
		<cfset local.parentRank = "">
		<cfset local.parentVariableRank = 0>
		<cfset local.parentExpectsLeafChildCount = 0>
		<cfset local.parentHeight = "">
		<cfset local.parentLength = "">
		<cfset local.parentWidth = "">

		<cfif NOT local.isRootPlacement>
			<cfquery name="queryParent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
				SELECT
					c.container_id,
					c.container_type,
					c.height,
					c.length,
					c.width,
					c.institution_acronym,
					ct.role,
					NVL(ct.expects_leaf_child_count, 0) AS expects_leaf_child_count,
					ct.rank_order,
					NVL(ct.variable_rank, 0) AS variable_rank
				FROM
					container c
					LEFT JOIN ctcontainer_type ct ON ct.container_type = c.container_type
				WHERE
					c.container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.proposed_parent_container_id#">
			</cfquery>
			<cfif queryParent.recordcount EQ 0>
				<cfset local.retval["allowed"] = false>
				<cfset local.retval["severity"] = "block">
				<cfset ArrayAppend(local.retval["blocks"], "Parent container was not found.")>
				<cfreturn serializeJSON(local.retval)>
			</cfif>
			<cfset local.parentType = queryParent.container_type>
			<cfset local.parentRole = lCase(trim(queryParent.role))>
			<cfset local.parentInst = queryParent.institution_acronym>
			<cfset local.parentRank = queryParent.rank_order>
			<cfset local.parentVariableRank = val(queryParent.variable_rank)>
			<cfset local.parentExpectsLeafChildCount = val(queryParent.expects_leaf_child_count)>
			<cfset local.parentHeight = queryParent.height>
			<cfset local.parentLength = queryParent.length>
			<cfset local.parentWidth = queryParent.width>
		</cfif>

		<cfset local.retval["child_type"] = local.childType>
		<cfset local.retval["child_role"] = local.childRole>
		<cfset local.retval["child_institution_acronym"] = local.childInst>
		<cfset local.retval["child_rank_order"] = local.childRank>
		<cfset local.retval["child_variable_rank"] = local.childVariableRank>
		<cfset local.retval["parent_type"] = local.parentType>
		<cfset local.retval["parent_role"] = local.parentRole>
		<cfset local.retval["parent_institution_acronym"] = local.parentInst>
		<cfset local.retval["parent_rank_order"] = local.parentRank>
		<cfset local.retval["expected_parent_types"] = local.expectedParentTypes>
		<cfset local.retval["force_expected_parent_type"] = local.forceExpectedParentType>
		<cfset local.retval["is_root_placement"] = local.isRootPlacement>

		<!--- GROUP 1 — TRIGGER MIRRORS (T1–T9) preflight restrictions imposed in MCZBASE.MOVE_CONTAINER trigger --->

		<!--- GROUP 1 (T1): self-placement --->
		<cfif val(arguments.child_container_id) EQ val(arguments.proposed_parent_container_id)>
			<cfset local.retval["allowed"] = false>
			<cfset local.retval["severity"] = "block">
			<cfset ArrayAppend(local.retval["blocks"], "A container cannot be placed inside itself.")>
			<cfreturn serializeJSON(local.retval)>
		</cfif>

		<!--- GROUP 1 (T4): institution root --->
		<cfif lCase(local.childType) EQ "institution" AND NOT local.isRootPlacement>
			<cfset local.retval["allowed"] = false>
			<cfset local.retval["severity"] = "block">
			<cfset ArrayAppend(local.retval["blocks"], "Institution containers must remain at the root (parent_container_id = 0).")>
			<cfreturn serializeJSON(local.retval)>
		</cfif>

		<!--- GROUP 1 (T3): collection object as parent --->
		<cfif NOT local.isRootPlacement AND local.parentRole EQ "leaf">
			<cfset local.retval["allowed"] = false>
			<cfset local.retval["severity"] = "block">
			<cfset ArrayAppend(local.retval["blocks"], "Collection objects cannot contain other containers.")>
			<cfreturn serializeJSON(local.retval)>
		</cfif>

		<!--- GROUP 1 (T5): label container checks --->
		<cfif findNoCase("label", local.childType) GT 0 OR (NOT local.isRootPlacement AND findNoCase("label", local.parentType) GT 0)>
			<cfset local.retval["allowed"] = false>
			<cfset local.retval["severity"] = "block">
			<cfset ArrayAppend(local.retval["blocks"], "Label containers cannot be placed in or contain other containers.")>
			<cfreturn serializeJSON(local.retval)>
		</cfif>

		<!--- GROUP 1 (T7): locked position --->
		<cfif val(queryChild.locked_position) EQ 1>
			<cfset local.retval["allowed"] = false>
			<cfset local.retval["severity"] = "block">
			<cfset ArrayAppend(local.retval["blocks"], "This position is locked and cannot be moved.")>
			<cfreturn serializeJSON(local.retval)>
		</cfif>

		<!--- GROUP 1 (T6): dimension fit --->
		<cfif NOT local.isRootPlacement
			AND isNumeric(queryChild.height) AND val(queryChild.height) GT 0
			AND isNumeric(queryChild.length) AND val(queryChild.length) GT 0
			AND isNumeric(queryChild.width) AND val(queryChild.width) GT 0
			AND isNumeric(local.parentHeight) AND val(local.parentHeight) GT 0
			AND isNumeric(local.parentLength) AND val(local.parentLength) GT 0
			AND isNumeric(local.parentWidth) AND val(local.parentWidth) GT 0>
			<cfif val(queryChild.height) GT val(local.parentHeight)
				OR val(queryChild.length) GT val(local.parentLength)
				OR val(queryChild.width) GT val(local.parentWidth)>
				<cfset local.retval["allowed"] = false>
				<cfset local.retval["severity"] = "block">
				<cfset ArrayAppend(local.retval["blocks"], "The child will not fit in the parent (check height/length/width).")>
				<cfreturn serializeJSON(local.retval)>
			</cfif>
		</cfif>

		<!--- GROUP 1 (T8): cycle prevention --->
		<cfif NOT local.isRootPlacement>
			<cfquery name="queryCycle" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
				SELECT COUNT(*) AS cycle_ct
				FROM (
					SELECT container_id
					FROM container
					START WITH parent_container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.child_container_id#">
					CONNECT BY NOCYCLE PRIOR container_id = parent_container_id
				)
				WHERE container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.proposed_parent_container_id#">
			</cfquery>
			<cfif val(queryCycle.cycle_ct) GT 0>
				<cfset local.retval["allowed"] = false>
				<cfset local.retval["severity"] = "block">
				<cfset ArrayAppend(local.retval["blocks"], "This move would create a cycle in the container hierarchy.")>
				<cfreturn serializeJSON(local.retval)>
			</cfif>
		</cfif>

		<!--- GROUP 1 (T9): institution acronym mismatch --->
		<cfif NOT local.isRootPlacement
			AND len(trim(local.childInst)) GT 0
			AND len(trim(local.parentInst)) GT 0
			AND local.childInst NEQ local.parentInst>
			<cfset local.retval["allowed"] = false>
			<cfset local.retval["severity"] = "block">
			<cfset ArrayAppend(local.retval["blocks"], "A container cannot be placed into a container with a different institution acronym (#local.childInst# vs #local.parentInst#).")>
			<cfreturn serializeJSON(local.retval)>
		</cfif>

		<!--- GROUP 2 — CTCONTAINER_TYPE DATA RULES (CT1–CT7) --->

		<!--- GROUP 2 (CT1): expected root container --->
		<cfif local.expectedParentTypes EQ "none" AND NOT local.isRootPlacement>
			<cfif local.forceExpectedParentType EQ 1>
				<cfset local.retval["allowed"] = false>
				<cfset local.retval["severity"] = "block">
				<cfset ArrayAppend(local.retval["blocks"], "A #local.childType# must be placed at the root.")>
				<cfreturn serializeJSON(local.retval)>
			<cfelse>
				<cfset ArrayAppend(local.retval["warnings"], "Containers of type #local.childType# are expected to be root containers.")>
			</cfif>
		</cfif>

		<!--- GROUP 2 (CT2): expected parent type list --->
		<cfif NOT local.isRootPlacement AND local.expectedParentTypes NEQ "any" AND local.expectedParentTypes NEQ "none"
			AND NOT listFindNoCase(local.expectedParentTypes, local.parentType)>
			<cfif local.forceExpectedParentType EQ 1>
				<cfset local.retval["allowed"] = false>
				<cfset local.retval["severity"] = "block">
				<cfset ArrayAppend(local.retval["blocks"], "A #local.childType# must be placed inside one of: #local.expectedParentTypes#.")>
				<cfreturn serializeJSON(local.retval)>
			<cfelse>
				<cfset ArrayAppend(local.retval["warnings"], "A #local.childType# is normally placed inside a #local.expectedParentTypes#. The selected parent is a #local.parentType#.")>
			</cfif>
		</cfif>

		<!--- GROUP 2 (CT3): proxy as parent --->
		<cfif NOT local.isRootPlacement AND local.parentRole EQ "proxy" AND local.childRole NEQ "leaf">
			<cfset local.retval["allowed"] = false>
			<cfset local.retval["severity"] = "block">
			<cfset ArrayAppend(local.retval["blocks"], "A #local.parentType# is a single-occupant container and can only contain a collection object leaf container.")>
			<cfreturn serializeJSON(local.retval)>
		</cfif>

		<!--- GROUP 2 (CT4): placing leaf into parent not expecting direct leaves --->
		<cfif NOT local.isRootPlacement AND local.childRole EQ "leaf" AND local.parentExpectsLeafChildCount EQ 0>
			<cfset ArrayAppend(local.retval["warnings"], "Containers of type #local.parentType# are not expected to hold collection objects directly.")>
		</cfif>

		<!--- GROUP 2 (CT5): single-occupant parent already occupied --->
		<cfif NOT local.isRootPlacement AND local.childRole EQ "leaf" AND local.parentExpectsLeafChildCount EQ 1>
			<cfquery name="queryLeafChildren" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
				SELECT COUNT(*) AS leaf_ct
				FROM container
				WHERE
					parent_container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.proposed_parent_container_id#">
					AND container_type = 'collection object'
					AND container_id <> <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.child_container_id#">
			</cfquery>
			<cfif val(queryLeafChildren.leaf_ct) GT 0>
				<cfset ArrayAppend(local.retval["warnings"], "This container already holds a collection object. Containers of type #local.parentType# are expected to hold exactly one collection object.")>
			</cfif>
		</cfif>

		<!--- GROUP 2 (CT6): rank order reversal --->
		<cfif NOT local.isRootPlacement
			AND local.childVariableRank EQ 0
			AND local.parentVariableRank EQ 0
			AND isNumeric(local.childRank)
			AND isNumeric(local.parentRank)
			AND val(local.childRank) LTE val(local.parentRank)>
			<cfset ArrayAppend(local.retval["warnings"], "This placement reverses the expected nesting depth. A #local.childType# (rank #local.childRank#) is being placed inside a #local.parentType# (rank #local.parentRank#).")>
		</cfif>

		<!--- GROUP 2 (CT7): same-type nesting --->
		<cfif NOT local.isRootPlacement
			AND local.childVariableRank EQ 0
			AND lCase(local.childType) EQ lCase(local.parentType)>
			<cfset ArrayAppend(local.retval["warnings"], "A #local.childType# is being placed inside another #local.childType#. Containers of the same type are not normally nested.")>
		</cfif>

		<!--- GROUP 3 — APPLICATION-ONLY CHECKS (AO1–AO3) --->

		<!--- GROUP 3 (AO1): root placement where parent normally expected --->
		<cfif local.isRootPlacement AND local.expectedParentTypes NEQ "none" AND local.expectedParentTypes NEQ "any">
			<cfset ArrayAppend(local.retval["warnings"], "Container is being placed at the root level. Containers of type #local.childType# are normally placed inside #local.expectedParentTypes#.")>
		</cfif>

		<!--- GROUP 3 (AO2): coll_obj_cont_hist dual current placement --->
		<cfif local.childRole EQ "leaf">
			<cfquery name="queryDualCurrent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
				SELECT COUNT(*) AS conflict_ct
				FROM coll_obj_cont_hist coch
				WHERE
					coch.container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.child_container_id#">
					AND coch.current_container_fg = 1
					AND EXISTS (
						SELECT 1
						FROM coll_obj_cont_hist other
						WHERE
							other.collection_object_id = coch.collection_object_id
							AND other.current_container_fg = 1
							AND other.container_id <> coch.container_id
					)
			</cfquery>
			<cfif val(queryDualCurrent.conflict_ct) GT 0>
				<cfset ArrayAppend(local.retval["warnings"], "This collection object is already recorded as currently placed in a different container.")>
			</cfif>
		</cfif>

		<!--- GROUP 3 (AO3): structural child in leafbearer --->
		<cfif NOT local.isRootPlacement
			AND local.parentRole EQ "leafbearer"
			AND NOT listFindNoCase("leaf,proxy", local.childRole)>
			<cfset ArrayAppend(local.retval["warnings"], "Containers of type #local.parentType# normally contain collection objects. Placing a #local.childType# container inside it is unusual.")>
		</cfif>

		<cfif ArrayLen(local.retval["warnings"]) GT 0>
			<cfset local.retval["severity"] = "warn">
		</cfif>

		<cfreturn serializeJSON(local.retval)>
	<cfcatch>
		<cfset local.error_message = cfcatchToErrorMessage(cfcatch)>
		<cfset local.function_called = "#GetFunctionCalledName()#">
		<cfscript>reportError(function_called="#local.function_called#", error_message="#local.error_message#");</cfscript>
		<cfset local.safe = StructNew()>
		<cfset local.safe["allowed"] = false>
		<cfset local.safe["severity"] = "block">
		<cfset local.safe["warnings"] = ArrayNew(1)>
		<cfset local.safe["blocks"] = ArrayNew(1)>
		<cfset ArrayAppend(local.safe["blocks"], "Validation error occurred. Please try again.")>
		<cfset local.safe["child_type"] = "">
		<cfset local.safe["child_role"] = "">
		<cfset local.safe["child_institution_acronym"] = "">
		<cfset local.safe["child_rank_order"] = "">
		<cfset local.safe["child_variable_rank"] = 0>
		<cfset local.safe["parent_type"] = "">
		<cfset local.safe["parent_role"] = "">
		<cfset local.safe["parent_institution_acronym"] = "">
		<cfset local.safe["parent_rank_order"] = "">
		<cfset local.safe["expected_parent_types"] = "any">
		<cfset local.safe["force_expected_parent_type"] = 0>
		<cfset local.safe["is_root_placement"] = (val(arguments.proposed_parent_container_id) EQ 0)>
		<cfreturn serializeJSON(local.safe)>
	</cfcatch>
	</cftry>
</cffunction>

<!---
Function moveContainerById. Moves a child container into a new parent container by container_id.
Returns status JSON and never aborts on trigger errors.
@param child_container_id container_id of the container to move.
@param parent_container_id container_id of the destination parent container.
@param move_timestamp optional timestamp string (YYYY-MM-DD HH24:MI:SS) for parent_install_date.
@return a JSON object with status (moved|notfound|error) and message, plus context fields:
	child_container_id, parent_container_id, child_label, child_type, parent_label, parent_type.
--->
<cffunction name="moveContainerById" access="remote" returntype="any" returnformat="json" output="false">
	<cfargument name="child_container_id" type="numeric" required="yes">
	<cfargument name="parent_container_id" type="numeric" required="yes">
	<cfargument name="move_timestamp" type="string" required="no" default="">

	<cfset local.retval = StructNew()>
	<cftry>
		<cfquery name="queryChild" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
			SELECT container_id, label, barcode, container_type, institution_acronym
			FROM container
			WHERE container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.child_container_id#">
		</cfquery>
		<cfif queryChild.recordcount EQ 0>
			<cfset local.retval["status"] = "notfound">
			<cfset local.retval["message"] = "Child container was not found.">
			<cfset local.retval["missing"] = "child">
			<cfreturn serializeJSON(local.retval)>
		</cfif>

		<cfquery name="queryParent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
			SELECT container_id, label, barcode, container_type, institution_acronym
			FROM container
			WHERE container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.parent_container_id#">
		</cfquery>
		<cfif queryParent.recordcount EQ 0>
			<cfset local.retval["status"] = "notfound">
			<cfset local.retval["message"] = "Parent container was not found.">
			<cfset local.retval["missing"] = "parent">
			<cfreturn serializeJSON(local.retval)>
		</cfif>

		<cfif len(trim(queryChild.institution_acronym)) GT 0
			AND len(trim(queryParent.institution_acronym)) GT 0
			AND queryChild.institution_acronym NEQ queryParent.institution_acronym>
			<cfset local.retval["status"] = "error">
			<cfset local.retval["message"] = "A container cannot be placed into a container with a different institution acronym (#queryChild.institution_acronym# vs #queryParent.institution_acronym#).">
			<cfreturn serializeJSON(local.retval)>
		</cfif>

		<cftry>
			<cfquery name="queryDoMove" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#" result="queryDoMove_result">
				UPDATE container
				SET
					parent_container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#queryParent.container_id#">
					<cfif len(trim(arguments.move_timestamp)) GT 0>
						, parent_install_date = TO_DATE(
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(arguments.move_timestamp)#">,
							'YYYY-MM-DD HH24:MI:SS'
						)
					</cfif>
				WHERE container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#queryChild.container_id#">
			</cfquery>
			<cfif queryDoMove_result.recordCount EQ 0>
				<cfthrow type="ChildNotFound" message="No rows updated.">
			</cfif>
		<cfcatch>
			<cfset local.userMessage = trim(REReplace(cfcatch.message, "^ORA-[0-9]+:\\s*", "", "one"))>
			<cfset local.matchPos = REFindNoCase("(You cannot|This move|A container|Institution|The child|The position)", local.userMessage)>
			<cfif local.matchPos GT 0>
				<cfset local.userMessage = mid(local.userMessage, local.matchPos, len(local.userMessage) - local.matchPos + 1)>
			</cfif>
			<cfif len(trim(local.userMessage)) EQ 0>
				<cfset local.userMessage = "Unable to move container due to a placement rule. Please review the selected parent and try again.">
			</cfif>
			<cfif cfcatch.type EQ "ChildNotFound">
				<cfset local.userMessage = "Query Error: " + cfcatch.message + " Child container was not found. It may have been deleted or moved by another user.">
			</cfif>
			<cfset local.retval["status"] = "error">
			<cfset local.retval["message"] = local.userMessage>
			<cfreturn serializeJSON(local.retval)>
		</cfcatch>
		</cftry>

		<cfset local.retval["status"] = "moved">
		<cfset local.retval["child_container_id"] = queryChild.container_id>
		<cfset local.retval["child_label"] = queryChild.label>
		<cfset local.retval["child_type"] = queryChild.container_type>
		<cfset local.retval["parent_container_id"] = queryParent.container_id>
		<cfset local.retval["parent_label"] = queryParent.label>
		<cfset local.retval["parent_type"] = queryParent.container_type>
		<cfreturn serializeJSON(local.retval)>
	<cfcatch>
		<cfset local.retval = StructNew()>
		<cfset local.retval["status"] = "error">
		<cfset local.retval["message"] = trim(cfcatch.message)>
		<cfreturn serializeJSON(local.retval)>
	</cfcatch>
	</cftry>
</cffunction>

<!---
Function preflightMoveContainerByBarcode. Resolves barcodes to container ids and runs placement preflight validation.
@param child_barcode barcode of the container to move.
@param parent_barcode barcode of the destination parent container.
@return a JSON object with status (ok|notfound|error), placement validation keys from validateContainerPlacement
	(allowed, severity, warnings, blocks, child_type, parent_type, etc), and context keys:
	child_container_id, parent_container_id, child_label, child_barcode, parent_label, parent_barcode.
--->
<cffunction name="preflightMoveContainerByBarcode" access="remote" returntype="any" returnformat="json" output="false">
	<cfargument name="child_barcode" type="string" required="yes">
	<cfargument name="parent_barcode" type="string" required="yes">

	<cfset local.retval = StructNew()>
	<cftry>
		<cfquery name="local.queryChild" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
			SELECT container_id, label, barcode
			FROM container
			WHERE barcode = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(arguments.child_barcode)#">
		</cfquery>
		<cfif local.queryChild.recordcount EQ 0>
			<cfset local.retval["status"] = "notfound">
			<cfset local.retval["message"] = "Child barcode was not found.">
			<cfset local.retval["missing"] = "child">
			<cfreturn serializeJSON(local.retval)>
		</cfif>

		<cfquery name="local.queryParent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
			SELECT container_id, label, barcode
			FROM container
			WHERE barcode = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(arguments.parent_barcode)#">
		</cfquery>
		<cfif local.queryParent.recordcount EQ 0>
			<cfset local.retval["status"] = "notfound">
			<cfset local.retval["message"] = "Parent barcode was not found.">
			<cfset local.retval["missing"] = "parent">
			<cfreturn serializeJSON(local.retval)>
		</cfif>

		<cfset local.validationResult = validateContainerPlacement(
			child_container_id=local.queryChild.container_id,
			proposed_parent_container_id=local.queryParent.container_id
		)>
		<cfif isSimpleValue(local.validationResult)>
			<cfset local.validationResult = deserializeJSON(local.validationResult)>
		</cfif>

		<cfset local.validationResult["status"] = "ok">
		<cfset local.validationResult["child_container_id"] = local.queryChild.container_id>
		<cfset local.validationResult["child_label"] = local.queryChild.label>
		<cfset local.validationResult["child_barcode"] = local.queryChild.barcode>
		<cfset local.validationResult["parent_container_id"] = local.queryParent.container_id>
		<cfset local.validationResult["parent_label"] = local.queryParent.label>
		<cfset local.validationResult["parent_barcode"] = local.queryParent.barcode>
		<cfreturn serializeJSON(local.validationResult)>
	<cfcatch>
		<cfset local.retval = StructNew()>
		<cfset local.retval["status"] = "error">
		<cfset local.retval["message"] = trim(cfcatch.message)>
		<cfreturn serializeJSON(local.retval)>
	</cfcatch>
	</cftry>
</cffunction>

<!---
Function moveContainerByBarcode. Moves a child container into a new parent container by barcode.
Returns status JSON and never aborts on trigger errors.
@param child_barcode barcode of the container to move.
@param parent_barcode barcode of the destination parent container.
@param move_timestamp optional timestamp string (YYYY-MM-DD HH24:MI:SS) for parent_install_date.
@return a JSON object with status (moved|notfound|error) and message, plus context fields:
	child_container_id, parent_container_id, child_barcode, parent_barcode, missing (when notfound).
--->
<cffunction name="moveContainerByBarcode" access="remote" returntype="any" returnformat="json" output="false">
	<cfargument name="child_barcode" type="string" required="yes">
	<cfargument name="parent_barcode" type="string" required="yes">
	<cfargument name="move_timestamp" type="string" required="no" default="">

	<cfset local.retval = StructNew()>
	<cftry>
		<cfquery name="queryChild" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
			SELECT container_id, label, barcode, container_type, institution_acronym
			FROM container
			WHERE barcode = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(arguments.child_barcode)#">
		</cfquery>
		<cfif queryChild.recordcount EQ 0>
			<cfset local.retval["status"] = "notfound">
			<cfset local.retval["message"] = "Child barcode was not found.">
			<cfset local.retval["missing"] = "child">
			<cfreturn serializeJSON(local.retval)>
		</cfif>

		<cfquery name="queryParent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
			SELECT container_id, label, barcode, container_type, institution_acronym
			FROM container
			WHERE barcode = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(arguments.parent_barcode)#">
		</cfquery>
		<cfif queryParent.recordcount EQ 0>
			<cfset local.retval["status"] = "notfound">
			<cfset local.retval["message"] = "Parent barcode was not found.">
			<cfset local.retval["missing"] = "parent">
			<cfreturn serializeJSON(local.retval)>
		</cfif>

		<cfif len(trim(queryChild.institution_acronym)) GT 0
			AND len(trim(queryParent.institution_acronym)) GT 0
			AND queryChild.institution_acronym NEQ queryParent.institution_acronym>
			<cfset local.retval["status"] = "error">
			<cfset local.retval["message"] = "A container cannot be placed into a container with a different institution acronym (#queryChild.institution_acronym# vs #queryParent.institution_acronym#).">
			<cfreturn serializeJSON(local.retval)>
		</cfif>

		<cftry>
			<cfquery name="queryDoMove" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#" result="queryDoMove_result"> 
				UPDATE container
				SET
					parent_container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#queryParent.container_id#">
					<cfif len(trim(arguments.move_timestamp)) GT 0>
						, parent_install_date = TO_DATE(
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(arguments.move_timestamp)#">,
							'YYYY-MM-DD HH24:MI:SS'
						)
					</cfif>
				WHERE container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#queryChild.container_id#">
			</cfquery>
			<cfif queryDoMove_result.recordCount EQ 0>
				<cfthrow type="ChildNotFound" message="No rows updated;">
			</cfif>
		<cfcatch>
			<cfset local.userMessage = trim(REReplace(cfcatch.message, "^ORA-[0-9]+:\\s*", "", "one"))>
			<cfset local.matchPos = REFindNoCase("(You cannot|This move|A container|Institution|The child|The position)", local.userMessage)>
			<cfif local.matchPos GT 0>
				<cfset local.userMessage = mid(local.userMessage, local.matchPos, len(local.userMessage) - local.matchPos + 1)>
			</cfif>
			<cfif len(trim(local.userMessage)) EQ 0>
				<cfset local.userMessage = "Unable to move container due to a placement rule. Please review the selected parent and try again.">
			</cfif>
			<cfif cfcatch.type EQ "ChildNotFound">
				<cfset local.userMessage = "Query Error: " + cfcatch.message + " Child container was not found. It may have been deleted or moved by another user.">
			</cfif>
			<cfset local.retval["status"] = "error">
			<cfset local.retval["message"] = local.userMessage>
			<cfreturn serializeJSON(local.retval)>
		</cfcatch>
		</cftry>

		<cfset local.retval["status"] = "moved">
		<cfset local.retval["child_container_id"] = queryChild.container_id>
		<cfset local.retval["child_label"] = queryChild.label>
		<cfset local.retval["child_type"] = queryChild.container_type>
		<cfset local.retval["parent_container_id"] = queryParent.container_id>
		<cfset local.retval["parent_label"] = queryParent.label>
		<cfset local.retval["parent_type"] = queryParent.container_type>
		<cfreturn serializeJSON(local.retval)>
	<cfcatch>
		<cfset local.retval = StructNew()>
		<cfset local.retval["status"] = "error">
		<cfset local.retval["message"] = trim(cfcatch.message)>
		<cfreturn serializeJSON(local.retval)>
	</cfcatch>
	</cftry>
</cffunction>

<!---
Function getPartsForContainerPlacementHTML. Resolves a cataloged item (by collection plus either
an other-ID type/value or a catalog number), then renders the specimen-context line and the whole
placement form -- Part selects (each option showing the barcode of whatever container currently
holds that part, if any), New Part button, Parent Barcode field, parent-retype controls (current
type, keep-current-type checkbox, New Container Type select excluding guarded types), badge
placeholders, and Move button -- as one HTML fragment for containers/placePartInContainer.cfm to
drop into its results area. Matches the specimens/component/functions.cfc getEditPartsHTML
convention of rendering a whole form region server-side rather than having JS assemble it.
@param collection_id the collection to search within.
@param other_id_type the other-ID type to match oidnum against, or the literal "catalog_number".
@param oidnum the ID number/value to match.
@param noBarcode when true, only include parts whose current container has no parent container
	(i.e. not yet placed inside another, barcoded container).
@param noSubsample when true, exclude parts that are themselves subsamples of another part.
@return HTML (plain text, not JSON) -- either an error message, or the full placement form.
--->
<!---
Function resolvePartCurrentContainer. Resolves a specimen part's actual current container to move
for placement purposes -- the part's own "collection object" leaf container, unless that leaf's
immediate parent is a "proxy"-role container (a single-occupant container type, e.g. pin/slide/
cryovial/envelope/glass vial, that can only ever hold one leaf -- see validateContainerPlacement's
CT3 rule), in which case the proxy is what actually gets re-parented, not the leaf trapped inside
it. Also resolves that entity's own current parent (needed to preflight/describe its *existing*
placement) and its current depth in the container tree (1 = root itself, 2 = directly under a
root/institution-level container, >2 = nested further) so callers can warn before moving something
already filed away several levels deep.
@param part_collection_object_id the specimen_part's own collection_object_id.
@return a struct: {found, leaf_container_id, leaf_label, leaf_barcode, leaf_type, is_proxy,
	move_container_id, move_label, move_barcode, move_type, current_parent_container_id,
	current_parent_label, current_parent_barcode, current_depth}.
--->
<cffunction name="resolvePartCurrentContainer" access="public" returntype="any" output="false">
	<cfargument name="part_collection_object_id" type="numeric" required="yes">

	<cfset local.retval = StructNew()>
	<cfset local.retval["found"] = false>

	<cfquery name="local.queryLeaf" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
		SELECT container.container_id, container.label, container.barcode, container.container_type, container.parent_container_id
		FROM coll_obj_cont_hist
			JOIN container ON coll_obj_cont_hist.container_id = container.container_id
		WHERE
			coll_obj_cont_hist.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.part_collection_object_id#">
			AND coll_obj_cont_hist.current_container_fg = 1
	</cfquery>
	<cfif local.queryLeaf.recordcount EQ 0>
		<cfreturn local.retval>
	</cfif>

	<cfset local.retval["found"] = true>
	<cfset local.retval["leaf_container_id"] = local.queryLeaf.container_id>
	<cfset local.retval["leaf_label"] = local.queryLeaf.label>
	<cfset local.retval["leaf_barcode"] = local.queryLeaf.barcode>
	<cfset local.retval["leaf_type"] = local.queryLeaf.container_type>
	<cfset local.retval["is_proxy"] = false>
	<cfset local.moveContainerId = local.queryLeaf.container_id>
	<cfset local.moveLabel = local.queryLeaf.label>
	<cfset local.moveBarcode = local.queryLeaf.barcode>
	<cfset local.moveType = local.queryLeaf.container_type>

	<cfif val(local.queryLeaf.parent_container_id) GT 0>
		<cfquery name="local.queryParent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
			SELECT container.container_id, container.label, container.barcode, container.container_type, ctcontainer_type.role
			FROM container
				JOIN ctcontainer_type ON container.container_type = ctcontainer_type.container_type
			WHERE container.container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#local.queryLeaf.parent_container_id#">
		</cfquery>
		<cfif local.queryParent.recordcount GT 0 AND local.queryParent.role EQ "proxy">
			<cfset local.retval["is_proxy"] = true>
			<cfset local.moveContainerId = local.queryParent.container_id>
			<cfset local.moveLabel = local.queryParent.label>
			<cfset local.moveBarcode = local.queryParent.barcode>
			<cfset local.moveType = local.queryParent.container_type>
		</cfif>
	</cfif>

	<cfset local.retval["move_container_id"] = local.moveContainerId>
	<cfset local.retval["move_label"] = local.moveLabel>
	<cfset local.retval["move_barcode"] = local.moveBarcode>
	<cfset local.retval["move_type"] = local.moveType>

	<cfquery name="local.queryCurrentParent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
		SELECT p.container_id, p.label, p.barcode
		FROM container c
			JOIN container p ON c.parent_container_id = p.container_id
		WHERE c.container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#local.moveContainerId#">
	</cfquery>
	<cfif local.queryCurrentParent.recordcount GT 0>
		<cfset local.retval["current_parent_container_id"] = local.queryCurrentParent.container_id>
		<cfset local.retval["current_parent_label"] = local.queryCurrentParent.label>
		<cfset local.retval["current_parent_barcode"] = local.queryCurrentParent.barcode>
	<cfelse>
		<cfset local.retval["current_parent_container_id"] = 0>
		<cfset local.retval["current_parent_label"] = "">
		<cfset local.retval["current_parent_barcode"] = "">
	</cfif>

	<cfquery name="local.queryDepth" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
		SELECT COUNT(*) AS depth
		FROM container
		START WITH container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#local.moveContainerId#">
		CONNECT BY PRIOR parent_container_id = container_id
	</cfquery>
	<cfset local.retval["current_depth"] = local.queryDepth.depth>

	<cfreturn local.retval>
</cffunction>

<!---
Function getContainerByBarcode. Resolves a barcode to its container's id/label/type -- used by
containers/placePartInContainer.cfm to show the target container's current type as soon as one is
chosen (via typing or the Choose... picker), independent of whether any part is checked yet (the
per-part placement preflight only runs once a part is selected, so it can't be relied on for this).
@param barcode barcode to resolve.
@return a JSON object: {status: "ok"|"notfound"|"error", message, container_id, label, barcode,
	container_type}.
--->
<cffunction name="getContainerByBarcode" access="remote" returntype="any" returnformat="json" output="false">
	<cfargument name="barcode" type="string" required="yes">

	<cfset local.retval = StructNew()>
	<cftry>
		<cfquery name="local.queryContainer" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
			SELECT container_id, label, barcode, container_type
			FROM container
			WHERE barcode = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(arguments.barcode)#">
		</cfquery>
		<cfif local.queryContainer.recordcount EQ 0>
			<cfset local.retval["status"] = "notfound">
			<cfset local.retval["message"] = "Barcode was not found.">
			<cfreturn serializeJSON(local.retval)>
		</cfif>
		<cfset local.retval["status"] = "ok">
		<cfset local.retval["container_id"] = local.queryContainer.container_id>
		<cfset local.retval["label"] = local.queryContainer.label>
		<cfset local.retval["barcode"] = local.queryContainer.barcode>
		<cfset local.retval["container_type"] = local.queryContainer.container_type>
		<cfreturn serializeJSON(local.retval)>
	<cfcatch>
		<cfset local.retval["status"] = "error">
		<cfset local.retval["message"] = trim(cfcatch.message)>
		<cfreturn serializeJSON(local.retval)>
	</cfcatch>
	</cftry>
</cffunction>

<cffunction name="getPartsForContainerPlacementHTML" access="remote" returntype="string" returnformat="plain" output="false">
	<cfargument name="collection_id" type="numeric" required="yes">
	<cfargument name="other_id_type" type="string" required="yes">
	<cfargument name="oidnum" type="string" required="yes">
	<cfargument name="noBarcode" type="boolean" required="no" default="false">
	<cfargument name="noSubsample" type="boolean" required="no" default="false">

	<cfsavecontent variable="local.html">
	<cfoutput>
	<cftry>
		<cfquery name="local.queryCatItem" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
			SELECT cataloged_item.collection_object_id, cataloged_item.cat_num, collection.collection_cde, collection.institution_acronym
			FROM cataloged_item
				JOIN collection ON cataloged_item.collection_id = collection.collection_id
				<cfif arguments.other_id_type NEQ "catalog_number">
					JOIN coll_obj_other_id_num ON cataloged_item.collection_object_id = coll_obj_other_id_num.collection_object_id
				</cfif>
			WHERE
				cataloged_item.collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.collection_id#">
				<cfif arguments.other_id_type NEQ "catalog_number">
					AND coll_obj_other_id_num.other_id_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.other_id_type#">
					AND coll_obj_other_id_num.display_value = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(arguments.oidnum)#">
				<cfelse>
					AND cataloged_item.cat_num = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(arguments.oidnum)#">
				</cfif>
		</cfquery>
		<cfif local.queryCatItem.recordcount EQ 0>
			<p class="text-danger">No specimen matches that collection and identifier.</p>
		<cfelseif local.queryCatItem.recordcount GT 1>
			<p class="text-danger">#local.queryCatItem.recordcount# specimens match that identifier -- it is not unique within this collection.</p>
		<cfelse>
			<cfset local.catalogedItemId = local.queryCatItem.collection_object_id>
			<cfset local.guid = "#local.queryCatItem.institution_acronym#:#local.queryCatItem.collection_cde#:#local.queryCatItem.cat_num#">
			<cfset local.guidUrl = "/guid/#encodeForURL(local.queryCatItem.institution_acronym)#:#encodeForURL(local.queryCatItem.collection_cde)#:#encodeForURL(local.queryCatItem.cat_num)#">
			<cfquery name="local.queryId" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
				SELECT MIN(scientific_name) AS scientific_name
				FROM identification
				WHERE
					collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#local.catalogedItemId#">
					AND accepted_id_fg = 1
			</cfquery>
			<cfquery name="local.queryTypeStatus" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
				SELECT DISTINCT type_status
				FROM citation
				WHERE
					collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#local.catalogedItemId#">
					AND type_status IS NOT NULL
				ORDER BY type_status
			</cfquery>
			<cfquery name="local.queryParts" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
				SELECT
					specimen_part.collection_object_id AS part_id,
					decode(specimen_part.sampled_from_obj_id, null, specimen_part.part_name, specimen_part.part_name || ' SAMPLE') AS part_name,
					specimen_part.preserve_method,
					coll_object.lot_count,
					coll_object.lot_count_modifier,
					coll_object_remark.coll_object_remarks AS part_remarks,
					part_container.container_id AS part_container_id
				FROM
					specimen_part
					JOIN coll_obj_cont_hist ON specimen_part.collection_object_id = coll_obj_cont_hist.collection_object_id
						AND coll_obj_cont_hist.current_container_fg = 1
					JOIN container part_container ON coll_obj_cont_hist.container_id = part_container.container_id
					LEFT JOIN coll_object ON coll_object.collection_object_id = specimen_part.collection_object_id
					LEFT JOIN coll_object_remark ON coll_object_remark.collection_object_id = specimen_part.collection_object_id
				WHERE
					specimen_part.derived_from_cat_item = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#local.catalogedItemId#">
					<cfif arguments.noBarcode>
						AND (part_container.parent_container_id = 0 OR part_container.parent_container_id IS NULL)
					</cfif>
					<cfif arguments.noSubsample>
						AND specimen_part.sampled_from_obj_id IS NULL
					</cfif>
				ORDER BY specimen_part.part_name
			</cfquery>
			<cfif local.queryParts.recordcount EQ 0>
				<p class="text-muted">No parts found for this specimen.</p>
			<cfelse>
				<cfset local.qNewTypes = getBulkRetypeableContainerTypes()>
				<cfset local.partWord = "parts">
				<cfif local.queryParts.recordcount EQ 1>
					<cfset local.partWord = "part">
				</cfif>
				<!--- Resolve each part's actual current container (proxy-aware) once, keyed by part_id,
					so the option labels and the breadcrumb/badge list below don't each re-derive it. --->
				<cfset local.partInfo = StructNew()>
				<cfloop query="local.queryParts">
					<cfset local.partInfo[local.queryParts.part_id] = resolvePartCurrentContainer(local.queryParts.part_id)>
				</cfloop>
				<input type="hidden" id="catalogedItemId" value="#local.catalogedItemId#">
				<p>
				#local.queryParts.recordcount# #local.partWord# found for <a href="#local.guidUrl#" target="_blank">#encodeForHtml(local.guid)#</a>.
				<cfif len(trim(local.queryId.scientific_name)) GT 0>
					Identified as <em>#encodeForHtml(local.queryId.scientific_name)#</em>.
				</cfif>
				<cfif local.queryTypeStatus.recordcount GT 0>
					Type status: #encodeForHtml(ValueList(local.queryTypeStatus.type_status, ", "))#.
				</cfif>
			</p>
				<div class="table-responsive">
					<table class="table table-sm" id="partsTable">
						<thead>
							<tr>
								<th><span class="sr-only">Include in move</span></th>
								<th>Part</th>
								<th>Prep. Type</th>
								<th>Lot Count</th>
								<th>Modifier</th>
								<th>Remarks</th>
								<th>Current Placement</th>
								<th>Placement</th>
							</tr>
						</thead>
						<tbody>
							<cfloop query="local.queryParts">
								<cfset local.thisPartInfo = local.partInfo[local.queryParts.part_id]>
								<cfquery name="local.queryBreadcrumb" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
									SELECT label, barcode, container_type, LEVEL AS lvl
									FROM container
									START WITH container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#local.queryParts.part_container_id#">
									CONNECT BY PRIOR parent_container_id = container_id
									ORDER BY lvl DESC
								</cfquery>
								<tr>
									<td>
										<input type="checkbox" class="part-select-checkbox" id="partSelect_#local.queryParts.part_id#" value="#local.queryParts.part_id#" data-part-name="#encodeForHtml(local.queryParts.part_name)#" onchange="onPartSelectionChange(this);">
										<label class="sr-only" for="partSelect_#local.queryParts.part_id#">Include #encodeForHtml(local.queryParts.part_name)# in move</label>
									</td>
									<td>#encodeForHtml(local.queryParts.part_name)#</td>
									<td>#encodeForHtml(local.queryParts.preserve_method)#</td>
									<td>#encodeForHtml(local.queryParts.lot_count)#</td>
									<td>#encodeForHtml(local.queryParts.lot_count_modifier)#</td>
									<td>#encodeForHtml(local.queryParts.part_remarks)#</td>
									<td>
										<cfif len(trim(local.thisPartInfo.current_parent_barcode)) GT 0>
											#encodeForHtml(local.thisPartInfo.current_parent_barcode)#
										<cfelse>
											<span class="text-muted">unplaced</span>
										</cfif>
									</td>
									<td><span id="currentPlacementBadge_#local.queryParts.part_id#" role="status" data-part-id="#local.queryParts.part_id#" data-current-parent-barcode="#encodeForHtml(local.thisPartInfo.current_parent_barcode)#"></span></td>
								</tr>
								<tr>
									<td class="border-top-0"></td>
									<td colspan="7" class="small text-muted border-top-0 pt-1 pb-2">
										<cfloop query="local.queryBreadcrumb">
											<cfset local.crumbLabel = local.queryBreadcrumb.barcode>
											<cfif len(trim(local.crumbLabel)) EQ 0>
												<cfset local.crumbLabel = local.queryBreadcrumb.label>
											</cfif>
											#encodeForHtml(local.crumbLabel)# (#encodeForHtml(local.queryBreadcrumb.container_type)#)<cfif local.queryBreadcrumb.currentRow LT local.queryBreadcrumb.recordcount> &rsaquo; </cfif>
										</cfloop>
										<a href="/containers/viewContainer.cfm?container_id=#local.queryParts.part_container_id#" target="_blank" class="btn btn-xs btn-info ml-1">Details</a>
										<cfif local.thisPartInfo.is_proxy>
											<div>This part's #encodeForHtml(local.thisPartInfo.leaf_type)# is held inside a #encodeForHtml(local.thisPartInfo.move_type)# (a single-occupant container) -- moving this part will move the #encodeForHtml(local.thisPartInfo.move_type)#, not the #encodeForHtml(local.thisPartInfo.leaf_type)# directly.</div>
										</cfif>
									</td>
								</tr>
							</cfloop>
						</tbody>
					</table>
				</div>
				<button type="button" id="newPartBtn" class="btn btn-xs btn-secondary my-2" onclick="openNewPartDialog();">New Part</button>
				<div class="row border rounded mx-0 my-2 pt-2 pb-1 px-2">
					<h2 class="h5 col-12 mb-1">Place into Container:</h2>
					<div class="col-12 col-xl-4 mb-2">
						<label for="parent_barcode" class="data-entry-label">Container to place into</label>
						<div class="d-flex align-items-center form-row">
							<div class="col-8 pr-1">
								<input type="text" name="parent_barcode" id="parent_barcode" class="data-entry-input col-12 reqdClr" required aria-required="true" onchange="onParentBarcodeChange();">
							</div>
							<div class="col-4 pl-0">
								<button type="button" id="chooseParentContainerBtn" class="btn btn-xs btn-secondary" onclick="openParentContainerPicker();">Choose...</button>
							</div>
						</div>
					</div>
					<div class="col-12 col-xl-3 mb-2">
						<span class="data-entry-label">Container Type</span>
						<div><small class="text-muted">Currently: <strong id="currentParentType">&ndash;</strong></small></div>
					</div>
					<div class="col-12 col-xl-5 mb-2">
						<span class="data-entry-label">Change Type</span>
						<div class="d-flex align-items-center flex-wrap">
							<div class="form-check mr-2">
								<input type="checkbox" class="form-check-input" id="keepCurrentType" checked onchange="onKeepCurrentTypeChange();">
								<label class="form-check-label" for="keepCurrentType">Keep current type</label>
							</div>
							<select name="new_container_type" id="new_container_type" class="data-entry-select" style="display:none;" onchange="onNewContainerTypeChange();">
								<option value=""></option>
								<cfloop query="local.qNewTypes">
									<option value="#encodeForHtml(local.qNewTypes.container_type)#">#encodeForHtml(local.qNewTypes.container_type)#</option>
								</cfloop>
							</select>
						</div>
						<span id="retypeBadge" role="status"></span>
					</div>
					<div class="col-12">
						<button type="button" id="moveBtn" class="btn btn-xs btn-primary" disabled onclick="commitPlacement();">Move</button>
					</div>
				</div>
			</cfif>
		</cfif>
	<cfcatch>
		<p class="text-danger">Error: #encodeForHtml(cfcatch.message)#</p>
	</cfcatch>
	</cftry>
	</cfoutput>
	</cfsavecontent>
	<cfreturn local.html>
</cffunction>

<!---
Function preflightPlacePartByBarcode. Resolves a specimen part's actual current container to move
(the part's own leaf, or its proxy parent when one is present -- see resolvePartCurrentContainer)
and a destination parent barcode, then runs placement preflight validation -- used before actually
moving a part on containers/placePartInContainer.cfm.
@param part_collection_object_id the specimen_part's own collection_object_id.
@param parent_barcode barcode of the destination parent container.
@return a JSON object with status (ok|notfound|error), placement validation keys from
	validateContainerPlacement (allowed, severity, warnings, blocks, parent_type -- the parent's
	current container_type, before any retype -- etc), and context keys: child_container_id,
	parent_container_id, parent_label, parent_barcode, is_proxy, leaf_type, move_type,
	current_depth (the moved container's current depth in the tree, 1=root).
--->
<cffunction name="preflightPlacePartByBarcode" access="remote" returntype="any" returnformat="json" output="false">
	<cfargument name="part_collection_object_id" type="numeric" required="yes">
	<cfargument name="parent_barcode" type="string" required="yes">

	<cfset local.retval = StructNew()>
	<cftry>
		<cfset local.partContainer = resolvePartCurrentContainer(arguments.part_collection_object_id)>
		<cfif NOT local.partContainer.found>
			<cfset local.retval["status"] = "notfound">
			<cfset local.retval["message"] = "This part's current container could not be found.">
			<cfset local.retval["missing"] = "child">
			<cfreturn serializeJSON(local.retval)>
		</cfif>

		<cfquery name="local.queryParent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
			SELECT container_id, label, barcode
			FROM container
			WHERE barcode = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(arguments.parent_barcode)#">
		</cfquery>
		<cfif local.queryParent.recordcount EQ 0>
			<cfset local.retval["status"] = "notfound">
			<cfset local.retval["message"] = "Parent barcode was not found.">
			<cfset local.retval["missing"] = "parent">
			<cfreturn serializeJSON(local.retval)>
		</cfif>

		<cfset local.validationResult = validateContainerPlacement(
			child_container_id=local.partContainer.move_container_id,
			proposed_parent_container_id=local.queryParent.container_id
		)>
		<cfif isSimpleValue(local.validationResult)>
			<cfset local.validationResult = deserializeJSON(local.validationResult)>
		</cfif>

		<cfset local.validationResult["status"] = "ok">
		<cfset local.validationResult["child_container_id"] = local.partContainer.move_container_id>
		<cfset local.validationResult["child_label"] = local.partContainer.move_label>
		<cfset local.validationResult["child_barcode"] = local.partContainer.move_barcode>
		<cfset local.validationResult["is_proxy"] = local.partContainer.is_proxy>
		<cfset local.validationResult["leaf_type"] = local.partContainer.leaf_type>
		<cfset local.validationResult["move_type"] = local.partContainer.move_type>
		<cfset local.validationResult["current_depth"] = local.partContainer.current_depth>
		<cfset local.validationResult["parent_container_id"] = local.queryParent.container_id>
		<cfset local.validationResult["parent_label"] = local.queryParent.label>
		<cfset local.validationResult["parent_barcode"] = local.queryParent.barcode>
		<cfreturn serializeJSON(local.validationResult)>
	<cfcatch>
		<cfset local.retval = StructNew()>
		<cfset local.retval["status"] = "error">
		<cfset local.retval["message"] = trim(cfcatch.message)>
		<cfreturn serializeJSON(local.retval)>
	</cfcatch>
	</cftry>
</cffunction>

<!---
Function placePartByBarcode. Moves a specimen part's actual current container (the part's own leaf,
or its proxy parent when one is present -- see resolvePartCurrentContainer) into a new parent
container by barcode -- the explicit commit step behind containers/placePartInContainer.cfm's
preflight badge. Delegates the actual move (and its trigger-error handling) to moveContainerById
once both containers are resolved.
@param part_collection_object_id the specimen_part's own collection_object_id.
@param parent_barcode barcode of the destination parent container.
@param move_timestamp optional timestamp string (YYYY-MM-DD HH24:MI:SS) for parent_install_date.
@return a JSON object with status (moved|notfound|error) and message, plus context fields:
	child_container_id, parent_container_id, missing (when notfound).
--->
<cffunction name="placePartByBarcode" access="remote" returntype="any" returnformat="json" output="false">
	<cfargument name="part_collection_object_id" type="numeric" required="yes">
	<cfargument name="parent_barcode" type="string" required="yes">
	<cfargument name="move_timestamp" type="string" required="no" default="">

	<cfset local.retval = StructNew()>

	<cfif NOT (isdefined("session.roles") AND listfindnocase(session.roles, "manage_container") GT 0)>
		<cfset local.retval["status"] = "error">
		<cfset local.retval["message"] = "You do not have permission to move containers.">
		<cfreturn serializeJSON(local.retval)>
	</cfif>

	<cftry>
		<cfset local.partContainer = resolvePartCurrentContainer(arguments.part_collection_object_id)>
		<cfif NOT local.partContainer.found>
			<cfset local.retval["status"] = "notfound">
			<cfset local.retval["message"] = "This part's current container could not be found.">
			<cfset local.retval["missing"] = "child">
			<cfreturn serializeJSON(local.retval)>
		</cfif>

		<cfquery name="local.queryParent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
			SELECT container_id
			FROM container
			WHERE barcode = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(arguments.parent_barcode)#">
		</cfquery>
		<cfif local.queryParent.recordcount EQ 0>
			<cfset local.retval["status"] = "notfound">
			<cfset local.retval["message"] = "Parent barcode was not found.">
			<cfset local.retval["missing"] = "parent">
			<cfreturn serializeJSON(local.retval)>
		</cfif>

		<cfreturn moveContainerById(
			child_container_id=local.partContainer.move_container_id,
			parent_container_id=local.queryParent.container_id,
			move_timestamp=arguments.move_timestamp
		)>
	<cfcatch>
		<cfset local.retval["status"] = "error">
		<cfset local.retval["message"] = trim(cfcatch.message)>
		<cfreturn serializeJSON(local.retval)>
	</cfcatch>
	</cftry>
</cffunction>

<!---
Function getNewPartFormHTML. Renders the "New Part" dialog's form fields for
containers/placePartInContainer.cfm -- vocab selects (part name and preserve method filtered to
the specimen's own collection via its collection_cde, disposition and lot-count modifier global,
matching the vocab sources specimens/component/functions.cfc's getEditPartsHTML already uses for
the same fields) plus the plain input fields createSpecimenPart also needs -- as one HTML fragment
for the dialog container to be filled with.
@param collection_id the collection the new part's cataloged item belongs to.
@return HTML (plain text, not JSON) -- either an error message, or the New Part form fields.
--->
<cffunction name="getNewPartFormHTML" access="remote" returntype="string" returnformat="plain" output="false">
	<cfargument name="collection_id" type="numeric" required="yes">

	<cfsavecontent variable="local.html">
	<cfoutput>
	<cftry>
		<cfquery name="local.queryCollection" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
			SELECT collection_cde FROM collection
			WHERE collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.collection_id#">
		</cfquery>
		<cfif local.queryCollection.recordcount EQ 0>
			<p class="text-danger">Collection was not found.</p>
		<cfelse>
			<cfquery name="local.queryDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
				SELECT coll_obj_disposition FROM ctcoll_obj_disp ORDER BY coll_obj_disposition
			</cfquery>
			<cfquery name="local.queryModifiers" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
				SELECT modifier FROM ctnumeric_modifiers ORDER BY modifier DESC
			</cfquery>
			<cfquery name="local.queryPartNames" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
				SELECT part_name FROM ctspecimen_part_name
				WHERE collection_cde = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#local.queryCollection.collection_cde#">
				ORDER BY part_name
			</cfquery>
			<cfquery name="local.queryPreserveMethods" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
				SELECT preserve_method FROM ctspecimen_preserv_method
				WHERE collection_cde = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#local.queryCollection.collection_cde#">
				ORDER BY preserve_method
			</cfquery>
			<div class="form-row mb-2">
				<div class="col-12">
					<label for="npart_name" class="data-entry-label">Part Name</label>
					<select name="npart_name" id="npart_name" class="data-entry-select reqdClr" required aria-required="true">
						<cfloop query="local.queryPartNames">
							<option value="#encodeForHtml(local.queryPartNames.part_name)#">#encodeForHtml(local.queryPartNames.part_name)#</option>
						</cfloop>
					</select>
				</div>
			</div>
			<div class="form-row mb-2">
				<div class="col-6">
					<label for="npreserve_method" class="data-entry-label">Preserve Method</label>
					<select name="npreserve_method" id="npreserve_method" class="data-entry-select reqdClr" required aria-required="true">
						<cfloop query="local.queryPreserveMethods">
							<option value="#encodeForHtml(local.queryPreserveMethods.preserve_method)#">#encodeForHtml(local.queryPreserveMethods.preserve_method)#</option>
						</cfloop>
					</select>
				</div>
				<div class="col-3">
					<label for="nlot_count" class="data-entry-label">Lot Count</label>
					<input type="text" name="nlot_count" id="nlot_count" class="data-entry-input reqdClr" required aria-required="true">
				</div>
				<div class="col-3">
					<label for="nlot_count_modifier" class="data-entry-label">Modifier</label>
					<select name="nlot_count_modifier" id="nlot_count_modifier" class="data-entry-select">
						<option value=""></option>
						<cfloop query="local.queryModifiers">
							<option value="#encodeForHtml(local.queryModifiers.modifier)#">#encodeForHtml(local.queryModifiers.modifier)#</option>
						</cfloop>
					</select>
				</div>
			</div>
			<div class="form-row mb-2">
				<div class="col-6">
					<label for="ncoll_obj_disposition" class="data-entry-label">Disposition</label>
					<select name="ncoll_obj_disposition" id="ncoll_obj_disposition" class="data-entry-select reqdClr" required aria-required="true">
						<cfloop query="local.queryDisp">
							<option value="#encodeForHtml(local.queryDisp.coll_obj_disposition)#">#encodeForHtml(local.queryDisp.coll_obj_disposition)#</option>
						</cfloop>
					</select>
				</div>
				<div class="col-6">
					<label for="ncondition" class="data-entry-label">Condition</label>
					<input type="text" name="ncondition" id="ncondition" class="data-entry-input reqdClr" required aria-required="true">
				</div>
			</div>
			<div class="form-row mb-2">
				<div class="col-6">
					<label for="ncondition_remarks" class="data-entry-label">Condition Remarks</label>
					<input type="text" name="ncondition_remarks" id="ncondition_remarks" class="data-entry-input">
				</div>
				<div class="col-6">
					<label for="ncoll_object_remarks" class="data-entry-label">Remarks</label>
					<input type="text" name="ncoll_object_remarks" id="ncoll_object_remarks" class="data-entry-input">
				</div>
			</div>
			<output id="newPartFeedback" class="d-block my-2">&nbsp;</output>
			<button type="button" id="createPartBtn" class="btn btn-xs btn-primary" onclick="submitNewPart();">Create</button>
		</cfif>
	<cfcatch>
		<p class="text-danger">Error: #encodeForHtml(cfcatch.message)#</p>
	</cfcatch>
	</cftry>
	</cfoutput>
	</cfsavecontent>
	<cfreturn local.html>
</cffunction>

<!---
Function placeContainerIntoPositionByBarcode.  Looks up a scanned/typed barcode and, if it
matches an existing container, places that container into the given position container by
delegating to moveContainerById.  Supports the positions-grid scan-to-place workflow on
viewContainer.cfm.  Returns status JSON and never aborts on trigger errors.

@param barcode barcode scanned or typed into the empty position's input.
@param position_container_id container_id of the empty position container to place into.
@return a JSON object with status (moved|notfound|error) and message, plus context fields:
	child_container_id, child_label, child_barcode, child_type, parent_container_id (when moved).
--->
<cffunction name="placeContainerIntoPositionByBarcode" access="remote" returntype="any" returnformat="json" output="false">
	<cfargument name="barcode" type="string" required="yes">
	<cfargument name="position_container_id" type="numeric" required="yes">

	<cfset local.retval = StructNew()>
	<cftry>
		<cfif NOT (isdefined("session.roles") AND listfindnocase(session.roles, "manage_container") GT 0)>
			<cfset local.retval["status"] = "error">
			<cfset local.retval["message"] = "You do not have permission to place containers.">
			<cfreturn serializeJSON(local.retval)>
		</cfif>

		<cfset local.trimmedBarcode = trim(arguments.barcode)>
		<cfif len(local.trimmedBarcode) EQ 0>
			<cfset local.retval["status"] = "notfound">
			<cfset local.retval["message"] = "Enter or scan a barcode.">
			<cfset local.retval["missing"] = "child">
			<cfreturn serializeJSON(local.retval)>
		</cfif>

		<cfquery name="queryChild" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
			SELECT container_id, label, barcode, container_type
			FROM container
			WHERE barcode = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#local.trimmedBarcode#">
		</cfquery>
		<cfif queryChild.recordcount EQ 0>
			<cfset local.retval["status"] = "notfound">
			<!--- encodeForHtml to prevent XSS if barcode contains HTML special characters, which will look ugly, but not for normal inputs --->
			<cfset local.retval["message"] = "No container found with barcode '#encodeForHTML(local.trimmedBarcode)#'.">
			<cfset local.retval["missing"] = "child">
			<cfreturn serializeJSON(local.retval)>
		</cfif>

		<cfset local.moveResult = deserializeJSON(moveContainerById(
			child_container_id=queryChild.container_id,
			parent_container_id=arguments.position_container_id
		))>
		<cfset local.moveResult["child_barcode"] = queryChild.barcode>
		<cfreturn serializeJSON(local.moveResult)>
	<cfcatch>
		<cfset local.retval = StructNew()>
		<cfset local.retval["status"] = "error">
		<cfset local.retval["message"] = trim(cfcatch.message)>
		<cfreturn serializeJSON(local.retval)>
	</cfcatch>
	</cftry>
</cffunction>

<!---
Function getBulkRetypeGuardedContainerTypes. Returns the container_type values that must never be
used as the Original or New Container Type on the bulk retype tool (containers/bulkModifyContainers.cfm)
-- the root/administrative hierarchy levels (institution, campus, building) and collection object
(a specimen record, not a physical container). Centralized here so the guard can't drift between the
dropdown-exclusion list and the server-side check.
@return an array of lowercase container_type strings.
--->
<cffunction name="getBulkRetypeGuardedContainerTypes" access="public" returntype="array" output="false">
	<cfset var guarded = ArrayNew(1)>
	<cfset ArrayAppend(guarded, "collection object")>
	<cfset ArrayAppend(guarded, "institution")>
	<cfset ArrayAppend(guarded, "campus")>
	<cfset ArrayAppend(guarded, "building")>
	<cfreturn guarded>
</cffunction>

<!---
Function getBulkRetypeableContainerTypes. Returns the container_type values selectable as either the
Original or New Container Type on the bulk retype tool, excluding the guarded types (see
getBulkRetypeGuardedContainerTypes) that must never be bulk-retyped into or out of.
@return a query of container_type, ordered alphabetically.
--->
<cffunction name="getBulkRetypeableContainerTypes" access="public" returntype="query" output="false">
	<cfset var guardedList = ArrayToList(getBulkRetypeGuardedContainerTypes())>
	<cfquery name="getTypes" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
		SELECT DISTINCT container_type
		FROM ctcontainer_type
		WHERE
			container_type NOT IN (<cfqueryparam value="#guardedList#" cfsqltype="CF_SQL_VARCHAR" list="true">)
		ORDER BY container_type
	</cfquery>
	<cfreturn getTypes>
</cffunction>

<!---
Function previewBulkRetypeRange. Resolves a barcode_prefix + integer range into actual containers,
for the range-analysis step of the bulk retype tool. Fetches candidates with a single parameterized
LIKE query rather than a WHERE barcode IN (...) built from the whole range, since Oracle caps an
IN-list at 1000 expressions and this tool is expected to handle ranges of a few thousand; each range
member is then confirmed with an exact string match in CF (barcode = barcode_prefix & i), matching
the original tool's exact matching logic rather than trusting the LIKE pattern alone (which would
also match longer barcodes that merely share the same prefix).
@param barcode_prefix literal prefix shared by every barcode in the range.
@param begin_barcode low end of the inclusive integer range.
@param end_barcode high end of the inclusive integer range.
@return a struct: rangeSize, matchedCount, missingCount, missingBarcodes (array, capped at 100),
	missingBarcodesTruncated (boolean), typeCounts (array of {container_type, type_count}, sorted
	by type_count descending).
--->
<cffunction name="previewBulkRetypeRange" access="public" returntype="struct" output="false">
	<cfargument name="barcode_prefix" type="string" required="yes">
	<cfargument name="begin_barcode" type="numeric" required="yes">
	<cfargument name="end_barcode" type="numeric" required="yes">

	<cfset var MAX_LISTED_MISSING = 100>
	<cfset var result = StructNew()>
	<cfset var candidates = "">
	<cfset var foundByBarcode = StructNew()>
	<cfset var typeCounts = StructNew()>
	<cfset var typeCountsArray = ArrayNew(1)>
	<cfset var sortedTypeCounts = ArrayNew(1)>
	<cfset var remaining = "">
	<cfset var expectedBarcode = "">
	<cfset var thisType = "">
	<cfset var i = 0>
	<cfset var j = 0>
	<cfset var maxIndex = 0>
	<cfset var typeName = "">
	<cfset var row = StructNew()>

	<cfset result["rangeSize"] = (arguments.end_barcode - arguments.begin_barcode) + 1>
	<cfset result["matchedCount"] = 0>
	<cfset result["missingCount"] = 0>
	<cfset result["missingBarcodes"] = ArrayNew(1)>
	<cfset result["missingBarcodesTruncated"] = false>

	<cfquery name="candidates" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
		SELECT barcode, container_type
		FROM container
		WHERE barcode LIKE <cfqueryparam value="#arguments.barcode_prefix#%" cfsqltype="CF_SQL_VARCHAR">
	</cfquery>

	<cfloop query="candidates">
		<cfset foundByBarcode[candidates.barcode] = candidates.container_type>
	</cfloop>

	<cfloop from="#arguments.begin_barcode#" to="#arguments.end_barcode#" index="i">
		<cfset expectedBarcode = arguments.barcode_prefix & i>
		<cfif structKeyExists(foundByBarcode, expectedBarcode)>
			<cfset result["matchedCount"] = result["matchedCount"] + 1>
			<cfset thisType = foundByBarcode[expectedBarcode]>
			<cfif NOT structKeyExists(typeCounts, thisType)>
				<cfset typeCounts[thisType] = 0>
			</cfif>
			<cfset typeCounts[thisType] = typeCounts[thisType] + 1>
		<cfelse>
			<cfset result["missingCount"] = result["missingCount"] + 1>
			<cfif ArrayLen(result["missingBarcodes"]) LT MAX_LISTED_MISSING>
				<cfset ArrayAppend(result["missingBarcodes"], expectedBarcode)>
			<cfelse>
				<cfset result["missingBarcodesTruncated"] = true>
			</cfif>
		</cfif>
	</cfloop>

	<cfloop collection="#typeCounts#" item="typeName">
		<cfset row = StructNew()>
		<cfset row["container_type"] = typeName>
		<cfset row["type_count"] = typeCounts[typeName]>
		<cfset ArrayAppend(typeCountsArray, row)>
	</cfloop>

	<!--- manual selection sort by type_count descending -- avoids relying on closure-based ArraySort
		callbacks that may not be available on every CFML engine this application is deployed to --->
	<cfset remaining = typeCountsArray>
	<cfloop condition="ArrayLen(remaining) GT 0">
		<cfset maxIndex = 1>
		<cfloop from="2" to="#ArrayLen(remaining)#" index="j">
			<cfif remaining[j].type_count GT remaining[maxIndex].type_count>
				<cfset maxIndex = j>
			</cfif>
		</cfloop>
		<cfset ArrayAppend(sortedTypeCounts, remaining[maxIndex])>
		<cfset ArrayDeleteAt(remaining, maxIndex)>
	</cfloop>
	<cfset result["typeCounts"] = sortedTypeCounts>

	<cfreturn result>
</cffunction>

<!---
Function getContainersInRange. Resolves a barcode_prefix + integer range, filtered to containers
currently of orig_container_type, for the change-entry/dry-run/apply steps of the bulk retype tool.
Uses the same LIKE-then-exact-match approach as previewBulkRetypeRange to avoid Oracle's IN-list
size limit, and returns an array of structs rather than a query object so each field keeps whatever
type the database driver already gave it, without needing to hand-build a new typed query.
@param barcode_prefix literal prefix shared by every barcode in the range.
@param begin_barcode low end of the inclusive integer range.
@param end_barcode high end of the inclusive integer range.
@param orig_container_type only containers currently of this type are included.
@return an array of structs: container_id, barcode, label, container_type, parent_container_id,
	description, container_remarks, height, length, width, number_positions.
--->
<cffunction name="getContainersInRange" access="public" returntype="array" output="false">
	<cfargument name="barcode_prefix" type="string" required="yes">
	<cfargument name="begin_barcode" type="numeric" required="yes">
	<cfargument name="end_barcode" type="numeric" required="yes">
	<cfargument name="orig_container_type" type="string" required="yes">

	<cfset var candidates = "">
	<cfset var matchedBarcodes = StructNew()>
	<cfset var results = ArrayNew(1)>
	<cfset var i = 0>
	<cfset var row = StructNew()>

	<cfquery name="candidates" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
		SELECT container_id, barcode, label, container_type, parent_container_id,
			description, container_remarks, height, length, width, number_positions
		FROM container
		WHERE
			barcode LIKE <cfqueryparam value="#arguments.barcode_prefix#%" cfsqltype="CF_SQL_VARCHAR">
			AND container_type = <cfqueryparam value="#arguments.orig_container_type#" cfsqltype="CF_SQL_VARCHAR">
	</cfquery>

	<cfloop from="#arguments.begin_barcode#" to="#arguments.end_barcode#" index="i">
		<cfset matchedBarcodes[arguments.barcode_prefix & i] = true>
	</cfloop>

	<cfloop query="candidates">
		<cfif structKeyExists(matchedBarcodes, candidates.barcode)>
			<cfset row = StructNew()>
			<cfset row["container_id"] = candidates.container_id>
			<cfset row["barcode"] = candidates.barcode>
			<cfset row["label"] = candidates.label>
			<cfset row["container_type"] = candidates.container_type>
			<cfset row["parent_container_id"] = candidates.parent_container_id>
			<cfset row["description"] = candidates.description>
			<cfset row["container_remarks"] = candidates.container_remarks>
			<cfset row["height"] = candidates.height>
			<cfset row["length"] = candidates.length>
			<cfset row["width"] = candidates.width>
			<cfset row["number_positions"] = candidates.number_positions>
			<cfset ArrayAppend(results, row)>
		</cfif>
	</cfloop>

	<cfreturn results>
</cffunction>

<!---
Function summarizeContainerProperties. Counts how many containers in a set (as returned by
getContainersInRange) have a value for each of description, container_remarks, height, length,
width, and number_positions -- used by the bulk retype tool's range-analysis and change-entry pages
to show what's actually populated before deciding what to overwrite. For the numeric dimension/
position fields, 0 counts as not-set (this data uses 0 to mean "no value recorded", not a real
zero-size dimension), not just blank/null. For description and container_remarks, also reports how
many distinct non-blank values exist and up to 3 example values, since "N have a description" alone
doesn't say whether that's one shared boilerplate value or genuinely varied text.
@param containers array of structs as returned by getContainersInRange.
@return a struct: totalCount, descriptionCount, descriptionDistinctCount, descriptionExamples (array,
	up to 3), remarksCount, remarksDistinctCount, remarksExamples (array, up to 3), heightCount,
	lengthCount, widthCount, positionsCount.
--->
<cffunction name="summarizeContainerProperties" access="public" returntype="struct" output="false">
	<cfargument name="containers" type="array" required="yes">

	<cfset var MAX_EXAMPLES = 3>
	<cfset var summary = StructNew()>
	<cfset var i = 0>
	<cfset var seenDescriptions = StructNew()>
	<cfset var seenRemarks = StructNew()>
	<cfset summary["totalCount"] = ArrayLen(arguments.containers)>
	<cfset summary["descriptionCount"] = 0>
	<cfset summary["descriptionDistinctCount"] = 0>
	<cfset summary["descriptionExamples"] = ArrayNew(1)>
	<cfset summary["remarksCount"] = 0>
	<cfset summary["remarksDistinctCount"] = 0>
	<cfset summary["remarksExamples"] = ArrayNew(1)>
	<cfset summary["heightCount"] = 0>
	<cfset summary["lengthCount"] = 0>
	<cfset summary["widthCount"] = 0>
	<cfset summary["positionsCount"] = 0>

	<cfloop from="1" to="#ArrayLen(arguments.containers)#" index="i">
		<cfif len(trim(arguments.containers[i].description)) GT 0>
			<cfset summary["descriptionCount"] = summary["descriptionCount"] + 1>
			<cfif NOT structKeyExists(seenDescriptions, arguments.containers[i].description)>
				<cfset seenDescriptions[arguments.containers[i].description] = true>
				<cfset summary["descriptionDistinctCount"] = summary["descriptionDistinctCount"] + 1>
				<cfif ArrayLen(summary["descriptionExamples"]) LT MAX_EXAMPLES>
					<cfset ArrayAppend(summary["descriptionExamples"], arguments.containers[i].description)>
				</cfif>
			</cfif>
		</cfif>
		<cfif len(trim(arguments.containers[i].container_remarks)) GT 0>
			<cfset summary["remarksCount"] = summary["remarksCount"] + 1>
			<cfif NOT structKeyExists(seenRemarks, arguments.containers[i].container_remarks)>
				<cfset seenRemarks[arguments.containers[i].container_remarks] = true>
				<cfset summary["remarksDistinctCount"] = summary["remarksDistinctCount"] + 1>
				<cfif ArrayLen(summary["remarksExamples"]) LT MAX_EXAMPLES>
					<cfset ArrayAppend(summary["remarksExamples"], arguments.containers[i].container_remarks)>
				</cfif>
			</cfif>
		</cfif>
		<cfif len(trim(arguments.containers[i].height)) GT 0 AND val(arguments.containers[i].height) NEQ 0>
			<cfset summary["heightCount"] = summary["heightCount"] + 1>
		</cfif>
		<cfif len(trim(arguments.containers[i].length)) GT 0 AND val(arguments.containers[i].length) NEQ 0>
			<cfset summary["lengthCount"] = summary["lengthCount"] + 1>
		</cfif>
		<cfif len(trim(arguments.containers[i].width)) GT 0 AND val(arguments.containers[i].width) NEQ 0>
			<cfset summary["widthCount"] = summary["widthCount"] + 1>
		</cfif>
		<cfif len(trim(arguments.containers[i].number_positions)) GT 0 AND val(arguments.containers[i].number_positions) NEQ 0>
			<cfset summary["positionsCount"] = summary["positionsCount"] + 1>
		</cfif>
	</cfloop>

	<cfreturn summary>
</cffunction>

<!---
Function validateContainerRetype. Checks whether changing an existing container's type to a new type
is still compatible with its CURRENT parent and CURRENT children. There is no database trigger
protecting a bare container_type change today (unlike moves, which MCZBASE.MOVE_CONTAINER enforces --
confirmed by inspecting saveContainer below, which updates container_type in the same statement as
parent_container_id but has none of moveContainerById's ORA- message-scrubbing for a trigger error),
so this is a new, app-only safety net for the bulk retype tool, not a mirror of an existing trigger.
Mirrors validateContainerPlacement's severity/warnings/blocks/field shape so the shared
renderPlacementWarningBadge JS function can render its result unmodified.
@param container_id the container being considered for retype.
@param new_container_type the proposed new container_type.
@return JSON: allowed, severity (ok|warn|block), warnings[], blocks[], child_type (set to
	new_container_type, named for badge-renderer compatibility), expected_parent_types,
	force_expected_parent_type, is_root_placement, current_type, parent_type, child_count.
--->
<cffunction name="validateContainerRetype" access="remote" returntype="any" returnformat="json" output="false">
	<cfargument name="container_id" type="numeric" required="yes">
	<cfargument name="new_container_type" type="string" required="yes">

	<cfset local.retval = StructNew()>
	<cfset local.retval["allowed"] = true>
	<cfset local.retval["severity"] = "ok">
	<cfset local.retval["warnings"] = ArrayNew(1)>
	<cfset local.retval["blocks"] = ArrayNew(1)>
	<cfset local.retval["child_type"] = arguments.new_container_type>

	<cfif listFindNoCase(ArrayToList(getBulkRetypeGuardedContainerTypes()), arguments.new_container_type) GT 0>
		<cfset local.retval["allowed"] = false>
		<cfset local.retval["severity"] = "block">
		<cfset ArrayAppend(local.retval["blocks"], "#arguments.new_container_type# is not a type containers can be bulk-retyped into.")>
		<cfreturn serializeJSON(local.retval)>
	</cfif>

	<cftry>
		<cfquery name="local.queryContainer" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
			SELECT container_id, container_type, parent_container_id
			FROM container
			WHERE container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.container_id#">
		</cfquery>
		<cfif local.queryContainer.recordcount EQ 0>
			<cfset local.retval["allowed"] = false>
			<cfset local.retval["severity"] = "block">
			<cfset ArrayAppend(local.retval["blocks"], "Container was not found.")>
			<cfreturn serializeJSON(local.retval)>
		</cfif>

		<cfquery name="local.queryNewType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
			SELECT role, NVL(expects_leaf_child_count, 0) AS expects_leaf_child_count,
				NVL(expected_parent_types, 'any') AS expected_parent_types,
				NVL(force_expected_parent_type, 0) AS force_expected_parent_type,
				rank_order, NVL(variable_rank, 0) AS variable_rank
			FROM ctcontainer_type
			WHERE container_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.new_container_type#">
		</cfquery>
		<cfif local.queryNewType.recordcount EQ 0>
			<cfset local.retval["allowed"] = false>
			<cfset local.retval["severity"] = "block">
			<cfset ArrayAppend(local.retval["blocks"], "The new container type was not found.")>
			<cfreturn serializeJSON(local.retval)>
		</cfif>

		<cfset local.newRole = lCase(trim(local.queryNewType.role))>
		<cfset local.newExpectsLeafChildCount = val(local.queryNewType.expects_leaf_child_count)>
		<cfset local.newExpectedParentTypes = lCase(trim(local.queryNewType.expected_parent_types))>
		<cfset local.newForceExpectedParentType = val(local.queryNewType.force_expected_parent_type)>
		<cfset local.newRankOrder = local.queryNewType.rank_order>
		<cfset local.newVariableRank = val(local.queryNewType.variable_rank)>
		<cfset local.isRootPlacement = (val(local.queryContainer.parent_container_id) EQ 0)>

		<cfset local.retval["expected_parent_types"] = local.newExpectedParentTypes>
		<cfset local.retval["force_expected_parent_type"] = local.newForceExpectedParentType>
		<cfset local.retval["is_root_placement"] = local.isRootPlacement>
		<cfset local.retval["current_type"] = local.queryContainer.container_type>

		<cfset local.parentType = "">
		<cfset local.parentRole = "">
		<cfset local.parentRankOrder = "">
		<cfset local.parentVariableRank = 0>

		<cfif NOT local.isRootPlacement>
			<cfquery name="local.queryParent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
				SELECT c.container_type, ct.role, ct.rank_order, NVL(ct.variable_rank,0) AS variable_rank
				FROM container c
					LEFT JOIN ctcontainer_type ct ON ct.container_type = c.container_type
				WHERE c.container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#val(local.queryContainer.parent_container_id)#">
			</cfquery>
			<cfif local.queryParent.recordcount GT 0>
				<cfset local.parentType = local.queryParent.container_type>
				<cfset local.parentRole = lCase(trim(local.queryParent.role))>
				<cfset local.parentRankOrder = local.queryParent.rank_order>
				<cfset local.parentVariableRank = val(local.queryParent.variable_rank)>
			</cfif>
		</cfif>
		<cfset local.retval["parent_type"] = local.parentType>

		<!--- GROUP 1 -- PARENT COMPATIBILITY (new app-only checks; no DB trigger covers a bare
			container_type change today, unlike MOVE_CONTAINER for moves) --->

		<!--- RT1: new type expects to be root, but this container currently has a parent --->
		<cfif NOT local.isRootPlacement AND local.newExpectedParentTypes EQ "none">
			<cfif local.newForceExpectedParentType EQ 1>
				<cfset local.retval["allowed"] = false>
				<cfset local.retval["severity"] = "block">
				<cfset ArrayAppend(local.retval["blocks"], "A #arguments.new_container_type# must be placed at the root, but this container currently has a parent.")>
				<cfreturn serializeJSON(local.retval)>
			<cfelse>
				<cfset ArrayAppend(local.retval["warnings"], "Containers of type #arguments.new_container_type# are expected to be root containers, but this one currently has a parent.")>
			</cfif>
		</cfif>

		<!--- RT2: new type's expected parent list doesn't include the actual current parent's type --->
		<cfif NOT local.isRootPlacement AND local.newExpectedParentTypes NEQ "any" AND local.newExpectedParentTypes NEQ "none"
			AND NOT listFindNoCase(local.newExpectedParentTypes, local.parentType)>
			<cfif local.newForceExpectedParentType EQ 1>
				<cfset local.retval["allowed"] = false>
				<cfset local.retval["severity"] = "block">
				<cfset ArrayAppend(local.retval["blocks"], "A #arguments.new_container_type# must be placed inside one of: #local.newExpectedParentTypes#. This container's current parent is a #local.parentType#.")>
				<cfreturn serializeJSON(local.retval)>
			<cfelse>
				<cfset ArrayAppend(local.retval["warnings"], "A #arguments.new_container_type# is normally placed inside a #local.newExpectedParentTypes#. This container's current parent is a #local.parentType#.")>
			</cfif>
		</cfif>

		<!--- RT3: current parent is a single-occupant (proxy) container, but the new type isn't a leaf --->
		<cfif NOT local.isRootPlacement AND local.parentRole EQ "proxy" AND local.newRole NEQ "leaf">
			<cfset local.retval["allowed"] = false>
			<cfset local.retval["severity"] = "block">
			<cfset ArrayAppend(local.retval["blocks"], "This container's current parent (#local.parentType#) is a single-occupant container and can only hold a collection object leaf container.")>
			<cfreturn serializeJSON(local.retval)>
		</cfif>

		<!--- RT4: same-type nesting relative to current parent --->
		<cfif NOT local.isRootPlacement AND local.newVariableRank EQ 0 AND lCase(arguments.new_container_type) EQ lCase(local.parentType)>
			<cfset ArrayAppend(local.retval["warnings"], "This would make a #arguments.new_container_type# the parent of another #arguments.new_container_type#. Containers of the same type are not normally nested.")>
		</cfif>

		<!--- RT5: rank order reversal relative to current parent --->
		<cfif NOT local.isRootPlacement
			AND local.newVariableRank EQ 0
			AND local.parentVariableRank EQ 0
			AND isNumeric(local.newRankOrder)
			AND isNumeric(local.parentRankOrder)
			AND val(local.newRankOrder) LTE val(local.parentRankOrder)>
			<cfset ArrayAppend(local.retval["warnings"], "This placement would reverse the expected nesting depth. A #arguments.new_container_type# (rank #local.newRankOrder#) would be inside a #local.parentType# (rank #local.parentRankOrder#).")>
		</cfif>

		<!--- RT6 (mirrors validateContainerPlacement's AO1): container is currently at the root, but
			the new type normally expects a parent --->
		<cfif local.isRootPlacement AND local.newExpectedParentTypes NEQ "none" AND local.newExpectedParentTypes NEQ "any">
			<cfset ArrayAppend(local.retval["warnings"], "This container is at the root level. Containers of type #arguments.new_container_type# are normally placed inside #local.newExpectedParentTypes#.")>
		</cfif>

		<!--- GROUP 2 -- EXISTING CHILDREN COMPATIBILITY --->
		<cfquery name="local.queryChildren" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
			SELECT c.container_id, c.container_type, ct.role, ct.rank_order, NVL(ct.variable_rank,0) AS variable_rank
			FROM container c
				LEFT JOIN ctcontainer_type ct ON ct.container_type = c.container_type
			WHERE c.parent_container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.container_id#">
		</cfquery>
		<cfset local.childCount = local.queryChildren.recordcount>
		<cfset local.retval["child_count"] = local.childCount>
		<cfset local.childWord = "children">
		<cfif local.childCount EQ 1>
			<cfset local.childWord = "child">
		</cfif>

		<cfif local.childCount GT 0>
			<!--- RT7: new type is a leaf, but this container currently holds children --->
			<cfif local.newRole EQ "leaf">
				<cfset local.retval["allowed"] = false>
				<cfset local.retval["severity"] = "block">
				<cfset ArrayAppend(local.retval["blocks"], "A #arguments.new_container_type# is a collection-object leaf type and cannot contain other containers, but this container currently holds #local.childCount# #local.childWord#.")>
				<cfreturn serializeJSON(local.retval)>
			</cfif>

			<!--- RT8: new type is a single-occupant (proxy) type, but doesn't currently hold exactly one leaf child --->
			<cfif local.newRole EQ "proxy">
				<cfset local.nonLeafChildCount = 0>
				<cfloop query="local.queryChildren">
					<cfif lCase(trim(local.queryChildren.role)) NEQ "leaf">
						<cfset local.nonLeafChildCount = local.nonLeafChildCount + 1>
					</cfif>
				</cfloop>
				<cfif local.childCount NEQ 1 OR local.nonLeafChildCount GT 0>
					<cfset local.retval["allowed"] = false>
					<cfset local.retval["severity"] = "block">
					<cfset ArrayAppend(local.retval["blocks"], "A #arguments.new_container_type# is a single-occupant container and can only hold exactly one collection object leaf, but this container currently holds #local.childCount# #local.childWord#.")>
					<cfreturn serializeJSON(local.retval)>
				</cfif>
			</cfif>

			<!--- RT9: new type not expected to hold leaves directly, but it currently holds at least one --->
			<cfif local.newExpectsLeafChildCount EQ 0>
				<cfset local.hasLeafChild = false>
				<cfloop query="local.queryChildren">
					<cfif lCase(trim(local.queryChildren.role)) EQ "leaf">
						<cfset local.hasLeafChild = true>
					</cfif>
				</cfloop>
				<cfif local.hasLeafChild>
					<cfset ArrayAppend(local.retval["warnings"], "Containers of type #arguments.new_container_type# are not expected to hold collection objects directly, but this container currently holds at least one.")>
				</cfif>
			</cfif>

			<!--- RT10: rank order reversal / same-type nesting relative to existing children --->
			<cfif local.newVariableRank EQ 0>
				<cfset local.rankReversedChild = false>
				<cfset local.sameTypeChild = false>
				<cfloop query="local.queryChildren">
					<cfif val(local.queryChildren.variable_rank) EQ 0 AND isNumeric(local.newRankOrder) AND isNumeric(local.queryChildren.rank_order)
						AND val(local.newRankOrder) GTE val(local.queryChildren.rank_order)>
						<cfset local.rankReversedChild = true>
					</cfif>
					<cfif val(local.queryChildren.variable_rank) EQ 0 AND lCase(trim(local.queryChildren.container_type)) EQ lCase(arguments.new_container_type)>
						<cfset local.sameTypeChild = true>
					</cfif>
				</cfloop>
				<cfif local.rankReversedChild>
					<cfset ArrayAppend(local.retval["warnings"], "This would reverse the expected nesting depth relative to at least one existing child.")>
				</cfif>
				<cfif local.sameTypeChild>
					<cfset ArrayAppend(local.retval["warnings"], "At least one existing child is also a #arguments.new_container_type#. Containers of the same type are not normally nested.")>
				</cfif>
			</cfif>
		</cfif>

		<cfif ArrayLen(local.retval["warnings"]) GT 0 AND local.retval["severity"] EQ "ok">
			<cfset local.retval["severity"] = "warn">
		</cfif>

		<cfreturn serializeJSON(local.retval)>
	<cfcatch>
		<cfset local.error_message = cfcatchToErrorMessage(cfcatch)>
		<cfset local.function_called = "#GetFunctionCalledName()#">
		<cfscript>reportError(function_called="#local.function_called#", error_message="#local.error_message#");</cfscript>
		<cfset local.safe = StructNew()>
		<cfset local.safe["allowed"] = false>
		<cfset local.safe["severity"] = "block">
		<cfset local.safe["warnings"] = ArrayNew(1)>
		<cfset local.safe["blocks"] = ArrayNew(1)>
		<cfset ArrayAppend(local.safe["blocks"], "Validation error occurred. Please try again.")>
		<cfset local.safe["child_type"] = arguments.new_container_type>
		<cfreturn serializeJSON(local.safe)>
	</cfcatch>
	</cftry>
</cffunction>

<!---
Function applyBulkRetypeContainer. Applies a bulk-retype change to one container -- called once per
matched container by the bulk retype tool's apply step, independently per container (not wrapped in
one all-or-nothing transaction like the legacy labels2containers.cfm), so one container's failure
doesn't roll back the rest of the batch. Requires manage_container on top of this file's <cf_rolecheck>,
per this redesign's rule that every mutating method must enforce it inline as well.
@param container_id the container to update.
@param new_container_type the new container_type to set.
@param description_value new value for description; ignored if blank.
@param description_mode "append" or "overwrite"; only meaningful if description_value is non-blank.
@param container_remarks_value new value for container_remarks; ignored if blank.
@param container_remarks_mode "append" or "overwrite"; only meaningful if container_remarks_value is non-blank.
@param height_value new height; ignored if blank.
@param length_value new length; ignored if blank.
@param width_value new width; ignored if blank.
@param number_positions_value new number_positions; ignored if blank.
@return JSON: status (updated|error), message; on success also the container's resulting state
	(re-fetched, not just echoed back) -- container_id, barcode, label, container_type, description,
	container_remarks, height, length, width, number_positions -- so a caller can show what a
	container actually looks like now without re-deriving append/overwrite logic itself.
--->
<cffunction name="applyBulkRetypeContainer" access="remote" returntype="any" returnformat="json" output="false">
	<cfargument name="container_id" type="numeric" required="yes">
	<cfargument name="new_container_type" type="string" required="yes">
	<cfargument name="description_value" type="string" required="no" default="">
	<cfargument name="description_mode" type="string" required="no" default="overwrite">
	<cfargument name="container_remarks_value" type="string" required="no" default="">
	<cfargument name="container_remarks_mode" type="string" required="no" default="overwrite">
	<cfargument name="height_value" type="string" required="no" default="">
	<cfargument name="length_value" type="string" required="no" default="">
	<cfargument name="width_value" type="string" required="no" default="">
	<cfargument name="number_positions_value" type="string" required="no" default="">

	<cfset local.retval = StructNew()>

	<cfif NOT (isdefined("session.roles") AND listfindnocase(session.roles, "manage_container") GT 0)>
		<cfset local.retval["status"] = "error">
		<cfset local.retval["message"] = "You do not have permission to modify containers.">
		<cfreturn serializeJSON(local.retval)>
	</cfif>

	<cfif listFindNoCase(ArrayToList(getBulkRetypeGuardedContainerTypes()), arguments.new_container_type) GT 0>
		<cfset local.retval["status"] = "error">
		<cfset local.retval["message"] = "#arguments.new_container_type# is not a type containers can be bulk-retyped into.">
		<cfreturn serializeJSON(local.retval)>
	</cfif>

	<!--- Oracle treats '' and NULL as equivalent; typing NULL is how a user clears one of these fields --->
	<cfset local.clearDescription = false>
	<cfif arguments.description_mode EQ "overwrite" AND UCase(trim(arguments.description_value)) EQ "NULL">
		<cfset local.clearDescription = true>
	</cfif>
	<cfset local.clearRemarks = false>
	<cfif arguments.container_remarks_mode EQ "overwrite" AND UCase(trim(arguments.container_remarks_value)) EQ "NULL">
		<cfset local.clearRemarks = true>
	</cfif>
	<cfset local.clearHeight = false>
	<cfif UCase(trim(arguments.height_value)) EQ "NULL">
		<cfset local.clearHeight = true>
	</cfif>
	<cfset local.clearLength = false>
	<cfif UCase(trim(arguments.length_value)) EQ "NULL">
		<cfset local.clearLength = true>
	</cfif>
	<cfset local.clearWidth = false>
	<cfif UCase(trim(arguments.width_value)) EQ "NULL">
		<cfset local.clearWidth = true>
	</cfif>
	<cfset local.clearNumberPositions = false>
	<cfif UCase(trim(arguments.number_positions_value)) EQ "NULL">
		<cfset local.clearNumberPositions = true>
	</cfif>

	<cftry>
		<cfset local.newDescription = "">
		<cfset local.newRemarks = "">

		<cfif local.clearDescription>
			<!--- newDescription stays blank; local.clearDescription drives the NULL in the UPDATE below --->
		<cfelseif len(trim(arguments.description_value)) GT 0 AND arguments.description_mode EQ "append">
			<cfquery name="local.queryCurrent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
				SELECT description FROM container WHERE container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.container_id#">
			</cfquery>
			<cfif local.queryCurrent.recordcount GT 0 AND len(trim(local.queryCurrent.description)) GT 0>
				<cfset local.newDescription = local.queryCurrent.description & "; " & arguments.description_value>
			<cfelse>
				<cfset local.newDescription = arguments.description_value>
			</cfif>
		<cfelseif len(trim(arguments.description_value)) GT 0>
			<cfset local.newDescription = arguments.description_value>
		</cfif>

		<cfif local.clearRemarks>
			<!--- newRemarks stays blank; local.clearRemarks drives the NULL in the UPDATE below --->
		<cfelseif len(trim(arguments.container_remarks_value)) GT 0 AND arguments.container_remarks_mode EQ "append">
			<cfquery name="local.queryCurrentRemarks" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
				SELECT container_remarks FROM container WHERE container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.container_id#">
			</cfquery>
			<cfif local.queryCurrentRemarks.recordcount GT 0 AND len(trim(local.queryCurrentRemarks.container_remarks)) GT 0>
				<cfset local.newRemarks = local.queryCurrentRemarks.container_remarks & "; " & arguments.container_remarks_value>
			<cfelse>
				<cfset local.newRemarks = arguments.container_remarks_value>
			</cfif>
		<cfelseif len(trim(arguments.container_remarks_value)) GT 0>
			<cfset local.newRemarks = arguments.container_remarks_value>
		</cfif>

		<cftry>
			<cfquery name="local.updateContainer" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#" result="local.updateContainer_result">
				UPDATE container
				SET
					container_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.new_container_type#">
					<cfif local.clearDescription>
						, description = NULL
					<cfelseif len(trim(arguments.description_value)) GT 0>
						, description = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#local.newDescription#">
					</cfif>
					<cfif local.clearRemarks>
						, container_remarks = NULL
					<cfelseif len(trim(arguments.container_remarks_value)) GT 0>
						, container_remarks = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#local.newRemarks#">
					</cfif>
					<cfif local.clearHeight>
						, height = NULL
					<cfelseif len(trim(arguments.height_value)) GT 0>
						, height = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" scale="4" value="#arguments.height_value#">
					</cfif>
					<cfif local.clearLength>
						, length = NULL
					<cfelseif len(trim(arguments.length_value)) GT 0>
						, length = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" scale="4" value="#arguments.length_value#">
					</cfif>
					<cfif local.clearWidth>
						, width = NULL
					<cfelseif len(trim(arguments.width_value)) GT 0>
						, width = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" scale="4" value="#arguments.width_value#">
					</cfif>
					<cfif local.clearNumberPositions>
						, number_positions = NULL
					<cfelseif len(trim(arguments.number_positions_value)) GT 0>
						, number_positions = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#arguments.number_positions_value#">
					</cfif>
				WHERE container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.container_id#">
			</cfquery>
			<cfif local.updateContainer_result.recordCount EQ 0>
				<cfthrow type="ContainerNotFound" message="No rows updated.">
			</cfif>
		<cfcatch>
			<cfset local.userMessage = trim(REReplace(cfcatch.message, "^ORA-[0-9]+:\s*", "", "one"))>
			<cfset local.matchPos = REFindNoCase("(You cannot|This move|A container|Institution|The child|The position)", local.userMessage)>
			<cfif local.matchPos GT 0>
				<cfset local.userMessage = mid(local.userMessage, local.matchPos, len(local.userMessage) - local.matchPos + 1)>
			</cfif>
			<cfif len(trim(local.userMessage)) EQ 0>
				<cfset local.userMessage = "Unable to update container due to a placement or type rule. Please review the new type and try again.">
			</cfif>
			<cfif cfcatch.type EQ "ContainerNotFound">
				<cfset local.userMessage = "Container was not found. It may have been deleted or changed by another user.">
			</cfif>
			<cfset local.retval["status"] = "error">
			<cfset local.retval["message"] = local.userMessage>
			<cfreturn serializeJSON(local.retval)>
		</cfcatch>
		</cftry>

		<cfquery name="local.queryUpdated" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
			SELECT container_id, barcode, label, container_type, description, container_remarks, height, length, width, number_positions
			FROM container
			WHERE container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.container_id#">
		</cfquery>
		<cfset local.retval["status"] = "updated">
		<cfset local.retval["message"] = "Updated.">
		<cfset local.retval["container_id"] = local.queryUpdated.container_id>
		<cfset local.retval["barcode"] = local.queryUpdated.barcode>
		<cfset local.retval["label"] = local.queryUpdated.label>
		<cfset local.retval["container_type"] = local.queryUpdated.container_type>
		<cfset local.retval["description"] = local.queryUpdated.description>
		<cfset local.retval["container_remarks"] = local.queryUpdated.container_remarks>
		<cfset local.retval["height"] = local.queryUpdated.height>
		<cfset local.retval["length"] = local.queryUpdated.length>
		<cfset local.retval["width"] = local.queryUpdated.width>
		<cfset local.retval["number_positions"] = local.queryUpdated.number_positions>
		<cfreturn serializeJSON(local.retval)>
	<cfcatch>
		<cfset local.retval["status"] = "error">
		<cfset local.retval["message"] = trim(cfcatch.message)>
		<cfreturn serializeJSON(local.retval)>
	</cfcatch>
	</cftry>
</cffunction>

</cfcomponent>
