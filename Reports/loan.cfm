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
<cfset top_loan_type = getLoan.loan_type>
<cfset top_loan_status = getLoan.loan_status>
<cfset top_loan_number = getLoan.loan_number>
<cfif getLoan.loan_type EQ "exhibition-master">
	<!--- Special handling --->
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
	<cfquery name="getSubloanCounts" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			SELECT sum(lot_count) lot_ct, count(coll_object.collection_object_id) item_ct
			FROM 
				loan_item 
				JOIN coll_object on loan_item.collection_object_id = coll_object.collection_object_id
			WHERE transaction_id in (
				SELECT related_transaction_id 
				FROM loan_relations 
				WHERE transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
			)
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
	SELECT DISTINCT 
		restriction_summary, permit_id, permit_num, source, permit_title, specific_type
	FROM (
	select permit.restriction_summary, permit.permit_id, permit.permit_num, 'accession' as source, permit_title, specific_type
	from loan_item li 
		join specimen_part sp on li.collection_object_id = sp.collection_object_id
		join cataloged_item ci on sp.derived_from_cat_item = ci.collection_object_id
		join accn on ci.accn_id = accn.transaction_id
		join permit_trans on accn.transaction_id = permit_trans.transaction_id
		join permit on permit_trans.permit_id = permit.permit_id
	where li.transaction_id = <cfqueryparam CFSQLType="CF_SQL_DECIMAL" value="#transaction_id#">
		and permit.restriction_summary is not null
	UNION
	select permit.restriction_summary, permit.permit_id, permit.permit_num, 'loan shipment' as source, permit_title, specific_type
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
		
		<!--- Footer, last page is shipping labels, not included in page count --->
		<cfdocumentitem type="footer" evalAtPrint="true">
			<div style="text-align: center; font-size: x-small;">
		   <cfif cfdocument.currentPageNumber eq cfdocument.totalPageCount>
        		Shipping Labels Generated: #dateFormat(now(),'yyyy-mm-dd')#
    		<cfelse>
				PDF Generated: #dateFormat(now(),'yyyy-mm-dd')#  Page #cfdocument.currentPageNumber# of #cfdocument.totalPageCount - 1#
    		</cfif>
			</div>
		</cfdocumentitem>

		<cfdocumentsection name="Loan Header">
			<div style="text-align: center; font-size: 1.2em;">
				<strong>Invoice of Specimens</strong>
			</div>
			<div style="text-align: center; font-size: 1em;">
				<!--- TODO: Comment, inconsistent use of Department and Collection, should list Department, except for Cryo, fix in custom tag? --->
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
							<cfif getLoan.loan_type EQ "exhibition-master">
								<li style="list-style-type: none"><strong>Number of Specimens:</strong> #getSubloanCounts.item_ct#</strong>
								<li style="list-style-type: none"><strong>Number of Lots:</strong> #getSubloanCounts.lot_ct#</strong>
							<cfelse>
								<li style="list-style-type: none"><strong>Number of Specimens:</strong> #num_specimens#</strong>
								<li style="list-style-type: none"><strong>Number of Lots:</strong> #num_lots#</strong>
							</cfif>
							<cfif len(foruse_by_name) GT 0>
								<li style="list-style-type: none"><strong>For Use By:</strong> #foruse_by_name#</strong>
							</cfif>
						</ul>
					</td>
				</tr>
			</table>
			<div style="font-size: small; margin-left: 4px;">
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
				<div style="margin 0px; border: 1px black;">
					<h2 style="font-size: small;">Terms and Conditions</h2>
					<ol style="margin-left: 0px;">
						<li>Specimens are loaned to bona fide institutions, not to individuals, for non-commercial use (e.g., scientific research, education, exhibition). </li>
						<li> Specimens are for sole use of the recipient for the specific purposes outlined in the loan request. Prior written permission from the MCZ is needed for any activities not specified in the loan request.</li>
						<li>Loans may not be transferred to other institutions without express written permission.
						<li>Borrowing institutions must demonstrate the ability to properly unpack, care for, use, and return the specimens according to best practices of collection curation.
						<li>Specimens must be returned by the date stated on the invoice unless a loan renewal is granted in writing.</li>
						<li>No destructive sampling or invasive procedures may be conducted on a loaned specimen without prior written permission.</li>
						<li>The recipient will return any unused material or derivatives (e.g., tissue, DNA/RNA extract) to the MCZ.</li>
						<li>The recipient will provide the MCZ with reprints of any resulting publications and accession numbers for genetic data in public repositories.</li>
						<li>The recipient will provide copies of any digital media files and all associated metadata. All resulting media is © President and Fellows of Harvard College.</li>
						<li>Loans may be recalled at any time at the discretion of the MCZ.</li>
						<cfif getRestrictions.recordcount GT 0>
							<li>Additional Restrictions on use from original permits apply, see instructions.</li>
						</cfif>
					</ol>
				</div>
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
			<cfset master_transaction_id = transaction_id>
			<cfloop query="getSubloans">
				<cfset transaction_id = getSubloans.transaction_id>
				<cf_getLoanFormInfo transaction_id="#getSubloans.transaction_id#">
				<cfquery name="getSubloan" dbtype="query">
					select * from getLoanMCZ
				</cfquery>
				<cfdocumentsection name="Subloan Header">
					<div style="text-align: center; font-size: 1em;">
						<strong> Exhibition Subloan #loan_number# </strong>
					</div>
					<div style="text-align: center; font-size: 1em;">
						<!--- TODO: Comment, inconsistent use of Department and Collection, should list Department, except for Cryo, fix in custom tag? --->
						#getSubloan.collection#
					</div>
					<div style="text-align: center; font-size; 1em;">
						Museum of Comparative Zoology, Harvard University
					</div>
					<table style="font-size: small; padding: 0px; margin: 0px;">
						<tr>
							<td style="width: 55%; vertical-align: top;">
								<div>
									This document acknowledges the Loan of specimens <strong>To:</strong> #getSubloan.recipientInstitutionName#.
								</div>
								<div>			
									<strong>Borrower:</strong> #getSubloan.recAgentName#
								</div>
								<div>
									<strong>Shipped To:</strong><br>
									#replace(replace(getSubloan.shipped_to_address,chr(10),"<br>","all"),"&","&amp;","all")#
									#getSubloan.outside_email_address#<br>#getSubloan.outside_phone_number#
								</div>
							</td>
							<td style="width: 45%; vertical-align: top;">
								<ul style="text-align: left; list-style: none;">
									<li style="list-style-type: none"><strong>Status:</strong> #getSubloan.loan_status#</strong>
									<cfif getSubloan.loan_status NEQ top_loan_status >
										<li style="list-style-type: none"><strong>#top_loan_number# Status:</strong> #top_loan_status#</strong>
									</cfif>
									<li style="list-style-type: none"><strong>Category:</strong> #getSubloan.loan_type#</strong>
									<li style="list-style-type: none"><strong>Loan Number:</strong> #getSubloan.loan_number#</strong>
									<cfif getSubloan.loan_type EQ "exhibition-subloan">
										<li style="list-style-type: none"><strong>Subloan of:</strong> #top_loan_number#</strong>
									</cfif>
									<li style="list-style-type: none"><strong>Loan Date:</strong> #getSubloan.trans_date#</strong>
									<li style="list-style-type: none"><strong>Approved By:</strong> #getSubloan.authAgentName#</strong>
									<li style="list-style-type: none"><strong>Packed By:</strong> #getSubloan.processed_by_name#</strong>
									<li style="list-style-type: none"><strong>Method of Shipment:</strong> #getSubloan.shipped_carrier_method#</strong>
									<li style="list-style-type: none"><strong>Number of Packages:</strong> #getSubloan.no_of_packages#</strong>
									<li style="list-style-type: none"><strong>Number of Specimens:</strong> #getSubloan.num_specimens#</strong>
									<li style="list-style-type: none"><strong>Number of Lots:</strong> #getSubloan.num_lots#</strong>
									<cfif len(getSubloan.foruse_by_name) GT 0>
										<li style="list-style-type: none"><strong>For Use By:</strong> #getSubloan.foruse_by_name#</strong>
									</cfif>
								</ul>
							</td>
						</tr>
					</table>
					<div style="font-size: small; margin-left: 4px;">
						<div>
							<strong>Nature of Material:</strong> #getSubloan.nature_of_material#
						</div>
						<cfif len(getSubloan.loan_description) GT 0>
							<div>
								<strong>Description:</strong> #getSubloan.loan_description#
							</div>
						</cfif>
						<div>
							<strong>Additional Instructions:</strong> #getSubloan.loan_instructions#
						</div>
						<div style="margin 0px; border: 1px black;">
							<h2 style="font-size: small;">All Terms and Conditions From Loan #top_loan_number# Apply.</h2>
						</div>
					</div>
					<table style="font-size: small;">
						<tr>
							<td style="width: 50%; vertical-align: top;">
								<h2 style="font-size: small;">UPON RECEIPT, SIGN AND RETURN ONE COPY TO:</h2>
								<div>
									#replace(getSubloan.shipped_from_address,chr(10),"<br>","all")# 
									<cfif loan_type EQ "exhibition">
										#getSubloan.addInHouseContactPhEmail#
									<cfelse>
										#getSubloan.inside_phone_number#
										<br>
										#getSubloan.inside_email_address#
									</cfif>
								</div>
							</td>
							<td style="width: 50%; vertical-align: top;">
								<div>Borrower (noted above) acknowledges reading and agreeing to the terms and conditions noted in this document.<div>
								<div><strong>Expected return date: #dateformat(getSubloan.return_due_date,"dd mmmm yyyy")#</strong></div>
								<br>
								<div style="text-align: right;">Borrower&##39;s Signature: ___________________________</div>
								<div style="text-align: right;">#getSubloan.recAgentName#</div>
							</td>
						</tr>
					</table>
				</cfdocumentsection>
			</cfloop>
			<cfset transaction_id = master_transaction_id>
		</cfif>

		<!--- TODO: May be desiriable to not include, needs further discussion --->
		<cfif getRestrictions.recordcount GT 0>
			<cfdocumentsection name="Additional Restrictions">
				<div style="text-align: center; font-size: 1em;">
					Summary of restrictions imposed by original collecting agreements
				</div>
				<ul>
					<cfloop query="getRestrictions">
						<cfif getRestrictions.source EQ "accession">
							<li>
								<strong>
									#specific_type# #permit_num#
									<cfif len(permit_num) EQ 0>#permit_title#</cfif>
								</strong> 
								#restriction_summary#
							</li>
					<cfelse>
						<li>
							<strong>
								#specific_type# #permit_num#
								<cfif len(permit_num) EQ 0>#permit_title#</cfif>
									Applies to all material in this loan:
							</strong>
							#restriction_summary#
						</li>
					</cfif>
				</cfloop>
			</ul>
			</cfdocumentsection>
		</cfif>

		<cfdocumentsection name="Items In Loan">
			<div style="text-align: center; font-size: 1.1em; margin-bottom: 1em;">
				<strong>Invoice of Specimens</strong>
			</div>
			<div>
				Retain in 70% ethanol unless noted otherwise.
			</div>
			<cfif top_loan_type EQ "exhibition-master">
				<cfset master_transaction_id = transaction_id>
				<cfset masterTotal = 0>
				<cfset masterLotTotal = 0>
				<cfloop query="getSubloans">
					<cfset transaction_id = getSubloans.transaction_id>
					<cf_getLoanFormInfo transaction_id="#getSubloans.transaction_id#">
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
									<cfif top_loan_status EQ "closed">#reconciled_date#</cfif>
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
											SELECT permit.permit_num,
												permit.specific_type,
												permit.permit_title
											FROM loan_item li 
												join specimen_part sp on li.collection_object_id = sp.collection_object_id
												join cataloged_item ci on sp.derived_from_cat_item = ci.collection_object_id
												join accn on ci.accn_id = accn.transaction_id
												join permit_trans on accn.transaction_id = permit_trans.transaction_id
												join permit on permit_trans.permit_id = permit.permit_id
											WHERE li.transaction_id = <cfqueryparam CFSQLType="CF_SQL_DECIMAL" value="#transaction_id#">
												and ci.collection_object_id  = <cfqueryparam CFSQLType="CF_SQL_DECIMAL" value="#getLoanItems.collection_object_id#">
												and permit.restriction_summary is not null
										</cfquery>
										<cfif getSpecificRestrictions.recordcount GT 0>
											<div>
												<strong>Use Restricted By:</strong>
												<cfloop query="getSpecificRestrictions">
													#getSpecificRestrictions.permit_num#
													<cfif len(getSpecificRestrictions.permit_num) EQ 0>
														#getSpecificRestrictions.permit_title#
													</cfif>
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
					<div style="margin-bottom: 2em; border-bottom: 1px black;">
						Subloan includes #TotalSpecimens# specimens in #TotalLotCount# lots.
						<cfset masterTotal = masterTotal + TotalSpecimens>
						<cfset masterLotTotal = masterLotTotal + TotalLotCount>
					</div>
				</cfloop>
				<div>
					<strong>Loan #loan_number# includes a total of #masterTotal# specimens in #masterLotTotal# lots.</strong>
				</div>
				<cfset transaction_id = master_transaction_id >
				<cf_getLoanFormInfo transaction_id="#master_transaction_id#">
			<cfelse>
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
								<cfif top_loan_status EQ "closed">#reconciled_date#</cfif>
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
										SELECT permit.permit_num, permit_title
										FROM loan_item li 
											join specimen_part sp on li.collection_object_id = sp.collection_object_id
											join cataloged_item ci on sp.derived_from_cat_item = ci.collection_object_id
											join accn on ci.accn_id = accn.transaction_id
											join permit_trans on accn.transaction_id = permit_trans.transaction_id
											join permit on permit_trans.permit_id = permit.permit_id
										WHERE li.transaction_id = <cfqueryparam CFSQLType="CF_SQL_DECIMAL" value="#transaction_id#">
											and ci.collection_object_id  = <cfqueryparam CFSQLType="CF_SQL_DECIMAL" value="#getLoanItems.collection_object_id#">
											and permit.restriction_summary is not null
									</cfquery>
									<cfif getSpecificRestrictions.recordcount GT 0>
										<div>
											<strong>Use Restricted By:</strong>
											<cfloop query="getSpecificRestrictions">
												#getSpecificRestrictions.permit_num#
												<cfif len(getSpecificRestrictions.permit_num) EQ 0>
													#getSpecificRestrictions.permit_title#
												</cfif>
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
				<div>
					Shipping Label
				</div>
				<table>
					<tr>
						<td>
							<strong style="font-size: 1.2em;">From:</strong>
							<br> 
							#replace(fromAddress,chr(10),"<br>","all")# 
						</td>
					</tr>
					<tr>
						<td style="border: 1px black;">
							<strong style="font-size: 1.2em;">To:</strong>
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
