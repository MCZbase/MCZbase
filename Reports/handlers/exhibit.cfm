<!--- 
Reports/templates/exhibition.cfm temporary exhibiton specimen label generation

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

<cfset target = "ExhibitTent__Mamm">

<cfswitch expression = "#target#">
	<cfcase value="ExhibitTent__Mamm">
		<cfquery name="getItems" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			SELECT DISTINCT
				MCZBASE.get_scientific_name(cataloged_item.collection_object_id) sci_name,
				MCZBASE.get_common_names(cataloged_item.collection_object_id) common_names,
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

		<cfdocument format="pdf" pagetype="letter" margintop=".5" marginbottom=".5" marginleft=".5" marginright=".5" orientation="#orientation#" fontembed="yes" saveAsName="MCZ_exhibitlabels_#result_id#.pdf">
		<cfoutput>

			<cfobject type="Java" name="qrCode" class="io.nayuki.qrcodegen.QrCode" >
			<cfobject type="Java" name="ecc" class="io.nayuki.qrcodegen.QrCode.Ecc" >
			<cfobject type="Java" name="qrCodeUtility" class="QrCodeGeneratorDemo" >

			<!--- TODO: roduce image from QRCode object and embed in pdf. --->
			<!--- for some options, see: https://stackoverflow.com/questions/34316662/using-cfimage-to-display-a-file-that-doesnt-have-an-extension/ --->

			<cfdocumentsection name="Lables">
				<cfloop query="getItems">
					<cfset guid="MCZ:#collection_cde#:#catalog_number#">
					<cfset qrCodeInstance = qrCode.encodeText(JavaCast("string","https://mczbase.mcz.harvard.edu/guid/#guid#"),ecc.HIGH) >
					<cfset svg = qrCodeUtility.toSvgString(qrCodeInstance,0,JavaCast("string","white"),JavaCast("string","black"))>
					<div>
						<div><strong style="font: 1.8em 'Times-Roman';">#guid#</strong></div>
						<div><strong style="font: 2em Helvetica;">#sci_name#</strong></div>
						<div style="height: 3in; font: 2em Helvetica; overflow: hidden;">#common_names#</div>
						<img src="data:image/svg+xml;utf8,#svg#">
						<div style="font: 0.9em 'Times-Roman'; position: absolute; bottom: 1px; left: 6em;">Museum of Comparative Zoology</div>
					</div>
					<cfdocumentitem type = "pagebreak" />
				</cfloop>	
			</cfdocumentsection>
		</cfoutput>
		</cfdocument>
	</cfcase>
</cfswitch>
