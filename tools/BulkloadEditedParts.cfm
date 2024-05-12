<!--- tools/bulkloadEditedParts.cfm add citations to specimens in bulk.

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
<!--- special case handling to dump problem data as csv --->
<cfif isDefined("action") AND action is "dumpProblems">
	<cfquery name="getProblemData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		SELECT institution_acronym,collection_cde,other_id_type,other_id_number,part_name,preserve_method,coll_obj_disposition,lot_count_modifier,lot_count,container_unique_id,condition,current_remarks,append_to_remarks,changed_date,new_preserve_method,part_att_name_1,part_att_val_1,part_att_units_1,part_att_detby_1,part_att_madedate_1,part_att_rem_1,part_att_name_2,part_att_val_2,part_att_units_2,part_att_detby_2,part_att_madedate_2,part_att_rem_2,part_att_name_3,part_att_val_3,part_att_units_3,part_att_detby_3,part_att_madedate_3,part_att_rem_3,part_att_name_4,part_att_val_4,part_att_units_4,part_att_detby_4,part_att_madedate_4,part_att_rem_4,part_att_name_5,part_att_val_5,part_att_units_5,part_att_detby_5,part_att_madedate_5,part_att_rem_5,part_att_name_6,part_att_val_6,part_att_units_6,part_att_detby_6,part_att_madedate_6,part_att_rem_6
		FROM cf_temp_citation 
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
<cfset fieldlist = "use_existing,institution_acronym,collection_cde,other_id_type,other_id_number,part_name,preserve_method,coll_obj_disposition,lot_count_modifier,lot_count,container_unique_id,condition,current_remarks,append_to_remarks,changed_date,new_preserve_method,part_att_name_1,part_att_val_1,part_att_units_1,part_att_detby_1,part_att_madedate_1,part_att_rem_1,part_att_name_2,part_att_val_2,part_att_units_2,part_att_detby_2,part_att_madedate_2,part_att_rem_2,part_att_name_3,part_att_val_3,part_att_units_3,part_att_detby_3,part_att_madedate_3,part_att_rem_3,part_att_name_4,part_att_val_4,part_att_units_4,part_att_detby_4,part_att_madedate_4,part_att_rem_4,part_att_name_5,part_att_val_5,part_att_units_5,part_att_detby_5,part_att_madedate_5,part_att_rem_5,part_att_name_6,part_att_val_6,part_att_units_6,part_att_detby_6,part_att_madedate_6,part_att_rem_6">
<cfset fieldTypes ="CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_DATE,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_DATE,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_DATE,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_DATE,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_DATE,CF_SQL_VARCHAR">
<cfset requiredfieldlist = "use_existing,institution_acronym,collection_cde,other_id_type,other_id_number,part_name,preserve_method,coll_obj_disposition,lot_count,condition">
	
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
		<h1 class="h2 mt-2">Bulkload Edited Parts </h1>
		<!------------------------------------------------------->
		<cfif #action# is "nothing">
			<cfoutput>
			<p>This tool adds part rows to the specimen record. It create metadata for part history and includes specimen part fields that can be empty if none exists. The cataloged items must be in the database and they can be entered using the catalog number or other ID. Error messages will appear if the values need to match values in MCZbase. It ignores rows that are exactly the same and alerts you if columns are missing. Additional columns will be ignored. Include column headings, spelled exactly as below. </p>
			<span class="btn btn-xs btn-info" onclick="document.getElementById('template').style.display='block';">View template</span>
			<div id="template" style="display:none;margin: 1em 0;">
				<label for="templatearea" class="data-entry-label">
					Copy this header line and save it as a .csv file (<a href="/tools/BulkloadEditedParts.cfm?action=getCSVHeader">download</a>)
				</label>
				<textarea rows="2" cols="90" id="templatearea" class="w-100 data-entry-textarea">#fieldlist#</textarea>
			</div>
			<h2 class="mt-4 h4">Columns in <span class="text-danger">red</span> are required; others are optional:</h2>
			<ul class="mb-4 small90 font-weight-normal list-group px-3 mx-3">
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
					<li>
						<span class="#class# font-weight-lessbold" #aria#>#field#: </span> <span class="text-secondary">#comment#</span>
					</li>
				</cfloop>
			</ul>
			<form name="atts" method="post" enctype="multipart/form-data" action="/tools/BulkloadEditedParts.cfm">
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
						and use_existing = 1
					</cfquery>
					<cfset variables.foundHeaders =""><!--- populated by loadCsvFile --->
					<cfset variables.size=""><!--- populated by loadCsvFile --->
					<cfset iterator = loadCsvFile(FileToUpload=FileToUpload,format=format,characterSet=characterSet)>			

					<!--- Note: As we can't use csvFormat.withHeader(), we can not match columns by name, we are forced to do so by number, thus arrays --->
					<cfset colNameArray = listToArray(ucase(variables.foundHeaders))><!--- the list of columns/fields found in the input file --->
					<cfset fieldArray = listToArray(ucase(fieldlist))><!--- the full list of fields --->
					<cfset typeArray = listToArray(fieldTypes)><!--- the types for the full list of fields --->
					<div class="col-12 my-4 px-0">
						<h3 class="h4">Found #variables.size# columns in header of csv file.</h3>
						<h3 class="h4">There are #ListLen(fieldList)# columns expected in the header (of these #ListLen(requiredFieldList)# are required).</h3>
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
							you probably want to <strong><a href="/tools/BulkloadEditedParts.cfm">reload</a></strong> this file selecting a different encoding.  If these appear as expected, then 
								you selected the correct encoding and can continue to validate or load.</p>
						</div>
						<ul class="h4 list-unstyled">
							#foundHighAscii# #foundMultiByte#
						</ul>
					</cfif>
					<h3 class="h3">
						<cfif loadedRows EQ 0>
							Loaded no rows from the CSV file.  The file appears to be just a header with no data. Fix file and <a href="/tools/BulkloadNewParts.cfm">reload</a>
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
		<!------------------------Validation------------------------------->
		<cfif #action# is "validate">
		<cfoutput>
			<h2 class="h4">Second step: Data Validation</h2>
			<cfquery name="getParentContainerId" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				update cf_temp_parts set parent_container_id = (select container_id from container where container.barcode = cf_temp_parts.CONTAINER_UNIQUE_ID)
			</cfquery>
			<cfquery name="validateGotParent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				update cf_temp_parts set status = status || ';Container Unique ID not found'
				where CONTAINER_UNIQUE_ID is not null and parent_container_id is null
			</cfquery>
			<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				update cf_temp_parts set status = status || ';Invalid part_name'
				where part_name|| '|' ||collection_cde NOT IN (
					select part_name|| '|' ||collection_cde from ctspecimen_part_name
					)
				OR part_name is null
			</cfquery>
			<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				update cf_temp_parts set status = status || ';Invalid preserve_method'
				where preserve_method|| '|' ||collection_cde NOT IN (
					select preserve_method|| '|' ||collection_cde from ctspecimen_preserv_method
					)
					OR preserve_method is null
			</cfquery>
			<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				update cf_temp_parts set status = status || ';Invalid new_preserve_method'
				where new_preserve_method|| '|' ||collection_cde NOT IN (
					select preserve_method|| '|' ||collection_cde from ctspecimen_preserv_method
					)
					and new_preserve_method is not null
			</cfquery>
			<cfquery name="isValid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				update cf_temp_parts set status = status || ';Invalid use_existing flag'
					where use_existing not in ('0','1') OR
					use_existing is null
			</cfquery>
			<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				update cf_temp_parts set status = status || ';Invalid CONTAINER_UNIQUE_ID'
				where CONTAINER_UNIQUE_ID NOT IN (
					select barcode from container where barcode is not null
					)
				AND CONTAINER_UNIQUE_ID is not null
			</cfquery>
			<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				update cf_temp_parts set status = status || ';Invalid DISPOSITION'
				where DISPOSITION NOT IN (
					select COLL_OBJ_DISPOSITION from CTCOLL_OBJ_DISP
					)
					OR disposition is null
			</cfquery>
			<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				update cf_temp_parts set status = status || ';Invalid CONTAINER_TYPE'
				where change_container_type NOT IN (
					select container_type from ctcontainer_type
					)
					AND change_container_type is null
			</cfquery>
			<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				update cf_temp_parts set status = status || ';Invalid CONDITION'
				where CONDITION is null
			</cfquery>
			<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				update cf_temp_parts set status = status || ';invalid lot_count_modifier'
				where lot_count_modifier NOT IN (
					select modifier from ctnumeric_modifiers
					)
			</cfquery>
			<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				update cf_temp_parts set status = status || ';Invalid LOT_COUNT'
				where (
					LOT_COUNT is null OR
					is_number(lot_count) = 0
					)
			</cfquery>
			<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				update cf_temp_parts set status = status || ';Invalid CHANGED_DATE'
				where isdate(changed_date) = 0
			</cfquery>

			<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				select * from cf_temp_parts where status is null
			</cfquery>
			<cfquery name="getCodeTables" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				select attribute_type, decode(value_code_tables, null, unit_code_tables,value_code_tables) code_table  from ctspecpart_attribute_type
			</cfquery>
			<cfquery name="getTempTableTypes" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT 
					other_id_type, key
				FROM 
					cf_temp_parts
				WHERE 
					username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
					AND use_existing= 1
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
							use_existing=1
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
							use_existing = 1
						WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
							and key = <cfqueryparam cfsqltype="CF_SQL_decimal" value="#getTempTableTypes.key#"> 
					</cfquery>
				</cfif>
				<cfset i= i+1>
			</cfloop>
			<!--- obtain the information needed to QC each row --->
			<cfquery name="getTempTableQC" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT 
					collection_object_id,key
				FROM 
					cf_temp_parts
				WHERE 
					username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
					and use_existing = 1
			</cfquery>
			<cfif #getTempTableQC.recordcount# is 1>
				<cfquery name="insColl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE cf_temp_parts SET collection_object_id = #getTempTableQC.collection_object_id#,
					status=null
					where key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableQC.key#">
				</cfquery>
			<cfelse>
				<cfquery name="insColl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE cf_temp_parts SET status = concat(nvl2(status, status || '; ', ''),'#data.institution_acronym# #data.collection_cde# #data.other_id_type# #data.other_id_number# could not be found.')
					where key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableQC.key#">
				</cfquery>
			</cfif>	
			<!---
			Things that can happen here:
				1) Upload a part that doesn't exist
					Solution: create a new part, optionally put it in a container that they specify in the upload.
				2) Upload a part that already exists
					use_existing is set above to always be 1
					a) use_existing = 1
						1) part is in a container
							Solution: warn them, create new part, optionally put it in a container that they've specified
						 2) part is NOT already in a container
						 	Solution: put the existing part into the new container that they've specified or, if
						 	they haven't specified a new container, ignore this line as it does nothing.
					Supported, in queries, but never used 
					b) use_existing = 0
						1) part is in a container
							Solution: warn them, create a new part, optionally put it in the container they've specified
						2) part is not in a container
							Solution: same: warning and new part
			---->
			<cfquery name="findduplicates" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				update cf_temp_parts 
				set status = concat(nvl2(status, status || '; ', ''),'ERROR: More that one matching part')
				where cf_temp_parts.key in (
					select cf_temp_parts.key
					from cf_temp_parts 
						join specimen_part on  
							cf_temp_parts.part_name=specimen_part.part_name and
							cf_temp_parts.preserve_method=specimen_part.preserve_method and
							cf_temp_parts.collection_object_id=specimen_part.derived_from_cat_item
						left join coll_object_remark on specimen_part.collection_object_id = coll_object_remark.collection_object_id
					where			
						nvl(cf_temp_parts.current_remarks, 'NULL') = nvl(coll_object_remark.coll_object_remarks, 'NULL')
						and use_existing = 1
					group by cf_temp_parts.key
					having count(cf_temp_parts.key) > 1
				)
			</cfquery>
			<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				update cf_temp_parts set status = (
				select
				decode(parent_container_id,
				0,'NOTE: PART EXISTS',
				'NOTE: PART EXISTS IN PARENT CONTAINER')
				from specimen_part,coll_obj_cont_hist,container, coll_object_remark where
				specimen_part.collection_object_id = coll_obj_cont_hist.collection_object_id AND
				coll_obj_cont_hist.container_id = container.container_id AND
				coll_object_remark.collection_object_id(+) = specimen_part.collection_object_id AND
				derived_from_cat_item = cf_temp_parts.collection_object_id AND
				cf_temp_parts.part_name=specimen_part.part_name AND
				cf_temp_parts.preserve_method=specimen_part.preserve_method AND
				nvl(cf_temp_parts.current_remarks, 'NULL') = nvl(coll_object_remark.coll_object_remarks, 'NULL')
				group by parent_container_id)
				where status='VALID'
			</cfquery>
			<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				update cf_temp_parts set parent_container_id = (
				select container_id
				from container where
				barcode=CONTAINER_UNIQUE_ID
				)
				where substr(status,1,5) IN ('VALID','NOTE:')
			</cfquery>
			<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				update cf_temp_parts set (use_part_id) = (
				select min(specimen_part.collection_object_id)
				from specimen_part, coll_object_remark where
				specimen_part.collection_object_id = coll_object_remark.collection_object_id(+) AND
				cf_temp_parts.part_name=specimen_part.part_name and
				cf_temp_parts.preserve_method=specimen_part.preserve_method and
				cf_temp_parts.collection_object_id=specimen_part.derived_from_cat_item and
				nvl(cf_temp_parts.current_remarks, 'NULL') = nvl(coll_object_remark.coll_object_remarks, 'NULL')
				)
				where status like '%NOTE: PART EXISTS%' 
			</cfquery>
			<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				update cf_temp_parts set status = concat(nvl2(status, status || '; ', ''),'PART NOT FOUND') where status is not null
			</cfquery>	
			<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				update cf_temp_parts set status = 'PART NOT FOUND' where status is not null
			</cfquery>
			</cfoutput>
			<cflocation url="/tools/BulkloadEditedParts.cfm?action=checkValidate">
		</cfif>
		<!---------------------------checkValidation-------------------------------->
	
		<cfif #action# is "checkValidate">
			<cfoutput>
			<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT *
				FROM cf_temp_parts
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				and use_existing = 1
				ORDER BY key
			</cfquery>
			<cfquery name="allValid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				select count(*) as cnt from cf_temp_parts where substr(validated_status,1,5) NOT IN
				('VALID','NOTE:')
				<!---select count(*) as cnt from cf_temp_parts
				where status is not null--->
			</cfquery>
			<cfif #allValid.cnt# is 0>
				<h3 class="mt-2"><span class="text-success">Validation checks passed</span>. Look over the table below and <a href="BulkloadEditedParts.cfm?action=load" class="btn-link font-weight-lessbold">click to continue</a> if it all looks good. Or, <a href="/tools/BulkloadEditedParts.cfm" class="font-weight-lessbold text-danger">start again</a>.
				</h3>
			<cfelse>
				<h3 class="mt-2">You must fix everything above to proceed. <a href="/tools/BulkloadEditedParts.cfm" class="text-danger">start again.</a></h3>
			</cfif>
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
						<th>USE_EXISTING</th>
						<th>APPEND_TO_REMARKS</th>
						<th>CHANGED_DATE</th>
						<th>NEW_PRESERVE_METHOD</th>
						<th>USE_PART_ID</th>
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
							<td>
									<cfif len(#collection_object_id#) gt 0 and (#status# is 'VALID')>
						<cfelseif left(status,5) is 'NOTE:'>
							<a href="/SpecimenDetail.cfm?collection_object_id=#collection_object_id#"
								target="_blank">Specimen</a> (#status#)
						<cfelseif left(status,6) is 'ERROR:'>
							<a href="/SpecimenDetail.cfm?collection_object_id=#collection_object_id#"
								target="_blank">Specimen</a> <strong>#status#</strong>
						<cfelse>
							<strong>ERROR: #status#</strong>
						</cfif>
								<!---<cfif len(data.status) eq 0>Cleared to load<cfelse><strong>#data.status#</strong></cfif>---></td>
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
							<td>#use_existing#</td>
							<td>#append_to_remarks#</td>
							<td>#changed_date#</td>
							<td>#new_preserve_method#</td>
							<td>#use_part_id#</td>
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
			
		<!--------------------END checkValidation----------------------------------->
			

				
		<!-------------------------------------------------------------------------------------------->
		<cfif #action# is "load">
			<cfoutput>
				<cfquery name="getTempData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					select * from cf_temp_parts where status is null
				</cfquery>
				<cfquery name= "getEntBy" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
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
						<cfif len(#use_part_id#) is 0 and use_existing is not 1>
							<cfquery name="NEXTID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
								select sq_collection_object_id.nextval NEXTID from dual
							</cfquery>
							<cfquery name="updateColl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
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
							<cfquery name="newTiss" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
								INSERT INTO specimen_part (
									COLLECTION_OBJECT_ID,
									PART_NAME,
									PRESERVE_METHOD,
									DERIVED_FROM_CAT_ITEM )
								VALUES (
									#NEXTID.NEXTID#,
									'#PART_NAME#',
									'#PRESERVE_METHOD#',
									'#COLLECTION_OBJECT_ID#')
							</cfquery>
							<cfif len(#current_remarks#) gt 0>
								<!---- new remark --->
								<cfquery name="newCollRem" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									INSERT INTO coll_object_remark (collection_object_id, coll_object_remarks)
									VALUES (sq_collection_object_id.currval, '#current_remarks#')
								</cfquery>
							</cfif>
							<cfif len(#changed_date#) gt 0>
								<cfquery name="change_date" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									update SPECIMEN_PART_PRES_HIST set CHANGED_DATE = to_date('#CHANGED_DATE#', 'YYYY-MM-DD') where collection_object_id =#NEXTID.NEXTID# and is_current_fg = 1
								</cfquery>
							</cfif>
							<cfif len(#container_unique_id#) gt 0>
								<cfquery name="part_container_id" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									select container_id from coll_obj_cont_hist where collection_object_id = #NEXTID.NEXTID#
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
						<cfelse>
							<cfif len(#disposition#) gt 0>
								<cfquery name="upDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									update coll_object set COLL_OBJ_DISPOSITION = '#disposition#' 
									where collection_object_id = '#use_part_id#'
								</cfquery>
							</cfif>
							<cfif len(#condition#) gt 0>
								<cfquery name="upCond" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									update coll_object set condition = '#condition#' 
									where collection_object_id = '#use_part_id#'
								</cfquery>
							</cfif>
							<cfif len(#lot_count#) gt 0>
								<cfquery name="upCond" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									update coll_object set lot_count = #lot_count#, lot_count_modifier='#lot_count_modifier#'
									where collection_object_id = '#use_part_id#'
								</cfquery>
							</cfif>
							<cfif len(#new_preserve_method#) gt 0>
								<cfquery name="change_preservemethod" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									update SPECIMEN_PART set PRESERVE_METHOD = '#NEW_PRESERVE_METHOD#' 
									where collection_object_id ='#use_part_id#'
								</cfquery>
							</cfif>
							<cfif len(#append_to_remarks#) gt 0>
								<cfquery name="remarksCount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									select * from coll_object_remark where collection_object_id = '#use_part_id#'
								</cfquery>
								<cfif remarksCount.recordcount is 0>
									<cfquery name="insertRemarks" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
										INSERT INTO coll_object_remark (collection_object_id, coll_object_remarks)
										VALUES (#use_part_id#, '#append_to_remarks#')
									</cfquery>
								<cfelse>
									<cfquery name="updateRemarks" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
										update coll_object_remark
										set coll_object_remarks = DECODE(coll_object_remarks, null, '#append_to_remarks#', coll_object_remarks || '; #append_to_remarks#')
										where collection_object_id = '#use_part_id#'
									</cfquery>
								</cfif>
							</cfif>
							<cfif len(#disposition#) gt 0>
								<cfquery name="upDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									update coll_object set COLL_OBJ_DISPOSITION = '#disposition#' where collection_object_id = #use_part_id#
								</cfquery>
							</cfif>
							<cfif len(#condition#) gt 0>
								<cfquery name="upCond" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									update coll_object set condition = '#condition#' where collection_object_id = #use_part_id#
								</cfquery>
							</cfif>
							<cfif len(#lot_count#) gt 0>
								<cfquery name="upCond" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									update coll_object set lot_count = #lot_count#, lot_count_modifier='#lot_count_modifier#' where collection_object_id = #use_part_id#
								</cfquery>
							</cfif>
							<cfif len(#new_preserve_method#) gt 0>
								<cfquery name="change_preservemethod" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									update SPECIMEN_PART set PRESERVE_METHOD = '#NEW_PRESERVE_METHOD#' where collection_object_id =#use_part_id#
								</cfquery>
							</cfif>
							<cfif len(#append_to_remarks#) gt 0>
								<cfquery name="remarksCount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									select * from coll_object_remark where collection_object_id = #use_part_id#
								</cfquery>
								<cfif remarksCount.recordcount is 0>
									<cfquery name="insertRemarks" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
										INSERT INTO coll_object_remark (collection_object_id, coll_object_remarks)
										VALUES (#use_part_id#, '#append_to_remarks#')
									</cfquery>
								<cfelse>
									<cfquery name="updateRemarks" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
										update coll_object_remark
										set coll_object_remarks = DECODE(coll_object_remarks, null, '#append_to_remarks#', coll_object_remarks || '; #append_to_remarks#')
										where collection_object_id = #use_part_id#
									</cfquery>
								</cfif>
							</cfif>
							<cfif len(#CONTAINER_UNIQUE_ID#) gt 0>
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
									update SPECIMEN_PART_PRES_HIST set CHANGED_DATE = to_date('#CHANGED_DATE#', 'YYYY-MM-DD') where collection_object_id =#use_part_id# and is_current_fg = 1
								</cfquery>
							</cfif>
						</cfif>
						<cfquery name="upLoaded" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							update cf_temp_parts set status = ''
						</cfquery>
					</cfloop>
				</cftransaction>
				<cfquery name="clearTempTable" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="clearTempTable_result">
					DELETE FROM cf_temp_parts 
					WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
					and use_existing = 0
				</cfquery>
				<!---insert collection_object_ids into link with a comma between them--->
				<h3><span class="text-success">Success!</span> Parts loaded.</h3>
				<cfif getTempData.recordcount gt 1>
					<a href="/Specimens.cfm?execute=true&builderMaxRows=1&action=builderSearch&nestdepth1=1&field1=COLL_OBJECT%3ACOLL_OBJ_COLLECTION_OBJECT_ID&searchText1=<cfloop query='getTempData'>#getTempData.collection_object_id#,</cfloop>" target="_blank" class="btn-link">
						See records in Specimen Results.
					</a>
				<cfelse>
					<a href="/Specimens.cfm?execute=true&builderMaxRows=1&action=builderSearch&nestdepth1=1&field1=COLL_OBJECT%3ACOLL_OBJ_COLLECTION_OBJECT_ID&searchText1=<cfloop query='getTempData'>#getTempData.collection_object_id#</cfloop>" target="_blank" class="btn-link">
						See records in Specimen Results.
					</a>
				</cfif>
			</cfoutput>
		</cfif>
		</div>
	</div>
</main>
<cfinclude template="/shared/_footer.cfm">