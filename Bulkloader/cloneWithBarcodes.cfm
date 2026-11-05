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
<cfinclude template="/containers/component/public.cfc" runOnce="true"><!--- for validateContainerPlacement --->

<!--- Bulkloader rows with ids up to this are the Data Entry templates, one per collection, as
	MAXTEMPLATE in /DataEntry.cfm; they are never offered for cloning. --->
<cfset MAXTEMPLATE = 14>
<cfset MAX_LISTED_RECORDS = 500>
<cfset MAX_CLONES = 100>
<!--- Entered By lists users with fewer records only when Show all users is ticked. --->
<cfset ENTEREDBY_MIN_RECORDS = 1>
<!--- What becomes of parts after the first: kept on the first clone only, kept on every clone, or removed from every clone. --->
<cfset OTHER_PARTS_CHOICES = "first,all,none">
<!--- What each choice does to the other parts, shown on the record's summary. --->
<cfset OTHER_PARTS_ACTIONS = {
	"first" = "Kept on the first clone only; removed from the other clones.",
	"all" = "Kept on every clone, in the same containers as the original.",
	"none" = "Removed; no bulkloader record will have them, and they will not be loaded."
}>
<cfset OTHER_PARTS_NO_ACTION = "Choose below what becomes of them.">
<!--- Bulkloader columns that describe a part after the first, as PART_NAME_2 or PART_2_ATT_NAME_1; the
	part number is the first group of digits. --->
<cfset OTHER_PART_COLUMN_PATTERN = "^(PART_NAME|PRESERV_METHOD|PART_CONDITION|PART_CONTAINER_UNIQUE_ID|PART_CONTAINER_NAME|PART_LOT_COUNT|PART_LOT_CNT_MOD|PART_DISPOSITION|PART_REMARK)_([0-9]+)$|^PART_([0-9]+)_ATT_">

<cfparam name="url.action" default="">
<cfparam name="form.action" default="">
<cfparam name="url.enteredby" default="">
<cfparam name="url.accn" default="">
<cfparam name="url.colln" default="">
<cfparam name="url.collection_object_id" default="">
<cfparam name="form.enteredby" default="">
<cfparam name="form.accn" default="">
<cfparam name="form.colln" default="">
<cfparam name="form.collection_object_id" default="">
<cfparam name="form.unique_ids" default="">
<cfparam name="form.other_parts" default="">

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
<cfset variables.colln = url.colln>
<cfset variables.collection_object_id = url.collection_object_id>
<cfif cgi.request_method EQ "POST">
	<cfset variables.enteredby = form.enteredby>
	<cfset variables.accn = form.accn>
	<cfset variables.colln = form.colln>
	<cfset variables.collection_object_id = form.collection_object_id>
</cfif>
<!--- Drops the empty value of the All option, should it come with others. --->
<cfset variables.enteredby = arrayToList(listToArray(variables.enteredby))>
<cfset variables.accn = arrayToList(listToArray(variables.accn))>
<cfset variables.colln = arrayToList(listToArray(variables.colln))>

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
<cfset variables.filterParams = "enteredby=#encodeForUrl(variables.enteredby)#&accn=#encodeForUrl(variables.accn)#&colln=#encodeForUrl(variables.colln)#">

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
	<cfset var n = 0>
	<cfquery name="getRecord" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getRecord_result">
		SELECT
			collection_object_id, institution_acronym, collection_cde, cat_num, taxon_name, spec_locality,
			part_name_1, preserv_method_1, part_lot_count_1, part_container_unique_id_1,
			<cfloop from="2" to="12" index="n">part_name_#n#, </cfloop>
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
	otherParts the parts of a record after the first.

	@param record a query from getCloneableRecord.
	@return an array of structures of number and part_name, one for each part after the first.
--->
<cffunction name="otherParts" returntype="array" output="false">
	<cfargument name="record" type="query" required="yes">

	<cfset var parts = []>
	<cfset var n = 0>
	<cfloop from="2" to="12" index="n">
		<cfif len(arguments.record["part_name_#n#"][1]) GT 0>
			<cfset arrayAppend(parts, { number = n, part_name = arguments.record["part_name_#n#"][1] })>
		</cfif>
	</cfloop>
	<cfreturn parts>
</cffunction>

<!---
	otherPartsForClone what a clone does with the other parts under an Other parts choice.

	@param choice the choice, one of OTHER_PARTS_CHOICES, or anything else for none made.
	@param cloneNumber the clone's position in the list of containers.
	@return Kept, Removed, or a note that a choice is needed.
--->
<cffunction name="otherPartsForClone" returntype="string" output="false">
	<cfargument name="choice" type="string" required="yes">
	<cfargument name="cloneNumber" type="numeric" required="yes">

	<cfif arguments.choice EQ "all" OR (arguments.choice EQ "first" AND arguments.cloneNumber EQ 1)>
		<cfreturn "Kept">
	<cfelseif arguments.choice EQ "first" OR arguments.choice EQ "none">
		<cfreturn "Removed">
	</cfif>
	<cfreturn "Choose an option">
</cffunction>

<!---
	isOtherPartColumn test whether a bulkloader column describes a part after the first.

	@param columnName the column name, in upper case.
	@return true for a column of part 2 or later, its attributes included.
--->
<cffunction name="isOtherPartColumn" returntype="boolean" output="false">
	<cfargument name="columnName" type="string" required="yes">

	<cfset var found = REFind(OTHER_PART_COLUMN_PATTERN, arguments.columnName, 1, true)>
	<cfset var i = 0>
	<cfif found.pos[1] EQ 0>
		<cfreturn false>
	</cfif>
	<cfloop from="2" to="#arrayLen(found.pos)#" index="i">
		<cfif found.pos[i] GT 0 AND isNumeric(mid(arguments.columnName, found.pos[i], found.len[i]))>
			<cfreturn val(mid(arguments.columnName, found.pos[i], found.len[i])) GE 2>
		</cfif>
	</cfloop>
	<cfreturn false>
</cffunction>

<!---
	parseUniqueIds split the entered container unique ids, separated by commas or line breaks.  A unique
	id may contain spaces, so spaces separate nothing; those around an id are trimmed.

	@param text the text entered.
	@return an array of the ids, in the order entered.
--->
<cffunction name="parseUniqueIds" returntype="array" output="false">
	<cfargument name="text" type="string" required="yes">

	<cfset var ids = []>
	<cfset var part = "">
	<cfloop list="#arguments.text#" delimiters=",#chr(10)##chr(13)#" index="part">
		<cfif len(trim(part)) GT 0>
			<cfset arrayAppend(ids, trim(part))>
		</cfif>
	</cfloop>
	<cfreturn ids>
</cffunction>

<!---
	checkUniqueIds check that each id is a container a part can be placed in, as the bulkloader will
	when the clones are loaded, that no id is entered twice, and that the placement rules allow a
	collection object in the container.

	The part's own collection object container is made only when a clone is loaded, so, as in
	tools/BulkloadNewParts.cfm, an existing collection object container of the record's institution
	stands in for it when the placement rules are applied.  A placement the rules block is a problem;
	placement warnings are shown and do not stop the clones.

	@param uniqueIds an array of container unique ids.
	@param institutionAcronym the institution of the record being cloned.
	@return a structure of results, an array of structures of unique_id, container_type, problem
		(empty for a usable container), placement (the placement rules' result, or an empty
		structure where they were not applied) and placementJson (that result as JSON); and problemCount.
--->
<cffunction name="checkUniqueIds" returntype="struct" output="false">
	<cfargument name="uniqueIds" type="array" required="yes">
	<cfargument name="institutionAcronym" type="string" required="yes">

	<cfset var result = { results = [], problemCount = 0 }>
	<cfset var getContainers = "">
	<cfset var getStandIn = "">
	<cfset var containers = structNew()>
	<cfset var seen = structNew()>
	<cfset var uniqueId = "">
	<cfset var entry = "">
	<cfset var placement = "">

	<cfif arrayLen(arguments.uniqueIds) GT 0>
		<cfquery name="getContainers" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getContainers_result">
			SELECT container_id, barcode, container_type
			FROM container
			WHERE barcode IN (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arrayToList(arguments.uniqueIds, chr(31))#" list="yes" separator="#chr(31)#">)
		</cfquery>
		<cfloop query="getContainers">
			<cfset containers[getContainers.barcode] = { container_id = getContainers.container_id, container_type = getContainers.container_type }>
		</cfloop>
		<!--- Unlocked and without dimensions, as the new part's container will be, so that the stand in
			brings no lock or fit problem of its own. --->
		<cfquery name="getStandIn" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getStandIn_result">
			SELECT container_id
			FROM container
			WHERE
				container_type = 'collection object'
				AND institution_acronym = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.institutionAcronym#">
				AND NVL(locked_position, 0) = 0
				AND height IS NULL AND length IS NULL AND width IS NULL
				AND ROWNUM = 1
		</cfquery>
	</cfif>
	<cfloop array="#arguments.uniqueIds#" index="uniqueId">
		<cfset entry = { unique_id = uniqueId, container_type = "", problem = "", placement = structNew(), placementJson = "" }>
		<cfif structKeyExists(seen, uniqueId)>
			<cfset entry.problem = "Entered more than once.">
		<cfelseif NOT structKeyExists(containers, uniqueId)>
			<cfset entry.problem = "No container has this unique id.">
		<cfelse>
			<cfset entry.container_type = containers[uniqueId].container_type>
			<!--- Every label is refused, as the placement rules and the container move trigger refuse
				them; a cryovial is identified by its own barcode, not by a label. --->
			<cfif findNoCase("label", entry.container_type) GT 0>
				<cfset entry.problem = "This container is a label, which a part cannot be placed in.">
			<cfelseif getStandIn.recordcount GT 0>
				<cfset placement = validateContainerPlacement(child_container_id=getStandIn.container_id, proposed_parent_container_id=containers[uniqueId].container_id)>
				<!--- The JSON is kept as given for the badges, whose keys are lower case. --->
				<cfif isSimpleValue(placement)>
					<cfset entry.placementJson = placement>
					<cfset placement = deserializeJSON(placement)>
				<cfelse>
					<cfset entry.placementJson = serializeJSON(placement)>
				</cfif>
				<cfset entry.placement = placement>
				<cfif placement.severity EQ "block">
					<cfset entry.problem = "The placement rules do not allow a part in this container: #arrayToList(placement.blocks, ' ')#">
				</cfif>
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
			<p>
				This page replaces a record waiting in the bulkloader (entered in Data Entry and not yet loaded) with a copy
				for each of several containers, so that each container gets its own cataloged item when the copies are loaded.
				Only the first part of the record is placed in the containers.
			</p>
			<ol>
				<li>Find and choose the record to clone.</li>
				<li>
					Enter the unique ids of the containers, one for each copy: type them, scan them, or add them with Pick and
					Add a Container.  If the record has other parts, choose what becomes of them.
				</li>
				<li>Check Containers, then Create Clones.  The copies are added to the bulkloader and the original is removed.</li>
			</ol>
			<p>Nothing is cataloged, and no container changed, until the copies are loaded.  Open the sections below for more.</p>

			<details class="border rounded bg-light px-3 py-2 mb-2">
				<summary class="font-weight-bold">Splitting a lot entered in Data Entry among several containers</summary>
				<p class="mt-2">
					Use this when a record you have entered describes material held in several containers, for example a lot
					divided among several jars, or tissue samples in several cryovials.
				</p>
				<ol>
					<li>Under Find the record to clone, choose whose records to list, and optionally accessions or collections, then List Records.</li>
					<li>Choose the record from the list with its Clone button.</li>
					<li>
						Enter the container unique ids, one for each copy you want.  Type them, separated by commas or line
						breaks (a unique id can contain spaces); scan them with a barcode scanner that ends each scan with a
						line break; or use Pick and Add a Container, as many times as needed, to find a container and add its
						unique id to the list.  The three can be mixed.
					</li>
					<li>If the record has other parts, choose what becomes of them (see Records with more than one part).</li>
					<li>Check Containers.  When every container passes, Create Clones.</li>
					<li>
						Open each clone in Data Entry from the list of new records, and correct anything that should differ between
						them, such as the catalog number and the first part's count, before the clones are loaded.
					</li>
				</ol>
			</details>

			<details class="border rounded bg-light px-3 py-2 mb-2">
				<summary class="font-weight-bold">Taking specimens out of a jar that is one part of a cataloged item</summary>
				<p class="mt-2">
					Use this to take a few specimens out of a jar that is one of several parts of a cataloged item, and make each
					a cataloged item of its own.
				</p>
				<ol>
					<li>
						Open the cataloged item's record and use Catalog/Clone, Clone into Bulkloader, to copy it into the
						bulkloader.  Make the part for the jar the first part of that record in Data Entry.
					</li>
					<li>Find and choose that record here, and enter a container for each specimen.</li>
					<li>Under Other parts, choose Remove them; no bulkloader record will have them, so each clone has only the specimen's part.</li>
					<li>Check Containers and Create Clones, then give each clone its own catalog number and count in Data Entry before loading.</li>
				</ol>
			</details>

			<details class="border rounded bg-light px-3 py-2 mb-2">
				<summary class="font-weight-bold">Records with more than one part</summary>
				<p class="mt-2">
					This page works best for records with one part.  Only the first part, the first row of the Parts table in
					Data Entry, is placed in the containers you enter.  If the record has other parts, choose what becomes of them:
				</p>
				<ul>
					<li>
						<strong>Keep them on the first clone only.</strong>  The first clone, for the first container in your list,
						keeps the other parts exactly as they are; they are removed from the other clones.  Use this when the first
						part is split among containers but the other parts, such as a skin or skeleton, stay with one cataloged item.
					</li>
					<li>
						<strong>Keep them on every clone.</strong>  Every clone has every part, with the same count and the same
						Container Unique ID, so each clone places those parts in the same containers as the original.  Use this only
						when the material of the other parts is split among the containers too, and edit those parts in each clone in
						Data Entry before the clones are loaded.
					</li>
					<li>
						<strong>Remove them; no bulkloader record will have them.</strong>  Each clone has only the first part,
						and as the original is removed too, the other parts are left in no record in the bulkloader and are not
						loaded.  Use this to take specimens out of a jar that is one part of a cataloged item (see the section
						above), where the other parts are already cataloged.
					</li>
				</ul>
			</details>

			<details class="border rounded bg-light px-3 py-2 mb-2">
				<summary class="font-weight-bold">What the clones contain</summary>
				<ul class="mt-2">
					<li>
						Each clone is a copy of the original record, with its own record number, except for the Container Unique ID
						of its first part, which is one of the containers you entered, and any other parts you chose to remove.
					</li>
					<li>
						Clones keep the original's catalog number.  A catalog number can be used only once, so if the original has
						one, give each clone its own in Data Entry before the clones are loaded.
					</li>
					<li>
						The first part's count is copied too: a lot of 10 split among 3 jars gives 3 clones that each say 10.
						Correct each clone's count in Data Entry before the clones are loaded.
					</li>
					<li>
						Clones keep the original's status.  If the original was marked to load, so are the clones; if it was waiting
						for changes, so are they.
					</li>
					<li>The original record is removed from the bulkloader when the clones are made.  This cannot be undone from this page.</li>
				</ul>
			</details>

			<details class="border rounded bg-light px-3 py-2 mb-2">
				<summary class="font-weight-bold">How a clone is linked to its container</summary>
				<p class="mt-2">
					All of the work on this page is done in the bulkloader.  The record you clone, and the clones made from it, are
					records waiting there, not cataloged items, and no cataloged item, part or container is created or changed here.
				</p>
				<ol>
					<li>
						<strong>When the clones are made</strong>, each container's unique id is entered as the Container Unique ID
						of its clone's first part, as if you had typed it in Data Entry.  Nothing is done to the container itself,
						and nothing reserves it for the clone.
					</li>
					<li>
						<strong>When the clone is checked</strong> before loading, the unique id must still belong to a container.
						It is checked again because the container may have changed since the clone was made.
						The placement rules shown by Check Containers are not checked again then.
					</li>
					<li>
						<strong>When the clone is loaded</strong>, its first part is created and placed in that container, dated the
						day it was loaded, just as for any part entered in Data Entry with a Container Unique ID.
					</li>
				</ol>
			</details>

			<details class="border rounded bg-light px-3 py-2 mb-3">
				<summary class="font-weight-bold">Which records and containers can be used</summary>
				<ul class="mt-2">
					<li>
						A container unique id must belong to a container already in MCZbase.
						For a cryovial, use the cryovial's own unique id, the barcode on the vial.
					</li>
					<li>
						Check Containers also applies the container placement rules used on the container pages to a part placed
						in each container, and shows the result as a badge in the Placement column.  A placement the rules block,
						such as into a collection object or a container of another institution, stops Create Clones.  A placement
						warning, such as a container that is not expected to hold specimens directly, or a single specimen
						container that already holds one, is for your information only; open the badge to read it.
					</li>
					<li>You can clone your own records, and if you manage a collection, the records of its data entry users.</li>
					<li>The Data Entry templates are not offered.</li>
					<li>At most #MAX_CLONES# clones can be made at a time.</li>
				</ul>
			</details>
		</div>
	</section>

	<!------------------------------------------------------------------------------------------>
	<cfif variables.action EQ "entryPoint">
		<!--- One row per combination of entered by, accession and collection, from which the page counts the
			records each choice would list given the choices in the other lists.  Counts leave out the Data
			Entry templates, which are never offered. --->
		<cfquery name="getRecordGroups" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getRecordGroups_result">
			SELECT enteredby, accn, institution_acronym, collection_cde, count(*) AS record_count
			FROM bulkloader
			WHERE
				enteredby IN (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.permittedUsers#" list="yes">)
				AND collection_object_id > <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#MAXTEMPLATE#">
			GROUP BY enteredby, accn, institution_acronym, collection_cde
		</cfquery>
		<cfset variables.userRecordCounts = {}>
		<cfset variables.accnRecordCounts = {}>
		<cfset variables.collnRecordCounts = {}>
		<cfloop query="getRecordGroups">
			<cfset variables.groupUser = lcase(getRecordGroups.enteredby)>
			<cfset variables.groupColln = "#getRecordGroups.institution_acronym#:#getRecordGroups.collection_cde#">
			<cfif NOT structKeyExists(variables.userRecordCounts, variables.groupUser)>
				<cfset variables.userRecordCounts[variables.groupUser] = 0>
			</cfif>
			<cfset variables.userRecordCounts[variables.groupUser] = variables.userRecordCounts[variables.groupUser] + getRecordGroups.record_count>
			<cfif len(getRecordGroups.accn) GT 0>
				<cfif NOT structKeyExists(variables.accnRecordCounts, getRecordGroups.accn)>
					<cfset variables.accnRecordCounts[getRecordGroups.accn] = 0>
				</cfif>
				<cfset variables.accnRecordCounts[getRecordGroups.accn] = variables.accnRecordCounts[getRecordGroups.accn] + getRecordGroups.record_count>
			</cfif>
			<cfif NOT structKeyExists(variables.collnRecordCounts, variables.groupColln)>
				<cfset variables.collnRecordCounts[variables.groupColln] = 0>
			</cfif>
			<cfset variables.collnRecordCounts[variables.groupColln] = variables.collnRecordCounts[variables.groupColln] + getRecordGroups.record_count>
		</cfloop>
		<!--- Every permitted user is listed, with 0 for those not in the counts. --->
		<cfset variables.usersWithoutRecords = 0>
		<cfset variables.sortedUsers = listSort(variables.permittedUsers, "textnocase")>
		<cfloop list="#variables.sortedUsers#" index="variables.permittedUser">
			<cfif NOT structKeyExists(variables.userRecordCounts, lcase(variables.permittedUser))>
				<cfset variables.userRecordCounts[lcase(variables.permittedUser)] = 0>
			</cfif>
			<cfif variables.userRecordCounts[lcase(variables.permittedUser)] LT ENTEREDBY_MIN_RECORDS>
				<cfset variables.usersWithoutRecords = variables.usersWithoutRecords + 1>
			</cfif>
		</cfloop>
		<cfset variables.sortedAccns = listSort(structKeyList(variables.accnRecordCounts, chr(31)), "textnocase", "asc", chr(31))>
		<cfset variables.sortedCollns = listSort(structKeyList(variables.collnRecordCounts, chr(31)), "textnocase", "asc", chr(31))>
		<!--- Coming back from Change Search, the earlier choices are selected again. --->
		<cfset variables.allUsersSelected = "">
		<cfif len(variables.enteredby) EQ 0>
			<cfset variables.allUsersSelected = "selected">
		</cfif>
		<cfset variables.allAccnsSelected = "">
		<cfif len(variables.accn) EQ 0>
			<cfset variables.allAccnsSelected = "selected">
		</cfif>
		<cfset variables.allCollnsSelected = "">
		<cfif len(variables.colln) EQ 0>
			<cfset variables.allCollnsSelected = "selected">
		</cfif>
		<section class="row mx-0" role="search" aria-labelledby="findHeading">
			<div class="col-12 col-xl-10 border rounded px-3 py-2 mb-4">
				<h2 class="h3" id="findHeading">1. Find the record to clone</h2>
				<p class="mb-2">
					Pick any of entered by, accession or collection, or leave All.  Each shows how many records in the bulkloader
					it would list with the choices made in the other two; hold Ctrl (or &##8984; on a Mac) to pick more than one.
				</p>
				<form name="findRecords" id="findRecords" method="get" action="/Bulkloader/cloneWithBarcodes.cfm">
					<input type="hidden" name="action" value="listRecords">
					<div class="form-row">
						<div class="col-12 col-md-4 mb-2">
							<label for="enteredby" class="data-entry-label">Entered By</label>
							<select name="enteredby" id="enteredby" multiple size="10" class="data-entry-select" onChange="selectAllOrSome(this); updateSelectionCounts(FIND_SELECTS, findRecordGroups, 'findCounts', ['listRecordsButton']);">
								<option value="" data-all="true" #variables.allUsersSelected#>All</option>
								<cfloop list="#variables.sortedUsers#" index="variables.permittedUser">
									<cfset variables.selected = "">
									<cfif listFindNoCase(variables.enteredby, variables.permittedUser) GT 0>
										<cfset variables.selected = "selected">
									</cfif>
									<option value="#encodeForHtml(variables.permittedUser)#" data-match="#encodeForHtml(lcase(variables.permittedUser))#" data-label="#encodeForHtml(variables.permittedUser)#" data-record-count="#variables.userRecordCounts[lcase(variables.permittedUser)]#" #variables.selected#>#encodeForHtml(variables.permittedUser)# (#variables.userRecordCounts[lcase(variables.permittedUser)]#)</option>
								</cfloop>
							</select>
							<cfif variables.usersWithoutRecords GT 0>
								<div class="form-check">
									<input type="checkbox" class="form-check-input" id="showAllEnteredBy" onChange="showOptionsByRecordCount('enteredby', this.checked, #ENTEREDBY_MIN_RECORDS#); selectAllOrSome($('##enteredby')[0]); updateSelectionCounts(FIND_SELECTS, findRecordGroups, 'findCounts', ['listRecordsButton']);">
									<label for="showAllEnteredBy" class="form-check-label small">Show all users (#variables.usersWithoutRecords# with no records)</label>
								</div>
							</cfif>
						</div>
						<div class="col-12 col-md-4 mb-2">
							<label for="accn" class="data-entry-label">Accession</label>
							<select name="accn" id="accn" multiple size="10" class="data-entry-select" onChange="selectAllOrSome(this); updateSelectionCounts(FIND_SELECTS, findRecordGroups, 'findCounts', ['listRecordsButton']);">
								<option value="" data-all="true" #variables.allAccnsSelected#>All</option>
								<cfloop list="#variables.sortedAccns#" index="variables.accnOption" delimiters="#chr(31)#">
									<cfset variables.selected = "">
									<cfif listFind(variables.accn, variables.accnOption) GT 0>
										<cfset variables.selected = "selected">
									</cfif>
									<option value="#encodeForHtml(variables.accnOption)#" data-match="#encodeForHtml(variables.accnOption)#" data-label="#encodeForHtml(variables.accnOption)#" #variables.selected#>#encodeForHtml(variables.accnOption)# (#variables.accnRecordCounts[variables.accnOption]#)</option>
								</cfloop>
							</select>
						</div>
						<div class="col-12 col-md-4 mb-2">
							<label for="colln" class="data-entry-label">Collection</label>
							<select name="colln" id="colln" multiple size="10" class="data-entry-select" onChange="selectAllOrSome(this); updateSelectionCounts(FIND_SELECTS, findRecordGroups, 'findCounts', ['listRecordsButton']);">
								<option value="" data-all="true" #variables.allCollnsSelected#>All</option>
								<cfloop list="#variables.sortedCollns#" index="variables.collnOption" delimiters="#chr(31)#">
									<cfset variables.selected = "">
									<cfif listFind(variables.colln, variables.collnOption) GT 0>
										<cfset variables.selected = "selected">
									</cfif>
									<option value="#encodeForHtml(variables.collnOption)#" data-match="#encodeForHtml(variables.collnOption)#" data-label="#encodeForHtml(variables.collnOption)#" #variables.selected#>#encodeForHtml(variables.collnOption)# (#variables.collnRecordCounts[variables.collnOption]#)</option>
								</cfloop>
							</select>
						</div>
					</div>
					<button type="submit" id="listRecordsButton" class="btn btn-xs btn-primary mb-2">List Records</button>
					<output id="findCounts" class="d-inline-block small ml-2" aria-live="polite"></output>
				</form>
				<script>
					// Built here rather than with serializeJSON, which would turn accession numbers into numbers.
					var FIND_SELECTS = ["enteredby", "accn", "colln"];
					var findRecordGroups = [
						<cfloop query="getRecordGroups">
							{ enteredby: '#encodeForJavaScript(lcase(getRecordGroups.enteredby))#', accn: '#encodeForJavaScript(getRecordGroups.accn)#', colln: '#encodeForJavaScript(getRecordGroups.institution_acronym & ":" & getRecordGroups.collection_cde)#', count: #getRecordGroups.record_count# }<cfif getRecordGroups.currentRow LT getRecordGroups.recordcount>,</cfif>
						</cfloop>
					];
					$(document).ready(function() {
						showOptionsByRecordCount('enteredby', false, #ENTEREDBY_MIN_RECORDS#);
						FIND_SELECTS.forEach(function(selectId) {
							selectAllOrSome($("##" + selectId)[0]);
						});
						updateSelectionCounts(FIND_SELECTS, findRecordGroups, 'findCounts', ['listRecordsButton']);
					});
				</script>
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
				<cfif len(variables.colln) GT 0>
					AND institution_acronym || ':' || collection_cde IN (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.colln#" list="yes">)
				</cfif>
			ORDER BY collection_object_id
		</cfquery>
		<section class="row mx-0" aria-labelledby="listHeading">
			<div class="col-12 mb-4">
				<h2 class="h3" id="listHeading">2. Choose the record to clone (#min(getRecords.recordcount, MAX_LISTED_RECORDS)# records)</h2>
				<p>
					<a href="/Bulkloader/cloneWithBarcodes.cfm?#variables.filterParams#" class="btn btn-xs btn-secondary">Change Search</a>
					<a href="/Bulkloader/cloneWithBarcodes.cfm" class="btn btn-xs btn-warning">New Search</a>
				</p>
				<cfif getRecords.recordcount GT MAX_LISTED_RECORDS>
					<div class="alert alert-warning" role="alert">
						Only the first #MAX_LISTED_RECORDS# matching records are shown; choose users, accessions or collections to narrow the list.
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
			<cfset variables.otherParts = otherParts(variables.record)>
			<cfset variables.otherPartsText = "">
			<cfloop array="#variables.otherParts#" index="variables.otherPart">
				<cfset variables.otherPartsText = listAppend(variables.otherPartsText, " #variables.otherPart.number#: #variables.otherPart.part_name#", ";")>
			</cfloop>
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
						<cfif arrayLen(variables.otherParts) GT 0>
							<cfset variables.otherPartsAction = OTHER_PARTS_NO_ACTION>
							<cfif structKeyExists(OTHER_PARTS_ACTIONS, form.other_parts)>
								<cfset variables.otherPartsAction = OTHER_PARTS_ACTIONS[form.other_parts]>
							</cfif>
							<dt class="col-sm-3">Other Parts</dt>
							<dd class="col-sm-9">
								#encodeForHtml(trim(variables.otherPartsText))#
								<!--- The prefix stays put; showOtherPartsAction replaces only the action. --->
								<span class="d-block font-weight-bold bg-light border border-dark rounded px-2 py-1 mt-1" aria-live="polite">Other Parts: <span id="otherPartsAction">#encodeForHtml(variables.otherPartsAction)#</span></span>
							</dd>
						</cfif>
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
						<cfif isNumeric(variables.record.part_lot_count_1) AND variables.record.part_lot_count_1 GT 1>
							<div class="alert alert-warning mb-1" role="alert">Every clone will have the first part's count of #encodeForHtml(variables.record.part_lot_count_1)#; correct each clone's count in Data Entry before loading.</div>
						</cfif>
						<cfif arrayLen(variables.otherParts) GT 0>
							<div class="alert alert-warning mb-1" role="alert">This record has more than one part.  Only the first part goes into the containers you enter; choose below what becomes of the other parts, and check each clone's parts in Data Entry before loading.</div>
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
			<cfset variables.check = checkUniqueIds(variables.uniqueIds, variables.record.institution_acronym)>
		</cfif>
		<!--- A record with more than one part needs a choice of what becomes of the others. --->
		<cfset variables.otherPartsChoice = "all">
		<cfset variables.otherPartsChoiceMissing = false>
		<cfif arrayLen(variables.otherParts) GT 0>
			<cfset variables.otherPartsChoice = form.other_parts>
			<cfif listFind(OTHER_PARTS_CHOICES, variables.otherPartsChoice) EQ 0>
				<cfset variables.otherPartsChoiceMissing = true>
			</cfif>
		</cfif>
		<cfset variables.mayCreate = false>
		<cfif arrayLen(variables.uniqueIds) GT 0 AND variables.check.problemCount EQ 0 AND NOT variables.tooMany AND NOT variables.otherPartsChoiceMissing>
			<cfset variables.mayCreate = true>
		</cfif>
		<!--- A failed recheck while creating shows the check and the form again. --->
		<cfif variables.action EQ "createClones" AND NOT variables.mayCreate>
			<cfset variables.action = "checkIds">
		</cfif>
	</cfif>

	<!------------------------------------------------------------------------------------------>
	<cfif variables.action EQ "createClones">
		<!--- Every column but the record id and the first part's container is copied from the original,
			except that the columns of later parts are left empty on the clones that do not keep them.
			Column names come from the data dictionary; they cannot be bound. --->
		<cfset variables.tableColumns = stagingTableColumns("BULKLOADER")>
		<cfset variables.copiedColumns = "">
		<cfset variables.otherPartColumns = structNew()>
		<cfloop collection="#variables.tableColumns#" item="variables.columnName">
			<cfif listFindNoCase("COLLECTION_OBJECT_ID,PART_CONTAINER_UNIQUE_ID_1,PART_CONTAINER_NAME_1", variables.columnName) EQ 0>
				<cfset variables.copiedColumns = listAppend(variables.copiedColumns, variables.columnName)>
				<cfif isOtherPartColumn(variables.columnName)>
					<cfset variables.otherPartColumns[variables.columnName] = true>
				</cfif>
			</cfif>
		</cfloop>
		<cfset variables.newIds = []>
		<cftransaction>
			<cfloop from="1" to="#arrayLen(variables.uniqueIds)#" index="variables.cloneNumber">
				<cfset variables.uniqueId = variables.uniqueIds[variables.cloneNumber]>
				<cfset variables.keepOtherParts = true>
				<cfif variables.otherPartsChoice EQ "none" OR (variables.otherPartsChoice EQ "first" AND variables.cloneNumber GT 1)>
					<cfset variables.keepOtherParts = false>
				</cfif>
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
						NULL
						<cfloop list="#variables.copiedColumns#" index="variables.columnName">
							<cfif NOT variables.keepOtherParts AND structKeyExists(variables.otherPartColumns, variables.columnName)>
								, NULL
							<cfelse>
								, #variables.columnName#
							</cfif>
						</cfloop>
					FROM bulkloader
					WHERE collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.record.collection_object_id#">
				</cfquery>
				<cfset arrayAppend(variables.newIds, { collection_object_id = getNewId.new_id, unique_id = variables.uniqueId, keeps_other_parts = variables.keepOtherParts })>
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
							<cfif arrayLen(variables.otherParts) GT 0>
								<th scope="col">Other Parts</th>
							</cfif>
						</tr>
					</thead>
					<tbody>
						<cfloop array="#variables.newIds#" index="variables.newId">
							<tr>
								<td><a href="/DataEntry.cfm?action=editEnterData&pMode=edit&showAllUsers=#variables.mayEditOthers#&collection_object_id=#variables.newId.collection_object_id#" target="_blank">#variables.newId.collection_object_id#</a></td>
								<td>#encodeForHtml(variables.newId.unique_id)#</td>
								<cfif arrayLen(variables.otherParts) GT 0>
									<cfif variables.newId.keeps_other_parts>
										<td>Kept</td>
									<cfelse>
										<td>Removed</td>
									</cfif>
								</cfif>
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
									<th scope="col">Placement</th>
									<cfif arrayLen(variables.otherParts) GT 0>
										<th scope="col">Other Parts</th>
									</cfif>
									<th scope="col">Check</th>
								</tr>
							</thead>
							<tbody>
								<cfset variables.badges = []>
								<cfloop from="1" to="#arrayLen(variables.check.results)#" index="variables.resultNumber">
									<cfset variables.result = variables.check.results[variables.resultNumber]>
									<tr>
										<td>#encodeForHtml(variables.result.unique_id)#</td>
										<td>#encodeForHtml(variables.result.container_type)#</td>
										<td>
											<cfif structKeyExists(variables.result.placement, "severity")>
												<span id="placementBadge#variables.resultNumber#"></span>
												<cfset arrayAppend(variables.badges, { id = "placementBadge#variables.resultNumber#", placementJson = variables.result.placementJson })>
											</cfif>
										</td>
										<cfif arrayLen(variables.otherParts) GT 0>
											<!--- The row's number is its clone's, which decides what it keeps under "first". --->
											<td class="otherPartsForClone" data-clone-number="#variables.resultNumber#">#otherPartsForClone(form.other_parts, variables.resultNumber)#</td>
										</cfif>
										<cfif len(variables.result.problem) EQ 0>
											<td class="text-success">OK</td>
										<cfelse>
											<td class="text-danger">#encodeForHtml(variables.result.problem)#</td>
										</cfif>
									</tr>
								</cfloop>
							</tbody>
						</table>
						<cfif arrayLen(variables.badges) GT 0>
							<p class="small text-secondary">Placement warnings are for your information; they do not stop the clones.</p>
							<script>
								// The same placement badges as the container pages, for results worked out on the server.
								$(document).ready(function() {
									<cfloop array="#variables.badges#" index="variables.badge">
										renderPlacementWarningBadge(JSON.parse('#encodeForJavaScript(variables.badge.placementJson)#'), '#variables.badge.id#');
									</cfloop>
								});
							</script>
						</cfif>
					</cfif>
					<cfif variables.otherPartsChoiceMissing>
						<div class="alert alert-warning" role="alert">Choose what becomes of the other parts.</div>
					</cfif>
					<cfif variables.mayCreate>
						<cfset variables.otherPartsSummary = "">
						<cfif arrayLen(variables.otherParts) GT 0>
							<cfswitch expression="#variables.otherPartsChoice#">
								<cfcase value="first"><cfset variables.otherPartsSummary = "The other parts will be kept on the first clone only, for #variables.uniqueIds[1]#."></cfcase>
								<cfcase value="all"><cfset variables.otherPartsSummary = "The other parts will be kept on every clone."></cfcase>
								<cfcase value="none"><cfset variables.otherPartsSummary = "The other parts will be removed: no bulkloader record will have them, so they will not be loaded."></cfcase>
							</cfswitch>
						</cfif>
						<p>
							All #arrayLen(variables.uniqueIds)# containers can be used.  #encodeForHtml(variables.otherPartsSummary)#
							Creating the clones removes record #variables.record.collection_object_id#.
						</p>
						<form name="createClones" id="createClonesForm" method="post" action="/Bulkloader/cloneWithBarcodes.cfm" class="mb-3">
							<input type="hidden" name="action" value="createClones">
							<input type="hidden" name="collection_object_id" value="#variables.record.collection_object_id#">
							<input type="hidden" name="unique_ids" value="#encodeForHtmlAttribute(arrayToList(variables.uniqueIds, ', '))#">
							<input type="hidden" name="other_parts" id="checkedOtherParts" value="#encodeForHtmlAttribute(form.other_parts)#">
							<input type="hidden" name="enteredby" value="#encodeForHtmlAttribute(variables.enteredby)#">
							<input type="hidden" name="accn" value="#encodeForHtmlAttribute(variables.accn)#">
							<input type="hidden" name="colln" value="#encodeForHtmlAttribute(variables.colln)#">
							<button type="submit" id="createClonesButton" class="btn btn-xs btn-primary">Create #arrayLen(variables.uniqueIds)# Clones</button>
							<output id="createClonesNote" class="d-block small text-danger"></output>
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
					<input type="hidden" name="colln" value="#encodeForHtmlAttribute(variables.colln)#">
					<label for="unique_ids" class="data-entry-label">Container Unique IDs, one for each clone</label>
					<textarea name="unique_ids" id="unique_ids" rows="2" class="data-entry-textarea autogrow w-100 mb-1" aria-describedby="uniqueIdsHelp" required>#encodeForHtml(form.unique_ids)#</textarea>
					<cfif arrayLen(variables.otherParts) GT 0>
						<fieldset class="border rounded px-2 pb-1 mb-2">
							<legend class="h6 w-auto px-1 mb-0">Other parts (#encodeForHtml(trim(variables.otherPartsText))#)</legend>
							<cfloop list="#OTHER_PARTS_CHOICES#" index="variables.choice">
								<cfset variables.checked = "">
								<cfif form.other_parts EQ variables.choice>
									<cfset variables.checked = "checked">
								</cfif>
								<cfswitch expression="#variables.choice#">
									<cfcase value="first"><cfset variables.choiceLabel = "Keep them on the first clone only (the first container in the list); remove them from the others"></cfcase>
									<cfcase value="all"><cfset variables.choiceLabel = "Keep them on every clone, in the same containers as the original"></cfcase>
									<cfcase value="none"><cfset variables.choiceLabel = "Remove them; no bulkloader record will have them (each clone has only the first part)"></cfcase>
								</cfswitch>
								<div class="form-check">
									<input type="radio" class="form-check-input" name="other_parts" id="other_parts_#variables.choice#" value="#variables.choice#" #variables.checked# required data-action="#encodeForHtmlAttribute(OTHER_PARTS_ACTIONS[variables.choice])#" onChange="showOtherPartsAction(this, 'otherPartsAction', 'otherPartsForClone', 'checkedOtherParts', 'createClonesButton', 'createClonesNote');">
									<label class="form-check-label" for="other_parts_#variables.choice#">#variables.choiceLabel#</label>
								</div>
							</cfloop>
						</fieldset>
					</cfif>
					<small id="uniqueIdsHelp" class="form-text text-secondary mt-0 mb-2">Type or scan the ids, separated by commas or line breaks, or add them with Pick and Add a Container.  Nothing is changed until Create Clones.</small>
					<button type="button" class="btn btn-xs btn-secondary mb-2" onClick="addPickedContainer('unique_ids', 'pickContainerFeedback');">Pick and Add a Container</button>
					<button type="submit" class="btn btn-xs btn-primary mb-2">Check Containers</button>
					<output id="pickContainerFeedback" class="d-block small" aria-live="polite"></output>
				</form>
			</div>
		</section>
	</cfif>
</main>
<script>
	$(document).ready(function() {
		// The list grows to show every id, whether typed, scanned, picked or brought back from a check.
		$("textarea.autogrow").keyup(autogrow);
		$("textarea.autogrow").each(function() { autogrow.call(this); });
		// The container type roles from the code table, for the picker's check of a picked container.
		loadContainerTypeMetadata();
	});

	/** Shows what the chosen Other parts option will do: on the record's summary, and for each clone in
	 * the check table.  A choice other than the one the containers were checked with holds back Create
	 * Clones until they are checked again, so the clones are made as the page shows.
	 *
	 * @param radio the option chosen, carrying the description in its data-action attribute.
	 * @param summaryId the id of the element for the description, without a leading ##.
	 * @param cloneCellClass the class of the check table's Other Parts cells, each with data-clone-number.
	 * @param checkedChoiceId the id of the hidden field holding the choice checked with.
	 * @param createButtonId the id of the Create Clones button.
	 * @param noteId the id of the element for a note beside Create Clones.
	 */
	function showOtherPartsAction(radio, summaryId, cloneCellClass, checkedChoiceId, createButtonId, noteId) {
		var choice = $(radio).val();
		$('##' + summaryId).text($(radio).data('action'));
		$('.' + cloneCellClass).each(function() {
			var cloneNumber = parseInt($(this).data('clone-number'), 10);
			var kept = (choice === 'all') || (choice === 'first' && cloneNumber === 1);
			$(this).text(kept ? 'Kept' : 'Removed');
		});
		var checkedChoice = $('##' + checkedChoiceId);
		if (checkedChoice.length) {
			var changed = (checkedChoice.val() !== choice);
			$('##' + createButtonId).prop('disabled', changed);
			$('##' + noteId).text(changed ? 'The Other parts choice has changed; Check Containers again to create the clones with it.' : '');
		}
	}

	/** Opens the container picker and adds the unique id of the container chosen to the end of a
	 * comma separated list of container unique ids, unless the list already has it.
	 *
	 * @param listControlId the id of the textarea holding the list, without a leading ##.
	 * @param feedbackId the id of an element for messages, without a leading ##.
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
				var containerType = (selectedItem && selectedItem.type) ? selectedItem.type : '';
				// The roles from the code table once loaded, otherwise the copy in containers.js.
				var role = CONTAINER_TYPE_META ? getContainerTypeMeta(containerType).role : getContainerRole(containerType);
				var list = $('##' + listControlId);
				if ((role || '').toLowerCase() === 'leaf') {
					feedback.text('The container picked, ' + selectedLabel + ', is a ' + containerType + ', the container of a part of a cataloged item, which cannot hold another part.  Pick the container it is in instead.');
				} else if (uniqueId === '') {
					feedback.text('The container picked, ' + selectedLabel + ', has no unique id, so a part cannot be placed in it by the bulkloader.');
				} else {
					// Commas and line breaks separate the ids; a unique id can contain spaces.
					var entered = $.map(list.val().split(/[,\r\n]+/), function(id) { return $.trim(id); });
					if (entered.indexOf(uniqueId) >= 0) {
						feedback.text(uniqueId + ' is already in the list.');
					} else {
						var text = list.val().replace(/[,\s]+$/, '');
						list.val(text === '' ? uniqueId : text + ', ' + uniqueId);
						autogrow.call(list[0]);
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
