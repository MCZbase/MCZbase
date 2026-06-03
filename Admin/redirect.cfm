<cfset pageTitle = "Manage Redirects">
<cfinclude template="/shared/_header.cfm">
<script src="/lib/misc/sorttable.js"></script>

<cfset local.action = "">
<cfif structKeyExists(form, "action")>
	<cfset local.action = form.action>
<cfelseif structKeyExists(url, "action")>
	<cfset local.action = url.action>
</cfif>

<cfset local.old_path = "">
<cfif structKeyExists(form, "old_path")>
	<cfset local.old_path = trim(form.old_path)>
<cfelseif structKeyExists(url, "old_path")>
	<cfset local.old_path = trim(url.old_path)>
</cfif>

<cfset local.new_path = "">
<cfif structKeyExists(form, "new_path")>
	<cfset local.new_path = trim(form.new_path)>
<cfelseif structKeyExists(url, "new_path")>
	<cfset local.new_path = trim(url.new_path)>
</cfif>

<cfset local.old = "">
<cfif structKeyExists(form, "old")>
	<cfset local.old = trim(form.old)>
<cfelseif structKeyExists(url, "old")>
	<cfset local.old = trim(url.old)>
</cfif>

<cfset local.new = "">
<cfif structKeyExists(form, "new")>
	<cfset local.new = trim(form.new)>
<cfelseif structKeyExists(url, "new")>
	<cfset local.new = trim(url.new)>
</cfif>
<cfquery name="totalRedirects" datasource="user_login" username="#session.dbuser#">
	SELECT COUNT(*) AS ct
	FROM redirect
</cfquery>

<cfif local.action IS "new">
	<cfquery name="insertRedirect" datasource="user_login" username="#session.dbuser#">
		INSERT INTO redirect (old_path, new_path)
		VALUES (
			<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#local.old#">,
			<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#local.new#">
		)
	</cfquery>
	<cflocation url="/Admin/redirect.cfm?old_path=#encodeForUrl(local.old)#&new_path=#encodeForUrl(local.new)#&action=search" addtoken="false">
</cfif>

<cfif local.action IS "search">
	<cfquery name="matchedRedirects" datasource="user_login" username="#session.dbuser#">
		SELECT
			old_path,
			new_path
		FROM
			redirect
		WHERE
			1 = 1
			<cfif len(local.old_path) GT 0>
				<cfif local.old_path EQ "%" OR uCase(local.old_path) EQ "NOT_NULL">
					AND old_path IS NOT NULL
				<cfelse>
					AND UPPER(old_path) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#uCase(local.old_path)#%">
				</cfif>
			</cfif>
			<cfif len(local.new_path) GT 0>
				<cfif local.new_path EQ "%" OR uCase(local.new_path) EQ "NOT_NULL">
					AND new_path IS NOT NULL
				<cfelse>
					AND UPPER(new_path) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#uCase(local.new_path)#%">
				</cfif>
			</cfif>
		ORDER BY
			old_path,
			new_path
	</cfquery>
</cfif>

<main class="container py-3" id="content">
	<section class="row g-3">
		<div class="col-12">
			<h1 class="h2">Manage Redirects</h1>
			<cfoutput>
				<p class="mb-0">Total redirects: <strong>#encodeForHtml(totalRedirects.ct)#</strong></p>
				<cfif local.action IS "search">
					<p class="mb-0">Matching redirects: <strong>#encodeForHtml(matchedRedirects.recordCount)#</strong></p>
				</cfif>
			</cfoutput>
		</div>
	</section>

	<section class="row g-3 mt-1">
		<div class="col-12 col-lg-6">
			<div class="border rounded p-3 h-100">
				<h2 class="h4">Find redirects</h2>
				<cfoutput>
				<form name="srch" method="post" action="/Admin/redirect.cfm">
					<input type="hidden" name="action" value="search">
					<div class="form-group">
						<label for="old_path" class="data-entry-label">old_path</label>
						<input type="text" name="old_path" id="old_path" value="#encodeForHtmlAttribute(local.old_path)#" class="data-entry-input" size="60">
					</div>
					<div class="form-group">
						<label for="new_path" class="data-entry-label">new_path</label>
						<input type="text" name="new_path" id="new_path" value="#encodeForHtmlAttribute(local.new_path)#" class="data-entry-input" size="60">
					</div>
					<p class="small text-muted">Use <code>%</code> or <code>NOT_NULL</code> to list all non-null values.</p>
					<input type="submit" value="Filter" class="btn btn-xs btn-primary">
				</form>
				</cfoutput>
			</div>
		</div>
		<div class="col-12 col-lg-6">
			<div class="border rounded p-3 h-100">
				<h2 class="h4">Create Redirect</h2>
				<form name="new" method="post" action="/Admin/redirect.cfm">
					<input type="hidden" name="action" value="new">
					<div class="form-group">
						<label for="old" class="data-entry-label">old (enter everything after the domain name, including a leading slash)</label>
						<input type="text" name="old" id="old" size="60" class="data-entry-input">
					</div>
					<div class="form-group">
						<label for="new" class="data-entry-label">new (enter everything after the domain name, including a leading slash)</label>
						<input type="text" name="new" id="new" size="60" class="data-entry-input">
					</div>
					<input type="submit" value="Create" class="btn btn-xs btn-primary">
				</form>
			</div>
		</div>
	</section>

	<cfif local.action IS "search">
		<section class="row mt-3">
			<div class="col-12">
				<cfoutput>
				<table id="redirectTable" class="sortable table table-responsive d-xl-table table-striped">
					<thead class="thead-light">
						<tr>
							<th scope="col">old_path</th>
							<th scope="col">new_path</th>
						</tr>
					</thead>
					<tbody>
						<cfloop query="matchedRedirects">
							<tr>
								<td><a href="#encodeForHtmlAttribute(old_path)#">#encodeForHtml(old_path)#</a></td>
								<td><a href="#encodeForHtmlAttribute(new_path)#">#encodeForHtml(new_path)#</a></td>
							</tr>
						</cfloop>
					</tbody>
				</table>
				</cfoutput>
			</div>
		</section>
	</cfif>
</main>

<cfinclude template="/shared/_footer.cfm">
