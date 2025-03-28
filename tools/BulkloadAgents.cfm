<!--- tools/bulkloadAgents.cfm add agents to specimens in bulk.

Copyright 2008-2017 Contributors to Arctos
Copyright 2008-2025 President and Fellows of Harvard College

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

<cfset NUMBER_OF_OTHER_NAME_PAIRS = 3>

<!--- page can submit with action either as a form post parameter or as a url parameter, obtain either into variable scope. --->
<cfif isDefined("url.action")><cfset variables.action = url.action></cfif>
<cfif isDefined("form.action")><cfset variables.action = form.action></cfif>

<!--- special case handling to dump problem data as csv --->
<cfif isDefined("variables.action") AND variables.action is "dumpProblems">
	<cfquery name="getProblemData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		SELECT agent_type,preferred_name,
			first_name,middle_name,last_name, prefix,suffix,
			birth_date,death_date,agent_remark, biography,
			<cfloop from="1" to="#NUMBER_OF_OTHER_NAME_PAIRS#" index="i">
				other_name_#i#, other_name_type_#i#,
			</cfloop>
			agentguid_guid_type,agentguid,
			status
		FROM cf_temp_agents 
		WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
		ORDER BY key
	</cfquery>
	<cfinclude template="/shared/component/functions.cfc">
	<cfset csv = queryToCSV(getProblemData)>
	<cfheader name="Content-Type" value="text/csv">
	<cfoutput>#csv#</cfoutput>
	<cfabort>
</cfif>
<!--- end special case dump of problems --->

<!--- build lists of fields for CSV file and their types --->
<cfset fieldlist = "AGENT_TYPE,PREFERRED_NAME,FIRST_NAME,MIDDLE_NAME,LAST_NAME,PREFIX,SUFFIX,BIRTH_DATE,DEATH_DATE,AGENT_REMARK,BIOGRAPHY">
<cfloop from="1" to="#NUMBER_OF_OTHER_NAME_PAIRS#" index="i">
	<cfset fieldlist = ListAppend(fieldlist,"OTHER_NAME_#i#")>
	<cfset fieldlist = ListAppend(fieldlist,"OTHER_NAME_TYPE_#i#")>
</cfloop>
<cfset fieldlist = ListAppend(fieldlist,"AGENTGUID_GUID_TYPE")>
<cfset fieldlist = ListAppend(fieldlist,"AGENTGUID")>
<cfset fieldTypes = "CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR">
<cfloop from="1" to="#NUMBER_OF_OTHER_NAME_PAIRS#" index="i">
	<cfset fieldTypes = ListAppend(fieldTypes,"CF_SQL_VARCHAR")>
	<cfset fieldTypes = ListAppend(fieldTypes,"CF_SQL_VARCHAR")>
</cfloop>
<cfset fieldTypes = ListAppend(fieldTypes,"CF_SQL_VARCHAR")>
<cfset fieldTypes = ListAppend(fieldTypes,"CF_SQL_VARCHAR")>

<cfset requiredfieldlist = "AGENT_TYPE,PREFERRED_NAME">

<cfif listlen(fieldlist) NEQ listlen(fieldTypes)>
	<cfthrow message = "Error: Bug in the definition of fieldlist[#listlen(fieldlist)#] and fieldType[#listlen(fieldTypes)#] lists, lists must be the same length, but are not.">
</cfif>

<!--- special case handling to dump column headers as csv --->
<cfif isDefined("variables.action") AND variables.action is "getCSVHeader">
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
<cfset pageTitle = "Bulkload Agents">
<cfinclude template="/shared/_header.cfm">
<cfinclude template="/tools/component/csv.cfc" runOnce="true"><!--- for common csv testing functions --->
<cfif not isDefined("variables.action") OR len(variables.action) EQ 0><cfset variables.action="entryPoint"></cfif>
<main class="container-fluid py-3 px-xl-5" id="content">
	<h1 class="h2 mt-2">Bulkload Agents</h1>
	<!------------------------------------------------------->
	
	<cfif variables.action is "entryPoint">
		<cfoutput>
			<p>
				This tool creates agent records of agent_type = "person" in bulk. The tool ignores rows that are exactly the same. Additional columns will be ignored. The different name types must appear as they do on the controlled vocabulary lists for <a href="vocabularies/ControlledVocabulary.cfm?table=CTAGENT_NAME_TYPE">ATTRIBUTE_NAME_TYPE</a> and the GUIDs for agent identifiers are in the controlled vocabularies listed in <a href="/vocabularies/ControlledVocabulary.cfm?table=CTGUID_TYPE">GUID_TYPE</a>. Upload a comma-delimited text file (csv). Include column headings, spelled exactly as below. 
			</p>
			<h2 class="h4">Use Template to Load Data</h2>
			<button class="btn btn-xs btn-primary float-left mr-3" id="copyButton">Copy Column Headers</button>
			<div id="template" class="my-1 mx-0">
				<label for="templatearea" class="data-entry-label" style="line-height: inherit;">
					Copy this header line, paste it into a blank worksheet, and save it as a .csv file or <a href="/tools/BulkloadAgents.cfm?action=getCSVHeader" class="font-weight-bold">download</a> a template.
				</label>
				<textarea style="height: 55px;" cols="90" id="templatearea" class="mb-1 w-100 data-entry-textarea small">#fieldlist#</textarea>
			</div>
			<div class="accordion" id="accordionID">
				<div class="card mb-2 bg-light">
					<div class="card-header" id="headingID">
						<h3 class="h5 my-0">
							<button type="button" role="button" aria-label="agents pane" class="headerLnk text-left w-100" data-toggle="collapse" data-target="##IDPane" aria-expanded="false" aria-controls="IDPane">
								Data Entry Instructions per Column
							</button>
						</h3>
					</div>
					<div id="IDPane" class="collapse" aria-labelledby="headingID" data-parent="##accordionID">
						<div class="card-body" id="IDCardBody">
							<p class="px-3 pt-2"> Columns in <span class="text-danger">red</span> are required; others are optional.</p>
							<ul class="mb-4 h5 font-weight-normal list-group mx-3">
								<cfloop list="#fieldlist#" index="field" delimiters=",">
									<cfquery name = "getComments"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#"  result="getComments_result">
										SELECT comments
										FROM sys.all_col_comments
										WHERE 
											owner = 'MCZBASE'
											and table_name = 'CF_TEMP_AGENTS'
											and column_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(field)#" />
									</cfquery>
									<cfset comment = "">
									<cfif getComments.recordcount GT 0>
										<cfset comment = getComments.comments>
									</cfif>
									<cfset aria = "">
									<cfif listContains(requiredfieldlist,field,",")>
										<cfset class="text-danger">
										<cfset aria = "aria-label='Required Field'">
									<cfelse>
										<cfset class="text-dark">
									</cfif>
									<li class="pb-1 mx-3">
										<span class="#class# font-weight-lessbold" #aria#>#field#: </span> <span class="text-secondary">#comment#</span>
									</li>
								</cfloop>
							</ul>
						</div>
					</div>
				</div>
			</div>
			<div class="">
				<h2 class="h4 mt-4">Upload a comma-delimited text file (csv)</h2>
				<form name="agts" method="post" enctype="multipart/form-data" action="/tools/BulkloadAgents.cfm">
					<div class="form-row border rounded p-2">
						<input type="hidden" name="action" value="getFile">
						<div class="col-12 col-md-4">
							<label for="fileToUpload" class="data-entry-label">File to bulkload:</label> 
							<input type="file" name="FiletoUpload" id="fileToUpload" class="data-entry-input p-0 m-0">
						</div>
						<div class="col-12 col-md-3">
							<cfset charsetSelect = getCharsetSelectHTML()>
						</div>
						<div class="col-12 col-md-3">
							<cfset formatSelect = getFormatSelectHTML()>
						</div>
						<div class="col-12 col-md-2">
							<label for="submitButton" class="data-entry-label">&nbsp;</label>
							<input type="submit" id="submittButton" value="Upload this file" class="btn btn-primary btn-xs">
						</div>
					</div>
				</form>
			</div>
			<script>
				document.getElementById('copyButton').addEventListener('click', function() {
					// Get the textarea element
					var textArea = document.getElementById('templatearea');

					// Select the text content
					textArea.select();

					try {
						// Copy the selected text to the clipboard
						var successful = document.execCommand('copy');
						var msg = successful ? 'successful' : 'unsuccessful';
						console.log('Copy command was ' + msg);
					} catch (err) {
						console.log('Oops, unable to copy', err);
					}

					// Optionally deselect the text after copying to avoid confusion
					window.getSelection().removeAllRanges();

					// Optional: Provide feedback to the user
					alert('Text copied to clipboard!');
				});
			</script>
		</cfoutput>
	</cfif>	
	

	<!------------------------------------------------------->

	<cfif variables.action is "getFile">

		<!--- get form variables --->
		<cfif isDefined("form.fileToUpload")><cfset variables.fileToUpload = form.fileToUpload></cfif>
		<cfif isDefined("form.format")><cfset variables.format = form.format></cfif>
		<cfif isDefined("form.characterSet")><cfset variables.characterSet = form.characterSet></cfif>

		<h2 class="h4">First step: Reading data from CSV file.</h2>
		<cfoutput>
		<!--- Compare the numbers of headers expected against provided in CSV file --->
		<!--- Set some constants to identify error cases in cfcatch block --->
		<cfset NO_COLUMN_ERR = "One or more required fields are missing in the header line of the csv file.">
		<cfset DUP_COLUMN_ERR = "One or more columns are duplicated in the header line of the csv file.">
		<cfset COLUMN_ERR = "Error inserting data">
		<cfset NO_HEADER_ERR = "No header line found, csv file appears to be empty.">
		<cfset TABLE_NAME = "CF_TEMP_AGENTS">
		<cftry>
			<!--- cleanup any incomplete work by the same user --->
			<cfquery name="clearTempTable" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="clearTempTable_result">
				DELETE FROM cf_temp_agents
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>

				<cfset variables.foundHeaders =""><!--- populated by loadCsvFile --->
				<cfset variables.size=""><!--- populated by loadCsvFile --->
				<cfset iterator = loadCsvFile(FileToUpload=FileToUpload,format=format,characterSet=characterSet)>			

				<!--- Note: As we can't use csvFormat.withHeader(), we can not match columns by name, we are forced to do so by number, thus arrays --->
				<cfset colNameArray = listToArray(ucase(variables.foundHeaders))><!--- the list of columns/fields found in the input file --->
				<cfset fieldArray = listToArray(ucase(fieldlist))><!--- the full list of fields --->
				<cfset typeArray = listToArray(fieldTypes)><!--- the types for the full list of fields --->
				<div class="col-12 my-4 px-0">
					<h3 class="h4">Found #variables.size# columns in header of csv file.</h3>
					There are #ListLen(fieldList)# columns expected in the header (of these #ListLen(requiredFieldList)# are required).
				</div>

				<!--- check for required fields in header line, list all fields, throw exception and fail if any required fields are missing --->
				<cfset reqFieldsResponse = checkRequiredFields(fieldList=fieldList,requiredFieldList=requiredFieldList,NO_COLUMN_ERR=NO_COLUMN_ERR,TABLE_NAME=TABLE_NAME)>

				<!--- Test for additional columns not in list, warn and ignore. --->
				<cfset addFieldsResponse = checkAdditionalFields(fieldList=fieldList)>

				<!--- Identify duplicate columns and fail if found --->
				<cfset dupFieldsResponse = checkDuplicateFields(foundHeaders=variables.foundHeaders,DUP_COLUMN_ERR=DUP_COLUMN_ERR)>

				<cfset colNames="#variables.foundHeaders#">
				<cfset loadedRows = 0>
				<cfset foundHighCount = 0>
				<cfset foundHighAscii = "">
				<cfset foundMultiByte = "">
				<!--- Iterate through the remaining rows inserting the data into the temp table. --->
				<cfset row = 0>
				<cfloop condition="#iterator.hasNext()#">
					<!--- obtain the values in the current row --->
					<cfset rowData = iterator.next()>
					<cfset row = row + 1>
					<cfset columnsCountInRow = rowData.size()>
					<cfset collValuesArray= ArrayNew(1)>
					<cfloop index="i" from="0" to="#rowData.size() - 1#">
						<!--- loading cells from object instead of list allows commas inside cells --->
						<cfset thisBit = "#rowData.get(JavaCast('int',i))#" >
						<!--- store in a coldfusion array so we won't need JavaCast to reference by position --->
						<cfset ArrayAppend(collValuesArray,thisBit)>
						<cfif REFind("[^\x00-\x7F]",thisBit) GT 0>
							<!--- high ASCII --->
							<cfif foundHighCount LT 6>
								<cfset foundHighAscii = "#foundHighAscii# <li class='text-danger font-weight-bold'>#thisBit#</li>"><!--- " --->
								<cfset foundHighCount = foundHighCount + 1>
							</cfif>
						<cfelseif REFind("[\xc0-\xdf][\x80-\xbf]",thisBit) GT 0>
							<!--- multibyte --->
							<cfif foundHighCount LT 6>
								<cfset foundMultiByte = "#foundMultiByte# <li class='text-danger font-weight-bold'>#thisBit#</li>"><!--- " --->
								<cfset foundHighCount = foundHighCount + 1>
							</cfif>
						</cfif>
					</cfloop>
					<cftry>
						<!--- construct insert for row with a line for each entry in fieldlist using cfqueryparam if column header is in fieldlist, otherwise using null --->
						<!--- Note: As we can't use csvFormat.withHeader(), we can not match columns by name, we are forced to do so by number, thus arrays --->
						<cfquery name="insert" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="insert_result">
							insert into cf_temp_agents
								(#fieldlist#,username)
							values (
								<cfset separator = "">
								<cfloop from="1" to ="#ArrayLen(fieldArray)#" index="col">
									<cfif arrayFindNoCase(colNameArray,fieldArray[col]) GT 0>
										<cfset fieldPos=arrayFind(colNameArray,fieldArray[col])>
										<cfset val=trim(collValuesArray[fieldPos])>
										<cfset val=rereplace(val,"^'+",'')>
										<cfset val=rereplace(val,"'+$",'')>
										<cfif val EQ ""> 
											#separator#NULL
										<cfelse>
											#separator#<cfqueryparam cfsqltype="#typeArray[col]#" value="#val#">
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
						<!--- identify the problematic row --->
						<cfset error_message="<h4>Check character set and format selected if your headers match required headers in red above.</h4> #COLUMN_ERR# from line #row# in input file.  <br>Header:[#colNames#] <br>Row:[#ArrayToList(collValuesArray)#] <br>Error: #cfcatch.message#"><!--- " --->
						<cfif isDefined("cfcatch.queryError")>
							<cfset error_message = "#error_message# #cfcatch.queryError#">
						</cfif>
						<cfthrow message = "#error_message#">
					</cfcatch>
					</cftry>
				</cfloop>
			
				<cfif foundHighCount GT 0>
					<cfset extendedResult = reportExtended(foundHighCount=foundHighCount,foundHighAscii=foundHighAscii,foundMultiByte=foundMultiByte,linkTarget='/tools/BulkloadAgents.cfm')>	
				</cfif>
				<h3 class="mt-3">
					<cfif loadedRows EQ 0>
						Loaded no rows from the CSV file. The file appears to be just a header with no data. Fix file and <a href="/tools/BulkloadAgents.cfm" class="text-danger">start again</a>
					<cfelse>
						<cfif variables.size eq 1>
							Size = 1
						<cfelse>
						Successfully read #loadedRows# records from the CSV file. Next <a href="/tools/BulkloadAgents.cfm?action=validate" class="btn-link font-weight-lessbold">click to validate</a>.</cfif>
					</cfif>
				</h3>
			<cfcatch>
				<h3 class="mt-3">
					<strong class="text-danger">Failed to read the CSV file.</strong> Fix the errors in the file and <a href="/tools/BulkloadAgents.cfm" class="text-danger">start again</a>.
				</h3>
				<cfif isDefined("variables.foundHeaders")>
					<cfset foundHighCount = 0>
					<cfset foundHighAscii = "">
					<cfset foundMultiByte = "">
					<cfloop list="#variables.foundHeaders#" index="thisBit">
						<cfif REFind("[^\x00-\x7F]",thisBit) GT 0>
							<!--- high ASCII --->
							<cfif foundHighCount LT 6>
								<cfset foundHighAscii = "#foundHighAscii# <li class='text-danger font-weight-bold'>#thisBit#</li>"><!--- " --->
								<cfset foundHighCount = foundHighCount + 1>
							</cfif>
						<cfelseif REFind("[\xc0-\xdf][\x80-\xbf]",thisBit) GT 0>
							<!--- multibyte --->
							<cfif foundHighCount LT 6>
								<cfset foundMultiByte = "#foundMultiByte# <li class='text-danger font-weight-bold'>#thisBit#</li>"><!--- " --->
								<cfset foundHighCount = foundHighCount + 1>
							</cfif>
						</cfif>
					</cfloop>
					<cfif isDefined("foundHighCount") AND foundHighCount GT 0>
						<cfset extendedResult = reportExtended(foundHighCount=foundHighCount,foundHighAscii=foundHighAscii,foundMultiByte=foundMultiByte,linkTarget='/tools/BulkloadAgents.cfm',inHeader='yes')>	
					</cfif>
				</cfif>
				<!--- identify and provide guidance for some standard failure conditions --->
				<cfif format EQ "DEFAULT"><cfset fmt="CSV: Default Comma Separated values"><cfelse><cfset fmt="#format#"></cfif>
				<cfif Find("#NO_COLUMN_ERR#",cfcatch.message) GT 0>
					<h4 class='mb-3'>#cfcatch.message#</h4>
				<cfelseif Find("#NO_HEADER_ERR#",cfcatch.message) GT 0>
					<h4 class='mb-3'>#cfcatch.message#</h4>
				<cfelseif Find("#COLUMN_ERR#",cfcatch.message) GT 0>
					<h4 class='mb-3'>#cfcatch.message#</h4>
				<cfelseif Find("#DUP_COLUMN_ERR#",cfcatch.message) GT 0>
					<h4 class='mb-3'>#cfcatch.message#</h4>
				<cfelseif Find("IOException reading next record: java.io.IOException: (line 1) invalid char between encapsulated token and delimiter",cfcatch.message) GT 0>
					<h4 class='mb-3'>
						Unable to read headers in line 1.  Does your file actually have the format #fmt#?  Did you select CSV format for a tab delimited file?
					</h4>
				<cfelseif Find("IOException reading next record: java.io.IOException: (line 1)",cfcatch.message) GT 0>
					<h4 class='mb-3'>
						Unable to read headers in line 1.  Is your file actually have the format #fmt#?
					</h4>
					<h4 class='mb-3'>#cfcatch.message#</h4>
				<cfelseif Find("invalid char between encapsulated token and delimiter",cfcatch.message) GT 0>
					<h4 class='mb-3'>
						Does your file have an inconsitent format?  Are some lines tab delimited but others comma delimited?
					</h4>
				<cfelseif Find("IOException reading next record: java.io.IOException:",cfcatch.message) GT 0>
					<h4 class='mb-3'>
						Unable to read a record from the file.  One or more lines may not be consistent with the specified format #fmt#
					</h4>
					<h4 class='mb-3'>#cfcatch.message#</h4>
				<cfelse>
					<cfdump var="#cfcatch#">
				</cfif>
			</cfcatch>

			<cffinally>
				<cftry>
					<!--- Close the CSV parser and the reader --->
					<cfset csvParser.close()>
					<cfset fileReader.close()>
				<cfcatch>
					<!--- consume exception and proceed --->
				</cfcatch>
				</cftry>
			</cffinally>
		</cftry>
		</cfoutput>
	</cfif>
			
	<!------------------------------------------------------->

	<cfif variables.action is "validate">
		<h2 class="h4">Second step: Data Validation</h2>
		<cfoutput>
			<!--- Checks on data without needing to iterate through rows --->
			<cfquery name="invAgntType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE cf_temp_agents
				SET 
					status = concat(nvl2(status, status || '; ', ''),'AGENT_TYPE not valid."</a>')
				WHERE 
					AGENT_TYPE not in (select agent_type from ctagent_type) AND
					username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#"> 
			</cfquery>
			<cfquery name="invBirthDate" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE cf_temp_agents
				SET 
					status = concat(nvl2(status, status || '; ', ''),'BIRTH_DATE not in correct form (yyyy, yyyy-mm, or yyyy-mm-dd)</a>')
				WHERE 
					birth_date IS NOT NULL AND
					IS_ISO8601(birth_date) <> 'valid' AND
					username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#"> 
			</cfquery>
			<cfquery name="invDeathDate" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE cf_temp_agents
				SET 
					status = concat(nvl2(status, status || '; ', ''),'DEATH_DATE not in correct form (yyyy, yyyy-mm, or yyyy-mm-dd)</a>')
				WHERE 
					death_date IS NOT NULL AND
					IS_ISO8601(death_date) <> 'valid' AND
					username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#"> 
			</cfquery>
			<cfloop list="#requiredfieldlist#" index="requiredField">
				<cfquery name="checkRequired" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE cf_temp_agents
					SET 
						status = concat(nvl2(status, status || '; ', ''),'#requiredField# is missing')
					WHERE 
						(#requiredField# is null OR trim(#requiredField#) IS NULL) AND
						username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
			</cfloop>
			<cfquery name="checkLastName" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" >
				UPDATE cf_temp_agents
				SET 
					status = concat(nvl2(status, status || '; ', ''), 'LAST_NAME is required if AGENT_TYPE is person')
				WHERE 
					agent_type = 'person' AND
					last_name IS NULL AND
					username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="checkNonPerson" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" >
				UPDATE cf_temp_agents
				SET 
					status = concat(nvl2(status, status || '; ', ''), 'FIRST_NAME, MIDDLE_NAME, LAST_NAME, PREFIX, and SUFFIX must be empty if AGENT_TYPE is not person')
				WHERE 
					agent_type <> 'person' AND
					(
						first_name IS NOT NULL OR
						middle_name IS NOT NULL OR
						last_name IS NOT NULL OR
						prefix IS NOT NULL OR
						suffix IS NOT NULL
					) AND 
					username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="dupName" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" >
				UPDATE cf_temp_agents
				SET 
					status = concat(nvl2(status, status || '; ', ''), 'An agent with PREFERRED_NAME [' || preferred_name || '] already exists')
				WHERE 
					preferred_name in (
						select agent_name from preferred_agent_name
					) AND
					username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="invGuidType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE cf_temp_agents
				SET 
					status = concat(nvl2(status, status || '; ', ''), 'A valid AGENTGUID_GUID_TYPE was not provided - check <a href="/vocabularies/ControlledVocabulary.cfm?table=CTGUID_TYPE">controlled vocabulary</a>')
				WHERE 
					AGENTGUID_GUID_TYPE not in (select guid_type from ctguid_type) AND 
					AGENTGUID_GUID_TYPE IS NOT NULL AND 
					username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="duplicateGuid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE cf_temp_agents
				SET 
					status = concat(nvl2(status, status || '; ', ''), 'An Agent record with this AGENTGUID already exists')
				WHERE 
					AGENTGUID_GUID_TYPE in (select guid_type from ctguid_type) AND 
					AGENTGUID IS NOT NULL AND 
					AGENTGUID IN (
						SELECT agentguid FROM agent WHERE agentguid IS NOT NULL 	
					) AND 
					username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfloop from="1" to="#NUMBER_OF_OTHER_NAME_PAIRS#" index="i">
				<cfquery name="invNAMEType1" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE cf_temp_agents
					SET 
						status = concat(nvl2(status, status || '; ', ''), 'A *valid* OTHER_NAME_TYPE_#i# was not provided - check <a href="/vocabularies/ControlledVocabulary.cfm?table=CTAGENT_NAME_TYPE">controlled vocabulary</a>')
					WHERE 
						OTHER_NAME_TYPE_#i# not in (select AGENT_NAME_TYPE from CTAGENT_NAME_TYPE) AND 
						OTHER_NAME_TYPE_#i# IS NOT NULL AND 
						username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cfquery name="invNAMEType1" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE cf_temp_agents
					SET 
						status = concat(nvl2(status, status || '; ', ''),'An OTHER_NAME_TYPE_#i# was not provided for OTHER_NAME_#i#')
					WHERE 
						OTHER_NAME_TYPE_#i# IS NULL AND 
						OTHER_NAME_#i# IS NOT NULL AND 
						username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cfquery name="invNAMEType1" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE cf_temp_agents
					SET 
						status = concat(nvl2(status, status || '; ', ''),'An OTHER_NAME_#i# was not provided with OTHER_NAME_TYPE_#i#')
					WHERE 
						OTHER_NAME_TYPE_#i# IS NOT NULL AND 
						OTHER_NAME_#i# IS NULL AND 
						username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
			</cfloop>
			<cfquery name="invAgntSuffix" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE cf_temp_agents
				SET 
					status = concat(nvl2(status, status || '; ', ''), 'SUFFIX not valid - check <a href="/vocabularies/ControlledVocabulary.cfm?table=CTSUFFIX">controlled vocabulary</a>')
				WHERE 
					SUFFIX not in (select suffix from ctsuffix)
					AND SUFFIX IS NOT NULL
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="invAgntPrefix" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE cf_temp_agents
				SET 
					status = concat(nvl2(status, status || '; ', ''),'PREFIX not valid - check <a href="/vocabularies/ControlledVocabulary.cfm?table=CTPREFIX">controlled vocabulary</a>')
				WHERE 
					PREFIX not in (select PREFIX from CTPREFIX)
					AND PREFIX IS NOT NULL
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="invGuidTypeGuid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE cf_temp_agents
				SET 
					status = concat(nvl2(status, status || '; ', ''),'AGENTGUID provided without a valid AGENTGUID_GUID_TYPE')
				WHERE 
					AGENTGUID_GUID_TYPE not in (select guid_type from ctguid_type)
					AND AGENTGUID_GUID_TYPE IS NOT NULL
					AND AGENTGUID IS NOT NULL
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="noGuidTypeGuid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE cf_temp_agents
				SET 
					status = concat(nvl2(status, status || '; ', ''),'AGENTGUID and AGENTGUID_GUID_TYPE must both be provided or blank')
				WHERE 
					(
						AGENTGUID_GUID_TYPE IS NULL
						AND AGENTGUID IS NOT NULL
					) OR ( 
						AGENTGUID_GUID_TYPE IS NOT NULL
						AND AGENTGUID IS NULL
					)
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>

			<!--- validation checks iterating through input rows --->
			<cfset key = ''>
			<cfset i = 1>
			<cfquery name="getTempData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT 
					key,
					birth_date, agent_type, preferred_name, first_name, middle_name, last_name,
					death_date, agent_remark, prefix, suffix,
					<cfloop from="1" to="#NUMBER_OF_OTHER_NAME_PAIRS#" index="i">
						other_name_#i#,other_name_type_#i#,
					</cfloop>
					agentguid_guid_type,agentguid,status
				FROM 
					cf_temp_agents
				WHERE 
					username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfloop query="getTempData">
				<cfif len(getTempData.agentguid) gt 0 AND len(getTempData.agentguid_guid_type) gt 0>
					<cfquery name="getPattern" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						SELECT 
							pattern_regex 
						FROM 
							ctguid_type 
						WHERE
							guid_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.agentguid_guid_type#">
					</cfquery>
					<cfif getPattern.recordcount GT 0>
						<cfif REFind(getPattern.pattern_regex,getTempData.agentguid) EQ 0>
							<cfquery name="invGuidType2" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
								UPDATE cf_temp_agents
								SET 
									status = concat(nvl2(status, status || '; ', ''),'AGENTGUID is not in the correct format for ' || agentguid_guid_type || ' expected pattern is #getPattern.pattern_regex#')
								WHERE 
									username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#"> AND
									key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#key#">
							</cfquery>
						</cfif>
					</cfif>
				</cfif>
			</cfloop>
			
			<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT 
					agent_type, preferred_name,first_name,middle_name,last_name,
					prefix,suffix,
					birth_date, death_date,
					agent_remark, biography,
					<cfloop from="1" to="#NUMBER_OF_OTHER_NAME_PAIRS#" index="i">
						other_name_#i#,other_name_type_#i#,
					</cfloop>
					agentguid_guid_type,agentguid,status
				FROM 
					cf_temp_agents
				WHERE 
					username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="pf" dbtype="query">
				SELECT count(*) c 
				FROM data 
				WHERE status is not null
			</cfquery>
			<h3 class="mt-3">
				<cfif pf.c gt 0>
					There is a problem with #pf.c# of #data.recordcount# row(s). See the STATUS column. (<a href="/tools/BulkloadAgents.cfm?action=dumpProblems">download</a>). Fix the problems in the data and <a href="/tools/BulkloadAgents.cfm" class="text-danger">start again</a>.
				<cfelse>
					<span class="text-success">Validation checks passed</span>. Look over the table below and <a href="/tools/BulkloadAgents.cfm?action=load" class="btn-link font-weight-lessbold">click to continue</a> if it all looks good or <a href="/tools/BulkloadAgents.cfm" class="text-danger">start again</a>.
				</cfif>
			</h3>
			<table class='sortable px-0 mx-0 table small table-responsive table-striped w-100'>
				<thead>
					<tr>
						<th>BULKLOADING&nbsp;STATUS</th>
						<th>AGENT_TYPE</th>
						<th>PREFERRED_NAME</th>
						<th>PREFIX</th>
						<th>FIRST_NAME</th>
						<th>MIDDLE_NAME</th>
						<th>LAST_NAME</th>
						<th>SUFFIX</th>
						<th>BIRTH_DATE</th>
						<th>DEATH_DATE</th>
						<th>AGENT_REMARK</th>
						<cfloop from="1" to="#NUMBER_OF_OTHER_NAME_PAIRS#" index="i">
							<th>OTHER_NAME_#i#</th>
							<th>OTHER_NAME_TYPE_#i#</th>
						</cfloop>
						<th>AGENTGUID_GUID_TYPE</th>
						<th>AGENTGUID</th>
						<th>BIOGRAPHY</th>
					</tr>
				<tbody>
					<cfloop query="data">
						<tr>
							<td><cfif len(data.status) eq 0>Cleared to load<cfelse><strong>#data.status#</strong></cfif></td>
							<td>#data.AGENT_TYPE#</td>
							<td>#data.PREFERRED_NAME#</td>
							<td>#data.PREFIX#</td>
							<td>#data.FIRST_NAME#</td>
							<td>#data.MIDDLE_NAME#</td>
							<td>#data.LAST_NAME#</td>
							<td>#data.SUFFIX#</td>
							<td>#data.BIRTH_DATE#</td>
							<td>#data.DEATH_DATE#</td>
							<td>#data.AGENT_REMARK#</td>
							<cfloop from="1" to="#NUMBER_OF_OTHER_NAME_PAIRS#" index="i">
								<td>#evaluate("data.OTHER_NAME_"&i)#</td>
								<td>#evaluate("data.OTHER_NAME_TYPE_"&i)#</td>
							</cfloop>
							<td>#data.agentguid_guid_type#</td>
							<td>#data.agentguid#</td>
							<td>#data.biography#</td>
						</tr>
					</cfloop>
				</tbody>
			</table>
		</cfoutput>
	</cfif>
	<!-------------------------------------------------------------------------------------------->
	<cfif variables.action is "load">
		<h2 class="h4 mb-3">Third step: Apply changes.</h2>
		<cfoutput>
			<cfset problem_key = "">
			<cfset agent_id_list = "">
			<cftransaction>
				<cfquery name="getTempData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT 
						key, 
						birth_date,
						death_date,
						agent_type, preferred_name, first_name, middle_name, last_name,
						prefix, suffix,
						agent_remark, biography, 
						<cfloop from="1" to="#NUMBER_OF_OTHER_NAME_PAIRS#" index="i">
							other_name_#i#,other_name_type_#i#,
						</cfloop>
						agentguid_guid_type, agentguid
					FROM cf_temp_agents
					WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cftry>
					<cfset agent_updates = 0>
					<cfif getTempData.recordcount EQ 0>
						<cfthrow message="You have no rows to load in the agents bulkloader table (cf_temp_agents).  <a href='/tools/BulkloadAgents.cfm' class='text-danger'>Start again</a>"><!--- " --->
					</cfif>
					<cfloop query="getTempData">
						<cfset problem_key = #getTempData.key#>
						<cfquery name="newAgents" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="insResult">
							insert into agent (
								AGENT_ID, 
								AGENT_TYPE, 
								AGENT_REMARKS, 
								PREFERRED_AGENT_NAME_ID,
								AGENTGUID_GUID_TYPE,
								AGENTGUID,
								BIOGRAPHY
							) values (
								sq_agent_id.nextval,
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.agent_type#">,
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.agent_remark#">,
								sq_agent_name_id.nextval,
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.agentguid_guid_type#">,
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.agentguid#">,
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.biography#">
							)
						</cfquery>
						<cfquery name="savePK" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="pkResult">
							SELECT preferred_agent_name_id, agent_id 
							FROM agent
							WHERE ROWIDTOCHAR(rowid) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#insResult.GENERATEDKEY#">
						</cfquery>
						<cfset agent_id_list = ListAppend(agent_id_list,savePK.agent_id) >
						<cfquery name="newPrefAgentName" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="insResult">
							INSERT into agent_name (
								AGENT_NAME_ID, 
								AGENT_ID, 
								AGENT_NAME_TYPE, 
								AGENT_NAME
							) values (
								#savePK.preferred_agent_name_id#,
								#savePK.agent_ID#,
								'preferred',
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.preferred_name#">
							)
						</cfquery>
						<cfset agentNAMEID = #savePK.preferred_agent_name_id#>
						<cfif #agent_type# is "person">
							<cfquery name="newPerson" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
								INSERT into person (
									PERSON_ID,
									PREFIX,
									LAST_NAME,
									FIRST_NAME,
									MIDDLE_NAME,
									SUFFIX,
									BIRTH_DATE,
									DEATH_DATE
								) values (
									#savePK.agent_id#,
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#PREFIX#">,
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#LAST_NAME#">,
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#FIRST_NAME#">,
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#MIDDLE_NAME#">,
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#SUFFIX#">,
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#birth_date#">,
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#death_date#">
								)
							</cfquery>
						</cfif>
						<cfloop from="1" to="#NUMBER_OF_OTHER_NAME_PAIRS#" index="i">
							<cfif len(evaluate("OTHER_NAME_"&i)) gt 0>
								<cfset nametype = evaluate("OTHER_NAME_TYPE_"&i)>
								<cfset name = evaluate("OTHER_NAME_"&i)>
								<cfquery name="newAgentName" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									insert into agent_name (
										AGENT_NAME_ID,
										AGENT_ID,
										AGENT_NAME_TYPE,
										AGENT_NAME 
									) values (
										SQ_AGENT_NAME_ID.NEXTVAL,
										<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#savePK.agent_id#">,
										<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#nametype#">,
										<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#name#">
									)
								</cfquery>
							</cfif>
						</cfloop>
						<cfif pkResult.recordcount gt 1>
							<cfthrow message="Error: Attempting to insert a duplicate agent">
						</cfif>
						<cfset agent_updates = agent_updates + pkResult.recordcount>
					</cfloop>
					<p>Number of agents added: #agent_updates# </p>
					<cfif getTempData.recordcount eq agent_updates and pkResult.recordcount eq 1>
						<h3 class="text-success">Success - loaded</h3>
					</cfif>
					<cftransaction action="commit">
					<cfif agent_updates GT 0>
						<h3><a href="/Agents.cfm?execute=true&method=getAgents&agent_id=#agent_id_list#">View New Agent Records</a></h3>
					</cfif>
					<!--- TODO: Link to agents --->
				<cfcatch>
					<cftransaction action="ROLLBACK">
					<h3>There was a problem updating the agents. </h3>
					<cfquery name="getProblemData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						SELECT 
							agent_type, preferred_name, first_name, middle_name, last_name,
							prefix, suffix,
							birth_date, death_date, 
							agent_remark, biography,
							<cfloop from="1" to="#NUMBER_OF_OTHER_NAME_PAIRS#" index="i">
								other_name_#i#,other_name_type_#i#,
							</cfloop>
							agentguid_guid_type,agentguid
						FROM cf_temp_agents
						WHERE key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#problem_key#">
					</cfquery>
					<cfif getProblemData.recordcount GT 0>
						<h3>
							Fix the issues and <a href="/tools/BulkloadAgents.cfm" class="text-danger font-weight-lessbold">start again</a>. Error loading row (<span class="text-danger">#agent_updates + 1#</span>) from the CSV: 
							<cfif len(cfcatch.detail) gt 0>
								<span class="font-weight-normal border-bottom border-danger">
									<cfif cfcatch.detail contains "birth_date">
										Problem with BIRTH_DATE
									<cfelseif cfcatch.detail contains "agent_type">
										Invalid or missing AGENT_TYPE
									<cfelseif cfcatch.detail contains "preferred_name">
										Invalid PREFERRED_NAME
									<cfelseif cfcatch.detail contains "first_name">
										Invalid FIRST_NAME
									<cfelseif cfcatch.detail contains "last_name">
										Problem with LAST_NAME
									<cfelseif cfcatch.detail contains "agentguid">
										Invalid AGENTGUID
									<cfelseif cfcatch.detail contains "agentguid_guid_type">
										Invalid AGENT GUID TYPE
									<cfelseif cfcatch.detail contains "prefix">
										Invalid PREFIX
									<cfelseif cfcatch.detail contains "suffix">
										Invalid SUFFIX
									<cfelseif cfcatch.detail contains "agent_id">
										Problem with AGENT_ID
									<cfelseif cfcatch.detail contains "unique constraint">
										This agent has already been entered. Remove from spreadsheet and try again.
									<cfelseif cfcatch.detail contains "no data">
										No data or the wrong data (#cfcatch.detail#)
									<cfelse>
										<!--- provide the raw error message if it isn't readily interpretable --->
										#cfcatch.detail#
									</cfif>
								</span>
							</cfif>
						</h3>
						<table class='px-0 sortable small table table-responsive table-striped w-100 mt-3'>
							<thead>
								<tr>
									<th>COUNT</th>
									<th>AGENT_TYPE</th>
									<th>PREFERRED_NAME</th>
									<th>PREFIX</th>
									<th>FIRST_NAME</th>
									<th>MIDDLE_NAME</th>
									<th>LAST_NAME</th>
									<th>SUFFIX</th>
									<th>BIRTH_DATE</th>
									<th>DEATH_DATE</th>
									<th>AGENT_REMARK</th>
									<cfloop from="1" to="#NUMBER_OF_OTHER_NAME_PAIRS#" index="i">
										<th>OTHER_NAME_#i#</th>
										<th>OTHER_NAME_TYPE_#i#</th>
									</cfloop>
									<th>AGENTGUID_GUID_TYPE</th>
									<th>AGENTGUID</th>
									<th>BIOGRAPHY</th>
								</tr> 
							</thead>
							<tbody>
								<cfset i=1>
								<cfloop query="getProblemData">
									<tr>
										<td>#i#</td>
										<td>#getProblemData.AGENT_TYPE# </td>
										<td>#getProblemData.PREFERRED_NAME# </td>
										<td>#getProblemData.PREFIX# </td>
										<td>#getProblemData.FIRST_NAME#</td>
										<td>#getProblemData.MIDDLE_NAME#</td>
										<td>#getProblemData.LAST_NAME#</td>
										<td>#getProblemData.SUFFIX#</td>
										<td>#getProblemData.BIRTH_DATE# </td>
										<td>#getProblemData.DEATH_DATE#</td>
										<td>#getProblemData.AGENT_REMARK# </td>
										<cfloop from="1" to="#NUMBER_OF_OTHER_NAME_PAIRS#" index="i">
											<td>#evaluate("getProblemData.OTHER_NAME_"&i)#</td>
											<td>#evaluate("getProblemData.OTHER_NAME_TYPE_"&i)#</td>
										</cfloop>
										<td>#getProblemData.AGENTGUID_GUID_TYPE#</td>
										<td>#getProblemData.AGENTGUID#</td>
										<td>#getProblemData.BIOGRAPHY# </td>
									</tr>
									<cfset i= i+1>
								</cfloop>
							</tbody>
						</table>
					</cfif>
					<div>#cfcatch.message#</div>
					<!--- Always provide global admins with a dump --->
					<cfif isdefined("session.roles") and listfindnocase(session.roles,"global_admin")>
						<cfdump var="#cfcatch#">
					</cfif>
				</cfcatch>
				</cftry>
			</cftransaction>
			<cfquery name="clearTempTable" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="clearTempTable_result">
				DELETE FROM cf_temp_agents
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
		</cfoutput>
	</cfif>
</main>
<cfinclude template="/shared/_footer.cfm">
