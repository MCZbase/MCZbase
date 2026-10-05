<!---
tools/access_report.cfm

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
<!--- Read-only report of which database accounts hold which roles, and which grants need attention. --->
<cfset pageTitle = "Database Access Report">
<cfinclude template="/shared/_header.cfm">
<!--- Who holds which role, with account status and contact details, is for administrators only. --->
<cfif NOT ( isdefined("session.roles") AND listfindnocase(session.roles,"global_admin") ) >
	<cflocation url="/errors/forbidden.cfm" addtoken="false">
</cfif>

<!--- action=role is accepted for existing links; the report has a single view. --->
<cfparam name="url.action" default="">

<!--- Roles that grant administrative control over MCZbase or the database. --->
<cfset variables.ADMINISTRATIVE_ROLES = "GLOBAL_ADMIN,DBA,MANAGE_COLLECTION">
<!--- An account unused for this many days, that still holds roles, is listed for review. --->
<cfset variables.STALE_DAYS = 365>
<!--- Login history is meaningful only on production; elsewhere few people log in, so unused holders are not flagged in the roles table. --->
<cfset variables.IS_PRODUCTION = isDefined("session.gitBranch") AND findNoCase("refs/heads/master", session.gitBranch) GT 0>
<!--- Roles that work with collection data, which a holder can see only through a collection role. --->
<cfset variables.DATA_ROLES = "MANAGE_SPECIMENS,DATA_ENTRY,MANAGE_TRANSACTIONS,MANAGE_CONTAINER,MANAGE_MEDIA">
<!--- A role held by at least this share of a role's open holders is expected of the others; only for roles with enough holders. --->
<cfset variables.COMPANION_SHARE = 0.8>
<cfset variables.COMPANION_MIN_HOLDERS = 5>

<cfquery name="getApplicationRoles" datasource="uam_god" result="getApplicationRoles_result">
	SELECT upper(role_name) AS role_name, description
	FROM cf_ctuser_roles
	ORDER BY role_name
</cfquery>
<cfquery name="getCollectionRoles" datasource="uam_god" result="getCollectionRoles_result">
	SELECT DISTINCT upper(portal_name) AS role_name
	FROM cf_collection
	WHERE portal_name IS NOT NULL
</cfquery>
<cfset variables.collectionRoles = valueList(getCollectionRoles.role_name)>
<cfquery name="getGrants" datasource="uam_god" result="getGrants_result">
	SELECT
		rp.grantee,
		rp.granted_role,
		rp.default_role,
		rp.admin_option,
		u.account_status,
		u.lock_date,
		u.expiry_date,
		cu.username AS mczbase_username,
		cu.last_login,
		cud.first_name,
		cud.last_name,
		cud.email
	FROM dba_role_privs rp
		JOIN dba_users u ON u.username = rp.grantee
		LEFT JOIN cf_users cu ON upper(cu.username) = rp.grantee
		LEFT JOIN cf_user_data cud ON cud.user_id = cu.user_id
	WHERE
		rp.grantee NOT LIKE 'PUB\_USR%' ESCAPE '\'
		AND rp.grantee NOT IN ('SYS', 'UAM')
	ORDER BY rp.grantee, rp.granted_role
</cfquery>
<cfquery name="getRoleToRole" datasource="uam_god" result="getRoleToRole_result">
	SELECT rp.grantee, rp.granted_role
	FROM dba_role_privs rp
		JOIN dba_roles r ON r.role = rp.grantee
	WHERE
		rp.granted_role IN (SELECT upper(role_name) FROM cf_ctuser_roles)
		OR rp.grantee IN (SELECT upper(role_name) FROM cf_ctuser_roles)
	ORDER BY rp.grantee, rp.granted_role
</cfquery>

<cfset variables.applicationRoles = valueList(getApplicationRoles.role_name)>
<!--- One entry per account, in account name order, with its roles and details. --->
<cfset variables.accountOrder = "">
<cfset variables.accounts = structNew()>
<cfloop query="getGrants">
	<cfif NOT structKeyExists(variables.accounts, getGrants.grantee)>
		<cfset variables.accountOrder = listAppend(variables.accountOrder, getGrants.grantee)>
		<cfset variables.name = trim(getGrants.first_name & " " & getGrants.last_name)>
		<cfset variables.daysSinceLogin = "">
		<cfif isDate(getGrants.last_login)>
			<cfset variables.daysSinceLogin = dateDiff("d", getGrants.last_login, now())>
		</cfif>
		<cfset variables.accounts[getGrants.grantee] = {
			mczbaseUsername = getGrants.mczbase_username,
			name = variables.name,
			email = getGrants.email,
			status = getGrants.account_status,
			lockDate = getGrants.lock_date,
			expiryDate = getGrants.expiry_date,
			lastLogin = getGrants.last_login,
			daysSinceLogin = variables.daysSinceLogin,
			roles = structNew(),
			otherRoles = ""
		}>
	</cfif>
	<cfset variables.accounts[getGrants.grantee].roles[getGrants.granted_role] = { isDefault = (getGrants.default_role EQ "YES"), withAdmin = (getGrants.admin_option EQ "YES") }>
	<cfif listFind(variables.applicationRoles, getGrants.granted_role) EQ 0>
		<cfset variables.accounts[getGrants.grantee].otherRoles = listAppend(variables.accounts[getGrants.grantee].otherRoles, getGrants.granted_role)>
	</cfif>
</cfloop>

<!--- Grants that need attention, one row per account and reason. --->
<cfset variables.attention = arrayNew(1)>
<cfset variables.activeCount = 0>
<cfloop list="#variables.accountOrder#" index="variables.grantee">
	<cfset variables.account = variables.accounts[variables.grantee]>
	<cfset variables.isActive = (variables.account.status EQ "OPEN")>
	<cfif variables.isActive>
		<cfset variables.activeCount = variables.activeCount + 1>
	<cfelse>
		<cfset arrayAppend(variables.attention, { grantee = variables.grantee, issue = "Account is #lcase(variables.account.status)# but still holds roles", action = "Revoke the roles, or drop the account if it is no longer needed." })>
	</cfif>
	<cfif len(variables.account.mczbaseUsername) EQ 0>
		<cfset arrayAppend(variables.attention, { grantee = variables.grantee, issue = "Database account with roles but no MCZbase user", action = "Check whether the account is still needed; MCZbase cannot be used to manage it." })>
	<cfelseif variables.isActive AND (len(variables.account.daysSinceLogin) EQ 0 OR variables.account.daysSinceLogin GT variables.STALE_DAYS)>
		<cfset variables.lastSeen = "never logged in to MCZbase">
		<cfif len(variables.account.daysSinceLogin) GT 0>
			<cfset variables.lastSeen = "last logged in #variables.account.daysSinceLogin# days ago">
		</cfif>
		<cfset arrayAppend(variables.attention, { grantee = variables.grantee, issue = "Open account, #variables.lastSeen#", action = "Confirm the access is still needed; lock the account or revoke roles if not." })>
	</cfif>
	<cfloop list="#variables.ADMINISTRATIVE_ROLES#" index="variables.adminRole">
		<cfif structKeyExists(variables.account.roles, variables.adminRole) AND variables.isActive>
			<cfset arrayAppend(variables.attention, { grantee = variables.grantee, issue = "Holds #variables.adminRole#", action = "Administrative role: confirm this person should have it." })>
		</cfif>
	</cfloop>
	<cfloop collection="#variables.account.roles#" item="variables.role">
		<cfif listFind(variables.applicationRoles, variables.role) GT 0 AND NOT variables.account.roles[variables.role].isDefault>
			<cfset arrayAppend(variables.attention, { grantee = variables.grantee, issue = "#variables.role# is granted but not a default role", action = "MCZbase lists the role, but the database account does not use it until it is enabled, so pages may allow actions the database then refuses. Make it a default role, or revoke it." })>
		</cfif>
		<cfif variables.account.roles[variables.role].withAdmin>
			<cfset arrayAppend(variables.attention, { grantee = variables.grantee, issue = "#variables.role# granted with admin option", action = "The account can grant this role to others; confirm that is intended." })>
		</cfif>
	</cfloop>
</cfloop>

<!---
	isCollectionRole test whether a role gives access to a collection's data.

	@param role the role name, in upper case.
	@return true for roles named by cf_collection.portal_name, or starting MCZ_.
--->
<cffunction name="isCollectionRole" returntype="boolean" output="false">
	<cfargument name="role" type="string" required="yes">
	<cfreturn listFind(variables.collectionRoles, arguments.role) GT 0 OR left(arguments.role, 4) EQ "MCZ_">
</cffunction>

<!---
	roleBadgeClass choose the badge colour for a role, so kinds of role can be told apart at a glance.

	@param role the role name, in upper case.
	@return Bootstrap badge classes.
--->
<cffunction name="roleBadgeClass" returntype="string" output="false">
	<cfargument name="role" type="string" required="yes">
	<cfif listFind("DBA,GLOBAL_ADMIN", arguments.role) GT 0>
		<cfreturn "badge-danger">
	<cfelseif left(arguments.role, 6) EQ "ADMIN_">
		<cfreturn "badge-warning">
	<cfelseif arguments.role EQ "MANAGE_COLLECTION">
		<cfreturn "badge-info">
	<cfelseif isCollectionRole(arguments.role)>
		<cfreturn "badge-success">
	<cfelseif arguments.role EQ "CONNECT">
		<cfreturn "badge-dark">
	</cfif>
	<cfreturn "badge-light border">
</cffunction>

<!--- For each application role: its open and inactive holders, and the reasons an open holder looks out of place. --->
<cfset variables.roleSummaries = structNew()>
<cfloop query="getApplicationRoles">
	<cfset variables.role = getApplicationRoles.role_name>
	<cfset variables.openHolders = "">
	<cfset variables.inactiveHolders = "">
	<cfloop list="#variables.accountOrder#" index="variables.grantee">
		<cfif structKeyExists(variables.accounts[variables.grantee].roles, variables.role)>
			<cfif variables.accounts[variables.grantee].status EQ "OPEN">
				<cfset variables.openHolders = listAppend(variables.openHolders, variables.grantee)>
			<cfelse>
				<cfset variables.inactiveHolders = listAppend(variables.inactiveHolders, variables.grantee)>
			</cfif>
		</cfif>
	</cfloop>
	<cfset variables.holderCount = listLen(variables.openHolders)>
	<cfset variables.companions = structNew()>
	<cfif variables.holderCount GTE variables.COMPANION_MIN_HOLDERS>
		<cfloop list="#variables.applicationRoles#" index="variables.otherRole">
			<cfif variables.otherRole NEQ variables.role AND variables.otherRole NEQ "COLDFUSION_USER">
				<cfset variables.withOther = 0>
				<cfloop list="#variables.openHolders#" index="variables.grantee">
					<cfif structKeyExists(variables.accounts[variables.grantee].roles, variables.otherRole)>
						<cfset variables.withOther = variables.withOther + 1>
					</cfif>
				</cfloop>
				<cfif variables.withOther / variables.holderCount GTE variables.COMPANION_SHARE AND variables.withOther LT variables.holderCount>
					<cfset variables.companions[variables.otherRole] = variables.withOther>
				</cfif>
			</cfif>
		</cfloop>
	</cfif>
	<cfset variables.reasons = structNew()>
	<cfloop list="#variables.openHolders#" index="variables.grantee">
		<cfset variables.account = variables.accounts[variables.grantee]>
		<cfset variables.holderReasons = "">
		<cfif variables.IS_PRODUCTION AND len(variables.account.daysSinceLogin) EQ 0>
			<cfset variables.holderReasons = listAppend(variables.holderReasons, "Never logged in to MCZbase", "|")>
		<cfelseif variables.IS_PRODUCTION AND variables.account.daysSinceLogin GT variables.STALE_DAYS>
			<cfset variables.holderReasons = listAppend(variables.holderReasons, "No MCZbase login in #variables.account.daysSinceLogin# days", "|")>
		</cfif>
		<cfif NOT variables.account.roles[variables.role].isDefault>
			<cfset variables.holderReasons = listAppend(variables.holderReasons, "Granted but not a default role, so the database does not use it", "|")>
		</cfif>
		<cfif variables.account.roles[variables.role].withAdmin>
			<cfset variables.holderReasons = listAppend(variables.holderReasons, "Granted with admin option, so the account can grant it to others", "|")>
		</cfif>
		<cfif len(variables.account.mczbaseUsername) EQ 0>
			<cfset variables.holderReasons = listAppend(variables.holderReasons, "No MCZbase user for this database account", "|")>
		</cfif>
		<cfif variables.role NEQ "COLDFUSION_USER" AND NOT structKeyExists(variables.account.roles, "COLDFUSION_USER")>
			<cfset variables.holderReasons = listAppend(variables.holderReasons, "Lacks coldfusion_user, so MCZbase treats the account as a public user", "|")>
		</cfif>
		<cfif listFind(variables.DATA_ROLES, variables.role) GT 0>
			<cfset variables.hasCollection = false>
			<cfloop collection="#variables.account.roles#" item="variables.heldRole">
				<cfif isCollectionRole(variables.heldRole)>
					<cfset variables.hasCollection = true>
				</cfif>
			</cfloop>
			<cfif NOT variables.hasCollection>
				<cfset variables.holderReasons = listAppend(variables.holderReasons, "Holds no collection role, so collection data is hidden from it", "|")>
			</cfif>
		</cfif>
		<cfloop collection="#variables.companions#" item="variables.otherRole">
			<cfif NOT structKeyExists(variables.account.roles, variables.otherRole)>
				<cfset variables.holderReasons = listAppend(variables.holderReasons, "Lacks #lcase(variables.otherRole)#, held by #variables.companions[variables.otherRole]# of #variables.holderCount# open holders of this role", "|")>
			</cfif>
		</cfloop>
		<cfif len(variables.holderReasons) GT 0>
			<cfset variables.reasons[variables.grantee] = variables.holderReasons>
		</cfif>
	</cfloop>
	<cfset variables.totalHolders = listLen(variables.openHolders) + listLen(variables.inactiveHolders)>
	<cfset variables.roleSummaries[variables.role] = {
		openHolders = variables.openHolders,
		inactiveHolders = variables.inactiveHolders,
		reasons = variables.reasons,
		isRare = (variables.totalHolders GT 0 AND variables.totalHolders LTE 2)
	}>
</cfloop>

<script src="/lib/misc/sorttable.js"></script>
<cfoutput>
<main class="container-fluid py-3" id="content">
	<section class="row mx-0 my-2">
		<div class="col-12">
			<h1 class="h2">Database Access Report</h1>
			<p>
				Which database accounts hold which roles, and which grants need attention. This page only reads; grant and revoke roles from
				<a href="/Admin/AdminUsers.cfm">Manage MCZbase Users</a>, and see <a href="/Admin/user_roles.cfm">Database Roles</a> for what each role allows in the database.
			</p>
			<ul>
				<li>Each MCZbase staff user logs in to Oracle with their own database account. At login, MCZbase reads the account's roles that are listed in <code>cf_ctuser_roles</code>; those decide which pages the user can open (<a href="/Admin/form_roles.cfm">Form Permissions</a>).</li>
				<li>What the user can then change is decided by the database, through the same roles. A role only takes effect in the database when it is a default role, or is enabled.</li>
				<li>Portal accounts (<code>PUB_USR…</code>), <code>SYS</code> and <code>UAM</code> are not listed.</li>
			</ul>
			<p class="small text-secondary">
				#structCount(variables.accounts)# accounts hold roles, #variables.activeCount# of them open; #listLen(variables.applicationRoles)# application roles.
				Accounts not used for over #variables.STALE_DAYS# days are flagged; administrative roles are #encodeForHtml(replace(variables.ADMINISTRATIVE_ROLES, ",", ", ", "all"))#.
			</p>
			<ul>
				<li><a href="##attention">Needs attention</a>: #arrayLen(variables.attention)#</li>
				<li><a href="##byRole">Roles</a></li>
				<li><a href="##roleToRole">Roles granted to roles</a>: #getRoleToRole.recordcount#</li>
				<li><a href="##matrix">Users and roles</a></li>
			</ul>
		</div>
	</section>

	<section class="accordion mx-0 my-2" id="attention">
		<div class="card mb-2 bg-light">
			<div class="card-header" id="attentionHeader">
				<h2 class="h3 my-0">
					<button type="button" class="headerLnk text-left w-100 h-100" data-toggle="collapse" data-target="##attentionBody" aria-expanded="true" aria-controls="attentionBody">
						Needs attention (#arrayLen(variables.attention)#)
					</button>
				</h2>
			</div>
			<div id="attentionBody" class="collapse show" aria-labelledby="attentionHeader" data-parent="##attention">
				<div class="card-body bg-white">
					<cfif arrayLen(variables.attention) EQ 0>
						<p class="font-italic">Nothing to review.</p>
					<cfelse>
						<table class="table table-responsive d-xl-table table-sm table-striped sortable">
							<thead class="thead-light">
								<tr><th scope="col">Account</th><th scope="col">Name</th><th scope="col">Issue</th><th scope="col">Suggested action</th></tr>
							</thead>
							<tbody>
								<cfloop array="#variables.attention#" index="variables.item">
									<cfset variables.account = variables.accounts[variables.item.grantee]>
									<tr>
										<td>
											<cfif len(variables.account.mczbaseUsername) GT 0>
												<a href="/Admin/AdminUsers.cfm?action=edit&username=#encodeForUrl(variables.account.mczbaseUsername)#">#encodeForHtml(variables.item.grantee)#</a>
											<cfelse>
												#encodeForHtml(variables.item.grantee)#
											</cfif>
										</td>
										<td>#encodeForHtml(variables.account.name)#</td>
										<td>#encodeForHtml(variables.item.issue)#</td>
										<td class="small">#encodeForHtml(variables.item.action)#</td>
									</tr>
								</cfloop>
							</tbody>
						</table>
					</cfif>
				</div>
			</div>
		</div>
	</section>

	<section class="accordion mx-0 my-2" id="byRole">
		<div class="card mb-2 bg-light">
			<div class="card-header" id="byRoleHeader">
				<h2 class="h3 my-0">
					<button type="button" class="headerLnk text-left w-100 h-100" data-toggle="collapse" data-target="##byRoleBody" aria-expanded="true" aria-controls="byRoleBody">
						Roles (#listLen(variables.applicationRoles)#)
					</button>
				</h2>
			</div>
			<div id="byRoleBody" class="collapse show" aria-labelledby="byRoleHeader" data-parent="##byRole">
				<div class="card-body bg-white">
					<p class="small">
						Holders of each application role. A holder marked <span class="badge badge-light border border-danger text-danger font-weight-normal"><span aria-hidden="true">&##9888;</span> account</span>
						looks out of place; hover over it for the reasons, which are:
					</p>
					<ul class="small">
						<cfif variables.IS_PRODUCTION>
							<li>no MCZbase login in over #variables.STALE_DAYS# days, or never;</li>
						</cfif>
						<li>the role is granted but not as a default role, or with admin option;</li>
						<li>a database account with no MCZbase user;</li>
						<li>no <code>coldfusion_user</code>, so MCZbase treats the account as a public user;</li>
						<li>for #encodeForHtml(lcase(replace(variables.DATA_ROLES, ",", ", ", "all")))#: no collection role, so collection data is hidden;</li>
						<li>lacking a role that at least #int(variables.COMPANION_SHARE * 100)#% of the role's open holders have (for roles with #variables.COMPANION_MIN_HOLDERS# or more open holders).</li>
					</ul>
					<p class="small">
						<span class="badge badge-light text-muted font-weight-normal"><s>account</s></span> is a locked or expired account still holding the role.
						<cfif NOT variables.IS_PRODUCTION>Login history is not checked here, as this is not production.</cfif>
					</p>
					<table class="table table-responsive d-xl-table table-sm table-striped sortable">
						<thead class="thead-light">
							<tr><th scope="col">Role</th><th scope="col">Description</th><th scope="col">Open</th><th scope="col">Locked or expired</th><th scope="col">Oddities</th><th scope="col">Held by</th></tr>
						</thead>
						<tbody>
							<cfloop query="getApplicationRoles">
								<cfset variables.summary = variables.roleSummaries[getApplicationRoles.role_name]>
								<tr>
									<th scope="row" class="font-weight-normal">
										<span class="badge #roleBadgeClass(getApplicationRoles.role_name)# font-weight-normal">#encodeForHtml(lcase(getApplicationRoles.role_name))#</span>
										<cfif variables.summary.isRare>
											<br><span class="small text-secondary">rarely held</span>
										</cfif>
									</th>
									<td class="small">#encodeForHtml(getApplicationRoles.description)#</td>
									<td>#listLen(variables.summary.openHolders)#</td>
									<td>#listLen(variables.summary.inactiveHolders)#</td>
									<td>#structCount(variables.summary.reasons)#</td>
									<td>
										<!--- Flagged holders first, then the other open holders, then locked or expired ones. --->
										<cfloop list="flagged,open,inactive" index="variables.group">
											<cfset variables.groupHolders = variables.summary.openHolders>
											<cfif variables.group EQ "inactive">
												<cfset variables.groupHolders = variables.summary.inactiveHolders>
											</cfif>
											<cfloop list="#variables.groupHolders#" index="variables.grantee">
												<cfset variables.isFlagged = structKeyExists(variables.summary.reasons, variables.grantee)>
												<cfif (variables.group EQ "flagged" AND variables.isFlagged) OR (variables.group EQ "open" AND NOT variables.isFlagged) OR variables.group EQ "inactive">
													<cfset variables.account = variables.accounts[variables.grantee]>
													<cfset variables.holderClass = "badge-light border">
													<cfset variables.holderTitle = variables.account.name>
													<cfset variables.holderLabel = encodeForHtml(variables.grantee)>
													<cfif variables.group EQ "flagged">
														<cfset variables.holderClass = "badge-light border border-danger text-danger">
														<cfset variables.holderTitle = variables.account.name & ": " & replace(variables.summary.reasons[variables.grantee], "|", "; ", "all")>
														<cfset variables.holderLabel = '<span aria-hidden="true">&##9888;</span> ' & variables.holderLabel>
													<cfelseif variables.group EQ "inactive">
														<cfset variables.holderClass = "badge-light text-muted">
														<cfset variables.holderTitle = variables.account.name & ": account " & lcase(variables.account.status)>
														<cfset variables.holderLabel = "<s>" & variables.holderLabel & "</s>">
													</cfif>
													<cfif len(variables.account.mczbaseUsername) GT 0>
														<a class="badge #variables.holderClass# font-weight-normal mr-1" href="/Admin/AdminUsers.cfm?action=edit&username=#encodeForUrl(variables.account.mczbaseUsername)#" title="#encodeForHtmlAttribute(variables.holderTitle)#">#variables.holderLabel#<span class="sr-only">: #encodeForHtml(variables.holderTitle)#</span></a>
													<cfelse>
														<span class="badge #variables.holderClass# font-weight-normal mr-1" title="#encodeForHtmlAttribute(variables.holderTitle)#">#variables.holderLabel#<span class="sr-only">: #encodeForHtml(variables.holderTitle)#</span></span>
													</cfif>
												</cfif>
											</cfloop>
										</cfloop>
									</td>
								</tr>
							</cfloop>
						</tbody>
					</table>
				</div>
			</div>
		</div>
	</section>

	<section class="accordion mx-0 my-2" id="roleToRole">
		<div class="card mb-2 bg-light">
			<div class="card-header" id="roleToRoleHeader">
				<h2 class="h3 my-0">
					<button type="button" class="headerLnk text-left w-100 h-100" data-toggle="collapse" data-target="##roleToRoleBody" aria-expanded="true" aria-controls="roleToRoleBody">
						Roles granted to roles (#getRoleToRole.recordcount#)
					</button>
				</h2>
			</div>
			<div id="roleToRoleBody" class="collapse show" aria-labelledby="roleToRoleHeader" data-parent="##roleToRole">
				<div class="card-body bg-white">
					<p class="small">An account holding the grantee role also gets the granted role, without it appearing in the matrix above.</p>
					<cfif getRoleToRole.recordcount EQ 0>
						<p class="font-italic">None.</p>
					<cfelse>
						<table class="table table-responsive d-xl-table table-sm table-striped sortable">
							<thead class="thead-light">
								<tr><th scope="col">Role</th><th scope="col">Also grants</th></tr>
							</thead>
							<tbody>
								<cfloop query="getRoleToRole">
									<tr>
										<td>#encodeForHtml(getRoleToRole.grantee)#</td>
										<td>#encodeForHtml(getRoleToRole.granted_role)#</td>
									</tr>
								</cfloop>
							</tbody>
						</table>
					</cfif>
				</div>
			</div>
		</div>
	</section>

	<section class="accordion mx-0 my-2" id="matrix">
		<div class="card mb-4 bg-light">
			<div class="card-header" id="matrixHeader">
				<h2 class="h3 my-0">
					<button type="button" class="headerLnk text-left w-100 h-100" data-toggle="collapse" data-target="##matrixBody" aria-expanded="true" aria-controls="matrixBody">
						Users and roles (#structCount(variables.accounts)# accounts)
					</button>
				</h2>
			</div>
			<div id="matrixBody" class="collapse show" aria-labelledby="matrixHeader" data-parent="##matrix">
				<div class="card-body bg-white">
					<p class="small">
						One row per account, with its roles:
						<span class="badge badge-danger font-weight-normal">dba, global_admin</span>
						<span class="badge badge-warning font-weight-normal">admin_ roles</span>
						<span class="badge badge-info font-weight-normal">manage_collection</span>
						<span class="badge badge-success font-weight-normal">collection roles</span>
						<span class="badge badge-dark font-weight-normal">connect</span>
						<span class="badge badge-light border font-weight-normal">other roles</span>.
						A role marked <span class="badge badge-light border font-weight-normal">role*</span> is granted but not as a default role, so the database does not use it.
						Roles outside <code>cf_ctuser_roles</code> are listed after the application roles.
					</p>
					<div class="form-row align-items-end mb-2">
						<div class="col-12 col-md-4 col-xl-3">
							<label for="accountFilter" class="data-entry-label">Account, name or email contains</label>
							<input type="text" id="accountFilter" class="data-entry-input" oninput="filterAccessMatrix('accessMatrix', 'accountFilter', 'roleFilter', 'activeOnly', 'accessMatrixCount');">
						</div>
						<div class="col-12 col-md-4 col-xl-3">
							<label for="roleFilter" class="data-entry-label">Show accounts holding</label>
							<select id="roleFilter" class="data-entry-select" onchange="filterAccessMatrix('accessMatrix', 'accountFilter', 'roleFilter', 'activeOnly', 'accessMatrixCount');">
								<option value="">any role</option>
								<cfloop query="getApplicationRoles">
									<option value="#encodeForHtmlAttribute(getApplicationRoles.role_name)#">#encodeForHtml(getApplicationRoles.role_name)#</option>
								</cfloop>
							</select>
						</div>
						<div class="col-12 col-md-auto">
							<input type="checkbox" id="activeOnly" checked onchange="filterAccessMatrix('accessMatrix', 'accountFilter', 'roleFilter', 'activeOnly', 'accessMatrixCount');">
							<label for="activeOnly" class="data-entry-label d-inline">Open accounts only</label>
						</div>
						<div class="col-12 col-md-auto">
							<output id="accessMatrixCount" class="small" aria-live="polite"></output>
						</div>
					</div>
					<table class="table table-responsive d-xl-table table-sm table-striped sortable" id="accessMatrix">
						<thead class="thead-light">
							<tr>
								<th scope="col">Account</th>
								<th scope="col">Name</th>
								<th scope="col">Status</th>
								<th scope="col">Last MCZbase login</th>
								<th scope="col">Roles</th>
							</tr>
						</thead>
						<tbody>
							<cfloop list="#variables.accountOrder#" index="variables.grantee">
								<cfset variables.account = variables.accounts[variables.grantee]>
								<cfset variables.rowHidden = "">
								<cfif variables.account.status NEQ "OPEN">
									<cfset variables.rowHidden = "d-none">
								</cfif>
								<cfset variables.lastLoginText = "never">
								<cfif isDate(variables.account.lastLogin)>
									<cfset variables.lastLoginText = dateFormat(variables.account.lastLogin, "yyyy-mm-dd")>
								</cfif>
								<cfset variables.searchText = lcase(variables.grantee & " " & variables.account.name & " " & variables.account.email)>
								<tr class="#variables.rowHidden#" data-roles=" #encodeForHtmlAttribute(structKeyList(variables.account.roles, ' '))# " data-open="#(variables.account.status EQ 'OPEN') ? 'yes' : 'no'#" data-search="#encodeForHtmlAttribute(variables.searchText)#">
									<th scope="row" class="font-weight-normal">
										<cfif len(variables.account.mczbaseUsername) GT 0>
											<a href="/Admin/AdminUsers.cfm?action=edit&username=#encodeForUrl(variables.account.mczbaseUsername)#">#encodeForHtml(variables.grantee)#</a>
										<cfelse>
											#encodeForHtml(variables.grantee)#
										</cfif>
									</th>
									<td>#encodeForHtml(variables.account.name)#</td>
									<td class="small">#encodeForHtml(lcase(variables.account.status))#</td>
									<td class="small" sorttable_customkey="#encodeForHtmlAttribute(variables.lastLoginText)#">#encodeForHtml(variables.lastLoginText)#</td>
									<td>
										<!--- Application roles in cf_ctuser_roles order, then any others. --->
										<cfset variables.roleOrder = "">
										<cfloop query="getApplicationRoles">
											<cfif structKeyExists(variables.account.roles, getApplicationRoles.role_name)>
												<cfset variables.roleOrder = listAppend(variables.roleOrder, getApplicationRoles.role_name)>
											</cfif>
										</cfloop>
										<cfset variables.roleOrder = listAppend(variables.roleOrder, variables.account.otherRoles)>
										<cfloop list="#variables.roleOrder#" index="variables.role">
											<cfset variables.badgeClass = roleBadgeClass(variables.role)>
											<cfset variables.roleLabel = lcase(variables.role)>
											<cfset variables.roleNote = "">
											<cfif NOT variables.account.roles[variables.role].isDefault>
												<cfset variables.roleLabel = variables.roleLabel & "*">
												<cfset variables.roleNote = " (granted, not a default role)">
											</cfif>
											<span class="badge #variables.badgeClass# font-weight-normal mr-1" title="#encodeForHtmlAttribute(variables.role & variables.roleNote)#">#encodeForHtml(variables.roleLabel)#<span class="sr-only">#encodeForHtml(variables.roleNote)#</span></span>
										</cfloop>
									</td>
								</tr>
							</cfloop>
						</tbody>
					</table>
				</div>
			</div>
		</div>
	</section>
</main>

<script>
	/** filterAccessMatrix show only the rows of the users and roles table that match the filters, and
	 * report how many are shown.
	 * @param tableId the id of the table, without the leading ##.
	 * @param textInputId the id of the text input matched against account, name and email, without the leading ##.
	 * @param roleSelectId the id of the role select, without the leading ##; an empty value matches any role.
	 * @param activeOnlyId the id of the open accounts only checkbox, without the leading ##.
	 * @param countId the id of the element reporting the number of rows shown, without the leading ##.
	 */
	function filterAccessMatrix(tableId, textInputId, roleSelectId, activeOnlyId, countId) {
		var text = $.trim($('##' + textInputId).val()).toLowerCase();
		var role = $('##' + roleSelectId).val();
		var activeOnly = $('##' + activeOnlyId).prop('checked');
		var shown = 0;
		$('##' + tableId + ' tbody tr').each(function () {
			var row = $(this);
			var show = (text == "" || row.attr('data-search').indexOf(text) >= 0)
				&& (role == "" || row.attr('data-roles').indexOf(' ' + role + ' ') >= 0)
				&& (!activeOnly || row.attr('data-open') == 'yes');
			row.toggleClass('d-none', !show);
			if (show) { shown++; }
		});
		$('##' + countId).text(shown + " shown");
	}
	$(document).ready(function () {
		filterAccessMatrix('accessMatrix', 'accountFilter', 'roleFilter', 'activeOnly', 'accessMatrixCount');
	});
</script>
</cfoutput>
<cfinclude template="/shared/_footer.cfm">
