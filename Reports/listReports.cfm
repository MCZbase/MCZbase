<!---
/Reporter/listReports.cfm

Copyright 2021 President and Fellows of Harvard College

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

--->
<!---
Metadata page with summary information on label reports.
--->
<cfset pageTitle = "Reports">
<cfinclude template = "/shared/_header.cfm">
<script src="/lib/misc/sorttable.js"></script>
	
<!-- Obtain the list of reports -->
<cfquery name="reports" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="reports_result">
	select 
		report_name,
		substr(report_name,instr(report_name,'__')+2) departments,
		nvl(instr(SQL_TEXT,'-- ##limit_part_name##'),0) partnamelimit,
		nvl(instr(SQL_TEXT,'-- ##limit_preserve_method##'),0) preservemethodlimit,
		report_template,
		pre_function,
		report_format,
		SQL_TEXT,
		description  
	from cf_report_sql 
	where report_name not like 'mcz_%' 
	order by report_name
</cfquery>
<!-- Obtain a list of collection codes for which this user has expressed a preference for seeing label reports for -->
<cfquery name="userColls" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="userColls_result">
	SELECT reportprefs 
	FROM cf_users
	WHERE 
		username=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
</cfquery>

<cfoutput>
	<main class="container py-3" id="content">
		<section class="row">
			<div class="col-12">
				<h1 class="h2">Label Reports</h1>
				<p>Reports used to generate labels are accessed through Specimen Search - Manage -> Print any report...</p>
				
				<table border id="labelsTable" class="sortable table table-responsive d-xl-table">
					<tr>
						<th>Department(s)</th>
						<th>Report name</th>
						<th>Description</th>
						<th>Part Limit</th>
						<th>Preserve Limit</th>
						<th>Format</th>
					<tr>
					<cfloop query="reports">
						<cfif partnamelimit GT 0><cfset partLimit = "Yes"><cfelse><cfset partLimit = ""></cfif>
						<cfif preservemethodlimit GT 0><cfset preserveLimit = "Yes"><cfelse><cfset preserveLimit = ""></cfif>
						<tr>
							<td>#departments#</td>
							<td>#report_name#</td>
							<td>#description#</td>
							<td>#partLimit#</td>
							<td>#preserveLimit#</td>
							<td>#report_format#</td>
						</tr>
					</cfloop>
				</table>
			</div>
		</section>
	</main>
</cfoutput>
<cfinclude template = "/shared/_footer.cfm">
