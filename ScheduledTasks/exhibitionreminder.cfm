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
				round(RETURN_DUE_DATE - (sysdate)) + 1 as numdays
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
				trans_agent.trans_agent_role in ('in-house contact',  'additional in-house contact', 'additional outside contact', 'for use by', 'received by','recipient institution') and
				round(RETURN_DUE_DATE - (sysdate)) + 1 in (-365,-180,-150,-120,-90,-60,-30,-7,0,30) and
				LOAN_STATUS like 'open%' and
				loan_type in ('exhibition-master') and
				loan.transaction_id=shipment.transaction_id(+) and
				shipment.shipped_to_addr_id = addr.addr_id(+)
		</cfquery>
		<!--- local query to organize and flatten loan data --->
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
				numdays
			from
				expLoan
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
					trans_agent_role in ('in-house contact', 'additional in-house contact') and
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
					trans_agent_role in ('additional outside contact', 'for use by', 'received by') and
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
			<cfquery name="recipInst" dbtype="query">
				select
					agent_name
				from
					expLoan
				where
					transaction_id=#transaction_id# and
					trans_agent_role = 'recipient institution'
				group by
					agent_name
			</cfquery>
			<cfquery name="subLoans" datasource="uam_god">
			select distinct
				loan.transaction_id,
				loan.LOAN_NUMBER,
				loan.loan_type,
				loan.loan_status
			from
				loan_relations, loan
			where
				loan_relations.transaction_id = #transaction_id# and
				loan_relations.RELATED_TRANSACTION_ID = loan.transaction_id
		</cfquery>
			<!--- the "contact if" section of the form we'll send to notification agents --->
			<!---cfsavecontent variable="contacts">
				<p>
					<cfif inhouseAgents.recordcount is 1>
						<!--- there is one in-house contact --->
						Contact #inhouseAgents.agent_name# at #inhouseAgents.address# with any questions or concerns.
					<cfelseif inhouseAgents.recordcount gt 1>
						<!--- there are multiple in-house contacts --->
						Contact the following with any questions or concern:
						<ul>
						<cfloop query="inhouseAgents">
							<li>#agent_name#: #address#</li>
						</cfloop>
						</ul>
					<cfelseif collectionAgents.recordcount is 1>
						<!--- there are no in-house contacts, but there is one "loan request" agent for the collection --->
						Contact #collectionAgents.agent_name# at #collectionAgents.address# with any questions or concerns.
					<cfelseif collectionAgents.recordcount gt 1>
						<!--- there are no in-house contacts, but there are multipls "loan request" agents for the collection --->
						Contact the following with any questions or concern:
						<ul>
						<cfloop query="collectionAgents">
							<li>#agent_name#: #address#</li>
						</cfloop>
						</ul>
					<cfelse>
						<!--- there are no curatorial contacts given - send them to the MCZbase contact form --->
						Please contact the MCZbase folks with any questions or concerns by visiting
						<a href="#application.serverRootUrl#/contact.cfm">#application.serverRootUrl#/contact.cfm</a>
					</cfif>
				</p>
			</cfsavecontent>
			<!--- the data we'll send to everyone --->
			<cfsavecontent variable="common">
				<p>The nature of the loaned material is:
					<blockquote>#loan.nature_of_material#</blockquote>
				</p>
				<p>Specimen data for this loan, unless restricted, may be accessed at
					<a href="#application.serverRootUrl#/SpecimenResults.cfm?collection_id=#loan.collection_id#&loan_number=#loan.loan_number#">
						#application.serverRootUrl#/SpecimenResults.cfm?collection_id=#loan.collection_id#&loan_number=#loan.loan_number#
					</a>
				</p>
			</cfsavecontent--->
			<!---cfif notificationAgents.recordcount gt 0 and expires_in_days gte 0>

				<!---
					there's at least one noticifation agent, and the loan expires on or after today
					Loop through the list of notification agents and email each of them. Blind copy
					Dusty for a while, since it's pretty much impossible to actually test a form that
					sends email and something somewhere is probably misspelled or something
				 --->
				<cfloop query="notificationAgents">
					<cfmail to="#address#" bcc="bhaley@oeb.harvard.edu"
						subject="MCZbase Loan Notification" from="loan_notification@#Application.fromEmail#" type="html">
						Dear #agent_name#,
						<p>
							You are receiving this message because you are listed as a contact for loan
							#loan.collection# #loan.loan_number#, due date #loan.return_due_date#.
						</p>
						#contacts#<!--- from cfsavecontent above ---->
						#common#<!--- from cfsavecontent above ---->
					</cfmail>
				</cfloop>
			</cfif>
			<!--- and an email for each in-house contact --->
			<cfloop query="inhouseAgents">
				<cfmail to="#address#" bcc="bhaley@oeb.harvard.edu"
					subject="MCZbase Loan Notification" from="loan_notification@#Application.fromEmail#" type="html">
					Dear #agent_name#,
					<p>
						You are receiving this message because you are listed as in-house contact for loan
						#loan.collection# #loan.loan_number#, due date #loan.return_due_date#.
					</p>
					<p>
						You may edit the loan, after signing in to MCZbase, at
						<a href="#application.serverRootUrl#/transactions/Loan.cfm?Action=editLoan&transaction_id=#loan.transaction_id#">
							#application.serverRootUrl#/transactions/Loan.cfm?Action=editLoan&transaction_id=#loan.transaction_id#
						</a>
					</p>
					#common#
				</cfmail>
			</cfloop>
			<cfif expires_in_days lte 0>
				<!--- the loan expires on or BEFORE today; also email the collection's loan request agent, if there is one --->
				<cfloop query="collectionAgents">
					<cfmail to="#address#" bcc="bhaley@oeb.harvard.edu"
						subject="MCZbase Loan Notification" from="loan_notification@#Application.fromEmail#" type="html">Dear #agent_name#,
						<p>
							You are receiving this message because you are listed as a #loan.collection# loan request collection contact.
							Loan #loan.collection# #loan.loan_number# due date #loan.return_due_date# is not listed as "closed."
						</p>
						<p>
							You may edit the loan, after signing in to MCZbase, at
							<a href="#application.serverRootUrl#/transactions/Loan.cfm?Action=editLoan&transaction_id=#loan.transaction_id#">
								#application.serverRootUrl#/transactions/Loan.cfm?Action=editLoan&transaction_id=#loan.transaction_id#
							</a>
						</p>
						#common#
					</cfmail>
				</cfloop>
			</cfif--->
			<cfset specialmail="">
			<cfif loan.loan_status EQ "open under-review">
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
						subject="MCZbase Notification for Exhibition Loan Number: #loan.loan_number#"
						from="no_reply_loan_notification@#Application.fromEmail#"
						replyto="#ValueList(inhouse.address,";")#"
						type="html">
				<cfif specialmail EQ "noemails">
					<font color="red">
					<<< MCZbase UNABLE TO SEND THE FOLLOWING LOAN NOTIFICATION >>><br>
	             	<<< ENTER EXTERNAL CONTACTS FOR THIS LOAN  >>><br>
					</font>
				<cfelseif specialmail EQ "underreview">
					<font color="red">
					<<< MCZbase UNABLE TO SEND THE FOLLOWING LOAN NOTIFICATION &mdash; LOAN "OPEN UNDER-REVIEW" >>><br>
             		<<< ENTER EXTERNAL CONTACTS FOR THIS LOAN. ORIGINAL BORROWER IS NOT VALID >>><br>
					</font>
				</cfif>

				<p>---------------------------------------------------------------------<br>
				MUSEUM OF COMPARATIVE ZOOLOGY<br>
				HARVARD UNIVERSITY<br>
				<br>
				LOAN NOTIFICATION REPORT FOR #DateFormat(Now(),"dd-mmmm-YYYY")#
				<br><br>
				Dear Colleague,
				<br><br>
				<cfif numdays EQ 30>
				This is	a friendly reminder that your MCZ Exhibition loan (#loan.loan_number#) is due for RETURN to the following MCZ Collection<cfif #subLoans.recordcount# GT 1>s</cfif> in about a month.
				<cfelse>
				This is an MCZbase notification report regarding an MCZ Exhibition loan (#loan.loan_number#) due for RETURN to the following MCZ Collection<cfif #subLoans.recordcount# GT 1>s</cfif>.
				</cfif>
				<br><br>
				#nature_of_material#
				<br><br>
				LOAN<cfif #subLoans.recordcount# GT 1>S</cfif> DUE TO BE RETURNED:
				<br><br>
				<cfset lines = 0>
				<cfloop query="subLoans">
					<cfquery name="counts" datasource="uam_god">
						select
							sum(coll_object.lot_count) total, sum(decode(coll_object.coll_obj_disposition, 'on loan', coll_object.lot_count, 0)) outstanding
						from
							loan, loan_item, coll_object
						where
							loan.transaction_id=#subLoans.transaction_id# and
							loan.transaction_id = loan_item.transaction_id and
							loan_item.collection_object_id = coll_object.collection_object_id
						group by
							loan.transaction_id
					</cfquery>
				<cfif lines EQ 1>------<br></cfif>
				Loan Number: #subLoans.loan_number#
				<br>
				Loan Date: #DateFormat(loan.trans_date, "dd-mmmm-YYYY")#
				<br>
				Due Date: #DateFormat(loan.return_due_date, "dd-mmmm-YYYY")#
				<br>
				Original Total Number of Items:	#counts.total#
				<br>
				Partial Return of Loaned Items: <cfif subLoans.loan_status EQ "open partially returned">Yes<cfelse>No</cfif>
				<br>
				<cfset lines = 1>
				</cfloop>
				<br>
				Approved Borrower: #receivedby.agent_name#
				<br>
				Recipient Institution: #recipInst.agent_name#
				<br>
				<br>
				Shipped to:<br>
				#formatted_addr#
				<br>
				<!---cfif len(#ValueList(forUseBy.agent_name)#) GT 0 >
				For Use By:	#ValueList(forUseBy.agent_name)#
				<br>
				</cfif--->
				<br>
				<cfif numdays EQ 30>
				Please return the above loan by the Due Date. If for any reason this is not possible, or for more information on this loan, please
				<cfelse>
				We request that you please return the above loan or request an extension by the Due Date. For more information on this loan,
				</cfif>
				contact MCZ Collections Operations (#ValueList(inhouse.address)#). Your attention to this matter will be greatly appreciated. Thank you.
				<BR>
				---------------------------------------------------------------------</P>
			</cfmail>

			<!---cfif specialmail EQ "">
					<cfquery name="upLogTable" datasource="uam_god">
						insert into LOAN_REMINDER_LOG(agent_id, date_sent, transaction_id, reminder_type, TOADDRESSES)
						values(#receivedBy.agent_id#, SYSDATE, #loan.transaction_id#, 'E', '#toaddresses#')
					</cfquery>
			</cfif--->
		</cfloop>
		<!--- end of loan code --->

	</cfoutput>
<cfinclude template="/includes/_footer.cfm">
