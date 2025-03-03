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
<!--- special case handling to dump problem data as csv --->
<cfif isDefined("action") AND action is "dumpProblems">
	<cfquery name="getProblemData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		SELECT INSTITUTION_ACRONYM,COLLECTION_CDE,OTHER_ID_TYPE,OTHER_ID_NUMBER,PART_NAME,PRESERVE_METHOD,CONTAINER_UNIQUE_ID
		FROM cf_temp_barcode_parts
		WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
	</cfquery>
	<cfinclude template="/shared/component/functions.cfc"><!---need to add to functions.cfc page--->
	<cfset csv = queryToCSV(getProblemData)>
	<cfheader name="Content-Type" value="text/csv">
	<cfoutput>#csv#</cfoutput>
	<cfabort>
</cfif>
<cfset fieldlist = "INSTITUTION_ACRONYM,COLLECTION_CDE,OTHER_ID_TYPE,OTHER_ID_NUMBER,PART_NAME,PRESERVE_METHOD,CONTAINER_UNIQUE_ID">
<cfset fieldTypes ="CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR">
<cfset requiredfieldlist = "OTHER_ID_TYPE,OTHER_ID_NUMBER,COLLECTION_CDE,INSTITUTION_ACRONYM,PART_NAME,PRESERVE_METHOD,CONTAINER_UNIQUE_ID">
	

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
<cfset pageTitle = "Bulk Part Container">
<cfinclude template="/shared/_header.cfm">
<cfinclude template="/tools/component/csv.cfc" runOnce="true"><!--- for common csv functions --->
<cfif not isDefined("action") OR len(action) EQ 0>
	<cfset action="nothing">
</cfif>
<main class="container-fluid px-xl-5 py-3" id="content">
	<h1 class="h2 mt-2">Bulkload Part Containers </h1>
	<cfif #action# is "nothing">
		<cfoutput>
			<p>Use this form to put collection objects (that is, parts) in containers. Parts and containers must already exist. This form can be used for specimen records with multiple parts as long as the full names (name plus preserve method) of the parts are unique. Upload a comma-delimited text file (csv).  Include column headings, spelled exactly as below.  Additional colums will be ignored.</p>
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
	<cfif #action# is "getFile">
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
		</cftry>
		</cfoutput>
	</cfif>
	<!------------------------------------------------------->
	<!------------------------------------------------------->
	<cfif #action# is "validate">
		<cfoutput>
			<h2 class="h4 mb-3">Second step: Data Validation</h2>
			<cfset key = ''>
			<cfset new_container_unique_id = ''>
			<cfquery name="getTempTableTypes" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				select 
					trim(institution_acronym) institution_acronym,
					trim(collection_cde) collection_cde,
					trim(other_id_type) other_id_type,
					trim(other_id_number) oidnum,
					trim(part_name) part_name,
					trim(preserve_method) preserve_method,
					trim(container_unique_id) container_unique_id,
					key
				from
					cf_temp_barcode_parts
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfloop query ='getTempTableTypes'> 
				<cfif other_id_type is "catalog number">
					<cfquery name="coll_obj" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						update cf_temp_barcode_parts set collection_object_id = (
							SELECT specimen_part.collection_object_id 
							FROM cataloged_item, specimen_part, collection
							WHERE cataloged_item.collection_object_id = specimen_part.derived_from_cat_item 
							AND cataloged_item.collection_id = collection.collection_id
							AND collection.collection_cde=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempTableTypes.collection_cde#">
							AND collection.institution_acronym = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempTableTypes.institution_acronym#">
							AND cat_num=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempTableTypes.oidnum#">
							AND part_name=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempTableTypes.part_name#">
							AND preserve_method = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempTableTypes.preserve_method#">),
						status = null
						WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						AND key = <cfqueryparam cfsqltype="CF_SQL_decimal" value="#getTempTableTypes.key#">
					</cfquery>
				<cfelse>
					<cfquery name="coll_obj" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						update cf_temp_barcode_parts set collection_object_id = (
							SELECT specimen_part.collection_object_id 
							FROM cataloged_item, specimen_part, coll_obj_other_id_num, collection
							WHERE cataloged_item.collection_object_id = specimen_part.derived_from_cat_item 
							AND cataloged_item.collection_object_id = coll_obj_other_id_num.collection_object_id 
							AND cataloged_item.collection_id = collection.collection_id 
							AND collection.collection_cde = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempTableTypes.collection_cde#">
							AND collection.institution_acronym = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempTableTypes.institution_acronym#"> 
							AND other_id_type=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempTableTypes.other_id_type#"> 
							AND display_value= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempTableTypes.oidnum#">
							AND part_name= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempTableTypes.part_name#">
							AND preserve_method = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempTableTypes.preserve_method#">),
						status = null
						WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						and key = <cfqueryparam cfsqltype="CF_SQL_decimal" value="#getTempTableTypes.key#"> 
					</cfquery>
				</cfif>
				
			</cfloop>			
			<cfquery name="check" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				select key,collection_object_id
				from cf_temp_barcode_parts
				where username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfloop query="check">
				<!--- get current container based on coll_obj_cont_hist or default--->
				<cfquery name="getCont" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE cf_temp_barcode_parts 
					SET 
						part_container_id = (
							select container_id 
							from 
								coll_obj_cont_hist 
							where 
								collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#check.collection_object_id#">
							AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#"> 
							AND key = '#key#'
							)
				</cfquery>
				<cfquery name="bad" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE cf_temp_barcode_parts
					SET 
						status = concat(nvl2(status, status || '; ', ''),' There is no part match to a cataloged item on "'||other_id_type||'" = "'||other_id_number||'" in collection "'||collection_cde||'"')
					WHERE collection_object_id IS NULL
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						AND key = '#key#'
				</cfquery>
			</cfloop>
			<cfquery name="check2" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				select 
					key,container_unique_id
				from 
					cf_temp_barcode_parts 
				where 
					username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfloop query="check2">
				<cfquery name="isGoodParent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					update cf_temp_barcode_parts set container_id = (
						select container_id from container 
						where container_type <> 'collection object' 
						and barcode=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#check2.container_unique_id#"> 
						)
					where 
						username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						and key = '#key#'
				</cfquery>
				<cfquery name="setter1" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE cf_temp_barcode_parts 
					SET parent_container_id = (
						select parent_container_id from container
						where barcode = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#check2.container_unique_id#">
						)
					where 
						username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#"> 
						and key = '#key#'
				</cfquery>
			</cfloop>
			<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT *
				FROM cf_temp_barcode_parts 
				WHERE 
					username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="pf" dbtype="query">
				SELECT count(*) c 
				FROM data 
				WHERE status is not null
			</cfquery>
				<h3>
					<cfif pf.c gt 0>
						There is a problem with #pf.c# of #data.recordcount# row(s). See the STATUS column. (<a href="/tools/BulkloadPartContainer.cfm?action=dumpProblems">download</a>). Fix the problems in the data and <a href="/tools/BulkloadPartContainer.cfm" class="text-danger">start again</a>.
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
						<th>COLLECTION_OBJECT_ID</th>
						<th>CONTAINER_UNIQUE_ID</th>
						<th>CONTAINER_ID</th>
						<th>PARENT_CONTAINER_ID</th>
						<th>PART_CONTAINER_ID</th>
					</tr>
				<tbody>
					<cfloop query="data">
						<tr>
							<td><cfif len(data.status) eq 0>Cleared to load<cfelse><strong>#data.status#</strong></cfif></td>
							<td>#data.institution_acronym#</td>
							<th>#data.collection_cde#</th>
							<td>#data.other_ID_TYPE#</td>
							<td>#data.other_id_number#</td>
							<td>#data.collection_object_id#</td>
							<td>#data.CONTAINER_UNIQUE_ID#</td>
							<td>#data.container_id#</td>
							<td>#data.parent_container_id#</td>
							<td>#data.part_container_id#</td>
						</tr>
					</cfloop>
				</tbody>
			</table>
			</div>
		</cfoutput>
	</cfif>
	<!-------------------------------------------------------------------------------------------->
	<cfif action is "load">
		<h2 class="h4">Third step: Apply changes.</h2>
		<cfoutput>
			<cfquery name="getTempData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT 
					key,parent_container_id,part_container_id,container_id,container_unique_id,collection_object_id 
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
						<cfquery name="updateContainer" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="updateContainer_result">
							UPDATE
								container
							SET
								container_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempData.container_id#">
							WHERE
								parent_container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempData.part_container_id#">
								and barcode = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.container_unique_id#">
						</cfquery>
						<cfquery name="updateContainer1" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="updateContainer1_result">
							UPDATE
								coll_obj_cont_hist
							SET
								container_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempData.container_id#">
							WHERE
								collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempData.collection_object_id#">
						</cfquery>
						<cfset container_updates = container_updates + updateContainer_result.recordcount>
					</cfloop>
					<cftransaction action="commit">
				<cfcatch>
					<cftransaction action="rollback">
					<cfquery name="getProblemData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						SELECT * 
						FROM 
							cf_temp_barcode_parts 
						WHERE 
							key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#problem_key#">
					</cfquery>
					<h3>Error updating row (#container_updates + 1#): #cfcatch.message#</h3>
					<table class='sortable table table-responsive table-striped d-lg-table'>
						<thead>
							<tr>
								<th>BULKLOADING&nbsp;STATUS</th>
								<th>CONTAINER_UNIQUE_ID</th>
								<th>PART_CONTAINER_ID</th>
								<th>CONTAINER_ID</th>
							</tr> 
						</thead>
						<tbody>
							<cfloop query="getProblemData">
								<tr>
									<td><cfif len(getProblemData.status) eq 0>Cleared to load<cfelse><strong>#getProblemData.status#</strong></cfif></td>
									<td>#getProblemData.container_unique_id#</td>
									<td>#getProblemData.part_container_id#</td>
									<td>#getProblemData.container_id#</t
								></tr> 
							</cfloop>
						</tbody>
					</table>
					<cfrethrow>
				</cfcatch>
				</cftry>
			</cftransaction>
			<cfif container_updates GT 1><cfset plural="s"><cfelse><cfset plural=""></cfif>
			<h3 class="mt-4">Updated #container_updates# container#plural#.</h3>
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
