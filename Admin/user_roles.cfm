<cfset pageTitle = "Application Roles">
<!---
/Admin/user_roles.cfm

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
<!--- Display and manage application roles with user counts and privilege counts. --->
<cfinclude template="/shared/_header.cfm">
<cfif isDefined("url.action")><cfset local.action = url.action></cfif>
<cfif NOT isDefined("local.action") OR len(local.action) EQ 0><cfset local.action = "entryPoint"></cfif>
<cfif isDefined("url.role_name")><cfset local.role_name = url.role_name></cfif>
<cfif NOT isDefined("local.role_name")><cfset local.role_name = ""></cfif>

<cfswitch expression="#local.action#">
	<cfcase value="entryPoint">
		<script src="/lib/misc/sorttable.js"></script>
		<main class="container py-3" id="content">
			<section class="row my-2">
				<div class="col-12">
					<h1 class="h2 px-4">Application Roles</h1>
					<p class="px-4">The following roles are defined for this application. Each role may be granted to database users to control access to MCZbase features.</p>
				</div>
				<div class="col-12">
					<cfquery name="roleList" datasource="uam_god">
						SELECT
							r.role_name,
							r.description,
							(
								SELECT COUNT(*)
								FROM dba_role_privs drp
								WHERE UPPER(drp.granted_role) = UPPER(r.role_name)
									AND drp.grantee NOT IN (SELECT role FROM dba_roles)
							) AS user_count,
							(
								SELECT COUNT(DISTINCT tp.table_name)
								FROM dba_tab_privs tp
								WHERE UPPER(tp.grantee) = UPPER(r.role_name)
									AND tp.owner = 'MCZBASE'
							) AS priv_count
						FROM cf_ctuser_roles r
						ORDER BY r.role_name
					</cfquery>
					<cfoutput>
					<table id="rolesTable" class="sortable table table-responsive d-xl-table">
						<thead class="thead-light">
							<tr>
								<th scope="col">Role Name</th>
								<th scope="col">Description</th>
								<th scope="col">Users Granted</th>
								<th scope="col">Tables with Privileges</th>
								<th scope="col">DB Definition</th>
							</tr>
						</thead>
						<tbody>
							<cfloop query="roleList">
								<tr>
									<td>#encodeForHtml(role_name)#</td>
									<td>#encodeForHtml(description)#</td>
									<td>#encodeForHtml(user_count)#</td>
									<td>#encodeForHtml(priv_count)#</td>
									<td>
										<a class="btn btn-xs btn-secondary" href="/Admin/user_roles.cfm?action=defineRole&amp;role_name=#encodeForUrl(role_name)#">
											View Privileges
										</a>
									</td>
								</tr>
							</cfloop>
						</tbody>
					</table>
					</cfoutput>
				</div>
			</section>
		</main>
	</cfcase>
	<cfcase value="defineRole">
		<cfif len(local.role_name) EQ 0>
			<cflocation url="/Admin/user_roles.cfm" addtoken="no">
		</cfif>
		<cfquery name="roleDetail" datasource="uam_god">
			SELECT
				role_name,
				description
			FROM cf_ctuser_roles
			WHERE UPPER(role_name) = UPPER(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#local.role_name#">)
		</cfquery>
		<cfif roleDetail.recordCount EQ 0>
			<cflocation url="/Admin/user_roles.cfm" addtoken="no">
		</cfif>
		<cfquery name="execPrivs" datasource="uam_god">
			SELECT
				tp.owner,
				tp.table_name AS object_name,
				o.object_type
			FROM dba_tab_privs tp
			LEFT JOIN dba_objects o
				ON o.object_name = tp.table_name
				AND o.owner = tp.owner
				AND o.object_type IN ('PROCEDURE', 'FUNCTION', 'PACKAGE', 'PACKAGE BODY', 'TYPE')
			WHERE tp.privilege = 'EXECUTE'
				AND UPPER(tp.grantee) = UPPER(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#local.role_name#">)
				AND tp.owner = 'MCZBASE'
			ORDER BY o.object_type, tp.table_name
		</cfquery>
		<cfquery name="tablePrivs" datasource="uam_god">
			SELECT
				table_name,
				grantee,
				MAX(DECODE(privilege, 'SELECT', 'yes', 'no')) AS select_priv,
				MAX(DECODE(privilege, 'INSERT', 'yes', 'no')) AS insert_priv,
				MAX(DECODE(privilege, 'UPDATE', 'yes', 'no')) AS update_priv,
				MAX(DECODE(privilege, 'DELETE', 'yes', 'no')) AS delete_priv
			FROM dba_tab_privs
			WHERE grantee IN (
				SELECT role FROM dba_roles
			)
			AND UPPER(grantee) = UPPER(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#local.role_name#">)
			AND owner = 'MCZBASE'
			GROUP BY table_name, grantee
			ORDER BY table_name
		</cfquery>
		<script src="/lib/misc/sorttable.js"></script>
		<cfoutput>
		<main class="container py-3" id="content">
			<section class="row my-2">
				<div class="col-12">
					<h1 class="h2 px-4">
						Table Privileges for Role: #encodeForHtml(roleDetail.role_name)#
					</h1>
					<cfif len(roleDetail.description) GT 0>
						<p class="px-4">#encodeForHtml(roleDetail.description)#</p>
					</cfif>
					<p class="px-4">
						<a class="btn btn-xs btn-secondary" href="/Admin/user_roles.cfm">&laquo; Back to All Roles</a>
					</p>
				</div>
				<div class="col-12">
					<cfif tablePrivs.recordCount EQ 0>
						<p class="px-4 text-muted">No table-level privileges found for this role.</p>
					<cfelse>
						<table id="tablePrivsTable" class="sortable table table-responsive d-xl-table">
							<thead class="thead-light">
								<tr>
									<th scope="col">Role</th>
									<th scope="col">Table Name</th>
									<th scope="col">Select</th>
									<th scope="col">Insert</th>
									<th scope="col">Update</th>
									<th scope="col">Delete</th>
								</tr>
							</thead>
							<tbody>
								<cfloop query="tablePrivs">
									<tr>
										<td>#encodeForHtml(grantee)#</td>
										<td>#encodeForHtml(table_name)#</td>
										<td>#encodeForHtml(select_priv)#</td>
										<td>#encodeForHtml(insert_priv)#</td>
										<td>#encodeForHtml(update_priv)#</td>
										<td>#encodeForHtml(delete_priv)#</td>
									</tr>
								</cfloop>
							</tbody>
						</table>
					</cfif>
				</div>
			</section>
			<section class="row my-2">
				<div class="col-12">
					<h2 class="h4 px-4">Execute Privileges (Procedures, Functions, Packages)</h2>
				</div>
				<div class="col-12">
					<cfif execPrivs.recordCount EQ 0>
						<p class="px-4 text-muted">No execute privileges on PL/SQL objects found for this role.</p>
					<cfelse>
						<table id="execPrivsTable" class="sortable table table-responsive d-xl-table">
							<thead class="thead-light">
								<tr>
									<th scope="col">Object Type</th>
									<th scope="col">Owner</th>
									<th scope="col">Object Name</th>
								</tr>
							</thead>
							<tbody>
								<cfloop query="execPrivs">
									<tr>
										<td>#encodeForHtml(object_type)#</td>
										<td>#encodeForHtml(owner)#</td>
										<td>#encodeForHtml(object_name)#</td>
									</tr>
								</cfloop>
							</tbody>
						</table>
					</cfif>
				</div>
			</section>
		</main>
		</cfoutput>
	</cfcase>
	<cfdefaultcase>
		<cflocation url="/Admin/user_roles.cfm" addtoken="no">
	</cfdefaultcase>
</cfswitch>

<cfinclude template="/shared/_footer.cfm">
