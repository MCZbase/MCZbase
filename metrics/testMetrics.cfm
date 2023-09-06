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
<cfoutput>
<div id="MetricsLink" class="col-12 col-md-7 col-xl-9 float-left my-0 pt-3 pb-0">
	<cfset theseMetrics= getMetrics()>
	<div id="theseMetrics">
		#theseMetrics#
	</div>
</div>
</cfoutput>
<cfinclude template="/shared/_footer.cfm">
