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
<cfquery name="getLoan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
				Printed: #dateFormat(now(),'yyyy-mm-dd')#
			</div>
		</cfdocumentitem>

		<cfdocumentsection name="Loan Header">
			<h1 style="text-align: center;">
				Invoice of Specimens
				#getLoan.collection#
				Museum of Comparative Zoology, Harvard University
			</h1>
			<table>
				<tr>
					<td>
						<div>
							This document acknowledges the #loan_type# of specimens to: #getLoan.recipientInstitutionName#.
						</div>
						<div>			
							<strong><cfif loan_type eq "gift" OR loan_type eq "transfer">Recipient<cfelse>Borrower</cfif></strong> #recAgentName#
						</div>
						<div>
							<strong>Shipped To:</strong><br>
							#replace(replace(shipped_to_address,chr(10),"<br>","all"),"&","&amp;","all")#
							#outside_email_address#<br>#outside_phone_number#
						</div>
					</td>
					<td>
						<ul style="text-align: left;">
							<li>Category: #getLoan.loan_type#</li>
							<li>Status: #getLoan.loan_status#</li>
							<li>Due Date: #getLoan.return_due_date#</li>
						</ul>
					</td>
				</tr>
			</table>
			<div>
				<strong>Nature of Material:</strong> #nature_of_material#
			</div>
			<div>
				<strong>Description:</strong> #loan_description#
			</div>
			<div>
				<strong>Instructions:</strong> #loan_instructions#
			</div>
		</cfdocumentsection>

		<cfdocumentsection name="Loan Conditions">
			<h1>Terms and Conditions</h1>
			<ol>
				<li>1.  Specimens from the collections of the Museum of Comparative Zoology are loaned at the discretion of the museum.</li>
				<li>2.  Specimens are loaned to bona fide institutions, not to individuals.</li>
				<li>3.  Borrowing institutions must demonstrate the ability properly unpack, care for, use, and return the borrowed specimens before a loan is granted.</li>
				<li>4.  The specimens must be returned by the date stated on the invoice unless a loan renewal is granted in writing by the loaning department.</li>
				<li>5.  Specimens on loan must be cared for according to standard best practices of collection care and handling.</li>
				<li>6.  Loans may not be transferred to another institution without the express written permission of the curator of the loaning department.</li>
				<li>7.  No invasive procedures (e.g., penetrations of the body wall or removal of any parts) of a loaned specimen may be conducted without the express written permission of the curator of the loaning department.</li>
				<li>8.  Express written permission must be obtained before a loaned specimen, image, mold or cast of the specimen may be used for any purpose other than scholarly research.</li>
				<li>9.  Loaned specimens must be packed for return in accordance with professional standards and be legally shipped to the Museum of Comparative Zoology.</li>
				<li>10. A loan may be recalled by the Museum of Comparative Zoology at any time at the discretion of the curator of the lending department or the Director of the MCZ.</li>
				<li>11. Copies of all publications, reports, or other citations of the loaned specimens must be sent promptly to the Museum of Comparative Zoology.</li>
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
