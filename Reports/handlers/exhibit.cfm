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

Requires qrcodegen and custom wrapper library in coldfusion cfusion/wwwroot/WEB-INF/lib
wget https://repo1.maven.org/maven2/io/nayuki/qrcodegen/1.8.0/qrcodegen-1.8.0.jar

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
				MCZBASE.concatattributevalue(cataloged_item.collection_object_id, 'sex') sex,
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

		<cfdocument format="pdf" localUrl="yes" pagetype="letter" margintop=".5" marginbottom=".5" marginleft=".5" marginright=".5" orientation="#orientation#" fontembed="yes" saveAsName="MCZ_exhibitlabels_#result_id#.pdf">
		<cfoutput>

			<!--- now wrapped in utility class --->
			<!--- cfobject type="Java" name="qrCode" class="io.nayuki.qrcodegen.QrCode" --->
			<!--- Utility class exposing methods from QrCodeGeneratorDemo and QrCode --->
			<cfobject type="Java" name="qrCodeUtility" class="edu.harvard.mcz.qrCodeUtility.QRCodeUtility" >
			<cfobject type="Java" name="bufferedImage" class="java.awt.image.BufferedImage" >
			<cfobject type="Java" name="imageIO" class="javax.imageio.ImageIO" >
			<cfobject type="Java" name="afile" class="java.io.File" >

			<cfdocumentsection name="Lables">
				<cfset counter = 0>
				<cfloop query="getItems">
					<cfif counter GT 0>
						<cfdocumentitem type = "pagebreak" />
					</cfif>
					<cfset counter = counter +1>
					<cfset guid="MCZ:#collection_cde#:#catalog_number#">
					<cfset qrCodeInstance = qrCodeUtility.encodeTextHigh(JavaCast("string","https://mczbase.mcz.harvard.edu/guid/#guid#")) >
					<!--- Produce image from QRCode object and embed in pdf. --->
					<!--- for some options, see: https://stackoverflow.com/questions/34316662/using-cfimage-to-display-a-file-that-doesnt-have-an-extension/ --->
					<cfset svg = qrCodeUtility.toSvgString(qrCodeInstance)>
					<cfset bimage = qrCodeUtility.toImage(qrCodeInstance,JavaCast("int",10))>
					<div style="padding-top: 4.25in;">
						<table style="width: 100%;">
							<tr>
								<td style="vertical-align: top;">
									<div>
										<strong style="font: 1.6em 'Times-Roman';">#guid#</strong></div>
									<br>
										<span style="font: 1.5em 'Times-Roman';">#sex#</span>
									</div>
								</td>
								<td>
									<div style="float: right;">
									<!--- needs jpeg or png, seems to need to go through filesystem write and load from a file:/// location --->
									<cfset filename = "tempqrcode_#collection_cde#_#catalog_number#.jpg">
									<cfset filepath = "#Application.webDirectory#/temp/#filename#">
       				  			<cfset outputfile = afile.init(JavaCast("string","#filepath#"))>
         						<cfset imageIO.write(bimage,JavaCast("string","jpg"),outputfile)>
									<img src="file:///#filepath#" height="215" width="215">
									<div>
								</td>
							</tr>
							<tr>
								<td colspan="2">
									<div style="text-align: center; padding-top: 1em;"><i style="font: 2.3em Helvetica;">#sci_name#</i></div>
									<div style="font: 2.3em Helvetica; text-align: center;">#common_names#</div>
								</td>
							</tr>
						</table>
					</div>
				</cfloop>	
			</cfdocumentsection>
		</cfoutput>
		</cfdocument>
		<!--- TODO: pdftk rotate, multistamp, or equivalent --->
		<!--- 
			pdftk file1.pdf cat 1-endsouth  output filerot.pdf
			pdftk file1.pdf multistamp filerot.pdf output file2.pdf
			or
			pdftk file1.pdf cat 1-endsouth output - | pdftk file1.pdf multistamp - output file2.pdf
		--->
		<!---
		<cfexecute name="bash" arguments="/usr/bin/pdftk file1.pdf cat 1-endsouth output - | pdftk file1.pdf multistamp - output file2.pdf" variable="standardOut" errorVariable="errorOut"  timeout="10" >
		--->
	</cfcase>
</cfswitch>
