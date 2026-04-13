<!--- tools/bulkloadCollectingEvent.cfm add collecting events in bulk.

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

<!--- page can submit with action either as a form post parameter or as a url parameter, obtain either into variable scope. --->
<cfif isDefined("url.action")><cfset variables.action = url.action></cfif>
<cfif isDefined("form.action")><cfset variables.action = form.action></cfif>

<!--- special case handling to dump problem data as csv --->
<cfif isDefined("variables.action") AND variables.action is "dumpProblems">
	<cfquery name="getProblemData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		SELECT 
			REGEXP_REPLACE( status, '\s*</?\w+((\s+\w+(\s*=\s*(".*?"|''.*?''|[^''">\s]+))?)+\s*|\s*)/?>\s*', NULL, 1, 0, 'im') AS STATUS, 
			spec_locality, locality_id,verbatim_date,verbatim_locality,coll_event_remarks,valid_distribution_fg,collecting_source,collecting_method,habitat_desc,
			date_determined_by_agent, date_determined_by_agent_id, fish_field_number,
			began_date,ended_date,collecting_time,verbatimcoordinates,verbatimlatitude,verbatimlongitude,verbatimcoordinatesystem,
			verbatimsrs,startdayofyear,enddayofyear,verbatimelevation,verbatimdepth,verbatim_collectors,verbatim_field_numbers,verbatim_habitat
		FROM cf_temp_collecting_event
		WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
		ORDER BY key
	</cfquery>
	<cfinclude template="/shared/component/functions.cfc">
	<cfinclude template="/shared/functionLib.cfm">
	<cfset csv = queryToCSV(getProblemData)>
	<cfheader name="Content-Type" value="text/csv">
	<cfoutput>#csv#</cfoutput>
	<cfabort>
</cfif>

<!--- KEY,DATE_DETERMINED_BY_AGENT_ID,spec_locality,LOCALITY_ID,VERBATIM_DATE,VERBATIM_LOCALITY,COLL_EVENT_REMARKS,VALID_DISTRIBUTION_FG,COLLECTING_SOURCE,COLLECTING_METHOD,HABITAT_DESC,DATE_DETERMINED_BY_AGENT,FISH_FIELD_NUMBER,BEGAN_DATE,ENDED_DATE,COLLECTING_TIME,VERBATIMCOORDINATES,VERBATIMLATITUDE,VERBATIMLONGITUDE,VERBATIMCOORDINATESYSTEM,VERBATIMSRS,STARTDAYOFYEAR,ENDDAYOFYEAR,VERBATIMELEVATION,VERBATIMDEPTH,VERBATIM_COLLECTORS,VERBATIM_FIELD_NUMBERS,VERBATIM_HABITAT,USERNAME,STATUS --->

<cfset fieldlist = "SPEC_LOCALITY,LOCALITY_ID,VERBATIM_DATE,VERBATIM_LOCALITY,COLL_EVENT_REMARKS,VALID_DISTRIBUTION_FG,COLLECTING_SOURCE,COLLECTING_METHOD,HABITAT_DESC,DATE_DETERMINED_BY_AGENT,FISH_FIELD_NUMBER,BEGAN_DATE,ENDED_DATE,COLLECTING_TIME,VERBATIMCOORDINATES,VERBATIMLATITUDE,VERBATIMLONGITUDE,VERBATIMCOORDINATESYSTEM,VERBATIMSRS,STARTDAYOFYEAR,ENDDAYOFYEAR,VERBATIMELEVATION,VERBATIMDEPTH,VERBATIM_COLLECTORS,VERBATIM_FIELD_NUMBERS,VERBATIM_HABITAT,DATE_DETERMINED_BY_AGENT_ID" >

<cfset fieldTypes="CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_DECIMAL">

<cfif listlen(fieldlist) NEQ listlen(fieldTypes)>
	<cfthrow message = "Error: Bug in the definition of fieldlist[#listlen(fieldlist)#] and fieldType[#listlen(fieldTypes)#] lists, lists must be the same length, but are not.">
</cfif>
	
<cfset requiredfieldlist = "SPEC_LOCALITY,LOCALITY_ID,VERBATIM_DATE,BEGAN_DATE,ENDED_DATE,COLLECTING_SOURCE">

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
<cfset pageTitle = "Bulkload Collecting Events">
<cfinclude template="/shared/_header.cfm">
<cfinclude template="/tools/component/csv.cfc" runOnce="true"><!--- for common csv testing functions --->
<cfif not isDefined("variables.action") OR len(variables.action) EQ 0><cfset variables.action="entryPoint"></cfif>
<main class="container-fluid py-3 px-5" id="content">
	<!--- Style elements for proof of concept accordion that will need to move to a css file --->
	<!--- NOTE: This should be replaced with a jquery-ui accordion --->
	<style>
			.accordion-button::after {
			content: none;
		}
			.accordion-header .fa {
			transition: transform 0.3s ease-in-out;
		}
			.accordion-button.collapsed .fa-plus {
			transform: rotate(0deg);
		}
			.accordion-button .fa-plus {
			transform: rotate(45deg);
		}
	</style>
	<!--- End proof of concept style block --->
	<h1 class="h2 mt-2">Bulkload Geography</h1>
	<cfif variables.action is "entryPoint">
		<cfoutput>
			<p>Load new collecting event records associated with existing locality records.</p>
			<h2 class="h4">Use Template to Load Data</h2>
			<button class="btn btn-xs btn-primary float-left mr-3" id="copyButton">Copy Column Headers</button>
			<div id="template" class="my-1 mx-0">
				<label for="templatearea" class="data-entry-label" style="line-height: inherit;">
					Copy this header line, paste it into a blank worksheet, and save it as a .csv file or <a href="/tools/BulkloadCollectingEvents.cfm?action=getCSVHeader" class="font-weight-bold">download</a> a template.
				</label>
				<textarea style="height: 56px;" cols="90" id="templatearea" class="mb-1 w-100 data-entry-textarea small">#fieldlist#</textarea>
			</div>
			<div class="accordion" id="accordionIdentifiers">
				<div class="card mb-2 bg-light">
					<div class="card-header" id="headingIdentifiers">
						<h3 class="h5 my-0">
							<button type="button" role="button" aria-label="identifiers pane" class="headerLnk text-left w-100" data-toggle="collapse" data-target="##identifiersPane" aria-expanded="false" aria-controls="identifiersPane">
								Data Entry Instructions per Column
							</button>
						</h3>
					</div>
					<div id="identifiersPane" class="collapse" aria-labelledby="headingIdentifiers" data-parent="##accordionIdentifiers">
						<div class="card-body" id="identifiersCardBody">
						<p class="px-3 pt-2"> Columns in <span class="text-danger">red</span> are required; others are optional.</p>
							<ul class="mb-4 h5 font-weight-normal list-group mx-3">
								<cfloop list="#fieldlist#" index="field" delimiters=",">
									<cfquery name = "getComments"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#"  result="getComments_result">
										SELECT comments
										FROM sys.all_col_comments
										WHERE 
											owner = 'MCZBASE'
											and table_name = 'CF_TEMP_COLLECTING_EVENT'
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
			<div>
				<h2 class="h4 mt-4">Upload a comma-delimited text file (csv)</h2>
				<form name="getFiles" method="post" enctype="multipart/form-data" action="/tools/BulkloadCollectingEvents.cfm">
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
			</div>
		</cfoutput>
	</cfif>
	<!------------------------------------------------------->
	<cfif variables.action is "getFile">
		<!--- get form variables from post --->
		<cfif isDefined("form.fileToUpload")><cfset variables.fileToUpload = form.fileToUpload></cfif>
		<cfif isDefined("form.format")><cfset variables.format = form.format></cfif>
		<cfif isDefined("form.characterSet")><cfset variables.characterSet = form.characterSet></cfif>
		<cfoutput>
			<h2 class="h4">First step: Reading data from CSV file.</h2>
			<!--- Set some constants to identify error cases in cfcatch block --->
			<cfset NO_COLUMN_ERR = "One or more required fields are missing in the header line of the csv file.">
			<cfset DUP_COLUMN_ERR = "One or more columns are duplicated in the header line of the csv file.">
			<cfset COLUMN_ERR = "Error inserting data">
			<cfset NO_HEADER_ERR = "No header line found, csv file appears to be empty.">
			<cfset TABLE_NAME = "CF_TEMP_COLLECTING_EVENT">
				<cftry>
				<!--- cleanup any incomplete work by the same user --->
				<cfquery name="killOld" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					DELETE FROM CF_TEMP_COLLECTING_EVENT
					WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<!---Parse the CSV file using Apache Commons CSV library. Include with ColdFusion so columns with comma delimiters will be separated properly.--->
					<cfset fileProxy = CreateObject("java","java.io.File") >
					<cfobject type="Java" name="csvFormat" class="org.apache.commons.csv.CSVFormat">
					<cfobject type="Java" name="csvParser" class="org.apache.commons.csv.CSVParser">
					<cfobject type="Java" name="csvRecord" class="org.apache.commons.csv.CSVRecord">
					<cfobject type="java" class="java.io.FileReader" name="fileReader">	
					<cfobject type="Java" name="javaCharset" class="java.nio.charset.Charset">
					<cfobject type="Java" name="standardCharsets" class="java.nio.charset.StandardCharsets">
					<cfset filePath = fileProxy.init(JavaCast("string",#FiletoUpload#)) >
					<cfset tempFileInputStream = CreateObject("java","java.io.FileInputStream").Init(#filePath#)>
					<!--- Create a FileReader object to provide a reader for the CSV file --->
					<cfset fileReader = CreateObject("java","java.io.FileReader").Init(#filePath#)>
					<!---We cannot use the withHeader() method from coldfusion, as it is overloaded. With no parameters ColdFusion has no means to pick the correct method.--->
					<!---Select format of csv file based on format variable from user.--->
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
							<!--- If not available, iso-8859-1 will substitute, except for 0x80 to 0x9F --->
							<!--- These characters won't be handled correctly if the source is windows-1252:  €  Š  š  Ž  ž  Œ  œ  Ÿ --->
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
					<cfset colNameArray = listToArray(ucase(foundHeaders))><!--- the list of columns/fields found in the input file --->
					<cfset fieldArray = listToArray(ucase(fieldlist))><!--- the full list of fields --->
					<cfset typeArray = listToArray(fieldTypes)><!--- the types for the full list of fields --->
					<div class="col-12 my-3 px-0">
						<h3>Found #size# columns in header of csv file.</h3> 
						There are #ListLen(fieldList)# columns expected in the header (of these #ListLen(requiredFieldList)# are required).
					</div>
					<!--- check for required fields in header line, list all fields, throw exception and fail if any required fields are missing --->
					<cfset reqFieldsResponse = checkRequiredFields(fieldList=fieldList,requiredFieldList=requiredFieldList,NO_COLUMN_ERR=NO_COLUMN_ERR,TABLE_NAME=TABLE_NAME)>

					<!--- Test for additional columns not in list, warn and ignore. --->
					<cfset addFieldsResponse = checkAdditionalFields(fieldList=fieldList)>

					<!--- Identify duplicate columns and fail if found --->
					<cfset dupFieldsResponse = checkDuplicateFields(foundHeaders=variables.foundHeaders,DUP_COLUMN_ERR=DUP_COLUMN_ERR)>
						
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
							<!---Construct insert for row with a line for each entry in fieldlist using cfqueryparam if column header is in fieldlist, otherwise using null.--->
								<cfquery name="insert" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="insert_result">
									INSERT INTO cf_temp_collecting_event
										(#fieldlist#,username)
									VALUES (
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
									<style>
										red {color: red;}
										p.wrapped-text {
											max-width: 100%;  /* Adjust as needed for your layout */
											white-space: normal;  /* Allow wrapping */
											word-wrap: break-word;  /* Break long words if necessary */
											border: 1px solid ##ccc;  /* Optional styling */
											padding: 5px 10px;
											margin-bottom: 2px;
										}
										p.top {margin-top: 1rem;}
									</style>
							
									<!--- identify the problematic row, and problem as much as possible --->
									<cfset err_help = "">
									<cfif isDefined("cfcatch.queryError") AND Find("cannot insert NULL into",cfcatch.queryError) GT 0>
										<cfset err_help = "<strong>A value is missing from a required field</strong>.  ">
									</cfif>
									<cfset error_message="<p class='top'>#COLUMN_ERR# from Row #row# in input file. </p>  <p class='wrapped-text'>Header Row: <br>[#colNames#]</p><p class='wrapped-text'>First error is in Row #row#: <br>[#ArrayToList(collValuesArray)#]</p><p class='wrapped-text'>Error Message:<br> <red>#err_help##cfcatch.message#</red>">
										<!--- " --->
									<cfif isDefined("cfcatch.queryError")>
										<cfset error_message = "#error_message# #cfcatch.queryError#</p>">
									<cfelse>
										<cfset error_message = "#error_message#</p>">
									</cfif>
									<cfthrow message = "#error_message#">
								</cfcatch>
								</cftry>
						</cfloop>
						<cfif foundHighCount GT 0>
							<h3 class="h4">Found characters where the encoding is probably important in the input data.</h3>
							<div>
								<p>Showing #foundHighCount# examples.  If these do not appear as the correct characters, the file likely has a different encoding from the one you selected and
								you probably want to <a href="/tools/BulkloadCollectingEvents.cfm">reload this file</a> selecting a different encoding. If these appear as expected, then you selected the correct encoding and can continue to validate or load.</p>
							</div>
							<ul class="pb-1 h4 list-unstyled">#foundHighAscii# #foundMultiByte#</ul>

						</cfif>
					</div>
					<h3 class="h4">
						Successfully read #loadedRows# records from the CSV file. Next <a href="/tools/BulkloadCollectingEvents.cfm?action=validate" class="btn-link font-weight-lessbold">click to validate</a>.
					</h3>

				<cfcatch>
					<h3 class="h4">
						Failed to read the CSV file.  Fix the errors in the file and <a href="/tools/BulkloadCollectingEvents.cfm">reload</a>.
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
									<cfset foundHighAscii = "#foundHighAscii# <li class='text-danger font-weight-bold m-3'>#thisBit#</li>"><!--- " --->
									<cfset foundHighCount = foundHighCount + 1>
								</cfif>
							<cfelseif REFind("[\xc0-\xdf][\x80-\xbf]",thisBit) GT 0>
								<!--- multibyte --->
								<cfif foundHighCount LT 6>
									<cfset foundMultiByte = "#foundMultiByte# <li class='text-danger font-weight-bold m-3'>#thisBit#</li>"><!--- " --->
									<cfset foundHighCount = foundHighCount + 1>
								</cfif>
							</cfif>
						</cfloop>
						<cfif isDefined("foundHighCount") AND foundHighCount GT 0>
							<h3 class="h4">Found characters with unexpected encoding in the header row. This is probably the cause of your error.</h3>
							<div>
								<p>Showing #foundHighCount# examples. Did you select utf-16 or unicode for the encoding for a file that does not have multibyte encoding?</p>
							</div>
							<ul class="py-1 h4">
								#foundHighAscii# #foundMultiByte#
							</ul>
						</cfif>
					</cfif>
					<cfif Find("#NO_COLUMN_ERR#",cfcatch.message) GT 0>
							#cfcatch.message# 
					<cfelseif Find("#COLUMN_ERR#",cfcatch.message) GT 0>
							#cfcatch.message#
					<cfelse>
						<cfdump var="#cfcatch#">
					</cfif>
				</cfcatch>
				</cftry>
			</cfoutput>
		</cfif>
	<!------------------------------------------------------->
	<cfif variables.action is "validate">
		<!--- Load utility class for evaluating date strings --->
		<cfobject type="Java" class="org.filteredpush.qc.date.util.DateUtils" name="dateUtils">

		<cfoutput>
			<h2 class="h4">Second step: Data Validation</h2>
			<!--- Validating data in bulk --->
			<!--- Checks that do not require looping through the data, check for missing required data, missing values from key value pairs, bad formats and values that do not match database code tables--->
			<cfloop list="#requiredfieldlist#" item="aField">
				<cfquery name="warningMissingRequired" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE CF_TEMP_COLLECTING_EVENT
					SET status = concat(nvl2(status, status || '; ', ''),'#aField# is required')
					WHERE
						( #aField# is null or trim(#aField#) is null )
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
			</cfloop>
			<cfquery name="localityIDNotInteger" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE CF_TEMP_COLLECTING_EVENT
				SET status = concat(nvl2(status, status || '; ', ''),'locality_id is not an integer.')
				WHERE
					locality_id is not null
					AND NOT regexp_like(locality_id,'^[0-9]+$')
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="localityIDNotFound" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE CF_TEMP_COLLECTING_EVENT
				SET status = concat(nvl2(status, status || '; ', ''),'locality_id not found.')
				WHERE
					locality_id is not null
					AND locality_id not in (select locality_id from locality)
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<!--- assume valid distribution flag is 1, yes, the normal case if not specified --->
			<cfquery name="flagAssume1" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE CF_TEMP_COLLECTING_EVENT
				SET 
					valid_distribution_fg = 1
				WHERE
					valid_distribution_fg is null
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="flagNot01" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE CF_TEMP_COLLECTING_EVENT
				SET status = concat(nvl2(status, status || '; ', ''),'valid_distribution_fg must be 0 or 1.')
				WHERE
					valid_distribution_fg is not null
					AND NOT regexp_like(valid_distribution_fg,'^[01]+$')
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="checkCollectingSouurce" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE CF_TEMP_COLLECTING_EVENT
				SET status = concat(nvl2(status, status || '; ', ''),'collecting source not in controlled vocabulary.')
				WHERE
					collecting_source is not null
					AND collecting_source not in (select collecting_source from ctcollecting_source)
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>

			<!--- Validation queries that test against individual rows looping through data in temp table --->
			<!--- Get Data from the temp table and the codetables with relevant information --->
			<cfquery name="getTempData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT 
					   began_date,ended_date, locality_id, spec_locality,
						date_determined_by_agent,date_determined_by_agent_id,
						KEY
				FROM CF_TEMP_COLLECTING_EVENT
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfloop query="getTempData">
				<!--- verify that the spec_locality is the value in the locality with the specified locality_id --->
				<cfif len(getTempData.locality_id) eq 0>
					<cfquery name="geogIDOnLocality" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						UPDATE CF_TEMP_COLLECTING_EVENT
						SET status = concat(nvl2(status, status || '; ', ''),'Required locality_id is empty.')
						WHERE
							username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
							AND key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.key#">
					</cfquery>
				<cfelse> 
					<cfquery name="geogIDOnLocality" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						UPDATE CF_TEMP_COLLECTING_EVENT
						SET status = concat(nvl2(status, status || '; ', ''),'spec_locality is not correct for specified locality_id, did you provide the correct locality_id?')
						WHERE
							spec_locality is not null
							AND NOT spec_locality in (select spec_locality from locality where locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempData.locality_id#">)
							AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
							AND key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.key#">
					</cfquery>
				</cfif>

				<!--- lookup agent --->
				<cfif len(getTempData.date_determined_by_agent) gt 0>
					<cfset agentProblem = "">
					<cfset relatedAgentID = "">
					<cfquery name="findAgentDet" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						SELECT agent_id 
						FROM agent_name 
						WHERE agent_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.date_determined_by_agent#">
							and agent_name_type = 'preferred'
					</cfquery>
					<cfif findAgentDet.recordCount EQ 1>
						<cfset relatedAgentID = findAgentDet.agent_id>
					<cfelseif findAgentDet.recordCount EQ 0>
						<!--- relax criteria, find agent by any name. --->
						<cfquery name="findAgentAnyDet" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							SELECT agent_id 
							FROM agent_name 
							WHERE agent_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.date_determined_by_agent#">
						</cfquery>
						<cfif findAgentAnyDet.recordCount EQ 1>
							<cfset relatedAgentID = findAgentAnyDet.agent_id>
						<cfelseif findAgentAnyDet.recordCount EQ 0>
							<cfset agentProblem = "no matches to any agent name">
						<cfelse>
							<cfset agentProblem = "matches to multiple agent names, use date_determined_by_agent_id">
						</cfif>
					<cfelse>
						<cfset agentProblem = "matches to multiple preferred agent names, use date_determined_by_agent_id">
					</cfif>
					<!---update the table with the agentID found above--->	
					<cfif findAgentDet.recordCount EQ 1 OR findAgentAnyDet.recordCount EQ 1>
						<cfquery name="chkDAID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							UPDATE cf_temp_collecting_event
							SET date_determined_by_agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#relatedAgentID#">
							WHERE date_determined_by_agent_id is null
								AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
								and key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.key#">
						</cfquery>
					<cfelseif len(agentProblem) gt 0>
						<cfquery name="warningDetermined" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							UPDATE cf_temp_collecting_event
							SET status = concat(nvl2(status, status || '; ', ''),'date_determined_by_agent not found #agentProblem#')
							WHERE date_determined_by_agent is not null 
								AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
								and key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.key#">
						</cfquery>
					</cfif>
				</cfif>
						
				<!--- Check that began_date and ended date are in the form yyyy, yyyy-mm, or yyyy-mm-dd --->
				<cfif REFind( "^[0-9]{4}(-[0-9]{2}){0,2}$", getTempData.BEGAN_DATE) GT 0>
					<cfset pattern = "yyyy-MM-dd">
					<cfif REFind( "^[0-9]{4}$", getTempData.BEGAN_DATE) GT 0>
						<cfset pattern = "yyyy">
					<cfelseif REFind( "^[0-9]{4}-[0-9]{2}$", getTempData.BEGAN_DATE) GT 0>
						<cfset pattern = "yyyy-MM">
					<cfelseif REFind( "^[0-9]{4}-[0-9]{2}-[0-9]{2}$", getTempData.BEGAN_DATE) GT 0>
						<cfset pattern = "yyyy-MM-dd">
					</cfif>
					<cfif NOT dateUtils.eventDateValid(#getTempData.BEGAN_DATE#)>
						<cfquery name="checkBeganDate" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							UPDATE cf_temp_collecting_event
							SET status = concat(nvl2(status, status || '; ', ''),'BEGAN_DATE is in the correct format but is not a valid date "#began_date#"')
							WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
								AND key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.key#"> 
						</cfquery>
					<cfelseif DatePart("yyyy",parseDateTime(getTempData.BEGAN_DATE,pattern)) LT '1700'>
						<cfquery name="checkBeganDate1" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							UPDATE cf_temp_collecting_event
							SET status = concat(nvl2(status, status || '; ', ''),'BEGAN_DATE Year must be 1700 or later "#began_date#"')
							WHERE began_date is not null
								AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
								AND key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.key#"> 
						</cfquery>
					</cfif>
				<cfelse>
					<cfquery name="checkBeganDate3" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						UPDATE cf_temp_collecting_event
						SET status = concat(nvl2(status, status || '; ', ''),'BEGAN_DATE is not in the form yyyy, yyyy-mm, or yyyy-mm-dd "#began_date#"')
						WHERE began_date is not null
							AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
							AND key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.key#"> 
					</cfquery>
				</cfif>
				<cfif REFind( "^[0-9]{4}(-[0-9]{2}){0,2}$", getTempData.ENDED_DATE) GT 0>
					<cfset pattern = "yyyy-MM-dd">
					<cfif REFind( "^[0-9]{4}$", getTempData.ENDED_DATE) GT 0>
						<cfset pattern = "yyyy">
					<cfelseif REFind( "^[0-9]{4}-[0-9]{2}$", getTempData.ENDED_DATE) GT 0>
						<cfset pattern = "yyyy-MM">
					<cfelseif REFind( "^[0-9]{4}-[0-9]{2}-[0-9]{2}$", getTempData.ENDED_DATE) GT 0>
						<cfset pattern = "yyyy-MM-dd">
					</cfif>
					<cfif NOT dateUtils.eventDateValid(#getTempData.ENDED_DATE#)>
						<cfquery name="checkEndedDate" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							UPDATE cf_temp_collecting_event
							SET status = concat(nvl2(status, status || '; ', ''),'ENDED_DATE is in the correct format but is not a valid date "#ended_date#"')
							WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
								AND key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.key#"> 
						</cfquery>
					<cfelseif DatePart("yyyy",parseDateTime(getTempData.ENDED_DATE,pattern)) LT '1700'>
						<cfquery name="checkEndedDate1" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							UPDATE cf_temp_collecting_event
							SET status = concat(nvl2(status, status || '; ', ''),'ENDED_DATE Year must be 1700 or later "#ended_date#"')
							WHERE ended_date is not null
								AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
								AND key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.key#"> 
						</cfquery>
					</cfif>
				<cfelse>
					<cfquery name="checkEndedDate3" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						UPDATE cf_temp_collecting_event
						SET status = concat(nvl2(status, status || '; ', ''),'ENDED_DATE is not in the form yyyy, yyyy-mm, or yyyy-mm-dd "#ended_date#"')
						WHERE ended_date is not null
							AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
							AND key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.key#"> 
					</cfquery>
				</cfif>


				<!--- Reload Data from the temp table --->
				<cfquery name="getTempDataKey" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT 
						DATE_DETERMINED_BY_AGENT_ID,spec_locality,LOCALITY_ID,VERBATIM_DATE,VERBATIM_LOCALITY,COLL_EVENT_REMARKS,VALID_DISTRIBUTION_FG,
						COLLECTING_SOURCE,COLLECTING_METHOD,HABITAT_DESC,DATE_DETERMINED_BY_AGENT,FISH_FIELD_NUMBER,BEGAN_DATE,ENDED_DATE,
						COLLECTING_TIME,VERBATIMCOORDINATES,VERBATIMLATITUDE,VERBATIMLONGITUDE,VERBATIMCOORDINATESYSTEM,VERBATIMSRS,
						STARTDAYOFYEAR,ENDDAYOFYEAR,VERBATIMELEVATION,VERBATIMDEPTH,VERBATIM_COLLECTORS,VERBATIM_FIELD_NUMBERS,
						VERBATIM_HABITAT,USERNAME,STATUS,
						KEY
					FROM CF_TEMP_COLLECTING_EVENT
					WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						and key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.key#"> 
				</cfquery>
			</cfloop>

			<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT *
				FROM cf_temp_collecting_event
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				ORDER BY key
			</cfquery>
			<cfquery name="problemsInData" dbtype="query">
				SELECT count(*) c 
				FROM data 
				WHERE status is not null
			</cfquery>
			<cfif len(problemsInData.c) gt 0>
				<h3 class="mt-3">
					There is a problem with #problemsInData.c# of #data.recordcount# row(s). See the STATUS column. (<a href="/tools/BulkloadCollectingEvents.cfm?action=dumpProblems" class="btn-link font-weight-lessbold">download</a>). Fix the problems in the data and <a href="/tools/BulkloadCollectingEvents.cfm" class="text-danger">start again</a>.
				</h3>
			<cfelse>
				<h3 class="mt-3">
					<span class="text-success">Validation checks passed</span>. Look over the table below and <a href="/tools/BulkloadCollectingEvents.cfm?action=load" class="btn-link font-weight-lessbold">click to continue</a> if it all looks good or <a href="/tools/BulkloadCollectingEvents.cfm" class="text-danger">start again</a>.
				</h3>
			</cfif>
	
			<table class='sortable px-0 mx-0 table small table-responsive table-striped w-100'>
				<thead class="thead-light">
					<tr>
						<th>STATUS&nbsp;<span style='color:##e9ecef'>for&nbsp;Bulkloader</span></th>
						<th>DATE_DETERMINED_BY_AGENT_ID</th>
						<th>SPEC_LOCALITY</th>
						<th>LOCALITY_ID</th>
						<th>VERBATIM_DATE</th>
						<th>VERBATIM_LOCALITY</th>
						<th>COLL_EVENT_REMARKS</th>
						<th>VALID_DISTRIBUTION_FG</th>
						<th>COLLECTING_SOURCE</th>
						<th>COLLECTING_METHOD</th>
						<th>HABITAT_DESC</th>
						<th>DATE_DETERMINED_BY_AGENT</th>
						<th>FISH_FIELD_NUMBER</th>
						<th>BEGAN_DATE</th>
						<th>ENDED_DATE</th>
						<th>COLLECTING_TIME</th>
						<th>VERBATIMCOORDINATES</th>
						<th>VERBATIMLATITUDE</th>
						<th>VERBATIMLONGITUDE</th>
						<th>VERBATIMCOORDINATESYSTEM</th>
						<th>VERBATIMSRS</th>
						<th>STARTDAYOFYEAR</th>
						<th>ENDDAYOFYEAR</th>
						<th>VERBATIMELEVATION</th>
						<th>VERBATIMDEPTH</th>
						<th>VERBATIM_COLLECTORS</th>
						<th>VERBATIM_FIELD_NUMBERS</th>
						<th>VERBATIM_HABITAT</th>
					</tr>
				</thead>
				<tbody>
					<cfloop query="data">
						<tr>
							<td><cfif len(data.status) eq 0>Cleared to load<cfelse><strong>#data.status#</strong></cfif></td>
							<td>#data.DATE_DETERMINED_BY_AGENT_ID#</td>
							<td>#data.SPEC_LOCALITY#</td>
							<td>#data.LOCALITY_ID#</td>
							<td>#data.VERBATIM_DATE#</td>
							<td>#data.VERBATIM_LOCALITY#</td>
							<td>#data.COLL_EVENT_REMARKS#</td>
							<td>#data.VALID_DISTRIBUTION_FG#</td>
							<td>#data.COLLECTING_SOURCE#</td>
							<td>#data.COLLECTING_METHOD#</td>
							<td>#data.HABITAT_DESC#</td>
							<td>#data.DATE_DETERMINED_BY_AGENT#</td>
							<td>#data.FISH_FIELD_NUMBER#</td>
							<td>#data.BEGAN_DATE#</td>
							<td>#data.ENDED_DATE#</td>
							<td>#data.COLLECTING_TIME#</td>
							<td>#data.VERBATIMCOORDINATES#</td>
							<td>#data.VERBATIMLATITUDE#</td>
							<td>#data.VERBATIMLONGITUDE#</td>
							<td>#data.VERBATIMCOORDINATESYSTEM#</td>
							<td>#data.VERBATIMSRS#</td>
							<td>#data.STARTDAYOFYEAR#</td>
							<td>#data.ENDDAYOFYEAR#</td>
							<td>#data.VERBATIMELEVATION#</td>
							<td>#data.VERBATIMDEPTH#</td>
							<td>#data.VERBATIM_COLLECTORS#</td>
							<td>#data.VERBATIM_FIELD_NUMBERS#</td>
							<td>#data.VERBATIM_HABITAT#</td>
						</tr>
					</cfloop>
				</tbody>
			</table>
		</cfoutput>
	</cfif>
	<!-------------------------------------------------------------------------------------------->

	<cfif variables.action is "load">
		<h2 class="h3">Third step: Apply changes.</h2>
		<cfoutput>
			<cfset problem_key = "">
			<cfset addedCollectingEventIDs = "">
			<cftransaction>
				<cftry>
					<cfquery name="getData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						SELECT *
						FROM cf_temp_collecting_event
						WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
					</cfquery>
					<cfif getData.recordcount EQ 0>
						<cfthrow message="You have no rows to load in the collecting event bulkloader. <a href='/tools/BulkloadCollectingEvent.cfm'>Start over</a>">
					</cfif>
					<cfset coll_event_updates = 0>
					<cfloop query="getData">
						<cfquery name="nextColl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							SELECT sq_collecting_event_id.nextval nextColl FROM dual
						</cfquery>
						<cfset addedCollectingEventIDs = ListAppend(addedCollectingEventIDs,nextColl.nextColl) >
						<cfquery name="makeCollectingEvent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="insResult">
							INSERT INTO collecting_event (
								COLLECTING_EVENT_ID,
								LOCALITY_ID,
								BEGAN_DATE,
								ENDED_DATE,
								VERBATIM_DATE,
								COLLECTING_SOURCE,
								VERBATIM_LOCALITY,
								VERBATIMDEPTH,
								VERBATIMELEVATION,
								COLL_EVENT_REMARKS,
								COLLECTING_METHOD,
								HABITAT_DESC,
								collecting_time,
								VERBATIMCOORDINATES,
								VERBATIMLATITUDE,
								VERBATIMLONGITUDE,
								VERBATIMCOORDINATESYSTEM,
								VERBATIMSRS,
								STARTDAYOFYEAR,
								ENDDAYOFYEAR,
								FISH_FIELD_NUMBER,
								DATE_DETERMINED_BY_AGENT_ID,
								VALID_DISTRIBUTION_FG ,
								VERBATIM_COLLECTORS ,
								VERBATIM_FIELD_NUMBERS ,
								VERBATIM_HABITAT
							) VALUES (
								<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#nextColl.nextColl#">
								,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getData.LOCALITY_ID#">
								,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getData.BEGAN_DATE#">
								,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getData.ENDED_DATE#">
								,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getData.VERBATIM_DATE#">
								,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getData.COLLECTING_SOURCE#">
								<cfif len(#VERBATIM_LOCALITY#) gt 0>
									,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getData.VERBATIM_LOCALITY#">
								<cfelse>
									,NULL
								</cfif>
								<cfif len(#VERBATIMDEPTH#) gt 0>
									,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getData.VERBATIMDEPTH#">
								<cfelse>
									,NULL
								</cfif>
								<cfif len(#VERBATIMELEVATION#) gt 0>
									,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getData.VERBATIMELEVATION#">
								<cfelse>
									,NULL
								</cfif>
								<cfif len(#COLL_EVENT_REMARKS#) gt 0>
									,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getData.COLL_EVENT_REMARKS#">
								<cfelse>
									,NULL
								</cfif>
								<cfif len(#COLLECTING_METHOD#) gt 0>
									,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getData.COLLECTING_METHOD#">
								<cfelse>
									,NULL
								</cfif>
								<cfif len(#HABITAT_DESC#) gt 0>
									,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getData.HABITAT_DESC#">
								<cfelse>
									,NULL
								</cfif>
								<cfif len(#collecting_time#) gt 0>
									,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getData.collecting_time#">
								<cfelse>
									,NULL
								</cfif>
								<cfif len(#VERBATIMCOORDINATES#) gt 0>
									,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getData.VERBATIMCOORDINATES#">
								<cfelse>
									,NULL
								</cfif>
								<cfif len(#VERBATIMLATITUDE#) gt 0>
									,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getData.VERBATIMLATITUDE#">
								<cfelse>
									,NULL
								</cfif>
								<cfif len(#VERBATIMLONGITUDE#) gt 0>
									,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getData.VERBATIMLONGITUDE#">
								<cfelse>
									,NULL
								</cfif>
								<cfif len(#VERBATIMCOORDINATESYSTEM#) gt 0>
									,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getData.VERBATIMCOORDINATESYSTEM#">
								<cfelse>
									,NULL
								</cfif>
								<cfif len(#VERBATIMSRS#) gt 0>
									,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getData.VERBATIMSRS#">
								<cfelse>
									,NULL
								</cfif>
								<cfif len(#STARTDAYOFYEAR#) gt 0>
									,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getData.STARTDAYOFYEAR#">
								<cfelse>
									,NULL
								</cfif>
								<cfif len(#ENDDAYOFYEAR#) gt 0>
									,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getData.ENDDAYOFYEAR#">
								<cfelse>
									,NULL
								</cfif>
								<cfif len(#fish_field_number#) gt 0>
									,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getData.fish_field_number#">
								<cfelse>
									,NULL
								</cfif>
								<cfif len(#date_determined_by_agent_id#) gt 0>
									,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getData.date_determined_by_agent_id#">
								<cfelse>
									,NULL
								</cfif>
								<cfif len(#valid_distribution_fg#) gt 0>
									,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getData.valid_distribution_fg#">
								<cfelse>
									,1
								</cfif>
								<cfif len(#verbatim_collectors#) gt 0>
									,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getData.verbatim_collectors#">
								<cfelse>
									,NULL
								</cfif>
								<cfif len(#verbatim_field_numbers#) gt 0>
									,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getData.verbatim_field_numbers#">
								<cfelse>
									,NULL
								</cfif>
								<cfif len(#verbatim_habitat#) gt 0>
									,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getData.verbatim_habitat#">
								<cfelse>
									,NULL
								</cfif>
							)
						</cfquery>
						<cfset coll_event_updates = coll_event_updates + insResult.recordcount>
					</cfloop>
					<p class="mt-2">Number of Collecting Events added: <b>#coll_event_updates#</b> </p>
					<cfif #getData.recordcount# eq #coll_event_updates#>
						<h3 class="text-success">Success - loaded</h3>
						<div>
							<p class="mt-2"><a href="/localities/CollectingEvents.cfm?action=search&execute=true&method=getCollectingEvents&MinElevOper=%3D&MaxElevOper=%3D&MinElevOperM=%3D&MaxElevOperM=%3D&minDepthOper=%3D&MaxDepthOper=%3D&minDepthOperM=%3D&MaxDepthOperM=%3D&geology_attribute_hier=0&gs_comparator=%3D&&collecting_event_id=#encodeForUrl(addedCollectingEventIds)#&begDateOper=%3D&endDateOper=%3D&accentInsensitive=1&include_counts=0">Added Collecting Events</a></p>
							<p class="mt-2"><a href="/tools/BulkloadCollectingEvents.cfm" class="btn btn-primary">Add more</a></p>
						</div>
					<cfelse>
						<cfthrow message="Number to insert not equal to number inserted.">
					</cfif>
					<cftransaction action="commit">
				<cfcatch>
					<cftransaction action="ROLLBACK">
					<h3>There was a problem adding collecting_events. </h3>
					<cfquery name="getProblemData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						SELECT *
						FROM cf_temp_collecting_event
						WHERE 
							key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#problem_key#">
							AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
					</cfquery>
					<cfif getProblemData.recordcount GT 0>
						<h3>
							Fix the issues and <a href="/tools/BulkloadCollectingEvents.cfm">start again</a>. Error loading row (<span class="text-danger">#coll_event_updates + 1#</span>) from the CSV: 
							<cfif len(cfcatch.detail) gt 0>
								<span class="font-weight-normal border-bottom border-danger">
									Error: #cfcatch.detail#
								</span>
							</cfif>
						</h3>
						<table class='mx-0 px-0 sortable table-danger table table-responsive table-striped mt-3'>
							<thead class="thead-light">
								<tr>
									<th>ROW</th>
									<th>LOCALITY_ID</th>
									<th>DATE_DETERMINED_BY_AGENT_ID</th>
									<th>VERBATIM_DATE</th>
									<th>VERBATIM_LOCALITY</th>
									<th>COLL_EVENT_REMARKS</th>
									<th>VALID_DISTRIBUTION_FG</th>
									<th>COLLECTING_SOURCE</th>
									<th>COLLECTING_METHOD</th>
									<th>HABITAT_DESC</th>
									<th>DATE_DETERMINED_BY_AGENT</th>
									<th>FISH_FIELD_NUMBER</th>
									<th>BEGAN_DATE</th>
									<th>ENDED_DATE</th>
									<th>COLLECTING_TIME</th>
									<th>VERBATIMCOORDINATES</th>
									<th>VERBATIMLATITUDE</th>
									<th>VERBATIMLONGITUDE</th>
									<th>VERBATIMCOORDINATESYSTEM</th>
									<th>VERBATIMSRS</th>
									<th>STARTDAYOFYEAR</th>
									<th>ENDDAYOFYEAR</th>
									<th>VERBATIMELEVATION</th>
									<th>VERBATIMDEPTH</th>
									<th>VERBATIM_COLLECTORS</th>
									<th>VERBATIM_FIELD_NUMBERS</th>
									<th>VERBATIM_HABITAT</th>
								</tr> 
							</thead>
							<tbody>
								<cfset i=1>
								<cfloop query="getProblemData">
									<tr>										
										<td>#i#</td>
										<td>#getProblemData.LOCALITY_ID#</td>
										<td>#getProblemData.DATE_DETERMINED_BY_AGENT_ID#</td>
										<td>#getProblemData.VERBATIM_DATE#</td>
										<td>#getProblemData.VERBATIM_LOCALITY#</td>
										<td>#getProblemData.COLL_EVENT_REMARKS#</td>
										<td>#getProblemData.VALID_DISTRIBUTION_FG#</td>
										<td>#getProblemData.COLLECTING_SOURCE#</td>
										<td>#getProblemData.COLLECTING_METHOD#</td>
										<td>#getProblemData.HABITAT_DESC#</td>
										<td>#getProblemData.DATE_DETERMINED_BY_AGENT#</td>
										<td>#getProblemData.FISH_FIELD_NUMBER#</td>
										<td>#getProblemData.BEGAN_DATE#</td>
										<td>#getProblemData.ENDED_DATE#</td>
										<td>#getProblemData.COLLECTING_TIME#</td>
										<td>#getProblemData.VERBATIMCOORDINATES#</td>
										<td>#getProblemData.VERBATIMLATITUDE#</td>
										<td>#getProblemData.VERBATIMLONGITUDE#</td>
										<td>#getProblemData.VERBATIMCOORDINATESYSTEM#</td>
										<td>#getProblemData.VERBATIMSRS#</td>
										<td>#getProblemData.STARTDAYOFYEAR#</td>
										<td>#getProblemData.ENDDAYOFYEAR#</td>
										<td>#getProblemData.VERBATIMELEVATION#</td>
										<td>#getProblemData.VERBATIMDEPTH#</td>
										<td>#getProblemData.VERBATIM_COLLECTORS#</td>
										<td>#getProblemData.VERBATIM_FIELD_NUMBERS#</td>
										<td>#getProblemData.VERBATIM_HABITAT#</td>
									</tr>
									<cfset i= i+1>
								</cfloop>
							</tbody>
						</table>
					</cfif>
					<div>#cfcatch.detail# <br>#cfcatch.message#</div>
					<cfif isdefined("session.roles") and listfindnocase(session.roles,"global_admin")>
						<div>
							<cfdump var="#cfcatch#">
						</div>
					</cfif>
				</cfcatch>
				</cftry>
			</cftransaction>
			<cfquery name="clearTempTable" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="clearTempTable_result">
				DELETE FROM cf_temp_collecting_event
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
		</cfoutput>
	</cfif>
</main>

<cfinclude template="/shared/_footer.cfm">
