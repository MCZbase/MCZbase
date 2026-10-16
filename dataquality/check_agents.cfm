<!---
dataquality/check_agents.cfm to evaluate agent names against MCZbase agent records

Copyright 2026 President and Fellows of Harvard College

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

Checks a csv list of agent names before a specimen or publication bulkload, reporting
which agent each name matches and whether it is an author, second author, or taxon author
form of that agent's name.  Does not alter the database.
--->
<cfset pageTitle = "Check a list of agent names">

<!--- agent_name_type values the publication loader and taxon authorship depend on --->
<cfset AUTHOR_NAME_TYPE = "author">
<cfset SECOND_AUTHOR_NAME_TYPE = "second author">
<cfset TAXON_AUTHOR_NAME_TYPE = "taxon author">

<!--- used by loadCsvFileSilent and in the cfcatch block --->
<cfset NO_COLUMN_ERR = "The required AGENT_NAME column is missing in the header line of the csv file.">
<cfset NO_HEADER_ERR = "No header line found, csv file appears to be empty.">

<cfparam name="form.action" default="">
<cfset variables.action = form.action>
<cfif len(variables.action) EQ 0>
	<cfset variables.action = "entryPoint">
</cfif>

<!---
Quote a value as one field of a csv line, doubling any embedded quotes.

@param value the value to quote.
@return the value enclosed in double quotes.
--->
<cffunction name="csvField" returntype="string">
	<cfargument name="value" type="string" required="yes">
	<cfreturn '"' & replace(arguments.value, '"', '""', 'all') & '"'>
</cffunction>

<cfswitch expression="#variables.action#">
	<cfcase value="entryPoint">
		<cfinclude template="/shared/_header.cfm">
		<cfinclude template="/tools/component/csv.cfc" runOnce="true">
		<cfoutput>
			<main class="container-fluid py-3 px-xl-5 mb-4" id="content">
				<h1 class="h2 mt-2">Check agent names against MCZbase agent records</h1>
				<section>
					<h2 class="h4 mt-4">Upload a comma-delimited text file (csv) containing an AGENT_NAME column</h2>
					<p>
						This tool checks whether each name exactly matches an agent name in MCZbase, and whether it matches
						exactly one agent.  Any columns other than AGENT_NAME are ignored, and repeated names are checked once.
						For a name that matches exactly one agent it reports the agent_id, the types of the matched name, and whether
						the name is the <strong>author</strong>, <strong>second author</strong>, or <strong>taxon author</strong> form
						of the agent's name, listing the agent's names of those types when the matched name is not one of them.
						For a name that matches more than one agent it lists each agent's preferred name and agent_id.
						The results can be returned as an HTML table or as a CSV file.  This tool does not alter the MCZbase database.
					</p>
					<p>
						Specimen bulkloads match agents (collectors, determiners, and the like) on any form of their name, and a
						name must match exactly one agent.  Publication bulkloads use the first author's name only if it is an
						author form, and the names of the second through seventh authors only if they are second author forms.
						Scientific name authorship is shown from taxon author names.
					</p>
					<p>
						To check names from a bulkload file, copy the agent name columns into a single column headed AGENT_NAME
						in a separate CSV file, and check that file here.
					</p>
					<form name="csvform" method="post" enctype="multipart/form-data" id="checkAgentsForm" action="/dataquality/check_agents.cfm">
						<input type="hidden" name="action" value="checkAgents">
						<fieldset class="my-0 px-2 border-top border-right border-bottom border-left field-set py-2">
							<legend class="h6 mb-0 px-3 border-top border-right border-bottom border-left field-set-legend bg-teal font-weight-bold w-auto">Check Agent Names</legend>
							<div class="form-row">
								<div class="col-12 col-md-4">
									<label for="fileToUpload" class="data-entry-label">File to check:</label>
									<input type="file" name="fileToUpload" id="fileToUpload" class="reqdClr p-0" required>
								</div>
								<div class="col-12 col-md-3">
									<cfset charsetSelect = getCharsetSelectHTML(default="utf-8")>
								</div>
								<div class="col-12 col-md-3">
									<cfset formatSelect = getFormatSelectHTML()>
								</div>
								<div class="col-12 col-md-2">
									<label for="returnAsCSV" class="data-entry-label">Return as:</label>
									<select name="returnAsCSV" id="returnAsCSV" class="data-entry-select reqdClr">
										<option value="html" selected>HTML</option>
										<option value="csv">CSV</option>
									</select>
								</div>
								<div class="col-12 mt-2">
									<input type="submit" value="Check this file" class="btn btn-xs btn-primary">
								</div>
							</div>
						</fieldset>
					</form>
				</section>
			</main>
		</cfoutput>
		<cfinclude template="/shared/_footer.cfm">
	</cfcase>
	<cfcase value="checkAgents">
		<cfparam name="form.fileToUpload" default="">
		<cfparam name="form.format" default="DEFAULT">
		<cfparam name="form.characterSet" default="utf-8">
		<cfparam name="form.returnAsCSV" default="html">
		<cfset variables.fileToUpload = form.fileToUpload>
		<cfset variables.format = form.format>
		<cfset variables.characterSet = form.characterSet>
		<cfset variables.asCsv = false>
		<cfif form.returnAsCSV EQ "csv">
			<cfset variables.asCsv = true>
		</cfif>

		<cfif variables.asCsv>
			<!--- a csv download is returned without the page header, so the header's role check has to run here --->
			<cf_rolecheck>
		<cfelse>
			<cfinclude template="/shared/_header.cfm">
		</cfif>
		<cfinclude template="/tools/component/csv.cfc" runOnce="true">

		<cfset results = ArrayNew(1)>
		<cfset evaluatedNames = ArrayNew(1)>
		<cfset foundCount = 0>
		<cfset ambiguousCount = 0>
		<cfset notFoundCount = 0>
		<cfset errorMessage = "">
		<cfset row = 0>
		<cfset agentName = "">
		<cftry>
			<cfif len(variables.fileToUpload) EQ 0>
				<cfthrow message="No file was uploaded.">
			</cfif>
			<cfset variables.foundHeaders = ""><!--- populated by loadCsvFileSilent --->
			<cfset variables.size = ""><!--- populated by loadCsvFileSilent --->
			<cfset iterator = loadCsvFileSilent(FileToUpload=variables.fileToUpload,format=variables.format,characterSet=variables.characterSet)>
			<!--- columns can only be matched by position, as csvFormat.withHeader() can't be called from coldfusion --->
			<cfset colNameArray = listToArray(ucase(variables.foundHeaders))>
			<cfset agentNamePosition = ArrayFind(colNameArray, "AGENT_NAME")>
			<cfif agentNamePosition EQ 0>
				<cfthrow message="#NO_COLUMN_ERR# Columns found: #variables.foundHeaders#">
			</cfif>
			<cfloop condition="iterator.hasNext()">
				<cfset rowData = iterator.next()>
				<cfset row = row + 1>
				<cfset agentName = "">
				<cfif rowData.size() GTE agentNamePosition>
					<cfset agentName = trim(rowData.get(JavaCast("int", agentNamePosition - 1)))>
				</cfif>
				<!--- ArrayFind is case sensitive, as is the agent name match in the bulkloaders --->
				<cfif len(agentName) GT 0 AND ArrayFind(evaluatedNames, agentName) EQ 0>
					<cfset ArrayAppend(evaluatedNames, agentName)>
					<cfquery name="getMatches" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getMatches_result">
						SELECT
							matched.agent_id,
							agent.agent_type,
							preferred_agent_name.agent_name AS preferred_agent_name,
							matched.name_types,
							(
								SELECT LISTAGG(author_name.agent_name, '; ') WITHIN GROUP (ORDER BY author_name.agent_name)
								FROM agent_name author_name
								WHERE
									author_name.agent_id = matched.agent_id
									AND author_name.agent_name_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#AUTHOR_NAME_TYPE#">
							) AS author_names,
							(
								SELECT LISTAGG(second_author_name.agent_name, '; ') WITHIN GROUP (ORDER BY second_author_name.agent_name)
								FROM agent_name second_author_name
								WHERE
									second_author_name.agent_id = matched.agent_id
									AND second_author_name.agent_name_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#SECOND_AUTHOR_NAME_TYPE#">
							) AS second_author_names,
							(
								SELECT LISTAGG(taxon_author_name.agent_name, '; ') WITHIN GROUP (ORDER BY taxon_author_name.agent_name)
								FROM agent_name taxon_author_name
								WHERE
									taxon_author_name.agent_id = matched.agent_id
									AND taxon_author_name.agent_name_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#TAXON_AUTHOR_NAME_TYPE#">
							) AS taxon_author_names
						FROM
							(
								SELECT
									agent_id,
									LISTAGG(agent_name_type, '|') WITHIN GROUP (ORDER BY agent_name_type) AS name_types
								FROM agent_name
								WHERE
									agent_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#agentName#">
								GROUP BY agent_id
							) matched
							JOIN agent ON matched.agent_id = agent.agent_id
							LEFT JOIN preferred_agent_name ON matched.agent_id = preferred_agent_name.agent_id
						ORDER BY
							preferred_agent_name.agent_name,
							matched.agent_id
					</cfquery>
					<cfif getMatches.recordcount EQ 0>
						<cfset notFoundCount = notFoundCount + 1>
						<!--- a near miss on case is the most common reason an otherwise correct name fails to load --->
						<cfquery name="getCaseVariants" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getCaseVariants_result">
							SELECT DISTINCT agent_name
							FROM agent_name
							WHERE
								UPPER(agent_name) = UPPER(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#agentName#">)
							ORDER BY agent_name
						</cfquery>
					</cfif>
					<!--- author form columns are left blank unless the name matches exactly one agent --->
					<cfset result = StructNew()>
					<cfset result.agent_name = agentName>
					<cfset result.match_count = getMatches.recordcount>
					<cfset result.matched_agent_id = "">
					<cfset result.agents = ArrayNew(1)>
					<cfset result.agent_list = "">
					<cfset result.agent_type = "">
					<cfset result.name_types = "">
					<cfset result.is_author = "">
					<cfset result.author_names = "">
					<cfset result.is_second_author = "">
					<cfset result.second_author_names = "">
					<cfset result.is_taxon_author = "">
					<cfset result.taxon_author_names = "">
					<cfset result.case_variants = "">
					<cfif getMatches.recordcount EQ 0>
						<cfset result.match = "Not Found">
						<cfset result.case_variants = ValueList(getCaseVariants.agent_name, "; ")>
					<cfelse>
						<cfset nameTypes = "">
						<cfloop query="getMatches">
							<cfset agentEntry = StructNew()>
							<cfset agentEntry.agent_id = getMatches.agent_id>
							<cfset agentEntry.preferred_agent_name = getMatches.preferred_agent_name>
							<cfset ArrayAppend(result.agents, agentEntry)>
							<cfset result.agent_list = ListAppend(result.agent_list, "#getMatches.preferred_agent_name# (#getMatches.agent_id#)", "|")>
							<cfloop list="#getMatches.name_types#" delimiters="|" index="nameType">
								<cfif ListFind(nameTypes, nameType, "|") EQ 0>
									<cfset nameTypes = ListAppend(nameTypes, nameType, "|")>
								</cfif>
							</cfloop>
						</cfloop>
						<cfset result.name_types = replace(nameTypes, "|", "; ", "all")>
						<cfif getMatches.recordcount EQ 1>
							<cfset foundCount = foundCount + 1>
							<cfset result.match = "Found">
							<cfset result.matched_agent_id = getMatches.agent_id>
							<!--- the agent_id is already in its own column --->
							<cfset result.agent_list = getMatches.preferred_agent_name>
							<cfset result.agent_type = getMatches.agent_type>
							<cfset result.is_author = YesNoFormat(ListFind(getMatches.name_types, AUTHOR_NAME_TYPE, "|") GT 0)>
							<cfset result.author_names = getMatches.author_names>
							<cfset result.is_second_author = YesNoFormat(ListFind(getMatches.name_types, SECOND_AUTHOR_NAME_TYPE, "|") GT 0)>
							<cfset result.second_author_names = getMatches.second_author_names>
							<cfset result.is_taxon_author = YesNoFormat(ListFind(getMatches.name_types, TAXON_AUTHOR_NAME_TYPE, "|") GT 0)>
							<cfset result.taxon_author_names = getMatches.taxon_author_names>
						<cfelse>
							<cfset ambiguousCount = ambiguousCount + 1>
							<cfset result.match = "Ambiguous">
						</cfif>
					</cfif>
					<cfset ArrayAppend(results, result)>
				</cfif>
			</cfloop>
		<cfcatch type="any">
			<cfset errorMessage = cfcatch.message>
			<cfif isDefined("cfcatch.queryError")>
				<cfset errorMessage = "#errorMessage# #cfcatch.queryError#">
			</cfif>
			<cfset errorCatch = cfcatch>
		</cfcatch>
		</cftry>

		<cfif variables.asCsv AND len(errorMessage) EQ 0>
			<cfheader name="Content-Disposition" value="attachment; filename=checkAgentsResults.csv">
			<cfcontent type="text/csv; charset=utf-8" reset="true">
			<cfset csvLines = ArrayNew(1)>
			<cfset ArrayAppend(csvLines, "AGENT_NAME,MATCH,MATCH_COUNT,MATCHED_AGENT_ID,AGENT,AGENT_TYPE,NAME_TYPES,IS_AUTHOR,AUTHOR_NAMES,IS_SECOND_AUTHOR,SECOND_AUTHOR_NAMES,IS_TAXON_AUTHOR,TAXON_AUTHOR_NAMES,CASE_VARIANTS")>
			<cfloop array="#results#" index="result">
				<cfset line = csvField(result.agent_name)>
				<cfset line = line & "," & csvField(result.match)>
				<cfset line = line & "," & result.match_count>
				<cfset line = line & "," & result.matched_agent_id>
				<cfset line = line & "," & csvField(result.agent_list)>
				<cfset line = line & "," & csvField(result.agent_type)>
				<cfset line = line & "," & csvField(result.name_types)>
				<cfset line = line & "," & result.is_author>
				<cfset line = line & "," & csvField(result.author_names)>
				<cfset line = line & "," & result.is_second_author>
				<cfset line = line & "," & csvField(result.second_author_names)>
				<cfset line = line & "," & result.is_taxon_author>
				<cfset line = line & "," & csvField(result.taxon_author_names)>
				<cfset line = line & "," & csvField(result.case_variants)>
				<cfset ArrayAppend(csvLines, line)>
			</cfloop>
			<cfoutput>#ArrayToList(csvLines, Chr(13) & Chr(10))#</cfoutput>
		<cfelse>
			<cfif variables.asCsv>
				<!--- an error is reported as a page rather than as a csv download --->
				<cfinclude template="/shared/_header.cfm">
			</cfif>
			<cfoutput>
				<main class="container-fluid py-3 px-xl-5 mb-4" id="content">
					<h1 class="h2 mt-2">Check of agent names against MCZbase agent records</h1>
					<p><a href="/dataquality/check_agents.cfm">Start again</a></p>
					<cfif len(errorMessage) GT 0>
						<section>
							<h2 class="h4">Error processing file</h2>
							<p>There was an error processing the file. Please check the file and try again.</p>
							<cfif row GT 0>
								<p>Error reading line #row# (after the header) of the input file, with AGENT_NAME [#encodeForHtml(agentName)#].</p>
							</cfif>
							<p>#encodeForHtml(errorMessage)#</p>
							<cfif isdefined("session.roles") AND listfindnocase(session.roles,"global_admin")>
								<cfdump var="#errorCatch#">
							</cfif>
						</section>
					<cfelse>
						<section>
							<h2 class="h4">Results Summary</h2>
							<ul>
								<li>Distinct names checked: #ArrayLen(evaluatedNames)#</li>
								<li>Names matching exactly one agent: #foundCount#</li>
								<li>Names matching more than one agent: #ambiguousCount#</li>
								<li>Names not found: #notFoundCount#</li>
							</ul>
						</section>
						<section>
							<h2 class="h4">Names Checked</h2>
							<table class="table table-responsive d-xl-table table-striped small">
								<thead>
									<tr>
										<th>Agent Name</th>
										<th>Match</th>
										<th>Matched Agent ID</th>
										<th>Agent</th>
										<th>Types of This Name</th>
										<th>Author</th>
										<th>Second Author</th>
										<th>Taxon Author</th>
									</tr>
								</thead>
								<tbody>
									<cfloop array="#results#" index="result">
										<cfset matchClass = "text-success">
										<cfif result.match EQ "Ambiguous">
											<cfset matchClass = "text-warning">
										<cfelseif result.match EQ "Not Found">
											<cfset matchClass = "text-danger">
										</cfif>
										<tr>
											<td>#encodeForHtml(result.agent_name)#</td>
											<td>
												<span class="#matchClass# font-weight-bold">#result.match#</span>
												<cfif result.match EQ "Ambiguous">
													(#result.match_count# agents)
												</cfif>
												<cfif len(result.case_variants) GT 0>
													<br>Differs only in case from: #encodeForHtml(result.case_variants)#
												</cfif>
											</td>
											<td>#encodeForHtml(result.matched_agent_id)#</td>
											<td>
												<cfset separator = "">
												<cfloop array="#result.agents#" index="agentEntry">
													#separator#<a href="/agents/Agent.cfm?agent_id=#encodeForUrl(agentEntry.agent_id)#" target="_blank">#encodeForHtml(agentEntry.preferred_agent_name)# (#encodeForHtml(agentEntry.agent_id)#)</a>
													<cfset separator = "|">
												</cfloop>
												<cfif len(result.agent_type) GT 0>
													<br>#encodeForHtml(result.agent_type)#
												</cfif>
											</td>
											<td>#encodeForHtml(result.name_types)#</td>
											<cfloop list="author,second_author,taxon_author" index="nameForm">
												<td>
													<cfif len(result.matched_agent_id) GT 0>
														<cfif result["is_#nameForm#"] EQ "Yes">
															<span class="text-success font-weight-bold">Yes</span>
														<cfelse>
															<span class="text-danger font-weight-bold">No</span>
															<cfif len(result["#nameForm#_names"]) GT 0>
																<br>Use: #encodeForHtml(result["#nameForm#_names"])#
															<cfelse>
																<br>Agent has no #replace(nameForm, "_", " ")# name
															</cfif>
														</cfif>
													</cfif>
												</td>
											</cfloop>
										</tr>
									</cfloop>
								</tbody>
							</table>
						</section>
					</cfif>
				</main>
			</cfoutput>
			<cfinclude template="/shared/_footer.cfm">
		</cfif>
	</cfcase>
</cfswitch>
