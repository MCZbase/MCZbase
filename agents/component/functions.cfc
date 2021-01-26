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

<!--- Given various information create dialog to create a new address, by default a temporary address.
 @param agent_id if given, the agent for whom this is an address
 @param shipment_id if given, the shipment for which this address is to be used for
 @param create_from_address_id, if given, used to lookup the agent_id for whom this is an address for
 @param address_type shipping, mailing, or temporary, defaults to temporary if not provided.
 @return html to populate a dialog
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
					<div>
						<div id='newAddressStatus'></div>
						<form name='newAddress' id='newAddressForm'>
							<input type='hidden' name='method' value='addNewAddress'>
							<input type='hidden' name='returnformat' value='json'>
							<input type='hidden' name='queryformat' value='column'>
							<cfif not isdefined("agent_id")><cfset agent_id = ""></cfif>
							<input type='hidden' name='agent_id' value='#agent_id#'>
							<input type='hidden' name='addr_type' value='#address_type#'>
							<input type='hidden' name='valid_addr_fg' id='valid_addr_fg' value='0'>
							<div class='form-row'>
								<div class='col-12 col-md-6'>
		 							<strong>Address Type:</strong> #ctAddrType.addr_type#
								</div>
								<div class='col-12 col-md-6'>
									<cfif len(agent_name) GT 0 >
										<strong>Address For:</strong> #agent_name#
									<cfelse>
										<span>
											<label for="addr_agent_name">Address For:</label>
											<span id="addr_agent_view">&nbsp;&nbsp;&nbsp;&nbsp;</span>
										</span>
										<div class="input-group">
											<div class="input-group-prepend">
												<span class="input-group-text smaller bg-lightgreen" id="addr_agent_icon"><i class="fa fa-user" aria-hidden="true"></i></span> 
											</div>
											<input name="agent_name" id="addr_agent_name" class="reqdClr form-control form-control-sm data-entry-input" required >
										</div>
										<input type="hidden" name="agent_id" id="addr_agent_id"  >
										<script>
											$(makeRichTransAgentPicker('addr_agent_name', 'addr_agent_id','addr_agent_icon','addr_agent_view',null))
										</script> 
									</cfif>
								</div>
							</div>
							<div class='form-row'>
								<div class='col-12 col-md-6'>
									<label for='institution'>Institution</label>
									<input type='text' name='institution' id='institution'size='50' >
								</div>
								<div class='col-12 col-md-6'>
									<label for='department'>Department</label>
									<input type='text' name='department' id='department' size='50' >
								</div>
							</div>
							<div class='form-row'>
								<div class='col-12'>
									<label for='street_addr1'>Street Address 1</label>
									<input type='text' name='street_addr1' id='street_addr1' class='reqdClr'>
								</div>
							</div>
							<div class='form-row'>
								<div class='col-12'>
									<label for='street_addr2'>Street Address 2</label>
									<input type='text' name='street_addr2' id='street_addr2'>
								</div>
							</div>
							<div class='form-row'>
								<div class='col-12 col-md-6'>
									<label for='city'>City</label>
									<input type='text' name='city' id='city' class='reqdClr'>
								</div>
								<div class='col-12 col-md-6'>
									<label for='state'>State</label>
									<input type='text' name='state' id='state' class='reqdClr'>
								</div>
							</div>
							<div class='form-row'>
								<div class='col-12 col-md-6'>
									<label for='zip'>Zip</label>
									<input type='text' name='zip' id='zip' class='reqdClr'>
								</div>
								<div class='col-12 col-md-6'>
									<label for='country_cde'>Country</label>
									<input type='text' name='country_cde' id='country_cde' class='reqdClr'>
								</div>
							</div>
							<div class='form-row'>
								<div class='col-12 col-md-6'>
									<label for='mail_stop'>Mail Stop</label>
									<input type='text' name='mail_stop' id='mail_stop'>
								</div>
								<div class='col-12 col-md-6'>
									<label for='addr_remarks'>Address Remark</label>
									<input type='text' name='addr_remarks' id='addr_remarks' size='50'>
								</div>
							</div>
							<input type='submit' class='insBtn' value='Create Address' >
							<script>
								$('##newAddressForm').submit( function (e) { 
									$.ajax({
										url: '/agents/component/functions.cfc',
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
							<input type='hidden' name='new_address_id' id='new_address_id' value=''>
							<input type='hidden' name='new_address' id='new_address' value=''>
						</form>
					</div>
				</cfif> <!--- known address type provided --->
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

<!--- given address parameters, create a new address record for a given agent --->
<cffunction name="addNewAddress" access="remote" returntype="query">
	<cftransaction>
    <cftry>
        <cfquery name="prefName" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
            select agent_name from preferred_agent_name 
            where agent_id= <cfqueryparam value='#agent_id#' cfsqltype='CF_SQL_DECIMAL'>
        </cfquery>
        <cfquery name="addrNextId" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
            select sq_addr_id.nextval as id from dual
        </cfquery>
        <cfset pk = addrNextId.id>
        <cfquery name="addr" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="addrResult"> 
            INSERT INTO addr (
                                ADDR_ID
                                ,STREET_ADDR1
                                ,STREET_ADDR2
                                ,institution
                                ,department
                                ,CITY
                                ,state
                                ,ZIP
                                ,COUNTRY_CDE
                                ,MAIL_STOP
                                ,agent_id
                                ,addr_type
                                ,valid_addr_fg
                                ,addr_remarks
                        ) VALUES (
                                 <cfqueryparam value='#pk#' cfsqltype='CF_SQL_DECIMAL'>
                                ,<cfqueryparam value='#STREET_ADDR1#' cfsqltype='CF_SQL_VARCHAR'>
                                ,<cfqueryparam value='#STREET_ADDR2#' cfsqltype='CF_SQL_VARCHAR'>
                                ,<cfqueryparam value='#institution#' cfsqltype='CF_SQL_VARCHAR'>
                                ,<cfqueryparam value='#department#' cfsqltype='CF_SQL_VARCHAR'>
                                ,<cfqueryparam value='#CITY#' cfsqltype='CF_SQL_VARCHAR'>
                                ,<cfqueryparam value='#state#' cfsqltype='CF_SQL_VARCHAR'>
                                ,<cfqueryparam value='#ZIP#' cfsqltype='CF_SQL_VARCHAR'>
                                ,<cfqueryparam value='#COUNTRY_CDE#' cfsqltype='CF_SQL_VARCHAR'>
                                ,<cfqueryparam value='#MAIL_STOP#' cfsqltype='CF_SQL_VARCHAR'>
                                ,<cfqueryparam value='#agent_id#' cfsqltype='CF_SQL_DECIMAL'>
                                ,<cfqueryparam value='#addr_type#' cfsqltype='CF_SQL_VARCHAR'>
                                ,<cfqueryparam value='#valid_addr_fg#' cfsqltype='CF_SQL_DECIMAL'>
                                ,<cfqueryparam value='#addr_remarks#' cfsqltype='CF_SQL_VARCHAR'>
                        )
        </cfquery>
        <cfquery name="newAddr" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="addrResult"> 
            select formatted_addr from addr 
            where addr_id = <cfqueryparam value='#pk#' cfsqltype="CF_SQL_DECIMAL">
        </cfquery>
		<cfset q=queryNew("STATUS,ADDRESS_ID,ADDRESS,MESSAGE")>
		<cfset t = queryaddrow(q,1)>
		<cfset t = QuerySetCell(q, "STATUS", "success", 1)>
		<cfset t = QuerySetCell(q, "ADDRESS_ID", "#pk#", 1)>
		<cfset t = QuerySetCell(q, "ADDRESS", "#newAddr.formatted_addr#", 1)>
		<cfset t = QuerySetCell(q, "MESSAGE", "", 1)>
     <cfcatch>
        <cftransaction action="rollback"/>
		<cfset q=queryNew("STATUS,ADDRESS_ID,ADDRESS,MESSAGE")>
		<cfset t = queryaddrow(q,1)>
		<cfset t = QuerySetCell(q, "STATUS", "error", 1)>
		<cfset t = QuerySetCell(q, "ADDRESS_ID", "", 1)>
		<cfset t = QuerySetCell(q, "ADDRESS", "", 1)>
		<cfset t = QuerySetCell(q, "MESSAGE", "Error: #cfcatch.message# #cfcatch.detail#", 1)>
     </cfcatch>
     </cftry>
	</cftransaction>
     <cfreturn q>
</cffunction>

</cfcomponent>
