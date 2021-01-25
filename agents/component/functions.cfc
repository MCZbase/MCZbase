<!----------------------------------------------------------------------------------------------------------------->
<cffunction name="addAddressHtml" returntype="string" access="remote" returnformat="plain">
   <cfargument name="agent_id" type="string" required="no">
   <cfargument name="transaction_id" type="string" required="no">
   <cfargument name="create_from_address_id" type="string" required="no">
   <cfargument name="address_type" type="string" required="no">
   <cfset result="">
   <cfif not isdefined("address_type") or len(#address_type#) gt 0>
      <cfset address_type = "temporary">
   </cfif>
   <cfquery name="qAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
    	select agent_id from addr where addr_id = <cfqueryparam value="#create_from_address_id#" CFSQLTYPE="CF_SQL_VARCHAR">
   </cfquery>
   <cfset agent_id = qAgent.agent_id >
   <cfquery name="ctAddrType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
    	select addr_type from ctaddr_type where addr_type = <cfqueryparam value="#address_type#" CFSQLTYPE="CF_SQL_VARCHAR">
   </cfquery>
   <cfif ctAddrType.addr_type IS ''>
       <cfset result=result & "<ul><li>Provided address type is unknown.</li></ul>">
   <cfelse>
   <cfset result="">
   <cfquery name="query" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
           select agent_name 
           from agent a left join agent_name on a.preferred_agent_name_id = agent_name.agent_name_id
           where
               a.agent_id = <cfqueryparam value="#agent_id#" CFSQLType="CF_SQL_DECIMAL">
               and rownum < 2
   </cfquery>
   <cfif query.recordcount gt 0>
       <cfset result=result & "<ul>">
       <cfloop query="query">
<!-- TODO: Make ajax response to save and hold resulting addressid for pickup.-->
          <cfset result = result & "
<div id='newAddressStatus'></div>
<form name='newAddress' id='newAddressForm'>
    <input type='hidden' name='method' value='addNewAddress'>
    <input type='hidden' name='returnformat' value='json'>
    <input type='hidden' name='queryformat' value='column'>
    <input type='hidden' name='agent_id' value='#agent_id#'>
    <input type='hidden' name='addr_type' value='#address_type#'>
    <input type='hidden' name='valid_addr_fg' id='valid_addr_fg' value='0'>
    <table>
     <tr>
      <td>
       <strong>Address Type:</strong> #ctAddrType.addr_type#
      </td>
      <td>
       <strong>Address For:</strong> #query.agent_name#
      </td>
     </tr>
     <tr>
      <td colspan='2'>
       <label for='institution'>Institution</label>
       <input type='text' name='institution' id='institution'size='50' >
      </td>
     </tr>
     <tr>
      <td colspan='2'>
       <label for='department'>Department</label>
       <input type='text' name='department' id='department' size='50' >
      </td>
     </tr>
     <tr>
      <td colspan='2'>
       <label for='street_addr1'>Street Address 1</label>
       <input type='text' name='street_addr1' id='street_addr1' size='50' class='reqdClr'>
      </td>
     </tr>
     <tr>
      <td colspan='2'>
       <label for='street_addr2'>Street Address 2</label>
       <input type='text' name='street_addr2' id='street_addr2' size='50'>
      </td>
     </tr>
     <tr>
      <td>
       <label for='city'>City</label>
       <input type='text' name='city' id='city' class='reqdClr'>
      </td>
      <td>
       <label for='state'>State</label>
       <input type='text' name='state' id='state' class='reqdClr'>
      </td>
     </tr>
     <tr>
      <td>
       <label for='zip'>Zip</label>
       <input type='text' name='zip' id='zip' class='reqdClr'>
      </td>
      <td>
       <label for='country_cde'>Country</label>
       <input type='text' name='country_cde' id='country_cde' class='reqdClr'>
      </td>
     </tr>
     <tr>
      <td colspan='2'>
       <label for='mail_stop'>Mail Stop</label>
       <input type='text' name='mail_stop' id='mail_stop'>
      </td>
     </tr>
     <tr>
      <td colspan='2'>
       <label for='addr_remarks'>Address Remark</label>
       <input type='text' name='addr_remarks' id='addr_remarks' size='50'>
      </td>
     </tr>
     <tr>
      <td colspan='2'>
       <input type='submit' class='insBtn' value='Create Address' >
       <script>
         $('##newAddressForm').submit( function (e) { 
             $.ajax({
                url: '/component/functions.cfc',
                data : $('##newAddressForm').serialize(),
                success: function (result) {
                     if (result.DATA.STATUS[0]=='success') { 
                        $('##newAddressStatus').html('New Address Added');
                        $('##new_address_id').val(result.DATA.ADDRESS_ID[0]);
                        $('##new_address').val(result.DATA.ADDRESS[0]);
                        $('##tempAddressDialog').dialog('close');
                     } else { 
                        $('##newAddressStatus').html(result.DATA.MESSAGE[0]);
                     }
                },
        	dataType: 'json'
              });
              e.preventDefault();
         });
      </script>
      </td>
     </tr>
    </table>
    <input type='hidden' name='new_address_id' id='new_address_id' value=''>
    <input type='hidden' name='new_address' id='new_address' value=''>
</form>
" >
       </cfloop>
       <cfset result= result & "</ul>">
   <cfelse>
       <cfset result=result & "<ul><li>No Agent Found for temporary address.</li></ul>">
   </cfif>
   </cfif>  <!--- known address type provided --->
   <cfreturn result>
</cffunction>
