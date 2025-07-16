<!---
info/slacker.cfm selected data use problem reports

Copyright 2019-2022 President and Fellows of Harvard College

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
<cfset pageTitle="Suspect Data Reports">
<cfinclude template="/shared/_header.cfm">

<cfset var action = "">
<cfif not isDefined("url.action")>
	<cfset local.action = "entryPoint">
<cfelse>
	<cfset local.action = url.action>
</cfif>

<main class=”container” id=”content”>
	<section class=”row” >

		<cfswitch expression="#local.action#">
			<cfcase value="entryPoint">
				<cfoutput>
					<h2 class="h2">Selected Suspect Data Reports</h2>
					<a href="slacker.cfm?action=pubNoAuth">Publications without Authors</a>
					<br><a href="slacker.cfm?action=pubNoCit">Publications without Citations</a>
					<br><a href="slacker.cfm?action=projNoCit">Projects with Loans and without Publications</a>	
					<br><a href="slacker.cfm?action=loanNoSpec">Loans without Specimens</a>
				</cfoutput>
			</cfcase>
			<cfcase value="pubNoAuth">
				<cfquery name="data" datasource="uam_god">
					select 
						publication_id,
						publication_type
					from 
						publication 
					where 
						publication_id not in (select publication_id from publication_author_name )
				</cfquery>
				<cfoutput>
					<h2 class="h2">Publications with no Authors</h2>
					<cfset i=1>
					<cfloop query="data">
						<a href="/publications/Publication.cfm?publication_id=#publication_id#">#publication_type#: #publication_id#</a>
						<br>
						<cfset i=i+1>
					</cfloop>
				</cfoutput>
			</cfcase>
			<cfcase value="pubNoCit">
				<cfquery name="data" datasource="uam_god">
					SELECT 
						publication_id,
						formatted_publication 
					FROM 
						formatted_publication
					WHERE
						publication_id not in ( select publication_id from citation )
					ORDER by
						formatted_publication
				</cfquery>
				<cfoutput>
					<h2 class="h2">Publications with no Citations</h2>
					<cfset i=1>
					<cfloop query="data">
						<div #iif(i MOD 2,DE("class='evenRow'"),DE("class='oddRow'"))#>
							<p class="indent">
								#formatted_publication#
								<br>
								<a href="/publications/showPublication.cfm?publication_id=#publication_id#">Details (This link may not work. These data are suspect. That's why they're here.)</a>
								<br>
								<a href="/publications/Publication.cfm?publication_id=#publication_id#">Edit Publication</a>
							</p>
						</div>
						<cfset i=i+1>
					</cfloop>
				</cfoutput>
			</cfcase>
			<cfcase value="projNoCit">
				<cfquery name="data" datasource="uam_god">
					SELECT 
						project_id,
						project_name
					FROM 
						project 
					WHERE 
						project_id in (
							SELECT project_id 
							FROM 
								project_trans 
								join loan on project_trans.transaction_id=loan.transaction_id
							WHERE
								project_id not in ( select project_id from project_publication)
						)
					ORDER BY project_name
				</cfquery>
				<cfoutput>
					<h2 class="h2">Projects with Loans and without Publications</h2>
					<cfset i=1>
					<cfloop query="data">
						<div #iif(i MOD 2,DE("class='evenRow'"),DE("class='oddRow'"))#>
							<p class="indent">
								#project_name#
								<br>
								<a href="/ProjectDetail.cfm?project_id=#project_id#">Project Details</a>
								<br>
								<a href="/Project.cfm?action=editProject&project_id=#project_id#">Edit Project</a>
							</p>
						</div>
						<cfset i=i+1>
					</cfloop>
				</cfoutput>
			</cfcase>
			<cfcase value="projCounts">
				<cfquery name="data" datasource="uam_god">
					SELECT 
						count(accn.transaction_id) accession_ct,
						count(loan.transaction_id) loan_ct, 
						count(project_publication.publication_id) publication_ct,
						project.project_id,
						project_name
					FROM 
						project 
						left join project_trans on project.project_id = project_trans.project_id
						left join loan on project_trans.transaction_id = loan.transaction_id
						left join project_publication on project.project_id = project_publication.project_id 
						left join accn on project_trans.transaction_id = accn.transaction_id
					GROUP BY project.project_id, project_name
					ORDER BY project_name
				</cfquery>
				<cfoutput>
					<h2 class="h2">Counts of Transactions and Publications per Project</h2>
					<table>
						<thead>
							<tr>
								<th>Accession Count</th>
								<th>Loan Count</th>
								<th>Publication Count</th>
								<th>Project Name</th>
								<th>Links</th>
							</tr>
						</thead>
						<tbody>
						<cfloop query="data">
							<tr>
								<td>#accession_ct#</td>
								<td>#loan_ct#</td>
								<td>#publication_ct#</td>
								<td>#project_name#</td>
								<td>
									<a href="/ProjectDetail.cfm?project_id=#project_id#">Project Details</a>
									<a href="/Project.cfm?action=editProject&project_id=#project_id#">Edit Project</a>
								</td>
							</tr>
						</cfloop>
						</tbody>
					</table>
				</cfoutput>
			</cfcase>
			<cfcase value="loanNoSpec">
				<!--- TODO: Should be supported in transactions search --->
				<cfquery name="data" datasource="uam_god">
					SELECT 
						collection,loan_number,loan.transaction_id
					FROM
						loan
						join trans on loan.transaction_id=trans.transaction_id
						join collection on trans.collection_id=collection.collection_id
					WHERE
						trans.transaction_id not in (select transaction_id from loan_item)
					ORDER BY collection,loan_number
				</cfquery>
				<cfoutput>
					<h2 class="h2">Loans without Specimens</h2>
					<cfset i=1>
					<cfloop query="data">
						<br><a href="/transactions/Loan.cfm?action=editLoan&transaction_id=#transaction_id#">#collection# #loan_number#</a>
					</cfloop>
				</cfoutput>
			</cfcase>
		</cfswitch>
		
	</section>
</main>

<cfinclude template="/shared/_footer.cfm">
