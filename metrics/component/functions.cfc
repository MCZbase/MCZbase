<cffunction name="getAnnualNumbers" returntype="string" access="remote">
	<cfargument name="endDate" type="date" required="no" default="2024-07-01">
	<cfargument name="beginDate" type="date" required="no" default="2023-07-01">
	<cfthread name="getAnnualNumbersThread">
		<cfoutput>
			<cftry>
		<!---		<cfquery name="check" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					Is a check of some sort needed here?
				</cfquery>--->
				<cfif endDate is null AND beginDate is null>
					<CFSET endDate = #DateFormat (Now(), "yyyy-mm-dd")#>
					<CFSET beginDate = #DateFormat(DateAdd( 'm', -12, now() ),"yyyy-mm-dd")#>
				</cfif>
				<!-- annual report queries -->
				<cfsetting RequestTimeout = "0">
				<cfset start = GetTickCount()>
				<cfquery name="totals" datasource="uam_god">
					SELECT 
						rm.holdings,
						h.collection, 
						h.catalogeditems, 
						h.specimens, 
						p.primaryCatItems, 
						p.primaryspecimens, 
						s.secondaryCatItems, 
						s.secondarySpecimens, 
						a.receivedCatItems,
						a.receivedSpecimens,
						e.enteredCatItems,
						e.enteredSpecimens,
						ncbi.ncbiCatItems,
						accn.numAccns
					FROM 
						(select collection_id from collection where collection_cde <> 'MCZ') c
					LEFT JOIN (select collection_id,holdings from collections_reported_metrics) rm on c.collection_id = rm.collection_id 
					LEFT JOIN 
						(select f.collection_id, f.collection, count(distinct f.collection_object_id) catalogeditems, sum(decode(total_parts,null, 1,total_parts)) specimens from flat f join coll_object co on f.collection_object_id = co.collection_object_id where co.COLL_OBJECT_ENTERED_DATE < to_date('#endDate#', 'YYYY-MM-DD') group by f.collection_id, f.collection) h on rm.collection_id = h.collection_id
					LEFT JOIN 
						(select f.collection_id, f.collection, ts.CATEGORY, count(distinct f.collection_object_id) primaryCatItems, sum(decode(total_parts,null, 1,total_parts)) primarySpecimens from coll_object co join flat f on co.collection_object_id = f.collection_object_id join citation c on f.collection_object_id = c.collection_object_id join ctcitation_type_status ts on c.type_status =  ts.type_status where ts.CATEGORY in ('Primary') and co.COLL_OBJECT_ENTERED_DATE <  to_date('#endDate#', 'YYYY-MM-DD') group by f.collection_id, f.collection, ts.CATEGORY) p on h.collection_id = p.collection_id
					LEFT JOIN 
						(select f.collection_id, f.collection, ts.CATEGORY, count(distinct f.collection_object_id) secondaryCatItems, sum(decode(total_parts,null, 1,total_parts)) secondarySpecimens from coll_object co join flat f on co.collection_object_id = f.collection_object_id join citation c on f.collection_object_id = c.collection_object_id join ctcitation_type_status ts on c.type_status =  ts.type_status where ts.CATEGORY in ('Secondary') and co.COLL_OBJECT_ENTERED_DATE <  to_date('#endDate#', 'YYYY-MM-DD') group by f.collection_id, f.collection, ts.CATEGORY) s on h.collection_id = s.collection_id
					LEFT JOIN 
						(select f.collection_id, f.collection, count(distinct collection_object_id) receivedCatitems, sum(decode(total_parts,null, 1,total_parts)) receivedSpecimens from flat f join accn a on f.ACCN_ID = a.transaction_id join trans t on a.transaction_id = t.transaction_id where a.received_DATE between  to_date('#beginDate#', 'YYYY-MM-DD') and  to_date('#endDate#', 'YYYY-MM-DD') group by f.collection_id, f.collection) a on h.collection_id = a.collection_id
					LEFT JOIN 
						(select f.collection_id, f.collection, count(distinct f.collection_object_id) enteredCatItems, sum(decode(total_parts,null, 1,total_parts)) enteredSpecimens from flat f join coll_object co on f.collection_object_id = co.collection_object_id where co.COLL_OBJECT_ENTERED_DATE between to_date('#beginDate#', 'YYYY-MM-DD') and  to_date('#endDate#', 'YYYY-MM-DD') group by f.collection_id, f.collection) e on e.collection_id = h.collection_id
					LEFT JOIN 
						(select f.collection_id, f.collection, count(distinct f.collection_object_id) ncbiCatItems, sum(total_parts) ncbiSpecimens from COLL_OBJ_OTHER_ID_NUM oid, flat f, COLL_OBJECT CO where OTHER_ID_TYPE like '%NCBI%' 	AND F.COLLECTION_OBJECT_ID = CO.COLLECTION_OBJECT_ID and co.COLL_OBJECT_ENTERED_DATE < to_date('#endDate#', 'YYYY-MM-DD') and oid.collection_object_id = f.collection_object_id group by f.collection_id, f.collection) ncbi on h.collection_id = ncbi.collection_id
					LEFT JOIN 
						(select c.collection_id, c.collection, count(distinct t.transaction_id) numAccns from accn a, trans t, collection c where a.transaction_id = t.transaction_id and t.collection_id = c.collection_id and a.received_date between to_date('#beginDate#', 'YYYY-MM-DD') and  to_date('#endDate#', 'YYYY-MM-DD') group by c.collection_id, c.collection) accn on h.collection_id = accn.collection_id
				</cfquery>
				<main class="container-lg mx-auto my-3" id="content">
					<section class="row" >
						<div class="col-12 mt-3">
							<h1 class="h2 px-2">Basic Collections Metrics</h1>
							<table class="table table-responsive table-striped d-lg-table" id="t">
								<thead>
									<tr>
										<th><strong>Collection</strong></th>
										<th><strong>Total Holdings</strong></th>
										<th><strong>% of Holdings in MCZbase</strong></th>
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
											<td>#collection#</td>
											<td>#holdings#</td>
											<td>#NumberFormat((catalogeditems/holdings)*100, '9.99')#%</td>
											<td>#catalogeditems#</td>
											<td>#specimens#</td>
											<td>#primaryCatItems#</td>
											<td>#primarySpecimens#</td>
											<td>#secondaryCatItems#</td>
											<td>#secondarySpecimens#</td>
										</tr>
									</cfloop>
								</tbody>
							</table>
						</div>
					</section>
					<section class="col-12 mt-3">
						<h1 class="h2 px-2">Basic Collections Metrics (cont.)</h1>
						<table class="table table-responsive table-striped d-lg-table" id="t">
							<thead>
								<tr>
									<th><strong>Collection</strong></th>
									<th><strong>Acquired Cataloged Items</strong></th>
									<th><strong>Acquired Specimens</strong></th>
									<th><strong>New Records Entered in MCZbase - Cataloged Items</strong></th>
									<th><strong>Number of Genetic Samples added To Cryo</strong></th>
									<th><strong>Number of Cataloged Items with NCBI numbers</strong></th>
									<th><strong>Number of NCBI numbers added</strong></th>
									<th><strong>Number of Accessions</strong></th>
									<th><strong>Items received but not Cataloged at and of Year</strong></th>
								</tr>
							</thead>
							<tbody>
								<cfloop query="totals">
									<tr>
										<td>#collection#</td>
										<td>#receivedCatItems#</td>
										<td>#receivedSpecimens#</td>
										<td>#enteredCatItems#</td>
										<td>&nbsp;</td>
										<td>#ncbiCatItems#</td>
										<td>&nbsp;</td>
										<td>#numAccns#</td>
										<td>&nbsp;</td>
									</tr>
								</cfloop>
							</tbody>
						</table>
					</section>
				</main>
			<cfcatch>
				<!---<cfset error_message = cfcatchToErrorMessage(cfcatch)>
				<cfset function_called = "#GetFunctionCalledName()#">--->
				<h2 class='h3'>Error in function?</h2>
				<div>Error message TBD</div>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="getAnnualNumbersThread" />
	<cfreturn getAnnualNumbersThread.output>
</cffunction>