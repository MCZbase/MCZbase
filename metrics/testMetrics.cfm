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
SELECT coll_obj_disposition, sum(coll_object.LOT_COUNT) as "LOT_COUNT"
FROM coll_object, specimen_part, cataloged_item where specimen_part.derived_from_cat_item =coll_object.collection_object_id
and specimen_part.DERIVED_FROM_CAT_ITEM = cataloged_item.COLLECTION_OBJECT_ID
GROUP BY  coll_object.coll_obj_disposition, coll_object.LOT_COUNT
</cfquery>
<cfloop query = "lots2">
#coll_obj_disposition#,
	</cfloop>
<cfloop index="i" from="1" to="10">
<cfset lots2.LOT_COUN datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">00>
<SELECT coll_obj_disposition, sum(coll_object.LOT_COUNT) as "LOT_COUNT"
FROM coll_object, specimen_part, cataloged_item where specimen_part.derived_from_cat_item =coll_object.collection_object_id
and specimen_part.DERIVED_FROM_CAT_ITEM = cataloged_item.COLLECTION_OBJECT_ID
GROUP BY  coll_object.coll_obj_disposition, coll_object.LOT_COUNT/cfloop>

<cfchart
chartWidth=400
BackgroundColor="##FFFF00"
show3D="yes">
<cfchartseries>
type="bar"
query="lots2"
valueColumn="lots2.LOT_COUNT"
itemColumn="lots2.coll_obj_disposition"
	</chartseries>
</cfchart>
<br>	
<cfquery name="qEmployee" datasource="cfdocexamples" maxRows="6">
    SELECT FirstName, LastName, Salary FROM EMPLOYEE
</cfquery>
<cfchart format="html" pieslicestyle="solid" chartWidth="600" chartHeight="400">
    <cfchartseries query="qEmployee" type="pie" serieslabel="Salary Details 2016" valuecolumn="Salary" itemcolumn="FirstName">
    </cfchartseries>
</cfchart>


<cfinclude template="/shared/_footer.cfm">
