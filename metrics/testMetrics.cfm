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
	
<cfchart format="html" chartHeight="400" chartWidth="600" showLegend="no" title="Line chart">
<cfchartseries type="line" serieslabel="WBC" markerstyle="circle" color="red">
<cfchartdata item="Day 1" value="19.2"/>
<cfchartdata item="Day 2" value="15.2"/>
<cfchartdata item="Day 3" value="15.1"/>
<cfchartdata item="Day 4" value="12.6"/>
<cfchartdata item="Day 5" value="14.2"/>
</cfchartseries>
</cfchart>

<cfinclude template="/shared/_footer.cfm">
