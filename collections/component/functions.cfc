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
<!--- Backing methods for the Collection Panel, /collections/CollectionPanel.cfm, for the
	curatorial_associate and global_admin roles.  The component's row is curatorial_associate, which
	cf_rolecheck also lets global_admin through, and each method checks for either role. --->
<cfcomponent>
<cf_rolecheck>
<cfinclude template="/shared/component/error_handler.cfc" runOnce="true">
<cfinclude template="/shared/component/roles.cfc" runOnce="true">

<!---
	requirePanelViewer stop a widget method for anyone without the curatorial_associate or global_admin role.
--->
<cffunction name="requirePanelViewer" access="private" returntype="void" output="false">
	<cfif NOT isdefined("session.roles")>
		<cfthrow message="Not authorized">
	</cfif>
	<cfif NOT ( listfindnocase(session.roles,"curatorial_associate") OR listfindnocase(session.roles,"global_admin") )>
		<cfthrow message="Not authorized">
	</cfif>
</cffunction>

<!---
	dueItemsHtml a section of the Loans or Borrows widget listing transactions in one due date group.

	@param title the group's name.
	@param items an array of structures with href, label and detail for each transaction.
	@param badgeClass the Bootstrap badge class for the group's count.
	@return HTML for the section, empty when the group has no transactions.
--->
<cffunction name="dueItemsHtml" access="private" returntype="string" output="false">
	<cfargument name="title" type="string" required="yes">
	<cfargument name="items" type="array" required="yes">
	<cfargument name="badgeClass" type="string" required="yes">
	<cfset var html = "">
	<cfset var item = "">
	<cfif arrayLen(arguments.items) EQ 0>
		<cfreturn "">
	</cfif>
	<cfsavecontent variable="html">
		<cfoutput>
			<details class="mb-1">
				<summary><strong>#encodeForHtml(arguments.title)#</strong> <span class="badge #arguments.badgeClass#">#arrayLen(arguments.items)#</span></summary>
				<ul class="small mb-1">
					<cfloop array="#arguments.items#" index="item">
						<li><a href="#item.href#">#encodeForHtml(item.label)#</a> #encodeForHtml(item.detail)#</li>
					</cfloop>
				</ul>
			</details>
		</cfoutput>
	</cfsavecontent>
	<cfreturn html>
</cffunction>

<!---
	getLoansHtml the Collection Panel widget listing a collection's open loans that are overdue by more
	than a year, overdue, or due within 30 days, using the criteria of the loan reminder emails
	(ScheduledTasks/reminder.cfm and longtermreminder.cfm): open returnable or consumable loans, with
	open historical loans left out of those overdue by more than a year; overdue loans the emails leave
	out (other loan types, and open historical loans overdue by more than a year); and all open loans
	not overdue.

	@param collection_id the collection to report on.
	@return HTML for the widget body.
--->
<cffunction name="getLoansHtml" access="remote" returntype="string" returnformat="plain">
	<cfargument name="collection_id" type="numeric" required="yes">
	<cfset var html = "">
	<cfset var openLoans = "">
	<cfset var openLoans_result = "">
	<cfset var item = "">
	<cfset var longOverdue = arrayNew(1)>
	<cfset var overdue = arrayNew(1)>
	<cfset var dueSoon = arrayNew(1)>
	<cfset var notOverdue = arrayNew(1)>
	<cfset var noReminder = arrayNew(1)>
	<cfset requirePanelViewer()>
	<!--- days_left is the reminder emails' measure: 0 is due today, negative is overdue --->
	<cfquery name="openLoans" datasource="uam_god" result="openLoans_result">
		SELECT
			trans.transaction_id, loan.loan_number, loan.loan_type, loan.loan_status, loan.return_due_date,
			round(loan.return_due_date - sysdate) + 1 AS days_left
		FROM loan
			JOIN trans ON loan.transaction_id = trans.transaction_id
		WHERE
			trans.collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.collection_id#">
			AND loan.loan_status LIKE 'open%'
		ORDER BY loan.return_due_date
	</cfquery>
	<cfloop query="openLoans">
		<cfset item = {
			href = "/transactions/Loan.cfm?action=editLoan&transaction_id=#openLoans.transaction_id#",
			label = openLoans.loan_number,
			detail = "#openLoans.loan_type#, #openLoans.loan_status#, due #dateFormat(openLoans.return_due_date, 'yyyy-mm-dd')#"
		}>
		<cfif len(openLoans.days_left) EQ 0 OR openLoans.days_left GE 0>
			<cfset arrayAppend(notOverdue, item)>
		</cfif>
		<cfif listFind("returnable,consumable", openLoans.loan_type) AND len(openLoans.days_left) GT 0>
			<cfif openLoans.days_left LT -365>
				<cfif openLoans.loan_status NEQ "open historical">
					<cfset arrayAppend(longOverdue, item)>
				<cfelse>
					<cfset arrayAppend(noReminder, item)>
				</cfif>
			<cfelseif openLoans.days_left LT 0>
				<cfset arrayAppend(overdue, item)>
			<cfelseif openLoans.days_left LE 30>
				<cfset arrayAppend(dueSoon, item)>
			</cfif>
		<cfelseif len(openLoans.days_left) GT 0 AND openLoans.days_left LT 0>
			<cfset arrayAppend(noReminder, item)>
		</cfif>
	</cfloop>
	<cfsavecontent variable="html">
		<cfoutput>
			<p class="mb-2">
				#openLoans.recordcount# open loans.
				<cfif arrayLen(longOverdue) + arrayLen(overdue) + arrayLen(noReminder) EQ 0><span class="badge badge-success">None overdue</span></cfif>
			</p>
			#dueItemsHtml("Overdue more than a year", longOverdue, "badge-danger")#
			#dueItemsHtml("Overdue", overdue, "badge-warning")#
			#dueItemsHtml("Overdue, no reminder sent", noReminder, "badge-warning")#
			#dueItemsHtml("Due within 30 days", dueSoon, "badge-secondary")#
			#dueItemsHtml("Open, not overdue", notOverdue, "badge-secondary")#
		</cfoutput>
	</cfsavecontent>
	<cfreturn html>
</cffunction>

<!---
	getBorrowsHtml the Collection Panel widget listing a collection's borrows not yet returned that are
	overdue by more than a year, overdue, or due within 30 days, using the criteria of the borrow
	reminder emails (ScheduledTasks/borrowreminder.cfm); and all such borrows not overdue.

	@param collection_id the collection to report on.
	@return HTML for the widget body.
--->
<cffunction name="getBorrowsHtml" access="remote" returntype="string" returnformat="plain">
	<cfargument name="collection_id" type="numeric" required="yes">
	<cfset var html = "">
	<cfset var borrows = "">
	<cfset var borrows_result = "">
	<cfset var item = "">
	<cfset var longOverdue = arrayNew(1)>
	<cfset var overdue = arrayNew(1)>
	<cfset var dueSoon = arrayNew(1)>
	<cfset var notOverdue = arrayNew(1)>
	<cfset requirePanelViewer()>
	<!--- days_left is the reminder emails' measure: 0 is due today, negative is overdue --->
	<cfquery name="borrows" datasource="uam_god" result="borrows_result">
		SELECT
			trans.transaction_id, borrow.borrow_number, borrow.borrow_status, borrow.due_date,
			round(borrow.due_date - sysdate) + 1 AS days_left
		FROM borrow
			JOIN trans ON borrow.transaction_id = trans.transaction_id
		WHERE
			trans.collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.collection_id#">
			AND borrow.borrow_status <> 'returned'
		ORDER BY borrow.due_date
	</cfquery>
	<cfloop query="borrows">
		<cfset item = {
			href = "/transactions/Borrow.cfm?action=edit&transaction_id=#borrows.transaction_id#",
			label = borrows.borrow_number,
			detail = "#borrows.borrow_status#, due #dateFormat(borrows.due_date, 'yyyy-mm-dd')#"
		}>
		<cfif len(borrows.days_left) EQ 0 OR borrows.days_left GE 0>
			<cfset arrayAppend(notOverdue, item)>
		</cfif>
		<cfif len(borrows.days_left) GT 0>
			<cfif borrows.days_left LT -365>
				<cfset arrayAppend(longOverdue, item)>
			<cfelseif borrows.days_left LT 0>
				<cfset arrayAppend(overdue, item)>
			<cfelseif borrows.days_left LE 30>
				<cfset arrayAppend(dueSoon, item)>
			</cfif>
		</cfif>
	</cfloop>
	<cfsavecontent variable="html">
		<cfoutput>
			<p class="mb-2">
				#borrows.recordcount# borrows not returned.
				<cfif arrayLen(longOverdue) + arrayLen(overdue) EQ 0><span class="badge badge-success">None overdue</span></cfif>
			</p>
			#dueItemsHtml("Overdue more than a year", longOverdue, "badge-danger")#
			#dueItemsHtml("Overdue", overdue, "badge-warning")#
			#dueItemsHtml("Due within 30 days", dueSoon, "badge-secondary")#
			#dueItemsHtml("Open, not overdue", notOverdue, "badge-secondary")#
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
	<cfset requirePanelViewer()>
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
	getSpecimenBulkloaderHtml the Collection Panel widget summarising a collection's rows in the specimen
	bulkloader by who entered them and their state.  A row's loaded value is its state: empty rows are
	loaded by the BULKLOAD job, anything other than the states the application sets is the reason
	the row failed to load.

	@param collection_id the collection to report on.
	@return HTML for the widget body.
--->
<cffunction name="getSpecimenBulkloaderHtml" access="remote" returntype="string" returnformat="plain">
	<cfargument name="collection_id" type="numeric" required="yes">
	<cfset var html = "">
	<cfset var collection = "">
	<cfset var collection_result = "">
	<cfset var byUser = "">
	<cfset var byUser_result = "">
	<cfset var failures = "">
	<cfset var failures_result = "">
	<cfset requirePanelViewer()>
	<cfquery name="collection" datasource="uam_god" result="collection_result">
		SELECT institution_acronym, collection_cde
		FROM collection
		WHERE collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.collection_id#">
	</cfquery>
	<cfif collection.recordcount EQ 0>
		<cfreturn '<p class="text-danger mb-0">Unknown collection.</p>'>
	</cfif>
	<cfquery name="byUser" datasource="uam_god" result="byUser_result">
		SELECT
			enteredby,
			sum(CASE WHEN loaded IS NULL THEN 1 ELSE 0 END) AS ready,
			sum(CASE WHEN lower(loaded) = 'waiting approval' THEN 1 ELSE 0 END) AS waiting,
			sum(CASE WHEN upper(loaded) = 'BULKLOADED RECORD' THEN 1 ELSE 0 END) AS staged,
			sum(CASE WHEN upper(loaded) = 'MARK FOR DELETION' THEN 1 ELSE 0 END) AS marked,
			sum(CASE WHEN loaded IS NOT NULL AND lower(loaded) <> 'waiting approval' AND upper(loaded) NOT IN ('BULKLOADED RECORD', 'MARK FOR DELETION') THEN 1 ELSE 0 END) AS failed,
			count(*) AS ct
		FROM bulkloader
		WHERE
			upper(institution_acronym) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(collection.institution_acronym)#">
			AND upper(collection_cde) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(collection.collection_cde)#">
		GROUP BY enteredby
		ORDER BY enteredby
	</cfquery>
	<cfquery name="failures" datasource="uam_god" result="failures_result">
		SELECT loaded, count(*) AS ct
		FROM bulkloader
		WHERE
			upper(institution_acronym) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(collection.institution_acronym)#">
			AND upper(collection_cde) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(collection.collection_cde)#">
			AND loaded IS NOT NULL
			AND lower(loaded) <> 'waiting approval'
			AND upper(loaded) NOT IN ('BULKLOADED RECORD', 'MARK FOR DELETION')
		GROUP BY loaded
		ORDER BY 2 DESC
	</cfquery>
	<cfsavecontent variable="html">
		<cfoutput>
			<cfif byUser.recordcount EQ 0>
				<p class="mb-0">No #encodeForHtml(collection.institution_acronym)#:#encodeForHtml(collection.collection_cde)# rows are in the specimen bulkloader.</p>
			<cfelse>
				<p class="mb-2">#encodeForHtml(collection.institution_acronym)#:#encodeForHtml(collection.collection_cde)# rows in the specimen bulkloader. Ready rows are loaded by the next bulkload run; staged rows have been checked and need to be released; failed rows need correcting.</p>
				<table class="table table-sm table-striped table-responsive d-xl-table small mb-1">
					<thead class="thead-light">
						<tr><th>Entered by</th><th>Ready</th><th>Waiting approval</th><th>Staged</th><th>Marked for deletion</th><th>Failed</th><th>Total</th></tr>
					</thead>
					<tbody>
						<cfloop query="byUser">
							<tr>
								<td>#encodeForHtml(byUser.enteredby)#</td>
								<td>#byUser.ready#</td>
								<td>#byUser.waiting#</td>
								<td>#byUser.staged#</td>
								<td>#byUser.marked#</td>
								<td><cfif byUser.failed GT 0><span class="badge badge-danger">#byUser.failed#</span><cfelse>0</cfif></td>
								<td>#byUser.ct#</td>
							</tr>
						</cfloop>
					</tbody>
				</table>
				<cfif failures.recordcount GT 0>
					<details class="mb-1">
						<summary><strong>Reasons for failures</strong> (#failures.recordcount#)</summary>
						<ul class="small mb-1">
							<cfloop query="failures">
								<li>#failures.ct#: #encodeForHtml(failures.loaded)#</li>
							</cfloop>
						</ul>
					</details>
				</cfif>
				<a href="/Bulkloader/bulkloader_status.cfm" class="small">Specimen Bulkloader Status</a>
				<a href="/Bulkloader/browseBulk.cfm" class="small ml-3">Browse and Edit Specimen Bulkloads</a>
			</cfif>
		</cfoutput>
	</cfsavecontent>
	<cfreturn html>
</cffunction>

<!---
	getRecentlyBulkloadedHtml the Collection Panel widget showing cataloged items the specimen bulkloader
	added to a collection in the last 30 days, by day, who entered them, and accession.

	@param collection_id the collection to report on.
	@return HTML for the widget body.
--->
<cffunction name="getRecentlyBulkloadedHtml" access="remote" returntype="string" returnformat="plain">
	<cfargument name="collection_id" type="numeric" required="yes">
	<cfset var html = "">
	<cfset var loaded = "">
	<cfset var loaded_result = "">
	<cfset var total = 0>
	<cfset requirePanelViewer()>
	<cfquery name="loaded" datasource="uam_god" result="loaded_result">
		SELECT
			trunc(bulkloader_attempts.tstamp) AS load_date,
			entered_name.agent_name AS entered_by,
			accn.transaction_id AS accn_transaction_id,
			accn.accn_number,
			count(*) AS ct
		FROM bulkloader_attempts
			JOIN cataloged_item ON bulkloader_attempts.collection_object_id = cataloged_item.collection_object_id
			JOIN coll_object ON cataloged_item.collection_object_id = coll_object.collection_object_id
			LEFT JOIN accn ON cataloged_item.accn_id = accn.transaction_id
			LEFT JOIN agent_name entered_name ON coll_object.entered_person_id = entered_name.agent_id
				AND entered_name.agent_name_type = 'preferred'
		WHERE
			cataloged_item.collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.collection_id#">
			AND bulkloader_attempts.tstamp >= trunc(sysdate) - 30
		GROUP BY
			trunc(bulkloader_attempts.tstamp), entered_name.agent_name, accn.transaction_id, accn.accn_number
		ORDER BY 1 DESC, 2, 4
	</cfquery>
	<cfloop query="loaded">
		<cfset total = total + loaded.ct>
	</cfloop>
	<cfsavecontent variable="html">
		<cfoutput>
			<p class="mb-2">#total# cataloged items bulkloaded in the last 30 days.</p>
			<cfif loaded.recordcount GT 0>
				<table class="table table-sm table-striped table-responsive d-xl-table small mb-1">
					<thead class="thead-light">
						<tr><th>Loaded</th><th>Entered by</th><th>Accession</th><th>Items</th></tr>
					</thead>
					<tbody>
						<cfloop query="loaded">
							<tr>
								<td>#dateFormat(loaded.load_date, "yyyy-mm-dd")#</td>
								<td>#encodeForHtml(loaded.entered_by)#</td>
								<td><cfif len(loaded.accn_transaction_id) GT 0><a href="/transactions/Accession.cfm?action=edit&transaction_id=#loaded.accn_transaction_id#">#encodeForHtml(loaded.accn_number)#</a></cfif></td>
								<td>#loaded.ct#</td>
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
	getDeaccessionsHtml the Collection Panel widget listing a collection's open and in process
	deaccessions, and closed deaccessions with items whose current container isn't within an external
	container (such as Deaccessioned), where deaccessioned material is expected to be placed.

	@param collection_id the collection to report on.
	@return HTML for the widget body.
--->
<cffunction name="getDeaccessionsHtml" access="remote" returntype="string" returnformat="plain">
	<cfargument name="collection_id" type="numeric" required="yes">
	<cfset var html = "">
	<cfset var deaccessions = "">
	<cfset var deaccessions_result = "">
	<cfset var misplaced = "">
	<cfset var misplaced_result = "">
	<cfset requirePanelViewer()>
	<cfquery name="deaccessions" datasource="uam_god" result="deaccessions_result">
		SELECT
			trans.transaction_id, trans.trans_date, deaccession.deacc_number, deaccession.deacc_type, deaccession.deacc_status
		FROM deaccession
			JOIN trans ON deaccession.transaction_id = trans.transaction_id
		WHERE
			trans.collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.collection_id#">
			AND deaccession.deacc_status <> 'closed'
		ORDER BY trans.trans_date
	</cfquery>
	<cfquery name="misplaced" datasource="uam_god" result="misplaced_result">
		WITH deaccessioned_containers AS (
			SELECT container_id
			FROM container
			START WITH container_type = 'external'
			CONNECT BY PRIOR container_id = parent_container_id
		)
		SELECT
			trans.transaction_id, deaccession.deacc_number, deaccession.deacc_type,
			count(*) AS items,
			sum(CASE WHEN deaccessioned_containers.container_id IS NULL THEN 1 ELSE 0 END) AS not_placed
		FROM deaccession
			JOIN trans ON deaccession.transaction_id = trans.transaction_id
			JOIN deacc_item ON deaccession.transaction_id = deacc_item.transaction_id
			LEFT JOIN coll_obj_cont_hist ON deacc_item.collection_object_id = coll_obj_cont_hist.collection_object_id
				AND coll_obj_cont_hist.current_container_fg = 1
			LEFT JOIN deaccessioned_containers ON coll_obj_cont_hist.container_id = deaccessioned_containers.container_id
		WHERE
			trans.collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.collection_id#">
			AND deaccession.deacc_status = 'closed'
		GROUP BY trans.transaction_id, deaccession.deacc_number, deaccession.deacc_type
		HAVING sum(CASE WHEN deaccessioned_containers.container_id IS NULL THEN 1 ELSE 0 END) > 0
		ORDER BY deaccession.deacc_number
	</cfquery>
	<cfsavecontent variable="html">
		<cfoutput>
			<p class="mb-2">#deaccessions.recordcount# deaccessions open or in process.</p>
			<cfif deaccessions.recordcount GT 0>
				<details class="mb-1">
					<summary><strong>Open or in process</strong> <span class="badge badge-secondary">#deaccessions.recordcount#</span></summary>
					<ul class="small mb-1">
						<cfloop query="deaccessions">
							<li><a href="/transactions/Deaccession.cfm?action=edit&transaction_id=#deaccessions.transaction_id#">#encodeForHtml(deaccessions.deacc_number)#</a>
								#encodeForHtml(deaccessions.deacc_type)#, #encodeForHtml(deaccessions.deacc_status)#, started #dateFormat(deaccessions.trans_date, "yyyy-mm-dd")#</li>
						</cfloop>
					</ul>
				</details>
			</cfif>
			<cfif misplaced.recordcount EQ 0>
				<p class="mb-0 small"><span class="badge badge-success">OK</span> All items of closed deaccessions are in a deaccessioned container.</p>
			<cfelse>
				<details class="mb-1">
					<summary><strong>Closed, with items not in a deaccessioned container</strong> <span class="badge badge-warning">#misplaced.recordcount#</span></summary>
					<ul class="small mb-1">
						<cfloop query="misplaced">
							<li><a href="/transactions/Deaccession.cfm?action=edit&transaction_id=#misplaced.transaction_id#">#encodeForHtml(misplaced.deacc_number)#</a>
								#encodeForHtml(misplaced.deacc_type)#, #misplaced.not_placed# of #misplaced.items# items not in a deaccessioned container</li>
						</cfloop>
					</ul>
				</details>
			</cfif>
		</cfoutput>
	</cfsavecontent>
	<cfreturn html>
</cffunction>

<!---
	getPermitsHtml the Collection Panel widget listing permits on a collection's transactions that
	expire within 90 days or expired in the last 30.

	@param collection_id the collection to report on.
	@return HTML for the widget body.
--->
<cffunction name="getPermitsHtml" access="remote" returntype="string" returnformat="plain">
	<cfargument name="collection_id" type="numeric" required="yes">
	<cfset var html = "">
	<cfset var permits = "">
	<cfset var permits_result = "">
	<cfset requirePanelViewer()>
	<cfquery name="permits" datasource="uam_god" result="permits_result">
		SELECT
			permit.permit_id, permit.permit_num, permit.permit_title, permit.specific_type, permit.exp_date,
			count(DISTINCT trans.transaction_id) AS transactions
		FROM permit
			JOIN permit_trans ON permit.permit_id = permit_trans.permit_id
			JOIN trans ON permit_trans.transaction_id = trans.transaction_id
		WHERE
			trans.collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.collection_id#">
			AND permit.exp_date >= trunc(sysdate) - 30
			AND permit.exp_date < trunc(sysdate) + 90
		GROUP BY
			permit.permit_id, permit.permit_num, permit.permit_title, permit.specific_type, permit.exp_date
		ORDER BY permit.exp_date
	</cfquery>
	<cfsavecontent variable="html">
		<cfoutput>
			<p class="mb-2">#permits.recordcount# permits on this collection's transactions expire within 90 days or expired in the last 30.</p>
			<cfif permits.recordcount GT 0>
				<ul class="small mb-1">
					<cfloop query="permits">
						<li><a href="/transactions/Permit.cfm?action=edit&permit_id=#permits.permit_id#"><cfif len(permits.permit_num) GT 0>#encodeForHtml(permits.permit_num)#<cfelse>#encodeForHtml(permits.permit_title)#</cfif></a>
							#encodeForHtml(permits.specific_type)#,
							<cfif permits.exp_date LT now()>expired<cfelse>expires</cfif> #dateFormat(permits.exp_date, "yyyy-mm-dd")#,
							#permits.transactions# transactions</li>
					</cfloop>
				</ul>
			</cfif>
		</cfoutput>
	</cfsavecontent>
	<cfreturn html>
</cffunction>

<!---
	getVpdUsersHtml the Collection Panel widget listing the database accounts granted the collection's
	role (institution acronym and collection code, e.g. MCZ_HERP), which gives access to the
	collection's data through its VPD, and any roles it is granted to.  Global admins and curatorial
	associates, who have access to every collection, are grouped separately from the accounts specific
	to this one; an account holding both is grouped with the global admins.  Database accounts with
	no MCZbase user are listed only for global admins.

	@param collection_id the collection to report on.
	@param show_roles true to list every role each account holds.
	@return HTML for the widget body.
--->
<cffunction name="getVpdUsersHtml" access="remote" returntype="string" returnformat="plain">
	<cfargument name="collection_id" type="numeric" required="yes">
	<cfargument name="show_roles" type="boolean" required="no" default="false">
	<cfset var html = "">
	<cfset var collection = "">
	<cfset var collection_result = "">
	<cfset var holders = "">
	<cfset var holders_result = "">
	<cfset var viaRoles = "">
	<cfset var viaRoles_result = "">
	<cfset var heldRoles = "">
	<cfset var heldRoles_result = "">
	<cfset var collectionRole = "">
	<cfset var broadAccess = "">
	<cfset var broadAccess_result = "">
	<cfset var groupOf = structNew()>
	<cfset var groupCounts = { specific = 0, admins = 0, associates = 0 }>
	<cfset var GROUP_LABELS = { specific = "Accounts for this collection", admins = "Global admins", associates = "Curatorial associates" }>
	<cfset var rolesByAccount = structNew()>
	<cfset var collectionRoles = "">
	<cfset var showUnlinked = false>
	<cfset var openCount = 0>
	<cfset var group = "">
	<cfset var name = "">
	<cfset var role = "">
	<cfset requirePanelViewer()>
	<cfif listFindNoCase(session.roles, "global_admin") GT 0>
		<cfset showUnlinked = true>
	</cfif>
	<cfquery name="collection" datasource="uam_god" result="collection_result">
		SELECT institution_acronym, collection_cde
		FROM collection
		WHERE collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.collection_id#">
	</cfquery>
	<cfif collection.recordcount EQ 0>
		<cfreturn '<p class="text-danger mb-0">Unknown collection.</p>'>
	</cfif>
	<cfset collectionRole = ucase(collection.institution_acronym & "_" & collection.collection_cde)>
	<cfquery name="holders" datasource="uam_god" result="holders_result">
		SELECT
			rp.grantee, rp.default_role, u.account_status,
			cu.username AS mczbase_username, cu.last_login,
			cud.first_name, cud.last_name
		FROM dba_role_privs rp
			JOIN dba_users u ON u.username = rp.grantee
			LEFT JOIN cf_users cu ON upper(cu.username) = rp.grantee
			LEFT JOIN cf_user_data cud ON cud.user_id = cu.user_id
		WHERE rp.granted_role = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#collectionRole#">
			<cfif NOT showUnlinked>
				AND cu.username IS NOT NULL
			</cfif>
		ORDER BY CASE WHEN u.account_status = 'OPEN' THEN 0 ELSE 1 END, rp.grantee
	</cfquery>
	<cfquery name="viaRoles" datasource="uam_god" result="viaRoles_result">
		SELECT rp.grantee
		FROM dba_role_privs rp
			JOIN dba_roles r ON r.role = rp.grantee
		WHERE rp.granted_role = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#collectionRole#">
		ORDER BY rp.grantee
	</cfquery>
	<cfquery name="broadAccess" datasource="uam_god" result="broadAccess_result">
		SELECT grantee, granted_role
		FROM dba_role_privs
		WHERE granted_role IN ('GLOBAL_ADMIN', 'CURATORIAL_ASSOCIATE')
	</cfquery>
	<cfif arguments.show_roles>
		<cfset collectionRoles = collectionRoleNames()>
		<cfquery name="heldRoles" datasource="uam_god" result="heldRoles_result">
			SELECT rp.grantee, rp.granted_role
			FROM dba_role_privs rp
			WHERE rp.grantee IN (
				SELECT grantee
				FROM dba_role_privs
				WHERE granted_role = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#collectionRole#">
			)
			ORDER BY rp.grantee, rp.granted_role
		</cfquery>
		<cfloop query="heldRoles">
			<cfif NOT structKeyExists(rolesByAccount, heldRoles.grantee)>
				<cfset rolesByAccount[heldRoles.grantee] = "">
			</cfif>
			<cfset rolesByAccount[heldRoles.grantee] = listAppend(rolesByAccount[heldRoles.grantee], heldRoles.granted_role)>
		</cfloop>
	</cfif>
	<cfloop query="holders">
		<cfset groupOf[holders.grantee] = "specific">
	</cfloop>
	<cfloop query="broadAccess">
		<cfif structKeyExists(groupOf, broadAccess.grantee)>
			<cfif broadAccess.granted_role EQ "GLOBAL_ADMIN">
				<cfset groupOf[broadAccess.grantee] = "admins">
			<cfelseif groupOf[broadAccess.grantee] EQ "specific">
				<cfset groupOf[broadAccess.grantee] = "associates">
			</cfif>
		</cfif>
	</cfloop>
	<cfloop query="holders">
		<cfif holders.account_status EQ "OPEN">
			<cfset openCount = openCount + 1>
		</cfif>
		<cfset groupCounts[groupOf[holders.grantee]] = groupCounts[groupOf[holders.grantee]] + 1>
	</cfloop>
	<cfsavecontent variable="html">
		<cfoutput>
			<p class="mb-2">
				#holders.recordcount# <cfif showUnlinked>database accounts<cfelse>MCZbase users</cfif> hold #encodeForHtml(lcase(collectionRole))#, which gives access to this collection's data; #openCount# of them are open.
				<cfif viaRoles.recordcount GT 0>
					It is also granted to the roles #encodeForHtml(lcase(valueList(viaRoles.grantee, ", ")))#, so their holders have access too.
				</cfif>
			</p>
			<cfif arguments.show_roles>
				<p class="small mb-2">
					Roles, coloured as on the Database Access Report:
					<span class="badge badge-danger font-weight-normal">dba, global_admin</span>
					<span class="badge badge-warning font-weight-normal">admin_ roles</span>
					<span class="badge badge-primary font-weight-normal">curatorial_associate</span>
					<span class="badge badge-info font-weight-normal">manage_collection</span>
					<span class="badge badge-success font-weight-normal">collection roles</span>
					<span class="badge badge-dark font-weight-normal">connect</span>
					<span class="badge badge-light border font-weight-normal">other roles</span>
				</p>
			</cfif>
			<cfloop list="specific,admins,associates" index="group">
				<cfif groupCounts[group] EQ 0>
					<cfcontinue>
				</cfif>
				<cfif group EQ "specific">
					<h3 class="h5">#GROUP_LABELS[group]# (#groupCounts[group]#)</h3>
				<cfelse>
					<details class="mt-2">
					<summary><strong>#GROUP_LABELS[group]#</strong> (#groupCounts[group]#), who have access to every collection</summary>
				</cfif>
				<table class="table table-sm table-striped table-responsive d-xl-table small mb-1">
					<thead class="thead-light">
						<tr>
							<th scope="col">Account</th>
							<th scope="col">Name</th>
							<th scope="col">Status</th>
							<th scope="col">Last login</th>
							<cfif arguments.show_roles><th scope="col">Roles</th></cfif>
						</tr>
					</thead>
					<tbody>
						<cfloop query="holders">
							<cfif groupOf[holders.grantee] EQ group>
								<cfset name = trim(holders.first_name & " " & holders.last_name)>
								<tr>
									<td>
										#encodeForHtml(holders.grantee)#
										<cfif holders.default_role NEQ "YES"><span class="badge badge-warning font-weight-normal" title="Granted, but not a default role, so the account does not use it">not default</span></cfif>
									</td>
									<td>
										<cfif len(holders.mczbase_username) EQ 0>
											<span class="text-secondary">no MCZbase user</span>
										<cfelse>
											#encodeForHtml(name)#
										</cfif>
									</td>
									<td><cfif holders.account_status EQ "OPEN">open<cfelse><span class="text-secondary">#encodeForHtml(lcase(holders.account_status))#</span></cfif></td>
									<td><cfif isDate(holders.last_login)>#dateFormat(holders.last_login, "yyyy-mm-dd")#<cfelseif len(holders.mczbase_username) GT 0>never</cfif></td>
									<cfif arguments.show_roles>
										<td>
											<cfif structKeyExists(rolesByAccount, holders.grantee)>
												<cfloop list="#rolesByAccount[holders.grantee]#" index="role">
													<span class="badge #roleBadgeClass(role, collectionRoles)# font-weight-normal mr-1">#encodeForHtml(lcase(role))#</span>
												</cfloop>
											</cfif>
										</td>
									</cfif>
								</tr>
							</cfif>
						</cfloop>
					</tbody>
				</table>
				<cfif group NEQ "specific">
					</details>
				</cfif>
			</cfloop>
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
	<cfset requirePanelViewer()>
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
