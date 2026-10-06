<cfset pageTitle="Administer Users">
<cfinclude template = "/shared/_header.cfm">
<cfinclude template="/shared/component/databaseAccounts.cfc" runOnce="true">
<cfinclude template="/shared/component/requestForgery.cfc" runOnce="true">
<script src="/lib/misc/sorttable.js"></script>

<cfif not isDefined("username")><cfset username=""></cfif>
<cfif not isDefined("action")><cfset action=""></cfif>
<cfif not isDefined("state")><cfset state=""></cfif>
<cfif not isDefined("findlastname")><cfset findlastname=""></cfif>

<cfif NOT ( isdefined("session.roles") AND listfindnocase(session.roles,"global_admin") ) >
	<!--- this should be handled by rolecheck but add another layer here to make sure of access control --->
	<cflocation url="/errors/forbidden.cfm" addtoken="false">
</cfif>

<main class="container py-3" id="content">
	<section class="row border rounded my-2 p-2">
		<h1 class="h2">Manage MCZbase Users</h1>
		<cfoutput>
			<div class="col-12">
				<h2 class="h3">Find Users</h2>
				<form action="/Admin/AdminUsers.cfm" method="get">
					<div class="form-row">
						<input type="hidden" name="Action" value="list">
						<div class="col-12 col-md-4">
							<label for="username" class="data-entry-label">Username</label>
							<input name="username" id="username" class="data-entry-input" value="#encodeForHtml(username)#">
						</div>
						<div class="col-12 col-md-4">
							<label for="findlastname" class="data-entry-label">Last Name</label>
							<input name="findlastname" id="findlastname" class="data-entry-input" value="#encodeForHtml(findlastname)#">
						</div>
						<div class="col-12 col-md-4">
							<label for="state" class="data-entry-label">State:</label>
							<select name="state" id="state" class="data-entry-input" value="#encodeForHtml(state)#">
								<cfif not isDefined("state") OR state EQ "all"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
								<option value="all" #selected#>All</option>
								<cfif isDefined("state") and state EQ "profile"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
								<option value="profile" #selected#>Has Profile</option>
								<cfif isDefined("state") and state EQ "invited"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
								<option value="invited" #selected#>Invited to become an operator</option>
								<cfif isDefined("state") and state EQ "oracle"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
								<option value="oracle" #selected#>Has Oracle User</option>
								<cfif isDefined("state") and state EQ "coldfusion_user"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
								<option value="coldfusion_user" #selected#>One of Us</option>
								<cfif isDefined("state") and state EQ "noprofile"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
								<option value="noprofile" #selected#>No Profile</option>
								<cfif isDefined("state") and state EQ "nooracle"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
								<option value="nooracle" #selected#>No Oracle User</option>
								<cfif isDefined("state") and state EQ "locked"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
								<option value="locked" #selected#>Locked Account</option>
							</select>
						</div>
					</div>
					<div class="form-row">
						<div class="col-12 col-md-4">
							<input type="submit" value="Find" class="btn btn-primary btn-xs">
						</div>
					</div>
				</form>
			</div>
		</cfoutput>
	</section>
	<section class="row">

<cfif Action is "list">
	<!--- everyone with an account has a record in cf_users, they may have added name/contact/affiliation information in cf_user_data --->
	<cfquery name="getUsers" datasource="uam_god">
		SELECT 
			cf_users.username,
			upper(cf_users.username) as ucasename,
			approved_to_request_loans,
			FIRST_NAME,
			MIDDLE_NAME,
			LAST_NAME,
			AFFILIATION,
			EMAIL,
			cf_user_data.user_id user_data_id,
			DBA_USERS.account_status
		FROM 
			cf_users
			left outer join cf_user_data on (cf_users.user_id = cf_user_data.user_id)
			left join DBA_USERS on upper(cf_users.username) = upper(DBA_USERS.username)
			<cfif isDefined("state") AND state EQ "coldfusion_user">
				left join dba_role_privs on upper(cf_users.username) = upper(dba_role_privs.grantee) and upper(dba_role_privs.granted_role) = 'COLDFUSION_USER'
			</cfif>
		WHERE 
			upper(cf_users.username) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(username)#%">
			<cfif isDefined("findlastname") AND len(findlastname) GT 0>
				AND upper(LAST_NAME) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(findlastname)#%">
			</cfif>
			<cfif isDefined("state") AND state EQ "profile">
				and cf_user_data.user_id IS NOT NULL
			<cfelseif isDefined("state") AND state EQ "noprofile">
				and cf_user_data.user_id IS NULL
			<cfelseif isDefined("state") AND state EQ "invited">
				and cf_users.user_id in (select user_id from temp_allow_cf_user where allow = 1)
			<cfelseif isDefined("state") AND state EQ "oracle">
				and DBA_USERS.username IS NOT NULL
			<cfelseif isDefined("state") AND state EQ "nooracle">
				and DBA_USERS.username IS NULL
			<cfelseif isDefined("state") AND state EQ "coldfusion_user">
				and dba_role_privs.grantee IS NOT NULL
			<cfelseif isDefined("state") AND state EQ "locked">
				and DBA_USERS.lock_date IS NOT NULL
			</cfif>
		ORDER BY
			cf_users.username	
	</cfquery>
	<cfoutput>
		<h2 class="h3">#getUsers.recordcount# matching users found.</h2>
		<table id="matchedUsers" class="table table-responsive sortable col-12">
			<thead class="thead-light">
				<tr>
					<th>Action</th>
					<th>Username</th>
					<th>Profile</th>
					<th>Contact</th>
					<th>Oracle User</th>
					<th>Agent</th>
					<th>Collections</th>
				</tr>
			</thead>
			<tbody>
			<cfloop query="getUsers">
				<cfif len(getUsers.user_data_id) GT 0>
					<cfset hasProfile = "#FIRST_NAME# #LAST_NAME#">
				<cfelse>
					<cfset hasProfile = "[no]">
				</cfif>
				<!--- Some users are linked to agent records by login name --->
				<cfquery name="getAgent" datasource="uam_god">
					SELECT
						agent_name.agent_id,
						MCZBASE.get_agentnameoftype(agent_name.agent_id) agent_name
					FROM
						agent_name 
					where
						upper(agent_name) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getUsers.ucasename#">	
						and 
						agent_name_type = 'login'
				</cfquery>
				<cfif getAgent.recordcount EQ 0>
					<cfset agentRecord = "[no]">
				<cfelse>
					<cfset agentRecord = "<a href='/agents/Agent.cfm?agent_id=#getAgent.agent_id#'>#getAgent.agent_name#</a>">
				</cfif>
				<!--- "Operators" have an oracle schema --->
				<cfquery name="oracleUser" datasource="uam_god">
					SELECT count(*) ct
					FROM 
						DBA_USERS
					WHERE
						upper(username) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getUsers.ucasename#">
				</cfquery>
				<!--- users with an oracle schema can have the coldfusion_user role, and be "one of us" --->
				<cfquery name="coldfusionUserRole" datasource="uam_god">
					SELECT 
						count(*) ct
					FROM
						dba_role_privs
					WHERE
						upper(dba_role_privs.granted_role) = 'COLDFUSION_USER'
						AND
						upper(grantee) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getUsers.ucasename#">
				</cfquery>
				<!--- users with an oracle schema can be granted access to VPDs for collections --->
				<cfquery name="collectionRoles" datasource="uam_god">
					select 
						granted_role role_name
					from 
						dba_role_privs,
						collection
					where
						upper(dba_role_privs.granted_role) = upper(collection.institution_acronym) || '_' || upper(collection.collection_cde) and
						upper(grantee) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getUsers.ucasename#">
				</cfquery>
				<cfif oracleUser.ct GT 0>
					<cfset operator = "Oracle User">
					<cfif coldfusionUserRole.ct GT 0>
						<cfset operator = "One of Us">
					</cfif>
					<cfif account_status NEQ "OPEN">
						<cfset operator = "#operator#: #account_status#">
					</cfif>
				<cfelse>
					<cfset operator = "[no]">
				</cfif>
				<tr>
			 		<td><a class="btn btn-xs btn-primary" href="/Admin/AdminUsers.cfm?action=edit&username=#encodeForUrl(username)#">Edit</a></td>
			 		<td>#encodeForHtml(username)#</td>
			 		<td>#hasProfile#</td>
					<td>
						<cfif len(getUsers.user_data_id) GT 0>
							#encodeForHtml(FIRST_NAME)# #encodeForHtml(MIDDLE_NAME)# #encodeForHtml(LAST_NAME)#: #encodeForHtml(AFFILIATION)# (#encodeForHtml(EMAIL)#)
						</cfif>
					</td>
			 		<td>#operator#</td>
			 		<td>#agentRecord#</td>
					<td>#valuelist(collectionRoles.role_name," ")#</td>
				 </tr>
			</cfloop>
			</tbody>
		</table>
	</cfoutput>
</cfif>

<!-------------------------------------------------->
<cfif #Action# is "addRole" OR #Action# is "remrole">
	<!--- Grant or revoke a role, posted by the forms on the edit view.  The DDL uses only the account and
		role names the data dictionary returns, quoted; only roles the edit view offers can be granted. --->
	<cfparam name="form.username" default="">
	<cfparam name="form.role_name" default="">
	<cfoutput>
	<cfif NOT isPostWithCsrfToken()>
		<cfthrow message="Granting or revoking a role requires a post from the edit form.">
	</cfif>
	<cfset variables.databaseAccount = databaseAccountName(form.username)>
	<cfset variables.databaseRole = databaseRoleName(form.role_name)>
	<cfif len(variables.databaseAccount) EQ 0 OR len(variables.databaseRole) EQ 0>
		<p class="text-danger">That user has no database account, or that role cannot be granted here.
			<a href="/Admin/AdminUsers.cfm?action=edit&username=#encodeForUrl(form.username)#">Go back</a></p>
		<cfabort>
	</cfif>
	<cfif Action is "addRole">
		<cfquery name="grantRole" datasource="uam_god">
			GRANT "#variables.databaseRole#" TO "#variables.databaseAccount#"
		</cfquery>
	<cfelse>
		<cfquery name="revokeRole" datasource="uam_god">
			REVOKE "#variables.databaseRole#" FROM "#variables.databaseAccount#"
		</cfquery>
	</cfif>
	<cflocation url="/Admin/AdminUsers.cfm?action=edit&username=#encodeForUrl(form.username)#" addtoken="no">
	</cfoutput>
</cfif>
<!-------------------------------------------------->
<cfif #Action# is "edit">
	<cfquery name="getUsers" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		SELECT 
			cf_users.username,
			cf_users.user_id,
			cf_user_data.user_id cf_user_data_user_id,
			cf_users.approved_to_request_loans,
			FIRST_NAME,
			MIDDLE_NAME,
			LAST_NAME,
			AFFILIATION,
			EMAIL
		FROM cf_users
			left outer join cf_user_data on (cf_users.user_id = cf_user_data.user_id)
		WHERE 
			username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#username#">
	</cfquery>
	<cfquery name="ctRoleName" datasource="uam_god">
		SELECT role_name 
		FROM cf_ctuser_roles 
		WHERE 
			upper(role_name) not in (
			SELECT upper(granted_role) role_name
			FROM 
				dba_role_privs,
				cf_ctuser_roles
			WHERE
				upper(dba_role_privs.granted_role) = upper(cf_ctuser_roles.role_name) and
				upper(grantee) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(username)#">
			)
	</cfquery>
	
	<cfoutput>
	<form action="/Admin/AdminUsers.cfm" method="post">
		<input type="hidden" name="Action" value="runUpdate">
		#csrfTokenInput()#
		<input type="hidden" name="orig_username" value="#getUsers.username#">
<table>
	<tr>
		<td valign="top">
		
<table border="1">
  <tr>
    <td>Username</td>
	<td>
		<input type="text" name="username" value="#getUsers.username#">
				
	</td>
  </tr>
  
  <tr>
    <td>Password</td>
    <td>
	<input type="password" name="password">
	</td>
  </tr>
     <tr>
          <td>Approved to request loans?</td>
    <td>
		<select name="approved_to_request_loans" size="1">
			<option <cfif #getUsers.approved_to_request_loans# is "0"> selected </cfif>value="0">no</option>
			<option <cfif #getUsers.approved_to_request_loans# is "1"> selected </cfif>value="1">yes</option>
		</select>
	</td>
  </tr>
  <tr>
          <td><font color="##FF0000">Delete this user</font></td>
    <td>
		<input type="text" name="delete">(type 'delete' to delete the user)
	</td>
  </tr>
  <tr>
  	<td>Info</td>
	<td>
		#getUsers.FIRST_NAME# #getUsers.MIDDLE_NAME# #getUsers.LAST_NAME# #getUsers.AFFILIATION# #getUsers.EMAIL#
	</td>
  </tr>
  <tr>
  	<td colspan="2">
		<input type="submit" value="update">		
	</td>
  </tr>
</table>
</form>


		</td>
		<td valign="top">
		<table border>
			<cfquery name="isDbUser" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT username 
				FROM all_users 
				WHERE username=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(username)#">
			</cfquery>
			<cfquery name="getAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT 
					agent_id,
					MCZBASE.get_agentnameoftype(agent_id) agent_name
				FROM 
					agent_name,
					cf_users
				where 
					agent_name.agent_name_type='login' and
					agent_name.agent_name=cf_users.username and
					cf_users.user_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getUsers.user_id#">
			</cfquery>
			<tr>
				<td>Has User Profile:</td>
				<td>
					<cfif len(getUsers.cf_user_data_user_id) GT 0 >
						Yes
					<cfelse>
						No
					</cfif>
				</td>
			</tr>
			<tr>
				<td>Has Agent Record:</td>
				<td>
					<cfif getAgent.recordcount GT 0>
						<a href="/agents/Agent.cfm?agent_id=#getAgent.agent_id#">#getAgent.agent_name#</a>
					<cfelse>
						No
					</cfif>
				</td>
			</tr>
			<cfif len(isDbUser.username) EQ 0>
				<td>Not a Database User:</td>
				<td>
					<cfquery name="hasInvite" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						select user_id,allow from temp_allow_cf_user where user_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getUsers.user_id#">
					</cfquery>
					<cfif hasInvite.allow is 1>
						Invited, <span class="text-warning">Awaiting User Action</span>
					<cfelse>
						<cfif getAgent.recordcount GT 0 AND len(getUsers.EMAIL) GT 0>
							<form method="post" action="/Admin/AdminUsers.cfm" class="d-inline m-0">
								<input type="hidden" name="action" value="makeNewDbUser">
								#csrfTokenInput()#
								<input type="hidden" name="username" value="#encodeForHtmlAttribute(username)#">
								<input type="hidden" name="user_id" value="#encodeForHtmlAttribute(getUsers.user_id)#">
								<input type="submit" value="Invite" class="btn btn-xs btn-secondary">
							</form>
						<cfelseif len(getUsers.EMAIL) EQ 0>
							User must add an email to their profile to be invited.
						<cfelse>
							Needs a linked agent record to invite.
						</cfif>
					</cfif>
				</td>
			<cfelse> 
				<tr>
					<td>Database User Status:</td>
					<td>
						<cfif len(isDbUser.username) gt 0>
							<cfquery name="getAccountStatus" datasource="uam_god" result="getAccountStatus_result">
								SELECT account_status, lock_date, expiry_date
								FROM dba_users
								WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(username)#">
							</cfquery>
							Is User; account #encodeForHtml(lcase(getAccountStatus.account_status))#
							<cfif isDate(getAccountStatus.lock_date)>
								since #dateFormat(getAccountStatus.lock_date, "yyyy-mm-dd")#
							</cfif>
							<cfif findNoCase("LOCKED", getAccountStatus.account_status) GT 0>
								<form method="post" action="/Admin/AdminUsers.cfm" class="d-inline m-0">
									<input type="hidden" name="action" value="unlockUser">
									#csrfTokenInput()#
									<input type="hidden" name="username" value="#encodeForHtmlAttribute(username)#">
									<button type="submit" class="btn btn-xs btn-secondary">Unlock Account</button>
								</form>
							<cfelse>
								<form method="post" action="/Admin/AdminUsers.cfm" class="d-inline m-0">
									<input type="hidden" name="action" value="lockUser">
									#csrfTokenInput()#
									<input type="hidden" name="username" value="#encodeForHtmlAttribute(username)#">
									<button type="submit" class="btn btn-xs btn-warning">Lock Account</button>
								</form>
							</cfif>
							<cfif findNoCase("EXPIRED", getAccountStatus.account_status) GT 0>
								<br><span class="text-danger small">The database password has expired: set a new password in the user form, as unlocking does not renew it.</span>
							</cfif>
							<!---  check if user_search_table exists for this user --->
							<cftry>
								<cfquery name="checkUserSearchTable" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									select count(*) ct from #isDbUser.username#.USER_SEARCH_TABLE
								</cfquery>
							<cfcatch>
								Warning: #isDbUser.username#.USER_SEARCH_TABLE not found.
							</cfcatch>
							</cftry> 
						<cfelse>
						</cfif>					
					</td>
				</tr>
				<cfquery name="coldfusionUserRole" datasource="uam_god">
					SELECT 
						count(*) ct
					FROM
						dba_role_privs
					WHERE
						upper(dba_role_privs.granted_role) = 'COLDFUSION_USER'
						AND
						upper(grantee) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(isDbUser.username)#">
				</cfquery>
				<tr>
					<td>One of Us</td>
					<td>
						<cfif coldfusionUserRole.ct GT 0>
							Yes
						<cfelse>
							No
						</cfif>
					</td>
				</tr>
				<tr>
					<td colspan="2">Roles <a href="/Admin/AdminUsers.cfm?username=#encodeForUrl(username)#&action=dbRole"><img src="/images/info.gif" border="0" /></a></td>
				</tr>
				<cfquery name="roles" datasource="uam_god">
					SELECT granted_role role_name
					FROM 
						dba_role_privs,
						cf_ctuser_roles
					WHERE
						upper(dba_role_privs.granted_role) = upper(cf_ctuser_roles.role_name) and
						upper(grantee) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(username)#">
				</cfquery>
				<cfif roles.recordcount EQ 0>
					<tr>
						<td>None</td>
						<td></td>
					</tr>
				<cfelse>
					<cfloop query="roles">
						<tr>
							<td>
								#role_name# 
							</td>
							<td>
								<form method="post" action="/Admin/AdminUsers.cfm" class="d-inline m-0">
									<input type="hidden" name="action" value="remrole">
									#csrfTokenInput()#
									<input type="hidden" name="role_name" value="#encodeForHtmlAttribute(role_name)#">
									<input type="hidden" name="username" value="#encodeForHtmlAttribute(username)#">
									<button type="submit" class="btn btn-xs btn-warning">Revoke</button>
								</form>
							</td>
						</tr>
					</cfloop>
				</cfif>
				<tr class="newRec">
					<td colspan="2">Add Roles For This User</td>
				</tr>
				<form name="ar" method="post" action="/Admin/AdminUsers.cfm">
					<tr class="newRec">
						<td>
							<input type="hidden" name="action" value="addRole" />
							#csrfTokenInput()#
							<input type="hidden" name="username" value="#getUsers.username#" />
							<select name="role_name" size="1">
								<cfloop query="ctRoleName">
									<option value="#role_name#">#role_name#</option>
								</cfloop>
							</select>
						</td>
						<td>
							<input type="submit" 
								value="Grant Role" 
								class="savBtn"
								onmouseover="this.className='savBtn btnhov'"
								onmouseout="this.className='savBtn'">
							<a href="Admin/user_roles.cfm"><img src="/images/info.gif" border="0" /></a>
						</td>
					</tr>
				</form>
			</cfif>
		</table>
		</td>
		<cfif len(isDbUser.username) EQ 0>
			<!--- user must be an oracle user to have any granted roles or vpd access --->
			<td valign="top">
				<table border>
					<tr>
						<th>Collection</th>
						<th>Access</th>
					</tr>
					<tr>
						<td>All</td>
						<td>No VPD access</td>
					</tr>
				</table>
			</td>
		<cfelse>
			<cfquery name="user_croles" datasource="uam_god">
				select granted_role role_name
				from 
				dba_role_privs,
				cf_collection
				where
				upper(dba_role_privs.granted_role) = upper(cf_collection.portal_name) and
				upper(grantee) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(username)#">
				order by granted_role
			</cfquery>
			<cfquery name="croles" datasource="uam_god">
				select granted_role role_name
				from 
				dba_role_privs,
				cf_collection
				where
				upper(dba_role_privs.granted_role) = upper(cf_collection.portal_name) 
				group by granted_role
				order by granted_role
			</cfquery>
			
			<cfquery name="myroles" datasource="uam_god">
				select granted_role role_name
				from 
				dba_role_privs,
				cf_collection
				where
				upper(dba_role_privs.granted_role) = upper(cf_collection.portal_name) and
				upper(grantee) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(session.username)#">
				group by granted_role
				order by granted_role
			</cfquery>
			
			<td valign="top">
				<table border>
					<tr>
						<th>Collection</th>
						<th>Access</th>
					</tr>
					<cfloop query="user_croles">
						<tr>
							<td>#role_name#</td>
							<td>
								<form method="post" action="/Admin/AdminUsers.cfm" class="d-inline m-0">
									<input type="hidden" name="action" value="remrole">
									#csrfTokenInput()#
									<input type="hidden" name="role_name" value="#encodeForHtmlAttribute(role_name)#">
									<input type="hidden" name="username" value="#encodeForHtmlAttribute(username)#">
									<button type="submit" class="btn btn-xs btn-warning">Revoke</button>
								</form>
							</td>
						</tr>
					</cfloop>					
					<tr>
						<td colspan="2">Grant access to collections</td>
					</tr>
					
					<form name="ar" method="post" action="/Admin/AdminUsers.cfm">
						<input type="hidden" name="action" value="addRole" />
						#csrfTokenInput()#
						<input type="hidden" name="username" value="#getUsers.username#" />
						<tr>
							<td>
								<select name="role_name" size="1">
									<cfloop query="croles">
										<cfif not listfindnocase(valuelist(user_croles.role_name),role_name)
												and listfindnocase(valuelist(myroles.role_name),role_name)>
											<option value="#role_name#">#role_name#</option>
										</cfif>
									</cfloop>
								</select>
							</td>
							<td>
								<input type="submit" 
									value="Grant Access" 
									class="savBtn">
							</td>
						</tr>
					</form>
				</table>
			</td>
		</cfif>
	</tr>
</table>
	</cfoutput>

</cfif>
<!---------------------------------------------------->
<cfif #Action# is "lockUser" OR #Action# is "unlockUser">
	<!--- Posted by the Lock Account and Unlock Account forms on the edit view.  The DDL uses only the
		account name the data dictionary returns, quoted. --->
	<cfparam name="form.username" default="">
	<cfoutput>
	<cfif NOT isPostWithCsrfToken()>
		<cfthrow message="Locking or unlocking an account requires a post from the edit form.">
	</cfif>
	<!--- Also checked at the top of the page; repeated here as only global_admin may lock or unlock accounts. --->
	<cfif NOT ( isdefined("session.roles") AND listfindnocase(session.roles,"global_admin") ) >
		<cflocation url="/errors/forbidden.cfm" addtoken="false">
	</cfif>
	<cfset variables.databaseAccount = databaseAccountName(form.username)>
	<cfif len(variables.databaseAccount) EQ 0>
		<p class="text-danger">That user has no database account.
			<a href="/Admin/AdminUsers.cfm?action=edit&username=#encodeForUrl(form.username)#">Go back</a></p>
		<cfabort>
	</cfif>
	<cfif Action is "lockUser">
		<cfquery name="lock" datasource="uam_god">
			ALTER USER "#variables.databaseAccount#" ACCOUNT LOCK
		</cfquery>
	<cfelse>
		<cfquery name="unlock" datasource="uam_god">
			ALTER USER "#variables.databaseAccount#" ACCOUNT UNLOCK
		</cfquery>
	</cfif>
	<cflocation url="/Admin/AdminUsers.cfm?action=edit&username=#encodeForUrl(form.username)#" addtoken="no">
	</cfoutput>
</cfif>
<!---------------------------------------------------->
<cfif #Action# is "adminSet">
	<cfparam name="form.user_id" default="">
	<cfparam name="form.username" default="">
	<cfoutput>
		<cfif NOT isPostWithCsrfToken()>
			<cfthrow message="Removing an invitation requires a post from the edit form.">
		</cfif>
		<cfquery name="gpw" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			DELETE FROM temp_allow_cf_user 
			WHERE user_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#form.user_id#">
		</cfquery>
		<cflocation url="/Admin/AdminUsers.cfm?Action=edit&username=#encodeForUrl(form.username)#" addtoken="false">
	</cfoutput>
</cfif>
<!---------------------------------------------------->
<cfif #Action# is "makeNewDbUser">
	<cfparam name="form.user_id" default="">
	<cfparam name="form.username" default="">
	<cfoutput>
		<!--- An invitation lets the user create a database account, so it must not be forgeable from another site. --->
		<cfif NOT isPostWithCsrfToken()>
			<cfthrow message="Inviting a user requires a post from the edit form.">
		</cfif>
		<!--- see if they have all the right stuff to be a user --->
		<cfquery name="getTheirEmail" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			SELECT 
				EMAIL,
				username
			FROM 
				cf_users,
				cf_user_data
			where 
				cf_users.user_id=cf_user_data.user_id and
				cf_users.user_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#form.user_id#">
		</cfquery>
		<cfif getTheirEmail.email is "">
			<div class="text-danger">
				Error: Unable to invite. The user needs a valid email address in their profile before you can continue.
			</div>
			<cfabort>
		</cfif>
		<cfquery name="getMyEmail" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			SELECT 
				EMAIL
			FROM 
				cf_users,
				cf_user_data
			where 
				cf_users.user_id=cf_user_data.user_id and
				username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
		</cfquery>
		<cfif getMyEmail.email is "">
			<div class="text-danger">
				Error: Unable to invite. You need a valid email address in your profile before you can continue.
			</div>
			<cfabort>
		</cfif>
		<cfquery name="getAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			SELECT 
				agent_id
			FROM 
				agent_name,
				cf_users
			where 
				agent_name.agent_name_type='login' and
				agent_name.agent_name=cf_users.username and
				cf_users.user_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.user_id#">
		</cfquery>
		<cfif getAgent.agent_id is "" or getAgent.recordcount is not 1>
			<div class="text-danger">
				Error: Unable to invite.  The user needs a unique agent name of type login (found #getAgent.recordcount# matches).
			</div>
			<cfabort>
		</cfif>
		<cfif len(getTheirEmail.EMAIL) gt 0 and len(getMyEmail.EMAIL) gt 0 and getAgent.recordcount is 1>
			<cfquery name="gpw" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				insert into temp_allow_cf_user (user_id,allow,invited_by_email) 
				values (
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#form.user_id#">,
					1,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getMyEmail.EMAIL#">
				)
			</cfquery>
			<!---cfmail to="#getTheirEmail.EMAIL#" from="welcome@#Application.fromEmail#" subject="operator invitation" cc="#getMyEmail.EMAIL#,#Application.PageProblemEmail#" type="html">
				Hello, #getTheirEmail.username#.
				<br>
				You have been invited to become an MCZbase Operator by #session.username#.
				<br>The next time you log in, your Profile page (#application.serverRootUrl#/users/UserProfile.cfm)
				will contain an authentication form.
				<br>You must complete this form. If your password does not meet our rules you may be required
				to create a new password by following the link from your Profile page. 
				You will then be required to fill out the authentication form again.
				The form will be replaced with a message when you have successfully authenticated.
				<br>
				Please email #getMyEmail.EMAIL# if you have any questions, or 
				#Application.PageProblemEmail# if you believe you have received this message in error.
			</cfmail0--->
			An invitation has been sent. <a href="/Admin/AdminUsers.cfm?Action=edit&username=#encodeForUrl(form.username)#">continue</a>			
		<cfelse>
			<div>User not invited. <a href="/Admin/AdminUsers.cfm?Action=edit&username=#encodeForUrl(form.username)#">Return to edit user</a>.</div>	
		</cfif>
	</cfoutput>
</cfif>
<!---------------------------------------------------->
<cfif action is "dbRole">
	<cfoutput>
	<a href="/Admin/AdminUsers.cfm?action=edit&username=#encodeForUrl(username)#">back</a>
	<br />
		<cfquery name="rd" datasource="uam_god">
			select
			  lpad(' ', 2*level) || granted_role role
			from
			  (
			  /* THE USERS */
				select 
				  null     grantee, 
				  username granted_role
				from 
				  dba_users
				where
				  username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(username)#">
			  /* THE ROLES TO ROLES RELATIONS */ 
			  union
				select 
				  grantee,
				  granted_role
				from
				  dba_role_privs
			  /* THE ROLES TO PRIVILEGE RELATIONS */ 
			  union
				select
				  grantee,
				  privilege
				from
				  dba_sys_privs
			  )
			start with grantee is null
			connect by grantee = prior granted_role
		</cfquery>
		<cfloop query="rd">
			#replace(role," ","&nbsp;","all")#<br />
		</cfloop>
	</cfoutput>
</cfif>
<!---------------------------------------------------->
<cfif #Action# is "runUpdate">
	<!--- Posted by the edit form above.  Request values reach DDL only as the account name the data
		dictionary returns and a password the checks in databaseAccounts.cfc accept; the other SQL binds them. --->
	<cfparam name="form.orig_username" default="">
	<cfparam name="form.username" default="">
	<cfparam name="form.password" default="">
	<cfparam name="form.approved_to_request_loans" default="">
	<cfparam name="form.delete" default="">
	<cfoutput>
	<cfif NOT isPostWithCsrfToken() OR len(form.orig_username) EQ 0>
		<cfthrow message="Updating a user requires a post from the edit form.">
	</cfif>
	<cfset variables.databaseAccount = databaseAccountName(form.orig_username)>
	<cfif form.delete EQ "delete">
		<cfquery name="deleteUser" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="deleteUser_result">
			DELETE FROM cf_users
			WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.orig_username#">
		</cfquery>
		<cfif len(variables.databaseAccount) GT 0>
			<cftry>
				<cfquery name="killDB" datasource="uam_god">
					DROP USER "#variables.databaseAccount#"
				</cfquery>
			<cfcatch>
				There may have been a problem dropping this user's database account.
				<br>They are probably still connected. Contact your systems administrator.
				<cfabort>
			</cfcatch>
			</cftry>
		</cfif>
		<cflocation url="/Admin/AdminUsers.cfm" addtoken="false">
	<cfelse>
		<cfset variables.newUsername = form.orig_username>
		<cfif len(form.username) GT 0>
			<cfset variables.newUsername = form.username>
		</cfif>
		<!--- Renaming cf_users would leave the user's database account under the old name. --->
		<cfif len(variables.databaseAccount) GT 0 AND compare(variables.newUsername, form.orig_username) NEQ 0>
			<p class="text-danger">This user has a database account, so the username cannot be changed here.
				<a href="/Admin/AdminUsers.cfm?action=edit&username=#encodeForUrl(form.orig_username)#">Go back</a></p>
			<cfabort>
		</cfif>
		<!--- A new username follows the registration rules, so the user can later be given a database account. --->
		<cfif compare(variables.newUsername, form.orig_username) NEQ 0>
			<cfset variables.usernameProblem = usernameProblem(variables.newUsername, form.orig_username)>
			<cfif len(variables.usernameProblem) GT 0>
				<p class="text-danger">#encodeForHtml(variables.usernameProblem)#
					<a href="/Admin/AdminUsers.cfm?action=edit&username=#encodeForUrl(form.orig_username)#">Go back</a></p>
				<cfabort>
			</cfif>
		</cfif>
		<cfif len(form.password) GT 0 AND len(variables.databaseAccount) GT 0>
			<cfset variables.passwordProblem = databasePasswordProblem(form.password)>
			<cfif len(variables.passwordProblem) EQ 0>
				<cfset variables.passwordProblem = databasePasswordCheck(variables.databaseAccount, form.password)>
			</cfif>
			<cfif len(variables.passwordProblem) GT 0>
				<p class="text-danger">#encodeForHtml(variables.passwordProblem)#
					<a href="/Admin/AdminUsers.cfm?action=edit&username=#encodeForUrl(form.orig_username)#">Go back</a></p>
				<cfabort>
			</cfif>
			<cftry>
				<!--- DDL commits implicitly, so it runs before the cf_users update: if it fails, nothing has changed. --->
				<cfquery name="setDatabasePassword" datasource="uam_god">
					ALTER USER "#variables.databaseAccount#" IDENTIFIED BY "#form.password#"
				</cfquery>
			<cfcatch>
				<cfif isPasswordComplexityError(cfcatch)>
					<p class="text-danger">The password does not meet the database's password requirements.
						<a href="/Admin/AdminUsers.cfm?action=edit&username=#encodeForUrl(form.orig_username)#">Go back</a></p>
					<cfabort>
				</cfif>
				<cflog file="MCZbase" type="error" text="Setting the database password for #form.orig_username# failed: #cfcatch.message#">
				There was a problem updating this user's database password; nothing was changed.
				<cfabort>
			</cfcatch>
			</cftry>
		</cfif>
		<cfquery name="updateUser" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="updateUser_result">
			UPDATE cf_users
			SET
				username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.newUsername#">
				<cfif len(form.password) GT 0>
					,password = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#hash(form.password)#">
				</cfif>
				<cfif len(form.approved_to_request_loans) GT 0>
					,approved_to_request_loans = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#form.approved_to_request_loans#">
				</cfif>
			WHERE
				username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.orig_username#">
		</cfquery>
		<cflocation url="/Admin/AdminUsers.cfm?action=edit&username=#encodeForUrl(variables.newUsername)#" addtoken="false">
	</cfif>
	</cfoutput>
</cfif>

	</section>
</main>
<cfinclude template = "/shared/_footer.cfm">
