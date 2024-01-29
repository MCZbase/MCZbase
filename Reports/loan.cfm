<!--- 
  Reports/loan.cfm proof of concept loan paperwork generation.

Copyright 2023-2024 President and Fellows of Harvard College

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
<cfif getLoan.loan_type EQ "exhibition-master">
	<!--- TODO: Special handling --->
	<cfquery name="getSubloans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		SELECT
			loan.transaction_id, 
			loan.loan_number
		FROM
			loan_relations
			join loan on loan_relations.related_transaction_id = loan.transaction_id
		WHERE
			loan_relations.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
			AND
			loan_relations.relation_type = 'Subloan'
	</cfquery>
</cfif>
<cfif getLoan.loan_type EQ "exhibition-subloan">
	<!--- TODO: Special handling --->
	<cfquery name="getMasterLoan" datasource="uam_god">
		SELECT
			loan.transaction_id, 
			loan.loan_number
		FROM
			loan_relations
			join loan on loan_relations.transaction_id = loan.transaction_id
		WHERE
			loan_relations.related_transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
			AND
			loan_relations.relation_type = 'Subloan'
	</cfquery>
</cfif>
<cfquery name="getLoanItems" dbtype="query">
   select * from getLoanItemsMCZ
</cfquery>
<cfquery name="getHasFluid" dbtype="query">
	select count(*) ct 
	from getLoanItemsMCZ
	where preserve_method like '%thanol%' or preserve_method like '%alcohol%'
</cfquery>
<cfquery name="getRestrictions" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select distinct restriction_summary, permit_id, permit_num, source from (
	select permit.restriction_summary, permit.permit_id, permit.permit_num, 'accession' as source
	from loan_item li 
		join specimen_part sp on li.collection_object_id = sp.collection_object_id
		join cataloged_item ci on sp.derived_from_cat_item = ci.collection_object_id
		join accn on ci.accn_id = accn.transaction_id
		join permit_trans on accn.transaction_id = permit_trans.transaction_id
		join permit on permit_trans.permit_id = permit.permit_id
	where li.transaction_id = <cfqueryparam CFSQLType="CF_SQL_DECIMAL" value="#transaction_id#">
		and permit.restriction_summary is not null
	union
	select permit.restriction_summary, permit.permit_id, permit.permit_num, 'loan shipment' as source
	from loan
		join shipment on loan.transaction_id = shipment.transaction_id
		join permit_shipment on shipment.shipment_id = permit_shipment.shipment_id
		join permit on permit_shipment.permit_id = permit.permit_id
	where loan.transaction_id = <cfqueryparam CFSQLType="CF_SQL_DECIMAL" value="#transaction_id#">
		and permit.restriction_summary is not null
	)
</cfquery>
<cfquery name="getShipments" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	SELECT
		shipment_id,
		to_addr.formatted_addr toAddress,
		from_addr.formatted_addr fromAddress
	FROM
		shipment
		left join addr to_addr on shipment.shipped_to_addr_id = to_addr.addr_id
		left join addr from_addr on shipment.shipped_from_addr_id = from_addr.addr_id 
	WHERE 
		shipment.transaction_id = <cfqueryparam CFSQLType="CF_SQL_DECIMAL" value="#transaction_id#">
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
			<table style="font-size: small; padding: 0px; margin: 0px;">
				<tr>
					<td style="width: 55%; vertical-align: top;">
						<div>
							This document acknowledges the Loan of specimens <strong>To:</strong> #getLoan.recipientInstitutionName#.
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
						<ul style="text-align: left; list-style: none;">
							<cfif NOT (loan_status EQ "open" OR loan_status EQ "in process") >
								<li style="list-style-type: none"><strong>Status:</strong> #loan_status#</strong>
							</cfif>
							<li style="list-style-type: none"><strong>Category:</strong> #getLoan.loan_type#</strong>
							<li style="list-style-type: none"><strong>Loan Number:</strong> #getLoan.loan_number#</strong>
							<cfif getLoan.loan_type EQ "exhibition-subloan">
								<cfloop query="getMasterLoan">
									<li style="list-style-type: none"><strong>Subloan of:</strong> #getMasterLoan.loan_number#</strong>
								</cfloop>
							</cfif>
							<li style="list-style-type: none"><strong>Loan Date:</strong> #trans_date#</strong>
							<li style="list-style-type: none"><strong>Approved By:</strong> #authAgentName#</strong>
							<li style="list-style-type: none"><strong>Packed By:</strong> #processed_by_name#</strong>
							<li style="list-style-type: none"><strong>Method of Shipment:</strong> #shipped_carrier_method#</strong>
							<li style="list-style-type: none"><strong>Number of Packages:</strong> #no_of_packages#</strong>
							<li style="list-style-type: none"><strong>Number of Specimens:</strong> #num_specimens#</strong>
							<li style="list-style-type: none"><strong>Number of Lots:</strong> #num_lots#</strong>
							<cfif len(foruse_by_name) GT 0>
								<li style="list-style-type: none"><strong>For Use By:</strong> #foruse_by_name#</strong>
							</cfif>
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
					<cfif getRestrictions.recordcount GT 0>
						<li>Additional Restrictions on use from original permits apply, see attached summary.</li>
					</cfif>
				</ol>
			</div>
			<table style="font-size: small;">
				<tr>
					<td style="width: 50%; vertical-align: top;">
						<h2 style="font-size: small;">UPON RECEIPT, SIGN AND RETURN ONE COPY TO:</h2>
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
						<div style="text-align: right;">Borrower&##39;s Signature: ___________________________</div>
						<div style="text-align: right;">#recAgentName#</div>
					</td>
				</tr>
			</table>
		</cfdocumentsection>

		<cfif getLoan.loan_type EQ "exhibition-master">
			<cfdocumentsection name="Subloans">
				<div style="text-align: center; font-size: 1em;">
					Exhibition Subloans
				</div>
				<ul>
					<cfloop query="getSubloans">
							<li><strong>#loan_number#</strong></li>
					</cfloop>
				</ul>
			</cfdocumentsection>
		</cfif>

		<cfif getRestrictions.recordcount GT 0>
			<cfdocumentsection name="Additional Restrictions">
				<div style="text-align: center; font-size: 1em;">
					Summary of restrictions imposed by original collecting agreements
				</div>
				<ul>
					<cfloop query="getRestrictions">
						<cfif getRestrictions.source EQ "accession">
							<li><strong>#permit_num#</strong> #restriction_summary#</li>
						<cfelse>
							<li><strong>#permit_num# Applies to all material in this loan:</strong> #restriction_summary#</li>
						</cfif>
					</cfloop>
				</ul>
			</cfdocumentsection>
		</cfif>

		<cfdocumentsection name="Items In Loan">
			<div style="text-align: center; font-size: 1em;">
				Invoice of Specimens
			</div>
			<div>
				Retain in 70% ethanol unless noted otherwise.
			</div>
			<cfif getLoan.loan_type EQ "exhibition-master">
				<cfset master_transaction_id = transaction_id>
				<cfset masterTotal = 0>
				<cfset masterLotTotal = 0>
				<cfloop query="getSubloans">
					<cfset transaction_id = getSubloans.transaction_id>
					<cfquery name="getLoanItems" dbtype="query">
					   select * from getLoanItemsMCZ
					</cfquery>
					<div style="text-align: left; font-size: 1em;">
						Specimens in Subloan #getSubloans.loan_number#
					</div>
					<table>
						<tr>
							<th style="width: 25%;">MCZ Number</th>
							<th style="width: 50%;">Taxon, Locality</th>
							<th style="width: 25%;">Specimen Count</th>
						</tr>
						<cfset totalSpecimens = 0>
						<cfset totalLotCount = 0>
						<cfloop query="getLoanItems">
							<tr>
								<td style="width: 25%; vertical-align: top;">
									#institution_acronym#:#collection_cde#:#cat_num#
									<cfif getLoan.loan_status EQ "closed">#reconciled_date#</cfif>
								</td>
								<td style="width: 50%; vertical-align: top;">
									<div>
										<em>#scientific_name#</em>
										<cfif Len(type_status) GT 0><BR></cfif><strong>#type_status#</strong><BR>
										#higher_geog#
										<cfif FindNoCase('Paleontology', collection) GT 0>
											#chronostrat##lithostrat#
										</cfif>
										<cfif Len(spec_locality) GT 0><BR>#spec_locality#</cfif>
										<cfif Len(collectors) GT 0><BR>#collectors#</cfif>
										<cfif Len(loan_item_remarks) GT 0><BR>Loan Comments: #loan_item_remarks#</cfif>
									</div>
								</td>
								<td style="width: 25%; vertical-align: top;">
									#lot_count# #part_modifier# #part_name#
									<cfif len(preserve_method) GT 0>(#preserve_method#)</cfif>
									<cfif getRestrictions.recordcount GT 0>
										<cfquery name="getSpecificRestrictions" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
											select permit.permit_num
											from loan_item li 
												join specimen_part sp on li.collection_object_id = sp.collection_object_id
												join cataloged_item ci on sp.derived_from_cat_item = ci.collection_object_id
												join accn on ci.accn_id = accn.transaction_id
												join permit_trans on accn.transaction_id = permit_trans.transaction_id
												join permit on permit_trans.permit_id = permit.permit_id
											where li.transaction_id = <cfqueryparam CFSQLType="CF_SQL_DECIMAL" value="#transaction_id#">
												and ci.collection_object_id  = <cfqueryparam CFSQLType="CF_SQL_DECIMAL" value="#getLoanItems.collection_object_id#">
												and permit.restriction_summary is not null
										</cfquery>
										<cfif getSpecificRestrictions.recordcount GT 0>
											<div>
												<strong>Use Restricted By:</strong>
												<cfloop query="getSpecificRestrictions">
													#getSpecificRestrictions.permit_num#
												</cfloop>
											</div>
										</cfif>
									</cfif>
								</td>
							</div>
							<cfset totalSpecimens = totalSpecimens + 1>
							<cfset totalLotCount = totalLotCount + lot_count>
						</cfloop>
					</table>
					<div>
						Subloan includes #TotalSpecimens# specimens in #TotalLotCount# lots.
						<cfset masterTotal = masterTotal + TotalSpecimens>
						<cfset masterLotTotal = masterLotTotal + TotalLotCount>
					</div>
				</cfloop>
				<div>
					Total of #masterTotal# specimens in #masterLotTotal# lots..
				</div>
				<cfset transaction_id = master_transaction_id >
			</cfelse>
				<table>
					<tr>
						<th style="width: 25%;">MCZ Number</th>
						<th style="width: 50%;">Taxon, Locality</th>
						<th style="width: 25%;">Specimen Count</th>
					</tr>
					<cfset totalSpecimens = 0>
					<cfset totalLotCount = 0>
					<cfloop query="getLoanItems">
						<tr>
							<td style="width: 25%; vertical-align: top;">
								#institution_acronym#:#collection_cde#:#cat_num#
								<cfif getLoan.loan_status EQ "closed">#reconciled_date#</cfif>
							</td>
							<td style="width: 50%; vertical-align: top;">
								<div>
									<em>#scientific_name#</em>
									<cfif Len(type_status) GT 0><BR></cfif><strong>#type_status#</strong><BR>
									#higher_geog#
									<cfif FindNoCase('Paleontology', collection) GT 0>
										#chronostrat##lithostrat#
									</cfif>
									<cfif Len(spec_locality) GT 0><BR>#spec_locality#</cfif>
									<cfif Len(collectors) GT 0><BR>#collectors#</cfif>
									<cfif Len(loan_item_remarks) GT 0><BR>Loan Comments: #loan_item_remarks#</cfif>
								</div>
							</td>
							<td style="width: 25%; vertical-align: top;">
								#lot_count# #part_modifier# #part_name#
								<cfif len(preserve_method) GT 0>(#preserve_method#)</cfif>
								<cfif getRestrictions.recordcount GT 0>
									<cfquery name="getSpecificRestrictions" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
										select permit.permit_num
										from loan_item li 
											join specimen_part sp on li.collection_object_id = sp.collection_object_id
											join cataloged_item ci on sp.derived_from_cat_item = ci.collection_object_id
											join accn on ci.accn_id = accn.transaction_id
											join permit_trans on accn.transaction_id = permit_trans.transaction_id
											join permit on permit_trans.permit_id = permit.permit_id
										where li.transaction_id = <cfqueryparam CFSQLType="CF_SQL_DECIMAL" value="#transaction_id#">
											and ci.collection_object_id  = <cfqueryparam CFSQLType="CF_SQL_DECIMAL" value="#getLoanItems.collection_object_id#">
											and permit.restriction_summary is not null
									</cfquery>
									<cfif getSpecificRestrictions.recordcount GT 0>
										<div>
											<strong>Use Restricted By:</strong>
											<cfloop query="getSpecificRestrictions">
												#getSpecificRestrictions.permit_num#
											</cfloop>
										</div>
									</cfif>
								</cfif>
							</td>
						</div>
						<cfset totalSpecimens = totalSpecimens + 1>
						<cfset totalLotCount = totalLotCount + lot_count>
					</cfloop>
				</table>
				<div>
					Total of #TotalSpecimens# specimens in #TotalLotCount# lots.
				</div>
			</cfif>
		</cfdocumentsection>

		<cfif getShipments.recordcount EQ 1>
			<cfdocumentsection name="Shipping Labels">
			<cfloop query="getShipments">
				<table>
					<tr>
						<td>
							<strong>From:</strong>
							<br> 
							#replace(fromAddress,chr(10),"<br>","all")# 
						</td>
					</tr>
						<td>
							<strong>To:</strong>
							<br>
							#replace(toAddress,chr(10),"<br>","all")#
						</td>
					</tr>
				</table>
			</cfloop>
			</cfdocumentsection>
		</cfif>
	</cfoutput>
</cfdocument>
