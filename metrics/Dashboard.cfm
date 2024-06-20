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
		<nav id="sidebarMenu" class="col-md-2 col-lg-2 d-md-block bg-light sidebar collapse">
			<div class="sidebar-sticky pt-4 px-3">
				<h3 class="text-muted"><span>Report Date Range</span></h3>
				<cfif endDate gt 0>
					<cfset endDate = #DateFormat (Now(), "yyyy-mm-dd")#>
					<cfset beginDate = #DateFormat(DateAdd( 'm', -12, now() ),"yyyy-mm-dd")#>
				<cfelse>
					<cfset endDate = "2023-07-01">
					<cfset beginDate = "2022-06-30">
				</cfif>
				<cfif NOT isdefined("action") or len(action) EQ 0>
					<cfset action="showBasic">
				</cfif>
				<form action="/metrics/Dashboard.cfm" method="post" name="pagendates">
					<input type="date" name="endDate" size="10" value="#endDate#"><br>
					<input type="date" name="beginDate" size="10" value="#beginDate#"><br>
					<input type="text" name="action" size="10" value="#action#"><br>
					<input type="submit" name="Submit">
				</form>
				<form action="/metrics/Dashboard.cfm?action=#action#&beginDate=#beginDate#&endDate=#endDate#" class="pt-1" id="dateForm">
					<cfif endDate gt 0>
						<cfset endDate = #DateFormat (Now(), "yyyy-mm-dd")#>
						<cfset beginDate = #DateFormat(DateAdd( 'm', -12, now() ),"yyyy-mm-dd")#>
					<cfelse>
						<cfset endDate = "2023-07-01">
						<cfset beginDate = "2022-06-30">
					</cfif>
					<cfif NOT isdefined("action") or len(action) EQ 0>
						<cfset action="showBasic">
					</cfif>
					<cfif NOT isDefined("endDate") and len(endDate) EQ 0>
						<cfset endDate = "#endDate#">
					</cfif>
					<cfif NOT isDefined("beginDate") and len(beginDate) EQ 0>
						<cfset beginDate = "#beginDate#">
					</cfif>
					<label for="beginDate" class="data-entry-label">Begin Date</label>
					<input type="date" id="beginDate" name="beginDate" class="data-entry-input" value="#beginDate#">
					<label for="endDate" class="data-entry-label mt-2">End Date</label>
					<input type="date" id="endDate" name="endDate" class="data-entry-input" value="#endDate#">
					

					<h3 class="sidebar-heading d-flex justify-content-between align-items-center px-1 mt-4 mb-1 text-muted"> 
						<span>Report Type</span> 
					</h3>
					
					<ul class="nav flex-column mb-2">
						<li class="nav-item"> 
							<a class="nav-link px-0" href="Dashboard.cfm?action=showBasic&beginDate=#beginDate#&endDate=#endDate#" onClick="showBasicFunction">

								<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="feather feather-file-text">
									<path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
									<polyline points="14 2 14 8 20 8"></polyline>
									<line x1="16" y1="13" x2="8" y2="13"></line>
									<line x1="16" y1="17" x2="8" y2="17"></line>
									<polyline points="10 9 9 9 8 9"></polyline>
								</svg>
								Basic Collection Metrics
							</a> 
							<input type="hidden" name="action" value="showBasic">
						</li>
						
						<li class="nav-item"> 
							<a class="nav-link px-0" href="Dashboard.cfm?action=showLoans&beginDate=#beginDate#&endDate=#endDate#">
								<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="feather feather-file-text">
									<path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
									<polyline points="14 2 14 8 20 8"></polyline>
									<line x1="16" y1="13" x2="8" y2="13"></line>
									<line x1="16" y1="17" x2="8" y2="17"></line>
									<polyline points="10 9 9 9 8 9"></polyline>
								</svg>
								Loans 
							</a> 
						</li>
						<li class="nav-item"> 
							<a class="nav-link px-0" href="Dashboard.cfm?action=showMedia&beginDate=#beginDate#&endDate=#endDate#">
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
							<a class="nav-link px-0" href="Dashboard.cfm?action=showCitations&beginDate=#beginDate#&endDate=#endDate#">
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
							<a class="nav-link px-0" href="javascript:void(0);" role="button">
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
					
					<input type="submit" value="Submit" class="btn btn-xs btn-secondary mt-2" onClick="event.preventDefault(); $(dateForm).submit();">
				</form>
				<script> 
					function myFunction() { 
						document.getElementById("GFG").submit(); 
					} 
				</script> 
			</div>
		</nav>

		<main role="main" class="col-md-10 ml-sm-auto col-lg-10 px-md-5 mb-3">
			<div class="row">
	
				<div class="col-12 px-0 mt-4">
					<h1 class="h2 float-left">Metrics</h1>
					<div class="btn-toolbar mb-2 mb-md-0 float-right">
						<div class="btn-group mr-2">
							<button type="button" class="btn btn-sm btn-outline-secondary">Share</button>
							<button type="button" class="btn btn-sm btn-outline-secondary">Export</button>
						</div>
					</div>
				</div>
				<cfoutput>
					<cfif action EQ "showBasic">
						<cfset summaryAnnualBlock=getAnnualNumbers(endDate="#endDate#",beginDate="#beginDate#")>
						<div id="annualNumbersDiv">
						#summaryAnnualBlock#
						</div>
					</cfif>
					<cfif action EQ "showLoans">
						<cfset loanBlock=getLoanNumbers(endDate="#endDate#",beginDate="#beginDate#")>
						<div id="annualLoanDiv">
							#loanBlock#
						</div>
					</cfif>	
					<cfif action EQ "showMedia">
						<cfset mediaBlock=getMediaNumbers(endDate="#endDate#",beginDate="#beginDate#")>
						<div id="mediaDiv">
							#mediaBlock#
						</div>
					</cfif>
					<cfif action EQ "showCitations">
						<cfset citationBlock=getCitationNumbers(endDate="#endDate#",beginDate="#beginDate#")>
						<div id="citationDiv">
							#citationBlock#
						</div>
					</cfif>
					<cfif action EQ "showGeorefs">
						<cfset georefBlock=getGeorefNumbers(endDate="#endDate#",beginDate="#beginDate#")>
						<div id="georefDiv">
							#georefBlock#
						</div>
					</cfif>
				</cfoutput>
			</div>
		</main>
	</div>
	<cfoutput>Execution Time: <b>#int(getTickCount()-start)#</b> milliseconds<br></cfoutput>
</div>

</cfoutput>

<cfinclude template="/shared/_footer.cfm">
