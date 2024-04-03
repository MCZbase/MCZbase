<!--- tools/bulkloadNewParts.cfm add parts to specimens in bulk.

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
<cfif isDefined("action") AND action is "dumpProblems">
	<cfquery name="getProblemData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		SELECT institution_acronym,collection_cde,other_id_type,other_id_number,part_name,preserve_method,lot_count_modifier,lot_count,condition,coll_obj_disposition
		FROM cf_temp_parts
		WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
	</cfquery>
	<cfinclude template="/shared/component/functions.cfc"><!---need to add to functions.cfc page--->
	<cfset csv = queryToCSV(getProblemData)>
	<cfheader name="Content-Type" value="text/csv">
	<cfoutput>#csv#</cfoutput>
	<cfabort>
</cfif>
<cfset fieldlist = "institution_acronym,collection_cde,other_id_type,other_id_number,container_unique_id,part_name,preserve_method,lot_count_modifier,lot_count,condition,coll_obj_disposition,current_remarks,part_att_name_1,part_att_val_1,part_att_units_1,part_att_detby_1,part_att_madedate_1,part_att_rem_1,part_att_name_2,part_att_val_2,part_att_units_2,part_att_detby_2,part_att_madedate_2,part_att_rem_2,part_att_name_3,part_att_val_3,part_att_units_3,part_att_detby_3,part_att_madedate_3,part_att_rem_3,part_att_name_4,part_att_val_4,part_att_units_4,part_att_detby_4,part_att_madedate_4,part_att_rem_4,part_att_name_5,part_att_val_5,part_att_units_5,part_att_detby_5,part_att_madedate_5,part_att_rem_5,part_att_name_6,part_att_val_6,part_att_units_6,part_att_detby_6,part_att_madedate_6,part_att_rem_6">
<cfset fieldTypes ="CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_DATE,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_DATE,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_DATE,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_DATE,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_DATE,CF_SQL_VARCHAR">
<cfset requiredfieldlist = "institution_acronym,collection_cde,other_id_type,other_id_number,part_name,preserve_method,lot_count,condition,coll_obj_disposition">
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
<cfset pageTitle = "Bulk New Parts">
<cfinclude template="/shared/_header.cfm">
<cfif not isDefined("action") OR len(action) EQ 0><cfset action="nothing"></cfif>
<main class="container-fluid px-5 py-3" id="content">
	<div class="row mx-0">
		<div class="col-12 pb-3">
			<h1 class="h2 mt-2">Bulkload New Parts </h1>
		<!------------------------------------------------------->
			<cfif #action# is "nothing">
				<cfoutput>
				<div class="col-12 px-0">
					<p>This tool adds part rows to the specimen record. It create metadata for part history and includes specimen part attributes fields that can be empty if none exists. The cataloged items must be in the database and they can be entered using the catalog number or other ID. Error messages will appear if the values need to match values in MCZbase. It ignores rows that are exactly the same and alerts you if columns are missing. Additional columns will be ignored. Include column headings, spelled exactly as below. </p>
					<span class="btn btn-xs btn-info" onclick="document.getElementById('template').style.display='block';">View template</span>
					<div id="template" style="display:none;margin: 1em 0;">
						<label for="templatearea" class="data-entry-label">
							Copy this header line and save it as a .csv file (<a href="/tools/BulkloadNewParts.cfm?action=getCSVHeader">download</a>)
						</label>
						<textarea rows="2" cols="90" id="templatearea" class="w-100 data-entry-textarea">#fieldlist#</textarea>
					</div>
					<h2 class="mt-4 h4">Columns in <span class="text-danger">red</span> are required; others are optional:</h2>
					<ul class="mb-4 h4 small font-weight-normal align-items-start align-items list-group list-group-horizontal flex-wrap col-12">
						<cfloop list="#fieldlist#" index="field" delimiters=",">
							<cfset aria = "">
							<cfif listContains(requiredfieldlist,field,",")>
								<cfset class="text-danger">
								<cfset aria = "aria-label='Required Field'">
							<cfelse>
								<cfset class="text-dark">
							</cfif>
							<li class="#class# list-group-item col-2 px-0 mx-0" #aria#> #field#</li>
						</cfloop>
					</ul>
				</div>
					<form name="atts" method="post" enctype="multipart/form-data" action="/tools/BulkloadNewParts.cfm">
						<div class="form-row border rounded p-2 mb-3">
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
						<cfset COLUMN_ERR = "Error inserting data ">
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
							<cfquery name="clearTempTable" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="clearTempTable_result">
								DELETE FROM cf_temp_parts 
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

							<div class="col-12 px-0 my-4">
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
										<cfset errorMessage = "#errorMessage# <i class='fas fa-arrow-right'></i><strong> &nbsp;#aField#<br></strong>">
									</cfif>
								</cfif>
							</cfloop>
							<cfif len(errorMessage) GT 0>
								<cfthrow message = "#NO_COLUMN_ERR# <h4 class='px-4'> #errorMessage#</h4>">
							</cfif>
							<cfset errorMessage = "">
							<!--- Loop through list of fields, mark each field as fields present in input or not, throw exception if required fields are missing --->

							<ul class="mb-4 h4 font-weight-normal align-items-start align-items list-group list-group-horizontal flex-wrap col-12">
								<cfloop list="#fieldlist#" index="field" delimiters=",">
									<cfset hint="">
									<cfif listContains(requiredfieldlist,field,",")>
										<cfset class="text-danger">
										<cfset hint="aria-label='required'">
									<cfelse>
										<cfset class="text-dark">
									</cfif>
									<li class="d-flex col-3 small list-group-numbered list-group-item col-2 px-0 mx-0">
										<span class="#class#" #hint#>#field#</span>
										<cfif arrayFindNoCase(colNameArray,field) GT 0>
											<strong class="text-success px-2"> Present in CSV</strong>
										<cfelse>
											<!--- Case 2. Check by identifying field in required field list --->
											<cfif ListContainsNoCase(requiredFieldList,field)>
												<strong class="text-dark px-2"> Required Column Not Found</strong>
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
								<!---Construct insert for rows if column header is in fieldlist, otherwise use null--->
								<!---We cannot use csvFormat.withHeader() or match columns by name, so we are forced to match by number, use arrays--->
									<cfquery name="insert" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="insert_result">
										insert into cf_temp_parts
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
									<cfset error_message="#COLUMN_ERR# from line #row# in input file.  
														  <div class='mb-2 h4 font-weight-normal align-items-start align-items list-group list-group-horizontal flex-wrap col-12 small'>Header:[#colNames#]</div>   <div class='mb-2 h4 font-weight-normal align-items-start align-items list-group list-group-horizontal flex-wrap col-12 small'>Row:[#ArrayToList(collValuesArray)#] </div>Error: #cfcatch.message#"><!--- " --->
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
									you probably want to <strong><a href="/tools/BulkloadNewParts.cfm">reload</a></strong> this file selecting a different encoding.  If these appear as expected, then 
										you selected the correct encoding and can continue to validate or load.</p>
								</div>
								<ul class="pb-1 h4 list-unstyled">
									#foundHighAscii# #foundMultiByte#
								</ul>
							</cfif>
							<h3 class="h3">
								<cfif loadedRows EQ 0>
									Loaded no rows from the CSV file.  The file appears to be just a header with no data. Fix file and <a href="/tools/BulkloadNewParts.cfm">reload</a>
								<cfelse>
									Successfully read #loadedRows# records from the CSV file.  Next <a href="/tools/BulkloadNewParts.cfm?action=validate">click to validate</a>.
								</cfif>
							</h3>
						<cfcatch>
							<h3 class="h4">
								Failed to read the CSV file.  Fix the errors in the file and <a href="/tools/BulkloadNewParts.cfm">reload</a>
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
				<cfoutput>
				<h2 class="h4">Second step: Data Validation</h2>
				<cfquery name="getTempTableTypes" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT 
						other_id_type, key
					FROM 
						cf_temp_parts
					WHERE 
						username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cfset i= 1>
					<cfloop query="getTempTableTypes">
					<!--- For each row, set the target collection_object_id --->
					<cfif getTempTableTypes.other_id_type eq 'catalog number'>
						<!--- either based on catalog_number --->
						<cfquery name="getCID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							UPDATE
								cf_temp_parts
							SET
								collection_object_id = (
									select collection_object_id 
									from cataloged_item 
									where cat_num = cf_temp_parts.other_id_number and collection_cde = cf_temp_parts.collection_cde
								),
								status = null
							WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
								and key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableTypes.key#"> 
						</cfquery>
					<cfelse>
						<!--- or on specified other identifier --->
						<cfquery name="getCID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							UPDATE
								cf_temp_parts
							SET
								collection_object_id= (
									select cataloged_item.collection_object_id from cataloged_item,coll_obj_other_id_num 
									where coll_obj_other_id_num.other_id_type = cf_temp_parts.other_id_type 
									and cataloged_item.collection_cde = cf_temp_parts.collection_cde 
									and display_value= cf_temp_parts.other_id_number
									and cataloged_item.collection_object_id = coll_obj_other_id_num.COLLECTION_OBJECT_ID
								),
								status = null
							WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
								and key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableTypes.key#"> 
						</cfquery>
					</cfif>
				</cfloop>
				<!--- obtain the information needed to QC each row --->
				<cfquery name="getTempTableQC" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT 
						collection_object_id, key
					FROM 
						cf_temp_parts
					WHERE 
						username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cfloop query="getTempTableQC">
					<cfquery name="CollID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						update cf_temp_parts set 
						status = concat(nvl2(status, status || '; ', ''),'Check other id. Internal ID could not be created.')
						where collection_object_id is null 
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						AND key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableQC.key#">
					</cfquery>
					<!---Update the container with the container_unique_id from the spreadsheet--->
					<cfquery name="getParentContainerId" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						update cf_temp_parts set parent_container_id =
						(select parent_container_id from container where container.barcode = cf_temp_parts.container_unique_id)
						where username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						AND key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableQC.key#">
					</cfquery>
					<!---Add to the status message if the container is null --->
					<cfquery name="validateGotParent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						update cf_temp_parts set 
						status = concat(nvl2(status, status || '; ', ''),'Invalid Container Unique ID "' || container_unique_id ||'"')
						where container_unique_id is not null 
						and parent_container_id is null
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						AND key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableQC.key#">
					</cfquery>
					<!---Add to the status message if the container is null --->
					<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						update cf_temp_parts set 
						status = concat(nvl2(status, status || '; ', ''),'<span class="font-weight-bold">Invalid part_name "' || part_name ||'"</span>')
						where part_name|| '|' ||collection_cde NOT IN (
							select part_name|| '|' ||collection_cde from ctspecimen_part_name)
						OR part_name is null
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						AND key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableQC.key#">
					</cfquery>
					<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						update cf_temp_parts set 
						status = concat(nvl2(status, status || '; ', ''),'Invalid preserve method "'||preserve_method||'"')
						where (preserve_method|| '|' ||collection_cde NOT IN (select preserve_method|| '|' ||collection_cde from ctspecimen_preserv_method)) 
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						AND key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableQC.key#">
					</cfquery>
					<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						update cf_temp_parts set 
						status = concat(nvl2(status, status || '; ', ''),'Invalid container_unique_id "' || container_unique_id ||'"')
						where container_unique_id NOT IN (
							select barcode from container where barcode is not null) AND container_unique_id is not null
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						AND key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableQC.key#">
					</cfquery>
					<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						update cf_temp_parts set 
						status = concat(nvl2(status, status || '; ', ''),'Invalid COLL_OBJ_DISPOSITION "' || COLL_OBJ_DISPOSITION ||'"')
						where COLL_OBJ_DISPOSITION NOT IN (select COLL_OBJ_DISPOSITION from CTCOLL_OBJ_DISP) 
						OR coll_obj_disposition is null
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						AND key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableQC.key#">
					</cfquery>
					<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						update cf_temp_parts set 
						status = concat(nvl2(status, status || '; ', ''),'Missing CONDITION')
						where CONDITION is null
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						AND key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableQC.key#">
					</cfquery>
					<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						update cf_temp_parts set 
						status = concat(nvl2(status, status || '; ', ''),'Invalid lot_count_modifier "' || lot_count_modifier ||'"')
						where lot_count_modifier NOT IN (select modifier from ctnumeric_modifiers)
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						AND key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableQC.key#">
					</cfquery>
					<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						update cf_temp_parts set 
						status = concat(nvl2(status, status || '; ', ''),'Invalid lot_count "' || lot_count ||'"')
						where (LOT_COUNT is null OR is_number(lot_count) = 0)
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						AND key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableQC.key#">
					</cfquery>
		
					<cfloop index="i" from="1" to="6">
						<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						update cf_temp_parts set 
						status = concat(nvl2(status, status || '; ', ''),'<span class="font-weight-bold">Invalid  "'||PART_ATT_NAME_#i#||'"</span>')
						where PART_ATT_NAME_#i# not in (select attribute_type from CTSPECPART_ATTRIBUTE_TYPE)
						AND PART_ATT_NAME_#i# is not null
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						AND key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableQC.key#">
						</cfquery>
						<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						update cf_temp_parts set 
						status = concat(nvl2(status, status || '; ', ''),'Invalid PART_ATT_MADEDATE_#i# "'||PART_ATT_MADEDATE_#i#||'"') where is_iso8601(PART_ATT_MADEDATE_#i#) <> 'valid' and PART_ATT_MADEDATE_#i# is not null
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						AND key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableQC.key#">
						</cfquery>
						<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						update cf_temp_parts set 
						status = concat(nvl2(status, status || '; ', ''),'Scientific Name "'||PART_ATT_VAL_#i#||'" invalid') 
						where PART_ATT_NAME_#i# = 'scientific name'
						AND regexp_replace(PART_ATT_VAL_#i#, ' (\?|sp.)$', '') in
						(select scientific_name from taxonomy group by scientific_name having count(*) > 1)
						AND PART_ATT_VAL_#i# is not null
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						AND key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableQC.key#">
						</cfquery>
						<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						update cf_temp_parts set 
						status = status || 'scientific name (' ||PART_ATT_VAL_#i# ||') does not exist'
						where PART_ATT_NAME_#i# = 'scientific name'
						AND regexp_replace(PART_ATT_VAL_#i#, ' (\?|sp.)$', '') not in
						(select scientific_name from taxonomy group by scientific_name having count(*) = 1)
						AND PART_ATT_VAL_#i# is not null
						and (status not like '%;scientific name ('||PART_ATT_VAL_#i#||') matched multiple taxonomy records%' or status is null)
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						AND key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableQC.key#">
						</cfquery>
						<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						update cf_temp_parts set 
						status = status || '; scientific name cannot be null'
						where PART_ATT_NAME_#i# = 'scientific name' AND PART_ATT_VAL_#i# is null
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						AND key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableQC.key#">
						</cfquery>
						<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						update cf_temp_parts set
						status = concat(nvl2(status, status || '; ', ''),'<span class="font-weight-bold">Invalid "'||PART_ATT_DETBY_#i#||'". Name matched multiple agent names. </span>')
						where PART_ATT_DETBY_#i# in
						(select agent_name from agent_name group by agent_name having count(*) > 1)
						AND PART_ATT_DETBY_#i# is not null
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						AND key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableQC.key#">
						</cfquery>
						<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						update cf_temp_parts set 
						status = concat(nvl2(status, status || '; ', ''),'<span class="font-weight-bold">Invalid determiner. "'||PART_ATT_DETBY_#i#||'" does not match an agent name.</span>')
						where PART_ATT_DETBY_#i# not in
						(select agent_name from agent_name group by agent_name having count(*) = 1)
						and PART_ATT_DETBY_#i# is not null
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						AND key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableQC.key#">
						</cfquery>
						<cfquery name="sp_" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						update cf_temp_parts set 
						status = concat(nvl2(status, status || '; ', ''),'<span class="font-weight-bold">Invalid PART_ATT_NAME "'||PART_ATT_NAME_#i#||'" does not match MCZbase </span>')
						where PART_ATT_NAME_#i# not in (select attribute_type from ctspecpart_attribute_type) 
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						AND key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableQC.key#">
						</cfquery>
						<cfquery name="sp_val1" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						update cf_temp_parts set status = status || 'PART_ATT_VAL_#i# is not valid for attribute('||PART_ATT_NAME_#i#||')'
						where chk_att_codetables(PART_ATT_NAME_#i#,PART_ATT_VAL_#i#,COLLECTION_CDE)=0
						and PART_ATT_NAME_#i# in
						(select attribute_type from ctspecpart_attribute_type where value_code_tables is not null)
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						AND key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableQC.key#">
						</cfquery>
						<cfquery name="sp_units1" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						update cf_temp_parts set status = status || 'PART_ATT_UNITS_#i# is not valid for attribute('||PART_ATT_NAME_#i#||')'
						where chk_att_codetables(PART_ATT_NAME_#i#,PART_ATT_UNITS_#i#,COLLECTION_CDE)=0
						and PART_ATT_NAME_#i# in
						(select attribute_type from ctspecpart_attribute_type where unit_code_tables is not null)
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						AND key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableQC.key#">
						</cfquery>
						<cfquery name="sp_units2" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select unit_code_tables,attribute_type from CTSPECPART_ATTRIBUTE_TYPE
						where attribute_type = ('||PART_ATT_NAME_#i#||') 
						and CTSPECPART_ATTRIBUTE_TYPE.unit_code_tables is not null
						</cfquery>
						<cfif len(#sp_units2.unit_code_tables#) gt 0>
						<cfquery name="flatWrongUnits" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							UPDATE cf_temp_parts
							SET 
								status = concat(nvl2(status, status || '; ', ''),'Part attribute units not in controlled vocabulary')
							WHERE 
								'||PART_ATT_UNITS_#i#||' not in (
									<cfif sp_units2.unit_code_tables EQ "CTLENGTH_UNITS">
										select LENGTH_UNITS from CTLENGTH_UNITS
									<cfelseif sp_units2.unit_code_tables EQ "CTWEIGHT_UNITS">
										select WEIGHT_UNITS from CTWEIGHT_UNITS
									<cfelseif sp_units2.unit_code_tables EQ "CTNUMERIC_AGE_UNITS">
										select NUMERIC_AGE_UNITS from CTNUMERIC_AGE_UNITS
									<cfelseif sp_units2.unit_code_tables EQ "CTAREA_UNITS">
										select AREA_UNITS from CTAREA_UNITS
									<cfelseif sp_units2.units_code_tables EQ "CTTHICKNESS_UNITS">
										select THICKNESS_UNITS from CTTHICKNESS_UNITS
									<cfelseif sp_units2.unit_code_tables EQ "CTANGLE_UNITS">
										select LENGTH_UNITS from CTANGLE_UNITS
									<cfelseif sp_units2.unit_code_tables EQ "CTTISSUE_VOLUME_UNITS">
										select TISSUE_VOLUME_UNITS from CTTISSUE_VOLUME_UNITS
									
									</cfif>
								)
								AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
								AND key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableQC.key#">
						</cfquery>
						</cfif>
		<!---				<cfquery name="PAvalues" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						update cf_temp_parts set 
						status = status || ';PART_ATT_VAL_#i#  (' || PART_ATT_VAL_#i# || ') is invalid; requires value from codetable;'
						where PART_ATT_NAME_#i# not in
						(select attribute_type from ctspec_part_att_att where unit_code_table is not null)
						</cfquery>--->
							
	<!---					
						<cfloop query="sp_units">
						<cfquery name="flatWrongUnits" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							UPDATE cf_temp_parts
							SET 
								status = concat(nvl2(status, status || '; ', ''),'Part attribute units not in controlled vocabulary')
							WHERE 
								(' || PART_ATT_UNITS_#i# || ') not in (
									<cfif sp_units.unit_code_table EQ "CTLENGTH_UNITS">
										select LENGTH_UNITS from CTLENGTH_UNITS
									<cfelseif sp_units.unit_code_table EQ "CTWEIGHT_UNITS">
										select WEIGHT_UNITS from CTWEIGHT_UNITS
									<cfelseif sp_units.unit_code_table EQ "CTNUMERIC_AGE_UNITS">
										select NUMERIC_AGE_UNITS from CTNUMERIC_AGE_UNITS
									<cfelseif sp_units.unit_code_table EQ "CTAREA_UNITS">
										select AREA_UNITS from CTAREA_UNITS
									<cfelseif sp_units.unit_code_table EQ "CTTHICKNESS_UNITS">
										select THICKNESS_UNITS from CTTHICKNESS_UNITS
									<cfelseif sp_units.unit_code_table EQ "CTANGLE_UNITS">
								
										select LENGTH_UNITS from CTANGLE_UNITS
									<cfelseif sp_units.unit_code_table EQ "CTTISSUE_VOLUME_UNITS">
										select TISSUE_VOLUME_UNITS from CTTISSUE_VOLUME_UNITS
									</cfif>
								)
								AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
								AND key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableQC.key#">
						</cfquery>
						</cfloop>
						<cfquery name="flatWrongValue" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							UPDATE cf_temp_parts
							SET 
								status = concat(nvl2(status, status || '; ', ''),'PART_ATT_VAL_#i# not in controlled vocabulary #ctspec_part_att_att.attribute#')
							WHERE 
								attribute_value not in (
									<cfif ctspecpart_att_att.value_code_table EQ "CTCASTE">
										select caste from CTCASTE where cf_temp_parts.collection_cde = ctcaste.collection_cde
									<cfelseif ctspecpart_att_att.value_code_table EQ "CTPARTASSOCIATION">
										select partassociation from CTCASTE where cf_temp_parts.collection_cde = ctcaste.collection_cde
									<cfelseif ctspecpart_att_att.value_code_table EQ "CTAGE_CLASS">
										select age_class from CTAGE_CLASS where cf_temp_parts.collection_cde = ctage_class.collection_cde
									<cfelseif ctspecpart_att_att.value_code_table EQ "CTSEX_CDE">
										select sex_cde from CTSEX_CDE where cf_temp_parts.collection_cde = ctcaste.collection_cde
									</cfif>
								)
								AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
								AND key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableQC.key#">
						</cfquery>--->
					</cfloop>
					<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						update cf_temp_parts set (status) = (select decode(parent_container_id,0,'','')
						from specimen_part,coll_obj_cont_hist,container, coll_object_remark 
						where specimen_part.collection_object_id = coll_obj_cont_hist.collection_object_id AND
						coll_obj_cont_hist.container_id = container.container_id AND
						coll_object_remark.collection_object_id(+) = specimen_part.collection_object_id AND
						derived_from_cat_item = cf_temp_parts.collection_object_id AND
						cf_temp_parts.part_name=specimen_part.part_name AND
						cf_temp_parts.preserve_method=specimen_part.preserve_method AND
						nvl(cf_temp_parts.current_remarks, 'NULL') = nvl(coll_object_remark.coll_object_remarks, 'NULL')
						group by parent_container_id) where status=''
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						AND key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableQC.key#">
					</cfquery>
					<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						update cf_temp_parts set (parent_container_id) = (select container_id from container where
						barcode=container_unique_id) where status = ''
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						AND key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableQC.key#">
					</cfquery>
					<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						update cf_temp_parts set (use_part_id) = (
						select min(specimen_part.collection_object_id)
						from specimen_part, coll_object_remark where
						specimen_part.collection_object_id = coll_object_remark.collection_object_id(+) AND
						cf_temp_parts.part_name=specimen_part.part_name and
						cf_temp_parts.preserve_method=specimen_part.preserve_method and
						cf_temp_parts.collection_object_id=specimen_part.derived_from_cat_item and
						nvl(cf_temp_parts.current_remarks, 'NULL') = nvl(coll_object_remark.coll_object_remarks, 'NULL'))
						where status like '%NOTE: PART EXISTS%' AND use_existing = 1
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						AND key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableQC.key#">
					</cfquery>
				</cfloop>
						
				<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT *
					FROM cf_temp_parts
					WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
					ORDER BY key
				</cfquery>
				
				<cfquery name="allValid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select count(*) as cnt from cf_temp_parts
				</cfquery>
				<cfif #allValid.cnt# is 0>
					<span class="text-success">Validation checks passed</span>. Look over the table below and <a href="BulkloadNewParts.cfm?action=load">click to continue</a> if it all looks good. Or, <a href="/tools/BulkloadNewParts.cfm">Start over</a>.
				<cfelse>
					You must fix everything above to proceed. <a href="/tools/BulkloadNewParts.cfm">Try again.</a>
				</cfif>
				<table class='sortable w-100 small px-0 mx-0 table table-responsive table-striped'>
					<thead class="thead-light smaller">
						<tr>
							<th>BULKLOADING&nbsp;STATUS&nbsp;FOR&nbsp;NEW&nbsp;PARTS</th>
							<th>INSTITUTION_ACRONYM</th>
							<th>COLLECTION_CDE</th>
							<th>OTHER_ID_TYPE</th>
							<th>OTHER_ID_NUMBER</th>
							<th>PART_NAME</th>
							<th>PRESERVE_METHOD</th>
							<th>COLL_OBJ_DISPOSITION</th>
							<th>LOT_COUNT_MODIFIER</th>
							<th>LOT_COUNT</th>
							<th>CURRENT_REMARKS</th>
							<th>CONDITION</th>
							<th>CONTAINER_UNIQUE_ID</th>
							<th>PART_ATT_NAME_1</th>
							<th>PART_ATT_VAL_1</th>
							<th>PART_ATT_UNITS_1</th>
							<th>PART_ATT_DETBY_1</th>
							<th>PART_ATT_MADEDATE_1</th>
							<th>PART_ATT_REM_1</th>
							<th>PART_ATT_NAME_2</th>
							<th>PART_ATT_VAL_2</th>
							<th>PART_ATT_UNITS_2</th>
							<th>PART_ATT_DETBY_2</th>
							<th>PART_ATT_MADEDATE_2</th>
							<th>PART_ATT_REM_2</th>
							<th>PART_ATT_NAME_3</th>
							<th>PART_ATT_VAL_3</th>
							<th>PART_ATT_UNITS_3</th>
							<th>PART_ATT_DETBY_3</th>
							<th>PART_ATT_MADEDATE_3</th>
							<th>PART_ATT_REM_3</th>
							<th>PART_ATT_NAME_4</th>
							<th>PART_ATT_VAL_4</th>
							<th>PART_ATT_UNITS_4</th>
							<th>PART_ATT_DETBY_4</th>
							<th>PART_ATT_MADEDATE_4</th>
							<th>PART_ATT_REM_4</th>
							<th>PART_ATT_NAME_5</th>
							<th>PART_ATT_VAL_5</th>
							<th>PART_ATT_UNITS_5</th>
							<th>PART_ATT_DETBY_5</th>
							<th>PART_ATT_MADEDATE_5</th>
							<th>PART_ATT_REM_5</th>
							<th>PART_ATT_NAME_6</th>
							<th>PART_ATT_VAL_6</th>
							<th>PART_ATT_UNITS_6</th>
							<th>PART_ATT_DETBY_6</th>
							<th>PART_ATT_MADEDATE_6</th>
							<th>PART_ATT_REM_6</th>
						</tr>
					</thead>
					<tbody>
						<cfloop query="data">
							<tr>
								<td>#status#</td>
								<td>#institution_acronym#</td>
								<td>#collection_cde#</td>
								<td>#OTHER_ID_TYPE#</td>
								<td>#OTHER_ID_NUMBER#</td>
								<td>#part_name#</td>
								<td>#preserve_method#</td>
								<td>#coll_obj_disposition#</td>
								<td>#lot_count_modifier#</td>
								<td>#lot_count#</td>
								<td>#current_remarks#</td>
								<td>#condition#</td>
								<td>#container_unique_id#</td>
								<td>#part_att_name_1#</td>
								<td>#part_att_val_1#</td>
								<td>#part_att_units_1#</td>
								<td>#part_att_detby_1#</td>
								<td>#part_att_madedate_1#</td>
								<td>#part_att_rem_1#</td>
								<td>#part_att_name_2#</td>
								<td>#part_att_val_2#</td>
								<td>#part_att_units_2#</td>
								<td>#part_att_detby_2#</td>
								<td>#part_att_madedate_2#</td>
								<td>#part_att_rem_2#</td>
								<td>#part_att_name_3#</td>
								<td>#part_att_val_3#</td>
								<td>#part_att_units_3#</td>
								<td>#part_att_detby_3#</td>
								<td>#part_att_madedate_3#</td>
								<td>#part_att_rem_3#</td>
								<td>#part_att_name_4#</td>
								<td>#part_att_val_4#</td>
								<td>#part_att_units_4#</td>
								<td>#part_att_detby_4#</td>
								<td>#part_att_madedate_4#</td>
								<td>#part_att_rem_4#</td>
								<td>#part_att_name_5#</td>
								<td>#part_att_val_5#</td>
								<td>#part_att_units_5#</td>
								<td>#part_att_detby_5#</td>
								<td>#part_att_madedate_5#</td>
								<td>#part_att_rem_5#</td>
								<td>#part_att_name_6#</td>
								<td>#part_att_val_6#</td>
								<td>#part_att_units_6#</td>
								<td>#part_att_detby_6#</td>
								<td>#part_att_madedate_6#</td>
								<td>#part_att_rem_6#</td>
							</tr>
						</cfloop>
					</tbody>
				</table>
			</cfoutput>
		</cfif>
			<!-------------------------------------------------------------------------------------------->
			<cfif #action# is "load">
			<cfoutput>
				<cfquery name="getTempData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select * from cf_temp_parts where status not in ('') or status is null
				</cfquery>
				<cfquery name= "getEntBy" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT agent_id FROM agent_name WHERE agent_name = '#session.username#'
				</cfquery>
				<cfif getEntBy.recordcount is 0>
					<cfabort showerror = "You aren't a recognized agent!">
				<cfelseif getEntBy.recordcount gt 1>
					<cfabort showerror = "Your login has has multiple matches.">
				</cfif>
				<cfset enteredbyid = getEntBy.agent_id>
				<cftransaction>
				<cfloop query="getTempData">
				<cfif len(#use_part_id#) is 0>
					<cfquery name="NEXTID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select sq_collection_object_id.nextval NEXTID from dual
					</cfquery>
					<cfquery name="updateColl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						INSERT INTO coll_object (
							COLLECTION_OBJECT_ID,
							COLL_OBJECT_TYPE,
							ENTERED_PERSON_ID,
							COLL_OBJECT_ENTERED_DATE,
							LAST_EDITED_PERSON_ID,
							COLL_OBJ_DISPOSITION,
							LOT_COUNT_MODIFIER,
							LOT_COUNT,
							CONDITION,
							FLAGS )
						VALUES (
							#NEXTID.NEXTID#,
							'SP',
							#enteredbyid#,
							sysdate,
							#enteredbyid#,
							'#COLL_OBJ_DISPOSITION#',
							'#lot_count_modifier#',
							#lot_count#,
							'#condition#',
							0 )
					</cfquery>
					<cfquery name="newTiss" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						INSERT INTO specimen_part (
							  COLLECTION_OBJECT_ID,
							  PART_NAME,
							  PRESERVE_METHOD,
							  DERIVED_FROM_cat_item )
							VALUES (
								#NEXTID.NEXTID#,
							  '#PART_NAME#',
							  '#PRESERVE_METHOD#'
								,#collection_object_id# )
					</cfquery>
					<cfif len(#current_remarks#) gt 0>
							<!---- new remark --->
							<cfquery name="newCollRem" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
								INSERT INTO coll_object_remark (collection_object_id, coll_object_remarks)
								VALUES (sq_collection_object_id.currval, '#current_remarks#')
							</cfquery>
					</cfif>
					<cfif len(#changed_date#) gt 0>
						<cfquery name="change_date" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							update SPECIMEN_PART_PRES_HIST set CHANGED_DATE = to_date('#CHANGED_DATE#', 'YYYY-MM-DD') where collection_object_id =#NEXTID.NEXTID# and is_current_fg = 1
						</cfquery>
					</cfif>
					<cfif len(#container_unique_id#) gt 0>
						<cfquery name="part_container_id" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							select container_id from coll_obj_cont_hist where collection_object_id = #NEXTID.NEXTID#
						</cfquery>
							<cfquery name="upPart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
								update container set parent_container_id=#parent_container_id#
								where container_id = #part_container_id.container_id#
							</cfquery>
						<cfif #len(change_container_type)# gt 0>
							<cfquery name="upPart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
								update container set
								container_type='#change_container_type#'
								where container_id=#parent_container_id#
							</cfquery>
						</cfif>
					</cfif>

					<cfif len(#part_att_name_1#) GT 0>
						<cfif len(#part_att_detby_1#) GT 0>
							<cfquery name="a" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
								select agent_id from agent_name where agent_name = trim('#part_att_detby_1#')
							</cfquery>
							<cfset numAgentID = a.agent_id>
						<cfelse>
							<cfset  numAgentID = "NULL">
						</cfif>
						<cfquery name="addPartAtt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							insert into SPECIMEN_PART_ATTRIBUTE(collection_object_id, attribute_type, attribute_value, attribute_units, determined_date, determined_by_agent_id, attribute_remark)
							values(sq_collection_object_id.currval, '#part_att_name_1#', '#part_att_val_1#', '#part_att_units_1#', '#part_att_madedate_1#', #numAgentId#, '#part_att_rem_1#')
						</cfquery>
					</cfif>
					<cfif len(#part_att_name_2#) GT 0>
						<cfif len(#part_att_detby_2#) GT 0>
							<cfquery name="a" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
								select agent_id from agent_name where agent_name = trim('#part_att_detby_2#')
							</cfquery>
							<cfset numAgentID = a.agent_id>
						<cfelse>
							<cfset  numAgentID = "NULL">
						</cfif>
						<cfquery name="addPartAtt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							insert into SPECIMEN_PART_ATTRIBUTE(collection_object_id, attribute_type, attribute_value, attribute_units, determined_date, determined_by_agent_id, attribute_remark)
							values(sq_collection_object_id.currval, '#part_att_name_2#', '#part_att_val_2#', '#part_att_units_2#', '#part_att_madedate_2#', #numAgentId#, '#part_att_rem_2#')
						</cfquery>
					</cfif>
					<cfif len(#part_att_name_3#) GT 0>
						<cfif len(#part_att_detby_3#) GT 0>
							<cfquery name="a" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
								select agent_id from agent_name where agent_name = trim('#part_att_detby_3#')
							</cfquery>
							<cfset numAgentID = a.agent_id>
						<cfelse>
							<cfset  numAgentID = "NULL">
						</cfif>
						<cfquery name="addPartAtt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							insert into SPECIMEN_PART_ATTRIBUTE(collection_object_id, attribute_type, attribute_value, attribute_units, determined_date, determined_by_agent_id, attribute_remark)
							values(sq_collection_object_id.currval, '#part_att_name_3#', '#part_att_val_3#', '#part_att_units_3#', '#part_att_madedate_3#', #numAgentId#, '#part_att_rem_3#')
						</cfquery>
					</cfif>
					<cfif len(#part_att_name_4#) GT 0>
						<cfif len(#part_att_detby_4#) GT 0>
							<cfquery name="a" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
								select agent_id from agent_name where agent_name = trim('#part_att_detby_4#')
							</cfquery>
							<cfset numAgentID = a.agent_id>
						<cfelse>
							<cfset  numAgentID = "NULL">
						</cfif>
						<cfquery name="addPartAtt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							insert into SPECIMEN_PART_ATTRIBUTE(collection_object_id, attribute_type, attribute_value, attribute_units, determined_date, determined_by_agent_id, attribute_remark)
							values(sq_collection_object_id.currval, '#part_att_name_4#', '#part_att_val_4#', '#part_att_units_4#', '#part_att_madedate_4#', #numAgentId#, '#part_att_rem_4#')
						</cfquery>
					</cfif>
					<cfif len(#part_att_name_5#) GT 0>
						<cfif len(#part_att_detby_5#) GT 0>
							<cfquery name="a" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
								select agent_id from agent_name where agent_name = trim('#part_att_detby_5#')
							</cfquery>
							<cfset numAgentID = a.agent_id>
						<cfelse>
							<cfset  numAgentID = "NULL">
						</cfif>
						<cfquery name="addPartAtt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							insert into SPECIMEN_PART_ATTRIBUTE(collection_object_id, attribute_type, attribute_value, attribute_units, determined_date, determined_by_agent_id, attribute_remark)
							values(sq_collection_object_id.currval, '#part_att_name_5#', '#part_att_val_5#', '#part_att_units_5#', '#part_att_madedate_5#', #numAgentId#, '#part_att_rem_5#')
						</cfquery>
					</cfif>
					<cfif len(#part_att_name_6#) GT 0>
						<cfif len(#part_att_detby_6#) GT 0>
							<cfquery name="a" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
								select agent_id from agent_name where agent_name = trim('#part_att_detby_6#')
							</cfquery>
							<cfset numAgentID = a.agent_id>
						<cfelse>
							<cfset  numAgentID = "NULL">
						</cfif>
						<cfquery name="addPartAtt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							insert into SPECIMEN_PART_ATTRIBUTE(collection_object_id, attribute_type, attribute_value, attribute_units, determined_date, determined_by_agent_id, attribute_remark)
							values(sq_collection_object_id.currval, '#part_att_name_6#', '#part_att_val_6#', '#part_att_units_6#', '#part_att_madedate_6#', #numAgentId#, '#part_att_rem_6#')
						</cfquery>
					</cfif>

				<cfelse>
				<!--- there is an existing matching container that is not in a parent_container;
					all we need to do is move the container to a parent IF it exists and is specified, or nothing otherwise --->
					<cfif len(#coll_obj_disposition#) gt 0>
						<cfquery name="upDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							update coll_object set COLL_OBJ_DISPOSITION = '#disposition#' where collection_object_id = #use_part_id#
						</cfquery>
					</cfif>
					<cfif len(#condition#) gt 0>
						<cfquery name="upCond" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							update coll_object set condition = '#condition#' where collection_object_id = #use_part_id#
						</cfquery>
					</cfif>
					<cfif len(#lot_count#) gt 0>
						<cfquery name="upCond" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							update coll_object set lot_count = #lot_count#, lot_count_modifier='#lot_count_modifier#' where collection_object_id = #use_part_id#
						</cfquery>
					</cfif>
					<cfif len(#new_preserve_method#) gt 0>
						<cfquery name="change_preservemethod" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							update SPECIMEN_PART set PRESERVE_METHOD = '#NEW_PRESERVE_METHOD#' where collection_object_id =#use_part_id#
						</cfquery>
					</cfif>
					<cfif len(#append_to_remarks#) gt 0>
						<cfquery name="remarksCount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							select * from coll_object_remark where collection_object_id = #use_part_id#
						</cfquery>
						<cfif remarksCount.recordcount is 0>
							<cfquery name="insertRemarks" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
								INSERT INTO coll_object_remark (collection_object_id, coll_object_remarks)
								VALUES (#use_part_id#, '#append_to_remarks#')
							</cfquery>
						<cfelse>
							<cfquery name="updateRemarks" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
								update coll_object_remark
								set coll_object_remarks = DECODE(coll_object_remarks, null, '#append_to_remarks#', coll_object_remarks || '; #append_to_remarks#')
								where collection_object_id = #use_part_id#
							</cfquery>
						</cfif>
					</cfif>
					<cfif len(#container_unique_id#) gt 0>
						<cfquery name="part_container_id" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							select container_id from coll_obj_cont_hist where collection_object_id = #use_part_id#
						</cfquery>
							<cfquery name="upPart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
								update container set parent_container_id=#parent_container_id#
								where container_id = #part_container_id.container_id#
							</cfquery>
						<cfif #len(change_container_type)# gt 0>
							<cfquery name="upPart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
								update container set
								container_type='#change_container_type#'
								where container_id=#parent_container_id#
							</cfquery>
						</cfif>
					</cfif>
					<cfif len(#changed_date#) gt 0>
						<cfquery name="change_date" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							update SPECIMEN_PART_PRES_HIST set CHANGED_DATE = to_date('#CHANGED_DATE#', 'YYYY-MM-DD') where collection_object_id =#use_part_id# and is_current_fg = 1
						</cfquery>
					</cfif>
				</cfif>
				<cfquery name="upLoaded" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					update cf_temp_parts set status = ''
				</cfquery>
				</cfloop>
				</cftransaction>
				<!---insert collection_object_ids into link with a comma between them--->
				Parts loaded.
				<a href="/Specimens.cfm?execute=true&builderMaxRows=1&action=builderSearch&nestdepth1=1&field1=COLL_OBJECT%3ACOLL_OBJ_COLLECTION_OBJECT_ID&searchText1=<cfloop query='getTempData'>#getTempData.collection_object_id#,</cfloop>" target="_blank">
					See in Specimen Results
				</a><br>
			</cfoutput>
		</cfif>
		</div>
	</div>
</main>
<cfinclude template="/shared/_footer.cfm">