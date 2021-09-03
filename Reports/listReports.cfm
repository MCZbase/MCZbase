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
		report_id,
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
		and report_name like '%\_\_%'
		escape '\'
	order by report_name
</cfquery>
<!-- Obtain a list of collection codes for which this user has expressed a preference for seeing label reports for -->
<cfquery name="userColls" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="userColls_result">
	SELECT reportprefs 
	FROM cf_users
	WHERE 
		username=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
</cfquery>
<cfset collList = []>
<cfloop query="userColls">
	<cfset collList = ListToArray(userColls.reportprefs,',')>
</cfloop>
<cfset added = ArrayPrepend(collList,"All") >

<cfoutput>
	<main class="container py-3" id="content">
		<section class="row">
			<div class="col-12">
				<h1 class="h2">Label Reports</h1>
				<p>Reports used to generate labels are accessed through Specimen Search - Manage -> Print any report...</p>
				<p>Department lists the department or department for which the reports were designed.  Shown indicates whether a particular report will be shown to you on the Print any report page by default, or if you need to click through the Show All Reports link at the bottom of that page to access that report.  The list of collections for which reports can be seen is configured for each user, if you or another user do not have Shown="By Default" for the desired set of labels, please file a bug report for the user and the desired list of collections.  Use is a guideline, though many Fluid reports will not produce labels for Dry specimens.  Every report has a different set of conditions and assumptions, these are spelled out in the Description.  Pay careful note to highlighted information, particularly cases where labels will not work as might be expected for types.  Part limit and Preserve limit note reports that can be filtered to produced labels for only particular part types or preservation methods, if you would like these limits added to a report that does not have them, please file a bug report.</p>
				
				<table border id="labelsTable" class="sortable table table-responsive d-xl-table">
					<thead class="thead-light">
					<tr>
						<th>Department(s)</th>
						<th>Shown</th>
						<th>Report name</th>
						<th>Description</th>
						<th>Use</th>
						<th>Part Limit</th>
						<th>Preserve Limit</th>
						<th>Format</th>
					</tr>
					</thead>
					<tbody>
					<cfloop query="reports">
						<cfif partnamelimit GT 0><cfset partLimit = "Yes"><cfelse><cfset partLimit = ""></cfif>
						<cfif preservemethodlimit GT 0><cfset preserveLimit = "Yes"><cfelse><cfset preserveLimit = ""></cfif>
						<cfset departmentsArray = ListToArray(departments,'_')>
						<cfset highlight="">
						<!---  If the report name includes a collection code in the user's list, then note that it is shown. --->
						<cfloop index="element" array="#departmentsArray#">
							<cfloop index="cel" array="#collList#">
								<cfif cel EQ element >
									<cfset highlight = "yes" >
								</cfif>
							</cfloop>
						</cfloop>
						<tr>
							<cfif highlight EQ "yes">
								<td><strong>#replace(departments,'_',', ')#</strong></td>
							<cfelse>
								<td>#replace(departments,'_',',')#</td>
							</cfif>
							<cfif highlight EQ "yes" OR len(userColls.reportprefs) EQ 0>
								<td>By Default</td>
							<cfelse>
								<td>No</td>
							</cfif>
							<td>
								<!--- TODO: Need role for editing reports --->
								<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"global_admin")>
									<a href="/Reports/reporter.cfm?action=edit&report_id=#report_id#" target="_blank">#report_name#</a>
								<cfelse>
									#report_name#
								</cfif>
							</td>
							<td>#description#</td>
							<td>
								#left(report_name,find('_',report_name)-1)#
							</td>
							<td>#partLimit#</td>
							<td>#preserveLimit#</td>
							<td>#report_format#</td>
						</tr>
					</cfloop>
					</tbody>
				</table>
			</div>
		</section>
	</main>
</cfoutput>
<cfinclude template = "/shared/_footer.cfm">
