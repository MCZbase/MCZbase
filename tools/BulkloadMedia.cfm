<!--- tools/bulkloadMedia.cfm add media in bulk.

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
		SELECT MEDIA_URI,MIME_TYPE,MEDIA_TYPE,PREVIEW_URI,CREATED_BY_AGENT_ID,SUBJECT,MADE_DATE,HEIGHT,WIDTH,DESCRIPTION,MEDIA_RELATIONSHIP_1,RELATED_PRIMARY_KEY_1,MEDIA_RELATIONSHIP_2,RELATED_PRIMARY_KEY_2,MEDIA_LICENSE_ID,MASK_MEDIA,MEDIA_LABEL_1,LABEL_VALUE_1,MEDIA_LABEL_2,LABEL_VALUE_2,MEDIA_LABEL_3,LABEL_VALUE_3,MEDIA_LABEL_4,LABEL_VALUE_4,MEDIA_LABEL_5,LABEL_VALUE_5,MEDIA_LABEL_6,LABEL_VALUE_6,MEDIA_LABEL_7,LABEL_VALUE_7,MEDIA_LABEL_8,LABEL_VALUE_8
		FROM cf_temp_media 
		WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
		ORDER BY key
	</cfquery>
	<cfinclude template="/shared/component/functions.cfc">
	<cfset csv = queryToCSV(getProblemData)>
	<cfheader name="Content-Type" value="text/csv">
	<cfoutput>#csv#</cfoutput>
	<cfabort>
</cfif>
<!--- end special case dump of problems --->
<cfset fieldlist = "MEDIA_URI,MIME_TYPE,MEDIA_TYPE,PREVIEW_URI,CREATED_BY_AGENT_ID,SUBJECT,MADE_DATE,HEIGHT,WIDTH,DESCRIPTION,MEDIA_RELATIONSHIP_1,RELATED_PRIMARY_KEY_1,MEDIA_RELATIONSHIP_2,RELATED_PRIMARY_KEY_2,MEDIA_LICENSE_ID,MASK_MEDIA,MEDIA_LABEL_1,LABEL_VALUE_1,MEDIA_LABEL_2,LABEL_VALUE_2,MEDIA_LABEL_3,LABEL_VALUE_3,MEDIA_LABEL_4,LABEL_VALUE_4,MEDIA_LABEL_5,LABEL_VALUE_5,MEDIA_LABEL_6,LABEL_VALUE_6,MEDIA_LABEL_7,LABEL_VALUE_7,MEDIA_LABEL_8,LABEL_VALUE_8">
<cfset fieldTypes ="CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_DATE,CF_SQL_DECIMAL,CF_SQL_DECIMAL,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_DECIMAL,CF_SQL_DECIMAL,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR">
<cfset requiredfieldlist = "MEDIA_URI,MIME_TYPE,MEDIA_TYPE,CREATED_BY_AGENT_ID,SUBJECT,MADE_DATE,DESCRIPTION">
		
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
<cfset pageTitle = "BulkloadMedia">
<cfinclude template="/shared/_header.cfm">
<cfinclude template="/tools/component/csv.cfc" runOnce="true"><!--- for common csv testing functions --->
<cfif not isDefined("action") OR len(action) EQ 0>
	<cfset action="nothing">
</cfif>
	
	
<main class="container-fluid px-5 py-3" id="content">
	<h1 class="h2 mt-2">Bulkload Media </h1>

<!------------------------------------------------------->
	
	<cfif #action# is "nothing">
		<cfoutput>
			<p class="font-weight-bold h4">Jump to <a href="##loader" class="btn-link font-weight-bold text-muted">Loader</a></p>
			<p>This tool adds media records. The media can be related to records that have to be in MCZbase prior to uploading this csv. Duplicate columns will be ignored. Some of the values must appear as they do on the following <a href="https://mczbase.mcz.harvard.edu/vocabularies/ControlledVocabulary.cfm?" class="font-weight-bold">controlled vocabularies</a> lists:
				<ul class="list-group list-group-horizontal-md">
					<li class="list-group-item font-weight-lessbold"><a href="/vocabularies/ControlledVocabulary.cfm?table=CTMEDIA_LABEL">MEDIA_LABEL (17 values)</a> </li> <span class="mt-1 d-none d-md-inline-block"> | </span>
					<li class="list-group-item font-weight-lessbold"><a href="/vocabularies/ControlledVocabulary.cfm?table=CTMEDIA_RELATIONSHIP">MEDIA_RELATIONSHIP (23 values)</a></li> <span class="mt-1 d-none d-md-inline-block"> | </span>
					<li class="list-group-item font-weight-lessbold"><a href="/vocabularies/ControlledVocabulary.cfm?table=CTMEDIA_TYPE">MEDIA_TYPE (6 values)</a> </li><span class="mt-1 d-none d-md-inline-block"> | </span>
					<li class="list-group-item font-weight-lessbold"><a href="/vocabularies/ControlledVocabulary.cfm?table=CTMIME_TYPE">MIME_TYPE (14 values)</a> </li><span class="mt-1 d-none d-md-inline-block"> | </span>
					<li class="list-group-item font-weight-lessbold"><a href="/vocabularies/ControlledVocabulary.cfm?table=CTMEDIA_LICENSE">MEDIA_LICENSE (7 values)</a></li>
				</ul>
			</p>
			<div class="mb-4 pl-2">
				<dl>
					<dt class="float-left px-2">Step 1:</dt><dd>Ensure that Media exists on the shared drive or external URL</dd>
					<dt class="float-left px-2">Step 2:</dt><dd>Check the existance of records for the relationships (e.g., cataloged_item, agent, collecting_event).</dd>
					<dt class="float-left px-2">Step 3:</dt><dd>Upload a comma-delimited text file (csv). </dd>
					<dt class="float-left px-2">Step 4:</dt><dd>Validation. Check the table of data. </dd>
					<dt class="float-left px-2">Step 5:</dt><dd>Load the data. </dd>
				</dl>
			</div>
		
			<h2 class="h4 mb-2">Media Relationship Entries</h2>
			<p class="mb-0">Some relationships require an ID specific to that the type of relationship and others can take a name. Look at the table below and see if you have the correct entries for the relationships.</p>
			<table class="table table-responsive small table-striped mx-2">
			 	<thead class="thead-light">
					<tr>
						<th>Agents</th><br>
						<th>Location/Event</th>
						<th>Object/Collection</th>
						<th>Media Related</th>
						<th>Publication or Project</th>
						<th>External Transactions</th>
						<th>Internal Transactions</th>
					</tr>
				</thead>
				<tbody>
					<tr>	
						<td>created by AGENT: <b>AGENT_ID</b> or <b>PREFERRED AGENT_NAME</b></td>
						<td>documents or shows COLLECTING_EVENT: <b>COLLECTING_EVENT_ID</b></td>
						<td>documents or shows or ledger entry for CATALOGED_ITEM: <b>GUID</b></td>
						<td>related to MEDIA: <b>MEDIA_ID</b></td>
						<td>shows PROJECT: <b>PROJECT_ID</b> or <b>PROJECT_NAME</b></td>
						<td>documents ACCN: <b>ACCN_NUMBER</b></td>
						<td>documents DEACCESSION: <b>DEACC_NUMBER</b></td>
					</tr>
					<tr>
						
						<td>physical object created by AGENT: <b>AGENT_ID</b> or <b>PREFERRED AGENT_NAME</b></td>
						<td>documents or shows LOCALITY: <b>LOCALITY_ID</b></td>
						<td>shows SPECIMEN_PART: <b>GUID</b></td>
						<td>transcript for AUDIO: <b>MEDIA_ID</b></td>
						<td>shows PUBLICATION: <b>PUBLICATION_ID</b></td>
						<td>documents LOAN: <b>LOAN_NUMBER</b></td>
						<td>documents BORROW: <b>BORROW_NUMBER</b></td>					
					</tr>
					<tr>
					
						<td>documents or shows or shows handwriting of AGENT: <b>AGENT_ID</b> or <b>PREFERRED AGENT_NAME</b></td>
						<td></td>
						<td>shows UNDERSCORE_COLLECTION: <b>UNDERSCORE_COLLECTION_ID</b> or <b>COLLECTION_NAME</b></td>
						<td><b></b></td>
						<td><b></b></td>
						<td>document for or shows PERMIT: <b>PERMIT_ID</b></td>
						<td><b></b></td>
					</tr>		
				</tbody>
			</table>
			
				<h2 class="h4 mt-4">Media License</h2>
				<p>The media license id should be entered using the numeric codes below. If omitted this will default to the &quot;1 - MCZ Permissions &amp; Copyright&quot; license.</p>
				<h3 class="small90 pl-3">Media License Codes:</h3>
				<dl class="pl-3">
					<dt class="btn-secondary"><span class="badge badge-light">1 </span> MCZ Permissions &amp; Copyright</dt> <dd>All MCZ images and publications should have this designation</dd>
					<dt class="btn-secondary"><span class="badge badge-light">4 </span> Rights defined by 3rd party host</dt> <dd>This material is hosted by an external party. Please refer to the licensing statement provided by the linked host.</dd>
					<dt class="btn-secondary"><span class="badge badge-light">5 </span> Creative Commons Zero (CC0)</dt><dd>CC0 enables scientists, educators, artists and other creators and owners of copyright- or database-protected content to waive those interests in their works and thereby place them as completely as possible in the public domain.</dd>
					<dt class="btn-secondary"><span class="badge badge-light">6 </span> Creative Commons Attribution (CC BY)</dt><dd>This license lets others distribute, remix, tweak, and build upon your work, even commercially, as long as they credit you for the original creation.</dd>
					<dt class="btn-secondary"><span class="badge badge-light">7</span> Creative Commons Attribution-ShareAlike (CC BY-SA)</dt> <dd>This license lets others remix, tweak, and build upon your work even for commercial purposes, as long as they credit you and license their new creations under the identical terms.</dd>
					<dt class="btn-secondary"><span class="badge badge-light">8 </span> Creative Commons Attribution-NonCommercial (CC BY-NC)</dt><dd>This license lets others remix, tweak, and build upon your work non-commercially, and although their new works must also acknowledge you and be non-commercial, they don&apos;t have to license their derivative works on the same terms.</dd>
					<dt class="btn-secondary"><span class="badge badge-light">9 </span> Creative Commons Attribution-NonCommercial-ShareAlike (CC BY-NC-SA)</dt><dd>This license lets others remix, tweak, and build upon your work non-commercially, as long as they credit you and license their new creations under the identical terms.</dd>
				</dl>
				<h2 class="h4 mt-4">Mask Media</h2>
				<p>Follow all the instructions above and read any error messages that pop up in the status column during validation or at the top of the final loading step. Reminder: To mark media as hidden from Public Users put a 1 in the MASK_MEDIA column. Enter zero or Leave blank for Public media.</p>
			
				<h2 class="h3 mt-4">Upload a comma-delimited text file (csv)</h2>
				<p>Include column headings, spelled exactly as below. Use "catalog number" as the value of other_id_type to match on catalog number. Click view template and download to create a csv with the column headers in place.</p>
				<span class="btn btn-xs btn-info" onclick="document.getElementById('template').style.display='block';">View template</span>
				<div id="template" style="margin: 1rem 0;display:none;">
					<label for="templatearea" class="data-entry-label mb-1">
						Copy this header line and save it as a .csv file (<a href="/tools/#pageTitle#.cfm?action=getCSVHeader" class="font-weight-lessbold">download</a>)
					</label>
					<textarea rows="2" cols="90" id="templatearea" class="w-100 data-entry-textarea">#fieldlist#</textarea>
				</div>
			</div>
			<a name="loader" class="text-white">top</a>
			<h2 class="mt-2 h4">Columns in <span class="text-danger">red</span> are required; others are optional:</h2>
			<ul class="mb-4 h5 font-weight-normal list-group mx-3">
				<cfloop list="#fieldlist#" index="field" delimiters=",">
					<cfquery name = "getComments"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#"  result="getComments_result">
						SELECT comments
						FROM sys.all_col_comments
						WHERE 
							owner = 'MCZBASE'
							and table_name = 'CF_TEMP_MEDIA'
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
			<form name="getFiles" method="post" enctype="multipart/form-data" action="/tools/#pageTitle#.cfm">
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
			<cfset table_name = "CF_TEMP_MEDIA">
			<cftry>
				<!--- cleanup any incomplete work by the same user --->
				<cfquery name="killOld" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					DELETE FROM cf_temp_media
					WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cfquery name="killOld" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					DELETE FROM cf_temp_media_relations
					WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cfquery name="killOld" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					DELETE FROM cf_temp_media_labels 
					WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>

				<cfset variables.foundHeaders =""><!--- populated by loadCsvFile --->
				<cfset variables.size=""><!--- populated by loadCsvFile --->
				<cfset iterator = loadCsvFile(FileToUpload=FileToUpload,format=format,characterSet=characterSet)>

				<!--- Note: As we can't use csvFormat.withHeader(), we can not match columns by name, we are forced to do so by number, thus arrays --->
				<cfset colNameArray = listToArray(ucase(variables.foundHeaders))><!---the list of columns/fields found in the input file--->
				<cfset fieldArray = listToArray(ucase(fieldlist))><!--- the full list of fields --->
				<cfset typeArray = listToArray(fieldTypes)><!--- the types for the full list of fields --->
					
				<div class="col-12 my-4">
					<h3 class="h4">Found #size# columns in header of csv file.</h3>
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
								insert into cf_temp_media
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
							you probably want to <strong><a href="/tools/BulkloadMedia.cfm">reload</a></strong> this file selecting a different encoding.  If these appear as expected, then 
								you selected the correct encoding and can continue to validate or load.</p>
						</div>
						<ul class="pb-1 h4 list-unstyled">
							#foundHighAscii# #foundMultiByte#
						</ul>
					</cfif>
				</div>
				<h3 class="h3">
					<cfif loadedRows EQ 0>
						Loaded no rows from the CSV file.  The file appears to be just a header with no data. Fix file and <a href="/tools/BulkloadMedia.cfm">reload</a>.
					<cfelse>
						Successfully read #loadedRows# records from the CSV file.  Next <a href="/tools/BulkloadMedia.cfm?action=validate">click to validate</a>.
					</cfif>
				</h3>
			<cfcatch>
				<h3 class="h4">
					Failed to read the CSV file.  Fix the errors in the file and <a href="/tools/BulkloadMedia.cfm">reload</a>.
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
		<h2 class="h4 mb-3">Second step: Data Validation</h2>
		<cfoutput>
			<cfquery name="getTempMedia" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT MEDIA_URI,MIME_TYPE,MEDIA_TYPE,PREVIEW_URI,CREATED_BY_AGENT_ID,SUBJECT,MADE_DATE,HEIGHT,WIDTH,DESCRIPTION,MEDIA_RELATIONSHIP_1,RELATED_PRIMARY_KEY_1,MEDIA_RELATIONSHIP_2,RELATED_PRIMARY_KEY_2,MEDIA_LICENSE_ID,MASK_MEDIA,MEDIA_LABEL_1,LABEL_VALUE_1,MEDIA_LABEL_2,LABEL_VALUE_2,MEDIA_LABEL_3,LABEL_VALUE_3,MEDIA_LABEL_4,LABEL_VALUE_4,MEDIA_LABEL_5,LABEL_VALUE_5,MEDIA_LABEL_6,LABEL_VALUE_6,MEDIA_LABEL_7,LABEL_VALUE_7,MEDIA_LABEL_8,LABEL_VALUE_8,KEY,USERNAME
				FROM 
					cf_temp_media
				WHERE 
					username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
		
				<cfset key = ''>
				<cfquery name="warningMessageMediaType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE
						cf_temp_media
					SET
						status = concat(nvl2(status, status || '; ', ''),'MEDIA_TYPE invalid - see <a href="/vocabularies/ControlledVocabulary.cfm?table=CTMEDIA_TYPE">controlled vocabulary</a>')
					WHERE 
						media_type not in (select media_type from ctmedia_type) AND
						username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>

				<cfquery name="warningMessageMimeType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE
						cf_temp_media
					SET
						status = concat(nvl2(status, status || '; ', ''),'MIME_TYPE invalid - see <a href="/vocabularies/ControlledVocabulary.cfm?table=CTMEDIA_TYPE">controlled vocabulary</a>')
					WHERE 
						mime_type not in (select mime_type from CTMIME_TYPE) AND
						username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cfquery name="warningMessageLicense" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE
						cf_temp_media
					SET
						status = concat(nvl2(status, status || '; ', ''),'MEDIA_LICENSE_ID #getTempMedia.MEDIA_LICENSE_ID# is invalid')
					WHERE
						media_license_id not in (select media_license_id from ctmedia_license) AND
						username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
	
				<!----------------------------------->
				<!---TODO: Fix CHECK for MADE_DATE--->
				<!----------------------------------->
				<cfset madedate = isDate(getTempMedia.made_date)>
					<cfif #madedate# eq 'NO'>
						<cfquery name="flagDateProblem" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							UPDATE
								cf_temp_media
							SET 
								status = concat(nvl2(status, status || '; ', ''),'invalid made_date')
							WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#"> 
								and key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempMedia.key#"> 
						</cfquery>	
					</cfif>
				<cfif len(getTempMedia.mask_media) GT 0>
					<cfif getTempMedia.mask_media NEQ 1>
						<cfquery name="warningMessageMask" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							UPDATE
								cf_temp_media
							SET
								cf_temp_media.status = concat(nvl2(status, status || '; ', ''),'MASK_MEDIA must = blank, 1 or 0')
							WHERE 
								username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#"> 
						</cfquery>
					</cfif>
				</cfif>
			<cfloop list="#requiredfieldlist#" index="requiredField">
				<cfquery name="checkRequired" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE cf_temp_media
					SET 
						status = concat(nvl2(status, status || '; ', ''),'#requiredField# is missing')
					WHERE #requiredField# is null
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
			</cfloop>
			
			<!-- labels------------------------------------ -->		
			<!-- labels------------------------------------ -->	
			<!-- Define label variables----------------------->
			<cfif len(getTempMedia.media_label_1) gt 0><cfset media_label_1 = "#getTempMedia.media_label_1#"><cfelse><cfset media_label_1 = ""></cfif>
			<cfif len(getTempMedia.media_label_2) gt 0><cfset media_label_2 = "#getTempMedia.media_label_2#"><cfelse><cfset media_label_2 = ""></cfif>
			<cfif len(getTempMedia.media_label_3) gt 0><cfset media_label_3 = "#getTempMedia.media_label_3#"><cfelse><cfset media_label_3 = ""></cfif>
			<cfif len(getTempMedia.media_label_4) gt 0><cfset media_label_4 = "#getTempMedia.media_label_4#"><cfelse><cfset media_label_4 = ""></cfif>
			<cfif len(getTempMedia.media_label_5) gt 0><cfset media_label_5 = "#getTempMedia.media_label_5#"><cfelse><cfset media_label_5 = ""></cfif>
			<cfif len(getTempMedia.media_label_6) gt 0><cfset media_label_6 = "#getTempMedia.media_label_6#"><cfelse><cfset media_label_6 = ""></cfif>
			<cfif len(getTempMedia.media_label_7) gt 0><cfset media_label_7 = "#getTempMedia.media_label_7#"><cfelse><cfset media_label_7 = ""></cfif>
			<cfif len(getTempMedia.media_label_8) gt 0><cfset media_label_8 = "#getTempMedia.media_label_8#"><cfelse><cfset media_label_8 = ""></cfif>
				
			<!-- Define the total number of variables -->
			<cfset numberOfVariables = 8>
			<cfloop from="1" to="#numberOfVariables#" index="i">
				<cfset variableName = "media_label_" & i>
				<cfset variableValue = evaluate(variableName)>
				<!-- Output the variable name and value -->
				<cfquery name="checkLabelType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE cf_temp_media
					SET 
						status = concat(nvl2(status, status || '; ', ''),'#variableName# is missing')
					WHERE #variableName# not in (select media_label from ctmedia_label)
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
			</cfloop>	
			<!-- END labels-------------------------------------------- -->	
			<!-- END CHECK FOR MISSING LABELS-------------------------- -->	
			<!-- ------------------------------------------------------ -->	
					
					
			<cfif len(getTempMedia.made_date) eq 0 && refind("^[0-9]{4}-[0-9]{2}-[0-9]{2}$",made_date) EQ 0>
				<cfquery name="setDate" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE
						cf_temp_media
					SET
						status = concat(nvl2(status, status || '; ', ''),'#made_date# is not in correct format')
					WHERE 
						made_date is not null AND
						username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#"> 
				</cfquery>
			</cfif>
			<cfloop query="getTempMedia">
				<!---Update created_by_agent_id entry to agent_id if provided with AGENT_NAME--->
				<cfif !isNumeric(created_by_agent_id) and len(created_by_agent_id) gt 0>
					<cfquery name="setAgentID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						UPDATE
							cf_temp_media
						SET
							created_by_agent_id = (select agent.agent_id from agent,agent_name where agent.agent_id = agent_name.agent_id 
							and agent_name.agent_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempMedia.created_by_agent_id#">)
						WHERE
							created_by_agent_id is not null and
							username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#"> and
							key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempMedia.key#">
					</cfquery>
				</cfif>
				<!---Check MEDIA_URI------------->
				<cfset urlToCheck = "#getTempMedia.media_uri#">
				<cfset validstyle = ''>
				<cfhttp url="#urlToCheck#" method="GET" timeout="10" throwonerror="false">
				<cfif cfhttp.statusCode EQ '200 OK'>	
					<cfset validstyle = '<span class="text-success">(Valid Link)</span>'>
				<cfelse>
					<cfquery name="warningBadURI1" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						UPDATE
							cf_temp_media
						SET
							status = concat(nvl2(status, status || '; ', ''),'MEDIA_URI is invalid')
						WHERE
							media_uri is not null and
							username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#"> and
							key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempMedia.key#">
					</cfquery>
				</cfif>
						
						
				<!----------Check Relationship Warnings for 1 and 2------------->
				<!----------Relationship Invalid-------------------------------->
				<!----------Related primary kay missing ------------------------>
				<cfif len(media_relationship_1) gt 0>
					<cfquery name="warningBadRel1" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						UPDATE
							cf_temp_media
						SET
							status = concat(nvl2(status, status || '; ', ''),'MEDIA_RELATIONSHIP_1 is invalid - Check  <a href="/vocabularies/ControlledVocabulary.cfm?table=CTMEDIA_RELATIONSHIP">controlled vocabulary</a>')
						WHERE
							media_relationship_1 not in (select media_relationship from ctmedia_relationship) and 
							media_relationship_1 is not null AND
							username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#"> and
							key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempMedia.key#">
					</cfquery>
				</cfif>
				<cfif len(media_relationship_1) gt 0 and len(related_primary_key_1) eq 0>
					<cfquery name="warningBadRel1" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						UPDATE
							cf_temp_media
						SET
							status = concat(nvl2(status, status || '; ', ''),'RELATED_PRIMARY_KEY_1 is missing')
						WHERE
							related_primary_key_1 is null and media_relationship_1 is not null AND
							username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#"> AND
							key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempMedia.key#">
					</cfquery>
				</cfif>
				<cfif len(media_relationship_2) gt 0>
					<cfquery name="warningBadRel2" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						UPDATE
							cf_temp_media
						SET
							status = concat(nvl2(status, status || '; ', ''),'MEDIA_RELATIONSHIP_2 is invalid - Check  <a href="/vocabularies/ControlledVocabulary.cfm?table=CTMEDIA_RELATIONSHIP">controlled vocabulary</a>')
						WHERE
							media_relationship_2 not in (select media_relationship from ctmedia_relationship) and 
							media_relationship_2 is not null AND
							username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#"> and
							key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempMedia.key#">
					</cfquery>
				</cfif>
				<cfif len(media_relationship_2) gt 0 and len(related_primary_key_2) eq 0>
					<cfquery name="warningBadRel2" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						UPDATE
							cf_temp_media
						SET
							status = concat(nvl2(status, status || '; ', ''),'RELATED_PRIMARY_KEY_2 is missing')
						WHERE
							related_primary_key_2 is null and media_relationship_2 is not null AND
							username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#"> AND
							key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempMedia.key#">
					</cfquery>
				</cfif>
				<!----------END Check Relationship Warnings for 1 and 2------------->
				<!----------END Relationship Invalid-------------------------------->
				<!----------END Related primary kay missing ------------------------>
				<!------------------------------------------------------------------>	
				
	
						
				<!--------------------------------------------------------->
				<!--- Check Height and Width and add if not entered-------->
				<!--- MD5HASH---------------------------------------------->
				<!--------------------------------------------------------->
				<cfif isimagefile(getTempMedia.media_uri)>
					<cfimage action="info" source="#getTempMedia.media_uri#" structname="imgInfo"/>
					<cfquery name="makeHeightLabel" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						UPDATE cf_temp_media
						SET  height = <cfif len(getTempMedia.height) gt 0>#getTempMedia.height#<cfelse>#imgInfo.height#</cfif>
						where username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#"> 
						AND
							key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempMedia.key#">
					</cfquery>
					<cfquery name="makeWidthLabel" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						UPDATE cf_temp_media
						SET  width = <cfif len(getTempMedia.height) gt 0>#getTempMedia.width#<cfelse>#imgInfo.width#</cfif>
						where username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						AND
							key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempMedia.key#">
					</cfquery>
					<cfhttp url="#getTempMedia.media_uri#" method="get" getAsBinary="yes" result="result">
					<cfset MD5HASH=Hash(result.filecontent,"MD5")>
					<cfquery name="makeMD5hash" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						UPDATE cf_temp_media
						SET MD5HASH = '#MD5HASH#'
						where username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#"> 
						AND
							key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempMedia.key#">
					</cfquery>
				</cfif>
				<!----------END height and width labels------------------->
				<!----------END MD5HASH----------------------------------->
				<!-------------------------------------------------------->
			</cfloop>
			<!-----END LOOP for getTempMedia----->
						
			<!-------------------Query the Table with updates again------------------------->			
			<cfquery name="getTempMedia2" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT MEDIA_URI,MIME_TYPE,MEDIA_TYPE,PREVIEW_URI,CREATED_BY_AGENT_ID,SUBJECT,MADE_DATE,HEIGHT,WIDTH,DESCRIPTION,MEDIA_RELATIONSHIP_1,RELATED_PRIMARY_KEY_1,MEDIA_RELATIONSHIP_2,RELATED_PRIMARY_KEY_2,MEDIA_LICENSE_ID,MASK_MEDIA,MEDIA_LABEL_1,LABEL_VALUE_1,MEDIA_LABEL_2,LABEL_VALUE_2,MEDIA_LABEL_3,LABEL_VALUE_3,MEDIA_LABEL_4,LABEL_VALUE_4,MEDIA_LABEL_5,LABEL_VALUE_5,MEDIA_LABEL_6,LABEL_VALUE_6,MEDIA_LABEL_7,LABEL_VALUE_7,MEDIA_LABEL_8,LABEL_VALUE_8,KEY,USERNAME,STATUS
				FROM 
					cf_temp_media
				WHERE 
					username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
				
			<!--------Loop through updated table if there are no status messages------->
			<cfif len(getTempMedia2.status) eq 0>
				<cfloop query = "getTempMedia2">
					<cfif isNumeric(CREATED_BY_AGENT_ID)>
						<cfquery name="warningMessageAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							UPDATE
								cf_temp_media
							SET
								status = concat(nvl2(status, status || '; ', ''),'CREATED_BY_AGENT_ID invalid')
							WHERE 
								CREATED_BY_AGENT_ID not in (select AGENT_ID from AGENT) AND
								username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#"> and
								key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempMedia2.key#">
						</cfquery>
					</cfif>
					<!---Update and check media relationships--->
					<cfset #i# lte 2>
					<cfloop index="i" from="1" to="2">
						<!--- This generalizes the two key:value pairs (to media_relationship and related_primary_key)--->
						<cfquery name="getMediaRel" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							SELECT 
								key,
								media_relationship_#i# as media_relationship,
								related_primary_key_#i# as related_primary_key
							FROM 
								cf_temp_media
							WHERE 
								media_relationship_#i# is not null
								AND related_primary_key_#i# is not null
								AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
								AND key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempMedia2.key#">
						</cfquery>

						<cfif ListLen(getMediaRel.related_primary_key) gte #i# >
							<!---Find the table name "theTable" from the second part of the media_relationship--->
							<cfset theTable = trim(listLast('#getMediaRel.media_relationship#'," "))>
							<!---based on the table, find the primary key--->
							<cfquery name="tables" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
								SELECT cols.table_name, cols.column_name, cols.position, cons.status, cons.owner
								FROM all_constraints cons, all_cons_columns cols
								WHERE cons.constraint_type = 'P'
								AND cons.constraint_name = cols.constraint_name
								AND cons.owner = cols.owner
								and cons.owner='MCZBASE'
								AND cols.table_name = UPPER('#theTable#')
								AND cols.position = 1
								ORDER BY cols.table_name, cols.position
							</cfquery>
							<cfif #getMediaRel.media_relationship# contains 'cataloged_item' and len(getMediaRel.related_primary_key) gt 0>
								<cfset l=3>
								<cfloop list="#getMediaRel.related_primary_key#" index="l" delimiters=":">
									<cfset IA = listGetAt(#getMediaRel.related_primary_key#,1,":")>
									<cfset CCDE = listGetAt(#getMediaRel.related_primary_key#,2,":")>
									<cfset CI = listGetAt(#getMediaRel.related_primary_key#,3,":")>
									<cfquery name="chkCOID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
										update cf_temp_media set related_primary_key_#i# =
										(
											select collection_object_id
											from #theTable# 
											where cat_num = '#CI#' 
											and collection_cde = '#CCDE#'
										)
										WHERE related_primary_key_#i# is not null AND
											username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#"> AND
											key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempMedia2.key#">
									</cfquery>
								</cfloop>
							<cfelseif #getMediaRel.media_relationship# contains 'specimen_part' and len(getMediaRel.related_primary_key) gt 0>
								<cfloop list="#getMediaRel.related_primary_key#" index="l" delimiters=":">
									<cfset IA = listGetAt(#getMediaRel.related_primary_key#,1,":")>
									<cfset CCDE = listGetAt(#getMediaRel.related_primary_key#,2,":")>
									<cfset CI = listGetAt(#getMediaRel.related_primary_key#,3,":")>
									<cfquery name="chkCOID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
										update cf_temp_media set related_primary_key_#i# =
										(
											select #theTable#.collection_object_id
											from #theTable#,cataloged_item
											where cataloged_item.cat_num = '#CI#' 
											and cataloged_item.collection_cde = '#CCDE#'
											and cataloged_item.collection_object_id = specimen_part.derived_from_cat_item
										)
										WHERE related_primary_key_#i# is not null AND
											username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#"> AND
											key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getMediaRel.key#">
									</cfquery>
								</cfloop>
							<!---Add additional blocks if non-numeric entries are the norm for a relationship type--->
							<cfelseif getTempMedia2.media_relationship_1 contains 'agent' and !isNumeric(getTempMedia2.related_primary_key_1)>
								<cfquery name="chkCOID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									update cf_temp_media set related_primary_key_1 =
									(
										select agent_id
										from agent
										where agent_id in (select agent_id from agent_name where agent_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempMedia2.related_primary_key_1#">)
									)
									WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
									and key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempMedia2.key#">
							
								</cfquery>
							<cfelseif getTempMedia2.media_relationship_2 contains 'agent' and !isNumeric(getTempMedia2.related_primary_key_2)>
								<cfquery name="chkCOID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									update cf_temp_media set related_primary_key_2 =
									(
										select agent_id
										from agent
										where agent_id in (select agent_id from agent_name where agent_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempMedia2.related_primary_key_2#">)
									)
									WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
									and key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempMedia2.key#">
							
								</cfquery>
							<!--- Block ends--->
							<cfelseif getTempMedia2.media_relationship_1 contains 'underscore_collection' and !isNumeric(getTempMedia2.related_primary_key_1)>
								<cfquery name="chkCOID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									update cf_temp_media set related_primary_key_1 =
									(
										select underscore_collection.underscore_collection_id
										from #theTable#
										where collection_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempMedia2.related_primary_key_1#">
									)
									WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#"> AND
										key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempMedia2.key#">
								</cfquery>
							<cfelseif getTempMedia2.media_relationship_2 contains 'underscore_collection' and !isNumeric(getTempMedia2.related_primary_key_2)>
								<cfquery name="chkCOID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									update cf_temp_media set related_primary_key_2 =
									(
										select underscore_collection.underscore_collection_id
										from #theTable#
										where collection_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempMedia2.related_primary_key_2#">
									)
									WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#"> AND
										key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempMedia2.key#">
								</cfquery>
								<cfelseif getMediaRel.media_relationship eq 'shows project' and !isNumeric(getMediaRel.related_primary_key)>
								<cfquery name="chkCOID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									update cf_temp_media set related_primary_key_#i# =
									(
										select project_id
										from project
										where project_name = '#getMediaRel.related_primary_key#'
									)
									WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#"> AND
										key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempMedia2.key#">
								</cfquery>
					<!---		<cfelseif getTempMedia2.media_relationship_1 eq 'shows project' and !isNumeric(getTempMedia2.related_primary_key_1)>
								<cfquery name="chkCOID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									update cf_temp_media set related_primary_key_1 =
									(
										select project_id
										from project
										where project_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempMedia2.related_primary_key_1#">
									)
									WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#"> AND
										key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempMedia2.key#">
								</cfquery>
							<cfelseif getTempMedia2.media_relationship_2 contains 'project' and !isNumeric(getTempMedia2.related_primary_key_2)>
								<cfquery name="chkCOID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									update cf_temp_media set related_primary_key_2 =
									(
										select project_id
										from project
										where project_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempMedia2.related_primary_key_2#">
									)
									WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#"> AND
										key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getMediaRel.key#">
								</cfquery>--->
							<cfelseif #getMediaRel.media_relationship# contains 'accn'><!---requires accn number--->
								<cfquery name="chkCOID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									update cf_temp_media set related_primary_key_#i# =
									(
										select #theTable#.transaction_id
										from #theTable#
										where accn_number = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getMediaRel.related_primary_key#">
									)
									WHERE related_primary_key_#i# is not null AND
										username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#"> AND
										key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getMediaRel.key#">
								</cfquery>
							<cfelseif #getMediaRel.media_relationship# contains 'loan'><!---requires deacc number--->
								<cfquery name="chkCOID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									update cf_temp_media set related_primary_key_#i# =
									(
										select #theTable#.transaction_id
										from #theTable#
										where loan_number = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getMediaRel.related_primary_key#">
									)
									WHERE related_primary_key_#i# is not null AND
										username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#"> AND
										key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getMediaRel.key#">
								</cfquery>
							<cfelseif #getMediaRel.media_relationship# contains 'deaccession'><!---requires deacc number--->
								<cfquery name="chkCOID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									update cf_temp_media set related_primary_key_#i# =
									(
										select #theTable#.transaction_id
										from #theTable#
										where deacc_number = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getMediaRel.related_primary_key#">
									)
									WHERE related_primary_key_#i# is not null AND
										username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#"> AND
										key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getMediaRel.key#">
								</cfquery>
							<cfelseif #getMediaRel.media_relationship# contains 'permit'><!---requires permit id--->
								<cfquery name="chkCOID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									update cf_temp_media set related_primary_key_#i# =
									(
										select #theTable#.permit_id
										from #theTable#
										where permit_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getMediaRel.related_primary_key#">
									)
									WHERE related_primary_key_#i# is not null AND
										username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#"> AND
										key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getMediaRel.key#">
								</cfquery>
							<cfelseif #getMediaRel.media_relationship# contains 'borrow'><!---requires permit id--->
								<cfquery name="chkCOID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									update cf_temp_media set related_primary_key_#i# =
									(
										select #theTable#.transaction_id
										from #theTable#
										where borrow_number = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getMediaRel.related_primary_key#">
									)
									WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#"> AND
										key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getMediaRel.key#">
								</cfquery>
							<cfelse>
								<cfif isNumeric(getMediaRel.related_primary_key)>
									<cfquery name="chkCOID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
										update cf_temp_media set related_primary_key_#i# =
										(
											select #tables.column_name# from #theTable# where #tables.column_name# = '#getMediaRel.related_primary_key#'
										)
										WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#"> AND
											key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getMediaRel.key#">
									</cfquery>
								<cfelse>
									<cfquery name="warningMessageAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
										UPDATE
											cf_temp_media
										SET
											status = concat(nvl2(status, status || '; ', ''),'related_primary_key '#related_primary_key#' invalid')
										WHERE 
											related_primary_key_#i# not in (select #tables.column_name# from #theTable# where #tables.column_name# = '#getMediaRel.related_primary_key#') AND
											username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#"> and
											key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempMedia2.key#">
									</cfquery>
								</cfif>
							</cfif>						
						</cfif>
					</cfloop>
				</cfloop>
			</cfif>
			<cfquery name="problemData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT *
				FROM 
					cf_temp_media
				WHERE 
					username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfset i= 1>
			<cfquery name="problemsInData" dbtype="query">
				SELECT count(*) c 
				FROM problemData 
				WHERE status is not null
			</cfquery>
			<h3 class="mt-3">
				<cfif problemsInData.c gt 0>
					There is a problem with #problemsInData.c# of #problemData.recordcount# row(s). See the STATUS column (<a href="/tools/BulkloadMedia.cfm?action=dumpProblems">download</a>). Fix the problems in the data and <a href="/tools/BulkloadMedia.cfm" class="text-danger">start again</a>.
				<cfelse>
					<span class="text-success">Validation checks passed</span>. Look over the table below and <a href="/tools/BulkloadMedia.cfm?action=load" class="btn-link font-weight-lessbold">click to continue (load data)</a> if it all looks good. Or, <a href="/tools/BulkloadMedia.cfm" class="text-danger">start again</a>.
				</cfif>
			</h3>
			<table class='px-0 mx-0 sortable table small table-responsive w-100'>
				<thead class="thead-light">
					<tr>
						<th>BULKLOAD&nbsp;STATUS</th>
						<th>MEDIA_URI</th>
						<th>MIME_TYPE</th>
						<th>MEDIA_TYPE</th>
						<th>PREVIEW_URI</th>
						<th>MEDIA_LICENSE_ID</th>
						<th>MASK_MEDIA</th>
						<th>CREATED_BY_AGENT_ID</th>
						<th>SUBJECT</th>
						<th>MADE_DATE</th>
						<th>HEIGHT(px)</th>
						<th>WIDTH(px)</th>
						<th>DESCRIPTION</th>
						<th>MEDIA_RELATIONSHIP_1</th>
						<th>RELATED_PRIMARY_KEY_1</th>
						<th>MEDIA_RELATIONSHIP_2</th>
						<th>RELATED_PRIMARY_KEY_2</th>
						<th>MEDIA_LABEL_1</th>
						<th>LABEL_VALUE_1</th>
						<th>MEDIA_LABEL_2</th>
						<th>LABEL_VALUE_2</th>
						<th>MEDIA_LABEL_3</th>
						<th>LABEL_VALUE_3</th>
						<th>MEDIA_LABEL_4</th>
						<th>LABEL_VALUE_4</th>	
						<th>MEDIA_LABEL_5</th>
						<th>LABEL_VALUE_5</th>
						<th>MEDIA_LABEL_6</th>
						<th>LABEL_VALUE_6</th>
						<th>MEDIA_LABEL_7</th>
						<th>LABEL_VALUE_7</th>
						<th>MEDIA_LABEL_8</th>
						<th>LABEL_VALUE_8</th>
					</tr>
				<tbody>
					<cfloop query="problemData">
						<tr>
							<td><cfif len(problemData.status) eq 0>Cleared to load<cfelse><strong>#problemData.status#</strong></cfif></td>
							<td>#problemData.MEDIA_URI# #validstyle#</td>
							<td>#problemData.MIME_TYPE#</td>
							<td>#problemData.MEDIA_TYPE#</td>
							<td>#problemData.PREVIEW_URI#</td>
							<td>#problemData.MEDIA_LICENSE_ID#</td>
							<td>#problemData.MASK_MEDIA#</td>
							<td>#problemData.CREATED_BY_AGENT_ID#</td>
							<td>#problemData.SUBJECT#</td>
							<td>#problemData.MADE_DATE#</td>
							<td>#problemData.HEIGHT#</td>
							<td>#problemData.WIDTH#</td>
							<td>#problemData.DESCRIPTION#</td>
							<td>#problemData.MEDIA_RELATIONSHIP_1#</td>
							<td>#problemData.RELATED_PRIMARY_KEY_1#</td>
							<td>#problemData.MEDIA_RELATIONSHIP_2#</td>
							<td>#problemData.RELATED_PRIMARY_KEY_2#</td>
							<td>#problemData.MEDIA_LABEL_1#</td>
							<td>#problemData.LABEL_VALUE_1#</td>
							<td>#problemData.MEDIA_LABEL_2#</td>
							<td>#problemData.LABEL_VALUE_2#</td>
							<td>#problemData.MEDIA_LABEL_3#</td>
							<td>#problemData.LABEL_VALUE_3#</td>
							<td>#problemData.MEDIA_LABEL_4#</td>
							<td>#problemData.LABEL_VALUE_4#</td>
							<td>#problemData.MEDIA_LABEL_5#</td>
							<td>#problemData.LABEL_VALUE_5#</td>
							<td>#problemData.MEDIA_LABEL_6#</td>
							<td>#problemData.LABEL_VALUE_6#</td>
							<td>#problemData.MEDIA_LABEL_7#</td>
							<td>#problemData.LABEL_VALUE_7#</td>
							<td>#problemData.MEDIA_LABEL_8#</td>
							<td>#problemData.LABEL_VALUE_8#</td>	
						</tr>
					</cfloop>
				</tbody>
			</table>
		</cfoutput>
	</cfif>

<!------------------------------------------------------->

	<cfif action is "load">
		<h2 class="h4">Third step: Apply changes.</h2>
		<cfoutput>
			
			<cfset problem_key = "">
			<cftransaction>
			<div class="position-relative" style="padding-top: 22px;">
				<cfquery name="getTempData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT * FROM cf_temp_media
					WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cfquery name="getAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT agent_id FROM agent_name
					WHERE agent_name_type = 'login'
					AND agent_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cfquery name="getCounts" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT 
						count(distinct media_uri) ctobj 
					FROM 
						cf_temp_media
					WHERE 
						username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cftry>
					<cfset media_updates = 0>
					<cfif getTempData.recordcount EQ 0>
						<cfthrow message="You have no rows to load in the media bulkloader table (cf_temp_media). <a href='/tools/BulkloadMedia.cfm'>Start over</a>"><!--- " --->
					</cfif>
					<div class="mt-2">
					<cfloop query="getTempData">
						<cfset username = '#session.username#'>
						<cfquery name="mediaDups" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="updateMedia1_result">
							SELECT 
								media_uri 
							FROM 
								MEDIA
							WHERE 
								media_uri = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.media_uri#">
							GROUP BY 
								media_uri
								having count(*) > 1
						</cfquery>
						<cfset problem_key = getTempData.key>
						<cfquery name="mid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							select sq_media_id.nextval nv from dual
						</cfquery>
						<cfset media_id=mid.nv>
						<cfif len(media_license_id) is 0>
							<cfset medialicenseid = 1>
						<cfelse>
							<cfset medialicenseid = media_license_id>
						</cfif>
						<cfif len(mask_media) is 0>
							<cfset maskmedia = 0>
						<cfelse>
							<cfset maskmedia = mask_media>
						</cfif>
						<cfquery name="makeMedia" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#"  result="insResult">
							INSERT into media (
								media_id,
								media_uri,
								mime_type,
								media_type,
								preview_uri,
								media_license_id,
								mask_media_fg
							) VALUES (
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#media_id#">,
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.media_uri#">,
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.mime_type#">,
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.media_type#">,
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.preview_uri#">,
								<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempData.media_license_id#">,
								<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempData.mask_media#">
							)
						</cfquery>
						<cfset rowid = insResult.generatedkey>
						<cfquery name="getID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							SELECT 
								media_id as theId
							FROM 
								media
							WHERE 
								ROWIDTOCHAR(rowid) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#rowid#">
						</cfquery>
						<cfif len(getTempData.media_relationship_1) gt 0>
							<cfquery name="makeRelations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="RelResult">
								INSERT into media_relations (
									media_id,
									media_relationship,
									created_by_agent_id,
									related_primary_key
								) VALUES (
									<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getID.theId#">,
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.media_relationship_1#">,
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.created_by_agent_id#">,
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.RELATED_PRIMARY_KEY_1#">
								)
							</cfquery>
						</cfif>
						<cfif len(getTempData.media_relationship_2) gt 0>
							<cfquery name="makeRelations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="RelResult">
								INSERT into media_relations (
									media_id,
									media_relationship,
									created_by_agent_id,
									related_primary_key
								) VALUES (
									<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getID.theId#">,
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.media_relationship_2#">,
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.created_by_agent_id#">,
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.RELATED_PRIMARY_KEY_2#">
								)
							</cfquery>
						</cfif>
						<cfquery name="makeLabels" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="LabResult">
							INSERT into media_labels (
								media_id,
								media_label,
								label_value,
								assigned_by_agent_id
							) VALUES (
								<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getID.theId#">,
								'Subject',
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.SUBJECT#">,	
								<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getAgent.agent_id#">
							)
						</cfquery>
						<cfquery name="makeLabels" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="LabResult">
							INSERT into media_labels (
								media_id,
								media_label,
								label_value,
								assigned_by_agent_id
							) VALUES (
								<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getID.theId#">,
								'description',
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.DESCRIPTION#">,	
								<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getAgent.agent_id#">
							)
						</cfquery>
						<cfquery name="makeLabels" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="LabResult">
							INSERT into media_labels (
								media_id,
								media_label,
								label_value,
								assigned_by_agent_id
							) VALUES (
								<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getID.theId#">,
								'made date',
								<cfqueryparam cfsqltype="CF_SQL_DATE" value="#getTempData.MADE_DATE#">,	
								<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getAgent.agent_id#">
							)
						</cfquery>
						<cfif isimagefile(getTempData.media_uri)>
							<cfimage action="info" source="#getTempData.media_uri#" structname="imgInfo"/>
							<cfquery name="makeHeightLabel" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
								insert into media_labels (
									media_id,
									MEDIA_LABEL,
									LABEL_VALUE,
									ASSIGNED_BY_AGENT_ID
								) values (
									<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getID.theId#">,
									'height',
									<cfif len(getTempData.height) gt 0>#getTempData.height#<cfelse>#imgInfo.height#</cfif>,
									<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getAgent.agent_id#">
								)
							</cfquery>
							<cfquery name="makeWidthLabel" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
								insert into media_labels (
									media_id,
									MEDIA_LABEL,
									LABEL_VALUE,
									ASSIGNED_BY_AGENT_ID
								) values (
									<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getID.theId#">,
									'width',
									<cfif len(getTempData.width) gt 0>#getTempData.width#<cfelse>#imgInfo.width#</cfif>,
									<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getAgent.agent_id#">
								)
							</cfquery>
							<cfhttp url="#getTempData.media_uri#" method="get" getAsBinary="yes" result="result">
							
							<cfset MD5HASH=Hash(result.filecontent,"MD5")>

							<cfquery name="makehash" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
								insert into media_labels (
									media_id,
									media_label,
									label_value,
									assigned_by_agent_id
								) values (
									<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getID.theId#">,
									'MD5HASH',
									'#MD5HASH#',
									<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getAgent.agent_id#">
								)
							</cfquery>
						</cfif>
						<cfif len(getTempData.media_label_1) gt 0>
							<cfquery name="makeLabels" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="LabResult">
								INSERT into media_labels (
									media_id,
									media_label,
									label_value,
									assigned_by_agent_id
								) VALUES (
									<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getID.theId#">,
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.media_label_1#">,
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.label_value_1#">,
									<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getAgent.agent_id#">
								)
							</cfquery>
						</cfif>
						<cfif len(getTempData.media_label_2) gt 0>
							<cfquery name="makeLabels" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="LabResult">
								INSERT into media_labels (
									media_id,
									media_label,
									label_value,
									assigned_by_agent_id
								) VALUES (
									<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getID.theId#">,
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.media_label_2#">,
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.label_value_2#">,
									<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getAgent.agent_id#">
								)
							</cfquery>
						</cfif>
						<cfif len(getTempData.media_label_3) gt 0>
							<cfquery name="makeLabels" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="LabResult">
								INSERT into media_labels (
									media_id,
									media_label,
									label_value,
									assigned_by_agent_id
								) VALUES (
									<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getID.theId#">,
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.media_label_3#">,
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.label_value_3#">,
									<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getAgent.agent_id#">
								)
							</cfquery>
						</cfif>
						<cfif len(getTempData.media_label_4) gt 0>
							<cfquery name="makeLabels" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="LabResult">
								INSERT into media_labels (
									media_id,
									media_label,
									label_value,
									assigned_by_agent_id
								) VALUES (
									<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getID.theId#">,
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.media_label_4#">,
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.label_value_4#">,
									<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getAgent.agent_id#">
								)
							</cfquery>
						</cfif>
						<cfif len(getTempData.media_label_5) gt 0>
							<cfquery name="makeLabels" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="LabResult">
								INSERT into media_labels (
									media_id,
									media_label,
									label_value,
									assigned_by_agent_id
								) VALUES (
									<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getID.theId#">,
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.media_label_5#">,
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.label_value_5#">,
									<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getAgent.agent_id#">
								)
							</cfquery>
						</cfif>
						<cfif len(getTempData.media_label_6) gt 0>
							<cfquery name="makeLabels" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="LabResult">
								INSERT into media_labels (
									media_id,
									media_label,
									label_value,
									assigned_by_agent_id
								) VALUES (
									<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getID.theId#">,
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.media_label_6#">,
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.label_value_6#">,
									<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getAgent.agent_id#">
								)
							</cfquery>
						</cfif>
						<cfif len(getTempData.media_label_7) gt 0>
							<cfquery name="makeLabels" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="LabResult">
								INSERT into media_labels (
									media_id,
									media_label,
									label_value,
									assigned_by_agent_id
								) VALUES (
									<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getID.theId#">,
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.media_label_7#">,
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.label_value_7#">,
									<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getAgent.agent_id#">
								)
							</cfquery>
						</cfif>
						<cfif len(getTempData.media_label_8) gt 0>
							<cfquery name="makeLabels" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="LabResult">
								INSERT into media_labels (
									media_id,
									media_label,
									label_value,
									assigned_by_agent_id
								) VALUES (
									<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getID.theId#">,
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.media_label_8#">,
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.label_value_8#">,
									<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getAgent.agent_id#">
								)
							</cfquery>
						</cfif>
						<cfset media_updates = media_updates + insResult.recordcount>
						<cfloop query="getID">
								<cfset myList = #getID.theId#>
								<cfloop list= #myList# index="mediaId" delimiters=",">
									<p class="my-1"><a href="/media/#mediaId#" target="_blank">#mediaId#</a> <cfif len(#getTempData.subject#) gt 0>#getTempData.subject#</cfif>  <cfif len(#getTempData.description#) gt 0>| #getTempData.description#</cfif> </p>
								</cfloop>
							</cfloop>
					</cfloop>
					</div>
					<cfif getTempData.recordcount eq media_updates and updateMedia1_result.recordcount eq 0>
						<h3 class="text-success position-absolute" style="top:0;">Success - loaded #media_updates# media records</h3>
					</cfif>
					<cfif updateMedia1_result.recordcount gt 0>
						<h3 class="text-danger position-absolute" style="top:0;">Not loaded - these have already been loaded</h3>
					</cfif>
				</div>
					<cftransaction action="commit">
				<cfcatch>
					<cftransaction action="ROLLBACK">
					<h3>There was a problem adding media records. </h3>
					<cfquery name="getProblemData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						SELECT STATUS,MEDIA_URI,MIME_TYPE,MEDIA_TYPE,PREVIEW_URI,CREATED_BY_AGENT_ID,SUBJECT,MADE_DATE,HEIGHT,WIDTH,DESCRIPTION,MEDIA_RELATIONSHIP_1,RELATED_PRIMARY_KEY_1,MEDIA_RELATIONSHIP_2,RELATED_PRIMARY_KEY_2,MEDIA_LICENSE_ID,MASK_MEDIA,MEDIA_LABEL_1,LABEL_VALUE_1,MEDIA_LABEL_2,LABEL_VALUE_2,MEDIA_LABEL_3,LABEL_VALUE_3,MEDIA_LABEL_4,LABEL_VALUE_4,MEDIA_LABEL_5,LABEL_VALUE_5,MEDIA_LABEL_6,LABEL_VALUE_6,MEDIA_LABEL_7,LABEL_VALUE_7,MEDIA_LABEL_8,LABEL_VALUE_8
						FROM 
							cf_temp_media
						WHERE
							key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#problem_key#"> AND
							username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
					</cfquery>
					<cfif getProblemData.recordcount GT 0>
						<h3>
							Fix the issues and <a href="/tools/BulkloadMedia.cfm" class="text-danger font-weight-lessbold">start again</a>. Error loading row (<span class="text-danger">#media_updates + 1#</span>) from the CSV: 
							<cfif len(cfcatch.detail) gt 0>
								<span class="font-weight-normal border-bottom border-danger">
									<cfif cfcatch.detail contains "media_type">
										Problem with MEDIA_TYPE
									<cfelseif cfcatch.detail contains "media_uri">
										Duplicate MEDIA_URI
									<cfelseif cfcatch.detail contains "media_license_id">
										Problem with MEDIA_LICENSE_ID
									<cfelseif cfcatch.detail contains "mask_media">
										Invalid MASK_MEDIA number
									<cfelseif cfcatch.detail contains "integrity constraint">
										Invalid MEDIA_ID 
									<cfelseif cfcatch.detail contains "media_id">
										Problem with MEDIA_ID (#cfcatch.detail#)
									<cfelseif cfcatch.detail contains "unique constraint">
										Unique Constraint issue (#cfcatch.detail#)
									<cfelseif cfcatch.detail contains "media_label">
										Problem with a MEDIA_LABEL (#cfcatch.detail#)
									<cfelseif cfcatch.detail contains "label_value">
										Problem with a LABEL_VALUE (#cfcatch.detail#)
									<cfelseif cfcatch.detail contains "ListGetAt">
										Reload your spreadsheet: <a href='/tools/BulkloadMedia.cfm'>upload again</a>
									<cfelseif cfcatch.detail contains "date">
										Problem with MADE_DATE (#cfcatch.detail#)
									<cfelseif cfcatch.detail contains "media_relationship">
										Problem with a MEDIA_RELATIONSHIP (#cfcatch.detail#)
									<cfelseif cfcatch.detail contains "no data">
										No data or the wrong data (#cfcatch.detail#)
									<cfelse>
										<!--- provide the raw error message if it isn't readily interpretable --->
										#cfcatch.detail#
									</cfif>
								</span>
							</cfif>
						</h3>
						<table class='px-0 sortable small table table-responsive table-striped mt-3 w-100'>
							<thead>
								<tr>
									<th>COUNT</th>
									<th>MEDIA_URI</th>
									<th>MEDIA_TYPE</th>
									<th>PREVIEW_URI</th>
									<th>CREATED_BY_AGENT_ID</th>
									<th>SUBJECT</th>
									<th>MADE_DATE</th>
									<th>HEIGHT</th>
									<th>WIDTH</th>
									<th>DESCRIPTION</th>
									<th>MEDIA_LICENSE_ID</th>
									<th>MASK_MEDIA</th>
									<th>MEDIA_RELATIONSHIP_1</th>
									<th>RELATED_PRIMARY_KEY_1</th>
									<th>MEDIA_RELATIONSHIP_2</th>
									<th>RELATED_PRIMARY_KEY_2</th>
									<th>MEDIA_LABEL_1</th>
									<th>LABEL_VALUE_1</th>
									<th>MEDIA_LABEL_2</th>
									<th>LABEL_VALUE_2</th>
									<th>MEDIA_LABEL_3</th>
									<th>LABEL_VALUE_3</th>
									<th>MEDIA_LABEL_4</th>
									<th>LABEL_VALUE_4</th>
									<th>MEDIA_LABEL_5</th>
									<th>LABEL_VALUE_5</th>
									<th>MEDIA_LABEL_6</th>
									<th>LABEL_VALUE_6</th>
									<th>MEDIA_LABEL_7</th>
									<th>LABEL_VALUE_7</th>
									<th>MEDIA_LABEL_8</th>
									<th>LABEL_VALUE_8</th>
								</tr> 
							</thead>
							<tbody>
								<cfset i=1>
								<cfloop query="getProblemData">
									<tr>
										<td>#i#</td>
										<td>#getProblemData.MEDIA_URI# </td>
										<td>#getProblemData.MEDIA_TYPE# </td>
										<td>#getProblemData.PREVIEW_URI# </td>
										<td>#getProblemData.CREATED_BY_AGENT_ID#</td>
										<td>#getProblemData.SUBJECT#</td>
										<td>#getProblemData.MADE_DATE#</td>
										<td>#getProblemData.HEIGHT#</td>
										<td>#getProblemData.WIDTH#</td>
										<td>#getProblemData.DESCRIPTION#</td>
										<td>#getProblemData.MEDIA_LICENSE_ID#</td>
										<td>#getProblemData.MASK_MEDIA#</td>
										<td>#getProblemData.MEDIA_RELATIONSHIP_1#</td>
										<td>#getProblemData.RELATED_PRIMARY_KEY_1#</td>
										<td>#getProblemData.MEDIA_RELATIONSHIP_2#</td>
										<td>#getProblemData.RELATED_PRIMARY_KEY_2#</td>
										<td>#getProblemData.MEDIA_LABEL_1#</td>
										<td>#getProblemData.LABEL_VALUE_1#</td>
										<td>#getProblemData.MEDIA_LABEL_2#</td>
										<td>#getProblemData.LABEL_VALUE_2#</td>
										<td>#getProblemData.MEDIA_LABEL_3#</td>
										<td>#getProblemData.LABEL_VALUE_3#</td>
										<td>#getProblemData.MEDIA_LABEL_4#</td>
										<td>#getProblemData.LABEL_VALUE_4#</td>
										<td>#getProblemData.MEDIA_LABEL_5#</td>
										<td>#getProblemData.LABEL_VALUE_5#</td>
										<td>#getProblemData.MEDIA_LABEL_6#</td>
										<td>#getProblemData.LABEL_VALUE_6#</td>
										<td>#getProblemData.MEDIA_LABEL_7#</td>
										<td>#getProblemData.LABEL_VALUE_7#</td>
										<td>#getProblemData.MEDIA_LABEL_8#</td>
										<td>#getProblemData.LABEL_VALUE_8#</td>
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
			<!--- cleanup any incomplete work by the same user --->
			<cfquery name="clearTempTable" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				DELETE from cf_temp_media WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
		</cfoutput>
	</cfif>
</main>
<cfinclude template="/shared/_footer.cfm">
