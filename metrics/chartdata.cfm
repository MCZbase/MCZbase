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
<cfquery dbtype = "query" name = "DeptSalaries">
SELECT
Dept_Name,
SUM(Salary) AS SumByDept,
AVG(Salary) AS AvgByDept
FROM GetSalaries
GROUP BY Dept_Name
</cfquery>

<!--- Reformat the generated numbers to show only thousands. --->
<cfloop index="i" from="1" to="#DeptSalaries.RecordCount#">
<cfset DeptSalaries.SumByDept[i]=Round(DeptSalaries.SumByDept[i]/
1000)*1000>
<cfset DeptSalaries.AvgByDept[i]=Round(DeptSalaries.AvgByDept[i]/
1000)*1000>
</cfloop>
	
	
<cfinclude template="/shared/_footer.cfm">
