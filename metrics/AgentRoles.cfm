<!---

* /metrics/AgentRoles.cfm

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

* Page to display graphic of user activity metrics.

@see: /ScheduledTasks/runRAgentMetrics.cfm
@see: /metrics/R/agent_activity_counts.R
* /metrics/AgentRoles.cfm

--->


<cfset pageTitle="Agent Roles | Metrics">
<cfinclude template="/shared/_header.cfm">

<!---  These must match the values in ScheduledTasks/runRAgentMetrics.cfm --->
<cfset targetFile = "agent_activity_counts.csv">
<cfset filePath = "/metrics/datafiles/">

<cfoutput>
	<div class="container-fluid">

		<div class="row">
			
			<div class="col-12 px-0">
				<!--- chart created by R script /metrics/R/agent_activity_counts.R --->
				<img src="/metrics/datafiles/Agent_Activity.svg" width="95%" alt="Stacked bar chart for agent roles arranged by activity in MCZbase; x-axis are agents in descending order, y-axis are activity counts 0-100,000 on main chart for each role labeled in the legend; the agents with the most activity are off the main chart to the right with higher y-axis count labels (100,001 to over 800,000)"/>
			</div>
		</div>
		
		<!---Used during development--->
		<cfif isdefined("session.roles") AND listfindnocase(session.roles,"global_admin")>
			<div class="row mx-0">
				<div class="col-12">
					<h1 class="h4 my-2">Data Visualization: <a href="#filePath##targetFile#">Agent Activity Data <img src="/images/linkOut.gif"/></a></h1>
				</div>
			</div>
		</cfif>
	</div>	

</cfoutput>
<cfinclude template="/shared/_footer.cfm">
