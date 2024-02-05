<!--- 
  Reports/thermalLabel.cfm proof of concept specimen label generation for thermal 
  ribbon printing.

Copyright 2024 President and Fellows of Harvard College

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

<cfif not isDefined("target")>
	 <cfset target = "Fluid_Consolidated_WHOI__Mala">
</cfif>

<cfset pageWidth = "4"><!--- fixed page width of 4" for thermal printer labels ---->

<cfswitch expression = "#target#">
	<cfcase value="Fluid_Consolidated_WHOI__Mala">
		<!--- proof of concept for a thermal label produced from cfdocument --->
		<!--- 
		
		Target layout, 4" wide, arbitrary height
		
		**********
		
		Museum of Comparative Zoology, Malacology
		
		WHOI Jar Number nnn  [per page]
		
		Higher Taxonomy [class order family]
		
		Identification  [group by]
		Catalog Number  Locality   Count
		Catalog Number  Locality   Count
		
		***********
		
		--->
		<cfquery name="getItems" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			SELECT DISTINCT
				cataloged_item.collection_object_id,
				collection.collection_cde,
				collection.collection,
				cat_num as catalog_number,
				GET_HIGHER_TAXA_LENLIMITED(cataloged_item.collection_object_id,80) highertaxa,
				get_scientific_name_auths(cataloged_item.collection_object_id) sci_name_with_auth,
				MCZBASE.GET_ALCOHOLIC_PART_COUNT(cataloged_item.collection_object_id) as alc_count,
				get_single_other_id_display(cataloged_item.collection_object_id, 'whoi jar number') whoi_number,
				MCZBASE.GET_ALCOHOLIC_PART_COUNT(cataloged_item.collection_object_id) as alc_count,
				--  Concatenate continent_ocean, ocean_region, ocean_subregion, sea and
				--  trim leading duplicated ocean name from ocean_region, but
				--  leave out ocean_region if any of ocean_subregion, sea, country, island_group
				--  are populated.
				upper(continent_ocean) ||
				  upper(
				     decode(ocean_subregion||sea||country||island_group, null,
				         decode(ocean_region,null,'',
				         ':' || substr(ocean_region,instr(ocean_region,',')+1)
				         ),
				     '')
				  ) || 
				  decode(ocean_subregion,null,'',': ' || ocean_subregion) ||
				  decode(sea,null,'', ': ' || sea) as continent_ocean,
				country,
				spec_locality
			FROM
				user_search_table
				JOIN cataloged_item on user_search_table.collection_object_id = cataloged_item.collection_object_id
				JOIN collection on cataloged_item.collection_id = collection.collection_id
				JOIN collecting_event on cataloged_item.collecting_event_id = collecting_event.collecting_event_id
				JOIN locality on collecting_event.locality_id = locality.locality_id 
				JOIN geog_auth_rec on locality.geog_auth_rec_id = geog_auth_rec.geog_auth_rec_id 
			WHERE
				user_search_table.result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
			ORDER BY
				lpad(cat_num,10)
		</cfquery>
		<cfquery name="getWhoiNumbers" dbtype="query">
			SELECT count(collection_object_id) ct,
				whoi_number, 
				collection 
			FROM getItems
			GROUP BY collection, whoi_number
			ORDER BY collection, whoi_number
		</cfquery>
		<cfset orientation = "portrait">
		<cfset columns = 1>

		<!--- 
			NOTE: The variable names here, tableWidth/labelWidth are used for consistency with the general case (see label.cfm) 
			where the table has multiple columns with a table cell holding each label.  
		--->
		<!--- this is the largest width (class of <table>) inside the page width of "4in" (on <cfdocument>)--->
		<!--- This ought to equal the cfdocument pagewidth minus the marginleft and marginright --->
		<!--- Discrepancy of 0.1 in suggests the existence of a margin on the <table> or padding on its container --->
		<cfset tableWidth = 'width: 3.6in;'>

		<!---this is a class on the table <tr>, TODO: Fix: but *** should be on the table <td> *** --->
		<cfset labelWidth = 'width: 3.5in; padding:.05in; vertical-align: top;'>

		<!---Unused in this particular proof of concept label, likely will be needed in others, retain for reuse in other blocks if needed --->
		<cfset labelBorder = 'border: 1px solid black;'><!--- not used on most thermal labels --->
		<cfset labelHeight = 'height: 4.8in;'> <!--- here, pageheight minus margintop margin bottom, not true if multiple labels per page --->
		<cfset labelStyle = '#labelHeight# #labelWidth# #labelBorder#'>

		<cfset pageheight = "5"><!--- TODO: should be tunable by number of records --->

		<cfdocument format="pdf" pagetype="custom" unit="in" pagewidth="#pageWidth#" pageheight="#pageheight#" margintop=".1" marginbottom=".15" marginleft=".15" marginright=".15" orientation="#orientation#" fontembed="true" saveAsName="MCZ_labels_#result_id#.pdf">

			<cfoutput>
				<cfloop query="getWhoiNumbers">
					<cfdocumentsection name="aLabel">

						<div style="text-align: center;padding-top: .11in;">
							Museum of Comparative Zoology, #getWhoiNumbers.collection#
						</div>
						<div style="text-align: center; padding-bottom: .08in; border-bottom: 1px solid;margin-bottom: .08in;">
							WHOI Jar Number #getWhoiNumbers.whoi_number#
						</div>

						<cfquery name="getTaxa" dbtype="query">
							SELECT DISTINCT sci_name_with_auth, highertaxa 
							FROM getItems
							WHERE 
								whoi_number = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getWhoiNumbers.whoi_number#">
						</cfquery>
						<cfloop query="getTaxa">
							<cfset previousTaxon = "">
							<cfquery name="getSpecificItems" dbtype="query">
								SELECT DISTINCT * 
								FROM getItems
								WHERE 
									whoi_number = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getWhoiNumbers.whoi_number#">
									AND sci_name_with_auth = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTaxa.sci_name_with_auth#">
									AND highertaxa = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTaxa.highertaxa#">
							</cfquery>
	
								<cfif previousTaxon NEQ highertaxa>
									<div style="text-align: left;font: 9pt Helvetica, Arial, 'sans-serif';font-weight:bold;">#getTaxa.highertaxa#
									</div>
								</cfif>
								<div style="text-align: left;font: 9pt 'Times-Roman';font-weight:bold;">
									#getTaxa.sci_name_with_auth#
								</div>
								
								<table style="#tableWidth#">
									<cfloop query="getSpecificItems">
										<tr style="#labelWidth#">
											<td style="vertical-align: top;">
												<span style="font: 8pt 'Times-Roman';">MCZ:#getSpecificItems.collection_cde#:#getSpecificItems.catalog_number#</span>
											</td>
											<td style="vertical-align: top;">
												<span style="font: 8pt 'Times-Roman';">#getSpecificItems.spec_locality#</span>
											</td>
											<td style="vertical-align: top;">
												<span style="font: 8pt 'Times-Roman';">#getSpecificItems.alc_count# spec.</span>
											</td>
										</tr>
									</cfloop>
								</table>
						</cfloop>
					</cfdocumentsection>
					<cfdocumentitem type="pagebreak" />
				</cfloop>
			</cfoutput>
		</cfdocument>
	</cfcase>
</cfswitch>
