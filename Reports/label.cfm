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

<cfset target = "Dry_Large_Type__All">

<cfswitch expression = "#target#">
	<cfcase value="Dry_Large_Type__All">
		<cfquery name="getItems" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
		<cfset labelWidth = 'width: 3.5in;'>
		<cfset labelBorder = 'border: 1px;'>
		<cfset labelHeight = 'height: 2.0in;'>
	</cfcase>
</cfswitch>

<cfset labelStyle = '#labelHeight# #labelWidth# #labelBorder#'>
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

		<cfdocumentsection name="Lables">
			<table>
				<tr>
					<cfset columnCounter = 0>
					<cfloop query="getItems">
						<td>
							<div style="#labelStyle#">
								<cfswitch expression = "#target#">
									<cfcase value="Dry_Large_Type__All">
										<div><strong>MCZ:#collection_cde#:#catalog_number#</strong></div>
										<div><strong>#sci_name_with_auth#</strong></div>
										<div style="height: 1.38in;">#tsname#</div>
										<div style="text-align:center;">Museum of Comparative Zoology</div>
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
					<cfloop i from columnCounter to columns>
						<td></td>
					</cfloop>
					</tr>
				</cfif>	
			</table>
		</cfdocumentsection>
	</cfoutput>
</cfdocument>
