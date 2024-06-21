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
<cfset endDate=''>
<cfset beginDate=''>
<cfset action=''>
	
<cfset pageTitle="Metrics Testing">
<cfinclude template="/shared/_header.cfm">
<cfinclude template="/metrics/component/functions.cfc">
<script type="text/javascript" src="/metrics/js/metrics.js"></script> 

<cfsetting RequestTimeout = "0">
<cfset start = GetTickCount()>
<meta name="theme-color" content="#563d7c">
<cfoutput>
<div class="container-fluid" id="content">
	<div class="row">
		

<!---<form id="myForm">
	<input type="date" name="beginDate">
	<input type="date" name="endDate"> 
	<input type="hidden" class="btn btn-xs btn-primary" value="submit">
</form>
<a href="javascript:submitForm()">Submit to Function</a>
<script> 
	function submitForm() { 
		var form = document.getElementById("myForm"); 
		form.action = "/metrics/Dashboard.cfm##getAnnualNumbers1"; 
		form.submit(); 
	} 
</script>
<cffunction name="getAnnualNumbers1"> 
	<cfargument name="form" type="date" required="true">
	<cfoutput>#form.beginDate#</cfoutput>
	<cfoutput>#form.endDate#</cfoutput>
</cffunction>--->
	<br clear="all">	
		<nav id="sidebarMenu" class="col-md-2 col-lg-2 d-md-block bg-light sidebar collapse">
			<div class="sidebar-sticky pt-4 px-3">
				<h3 class="text-muted"><span>Report Date Range</span></h3>
				
				<cfif NOT isdefined("action") or len(action) EQ 0>
					<cfset action="showBasic">
				</cfif>
			
				<cfif len(endDate) eq 0>
					<form action="/metrics/Dashboard.cfm" class="pt-1" id="dateForm">
						<label for="beginDate" class="data-entry-label">Begin Date</label>
						<input type="date" id="beginDate" name="beginDate" class="data-entry-input" value="#DateFormat (Now(), "yyyy-mm-dd")#">
						<label for="endDate" class="data-entry-label mt-2">End Date</label>
						<input type="date" id="endDate" name="endDate" class="data-entry-input" value="#DateFormat (Now(), 'yyyy-mm-dd')#">
					</form>
				<cfelse>
					<form action="/metrics/Dashboard.cfm" class="pt-1" id="dateForm">
						<label for="beginDate" class="data-entry-label">Begin Date</label>
						<input type="date" id="beginDate" name="beginDate" class="data-entry-input" value="#beginDate#">
						<label for="endDate" class="data-entry-label mt-2">End Date</label>
						<input type="date" id="endDate" name="endDate" class="data-entry-input" value="#endDate#">
					</form>
				</cfif>
				<cfset beginDate = "2022-01-01">
				<cfset endDate = "2024-01-01">
				<h3 class="sidebar-heading d-flex justify-content-between align-items-center px-1 mt-4 mb-1 text-muted"> 
					<span>Report Type</span> 
				</h3>
					<ul class="nav flex-column mb-2">
						<li class="nav-item"> 
							<cfset myBasicResults = CreateObject("component", "/metrics/component/functions")>
							<cfset basicresult = myBasicResults.getAnnualNumbers("2022-01-01","2024-01-01")>
								<a class="nav-link px-0" href="##" onclick="getAnnualNums(); return false;">
								<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="feather feather-file-text">
									<path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
									<polyline points="14 2 14 8 20 8"></polyline>
									<line x1="16" y1="13" x2="8" y2="13"></line>
									<line x1="16" y1="17" x2="8" y2="17"></line>
									<polyline points="10 9 9 9 8 9"></polyline>
								</svg>
								Basic Collection Metrics
							</a> 
						</li>
						<li class="nav-item"> 
							<cfset myBasicResults = CreateObject("component", "/metrics/component/functions")>
							<cfset loanresult = myBasicResults.getloanNumbers(beginDate,endDate)>
								<a class="nav-link px-0" href="##" onclick="getLoanNums(); return false;">
								<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="feather feather-file-text">
									<path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
									<polyline points="14 2 14 8 20 8"></polyline>
									<line x1="16" y1="13" x2="8" y2="13"></line>
									<line x1="16" y1="17" x2="8" y2="17"></line>
									<polyline points="10 9 9 9 8 9"></polyline>
								</svg>
								Loan Numbers
							</a> 
						</li>
						<li class="nav-item"> 
							<cfset myMediaResults = CreateObject("component", "/metrics/component/functions")>
							<cfset mediaresult = myMediaResults.getMediaNumbers(beginDate,endDate)>
								<a class="nav-link px-0" href="##" onclick="getMediaNums(); return false;">
								<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="feather feather-file-text">
									<path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
									<polyline points="14 2 14 8 20 8"></polyline>
									<line x1="16" y1="13" x2="8" y2="13"></line>
									<line x1="16" y1="17" x2="8" y2="17"></line>
									<polyline points="10 9 9 9 8 9"></polyline>
								</svg>
								Media 
							</a> 
						</li>
						<li class="nav-item"> 
							<cfset myCitationResults = CreateObject("component", "/metrics/component/functions")>
							<cfset citationresult = myCitationResults.getCitationNumbers(beginDate,endDate)>
								<a class="nav-link px-0" href="##" onclick="callCitations(); return false;">
								<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="feather feather-file-text">
									<path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
									<polyline points="14 2 14 8 20 8"></polyline>
									<line x1="16" y1="13" x2="8" y2="13"></line>
									<line x1="16" y1="17" x2="8" y2="17"></line>
									<polyline points="10 9 9 9 8 9"></polyline>
								</svg>
								Citations 
							</a> 
						</li>
						<li class="nav-item"> 
							<cfset myGeorefResults = CreateObject("component", "/metrics/component/functions")>
							<cfset georefresult = myGeorefResults.getGeorefNumbers(beginDate,endDate)>
								<a class="nav-link px-0" href="##" onclick="getGeorefNumbers(); return false;">
								<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="feather feather-file-text">
									<path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
									<polyline points="14 2 14 8 20 8"></polyline>
									<line x1="16" y1="13" x2="8" y2="13"></line>
									<line x1="16" y1="17" x2="8" y2="17"></line>
									<polyline points="10 9 9 9 8 9"></polyline>
								</svg>
								Georeferences
							</a> 
						</li>
					</ul>
					
			
			
			</div>
		</nav>

		<main role="main" class="col-md-10 ml-sm-auto col-lg-10 px-md-5 mb-3">
			<div class="row">
				<cfoutput>
					<div class="col-12 px-0 mt-4">
						<h1 class="h2 float-left">Metrics</h1>
						<div class="btn-toolbar mb-2 mb-md-0 float-right">
							<div class="btn-group mr-2">
								<button type="button" class="btn btn-sm btn-outline-secondary">Share</button>
								<button type="button" class="btn btn-sm btn-outline-secondary">Export</button>
							</div>
						</div>
					</div>
							
				<!---	<div id="basicresult">#basicresult#</div>--->
							
						<cfset loanBlock=getLoanNumbers(endDate="2024-07-01",beginDate="2023-07-01")>
						<div id="annualLoanDiv">
							#loanBlock#
						</div>
							
				<!---	<div id="citationresult">#citationresult#</div>
							
					<div id="mediaresult">#mediaresult#</div>--->
							
				<!---	<div id="georefresult">#georefresult#</div>--->
			<!---		<cfif action EQ "showBasic">
						<cfset summaryAnnualBlock=getAnnualNumbers(endDate="2024-07-01",beginDate="2023-07-01")>
						<div id="annualNumbersDiv">
							#summaryAnnualBlock#
						</div>
					</cfif>--->
<!---					<cfif action EQ "showLoans">
						<cfset loanBlock=getLoanNumbers(action="showLoans",endDate="2024-07-01",beginDate="2023-07-01")>
						<div id="annualLoanDiv">
							#loanBlock#
						</div>
					</cfif>	
					<cfif action EQ "showMedia">
						<cfset mediaBlock=getMediaNumbers(action="showMedia",endDate="2024-07-01",beginDate="2023-07-01")>
						<div id="mediaDiv">
							#mediaBlock#
						</div>
					</cfif>
					<cfif action EQ "showCitations">
						<cfset citationBlock=getCitationNumbers(action="showCitations",endDate="2024-07-01",beginDate="2023-07-01")>
						<div id="citationDiv">
							#citationBlock#
						</div>
					</cfif>
					<cfif action EQ "showGeorefs">
						<cfset georefBlock=getGeorefNumbers(action="showGeorefs",endDate="#endDate#",beginDate="#beginDate#")>
						<div id="georefDiv">
							#georefBlock#
						</div>
					</cfif>--->
				</cfoutput>
			</div>
		</main>
	</div>
	<cfoutput>Execution Time: <b>#int(getTickCount()-start)#</b> milliseconds<br></cfoutput>
</div>

</cfoutput>

<cfinclude template="/shared/_footer.cfm">
