<!---
encumbrances/component/search.cfc

Backing search methods for encumbrance search and results rendering.

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
<cfcomponent>
<cfinclude template="/shared/component/error_handler.cfc" runOnce="true">
<cf_rolecheck>

<!---
 renderEncumbranceSearchResults renders an HTML results table for encumbrance search criteria.

 Current columns include a specimen_count (rows in coll_object_encumbrance) for each
 result row.

 TODO: When locality_encumbrance is implemented, add a locality_count subquery alongside
 the specimen_count subquery so the results table can show both columns.  The locality
 count should reflect direct locality-level encumbrances only; inherited specimen counts
 derived from locality membership will remain in the specimen_count column and should not
 be double-counted.  The query change required will be:
   - Add a subquery or LEFT JOIN to locality_encumbrance keyed on encumbrance.encumbrance_id
   - Add locality_count to the SELECT and GROUP BY lists
   - Add <th>Localities</th> column to the results table header
   - Add <td>#getEnc.locality_count#</td> cell in the results loop
   - Adjust the delete-guard logic: also allow delete when locality_count EQ 0

 @param encumberingAgent  optional agent name fragment (case-insensitive LIKE match).
 @param made_date_after   optional ISO date string; filter made_date >=.
 @param made_date_before  optional ISO date string; filter made_date <=.
 @param expiration_date_after  optional ISO date string; filter expiration_date >=.
 @param expiration_date_before optional ISO date string; filter expiration_date <=.
 @param encumbrance_id    optional exact encumbrance_id numeric match.
 @param encumbrance       optional encumbrance name fragment (case-insensitive LIKE match).
 @param encumbrance_action optional exact encumbrance_action match.
 @param expiration_event  optional expiration event fragment (case-insensitive LIKE match).
 @param remarks           optional remarks fragment (case-insensitive LIKE match).
 @param collection_object_id  optional comma-separated list of collection_object_id values;
                              when present the results table includes Add/Remove action buttons.
 @return HTML string containing the results table or a no-results message.
--->
<cffunction name="renderEncumbranceSearchResults" access="remote" returntype="string" returnformat="plain">
	<cfargument name="encumberingAgent" type="string" required="no" default="">
	<cfargument name="made_date_after" type="string" required="no" default="">
	<cfargument name="made_date_before" type="string" required="no" default="">
	<cfargument name="expiration_date_after" type="string" required="no" default="">
	<cfargument name="expiration_date_before" type="string" required="no" default="">
	<cfargument name="encumbrance_id" type="string" required="no" default="">
	<cfargument name="encumbrance" type="string" required="no" default="">
	<cfargument name="encumbrance_action" type="string" required="no" default="">
	<cfargument name="expiration_event" type="string" required="no" default="">
	<cfargument name="remarks" type="string" required="no" default="">
	<cfargument name="collection_object_id" type="string" required="no" default="">

	<cftry>
		<!---
		     specimen_count: rows in coll_object_encumbrance for this encumbrance.
		     TODO: When locality_encumbrance is added, include a parallel
		     (SELECT count(*) FROM locality_encumbrance le
		          WHERE le.encumbrance_id = encumbrance.encumbrance_id) AS locality_count
		     subquery in the SELECT and add it to the GROUP BY.
		--->
		<cfquery name="getEnc" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			SELECT
				count(coll_object_encumbrance.collection_object_id) AS specimen_count,
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
				<cfif len(trim(encumberingAgent)) GT 0>
					LEFT JOIN agent_name
						ON encumbrance.encumbering_agent_id = agent_name.agent_id
				</cfif>
				LEFT JOIN coll_object_encumbrance
					ON encumbrance.encumbrance_id = coll_object_encumbrance.encumbrance_id
			WHERE
				encumbrance.encumbrance_id IS NOT NULL
			<cfif len(trim(encumberingAgent)) GT 0>
				AND upper(agent_name.agent_name) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(trim(encumberingAgent))#%">
			</cfif>
			<cfif len(trim(made_date_after)) GT 0>
				AND made_date >= to_date(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(made_date_after)#">)
			</cfif>
			<cfif len(trim(made_date_before)) GT 0>
				AND made_date <= to_date(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(made_date_before)#">)
			</cfif>
			<cfif len(trim(expiration_date_after)) GT 0>
				AND expiration_date >= to_date(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(expiration_date_after)#">)
			</cfif>
			<cfif len(trim(expiration_date_before)) GT 0>
				AND expiration_date <= to_date(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(expiration_date_before)#">)
			</cfif>
			<cfif len(trim(encumbrance_id)) GT 0>
				AND encumbrance.encumbrance_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#trim(encumbrance_id)#">
			</cfif>
			<cfif len(trim(encumbrance)) GT 0>
				AND upper(encumbrance.encumbrance) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(trim(encumbrance))#%">
			</cfif>
			<cfif len(trim(encumbrance_action)) GT 0>
				AND encumbrance.encumbrance_action = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(encumbrance_action)#">
			</cfif>
			<cfif len(trim(expiration_event)) GT 0>
				AND upper(encumbrance.expiration_event) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(trim(expiration_event))#%">
			</cfif>
			<cfif len(trim(remarks)) GT 0>
				AND upper(encumbrance.remarks) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(trim(remarks))#%">
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

		<cfset variables.hasCollObj = len(trim(collection_object_id)) GT 0>

		<cfoutput>
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
							<!--- specimen_count: number of cataloged items directly linked via coll_object_encumbrance.
							     TODO: When locality_encumbrance is implemented, rename this column header to
							     "Specimens" and add a "Localities" column beside it showing locality_count.
							     Consider adding a tooltip explaining that locality encumbrances are inherited
							     by specimens at those localities but are not counted in the Specimens column. --->
							<th scope="col">Specimens</th>
							<th scope="col">Manage</th>
						</tr>
					</thead>
					<tbody>
						<cfset variables.rowNum = 1>
						<cfloop query="getEnc">
							<tr>
								<td>#variables.rowNum#</td>
								<td>
									<a href="/encumbrances/viewEncumbrance.cfm?encumbrance_id=#encodeForURL(getEnc.encumbrance_id)#">
										#encodeForHTML(getEnc.encumbrance)#
									</a>
								</td>
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
								<td>#getEnc.specimen_count#</td>
								<td>
									<cfif variables.hasCollObj>
										<button type="button" class="btn btn-xs btn-secondary mb-1"
											onclick="submitEncumbranceAction('saveEncumbrances','#getEnc.encumbrance_id#','#encodeForHTML(collection_object_id)#');">
											Add Items to This Encumbrance
										</button>
										<button type="button" class="btn btn-xs btn-warning mb-1"
											onclick="submitEncumbranceAction('remListedItems','#getEnc.encumbrance_id#','#encodeForHTML(collection_object_id)#');">
											Remove Listed Items
										</button>
									</cfif>
									<a href="/encumbrances/Encumbrance.cfm?action=edit&encumbrance_id=#encodeForURL(getEnc.encumbrance_id)#" class="btn btn-xs btn-secondary mb-1">
										Edit
									</a>
									<!--- Enable delete if remarks does not contain 'DO NOT DELETE'. --->
									<cfif NOT findNoCase("DO NOT DELETE", getEnc.remarks)>
										<!--- Enable delete only when no cataloged items use this encumbrance,
										     or when the encumbrance has an expiration event or a past expiration date.
										     TODO: When locality_encumbrance is added, also require locality_count EQ 0
										     (or that all localities are expired/have expiration events) before enabling
										     the delete button. --->
										<cfif getEnc.specimen_count EQ 0 OR len(trim(getEnc.expiration_event)) GT 0 OR (len(getEnc.expiration_date) GT 0 AND ( dateCompare(parseDateTime(getEnc.expiration_date),now(),"d") ))>
											<button type="button" class="btn btn-xs btn-danger mb-1"
												onclick="confirmDeleteEncumbranceResult('#getEnc.encumbrance_id#','#encodeForHTML(collection_object_id)#');">
												Delete
											</button>
										</cfif>
									</cfif>
									<cfif getEnc.specimen_count GT 0>
										<a href="/SpecimenResults.cfm?encumbrance_id=#getEnc.encumbrance_id#" class="btn btn-xs btn-info mb-1">See Specimens</a>
									</cfif>
									<!--- Enable delete specimens if items are in the encumbrance and action is delete records. --->
									<cfif getEnc.specimen_count GT 0 AND getEnc.encumbrance_action EQ "delete records">
										<a href="/Admin/deleteSpecByEncumbrance.cfm?encumbrance_id=#getEnc.encumbrance_id#"
											class="btn btn-xs btn-danger mb-1">
											Delete Encumbered Specimens
										</a>
									</cfif>
								</td>
							</tr>
							<cfset variables.rowNum = variables.rowNum + 1>
						</cfloop>
					</tbody>
				</table>
				<!--- Single shared form for all table-row POST actions (add/remove items).
				     Buttons populate this form via JavaScript and submit it,
				     avoiding the invalid HTML of nesting a form inside a table row. --->
				<form id="encumbranceActionForm" name="encumbranceActionForm"
					method="post" action="/Encumbrances.cfm">
					<input type="hidden" id="encActionValue" name="action" value="">
					<input type="hidden" id="encIdValue" name="encumbrance_id" value="">
					<input type="hidden" id="encCollObjValue" name="collection_object_id" value="">
				</form>
			</cfif>
		</cfoutput>
	<cfcatch>
		<cfset error_message = cfcatchToErrorMessage(cfcatch)>
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfoutput>
			<h2 class="h3">Error in #function_called#:</h2>
			<div>#error_message#</div>
		</cfoutput>
	</cfcatch>
	</cftry>
</cffunction>

</cfcomponent>
