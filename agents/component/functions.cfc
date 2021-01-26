<!---
/transactions/component/functions.cfc

Copyright 2020 President and Fellows of Harvard College

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	 http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

--->
<cfcomponent>
<cf_rolecheck>

<!--- given various information create a new address 
--->
<cffunction name="addAddressHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="agent_id" type="string" required="no"><!--- if given, the agent for whom this is an address, if not, select --->
	<cfargument name="shipment_id" type="string" required="no"><!--- if given, the address is used for this shipment --->
	<cfargument name="create_from_address_id" type="string" required="no"><!--- if given, use this address's agent for this address --->
	<cfargument name="address_type" type="string" required="no"><!--- use temporary to create a temporary address, otherwise shipping or mailing --->

	<cfthread name="createAddressThread">
		<cfoutput>
			<cftry>

				<cfif not isdefined("address_type") or len(#address_type#) gt 0>
					<cfset address_type = "temporary">
				</cfif>
				<cfif isdefined("create_from_address_id") AND (not isdefined("agent_id") AND len(agent_id) GT 0) >
					<!--- look up agent id from address --->
					<cfquery name="qAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select agent_id from addr where addr_id = <cfqueryparam value="#create_from_address_id#" CFSQLTYPE="CF_SQL_VARCHAR">
					</cfquery>
					<cfset agent_id = qAgent.agent_id >
				</cfif>
				<cfquery name="ctAddrType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select addr_type from ctaddr_type where addr_type = <cfqueryparam value="#address_type#" CFSQLTYPE="CF_SQL_VARCHAR">
				</cfquery>
				<cfif ctAddrType.addr_type IS ''>
					<ul><li>Provided address type is unknown.</li></ul>
				<cfelse>
					<cfset agent_name ="">
					<cfif isdefined("agent_id") AND len(agent_id) GT 0 >
						<cfquery name="query" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							select agent_name 
							from agent a left join agent_name on a.preferred_agent_name_id = agent_name.agent_name_id
							where
							a.agent_id = <cfqueryparam value="#agent_id#" CFSQLType="CF_SQL_DECIMAL">
							and rownum < 2
						</cfquery>
						<cfif query.recordcount gt 0>
							<cfset agentname = query.agent_name>
						</cfif>
					</cfif>
					<ul>
						<div id='newAddressStatus'></div>
						<form name='newAddress' id='newAddressForm'>
							<input type='hidden' name='method' value='addNewAddress'>
							<input type='hidden' name='returnformat' value='json'>
							<input type='hidden' name='queryformat' value='column'>
							<cfif not isdefined("agent_id")><cfset agent_id = ""></cfif>
							<input type='hidden' name='agent_id' value='#agent_id#'>
							<input type='hidden' name='addr_type' value='#address_type#'>
							<input type='hidden' name='valid_addr_fg' id='valid_addr_fg' value='0'>
    <table>
     <tr>
      <td>
       <strong>Address Type:</strong> #ctAddrType.addr_type#
      </td>
      <td>
		<cfif len(agent_name) GT 0 >
			<strong>Address For:</strong> #agent_name#
		<cfelse>
			TODO: Agent Picker
		</cfif>
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

       </ul>
   </cfif>  <!--- known address type provided --->

			<cfcatch>
				<h2>Error: #cfcatch.type# #cfcatch.message#</h2> 
				<div>#cfcatch.detail#</div>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="createAddressThread" />
	<cfreturn createAddressThread.output>
</cffunction>

</cfcomponent>
