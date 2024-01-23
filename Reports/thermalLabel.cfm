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

<cfset target = "Fluid_Consolidated_WHOI__Mala">

<cfswitch expression = "#target#">
	<cfcase value="Fluid_Consolidated_WHOI__Mala">
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
		<cfset tableWidth = 'width: 4in;'>
		<cfset labelWidth = 'width: 3.5in;'>
		<cfset labelBorder = 'border: 1px solid black;'>
		<cfset labelHeight = 'height: 2.0in;'>
		<cfset labelStyle = '#labelHeight# #labelWidth# #labelBorder# padding: 5px;'>

		<cfset pageheight = "6"><!--- should be tunable by number of records --->

		<cfdocument format="pdf" pagetype="custom" unit="in" pagewidth="4" pageheight="#pageheight#" margintop=".25" marginbottom=".25" marginleft=".5" marginright=".5" orientation="#orientation#" fontembed="true" saveAsName="MCZ_labels_#result_id#.pdf">
			<cfoutput>
				<cfloop query="getWhoiNumbers">

					<cfdocumentsection name="header">
						<div style="text-align: center; font-size: small;">
							Museum of Comparative Zoology, #getWhoiNumbers.collection#
						</div>
						<div style="text-align: center;">
							WHOI Jar Number #getWhoiNumbers.whoi_number#
						</div>
					</cfdocumentsection>

					<cfquery name="getTaxa" dbtype="query">
						SELECT sci_name_with_auth, highertaxa 
						FROM getItems
						WHERE 
							whoi_number = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getWhoiNumbers.whoi_number#">
					</cfquery>
					<cfloop query="getTaxa">
						<cfset previousTaxon = "">
						<cfquery name="getSpecificItems" dbtype="query">
							SELECT * 
							FROM getItems
							WHERE 
								whoi_number = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getWhoiNumbers.whoi_number#">
								AND sci_name_with_auth = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getWhoiNumbers.sci_name_with_auth#">
								AND highertaxa = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getWhoiNumbers.highertaxa#">
						</cfquery>

						<cfdocumentsection name="Lables">
							<cfif previousTaxon NEQ highertaxa>
								<div style="text-align: left;">
									<strong style="font: 1em Helvetica;">#highertaxa#</strong>
								</div>
							</cfif>
							<div style="text-align: left;">
								<strong style="font: 1em 'Times-Roman';">#sci_name_with_auth#</strong>
							</div>
							
							<table style="#tableWidth#">
								<tr style="#labelWidth#">
									<cfloop query="getSpecificItems">
										<td>
											<strong style="font: 1.1em 'Times-Roman';">MCZ:#getSpecificItems.collection_cde#:#getSpecificItems.catalog_number#</strong>
										</td>
										<td>
											<strong style="font: 1em Helvetica;">#sci_name_with_auth#</strong>
										</td>
										<td>
											<strong style="font: 1em Helvetica;">#getSpecificItems.alc_count#</strong>
										</td>
									</cfloop>
								</tr>
							</table>
						</cfdocumentsection>

					<cfdocumentitem type="pagebreak" />
				</cfloop>
				</cfloop>

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


Entomology consolidated query, with collector_number:

select
get_taxonomy(cataloged_item.collection_object_id,'family') family,

mczbase.get_scientific_name_truncate(cataloged_item.collection_object_id,32) tsname,

-- obtain the first typestatus name, if any
REGEXP_SUBSTR(
   replace(
      replace(MCZBASE.concattypestatus_label(cataloged_item.collection_object_id), '&', '&amp;')
      ,'<BR>','|')
   , '[^|]+',1,1
) typestatusnames,

cat_num as catalog_number,
sea,
state_prov,
country,
ocean_region,
ocean_subregion,
type_status,
get_single_other_id_display(cataloged_item.collection_object_id, 'collector number') field_number,
get_alcoholic_part_count(cataloged_item.collection_object_id) alc_count
FROM
cataloged_item,
identification,
collecting_event,
locality,
geog_auth_rec,
citation
WHERE
cataloged_item.collection_object_id = identification.collection_object_id AND
cataloged_item.collecting_event_id = collecting_event.collecting_event_id AND
collecting_event.locality_id = locality.locality_id AND
locality.geog_auth_rec_id = geog_auth_rec.geog_auth_rec_id AND
cataloged_item.collection_object_id = citation.collection_object_id (+) AND
accepted_id_fg=1 AND cataloged_item.collection_object_id IN (#collection_object_id#)

---------

Query for Fluid_ConsolidatedMultiTaxon__Mala_IZ 

select
GET_HIGHER_TAXA_LENLIMITED(cataloged_item.collection_object_id,80) highertaxa,
get_scientific_name_auths(cataloged_item.collection_object_id) sci_name_with_auth,

-- obtain the first typestatus name, if any
REGEXP_SUBSTR(
   replace(
      replace(MCZBASE.concattypestatus_label(cataloged_item.collection_object_id), '&', '&amp;')
      ,'<BR>','|')
   , '[^|]+',1,1
) typestatusnames,


cat_num as catalog_number,
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
state_prov
FROM
cataloged_item,
identification,
collecting_event,
locality,
geog_auth_rec,
citation
WHERE
cataloged_item.collection_object_id = identification.collection_object_id AND
cataloged_item.collecting_event_id = collecting_event.collecting_event_id AND
collecting_event.locality_id = locality.locality_id AND
locality.geog_auth_rec_id = geog_auth_rec.geog_auth_rec_id AND
cataloged_item.collection_object_id = citation.collection_object_id (+) AND
accepted_id_fg=1 AND cataloged_item.collection_object_id IN (#collection_object_id#)

order by get_scientific_name_auths(cataloged_item.collection_object_id), cat_num_prefix, cat_num


--->
	

			</cfoutput>
		</cfdocument>
	</cfcase>
</cfswitch>
