<!--- tools/bulkloadOtherId.cfm add other identifiers (other numbers)
  to specimens in bulk.

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
		SELECT status,institution_acronym,collection_cde,existing_other_id_type,existing_other_id_number,new_other_id_type,new_other_id_number
		FROM cf_temp_OIDS 
		WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
		ORDER BY key
	</cfquery>
	<cfinclude template="/shared/component/functions.cfc">
	<cfset csv = queryToCSV(getProblemData)>
	<cfheader name="Content-Type" value="text/csv; charset=utf-8">
	<cfoutput>#csv#</cfoutput>
	<cfabort>
</cfif>
<!--- end special case dump of problems --->

<cfset fieldlist = "INSTITUTION_ACRONYM,COLLECTION_CDE,EXISTING_OTHER_ID_TYPE,EXISTING_OTHER_ID_NUMBER,NEW_OTHER_ID_TYPE,NEW_OTHER_ID_NUMBER">
<cfset fieldTypes ="CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR">
<cfset requiredfieldlist = "INSTITUTION_ACRONYM,COLLECTION_CDE,EXISTING_OTHER_ID_TYPE,EXISTING_OTHER_ID_NUMBER,NEW_OTHER_ID_TYPE,NEW_OTHER_ID_NUMBER">

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
<cfset pageTitle = "Bulkload Other IDs">
<cfinclude template="/shared/_header.cfm">
<cfinclude template="/tools/component/csv.cfc" runOnce="true"><!--- for common csv testing functions --->
<cfif not isDefined("action") OR len(action) EQ 0><cfset action="entryPoint"></cfif>
<main class="container-fluid py-3 px-xl-5" id="content">
	<h1 class="h2 mt-2">Bulkload Other IDs</h1>
	<cfif #action# is "entryPoint">
		<cfoutput>
			<p>This tool is used to bulkload Other IDs (other numbers for specimens). Copy the column headers or download a comma-delimited text file (csv), enter, and upload data. Pay attention to capitalization where it is required. Messages will help to locate, identify, and fix problems with the data in the uploaded .csv file. Note: The errors preventing upload are displayed first and then any warnings about content. Check the Help > Controlled Vocabulary page and select the <a href="/vocabularies/ControlledVocabulary.cfm?table=CTCOLL_OTHER_ID_TYPE">CTCOLL_OTHER_ID_TYPE</a> list for types ("catalog number" can also be used). Values can be combinations of letters, special characters, and numbers or just numbers. Submit a bug report to request an additional type when needed.</p>
			<h2 class="h4">Use Template to Load Data</h2>
			<button class="btn btn-xs btn-primary float-left mr-3" id="copyButton">Copy Column Headers</button>
			<div id="template" class="my-1 mx-0">
			<label for="templatearea" class="data-entry-label" style="line-height: inherit;">
					Copy this header line, paste it into a blank worksheet, and save it as a .csv file or <a href="/tools/BulkloadRelations.cfm?action=getCSVHeader" class="font-weight-bold">download</a> a template.
				</label>
				<textarea style="height: 30px;" cols="90" id="templatearea" class="mb-1 w-100 data-entry-textarea small">#fieldlist#</textarea>
			</div>
			<div class="accordion" id="accordionOtherid">
				<div class="card mb-2 bg-light">
					<div class="card-header" id="headingOtherid">
						<h3 class="h5 my-0">
							<button type="button" role="button" aria-label="other id pane" class="headerLnk text-left w-100" data-toggle="collapse" data-target="##otheridPane" aria-expanded="false" aria-controls="otheridPane">
								Data Entry Instructions per Column
							</button>
						</h3>
					</div>
					<div id="otheridPane" class="collapse" aria-labelledby="headingOtherid" data-parent="##accordionOtherid">
						<div class="card-body" id="otheridCardBody">
							<p class="px-3 pt-2"> Columns in <span class="text-danger">red</span> are required; others are optional.</p>
							<ul class="mb-4 h5 font-weight-normal list-group mx-3">
								<cfloop list="#fieldlist#" index="field" delimiters=",">
									<cfquery name = "getComments"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#"  result="getComments_result">
										SELECT comments
										FROM sys.all_col_comments
										WHERE 
											owner = 'MCZBASE'
											and table_name = 'CF_TEMP_OIDS'
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
				<form name="atts" method="post" enctype="multipart/form-data" action="/tools/BulkloadOtherId.cfm">
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
			<cfset NO_COLUMN_ERR = "One or more required fields are missing in the header line of the csv file. Check charset selected if columns match required headers and the first column is not found.">
			<cfset DUP_COLUMN_ERR = "One or more columns are duplicated in the header line of the csv file.">
			<cfset COLUMN_ERR = "Error inserting data ">
			<cfset NO_HEADER_ERR = "No header line found, csv file appears to be empty.">
			<cfset table_name = "CF_TEMP_OIDS">

			<cftry>
				<!--- cleanup any incomplete work by the same user --->
				<cfquery name="clearTempTable" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="clearTempTable_result">
					DELETE FROM cf_temp_oids 
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
					<h3 class="h4">There are #ListLen(fieldList)# columns expected in the header (of these #ListLen(requiredFieldList)# are required).</h3>
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
							insert into cf_temp_oids
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
					<cfset extendedResult = reportExtended(foundHighCount=foundHighCount,foundHighAscii=foundHighAscii,foundMultiByte=foundMultiByte,linkTarget='/tools/BulkloadOtherId.cfm')>	
				</cfif>
				<h4>
					<cfif loadedRows EQ 0>
						Loaded no rows from the CSV file.  The file appears to be just a header with no data. Fix file and <a href="/tools/BulkloadOtherId.cfm">reload</a>
					<cfelse>
						<cfif variables.size eq 1>Size = 1<cfelse>
						Successfully read #loadedRows# records from the CSV file. Next <a href="/tools/BulkloadOtherId.cfm?action=validate">click to validate</a>.</cfif>
					</cfif>
				</h4>
			<cfcatch>
				<h4>
					<strong class="text-danger">Failed to read the CSV file.</strong> Fix the errors in the file and <a href="/tools/BulkloadOtherId.cfm">reload</a>
				</h4>
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
						<cfset extendedResult = reportExtended(foundHighCount=foundHighCount,foundHighAscii=foundHighAscii,foundMultiByte=foundMultiByte,linkTarget='/tools/BulkloadOtherId.cfm',inHeader='yes')>	
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
			<cfquery name="getTempTableTypes" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT 
					existing_other_id_type, existing_other_id_type,new_other_id_number, key
				FROM 
					cf_temp_oids
				WHERE 
					username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<!--- loop through rows, lookup collection_object_id  --->
			<cfloop query="getTempTableTypes">
				<cfif getTempTableTypes.existing_other_id_type eq 'catalog number'>
					<!--- either based on catalog_number --->
					<cfquery name="getCID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						UPDATE
							cf_temp_oids
						SET
							collection_object_id = (
								select collection_object_id 
								from cataloged_item 
								where cat_num = cf_temp_oids.existing_other_id_number 
								and collection_cde = cf_temp_oids.collection_cde
							),
							status = null
						WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
							and key = <cfqueryparam cfsqltype="CF_SQL_decimal" value="#getTempTableTypes.key#"> 
					</cfquery>
				<cfelse>
					<!--- or on specified other identifier --->
					<cfquery name="getCID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						UPDATE
							cf_temp_oids
						SET
							collection_object_id= (
								select cataloged_item.collection_object_id from cataloged_item,coll_obj_other_id_num 
								where coll_obj_other_id_num.other_id_type = cf_temp_oids.existing_other_id_type 
								and cataloged_item.collection_cde = cf_temp_oids.collection_cde 
								and display_value= cf_temp_oids.existing_other_id_number
								and cataloged_item.collection_object_id = coll_obj_other_id_num.COLLECTION_OBJECT_ID
							),
							status = null
						WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
							and key = <cfqueryparam cfsqltype="CF_SQL_decimal" value="#getTempTableTypes.key#"> 
					</cfquery>
				</cfif>
			</cfloop>
			<cfquery name="flagMczAcronym" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE cf_temp_oids
				SET 
					status = concat(nvl2(status, status || '; ', ''),'INSTIUTION_ACRONYM is not "MCZ" (check case)')
				WHERE institution_acronym <> 'MCZ'
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="flagMczAcronym" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE cf_temp_oids
				SET 
					status = concat(nvl2(status, status || '; ', ''),'COLLECTION_CDE does not match Cryo, Ent, Herp, Ich, IP, IZ, Mala, Mamm, Orn, SC, or VP (check case)')
				WHERE collection_cde not in (select collection_cde from ctcollection_cde)
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="flagNoCollectionObject" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE cf_temp_oids
				SET 
					status = concat(nvl2(status, status || '; ', ''),' There is no match to a cataloged item on "' || existing_other_id_type || '" = "' || existing_other_id_number || '" in collection "' || collection_cde ||'"')
				WHERE collection_object_id IS NULL
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="flagNotMatchedExistOther_ID_Type1" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE cf_temp_oids
				SET 
					status = concat(nvl2(status, status || '; ', ''), 'Unknown existing_other_id_type: "' || existing_other_id_type ||'" not in controlled vocabulary.')
				WHERE existing_other_id_type is not null 
					AND existing_other_id_type <> 'catalog number'
					AND existing_other_id_type not in (select other_id_type from ctcoll_other_id_type)
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="flagNotMatchedExistOther_ID_Type2" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE cf_temp_oids
				SET 
					status = concat(nvl2(status, status || '; ', ''), 'Unknown new_other_id_type: "' || new_other_id_type ||'" not in controlled vocabulary.')
				WHERE new_other_id_type is not null 
					AND new_other_id_type <> 'catalog number'
					AND new_other_id_type not in (select other_id_type from ctcoll_other_id_type)
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<!--- Missing data in required fields, if columns are present, but required fields are empty. --->
			<cfloop list="#requiredfieldlist#" index="requiredField">
				<cfquery name="checkRequired" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE cf_temp_oids
					SET 
						status = concat(nvl2(status, status || '; ', ''),'#requiredField# is missing')
					WHERE #requiredField# is null
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
			</cfloop>

			<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT collection_object_id,collection_cde,institution_acronym,existing_other_id_type,existing_other_id_number,new_other_id_type,new_other_id_number,status
				FROM cf_temp_oids
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				ORDER BY key
			</cfquery>
			<cfquery name="pf" dbtype="query">
				SELECT count(*) c 
				FROM data 
				WHERE status is not null
			</cfquery>
			<h3 class="mt-3">
				<cfif pf.c gt 0>
					There is a problem with #pf.c# of #data.recordcount# row(s). See the STATUS column. (<a href="/tools/BulkloadOtherId.cfm?action=dumpProblems">download</a>). Fix the problem(s) noted in the status column and <a href="/tools/BulkloadOtherId.cfm" class="text-danger">start again</a>.
				<cfelse>
					<span class="text-success">Validation checks passed</span>. Look over the table below and <a href="/tools/BulkloadOtherId.cfm?action=load" class="btn-link font-weight-lessbold">click to continue</a> if it all looks good. Or, <a href="/tools/BulkloadOtherId.cfm" class="text-danger">start again</a>.
				</cfif>
			</h3>
			<table class='px-0 sortable table small table-responsive table-striped w-100'>
				<thead>
					<tr>
						<th>BULKLOADING STATUS</th>
						<th>INSTITUTION_ACRONYM</th>
						<th>COLLECTION_CDE</th>
						<th>EXISTING_OTHER_ID_TYPE</th>
						<th>EXISTING_OTHER_ID_NUMBER</th>
						<th>NEW_OTHER_ID_TYPE</th>
						<th>NEW_OTHER_ID_NUMBER</th>
					</tr>
				<tbody>
					<cfloop query="data">
						<tr>
							<td><cfif len(data.status) eq 0>Cleared to load<cfelse><strong>#data.status#</strong></cfif></td>
							<td>#data.institution_acronym#</td>
							<td>#data.collection_cde#</td>
							<td>#data.existing_other_id_type#</td>
							<td>#data.existing_other_id_number#</td>
							<td>#data.new_other_id_type#</td>
							<td>#data.new_other_id_number#</td>
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
				<cfquery name="getTempData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT * FROM cf_temp_oids
					WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cfquery name="getCounts" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT count(distinct collection_object_id) ctobj FROM cf_temp_oids
					WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cftry>
					<cfset testParse = 0>
					<cfif getTempData.recordcount EQ 0>
						<cfthrow message="You have no rows to load in the Other ID bulkloader table (cf_temp_oids).  <a href='/tools/BulkloadOtherId.cfm'>Start over</a>">
					</cfif>
					<cfset i = 0>
					<cfloop query="getTempData">
						<cfset problem_key = getTempData.key>
						<cfstoredproc procedure="parse_other_id" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							<cfprocparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
							<cfprocparam cfsqltype="cf_sql_varchar" value="#new_other_id_number#">
							<cfprocparam cfsqltype="cf_sql_varchar" value="#new_other_id_type#">
						</cfstoredproc>
						<cfquery name="updateParse" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="updateParse_result">
							select distinct display_value
								from coll_obj_other_id_num 
								where collection_object_id =<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.collection_object_id#">
								group by display_value
								having count(*) > 1
						</cfquery>
						<cfset testParse = testParse + 1>
						<cfif updateParse_result.recordcount gt 0>
							<cfthrow message = "Error: insert would create a duplicate other id type : other id value pair.">
						<cfelse>
						</cfif>
						<cfset i = i+1>
					</cfloop>
					<cfif getTempData.recordcount eq testParse>
						<p>Number of Other IDs updated: #i# (on #getCounts.ctobj# cataloged items)</p>
						<h2 class="text-success">Success - loaded</h2>
						<p>
							<a href="/Specimens.cfm?execute=true&builderMaxRows=1&action=builderSearch&openParens1=0&field1=COLL_OBJECT%3ACOLL_OBJ_COLLECTION_OBJECT_ID&searchText1=#encodeForUrl(valuelist(getTempData.collection_object_id))#&closeParens1=0" class="btn-link font-weight-lessbold">
								See in Specimen Search Results.
							</a>
						</p>
					<cfelse>
						<cfthrow message="Number of other IDs added does not match the number of rows in the input file.">
					</cfif>
					<cftransaction action="COMMIT">
				<cfcatch>
					<cftransaction action="ROLLBACK">
					<h2 class="text-danger mt-4">There was a problem updating the Other IDs.</h2>
					<cfquery name="getProblemData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getProblemData_result">
						SELECT institution_acronym, collection_cde,existing_other_id_type, existing_other_id_number, new_other_id_type,new_other_id_number,collection_object_id
						FROM cf_temp_oids
						WHERE key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#problem_key#">
					</cfquery>
						
					<h3 class="h4">Errors encountered during application are displayed one row at a time.</h3>
					<h3 class="mt-3 mb-2">
						Error loading row (<span class="text-danger">#getProblemData_result.recordcount#</span>) from the CSV: 
						<cfif len(cfcatch.detail) gt 0>
							<span class="border-bottom border-danger">
								<cfif cfcatch.detail contains "NEW_OTHER_ID_TYPE">
									Invalid MEW_OTHER_ID_TYPE; check controlled vocabulary (Help menu)
								<cfelseif cfcatch.detail contains "COLLECTION_CDE">
									COLLECTION_CDE does not match abbreviated collection (e.g., Ent, Herp, Ich, IP, IZ, Mala, Mamm, Orn, SC, or VP)
								<cfelseif cfcatch.detail contains "INSTITUTION_ACRONYM">
									INSTITUTION_ACRONYM does not match MCZ (all caps)
								<cfelseif cfcatch.detail contains "NEW_OTHER_ID_NUMBER">
									Problem with NEW_OTHER_ID_NUMBER, check to see the correct new_other_id_number was entered
								<cfelseif cfcatch.detail contains "unique constraint">
									Problem with NEW_OTHER_ID_NUMBER (see below); NEW_OTHER_ID_NUMBER already entered; Remove and <a href="/tools/BulkloadOtherId.cfm">try again</a>
								<cfelseif cfcatch.detail contains "COLLECTION_OBJECT_ID">
									Problem with EXISTING_OTHER_ID_TYPE or EXISTING_OTHER_ID_NUMBER (couldn not find collection_object_id) 
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
					<table class='sortable table table-responsive table-striped d-lg-table'>
						<thead>
							<tr>
								<th>institution_acronym</th>
								<th>collection_cde</th>
								<th>existing_other_id_type</th>
								<th>existing_other_id_number</th>
								<th>new_other_id_type</th>
								<th>new_other_id_number</th>
								<th>collection_object_id</th>
							</tr>
						</thead>
						<tbody>
							<cfloop query="getProblemData">
								<tr>
									<td>#getProblemData.institution_acronym#</td>
									<td>#getProblemData.collection_cde#</td>
									<td>#getProblemData.existing_other_id_type#</td>
									<td>#getProblemData.existing_other_id_number#</td>
									<td>#getProblemData.new_other_id_type#</td>
									<td>#getProblemData.new_other_id_number#</td>
									<td>#getProblemData.collection_object_id#</td>
								</tr>
							</cfloop>
						</tbody>
					</table>
					<cfrethrow>
				</cfcatch>
				</cftry>
			</cftransaction>
			<cfquery name="clearTempTable" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="clearTempTable_result">
				DELETE FROM cf_temp_oids 
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
		</cfoutput>
	</cfif>
</main>

<cfinclude template="/shared/_footer.cfm">
