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
		SELECT
			STATUS, 
			INSTITUTION_ACRONYM,COLLECTION_CDE,OTHER_ID_TYPE,OTHER_ID_NUMBER,PART_NAME,
			PRESERVE_METHOD,CURRENT_REMARKS,NEW_CONTAINER_BARCODE,CONTAINER_BARCODE,
			PART_COLLECTION_OBJECT_ID
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
<cfset fieldlist = "INSTITUTION_ACRONYM,COLLECTION_CDE,OTHER_ID_TYPE,OTHER_ID_NUMBER,PART_NAME,PRESERVE_METHOD,CURRENT_REMARKS,NEW_CONTAINER_BARCODE,CONTAINER_BARCODE,PART_COLLECTION_OBJECT_ID">
<cfset fieldTypes ="CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_DECIMAL">
<cfif listlen(fieldlist) NEQ listlen(fieldTypes)>
	<cfthrow message = "Error: Bug in the definition of fieldlist[#listlen(fieldlist)#] and fieldType[#listlen(fieldTypes)#] lists, lists must be the same length, but are not.">
</cfif>
<cfset requiredfieldlist = "COLLECTION_CDE,OTHER_ID_TYPE,OTHER_ID_NUMBER,PART_NAME,PRESERVE_METHOD,CONTAINER_BARCODE,NEW_CONTAINER_BARCODE">
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
			<p>Use this form to put collection objects (that is, parts) in containers. Only the other_id_type of "catalog number" is supported in this bulkloader. The unique string representing the container is used (Container Unique Identifier). Parts and containers must already exist.</p>
			<p>Upload a comma-delimited text file (csv). You can either enter the data using the template below or (preferred) edit a part report produced from Manage from Specimen Searhc Results. </p>
			<p><em>Distinguishing Multiple Parts for the same cataloged item:</em> This bulkloader can be used for specimen records with multiple parts as long as the combination of the following column values are unique within the cataloged item (identified by institution acronym, collection code, and catalog number): part_name, preserve_method, and part_remarks. If part_collection_object_id is not supplied, it will be looked up from this set of fields.  If parts are ambiguous and can not be uniquely identified within a cataloged item by part_name, preserve_method, and part_remarks, the part_collection_object_id must be provided.</p>
			<p><em>Edit a Part Report:</em> The best way to avoid ambiguous parts is to use a part report from the Specimen Search results > Manage > Part Download/Report feature.  To pobtain the part report, select the "Download Parts CSV for:" option "Bulkloading Parts to New Containers", check that the parts downloaded are as expected, remove any parts you do not want to move, and fill in the column NEW_CONTAINER_BARCODE to hold the container barcode (a.k.a., unique_container_id) of the container to place the part into.  Additional columns not used in this downloader may help you identify which parts you wish to move where and will be ignored on upload (and will appear in the warning section of the validation screen with any other columns not needed for the bulkload). </p>
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
	<!---This provides the collection_cde,other_id_type, other_id_number if the part_collection_object_id is provided to be used as reference/verification--->
	<!---If the collection_cde, other_id_type, and other_id_number, part_name, preserve_method are provided, it gets the part_collection_object_id--->
	<!---If required fields are provided along with the part_collection_object_id and they do not match what is in spec record/part row, it notifies the user--->
	<!---If duplicate rows are listed based on the part_collection_object_id (whether generated from required fields or provided), it notifies the user--->
	<cfoutput>
		<h2 class="h4 mb-3">Second step: Data Validation</h2>
		<cfset key = ''>
		<!--- checks that don't need to go record by record --->
		<cfloop list="#requiredfieldlist#" index="requiredField">
			<cfquery name="checkRequired" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE cf_temp_barcode_parts
				SET 
					status = concat(nvl2(status, status || '; ', ''),'#requiredField# missing')
				WHERE #requiredField# is null
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
		</cfloop>
		<cfquery name="checkIDType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			UPDATE cf_temp_barcode_parts
			SET 
				status = concat(nvl2(status, status || '; ', ''),' OTHER_ID_TYPE must be "catalog number"')
			WHERE 
				(other_id_type is null OR other_id_type <> 'catalog number') 
				AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
		</cfquery>
		<cfquery name="probPartName" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			UPDATE cf_temp_barcode_parts
			SET
				status = concat(nvl2(status, status || '; ', ''),'part_name is invalid')
			WHERE 
				part_name not in (select part_name from ctspecimen_part_name)
				AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
		</cfquery>
		<!--- Load temp table cf_temp_barcode_part and iterate --->
		<cfquery name="dataParts" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			SELECT INSTITUTION_ACRONYM,COLLECTION_CDE,OTHER_ID_TYPE,OTHER_ID_NUMBER,
				PART_COLLECTION_OBJECT_ID,
				PART_NAME,PRESERVE_METHOD,CURRENT_REMARKS,
				NEW_CONTAINER_BARCODE,CONTAINER_BARCODE,
				CURRENT_PARENT_CONTAINER_ID,NEW_PARENT_CONTAINER_ID,
				KEY
			FROM cf_temp_barcode_parts 
			WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
		</cfquery>
		<cfloop query="dataParts">
			<cfif len(dataParts.part_collection_object_id) eq 0>
				<!--- case 1: part_collection_object_id needs to be looked up against provided values of other fields --->
				<cfquery name="getCOID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getCOID_result">
					SELECT
						cataloged_item.collection_object_id
					FROM
						cataloged_item 
						join collection on cataloged_item.collection_id = collection.collection_id
					WHERE
						collection.collection_cde = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#dataParts.collection_cde#"> and
						collection.institution_acronym = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#dataParts.institution_acronym#"> and
						cataloged_item.cat_num=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#dataParts.other_id_number#"> 
				</cfquery>
				<cfif getCOID.recordcount NEQ 1>
					<!--- cataloged item for part_collection_object_id not found --->
					<cfquery name="probPartName" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						UPDATE cf_temp_barcode_parts
						SET
							status = concat(nvl2(status, status || '; ', ''),'institution:collection:cat_num [#dataParts.institution_acronym#:#dataParts.collection_cde#:#dataParts.other_id_number#] not found')
						WHERE 
							username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
							and key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#dataParts.key#"> 
					</cfquery>
				<cfelse> 
					<!--- cataloged item for part_collection_object_id found --->
					<!--- lookup the  part, use remarks in necessary --->
					<cfquery name="getPart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getPart_result">
						SELECT 
							specimen_part.collection_object_id
						FROM 
							specimen_part 
						WHERE 
							derived_from_cat_item = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getCOID.collection_object_id#">
							and part_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#dataParts.part_name#">
							and preserve_method = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#dataParts.preserve_method#">
					</cfquery>
					<cfif getPart.recordcount EQ 0>
						<!--- part not found --->
						<cfquery name="probPartName" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							UPDATE cf_temp_barcode_parts
							SET
								status = concat(nvl2(status, status || '; ', ''),'no part #dataParts.part_name# (#dataParts.preserve_method#) found for #dataParts.institution_acronym#:#dataParts.collection_cde#:#dataParts.other_id_number#')
							WHERE 
								username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
								and key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#dataParts.key#"> 
						</cfquery>
					<cfelseif getPart.recordcount EQ 1>
						<!--- part found --->
						<cfquery name="partFound" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							UPDATE cf_temp_barcode_parts
							SET
								part_collection_object_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getPart.collection_object_id#">
							WHERE 
								username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
								and key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#dataParts.key#"> 
						</cfquery>
					<cfelseif getPart.recordcount GT 1>
						<!--- duplicate parts found, check using remark --->
						<cfquery name="getPartwithRemark" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getPart_result">
							SELECT
								specimen_part.collection_object_id
							FROM 
								specimen_part 
								left join coll_object_remark specimen_part_remarks on specimen_part.collection_object_id = specimen_part_remarks.collection_object_id
							WHERE 
								derived_from_cat_item = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getCOID.collection_object_id#">
								and part_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#dataParts.part_name#">
								and preserve_method = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#dataParts.preserve_method#">
								<cfif len(dataParts.current_remarks) GT 0>
									and coll_object_remarks = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#dataParts.current_remarks#">
								<cfelse>
									and coll_object_remarks is null
								</cfif>
						</cfquery>
						<cfif getPartWithRemark.recordcount EQ 0>
							<!--- part not found --->
							<cfquery name="probPartName" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
								UPDATE cf_temp_barcode_parts
								SET
									status = concat(nvl2(status, status || '; ', ''),'no part #dataParts.part_name# (#dataParts.preserve_method#) found for #dataParts.institution_acronym#:#dataParts.collection_cde#:#dataParts.other_id_number# with remarks [#dataParts.current_remarks#]')
								WHERE 
									username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
									and key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#dataParts.key#"> 
							</cfquery>
						<cfelseif getPartWithRemark.recordcount EQ 1>
							<!--- part found --->
							<cfquery name="partFound" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
								UPDATE cf_temp_barcode_parts
								SET
									part_collection_object_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getPartwitRemark.collection_object_id#">
								WHERE 
									username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
									and key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#dataParts.key#"> 
							</cfquery>
						<cfelseif getPartWithRemark.recordcount GT 1>
							<!--- duplicate parts still found --->
							<cfquery name="probPartName" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
								UPDATE cf_temp_barcode_parts
								SET
									status = concat(nvl2(status, status || '; ', ''),'unable to match a unique part on part_name, preserve_method, and remarks, specify a part_collection_object_id')
								WHERE 
									username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
									and key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#dataParts.key#"> 
							</cfquery>
						</cfif>
					</cfif>
				</cfif>
			<cfelse>
				<!--- case 2: part_collection_object_id needs to be validated against other fields --->
				<cfquery name="checkData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getCOID_result">
					SELECT 
						collection.institution_acronym,
						cataloged_item.collection_object_id,
						cataloged_item.cat_num, 
						cataloged_item.collection_cde,
						part_name, preserve_method 
					FROM
						coll_object 
						join specimen_part on coll_object.collection_object_id = specimen_part.collection_object_id
						join cataloged_item on specimen_part.derived_from_cat_item = cataloged_item.collection_object_id
						join collection on cataloged_item.collection_id = collection.collection_id
					WHERE
						coll_object.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#dataParts.part_collection_object_id#">
				</cfquery>
				<cfif dataParts.recordcount EQ 0>
					<cfquery name="noMatchInstitution" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						UPDATE cf_temp_barcode_parts
						SET
							status = concat(nvl2(status, status || '; ', ''),' part_collection_object_id not found ')
						WHERE 
							key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#dataParts.key#"> 
							AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
					</cfquery>
				<cfelse>
					<cfif dataParts.institution_acronym NEQ checkData.institution_acronym>
						<cfquery name="noMatchInstitution" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							UPDATE cf_temp_barcode_parts
							SET
								status = concat(nvl2(status, status || '; ', ''),' institution_acronym [#dataParts.institution_acronym#] does not match [#checkData.institution_acronym#] for part_collection_object_id ')
							WHERE 
								key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#dataParts.key#"> 
								AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						</cfquery>
					</cfif>
					<cfif dataParts.collection_cde NEQ checkData.collection_cde>
						<cfquery name="notMatchCollection" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							UPDATE cf_temp_barcode_parts
							SET
								status = concat(nvl2(status, status || '; ', ''),' collection_cde [#dataParts.collection_cde#] does not match [#checkData.collection_cde#] for part_collection_object_id ')
							WHERE 
								key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#dataParts.key#"> 
								AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						</cfquery>
					</cfif>
					<cfif dataParts.other_id_number NEQ checkData.cat_num>
						<cfquery name="noMatchNumber" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							UPDATE cf_temp_barcode_parts
							SET
								status = concat(nvl2(status, status || '; ', ''),' other_id_number [#dataParts.other_id_number#] does not match cat_num [#checkData.cat_num#] for part_collection_object_id ')
							WHERE 
								key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#dataParts.key#"> 
								AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						</cfquery>
					</cfif>
					<cfif dataParts.part_name NEQ checkData.part_name>
						<cfquery name="noMatchPart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							UPDATE cf_temp_barcode_parts
							SET
								status = concat(nvl2(status, status || '; ', ''),' part_name [#dataParts.part_name#] does not match [#checkData.part_name#] for part_collection_object_id ')
							WHERE 
								key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#dataParts.key#"> 
								AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						</cfquery>
					</cfif>
					<cfif dataParts.preserve_method NEQ checkData.preserve_method>
						<cfquery name="noMatchInstitution" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							UPDATE cf_temp_barcode_parts
							SET
								status = concat(nvl2(status, status || '; ', ''),' preserve_method [#dataParts.preserve_method#] does not match [#checkData.preserve_method#] for part_collection_object_id ')
							WHERE 
								key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#dataParts.key#"> 
								AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						</cfquery>
					</cfif>
				</cfif>
			</cfif>
		</cfloop>
		<!--- check container terms, use list of keys for row by row validations of containers --->
		<cfquery name="getTempTableQC1" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			SELECT INSTITUTION_ACRONYM,COLLECTION_CDE,OTHER_ID_TYPE,OTHER_ID_NUMBER,PART_NAME,PRESERVE_METHOD,CURRENT_REMARKS,NEW_CONTAINER_BARCODE,CONTAINER_BARCODE,PART_COLLECTION_OBJECT_ID,CURRENT_PARENT_CONTAINER_ID,NEW_PARENT_CONTAINER_ID,key
			FROM cf_temp_barcode_parts  
			WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
		</cfquery>
		<cfloop query="getTempTableQC1">
			<!--- confirm that part is actually in the current container --->
			<cfquery name="checkPartContainerCurrent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE cf_temp_barcode_parts
				SET status = concat(nvl2(status, status || '; ', ''), 'Part is not currently in container_barcode [#getTempTableQC1.container_barcode#]')
				WHERE 
					container_barcode not in (
						select p.barcode 
						from coll_obj_cont_hist
							join container c on coll_obj_cont_hist.container_id = c.container_id
							join container p on c.parent_container_id = p.container_id
						where 
							current_container_fg = 1
							and p.barcode = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempTableQC1.container_barcode#">	
							and coll_obj_cont_hist.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempTableQC1.part_collection_object_id#">	
					)
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
					AND key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableQC1.key#">
					AND (status IS NULL OR NOT (status LIKE '%no part%found for%' OR status LIKE '%unable to match a unique part%'))
			</cfquery>
			<!--- Based on part_collection_object_id--->
			<cfif len(part_collection_object_id) gt 0>
				<cfquery name="getPartCollID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE cf_temp_barcode_parts
					SET status = concat(nvl2(status, status || '; ', ''), 'PART_COLLECTION_OBJECT_ID not found')
					WHERE part_collection_object_id not in (select collection_object_id from specimen_part)
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						AND key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableQC1.key#">
				</cfquery>
				<!---update the collection_object_id field based on part_collection_object_id so the catalog number can be back filled later--->
				<cfquery name="getCollObjId" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE cf_temp_barcode_parts  
					SET 
						collection_object_id = (
							select specimen_part.derived_from_cat_item 
							from specimen_part 
							where specimen_part.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempTableQC1.part_collection_object_id#">
						)
					WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						AND key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableQC1.key#"> 
				</cfquery>
				<!---Put the container ID of the collection_object into the table to exchange parent_container_id later--->
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
						AND key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableQC1.key#"> 
				</cfquery>
			</cfif>
		</cfloop>
		<!--- Second set of Validation tests: container terms ---> 
		<!---Get current_parent_container_id. This is the container_id that currently shows in the part row--->
		<cfquery name="getTempTableQC2" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			SELECT INSTITUTION_ACRONYM,COLLECTION_CDE,OTHER_ID_TYPE,OTHER_ID_NUMBER,PART_NAME,PRESERVE_METHOD,CURRENT_REMARKS,NEW_CONTAINER_BARCODE,CONTAINER_BARCODE,PART_COLLECTION_OBJECT_ID,CURRENT_PARENT_CONTAINER_ID,PART_CONTAINER_ID,NEW_PARENT_CONTAINER_ID,key
			FROM cf_temp_barcode_parts  
			WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
		</cfquery>
		<cfloop query="getTempTableQC2">
			<!---Use the part_container_id (i.e., collecton_object starter container) to find the current barcode (a.k.a. unique_container_id)--->
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
					AND key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableQC2.key#"> 
			</cfquery>
		</cfloop>
		<!---Find the new container's container_id so it can be placed in the collection object's parent_container_id field with an update--->
		<cfquery name="getTempTableQC3" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			SELECT new_container_barcode, key
			FROM cf_temp_barcode_parts  
			WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
		</cfquery>	
		<cfif len(getTempTableQC3.new_container_barcode) gt 0>
			<cfloop query="getTempTableQC3">
				<cfquery name="getPartContainer" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE cf_temp_barcode_parts  
					SET 
						NEW_PARENT_CONTAINER_ID = (
							select c.container_id
							from 
								container c
							where 
								c.barcode = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempTableQC3.new_container_barcode#">
						)
					WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						AND key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableQC3.key#"> 
				</cfquery>
			</cfloop>
			<cfquery name="getTempTableQC4" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT NEW_PARENT_CONTAINER_ID, key
				FROM cf_temp_barcode_parts  
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<!---If the new entry in container_barcode is not already in MCZbase, show container not found--->
			<cfloop query="getTempTableQC4">
				<cfquery name="getPartContainerNew" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE cf_temp_barcode_parts
					SET status = concat(nvl2(status, status || '; ', ''), 'New container not found in MCZbase')
					WHERE NEW_PARENT_CONTAINER_ID is null 
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						AND key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableQC4.key#">
				</cfquery>
			</cfloop>
		</cfif>
		<!---Find the current container that shows in the part row on the specimen record and put it in the table so the change can be seen easily--->
		<!---This comes from the collection object container parent in getTempTableQC2--->
		<cfif len(getTempTableQC1.container_barcode) eq 0>
			<cfquery name="getTempTableQC5" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT current_parent_container_id, container_barcode,key
				FROM cf_temp_barcode_parts  
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfloop query="getTempTableQC5">
				<cfquery name="getPartContainer" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE cf_temp_barcode_parts  
					SET 
						container_barcode = (
							select c.barcode 
							from 
								container c
							where 
								c.container_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempTableQC5.current_parent_container_id#">
						)
					WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						AND key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableQC5.key#"> 
				</cfquery>
			</cfloop>
		</cfif>
		<cfquery name="getTempTableQC6" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			SELECT part_name, preserve_method,other_id_number,other_id_type,collection_cde,part_collection_object_id,key
			FROM cf_temp_barcode_parts
			WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
		</cfquery>
		<cfloop query="getTempTableQC6">
			<cfquery name="warningDuplicatedRows" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE CF_TEMP_BARCODE_PARTS 
				SET status = concat(nvl2(status, status || '; ', ''),'Duplicate rows')
				WHERE 
					part_collection_object_id in 
						(	select part_collection_object_id 
							from CF_TEMP_BARCODE_PARTS
							where part_collection_object_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempTableQC6.part_collection_object_id#">
								AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
							group by part_collection_object_id 
							having count(*) > 1
						)
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
					AND key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableQC6.key#"> 
			</cfquery>
		</cfloop>
		<cfif len(getTempTableQC6.part_collection_object_id) EQ 0>
			<cfquery name="getPartCollID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE cf_temp_barcode_parts
				SET status = concat(nvl2(status, status || '; ', ''), 'PART_COLLECTION_OBJECT_ID invalid')
				WHERE part_collection_object_id is not null
					and part_collection_object_id not in (select collection_object_id from specimen_part)
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
					AND key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableQC6.key#">
			</cfquery>
		</cfif>
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
					There is a problem with #pc.c# of #data.recordcount# row(s). See the STATUS column. (<a href="/tools/BulkloadPartContainer.cfm?action=dumpProblems">download</a>). Fix the problems in the data and <a href="/tools/BulkloadPartContainer.cfm" class="text-danger">start again</a>.
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
							<th>CURRENT_REMARKS</th>
							<th>NEW_CONTAINER_BARCODE</th>
							<th>CONTAINER_BARCODE</th>
							<th>PART_COLLECTION_OBJECT_ID</th>
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
								<td>#data.current_remarks#</td>
								<td>#data.NEW_CONTAINER_BARCODE#</td>
								<td>#data.CONTAINER_BARCODE#</td>
								<td>#data.part_collection_object_id#</td>
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
				SELECT *
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
							<cfif len(#getTempData.new_container_barcode#) gt 0>
								<cfquery name="updateContainer" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="updateContainer_result">
									UPDATE
										container
									set 
										parent_container_id = (select container_id from container where barcode = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.new_container_barcode#">)
									where 
										container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempData.part_container_id#">
								</cfquery>	
							<cfelse>
								<!--- should be unnecessary, but just in case a blank value gets to here --->
								<cfquery name="getPartContainer" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									UPDATE cf_temp_barcode_parts
									SET status = concat(nvl2(status, status || '; ', ''), 'New CONTAINER is required')
									WHERE NEW_container_barcode is null
										AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
										AND key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempData.key#">
								</cfquery>
								<cfthrow message = "Container #getTempData.new_container_barcode# is required.">
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
										<cfelseif cfcatch.detail contains "container_barcode">
											Invalid container_barcode
										<cfelseif cfcatch.detail contains "ID">
											Invalid ID
										<cfelseif cfcatch.detail contains "current_remarks">
											Invalid remarks
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
										<th>INSTITUTION_ACRONYM</th>
										<th>COLLECTION_CDE</th>
										<th>OTHER_ID_TYPE</th>
										<th>OTHER_ID_NUMBER</th>
										<th>PART_NAME</th>
										<th>PRESERVE_METHOD</th>
										<th>CURRENT_REMARKS</th>
										<th>NEW_CONTAINER_BARCODE</th>
										<th>CONTAINER_BARCODE</th>
										<th>CURRENT_PARENT_CONTAINER_ID</th>
										<th>NEW_PARENT_CONTAINER_ID</th>
										<th>PART_COLLECTION_OBJECT_ID</th>
										<th>PART_CONTAINER_ID</th>
									</tr> 
								</thead>
								<tbody>
									<cfloop query="getProblemData">
										<tr>
											<td><cfif len(getProblemData.status) eq 0>Cleared to load<cfelse><strong>#getProblemData.status#</strong></cfif></td>
											<td>#getProblemData.INSTITUTION_ACRONYM#</td>
											<td>#getProblemData.COLLECTION_CDE#</td>
											<td>#getProblemData.OTHER_ID_TYPE#</td>
											<td>#getProblemData.OTHER_ID_NUMBER#</td>
											<td>#getProblemData.PART_NAME#</td>
											<td>#getProblemData.PRESERVE_METHOD#</td>
											<td>#getProblemData.CURRENT_REMARKS#</td>
											<td>#getProblemData.NEW_CONTAINER_BARCODE#</td>
											<td>#getProblemData.CONTAINER_BARCODE#</td>
											<td>#getProblemData.CURRENT_PARENT_CONTAINER_ID#</td>
											<td>#getProblemData.NEW_PARENT_CONTAINER_ID#</td>
											<td>#getProblemData.PART_COLLECTION_OBJECT_ID#</td>
											<td>#getProblemData.PART_CONTAINER_ID#</td>
										</tr> 
									</cfloop>
								</tbody>
							</table>
						</cfif>
					<cfrethrow>
				</cfcatch>
				</cftry>
			</cftransaction>
			<cfif container_updates GT 1><cfset plural="s"><cfelse><cfset plural=""></cfif>
			<h3 class="mt-4">Updated #container_updates# part#plural# with containers.</h3>
				<h3 class="text-success">Success, changes applied. </h3>
				<h3><a href="/Specimens.cfm?execute=true&builderMaxRows=1&action=builderSearch&openParens1=0&field1=COLL_OBJECT%3ACOLL_OBJ_COLLECTION_OBJECT_ID&searchText1=#encodeForUrl(valuelist(getTempData.collection_object_id))#&closeParens1=0">Specimen Records</a></h3>
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
