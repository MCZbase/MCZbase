<!---
transactions/ShipmentReport.cfm
Provides a report on shipment costs for a given date range, optionally limited to a particular department or transaction. 

Copyright 2008-2017 Contributors to Arctos
Copyright 2008-2021 President and Fellows of Harvard College

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

<cfset start_date = "">
<cfif isDefined("url.start_date") and len(url.start_date) GT 0>
	<cfset start_date = url.start_date>
<cfelseif isDefined("form.start_date") and len(form.start_date) GT 0>
	<cfset start_date = form.start_date>
</cfif>
<cfset end_date = "">
<cfif isDefined("url.end_date") and len(url.end_date) GT 0>
	<cfset end_date = url.end_date>
<cfelseif isDefined("form.end_date") and len(form.end_date) GT 0>
	<cfset end_date = form.end_date>
</cfif>
<cfif len(start_date) EQ 0>
	<!--- set to most recent July 1 if not provided --->
	<cfset start_date = dateFormat(createDate(year(now()), 7, 1), "yyyy-mm-dd")>
	<!--- if in the future, use last July 1 --->
	<cfif start_date GT dateFormat(now(), "yyyy-mm-dd")>
		<cfset start_date = dateFormat(createDate(year(now())-1, 7, 1), "yyyy-mm-dd")>
	</cfif>
</cfif>
<cfif len(end_date) EQ 0>
	<!--- set to today if not provided --->
	<cfset end_date = dateFormat(now(), "yyyy-mm-dd")>
</cfif>
<!--- allow limit by department --->
<cfset collection_cde = "">
<cfif isDefined("url.collection_cde") and len(url.collection_cde) GT 0>
	<cfset collection_cde = url.collection_cde>
<cfelseif isDefined("form.collection_cde") and len(form.collection_cde) GT 0>
	<cfset collection_cde = form.collection_cde>
</cfif>
<!--- TODO: allow limit to a particular transaction --->
<cfset transaction_id = "">
<cfif isDefined("url.transaction_id") and len(url.transaction_id) GT 0>
	<cfset transaction_id = url.transaction_id>
<cfelseif isDefined("form.transaction_id") and len(form.transaction_id) GT 0>
	<cfset transaction_id = form.transaction_id>
</cfif>

<cfset pageTitle="Shipment Cost Report">
<cfinclude template="/shared/_header.cfm">
<cfquery name="collectionCodes" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	SELECT collection_cde, institution_acronym 
	FROM collection
</cfquery>

<cfoutput>
	<main class="container-fluid" id="content">
		<h2 class=h2>Shipments and Costs #encodeForHtml(start_date)# to #encodeForHtml(end_date)#</h2>
		<form id="cost_report_form" name="cost_report_form"  method="post" action="/transactions/ShipmentReport.cfm">
			<div class="form-row">
				<div class="col-12 col-md-3">
					<label for="start_date" class="data-entry-label">Start Date</label>
					<input type="text" value="#dateformat(start_date,'yyyy-mm-dd')#" name="start_date" id="start_date" class="data-entry-input">
				</div>
				<div class="col-12 col-md-3">
					<label for="end_date" class="data-entry-label">End Date</label>
					<input type="text" value="#dateformat(end_date,'yyyy-mm-dd')#" name="end_date" id="end_date" class="data-entry-input">
				</div>
				<div class="col-12 col-md-3">
					<label for="collection_cde" class="data-entry-label">Collection</label>
					<select name="collection_cde" id="collection_cde" class="data-entry-select">
						<cfset hasSelection = false>
						<cfloop query="collectionCodes">
							<cfif collectionCodes.collection_cde EQ collection_cde>
								<cfset selected = "selected">
								<cfset hasSelection = true>
							<cfelse>
								<cfset selected = "">
							</cfif>
							
						</cfloop>
						<cfif hasSelection EQ true>
							<cfset selected = "selected">
							<cfset hasSelection = true>
						<cfelse>
							<cfset selected = "">
						</cfif>
						<cfset option="#selected#">All</option>
					</select>
				</div>
				<div class="col-12 col-md-3">
					<button class="btn btn-xs btn-primary mt-3" type="submit" aria-label="get report for specified date range and collection">Get Report</button>
				</div>
			</div>
		</form>
		<cfquery name="shipmentCount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			SELECT 
				count(*) all_shipments, 
				count(ALL shipment.costs) shipments_with_costs, 
				count(DISTINCT loan.transaction_id) loans,
				count(DISTINCT accn.transaction_id) accessions,
				count(DISTINCT deaccession.transaction_id) deaccessions,
				count(DISTINCT borrow.transaction_id) borrows,
				count(ALL loan.transaction_id) loan_shipments,
				count(ALL accn.transaction_id) accession_shipments,
				count(ALL deaccession.transaction_id) deaccession_shipments,
				count(ALL borrow.transaction_id) borrow_shipments,
				collection.institution_acronym, collection.collection_cde, 
				collection.collection_id,
				sum(costs) sum_costs
			FROM shipment 
				join trans on shipment.transaction_id = trans.transaction_id
				join collection on trans.collection_id = collection.collection_id
				left join loan on trans.transaction_id = loan.transaction_id
				left join accn on trans.transaction_id = accn.transaction_id
				left join deaccession on trans.transaction_id = deaccession.transaction_id
				left join borrow on trans.transaction_id = borrow.transaction_id
			WHERE
				shipment.shipped_date <= <cfqueryparam cfsqltype="CF_SQL_DATE" value="#end_date#">
				AND shipment.shipped_date >= <cfqueryparam cfsqltype="CF_SQL_DATE" value="#start_date#">
				<cfif len(collection_cde) GT 0>
					AND collection.collection_cde = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#collection_cde#">
				</cfif>
			GROUP BY collection.institution_acronym, collection.collection_cde
		</cfquery>
		<cfif shipmentCount.recordCount EQ 0>
				<div class=h3>No shipments found for specified date range and collection.</div>
		<cfelse>
			<table class="table table-striped table-responsive mt-2">
				<tr>
					<th>Collection</th>
					<th>All Shipments</th>
					<th>Loan Shipments</th>
					<th>Accession Shipments</th>
					<th>Deaccession Shipments</th>
					<th>Borrow Shipments</th>
					<th>Shipments with Costs</th>
					<th>Total Costs</th>
				</tr>
				<cfloop query="shipmentCount">
					<tr>
						<td><a href="/Transactions.cfm?action=findAll&execute=true&method=getTransactions&collection_id=#collection_id#&shipment_count=1%2B&trans_date=#start_date#&to_trans_date=#end_date#">#institution_acronym#:#collection_cde#</a></td>
						<td>#all_shipments#</td>
						<td>#loan_shipments#</td>
						<td>#accession_shipments#</td>
						<td>#deaccession_shipments#</td>
						<td>#borrow_shipments#</td>
						<td>#shipments_with_costs#</td> 
						<td>
							<cfif sum_costs EQ "">
								$0
							<cfelse>
								$#sum_costs#
							</cfif>
						</td>
					</tr>
				</cfloop>
		</table
		</cfif>
	</main>
</cfoutput>

<cfinclude template="/shared/_footer.cfm">
