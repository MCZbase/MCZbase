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

<cfquery name="getApplicationRoles" datasource="uam_god" result="getApplicationRoles_result">
	SELECT upper(role_name) AS role_name, description
	FROM cf_ctuser_roles
	ORDER BY role_name
</cfquery>
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
				<li><a href="##matrix">Users and roles</a></li>
				<li><a href="##byRole">Roles</a></li>
				<li><a href="##roleToRole">Roles granted to roles</a>: #getRoleToRole.recordcount#</li>
			</ul>
		</div>
	</section>

	<section class="row mx-0 my-2 border rounded" id="attention">
		<div class="col-12 py-2">
			<h2 class="h3">Needs attention</h2>
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
	</section>

	<section class="row mx-0 my-2 border rounded" id="matrix">
		<div class="col-12 py-2">
			<h2 class="h3">Users and roles</h2>
			<p class="small">
				<span aria-hidden="true">&##10003;</span> the account holds the role;
				<span aria-hidden="true">&##10003;*</span> it holds it, but not as a default role.
				Roles outside <code>cf_ctuser_roles</code> are listed under Other roles.
			</p>
			<div class="form-row align-items-end mb-2">
				<div class="col-12 col-md-4 col-xl-3">
					<label for="roleFilter" class="data-entry-label">Show accounts holding</label>
					<select id="roleFilter" class="data-entry-select" onchange="filterAccessMatrix('accessMatrix', 'roleFilter', 'activeOnly');">
						<option value="">any role</option>
						<cfloop query="getApplicationRoles">
							<option value="#encodeForHtmlAttribute(getApplicationRoles.role_name)#">#encodeForHtml(getApplicationRoles.role_name)#</option>
						</cfloop>
					</select>
				</div>
				<div class="col-12 col-md-auto">
					<input type="checkbox" id="activeOnly" checked onchange="filterAccessMatrix('accessMatrix', 'roleFilter', 'activeOnly');">
					<label for="activeOnly" class="data-entry-label d-inline">Open accounts only</label>
				</div>
			</div>
			<!--- No d-xl-table: with a column per role the matrix needs its horizontal scroll at every width. --->
			<table class="table table-responsive table-sm table-striped sortable" id="accessMatrix">
				<thead class="thead-light">
					<tr>
						<th scope="col">Account</th>
						<th scope="col">Name</th>
						<th scope="col">Status</th>
						<th scope="col">Last MCZbase login</th>
						<cfloop query="getApplicationRoles">
							<th scope="col" class="small" title="#encodeForHtmlAttribute(getApplicationRoles.description)#">#encodeForHtml(lcase(replace(getApplicationRoles.role_name, "_", "_ ", "all")))#</th>
						</cfloop>
						<th scope="col">Other roles</th>
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
						<tr class="#variables.rowHidden#" data-roles=" #encodeForHtmlAttribute(structKeyList(variables.account.roles, ' '))# " data-open="#(variables.account.status EQ 'OPEN') ? 'yes' : 'no'#">
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
							<cfloop query="getApplicationRoles">
								<td class="text-center">
									<cfif structKeyExists(variables.account.roles, getApplicationRoles.role_name)>
										<cfif variables.account.roles[getApplicationRoles.role_name].isDefault>
											<span aria-hidden="true">&##10003;</span><span class="sr-only">has #encodeForHtml(getApplicationRoles.role_name)#</span>
										<cfelse>
											<span aria-hidden="true">&##10003;*</span><span class="sr-only">has #encodeForHtml(getApplicationRoles.role_name)#, not as a default role</span>
										</cfif>
									</cfif>
								</td>
							</cfloop>
							<td class="small">#encodeForHtml(replace(variables.account.otherRoles, ",", ", ", "all"))#</td>
						</tr>
					</cfloop>
				</tbody>
			</table>
		</div>
	</section>

	<section class="row mx-0 my-2 border rounded" id="byRole">
		<div class="col-12 py-2">
			<h2 class="h3">Roles</h2>
			<p class="small">Open accounts holding each application role. Locked and expired accounts are counted separately.</p>
			<table class="table table-responsive d-xl-table table-sm table-striped sortable">
				<thead class="thead-light">
					<tr><th scope="col">Role</th><th scope="col">Description</th><th scope="col">Open</th><th scope="col">Locked or expired</th><th scope="col">Held by (open accounts)</th></tr>
				</thead>
				<tbody>
					<cfloop query="getApplicationRoles">
						<cfset variables.holders = "">
						<cfset variables.inactiveCount = 0>
						<cfloop list="#variables.accountOrder#" index="variables.grantee">
							<cfif structKeyExists(variables.accounts[variables.grantee].roles, getApplicationRoles.role_name)>
								<cfif variables.accounts[variables.grantee].status EQ "OPEN">
									<cfset variables.holders = listAppend(variables.holders, variables.grantee)>
								<cfelse>
									<cfset variables.inactiveCount = variables.inactiveCount + 1>
								</cfif>
							</cfif>
						</cfloop>
						<tr>
							<th scope="row" class="font-weight-normal">#encodeForHtml(lcase(getApplicationRoles.role_name))#</th>
							<td class="small">#encodeForHtml(getApplicationRoles.description)#</td>
							<td>#listLen(variables.holders)#</td>
							<td>#variables.inactiveCount#</td>
							<td class="small">#encodeForHtml(replace(variables.holders, ",", ", ", "all"))#</td>
						</tr>
					</cfloop>
				</tbody>
			</table>
		</div>
	</section>

	<section class="row mx-0 my-2 mb-4 border rounded" id="roleToRole">
		<div class="col-12 py-2">
			<h2 class="h3">Roles granted to roles</h2>
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
	</section>
</main>

<script>
	/** filterAccessMatrix show only the rows of the access matrix for accounts holding a role, and
	 * optionally only open accounts.
	 * @param tableId the id of the matrix table, without the leading ##.
	 * @param roleSelectId the id of the role select, without the leading ##; an empty value matches any role.
	 * @param activeOnlyId the id of the open accounts only checkbox, without the leading ##.
	 */
	function filterAccessMatrix(tableId, roleSelectId, activeOnlyId) {
		var role = $('##' + roleSelectId).val();
		var activeOnly = $('##' + activeOnlyId).prop('checked');
		$('##' + tableId + ' tbody tr').each(function () {
			var row = $(this);
			var show = (role == "" || row.attr('data-roles').indexOf(' ' + role + ' ') >= 0)
				&& (!activeOnly || row.attr('data-open') == 'yes');
			row.toggleClass('d-none', !show);
		});
	}
</script>
</cfoutput>
<cfinclude template="/shared/_footer.cfm">
