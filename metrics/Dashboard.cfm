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
	<cfcase value="dowloadAcquisitions">
		<!--- download accessions table as csv  --->
		<cfset csv = getAcquisitions(beginDate="#beginDate#",endDate="#endDate#",returnAs="csv")>
		<cfheader name="Content-Type" value="text/csv">
		<cfset beginDate = rereplace(beginDate,'[^0-9]','','all')>
		<cfset endDate = rereplace(endDate,'[^0-9]','','all')>
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
			});
		</script>
		<style>
			.collapsible-link {
				width: 100%;
				position: relative;
				text-align: left;
			}

			.collapsible-link::before {
				content: "\f107";
				position: absolute;
				top: 50%;
				right: 0.8rem;
				transform: translateY(-50%);
				display: block;
				font-family: "FontAwesome";
				font-size: 1.1rem;
			}

			.collapsible-link[aria-expanded="true"]::before {
				content: "\f106";
			}
		</style>
		<div class="container-fluid" id="content">
			<div class="row">
				<br clear="all">	
				<nav id="sidebarMenu" class="px-1 pt-2 col-md-3 col-lg-2 d-md-block sidebar" style="background-color: ##efeded;border: ##e3e3e3;">
					<div id="accordionExample" class="accordion shadow">
						<!-- Accordion item 1 -->
						<div class="card">
							<div id="headingOne" class="card-header bg-white shadow-sm border-0">
								<h2 class="mb-0">
									<button type="button" data-toggle="collapse" data-target="##collapseOne" aria-expanded="true"
									aria-controls="collapseOne"
									class="btn btn-link text-dark font-weight-bold text-uppercase collapsible-link">
										Annual Reports
									</button>
								</h2>
							</div>
							<div id="collapseOne" aria-labelledby="headingOne" data-parent="##accordionExample" class="collapse show">
								<div class="card-body p-1">
									<div class="sidebar-sticky py-2 mt-2 px-2 border rounded" id="annualReports" style="background-color: ##efeded;">
										<form id="loadReportForm">
											<h3 class="h4 text-muted">Annual Reports</h3>
											<input type="hidden" name="returnFormat" value="plain">
											<cfset currentDate = Year(Now())>
											<cfset beginYear = currentYear - 1> <!-- Adjust as needed to show past fiscal years -->
											<cfset endYear = currentDate + 1>	
											<label for="fiscalYear" class="data-entry-label mt-2">Select Fiscal Year:</label>
											<select name="method" id="method" class="mb-1 data-entry-input">	
												<cfloop from="#beginYear#" to="#endYear#" index="fiscalYear">
													<cfset fiscalYearStart = #fiscalYear# - 1>
													<option value="getLoanNumbers2" selected>Fiscal Year:  7/1/#fiscalYearStart#-6/30/#fiscalYear#</option>
												</cfloop>
											</select>
											<input type="submit" value="Show Annual Report" class="my-2 btn-xs btn btn-primary" aria-label="Show the selected report for the specified date range">
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
								</div>
							</div>
						</div>
						<!-- Accordion item 2 -->
						<div class="card">
							<div id="headingTwo" class="card-header bg-white shadow-sm border-0">
								<h2 class="mb-0">
									<button type="button" data-toggle="collapse" data-target="##collapseTwo" aria-expanded="false"
										aria-controls="collapseTwo"
										class="btn btn-link collapsed text-dark font-weight-bold text-uppercase collapsible-link">
									Selected Report
									</button>
								</h2>
							</div>
							<div id="collapseTwo" aria-labelledby="headingTwo" data-parent="##accordionExample" class="collapse">
								<div class="card-body p-1">
									<div class="sidebar-sticky py-2 mt-2 border rounded mb-3 px-2" id="selectedReports" style="background-color: ##efeded;">
										<form id="loadReportForm">
									<h3 class="h4 text-muted">Select a Report</h3>
									<input type="hidden" name="returnFormat" value="plain">
									<label for="beginDate" class="data-entry-label mt-2">Begin Date</label>
									<input name="beginDate" id="beginDate" type="text" class="mb-1 datetimeinput data-entry-input data-entry-input" placeholder="yyyy-mm-dd" value="#beginDate#" aria-label="start of range for dates to display metrics.">
									<label for="endDate" class="data-entry-label mt-2">End Date</label>
									<input name="endDate" id="endDate" type="text" class="mb-1 datetimeinput data-entry-input data-entry-input" placeholder="yyyy-mm-dd" value="#endDate#" aria-label="end of range for dates to display metrics.">
									<label for="method" class="data-entry-label mt-2">Report To Show</label>
									<select id="method" name="method" class="my-1 data-entry-input">
										<option value="getAnnualNumbers" selected="selected">Holdings</option>
										<option value="getAcquisitions">Acquisitions</option>
										<option value="getLoanNumbers">Loan Activity</option>
										<option value="getMediaNumbers">Media (current)</option>
										<option value="getCitationNumbers">Citations (current)</option>
										<option value="getGeorefNumbers">Georeferences (current)</option>
									</select>
									<input type="submit" value="Show Selected Report" class="mt-2 mb-2 btn-xs btn btn-primary" aria-label="Show the selected report for the specified date range">
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
								</div>
							</div>
						</div>
					</div>
				</nav>

				<main role="main" class="col-md-9 px-3 ml-sm-auto col-lg-10 mb-3">
					<div class="col-12 mt-4">
						<h1 class="h2 float-left mb-1 w-100">MCZbase Metrics 
						</h1>
						<p class="text-muted small">Reports are generated from the current MCZbase data and may not match numbers printed in previous annual reports.</p>
						<cfset summaryAnnualBlock=getAcquisitions(endDate="#endDate#",beginDate="#beginDate#")>
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