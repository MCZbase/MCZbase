<!--- 
  Reports/handers/label.cfm proof of concept specimen label paperwork generation.

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

<cfif not isDefined("url.result_id") OR len(url.result_id) EQ 0>
	<cfthrow message = "No result_id provided for query selecting labels to print.">
<cfelse>
	<cfset variables.result_id = url.result_id>
</cfif>

<cfif isDefined("url.target") AND len(url.target)>
	<cfset variables.target = url.target>
<cfelse>
	<cfset variables.target = "Dry_Large_Type__All">
</cfif>

<cfswitch expression = "#variables.target#">
	<cfcase value="Dry_Large_Type__All">
		<cfquery name="getItems" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			SELECT DISTINCT
				get_scientific_name_auths(cataloged_item.collection_object_id) sci_name_with_auth,
				concatAcceptedIdentifyingAgent(cataloged_item.collection_object_id) identified_by,
				MCZBASE.CONCATTYPESTATUS_LABEL(cataloged_item.collection_object_id) as tsname,
				MCZBASE.CONCATTYPESTATUS_WORDS(cataloged_item.collection_object_id) as type_status,
				cat_num as catalog_number,
				collection_cde
			FROM
				user_search_table
				JOIN cataloged_item on user_search_table.collection_object_id = cataloged_item.collection_object_id
			WHERE
				user_search_table.result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
			ORDER BY
				lpad(cat_num,10)
		</cfquery>
		<cfset orientation = "portrait">
		<cfset columns = 2>
		<cfset tableWidth = 'width: 7in;'>
		<cfset labelWidth = 'width: 3.5in;'>
		<cfset labelBorder = 'border: 1px solid black;'>
		<cfset labelHeight = 'height: 2.0in;'>
	</cfcase>
	<cfcase value="Slide_1x3__Mala">
		<cfquery name="getItems" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			SELECT DISTINCT
				nvl2(mczbase.concattypestatus_label(cataloged_item.collection_object_id), 
					mczbase.concattypestatus_label(cataloged_item.collection_object_id), 
					get_scientific_name_auths(cataloged_item.collection_object_id)
					) as sci_name,
				concatAcceptedIdentifyingAgent(cataloged_item.collection_object_id) identified_by,
				MCZBASE.CONCATTYPESTATUS_LABEL(cataloged_item.collection_object_id) as tsname,
				MCZBASE.CONCATTYPESTATUS_WORDS(cataloged_item.collection_object_id) as type_status,
				cataloged_item.cat_num as catalog_number,
				cataloged_item.collection_cde,
				parent.barcode as barcode_number,
				parent.label as container_label,
				MCZBASE.GET_PARENTCONTLABELFORCONT(container.parent_container_id) as parent_label,
				flat.verbatimlocality as verbatim_locality
			FROM
				user_search_table
				JOIN cataloged_item on user_search_table.collection_object_id = cataloged_item.collection_object_id
				join specimen_part on cataloged_item.collection_object_id = specimen_part.derived_from_cat_item
				join coll_obj_cont_hist on specimen_part.collection_object_id = coll_obj_cont_hist.collection_object_id
				join container on coll_obj_cont_hist.container_id = container.container_id
				join container parent on container.parent_container_id = parent.container_id
				join flat on cataloged_item.collection_object_id = flat.collection_object_id
			WHERE
				coll_obj_cont_hist.current_container_fg = 1 AND
				specimen_part.preserve_method LIKE '%slide%' AND
				user_search_table.result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
			ORDER BY
				lpad(cataloged_item.cat_num,10)
		</cfquery>
		<cfset orientation = "portrait">
		<cfset columns = 2>
		<cfset tableWidth = 'width: 6in;'>
		<cfset labelWidth = 'width: 3.0in;'>
		<cfset labelBorder = 'border: 1px solid black;'>
		<cfset labelHeight = 'height: 1.0in;'>
	</cfcase>
	<cfcase value="Slide_1x3__IZ">
		<cfquery name="getItems" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			SELECT DISTINCT
				nvl2(mczbase.concattypestatus_label(cataloged_item.collection_object_id), 
					mczbase.concattypestatus_label(cataloged_item.collection_object_id), 
					get_scientific_name_auths(cataloged_item.collection_object_id)
					) as sci_name,
				nvl2(mczbase.concattypestatus_label(cataloged_item.collection_object_id), 
					mczbase.GET_TYPESTATUSNAME(cataloged_item.collection_object_id,mczbase.get_top_typestatus_kind(cataloged_item.collection_object_id)), 
					get_scientific_name_auths(cataloged_item.collection_object_id)
					) as just_sci_name,
				flat.phylum as phylum,
				flat.phylclass as phylclass,
				flat.phylorder as phylorder,
				flat.family as family,
				concatAcceptedIdentifyingAgent(cataloged_item.collection_object_id) identified_by,
				MCZBASE.CONCATTYPESTATUS_LABEL(cataloged_item.collection_object_id) as tsname,
				MCZBASE.CONCATTYPESTATUS_WORDS(cataloged_item.collection_object_id) as type_status,
				MCZBASE.GET_TOP_TYPESTATUS_KIND(cataloged_item.collection_object_id) as type_status_kind,
				MCZBASE.GET_TOP_TYPESTATUS(cataloged_item.collection_object_id) as top_type_status,
				cataloged_item.cat_num as catalog_number,
				cataloged_item.collection_cde,
				parent.barcode as barcode_number,
				parent.label as container_label,
				MCZBASE.GET_PARENTCONTLABELFORCONT(container.parent_container_id) as parent_label
			FROM
				user_search_table
				JOIN cataloged_item on user_search_table.collection_object_id = cataloged_item.collection_object_id
				join specimen_part on cataloged_item.collection_object_id = specimen_part.derived_from_cat_item
				join coll_obj_cont_hist on specimen_part.collection_object_id = coll_obj_cont_hist.collection_object_id
				join container on coll_obj_cont_hist.container_id = container.container_id
				join container parent on container.parent_container_id = parent.container_id
				join flat on cataloged_item.collection_object_id = flat.collection_object_id
			WHERE
				coll_obj_cont_hist.current_container_fg = 1 AND
				specimen_part.preserve_method LIKE '%slide%' AND
				user_search_table.result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
			ORDER BY
				lpad(cataloged_item.cat_num,10)
		</cfquery>
		<cfset orientation = "portrait">
		<cfset columns = 2>
		<cfset tableWidth = 'width: 6in;'>
		<cfset labelWidth = 'width: 3.0in;'>
		<cfset labelBorder = 'border: 1px solid black;'>
		<cfset labelHeight = 'height: 1.0in;'>
	</cfcase>
</cfswitch>

<cfset labelStyle = '#labelHeight# #labelWidth# #labelBorder# padding: 5px;'>
<cfdocument format="pdf" pagetype="letter" margintop=".25" marginbottom=".25" marginleft=".5" marginright=".5" orientation="#orientation#" fontembed="yes" saveAsName="MCZ_labels_#result_id#.pdf">
	<cfoutput>
		<cfdocumentitem type="header">
			<div style="text-align: center; font-size: x-small;">
				Museum of Comparative Zoology #variables.target#
			</div>
		</cfdocumentitem>
		
		<cfdocumentitem type="footer">
			<div style="text-align: center; font-size: x-small;">
				Labels Generated: #dateFormat(now(),'yyyy-mm-dd')#  Page #cfdocument.currentPageNumber# of #cfdocument.totalPageCount#
			</div>
		</cfdocumentitem>

		<cfdocumentsection name="Lables">
			<table style="#tableWidth#">
				<tr>
					<cfset columnCounter = 0>
					<cfloop query="getItems">
						<td style="#labelHeight# #labelWidth#">
							<div style="#labelStyle# position: relative;">
								<cfswitch expression = "#variables.target#">
									<cfcase value="Dry_Large_Type__All">
										<div><strong style="font: 1.1em 'Times-Roman';">MCZ:#collection_cde#:#catalog_number#</strong></div>
										<div><strong style="font: 1em Helvetica;">#sci_name_with_auth#</strong></div>
										<div style="height: 1.38in; font: 1em Helvetica; overflow: hidden;">#tsname#</div>
										<div style="font: 0.9em 'Times-Roman'; position: absolute; bottom: 1px; left: 6em;">Museum of Comparative Zoology</div>
									</cfcase>
									<cfcase value="Slide_1x3__Mala">
										<div>
											<strong style="font: 0.9em 'Times-Roman';">MCZ:#collection_cde#:#catalog_number#</strong>
											<strong style="float: right; font: 0.9em Helvetica;">#type_status#</strong>
										</div>
										<cfif len(parent_label) EQ 0 or parent_label EQ 'unplaced'>
											<cfset parent = "">
										<cfelse>
											<cfset parent = " in #parent_label#">
										</cfif>
										<div style="font: 0.9em helvetica">Container:#container_label##parent#</div>
										<div><strong style="font: 0.9em Helvetica;">#just_sci_name#</strong></div>
										<div><strong style="font: 0.9em Helvetica;">#sci_name#</strong></div>
										<div style="height: 0.9in; font: 0.9em Helvetica; overflow: hidden;">#verbatim_locality#</div>
									</cfcase>
									<cfcase value="Slide_1x3__IZ">
										<cfif type_status_kind EQ 'Primary'>
											<cfset type_status_color = "color: red;">
										<cfelseif type_status_kind EQ 'Secondary'>
											<cfset type_status_color = "color: blue;">
										<cfelse>
											<cfset type_status_color = "">
										</cfif>
										<div>
											<strong style="font: 0.9em 'Times-Roman';">MCZ:#collection_cde#:#catalog_number#</strong>
											<strong style="float: right; font: 0.9em Helvetica; #type_status_color#">#top_type_status#</strong>
										</div>
										<cfif len(parent_label) EQ 0 or parent_label EQ 'unplaced'>
											<cfset parent = "">
										<cfelse>
											<cfset parent = " in #parent_label#">
										</cfif>
										<div style="font: 0.9em Helvetica;">#phylum# #phylclass# #phylorder# #family#</div>
										<div><strong style="font: 0.9em Helvetica;">#sci_name#</strong></div>
										<div style="position:absolute; bottom:0; left:0; right:0; font: 0.9em Helvetica;">#container_label#</div>
									</cfcase>
								</cfswitch>
							</div>
						</td>
						<cfset columnCounter = columnCounter + 1>
						<cfif columnCounter EQ columns>
							</tr>
							<cfset columnCounter = 0>
						</cfif>
					</cfloop>
				<cfif columnCounter NEQ 0>
					<cfloop index="i" from="#columnCounter#" to="#columns#">
						<td></td>
					</cfloop>
					</tr>
				</cfif>	
			</table>
		</cfdocumentsection>
	</cfoutput>
</cfdocument>
