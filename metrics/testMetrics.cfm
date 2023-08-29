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
	select coll_object.COLL_OBJ_DISPOSITION as "disp", SUM(coll_object.LOT_COUNT) As "lots" from coll_object, specimen_part 
where coll_object.collection_object_id = specimen_part.collection_object_id
group by coll_object.COLL_OBJ_DISPOSITION
</cfquery>
<cfchart
   format="png"
   scalefrom="0"
   scaleto="1200000"
pieslicestyle="solid">
  <cfchartseries
      type="pie"
      serieslabel="Lots by disp"
      seriescolor="blue">
    <cfchartdata item="Jan" value="503100">
    <cfchartdata item="Feb" value="720310">
    <cfchartdata item="Mar" value="688700">
    <cfchartdata item="Apr" value="986500">
    <cfchartdata item="May" value="1063911">
    <cfchartdata item="Jun" value="1125123">
  </cfchartseries>
</cfchart>

<cfinclude template="/shared/_footer.cfm">
