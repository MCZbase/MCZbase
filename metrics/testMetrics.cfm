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
   format="png"
   scalefrom="0"
   scaleto="1200000">
  <cfchartseries
      type="bar"
      serieslabel="Website Traffic 2006"
      seriescolor="blue">
    <cfchartdata item="January" value="503100">
    <cfchartdata item="February" value="720310">
    <cfchartdata item="March" value="688700">
    <cfchartdata item="April" value="986500">
    <cfchartdata item="May" value="1063911">
    <cfchartdata item="June" value="1125123">
  </cfchartseries>
</cfchart>


<cfinclude template="/shared/_footer.cfm">
