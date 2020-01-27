<!---cfinclude template="/includes/_header.cfm">
	<cfoutput>
		<!--- start of long term loan code --->
		<!---
			Query to get all loan data from the server. Use GOD query so we can ignore collection partitions.
			This form has no output and relies on system time to run, so only danger is in sending multiple copies
			of notification to loan folks. No real risk in not using a lesser agent for the queries.
		--->
		<cfquery name="addresses" datasource="uam_god">
			select distinct
				electronic_address.address,
                country_cde
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
				trans_agent.trans_agent_role in ('additional outside contact', 'for use by', 'received by') and
				LOAN_STATUS like 'open%' and
				loan_type in ('returnable', 'consumable') and
				loan.transaction_id=shipment.transaction_id(+) and
				shipment.shipped_to_addr_id = addr.addr_id(+) and
                lower(addr.country_cde) not in ('us', 'usa', 'united states', 'united states of america', 'u.s.a.') and
                addr.country_cde is not null
				and electronic_address.address is not null
				and electronic_address.address not in
				(select address from intshipping_log)
		</cfquery>

		<!--- loop once for each agent --->
<cfloop query="addresses">

			<cfset mailsubject = "Important information for returning MCZ loans; new international shipping protocols from US Fish and Wildlife Service" >

			<cfmail 	to="#address#"
						bcc="bhaley@oeb.harvard.edu"
						subject="#mailsubject#"
						from="no_reply_loan_notification@#Application.fromEmail#"
						type="html">

				<p>---------------------------------------------------------------------<br>
				MUSEUM OF COMPARATIVE ZOOLOGY<br>
				HARVARD UNIVERSITY<br>
				<br>
				Important information for returning MCZ loans; new international shipping protocols from US Fish and Wildlife Service
				<br><br>
				Dear International Colleague,
				<br><br>
				In order to facilitate proper clearance of international return shipments, a new protocol for the US Fish and Wildlife Service clearance has been initiated to meet federal regulations. Please note that all incoming shipments (e.g., return of MCZ material) must provide the following:<br>
				<ul>
					<li>Notification prior to sending out the shipment 72 hours in advance of the shipment.  The MCZ is required to provide pre-clearance notification to the appropriate port prior to arrival.</li>
					<li>Provide the name of courier (e.g., FedEx, DHL, trackable post), the Airway Bill number and an invoice of contents (Scientific names and number of specimens of each).  This will provide us with the information necessary to file a pre-clearance notification to USFWS.</li>
					<li>All returning international shipments of specimens, should have noted on International Air Waybill the following: "USFWS CLEARANCE REQUIRED". The IATA A180 Special Provision should also be noted there if applicable.</li>
					<li>All packages should be marked boldly and in red "USFWS CLEARANCE REQUIRED" on all sides of the outside of package.</li>
					<li>Include three copies of all documentation in Airway Bill pocket.</li>
				</ul>
				Thank you for your help in these matters and to ensure that research material does not get delayed or confiscated during shipment.<br><br>
				If you have any questions or need more info, please reach out to the MCZ contact on your loan paperwork or write to MCZ_collections_operations@oeb.harvard.edu
				<br><br>

				<!---cfquery name="upLogTable" datasource="uam_god">
					insert into LOAN_REMINDER_LOG(agent_id, date_sent, transaction_id, reminder_type, TOADDRESSES)
					values(#agent.agent_id#, SYSDATE, #transaction_id#, 'L', <cfif specialmail NEQ "noemails">'#toaddresses#'<cfelse>'noemails'</cfif>)
				</cfquery--->

				<p>---------------------------------------------------------------------</P>
				<hr><hr>
			</cfmail>

				<cfquery name="upLogTable" datasource="uam_god">
					insert into intshipping_log(address, date_sent)
					values('#address#', SYSDATE)
				</cfquery>

</cfloop>
<!--- end of loan code --->

</cfoutput>
<cfinclude template="/includes/_footer.cfm"--->
