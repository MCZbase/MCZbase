<!---
collections/component/functions.cfc

Copyright 2026 President and Fellows of Harvard College

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
<!--- Backing methods for the Collection Panel, /collections/CollectionPanel.cfm, role curatorial_associate. --->
<cfcomponent>
<cf_rolecheck>
<cfinclude template="/shared/component/error_handler.cfc" runOnce="true">

<!---
	requireCuratorialAssociate stop a widget method for anyone without the curatorial_associate role.
--->
<cffunction name="requireCuratorialAssociate" access="private" returntype="void" output="false">
	<cfif NOT ( isdefined("session.roles") AND listfindnocase(session.roles,"curatorial_associate") ) >
		<cfthrow message="Not authorized">
	</cfif>
</cffunction>

<!---
	getLoansHtml the Collection Panel widget listing a collection's open loans that are overdue or due
	within 30 days.

	@param collection_id the collection to report on.
	@return HTML for the widget body.
--->
<cffunction name="getLoansHtml" access="remote" returntype="string" returnformat="plain">
	<cfargument name="collection_id" type="numeric" required="yes">
	<cfset var html = "">
	<cfset var openLoans = "">
	<cfset var openLoans_result = "">
	<cfset var dueLoans = "">
	<cfset var dueLoans_result = "">
	<cfset requireCuratorialAssociate()>
	<cfquery name="openLoans" datasource="uam_god" result="openLoans_result">
		SELECT
			count(*) AS ct,
			sum(CASE WHEN loan.return_due_date < trunc(sysdate) THEN 1 ELSE 0 END) AS overdue
		FROM loan
			JOIN trans ON loan.transaction_id = trans.transaction_id
		WHERE
			trans.collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.collection_id#">
			AND loan.loan_status LIKE 'open%'
	</cfquery>
	<cfquery name="dueLoans" datasource="uam_god" result="dueLoans_result">
		SELECT
			trans.transaction_id, loan.loan_number, loan.loan_type, loan.loan_status, loan.return_due_date
		FROM loan
			JOIN trans ON loan.transaction_id = trans.transaction_id
		WHERE
			trans.collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.collection_id#">
			AND loan.loan_status LIKE 'open%'
			AND loan.return_due_date < trunc(sysdate) + 30
		ORDER BY loan.return_due_date
	</cfquery>
	<cfsavecontent variable="html">
		<cfoutput>
			<p class="mb-2">
				#val(openLoans.ct)# open loans, #val(openLoans.overdue)# overdue
				<cfif val(openLoans.overdue) EQ 0><span class="badge badge-success">OK</span><cfelse><span class="badge badge-danger">Overdue</span></cfif>
			</p>
			<cfif dueLoans.recordcount GT 0>
				<details>
					<summary><strong>Overdue or due within 30 days</strong> (#dueLoans.recordcount#)</summary>
					<ul class="small mb-1">
						<cfloop query="dueLoans">
							<li><a href="/transactions/Loan.cfm?action=editLoan&transaction_id=#dueLoans.transaction_id#">#encodeForHtml(dueLoans.loan_number)#</a>
								#encodeForHtml(dueLoans.loan_type)#, #encodeForHtml(dueLoans.loan_status)#, due #dateFormat(dueLoans.return_due_date, "yyyy-mm-dd")#</li>
						</cfloop>
					</ul>
				</details>
			</cfif>
		</cfoutput>
	</cfsavecontent>
	<cfreturn html>
</cffunction>

<!---
	getBorrowsHtml the Collection Panel widget listing a collection's borrows not yet returned that are
	overdue or due within 30 days.

	@param collection_id the collection to report on.
	@return HTML for the widget body.
--->
<cffunction name="getBorrowsHtml" access="remote" returntype="string" returnformat="plain">
	<cfargument name="collection_id" type="numeric" required="yes">
	<cfset var html = "">
	<cfset var borrows = "">
	<cfset var borrows_result = "">
	<cfset var dueCount = 0>
	<cfset requireCuratorialAssociate()>
	<cfquery name="borrows" datasource="uam_god" result="borrows_result">
		SELECT
			trans.transaction_id, borrow.borrow_number, borrow.borrow_status, borrow.due_date
		FROM borrow
			JOIN trans ON borrow.transaction_id = trans.transaction_id
		WHERE
			trans.collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.collection_id#">
			AND borrow.borrow_status <> 'returned'
		ORDER BY borrow.due_date
	</cfquery>
	<cfloop query="borrows">
		<cfif isDate(borrows.due_date) AND borrows.due_date LT dateAdd("d", 30, now())>
			<cfset dueCount = dueCount + 1>
		</cfif>
	</cfloop>
	<cfsavecontent variable="html">
		<cfoutput>
			<p class="mb-2">#borrows.recordcount# borrows not returned, #dueCount# overdue or due within 30 days.</p>
			<cfif dueCount GT 0>
				<details>
					<summary><strong>Overdue or due within 30 days</strong> (#dueCount#)</summary>
					<ul class="small mb-1">
						<cfloop query="borrows">
							<cfif isDate(borrows.due_date) AND borrows.due_date LT dateAdd("d", 30, now())>
								<li><a href="/transactions/Borrow.cfm?action=edit&transaction_id=#borrows.transaction_id#">#encodeForHtml(borrows.borrow_number)#</a>
									#encodeForHtml(borrows.borrow_status)#, due #dateFormat(borrows.due_date, "yyyy-mm-dd")#</li>
							</cfif>
						</cfloop>
					</ul>
				</details>
			</cfif>
		</cfoutput>
	</cfsavecontent>
	<cfreturn html>
</cffunction>

<!---
	getEncumbrancesHtml the Collection Panel widget listing encumbrances on a collection's cataloged items
	that have expired or expire within 90 days.

	@param collection_id the collection to report on.
	@return HTML for the widget body.
--->
<cffunction name="getEncumbrancesHtml" access="remote" returntype="string" returnformat="plain">
	<cfargument name="collection_id" type="numeric" required="yes">
	<cfset var html = "">
	<cfset var encumbrances = "">
	<cfset var encumbrances_result = "">
	<cfset requireCuratorialAssociate()>
	<cfquery name="encumbrances" datasource="uam_god" result="encumbrances_result">
		SELECT
			encumbrance.encumbrance_id, encumbrance.encumbrance, encumbrance.encumbrance_action,
			encumbrance.expiration_date, count(*) AS ct
		FROM encumbrance
			JOIN coll_object_encumbrance ON encumbrance.encumbrance_id = coll_object_encumbrance.encumbrance_id
			JOIN cataloged_item ON coll_object_encumbrance.collection_object_id = cataloged_item.collection_object_id
		WHERE
			cataloged_item.collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.collection_id#">
			AND encumbrance.expiration_date < trunc(sysdate) + 90
		GROUP BY
			encumbrance.encumbrance_id, encumbrance.encumbrance, encumbrance.encumbrance_action, encumbrance.expiration_date
		ORDER BY encumbrance.expiration_date
	</cfquery>
	<cfsavecontent variable="html">
		<cfoutput>
			<p class="mb-2">#encumbrances.recordcount# encumbrances on this collection's items have expired or expire within 90 days.</p>
			<cfif encumbrances.recordcount GT 0>
				<ul class="small mb-1">
					<cfloop query="encumbrances">
						<li><a href="/encumbrances/Encumbrance.cfm?action=edit&encumbrance_id=#encumbrances.encumbrance_id#">#encodeForHtml(encumbrances.encumbrance)#</a>
							(#encodeForHtml(encumbrances.encumbrance_action)#),
							<cfif encumbrances.expiration_date LT now()>expired<cfelse>expires</cfif> #dateFormat(encumbrances.expiration_date, "yyyy-mm-dd")#,
							#encumbrances.ct# items</li>
					</cfloop>
				</ul>
			</cfif>
		</cfoutput>
	</cfsavecontent>
	<cfreturn html>
</cffunction>

<!---
	getBulkloadsHtml the Collection Panel widget summarising rows waiting in the bulkloaders for a
	collection, by bulkloader and user.  Only staging tables recording the collection, the user and a
	status are included; a status on a row is a problem found when the bulkloader checked it.

	@param collection_id the collection to report on.
	@return HTML for the widget body.
--->
<cffunction name="getBulkloadsHtml" access="remote" returntype="string" returnformat="plain">
	<cfargument name="collection_id" type="numeric" required="yes">
	<cfset var html = "">
	<cfset var collection = "">
	<cfset var collection_result = "">
	<cfset var stagingTables = "">
	<cfset var stagingTables_result = "">
	<cfset var waiting = "">
	<cfset var rows = arrayNew(1)>
	<cfset var row = "">
	<cfset var bulkloaderName = "">
	<cfset var BULKLOADERS = {
		CF_TEMP_ATTRIBUTES = { name = "Attributes", page = "/tools/BulkloadAttributes.cfm" },
		CF_TEMP_BARCODE_PARTS = { name = "Parts to Containers", page = "/tools/BulkloadPartContainer.cfm" },
		CF_TEMP_BL_RELATIONS = { name = "Relationships", page = "/tools/BulkloadRelations.cfm" },
		CF_TEMP_CITATION = { name = "Citations", page = "/tools/BulkloadCitations.cfm" },
		CF_TEMP_EDIT_PARTS = { name = "Edited Parts", page = "/tools/BulkloadEditedParts.cfm" },
		CF_TEMP_ID = { name = "Identifications", page = "/tools/BulkloadIdentification.cfm" },
		CF_TEMP_LOAN_ITEM = { name = "Loan Items", page = "/tools/BulkloadLoanItems.cfm" },
		CF_TEMP_OIDS = { name = "Other IDs", page = "/tools/BulkloadOtherId.cfm" },
		CF_TEMP_PARTS = { name = "New Parts", page = "/tools/BulkloadNewParts.cfm" }
	}>
	<cfset requireCuratorialAssociate()>
	<cfquery name="collection" datasource="uam_god" result="collection_result">
		SELECT institution_acronym, collection_cde
		FROM collection
		WHERE collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.collection_id#">
	</cfquery>
	<cfif collection.recordcount EQ 0>
		<cfreturn '<p class="text-danger mb-0">Unknown collection.</p>'>
	</cfif>
	<cfquery name="stagingTables" datasource="uam_god" result="stagingTables_result">
		SELECT table_name
		FROM user_tab_columns
		WHERE
			table_name LIKE 'CF\_TEMP\_%' ESCAPE '\'
			AND column_name IN ('INSTITUTION_ACRONYM', 'COLLECTION_CDE', 'USERNAME', 'STATUS')
		GROUP BY table_name
		HAVING count(*) = 4
		ORDER BY table_name
	</cfquery>
	<cfloop query="stagingTables">
		<!--- table names come from the data dictionary, as they can't be bound --->
		<cftry>
			<cfquery name="waiting" datasource="uam_god">
				SELECT username, count(*) AS ct, count(status) AS problems
				FROM "#stagingTables.table_name#"
				WHERE
					upper(institution_acronym) = upper(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#collection.institution_acronym#">)
					AND upper(collection_cde) = upper(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#collection.collection_cde#">)
				GROUP BY username
				ORDER BY username
			</cfquery>
			<cfloop query="waiting">
				<cfset arrayAppend(rows, { table_name = stagingTables.table_name, username = waiting.username, ct = waiting.ct, problems = waiting.problems })>
			</cfloop>
		<cfcatch></cfcatch>
		</cftry>
	</cfloop>
	<cfsavecontent variable="html">
		<cfoutput>
			<cfif arrayLen(rows) EQ 0>
				<p class="mb-0">No rows for #encodeForHtml(collection.institution_acronym)#:#encodeForHtml(collection.collection_cde)# are waiting in the bulkloaders.</p>
			<cfelse>
				<p class="mb-2">Rows for #encodeForHtml(collection.institution_acronym)#:#encodeForHtml(collection.collection_cde)# waiting in the bulkloaders. Rows with problems failed the bulkloader's checks.</p>
				<table class="table table-sm table-striped table-responsive d-xl-table small mb-1">
					<thead class="thead-light">
						<tr><th>Bulkloader</th><th>User</th><th>Rows</th><th>With problems</th></tr>
					</thead>
					<tbody>
						<cfloop array="#rows#" index="row">
							<tr>
								<td>
									<cfif structKeyExists(BULKLOADERS, row.table_name)>
										<a href="#BULKLOADERS[row.table_name].page#">#BULKLOADERS[row.table_name].name#</a>
									<cfelse>
										#encodeForHtml(row.table_name)#
									</cfif>
								</td>
								<td>#encodeForHtml(row.username)#<cfif compareNoCase(row.username, session.username) EQ 0> (you)</cfif></td>
								<td>#row.ct#</td>
								<td><cfif row.problems GT 0><span class="badge badge-danger">#row.problems#</span><cfelse>0</cfif></td>
							</tr>
						</cfloop>
					</tbody>
				</table>
			</cfif>
		</cfoutput>
	</cfsavecontent>
	<cfreturn html>
</cffunction>

<!---
	getRecentEditsHtml the Collection Panel widget showing a collection's cataloged items edited in the
	last 7 days.

	@param collection_id the collection to report on.
	@return HTML for the widget body.
--->
<cffunction name="getRecentEditsHtml" access="remote" returntype="string" returnformat="plain">
	<cfargument name="collection_id" type="numeric" required="yes">
	<cfset var html = "">
	<cfset var edits = "">
	<cfset var edits_result = "">
	<cfset var SHOWN = 20>
	<cfset requireCuratorialAssociate()>
	<cfquery name="edits" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="edits_result">
		SELECT guid, scientific_name, last_edit_date
		FROM flat
		WHERE
			collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.collection_id#">
			AND last_edit_date >= trunc(sysdate) - 7
		ORDER BY last_edit_date DESC
	</cfquery>
	<cfsavecontent variable="html">
		<cfoutput>
			<p class="mb-2">#edits.recordcount# cataloged items edited in the last 7 days.</p>
			<cfif edits.recordcount GT 0>
				<details>
					<summary><strong>Latest</strong> (up to #SHOWN#)</summary>
					<ul class="small mb-1">
						<cfloop query="edits" endrow="#SHOWN#">
							<li><a href="/guid/#encodeForUrl(edits.guid)#">#encodeForHtml(edits.guid)#</a>
								#encodeForHtml(edits.scientific_name)#, #dateTimeFormat(edits.last_edit_date, "yyyy-mm-dd HH:nn")#</li>
						</cfloop>
					</ul>
				</details>
			</cfif>
		</cfoutput>
	</cfsavecontent>
	<cfreturn html>
</cffunction>

</cfcomponent>
