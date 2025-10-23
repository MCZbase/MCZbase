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
		<cfquery name="expEncumbrance" datasource="uam_god">
			select
				ENCUMBRANCE_ID,
				TO_CHAR(EXPIRATION_DATE, 'YYYY-MM-DD') EXPIRATION_DATE,
				EXPIRATION_EVENT,
				ENCUMBRANCE,
				TO_CHAR(MADE_DATE, 'YYYY-MM-DD') MADE_DATE,
				REMARKS,
				ENCUMBRANCE_ACTION,
				AGENT_NAME,
				ADDRESS
				from encumbrance e,
				preferred_agent_name pan,
				(select * from electronic_address where address_type like 'email') ea
				where expiration_date is not null and encumbrance_action like 'mask%'
				and e.ENCUMBERING_AGENT_ID = pan.AGENT_ID
				and e.ENCUMBERING_AGENT_ID = ea.agent_id(+)
				and expiration_date = to_char(sysdate, 'YYYY-MM-DD')
		</cfquery>
		<!--- loop once for each loan --->
		<cfloop query="expEncumbrance">
			<cfset specialmail="">
			<cfif len(expEncumbrance.address) GT 0>
				<cfset toaddresses = expEncumbrance.address>
			<cfelse>
				<cfset specialmail = 'noemails'>
				<cfset toaddresses = "bhaley@oeb.harvard.edu">
			</cfif>

			<cfmail 	to="#toaddresses#"
						bcc="bhaley@oeb.harvard.edu"
						subject="MCZbase Notification for Expiring Encumbrance: #encumbrance#"
						from="no_reply_encumbrance_notification@#Application.fromEmail#"
						replyto="bhaley@oeb.harvard.edu"
						type="html">
				<cfif specialmail EQ "noemails">
					<font color="red">
					<<< MCZbase UNABLE TO SEND THE FOLLOWING ENCUMBRANCE NOTIFICATION >>><br>
	             	<<< ENTER CONTACT EMAILS FOR THIS ENCUMBRANCE >>><br>
					</font>
				</cfif>

				<p>---------------------------------------------------------------------<br>
				MUSEUM OF COMPARATIVE ZOOLOGY<br>
				HARVARD UNIVERSITY<br>
				<br>
				ENCUMBRANCE EXPIRATION NOTIFICATION FOR #DateFormat(Now(),"dd-mmmm-YYYY")#
				<br><br>
				The following encumbrance for which you are the encumbering agent is set to expire today:<br><br>

				https://mczbase.mcz.harvard.edu/Encumbrances.cfm?action=listEncumbrances&encumbrance_id=#encumbrance_id#

				<br><br>

				If you wish to extend the encumbrance, please change the expiration date appropriately. If the encumbrance is expired, please remove the items and delete the encumbrance. Note: the encumberance does not expire automatically. It must be removed or extended manually.
				<br><br>
				Encumbrance: #ENCUMBRANCE#<br>
				Encumbrance Action: #ENCUMBRANCE_ACTION#<br>
				Encumbering Agent: #AGENT_NAME#<br>
				Made Date: #MADE_DATE#<br>
				Expiration Date: #EXPIRATION_DATE#<br>
				Expiration Event: #EXPIRATION_EVENT#<br>
				Remarks: #REMARKS#<br>

				---------------------------------------------------------------------</P>
				<hr><hr>
			</cfmail>
		</cfloop>
	</cfoutput>
<cfinclude template="/includes/_footer.cfm">
