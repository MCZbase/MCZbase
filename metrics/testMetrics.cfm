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
<cfinclude template = "/shared/component/functions.cfc">
<cfquery name="getStats" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
select f.COLLECTION, ts.CATEGORY as "CITATION_TYPE",ts.type_status, count(distinct f.collection_object_id) as "NUMBER_CATALOG_ITEMS", count(distinct media_id) as "NUMBER_OF_IMAGES", 
count(distinct mr.related_primary_key) as "NUMBER_OF_TYPES_WITH_IMAGES", to_char(co.coll_object_entered_date,'YYYY') as "ENTERED_DATE"
from flat f, citation c, ctcitation_type_status ts, coll_object co,
(select * from media_relations where media_relationship = 'shows cataloged_item') mr
where f.collection_object_id=c.collection_object_id
and c.type_status=ts.type_status
and mr.related_primary_key(+) = f.collection_object_id
and f.collection_object_id = co.collection_object_id
and ts.category != 'Temp'
group by f.collection, ts.type_status, co.coll_object_entered_date, ts.category
</cfquery>
<cfoutput>
<cfset csv = queryToCSV(getStats)> 
<cffile action="write" file="#application.webDirectory#/metrics/R/datafiles/chart_data.csv" output = "#csv#" addnewline="No">
</cfoutput>
<a href="/metrics/R/datafiles/chart_data.csv">download table</a>
<cftry>
	<cfexecute name = "/usr/bin/Rscript" 
		arguments = "/var/www/html/arctos/metrics/R/bubble_graph.R" 
		variable = "chartdata"
		timeout = "10000"> 
	</cfexecute>
	<cfcatch>
		<cfdump var="/metrics/graphs/#chartdata#">
	</cfcatch>

</cftry>
<cfinclude template="/shared/_footer.cfm">
