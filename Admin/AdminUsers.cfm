<!---
Admin/AdminUsers.cfm

Copyright 2008-2017 Contributors to Arctos
Copyright 2008-2026 President and Fellows of Harvard College

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
<!--- Find MCZbase users, and edit a user: username, password, loan approval, database account
	lock, MCZbase login lock, roles and collection access.  Searches and views are GET requests; every change is a
	POST with the session token (requestForgery.cfc). --->
<cfset pageTitle="Administer Users">
<cfinclude template = "/shared/_header.cfm">
<cfinclude template="/shared/component/databaseAccounts.cfc" runOnce="true">
<cfinclude template="/shared/component/requestForgery.cfc" runOnce="true">
<cfif NOT isDefined("loginLocks")>
	<cfinclude template="/shared/component/loginThrottle.cfc" runOnce="true">
</cfif>

<cfif NOT ( isdefined("session.roles") AND listfindnocase(session.roles,"global_admin") ) >
	<!--- this should be handled by rolecheck but add another layer here to make sure of access control --->
	<cflocation url="/errors/forbidden.cfm" addtoken="false">
</cfif>

<!--- Creating a database account through an invitation and makeUser on the user's profile page
	does not work (Redmine #837), so the Invite action shows instructions for creating the account
	by hand instead.  Set to true to record invitations again. --->
<cfset INVITATIONS_ENABLED = false>

<cfparam name="url.action" default="">
<cfparam name="form.action" default="">
<cfparam name="url.username" default="">
<cfparam name="url.findlastname" default="">
<cfparam name="url.state" default="all">
<cfset variables.action = url.action>
<cfif len(form.action) GT 0>
	<cfset variables.action = form.action>
</cfif>
<cfset variables.username = url.username>
<cfset variables.findlastname = url.findlastname>
<cfset variables.state = url.state>

<main class="container py-3" id="content">
	<cfoutput>
		<section class="row mx-0 mb-3" role="search">
			<div class="search-box">
				<div class="search-box-header">
					<h1 class="h3 text-white" id="formheading">Manage MCZbase Users</h1>
				</div>
				<div class="col-12 px-4 py-2">
					<form name="findUsers" id="findUsers" action="/Admin/AdminUsers.cfm" method="get">
						<input type="hidden" name="action" value="list">
						<div class="form-row">
							<div class="col-12 col-md-4">
								<label for="username" class="data-entry-label">Username</label>
								<input type="text" name="username" id="username" class="data-entry-input" value="#encodeForHtmlAttribute(variables.username)#">
							</div>
							<div class="col-12 col-md-4">
								<label for="findlastname" class="data-entry-label">Last Name</label>
								<input type="text" name="findlastname" id="findlastname" class="data-entry-input" value="#encodeForHtmlAttribute(variables.findlastname)#">
							</div>
							<div class="col-12 col-md-4">
								<label for="state" class="data-entry-label">State</label>
								<select name="state" id="state" class="data-entry-select">
									<cfloop list="all:All,profile:Has Profile,invited:Invited to become an operator,oracle:Has Oracle User,coldfusion_user:One of Us,noprofile:No Profile,nooracle:No Oracle User,locked:Locked Account" index="variables.stateOption">
										<cfset variables.stateValue = listFirst(variables.stateOption, ":")>
										<cfset selected = "">
										<cfif variables.state EQ variables.stateValue>
											<cfset selected = "selected">
										</cfif>
										<option value="#variables.stateValue#" #selected#>#listRest(variables.stateOption, ":")#</option>
									</cfloop>
								</select>
							</div>
						</div>
						<div class="form-row my-2">
							<div class="col-12">
								<input type="submit" value="Find" class="btn btn-xs btn-primary">
								<a href="/Admin/AdminUsers.cfm" class="btn btn-xs btn-warning">New Search</a>
								<a href="/Admin/AdminUsers.cfm?action=loginLocks" class="btn btn-xs btn-info">Login Locks</a>
							</div>
						</div>
					</form>
				</div>
			</div>
		</section>
	</cfoutput>

<cfif variables.action EQ "list">
	<!--- usernames whose MCZbase logins are locked after repeated failures (loginThrottle.cfc) --->
	<cfset loginLocked = loginLocks()>
	<cfquery name="lockedUsernames" dbtype="query">
		SELECT lock_key, locked_until FROM loginLocked WHERE kind = 'username' AND is_locked = 1
	</cfquery>
	<cfset variables.loginLockedUntil = structNew()>
	<cfloop query="lockedUsernames">
		<cfset variables.loginLockedUntil[lockedUsernames.lock_key] = lockedUsernames.locked_until>
	</cfloop>
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
			<cfif variables.state EQ "coldfusion_user">
				left join dba_role_privs on upper(cf_users.username) = upper(dba_role_privs.grantee) and upper(dba_role_privs.granted_role) = 'COLDFUSION_USER'
			</cfif>
		WHERE
			upper(cf_users.username) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(variables.username)#%">
			<cfif len(variables.findlastname) GT 0>
				AND upper(LAST_NAME) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(variables.findlastname)#%">
			</cfif>
			<cfif variables.state EQ "profile">
				and cf_user_data.user_id IS NOT NULL
			<cfelseif variables.state EQ "noprofile">
				and cf_user_data.user_id IS NULL
			<cfelseif variables.state EQ "invited">
				and cf_users.user_id in (select user_id from temp_allow_cf_user where allow = 1)
			<cfelseif variables.state EQ "oracle">
				and DBA_USERS.username IS NOT NULL
			<cfelseif variables.state EQ "nooracle">
				and DBA_USERS.username IS NULL
			<cfelseif variables.state EQ "coldfusion_user">
				and dba_role_privs.grantee IS NOT NULL
			<cfelseif variables.state EQ "locked">
				<!--- locked in Oracle, or locked out of MCZbase logins after repeated failures --->
				and (
					DBA_USERS.lock_date IS NOT NULL
					<cfif lockedUsernames.recordcount GT 0>
						OR lower(cf_users.username) IN (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#valueList(lockedUsernames.lock_key)#" list="yes">)
					</cfif>
				)
			</cfif>
		ORDER BY
			cf_users.username
	</cfquery>
	<cfoutput>
		<section class="row mx-0 mb-4">
			<div class="col-12">
				<h2 class="h3">#getUsers.recordcount# matching users found.</h2>
				<table id="matchedUsers" class="table table-responsive d-xl-table table-sm table-striped sortable">
					<thead class="thead-light">
						<tr>
							<th scope="col">Action</th>
							<th scope="col">Username</th>
							<th scope="col">Profile</th>
							<th scope="col">Contact</th>
							<th scope="col">Oracle User</th>
							<th scope="col">Agent</th>
							<th scope="col">Collections</th>
						</tr>
					</thead>
					<tbody>
						<cfloop query="getUsers">
							<cfif len(getUsers.user_data_id) GT 0>
								<cfset hasProfile = encodeForHtml("#getUsers.FIRST_NAME# #getUsers.LAST_NAME#")>
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
								<cfset agentRecord = "<a href='/agents/Agent.cfm?agent_id=#encodeForUrl(getAgent.agent_id)#'>#encodeForHtml(getAgent.agent_name)#</a>">
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
								<cfif getUsers.account_status NEQ "OPEN">
									<cfset operator = "#operator#: #lcase(getUsers.account_status)#">
								</cfif>
							<cfelse>
								<cfset operator = "[no]">
							</cfif>
							<tr>
								<td><a class="btn btn-xs btn-outline-primary" href="/Admin/AdminUsers.cfm?action=edit&username=#encodeForUrl(getUsers.username)#">Edit</a></td>
								<td>
									#encodeForHtml(getUsers.username)#
									<cfif structKeyExists(variables.loginLockedUntil, lcase(getUsers.username))>
										<span class="badge badge-danger" title="MCZbase logins locked after repeated failures">login locked</span>
									</cfif>
									<cfif findNoCase("LOCKED", getUsers.account_status) GT 0>
										<span class="badge badge-danger" title="Oracle account #encodeForHtmlAttribute(lcase(getUsers.account_status))#">oracle locked</span>
									</cfif>
								</td>
								<td>#hasProfile#</td>
								<td>
									<cfif len(getUsers.user_data_id) GT 0>
										#encodeForHtml(getUsers.FIRST_NAME)# #encodeForHtml(getUsers.MIDDLE_NAME)# #encodeForHtml(getUsers.LAST_NAME)#: #encodeForHtml(getUsers.AFFILIATION)# (#encodeForHtml(getUsers.EMAIL)#)
									</cfif>
								</td>
								<td>#encodeForHtml(operator)#</td>
								<td>#agentRecord#</td>
								<td>#encodeForHtml(valuelist(collectionRoles.role_name," "))#</td>
							</tr>
						</cfloop>
					</tbody>
				</table>
			</div>
		</section>
	</cfoutput>
</cfif>

<!-------------------------------------------------->
<cfif variables.action EQ "addRole" OR variables.action EQ "remrole">
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
		<div class="alert alert-danger">That user has no database account, or that role cannot be granted here.
			<a href="/Admin/AdminUsers.cfm?action=edit&username=#encodeForUrl(form.username)#">Go back</a></div>
		<cfabort>
	</cfif>
	<cfif variables.action EQ "addRole">
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
<cfif variables.action EQ "edit">
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
			username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.username#">
			<!--- links built from the data dictionary carry the username in upper case: match regardless of
				case when there is no exact match --->
			OR (
				upper(username) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(variables.username)#">
				AND NOT EXISTS (
					SELECT 1 FROM cf_users exact_user
					WHERE exact_user.username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.username#">
				)
			)
	</cfquery>
	<cfif getUsers.recordcount GT 1>
		<cfoutput>
			<div class="alert alert-warning">More than one user has the username #encodeForHtml(variables.username)# in some mix of case:
				<a href="/Admin/AdminUsers.cfm?action=list&username=#encodeForUrl(variables.username)#">list them</a>.</div>
		</cfoutput>
	<cfelseif getUsers.recordcount NEQ 1>
		<cfoutput>
			<div class="alert alert-warning">No user found with the username #encodeForHtml(variables.username)#.</div>
		</cfoutput>
	<cfelse>
	<cfset variables.username = getUsers.username>
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
				upper(grantee) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(variables.username)#">
			)
	</cfquery>
	<cfquery name="isDbUser" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		SELECT username
		FROM all_users
		WHERE username=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(variables.username)#">
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
	<cfset approvedNo = "">
	<cfset approvedYes = "">
	<cfif getUsers.approved_to_request_loans EQ "1">
		<cfset approvedYes = "selected">
	<cfelse>
		<cfset approvedNo = "selected">
	</cfif>
	<cfoutput>
	<section class="row mx-0">
		<div class="col-12 px-0">
			<h2 class="h3">
				User #encodeForHtml(getUsers.username)#
				<cfif len(getUsers.cf_user_data_user_id) GT 0>
					<span class="small">#encodeForHtml(getUsers.FIRST_NAME)# #encodeForHtml(getUsers.MIDDLE_NAME)# #encodeForHtml(getUsers.LAST_NAME)#, #encodeForHtml(getUsers.AFFILIATION)# #encodeForHtml(getUsers.EMAIL)#</span>
				</cfif>
			</h2>
		</div>
	</section>
	<section class="row mx-0">
		<div class="col-12 col-md-6 pl-0 pr-0 pr-md-2">
			<div class="card mb-2 bg-light">
				<div class="card-header py-0">
					<h3 class="h4 my-1 mx-2 px-2">Account</h3>
				</div>
				<div class="card-body py-2">
					<form name="updateUser" id="updateUser" action="/Admin/AdminUsers.cfm" method="post">
						<input type="hidden" name="action" value="runUpdate">
						#csrfTokenInput()#
						<input type="hidden" name="orig_username" value="#encodeForHtmlAttribute(getUsers.username)#">
						<div class="form-row">
							<div class="col-12 col-xl-6 mb-1">
								<label for="edit_username" class="data-entry-label">Username</label>
								<input type="text" name="username" id="edit_username" class="data-entry-input" value="#encodeForHtmlAttribute(getUsers.username)#">
							</div>
							<div class="col-12 col-xl-6 mb-1">
								<label for="edit_password" class="data-entry-label">New password</label>
								<input type="password" name="password" id="edit_password" class="data-entry-input" autocomplete="new-password">
							</div>
							<div class="col-12 col-xl-6 mb-1">
								<label for="approved_to_request_loans" class="data-entry-label">Approved to request loans?</label>
								<select name="approved_to_request_loans" id="approved_to_request_loans" class="data-entry-select">
									<option value="0" #approvedNo#>no</option>
									<option value="1" #approvedYes#>yes</option>
								</select>
							</div>
							<div class="col-12 col-xl-6 mb-1">
								<label for="edit_delete" class="data-entry-label text-danger">Delete this user (type delete)</label>
								<input type="text" name="delete" id="edit_delete" class="data-entry-input">
							</div>
						</div>
						<div class="form-row mt-2">
							<div class="col-12">
								<input type="submit" value="Save" class="btn btn-xs btn-primary">
							</div>
						</div>
					</form>
				</div>
			</div>
		</div>
		<div class="col-12 col-md-6 pl-0 pl-md-2 pr-0">
			<div class="card mb-2 bg-light">
				<div class="card-header py-0">
					<h3 class="h4 my-1 mx-2 px-2">Status</h3>
				</div>
				<div class="card-body py-2">
					<ul class="list-unstyled mb-0">
						<li>
							Has User Profile:
							<cfif len(getUsers.cf_user_data_user_id) GT 0 >
								Yes
							<cfelse>
								No
							</cfif>
						</li>
						<li>
							Has Agent Record:
							<cfif getAgent.recordcount GT 0>
								<a href="/agents/Agent.cfm?agent_id=#encodeForUrl(getAgent.agent_id)#">#encodeForHtml(getAgent.agent_name)#</a>
							<cfelse>
								No
							</cfif>
						</li>
						<cfset variables.userLoginLockedUntil = usernameLoginLockedUntil(getUsers.username)>
						<li>
							MCZbase Login:
							<cfif len(variables.userLoginLockedUntil) GT 0>
								<span class="badge badge-danger">locked</span>
								after repeated failed logins, until #dateTimeFormat(variables.userLoginLockedUntil, "yyyy-mm-dd HH:nn")#
								<form method="post" action="/Admin/AdminUsers.cfm" class="d-inline m-0">
									<input type="hidden" name="action" value="clearLoginLock">
									#csrfTokenInput()#
									<input type="hidden" name="kind" value="username">
									<input type="hidden" name="key" value="#encodeForHtmlAttribute(getUsers.username)#">
									<input type="hidden" name="returnTo" value="edit">
									<button type="submit" class="btn btn-xs btn-secondary">Clear Login Lock</button>
								</form>
							<cfelse>
								not locked
							</cfif>
						</li>
						<cfif len(isDbUser.username) EQ 0>
							<li>
								Not a Database User:
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
											<input type="hidden" name="username" value="#encodeForHtmlAttribute(getUsers.username)#">
											<input type="hidden" name="user_id" value="#encodeForHtmlAttribute(getUsers.user_id)#">
											<input type="submit" value="Invite" class="btn btn-xs btn-secondary">
										</form>
									<cfelseif len(getUsers.EMAIL) EQ 0>
										User must add an email to their profile to be invited.
									<cfelse>
										Needs a linked agent record to invite.
									</cfif>
								</cfif>
							</li>
						<cfelse>
							<cfquery name="getAccountStatus" datasource="uam_god" result="getAccountStatus_result">
								SELECT account_status, lock_date, expiry_date
								FROM dba_users
								WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(variables.username)#">
							</cfquery>
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
							<li>
								Database User Status:
								<cfif findNoCase("LOCKED", getAccountStatus.account_status) GT 0>
									<span class="badge badge-danger">oracle locked</span>
								</cfif>
								account #encodeForHtml(lcase(getAccountStatus.account_status))#
								<cfif isDate(getAccountStatus.lock_date)>
									since #dateFormat(getAccountStatus.lock_date, "yyyy-mm-dd")#
								</cfif>
								<cfif findNoCase("LOCKED", getAccountStatus.account_status) GT 0>
									<form method="post" action="/Admin/AdminUsers.cfm" class="d-inline m-0">
										<input type="hidden" name="action" value="unlockUser">
										#csrfTokenInput()#
										<input type="hidden" name="username" value="#encodeForHtmlAttribute(getUsers.username)#">
										<button type="submit" class="btn btn-xs btn-secondary">Unlock Account</button>
									</form>
								<cfelse>
									<form method="post" action="/Admin/AdminUsers.cfm" class="d-inline m-0">
										<input type="hidden" name="action" value="lockUser">
										#csrfTokenInput()#
										<input type="hidden" name="username" value="#encodeForHtmlAttribute(getUsers.username)#">
										<button type="submit" class="btn btn-xs btn-warning">Lock Account</button>
									</form>
								</cfif>
								<cfif findNoCase("EXPIRED", getAccountStatus.account_status) GT 0>
									<br><span class="text-danger small">The database password has expired: set a new password in the account form, as unlocking does not renew it.</span>
								</cfif>
								<!---  check if user_search_table exists for this user; the schema name comes from the data dictionary, checked by databaseAccountName --->
								<cfset variables.searchTableSchema = databaseAccountName(variables.username)>
								<cftry>
									<cfquery name="checkUserSearchTable" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
										select count(*) ct from "#variables.searchTableSchema#".USER_SEARCH_TABLE
									</cfquery>
								<cfcatch>
									<br><span class="text-warning small">Warning: #encodeForHtml(isDbUser.username)#.USER_SEARCH_TABLE not found.</span>
								</cfcatch>
								</cftry>
							</li>
							<li>
								One of Us:
								<cfif coldfusionUserRole.ct GT 0>
									Yes
								<cfelse>
									No
								</cfif>
							</li>
						</cfif>
					</ul>
				</div>
			</div>
		</div>
	</section>
	<section class="row mx-0">
		<cfif len(isDbUser.username) GT 0>
			<cfquery name="roles" datasource="uam_god">
				SELECT granted_role role_name
				FROM
					dba_role_privs,
					cf_ctuser_roles
				WHERE
					upper(dba_role_privs.granted_role) = upper(cf_ctuser_roles.role_name) and
					upper(grantee) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(variables.username)#">
			</cfquery>
			<div class="col-12 col-md-6 pl-0 pr-0 pr-md-2">
				<div class="card mb-2 bg-light">
					<div class="card-header py-0">
						<h3 class="h4 my-1 mx-2 px-2">
							Roles
							<a href="/Admin/AdminUsers.cfm?action=dbRole&username=#encodeForUrl(getUsers.username)#" class="small ml-2">role tree</a>
							<a href="/Admin/user_roles.cfm" class="small ml-2">role definitions</a>
						</h3>
					</div>
					<div class="card-body py-2">
						<table class="table table-sm mb-2">
							<tbody>
								<cfif roles.recordcount EQ 0>
									<tr><td>None</td><td></td></tr>
								<cfelse>
									<cfloop query="roles">
										<tr>
											<td>#encodeForHtml(roles.role_name)#</td>
											<td>
												<form method="post" action="/Admin/AdminUsers.cfm" class="d-inline m-0">
													<input type="hidden" name="action" value="remrole">
													#csrfTokenInput()#
													<input type="hidden" name="role_name" value="#encodeForHtmlAttribute(roles.role_name)#">
													<input type="hidden" name="username" value="#encodeForHtmlAttribute(getUsers.username)#">
													<button type="submit" class="btn btn-xs btn-warning">Revoke</button>
												</form>
											</td>
										</tr>
									</cfloop>
								</cfif>
							</tbody>
						</table>
						<form name="addRoleForm" id="addRoleForm" method="post" action="/Admin/AdminUsers.cfm">
							<input type="hidden" name="action" value="addRole">
							#csrfTokenInput()#
							<input type="hidden" name="username" value="#encodeForHtmlAttribute(getUsers.username)#">
							<div class="form-row">
								<div class="col-8">
									<label for="add_role_name" class="data-entry-label">Add a role for this user</label>
									<select name="role_name" id="add_role_name" class="data-entry-select">
										<cfloop query="ctRoleName">
											<option value="#encodeForHtmlAttribute(ctRoleName.role_name)#">#encodeForHtml(ctRoleName.role_name)#</option>
										</cfloop>
									</select>
								</div>
								<div class="col-4 d-flex align-items-end">
									<input type="submit" value="Grant Role" class="btn btn-xs btn-secondary">
								</div>
							</div>
						</form>
					</div>
				</div>
			</div>
			<cfquery name="user_croles" datasource="uam_god">
				select granted_role role_name
				from
				dba_role_privs,
				cf_collection
				where
				upper(dba_role_privs.granted_role) = upper(cf_collection.portal_name) and
				upper(grantee) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(variables.username)#">
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
			<div class="col-12 col-md-6 pl-0 pl-md-2 pr-0">
				<div class="card mb-2 bg-light">
					<div class="card-header py-0">
						<h3 class="h4 my-1 mx-2 px-2">Collection Access</h3>
					</div>
					<div class="card-body py-2">
						<table class="table table-sm mb-2">
							<tbody>
								<cfif user_croles.recordcount EQ 0>
									<tr><td>None</td><td></td></tr>
								</cfif>
								<cfloop query="user_croles">
									<tr>
										<td>#encodeForHtml(user_croles.role_name)#</td>
										<td>
											<form method="post" action="/Admin/AdminUsers.cfm" class="d-inline m-0">
												<input type="hidden" name="action" value="remrole">
												#csrfTokenInput()#
												<input type="hidden" name="role_name" value="#encodeForHtmlAttribute(user_croles.role_name)#">
												<input type="hidden" name="username" value="#encodeForHtmlAttribute(getUsers.username)#">
												<button type="submit" class="btn btn-xs btn-warning">Revoke</button>
											</form>
										</td>
									</tr>
								</cfloop>
							</tbody>
						</table>
						<form name="addCollectionForm" id="addCollectionForm" method="post" action="/Admin/AdminUsers.cfm">
							<input type="hidden" name="action" value="addRole">
							#csrfTokenInput()#
							<input type="hidden" name="username" value="#encodeForHtmlAttribute(getUsers.username)#">
							<div class="form-row">
								<div class="col-8">
									<label for="add_collection_role" class="data-entry-label">Grant access to a collection (those you can access)</label>
									<select name="role_name" id="add_collection_role" class="data-entry-select">
										<cfloop query="croles">
											<cfif not listfindnocase(valuelist(user_croles.role_name),croles.role_name)
													and listfindnocase(valuelist(myroles.role_name),croles.role_name)>
												<option value="#encodeForHtmlAttribute(croles.role_name)#">#encodeForHtml(croles.role_name)#</option>
											</cfif>
										</cfloop>
									</select>
								</div>
								<div class="col-4 d-flex align-items-end">
									<input type="submit" value="Grant Access" class="btn btn-xs btn-secondary">
								</div>
							</div>
						</form>
					</div>
				</div>
			</div>
		<cfelse>
			<!--- user must be an oracle user to have any granted roles or vpd access --->
			<div class="col-12 px-0">
				<div class="card mb-2 bg-light">
					<div class="card-header py-0">
						<h3 class="h4 my-1 mx-2 px-2">Roles and Collection Access</h3>
					</div>
					<div class="card-body py-2">
						No database account, so no roles and no VPD access to any collection.
					</div>
				</div>
			</div>
		</cfif>
	</section>
	<cfquery name="getDownloadsByPurpose" datasource="cf_dbuser" result="getDownloadsByPurpose_result">
		SELECT
			download_purpose,
			count(*) AS downloads,
			sum(num_records) AS records,
			to_char(max(download_date), 'yyyy-mm-dd') AS latest
		FROM cf_download
		WHERE
			user_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getUsers.user_id#" null="#len(getUsers.user_id) EQ 0#">
		GROUP BY download_purpose
		ORDER BY count(*) DESC
	</cfquery>
	<cfquery name="getDownloadTotals" dbtype="query">
		SELECT sum(downloads) AS downloads, sum(records) AS records, max(latest) AS latest
		FROM getDownloadsByPurpose
	</cfquery>
	<cfquery name="getFileRequests" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getFileRequests_result">
		SELECT
			status,
			count(*) AS requests,
			to_char(max(time_created), 'yyyy-mm-dd') AS latest
		FROM cf_download_file
		WHERE
			username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getUsers.username#">
		GROUP BY status
		ORDER BY count(*) DESC
	</cfquery>
	<section class="row mx-0 mb-4">
		<div class="col-12 px-0">
			<div class="card mb-2 bg-light">
				<div class="card-header py-0">
					<h3 class="h4 my-1 mx-2 px-2">Downloads</h3>
				</div>
				<div class="card-body py-2">
					<cfif getDownloadsByPurpose.recordcount EQ 0>
						<p class="mb-1">No downloads logged for this user.</p>
					<cfelse>
						<p class="mb-1">
							#getDownloadTotals.downloads# downloads of #numberFormat(getDownloadTotals.records)# records in total;
							most recent #getDownloadTotals.latest#.
							<a href="/Admin/download.cfm?username=#encodeForUrl("=" & getUsers.username)#&execute=true">List these downloads</a>.
						</p>
						<table class="table table-responsive d-xl-table table-sm">
							<thead class="thead-light">
								<tr><th scope="col">Purpose</th><th scope="col">Downloads</th><th scope="col">Records</th><th scope="col">Most recent</th></tr>
							</thead>
							<tbody>
								<cfloop query="getDownloadsByPurpose">
									<tr>
										<td>#encodeForHtml(getDownloadsByPurpose.download_purpose)#</td>
										<td>#getDownloadsByPurpose.downloads#</td>
										<td>#numberFormat(getDownloadsByPurpose.records)#</td>
										<td>#getDownloadsByPurpose.latest#</td>
									</tr>
								</cfloop>
							</tbody>
						</table>
					</cfif>
					<cfif getFileRequests.recordcount GT 0>
						<h4 class="h5">Specimen CSV file requests</h4>
						<table class="table table-responsive d-xl-table table-sm">
							<thead class="thead-light">
								<tr><th scope="col">Status</th><th scope="col">Requests</th><th scope="col">Most recent</th></tr>
							</thead>
							<tbody>
								<cfloop query="getFileRequests">
									<tr>
										<td>#encodeForHtml(getFileRequests.status)#</td>
										<td>#getFileRequests.requests#</td>
										<td>#getFileRequests.latest#</td>
									</tr>
								</cfloop>
							</tbody>
						</table>
					</cfif>
				</div>
			</div>
		</div>
	</section>
	</cfoutput>
	</cfif>
</cfif>
<!---------------------------------------------------->
<cfif variables.action EQ "loginLocks">
	<!--- MCZbase login locks and recent failures (loginThrottle.cfc), held in memory until they expire
		or the server restarts.  Oracle account locks are shown and cleared on each user's edit view. --->
	<cfset variables.locks = loginLocks()>
	<cfset variables.throttleSettings = loginThrottleSettings()>
	<cfoutput>
		<section class="row mx-0 mb-4">
			<div class="col-12">
				<h2 class="h3">Login Locks</h2>
				<p>
					A username is locked for #variables.throttleSettings.lockMinutes# minutes after
					#variables.throttleSettings.usernameLimit# failed logins within #variables.throttleSettings.windowMinutes# minutes,
					and a client address after #variables.throttleSettings.addressLimit#. Usernames that don't exist are counted too.
					These are held in memory and are cleared by a restart. Oracle account locks are shown on each user's edit page,
					and found by the Locked Account search.
				</p>
				<cfif variables.locks.recordcount EQ 0>
					<p>No locks or recent failures.</p>
				<cfelse>
					<table class="table table-responsive d-xl-table table-sm table-striped">
						<thead class="thead-light">
							<tr>
								<th scope="col">Kind</th>
								<th scope="col">Username or Address</th>
								<th scope="col">Failures</th>
								<th scope="col">Since</th>
								<th scope="col">Locked Until</th>
								<th scope="col">Action</th>
							</tr>
						</thead>
						<tbody>
							<cfloop query="variables.locks">
								<tr>
									<td>#encodeForHtml(variables.locks.kind)#</td>
									<td>
										<cfif variables.locks.kind EQ "username">
											<a href="/Admin/AdminUsers.cfm?action=edit&username=#encodeForUrl(variables.locks.lock_key)#">#encodeForHtml(variables.locks.lock_key)#</a>
										<cfelse>
											#encodeForHtml(variables.locks.lock_key)#
										</cfif>
									</td>
									<td>#encodeForHtml(variables.locks.failures)#</td>
									<td>#dateTimeFormat(variables.locks.window_start, "yyyy-mm-dd HH:nn")#</td>
									<td>
										<cfif variables.locks.is_locked EQ 1>
											<span class="badge badge-danger">locked</span> #encodeForHtml(variables.locks.locked_until)#
										</cfif>
									</td>
									<td>
										<form method="post" action="/Admin/AdminUsers.cfm" class="d-inline m-0">
											<input type="hidden" name="action" value="clearLoginLock">
											#csrfTokenInput()#
											<input type="hidden" name="kind" value="#encodeForHtmlAttribute(variables.locks.kind)#">
											<input type="hidden" name="key" value="#encodeForHtmlAttribute(variables.locks.lock_key)#">
											<input type="hidden" name="returnTo" value="loginLocks">
											<button type="submit" class="btn btn-xs btn-warning">Clear</button>
										</form>
									</td>
								</tr>
							</cfloop>
						</tbody>
					</table>
				</cfif>
			</div>
		</section>
	</cfoutput>
</cfif>
<!---------------------------------------------------->
<cfif variables.action EQ "clearLoginLock">
	<!--- Posted by the Clear buttons on the edit view and the Login Locks view. --->
	<cfparam name="form.kind" default="">
	<cfparam name="form.key" default="">
	<cfparam name="form.returnTo" default="loginLocks">
	<cfif NOT isPostWithCsrfToken()>
		<cfthrow message="Clearing a login lock requires a post from this page.">
	</cfif>
	<cfif NOT listFind("username,address", form.kind)>
		<cfthrow message="Unknown kind of login lock.">
	</cfif>
	<cfset clearLoginLock(form.kind, form.key)>
	<cflog file="MCZbase" text="loginThrottle: #form.kind# #form.key# login lock cleared by #session.username#">
	<cfif form.returnTo EQ "edit">
		<cflocation url="/Admin/AdminUsers.cfm?action=edit&username=#encodeForUrl(form.key)#" addtoken="false">
	<cfelse>
		<cflocation url="/Admin/AdminUsers.cfm?action=loginLocks" addtoken="false">
	</cfif>
</cfif>
<!---------------------------------------------------->
<cfif variables.action EQ "lockUser" OR variables.action EQ "unlockUser">
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
		<div class="alert alert-danger">That user has no database account.
			<a href="/Admin/AdminUsers.cfm?action=edit&username=#encodeForUrl(form.username)#">Go back</a></div>
		<cfabort>
	</cfif>
	<cfif variables.action EQ "lockUser">
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
<cfif variables.action EQ "adminSet">
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
		<cflocation url="/Admin/AdminUsers.cfm?action=edit&username=#encodeForUrl(form.username)#" addtoken="false">
	</cfoutput>
</cfif>
<!---------------------------------------------------->
<cfif variables.action EQ "makeNewDbUser">
	<cfparam name="form.user_id" default="">
	<cfparam name="form.username" default="">
	<cfoutput>
		<!--- An invitation lets the user create a database account, so it must not be forgeable from another site. --->
		<cfif NOT isPostWithCsrfToken()>
			<cfthrow message="Inviting a user requires a post from the edit form.">
		</cfif>
		<cfif NOT INVITATIONS_ENABLED>
			<div class="alert alert-danger">
				<p>Error: Unable to invite.  Database accounts cannot currently be created through an
					invitation (Redmine ##837).  Create the account by hand, following
					<a href="https://code.mcz.harvard.edu/redmine/projects/mczbase-application-and-database/wiki/MCZbase_User_Creation" target="_blank">MCZbase User Creation</a>.</p>
				<cfif len(form.username) GT 0 AND len(newDatabaseAccountName(form.username)) EQ 0>
					<p>The username #encodeForHtml(form.username)# cannot be used as a database account name: it is
						already a database account or role, or it is not a plain identifier (a letter, then
						letters, digits and underscores).  An email address must first be changed to such a
						username on this page.</p>
				</cfif>
				<a href="/Admin/AdminUsers.cfm?action=edit&username=#encodeForUrl(form.username)#">Return to edit user</a>.
			</div>
		<cfelse>
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
				<div class="alert alert-danger">
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
				<div class="alert alert-danger">
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
				<div class="alert alert-danger">
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
				<div class="alert alert-success">An invitation has been sent. <a href="/Admin/AdminUsers.cfm?action=edit&username=#encodeForUrl(form.username)#">continue</a></div>
			<cfelse>
				<div class="alert alert-warning">User not invited. <a href="/Admin/AdminUsers.cfm?action=edit&username=#encodeForUrl(form.username)#">Return to edit user</a>.</div>
			</cfif>
		</cfif>
	</cfoutput>
</cfif>
<!---------------------------------------------------->
<cfif variables.action EQ "dbRole">
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
			  username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(variables.username)#">
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
	<cfoutput>
		<section class="row mx-0 mb-4">
			<div class="col-12 px-0">
				<div class="card mb-2 bg-light">
					<div class="card-header py-0">
						<h2 class="h4 my-1 mx-2 px-2">
							Database roles and privileges of #encodeForHtml(variables.username)#
							<a href="/Admin/AdminUsers.cfm?action=edit&username=#encodeForUrl(variables.username)#" class="small ml-2">back to user</a>
						</h2>
					</div>
					<div class="card-body py-2">
						<cfif rd.recordcount EQ 0>
							No database account.
						<cfelse>
							<pre class="mb-0">#encodeForHtml(valueList(rd.role, chr(10)))#</pre>
						</cfif>
					</div>
				</div>
			</div>
		</section>
	</cfoutput>
</cfif>
<!---------------------------------------------------->
<cfif variables.action EQ "runUpdate">
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
		<!--- cf_password_reset has no foreign key to cf_users; a user_id can be reused by the next new user. --->
		<cfquery name="deleteResetTokens" datasource="uam_god" result="deleteResetTokens_result">
			DELETE FROM cf_password_reset
			WHERE user_id IN (
				SELECT user_id FROM cf_users
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.orig_username#">
			)
		</cfquery>
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
				<div class="alert alert-danger">There may have been a problem dropping this user's database account.
					They are probably still connected. Contact your systems administrator.</div>
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
			<div class="alert alert-danger">This user has a database account, so the username cannot be changed here.
				<a href="/Admin/AdminUsers.cfm?action=edit&username=#encodeForUrl(form.orig_username)#">Go back</a></div>
			<cfabort>
		</cfif>
		<!--- A new username follows the registration rules, so the user can later be given a database account. --->
		<cfif compare(variables.newUsername, form.orig_username) NEQ 0>
			<cfset variables.usernameProblem = usernameProblem(variables.newUsername, form.orig_username)>
			<cfif len(variables.usernameProblem) GT 0>
				<div class="alert alert-danger">#encodeForHtml(variables.usernameProblem)#
					<a href="/Admin/AdminUsers.cfm?action=edit&username=#encodeForUrl(form.orig_username)#">Go back</a></div>
				<cfabort>
			</cfif>
		</cfif>
		<cfif len(form.password) GT 0 AND len(variables.databaseAccount) GT 0>
			<cfset variables.passwordProblem = databasePasswordProblem(form.password)>
			<cfif len(variables.passwordProblem) EQ 0>
				<cfset variables.passwordProblem = databasePasswordCheck(variables.databaseAccount, form.password)>
			</cfif>
			<cfif len(variables.passwordProblem) GT 0>
				<div class="alert alert-danger">#encodeForHtml(variables.passwordProblem)#
					<a href="/Admin/AdminUsers.cfm?action=edit&username=#encodeForUrl(form.orig_username)#">Go back</a></div>
				<cfabort>
			</cfif>
			<cftry>
				<!--- DDL commits implicitly, so it runs before the cf_users update: if it fails, nothing has changed. --->
				<cfquery name="setDatabasePassword" datasource="uam_god">
					ALTER USER "#variables.databaseAccount#" IDENTIFIED BY "#form.password#"
				</cfquery>
			<cfcatch>
				<cfif isPasswordComplexityError(cfcatch)>
					<div class="alert alert-danger">The password does not meet the database's password requirements.
						<a href="/Admin/AdminUsers.cfm?action=edit&username=#encodeForUrl(form.orig_username)#">Go back</a></div>
					<cfabort>
				</cfif>
				<cflog file="MCZbase" type="error" text="Setting the database password for #form.orig_username# failed: #cfcatch.message#">
				<div class="alert alert-danger">There was a problem updating this user's database password; nothing was changed.</div>
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
</main>
<script src="/lib/misc/sorttable.js"></script>
<cfinclude template = "/shared/_footer.cfm">
