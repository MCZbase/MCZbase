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
<!---STYLING NOTES:::The thermal label needs to have inches (widths, margins, and padding) and points (fonts). The Arial, "sans-serif" font works best for the Mala collection. Not all fonts work. Only the most generic ones are available for printing.
-WHOI Jar Label width = 4 (inches)
-WHOI Jar Label height = 5 (inches)
-Margin = .015 (inches)
-The titles have padding above and below to separate them with a border-bottom under the jar name. Font is a bit larger than content at 11pt.
-Higher taxa is a bit smaller than the sciName at their request; 10.5pt and 11pt.
-Table of label content is the page width (4 in) minus the marginleft and marginright (.015in + .015in = .03in) in the <cfdocument> tag.
-Table row width equals "auto" to fill the table width.
-Table <td>s have align-top and font 10pt.--->
		<cfquery name="getItems" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			SELECT DISTINCT
				cataloged_item.collection_object_id,
				collection.collection_cde,
				collection.collection,
				cat_num as catalog_number,
				GET_HIGHER_TAXA_LENLIMITED(cataloged_item.collection_object_id,80) highertaxa,
				get_scientific_name_auths(cataloged_item.collection_object_id) sci_name_with_auth,
				MCZBASE.GET_ALCOHOLIC_PART_COUNT(cataloged_item.collection_object_id) as alc_count,
				get_single_other_id_display(cataloged_item.collection_object_id, 'whoi jar number') whoi_number,
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
		<!--- This equals the cfdocument pageWidth minus the marginleft and marginright --->
		<cfset tableWidth = 'width: 3.97in;'>
		<!---this is a class on the table row. It should fill the space inside he tableWidth. --->
		<cfset labelWidth = 'width: auto;'>
		<!---Unused in this particular proof of concept label, likely will be needed in others, retain for reuse in other blocks if needed --->
		<cfset labelBorder = 'border: 1px solid black;'><!--- Used under label type (e.g., WHOI Jar Number)  --->
		<cfset labelHeight = 'height: 5in;'> <!--- Jar label --Assuming 1 page per jar (not used yet) --->
		<cfset mczTitle = 'text-align: center;padding-top: .05in;font: 10.5pt Arial;'>
		<cfset jarTitle = 'text-align: center; padding-bottom: .05in; border-bottom: 1px solid;font: 10.5pt Arial;padding-top: .04in;margin-bottom: 0.04in;'>
		<cfset higherTaxa = 'text-align: left; font: 10.5pt Arial;padding: .02in;'>
		<cfset sciName = "text-align: left;font: 10.5pt Helvetica, Arial, 'sans-serif'; padding: .05in .02in .02in .02in;font-weight:bold;">
		<cfset contentFont = 'font: 9pt Arial;'>
		<cfset tdAlign = 'vertical-align: top;'>
		<cfset labelStyle = '#labelHeight# #labelWidth# #labelBorder#'><!---  (not used yet) --->
		<cfset pageHeight = "5"><!--- Thermal Paper height; For WHOI jar number label, this is the height the jar can accommodate. TODO: should be tunable by number of records --->
		<cfset pageWidth = "4"><!---Thermal Paper width--->
		<cfdocument format="pdf" pagetype="custom" unit="in" pagewidth="#pageWidth#" pageheight="#pageHeight#" margintop=".015" marginright=".015" marginbottom=".015" marginleft=".015" orientation="#orientation#" fontembed="true" saveAsName="MCZ_labels_#result_id#.pdf">
			<cfoutput>
				<cfloop query="getWhoiNumbers">
					<cfdocumentsection name="aLabel">
						<div style="#mczTitle#">
							Museum of Comparative Zoology, #getWhoiNumbers.collection#
						</div>
						<div style="#jarTitle#">
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
									<div style="#higherTaxa#">#getTaxa.highertaxa#</div>
								</cfif>
								<div style="#sciName#">#getTaxa.sci_name_with_auth#</div>
								
								<table style="#tableWidth#">
									<cfloop query="getSpecificItems">
										<tr style="#labelWidth#">
											<td style="#tdAlign#">
												<span style="#contentFont#">MCZ:#getSpecificItems.collection_cde#:#getSpecificItems.catalog_number#
											</td>
											<td style="#tdAlign#">
												<span style="#contentFont#">#getSpecificItems.spec_locality#</span>
											</td>
											<td style="#tdAlign#">
												<span style="#contentFont#">#getSpecificItems.alc_count# spec.</span>
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
	<cfcase value="Fluid_Consolidated_SchJ__Mala">
		<cfquery name="getItems" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			SELECT DISTINCT
				cataloged_item.collection_object_id,
				collection.collection_cde,
				collection.collection,
				cat_num as catalog_number,
				GET_HIGHER_TAXA_LENLIMITED(cataloged_item.collection_object_id,80) highertaxa,
				get_scientific_name_auths(cataloged_item.collection_object_id) sci_name_with_auth,
				MCZBASE.GET_ALCOHOLIC_PART_COUNT(cataloged_item.collection_object_id) as alc_count,
				MCZBASE.GET_PART_COUNT_MOD(cataloged_item.collection_object_id) as part_count,
				get_single_other_id_display(cataloged_item.collection_object_id, 'Scheltema jar number') jar_number,
				'Scheltema jar number' number_series,
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
		<cfquery name="getJarNumbers" dbtype="query">
			SELECT count(collection_object_id) ct,
				jar_number, 
				collection,
				number_series
			FROM getItems
			GROUP BY collection, jar_number, number_series
			ORDER BY collection, jar_number, number_series
		</cfquery>
		<cfset orientation = "portrait">
		<cfset columns = 1>
		<!--- 
			NOTE: The variable names here, tableWidth/labelWidth are used for consistency with the general case (see label.cfm) 
			where the table has multiple columns with a table cell holding each label.  
		--->
		<!--- this is the largest width (class of <table>) inside the page width of "4in" (on <cfdocument>)--->
		<!--- This equals the cfdocument pageWidth minus the marginleft and marginright --->
		<cfset tableWidth = 'width: 3.97in;'>
		<!---this is a class on the table row. It should fill the space inside he tableWidth. --->
		<cfset labelWidth = 'width: auto;'>
		<!---Unused in this particular proof of concept label, likely will be needed in others, retain for reuse in other blocks if needed --->
		<cfset labelBorder = 'border: 1px solid black;'><!--- Used under label type  --->
		<cfset labelHeight = 'height: 5in;'> <!--- Jar label --Assuming 1 page per jar (not used yet) --->
		<cfset mczTitle = 'text-align: center;padding-top: .11in;font: 11pt Arial;'>
		<cfset jarTitle = 'text-align: center; padding-bottom: .07in; border-bottom: 1px solid;font: 11pt Arial;padding-top: .05in;margin-bottom: 0.05in;'>
		<cfset higherTaxa = 'text-align: left; font: 10.5pt Arial;padding: .02in;'>
		<cfset sciName = "text-align: left;font: 10.5pt Helvetica, Arial, 'sans-serif'; padding: .05in .02in .02in .02in;font-weight:bold;">
		<cfset contentFont = 'font: 9pt Arial;'>
		<cfset tdAlign = 'vertical-align: top;'>
		<cfset labelStyle = '#labelHeight# #labelWidth# #labelBorder#'><!---  (not used yet) --->
		<cfset pageHeight = "5"><!--- Thermal Paper height; For jar number label, this is the height the jar can accommodate. TODO: should be tunable by number of records --->
		<cfset pageWidth = "4"><!---Thermal Paper width--->
		<cfdocument format="pdf" pagetype="custom" unit="in" pagewidth="#pageWidth#" pageheight="#pageHeight#" margintop=".015" marginright=".015" marginbottom=".015" marginleft=".015" orientation="#orientation#" fontembed="true" saveAsName="MCZ_labels_#result_id#.pdf">
			<cfoutput>
				<cfloop query="getJarNumbers">
					<cfdocumentsection name="aLabel">
						<div style="#mczTitle#">
							Museum of Comparative Zoology, #getJarNumbers.collection#
						</div>
						<div style="#jarTitle#">
							#number_series# #getJarNumbers.jar_number#
						</div>
						<cfquery name="getTaxa" dbtype="query">
							SELECT DISTINCT sci_name_with_auth, highertaxa 
							FROM getItems
							WHERE 
								jar_number = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getJarNumbers.jar_number#">
						</cfquery>
						<cfloop query="getTaxa">
							<cfset previousTaxon = "">
							<cfquery name="getSpecificItems" dbtype="query">
								SELECT DISTINCT * 
								FROM getItems
								WHERE 
									jar_number = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getJarNumbers.jar_number#">
									AND sci_name_with_auth = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTaxa.sci_name_with_auth#">
									AND highertaxa = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTaxa.highertaxa#">
							</cfquery>
	
								<cfif previousTaxon NEQ highertaxa>
									<div style="#higherTaxa#">#getTaxa.highertaxa#</div>
								</cfif>
								<div style="#sciName#">#getTaxa.sci_name_with_auth#</div>
								
								<table style="#tableWidth#">
									<cfloop query="getSpecificItems">
										<tr style="#labelWidth#">
											<td style="#tdAlign#">
												<span style="#contentFont#">MCZ:#getSpecificItems.collection_cde#:#getSpecificItems.catalog_number#
											</td>
											<td style="#tdAlign#">
												<span style="#contentFont#">#getSpecificItems.spec_locality#</span>
											</td>
											<td style="#tdAlign#">
												<span style="#contentFont#">
													#getSpecificItems.alc_count# spec.
													<cfif getSpecificItems.part_count NEQ getSpecificItems.alc_count>
														[#getSpecificItems.part_count# total]
													</cfif>
												</span>
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
