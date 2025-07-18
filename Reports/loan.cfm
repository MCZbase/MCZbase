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
<cfif not isDefined("sort")>
	<cfset sort="cat_num">
</cfif>

<cf_rolecheck>
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
<cfset INSTRUCTIONS_LIMIT = 751>
<cfset MASTER_PAGES = 2><!--- header for master exhibtion loan is two pages --->
<cfif getLoan.loan_type EQ "exhibition-master">
	<!--- Special handling --->
	<cfquery name="getSubloans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
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
	<cfquery name="getSubloanCounts" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
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
<cfif isDefined("groupBy") AND groupBy EQ "part">
	<cfquery name="getLoanItems" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		SELECT DISTINCT
			collection.collection AS collection,
			cataloged_item.collection_cde as collection_cde,
			cataloged_item.collection_object_id as collection_object_id,
			collection.institution_acronym as institution_acronym,
			loan_number,
			to_char(loan_item.reconciled_date,'yyyy-mm-dd') reconciled_date,
			MCZBASE.CONCATITEMREMINLOAN(specimen_part.derived_from_cat_item, loan_item.transaction_id) as loan_item_remarks,
			concattransagent(loan.transaction_id, 'received by')  recAgentName,
			cat_num,
			MCZBASE.GET_TYPESTATUS(cataloged_item.collection_object_id) as type_status,
			decode(
				MCZBASE.GET_TYPESTATUSNAME(cataloged_item.collection_object_id,
				MCZBASE.GET_TYPESTATUS(cataloged_item.collection_object_id)), 
				MCZBASE.GET_SCIENTIFIC_NAME(cataloged_item.collection_object_id),
				'', 
				decode(MCZBASE.GET_TYPESTATUSNAME(cataloged_item.collection_object_id,
					MCZBASE.GET_TYPESTATUS(cataloged_item.collection_object_id)),'','',
					' of ' || MCZBASE.GET_TYPESTATUSNAME(cataloged_item.collection_object_id,
					MCZBASE.GET_TYPESTATUS(cataloged_item.collection_object_id))
				)
			) as typestatusname,
		
			MCZBASE.CONCATPARTSINLOAN(specimen_part.derived_from_cat_item, loan_item.transaction_id) as parts,
			MCZBASE.CONCATPARTCTINLOAN(specimen_part.derived_from_cat_item, loan_item.transaction_id) as lot_count,
			MCZBASE.GET_SCIENTIFIC_NAME(cataloged_item.collection_object_id) as scientific_name, 
			spec_locality,
			higher_geog,
			GET_CHRONOSTRATIGRAPHY(locality.locality_id) chronostrat,
			GET_LITHOSTRATIGRAPHY(locality.locality_id) lithostrat,
			HTF.escape_sc(concatColl(cataloged_item.collection_object_id)) as collectors,
			cat_num_prefix,
			cat_num_integer
		FROM loan 
			left join loan_item on loan.transaction_id = loan_item.transaction_id 
			left join specimen_part on loan_item.collection_object_id = specimen_part.collection_object_id 
			left join cataloged_item on specimen_part.derived_from_cat_item = cataloged_item.collection_object_id 
			left join collection on cataloged_item.collection_id = collection.collection_id 
			left join collecting_event on cataloged_item.collecting_event_id = collecting_event.collecting_event_id 
			left join locality on collecting_event.locality_id = locality.locality_id 
			left join geog_auth_rec on locality.geog_auth_rec_id = geog_auth_rec.geog_auth_rec_id 
		WHERE 
			loan.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
		<cfif sort eq "cat_num"> 
			ORDER BY cat_num
		<cfelseif sort eq "cat_num_pre_int"> 
			ORDER BY cat_num_prefix, cat_num_integer
		<cfelseif sort eq "scientific_name"> 
			ORDER BY scientific_name
		</cfif>
	</cfquery>
<cfelse>
	<cfquery name="getLoanItems" dbtype="query">
		SELECT * 
		FROM getLoanItemsMCZ
		<cfif sort eq "cat_num"> 
			ORDER BY cat_num
		<cfelseif sort eq "cat_num_pre_int"> 
			ORDER BY cat_num_prefix, cat_num_integer
		<cfelseif sort eq "scientific_name"> 
			ORDER BY scientific_name
		</cfif>
	</cfquery>
</cfif>
<cfquery name="getHasFluid" dbtype="query">
	select count(*) ct 
	from getLoanItemsMCZ
	where preserve_method like '%thanol%' or preserve_method like '%alcohol%'
</cfquery>
<cfquery name="getRestrictions" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	SELECT DISTINCT 
		restriction_summary, benefits_summary,
		permit_id, permit_num, source, permit_title, specific_type
	FROM (
	select permit.restriction_summary, permit.benefits_summary,
		permit.permit_id, permit.permit_num, 'accession' as source, permit_title, specific_type
	from loan_item li 
		join specimen_part sp on li.collection_object_id = sp.collection_object_id
		join cataloged_item ci on sp.derived_from_cat_item = ci.collection_object_id
		join accn on ci.accn_id = accn.transaction_id
		join permit_trans on accn.transaction_id = permit_trans.transaction_id
		join permit on permit_trans.permit_id = permit.permit_id
	where li.transaction_id = <cfqueryparam CFSQLType="CF_SQL_DECIMAL" value="#transaction_id#">
		and (permit.restriction_summary is not null
		 or permit.benefits_summary is not null)
	UNION
	select permit.restriction_summary, permit.benefits_summary,
		permit.permit_id, permit.permit_num, 'loan shipment' as source, permit_title, specific_type
	from loan
		join shipment on loan.transaction_id = shipment.transaction_id
		join permit_shipment on shipment.shipment_id = permit_shipment.shipment_id
		join permit on permit_shipment.permit_id = permit.permit_id
	where loan.transaction_id = <cfqueryparam CFSQLType="CF_SQL_DECIMAL" value="#transaction_id#">
		and (permit.restriction_summary is not null
		 or permit.benefits_summary is not null)
	)
</cfquery>
<cfquery name="getShipments" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
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
<cfset font = "font: Helvetica, Arial, 'sans-serif'; ">
<cfset font_dq = replace(font,"'",'"')>
<cfdocument format="pdf" saveAsName="MCZ_Loan_#getLoan.loan_number#.pdf" pageType="letter" marginTop="0.6" marginBottom="0.6" marginLeft="0.5" marginRight="0.5" fontEmbed="yes">
	<cfoutput query="getLoan">

		<cfdocumentitem type="header">
			<div style="text-align: center; #font# font-size: small; position: relative; top: 2em;">
				Museum of Comparative Zoology Loan #getLoan.loan_number#
			</div>
		</cfdocumentitem>
		
		<!--- Footer, last page is shipping labels, not included in page count --->
		<cfdocumentitem type="footer" evalAtPrint="true">
			<div style="text-align: center; #font# font-size: x-small;">
		   <cfif cfdocument.currentPageNumber eq cfdocument.totalPageCount>
        		Shipping Labels Generated: #dateFormat(now(),'yyyy-mm-dd')#
    		<cfelse>
				PDF Generated: #dateFormat(now(),'yyyy-mm-dd')#  Page #cfdocument.currentPageNumber# of #cfdocument.totalPageCount - 1#
    		</cfif>
			</div>
		</cfdocumentitem>
	
		<cfif getLoan.loan_type EQ "exhibition-subloan">
			<!--- Header for subloan in isolation is not sufficient to send, must generate paperwork to send from master exhibition loan --->
			<cfquery name="getParent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT loan.transaction_id, loan.loan_number
				FROM loan
					left join loan_relations on loan.transaction_id = loan_relations.transaction_id
				WHERE loan_relations.related_transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
					AND loan_relations.relation_type = 'Subloan'
			</cfquery>
			<cfset master_transaction_id = getParent.transaction_id>
			<cfset parent_loan_number = getParent.loan_number>
			<cf_getLoanFormInfo transaction_id="#transaction_id#">
			<cfquery name="getSubloan" dbtype="query">
				select * from getLoanMCZ
			</cfquery>
			<cfdocumentsection name="Subloan only Header">
				<div style="text-align: center; #font# font-size: 1em;">
					<strong> Exhibition Subloan #loan_number# </strong>
				</div>
				<div style="text-align: center; #font# font-size: 1em;">
					<strong> Parent Exhibtion Loan is: #parent_loan_number# </strong>
				</div>
				<div style="text-align: center; #font# font-size: 1em;">
					#getSubloan.collection#
				</div>
				<div style="text-align: center; #font# font-size: 1em; margin-bottom 1em;">
					Museum of Comparative Zoology, Harvard University
				</div>
				<table style="#font# font-size: small; padding: 0px; margin: 0px;">
					<tr>
						<td style="width: 55%; vertical-align: top;">
							<div>
								This document acknowledges the loan of specimens <strong>To:</strong> #getSubloan.recipientInstitutionName#.
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
						<td style="width: 45%; vertical-align: top; margin-bottom: 1em;">
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
				<div style="#font# font-size: small; margin-left: 4px;">
					<cfif len(getSubloan.nature_of_material) GT 0>
					<div>
						<strong>Nature of Material:</strong>
						<cfif len(getSubloan.nature_of_material) LT INSTRUCTIONS_LIMIT>
							#getSubloan.nature_of_material#
						<cfelse>
							#trim(left(getSubloan.nature_of_material,(INSTRUCTIONS_LIMIT - 26)))#... 
							<cfif getLoan.loan_type EQ "exhibition-master" AND getSubloans.recordcount GT 0>
								<strong>Continued on Page #getSubloans.recordcount + MASTER_PAGES#.</strong>
							<cfelse>
								<strong>Continued on Next Page.</strong>
							</cfif>
						</cfif>
					</div>
					</cfif>
					<cfif len(getSubloan.loan_description) GT 0>
						<div>
							<strong>Description:</strong>
							<cfif len(getSubloan.loan_description) LT INSTRUCTIONS_LIMIT>
								#getSubloan.loan_description#
							<cfelse>
								#trim(left(getSubloan.loan_description,(INSTRUCTIONS_LIMIT - 26)))#... 
								<cfif getLoan.loan_type EQ "exhibition-master" AND getSubloans.recordcount GT 0>
									<strong>Continued on Page #getSubloans.recordcount + MASTER_PAGES#.</strong>
								<cfelse>
									<strong>Continued on Next Page.</strong>
								</cfif>
							</cfif>
						</div>
					</cfif>
					<cfif len(getSubloan.loan_instructions) GT 0>
						<div>
							<strong>Additional Instructions:</strong> 
							<cfif len(getSubloan.loan_instructions) LT INSTRUCTIONS_LIMIT>
								#getSubloan.loan_instructions#
							<cfelse>
								#trim(left(getSubloan.loan_instructions,(INSTRUCTIONS_LIMIT - 26)))#... 
								<cfif getLoan.loan_type EQ "exhibition-master" AND getSubloans.recordcount GT 0>
									<strong>Continued on Page #getSubloans.recordcount + MASTER_PAGES#.</strong>
								<cfelse>
									<strong>Continued on Next Page.</strong>
								</cfif>
							</cfif>
						</div>
					</cfif>
					<br>
					<div style="margin: 0px; border: 1px solid black;">
						<div style="#font# font-size: small;">All Terms and Conditions From Loan #top_loan_number# Apply.</div>
					</div>
					<br>
				</div>
				<table style="#font# font-size: small;">
					<tr>
						<td style="width: 50%; vertical-align: top;">
							<div style="#font# font-size: small;">UPON RECEIPT, SIGN AND RETURN ONE COPY TO:</div>
							<div>
								#replace(getSubloan.shipped_from_address,chr(10),"<br>","all")# 
								<cfif getSubloan.loan_type EQ "exhibition">
									#getSubloan.addInHouseContactPhEmail#
								<cfelse>
									#getSubloan.inside_phone_number#
									<br>
									#getSubloan.inside_email_address#
								</cfif>
							</div>
						</td>
						<td style="width: 50%; vertical-align: top;">
							<strong>Paperwork to ship with loan and to sign must be printed from Parent Exhibtion Loan: #parent_loan_number#</strong>
							<div><strong>Expected return date: #dateformat(getSubloan.return_due_date,"dd mmmm yyyy")#</strong></div>
							<br>
							<div style="text-align: right;">Borrower</div>
							<div style="text-align: right;">#getSubloan.recAgentName#</div>
						</td>
					</tr>
				</table>
			</cfdocumentsection>
		<cfelseif getLoan.loan_type EQ "exhibition-master">
			<!--- Special header for exhibition-master loans. --->
			<cfdocumentsection name="Exhibition Loan Agreement Header">
				<div style="text-align: center; #font# font-size: 1em;">
					<strong>Museum of Comparative Zoology, Harvard University</strong>
				</div>
				<div style="text-align: center; #font# font-size: 1em;">
					26 Oxford Street<br>
					Harvard University<br>
					Cambridge, MA 02138
				</div>
				<div style="width: 100%; #font# font-size: 1em; border-bottom: 2px solid black;">
					<span style="text-align: center;"><strong>Exhibition Loan Agreement</strong></span>
					<span style="text-align: right;">No. <strong>#getLoan.loan_number#</strong></span>
				</div>
				<table style="#font# font-size: small; padding: 0px; margin: 0px;">
					<tr>
						<td style="width: 40%; vertical-align: top;">
							<strong>MCZ DEPT/LOAN ## (number of specimens)</strong>
						</td>
						<td style="width: 60%; vertical-align: top;">
							<cfloop query="getSubloans">
								<div style="#font# font-size: 1em;">
									<cfquery name="getSubloanCount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
										SELECT sum(lot_count) lot_ct, count(coll_object.collection_object_id) item_ct, collection
										FROM 
											loan_item 
											JOIN coll_object on loan_item.collection_object_id = coll_object.collection_object_id
											JOIN trans on loan_item.transaction_id = trans.transaction_id
											JOIN collection on trans.collection_id = collection.collection_id
										WHERE loan_item.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getSubloans.transaction_id#">
										GROUP BY collection
									</cfquery>
									<cfloop query="getSubloanCount">
										#getSubloanCount.collection# #getSubloans.loan_number#
										<cfif getSubloanCount.item_ct EQ 1><cfset plural = ""><cfelse><cfset plural = "s"></cfif>
										(#getSubloanCount.item_ct# specimen#plural#)
									</cfloop>
								</div>
							</cfloop>
							<!--- div style="#font# font-size: 1em;">
								#getLoan.loan_description#
							</div --->
						</td>
					</tr>
					<tr>
						<td style="width: 40%; vertical-align: top;">
							<strong>MCZ LOAN CONTACT INFO:</strong>
						</td>
						<td style="width: 60%; vertical-align: top;">
									#getLoan.internalContactName# / #getLoan.inside_phone_number# / #getLoan.inside_email_address#
						</td>
					</tr>
					<tr>
						<td style="width: 40%; vertical-align: top;">
							<strong>BORROWING INSTITUTION:</strong>
						</td>
						<td style="width: 60%; vertical-align: top;">
									#getLoan.recipientInstitutionName#
						</td>
					</tr>
					<tr>
						<td style="width: 40%; vertical-align: top;">
							<strong>ADDRESS:</strong>
						</td>
						<td style="width: 60%; vertical-align: top;">
									#getLoan.shipped_to_address#
						</td>
					</tr>
					<tr>
						<td style="width: 40%; vertical-align: top;">
							<strong>CONTACT INFO:</strong>
						</td>
						<td style="width: 60%; vertical-align: top;">
									#getLoan.outside_contact_name# / #getLoan.outside_phone_number# / #getLoan.outside_email_address#
						</td>
					</tr>
					<tr>
						<td style="width: 40%; vertical-align: top;">
							<strong>EXHIBIT PURPOSE, VENUE, TITLE &amp; DATES:</strong>
						</td>
						<td style="width: 60%; vertical-align: top;">
									#getLoan.nature_of_material#
						</td>
					</tr>
					<tr>
						<td style="width: 40%; vertical-align: top;">
							<strong>LOAN PERIOD:</strong>
						</td>
						<td style="width: 60%; vertical-align: top;">
									#getLoan.trans_date# to #getLoan.return_due_date#
						</td>
					</tr>
				</table>
				<div style="text-align: left; #font# font-size: small; border-bottom solid black 1px; width: 100%;">
					Departmental Loan document(s) include an itemized list of the loaned object(s), relevant associated data, and object condition report(s).
				</div>
				<div style="text-align: left; #font# font-size: small; margin-top: 1em;">
					<strong>SPECIAL HANDLING INSTRUCTIONS/ REQUIREMENTS:</strong>
					<p>
						See Conditions on next page and instructions in Departmental Loan document(s).
					</p>
					<cfif len(getLoan.loan_instructions) GT 0>
						<p>
							#getLoan.loan_instructions#
						</p>
					</cfif>
				</div>
				<div style="text-align: left; #font# font-size: small;">
					<strong>INSURANCE:</strong>
					<p>Insurance Value: #getLoan.insurance_value#</p>
					<p>Insurance Maintained By: #getLoan.insurance_maintained_by#</p>
				</div>
				<div style="text-align: left; #font# font-size: small; margin-bottom: 1em;">
					<strong>CREDIT LINE FOR EXHIBITION LABEL/CATALOG/PROMOTION:</strong>
					<p>Museum of Comparative Zoology, President and Fellows of Harvard College</p>
				</div>
				<div style="text-align: left; #font# font-size: small; border-bottom: solid black 1px; width: 100%;">
					If the Borrower&##39;s loan agreement is signed by the Museum of Comparative Zoology, conditions of the Museum of
					Comparative Zoology&##39;s loan agreement will supersede inconsistent conditions and augment other conditions of the Borrower&##39;s
					loan agreement. The MCZ loan agreement will be governed by and construed according to the laws of the Commonwealth of Massachusetts.
				</div>
				<div style="text-align: left; #font# font-size: small; margin-top: 1px;">
					<p>The Borrower acknowledges reading and agreeing to the conditions listed on all pages of this document.</p>
					<p>Signature of Borrowing Institution: _____________________________________________________</p>
					<p>Title: ______________________________________________ Date: _________________________</p>
					<p>MCZ Signature: ____________________________________________________________________</p>
					<p>Title: ______________________________________________ Date: _________________________</p>
					<p>Please return all copies to MCZ Collections Operations, Museum of Comparative Zoology, Harvard University,
					26 Oxford Street, Cambridge, MA 02138. A signed copy will be returned for your records.</p>
				</div>
			</cfdocumentsection>
			<cfdocumentsection name="Exhibition Loan Conditions">
				<div style="text-align: center; #font# font-size: x-small;">
					<strong>CONDITIONS</strong>
				</div>
				<div style="text-align: left;#font# font-size: x-small;">
					<strong>1. USE</strong>
					<p>Specimens are loaned to bona fide institutions for non-commercial use (e.g., education, exhibition). 
						Loans may not be transferred to other institutions without express written permission. 
					</p>
					<strong>2. TRANSPORTATION</strong>
					<p>The Museum of Comparative Zoology (MCZ) will determine the appropriate means 
						of transportation of the loan material and will approve in writing all
						transportation arrangements. The Borrowing Institution agrees to cover 
						all shipping costs, including courier fee, courier travel, and courier per diem to
						and from the MCZ.
					</p>
					<strong>3. PACKING</strong>
					<p>The MCZ will determine the appropriate means of packing the loan material 
						and will approve in writing all crating and packing arrangements. The Borrowing 
						Institution agrees to cover all crating and packing costs.
					</p>
					<strong>4. INSURANCE</strong>
					<p>If insurance is arranged by the Borrowing Institution, coverage will be under
						an All Risk fine arts "wall to wall" policy from the time that the loan object(s)
						leaves the MCZ, until the object(s) is returned to the MCZ and the final condition reports are
						completed. Coverage will include all risk of physical damage or loss
						including, but not limited to, loss or damage from earthquakes, floods,
						strikes, riots, or civil commotion. The loan object(s) will be insured at the
						value(s) assigned by the MCZ in this agreement. The Borrowing Institution&##39;s policy 
						will name "President and Fellows of Harvard College" as additional insured and will waive
						subrogation rights against Harvard University. A Certificate of Insurance
						evidencing such coverage must be delivered to the MCZ before shipment to the 
						Borrowing Institution occurs.  The Borrowing Institution agrees to cover any 
						deductible under its policy. If the MCZ carries insurance under its policy, the
						Borrowing Institution will be responsible for the cost of the premium while
						the loan object(s) is in transit and on location.
					</p>
					<strong>5. LOAN RETURN, WITHDRAWAL OF OBJECTS </strong>
					<p>Specimens must be returned by the date stated on the invoice unless a loan renewal 
						is granted in writing. Loans are granted for a period of up to one year and 
						may be renewed up to four times in one-year increments. Loans that have been 
						open for five years must be returned to the MCZ. A new loan request can then 
						be submitted for consideration.  The MCZ reserves the right to withdraw any
						items whose condition has deteriorated or may deteriorate due to continued
						travel, or whose security appears to be threatened, or when other urgent
						reasons necessitate withdrawal.
					</p>
					<strong>6. PROCEDURE IN EVENT OF MISHAP </strong>
					<p>In the event that a loan item is damaged, destroyed, lost or stolen, the
						Borrowing Institution shall give the Departmental contact at the MCZ 
						immediate telephone notice, followed by written
						confirmation. The report of damage or loss should provide a description of
						the extent and circumstances surrounding the mishap. No repairs or other
						actions may be taken on the object(s) by the Borrowing Institution without
						instruction in writing from the MCZ.
					</p>
					<strong>7. PUBLICITY AND CREDITS </strong>
					<p>The credit line as shown on the first page of this form will be used in all printed
						material (including web) related to the loan object(s).  One copy of any publication, 
						catalog, or publicity material must be sent to the Departmental contact at the MCZ.
					</p>
					<strong>8. PHOTOGRAPHY </strong>
					<p>All photographs of MCZ items to be used in
						exhibition catalog, brochures, publicity releases, and the like, either will be
						taken by the MCZ or, if taken by another photographer, must be approved in writing 
						by the MCZ. Copyright to any photograph of MCZ object(s), regardless of
						the photographer and the intended use, is retained by the President and
						Fellows of Harvard College, and a copy of any photograph must be sent
						directly to the MCZ Departmental contact if not taken by the MCZ. Use of the 
						photograph in any publication (including web) requires prior permission by the MCZ. All
						permissions are for one time only.
					</p>
					<strong>9. GENERAL CARE AND HANDLING </strong>
					<p>Borrowing institutions must demonstrate the ability to properly unpack, 
						care for, use, and return the specimens according to best practices. 
						The Borrowing Institution will exercise the same care and handling of the
						loan item(s) as it does in the safekeeping of comparable property of its own.
						Each object shall remain in the same condition in which it was received.
						The Borrowing Institution agrees to follow all special handling, installation,
						and packing instructions provided on the first page of this document, and
						detailed in the correspondence and the Loan document from
						the MCZ to the Borrowing Institution.  Upon arrival, all travel containers 
						must be equilibrated to the environment for 24-48 hours before unpacked.
						No restoration, repair, cleaning, or fumigation of loan objects may be
						performed by the borrower without instruction in writing from the MCZ. 
						Other organic objects stored or exhibited with those from the MCZ must 
						be free of infestation.
					</p>
					<strong>10. CONDITION REPORT </strong>
					<p>The MCZ will provide a detailed condition
						report of the loan item(s). The Borrowing Institution will review this condition
						report against the loan item(s) at the time of its arrival and departure.
					</p>
					<strong>11. EXHIBITION DESIGN AND INSTALLATION </strong>
					<p>The Borrowing Institution agrees to comply with all requirements detailed on
						the first page of this document, as well as those described in correspondence
						and the Loan document from the MCZ to the Borrowing Institution.
						Mounting fixtures must be padded at contact points with the loan item(s).
					</p>
					<strong>12. LOAN FEES </strong>
					<p>The Borrowing Institution agrees to pay administrative loan fees,
						conservation, mount fabrication costs, courier fee, courier travel, and
						courier per diem as detailed in correspondence and the Loan document 
						from the MCZ to the Borrowing Institution.
					</p>
					<strong>13. GOVERNING LAW </strong>
					<p>This agreement shall be governed by and construed in accordance with the laws 
						of the Commonwealth of Massachusetts.
					</p>
					<strong>14. NON-ASSIGNABILITY AND BINDING EFFECT</strong>
					<p>Neither party&##39;s rights nor obligation hereunder may be assigned except with
						the other&##39;s written consent. Subject to the foregoing, this agreement shall
						be binding on and inure to the benefit of the parties and their successors
						and assigns.
					</p>
				</div>
			</cfdocumentsection>
		<cfelse>
			<!--- Normal invoice header for regular loans and exhibition-master loans. --->
			<cfdocumentsection name="Loan Header">
				<div style="text-align: center; #font# font-size: 1em; padding-top: 0px;">
					<strong>Invoice of Specimens</strong>
				</div>
					
				<div style="text-align: center; #font# font-size: 1em;">
					#getLoan.collection#
				</div>
				<div style="text-align: center; #font# font-size: 1em;">
					Museum of Comparative Zoology, Harvard University
				</div>
				<table style="#font# font-size: small; padding: 0px; margin: 0px;">
					<tr>
						<td style="width: 55%; vertical-align: top;">
							<div>
								This document acknowledges the loan of specimens <strong>To:</strong> #getLoan.recipientInstitutionName#.
							</div>
							<div>
								<strong>Borrower:</strong> #recAgentName#
							</div>
							<cfif len(outside_email_address) GT 0>
								<div>
									<strong>Contact Email:</strong> #outside_email_address#
								</div>
							</cfif>
							<cfif len(outside_phone_number) GT 0>
								<div>
									<strong>Contact Phone:</strong> #outside_phone_number#
								</div>
							</cfif>
							<div>
								<strong>Shipped To:</strong><br>
								#replace(replace(shipped_to_address,chr(10),"<br>","all"),"&","&amp;","all")#
							</div>
						</td>
						<td style="width: 45%; vertical-align: top;">
							<ul style="text-align: left; list-style: none;">
								<cfif NOT (loan_status EQ "open" OR loan_status EQ "in process") >
									<li style="list-style-type: none"><strong>Status:</strong> #loan_status#</strong>
								</cfif>
								<cfif getLoan.loan_type EQ "exhibition-master">
									<li style="list-style-type: none"><strong>Category:</strong> Exhibition Loan</strong>
								<cfelse>
									<li style="list-style-type: none"><strong>Category:</strong> #getLoan.loan_type#</strong>
								</cfif>
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
				<div style="#font# font-size: small; margin-left: 4px;">
					<cfif len(nature_of_material) GT 0>
						<div>
							<strong>Nature of Material:</strong>
							<cfif len(nature_of_material) LT INSTRUCTIONS_LIMIT>
								#nature_of_material#
							<cfelse>
								#trim(left(nature_of_material,(INSTRUCTIONS_LIMIT - 26)))#... 
								<cfif getLoan.loan_type EQ "exhibition-master" AND getSubloans.recordcount GT 0>
									<strong>Continued on Page #getSubloans.recordcount + MASTER_PAGES#.</strong>
								<cfelse>
									<strong>Continued on Next Page.</strong>
								</cfif>
							</cfif>
						</div>
					</cfif>
					<cfif len(loan_description) GT 0>
						<div>
							<strong>Description:</strong>
							<cfif len(loan_description) LT INSTRUCTIONS_LIMIT>
								#loan_description#
							<cfelse>
								#trim(left(loan_description,(INSTRUCTIONS_LIMIT - 26)))#... 
								<cfif getLoan.loan_type EQ "exhibition-master" AND getSubloans.recordcount GT 0>
									<strong>Continued on Page #getSubloans.recordcount + MASTER_PAGES#.</strong>
								<cfelse>
									<strong>Continued on Next Page.</strong>
								</cfif>
							</cfif>
						</div>
					</cfif>
					<cfif len(loan_instructions) GT 0>
						<div>
							<strong>Instructions:</strong> 
							<cfif len(loan_instructions) LT INSTRUCTIONS_LIMIT>
								#loan_instructions#
							<cfelse>
								#trim(left(loan_instructions,(INSTRUCTIONS_LIMIT - 26)))#... 
								<cfif getLoan.loan_type EQ "exhibition-master" AND getSubloans.recordcount GT 0>
									<strong>Continued on Page #getSubloans.recordcount + MASTER_PAGES#.</strong>
								<cfelse>
									<strong>Continued on Next Page.</strong>
								</cfif>
							</cfif>
						</div>
					</cfif>
					<div style="margin: 0px; border: 1px solid black; ">
						<h2 style="#font# font-size: small; margin-top: 2px;">Terms and Conditions</h2>
						<ol style="margin-left: 2em; #font# font-size: x-small;">
							<li>Specimens are loaned to bona fide institutions, not to individuals, for non-commercial use (e.g., scientific research, education, exhibition).</li>
							<li>Specimens are for sole use of the recipient for the specific purposes outlined in the loan request. Prior written permission from the MCZ is needed for any activities not specified in the loan request.</li>
							<li>Loans may not be transferred to other institutions without express written permission.</li>
							<li>Borrowing institutions must demonstrate the ability to properly unpack, care for, use, and return the specimens according to best practices of collection curation.</li>
							<li>Specimens must be returned by the date stated on the invoice unless a loan renewal is granted in writing.</li>
							<li>No destructive sampling or invasive procedures may be conducted on a loaned specimen without prior written permission.</li>
							<li>The recipient will return any unused material or derivatives (e.g., tissue, DNA/RNA extract) to the MCZ.</li>
							<li>The recipient will provide the MCZ with reprints of any resulting publications and accession numbers for genetic data in public repositories.</li>
							<li>The recipient will provide copies of any digital media files and all associated metadata. All resulting media is ©President and Fellows of Harvard College.</li>
							<li>Loans are granted for a period of up to one year and may be renewed up to four times in one-year increments.  Loans that have been open for five years must be returned to the MCZ. A new loan request can then be submitted for consideration. Loans may be recalled at any time at the discretion of the MCZ.</li>
							<cfif getRestrictions.recordcount GT 0>
								<li>Additional Restrictions on use from original permits apply, a summary of these is provided below.</li>
							</cfif>
						</ol>
					</div>
				</div>
				<table style="#font# font-size: small;">
					<tr>
						<td style="width: 50%; vertical-align: top;">
							<div style="#font# font-size: small;">UPON RECEIPT, SIGN AND RETURN ONE COPY TO:</div>
							<div style="border: 1px solid black;">
								#replace(shipped_from_address,chr(10),"<br>","all")#
								<div><strong>MCZ Contact:</strong>
									<cfif loan_type EQ "exhibition">
										#addInHouseContactPhEmail#
									<cfelse>
										#inside_phone_number#
										<br>
										#inside_email_address#
									</cfif>
								</div>
							</div>
						</td>
						<td style="width: 50%; vertical-align: top;">
							<div>Borrower (noted above) acknowledges reading and agreeing to the terms and conditions noted in this document.<div>
							<div><strong>Expected return date: #dateformat(return_due_date,"dd mmmm yyyy")#</strong></div>
							<br>
							<br>
							<div style="text-align: right; margin-top 1em;">Borrower&##39;s Signature: ______________________</div>
							<div style="text-align: right;">#recAgentName#</div>
						</td>
					</tr>
				</table>
			</cfdocumentsection>
		</cfif>

		<cfset accumulated_instructions = "">
		<cfset accumulated_description= "">
		<cfset accumulated_nature= "">
		<cfif getLoan.loan_type EQ "exhibition-master">
			<cfset master_transaction_id = transaction_id>
			<cfloop query="getSubloans">
				<cfset transaction_id = getSubloans.transaction_id>
				<cf_getLoanFormInfo transaction_id="#getSubloans.transaction_id#">
				<cfquery name="getSubloan" dbtype="query">
					select * from getLoanMCZ
				</cfquery>
				<cfdocumentsection name="Subloan Header">
					<div style="text-align: center; #font# font-size: 1em;">
						<strong> Exhibition Subloan #loan_number# </strong>
					</div>
					<div style="text-align: center; #font# font-size: 1em;">
						#getSubloan.collection#
					</div>
					<div style="text-align: center; #font# font-size: 1em;">
						Museum of Comparative Zoology, Harvard University
					</div>
					<table style="#font# font-size: small; padding: 0px; margin: 0px;">
						<tr>
							<td style="width: 55%; vertical-align: top;">
								<div>
									This document acknowledges the loan of specimens <strong>To:</strong> #getSubloan.recipientInstitutionName#.
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
					<div style="#font# font-size: small; margin-left: 4px;">
						<cfif len(getSubloan.nature_of_material) GT 0>
							<div>
								<strong>Nature of Material:</strong>
								<cfif len(getSubloan.nature_of_material) LT INSTRUCTIONS_LIMIT>
									#getSubloan.nature_of_material#
								<cfelse>
									#trim(left(getSubloan.nature_of_material,(INSTRUCTIONS_LIMIT - 26)))#... 
									<strong>Continued on Page #getSubloans.recordcount + MASTER_PAGES#.</strong>
									<cfset accumulated_nature= "#accumulated_nature# <div style='border-bottom: 1px solid black; width: 100%; #font_dq# font-size: 1em;'> <strong style='font-size: 1.2em'>Additional Nature of Material #getSubloan.loan_number#:</strong> #getSubloan.nature_of_material# </div> <br>"><!--- " --->
								</cfif>
							</div>
						</cfif>
						<cfif len(getSubloan.loan_description) GT 0>
							<div>
								<strong>Description:</strong>
								<cfif len(getSubloan.loan_description) LT INSTRUCTIONS_LIMIT>
									#getSubloan.loan_description#
								<cfelse>
									#trim(left(getSubloan.loan_description,(INSTRUCTIONS_LIMIT - 26)))#... 
									<strong>Continued on Page #getSubloans.recordcount + MASTER_PAGES#.</strong>
									<cfset accumulated_description = "#accumulated_description# <div style='border-bottom: 1px solid black; width: 100%; #font_dq# font-size: 1em;'> <strong style='font-size: 1.2em'>Description #getSubloan.loan_number#:</strong> #getSubloan.loan_description# </div> <br>"><!--- " --->
								</cfif>
							</div>
						</cfif>
						<cfif len(getSubloan.loan_instructions) GT 0>
							<div>
								<strong>Additional Instructions:</strong> 
								<cfif len(getSubloan.loan_instructions) LT INSTRUCTIONS_LIMIT>
									#getSubloan.loan_instructions#
								<cfelse>
									#trim(left(getSubloan.loan_instructions,(INSTRUCTIONS_LIMIT - 26)))#... 
									<strong>Continued on Page #getSubloans.recordcount + MASTER_PAGES#.</strong>
									<cfset accumulated_instructions = "#accumulated_instructions# <div style='border-bottom: 1px solid black; width: 100%; #font_dq# font-size: 1em;'> <strong style='font-size: 1.2em'>Additional Instructions #getSubloan.loan_number#:</strong> #getSubloan.loan_instructions# </div> <br>"><!--- " --->
								</cfif>
							</div>
						</cfif>
						<div style="margin: 0px; border: 1px solid black;">
							<div style="#font# font-size: small;">All Terms and Conditions From Loan #top_loan_number# Apply.</div>
						</div>
					</div>
					<table style="#font# font-size: small;">
						<tr>
							<td style="width: 50%; vertical-align: top;">
								<div style="#font# font-size: small;">UPON RECEIPT, SIGN AND RETURN ONE COPY TO:</div>
								<div>
									#replace(getSubloan.shipped_from_address,chr(10),"<br>","all")# 
									<div><strong>MCZ Contact:</strong>
										<cfif getSubloan.loan_type EQ "exhibition">
											#getSubloan.addInHouseContactPhEmail#
										<cfelse>
											#getSubloan.inside_phone_number#
											<br>
											#getSubloan.inside_email_address#
										</cfif>
									</div>
								</div>
							</td>
							<td style="width: 50%; vertical-align: top;">
								<div>Borrower (noted above) acknowledges reading and agreeing to the terms and conditions noted in this document.<div>
								<div><strong>Expected return date: #dateformat(getSubloan.return_due_date,"dd mmmm yyyy")#</strong></div>
								<br>
								<div style="text-align: right; margin-top: 1em;">Borrower&##39;s Signature: ______________________</div>
								<div style="text-align: right;">#getSubloan.recAgentName#</div>
							</td>
						</tr>
					</table>
				</cfdocumentsection>
			</cfloop>
			<cfset transaction_id = master_transaction_id>
		</cfif>

		<!--- Sumarize restrictions on material in loan inherited from accession permission and rights documents, and overflow long text from first page. --->
		<cfdocumentsection name="Additional Restrictions">
			<cfif len(nature_of_material) GT INSTRUCTIONS_LIMIT -1 OR ( getLoan.loan_type EQ "exhibition-master" AND len(accumulated_nature) GT 0)>
				<div style="border-bottom: 1px solid black; width: 100%; #font# font-size: small;">
					<strong>Nature of Material:</strong> 
					<cfif len(nature_of_material) GT INSTRUCTIONS_LIMIT -1 >
						#nature_of_material#
						<br>
					</cfif>
					<cfif getLoan.loan_type EQ "exhibition-master" AND len(accumulated_nature) GT 0>
						#accumulated_nature#
						<br>
					</cfif>
				</div>
			</cfif>
			<cfif len(loan_description) GT INSTRUCTIONS_LIMIT -1 OR ( getLoan.loan_type EQ "exhibition-master" AND len(accumulated_description) GT 0)>
				<div style="border-bottom: 1px solid black; width: 100%; #font# font-size: small;">
					<strong>Description:</strong> 
					<cfif len(loan_description) GT INSTRUCTIONS_LIMIT -1 >
						#loan_description#
						<br>
					</cfif>
					<cfif getLoan.loan_type EQ "exhibition-master" AND len(accumulated_description) GT 0>
						#accumulated_description#
						<br>
					</cfif>
				</div>
			</cfif>
			<cfif len(loan_instructions) GT INSTRUCTIONS_LIMIT -1 OR ( getLoan.loan_type EQ "exhibition-master" AND len(accumulated_instructions) GT 0)>
				<div style="border-bottom: 1px solid black; width: 100%; #font# font-size: small;">
					<strong>Instructions:</strong> 
					<cfif len(loan_instructions) GT INSTRUCTIONS_LIMIT -1 >
						#loan_instructions#
						<br>
					</cfif>
					<cfif getLoan.loan_type EQ "exhibition-master" AND len(accumulated_instructions) GT 0>
						#accumulated_instructions#
						<br>
					</cfif>
				</div>
			</cfif>
			<cfif getRestrictions.recordcount GT 0>
				<div style="text-align: center; #font# font-size: small;">
					<strong style="#font# font-size: small;">Summary of restrictions imposed and benefits required from original collecting agreements</strong>
				</div>
			</cfif>
			<cfif getRestrictions.recordcount GT 0 OR left(getLoan.loan_type,10) NEQ "exhibition">
				<!--- show generic CBD text on all non-exhibition loans, and any loans where there are restrictions on use --->
				<div style="#font# font-size: small;">
					The MCZ is committed to the spirit and letter of the Convention on Biological Diversity and its associated Nagoya Protocol on Access
					and Benefit-Sharing, and it expects its partner users to act in a manner consistent with these international obligations. Use
					of some specimens may be restricted by the providing country; therefore, a specimen may only be used for approved
					purposes, and express written permission must be obtained before a loaned specimen can be used for additional purposes.
				</div>
			</cfif>
			<cfif getRestrictions.recordcount GT 0>
				<ul style="#font# font-size: 1em;">
					<cfloop query="getRestrictions">
						<cfif getRestrictions.source EQ "accession">
							<li style="#font# font-size: small;">
								<strong style="#font# font-size: 1em;">
									#getRestrictions.specific_type# #getRestrictions.permit_num#
									<cfif len(getRestrictions.permit_num) EQ 0>#getRestrictions.permit_title#</cfif>
									<br>
								</strong> 
								<cfif len(getRestrictions.restriction_summary) GT 0> 
									Summary of restrictions on use: #getRestrictions.restriction_summary#<br>
								</cfif>
								<!--- internal_benefits_summary is not shown here, just the all users benefits summary --->
								<cfif len(getRestrictions.benefits_summary) GT 0> 
									Summary of required benefits: #getRestrictions.benefits_summary#
								</cfif>
							</li>
						<cfelse>
							<li style="#font# font-size: small;">
								<strong style="#font# font-size: 1em;">
									#getRestrictions.specific_type# #getRestrictions.permit_num#
									<cfif len(getRestrictions.permit_num) EQ 0>#getRestrictions.permit_title#</cfif>
									<br>
									Applies to all material in this loan:
									<br>
								</strong>
								<cfif len(getRestrictions.restriction_summary) GT 0> 
									Summary of restrictions on use: #getRestrictions.restriction_summary#<br>
								</cfif>
								<!--- internal_benefits_summary is not shown here, just the all users benefits summary --->
								<cfif len(getRestrictions.benefits_summary) GT 0> 
									Summary of required benefits: #getRestrictions.benefits_summary#
								</cfif>
							</li>
						</cfif>
					</cfloop>
				</ul>
			</cfif>
		</cfdocumentsection>

		<cfdocumentsection name="Items In Loan">
			<div style="text-align: center; #font# font-size: 1.1em; margin-bottom: 1em;">
				<strong>Invoice of Specimens</strong>
			</div>
			<cfif getHasFluid.ct EQ 0 or getHasFluid.ct EQ "">
				<div style="text-align: center; #font# font-size: small; margin-bottom: 0.5em;">
					Retain fluid specimens in 70% ethanol unless noted otherwise.
				</div>
			<cfelse>
				<div style="text-align: center; #font# font-size: 1.1em; margin-bottom: 0.5em;">
					<strong>Retain fluid specimens in 70% ethanol unless noted otherwise.</strong>
				</div>
			</cfif>
			<cfif top_loan_type EQ "exhibition-master">
				<cfset master_transaction_id = transaction_id>
				<cfset masterTotal = 0>
				<cfset masterLotTotal = 0>
				<cfloop query="getSubloans">
					<cfset transaction_id = getSubloans.transaction_id>
					<cf_getLoanFormInfo transaction_id="#getSubloans.transaction_id#">
					<cfif isDefined("groupBy") AND groupBy EQ "part">
						<cfquery name="getLoanItems" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							SELECT DISTINCT
								collection.collection AS collection,
								cataloged_item.collection_cde as collection_cde,
								collection.institution_acronym as institution_acronym,
								cataloged_item.collection_object_id as collection_object_id,
								loan_number,
								to_char(loan_item.reconciled_date,'yyyy-mm-dd') reconciled_date,
								MCZBASE.CONCATITEMREMINLOAN(specimen_part.derived_from_cat_item, loan_item.transaction_id) as loan_item_remarks,
								concattransagent(loan.transaction_id, 'received by')  recAgentName,
								cat_num,
								MCZBASE.GET_TYPESTATUS(cataloged_item.collection_object_id) as type_status,
								decode(
									MCZBASE.GET_TYPESTATUSNAME(cataloged_item.collection_object_id,
									MCZBASE.GET_TYPESTATUS(cataloged_item.collection_object_id)), 
									MCZBASE.GET_SCIENTIFIC_NAME(cataloged_item.collection_object_id),
									'', 
									decode(MCZBASE.GET_TYPESTATUSNAME(cataloged_item.collection_object_id,
										MCZBASE.GET_TYPESTATUS(cataloged_item.collection_object_id)),'','',
										' of ' || MCZBASE.GET_TYPESTATUSNAME(cataloged_item.collection_object_id,
										MCZBASE.GET_TYPESTATUS(cataloged_item.collection_object_id))
									)
								) as typestatusname,
							
								MCZBASE.CONCATPARTSINLOAN(specimen_part.derived_from_cat_item, loan_item.transaction_id) as parts,
								MCZBASE.CONCATPARTCTINLOAN(specimen_part.derived_from_cat_item, loan_item.transaction_id) as lot_count,
								MCZBASE.GET_SCIENTIFIC_NAME(cataloged_item.collection_object_id) as scientific_name, 
								spec_locality,
								higher_geog,
								GET_CHRONOSTRATIGRAPHY(locality.locality_id) chronostrat,
								GET_LITHOSTRATIGRAPHY(locality.locality_id) lithostrat,
								HTF.escape_sc(concatColl(cataloged_item.collection_object_id)) as collectors,
								cat_num_prefix,
								cat_num_integer,
								part.condition as condition
							FROM loan 
								left join loan_item on loan.transaction_id = loan_item.transaction_id 
								left join specimen_part on loan_item.collection_object_id = specimen_part.collection_object_id 
								left join coll_object part on loan_item.collection_object_id = part.collection_object_id 
								left join cataloged_item on specimen_part.derived_from_cat_item = cataloged_item.collection_object_id 
								left join collection on cataloged_item.collection_id = collection.collection_id 
								left join collecting_event on cataloged_item.collecting_event_id = collecting_event.collecting_event_id 
								left join locality on collecting_event.locality_id = locality.locality_id 
								left join geog_auth_rec on locality.geog_auth_rec_id = geog_auth_rec.geog_auth_rec_id 
							WHERE 
								loan.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
							<cfif sort eq "cat_num"> 
		  						ORDER BY cat_num
							<cfelseif sort eq "cat_num_pre_int"> 
		  						ORDER BY cat_num_prefix, cat_num_integer
							<cfelseif sort eq "scientific_name"> 
			  					ORDER BY scientific_name
							</cfif>
						</cfquery>
					<cfelse>
						<cfquery name="getLoanItems" dbtype="query">
							SELECT * 
							FROM getLoanItemsMCZ
							<cfif sort eq "cat_num"> 
		  						order by cat_num
							<cfelseif sort eq "cat_num_pre_int"> 
		  						order by cat_num_prefix, cat_num_integer
							<cfelseif sort eq "scientific_name"> 
			  					order by scientific_name
							</cfif>
						</cfquery>
					</cfif>
					<div style="text-align: left; #font# font-size: 1em;">
						Specimens in Subloan #getSubloans.loan_number#
					</div>
					<table style="#font# font-size: 1em; width: 100%;">
						<tr>
							<th style="width: 25%;">MCZ Number</th>
							<th style="width: 50%;">Taxon, Locality</th>
							<th style="width: 25%;">Specimen Count</th>
						</tr>
						<cfset totalLotCount = 0>
						<cfset totalSpecimens = 0>
						<cfif isDefined("groupBy") AND groupBy EQ "part">
							<cfquery name="getLoanItemsLoop" dbtype="query">
								SELECT distinct 
									collection_object_id,
									institution_acronym, collection_cde, cat_num,
									reconciled_date,
									scientific_name, type_status, higher_geog,
									collection, chronostrat,lithostrat,
									spec_locality, collectors, loan_item_remarks
								FROM getLoanItems
							</cfquery>
						<cfelse>
							<cfquery name="getLoanItemsLoop" dbtype="query">
								SELECT *
								FROM getLoanItems
							</cfquery>
						</cfif>
						<cfloop query="getLoanItemsLoop">
							<tr>
								<td style="width: 25%; vertical-align: top; #font# font-size: small;">
									#institution_acronym#:#collection_cde#:#cat_num#
									<cfif top_loan_status EQ "closed">#reconciled_date#</cfif>
								</td>
								<td style="width: 50%; vertical-align: top; #font# font-size: small;">
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
								<td style="width: 25%; vertical-align: top; #font# font-size: small;">
									<cfif isDefined("groupBy") AND groupBy EQ "part">
										<cfquery name="getLoanItemsParts" dbtype="query">
											SELECT sum(lot_count) slc, parts
											FROM getLoanItems
											WHERE 
												institution_acronym = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#institution_acronym#">
												and collection_cde = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#collection_cde#">
												and cat_num = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#cat_num#">
											GROUP BY parts
										</cfquery>
										<cfloop query="getLoanItemsParts">
											#parts#
											<cfset totalSpecimens = totalSpecimens + slc>
										</cfloop>
									<cfelse>
										<cfset totalSpecimens = totalSpecimens + lot_count>
										#lot_count# #part_modifier# #part_name#
										<cfif len(preserve_method) GT 0>(#preserve_method#)</cfif>
										<cfif Len(condition) GT 0 and top_loan_type contains 'exhibition' ><BR>Condition: #condition#</cfif>
									</cfif>
									<cfif getRestrictions.recordcount GT 0>
										<cfquery name="getSpecificRestrictions" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
											SELECT DISTINCT
												permit.permit_num,
												permit.specific_type,
												permit.permit_title
											FROM loan_item li 
												join specimen_part sp on li.collection_object_id = sp.collection_object_id
												join cataloged_item ci on sp.derived_from_cat_item = ci.collection_object_id
												join accn on ci.accn_id = accn.transaction_id
												join permit_trans on accn.transaction_id = permit_trans.transaction_id
												join permit on permit_trans.permit_id = permit.permit_id
											WHERE li.transaction_id = <cfqueryparam CFSQLType="CF_SQL_DECIMAL" value="#transaction_id#">
												and ci.collection_object_id  = <cfqueryparam CFSQLType="CF_SQL_DECIMAL" value="#getLoanItemsLoop.collection_object_id#">
												and (permit.restriction_summary is not null
													or permit.benefits_summary is not null)
										</cfquery>
										<cfif getSpecificRestrictions.recordcount GT 0>
											<br>
											<strong>Use Restricted By:</strong>
											<cfset separator = "">
											<cfloop query="getSpecificRestrictions"><span style="#font# font-size: small;">#separator##getSpecificRestrictions.permit_num#<cfif len(getSpecificRestrictions.permit_num) EQ 0> #getSpecificRestrictions.permit_title#</cfif></span><cfset separator = ", "></cfloop>
										</cfif>
									</cfif>
								</td>
							</tr>
							<cfset totalLotCount = totalLotCount + 1>
						</cfloop>
					</table>
					<div style="#font# font-size: 1em; margin-bottom: 2em; border-bottom: 1px solid black;">
						<cfif TotalSpecimens EQ 1><cfset splural = ""><cfelse><cfset splural = "s"></cfif>
						<cfif TotalLotCount EQ 1><cfset lplural = ""><cfelse><cfset lplural = "s"></cfif>
						Subloan #getSubloans.loan_number# includes #TotalSpecimens# specimen#splural# in #TotalLotCount# lot#lplural#.
						<cfset masterTotal = masterTotal + TotalSpecimens>
						<cfset masterLotTotal = masterLotTotal + TotalLotCount>
					</div>
				</cfloop>
				<div style="#font# font-size: 1em;">
					<cfif masterTotal EQ 1><cfset splural = ""><cfelse><cfset splural = "s"></cfif>
					<cfif masterLotTotal EQ 1><cfset lplural = ""><cfelse><cfset lplural = "s"></cfif>
					<strong>Loan #loan_number# includes a total of #masterTotal# specimen#splural# in #masterLotTotal# lot#lplural#.</strong>
				</div>
				<cfset transaction_id = master_transaction_id >
				<cf_getLoanFormInfo transaction_id="#master_transaction_id#">
			<cfelse>
				<table style="#font# font-size: 1em;">
					<tr>
						<th style="width: 25%;">MCZ Number</th>
						<th style="width: 50%;">Taxon, Locality</th>
						<th style="width: 25%;">Specimen Count</th>
					</tr>
					<cfset totalLotCount = 0>
					<cfset totalSpecimens = 0>
					<cfif isDefined("groupBy") AND groupBy EQ "part">
						<cfquery name="getLoanItemsLoop" dbtype="query">
							SELECT distinct 
								collection_object_id,
								institution_acronym, collection_cde, cat_num,
								reconciled_date,
								scientific_name, type_status, higher_geog,
								collection, chronostrat,lithostrat,
								spec_locality, collectors, loan_item_remarks
							FROM getLoanItems
						</cfquery>
					<cfelse>
						<cfquery name="getLoanItemsLoop" dbtype="query">
							SELECT *
							FROM getLoanItems
						</cfquery>
					</cfif>
					<cfloop query="getLoanItemsLoop">
						<tr>
							<td style="width: 25%; vertical-align: top; #font# font-size: small;">
								#institution_acronym#:#collection_cde#:#cat_num#
								<cfif top_loan_status EQ "closed">#reconciled_date#</cfif>
							</td>
							<td style="width: 50%; vertical-align: top; #font# font-size: small;">
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
							<td style="width: 25%; vertical-align: top; #font# font-size: small;">
								<cfif isDefined("groupBy") AND groupBy EQ "part">
									<cfquery name="getLoanItemsParts" dbtype="query">
										SELECT sum(lot_count) slc, parts
										FROM getLoanItems
										WHERE 
											institution_acronym = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#institution_acronym#">
											and collection_cde = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#collection_cde#">
											and cat_num = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#cat_num#">
										GROUP BY parts
									</cfquery>
									<cfloop query="getLoanItemsParts">
										#parts#
										<cfset totalSpecimens = totalSpecimens + slc>
									</cfloop>
								<cfelse>
									<cfset totalSpecimens = totalSpecimens + lot_count>
									#lot_count# #part_modifier# #part_name#
									<cfif len(preserve_method) GT 0>(#preserve_method#)</cfif>
									<cfif Len(condition) GT 0 and top_loan_type contains 'exhibition' ><BR>Condition: #condition#</cfif>
								</cfif>
								<cfif getRestrictions.recordcount GT 0>
									<cfquery name="getSpecificRestrictions" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
										SELECT DISTINCT
											permit.permit_num, permit_title
										FROM loan_item li 
											join specimen_part sp on li.collection_object_id = sp.collection_object_id
											join cataloged_item ci on sp.derived_from_cat_item = ci.collection_object_id
											join accn on ci.accn_id = accn.transaction_id
											join permit_trans on accn.transaction_id = permit_trans.transaction_id
											join permit on permit_trans.permit_id = permit.permit_id
										WHERE li.transaction_id = <cfqueryparam CFSQLType="CF_SQL_DECIMAL" value="#transaction_id#">
											and ci.collection_object_id  = <cfqueryparam CFSQLType="CF_SQL_DECIMAL" value="#getLoanItemsLoop.collection_object_id#">
											and (permit.restriction_summary is not null
												or permit.benefits_summary is not null)
									</cfquery>
									<cfif getSpecificRestrictions.recordcount GT 0>
										<br>
										<strong>Use Restricted By:</strong>
										<cfset separator = "">
										<cfloop query="getSpecificRestrictions"><span style="#font# font-size: small;">#separator##getSpecificRestrictions.permit_num#<cfif len(getSpecificRestrictions.permit_num) EQ 0> #getSpecificRestrictions.permit_title#</cfif></span><cfset separator = ", "></cfloop>
									</cfif>
								</cfif>
							</td>
						</tr>
						<cfset totalLotCount = totalLotCount + 1>
					</cfloop>
				</table>
				<div style="#font# font-size: 1em;">
					<cfif TotalSpecimens EQ 1><cfset splural = ""><cfelse><cfset splural = "s"></cfif>
					<cfif TotalLotCount EQ 1><cfset lplural = ""><cfelse><cfset lplural = "s"></cfif>
					Total of #TotalSpecimens# specimen#splural# in #TotalLotCount# lot#lplural#.
				</div>
			</cfif>
		</cfdocumentsection>

		<cfif getShipments.recordcount EQ 1 AND getLoan.loan_type NEQ "exhibition-subloan">
			<cfdocumentsection name="Shipping Labels">
			<cfloop query="getShipments">
				<div style="#font# font-size: 1em; margin-bottom: 2em;">
					Shipping Label
				</div>
				<table style="#font# font-size: 1em;">
					<tr>
						<td>
							<strong style="#font# font-size: 1em;">From:</strong>
							<br> 
							#replace(fromAddress,chr(10),"<br>","all")# 
						</td>
					</tr>
					<tr>
						<td style="border: 1px solid black;">
							<strong style="#font# font-size: 1.2em;">To:</strong>
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
