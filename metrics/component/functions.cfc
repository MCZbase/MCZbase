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
	<cfset tn = REReplace(CreateUUID(), "[-]", "", "all") >
	<cfthread name="getAnnualChartThread#tn#">
		<cfoutput>
			<cfset targetFile = "chart_numbers.csv">
			<cfset filePath = "/metrics/datafiles/">
			<cftry>
				<div class="container">
					<div class="row">
						<div class="col-12 px-0">
							<!--- chart created by R script --->
							<img src="/metrics/R/graphs/chart1.png" width="672" />
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
	<cfthread action="join" name="getAnnualChartThread#tn#" />
	<cfreturn cfthread['getAnnualChartThread#tn#'].output>
</cffunction>
						
<!--- getNumbers  REPORT: HOLDINGS within an arbitary period, holdings as of endDate
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
	<cfset tn = REReplace(CreateUUID(), "[-]", "", "all") >
	<cfthread name="getNumbersThread#tn#">
		<cftry>
			<!--- get correct schema for annual report or date range--->
			<cfif annualReport EQ 'yes'>
				<cfquery name="getendSchema" datasource="uam_god" cachedwithin="#createtimespan(7,0,0,0)#">
					select username from dba_users where username like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="ARCHIVE_#left(endDate,4)#07%"> 
				</cfquery>
				<cfset endschema = getendSchema.username> 
				<cfquery name="getbeginSchema" datasource="uam_god" cachedwithin="#createtimespan(7,0,0,0)#">
					select username from dba_users where username like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="ARCHIVE_#left(beginDate,4)#07%">
				</cfquery>
				<cfset beginschema = getbeginSchema.username>
			<cfelse>
				<cfset beginSchema="MCZBASE">
				<cfset endSchema="MCZBASE">
			</cfif>
			<!--- annual report queries: holdings by collection --->
			<cfquery name="totals" datasource="uam_god" cachedwithin="#createtimespan(7,0,0,0)#">
				SELECT 
					h.Collection, 
					<cfif annualReport EQ "yes">rm.value holdings,</cfif>
					h.Cataloged_Items, 
					h.Specimens, 
					nvl(p.Primary_Cat_Items,0) Primary_Cat_Items, 
					nvl(p.Primary_Specimens,0) Primary_Specimens, 
					nvl(s.Secondary_Cat_Items,0) Secondary_Cat_Items, 
					nvl(s.Secondary_Specimens,0) Secondary_Specimens
				FROM 
					(select collection_cde,institution_acronym,descr,collection,collection_id from collection where collection_cde <> 'MCZ') c
				<cfif annualReport EQ "yes">
				LEFT JOIN 
					(select collection_id,value,reported_date from MCZBASE.collections_reported_metrics where metric='HOLDINGS'
					and to_char(reported_date, 'yyyy')=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#left(endDate,4)#">
					) rm on c.collection_id = rm.collection_id
				</cfif>
				LEFT JOIN 
					(select f.collection_id, f.collection, count(distinct f.collection_object_id) Cataloged_Items, sum(decode(total_parts,null, 1,total_parts)) specimens from #endSchema#.flat f join #endSchema#.coll_object co on f.collection_object_id = co.collection_object_id where co.COLL_OBJECT_ENTERED_DATE < to_date(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#endDate#">, 'YYYY-MM-DD') group by f.collection_id, f.collection) h on c.collection_id = h.collection_id
				LEFT JOIN 
					(select f.collection_id, f.collection, ts.CATEGORY, count(distinct f.collection_object_id) Primary_Cat_Items, sum(decode(total_parts,null, 1,total_parts)) Primary_Specimens from #endSchema#.coll_object co join #endSchema#.flat f on co.collection_object_id = f.collection_object_id join #endSchema#.citation c on f.collection_object_id = c.collection_object_id join ctcitation_type_status ts on c.type_status =  ts.type_status where ts.CATEGORY in ('Primary') and co.COLL_OBJECT_ENTERED_DATE <  to_date(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#endDate#">, 'YYYY-MM-DD') group by f.collection_id, f.collection, ts.CATEGORY) p on h.collection_id = p.collection_id
				LEFT JOIN 
					(select f.collection_id, f.collection, ts.CATEGORY, count(distinct f.collection_object_id) Secondary_Cat_Items, sum(decode(total_parts,null, 1,total_parts)) Secondary_Specimens from #endSchema#.coll_object co join #endSchema#.flat f on co.collection_object_id = f.collection_object_id join #endSchema#.citation c on f.collection_object_id = c.collection_object_id join ctcitation_type_status ts on c.type_status =  ts.type_status where ts.CATEGORY in ('Secondary') and co.COLL_OBJECT_ENTERED_DATE <  to_date(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#endDate#">, 'YYYY-MM-DD') group by f.collection_id, f.collection, ts.CATEGORY) s on h.collection_id = s.collection_id
				ORDER BY COLLECTION
			</cfquery>
			<cfif variables.returnAs EQ "csv">
				<cfset csv = queryToCSV(totals)> 
				<cfoutput>#csv#</cfoutput>
			<cfelse>
				<cfoutput>
					<section class="col-12 mt-1 px-0">
						<div class="my-2 float-left w-100">
							<h2 class="h3 px-0 float-left mb-1 px-0 mt-0">
								<cfif annualReport eq "yes">Annual Report:</cfif> Holdings <span class="text-muted">(as of #encodeForHtml(endDate)#)</span>
							</h3>
							<div class="btn-toolbar my-1 mt-md-0 float-right">
								<div class="btn-group mr-2">
									<button onclick="toggleRow()" class="btn btn-xs btn-primary">Show/Hide Definitions</button> <a type="button" href="/metrics/Dashboard.cfm?action=dowloadHoldings&returnAs=csv&annualReport=#annualReport#&beginDate=#encodeForURL(beginDate)#&endDate=#encodeForUrl(endDate)#" class="btn btn-xs btn-outline-secondary text-decoration-none">Export Table</a>
								</div>
							</div>
						</div>
						<div class="table-responsive-lg">

							<table class="table table-striped" id="t">
								<thead class="thead-light">
									<tr>
										<th>Collection </th>
										<cfif annualReport EQ "yes">
											<th>Total Holdings </th>
											<th>% of Holdings in MCZbase</th>
										</cfif>
										<th>Total Records - Cataloged Items</th>
										<th>Total Records - Specimens</th>
										<th>Primary Types - Cataloged Items</th>
										<th>Primary Types - Specimens</th>
										<th>Secondary Types - Cataloged Items</th>
										<th>Secondary Types - Specimens</th>
									</tr>
								</thead>
								<tbody>
									<tr class="toggle1 hidden">
										<td class="barber_stripes">Column Data Definitions <b>&rarr;</b></td>
										<cfif annualReport EQ "yes">
											<td>Total collection holdings are expressed in cataloged items, which may represent individual specimens or lots. Reported by MCZ curatorial staff and not derived from MCZbase data.</td>
											<td>Total number of specimens represented by records in MCZbase divided by total holdings reported by the collections.</td>
										</cfif>
										<td>The total number of cataloged items in MCZbase.</td>
										<td>The total number of individual specimens represented by cataloged item records.</td>
										<td>The total number of cataloged item records that are primary types with citations.</td>
										<td>The number of individual specimens which are part of primary type cataloged item records with citations.</td>
										<td>The total number of cataloged item records that are secondary types with citations.</td>
										<td>The number of individual specimens which are part of secondary type catalog item records with citations.</td>
									</tr>
									<cfloop query="totals">
										<tr>
											<td>#Collection#</td>
											<cfif annualReport EQ "yes">
												<td>#Holdings#</td>
												<td>#NumberFormat((Cataloged_Items/Holdings)*100, '9.99')#%</td>
											</cfif>
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
						<cfif annualReport EQ "yes">
							<p class="text-muted small">Reports are generated from the current MCZbase data and may not match numbers printed in previous annual reports.</p>
						<cfelse> 
							<p class="text-muted small">Reports are generated from the current MCZbase data for the given date range.</p>
						</cfif>

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
	<cfthread action="join" name="getNumbersThread#tn#" />
	<cfreturn cfthread["getNumbersThread#tn#"].output>
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
	<cfset tn = REReplace(CreateUUID(), "[-]", "", "all") >
	<cfthread name="getAcquisitionsThread#tn#">
		<cftry>
			<cfif annualReport EQ 'yes'>
				<cfquery name="getendSchema" datasource="uam_god" cachedwithin="#createtimespan(7,0,0,0)#">
						select username from dba_users where username like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="ARCHIVE_#left(endDate,4)#07%">
				</cfquery>
				<cfset endschema = getendSchema.username>
				<cfquery name="getbeginSchema" datasource="uam_god" cachedwithin="#createtimespan(7,0,0,0)#">
						select username from dba_users where username like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="ARCHIVE_#left(beginDate,4)#07%">
				</cfquery>
				<cfset beginschema = getbeginSchema.username>
			<cfelse>
				<cfset beginSchema="MCZBASE">
				<cfset endSchema="MCZBASE">
			</cfif>
			<!--- acquisition counts queries --->
			<cfquery name="ACtotals" datasource="uam_god" cachedwithin="#createtimespan(7,0,0,0)#">
				SELECT
					c.Collection, 
					a.Received_Cat_Items,
					a.Received_Specimens,
					e.Entered_Cat_Items,
					ncbi.NCBI_Cat_Items, 
					accn.Num_Accns
					<cfif annualReport eq 'yes'>
					,rm.value numrecnotcat
					,cryo.numAddedCryo
					</cfif>
				FROM 
					(select collection_cde,institution_acronym,descr,collection,collection_id from collection where collection_cde <> 'MCZ') c
				LEFT JOIN 
					(select f.collection_id, f.collection, count(distinct f.collection_object_id) Cataloged_Items, sum(decode(total_parts,null, 1,total_parts)) Specimens from flat f join #endSchema#.coll_object co on f.collection_object_id = co.collection_object_id where co.COLL_OBJECT_ENTERED_DATE < to_date(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#endDate#">, 'YYYY-MM-DD') group by f.collection_id, f.collection) h on c.collection_id = h.collection_id
				LEFT JOIN 
					(select f.collection_id, f.collection, count(distinct collection_object_id) Received_Cat_Items, sum(decode(total_parts,null, 1,total_parts)) Received_Specimens from #endSchema#.flat f join accn a on f.ACCN_ID = a.transaction_id join trans t on a.transaction_id = t.transaction_id where a.received_DATE between  to_date(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#beginDate#">, 'YYYY-MM-DD') and  to_date(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#endDate#">, 'YYYY-MM-DD') group by f.collection_id, f.collection) a on c.collection_id = a.collection_id
				LEFT JOIN 
					(select f.collection_id, f.collection, count(distinct f.collection_object_id) Entered_Cat_Items, sum(decode(total_parts,null, 1,total_parts)) Entered_Specimens from #endSchema#.flat f join #endSchema#.coll_object co on f.collection_object_id = co.collection_object_id where co.COLL_OBJECT_ENTERED_DATE between to_date(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#beginDate#">, 'YYYY-MM-DD') and  to_date(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#endDate#">, 'YYYY-MM-DD') group by f.collection_id, f.collection) e on e.collection_id = c.collection_id
				LEFT JOIN 
					(select f.collection_id, f.collection, count(distinct f.collection_object_id) NCBI_Cat_Items, sum(total_parts) ncbiSpecimens from COLL_OBJ_OTHER_ID_NUM oid, #endSchema#.flat f, COLL_OBJECT CO where OTHER_ID_TYPE like '%NCBI%' AND F.COLLECTION_OBJECT_ID = CO.COLLECTION_OBJECT_ID and co.COLL_OBJECT_ENTERED_DATE < to_date(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#endDate#">, 'YYYY-MM-DD') and oid.collection_object_id = f.collection_object_id group by f.collection_id, f.collection) ncbi on c.collection_id = ncbi.collection_id
				LEFT JOIN 
					(select c.collection_id, c.collection, count(distinct t.transaction_id) Num_Accns from accn a, trans t, collection c where a.transaction_id = t.transaction_id and t.collection_id = c.collection_id and a.received_date between to_date(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#beginDate#">, 'YYYY-MM-DD') and  to_date(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#endDate#">, 'YYYY-MM-DD') group by c.collection_id, c.collection) accn on c.collection_id = accn.collection_id
				<cfif annualReport EQ "yes">
				LEFT JOIN
					(select collection_id,value,reported_date from MCZBASE.collections_reported_metrics where metric='NUMRECNOTCAT'
					and to_char(reported_date, 'yyyy')=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#left(endDate,4)#">
					) rm on c.collection_id = rm.collection_id
				LEFT JOIN
					(select a.collection_id, a.numparts - b.numparts numAddedCryo from
					#endschema#.cryo_counts a
					left join #beginschema#.cryo_counts b on a.collection_id = b.collection_id) cryo on c.collection_id = cryo.collection_id	
				</cfif> 
			ORDER BY COLLECTION
			</cfquery>
			<cfif variables.returnAs EQ "csv">
				<cfset csv = queryToCSV(ACtotals)> 
				<cfoutput>#csv#</cfoutput>
			<cfelse>
				<cfoutput>
					<section class="col-12 mt-2 px-0">
						<div class="my-2 float-left w-100">
							<h2 class="h3 mt-0 mb-1 px-0 float-left">
								<cfif annualReport eq "yes">Annual Report:</cfif> Acquisitions <span class="text-muted">(#encodeForHtml(beginDate)#/#encodeForHtml(endDate)#)</span>
							</h2>
							<div class="btn-toolbar my-1 mt-md-0 float-right">
								<div class="btn-group mr-2">
									<button onclick="toggleRow()" class="btn btn-xs btn-primary">Show/Hide Definitions</button> <a type="button" href="/metrics/Dashboard.cfm?action=dowloadAcquisitions&returnAs=csv&annualReport=#annualReport#&beginDate=#encodeForURL(beginDate)#&endDate=#encodeForUrl(endDate)#" class="btn btn-xs btn-outline-secondary text-decoration-none">Export Table</a>
								</div>
							</div>
						</div>
						<div class="table-responsive-lg">
							<table class="table table-striped" id="t">
								<thead class="thead-light">
									<tr>
										<th>Collection</th>
										<th>Acquired Cataloged Items</th>
										<th>Acquired Specimens</th>
										<th>New Records Entered in MCZbase - Cataloged Items</th>
										<th>Number of Cataloged Items with NCBI numbers</th>
										<cfif annualReport EQ "yes">
											<th>Number of Genetic Samples added To Cryo</th>
										</cfif>
										<th>Number of Accessions in the FY</th>
										<cfif annualReport EQ "yes">
											<th>Items Received but Not Cataloged in the FY</th>
										</cfif>
									</tr>
								</thead>
								<tbody>
									<tr class="toggle1 hidden">
										<td class="barber_stripes">Column Data Definitions <b>&rarr;</b></td>
										<td>The number of databased cataloged items acquired in the FY, derived from the total number of cataloged item records in accessions for the FY.</td>
										<td>The number of specimens acquired in the FY, derived from the total number of specimens which are part of cataloged item records in databased accessions for the FY.</td>
										<td>The number of cataloged items databased in the FY. </td>
										<cfif annualReport EQ "yes">
											<td>The total number of cataloged items with NCBI numbers as of #encodeForHtml(endDate)#</td>
										</cfif>
										<td>The number of databased genetic samples added to the Cryo Collection in the FY as indicated by the number of parts in cryovats.</td>
										<td>The number of accessions received and databased in the FY.</td>
										<cfif annualReport EQ "yes">
											<td>The number of cataloged items received in the FY, but not databased, as reported by MCZ collections staff, and not derived from MCZbase data (may be estimate).</td>
										</cfif>
									</tr>
									<cfloop query="ACtotals">
										<tr>
											<td>#collection#</td>
											<td>
												<cfif #Received_Cat_Items# EQ ''>
													0
												<cfelse> 	
													#Received_Cat_Items# 
												</cfif>
											</td>
											<td>
												<cfif #Received_Specimens# EQ ''>
													0
												<cfelse>
													#Received_Specimens#
												</cfif>
											</td>
											<td>
												<cfif #Entered_Cat_Items# EQ ''>
													0
												<cfelse>
														#Entered_Cat_Items#
												</cfif>
											</td>
											<td>
												<cfif #NCBI_Cat_Items# EQ ''>
													N/A
												<cfelse>
													#NCBI_Cat_Items#
												</cfif>
											</td>
											<cfif annualReport EQ "yes">
												<td>
													<cfif #numAddedCryo# EQ ''>
														N/A
													<cfelse>
														#numAddedCryo#
													</cfif>
												</td>
											</cfif>
											<td>
												<cfif #Num_Accns# EQ '' and #Collection# EQ 'Cryogenic'>
													N/A
												<cfelseif #Num_Accns# EQ ''>
													0
												<cfelse>
													#Num_Accns#
												</cfif>
											</td>
											<cfif annualReport EQ "yes">
												<td>
													<cfif #numrecnotcat# EQ ''>
														N/A
													<cfelse>
														#numrecnotcat#
													</cfif>
												</td>
											</cfif>
										</tr>
									</cfloop>
								</tbody>
							</table>
						</div>
						<cfif annualReport EQ "yes">
							<p class="text-muted small">Reports are generated from the current MCZbase data and may not match numbers printed in previous annual reports.</p>
						<cfelse> 
							<p class="text-muted small">Reports are generated from the current MCZbase data for the given date range.</p>
						</cfif>
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
	<cfthread action="join" name="getAcquisitionsThread#tn#" />
	<cfreturn cfthread['getAcquisitionsThread#tn#'].output>
</cffunction>
					
<!--- getLoanNumbers report on loan activity 
@param beginDate starting date for range to report 
@param endDate end date for range to report
@param returnAs html or csv, if csv returns result as csv, otherwise as html table 
--->
<cffunction name="getLoanNumbers" access="remote" returntype="any" returnformat="json">
	<cfargument name="endDate" type="any" required="yes">
	<cfargument name="beginDate" type="any" required="yes">
	<cfargument name="annualReport" type="any" required="yes">
	<cfargument name="returnAs" type="string" required="no" default="html">
	
	<!--- make arguments available within thread --->
	<cfset variables.beginDate = arguments.beginDate>
	<cfset variables.endDate = arguments.endDate>
	<cfset variables.annualReport = arguments.annualReport>
	<cfset variables.returnAs = arguments.returnAs>
	<cfset tn = REReplace(CreateUUID(), "[-]", "", "all") >
	<cfthread name="getLoanNumbersThread#tn#">
		<cftry>
			<!--- annual report queries for loan activity --->
			<cfquery name="loans" datasource="uam_god" cachedwithin="#createtimespan(7,0,0,0)#">
				SELECT
					c.Collection, 
					nvl(ol.Num_Outgoing_Loans,0) Num_Outgoing_Loans,
					nvl(cl.Num_Closed_Loans,0) Num_Closed_Loans,
					nvl(fy.Num_5yr_Loans,0) Num_5yr_Loans,
					nvl(ty.Num_10yr_Loans,0) Num_10yr_Loans,
					nvl(b.Num_Borrows,0) Num_Borrows,
					nvl(opL.Num_Open_Loans,0) Num_Open_Loans,
					nvl(open5.Num_Open_OverDue_5yrs,0) Num_Open_OverDue_5yrs,
					nvl(open10.Num_Open_OverDue_10yrs,0) Num_Open_OverDue_10yrs,
					nvl(ol.Outgoing_CatItems, 0) Outgoing_CatItems,
					nvl(ol.Outgoing_Specimens, 0) Outgoing_Specimens
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
							<h2 class="h3 mt-0 px-0 float-left mb-1">
								<cfif annualReport eq "yes">Annual Report:</cfif> Loan Activity <span class="text-muted">(#encodeForHtml(beginDate)#/#encodeForHtml(endDate)#)</span>
							</h2>
							<div class="btn-toolbar my-1 mt-md-0 float-right">
								<div class="btn-group mr-2">
									<button onclick="toggleRow()" class="btn btn-xs btn-primary">Show/Hide Definitions</button> <a type="button" href="/metrics/Dashboard.cfm?action=dowloadLoanActivity&returnAs=csv&annualReport=#annualReport#&beginDate=#encodeForURL(beginDate)#&endDate=#encodeForUrl(endDate)#" class="btn btn-xs btn-outline-secondary text-decoration-none">Export Table</a>
								</div>
							</div>
						</div>
						<div class="table-responsive-lg">
							<table class="table table-striped border" id="t">
								<thead class="thead-light">
									<tr>
										<th>Collection</th>
										<th>Outgoing Loans</th>
										<th>Closed Loans</th>
										<th>Closed Overdue (>5 years) Loans</th>
										<th>Closed Overdue (>10 years) Loans</th>
										<th>Incoming loans (=Borrows)</th>
										<th>Number of Open Loans</th>
										<th>Number of Open Loans overdue > 5 years</th>
										<th>Number of Open Loans overdue > 10 year</th>
										<th>Outgoing Cataloged Items</th>
										<th>Outgoing Specimens</th>
									</tr>
								</thead>
								<tbody>
									<tr class="toggle1 hidden">
										<td class="barber_stripes">Column Data Definitions &rarr;</div>
										<td>Number of outgoing loans in the FY. </div>
										<td>Total number of open loans that were completely closed in the FY.</div>
										<td>Total number of open loans older than 5 years closed in the FY.</td>
										<td>Total number of open loans older than 10 years closed in the FY.</td>
										<td>Total number of borrows in the FY.</td>
										<td>Total number of open loans as of 2019-06-30.</td>
										<td>Total number of open loans that are past due for over 5 years as of 2019-06-30.</td>
										<td>Total number of open loans that are past due for over 10 years as of 2019-06-30.</td>
										<td>Cataloged Items in Loans in the FY.</td>
										<td>Specimens in Loans in the FY.</td>
									</tr>
									<cfloop query="loans">
										<cfif #Collection# EQ 'Herpetology Observations'>
											<tr>
												<td>#Collection#</td>
												<td>N/A</td>
												<td>N/A</td>
												<td>N/A</td>
												<td>N/A</td>
												<td>N/A</td>
												<td>N/A</td>
												<td>N/A</td>
												<td>N/A</td>
												<td>N/A</td>
												<td>N/A</td>
											</tr>
										<cfelse>
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
										</cfif>
									</cfloop>
								</tbody>
							</table>
						</div>
						<cfif annualReport EQ "yes">
							<p class="text-muted small">Reports are generated from the current MCZbase data and may not match numbers printed in previous annual reports.</p>
						<cfelse> 
							<p class="text-muted small">Reports are generated from the current MCZbase data for the given date range.</p>
						</cfif>
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
	<cfthread action="join" name="getLoanNumbersThread#tn#" />
	<cfreturn cfthread['getLoanNumbersThread#tn#'].output>
</cffunction>

<!--- getMediaNumbers report on media activity in a specified time period 
@param beginDate starting date for range to report 
@param endDate end date for range to report
@param returnAs html or csv, if csv returns result as csv, otherwise as html table 
--->
<cffunction name="getMediaNumbers" access="remote" returntype="any" returnformat="json">
	<cfargument name="endDate" type="any" required="no">
	<cfargument name="beginDate" type="any" required="no">
	<cfargument name="annualReport" type="any" required="yes">
	<cfargument name="returnAs" type="string" required="no" default="html">
	
	<!--- make arguments available within thread --->
	<cfset variables.beginDate = arguments.beginDate>
	<cfset variables.endDate = arguments.endDate>
	<cfset variables.annualReport = arguments.annualReport>
	<cfset variables.returnAs = arguments.returnAs>
	<cfset tn = REReplace(CreateUUID(), "[-]", "", "all") >
	<cfthread name="getMediaNumbersThread#tn#">
		<cftry>
			<cfif annualReport EQ 'yes'>
				<cfquery name="getendSchema" datasource="uam_god" cachedwithin="#createtimespan(7,0,0,0)#">
						select username from dba_users where username like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="ARCHIVE_#left(endDate,4)#07%">
				</cfquery>
				<cfset endschema = getendSchema.username>
				<cfquery name="getbeginSchema" datasource="uam_god" cachedwithin="#createtimespan(7,0,0,0)#">
						select username from dba_users where username like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="ARCHIVE_#left(beginDate,4)#07%">
				</cfquery>
				<cfset beginschema = getbeginSchema.username>
			<cfelse>
				<cfset beginSchema="MCZBASE">
				<cfset endSchema="MCZBASE">
			</cfif>

			<!--- annual report queries --->
			<cfquery name="media" datasource="uam_god" cachedwithin="#createtimespan(7,0,0,0)#">
				SELECT
					c.collection,
					i.Num_Images_Cat_Items,
					i.Num_Images,
					<cfif annualReport EQ "yes">
						i.Num_Images - prev.Num_Images NumImagesAdded,
						i.Num_Images_Cat_Items - prev.Num_Images_Cat_Items NumCatItemsImgAdded,
					</cfif>
					pt.Images_Primary_Cat_Items,
					pt.Images_Primary_Cat_Items/p.Primary_Cat_Items percentPrimaryImages,
					st.Images_Secondary_Cat_Items
				FROM
					(select * from collection where collection_cde <> 'MCZ') c
					left join (select f.collection_id, f.collection, count(distinct f.collection_object_id) Num_Images_Cat_Items, sum(total_parts) numImagesSpecimens, count(distinct m.media_id) Num_Images
					from #endschema#.media m, #endschema#.MEDIA_RELATIONS mr, #endschema#.flat f, #endSchema#.coll_object co 
					where m.media_id = mr.media_id
					and mr.MEDIA_RELATIONSHIP = 'shows cataloged_item'
					and mr.RELATED_PRIMARY_KEY = f.collection_object_id
					and f.collection_object_id = co.collection_object_id
					and co.COLL_OBJECT_ENTERED_DATE < to_date(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#endDate#">, 'YYYY-MM-DD')
					group by f.collection_id, f.collection) i on c.collection_id = i.collection_id
				LEFT JOIN 
					(select f.collection_id, f.collection, count(distinct f.collection_object_id) Images_Primary_Cat_Items, sum(decode(total_parts,null, 1,total_parts)) Images_Primary_Specimens
					from #endschema#.flat f, #endschema#.citation c, ctcitation_type_status ts
					where f.collection_object_id = c.collection_object_id
					and c.type_status = ts.type_status
					and ts.CATEGORY in ('Primary')
					and f.collection_object_id in
					(select related_primary_key from MEDIA_RELATIONS where media_relationship='shows cataloged_item')
					group by f.collection_id, f.collection) pt on c.collection_id = pt.collection_id
				LEFT JOIN
					(select f.collection_id, f.collection, count(distinct f.collection_object_id) Images_Secondary_Cat_Items, sum(decode(total_parts,null, 1,total_parts)) Images_Secondary_Specimens
					from #endschema#.flat f, #endschema#.citation c, ctcitation_type_status ts
					where f.collection_object_id = c.collection_object_id
					and c.type_status = ts.type_status
					and ts.CATEGORY in ('Secondary')
					and f.collection_object_id in
					(select related_primary_key from MEDIA_RELATIONS where media_relationship='shows cataloged_item')
					group by f.collection_id, f.collection) st on c.collection_id = st.collection_id
				LEFT JOIN
					(select f.collection_id, f.collection, ts.CATEGORY, count(distinct f.collection_object_id) Primary_Cat_Items from #endSchema#.coll_object co join #endSchema#.flat f on co.collection_object_id = f.collection_object_id join #endSchema#.citation c on f.collection_object_id = c.collection_object_id join ctcitation_type_status ts on c.type_status =  ts.type_status where ts.CATEGORY in ('Primary') and co.COLL_OBJECT_ENTERED_DATE <  to_date(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#endDate#">, 'YYYY-MM-DD') group by f.collection_id, f.collection, ts.CATEGORY) p on c.collection_id = p.collection_id
				<cfif annualReport EQ "yes">
				left join (select f.collection_id, f.collection, count(distinct f.collection_object_id) Num_Images_Cat_Items, sum(total_parts) numImagesSpecimens, count(distinct m.media_id) Num_Images
					from #beginschema#.media m, #beginschema#.MEDIA_RELATIONS mr, #beginschema#.flat f, #endSchema#.coll_object co
					where m.media_id = mr.media_id
					and mr.MEDIA_RELATIONSHIP = 'shows cataloged_item'
					and mr.RELATED_PRIMARY_KEY = f.collection_object_id
					and f.collection_object_id = co.collection_object_id
					group by f.collection_id, f.collection) prev on c.collection_id = prev.collection_id
				</cfif>
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
							<h2 class="h3 mt-0 px-0 float-left mb-1">
								<cfif annualReport eq "yes">Annual Report:</cfif> Media Activity <span class="text-muted">(as of #encodeForHtml(endDate)#)</span>
							</h2>
							<div class="btn-toolbar my-1 mt-md-0 float-right">
								<div class="btn-group mr-2">
									<button onclick="toggleRow()" class="btn btn-xs btn-primary">Show/Hide Definitions</button> <a type="button" href="/metrics/Dashboard.cfm?action=dowloadMediaActivity&returnAs=csv&annualReport=#annualReport#&beginDate=#encodeForURL(beginDate)#&endDate=#encodeForUrl(endDate)#" class="btn btn-xs btn-outline-secondary text-decoration-none">Export Table</a>
								</div>
							</div>
						</div>
						<div class="table-responsive-lg">
							<table class="table table-striped" id="t">
								<thead class="thead-light">
									<tr>
										<th>Collection</th>
										<th>Number of Cataloged Items with Media</th>
										<th>Number of Media Items</th>
										<cfif annualReport EQ "yes">
											<th>Number of Cataloged Items with Media added</th>
											<th>Number of Media Items added</th>
										</cfif>
										<th>Number of Primary Types with Images</th>
										<th>% of Primary Types Imaged</th>
										<th>Number of Secondary Types with Images</th>
									</tr>
								</thead>
								<tbody>
									<tr class="toggle1 hidden">
										<td class="barber_stripes">Column Data Definitions <b>&rarr;</b></td>
										<td>Total number of cataloged item records that have associated media.</td>
										<td>Total number of media items associated with cataloged item records.</td>
										<cfif annualReport EQ "yes">
											<td>Total number of cataloged item records that had media items added during the FY.</td>
											<td>Total number of media items associated with cataloged item records that were added during the FY.</td>
										</cfif>
										<td>Total number of primary type cataloged item records with citations that have associated images.</td>
										<td>The percentage of primary types with associated media as of #encodeForHtml(endDate)#</td>
										<td>Total number of secondary type cataloged item records with citations that have associated images.</td>
										
									</tr>
									<cfloop query="media">
										<tr>
											<td>#Collection#</td>
											<td>#Num_Images_Cat_Items#</td>
											<td>#Num_Images#</td>
											<cfif annualReport EQ "yes">
												<td>#NumCatItemsImgAdded#</td>
												<td>#NumImagesAdded#</td>
											</cfif>
											<td>
												<cfif #Images_Primary_Cat_Items# eq ''>
													N/A
												<cfelse>
													#Images_Primary_Cat_Items#
												</cfif>
											</td>
											<td>
												<cfif isNumeric(percentPrimaryImages)> 
													#NumberFormat((percentPrimaryImages)*100, '9.99')#%
												<cfelse>
													N/A
												</cfif>
											</td>
											<td>
												<cfif #Images_Secondary_Cat_Items# eq ''>
													N/A
												<cfelse>
													#Images_Secondary_Cat_Items#
												</cfif>
											</td>
										</tr>
									</cfloop>
								</tbody>
							</table>
						</div>
						<cfif annualReport EQ "yes">
							<p class="text-muted small">Reports are generated from the current MCZbase data and may not match numbers printed in previous annual reports.</p>
						<cfelse> 
							<p class="text-muted small">Reports are generated from the current MCZbase data for the given date range.</p>
						</cfif>
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
	<cfthread action="join" name="getMediaNumbersThread#tn#" />
	<cfreturn cfthread['getMediaNumbersThread#tn#'].output>
</cffunction>

<!--- getCitationNumbers obtain report on citations of specimens within a specified time period.				
@param beginDate starting date for range to report 
@param endDate end date for range to report
@param returnAs html or csv, if csv returns result as csv, otherwise as html table 
--->
<cffunction name="getCitationNumbers" access="remote" returntype="any" returnformat="json">
	<cfargument name="endDate" type="any" required="no">
	<cfargument name="beginDate" type="any" required="no">
	<cfargument name="annualReport" type="any" required="yes">
	<cfargument name="returnAs" type="string" required="no" default="html">
	
	<!--- make arguments available within thread --->
	<cfset variables.beginDate = arguments.beginDate>
	<cfset variables.endDate = arguments.endDate>
	<cfset variables.annualReport = arguments.annualReport>
	<cfset variables.returnAs = arguments.returnAs>
	<cfset tn = REReplace(CreateUUID(), "[-]", "", "all") >
	<cfthread name="getCitationNumbersThread#tn#">
		<cftry>
			 <cfif annualReport EQ 'yes'>
				<cfquery name="getendSchema" datasource="uam_god" cachedwithin="#createtimespan(7,0,0,0)#">
						select username from dba_users where username like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="ARCHIVE_#left(endDate,4)#07%">
				</cfquery>
				<cfset endschema = getendSchema.username>
				<cfquery name="getbeginSchema" datasource="uam_god" cachedwithin="#createtimespan(7,0,0,0)#">
						select username from dba_users where username like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="ARCHIVE_#left(beginDate,4)#07%">
				</cfquery>
				<cfset beginschema = getbeginSchema.username>
			<cfelse>
				<cfset beginSchema="MCZBASE">
				<cfset endSchema="MCZBASE">
			</cfif>

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
					from #endSchema#.coll_object co,  #endSchema#.flat f,  #endSchema#.citation c,  #endschema#.publication p, collection coll
					where f.collection_object_id = co.collection_object_id
					and f.collection_object_id = c.collection_object_id
					and c.publication_id = p.publication_id
					and f.collection_cde = coll.collection_cde
					and p.publication_title not like '%Placeholder%'
					and co.COLL_OBJECT_ENTERED_DATE <  to_date(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#endDate#">, 'YYYY-MM-DD')
					GROUP BY coll.collection_id, coll.collection) cit on c.collection_id = cit.collection_id
				ORDER BY COLLECTION
				</cfquery>
			<cfif variables.returnAs EQ "csv">
				<cfset csv = queryToCSV(citationNums)> 
				<cfoutput>#csv#</cfoutput>
			<cfelse>
				<cfoutput>
					<section class="col-12 mt-2 px-0">
						<div class="my-2 float-left w-100">
							<h2 class="h3 px-0 mt-0 float-left mb-1">
								<cfif annualReport eq "yes">Annual Report:</cfif> Citation Activity <span class="text-muted">(as of #encodeForHtml(endDate)#)</span>
							</h2>
							<div class="btn-toolbar my-1 mt-md-0 float-right">
								<div class="btn-group mr-2">
									<button onclick="toggleRow()" class="btn btn-xs btn-primary">Show/Hide Definitions</button> <a type="button" href="/metrics/Dashboard.cfm?action=dowloadCitationActivity&returnAs=csv&annualReport=#annualReport#&beginDate=#encodeForURL(beginDate)#&endDate=#encodeForUrl(endDate)#" class="btn btn-xs btn-outline-secondary text-decoration-none">Export Table</a>
								</div>
							</div>
						</div>
						<div class="table-responsive-lg">
							<table class="table table-striped" id="t">
								<thead class="thead-light">
									<tr>
										<th>Collection</th>
										<th>Total Citations</th>
										<th>Number of Cataloged Items with Citations</th>
										<th>Number of Genetic Voucher Citations</th>
									</tr>
								</thead>
								<tbody>
									<tr class="toggle1 hidden">
										<td class="barber_stripes">Column Data Definitions <b>&rarr;</b></td>
										<td>Total number of complete citations associated with cataloged items.</td>
										<td>Number of cataloged items with citations.</td>
										<td>Number of genetic voucher citations.</td>
									</tr>
									<cfloop query="citationNums">
										<tr>
											<td>#Collection#</td>
											<td>#Num_Citations#</td>
											<td>#Num_Citation_Cat_Items#</td>
											<td>#Num_Genetic_Citations#</td>
										</tr>
									</cfloop>
								</tbody>
							</table>
						</div>
						<cfif annualReport EQ "yes">
							<p class="text-muted small">Reports are generated from the current MCZbase data and may not match numbers printed in previous annual reports.</p>
						<cfelse> 
							<p class="text-muted small">Reports are generated from the current MCZbase data for the given date range.</p>
						</cfif>
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
	<cfthread action="join" name="getCitationNumbersThread#tn#" />
	<cfreturn cfthread['getCitationNumbersThread#tn#'].output>
</cffunction>

<!--- getGeorefNumbers report on georeferences and georeferencing activity within a specified time period 			
@param beginDate starting date for range to report 
@param endDate end date for range to report
@param returnAs html or csv, if csv returns result as csv, otherwise as html table 
--->
<cffunction name="getGeorefNumbers" access="remote" returntype="any" returnformat="json">
	<cfargument name="endDate" type="any" required="no">
	<cfargument name="beginDate" type="any" required="no">
	<cfargument name="annualReport" type="any" required="yes">
	<cfargument name="returnAs" type="string" required="no" default="html">
	
	<!--- make arguments available within thread --->
	<cfset variables.beginDate = arguments.beginDate>
	<cfset variables.endDate = arguments.endDate>
	<cfset variables.annualReport = arguments.annualReport>
	<cfset variables.returnAs = arguments.returnAs>
	<cfset tn = REReplace(CreateUUID(), "[-]", "", "all") >
	<cfthread name="getGeorefNumbersThread#tn#">
		<cftry>
			<cfif annualReport EQ 'yes'>
					<cfquery name="getendSchema" datasource="uam_god" cachedwithin="#createtimespan(7,0,0,0)#">
							select username from dba_users where username like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="ARCHIVE_#left(endDate,4)#07%">
					</cfquery>
					<cfset endschema = getendSchema.username>
					<cfquery name="getbeginSchema" datasource="uam_god" cachedwithin="#createtimespan(7,0,0,0)#">
							select username from dba_users where username like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="ARCHIVE_#left(beginDate,4)#07%">
					</cfquery>
					<cfset beginschema = getbeginSchema.username>
			<cfelse>
					<cfset beginSchema="MCZBASE">
					<cfset endSchema="MCZBASE">
			</cfif>
			<cfquery name="georef" datasource="uam_god" cachedwithin="#createtimespan(7,0,0,0)#">
				SELECT
					c.Collection,
					l.Num_Localities,
					l.Num_Cat_Items,
					gl.Num_GeoRef_Localities,
					vgl.Num_Verified_GeoRef_Localities,
					gl.Num_GeoRef_Cat_Items
					<cfif annualReport EQ "yes">
						,prevgl.Num_GeoRef_Localities prevGeorefLoc
						,prevgl.Num_GeoRef_Cat_Items prevGeorefCatItems
					</cfif>
				FROM
					(select * from collection where collection_cde<>'MCZ') c
					left join (select collection_id, collection, count(distinct locality_id) Num_Localities, count(distinct collection_object_id) Num_Cat_Items 
					from #endschema#.flat
					group by collection_id, collection) l on c.collection_id = l.collection_id
				LEFT JOIN
					(select f.collection_id, f.collection, count(distinct f.collection_object_id) Num_GeoRef_Cat_Items, sum(total_parts) Num_GeoRef_Specimens, count(distinct locality_id) Num_GeoRef_Localities
					from #endschema#.flat f, #endSchema#.coll_object co
					where dec_lat is not null and dec_long is not null
					and f.collection_object_id = co.collection_object_id
					group by f.collection_id, f.collection) gl on c.collection_id = gl.collection_id
				LEFT JOIN
					(select f.collection_id, f.collection, count(distinct f.collection_object_id) Num_GeoRef_Cat_Items, sum(total_parts) Num_Verified_GeoRef_Specimens, count(distinct locality_id) Num_Verified_GeoRef_Localities
					from #endschema#.flat f, #endSchema#.coll_object co
					where dec_lat is not null and dec_long is not null
					and f.collection_object_id = co.collection_object_id
					and f.VERIFICATIONSTATUS like 'verified%'
					group by f.collection_id, f.collection) vgl on c.collection_id = vgl.collection_id
				<cfif annualReport EQ "yes">
				LEFT JOIN
					(select f.collection_id, f.collection, count(distinct f.collection_object_id) Num_GeoRef_Cat_Items, sum(total_parts) Num_GeoRef_Specimens, count(distinct locality_id) Num_GeoRef_Localities
					from #beginschema#.flat f, #beginSchema#.coll_object co
					where dec_lat is not null and dec_long is not null
					and f.collection_object_id = co.collection_object_id
					group by f.collection_id, f.collection) prevgl on c.collection_id = prevgl.collection_id
				</cfif>
				ORDER BY COLLECTION
			</cfquery>
			<cfif variables.returnAs EQ "csv">
				<cfset csv = queryToCSV(georef)> 
				<cfoutput>#csv#</cfoutput>
			<cfelse>
				<cfoutput>
					<section class="col-12 mt-2 px-0">
						<div class="my-2 float-left w-100">
							<h2 class="h3 px-0 mt-0 float-left mb-1">
								<cfif annualReport eq "yes">Annual Report:</cfif> Georeferencing Activity <span class="text-muted">(as of #encodeForHtml(endDate)#)</span>
							</h2>
							
							<div class="btn-toolbar my-1 mt-lg-0 float-right">
								<div class="btn-group mr-2">
									<button onclick="toggleRow()" class="btn btn-xs btn-primary">Show/Hide Definitions</button> <a type="button" href="/metrics/Dashboard.cfm?action=dowloadGeoreferenceActivity&returnAs=csv&annualReport=#annualReport#&beginDate=#encodeForURL(beginDate)#&endDate=#encodeForUrl(endDate)#" class="btn btn-xs btn-outline-secondary text-decoration-none">Export Table</a>
								</div>
							</div>
						</div>
						<div class="table-responsive-lg">
							<table class="table table-striped" id="t">
								<thead class="thead-light">
									<tr>
										<th>Collection</th>
										<th>Total Number of Localities</th>
										<th>Records Georeferenced - Localities</th>
										<th>% of Localities Georeferenced</th>
										<th>Records Georeferenced and Verified - Localities</th>
										<th>Records Georeferenced Total - Cataloged Items</th>
										<th>% of Cataloged Items Georeferenced</th>
										<cfif annualReport EQ "yes">
											<th>Records Georeferenced in FY - Localities</th>
											<th>Records Georeferenced in FY - Cataloged Items</th>
										</cfif>
									</tr>
								</thead>
								<tbody>
									<tr class="toggle1 hidden">
										<td class="barber_stripes">Column Data Definitions &rarr;</td>
										<td>Total number of localities.</td>
										<td>Total number of georeferenced localities.</td>
										<td>Total number of georeferenced localities divided by the total number of localities as a percentage.</td>
										<td>Total number of georeferenced localities verified by the collection.</td>
										<td>Total number of cataloged item records georeferenced.</td>
										<td>Total number of cataloged item records that are georeferenced divided by total number of catalog item records, which may represent individual specimens or lots depending on the collection.</td>
										<cfif annualReport EQ "yes">
											<td>Total number of localities georeferenced during the FY. Can be a negative number if localities have been merged.</td>
											<td>Total number of cataloged item records georeferenced during the FY.</td>
										</cfif>
									</tr>
									<cfloop query="georef">
										<tr>
											<td>#Collection#</td>
											<td>#Num_Localities#</td>
											<td>#Num_GeoRef_Localities#</td>
											<td>#NumberFormat((Num_GeoRef_Localities/Num_Localities)*100, '9.99')#%</td>
											<td>#Num_Verified_GeoRef_Localities#</td>
											<td>#Num_GeoRef_Cat_Items#</td>
											<td>#NumberFormat((Num_GeoRef_Cat_Items/Num_Cat_Items)*100, '9.99')#%</td>
											<cfif annualReport EQ "yes">
												<td>#Num_GeoRef_Localities-prevGeorefLoc#</td>
												<td>#Num_GeoRef_Cat_Items-prevGeorefCatItems#</td>
											</cfif>
										</tr>
									</cfloop>
								</tbody>
							</table>
						</div>
						<cfif annualReport EQ "yes">
							<p class="text-muted small">Reports are generated from the current MCZbase data and may not match numbers printed in previous annual reports.</p>
						<cfelse> 
							<p class="text-muted small">Reports are generated from the current MCZbase data for the given date range.</p>
						</cfif>
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
	<cfthread action="join" name="getGeorefNumbersThread#tn#" />
	<cfreturn cfthread['getGeorefNumbersThread#tn#'].output>
</cffunction>

<!--- visitors and media requests for annual report
@param beginDate starting date for range to report
@param endDate end date for range to report
@param returnAs html or csv, if csv returns result as csv, otherwise as html table
--->
<cffunction name="getVisitorsMediaRequests" access="remote" returntype="any" returnformat="json">
	<cfargument name="endDate" type="any" required="no">
	<cfargument name="beginDate" type="any" required="no">
	<cfargument name="annualReport" type="any" required="yes">
	<cfargument name="returnAs" type="string" required="no" default="html">

	<!--- make arguments available within thread --->
	<cfset variables.beginDate = arguments.beginDate>
	<cfset variables.endDate = arguments.endDate>
	<cfset variables.annualReport = arguments.annualReport>
	<cfset variables.returnAs = arguments.returnAs>
	<cfset tn = REReplace(CreateUUID(), "[-]", "", "all") >
	<cfthread name="getVisitorsMediaRequestsThread#tn#">
		<cftry>
			<cfif annualReport EQ 'yes'>
				<cfquery name="getendSchema" datasource="uam_god" cachedwithin="#createtimespan(7,0,0,0)#">
					select username 
					from dba_users 
					where username like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="ARCHIVE_#left(endDate,4)#07%">
				</cfquery>
				<cfset endschema = getendSchema.username>
				<cfquery name="getbeginSchema" datasource="uam_god" cachedwithin="#createtimespan(7,0,0,0)#">
					select username 
					from dba_users 
					where username like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="ARCHIVE_#left(beginDate,4)#07%">
				</cfquery>
					<cfset beginschema = getbeginSchema.username>
			<cfelse>
					<cfset beginSchema="MCZBASE">
					<cfset endSchema="MCZBASE">
			</cfif>
			<cfquery name="visitorsmediareq" datasource="uam_god" cachedwithin="#createtimespan(7,0,0,0)#">
				SELECT
					c.collection,
					visitors.numvisitors,
					visitordays.numvisitordays,
					mediareqs.nummediareqs
				FROM
					(select collection_cde,institution_acronym,descr,collection,collection_id 
					from collection 
					where collection_cde <> 'MCZ') c				
				LEFT JOIN
					(select collection_id, value numvisitors 
					from collections_reported_metrics 
					where to_char(reported_date, 'yyyy')=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#left(endDate,4)#">
					and metric = 'NUMVISITORS') visitors on c.collection_id = visitors.collection_id
				LEFT JOIN
					(select collection_id, value numvisitordays
					from collections_reported_metrics
					where to_char(reported_date, 'yyyy')=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#left(endDate,4)#">
					and metric = 'NUMVISITORDAYS') visitordays on c.collection_id = visitordays.collection_id
				LEFT JOIN
					(select collection_id, value nummediareqs
					from collections_reported_metrics
					where to_char(reported_date, 'yyyy')=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#left(endDate,4)#">
					and metric = 'NUMMEDIAREQ') mediareqs on c.collection_id = mediareqs.collection_id
				ORDER BY COLLECTION
			</cfquery>

			<cfif variables.returnAs EQ "csv">
				<cfset csv = queryToCSV(visitorsmediareq)>
				<cfoutput>#csv#</cfoutput>
			<cfelse>
				<cfoutput>
					<section class="col-12 mt-2 px-0">
						<div class="my-2 float-left w-100">
							<h2 class="h3 mt-0 mb-1 px-0 float-left">
								<cfif annualReport eq "yes">Annual Report:</cfif> Visitors and Media Requests <span class="text-muted">(#encodeForHtml(beginDate)#/#encodeForHtml(endDate)#)</span>
							</h2>
							<div class="btn-toolbar my-1 mt-md-0 float-right">
								<div class="btn-group mr-2">
									<button onclick="toggleRow()" class="btn btn-xs btn-primary">Show/Hide Definitions</button> <a type="button" href="/metrics/Dashboard.cfm?action=downloadVisitorsMediareqs&returnAs=csv&annualReport=#annualReport#&beginDate=#encodeForURL(beginDate)#&endDate=#encodeForUrl(endDate)#" class="btn btn-xs btn-outline-secondary text-decoration-none">Export Table</a>
								</div>
							</div>
						</div>
						<div class="table-responsive-lg">
							<table class="table table-striped" id="t">
								<thead class="thead-light">
									<tr>
										<th>Collection</th>
										<th>Number of Scholarly Visitors</th>
										<th>Total Number of Days Scholarly Visitors used Collection</th>
										<th>Media Requests</th>
									</tr>
								</thead>
								<tbody>
									<tr class="toggle1 hidden">
										<td class="barber_stripes">Column Data Definitions &rarr; </td>
										<td>Number of scholarly visitors working in the collections during the FY as reported by MCZ Collections staff.</td>
										<td>Number of days that scholarly visitors were working in the collections during the FY as reported by MCZ Collections staff.</td>
										<td>Number of image/filming/media requests as indicated by the MCZ permissions requests during the FY as reported by MCZ Collections staff. </td>
									</tr>
									<cfloop query="visitorsmediareq">
										<tr>
											<td>#collection#</td>
											<td>
												<cfif #numvisitors# EQ ''>
													N/A
												<cfelse>
													#numvisitors#
												</cfif>
											</td>
											<td>
												<cfif #numvisitordays# EQ ''>
													N/A
												<cfelse>
													#numvisitordays#
												</cfif>
											</td>
											<td>
												<cfif #nummediareqs# EQ ''>
													N/A
												<cfelse>
													#nummediareqs#
												</cfif>
											</td>
										</tr>
									</cfloop>
								</tbody>
							</table>
						</div>
						<cfif annualReport EQ "yes">
							<p class="text-muted small">Reports are generated from the current MCZbase data and may not match numbers printed in previous annual reports.</p>
						<cfelse> 
							<p class="text-muted small">Reports are generated from the current MCZbase data for the given date range.</p>
						</cfif>
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
	<cfthread action="join" name="getVisitorsMediaRequestsThread#tn#" />
	<cfreturn cfthread['getVisitorsMediaRequestsThread#tn#'].output>
</cffunction>

</cfcomponent>	
