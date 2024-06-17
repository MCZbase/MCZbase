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
<cfif isDefined("endDate") and len(endDate) GT 0>
	<cfset endDate = endDate>
</cfif>
<cfif isDefined("beginDate") and len(beginDate) GT 0>
	<cfset beginDate = beginDate>
</cfif>
	
<cfset pageTitle="Metrics Testing">
<cfinclude template="/shared/_header.cfm">
<script type="text/javascript" src="/metrics/js/metrics.js"></script> 


<meta name="theme-color" content="#563d7c">
<cfoutput>
<div class="container-fluid" id="content">
	<div class="row">
		<nav id="sidebarMenu" class="col-md-2 col-lg-2 d-md-block bg-light sidebar collapse">
			<div class="sidebar-sticky pt-4 px-3">
				<h3>Fiscal Year Reports</h3>
				<cfform action="/metrics/Dashboard.cfm" class="pt-1">
					<label for="beginDate" class="data-entry-label">Begin Date</label>
					<input type="date" id="beginDate" name="beginDate" class="data-entry-input">
					<label for="endDate" class="data-entry-label mt-3">End Date</label>
					<input type="date" id="endDate" name="endDate" class="data-entry-input">
					<input type="submit" value="Submit" class="btn btn-xs btn-secondary mt-2" onClick="event.preventDefault(); $(getAnnualNumbersJS).submit();">
				</cfform>

				<h4 class="sidebar-heading d-flex justify-content-between align-items-center px-1 mt-4 mb-1 text-muted"> 
					<span>Other Reports</span> 
					<!---<a class="d-flex align-items-center text-muted" href="##" aria-label="Add a new report">
						<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="feather feather-plus-circle">
							<circle cx="12" cy="12" r="10"></circle>
							<line x1="12" y1="8" x2="12" y2="16"></line>
							<line x1="8" y1="12" x2="16" y2="12"></line>
						</svg>
					</a> --->
				</h4>
				<ul class="nav flex-column mb-2">
					<li class="nav-item"> 
						<a class="nav-link" href="##">
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
						<a class="nav-link" href="##">
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
						<a class="nav-link" href="##">
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
				</ul>
			</div>
		</nav>
		<main role="main" class="col-md-10 ml-sm-auto col-lg-10 px-md-5">
		<cfset endDate = #DateFormat (Now(), "yyyy-mm-dd")#>
		<cfset beginDate = #DateFormat(DateAdd( 'm', -12, now() ),"yyyy-mm-dd")#>
			<div class="d-flex justify-content-between flex-wrap flex-md-nowrap align-items-center pt-3 pb-2 mb-3 border-bottom">
				<h1 class="h2">Metrics Sandbox</h1>
				<div class="btn-toolbar mb-2 mb-md-0">
					<div class="btn-group mr-2">
						<button type="button" class="btn btn-sm btn-outline-secondary">Share</button>
						<button type="button" class="btn btn-sm btn-outline-secondary">Export</button>
					</div>

					<cfoutput>
						<cfset summaryAnnualBlock = getAnnual(endDate = "#endDate#", beginDate = "#beginDate#")>
					</cfoutput>

					<div id="annualNumbersDiv">
						#summaryAnnualBlock#
					</div>

				</div>
			</div>
		</main>
	</div>
</div>

</cfoutput>
<cfinclude template="/shared/_footer.cfm">
