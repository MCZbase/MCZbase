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
<cfquery name="lot" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="lot_result">
	select coll_object.COLL_OBJ_DISPOSITION, coll_object.LOT_COUNT from coll_object

</cfquery>
<cfquery dbtype = "query" name = "DataTable"> 
SELECT 
COLL_OBJ_DISPOSITION, 
AVG(LOT_COUNT) AS avgLot, 
SUM(LOT_COUNT) AS sumLot 
FROM lot 
GROUP BY COLL_OBJ_DISPOSITION 
	where sumLot <= 1000
</cfquery> 
	
<cfloop index = "i" from = "1" to = "1000> 
<cfset DataTable.sumLot[i] = Round(DataTable.sumLot[i]/1000)*1000> 
<cfset DataTable.avgLot[i] = Round(DataTable.avgLot[i]/1000)*1000> 
</cfloop> 
	
<cfchart format="png" 
xaxistitle="Disposition" 
yaxistitle="Lot Sum"> 

<cfchartseries type="bar" 
query="DataTable" 
itemcolumn="COLL_OBJ_DISPOSITION" 
valuecolumn="sumLot" /> 
</cfchart>

<cfinclude template="/shared/_footer.cfm">
