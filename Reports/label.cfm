<!--- 
  Reports/lable.cfm proof of concept specimen label paperwork generation.

Copyright 2023 President and Fellows of Harvard College

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

<cfif not isDefined("result_id") OR len(result_id) EQ 0>
	<cfthrow message = "No result_id provided for query selecting labels to print.">
</cfif>

<cfset orientation = "portrait">

<cfquery name="getItems" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	SELECT DISTINCT
		cataloged_item.collection_object_id,
		cataloged_item.collection_cde,
		cataloged_item.cat_num,
		MCZBASE.get_top_typestatus(cataloged_item.collection_object_id) as typestatus,
		identification.scientific_name,
		specimen_part.part_name,
		MCZBASE.GET_PART_PREP(specimen_part.collection_object_id) as part_prep,
		MCZBASE.GET_PART_COUNT_MOD_FOR_PART(specimen_part.collection_object_id) as lot_count_mod,
		get_taxonomy(cataloged_item.collection_object_id,'family') as family,
		get_taxonomy(cataloged_item.collection_object_id,'phylum') as phylum
	 FROM
		user_search_table
		JOIN cataloged_item on user_search_table.collection_object_id = cataloged_item.collection_object_id
		JOIN specimen_part on cataloged_item.collection_object_id = specimen_part.derived_from_cat_item
		JOIN identification on cataloged_item.collection_object_id = identification.collection_object_id
		JOIN collecting_event on cataloged_item.collecting_event_id = collecting_event.collecting_event_id 
	WHERE
		identification.accepted_id_fg = 1 AND
		user_search_table.result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
	ORDER BY cat_num
</cfquery>

<cfdocument format="pdf" pagetype="letter" margintop=".25" marginbottom=".25" marginleft=".25" marginright=".25" orientation="#orientation#" fontembed="yes" saveAsName="MCZ_labels_#result_id#.pdf">
	<cfoutput>
		<cfdocumentitem type="header">
			<div style="text-align: center; font-size: x-small;">
				Museum of Comparative Zoology
			</div>
		</cfdocumentitem>
		
		<cfdocumentitem type="footer">
			<div style="text-align: center; font-size: x-small;">
				Labels Generated: #dateFormat(now(),'yyyy-mm-dd')#  Page #cfdocument.currentPageNumber# of #cfdocument.totalPageCount#
			</div>
		</cfdocumentitem>

		<cfset columns = 2>
		<cfset labelWidth = 'width: 3.3in;'>
		<cfset labelBorder = 'border: 1px;'>
		<cfset labelHeight = 'height: 2.5in;'>
		<cfset labelStyle = '#labelHeight# #labelWidth# #labelBorder#'>
		<cfdocumentsection name="Lables">
			<table>
				<tr>
					<cfset columnCounter = 0>
					<cfloop query="getItems">
						<td>
							<div style="#labelStyle#">
								#collection_cde# #cat_num#
								#phylum#:#family#
								#typestatus#
								#typestatus#
								#scientific_name#
								#part_name# #part_prep# #lot_count_mod#
							</div>
						</td>
						<cfset columnCounter = columnCounter + 1>
						<cfif columnCounter EQ columns>
							</tr>
							<cfset columnCounter = 0>
						</cfif>
					</cfloop>
				<!--- TODO: if not closed, close tr --->>
				</tr>
			</table>
		</cfdocumentsection>
	</cfoutput>
</cfdocument>
