<cfinclude template="../includes/_pickHeader.cfm">
<cfset title = "Permit Pick">
<cfquery name="ctPermitType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select * from ctpermit_type order by permit_type
</cfquery>
<cfoutput>
   <cfif action is "nothing">
      Search for permits. Any part of dates and names accepted, case isn't important.<br>
      <cfform name="findPermit" action="findPermit.cfm" method="post">
              <input type="hidden" name="Action" value="search">
              <input type="hidden" name="PermitNumFld" value="#PermitNumFld#">
              <input type="hidden" name="PermitIdFld" value="#PermitIdFld#">
              <input type="hidden" name="formName" value="#formName#">
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
                              <td><input type="text" name="permit_Num"></td>
                      </tr>
                      <tr>
                              <td>Permit Type</td>
                              <td>
                                      <select name="permit_Type" size="1">
                                              <option value=""></option>
                                              <cfloop query="ctPermitType">
                                                      <option value = "#ctPermitType.permit_type#">#ctPermitType.permit_type#</option>
                                              </cfloop>
      
                                      </select>
                              </td>
                              <td>Remarks</td>
                              <td><input type="text" name="permit_remarks"></td>
                      </tr>
                      <tr>
                              <td colspan="4" align="center">
                              <input type="submit" 
                                      value="Search" 
                                      class="schBtn">
      
         <img src="../images/nada.gif" width="30">
                              <input type="reset" 
                                      value="Clear" 
                                      class="clrBtn">
                                      </td>
                      </tr>
              </table>
      </cfform>
   </cfif>
</cfoutput>
   <cfif action is "search">

<cfset sql = "select permit.permit_id,
	issuedByPref.agent_name IssuedByAgent,
	issuedToPref.agent_name IssuedToAgent,
	issued_Date,
	renewed_Date,
	exp_Date,
	permit_Num,
	permit_Type,
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
<cfif len(#permit_Type#) gt 0>
	
		<cfset permit_Type = #replace(permit_type,"'","''","All")#>
	
	
	<cfset sql = "#sql# AND permit_Type = '#permit_Type#'">
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
<cfquery name="matchPermit" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
        #preservesinglequotes(sql)#
</cfquery>

</cfoutput>
<cfoutput query="matchPermit" group="permit_id">

<cfif #matchPermit.recordcount# is 0>
    Nothing matched. <a href="findPermit.cfm?formName=#formName#&PermitNumFld=#PermitNumFld#&PermitIdFld=#PermitIdFld#">Try again.</a>
<cfelseif #matchPermit.recordcount# is 1>
    <script>
       opener.document.#formName#.#PermitNumFld#.value='#permit_Num# (#permit_Type#)';
       opener.document.#formName#.#PermitIdFld#.value='#permit_id#';
       opener.document.#formName#.#PermitNumFld#.style.background='##8BFEB9';
       self.close();
   </script>
<cfelse>
   <tr>
   <td>
      <a onClick="javascript: opener.document.#formName#.#PermitNumFld#.value='#permit_Num# (#permit_Type#)';
          opener.document.#formName#.#PermitIdFld#.value='#permit_id#';self.close();">Permit Number #permit_Num# (#permit_Type#)</a> 
      issued to #IssuedToAgent# by #IssuedByAgent# on #dateformat(issued_Date,"yyyy-mm-dd")# <cfif len(#renewed_Date#) gt 0> (renewed #dateformat(renewed_Date,"yyyy-mm-dd")#)</cfif>. Expires #dateformat(exp_Date,"yyyy-mm-dd")#.  <cfif len(#permit_remarks#) gt 0>Remarks: #permit_remarks# </cfif> (ID## #permit_id#)
   </td>
   </tr>
</cfif>
</cfoutput>

</cfif>
<cfinclude template="../includes/_pickFooter.cfm">
