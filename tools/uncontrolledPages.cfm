<!---
tools/uncontrolledPages.cfm

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
<!--- Read-only audit of cf_form_permissions against the ColdFusion files under the webroot. --->
<cfset pageTitle = "Form Permissions Audit">
<cfinclude template="/shared/_header.cfm">
<cfinclude template="/shared/component/fileUtilities.cfc" runOnce="true">
<!--- The cf_form_permissions row for this page requires only coldfusion_user. --->
<cfif NOT ( isdefined("session.roles") AND listfindnocase(session.roles,"global_admin") ) >
	<cflocation url="/errors/forbidden.cfm" addtoken="false">
</cfif>
<cfsetting requesttimeout="300">

<!--- Libraries, generated files and media, and directories Application.cfc refuses outright. --->
<cfset variables.EXCLUDED_DIRECTORIES = "lib,.git,CFIDE,WEB-INF,META-INF,cfdocs,temp,download,tempImages,mediaUploads,specimen_images,cache,CustomTags,binary_stuff,log,node_modules,bower_components">
<cfset variables.BROAD_ROLES = "public,coldfusion_user">
<cfset variables.STAFF_DIRECTORIES = "/Admin/,/tools/,/ScheduledTasks/,/Bulkloader/">
<cfset variables.HEADER_PATTERN = "<cfinclude[^>]+template\s*=\s*[""']\s*(\.\./|/)*(shared/_header|includes/_header|includes/_pickHeader|includes/_frameHeader)\.cfm">
<!--- Templates that invoke cf_rolecheck for the page that includes them; never requested themselves. --->
<cfset variables.HEADER_TEMPLATES = "/shared/_header.cfm,/includes/_header.cfm,/includes/_pickHeader.cfm,/includes/_frameHeader.cfm">
<!--- Directories Application.cfc refuses for every request. --->
<cfset variables.REFUSED_DIRECTORIES = "/CustomTags/,/binary_stuff/,/log/">

<!---
	permissionCheckFor report how a ColdFusion file runs cf_rolecheck, by looking for an include of
	one of the headers that invoke it, or a direct call.  This is a text search: a commented out
	include counts, and a check reached through some other include does not.

	@param fullPath the file to examine.
	@return "header" or "cf_rolecheck" when the file runs the check, otherwise an empty string.
--->
<cffunction name="permissionCheckFor" returntype="string" output="false">
	<cfargument name="fullPath" type="string" required="yes">
	<cfset var content = "">
	<cftry>
		<cfset content = fileRead(arguments.fullPath)>
	<cfcatch>
		<cfreturn "">
	</cfcatch>
	</cftry>
	<cfif findNoCase("<cf_rolecheck", content) GT 0>
		<cfreturn "cf_rolecheck">
	</cfif>
	<cfif REFindNoCase(variables.HEADER_PATTERN, content) GT 0>
		<cfreturn "header">
	</cfif>
	<cfreturn "">
</cffunction>

<cfset variables.webRoot = REReplace(application.webDirectory, "/+$", "")>

<!--- ColdFusion files under the webroot, keyed by webroot relative path, with how each runs cf_rolecheck. --->
<cfset variables.files = structNew()>
<cfloop array="#listColdFusionFiles(variables.webRoot, variables.EXCLUDED_DIRECTORIES)#" index="variables.relativePath">
	<cfset variables.files[variables.relativePath] = permissionCheckFor(variables.webRoot & variables.relativePath)>
</cfloop>

<cfquery name="getPermissions" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getPermissions_result">
	SELECT key, form_path, role_name
	FROM cf_form_permissions
	ORDER BY form_path, role_name
</cfquery>
<!--- Roles and row keys for each path in cf_form_permissions. --->
<cfset variables.permissions = structNew()>
<cfloop query="getPermissions">
	<cfif NOT structKeyExists(variables.permissions, getPermissions.form_path)>
		<cfset variables.permissions[getPermissions.form_path] = { roles = "", keys = "" }>
	</cfif>
	<cfset variables.permissions[getPermissions.form_path].roles = listAppend(variables.permissions[getPermissions.form_path].roles, getPermissions.role_name)>
	<cfset variables.permissions[getPermissions.form_path].keys = listAppend(variables.permissions[getPermissions.form_path].keys, getPermissions.key)>
</cfloop>

<!--- Section 1: files that run cf_rolecheck but have no row, which it refuses for everyone. --->
<cfset variables.noRow = arrayNew(1)>
<cfloop list="#listSort(structKeyList(variables.files, chr(9)), 'textnocase', 'asc', chr(9))#" index="variables.path" delimiters="#chr(9)#">
	<cfif len(variables.files[variables.path]) GT 0 AND NOT structKeyExists(variables.permissions, variables.path) AND listFind(variables.HEADER_TEMPLATES, variables.path) EQ 0>
		<cfset arrayAppend(variables.noRow, { path = variables.path, check = variables.files[variables.path] })>
	</cfif>
</cfloop>

<!--- Sections 2 to 4 classify each path that has rows. --->
<cfset variables.stale = arrayNew(1)>
<cfset variables.staleKeys = "">
<cfset variables.unenforced = arrayNew(1)>
<cfset variables.broad = arrayNew(1)>
<cfloop list="#listSort(structKeyList(variables.permissions, chr(9)), 'textnocase', 'asc', chr(9))#" index="variables.path" delimiters="#chr(9)#">
	<cfset variables.entry = variables.permissions[variables.path]>
	<cfif NOT fileExists(variables.webRoot & variables.path)>
		<cfset arrayAppend(variables.stale, { path = variables.path, roles = variables.entry.roles, keys = variables.entry.keys })>
		<cfset variables.staleKeys = listAppend(variables.staleKeys, variables.entry.keys)>
	<cfelse>
		<cfset variables.inRefusedDirectory = false>
		<cfloop list="#variables.REFUSED_DIRECTORIES#" index="variables.refusedDirectory">
			<cfif left(variables.path, len(variables.refusedDirectory)) EQ variables.refusedDirectory>
				<cfset variables.inRefusedDirectory = true>
			</cfif>
		</cfloop>
		<cfif variables.inRefusedDirectory>
			<cfset variables.check = "">
			<cfset variables.reason = "In a directory Application.cfc refuses for every request; the row is unnecessary.">
		<cfelseif listFindNoCase("cfm,cfc", listLast(variables.path, ".")) EQ 0>
			<cfset variables.check = "">
			<cfset variables.reason = "Not a ColdFusion template; cf_rolecheck never looks this path up.">
		<cfelseif structKeyExists(variables.files, variables.path)>
			<cfset variables.check = variables.files[variables.path]>
			<cfset variables.reason = "Includes no header and does not call cf_rolecheck.">
		<cfelse>
			<cfset variables.check = permissionCheckFor(variables.webRoot & variables.path)>
			<cfset variables.reason = "Includes no header and does not call cf_rolecheck (in a directory this audit does not scan).">
		</cfif>
		<cfif len(variables.check) EQ 0>
			<cfset arrayAppend(variables.unenforced, { path = variables.path, roles = variables.entry.roles, reason = variables.reason })>
		</cfif>
		<cfset variables.isBroad = true>
		<cfloop list="#variables.entry.roles#" index="variables.role">
			<cfif listFindNoCase(variables.BROAD_ROLES, variables.role) EQ 0>
				<cfset variables.isBroad = false>
			</cfif>
		</cfloop>
		<cfset variables.inStaffDirectory = false>
		<cfloop list="#variables.STAFF_DIRECTORIES#" index="variables.staffDirectory">
			<cfif left(variables.path, len(variables.staffDirectory)) EQ variables.staffDirectory>
				<cfset variables.inStaffDirectory = true>
			</cfif>
		</cfloop>
		<cfif variables.isBroad AND variables.inStaffDirectory>
			<cfset arrayAppend(variables.broad, { path = variables.path, roles = variables.entry.roles, enforced = len(variables.check) GT 0 })>
		</cfif>
	</cfif>
</cfloop>

<script src="/lib/misc/sorttable.js"></script>
<cfoutput>
<main class="container-fluid py-3" id="content">
	<section class="row mx-0 my-2">
		<div class="col-12">
			<h1 class="h2">Form Permissions Audit</h1>
			<p>
				This page compares <code>cf_form_permissions</code> with the ColdFusion files under the webroot.
				It only reads; nothing on this page changes permissions. Use
				<a href="/Admin/form_roles.cfm">Form Permissions</a> to add or remove rows.
			</p>
			<h2 class="h3">How page permissions work</h2>
			<ul>
				<li><code>cf_rolecheck</code> looks up the requested path (<code>cgi.script_name</code>) in <code>cf_form_permissions</code>. The user must hold <strong>every</strong> role listed for that path. A path with no rows is refused for everyone.</li>
				<li>It runs only when a page includes <code>/shared/_header.cfm</code>, <code>/includes/_header.cfm</code>, <code>/includes/_pickHeader.cfm</code> or <code>/includes/_frameHeader.cfm</code>, or when a file calls <code>&lt;cf_rolecheck&gt;</code> itself, as a component must. For any other file its rows have no effect, and access control must be in the code.</li>
				<li>Code that runs before the header include is not checked.</li>
				<li>When a component includes another component, the included file's remote methods are checked against the outer component's path. <strong>Including /topic/component/functions.cfc in /topic/component/public.cfc will provide access to the methods in functions.cfc with the access control on public.cfc, meaning that methods inside functions.cfc will need their own individual permissions checks.</strong></li>
				<li>Lookups are cached for an hour, so a change to a row can take that long to apply.  You can make a temporary edit (from 1 to 0) to the cachedWithin timespan in isValid in line 15 of /CustomTags/rolecheck.cfm to clear this cache.</li>
				<li><code>Application.cfc</code> separately refuses <code>/CustomTags/</code>, <code>/binary_stuff/</code> and <code>/log/</code>. It also refuses users whose only role is <code>public</code> from <code>/Admin/</code>, <code>/ALA_Imaging/</code>, <code>/Bulkloader/</code>, <code>/fix/</code>, <code>/picks/</code>, <code>/tools/</code> and <code>/ScheduledTasks/</code>, and requires <code>coldfusion_user</code> for <code>/Reports/</code>. Those checks apply only to requests ColdFusion handles; Apache serves other files directly.</li>
				<li>A role here controls who can open a page. What the page then does is still limited by the user's Oracle grants, except where it uses the <code>uam_god</code> or <code>cf_dbuser</code> datasources.</li>
			</ul>
			<p class="small text-secondary">
				Scanned #structCount(variables.files)# <code>.cfm</code> and <code>.cfc</code> files and #getPermissions.recordcount# permission rows for #structCount(variables.permissions)# paths.
				Not scanned: <code>#encodeForHtml(replace(variables.EXCLUDED_DIRECTORIES, ",", ", ", "all"))#</code>.
				Whether a file runs <code>cf_rolecheck</code> is decided by searching its text, so a commented out include counts, and a check reached through another include does not.
			</p>
			<ul>
				<li><a href="##noRow">1. Files refused for everyone (no row)</a>: #arrayLen(variables.noRow)#</li>
				<li><a href="##stale">2. Rows for files that do not exist</a>: #arrayLen(variables.stale)#</li>
				<li><a href="##unenforced">3. Rows that are not enforced</a>: #arrayLen(variables.unenforced)#</li>
				<li><a href="##broad">4. Broad rows in staff directories</a>: #arrayLen(variables.broad)#</li>
			</ul>
		</div>
	</section>

	<section class="row mx-0 my-2 border rounded" id="noRow">
		<div class="col-12 py-2">
			<h2 class="h3">1. Files refused for everyone</h2>
			<p>
				These files run <code>cf_rolecheck</code> but have no row, so every request is refused, for public visitors and staff alike.
				That is usually a new page or component that was never given permissions.
				For a component, every remote method fails, which typically shows as a broken AJAX section on the pages that use it.
				Add rows for the roles that should reach it, or remove the file if it is unused.
			</p>
			<cfif arrayLen(variables.noRow) EQ 0>
				<p class="font-italic">None.</p>
			<cfelse>
				<table class="table table-responsive d-xl-table table-sm table-striped sortable">
					<thead class="thead-light">
						<tr><th>File</th><th>Checked by</th><th>Permissions</th></tr>
					</thead>
					<tbody>
						<cfloop array="#variables.noRow#" index="variables.item">
							<tr>
								<td>#encodeForHtml(variables.item.path)#</td>
								<td>#encodeForHtml(variables.item.check)#</td>
								<td><a href="/Admin/form_roles.cfm?action=setRoles&filter=#encodeForUrl(variables.item.path)#">set permissions</a></td>
							</tr>
						</cfloop>
					</tbody>
				</table>
			</cfif>
		</div>
	</section>

	<section class="row mx-0 my-2 border rounded" id="stale">
		<div class="col-12 py-2">
			<h2 class="h3">2. Rows for files that do not exist</h2>
			<p>
				These rows name paths with no file under the webroot, usually pages that have been removed or renamed.
				They grant nothing today, but a file later created at the same path would inherit them, so they should be deleted.
				Before deleting, check the path is not a file served from outside this checkout. File names on the server are case sensitive, so a path that differs from a real file only in letter case is listed here.
			</p>
			<cfif arrayLen(variables.stale) EQ 0>
				<p class="font-italic">None.</p>
			<cfelse>
				<table class="table table-responsive d-xl-table table-sm table-striped sortable">
					<thead class="thead-light">
						<tr><th>Path</th><th>Roles</th><th>Row keys</th></tr>
					</thead>
					<tbody>
						<cfloop array="#variables.stale#" index="variables.item">
							<tr>
								<td>#encodeForHtml(variables.item.path)#</td>
								<td>#encodeForHtml(replace(variables.item.roles, ",", ", ", "all"))#</td>
								<td>#encodeForHtml(replace(variables.item.keys, ",", ", ", "all"))#</td>
							</tr>
						</cfloop>
					</tbody>
				</table>
				<p class="small">
					To remove them: <code>DELETE FROM cf_form_permissions WHERE key IN (#encodeForHtml(replace(variables.staleKeys, ",", ", ", "all"))#);</code>
				</p>
			</cfif>
		</div>
	</section>

	<section class="row mx-0 my-2 border rounded" id="unenforced">
		<div class="col-12 py-2">
			<h2 class="h3">3. Rows that are not enforced</h2>
			<p>
				These files have rows, but nothing ever checks them: the file includes no header and does not call <code>cf_rolecheck</code>, or is not a ColdFusion template.
				The roles listed do <strong>not</strong> restrict access.
				Unless the file is reached only by inclusion, anyone who can reach its directory can request it. For a component, that includes every <code>access="remote"</code> method.
				Many are intended to be open: error pages, library files only ever included by other pages, and public endpoints.
				Review the rest, especially components with remote methods and anything in a staff directory.
				Either add <code>&lt;cf_rolecheck&gt;</code> (at the top of a component, or a header include for a page), or make sure every action the file takes checks <code>session.roles</code> itself.
			</p>
			<cfif arrayLen(variables.unenforced) EQ 0>
				<p class="font-italic">None.</p>
			<cfelse>
				<table class="table table-responsive d-xl-table table-sm table-striped sortable">
					<thead class="thead-light">
						<tr><th>File</th><th>Roles (not enforced)</th><th>Why</th></tr>
					</thead>
					<tbody>
						<cfloop array="#variables.unenforced#" index="variables.item">
							<tr>
								<td>#encodeForHtml(variables.item.path)#</td>
								<td>#encodeForHtml(replace(variables.item.roles, ",", ", ", "all"))#</td>
								<td>#encodeForHtml(variables.item.reason)#</td>
							</tr>
						</cfloop>
					</tbody>
				</table>
			</cfif>
		</div>
	</section>

	<section class="row mx-0 my-2 mb-4 border rounded" id="broad">
		<div class="col-12 py-2">
			<h2 class="h3">4. Broad rows in staff directories</h2>
			<p>
				These files are under <code>#encodeForHtml(replace(variables.STAFF_DIRECTORIES, ",", ", ", "all"))#</code>, and their only roles are <code>public</code> or <code>coldfusion_user</code>.
				So any staff login can open them, and where the role is <code>public</code>, any account with a role beyond <code>public</code> can too.
				Many are intended for all staff. Review the rest, especially administrative tools, scheduled tasks and anything that writes through the <code>uam_god</code> or <code>cf_dbuser</code> datasources, and give them the specific role they need, such as <code>global_admin</code>.
				Where the row is not enforced (see section 3), changing it has no effect until the file runs <code>cf_rolecheck</code>.
			</p>
			<cfif arrayLen(variables.broad) EQ 0>
				<p class="font-italic">None.</p>
			<cfelse>
				<table class="table table-responsive d-xl-table table-sm table-striped sortable">
					<thead class="thead-light">
						<tr><th>File</th><th>Roles</th><th>Enforced</th><th>Permissions</th></tr>
					</thead>
					<tbody>
						<cfloop array="#variables.broad#" index="variables.item">
							<cfset variables.enforcedText = "no">
							<cfif variables.item.enforced>
								<cfset variables.enforcedText = "yes">
							</cfif>
							<tr>
								<td>#encodeForHtml(variables.item.path)#</td>
								<td>#encodeForHtml(replace(variables.item.roles, ",", ", ", "all"))#</td>
								<td>#variables.enforcedText#</td>
								<td><a href="/Admin/form_roles.cfm?action=setRoles&filter=#encodeForUrl(variables.item.path)#">set permissions</a></td>
							</tr>
						</cfloop>
					</tbody>
				</table>
			</cfif>
		</div>
	</section>
</main>
</cfoutput>
<cfinclude template="/shared/_footer.cfm">
