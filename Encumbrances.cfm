<!---
Encumbrances.cfm

Search, create, edit, and delete encumbrances. Provides a search form for
locating encumbrances, forms to create and edit encumbrance records, and
management of cataloged items within encumbrances.

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

TODO: The data-changing actions (createEncumbrance, updateEncumbrance2,
deleteEncumbrance, saveEncumbrances, remListedItems) should be moved to
backing cffunction methods in encumbrance/component/functions.cfc.

TODO: The cataloged items section shown when collection_object_id is provided
has been partially moved to a manage page but is not yet fully disentangled
from this file.
--->

<!--- URL parameter declarations: expose all supported parameters from url scope. --->
<cfparam name="url.action" default="">
<cfparam name="url.encumbrance_id" default="">
<cfparam name="url.collection_object_id" default="">
<cfparam name="url.execute" default="">
<cfparam name="url.encumberingAgent" default="">
<cfparam name="url.made_date_after" default="">
<cfparam name="url.made_date_before" default="">
<cfparam name="url.expiration_date_after" default="">
<cfparam name="url.expiration_date_before" default="">
<cfparam name="url.expiration_event" default="">
<cfparam name="url.encumbrance" default="">
<cfparam name="url.encumbrance_action" default="">
<cfparam name="url.remarks" default="">

<!--- Resolve action: form scope (POST) takes priority over url scope (GET).
     No case normalisation is applied; an exact-case match against the
     whitelist is enforced below. --->
<cfif isDefined("form.action") AND len(trim(form.action)) GT 0>
	<cfset variables.action = trim(form.action)>
<cfelseif len(trim(url.action)) GT 0>
	<cfset variables.action = trim(url.action)>
<cfelse>
	<cfset variables.action = "entryPoint">
</cfif>

<!--- Require an exact-case match against the known action whitelist.
     listFind() is case-sensitive; any unrecognised or wrong-case value
     silently falls back to entryPoint. --->
<cfset variables.knownActions = "entryPoint,create,createEncumbrance,listEncumbrances,remListedItems,updateEncumbrance,updateEncumbrance2,deleteEncumbrance,saveEncumbrances">
<cfif NOT listFind(variables.knownActions, variables.action)>
	<cfset variables.action = "entryPoint">
</cfif>

<!--- Resolve collection_object_id: form (POST) takes priority over url (GET). --->
<cfif isDefined("form.collection_object_id") AND len(trim(form.collection_object_id)) GT 0>
	<cfset variables.collection_object_id = trim(form.collection_object_id)>
<cfelseif len(trim(url.collection_object_id)) GT 0>
	<cfset variables.collection_object_id = trim(url.collection_object_id)>
<cfelse>
	<cfset variables.collection_object_id = "">
</cfif>

<!--- Pre-compute context-aware URLs for reuse in links throughout the page. --->
<cfif len(variables.collection_object_id) GT 0>
	<cfset variables.createEncUrl = "/Encumbrances.cfm?action=create&collection_object_id=" & URLEncodedFormat(variables.collection_object_id)>
	<cfset variables.backToSearchUrl = "/Encumbrances.cfm?action=entryPoint&collection_object_id=" & URLEncodedFormat(variables.collection_object_id)>
<cfelse>
	<cfset variables.createEncUrl = "/Encumbrances.cfm?action=create">
	<cfset variables.backToSearchUrl = "/Encumbrances.cfm">
</cfif>

<!--- Resolve encumbrance_id: form (POST) takes priority over url (GET). --->
<cfif isDefined("form.encumbrance_id") AND len(trim(form.encumbrance_id)) GT 0>
	<cfset variables.encumbrance_id = trim(form.encumbrance_id)>
<cfelseif len(trim(url.encumbrance_id)) GT 0>
	<cfset variables.encumbrance_id = trim(url.encumbrance_id)>
<cfelse>
	<cfset variables.encumbrance_id = "">
</cfif>

<!--- Resolve search and form fields: form (POST) takes priority over url (GET).
     The encumbrance name field is stored as encumbranceName to prevent collisions
     with the encumbrance column name returned in query result sets. --->
<cfif isDefined("form.encumberingAgent")>
	<cfset variables.encumberingAgent = trim(form.encumberingAgent)>
<cfelse>
	<cfset variables.encumberingAgent = trim(url.encumberingAgent)>
</cfif>
<cfif isDefined("form.made_date_after")>
	<cfset variables.made_date_after = trim(form.made_date_after)>
<cfelse>
	<cfset variables.made_date_after = trim(url.made_date_after)>
</cfif>
<cfif isDefined("form.made_date_before")>
	<cfset variables.made_date_before = trim(form.made_date_before)>
<cfelse>
	<cfset variables.made_date_before = trim(url.made_date_before)>
</cfif>
<cfif isDefined("form.expiration_date_after")>
	<cfset variables.expiration_date_after = trim(form.expiration_date_after)>
<cfelse>
	<cfset variables.expiration_date_after = trim(url.expiration_date_after)>
</cfif>
<cfif isDefined("form.expiration_date_before")>
	<cfset variables.expiration_date_before = trim(form.expiration_date_before)>
<cfelse>
	<cfset variables.expiration_date_before = trim(url.expiration_date_before)>
</cfif>
<cfif isDefined("form.expiration_event")>
	<cfset variables.expiration_event = trim(form.expiration_event)>
<cfelse>
	<cfset variables.expiration_event = trim(url.expiration_event)>
</cfif>
<cfif isDefined("form.encumbrance")>
	<cfset variables.encumbranceName = trim(form.encumbrance)>
<cfelse>
	<cfset variables.encumbranceName = trim(url.encumbrance)>
</cfif>
<cfif isDefined("form.encumbrance_action")>
	<cfset variables.encumbrance_action = trim(form.encumbrance_action)>
<cfelse>
	<cfset variables.encumbrance_action = trim(url.encumbrance_action)>
</cfif>
<cfif isDefined("form.remarks")>
	<cfset variables.remarks = trim(form.remarks)>
<cfelse>
	<cfset variables.remarks = trim(url.remarks)>
</cfif>

<!--- Resolve create/edit-only fields that arrive via POST only. --->
<cfif isDefined("form.encumberingAgentId") AND len(trim(form.encumberingAgentId)) GT 0>
	<cfset variables.encumberingAgentId = trim(form.encumberingAgentId)>
<cfelse>
	<cfset variables.encumberingAgentId = "">
</cfif>
<cfif isDefined("form.made_date") AND len(trim(form.made_date)) GT 0>
	<cfset variables.made_date = trim(form.made_date)>
<cfelse>
	<cfset variables.made_date = "">
</cfif>
<cfif isDefined("form.expiration_date") AND len(trim(form.expiration_date)) GT 0>
	<cfset variables.expiration_date = trim(form.expiration_date)>
<cfelse>
	<cfset variables.expiration_date = "">
</cfif>

<!--- Set page title before the header include. --->
<cfswitch expression="#variables.action#">
	<cfcase value="create">
		<cfset pageTitle = "Create Encumbrance">
	</cfcase>
	<cfcase value="updateEncumbrance">
		<cfset pageTitle = "Edit Encumbrance">
	</cfcase>
	<cfcase value="listEncumbrances">
		<cfset pageTitle = "Encumbrance Search Results">
	</cfcase>
	<cfdefaultcase>
		<cfset pageTitle = "Find Encumbrances">
	</cfdefaultcase>
</cfswitch>

<cfinclude template="/shared/_header.cfm">

<!--- Load the encumbrance action controlled vocabulary for use in all forms on this page. --->
<cfquery name="getCtEncumbranceAction" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	SELECT ctecumbrance_action.encumbrance_action, count(encumbrance.encumbrance_id) ct
	FROM ctencumbrance_action
		left join encumbrance on ctencumbrance_action.encumbrance_action
	GROUP BY ctencumbrance_action.encumbrance_action
	ORDER BY ctencumbrance_action.encumbrance_action
</cfquery>

<!--- Use fluid layout for search and results pages; contained layout for forms. --->
<cfif variables.action EQ "entryPoint" OR variables.action EQ "listEncumbrances">
	<cfset variables.mainClass = "container-fluid">
<cfelse>
	<cfset variables.mainClass = "container py-3">
</cfif>

<cfoutput>
<main class="#variables.mainClass#" id="content">
	<cfswitch expression="#variables.action#">

		<!--- ================================================================
		     entryPoint: encumbrance search form
		     ================================================================ --->
		<cfcase value="entryPoint">
			<section role="search">
				<div class="row mx-0 mb-2">
					<div class="search-box col-12 px-0">
						<div class="search-box-header">
							<h1 class="h3 text-white" tabindex="0">Find Encumbrances</h1>
						</div>
						<div class="col-12 px-3 py-3">
							<cfif len(variables.collection_object_id) GT 0>
								<p class="mb-2">
									Now find an encumbrance to apply to the specimens below.
									If you need a new encumbrance,
									<a href="/Encumbrances.cfm?action=create&collection_object_id=#URLEncodedFormat(variables.collection_object_id)#">create it first</a>
									then come back here.
								</p>
							</cfif>
							<form id="encumbranceSearchForm" name="encumbranceSearch"
								method="get" action="/Encumbrances.cfm">
								<input type="hidden" name="action" value="listEncumbrances">
								<input type="hidden" name="collection_object_id"
									value="#encodeForHTML(variables.collection_object_id)#">
								<div class="form-row">
									<div class="col-12 col-md-6 col-xl-3 mb-2">
										<label for="encumberingAgent" class="data-entry-label">Encumbering Agent</label>
										<input type="text" name="encumberingAgent" id="encumberingAgent" value="#encodeForHTML(variables.encumberingAgent)#" class="data-entry-input col-12">
									</div>
									<div class="col-12 col-md-6 col-xl-3 mb-2">
										<label for="encumbrance" class="data-entry-label">Encumbrance Name</label>
										<input type="text" name="encumbrance" id="encumbrance" value="#encodeForHTML(variables.encumbranceName)#" class="data-entry-input col-12">
									</div>
									<div class="col-12 col-md-6 col-xl-3 mb-2">
										<label for="encumbrance_action" class="data-entry-label">Encumbrance Action</label>
										<select name="encumbrance_action" id="encumbrance_action" class="data-entry-select col-12">
											<option value=""></option>
											<cfloop query="getCtEncumbranceAction">
												<cfif variables.encumbrance_action EQ getCtEncumbranceAction.encumbrance_action>
													<cfset variables.encActSelected = "selected">
												<cfelse>
													<cfset variables.encActSelected = "">
												</cfif>
												<option value="#encodeForHTML(getCtEncumbranceAction.encumbrance_action)#" #variables.encActSelected#>
													#encodeForHTML(getCtEncumbranceAction.encumbrance_action)# (#getEncumbranceAction.ct#)
												</option>
											</cfloop>
										</select>
									</div>
									<div class="col-12 col-md-6 col-xl-3 mb-2">
										<label for="expiration_event" class="data-entry-label">Expiration Event</label>
										<input type="text" name="expiration_event" id="expiration_event" value="#encodeForHTML(variables.expiration_event)#" class="data-entry-input col-12">
									</div>
								</div>
								<div class="form-row">
									<div class="col-12 col-md-6 col-xl-3 mb-2">
										<label for="made_date_after" class="data-entry-label">Made Date After</label>
										<input type="text" name="made_date_after" id="made_date_after" value="#encodeForHTML(variables.made_date_after)#" class="data-entry-input col-12">
									</div>
									<div class="col-12 col-md-6 col-xl-3 mb-2">
										<label for="made_date_before" class="data-entry-label">Made Date Before</label>
										<input type="text" name="made_date_before" id="made_date_before" value="#encodeForHTML(variables.made_date_before)#" class="data-entry-input col-12">
									</div>
									<div class="col-12 col-md-6 col-xl-3 mb-2">
										<label for="expiration_date_after" class="data-entry-label">Expiration Date After</label>
										<input type="text" name="expiration_date_after" id="expiration_date_after" value="#encodeForHTML(variables.expiration_date_after)#" class="data-entry-input col-12">
									</div>
									<div class="col-12 col-md-6 col-xl-3 mb-2">
										<label for="expiration_date_before" class="data-entry-label">Expiration Date Before</label>
										<input type="text" name="expiration_date_before" id="expiration_date_before" value="#encodeForHTML(variables.expiration_date_before)#" class="data-entry-input col-12">
									</div>
								</div>
								<div class="form-row">
									<div class="col-12 col-md-9 mb-2">
										<label for="remarks" class="data-entry-label">Remarks</label>
										<input type="text" name="remarks" id="remarks" value="#encodeForHTML(variables.remarks)#" class="data-entry-input col-12">
									</div>
								</div>
								<div class="form-row mt-2 mb-1">
									<div class="col-12">
										<button type="submit" class="btn btn-xs btn-primary">Search</button>
										<a href="/Encumbrances.cfm" class="btn btn-xs btn-warning ml-1">Reset</a>
										<a href="#variables.createEncUrl#" class="btn btn-xs btn-secondary ml-1">Create New Encumbrance</a>
									</div>
								</div>
							</form>
						</div>
					</div>
				</div>
			</section>
			<section class="row mx-0 mb-4">
				<div class="col-12">
					<p class="mt-3 text-muted pl-1">
						Enter search criteria above and click Search to find encumbrances.
					</p>
				</div>
			</section>
			<script>
				$(document).ready(function() {
					$('##made_date_after').datepicker();
					$('##made_date_before').datepicker();
					$('##expiration_date_after').datepicker();
					$('##expiration_date_before').datepicker();
				});
			</script>
		</cfcase>

		<!--- ================================================================
		     create: new encumbrance form
		     ================================================================ --->
		<cfcase value="create">
			<h1 class="h2 ml-3 mb-1">Create Encumbrance
				<i class="fas fa-info-circle" onClick="getMCZDocs('encumbrance','encumbrance')" aria-label="help link"></i>
			</h1>
			<section class="row mx-0 border rounded my-2 pt-2">
				<form class="col-12" name="encumberCreateForm" id="encumberCreateForm"
					method="post" action="/Encumbrances.cfm">
					<input type="hidden" name="action" value="createEncumbrance">
					<input type="hidden" name="collection_object_id" value="#encodeForHTML(variables.collection_object_id)#">
					<div class="form-row">
						<div class="col-12 col-md-6 mb-2">
							<span class="d-block">
								<label for="encumberingAgent" class="data-entry-label w-auto d-inline">Encumbering Agent</label>
								<span id="agentViewCreate" class="d-inline ml-1"></span>
							</span>
							<div class="input-group">
								<div class="input-group-prepend">
									<span class="input-group-text smaller" id="agentIconCreate">
										<i class="fa fa-user" aria-hidden="true"></i>
									</span>
								</div>
								<input type="hidden" name="encumberingAgentId" id="encumberingAgentId">
								<input type="text" name="encumberingAgent" id="encumberingAgent" required aria-required="true" class="form-control data-entry-input reqdClr" aria-describedby="agentIconCreate">
							</div>
							<script>
								$(document).ready(function() {
									makeRichAgentPicker('encumberingAgent', 'encumberingAgentId', 'agentIconCreate', 'agentViewCreate', '');
								});
							</script>
						</div>
						<div class="col-12 col-md-3 mb-2">
							<label for="made_date" class="data-entry-label">Made Date</label>
							<input type="text" name="made_date" id="made_date" required aria-required="true" class="data-entry-input col-12 reqdClr">
						</div>
					</div>
					<div class="form-row">
						<div class="col-12 col-md-3 mb-2">
							<label for="expiration_date" class="data-entry-label">Expiration Date</label>
							<input type="text" name="expiration_date" id="expiration_date" class="data-entry-input col-12">
						</div>
						<div class="col-12 col-md-3 mb-2">
							<label for="expiration_event" class="data-entry-label">Expiration Event</label>
							<input type="text" name="expiration_event" id="expiration_event" class="data-entry-input col-12">
						</div>
					</div>
					<div class="form-row">
						<div class="col-12 col-md-6 mb-2">
							<label for="encumbranceNameCreate" class="data-entry-label">Encumbrance Name</label>
							<input type="text" name="encumbrance" id="encumbranceNameCreate" required aria-required="true" class="data-entry-input col-12 reqdClr">
						</div>
						<div class="col-12 col-md-3 mb-2">
							<label for="encumbrance_action_create" class="data-entry-label">Encumbrance Action</label>
							<select name="encumbrance_action" id="encumbrance_action_create" required aria-required="true" class="data-entry-select col-12 reqdClr">
								<option value=""></option>
								<cfloop query="getCtEncumbranceAction">
									<option value="#encodeForHTML(getCtEncumbranceAction.encumbrance_action)#">
										#encodeForHTML(getCtEncumbranceAction.encumbrance_action)#
									</option>
								</cfloop>
							</select>
						</div>
					</div>
					<div class="form-row">
						<div class="col-12 col-md-9 mb-2">
							<label for="remarks" class="data-entry-label">Remarks</label>
							<textarea name="remarks" id="remarks" rows="3" class="data-entry-input col-12"></textarea>
						</div>
					</div>
					<div class="form-row mb-4 mt-1">
						<div class="col-12">
							<button type="submit" class="btn btn-xs btn-primary" onclick="return validateCreateEncumbranceForm();">Create Encumbrance</button>
							<a href="#variables.backToSearchUrl#" class="btn btn-xs btn-warning ml-1">Cancel</a>
						</div>
					</div>
				</form>
			</section>
			<script>
				$(document).ready(function() {
					$('##made_date').datepicker();
					$('##expiration_date').datepicker();
				});

				/**
				 * Validates the create encumbrance form before submission.
				 * Checks that an agent has been resolved to a database record and that
				 * expiration date and expiration event are not both specified.
				 * @return {boolean} false if validation fails, true otherwise.
				 */
				function validateCreateEncumbranceForm() {
					if ($('##encumberingAgentId').val() === "") {
						alert("Error: You must pick an Encumbering Agent from the list.");
						return false;
					}
					if ($('##expiration_date').val() !== "" && $('##expiration_event').val() !== "") {
						alert("Error: You may specify an expiration event or an expiration date, but not both.");
						return false;
					}
					return true;
				}
			</script>
		</cfcase>

		<!--- ================================================================
		     createEncumbrance: insert a new encumbrance record then redirect.
		     TODO: Move to a backing cffunction in encumbrance/component/functions.cfc.
		     ================================================================ --->
		<cfcase value="createEncumbrance">
			<cfif len(variables.encumberingAgentId) EQ 0>
				<cfthrow message="No Encumbering Agent provided. You must select an agent.">
			</cfif>
			<cfif len(variables.encumbrance_action) EQ 0>
				<cfthrow message="No Encumbrance Action provided. You must specify an action.">
			</cfif>
			<cfif len(variables.encumbranceName) EQ 0>
				<cfthrow message="No Encumbrance Name provided. You must provide a descriptive name for the encumbrance.">
			</cfif>
			<cfquery name="nextEncumbrance" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT sq_encumbrance_id.nextval AS nextEncumbrance
				FROM dual
			</cfquery>
			<cfquery name="insertEncumbrance" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				INSERT INTO encumbrance (
					ENCUMBRANCE_ID,
					ENCUMBERING_AGENT_ID,
					ENCUMBRANCE,
					ENCUMBRANCE_ACTION
					<cfif len(variables.expiration_date) GT 0>
						,EXPIRATION_DATE
					</cfif>
					<cfif len(variables.expiration_event) GT 0>
						,EXPIRATION_EVENT
					</cfif>
					<cfif len(variables.made_date) GT 0>
						,MADE_DATE
					</cfif>
					<cfif len(variables.remarks) GT 0>
						,REMARKS
					</cfif>
				) VALUES (
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#nextEncumbrance.nextEncumbrance#">,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.encumberingAgentId#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.encumbranceName#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.encumbrance_action#">
					<cfif len(variables.expiration_date) GT 0>
						,<cfqueryparam cfsqltype="CF_SQL_DATE" value="#dateformat(variables.expiration_date,'yyyy-mm-dd')#">
					</cfif>
					<cfif len(variables.expiration_event) GT 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.expiration_event#">
					</cfif>
					<cfif len(variables.made_date) GT 0>
						,<cfqueryparam cfsqltype="CF_SQL_DATE" value="#dateformat(variables.made_date,'yyyy-mm-dd')#">
					</cfif>
					<cfif len(variables.remarks) GT 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.remarks#">
					</cfif>
				)
			</cfquery>
			<cfset additional="">
			<cfif len(variables.collection_object_id) GT 0>
				<cfset additional="&collection_object_id=#URLEncodedFormat(variables.collection_object_id)#">
			</cfif>
			<cflocation url="/Encumbrances.cfm?action=listEncumbrances&encumbrance_id=#nextEncumbrance.nextEncumbrance##additional#" addtoken="false">
		</cfcase>

		<!--- ================================================================
		     listEncumbrances: display encumbrance search results
		     ================================================================ --->
		<cfcase value="listEncumbrances">
			<cfquery name="getEnc" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT
					count(coll_object_encumbrance.collection_object_id) AS object_count,
					encumbrance.encumbrance_id,
					encumbrance.encumbrance,
					encumbrance.encumbrance_action,
					preferred_agent_name.agent_name,
					encumbrance.made_date,
					encumbrance.expiration_date,
					encumbrance.expiration_event,
					encumbrance.remarks
				FROM
					encumbrance
					LEFT JOIN preferred_agent_name
						ON encumbrance.encumbering_agent_id = preferred_agent_name.agent_id
					<cfif len(variables.encumberingAgent) GT 0>
						LEFT JOIN agent_name
							ON encumbrance.encumbering_agent_id = agent_name.agent_id
					</cfif>
					LEFT JOIN coll_object_encumbrance
						ON encumbrance.encumbrance_id = coll_object_encumbrance.encumbrance_id
				WHERE
					encumbrance.encumbrance_id IS NOT NULL
				<cfif len(variables.encumberingAgent) GT 0>
					AND upper(agent_name.agent_name) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(variables.encumberingAgent)#%">
				</cfif>
				<cfif len(variables.made_date_after) GT 0>
					AND made_date >= to_date(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.made_date_after#">)
				</cfif>
				<cfif len(variables.made_date_before) GT 0>
					AND made_date <= to_date(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.made_date_before#">)
				</cfif>
				<cfif len(variables.expiration_date_after) GT 0>
					AND expiration_date >= to_date(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.expiration_date_after#">)
				</cfif>
				<cfif len(variables.expiration_date_before) GT 0>
					AND expiration_date <= to_date(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.expiration_date_before#">)
				</cfif>
				<cfif len(variables.encumbrance_id) GT 0>
					AND encumbrance.encumbrance_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.encumbrance_id#">
				</cfif>
				<cfif len(variables.encumbranceName) GT 0>
					AND upper(encumbrance.encumbrance) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(variables.encumbranceName)#%">
				</cfif>
				<cfif len(variables.encumbrance_action) GT 0>
					AND encumbrance.encumbrance_action = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.encumbrance_action#">
				</cfif>
				<cfif len(variables.expiration_event) GT 0>
					AND upper(encumbrance.expiration_event) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(variables.expiration_event)#%">
				</cfif>
				<cfif len(variables.remarks) GT 0>
					AND upper(encumbrance.remarks) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(variables.remarks)#%">
				</cfif>
				GROUP BY
					encumbrance.encumbrance_id,
					encumbrance.encumbrance,
					encumbrance.encumbrance_action,
					preferred_agent_name.agent_name,
					encumbrance.made_date,
					encumbrance.expiration_date,
					encumbrance.expiration_event,
					encumbrance.remarks
				ORDER BY
					encumbrance.encumbrance,
					preferred_agent_name.agent_name,
					encumbrance.made_date
			</cfquery>
			<section class="row mx-0 mt-2 mb-2">
				<div class="col-12">
					<h1 class="h3 mb-2">Encumbrance Search Results</h1>
					<a href="#variables.backToSearchUrl#" class="btn btn-xs btn-secondary mb-3">
						<i class="fa fa-arrow-left" aria-hidden="true"></i> Back to Search
					</a>
					<cfif getEnc.recordcount EQ 0>
						<div class="alert alert-warning" role="alert">
							No encumbrances found matching the specified criteria.
						</div>
					<cfelse>
						<p class="text-muted mb-2">
							<small>#getEnc.recordcount# encumbrance(s) found.</small>
						</p>
						<table class="table table-sm table-striped table-responsive d-xl-table">
							<thead class="thead-light">
								<tr>
									<th scope="col">##</th>
									<th scope="col">Encumbrance Name</th>
									<th scope="col">Action</th>
									<th scope="col">Encumbering Agent</th>
									<th scope="col">Made Date</th>
									<th scope="col">Expiration</th>
									<th scope="col">Remarks</th>
									<th scope="col">Items</th>
									<th scope="col">Manage</th>
								</tr>
							</thead>
							<tbody>
								<cfset variables.rowNum = 1>
								<cfloop query="getEnc">
									<tr>
										<td>#variables.rowNum#</td>
										<td>#encodeForHTML(getEnc.encumbrance)#</td>
										<td>#encodeForHTML(getEnc.encumbrance_action)#</td>
										<td>#encodeForHTML(getEnc.agent_name)#</td>
										<td>
											<cfif isDate(getEnc.made_date)>
												#dateformat(getEnc.made_date,"yyyy-mm-dd")#
											</cfif>
										</td>
										<td>
											<cfif isDate(getEnc.expiration_date)>
												#dateformat(getEnc.expiration_date,"yyyy-mm-dd")#
											</cfif>
											<cfif len(trim(getEnc.expiration_event)) GT 0>
												<span class="d-block">
													#encodeForHTML(getEnc.expiration_event)#
												</span>
											</cfif>
										</td>
										<td>
											<cfif len(trim(getEnc.remarks)) GT 0>
												<small class="text-muted">
													#encodeForHTML(getEnc.remarks)#
												</small>
											</cfif>
										</td>
										<td>#getEnc.object_count#</td>
										<td>
											<cfif len(variables.collection_object_id) GT 0>
												<button type="button" class="btn btn-xs btn-secondary mb-1"
													onclick="submitEncumbranceAction('saveEncumbrances','#getEnc.encumbrance_id#','#encodeForHTML(variables.collection_object_id)#');">
													Add Items to This Encumbrance
												</button>
												<button type="button" class="btn btn-xs btn-warning mb-1"
													onclick="submitEncumbranceAction('remListedItems','#getEnc.encumbrance_id#','#encodeForHTML(variables.collection_object_id)#');">
													Remove Listed Items
												</button>
											</cfif>
											<button type="button" class="btn btn-xs btn-secondary mb-1"
												onclick="submitEncumbranceAction('updateEncumbrance','#getEnc.encumbrance_id#','#encodeForHTML(variables.collection_object_id)#');">
												Edit
											</button>
											<button type="button" class="btn btn-xs btn-danger mb-1"
												onclick="confirmDeleteEncumbrance('#getEnc.encumbrance_id#','#encodeForHTML(variables.collection_object_id)#');">
												Delete
											</button>
											<a href="/SpecimenResults.cfm?encumbrance_id=#getEnc.encumbrance_id#"
												class="btn btn-xs btn-info mb-1">
												See Specimens
											</a>
											<a href="/Admin/deleteSpecByEncumbrance.cfm?encumbrance_id=#getEnc.encumbrance_id#"
												class="btn btn-xs btn-danger mb-1">
												Delete Encumbered Specimens
											</a>
										</td>
									</tr>
									<cfset variables.rowNum = variables.rowNum + 1>
								</cfloop>
							</tbody>
						</table>
						<!--- Single shared form for all table-row POST actions.
						     Buttons populate this form via JavaScript and submit it,
						     avoiding the invalid HTML of nesting a form inside a table row. --->
						<form id="encumbranceActionForm" name="encumbranceActionForm"
							method="post" action="/Encumbrances.cfm">
							<input type="hidden" id="encActionValue" name="action" value="">
							<input type="hidden" id="encIdValue" name="encumbrance_id" value="">
							<input type="hidden" id="encCollObjValue" name="collection_object_id" value="">
						</form>
						<script>
							/**
							 * Populates and submits the shared encumbrance action form.
							 * @param {string} actionValue the action to perform (e.g. 'updateEncumbrance').
							 * @param {string} encumbranceId the encumbrance_id to act on.
							 * @param {string} collectionObjectId the collection_object_id context; may be empty.
							 */
							function submitEncumbranceAction(actionValue, encumbranceId, collectionObjectId) {
								$('##encActionValue').val(actionValue);
								$('##encIdValue').val(encumbranceId);
								$('##encCollObjValue').val(collectionObjectId);
								$('##encumbranceActionForm').submit();
							}

							/**
							 * Asks the user to confirm deletion then submits the deleteEncumbrance action.
							 * @param {string} encumbranceId the ID of the encumbrance to delete.
							 * @param {string} collectionObjectId the collection_object_id context; may be empty.
							 */
							function confirmDeleteEncumbrance(encumbranceId, collectionObjectId) {
								if (confirm("Are you sure you want to delete this encumbrance? This cannot be undone.")) {
									submitEncumbranceAction('deleteEncumbrance', encumbranceId, collectionObjectId);
								}
							}
						</script>
					</cfif>
				</div>
			</section>
		</cfcase>

		<!--- ================================================================
		     remListedItems: remove listed specimens from an encumbrance.
		     TODO: Move to a backing cffunction in encumbrance/component/functions.cfc.
		     ================================================================ --->
		<cfcase value="remListedItems">
			<cfif len(variables.encumbrance_id) EQ 0>
				<div class="alert alert-danger mt-2" role="alert">
					No encumbrance_id provided.
				</div>
				<cfabort>
			</cfif>
			<cfif len(variables.collection_object_id) EQ 0>
				<div class="alert alert-danger mt-2" role="alert">
					No collection_object_id provided.
				</div>
				<cfabort>
			</cfif>
			<cftry>
				<cfquery name="remItem" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					DELETE FROM coll_object_encumbrance
					WHERE
						encumbrance_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.encumbrance_id#">
						AND collection_object_id IN  ( <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.collection_object_id#" list="Yes" > )
				</cfquery>
			<cfcatch type="database">
				<div class="alert alert-danger mt-2" role="alert">
					<strong>Database error removing items:</strong>
					#encodeForHTML(cfcatch.message)#
				</div>
				<cfabort>
			</cfcatch>
			</cftry>
			<section class="row mx-0 mt-2 mb-2">
				<div class="col-12">
					<div class="alert alert-success" role="alert">
						All listed items have been removed from this encumbrance.
					</div>
					<a href="/Encumbrances.cfm?action=listEncumbrances&encumbrance_id=#variables.encumbrance_id#&collection_object_id=#URLEncodedFormat(variables.collection_object_id)#"
						class="btn btn-xs btn-secondary">
						Return to Encumbrance
					</a>
				</div>
			</section>
		</cfcase>

		<!--- ================================================================
		     updateEncumbrance: display the encumbrance edit form
		     ================================================================ --->
		<cfcase value="updateEncumbrance">
			<cfquery name="encDetails" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT
					encumbrance.*,
					preferred_agent_name.agent_name
				FROM
					encumbrance
					JOIN preferred_agent_name
						ON encumbrance.encumbering_agent_id = preferred_agent_name.agent_id
				WHERE
					encumbrance.encumbrance_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.encumbrance_id#">
			</cfquery>
			<cfif encDetails.recordcount EQ 0>
				<div class="alert alert-danger mt-2" role="alert">
					Encumbrance not found (ID: #encodeForHTML(variables.encumbrance_id)#).
				</div>
				<cfabort>
			</cfif>
			<!--- Pre-format dates; isDate() guards against null database values. --->
			<cfset variables.editMadeDate = "">
			<cfif isDate(encDetails.made_date)>
				<cfset variables.editMadeDate = dateformat(encDetails.made_date,"yyyy-mm-dd")>
			</cfif>
			<cfset variables.editExpDate = "">
			<cfif isDate(encDetails.expiration_date)>
				<cfset variables.editExpDate = dateformat(encDetails.expiration_date,"yyyy-mm-dd")>
			</cfif>
			<h1 class="h2 ml-3 mb-1">Edit Encumbrance
				<i class="fas fa-info-circle" onClick="getMCZDocs('encumbrance','encumbrance')" aria-label="help link"></i>
			</h1>
			<section class="row mx-0 border rounded my-2 pt-2">
				<div class="col-12 pb-2">
					<p class="text-muted mb-1">
						<small>Encumbrance ID: #encodeForHTML(variables.encumbrance_id)#</small>
					</p>
					<a href="/Encumbrances.cfm?action=listEncumbrances&encumbrance_id=#encodeForHTML(variables.encumbrance_id)#"
						class="btn btn-xs btn-secondary mb-2">
						<i class="fa fa-arrow-left" aria-hidden="true"></i> Back to Encumbrance
					</a>
				</div>
				<form class="col-12" name="updateEncumbranceForm" id="updateEncumbranceForm"
					method="post" action="/Encumbrances.cfm">
					<input type="hidden" name="action" value="updateEncumbrance2">
					<input type="hidden" name="encumbrance_id"
						value="#encodeForHTML(variables.encumbrance_id)#">
					<input type="hidden" name="collection_object_id"
						value="#encodeForHTML(variables.collection_object_id)#">
					<div class="form-row">
						<div class="col-12 col-md-6 mb-2">
							<span class="d-block">
								<label for="encumberingAgentEdit" class="data-entry-label w-auto d-inline">Encumbering Agent</label>
								<span id="agentViewEdit" class="d-inline ml-1"></span>
							</span>
							<div class="input-group">
								<div class="input-group-prepend">
									<span class="input-group-text smaller" id="agentIconEdit">
										<i class="fa fa-user" aria-hidden="true"></i>
									</span>
								</div>
								<input type="hidden" name="encumberingAgentId" id="encumberingAgentId" value="#encodeForHTML(encDetails.encumbering_agent_id)#">
								<input type="text" name="encumberingAgent" id="encumberingAgentEdit" class="form-control data-entry-input reqdClr" value="#encodeForHTML(encDetails.agent_name)#" aria-describedby="agentIconEdit">
							</div>
							<script>
								$(document).ready(function() {
									makeRichAgentPicker('encumberingAgentEdit', 'encumberingAgentId', 'agentIconEdit', 'agentViewEdit', '#val(encDetails.encumbering_agent_id)#');
								});
							</script>
						</div>
						<div class="col-12 col-md-3 mb-2">
							<label for="made_date" class="data-entry-label">Made Date</label>
							<input type="text" name="made_date" id="made_date" value="#encodeForHTML(variables.editMadeDate)#" class="data-entry-input col-12">
						</div>
					</div>
					<div class="form-row">
						<div class="col-12 col-md-3 mb-2">
							<label for="expiration_date" class="data-entry-label">Expiration Date</label>
							<input type="text" name="expiration_date" id="expiration_date" value="#encodeForHTML(variables.editExpDate)#" class="data-entry-input col-12">
						</div>
						<div class="col-12 col-md-3 mb-2">
							<label for="expiration_event" class="data-entry-label">Expiration Event</label>
							<input type="text" name="expiration_event" id="expiration_event" value="#encodeForHTML(encDetails.expiration_event)#" class="data-entry-input col-12">
						</div>
					</div>
					<div class="form-row">
						<div class="col-12 col-md-6 mb-2">
							<label for="encumbranceNameEdit" class="data-entry-label">Encumbrance Name</label>
							<input type="text" name="encumbrance" id="encumbranceNameEdit" value="#encodeForHTML(encDetails.encumbrance)#" class="data-entry-input col-12 reqdClr">
						</div>
						<div class="col-12 col-md-3 mb-2">
							<label for="encumbrance_action_edit" class="data-entry-label">Encumbrance Action</label>
							<select name="encumbrance_action" id="encumbrance_action_edit" class="data-entry-select col-12 reqdClr">
								<cfloop query="getCtEncumbranceAction">
									<cfif getCtEncumbranceAction.encumbrance_action EQ encDetails.encumbrance_action>
										<cfset variables.encActEditSelected = "selected">
									<cfelse>
										<cfset variables.encActEditSelected = "">
									</cfif>
									<option value="#encodeForHTML(getCtEncumbranceAction.encumbrance_action)#" #variables.encActEditSelected#>
										#encodeForHTML(getCtEncumbranceAction.encumbrance_action)#
									</option>
								</cfloop>
							</select>
						</div>
					</div>
					<div class="form-row">
						<div class="col-12 col-md-9 mb-2">
							<label for="remarks" class="data-entry-label">Remarks</label>
							<textarea name="remarks" id="remarks" rows="3" class="data-entry-input col-12">#encodeForHTML(encDetails.remarks)#</textarea>
						</div>
					</div>
					<div class="form-row mb-4 mt-1">
						<div class="col-12">
							<button type="submit" class="btn btn-xs btn-primary" onclick="return validateEditEncumbranceForm();">Save Changes</button>
							<a href="/Encumbrances.cfm?action=listEncumbrances&encumbrance_id=#encodeForHTML(variables.encumbrance_id)#" class="btn btn-xs btn-warning ml-1">
								Cancel
							</a>
						</div>
					</div>
				</form>
			</section>
			<script>
				$(document).ready(function() {
					$('##made_date').datepicker();
					$('##expiration_date').datepicker();
				});

				/**
				 * Validates the edit encumbrance form before submission.
				 * Checks that the encumbering agent has been resolved to a valid database id,
				 * and that expiration date and expiration event are not both specified.
				 * @return {boolean} false if validation fails, true otherwise.
				 */
				function validateEditEncumbranceForm() {
					if ($('##encumberingAgentId').val() === "") {
						alert("Error: You must pick an Encumbering Agent from the list.");
						return false;
					}
					if ($('##expiration_date').val() !== "" && $('##expiration_event').val() !== "") {
						alert("Error: You may specify an expiration event or an expiration date, but not both.");
						return false;
					}
					return true;
				}
			</script>
		</cfcase>

		<!--- ================================================================
		     updateEncumbrance2: save edits to an encumbrance record then redirect.
		     TODO: Move to a backing cffunction in encumbrance/component/functions.cfc.
		     ================================================================ --->
		<cfcase value="updateEncumbrance2">
			<cfquery name="updateEnc" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE encumbrance
				SET
					ENCUMBERING_AGENT_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.encumberingAgentId#">,
					ENCUMBRANCE = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.encumbranceName#">,
					ENCUMBRANCE_ACTION = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.encumbrance_action#">,
					EXPIRATION_DATE = <cfif len(variables.expiration_date) GT 0><cfqueryparam cfsqltype="CF_SQL_DATE" value="#dateformat(variables.expiration_date,'yyyy-mm-dd')#"><cfelse>NULL</cfif>,
					EXPIRATION_EVENT = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.expiration_event#">
					<cfif len(variables.made_date) GT 0>
						,MADE_DATE = <cfqueryparam cfsqltype="CF_SQL_DATE" value="#dateformat(variables.made_date,'yyyy-mm-dd')#">
					</cfif>
					,REMARKS = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.remarks#">
				WHERE
					encumbrance_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.encumbrance_id#">
			</cfquery>
			<cfset additional="">
			<cfif len(variables.collection_object_id) GT 0>
				<cfset additional="&collection_object_id=#URLEncodedFormat(variables.collection_object_id)#">
			</cfif>
			<cflocation url="/Encumbrances.cfm?action=updateEncumbrance&encumbrance_id=#variables.encumbrance_id##additional#" addtoken="false">
		</cfcase>

		<!--- ================================================================
		     deleteEncumbrance: check usage then delete the encumbrance record.
		     TODO: Move to a backing cffunction in encumbrance/component/functions.cfc.
		     ================================================================ --->
		<cfcase value="deleteEncumbrance">
			<cfif len(variables.encumbrance_id) EQ 0>
				<div class="alert alert-danger mt-2" role="alert">
					No encumbrance_id provided.
				</div>
				<cfabort>
			</cfif>
			<cfquery name="isUsed" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT count(*) AS cnt
				FROM coll_object_encumbrance
				WHERE encumbrance_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.encumbrance_id#">
			</cfquery>
			<section class="row mx-0 mt-2 mb-2">
				<div class="col-12">
					<cfif isUsed.cnt GT 0>
						<div class="alert alert-danger" role="alert">
							<strong>Cannot delete:</strong> This encumbrance is applied to
							#isUsed.cnt# specimen(s). Remove all specimens from this encumbrance
							before deleting it.
						</div>
						<a href="/Encumbrances.cfm?action=listEncumbrances&encumbrance_id=#variables.encumbrance_id#"
							class="btn btn-xs btn-secondary">
							Return to Encumbrance
						</a>
					<cfelse>
						<cfquery name="deleteEnc" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							DELETE FROM encumbrance
							WHERE encumbrance_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.encumbrance_id#">
						</cfquery>
						<div class="alert alert-success" role="alert">
							Encumbrance deleted successfully.
						</div>
						<a href="/Encumbrances.cfm" class="btn btn-xs btn-secondary">
							Return to Find Encumbrances
						</a>
					</cfif>
				</div>
			</section>
		</cfcase>

		<!--- ================================================================
		     saveEncumbrances: add listed specimens to an encumbrance.
		     TODO: Move to a backing cffunction in encumbrance/component/functions.cfc.
		     ================================================================ --->
		<cfcase value="saveEncumbrances">
			<cfif len(variables.encumbrance_id) EQ 0>
				<div class="alert alert-danger mt-2" role="alert">
					No encumbrance_id provided.
				</div>
				<cfabort>
			</cfif>
			<cfif len(variables.collection_object_id) EQ 0>
				<div class="alert alert-danger mt-2" role="alert">
					No collection_object_id provided.
				</div>
				<cfabort>
			</cfif>
			<cftry>
				<cfloop index="loopId" list="#variables.collection_object_id#" delimiters=",">
					<cfquery name="encSpec" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						INSERT INTO coll_object_encumbrance (
							encumbrance_id,
							collection_object_id
						) VALUES (
							<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.encumbrance_id#">,
							<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#loopId#">
						)
					</cfquery>
				</cfloop>
			<cfcatch type="database">
				<div class="alert alert-danger mt-2" role="alert">
					<strong>Database error saving encumbrances:</strong>
					#encodeForHTML(cfcatch.message)#
				</div>
				<cfabort>
			</cfcatch>
			</cftry>
			<section class="row mx-0 mt-2 mb-2">
				<div class="col-12">
					<div class="alert alert-success" role="alert">
						All listed items have been added to this encumbrance.
					</div>
					<a href="/Encumbrances.cfm?action=listEncumbrances&encumbrance_id=#variables.encumbrance_id#&collection_object_id=#URLEncodedFormat(variables.collection_object_id)#"
						class="btn btn-xs btn-secondary">
						Return to Encumbrance
					</a>
				</div>
			</section>
		</cfcase>

	</cfswitch>

	<!--- ================================================================
	     Cataloged items section.
	     Shown when collection_object_id is present and the current action
	     is not one of the two silent redirect actions (createEncumbrance
	     and updateEncumbrance2 call cflocation and never reach this point).
	     This section is retained here pending full disentanglement into a
	     dedicated manage page (see TODO at top of file).
	     ================================================================ --->
	<cfif len(variables.collection_object_id) GT 0
		AND NOT listFind(variables.knownActions, variables.action) EQ 0
		AND NOT listFindNoCase("createEncumbrance,updateEncumbrance2", variables.action)>
		<!--- Note: session.CustomOtherIdentifier is used directly as an argument to
		     concatSingleOtherId() in the SELECT clause. This is the standard MCZbase
		     pattern for this function; it is a session-managed configuration value,
		     not user-provided input. --->
		<cfquery name="getData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			SELECT
				cataloged_item.collection_object_id AS collection_object_id,
				cat_num,
				concatSingleOtherId(cataloged_item.collection_object_id,'#session.CustomOtherIdentifier#') AS CustomID,
				identification.scientific_name,
				country,
				state_prov,
				county,
				quad,
				institution_acronym,
				collection.collection_cde,
				part_name,
				specimen_part.collection_object_id AS partID,
				encumbering_agent.agent_name AS encumbering_agent,
				expiration_date,
				expiration_event,
				encumbrance.encumbrance AS enc_name,
				encumbrance.made_date AS encumbered_date,
				encumbrance.remarks AS enc_remarks,
				encumbrance_action,
				encumbrance.encumbrance_id
			FROM
				identification,
				collecting_event,
				locality,
				geog_auth_rec,
				cataloged_item,
				collection,
				specimen_part,
				coll_object_encumbrance,
				encumbrance,
				preferred_agent_name encumbering_agent
			WHERE
				locality.geog_auth_rec_id = geog_auth_rec.geog_auth_rec_id
				AND collecting_event.locality_id = locality.locality_id
				AND cataloged_item.collecting_event_id = collecting_event.collecting_event_id
				AND cataloged_item.collection_object_id = identification.collection_object_id
				AND identification.accepted_id_fg = 1
				AND cataloged_item.collection_object_id = specimen_part.derived_from_cat_item (+)
				AND cataloged_item.collection_id = collection.collection_id
				AND cataloged_item.collection_object_id = coll_object_encumbrance.collection_object_id (+)
				AND coll_object_encumbrance.encumbrance_id = encumbrance.encumbrance_id (+)
				AND encumbrance.encumbering_agent_id = encumbering_agent.agent_id (+)
				AND cataloged_item.collection_object_id
					IN (<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.collection_object_id#" list="yes">)
			ORDER BY
				cataloged_item.collection_object_id
		</cfquery>
		<section class="row mx-0 mt-3 mb-4">
			<div class="col-12">
				<hr>
				<h2 class="h3 mb-3">Cataloged Items Being Encumbered</h2>
				<table class="table table-sm table-striped table-responsive d-xl-table">
					<thead class="thead-light">
						<tr>
							<th scope="col">Catalog Number</th>
							<th scope="col">#encodeForHTML(session.CustomOtherIdentifier)#</th>
							<th scope="col">Scientific Name</th>
							<th scope="col">Country</th>
							<th scope="col">State</th>
							<th scope="col">County</th>
							<th scope="col">Quad</th>
							<th scope="col">Parts</th>
							<th scope="col">Existing Encumbrances</th>
						</tr>
					</thead>
					<tbody>
						<cfloop query="getData" group="collection_object_id">
							<tr>
								<td>
									<a href="/specimens/Specimen.cfm?collection_object_id=#collection_object_id#">
										#encodeForHTML(collection_cde)#&nbsp;#encodeForHTML(cat_num)#
									</a>
								</td>
								<td>#encodeForHTML(CustomID)#&nbsp;</td>
								<td><em>#encodeForHTML(Scientific_Name)#</em></td>
								<td>#encodeForHTML(Country)#&nbsp;</td>
								<td>#encodeForHTML(State_Prov)#&nbsp;</td>
								<td>#encodeForHTML(county)#&nbsp;</td>
								<td>#encodeForHTML(quad)#&nbsp;</td>
								<td>
									<!--- Query of queries: cfqueryparam is not supported in dbtype="query".
									     collection_object_id originates from the getData result set,
									     not from user input. --->
									<cfquery name="getParts" dbtype="query">
										SELECT part_name, partID
										FROM getData
										WHERE collection_object_id = #collection_object_id#
										GROUP BY part_name, partID
									</cfquery>
									<cfloop query="getParts">
										<cfif len(getParts.partID) GT 0>
											#encodeForHTML(getParts.part_name)#<br>
										</cfif>
									</cfloop>
								</td>
								<td>
									<!--- Query of queries: cfqueryparam is not supported in dbtype="query".
									     collection_object_id originates from the getData result set,
									     not from user input. --->
									<cfquery name="encs" dbtype="query">
										SELECT
											collection_object_id,
											encumbrance_id,
											enc_name,
											encumbrance_action,
											encumbering_agent,
											encumbered_date,
											expiration_date,
											expiration_event,
											enc_remarks
										FROM getData
										WHERE collection_object_id = #collection_object_id#
										GROUP BY
											collection_object_id,
											encumbrance_id,
											enc_name,
											encumbrance_action,
											encumbering_agent,
											encumbered_date,
											expiration_date,
											expiration_event,
											enc_remarks
									</cfquery>
									<cfloop query="encs">
										<cfif len(encs.enc_name) GT 0>
											<span class="d-block mb-1">
												#encodeForHTML(encs.enc_name)# (#encodeForHTML(encs.encumbrance_action)#)
												by #encodeForHTML(encs.encumbering_agent)#
												made <cfif isDate(encs.encumbered_date)>#dateformat(encs.encumbered_date,"yyyy-mm-dd")#</cfif>,
												expires <cfif isDate(encs.expiration_date)>#dateformat(encs.expiration_date,"yyyy-mm-dd")#</cfif>
												#encodeForHTML(encs.expiration_event)#
												#encodeForHTML(encs.enc_remarks)#
											</span>
											<button type="button" class="btn btn-xs btn-warning mb-1"
												onclick="submitEncumbranceAction('remListedItems','#val(encs.encumbrance_id)#','#val(collection_object_id)#');">
												Remove This Encumbrance
											</button>
										<cfelse>
											<span class="text-muted">None</span>
										</cfif>
									</cfloop>
								</td>
							</tr>
						</cfloop>
					</tbody>
				</table>
			</div>
		</section>
	</cfif>

</main>
</cfoutput>

<cfinclude template="/shared/_footer.cfm">
