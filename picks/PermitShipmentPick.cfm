<cfset jquery11=true>
<cfinclude template="../includes/_pickHeader.cfm">
<cfset title = "Permit Pick">
<cfquery name="ctPermitType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	select ct.permit_type, count(p.permit_id) uses from ctpermit_type ct left join permit p on ct.permit_type = p.permit_type 
        group by ct.permit_type 
        order by ct.permit_type
</cfquery>
<cfquery name="ctSpecificPermitType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
        select ct.specific_type, count(p.permit_id) uses from ctspecific_permit_type ct left join permit p on ct.specific_type = p.specific_type
        group by ct.specific_type
        order by ct.specific_type
</cfquery>
<cfoutput>
<script type='text/javascript' src='/includes/transAjax.js'></script>

<cfif not isdefined("IssuedByAgent")><cfset IssuedByAgent=""></cfif>
<cfif not isdefined("IssuedToAgent")><cfset IssuedToAgent=""></cfif>
<cfif not isdefined("permit_type")><cfset permit_type=""></cfif>
<cfif not isdefined("permit_title")><cfset permit_title=""></cfif>
<cfif not isdefined("specific_type")><cfset specific_type=""></cfif>
<cfif not isdefined("issued_Date")><cfset issued_Date=""></cfif>
<cfif not isdefined("renewed_Date")><cfset renewed_Date=""></cfif>
<cfif not isdefined("exp_Date")><cfset exp_Date=""></cfif>
<cfif not isdefined("permit_Num")><cfset permit_Num=""></cfif>
<cfif not isdefined("permit_remarks")><cfset permit_remarks=""></cfif>
<cfif isdefined("permit_type")><cfset permit_type_val="#permit_type#"></cfif>
<cfif isdefined("permit_title")><cfset permit_title_val="#permit_title#"></cfif>
<cfif isdefined("specific_type")><cfset specific_type_val="#specific_type#"></cfif>

Search for permits. Any part of names accepted, year or full date for dates, case isn't important.<br>
<cfform name="findPermit" action="PermitShipmentPick.cfm" method="post" id="findPermitForm">
	<input type="hidden" name="Action" value="search">
	<input type="hidden" name="shipment_id" value="#shipment_id#">
	<table>
		<tr>
			<td>Issued By</td>
			<td><input type="text" name="IssuedByAgent" value="#IssuedByAgent#"></td>
			<td>Issued To</td>
			<td><input type="text" name="IssuedToAgent" value="#IssuedToAgent#"></td>
			
			
		</tr>
		<tr>
			<td>Issued Date</td>
			<td><input type="text" name="issued_Date" value="#issued_Date#"></td>
			<td>Renewed Date</td>
			<td><input type="text" name="renewed_Date" value="#renewed_Date#"></td>
		</tr>
		<tr>
			<td>Expiration Date</td>
			<td><input type="text" name="exp_Date" value="#exp_Date#"></td>
			<td>Permit Number</td>
			<td><input type="text" name="permit_Num" id="permit_Num" value="#permit_Num#" ></td>
		</tr>
		<tr>
			<td>Permit Type</td>
			<td>
				<select name="permit_Type" size="1" id="permit_type" style="width: 15em;">
					<option value=""></option>
					<cfloop query="ctPermitType">
                                                <cfif permit_type_val EQ ctPermitType.permit_type><cfset selected='selected'><cfelse><cfset selected=''></cfif>
						<option value = "#ctPermitType.permit_type#" #selected#>#ctPermitType.permit_type# (#ctPermitType.uses#)</option>
					</cfloop>
				
				</select>
			</td>
			<td>Remarks</td>
			<td><input type="text" name="permit_remarks" value="#permit_remarks#"></td>
		</tr>
		<tr>
			<td>Specific Type</td>
			<td>
				<select name="specific_type" size="1" style="width: 15em;">
					<option value=""></option>
					<cfloop query="ctSpecificPermitType">
                                                <cfif specific_type_val EQ ctSpecificPermitType.specific_type><cfset selected='selected'><cfelse><cfset selected=''></cfif>
						<option value = "#ctSpecificPermitType.specific_type#" #selected#>#ctSpecificPermitType.specific_type# (#ctSpecificPermitType.uses#)</option>
					</cfloop>
				
				</select>
			</td>
			<td>Permit Title</td>
			<td><input type="text" name="permit_title" value="#permit_title_val#"></td>
		</tr>
		<tr>
			<td></td>
			<td>
			   <input type="submit" value="Search" class="schBtn">	
                           <script> 
                              function findPermitFormReset() { 
   			           $('##findPermitForm').find('input[type=text]').val('');
   			           $('##permit_type option').prop('selected',false);
                              };
                           </script>
   			   <input type="button" value="Clear" class="clrBtn" onclick=" findPermitFormReset(); ">
			</td>
            	`	<td>
		    	</td>
			<td>
				<a href="/transactions/Permit.cfm?action=new" target="_blank">Create New Permissions and Rights Document</a>
          </td>
		</tr>
	</table>
	
	
	
</cfform>
</cfoutput>
<cfif Action is "search">

<!--- set dateformat --->

<cfset sql = "select permit.permit_id,
	issuedByPref.agent_name IssuedByAgent,
	issuedToPref.agent_name IssuedToAgent,
	issued_Date,
	renewed_Date,
	exp_Date,
	permit_Num,
	permit_Type,
        specific_type,
        permit_title,
	permit_remarks 
from 
	permit,
	preferred_agent_name issuedToPref,
	preferred_agent_name issuedByPref,
	agent_name issuedTo,
	agent_name issuedBy 
where 
	permit.issued_by_agent_id = issuedBy.agent_id and
	permit.issued_to_agent_id = issuedTo.agent_id and
		permit.issued_by_agent_id = issuedByPref.agent_id and
	permit.issued_to_agent_id = issuedToPref.agent_id ">

<cfif len(IssuedByAgent) gt 0>
	<cfset sql = "#sql# AND upper(issuedBy.agent_name) like '%#ucase(IssuedByAgent)#%'">
</cfif>
<cfif len(#IssuedToAgent#) gt 0>
	<cfset sql = "#sql# AND upper(issuedTo.agent_name) like '%#ucase(IssuedToAgent)#%'">
</cfif>
<cfif len(#issued_Date#) gt 0>
	<cfset sql = "#sql# AND upper(issued_Date) like '%#ucase(issued_Date)#%'">
</cfif>
<cfif len(#renewed_Date#) gt 0>
	<cfset sql = "#sql# AND upper(renewed_Date) like '%#ucase(renewed_Date)#%'">
</cfif>
<cfif len(#exp_Date#) gt 0>
	<cfset sql = "#sql# AND upper(exp_Date) like '%#ucase(exp_Date)#%'">
</cfif>
<cfif len(#permit_Num#) gt 0>
	<cfset sql = "#sql# AND permit_Num = '#permit_Num#'">
</cfif>
<cfif len(#specific_type#) gt 0>
	<cfset specific_type = #replace(specific_type,"'","''","All")#>
	<cfset sql = "#sql# AND specific_type = '#specific_type#'">
</cfif>
<cfif len(#permit_title#) gt 0>
	<cfset permit_title = #replace(permit_title,"'","''","All")#>
	<cfset sql = "#sql# AND upper(permit_title) like '%#ucase(permit_title)#%'">
</cfif>
<cfif len(#permit_Type#) gt 0>
	<cfset permit_Type = #replace(permit_type,"'","''","All")#>
	<cfset sql = "#sql# AND permit_Type = '#permit_Type#'">
</cfif>
<cfif len(#permit_remarks#) gt 0>
	<cfset permit_remarks = #replace(permit_remarks,"'","''","All")#>
	<cfset sql = "#sql# AND upper(permit_remarks) like '%#ucase(permit_remarks)#%'">
</cfif>
<cfset sql = "#sql# ORDER BY permit_id">
<hr>
<cfoutput>
<cfif #sql# is "select * from permit, agent_name issuedTo, agent_name issuedBy where permit.issued_by_agent_id = issuedBy.agent_id and permit.issued_to_agent_id = issuedTo.agent_id ">
	Enter some criteria.<cfabort>
</cfif>
<cfquery name="matchPermit" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	#preservesinglequotes(sql)#
</cfquery>

</cfoutput>
<cfset i=1>
<cfoutput query="matchPermit" group="permit_id">
<div #iif(i MOD 2,DE("class='evenRow'"),DE("class='oddRow' style='background-color: lightcyan;' "))#	>
	<form action="PermitShipmentPick.cfm" method="post" name="save" id="psp_#permit_id#" >
	<input type="hidden" value="#shipment_id#" name="shipment_id">
	<input type="hidden" name="permit_id" value="#permit_id#">
	<input type="hidden" name="Action" value="addThisOne">
	Permit Number #permit_Num# (#permit_Type#:#specific_type#) issued to #IssuedToAgent# by #IssuedByAgent# on #dateformat(issued_Date,"yyyy-mm-dd")# <cfif len(#renewed_Date#) gt 0> (renewed #dateformat(renewed_Date,"yyyy-mm-dd")#)</cfif>. Expires #dateformat(exp_Date,"yyyy-mm-dd")#.  <cfif len(#permit_remarks#) gt 0>Remarks: #permit_remarks# </cfif> (ID## #permit_id#) #permit_title#
<br><input type="button" value="Add this permit" class='picBtn' onclick=" $('##psp_#permit_id#').submit(); " >
	</form>
</div>
<cfset i=i+1>
</cfoutput>


	</cfif>
<cfif #Action# is "AddThisOne">
	<cfoutput>
		<cfif not (len(#shipment_id#) gt 0 and len(#permit_id#) gt 0)>
			something bad happened <cfabort>
		</cfif>
		<cfquery name="addPermit" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			INSERT INTO permit_shipment (permit_id, shipment_id) VALUES (#permit_id#, #shipment_id#)
		</cfquery>
		
		Added permit #permit_id# to shipment #shipment_id#. 
		<br>Search to add another permit to this accession or click OK to close this dialog.
	</cfoutput>	
	
	
</cfif>
<cfinclude template="../includes/_pickFooter.cfm">
