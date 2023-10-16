<!--- special case handling to dump problem data as csv --->
<cfif isDefined("action") AND action is "dumpProblems">
	<cfquery name="getProblemData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		SELECT institution_acronym,collection_cde,other_id_type,other_id_number,publication_title,publication_id,cited_scientific_name,occurs_page_number,citation_page_uri,type_status,citation_remarks
		FROM cf_temp_citation 
		WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
	</cfquery>
	<cfinclude template="/shared/component/functions.cfc">
	<cfset csv = queryToCSV(getProblemData)>
	<cfheader name="Content-Type" value="text/csv">
	<cfoutput>#csv#</cfoutput>
	<cfabort>
</cfif>
<!--- end special case dump of problems --->

<cfset fieldlist = "institution_acronym,collection_cde,other_id_type,other_id_number,publication_title,publication_id,cited_scientific_name,occurs_page_number,citation_page_uri,type_status,citation_remarks">
<cfset fieldTypes ="CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_DECIMAL,CF_SQL_VARCHAR,CF_SQL_DECIMAL,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR">
<cfset requiredfieldlist = "institution_acronym,collection_cde,other_id_type,other_id_number,cited_scientific_name,type_status,citation_remarks">

<!--- special case handling to dump column headers as csv --->
<cfif isDefined("action") AND action is "getCSVHeader">
	<cfset csv = "">
	<cfset separator = "">
	<cfloop list="#fieldlist#" index="field" delimiters=",">
		<cfset csv='#csv##separator#"#field#"'>
		<cfset separator = ",">
	</cfloop>
	<cfheader name="Content-Type" value="text/csv">
	<cfoutput>#csv##chr(13)##chr(10)#</cfoutput>
	<cfabort>
</cfif>

<!--- Normal page delivery with header/footer --->
<cfset pageTitle = "Bulkload Citations">
<cfinclude template="/shared/_header.cfm">
<cfif not isDefined("action") OR len(action) EQ 0><cfset action="nothing"></cfif>
<main class="container py-3" id="content">
	<h1 class="h2 mt-2">Bulkload Citations</h1>

	<cfif #action# is "nothing">
		<cfoutput>
			<p>This tool is used to bulkload citations.</p>
			<p>Upload a comma-delimited text file (csv).  Include column headings, spelled exactly as below.  Additional colums will be ignored</p>
			<span class="btn btn-xs btn-info" onclick="document.getElementById('template').style.display='block';">View template</span>
			<div id="template" style="display:none;margin: 1em 0;">
				<label for="templatearea" class="data-entry-label">
					Copy this header line and save it as a .csv file (<a href="/tools/BulkloadCitations.cfm?action=getCSVHeader">download</a>)
				</label>
				<textarea rows="2" cols="90" id="templatearea" class="w-100 data-entry-textarea">#fieldlist#</textarea>
			</div>
			<p>Columns in <span class="text-danger">red</span> are required; others are optional:</p>
			<ul class="geol_hier">
				<cfloop list="#fieldlist#" index="field" delimiters=",">
					<cfif listContains(requiredfieldlist,field,",")>
						<cfset class="text-danger">
					<cfelse>
						<cfset class="text-dark">
					</cfif>
					<li class="#class#">#field#</li>
				</cfloop>
			</ul>
			<cfform name="atts" method="post" enctype="multipart/form-data" action="/tools/BulkloadCitations.cfm">
				<input type="hidden" name="Action" value="getFile">
				<input type="file" name="FiletoUpload" size="45">
				<input type="submit" value="Upload this file" class="btn btn-primary btn-xs">
			</cfform>
		</cfoutput>
	</cfif>	
	
	
<!------------------------------------------------------->
	<cfif #action# is "getFile">
		<h2 class="h3">First step: Reading data from CSV file.</h2>
		<cfoutput>
			<cffile action="READ" file="#FiletoUpload#" variable="fileContent">
			<cfset fileContent=replace(fileContent,"'","''","all")>
			<cfset arrResult = CSVToArray(CSV = fileContent.Trim()) />
		
			<!--- cleanup any incomplete work by the same user --->
			<cfquery name="clearTempTable" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="clearTempTable_result">
				DELETE FROM cf_temp_citation 
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			
			<!--- check for required fields in header line --->
			<cfset institution_acronym_exists = false>
			<cfset collection_cde_exists = false>
			<cfset other_id_type_exists = false>
			<cfset other_id_number_exists = false>
			<cfset publication_title_exists = false>
			<cfset cited_scientific_name_exists = false>
			<cfset type_status_exists = false>
			<cfloop from="1" to ="#ArrayLen(arrResult[1])#" index="col">
				<cfset header = arrResult[1][col]>
				<cfif ucase(header) EQ 'institution_acronym'><cfset institution_acronym_exists=true></cfif>
				<cfif ucase(header) EQ 'collection_cde'><cfset collection_cde_exists=true></cfif>
				<cfif ucase(header) EQ 'other_id_type'><cfset other_id_type_exists=true></cfif>
				<cfif ucase(header) EQ 'other_id_number'><cfset other_id_number_exists=true></cfif>
				<cfif ucase(header) EQ 'publication_title'><cfset publication_title_exists=true></cfif>
				<cfif ucase(header) EQ 'cited_scientific_name'><cfset cited_scientific_name_exists=true></cfif>
				<cfif ucase(header) EQ 'type_status'><cfset type_status_exists=true></cfif>				
			</cfloop>
			<cfif not (institution_acronym_exists AND collection_cde_exists AND other_id_type_exists AND other_id_number_exists AND publication_title_exists AND cited_scientific_name_exists AND type_status_exists)>
				<cfset message = "One or more required fields are missing in the header line of the csv file.">
				<cfif not institution_acronym_exists><cfset message = "#message# institution_acronym is missing."></cfif>
				<cfif not collection_cde_exists><cfset message = "#message# collection_cde is missing."></cfif>
				<cfif not other_id_type_exists><cfset message = "#message# other_id_type is missing."></cfif>
				<cfif not other_id_number_exists><cfset message = "#message# other_id_number is missing."></cfif>
				<cfif not publication_title_exists><cfset message = "#message# publication_title is missing."></cfif>
				<cfif not cited_scientific_name_exists><cfset message = "#message# cited_scientific_name is missing."></cfif>
				<cfif not type_status_exists><cfset message = "#message# type_status is missing."></cfif>
				<cfthrow message="#message#">
			</cfif>
			<cfset colNames="">
			<cfset loadedRows = 0>
			<!--- get the headers from the first row of the input, then iterate through the remaining rows inserting the data into the temp table. --->
			<cfloop from="1" to ="#ArrayLen(arrResult)#" index="row">
				<!--- obtain the values in the current row --->
				<cfset colVals="">
				<cfloop from="1" to ="#ArrayLen(arrResult[row])#" index="col">
					<cfset thisBit=arrResult[row][col]>
					<cfif #row# is 1>
						<cfset colNames="#colNames#,#thisBit#">
					<cfelse>
						<!--- quote values to ensure all columns have content, will need to strip out later to insert values --->
						<cfset colVals="#colVals#,'#thisBit#'">
					</cfif>
				</cfloop>
				<cfif #row# is 1>
					<!--- first row, obtain column headers --->
					<!--- strip off the leading separator --->
					<cfset colNames=replace(colNames,",","","first")>
					<cfset colNameArray = listToArray(ucase(colNames))><!--- the list of columns/fields found in the input file --->
					<cfset fieldArray = listToArray(ucase(fieldlist))><!--- the full list of fields --->
					<cfset typeArray = listToArray(fieldTypes)><!--- the types for the full list of fields --->
					<h3 class="h4">Found #arrayLen(colNameArray)# matching columns in header of csv file.</h3>
					<ul class="geol_hier">
						<cfloop list="#fieldlist#" index="field" delimiters=",">
							<cfif listContains(requiredfieldlist,field,",")>
								<cfset class="text-danger">
							<cfelse>
								<cfset class="text-dark">
							</cfif>
							<li class="#class#">
								#field#
								<cfif arrayFindNoCase(colNameArray,field) GT 0>
									<strong>Present in CSV</strong>
								</cfif>
							</li>
						</cfloop>
					</ul>
				<cfelse>
					<!--- subsequent rows, data --->
					<!--- strip off the leading separator --->
					<cfset colVals=replace(colVals,",","","first")>
					<cfset colValArray=listToArray(colVals)>
					<cftry>
						<!--- construct insert for row with a line for each entry in fieldlist using cfqueryparam if column header is in fieldlist, otherwise using null --->
						<cfquery name="insert" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="insert_result">
							insert into cf_temp_citation
								(#fieldlist#,username)
							values (
								<cfset separator = "">
								<cfloop from="1" to ="#ArrayLen(fieldArray)#" index="col">
									<cfif arrayFindNoCase(colNameArray,fieldArray[col]) GT 0>
										<cfset fieldPos=arrayFind(colNameArray,fieldArray[col])>
										<cfset val=trim(colValArray[col])>
										<cfset val=rereplace(val,"^'+",'')>
										<cfset val=rereplace(val,"'+$",'')>
										<cfif val EQ ""> 
											#separator#NULL
										<cfelse>
											#separator#<cfqueryparam cfsqltype="#typeArray[fieldPos]#" value="#val#">
										</cfif>
									<cfelse>
										#separator#NULL
									</cfif>
									<cfset separator = ",">
								</cfloop>
								#separator#<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
							)
						</cfquery>
						<cfset loadedRows = loadedRows + insert_result.recordcount>
					<cfcatch>
						<cfthrow message="Error inserting data from line #row# in input file.  Header:[#colNames#] Row:[#colVals#] Error: #cfcatch.message#">
					</cfcatch>
					</cftry>
				</cfif>
			</cfloop>
		
			<h3 class="h3">
				Successfully loaded #loadedRows# records from the CSV file.  Next <a href="/tools/BulkloadCitations.cfm?action=validate">click to validate</a>.
			</h3>
		</cfoutput>
	</cfif>
	<!------------------------------------------------------->
	<cfif #action# is "validate">
		<h2 class="h3">Second step: Data Validation</h2>
		<cfoutput>
			<cfquery name="getCID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				update cf_temp_citation set collection_object_id =
				(select cataloged_item.collection_object_id from cataloged_item where cataloged_item.collection_cde = cf_temp_citation.collection_cde and cataloged_item.cat_num = cf_temp_citation.other_id_number)
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="getCID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				update cf_temp_citation set cited_taxon_name_id =
				(select taxonomy.taxon_name_id from taxonomy,taxonomy_publication where taxonomy.taxon_name_id = taxonomy_publication.TAXON_NAME_ID
				AND publication_id = cf_temp_citation.publication_id AND scientific_name=cf_temp_citation.cited_scientific_name)
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="getCID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				update cf_temp_citation set type_status = (select type_status from CTCITATION_TYPE_STATUS where CTCITATION_TYPE_STATUS.type_status = cf_temp_citation.type_status)
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="miac" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE cf_temp_citation 
				SET status = 'type_status_not_found'
				WHERE type_status is null
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="miap" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE cf_temp_citation 
				SET status = 'collection_object_id_not_found'
				WHERE collection_object_id is null
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT collection_object_id,institution_acronym,collection_cde,other_id_type,other_id_number,publication_title,publication_id,cited_scientific_name,occurs_page_number,citation_page_uri,type_status,citation_remarks,status
				FROM cf_temp_citation
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="pf" dbtype="query">
				SELECT count(*) c 
				FROM data 
				WHERE status is not null
			</cfquery>
			<cfif pf.c gt 0>
				<h2>
					There is a problem with #pf.c# of #data.recordcount# row(s). See the STATUS column. (<a href="/tools/BulkloadCitations.cfm?action=dumpProblems">download</a>).
				</h2>
				<h3>
					Fix the problems in the data and <a href="/tools/BulkloadCitations.cfm">start again</a>.
				</h3>
			<cfelse>
				<h2>
					Validation checks passed. Look over the table below and <a href="/tools/BulkloadCitations.cfm?action=load">click to continue</a> if it all looks good.
				</h2>
			</cfif>
			<table class='sortable table table-responsive table-striped d-lg-table'>
				<thead>
					<tr>
						<th>INSTITUTION_ACRONYM</th>
						<th>COLLECTION_CDE</th>
						<th>OTHER_ID_TYPE</th>
						<th>OTHER_ID_NUMBER</th>
						<th>PUBLICATION_TITLE</th>
						<th>PUBLICATION_ID</th>
						<th>CITED_SCIENTIFIC_NAME</th>
						<th>OCCURS_PAGE_NUMBER</th>
						<th>CITATION_PAGE_URI</th>
						<th>TYPE_STATUS</th>
						<th>CITATION_REMARKS</th>
						<th>STATUS</th>
					</tr>
				<tbody>
					<cfloop query="data">
						<tr>
							<td>#data.INSTITUTION_ACRONYM#</td>
							<td>#data.COLLECTION_CDE#</td>
							<td>#data.OTHER_ID_TYPE#</td>
							<td>#data.OTHER_ID_NUMBER#</td>
							<td>#data.PUBLICATION_TITLE#</td>
							<td>#data.PUBLICATION_ID#</td>
							<td>#data.CITED_SCIENTIFIC_NAME#</td>
							<td>#data.OCCURS_PAGE_NUMBER#</td>
							<td>#data.CITATION_PAGE_URI#</td>
							<td>#data.TYPE_STATUS#</td>
							<td>#data.CITATION_REMARKS#</td>
							<td><strong>#STATUS#</strong></td>
						</tr>
					</cfloop>
				</tbody>
			</table>
		</cfoutput>
	</cfif>
	<!-------------------------------------------------------------------------------------------->
	<cfif action is "load">
		<h2 class="h3">Third step: Apply changes.</h2>
		<cfoutput>
			<cfquery name="getTempData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT * FROM cf_temp_citation
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cftry>
				<cfset agent_updates = 0>
				<cftransaction>
					<cfloop query="getTempData">
						<cfquery name="updateCitations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="updateCitations_result">
							insert into citatons
							(publication_title,publication_id) values(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#publication_title#">,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#publication_id#">)
						</cfquery>
						<cfset citation_updates = citation_updates + updateCitations_result.recordcount>
					</cfloop>
				</cftransaction>
				<h2>Updated #citation_updates# agents.</h2>
			<cfcatch>
				<h2>There was a problem updating citations.</h2>
				<cfquery name="getProblemData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT publication_title,publication_id, status 
					FROM cf_temp_citation 
					WHERE status is not null
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<h3>Problematic Rows (<a href="/tools/BulkloadCitations.cfm?action=dumpProblems">download</a>)</h3>
				<table class='sortable table table-responsive table-striped d-lg-table'>
					<thead>
						<tr>
							<th>institution_acronym</th>
							<th>collection_cde</th>
							<th>other_id_type</th>
							<th>other_id_number</th>
							<th>publication_title</th>
							<th>publication_id</th>
							<th>cited_scientific_name</th>
							<th>occurs_page_number</th>
							<th>citation_page_uri</th>
							<th>type_status</th>
							<th>citation_remarks</th>
							<th>status</th>
						</tr> 
					</thead>
					<tbody>
						<cfloop query="getProblemData">
							<tr>
								<td>#getProblemData.institution_acronym#</td>
								<td>#getProblemData.collection_cde#</td>
								<td>#getProblemData.other_id_type#</td>
								<td>#getProblemData.other_id_number#</td>
								<td>#getProblemData.publication_title#</td>
								<td>#getProblemData.publication_id#</td>
								<td>#getProblemData.cited_scientific_name#</td>
								<td>#getProblemData.occurs_page_number#</td>
								<td>#getProblemData.citation_page_uri#</td>
								<td>#getProblemData.type_status#</td>
								<td>#getProblemData.citation_remarks#</td>
								<td>#getProblemData.status#</td>
							</tr> 
						</cfloop>
					</tbody>
				</table>
				<cfrethrow>
			</cfcatch>
			</cftry>
			<cfset problem_key = "">
			<cftransaction>
				<cftry>
					<cfset agent_updates = 0>
					<cfloop query="getTempData">
						<cfset problem_key = getTempData.key>
						<cfquery name="updateCitations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="updateCitations_result">
							insert into citation (publication_id,collection_object_id,cited_taxon_name_id,cit_current_fg,occurs_page_number,
							citation_page_uri,type_status,citation_remarks)values(<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#cited_taxon_name_id#">,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#occurs_page_number#">,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#citation_page_URI#">,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#type_status#">,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#citation_remarks#">)
						</cfquery>
						<cfset agent_updates = citation_updates + updateCitations_result.recordcount>
					</cfloop>
					<cftransaction action="commit">
				<cfcatch>
					<cftransaction action="rollback">
					<cfquery name="getProblemData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						SELECT *
						FROM cf_temp_agents 
						WHERE key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#problem_key#">
					</cfquery>
					<h3>Error updating row (#agent_updates + 1#): #cfcatch.message#</h3>
					<table class='sortable table table-responsive table-striped d-lg-table'>
						<thead>
							<tr>
								<th>publication_title</th>
								<th>publication_id</th>
								<th>cited_scientific_name</th>
								<th>occurs_page_number</th>
								<th>citation_page_uri</th>
								<th>type_status</th>
								<th>citation_remarks</th>
								<th>institution_acronym</th>
								<th>collection_cde</th>
								<th>other_id_type</th>
								<th>other_id_number</th>
								<th>status</th>
							</tr> 
						</thead>
						<tbody>
							<cfloop query="getProblemData">
								<tr>
									<td>#getProblemData.publication_title#</td>
									<td>#getProblemData.publication_id#</td>
									<td>#getProblemData.cited_scientific_name#</td>
									<td>#getProblemData.occurs_page_number#</td>
									<td>#getProblemData.citation_page_uri#</td>
									<td>#getProblemData.type_status#</td>
									<td>#getProblemData.citation_remarks#</td>
									<td>#getProblemData.institution_acronym#</td>
									<td>#getProblemData.collection_cde#</td>
									<td>#getProblemData.other_id_type#</td>
									<td>#getProblemData.other_id_number#</td>
									<td>#getProblemData.status#</td>
								</tr> 
							</cfloop>
						</tbody>
					</table>
					<cfrethrow>
				</cfcatch>
				</cftry>
			</cftransaction>
			<h2>Updated #agent_updates# agents.</h2>
			<h2>Success, changes applied.</h2>
			<!--- cleanup --->
			<cfquery name="clearTempTable" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="clearTempTable_result">
				DELETE FROM cf_temp_agents
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
		</cfoutput>
	</cfif>