<!--- tools/bulkloadMedia.cfm add media in bulk.

Copyright 2008-2017 Contributors to Arctos
Copyright 2008-2023 President and Fellows of Harvard College

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
<cfset pageTitle = "Bulkload Media">
<cfinclude template="/shared/_header.cfm">
<cfif not isDefined("action") OR len(action) EQ 0><cfset action="nothing"></cfif>
<main class="container-fluid px-5 py-3" id="content">
	<h1 class="h2 mt-2">Bulkload Media</h1>
	<cfif #action# is "nothing">
		<cfoutput>
			<p>This tool adds media records. The media can be related to records that have to be in MCZbase prior to uploading this csv. It ignores rows that are exactly the same and additional columns. Some of the values must appear as they do on the following <a href="https://mczbase.mcz.harvard.edu/vocabularies/ControlledVocabulary.cfm?" class="font-weight-bold">controlled vocabularies</a> lists: </p>
				<ul>
					<li><a href="/vocabularies/ControlledVocabulary.cfm?table=CTMEDIA_LABEL">MEDIA_LABEL (17 values)</a></li>
					<li><a href="/vocabularies/ControlledVocabulary.cfm?table=CTMEDIA_RELATIONSHIP">MEDIA_RELATIONSHIP (23 values)</a></li>
					<li><a href="/vocabularies/ControlledVocabulary.cfm?table=CTMEDIA_TYPE">MEDIA_TYPE (6 values)</a></li>
					<li><a href="/vocabularies/ControlledVocabulary.cfm?table=CTMIME_TYPE">MIME_TYPE (14 values)</a></li>
					<li><a href="/vocabularies/ControlledVocabulary.cfm?table=CTMEDIA_LICENSE">MEDIA_LICENSE (7 values)</a></li>
				</ul>
			<p>Step 1: Ensure that Media exists on the shared drive or externl URL and that the records that you want to  (e.g., specimen, agent, collecting event) exist.</p>
			<p>Step 2: Upload a comma-delimited text file (csv). (Jump to <a href="##loader">loader</a>)</p>
			<h2 class="h4 mt-4">Media Relationships</h2>
			<p>The format for Media_Relationship is {media_relationship}={value}[;{media_relationship}={value}]</p>
			<p class="font-weight-bold text-dark">Relationship Examples:</p>
			<ul>
				<li>created by agent=Jane Doe</li>
				<li>created by agent=Jane Doe;assigned to project=Vocal variation in Pipilo maculatus</li>
				<li>created by agent=Jane Doe;assigned to project=Vocal variation in Pipilo maculatus;shows cataloged_item=MCZ:Bird:12345
				</li>
				<li>created by agent=Jane Doe;documents collecting_event=Baker-Foster Stickleback Collection Field Number|B93-3</li>
				<li>created by agent=Jane Doe;documents collecting_event=1524028</li>
			</ul>
			<p class="font-weight-bold text-dark">Acceptable values for relationships are:</p>
			<ul>
				<li>Agent Name (must resolve to one agent_id)</li>
				<li>Project Title (exact string match)</li>
				<li>Cataloged Item (DWC triplet)</li>
				<li>Collecting Event (collecting_event_id OR Collecting Event Number Series Type|Collecting Event Number)</li>
			</ul>
			<h2 class="h4 mt-4">Media Labels</h2>
			<p>The format for MEDIA_LABELS is {media_label}={value}[;{media_label}={value}]</p>
			<p>Notes: Made date must be in the form yyyy-mm-dd. More than one media label must be separated by a semicolon, and individual values must not themselves contain semicolons.  Check the data as presented after the file has been uploaded carefully to make sure that the individual media labels and values have been correctly parsed.</p>
			
			<p class="font-weight-bold text-dark">Media Label Examples:</h2>
			<ul>
				<li>audio bit resolution=whatever</li>
				<li>audio bit resolution=2;audio cut id=5</li>
				<li>audio bit resolution=2;audio cut id=5;made date=1964-01-07</li>
			</ul>
			<h2 class="h4 mt-4">Media License:</h2>
			<p>The media license id should be entered using the numeric codes below. If omitted this will default to &quot;1 - MCZ Permissions &amp; Copyright&quot;</p>
			<p class="font-weight-bold text-dark">Media License Codes:</p>
			<dl>
				<dt class="btn-secondary"><span class="badge badge-light">1 </span> MCZ Permissions &amp; Copyright</dt> <dd>All MCZ images and publications should have this designation</dd>
				<dt class="btn-secondary"><span class="badge badge-light">4 </span> Rights defined by 3rd party host</dt> <dd>This material is hosted by an external party. Please refer to the licensing statement provided by the linked host.</dd>
				<dt class="btn-secondary"><span class="badge badge-light">5 </span> Creative Commons Zero (CC0)</dt><dd>CC0 enables scientists, educators, artists and other creators and owners of copyright- or database-protected content to waive those interests in their works and thereby place them as completely as possible in the public domain.</dd>
				<dt class="btn-secondary"><span class="badge badge-light">6 </span> Creative Commons Attribution (CC BY)</dt><dd>This license lets others distribute, remix, tweak, and build upon your work, even commercially, as long as they credit you for the original creation.</dd>
				<dt class="btn-secondary"><span class="badge badge-light">7</span> Creative Commons Attribution-ShareAlike (CC BY-SA)</dt> <dd>This license lets others remix, tweak, and build upon your work even for commercial purposes, as long as they credit you and license their new creations under the identical terms.</dd>
				<dt class="btn-secondary"><span class="badge badge-light">8 </span> Creative Commons Attribution-NonCommercial (CC BY-NC)</dt><dd>This license lets others remix, tweak, and build upon your work non-commercially, and although their new works must also acknowledge you and be non-commercial, they don&apos;t have to license their derivative works on the same terms.</dd>
				<dt class="btn-secondary"><span class="badge badge-light">9 </span> Creative Commons Attribution-NonCommercial-ShareAlike (CC BY-NC-SA)</dt><dd>This license lets others remix, tweak, and build upon your work non-commercially, as long as they credit you and license their new creations under the identical terms.</dd>
			</dl>
			<h2 class="h4 mt-4">Mask Media:</h2>
			<p>To mark media as hidden from Public Users put a 1 in the MASK_MEDIA column. Leave blank for Public media</p>
			<p>Upload a comma-delimited text file (csv). Include column headings, spelled exactly as below. Use "catalog number" as the value of other_id_type to match on catalog number.</p>
			<span class="btn btn-xs btn-info" onclick="document.getElementById('template').style.display='block';">View template</span>
			<div id="template" style="margin: 1rem 0;display:none;">
				<label for="templatearea" class="data-entry-label mb-1">
					Copy this header line and save it as a .csv file (<a href="/tools/BulkloadAttributes.cfm?action=getCSVHeader">download</a>)
				</label>
				<textarea rows="2" cols="90" id="templatearea" class="w-100 data-entry-textarea">#fieldlist#</textarea>
			</div>
			<a name="loader" class="text-white">top</a>
			<h2 class="mt-4 h4">Columns in <span class="text-danger">red</span> are required; others are optional:</h2>
			<ul class="mb-4 h4 font-weight-normal">
				<cfloop list="#fieldlist#" index="field" delimiters=",">
					<cfset aria = "">
					<cfif listContains(requiredfieldlist,field,",")>
						<cfset class="text-danger">
						<cfset aria = "aria-label='Required Field'">
					<cfelse>
						<cfset class="text-dark">
					</cfif>
					<li class="#class#" #aria#>#field#</li>
				</cfloop>
			</ul>
			<form name="atts" method="post" enctype="multipart/form-data" action="/tools/BulkloadAttributes.cfm">
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
</main>
<!------------------------------------------------------->
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
			<cftry>
				<!--- cleanup any incomplete work by the same user --->
				<cfquery name="killOld" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					delete from cf_temp_media WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cfquery name="killOld" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					delete from cf_temp_media_relations WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cfquery name="killOld" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					delete from cf_temp_media_labels WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
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
				<cfset reqFieldsResponse = checkRequiredFields(fieldList=fieldList,requiredFieldList=requiredFieldList,NO_COLUMN_ERR=NO_COLUMN_ERR)>

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
						you probably want to <strong><a href="/tools/BulkloadNewParts.cfm">reload</a></strong> this file selecting a different encoding.  If these appear as expected, then 
							you selected the correct encoding and can continue to validate or load.</p>
					</div>
					<ul class="pb-1 h4 list-unstyled">
						#foundHighAscii# #foundMultiByte#
					</ul>
				</cfif>
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
<!------------------------------------------------------->
	<cfif #action# is "validate">
		<h2 class="h4 mb-3">Second step: Data Validation</h2>
		<cfoutput>
			<cfquery name="getTempTableMedia" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT 
					media_URI, key
				FROM 
					cf_temp_media
				WHERE 
					username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfset i= 1>
			<cfloop query="getTempTableMedia">
				<!--- For each row, set the target collection_object_id --->
				<cfif getTempTableMedia.media_URI gt 0>
					<!--- either based on catalog_number --->
					<cfquery name="getCID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						UPDATE
							cf_temp_media
						SET
							status = concat(nvl2(status, status || '; ', ''),'Media URI already exists on shared drive ' || media_uri)
						WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
							and key = <cfqueryparam cfsqltype="CF_SQL_decimal" value="#getTempTableTypes.key#"> 
					</cfquery>
				</cfif>
				<cfif len(mask_media) gt 0>
					<cfif not(mask_media EQ 1 or mask_media EQ 0)>
						UPDATE
							cf_temp_media
						SET
							status = concat(nvl2(status, status || '; ', ''),'MASK_MEDIA should be blank, 1 or 0' || mask_media)
						WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
							and key = <cfqueryparam cfsqltype="CF_SQL_decimal" value="#getTempTableTypes.key#"> 
					</cfif>
				</cfif>
				<cfif len(MEDIA_LABELS) gt 0>
					<cfloop list="#media_labels#" index="l" delimiters=";">
						<cfset ln=listgetat(l,1,"=")>
						<cfset lv=listgetat(l,2,"=")>
						<cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							SELECT MEDIA_LABEL 
							FROM CTMEDIA_LABEL 
							WHERE MEDIA_LABEL = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ln#">
						</cfquery>
						<cfif len(c.MEDIA_LABEL) is 0>
							<cfset rec_stat=listappend(rec_stat,'Media label #ln# is invalid',";")>
						<cfelseif ln EQ "made date" && refind("^[0-9]{4}-[0-9]{2}-[0-9]{2}$",lv) EQ 0>
							<cfset rec_stat=listappend(rec_stat,'Media label #ln# must have a value in the form yyyy-mm-dd',";")>
						<cfelse>
							<cfquery name="i" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
								insert into cf_temp_media_labels (
									key,
									MEDIA_LABEL,
									ASSIGNED_BY_AGENT_ID,
									LABEL_VALUE
								) values (
									<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#key#">,
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ln#">,
									<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#session.myAgentId#">,
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#lv#">
								)
							</cfquery>
						</cfif>
					</cfloop>
				</cfif>
			</cfloop>
			<cfif len(MEDIA_LABELS) gt 0>
				<cfloop list="#media_labels#" index="l" delimiters=";">
					<cfset ln=listgetat(l,1,"=")>
					<cfset lv=listgetat(l,2,"=")>
					<cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						SELECT MEDIA_LABEL 
						FROM CTMEDIA_LABEL 
						WHERE MEDIA_LABEL = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ln#">
					</cfquery>
					<cfif len(c.MEDIA_LABEL) is 0>
						<cfset rec_stat=listappend(rec_stat,'Media label #ln# is invalid',";")>
					<cfelseif ln EQ "made date" && refind("^[0-9]{4}-[0-9]{2}-[0-9]{2}$",lv) EQ 0>
						<cfset rec_stat=listappend(rec_stat,'Media label #ln# must have a value in the form yyyy-mm-dd',";")>
					<cfelse>
						<cfquery name="i" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							insert into cf_temp_media_labels (
								key,
								MEDIA_LABEL,
								ASSIGNED_BY_AGENT_ID,
								LABEL_VALUE
							) values (
								<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#key#">,
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ln#">,
								<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#session.myAgentId#">,
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#lv#">
							)
						</cfquery>
					</cfif>
				</cfloop>
			</cfif>
			<cfif len(MEDIA_RELATIONSHIPS) gt 0>
				<cfloop list="#MEDIA_RELATIONSHIPS#" index="l" delimiters=";">
					<cfset ln=listgetat(l,1,"=")>
					<cfset lv=listgetat(l,2,"=")>
					<cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						select MEDIA_RELATIONSHIP from CTMEDIA_RELATIONSHIP where MEDIA_RELATIONSHIP='#ln#'
					</cfquery>
					<cfif len(c.MEDIA_RELATIONSHIP) is 0>
						<cfset rec_stat=listappend(rec_stat,'Media relationship #ln# is invalid',";")>
					<cfelse>
						<cfset table_name = listlast(ln," ")>
						<cfif table_name is "agent">
							<cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
								select distinct(agent_id) agent_id from agent_name where agent_name ='#lv#'
							</cfquery>
							<cfif c.recordcount is 1 and len(c.agent_id) gt 0>
								<cfquery name="i" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									insert into cf_temp_media_relations (
										key,
										MEDIA_RELATIONSHIP,
										CREATED_BY_AGENT_ID,
										RELATED_PRIMARY_KEY
									) values (
										#key#,
										'#ln#',
										#session.myAgentId#,
										#c.agent_id#
									)
								</cfquery>
							<cfelse>
								<cfset rec_stat=listappend(rec_stat,'Agent #lv# matched #c.recordcount# records.',";")>
							</cfif>
						<cfelseif table_name is "locality">
							<cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
								select locality_id from locality where locality_id ='#lv#'
							</cfquery>
							<cfif c.recordcount is 1 and len(c.locality_id) gt 0>
								<cfquery name="i" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									insert into cf_temp_media_relations (
										key,
										MEDIA_RELATIONSHIP,
										CREATED_BY_AGENT_ID,
										RELATED_PRIMARY_KEY
									) values (
										#key#,
										'#ln#',
										#session.myAgentId#,
										#c.locality_id#
									)
								</cfquery>
							<cfelse>
								<cfset rec_stat=listappend(rec_stat,'locality_id #lv# matched #c.recordcount# records.',";")>
							</cfif>
						<cfelseif table_name is "collecting_event">
							<cfif isnumeric(lv)>
								<cfset idtype = "collecting_event_id">
								<cfset idvalue = lv>
							<cfelse>
								<cfset idtype=trim(listfirst(lv,"|"))>
								<cfset idvalue=trim(listlast(lv,"|"))>
							</cfif>
							<cfif idtype EQ "collecting_event_id">
								<cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									select collecting_event_id from collecting_event where collecting_event_id ='#idvalue#'
								</cfquery>
								<cfif c.recordcount is 1 and len(c.collecting_event_id) gt 0>
									<cfquery name="i" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
										insert into cf_temp_media_relations (
											key,
											MEDIA_RELATIONSHIP,
											CREATED_BY_AGENT_ID,
											RELATED_PRIMARY_KEY
										) values (
											#key#,
											'#ln#',
											#session.myAgentId#,
											#c.collecting_event_id#
										)
									</cfquery>
								<cfelse>
									<cfset rec_stat=listappend(rec_stat,'collecting_event #lv# matched #c.recordcount# records.',";")>
								</cfif>
							<cfelse>
								<cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									select collecting_event_id 
									from coll_event_num_series ns 
										join coll_event_number n  on ns.coll_event_num_series_id = n.coll_event_num_series_id
										where ns.number_series = '#idtype#'
										and n.coll_event_number = '#idvalue#'
								</cfquery>
								<cfif c.recordcount gt 0>
									<cfloop query="c">
										<cfif len(c.collecting_event_id) gt 0>
											<cfquery name="i" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
												insert into cf_temp_media_relations (
												key,
												MEDIA_RELATIONSHIP,
												CREATED_BY_AGENT_ID,
												RELATED_PRIMARY_KEY
												) values (
												#d.key#,
												'#ln#',
												#session.myAgentId#,
												#c.collecting_event_id#)
											</cfquery>
										</cfif>
									</cfloop>
								<cfelse>
									<cfset rec_stat=listappend(rec_stat,'collecting event number #lv# matched #c.recordcount# records.',";")>
								</cfif>
							</cfif>
						<cfelseif table_name is "project">
							<cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
								select distinct(project_id) project_id from project where PROJECT_NAME ='#lv#'
							</cfquery>
							<cfif c.recordcount is 1 and len(c.project_id) gt 0>
								<cfquery name="i" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									insert into cf_temp_media_relations (
										key,
										MEDIA_RELATIONSHIP,
										CREATED_BY_AGENT_ID,
										RELATED_PRIMARY_KEY
									) values (
										#key#,
										'#ln#',
										#session.myAgentId#,
										#c.project_id#
									)
								</cfquery>
							<cfelse>
								<cfset rec_stat=listappend(rec_stat,'Project #lv# matched #c.recordcount# records.',";")>
							</cfif>
						<cfelseif table_name is "publication">
							<cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
								select publication_id from publication where publication_id ='#lv#'
							</cfquery>
							<cfif c.recordcount is 1 and len(c.publication_id) gt 0>
								<cfquery name="i" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									insert into cf_temp_media_relations (
										key,
										MEDIA_RELATIONSHIP,
										CREATED_BY_AGENT_ID,
										RELATED_PRIMARY_KEY
									) values (
										#key#,
										'#ln#',
										#session.myAgentId#,
										#c.publication_id#
									)
								</cfquery>
							<cfelse>
								<cfset rec_stat=listappend(rec_stat,'publication_id #lv# matched #c.recordcount# records.',";")>
							</cfif>
						<cfelseif table_name is "cataloged_item">
						<cftry>
							<cfset institution_acronym = listgetat(lv,1,":")>
							<cfset collection_cde = listgetat(lv,2,":")>
							<cfset cat_num = listgetat(lv,3,":")>
							<cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
								select collection_object_id from
									cataloged_item,
									collection
								WHERE
									cataloged_item.collection_id = collection.collection_id AND
									cat_num = '#cat_num#' AND
									lower(collection.collection_cde)='#lcase(collection_cde)#' AND
									lower(collection.institution_acronym)='#lcase(institution_acronym)#'
							</cfquery>
							<cfif c.recordcount is 1 and len(c.collection_object_id) gt 0>
								<cfquery name="i" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									insert into cf_temp_media_relations (
										key,
										MEDIA_RELATIONSHIP,
										CREATED_BY_AGENT_ID,
										RELATED_PRIMARY_KEY
									) values (
										#key#,
										'#ln#',
										#session.myAgentId#,
										#c.collection_object_id#
									)
								</cfquery>
							<cfelse>
								<cfset rec_stat=listappend(rec_stat,'Cataloged Item #lv# matched #c.recordcount# records.',";")>
							</cfif>
							<cfcatch>
								<cfset rec_stat=listappend(rec_stat,'#lv# is not a BOO DWC Triplet. *#institution_acronym#* *#collection_cde#* *#cat_num#*',";")>
							</cfcatch>
						</cftry>
						<cfelseif table_name is "accn">
							<cfset coll = listgetat(lv,1," ")>
							<cfset accnnum = listgetat(lv,2," ")>
							<cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
								select a.transaction_id
								from accn a, trans t, collection c
								where a.transaction_id = t.transaction_id
								and t.collection_id = c.collection_id
								and a.accn_number = #accnnum#
								and c.collection = '#coll#'
							</cfquery>
							<cfif c.recordcount is 1 and len(c.transaction_id) gt 0>
								<cfquery name="i" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									insert into cf_temp_media_relations (
										key,
										MEDIA_RELATIONSHIP,
										CREATED_BY_AGENT_ID,
										RELATED_PRIMARY_KEY
									) values (
										#key#,
										'#ln#',
										#session.myAgentId#,
										#c.transaction_id#
									)
								</cfquery>
							<cfelse>
								<cfset rec_stat=listappend(rec_stat,'accn number #lv# matched #c.recordcount# records.',";")>
							</cfif>
						<cfelseif table_name is "permit">
							<cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
								select permit_id from permit where permit_num = '#lv#'
							</cfquery>
							<cfif c.recordcount is 1 and len(c.permit_id) gt 0>
								<cfquery name="i" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									insert into cf_temp_media_relations (
										key,
										MEDIA_RELATIONSHIP,
										CREATED_BY_AGENT_ID,
										RELATED_PRIMARY_KEY
									) values (
										<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#key#">,
										<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ln#">,
										<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#session.myAgentId#">,
										<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#c.permit_id#">
									)
								</cfquery>
							<cfelse>
								<cfset rec_stat=listappend(rec_stat,'permit number #lv# matched #c.recordcount# records.',";")>
							</cfif>
						<cfelseif table_name is "borrow">
							<cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
								select transaction_id 
								from borrow 
								where borrow_number = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#lv#">
							</cfquery>
							<cfif c.recordcount is 1 and len(c.transaction_id) gt 0>
								<cfquery name="i" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									insert into cf_temp_media_relations (
										key,
										MEDIA_RELATIONSHIP,
										CREATED_BY_AGENT_ID,
										RELATED_PRIMARY_KEY
									) values (
										#key#,
										'#ln#',
										#session.myAgentId#,
										#c.transaction_id#
									)
								</cfquery>
							<cfelse>
								<cfset rec_stat=listappend(rec_stat,'permit number #lv# matched #c.recordcount# records.',";")>
							</cfif>
						<cfelseif table_name is "specimen_part">
							<cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
								select sp.collection_object_id
								from specimen_part sp
								join (select * from coll_obj_cont_hist where current_container_fg = 1)  ch on (sp.collection_object_id = ch.collection_object_id)
								join  container c on (ch.container_id = c.container_id)
								join  container pc on (c.parent_container_id = pc.container_id)
								where pc.barcode = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#lv#">
							</cfquery>
							<cfif c.recordcount is 1 and len(c.collection_object_id) gt 0>
								<cfquery name="i" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									insert into cf_temp_media_relations (
											key,
											MEDIA_RELATIONSHIP,
											CREATED_BY_AGENT_ID,
											RELATED_PRIMARY_KEY
									) values (
											#key#,
											'#ln#',
											#session.myAgentId#,
											#c.collection_object_id#
									)
								</cfquery>
							<cfelse>
								<cfset rec_stat=listappend(rec_stat,'barcode #lv# matched #c.recordcount# records.',";")>
							</cfif>
						<cfelse>
							<cfset rec_stat=listappend(rec_stat,'Media relationship #ln# is not handled',";")>
						</cfif>
					</cfif>
				</cfloop>
			</cfif>
			<cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				select MIME_TYPE from CTMIME_TYPE where MIME_TYPE='#MIME_TYPE#'
			</cfquery>
			<cfif len(c.MIME_TYPE) is 0>
				<cfset rec_stat=listappend(rec_stat,'MIME_TYPE #MIME_TYPE# is invalid',";")>
			</cfif>
			<cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				select MEDIA_TYPE from CTMEDIA_TYPE where MEDIA_TYPE='#MEDIA_TYPE#'
			</cfquery>
			<cfif len(c.MEDIA_TYPE) is 0>
				<cfset rec_stat=listappend(rec_stat,'MEDIA_TYPE #MEDIA_TYPE# is invalid',";")>
			</cfif>
			<cfif len(MEDIA_LICENSE_ID) gt 0>
				<cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					select media_license_id from CTMEDIA_LICENSE where media_license_id='#MEDIA_LICENSE_ID#'
				</cfquery>
				<cfif len(c.media_license_id) is 0>
					<cfset rec_stat=listappend(rec_stat,'MEDIA_LICENSE_ID #MEDIA_LICENSE_ID# is invalid',";")>
				</cfif>
			</cfif>
			<cfhttp url="#media_uri#" charset="utf-8" timeout=5 method="head" />
			<cfif left(cfhttp.statuscode,3) is not "200">
				<cfset rec_stat=listappend(rec_stat,'#media_uri# is invalid',";")>
			</cfif>
			<cfif len(preview_uri) gt 0>
				<cfhttp url="#preview_uri#" charset="utf-8" timeout=5 method="head" />
				<cfif left(cfhttp.statuscode,3) is not "200">
					<cfset rec_stat=listappend(rec_stat,'#preview_uri# is invalid',";")>
				</cfif>
			</cfif>
			<cfif not isDefined("veryLargeFiles")><cfset veryLargeFiles=""></cfif>
			<cfif veryLargeFiles NEQ "true">
				<!--- both isimagefile and cfimage run into heap space limits with very large files --->
				<cfif isimagefile("#escapeQuotes(media_uri)#")>
					<cfimage action="info" source="#escapeQuotes(media_uri)#" structname="imgInfo"/>
					<cfquery name="makeHeightLabel" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						insert into cf_temp_media_labels (
							key,
							MEDIA_LABEL,
							ASSIGNED_BY_AGENT_ID,
							LABEL_VALUE
						) values (
							#key#,
							'height',
							#session.myAgentId#,
							'#imgInfo.height#'
						)
					</cfquery>
					<cfquery name="makeWidthLabel" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						insert into cf_temp_media_labels (
							key,
							MEDIA_LABEL,
							ASSIGNED_BY_AGENT_ID,
							LABEL_VALUE
						) values (
							#key#,
							'width',
							#session.myAgentId#,
							'#imgInfo.width#'
						)
					</cfquery>
					<cfhttp url="#media_uri#" method="get" getAsBinary="yes" result="result">
					<cfset md5hash=Hash(result.filecontent,"MD5")>
					<cfquery name="makeMD5hash" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						insert into cf_temp_media_labels (
							key,
							MEDIA_LABEL,
							ASSIGNED_BY_AGENT_ID,
							LABEL_VALUE
						) values (
							#key#,
							'md5hash',
							#session.myAgentId#,
							'#md5Hash#'
						)
					</cfquery>
				</cfif>
			</cfif>
			<cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				update cf_temp_media set status='#rec_stat#' where key=#key#
			</cfquery>
			<cfquery name="bad" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				select * from cf_temp_media where status is not null
			</cfquery>
			<cfif len(bad.key) gt 0>
				Oops! You must fix everything below before proceeding (see STATUS column).
				<cfdump var=#bad#>
			<cfelse>
				Yay! Initial checks on your file passed. Carefully review the tables below, then
				<a href="BulkloadMedia.cfm?action=load"><strong>click here</strong></a> to proceed.
				<br>^^^ that thing. You must click it.
				<br>
				(Note that the table below is "flattened." Media entries are repeated for every Label and Relationship.)
				<cfquery name="media" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					select
						cf_temp_media.key,
						status,
						MEDIA_URI,
						MIME_TYPE,
						MEDIA_TYPE,
						PREVIEW_URI,
						MEDIA_LICENSE_ID,
						MEDIA_RELATIONSHIP,
						RELATED_PRIMARY_KEY,
						MEDIA_LABEL,
						LABEL_VALUE
					from
						cf_temp_media,
						cf_temp_media_labels,
						cf_temp_media_relations
					where
						cf_temp_media.key=cf_temp_media_labels.key (+) and
						cf_temp_media.key=cf_temp_media_relations.key (+)
					group by
						cf_temp_media.key,
						status,
						MEDIA_URI,
						MIME_TYPE,
						MEDIA_TYPE,
						PREVIEW_URI,
						MEDIA_LICENSE_ID,
						MEDIA_RELATIONSHIP,
						RELATED_PRIMARY_KEY,
						MEDIA_LABEL,
						LABEL_VALUE
				</cfquery>
				<cfdump var=#media#>
			</cfif>
		</cfoutput>
	</cfif>
<!------------------------------------------------------->
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
					SELECT count(distinct collection_object_id) ctobj FROM cf_temp_media
					WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cftry>
					<cfset media_updates = 0>
					<cfset media_updates1 = 0>
					<cfif getTempData.recordcount EQ 0>
						<cfthrow message="You have no rows to load in the media bulkloader table (cf_temp_media).  <a href='/tools/BulkloadMedia.cfm'>Start over</a>"><!--- " --->
					</cfif>
					<cfloop query="getTempData">
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
						<cfquery name="makeMedia" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							insert into 
							media (
							media_id,
							media_uri,
							mime_type,
							media_type,
							preview_uri,
							media_license_id,
							mask_media_fg)
							values (
							#media_id#,
							'#escapeQuotes(media_uri)#',
							'#mime_type#',
							'#media_type#',
							'#preview_uri#',
							#medialicenseid#,
							#MASKMEDIA#)
						</cfquery>
						<cfquery name="media_relations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							select
								*
							from
								cf_temp_media_relations
							where
								key=#key#
						</cfquery>
						<cfloop query="media_relations">
							<cfquery name="makeRelation" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
								insert into
								media_relations (
								media_id,
								media_relationship,
								related_primary_key
								) values (
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#MEDIA_ID#">,
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#MEDIA_RELATIONSHIP#">,
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#RELATED_PRIMARY_KEY#">,
								)
							</cfquery>
						</cfloop>
						<cfquery name="medialabels" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							select * from
								cf_temp_media_labels
							where
								key=#key#
						</cfquery>
						<cfloop query="medialabels">
							<cfquery name="makeRelation" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
								insert into 
								media_labels (
								media_id,
								media_label,
								label_value)
								values (
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#MEDIA_ID#">,
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#MEDIA_LABEL#">,
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#LABEL_VALUE#">)
							</cfquery>
						</cfloop>
					</cfloop>
					<cfcatch>
								
					</cfcatch>
				</cftry>
			</cftransaction>
			<!--- cleanup any incomplete work by the same user --->
			<cfquery name="killOld" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				delete from cf_temp_media WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="killOld" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				delete from cf_temp_media_relations WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="killOld" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				delete from cf_temp_media_labels WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			Spiffy, all done.
		</cfoutput>
	</cfif>
</div>
<cfinclude template="/shared/_footer.cfm">
