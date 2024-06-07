<!--- tools/bulkloadEditedParts.cfm to edit existing parts of specimens in bulk.

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
<!--- 
	General overview of actions set up in validation step: 
		1) Upload a part that can not be matched to an existing part
			Fail, and report error
		2) Upload a part that already exists
			Edit existing part using new values, 
			A) part is in a parent container
				If a new container is specified, move the part to that parent container.
			B) part is NOT already in a parent container
				If the upload specifies a container, place the part in that parent container,
---->

<!--- special case handling to dump problem data as csv --->
<cfif isDefined("action") AND action is "dumpProblems">
	<cfquery name="getProblemData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		SELECT 
			INSTITUTION_ACRONYM,COLLECTION_CDE,OTHER_ID_TYPE,OTHER_ID_NUMBER,
			PART_COLLECTION_OBJECT_ID,
			PART_NAME,PRESERVE_METHOD,COLL_OBJ_DISPOSITION,LOT_COUNT_MODIFIER,LOT_COUNT,CURRENT_REMARKS,
			CONDITION,
			CONTAINER_UNIQUE_ID,
			APPEND_TO_REMARKS,CHANGED_DATE,
			NEW_PRESERVE_METHOD,NEW_PART_NAME,NEW_COLL_OBJ_DISPOSITION,NEW_LOT_COUNT_MODIFIER,NEW_LOT_COUNT,NEW_CONDITION
			PART_ATT_NAME_1,PART_ATT_VAL_1,PART_ATT_UNITS_1,PART_ATT_DETBY_1,PART_ATT_MADEDATE_1,PART_ATT_REM_1,
			PART_ATT_NAME_2,PART_ATT_VAL_2,PART_ATT_UNITS_2,PART_ATT_DETBY_2,PART_ATT_MADEDATE_2,PART_ATT_REM_2,
			PART_ATT_NAME_3,PART_ATT_val_3,PART_ATT_UNITS_3,PART_ATT_DETBY_3,PART_ATT_MADEDATE_3,PART_ATT_REM_3,
			PART_ATT_NAME_4,PART_ATT_VAL_4,PART_ATT_UNITS_4,PART_ATT_DETBY_4,PART_ATT_MADEDATE_4,PART_ATT_REM_4,
			PART_ATT_NAME_5,PART_ATT_VAL_5,PART_ATT_UNITS_5,PART_ATT_DETBY_5,PART_ATT_MADEDATE_5,part_ATT_REM_5,
			PART_ATT_NAME_6,PART_ATT_VAL_6,part_ATT_UNITS_6,PART_ATT_DETBY_6,PART_ATT_MADEDATE_6,PART_ATT_REM_6
		FROM cf_temp_edit_parts
		WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
		ORDER BY key
	</cfquery>
	<cfinclude template="/shared/component/functions.cfc">
	<cfinclude template="/shared/functionLib.cfm">
	<cfset csv = queryToCSV(getProblemData)>
	<cfheader name="Content-Type" value="text/csv; charset=utf-8">
	<cfoutput>#csv#</cfoutput>
	<cfabort>
</cfif>
<cfset fieldlist = "INSTITUTION_ACRONYM,COLLECTION_CDE,OTHER_ID_TYPE,OTHER_ID_NUMBER,PART_COLLECTION_OBJECT_ID,PART_NAME,PRESERVE_METHOD,COLL_OBJ_DISPOSITION,LOT_COUNT_MODIFIER,LOT_COUNT,CONTAINER_UNIQUE_ID,CONDITION,CURRENT_REMARKS,APPEND_TO_REMARKS,CHANGED_DATE,NEW_PRESERVE_METHOD,NEW_PART_NAME,NEW_COLL_OBJ_DISPOSITION,NEW_LOT_COUNT_MODIFIER,NEW_LOT_COUNT,NEW_CONDITION,PART_ATT_NAME_1,PART_ATT_VAL_1,PART_ATT_UNITS_1,PART_ATT_DETBY_1,PART_ATT_MADEDATE_1,PART_ATT_REM_1,PART_ATT_NAME_2,PART_ATT_VAL_2,PART_ATT_UNITS_2,PART_ATT_DETBY_2,PART_ATT_MADEDATE_2,PART_ATT_REM_2,PART_ATT_NAME_3,PART_ATT_val_3,PART_ATT_UNITS_3,PART_ATT_DETBY_3,PART_ATT_MADEDATE_3,PART_ATT_REM_3,PART_ATT_NAME_4,PART_ATT_VAL_4,PART_ATT_UNITS_4,PART_ATT_DETBY_4,PART_ATT_MADEDATE_4,PART_ATT_REM_4,PART_ATT_NAME_5,PART_ATT_VAL_5,PART_ATT_UNITS_5,PART_ATT_DETBY_5,PART_ATT_MADEDATE_5,part_ATT_REM_5,PART_ATT_NAME_6,PART_ATT_VAL_6,part_ATT_UNITS_6,PART_ATT_DETBY_6,PART_ATT_MADEDATE_6,PART_ATT_REM_6">
<cfset fieldTypes ="CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_DECIMAL,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,">
<cfset requiredfieldlist = "INSTITUTION_ACRONYM,COLLECTION_CDE,OTHER_ID_TYPE,OTHER_ID_NUMBER">
	
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
<cfset pageTitle = "Bulk Edit Parts">
<cfinclude template="/shared/_header.cfm">
<cfinclude template="/tools/component/csv.cfc" runOnce="true"><!--- for common csv testing functions --->
<cfif not isDefined("action") OR len(action) EQ 0><cfset action="entryPoint"></cfif>

<main class="container-fluid px-xl-5 py-3" id="content">
	<h1 class="h2 mt-2">Bulkload Edited Parts </h1>
	<!------------------------------------------------------->
	<cfif #action# is "entryPoint">
		<cfoutput>
			<p>This tool edits existing part records of specimen records. It creates metadata for the part history. The cataloged items must be in the database and they can be entered using the catalog number or other ID.  Parts must also exist, new parts will not be added with this tool.  Error messages will appear if the values need to match values in MCZbase and if required columns are missing. Additional columns will be ignored.  The first line of the file must be the column headings, spelled exactly as below. </p>
			<p>Institution Acronym, Collection Code, and an identifying number for the cataloged item must be specified, as must either PART_COLLECTION_OBJECT_ID or the values of PART_NAME,PRESERVE_METHOD,COLL_OBJ_DISPOSITION,CONDITION,LOT_COUNT,LOT_COUNT_MODIFIER, and CURRENT_REMARKS to uniquely identify the part to be modified.</p> 
			<p>To change lot count or lot count modifier, both NEW_LOT_COUNT and NEW_LOT_COUNT_MODIFIER will be used.</p>
			<p>If any of the PART_ATT_..._1 fields are populated, they will be used to add new part attributes to the specified part.  They do not edit existing part attributes, and can result in duplicate part attributes.</p>
			<p>A file of parts to be edited can be obtained from the <strong>Parts Report/Download</strong> option from the <strong>Manage</strong> page for a specimen search result.  The Download Parts CSV option on the Parts Report/Download page has the correct format to upload here.</p>
			<div class="w-100">
				<span class="btn btn-xs btn-info" onclick="document.getElementById('template').style.display='block';">View template</span>
				<div id="template" style="display:none;margin: 1em 0;">
					<label for="templatearea" class="data-entry-label">
						Copy this header line and save it as a .csv file (<a href="/tools/BulkloadEditedParts.cfm?action=getCSVHeader" class="font-weight-lessbold">download</a>)
					</label>
					<textarea rows="2" cols="90" id="templatearea" class="w-100 data-entry-textarea">#fieldlist#</textarea>
				</div>
			</div>
			<div class="w-100">
				<span class="btn btn-xs btn-info" onclick="document.getElementById('fieldmetadata').style.display='block';">View List of Columns with descriptions.</span>
				<div id="fieldmetadata" style="display:none;margin: 1em 0;">
					<h2 class="mt-4 h4">Columns in <span class="text-danger">red</span> are required; others are optional:</h2>
					<ul class="mb-4 h5 font-weight-normal list-group mx-3">
						<cfloop list="#fieldlist#" index="field" delimiters=",">
							<cfquery name = "getComments"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#"  result="getComments_result">
								SELECT comments
								FROM sys.all_col_comments
								WHERE 
									owner = 'MCZBASE'
									and table_name = 'CF_TEMP_EDIT_PARTS'
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
			<form name="atts" method="post" enctype="multipart/form-data" action="/tools/BulkloadEditedParts.cfm">
				<div class="form-row border rounded p-2 mb-3">
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
		</cfoutput>
	</cfif>	
	<!------------------------------------------------------->
	<cfif #action# is "getFile">
		<cfoutput>
			<h2 class="h4">First step: Reading data from CSV file.</h2>
			<!--- Compare the numbers of headers expected against provided in CSV file --->
			<!--- Set some constants to identify error cases in cfcatch block --->
			<cfset NO_COLUMN_ERR = "One or more required fields are missing in the header line of the csv file. Check charset selected if columns match the required headers and the first column is not found.">
			<cfset DUP_COLUMN_ERR = "One or more columns are duplicated in the header line of the csv file.">
			<cfset COLUMN_ERR = "Error inserting data ">
			<cfset NO_HEADER_ERR = "No header line found, csv file appears to be empty.">
			<cfset TABLE_NAME = "cf_temp_edit_parts">
			<cftry>
				<!--- cleanup any incomplete work by the same user --->
				<cfquery name="clearTempTable" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="clearTempTable_result">
					DELETE FROM cf_temp_edit_parts 
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
					<h3 class="h4">Found #variables.size# columns in header of csv file.</h3>
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
						<!---Construct insert for rows if column header is in fieldlist, otherwise use null--->
						<!---We cannot use csvFormat.withHeader() or match columns by name, so we are forced to match by number, use arrays--->
						<cfquery name="insert" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="insert_result">
							INSERT INTO cf_temp_edit_parts (
								#fieldlist#,
								username
							) VALUES (
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
						<p>
							Showing #foundHighCount# example#plural#.  If these do not appear as the correct characters, 
							the file likely has a different encoding from the one you selected and
							you probably want to <strong><a href="/tools/BulkloadEditedParts.cfm">reload</a></strong> 
							this file selecting a different encoding.  If these appear as expected, then 
							you selected the correct encoding and can continue to validate or load.
						</p>
					</div>
					<ul class="h4 list-unstyled">
						#foundHighAscii# #foundMultiByte#
					</ul>
				</cfif>
				<h3 class="h3">
					<cfif loadedRows EQ 0>
						Loaded no rows from the CSV file.  The file appears to be just a header with no data. Fix file and <a href="/tools/BulkloadEditedParts.cfm">reload</a>
					<cfelse>
						Successfully read #loadedRows# records from the CSV file.  Next <a href="/tools/BulkloadEditedParts.cfm?action=validate" class="btn-link font-weight-lessbold">click to validate</a>.
					</cfif>
				</h3>
			<cfcatch>
				<h3 class="h4">
					Failed to read the CSV file.  Fix the errors in the file and <a href="/tools/BulkloadEditedParts.cfm">reload</a>
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
				<!--- identify and provide guidance for some standard failure conditions --->
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
					<cfif format EQ "DEFAULT"><cfset fmt="CSV: Default Comma Separated values"><cfelse><cfset fmt="#format#"></cfif>
					<h4 class='mb-3'>
						Unable to read headers in line 1.  Is your file actually have the format #fmt#?
					</h4>
					<h4 class='mb-3'>#cfcatch.message#</h4>
				<cfelseif Find("invalid char between encapsulated token and delimiter",cfcatch.message) GT 0>
					<h4 class='mb-3'>
						Does your file have an inconsitent format?  Are some lines tab delimited but others comma delimited?
					</h4>
				<cfelseif Find("IOException reading next record: java.io.IOException:",cfcatch.message) GT 0>
					<cfif format EQ "DEFAULT"><cfset fmt="CSV: Default Comma Separated values"><cfelse><cfset fmt="#format#"></cfif>
					<h4 class='mb-3'>
						Unable to read a record from the file.  One or more lines may not be consistent with the specified format #format#
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
	<!------------------------Validation------------------------------->
	<cfif #action# is "validate">
		<cfoutput>
			<h2 class="h4">Second step: Validate data from CSV file.</h2>
			<cfset key = "">
			<!--- setup for validation checks, ensure that status is empty. --->
			<cfquery name="insColl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE cf_temp_edit_parts 
				SET status = ''
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<!--- First set of Validation tests: find part and collection object --->: 
			<!--- check various terms used for matching if part_collection_object_id was not specified --->
			<cfquery name="badDisposition" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE cf_temp_edit_parts 
				SET status = concat(nvl2(status, status || '; ', ''),'Invalid DISPOSITION, must be specified ')
				WHERE
					( 
						COLL_OBJ_DISPOSITION NOT IN (
							select COLL_OBJ_DISPOSITION from CTCOLL_OBJ_DISP
						)
						OR coll_obj_disposition is null
					)
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
					AND part_collection_object_id is null
			</cfquery>
			<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE cf_temp_edit_parts 
				SET status = concat(nvl2(status, status || '; ', ''),'CONDITION must be specified if part_collection_object_id is not')
				WHERE CONDITION is null
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
					AND part_collection_object_id is null
			</cfquery>
			<!--- Check row by row for matching cataloged items and then parts --->
			<!--- If successfull, this block will set the magic phrase ' :Found Cataloged Item; Found Part' --->
			<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT * 
				FROM cf_temp_edit_parts 
				WHERE status is null
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfloop query="data">
				<cfif #other_id_type# is "catalog number">
					<cfquery name="collObj" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						SELECT
							collection_object_id
						FROM
							cataloged_item 
							join collection on cataloged_item.collection_id = collection.collection_id
						WHERE
							collection.collection_cde = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#collection_cde#"> and
							collection.institution_acronym = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#institution_acronym#"> and
							cat_num=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#other_id_number#">
					</cfquery>
				<cfelse>
					<cfquery name="collObj" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						SELECT
							coll_obj_other_id_num.collection_object_id
						FROM
							coll_obj_other_id_num
							join cataloged_item on coll_obj_other_id_num.collection_object_id = cataloged_item.collection_object_id 
							join collection on cataloged_item.collection_id = collection.collection_id
						WHERE
							collection.collection_cde = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#collection_cde#"> and
							collection.institution_acronym = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#institution_acronym#"> and
							other_id_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#other_id_type#"> and
							display_value = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#other_id_number#">
					</cfquery>
				</cfif>
				<cfif #collObj.recordcount# is 1>
					<!--- mark the collection object id for the cataloged item --->
					<cfquery name="insColl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						UPDATE cf_temp_edit_parts 
							SET 
								collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collObj.collection_object_id#">,
								status = concat(nvl2(status, status || '; ', ''),'Found Cataloged Item')
						WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
							AND key = <cfqueryparam cfsqltype="CF_SQL_decimal" value="#data.key#"> 
					</cfquery>
					<!--- check that the specified part can be found --->
					<cfquery name="markPartExists" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						UPDATE cf_temp_edit_parts 
							SET status = 'VALID:' || concat(nvl2(status, status || '; ', ''),'Found Part')
						WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
							AND key = <cfqueryparam cfsqltype="CF_SQL_decimal" value="#data.key#">
							AND part_collection_object_id IS NOT NULL
							AND part_collection_object_id IN (
								select collection_object_id from specimen_part 
								where derived_from_cat_item = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collObj.collection_object_id#">
							)
					</cfquery>
					<cfquery name="getPart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						select specimen_part.collection_object_id
						from specimen_part   
							left join coll_object_remark on specimen_part.collection_object_id = coll_object_remark.collection_object_id
							left join coll_object on specimen_part.collection_object_id = coll_object.collection_object_id
						where			
							part_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#data.part_name#">
							and preserve_method = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#data.preserve_method#">
							and derived_from_cat_item = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#collObj.collection_object_id#">
							<cfif len(data.current_remarks) EQ 0>
								and coll_object_remark.coll_object_remarks IS NULL
							<cfelse>
								and coll_object_remark.coll_object_remarks = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#data.current_remarks#">
							</cfif>
							<cfif len(data.lot_count) EQ 0>
								and coll_object.lot_count IS NULL
							<cfelse>
								and coll_object.lot_count= <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#data.lot_count#">
							</cfif>
							<cfif len(data.lot_count_modifier) EQ 0>
								and coll_object.lot_count_modifier IS NULL
							<cfelse>
								and coll_object.lot_count_modifier= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#data.lot_count_modifier#">
							</cfif>
					</cfquery>
					<cfif getPart.recordcount EQ 1>
						<cfquery name="setPartCollObjectID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							UPDATE cf_temp_edit_parts 
								SET 
									part_collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getPart.collection_object_id#">,
									status = 'VALID:' || concat(nvl2(status, status || '; ', ''),'Found Part')
							WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
								AND key = <cfqueryparam cfsqltype="CF_SQL_decimal" value="#data.key#">
								AND part_collection_object_id IS NULL
						</cfquery>
					</cfif>
				<cfelse>
					<cfquery name="insColl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						UPDATE cf_temp_edit_parts 
						SET 
							status = concat(
								nvl2(status, status || '; ', ''),
							'	#data.institution_acronym# #data.collection_cde# #data.other_id_type# #data.other_id_number# could not be found.'
							)
						WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
							AND key = <cfqueryparam cfsqltype="CF_SQL_decimal" value="#data.key#">
					</cfquery>
				</cfif>
			</cfloop>

			<!--- Second set of Validation tests: container terms --->: 
			<!--- check container terms, use list of keys for row by row validations of containers --->
			<cfquery name="getTempTableQC" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT key, container_unique_id 
				FROM cf_temp_edit_parts 
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfloop query="getTempTableQC">
				<cfquery name="getParentContainerId" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE cf_temp_edit_parts 
					SET 
						parent_container_id = (
							select container_id from container 
							where container.barcode = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempTableQC.container_unique_id#">
						),
					WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						AND key = <cfqueryparam cfsqltype="CF_SQL_decimal" value="#getTempTableQC.key#"> 
				</cfquery>
				<cfquery name="validateGotParent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE cf_temp_edit_parts 
					SET status = concat(nvl2(status, status || '; ', ''), 'Container Unique ID not found')
					WHERE CONTAINER_UNIQUE_ID is not null 
						AND parent_container_id is null
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						AND key = <cfqueryparam cfsqltype="CF_SQL_decimal" value="#getTempTableQC.key#"> 
				</cfquery>
				<cfquery name="badContainerId" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE cf_temp_edit_parts 
					SET status = concat(nvl2(status, status || '; ', ''),'Invalid CONTAINER_UNIQUE_ID')
					WHERE 
						CONTAINER_UNIQUE_ID NOT IN (
							select barcode from container where barcode is not null
						)
						AND CONTAINER_UNIQUE_ID is not null
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						AND key = <cfqueryparam cfsqltype="CF_SQL_decimal" value="#getTempTableQC.key#"> 
				</cfquery>
				<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE cf_temp_edit_parts
					SET status = concat(nvl2(status, status || '; ', ''),'Invalid CONTAINER_TYPE')
					WHERE 
						change_container_type NOT IN (
							select container_type from ctcontainer_type
						)
						AND change_container_type is null
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						AND key = <cfqueryparam cfsqltype="CF_SQL_decimal" value="#getTempTableQC.key#"> 
				</cfquery>
			</cfloop>

			<!--- Third set of Validation tests: new values that will replace existing ones --->: 
			<!--- Assess new values, in bulk --->
			<cfquery name="badNewPreserve" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE cf_temp_edit_parts 
				SET status = concat(
						nvl2(status, status || '; ', ''),
						'Invalid NEW_PRESERVE_METHOD must be in preserve_method vocabulary for collection'
					)
				WHERE 
					new_preserve_method|| '|' ||collection_cde NOT IN (
						select preserve_method|| '|' ||collection_cde from ctspecimen_preserv_method
					)
					AND new_preserve_method is not null
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="badNewPartName" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE cf_temp_edit_parts 
				SET status = concat(
						nvl2(status, status || '; ', ''),
						'Invalid NEW_PART_NAME, must be in part name vocabulary for collection'
					)
				WHERE 
					new_part_name || '|' ||collection_cde NOT IN (
						select part_name|| '|' ||collection_cde from ctspecimen_preserv_method
					)
					AND new_part_name IS NOT NULL
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="badlotcounts" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE cf_temp_edit_parts 
				SET status = concat(nvl2(status, status || '; ', ''),'Invalid NEW_LOT_COUNT, must be a number')
				WHERE 
					is_number(new_lot_count) = 0
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
					AND new_lot_count IS NOT NULL
			</cfquery>
			<cfquery name="badmodifiers" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE cf_temp_edit_parts 
				SET status = concat(nvl2(status, status || '; ', ''),'Invalid LOT_COUNT_MODIFIER, must be in numeric modifiers vocabulary')
				WHERE 
					lot_count_modifier NOT IN (
						select modifier from ctnumeric_modifiers
					)
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
					and lot_count_modifier is not null
			</cfquery>
			<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE cf_temp_edit_parts 
				SET status = concat(nvl2(status, status || '; ', ''),'Invalid CHANGED_DATE, must be a date in yyyy-mm-dd format.')
				WHERE 
					isdate(changed_date) = 0
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
					AND changed_date is not null
			</cfquery>

			<!--- Fourth set of Validation tests: check attribute values --->: 
			<!--- Check part attributes with general queries for the user --->
			<cfloop index="i" from="1" to="6">
				<cfquery name="chkPAtt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE cf_temp_edit_parts 
					SET status = concat(nvl2(status, status || '; ', ''),'Invalid part attribute "'||PART_ATT_NAME_#i#||'"')
					WHERE PART_ATT_NAME_#i# not in (select attribute_type from CTSPECPART_ATTRIBUTE_TYPE) 
						AND PART_ATT_NAME_#i# is not null
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>	
				<cfquery name="chkPAtt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE cf_temp_edit_parts 
					SET status = concat(nvl2(status, status || '; ', ''),'"'||PART_ATT_VAL_#i#||'" is required for "'||PART_ATT_NAME_#i#||'"')
					WHERE 
						chk_att_codetables(PART_ATT_NAME_#i#,PART_ATT_VAL_#i#,COLLECTION_CDE)=0
						AND PART_ATT_NAME_#i# is not null and PART_ATT_VAL_#i# is null
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<!--- TODO: This is a select query that is never used --->
				<cfquery name="chkPAttCT" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT 
						cf_temp_edit_parts.part_att_name_#i#,
						cf_temp_edit_parts.part_att_val_#i#,
						cf_temp_edit_parts.collection_cde,
						ctspecpart_attribute_type.attribute_type,
						decode(value_code_tables, null, unit_code_tables,value_code_tables) code_table 
					FROM 
						cf_temp_edit_parts, 
						ctspecpart_attribute_type 
					WHERE attribute_type = '||PART_ATT_NAME_#i#||'
						AND cf_temp_edit_parts.part_att_name_#i# = attribute_type
						AND cf_temp_edit_parts.part_att_val_#i# is not null
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cfquery name="chkPAtt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE cf_temp_edit_parts 
					SET status = concat(nvl2(status, status || '; ', ''),'Invalid PART_ATT_MADEDATE_#i# must be yyyy-mm-dd "'||PART_ATT_MADEDATE_#i#||'"')
					WHERE PART_ATT_NAME_#i# is not null 
						AND (
							is_iso8601(PART_ATT_MADEDATE_#i#) <> 'valid' 
							OR length(PART_ATT_MADEDATE_#i#) <> 10
                  )
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE cf_temp_edit_parts 
					SET status = concat(nvl2(status, status || '; ', ''),'Invalid CHANGED_DATE')
					WHERE isdate(changed_date) = 0
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cfquery name="chkPAtt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE cf_temp_edit_parts 
					SET status = concat(nvl2(status, status || '; ', ''),'Invalid scientific name <span class="font-weight-bold">"'||PART_ATT_VAL_#i#||'"</span>') 
					WHERE 
						PART_ATT_NAME_#i# = 'scientific name'
						AND regexp_replace(PART_ATT_VAL_#i#, ' (\?|sp.)$', '') in
							(select scientific_name from taxonomy group by scientific_name having count(*) > 1)
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cfquery name="chkPAtt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE cf_temp_edit_parts 
					SET status = concat(nvl2(status, status || '; ', ''), 'scientific name (' ||PART_ATT_VAL_#i# ||') does not exist')
					WHERE 
						PART_ATT_NAME_#i# = 'scientific name'
						AND regexp_replace(PART_ATT_VAL_#i#, ' (\?|sp.)$', '') not in
							(select scientific_name from taxonomy group by scientific_name having count(*) = 1)
						AND PART_ATT_VAL_#i# is not null
						and (status not like '%scientific name ('||PART_ATT_VAL_#i#||') matched multiple taxonomy records%' or status is null)
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cfquery name="chkPAtt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE cf_temp_edit_parts 
					SET status = concat(nvl2(status, status || '; ', ''),'scientific name cannot be null')
					WHERE 
						PART_ATT_NAME_#i# = 'scientific name' AND PART_ATT_VAL_#i# is null
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cfquery name="chkPAtt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE cf_temp_edit_parts 
					SET status = concat(nvl2(status, status || '; ', ''),'Invalid part attribute determiner "'||PART_ATT_DETBY_#i#||'"')
					WHERE 
						PART_ATT_DETBY_#i# not in 
							(select agent_name from preferred_agent_name where PART_ATT_DETBY_#i# = preferred_agent_name.agent_name)  
						AND PART_ATT_NAME_#i# is not null
						AND PART_ATT_DETBY_#i# is not null
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cfquery name="chkPAtt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE cf_temp_edit_parts 
					SET status = concat(nvl2(status, status || '; ', ''),'Invalid PART_ATT_NAME "'||PART_ATT_NAME_#i#||'" does not match MCZbase')
					WHERE 
						PART_ATT_NAME_#i# not in 
							(select attribute_type from ctspecpart_attribute_type) 
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cfquery name="chkPAtt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE cf_temp_edit_parts 
					SET status = concat(nvl2(status,status ||  '; ', ''), 'PART_ATT_UNITS_#i# is not valid for attribute "'||PART_ATT_NAME_#i#||'"')
					WHERE 
						MCZBASE.CHK_SPECPART_ATT_CODETABLES(PART_ATT_NAME_#i#,PART_ATT_UNITS_#i#,COLLECTION_CDE)=0
						AND PART_ATT_NAME_#i# in
							(select attribute_type from ctspecpart_attribute_type where unit_code_tables is not null)
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
			</cfloop>

			<!--- Fifth set of Validation tests: confirm that part was matched and exists to be updated --->: 
			<!--- confirm that part exists if part_collection_object_id is specified --->
			<cfquery name="findunmatchedbyid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE cf_temp_edit_parts 
				SET status = concat(
						nvl2(status, status || '; ', ''),
						'ERROR: no matching part by part id' 
					)
				WHERE cf_temp_edit_parts.key NOT in 
					(
						select cf_temp_edit_parts.key
						from cf_temp_edit_parts 
							join specimen_part on cf_temp_edit_parts.part_collection_object_id=specimen_part.collection_object_id
						where
							specimen_part.collection_object_id is not null
					)
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
					AND cf_temp_edit_parts.part_collection_object_id IS NOT NULL
			</cfquery>

			<!--- confirm that parts can be uniquely found, if part_collection_object_id is not specified depends on lookup of collection_object_id --->
			<cfquery name="findunmatched" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE cf_temp_edit_parts 
				SET status = concat(
						nvl2(status, status || '; ', ''),
						'ERROR: no matching part by part fields' 
					)
				WHERE cf_temp_edit_parts.key NOT in 
					(
						select cf_temp_edit_parts.key
						from cf_temp_edit_parts 
							join specimen_part on  
								cf_temp_edit_parts.part_name=specimen_part.part_name and
								cf_temp_edit_parts.preserve_method=specimen_part.preserve_method and
								cf_temp_edit_parts.collection_object_id=specimen_part.derived_from_cat_item
							left join coll_object_remark on specimen_part.collection_object_id = coll_object_remark.collection_object_id
							left join coll_object on specimen_part.collection_object_id = coll_object.collection_object_id
						where			
							nvl(cf_temp_edit_parts.current_remarks, 'NULL') = nvl(coll_object_remark.coll_object_remarks, 'NULL') and
							nvl2(cf_temp_edit_parts.lot_count,cf_temp_edit_parts.lot_count,-1) 
								= nvl2(coll_object.lot_count,coll_object.lot_count,-1) and
							nvl2(cf_temp_edit_parts.lot_count_modifier,cf_temp_edit_parts.lot_count_modifier,'NULL') 
								= nvl2(coll_object.lot_count_modifier,coll_object.lot_count_modifier,'NULL')
					)
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
					AND cf_temp_edit_parts.collection_object_id IS NOT NULL
					AND cf_temp_edit_parts.part_collection_object_id IS NULL
			</cfquery>
			<cfquery name="findduplicates" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE cf_temp_edit_parts 
				SET status = concat(
						nvl2(status, status || '; ', ''),
						'ERROR: More that one matching part by part fields' 
					)
				WHERE cf_temp_edit_parts.key in 
					(
						select cf_temp_edit_parts.key
						from cf_temp_edit_parts 
							join specimen_part on  
								cf_temp_edit_parts.part_name=specimen_part.part_name and
								cf_temp_edit_parts.preserve_method=specimen_part.preserve_method and
								cf_temp_edit_parts.collection_object_id=specimen_part.derived_from_cat_item
							left join coll_object_remark on specimen_part.collection_object_id = coll_object_remark.collection_object_id
							left join coll_object on specimen_part.collection_object_id = coll_object.collection_object_id
						where			
							nvl(cf_temp_edit_parts.current_remarks, 'NULL') = nvl(coll_object_remark.coll_object_remarks, 'NULL') and
							nvl2(cf_temp_edit_parts.lot_count,cf_temp_edit_parts.lot_count,-1) 
								= nvl2(coll_object.lot_count,coll_object.lot_count,-1) and
							nvl2(cf_temp_edit_parts.lot_count_modifier,cf_temp_edit_parts.lot_count_modifier,'NULL') 
								= nvl2(coll_object.lot_count_modifier,coll_object.lot_count_modifier,'NULL')
						group by cf_temp_edit_parts.key
						having count(cf_temp_edit_parts.key) > 1
					)
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
					AND cf_temp_edit_parts.collection_object_id IS NOT NULL
					AND cf_temp_edit_parts.part_collection_object_id IS NULL
			</cfquery>
		
			<!--- Last phase of Validation tests: cleanup and prepare to report --->: 
			<!--- to tell if there are failure cases, we need to remove the string VALID if there are any error messages, 
					as almost all of the error messages are concatenated onto status, instead of replacing valid --->
			<cfquery name="cleanoutValidFromInvalid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE cf_temp_edit_parts 
				SET status = REGEXP_REPLACE(status,'^VALID',' ')
				WHERE 
					status <> 'VALID'
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="setParentContainerIds" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE cf_temp_edit_parts 
				SET (parent_container_id) = (
					select container_id
					from container where
					barcode=CONTAINER_UNIQUE_ID)
				WHERE 
					substr(status,1,5) IN ('VALID')
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="markPartsNotFound" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE cf_temp_edit_parts 
				SET status = concat(nvl2(status,status ||  '; ', ''), 'PART NOT FOUND')
				WHERE 
					part_collection_object_id NOT IN (
						select collection_object_id from specimen_part
					)
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>

			<cfquery name="inT" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT * 
				FROM cf_temp_edit_parts
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="countFailures" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT count(*) as cnt 
				FROM cf_temp_edit_parts 
				WHERE
					(
						status IS NULL or
						status <> ' :Found Cataloged Item; Found Part'
					)
					AND collection_object_id is not null
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<h3 class="mt-3">
				<cfif #countFailures.cnt# is 0>
					<span class="text-success">Validation checks passed.</span> Look over the table below and <a href="/tools/BulkloadEditedParts.cfm?action=load" class="btn-link font-weight-lessbold">click to continue</a> if it all looks good. Or, <a href="/tools/BulkloadEditedParts.cfm" class="text-danger">start again</a>.
				<cfelse>
					There is a problem with #countFailures.cnt# of #inT.recordcount# row(s). See the STATUS column. (<a href="/tools/BulkloadEditedParts.cfm?action=dumpProblems">download</a>).
					Fix the problem(s) noted in the status column and <a href="/tools/BulkloadEditedParts.cfm" class="text-danger">start again</a>.
				</cfif>
			</h3>
			<table class='px-0 small sortable table table-responsive table-striped w-100'>
				<thead class="thead-light">
					<tr>
						<th>BULKLOADING&nbsp;STATUS</th>
						<th>INSTITUTION_ACRONYM</th>
						<th>COLLECTION_CDE</th>
						<th>OTHER_ID_TYPE</th>
						<th>OTHER_ID_NUMBER</th>
						<th>PART_NAME</th>
						<th>PRESERVE_METHOD</th>
						<th>DISPOSITION</th>
						<th>LOT_COUNT_MODIFIER</th>
						<th>LOT_COUNT</th>
						<th>CURRENT_REMARKS</th>
						<th>CONDITION</th>
						<th>CONTAINER_UNIQUE_ID</th>
						<th>APPEND_TO_REMARKS</th>
						<th>CHANGED_DATE</th>
						<th>NEW_PART_NAME</th>
						<th>NEW_PRESERVE_METHOD</th>
						<th>NEW_COLL_OBJ_DISPOSITION</th>
						<th>NEW_LOT_COUNT</th>
						<th>NEW_LOT_COUNT_MODIFIER</th>
						<th>NEW_CONDITION</th>
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
					<cfloop query="inT">
						<tr>
							<td>
								<cfquery name="lookupGuid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									SELECT collection_cde, cat_num 
									FROM cataloged_item
									WHERE collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#inT.collection_object_id#">
								</cfquery>
								<cfloop query="lookupGuid">
									<cfset guid = "MCZ:#lookupGuid.collection_cde#:#lookupGuid.cat_num#">
								</cfloop>
								<cfif len(#collection_object_id#) gt 0 and (#status# is ' :Found Cataloged Item; Found Part')>
									<!--- no need to display status --->
								<cfelseif left(status,5) is 'VALID'>
									<a href="/guid/#guid#"
										target="_blank">#guid#</a> (#status#)
								<cfelseif left(status,6) is 'ERROR:'>
									<a href="/guid/#guid#"
										target="_blank">#guid#</a> <strong>#status#</strong>
								<cfelseif len(status) EQ 0>
									<strong>BUG: Validation checks not run.</strong>
								<cfelse>
									<strong>ERROR: #status#</strong>
								</cfif>
							</td>
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
							<td>#CONTAINER_UNIQUE_ID#</td>
							<td>#append_to_remarks#</td>
							<td>#changed_date#</td>
							<td>#NEW_PART_NAME#</td>
							<td>#NEW_PRESERVE_METHOD#</td>
							<td>#NEW_COLL_OBJ_DISPOSITION#</td>
							<td>#NEW_LOT_COUNT#</td>
							<td>#NEW_LOT_COUNT_MODIFIER#</td>
							<td>#NEW_CONDITION#</td>
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
			<h2 class="h4">Third Step: Load Data</h2>
			<cfset problem_key = "">
			<cftransaction>
				<cfquery name="getTempData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT * 
					FROM cf_temp_edit_parts 
					WHERE status not in ('LOADED', 'PART NOT FOUND')
				</cfquery>
				<cfquery name= "getEntBy" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT agent_id 
					FROM agent_name 
					WHERE agent_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cftry>
					<cfif getEntBy.recordcount is 0>
						<cfabort showerror = "Your user name is not associated with an agent record.  Contact a database administrator.">
					<cfelseif getEntBy.recordcount gt 1>
						<cfabort showerror = "Your login has has multiple matches.">
					</cfif>
					<cfif getTempData.recordcount EQ 0>
						<cfthrow message="You have no rows to load in the Part bulkloader table (cf_temp_edit_parts).  <a href='/tools/BulkloadEditedParts.cfm' class='text-danger'>Start again</a>">.<!--- " --->
					</cfif>
					<cfset enteredbyid = getEntBy.agent_id>
					<cfset part_updates = 0>
					<cfset part_updates1 = 0>
					<cfloop query="getTempData">
						<cfset problem_key = #getTempData.key#>
						<cfif len(#part_collection_object_id#) is 0>
							<!--- no part to modify, fail --->
							<cfthrow message="No part to modify for #getTempData.institution_acronym#:#getTempData.collection_cde# #getTempData.other_id_type##getTempData.other_id_number#">
						<cfelse>
							<!--- update existing part --->
							<cfif len(#new_part_name#) gt 0>
								<cfquery name="change_preservemethod" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									UPDATE SPECIMEN_PART 
									SET part_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#NEW_part_name#"> 
									WHERE collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#part_collection_object_id#">
								</cfquery>
							</cfif>
							<cfif len(#new_preserve_method#) gt 0>
								<cfquery name="change_preservemethod" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									UPDATE SPECIMEN_PART 
									SET PRESERVE_METHOD = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#NEW_PRESERVE_METHOD#"> 
									WHERE collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#part_collection_object_id#">
								</cfquery>
							</cfif>
							<cfif len(#new_lot_count#) gt 0>
								<cfquery name="upCond" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									UPDATE coll_object 
									SET lot_count = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#new_lot_count#">, 
										lot_count_modifier=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#new_lot_count_modifier#"> 
									WHERE collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#part_collection_object_id#">
								</cfquery>
							</cfif>
							<cfif len(#NEW_COLL_OBJ_disposition#) gt 0>
								<cfquery name="upDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="updateColl_result">
									UPDATE coll_object 
									SET COLL_OBJ_DISPOSITION = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#NEW_coll_obj_disposition#"> 
									WHERE collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#part_collection_object_id#">
								</cfquery>
							</cfif>
							<cfif len(#new_condition#) gt 0>
								<cfquery name="upCond" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									UPDATE coll_object 
									SET condition = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#new_condition#"> 
									WHERE collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#part_collection_object_id#">
								</cfquery>
							</cfif>
							<cfif len(#append_to_remarks#) gt 0>
								<cfquery name="remarksCount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									SELECT * FROM coll_object_remark 
									where collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#part_collection_object_id#">
								</cfquery>
								<cfif remarksCount.recordcount is 0>
									<cfquery name="insertRemarks" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
										INSERT INTO coll_object_remark (
											collection_object_id, 
											coll_object_remarks
										) VALUES (
											<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#part_collection_object_id#">, 
											<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#append_to_remarks#">
										)
									</cfquery>
								<cfelse>
									<!--- NOTE: Expectation is that there is a zero to 1 relationship between part and collection_object_remark. --->
									<cfquery name="updateRemarks" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
										UPDATE coll_object_remark
										SET coll_object_remarks = 
											DECODE(coll_object_remarks, 
												null, 
												<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#append_to_remarks#">,
												coll_object_remarks || <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="; #append_to_remarks#">
											)
										WHERE collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#part_collection_object_id#">
									</cfquery>
								</cfif>
							</cfif>
							<cfif len(#CONTAINER_UNIQUE_ID#) gt 0>
								<cfquery name="part_container_id" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									SELECT container_id 
									FROM coll_obj_cont_hist 
									where collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#part_collection_object_id#">
								</cfquery>
								<!--- TODO: Review this comment, was not in appropriate place, may not be correct --->
								<!--- there is an existing matching container that is not in a parent_container;
									all we need to do is move the container to a parent IF it exists and is specified, or nothing otherwise --->
								<cfquery name="upPart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									UPDATE container 
									SET parent_container_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#parent_container_id#">
									WHERE container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#part_container_id.container_id#">
								</cfquery>
								<cfif #len(change_container_type)# gt 0>
									<cfquery name="upPart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
										UPDATE container 
										SET container_type=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#change_container_type#">
										WHERE container_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#parent_container_id#">
									</cfquery>
								</cfif>
							</cfif>
							<cfif len(#changed_date#) gt 0>
								<cfquery name="change_date" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									UPDATE specimen_part_pres_hist 
									SET changed_date = to_date(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#CHANGED_DATE#">, 'YYYY-MM-DD') 
									WHERE collection_object_id =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#part_collection_object_id#">
										and is_current_fg = 1
								</cfquery>
							</cfif>
							<!--- Add part attributes, if specified --->
							<cfif len(#part_att_name_1#) GT 0>
								<cfif len(#part_att_detby_1#) GT 0>
									<cfquery name="a" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
										SELECT agent_id 
										FROM agent_name 
										WHERE agent_name = trim(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#part_att_detby_1#">)
									</cfquery>
									<cfset numAgentID = a.agent_id>
								<cfelse>
									<cfset  numAgentID = "NULL">
								</cfif>
								<cfquery name="addPartAtt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									INSERT INTO SPECIMEN_PART_ATTRIBUTE (
										collection_object_id,
										attribute_type,
										attribute_value,
										attribute_units,
										determined_date,
										determined_by_agent_id,
										attribute_remark
									) VALUES (
										<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#part_collection_object_id#">,
										<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.part_att_name_1#">,
										<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.part_att_val_1#">,
										<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.part_att_units_1#">,
										<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.part_att_madedate_1#">,
										<cfif numAgentId EQ "NULL">
											NULL,
										<cfelse>
											<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#numAgentId#">,
										</cfif>
										<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.part_att_rem_1#">
									)
								</cfquery>
							</cfif>
							<cfif len(#part_att_name_2#) GT 0>
								<cfif len(#part_att_detby_2#) GT 0>
									<cfquery name="a" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
										SELECT agent_id 
										FROM agent_name 
										WHERE agent_name = trim(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#part_att_detby_2#">)
									</cfquery>
									<cfset numAgentID = a.agent_id>
								<cfelse>
									<cfset  numAgentID = "NULL">
								</cfif>
								<cfquery name="addPartAtt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									INSERT INTO SPECIMEN_PART_ATTRIBUTE (
										collection_object_id,
										attribute_type,
										attribute_value,
										attribute_units,
										determined_date,
										determined_by_agent_id,
										attribute_remark
									) VALUES (
										<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#part_collection_object_id#">,
										<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.part_att_name_2#">,
										<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.part_att_val_2#">,
										<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.part_att_units_2#">,
										<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.part_att_madedate_2#">,
										<cfif numAgentId EQ "NULL">
											NULL,
										<cfelse>
											<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#numAgentId#">,
										</cfif>
										<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.part_att_rem_2#">
									)
								</cfquery>
							</cfif>
							<cfif len(#part_att_name_3#) GT 0>
								<cfif len(#part_att_detby_3#) GT 0>
									<cfquery name="a" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
										SELECT agent_id 
										FROM agent_name 
										WHERE agent_name = trim(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#part_att_detby_3#">)
									</cfquery>
									<cfset numAgentID = a.agent_id>
								<cfelse>
									<cfset  numAgentID = "NULL">
								</cfif>
								<cfquery name="addPartAtt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									INSERT INTO SPECIMEN_PART_ATTRIBUTE (
										collection_object_id,
										attribute_type,
										attribute_value,
										attribute_units,
										determined_date,
										determined_by_agent_id,
										attribute_remark
									) VALUES (
										<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#part_collection_object_id#">,
										<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.part_att_name_3#">,
										<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.part_att_val_3#">,
										<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.part_att_units_3#">,
										<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.part_att_madedate_3#">,
										<cfif numAgentId EQ "NULL">
											NULL,
										<cfelse>
											<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#numAgentId#">,
										</cfif>
										<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.part_att_rem_3#">
									)
								</cfquery>
							</cfif>
							<cfif len(#part_att_name_4#) GT 0>
								<cfif len(#part_att_detby_4#) GT 0>
									<cfquery name="a" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
										SELECT agent_id 
										FROM agent_name 
										WHERE agent_name = trim(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#part_att_detby_4#">)
									</cfquery>
									<cfset numAgentID = a.agent_id>
								<cfelse>
									<cfset  numAgentID = "NULL">
								</cfif>
								<cfquery name="addPartAtt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									INSERT INTO SPECIMEN_PART_ATTRIBUTE (
										collection_object_id,
										attribute_type,
										attribute_value,
										attribute_units,
										determined_date,
										determined_by_agent_id,
										attribute_remark
									) VALUES (
										<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#part_collection_object_id#">,
										<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.part_att_name_4#">,
										<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.part_att_val_4#">,
										<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.part_att_units_4#">,
										<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.part_att_madedate_4#">,
										<cfif numAgentId EQ "NULL">
											NULL,
										<cfelse>
											<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#numAgentId#">,
										</cfif>
										<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.part_att_rem_4#">
									)
								</cfquery>
							</cfif>
							<cfif len(#part_att_name_5#) GT 0>
								<cfif len(#part_att_detby_5#) GT 0>
									<cfquery name="a" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
										SELECT agent_id 
										FROM agent_name 
										WHERE agent_name = trim(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#part_att_detby_5#">)
									</cfquery>
									<cfset numAgentID = a.agent_id>
								<cfelse>
									<cfset  numAgentID = "NULL">
								</cfif>
								<cfquery name="addPartAtt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									INSERT INTO SPECIMEN_PART_ATTRIBUTE (
										collection_object_id,
										attribute_type,
										attribute_value,
										attribute_units,
										determined_date,
										determined_by_agent_id,
										attribute_remark
									) VALUES (
										<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#part_collection_object_id#">,
										<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.part_att_name_5#">,
										<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.part_att_val_5#">,
										<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.part_att_units_5#">,
										<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.part_att_madedate_5#">,
										<cfif numAgentId EQ "NULL">
											NULL,
										<cfelse>
											<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#numAgentId#">,
										</cfif>
										<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.part_att_rem_5#">
									)
								</cfquery>
							</cfif>
							<cfif len(#part_att_name_6#) GT 0>
								<cfif len(#part_att_detby_6#) GT 0>
									<cfquery name="a" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
										SELECT agent_id 
										FROM agent_name 
										WHERE agent_name = trim(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#part_att_detby_6#">)
									</cfquery>
									<cfset numAgentID = a.agent_id>
								<cfelse>
									<cfset  numAgentID = "NULL">
								</cfif>
								<cfquery name="addPartAtt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									INSERT INTO SPECIMEN_PART_ATTRIBUTE (
										collection_object_id,
										attribute_type,
										attribute_value,
										attribute_units,
										determined_date,
										determined_by_agent_id,
										attribute_remark
									) VALUES (
										<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#part_collection_object_id#">,
										<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.part_att_name_6#">,
										<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.part_att_val_6#">,
										<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.part_att_units_6#">,
										<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.part_att_madedate_6#">,
										<cfif numAgentId EQ "NULL">
											NULL,
										<cfelse>
											<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#numAgentId#">,
										</cfif>
										<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.part_att_rem_6#">
									)
								</cfquery>
							</cfif>
						<cfset part_updates = part_updates + updateColl_result.recordcount>
					</cfif>
				</cfloop>
					<h3 class="mt-3">There were #part_updates# parts in #updateColl_result.recordcount# specimen records updated.</h3>
					<h3><span class="text-success">Success!</span> Parts loaded.
						<a href="https://mczbase-test.rc.fas.harvard.edu/Specimens.cfm?execute=true&builderMaxRows=1&action=builderSearch&openParens1=0&field1=COLL_OBJECT%3ACOLL_OBJ_COLLECTION_OBJECT_ID&searchText1=#encodeForUrl(valuelist(getTempData.collection_object_id))#&closeParens1=0" class="btn-link font-weight-lessbold">
							See in Specimen Search Results.
						</a>
					</h3>
					<cftransaction action="commit">
				<cfcatch>
					<cftransaction action="ROLLBACK">
					<h3>There was a problem updating the specimen parts. </h3>
					<cfquery name="getProblemData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						SELECT *
						FROM cf_temp_edit_parts
						WHERE key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#problem_key#">
					</cfquery>
					<cfif getProblemData.recordcount GT 0>
						<h3>
							Fix the issues and <a href="/tools/BulkloadEditedParts.cfm">start again</a>. Error loading row (<span class="text-danger">#part_updates + 1#</span>) from the CSV: 
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
										Invalid disposition
									<cfelseif cfcatch.detail contains "part_name">
										Invalid part_name
									<cfelseif cfcatch.detail contains "part_value">
										Invalid part_value
									<cfelseif cfcatch.detail contains "unique constraint">
										This change has already been entered. Remove from spreadsheet and try again. (<a href="/tools/BulkloadEditedParts.cfm">Reload.</a>)
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
									<th>DISPOSITION</th>
									<th>LOT_COUNT_MODIFIER</th>
									<th>LOT_COUNT</th>
									<th>CURRENT_REMARKS</th>
									<th>CONDITION</th>
									<th>CONTAINER_UNIQUE_ID</th>
									<th>APPEND_TO_REMARKS</th>
									<th>CHANGED_DATE</td>
									<th>NEW_PRESERVE_METHOD</th>
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
										<td>#getProblemData.CURRENT_REMARKS#</td>
										<td>#getProblemData.CONDITION#</td>
										<td>#getProblemData.CONTAINER_UNIQUE_ID# </td>
										<td>#getProblemData.APPEND_TO_REMARKS#</td>
										<td>#getProblemData.CHANGED_DATE#</td>
										<td>#getProblemData.NEW_PRESERVE_METHOD#</td>
										<td>#getProblemData.part_att_name_1#</td>
										<td>#getProblemData.part_att_val_1#</td>
										<td>#getProblemData.part_att_units_1#</td>
										<td>#getProblemData.part_att_detby_1#</td>
										<td>#getProblemData.part_att_madedate_1#</td>
										<td>#getProblemData.part_att_rem_1#</td>
										<td>#getProblemData.part_att_name_2#</td>
										<td>#getProblemData.part_att_val_2#</td>
										<td>#getProblemData.part_att_units_2#</td>
										<td>#getProblemData.part_att_detby_2#</td>
										<td>#getProblemData.part_att_madedate_2#</td>
										<td>#getProblemData.part_att_rem_2#</td>
										<td>#getProblemData.part_att_name_3#</td>
										<td>#getProblemData.part_att_val_3#</td>
										<td>#getProblemData.part_att_units_3#</td>
										<td>#getProblemData.part_att_detby_3#</td>
										<td>#getProblemData.part_att_madedate_3#</td>
										<td>#getProblemData.part_att_rem_3#</td>
										<td>#getProblemData.part_att_name_4#</td>
										<td>#getProblemData.part_att_val_4#</td>
										<td>#getProblemData.part_att_units_4#</td>
										<td>#getProblemData.part_att_detby_4#</td>
										<td>#getProblemData.part_att_madedate_4#</td>
										<td>#getProblemData.part_att_rem_4#</td>
										<td>#getProblemData.part_att_name_5#</td>
										<td>#getProblemData.part_att_val_5#</td>
										<td>#getProblemData.part_att_units_5#</td>
										<td>#getProblemData.part_att_detby_5#</td>
										<td>#getProblemData.part_att_madedate_5#</td>
										<td>#getProblemData.part_att_rem_5#</td>
										<td>#getProblemData.part_att_name_6#</td>
										<td>#getProblemData.part_att_val_6#</td>
										<td>#getProblemData.part_att_units_6#</td>
										<td>#getProblemData.part_att_detby_6#</td>
										<td>#getProblemData.part_att_madedate_6#</td>
										<td>#getProblemData.part_att_rem_6#</td>
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
				DELETE FROM cf_temp_edit_parts
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
		</cfoutput>
	</cfif>
</main>
<cfinclude template="/shared/_footer.cfm">
