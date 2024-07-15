<!---

* /metrics/Dashbord.cfm

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

--->
<cf_rolecheck>

<cfinclude template="/metrics/component/functions.cfc">
<cfif NOT isDefined("action") OR len(action) EQ 0>
	<cfset action = "showMetrics">
</cfif>
<!--- obtain beginDate and endDate from either URL or Form scope --->
<cfif isDefined("url.beginDate")>
	<cfset variables.beginDate=url.beginDate>
<cfelseif isDefined("form.beginDate")>
	<cfset variables.beginDate=form.beginDate>
</cfif> 
<cfif isDefined("url.endDate")>
	<cfset variables.endDate=url.endDate>
<cfelseif isDefined("form.endDate")>
	<cfset variables.endDate=form.endDate>
</cfif> 

<!--- TODO: Set to most recent full year. Fix Begin date --->
<cfset currentYear = '#dateFormat(now(), "yyyy")#'>
<cfif NOT isDefined("endDate") OR len(endDate) EQ 0>
	<cfset endDate = '#dateFormat(now(), "yyyy-mm-dd")#'>
</cfif>
<cfif NOT isDefined("beginDate")>
	<cfset beginDate = '#DateFormat(DateAdd("yyyy", -1, endDate),"yyyy-mm-dd")#'>
</cfif>

<cfswitch expression="#action#">
	<cfcase value="dowloadHoldings">
		<!--- download holdings table as csv  --->
		<cfset csv = getAnnualNumbers(beginDate="#beginDate#",endDate="#endDate#",returnAs="csv")>
		<cfheader name="Content-Type" value="text/csv">
		<cfset beginDate = rereplace(beginDate,'[^0-9]','','all')>
		<cfset endDate = rereplace(endDate,'[^0-9]','','all')>
		<cfset targetFile = "Holdings_#beginDate#_to_#endDate#.csv">
		<cfheader name="Content-disposition" value="attachment;filename=#targetFile#">
		<cfoutput>#csv#</cfoutput>
		<cfabort>
	</cfcase>
	<cfcase value="showMetrics">
		<cfset pageTitle="Metrics Dashboard">
		<cfinclude template="/shared/_header.cfm">
		<script type="text/javascript" src="/metrics/js/metrics.js"></script> 
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
									<option value="getAnnualNumbers" selected="selected">Holdings</option>
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
						<div class="col-12 mt-4">
							<h1 class="h2 float-left mb-1 w-100">MCZbase Metrics</h1>
							<cfset summaryAnnualBlock=getAnnualNumbers(endDate="#endDate#",beginDate="#beginDate#")>
							<div id="annualNumbersDiv"> 
								#summaryAnnualBlock#
							</div>
						</div>
					</main>

				</div>
			</div>
		</cfoutput>
		<cfinclude template="/shared/_footer.cfm">
	</cfcase>
</cfswitch>
