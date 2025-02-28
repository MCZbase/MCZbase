<!--- tools/bulkloadLoanItems.cfm.cfm add Loan Items (parts) to a loan in bulk.

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
<!--- page can submit with action either as a form post parameter or as a url parameter, obtain either into variable scope. --->
<cfif isDefined("url.action")><cfset variables.action = url.action></cfif>
<cfif isDefined("form.action")><cfset variables.action = form.action></cfif>
<cfif isDefined("variables.action") AND variables.action is "dumpProblems">
	<cfquery name="getProblemData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		SELECT REGEXP_REPLACE( status, '\s*</?\w+((\s+\w+(\s*=\s*(".*?"|''.*?''|[^''">\s]+))?)+\s*|\s*)/?>\s*', NULL, 1, 0, 'im') AS 
				STATUS, INSTITUTION_ACRONYM,COLLECTION_CDE,OTHER_ID_TYPE,OTHER_ID_NUMBER,PART_NAME,PART_REMARKS,ITEM_INSTRUCTIONS,ITEM_REMARKS,CONTAINER_BARCODE,PRESERVE_METHOD,SUBSAMPLE,LOAN_NUMBER,CONDITION,COLL_OBJ_DISPOSITION,PART_COLLECTION_OBJECT_ID,TRANSACTION_ID
		FROM cf_temp_loan_item 
		WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
		ORDER BY key
	</cfquery>
	<cfinclude template="/shared/component/functions.cfc">
	<cfinclude template="/shared/functionLib.cfm">
	<cfset csv = queryToCSV(getProblemData)>
	<cfheader name="Content-Type" value="text/csv">
	<cfoutput>#csv#</cfoutput>
	<cfabort>
</cfif>
<cfset fieldlist = "INSTITUTION_ACRONYM,COLLECTION_CDE,OTHER_ID_TYPE,OTHER_ID_NUMBER,PART_NAME,PART_REMARKS,ITEM_INSTRUCTIONS,ITEM_REMARKS,CONTAINER_BARCODE,PRESERVE_METHOD,SUBSAMPLE,LOAN_NUMBER,CONDITION,COLL_OBJ_DISPOSITION,PART_COLLECTION_OBJECT_ID,TRANSACTION_ID">
<cfset fieldTypes = "CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_DECIMAL,CF_SQL_DECIMAL">
<cfif listlen(fieldlist) NEQ listlen(fieldTypes)>
	<cfthrow message = "Error: Bug in the definition of fieldlist[#listlen(fieldlist)#] and fieldType[#listlen(fieldTypes)#] lists, lists must be the same length, but are not.">
</cfif>
<cfset requiredfieldlist = "INSTITUTION_ACRONYM,COLLECTION_CDE,OTHER_ID_TYPE,OTHER_ID_NUMBER,PART_NAME,CONDITION,COLL_OBJ_DISPOSITION,PRESERVE_METHOD,SUBSAMPLE,LOAN_NUMBER">

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
<cfset pageTitle = "Bulkload Loan Items">
<cfinclude template="/shared/_header.cfm">
<cfinclude template="/tools/component/csv.cfc" runOnce="true"><!--- for common csv testing functions --->
<cfif not isDefined("action") OR len(action) EQ 0><cfset action="entryPoint"></cfif>
	
<main class="container-fluid py-3 px-5" id="content">
	<!--- Style elements for proof of concept accordion that will need to move to a css file --->
	<!--- NOTE: This should be replaced with a jquery-ui accordion --->
	<style>
			.accordion-button::after {
			content: none;
		}
			.accordion-header .fa {
			transition: transform 0.3s ease-in-out;
		}
			.accordion-button.collapsed .fa-plus {
			transform: rotate(0deg);
		}
			.accordion-button .fa-plus {
			transform: rotate(45deg);
		}
	</style>
	<!--- End proof of concept style block --->
	<h1 class="h2 mt-2">Bulkload Loan Items</h1>
	<cfif variables.action is "entryPoint">
		<cfoutput>
			<p>This tool is used to bulkload loan items (connect parts to a loan).</p>
			<p>The following must all be true to use this form:</p>
			<ul>
				<li>Items in the file you load are not already on loan (check part disposition)</li>
				<li>Encumbrances have been checked</li>
				<li>A loan has been created in MCZbase.</li>
				<li>Loan Item reconciled person is you (username) - automatically added</li>
				<li>Loan Item reconciled date is today (2024-07-18) - automatically added</li>
			</ul>
			
			<h2 class="h4">Use Template to Load Data</h2>
			<button class="btn btn-xs btn-primary float-left mr-3" id="copyButton">Copy Column Headers</button>
			<div id="template" class="my-1 mx-0">
				<label for="templatearea" class="data-entry-label" style="line-height: inherit;">
					Copy this header line, paste it into a blank worksheet, and save it as a .csv file or <a href="/tools/BulkloadLoanItems.cfm?action=getCSVHeader" class="font-weight-bold">download</a> a template.
				</label>
				<textarea style="height: 56px;" cols="90" id="templatearea" class="mb-1 w-100 data-entry-textarea small">#fieldlist#</textarea>
			</div>
			<div class="accordion" id="accordionIdentifiers">
				<div class="card mb-2 bg-light">
					<div class="card-header" id="headingIdentifiers">
						<h3 class="h5 my-0">
							<button type="button" role="button" aria-label="identifiers pane" class="headerLnk text-left w-100" data-toggle="collapse" data-target="##identifiersPane" aria-expanded="false" aria-controls="identifiersPane">
								Data Entry Instructions per Column
							</button>
						</h3>
					</div>
					<div id="identifiersPane" class="collapse" aria-labelledby="headingIdentifiers" data-parent="##accordionIdentifiers">
						<div class="card-body" id="identifiersCardBody">
						<p class="px-3 pt-2"> Columns in <span class="text-danger">red</span> are required; others are optional.</p>
							<ul class="mb-4 h5 font-weight-normal list-group mx-3">
								<cfloop list="#fieldlist#" index="field" delimiters=",">
									<cfquery name = "getComments"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#"  result="getComments_result">
										SELECT comments
										FROM sys.all_col_comments
										WHERE 
											owner = 'MCZBASE'
											and table_name = 'CF_TEMP_LOAN_ITEMS'
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
			<div>
				<h2 class="h4 mt-4">Upload a comma-delimited text file (csv)</h2>
				<form name="getFiles" method="post" enctype="multipart/form-data" action="/tools/BulkloadLoanItems.cfm">
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
			</div>
		</cfoutput>
	</cfif>
	
	<!------------------------------------------------------->

	<cfif #action# is "getFile">
		<h2 class="h4">First step: Reading data from CSV file.</h2>
		<cfoutput>
		<!--- Compare the numbers of headers expected against provided in CSV file --->
		<!--- Set some constants to identify error cases in cfcatch block --->
		<cfset NO_COLUMN_ERR = "One or more required fields are missing in the header line of the csv file.">
		<cfset DUP_COLUMN_ERR = "One or more columns are duplicated in the header line of the csv file.">
		<cfset COLUMN_ERR = "Error inserting data">
		<cfset NO_HEADER_ERR = "No header line found, csv file appears to be empty.">
		<cfset TABLE_NAME = "CF_TEMP_LOAN_ITEM">
		<cftry>
			<!--- cleanup any incomplete work by the same user --->
			<cfquery name="clearTempTable" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="clearTempTable_result">
				DELETE FROM CF_TEMP_LOAN_ITEM
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
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
					There are #ListLen(fieldList)# columns expected in the header (of these #ListLen(requiredFieldList)# are required).
				</div>

				<!--- check for required fields in header line, list all fields, throw exception and fail if any required fields are missing --->
				<cfset reqFieldsResponse = checkRequiredFields(fieldList=fieldList,requiredFieldList=requiredFieldList,NO_COLUMN_ERR=NO_COLUMN_ERR,TABLE_NAME=TABLE_NAME)>

				<!--- Test for additional columns not in list, warn and ignore. --->
				<cfset addFieldsResponse = checkAdditionalFields(fieldList=fieldList)>

				<!--- Identify duplicate columns and fail if found --->
				<cfset dupFieldsResponse = checkDuplicateFields(foundHeaders=variables.foundHeaders,DUP_COLUMN_ERR=DUP_COLUMN_ERR)>

				<cfset colNames="#variables.foundHeaders#">
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
							insert into cf_temp_loan_item
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
					<cfset extendedResult = reportExtended(foundHighCount=foundHighCount,foundHighAscii=foundHighAscii,foundMultiByte=foundMultiByte,linkTarget='/tools/BulkloadLoanItems.cfm')>	
				</cfif>
				<h3 class="mt-3">
					<cfif loadedRows EQ 0>
						Loaded no rows from the CSV file. The file appears to be just a header with no data. Fix file and <a href="/tools/BulkloadLoanItems.cfm" class="text-danger">start again</a>
					<cfelse>
						<cfif variables.size eq 1>
							Size = 1
						<cfelse>
						Successfully read #loadedRows# records from the CSV file. Next <a href="/tools/BulkloadLoanItems.cfm?action=validate" class="btn-link font-weight-lessbold">click to validate</a>.</cfif>
					</cfif>
				</h3>
			<cfcatch>
				<h3 class="mt-3">
					<strong class="text-danger">Failed to read the CSV file.</strong> Fix the errors in the file and <a href="/tools/BulkloadLoanItems.cfm" class="text-danger">start again</a>.
				</h3>
				<cfif isDefined("variables.foundHeaders")>
					<cfset foundHighCount = 0>
					<cfset foundHighAscii = "">
					<cfset foundMultiByte = "">
					<cfloop list="#variables.foundHeaders#" index="thisBit">
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
						<cfset extendedResult = reportExtended(foundHighCount=foundHighCount,foundHighAscii=foundHighAscii,foundMultiByte=foundMultiByte,linkTarget='/tools/BulkloadLoanItems.cfm',inHeader='yes')>	
					</cfif>
				</cfif>
				<!--- identify and provide guidance for some standard failure conditions --->
				<cfif format EQ "DEFAULT"><cfset fmt="CSV: Default Comma Separated values"><cfelse><cfset fmt="#format#"></cfif>
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
					<h4 class='mb-3'>
						Unable to read headers in line 1.  Is your file actually have the format #fmt#?
					</h4>
					<h4 class='mb-3'>#cfcatch.message#</h4>
				<cfelseif Find("invalid char between encapsulated token and delimiter",cfcatch.message) GT 0>
					<h4 class='mb-3'>
						Does your file have an inconsitent format?  Are some lines tab delimited but others comma delimited?
					</h4>
				<cfelseif Find("IOException reading next record: java.io.IOException:",cfcatch.message) GT 0>
					<h4 class='mb-3'>
						Unable to read a record from the file.  One or more lines may not be consistent with the specified format #fmt#
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
			
	<!------------------------------------------------------->

	<cfif #action# is "validate">
		<h2 class="h4">Second step: Data Validation</h2>
		<cfoutput>
			<cfquery name="getParts" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT INSTITUTION_ACRONYM,COLLECTION_CDE,OTHER_ID_TYPE,OTHER_ID_NUMBER,PART_NAME,PART_REMARKS,ITEM_INSTRUCTIONS,ITEM_REMARKS,CONTAINER_BARCODE,PRESERVE_METHOD,SUBSAMPLE,LOAN_NUMBER,CONDITION,COLL_OBJ_DISPOSITION,PART_COLLECTION_OBJECT_ID,KEY
				FROM 
					cf_temp_LOAN_ITEM
				WHERE 
					username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfloop query="getParts">
				<cfif len(PART_COLLECTION_OBJECT_ID) eq 0>
					<cfquery name="collObj" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						update
							cf_temp_loan_item
						set
							status=concat(nvl2(status, status || '; ', ''),'Part ID missing')
						where
						key=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#KEY#">
					</cfquery>
				<cfelse>
					<cfquery name="collObj" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						update
							cf_temp_loan_item
						set
							status=concat(nvl2(status, status || '; ', ''),'No matching part found; Item Description not created')
						where part_collection_object_id not in (
							select specimen_part.collection_object_id 
							from specimen_part, cataloged_item 
							where specimen_part.derived_from_cat_item = cataloged_item.collection_object_id
							) and
						key=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#KEY#"> and
						username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.USERNAME#">
					</cfquery>
				</cfif>
			</cfloop>

			<cfquery name="getTempDataQC" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT INSTITUTION_ACRONYM,COLLECTION_CDE,OTHER_ID_TYPE,OTHER_ID_NUMBER,PART_NAME,PART_REMARKS,ITEM_INSTRUCTIONS,ITEM_REMARKS,ITEM_DESCRIPTION,CONTAINER_BARCODE,PRESERVE_METHOD,SUBSAMPLE,LOAN_NUMBER,PART_COLLECTION_OBJECT_ID,TRANSACTION_ID,STATUS,KEY
				FROM 
					CF_TEMP_LOAN_ITEM
				WHERE 
					username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfloop query="getTempDataQC">
				<cfif getTempDataQC.recordcount is 0><!--- no part --->
				<!---no part--->
					<cfquery name="BadCollObj" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						update
							cf_temp_loan_item
						set
							status=concat(nvl2(status, status || '; ', ''),'No Parts Found')
						where
							key=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#KEY#">
					</cfquery>
				<cfelseif getTempDataQC.recordcount gt 1 and len(part_COLLECTION_OBJECT_ID) is 0 >
					<cfquery name="BadCollObj" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						update
							cf_temp_loan_item
						set
							status=concat(nvl2(status, status || '; ', ''),'PART COLLECTION OBJECT ID could not be made. Check other_id_type, other_id_number, collection_cde, and part_name. Make sure part is not already on loan')
						where
							key=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#KEY#">
							and username=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
					</cfquery>
				</cfif>
				<cfquery name="loanID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					update
						cf_temp_loan_item
					set
						transaction_id= (
							select
								transaction_id
							from
								loan
							where
								loan_number = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempDataQC.loan_number#">
						)
					where username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
					and key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempDataQC.key#"> 
				</cfquery>
				<cfquery name="bad_loan_num" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					update
						cf_temp_loan_item
					set
						status = concat(nvl2(status, status || '; ', ''),'Loan ['|| loan_number ||'] does not exist')
					where 
						transaction_id is null
						and username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						and key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempDataQC.key#"> 
				</cfquery>
				<!--- flag invalid collection code --->
				<cfquery name="ctPartNameProblems" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="flatAttributeProblems_result">
					UPDATE cf_temp_loan_item
					SET
						status = concat(nvl2(status, status || '; ', ''),'Part_Name ['|| part_name ||'] not allowed for collection_cde ' || collection_cde)
					WHERE 
						part_name IS NOT NULL
						AND part_name NOT IN (
							SELECT part_name 
							FROM ctspecimen_part_name 
							WHERE collection_cde = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempDataQC.collection_cde#">
						)
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						AND key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempDataQC.key#">
				</cfquery>
				<cfquery name="ctBarcodeProblems" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="flatAttributeProblems_result">
					UPDATE cf_temp_loan_item
					SET
						status = concat(nvl2(status, status || '; ', ''),'Barcode (a.k.a. container_unique_id): ['|| CONTAINER_BARCODE ||'] is not valid. If not known, enter "The Museum of Comparative Zoology"')
					WHERE 
						CONTAINER_barcode IS NOT NULL
						AND CONTAINER_barcode NOT IN (
							SELECT barcode
							FROM container
							WHERE barcode  = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempDataQC.container_barcode#">
						)
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						AND key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempDataQC.key#">
				</cfquery>
				<cfquery name="ctOtherIDProblems" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="flatAttributeProblems_result">
					UPDATE cf_temp_loan_item
					SET
						status = concat(nvl2(status, status || '; ', ''),'OTHER_ID_TYPE: ['|| OTHER_ID_TYPE ||'] not valid')
					WHERE other_id_type NOT IN (
							SELECT other_id_type
							FROM ctcoll_other_id_type
							WHERE other_id_type  = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempDataQC.other_id_type#">
						) 
						AND other_id_type <> 'catalog number'
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						AND key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempDataQC.key#">
				</cfquery>
				<cfquery name="defDescr" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					update
						cf_temp_loan_item
						set ITEM_DESCRIPTION = 
						(
							select collection.collection_cde || ' ' || cat_num || ' ' || part_name || '' || preserve_method || '' ||
							from
							cataloged_item,
							collection,
							specimen_part
							where
							specimen_part.derived_from_cat_item = cataloged_item.collection_object_id and
							cataloged_item.collection_id = collection.collection_id and
						specimen_part.collection_object_id = '#getTempDataQC.PART_COLLECTION_OBJECT_ID#'
						)
					where ITEM_DESCRIPTION IS NULL 
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
					and key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#key#"> 
				</cfquery>
			</cfloop>
			<cfquery name="ctSubsampleProblems" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="flatAttributeProblems_result">
				UPDATE cf_temp_loan_item
				SET
					status = concat(nvl2(status, status || '; ', ''),'Subsample ["'|| subsample ||'"] is not an accepted value (enter "yes" or "no")')
				WHERE 
					subsample IS NOT NULL
					AND subsample != upper('no') 
					AND subsample != lower('no') 
					AND subsample != upper('yes') 
					AND subsample != lower('yes')
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="ctSubsampleProblems" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="flatAttributeProblems_result">
				UPDATE cf_temp_loan_item
				SET
					status = concat(nvl2(status, status || '; ', ''),'Institution acronym is not "MCZ"')
				WHERE 
					institution_acronym is not null
					AND institution_acronym <> 'MCZ'
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfloop list="#requiredfieldlist#" index="requiredField">
				<cfquery name="checkRequired" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE cf_temp_loan_item
					SET 
						status = concat(nvl2(status, status || '; ', ''),'#requiredField# is missing')
					WHERE #requiredField# is null
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
			</cfloop>
			<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT STATUS,INSTITUTION_ACRONYM,COLLECTION_CDE,OTHER_ID_TYPE,OTHER_ID_NUMBER,PART_NAME,PART_REMARKS,ITEM_INSTRUCTIONS,ITEM_REMARKS,ITEM_DESCRIPTION,CONTAINER_BARCODE,SUBSAMPLE,LOAN_NUMBER,PART_COLLECTION_OBJECT_ID,TRANSACTION_ID,KEY
				FROM 
					cf_temp_LOAN_ITEM
				WHERE 
					username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="pf" dbtype="query">
				SELECT count(*) c 
				FROM data 
				WHERE status is not null
			</cfquery>
			<h3 class="mt-3">
				<cfif pf.c gt 0>
					There is a problem with #pf.c# of #data.recordcount# row(s). See the STATUS column. (<a href="/tools/BulkloadLoanItems.cfm?action=dumpProblems">download</a>). Fix the problems in the data and <a href="/tools/BulkloadLoanItems.cfm" class="text-danger">start again</a>.
				<cfelse>
					<span class="text-success">Validation checks passed</span>. Look over the table below and <a href="/tools/BulkloadLoanItems.cfm?action=load" class="btn-link font-weight-lessbold">click to continue</a> if it all looks good or <a href="/tools/BulkloadLoanItems.cfm" class="text-danger">start again</a>.
				</cfif>
			</h3>
			<table class='sortable px-0 mx-0 table small table-responsive table-striped w-100'>
				<thead>
					<tr>
						<th>BULKLOADING&nbsp;STATUS</th>
						<th>INSTITUTION_ACRONYM</th>
						<th>COLLECTION_CDE</th>
						<th>OTHER_ID_TYPE</th>
						<th>OTHER_ID_NUMBER</th>
						<th>PART_NAME</th>
						<th>PART_REMARKS</th>
						<th>ITEM_INSTRUCTIONS</th>
						<th>ITEM_REMARKS</th>
						<th>ITEM_DESCRIPTION</th>
						<th>CONTAINER_BARCODE</th>
						<th>SUBSAMPLE</th>
						<th>LOAN_NUMBER</th>
						<th>PART_COLLECTION_OBJECT_ID</th>
						<th>TRANSACTION_ID</th>
						<th>KEY</th>
					</tr>
				<tbody>
					<cfloop query="data">
						<tr>
							<td><cfif len(data.status) eq 0>Cleared to load<cfelse><strong>#data.status#</strong></cfif></td>
							<td>#data.INSTITUTION_ACRONYM#</td>
							<td>#data.COLLECTION_CDE#</td>
							<td>#data.OTHER_ID_TYPE#</td>
							<td>#data.OTHER_ID_NUMBER#</td>
							<td>#data.PART_NAME#</td>
							<td>#data.PART_REMARKS#</td>
							<td>#data.ITEM_INSTRUCTIONS#</td>
							<td>#data.ITEM_REMARKS#</td>
							<td>#data.ITEM_DESCRIPTION#</td>
							<td>#data.CONTAINER_BARCODE#</td>
							<td>#data.SUBSAMPLE#</td>
							<td>#data.LOAN_NUMBER#</td>
							<td>#data.PART_COLLECTION_OBJECT_ID#</td>
							<td>#data.TRANSACTION_ID#</td>
							<td>#data.KEY#</td>
						</tr>
					</cfloop>
				</tbody>
			</table>
		</cfoutput>
	</cfif>
	<!-------------------------------------------------------------------------------------------->

	<!-------------------------------------------------------------------------------------------->
	<cfif #action# is "load">
		<h2 class="h4">Third step: Apply changes.</h2>
			<cfoutput>
				<cfset problem_key = "">
				<cftransaction>
				<cfquery name="getTempData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					select *
					from cf_temp_loan_item
					WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cfquery name="getCountParts" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT count(distinct PART_COLLECTION_OBJECT_ID) ctObj 
					FROM cf_temp_loan_item
					WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cfquery name="getCountLoans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT count(distinct loan_number) ctTrans 
					FROM cf_temp_loan_item
					WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cftry>
					<cfset loan_updates = 0>
					<cfset loan_updates1 = 0>
					<cfif getTempData.recordcount EQ 0>
						<cfthrow message="You have no rows to load in the loan item bulkloader table (cf_temp_loan_item). <a href='/tools/BulkloadLoanItems.cfm' class='text-danger'>Start over</a>">
					</cfif>
					<cfloop query="getTempData">
						<cfset problem_key = getTempData.key>
						<cfif subsample is "yes">
							<cfquery name="nid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
								select sq_collection_object_id.nextval nid from dual
							</cfquery>
							<cfset thisPART_COLLECTION_OBJECT_ID=nid.nid>
							<cfquery name="makeSubsampleObj" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#"result="updateLoanItem_result">
								INSERT INTO coll_object (
									COLLECTION_OBJECT_ID,
									COLL_OBJECT_TYPE,
									ENTERED_PERSON_ID,
									COLL_OBJECT_ENTERED_DATE,
									LAST_EDITED_PERSON_ID,
									COLL_OBJ_DISPOSITION,
									LOT_COUNT,
									CONDITION,
									FLAGS
								) (
									select
										#thisPART_COLLECTION_OBJECT_ID#,
										'SS',
										#session.myAgentId#,
										sysdate,
										NULL,
										'on loan',
										lot_count,
										condition,
										flags
									from
										coll_object
									where
										collection_object_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.PART_COLLECTION_OBJECT_ID#">
								)
							</cfquery>
							<cfquery name="makeSubsample" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
								INSERT INTO specimen_part (
									COLLECTION_OBJECT_ID,
									PART_NAME,
									PRESERVE_METHOD,
									DERIVED_FROM_cat_item,
									sampled_from_obj_id
								) ( 
									select
										#thisPART_COLLECTION_OBJECT_ID#,
										part_name,
										PRESERVE_METHOD,
										DERIVED_FROM_cat_item,
										<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.PART_COLLECTION_OBJECT_ID#">
									FROM
										specimen_part
									WHERE
										collection_object_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.PART_COLLECTION_OBJECT_ID#">
								)
							</cfquery>
						<cfelse>
							<cfset thisPART_COLLECTION_OBJECT_ID=#PART_COLLECTION_OBJECT_ID#>
							<cfquery name="updateDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
								update coll_object set 
									coll_obj_disposition = 'on loan'
								where
									collection_object_id ='#thisPART_COLLECTION_OBJECT_ID#'
							</cfquery>
						</cfif>
						<cfquery name="move" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="updateLoan_result">
							INSERT INTO loan_item (
							collection_object_id,
							RECONCILED_BY_PERSON_ID,
							reconciled_date,
							<cfif len(#getTempData.ITEM_INSTRUCTIONS#) gt 0>
								item_instructions,
							</cfif>
							<cfif len(#getTempData.ITEM_REMARKS#) gt 0>
								LOAN_ITEM_REMARKS,
							</cfif>
							item_descr,
							transaction_id
							) VALUES (
							<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#thisPART_COLLECTION_OBJECT_ID#">,
							<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#session.myAgentId#">,
							sysdate,
							<cfif len(#getTempData.ITEM_INSTRUCTIONS#) gt 0>
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ITEM_INSTRUCTIONS#">,
							</cfif>
							<cfif len(#getTempData.ITEM_REMARKS#) gt 0>
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ITEM_REMARKS#">,
							</cfif>
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ITEM_DESCRIPTION#">,
							<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#TRANSACTION_ID#">
							)
						</cfquery>
						<cfquery name="updateLoan1" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="updateLoan1_result">
							select transaction_id, collection_object_id from loan_item 
							where collection_object_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.PART_COLLECTION_OBJECT_ID#">
							group by transaction_id, collection_object_id
							having count(*) > 1
						</cfquery>
						<cfset loan_updates = loan_updates + updateLoan_result.recordcount>
						<cfif updateLoan1_result.recordcount gt 0>
							<cfthrow message = "Error: attempting to insert duplicated loan item.">
						</cfif>
					</cfloop>
					<cfif #getCountLoans.ctTrans# gt 1><cfset plural="s"><cfelse><cfset plural=""></cfif>
					<cfif getTempData.recordcount eq loan_updates>
						<p>Number of loan items updated: #getCountParts.ctObj# in #loan_updates# cataloged_items (on #getCountLoans.ctTrans# loan#plural#)</p>
						<h3 class="text-success">Success - loaded</h3>
					<cfelse>
						<cfthrow message="Error: Number of successful updates did not match number of records to update.">
					</cfif>
					<cftransaction action="COMMIT">
				<cfcatch>
						<cftransaction action="ROLLBACK">
						<h3>There was a problem updating the loan items.</h3>
						<cfquery name="getProblemData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							SELECT STATUS,INSTITUTION_ACRONYM,COLLECTION_CDE,OTHER_ID_TYPE,OTHER_ID_NUMBER,PART_NAME,ITEM_INSTRUCTIONS,ITEM_REMARKS,ITEM_DESCRIPTION,CONTAINER_BARCODE,SUBSAMPLE,LOAN_NUMBER,PART_COLLECTION_OBJECT_ID,TRANSACTION_ID
							FROM cf_temp_loan_item 
							WHERE key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#problem_key#">
						</cfquery>
						<cfquery name="getCollectionCodes" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							SELECT collection_cde
							FROM collection
						</cfquery>
						<cfset collection_codes = "">
						<cfloop query="getCollectionCodes">
							<cfset collection_codes = ListAppend(collection_codes,getCollectionCodes.collection_cde)>
						</cfloop>
						<cfquery name="getInstitution" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							SELECT distinct institution_acronym
							FROM collection
						</cfquery>
						<cfset institutions = "">
						<cfloop query="getInstitution">
							<cfset institutions = ListAppend(institutions,getInstitution.institution_acronym)>
						</cfloop>
						<cfif getProblemData.recordcount GT 0>
							<h3>Errors at this stage are displayed one row at a time, more errors may exist in this file.</h3>
							<h3>
								Error loading row (<span class="text-danger">#loan_updates + 1#</span>) from the CSV: 
								<cfif len(cfcatch.detail) gt 0>
									<span class="font-weight-normal border-bottom border-danger">
										<cfif cfcatch.detail contains "Invalid LOAN_NUMBER">
											LOAN_NUMBER is invalid; Does it exist in MCZbase?
										<cfelseif cfcatch.detail contains "collection_cde">
											COLLECTION_CDE does not match abbreviated collection (#collection_codes#)
										<cfelseif cfcatch.detail contains "institution_acronym">
											INSTITUTION_ACRONYM does not match #institutions# (all caps)
										<cfelseif cfcatch.detail contains "other_id_type">
											OTHER_ID_TYPE is not valid
										<cfelseif cfcatch.detail contains "subsample">
											SUBSAMPLE does not match "yes" or "no"
										<cfelseif cfcatch.detail contains "part_name">
											PART_NAME does not match controlled vocabulary
										<cfelseif cfcatch.detail contains "item_description">
											ITEM_DESCRIPTION invalid
										<cfelseif cfcatch.detail contains "item_instructions">
											ITEM_INSTRUCTIONS invalid
										<cfelseif cfcatch.detail contains "item_remarks">
											Problem with ITEM_REMARKS (#cfcatch.detail#)
										<cfelseif cfcatch.detail contains "OTHER_ID_NUMBER">
											Problem with OTHER_ID_NUMBER (#cfcatch.detail#)
										<cfelseif cfcatch.detail contains "CONTAINER_BARCODE">
											Problem with CONTAINER_BARCODE (#cfcatch.detail#)
										<cfelseif cfcatch.detail contains "no data">
											No data or the wrong data (#cfcatch.detail#)
										<cfelse>
											<!--- provide the raw error message if it isn't readily interpretable --->
											#cfcatch.detail#
										</cfif>
									</span>
								</cfif>
							</h3>
							<!--- Note: we can not link to a dump of the temp table as it will be cleared for this user at the end of this step --->
							<p>Fix the problems and <a href="/tools/BulkloadLoanItems.cfm">Reload your file</a></p> 
							<table class='px-0 sortable small table-danger w-100 table table-responsive table-striped mt-3'>
								<thead>
									<tr>
										<th>STATUS</th>
										<th>INSTITUTION_ACRONYM</th>
										<th>COLLECTION_CDE</th>
										<th>OTHER_ID_TYPE</th>
										<th>OTHER_ID_NUMBER</th>
										<th>LOAN_NUMBER</th>
										<th>PART_COLLECTION_OBJECT_ID</th>
										<th>TRANSACTION_ID</th>
										<th>BARCODE</th>
										<th>PART_NAME</th>
										<th>ITEM_DESCRIPTION</th>
										<th>SUBSAMPLE</th>
									</tr> 
								</thead>
								<tbody>
									<cfloop query="getProblemData">
										<tr>
											<td>#getProblemData.status# </td>
											<td>#getProblemData.institution_acronym# </td>
											<td>#getProblemData.collection_cde# </td>
											<td>#getProblemData.other_id_type#</td>
											<td>#getProblemData.other_id_number#</td>
											<td>#getProblemData.loan_number# </td>
											<td>#getProblemData.PART_COLLECTION_OBJECT_ID# </td>
											<td>#getProblemData.transaction_id# </td>
											<td>#getProblemData.container_barcode#</td>
											<td>#getProblemData.part_name# </td>
											<td>#getProblemData.item_description# </td>
											<td>#getProblemData.subsample# </td>
										</tr>
									</cfloop>
								</tbody>
							</table>
						</cfif>
						<div>#cfcatch.message#</div>
				</cfcatch>
				</cftry>
			</cftransaction>
			
			<cfquery name="clearTempTable" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="clearTempTable_result">
				DELETE FROM cf_temp_LOAN_ITEM
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
		</cfoutput>
	</cfif>
</main>
<cfinclude template="/shared/_footer.cfm">