<!--- special case handling to dump problem data as csv --->
<cfif isDefined("action") AND action is "dumpProblems">
	<cfquery name="getProblemData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		SELECT status,institution_acronym,collection_cde,existing_other_id_type,existing_other_id_number,new_other_id_type,new_other_id_number
		FROM cf_temp_OIDS 
		WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
	</cfquery>
	<cfinclude template="/shared/component/functions.cfc">
	<cfset csv = queryToCSV(getProblemData)>
	<cfheader name="Content-Type" value="text/csv">
	<cfoutput>#csv#</cfoutput>
	<cfabort>
</cfif>
<!--- end special case dump of problems --->
<cfset fieldlist = "institution_acronym,collection_cde,existing_other_id_type,existing_other_id_number,new_other_id_type,new_other_id_number">
<cfset fieldTypes ="CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR">
<cfset requiredfieldlist = "institution_acronym,collection_cde,existing_other_id_type,existing_other_id_number,new_other_id_type,new_other_id_number">

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
<cfset pageTitle = "Bulkload Other IDs">
<cfinclude template="/shared/_header.cfm">
<cfif not isDefined("action") OR len(action) EQ 0><cfset action="nothing"></cfif>
<main class="container py-3" id="content">
	<h1 class="h2 mt-2">Bulkload Other IDs</h1>
	<cfif #action# is "nothing">
		<cfoutput>
			<p>This tool is used to bulkload Other IDs. Click view template download a comma-delimited text file (csv) to enter and upload data. OR, create a csv by including column headings spelled exactly as listed below.  Additional colums will be ignored. Pay attention to capitalization where it is required. Messages will help to navigate problems with the data in the uploaded .csv file. </p>
			
			<span class="btn btn-xs btn-info" onclick="document.getElementById('template').style.display='block';">View template</span>
			<div id="template" style="margin: 1rem 0;display:none;">
				<label for="templatearea" class="data-entry-label mb-1">
					Copy this header line and save it as a .csv file (<a href="/tools/BulkloadOtherId.cfm?action=getCSVHeader">download</a>)
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
					<li class="#class#" #aria#>#field#</li>
				</cfloop>
			</ul>
			<p>Check the Help > Controlled Vocabulary page and select the <a href="/vocabularies/ControlledVocabulary.cfm?table=CTCOLL_OTHER_ID_TYPE">CTCOLL_OTHER_ID_TYPE</a> list for types ("catalog number" can also be used). Values can be combinations of letters, special characters, and numbers or just numbers. Submit a bug report to request an additional type when needed.</p>
			<form name="atts" method="post" enctype="multipart/form-data" action="/tools/BulkloadOtherId.cfm">
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
	<!------------------------------------------------------->
	<cfif #action# is "getFile">
		<cfoutput>
		<h2 class="h3">First step: Reading data from CSV file.</h2>
		<!--- Compare the numbers of headers expected against provided in CSV file --->
		<!--- Set some constants to identify error cases in cfcatch block --->
		<cfset NO_COLUMN_ERR = 'One or more required fields are missing in the header line of the csv file. [If you uploaded csv columns that match the required headers and see at least one "Required column not found," check the charset you selected.]'>
		<cfset DUP_COLUMN_ERR = "<h4 class='mt-2 mb-3'>One or more columns are duplicated in the header line of the csv file. </h4>">
		<cfset COLUMN_ERR = "Error inserting data ">
		<cfset NO_HEADER_ERR = "<h4 class='mt-4 mb-3'>No header line found, csv file appears to be empty.</h4>">

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
				<cfquery name="clearTempTable" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="clearTempTable_result">
					DELETE FROM cf_temp_oids 
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
							<cfset errorMessage = "#errorMessage# <i class='fas fa-arrow-right text-dark'></i><strong class='text-dark'> &nbsp;#aField#<br></strong>">
						</cfif>
					</cfif>
				</cfloop>
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
							<span class="#class#" #hint#>#field# &nbsp;&nbsp;</span>
							<cfif arrayFindNoCase(colNameArray,field) GT 0>
								<strong class="text-success">Present in CSV</strong>
							<cfelse>
								<!--- Case 2. Check by identifying field in required field list --->
								<cfif ListContainsNoCase(requiredFieldList,field)>
									<strong class="text-dark">Required column not found</strong>
									<cfset errorMessage = "#errorMessage# <strong>#field#</strong>">
								</cfif>
							</cfif>
						</li>
					</cfloop>
				</ul>
				<cfif len(errorMessage) GT 0>
					<cfif size GT 0>
						<cfif size GT 1><cfset plural="s"><cfelse><cfset plural=""></cfif>
						<!--- likely a problem parsing the first line into column headers --->
						<cfset errorMessage = "Column#plural# not found: #errorMessage#.">
					</cfif>
					<cfthrow message = "#NO_COLUMN_ERR# #errorMessage#">
				</cfif>
				<cfif NOT ListContainsNoCase(fieldList,aField)>
					<ul class="py-1 h4 list-unstyled">
					<strong>Found additional column header(s) in the CSV that is not in the list of expected headers: </strong>
					<!--- Identify additional columns that will be ignored --->
					<cfloop list="#foundHeaders#" item="aField">
						<cfif NOT ListContainsNoCase(fieldList,aField)>
							<li class="pt-1 px-4"><i class='fas fa-arrow-right text-info'></i> <strong class="text-info">#aField#</strong> </1i>
						</cfif>
					</cfloop>
					</ul>
				</cfif>
				<cfif NOT ListLen(ListRemoveDuplicates(foundHeaders)) EQ ListLen(foundHeaders)>
					<ul class="py-1 h4 list-unstyled">
						<cfset i=1>
						<!--- Identify duplicate columns and fail if found --->
						<cfif NOT ListLen(ListRemoveDuplicates(foundHeaders)) EQ ListLen(foundHeaders)>
							<strong>#DUP_COLUMN_ERR# </strong>
							<cfloop list="#foundHeaders#" item="aField">
								<cfif listValueCount(foundHeaders,aField) GT 1>
										<li class="pt-1 px-4"><i class='fas fa-arrow-right text-info'></i> <strong class="text-info">column ###i# = #aField#</strong> </1i>
								</cfif>
							<cfset i=i+1>
							</cfloop>
						</cfif>
					</ul>
				</cfif>
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
						<cfquery name="insert" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="insert_result">
							insert into cf_temp_oids
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
						<cfset error_message="Check Charset selected if your headers match required headers in red.<br> #COLUMN_ERR# from line #row# in input file.  <br>Header:[#colNames#] <br>Row:[#ArrayToList(collValuesArray)#] <br>Error: #cfcatch.message#"><!--- " --->
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
						<p>Showing #foundHighCount# example#plural#. If these do not appear as the correct characters, the file likely has a different encoding from the one you selected and
						you probably want to <strong><a href="/tools/BulkloadOtherId.cfm">reload</a></strong> this file selecting a different character set.  If these appear as expected, then 
							you selected the correct encoding and can continue to validate or load.</p>
					</div>
					<ul class="pb-1 h4 list-unstyled">
						#foundHighAscii# #foundMultiByte#
					</ul>
				</cfif>
				<h3>
					<cfif loadedRows EQ 0>
						Loaded no rows from the CSV file.  The file appears to be just a header with no data. Fix file and <a href="/tools/BulkloadOtherId.cfm">reload</a>
					<cfelse>
						Successfully read #loadedRows# records from the CSV file. Next <a href="/tools/BulkloadOtherId.cfm?action=validate">click to validate</a>.
					</cfif>
				</h3>
			<cfcatch>
				<h3>
					<span class="text-danger">Failed to read the CSV file.</span> Fix the errors in the file and <a href="/tools/BulkloadOtherId.cfm">reload</a>
				</h3>
				<cfif isDefined("othResult")>
					<cfset foundHighCount = 0>
					<cfset foundHighAscii = "">
					<cfset foundMultiByte = "">
					<cfloop from="1" to ="#ArrayLen(othResult[1])#" index="col">
						<cfset thisBit=othResult[1][col]>
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
		<h2 class="h4">Second step: Data Validation</h2>
			<cfoutput>
			<cfquery name="getTempTableTypes" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT 
					existing_other_id_type, existing_other_id_type,new_other_id_number, key
				FROM 
					cf_temp_oids
				WHERE 
					username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfloop query="getTempTableTypes">
				<cfif getTempTableTypes.existing_other_id_type eq 'catalog number'>
					<!--- either based on catalog_number --->
					<cfquery name="getCID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						UPDATE
							cf_temp_oids
						SET
							collection_object_id = (
								select collection_object_id 
								from cataloged_item 
								where cat_num = cf_temp_oids.existing_other_id_number 
								and collection_cde = cf_temp_oids.collection_cde
							),
							status = null
						WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
							and key = <cfqueryparam cfsqltype="CF_SQL_decimal" value="#getTempTableTypes.key#"> 
					</cfquery>
				<cfelse>
					<!--- or on specified other identifier --->
					<cfquery name="getCID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						UPDATE
							cf_temp_oids
						SET
							collection_object_id= (
								select cataloged_item.collection_object_id from cataloged_item,coll_obj_other_id_num 
								where coll_obj_other_id_num.other_id_type = cf_temp_oids.existing_other_id_type 
								and cataloged_item.collection_cde = cf_temp_oids.collection_cde 
								and display_value= cf_temp_oids.existing_other_id_number
								and cataloged_item.collection_object_id = coll_obj_other_id_num.COLLECTION_OBJECT_ID
							),
							status = null
						WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
							and key = <cfqueryparam cfsqltype="CF_SQL_decimal" value="#getTempTableTypes.key#"> 
					</cfquery>
				</cfif>
			</cfloop>
			<cfquery name="flagMczAcronym" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE cf_temp_oids
				SET 
					status = concat(nvl2(status, status || '; ', ''),'INSTIUTION_ACRONYM is not "MCZ" (check case)')
				WHERE institution_acronym <> 'MCZ'
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="flagMczAcronym" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE cf_temp_oids
				SET 
					status = concat(nvl2(status, status || '; ', ''),'COLLECTION_CDE does not match Cryo, Ent, Herp, Ich, IP, IZ, Mala, Mamm, Orn, SC, or VP (check case)')
				WHERE collection_cde not in (select collection_cde from ctcollection_cde)
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="flagNoCollectionObject" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE cf_temp_oids
				SET 
					status = concat(nvl2(status, status || '; ', ''),' There is no match to a cataloged item on "' || existing_other_id_type || '" = "' || existing_other_id_number || '" in collection "' || collection_cde ||'"')
				WHERE collection_object_id IS NULL
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="flagNotMatchedExistOther_ID_Type1" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE cf_temp_oids
				SET 
					status = concat(nvl2(status, status || '; ', ''), 'Unknown existing_other_id_type: "' || existing_other_id_type ||'"&mdash;not on list')
				WHERE existing_other_id_type is not null 
					AND existing_other_id_type <> 'catalog number'
					AND existing_other_id_type not in (select other_id_type from ctcoll_other_id_type)
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="flagNotMatchedExistOther_ID_Type2" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE cf_temp_oids
				SET 
					status = concat(nvl2(status, status || '; ', ''), 'Unknown new_other_id_type: "' || new_other_id_type ||'"&mdash;not on list')
				WHERE new_other_id_type is not null 
					AND new_other_id_type <> 'catalog number'
					AND new_other_id_type not in (select other_id_type from ctcoll_other_id_type)
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<!---Missing data in required fields--->
			<cfloop list="#requiredfieldlist#" index="requiredField">
				<cfquery name="checkRequired" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					UPDATE cf_temp_oids
					SET 
						status = concat(nvl2(status, status || '; ', ''),'#requiredField# is missing')
					WHERE #requiredField# is null
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
			</cfloop>
			
			<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT collection_object_id,collection_cde,institution_acronym,existing_other_id_type,existing_other_id_number,new_other_id_type,new_other_id_number,status
				FROM cf_temp_oids
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="pf" dbtype="query">
				SELECT count(*) c 
				FROM data 
				WHERE status is not null
			</cfquery>
			<cfif pf.c gt 0>
				<h3 class="mt-4">
					There is a problem with #pf.c# of #data.recordcount# row(s). See the STATUS column. (<a href="/tools/BulkloadOtherId.cfm?action=dumpProblems">download</a>).
				</h3>
				<h3 class="my-2">
					Fix the problems in the data and <a href="/tools/BulkloadOtherId.cfm">start again</a>.
				</h3>
			<cfelse>
				<h3 class="mt-4 mb-2">
					<span class="text-success">Validation checks passed.</span> Look over the table below and <a href="/tools/BulkloadOtherId.cfm?action=load">click to continue</a> if it all looks good or <a href="/tools/BulkloadOtherId.cfm">start again</a>.
				</h3>
			</cfif>
			<table class='px-0 sortable table table-responsive table-striped d-lg-table'>
				<thead>
					<tr>
						<th>BULKLOADING STATUS</th>
						<th>INSTITUTION_ACRONYM</th>
						<th>COLLECTION_CDE</th>
						<th>EXISTING_OTHER_ID_TYPE</th>
						<th>EXISTING_OTHER_ID_NUMBER</th>
						<th>NEW_OTHER_ID_TYPE</th>
						<th>NEW_OTHER_ID_NUMBER</th>
					</tr>
				<tbody>
					<cfloop query="data">
						<tr>
							<td><cfif len(data.status) eq 0>Cleared to load<cfelse><strong>#data.status#</strong></cfif></td>
							<td>#data.institution_acronym#</td>
							<td>#data.collection_cde#</td>
							<td>#data.existing_other_id_type#</td>
							<td>#data.existing_other_id_number#</td>
							<td>#data.new_other_id_type#</td>
							<td>#data.new_other_id_number#</td>
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
			<cfset problem_key = "">
			<cftransaction>
				<cfquery name="getTempData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT * FROM cf_temp_oids
					WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cfquery name="getCounts" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT count(distinct collection_object_id) ctobj FROM cf_temp_oids
					WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
			<cftry>
					<cfset testParse = 0>
					<cfif getTempData.recordcount EQ 0>
						<cfthrow message="You have no rows to load in the Other ID bulkloader table (cf_temp_oids).  <a href='/tools/BulkloadOtherId.cfm'>Start over</a>"><!--- " --->
					</cfif>
					<cfset i = 0>
					<cfloop query="getTempData">
						<cfset problem_key = getTempData.key>
						<cfstoredproc procedure="parse_other_id" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							<cfprocparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
							<cfprocparam cfsqltype="cf_sql_varchar" value="#new_other_id_number#">
							<cfprocparam cfsqltype="cf_sql_varchar" value="#new_other_id_type#">
						</cfstoredproc>
						<cfquery name="updateParse" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="updateParse_result">
							select distinct display_value
								from coll_obj_other_id_num 
								where collection_object_id =<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.collection_object_id#">
								group by display_value
								having count(*) > 1
						</cfquery>
						<cfset testParse = testParse + 1>
						<cfif updateParse_result.recordcount gt 0>
							<cftransaction action = "ROLLBACK">
						<cfelse>
							<cftransaction action="COMMIT">
						</cfif>
						<cfset i = i+1>
					</cfloop>
					<cfif getTempData.recordcount eq testParse and updateParse_result.recordcount eq 0>
						<p>Number of Other IDs updated: #i# (on #getCounts.ctobj# cataloged items)</p>
						<h2 class="text-success">Success - loaded</h2>
					</cfif>
					<cfif updateParse_result.recordcount gt 0>
						<p>Attempted to update #i# Other IDs (on #getCounts.ctobj# cataloged items)</p>
						<h2 class="text-danger">Not loaded - these have already been loaded</h2>
					</cfif>
				
					<cfcatch>
						<cftransaction action="ROLLBACK">
						<h2 class="text-danger mt-4">There was a problem updating the Other IDs.</h2>
						<cfquery name="getProblemData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getProblemData_result">
							SELECT institution_acronym, collection_cde,existing_other_id_type, existing_other_id_number, new_other_id_type,new_other_id_number,collection_object_id
							FROM cf_temp_oids
							WHERE key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#problem_key#">
						</cfquery>
						
							<h3 class="h4">Errors encountered during application are displayed one row at a time.</h3>
							<h3 class="mt-3 mb-2">
								Error loading row (<span class="text-danger">#getProblemData_result.recordcount#</span>) from the CSV: 
								<cfif len(cfcatch.detail) gt 0>
									<span class="border-bottom border-danger">
										<cfif cfcatch.detail contains "NEW_OTHER_ID_TYPE">
											Invalid MEW_OTHER_ID_TYPE; check controlled vocabulary (Help menu)
										<cfelseif cfcatch.detail contains "COLLECTION_CDE">
											COLLECTION_CDE does not match abbreviated collection (e.g., Ent, Herp, Ich, IP, IZ, Mala, Mamm, Orn, SC, or VP)
										<cfelseif cfcatch.detail contains "INSTITUTION_ACRONYM">
											INSTITUTION_ACRONYM does not match MCZ (all caps)
										<cfelseif cfcatch.detail contains "NEW_OTHER_ID_NUMBER">
											Problem with NEW_OTHER_ID_NUMBER, check to see the correct new_other_id_number was entered
										<cfelseif cfcatch.detail contains "unique constraint">
											Problem with NEW_OTHER_ID_NUMBER (see below); NEW_OTHER_ID_NUMBER already entered; Remove and <a href="/tools/BulkloadOtherId.cfm">try again</a>
										<cfelseif cfcatch.detail contains "COLLECTION_OBJECT_ID">
											Problem with EXISTING_OTHER_ID_TYPE or EXISTING_OTHER_ID_NUMBER (couldn not find collection_object_id) 
										<cfelseif cfcatch.detail contains "no data">
											No data or the wrong data (#cfcatch.detail#)
										<cfelseif cfcatch.detail contains "NULL">
											Missing Data (#cfcatch.detail#)
										<cfelse>
											 provide the raw error message if it isn't readily interpretable 
											#cfcatch.detail#
										</cfif>
									</span>
								</cfif>
							</h3>
							<table class='sortable table table-responsive table-striped d-lg-table'>
								<thead>
									<tr>
										<th>institution_acronym</th>
										<th>collection_cde</th>
										<th>existing_other_id_type</th>
										<th>existing_other_id_number</th>
										<th>new_other_id_type</th>
										<th>new_other_id_number</th>
										<th>collection_object_id</th>
									</tr>
								</thead>
								<tbody>
									<cfloop query="getProblemData">
										<tr>
											<td>#getProblemData.institution_acronym#</td>
											<td>#getProblemData.collection_cde#</td>
											<td>#getProblemData.existing_other_id_type#</td>
											<td>#getProblemData.existing_other_id_number#</td>
											<td>#getProblemData.new_other_id_type#</td>
											<td>#getProblemData.new_other_id_number#</td>
											<td>#getProblemData.collection_object_id#</td>
										</tr>
									</cfloop>
								</tbody>
							</table>
				<!---		<cfrethrow>--->
					</cfcatch>
				</cftry>
			</cftransaction>
			<cfquery name="clearTempTable" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="clearTempTable_result">
				DELETE FROM cf_temp_oids 
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
		</cfoutput>
	</cfif>
</main>

<cfinclude template="/shared/_footer.cfm">