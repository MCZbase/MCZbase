<!--- no security --->
<cfinclude template="../includes/_pickHeader.cfm">
<cfset title = "Agent Pick">
<cfif isdefined("includeTemporary") and #includeTemporary# IS "true">
  <cfset showTemp = TRUE>
<cfelse>
  <cfset showTemp = FALSE>
</cfif>
 
<!--- build an agent id search --->
<form name="searchForAgent" action="AddrPick.cfm" method="post">
	<br>Agent Name: <input type="text" name="agentname">
	<br><input type="submit" value="Find Matches">
	<input type="hidden" name="search" value="true" class="lnkBtn">
	<cfif showTemp EQ TRUE >
		<input type="hidden" name="includeTemporary" value="true" class="lnkBtn">
	</cfif>
	<cfoutput>
		<input type="hidden" name="addrIdFld" value="#addrIdFld#">
		<input type="hidden" name="addrFld" value="#addrFld#">
		<input type="hidden" name="formName" value="#formName#">
	</cfoutput>
</form>
<cfif isdefined("search") and #search# is "true">
	<!--- make sure we're searching for something --->
	<cfif len(#agentname#) is 0>
		You must enter search criteria.
		<cfabort>
	</cfif>
	<cfset searchAgentString = "%#ucase(agentname)#%" >
	<cfquery name="getAgentId" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		SELECT agent_name, preferred_agent_name.agent_id, formatted_addr, addr_id,VALID_ADDR_FG, addr_type
		FROM preferred_agent_name left join addr on preferred_agent_name.agent_id = addr.agent_id
		WHERE
		    UPPER(agent_name) LIKE <cfqueryparam value="#searchAgentString#" cfsqltype="CF_SQL_VARCHAR">
		<cfif showTemp EQ FALSE >
		    AND addr_type <> 'temporary'
		</cfif >
		ORDER BY valid_addr_fg desc, agent_name asc
	</cfquery>
	<cfoutput query="getAgentId">
		
<br>
<cfset temp = "">
<cfif addr_type EQ 'temporary'>
  <cfset temp = "&nbsp;[Temporary]">
</cfif>
<span>#agent_name##temp#</span><br>
<cfif len(#formatted_addr#) gt 0>
<cfset addr = #replace(formatted_addr,"'","`","ALL")#>
<cfset addr = #replace(addr,"#chr(9)#","-","ALL")#>
<cfset addr = #replace(addr,"#chr(10)#","-","ALL")#>
<cfset addr = #replace(addr,"#chr(13)#","-","ALL")#>
<cfset addr=trim(addr)>
<a href="##" onClick="javascript: opener.document.#formName#.#addrFld#.value='#addr#';opener.document.#formName#.#addrIdFld#.value='#addr_id#';self.close();">
	<cfif VALID_ADDR_FG is 0><span class="red">#addr#</span><cfelse>#addr#</cfif></a>
<br>
      <a href="/agents/editAgent.cfm?agent_id=#agent_id#" target="_blank"><font color="##00FF66">Add 
      address for #agent_name# <font size="-2">(new window)</font></font></a> 
      <cfelse>
      <a href="/agents/editAgent.cfm?agent_id=#agent_id#" target="_blank"><font color="##00FF66">Add 
      address for #agent_name# <font size="-2">(new window)</font></font></a> 
    </cfif>
<hr>
	</cfoutput>
</cfif>
<cfinclude template="../includes/_pickFooter.cfm">
