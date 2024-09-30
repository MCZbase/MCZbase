<!--- tools/bulkloadAgents.cfm add agents to specimens in bulk.

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
		SELECT highergeography,speclocality,locality_id,dec_lat,dec_long,max_error_distance,max_error_units,lat_long_remarks,determined_by_agent,georefmethod,orig_lat_long_units,datum,determined_date,lat_long_ref_source,extent,extent_units,lat_long_for_NNP_FG,gpsaccuracy,verificationstatus,verified_by,verified_by_agent_id,spatialfit,nearest_named_place,coordinate_precision,accepted_lat_long_fg,determined_by_agent_id 
		FROM cf_temp_georef 
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

<cfset fieldlist = "HIGHERGEOGRAPHY,SPECLOCALITY,LOCALITY_ID,DEC_LAT,DEC_LONG,MAX_ERROR_DISTANCE,MAX_ERROR_UNITS,LAT_LONG_REMARKS,DETERMINED_BY_AGENT,GEOREFMETHOD,ORIG_LAT_LONG_UNITS,DATUM,DETERMINED_DATE,LAT_LONG_REF_SOURCE,EXTENT,EXTENT_UNITS,LAT_LONG_FOR_NNP_FG,GPSACCURACY,VERIFICATIONSTATUS,VERIFIED_BY,VERIFIED_BY_AGENT_ID,SPATIALFIT,NEAREST_NAMED_PLACE,COORDINATE_PRECISION,ACCEPTED_LAT_LONG_FG,DETERMINED_BY_AGENT_ID">
	
<cfset fieldTypes ="CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_DECIMAL,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_DECIMAL,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_DATE,CF_SQL_VARCHAR,CF_SQL_DECIMAL,CF_SQL_VARCHAR,CF_SQL_DECIMAL,CF_SQL_DECIMAL,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_DECIMAL,CF_SQL_VARCHAR,CF_SQL_DECIMAL,CF_SQL_VARCHAR,CF_SQL_DECIMAL">
	
<cfset requiredfieldlist = "HIGHERGEOGRAPHY,SPECLOCALITY,LOCALITY_ID,DEC_LAT,DEC_LONG,DETERMINED_BY_AGENT,GEOREFMETHOD,ORIG_LAT_LONG_UNITS,DATUM,DETERMINED_DATE,LAT_LONG_REF_SOURCE,VERIFICATIONSTATUS,COORDINATE_PRECISION">

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
<cfset pageTitle = "Bulkload Georeferences">
<cfinclude template="/shared/_header.cfm">
<cfinclude template="/tools/component/csv.cfc" runOnce="true"><!--- for common csv testing functions --->
<cfif not isDefined("action") OR len(action) EQ 0><cfset action="nothing"></cfif>
<main class="container-fluid py-3 px-5" id="content">
	<h1 class="h2 mt-2">Bulkload Geography</h1>
	
	
	<cfif #action# is "nothing">
		<cfoutput>
			<p>Load a new georeference to a locality record. HigherGeography, SpecLocality, and locality_id must all match MCZbase data or this form will not work. There are still plenty of ways to hook a georeference to the wrong socket&mdash;make sure you know what you are doing before you try to use this form.  If in doubt, give your filled-out template to Collections Operations to load.</p>
			<span class="btn btn-xs btn-info" onclick="document.getElementById('template').style.display='block';">View template</span>
			<div id="template" class="my-1 mx-0" style="display:none;">
				<label for="templatearea" class="data-entry-label mb-1">
					Copy this header line and save it as a .csv file (<a href="/tools/BulkloadGeoref.cfm?action=getCSVHeader" class="font-weight-lessbold">download</a>)
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
							and table_name = 'CF_TEMP_GEOREF'
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
			<form name="atts" method="post" enctype="multipart/form-data" action="/tools/BulkloadGeoref.cfm">
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
		</cfoutput>
	</cfif>
	<!------------------------------------------------------->
	<cfif #action# is "getFile">
		<cfoutput>
			<h2 class="h4">First step: Reading data from CSV file.</h2>
			<!--- Set some constants to identify error cases in cfcatch block --->
			<cfset NO_COLUMN_ERR = "One or more required fields are missing in the header line of the csv file.">
			<cfset DUP_COLUMN_ERR = "One or more columns are duplicated in the header line of the csv file.">
			<cfset COLUMN_ERR = "Error inserting data">
			<cfset NO_HEADER_ERR = "No header line found, csv file appears to be empty.">
			<cfset TABLE_NAME = "CF_TEMP_GEOREF">
				<cftry>
				<!---Parse the CSV file using Apache Commons CSV library. Include with ColdFusion so columns with comma delimiters will be separated properly.--->
					<cfset fileProxy = CreateObject("java","java.io.File") >
					<cfobject type="Java" name="csvFormat" class="org.apache.commons.csv.CSVFormat">
					<cfobject type="Java" name="csvParser" class="org.apache.commons.csv.CSVParser">
					<cfobject type="Java" name="csvRecord" class="org.apache.commons.csv.CSVRecord">
					<cfobject type="java" class="java.io.FileReader" name="fileReader">	
					<cfobject type="Java" name="javaCharset" class="java.nio.charset.Charset">
					<cfobject type="Java" name="standardCharsets" class="java.nio.charset.StandardCharsets">
					<cfset filePath = fileProxy.init(JavaCast("string",#FiletoUpload#)) >
					<cfset tempFileInputStream = CreateObject("java","java.io.FileInputStream").Init(#filePath#)>
					<!--- Create a FileReader object to provide a reader for the CSV file --->
					<cfset fileReader = CreateObject("java","java.io.FileReader").Init(#filePath#)>
					<!---We cannot use the withHeader() method from coldfusion, as it is overloaded. With no parameters ColdFusion has no means to pick the correct method.--->
					<!---Select format of csv file based on format variable from user.--->
					<cfif not isDefined("format")><cfset format="DEFAULT"></cfif>
					<cfswitch expression="#format#">
						<cfcase value="DEFAULT">
							<cfset csvFormat = CSVFormat.DEFAULT>
						</cfcase>
						<cfcase value="TDF">
							<cfset csvFormat = CSVFormat.TDF>
						</cfcase>
						<cfcase value="RFC4180">
							<cfset csvFormat = CSVFormat.RFC4180>
						</cfcase>
						<cfcase value="EXCEL">
							<cfset csvFormat = CSVFormat.EXCEL>
						</cfcase>
						<cfcase value="ORACLE">
							<cfset csvFormat = CSVFormat.ORACLE>
						</cfcase>
						<cfcase value="MYSQL">
							<cfset csvFormat = CSVFormat.MYSQL>
						</cfcase>
						<cfdefaultcase>
							<cfset csvFormat = CSVFormat.DEFAULT>
						</cfdefaultcase>
					</cfswitch>
					<!--- Create a CSVParser using the FileReader and CSVFormat--->
					<cfset csvParser = CSVParser.parse(fileReader, csvFormat)>
					<!--- Select charset based on characterSet variable from user --->
					<cfswitch expression="#characterSet#">
						<cfcase value="utf-8">
							<cfset javaSelectedCharset = standardCharsets.UTF_8 >
						</cfcase>
						<cfcase value="iso-8859-1">
							<cfset javaSelectedCharset = standardCharsets.ISO_8859_1 >
						</cfcase>
						<cfcase value="windows-1250">
							<cfset javaSelectedCharset = javaCharset.forName(JavaCast("string","windows-1250")) >
						</cfcase>
						<cfcase value="windows-1251">
							<cfset javaSelectedCharset = javaCharset.forName(JavaCast("string","windows-1251")) >
						</cfcase>
						<cfcase value="windows-1252">
							<cfif javaCharset.isSupported(JavaCast("string","windows-1252"))>
								<cfset javaSelectedCharset = javaCharset.forName(JavaCast("string","windows-1252")) >
							<cfelse>
							<!--- If not available, iso-8859-1 will substitute, except for 0x80 to 0x9F --->
							<!--- These characters won't be handled correctly if the source is windows-1252:  €  Š  š  Ž  ž  Œ  œ  Ÿ --->
								<cfset javaSelectedCharset = standardCharsets.ISO_8859_1 >
							</cfif>
						</cfcase>
						<cfcase value="x-MacCentralEurope">
							<cfset javaSelectedCharset = javaCharset.forName(JavaCast("string","x-MacCentralEurope")) >
						</cfcase>
						<cfcase value="MacRoman">
							<cfset javaSelectedCharset = javaCharset.forName(JavaCast("string","x-MacRoman")) >
						</cfcase>
						<cfcase value="utf-16">
							<cfset javaSelectedCharset = standardCharsets.UTF_16 >
						</cfcase>
						<cfcase value="utf-32">
							<cfset javaSelectedCharset = javaCharset.forName(JavaCast("string","utf-32")) >
						</cfcase>
						<cfdefaultcase>
							<cfset javaSelectedCharset = standardCharsets.UTF_8 >
						</cfdefaultcase>
					</cfswitch>
					<cfset records = CSVParser.parse(#tempFileInputStream#,#javaSelectedCharset#,#csvFormat#)>
					<!--- cleanup any incomplete work by the same user --->
					<cfquery name="clearTempTable" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="clearTempTable_result">
						DELETE FROM cf_temp_georef
						WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
					</cfquery>
					<!--- obtain an iterator to loops through the rows/records in the csv --->
					<cfset iterator = records.iterator()>
					<!---Obtain the first line of the file as the header line, we can not use the withHeader() method to do this in coldfusion --->
					<cfif iterator.hasNext()>
						<cfset headers = iterator.next()>
					<cfelse>
						<cfthrow message="#NO_HEADER_ERR# No first line found.">
					</cfif>
					<!---Get the number of column headers--->
					<cfset size = headers.size()>
					<cfif size EQ 0>
						<cfthrow message="#NO_HEADER_ERR# First line appears empty.">
					</cfif>
					<cfset separator = "">
					<cfset foundHeaders = "">
					<cfloop index="i" from="0" to="#headers.size() - 1#">
						<cfset foundHeaders = "#foundHeaders##separator##headers.get(JavaCast("int",i))#" >
						<cfset separator = ",">
					</cfloop>
					<cfset colNameArray = listToArray(ucase(foundHeaders))><!--- the list of columns/fields found in the input file --->
					<cfset fieldArray = listToArray(ucase(fieldlist))><!--- the full list of fields --->
					<cfset typeArray = listToArray(fieldTypes)><!--- the types for the full list of fields --->
					<div class="col-12 my-3 px-0">
						<h3>Found #size# columns in header of csv file.</h3> 
						There are #ListLen(fieldList)# columns expected in the header (of these #ListLen(requiredFieldList)# are required).
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
							<!---Construct insert for row with a line for each entry in fieldlist using cfqueryparam if column header is in fieldlist, otherwise using null.--->
								<cfquery name="insert" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="insert_result">
									insert into cf_temp_georef
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
							<h3 class="h4">Found characters where the encoding is probably important in the input data.</h3>
							<div>
								<p>Showing #foundHighCount# examples.  If these do not appear as the correct characters, the file likely has a different encoding from the one you selected and
								you probably want to <a href="/tools/BulkloadGeoref.cfm">reload this file</a> selecting a different encoding. If these appear as expected, then you selected the correct encoding and can continue to validate or load.</p>
							</div>
							<ul class="pb-1 h4 list-unstyled">#foundHighAscii# #foundMultiByte#</ul>

						</cfif>
					</div>
					<h3 class="h4">
						Successfully read #loadedRows# records from the CSV file. Next <a href="/tools/BulkloadGeoref.cfm?action=validate" class="btn-link font-weight-lessbold">click to validate</a>.
					</h3>
				<cfcatch>
					<h3 class="h4">
						Failed to read the CSV file.  Fix the errors in the file and <a href="/tools/BulkloadGeoref.cfm">reload</a>.
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
									<cfset foundHighAscii = "#foundHighAscii# <li class='text-danger font-weight-bold m-3'>#thisBit#</li>"><!--- " --->
									<cfset foundHighCount = foundHighCount + 1>
								</cfif>
							<cfelseif REFind("[\xc0-\xdf][\x80-\xbf]",thisBit) GT 0>
								<!--- multibyte --->
								<cfif foundHighCount LT 6>
									<cfset foundMultiByte = "#foundMultiByte# <li class='text-danger font-weight-bold m-3'>#thisBit#</li>"><!--- " --->
									<cfset foundHighCount = foundHighCount + 1>
								</cfif>
							</cfif>
						</cfloop>
						<cfif isDefined("foundHighCount") AND foundHighCount GT 0>
							<h3 class="h4">Found characters with unexpected encoding in the header row. This is probably the cause of your error.</h3>
							<div>
								<p>Showing #foundHighCount# examples. Did you select utf-16 or unicode for the encoding for a file that does not have multibyte encoding?</p>
							</div>
							<ul class="py-1 h4">
								#foundHighAscii# #foundMultiByte#
							</ul>
						</cfif>
					</cfif>
					<cfif Find("#NO_COLUMN_ERR#",cfcatch.message) GT 0>
							#cfcatch.message#
					<cfelseif Find("#COLUMN_ERR#",cfcatch.message) GT 0>
							#cfcatch.message#
					<cfelse>
						<cfdump var="#cfcatch#">
					</cfif>
				</cfcatch>
				</cftry>
			</cfoutput>
		</cfif>
	<!------------------------------------------------------->
	<cfif #action# is "validate">
		<cfoutput>
			<h2 class="h4">Second step: Data Validation</h2>
			<!---Get Data from the temp table and the codetables with relevant information--->
			<cfset key = ''>
			<cfquery name="getTempData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				select * 
				From CF_TEMP_GEOREF
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfloop query="getTempData">
				<!---Check max_error_units--->
				<cfquery name="warningMessageErrorUnits" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE
						cf_temp_georef
					SET
						status = concat(nvl2(status, status || '; ', ''),'MAX_ERROR_UNITS are invalid - see <a href="/vocabularies/ControlledVocabulary.cfm?table=CTLAT_LONG_ERROR_UNITS">controlled vocabulary</a>')
					WHERE 
						MAX_ERROR_UNITS not in (select LAT_LONG_ERROR_UNITS from CTLAT_LONG_ERROR_UNITS) AND
						username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						and key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.key#"> 
				</cfquery>
				<!---Check lat_long_ref_source--->
				<cfquery name="warningMessageRefSource" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE
						cf_temp_georef
					SET
						status = concat(nvl2(status, status || '; ', ''),'Ref_Source is invalid - see <a href="/vocabularies/ControlledVocabulary.cfm?table=CTLAT_LONG_REF_SOURCE">controlled vocabulary</a>')
					WHERE 
						LAT_LONG_REF_SOURCE not in (select LAT_LONG_REF_SOURCE from CTLAT_LONG_REF_SOURCE) AND
						username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						and key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.key#"> 
				</cfquery>
				<!---Check ORIG_LAT_LONG_UNITS--->
				<cfquery name="warningMessageRefSource" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE
						cf_temp_georef
					SET
						status = concat(nvl2(status, status || '; ', ''),'Original Lat Long Units are invalid - see <a href="/vocabularies/ControlledVocabulary.cfm?table=CTLAT_LONG_UNITS">controlled vocabulary</a>')
					WHERE 
						orig_lat_long_units not in (select ORIG_LAT_LONG_UNITS from CTLAT_LONG_UNITS) AND
						username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						and key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.key#"> 
				</cfquery>
				<!---Check VERIFICATIONSTATUS--->
				<cfquery name="warningMessageVerification" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE
						cf_temp_georef
					SET
						status = concat(nvl2(status, status || '; ', ''),'verificationstatus is invalid - see <a href="/vocabularies/ControlledVocabulary.cfm?table=CTVERIFICATIONSTATUS">controlled vocabulary</a>')
					WHERE 
						VERIFICATIONSTATUS not in (select VERIFICATIONSTATUS from CTVERIFICATIONSTATUS) AND
						username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						and key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.key#"> 
				</cfquery>
				<!---Check LOCALITY_ID--->
				<cfquery name="warningMessageLocality" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE
						cf_temp_georef
					SET
						status = concat(nvl2(status, status || '; ', ''),'Locality ID does not match spec_locality')
					WHERE 
						locality_id not in (
							select locality_id from locality where spec_locality = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.speclocality#">
							and )
							AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						AND key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.key#"> 
				</cfquery>
				<!---Check DETERMINED BY AGENT_ID--->
				<cfquery name="getAgentID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE cf_temp_georef
					SET determined_by_agent_id = (
						select agent_id from preferred_agent_name 
						where agent_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.determined_by_agent#">
						)
					WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						and key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.key#"> 
				</cfquery>
				<!---Check VERIFIED BY AGENT_ID--->
				<cfquery name="getVerifiedByAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					update cf_temp_georef
					set verified_by_agent_id = (select AGENT_ID from agent_name where agent_name = <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value="#getTempData.verified_by#"> AND agent_name_type = 'preferred')
					WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
					and key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.key#"> 
				</cfquery>
				<!---Check DETERMINED_DATE--->
				<cfquery name="getDeterminedDate" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					update cf_temp_georef
					set determined_date =  TO_DATE(<cfqueryparam cfsqltype="CF_SQL_DATE" value="#getTempData.DETERMINED_DATE#">, 'YYYY-MM-DD')
					WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
					and key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.key#"> 
				</cfquery>
			</cfloop>
			<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT *
				FROM cf_temp_georef
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="dataCount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT count(*) c 
				FROM cf_temp_georef
				WHERE status is not null
			</cfquery>
			<cfif dataCount.c gt 0>
				<h3 class="mt-3">
					There is a problem with #dataCount.c# of #data.recordcount# row(s). See the STATUS column. (<a href="/tools/BulkloadGeoref.cfm?action=dumpProblems" class="btn-link font-weight-lessbold">download</a>). Fix the problems in the data and <a href="/tools/BulkloadGeoref.cfm" class="text-danger">start again</a>.
				</h3>
			<cfelse>
				<h3 class="mt-3">
					<span class="text-success">Validation checks passed</span>. Look over the table below and <a href="/tools/BulkloadGeoref.cfm?action=load" class="btn-link font-weight-lessbold">click to continue</a> if it all looks good or <a href="/tools/BulkloadGeoref.cfm" class="text-danger">start again</a>.
				</h3>
			</cfif>
			<table class='sortable px-0 mx-0 table small table-responsive table-striped w-100'>
				<thead class="thead-light">
					<tr>
						<th>STATUS</th>
						<th>DETERMINED_BY_AGENT_ID</th>
						<th>HIGHERGEOGRAPHY</th>
						<th>SPECLOCALITY</th>
						<th>LOCALITY_ID</th>
						<th>DEC_LAT</th>
						<th>DEC_LONG</th>
						<th>MAX_ERROR_DISTANCE</th>
						<th>MAX_ERROR_UNITS</th>
						<th>LAT_LONG_REMARKS</th>
						<th>DETERMINED_BY_AGENT</th>
						<th>GEOREFMETHOD</th>
						<th>ORIG_LAT_LONG_UNITS</th>
						<th>DATUM</th>
						<th>DETERMINED_DATE</th>
						<th>LAT_LONG_REF_SOURCE</th>
						<th>EXTENT</th>
						<th>GPSACCURACY</th>
						<th>VERIFICATIONSTATUS</th>
						<th>SPATIALFIT</th>
						<th>NEAREST_NAMED_PLACE</th>
						<th>USERNAME</th>
						<th>VERIFIED_BY</th>
						<th>VERIFIED_BY_AGENT_ID</th>
						<th>ACCEPTED_LAT_LONG_FG</th>
						<th>COORDINATE_PRECISION</th>
						<th>EXTENT_UNITS</th>
						<th>LAT_LONG_FOR_NNP_FG</th>
					</tr>
				</thead>
				<tbody>
					<cfloop query="data">
						<tr>
							<td><cfif len(data.status) eq 0>Cleared to load<cfelse><strong>#data.status#</strong></cfif></td>
							<td>#data.DETERMINED_BY_AGENT_ID#</td>
							<td>#data.HIGHERGEOGRAPHY#</td>
							<td>#data.SPECLOCALITY#</td>
							<td>#data.LOCALITY_ID#</td>
							<td>#data.DEC_LAT#</td>
							<td>#data.DEC_LONG#</td>
							<td>#data.MAX_ERROR_DISTANCE#</td>
							<td>#data.MAX_ERROR_UNITS#</td>
							<td>#data.LAT_LONG_REMARKS#</td>
							<td>#data.DETERMINED_BY_AGENT#</td>
							<td>#data.GEOREFMETHOD#</td>
							<td>#data.ORIG_LAT_LONG_UNITS#</td>
							<td>#data.DATUM#</td>
							<td>#data.DETERMINED_DATE#</td>
							<td>#data.LAT_LONG_REF_SOURCE#</td>
							<td>#data.EXTENT#</td>
							<td>#data.GPSACCURACY#</td>
							<td>#data.VERIFICATIONSTATUS#</td>
							<td>#data.SPATIALFIT#</td>
							<td>#data.NEAREST_NAMED_PLACE#</td>
							<td>#data.USERNAME#</td>
							<td>#data.VERIFIED_BY#</td>
							<td>#data.VERIFIED_BY_AGENT_ID#</td>
							<td>#data.ACCEPTED_LAT_LONG_FG#</td>
							<td>#data.COORDINATE_PRECISION#</td>
							<td>#data.EXTENT_UNITS#</td>
							<td>#data.LAT_LONG_FOR_NNP_FG#</td>
						</tr>
					</cfloop>
				</tbody>
			</table>
		</cfoutput>
	</cfif>
	<!-------------------------------------------------------------------------------------------->

	<cfif #action# is "load">
		<h2 class="h3">Third step: Apply changes.</h2>
		<cfoutput>
			<cfset problem_key = "">
			<cftransaction>
				<cfquery name="getTempData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT *
					FROM cf_temp_georef
					WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cfquery name="getCounts" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT count(distinct locality_id) loc 
					FROM cf_temp_georef
					WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cfset temp_lat = fix(#getTempData.dec_lat)>
				<cfset temp_long = fix(#getTempData.dec_long#)>
				<cfset table_lat = 'select dec_lat from lat_long where locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempData.locality_id">'>
				<cfset table_long = 'select dec_long from lat_long where locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempData.locality_id">'>
				<cfset short_dec_lat = fix(#table_lat#)>
				<cfset short_dec_long = fix(#table_long#)>
				<cfquery name="updateFlag" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT *
					FROM cf_temp_georef, lat_long
					WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
					and short_dec_lat = temp_lat
				</cfquery>
				<cftry>
					<cfset georef_updates = 0>
					<cfif getTempData.recordcount EQ 0>
						<cfthrow message="You have no rows to load in the Georeference bulkloader table (cf_temp_georef). <a href='/tools/BulkloadGeoref.cfm'>Start over</a>">
					</cfif>
					<cfloop query="getTempData">
						<cfset username="#session.username#">
						<cfset problem_key = getTempData.key>
						<cfset lat_long_id = ''>
						
						<cfquery name="makeGeoref" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="insResult">
							INSERT into lat_long (
								lat_long_id,
								LOCALITY_ID,
								DEC_LAT,
								DEC_LONG,
								DATUM,
								COORDINATE_PRECISION,
								ORIG_LAT_LONG_UNITS,
								DETERMINED_BY_AGENT_ID,
								DETERMINED_DATE,
								LAT_LONG_REF_SOURCE,
								LAT_LONG_REMARKS,
								MAX_ERROR_DISTANCE,
								MAX_ERROR_UNITS,
								ACCEPTED_LAT_LONG_FG,
								EXTENT,
								GPSACCURACY,
								GEOREFMETHOD,
								VERIFICATIONSTATUS,
								VERIFIED_BY_AGENT_ID,
								SPATIALFIT,
								NEAREST_NAMED_PLACE,
								EXTENT_UNITS,
								LAT_LONG_FOR_NNP_FG
							)VALUES(
								sq_lat_long_id.nextval,
								<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#LOCALITY_ID#">,
								<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#Dec_Lat#" scale="10">,
								<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#Dec_Long#" scale="10">,
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#DATUM#">,
								<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#COORDINATE_PRECISION#">,
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ORIG_LAT_LONG_UNITS#">,
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#DETERMINED_BY_AGENT_ID#">,
								<cfqueryparam cfsqltype="CF_SQL_DATE" value="#DETERMINED_DATE#">,
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#LAT_LONG_REF_SOURCE#">,
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#LAT_LONG_REMARKS#">,
								<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#MAX_ERROR_DISTANCE#">,
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#MAX_ERROR_UNITS#">,
								1,
								<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#EXTENT#" scale="5">,
								<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#GPSACCURACY#" scale="3">,
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#GEOREFMETHOD#">,
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#VERIFICATIONSTATUS#">,
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#VERIFIED_BY_AGENT_ID#">,
								<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#SPATIALFIT#" scale="3">,
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#NEAREST_NAMED_PLACE#">,
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#EXTENT_UNITS#" scale="5">,
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#LAT_LONG_FOR_NNP_FG#">
							)
						</cfquery>
						<cfset georef_updates = georef_updates + insResult.recordcount>
					</cfloop>
		
					<p class="mt-2">Number of Georeferences added: <b>#georef_updates#</b></p>
					<cfif getTempData.recordcount eq georef_updates and updateGeoref1_result.recordcount eq 0>
						<h3 class="text-success">Success - loaded</h3>
					</cfif>
					<cfif updateGeoref1_result.recordcount gt 0>
						<h3 class="text-danger">Not loaded - these have already been loaded</h3>
					</cfif>
					<cftransaction action="commit">
				<cfcatch>
					<cftransaction action="ROLLBACK">
					<h3>There was a problem adding coordinates to the locality records. </h3>
					<cfquery name="getProblemData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						SELECT *
						FROM cf_temp_georef
						WHERE 
							key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#problem_key#">
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
					</cfquery>
					<cfif getProblemData.recordcount GT 0>
						<h3>
							Fix the issues and <a href="/tools/BulkloadGeoref.cfm">start again</a>. Error loading row (<span class="text-danger">#georef_updates + 1#</span>) from the CSV: 
							<cfif len(cfcatch.detail) gt 0>
								<span class="font-weight-normal border-bottom border-danger">
									<cfif cfcatch.detail contains "locality_id">
										LOCALITY_ID is not valid
									<cfelseif cfcatch.detail contains "dec_lat">
										DEC_LAT is not valid
									<cfelseif cfcatch.detail contains "dec_long">
										DEC_LONG is not valid
									<cfelseif cfcatch.detail contains "datum">
										Problem with DATUM
									<cfelseif cfcatch.detail contains "orig_lat_long_units">
										Invalid ORIG_LAT_LONG_UNITS
									<cfelseif cfcatch.detail contains "determined_by_agent_id">
										Invalid DETERMINED_BY_AGENT_ID
									<cfelseif cfcatch.detail contains "determined_date">
										Invalid DETERMINED_DATE
									<cfelseif cfcatch.detail contains "lat_long_ref_source">
										Invalid LAT_LONG_REF_SOURCE
									<cfelseif cfcatch.detail contains "lat_long_remarks">
										Invalid LAT_LONG_REMARKS
									<cfelseif cfcatch.detail contains "max_error_distance">
										Invalid MAX_ERROR_DISTANCE
									<cfelseif cfcatch.detail contains "max_error_units">
										Invalid MAX_ERROR_UNITS
									<cfelseif cfcatch.detail contains "accepted_lat_long_fg">
										Invalid ACCEPTED_LAT_LONG_FG
									<cfelseif cfcatch.detail contains "extent">
										Invalid EXTENT
									<cfelseif cfcatch.detail contains "extent_units">
										Invalid EXTENT_UNITS
									<cfelseif cfcatch.detail contains "gpsaccuracy">
										Invalid GPSACCURANCY
									<cfelseif cfcatch.detail contains "georefmethod">
										Invalid GEOREFMETHOD
									<cfelseif cfcatch.detail contains "verificationstatus">
										Invalid VERIFICATIONSTATUS
									<cfelseif cfcatch.detail contains "spatialfit">
										Invalid SPATIALFIT
									<cfelseif cfcatch.detail contains "nearest_named_place">
										Invalid NEAREST_NAMED_PLACE
									<cfelseif cfcatch.detail contains "lat_long_for_NNP_FG">
										Invalid lat_long_for_nnp_fg
									<cfelseif cfcatch.detail contains "COORDINATE_PRECISION">
										Invalid coordinate_precision
									<cfelseif cfcatch.detail contains "DETERMINED_BY_AGENT_ID">
										Invalid determined_by_agent_id
									<cfelseif cfcatch.detail contains "VERIFIED_BY_AGENT_ID">
										Invalid VERIFIED_BY_AGENT_ID
									<cfelseif cfcatch.detail contains "data">
										No data or the wrong data (#cfcatch.detail#)
									<cfelse>
										<!--- provide the raw error message if it isn't readily interpretable --->
										What happened? #cfcatch.detail#
									</cfif>
								</span>
							</cfif>
						</h3>
						<table class='mx-0 px-0 sortable table-danger table table-responsive table-striped mt-3'>
							<thead class="thead-light">
								<tr>
									<th>COUNT</th>
									<th>DETERMINED_BY_AGENT_ID</th>
									<th>HIGHERGEOGRAPHY</th>
									<th>SPECLOCALITY</th>
									<th>LOCALITY_ID</th>
									<th>DEC_LAT</th>
									<th>DEC_LONG</th>
									<th>MAX_ERROR_DISTANCE</th>
									<th>MAX_ERROR_UNITS</th>
									<th>LAT_LONG_REMARKS</th>
									<th>DETERMINED_BY_AGENT</th>
									<th>GEOREFMETHOD</th>
									<th>ORIG_LAT_LONG_UNITS</th>
									<th>DATUM</th>
									<th>DETERMINED_DATE</th>
									<th>LAT_LONG_REF_SOURCE</th>
									<th>EXTENT</th>
									<th>GPSACCURACY</th>
									<th>VERIFICATIONSTATUS</th>
									<th>SPATIALFIT</th>
									<th>NEAREST_NAMED_PLACE</th>
									<th>USERNAME</th>
									<th>VERIFIED_BY</th>
									<th>VERIFIED_BY_AGENT_ID</th>
									<th>ACCEPTED_LAT_LONG_FG</th>
									<th>COORDINATE_PRECISION</th>
									<th>EXTENT_UNITS</th>
									<th>LAT_LONG_FOR_NNP_FG</th>
								</tr> 
							</thead>
							<tbody>
								<cfset i=1>
								<cfloop query="getProblemData">
									<tr>										
										<td>#i#</td>
										<td>#getProblemData.DETERMINED_BY_AGENT_ID#</td>
										<td>#getProblemData.HIGHERGEOGRAPHY#</td>
										<td>#getProblemData.SPECLOCALITY#</td>
										<td>#getProblemData.LOCALITY_ID#</td>
										<td>#getProblemData.DEC_LAT#</td>
										<td>#getProblemData.DEC_LONG#</td>
										<td>#getProblemData.MAX_ERROR_DISTANCE#</td>
										<td>#getProblemData.MAX_ERROR_UNITS#</td>
										<td>#getProblemData.LAT_LONG_REMARKS#</td>
										<td>#getProblemData.DETERMINED_BY_AGENT#</td>
										<td>#getProblemData.GEOREFMETHOD#</td>
										<td>#getProblemData.ORIG_LAT_LONG_UNITS#</td>
										<td>#getProblemData.DATUM#</td>
										<td>#getProblemData.DETERMINED_DATE#</td>
										<td>#getProblemData.LAT_LONG_REF_SOURCE#</td>
										<td>#getProblemData.EXTENT#</td>
										<td>#getProblemData.GPSACCURACY#</td>
										<td>#getProblemData.VERIFICATIONSTATUS#</td>
										<td>#getProblemData.SPATIALFIT#</td>
										<td>#getProblemData.NEAREST_NAMED_PLACE#</td>
										<td>#getProblemData.USERNAME#</td>
										<td>#getProblemData.VERIFIED_BY#</td>
										<td>#getProblemData.VERIFIED_BY_AGENT_ID#</td>
										<td>#getProblemData.ACCEPTED_LAT_LONG_FG#</td>
										<td>#getProblemData.COORDINATE_PRECISION#</td>
										<td>#getProblemData.EXTENT_UNITS#</td>
										<td>#getProblemData.LAT_LONG_FOR_NNP_FG#</td>
									</tr>
									<cfset i= i+1>
								</cfloop>
							</tbody>
						</table>
					</cfif>
					<div>#cfcatch.detail# <br>#cfcatch.message#</div>
				</cfcatch>
				</cftry>
			</cftransaction>
			<cfquery name="clearTempTable" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="clearTempTable_result">
				DELETE FROM cf_temp_georef 
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
		</cfoutput>
	</cfif>
</main>

<cfinclude template="/shared/_footer.cfm">
