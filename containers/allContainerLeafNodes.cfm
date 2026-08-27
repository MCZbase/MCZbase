<!--- /containers/allContainerLeafNodes.cfm list collection object leaf nodes in container heirarchy for a given parent node.

Copyright 2008-2017 Contributors to Arctos
Copyright 2008-2025 President and Fellows of Harvard College

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

<cfif isDefined("url.action")>
	<cfset variables.action = url.action>
<cfelse>
	<cfset variables.action = "list">
</cfif>
<cfif isDefined("url.show")>
	<cfset variables.show = url.show>
<cfelse>
	<cfset variables.show = "all">
</cfif>

<cfif isdefined("url.container_id") and len(url.container_id) GT 0>
	<cfset variables.container_id = url.container_id>
<cfelse>
	<cfif isdefined("url.barcode") and len(url.barcode) GT 0>
		<cfset variables.barcode = url.barcode>
		<cfquery name="getContainerId" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			SELECT container_id 
			FROM container 
			WHERE 
				barcode = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.barcode#">
		</cfquery>
		<cfloop query="getContainerId">
			<cfset variables.container_id = getContainerID.container_id >
		</cfloop>
	</cfif>
</cfif>
<cfif isdefined("variables.container_id") AND len(variables.container_id) GT 0>
	<cfquery name="getContainerInfo" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		SELECT barcode, container_type, label
		FROM container 
		WHERE 
			container_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.container_id#">
	</cfquery>
	<cfif getContainerInfo.recordcount EQ 0>
		<cfthrow message="Container [#encodeForHtml(variables.container_id)#] not found.">
	</cfif>
	<!--- special case handling to dump as csv -- streams a file before the shared header runs,
		so needs its own <cf_rolecheck> here since this file has no other role check. --->
	<cfif isDefined("variables.action") AND variables.action is "csvDump">
		<cf_rolecheck>
		<cfquery name="allLeafData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			SELECT 
				p.barcode parent_barcode,
				p.container_type parent_container_type,
				container.container_id,
				container.container_type,
				container.label container_label,
				container.description container_description,
				container.container_remarks,
				cataloged_item.collection_object_id,
				scientific_name,
				part_name,
				specimen_part.preserve_method,
				cat_num,
				cataloged_item.collection_cde,
				collection.institution_acronym,
				get_storedas_by_contid(container.container_id) storedAs
			FROM
				container
				left join container p on container.parent_container_id=p.container_id
				left join coll_obj_cont_hist on container.container_id = coll_obj_cont_hist.container_id
				left join specimen_part on coll_obj_cont_hist.collection_object_id = specimen_part.collection_object_id
				left join cataloged_item on specimen_part.derived_from_cat_item = cataloged_item.collection_object_id 
				left join identification on cataloged_item.collection_object_id = identification.collection_object_id 
				left join collection on cataloged_item.collection_id=collection.collection_id
			WHERE
				container.container_type='collection object' AND
				identification.accepted_id_fg = 1 
				<cfif isdefined("variables.show") AND variables.show is "immediate">
					AND CONNECT_BY_ISLEAF = 1
					AND LEVEL = 2
				</cfif>
			START WITH
				container.container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.container_id#">
			CONNECT BY
				container.parent_container_id = PRIOR container.container_id
		</cfquery>

		<cfinclude template="/shared/component/functions.cfc">
		<cfset csv = queryToCSV(allLeafData)>
		<cfheader name="Content-Type" value="text/csv">
		<cfoutput>#csv#</cfoutput>
		<cfabort>
	</cfif>
	<!--- normal handling, report on leaf nodes below target node --->
	<cfquery name="leaf" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		SELECT
			container.container_id,
			container.container_type,
			container.label,
			container.description,
			p.barcode,
			container.container_remarks
		FROM
			container
			left join container p on container.parent_container_id=p.container_id
		WHERE
			container.container_type='collection object'
			<cfif isdefined("variables.show") AND variables.show is "immediate">
				AND CONNECT_BY_ISLEAF = 1
				AND LEVEL = 2
			</cfif>
		START WITH
			container.container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.container_id#">
		CONNECT BY
			container.parent_container_id = prior container.container_id
	</cfquery>
	<cfif variables.show NEQ "all">
		<cfquery name="countAll" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			SELECT
				count (distinct container.container_id) as total
			FROM
				container
				left join container p on container.parent_container_id=p.container_id
			WHERE
				container.container_type='collection object'
			START WITH
				container.container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.container_id#">
			CONNECT BY
				container.parent_container_id = prior container.container_id
		</cfquery>
		<cfset countAllLeaves = countAll.total>
	<cfelse>
		<cfset countAllLeaves = leaf.recordcount>
	</cfif>
	<cfquery name="listCatItems" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		SELECT DISTINCT
			cataloged_item.collection_object_id
		FROM
			container
			left join coll_obj_cont_hist on container.container_id = coll_obj_cont_hist.container_id
			left join specimen_part on coll_obj_cont_hist.collection_object_id = specimen_part.collection_object_id
			left join cataloged_item on specimen_part.derived_from_cat_item = cataloged_item.collection_object_id 
		WHERE
			container.container_type='collection object'
			<cfif isdefined("variables.show") AND variables.show is "immediate">
				AND CONNECT_BY_ISLEAF = 1
				AND LEVEL = 2
			</cfif>
		START WITH
			container.container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.container_id#">
		CONNECT BY
			container.parent_container_id = PRIOR container.container_id
	</cfquery>
	<cfset collectionObjectIds = "">
	<cfloop query="listCatItems">
		<cfset collectionObjectIds = listAppend(collectionObjectIds, listCatItems.collection_object_id)>
	</cfloop>
</cfif>

<cfset pageTitle = "Containers | List cataloged items">
<cfinclude template="/shared/_header.cfm">
<script src="/lib/misc/sorttable.js"></script>
<cfset title = "Container Locations">
<main class="container-fluid">
	<cfoutput>
		<cfif isdefined("variables.container_id") AND len(variables.container_id) GT 0>
			<div class="row">
				<div class="col-12">
					<h1>Container Leaf Nodes</h1>
					<p>
						<cfif variables.show is "immediate">
							This page lists only the #leaf.recordcount# immediate leaf nodes of the container hierarchy for the container
						<cfelse>
							This page lists the #leaf.recordcount# collection object leaf nodes in the container hierarchy for the container
						</cfif>
						<a href="/containers/viewContainer.cfm?container_id=#encodeForUrl(variables.container_id)#" target="_detail">
			   			#getContainerInfo.container_type#: #getContainerInfo.barcode#
						</a>.
						<cfif variables.show IS "all">
							<a class="btn-secondary btn-xs" role="button"  href="/containers/allContainerLeafNodes.cfm?container_id=#encodeForUrl(variables.container_id)#&show=immediate">Show only immediate leaves</a>
						</cfif>
						<cfif leaf.recordcount GT 0>
							<a class="btn-secondary btn-xs" role="button"  href="/containers/allContainerLeafNodes.cfm?container_id=#encodeForUrl(variables.container_id)#&action=csvDump" target="_blank">Download as CSV</a>
						</cfif>
						<cfif listCatItems.recordcount GT 0 AND listCatItems.recordcount LT 101>
							<a class="btn-secondary btn-xs" role="button"  href="/Specimens.cfm?execute=true&builderMaxRows=1&action=builderSearch&openParens1=0&field1=COLL_OBJECT%3ACOLL_OBJ_COLLECTION_OBJECT_ID&searchText1=#collectionObjectIds#&closeParens1=0" target="_blank">View in Specimen Search</a>
						</cfif>
						<!--- add info link to view this container in viewContainer.cfm --->
						<a class="btn btn-xs btn-info" role="button" href="/containers/Containers.cfm?container_id=#encodeForUrl(variables.container_id)#&amp;execute=true" target="_blank">Browse in Hierarchy</a>
						<a class="btn btn-xs btn-primary" role="button"  href="/containers/viewContainer.cfm?container_id=#encodeForUrl(variables.container_id)#" target="_blank">View</a>
					</p>
					<cfif variables.show is "immediate">
						<p>
							There are #countAllLeaves# total collection object nodes attached at any level below this container.
							<a class="btn-secondary btn-xs" role="button"  href="/containers/allContainerLeafNodes.cfm?container_id=#encodeForUrl(variables.container_id)#&show=all">Show all</a>
						</p>
					</cfif>

					<table border id="t" class="sortable">
						<tr>
							<th><strong>Container Name</strong></th>
							<th><strong>Container Description</strong></th>
							<th><strong>In Unique ID</strong></th>
							<th><strong>Container Remarks</strong></th>
							<th><strong>Part Name</strong></th>
							<th><strong>Preserve Method</strong></th>
							<th><strong>Cat Num</strong></th>
							<th><strong>Scientific Name</strong></th>
							<th><strong>Stored As</strong></th>
						</tr>
						<cfloop query="leaf">
							<cfquery name="specData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
								SELECT 
									cataloged_item.collection_object_id,
									scientific_name,
									part_name,
									preserve_method,
									specimen_part.preserve_method,
									cat_num,
									cataloged_item.collection_cde,
									institution_acronym,
									get_storedas_by_contid(#variables.container_id#) storedAs
								FROM
									coll_obj_cont_hist
									left join specimen_part on coll_obj_cont_hist.collection_object_id = specimen_part.collection_object_id
									left join cataloged_item on specimen_part.derived_from_cat_item = cataloged_item.collection_object_id 
									left join identification on cataloged_item.collection_object_id = identification.collection_object_id AND accepted_id_fg=1 
									left join collection on cataloged_item.collection_id=collection.collection_id
								WHERE
									container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#leaf.container_id#">
							</cfquery>
							<cfloop query="specData">
								<tr>
									<td> <a href="/containers/viewContainer.cfm?container_id=#leaf.container_id#" target="_blank">#leaf.label#</a> &nbsp;</td>
									<td>#leaf.description#&nbsp;</td>
									<td>#leaf.barcode#&nbsp;</td>
									<td>#leaf.container_remarks#&nbsp;</td>
									<td>#specData.part_name#</td>
									<td>#specData.preserve_method#</td>
									<td>
										<a href="/guid/#specData.institution_acronym#:#specData.collection_cde#:#specData.cat_num#" target="_blank">
											#specData.institution_acronym# #specData.collection_cde# #specData.cat_num#
										</a>
									</td>
									<td>#specData.scientific_name#</td>
									<td>#specData.storedAs#</td>
								</tr>
							</cfloop>
						</cfloop>
					</table>
				</div>
			</div>
		</cfif>
	</cfoutput>

</main>
<cfinclude template="/shared/_footer.cfm">
