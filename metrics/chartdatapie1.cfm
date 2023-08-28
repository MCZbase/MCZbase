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
<!--- TODO: Move inclusion to shared/_header.cfm --->
<script type="text/javascript" src="/metrics/js/metrics.js"></script>

<!--- existing metrics/activity function --->
<cfinclude template="/info/component/activity.cfc">

<!--- Put new backing functions in scope, so that they can be invoked directly in this page --->
<cfinclude template="/metrics/component/functions.cfc">

<cfinclude template="/metrics/component/chartdata.cfm">
<cfchart
tipStyle="mousedown"
font="Times"
fontsize=14
fontBold="yes"
backgroundColor = "##CCFFFF"
show3D="yes"
>

<cfchartseries
type="pie"
query="DeptSalaries"
valueColumn="SumByDept"
itemColumn="Dept_Name"
colorlist="##6666FF,##66FF66,##FF6666,##66CCCC"
/>
</cfchart>
<br>
	
	
<cfinclude template="/shared/_footer.cfm">
