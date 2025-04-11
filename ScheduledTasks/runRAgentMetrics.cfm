<!---  ScheduledTasks/runRAgentMetrics.cfm

Copyright 2024-2025 President and Fellows of Harvard College

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

Scheduled job to obtain agent activity from database and run an R script
on that data to produce a graphic. 

@see: /metrics/R/agent_activity_counts.R file to generate svg graphic
@see: /metrics/AgentRoles.cfm file to display output to users
@see: /metrics/datafiles/Agent_Activity.svg generated graphics file
@see: filePath/targetFile below for data file
--->
<!--- these must match the values in /metrics/AgentRoles.cfm --->
<cfset targetFile = "agent_activity_counts.csv">
<cfset filePath = "/metrics/datafiles/">
<cfset debug = false>
<!--- obtain pre-built table of agent activity from database --->
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
<!--- store it as a csv file --->
<cfset csv = queryToCSV(getStats)> 
<cffile action="write" file="/#application.webDirectory##filePath##targetFile#" output = "#csv#" addnewline="No">
<!--- Run R script to read this file and write out an svg graphic file --->
<cftry>
	<cfexecute name = "/usr/bin/Rscript" 
		arguments = "/#application.webDirectory#/metrics/R/agent_activity_counts.R" 
		variable = "chartOutput"
		timeout = "10000"
		errorVariable = "chartError"> 
	</cfexecute>
<cfcatch>
	<h3>Error executing R to generate chart</h3>
	<cfdump var="#cfcatch#">
	<cfset chartOutput = "">
	<cfset errorVariable="">
</cfcatch>
</cftry>
<cfif debug>
	<cfoutput>
		<cfif len(#chartOutput#) gt 0>
			<div>
				Script output: [#chartOutput#]
			</div>
		</cfif>
		<cfif len(#chartError#) gt 0>
			<div>
				Script errors: [#chartError#]
			</div>
		</cfif>
	</cfoutput>
</cfif>
