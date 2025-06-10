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
	<cfset variables.action = "nothing">
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
	<cfquery name="leaf" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		select
			container.container_id,
			container.container_type,
			container.label,
			container.description,
			p.barcode,
			container.container_remarks
		from
			container
			left join container p on container.parent_container_id=p.container_id
		where
			container.container_type='collection object'
		start with
			container.container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.container_id#">
		connect by
			container.parent_container_id = prior container.container_id
	</cfquery>
	<!--- special case handling to dump as csv --->
	<cfif isDefined("variables.action") AND variables.action is "csvDump">
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
						This page lists the #leaf.recordcount# collection object leaf nodes in the container hierarchy for the container
						<a href="/findContainer.cfm?container_id=#encodeForUrl(variables.container_id)#" target="_detail">
			   			#getContainerInfo.container_type#: #getContainerInfo.barcode#
						</a>.
						<cfif leaf.recordcount GT 0>  
							<a class="btn-secondary btn-xs" role="button"  href="/containers/allContainerLeafNodes.cfm?container_id=#encodeForUrl(variables.container_id)#&action=csvDump" target="_blank">Download as CSV</a>.
						</cfif>
						<cfif listCatItems.recordcount GT 0 AND listCatItems.recordcount LT 101>
							<a class="btn-secondary btn-xs" role="button"  href="/Specimens.cfm?execute=true&builderMaxRows=1&action=builderSearch&openParens1=0&field1=COLL_OBJECT%3ACOLL_OBJ_COLLECTION_OBJECT_ID&searchText1=#collectionObjectIds#&closeParens1=0" target="_blank">View in Specimen Search</a>.
						</cfif>
					</p>

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
									coll_obj_cont_hist,
									specimen_part,
									cataloged_item,
									identification,
									collection
								WHERE
									coll_obj_cont_hist.collection_object_id = specimen_part.collection_object_id AND
									specimen_part.derived_from_cat_item = cataloged_item.collection_object_id AND
									cataloged_item.collection_object_id = identification.collection_object_id AND
									cataloged_item.collection_id=collection.collection_id AND
									accepted_id_fg=1 AND
									container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#leaf.container_id#">
							</cfquery>
							<cfloop query="specData">
								<tr>
									<td> <a href="/findContainer.cfm?container_id=#leaf.container_id#" target="_blank">#leaf.label#</a> &nbsp;</td>
									<td>#leaf.description#&nbsp;</td>
									<td>#leaf.barcode#&nbsp;</td>
									<td>#leaf.container_remarks#&nbsp;</td>
									<td>#specData.part_name#</td>
									<td>#specData.preserve_method#</td>
									<td>
										<a href="/SpecimenDetail.cfm?collection_object_id=#specData.collection_object_id#" target="_blank">
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

	<!--- TODO: The following code appears to be unused --->
	<!---------------- start search by container ---------------->
	<cfif #action# is "nothing">
		<cfif not isdefined ("srch")>
			<cfabort>
		</cfif>
		<cfquery name="allRecords" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			SELECT
				container.container_id,
				container.parent_container_id,
				container_type,
				label
			FROM
				container
				<cfif srch is "Part">
					, coll_obj_cont_hist, specimen_part, cataloged_item
				</cfif>
				<cfif srch is "Container">
					, fluid_container_history
				</cfif>
				<cfif isdefined("af_num")>
					, af_num
				</cfif>
				<cfif isdefined("Scientific_Name")>
					, identification, taxonomy
				</cfif>
			WHERE
				1=1
				<cfif srch is "Part">
					AND container.container_id = coll_obj_cont_hist.container_id
					AND coll_obj_cont_hist.collection_object_id = specimen_part.collection_object_id
					AND specimen_part.derived_from_cat_item = cataloged_item.collection_object_id
				</cfif>
				<cfif srch is "Container">
					AND container.container_id = fluid_container_history.container_id (+)
				</cfif>
				<cfif isdefined("af_num")>
					AND cataloged_item.collection_object_id = af_num.collection_object_id
					AND af_num.af_num IN (
						<cfqueryparam value="#listToArray(af_num)#" cfsqltype="CF_SQL_VARCHAR" list="true">
					)
				</cfif>
				<cfif isdefined("cat_num")>
					AND cataloged_item.cat_num IN (
						<cfqueryparam value="#listToArray(cat_num)#" cfsqltype="CF_SQL_VARCHAR" list="true">
					)
				</cfif>
				<cfif isdefined("collection_cde")>
					AND cataloged_item.collection_cde = <cfqueryparam value="#collection_cde#" cfsqltype="CF_SQL_VARCHAR">
				</cfif>
				<cfif isdefined("Tissue_Type")>
					AND Tissue_Type = <cfqueryparam value="#Tissue_Type#" cfsqltype="CF_SQL_VARCHAR">
				</cfif>
				<cfif isdefined("Part_Name")>
					AND part_Name = <cfqueryparam value="#Part_Name#" cfsqltype="CF_SQL_VARCHAR">
				</cfif>
				<cfif isdefined("Scientific_Name")>
					AND cataloged_item.collection_object_id = identification.collection_object_id
					AND identification.accepted_id_fg = 1
					AND identification.taxon_name_id = taxonomy.taxon_name_id
					AND upper(Scientific_Name) LIKE <cfqueryparam value="%#ucase(Scientific_Name)#%" cfsqltype="CF_SQL_VARCHAR">
				</cfif>
				<cfif isdefined("container_label")>
					<cfif isdefined("wildLbl") and wildLbl is 1>
						AND upper(label) LIKE <cfqueryparam value="%#ucase(container_label)#%" cfsqltype="CF_SQL_VARCHAR">
					<cfelse>
						AND label = <cfqueryparam value="#container_label#" cfsqltype="CF_SQL_VARCHAR">
					</cfif>
				</cfif>
				<cfif isdefined("description")>
					<cfif isdefined("wildLbl") and wildLbl is 1>
						AND upper(description) LIKE <cfqueryparam value="%#ucase(description)#%" cfsqltype="CF_SQL_VARCHAR">
					<cfelse>
						AND description = <cfqueryparam value="#description#" cfsqltype="CF_SQL_VARCHAR">
					</cfif>
				</cfif>
				<cfif isdefined("collection_object_id")>
					AND cataloged_item.collection_object_id = <cfqueryparam value="#collection_object_id#" cfsqltype="CF_SQL_DECIMAL">
				</cfif>
				<cfif isdefined("barcode")>
					AND barcode IN (
						<cfqueryparam value="#listToArray(barcode)#" cfsqltype="CF_SQL_VARCHAR" list="true">
					)
				</cfif>
				<cfif isdefined("container_type")>
					AND container_type = <cfqueryparam value="#container_type#" cfsqltype="CF_SQL_VARCHAR">
				</cfif>
				<cfif isdefined("container_remarks")>
					AND upper(container_remarks) LIKE <cfqueryparam value="%#ucase(container_remarks)#%" cfsqltype="CF_SQL_VARCHAR">
				</cfif>
				<cfif isdefined("container_id")>
					AND container.container_id = <cfqueryparam value="#container_id#" cfsqltype="CF_SQL_DECIMAL">
				</cfif>
			ORDER BY
				container.container_id
		</cfquery>
	</cfif>
	<!---------------- end search by container ---------------->

	<!---------------- search by container_id (ie, for all the containers in a container
	from a previous search ---------------------------------->
	<cfif #action# is "contentsSearch">
		<cfquery name="allRecords" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			SELECT 
				container_id
			FROM
				container
			WHERE
				parent_container_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#container_id#">
		</cfquery>
	</cfif>
	<!-------------------------- end contents search ----------------------->

	<cfif isDefined("allRecords")>
		<cfif #allRecords.recordcount# is 0>
			Your search returned no records. Use your browser&##39;s back button to try again.
		<cfelse>
			<cfform name="TissTree" enablecab="yes">
				<cftree name="tt" height="600" width="400"  format="html">
					<cftreeitem value="0" expand="yes" display="Location">
					<!--- set up a list to keep track of the container_ids that we've put in the tree --->
					<cfset placedContainers = "">
	
					<cfloop query="allRecords">
						<cfquery name="thisRecord" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							SELECT
								container_id,
								parent_container_id,
								container_type,
								description,
								parent_install_date,
								container_remarks,
								label
							FROM 
								container
							START WITH container_id =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#allRecords.container_id#">
							CONNECT BY PRIOR parent_container_id = container_id
						</cfquery>
						<cfoutput>
							<cfloop query="thisRecord">
								<cfif not listfind(placedContainers,#thisRecord.container_id#)>
									<cfif #thisRecord.container_type# is "collection object">
										<cftreeitem
											value="#thisRecord.container_id#--ContainerDetails.cfm?container_id=#thisRecord.container_id#&objType=CollObj"
											display="#thisRecord.label#"
											parent="#thisRecord.parent_container_id#"
											expand="yes"
											href="ContainerDetails.cfm?container_id=#thisRecord.container_id#"
											target="_detail">
									<cfelse>
										<cftreeitem 
											value="#thisRecord.container_id#" 
											display="#thisRecord.label#" 
											parent="#thisRecord.parent_container_id#" 
											href="ContainerDetails.cfm?container_id=#thisRecord.container_id#" 
											target="_detail" 
											expand="yes">
									</cfif>
									<cfset placedContainers = listappend(placedContainers,#thisRecord.container_id#)>
								</cfif>
							</cfloop>
						</cfoutput>
 					</cfloop>
 				</cftree>
			</cfform>
		</cfif>
		<cfif isdefined("sql") and len(#sql#) gt 0>
			<form method="post" action="/locDownload.cfm" target="_blank">
				<cfoutput>
					<input type="hidden" name="sql" value="#preservesinglequotes(sql)#">
					<input type="submit" value="download summary">
				</cfoutput>
	 		</form>
		</cfif>
	</cfif>
</main>
<cfinclude template="/shared/_footer.cfm">
