<!--- tools/bulkloadGeoref.cfm.cfm add georeferences to localities in bulk.

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
			highergeography,speclocality,locality_id,dec_lat,dec_long,max_error_distance,max_error_units,lat_long_remarks,determined_by_agent,georefmethod,orig_lat_long_units,datum,determined_date,lat_long_ref_source,extent,extent_units,gpsaccuracy,verificationstatus,verified_by,spatialfit,nearest_named_place,lat_long_for_NNP_FG,coordinate_precision,determined_by_agent_id,LAT_DEG,LAT_SEC,LAT_MIN,LAT_DIR,LONG_DEG,LONG_MIN,LONG_SEC,LONG_DIR
		FROM cf_temp_georef 
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

<cfset fieldlist = "HIGHERGEOGRAPHY,SPECLOCALITY,LOCALITY_ID,DEC_LAT,DEC_LONG,DETERMINED_BY_AGENT,GEOREFMETHOD,ORIG_LAT_LONG_UNITS,DATUM,DETERMINED_DATE,LAT_LONG_REF_SOURCE,VERIFICATIONSTATUS,COORDINATE_PRECISION,MAX_ERROR_DISTANCE,MAX_ERROR_UNITS,LAT_LONG_REMARKS,EXTENT,EXTENT_UNITS,GPSACCURACY,VERIFIED_BY,SPATIALFIT,NEAREST_NAMED_PLACE,LAT_LONG_FOR_NNP_FG,DETERMINED_BY_AGENT_ID,VERIFIED_BY_AGENT_ID,LAT_DEG,LAT_SEC,LAT_MIN,LAT_DIR,LONG_DEG,LONG_MIN,LONG_SEC,LONG_DIR">

<cfset fieldTypes="CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_DECIMAL,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_DATE,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_DECIMAL,CF_SQL_DECIMAL,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_DECIMAL,CF_SQL_VARCHAR,CF_SQL_DECIMAL,CF_SQL_VARCHAR,CF_SQL_DECIMAL,CF_SQL_VARCHAR,CF_SQL_DECIMAL,CF_SQL_DECIMAL,CF_SQL_DECIMAL,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR">

<cfif listlen(fieldlist) NEQ listlen(fieldTypes)>
	<cfthrow message = "Error: Bug in the definition of fieldlist[#listlen(fieldlist)#] and fieldType[#listlen(fieldTypes)#] lists, lists must be the same length, but are not.">
</cfif>
	
<cfset requiredfieldlist = "DEC_LAT,DEC_LONG,DETERMINED_BY_AGENT,GEOREFMETHOD,ORIG_LAT_LONG_UNITS,DATUM,DETERMINED_DATE,LAT_LONG_REF_SOURCE,VERIFICATIONSTATUS,COORDINATE_PRECISION,MAX_ERROR_DISTANCE,MAX_ERROR_UNITS">

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
<cfset pageTitle = "Bulkload Georeferences">
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
			<p>Load a new accepted georeference to a locality record. HigherGeography and SpecLocality, if provided, can be used to look up a locality_id in MCZbase data or the locality_id can be provided alone. The locality_id will be used to cross reference the HigherGeography and SpecLocality data (to either verify provided data or add where missing). Check each step to be sure what is expected is being loaded. If in doubt, give your filled-out template to Collections Operations to load.</p>
			<p>For guidance on georeferencing see: Chapman AD and Wieczorek JR (2020) Georeferencing Best Practices. <a href="https://doi.org/10.15468/doc-gg7h-s853" target="_blank">DOI: 10.15468/doc-gg7h-s853</a></p>
			<h2 class="h4">Use Template to Load Data</h2>
			<button class="btn btn-xs btn-primary float-left mr-3" id="copyButton">Copy Column Headers</button>
			<div id="template" class="my-1 mx-0">
				<label for="templatearea" class="data-entry-label" style="line-height: inherit;">
					Copy this header line, paste it into a blank worksheet, and save it as a .csv file or <a href="/tools/BulkloadGeoref.cfm?action=getCSVHeader" class="font-weight-bold">download</a> a template.
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
											and table_name = 'CF_TEMP_GEOREF'
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
				<form name="getFiles" method="post" enctype="multipart/form-data" action="/tools/BulkloadGeoref.cfm">
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
			<cfset TABLE_NAME = "CF_TEMP_GEOREF">
				<cftry>
				<!--- cleanup any incomplete work by the same user --->
				<cfquery name="killOld" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					DELETE FROM CF_TEMP_GEOREF
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
									insert into cf_temp_georef
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
								you probably want to <a href="/tools/BulkloadGeoref.cfm">reload this file</a> selecting a different encoding. If these appear as expected, then you selected the correct encoding and can continue to validate or load.</p>
							</div>
							<ul class="pb-1 h4 list-unstyled">#foundHighAscii# #foundMultiByte#</ul>

						</cfif>
					</div>
					<h3 class="h4">
						Successfully read #loadedRows# records from the CSV file. Next <a href="/tools/BulkloadGeoref.cfm?action=validate" class="btn-link font-weight-lessbold">click to validate</a>.
					</h3>

				<cfcatch>
					<h3 class="h4">
						Failed to read the CSV file.  Fix the errors in the file and <a href="/tools/BulkloadGeoref.cfm">reload</a>.
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

		<cfoutput>
			<h2 class="h4">Second step: Data Validation</h2>
			<!--- Validating data in bulk --->
			<!--- Checks that do not require looping through the data, check for missing required data, missing values from key value pairs, bad formats and values that do not match database code tables--->
			<cfquery name="warningMissingAlternative" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE CF_TEMP_GEOREF
				SET status = concat(nvl2(status, status || '; ', ''),'If locality_id is not provided, HigherGeography and SpecLocality must be provided')
				WHERE
					locality_id is null 
					AND (HIGHERGEOGRAPHY is null OR SPECLOCALITY is null)
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<!--- TODO: Support more fields than just dec_lat and dec_long. --->
			<cfquery name="unsupportedUnits" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE CF_TEMP_GEOREF
				SET status = concat(nvl2(status, status || '; ', ''),'Unsupported orig_lat_long_units.')
				WHERE
					orig_lat_long_units <> 'decimal degrees'
					AND orig_lat_long_units <> 'deg. min. sec.'
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="UTMCheck" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE CF_TEMP_GEOREF
				SET status = concat(nvl2(status, status || '; ', ''),'If UTM_ZONE is provided both UTM easting and northing must be provided.')
				WHERE
					utm_zone is not null
					AND (utm_ew is null or utm_ns is null)
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="UTMCheckLen" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE CF_TEMP_GEOREF
				SET status = concat(nvl2(status, status || '; ', ''),'UTM_ZONE can be no more than three characters, USNG and MGRS coordinates are not supported.')
				WHERE
					utm_zone is not null 
					AND length(utm_zone) > 3
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="UTMEastingNorthingType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE CF_TEMP_GEOREF
				SET status = concat(nvl2(status, status || '; ', ''),'UTM_EW and UTM_NS can only contain numbers, USNG and MGRS coordinates are not supported.')
				WHERE
					utm_ew is not null and utm_ns is not null
					AND NOT (REGEXP_LIKE(utm_ew, '^[0-9]+$') AND REGEXP_LIKE(utm_ns, '^[0-9]+$'))
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<!---Prevent Duplicate Accepted IDs from loading--->
			<!---Prevent Duplicate Accepted IDs from loading--->
			<cfquery name="warningDuplicatedRows" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE CF_TEMP_GEOREF 
				SET status = concat(nvl2(status, status || '; ', ''),'Only one record per locality_id is allowed')
				WHERE 
					locality_id in 
						(select locality_id from CF_TEMP_GEOREF group by locality_id 
						having count(*) > 1)
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<!---Check ORIG_LAT_LONG_UNITS in code table--->
			<cfquery name="warningOrigLatLongUnits" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE cf_temp_georef
				SET status = concat(nvl2(status, status || '; ', ''),'Original Lat Long Units are invalid - see <a href="/vocabularies/ControlledVocabulary.cfm?table=CTLAT_LONG_UNITS">controlled vocabulary</a>')
				WHERE orig_lat_long_units not in (select ORIG_LAT_LONG_UNITS from CTLAT_LONG_UNITS) AND
					ORIG_LAT_LONG_UNITS is not null AND
					username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<!---Check Datum in code table--->
			<cfquery name="warningDatum" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE cf_temp_georef
				SET status = concat(nvl2(status, status || '; ', ''),'DATUM does not match - See <a href="/vocabularies/ControlledVocabulary.cfm?table=CTEXTENT_UNITS">controlled vocabulary</a>')
				WHERE DATUM not in (select DATUM from CTDATUM ) AND
					username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>

			<!---Check max_error_units in code table--->
			<cfquery name="warningErrorUnits" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE cf_temp_georef
				SET status = concat(nvl2(status, status || '; ', ''),'MAX_ERROR_UNITS are invalid - See <a href="/vocabularies/ControlledVocabulary.cfm?table=CTLAT_LONG_ERROR_UNITS">controlled vocabulary</a>')
				WHERE MAX_ERROR_UNITS is not null AND
					MAX_ERROR_UNITS not in (select LAT_LONG_ERROR_UNITS from CTLAT_LONG_ERROR_UNITS ) 
				AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
	
			<!--- If locality_id is entered, see if it matches one in MCZbase --->
			<cfquery name="warningLOCALITYID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE cf_temp_georef
				SET status = concat(nvl2(status, status || '; ', ''),'LOCALITY_ID does not exist in MCZbase')
				WHERE LOCALITY_ID not in (select LOCALITY_ID from locality)
					AND LOCALITY_ID is not null
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<!--- If spec_locality is entered, see if it matches one in MCZbase --->
				<cfquery name="warningSpec" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE cf_temp_georef
				SET status = concat(nvl2(status, status || '; ', ''),'SPECLOCALITY does not exist in MCZbase')
				WHERE 
					SPECLOCALITY not in (
						select spec_locality from locality
						) 
					AND SPECLOCALITY is not null
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<!---Check lat_long_ref_source--->
			<cfquery name="warningRefSource" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE cf_temp_georef
				SET status = concat(nvl2(status, status || '; ', ''),'LAT_LONG_REF_SOURCE is invalid - see <a href="/vocabularies/ControlledVocabulary.cfm?table=CTLAT_LONG_REF_SOURCE">controlled vocabulary</a>')
				WHERE 
					LAT_LONG_REF_SOURCE not in 
						(select LAT_LONG_REF_SOURCE from CTLAT_LONG_REF_SOURCE)
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>

			<!--- Check Extent in code table--->
			<cfquery name="warningExtent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE cf_temp_georef
				SET status = concat(nvl2(status, status || '; ', ''),'EXTENT_UNITS does not exist')
				WHERE 
					EXTENT_UNITS not in 
						(select UNITS from MCZBASE.CTEXTENT_UNITS)
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="warningHigherGeog" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE cf_temp_georef
				SET status = concat(nvl2(status, status || '; ', ''),'Higher Geography does not exist')
				WHERE 
					HIGHERGEOGRAPHY not in 
						(select HIGHER_GEOG from GEOG_AUTH_REC) 
					AND HIGHERGEOGRAPHY is not null 
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="degminsecCheck" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE cf_temp_georef
				SET status = concat(nvl2(status, status || '; ', ''),'All of LAT_DEG, LAT_MIN, LAT_SEC, LAT_DIR, LONG_DEG, LONG_MIN, LONG_SEC, LONG_DIR must be entered when original units are deg. min. sec.')
				WHERE 
					(	
						LAT_DEG is null OR LAT_MIN is null OR LAT_SEC is null OR LAT_DIR is null 
						OR LONG_DEG is null OR LONG_MIN is null OR LONG_SEC is null OR LONG_DIR is null
					)
					AND orig_lat_long_units = 'deg. min. sec.'
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="decdegCheck" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE cf_temp_georef
				SET status = concat(nvl2(status, status || '; ', ''),'None of of LAT_DEG, LAT_MIN, LAT_SEC, LAT_DIR, LONG_DEG, LONG_MIN, LONG_SEC, LONG_DIR may be entered when original units are decimal degrees.')
				WHERE 
					(	
						LAT_DEG is not null OR LAT_MIN is not null OR LAT_SEC is not null OR LAT_DIR is not null 
						OR LONG_DEG is not null OR LONG_MIN is not null OR LONG_SEC is not null OR LONG_DIR is not null
					)
					AND orig_lat_long_units = 'decimal degrees'
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="latDirCheck" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE cf_temp_georef
				SET status = concat(nvl2(status, status || '; ', ''),'LAT_DIR must be N or S.')
				WHERE 
					LAT_DIR is not null 
					AND LAT_DIR <> 'N' 
					AND LAT_DIR <> 'S' 
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="longDirCheck" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE cf_temp_georef
				SET status = concat(nvl2(status, status || '; ', ''),'LONG_DIR must be W or W.')
				WHERE 
					LAT_DIR is not null 
					AND LONG_DIR <> 'E' 
					AND LONG_DIR <> 'W' 
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="latTypeCheck" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE cf_temp_georef
				SET status = concat(nvl2(status, status || '; ', ''),'LAT_DEG must be a positive integer in the range 0 to 90.')
				WHERE 
					LAT_DEG is not null 
					AND NOT regexp_like(LAT_DEG,'^[0-9]+$')
					AND TO_NUMBER(LAT_DEG) < 0 
					AND TO_NUMBER(LAT_DEG) > 90 
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="longTypeCheck" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE cf_temp_georef
				SET status = concat(nvl2(status, status || '; ', ''),'LONG_DEG must be a positive integer in the range 0 to 180.')
				WHERE 
					LONG_DEG is not null 
					AND NOT regexp_like(LONG_DEG,'^[0-9]+$')
					AND TO_NUMBER(LONG_DEG) < 0 
					AND TO_NUMBER(LONG_DEG) > 180
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="minTypeCheck" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE cf_temp_georef
				SET status = concat(nvl2(status, status || '; ', ''),'LAT_MIN and LONG_MIN must be positive integers in the range 0 to 60.')
				WHERE 
					LAT_MIN is not null 
					AND NOT regexp_like(LAT_MIN,'^[0-9]+$')
					AND TO_NUMBER(LAT_MIN) < 0 
					AND TO_NUMBER(LAT_MIN) > 60
					AND LONG_MIN is not null 
					AND NOT regexp_like(LONG_MIN,'^[0-9]+$')
					AND TO_NUMBER(LONG_MIN) < 0 
					AND TO_NUMBER(LONG_MIN) > 60
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="secTypeCheck" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE cf_temp_georef
				SET status = concat(nvl2(status, status || '; ', ''),'LAT_SEC and LONG_SEC must be positive numbers in the range 0 to 60.')
				WHERE 
					LAT_MIN is not null 
					AND NOT regexp_like(LAT_MIN,'^[0-9.]+$')
					AND TO_NUMBER(LAT_MIN) < 0 
					AND TO_NUMBER(LAT_MIN) > 60
					AND LONG_MIN is not null 
					AND NOT regexp_like(LONG_MIN,'^[0-9.]+$')
					AND TO_NUMBER(LONG_MIN) < 0 
					AND TO_NUMBER(LONG_MIN) > 60
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="decLatCheck" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE cf_temp_georef
				SET status = concat(nvl2(status, status || '; ', ''),'DEC_LAT must be a number in the range 0 to 90.')
				WHERE 
					NOT regexp_like(DEC_LAT,'^[0-9.-]+$')
					AND TO_NUMBER(DEC_LAT) < 0 
					AND TO_NUMBER(DEC_LAT) > 90
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="decLongCheck" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE cf_temp_georef
				SET status = concat(nvl2(status, status || '; ', ''),'DEC_LONG must be a number in the range 0 to 180.')
				WHERE 
					NOT regexp_like(DEC_LONG,'^[0-9.-]+$')
					AND TO_NUMBER(DEC_LONG) < 0 
					AND TO_NUMBER(DEC_LONG) > 180
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>

			<!--- Validation queries that test against individual rows looping through data in temp table --->
			<!--- Get Data from the temp table and the codetables with relevant information --->
			<cfquery name="getTempData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT HIGHERGEOGRAPHY,SPECLOCALITY,LOCALITY_ID,DEC_LAT,DEC_LONG,DETERMINED_BY_AGENT,
						GEOREFMETHOD,ORIG_LAT_LONG_UNITS,DATUM,DETERMINED_DATE,LAT_LONG_REF_SOURCE,
						VERIFICATIONSTATUS,COORDINATE_PRECISION,MAX_ERROR_DISTANCE,MAX_ERROR_UNITS,
						LAT_LONG_REMARKS,EXTENT,EXTENT_UNITS,GPSACCURACY,
						VERIFIED_BY,VERIFIED_BY_AGENT_ID,DETERMINED_BY_AGENT_ID,
						SPATIALFIT,NEAREST_NAMED_PLACE,LAT_LONG_FOR_NNP_FG,
						LAT_DEG, LAT_MIN, LAT_SEC, LAT_DIR, LONG_DEG, LONG_MIN, LONG_SEC, LONG_DIR,
						KEY
				FROM CF_TEMP_GEOREF
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfloop query="getTempData">
				<!--- check for any existing accepted lat_long records --->
				<!--- currently unable to insert if accepted record exists --->
				<cfquery name="warningMissingSpecLoc" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE cf_temp_georef
					SET status = concat(nvl2(status, status || '; ', ''),'There is already an accepted georeference for this locality.')
					WHERE 
						locality_id IN (
							SELECT locality_id
							FROM LAT_LONG
							WHERE locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempData.locality_id#">
								AND accepted_lat_long_fg = 1
						)
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						AND key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.key#">
				</cfquery>
				<cfset agentProblem1 = "">
				<!--- Determination Agent --->
				<cfset relatedAgentID = "">
				<!--- Check that either spec_locality or locality_id is entered --->
				<cfif len(getTempData.LOCALITY_ID) eq 0>
					<cfif len(getTempData.HIGHERGEOGRAPHY) eq 0>
						<cfquery name="warningMissingSpecLoc" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							UPDATE cf_temp_georef
							SET status = concat(nvl2(status, status || '; ', ''),'HIGHERGEOGRAPHY needs to be entered')
							WHERE (HIGHERGEOGRAPHY is null) AND
								username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
								AND key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.key#">
						</cfquery>
					</cfif>
					<cfif len(getTempData.SPECLOCALITY) eq 0>
						<cfquery name="warningMissingSpecLoc" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							UPDATE cf_temp_georef
							SET status = concat(nvl2(status, status || '; ', ''),'SPECLOCALITY needs to be entered')
							WHERE (SPECLOCALITY is null) AND
								username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
								AND key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.key#">
						</cfquery>
					</cfif>		
				<cfelse>
					<cfif len(SPECLOCALITY) eq 0>
						<cfquery name="updateSpecLocality" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							UPDATE cf_temp_georef
							SET SPECLOCALITY = (
									select spec_locality 
									from LOCALITY
									where locality_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.locality_id#">
								)
							WHERE locality_ID is not null 
								AND SPECLOCALITY is null 
								AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
								AND key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.key#">
						</cfquery>
					</cfif>
					<cfif len(HIGHERGEOGRAPHY) eq 0>
						<cfquery name="updatehighergeography" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							UPDATE cf_temp_georef
							SET HIGHERGEOGRAPHY = (
									select higher_geog 
									from geog_auth_rec
									join locality on geog_auth_rec.GEOG_AUTH_REC_ID = locality.geog_auth_rec_id
									where locality_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.locality_id#">
								)
							WHERE HIGHERGEOGRAPHY is null
								and locality_id is not null
								AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
								AND key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.key#">
						</cfquery>
					</cfif>
					<cfquery name="warningHGSpecLoc" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						UPDATE cf_temp_georef
						SET status = concat(nvl2(status, status || '; ', ''),'Higher Geography is not correct for the given locality_id')
						WHERE HIGHERGEOGRAPHY not in (
								select HIGHER_GEOG 
								from GEOG_AUTH_REC 
									join locality on geog_auth_rec.GEOG_AUTH_REC_ID = locality.geog_auth_rec_id 
								where locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempData.locality_id#">
							)
							AND HIGHERGEOGRAPHY is not null 
							AND locality_id is not null 
							AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
							AND key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.key#">
					</cfquery>
					<cfquery name="warningHGSpecLoc" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						UPDATE cf_temp_georef
						SET status = concat(nvl2(status, status || '; ', ''),'SPECLOCALITY is not correct for the given locality_id')
						WHERE SPECLOCALITY not in (
								select spec_locality
								from locality 
								where locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempData.locality_id#">
							)
							AND locality_id is not null 
							AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
							AND key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.key#">
					</cfquery>
				</cfif>
						
				<cfif len(getTempData.determined_by_agent) gt 0>
					<cfquery name="findAgentDet" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						SELECT agent_id 
						FROM agent_name 
						WHERE agent_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.determined_by_agent#">
							and agent_name_type = 'preferred'
					</cfquery>
					<cfif findAgentDet.recordCount EQ 1>
						<cfset relatedAgentID = findAgentDet.agent_id>
					<cfelseif findAgentDet.recordCount EQ 0>
						<!--- relax criteria, find agent by any name. --->
						<cfquery name="findAgentAnyDet" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							SELECT agent_id 
							FROM agent_name 
							WHERE agent_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.determined_by_agent#">
						</cfquery>
						<cfif findAgentAnyDet.recordCount EQ 1>
							<cfset relatedAgentID = findAgentAnyDet.agent_id>
						<cfelseif findAgentAnyDet.recordCount EQ 0>
							<cfset agentProblem1 = "no matches to any agent name">
						<cfelse>
							<cfset agentProblem1 = "matches to multiple agent names, use agent_id">
						</cfif>
					<cfelse>
						<cfset agentProblem1 = "matches to multiple preferred agent names, use agent_id">
					</cfif>
					<!---update the table with the agentID found above--->	
					<cfif findAgentDet.recordCount EQ 1 OR findAgentAnyDet.recordCount EQ 1>
						<cfquery name="chkDAID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							UPDATE cf_temp_georef 
							SET determined_by_agent_id = #relatedAgentID#
							WHERE determined_by_agent_ID is null
								AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
								and key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.key#">
						</cfquery>
					<cfelse>
						<cfquery name="warningDetermined" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							UPDATE cf_temp_georef
							SET status = concat(nvl2(status, status || '; ', ''),'Determiner is not found because #agentProblem1#')
							WHERE determined_by_agent is not null 
								AND determined_by_agent not in (select agent_name from agent_name)
								AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
								and key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.key#">
						</cfquery>
					</cfif>
				<cfelse>
					<cfquery name="warningDetMissing" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						UPDATE cf_temp_georef
						SET status = concat(nvl2(status, status || '; ', ''),'Determined_by_agent needs a value')
						WHERE determined_by_agent is null
							AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
							and key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.key#">
					</cfquery>
				</cfif>
						
				<!---Verified by checked against all names for agents and checked against verificationstatus--->			
				<cfif len(verified_by) gt 0>
					<cfset agentProblem2 = "">
					<cfset relatedVerAgentID = "">
					<cfquery name="findAgentVer" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						SELECT agent_id 
						FROM agent_name 
						WHERE agent_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.verified_by#">
							AND agent_name_type = 'preferred'
					</cfquery>
					<cfif findAgentVer.recordCount EQ 1>
						<cfset relatedVerAgentID = findAgentVer.agent_id>
						<cfquery name="chkDAID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							UPDATE cf_temp_georef 
							SET verified_by_agent_id = #relatedVerAgentID#
							WHERE verified_by_agent_ID is null
								AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
								and key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.key#">
						</cfquery>
					<cfelseif findAgentVer.recordCount EQ 0>
						<!--- relax criteria, find agent by any name. --->
						<cfquery name="findAgentAnyVer" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							SELECT agent_id 
							FROM agent_name 
							WHERE agent_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.verified_by#">
						</cfquery>
						<cfif findAgentAnyVer.recordCount EQ 1>
							<cfset relatedVerAgentID = findAgentAnyVer.agent_id>
							<cfquery name="chkDAID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
								UPDATE cf_temp_georef 
								SET verified_by_agent_id = #relatedVerAgentID#
								WHERE verified_by_agent_ID is null
									AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
									and key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.key#">
							</cfquery>
						<cfelseif findAgentAnyVer.recordCount EQ 0>
							<cfset agentProblem2 = "no matches to any agent name">
							<cfquery name="warningVerifNoMatch" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
								UPDATE cf_temp_georef
								SET status = concat(nvl2(status, status || '; ', ''),'Verified_by not found because there were #agentProblem2#')
								WHERE verified_by is not null 
									AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
									and key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.key#">
							</cfquery>
						<cfelse>
							<cfset agentProblem2 = "matches to multiple agent names, use agent_id">
							<cfquery name="warningVerifNoMatch" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
								UPDATE cf_temp_georef
								SET status = concat(nvl2(status, status || '; ', ''),'Verified_by not found because there were #agentProblem2#')
								WHERE verified_by is not null 
									AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
									and key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.key#">
							</cfquery>
						</cfif>
					<cfelse>
						<cfset agentProblem2 = "matches to multiple preferred agent names, use agent_id">
						<cfquery name="warningVerifNoMatch" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							UPDATE cf_temp_georef
							SET status = concat(nvl2(status, status || '; ', ''),'Verified_by not found because there were #agentProblem2#')
							WHERE verified_by is not null 
								AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
								and key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.key#">
						</cfquery>
					</cfif>
				</cfif>
				<!--- Verification Agent --->
				<cfif verificationstatus eq "rejected by MCZ collection" OR verificationstatus eq "verified by MCZ collection" OR verificationstatus eq "verified by collector">
					<cfif len(verified_by) eq 0>
						<cfquery name="chkDAID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							UPDATE cf_temp_georef
							SET status = concat(nvl2(status, status || '; ', ''),'VERIFIED_BY not found--it is needed for VERIFICATIONSTATUS [#verificationstatus#]')
							WHERE verified_by is null
								AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
								and key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.key#">
						</cfquery>
					</cfif>
				<cfelseif verificationstatus eq "unknown" OR verificationstatus eq "unverified" >
					<cfif len(verified_by) gt 0>
						<cfquery name="warningExtraVerAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							UPDATE cf_temp_georef
							SET status = concat(nvl2(status, status || '; ', ''),'VERIFICATIONSTATUS [#verificationstatus#] should not have a VERIFIED_BY agent')
							WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
								AND key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.key#">
						</cfquery>
					</cfif>
				<cfelse>
					<cfif len(verified_by) gt 0>
						<cfquery name="warningExtraVerAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							UPDATE cf_temp_georef
							SET status = concat(nvl2(status, status || '; ', ''),'VERIFICATIONSTATUS entry is needed if there is a VERIFIED_BY Agent')
							WHERE
								verificationstatus is null
								AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
								AND key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.key#">
						</cfquery>	
					</cfif>
				</cfif>
				<!---End verificationstatus and verified_by agent code--->		
						

				<cfif len(locality_id) eq 0 AND len(getTempData.highergeography) gt 0 and len(getTempData.speclocality) gt 0>
					<!--- TODO: Only spec_locality is used to lookup locality id, not combination of higher_geog and locality_id --->
					<cfquery name="updateLocality_ID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						UPDATE cf_temp_georef
						SET locality_id = (
								select Locality_id 
								from LOCALITY
									join GEOG_AUTH_REC on geog_auth_rec.GEOG_AUTH_REC_ID = locality.geog_auth_rec_id 
								where spec_locality = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.SPECLOCALITY#">
								and higher_geog = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.HIGHERGEOGRAPHY#">
							)
						WHERE HIGHERGEOGRAPHY is not null 
							AND SPECLOCALITY is not null 
							AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
							AND key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.key#">
					</cfquery>
				</cfif>

				<!---SET DETERMINED_DATE to YYYY-MM-DD--->
				<cfif DatePart("yyyy",getTempData.DETERMINED_DATE) gte '1700'>
					<cfquery name="getDeterminedDate" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						UPDATE cf_temp_georef
						SET determined_date =  TO_DATE(<cfqueryparam cfsqltype="CF_SQL_DATE" value="#getTempData.DETERMINED_DATE#">, 'YYYY-MM-DD')
						WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
							AND key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.key#"> 
					</cfquery>
				<cfelse>
					<cfquery name="getDeterminedDate" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						UPDATE cf_temp_georef
						SET status = concat(nvl2(status, status || '; ', ''),'Year is invalid "#determined_date#"')
						WHERE determined_date is not null
							AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
							AND key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.key#"> 
					</cfquery>
				</cfif>
				<cfset dec_lat = "#getTempData.DEC_LAT#">
				<cfset dec_long = "#getTempData.DEC_LONG#">

				<!---You can get at the part of the coordinates after the decimal (dot_dec_lat,dot_dec_long) within the getDecimalParts function--->		
				<cfset minLength = #getTempData.coordinate_precision#>
				<cfset geoPrecision = #getDecimalParts(dec_lat,dec_long)#>
				<cfif len(#geoPrecision.dot_dec_lat#) lt #minLength#>
					<cfquery name="getDeterminedPrecision1" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						update cf_temp_georef
						SET status = concat(nvl2(status, status || '; ', ''),'DEC_LAT: #dec_lat# does not match precision #minLength#')
						WHERE coordinate_precision is not null
							AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
							AND key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.key#"> 
					</cfquery>
				</cfif>
				<cfif len(#geoPrecision.dot_dec_long#) lt #minLength#>
					<cfquery name="getDeterminedPrecision" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						update cf_temp_georef
						SET status = concat(nvl2(status, status || '; ', ''),'DEC_LONG: #dec_long# does not match precision #minLength#')
						WHERE coordinate_precision is not null
							AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
							AND key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.key#"> 
					</cfquery>
				</cfif>
				<!---Check to see if the CSV georef is a dup of one already in the locality record--->
				<cfquery name="warningLocalityID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE cf_temp_georef
					SET status = concat(nvl2(status, status || '; ', ''),'This georeference exists on the locality record. Remove row.')
					WHERE dec_lat in (select dec_lat from lat_long where dec_lat = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.dec_lat#">)
						and dec_long in (select dec_long from lat_long where dec_long = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.dec_long#">) 
						and georefmethod in (select georefmethod from lat_long where georefmethod = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.georefmethod#">)
						and max_error_distance in (select max_error_distance from lat_long where max_error_distance = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.max_error_distance#">)
						and datum in (select datum from lat_long where datum = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.datum#">)
						and max_error_units in (select MAX_ERROR_UNITS from lat_long where MAX_ERROR_UNITS = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.max_error_units#">)
						and NEAREST_NAMED_PLACE in (select NEAREST_NAMED_PLACE from lat_long where NEAREST_NAMED_PLACE = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.NEAREST_NAMED_PLACE#">)
						and locality_id = (select locality_id from lat_long where locality_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.locality_id#">)
						and username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						and key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.key#"> 
				</cfquery>
				<cfif getTempData.SPATIALFIT GT 1>
					<cfquery name="warningSpatialFit" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						UPDATE cf_temp_georef
						SET status = concat(nvl2(status, status || '; ', ''),'SPATIALFIT is not valid')
						WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
							AND key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.key#">
					</cfquery>
				</cfif>

				<cfif len(getTempData.GEOREFMETHOD) gt 0>
					<!---Check Georefmethod code table--->
					<cfquery name="warningGeorefMethod" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						UPDATE cf_temp_georef
						SET status = concat(nvl2(status, status || '; ', ''),'GEOREFMETHOD does not exist - See <a href="/vocabularies/ControlledVocabulary.cfm?table=CTGEOREFMETHOD">controlled vocabulary</a>')
						WHERE GEOREFMETHOD not in (select GEOREFMETHOD from CTGEOREFMETHOD)
							AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
							AND key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.key#">
					</cfquery>
				</cfif>
			</cfloop>

			<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT *
				FROM cf_temp_georef
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
					There is a problem with #problemsInData.c# of #data.recordcount# row(s). See the STATUS column. (<a href="/tools/BulkloadGeoref.cfm?action=dumpProblems" class="btn-link font-weight-lessbold">download</a>). Fix the problems in the data and <a href="/tools/BulkloadGeoref.cfm" class="text-danger">start again</a>.
				</h3>
			<cfelse>
				<h3 class="mt-3">
					<span class="text-success">Validation checks passed</span>. Look over the table below and <a href="/tools/BulkloadGeoref.cfm?action=load" class="btn-link font-weight-lessbold">click to continue</a> if it all looks good or <a href="/tools/BulkloadGeoref.cfm" class="text-danger">start again</a>.
				</h3>
			</cfif>
	
			<table class='sortable px-0 mx-0 table small table-responsive table-striped w-100'>
				<thead class="thead-light">
					<tr>
						<th>STATUS&nbsp;<span style='color:##e9ecef'>for&nbsp;Bulkloader</span></th>
						<th>HIGHERGEOGRAPHY</th>
						<th>SPECLOCALITY</th>
						<th>LOCALITY_ID</th>
						<th>DEC_LAT</th>
						<th>DEC_LONG</th>
						<th>DETERMINED_BY_AGENT</th>
						<th>GEOREFMETHOD</th>
						<th>ORIG_LAT_LONG_UNITS</th>
						<th>DATUM</th>
						<th>DETERMINED_DATE</th>
						<th>LAT_LONG_REF_SOURCE</th>
						<th>VERIFICATIONSTATUS</th>
						<th>COORDINATE_PRECISION</th>
						<th>MAX_ERROR_DISTANCE</th>
						<th>MAX_ERROR_UNITS</th>
						<th>LAT_LONG_REMARKS</th>
						<th>EXTENT</th>
						<th>GPSACCURACY</th>
						<th>SPATIALFIT</th>
						<th>NEAREST_NAMED_PLACE</th>
						<th>USERNAME</th>
						<th>VERIFIED_BY</th>
						<th>ACCEPTED_LAT_LONG_FG</th>
						<th>EXTENT_UNITS</th>
						<th>LAT_LONG_FOR_NNP_FG</th>
						<th>DETERMINED_BY_AGENT_ID</th>
						<th>VERIFIED_BY_AGENT_ID</th>
						<th>Lat Deg Min Sec</th>
						<th>Long Deg Min Sec</th>
					</tr>
				</thead>
				<tbody>
					<cfloop query="data">
						<tr>
							<td><cfif len(data.status) eq 0>Cleared to load<cfelse><strong>#data.status#</strong></cfif></td>
							<td>#data.HIGHERGEOGRAPHY#</td>
							<td>#data.SPECLOCALITY#</td>
							<td>#data.LOCALITY_ID# </td>
							<td>#data.DEC_LAT#</td>
							<td>#data.DEC_LONG#</td>
							<td>#data.DETERMINED_BY_AGENT#</td>
							<td>#data.GEOREFMETHOD#</td>
							<td>#data.ORIG_LAT_LONG_UNITS#</td>
							<td>#data.DATUM#</td>
							<td>#data.DETERMINED_DATE#</td>
							<td>#data.LAT_LONG_REF_SOURCE#</td>
							<td>#data.VERIFICATIONSTATUS#</td>
							<td>#data.COORDINATE_PRECISION#</td>
							<td>#data.MAX_ERROR_DISTANCE#</td>
							<td>#data.MAX_ERROR_UNITS#</td>
							<td>#data.LAT_LONG_REMARKS#</td>
							<td>#data.EXTENT#</td>
							<td>#data.GPSACCURACY#</td>
							<td>#data.SPATIALFIT#</td>
							<td>#data.NEAREST_NAMED_PLACE#</td>
							<td>#data.USERNAME#</td>
							<td>#data.VERIFIED_BY#</td>
							<td>1</td>
							<td>#data.EXTENT_UNITS#</td>
							<td>#data.LAT_LONG_FOR_NNP_FG#</td>
							<td>#data.DETERMINED_BY_AGENT_ID#</td>
							<td>#data.VERIFIED_BY_AGENT_ID#</td>
							<td>#data.LAT_DEG# #data.LAT_MIN# #data.LAT_SEC# #data.LAT_DIR# </td>
							<td>#data.LONG_DEG# #data.LONG_MIN# #data.LONG_SEC# #data.LONG_DIR# </td>
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
			<cftransaction>
				<cftry>
					<cfquery name="getData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						SELECT *
						FROM cf_temp_georef
						WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
					</cfquery>
					<cfif getData.recordcount EQ 0>
						<cfthrow message="You have no rows to load in the Georeference bulkloader table (cf_temp_georef). <a href='/tools/BulkloadGeoref.cfm'>Start over</a>">
					</cfif>
					<cfset georef_updates = 0>
					<cfloop query="getData">
						<cfset problem_key = getData.key>
						<!--- set any existing lat_long records to unnaccepted, allowing insert of new accepted ones --->
						<!--- TODO: TR_LATLONG_ACCEPTED_BIUPA will cause this to fail if any accepted lat_long records exist --->
						<cfquery name="updateAccpt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							UPDATE lat_long
							SET accepted_lat_long_fg = 0
							WHERE locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getData.locality_id#">
						</cfquery>
						<cfquery name="makeGeoref" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="insResult">
							INSERT INTO lat_long (
								lat_long_id,
								LOCALITY_ID,
								DEC_LAT,
								DEC_LONG,
								DATUM,
								COORDINATE_PRECISION,
								ORIG_LAT_LONG_UNITS,
								DETERMINED_BY_AGENT_ID,
								DETERMINED_DATE,
								LAT_LONG_REF_SOURCE,
								LAT_LONG_REMARKS,
								MAX_ERROR_DISTANCE,
								MAX_ERROR_UNITS,
								ACCEPTED_LAT_LONG_FG,
								EXTENT,
								GPSACCURACY,
								GEOREFMETHOD,
								VERIFICATIONSTATUS,
								VERIFIED_BY_AGENT_ID,
								SPATIALFIT,
								NEAREST_NAMED_PLACE,
								EXTENT_UNITS,
								LAT_LONG_FOR_NNP_FG,
								UTM_ZONE,
								UTM_EW,
								UTM_NS
							) VALUES (
								sq_lat_long_id.nextval,
								<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#LOCALITY_ID#">,
								<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#Dec_Lat#" scale="10">,
								<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#Dec_Long#" scale="10">,
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#DATUM#">,
								<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#COORDINATE_PRECISION#">,
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ORIG_LAT_LONG_UNITS#">,
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#DETERMINED_BY_AGENT_ID#">,
								<cfqueryparam cfsqltype="CF_SQL_DATE" value="#DETERMINED_DATE#">,
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#LAT_LONG_REF_SOURCE#">,
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#LAT_LONG_REMARKS#">,
								<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#MAX_ERROR_DISTANCE#">,
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#MAX_ERROR_UNITS#">,
								1,
								<cfif len(EXTENT) gt 0>
									<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#EXTENT#" scale="5">,
								<cfelse>
									NULL,
								</cfif>
								<cfif len(GPSACCURACY) gt 0>
									<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#GPSACCURACY#" scale="3">,
								<cfelse>
									NULL,
								</cfif>
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#GEOREFMETHOD#">,
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#VERIFICATIONSTATUS#">,
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#VERIFIED_BY_AGENT_ID#">,
								<cfif len(SPATIALFIT) gt 0>
									<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#SPATIALFIT#" scale="3">,
								<cfelse>
									NULL,
								</cfif>
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#NEAREST_NAMED_PLACE#">,
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#EXTENT_UNITS#" scale="5">,
								<cfif len(LAT_LONG_FOR_NNP_FG) gt 0>
									<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#LAT_LONG_FOR_NNP_FG#">,
								<cfelse>
									NULL,
								</cfif>
								<cfif len(LAT_DEG) gt 0>
									<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#LAT_DEG#">,
								<cfelse>
									NULL,
								</cfif>
								<cfif len(LAT_MIN) gt 0>
									<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#LAT_MIN#">,
								<cfelse>
									NULL,
								</cfif>
								<cfif len(LAT_SEC) gt 0>
									<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#LAT_SEC#" scale="5">,
								<cfelse>
									NULL,
								</cfif>
								<cfif len(LAT_DIR) gt 0>
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#LAT_DIR#">,
								<cfelse>
									NULL,
								</cfif>
								<cfif len(LONG_DEG) gt 0>
									<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#LONG_DEG#">,
								<cfelse>
									NULL,
								</cfif>
								<cfif len(LONG_MIN) gt 0>
									<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#LONG_MIN#">,
								<cfelse>
									NULL,
								</cfif>
								<cfif len(LONG_SEC) gt 0>
									<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#LONG_SEC#" scale="5">,
								<cfelse>
									NULL,
								</cfif>
								<cfif len(LONG_DIR) gt 0>
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#LONG_DIR#">,
								<cfelse>
									NULL,
								</cfif>
								<cfif len(UTM_ZONE) gt 0>
									<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#UTM_ZONE#">,
								<cfelse>
									NULL,
								</cfif>
								<cfif len(UTM_EW) gt 0>
									<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#UTM_EW#">,
								<cfelse>
									NULL,
								</cfif>
								<cfif len(UTM_NS) gt 0>
									<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#UTM_NS#">
								<cfelse>
									NULL
								</cfif>
							)
						</cfquery>
						<cfset georef_updates = georef_updates + insResult.recordcount>
					</cfloop>
					<p class="mt-2">Number of Georeferences added: <b>#georef_updates#</b> </p>
					<cfif #getData.recordcount# eq #georef_updates#>
						<h3 class="text-success">Success - loaded</h3>
					</cfif>
					<cfif #insResult.recordcount# gt #getData.recordcount#>
						<h3 class="text-danger">Not loaded - these have already been loaded</h3>
					</cfif>
					<cftransaction action="commit">
				<cfcatch>
					<cftransaction action="ROLLBACK">
					<h3>There was a problem adding coordinates to the locality records. </h3>
					<cfquery name="getProblemData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						SELECT *
						FROM cf_temp_georef
						WHERE 
							key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#problem_key#">
							AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
					</cfquery>
					<cfif getProblemData.recordcount GT 0>
						<h3>
							Fix the issues and <a href="/tools/BulkloadGeoref.cfm">start again</a>. Error loading row (<span class="text-danger">#georef_updates + 1#</span>) from the CSV: 
							<cfif len(cfcatch.detail) gt 0>
								<span class="font-weight-normal border-bottom border-danger">
									<cfif cfcatch.detail contains "locality_id">
										LOCALITY_ID is not valid
									<cfelseif cfcatch.detail contains "dec_lat">
										DEC_LAT is not valid
									<cfelseif cfcatch.detail contains "dec_long">
										DEC_LONG is not valid
									<cfelseif cfcatch.detail contains "datum">
										Problem with DATUM
									<cfelseif cfcatch.detail contains "orig_lat_long_units">
										Invalid ORIG_LAT_LONG_UNITS
									<cfelseif cfcatch.detail contains "determined_by_agent_id">
										Invalid DETERMINED_BY_AGENT_ID
									<cfelseif cfcatch.detail contains "determined_date">
										Invalid DETERMINED_DATE
									<cfelseif cfcatch.detail contains "lat_long_ref_source">
										Invalid LAT_LONG_REF_SOURCE
									<cfelseif cfcatch.detail contains "lat_long_remarks">
										Invalid LAT_LONG_REMARKS
									<cfelseif cfcatch.detail contains "max_error_distance">
										Invalid MAX_ERROR_DISTANCE
									<cfelseif cfcatch.detail contains "max_error_units">
										Invalid MAX_ERROR_UNITS
									<cfelseif cfcatch.detail contains "extent">
										Invalid EXTENT
									<cfelseif cfcatch.detail contains "extent_units">
										Invalid EXTENT_UNITS
									<cfelseif cfcatch.detail contains "gpsaccuracy">
										Invalid GPSACCURANCY
									<cfelseif cfcatch.detail contains "georefmethod">
										Invalid GEOREFMETHOD
									<cfelseif cfcatch.detail contains "verificationstatus">
										Invalid VERIFICATIONSTATUS
									<cfelseif cfcatch.detail contains "spatialfit">
										Invalid SPATIALFIT
									<cfelseif cfcatch.detail contains "nearest_named_place">
										Invalid NEAREST_NAMED_PLACE
									<cfelseif cfcatch.detail contains "lat_long_for_NNP_FG">
										Invalid lat_long_for_nnp_fg
									<cfelseif cfcatch.detail contains "COORDINATE_PRECISION">
										Invalid coordinate_precision
									<cfelseif cfcatch.detail contains "DETERMINED_BY_AGENT_ID">
										Invalid determined_by_agent_id
									<cfelseif cfcatch.detail contains "VERIFIED_BY_AGENT_ID">
										Invalid VERIFIED_BY_AGENT_ID
									<cfelseif cfcatch.detail contains "data">
										No data or the wrong data (#cfcatch.detail#)
									<cfelse>
										<!--- provide the raw error message if it isn't readily interpretable --->
										What happened? #cfcatch.detail#
									</cfif>
								</span>
							</cfif>
						</h3>
						<table class='mx-0 px-0 sortable table-danger table table-responsive table-striped mt-3'>
							<thead class="thead-light">
								<tr>
									<th>COUNT</th>
									<th>HIGHERGEOGRAPHY</th>
									<th>SPECLOCALITY</th>
									<th>LOCALITY_ID</th>
									<th>DEC_LAT</th>
									<th>DEC_LONG</th>
									<th>DETERMINED_BY_AGENT</th>
									<th>GEOREFMETHOD</th>
									<th>ORIG_LAT_LONG_UNITS</th>
									<th>DATUM</th>
									<th>DETERMINED_DATE</th>
									<th>LAT_LONG_REF_SOURCE</th>
									<th>VERIFICATIONSTATUS</th>
									<th>COORDINATE_PRECISION</th>
									<th>MAX_ERROR_DISTANCE</th>
									<th>MAX_ERROR_UNITS</th>
									<th>LAT_LONG_REMARKS</th>
									<th>EXTENT</th>
									<th>EXTENT_UNITS</th>
									<th>GPSACCURACY</th>
									<th>DETERMINED_BY_AGENT_ID</th>
									<th>SPATIALFIT</th>
									<th>NEAREST_NAMED_PLACE</th>
									<th>USERNAME</th>
									<th>VERIFIED_BY</th>
									<th>VERIFIED_BY_AGENT_ID</th>
									<th>ACCEPTED_LAT_LONG_FG</th>
									<th>LAT_LONG_FOR_NNP_FG</th>
									<th>Lat Deg Min Sec</th>
									<th>Long Deg Min Sec</th>
								</tr> 
							</thead>
							<tbody>
								<cfset i=1>
								<cfloop query="getProblemData">
									<tr>										
										<td>#i#</td>
										<td>#getProblemData.HIGHERGEOGRAPHY#</td>
										<td>#getProblemData.SPECLOCALITY#</td>
										<td>#getProblemData.LOCALITY_ID#</td>
										<td>#getProblemData.DEC_LAT#</td>
										<td>#getProblemData.DEC_LONG#</td>
										<td>#getProblemData.DETERMINED_BY_AGENT#</td>
										<td>#getProblemData.GEOREFMETHOD#</td>
										<td>#getProblemData.ORIG_LAT_LONG_UNITS#</td>
										<td>#getProblemData.DATUM#</td>
										<td>#getProblemData.DETERMINED_DATE#</td>
										<td>#getProblemData.LAT_LONG_REF_SOURCE#</td>
										<td>#getProblemData.VERIFICATIONSTATUS#</td>
										<td>#getProblemData.COORDINATE_PRECISION#</td>
										<td>#getProblemData.MAX_ERROR_DISTANCE#</td>
										<td>#getProblemData.MAX_ERROR_UNITS#</td>
										<td>#getProblemData.LAT_LONG_REMARKS#</td>
										<td>#getProblemData.EXTENT#</td>
										<td>#getProblemData.EXTENT_UNITS#</td>
										<td>#getProblemData.GPSACCURACY#</td>
										<td>#getProblemData.DETERMINED_BY_AGENT_ID#</td>
										<td>#getProblemData.SPATIALFIT#</td>
										<td>#getProblemData.NEAREST_NAMED_PLACE#</td>
										<td>#getProblemData.USERNAME#</td>
										<td>#getProblemData.VERIFIED_BY#</td>
										<td>#getProblemData.VERIFIED_BY_AGENT_ID#</td>
										<td>1</td>
										<td>#getProblemData.LAT_LONG_FOR_NNP_FG#</td>
										<td>#getProblemData.LAT_DEG# #getProblemData.LAT_MIN# #getProblemData.LAT_SEC# #getProblemData.LAT_DIR# </td>
										<td>#getProblemData.LONG_DEG# #getProblemData.LONG_MIN# #getProblemData.LONG_SEC# #getProblemData.LONG_DIR# </td>
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
				DELETE FROM cf_temp_georef 
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
		</cfoutput>
	</cfif>
</main>

<cfinclude template="/shared/_footer.cfm">
