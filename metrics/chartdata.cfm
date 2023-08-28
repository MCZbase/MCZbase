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
<cfquery dbtype = "query" name = "lots">
SELECT
coll_obj_disposition,
AVG(lot_count) AS AvgLot
FROM coll_object 
GROUP BY coll_obj_disposition
</cfquery>

<!--- Round average salaries to thousands. --->
<cfloop index="i" from="1" to="#lots.RecordCount#">
<cfset lots.AvgLot[i]=
Round(lots.AvgLot[i]/1000)*1000>
</cfloop>
<!--- Put new backing functions in scope, so that they can be invoked directly in this page --->
<cfinclude template="/metrics/component/functions.cfc">
<cfquery name="parts" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select lot_count, part_name, preserve_method 
	from specimen_part sp, coll_object co 
	where co.collection_object_id = sp.DERIVED_FROM_CAT_ITEM
</cfquery>

<!--- Reformat the generated numbers to show only thousands. --->
<cfloop index="i" from="1" to="#parts.RecordCount#">
<cfset parts.lot_count[i]=Round(parts.SumByDept[i]/
1000)*1000>
<cfset parts.lot_count[i]=Round(parts.AvgByDept[i]/
1000)*1000>
</cfloop>
<cfchart 
xAxisTitle="Department" 
yAxisTitle="Salary Average" 
> 
<cfchartseries 
type="bar" 
query="parts" 
valueColumn="AvgByDept" 
itemColumn="part_name" 
/> 
</cfchart>	
	
<cfinclude template="/shared/_footer.cfm">
