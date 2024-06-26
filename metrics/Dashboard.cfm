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

-->

	
<cfset pageTitle="Metrics Dashboard">
<cfinclude template="/shared/_header.cfm">
<cfinclude template="/metrics/component/functions.cfc">
<script type="text/javascript" src="/metrics/js/metrics.js"></script> 
<style>
.loader,
	.loader:after {
		border-radius: 50%;
		width: 10em;
		height: 10em;
	}
	.loader {            
		margin: 60px auto;
		font-size: 10px;
		position: relative;
		text-indent: -9999em;
		border-top: 1.1em solid rgba(255, 255, 255, 0.2);
		border-right: 1.1em solid rgba(255, 255, 255, 0.2);
		border-bottom: 1.1em solid rgba(255, 255, 255, 0.2);
		border-left: 1.1em solid #ffffff;
		-webkit-transform: translateZ(0);
		-ms-transform: translateZ(0);
		transform: translateZ(0);
		-webkit-animation: load8 1.1s infinite linear;
		animation: load8 1.1s infinite linear;
	}
	@-webkit-keyframes load8 {
		0% {
			-webkit-transform: rotate(0deg);
			transform: rotate(0deg);
		}
		100% {
			-webkit-transform: rotate(360deg);
			transform: rotate(360deg);
		}
	}
	@keyframes load8 {
		0% {
			-webkit-transform: rotate(0deg);
			transform: rotate(0deg);
		}
		100% {
			-webkit-transform: rotate(360deg);
			transform: rotate(360deg);
		}
	}
	#loadingDiv {
		position:absolute;;
		top:0;
		left:0;
		width:100%;
		height:100%;
		background-color:#000;
	}

</style>

<!--- TODO: Set to most recent full year. --->
<cfif NOT isDefined("beginDate")><cfset beginDate = '2023-01-01'></cfif>
<cfif NOT isDefined("endDate")><cfset endDate = '2023-12-31'></cfif>
<cfsetting RequestTimeout = "0">
<cfset start = GetTickCount()>
<meta name="theme-color" content="#563d7c">
<cfoutput>
	<div class="container-fluid" id="content">
		<div class="row">
			<br clear="all">	
			<nav id="sidebarMenu" class="col-md-2 col-lg-2 d-md-block bg-light sidebar collapse">
				<div class="sidebar-sticky pt-4 px-2">
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
							<option value="getAnnualNumbers" selected="selected">Holdings &amp; Acquisitions</option>
							<option value="getLoanNumbers">Loan Activity</option>
							<option value="getMediaNumbers">Media Activity</option>
							<option value="getCitationNumbers">Citation Activity</option>
							<option value="getGeorefNumbers">Georeference Activity</option>
						</select>
						<input type="submit" value="submit" class="my-3 btn-xs btn btn-primary">
					</form>
					<script>
						$('body').append('<div style="" id="loadingDiv"><div class="loader">Loading...</div></div>');
						$(window).on('load', function(){
							setTimeout(removeLoader, 2000); //wait for page load PLUS two seconds.
						});
						function removeLoader(){
							$( "#loadingDiv" ).fadeOut(500, function() {
						// fadeOut complete. Remove the loading div
							$( "#loadingDiv" ).remove(); //makes page more lightweight 
							});  
						}
					</script>
				</div>
			</nav>
			<main role="main" class="col-md-10 ml-sm-auto col-lg-10 px-md-5 mb-3">
				<div class="row">
					<cfoutput>
						<div class="col-12 px-0 mt-4">
							<h1 class="h2 float-left pt-1">MCZbase Metrics</h1>
							<div class="btn-toolbar mb-2 mb-md-0 float-right">
								<div class="btn-group mr-2">
									<button type="button" class="btn btn-sm btn-outline-secondary">Share</button>
									<button type="button" class="btn btn-sm btn-outline-secondary">Export</button>
								</div>
							</div>
						</div>
						<cfset summaryAnnualBlock=getAnnualNumbers(endDate="#endDate#",beginDate="#beginDate#")>
						<div id="annualNumbersDiv">
							#summaryAnnualBlock#
						</div>
					</cfoutput>
				</div>
			</main>
		<cfoutput><div class="my-3">Execution Time: <b>#int(getTickCount()-start)#</b> milliseconds</div></cfoutput>
		</div>
	</div>
</cfoutput>
<cfinclude template="/shared/_footer.cfm">
