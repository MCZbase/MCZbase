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


<cfset pageTitle="Agent Activity | Metrics">
<cfinclude template="/shared/_header.cfm">

<!---  These must match the values in ScheduledTasks/runRAgentMetrics.cfm --->
<cfset targetFile = "agent_activity_counts.csv">
<cfset filePath = "/metrics/datafiles/">

<cfoutput>
	<div class="container-fluid">
		<h1 class="h2 pl-3 pt-2 mt-2 mb-0">Visualization of Agent activity by type of task (role)</h1>
		<div class="row">
			<div class="col-12 px-0">
				<!--- chart created by R script /metrics/R/agent_activity_counts.R --->
				<img src="/metrics/datafiles/Agent_Activity.svg" width="100%" alt="Stacked bar chart for agent roles arranged by activity in MCZbase; x-axis are agents in descending order, y-axis are activity counts 0-100,000 on main chart for each role labeled in the legend; the agents with the most activity are off the main chart to the right with higher y-axis count labels (100,001 to over 800,000)"/>
				<div class="px-5 mx-auto mb-3">
					<p class="mx-3" style="margin-top:-2%;">This stacked bar chart displays the database activity for each agent, focusing on those with more than 3,500 total actions.  A few agents have very large numbers of actions, these appear in the outlier plot to the right, where the agent must have exceeded 100,000 actions. This visualization highlights the variability in the types of actions that people carry out in the database, that is variability in each agent&##39;s role. Much of the variation in activity is attributed to the specific needs of the collections, rather than reflecting the individual effort of staff members.  Substantial curatorial effort involves physical activity in the collections, which is not not captured here, and different tasks involve very different amounts of time and effort per action recorded in the database. For example, an agent responsible for identifying specimens (a time consuming task) and organizing specimens for researchers (a physical activity with few changes in the database), are likely be relatively small compared to those of another employee whose primary role is rapid capture of specimen records.</p>
				</div>
			</div>
		</div>
		
		<!---Used during development--->
		<cfif isdefined("session.roles") AND listfindnocase(session.roles,"global_admin")>
			<div class="row mx-0">
				<div class="col-12 px-5 mx-auto">
					<p class="h4 my-2">Data Visualization: <a href="#filePath##targetFile#">Agent Activity Data <img src="/images/linkOut.gif"/></a></p>
				</div>
			</div>
		</cfif>
		
	</div>	

</cfoutput>
<cfinclude template="/shared/_footer.cfm">
