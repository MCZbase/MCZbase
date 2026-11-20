<cfinclude template="/includes/_header.cfm">
	<cfoutput>
		<cfquery name="coll" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			select
				*
			from
				collection
		</cfquery>
		<cfloop query="coll">
			<cfquery name="members" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				select
					mem.agent_name
				from
					agent_name mem,
					group_member,
					agent_name grp
				where
					mem.agent_id = group_member.member_agent_id and
					mem.agent_name_type='login' and
					group_member.group_agent_id = grp.agent_id and
					grp.agent_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#institution_acronym# #collection_cde# Data Entry Group">
			</cfquery>
			<cfquery name="admins" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				select
					mem.agent_name
				from
					agent_name mem,
					group_member,
					agent_name grp
				where
					mem.agent_id = group_member.member_agent_id and
					mem.agent_name_type='login' and
					group_member.group_agent_id = grp.agent_id and
					grp.agent_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#institution_acronym# #collection_cde# Data Admin Group">
			</cfquery>
			<!--- a login name could hold a comma, so the names are listed with a separator none holds --->
			<cfset USERSEPARATOR = chr(31)>
			<cfset users = ''>
			<cfloop query="members">
				<cfset users = listAppend(users, members.agent_name, USERSEPARATOR)>
			</cfloop>
			<cfloop query="admins">
				<cfset users = listAppend(users, admins.agent_name, USERSEPARATOR)>
			</cfloop>
			<cfif len(#users#) gt 0>
				<cfquery name="bl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					select 
						loaded,
						collection_object_id,
						enteredby
					from bulkloader
					where loaded is not null and loaded !='waiting approval' and
					enteredby in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#users#" list="yes" separator="#USERSEPARATOR#">)
					order by enteredby, loaded, collection_object_id
				</cfquery>
				<cfquery name="addrs" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					select address 
					from
						electronic_address,
						agent_name
					<!--- TODO: Broken: ctelectronic_addr_type holds 'email', not 'e-mail', so this
						matches no row: addrs comes back empty and no status mail is sent. --->
					where address_type='e-mail' and
					electronic_address.agent_id = agent_name.agent_id and
					agent_name in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#users#" list="yes" separator="#USERSEPARATOR#">)
					group by address
				</cfquery>
				<hr>
				To: #valuelist(addrs.address)#<br>
				<table border>
					<tr>
						<th>Collection_Object_Id</th>
						<th>EnteredBy</th>
						<th>Problem</th>
					</tr>
				<cfloop query="bl">
					<tr>
						<td>#collection_object_id#</td>
						<td>#enteredby#</td>
						<td>#loaded#</td>
					</tr>
				</cfloop>
				</table>
			</cfif>
		</cfloop>
	</cfoutput>
<cfinclude template="/includes/_footer.cfm">
