<cfinclude template="/includes/_header.cfm">
	<cfoutput>
		<!--- start of loan code --->
		<!--- days after and before return_due_date on which to send email. Negative is after ---->
		<cfset eid="-365,-180,-150,-120,-90,-60,-30,-7,0,30">
		<!---
			Query to get all loan data from the server. Use GOD query so we can ignore collection partitions.
			This form has no output and relies on system time to run, so only danger is in sending multiple copies
			of notification to loan folks. No real risk in not using a lesser agent for the queries.
		--->
		<cfquery name="expLoan" datasource="uam_god">
			select
				borrow.transaction_id,
				BORROW_NUMBER,
				lender_loan_type,
				borrow_status,
				trans_date,
				due_date,
				electronic_address.address,
				round(DUE_DATE - sysdate)+1 expires_in_days,
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
				round(DUE_DATE - (sysdate)) + 1 as numdays
			FROM
				borrow,
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
				borrow.transaction_id = trans.transaction_id AND
				trans.collection_id=collection_contacts.collection_id (+) and
				trans.collection_id=collection.collection_id and
				collection_contacts.contact_agent_id=nnName.agent_id (+) and
				collection_contacts.contact_agent_id=nnAddr.agent_id (+) and
				trans.transaction_id=trans_agent.transaction_id and
				trans_agent.agent_id = preferred_agent_name.agent_id AND
				trans_agent.agent_id = person.person_id(+) AND
				preferred_agent_name.agent_id = electronic_address.agent_id(+) AND
				/*trans_agent.trans_agent_role in ('in-house contact',  'additional in-house contact', 'additional outside contact', 'for use by', 'received by') and*/
				round(DUE_DATE - (sysdate)) + 1 in (-365,-180,-150,-120,-90,-60,-30,-7,0,30) and
				BORROW_STATUS <> 'returned' and
				/*loan_type in ('returnable', 'consumable') and*/
				borrow.transaction_id=shipment.transaction_id(+) and
				shipment.shipped_to_addr_id = addr.addr_id(+) and
				(shipment.print_flag is null or shipment.print_flag = 1)
		</cfquery>
		<!--- local query to organize and flatten loan data --->
		<cfquery name="loan" dbtype="query">
			select
				transaction_id,
				BORROW_NUMBER,
				lender_loan_type,
				borrow_status,
				trans_date,
				due_date,
				expires_in_days,
				collection,
				nature_of_material,
				collection_id,
				formatted_addr,
				numdays
			from
				expLoan
			group by
				transaction_id,
				BORROW_NUMBER,
				lender_loan_type,
				borrow_status,
				trans_date,
				due_date,
				expires_in_days,
				collection,
				nature_of_material,
				collection_id,
				formatted_addr,
				numdays
		</cfquery>
		<!--- loop once for each loan --->
		<cfloop query="loan">
			<!--- local queries to organize and flatten loan data --->
			<cfquery name="cc_Agents" dbtype="query">
				select
					address,
					agent_name
				from
					expLoan
				where
					transaction_id=#transaction_id# and
					trans_agent_role in ('received by') and
					address is not null
				group by
					address,
					agent_name
			</cfquery>
			<cfquery name="inhouse" dbtype="query">
				select
					address,
					agent_name
				from
					expLoan
				where
					transaction_id=#transaction_id# and
					trans_agent_role in ('in-house contact') and
					address is not null
				group by
					address,
					agent_name
			</cfquery>
			<cfquery name="to_agents" dbtype="query">
				select
					address,
					agent_name
				from
					expLoan
				where
					transaction_id=#transaction_id# and
					trans_agent_role in ('in-house contact', 'for use by', 'additional in-house contact') and
					address is not null
				group by
					address,
					agent_name
			</cfquery>
			<cfquery name="collectionAgents" dbtype="query">
				select
					collection_agent_name agent_name,
					collection_email address
				from
					expLoan
				where
					transaction_id=#transaction_id# and
					collection_email is not null
				group by
					collection_agent_name,
					collection_email
			</cfquery>
			<cfquery name="receivedBy" dbtype="query">
				select
					agent_id,
					last_name,
					first_name,
					agent_name
				from
					expLoan
				where
					transaction_id=#transaction_id# and
					trans_agent_role = 'received by'
				group by
					agent_id,
					last_name,
					first_name,
					agent_name
			</cfquery>
			<cfquery name="forUseBy" dbtype="query">
				select
					last_name,
					first_name,
					agent_name
				from
					expLoan
				where
					transaction_id=#transaction_id# and
					trans_agent_role = 'for use by'
				group by
					last_name,
					first_name,
					agent_name
			</cfquery>

			<cfset specialmail="">
			<cfif loan.borrow_status EQ "open under-review">
				<cfset toaddresses = ValueList(cc_agents.address,";")>
				<cfset ccaddresses = "">
				<cfset specialmail="underreview">
			<cfelseif to_agents.recordcount EQ 0>
				<cfset toaddresses = ValueList(cc_agents.address,";")>
				<cfset ccaddresses = "">
				<cfset specialmail="noemails">
			<cfelse>
				<cfset toaddresses = ValueList(to_agents.address,";")>
				<cfset ccaddresses = ValueList(cc_agents.address,";")>
			</cfif>

			<cfmail 	<!---to="bhaley@oeb.harvard.edu;heliumcell@gmail.com"--->
						to="#toaddresses#"
						cc="#ccaddresses#"
						bcc="bhaley@oeb.harvard.edu"
						subject="MCZbase Notification for Borrow Number: #loan.borrow_number#"
						from="no_reply_borrow_notification@#Application.fromEmail#"
						replyto="#ValueList(inhouse.address,";")#"
						type="html">
				<cfif specialmail EQ "noemails">
					<font color="red">
					<<< MCZbase UNABLE TO SEND THE FOLLOWING BORROW NOTIFICATION >>><br>
	             	<<< ENTER IN-HOUSE CONTACTS FOR THIS BORROW  >>><br>
					</font>
				<cfelseif specialmail EQ "underreview">
					<font color="red">
					<<< MCZbase UNABLE TO SEND THE FOLLOWING BORROW NOTIFICATION &mdash; BORROW "OPEN UNDER-REVIEW" >>><br>
             		<<< ENTER IN-HOUSE CONTACTS CONTACTS FOR THIS BORROW. ORIGINAL BORROWER IS NOT VALID >>><br>
					</font>
				</cfif>

				<p>---------------------------------------------------------------------<br>
				MUSEUM OF COMPARATIVE ZOOLOGY<br>
				HARVARD UNIVERSITY<br>
				<br>
				BORROW NOTIFICATION REPORT FOR #DateFormat(Now(),"DD-mmmm-YYYY")#
				<br><br>
				Dear Colleague,
				<br><br>
				<cfif numdays EQ 30>
				This is	a friendly reminder that your Borrow is due for RETURN in about a month.
				<cfelse>
				This is an MCZbase notification report regarding an MCZ Borrow due for RETURN.
				</cfif>
				<br><br>
				BORROW DUE TO BE RETURNED:
				<br><br>
				Borrow Number: #borrow_number#
				<br>
				Borrow Type: #lender_loan_type#
				<br>
				Borrow Date: #DateFormat(trans_date, "DD-mmmm-YYYY")#
				<br>
				Due Date: #DateFormat(due_date, "DD-mmmm-YYYY")#
				<br><br>

				Approved Borrower: #receivedby.agent_name#
				<br>
				<br>
				Shipped to:<br>
				#formatted_addr#
				<br>
				<cfif len(#ValueList(forUseBy.agent_name)#) GT 0 >
				For Use By:	#ValueList(forUseBy.agent_name)#
				<br>
				</cfif>
				<br>
				Nature of Material: #nature_of_material#
				<br>
				Partial Return of Borrowed Items: <cfif borrow_status EQ "open partially returned">Yes<cfelse>No</cfif>
				<br><br>
				<cfif numdays EQ 30>
				Please return the above Borrow by the Due Date. If for any reason this is not possible, or for more information on this borrow, please
				<cfelse>
				We request that you please return the above Borrow or request an extension by the Due Date. For more information on this Borrow,
				</cfif>
				contact the institution from which the Borrow was received.  Your attention to this matter will be greatly appreciated.
				Thank you.<br>
				---------------------------------------------------------------------</P>
				<hr><hr>
			</cfmail>
		</cfloop>
		<!--- end of loan code --->
		<!----------- permit ------------
		<cfset cInt = "365,180,30,0">
		<cfloop list="#cInt#" index="inDays">
			<cfquery name="permitExpOneYear" datasource="uam_god">
				select
					permit_id,
					EXP_DATE,
					PERMIT_NUM,
					ADDRESS,
					round(EXP_DATE - sysdate) expires_in_days,
					EXP_DATE,
					CONTACT_AGENT_ID
				FROM
					permit,
					electronic_address
				WHERE
					permit.CONTACT_AGENT_ID = electronic_address.agent_id AND
					ADDRESS_TYPE='email' AND
					round(EXP_DATE - sysdate) = #inDays#
			</cfquery>
			<cfquery name="expYearID" dbtype="query">
				select CONTACT_AGENT_ID from permitExpOneYear group by CONTACT_AGENT_ID
			</cfquery>
			<cfloop query="permitExpOneYear">
				<cfquery name="permitExpOneYearnames" dbtype="query">
					select ADDRESS from permitExpOneYear where CONTACT_AGENT_ID=#permitExpOneYear.CONTACT_AGENT_ID#
					group by ADDRESS
				</cfquery>
				<cfquery name="permitExpOneYearIndiv" dbtype="query">
					select * from permitExpOneYear where CONTACT_AGENT_ID=#CONTACT_AGENT_ID# order by expires_in_days
				</cfquery>
				<cfmail to="#permitExpOneYearnames.ADDRESS#" subject="Expiring Permits" from="reminder@#Application.fromEmail#" type="html">
					You are receiving this message because you are the contact person for the permits listed below, which are expiring.
					<p>
						<cfloop query="permitExpOneYearIndiv">
							<a href="#Application.ServerRootUrl#/transactions/Permit.cfm?action=search&execute=true&permit_id=#permit_id#">Permit##: #PERMIT_NUM#</a> expires on #dateformat(exp_date,'yyyy-mm-dd')# (#expires_in_days# days)<br>
						</cfloop>
					</p>
				</cfmail>
			</cfloop>
		</cfloop>
		<!---- year=old accessions with no specimens ---->
		<cfquery name="yearOldAccn" datasource="uam_god">
			select
				accn.transaction_id,
				collection.collection,
				collection.collection_id,
				accn_number,
				to_char(RECEIVED_DATE,'yyyy-mm-dd') received_date
			from
				accn,
				trans,
				collection,
				cataloged_item
			where
				accn.transaction_id=trans.transaction_id and
				trans.collection_id=collection.collection_id and
				accn.transaction_id=cataloged_item.accn_id (+) and
				cataloged_item.accn_id is null and
				to_char(sysdate,'DD-Mon')=to_char(RECEIVED_DATE,'DD-Mon') and
				to_char(sysdate,'YYYY')-to_char(RECEIVED_DATE,'YYYY')>=1
		</cfquery>
		<cfquery name="colns" dbtype="query">
			select collection,collection_id from yearOldAccn group by collection,collection_id
		</cfquery>
		<cfloop query="colns">
			<cfquery name="contact" datasource="uam_god">
				select
					electronic_address.address
				from
					(select * from electronic_address where address_type='email') electronic_address,
					(select * from collection_contacts where contact_role='data quality') collection_contacts
				where
					collection_contacts.CONTACT_AGENT_ID=electronic_address.AGENT_ID and
					collection_contacts.collection_id=#collection_id#
			</cfquery>
			<cfquery name="data" dbtype="query">
				select
					transaction_id,
					collection,
					accn_number,
					received_date
				from
					yearOldAccn
				where collection_id=#collection_id#
				group by
					transaction_id,
					collection,
					accn_number,
					received_date
			</cfquery>
			<cfmail to="#valuelist(contact.ADDRESS)#" bcc="bhaley@oeb.harvard.edu" subject="Bare Accession" from="bare_accession@#Application.fromEmail#" type="html">
				You are receiving this message because you are the data quality contact for collection #collection#.
				<p>
					The following accessions are one or more years old and have no specimens attached.
				</p>
				<p>
					<cfloop query="data">
						<a href="#Application.ServerRootUrl#/transactions/Accession.cfm?action=edit&transaction_id=#transaction_id#">
							#collection# #accn_number#
						</a>
						<br>
					</cfloop>
				</p>
			</cfmail>


		</cfloop--->

	</cfoutput>
<cfinclude template="/includes/_footer.cfm">
