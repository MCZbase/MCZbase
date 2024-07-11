<!--

* /metrics/testMetrics.cfm

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

* Dashboard for obtaining annual reporting and other collections metrics.

-->
<cfset pageTitle="Metrics Testing">
<cfinclude template="/shared/_header.cfm">
<!---<cfinclude template = "/shared/component/functions.cfc">--->

<cfset targetFile = "chart_data.csv">
<cfset filePath = "/metrics/datafiles/">
<cfinclude template="/metrics/component/functions.cfc">
<script type="text/javascript" src="/metrics/js/metrics.js"></script> 


	
<!--- TODO: Set to most recent full year. Fix Begin date --->
<!---<cfoutput><cfif NOT isDefined("endDate")><cfset endDate = '#dateFormat(now(), "yyyy-mm-dd")#'></cfif>
<cfif NOT isDefined("beginDate")><cfset beginDate = '#DateFormat(DateAdd("yyyy", -1, endDate),"yyyy-mm-dd")#'></cfif></cfoutput>--->
<cfset beginDate = ''>
<cfset endDate = ''>
<cfsetting RequestTimeout = "0">
<cfset start = GetTickCount()>
<meta name="theme-color" content="#563d7c">
<cfoutput>
<div class="container-fluid" id="content">
	<div class="row">
	<br clear="all">	
		<nav id="sidebarMenu" class="col-md-2 col-lg-2 d-md-block sidebar" style="background-color: ##efeded;border: ##e3e3e3;">
			<div class="sidebar-sticky pt-4 px-2" style="background-color: ##efeded;">
				<form id="loadReportForm">
					<h3 class="h4 text-muted">Report Date Range</h3>
					<input type="hidden" name="returnFormat" value="plain">
					<label for="beginDate" class="data-entry-label mt-2">Begin Date</label>
					<input name="beginDate" id="beginDate" type="text" class="mb-1 datetimeinput data-entry-input data-entry-input" placeholder="yyyy-mm-dd" value="#beginDate#" aria-label="start of range for dates to display metrics.">
					<label for="endDate" class="data-entry-label mt-2">End Date</label>
					<input name="endDate" id="endDate" type="text" class="mb-1 datetimeinput data-entry-input data-entry-input" placeholder="yyyy-mm-dd" value="#endDate#" aria-label="end of range for dates to display metrics.">
					<h3 class="h4 text-muted mt-3">Report to Show</h3>
					<label for="method" class="sr-only">Report To Show</label>
					<select id="method" name="method" class="my-1 data-entry-input">
						<option value="getAnnualChart" selected="selected">Current Fiscal Year Chart</option>
						<option value="getAcquisitions">Acquisitions</option>
						<option value="getLoanNumbers">Loan Activity</option>
						<option value="getMediaNumbers">Media Activity</option>
						<option value="getCitationNumbers">Citation Activity</option>
						<option value="getGeorefNumbers">Georeference Activity</option>
					</select>
					<input type="submit" value="submit" class="my-3 btn-xs btn btn-primary">
				</form>
				<script>
					$(document).ready(function() {
						$('##loadReportForm').on('submit',function(event){ event.preventDefault(); loadReport(); } );
					});
					function loadReport(){
						$('##annualNumbersDiv').html("Loading...");
						$.ajax(
							{
								url: '/metrics/component/functions.cfc',
								type: 'GET', 
								data: $('##loadReportForm').serialize()
							}
						).done(
							function(response) {
								console.log(response);
								$('##annualNumbersDiv').html(response);
							}
						).fail(function(jqXHR,textStatus,error){
							$('##annualNumbersDiv').html("Error Loading Metrics");
						handleFail(jqXHR,textStatus,error,"loading metrics for date range.");
						});
					}
				</script>
			</div>
		</nav>
	
		<main role="main" class="col-md-10 px-3 ml-sm-auto col-lg-10 px-md-5 mb-3">
			<cfoutput>
				<div class="col-12 mt-4">
					<h1 class="h2 float-left mb-1 w-100">MCZbase Metrics</h1>
					<cfset summaryAnnualBlock=getAnnualChart(endDate='#dateFormat(now(), "yyyy-mm-dd")#',beginDate='#DateFormat(sysdate - 365 * interval '365' day),"yyyy-mm-dd")#')>
					<div id="annualNumbersDiv"> 
						#summaryAnnualBlock#
					</div>
				</div>
			</cfoutput>
		</main>
	</div>
	
	<!---<p class="mt-2 smaller">Execution Time: <b>#int(getTickCount()-start)#</b> milliseconds</p>--->
</div>

</cfoutput>
<cfinclude template="/shared/_footer.cfm">


<!--

* /metrics/testMetrics.cfm

Copyright 2023 President and Fellows of Harvard College

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

* Demonstration of ajax patterns in MCZbase.

-->
<!---<cfset pageTitle="Metrics Testing">
<cfinclude template="/shared/_header.cfm">
<cfinclude template = "/shared/component/functions.cfc">

<cfset targetFile = "chart_data.csv">
<cfset filePath = "/metrics/datafiles/">--->
<!--temp commenting -->
<!---<cfquery name="getStats" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select 
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
	from 
		(select * from collection where collection_cde <> 'MCZ') c
	left join (select * from MCZBASE.collections_reported_metrics) rm on c.collection_id = rm.collection_id 
	left join (select f.collection_id, f.collection, count(distinct f.collection_object_id) catalogeditems, sum(decode(total_parts,null, 1,total_parts)) specimens
		from flat f
		join coll_object co on f.collection_object_id = co.collection_object_id
		where co.COLL_OBJECT_ENTERED_DATE < to_date('2023-06-30', 'YYYY-MM-DD')
		group by f.collection_id, f.collection) h on rm.collection_id = h.collection_id
	left join  ( select f.collection_id, f.collection, ts.CATEGORY, count(distinct f.collection_object_id) primaryCatItems, sum(decode(total_parts,null, 1,total_parts)) primarySpecimens
		from coll_object co
		join flat f on co.collection_object_id = f.collection_object_id
		join citation c on f.collection_object_id = c.collection_object_id
		join ctcitation_type_status ts on c.type_status =  ts.type_status
		where ts.CATEGORY in ('Primary')
		and co.COLL_OBJECT_ENTERED_DATE <  to_date('2023-06-30', 'YYYY-MM-DD')
		group by f.collection_id, f.collection, ts.CATEGORY) p on h.collection_id = p.collection_id
	left join (select f.collection_id, f.collection, ts.CATEGORY, count(distinct f.collection_object_id) secondaryCatItems, sum(decode(total_parts,null, 1,total_parts)) secondarySpecimens
		from coll_object co
		join flat f on co.collection_object_id = f.collection_object_id
		join citation c on f.collection_object_id = c.collection_object_id
		join ctcitation_type_status ts on c.type_status =  ts.type_status
		where ts.CATEGORY in ('Secondary')
		and co.COLL_OBJECT_ENTERED_DATE <  to_date('2023-06-30', 'YYYY-MM-DD')
		group by f.collection_id, f.collection, ts.CATEGORY) s on h.collection_id = s.collection_id
	left join (select f.collection_id, f.collection, count(distinct collection_object_id) receivedCatitems, sum(decode(total_parts,null, 1,total_parts)) receivedSpecimens
		from flat f
		join accn a on f.ACCN_ID = a.transaction_id
		join trans t on a.transaction_id = t.transaction_id
		where a.received_DATE between  to_date((EXTRACT (YEAR FROM ADD_MONTHS (sysdate, -1))||'-06-30'), 'YYYY-MM-DD') and  to_date('2023-06-30', 'YYYY-MM-DD')
		group by f.collection_id, f.collection) a 
		on h.collection_id = a.collection_id
	left join (select f.collection_id, f.collection, count(distinct f.collection_object_id) enteredCatItems, sum(decode(total_parts,null, 1,total_parts)) enteredSpecimens 
		from flat f
		join coll_object co on f.collection_object_id = co.collection_object_id
		where co.COLL_OBJECT_ENTERED_DATE between to_date((EXTRACT (YEAR FROM ADD_MONTHS (sysdate, -1))||'-06-30'), 'YYYY-MM-DD') and  to_date('2023-06-30', 'YYYY-MM-DD')
		group by f.collection_id, f.collection) e 
		on e.collection_id = h.collection_id
	left join (select f.collection_id, f.collection, count(distinct f.collection_object_id) ncbiCatItems, sum(total_parts) ncbiSpecimens 
		from COLL_OBJ_OTHER_ID_NUM oid, flat f, COLL_OBJECT CO 
		where OTHER_ID_TYPE like '%NCBI%'
		AND F.COLLECTION_OBJECT_ID = CO.COLLECTIOn_OBJECT_ID
		and co.COLL_OBJECT_ENTERED_DATE < to_date('2023-06-30', 'YYYY-MM-DD')
		and oid.collection_object_id = f.collection_object_id
		group by f.collection_id, f.collection) ncbi on h.collection_id = ncbi.collection_id
	left join (select c.collection_id, c.collection, count(distinct t.transaction_id) numAccns
		from accn a, trans t, collection c
		where a.transaction_id = t.transaction_id
		and t.collection_id = c.collection_id
		and a.received_date between to_date('2022-07-01', 'YYYY-MM-DD') and  to_date('2023-06-30', 'YYYY-MM-DD')
		group by c.collection_id, c.collection) accn on h.collection_id = accn.collection_id
</cfquery>
<cfoutput>
	<cfset csv = queryToCSV(getStats)> 
	<cffile action="write" file="#application.webDirectory##filePath##targetFile#" output = "#csv#" addnewline="No">
</cfoutput>--->
<!---<cftry>
	<cfexecute name = "/usr/bin/Rscript" 
		arguments = "#application.webDirectory#/metrics/R/simple_chart.R" 
		variable = "chartOutput"
		timeout = "10000"
		errorVariable = "chartError"> 
	</cfexecute>
<cfcatch>
	<h3>Error loading chart</h3>
	<cfdump var="#cfcatch#">
	<cfset chartOutput = "">
	<cfset errorVariable="">
</cfcatch>
</cftry>
<cftry>
	<cfoutput>
		<div class="container">
			<div class="row">
				<h1 class="h3 mt-3">Metrics</h1>
				<div class="col-12">
					<h3 class="h4 mt-1">Data Visualization Testing</h3>
					<p>Data that is imported into the R script is /metrics/datafiles/chart_data.csv and available here: <a href="#filePath##targetFile#">download table</a>.</p> This data comes from a temporary table in the database generated by a procedure and scheduled job which is then queried by CF to create the csv.
				</div>
			</div>
			<div class="row">
				<div class="col-12">
					Script output: [#chartOutput#]
				</div>
				<div class="col-12">
					Script errors: [#chartError#]
				</div>
				<div class="col-12">
					<p> Chart1 should appear.</p>
				</div>
				<div class="col-12">
					<!--- chart created by R script --->
					<img src="/metrics/R/graphs/chart1.png"/>
				</div>
			</div>
		</div>
	</cfoutput>
	<cfcatch>
		<cfset error_message = cfcatchToErrorMessage(cfcatch)>
		<cfset function_called = "#GetFunctionCalledName()#">
		<h2 class="h3">Error in #function_called#:</h2>
		<div>#error_message#</div>
	</cfcatch>
</cftry>
<cfinclude template="/shared/_footer.cfm">--->
