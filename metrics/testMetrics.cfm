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
	
	
<!---	<cfquery name="types" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select ts.CATEGORY as "CITATION_TYPE",ts.type_status, count(distinct f.collection_object_id) as "NUMBER_CATALOG_ITEMS", count(distinct media_id) as "NUMBER_OF_IMAGES", 
		count(distinct mr.related_primary_key) as "NUMBER_OF_TYPES_WITH_IMAGES", to_char(co.coll_object_entered_date,'YYYY') as "ENTERED_DATE"
		from UNDERSCORE_RELATION u, flat f, citation c, CTCITATION_TYPE_STATUS ts, coll_object co,
		(select * from MEDIA_RELATIONS where MEDIA_RELATIONSHIP = 'shows cataloged_item') mr
		where u.collection_object_id = f.collection_object_id
		and f.COLLECTION_OBJECT_ID=c.COLLECTION_OBJECT_ID
		and c.type_status=ts.TYPE_STATUS
		and mr.RELATED_PRIMARY_KEY(+) = f.collection_object_id
		--and co.coll_object_entered_date >= '01-JAN-23'
		and f.collection_object_id = co.collection_object_id
		and ts.CATEGORY != 'Temp'
		group by ts.type_status, co.coll_object_entered_date, ts.CATEGORY
	</cfquery>

<cfchart
chartWidth=400
BackgroundColor="##FFFF00"
show3D="yes"
>
<cfchartseries
type="area"
query="types"
valueColumn="ts.TYPE_STATUS"
itemColumn="to_char(co.coll_object_entered_date,'YYYY') "
/>
</cfchart>--->
		
<!---<cfquery name="GetSalaries" datasource="cfdocexamples">
SELECT Departmt.Dept_Name,
Employee.StartDate,
Employee.Salary
FROM Departmt, Employee
WHERE Departmt.Dept_ID = Employee.Dept_ID
</cfquery>	--->

<!--- Convert the date to a number for the query to work --->
<!---<cfloop index="i" from="1" to="#GetSalaries.RecordCount#">
<cfset GetSalaries.StartDate[i]=
NumberFormat(DatePart("yyyy", GetSalaries.StartDate[i]) ,9999)>
</cfloop>--->

<!--- Query of Queries for average salary by start year. --->
<cfquery dbtype = "query" name = "types">
SELECT
began_date,
toptypestatus
FROM flat
</cfquery>
<!---	<cfquery name="types" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select ts.CATEGORY as "CITATION_TYPE",ts.type_status, count(distinct f.collection_object_id) as "NUMBER_CATALOG_ITEMS", count(distinct media_id) as "NUMBER_OF_IMAGES", 
		count(distinct mr.related_primary_key) as "NUMBER_OF_TYPES_WITH_IMAGES", to_char(co.coll_object_entered_date,'YYYY') as "ENTERED_DATE"
		from UNDERSCORE_RELATION u, flat f, citation c, CTCITATION_TYPE_STATUS ts, coll_object co,
		(select * from MEDIA_RELATIONS where MEDIA_RELATIONSHIP = 'shows cataloged_item') mr
		where u.collection_object_id = f.collection_object_id
		and f.COLLECTION_OBJECT_ID=c.COLLECTION_OBJECT_ID
		and c.type_status=ts.TYPE_STATUS
		and mr.RELATED_PRIMARY_KEY(+) = f.collection_object_id
		--and co.coll_object_entered_date >= '01-JAN-23'
		and f.collection_object_id = co.collection_object_id
		and ts.CATEGORY != 'Temp'
		group by ts.type_status, co.coll_object_entered_date, ts.CATEGORY
	</cfquery>--->


<!--- Round average salaries to thousands. --->
<!---<cfloop index="i" from="1" to="#types.RecordCount#">
<cfset HireSalaries.AvgByStart[i]=
Round(HireSalaries.AvgByStart[i]/1000)*1000>
</cfloop>--->
	
<cfchart
chartWidth=400
BackgroundColor="##FFFF00"
show3D="yes"
>
<cfchartseries
type="area"
query="types"
itemColumn="Began_date"
/>
</cfchart>
<cfinclude template="/shared/_footer.cfm">
