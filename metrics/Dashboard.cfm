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
<cfset pageTitle="Metrics Testing">
<cfinclude template="/shared/_header.cfm">
<cfinclude template = "/shared/component/functions.cfc">
    <meta name="author" content="Mark Otto, Jacob Thornton, and Bootstrap contributors">
<link rel="canonical" href="https://getbootstrap.com/docs/4.5/examples/dashboard/">
<meta name="theme-color" content="#563d7c">
<style>
.bd-placeholder-img {
	font-size: 1.125rem;
	text-anchor: middle;
	-webkit-user-select: none;
	-moz-user-select: none;
	-ms-user-select: none;
	user-select: none;
}

@media (min-width: 768px) {
	.bd-placeholder-img-lg {
	font-size: 3.5rem;
	}
}
</style>
<!-- Custom styles for this template -->
<link href="dashboard.css" rel="stylesheet">
<style type="text/css">/* Chart.js */
@-webkit-keyframes chartjs-render-animation{from{opacity:0.99}to{opacity:1}}@keyframes chartjs-render-animation{from{opacity:0.99}to{opacity:1}}.chartjs-render-monitor{-webkit-animation:chartjs-render-animation 0.001s;animation:chartjs-render-animation 0.001s;}</style>

<cfoutput>

<div class="container-fluid">
  <div class="row">
    <nav id="sidebarMenu" class="col-md-3 col-lg-2 d-md-block bg-light sidebar collapse">
      <div class="sidebar-sticky pt-3">
        <ul class="nav flex-column">
          <li class="nav-item">
            <a class="nav-link active" href="##">
              <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="feather feather-home"><path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"></path><polyline points="9 22 9 12 15 12 15 22"></polyline></svg>
              Dashboard <span class="sr-only">(current)</span>
            </a>
          </li>
          <li class="nav-item">
            <a class="nav-link" href="##">
              <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="feather feather-file"><path d="M13 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V9z"></path><polyline points="13 2 13 9 20 9"></polyline></svg>
              Definitions
            </a>
          </li>
          <li class="nav-item">
            <a class="nav-link" href="##">
              <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="feather feather-shopping-cart"><circle cx="9" cy="21" r="1"></circle><circle cx="20" cy="21" r="1"></circle><path d="M1 1h4l2.68 13.39a2 2 0 0 0 2 1.61h9.72a2 2 0 0 0 2-1.61L23 6H6"></path></svg>
              Loan Stats
            </a>
          </li>
          <li class="nav-item">
            <a class="nav-link" href="##">
              <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="feather feather-users"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path><circle cx="9" cy="7" r="4"></circle><path d="M23 21v-2a4 4 0 0 0-3-3.87"></path><path d="M16 3.13a4 4 0 0 1 0 7.75"></path></svg>
              Media Stats
            </a>
          </li>
          <li class="nav-item">
            <a class="nav-link" href="##">
              <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="feather feather-bar-chart-2"><line x1="18" y1="20" x2="18" y2="10"></line><line x1="12" y1="20" x2="12" y2="4"></line><line x1="6" y1="20" x2="6" y2="14"></line></svg>
              Georeferencing Stats
            </a>
          </li>
          <li class="nav-item">
            <a class="nav-link" href="##">
              <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="feather feather-layers"><polygon points="12 2 2 7 12 12 22 7 12 2"></polygon><polyline points="2 17 12 22 22 17"></polyline><polyline points="2 12 12 17 22 12"></polyline></svg>
              Publications
            </a>
          </li>
			<li class="nav-item">
            <a class="nav-link" href="##">
              <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="feather feather-layers"><polygon points="12 2 2 7 12 12 22 7 12 2"></polygon><polyline points="2 17 12 22 22 17"></polyline><polyline points="2 12 12 17 22 12"></polyline></svg>
             Visits
            </a>
          </li>
        </ul>

        <h6 class="sidebar-heading d-flex justify-content-between align-items-center px-3 mt-4 mb-1 text-muted">
          <span>Saved reports</span>
          <a class="d-flex align-items-center text-muted" href="##" aria-label="Add a new report">
            <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="feather feather-plus-circle"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="8" x2="12" y2="16"></line><line x1="8" y1="12" x2="16" y2="12"></line></svg>
          </a>
        </h6>
        <ul class="nav flex-column mb-2">
          <li class="nav-item">
            <a class="nav-link" href="##">
              <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="feather feather-file-text"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path><polyline points="14 2 14 8 20 8"></polyline><line x1="16" y1="13" x2="8" y2="13"></line><line x1="16" y1="17" x2="8" y2="17"></line><polyline points="10 9 9 9 8 9"></polyline></svg>
              Current month
            </a>
          </li>
          <li class="nav-item">
            <a class="nav-link" href="##">
              <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="feather feather-file-text"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path><polyline points="14 2 14 8 20 8"></polyline><line x1="16" y1="13" x2="8" y2="13"></line><line x1="16" y1="17" x2="8" y2="17"></line><polyline points="10 9 9 9 8 9"></polyline></svg>
              Last quarter
            </a>
          </li>
          <li class="nav-item">
            <a class="nav-link" href="##">
              <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="feather feather-file-text"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path><polyline points="14 2 14 8 20 8"></polyline><line x1="16" y1="13" x2="8" y2="13"></line><line x1="16" y1="17" x2="8" y2="17"></line><polyline points="10 9 9 9 8 9"></polyline></svg>
              Prior Years
            </a>
          </li>
        </ul>
      </div>
    </nav>

    <main role="main" class="col-md-9 ml-sm-auto col-lg-10 px-md-4"><div class="chartjs-size-monitor" style="position: absolute; inset: 0px; overflow: hidden; pointer-events: none; visibility: hidden; z-index: -1;"><div class="chartjs-size-monitor-expand" style="position:absolute;left:0;top:0;right:0;bottom:0;overflow:hidden;pointer-events:none;visibility:hidden;z-index:-1;"><div style="position:absolute;width:1000000px;height:1000000px;left:0;top:0"></div></div><div class="chartjs-size-monitor-shrink" style="position:absolute;left:0;top:0;right:0;bottom:0;overflow:hidden;pointer-events:none;visibility:hidden;z-index:-1;"><div style="position:absolute;width:200%;height:200%;left:0; top:0"></div></div></div>
      <div class="d-flex justify-content-between flex-wrap flex-md-nowrap align-items-center pt-3 pb-2 mb-3 border-bottom">
        <h1 class="h2">Dashboard</h1>
        <div class="btn-toolbar mb-2 mb-md-0">
          <div class="btn-group mr-2">
            <button type="button" class="btn btn-sm btn-outline-secondary">Share</button>
            <button type="button" class="btn btn-sm btn-outline-secondary">Export</button>
          </div>
          <button type="button" class="btn btn-sm btn-outline-secondary dropdown-toggle">
            <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="feather feather-calendar"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect><line x1="16" y1="2" x2="16" y2="6"></line><line x1="8" y1="2" x2="8" y2="6"></line><line x1="3" y1="10" x2="21" y2="10"></line></svg>
            This week
          </button>
        </div>
      </div>

      <img class="my-4 w-100 chartjs-render-monitor" src="/metrics/images/downloadChart.png" width="1610" height="678" style="display: block; width: 805px; height: 339px;"/>
<div class="w-100">
	<h2>Collections Record Counts</h2>
	<h3 class="float-left">New Acquisitions</h3>
	<div class="dropdown float-right">
	<button class="btn btn-xs btn-primary dropdown-toggle mb-2" type="button" data-toggle="dropdown">Select Report
	<span class="caret"></span></button>
	<div class="dropdown-menu">
		<a class="dropdown-item" href="##">Holdings</a>
		<a class="dropdown-item" href="##">New Acquisitions</a></li>
		<a class="dropdown-item" href="##">Loan Stats</a></li>
		<a class="dropdown-item" href="##">Holdings</a></li>
		<a class="dropdown-item" href="##">New Acquisitions</a></li>
		<a class="dropdown-item" href="##">Loan Stats</a></li>
	</div>
</div>

	<div class="table-responsive">
		<table class="table table-striped table-sm">
			<thead>
				<tr>
					<th>Collection</th>
					<th>Acquired Cataloged Items in FY</th>
					<th>Acquired Specimens in FY</th>
					<th>New Records Entered in MCZbase in FY - Cataloged Items</th>
					<th>Number of Genetic Samples added to Cryogenetic Facility in FY</th>
					<th>Number of Cataloged Items with NCBI numbers</th>
					<th>Number of NCBI numbers added in FY</th>
					<th>Number of Accessions in FY</th>
					<th>Number of Accessions - Items not Cataloged at end of this FY  (reported by collection)</th>
				</tr>
			</thead>
				<tbody>
					<tr>
						<td>Cryo</td>
						<td>997</td>
						<td>1649</td>
						<td>1000</td>
						<td>0</td>
						<td>242</td>
						<td>14</td>
						<td>NA</td>
						<td>NA</td>
					</tr>
					<tr>
						<td>Ent</td>
						<td>409</td>
						<td>416</td>
						<td>26531</td>
						<td>37</td>
						<td>77</td>
						<td>0</td>
						<td>17</td>
						<td>15000</td>
					</tr>
					<tr>
						<td>Herp</td>
						<td>521</td>
						<td>1245</td>
						<td>1550</td>
						<td>4271</td>
						<td>972</td>
						<td>17</td>
						<td>9</td>
						<td>10</td>
					</tr>
					<tr>
						<td>HerpOBS</td>
						<td>521</td>
						<td>1245</td>
						<td>1550</td>
						<td>4271</td>
						<td>972</td>
						<td>17</td>
						<td>9</td>
						<td>10</td>
					</tr>
					<tr>
						<td>Ich</td>
						<td>81</td>
						<td>123</td>
						<td>936</td>
						<td>1296</td>
						<td>487</td>
						<td>0</td>
						<td>11</td>
						<td>4</td>
					</tr>
					<tr>
						<td>IP</td>
						<td>81</td>
						<td>123</td>
						<td>936</td>
						<td>1296</td>
						<td>487</td>
						<td>0</td>
						<td>11</td>
						<td>4</td>
					</tr>
					<tr>
						<td>IZ</td>
						<td>81</td>
						<td>123</td>
						<td>936</td>
						<td>1296</td>
						<td>487</td>
						<td>0</td>
						<td>11</td>
						<td>4</td>
					</tr>
					<tr>
						<td>Mala</td>
						<td>81</td>
						<td>123</td>
						<td>936</td>
						<td>1296</td>
						<td>487</td>
						<td>0</td>
						<td>11</td>
						<td>4</td>
					</tr>
					<tr>
						<td>Mamm</td>
						<td>81</td>
						<td>123</td>
						<td>936</td>
						<td>1296</td>
						<td>487</td>
						<td>0</td>
						<td>11</td>
						<td>4</td>
					</tr>
					<tr>
						<td>Orn</td>
						<td>81</td>
						<td>123</td>
						<td>936</td>
						<td>1296</td>
						<td>487</td>
						<td>0</td>
						<td>11</td>
						<td>4</td>
					</tr>
					<tr>
						<td>SC</td>
						<td>81</td>
						<td>123</td>
						<td>936</td>
						<td>1296</td>
						<td>487</td>
						<td>0</td>
						<td>11</td>
						<td>4</td>
					</tr>
					<tr>
						<td>VP</td>
						<td>9000</td>
						<td>51.36%</td>
						<td>936</td>
						<td>1296</td>
						<td>487</td>
						<td>0</td>
						<td>11</td>
						<td>4</td>
					</tr>
				</tbody>
			</table>
		</div>
	</main>
</div>
</div>
</cfoutput>
<cfinclude template="/shared/_footer.cfm">
