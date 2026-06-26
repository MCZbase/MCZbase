<cfset pageTitle = "Media Licenses">
<!---
/vocabularies/ctmedia_license.cfm

Manage ctmedia_license code table: media license display names, descriptions, and URIs.
Provides insert, update, and delete of media license records.

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
<cfset variables.action = "entryPoint">
<cfif isDefined("form.action") AND len(trim(form.action)) GT 0>
	<cfset variables.action = trim(form.action)>
<cfelseif isDefined("url.action") AND len(trim(url.action)) GT 0>
	<cfset variables.action = trim(url.action)>
</cfif>

<cfswitch expression="#variables.action#">
	<cfcase value="delete">
		<cfif isDefined("form.media_license_id") AND isNumeric(form.media_license_id)>
			<cfquery name="del" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				DELETE FROM ctmedia_license
				WHERE media_license_id = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#form.media_license_id#">
			</cfquery>
		</cfif>
		<cflocation url="/vocabularies/ctmedia_license.cfm" addtoken="false">
	</cfcase>
	<cfcase value="save">
		<cfif isDefined("form.media_license_id") AND isNumeric(form.media_license_id)
			AND isDefined("form.display") AND isDefined("form.description") AND isDefined("form.uri")>
			<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE ctmedia_license SET
					display      = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(form.display)#">,
					description  = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(form.description)#">,
					uri          = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(form.uri)#">
				WHERE media_license_id = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#form.media_license_id#">
			</cfquery>
		</cfif>
		<cflocation url="/vocabularies/ctmedia_license.cfm" addtoken="false">
	</cfcase>
	<cfcase value="insert">
		<cfif isDefined("form.display") AND len(trim(form.display)) GT 0
			AND isDefined("form.description") AND isDefined("form.uri")>
			<cfquery name="ins" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				INSERT INTO ctmedia_license (display, description, uri)
				VALUES (
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(form.display)#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(form.description)#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(form.uri)#">
				)
			</cfquery>
		</cfif>
		<cflocation url="/vocabularies/ctmedia_license.cfm" addtoken="false">
	</cfcase>
</cfswitch>

<cfquery name="q" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	SELECT media_license_id, display, description, uri
	FROM ctmedia_license
	ORDER BY display
</cfquery>

<cfinclude template="/shared/_header.cfm">
<cfoutput>
<main id="content" aria-labelledby="pageHeading">
	<div class="row">
		<div class="col-12">
			<h1 id="pageHeading" class="h3 mt-3 mb-1">Media Licenses</h1>
			<p class="text-muted small">Manage media license display names, descriptions, and URIs used for specimen media.</p>
		</div>
	</div>

	<section aria-labelledby="addHeading">
		<h2 id="addHeading" class="h5 mt-3 mb-2 text-success">Add Media License</h2>
		<div class="border rounded p-3 bg-light mb-4">
			<form method="post" action="/vocabularies/ctmedia_license.cfm">
				<input type="hidden" name="action" value="insert">
				<div class="form-row align-items-end">
					<div class="col-auto">
						<label class="col-form-label-sm font-weight-bold" for="newDisplay">Display Name <span class="text-danger">*</span></label>
						<input type="text" class="form-control form-control-sm" id="newDisplay" name="display" required>
					</div>
					<div class="col-auto">
						<label class="col-form-label-sm font-weight-bold" for="newUri">URI</label>
						<input type="text" class="form-control form-control-sm" id="newUri" name="uri">
					</div>
					<div class="col">
						<label class="col-form-label-sm font-weight-bold" for="newDescription">Description</label>
						<textarea class="form-control form-control-sm" id="newDescription" name="description" rows="2"></textarea>
					</div>
					<div class="col-auto">
						<button type="submit" class="btn btn-sm btn-success">Add</button>
					</div>
				</div>
			</form>
		</div>
	</section>

	<section aria-labelledby="editHeading">
		<h2 id="editHeading" class="h5 mt-2 mb-2">Edit Media Licenses</h2>
		<div class="d-table w-100 border rounded">
			<div class="d-table-row bg-light font-weight-bold">
				<div class="d-table-cell p-2 border-bottom">Display Name</div>
				<div class="d-table-cell p-2 border-bottom">URI</div>
				<div class="d-table-cell p-2 border-bottom">Description</div>
				<div class="d-table-cell p-2 border-bottom">Actions</div>
			</div>
			<cfset variables.fid = "">
			<cfloop query="q">
				<cfset variables.fid = "lic" & media_license_id>
				<form
					class="d-table-row"
					name="#variables.fid#"
					id="#variables.fid#"
					method="post"
					action="/vocabularies/ctmedia_license.cfm">
					<input type="hidden" name="action" value="">
					<input type="hidden" name="media_license_id" value="#media_license_id#">
					<div class="d-table-cell p-2 align-middle">
						<label class="sr-only" for="#variables.fid#_display">Display Name</label>
						<input type="text" class="form-control form-control-sm" id="#variables.fid#_display" name="display" value="#encodeForHTML(display)#" required>
					</div>
					<div class="d-table-cell p-2 align-middle">
						<label class="sr-only" for="#variables.fid#_uri">URI</label>
						<input type="text" class="form-control form-control-sm" id="#variables.fid#_uri" name="uri" value="#encodeForHTML(uri)#">
					</div>
					<div class="d-table-cell p-2 align-middle">
						<label class="sr-only" for="#variables.fid#_description">Description</label>
						<textarea class="form-control form-control-sm" id="#variables.fid#_description" name="description" rows="2">#encodeForHTML(description)#</textarea>
					</div>
					<div class="d-table-cell p-2 align-middle text-nowrap">
						<button type="submit" class="btn btn-xs btn-primary mr-1"
							onclick="document.getElementById('#variables.fid#').elements['action'].value='save';">Save</button>
						<button type="submit" class="btn btn-xs btn-danger"
							onclick="document.getElementById('#variables.fid#').elements['action'].value='delete'; return confirm('Delete this license?');">Delete</button>
					</div>
				</form>
			</cfloop>
		</div>
	</section>
</main>
</cfoutput>
<cfinclude template="/shared/_footer.cfm">
