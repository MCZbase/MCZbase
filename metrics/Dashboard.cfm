<!--

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
	
<!---<cfif NOT isDefined("annualReport")>
	<cfset annualReport = "no">
</cfif>--->

<!--- If not provided, Set to most recent full fiscal year  --->
<cfset currentYear = DateFormat(now(), "yyyy")>
<cfset previousYear = DateFormat(DateAdd("yyyy", -1, now()),"yyyy")>
<cfif NOT isDefined("endDate") OR len(endDate) EQ 0>
	<cfif DateCompare(now(),createDate(currentYear,7,1)) LT 0> 
		<!--- before the end of the fiscal year, go to end of previous full fiscal year--->
		<cfset endDate = "#previousYear#-06-30">
	<cfelse>
		<cfset endDate = "#currentYear#-06-30">
	</cfif>
</cfif>
<cfif NOT isDefined("beginDate")>
	<cfset beginDate = '#DateFormat(DateAdd("d",1,DateAdd("yyyy", -1, endDate)),"yyyy-mm-dd")#'>
</cfif>
<cfset annualReport = 'no'>
<cfswitch expression="#action#">
	<cfcase value="dowloadHoldings">
		<!--- download holdings table as csv  --->
		<cfset csv = getNumbers(beginDate="#beginDate#",endDate="#endDate#",returnAs="csv")>
		<cfheader name="Content-Type" value="text/csv">
		<cfset beginDate = rereplace(beginDate,'[^0-9]','','all')>
		<cfset endDate = rereplace(endDate,'[^0-9]','','all')>
		<cfset annualReport = "no">
		<cfset targetFile = "Holdings_#beginDate#_to_#endDate#.csv">
		<cfheader name="Content-disposition" value="attachment;filename=#targetFile#">
		<cfoutput>#csv#</cfoutput>
		<cfabort>
	</cfcase>
	<cfcase value="dowloadAcquisitions">
		<!--- download accessions table as csv  --->
		<cfset csv = getAcquisitions(beginDate="#beginDate#",endDate="#endDate#",returnAs="csv",annualReport="no")>
		<cfheader name="Content-Type" value="text/csv">
		<cfset beginDate = rereplace(beginDate,'[^0-9]','','all')>
		<cfset endDate = rereplace(endDate,'[^0-9]','','all')>
		<cfset annualReport = "no">
		<cfset targetFile = "Acquisitions_#beginDate#_to_#endDate#.csv">
		<cfheader name="Content-disposition" value="attachment;filename=#targetFile#">
		<cfoutput>#csv#</cfoutput>
		<cfabort>
	</cfcase>
	<cfcase value="dowloadLoanActivity">
		<!--- download loan table as csv  --->
		<cfset csv = getLoanNumbers(beginDate="#beginDate#",endDate="#endDate#",returnAs="csv")>
		<cfheader name="Content-Type" value="text/csv">
		<cfset beginDate = rereplace(beginDate,'[^0-9]','','all')>
		<cfset endDate = rereplace(endDate,'[^0-9]','','all')>
		<cfset targetFile = "Loan_Activity_#beginDate#_to_#endDate#.csv">
		<cfheader name="Content-disposition" value="attachment;filename=#targetFile#">
		<cfoutput>#csv#</cfoutput>
		<cfabort>
	</cfcase>
	<cfcase value="dowloadMediaActivity">
		<!--- download media table as csv  --->
		<cfset csv = getMediaNumbers(beginDate="#beginDate#",endDate="#endDate#",returnAs="csv")>
		<cfheader name="Content-Type" value="text/csv">
		<cfset beginDate = rereplace(beginDate,'[^0-9]','','all')>
		<cfset endDate = rereplace(endDate,'[^0-9]','','all')>
		<cfset annualReport = "no">
		<cfset targetFile = "Media_Activity_#beginDate#_to_#endDate#.csv">
		<cfheader name="Content-disposition" value="attachment;filename=#targetFile#">
		<cfoutput>#csv#</cfoutput>
		<cfabort>
	</cfcase>
	<cfcase value="dowloadCitationActivity">
		<!--- download citation table as csv  --->
		<cfset csv = getCitationNumbers(beginDate="#beginDate#",endDate="#endDate#",returnAs="csv")>
		<cfheader name="Content-Type" value="text/csv">
		<cfset beginDate = rereplace(beginDate,'[^0-9]','','all')>
		<cfset endDate = rereplace(endDate,'[^0-9]','','all')>
		<cfset annualReport = "no">
		<cfset targetFile = "Media_Activity_#beginDate#_to_#endDate#.csv">
		<cfheader name="Content-disposition" value="attachment;filename=#targetFile#">
		<cfoutput>#csv#</cfoutput>
		<cfabort>
	</cfcase>
	<cfcase value="dowloadGeoreferenceActivity">
		<!--- download georeference activity table as csv  --->
		<cfset csv = getGeorefNumbers(beginDate="#beginDate#",endDate="#endDate#",returnAs="csv")>
		<cfheader name="Content-Type" value="text/csv">
		<cfset beginDate = rereplace(beginDate,'[^0-9]','','all')>
		<cfset endDate = rereplace(endDate,'[^0-9]','','all')>
		<cfset annualReport = "no">
		<cfset targetFile = "Media_Activity_#beginDate#_to_#endDate#.csv">
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
			<script>
				$(document).ready(function() {
					$("##beginDate").datepicker({ dateFormat: 'yy-mm-dd'});
					$("##endDate").datepicker({ dateFormat: 'yy-mm-dd'});
					$("##fiscalYear").datepicker({ dateFormat: 'yyyy'});
				});
			</script>
			<div class="container-fluid" id="content">
				<div class="row">
				<br clear="all">	
					<script>
						function addOneYear(date) {
							let newDate = new Date(date);
							newDate.setFullYear(newDate.getFullYear() + 1);
							return newDate.toISOString().substring(0,10); 
						}

						function subtractOneYear(date) {
							let newDate = new Date(date);
							newDate.setFullYear(newDate.getFullYear() - 1);
							return newDate.toISOString().substring(0,10); 
						}

						document.addEventListener('DOMContentLoaded', (event) => {
							const beginDateInput = document.getElementById('beginDate');
							const endDateInput = document.getElementById('endDate');

							beginDateInput.addEventListener('change', () => {
								const beginDate = beginDateInput.value;
								if (beginDate) {
									endDateInput.value = addOneYear(beginDate);
								}
							});

							endDateInput.addEventListener('change', () => {
								const endDate = endDateInput.value;
								if (endDate) {
									beginDateInput.value = subtractOneYear(endDate);
								}
							});
						});
					</script>
					<nav id="sidebarMenu" class="col-md-3 col-lg-2 d-md-block sidebar" style="background-color: ##efeded;border: ##e3e3e3;">
						<div class="sidebar-sticky pt-4 px-2" style="background-color: ##efeded;">
							<div class="accordion" id="accordionExample">
								<div class="card">
									<div class="card-header" id="headingOne">
										<h2 class="mb-0">
										<button class="btn btn-link" type="button" data-toggle="collapse" data-target="#collapseOne" aria-expanded="true" aria-controls="collapseOne">
											Accordion Item ##1
										</button>
										</h2>
									</div>
								</div>
								<div class="card">
									<div class="card-header" id="headingTwo">
										<h2 class="mb-0">
										<button class="btn btn-link collapsed" type="button" data-toggle="collapse" data-target="#collapseTwo" aria-expanded="false" aria-controls="collapseTwo">
											Accordion Item ##2
										</button>
										</h2>
									</div>
								</div>
							</div>
								<cfif annualReport eq 'no'>
								<form id="loadReportForm">
									<h3>Reports (Any Date Range)</h3>
									<h3 class="h4 text-muted mt-4 mb-0">Select Report Date Range</h3>
									<input type="hidden" name="returnFormat" value="plain">
									<input type="hidden" name="annualReport" value="no">
									<div class="row mx-0">
										<div class="col-12 px-0">
											<div class="col-12 col-md-6 px-1 float-left">
												<label for="beginDate" class="data-entry-label mt-2">Begin Date</label>
												<input name="beginDate" id="beginDate" type="text" class="mb-1 datetimeinput data-entry-input data-entry-input" placeholder="yyyy-mm-dd" value="#beginDate#" aria-label="start of range for dates to display metrics.">
											</div>
											<div class="col-12 col-md-6 px-1 float-left">
												<label for="endDate" class="data-entry-label mt-2">End Date</label>
												<input name="endDate" id="endDate" type="text" class="mb-1 datetimeinput data-entry-input data-entry-input" placeholder="yyyy-mm-dd" value="#endDate#" aria-label="end of range for dates to display metrics.">
											</div>
										</div>
									</div>
									<h3 class="h4 text-muted mt-3">Report to Show</h3>
									<label for="method" class="sr-only">Report To Show</label>
									<select id="method" name="method" class="my-1 data-entry-input">
										<option value="getAcquisitions" selected="selected">Acquisitions</option>
										<option value="getNumbers">Holdings</option>
										<option value="getLoanNumbers">Loan Activity</option>
										<option value="getMediaNumbers">Media (current)</option>
										<option value="getCitationNumbers">Citations (current)</option>
										<option value="getGeorefNumbers">Georeferences (current)</option>
									</select>
									<input type="submit" name="submit" value="Show Report" class="my-3 btn-xs btn btn-primary" aria-label="Show the selected report for the specified date range">
								</form>
							<cfelseif annualReport eq 'yes'>
								<form id="loadReportForm">
									<h3>Annual Reports</h3>
									<h3 class="h4 text-muted mt-3 mb-2">Select Fiscal Year</h3>
									<input type="hidden" name="returnFormat" value="plain">
									<input type="hidden" name="annualReport" value="no">
									<div class="row mx-0">
										<div class="col-12 px-0">
											<div class="col-12 col-md-6 px-1 float-left">
												<label for="beginDate" class="data-entry-label mt-2">Begin Date</label>
												<input name="beginDate" id="beginDate" type="text" class="mb-1 datetimeinput data-entry-input data-entry-input" placeholder="yyyy-mm-dd" value="#beginDate#" aria-label="start of range for dates to display metrics.">
											</div>
											<div class="col-12 col-md-6 px-1 float-left">
												<label for="endDate" class="data-entry-label mt-2">End Date</label>
												<input name="endDate" id="endDate" type="text" class="mb-1 datetimeinput data-entry-input data-entry-input" placeholder="yyyy-mm-dd" value="#endDate#" aria-label="end of range for dates to display metrics.">
											</div>
										</div>
									</div>
									<h3 class="h4 text-muted mt-3">Report to Show</h3>
									<label for="method" class="sr-only">Report To Show</label>
									<select id="method" name="method" class="my-1 data-entry-input">
										<option value="getAcquisitions" selected="selected">Annual Report (Acquisitions)</option>
										<option value="getNumbers">Annual Report (Holdings)</option>
										<option value="getLoanNumbers">Annual Report (Loan Activity)</option>
										<option value="getMediaNumbers">Annual Report (Media (current))</option>
										<option value="getCitationNumbers">Annual Report (Citations (current))</option>
										<option value="getGeorefNumbers">Annual Report (Georeferences (current))</option>
									</select>
									<input type="submit" name="submit" value="Show Annual Report" class="my-3 btn-xs btn btn-primary" aria-label="Show the selected report for the specified date range">
								</form>
							</cfif>
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
											$('##annualNumbersDiv').show();
										}
									).fail(function(jqXHR,textStatus,error){
										$('##annualNumbersDiv').html("Error Loading Metrics");
									handleFail(jqXHR,textStatus,error,"loading metrics for date range.");
									});
								}
							</script>
							</cfif>
						</div>
					</nav>
					<main role="main" class="col-md-9 px-3 ml-sm-auto col-lg-10 mb-3">
						<div id="accordionContent">
							<div id="collapseOne" class="collapse" aria-labelledby="headingOne" data-parent="##accordionExample">
								<div class="card-body">
									Content for Accordion Item #1
								</div>
							</div>
							<div id="collapseTwo" class="collapse" aria-labelledby="headingTwo" data-parent="##accordionExample">
								<div class="card-body">
									Content for Accordion Item #2
								</div>
							</div>
						</div>
						<div class="col-12 mt-4">
							<h1 class="h2 float-left mb-1 w-100">MCZbase Metrics </h1>
							<p class="text-muted small">Reports are generated from the current MCZbase data and may not match numbers printed in previous annual reports.</p>
							<cfset summaryAnnualBlock=getAcquisitions(endDate="#endDate#",beginDate="#beginDate#",annualReport="#annualReport#")>
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
	<cfdefaultcase>
		<cfoutput>
			Error: Unknown action
		</cfoutput>
	</cfdefaultcase>
</cfswitch>