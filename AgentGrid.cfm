<cfinclude template="includes/_pickHeader.cfm">

<cfif not isdefined("Action") OR not #action# is "search">
	<!---- waiting for something to search --->
	<cfabort>
</cfif>
<!--- make sure they didn't just hit search (return all agents) --->
<!----
<cfif not (
	len(#First_Name#) gt 0 or
	len(#Last_Name#) gt 0 or
	len(#Middle_Name#) gt 0 or
	len(#Suffix#) gt 0 or
	len(#Prefix#) gt 0 or
	len(#Birth_Date#) gt 0 or
	len(#anyName#) gt 0 or
	len(#agent_id#) gt 0 or
	len(#Death_Date#) gt 0)
>
	<font color="#FF0000"><strong>You must enter search criteria.</strong></font>
	<cfabort>

</cfif>
---->

<cfoutput>
<div style="padding: 3px;">

	<cfif not isDefined("birthOper")><cfset birthOper="="></cfif>
	<cfif not isDefined("deathOper")><cfset deathOper="="></cfif>
	<cfquery name="getAgents" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		SELECT 
			distinct preferred_agent_name.agent_id,
			preferred_agent_name.agent_name,
			agent_type,
			agent.edited,
			MCZBASE.get_worstagentrank(agent.agent_id) worstagentrank
		FROM 
			agent_name
			left outer join preferred_agent_name ON (agent_name.agent_id = preferred_agent_name.agent_id)
			LEFT OUTER JOIN agent ON (agent_name.agent_id = agent.agent_id)
			LEFT OUTER JOIN person ON (agent.agent_id = person.person_id)
		WHERE
			agent.agent_id > -1
			and rownum<501
			<cfif isdefined("First_Name") AND len(#First_Name#) gt 0>
				AND first_name LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#First_Name#">
			</cfif>
			<cfif isdefined("Last_Name") AND len(#Last_Name#) gt 0>
				AND Last_Name LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#last_name#">
			</cfif>
			<cfif isdefined("Middle_Name") AND len(#Middle_Name#) gt 0>
				AND Middle_Name LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#Middle_Name#">
			</cfif>
			<cfif isdefined("Suffix") AND len(#Suffix#) gt 0>
				AND Suffix = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#Suffix#">
			</cfif>
			<cfif isdefined("Prefix") AND len(#Prefix#) gt 0>
				AND Prefix = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#Prefix#">
			</cfif>
			<cfif isdefined("Birth_Date") AND len(#Birth_Date#) gt 0>
				<cfset bdate = dateformat(birth_date,'yyyy-mm-dd')>
				AND Birth_Date 
					<cfif birthOper IS "<="> <= <cfelseif birthOper IS ">="> >= <cfelse> = </cfif>
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#bdate#">
			</cfif>
			<cfif isdefined("Death_Date") AND len(#Death_Date#) gt 0>
				<cfset ddate = #dateformat(Death_Date,'yyyy-mm-dd')#>
				AND Death_Date 
					<cfif deathOper IS "<="> <= <cfelseif deathOper IS ">="> >= <cfelse> = </cfif>
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ddate#">
			</cfif>
			<cfif isdefined("anyName") AND len(#anyName#) gt 0>
				AND upper(agent_name.agent_name) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(anyName)#%">
			</cfif>
			<cfif isdefined("agent_id") AND isnumeric(#agent_id#)>
				AND agent_name.agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
			</cfif>
			<cfif isdefined("address") AND len(#address#) gt 0>
				AND agent.agent_id IN (
					select agent_id from addr where upper(formatted_addr) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(address)#%">
				)
			</cfif>
		GROUP BY preferred_agent_name.agent_id,
					preferred_agent_name.agent_name,
					agent_type,agent.edited, MCZBASE.get_worstagentrank(agent.agent_id)
		ORDER BY preferred_agent_name.agent_name
	</cfquery>

	<cfif getAgents.recordcount is 0>
		<span class="error">Nothing Matched.</span>
	<cfelse>
		<span style="display: inline-block;padding:1px 5px;">
			#getAgents.recordcount# matches (limit 500)
		</span>
	</cfif>

	<cfloop query="getAgents">
		<span style="display: inline-block;padding:1px 5px;">
			<a href="editAllAgent.cfm?agent_id=#agent_id#" target="_person">#agent_name#</a> 
			<span style="font-size: smaller;">(#agent_type#: #agent_id#) <cfif #edited# EQ 1>*</cfif><cfif #worstagentrank# EQ 'A'>&nbsp;<cfelseif #worstagentrank# EQ 'F'><img src="images/flag-red.svg.png" width="16"><cfelse><img src="images/flag-yellow.svg.png" width="16"></cfif>
			</span>
		</span>
		<br>
	</cfloop>
	<cfif getAgents.recordcount GT 498 >
		<cfquery name="getAgentCount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			SELECT 
				count(distinct preferred_agent_name.agent_id) as ct
			FROM 
				agent_name
				left outer join preferred_agent_name ON (agent_name.agent_id = preferred_agent_name.agent_id)
				LEFT OUTER JOIN agent ON (agent_name.agent_id = agent.agent_id)
				LEFT OUTER JOIN person ON (agent.agent_id = person.person_id)
			WHERE
				agent.agent_id > -1
				and rownum<500
				<cfif isdefined("First_Name") AND len(#First_Name#) gt 0>
					AND first_name LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#First_Name#">
				</cfif>
				<cfif isdefined("Last_Name") AND len(#Last_Name#) gt 0>
					AND Last_Name LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#last_name#">
				</cfif>
				<cfif isdefined("Middle_Name") AND len(#Middle_Name#) gt 0>
					AND Middle_Name LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#Middle_Name#">
				</cfif>
				<cfif isdefined("Suffix") AND len(#Suffix#) gt 0>
					AND Suffix = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#Suffix#">
				</cfif>
				<cfif isdefined("Prefix") AND len(#Prefix#) gt 0>
					AND Prefix = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#Prefix#">
				</cfif>
				<cfif isdefined("Birth_Date") AND len(#Birth_Date#) gt 0>
					<cfset bdate = dateformat(birth_date,'yyyy-mm-dd')>
					AND Birth_Date 
						<cfif birthOper IS "<="> <= <cfelseif birthOper IS ">="> >= <cfelse> = </cfif>
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#bdate#">
				</cfif>
				<cfif isdefined("Death_Date") AND len(#Death_Date#) gt 0>
					<cfset ddate = #dateformat(Death_Date,'yyyy-mm-dd')#>
					AND Death_Date 
						<cfif deathOper IS "<="> <= <cfelseif deathOper IS ">="> >= <cfelse> = </cfif>
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ddate#">
				</cfif>
				<cfif isdefined("anyName") AND len(#anyName#) gt 0>
					AND upper(agent_name.agent_name) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(anyName)#%">
				</cfif>
				<cfif isdefined("agent_id") AND isnumeric(#agent_id#)>
					AND agent_name.agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
				</cfif>
				<cfif isdefined("address") AND len(#address#) gt 0>
					AND agent.agent_id IN (
						select agent_id from addr where upper(formatted_addr) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(address)#%">
					)
				</cfif>
		</cfquery>
		<cfloop query="getAgentCount">
			<span class="error">
				#getAgentCount.ct# matching agents, only the first 500 shown.
			</span>
		</cfloop>
	</cfif>

	</div>
</cfoutput>
<cfinclude template="includes/_pickFooter.cfm">
