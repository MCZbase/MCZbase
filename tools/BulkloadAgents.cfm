<!--- tools/bulkloadAgents.cfm add agents to specimens in bulk.

Copyright 2008-2017 Contributors to Arctos
Copyright 2008-2023 President and Fellows of Harvard College

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
		SELECT agent_type,preferred_name,first_name,middle_name,last_name,birth_date,death_date,agent_remark,prefix,suffix,other_name_type,other_name,other_name_type_2,other_name_2,other_name_type_3,other_name_3,agentguid_guid_type,agentguid 
		FROM cf_temp_agents 
		WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
	</cfquery>
	<cfinclude template="/shared/component/functions.cfc">
	<cfset csv = queryToCSV(getProblemData)>
	<cfheader name="Content-Type" value="text/csv">
	<cfoutput>#csv#</cfoutput>
	<cfabort>
</cfif>
<!--- end special case dump of problems --->

<cfset fieldlist = "agent_type,preferred_name,first_name,middle_name,last_name,birth_date,death_date,agent_remark,prefix,suffix,other_name_type,other_name,other_name_type_2,other_name_2,other_name_type_3,other_name_3,agentguid_guid_type,agentguid">
<cfset fieldTypes ="CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_DATE,CF_SQL_DATE,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR">
<cfset requiredfieldlist = "agent_type,preferred_name,last_name">

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
<cfset pageTitle = "Bulkload Agents">
<cfinclude template="/shared/_header.cfm">
<cfif not isDefined("action") OR len(action) EQ 0><cfset action="nothing"></cfif>
<main class="container py-3" id="content">
	<h1 class="h2 mt-2">Bulkload Agents</h1>
	<cfif #action# is "nothing">
		<cfoutput>
			<p>This tool is used to bulkload agents.</p>
			<p>Upload a comma-delimited text file (csv).  Include column headings, spelled exactly as below.  Additional colums will be ignored</p>
			<span class="btn btn-xs btn-info" onclick="document.getElementById('template').style.display='block';">View template</span>
			<div id="template my-3 mx-0" style="display:none;">
				<label for="templatearea" class="data-entry-label">
					Copy this header line and save it as a .csv file (<a href="/tools/BulkloadAgents.cfm?action=getCSVHeader">download</a>)
				</label>
				<textarea rows="2" cols="90" id="templatearea" class="w-100 data-entry-textarea">#fieldlist#</textarea>
			</div>
			<h2 class="mt-4 h4">Columns in <span class="text-danger">red</span> are required; others are optional:</h2>
			<ul class="mb-4 h4">
				<cfloop list="#fieldlist#" index="field" delimiters=",">
					<cfset aria = "">
					<cfif listContains(requiredfieldlist,field,",")>
						<cfset class="text-danger">
						<cfset aria = "aria-label='Required Field'">
					<cfelse>
						<cfset class="text-dark">
					</cfif>
					<li class="#class#">#field#</li>
				</cfloop>
			</ul>
			<form name="agts" method="post" enctype="multipart/form-data" action="/tools/BulkloadAgents.cfm">
				<div class="form-row border rounded p-2">
					<input type="hidden" name="action" value="getFile">
					<div class="col-12 col-md-4">
						<label for="fileToUpload" class="data-entry-label">File to bulkload:</label> 
						<input type="file" name="FiletoUpload" id="fileToUpload" class="data-entry-input p-0 m-0">
					</div>
					<div class="col-12 col-md-3">
						<label for="characterSet" class="data-entry-label">Character Set:</label> 
						<select name="characterSet" id="characterSet" required class="data-entry-select reqdClr">
							<option selected></option>
							<option value="utf-8" >utf-8</option>
							<option value="iso-8859-1">iso-8859-1</option>
							<option value="windows-1252">windows-1252 (Win Latin 1)</option>
							<option value="MacRoman">MacRoman</option>
							<option value="x-MacCentralEurope">Macintosh Latin-2</option>
							<option value="windows-1250">windows-1250 (Win Eastern European)</option>
							<option value="windows-1251">windows-1251 (Win Cyrillic)</option>
							<option value="utf-16">utf-16</option>
							<option value="utf-32">utf-32</option>
						</select>
					</div>
					<div class="col-12 col-md-3">
						<label for="format" class="data-entry-label">Format:</label> 
						<select name="format" id="format" required class="data-entry-select reqdClr">
							<option value="DEFAULT" selected >Standard CSV</option>
							<option value="TDF">Tab Separated Values</option>
							<option value="EXCEL">CSV export from MS Excel</option>
							<option value="RFC4180">Strict RFC4180 CSV</option>
							<option value="ORACLE">Oracle SQL*Loader CSV</option>
							<option value="MYSQL">CSV export from MYSQL</option>
						</select>
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
		<h2 class="h3">First step: Reading data from CSV file.</h2>
		<cfoutput>
		<!--- Compare the numbers of headers expected against provided in CSV file --->
		<!--- Set some constants to identify error cases in cfcatch block --->
		<cfset NO_COLUMN_ERR = "One or more required fields are missing in the header line of the csv file.">
		<cfset DUP_COLUMN_ERR = "One or more columns are duplicated in the header line of the csv file.">
		<cfset COLUMN_ERR = "Error inserting data">
		<cfset NO_HEADER_ERR = "No header line found, csv file appears to be empty.">
		
		<cftry>
			<!--- Parse the CSV file using Apache Commons CSV library included with coldfusion so that columns with comma delimeters will be separated properly --->
			<cfset fileProxy = CreateObject("java","java.io.File") >
			<cfobject type="Java" name="csvFormat" class="org.apache.commons.csv.CSVFormat" >
			<cfobject type="Java" name="csvParser" class="org.apache.commons.csv.CSVParser" >
			<cfobject type="Java" name="csvRecord" class="org.apache.commons.csv.CSVRecord" >			
			<cfobject type="java" class="java.io.FileReader" name="fileReader">	
			<cfobject type="Java" name="javaCharset" class="java.nio.charset.Charset" >
			<cfobject type="Java" name="standardCharsets" class="java.nio.charset.StandardCharsets" >
			<cfset filePath = fileProxy.init(JavaCast("string",#FiletoUpload#)) >
			<cfset tempFileInputStream = CreateObject("java","java.io.FileInputStream").Init(#filePath#) >
			<!--- Create a FileReader object to provide a reader for the CSV file --->
			<cfset fileReader = CreateObject("java","java.io.FileReader").Init(#filePath#) >
			<!--- we can not use the withHeader() method from coldfusion, as it is overloaded, and with no parameters provides coldfusion no means to pick the correct method --->
			<!--- Select format of csv file based on format variable from user --->
			<cfif not isDefined("format")><cfset format="DEFAULT"></cfif>
			<cfswitch expression="#format#">
				<cfcase value="DEFAULT">
					<cfset csvFormat = CSVFormat.DEFAULT>
				</cfcase>
				<cfcase value="TDF">
					<cfset csvFormat = CSVFormat.TDF>
				</cfcase>
				<cfcase value="RFC4180">
					<cfset csvFormat = CSVFormat.RFC4180>
				</cfcase>
				<cfcase value="EXCEL">
					<cfset csvFormat = CSVFormat.EXCEL>
				</cfcase>
				<cfcase value="ORACLE">
					<cfset csvFormat = CSVFormat.ORACLE>
				</cfcase>
				<cfcase value="MYSQL">
					<cfset csvFormat = CSVFormat.MYSQL>
				</cfcase>
				<cfdefaultcase>
					<cfset csvFormat = CSVFormat.DEFAULT>
				</cfdefaultcase>
			</cfswitch>
				<!--- Create a CSVParser using the FileReader and CSVFormat--->
			<cfset csvParser = CSVParser.parse(fileReader, csvFormat)>
				<!--- Select charset based on characterSet variable from user --->
			<cfswitch expression="#characterSet#">
					<cfcase value="utf-8">
						<cfset javaSelectedCharset = standardCharsets.UTF_8 >
					</cfcase>
					<cfcase value="iso-8859-1">
						<cfset javaSelectedCharset = standardCharsets.ISO_8859_1 >
					</cfcase>
					<cfcase value="windows-1250">
						<cfset javaSelectedCharset = javaCharset.forName(JavaCast("string","windows-1250")) >
					</cfcase>
					<cfcase value="windows-1251">
						<cfset javaSelectedCharset = javaCharset.forName(JavaCast("string","windows-1251")) >
					</cfcase>
					<cfcase value="windows-1252">
						<cfif javaCharset.isSupported(JavaCast("string","windows-1252"))>
							<cfset javaSelectedCharset = javaCharset.forName(JavaCast("string","windows-1252")) >
						<cfelse>
							<!--- if not available, iso-8859-1 will substitute, except for 0x80 to 0x9F --->
							<!--- the following characters won't be handled correctly if the source is windows-1252:  €  Š  š  Ž  ž  Œ  œ  Ÿ --->
							<cfset javaSelectedCharset = standardCharsets.ISO_8859_1 >
						</cfif>
					</cfcase>
					<cfcase value="x-MacCentralEurope">
						<cfset javaSelectedCharset = javaCharset.forName(JavaCast("string","x-MacCentralEurope")) >
					</cfcase>
					<cfcase value="MacRoman">
						<cfset javaSelectedCharset = javaCharset.forName(JavaCast("string","x-MacRoman")) >
					</cfcase>
					<cfcase value="utf-16">
						<cfset javaSelectedCharset = standardCharsets.UTF_16 >
					</cfcase>
					<cfcase value="utf-32">
						<cfset javaSelectedCharset = javaCharset.forName(JavaCast("string","utf-32")) >
					</cfcase>
					<cfdefaultcase>
						<cfset javaSelectedCharset = standardCharsets.UTF_8 >
					</cfdefaultcase>
				</cfswitch>
				<cfset records = CSVParser.parse(#tempFileInputStream#,#javaSelectedCharset#,#csvFormat#)>

				<!--- cleanup any incomplete work by the same user --->
				<cfquery name="clearTempTable" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="clearTempTable_result">
					DELETE FROM cf_temp_agents 
					WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
					
			<!--- obtain an iterator to loops through the rows/records in the csv --->
				<cfset iterator = records.iterator()>
				<!---Obtain the first line of the file as the header line, we can not use the withHeader() method to do this in coldfusion --->
				<cfif iterator.hasNext()>
					<cfset headers = iterator.next()>
				<cfelse>
					<cfthrow message="#NO_HEADER_ERR# No first line found.">
				</cfif>
				<!---Get the number of column headers--->
				<cfset size = headers.size()>
				<cfif size EQ 0>
					<cfthrow message="#NO_HEADER_ERR# First line appears empty.">
				</cfif>
				<cfset separator = "">
				<cfset foundHeaders = "">
				<cfloop index="i" from="0" to="#headers.size() - 1#">
					<cfset foundHeaders = "#foundHeaders##separator##headers.get(JavaCast("int",i))#" >
					<cfset separator = ",">
				</cfloop>
				<!--- Note: As we can't use csvFormat.withHeader(), we can not match columns by name, we are forced to do so by number, thus arrays --->
				<cfset colNameArray = listToArray(ucase(foundHeaders))><!--- the list of columns/fields found in the input file --->
				<cfset fieldArray = listToArray(ucase(fieldlist))><!--- the full list of fields --->
				<cfset typeArray = listToArray(fieldTypes)><!--- the types for the full list of fields --->

				<div class="col-12 my-4">
					<h3 class="h4">Found #size# columns in header of csv file.</h3>
					<h3 class="h4">There are #ListLen(fieldList)# columns expected in the header (of these #ListLen(requiredFieldList)# are required).</h3>
				</div>
			
				<!--- check for required fields in header line (performng check in two different ways, Case 1, Case 2) --->
				<!--- Loop through list of fields throw exception if required fields are missing --->
				<cfset errorMessage = "">
				<cfloop list="#fieldList#" item="aField">
					<cfif ListContainsNoCase(requiredFieldList,aField)>
						<!--- Case 1. Check by splitting assembled list of foundHeaders --->
						<cfif NOT ListContainsNoCase(foundHeaders,aField)>
							<cfset errorMessage = "#errorMessage# <strong>#aField#</strong> is missing.">
						</cfif>
					</cfif>
				</cfloop>
				<cfif len(errorMessage) GT 0>
					<cfthrow message = "#NO_COLUMN_ERR# #errorMessage#">
				</cfif>
				<cfset errorMessage = "">
				<!--- Loop through list of fields, mark each field as fields present in input or not, throw exception if required fields are missing --->
				<ul class="h4 mb-4">
					<cfloop list="#fieldlist#" index="field" delimiters=",">
						<cfset hint="">
						<cfif listContains(requiredfieldlist,field,",")>
							<cfset class="text-danger">
							<cfset hint="aria-label='required'">
						<cfelse>
							<cfset class="text-dark">
						</cfif>
						<li>
							<span class="#class#" #hint#>#field#</span>
							<cfif arrayFindNoCase(colNameArray,field) GT 0>
								<strong class="text-success">Present in CSV</strong>
							<cfelse>
								<!--- Case 2. Check by identifying field in required field list --->
								<cfif ListContainsNoCase(requiredFieldList,field)>
									<strong class="text-dark">Required Column Not Found</strong>
									<cfset errorMessage = "#errorMessage# <strong>#field#</strong> is missing.">
								</cfif>
							</cfif>
						</li>
					</cfloop>
				</ul>
				<cfif len(errorMessage) GT 0>
					<cfif size EQ 1>
						<!--- likely a problem parsing the first line into column headers --->
						<!--- to get here, upload a csv file with the correct headers as MYSQL format --->
						<cfset errorMessage = "You may have specified the wrong format, only one column header was found. #errorMessage#">
					</cfif>
					<cfthrow message = "#NO_COLUMN_ERR# #errorMessage#">
				</cfif>
				<ul class="py-1 h4 list-unstyled">
					<!--- Identify additional columns that will be ignored --->
					<cfloop list="#foundHeaders#" item="aField">
						<cfif NOT ListContainsNoCase(fieldList,aField)>
							<li>Found additional column header [<strong>#aField#</strong>] in the CSV that is not in the list of expected headers.</1i>
						</cfif>
					</cfloop>
					<!--- Identify duplicate columns and fail if found --->
					<cfif NOT ListLen(ListRemoveDuplicates(foundHeaders)) EQ ListLen(foundHeaders)>
						<li>At least one column header occurs more than once.</1i>
						<cfloop list="#foundHeaders#" item="aField">
							<cfif listValueCount(foundHeaders,aField) GT 1>
								<li>[<strong>#aField#</strong>] is duplicated as the header for #listValueCount(foundHeaders,aField)# columns.</li>
							</cfif>
						</cfloop>
						<cfthrow message = "#DUP_COLUMN_ERR#">
					</cfif>
				</ul>

				<cfset colNames="#foundHeaders#">
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
						<cfset error_message="#COLUMN_ERR# from line #row# in input file.  <br>Header:[#colNames#] <br>Row:[#ArrayToList(collValuesArray)#] <br>Error: #cfcatch.message#"><!--- " --->
						<cfif isDefined("cfcatch.queryError")>
							<cfset error_message = "#error_message# #cfcatch.queryError#">
						</cfif>
						<cfthrow message = "#error_message#">
					</cfcatch>
					</cftry>
				</cfloop>

				<cfif foundHighCount GT 0>
					<cfif foundHighCount GT 1><cfset plural="s"><cfelse><cfset plural=""></cfif>
					<h3 class="h4">Found characters where the encoding is probably important in the input data.</h3>
					<div>
						<p>Showing #foundHighCount# example#plural#.  If these do not appear as the correct characters, the file likely has a different encoding from the one you selected and
						you probably want to <strong><a href="/tools/BulkloadAgents.cfm">reload</a></strong> this file selecting a different encoding.  If these appear as expected, then 
							you selected the correct encoding and can continue to validate or load.</p>
					</div>
					<ul class="pb-1 h4 list-unstyled">
						#foundHighAscii# #foundMultiByte#
					</ul>
				</cfif>
				<h3 class="h3">
					<cfif loadedRows EQ 0>
						Loaded no rows from the CSV file.  The file appears to be just a header with no data. Fix file and <a href="/tools/BulkloadAgents.cfm">reload</a>
					<cfelse>
						Successfully read #loadedRows# records from the CSV file.  Next <a href="/tools/BulkloadAgents.cfm?action=validate">click to validate</a>.
					</cfif>
				</h3>
			<cfcatch>
				<h3 class="h4">
					Failed to read the CSV file.  Fix the errors in the file and <a href="/tools/BulkloadAgents.cfm">reload</a>
				</h3>
				<cfif isDefined("arrResult")>
					<cfset foundHighCount = 0>
					<cfset foundHighAscii = "">
					<cfset foundMultiByte = "">
					<cfloop from="1" to ="#ArrayLen(arrResult[1])#" index="col">
						<cfset thisBit=arrResult[1][col]>
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
						<h3 class="h4">Found characters with unexpected encoding in the header row.  This is probably the cause of your error.</h3>
						<div>
							Showing #foundHighCount# examples. Did you select utf-16 or unicode for the encoding for a file that does not have multibyte encoding?
						</div>
						<ul class="pb-1 h4 list-unstyled">
							#foundHighAscii# #foundMultiByte#
						</ul>
					</cfif>
				</cfif>
				<cfif Find("#NO_COLUMN_ERR#",cfcatch.message) GT 0>
					#cfcatch.message#
				<cfelseif Find("#COLUMN_ERR#",cfcatch.message) GT 0>
					#cfcatch.message#
				<cfelseif Find("#DUP_COLUMN_ERR#",cfcatch.message) GT 0>
					#cfcatch.message#
				<cfelseif Find("IOException reading next record: java.io.IOException: (line 1) invalid char between encapsulated token and delimiter",cfcatch.message) GT 0>
					<ul class="py-1 h4 list-unstyled">
						<li>Unable to read headers in line 1.  Did you select CSV format for a tab delimited file?</li>
					</ul>
				<cfelseif Find("IOException reading next record: java.io.IOException: (line 1)",cfcatch.message) GT 0>
					<ul class="py-1 h4 list-unstyled">
						<cfif format EQ "DEFAULT"><cfset fmt="CSV: Default Comma Separated values"><cfelse><cfset fmt="#format#"></cfif>
						<li>Unable to read headers in line 1.  Is your file actually have the format #fmt#?</li>
						<li>#cfcatch.message#</li>
					</ul>
				<cfelseif Find("IOException reading next record: java.io.IOException:",cfcatch.message) GT 0>
					<ul class="py-1 h4 list-unstyled">
						<cfif format EQ "DEFAULT"><cfset fmt="CSV: Default Comma Separated values"><cfelse><cfset fmt="#format#"></cfif>
						<li>Unable to read a record from the file.  One or more lines may not be consistent with the specified format #format#</li>
						<li>#cfcatch.message#</li>
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
			
	<!------------------------------------------------------->
	<cfif #action# is "validate">
		<h2 class="h3">Second step: Data Validation</h2>
		<cfoutput>
			<cfquery name="getCID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				update cf_temp_agents set agent_type=
				(select agent_type from ctagent_type where agent_type = cf_temp_agents.agent_type)
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="getCID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				update cf_temp_agents set other_name_type = 'preferred'
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="miac" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE cf_temp_agents 
				SET status = 'agent_type_not_found'
				WHERE agent_type is null
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="miap" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE cf_temp_agents 
				SET status = 'last_name_not_found'
				WHERE last_name is null
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="miap" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE cf_temp_agents 
				SET status = 'preferred_name_not_found'
				WHERE preferred_name is null
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT agent_type, preferred_name, first_name, middle_name, last_name, birth_date, death_date, agent_remark, prefix, suffix, other_name, other_name_type,other_name_2,other_name_type_2,other_name_3,other_name_type_3,agentguid_guid_type, agentguid, status
				FROM cf_temp_agents
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="pf" dbtype="query">
				SELECT count(*) c 
				FROM data 
				WHERE status is not null
			</cfquery>
			<cfif pf.c gt 0>
				<h2>
					There is a problem with #pf.c# of #data.recordcount# row(s). See the STATUS column. (<a href="/tools/BulkloadAgents.cfm?action=dumpProblems">download</a>).
				</h2>
				<h3>
					Fix the problems in the data and <a href="/tools/BulkloadAgents.cfm">start again</a>.
				</h3>
			<cfelse>
				<h2>
					Validation checks passed. Look over the table below and <a href="/tools/BulkloadAgents.cfm?action=load">click to continue</a> if it all looks good.
				</h2>
			</cfif>
			<table class='sortable table table-responsive table-striped d-lg-table'>
				<thead>
					<tr>
						<th>AGENT_TYPE</th>
						<th>PREFERRED_NAME</th>
						<th>FIRST_NAME</th>
						<th>MIDDLE_NAME</th>
						<th>LAST_NAME</th>
						<th>BIRTH_DATE</th>
						<th>DEATH_DATE</th>
						<th>AGENT_REMARK</th>
						<th>PREFIX</th>
						<th>SUFFIX</th>
						<th>OTHER_NAME</th>
						<th>OTHER_NAME_TYPE</th>
						<th>OTHER_NAME_2</th>
						<th>OTHER_NAME_TYPE_2</th>
						<th>OTHER_NAME_3</th>
						<th>OTHER_NAME_TYPE_3</th>
						<th>agentguid_guid_type</th>
						<th>agentguid</th>
						<th>STATUS</th>
					</tr>
				<tbody>
					<cfloop query="data">
						<tr>
							<td>#data.AGENT_TYPE#</td>
							<td>#data.PREFERRED_NAME#</td>
							<td>#data.FIRST_NAME#</td>
							<td>#data.MIDDLE_NAME#</td>
							<td>#data.LAST_NAME#</td>
							<td>#data.BIRTH_DATE#</td>
							<td>#data.DEATH_DATE#</td>
							<td>#data.AGENT_REMARK#</td>
							<td>#data.PREFIX#</td>
							<td>#data.SUFFIX#</td>
							<td>#data.OTHER_NAME#</td>
							<td>#data.OTHER_NAME_TYPE#</td>
							<td>#data.OTHER_NAME_2#</td>
							<td>#data.OTHER_NAME_TYPE_2#</td>
							<td>#data.OTHER_NAME_3#</td>
							<td>#data.OTHER_NAME_TYPE_3#</td>
							<td>#data.agentguid_guid_type#</td>
							<td>#data.agentguid#</td>
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
			<cfquery name="getTempData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT * FROM cf_temp_agents
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cftry>
				<cfset agent_updates = 0>
				<cftransaction>
					<cfloop query="getTempData">
						<cfquery name="updateAgents" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="updateAgents_result">
							insert into agent
							(agent_id,agent_type,agent_remarks,agentguid_guid_type,agentguid,preferred_agent_name_id) values(sq_agent_id.nextval,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#agent_type#">,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#agent_remark#">,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#agentguid_guid_type#">,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#agentguid#">,sq_agent_id.nextval)
						</cfquery>
						<cfquery name="updateAgents" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="updateAgents_result">
							insert into agent_name
							(agent_name_id,agent_id,agent_name_type,agent_name) values(sq_agent_name_id.nextval,sq_agent_id.currval,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#other_name_type#">,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#preferred_name#">)
						</cfquery>
						<cfquery name="updateAgents" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="updateAgents_result">
							insert into person
							(person_id,prefix,last_name,first_name,middle_name,suffix,birth_date,death_date) values(sq_agent_id.currval,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#prefix#">,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#last_name#">,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#first_name#">,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#middle_name#">,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#suffix#">,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#dateformat(birth_date,'yyyy-mm-dd')#">,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#dateformat(death_date,'yyyy-mm-dd')#">)
						</cfquery>
						<cfset agent_updates = agent_updates + updateAgents_result.recordcount>
					</cfloop>
				</cftransaction>
				<h2>Updated #agent_updates# agents.</h2>
			<cfcatch>
				<h2>There was a problem updating container types.</h2>
				<cfquery name="getProblemData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT agent_type, preferred_name, first_name, middle_name, last_name, birth_date, death_date, agent_remark, prefix, suffix, other_name, other_name_type,other_name_2,other_name_type_2,other_name_3,other_name_type_3,agentguid_guid_type, agentguid, status 
					FROM cf_temp_agents 
					WHERE status is not null
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<h3>Problematic Rows (<a href="/tools/BulkloadAgents.cfm?action=dumpProblems">download</a>)</h3>
				<table class='sortable table table-responsive table-striped d-lg-table'>
					<thead>
						<tr>
							<th>agent_type</th>
							<th>preferred_name</th>
							<th>first_name</th>
							<th>middle_name</th>
							<th>last_name</th>
							<th>birth_date</th>
							<th>death_date</th>
							<th>agent_remark</th>
							<th>prefix</th>
							<th>suffix</th>
							<th>other_name_1</th><th>other_name_type_1</th><th>other_name_2</th><th>other_name_type_2</th><th>other_name_3</th><th>other_name_type_3</th><th>agentguid_guid_type</th><th>agentguid</th><th>status</th>
						</tr> 
					</thead>
					<tbody>
						<cfloop query="getProblemData">
							<tr>
								<td>#getProblemData.agent_type#</td>
								<td>#getProblemData.preferred_name#</td>
								<td>#getProblemData.first_name#</td>
								<td>#getProblemData.middle_name#</td>
								<td>#getProblemData.agent_type#</td>
								<td>#getProblemData.preferred_name#</td>
								<td>#getProblemData.first_name#</td>
								<td>#getProblemData.middle_name#</td>
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
						<cfquery name="updateAgents" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="updateAgents_result">
							insert into person
							(person_id,prefix,last_name,first_name,middle_name,suffix,birth_date,death_date) values(sq_agent_id.currval,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#prefix#">,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#last_name#">,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#first_name#">,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#middle_name#">,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#suffix#">,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#dateformat(birth_date,'yyyy-mm-dd')#">,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#dateformat(death_date,'yyyy-mm-dd')#">)
						</cfquery>
						<cfset agent_updates = agent_updates + updateAgents_result.recordcount>
					</cfloop>
					<cftransaction action="commit">
				<cfcatch>
					<cftransaction action="rollback">
					<cfquery name="getProblemData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						SELECT *
						FROM cf_temp_agents 
						WHERE key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#problem_key#">
					</cfquery>
					<h3>Error updating row (#agent_updates + 1#): #cfcatch.message#</h3>
					<table class='sortable table table-responsive table-striped d-lg-table'>
						<thead>
							<tr>
								<th>agent_type</th>
								<th>preferred_name</th>
								<th>first_name</th>
								<th>middle_name</th>
								<th>last_name</th>
								<th>birth_date</th>
								<th>death_date</th>
								<th>agent_remark</th>
								<th>prefix</th>
								<th>suffix</th>
								<th>other_name_type</th>
								<th>other_name</th>
								<th>other_name_type_2</th>
								<th>other_name_2</th>
								<th>other_name_type_3</th>
								<th>other_name_3</th>
								<th>username</th>
								<th>agentguid_guid_type</th>
								<th>agentguid</th>
								<th>status</th>
							</tr> 
						</thead>
						<tbody>
							<cfloop query="getProblemData">
								<tr>
									<td>#getProblemData.agent_type#</td>
									<td>#getProblemData.preferred_name#</td>
									<td>#getProblemData.first_name#</td>
									<td>#getProblemData.middle_name#</td>
									<td>#getProblemData.last_name#</td>
									<td>#getProblemData.birth_date#</td>
									<td>#getProblemData.death_date#</td>
									<td>#getProblemData.agent_remark#</td>
									<td>#getProblemData.prefix#</td>
									<td>#getProblemData.suffix#</td>
									<td>#getProblemData.other_name_type#</td>
									<td>#getProblemData.other_name#</td>
									<td>#getProblemData.other_name_type_2#</td>
									<td>#getProblemData.other_name_2#</td>
									<td>#getProblemData.other_name_type_3#</td>
									<td>#getProblemData.other_name_3#</td>
									<td>#getProblemData.agentguid_guid_type#</td>
									<td>#getProblemData.agentguid#</td>
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
			<cfquery name="clearTempTable" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="clearTempTable_result">
				DELETE FROM cf_temp_agents
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
		</cfoutput>
	</cfif>