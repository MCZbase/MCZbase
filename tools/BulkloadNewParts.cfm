<!--- tools/bulkloadNewParts.cfm add parts to specimens in bulk.

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
<cfif isDefined("action") AND action is "dumpProblems">
	<cfquery name="getProblemData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		SELECT use_existing,institution_acronym,collection_cde,other_id_type,other_id_number,
			part_name,preserve_method,lot_count_modifier,lot_count,condition,coll_obj_disposition
		FROM cf_temp_parts
		WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			and use_existing=0
		ORDER BY key
	</cfquery>
	<cfinclude template="/shared/component/functions.cfc"><!---need to add to functions.cfc page--->
	<cfset csv = queryToCSV(getProblemData)>
	<cfheader name="Content-Type" value="text/csv">
	<cfoutput>#csv#</cfoutput>
	<cfabort>
</cfif>

<cfset fieldlist = "INSTITUTION_ACRONYM,COLLECTION_CDE,OTHER_ID_TYPE,OTHER_ID_NUMBER,CONTAINER_UNIQUE_ID,PART_NAME,PRESERVE_METHOD,LOT_COUNT_MODIFIER,LOT_COUNT,CONDITION,COLL_OBJ_DISPOSITION,CURRENT_REMARKS,PART_ATT_NAME_1,PART_ATT_VAL_1,PART_ATT_UNITS_1,PART_ATT_DETBY_1,PART_ATT_MADEDATE_1,PART_ATT_REM_1,PART_ATT_NAME_2,PART_ATT_VAL_2,PART_ATT_UNITS_2,PART_ATT_DETBY_2,PART_ATT_MADEDATE_2,PART_ATT_REM_2,PART_ATT_NAME_3,PART_ATT_VAL_3,PART_ATT_UNITS_3,PART_ATT_DETBY_3,PART_ATT_MADEDATE_3,PART_ATT_REM_3,PART_ATT_NAME_4,PART_ATT_VAL_4,PART_ATT_UNITS_4,PART_ATT_DETBY_4,PART_ATT_MADEDATE_4,PART_ATT_REM_4,PART_ATT_NAME_5,PART_ATT_VAL_5,PART_ATT_UNITS_5,PART_ATT_DETBY_5,PART_ATT_MADEDATE_5,PART_ATT_REM_5,PART_ATT_NAME_6,PART_ATT_VAL_6,PART_ATT_UNITS_6,PART_ATT_DETBY_6,PART_ATT_MADEDATE_6,PART_ATT_REM_6">
<cfset fieldTypes ="CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_DATE,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_DATE,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_DATE,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_DATE,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_DATE,CF_SQL_VARCHAR">
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
			<p>This tool adds part rows to the specimen record. It create metadata for part history and includes specimen part attributes fields that can be empty if none exists. The cataloged items must be in the database and they can be entered using the catalog number or other ID. Error messages will appear if the values need to match values in MCZbase. It ignores rows that are exactly the same and alerts you if columns are missing. Additional columns will be ignored. Include column headings, spelled exactly as below. </p>
			<span class="btn btn-xs btn-info" onclick="document.getElementById('template').style.display='block';">View template</span>
			<div id="template" style="display:none;margin: 1em 0;">
				<label for="templatearea" class="data-entry-label">
					Copy this header line and save it as a .csv file (<a href="/tools/BulkloadNewParts.cfm?action=getCSVHeader" class="font-weight-lessbold">download</a>)
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
					<cfset TABLE_NAME = "CF_TEMP_PARTS">
					<cftry>
						<!--- cleanup any incomplete work by the same user --->
						<cfquery name="clearTempTable" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="clearTempTable_result">
							DELETE FROM cf_temp_parts 
							WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
							and use_existing = 0
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
									<cfset error_message="#COLUMN_ERR# from line #row# in input file.  
									<div class='mb-2 h4 font-weight-normal align-items-start align-items list-group list-group-horizontal flex-wrap col-12 small'>Header:[#colNames#]</div>   <div class='mb-2 h4 font-weight-normal align-items-start align-items list-group list-group-horizontal flex-wrap col-12 small'>Row:[#ArrayToList(collValuesArray)#] </div>Error: This is the GET FILE SECTION#cfcatch.message#"><!--- " --->
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
								Successfully read #loadedRows# records from the CSV file.  Next <a href="/tools/BulkloadNewParts.cfm?action=validate" class="font-weight-lessbold btn-link">click to validate</a>.
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
							status = null,
							use_existing=0
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
							status = null,
							use_existing = 0
						WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
							and key = <cfqueryparam cfsqltype="CF_SQL_decimal" value="#getTempTableTypes.key#"> 
					</cfquery>
				</cfif>
				<cfset i= i+1>
			</cfloop>
			<!--- obtain the information needed to QC each row --->
			<cfquery name="getTempTableQC" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT 
					collection_object_id,collection_cde,key
				FROM 
					cf_temp_parts
				WHERE 
					username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
					and use_existing = 0
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
				<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					update cf_temp_parts set status = concat(nvl2(status, status || '; ', ''),'Invalid part_name')
					where part_name|| '|' ||collection_cde NOT IN (
						select part_name|| '|' ||collection_cde from ctspecimen_part_name
						)
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
					AND key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableQC.key#">
				</cfquery>
				<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					update cf_temp_parts set status = concat(nvl2(status, status || '; ', ''),'Invalid preserve_method')
					where preserve_method|| '|' ||collection_cde NOT IN (
						select preserve_method|| '|' ||collection_cde from ctspecimen_preserv_method
						)
						OR preserve_method is null
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
					AND key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableQC.key#">
				</cfquery>
				<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					update cf_temp_parts set status = concat(nvl2(status, status || '; ', ''),'Invalid container_unique_id')
					where container_unique_id NOT IN (
						select barcode from container where barcode is not null
						)
					AND container_unique_id is not null
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
					AND key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableQC.key#">
				</cfquery>
				<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					update cf_temp_parts set status = concat(nvl2(status, status || '; ', ''),'Invalid DISPOSITION')
					where COLL_OBJ_DISPOSITION NOT IN (select COLL_OBJ_DISPOSITION from CTCOLL_OBJ_DISP)
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
					AND key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableQC.key#">
				</cfquery>
				<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					update cf_temp_parts set status = concat(nvl2(status, status || '; ', ''),'Invalid CONDITION')
					where CONDITION is null
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
					AND key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableQC.key#">
				</cfquery>
				<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					update cf_temp_parts set status = concat(nvl2(status, status || '; ', ''),'invalid lot_count_modifier')
					where lot_count_modifier NOT IN (
						select modifier from ctnumeric_modifiers
						)
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
					AND key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableQC.key#">
				</cfquery>
				<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					update cf_temp_parts set status = concat(nvl2(status, status || '; ', ''),'Invalid LOT_COUNT')
					where (
						LOT_COUNT is null OR
						is_number(lot_count) = 0
						)
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
					AND key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableQC.key#">
				</cfquery>
					<cfloop index="i" from="1" to="6">
						<cfquery name="chkPAtt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							update cf_temp_parts set 
							status = concat(nvl2(status, status || '; ', ''),'Invalid part attribute <span class="font-weight-bold">"'||PART_ATT_NAME_#i#||'"</span>')
							where PART_ATT_NAME_#i# not in (select attribute_type from CTSPECPART_ATTRIBUTE_TYPE) 
							and PART_ATT_NAME_#i# is not null
							AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
							AND key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableQC.key#">
						</cfquery>	
						<cfquery name="chkPAtt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							update cf_temp_parts set 
							status = concat(nvl2(status, status || '; ', ''),'"'||PART_ATT_VAL_#i#||'" is required when <span class="font-weight-bold">"'||PART_ATT_NAME_#i#||'"</span>')
							where PART_ATT_NAME_#i# is not null and PART_ATT_VAL_#i# is null
							AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
							AND key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableQC.key#">
						</cfquery>	
						<cfquery name="chkPAttCT" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							SELECT cf_temp_parts.part_att_name_#i#,cf_temp_parts.part_att_val_#i#,
								cf_temp_parts.collection_cde,
								ctspecpart_attribute_type.attribute_type,
								decode(value_code_table, null, unit_code_table,value_code_table) code_table 
							FROM ctspecpart_att_att, cf_temp_parts 
							WHERE attribute_type = '||PART_ATT_NAME_#i#||'
							AND cf_temp_parts.part_att_name_#i# = attribute_type
							and cf_temp_parts.part_att_val_#i# is not null
							AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
							AND key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableQC.key#">
						</cfquery>
						<cfset partAttName = '||chkPAttCT.part_att_name_#i#||'>
						<cfset partAttVal = '||chkPAttCT.part_att_val_#i#||'>
						<cfset partAttCollCde = #chkPAttCT.collection_cde#>
						<cfloop query="chkPAttCT">
							<cfquery name="chkPAtt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
								update cf_temp_parts set status = concat(nvl2(status, status || '; ', ''),'part attribute value <span class="font-weight-bold">#partAttVal#</span> not in codetable')
								where chk_specpart_att_codetables(partAttName,partAttVal,partAttCollCde)=0
								and #partAttName# is not null
								and #partAttVal# = '||#chkPAttCT.attribute_type#||'
								AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
								AND key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableQC.key#">
							</cfquery>
						</cfloop>
						<!---TODO: ABOVE. Fix type/value/units relationship check (chk_specpart_att_codetable)--->
						<cfquery name="chkPAtt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							update cf_temp_parts set 
							status = concat(nvl2(status, status || '; ', ''),'Invalid PART_ATT_MADEDATE_#i# "'||PART_ATT_MADEDATE_#i#||'"') WHERE PART_ATT_NAME_#i# is not null 
							AND is_iso8601(PART_ATT_MADEDATE_#i#) <> '' 
							AND length(PART_ATT_MADEDATE_#i#) <> 10
							AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
							AND key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableQC.key#">
						</cfquery>
						<cfquery name="chkPAtt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							update cf_temp_parts set status = concat(nvl2(status, status || '; ', ''),'Invalid scientific name <span class="font-weight-bold">"'||PART_ATT_VAL_#i#||'"</span>') 
							where PART_ATT_NAME_#i# = 'scientific name'
							AND regexp_replace(PART_ATT_VAL_#i#, ' (\?|sp.)$', '') in
							(select scientific_name from taxonomy group by scientific_name having count(*) > 1)
							AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
							AND key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableQC.key#">
						</cfquery>
						<cfquery name="chkPAtt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							update cf_temp_parts set status = status || 'scientific name (' ||PART_ATT_VAL_#i# ||') does not exist'
							where PART_ATT_NAME_#i# = 'scientific name'
							AND regexp_replace(PART_ATT_VAL_#i#, ' (\?|sp.)$', '') not in
							(select scientific_name from taxonomy group by scientific_name having count(*) = 1)
							AND PART_ATT_VAL_#i# is not null
							and (status not like '%scientific name ('||PART_ATT_VAL_#i#||') matched multiple taxonomy records%' or status is null)
							AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
							AND key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableQC.key#">
						</cfquery>
						<cfquery name="chkPAtt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							update cf_temp_parts set 
							status = concat(nvl2(status, status || '; ', ''),'scientific name cannot be null')
							where PART_ATT_NAME_#i# = 'scientific name' AND PART_ATT_VAL_#i# is null
							AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
							AND key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableQC.key#">
						</cfquery>
						<cfquery name="chkPAtt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							update cf_temp_parts set 
							status = concat(nvl2(status, status || '; ', ''),'<span class="font-weight-bold">Invalid part attribute determiner <span class="font-weight-bold">"'||PART_ATT_DETBY_#i#||'"</span>')
							where PART_ATT_DETBY_#i# not in (select agent_name from preferred_agent_name where PART_ATT_DETBY_#i# = preferred_agent_name.agent_name)  
							AND PART_ATT_NAME_#i# is not null
							AND PART_ATT_DETBY_#i# is not null
							AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
							AND key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableQC.key#">
						</cfquery>
						<cfquery name="chkPAtt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							update cf_temp_parts set 
							status = concat(nvl2(status, status || '; ', ''),'Invalid PART_ATT_NAME "'||PART_ATT_NAME_#i#||'" does not match MCZbase')
							where PART_ATT_NAME_#i# not in (select attribute_type from ctspecpart_attribute_type) 
							AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
							AND key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableQC.key#">
						</cfquery>
						<cfquery name="chkPAtt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							update cf_temp_parts set status = concat(nvl2(status, status || '; ', ''), 'PART_ATT_UNITS_#i# is not valid for attribute "'||PART_ATT_NAME_#i#||'". See code table.')
							where MCZBASE.CHK_SPECPART_ATT_CODETABLES(PART_ATT_NAME_#i#,PART_ATT_UNITS_#i#,COLLECTION_CDE)=0
							and PART_ATT_NAME_#i# in
							(select attribute_type from ctspecpart_att_att where unit_code_table is not null)
							AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
							AND key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableQC.key#">
						</cfquery>
					</cfloop>
					<cfquery name="chk" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						update cf_temp_parts set status = (select decode(parent_container_id,0,'','')
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
					<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						update cf_temp_parts set (parent_container_id) = (
						select container_id
						from container where
						barcode=container_unique_id)
						where status = ''
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						AND key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableQC.key#">
					</cfquery>
					<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						update cf_temp_parts set (use_part_id) = (
						select min(specimen_part.collection_object_id)
						from specimen_part, coll_object_remark where
						specimen_part.collection_object_id = coll_object_remark.collection_object_id(+) AND
						cf_temp_parts.part_name=specimen_part.part_name and
						cf_temp_parts.preserve_method=specimen_part.preserve_method and
						cf_temp_parts.collection_object_id=specimen_part.derived_from_cat_item and
						nvl(cf_temp_parts.current_remarks, 'NULL') = nvl(coll_object_remark.coll_object_remarks, 'NULL'))
						where status like '%NOTE: PART EXISTS%' AND use_existing = 1
					</cfquery>
				</cfloop>
				<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT *
					FROM cf_temp_parts
					WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
					and use_existing = 0
					ORDER BY key
				</cfquery>
				<cfquery name="allValid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					select count(*) as cnt from cf_temp_parts
					where status is not null
				</cfquery>
				<h3 class="mt-3">
				<cfif #allValid.cnt# is 0>
					<span class="text-success">Validation checks passed</span>. Look over the table below and <a href="BulkloadNewParts.cfm?action=load" class="font-weight-lessbold btn-link">click to continue</a> if it all looks good. Or, <a href="/tools/BulkloadNewParts.cfm" class="text-danger">start again</a>.
				<cfelse>
					You must fix everything above to proceed. <a href="/tools/BulkloadNewParts.cfm" class="text-danger font-weight-lessbold">Start again.</a>
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
								<td><cfif len(data.status) eq 0>Cleared to load<cfelse><strong>#data.status#</strong></cfif></td>
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
				<h2 class="h4">Third step: Apply changes</h2>
				<cfset problem_key = "">
				<cftransaction>
				<cfquery name="getTempData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					select * from cf_temp_parts where status is null
				</cfquery>
				<cfquery name= "getEntBy" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT agent_id FROM agent_name WHERE agent_name = '#session.username#'
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
					<cfset part_updates1 = 0>
					<cfloop query="getTempData">
						<cfif len(#use_part_id#) is 0>
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
									#NEXTID.NEXTID#,
									'SP',
									'#enteredbyid#',
									sysdate,
									'#enteredbyid#',
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
									#NEXTID.NEXTID#,
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.PART_NAME#">,
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.PRESERVE_METHOD#">,
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.collection_object_id#">)
							</cfquery>
							<cfif len(#current_remarks#) gt 0>
									<!---- new remark --->
									<cfquery name="newCollRem" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
										INSERT INTO coll_object_remark (
										collection_object_id, 
										coll_object_remarks
										) VALUES (
										sq_collection_object_id.currval, 
										<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.current_remarks#">)
									</cfquery>
							</cfif>
							<cfif len(#changed_date#) gt 0>
								<cfquery name="change_date" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									update SPECIMEN_PART_PRES_HIST 
									set CHANGED_DATE = to_date('#CHANGED_DATE#', 'YYYY-MM-DD') 
									where collection_object_id =#NEXTID.NEXTID# 
									and is_current_fg = 1
								</cfquery>
							</cfif>
							<cfif len(#container_unique_id#) gt 0>
								<cfquery name="part_container_id" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									select container_id 
									from coll_obj_cont_hist 
									where collection_object_id = #NEXTID.NEXTID#
								</cfquery>
									<cfquery name="upPart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
										update container set 
											parent_container_id=#parent_container_id#
										where 
											container_id = #part_container_id.container_id#
									</cfquery>
								<cfif #len(change_container_type)# gt 0>
									<cfquery name="upPart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
										update container set
										container_type='#change_container_type#'
										where container_id=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.parent_container_id#">
									</cfquery>
								</cfif>
							</cfif>
							<cfif len(#part_att_name_1#) GT 0>
								<cfif len(#part_att_detby_1#) GT 0>
									<cfquery name="a" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
										select agent_id from agent_name where agent_name = trim('#part_att_detby_1#')
									</cfquery>
									<cfset numAgentID = a.agent_id>
								<cfelse>
									<cfset  numAgentID = "NULL">
								</cfif>
								<cfquery name="addPartAtt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									insert into SPECIMEN_PART_ATTRIBUTE(
									collection_object_id, attribute_type, attribute_value, attribute_units, determined_date, determined_by_agent_id, attribute_remark
									) values (
									sq_collection_object_id.currval, 
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.part_att_name_1#">, 
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.part_att_val_1#">, 
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.part_att_units_1#">, 
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.part_att_madedate_1#">, 
									'#numAgentId#', 
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.part_att_rem_1#">)
								</cfquery>
							</cfif>
							<cfif len(#part_att_name_2#) GT 0>
								<cfif len(#part_att_detby_2#) GT 0>
									<cfquery name="a" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
										select agent_id from agent_name where agent_name = trim('#part_att_detby_2#')
									</cfquery>
									<cfset numAgentID = a.agent_id>
								<cfelse>
									<cfset  numAgentID = "NULL">
								</cfif>
								<cfquery name="addPartAtt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									insert into SPECIMEN_PART_ATTRIBUTE(
									collection_object_id, attribute_type, attribute_value, attribute_units, determined_date, determined_by_agent_id, attribute_remark
									) values (
									sq_collection_object_id.currval, 
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.part_att_name_2#">, 
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.part_att_val_2#">, 
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.part_att_units_2#">, 
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.part_att_madedate_2#">, 
									'#numAgentId#',
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.part_att_rem_2#">)
								</cfquery>
							</cfif>
							<cfif len(#part_att_name_3#) GT 0>
								<cfif len(#part_att_detby_3#) GT 0>
									<cfquery name="a" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
										select agent_id from agent_name where agent_name = trim('#part_att_detby_3#')
									</cfquery>
									<cfset numAgentID = a.agent_id>
								<cfelse>
									<cfset  numAgentID = "NULL">
								</cfif>
								<cfquery name="addPartAtt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									insert into SPECIMEN_PART_ATTRIBUTE(
									collection_object_id, attribute_type, attribute_value, attribute_units, determined_date, determined_by_agent_id, attribute_remark
									) values (
									sq_collection_object_id.currval, 
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.part_att_name_3#">, 
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.part_att_val_3#">, 
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.part_att_units_3#">, 
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.part_att_madedate_3#">, 
									'#numAgentId#',
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.part_att_rem_3#">)
								</cfquery>
							</cfif>
							<cfif len(#part_att_name_4#) GT 0>
								<cfif len(#part_att_detby_4#) GT 0>
									<cfquery name="a" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
										select agent_id from agent_name where agent_name = trim('#part_att_detby_4#')
									</cfquery>
									<cfset numAgentID = a.agent_id>
								<cfelse>
									<cfset  numAgentID = "NULL">
								</cfif>
								<cfquery name="addPartAtt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									insert into SPECIMEN_PART_ATTRIBUTE(
									collection_object_id, attribute_type, attribute_value, attribute_units, determined_date, determined_by_agent_id, attribute_remark
									) values (
									sq_collection_object_id.currval, 
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.part_att_name_4#">, 
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.part_att_val_4#">, 
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.part_att_units_4#">, 
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.part_att_madedate_4#">, 
									'#numAgentId#',
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.part_att_rem_4#">)
								</cfquery>
							</cfif>
							<cfif len(#part_att_name_5#) GT 0>
								<cfif len(#part_att_detby_5#) GT 0>
									<cfquery name="a" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
										select agent_id from agent_name where agent_name = trim('#part_att_detby_5#')
									</cfquery>
									<cfset numAgentID = a.agent_id>
								<cfelse>
									<cfset  numAgentID = "NULL">
								</cfif>
								<cfquery name="addPartAtt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									insert into SPECIMEN_PART_ATTRIBUTE(
									collection_object_id, attribute_type, attribute_value, attribute_units, determined_date, determined_by_agent_id, attribute_remark
									) values (
									sq_collection_object_id.currval, 
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.part_att_name_5#">, 
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.part_att_val_5#">, 
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.part_att_units_5#">, 
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.part_att_madedate_5#">, 
									'#numAgentId#', 
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.part_att_rem_5#">)
								</cfquery>
							</cfif>
							<cfif len(#part_att_name_6#) GT 0>
								<cfif len(#part_att_detby_6#) GT 0>
									<cfquery name="a" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
										select agent_id from agent_name where agent_name = trim('#part_att_detby_6#')
									</cfquery>
									<cfset numAgentID = a.agent_id>
								<cfelse>
									<cfset  numAgentID = "NULL">
								</cfif>
								<cfquery name="addPartAtt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									insert into SPECIMEN_PART_ATTRIBUTE(
									collection_object_id, attribute_type, attribute_value, attribute_units, determined_date, determined_by_agent_id, attribute_remark
									) values (
									sq_collection_object_id.currval, 
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.part_att_name_6#">, 
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.part_att_val_6#">, 
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.part_att_units_6#">, 
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.part_att_madedate_6#">, 
									'#numAgentId#', 
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.part_att_rem_6#">)
								</cfquery>
							</cfif>
						<cfelse>
						<!--- there is an existing matching container that is not in a parent_container;
							all we need to do is move the container to a parent IF it exists and is specified, or nothing otherwise --->
							<cfif len(#coll_obj_disposition#) gt 0>
								<cfquery name="upDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									update coll_object set 
									COLL_OBJ_DISPOSITION = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.coll_obj_disposition#"> 
									where collection_object_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.use_part_id#">
								</cfquery>
							</cfif>
							<cfif len(#condition#) gt 0>
								<cfquery name="upCond" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									update coll_object set 
									condition = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.condition#">
									where collection_object_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.use_part_id#">
								</cfquery>
							</cfif>
							<cfif len(#lot_count#) gt 0>
								<cfquery name="upCond" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									update coll_object set 
									lot_count = #lot_count#, 
									lot_count_modifier='#lot_count_modifier#' 
									where collection_object_id = #use_part_id#
								</cfquery>
							</cfif>
							<cfif len(#new_preserve_method#) gt 0>
								<cfquery name="change_preservemethod" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									update SPECIMEN_PART set 
									PRESERVE_METHOD = '#NEW_PRESERVE_METHOD#' 
									where collection_object_id =#use_part_id#
								</cfquery>
							</cfif>
							<cfif len(#append_to_remarks#) gt 0>
								<cfquery name="remarksCount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									select * from coll_object_remark 
									where collection_object_id = #use_part_id#
								</cfquery>
								<cfif remarksCount.recordcount is 0>
									<cfquery name="insertRemarks" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
										INSERT INTO coll_object_remark 
										(collection_object_id, coll_object_remarks)
										VALUES 
										(#use_part_id#, '#append_to_remarks#')
									</cfquery>
								<cfelse>
									<cfquery name="updateRemarks" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
										update coll_object_remark
										set coll_object_remarks = DECODE(coll_object_remarks, null, '#append_to_remarks#', coll_object_remarks || '; #append_to_remarks#')
										where collection_object_id = #use_part_id#
									</cfquery>
								</cfif>
							</cfif>
							<cfif len(#container_unique_id#) gt 0>
								<cfquery name="part_container_id" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									select container_id from coll_obj_cont_hist where collection_object_id = #use_part_id#
								</cfquery>
									<cfquery name="upPart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
										update container set parent_container_id=#parent_container_id#
										where container_id = #part_container_id.container_id#
									</cfquery>
								<cfif #len(change_container_type)# gt 0>
									<cfquery name="upPart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
										update container set
										container_type='#change_container_type#'
										where container_id=#parent_container_id#
									</cfquery>
								</cfif>
							</cfif>
							<cfif len(#changed_date#) gt 0>
								<cfquery name="change_date" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									update SPECIMEN_PART_PRES_HIST set 
									CHANGED_DATE = to_date('#CHANGED_DATE#', 'YYYY-MM-DD') 
									where collection_object_id =#use_part_id# 
									and is_current_fg = 1
								</cfquery>
							</cfif>
							<cfset part_updates = part_updates + updateColl_result.recordcount>
						</cfif>
						<cfquery name="upLoaded" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							update cf_temp_parts set status = ''
						</cfquery>
					</cfloop>
					<cfif updateColl_result.recordcount eq 1>
						<cfset plur= "">
					<cfelse>
					<cfset plur = "s">
					</cfif>
					<h3 class="mt-3"> #updateColl_result.recordcount# specimen record#plur# was updated.</h3>
					<h3><span class="text-success">Success!</span> Parts loaded.
					<a href="/SpecimenResults.cfm?collection_object_id=#valuelist(getTempData.collection_object_id)#" class="btn-link font-weight-lessbold">
						See in Specimen Results.
					</a>
					</h3>
					<cftransaction action="commit">
				<cfcatch>
					<cftransaction action="ROLLBACK">
					<h3>There was a problem updating the specimen parts. </h3>
					<cfquery name="getProblemData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						SELECT *
						FROM cf_temp_parts
						WHERE key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#problem_key#">
							and use_existing = 0
					</cfquery>
					<cfif getProblemData.recordcount GT 0>
						<h3>
							Fix the issues and <a href="/tools/BulkloadNewParts.cfm">start again</a>. Error loading row (<span class="text-danger">#part_updates + 1#</span>) from the CSV: 
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
									<th>DISPOSITION</th>
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
					DELETE FROM cf_temp_parts 
					WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						and use_existing = 0
				</cfquery>
			</cfoutput>
		</cfif>
		</div>
	</div>
</main>
<cfinclude template="/shared/_footer.cfm">
