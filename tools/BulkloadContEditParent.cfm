<!--- tools/bulkloadContEditParent.cfm to move containers to new parents in bulk.

Copyright 2008-2017 Contributors to Arctos
Copyright 2008-2024 President and Fellows of Harvard College

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
<!--- special case handling to dump problem data as csv --->
<cfif isDefined("action") AND action is "dumpProblems">
	<cfquery name="getProblemData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		SELECT container_unique_id,parent_unique_id,container_type,container_name, 
			description, remarks, width, height, length, number_positions,
			status 
		FROM cf_temp_cont_edit 
		WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
	</cfquery>
	<cfinclude template="/shared/component/functions.cfc">
	<cfset csv = queryToCSV(getProblemData)>
	<cfheader name="Content-Type" value="text/csv; charset=utf-8">
	<cfoutput>#csv#</cfoutput>
	<cfabort>
</cfif>
<!--- end special case dump of problems --->

<cfset fieldlist = "container_unique_id,parent_unique_id,container_type,container_name,description,remarks,width,height,length,number_positions">
<cfset fieldTypes ="CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_DECIMAL,CF_SQL_DECIMAL,CF_SQL_DECIMAL,CF_SQL_DECIMAL">
<cfset requiredfieldlist = "container_unique_id,container_type,container_name">

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
<cfset pageTitle = "Bulk Edit Container">
<cfinclude template="/shared/_header.cfm">
<cfinclude template="/tools/component/csv.cfc" runOnce="true"><!--- for common csv testing functions --->
<cfif not isDefined("action") OR len(action) EQ 0><cfset action="entryPoint"></cfif>
<main class="container-fluid py-3 px-xl-5" id="content">
	<h1 class="h2 mt-2">Bulkload Container Edit Parent</h1>
	<cfif #action# is "entryPoint">
		<cfoutput>
			<p>This tool is used to edit container information and/or move parts to a different parent container. Upload a comma-delimited text file (csv).  Include column headings, spelled exactly as below.  Additional colums will be ignored. The container_unique_id, container_name, and parent_unique_id fields take a mix of text, hyphens, underscores, and numbers. (Numbers should match values in MCZbase.) Only number entries are expected in the width, height, length, and number_positions fields.</p>
			<p>The container_unique_id is the container's unique identifier to update. All other values provided will change this record. Specify the current value for container type and container name if you wish to avoid changing those, leave others blank to retain current values. To place a container in a new parent container, specify the Unique Identifier for the new parent container in parent_unique_id. Check the Help > Controlled Vocabulary page and select the <a href="/vocabularies/ControlledVocabulary.cfm?table=CTCONTAINER_TYPE">CTCONTAINER_TYPE</a> list for types. Submit a bug report to request an additional type when needed.</p>
			<span class="btn btn-xs btn-info" onclick="document.getElementById('template').style.display='block';">View template</span>
			<div id="template" style="display:none;margin: 1em 0;">
				<label for="templatearea" class="data-entry-label">
					Copy this header line and save it as a .csv file (<a href="/tools/BulkloadContEditParent.cfm?action=getCSVHeader" class="font-weight-lessbold">download</a>)
				</label>
				<textarea rows="2" cols="90" id="templatearea" class="w-100 data-entry-textarea">#fieldlist#</textarea>
			</div>
			<h2 class="mt-4 h4">Columns in <span class="text-danger">red</span> are required; others are optional:</h2>
			<ul class="mb-4 h5 font-weight-normal list-group mx-3">
				<cfloop list="#fieldlist#" index="field" delimiters=",">
					<cfquery name = "getComments"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#"  result="getComments_result">
						SELECT comments
						FROM sys.all_col_comments
						WHERE 
							owner = 'MCZBASE'
							and table_name = 'CF_TEMP_CONT_EDIT'
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

			<form name="atts" method="post" enctype="multipart/form-data" action="/tools/BulkloadContEditParent.cfm">
				<div class="form-row border rounded p-2">
					<input type="hidden" name="action" value="getFile">
					<div class="col-12 col-md-4">
						<label for="fileToUpload" class="data-entry-label">File to bulkload:</label> 
						<input type="file" name="FileToUpload" id="fileToUpload" class="data-entry-input p-0 m-0">
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
		</cfoutput>
	</cfif>
	<!------------------------------------------------------->
	<cfif #action# is "getFile">
		<cfoutput>
			<h2 class="h4">First step: Reading data from CSV file.</h2>
			<!--- Compare the numbers of headers expected against provided in CSV file --->
			<!--- Set some constants to identify error cases in cfcatch block --->
			<cfset NO_COLUMN_ERR = "One or more required fields are missing in the header line of the csv file. Check charset selected if columns match required headers and one column is not found.">
			<cfset DUP_COLUMN_ERR = "One or more columns are duplicated in the header line of the csv file.">
			<cfset COLUMN_ERR = "Error inserting data.">
			<cfset NO_HEADER_ERR = "No header line found, csv file appears to be empty.">
			<cfset TABLE_NAME = "CF_TEMP_CONT_EDIT">
			<cftry>
				<!--- cleanup any incomplete work by the same user --->
				<cfquery name="clearTempTable" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="clearTempTable_result">
					DELETE FROM cf_temp_cont_edit
					WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>

				<cfset variables.foundHeaders =""><!--- populated by loadCsvFile --->
				<cfset variables.size=""><!--- populated by loadCsvFile --->
				<cfset iterator = loadCsvFile(FileToUpload=FileToUpload,format=format,characterSet=characterSet)>

				<!--- Note: As we can't use csvFormat.withHeader(), we can not match columns by name, we are forced to do so by number, thus arrays --->
				<cfset colNameArray = listToArray(ucase(variables.foundHeaders))><!--- the list of columns/fields found in the input file --->
				<cfset fieldArray = listToArray(ucase(fieldlist))><!--- the full list of fields --->
				<cfset typeArray = listToArray(fieldTypes)><!--- the types for the full list of fields --->
				<div class="col-12 px-0 my-4">
					<h3 class="h4">Found #variables.size# columns in header of csv file.</h3>
					<h3 class="h4">There are #ListLen(fieldList)# columns expected in the header (of these #ListLen(requiredFieldList)# are required).</h3>
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
						<cfset thisBit = "#rowData.get(JavaCast("int",i))#" >
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
							insert into cf_temp_cont_edit
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
						<cfset error_message="Check character set and format selected. #COLUMN_ERR# from line #row# in input file.  <br>Header:[#colNames#] <br>Row:[#ArrayToList(collValuesArray)#] <br>Error: #cfcatch.message#"><!--- " --->
						<cfif isDefined("cfcatch.queryError")>
							<cfset error_message = "#error_message# #cfcatch.queryError#">
						</cfif>
						<cfthrow message = "#error_message#">
					</cfcatch>
					</cftry>
				</cfloop>

				<cfif foundHighCount GT 0>
					<cfset extendedResult = reportExtended(foundHighCount=foundHighCount,foundHighAscii=foundHighAscii,foundMultiByte=foundMultiByte,linkTarget='/tools/BulkloadContEditParent.cfm')>
				</cfif>
				<h3>
					<cfif loadedRows EQ 0>
						Loaded no rows from the CSV file.  The file appears to be just a header with no data. Fix file and <a href="/tools/BulkloadContEditParent.cfm">reload</a>
					<cfelse>
						Successfully read #loadedRows# records from the CSV file. Next <a href="/tools/BulkloadContEditParent.cfm?action=validate">click to validate</a>.
					</cfif>
				</h3>
			<cfcatch>
				<h3>
					<span class="text-danger">Failed to read the CSV file.</span> Fix the errors in the file and <a href="/tools/BulkloadContEditParent.cfm">reload</a>
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
						<cfset extendedResult = reportExtended(foundHighCount=foundHighCount,foundHighAscii=foundHighAscii,foundMultiByte=foundMultiByte,linkTarget='/tools/BulkloadContEditParent.cfm',inHeader='yes')>	
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
	<cfif #action# is "validate">
		<cfoutput>
			<h2 class="h4 mb-4">Second step: Data Validation</h2>
				<cfquery name="getCID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					update cf_temp_cont_edit set container_id=
					(select container_id from container where container.barcode = cf_temp_cont_edit.container_unique_id)
					WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cfquery name="getCID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					update cf_temp_cont_edit set parent_container_id=
					(select container_id from container where container.barcode = cf_temp_cont_edit.parent_unique_id)
					WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cfquery name="miac" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE cf_temp_cont_edit 
					SET status = concat(nvl2(status, status || '; ', ''), 'container_not_found, no Unique Identifier found matching [' || container_unique_id || '].')
					WHERE container_id is null
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cfquery name="miap" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE cf_temp_cont_edit 
					SET status = concat(nvl2(status, status || '; ', ''),'parent_container_not_found, no Unique Identifier found matching ['|| parent_unique_id ||']')
					WHERE parent_container_id is null and parent_unique_id is not null
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cfquery name="miap" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE cf_temp_cont_edit 
					SET status = concat(nvl2(status, status || '; ', ''),'bad_container_type ['||container_type||'], container_type must be in the CTCONTAINER_TYPE controlled vocabulary.')
					WHERE container_type not in (select container_type from ctcontainer_type)
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cfquery name="miap" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE cf_temp_cont_edit
					SET status = concat(nvl2(status, status || '; ', ''), 'missing_label, container_name is required.')
					WHERE CONTAINER_NAME is null
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
			
				<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT CONTAINER_UNIQUE_ID, PARENT_UNIQUE_ID, CONTAINER_TYPE, CONTAINER_NAME, DESCRIPTION, REMARKS, WIDTH,
						HEIGHT, LENGTH, NUMBER_POSITIONS, CONTAINER_ID, PARENT_CONTAINER_ID, STATUS 
					FROM cf_temp_cont_edit
					WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cfquery name="pf" dbtype="query">
					SELECT count(*) c 
					FROM data 
					WHERE status is not null
				</cfquery>
				<h3 class="mt-3">
					<cfif pf.c gt 0>
						There is a problem with #pf.c# of #data.recordcount# row(s) (<a href="/tools/BulkloadContEditParent.cfm?action=dumpProblems">download</a>). See the STATUS column. Fix the problems in the data and <a href="/tools/BulkloadContEditParent.cfm" class="text-danger">start again</a>.
					<cfelse>
						<span class="text-success">Validation checks passed.</span> Look over the table below and <a href="/tools/BulkloadContEditParent.cfm?action=load" class="btn-link font-weight-lessbold">click to continue</a> if it all looks good. Or, <a href="/tools/BulkloadContEditParent.cfm" class="text-danger">start again</a>.
					</cfif>
				</h3>
				<table class='px-0 sortable small table table-responsive table-striped d-lg-table'>
				<thead class="thead-light">
					<tr>
						<th>STATUS</th>
						<th>CONTAINER_UNIQUE_ID</th>
						<th>PARENT_UNIQUE_ID</th>
						<th>CONTAINER_TYPE</th>
						<th>CONTAINER_NAME</th>
						<th>DESCRIPTION</th>
						<th>REMARKS</th>
						<th>WIDTH</th>
						<th>HEIGHT</th>
						<th>LENGTH</th>
						<th>NUMBER_POSITIONS</th>
						<th>CONTAINER_ID</th>
						<th>PARENT_CONTAINER_ID</th>
					</tr>
				<tbody>
					<cfloop query="data">
						<tr>
							<td><cfif len(data.status) eq 0>Cleared to load<cfelse><strong>#data.status#</strong></cfif></td>
							<td>#data.CONTAINER_UNIQUE_ID#</td>
							<td>#data.PARENT_UNIQUE_ID#</td>
							<td>#data.CONTAINER_TYPE#</td>
							<td>#data.CONTAINER_NAME#</td>
							<td>#data.DESCRIPTION#</td>
							<td>#data.REMARKS#</td>
							<td>#data.WIDTH#</td>
							<td>#data.HEIGHT#</td>
							<td>#data.LENGTH#</td>
							<td>#data.NUMBER_POSITIONS#</td>
							<td>#data.CONTAINER_ID#</td>
							<td>#data.PARENT_CONTAINER_ID#</td>
						</tr>
					</cfloop>
				</tbody>
			</table>
		</cfoutput>
	</cfif>
	<!-------------------------------------------------------------------------------------------->
	<cfif action is "load">
		<h2 class="h4">Third step: Apply changes.</h2>
		<cfoutput>
			<cftransaction>
				<cfquery name="getTempData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT * FROM cf_temp_cont_edit
					WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cftry>
					<cfset stage = "containerType"> 
					<cfset container_type_updates = 0>
					<cfset problem_key = "">
					<cfloop query="getTempData">
						<cfset problem_key = getTempData.key>
						<cfquery name="updateContainer" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="updateContainer_result">
							UPDATE
								container 
							SET
								CONTAINER_TYPE= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#CONTAINER_TYPE#">
							WHERE
								CONTAINER_ID= <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#CONTAINER_ID#">
						</cfquery>
						<cfset container_type_updates = container_type_updates + updateContainer_result.recordcount>
					</cfloop>
					<cfset problem_key = "">
					<cfset stage = "containerUpdate"> 
					<cfset container_updates = 0>
					<cfloop query="getTempData">
						<cfset problem_key = getTempData.key>
						<cfquery name="updateContainer" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="updateContainer_result">
							UPDATE
								container 
							SET
								label=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#CONTAINER_NAME#">,
								DESCRIPTION=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#DESCRIPTION#">,
								PARENT_INSTALL_DATE=sysdate,
								CONTAINER_REMARKS=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#remarks#">
								<cfif len(#WIDTH#) gt 0>
									,WIDTH=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#WIDTH#">
								</cfif>
								<cfif len(#HEIGHT#) gt 0>
									,HEIGHT=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#HEIGHT#">
								</cfif>
								<cfif len(#LENGTH#) gt 0>
									,LENGTH=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#LENGTH#">
								</cfif>
								<cfif len(#NUMBER_POSITIONS#) gt 0>
									,NUMBER_POSITIONS=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#NUMBER_POSITIONS#">
								</cfif>
								<cfif len(#parent_container_id#) gt 0>
									,parent_container_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#parent_container_id#">
								</cfif>
							WHERE
								CONTAINER_ID=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#CONTAINER_ID#">
						</cfquery>
						<cfset container_updates = container_updates + updateContainer_result.recordcount>
					</cfloop>
					<cftransaction action="commit">
				<cfcatch>
					<cftransaction action="rollback">
					<cfif stage="containerType">
						<h3>There was a problem updating container types.</h3>
					<cfelse>
						<h3>There was a problem updating the containers.</h3>
					</cfif>
					<cfquery name="getProblemData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						SELECT container_unique_id,parent_unique_id,container_type,container_name, status 
						FROM cf_temp_cont_edit 
						WHERE key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#problem_key#">
					</cfquery>
					<h3>Error updating row (#container_updates + 1#): #cfcatch.message#</h3>
					<table class='sortable table table-responsive table-striped d-lg-table'>
						<thead>
							<tr>
								<th>BULKLOADING&nbsp;STATUS</th>
								<th>container_unique_id</th>
								<th>parent_unique_id</th>
								<th>container_type</th>
								<th>container_name</th>
							</tr> 
						</thead>
						<tbody>
							<cfloop query="getProblemData">
								<tr>
									<td><cfif len(data.status) eq 0>Cleared to load<cfelse><strong>#getProblemData.status#</strong></cfif></td>
									<td>#getProblemData.container_unique_id#</td>
									<td>#getProblemData.parent_unique_id#</td>
									<td>#getProblemData.container_type#</td>
									<td>#getProblemData.container_name#</t
								></tr> 
							</cfloop>
						</tbody>
					</table>
				</cfcatch>
				</cftry>
			</cftransaction>
			<cfif container_updates GT 1><cfset plural="s"><cfelse><cfset plural=""></cfif>
			<h3 class="mt-4">Updated #container_updates# container#plural#.</h3>
			<h3 class="text-success">Success, changes applied.</h3>
			<!--- cleanup --->
			<cfquery name="clearTempTable" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="clearTempTable_result">
				DELETE FROM cf_temp_cont_edit 
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
		</cfoutput>
	</cfif>
</main>
<cfinclude template="/shared/_footer.cfm">
