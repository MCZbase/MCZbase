<cfif len(#CGI.HTTP_REFERER#) is 0 OR #CGI.HTTP_REFERER# does not contain #Application.ServerRootUrl#>
	Illegal use of form.
	<cfabort>
</cfif>
<cfinclude template="/includes/_header.cfm">
<cfif #Action# is "nothing">
<cfset title="Report Data Problems">
<h2>Report Data Errors</h2>
<table>
<tr>
	<td colspan="2">
		All fields are optional. 
		<br>Include your email address if you would like us to contact you when the issue you submit has been addressed. 
		Your email address will <b>not</b> be released or publicly displayed on our site.
		<br>Scroll down to view the data you are reporting.
	</td>
</tr>

<cfif isdefined("collection_object_id")>
	<!--- get summary data ---->
	<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select 
			cataloged_item.collection_object_id id,
			scientific_name, 
			cat_num, 
			collection.collection, 
			higher_geog,
			spec_locality
		FROM
			cataloged_item,
			identification,
			collection,
			collecting_event,
			locality,
			geog_auth_rec
		WHERE
			cataloged_item.collection_object_id = identification.collection_object_id AND
			identification.accepted_id_fg = 1 AND
			cataloged_item.collection_id = collection.collection_id AND
			cataloged_item.collecting_event_id = collecting_event.collecting_event_id AND
			collecting_event.locality_id = locality.locality_id AND
			locality.geog_auth_rec_id = geog_auth_rec.geog_auth_rec_id AND
			cataloged_item.collection_object_id IN (#collection_object_id#)
	</cfquery>
</cfif>
<cfoutput>
	<form name="bug" method="post" action="reportBadData.cfm">
		<input type="hidden" name="action" value="save">
		<tr>
			<td valign="top">
				<strong>Name:</strong>&nbsp;<input type="text" name="reported_name" size="20">
				&nbsp;&nbsp;&nbsp;
				<strong>Email:</strong>&nbsp;<input type="text" name="user_email" size="30">
			</td>
		</tr>
		
		<tr>
			<td>
				<strong>Problem:</strong><br>
				<textarea name="suggested_solution" rows="6" cols="100"></textarea>		
			</td>
		</tr>
		
		<tr>
			<td>
				<strong>Remarks:</strong><br>
				<textarea name="user_remarks" rows="6" cols="100"></textarea></td>
		</tr>
		<tr>
			
			<td align="center">
				<input type="submit" value="Submit Report" class="insBtn">	
			</td>
		</tr>
		<tr>
			<td>
			The following records will be reported. Uncheck any which you do not wish to include:<br>
			<a href="#Application.ServerRootUrl#/SpecimenResults.cfm?collection_object_id=#collection_object_id#">
			View All Specimens</a>
			
				<table border>
					<tr>
						<td nowrap align="center"><strong>Report</strong></td>
						<td nowrap align="center"><strong>Catalog Number</strong></td>
						<td nowrap align="center"><strong>Scientific Name</strong></td>
						<td nowrap align="center"><strong>Higher Geog</strong></td>
						<td nowrap align="center"><strong>Locality</strong></td>
					</tr>
				<cfloop query="data">
					<tr>
						<td>
							<input type="checkbox" name="newCollObjId" value="#id#" checked>
						</td>
						<td>
							<a href="#Application.ServerRootUrl#/SpecimenDetail.cfm?collection_object_id=#id#">#collection# #cat_num#</a>
					    </td>
						<td>#scientific_name#</td>
						<td>#higher_geog#</td>
						<td>#spec_locality#</td>
					</tr>
				</cfloop>
				</table>
			</td>
		</tr>
	</form>
	</cfoutput>
</table>
</cfif>
<!------------------------------------------------------------>
<cfif action is "save">

    <cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
        select 
            guid
        FROM
            flat
        WHERE
            collection_object_id IN (#collection_object_id#)
    </cfquery>
    <cfset guids = "">
    <cfset recordCount = 0>
    <cfloop query="data">
        <cfset recordCount = recordCount + 1>
        <cfset guids = guids + " " + data.guid>
    </cfloop>

<cfoutput>
<cfset user_id=0>
<cfif isdefined("session.username") and len(session.username) gt 0>
	<cfquery name="isUser" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		SELECT user_id FROM cf_users WHERE username = '#session.username#'
	</cfquery>
	<cfset user_id = isUser.user_id>
</cfif>
	<cfquery name="bugID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select max(bug_id) + 1 as id from cf_bugs
	</cfquery>
	<!--- strip out the crap....--->
	<cfset badStuff = "---a href,---script,[link,[url">
	<cfset concatSub = "#reported_name# #suggested_solution# #user_remarks# #user_email#">
	<cfset concatSub = replace(concatSub,"#chr(60)#","---","all")>
	
	<cfif #ucase(concatSub)# contains "invalidTag">
			Bug reports may not contain markup or script.
			<cfabort>
		</cfif>
	<cfloop list="#badStuff#" index="i">
		<cfif #ucase(concatSub)# contains #ucase(i)#>
			Bug reports may not contain markup or script.
			<cfabort>
		</cfif>
	</cfloop>
	<cfquery name="newBug" datasource="cf_dbuser">
		INSERT INTO cf_bugs (
			bug_id,
			user_id,
			reported_name,
			complaint,
			suggested_solution,
			user_remarks,
			user_email,
			submission_date)
		VALUES (
			#bugID.id#,
			#user_id#,
			'#reported_name#',
			'<a href="#Application.ServerRootUrl#/SpecimenResults.cfm?collection_object_id=#newCollObjId#">Specimens</a>',
			'#suggested_solution#',
			'#user_remarks#',
			'#user_email#',
			sysdate)				
	</cfquery>
	
	<!--- get the proper emails to report this to --->
    <!--- As of July 2018, MCZbase does not have any entries in collection_contacts for 'data quality'.  --->
    <!--- Issue reports are expected to be filtered through collections operations to relevant collections staff --->
	<cfquery name="whatEmails" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select address from
			electronic_address,
			collection_contacts,
			cataloged_item
		WHERE
			electronic_address.agent_id = collection_contacts.contact_agent_id AND
			collection_contacts.collection_id = cataloged_item.collection_id AND
			address_type='e-mail' AND
			contact_role='data quality' AND
			cataloged_item.collection_object_id IN (#newCollObjId#)
		GROUP BY address
	</cfquery>
	<cfset thisAddress = #Application.DataProblemReportEmail#><!--- always send data problems to SOMEONE, even if we don't 
		find additional contacts --->
	<cfloop query="whatEmails">
		<cfset thisAddress = "#thisAddress#,#address#">
	</cfloop>
	
	<cfmail to="#thisAddress#" subject="Arctos Bad Data Report" from="BadData@#Application.fromEmail#" type="html">
		<p>Reported Name: #reported_name# (Username: #session.username#) submitted a data report.</p>
		
		<p><a href="#Application.ServerRootUrl#/SpecimenResults.cfm?collection_object_id=#newCollObjId#">Specimens</a></p>
		
		<P>Solution: #suggested_solution#</P>
		
		<P>Remarks: #user_remarks#</P>
		
		<P>Email: #user_email#</P>
	</cfmail>

     <!--- create a bugzilla bug from the bad data report --->
    <cfset summary=left(#complaint#,60)><!--- obtain the begining of the complaint as a bug summary --->
        <cfset bugzilla_mail="#Application.bugzillaToEmail#"><!--- address to access email_in.pl script --->
        <!--cfset bugzilla_user="#Application.bugzillaToEmail#"--><!--- bugs submitted by email can only come from a registered bugzilla user --->
        <!--cfset bugzilla_user="test@example.com"--><!-- bugzilla user for testing integration as bugreport@software can have alias resolution problems -->
        <cfset bugzilla_user="#Application.bugzillaFromEmail#"><!--- bugs submitted by email can only come from a registered bugzilla user --->
        <cfset bugzilla_component="Data">
        <cfset bugzilla_priority="@priority = P3">
        <cfset bugzilla_severity="@bug_severity = normal">
        <cfset newline= Chr(13) & Chr(10)>
        <cfmail to="#bugzilla_mail#" subject="#summary#" from="#bugzilla_user#" type="text">@rep_platform = PC
@op_sys = Linux
@product = MCZbase
@component = Data
@version = 2.5.1merge
#bugzilla_priority##newline#
#bugzilla_severity#

Bug report by: #reported_name# (Username: #session.username#)
Email: #user_email#
Complaint: #complaint#
SpecimenRecords: #guids#
#newline##newline#
        </cfmail>


	<div align="center">Your report has been successfully submitted.</div>
	<P align="center">Thank you for helping to improve the quality of our data.</p>
	<p align="center">
		Click <a href="/SpecimenResults.cfm?collection_object_id=#newCollObjId#">here</a> to return to your search results.
	</p>
	<p align="center">
		Click <a href="/SpecimenSearch.cfm">here</a> to return to a new Specimen search.
	</p>
</cfoutput>
</cfif>
<cfinclude template="/includes/_footer.cfm">
