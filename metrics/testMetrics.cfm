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
	
<cfquery name = "lots2" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
SELECT coll_object.coll_obj_disposition, AVG(lot_count) AS "AvgLot", lot_count, coll_object.coll_object_entered_date
FROM coll_object, specimen_part where specimen_part.derived_from_cat_item =coll_object.collection_object_id
GROUP BY coll_object.coll_object_entered_date, coll_object.coll_obj_disposition
</cfquery>
	
<!--- Round average salaries to thousands. --->
<cfloop index="i" from="1" to="#lots2.RecordCount#">
<cfset lots2.AvgLot[i]=
Round(lots2.AvgLot[i]/1000)*1000>
</cfloop>

<cfchart
chartWidth=400
BackgroundColor="##FFFF00"
show3D="yes">
<cfchartseries
type="area"
query="lots2"
valueColumn="lots2.AvgLot"
itemColumn="lots2.lot_count"/>
</cfchart>
<br>	
	
	
<cfinclude template="/shared/_footer.cfm">
