<!---
Bulkloader/cloneWithBarcodes.cfm

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
<!--- Replaces one record staged in the bulkloader with a copy for each of a list of containers,
	each copy putting its first part in one of the containers. --->
<cfset pageTitle = "Clone Records by Container">
<!--- for the container picker in step 3 --->
<cfset pageHasContainers = "true">
<cfinclude template="/shared/_header.cfm">
<cfinclude template="/shared/component/stagingTables.cfc" runOnce="true">

<!--- Bulkloader rows with ids up to this are the Data Entry templates, one per collection, as
	MAXTEMPLATE in /DataEntry.cfm; they are never offered for cloning. --->
<cfset MAXTEMPLATE = 14>
<cfset MAX_LISTED_RECORDS = 500>
<cfset MAX_CLONES = 100>
<!--- The bulkloader's check rejects a part container whose type is a label, other than a cryovial label. --->
<cfset ALLOWED_LABEL_TYPE = "cryovial label">

<cfparam name="url.action" default="">
<cfparam name="form.action" default="">
<cfparam name="url.enteredby" default="">
<cfparam name="url.accn" default="">
<cfparam name="url.collection_object_id" default="">
<cfparam name="form.enteredby" default="">
<cfparam name="form.accn" default="">
<cfparam name="form.collection_object_id" default="">
<cfparam name="form.unique_ids" default="">

<cfset variables.action = "entryPoint">
<cfif len(url.action) GT 0>
	<cfset variables.action = url.action>
</cfif>
<cfif len(form.action) GT 0>
	<cfset variables.action = form.action>
</cfif>
<!--- The record filters travel by url on the read only steps and by form on the posts. --->
<cfset variables.enteredby = url.enteredby>
<cfset variables.accn = url.accn>
<cfset variables.collection_object_id = url.collection_object_id>
<cfif cgi.request_method EQ "POST">
	<cfset variables.enteredby = form.enteredby>
	<cfset variables.accn = form.accn>
	<cfset variables.collection_object_id = form.collection_object_id>
</cfif>

<!--- As on /DataEntry.cfm, a collection manager may work on the records of the data entry users in
	the collections they manage, and anyone on their own. --->
<cf_setDataEntryGroups>
<cfset variables.mayEditOthers = false>
<cfif isDefined("inAdminGroups") AND len(inAdminGroups) GT 0>
	<cfset variables.mayEditOthers = true>
</cfif>
<cfset variables.permittedUsers = session.username>
<cfif variables.mayEditOthers AND isDefined("adminForUsers") AND len(adminForUsers) GT 0>
	<cfset variables.permittedUsers = adminForUsers>
	<cfif listFindNoCase(variables.permittedUsers, session.username) EQ 0>
		<cfset variables.permittedUsers = listAppend(variables.permittedUsers, session.username)>
	</cfif>
</cfif>
<!--- Only the permitted users among those asked for; none asked for means all of them. --->
<cfset variables.selectedUsers = "">
<cfloop list="#variables.enteredby#" index="variables.requestedUser">
	<cfif listFindNoCase(variables.permittedUsers, trim(variables.requestedUser)) GT 0>
		<cfset variables.selectedUsers = listAppend(variables.selectedUsers, trim(variables.requestedUser))>
	</cfif>
</cfloop>
<cfif len(variables.selectedUsers) EQ 0>
	<cfset variables.selectedUsers = variables.permittedUsers>
</cfif>
<cfset variables.filterParams = "enteredby=#encodeForUrl(variables.enteredby)#&accn=#encodeForUrl(variables.accn)#">

<!---
	getCloneableRecord the staged record to clone, if it is one the user may clone.

	@param collection_object_id the bulkloader record id.
	@param users the users whose records may be cloned.
	@return a query with the record's summary fields, empty if it is not one the user may clone.
--->
<cffunction name="getCloneableRecord" returntype="query" output="false">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfargument name="users" type="string" required="yes">

	<cfset var getRecord = "">
	<cfquery name="getRecord" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getRecord_result">
		SELECT
			collection_object_id, institution_acronym, collection_cde, cat_num, taxon_name, spec_locality,
			part_name_1, preserv_method_1, part_lot_count_1, part_container_unique_id_1, part_name_2,
			accn, enteredby, loaded
		FROM bulkloader
		WHERE
			collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#val(arguments.collection_object_id)#">
			AND collection_object_id > <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#MAXTEMPLATE#">
			AND enteredby IN (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.users#" list="yes">)
	</cfquery>
	<cfreturn getRecord>
</cffunction>

<!---
	parseUniqueIds split the entered container unique ids, separated by commas, spaces or line breaks.

	@param text the text entered.
	@return an array of the ids, in the order entered.
--->
<cffunction name="parseUniqueIds" returntype="array" output="false">
	<cfargument name="text" type="string" required="yes">
	<cfreturn REMatch("[^,\s]+", arguments.text)>
</cffunction>

<!---
	checkUniqueIds check that each id is a container a part can be placed in, as the bulkloader will
	when the clones are loaded, and that no id is entered twice.

	@param uniqueIds an array of container unique ids.
	@return a structure of results, an array of structures of unique_id, container_type and
		problem (empty for a usable container); and problemCount.
--->
<cffunction name="checkUniqueIds" returntype="struct" output="false">
	<cfargument name="uniqueIds" type="array" required="yes">

	<cfset var result = { results = [], problemCount = 0 }>
	<cfset var getContainers = "">
	<cfset var containerTypes = structNew()>
	<cfset var seen = structNew()>
	<cfset var uniqueId = "">
	<cfset var entry = "">

	<cfif arrayLen(arguments.uniqueIds) GT 0>
		<cfquery name="getContainers" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getContainers_result">
			SELECT barcode, container_type
			FROM container
			WHERE barcode IN (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arrayToList(arguments.uniqueIds, chr(31))#" list="yes" separator="#chr(31)#">)
		</cfquery>
		<cfloop query="getContainers">
			<cfset containerTypes[getContainers.barcode] = getContainers.container_type>
		</cfloop>
	</cfif>
	<cfloop array="#arguments.uniqueIds#" index="uniqueId">
		<cfset entry = { unique_id = uniqueId, container_type = "", problem = "" }>
		<cfif structKeyExists(seen, uniqueId)>
			<cfset entry.problem = "Entered more than once.">
		<cfelseif NOT structKeyExists(containerTypes, uniqueId)>
			<cfset entry.problem = "No container has this unique id.">
		<cfelse>
			<cfset entry.container_type = containerTypes[uniqueId]>
			<cfif findNoCase("label", entry.container_type) GT 0 AND entry.container_type NEQ ALLOWED_LABEL_TYPE>
				<cfset entry.problem = "This container is a label, which a part cannot be placed in.">
			</cfif>
		</cfif>
		<cfset seen[uniqueId] = true>
		<cfif len(entry.problem) GT 0>
			<cfset result.problemCount = result.problemCount + 1>
		</cfif>
		<cfset arrayAppend(result.results, entry)>
	</cfloop>
	<cfreturn result>
</cffunction>

<!--- The guidance starts open on the first step and closed on the later ones. --->
<cfset variables.guidanceOpen = "">
<cfif variables.action EQ "entryPoint">
	<cfset variables.guidanceOpen = "open">
</cfif>
<cfoutput>
<main class="container-fluid py-3" id="content">
	<div class="row mx-0">
		<div class="col-12">
			<h1 class="h2">Clone Records by Container</h1>
		</div>
	</div>

	<!--- Shown on every step so the steps can be followed from any of them. --->
	<section class="row mx-0" aria-labelledby="aboutHeading">
		<div class="col-12 col-xl-10">
			<h2 class="h4" id="aboutHeading">What this does and how to use it</h2>
			<details class="border rounded bg-light px-3 py-2 mb-3" #variables.guidanceOpen#>
				<summary>Show or hide the instructions</summary>
				<p class="mt-2">
					Use this page when a record you have entered in Data Entry, and not yet loaded, describes material
					that is held in several containers, for example a lot divided among several jars, or tissue
					samples in several cryovials.  It replaces that one record with a copy for each container, so
					that each container gets its own cataloged item when the records are loaded.
				</p>
				<p>
					All of the work here is done in the bulkloader, where records entered in Data Entry wait until
					they are loaded.  The record you clone, and the clones made from it, are records waiting
					there, not cataloged items.  No cataloged item, part or container is created or changed by this
					page; the containers you enter are only checked and written into the clones.  The specimens are
					created, and each first part placed in its container, when the bulkloader loads the clones, as for
					any other record from Data Entry.
				</p>
				<ol>
					<li><strong>Find the record.</strong> Choose whose records to list, and optionally accessions, then List Records.</li>
					<li><strong>Choose the record</strong> to clone from the list, with its Clone button.</li>
					<li>
						<strong>Enter the container unique ids</strong>, one for each copy you want.  Type them, separated by
						commas, spaces or line breaks; scan them with a barcode scanner that ends each scan with a line break; or
						use Pick a Container, as many times as needed, to find a container and add its unique id to the list.
						The three can be mixed.  Then Check Containers.
					</li>
					<li>
						<strong>Create the clones.</strong> When every container passes the check, Create Clones adds the
						copies to the bulkloader and removes the original record from it.
					</li>
				</ol>
				<p>What the clones contain:</p>
				<ul>
					<li>
						Each clone is a copy of the original record, with its own record number, except for the Container
						Unique ID of its first part (the first row of the Parts table in Data Entry), which is one of the
						containers you entered.
					</li>
					<li>
						Other parts are copied unchanged, containers included, so every clone puts those parts in the same
						containers.  Only the first part is given a container of its own.
					</li>
					<li>
						Clones keep the original's catalog number.  A catalog number can be used only once, so if the original
						has one, give each clone its own in Data Entry before the clones are loaded.
					</li>
					<li>
						Clones keep the original's status.  If the original was marked to load, so are the clones; if it was
						waiting for changes, so are they.
					</li>
					<li>The original record is removed from the bulkloader when the clones are made.  This cannot be undone from this page.</li>
				</ul>
				<p>How a clone is linked to its container:</p>
				<ol>
					<li>
						<strong>When the clones are made</strong>, each container's unique id is entered as the Container
						Unique ID of its clone's first part, as if you had typed it in Data Entry.  Nothing is done to the
						container itself, and nothing reserves it for the clone.
					</li>
					<li>
						<strong>When the clone is checked</strong> before loading, the unique id must still belong to a
						container that is not a label.  It is checked again because the container may have changed since the
						clone was made.
					</li>
					<li>
						<strong>When the clone is loaded</strong>, its first part is created and placed in that container,
						dated the day it was loaded, just as for any part entered in Data Entry with a Container Unique ID.
					</li>
				</ol>
				<p>
					A container unique id must belong to a container already in MCZbase, and that container must not be a label
					(cryovial labels excepted), the same check the bulkloader makes when the records are loaded.
					You can clone your own records, and if you manage a collection, the records of its data entry users.
					The Data Entry templates are not offered.  At most #MAX_CLONES# clones can be made at a time.
				</p>
			</details>
		</div>
	</section>

	<!------------------------------------------------------------------------------------------>
	<cfif variables.action EQ "entryPoint">
		<cfquery name="getAccessions" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getAccessions_result">
			SELECT accn, count(*) AS record_count
			FROM bulkloader
			WHERE
				enteredby IN (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.permittedUsers#" list="yes">)
				AND collection_object_id > <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#MAXTEMPLATE#">
				AND accn IS NOT NULL
			GROUP BY accn
			ORDER BY accn
		</cfquery>
		<section class="row mx-0" role="search" aria-labelledby="findHeading">
			<div class="col-12 col-md-8 col-xl-6 border rounded px-3 py-2 mb-4">
				<h2 class="h3" id="findHeading">1. Find the record to clone</h2>
				<form name="findRecords" id="findRecords" method="get" action="/Bulkloader/cloneWithBarcodes.cfm">
					<input type="hidden" name="action" value="listRecords">
					<div class="form-row">
						<div class="col-12 col-sm-6 mb-2">
							<label for="enteredby" class="data-entry-label">Entered By</label>
							<select name="enteredby" id="enteredby" multiple size="6" class="data-entry-select" aria-describedby="enteredbyHelp">
								<cfloop list="#variables.permittedUsers#" index="variables.permittedUser">
									<option value="#encodeForHtml(variables.permittedUser)#">#encodeForHtml(variables.permittedUser)#</option>
								</cfloop>
							</select>
							<small id="enteredbyHelp" class="text-secondary">None selected lists everyone shown.</small>
						</div>
						<div class="col-12 col-sm-6 mb-2">
							<label for="accn" class="data-entry-label">Accession</label>
							<select name="accn" id="accn" multiple size="6" class="data-entry-select" aria-describedby="accnHelp">
								<cfloop query="getAccessions">
									<option value="#encodeForHtml(getAccessions.accn)#">#encodeForHtml(getAccessions.accn)# (#getAccessions.record_count#)</option>
								</cfloop>
							</select>
							<small id="accnHelp" class="text-secondary">None selected lists all accessions.</small>
						</div>
					</div>
					<button type="submit" class="btn btn-xs btn-primary mb-2">List Records</button>
				</form>
			</div>
		</section>
	</cfif>

	<!------------------------------------------------------------------------------------------>
	<cfif variables.action EQ "listRecords">
		<cfquery name="getRecords" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getRecords_result" maxrows="#MAX_LISTED_RECORDS + 1#">
			SELECT
				collection_object_id, institution_acronym, collection_cde, cat_num, taxon_name, spec_locality,
				part_name_1, preserv_method_1, part_lot_count_1, part_container_unique_id_1,
				accn, enteredby, loaded
			FROM bulkloader
			WHERE
				enteredby IN (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.selectedUsers#" list="yes">)
				AND collection_object_id > <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#MAXTEMPLATE#">
				<cfif len(variables.accn) GT 0>
					AND accn IN (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.accn#" list="yes">)
				</cfif>
			ORDER BY collection_object_id
		</cfquery>
		<section class="row mx-0" aria-labelledby="listHeading">
			<div class="col-12 mb-4">
				<h2 class="h3" id="listHeading">2. Choose the record to clone (#min(getRecords.recordcount, MAX_LISTED_RECORDS)# records)</h2>
				<p>
					<a href="/Bulkloader/cloneWithBarcodes.cfm" class="btn btn-xs btn-warning">New Search</a>
				</p>
				<cfif getRecords.recordcount GT MAX_LISTED_RECORDS>
					<div class="alert alert-warning" role="alert">
						Only the first #MAX_LISTED_RECORDS# matching records are shown; choose accessions or users to narrow the list.
					</div>
				</cfif>
				<cfif getRecords.recordcount EQ 0>
					<p>No records in the bulkloader match.</p>
				<cfelse>
					<table class="table table-responsive d-xl-table table-sm table-striped">
						<thead>
							<tr>
								<th scope="col">Clone</th>
								<th scope="col">Record</th>
								<th scope="col">Collection</th>
								<th scope="col">Catalog Number</th>
								<th scope="col">Taxon</th>
								<th scope="col">Specific Locality</th>
								<th scope="col">Part 1</th>
								<th scope="col">Part 1 Container</th>
								<th scope="col">Accession</th>
								<th scope="col">Entered By</th>
								<th scope="col">Status</th>
							</tr>
						</thead>
						<tbody>
							<cfloop query="getRecords" endrow="#MAX_LISTED_RECORDS#">
								<tr>
									<td>
										<a href="/Bulkloader/cloneWithBarcodes.cfm?action=chooseRecord&collection_object_id=#getRecords.collection_object_id#&#variables.filterParams#" class="btn btn-xs btn-secondary" aria-label="Clone record #getRecords.collection_object_id#">Clone</a>
									</td>
									<td>
										<a href="/DataEntry.cfm?action=editEnterData&pMode=edit&showAllUsers=#variables.mayEditOthers#&collection_object_id=#getRecords.collection_object_id#" target="_blank">#getRecords.collection_object_id#</a>
									</td>
									<td>#encodeForHtml(getRecords.institution_acronym)# #encodeForHtml(getRecords.collection_cde)#</td>
									<td>#encodeForHtml(getRecords.cat_num)#</td>
									<td>#encodeForHtml(getRecords.taxon_name)#</td>
									<td>#encodeForHtml(getRecords.spec_locality)#</td>
									<td>#encodeForHtml(getRecords.part_name_1)# <cfif len(getRecords.preserv_method_1) GT 0>(#encodeForHtml(getRecords.preserv_method_1)#)</cfif> <cfif len(getRecords.part_lot_count_1) GT 0>&times;#encodeForHtml(getRecords.part_lot_count_1)#</cfif></td>
									<td>#encodeForHtml(getRecords.part_container_unique_id_1)#</td>
									<td>#encodeForHtml(getRecords.accn)#</td>
									<td>#encodeForHtml(getRecords.enteredby)#</td>
									<td>#encodeForHtml(getRecords.loaded)#</td>
								</tr>
							</cfloop>
						</tbody>
					</table>
				</cfif>
			</div>
		</section>
	</cfif>

	<!------------------------------------------------------------------------------------------>
	<cfif variables.action EQ "chooseRecord" OR variables.action EQ "checkIds" OR variables.action EQ "createClones">
		<cfset variables.record = getCloneableRecord(variables.collection_object_id, variables.permittedUsers)>
		<cfif variables.record.recordcount EQ 0>
			<section class="row mx-0" aria-labelledby="notFoundHeading">
				<div class="col-12 mb-4">
					<h2 class="h3" id="notFoundHeading">Record not found</h2>
					<p>
						Record #encodeForHtml(variables.collection_object_id)# is not a record in the bulkloader that you can clone.
						It may already have been cloned, loaded or removed.
					</p>
					<a href="/Bulkloader/cloneWithBarcodes.cfm?action=listRecords&#variables.filterParams#" class="btn btn-xs btn-secondary">Back to the list</a>
				</div>
			</section>
			<cfset variables.action = "">
		<cfelse>
			<cfset variables.recordHeading = "Record to clone">
			<cfif variables.action EQ "createClones">
				<cfset variables.recordHeading = "Cloned record">
			</cfif>
			<section class="row mx-0" aria-labelledby="recordHeading">
				<div class="col-12 col-xl-10 border rounded px-3 py-2 mb-3">
					<h2 class="h3" id="recordHeading">#variables.recordHeading#: #variables.record.collection_object_id#</h2>
					<dl class="row mb-0">
						<dt class="col-sm-3">Collection</dt>
						<dd class="col-sm-9">#encodeForHtml(variables.record.institution_acronym)# #encodeForHtml(variables.record.collection_cde)#</dd>
						<dt class="col-sm-3">Catalog Number</dt>
						<dd class="col-sm-9">#encodeForHtml(variables.record.cat_num)#&nbsp;</dd>
						<dt class="col-sm-3">Taxon</dt>
						<dd class="col-sm-9">#encodeForHtml(variables.record.taxon_name)#&nbsp;</dd>
						<dt class="col-sm-3">Specific Locality</dt>
						<dd class="col-sm-9">#encodeForHtml(variables.record.spec_locality)#&nbsp;</dd>
						<dt class="col-sm-3">Part 1</dt>
						<dd class="col-sm-9">#encodeForHtml(variables.record.part_name_1)# #encodeForHtml(variables.record.preserv_method_1)# #encodeForHtml(variables.record.part_lot_count_1)#&nbsp;</dd>
						<dt class="col-sm-3">Part 1 Container</dt>
						<dd class="col-sm-9">#encodeForHtml(variables.record.part_container_unique_id_1)#&nbsp;</dd>
						<dt class="col-sm-3">Accession</dt>
						<dd class="col-sm-9">#encodeForHtml(variables.record.accn)#&nbsp;</dd>
						<dt class="col-sm-3">Entered By</dt>
						<dd class="col-sm-9">#encodeForHtml(variables.record.enteredby)#</dd>
						<dt class="col-sm-3">Status</dt>
						<dd class="col-sm-9">#encodeForHtml(variables.record.loaded)#&nbsp;</dd>
					</dl>
					<!--- After cloning the original is gone, so it gets no links or warnings. --->
					<cfif variables.action NEQ "createClones">
						<p class="mb-1">
							<a href="/DataEntry.cfm?action=editEnterData&pMode=edit&showAllUsers=#variables.mayEditOthers#&collection_object_id=#variables.record.collection_object_id#" target="_blank">Open in Data Entry</a>
							&middot;
							<a href="/Bulkloader/cloneWithBarcodes.cfm?action=listRecords&#variables.filterParams#">Back to the list</a>
						</p>
						<cfif len(variables.record.part_name_1) EQ 0>
							<div class="alert alert-warning mb-1" role="alert">This record has no first part, so its clones will have no part to place in the containers.</div>
						</cfif>
						<cfif len(variables.record.cat_num) GT 0>
							<div class="alert alert-warning mb-1" role="alert">Every clone will have catalog number #encodeForHtml(variables.record.cat_num)#; give each its own in Data Entry before loading.</div>
						</cfif>
					</cfif>
				</div>
			</section>
		</cfif>
	</cfif>

	<!------------------------------------------------------------------------------------------>
	<cfif variables.action EQ "checkIds" OR variables.action EQ "createClones">
		<cfset variables.uniqueIds = parseUniqueIds(form.unique_ids)>
		<cfset variables.tooMany = arrayLen(variables.uniqueIds) GT MAX_CLONES>
		<cfset variables.check = { results = [], problemCount = 0 }>
		<cfif NOT variables.tooMany>
			<cfset variables.check = checkUniqueIds(variables.uniqueIds)>
		</cfif>
		<cfset variables.mayCreate = false>
		<cfif arrayLen(variables.uniqueIds) GT 0 AND variables.check.problemCount EQ 0 AND NOT variables.tooMany>
			<cfset variables.mayCreate = true>
		</cfif>
		<!--- A failed recheck while creating shows the check and the form again. --->
		<cfif variables.action EQ "createClones" AND NOT variables.mayCreate>
			<cfset variables.action = "checkIds">
		</cfif>
	</cfif>

	<!------------------------------------------------------------------------------------------>
	<cfif variables.action EQ "createClones">
		<!--- Every column but the record id and the first part's container is copied from the original.
			Column names come from the data dictionary; they cannot be bound. --->
		<cfset variables.tableColumns = stagingTableColumns("BULKLOADER")>
		<cfset variables.copiedColumns = "">
		<cfloop collection="#variables.tableColumns#" item="variables.columnName">
			<cfif listFindNoCase("COLLECTION_OBJECT_ID,PART_CONTAINER_UNIQUE_ID_1,PART_CONTAINER_NAME_1", variables.columnName) EQ 0>
				<cfset variables.copiedColumns = listAppend(variables.copiedColumns, variables.columnName)>
			</cfif>
		</cfloop>
		<cfset variables.newIds = []>
		<cftransaction>
			<cfloop array="#variables.uniqueIds#" index="variables.uniqueId">
				<cfquery name="getNewId" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getNewId_result">
					SELECT bulkloader_pkey.nextval AS new_id FROM dual
				</cfquery>
				<cfquery name="insertClone" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="insertClone_result">
					INSERT INTO bulkloader (
						collection_object_id, part_container_unique_id_1, part_container_name_1, #variables.copiedColumns#
					)
					SELECT
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getNewId.new_id#">,
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.uniqueId#">,
						NULL,
						#variables.copiedColumns#
					FROM bulkloader
					WHERE collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.record.collection_object_id#">
				</cfquery>
				<cfset arrayAppend(variables.newIds, { collection_object_id = getNewId.new_id, unique_id = variables.uniqueId })>
			</cfloop>
			<cfquery name="deleteOriginal" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="deleteOriginal_result">
				DELETE FROM bulkloader
				WHERE collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.record.collection_object_id#">
			</cfquery>
		</cftransaction>
		<section class="row mx-0" aria-labelledby="createdHeading">
			<div class="col-12 col-xl-10 mb-4">
				<h2 class="h3" id="createdHeading">Created #arrayLen(variables.newIds)# clones</h2>
				<p>Record #variables.record.collection_object_id# has been replaced by these records:</p>
				<table class="table table-responsive d-md-table table-sm table-striped">
					<thead>
						<tr>
							<th scope="col">New Record</th>
							<th scope="col">Part 1 Container Unique ID</th>
						</tr>
					</thead>
					<tbody>
						<cfloop array="#variables.newIds#" index="variables.newId">
							<tr>
								<td><a href="/DataEntry.cfm?action=editEnterData&pMode=edit&showAllUsers=#variables.mayEditOthers#&collection_object_id=#variables.newId.collection_object_id#" target="_blank">#variables.newId.collection_object_id#</a></td>
								<td>#encodeForHtml(variables.newId.unique_id)#</td>
							</tr>
						</cfloop>
					</tbody>
				</table>
				<a href="/Bulkloader/cloneWithBarcodes.cfm?action=listRecords&#variables.filterParams#" class="btn btn-xs btn-secondary">Clone another record</a>
			</div>
		</section>
	</cfif>

	<!------------------------------------------------------------------------------------------>
	<cfif variables.action EQ "chooseRecord" OR variables.action EQ "checkIds">
		<section class="row mx-0" aria-labelledby="idsHeading">
			<div class="col-12 col-xl-10 border rounded px-3 py-2 mb-4">
				<h2 class="h3" id="idsHeading">3. Enter the containers</h2>
				<cfif variables.action EQ "checkIds">
					<cfif arrayLen(variables.uniqueIds) EQ 0>
						<div class="alert alert-warning" role="alert">Enter at least one container unique id.</div>
					<cfelse>
						<cfif variables.tooMany>
							<div class="alert alert-warning" role="alert">#arrayLen(variables.uniqueIds)# ids were entered; at most #MAX_CLONES# clones can be made at a time.</div>
						</cfif>
						<table class="table table-responsive d-md-table table-sm">
							<caption class="sr-only">Check of the containers entered</caption>
							<thead>
								<tr>
									<th scope="col">Container Unique ID</th>
									<th scope="col">Container Type</th>
									<th scope="col">Check</th>
								</tr>
							</thead>
							<tbody>
								<cfloop array="#variables.check.results#" index="variables.result">
									<tr>
										<td>#encodeForHtml(variables.result.unique_id)#</td>
										<td>#encodeForHtml(variables.result.container_type)#</td>
										<cfif len(variables.result.problem) EQ 0>
											<td class="text-success">OK</td>
										<cfelse>
											<td class="text-danger">#encodeForHtml(variables.result.problem)#</td>
										</cfif>
									</tr>
								</cfloop>
							</tbody>
						</table>
					</cfif>
					<cfif variables.mayCreate>
						<p>All #arrayLen(variables.uniqueIds)# containers can be used.  Creating the clones removes record #variables.record.collection_object_id#.</p>
						<form name="createClones" id="createClonesForm" method="post" action="/Bulkloader/cloneWithBarcodes.cfm" class="mb-3">
							<input type="hidden" name="action" value="createClones">
							<input type="hidden" name="collection_object_id" value="#variables.record.collection_object_id#">
							<input type="hidden" name="unique_ids" value="#encodeForHtmlAttribute(arrayToList(variables.uniqueIds, chr(10)))#">
							<input type="hidden" name="enteredby" value="#encodeForHtmlAttribute(variables.enteredby)#">
							<input type="hidden" name="accn" value="#encodeForHtmlAttribute(variables.accn)#">
							<button type="submit" class="btn btn-xs btn-primary">Create #arrayLen(variables.uniqueIds)# Clones</button>
						</form>
						<p class="mb-1">Or change the list and check it again:</p>
					<cfelseif arrayLen(variables.uniqueIds) GT 0>
						<p>Correct the ids marked above and check again.</p>
					</cfif>
				</cfif>
				<form name="checkIds" id="checkIdsForm" method="post" action="/Bulkloader/cloneWithBarcodes.cfm">
					<input type="hidden" name="action" value="checkIds">
					<input type="hidden" name="collection_object_id" value="#variables.record.collection_object_id#">
					<input type="hidden" name="enteredby" value="#encodeForHtmlAttribute(variables.enteredby)#">
					<input type="hidden" name="accn" value="#encodeForHtmlAttribute(variables.accn)#">
					<label for="unique_ids" class="data-entry-label">Container Unique IDs, one for each clone</label>
					<textarea name="unique_ids" id="unique_ids" rows="8" class="data-entry-textarea w-100 mb-1" aria-describedby="uniqueIdsHelp" required>#encodeForHtml(form.unique_ids)#</textarea>
					<small id="uniqueIdsHelp" class="form-text text-secondary mt-0 mb-2">Type or scan the ids, separated by commas, spaces or line breaks, or add them with Pick a Container.  Nothing is changed until Create Clones.</small>
					<button type="button" class="btn btn-xs btn-secondary mb-2" onClick="addPickedContainer('unique_ids', 'pickContainerFeedback');">Pick a Container</button>
					<button type="submit" class="btn btn-xs btn-primary mb-2">Check Containers</button>
					<output id="pickContainerFeedback" class="d-block small" aria-live="polite"></output>
				</form>
			</div>
		</section>
	</cfif>
</main>
<script>
	/** Opens the container picker and adds the unique id of the container chosen to the end of a
	 * list of container unique ids, on a line of its own, unless the list already has it.
	 *
	 * @param listControlId the id of the textarea holding the list, without a leading #.
	 * @param feedbackId the id of an element for messages, without a leading #.
	 */
	function addPickedContainer(listControlId, feedbackId) {
		var feedback = $('##' + feedbackId);
		feedback.text('');
		openContainerPickerDialog({
			mode: 'find',
			dialogTitle: 'Pick a Container to Clone Into',
			onSelect: function(selectedId, selectedLabel, wrapper, controls, selectedItem) {
				wrapper.dialog('close');
				var uniqueId = (selectedItem && selectedItem.barcode) ? $.trim(selectedItem.barcode) : '';
				var list = $('##' + listControlId);
				if (uniqueId === '') {
					feedback.text('The container picked, ' + selectedLabel + ', has no unique id, so a part cannot be placed in it by the bulkloader.');
				} else {
					var entered = list.val().split(/[,\s]+/);
					if (entered.indexOf(uniqueId) >= 0) {
						feedback.text(uniqueId + ' is already in the list.');
					} else {
						var text = list.val().replace(/\s+$/, '');
						list.val(text === '' ? uniqueId : text + '\n' + uniqueId);
						feedback.text('Added ' + uniqueId + '.');
					}
				}
				list.focus();
			}
		});
	}
</script>
</cfoutput>
<cfinclude template="/shared/_footer.cfm">
