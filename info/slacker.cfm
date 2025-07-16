<!---
info/slacker.cfm selected data use problem reports

Copyright 2019-2025 President and Fellows of Harvard College

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
<cfset pageTitle="Miscelaneous Suspect Data Reports">
<cfinclude template="/shared/_header.cfm">

<cfset var action = "">
<cfif not isDefined("url.action")>
	<cfset local.action = "entryPoint">
<cfelse>
	<cfset local.action = url.action>
</cfif>

<main class="container-fluid" id="content">
	<div class="row">
		<div class="col-12">

			<cfswitch expression="#local.action#">
				<cfcase value="entryPoint">
					<cfoutput>
						<h1 class="h2">Selected Suspect Data Reports</h1>
						<p>Use these reports to identify and fix miscelaneous potential data quality issues in MCZbase.</p>
						
						<ul>
							<li><a href="/info/slacker.cfm?action=pubNoAuth">Publications without Authors</a></li>
							<li><a href="/info/slacker.cfm?action=pubNoCit">Publications without Citations</a></li>
							<li><a href="/info/slacker.cfm?action=projNoCit">Projects with Loans and without Publications</a></li>
							<li><a href="/info/slacker.cfm?action=projCounts">Counts of Transactions and Publications for Projects</a></li>
							<li><a href="/info/slacker.cfm?action=loanNoSpec">Loans without Specimens</a></li>
						</ul>
					</cfoutput>
				</cfcase>
				<cfcase value="pubNoAuth">
					<cfquery name="data" datasource="uam_god">
						SELECT 
							publication.publication_id,
							publication_type,
							formatted_publication
						FROM 
							publication 
							join formatted_publication on publication.publication_id = formatted_publication.publication_id
								AND formatted_publication.format_style = 'long'
						WHERE 
							publication.publication_id not in (select publication_id from publication_author_name )
						ORDER BY publication_type, formatted_publication, publication.publication_id 
					</cfquery>
					<cfoutput>
						<h1 class="h2">Publications with no Authors</h1>
						<p><a href="/info/slacker.cfm">&laquo; Back to miscelaneous Reports</a></p>
						
						<cfif data.recordcount GT 0>
							<p><strong>#data.recordcount#</strong> publication<cfif data.recordcount NEQ 1>s</cfif> found with no authors.</p>
							
							<div class="table-responsive">
								<table class="table table-striped">
									<thead>
										<tr>
											<th>Publication ID</th>
											<th>Long Citation</th>
											<th>Type</th>
											<th>Actions</th>
										</tr>
									</thead>
									<tbody>
										<cfloop query="data">
											<tr>
												<td>#publication_id#</td>
												<td>#formatted_publication#</td>
												<td>#publication_type#</td>
												<td>
													<a href="/publications/Publication.cfm?publication_id=#publication_id#" class="btn btn-primary btn-sm">Edit</a>
												</td>
											</tr>
										</cfloop>
									</tbody>
								</table>
							</div>
						<cfelse>
							<p class="text-success"><strong>No issues found!</strong> All publications have authors.</p>
						</cfif>
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
							AND format_style = 'long'
						ORDER by
							formatted_publication
					</cfquery>
					<cfoutput>
						<h1 class="h2">Publications with no Citations</h1>
						<p><a href="/info/slacker.cfm">&laquo; Back to miscelaneous Reports</a></p>
						
						<cfif data.recordcount GT 0>
							<p><strong>#data.recordcount#</strong> publication<cfif data.recordcount NEQ 1>s</cfif> found with no citations.</p>
							
							<div class="table-responsive">
								<table class="table table-striped">
									<thead>
										<tr>
											<th>Publication</th>
											<th>Actions</th>
										</tr>
									</thead>
									<tbody>
										<cfloop query="data">
											<tr>
												<td>#formatted_publication#</td>
												<td>
													<a href="/publications/showPublication.cfm?publication_id=#publication_id#" class="btn btn-outline-info btn-sm">Details</a>
													<a href="/publications/Publication.cfm?publication_id=#publication_id#" class="btn btn-primary btn-sm">Edit</a>
												</td>
											</tr>
										</cfloop>
									</tbody>
								</table>
							</div>
						<cfelse>
							<p class="text-success"><strong>No issues found!</strong> All publications have citations.</p>
						</cfif>
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
						<h1 class="h2">Projects with Loans and without Publications</h1>
						<p><a href="/info/slacker.cfm">&laquo; Back to miscelaneous Reports</a></p>
						
						<cfif data.recordcount GT 0>
							<p><strong>#data.recordcount#</strong> project<cfif data.recordcount NEQ 1>s</cfif> found with loans but no publications.</p>
							
							<div class="table-responsive">
								<table class="table table-striped">
									<thead>
										<tr>
											<th>Project Name</th>
											<th>Actions</th>
										</tr>
									</thead>
									<tbody>
										<cfloop query="data">
											<tr>
												<td>#project_name#</td>
												<td>
													<a href="/ProjectDetail.cfm?project_id=#project_id#" class="btn btn-outline-info btn-sm">Details</a>
													<a href="/Project.cfm?action=editProject&project_id=#project_id#" class="btn btn-primary btn-sm">Edit</a>
												</td>
											</tr>
										</cfloop>
									</tbody>
								</table>
							</div>
						<cfelse>
							<p class="text-success"><strong>No issues found!</strong> All projects with loans have associated publications.</p>
						</cfif>
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
						<p><a href="/info/slacker.cfm">&laquo; Back to miscelaneous Reports</a></p>
						<div class="table-responsive">
							<table class="table table-striped">
								<thead>
									<tr>
										<th>Accession Count</th>
										<th>Loan Count</th>
										<th>Publication Count</th>
										<th>Project Name</th>
										<th>Actions</th>
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
												<a href="/ProjectDetail.cfm?project_id=#project_id#" class="btn btn-outline-info btn-sm">Details</a>
												<a href="/Project.cfm?action=editProject&project_id=#project_id#" class="btn btn-primary btn-sm">Edit</a>
											</td>
										</tr>
									</cfloop>
								</tbody>
							</table>
						</div>
					</cfoutput>
				</cfcase>
				<cfcase value="loanNoSpec">
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
						<h1 class="h2">Loans without Specimens</h1>
						<p><a href="/info/slacker.cfm">&laquo; Back to miscelaneous Reports</a></p>
						
						<cfif data.recordcount GT 0>
							<p><strong>#data.recordcount#</strong> loan<cfif data.recordcount NEQ 1>s</cfif> found with no attached cataloged items.</p>
							
							<div class="table-responsive">
								<table class="table table-striped">
									<thead>
										<tr>
											<th>Collection</th>
											<th>Loan Number</th>
											<th>Actions</th>
										</tr>
									</thead>
									<tbody>
										<cfloop query="data">
											<tr>
												<td>#collection#</td>
												<td>#loan_number#</td>
												<td>
													<a href="/transactions/Loan.cfm?action=editLoan&transaction_id=#transaction_id#" class="btn btn-primary btn-sm">Edit</a>
												</td>
											</tr>
										</cfloop>
									</tbody>
								</table>
							</div>
						<cfelse>
							<p class="text-success"><strong>No issues found!</strong> All loans have associated cataloged items.</p>
						</cfif>
					</cfoutput>
				</cfcase>
			</cfswitch>
			
		</div>
	</div>
</main>

<cfinclude template="/shared/_footer.cfm">
