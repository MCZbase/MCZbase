<!--

* /metrics/testMetrics.cfm

Copyright 2024 President and Fellows of Harvard College

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

* Dashboard for obtaining annual reporting and other collections metrics.

-->


<cfset pageTitle="Agent Roles | Metrics">
<cfinclude template="/shared/_header.cfm">
<cfinclude template = "/shared/component/functions.cfc">

<cfset targetFile = "agent_activity_counts.csv">
<cfset filePath = "/metrics/datafiles/">
	
<cfquery name="getStats" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">	
	select distinct agent_id, agent_name, table_name, column_name, count 
	from mczbase.cf_temp_agent_role_summary 
	where agent_id <> 0 
	and agent_id <> 9734 
	and agent_id <> 102573 
	and agent_id <> 104339 
	and column_name <> 'PERSON_ID'
	group by agent_id, agent_name, table_name, column_name, count
</cfquery>
<cfquery name="getLabels" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">	
	UPDATE getStats  
	SET label = CASE
	WHEN CONSTRAINT_NAME = 'FK_IDAGENT_AGENT' THEN 'Identified Spec.'
	WHEN CONSTRAINT_NAME = 'FK_LATLONG_AGENT' THEN 'Created Georef.'
	WHEN CONSTRAINT_NAME = 'FK_LATLONG_VERIFIEDBY' THEN 'Verified Georef.'
	WHEN CONSTRAINT_NAME = 'FK_MEDIARELNS_AGENT' THEN 'Created Media'
	WHEN CONSTRAINT_NAME = 'FK_DEACC_ITEM_RECONCILED_AGENT' THEN 'Reconciled Deacc.'
	WHEN CONSTRAINT_NAME = 'FK_ENCUMB_AGENT' THEN 'Encumbered Spec.'
	WHEN CONSTRAINT_NAME = 'FK_PERMIT_CONTACTAGENT' THEN 'Tracked Permit'
	WHEN CONSTRAINT_NAME = 'FK_UNDERSCORE_AGENT_ID' THEN 'Created NamedGroup'
	WHEN CONSTRAINT_NAME = 'FK_SHIPMENT_PACKED_BY' THEN 'Shipped Spec.'
	WHEN CONSTRAINT_NAME = 'FK_COLL_OBJECT_EDITED_AGENT' THEN 'Edited Spec.'
	WHEN CONSTRAINT_NAME = 'FK_COLL_OBJECT_ENTERED_AGENT' THEN 'Entered Spec.'
	WHEN CONSTRAINT_NAME = 'FK_COLLECTOR_AGENT' THEN 'Collected Spec.'
	WHEN CONSTRAINT_NAME = 'FK_ATTRIBUTES_AGENT' THEN 'Created Attribute'
	WHEN CONSTRAINT_NAME = 'LOAN_ITEM_FK1' THEN 'Created Loan'
	WHEN CONSTRAINT_NAME = 'FK_DETERMINER_AGENT' THEN 'Determined Geology Att.'
	group by agent_id, agent_name, table_name, column_name, count
</cfquery>
<cfoutput>
<cfset csv = queryToCSV(getStats)> 
<cffile action="write" file="/#application.webDirectory##filePath##targetFile#" output = "#csv#" addnewline="No">
</cfoutput>

<cftry>
	<cfexecute name = "/usr/bin/Rscript" 
		arguments = "/#application.webDirectory#/metrics/R/agent_activity_counts.R" 
		variable = "chartOutput"
		timeout = "10000"
		errorVariable = "chartError"> 
	</cfexecute>
<cfcatch>
	<h3>Error loading chart</h3>
	<cfdump var="#cfcatch#">
	<cfset chartOutput = "">
	<cfset errorVariable="">
</cfcatch>
</cftry>
<cfoutput>
	<div class="container-fluid">
		<div class="row mx-0">
			<h1 class="h3 mt-3">Data Visualization: Agent Activity</h1>
			<div class="col-12">
				<p>Data <a href="#filePath##targetFile#">download table</a>. Stacked barchart with outlier y-axis showing greater than 100,000 total counts (instances of agent activity).</p>
			</div>
		</div>
		<div class="row">
			
			<div class="col-12 px-0">
				<!--- chart created by R script --->
				<img src="/metrics/R/Agent_Activity.svg" width="100%"/>
			</div>
		</div>
		<cfif len(#chartOutput#) gt 0>
			<div class="col-12">
				Script output: [#chartOutput#]
			</div>
		</cfif>
<!---		<cfif len(#chartError#) gt 0>
			<div class="col-12 my-3 border py-2">
				Script errors: [#chartError#]
			</div>
		</cfif>--->
	</div>	
	
</cfoutput>
<cfinclude template="/shared/_footer.cfm">