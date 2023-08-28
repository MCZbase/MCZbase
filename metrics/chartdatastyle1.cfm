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


<cfchart
scaleFrom=40000
scaleTo=100000
font="arial"
fontSize=16
gridLines=4
show3D="yes"
foregroundcolor="##000066"
databackgroundcolor="##FFFFCC"
chartwidth="450"
>

<cfchartseries
type="bar"
query="DeptSalaries"
valueColumn="AvgByDept"
itemColumn="Dept_Name"
seriescolor="##33CC99"
paintstyle="shade"
/>

</cfchart>	
	
	
<cfinclude template="/shared/_footer.cfm">
