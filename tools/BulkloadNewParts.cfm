<!--- tools/bulkloadNewParts.cfm add parts to specimens in bulk.

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
<cfset NUM_PART_ATTRIBUTE_PAIRS = 6>

<cfif isDefined("action") AND action is "dumpProblems">
	<cfquery name="getProblemData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		SELECT 
			status, 
			institution_acronym, collection_cde, other_id_type, other_id_number, collection_object_id,
			part_name, preserve_method, coll_obj_disposition, condition, lot_count, lot_count_modifier, 
			part_remarks, container_unique_id
			<cfloop index="i" from="1" to="#NUM_PART_ATTRIBUTE_PAIRS#">
				,part_att_name_#i#, part_att_val_#i#, part_att_units_#i#, part_att_detby_#i#, part_att_madedate_#i#, part_att_rem_#i#
			</cfloop>
		FROM cf_temp_parts
		WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
		ORDER BY key
	</cfquery>
	<cfinclude template="/shared/component/functions.cfc"><!---need to add to functions.cfc page--->
	<cfset csv = queryToCSV(getProblemData)>
	<cfheader name="Content-Type" value="text/csv">
	<cfoutput>#csv#</cfoutput>
	<cfabort>
</cfif>

<cfset fieldlist = "INSTITUTION_ACRONYM,COLLECTION_CDE,OTHER_ID_TYPE,OTHER_ID_NUMBER,CONTAINER_UNIQUE_ID,PART_NAME,PRESERVE_METHOD,LOT_COUNT_MODIFIER,LOT_COUNT,CONDITION,COLL_OBJ_DISPOSITION,PART_REMARKS,PART_ATT_NAME_1,PART_ATT_VAL_1,PART_ATT_UNITS_1,PART_ATT_DETBY_1,PART_ATT_MADEDATE_1,PART_ATT_REM_1,PART_ATT_NAME_2,PART_ATT_VAL_2,PART_ATT_UNITS_2,PART_ATT_DETBY_2,PART_ATT_MADEDATE_2,PART_ATT_REM_2,PART_ATT_NAME_3,PART_ATT_VAL_3,PART_ATT_UNITS_3,PART_ATT_DETBY_3,PART_ATT_MADEDATE_3,PART_ATT_REM_3,PART_ATT_NAME_4,PART_ATT_VAL_4,PART_ATT_UNITS_4,PART_ATT_DETBY_4,PART_ATT_MADEDATE_4,PART_ATT_REM_4,PART_ATT_NAME_5,PART_ATT_VAL_5,PART_ATT_UNITS_5,PART_ATT_DETBY_5,PART_ATT_MADEDATE_5,PART_ATT_REM_5,PART_ATT_NAME_6,PART_ATT_VAL_6,PART_ATT_UNITS_6,PART_ATT_DETBY_6,PART_ATT_MADEDATE_6,PART_ATT_REM_6">
<cfset fieldTypes ="CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_DATE,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_DATE,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_DATE,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_DATE,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_DATE,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_DATE,CF_SQL_VARCHAR">
<cfif listlen(fieldlist) NEQ listlen(fieldTypes)>
	<cfthrow message = "Error: Bug in the definition of fieldlist[#listlen(fieldlist)#] and fieldType[#listlen(fieldTypes)#] lists, lists must be the same length, but are not.">
</cfif>
<cfset requiredfieldlist = "INSTITUTION_ACRONYM,COLLECTION_CDE,OTHER_ID_TYPE,OTHER_ID_NUMBER,PART_NAME,PRESERVE_METHOD,LOT_COUNT,CONDITION,COLL_OBJ_DISPOSITION">

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
<cfinclude template="/tools/component/csv.cfc" runOnce="true"><!--- for common csv testing functions --->
<cfif not isDefined("action") OR len(action) EQ 0><cfset action="nothing"></cfif>
<main class="container-fluid px-xl-5 py-3" id="content">
	<h1 class="h2 mt-2">Bulkload New Parts </h1>
	<!------------------------------------------------------->
	<cfif #action# is "nothing">
		<cfoutput>
			<p>This tool adds part rows to the specimen record. It creates metadata for part history and includes specimen part attributes fields (that can be empty). The cataloged items must be in the database and they can be entered using the catalog number or other ID. Error messages will appear if the values need to match values in MCZbase. It alerts you if columns are missing. Additional columns will be ignored. Include column headings, spelled exactly as below. </p>
			<h2 class="h4">Use Template to Load Data</h2>
			<button class="btn btn-xs btn-primary float-left mr-3" id="copyButton">Copy Column Headers</button>
			<div id="template" class="my-1 mx-0">
				<label for="templatearea" class="data-entry-label" style="line-height: inherit;">
					Copy this header line, paste it into a blank worksheet, and save it as a .csv file or <a href="/tools/BulkloadNewParts.cfm?action=getCSVHeader" class="font-weight-bold">download</a> a template.
				</label>
				<textarea style="height: 61px;" cols="90" id="templatearea" class="mb-1 w-100 data-entry-textarea small">#fieldlist#</textarea>
			</div>
			<div class="accordion" id="accordionID">
				<div class="card mb-2 bg-light">
					<div class="card-header" id="headingID">
						<h3 class="h5 my-0">
							<button type="button" role="button" aria-label="parts pane" class="headerLnk text-left w-100" data-toggle="collapse" data-target="##IDPane" aria-expanded="false" aria-controls="IDPane">
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
											and table_name = 'CF_TEMP_PARTS'
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
		<cfif #action# is "getFile">
				<cfoutput>
					<h2 class="h4">First step: Reading data from CSV file.</h2>
					<!--- Compare the numbers of headers expected against provided in CSV file --->
					<!--- Set some constants to identify error cases in cfcatch block --->
					<cfset NO_COLUMN_ERR = "<p>One or more required fields are missing in the header line of the csv file. <br>Missing fields: </p>">
					<cfset DUP_COLUMN_ERR = "<p>One or more columns are duplicated in the header line of the csv file.<p>">
					<cfset COLUMN_ERR = "Error inserting data ">
					<cfset NO_HEADER_ERR = "<p>No header line found, csv file appears to be empty.</p>">
					<cfset TABLE_NAME = "CF_TEMP_PARTS"><!--- " --->
					<cftry>
						<!--- cleanup any incomplete work by the same user --->
						<cfquery name="clearTempTable" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="clearTempTable_result">
							DELETE FROM cf_temp_parts 
							WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						</cfquery>
						<cfset variables.foundHeaders =""><!--- populated by loadCsvFile --->
						<cfset variables.size=""><!--- populated by loadCsvFile --->
						<cfset iterator = loadCsvFile(FileToUpload=FileToUpload,format=format,characterSet=characterSet)>			

						<!--- Note: As we can't use csvFormat.withHeader(), we can not match columns by name, we are forced to do so by number, thus arrays --->
						<cfset colNameArray = listToArray(ucase(variables.foundHeaders))><!--- the list of columns/fields found in the input file --->
						<cfset fieldArray = listToArray(ucase(fieldlist))><!--- the full list of fields --->
						<cfset typeArray = listToArray(fieldTypes)><!--- the types for the full list of fields --->
						<div class="col-12 my-3 px-0">
							<h3>Found #variables.size# column headers in the CSV file.</h3>
							There are #ListLen(fieldList)# columns expected in the header (of these, #ListLen(requiredFieldList)# are <span class="text-danger">required</span>).
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
							<!---Construct insert for rows if column header is in fieldlist, otherwise use null--->
							<!---We cannot use csvFormat.withHeader() or match columns by name, so we are forced to match by number, use arrays--->
								<cfquery name="insert" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="insert_result">
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
									<cfset error_message="#COLUMN_ERR# from line #row# in input file.">
									<cfset error_message = "#error_message# <div class='mb-2 h4 font-weight-normal align-items-start align-items list-group list-group-horizontal flex-wrap col-12 small'> Header:[#colNames#] </div>"><!--- " --->
									<cfset error_message = "#error_message# <div class='mb-2 h4 font-weight-normal align-items-start align-items list-group list-group-horizontal flex-wrap col-12 small'> Row:[#ArrayToList(collValuesArray)#] </div>"><!--- " --->
									<cfset error_message = "#error_message# Error: #cfcatch.message#">
									<cfif isDefined("cfcatch.queryError")>
										<cfset error_message = "#error_message# #cfcatch.queryError#">
									</cfif>
									<cfthrow message = "#error_message#">
								</cfcatch>
							</cftry>
						</cfloop>
						<cfif foundHighCount GT 0>
							<cfif foundHighCount GT 1><cfset plural="s"><cfelse><cfset plural=""></cfif>
							<h3>Found characters where the encoding is probably important in the input data.</h3>
							<div>
								<p>Showing #foundHighCount# example#plural#.  If these do not appear as the correct characters, the file likely has a different encoding from the one you selected and
								you probably want to <strong><a href="/tools/BulkloadNewParts.cfm" class="text-danger">start again</a></strong> this file selecting a different encoding.  If these appear as expected, then 
									you selected the correct encoding and can continue to validate or load.</p>
							</div>
							<ul class="pb-1 h4 list-unstyled px-3 mx-3">
								#foundHighAscii# #foundMultiByte#
							</ul>
						</cfif>
						<h3>
							<cfif loadedRows EQ 0>
								Loaded no rows from the CSV file.  The file appears to be just a header with no data. Fix file and <a href="/tools/BulkloadNewParts.cfm" class="text-danger">start again</a>
							<cfelse>
								Successfully read #loadedRows# records from the CSV file.  Next <a href="/tools/BulkloadNewParts.cfm?action=validate" class="font-weight-lessbold btn-link">click to validate</a> or <strong><a href="/tools/BulkloadNewParts.cfm" class="text-danger">start again</a></strong>.
							</cfif>
						</h3>
						<cfcatch>
							<h3>
								Failed to read the CSV file.  Fix the errors in the file and <a href="/tools/BulkloadNewParts.cfm" class="text-danger">start again</a>.
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
									<h3>Found characters with unexpected encoding in the header row.  This is probably the cause of your error.</h3>
									<div>
										Showing #foundHighCount# examples. Did you select utf-16 or unicode for the encoding for a file that does not have multibyte encoding?
									</div>
									<ul class="pb-1 h4 list-unstyled mx-3 px-3">
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
								<ul class="py-1 h4 list-unstyled mx-3 px-3">
									<li>Unable to read headers in line 1.  Did you select CSV format for a tab delimited file?</li>
								</ul>
							<cfelseif Find("IOException reading next record: java.io.IOException: (line 1)",cfcatch.message) GT 0>
								<ul class="py-1 h4 list-unstyled mx-3 px-3">
									<cfif format EQ "DEFAULT"><cfset fmt="CSV: Default Comma Separated values"><cfelse><cfset fmt="#format#"></cfif>
									<li>Unable to read headers in line 1.  Is your file actually have the format #fmt#?</li>
									<li>#cfcatch.message#</li>
								</ul>
							<cfelseif Find("IOException reading next record: java.io.IOException:",cfcatch.message) GT 0>
								<ul class="py-1 h4 list-unstyled px-3 mx-3">
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
			<cfquery name="getTempTableTypes" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
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
					<cfquery name="getCID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						UPDATE
							cf_temp_parts
						SET
							collection_object_id = (
								select collection_object_id 
								from cataloged_item 
								where cat_num = cf_temp_parts.other_id_number 
								and collection_cde = cf_temp_parts.collection_cde
								and institution_acronym = 'MCZ'
							),
							status = null
						WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
							and key = <cfqueryparam cfsqltype="CF_SQL_decimal" value="#getTempTableTypes.key#"> 
					</cfquery>
				<cfelse>
					<!--- or on specified other identifier --->
					<cfquery name="getCID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						UPDATE
							cf_temp_parts
						SET
							collection_object_id= (
								select cataloged_item.collection_object_id from cataloged_item,coll_obj_other_id_num 
								where coll_obj_other_id_num.other_id_type = cf_temp_parts.other_id_type 
								and cataloged_item.collection_cde = cf_temp_parts.collection_cde 
								and display_value= cf_temp_parts.other_id_number
								and cataloged_item.collection_object_id = coll_obj_other_id_num.COLLECTION_OBJECT_ID
								and institution_acronym = 'MCZ'
							),
							status = null
						WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
							and key = <cfqueryparam cfsqltype="CF_SQL_decimal" value="#getTempTableTypes.key#"> 
					</cfquery>
				</cfif>
				<cfset i= i+1>
			</cfloop>
			<!--- QC Checks that can be performed in bulk --->
			<cfloop list="#requiredfieldlist#" item="field">
				<cfquery name="requiredFields" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE cf_temp_parts 
					SET status = concat(nvl2(status, status || '; ', ''),'Required field #field# is empty')
					WHERE
						( 
							#field# IS NULL
							OR (trim(#field#) IS NULL)
						)
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
			</cfloop>
			<cfquery name="badPartName" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE cf_temp_parts 
				SET status = concat(nvl2(status, status || '; ', ''),'Invalid part_name')
				WHERE part_name|| '|' ||collection_cde NOT IN (
					select part_name|| '|' ||collection_cde from ctspecimen_part_name
					)
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="badPreserveMethod" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE cf_temp_parts 
				SET status = concat(nvl2(status, status || '; ', ''),'Invalid preserve_method')
				WHERE 
					( 
						preserve_method|| '|' ||collection_cde NOT IN 
						(
							select preserve_method|| '|' ||collection_cde from ctspecimen_preserv_method
						)
						OR preserve_method is null
					)
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="badContainer" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE cf_temp_parts 
				SET status = concat(nvl2(status, status || '; ', ''),'Invalid container_unique_id')
				WHERE 
					container_unique_id NOT IN (
						select barcode from container where barcode is not null
					)
					AND container_unique_id is not null
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="badDisposition" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE cf_temp_parts 
				SET status = concat(nvl2(status, status || '; ', ''),'Invalid COLL_OBJ_DISPOSITION')
				WHERE 
					COLL_OBJ_DISPOSITION NOT IN (
						select COLL_OBJ_DISPOSITION from CTCOLL_OBJ_DISP
					)
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="emptyCondition" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE cf_temp_parts set 
				STATUS = concat(nvl2(status, status || '; ', ''),'CONDITION must have a value')
				WHERE CONDITION is null
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="badLotCountModifier" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE cf_temp_parts 
				SET status = concat(nvl2(status, status || '; ', ''),'invalid lot_count_modifier')
				WHERE 
					lot_count_modifier NOT IN (
						select modifier from ctnumeric_modifiers
					)
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="emptyLotCount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE cf_temp_parts 
				SET status = concat(nvl2(status, status || '; ', ''),'Invalid LOT_COUNT, must be a number.')
				WHERE 
					(
						LOT_COUNT is null 
						OR
						is_number(lot_count) = 0
					)
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<!--- Loop through part attribute key:value pairs  --->
			<cfloop index="i" from="1" to="#NUM_PART_ATTRIBUTE_PAIRS#">
				<cfquery name="chkPAttType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE cf_temp_parts 
					SET status = concat(nvl2(status, status || '; ', ''),'Invalid part attribute name ['||PART_ATT_NAME_#i#||']')
					WHERE 
						PART_ATT_NAME_#i# not in (select attribute_type from CTSPECPART_ATTRIBUTE_TYPE) 
						AND PART_ATT_NAME_#i# is not null
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>	
				<cfquery name="chkPAttPair" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE cf_temp_parts 
					SET status = concat(nvl2(status, status || '; ', ''),'"'||PART_ATT_VAL_#i#||'" is required when '||PART_ATT_NAME_#i#||' has a value')
					WHERE 
						PART_ATT_NAME_#i# IS NOT NULL 
						AND PART_ATT_VAL_#i# IS NULL
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cfquery name="chkPAttPair1" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE cf_temp_parts 
					SET status = concat(nvl2(status, status || '; ', ''),'"'||PART_ATT_NAME_#i#||'" is required when '||PART_ATT_VAL_#i#||' has a value')
					WHERE 
						PART_ATT_NAME_#i# IS NULL 
						AND PART_ATT_VAL_#i# IS NOT NULL
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cfquery name="chkPAttDate" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE cf_temp_parts 
					SET status = concat(nvl2(status, status || '; ', ''),'Invalid PART_ATT_MADEDATE_#i# "'||PART_ATT_MADEDATE_#i#||'"') 
					WHERE PART_ATT_NAME_#i# is not null 
							AND is_iso8601(PART_ATT_MADEDATE_#i#) <> '' 
							AND length(PART_ATT_MADEDATE_#i#) <> 10
							AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cfquery name="chkPAtt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE cf_temp_parts 
					SET status = concat(nvl2(status, status || '; ', ''),'Invalid part attribute determiner ['||PART_ATT_DETBY_#i#||'], must be preferred name.')
					WHERE 
						PART_ATT_DETBY_#i# not in (select agent_name from preferred_agent_name where PART_ATT_DETBY_#i# = preferred_agent_name.agent_name)
						AND PART_ATT_NAME_#i# is not null
						AND PART_ATT_DETBY_#i# is not null
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
			</cfloop>

			<!--- obtain the information needed to QC each row --->
			<cfquery name="getTempTableQC" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT 
					collection_object_id,collection_cde,key
				FROM 
					cf_temp_parts
				WHERE 
					username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<!---Loop through the temp part data and validate against code tables and requirements--->
			<cfloop query="getTempTableQC">
				<cfquery name="getParentContainerId" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					update cf_temp_parts set parent_container_id =
					(select container_id from container where container.barcode = cf_temp_parts.container_unique_id)
					WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
					AND key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableQC.key#">
				</cfquery>
				<cfquery name="validateGotParent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					update cf_temp_parts set status = concat(nvl2(status, status || '; ', ''),'Container Unique ID not found')
					where container_unique_id is not null and parent_container_id is null
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
					AND key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableQC.key#">
				</cfquery>

				<cfloop index="i" from="1" to="#NUM_PART_ATTRIBUTE_PAIRS#">
					<!--- TODO: Query is broken --->	
					<!--- find the unit and code value tables for attributes --->
					<cfquery name="findCodeTables" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						SELECT
								cf_temp_parts.part_att_name_#i# as partAttName,
								cf_temp_parts.part_att_val_#i# as partAttVal,
								cf_temp_parts.collection_cde as partAttCollCde,
								ctspec_part_att_att.attribute_type,
								decode(value_code_table, null, unit_code_table,value_code_table) code_table 
							FROM 
								cf_temp_parts 
								join ctspec_part_att_att on cf_temp_parts.part_att_name_#i# = ctspec_part_att_att.attribute_type
							WHERE
								cf_temp_parts.part_att_val_#i# is not null
								AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
								AND key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableQC.key#">
					</cfquery>
					<cfloop query="findCodeTables">
						<cfif len('#findCodeTables.partAttName#') GT 0 AND 
								len('#findCodeTables.partAttVal#') GT 0 AND 
								len('#findCodeTables.code_table#') EQ 0>
							<cfquery name="chkPAtt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
								UPDATE cf_temp_parts 
								SET status = concat(nvl2(status, status || '; ', ''),'part attribute value [#findCodeTables.partAttVal#] not in codetable #findCodeTAbles.code_table#')
								WHERE 
									chk_specpart_att_codetables('#findCodeTables.partAttName#','#findCodeTables.partAttVal#','#findCodeTables.partAttCollCde#')=0
									AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
									AND key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableQC.key#">
							</cfquery>
						</cfif>
					</cfloop>
					<!---TODO: ABOVE. Fix type/value/units relationship check (chk_specpart_att_codetable)--->

					<cfquery name="chkSciName" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						UPDATE cf_temp_parts 
						SET status = concat(nvl2(status, status || '; ', ''),'Invalid scientific name ['||PART_ATT_VAL_#i#||']') 
						WHERE 
							PART_ATT_NAME_#i# = 'scientific name'
							AND regexp_replace(PART_ATT_VAL_#i#, ' (\?|sp.)$', '') NOT in
								(select scientific_name from taxonomy)
							AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
							AND key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableQC.key#">
					</cfquery>

					<cfquery name="chkPAttUnit" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						UPDATE cf_temp_parts 
						SET status = concat(nvl2(status, status || '; ', ''), 'PART_ATT_UNITS_#i# is not valid for attribute "'||PART_ATT_NAME_#i#||'". See code table.')
						WHERE 
							MCZBASE.CHK_SPECPART_ATT_CODETABLES(PART_ATT_NAME_#i#,PART_ATT_UNITS_#i#,COLLECTION_CDE)=0
							AND PART_ATT_NAME_#i# in
								(select attribute_type from ctspec_part_att_att where unit_code_table is not null)
							AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
							AND key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableQC.key#">
					</cfquery>
				</cfloop>
				<cfquery name="chk" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE cf_temp_parts 
					SET status = (
						SELECT decode(parent_container_id,0,'','')
						FROM specimen_part,coll_obj_cont_hist,container, coll_object_remark 
						WHERE specimen_part.collection_object_id = coll_obj_cont_hist.collection_object_id AND
							coll_obj_cont_hist.container_id = container.container_id AND
							coll_object_remark.collection_object_id(+) = specimen_part.collection_object_id AND
							derived_from_cat_item = cf_temp_parts.collection_object_id AND
							cf_temp_parts.part_name=specimen_part.part_name AND
							cf_temp_parts.preserve_method=specimen_part.preserve_method AND
							nvl(cf_temp_parts.part_remarks, 'NULL') = nvl(coll_object_remark.coll_object_remarks, 'NULL')
						GROUP BY parent_container_id
					) 
					WHERE status IS NULL
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						AND key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableQC.key#">
				</cfquery>
				<cfquery name="setParentContainer" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE cf_temp_parts 
					SET (parent_container_id) = (
						select container_id
						from container 
						where barcode=container_unique_id
					)
					WHERE status IS NULL
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
					AND key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableQC.key#">
				</cfquery>
			</cfloop>
			<cfquery name="markNoPart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE cf_temp_parts 
				SET status = concat(nvl2(status, status || '; ', ''),'Cataloged item not found.') 
				WHERE collection_object_id IS NULL
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<!--- Refresh data from cf_temp_parts --->
			<cfquery name="getTempDataToShow" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT *
				FROM cf_temp_parts
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				ORDER BY key
			</cfquery>
			<cfquery name="countFailures" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT count(*) as cnt 
				from cf_temp_parts
				WHERE 
					status IS NOT NULL
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<h3 class="mt-3">
				<cfif #countFailures.cnt# is 0>
					<span class="text-success">Validation checks passed</span>. Look over the table below and <a href="BulkloadNewParts.cfm?action=load" class="font-weight-lessbold btn-link">click to continue</a> if it all looks good. Or, <a href="/tools/BulkloadNewParts.cfm" class="text-danger">start again</a>.
				<cfelse>
					There is a problem with #countFailures.cnt# of #getTempDataToShow.recordcount# row(s). See the STATUS column. (<a href="/tools/BulkloadNewParts.cfm?action=dumpProblems">download</a>).
					Fix the problem(s) noted in the status column and <a href="/tools/BulkloadNewParts.cfm" class="text-danger">start again</a>.
				</cfif>
			</h3>
				<table class='sortable w-100 small px-0 mx-0 table table-responsive table-striped'>
					<thead class="thead-light small">
						<tr>
							<th>BULKLOADING&nbsp;STATUS</th>
							<th>INSTITUTION_ACRONYM</th>
							<th>COLLECTION_CDE</th>
							<th>OTHER_ID_TYPE</th>
							<th>OTHER_ID_NUMBER</th>
							<th>PART_NAME</th>
							<th>PRESERVE_METHOD</th>
							<th>COLL_OBJ_DISPOSITION</th>
							<th>LOT_COUNT_MODIFIER</th>
							<th>LOT_COUNT</th>
							<th>part_remarks</th>
							<th>CONDITION</th>
							<th>CONTAINER_UNIQUE_ID</th>
							<cfloop index="i" from="1" to="#NUM_PART_ATTRIBUTE_PAIRS#">
								<th>PART_ATT_NAME_#i#</th>
								<th>PART_ATT_VAL_#i#</th>
								<th>PART_ATT_UNITS_#i#</th>
								<th>PART_ATT_DETBY_#i#</th>
								<th>PART_ATT_MADEDATE_#i#</th>
								<th>PART_ATT_REM_#i#</th>
							</cfloop>
						</tr>
					</thead>
					<tbody>
						<cfloop query="getTempDataToShow">
							<tr>
								<td><cfif len(getTempDataToShow.status) eq 0>Cleared to load<cfelse><strong>#getTempDataToShow.status#</strong></cfif></td>
								<td>#institution_acronym#</td>
								<td>#collection_cde#</td>
								<td>#OTHER_ID_TYPE#</td>
								<td>#OTHER_ID_NUMBER#</td>
								<td>#part_name#</td>
								<td>#preserve_method#</td>
								<td>#coll_obj_disposition#</td>
								<td>#lot_count_modifier#</td>
								<td>#lot_count#</td>
								<td>#part_remarks#</td>
								<td>#condition#</td>
								<td>#container_unique_id#</td>
								<cfloop index="i" from="1" to="#NUM_PART_ATTRIBUTE_PAIRS#">
									<td>#evaluate("part_att_name_"&i)#</td>
									<td>#evaluate("part_att_val_"&i)#</td>
									<td>#evaluate("part_att_units_"&i)#</td>
									<td>#evaluate("part_att_detby_"&i)#</td>
									<td>#evaluate("part_att_madedate_"&i)#</td>
									<td>#evaluate("part_att_rem_"&i)#</td>
								</cfloop>
							</tr>
						</cfloop>
					</tbody>
				</table>
			</cfoutput>
		</cfif>
		<!-------------------------------------------------------------------------------------------->
		<cfif #action# is "load">
			<cfoutput>
				<h2 class="h4">Third step: Apply changes</h2>
				<cfset problem_key = "">
				<cftransaction>
					<cfquery name="countSpecimens" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						SELECT count(distinct collection_object_id) ct
						FROM cf_temp_parts 
						WHERE status IS NULL
							AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						GROUP BY username
					</cfquery>
					<cfquery name="getTempData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						SELECT * 
						FROM cf_temp_parts 
						WHERE status IS NULL
							AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
					</cfquery>
					<cfquery name= "getEntBy" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						SELECT 
							agent_id 
						FROM agent_name 
						WHERE 
							agent_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
					</cfquery>
					<cftry>
					<cfif getEntBy.recordcount is 0>
						<cfabort showerror = "You aren't a recognized agent!">
					<cfelseif getEntBy.recordcount gt 1>
						<cfabort showerror = "Your login has has multiple matches.">
					</cfif>
					<cfif getTempData.recordcount EQ 0>
						<cfthrow message="You have no rows to load in the Part bulkloader table (cf_temp_parts).  <a href='/tools/BulkloadNewParts.cfm' class='text-danger'>Start again</a>"><!--- " --->
					</cfif>
					<cfset enteredbyid = getEntBy.agent_id>
						<cfset part_updates = 0>
						<cfloop query="getTempData">
							<cfset problem_key = getTempData.key>
							<cfquery name="NEXTID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
								select sq_collection_object_id.nextval NEXTID from dual
							</cfquery>
							<cfquery name="updateColl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="updateColl_result">
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
									<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#NEXTID.NEXTID#">,
									'SP',
									<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#enteredbyid#">,
									sysdate,
									<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#enteredbyid#">,
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.coll_obj_disposition#">,
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.lot_count_modifier#">,
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.lot_count#">,
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.condition#">,
									0 )
							</cfquery>
							<cfquery name="newTiss" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
								INSERT INTO specimen_part (
									COLLECTION_OBJECT_ID,
									PART_NAME,
									PRESERVE_METHOD,
									DERIVED_FROM_CAT_ITEM)
								VALUES (
									<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#NEXTID.NEXTID#">,
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.PART_NAME#">,
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.PRESERVE_METHOD#">,
									<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempData.collection_object_id#">)
							</cfquery>
							<cfif len(#part_remarks#) gt 0>
									<!---- new remark --->
									<cfquery name="newCollRem" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
										INSERT INTO coll_object_remark (
											collection_object_id, 
											coll_object_remarks
										) VALUES (
											<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#NEXTID.NEXTID#">,
											<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.part_remarks#">)
									</cfquery>
							</cfif>
							<cfif len(#container_unique_id#) gt 0>
								<cfquery name="part_container_id" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									SELECT container_id 
									FROM coll_obj_cont_hist 
									WHERE collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#NEXTID.NEXTID#">
								</cfquery>
								<cfif part_container_id.recordcount GT 0>
									<cfquery name="upPart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
										UPDATE container 
										SET 
											parent_container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#parent_container_id#">
										WHERE 
											container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#part_container_id.container_id#">
									</cfquery>
								</cfif>
							</cfif>
							<cfloop from="1" to="#NUM_PART_ATTRIBUTE_PAIRS#" index="i">
								<cfif len(evaluate("part_att_name_#i#")) GT 0>
									<cfset numAgentID = "">
									<cfset det_agent_name = trim(evaluate("part_att_detby_#i#"))>
									<cfif len(det_agent_name) GT 0>
										<cfquery name="getDetAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
											SELECT agent_id 
											FROM agent_name 
											WHERE agent_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#det_agent_name#">
										</cfquery>
										<cfloop query="getDetAgent">
											<cfset numAgentID = getDetAgent.agent_id>
										</cfloop>
									</cfif>
									<cfset att_name = trim(evaluate("getTempData.part_att_name_#i#"))>
									<cfset att_val = trim(evaluate("getTempData.part_att_val_#i#"))>
									<cfset att_units = trim(evaluate("getTempData.part_att_units_#i#"))>
									<cfset att_madedate = trim(evaluate("getTempData.part_att_madedate_#i#"))>
									<cfset att_rem = trim(evaluate("getTempData.part_att_rem_#i#"))>
									<cfquery name="addPartAtt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
										INSERT INTO specimen_part_attribute (
											collection_object_id, 
											attribute_type, 
											attribute_value, 
											attribute_units, 
											determined_date, 
											determined_by_agent_id, 
											attribute_remark
										) VALUES (
											<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#NEXTID.NEXTID#">,
											<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#att_name#">, 
											<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#att_val#">, 
											<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#att_units#">, 
											<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#att_madedate#">, 
											<cfif len(numAgentId) GT 0>
												<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#numAgentId#">,
											<cfelse>
												NULL,
											</cfif> 
											<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#att_rem#">
										)
									</cfquery>
								</cfif>
							</cfloop>
							<cfset part_updates = part_updates + updateColl_result.recordcount>
							<cfquery name="upLoaded" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
								UPDATE cf_temp_parts 
								SET status = ''
								WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
							</cfquery>
						</cfloop>
						<cfif part_updates eq 1>
							<cfset plur= "">
						<cfelse>
							<cfset plur = "s">
						</cfif>
						<cfif countSpecimens.ct eq 1>
							<cfset splur = "">
						<cfelse>
							<cfset splur = "s">
						</cfif>
						<h3 class="mt-3">#part_updates# part#plur# added for #countSpecimens.ct# cataloged item#splur#.</h3>
						<h3><span class="text-success">Success!</span> Parts loaded.
						<a href="/SpecimenResults.cfm?collection_object_id=#valuelist(getTempData.collection_object_id)#" class="btn-link font-weight-lessbold">
							See in Specimen Results.
						</a>
						</h3>
						<cftransaction action="commit">
					<cfcatch>
						<cftransaction action="ROLLBACK">
						<h3>There was a problem updating the specimen parts.</h3>
						<cfquery name="getProblemData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							SELECT *
							FROM cf_temp_parts
							WHERE key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#problem_key#">
						</cfquery>
						<h3>Fix the issues and <a href="/tools/BulkloadNewParts.cfm">start again</a>.</h3>
						<cfif getProblemData.recordcount GT 0>
							<h3>
								Error loading row (<span class="text-danger">#part_updates + 1#</span>) from the CSV: 
								<cfif len(cfcatch.detail) gt 0>
									<span class="font-weight-normal border-bottom border-danger">
										<cfif cfcatch.detail contains "institution_acronym">
											Invalid Institution Acronyn; Should be 'MCZ'.
										<cfelseif cfcatch.detail contains "collection_cde">
											Problem with collection_cde
										<cfelseif cfcatch.detail contains "other_id_type">
											Invalid or missing other_id_type
										<cfelseif cfcatch.detail contains "other_id_number">
											Invalid other_id_number
										<cfelseif cfcatch.detail contains "part_name">
											Invalid CITED_TAXON_NAME_ID
										<cfelseif cfcatch.detail contains "preserve_method">
											Problem with preserve_method
										<cfelseif cfcatch.detail contains "lot_count_modifier">
											Invalid lot_count_modifier
										<cfelseif cfcatch.detail contains "part_name">
											Invalid part_name
										<cfelseif cfcatch.detail contains "part_value">
											Invalid part_value
										<cfelseif cfcatch.detail contains "unique constraint">
											This change has already been entered. Remove from spreadsheet and try again. (<a href="/tools/BulkloadNewParts.cfm">Reload.</a>)
										<cfelseif cfcatch.detail contains "no data">
											No data or the wrong data (#cfcatch.detail#)
										<cfelse>
											<!--- provide the raw error message if it isn't readily interpretable --->
											#cfcatch.detail#
										</cfif>
									</span>
								</cfif>
							</h3>
							<table class='sortable small table table-responsive table-striped d-lg-table mt-3'>
								<thead>
									<tr>
										<th>COUNT</th>
										<th>BULKLOADING&nbsp;STATUS</th>
										<th>INSTITUTION_ACRONYM</th>
										<th>COLLECTION_CDE</th>
										<th>OTHER_ID_TYPE</th>
										<th>OTHER_ID_NUMBER</th>
										<th>PART_NAME</th>
										<th>PRESERVE_METHOD</th>
										<th>COL_OBJ_DISPOSITION</th>
										<th>LOT_COUNT_MODIFIER</th>
										<th>LOT_COUNT</th>
										<th>PART_REMARKS</th>
										<th>CONDITION</th>
										<th>CONTAINER_UNIQUE_ID</th>
										<cfloop index="i" from="1" to="#NUM_PART_ATTRIBUTE_PAIRS#">
											<th>PART_ATT_NAME_#i#</th>
											<th>PART_ATT_VAL_#i#</th>
											<th>PART_ATT_UNITS_#i#</th>
											<th>PART_ATT_DETBY_#i#</th>
											<th>PART_ATT_MADEDATE_#i#</th>
											<th>PART_ATT_REM_#i#</th>
										</cfloop>
									</tr> 
								</thead>
								<tbody>
									<cfset i=1>
									<cfloop query="getProblemData">
										<tr>
											<td>#i#</td>
											<td>#getProblemData.STATUS# </td>
											<td>#getProblemData.INSTITUTION_ACRONYM# </td>
											<td>#getProblemData.COLLECTION_CDE# </td>
											<td>#getProblemData.OTHER_ID_TYPE#</td>
											<td>#getProblemData.OTHER_ID_NUMBER#</td>
											<td>#getProblemData.PART_NAME#</td>
											<td>#getProblemData.PRESERVE_METHOD#</td>
											<td>#getProblemData.COLL_OBJ_DISPOSITION# </td>
											<td>#getProblemData.LOT_COUNT_MODIFIER# </td>
											<td>#getProblemData.LOT_COUNT#</td>
											<td>#getProblemData.part_remarks#</td>
											<td>#getProblemData.CONDITION#</td>
											<td>#getProblemData.CONTAINER_UNIQUE_ID# </td>
											<cfloop index="i" from="1" to="#NUM_PART_ATTRIBUTE_PAIRS#">
												<td>#evaluate("getProblemData.part_att_name_"&i)#</td>
												<td>#evaluate("getProblemData.part_att_val_"&i)#</td>
												<td>#evaluate("getProblemData.part_att_units_"&i)#</td>
												<td>#evaluate("getProblemData.part_att_detby_"&i)#</td>
												<td>#evaluate("getProblemData.part_att_madedate_"&i)#</td>
												<td>#evaluate("getProblemData.part_att_rem_"&i)#</td>
											</cfloop>
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
					DELETE FROM cf_temp_parts 
					WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
			</cfoutput>
		</cfif>
		</div>
	</div>
</main>
<cfinclude template="/shared/_footer.cfm">
