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
	select coll_object.COLL_OBJ_DISPOSITION, sum(coll_object.LOT_COUNT) as "lots" from coll_object

</cfquery>


	
<cfchart format="png" 
xaxistitle="Disposition" 
yaxistitle="Lot Sum"> 

<cfchartseries type="bar" 
query="DataTable" 
itemcolumn="COLL_OBJ_DISPOSITION" 
valuecolumn="lots" /> 
</cfchart>

<cfinclude template="/shared/_footer.cfm">
