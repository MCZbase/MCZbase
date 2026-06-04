<!---
/Admin/user_report.cfm

Displays a report of all database users, their reported name, affiliation, email, and assigned roles. This report is intended to be used by global administrators to identify discrepancies between the database users and the users in MCZbase.

Copyright 2008-2017 Contributors to Arctos
Copyright 2020-2026 President and Fellows of Harvard College

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
<cfset pageTitle = "User Report">
<cfinclude template="/shared/_header.cfm">
<script src="/lib/misc/sorttable.js"></script>

<cfset local.canEditUsers = isDefined("session.roles") AND listFindNoCase(session.roles, "global_admin")>

<cfquery name="addDbUsers" datasource="uam_god">
	SELECT username
	FROM dba_users
	ORDER BY username
</cfquery>

<main class="container py-3" id="content">
	<section class="row">
		<div class="col-12">
			<cfoutput>
				<h1 class="h2">User Report (#encodeForHtml(addDbUsers.recordCount)#)</h1>
			</cfoutput>
		</div>
	</section>
	<section class="row mt-2">
		<div class="col-12">
			<cfoutput>
			<table id="userReportTable" class="sortable table table-responsive d-xl-table table-striped">
				<thead class="thead-light">
					<tr>
						<th scope="col">Username</th>
						<th scope="col">Reported Name</th>
						<th scope="col">Reported Affiliation</th>
						<th scope="col">Reported Email</th>
						<th scope="col">Assigned Roles</th>
					</tr>
				</thead>
				<tbody>
				<cfloop query="addDbUsers">
					<cfquery name="cfUser" datasource="uam_god">
						SELECT 
							FIRST_NAME,
							MIDDLE_NAME,
							LAST_NAME,
							AFFILIATION,
							EMAIL
						FROM
							cf_users,
							cf_user_data
						WHERE
							cf_users.user_id = cf_user_data.user_id
							AND upper(cf_users.username) = upper(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#addDbUsers.username#">)
					</cfquery>
					<cfquery name="roles" datasource="uam_god">
						SELECT granted_role role_name
						FROM 
							dba_role_privs,
							cf_ctuser_roles
						WHERE
							upper(dba_role_privs.granted_role) = upper(cf_ctuser_roles.role_name)
							AND upper(grantee) = upper(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#addDbUsers.username#">)
					</cfquery>
					<tr>
						<td>
							<cfif local.canEditUsers>
								<a href="/Admin/AdminUsers.cfm?action=edit&username=#encodeForUrl(addDbUsers.username)#">#encodeForHtml(addDbUsers.username)#</a>
							<cfelse>
								#encodeForHtml(addDbUsers.username)#
							</cfif>
						</td>
						<td>#encodeForHtml(trim(cfUser.FIRST_NAME & " " & cfUser.MIDDLE_NAME & " " & cfUser.LAST_NAME))#</td>
						<td>#encodeForHtml(cfUser.AFFILIATION)#</td>
						<td>#encodeForHtml(cfUser.EMAIL)#</td>
						<td>
							<cfloop query="roles">
								#encodeForHtml(role_name)#<br>
							</cfloop>
						</td>
					</tr>
				</cfloop>
				</tbody>
			</table>
			</cfoutput>
		</div>
	</section>
</main>

<cfinclude template="/shared/_footer.cfm">
