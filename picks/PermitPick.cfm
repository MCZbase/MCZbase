<cfset jquery11=true>
<cfinclude template="../includes/_pickHeader.cfm">
<script type='text/javascript' src='/includes/transAjax.js'></script>
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
<cfif Action is "movePermit">
   <!---  Dialog to move a permit from one shipment to another shipment in the same transaction ---> 
   <!---  Or to copy (add another link for) a permit from one shipment to another shipment in the same transaction ---> 
   <cfset ok = false>
   <cfif isDefined("permit_id") and len(permit_id) gt 0>
       <cfif isDefined("current_shipment_id") and len(current_shipment_id) gt 0>
          <cfif isDefined("transaction_id") and len(transaction_id) gt 0>
             <cfset ok = true>
          </cfif>
       </cfif>
   </cfif>
   <cfif ok EQ false>
      <cfset result="Error: PermitPick.cfm:movePermit must be provided with permit_id, current_shipment_id and transaction_id">
   <cfelse>
   <cfset feedbackId = "queryMovePermit#permit_id##current_shipment_id#">
   <cfif not isDefined("inDialog")>
       <cfset inDialog = false>
   </cfif>
   
   <cfset result="">
   <cfquery name="queryPermit" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
        select distinct permit_num, permit_type, issued_date, permit.permit_id,
             issuedBy.agent_name as IssuedByAgent
        from permit left join preferred_agent_name issuedBy on permit.issued_by_agent_id = issuedBy.agent_id
        where permit_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value=#permit_id#>
   </cfquery>
   <cfloop query="queryPermit">
       <cfset result = result & "<h3>Move/Copy Permit #permit_type# #permit_num# Issued By: #IssuedByAgent#</h3><p><strong><span id='#feedbackId#'></span></strong></p>">
   </cfloop>
   <cfquery name="queryShip" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
                   select 1 as status, shipment_id,
                   packed_by_agent_id, mczbase.get_agentnameoftype(packed_by_agent_id,'preferred') packed_by_agent, carriers_tracking_number,
                   shipped_carrier_method, to_char(shipped_date, 'yyyy-mm-dd') as shipped_date, package_weight, no_of_packages,
                   hazmat_fg, insured_for_insured_value, shipment_remarks, contents, foreign_shipment_fg, shipped_to_addr_id,
                   shipped_from_addr_id, fromaddr.formatted_addr as shipped_from_address, toaddr.formatted_addr as shipped_to_address
             from shipment
                  left join addr fromaddr on shipment.shipped_from_addr_id = fromaddr.addr_id
                  left join addr toaddr on shipment.shipped_to_addr_id = toaddr.addr_id
             where transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#"> and
                   shipment_id <> <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#current_shipment_id#">
   </cfquery>
   <cfif queryShip.recordcount gt 0>
       <cfset result= result & "<ul>">
       <cfloop query="queryShip">
          <cfset result = result & "<li><input type='button' style='margin-left: 30px;' value='Move To' class='lnkBtn' onClick="" movePermitFromShipmentCB(#current_shipment_id#,#shipment_id#,#permit_id#,#transaction_id#, function(status) { if (status == 1) { $('##" & "#feedbackId#').html('Moved.  Click OK to close dialog.'); } else { $('##" & "#feedbackId#').html('Error.'); }; }); ""> ">
          <cfset result = result & "<input type='button' style='margin-left: 30px;' value='Copy To' class='lnkBtn' onClick=""  addPermitToShipmentCB(#shipment_id#,#permit_id#,#transaction_id#, function(status) { if (status == 1) { $('##" & "#feedbackId#').html('Added.  Click OK to close dialog.'); } else { $('##" & "#feedbackId#').html('Error.'); }; }); ""> ">
          <cfset result = result & "#shipped_carrier_method# #shipped_date# #carriers_tracking_number#</li>">
       </cfloop>
       <cfset result= result & "</ul>">
   <cfelse>
       <cfset result= result & "There are no other shipments in this transaction, you must create a new shipment to move this permit to.">
   </cfif>
  
   </cfif> <!--- if ok ---> 

   <cfoutput>
   <script type='text/javascript' src='/includes/transAjax.js'></script>
   #result#
   </cfoutput>

<cfelse>

   <!---  Default dialog: find a permit to link to --->
   <cfoutput>

   Search for permits. Any part of dates and names accepted, case isn't important.<br>
   <cfform name="findPermit" action="PermitPick.cfm" method="post">
	<input type="hidden" name="Action" value="search">
	<input type="hidden" name="inDialog" value="#inDialog#">
	<input type="hidden" name="transaction_id" value="#transaction_id#">
	<table>
		<tr>
			<td>Issued By</td>
			<td><input type="text" name="IssuedByAgent"></td>
			<td>Issued To</td>
			<td><input type="text" name="IssuedToAgent"></td>
			
			
		</tr>
		<tr>
			<td>Issued Date</td>
			<td><input type="text" name="issued_Date"></td>
			<td>Renewed Date</td>
			<td><input type="text" name="renewed_Date"></td>
		</tr>
		<tr>
			<td>Expiration Date</td>
			<td><input type="text" name="exp_Date"></td>
			<td>Permit Number</td>
			<td><input type="text" name="permit_Num" id="permit_Num"></td>
		</tr>
		<tr>
			<td>Permit Type</td>
			<td>
				<select name="permit_Type" size="1" style="width: 15em;">
					<option value=""></option>
					<cfloop query="ctPermitType">
						<option value = "#ctPermitType.permit_type#">#ctPermitType.permit_type# (#ctPermitType.uses#)</option>
					</cfloop>
				
				</select>
			</td>
			<td>Remarks</td>
			<td><input type="text" name="permit_remarks"></td>
		</tr>
		<tr>
			<td>Specific Type</td>
			<td>
				<select name="specific_type" size="1" style="width: 15em;">
					<option value=""></option>
					<cfloop query="ctSpecificPermitType">
						<option value = "#ctSpecificPermitType.specific_type#">#ctSpecificPermitType.specific_type# (#ctSpecificPermitType.uses#)</option>
					</cfloop>
				
				</select>
			</td>
			<td>Permit Title</td>
			<td><input type="text" name="permit_title"></td>
		</tr>
		<tr>
			<td></td>
			<td>
			    <input type="submit" value="Search" class="schBtn">	
			</td>
			<td>
				<a href="/transactions/Permit.cfm?action=new" target="_blank">Create New Permissions and Rights Document</a>
			</td>
			<td>
   			    <input type="reset" value="Clear" class="clrBtn">
			</td>
		</tr>
	</table>
	
	
	
</cfform>
</cfoutput>

</cfif>
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
	permit_title,
	specific_type,
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
<cfif len(#permit_Type#) gt 0>
	<cfset permit_Type = #replace(permit_type,"'","''","All")#>
	<cfset sql = "#sql# AND permit_Type = '#permit_Type#'">
</cfif>
<cfif len(#permit_title#) gt 0>
	<cfset permit_title = #replace(permit_title,"'","''","All")#>
	<cfset sql = "#sql# AND upper(permit_title) like '%#ucase(permit_title)#%'">
</cfif>
<cfif len(#permit_remarks#) gt 0>
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
<div #iif(i MOD 2,DE("class='evenRow'"),DE("class='oddRow' style=' background-color: lightcyan; ' "))#	>
	<form action="PermitPick.cfm" method="post" name="save" id="pp_#permit_id#_#transaction_id#" >
	<input type="hidden" value="#transaction_id#" name="transaction_id">
	<input type="hidden" name="permit_id" value="#permit_id#">
	<input type="hidden" name="Action" value="addThisOne">
	<input type="hidden" name="inDialog" value="#inDialog#">
	Permit Number #permit_Num# (#permit_Type#:#specific_type#) issued to #IssuedToAgent# by #IssuedByAgent# on #dateformat(issued_Date,"yyyy-mm-dd")# <cfif len(#renewed_Date#) gt 0> (renewed #dateformat(renewed_Date,"yyyy-mm-dd")#)</cfif>. Expires #dateformat(exp_Date,"yyyy-mm-dd")#.  <cfif len(#permit_remarks#) gt 0>Remarks: #permit_remarks# </cfif> (ID## #permit_id#) #permit_title#
<br><input type="submit" value="Add this permit"  class='picBtn' onclick=" $('##pp_#permit_id#_#transaction_id#').submit(); ">
	</form>
</div>
<cfset i=i+1>
</cfoutput>


	</cfif>
<cfif #Action# is "AddThisOne">
	<cfoutput>
		<cfif not (len(#transaction_id#) gt 0 and len(#permit_id#) gt 0)>
			something bad happened <cfabort>
		</cfif>
		<cfquery name="addPermit" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			INSERT INTO permit_trans (permit_id, transaction_id) VALUES (#permit_id#, #transaction_id#)
		</cfquery>
		
		
		
		Added permit #permit_id# to transaction #transaction_id#. 
		<br>Search to add another permit to this accession or click
                <cfif inDialog>
			ok to close this window.
                <cfelse>
 			<a href="##" onclick="javascript: self.close();">here</a> to close this window.
                </cfif>
	</cfoutput>	
	
	
</cfif>
<cfinclude template="../includes/_pickFooter.cfm">
