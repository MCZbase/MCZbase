<!--- tools/bulkloadPartContainers.cfm to place collection objects into containers in bulk.

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
<!--- page can submit with action either as a form post parameter or as a url parameter, obtain either into variable scope. --->
<cfif isDefined("url.action")><cfset variables.action = url.action></cfif>
<cfif isDefined("form.action")><cfset variables.action = form.action></cfif>
	
<!--- special case handling to dump problem data as csv --->
<cfif isDefined("action") AND action is "dumpProblems">
	<cfquery name="getProblemData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		SELECT INSTITUTION_ACRONYM,COLLECTION_CDE,OTHER_ID_TYPE,OTHER_ID_NUMBER,PART_NAME,PRESERVE_METHOD,CURRENT_REMARKS,CONTAINER_BARCODE,CURRENT_CONTAINER_BARCODE,PART_COLLECTION_OBJECT_ID,CURRENT_PARENT_CONTAINER_ID,NEW_PARENT_CONTAINER_ID
		FROM cf_temp_barcode_parts
		WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
		ORDER BY key
	</cfquery>
	<cfinclude template="/shared/component/functions.cfc"><!---need to add to functions.cfc page--->
	<cfinclude template="/shared/functionLib.cfm">
	<cfset csv = queryToCSV(getProblemData)>
	<cfheader name="Content-Type" value="text/csv; charset=utf-8">
	<cfoutput>#csv#</cfoutput>
	<cfabort>
</cfif>
<cfset fieldlist = "INSTITUTION_ACRONYM,COLLECTION_CDE,OTHER_ID_TYPE,OTHER_ID_NUMBER,PART_NAME,PRESERVE_METHOD,CURRENT_REMARKS,CONTAINER_BARCODE,CURRENT_CONTAINER_BARCODE,PART_COLLECTION_OBJECT_ID,CURRENT_PARENT_CONTAINER_ID,NEW_PARENT_CONTAINER_ID">
<cfset fieldTypes ="CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_DECIMAL,CF_SQL_DECIMAL,CF_SQL_DECIMAL">
<cfif listlen(fieldlist) NEQ listlen(fieldTypes)>
	<cfthrow message = "Error: Bug in the definition of fieldlist[#listlen(fieldlist)#] and fieldType[#listlen(fieldTypes)#] lists, lists must be the same length, but are not.">
</cfif>
<cfset requiredfieldlist = "OTHER_ID_TYPE,OTHER_ID_NUMBER,COLLECTION_CDE,INSTITUTION_ACRONYM,PART_NAME,PRESERVE_METHOD,CURRENT_REMARKS,CONTAINER_BARCODE,PART_COLLECTION_OBJECT_ID">

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
<cfset pageTitle = "Bulk Part Container">
<cfinclude template="/shared/_header.cfm">
<cfinclude template="/tools/component/csv.cfc" runOnce="true"><!--- for common csv functions --->
<cfif not isDefined("variables.action") OR len(variables.action) EQ 0>
	<cfset variables.action="entryPoint">
</cfif>

<main class="container-fluid px-xl-5 py-3" id="content">
	<h1 class="h2 mt-2">Bulkload Part Containers </h1>
	
	<!------------------------------------------------------->
	<cfif variables.action is "entryPoint">
		<cfoutput>
			<p>Use this form to put collection objects (that is, parts) in containers. Parts and containers must already exist. This form can be used for specimen records with multiple parts as long as the full names (part name plus preserve method and part remarks) of the parts are unique. Upload a comma-delimited text file (csv). The best way to avoid ambiguous parts is to use a part report from the specimen search results > Manage > Part Download/Report feature.  Additional colums will be ignored. </p>
			<h2 class="h4">Use Template to Load Data</h2>
			<button class="btn btn-xs btn-primary float-left mr-3" id="copyButton">Copy Column Headers</button>
			<div id="template" class="my-1 mx-0">
				<label for="templatearea" class="data-entry-label" style="line-height: inherit;">
					Copy this header line, paste it into a blank worksheet, and save it as a .csv file or <a href="/tools/BulkloadPartContainer.cfm?action=getCSVHeader" class="font-weight-bold">download</a> a template.
				</label>
				<textarea style="height: 30px;" cols="90" id="templatearea" class="mb-1 w-100 data-entry-textarea small">#fieldlist#</textarea>
			</div>
			<div class="accordion" id="accordionPC">
				<div class="card mb-2 bg-light">
					<div class="card-header" id="headingPC">
						<h3 class="h5 my-0">
							<button type="button" role="button" aria-label="part container pane" class="headerLnk text-left w-100" data-toggle="collapse" data-target="##pcPane" aria-expanded="false" aria-controls="pcPane">
								Data Entry Instructions per Column
							</button>
						</h3>
					</div>
					<div id="pcPane" class="collapse" aria-labelledby="headingPC" data-parent="##accordionPC">
						<div class="card-body" id="pcCardBody">
							<p class="px-3 pt-2"> Columns in <span class="text-danger">red</span> are required; others are optional.</p>
							<ul class="mb-4 h5 font-weight-normal list-group mx-3">
								<cfloop list="#fieldlist#" index="field" delimiters=",">
									<cfquery name = "getComments"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#"  result="getComments_result">
										SELECT comments
										FROM sys.all_col_comments
										WHERE 
											owner = 'MCZBASE'
											and table_name = 'CF_TEMP_BARCODE_PARTS'
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
				<form name="bulk" method="post" enctype="multipart/form-data" action="/tools/BulkloadPartContainer.cfm">
					<div class="form-row border rounded p-2">
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
	<cfif variables.action is "getFile">
	<!--- get form variables --->
	<cfif isDefined("form.fileToUpload")><cfset variables.fileToUpload = form.fileToUpload></cfif>
	<cfif isDefined("form.format")><cfset variables.format = form.format></cfif>
	<cfif isDefined("form.characterSet")><cfset variables.characterSet = form.characterSet></cfif>
	<cfoutput>
		<h2 class="h3">First step: Reading data from CSV file.</h2>
		<!--- Compare the numbers of headers expected against provided in CSV file --->
		<!--- Set some constants to identify error cases in cfcatch block --->
		<cfset NO_COLUMN_ERR = "One or more required fields are missing in the header line of the csv file. Check charset selected if columns match required headers and one column is not found.">
		<cfset DUP_COLUMN_ERR = "One or more columns are duplicated in the header line of the csv file.">
		<cfset COLUMN_ERR = "Error inserting data ">
		<cfset NO_HEADER_ERR = "No header line found, csv file appears to be empty.">
		<cfset table_name = "CF_TEMP_BARCODE_PARTS">
		<cftry>
			<cfquery name="clearTempTable" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="clearTempTable_result">
				DELETE FROM cf_temp_barcode_parts
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfset variables.foundHeaders =""><!--- populated by loadCsvFile --->
			<cfset variables.size=""><!--- populated by loadCsvFile --->
			<cfset iterator = loadCsvFile(FileToUpload=FileToUpload,format=format,characterSet=characterSet)>

			<!--- Note: As we can't use csvFormat.withHeader(), we can not match columns by name, we are forced to do so by number, thus arrays --->
			<cfset colNameArray = listToArray(ucase(variables.foundHeaders))><!---the list of columns/fields found in the input file--->
			<cfset fieldArray = listToArray(ucase(fieldlist))><!--- the full list of fields --->
			<cfset typeArray = listToArray(fieldTypes)><!--- the types for the full list of fields --->
					
			<div class="col-12 my-4 px-0">
				<h3 class="h4">Found #variables.size# columns in header of csv file.</h3>
				<h3 class="h4">There are #ListLen(fieldList)# columns expected in the header (of these #ListLen(requiredFieldList)# are required).</h3>
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
						<!--- construct insert for row with a line for each entry in fieldlist using cfqueryparam if column header is in fieldlist, otherwise using null --->
						<!--- Note: As we can't use csvFormat.withHeader(), we can not match columns by name, we are forced to do so by number, thus arrays --->
						<cfquery name="insert" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="insert_result">
							insert into CF_TEMP_BARCODE_PARTS
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
						you probably want to <strong><a href="/tools/BulkloadPartContainer.cfm">reload</a></strong> this file selecting a different encoding.  If these appear as expected, then 
							you selected the correct encoding and can continue to validate or load.</p>
					</div>
					<ul class="pb-1 h4 list-unstyled">
						#foundHighAscii# #foundMultiByte#
					</ul>
				</cfif>
				<h3 class="h3">
					<cfif loadedRows EQ 0>
						Loaded no rows from the CSV file.  The file appears to be just a header with no data. Fix file and <a href="/tools/BulkloadPartContainer.cfm">reload</a>
					<cfelse>
						Successfully read #loadedRows# records from the CSV file.  Next <a href="/tools/BulkloadPartContainer.cfm?action=validate" class="btn-link font-weight-lessbold">click to validate</a>.
					</cfif>
				</h3>
			<cfcatch>
				<h3 class="h4">
					Failed to read the CSV file.  Fix the errors in the file and <a href="/tools/BulkloadPartContainer.cfm">reload</a>
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
			</div>
		</cftry>
	</cfoutput>
</cfif>
<!------------------------------------------------------->
<!------------------------------------------------------->
<cfif variables.action is "validate">
	<cfoutput>
		<h2 class="h4 mb-3">Second step: Data Validation</h2>
		<cfset key = ''>
		<cfquery name="dataParts" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			SELECT collection_cde, institution_acronym,other_id_number,other_id_type,part_name,preserve_method,current_remarks,key
			FROM cf_temp_barcode_parts 
			WHERE status is null
				AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
		</cfquery>
		<cfloop query="dataParts">
			<cfif len(dataParts.collection_object_id) eq 0>
			<!---This gets the collection_object_id based on the catalog number/other id--->
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
			</cfif>
			<!---Get the collection_object_id based on the specimen parts--->
			<cfif len(collObj.collection_object_id) gt 0>
				<cfquery name="partColl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE 
						cf_temp_barcode_parts
					SET 
						part_collection_object_id = (
							select specimen_part.collection_object_id
							from specimen_part   
								left join coll_object_remark on specimen_part.collection_object_id = coll_object_remark.collection_object_id
								left join coll_object on specimen_part.collection_object_id = coll_object.collection_object_id
							where			
								part_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#dataParts.part_name#">
								and preserve_method = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#dataParts.preserve_method#">
								and derived_from_cat_item = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collObj.collection_object_id#">
								<cfif len(dataParts.current_remarks) EQ 0>
									and coll_object_remark.coll_object_remarks IS NULL
								<cfelse>
									and coll_object_remark.coll_object_remarks = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#dataParts.current_remarks#">
								</cfif>							
							)
					WHERE 
						username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						AND key = <cfqueryparam cfsqltype="CF_SQL_decimal" value="#dataParts.key#"> 
				</cfquery>
			</cfif>
		</cfloop>
		<!--- Second set of Validation tests: container terms ---> 
		<!--- check container terms, use list of keys for row by row validations of containers --->
		<cfquery name="getTempTableQC1" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			SELECT part_collection_object_id, key
			FROM cf_temp_barcode_parts  
			WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
		</cfquery>
			<cfloop query="getTempTableQC1">
				<cfquery name="getPartContainerId" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE cf_temp_barcode_parts  
					SET 
						part_container_id = (
							select c.container_id 
							from 
								container c, coll_obj_cont_hist ch
							where 
								ch.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempTableQC1.part_collection_object_id#">
							AND	c.container_id = ch.container_id
						)
					WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						AND key = <cfqueryparam cfsqltype="CF_SQL_decimal" value="#getTempTableQC1.key#"> 
				</cfquery>
			</cfloop>
			<cfquery name="getTempTableQC2" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT *
				FROM cf_temp_barcode_parts  
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfloop query="getTempTableQC2">
				<cfquery name="getPartContainer" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE cf_temp_barcode_parts  
					SET 
						current_parent_container_id = (
							select c.parent_container_id 
							from 
								container c
							where 
								c.container_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempTableQC2.part_container_id#">
						)
					WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						AND key = <cfqueryparam cfsqltype="CF_SQL_decimal" value="#getTempTableQC2.key#"> 
				</cfquery>
				<cfquery name="getPartContainer" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE cf_temp_barcode_parts
					SET status = concat(nvl2(status, status || '; ', ''), 'PART not found')
					WHERE part_collection_object_id is null
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						AND key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableQC2.key#">
				</cfquery>
			</cfloop>
			<cfquery name="getTempTableQC3" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT *
				FROM cf_temp_barcode_parts  
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>	
			<cfloop query="getTempTableQC3">
				<cfquery name="getPartContainer" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE cf_temp_barcode_parts  
					SET 
						NEW_PARENT_CONTAINER_ID = (
							select c.container_id
							from 
								container c
							where 
								c.barcode = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempTableQC3.container_barcode#">
						)
					WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						AND key = <cfqueryparam cfsqltype="CF_SQL_decimal" value="#getTempTableQC3.key#"> 
				</cfquery>
				<cfquery name="getPartContainer" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE cf_temp_barcode_parts
					SET status = concat(nvl2(status, status || '; ', ''), 'CONTAINER not found')
					WHERE container_barcode not in (select barcode from container) 
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						AND key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableQC3.key#">
				</cfquery>
			</cfloop>
			<cfquery name="getTempTableQC4" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT *
				FROM cf_temp_barcode_parts  
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfloop query="getTempTableQC4">
				<cfquery name="getPartContainer" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE cf_temp_barcode_parts  
					SET 
						current_container_barcode = (
							select c.barcode 
							from 
								container c
							where 
								c.container_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempTableQC4.current_parent_container_id#">
						)
					WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						AND key = <cfqueryparam cfsqltype="CF_SQL_decimal" value="#getTempTableQC4.key#"> 
				</cfquery>
			</cfloop>
			<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT * 
				FROM cf_temp_barcode_parts 
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="pc" dbtype="query">
				SELECT count(*) c 
				FROM data 
				WHERE status is not null
			</cfquery>
			<h3>
				<cfif pc.c gt 0>
					There is a problem with #pc.c# of #pc.recordcount# row(s). See the STATUS column. (<a href="/tools/BulkloadPartContainer.cfm?action=dumpProblems">download</a>). Fix the problems in the data and <a href="/tools/BulkloadPartContainer.cfm" class="text-danger">start again</a>.
				<cfelse>
					<span class="text-success">Validation checks passed.</span> Look over the table below and <a href="/tools/BulkloadPartContainer.cfm?action=load" class="btn-link font-weight-lessbold">click to continue</a> if it all looks good. Or, <a href="/tools/BulkloadPartContainer.cfm" class="text-danger">start again</a>.
				</cfif>
			</h3>
				<table class='px-0 sortable small table table-responsive table-striped'>
					<thead class="thead-light">
						<tr>
							<th>BULKLOADING&nbsp;STATUS</th>
							<th>INSTITUTION_ACRONYM</th>
							<th>COLLECTION_CDE</th>
							<th>OTHER_ID_TYPE</th>
							<th>OTHER_ID_NUMBER</th>
							<th>PART_NAME</th>
							<th>PRESERVE_METHOD</th>
							<th>PART_COLLECTION_OBJECT_ID</th>
							<th>PART_CONTAINER_ID</th>
							<th>CONTAINER_BARCODE</th>
							<th>CURRENT_CONTAINER_BARCODE</th>
							<!---<th>CURRENT_PARENT_CONTAINER_ID</th>
							<th>NEW_PARENT_CONTAINER_ID</th>--->

						</tr>
					</thead>
					<tbody>
						<cfloop query="data">
							<tr>
								<td><cfif len(data.status) eq 0>Cleared to load<cfelse><strong>#data.status#</strong></cfif></td>
								<td>#data.institution_acronym#</td>
								<th>#data.collection_cde#</th>
								<td>#data.other_ID_TYPE#</td>
								<td>#data.other_id_number#</td>
								<td>#data.part_name#</td>
								<td>#data.preserve_method#</td>
								<td>#data.PART_collection_object_id#</td>
								<td>#data.part_container_id#</td>
								<td>#data.CONTAINER_BARCODE#</td>
								<td>#data.CURRENT_CONTAINER_BARCODE#</td>
<!---								<td>#data.current_parent_container_id#</td>
								<td>#data.new_parent_container_id#</td>--->

							</tr>
						</cfloop>
					</tbody>
				</table>
			</div>
		</cfoutput>
	</cfif>
	<!-------------------------------------------------------------------------------------------->
	<cfif variables.action is "load">
		<h2 class="h4">Third step: Apply changes.</h2>
		<cfoutput>
			<cfquery name="getTempData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT 
					new_parent_container_id, part_container_id, container_barcode,key
				FROM 
					cf_temp_barcode_parts
				WHERE 
					username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfset problem_key = "">
			<cftransaction>
				<cftry>
					<cfset container_updates = 0>
					<cfloop query="getTempData">
						<cfset problem_key = getTempData.key>
						<cfif len(#getTempData.container_barcode#) gt 0>
							<cfquery name="updateContainer" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="updateContainer_result">
								UPDATE
									container
								set 
									parent_container_id = (select container_id from container where barcode = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.container_barcode#">)
								where 
									container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempData.part_container_id#">
							</cfquery>	
						</cfif>
						<cfset container_updates = container_updates + updateContainer_result.recordcount>
					</cfloop>

					<cftransaction action="commit">
				<cfcatch>
					<cftransaction action="rollback">						
						<cftransaction action="ROLLBACK">
						<h3>There was a problem updating row (#container_updates +1#) of the containers for parts .</h3>
						<cfquery name="getProblemData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							SELECT *
							FROM cf_temp_barcode_parts
							WHERE key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#problem_key#">
						</cfquery>
						<h3>Fix the issues and <a href="/tools/BulkloadPartContainer.cfm">start again</a>.</h3>
						<cfif getProblemData.recordcount GT 0>
							<h3>
								Error loading row (<span class="text-danger"></span>) from the CSV: 
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
											This change has already been entered. Remove from spreadsheet and try again. (<a href="/tools/BulkloadPartContainer.cfm">Reload.</a>)
										<cfelseif cfcatch.detail contains "no data">
											No data or the wrong data (#cfcatch.detail#)
										<cfelse>
											<!--- provide the raw error message if it isn't readily interpretable --->
											#cfcatch.detail#
										</cfif>
									</span>
								</cfif>
							</h3>
							<table class='sortable table table-responsive table-striped d-lg-table'>
								<thead>
									<tr>
										<th>BULKLOADING&nbsp;STATUS</th>
										<th>CONTAINER_BARCODE</th>
										<th>PART_CONTAINER_ID</th>
										<th>NEW_PARENT_CONTAINER_ID</th>
									</tr> 
								</thead>
								<tbody>
									<cfloop query="getProblemData">
										<tr>
											<td><cfif len(getProblemData.status) eq 0>Cleared to load<cfelse><strong>#getProblemData.status#</strong></cfif></td>
											<td>#getProblemData.container_BARCODE#</td>
											<td>#getProblemData.part_container_id#</td>
											<td>#getProblemData.NEW_PARENT_container_id#</td></tr> 
									</cfloop>
								</tbody>
							</table>
						</cfif>
					<cfrethrow>
				</cfcatch>
				</cftry>
			</cftransaction>
			<cfif container_updates GT 1><cfset plural="s"><cfelse><cfset plural=""></cfif>
			<h3 class="mt-4">Updated #container_updates# parts#plural# with containers.</h3>
			<h3 class="text-success">Success, changes applied.</h3>
			<!--- cleanup --->
			<cfquery name="clearTempTable" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="clearTempTable_result">
				DELETE FROM cf_temp_barcode_parts 
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
		</cfoutput>
		</div>
	</cfif>
</main>
<cfinclude template="/shared/_footer.cfm">
