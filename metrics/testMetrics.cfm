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

<cfquery name = "lots1" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
SELECT
coll_object.coll_obj_disposition, coll_object.coll_object_entered_date, flat.began_date
FROM coll_object, flat, specimen_part
	where flat.collection_object_id = coll_object.collection_object_id
	and specimen_part.derived_from_cataloged_item =coll_object.collection_object_id
GROUP BY coll_object.coll_obj_disposition
</cfquery>

<cfloop index="i" from="1" to="#lots1.RecordCount#">
<cfset lots.began_date[i]=
NumberFormat(flat.began_date("yyyy", lots.began_date[i]) ,9999)>
</cfloop>
	
<cfquery name = "lots2" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
SELECT
coll_object.coll_obj_disposition, coll_object.coll_object_entered_date,flat.began_date
AVG(lot_count) AS AvgLot
FROM coll_object, flat, specimen_part
	where flat.collection_object_id = coll_object.collection_object_id
	and specimen_part.derived_from_cataloged_item =coll_object.collection_object_id
GROUP BY coll_object.coll_object_entered_date, coll_object.coll_obj_disposition
</cfquery>
	
<!--- Round average salaries to thousands. --->
<cfloop index="i" from="1" to="#lots.RecordCount#">
<cfset lots.AvgLot[i]=
Round(lots.AvgLot[i]/1000)*1000>
</cfloop>

<cfchart
chartWidth=400
BackgroundColor="##FFFF00"
show3D="yes">
<cfchartseries
type="area"
query="lot2"
valueColumn="coll_object.coll_object_entered_date"
itemColumn="flat.began_date"/>
</cfchart>
<br>	
	
	
<cfinclude template="/shared/_footer.cfm">
