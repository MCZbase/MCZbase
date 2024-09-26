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
<!--- store most recent full fiscal year in variables available as defaults for form --->
<cfif DateCompare(now(),createDate(currentYear,7,1)) LT 0> 
	<!--- before the end of the fiscal year, go to end of previous full fiscal year--->
	<cfset endDateFiscal = "#previousYear#-06-30">
<cfelse>
	<cfset endDateFiscal = "#currentYear#-06-30">
</cfif>
<cfset beginDateFiscal = '#DateFormat(DateAdd("d",1,DateAdd("yyyy", -1, endDateFiscal)),"yyyy-mm-dd")#'>

<cfswitch expression="#action#">
	<cfcase value="dowloadHoldings">
		<!--- download holdings table as csv  --->
		<cfset csv = getNumbers(beginDate="#beginDate#",endDate="#endDate#",returnAs="csv",annualReport="#annualReport#")>
		<cfheader name="Content-Type" value="text/csv">
		<cfset beginDate = rereplace(beginDate,'[^0-9]','','all')>
		<cfset endDate = rereplace(endDate,'[^0-9]','','all')>
		<cfset targetFile = "Holdings_#beginDate#_to_#endDate#.csv">
		<cfheader name="Content-disposition" value="attachment;filename=#targetFile#">
		<cfoutput>#csv# #annualReport#</cfoutput>
		<cfabort>
	</cfcase>
	<cfcase value="dowloadAcquisitions">
		<!--- download accessions table as csv  --->
		<cfset csv = getAcquisitions(beginDate="#beginDate#",endDate="#endDate#",returnAs="csv",annualReport="#annualReport#")>
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
		<cfset csv = getLoanNumbers(beginDate="#beginDate#",endDate="#endDate#",returnAs="csv",annualReport="#annualReport#")>
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
		<cfset csv = getMediaNumbers(beginDate="#beginDate#",endDate="#endDate#",returnAs="csv",annualReport="#annualReport#")>
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
		<cfset csv = getCitationNumbers(beginDate="#beginDate#",endDate="#endDate#",returnAs="csv",annualReport="#annualReport#")>
		<cfheader name="Content-Type" value="text/csv">
		<cfset beginDate = rereplace(beginDate,'[^0-9]','','all')>
		<cfset endDate = rereplace(endDate,'[^0-9]','','all')>
		<cfset targetFile = "Citation_Activity_#beginDate#_to_#endDate#.csv">
		<cfheader name="Content-disposition" value="attachment;filename=#targetFile#">
		<cfoutput>#csv#</cfoutput>
		<cfabort>
	</cfcase>
	<cfcase value="dowloadGeoreferenceActivity">
		<!--- download georeference activity table as csv  --->
		<cfset csv = getGeorefNumbers(beginDate="#beginDate#",endDate="#endDate#",returnAs="csv",annualReport="#annualReport#")>
		<cfheader name="Content-Type" value="text/csv">
		<cfset beginDate = rereplace(beginDate,'[^0-9]','','all')>
		<cfset endDate = rereplace(endDate,'[^0-9]','','all')>
		<cfset targetFile = "Georef_Activity_#beginDate#_to_#endDate#.csv">
		<cfheader name="Content-disposition" value="attachment;filename=#targetFile#">
		<cfoutput>#csv#</cfoutput>
		<cfabort>
	</cfcase>
	<cfcase value="downloadVisitorsMediareqs">
		<!--- download Visitor and Media activity table as csv  --->
		<cfset csv = getVisitorsMediaRequests(beginDate="#beginDate#",endDate="#endDate#",returnAs="csv",annualReport="#annualReport#")>
		<cfheader name="Content-Type" value="text/csv">
		<cfset beginDate = rereplace(beginDate,'[^0-9]','','all')>
		<cfset endDate = rereplace(endDate,'[^0-9]','','all')>
		<cfset targetFile = "VisitorMedia_Activity_#beginDate#_to_#endDate#.csv">
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
			<div class="container-fluid" id="content">
				<div class="row">
				<br clear="all">	
					<nav id="sidebarMenu" class="col-md-3 col-lg-2 d-md-block sidebar" style="background-color: ##efeded;border: ##e3e3e3;">
						<div class="sidebar-sticky py-4 px-2" style="background-color: ##efeded;">
							<div class="accordion" id="accordionExample">
								<div class="card">
									<div class="card-header" id="headingTwo">
										<h2 class="mb-0">
										<button class="btn btn-link collapsed" type="button" data-toggle="collapse" data-target="##collapseTwo" aria-expanded="true" aria-controls="collapseTwo">
											Annual Reports
										</button>
										</h2>
									</div>
									<div id="collapseTwo" class="collapse show" style="border: 2px solid ##deedec;" aria-labelledby="headingTwo" data-parent="##accordionExample">
										<div class="card-body">
									
									<!---		<form class="py-2" id="loadReportForm2" onsubmit="return validateFiscalYear();">--->
											<form class="py-2" id="loadReportForm2">
												<div class="form-group">
													<input type="hidden" name="returnFormat" value="plain">
													<input type="hidden" name="annualReport" value="yes" class="data-entry-input">
													<h3 class="h4 text-muted mt-1 mb-2">Select Fiscal Year</h3>
													<!--- TODO: This needs to be a query on the historical data table, not a hard coded list, query below --->
													<!---
														SELECT 
                                       		distinct 'FY' || to_char(reported_date, 'yyyy') as fiscal_year_option
														FROM
															collections_reported_metrics
													--->
													<select id="fiscalYear" name="fiscalYear" onchange="setFiscalYearDates()" required class="data-entry-input my-1">
														
														<option value="FY2024" selected="selected">FY2024</option>
														<option value="FY2023">FY2023</option>
														<!-- Add more fiscal years as needed -->
													</select>
													<!-- Hidden fields to store beginDate and endDate -->
													<input type="hidden" id="beginDateFiscal" name="beginDate" value="#beginDateFiscal#">
													<input type="hidden" id="endDateFiscal" name="endDate" value="#endDateFiscal#">
													<h3 class="h4 text-muted mt-3">Report to Show</h3>
													<label for="method" class="sr-only">Report To Show</label>
													<select id="method" name="method" class="my-1 data-entry-input">
														<option value="getNumbers" selected="selected">Annual Report: Holdings</option>
														<option value="getAcquisitions">Annual Report: Acquisitions</option>
														<option value="getLoanNumbers">Annual Report: Loan Activity</option>
														<option value="getMediaNumbers">Annual Report: Media</option>
														<option value="getCitationNumbers">Annual Report: Citations</option>
														<option value="getGeorefNumbers">Annual Report: Georeferences</option>
														<option value="getVisitorsMediaRequests">Annual Report: Visitors and Media Requests</option>
													</select>
												</div>
												<button type="submit" value="Show Report" id="loadReportForm2" class="my-2 btn-xs btn btn-primary">Show Annual Report</button>
											</form>
											<!--- TODO: This needs to be an interpretation of a year value to fiscal year start end dates, not a hard coded list (allowing list of fiscal years to be retrieved from the database, not hard coded) --->
											<script>
												function setFiscalYearDates() {
													const fiscalYear = document.getElementById("fiscalYear").value; 
														var beginDate;
														var endDate;
														switch(fiscalYear) {
															case "FY2023":
																beginDate = "2022-07-01";
																endDate = "2023-06-30";
																break;
															case "FY2024":
																beginDate = "2023-07-01";
																endDate = "2024-06-30";
																break;
															default:
																beginDate = "";
																endDate = "";
																break;
														}
													document.getElementById("beginDateFiscal").value = beginDate; 
													document.getElementById("endDateFiscal").value = endDate;
												}
											</script>
										</div>
									</div>
								</div>
								<div class="card">
									<div class="card-header" id="headingOne">
										<h2 class="mb-0">
										<button class="btn btn-link" type="button" data-toggle="collapse" data-target="##collapseOne" aria-expanded="false" aria-controls="collapseOne">
											Custom Reports
										</button>
										</h2>
									</div>
									<div id="collapseOne" class="collapse" style="border: 2px solid ##deedec;" aria-labelledby="headingOne" data-parent="##accordionExample">
										<div class="card-body">
											<form class="py-2" id="loadReportForm1">
												<div class="form-group">
													<h3 class="h4 text-muted mt-1 mb-0">Select Report Date Range</h3>
													<input type="hidden" name="returnFormat" value="plain">
													<input type="hidden" name="annualReport" value="no" class="data-entry-input">
													<div class="row mx-0">
														<div class="col-12 px-0">
															<div class="col-12 col-md-6 pl-0 pr-1 float-left">
																<label for="beginDate" class="data-entry-label mt-2">Begin Date</label>
																<input name="beginDate" id="beginDate" type="text" class="mb-1 datetimeinput data-entry-input" placeholder="yyyy-mm-dd" value="#beginDate#" aria-label="start of range for dates to display metrics.">
															</div>
															<div class="col-12 col-md-6 pl-1 pr-0 float-left">
																<label for="endDate" class="data-entry-label mt-2">End Date</label>
																<input name="endDate" id="endDate" type="text" class="mb-1 datetimeinput data-entry-input" placeholder="yyyy-mm-dd" value="#endDate#" aria-label="end of range for dates to display metrics.">
															</div>
														</div>
													</div>
													<h3 class="h4 text-muted mt-3">Report to Show</h3>
													<label for="method" class="sr-only">Report To Show</label>
													<select id="method" name="method" class="my-1 data-entry-input">
														<option value="getNumbers" selected="selected">Holdings</option>
														<option value="getAcquisitions">Acquisitions</option>
														<option value="getLoanNumbers">Loan Activity</option>
														<option value="getMediaNumbers">Media</option>
														<option value="getCitationNumbers">Citations</option>
														<option value="getGeorefNumbers">Georeferences</option>
													</select>
												</div>
												<button type="submit" value="Show Report" id="loadReportForm1" class="btn btn-primary btn-xs my-2">Show Custom Report</button>
											</form>
										</div>
									</div>
								</div>

							</div>
							<script>
								$(document).ready(function() {
									$('##loadReportForm1').on('submit',function(event){ event.preventDefault(); loadReport1(); } );
								});
								function loadReport1(){
									$('##annualNumbersDiv1').html("Loading...");
									$.ajax(
										{
											url: '/metrics/component/functions.cfc',
											type: 'GET', 
											data: $('##loadReportForm1').serialize()
										}
									).done(
										function(response) {
											console.log(response);
											$('##annualNumbersDiv1').html(response);
											$('##annualNumbersDiv1').show();
										}
									).fail(function(jqXHR,textStatus,error){
										$('##annualNumbersDiv').html("Error Loading Metrics");
									handleFail(jqXHR,textStatus,error,"loading metrics for date range.");
									});
								}
							</script>
							<script>
								$(document).ready(function() {
									$('##loadReportForm2').on('submit',function(event){ event.preventDefault(); loadReport2(); } );
								});
								function loadReport2(){
									$('##annualNumbersDiv2').html("Loading...");
									$.ajax(
										{
											url: '/metrics/component/functions.cfc',
											type: 'GET', 
											data: $('##loadReportForm2').serialize()
										}
									).done(
										function(response) {
											console.log(response);
											$('##annualNumbersDiv2').html(response);
											$('##annualNumbersDiv2').show();
										}
									).fail(function(jqXHR,textStatus,error){
										$('##annualNumbersDiv2').html("Error Loading Metrics");
									handleFail(jqXHR,textStatus,error,"loading metrics for date range.");
									});
								}
							</script>
							<script>
								 document.addEventListener('DOMContentLoaded', function () {
									const formInSidebar1 = document.getElementById('collapseTwo');
									const resultsInMain1 = document.getElementById('divTwo');
									
									const formInSidebar2 = document.getElementById('collapseOne');
									const resultsInMain2 = document.getElementById('divOne');
									
									function checkFormVisibility1() {
										if ($(formInSidebar1).hasClass('show')) {
											resultsInMain1.style.display = 'block';
										} else {
											resultsInMain1.style.display = 'none';
										}
									}
									
									function checkFormVisibility2() {
										if ($(formInSidebar2).hasClass('show')) {
											resultsInMain2.style.display = 'block';
										} else {
											resultsInMain2.style.display = 'none';
										}
									}

									$(formInSidebar1).on('hidden.bs.collapse', checkFormVisibility1);
									$(formInSidebar1).on('shown.bs.collapse', checkFormVisibility1);
									 
									$(formInSidebar2).on('hidden.bs.collapse', checkFormVisibility2);
									$(formInSidebar2).on('shown.bs.collapse', checkFormVisibility2);

									checkFormVisibility1();
									checkFormVisibility2();
								});

								function displayResults1() {
									const resultsInMain1 = document.getElementById('resultsInMain1');
									resultsInMain1.innerHTML = '<p>Results from CFC function query appear here.</p>';
									resultsInMain1.style.display = 'block';
								}
								function displayResults2() {
									const resultsInMain2 = document.getElementById('resultsInMain2');
									resultsInMain2.innerHTML = '<p>Results from CFC function query appear here.</p>';
									resultsInMain2.style.display = 'block';
								}
								
								
								
							//	function validateFiscalYear() {
//									var beginDate = new Date(document.getElementById('beginDate').value);
//									var endDate = new Date(document.getElementById('endDate').value);
//										
//									var expectedEndDate = new Date(beginDate);
//										expectedEndDate.setFullYear(expectedEndDate.getFullYear() + 1);
//										expectedEndDate.setMonth(5); // June
//										expectedEndDate.setDate(30); // 30
//
//									displayResults();
//									return true; 
//								}
							</script>
						</div>
					</nav>
					<main role="main" class="col-md-9 px-3 ml-sm-auto col-lg-10 mb-3">
						<div class="card-body">
							<div class="col-12 mt-4">
								<h1 class="h2 float-left mb-1 w-100">MCZbase Metrics </h1>
								<p class="text-muted small">Reports are generated from the current MCZbase data and may not match numbers printed in previous annual reports.</p>
								<div id="divOne" style="border: 2px solid ##deedec;padding:0 15px 0 15px;">
									<cfset summaryAnnualBlock1=getNumbers(endDate="#endDate#",beginDate="#beginDate#",annualReport="no")>
									<div id="annualNumbersDiv1" class="py-2"> 
										#summaryAnnualBlock1#
									</div>
								</div>
								<div id="divTwo" style="border: 2px solid ##deedec;padding:0 15px 0 15px;">
									<cfset summaryAnnualBlock2=getNumbers(endDate="#endDate#",beginDate="#beginDate#",annualReport="yes")>
									<div id="annualNumbersDiv2" class="py-2"> 
										#summaryAnnualBlock2#
									</div>
								</div>
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
