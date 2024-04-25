<!--- tools/bulkloadAttributes.cfm add attributes to specimens in bulk.

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
		SELECT institution_acronym,collection_cde,other_id_type,other_id_number,attribute,attribute_value,attribute_units,attribute_date,attribute_meth,determiner,remarks,status
		FROM cf_temp_attributes 
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
<cfset fieldlist = "OTHER_ID_TYPE,OTHER_ID_NUMBER,ATTRIBUTE,ATTRIBUTE_VALUE,ATTRIBUTE_UNITS,ATTRIBUTE_DATE,ATTRIBUTE_METH,DETERMINER,REMARKS,COLLECTION_CDE,INSTITUTION_ACRONYM">

<cfquery name="getDataDetails" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	SELECT tab.COLUMN_NAME, col.COMMENTS, tab.COLUMN_ID
		from sys.all_col_comments col
		left join sys.all_tab_columns tab on col.COLUMN_NAME=tab.COLUMN_NAME 
		where col.TABLE_NAME = 'CF_TEMP_ATTRIBUTES'
		and col.table_name = tab.table_name
		and tab.column_id = #getDataDetails.COLUMN_ID#
</cfquery>
<cfset fieldSet = ''>
<cfset dataType = ''>
<cfset requiredFields = ''>
<cfset requiredDataTypes = ''>
<cfloop query = 'getDataDetails'>
	<CFOUTPUT>
		<cfif getDataDetails.comments contains '%Required%'>
			<cfquery name="getDataRequired" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			SELECT tab.COLUMN_NAME, col.COMMENTS
			from sys.all_col_comments col
			left join sys.all_tab_columns tab on col.COLUMN_NAME=tab.COLUMN_NAME 
			where col.TABLE_NAME = 'CF_TEMP_ATTRIBUTES'
			AND col.COMMENTS like '%Required%'
			and col.table_name = tab.table_name
			and tab.column_id = #getDataDetails.COLUMN_ID#
			</cfquery>
			<cfset requiredFields = '#getDataRequired.COLUMN_NAME#'>
			<cfset requiredDataTypes = '#getDataRequired.DATA_TYPE#'>
		<cfelse>
			<cfset fieldSet = '#getDataDetails.COLUMN_NAME#'>
			<cfset dataType = '#getDataDetails.DATA_TYPE#'>
		</cfif>
	</CFOUTPUT>
</cfloop>
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
<cfset pageTitle = "Bulkload Attributes">
<cfinclude template="/shared/_header.cfm">
<cfif not isDefined("action") OR len(action) EQ 0><cfset action="nothing"></cfif>
<main class="container-fluid px-5 py-3" id="content">
	<h1 class="h2 mt-2">Bulkload Attributes</h1>
	<cfif #action# is "nothing">
		<cfoutput>
			<p>This tool adds attributes to the specimen record. The attribute has to be in the code table prior to uploading this .csv. It ignores rows that are exactly the same. Additional columns will be ignored. The attributes and attribute values must appear as they do on the <a href="https://mczbase.mcz.harvard.edu/vocabularies/ControlledVocabulary.cfm?" class="font-weight-bold">controlled vocabularies</a> lists for <a href="/vocabularies/ControlledVocabulary.cfm?table=CTATTRIBUTE_TYPE">ATTRIBUTE_TYPE</a> and for some attributes the controlled vocabularies are listed in <a href="/vocabularies/ControlledVocabulary.cfm?table=CTATTRIBUTE_CODE_TABLES">ATTRIBUTE_CODE_TABLES</a>. Upload a comma-delimited text file (csv). Include column headings, spelled exactly as below. Use "catalog number" as the value of other_id_type to match on catalog number.</p>
			<span class="btn btn-xs btn-info" onclick="document.getElementById('template').style.display='block';">View template</span>
			<div id="template" style="margin: 1rem 0;display:none;">
				<label for="templatearea" class="data-entry-label mb-1">
					Copy this header line and save it as a .csv file (<a href="/tools/BulkloadAttributes.cfm?action=getCSVHeader">download</a>)
				</label>
				<textarea rows="2" cols="90" id="templatearea" class="w-100 data-entry-textarea">#fieldlist#</textarea>
			</div>
			<h2 class="mt-4 h4">Columns in <span class="text-danger">red</span> are required; others are optional:</h2>
			<ul class="mb-4 h4">
				<cfloop list="#fieldlist#" index="field" delimiters=",">
					<cfset aria = "">
					<cfif listContains(requiredFields,field,",")>
						<cfset class="text-danger">
						<cfset aria = "aria-label='Required Field'">
					<cfelse>
						<cfset class="text-dark">
					</cfif>
					<li class="#class#" #aria#>#field#</li>
				</cfloop>
			</ul>
			<form name="atts" method="post" enctype="multipart/form-data" action="/tools/BulkloadAttributes.cfm">
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
		<cfoutput>
		<h2 class="h4">First step: Reading data from CSV file.</h2>
		<!--- Compare the numbers of headers expected against provided in CSV file --->
		<!--- Set some constants to identify error cases in cfcatch block --->
		<cfset NO_COLUMN_ERR = "<p>One or more required fields are missing in the header line of the csv file. <br>Missing fields: </p>">
		<cfset DUP_COLUMN_ERR = "<p>One or more columns are duplicated in the header line of the csv file.<p>">
		<cfset COLUMN_ERR = "<p>Error inserting data.</p>">
		<cfset NO_HEADER_ERR = "<p>No header line found, csv file appears to be empty.</p>">

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
					DELETE FROM cf_temp_attributes 
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
					<cfset bit = headers.get(JavaCast("int",i))>
					<cfif i EQ 0 and characterSet EQ 'utf-8'>
						<!--- strip off windows non-standard UTF-8-BOM byte order mark if present (raw hex EF, BB, BF or U+FEFF --->
						<cfset bit = "#Replace(bit,CHR(65279),'')#" >
					</cfif>
					<!--- we could strip out all unexpected characters from the header, but seems likely to cause problems. --->
					<!--- cfset bit=REReplace(headers.get(JavaCast("int",i)),'[^A-Za-z0-9_-]','','All') --->
					<cfset foundHeaders = "#foundHeaders##separator##bit#" >
					<cfset separator = ",">
				</cfloop>
				<!--- Note: As we can't use csvFormat.withHeader(), we can not match columns by name, we are forced to do so by number, thus arrays --->
				<cfset colNameArray = listToArray(ucase(foundHeaders))><!--- the list of columns/fields found in the input file --->
				<cfset fieldArray = listToArray(ucase(fieldlist))><!--- the full list of fields --->
				<cfset typeArray = listToArray(ucase(dataType))><!--- the types for the full list of fields --->
				<div class="col-12 my-4">
					<h3 class="h4">Found #size# columns in header of csv file.</h3>
					<h3 class="h4">There are #ListLen(fieldList)# columns expected in the header (of these #ListLen(requiredFields)# are required).</h3>
				</div>

				<!--- check for required fields in header line (performng check in two different ways, Case 1, Case 2) --->
				<!--- Loop through list of fields throw exception if required fields are missing --->
				<cfset errorMessage = "">
				<cfloop list="#fieldList#" item="aField">
					<cfif ListContainsNoCase(requiredFields,aField)>
						<!--- Case 1. Check by splitting assembled list of foundHeaders --->
						<cfif NOT ListContainsNoCase(foundHeaders,aField)>
							<cfset errorMessage = "#errorMessage# <i class='fas fa-arrow-right'></i><strong> &nbsp;#aField#<br></strong>">
						</cfif>
					</cfif>
				</cfloop>
				<cfif len(errorMessage) GT 0>
					<cfthrow message = "#NO_COLUMN_ERR# <h4 class='px-4'> #errorMessage#</h4>">
				</cfif>
				<cfset errorMessage = "">
				<!--- Loop through list of fields, mark each field as fields present in input or not, throw exception if required fields are missing --->
				<ul class="h4 mb-4 font-weight-normal">
					<cfloop list="#fieldlist#" index="field" delimiters=",">
						<cfset hint="">
						<cfif listContains(requiredFields,field,",")>
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
								<cfif ListContainsNoCase(requiredFields,field)>
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
							insert into cf_temp_attributes
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
						you probably want to <strong><a href="/tools/BulkloadAttributes.cfm">reload</a></strong> this file selecting a different encoding.  If these appear as expected, then 
							you selected the correct encoding and can continue to validate or load.</p>
					</div>
					<ul class="pb-1 h4 list-unstyled">
						#foundHighAscii# #foundMultiByte#
					</ul>
				</cfif>
				<h3 class="h3">
					<cfif loadedRows EQ 0>
						Loaded no rows from the CSV file.  The file appears to be just a header with no data. Fix file and <a href="/tools/BulkloadAttributes.cfm">reload</a>
					<cfelse>
						Successfully read #loadedRows# records from the CSV file.  Next <a href="/tools/BulkloadAttributes.cfm?action=validate">click to validate</a>.
					</cfif>
				</h3>
			<cfcatch>
				<h3 class="h4">
					Failed to read the CSV file.  Fix the errors in the file and <a href="/tools/BulkloadAttributes.cfm">reload</a>
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
	<cfif #action# is "validate">
		<h2 class="h4 mb-3">Second step: Data Validation</h2>
		<cfoutput>
			<cfquery name="getTempTableTypes" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT 
					other_id_type, key
				FROM 
					cf_temp_attributes
				WHERE 
					username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfset i= 1>
			<cfloop query="getTempTableTypes">
				<!--- For each row, set the target collection_object_id --->
				<cfif getTempTableTypes.other_id_type eq 'catalog number'>
					<!--- either based on catalog_number --->
					<cfquery name="getCID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						UPDATE
							cf_temp_attributes
						SET
							collection_object_id = (
								select collection_object_id 
								from cataloged_item 
								where cat_num = cf_temp_attributes.other_id_number and collection_cde = cf_temp_attributes.collection_cde
							),
							status = null
						WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
							and key = <cfqueryparam cfsqltype="CF_SQL_decimal" value="#getTempTableTypes.key#"> 
					</cfquery>
				<cfelse>
					<!--- or on specified other identifier --->
					<cfquery name="getCID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						UPDATE
							cf_temp_attributes
						SET
							collection_object_id= (
								select cataloged_item.collection_object_id from cataloged_item,coll_obj_other_id_num 
								where coll_obj_other_id_num.other_id_type = cf_temp_attributes.other_id_type 
								and cataloged_item.collection_cde = cf_temp_attributes.collection_cde 
								and display_value= cf_temp_attributes.other_id_number
								and cataloged_item.collection_object_id = coll_obj_other_id_num.COLLECTION_OBJECT_ID
							),
							status = null
						WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
							and key = <cfqueryparam cfsqltype="CF_SQL_decimal" value="#getTempTableTypes.key#"> 
					</cfquery>
				</cfif>
			</cfloop>
			<!--- obtain the information needed to QC each row --->
			<cfquery name="getTempTableQC" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT 
					attribute_date, key, collection_cde, attribute
				FROM 
					cf_temp_attributes
				WHERE 
					username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfloop query="getTempTableQC">
				<!--- For each row, evaluate the date against expectations and provide an error message --->
				<!---DATE ERROR MESSAGE--->
				<cfset attDate = isDate(getTempTableQC.attribute_date)>
				<cfif #attdate# eq 'NO'>
					<cfquery name="flagDateProblem" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						UPDATE
							cf_temp_attributes
						SET 
							status = concat(nvl2(status, status || '; ', ''),'invalid attribute_date')
						WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#"> 
							and key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableQC.key#"> 
					</cfquery>	
				</cfif>
				<!--- for each row, evaluate the attribute against expectations and provide an error message --->
				<cfquery name="flatAttributeProblems" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="flatAttributeProblems_result">
					UPDATE cf_temp_attributes
					SET
						status = concat(nvl2(status, status || '; ', ''),'invalid attribute for collection_cde ' || collection_cde)
					WHERE 
						attribute IS NOT NULL
						AND attribute NOT IN (
							SELECT attribute_type 
							FROM ctattribute_type 
							WHERE collection_cde = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempTableQC.collection_cde#">
						)
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						AND key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableQC.key#">
				</cfquery>
				<cfquery name="ctAttribute_code_tables" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					select upper(value_code_table) as value_code_table, upper(units_code_table) as units_code_table
					FROM ctattribute_code_tables
					WHERE attribute_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempTableQC.attribute#">
				</cfquery>
				<cfloop query="ctAttribute_code_tables">
					<!--- assumption, if an attribute has an entry in attribute_code_tables and the units_code_table there is blank, then 
							the attribute does not take units --->
					<!--- however, an entry in ctattribute_type without an entry in ctattribute_code_tables make take units. --->
					<cfif len(ctAttribute_code_tables.units_code_table) EQ 0>
						<cfquery name="flagNotNullUnits" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							UPDATE cf_temp_attributes
							SET 
								status = concat(nvl2(status, status || '; ', ''),'attribute inconsistent with units')
							WHERE 
								attribute_units is not null
								AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
								AND key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableQC.key#">
						</cfquery>
					<cfelse>
						<cfquery name="flagNullUnits" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							UPDATE cf_temp_attributes
							SET 
								status = concat(nvl2(status, status || '; ', ''),'attribute requires units from controlled vocabulary')
							WHERE 
								attribute_units is null
								AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
								AND key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableQC.key#">
						</cfquery>
						<cftry>
						<cfquery name="flatWrongUnits" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							UPDATE cf_temp_attributes
							SET 
								status = concat(nvl2(status, status || '; ', ''),'attribute_units not in controlled vocabulary #ctAttribute_code_tables.units_code_table#')
							WHERE 
								attribute_units not in (
									<cfif ctAttribute_code_tables.units_code_table EQ "CTLENGTH_UNITS">
										select LENGTH_UNITS from CTLENGTH_UNITS
									<cfelseif ctAttribute_code_tables.units_code_table EQ "CTWEIGHT_UNITS">
										select WEIGHT_UNITS from CTWEIGHT_UNITS
									<cfelseif ctAttribute_code_tables.units_code_table EQ "CTNUMERIC_AGE_UNITS">
										select NUMERIC_AGE_UNITS from CTNUMERIC_AGE_UNITS
									<cfelseif ctAttribute_code_tables.units_code_table EQ "CTAREA_UNITS">
										select AREA_UNITS from CTAREA_UNITS
									<cfelseif ctAttribute_code_tables.units_code_table EQ "CTTHICKNESS_UNITS">
										select THICKNESS_UNITS from CTTHICKNESS_UNITS
									<cfelseif ctAttribute_code_tables.units_code_table EQ "CTANGLE_UNITS">
										<!--- yes the field name is inconsistent with the table --->
										select LENGTH_UNITS from CTANGLE_UNITS
									<cfelseif ctAttribute_code_tables.units_code_table EQ "CTTISSUE_VOLUME_UNITS">
										select TISSUE_VOLUME_UNITS from CTTISSUE_VOLUME_UNITS
									</cfif>
								)
								AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
								AND key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableQC.key#">
						</cfquery>
						<cfcatch>
						</cfcatch>
							<!--- silently fail if another units table is added to the database but isn't added here. --->
						</cftry>
					</cfif>
					<cfif len(ctAttribute_code_tables.value_code_table) GT 0>
						<cftry>
						<cfquery name="flatWrongUnits" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							UPDATE cf_temp_attributes
							SET 
								status = concat(nvl2(status, status || '; ', ''),'attribute_value not in controlled vocabulary #ctAttribute_code_tables.value_code_table#')
							WHERE 
								attribute_value not in (
									<cfif ctAttribute_code_tables.value_code_table EQ "CTSEX_CDE">
										select SEX_CDE from CTSEX_CDE
										where collection_cde = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempTableQC.collection_cde#">
									<cfelseif ctAttribute_code_tables.value_code_table EQ "CTAGE_CLASS">
										select AGE_CLASS from CTAGE_CLASS
										where collection_cde = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempTableQC.collection_cde#">
									<cfelseif ctAttribute_code_tables.value_code_table EQ "CTASSOCIATED_GRANTS">
										select ASSOCIATED_GRANT from CTASSOCIATED_GRANTS
									<cfelseif ctAttribute_code_tables.value_code_table EQ "CTCOLLECTION_FULL_NAMES">
										select COLLECTION from CTCOLLECTION_FULL_NAMES
									</cfif>
								)
								AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
								AND key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableQC.key#">
						</cfquery>
						<cfcatch>
						</cfcatch>
							<!--- silently fail if another value code table is added to the database but isn't added here. --->
						</cftry>
					</cfif>
				</cfloop>
			</cfloop>
			<!--- qc checks independent of attributes, includes presence of values in required columns --->
			<cfloop list="#requiredFields#" index="requiredField">
				<cfquery name="checkRequired" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE cf_temp_attributes
					SET 
						status = concat(nvl2(status, status || '; ', ''),'#requiredField# is missing')
					WHERE #requiredField# is null
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
			</cfloop>
			<!---INSTITUTION_ACRONYM--->			
			<cfquery name="m1b" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE cf_temp_attributes
				SET 
					status = concat(nvl2(status, status || '; ', ''),'INSTIUTION_ACRONYM is not "MCZ" (check case)')
				WHERE institution_acronym <> 'MCZ'
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<!---COLLECTION_CDE--->	
			<!--- concat before other messages, as it is cause for unknown attribute for collection etc --->
			<cfquery name="flagUnknownCollectionCde" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE cf_temp_attributes
				SET 
					status = concat('Invalid collection_cde: ' || collection_cde, nvl2(status, '; ' || status, ''))
				WHERE collection_cde not in (select collection_cde from collection) 
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<!--- found a collection object --->
			<cfquery name="flagNoCollectionObject" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE cf_temp_attributes
				SET 
					status = concat(nvl2(status, status || '; ', ''),' no match to a cataloged item on [' || other_id_type || ']=[' || other_id_number || '] in collection ' || collection_cde)
				WHERE collection_object_id IS NULL
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>

			<!--- Determiner Agent --->
			<cfquery name="setAgentIDForDetermier" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE cf_temp_attributes
				SET determined_by_agent_id= (select agent_id from preferred_agent_name where agent_name = cf_temp_attributes.determiner)
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="flagEmptyAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE cf_temp_attributes
				SET 
					status = concat(nvl2(status, status || '; ', ''), 'agent value (preferred name) is missing in DETERMINER column')
				WHERE determiner is null
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="flagNotMatchedAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE cf_temp_attributes
				SET 
					status = concat(nvl2(status, status || '; ', ''), 'unknown agent (no match to preferred name) in DETERMINER column')
				WHERE determiner IS NOT NULL
					AND determined_by_agent_id IS NULL
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>

			<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT institution_acronym,collection_cde,other_id_type,other_id_number,attribute,attribute_value,attribute_units,attribute_date, attribute_meth,determiner,remarks,status
				FROM cf_temp_attributes
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				ORDER BY key
			</cfquery>
			
			<cfquery name="pf" dbtype="query">
				SELECT count(*) c 
				FROM data 
				WHERE status is not null
			</cfquery>
			<cfif pf.c gt 0>
				<h3>
					There is a problem with #pf.c# of #data.recordcount# row(s). See the STATUS column. (<a href="/tools/BulkloadAttributes.cfm?action=dumpProblems">download</a>).
				</h3>
				<h3>
					Fix the problem(s) noted in the status column and <a href="/tools/BulkloadAttributes.cfm">start again</a>.
				</h3>
			<cfelse>
				<h3>
					Validation checks passed. Look over the table below and <a href="/tools/BulkloadAttributes.cfm?action=load">click to continue</a> if it all looks good.
				</h3>
			</cfif>
			<table class='px-0 sortable table table-responsive table-striped d-xl-table w-100'>
				<thead>
					<tr>
						<th>Row</th>
						<th>STATUS</th>
						<th>INSTITUTION_ACRONYM</th>
						<th>COLLECTION_CDE</th>
						<th>OTHER_ID_TYPE</th>
						<th>OTHER_ID_NUMBER</th>
						<th>ATTRIBUTE</th>
						<th>ATTRIBUTE_VALUE</th>
						<th>ATTRIBUTE_UNITS</th>
						<th>ATTRIBUTE_DATE</th>
						<th>ATTRIBUTE_METH</th>
						<th>DETERMINER</th>
						<th>REMARKS</th>
					</tr>
				<tbody>
					<cfset i=1>
					<cfloop query="data">
						<tr>
							<td>#i#</td>
							<td><strong>#STATUS#</strong></td>
							<td>#data.INSTITUTION_ACRONYM#</td>
							<td>#data.COLLECTION_CDE#</td>
							<td>#data.OTHER_ID_TYPE#</td>
							<td>#data.OTHER_ID_NUMBER#</td>
							<td>#data.ATTRIBUTE#</td>
							<td>#data.ATTRIBUTE_VALUE#</td>
							<td>#data.ATTRIBUTE_UNITS#</td>
							<td>#data.ATTRIBUTE_DATE#</td>
							<td>#data.ATTRIBUTE_METH#</td>
							<td>#data.DETERMINER#</td>
							<td>#data.REMARKS#</td>
						</tr>
						<cfset i=i+1>
					</cfloop>
				</tbody>
			</table>
		</cfoutput>
	</cfif>
	<!-------------------------------------------------------------------------------------------->
	<cfif action is "load">
		<h2 class="h4">Third step: Apply changes.</h2>
		<cfoutput>
			<cfset problem_key = "">
			<cftransaction>
				<cfquery name="getTempData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT * FROM cf_temp_attributes
					WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cfquery name="getCounts" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT count(distinct collection_object_id) ctobj FROM cf_temp_attributes
					WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
			<cftry>
					<cfset attributes_updates = 0>
					<cfset attributes_updates1 = 0>
					<cfif getTempData.recordcount EQ 0>
						<cfthrow message="You have no rows to load in the attributes bulkloader table (cf_temp_attributes).  <a href='/tools/BulkloadAttributes.cfm'>Start over</a>"><!--- " --->
					</cfif>
					<cfloop query="getTempData">
						<cfset problem_key = getTempData.key>
						<cfquery name="updateAttributes" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="updateAttributes_result">
							INSERT into attributes (
							COLLECTION_OBJECT_ID,
							ATTRIBUTE_TYPE,
							ATTRIBUTE_VALUE,
							ATTRIBUTE_UNITS,
							DETERMINED_DATE,
							DETERMINATION_METHOD,
							DETERMINED_BY_AGENT_ID,
							ATTRIBUTE_REMARK
							)VALUES(
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#collection_object_id#">,
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#attribute#">,
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#attribute_value#">,
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#attribute_units#">, 
							<cfqueryparam cfsqltype="CF_SQL_DATE" value="#attribute_date#">,
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#attribute_meth#">,
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#determined_by_agent_id#">,
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#remarks#">
							)
						</cfquery>
						<cfquery name="updateAttributes1" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="updateAttributes1_result">
							select attribute_type,attribute_value,collection_object_id from attributes 
							where collection_object_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.collection_object_id#">
							group by attribute_type,attribute_value,collection_object_id
							having count(*) > 1
						</cfquery>
						<cfset attributes_updates = attributes_updates + updateAttributes_result.recordcount>
						<cfif updateAttributes1_result.recordcount gt 0>
							<cftransaction action = "ROLLBACK">
						<cfelse>
							<cftransaction action="COMMIT">
						</cfif>
					</cfloop>
					<p>Number of attributes to update: #attributes_updates# (on #getCounts.ctobj# cataloged items)</p>
					<cfif getTempData.recordcount eq attributes_updates and updateAttributes1_result.recordcount eq 0>
						<h2 class="text-success">Success - loaded</h2>
					</cfif>
					<cfif updateAttributes1_result.recordcount gt 0>
						<h2 class="text-danger">Not loaded - these have already been loaded</h2>
					</cfif>
				<cfcatch>
					<cftransaction action="ROLLBACK">
					<h2 class="h3">There was a problem updating the attributes.</h2>
					<cfquery name="getProblemData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						SELECT status,institution_acronym,collection_cde,other_id_type,other_id_number,attribute,attribute_value, attribute_units,attribute_date,attribute_meth,determiner,remarks
						FROM cf_temp_attributes 
						WHERE key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#problem_key#">
					</cfquery>
					<cfquery name="getCollectionCodes" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						SELECT collection_cde
						FROM collection
					</cfquery>
					<cfset collection_codes = "">
					<cfloop query="getCollectionCodes">
						<cfset collection_codes = ListAppend(collection_codes,getCollectionCodes.collection_cde)>
					</cfloop>
					<cfquery name="getInstitution" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						SELECT distinct institution_acronym
						FROM collection
					</cfquery>
					<cfset institutions = "">
					<cfloop query="getInstitution">
						<cfset institutions = ListAppend(institutions,getInstitution.institution_acronym)>
					</cfloop>
					<cfif getProblemData.recordcount GT 0>
 						<h2 class="h3">Errors are displayed one row at a time.</h2>
						<h3>
							Error loading row (<span class="text-danger">#attributes_updates + 1#</span>) from the CSV: 
							<cfif len(cfcatch.detail) gt 0>
								<span class="font-weight-normal border-bottom border-danger">
									<cfif cfcatch.detail contains "Invalid ATTRIBUTE_TYPE">
										Invalid ATTRIBUTE_TYPE for this collection; check controlled vocabulary (Help menu)
									<cfelseif cfcatch.detail contains "collection_cde">
										COLLECTION_CDE does not match abbreviated collection (#collection_codes#)
									<cfelseif cfcatch.detail contains "institution_acronym">
										INSTITUTION_ACRONYM does not match #institutions# (all caps)
									<cfelseif cfcatch.detail contains "other_id_type">
										OTHER_ID_TYPE is not valid
									<cfelseif cfcatch.detail contains "DETERMINED_BY_AGENT_ID">
										DETERMINER does not match preferred agent name
									<cfelseif cfcatch.detail contains "date">
										Problem with ATTRIBUTE_DATE, Check Date Format in CSV. (#cfcatch.detail#)
									<cfelseif cfcatch.detail contains "attribute_units">
										Invalid or missing ATTRIBUTE_UNITS
									<cfelseif cfcatch.detail contains "attribute_value">
										Invalid with ATTRIBUTE_VALUE for ATTRIBUTE_TYPE
									<cfelseif cfcatch.detail contains "attribute_meth">
										Problem with ATTRIBUTE_METH (#cfcatch.detail#)
									<cfelseif cfcatch.detail contains "OTHER_ID_NUMBER">
										Problem with OTHER_ID_NUMBER (#cfcatch.detail#)
									<cfelseif cfcatch.detail contains "attribute_remarks">
										Problem with ATTRIBUTE_REMARKS (#cfcatch.detail#)
									<cfelseif cfcatch.detail contains "no data">
										No data or the wrong data (#cfcatch.detail#)
									<cfelse>
										<!--- provide the raw error message if it isn't readily interpretable --->
										#cfcatch.detail#
									</cfif>
								</span>
							</cfif>
						</h3>
						<table class='px-0 sortable table-danger table table-responsive table-striped d-lg-table mt-3'>
							<thead>
								<tr><th>COUNT</th><th>STATUS</th>
									<th>INSTITUTION_ACRONYM</th><th>COLLECTION_CDE</th><th>OTHER_ID_TYPE</th><th>OTHER_ID_NUMBER</th><th>ATTRIBUTE</th><th>ATTRIBUTE_VALUE</th><th>ATTRIBUTE_UNITS</th><th>ATTRIBUTE_DATE</th><th>ATTRIBUTE_METH</th><th>DETERMINER</th><th>REMARKS</th>
								</tr> 
							</thead>
							<tbody>
								<cfset i=1>
								<cfloop query="getProblemData">
									<tr>
										<td>#i#</td>
										<td>#getProblemData.status# </td>
										<td>#getProblemData.institution_acronym# </td>
										<td>#getProblemData.collection_cde# </td>
										<td>#getProblemData.other_id_type#</td>
										<td>#getProblemData.other_id_number#</td>
										<td>#getProblemData.attribute# </td>
										<td>#getProblemData.attribute_value# </td>
										<td>#getProblemData.attribute_units# </td>
										<td>#getProblemData.attribute_date#</td>
										<td>#getProblemData.attribute_meth# </td>
										<td>#getProblemData.determiner# </td>
										<td>#getProblemData.remarks# </td>
									</tr>
									<cfset i= i+1>
								</cfloop>
							</tbody>
						</table>
					</cfif>
					<div>#cfcatch.message#</div>
				</cfcatch>
				</cftry>
			</cftransaction>
			
			<cfquery name="clearTempTable" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="clearTempTable_result">
				DELETE FROM cf_temp_attributes 
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
		</cfoutput>
	</cfif>
</main>
<cfinclude template="/shared/_footer.cfm">
