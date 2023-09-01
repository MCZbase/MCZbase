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
select collection_object_id, lastuser, collection, lastdate, scientific_name, state_prov from mczbase.cf_temp_chart_data
</cfquery>
<cfoutput>
 <cfset csv = queryToCSV(getStats)> 
	 
<cffile action="write" file="#application.webDirectory#/media/datafiles/chart_data.csv" output = "Chart_Data" addnewline="Yes">
</cfoutput>

<cfinclude template="/shared/_footer.cfm">
