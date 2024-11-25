<cfinclude template="/includes/_header.cfm">
	<cfoutput>
		<!--- start of long term loan code --->
		<!---
			Query to get all loan data from the server. Use GOD query so we can ignore collection partitions.
			This form has no output and relies on system time to run, so only danger is in sending multiple copies
			of notification to loan folks. No real risk in not using a lesser agent for the queries.
		--->
		<cfquery name="expLoan" datasource="uam_god">
			select
				loan.transaction_id,
				LOAN_NUMBER,
				loan_type,
				loan_status,
				trans_date,
				return_due_date,
				electronic_address.address,
				round(RETURN_DUE_DATE - sysdate)+1 expires_in_days,
				trans_agent.trans_agent_role,
				preferred_agent_name.agent_id,
				preferred_agent_name.agent_name,
				nnName.agent_name collection_agent_name,
				nnAddr.address collection_email,
				collection,
				collection.collection_id,
				nature_of_material,
				REPLACE(formatted_addr, CHR(10),'<br>') FORMATTED_ADDR,
				last_name,
				first_name,
				addr.country_cde
			FROM
				loan,
				trans,
				collection,
				trans_agent,
				person,
				preferred_agent_name,
				preferred_agent_name nnName,
				(select * from electronic_address where address_type='email') electronic_address,
				(select * from electronic_address where address_type='email') nnAddr,
				(select * from collection_contacts where contact_role='loan request') collection_contacts,
				shipment,
				addr
			WHERE
				loan.transaction_id = trans.transaction_id AND
				trans.collection_id=collection_contacts.collection_id (+) and
				trans.collection_id=collection.collection_id and
				collection_contacts.contact_agent_id=nnName.agent_id (+) and
				collection_contacts.contact_agent_id=nnAddr.agent_id (+) and
				trans.transaction_id=trans_agent.transaction_id and
				trans_agent.agent_id = preferred_agent_name.agent_id AND
				trans_agent.agent_id = person.person_id(+) AND
				preferred_agent_name.agent_id = electronic_address.agent_id(+) AND
				trans_agent.trans_agent_role in ('in-house contact',  'additional in-house contact', 'additional outside contact', 'for use by', 'received by','outside contact') and
				round(RETURN_DUE_DATE - (sysdate)) +1 < -365 and
				LOAN_STATUS like 'open%' and
				loan_status <> 'open historical' and
				loan_type in ('returnable', 'consumable') and
				loan.transaction_id=shipment.transaction_id(+) and
				shipment.shipped_to_addr_id = addr.addr_id(+)
		</cfquery>
		<!--- local query to organize and flatten loan data --->
		<cfquery name="agent" dbtype="query">
			select distinct agent_name, agent_id from expLoan where trans_agent_role = 'received by' order by agent_name
		</cfquery>
		<!--- loop once for each agent --->
	<cfloop query="agent" startrow=1 endrow=330>
	<cfquery name="chkLog" datasource="uam_god">
		select * from loan_reminder_log where agent_id=#agent.agent_id# and reminder_type = 'L' and date_sent > to_date('2024-08-31', 'YYYY-MM-DD')
	</cfquery>
	<cfif chkLog.recordcount EQ 0>
			<!--- local queries to organize and flatten loan data --->
			<cfquery name="agent_loans" dbtype="query">
				select * from expLoan
				where agent_id = #agent.agent_id# and trans_agent_role = 'received by'
			</cfquery>
			<cfquery name="loan" dbtype="query">
			select
				transaction_id,
				LOAN_NUMBER,
				loan_type,
				loan_status,
				trans_date,
				return_due_date,
				expires_in_days,
				collection,
				nature_of_material,
				collection_id,
				formatted_addr,
				country_cde
			from
				agent_loans
			where
				loan_status not in ('open under-review') and
				loan_type not in ('exhibition')
			group by
				transaction_id,
				RETURN_DUE_DATE,
				LOAN_NUMBER,
				loan_type,
				loan_status,
				trans_date,
				return_due_date,
				expires_in_days,
				collection,
				nature_of_material,
				collection_id,
				formatted_addr,
				country_cde
			order by collection, trans_date
		</cfquery>
		<cfquery name="loanunderreview" dbtype="query">
			select
				transaction_id,
				LOAN_NUMBER,
				loan_type,
				loan_status,
				trans_date,
				return_due_date,
				expires_in_days,
				collection,
				nature_of_material,
				collection_id,
				formatted_addr,
				country_cde
			from
				agent_loans
			where
				loan_status in ('open under-review') and
				loan_type not in ('exhibition')
			group by
				transaction_id,
				RETURN_DUE_DATE,
				LOAN_NUMBER,
				loan_type,
				loan_status,
				trans_date,
				return_due_date,
				expires_in_days,
				collection,
				nature_of_material,
				collection_id,
				formatted_addr,
				country_cde
			order by collection, trans_date
		</cfquery>
		<!---cfquery name="loanexhibition" dbtype="query">
			select
				transaction_id,
				LOAN_NUMBER,
				loan_type,
				loan_status,
				trans_date,
				return_due_date,
				expires_in_days,
				collection,
				nature_of_material,
				collection_id,
				formatted_addr
			from
				agent_loans
			where
				loan_type in ('exhibition')
			group by
				transaction_id,
				RETURN_DUE_DATE,
				LOAN_NUMBER,
				loan_type,
				loan_status,
				trans_date,
				return_due_date,
				expires_in_days,
				collection,
				nature_of_material,
				collection_id,
				formatted_addr
			order by collection, trans_date
		</cfquery--->


			<cfquery name="cc_Agents" dbtype="query">
				select
					expLoan.address,
					expLoan.agent_name
				from
					agent_loans, expLoan
				where
					agent_loans.transaction_id = expLoan.transaction_id and
					expLoan.trans_agent_role in ('in-house contact', 'additional in-house contact') and
					expLoan.address is not null
				group by
					expLoan.address,
					expLoan.agent_name
			</cfquery>
			<cfquery name="inhouse" dbtype="query">
				select
					expLoan.address,
					expLoan.agent_name
				from
					agent_loans, expLoan
				where
					agent_loans.transaction_id = expLoan.transaction_id and
					expLoan.trans_agent_role in ('in-house contact') and
					expLoan.address is not null
				group by
					expLoan.address,
					expLoan.agent_name
			</cfquery>
			<cfquery name="formattedinhouse" dbtype="query">
				select
					(expLoan.agent_name + ' in the ' + expLoan.collection + ' Collection (' + expLoan.address + ')') contact,
					expLoan.agent_name
				from
					agent_loans, expLoan
				where
					agent_loans.transaction_id = expLoan.transaction_id and
					expLoan.trans_agent_role in ('in-house contact') and
					expLoan.address is not null
				group by
					expLoan.collection,
					expLoan.address,
					expLoan.agent_name
			</cfquery>
			<cfquery name="to_agents" dbtype="query">
				select
					expLoan.address,
					expLoan.agent_name
				from
					agent_loans, expLoan
				where
					agent_loans.transaction_id = expLoan.transaction_id and
					expLoan.trans_agent_role in ('additional outside contact', 'for use by', 'received by','outside contact') and
					expLoan.address is not null
				group by
					expLoan.address,
					expLoan.agent_name
			</cfquery>
			<!---cfquery name="collectionAgents" dbtype="query">
				select
					collection_agent_name agent_name,
					collection_email address
				from
					agent_loans
				where
					collection_email is not null
				group by
					collection_agent_name,
					collection_email
			</cfquery--->
			<cfquery name="receivedBy" dbtype="query">
				select
					last_name,
					first_name,
					agent_name
				from
					agent_loans
				where
					trans_agent_role = 'received by'
				group by
					last_name,
					first_name,
					agent_name
			</cfquery>

			<cfset specialmail="">
			<cfif to_agents.recordcount EQ 0>
				<cfset toaddresses = ValueList(cc_agents.address,";")>
				<cfset ccaddresses = "">
				<cfset specialmail="noemails">
			<cfelse>
				<cfset toaddresses = ValueList(to_agents.address,";")>
				<cfset ccaddresses = ValueList(cc_agents.address,";")>
			</cfif>

			<!---cfif to_agents.recordcount EQ 0>
				<cfset toaddresses = "bhaley@oeb.harvard.edu">
				<cfset ccaddresses = "">
				<cfset specialmail="noemails">
			<cfelse>
				<cfset toaddresses = "bhaley@oeb.harvard.edu">
				<cfset ccaddresses = "">
			</cfif--->
			<cfif len(toaddresses) EQ 0>
				<cfset toaddresses = "bhaley@oeb.harvard.edu">
				<cfset specialmail="noemails">
			</cfif>
	<cfset uscodes="US,USA,UNITED STATES,UNITED STATES OF AMERICA,U.S.A">
	<cfif loan.recordcount GT 0>
			<cfquery name="collections" dbtype="query">
				select distinct collection from loan
			</cfquery>
			<cfset mailsubject = "MCZbase Notification for Overdue Loans to " & #receivedby.agent_name#>
			<cfif specialmail EQ "noemails">
				<cfset mailsubject = "ALERT: NO EXTERNAL CONTACTS | MCZbase Notification for Overdue Loans to " & #receivedby.agent_name#>
			</cfif>
			<cfmail 	to="#toaddresses#"
						cc="#ccaddresses#"
						bcc="bhaley@oeb.harvard.edu;heliumcell@gmail.com"
						subject="#mailsubject#"
						from="no_reply_loan_notification@#Application.fromEmail#"
						replyto="#ValueList(inhouse.address,";")#"
						type="html">

			<cfif specialmail EQ "noemails">
					<font color="red">
					<<< MCZbase UNABLE TO SEND THE FOLLOWING OVERDUE LOAN NOTIFICATION >>><br>
	             	<<< ENTER EXTERNAL CONTACTS FOR THIS LOAN  >>><br>
					</font>
			</cfif>

				<p>---------------------------------------------------------------------<br>
				MUSEUM OF COMPARATIVE ZOOLOGY<br>
				HARVARD UNIVERSITY<br>
				<br>
				OVERDUE LOAN NOTIFICATION REPORT FOR #DateFormat(Now(),"dd-mmmm-YYYY")#
				<br><br>
				Dear Colleague,
				<br><br>
				This is an MCZbase notification report regarding #loan.recordcount# MCZ Loan<cfif #loan.recordcount# GT 1>s</cfif> overdue for RETURN for more than one year to the
					<cfif collections.recordcount EQ 1>
						<cfif #collections.collection# EQ "Special Collections">
							Special Collections.
						<cfelse>
							#collections.collection# Collection.
						</cfif>
					<cfelseif collections.recordcount EQ 2>
						#ReReplace(ValueList(collections.collection, ' and '),'Collections$', '')# Collections.
					<cfelse >
						#ReReplace(ReReplace(ValueList(collections.collection, ', '),',(?=[^,]+$)' , ', and ' ),'Collections$', '')# Collections.
					</cfif>

				<br><br>
				LOAN<cfif #loan.recordcount# GT 1>S</cfif> DUE TO BE RETURNED:

				<br><br>
				<cfset isInternational = 0>
				<cfloop query="loan">
				<cfif not ListFind(usCodes,country_cde) AND len(COUNTRY_CDE) GT 0>
					<cfset isInternational = 1>
				</cfif>
					<cfquery name="counts" datasource="uam_god">
						select
							sum(coll_object.lot_count) total, sum(decode(coll_object.coll_obj_disposition, 'on loan', coll_object.lot_count, 0)) outstanding
						from
							loan, loan_item, coll_object
						where
							loan.transaction_id=#transaction_id# and
							loan.transaction_id = loan_item.transaction_id and
							loan_item.collection_object_id = coll_object.collection_object_id
						group by
						loan.transaction_id
					</cfquery>
				Loan Number: #loan_number# // Due Date: #DateFormat(return_due_date, "dd-mmmm-YYYY")#
				<br>
				Original Total Number of Items:	#counts.total# // Partial Return of Loaned Items: <cfif loan_status EQ "open partially returned">Yes<cfelse>No</cfif>
				<br>
				Nature of Material: #nature_of_material#
				<br>
				<cfquery name="forUseBy" dbtype="query">
					select
						exploan.last_name,
						exploan.first_name,
						exploan.agent_name
					from
						agent_loans, exploan
					where
						agent_loans.transaction_id = expLoan.transaction_id and
						agent_loans.transaction_id = #loan.transaction_id# and
						expLoan.trans_agent_role = 'for use by'
					group by
						exploan.last_name,
						exploan.first_name,
						exploan.agent_name
				</cfquery>
				<cfif len(#ValueList(forUseBy.agent_name)#) GT 0 >
				For Use By:	#ValueList(forUseBy.agent_name)#
				<br>
				</cfif>
				<br>
				------
				<br><br>

				<cfquery name="upLogTable" datasource="uam_god">
					insert into LOAN_REMINDER_LOG(agent_id, date_sent, transaction_id, reminder_type, TOADDRESSES)
					values(#agent.agent_id#, SYSDATE, #transaction_id#, 'L', <cfif specialmail NEQ "noemails">'#toaddresses#'<cfelse>'noemails'</cfif>)
				</cfquery>

				</cfloop>
				Approved Borrower: #receivedby.agent_name#
				<!---cfquery name="address" datasource="uam_god">
					select formatted_addr from addr where valid_addr_fg = 1 and addr_type = 'correspondence' and agent_id = #agent.agent_id#
				</cfquery>
				Shipped to:<br>
				#address.formatted_addr#--->
				<br><br>
				We request that you please return the above loan<cfif #loan.recordcount# GT 1>s</cfif>
					 as soon as possible. For more information on <cfif #loan.recordcount# EQ 1>this loan<cfelse>these loans</cfif>, contact
					<cfif collections.recordcount EQ 1>
						#Replace(ValueList(formattedinhouse.contact, ', '), "Special Collections Collection", "Special Collections")#.
					<cfelse >
						#REPLACE(ReReplace(ValueList(formattedinhouse.contact, ', '),',(?=[^,]+$)' , ', and ' ), "Special Collections Collection", "Special Collections")#.
					</cfif>
				<cfif isInternational EQ 1>
				<br><br>To meet federal regulations regarding importation and clearance of international shipments, researchers returning MCZ material must:<br>
				<ul>
					<li>Provide the name of the courier (e.g., FedEx, DHL, trackable post), the Airway Bill number, and an
						invoice of contents (scientific names, countries of origin, and number of specimens of each) to the MCZ Curatorial
						Associate <strong>at least 72 hours in advance of any shipment.</strong></li>
					<li>Include “<strong>USFWS CLEARANCE REQUIRED</strong>” on the International waybill AND in red on all sides of the
						outside of the package. (Note: “Scientific research specimens, not restricted, Special Provision A180
						applies” should also be noted on the waybill and package if applicable.)</li>
					<li>Include three copies of all documentation in the waybill pouch.</li>
				</ul>
				</cfif>
				 Your attention to this matter will be greatly appreciated.
				 <cfif findnocase("CRYOGENIC",ValueList(formattedinhouse.contact, ', ')) GT 0>
				<br><br>
				For Cryogenic Collection loans, if you have any remaining material (e.g., tissue, DNA), please email the Collection Manager to discuss whether it should be returned.
				To officially close this loan, please also provide publication information and NCBI sequence accession numbers to the MCZ-CRYO.<br><br>
				NCBI accessions will automatically link to MCZbase records if information is submitted correctly:<br>
				https://mcz.harvard.edu/files/mcz/files/guidelines_for_submitting_to_genbank.pdf<br>
				https://mcz.harvard.edu/files/mcz/files/ncbi_bioproject_biosample_data.pdf<br>
				<br>
				Thank you.<br>
				<cfelse>
				Thank you.<br>
				</cfif>
				<BR>
				---------------------------------------------------------------------</P>
				<hr><hr>
			</cfmail>

	</cfif>


	<cfif loanunderreview.recordcount GT 0>
				<cfset toaddresses = ValueList(cc_agents.address,";")>
				<cfset ccaddresses = "">

				<cfif len(toaddresses) EQ 0>
				<cfset toaddresses = "bhaley@oeb.harvard.edu">
				<cfset ccaddresses = "">
				</cfif>

			<cfquery name="collections" dbtype="query">
				select distinct collection from loanunderreview
			</cfquery>

			<cfmail 	to="#toaddresses#"
						cc="#ccaddresses#"
						bcc="bhaley@oeb.harvard.edu"
						subject="ALERT: OPEN UNDER-REVIEW | MCZbase Notification for Overdue Loans"
						from="no_reply_loan_notification@#Application.fromEmail#"
						replyto="#ValueList(inhouse.address,";")#"
						type="html">

			<cfif specialmail EQ "noemails">
					<font color="red">
					<<< MCZbase UNABLE TO SEND THE FOLLOWING OVERDUE LOAN NOTIFICATION >>><br>
	             	<<< ENTER EXTERNAL CONTACTS FOR THIS LOAN  >>><br>
					</font>
			</cfif>
					<font color="red">
						<<< THE FOLLOWING OVERDUE LOANS ARE MARKED AS "OPEN UNDER-REVIEW" >>><br>
					</font>
				<p>---------------------------------------------------------------------<br>
				MUSEUM OF COMPARATIVE ZOOLOGY<br>
				HARVARD UNIVERSITY<br>
				<br>
				OVERDUE LOAN NOTIFICATION REPORT FOR #DateFormat(Now(),"dd-mmmm-YYYY")#
				<br><br>
				Dear Colleague,
				<br><br>
				This is an MCZbase notification report regarding #loanunderreview.recordcount# MCZ Loan<cfif #loanunderreview.recordcount# GT 1>s</cfif> overdue for RETURN for more than one year to the
					<cfif collections.recordcount EQ 1>
						<cfif #collections.collection# EQ "Special Collections">
							Special Collections.
						<cfelse>
							#collections.collection# Collection.
						</cfif>
					<cfelseif collections.recordcount EQ 2>
						#ReReplace(ValueList(collections.collection, ' and '),'Collections$', '')# Collections.
					<cfelse >
						#ReReplace(ReReplace(ValueList(collections.collection, ', '),',(?=[^,]+$)' , ', and ' ),'Collections$', '')# Collections.
					</cfif>

				<br><br>
				LOAN<cfif #loanunderreview.recordcount# GT 1>S</cfif> DUE TO BE RETURNED:

				<br><br>
				<cfset isInternational = 0>
				<cfloop query="loanunderreview">
				<cfif not ListFind(usCodes,country_cde) AND len(COUNTRY_CDE) GT 0>
					<cfset isInternational = 1>
				</cfif>
					<cfquery name="counts" datasource="uam_god">
						select
							sum(coll_object.lot_count) total, sum(decode(coll_object.coll_obj_disposition, 'on loan', coll_object.lot_count, 0)) outstanding
						from
							loan, loan_item, coll_object
						where
							loan.transaction_id=#transaction_id# and
							loan.transaction_id = loan_item.transaction_id and
							loan_item.collection_object_id = coll_object.collection_object_id
						group by
						loan.transaction_id
					</cfquery>
				Loan Number: #loan_number# // Due Date: #DateFormat(return_due_date, "dd-mmmm-YYYY")#
				<br>
				Original Total Number of Items:	#counts.total# // Partial Return of Loaned Items: <cfif loan_status EQ "open partially returned">Yes<cfelse>No</cfif>
				<br>
				Nature of Material: #nature_of_material#
				<br>
				<cfquery name="forUseBy" dbtype="query">
					select
						exploan.last_name,
						exploan.first_name,
						exploan.agent_name
					from
						agent_loans, exploan
					where
						agent_loans.transaction_id = expLoan.transaction_id and
						agent_loans.transaction_id = #loanunderreview.transaction_id# and
						expLoan.trans_agent_role = 'for use by'
					group by
						exploan.last_name,
						exploan.first_name,
						exploan.agent_name
				</cfquery>
				<cfif len(#ValueList(forUseBy.agent_name)#) GT 0 >
				For Use By:	#ValueList(forUseBy.agent_name)#
				<br>
				</cfif>
				<br>
				------
				<br><br>

				<cfquery name="upLogTable" datasource="uam_god">
					insert into LOAN_REMINDER_LOG(agent_id, date_sent, transaction_id, reminder_type, TOADDRESSES)
					values(#agent.agent_id#, SYSDATE, #transaction_id#, 'L', 'under-review')
				</cfquery>

				</cfloop>
				Approved Borrower: #receivedby.agent_name#
				<!---cfquery name="address" datasource="uam_god">
					select formatted_addr from addr where valid_addr_fg = 1 and addr_type = 'correspondence' and agent_id = #agent.agent_id#
				</cfquery>
				Shipped to:<br>
				#address.formatted_addr#--->
				<br><br>
				We request that you please return the above loan<cfif #loanunderreview.recordcount# GT 1>s</cfif>
					 as soon as possible. For more information on <cfif #loanunderreview.recordcount# EQ 1>this loan<cfelse>these loans</cfif>, contact the
					<cfif collections.recordcount EQ 1>
						#Replace(ValueList(formattedinhouse.contact, ', '), "Special Collections Collection", "Special Collections")#.
					<cfelse >
						#REPLACE(ReReplace(ValueList(formattedinhouse.contact, ', '),',(?=[^,]+$)' , ', and ' ), "Special Collections Collection", "Special Collections")#.
					</cfif>
				<cfif isInternational EQ 1>
				<br><br>To meet federal regulations regarding importation and clearance of international shipments, researchers returning MCZ material must:<br>
				<ul>
					<li>Provide the name of the courier (e.g., FedEx, DHL, trackable post), the Airway Bill number, and an
						invoice of contents (scientific names and number of specimens of each) to the MCZ Curatorial
						Associate <strong>at least 72 hours in advance of any shipment.</strong></li>
					<li>Include “<strong>USFWS CLEARANCE REQUIRED</strong>” on the International waybill AND in red on all sides of the
						outside of the package. (Note: “Scientific research specimens, not restricted, Special Provision A180
						applies” should also be noted on the waybill and package if applicable.)</li>
					<li>Include three copies of all documentation in the waybill pouch.</li>
				</ul>
				</cfif>
				 Your attention to this matter will be greatly appreciated. Thank you.
				<BR>
				---------------------------------------------------------------------</P>
				<hr><hr>
			</cfmail>
	</cfif>
	</cfif>
</cfloop>
<!--- end of loan code --->

</cfoutput>
<cfinclude template="/includes/_footer.cfm">
