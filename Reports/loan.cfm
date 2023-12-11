<!--- 
  Reports/loan.cfm proof of concept loan paperwork generation.

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

<cfif not isDefined("transaction_id") OR len(transaction_id) EQ 0>
	<cfthrow message = "No transaction_id provided for loan to print.">
</cfif>
<cfif not isDefined("action") OR len(action) EQ 0>
	<cfset action="entryPoint">
</cfif>

<cf_getLoanFormInfo>
<cfquery name="getLoan" dbtype="query">
   select * from getLoanMCZ
</cfquery>
<cfif getLoan.recordcount EQ 0>
	<cfthrow message = "No loan found for provided transaction_id [#encodeForHtml(transaction_id)#].">
</cfif>
<cfquery name="getLoanItems" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	SELECT guid, part_name,
		to_char(reconciled_date,'yyyy-mm-dd') reconciled_date 
	FROM loan_item
		JOIN specimen_part on loan_item.collection_object_id = specimen_part.collection_object_id
		JOIN flat on specimen_part.derived_from_cat_item = flat.collection_object_id
	WHERE
		loan_item.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
</cfquery>

<!--------------------------------------------------------------------------------->
<cfdocument format="pdf" saveAsName="MCZ_Loan_#getLoan.loan_number#.pdf" pageType="letter" marginTop="0.5" marginBottom="0.5" marginLeft="0.5" marginRight="0.5" fontEmbed="yes">
	<cfoutput query="getLoan">

		<cfdocumentitem type="header">
			<div style="text-align: center; font-size: small;">
				Museum of Comparative Zoology Loan #getLoan.loan_number#
			</div>
		</cfdocumentitem>
		
		<cfdocumentitem type="footer">
			<div style="text-align: center; font-size: x-small;">
				PDF Generated: #dateFormat(now(),'yyyy-mm-dd')#  Page #cfdocument.currentPageNumber# of #cfdocument.totalPageCount#
			</div>
		</cfdocumentitem>

		<cfdocumentsection name="Loan Header">
			<div style="text-align: center; font-size: 1em;">
				Invoice of Specimens
			</div>
			<div style="text-align: center; font-size: 1em;">
				#getLoan.collection#
			</div>
			<div style="text-align: center; font-size; 1em;">
				Museum of Comparative Zoology, Harvard University
			</div>
			<table style="font-size: small;">
				<tr>
					<td style="width: 55%; vertical-align: top;">
						<div>
							This document acknowledges the Loan of specimens to: #getLoan.recipientInstitutionName#.
						</div>
						<div>			
							<strong>Borrower:</strong> #recAgentName#
						</div>
						<div>
							<strong>Shipped To:</strong><br>
							#replace(replace(shipped_to_address,chr(10),"<br>","all"),"&","&amp;","all")#
							#outside_email_address#<br>#outside_phone_number#
						</div>
					</td>
					<td style="width: 45%; vertical-align: top;">
						<ul style="text-align: left;">
							<li><strong>Category:</strong> #getLoan.loan_type#</strong>
							<li><strong>Loan Number:</strong> #getLoan.loan_number#</strong>
							<li><strong>Loan Date:</strong> #trans_date#</strong>
							<li><strong>Approved By:</strong> #authAgentName#</strong>
							<li><strong>Packed By:</strong> #processed_by_name#</strong>
							<li><strong>Method of Shipment:</strong> #shipped_carrier_method#</strong>
							<li><strong>Number of Packages:</strong> #no_of_packages#</strong>
							<li><strong>Number of Specimens:</strong> #num_specimens#</strong>
							<li><strong>Number of Lots:</strong> #num_lots#</strong>
							<li><strong>For Use By:</strong> #foruse_by_name#</strong>
						</ul>
					</td>
				</tr>
			</table>
			<div style="font-size: small;">
				<div>
					<strong>Nature of Material:</strong> #nature_of_material#
				</div>
				<cfif len(loan_description) GT 0>
					<div>
						<strong>Description:</strong> #loan_description#
					</div>
				</cfif>
				<div>
					<strong>Instructions:</strong> #loan_instructions#
				</div>
				<h2 style="font-size: small;">Terms and Conditions</h2>
				<ol>
					<li>Specimens from the collections of the Museum of Comparative Zoology are loaned at the discretion of the museum.</li>
					<li>Specimens are loaned to bona fide institutions, not to individuals.</li>
					<li>Borrowing institutions must demonstrate the ability properly unpack, care for, use, and return the borrowed specimens before a loan is granted.</li>
					<li>The specimens must be returned by the date stated on the invoice unless a loan renewal is granted in writing by the loaning department.</li>
					<li>Specimens on loan must be cared for according to standard best practices of collection care and handling.</li>
					<li>Loans may not be transferred to another institution without the express written permission of the curator of the loaning department.</li>
					<li>No invasive procedures (e.g., penetrations of the body wall or removal of any parts) of a loaned specimen may be conducted without the express written permission of the curator of the loaning department.</li>
					<li>Express written permission must be obtained before a loaned specimen, image, mold or cast of the specimen may be used for any purpose other than scholarly research.</li>
					<li>Loaned specimens must be packed for return in accordance with professional standards and be legally shipped to the Museum of Comparative Zoology.</li>
					<li>A loan may be recalled by the Museum of Comparative Zoology at any time at the discretion of the curator of the lending department or the Director of the MCZ.</li>
					<li>Copies of all publications, reports, or other citations of the loaned specimens must be sent promptly to the Museum of Comparative Zoology.</li>
				</ol>
			</div>
			<table style="font-size: small;">
				<tr>
					<td style="width: 50%; vertical-align: top;">
						<h2>UPON RECEIPT, SIGN AND RETURN ONE COPY TO:</h2>
						<div>
							#replace(shipped_from_address,chr(10),"<br>","all")# 
							<cfif loan_type EQ "exhibition">
								#addInHouseContactPhEmail#
							<cfelse>
								#inside_phone_number#
								<br>
								#inside_email_address#
							</cfif>
						</div>
					</td>
					<td style="width: 50%; vertical-align: top;">
						<div>Borrower (noted above) acknowledges reading and agreeing to the terms and conditions noted in this document.<div>
						<div><strong>Expected return date: #dateformat(return_due_date,"dd mmmm yyyy")#</strong></div>
						<br>
						<div style="text-align: right;">Borrower&##39;s Signature: _________________</div>
						<div style="text-align: right;">#recAgentName#</div>
					</td>
				</tr>
			</table>
		</cfdocumentsection>

		<cfdocumentsection name="Loan Conditions">
			<h1>Terms and Conditions</h1>
			<ol>
				<li>Specimens from the collections of the Museum of Comparative Zoology are loaned at the discretion of the museum.</li>
				<li>Specimens are loaned to bona fide institutions, not to individuals.</li>
				<li>Borrowing institutions must demonstrate the ability properly unpack, care for, use, and return the borrowed specimens before a loan is granted.</li>
				<li>The specimens must be returned by the date stated on the invoice unless a loan renewal is granted in writing by the loaning department.</li>
				<li>Specimens on loan must be cared for according to standard best practices of collection care and handling.</li>
				<li>Loans may not be transferred to another institution without the express written permission of the curator of the loaning department.</li>
				<li>No invasive procedures (e.g., penetrations of the body wall or removal of any parts) of a loaned specimen may be conducted without the express written permission of the curator of the loaning department.</li>
				<li>Express written permission must be obtained before a loaned specimen, image, mold or cast of the specimen may be used for any purpose other than scholarly research.</li>
				<li>Loaned specimens must be packed for return in accordance with professional standards and be legally shipped to the Museum of Comparative Zoology.</li>
				<li>A loan may be recalled by the Museum of Comparative Zoology at any time at the discretion of the curator of the lending department or the Director of the MCZ.</li>
				<li>Copies of all publications, reports, or other citations of the loaned specimens must be sent promptly to the Museum of Comparative Zoology.</li>
			</ol>
		</cfdocumentsection>

		<cfdocumentsection name="Items In Loan">
			<h1>Item Invoice</h1>
			<cfloop query="getLoanItems">
				<div>
					#guid# #part_name# #reconciled_date#
				</div>
			</cfloop>
		</cfdocumentsection>

	</cfoutput>
</cfdocument>
