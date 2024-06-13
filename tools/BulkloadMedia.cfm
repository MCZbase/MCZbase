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
		SELECT MEDIA_URI,MIME_TYPE,MEDIA_TYPE,PREVIEW_URI,MEDIA_RELATIONSHIPS,MEDIA_LABELS,MEDIA_LICENSE_ID, MASK_MEDIA
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
<cfset fieldlist = "MEDIA_URI,MIME_TYPE,MEDIA_TYPE,PREVIEW_URI,MEDIA_RELATIONSHIPS,MEDIA_LABELS,MEDIA_LICENSE_ID,MASK_MEDIA">
<cfset fieldTypes ="CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_DECIMAL,CF_SQL_DECIMAL">
<cfset requiredfieldlist = "MEDIA_URI,MIME_TYPE,MEDIA_TYPE">
		
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
	<h1 class="h2 mt-2">Bulkload Media</h1>

<!------------------------------------------------------->
	
	<cfif #action# is "nothing">
		<cfoutput>
			<div>
				<p>This tool adds media records. The media can be related to records that have to be in MCZbase prior to uploading this csv. It ignores rows that are exactly the same and additional columns. Some of the values must appear as they do on the following <a href="https://mczbase.mcz.harvard.edu/vocabularies/ControlledVocabulary.cfm?" class="font-weight-bold">controlled vocabularies</a> lists:
					<ul class="list-group list-group-horizontal">
						<li class="list-group-item font-weight-lessbold"><a href="/vocabularies/ControlledVocabulary.cfm?table=CTMEDIA_LABEL">MEDIA_LABEL (17 values)</a> </li> <span class="mt-1"> | </span>
						<li class="list-group-item font-weight-lessbold"><a href="/vocabularies/ControlledVocabulary.cfm?table=CTMEDIA_RELATIONSHIP">MEDIA_RELATIONSHIP (23 values)</a></li> <span class="mt-1"> | </span>
						<li class="list-group-item font-weight-lessbold"><a href="/vocabularies/ControlledVocabulary.cfm?table=CTMEDIA_TYPE">MEDIA_TYPE (6 values)</a> </li><span class="mt-1"> | </span>
						<li class="list-group-item font-weight-lessbold"><a href="/vocabularies/ControlledVocabulary.cfm?table=CTMIME_TYPE">MIME_TYPE (14 values)</a> </li><span class="mt-1"> | </span>
						<li class="list-group-item font-weight-lessbold"><a href="/vocabularies/ControlledVocabulary.cfm?table=CTMEDIA_LICENSE">MEDIA_LICENSE (7 values)</a></li>
					</ul>
				</p>

				<p>Step 1: Ensure that Media exists on the shared drive or external URL and that the records that you want to use for relationships exist (e.g., specimen, agent, collecting event).</p>
				<p>Step 2: Upload a comma-delimited text file (csv). <span class="font-weight-lessbold">(Jump to <a href="##loader" class="btn-link font-weight-bold">Loader</a>.)</span></p>
				<h2 class="h4 mt-4">Media Relationships</h2>
				<p>The format for Media_Relationship is {media_relationship}={value}[;{media_relationship}={value}]</p>
				<h3 class="small90 pl-3">Relationship Examples:</h3>
				<ul class="pl-5">
					<li>created by agent=Jane Doe</li>
					<li>created by agent=Jane Doe;assigned to project=Vocal variation in Pipilo maculatus</li>
					<li>created by agent=Jane Doe;assigned to project=Vocal variation in Pipilo maculatus;shows cataloged_item=MCZ:Bird:12345
					</li>
					<li>created by agent=Jane Doe;documents collecting_event=Baker-Foster Stickleback Collection Field Number|B93-3</li>
					<li>created by agent=Jane Doe;documents collecting_event=1524028</li>
				</ul>
				<h3 class="small90 pl-3">Examples of acceptable relationship values are:</h6>
				<ul class="pl-5">
					<li>Agent Name (must resolve to one agent_id)</li>
					<li>Project Title (exact string match)</li>
					<li>Cataloged Item (DWC triplet)</li>
					<li>Collecting Event (collecting_event_id OR Collecting Event Number Series Type|Collecting Event Number)</li>
					<li>Accession Number</li>
				</ul>
				<h2 class="h4 mt-4">Media Labels</h2>
				<p>The format for MEDIA_LABELS is {media_label}={value}[;{media_label}={value}]. See <a href="/vocabularies/ControlledVocabulary.cfm?table=CTMEDIA_LABEL">controlled vocabulary</a> for label names and values.</p>
				<p>Notes: Made date must be in the form yyyy-mm-dd. More than one media label must be separated by a semicolon, and individual values must not themselves contain semicolons.  Check the data as presented after the file has been uploaded carefully to make sure that the individual media labels and values have been correctly parsed.</p>

				<h3 class="small90 pl-3">Label Examples:</h3>
				<ul class="pl-5">
					<li>audio bit resolution=whatever</li>
					<li>audio bit resolution=2;audio cut id=5</li>
					<li>audio bit resolution=2;audio cut id=5;made date=1964-01-07</li>
				</ul>
				<h2 class="h4 mt-4">Media License:</h2>
				<p>The media license id should be entered using the numeric codes below. If omitted this will default to &quot;1 - MCZ Permissions &amp; Copyright&quot;</p>
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
				<h2 class="h4 mt-4">Mask Media:</h2>
				<p>Follow all the instructions above and read any error messages that pop up in the status column during validation or at the top of the final loading step. Reminder: To mark media as hidden from Public Users put a 1 in the MASK_MEDIA column. Enter zero or Leave blank for Public media.</p>
				<p>Upload a comma-delimited text file (csv). Include column headings, spelled exactly as below. Use "catalog number" as the value of other_id_type to match on catalog number. Click view template and download to create a csv with the column headers in place.</p>
				<span class="btn btn-xs btn-info" onclick="document.getElementById('template').style.display='block';">View template</span>
				<div id="template" style="margin: 1rem 0;display:none;">
					<label for="templatearea" class="data-entry-label mb-1">
						Copy this header line and save it as a .csv file (<a href="/tools/#pageTitle#.cfm?action=getCSVHeader" class="font-weight-lessbold">download</a>)
					</label>
					<textarea rows="2" cols="90" id="templatearea" class="w-100 data-entry-textarea">#fieldlist#</textarea>
				</div>
			</div>
			<a name="loader" class="text-white">top</a>
			<h2 class="mt-4 h4">Columns in <span class="text-danger">red</span> are required; others are optional:</h2>
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
						Loaded no rows from the CSV file.  The file appears to be just a header with no data. Fix file and <a href="/tools/BulkloadMedia.cfm">reload</a>
					<cfelse>
						Successfully read #loadedRows# records from the CSV file.  Next <a href="/tools/BulkloadMedia.cfm?action=validate">click to validate</a>.
					</cfif>
				</h3>
			<cfcatch>
				<h3 class="h4">
					Failed to read the CSV file.  Fix the errors in the file and <a href="/tools/BulkloadMedia.cfm">reload</a>
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
			<cfset key = ''>
			<cfquery name="getTempMedia" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT *
				FROM 
					cf_temp_media
				WHERE 
					username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
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
					key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempMedia.key#"> AND
					username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfif len(getTempMedia.mask_media) gt 0>
				<cfif not(getTempMedia.mask_media EQ 1 or getTempMedia.mask_media EQ 0)>
					<cfquery name="warningMessageMask" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						UPDATE
							cf_temp_media
						SET
							status = concat(nvl2(status, status || '; ', ''),'MASK_MEDIA must = blank, 1 or 0')
						WHERE 
							username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#"> 
					</cfquery>
				</cfif>
			</cfif>
			<cfset i= 1>
			<cfloop query="getTempMedia">
				<cfquery name="warningMessageDup" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE
						cf_temp_media
					SET
						status = concat(nvl2(status, status || '; ', ''),'Media record already exists with this MEDIA_URI')
					WHERE 
						media_URI in (select media_uri from media where MEDIA_URI = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempMedia.media_uri#">) AND
						username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#"> AND
						key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempMedia.key#"> 
				</cfquery>
				<cfif len(getTempMedia.MEDIA_LABELS) gt 0>
					<cfloop list="#getTempMedia.media_labels#" index="label" delimiters=";">
						<cfset labelName=listgetat(label,1,"=")>
						<cfset labelValue=listgetat(label,2,"=")>
						<cfquery name="ct" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							SELECT MEDIA_LABEL FROM CTMEDIA_LABEL 
							WHERE MEDIA_LABEL = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#labelName#">
						</cfquery>
						<cfif len(ct.MEDIA_LABEL) is 0>
							<cfquery name="warningMessageLN" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
								UPDATE
									cf_temp_media
								SET
									status = concat(nvl2(status, status || '; ', ''),'Media label name is invalid')
								WHERE 
									username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#username#">
							</cfquery>
						<cfelseif labelName EQ "made date" && refind("^[0-9]{4}-[0-9]{2}-[0-9]{2}$",labelValue) EQ 0>
							<cfquery name="warningMessageDate" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
								UPDATE
									cf_temp_media
								SET
									status = concat(nvl2(status, status || '; ', ''),'Media Label, made date, must be yyyy-mm-dd')
								WHERE 
									username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#username#">
							</cfquery>
						<cfelse>
							<cfquery name="insLabel" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
								insert into cf_temp_media_labels (
									key,
									MEDIA_LABEL,
									ASSIGNED_BY_AGENT_ID,
									LABEL_VALUE,
									USERNAME
								) values (
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#key#">,
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#labelName#">,
									<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#session.myAgentId#">,
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#labelValue#">,
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#username#">
								)
							</cfquery>
						</cfif>
					</cfloop>
				</cfif>
				<cfif len(getTempMedia.MEDIA_RELATIONSHIPS) gt 0>
					<cfloop list="#getTempMedia.MEDIA_RELATIONSHIPS#" index="label" delimiters=";">
						<cfif len(getTempMedia.MEDIA_RELATIONSHIPS) is 0>
							<cfquery name="warningMessage" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
								UPDATE cf_temp_media
								SET 
									status = concat(nvl2(status, status || '; ', ''),'Media relationship NAME is invalid.')
								WHERE 
									username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#username#"> AND 
									key = <cfqueryparam cfsqltype="CF_SQL_decimal" value="#getTempMedia.key#">
							</cfquery>
						<!---If the relationship is good, use conditionals to insert the other relationships--->
						<cfelse>
							<cfset labelName=listgetat(label,1,"=")>
							<cfset labelValue=listgetat(label,2,"=")>
							<!---Grabs the last word of the ct media relationship to identify the table name.--->
							<cfset table_name = listlast(labelName," ")>
							<cfloop list="#table_name#" index="table_name" delimiters=",">
								<cfquery name = "getRPK"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" >
									SELECT cols.table_name, cols.column_name
									FROM all_constraints cons, all_cons_columns cols
									WHERE cols.table_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(table_name)#" />
									AND cons.constraint_type = 'P'
									AND cons.constraint_name = cols.constraint_name
									AND cons.owner = cols.owner
									AND cons.owner = 'MCZBASE'
									ORDER BY cols.table_name
								</cfquery>
								<cfloop query='getRPK'>
									<cfset primaryKey ='#getRPK.column_name#'>
									<cfif primaryKey is 'agent_id'><cfset agent_id = 'labelValue'></cfif>
									
										<!---Is CSV value is a primary key ID--->
									<cfif isnumeric(labelValue) and len(table_name) gt 0 and table_name neq 'LOAN'>
										<cfoutput>#table_name#: #primaryKey#: #labelValue#</cfoutput>
										<cfquery name="insRel" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
											insert into cf_temp_media_relations (
												KEY,
												MEDIA_RELATIONSHIP,
												CREATED_BY_AGENT_ID,
												RELATED_PRIMARY_KEY,
												USERNAME
											) values (
												<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#key#">,
												<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#labelName#">,
												<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.myAgentId#">,
												<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#labelValue#">,
												<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
											)
										</cfquery>
									<cfelse>
										<cfif #labelName# is 'shows agent' OR #labelName# is 'shows handwriting of agent'>
											<cfquery name="CID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
												select primaryKey from agent_name where agent_name = '#labelValue#'
											</cfquery>
											<cfquery name="insRel" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
												insert into cf_temp_media_relations (
													KEY,
													MEDIA_RELATIONSHIP,
													CREATED_BY_AGENT_ID,
													RELATED_PRIMARY_KEY,
													USERNAME
												) values (
													<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#key#">,
													<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#labelName#">,
													<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.myAgentId#">,
													<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#CID.primaryKey#">,
													<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
												)
											</cfquery>
										<cfelseif #table_name# is 'loan'>
											<cfquery name="CID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
												select #primaryKey# from loan where loan_number = '#labelValue#'
											</cfquery>
										<cfelseif #table_name# is 'borrow'>
											<cfquery name="CID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
												select #primaryKey# from borrow where borrow_number = '#labelValue#'
											</cfquery>
										<cfelseif #table_name# is 'project'>
											<cfquery name="CID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
												select #primaryKey# from #table_name# where project_name = '#labelValue#'
											</cfquery>
										<cfelseif table_name eq 'specimen_part'>
											<cfset #table_name# = 'flat'>
										<cfelseif table_name eq 'cataloged_item'>
											<cfset institution_acronym = listgetat(labelValue,1,":")>
											<cfset collection_cde = listgetat(labelValue,2,":")>
											<cfset cat_num = listgetat(labelValue,3,":")>
											<cfquery name="CID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
												select #primaryKey# from flat where GUID = '#institution_acronym#:#collection_cde#:#cat_num#'
											</cfquery>
										<cfelse>
											<span class="text-danger"><cfoutput>#table_name#: #primaryKey#: #labelValue#</cfoutput>  </span>
											<cfquery name="CID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
												select #primaryKey# from #table_name# where #primarykey# = '#labelValue#'
											</cfquery>
											<cfquery name="insRel" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
												insert into cf_temp_media_relations (
													KEY,
													MEDIA_RELATIONSHIP,
													CREATED_BY_AGENT_ID,
													RELATED_PRIMARY_KEY,
													USERNAME
												) values (
													<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#key#">,
													<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#labelName#">,
													<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.myAgentId#">,
													<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#CID.primaryKey#">,
													<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
												)
											</cfquery>
										</cfif>
									</cfif>
								</cfloop>
							</cfloop>
						</cfif>
						<cfif not isDefined("veryLargeFiles")><cfset veryLargeFiles=""></cfif>
						<cfif veryLargeFiles NEQ "true">
							<!--- both isimagefile and cfimage run into heap space limits with very large files --->
							<cfif isimagefile("#getTempMedia.media_uri#")>
								<cfimage action="info" source="#getTempMedia.media_uri#" structname="imgInfo"/>
								<cfquery name="makeHeightLabel" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									INSERT into cf_temp_media_labels (
										MEDIA_LABEL,
										ASSIGNED_BY_AGENT_ID,
										LABEL_VALUE,
										USERNAME
									) VALUES (
										'height',
										<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.myAgentId#">,
										<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#imgInfo.height#">,
										<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#username#">
									)
								</cfquery>
								<cfquery name="makeWidthLabel" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									insert into cf_temp_media_labels (
										MEDIA_LABEL,
										ASSIGNED_BY_AGENT_ID,
										LABEL_VALUE,
										USERNAME
									) values (
										'width',
										<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.myAgentId#">,
										<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#imgInfo.width#">,
										<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#username#">
									)
								</cfquery>
								<cfhttp url="#getTempMedia.media_uri#" method="get" getAsBinary="yes" result="result">
								<cfset md5hash=Hash(result.filecontent,"MD5")>
								<cfquery name="makeMD5hash" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									INSERT into cf_temp_media_labels (
										MEDIA_LABEL,
										ASSIGNED_BY_AGENT_ID,
										LABEL_VALUE,
										USERNAME
									) VALUES (
										'md5hash',
										<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.myAgentId#">,
										<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#md5Hash#">,
										<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#username#">
									)
								</cfquery>
							</cfif>
						</cfif>
					</cfloop>
				</cfif>
			</cfloop>
			<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				select
					distinct (cf_temp_media.key), cf_temp_media.*
				from
					cf_temp_media,
					cf_temp_media_labels,
					cf_temp_media_relations
				where
					cf_temp_media.key=cf_temp_media_labels.key (+) and
					cf_temp_media.key=cf_temp_media_relations.key (+)
				AND 
					cf_temp_media.username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="problemsInData" dbtype="query">
				SELECT count(*) c 
				FROM data 
				WHERE status is not null
			</cfquery>
			<h3 class="mt-3">
				<cfif problemsInData.c gt 0>
					There is a problem with #problemsInData.c# of #data.recordcount# row(s). See the STATUS column (<a href="/tools/BulkloadMedia.cfm?action=dumpProblems">download</a>). Fix the problems in the data and <a href="/tools/BulkloadMedia.cfm" class="text-danger">start again</a>.
				<cfelse>
					<span class="text-success">Validation checks passed</span>. Look over the table below and <a href="/tools/BulkloadMedia.cfm?action=load" class="btn-link font-weight-lessbold">click to continue</a> if it all looks good. Or, <a href="/tools/BulkloadMedia.cfm" class="text-danger">start again</a>.
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
						<th>MEDIA_RELATIONSHIPS</th>
						<th>MEDIA_LABELS</th>
					</tr>
				<tbody>
					<cfloop query="data">
						<tr>
							<td><cfif len(data.status) eq 0>Cleared to load<cfelse><strong>#data.status#</strong></cfif></td>
							<td>#data.MEDIA_URI#</td>
							<td>#data.MIME_TYPE#</td>
							<td>#data.MEDIA_TYPE#</td>
							<td>#data.PREVIEW_URI#</td>
							<td>#data.MEDIA_LICENSE_ID#</td>
							<td>#data.MEDIA_RELATIONSHIPS#</td>
							<td>#data.MEDIA_LABELS#</td>
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
				<cfquery name="getTempData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT * FROM cf_temp_media
					WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
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
						<cfthrow message="You have no rows to load in the media bulkloader table (cf_temp_media).  <a href='/tools/BulkloadMedia.cfm'>Start over</a>"><!--- " --->
					</cfif>
					<cfloop query="getTempData">
						<cfset username = '#session.username#'>
						<cfquery name="updateMedia1" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="updateMedia1_result">
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
						<cfquery name="makeMedia" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="insResult">
							INSERT into media (
								media_id,
								media_uri,
								mime_type,
								media_type,
								preview_uri,
								media_license_id,
								mask_media_fg
							) VALUES (
								<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">,
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.media_uri#">,
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.mime_type#">,
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.media_type#">,
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.preview_uri#">,
								<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#medialicenseid#">,
								<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#MASKMEDIA#">
							)
						</cfquery>
						<cfquery name="savePK" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="pkResult">
							SELECT 
								media_id 
							FROM
								media
							WHERE 
								ROWIDTOCHAR(rowid) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#insResult.GENERATEDKEY#">
						</cfquery>
						<cfquery name="media_relations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							SELECT 
								* 
							FROM
								cf_temp_media_relations
							WHERE
								key=#key#
						</cfquery>
						<cfloop query="media_relations">
							<cfquery name="makeRel" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
								insert into
									media_relations (
									media_id,
									created_by_agent_id,
									media_relationship,
									related_primary_key
								) values (
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#savePK.MEDIA_ID#">,
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.myAgentId#">,
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#MEDIA_RELATIONSHIP#">,
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#RELATED_PRIMARY_KEY#">
								)
							</cfquery>
						</cfloop>
						<cfquery name="medialabels" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							SELECT * 
							FROM
								cf_temp_media_labels
							WHERE
								key=#key# AND
								username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						</cfquery>
						<cfloop query="medialabels">
							<cfquery name="makeRelation" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
								insert into 
									media_labels (
									media_id,
									media_label,
									label_value
								) values (
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#savePK.MEDIA_ID#">,
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#MEDIA_LABEL#">,
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#LABEL_VALUE#">
								)
							</cfquery>
						</cfloop>
						<cfset media_updates = media_updates + insResult.recordcount>
					</cfloop>
					<p>Number of Media Records added: #media_updates#</p>
					<cfif getTempData.recordcount eq media_updates and updateMedia1_result.recordcount eq 0>
						<h3 class="text-success">Success - loaded</h3>
					</cfif>
					<cfif updateMedia1_result.recordcount gt 0>
						<h3 class="text-danger">Not loaded - these have already been loaded</h3>
					</cfif>
					<cftransaction action="commit">
				<cfcatch>
					<cftransaction action="ROLLBACK">
					<h3>There was a problem adding media records. </h3>
					<cfquery name="getProblemData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						SELECT 
							MEDIA_URI, MIME_TYPE, MEDIA_TYPE, PREVIEW_URI, MEDIA_RELATIONSHIPS, MEDIA_LABELS, STATUS, MEDIA_LICENSE_ID, MASK_MEDIA,USERNAME
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
										Invalid or missing MEDIA_URI
									<cfelseif cfcatch.detail contains "media_relationship">
										Invalid MEDIA_RELATIONSHIP
									<cfelseif cfcatch.detail contains "media_labels">
										Invalid MEDIA_LABELS
									<cfelseif cfcatch.detail contains "media_license_id">
										Problem with MEDIA_LICENSE_ID
									<cfelseif cfcatch.detail contains "mask_media">
										Invalid MASK_MEDIA number
									<cfelseif cfcatch.detail contains "integrity constraint">
										Invalid MEDIA_ID 
									<cfelseif cfcatch.detail contains "media_id">
										Problem with MEDIA_ID (#cfcatch.detail#)
									<cfelseif cfcatch.detail contains "unique constraint">
										This media_uri has already been entered. Remove from spreadsheet and try again.
									<cfelseif cfcatch.detail contains "no data">
										No data or the wrong data (#cfcatch.detail#)
									<cfelse>
										<!--- provide the raw error message if it isn't readily interpretable --->
										#cfcatch.detail#
									</cfif>
								</span>
							</cfif>
						</h3>
						<table class='px-0 sortable small table table-responsive table-striped d-lg-table mt-3'>
							<thead>
								<tr>
									<th>COUNT</th>
									<th>MEDIA_URI</th>
									<th>MEDIA_TYPE</th>
									<th>PREVIEW_URI</th>
									<th>MEDIA_RELATIONSHIPS</th>
									<th>MEDIA_LABELS</th>
									<th>MEDIA_LICENSE_ID</th>
									<th>MASK_MEDIA</th>
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
										<td>#getProblemData.MEDIA_RELATIONSHIPS#</td>
										<td>#getProblemData.MEDIA_LABELS#</td>
										<td>#getProblemData.MEDIA_LICENSE_ID#</td>
										<td>#getProblemData.MASK_MEDIA#</td>
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
			<cfquery name="clearTempTable" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				DELETE from cf_temp_media_relations WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="clearTempTable" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				DELETE from cf_temp_media_labels WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
		</cfoutput>
	</cfif>
</main>
<cfinclude template="/shared/_footer.cfm">
