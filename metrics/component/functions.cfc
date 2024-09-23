<!---
metrics/component/functions.cfc

Copyright 2024 President and Fellows of Harvard College
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

<cf_rolecheck>
<cfinclude template="/shared/component/error_handler.cfc" runOnce="true">
<cfinclude template="/shared/component/functions.cfc">
	
<!--- 
 ** given a query, write a serialization of that query as csv, with a header line
 * to a file.
 * @param queryToConvert the query to serialize as csv 
 * @return a structure containing the name of the file, the count of the number of records 
 * written to the file, and a status (STATUS, WRITTEN, FILENAME, MESSAGE), 
 * values of STATUS are Success, Incomplete, and Failed.  For Success and Incomplete, FILENAME 
 * contains the name of the file that was written.
 **REPEATED HERE FOR TESTING -- IS ALSO IN /shared/component/functions.cfc
--->

<!---This function uses the SQL procedure (CHART_DATA_EXPORT), scheduled job (CHART_DATA), and temp table (CF_TEMP_CHART_DATA) to produce a png to write to /metrics/R/graphs/chart1.png
** TO DO: make date pass to dates from form to CHART_DATA_EXPORT (if possible) or at least use sysdate minus 1 year (e.g., change the year YYYY to -1)
--->



<cffunction name="getAnnualChart" access="remote" returntype="any" returnformat="plain">
	<cfthread name="getAnnualChartThread">
		<cfoutput>
			<cfset targetFile = "chart_numbers.csv">
			<cfset filePath = "/metrics/datafiles/">
			<cftry>
				<div class="container">
					<div class="row">
						<div class="col-12 px-0">
							<!--- chart created by R script --->
							<img src="/metrics/R/graphs/chart1.png" width="672" />
							
							<!---<p class="small mt-3">MCZbase data used in chart can be <a href="#filePath##targetFile#">downloaded</a>. Chart and data are updated on Fridays at midnight (1 fiscal year back to present ).</p>--->
						</div>
					</div>
				</div>
				<cfcatch>
					<cfset error_message = cfcatchToErrorMessage(cfcatch)>
					<cfset function_called = "#GetFunctionCalledName()#">
					<h2 class="h3">Error in #function_called#:</h2>
					<div>#error_message#</div>
				</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="getAnnualChartThread" />
	<cfreturn getAnnualChartThread.output>
</cffunction>
						
<!--- getAnnualNumbers  REPORT: HOLDINGS within an arbitary period, holdings as of endDate
@param beginDate starting date for range to report 
@param endDate end date for range to report
@param returnAs html or csv, if csv returns result as csv, otherwise as html table 
--->
<cffunction name="getNumbers" access="remote" returntype="any" returnformat="json">
	<cfargument name="beginDate" type="any" required="yes">
	<cfargument name="endDate" type="any" required="yes">
	<cfargument name="annualReport" type="any" required="yes">
	<cfargument name="returnAs" type="string" required="no" default="html">

	<!--- make arguments available within thread --->
	<cfset variables.beginDate = arguments.beginDate>
	<cfset variables.endDate = arguments.endDate>
	<cfset variables.annualReport = arguments.annualReport>
	<cfset variables.returnAs = arguments.returnAs>
	<cfthread name="getNumbersThread">
		<cftry>
			<!--- annual report queries: holdings by collection --->
			<cfquery name="totals" datasource="uam_god" cachedwithin="#createtimespan(0,0,0,0)#">
				SELECT 
					h.Collection, 
					rm.metric,
					h.Cataloged_Items, 
					h.Specimens, 
					nvl(p.Primary_Cat_Items,0) Primary_Cat_Items, 
					nvl(p.Primary_Specimens,0) Primary_Specimens, 
					nvl(s.Secondary_Cat_Items,0) Secondary_Cat_Items, 
					nvl(s.Secondary_Specimens,0) Secondary_Specimens
				FROM 
					(select collection_cde,institution_acronym,descr,collection,collection_id from collection where collection_cde <> 'MCZ') c
				LEFT JOIN 
					(select collection_id, metric,
					reported_date from MCZBASE.collections_reported_metrics
					where 
					metric='HOLDINGS' and 
					to_char(reported_date, 'yyyy')=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#left(endDate,4)#">
					) rm on c.collection_id = rm.collection_id 
				LEFT JOIN 
					(select f.collection_id, f.collection, count(distinct f.collection_object_id) Cataloged_Items, sum(decode(total_parts,null, 1,total_parts)) specimens from flat f join coll_object co on f.collection_object_id = co.collection_object_id where co.COLL_OBJECT_ENTERED_DATE < to_date(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#endDate#">, 'YYYY-MM-DD') group by f.collection_id, f.collection) h on rm.collection_id = h.collection_id
				LEFT JOIN 
					(select f.collection_id, f.collection, ts.CATEGORY, count(distinct f.collection_object_id) Primary_Cat_Items, sum(decode(total_parts,null, 1,total_parts)) Primary_Specimens from coll_object co join flat f on co.collection_object_id = f.collection_object_id join citation c on f.collection_object_id = c.collection_object_id join ctcitation_type_status ts on c.type_status =  ts.type_status where ts.CATEGORY in ('Primary') and co.COLL_OBJECT_ENTERED_DATE <  to_date(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#endDate#">, 'YYYY-MM-DD') group by f.collection_id, f.collection, ts.CATEGORY) p on h.collection_id = p.collection_id
				LEFT JOIN 
					(select f.collection_id, f.collection, ts.CATEGORY, count(distinct f.collection_object_id) Secondary_Cat_Items, sum(decode(total_parts,null, 1,total_parts)) Secondary_Specimens from coll_object co join flat f on co.collection_object_id = f.collection_object_id join citation c on f.collection_object_id = c.collection_object_id join ctcitation_type_status ts on c.type_status =  ts.type_status where ts.CATEGORY in ('Secondary') and co.COLL_OBJECT_ENTERED_DATE <  to_date(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#endDate#">, 'YYYY-MM-DD') group by f.collection_id, f.collection, ts.CATEGORY) s on h.collection_id = s.collection_id
			</cfquery>
			<cfif variables.returnAs EQ "csv">
				<cfset csv = queryToCSV(totals)> 
				<cfoutput>#csv#</cfoutput>
			<cfelse>
				<cfoutput>
					<section class="col-12 mt-1 px-0">
						<div class="my-2 float-left w-100">
							<h2 class="h3 mt-0 px-0 float-left mb-1"><cfif annualReport eq "yes">Annual Report</cfif> Holdings <span class="text-muted">(as of #encodeForHtml(endDate)#)</span></h2>
							<div class="btn-toolbar my-1 mt-md-0 float-right">
								<div class="btn-group mr-2">
									<a href="/metrics/Dashboard.cfm?action=dowloadHoldings&returnAs=csv&annualReport=#annualReport#&beginDate=#encodeForURL(beginDate)#&endDate=#encodeForUrl(endDate)#" class="btn btn-xs btn-outline-secondary">Export Table</a>
								</div>
							</div>
						</div>
						<div class="table-responsive-lg">
							<table class="table table-striped" id="t">
								<thead>
									<tr>
										<th><strong>Collection</strong></th>
										<!---<th><strong>Total Holdings</strong></th>--->
										<th><strong>Total Records - Cataloged Items</strong></th>
										<th><strong>Total Records - Specimens</strong></th>
										<th><strong>Primary Types - Cataloged Items</strong></th>
										<th><strong>Primary Types - Specimens</strong></th>
										<th><strong>Secondary Types - Cataloged Items</strong></th>
										<th><strong>Secondary Types - Specimens</strong></th>
									</tr>
								</thead>
								<tbody>
									<cfloop query="totals">
										<tr>
											<td>#Collection#</td>
									<!---		<td>#NumberFormat((Cataloged_Items/Value)*100, '9.99')#%</td>--->
											<td>#Cataloged_Items#</td>
											<td>#Specimens#</td>
											<td>#Primary_Cat_Items#</td>
											<td>#Primary_Specimens#</td>
											<td>#Secondary_Cat_Items#</td>
											<td>#Secondary_Specimens#</td>
										</tr>
									</cfloop>
								</tbody>
							</table>
						</div>
					</section>
				</cfoutput>
			</cfif>
		<cfcatch>
			<cfoutput>
				<cfset error_message = cfcatchToErrorMessage(cfcatch)>
				<cfset function_called = "#GetFunctionCalledName()#">
				<h2 class="h3">Error in #function_called#:</h2>
				<div>#error_message#</div>
			</cfoutput>
		</cfcatch>
		</cftry>
	</cfthread>
	<cfthread action="join" name="getNumbersThread" />
	<cfreturn getNumbersThread.output>
</cffunction>

<!--- getAcquisitions REPORT: ACQUISITIONS within a specified time period 
@param beginDate starting date for range to report 
@param endDate end date for range to report
@param returnAs html or csv, if csv returns result as csv, otherwise as html table 
--->
<cffunction name="getAcquisitions" access="remote" returntype="any" returnformat="json">
	<cfargument name="beginDate" type="any" required="yes">
	<cfargument name="endDate" type="any" required="yes">
	<cfargument name="annualReport" type="any" required="yes">
	<cfargument name="returnAs" type="string" required="no" default="html">
	
	<!--- make arguments available within thread --->
	<cfset variables.beginDate = arguments.beginDate>
	<cfset variables.endDate = arguments.endDate>
	<cfset variables.annualReport = arguments.annualReport>
	<cfset variables.returnAs = arguments.returnAs>
	<cfthread name="getAcquisitionsThread">
		<cftry>
			<!--- annual report queries --->
			<cfquery name="ACtotals" datasource="uam_god" cachedwithin="#createtimespan(7,0,0,0)#">
				SELECT
					h.Collection, 
					a.Received_Cat_Items,
					a.Received_Specimens,
					e.Entered_Cat_Items,
			<!---		e.Entered_Specimens,--->
					ncbi.NCBI_Cat_Items,
					accn.Num_Accns,
					h.Cataloged_Items, 
					h.Specimens,
					<cfif annualReport eq 'yes'>c.institution_acronym</cfif>
				FROM 
					(select collection_cde,institution_acronym,descr,collection,collection_id from collection where collection_cde <> 'MCZ') c
				LEFT JOIN 
					(select f.collection_id, f.collection, count(distinct f.collection_object_id) Cataloged_Items, sum(decode(total_parts,null, 1,total_parts)) Specimens from flat f join coll_object co on f.collection_object_id = co.collection_object_id where co.COLL_OBJECT_ENTERED_DATE < to_date(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#endDate#">, 'YYYY-MM-DD') group by f.collection_id, f.collection) h on c.collection_id = h.collection_id
				LEFT JOIN 
					(select f.collection_id, f.collection, count(distinct collection_object_id) Received_Cat_Items, sum(decode(total_parts,null, 1,total_parts)) Received_Specimens from flat f join accn a on f.ACCN_ID = a.transaction_id join trans t on a.transaction_id = t.transaction_id where a.received_DATE between  to_date(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#beginDate#">, 'YYYY-MM-DD') and  to_date(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#endDate#">, 'YYYY-MM-DD') group by f.collection_id, f.collection) a on h.collection_id = a.collection_id
				LEFT JOIN 
					(select f.collection_id, f.collection, count(distinct f.collection_object_id) Entered_Cat_Items, sum(decode(total_parts,null, 1,total_parts)) Entered_Specimens from flat f join coll_object co on f.collection_object_id = co.collection_object_id where co.COLL_OBJECT_ENTERED_DATE between to_date(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#beginDate#">, 'YYYY-MM-DD') and  to_date(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#endDate#">, 'YYYY-MM-DD') group by f.collection_id, f.collection) e on e.collection_id = h.collection_id
				LEFT JOIN 
					(select f.collection_id, f.collection, count(distinct f.collection_object_id) NCBI_Cat_Items, sum(total_parts) ncbiSpecimens from COLL_OBJ_OTHER_ID_NUM oid, flat f, COLL_OBJECT CO where OTHER_ID_TYPE like '%NCBI%' AND F.COLLECTION_OBJECT_ID = CO.COLLECTION_OBJECT_ID and co.COLL_OBJECT_ENTERED_DATE < to_date(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#endDate#">, 'YYYY-MM-DD') and oid.collection_object_id = f.collection_object_id group by f.collection_id, f.collection) ncbi on h.collection_id = ncbi.collection_id
				LEFT JOIN 
					(select c.collection_id, c.collection, count(distinct t.transaction_id) Num_Accns from accn a, trans t, collection c where a.transaction_id = t.transaction_id and t.collection_id = c.collection_id and a.received_date between to_date(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#beginDate#">, 'YYYY-MM-DD') and  to_date(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#endDate#">, 'YYYY-MM-DD') group by c.collection_id, c.collection) accn on h.collection_id = accn.collection_id
			</cfquery>
			<cfif variables.returnAs EQ "csv">
				<cfset csv = queryToCSV(ACtotals)> 
				<cfoutput>#csv#</cfoutput>
			<cfelse>
				<cfoutput>
					<section class="col-12 mt-2 px-0">
						<div class="my-2 float-left w-100">
							<h2 class="h3 mt-0 mb-1 px-0 float-left"><cfif annualReport eq "yes">Annual Report:</cfif> Acquisitions <span class="text-muted">(#encodeForHtml(beginDate)#/#encodeForHtml(endDate)#)</span></h2>
							<div class="btn-toolbar my-1 mt-md-0 float-right">
								<div class="btn-group mr-2">
									<a href="/metrics/Dashboard.cfm?action=dowloadAcquisitions&returnAs=csv&annualReport=#annualReport#&beginDate=#encodeForURL(beginDate)#&endDate=#encodeForUrl(endDate)#" class="btn btn-xs btn-outline-secondary">Export Table</a>
								</div>
							</div>
						</div>
						<div class="table-responsive-lg">
							<table class="table table-striped" id="t">
								<thead>
									<tr>
										<th><strong>Collection</strong></th>
										<th><strong>Acquired Cataloged Items</strong></th>
										<th><strong>Acquired Specimens</strong></th>
										<th><strong>New Records Entered in MCZbase - Cataloged Items</strong></th>
										<th><strong>Number of Genetic Samples added To Cryo</strong></th>
										<th><strong>Number of Cataloged Items with NCBI numbers</strong></th>
										<!---th><strong>Number of NCBI numbers added</strong></th--->
										<th><strong>Items received but not Cataloged at End of Year</strong></th>
										<th><strong>Number of Accessions</strong></th>
										<!---th><strong>Total Cataloged Items</strong></th>
										<th><strong>Total Specimens (parts)</strong></th--->
										<cfif annualRport eq 'yes'><th>Institution Acronym</th></cfif>
									</tr>
								</thead>
								<tbody>
									<cfloop query="ACtotals">
										<tr>
											<td>#collection#</td>
											<td>#Received_Cat_Items#</td>
											<td>#Received_Specimens#</td>
											<td>#Entered_Cat_Items#</td>
											<td>N/A</td>
											<td>#NCBI_Cat_Items#</td>
											<!---td>N/A</td--->
											<td>N/A</td>
											<td>#Num_Accns#</td>
											<!---td>#Cataloged_Items#</td>
											<td>#Specimens#</td--->
											<cfif annualRport eq 'yes'><td>#c.institution_acronym#</td></cfif>
										</tr>
									</cfloop>
								</tbody>
							</table>
						</div>
					</section>
				</cfoutput>
			</cfif>
		<cfcatch>
			<cfoutput>
				<cfset error_message = cfcatchToErrorMessage(cfcatch)>
				<cfset function_called = "#GetFunctionCalledName()#">
				<h2 class="h3">Error in #function_called#:</h2>
				<div>#error_message#</div>
			</cfoutput>
		</cfcatch>
		</cftry>
	</cfthread>
	<cfthread action="join" name="getAcquisitionsThread" />
	<cfreturn getAcquisitionsThread.output>
</cffunction>
					
<!--- getLoanNumbers report on loan activity 
@param beginDate starting date for range to report 
@param endDate end date for range to report
@param returnAs html or csv, if csv returns result as csv, otherwise as html table 
--->
<cffunction name="getLoanNumbers" access="remote" returntype="any" returnformat="json">
	<cfargument name="endDate" type="any" required="yes" default="2024-06-30">
	<cfargument name="beginDate" type="any" required="yes" default="2023-07-01">
	<cfargument name="annualReport" type="any" required="yes">
	<cfargument name="returnAs" type="string" required="no" default="html">
	
	<!--- make arguments available within thread --->
	<cfset variables.beginDate = arguments.beginDate>
	<cfset variables.endDate = arguments.endDate>
	<cfset variables.annualReport = arguments.annualReport>
	<cfset variables.returnAs = arguments.returnAs>
	<cfthread name="getLoanNumbersThread">
		<cftry>
			<!--- annual report queries for loan activity --->
			<cfquery name="loans" datasource="uam_god" cachedwithin="#createtimespan(7,0,0,0)#">
				SELECT
					c.Collection, 
					ol.Num_Outgoing_Loans,
					cl.Num_Closed_Loans,
					fy.Num_5yr_Loans,
					ty.Num_10yr_Loans,
					b.Num_Borrows,
					opL.Num_Open_Loans,
					open5.Num_Open_OverDue_5yrs,
					open10.Num_Open_OverDue_10yrs,
					ol.Outgoing_CatItems,
					ol.Outgoing_Specimens
				FROM
					(select collection_cde,institution_acronym,descr,collection,collection_id from collection where collection_cde <> 'MCZ') c
				LEFT JOIN
					(select c.collection_id, collection, count(distinct l.transaction_id) Num_Outgoing_Loans, count(distinct sp.derived_from_cat_item) Outgoing_CatItems, sum(co.lot_count) as Outgoing_Specimens
					from loan l, trans t, collection c, loan_item li, specimen_part sp, coll_object co
					where l.transaction_id = t.transaction_id
					and t.collection_id = c.collection_id
					and t.transaction_id = li.transaction_id(+)
					and li.collection_object_id = sp.collection_object_id(+)
					and sp.collection_object_id = co.collection_object_id(+)
					and t.TRANS_DATE between to_date(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#beginDate#">, 'YYYY-MM-DD') and  to_date(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#endDate#">, 'YYYY-MM-DD')
					group by c.collection_id, c.collection) ol on c.collection_id = ol.collection_id
				LEFT JOIN (select c.collection_id, collection, count(distinct l.transaction_id) Num_Closed_Loans
					from loan l, trans t, collection c, loan_item li, specimen_part sp, coll_object co
					where l.transaction_id = t.transaction_id
					and t.collection_id = c.collection_id
					and t.transaction_id = li.transaction_id(+)
					and li.collection_object_id = sp.collection_object_id(+)
					and sp.collection_object_id = co.collection_object_id(+)
					and l.CLOSED_DATE between to_date(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#beginDate#">, 'YYYY-MM-DD') and  to_date(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#endDate#">, 'YYYY-MM-DD')
					group by c.collection_id, collection) cl on c.collection_id = cl.collection_id
				LEFT JOIN (select c.collection_id, collection_cde, count(*)as Num_5yr_Loans
					from loan l, trans t, collection c
					where l.transaction_id = t.transaction_id
					and t.collection_id = c.collection_id
					and l.CLOSED_DATE between to_date(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#beginDate#">, 'YYYY-MM-DD') and  to_date(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#endDate#">, 'YYYY-MM-DD')
					and l.closed_date -l.return_due_date > (365*5)
					group by c.collection_id, collection_cde) fy on c.collection_id = fy.collection_id
				LEFT JOIN (select c.collection_id, collection_cde, count(*) as Num_10yr_Loans
					from loan l, trans t, collection c
					where l.transaction_id = t.transaction_id
					and t.collection_id = c.collection_id
					and l.CLOSED_DATE between to_date(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#beginDate#">, 'YYYY-MM-DD') and  to_date(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#endDate#">, 'YYYY-MM-DD')
					and l.closed_date -l.return_due_date > (365*10)
					group by c.collection_id, collection_cde) ty on c.collection_id = ty.collection_id
				LEFT JOIN (select c.collection_id, collection, count(*) as Num_Borrows 
					from borrow l, trans t, collection c
					where l.transaction_id = t.transaction_id
					and t.collection_id = c.collection_id
					and l.RECEIVED_DATE between to_date(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#beginDate#">, 'YYYY-MM-DD') and  to_date(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#endDate#">, 'YYYY-MM-DD')
					group by c.collection_id, collection) b on c.collection_id = b.collection_id
				LEFT JOIN (select c.collection_id, collection_cde, count(*) as Num_Open_Loans 
					from loan l, trans t, collection c
					where l.transaction_id = t.transaction_id
					and t.collection_id = c.collection_id
					and (loan_status like '%open%' or closed_date > to_date(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#endDate#">, 'YYYY-MM-DD'))
					and t.trans_date <  to_date(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#endDate#">, 'YYYY-MM-DD')
					group by c.collection_id, collection_cde) opL on c.collection_id = opL.collection_id
				LEFT JOIN (select c.collection_id, collection, count(*) Num_Open_OverDue_5yrs 
					from loan l, trans t, collection c
					where l.transaction_id = t.transaction_id
					and t.collection_id = c.collection_id
					and (loan_status like '%open%' or closed_date > to_date(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#endDate#">, 'YYYY-MM-DD'))
					and t.trans_date < to_date(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#endDate#">, 'YYYY-MM-DD')
					and to_date(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#endDate#">, 'YYYY-MM-DD') - l.return_due_date > 365*5
					group by c.collection_id, collection) open5 on c.collection_id = open5.collection_id
				LEFT JOIN (select c.collection_id, collection, count(*) Num_Open_OverDue_10yrs
					from loan l, trans t, collection c
					where l.transaction_id = t.transaction_id
					and t.collection_id = c.collection_id
					and (loan_status like '%open%' or closed_date > to_date(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#endDate#">, 'YYYY-MM-DD'))
					and t.trans_date < to_date(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#endDate#">, 'YYYY-MM-DD')
					and to_date(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#endDate#">, 'YYYY-MM-DD') - l.return_due_date > 365*10
					group by c.collection_id, collection) open10 on c.collection_id = open10.collection_id
				ORDER BY collection
			</cfquery>
			<cfif variables.returnAs EQ "csv">
				<cfset csv = queryToCSV(loans)> 
				<cfoutput>#csv#</cfoutput>
			<cfelse>
				<cfoutput>
					<section class="col-12 mt-2 px-0">
						<div class="my-2 float-left w-100">
							<h2 class="h3 mt-0 px-0 float-left mb-1"><cfif annualReport eq "yes">Annual Report:</cfif> Loan Activity <span class="text-muted">(#encodeForHtml(beginDate)#/#encodeForHtml(endDate)#)</span></h2>
							<div class="btn-toolbar my-1 mt-md-0 float-right">
								<div class="btn-group mr-2">
									<a href="/metrics/Dashboard.cfm?action=dowloadLoanActivity&returnAs=csv&annualReport=#annualReport#&beginDate=#encodeForURL(beginDate)#&endDate=#encodeForUrl(endDate)#" class="btn btn-xs btn-outline-secondary">Export Table</a>
								</div>
							</div>
						</div>
						<div class="table-responsive-lg">
							<table class="table table-striped" id="t">
								<thead>
									<tr>
										<th><strong>Collection</strong></th>
										<th><strong>Outgoing Loans</strong></th>
										<th><strong>Closed Loans</strong></th>
										<th><strong>Closed Overdue (>5 years) Loans</strong></th>
										<th><strong>Closed Overdue (>10 years) Loans</strong></th>
										<th><strong>Incoming loans (=Borrows)</strong></th>
										<th><strong>Number of Open Loans</strong></th>
										<th><strong>Number of Open Loans overdue > 5 years</strong></th>
										<th><strong>Number of Open Loans overdue > 10 year</strong></th>
										<th><strong>Outgoing Cataloged Items</strong></th>
										<th><strong>Outgoing Specimens</strong></th>
									</tr>
								</thead>
								<tbody>
									<cfloop query="loans">
										<tr>
											<td>#Collection#</td>
											<td>#Num_Outgoing_Loans#</td>
											<td>#Num_Closed_Loans#</td>
											<td>#Num_5yr_Loans#</td>
											<td>#Num_10yr_Loans#</td>
											<td>#Num_Borrows#</td>
											<td>#Num_Open_Loans#</td>
											<td>#Num_Open_OverDue_5yrs#</td>
											<td>#Num_Open_OverDue_10yrs#</td>
											<td>#Outgoing_CatItems#</td>
											<td>#Outgoing_Specimens#</td>
										</tr>
									</cfloop>
								</tbody>
							</table>
						</div>
					</section>
				</cfoutput>
			</cfif>
		<cfcatch>
			<cfoutput>
				<cfset error_message = cfcatchToErrorMessage(cfcatch)>
				<cfset function_called = "#GetFunctionCalledName()#">
				<h2 class="h3">Error in #function_called#:</h2>
				<div>#error_message#</div>
			</cfoutput>
		</cfcatch>
		</cftry>
	</cfthread>
	<cfthread action="join" name="getLoanNumbersThread" />
	<cfreturn getLoanNumbersThread.output>
</cffunction>

<!--- getMediaNumbers report on media activity in a specified time period 
@param beginDate starting date for range to report 
@param endDate end date for range to report
@param returnAs html or csv, if csv returns result as csv, otherwise as html table 
--->
<cffunction name="getMediaNumbers" access="remote" returntype="any" returnformat="json">
	<cfargument name="endDate" type="any" required="no" default="2024-06-30">
	<cfargument name="beginDate" type="any" required="no" default="2023-07-01">
	<cfargument name="annualReport" type="any" required="yes">
	<cfargument name="returnAs" type="string" required="no" default="html">
	
	<!--- make arguments available within thread --->
	<cfset variables.beginDate = arguments.beginDate>
	<cfset variables.endDate = arguments.endDate>
	<cfset variables.annualReport = arguments.annualReport>
	<cfset variables.returnAs = arguments.returnAs>
	<cfthread name="getMediaNumbersThread">
		<cftry>
			<!--- annual report queries --->
			<cfquery name="media" datasource="uam_god" cachedwithin="#createtimespan(7,0,0,0)#">
				SELECT
					c.collection,
					i.Num_Images_Cat_Items,
					i.Num_Images,
					pt.Images_Primary_Cat_Items,
					st.Images_Secondary_Cat_Items
				FROM
					(select * from collection where collection_cde <> 'MCZ') c
					left join (select f.collection_id, f.collection, count(distinct f.collection_object_id) Num_Images_Cat_Items, sum(total_parts) numImagesSpecimens, count(distinct m.media_id) Num_Images
					from media m, MEDIA_RELATIONS mr, flat f, coll_object co 
					where m.media_id = mr.media_id
					and mr.MEDIA_RELATIONSHIP = 'shows cataloged_item'
					and mr.RELATED_PRIMARY_KEY = f.collection_object_id
					and f.collection_object_id = co.collection_object_id
					group by f.collection_id, f.collection) i on c.collection_id = i.collection_id
				LEFT JOIN 
					(select f.collection_id, f.collection, count(distinct f.collection_object_id) Images_Primary_Cat_Items, sum(decode(total_parts,null, 1,total_parts)) Images_Primary_Specimens
					from flat f, citation c, ctcitation_type_status ts
					where f.collection_object_id = c.collection_object_id
					and c.type_status = ts.type_status
					and ts.CATEGORY in ('Primary')
					and f.collection_object_id in
					(select related_primary_key from MEDIA_RELATIONS where media_relationship='shows cataloged_item')
					group by f.collection_id, f.collection) pt on c.collection_id = pt.collection_id
				LEFT JOIN
					(select f.collection_id, f.collection, count(distinct f.collection_object_id) Images_Secondary_Cat_Items, sum(decode(total_parts,null, 1,total_parts)) Images_Secondary_Specimens
					from flat f, citation c, ctcitation_type_status ts
					where f.collection_object_id = c.collection_object_id
					and c.type_status = ts.type_status
					and ts.CATEGORY in ('Secondary')
					and f.collection_object_id in
					(select related_primary_key from MEDIA_RELATIONS where media_relationship='shows cataloged_item')
					group by f.collection_id, f.collection) st on c.collection_id = st.collection_id
					order by collection
			</cfquery>
			<cfif variables.returnAs EQ "csv">
				<cfset csv = queryToCSV(media)> 
				<cfoutput>#csv#</cfoutput>
			<cfelse>
				<cfoutput>
					<section class="col-12 mt-2 px-0">
						<div class="my-1 float-left w-100">
							<!---
							TODO: Media queries do not use dates. 
							<h2 class="h3 mt-0 px-0 float-left mb-1">Media Activity <span class="text-muted">(#encodeForHtml(beginDate)#/#encodeForHtml(endDate)#)</span></h2>
							--->
							<h2 class="h3 mt-0 px-0 float-left mb-1"><cfif annualReport eq "yes">Annual Report:</cfif> Media Activity <span class="text-muted">(current values)</span></h2>
							<div class="btn-toolbar my-1 mt-md-0 float-right">
								<div class="btn-group mr-2">
									<a href="/metrics/Dashboard.cfm?action=dowloadMediaActivity&returnAs=csv&annualReport=#annualReport#&beginDate=#encodeForURL(beginDate)#&endDate=#encodeForUrl(endDate)#" class="btn btn-xs btn-outline-secondary">Export Table</a>
								</div>
							</div>
						</div>
						<div class="table-responsive-lg">
							<table class="table table-striped" id="t">
								<thead>
									<tr>
										<th><strong>Collection</strong></th>
										<th><strong>Number of Cataloged Items with Media</strong></th>
										<th><strong>Number of Media Items</strong></th>
										<th><strong>Number of Cataloged Items with Media added</strong></th>
										<th><strong>Number of Media Items added</strong></th>
										<th><strong>Number of Primary Types with Images</strong></th>
										<th><strong>% of Primary Types Imaged</strong></th>
										<th><strong>Number of Secondary Types with Images</strong></th>
									</tr>
								</thead>
								<tbody>
									<cfloop query="media">
										<tr>
											<td>#Collection#</td>
											<td>#Num_Images_Cat_Items#</td>
											<td>#Num_Images#</td>
											<td>N/A</td>
											<td>N/A</td>
											<td>#Images_Primary_Cat_Items#</td>
											<td>N/A</td>
											<td>#Images_Secondary_Cat_Items#</td>
										</tr>
									</cfloop>
								</tbody>
							</table>
						</div>
					</section>
				</cfoutput>
			</cfif>
		<cfcatch>
			<cfoutput>
				<cfset error_message = cfcatchToErrorMessage(cfcatch)>
				<cfset function_called = "#GetFunctionCalledName()#">
				<h2 class="h3">Error in #function_called#:</h2>
				<div>#error_message#</div>
			</cfoutput>
		</cfcatch>
		</cftry>
	</cfthread>
	<cfthread action="join" name="getMediaNumbersThread" />
	<cfreturn getMediaNumbersThread.output>
</cffunction>

<!--- getCitationNumbers obtain report on citations of specimens within a specified time period.				
@param beginDate starting date for range to report 
@param endDate end date for range to report
@param returnAs html or csv, if csv returns result as csv, otherwise as html table 
--->
<cffunction name="getCitationNumbers" access="remote" returntype="any" returnformat="json">
	<cfargument name="endDate" type="any" required="no" default="2024-06-30">
	<cfargument name="beginDate" type="any" required="no" default="2023-07-01">
	<cfargument name="annualReport" type="any" required="yes">
	<cfargument name="returnAs" type="string" required="no" default="html">
	
	<!--- make arguments available within thread --->
	<cfset variables.beginDate = arguments.beginDate>
	<cfset variables.endDate = arguments.endDate>
	<cfset variables.annualReport = arguments.annualReport>
	<cfset variables.returnAs = arguments.returnAs>
	<cfthread name="getCitationNumbersThread">
		<cftry>
			<!--- annual report queries, citation activity --->
			<cfquery name="citationNums" datasource="uam_god" result="citation_result" cachedwithin="#createtimespan(7,0,0,0)#">
				SELECT
					c.Collection,
					cit.Num_Citations,
					cit.Num_Citation_Cat_Items,
					cit.Num_Genetic_Citations
				FROM
					(select collection_cde,institution_acronym,descr,collection,collection_id from collection where collection_cde <> 'MCZ') c
				LEFT JOIN 
					(select coll.collection_id, coll.collection, count(distinct f.collection_object_id) Num_Citation_Cat_Items, count(*) Num_Citations, sum(decode(c.type_status, 'Genetic Voucher',1,0)) Num_Genetic_Citations 
					from coll_object co,  flat f,  citation c,  publication p, collection coll
					where f.collection_object_id = co.collection_object_id
					and f.collection_object_id = c.collection_object_id 
					and c.publication_id = p.publication_id
					and f.collection_cde = coll.collection_cde
					and p.publication_title not like '%Placeholder%'
					and co.COLL_OBJECT_ENTERED_DATE <  to_date(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#endDate#">, 'YYYY-MM-DD')
					GROUP BY coll.collection_id, coll.collection) cit on c.collection_id = cit.collection_id
				</cfquery>
			<cfif variables.returnAs EQ "csv">
				<cfset csv = queryToCSV(citationNums)> 
				<cfoutput>#csv#</cfoutput>
			<cfelse>
				<cfoutput>
					<section class="col-12 mt-2 px-0">
						<div class="my-2 float-left w-100">
							<!--- 
								TODO: Citation query does not use dates 
							<h2 class="h3 px-0 mt-0 float-left mb-0">Citation Activity <span class="text-muted">(#encodeForHtml(beginDate)#/#encodeForHtml(endDate)#)</span></h2>
							--->
							<h2 class="h3 px-0 mt-0 float-left mb-0"><cfif annualReport eq "yes">Annual Report:</cfif> Citation Activity <span class="text-muted">(current values)</span></h2>
							<div class="btn-toolbar my-1 mt-md-0 float-right">
								<div class="btn-group mr-2">
									<a href="/metrics/Dashboard.cfm?action=dowloadCitationActivity&returnAs=csv&annualReport=#annualReport#&beginDate=#encodeForURL(beginDate)#&endDate=#encodeForUrl(endDate)#" class="btn btn-xs btn-outline-secondary">Export Table</a>
								</div>
							</div>
						</div>
						<div class="table-responsive-lg">
							<table class="table table-striped" id="t">
								<thead>
									<tr>
										<th><strong>Collection</strong></th>
										<th><strong>Total Citations</strong></th>
										<th><strong>Number of Cataloged Items with Citations</strong></th>
										<!---th><strong>Number of Cataloged Items with Full Citations (w/ogenetic vouchers) added</strong></th--->
										<th><strong>Number of Genetic Voucher Citations</strong></th>
									</tr>
								</thead>
								<tbody>
									<cfloop query="citationNums">
										<tr>
											<td>#Collection#</td>
											<td>#Num_Citations#</td>
											<td>#Num_Citation_Cat_Items#</td>
											<!---td>N/A</td--->
											<td>#Num_Genetic_Citations#</td>
										</tr>
									</cfloop>
								</tbody>
							</table>
						</div>
					</section>
				</cfoutput>
			</cfif>
		<cfcatch>
			<cfoutput>
				<cfset error_message = cfcatchToErrorMessage(cfcatch)>
				<cfset function_called = "#GetFunctionCalledName()#">
				<h2 class="h3">Error in #function_called#:</h2>
				<div>#error_message#</div>
			</cfoutput>
		</cfcatch>
		</cftry>
	</cfthread>
	<cfthread action="join" name="getCitationNumbersThread" />
	<cfreturn getCitationNumbersThread.output>
</cffunction>

<!--- getGeorefNumbers report on georeferences and georeferencing activity within a specified time period 			
@param beginDate starting date for range to report 
@param endDate end date for range to report
@param returnAs html or csv, if csv returns result as csv, otherwise as html table 
--->
<cffunction name="getGeorefNumbers" access="remote" returntype="any" returnformat="json">
	<cfargument name="endDate" type="any" required="no" default="2024-06-30">
	<cfargument name="beginDate" type="any" required="no" default="2023-07-01">
	<cfargument name="annualReport" type="any" required="yes">
	<cfargument name="returnAs" type="string" required="no" default="html">
	
	<!--- make arguments available within thread --->
	<cfset variables.beginDate = arguments.beginDate>
	<cfset variables.endDate = arguments.endDate>
	<cfset variables.annualReport = arguments.annualReport>
	<cfset variables.returnAs = arguments.returnAs>
	<cfthread name="getGeorefNumbersThread">
		<cftry>
			<cfquery name="georef" datasource="uam_god" cachedwithin="#createtimespan(7,0,0,0)#">
				SELECT
					c.Collection,
					l.Num_Localities,
					gl.Num_GeoRef_Localities,
					vgl.Num_Verified_GeoRef_Localities,
					gl.Num_GeoRef_Cat_Items
				FROM
					(select * from collection where collection_cde<>'MCZ') c
					left join (select collection_id, collection, count(distinct locality_id) Num_Localities 
					from flat
					group by collection_id, collection) l on c.collection_id = l.collection_id
				LEFT JOIN
					(select f.collection_id, f.collection, count(distinct f.collection_object_id) Num_GeoRef_Cat_Items, sum(total_parts) Num_GeoRef_Specimens, count(distinct locality_id) Num_GeoRef_Localities
					from flat f, coll_object co
					where dec_lat is not null and dec_long is not null
					and f.collection_object_id = co.collection_object_id
					group by f.collection_id, f.collection) gl on c.collection_id = gl.collection_id
				LEFT JOIN
					(select f.collection_id, f.collection, count(distinct f.collection_object_id) Num_GeoRef_Cat_Items, sum(total_parts) Num_Verified_GeoRef_Specimens, count(distinct locality_id) Num_Verified_GeoRef_Localities
					from flat f, coll_object co
					where dec_lat is not null and dec_long is not null
					and f.collection_object_id = co.collection_object_id
					and f.VERIFICATIONSTATUS like 'verified%'
					group by f.collection_id, f.collection) vgl on c.collection_id = vgl.collection_id
			</cfquery>
			<cfif variables.returnAs EQ "csv">
				<cfset csv = queryToCSV(georef)> 
				<cfoutput>#csv#</cfoutput>
			<cfelse>
				<cfoutput>
					<section class="col-12 mt-2 px-0">
						<div class="my-2 float-left w-100">
							<!--- 
								TODO: Georeferencing queries do not use dates 
							<h2 class="h3 px-0 mt-0 float-left mb-0">Georeferencing Activity 
								<span class="text-muted">(#encodeForHtml(beginDate)#/#encodeForHtml(endDate)#)</span>
							</h2>
							--->
							<h2 class="h3 px-0 mt-0 float-left mb-0"><cfif annualReport eq "yes">Annual Report:</cfif> Georeferencing Activity 
								<span class="text-muted">(current values)</span>
							</h2>
							<div class="btn-toolbar my-1 mt-lg-0 float-right">
								<div class="btn-group mr-2">
									<a href="/metrics/Dashboard.cfm?action=dowloadGeoreferenceActivity&returnAs=csv&annualReport=#annualReport#&beginDate=#encodeForURL(beginDate)#&endDate=#encodeForUrl(endDate)#" class="btn btn-xs btn-outline-secondary">Export Table</a>
								</div>
							</div>
						</div>
						<div class="table-responsive-lg">
							<table class="table table-striped" id="t">
								<thead>
									<tr>
										<th><strong>Collection</strong></th>
										<th><strong>Total Number of Localities</strong></th>
										<th><strong>Records Georeferenced - Localities</strong></th>
										<th><strong>% of Localities Georeferenced</strong></th>
										<th><strong>Records Georeferences Verified - Localities</strong></th>
										<th><strong>Records Georeferenced Total - Cataloged Items</strong></th>
										<th><strong>% of Cataloged Items Georeferenced</strong></th>
										<th><strong>Records Georeferenced in FY - Localities</strong></th>
										<th><strong>Records Georeferenced in FY - Cataloged Items</strong></th>
									</tr>
								</thead>
								<tbody>
									<cfloop query="georef">
										<tr>
											<td>#Collection#</td>
											<td>#Num_Localities#</td>
											<td>#Num_GeoRef_Localities#</td>
											<td>#NumberFormat((Num_GeoRef_Localities/Num_Localities)*100, '9.99')#%</td>
											<td>#Num_Verified_GeoRef_Localities#</td>
											<td>#Num_GeoRef_Cat_Items#</td>
											<td>N/A</td>
											<td>N/A</td>
											<td>N/A</td>
										</tr>
									</cfloop>
								</tbody>
							</table>
						</div>
					</section>
				</cfoutput>
			</cfif>
		<cfcatch>
			<cfoutput>
				<cfset error_message = cfcatchToErrorMessage(cfcatch)>
				<cfset function_called = "#GetFunctionCalledName()#">
				<h2 class="h3">Error in #function_called#:</h2>
				<div>#error_message#</div>
			</cfoutput>
		</cfcatch>
		</cftry>
	</cfthread>
	<cfthread action="join" name="getGeorefNumbersThread" />
	<cfreturn getGeorefNumbersThread.output>
</cffunction>



</cfcomponent>