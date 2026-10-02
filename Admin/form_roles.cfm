<!---
Admin/form_roles.cfm

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
<!--- Set the roles cf_rolecheck requires for each page and component, in cf_form_permissions. --->
<cfset pageTitle = "Form Permissions">
<cfinclude template="/shared/_header.cfm">
<cfinclude template="/shared/component/fileUtilities.cfc" runOnce="true">
<cfif NOT ( isdefined("session.roles") AND listfindnocase(session.roles,"global_admin") ) >
	<cflocation url="/errors/forbidden.cfm" addtoken="false">
</cfif>

<!--- action is accepted for links that pass action=setRoles; the filter alone selects the files. --->
<cfparam name="url.action" default="">
<cfparam name="url.filter" default="">
<cfset variables.filter = trim(url.filter)>

<!--- Same exclusions as /tools/uncontrolledPages.cfm. --->
<cfset variables.EXCLUDED_DIRECTORIES = "lib,.git,CFIDE,WEB-INF,META-INF,cfdocs,temp,download,tempImages,mediaUploads,specimen_images,cache,CustomTags,binary_stuff,log,node_modules,bower_components">
<cfset variables.MAX_FILES = 300>

<cfset variables.matches = arrayNew(1)>
<cfif len(variables.filter) GT 0>
	<cfloop array="#listColdFusionFiles(application.webDirectory, variables.EXCLUDED_DIRECTORIES)#" index="variables.relativePath">
		<cfif findNoCase(variables.filter, variables.relativePath) GT 0>
			<cfset arrayAppend(variables.matches, variables.relativePath)>
		</cfif>
	</cfloop>
	<cfquery name="getRoles" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getRoles_result">
		SELECT role_name, description
		FROM cf_ctuser_roles
		ORDER BY role_name
	</cfquery>
	<cfquery name="getPermissions" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getPermissions_result">
		SELECT form_path, role_name
		FROM cf_form_permissions
		ORDER BY form_path, role_name
	</cfquery>
	<!--- Lower case role list for each path, for case insensitive matching against cf_ctuser_roles. --->
	<cfset variables.permissions = structNew()>
	<cfloop query="getPermissions">
		<cfif NOT structKeyExists(variables.permissions, getPermissions.form_path)>
			<cfset variables.permissions[getPermissions.form_path] = "">
		</cfif>
		<cfset variables.permissions[getPermissions.form_path] = listAppend(variables.permissions[getPermissions.form_path], lcase(getPermissions.role_name))>
	</cfloop>
</cfif>

<main class="container-fluid py-3" id="content">
	<section class="row mx-0 my-2">
		<div class="col-12">
			<h1 class="h2">Form Permissions</h1>
			<p>
				Set the roles a user needs to load each page or call each component.
				<code>cf_rolecheck</code> requires <strong>every</strong> role checked for a file, and refuses a file with none checked, for everyone.
				It runs only for pages that include a header and for components that call <code>&lt;cf_rolecheck&gt;</code>; for other files these settings have no effect.
				Changes are saved as soon as a box is checked or cleared, and can take up to an hour to apply, as lookups are cached.
				See the <a href="/tools/uncontrolledPages.cfm">Form Permissions Audit</a> for files with no permissions, stale rows and rows that are not enforced.
			</p>
			<cfoutput>
				<form method="get" action="/Admin/form_roles.cfm" class="form-row align-items-end mb-2">
					<input type="hidden" name="action" value="setRoles">
					<div class="col-12 col-md-6 col-xl-4">
						<label for="filter" class="data-entry-label">Path contains (for example <code>/Admin/</code> or <code>functions.cfc</code>)</label>
						<input type="text" name="filter" id="filter" class="data-entry-input" value="#encodeForHtml(variables.filter)#" required>
					</div>
					<div class="col-12 col-md-auto">
						<button type="submit" class="btn btn-xs btn-primary">Search</button>
					</div>
				</form>
			</cfoutput>
		</div>
	</section>

	<cfif len(variables.filter) GT 0>
		<cfoutput>
		<section class="row mx-0 my-2 mb-4 border rounded">
			<div class="col-12 py-2">
				<h2 class="h3">#arrayLen(variables.matches)# files matching <code>#encodeForHtml(variables.filter)#</code></h2>
				<output id="saveFeedback" class="d-block mb-2" aria-live="polite">&nbsp;</output>
				<cfif arrayLen(variables.matches) EQ 0>
					<p class="font-italic">No .cfm or .cfc files match.</p>
				<cfelseif arrayLen(variables.matches) GT variables.MAX_FILES>
					<p>That matches more than #variables.MAX_FILES# files. Use a more specific filter.</p>
				<cfelse>
					<!--- No d-xl-table: with a column per role the grid needs its horizontal scroll at every width. --->
					<table class="table table-responsive table-sm table-striped">
						<thead class="thead-light">
							<tr>
								<th scope="col">File</th>
								<th scope="col">Roles required</th>
								<cfloop query="getRoles">
									<th scope="col" class="small" title="#encodeForHtmlAttribute(getRoles.description)#">#encodeForHtml(replace(getRoles.role_name, "_", "_ ", "all"))#</th>
								</cfloop>
							</tr>
						</thead>
						<tbody>
							<cfset variables.i = 0>
							<cfloop array="#variables.matches#" index="variables.path">
								<cfset variables.i = variables.i + 1>
								<cfset variables.pathRoles = "">
								<cfif structKeyExists(variables.permissions, variables.path)>
									<cfset variables.pathRoles = variables.permissions[variables.path]>
								</cfif>
								<cfset variables.rolesText = "none: refused for everyone">
								<cfset variables.rolesClass = "text-danger">
								<cfif len(variables.pathRoles) GT 0>
									<cfset variables.rolesText = replace(variables.pathRoles, ",", ", ", "all")>
									<cfset variables.rolesClass = "">
								</cfif>
								<tr>
									<th scope="row" class="small font-weight-normal">#encodeForHtml(variables.path)#</th>
									<td class="small #variables.rolesClass#" id="rolesFor_#variables.i#">#encodeForHtml(variables.rolesText)#</td>
									<cfloop query="getRoles">
										<cfset variables.checked = "">
										<cfif listFind(variables.pathRoles, lcase(getRoles.role_name)) GT 0>
											<cfset variables.checked = "checked">
										</cfif>
										<td class="text-center">
											<input type="checkbox" #variables.checked#
												aria-label="Require #encodeForHtmlAttribute(getRoles.role_name)# for #encodeForHtmlAttribute(variables.path)#"
												onchange="setFormPermission(this, '#encodeForJavaScript(variables.path)#', '#encodeForJavaScript(getRoles.role_name)#', 'rolesFor_#variables.i#', 'saveFeedback');">
										</td>
									</cfloop>
								</tr>
							</cfloop>
						</tbody>
					</table>
				</cfif>
			</div>
		</section>
		</cfoutput>
	</cfif>
</main>

<cfoutput>
<script>
	/** setFormPermission save one checkbox of the permissions grid, reverting it if the save fails.
	 * @param checkbox the checkbox that changed.
	 * @param formPath the webroot relative path of the file.
	 * @param roleName the role the checkbox represents.
	 * @param rolesCellId the id of the cell listing the file's required roles, without the leading ##.
	 * @param feedbackId the id of the output element for status messages, without the leading ##.
	 */
	function setFormPermission(checkbox, formPath, roleName, rolesCellId, feedbackId) {
		var granted = checkbox.checked;
		checkbox.disabled = true;
		$('##' + feedbackId).html('<img src="/shared/images/indicator.gif" alt=""> Saving...');
		$.ajax({
			url: "/Admin/component/functions.cfc",
			type: "post",
			dataType: "json",
			data: {
				method: "setFormPermission",
				returnformat: "json",
				form_path: formPath,
				role_name: roleName,
				granted: granted
			},
			success: function (result) {
				checkbox.disabled = false;
				if (result.status == "saved") {
					var roles = result.roles.length > 0 ? result.roles.toLowerCase().split(",").join(", ") : "none: refused for everyone";
					$('##' + rolesCellId).text(roles).toggleClass("text-danger", result.roles.length == 0);
					$('##' + feedbackId).text("Saved: " + formPath + " now requires " + roles + ".");
				} else {
					checkbox.checked = !granted;
					$('##' + feedbackId).text("Not saved: " + result.message);
				}
			},
			error: function (jqXHR, textStatus, error) {
				checkbox.disabled = false;
				checkbox.checked = !granted;
				$('##' + feedbackId).text("Not saved.");
				handleFail(jqXHR, textStatus, error, "saving form permissions");
			}
		});
	}
</script>
</cfoutput>
<cfinclude template="/shared/_footer.cfm">
