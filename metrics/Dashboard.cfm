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
				nav##sidebarMenu {
					background-color: ##efeded;
					background-color: white;
					border-right: ##e3e3e3;
				}
				div.sidebar-sticky a {
					display: block;
					text-decoration: none;
					color: inherit; /* Inherit the color of the <h2> element */
					padding: 2rem;
					transition: background-color 0.3s ease;
				}
				div.sidebar-sticky a.active {
					background-color: lightcoral; /* Default active background color */
					background-color: ##d7d7d7;
				}
				div.sidebar-sticky a.active-1 {
					background-color: lightcoral;
					background-color: ##d7d7d7;
				}
				div.sidebar-sticky a:hover {
					color: darkblue;
					color: ##0460c1;
				}
				.target-div {
					display: none; /* Hide divs by default */
					margin-top: 30px;
					padding: 20px;
					transition: opacity 0.3s ease;
				}
				.target-div.visible {
					display: block; /* Show div when it has the 'visible' class */
				}
			</style>
			<div class="container-fluid px-0" id="content">
				<div class="col-12 border-bottom border-muted border-right-0 border-left-0 border-top-0 py-3">
					<h1 class="h2 float-left mb-1 w-100 px-3">MCZbase Metrics </h1>
					<p class="text-muted px-3 mb-0">Reports are generated from the current MCZbase data and may not match numbers printed in previous annual reports.</p>
				</div>
				<div class="row mx-0">
				<br clear="all">	
					<nav id="sidebarMenu" class="col-12 col-xl-auto w-auto px-4 d-md-block sidebar border-right border-muted">
						<div class="sidebar-sticky pt-4 px-2">
							<a href="##" id="link1"><h2 class="h4"><i class="fa fa-list-alt text-muted pr-2" aria-hidden="true"></i>Annual Report List</h2></a>
							<a href="##" id="link2"><h2 class="h4"><i class="fa fa-calendar text-muted pr-2" aria-hidden="true"></i>Select Date Range</h2></a>
						</div>
					</nav>
				
					<main role="main" class="col-md-9 mr-xl-auto col-lg-10 pb-3 bg-light border-right border-muted">
						<div id="div1" class="target-div bg-none">
							<div class="col-12 mt-0 pb-4">
								<form id="loadReportForm" class="row mx-0">
									<div class="col-12 col-xl-5 px-0">
										<h3 class="h4 text-muted">Annual Reports</h3>
										<div class="row mx-0">
											<div class="col-12 col-xl-10 pl-xl-0">
												<input type="hidden" name="returnFormat" value="plain">
												<input name="beginDate" id="beginDate" type="hidden" value="#beginDate#">
												<input name="endDate" id="endDate" type="hidden" value="#endDate#">
												<cfset currentDate = Year(Now())>
												<cfset beginYear = currentYear - 1> <!-- Adjust as needed to show past fiscal years -->
												<cfset endYear = currentDate + 1>	
											 	<label for="fiscalYear" class="data-entry-label mt-2">Select Fiscal Year:</label>
												<select name="fiscalYear" id="fiscalYear" class="mb-1 data-entry-input">	
													<cfloop from="#beginYear#" to="#endYear#" index="fiscalYear">
														<cfset fiscalYearStart = #fiscalYear# - 1>
														<option value="getAnnualNumbers" selected>Fiscal Year:  7/1/#fiscalYearStart# - 6/30/#fiscalYear#</option>
													</cfloop>
												</select>
											</div>
										</div>
									</div>
									<div class="col-12 col-xl-2 px-0">
										<h3 class="h4 mt-3 text-light">Submit</h3>
										<div class="row mx-0">
											<div class="col-12 col-xl-9">
												<input type="submit" value="Show Report" class="my-2 btn-xs btn btn-primary" aria-label="Show the annual report selected">
											</div>
										</div>
									</div>
								</form>
								<script>
									$(document).ready(function() {
										$('##loadAnnualReport').on('submit',function(event){ event.preventDefault(); loadReportYear(); } );
									});
									function loadReport2(){
										$('##annualNumbersDiv2').html("Loading...");
										$.ajax(
											{
												url: '/metrics/component/functions.cfc',
												type: 'GET', 
												data: $('##loadAnnualReport').serialize()
											}
										).done(
											function(response) {
												console.log(response);
												$('##annualNumbersDiv2').html(response);
											}
										).fail(function(jqXHR,textStatus,error){
											$('##annualNumbersDiv2').html("Error Loading Metrics");
										handleFail(jqXHR,textStatus,error,"loading metrics for date range.");
										});
									}
								</script>
							</div>
							<div class="col-12 mt-0 pb-3">
							<!---	<cfset summaryAnnualBlock=getAnnualNumbers(fiscalYear="#fiscalYear#")>
								<div id="annualNumbersDiv2"> 
									#summaryAnnualBlock#
								</div>--->
								<h2 class="h4">Report will be displayed here.</h2>
							</div>
						</div>
						
						<div id="div2" class="target-div bg-none">
							<div class="col-12 mt-0 pb-4">
								<form id="loadReportForm" class="row mx-0">
									<div class="col-12 col-xl-8 px-0">
										<h3 class="h4 text-muted">Select Report Date Range and Report Type</h3>
										<div class="row mx-0">
											<div class="col-12 col-xl-4 pl-xl-0">
												<input type="hidden" name="returnFormat" value="plain">
												<label for="beginDate" class="data-entry-label mt-2">Begin Date</label>
												<input name="beginDate" id="beginDate" type="text" class="mb-1 datetimeinput data-entry-input data-entry-input" placeholder="yyyy-mm-dd" value="#beginDate#" aria-label="start of range for dates to display metrics.">
											</div>
											<div class="col-12 col-xl-4 pl-xl-0">
												<label for="endDate" class="data-entry-label mt-2">End Date</label>
												<input name="endDate" id="endDate" type="text" class="mb-1 datetimeinput data-entry-input" placeholder="yyyy-mm-dd" value="#endDate#" aria-label="end of range for dates to display metrics.">
											</div>
											<div class="col-12 col-xl-3 pl-xl-0">
												<label for="method" class="data-entry-label mt-2">Report To Show</label>
												<select id="method" name="method" class="mb-1 data-entry-input">
													<option value="getAcquisitions"  selected="selected">Acquisitions</option>
													<option value="getAnnualNumbers">Holdings</option>
													<option value="getLoanNumbers">Loan Activity</option>
													<option value="getMediaNumbers">Media (current)</option>
													<option value="getCitationNumbers">Citations (current)</option>
													<option value="getGeorefNumbers">Georeferences (current)</option>
												</select>
											</div>
										</div>
									</div>
									<div class="col-12 col-xl-2 px-0">
										<h3 class="h4 mt-3 text-white">Submit</h3>
										<div class="row mx-0">
											<div class="col-12 col-xl-9">
												<input type="submit" value="Show Report" class="my-2 btn-xs btn btn-primary" aria-label="Show the selected report for the specified date range">
											</div>
										</div>
									</div>
								</form>

								<script>
									$(document).ready(function() {
										$('##loadReportForm').on('submit',function(event){ event.preventDefault(); loadReport(); } );
									});
									function loadReport(){
										$('##selectedReportDiv').html("Loading...");
										$.ajax(
											{
												url: '/metrics/component/functions.cfc',
												type: 'GET', 
												data: $('##loadReportForm').serialize()
											}
										).done(
											function(response) {
												console.log(response);
												$('##selectedReportDiv').html(response);
											}
										).fail(function(jqXHR,textStatus,error){
											$('##selectedReportDiv').html("Error Loading Metrics");
										handleFail(jqXHR,textStatus,error,"loading metrics for date range.");
										});
									}
								</script>
							</div>
							<div class="col-12 mt-0 pb-3">
								<cfset selectedReportBlock=getAcquisitions(endDate="#endDate#",beginDate="#beginDate#")>
								<div id="selectedReportDiv"> 
									#selectedReportBlock#
								</div>
							</div>
						</div>
					</main>
					<script>
						function removeActiveClasses() {
							document.querySelectorAll('a').forEach(link => link.classList.remove('active', 'active-1', 'active-2'));
						}

						function hideAllDivs() {
							document.querySelectorAll('.target-div').forEach(div => div.classList.remove('visible'));
						}

						function setInitialState() {
							const savedLinkId = localStorage.getItem('activeLink');
							const savedDivId = localStorage.getItem('activeDiv');

							if (savedLinkId && savedDivId) {
								document.getElementById(savedLinkId).classList.add('active', `active-${savedLinkId.slice(-1)}`);
								document.getElementById(savedDivId).classList.add('visible');
							} else {
								// Default state if nothing is saved
								document.getElementById("link1").classList.add('active', 'active-1');
								document.getElementById("div1").classList.add('visible');
							}
						}

						function saveState(linkId, divId) {
							localStorage.setItem('activeLink', linkId);
							localStorage.setItem('activeDiv', divId);
						}

						document.getElementById("link1").addEventListener("click", function(e) {
							e.preventDefault(); // Prevent default anchor behavior
							removeActiveClasses();
							this.classList.add('active', 'active-1');
							hideAllDivs();
							document.getElementById("div1").classList.add('visible');
							saveState('link1', 'div1');
						});

						document.getElementById("link2").addEventListener("click", function(e) {
							e.preventDefault(); // Prevent default anchor behavior
							removeActiveClasses();
							this.classList.add('active', 'active-2');
							hideAllDivs();
							document.getElementById("div2").classList.add('visible');
							saveState('link2', 'div2');
						});


						// Initial setup
						setInitialState();

					</script>
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
