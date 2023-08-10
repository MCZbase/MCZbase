<!--

* /hello/World.cfm

Copyright 2022 President and Fellows of Harvard College

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
	<!--- Script includes are normally in shared/_header.cfm, but in one-off non-reused, can be in the page --->
<script type="text/javascript" src="/metrics/js/metrics.js"></script>

<!--- Put the getCounterHtml function in scope, so that it can be invoked directly in this page --->
<cfinclude template="/metrics/component/functions.cfc">
	
	
<cfinclude template="/shared/_footer.cfm">