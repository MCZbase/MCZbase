<!---
/Admin/Collection.cfm

Display and manage collection metadata, contacts, and portal appearance settings.

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
<cfset pageTitle = "Manage Collections">
<cfinclude template="/shared/_header.cfm">

<cfset variables.allowedActions = "entryPoint,findColl,updateContact,deleteContact,changeAppearance,newContact,modifyCollection">
<cfset variables.actionsRequiringCollectionId = "findColl,updateContact,deleteContact,changeAppearance,newContact,modifyCollection">
<cfset variables.findCollectionBaseUrl = "/Admin/Collection.cfm?action=findColl&collection_id=">

<cfset variables.action = "entryPoint">
<cfif isDefined("form.action") AND len(trim(form.action)) GT 0>
	<cfset variables.action = trim(form.action)>
<cfelseif isDefined("url.action") AND len(trim(url.action)) GT 0>
	<cfset variables.action = trim(url.action)>
</cfif>
<cfif NOT listFindNoCase(variables.allowedActions, variables.action)>
	<cfset variables.action = "entryPoint">
</cfif>

<cfset variables.collection_id = "">
<cfif isDefined("form.collection_id") AND len(trim(form.collection_id)) GT 0>
	<cfset variables.collection_id = trim(form.collection_id)>
<cfelseif isDefined("url.collection_id") AND len(trim(url.collection_id)) GT 0>
	<cfset variables.collection_id = trim(url.collection_id)>
</cfif>

<cfset variables.hasValidCollectionId = len(variables.collection_id) GT 0 AND isValid("integer", variables.collection_id)>

<cfif listFindNoCase(variables.actionsRequiringCollectionId, variables.action) AND NOT variables.hasValidCollectionId>
	<cfset variables.action = "entryPoint">
	<cfset variables.collection_id = "">
	<cfset variables.hasValidCollectionId = false>
</cfif>

<!--- Handle form submissions for collection contact management, portal appearance settings, and collection metadata updates --->
<cfswitch expression="#variables.action#">
	<cfcase value="newContact">
		<!--- insert a new collection_contacts record --->
		<cfparam name="form.contact_role" default="">
		<cfparam name="form.contact_agent_id" default="">
		<cftransaction>
			<cfquery name="newContact" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				INSERT INTO collection_contacts (
					collection_contact_id,
					collection_id,
					contact_role,
					contact_agent_id
				) VALUES (
					sq_collection_contact_id.nextval,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#form.collection_id#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.contact_role#">,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#form.contact_agent_id#">
				)
			</cfquery>
		</cftransaction>
		<cflocation url="#variables.findCollectionBaseUrl##encodeForUrl(form.collection_id)#" addtoken="false">
	</cfcase>
	<cfcase value="updateContact">
		<!--- update an existing collection_contacts record --->
		<cfparam name="form.contact_role" default="">
		<cfparam name="form.contact_agent_id" default="">
		<cfparam name="form.collection_contact_id" default="">
		<cfquery name="changeContact" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			UPDATE collection_contacts
			SET
				contact_role = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.contact_role#">,
				contact_agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#form.contact_agent_id#">
			WHERE
				collection_contact_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#form.collection_contact_id#">
		</cfquery>
		<cflocation url="#variables.findCollectionBaseUrl##encodeForUrl(form.collection_id)#" addtoken="false">
	</cfcase>
	<cfcase value="deleteContact">
		<!--- delete a collection_contacts record --->
		<cfparam name="form.collection_contact_id" default="">
		<cfquery name="killContact" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			DELETE FROM collection_contacts
			WHERE
				collection_contact_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#form.collection_contact_id#">
		</cfquery>
		<cflocation url="#variables.findCollectionBaseUrl##encodeForUrl(form.collection_id)#" addtoken="false">
	</cfcase>
	<cfcase value="changeAppearance">
		<!--- update the appearance related fields of the cf_collection record for this collection --->
		<cfparam name="form.HEADER_COLOR" default="">
		<cfparam name="form.HEADER_IMAGE" default="">
		<cfparam name="form.COLLECTION_URL" default="">
		<cfparam name="form.COLLECTION_LINK_TEXT" default="">
		<cfparam name="form.INSTITUTION_URL" default="">
		<cfparam name="form.INSTITUTION_LINK_TEXT" default="">
		<cfparam name="form.META_DESCRIPTION" default="">
		<cfparam name="form.META_KEYWORDS" default="">
		<cfparam name="form.STYLESHEET" default="">
		<cfparam name="form.HEADER_CREDIT" default="">
		<cfquery name="insApp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			UPDATE cf_collection
			SET
				HEADER_COLOR = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.HEADER_COLOR#">,
				HEADER_IMAGE = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.HEADER_IMAGE#">,
				COLLECTION_URL = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.COLLECTION_URL#">,
				COLLECTION_LINK_TEXT = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.COLLECTION_LINK_TEXT#">,
				INSTITUTION_URL = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.INSTITUTION_URL#">,
				INSTITUTION_LINK_TEXT = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.INSTITUTION_LINK_TEXT#">,
				META_DESCRIPTION = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.META_DESCRIPTION#">,
				META_KEYWORDS = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.META_KEYWORDS#">,
				STYLESHEET = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.STYLESHEET#">,
				HEADER_CREDIT = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.HEADER_CREDIT#">
			WHERE
				collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#form.collection_id#">
		</cfquery>
		<cflocation url="#variables.findCollectionBaseUrl##encodeForUrl(form.collection_id)#" addtoken="false">
	</cfcase>
	<cfcase value="modifyCollection">
		<!--- update the core metadata in the collection record for this collection --->
		<cfparam name="form.collection_cde" default="">
		<cfparam name="form.guid_prefix" default="">
		<cfparam name="form.collection" default="">
		<cfparam name="form.institution_acronym" default="">
		<cfparam name="form.descr" default="">
		<cfparam name="form.web_link" default="">
		<cfparam name="form.web_link_text" default="">
		<cfparam name="form.loan_policy_url" default="">
		<cfparam name="form.allow_prefix_suffix" default="0">
		<cftransaction>
			<cfquery name="modColl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE collection
				SET
					COLLECTION_CDE = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.collection_cde#">,
					guid_prefix = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.guid_prefix#">,
					COLLECTION = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.collection#">,
					INSTITUTION_ACRONYM = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.institution_acronym#">,
					DESCR = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.descr#">,
					web_link = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.web_link#">,
					web_link_text = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.web_link_text#">,
					loan_policy_url = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.loan_policy_url#">,
					allow_prefix_suffix = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#form.allow_prefix_suffix#">
				WHERE
					COLLECTION_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#form.collection_id#">
			</cfquery>
		</cftransaction>
		<cflocation url="#variables.findCollectionBaseUrl##encodeForUrl(form.collection_id)#" addtoken="false">
	</cfcase>
</cfswitch>

<cfif variables.action EQ "findColl" AND variables.hasValidCollectionId>
	<!--- retrieve collection metadata for the specified collection --->
	<cfquery name="colls" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		SELECT
			COLLECTION_CDE,
			INSTITUTION_ACRONYM,
			DESCR,
			COLLECTION,
			COLLECTION_ID,
			WEB_LINK,
			WEB_LINK_TEXT,
			loan_policy_url,
			guid_prefix,
			allow_prefix_suffix
		FROM collection
		WHERE
			collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.collection_id#">
	</cfquery>
	<cfif colls.recordCount EQ 1>
		<cfset pageTitle = "Manage Collection: #colls.collection#">
		<cfquery name="app" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			SELECT *
			FROM cf_collection
			WHERE
				collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.collection_id#">
		</cfquery>
		<cfquery name="ctCollCde" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			SELECT collection_cde
			FROM ctcollection_cde
		</cfquery>
		<cfquery name="contact" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			SELECT
				collection_contact_id,
				contact_role,
				contact_agent_id,
				agent_name AS contact_name
			FROM
				collection_contacts
				JOIN preferred_agent_name
					ON contact_agent_id = agent_id
			WHERE
				collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.collection_id#">
			ORDER BY
				contact_name,
				contact_role
		</cfquery>
		<cfquery name="ctContactRole" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			SELECT contact_role
			FROM ctcoll_contact_role
		</cfquery>
		<cfdirectory action="list" directory="#Application.webDirectory#/includes/css" name="sheets" filter="*.css">
	<cfelse>
		<cfset variables.action = "entryPoint">
		<cfset variables.collection_id = "">
	</cfif>
</cfif>

<cfquery name="ctcoll" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	SELECT
		collection_id,
		collection
	FROM collection
	ORDER BY collection
</cfquery>

<!--- Display collection selection form if no valid collection_id provided, otherwise display collection details, contacts, and portal appearance settings --->
<main class="container py-3" id="content">
	<section class="row my-2">
		<div class="col-12">
			<div class="border rounded bg-light p-3">
				<cfoutput>
					<div class="d-flex flex-column flex-md-row justify-content-between align-items-md-end">
						<div>
							<h1 class="h2 mb-2">Manage Collections</h1>
							<p class="mb-3 mb-md-0">Select a collection to review collection metadata, contacts, and portal appearance settings.</p>
						</div>
						<cfif variables.action EQ "findColl">
							<a class="btn btn-xs btn-secondary mt-2 mt-md-0" href="/Admin/Collection.cfm">Choose Another Collection</a>
						</cfif>
					</div>
					<form name="coll" method="post" action="/Admin/Collection.cfm" class="mt-3">
						<input type="hidden" name="action" value="findColl">
						<div class="form-row align-items-end">
							<div class="col-12 col-md-8 col-lg-6">
								<label for="collection_id" class="data-entry-label">Collection</label>
								<select name="collection_id" id="collection_id" size="1" class="data-entry-select reqdClr" required>
									<option value=""></option>
									<cfloop query="ctcoll">
										<option value="#encodeForHtmlAttribute(ctcoll.collection_id)#"<cfif variables.collection_id EQ ctcoll.collection_id> selected="selected"</cfif>>#encodeForHtml(ctcoll.collection)#</option>
									</cfloop>
								</select>
							</div>
							<div class="col-12 col-md-auto mt-3 mt-md-0">
								<input type="submit" value="Open Collection" class="btn btn-primary btn-xs">
							</div>
						</div>
					</form>
				</cfoutput>
			</div>
		</div>
	</section>

	<cfif variables.action EQ "findColl">
		<cfset variables.HEADER_COLOR = "">
		<cfset variables.HEADER_IMAGE = "">
		<cfset variables.HEADER_CREDIT = "">
		<cfset variables.COLLECTION_URL = "">
		<cfset variables.COLLECTION_LINK_TEXT = "">
		<cfset variables.INSTITUTION_URL = "">
		<cfset variables.INSTITUTION_LINK_TEXT = "">
		<cfset variables.META_DESCRIPTION = "">
		<cfset variables.META_KEYWORDS = "">
		<cfset variables.STYLESHEET = "">
		<cfif app.recordCount GT 0>
			<cfset variables.HEADER_COLOR = app.HEADER_COLOR>
			<cfset variables.HEADER_IMAGE = app.HEADER_IMAGE>
			<cfset variables.HEADER_CREDIT = app.HEADER_CREDIT>
			<cfset variables.COLLECTION_URL = app.COLLECTION_URL>
			<cfset variables.COLLECTION_LINK_TEXT = app.COLLECTION_LINK_TEXT>
			<cfset variables.INSTITUTION_URL = app.INSTITUTION_URL>
			<cfset variables.INSTITUTION_LINK_TEXT = app.INSTITUTION_LINK_TEXT>
			<cfset variables.META_DESCRIPTION = app.META_DESCRIPTION>
			<cfset variables.META_KEYWORDS = app.META_KEYWORDS>
			<cfset variables.STYLESHEET = app.STYLESHEET>
		</cfif>

		<cfoutput>
			<section class="row my-2">
				<div class="col-12">
					<div class="border rounded p-3 h-100">
						<h2 class="h3 mb-3">Collection Details</h2>
						<form name="editCollection" method="post" action="/Admin/Collection.cfm">
							<input type="hidden" name="action" value="modifyCollection">
							<input type="hidden" name="collection_id" value="#encodeForHtmlAttribute(colls.collection_id)#">
							<div class="form-row">
								<div class="col-12 col-md-4 col-lg-3">
									<label for="collection_cde" class="data-entry-label">Collection Type</label>
									<select name="collection_cde" id="collection_cde" size="1" class="data-entry-select reqdClr">
										<cfloop query="ctCollCde">
											<option value="#encodeForHtmlAttribute(ctCollCde.collection_cde)#"<cfif ctCollCde.collection_cde EQ colls.collection_cde> selected="selected"</cfif>>#encodeForHtml(ctCollCde.collection_cde)#</option>
										</cfloop>
									</select>
								</div>
								<div class="col-12 col-md-4 col-lg-3">
									<label for="institution_acronym" class="data-entry-label">Institution Acronym</label>
									<input type="text" name="institution_acronym" id="institution_acronym" value="#encodeForHtmlAttribute(colls.institution_acronym)#" class="data-entry-input reqdClr">
								</div>
								<div class="col-12 col-md-4 col-lg-6">
									<label for="collection" class="data-entry-label">Collection</label>
									<input type="text" name="collection" id="collection" value="#encodeForHtmlAttribute(colls.collection)#" class="data-entry-input reqdClr">
								</div>
							</div>
							<div class="form-row">
								<div class="col-12 col-md-6 col-lg-4">
									<label for="guid_prefix" class="data-entry-label">GUID Prefix</label>
									<input type="text" name="guid_prefix" id="guid_prefix" value="#encodeForHtmlAttribute(colls.guid_prefix)#" class="data-entry-input">
								</div>
								<div class="col-12 col-md-6 col-lg-4">
									<label for="allow_prefix_suffix" class="data-entry-label">Allow catnum prefix/suffix?</label>
									<select name="allow_prefix_suffix" id="allow_prefix_suffix" class="data-entry-select">
										<option value="0"<cfif colls.allow_prefix_suffix EQ 0> selected="selected"</cfif>>No</option>
										<option value="1"<cfif colls.allow_prefix_suffix EQ 1> selected="selected"</cfif>>Yes</option>
									</select>
								</div>
								<div class="col-12 col-lg-4">
									<label for="loan_policy_url" class="data-entry-label">Loan Policy URL</label>
									<input type="text" name="loan_policy_url" id="loan_policy_url" value="#encodeForHtmlAttribute(colls.loan_policy_url)#" class="data-entry-input">
								</div>
							</div>
							<div class="form-row">
								<div class="col-12">
									<label for="descr" class="data-entry-label">Description</label>
									<input type="text" name="descr" id="descr" value="#encodeForHtmlAttribute(colls.descr)#" class="data-entry-input">
								</div>
							</div>
							<div class="form-row">
								<div class="col-12 col-lg-6">
									<label for="web_link" class="data-entry-label">Web Link</label>
									<input type="text" name="web_link" id="web_link" value="#encodeForHtmlAttribute(colls.web_link)#" class="data-entry-input">
								</div>
								<div class="col-12 col-lg-6">
									<label for="web_link_text" class="data-entry-label">Link Text</label>
									<input type="text" name="web_link_text" id="web_link_text" value="#encodeForHtmlAttribute(colls.web_link_text)#" class="data-entry-input">
								</div>
							</div>
							<div class="form-row mt-3">
								<div class="col-12">
									<input type="submit" value="Save Collection Details" class="btn btn-primary btn-xs">
									<a class="btn btn-xs btn-secondary" href="/Admin/Collection.cfm">Done</a>
								</div>
							</div>
						</form>
					</div>
				</div>
			</section>

			<section class="row my-2">
				<div class="col-12 col-xl-8">
					<div class="border rounded p-3 h-100">
						<h2 class="h3 mb-3">Collection Contacts</h2>
						<cfif contact.recordCount EQ 0>
							<p class="text-muted mb-0">No contacts are currently configured for this collection.</p>
						<cfelse>
							<cfloop query="contact">
								<form name="contact#contact.currentRow#" id="contact#contact.currentRow#" method="post" action="/Admin/Collection.cfm" class="border rounded bg-light p-3 mb-3">
									<input type="hidden" name="action" id="action_contact_#contact.currentRow#" value="updateContact">
									<input type="hidden" name="collection_id" value="#encodeForHtmlAttribute(colls.collection_id)#">
									<input type="hidden" name="collection_contact_id" value="#encodeForHtmlAttribute(contact.collection_contact_id)#">
									<input type="hidden" name="contact_agent_id" id="contact_agent_id_#contact.currentRow#" value="#encodeForHtmlAttribute(contact.contact_agent_id)#">
									<div class="form-row align-items-end">
										<div class="col-12 col-lg-5">
											<label for="contact_#contact.currentRow#" class="data-entry-label mb-0">Contact Name
												<span id="contact_view_#contact.currentRow#" class="d-inline">&nbsp;&nbsp;&nbsp;&nbsp;</span>
											</label>
											<div class="input-group">
												<div class="input-group-prepend">
													<span class="input-group-text smaller bg-light" id="contact_name_icon_#contact.currentRow#"><i class="fa fa-user" aria-hidden="true"></i></span>
												</div>
												<input type="text" name="contact" id="contact_#contact.currentRow#" class="data-entry-input reqdClr form-control rounded-right" aria-label="Contact Name" value="#encodeForHtmlAttribute(contact.contact_name)#" onKeyPress="return noenter(event);">
											</div>
										</div>
										<div class="col-12 col-lg-4">
											<label for="contact_role_#contact.currentRow#" class="data-entry-label">Contact Role</label>
											<select name="contact_role" id="contact_role_#contact.currentRow#" size="1" class="data-entry-select reqdClr">
												<cfloop query="ctContactRole">
													<option value="#encodeForHtmlAttribute(ctContactRole.contact_role)#"<cfif ctContactRole.contact_role EQ contact.contact_role> selected="selected"</cfif>>#encodeForHtml(ctContactRole.contact_role)#</option>
												</cfloop>
											</select>
										</div>
										<div class="col-12 col-lg-3 mt-3 mt-lg-0">
											<div class="d-flex flex-wrap">
												<input type="submit" value="Save" class="btn btn-primary btn-xs mr-2 mb-2">
												<input type="button" value="Delete" class="btn btn-xs btn-danger mb-2" onclick="if (confirm('Delete this collection contact?')) { document.getElementById('action_contact_#contact.currentRow#').value='deleteContact'; document.getElementById('contact#contact.currentRow#').submit(); }">
											</div>
										</div>
									</div>
								</form>
							</cfloop>
						</cfif>
					</div>
				</div>
				<div class="col-12 col-xl-4 mt-3 mt-xl-0">
					<div class="border rounded bg-light p-3 h-100">
						<h2 class="h3 mb-3">Add Contact</h2>
						<form name="newContact" id="newContact" method="post" action="/Admin/Collection.cfm" class="mb-0">
							<input type="hidden" name="action" value="newContact">
							<input type="hidden" name="collection_id" value="#encodeForHtmlAttribute(colls.collection_id)#">
							<input type="hidden" name="contact_agent_id" id="new_contact_agent_id">
							<p class="small text-muted mb-3">Add a role assignment for a new collection contact.</p>
							<div class="form-row">
								<div class="col-12">
									<label for="new_contact" class="data-entry-label mb-0">Contact Name
										<span id="new_contact_view" class="d-inline">&nbsp;&nbsp;&nbsp;&nbsp;</span>
									</label>
									<div class="input-group">
										<div class="input-group-prepend">
											<span class="input-group-text smaller bg-light" id="new_contact_name_icon"><i class="fa fa-user" aria-hidden="true"></i></span>
										</div>
										<input type="text" name="contact" id="new_contact" class="data-entry-input reqdClr form-control rounded-right" aria-label="Contact Name" onKeyPress="return noenter(event);">
									</div>
								</div>
							</div>
							<div class="form-row">
								<div class="col-12">
									<label for="new_contact_role" class="data-entry-label">Contact Role</label>
									<select name="contact_role" id="new_contact_role" size="1" class="data-entry-select reqdClr">
										<cfloop query="ctContactRole">
											<option value="#encodeForHtmlAttribute(ctContactRole.contact_role)#">#encodeForHtml(ctContactRole.contact_role)#</option>
										</cfloop>
									</select>
								</div>
							</div>
							<div class="form-row mt-3">
								<div class="col-12">
									<input type="submit" value="Add Contact" class="btn btn-primary btn-xs">
								</div>
							</div>
						</form>
					</div>
				</div>
			</section>
			<script>
				<cfif contact.recordCount GT 0>
					<cfloop query="contact">
						const agentId#contact.currentRow# = Number.parseInt(document.getElementById('contact_agent_id_#contact.currentRow#').value, 10);
						makeRichAgentPicker(
							'contact_#contact.currentRow#',
							'contact_agent_id_#contact.currentRow#',
							'contact_name_icon_#contact.currentRow#',
							'contact_view_#contact.currentRow#',
							Number.isNaN(agentId#contact.currentRow#) ? null : agentId#contact.currentRow#
						);
					</cfloop>
				</cfif>
				makeRichAgentPicker('new_contact', 'new_contact_agent_id', 'new_contact_name_icon', 'new_contact_view', null);
			</script>

			<section class="row my-2">
				<div class="col-12">
					<div class="border rounded p-3 h-100">
						<h2 class="h3 mb-2">Collection Specific Appearance</h2>
						<p class="small text-muted">These settings should not normally be changed.  You will need DBA help to set this up properly for new collections. Settings may be ignored if the related portal configuration is incomplete.</p>
						<form name="appearance" method="post" action="/Admin/Collection.cfm">
							<input type="hidden" name="action" value="changeAppearance">
							<input type="hidden" name="collection_id" value="#encodeForHtmlAttribute(colls.collection_id)#">
							<div class="form-row">
								<div class="col-12 col-md-6 col-lg-3">
									<label for="HEADER_COLOR" class="data-entry-label">Header Color</label>
									<input type="text" name="HEADER_COLOR" id="HEADER_COLOR" class="data-entry-input reqdClr" value="#encodeForHtmlAttribute(variables.HEADER_COLOR)#">
									<p class="small mb-0"><a href="https://www.google.com/search?q=html+color+picker" target="_blank" rel="noopener noreferrer">Find a color value</a></p>
								</div>
								<div class="col-12 col-md-6 col-lg-3">
									<label for="HEADER_IMAGE" class="data-entry-label">Header Image</label>
									<input type="text" name="HEADER_IMAGE" id="HEADER_IMAGE" class="data-entry-input reqdClr" value="#encodeForHtmlAttribute(variables.HEADER_IMAGE)#">
									<p class="small mb-0"><a href="/tools/listImages.cfm" target="_blank" rel="noopener noreferrer">Browse available images</a></p>
								</div>
								<div class="col-12 col-md-6 col-lg-3">
									<label for="HEADER_CREDIT" class="data-entry-label">Header Credit</label>
									<input type="text" name="HEADER_CREDIT" id="HEADER_CREDIT" class="data-entry-input reqdClr" value="#encodeForHtmlAttribute(variables.HEADER_CREDIT)#">
								</div>
								<div class="col-12 col-md-6 col-lg-3">
									<label for="STYLESHEET" class="data-entry-label">Stylesheet</label>
									<select name="STYLESHEET" id="STYLESHEET" size="1" class="data-entry-select">
										<option value=" "<cfif len(trim(variables.STYLESHEET)) EQ 0> selected="selected"</cfif>>none</option>
										<cfloop query="sheets">
											<option value="#encodeForHtmlAttribute(sheets.name)#"<cfif sheets.name EQ variables.STYLESHEET> selected="selected"</cfif>>#encodeForHtml(sheets.name)#</option>
										</cfloop>
									</select>
								</div>
							</div>
							<div class="form-row">
								<div class="col-12 col-md-6 col-lg-3">
									<label for="COLLECTION_URL" class="data-entry-label">Collection URL</label>
									<input type="text" name="COLLECTION_URL" id="COLLECTION_URL" class="data-entry-input reqdClr" value="#encodeForHtmlAttribute(variables.COLLECTION_URL)#">
								</div>
								<div class="col-12 col-md-6 col-lg-3">
									<label for="COLLECTION_LINK_TEXT" class="data-entry-label">Collection Link Text</label>
									<input type="text" name="COLLECTION_LINK_TEXT" id="COLLECTION_LINK_TEXT" class="data-entry-input reqdClr" value="#encodeForHtmlAttribute(variables.COLLECTION_LINK_TEXT)#">
								</div>
								<div class="col-12 col-md-6 col-lg-3">
									<label for="INSTITUTION_URL" class="data-entry-label">Institution URL</label>
									<input type="text" name="INSTITUTION_URL" id="INSTITUTION_URL" class="data-entry-input reqdClr" value="#encodeForHtmlAttribute(variables.INSTITUTION_URL)#">
								</div>
								<div class="col-12 col-md-6 col-lg-3">
									<label for="INSTITUTION_LINK_TEXT" class="data-entry-label">Institution Link Text</label>
									<input type="text" name="INSTITUTION_LINK_TEXT" id="INSTITUTION_LINK_TEXT" class="data-entry-input reqdClr" value="#encodeForHtmlAttribute(variables.INSTITUTION_LINK_TEXT)#">
								</div>
							</div>
							<div class="form-row">
								<div class="col-12 col-lg-6">
									<label for="META_DESCRIPTION" class="data-entry-label">Meta Description</label>
									<input type="text" name="META_DESCRIPTION" id="META_DESCRIPTION" class="data-entry-input reqdClr" value="#encodeForHtmlAttribute(variables.META_DESCRIPTION)#">
								</div>
								<div class="col-12 col-lg-6">
									<label for="META_KEYWORDS" class="data-entry-label">Meta Keywords</label>
									<input type="text" name="META_KEYWORDS" id="META_KEYWORDS" class="data-entry-input reqdClr" value="#encodeForHtmlAttribute(variables.META_KEYWORDS)#">
								</div>
							</div>
							<div class="form-row mt-3">
								<div class="col-12">
									<input type="submit" value="Save Portal Settings" class="btn btn-primary btn-xs">
								</div>
							</div>
						</form>
					</div>
				</div>
			</section>
		</cfoutput>
	</cfif>
</main>

<cfinclude template="/shared/_footer.cfm">
