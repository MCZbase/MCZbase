<!--- special case handling to dump problem data as csv --->
<cfif isDefined("action") AND action is "dumpProblems">
	<cfquery name="getProblemData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		SELECT institution_acronym,collection_cde,other_id_type,other_id_number,scientific_name,made_date,nature_of_id,accepted_id_fg,identification_remarks,taxa_formula,agent_1,agent_2,stored_as_fg
		FROM cf_temp_ID
		WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
	</cfquery>
	<cfinclude template="/shared/component/functions.cfc">
	<cfset csv = queryToCSV(getProblemData)>
	<cfheader name="Content-Type" value="text/csv">
	<cfoutput>#csv#</cfoutput>
	<cfabort>
</cfif>
		
<!--- end special case dump of problems --->
<cfset fieldlist = "institution_acronym,collection_cde,other_id_type,other_id_number,scientific_name,made_date,nature_of_id,accepted_id_fg,identification_remarks,taxa_formula,agent_1,agent_2,stored_as_fg">
<cfset fieldTypes ="CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_DECIMAL">
<cfset requiredfieldlist = "institution_acronym,collection_cde,other_id_type,other_id_number,scientific_name,nature_of_id,accepted_id_fg,agent_1">
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
<cfset pageTitle = "Bulkload Identification">
<cfinclude template="/shared/_header.cfm">
<cfif not isDefined("action") OR len(action) EQ 0><cfset action="nothing"></cfif>
<main class="container-fluid py-3 px-5" id="content">
	<h1 class="h2 mt-2">Bulkload Identification</h1>
	<cfif #action# is "nothing">
	<cfoutput>
			<p>This tool is used to bulkload identifications.Upload a comma-delimited text file (csv). Include column headings, spelled exactly as below. Additional colums will be ignored.</p>
			<span class="btn btn-xs btn-info" onclick="document.getElementById('template').style.display='block';">View template</span>
			<div id="template" class="my-1 mx-0" style="display:none;">
				<label for="templatearea" class="data-entry-label mb-1">
					Copy this header line and save it as a .csv file (<a href="/tools/BulkloadIdentification.cfm?action=getCSVHeader">download</a>)
				</label>
				<textarea rows="2" cols="90" id="templatearea" class="w-100 data-entry-textarea">#fieldlist#</textarea>
			</div>
			<h2 class="mt-4 h4">Columns in <span class="text-danger">red</span> are required; others are optional:</h2>
			<ul class="mb-4 h4 font-weight-normal">
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
			<form name="atts" method="post" enctype="multipart/form-data" action="/tools/BulkloadIdentification.cfm">
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
		<h2 class="h3">First step: Reading data from CSV file.</h2>
		<!--- Compare the numbers of headers expected against provided in CSV file --->
		<!--- Set some constants to identify error cases in cfcatch block --->
		<cfset NO_COLUMN_ERR = '<h4 class="mt-3">One or more required fields are missing in the header line of the csv file.</h4><p class="text-dark d-block">[<span class="font-weight-bold">Note:</span> If you uploaded csv columns that match the required headers and see "Required column not found" for those headers, check that the <span class="font-weight-bold">character set and format</span> you selected matches the file''s encodings.]</p>'><!--- ' --->
		<cfset DUP_COLUMN_ERR = "<p>Fix the one or more columns that are duplicated, mispelled, or added in the header line of the csv file and reload. </p>"><!--- " --->
		<cfset COLUMN_ERR = "Error inserting data ">
		<cfset NO_HEADER_ERR = "<h4 class='mb-3'>No header line found, csv file appears to be empty.</h4>"><!--- " --->
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
					DELETE FROM cf_temp_ID 
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
				<div class="col-12 my-4 px-0">
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
							<cfset errorMessage = "#errorMessage# #aField#">
						</cfif>
					</cfif>
				</cfloop>
				<cfset errorMessage = "">
				<cfif len(errorMessage) gt 0>
					<cfif size eq 1 >
						<cfthrow message = "#errorMessage# #NO_COLUMN_ERR# ">
					</cfif>
				</cfif>
				
				<!--- Loop through list of fields, mark each field as fields present in input or not, throw exception if required fields are missing --->
				<cfset errorMessage = "">
				<ul class="h4 mb-4 font-weight-normal">
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
									<cfset errorMessage = "#errorMessage# <div class='pl-3 pb-1 font-weight-bold'><i class='fas fa-arrow-right text-dark'></i> #field#</div>">
								</cfif>
							</cfif>
						</li>
					</cfloop>
				</ul>

				<!---OTHER TYPES OF ERRORS: DUPLICATION, WRONG CHARSET, WRONG FORMAT, EXTRA HEADERS--->
				<cfif len(errorMessage) GT 0>
					<h3 class="">Error Messages</h3>
					<cfif size EQ 1>
						<!--- Likely a problem parsing the first line into column headers --->
						<cfset errorMessage = "<div class='pt-3'><p>Column not found:</p> #errorMessage#</div>">
					<cfelse>
						<cfset errorMessage = "<div class='pt-3'><p>Columns not found:</p> #errorMessage#</div>">
					</cfif>
					<cfthrow message = "#NO_COLUMN_ERR# #errorMessage#">
				</cfif>
						
				<cfif #aField# GT 1><cfset plural1="s"><cfelse><cfset plural1=""></cfif>
				<cfif #aField# GT 1><cfset plural1a="are"><cfelse><cfset plural1a="is"></cfif>
				<cfif #aField# GT 1><cfset plural2=""><cfelse><cfset plural2="s"></cfif>
				<!--- Identify additional columns that will be ignored --->
				<cfif NOT ListContainsNoCase(fieldList,aField)>
					<h3 class="h4">Warning: Found additional column header#plural1# in the CSV that #plural1a# not in the list of expected headers: </h3>
					<!--- Identify additional columns that will be ignored --->
					<cfloop list="#foundHeaders#" item="aField">
						<cfif NOT ListContainsNoCase(fieldList,aField)>
							<li class="pb-1 px-4"><i class='fas fa-arrow-right text-info'></i> <strong class="text-info">#aField#</strong> </1i>
						</cfif>
					</cfloop>
				</cfif>
					<!--- Identify additional columns that will be ignored --->
				<cfset containsAdditional=false>
				<cfset additionalCount = 0>
				<cfloop list="#foundHeaders#" item="aField">
					<cfif NOT ListContainsNoCase(fieldList,aField)>
						<cfset containsAdditional=true>
						<cfset additionalCount = additionalCount+1>
					</cfif>
				</cfloop>
				<cfif containsAdditional>
					<cfif additionalCount GT 1><cfset plural1="s"><cfelse><cfset plural1=""></cfif>
					<cfif additionalCount GT 1><cfset plural1a="are"><cfelse><cfset plural1a="is"></cfif>
					<h3 class="h4">Warning: Found #additionalCount# additional column header#plural1# in the CSV that #plural1a# not in the list of expected headers: </h3>
					<!--- Identify additional columns that will be ignored --->
					<cfloop list="#foundHeaders#" item="aField">
						<cfif NOT ListContainsNoCase(fieldList,aField)>
							<li class="pb-1 px-4"><i class='fas fa-arrow-right text-info'></i> <strong class="text-info">#aField#</strong> </1i>
						</cfif>
					</cfloop>
					<!--- Do not throw an exception, additional columns to be ignored are not fatal. --->
				</cfif>
				
				<!--- Identify duplicate columns and fail if found --->
				<cfif NOT ListLen(ListRemoveDuplicates(foundHeaders)) EQ ListLen(foundHeaders)>
					<h3 class="h4">Expected column header#plural1# occur#plural2# more than once: </h3>
					<ul class="pb-1 h4 list-unstyled">
						<!--- Identify duplicate columns and fail if found --->
						<cfloop list="#foundHeaders#" item="aField">
							<cfif listValueCount(foundHeaders,aField) GT 1>
									<li class="pb-1 px-4 text-dark"><i class='fas fa-arrow-right text-dark'></i> #aField# </1i>
							</cfif>
						<cfset i=i+1>
						</cfloop>
					</ul>
					<cfthrow message = "#DUP_COLUMN_ERR#">
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
						<cfset thisBit = "#rowData.get(JavaCast('int',i))#" >
						<!--- store in a coldfusion array so we won't need JavaCast to reference by position --->
						<cfset ArrayAppend(collValuesArray,thisBit)>
						<cfif REFind("[^\x00-\x7F]",thisBit) GT 0>
							<!--- high ASCII --->
							<cfif foundHighCount LT 6>
								<cfset foundHighAscii = "#foundHighAscii# <li class='text-dark pb-1'><i class='fas fa-arrow-right text-dark'></i> #thisBit#</li>"><!--- " --->
								<cfset foundHighCount = foundHighCount + 1>
							</cfif>
						<cfelseif REFind("[\xc0-\xdf][\x80-\xbf]",thisBit) GT 0>
							<!--- multibyte --->
							<cfif foundHighCount LT 6>
								<cfset foundMultiByte = "#foundMultiByte# <li class='text-dark pb-1'><i class='fas fa-arrow-right text-dark'></i>  #thisBit#</li>"><!--- " --->
								<cfset foundHighCount = foundHighCount + 1>
							</cfif>
						</cfif>
					</cfloop>
					<cftry>
						<!--- construct insert for row with a line for each entry in fieldlist using cfqueryparam if column header is in fieldlist, otherwise using null --->
						<!--- Note: As we can't use csvFormat.withHeader(), we can not match columns by name, we are forced to do so by number, thus arrays --->
						<cfquery name="insert" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="insert_result">
							insert into cf_temp_ID
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
					<cfif foundHighCount GT 1><cfset plural="s"><cfelse><cfset plural=""></cfif>
					<!---This shows when everything is correct but the code found special characters.--->
					<h3 class="h4"><span class="text-danger">Check character set.</span> Found characters where the encoding is probably important in the input data. </h3>
					<div class="px-4">
						<p>Showing #foundHighCount# example#plural#. If these do not appear as the correct characters, the file likely has a different encoding from the one you selected and
						you probably want to <strong><a href="/tools/BulkloadIdentification.cfm">reload</a></strong> this file selecting a different character set. If these appear as expected, then you selected the correct encoding and can continue to validate or load.</p>
						<ul class="h4 list-unstyled font-weight-normal ">
								<!---These include the <li></li>--->
							#foundHighAscii# #foundMultiByte#
						</ul>
					</div>
				</cfif>
				<h4>
					<cfif loadedRows EQ 0>
						Loaded no rows from the CSV file.  The file appears to be just a header with no data. Fix file and <a href="/tools/BulkloadIdentification.cfm">reload</a>
					<cfelse>
						<cfif size eq 1>Size = 1<cfelse>
						Successfully read #loadedRows# records from the CSV file. Next <a href="/tools/BulkloadIdentification.cfm?action=validate">click to validate</a>.</cfif>
					</cfif>
				</h4>
			<cfcatch>
				<h4>
					<strong class="text-danger">Failed to read the CSV file.</strong> Fix the errors in the file and <a href="/tools/BulkloadIdentification.cfm">reload</a>
				</h4>
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
	<cfif #action# is "validate">
		<h2 class="h4">Second step: Data Validation</h2>
			<cfoutput>
			<cfquery name="getTempTableTypes" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT 
					other_id_type,key
				FROM 
					cf_temp_ID
				WHERE 
					username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfloop query="getTempTableTypes">
				<cfif getTempTableTypes.other_id_type eq 'catalog number'>
					<!--- either based on catalog_number --->
					<cfquery name="getCID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						UPDATE
							cf_temp_ID
						SET
							collection_object_id = (
								select collection_object_id 
								from cataloged_item 
								where cat_num = cf_temp_ID.other_id_number 
								and collection_cde = cf_temp_ID.collection_cde
							),
							status = null
						WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
							and key = <cfqueryparam cfsqltype="CF_SQL_decimal" value="#getTempTableTypes.key#"> 
					</cfquery>
				<cfelse>
					<!--- or on specified other identifier --->
					<cfquery name="getCID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						UPDATE
							cf_temp_ID
						SET
							collection_object_id= (
							SELECT cataloged_item.collection_object_id 
							FROM cataloged_item,coll_obj_other_id_num 
							WHERE coll_obj_other_id_num.other_id_type = cf_temp_ID.other_id_type 
							AND cataloged_item.collection_cde = cf_temp_ID.collection_cde 
							AND display_value = cf_temp_ID.other_id_number
							AND cataloged_item.collection_object_id = coll_obj_other_id_num.COLLECTION_OBJECT_ID
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
					key,collection_object_id,collection_cde,nature_of_id,scientific_name,taxa_formula,agent_1,agent_2
				FROM 
					cf_temp_ID
				WHERE 
					username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfloop query="getTempTableQC">
				<cfquery name="flagMczAcronym" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE cf_temp_ID
					SET 
						status = concat(nvl2(status, status || '; ', ''),'INSTIUTION_ACRONYM is not "MCZ" (check case)')
					WHERE institution_acronym <> 'MCZ'
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						AND key = <cfqueryparam cfsqltype="CF_SQL_decimal" value="#getTempTableQC.key#"> 
				</cfquery>
				<cfquery name="flagMczAcronym" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE cf_temp_ID
					SET 
						status = concat(nvl2(status, status || '; ', ''),'COLLECTION_CDE does not match Cryo, Ent, Herp, Ich, IP, IZ, Mala, Mamm, Orn, SC, or VP (check case)')
					WHERE collection_cde not in (select collection_cde from ctcollection_cde)
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						AND key = <cfqueryparam cfsqltype="CF_SQL_decimal" value="#getTempTableQC.key#"> 
				</cfquery>
				<cfquery name="flagNoCollectionObject" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE cf_temp_ID
					SET 
						status = concat(nvl2(status, status || '; ', ''),' There is no match to a cataloged item on "'||other_id_type||'" = "'||other_id_number||'" in collection "'||collection_cde||'"')
					WHERE collection_object_id IS NULL
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						AND key = <cfqueryparam cfsqltype="CF_SQL_decimal" value="#getTempTableQC.key#"> 
				</cfquery>
				<cfquery name="flagNotMatchedExistOther_ID_Type1" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE cf_temp_ID
					SET 
						status = concat(nvl2(status, status || '; ', ''), 'Unknown other_id_type: "' || other_id_type ||'"&mdash;not on list')
					WHERE other_id_type is not null 
						AND other_id_type <> 'catalog number'
						AND other_id_type not in (select other_id_type from ctcoll_other_id_type)
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						AND key = <cfqueryparam cfsqltype="CF_SQL_decimal" value="#getTempTableQC.key#"> 
				</cfquery>
				<cfquery name="flagNotMatchedToStoredAs" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE cf_temp_ID
					SET 
						status = concat(nvl2(status, status || '; ', ''), 'Stored_as_fg can only be 1 when identification is not current (accepted_id_fg=1)')
					WHERE stored_as_fg = 1
						AND accepted_id_fg = 1
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						AND key = <cfqueryparam cfsqltype="CF_SQL_decimal" value="#getTempTableQC.key#"> 
				</cfquery>
				<cfquery name="flagNotMatchCTnature" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE cf_temp_ID SET 
					status = concat(nvl2(status, status || '; ', ''), 'Unknown nature of ID: "'||nature_of_id||'"')
					WHERE nature_of_id not in (select nature_of_id from ctnature_of_id)
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						AND key = <cfqueryparam cfsqltype="CF_SQL_decimal" value="#getTempTableQC.key#"> 
				</cfquery>
				<cfquery name="getCTFormula" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE cf_temp_ID 
					SET status = concat(nvl2(status, status || '; ', ''),'taxa_formula is not found')
					WHERE taxa_formula is null 
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						AND key = <cfqueryparam cfsqltype="CF_SQL_decimal" value="#getTempTableQC.key#"> 
				</cfquery>
				<cfquery name="getTaxaID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					update cf_temp_id set taxon_name_id =
					(SELECT taxon_name_id FROM taxonomy where scientific_name ='#getTempTableQC.scientific_name#')
					WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						AND key = <cfqueryparam cfsqltype="CF_SQL_decimal" value="#getTempTableQC.key#"> 
				</cfquery>
				<cfquery name="flagNotMatchSciName" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE cf_temp_ID SET status = concat(nvl2(status, status || '; ', ''),'scientific_name not found')
					WHERE scientific_name is null 
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						AND key = <cfqueryparam cfsqltype="CF_SQL_decimal" value="#getTempTableQC.key#"> 
				</cfquery>
				<cfquery name="a1" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select distinct agent_id from agent_name where agent_name='#agent_1#'
				</cfquery>
				<cfif #a1.recordcount# is not 1>
					<cfif len(#problem#) is 0>
						<cfset problem = "agent_1 matched #a1.recordcount# records">
					<cfelse>
						<cfset problem = "#problem#; agent_1 matched #a1.recordcount# records">
					</cfif>
				<cfelse>
					<cfquery name="insColl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						UPDATE cf_temp_id SET agent_1_id = #a1.agent_id# where
						key = #key#
					</cfquery>
				</cfif>
				<cfif len(agent_2) gt 0>
					<cfquery name="a2" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select distinct agent_id from agent_name where agent_name='#agent_2#'
					</cfquery>
					<cfif #a2.recordcount# is not 1>
						<cfif len(#problem#) is 0>
							<cfset problem = "agent_2 matched #a2.recordcount# records">
						<cfelse>
							<cfset problem = "#problem#; agent_2 matched #a2.recordcount# records">
						</cfif>
					<cfelse>
						<cfquery name="insColl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							UPDATE cf_temp_id SET agent_2_id = #a2.agent_id# where
							key = #key#
						</cfquery>
					</cfif>
				</cfif>
				<cfquery name="miap" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE cf_temp_ID SET status = concat(nvl2(status, status || '; ', ''), 'collection_object_id not found')
					WHERE collection_object_id is null 
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						AND key = <cfqueryparam cfsqltype="CF_SQL_decimal" value="#getTempTableQC.key#"> 
				</cfquery>
				<cfset scientific_name = '#getTempTableQC.scientific_name#'>
				<cfset tf = '#getTempTableQC.taxa_formula#'>
				<cfif right(scientific_name,4) is " sp.">
					<cfset scientific_name=left(scientific_name,len(scientific_name) -4)>
					<cfset tf = "A sp.">
				<cfelseif right(scientific_name,5) is " ssp.">
					<cfset scientific_name=left(scientific_name,len(scientific_name) -5)>
					<cfset tf = "A ssp.">
				<cfelseif right(scientific_name,5) is " spp.">
					<cfset scientific_name=left(scientific_name,len(scientific_name) -5)>
					<cfset tf = "A spp.">
				<cfelseif right(scientific_name,5) is " var.">
					<cfset scientific_name=left(scientific_name,len(scientific_name) -5)>
					<cfset tf = "A var.">
				<cfelseif right(scientific_name,9) is " sp. nov.">
					<cfset scientific_name=left(scientific_name,len(scientific_name) -9)>
					<cfset tf = "A sp. nov.">
				<cfelseif right(scientific_name,10) is " gen. nov.">
					<cfset scientific_name=left(scientific_name,len(scientific_name) -10)>
					<cfset tf = "A gen. nov.">
				<cfelseif right(scientific_name,8) is " (Group)">
					<cfset scientific_name=left(scientific_name,len(scientific_name) -8)>
					<cfset tf = "A (Group)">
				<cfelseif right(scientific_name,4) is " nr.">
					<cfset scientific_name=left(scientific_name,len(scientific_name) -5)>
					<cfset tf = "A nr.">
				<cfelseif right(scientific_name,4) is " cf.">
					<cfset scientific_name=left(scientific_name,len(scientific_name) -4)>
					<cfset tf = "A cf.">
				<cfelseif right(scientific_name,2) is " ?">
					<cfset scientific_name=left(scientific_name,len(scientific_name) -2)>
					<cfset tf = "A ?">
				<cfelse>
					<cfset  tf = "A">
					<cfset scientific_name="#scientific_name#">
				</cfif>
			</cfloop>
			<!---Missing data in required fields--->
			<cfloop list="#requiredfieldlist#" index="requiredField">
				<cfquery name="checkRequired" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE cf_temp_ID
					SET 
						status = concat(nvl2(status, status || '; ', ''),'#requiredField# is missing')
					WHERE #requiredField# is null
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						AND key = <cfqueryparam cfsqltype="CF_SQL_decimal" value="#getTempTableQC.key#"> 
				</cfquery>
			</cfloop>
			
			<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT key,status,collection_object_id,nature_of_id,taxon_name_id,scientific_name,institution_acronym,collection_cde,other_id_type,other_id_number,made_date,accepted_id_fg,identification_remarks,taxa_formula,agent_1,agent_2,stored_as_fg
				FROM cf_temp_ID
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				and key = <cfqueryparam cfsqltype="CF_SQL_decimal" value="#getTempTableQC.key#"> 
			</cfquery>
			<cfquery name="problemCount" dbtype="query">
				SELECT count(*) c 
				FROM data 
				WHERE status is not null
			</cfquery>
			<cfif problemCount.c gt 0>
				<h3 class="mt-4">
					<cfif problemCount.c GT 1><cfset plural="s"><cfelse><cfset plural=""></cfif>
					There is a problem with #problemCount.c# of #data.recordcount# row#plural#. See the STATUS column. (<a href="/tools/BulkloadIdentification.cfm?action=dumpProblems">download</a>).
				</h3>
				<h3 class="my-2">
					Fix the problems in the data and <a href="/tools/BulkloadIdentification.cfm">start again</a>.
				</h3>
			<cfelse>
				<h3 class="mt-4 mb-2">
					<span class="text-success">Validation checks passed.</span> Look over the table below and <a href="/tools/BulkloadIdentification.cfm?action=load">click to continue</a> if it all looks good or <a href="/tools/BulkloadIdentification.cfm">start again</a>.
				</h3>
			</cfif>
			<table class='px-0 sortable table small table-responsive table-striped d-lg-table'>
				<thead>
					<tr>
						<th>BULKLOAD&nbsp;STATUS</th>
						<th>INSTITUTION_ACRONYM</th>
						<th>COLLECTION_CDE</th>
						<th>OTHER_ID_TYPE</th>
						<th>OTHER_ID_NUMBER</th>
						<th>SCIENTIFIC_NAME</th>
						<th>MADE_DATE</th>
						<th>NATURE_OF_ID</th>
						<th>ACCEPTED_ID_FG</th>
						<th>IDENTIFICATION_REMARKS</th>
						<th>taxa_formula</th>
						<th>AGENT_1</th>
						<th>AGENT_2</th>
						<th>STORED_AS_FG</th>
					</tr>
				<tbody>
					<cfloop query="data">
						<tr>
							<td><cfif len(data.status) eq 0>Cleared to load<cfelse><strong>#data.status#</strong></cfif></td>
							<td>#data.INSTITUTION_ACRONYM#</td>
							<td>#data.COLLECTION_CDE#</td>
							<td>#data.OTHER_ID_TYPE#</td>
							<td>#data.OTHER_ID_NUMBER#</td>
							<td>#data.scientific_name# </td>
							<td>#data.MADE_DATE#</td>
							<td>#data.NATURE_OF_ID#</td>
							<td>#data.ACCEPTED_ID_FG#</td>
							<td>#data.IDENTIFICATION_REMARKS#</td>
							<td>#data.TAXA_FORMULA#</td>
							<td>#data.AGENT_1#</td>
							<td>#data.AGENT_2#</td>
							<td>#data.STORED_AS_FG#</td>
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
				<cfquery name="getCounts" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT count(distinct collection_object_id) c FROM cf_temp_ID
					WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cfquery name="NEXTID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					select sq_identification_id.nextval NEXTID from dual
				</cfquery>
				<cfquery name="getTempData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT KEY,COLLECTION_OBJECT_ID,COLLECTION_CDE,INSTITUTION_ACRONYM,OTHER_ID_TYPE,OTHER_ID_NUMBER,SCIENTIFIC_NAME,MADE_DATE,NATURE_OF_ID, ACCEPTED_ID_FG,IDENTIFICATION_REMARKS,AGENT_1,AGENT_2,STATUS,TAXON_NAME_ID,TAXA_FORMULA,AGENT_1_ID,AGENT_2_ID,STORED_AS_FG FROM cf_temp_ID
					WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cftry>
					<cfif getTempData.recordcount EQ 0>
						<cfthrow message="You have no rows to load in the Identifications bulkloader table (cf_temp_ID). <a href='/tools/BulkloadIdentification.cfm'>Start over</a>">
					</cfif>
					<cfset insert_id = 0>
					<cfset insertidt = 0>
					<cfset insertida1 = 0>
					<cfloop query="getTempData">
						<cfset problem_key = getTempData.key>
						<cfif getTempData.ACCEPTED_ID_FG is 1>
							<cfquery name="sinkOld" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
								update identification set ACCEPTED_ID_FG=0 
								where COLLECTION_OBJECT_ID=#getTempData.COLLECTION_OBJECT_ID#
							</cfquery>
						</cfif>
						<cfquery name="insertID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="insertID_result">
							insert into identification (
								IDENTIFICATION_ID,
								COLLECTION_OBJECT_ID,
								MADE_DATE,
								NATURE_OF_ID,
								ACCEPTED_ID_FG,
								IDENTIFICATION_REMARKS,
								TAXA_FORMULA,
								SCIENTIFIC_NAME,
								stored_as_fg
							) values (
								#NEXTID.NEXTID#,
								#COLLECTION_OBJECT_ID#,
								'#MADE_DATE#',
								'#NATURE_OF_ID#',
								#ACCEPTED_ID_FG#,
								'#IDENTIFICATION_REMARKS#',
								'#TAXA_FORMULA#',
								'#SCIENTIFIC_NAME#',
								<cfif len(stored_as_fg)gt 0>
									#stored_as_fg#
								<cfelse>
									'(null)'
								</cfif>
								group by IDENTIFICATION_ID,
								COLLECTION_OBJECT_ID,
								MADE_DATE,
								NATURE_OF_ID,
								ACCEPTED_ID_FG,
								IDENTIFICATION_REMARKS,
								TAXA_FORMULA,
								SCIENTIFIC_NAME,
								stored_as_fg
								having count(*) > 1
							)
						</cfquery>
						<cfquery name="insertIDT" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="insertIDT_result">
							insert into identification_taxonomy (
								IDENTIFICATION_ID,
								TAXON_NAME_ID,
								VARIABLE
							) values (
								sq_identification_id.currval,
								#TAXON_NAME_ID#,
								'A')
						</cfquery>
						<cfquery name="insertIDA1" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="insertIDA1_result">
							insert into identification_agent (
								IDENTIFICATION_ID,
								AGENT_ID,
								IDENTIFIER_ORDER
							) values (
								sq_identification_id.currval,
								#agent_1_id#,
								1
							)
						</cfquery>
						<cfset insert_id = insert_id + insertID_result.recordcount>
						<cfif insertIDA1_result.recordcount gt 0>
							<cftransaction action = "ROLLBACK">
						<cfelse>
							<cftransaction action="COMMIT">
						</cfif>
					</cfloop>
					<cfif getTempData.recordcount eq insert_id and insertID_result.recordcount eq 0>
						<p>Number of Identifications updated: #insert_id# (on #getCounts.c# cataloged items)</p>
						<h2 class="text-success">Success - loaded</h2>
					</cfif>
					<cfif insertIDA1_result.recordcount gt 0>
						<p>Attempted to update #insert_id# Identifications (on #getCounts.c# cataloged items)</p>
						<h2 class="text-danger">Not loaded - these have already been loaded</h2>
					</cfif>
				<cfcatch>
					<cftransaction action="ROLLBACK">
					<h2 class="text-danger mt-4">There was a problem updating the Identifications.</h2>
					<cfquery name="getProblemData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getProblemData_result">
						SELECT institution_acronym, collection_cde,other_id_type, other_id_number,collection_object_id,scientific_name,made_date,nature_of_id,accepted_id_fg,identification_remarks,agent_1, agent_2,taxa_formula,taxon_name_id,stored_as_fg
						FROM cf_temp_id
						WHERE key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#problem_key#">
					</cfquery>
						
					<h3 class="h4">Errors encountered during application are displayed one row at a time.</h3>
					<h3 class="mt-3 mb-2">
						Error loading row (<span class="text-danger">#getProblemData_result.recordcount#</span>) from the CSV: 
						<cfif len(cfcatch.detail) gt 0>
							<span class="border-bottom border-danger">
								<cfif cfcatch.detail contains "OTHER_ID_TYPE">
									Invalid OTHER_ID_TYPE; check controlled vocabulary (Help menu)
								<cfelseif cfcatch.detail contains "COLLECTION_CDE">
									COLLECTION_CDE does not match abbreviated collection (e.g., Ent, Herp, Ich, IP, IZ, Mala, Mamm, Orn, SC, or VP)
								<cfelseif cfcatch.detail contains "INSTITUTION_ACRONYM">
									INSTITUTION_ACRONYM does not match MCZ (all caps)
								<cfelseif cfcatch.detail contains "OTHER_ID_NUMBER">
									Problem with OTHER_ID_NUMBER, check to see the correct other_id_number was entered
								<cfelseif cfcatch.detail contains "unique constraint">
									Problem with OTHER_ID_NUMBER (see below); OTHER_ID_NUMBER already entered; Remove and <a href="/tools/BulkloadIdentification.cfm">try again</a>
								<cfelseif cfcatch.detail contains "COLLECTION_OBJECT_ID">
									Problem with OTHER_ID_TYPE or OTHER_ID_NUMBER (could not find collection_object_id) 
								<cfelseif cfcatch.detail contains "SCIENTIFIC_NAME">
									Problem with SCIENTIFIC_NAME 
								<cfelseif cfcatch.detail contains "no data">
									No data or the wrong data (#cfcatch.detail#)
								<cfelseif cfcatch.detail contains "NULL">
									Missing Data (#cfcatch.detail#)
								<cfelse>
									 <!--- provide the raw error message if it is not readily interpretable --->
									#cfcatch.detail#
								</cfif>
							</span>
						</cfif>
					</h3>
					<table class='sortable table small table-responsive table-striped d-lg-table'>
						<thead>
							<tr>
								<th>institution_acronym</th>
								<th>collection_cde</th>
								<th>other_id_type</th>
								<th>other_id_number</th>
								<th>collection_object_id</th>
								<th>institution_acronym</th>
								<th>scientific_name</th>
								<th>made_date</th>
								<th>nature_of_id</th>
								<th>accepted_id_fg</th>
								<th>identification_remarks</th>
								<th>agent_1</th>
								<th>agent_2</th>
								<th>stored_as_fg</th>
								<th>taxon_named_id</th>
							</tr>
						</thead>
						<tbody>
							<cfloop query="getProblemData">
								<tr>
									<td>#getProblemData.institution_acronym#</td>
									<td>#getProblemData.collection_cde#</td>
									<td>#getProblemData.other_id_type#</td>
									<td>#getProblemData.other_id_number#</td>
									<td>#getProblemData.collection_object_id#</td>
									<td>#getProblemData.scientific_name#</td>
									<td>#getProblemData.made_date#</td>
									<td>#getProblemData.nature_of_id#</td>
									<td>#getProblemData.accepted_id_fg#</td>
									<td>#getProblemData.identification_remarks#</td>
									<td>#getProblemData.agent_1#</td>
									<td>#getProblemData.agent_2#</td>
									<td>#getProblemData.taxa_formula#</td>
									<td>#getProblemData.stored_as_fg#</td>
									<td>#getProblemData.taxon_name_id#</td>
								</tr>
							</cfloop>
						</tbody>
					</table>
					<cfrethrow>
				</cfcatch>
				</cftry>
			</cftransaction>
			<cfquery name="clearTempTable" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="clearTempTable_result">
				DELETE FROM cf_temp_ID 
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
		</cfoutput>
	</cfif>
</main>
<cfinclude template="/shared/_footer.cfm">
