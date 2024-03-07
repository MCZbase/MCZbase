<!--- tools/bulkloadAgents.cfm add agents to specimens in bulk.

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
	<cfquery name="getProblemData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		SELECT highergeography,speclocality,locality_id,dec_lat,dec_long,,max_error_distance,max_error_units,lat_long_remarks,determined_by_agent,georefmethod,orig_lat_long_units,datum,determined_date,lat_long_ref_source,extent,gpsaccuracy,verificationstatus,spatialfit 
		FROM cf_temp_georef 
		WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
	</cfquery>
	<cfinclude template="/shared/component/functions.cfc">
	<cfinclude template="/shared/functionLib.cfm">
	<cfset csv = queryToCSV(getProblemData)>
	<cfheader name="Content-Type" value="text/csv">
	<cfoutput>#csv#</cfoutput>
	<cfabort>
</cfif>

<cfset fieldlist = "highergeography,speclocality,locality_id,dec_lat,dec_long,max_error_distance,max_error_units,lat_long_remarks,determined_by_agent,georefmethod,orig_lat_long_units,datum,determined_date,lat_long_ref_source,extent,gpsaccuracy,verificationstatus,spatialfit">
<cfset fieldTypes ="CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_DECIMAL,CF_SQL_DECIMAL,CF_SQL_DECIMAL,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_DATE,CF_SQL_VARCHAR,CF_SQL_DECIMAL,CF_SQL_DECIMAL,CF_SQL_VARCHAR,CF_SQL_DECIMAL">
<cfset requiredfieldlist = "DETERMINED_BY_AGENT,DEC_LAT,DEC_LONG,MAX_ERROR_DISTANCE,MAX_ERROR_UNITS,LAT_LONG_REMARKS,EXTENT,GPSACCURACY,SPATIALFIT,NEAREST_NAMED_PLACE">
		
		
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
<cfif not isDefined("action") OR len(action) EQ 0><cfset action="nothing"></cfif>
<main class="container-fluid py-3 px-5" id="content">
	<h1 class="h2 mt-2">Bulkload Geography</h1>
	<cfif #action# is "nothing">
		<cfoutput>
			<h3 class="wikilink">Bulkload Geography</h3>
			<p>HigherGeography, SpecLocality, and locality_id must all match MCZbase data or this form will not work. There are still plenty of ways to hook a georeference to the wrong socket&mdash;make sure you know what you're doing before you try to use this form.  If in doubt, give your filled-out template to Collections Operations to load.</p>
			<span class="btn btn-xs btn-info" onclick="document.getElementById('template').style.display='block';">View template</span>
			<div id="template" class="my-1 mx-0" style="display:none;">
				<label for="templatearea" class="data-entry-label mb-1">
					Copy this header line and save it as a .csv file (<a href="/tools/BulkloadGeoref.cfm?action=getCSVHeader">download</a>)
				</label>
				<textarea rows="2" cols="90" id="templatearea" class="w-100 data-entry-textarea">#fieldlist#</textarea>
			</div>
			<h2 class="mt-4 h4">Columns in <span class="text-danger">red</span> are required; others are optional:</h2>
			<ul class="mb-4 small90">
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
			<form name="atts" method="post" enctype="multipart/form-data" action="/tools/BulkloadGeoref.cfm">
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
			<!--- Set some constants to identify error cases in cfcatch block --->
			<cfset NO_COLUMN_ERR = "One or more required fields are missing in the header line of the csv file.">
			<cfset DUP_COLUMN_ERR = "One or more columns are duplicated in the header line of the csv file.">
			<cfset COLUMN_ERR = "Error inserting data">
			<cfset NO_HEADER_ERR = "No header line found, csv file appears to be empty.">
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
					<cfquery name="clearTempTable" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="clearTempTable_result">
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
					<div class="col-12 my-4 px-xl-4">
						<h3 class="h4">Found #size# columns in header of csv file.</h3>
						<h3 class="h4">There are #ListLen(fieldList)# columns expected in the header (of these #ListLen(requiredFieldList)# are required).</h3>
						<!--- check for required fields in header line (performng check in two different ways, Case 1, Case 2) --->
						<!--- Loop through list of fields throw exception if required fields are missing --->
						<cfset errorMessage = "">
						<cfloop list="#fieldList#" item="aField">
							<cfif ListContainsNoCase(requiredFieldList,aField)>
								<!--- Case 1. Check by splitting assembled list of foundHeaders --->
								<cfif NOT ListContainsNoCase(foundHeaders,aField)>
									<cfset errorMessage = "#errorMessage# #aField# is missing.">
								</cfif>
							</cfif>
						</cfloop>
						<cfif len(errorMessage) GT 0>
							<cfthrow message = "#NO_COLUMN_ERR# #errorMessage#">
						</cfif>
						<cfset errorMessage = "">
						<!---Loop through field list, mark each as present in input or not, throw exception if required fields are missing--->
						<ul class="mb-4 small90">
							<cfloop list="#fieldlist#" index="field" delimiters=",">
								<cfset hint="">
								<cfif listContains(requiredfieldlist,field,",")>
									<cfset class="text-danger">
									<cfset hint="aria-label='required'">
								<cfelse>
									<cfset class="text-dark">
								</cfif>
								<li>
									<span class="#class#" #hint#>#field#</span>
									<cfif arrayFindNoCase(colNameArray,field) GT 0>
										<span class="text-success font-weight-bold">Present in CSV</span>
									<cfelse>
										<!--- Case 2. Check by identifying field in required field list --->
										<cfif ListContainsNoCase(requiredFieldList,field)>
											<strong class="text-dark">Required Column Not Found</strong>
											<cfset errorMessage = "#errorMessage# #field# is missing.">
										</cfif>
									</cfif>
								</li>
							</cfloop>
						</ul>
						<cfif len(errorMessage) GT 0>
							<cfif size EQ 1>
								<!--- Likely a problem parsing the first line into column headers --->
								<!--- To get here, upload a csv file with the correct headers as MYSQL format --->
								<cfset errorMessage = "You may have specified the wrong format, only one column header was found. #errorMessage#">
							</cfif>
							<cfthrow message = "#NO_COLUMN_ERR# #errorMessage#">
						</cfif>
						<ul class="">
							<!--- Identify additional columns that will be ignored --->
							<cfloop list="#foundHeaders#" item="aField">
								<cfif NOT ListContainsNoCase(fieldList,aField)>
									<li>Found additional column header [<strong>#aField#</strong>] in the CSV that is not in the list of expected headers.</1i>
								</cfif>
							</cfloop>
							<!--- Identify duplicate columns and fail if found --->
							<cfif NOT ListLen(ListRemoveDuplicates(foundHeaders)) EQ ListLen(foundHeaders)>
								<li>At least one column header occurs more than once.</1i>
								<cfloop list="#foundHeaders#" item="aField">
									<cfif listValueCount(foundHeaders,aField) GT 1>
										<li><strong>#aField#</strong> is duplicated as the header for #listValueCount(foundHeaders,aField)# columns.</1i>
									</cfif>
								</cfloop>
								<cfthrow message = "#DUP_COLUMN_ERR#">
							</cfif>
						</ul>
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
								<cfquery name="insert" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="insert_result">
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
							<ul class="h4">#foundHighAscii# #foundMultiByte#</ul>

						</cfif>
					</div>
					<h3 class="h4">
						Successfully read #loadedRows# records from the CSV file. Next <a href="/tools/BulkloadGeoref.cfm?action=validate">click to validate</a>.
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
		<h2 class="h4">Second step: Data Validation</h2>
		<cfoutput>
			<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select * from cf_temp_georef
			</cfquery>
			<cfquery name="ctGEOREFMETHOD" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select GEOREFMETHOD from ctGEOREFMETHOD
			</cfquery>
			<cfquery name="CTLAT_LONG_UNITS" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select ORIG_LAT_LONG_UNITS from CTLAT_LONG_UNITS
			</cfquery>
			<cfquery name="CTDATUM" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select DATUM from CTDATUM
			</cfquery>
			<cfquery name="CTVERIFICATIONSTATUS" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select VERIFICATIONSTATUS from CTVERIFICATIONSTATUS
			</cfquery>
			<cfquery name="CTLAT_LONG_ERROR_UNITS" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select LAT_LONG_ERROR_UNITS from CTLAT_LONG_ERROR_UNITS
			</cfquery>
			<cfloop query="d">
				<cfset ts="">
				<cfset sql="select spec_locality,higher_geog,locality.locality_id from locality,geog_auth_rec where
					locality.geog_auth_rec_id=geog_auth_rec.geog_auth_rec_id and
					locality.locality_id=#Locality_ID# and
					trim(geog_auth_rec.higher_geog)='#trim(HigherGeography)#' and
					 trim(locality.spec_locality)='#trim(SpecLocality)#'">
				<cfquery name="m" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					#preservesinglequotes(sql)#
				</cfquery>
				<cfif len(m.locality_id) is 0>
					<cfset ts=listappend(ts,'no Locality_ID:SpecLocality:HigherGeography match',";")>
					<cfquery name="fail" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select
							spec_locality,higher_geog
						from locality,geog_auth_rec where
							locality.geog_auth_rec_id=geog_auth_rec.geog_auth_rec_id and
							locality.locality_id=#Locality_ID#
					</cfquery>
					<cfif trim(SpecLocality) is not fail.spec_locality>
						<label>Locality Fail: ID=#locality_id#</label>
						<cfset yl=replace(trim(SpecLocality)," ","{space}","all")>
						<cfset al=replace(fail.spec_locality," ","{space}","all")>
						<table border>
							<tr>
								<td>yours:</td>
								<td>#yl#</td>
							</tr>
							<tr>
								<td>arctos:</td>
								<td>#al#</td>
							</tr>
						</table>
					</cfif>
					<cfif trim(HigherGeography) is not fail.higher_geog>
						<label>Geography Fail: ID=#locality_id#</label>
						<cfset yg=replace(trim(HigherGeography)," ","{space}","all")>
						<cfset ag=replace(fail.higher_geog," ","{space}","all")>
						<table border>
							<tr>
								<td>yours:</td>
								<td>#yg#</td>
							</tr>
							<tr>
								<td>arctos:</td>
								<td>#ag#</td>
							</tr>
						</table>
					</cfif>
				</cfif>
				<cfquery name="a" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select agent_id from agent_name where agent_name='#DETERMINED_BY_AGENT#'
				</cfquery>
				<cfif a.recordcount is 1>
					<cfquery name="au" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						update cf_temp_georef set DETERMINED_BY_AGENT_ID=#a.agent_id# where key=#key#
					</cfquery>
				<cfelse>
					<cfset ts=listappend(ts,'bad agent match',";")>
				</cfif>
				<cfif not listfind(valuelist(ctGEOREFMETHOD.GEOREFMETHOD),GEOREFMETHOD)>
					<cfset ts=listappend(ts,'bad GEOREFMETHOD',";")>
				</cfif>
				<cfif not listfind(valuelist(CTLAT_LONG_UNITS.ORIG_LAT_LONG_UNITS),ORIG_LAT_LONG_UNITS)>
					<cfset ts=listappend(ts,'bad ORIG_LAT_LONG_UNITS',";")>
				</cfif>
				<cfif not listfind(valuelist(CTDATUM.DATUM),DATUM)>
					<cfset ts=listappend(ts,'bad DATUM',";")>
				</cfif>
				<cfif not listfind(valuelist(CTVERIFICATIONSTATUS.VERIFICATIONSTATUS),VERIFICATIONSTATUS)>
					<cfset ts=listappend(ts,'bad VERIFICATIONSTATUS',";")>
				</cfif>
				<cfif len(MAX_ERROR_DISTANCE) GT 0 >
					<cfif not listfind(valuelist(CTLAT_LONG_ERROR_UNITS.LAT_LONG_ERROR_UNITS),MAX_ERROR_UNITS)>
						<cfset ts=listappend(ts,'bad MAX_ERROR_UNITS',";")>
					</cfif>
				</cfif>
				<cfquery name="l" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select count(*) c from lat_long where
					lat_long.locality_id=#Locality_ID#
				</cfquery>
				<cfif l.c neq 0>
					<cfset ts=listappend(ts,'georeference exists.',";")>
				</cfif>
				<cfif len(ts) gt 0>
					<cfquery name="au" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						update cf_temp_georef set status='#ts#' where key=#key#
					</cfquery>
				<cfelse>
					<cfquery name="au" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						update cf_temp_georef set status='spiffy' where key=#key#
					</cfquery>
				</cfif>
			</cfloop>
			<cfquery name="dp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select count(*) c from cf_temp_georef where status != 'spiffy'
			</cfquery>
			<cfif dp.c is 0>
				Looks like we made it. Take a look at everything below, then
				<a href="BulkloadGeoref.cfm?action=load">click to load</a>
			<cfelse>
				fail. Something's busted.
			</cfif>
			<cfquery name="df" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select * from cf_temp_georef
			</cfquery>
			<cfset internalPath="#Application.webDirectory#/temp/">
			<cfset externalPath="#Application.ServerRootUrl#/temp/">
			<cfset dlFile = "BulkloadGeoref.kml">
			<cfset variables.fileName="#internalPath##dlFile#">
			<cfset variables.encoding="UTF-8">
			<cfscript>
				variables.joFileWriter = createObject('Component', '/component.FileWriter').init(variables.fileName, variables.encoding, 32768);
				kml='<?xml version="1.0" encoding="UTF-8"?>' & chr(10) &
					'<kml xmlns="http://earth.google.com/kml/2.2">' & chr(10) &
					chr(9) & '<Document>' & chr(10) &
					chr(9) & chr(9) & '<name>Localities</name>' & chr(10) &
					chr(9) & chr(9) & '<open>1</open>' & chr(10) &
					chr(9) & chr(9) & '<Style id="green-star">' & chr(10) &
					chr(9) & chr(9) & chr(9) & '<IconStyle>' & chr(10) &
					chr(9) & chr(9) & chr(9) & chr(9) & '<Icon>' & chr(10) &
					chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & '<href>http://maps.google.com/mapfiles/kml/paddle/grn-stars.png</href>' & chr(10) &
					chr(9) & chr(9) & chr(9) & chr(9) & '</Icon>' & chr(10) &
					chr(9) & chr(9) & chr(9) & '</IconStyle>' & chr(10) &
					chr(9) & chr(9) & '</Style>';
				variables.joFileWriter.writeLine(kml);
			</cfscript>
			<cfloop query="df">
				<cfset cdata='<![CDATA[Datum: #datum#<br/>Error: #max_error_distance# #max_error_units#<br/><p><a href="#Application.ServerRootUrl#/localities/Locality.cfm?locality_id=#locality_id#">Edit Locality</a></p>]]>'>
				<cfscript>
					kml='<Placemark>'  & chr(10) &
						chr(9) & '<name>#HigherGeography#: #replace(SpecLocality,"&","&amp;","all")#</name>' & chr(10) &
						chr(9) & '<visibility>1</visibility>' & chr(10) &
						chr(9) & '<description>' & chr(10) &
						chr(9) & chr(9) & '#cdata#' & chr(10) &
						chr(9) & '</description>' & chr(10) &
						chr(9) & '<Point>' & chr(10) &
						chr(9) & chr(9) & '<coordinates>#dec_long#,#dec_lat#</coordinates>' & chr(10) &
						chr(9) & '</Point>' & chr(10) &
						chr(9) & '<styleUrl>##green-star</styleUrl>' & chr(10) &
						'</Placemark>';
					variables.joFileWriter.writeLine(kml);
				</cfscript>
			</cfloop>
			<cfscript>
		kml='</Document></kml>';
		variables.joFileWriter.writeLine(kml);
		variables.joFileWriter.close();
	</cfscript>
		<p>
		<a href="http://maps.google.com/maps?q=#externalPath##dlFile#?r=#randRange(1,10000)#">map it</a>
		</p>
Data:
<cfdump var=#df#>
</cfoutput>
</cfif>
	<!------------------------------------------------------->
	<cfif #action# is "load">
		<h2 class="h3">Third step: Apply changes.</h2>
		<cfoutput>
			<cfset problem_key = "">
			<cftransaction>
				<cfquery name="getTempData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT * FROM cf_temp_georef
					WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cfquery name="getCounts" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT count(distinct collection_object_id) ctobj FROM cf_temp_georef
					WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
			<cftry>
					<cfset georef_updates = 0>
					<cfset georef_updates1 = 0>
					<cfif getTempData.recordcount EQ 0>
						<cfthrow message="You have no rows to load in the geography bulkloader table (cf_temp_georef).  <a href='/tools/BulkloadGeoref.cfm'>Start over</a>"><!--- " --->
					</cfif>
					<cfloop query="getTempData">
						<cfset problem_key = getTempData.key>
						<cfquery name="updateGeoref" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="updateGeoref_result">
							INSERT into lat_long (
								LAT_LONG_ID,
								LOCALITY_ID,
								DEC_LAT,
								DEC_LONG,
								DATUM,
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
								SPATIALFIT
							)VALUES(
							sq_lat_long_id.nextval,
							<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#LOCALITY_ID#">,
							<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#Dec_Lat#" scale="10">,
							<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#Dec_Long#" scale="10">,
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#DATUM#">,
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ORIG_LAT_LONG_UNITS#">,
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#DETERMINED_BY_AGENT_ID#">,
							<cfqueryparam cfsqltype="CF_SQL_TIMESTAMP" value="#dateformat(DETERMINED_DATE,'yyyy-mm-dd')#">,
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#LAT_LONG_REF_SOURCE#">,
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#LAT_LONG_REMARKS#">,
							<cfif len(MAX_ERROR_DISTANCE) gt 0>
								<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#MAX_ERROR_DISTANCE#">,
							<cfelse>
								NULL,
							</cfif>
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#MAX_ERROR_UNITS#">,
							1,
							<cfif len(EXTENT) gt 0>
								<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#EXTENT#" scale="5">,
							<cfelse>
								NULL,
							</cfif>
							<cfif len(GPSACCURACY) gt 0>
								<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#GPSACCURACY#" scale="3">,
							<cfelse>
								NULL,
							</cfif>
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#GEOREFMETHOD#">,
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#VERIFICATIONSTATUS#">,
						<cfif len(SPATIALFIT) gt 0>
							<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#SPATIALFIT#" scale="3">
						<cfelse>
							NULL
						</cfif>
							)
						</cfquery>
						<cfquery name="updateGeoref1" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="updateGeoref1_result">
							select LAT_LONG_ID,
								LOCALITY_ID,
								DEC_LAT,
								DEC_LONG,
								DATUM,
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
								SPATIALFIT
							where collection_object_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.collection_object_id#">
							group by LAT_LONG_ID,
								LOCALITY_ID,
								DEC_LAT,
								DEC_LONG,
								DATUM,
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
								SPATIALFIT
							having count(*) > 1
						</cfquery>
						<cfset georef_updates = georef_updates + updateGeoref_result.recordcount>
						<cfif updateGeoref1_result.recordcount gt 0>
							<cftransaction action = "ROLLBACK">
						<cfelse>
							<cftransaction action="COMMIT">
						</cfif>
					</cfloop>
					<p>Number of geographies to update: #georef_updates# (on #getCounts.ctobj# cataloged items)</p>
					<cfif getTempData.recordcount eq georef_updates and updateGeoref1_result.recordcount eq 0>
						<h2 class="text-success">Success - loaded</h2>
					</cfif>
					<cfif updateGeoref1_result.recordcount gt 0>
						<h2 class="text-danger">Not loaded - these have already been loaded</h2>
					</cfif>
				<cfcatch>
					<cftransaction action="ROLLBACK">
					<h2 class="h3">There was a problem updating the georeferences.</h2>
					<cfquery name="getProblemData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						SELECT verificationstatus,institution_acronym,collection_cde,other_id_type,other_id_number,attribute,attribute_value, attribute_units,attribute_date,attribute_meth,determiner,remarks
						FROM cf_temp_georef
						WHERE key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#problem_key#">
					</cfquery>
					<cfif getProblemData.recordcount GT 0>
 						<h2 class="h3">Errors are displayed one row at a time.</h2>
						<h3>
							Error loading row (<span class="text-danger">#georef_updates + 1#</span>) from the CSV: 
							<cfif len(cfcatch.detail) gt 0>
								<span class="font-weight-normal border-bottom border-danger">
									<cfif cfcatch.detail contains "lat_long">
										Invalid LAT_LONG
									<cfelseif cfcatch.detail contains "lat_long_id">
										LAT_LONG_ID does not exist
									<cfelseif cfcatch.detail contains "locality_id">
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
									<cfelseif cfcatch.detail contains "gpsaccuracy">
										Invalid GPSACCURANCY
									<cfelseif cfcatch.detail contains "georefmethod">
										Invalid GEOREFMETHOD
									<cfelseif cfcatch.detail contains "verificationstatus">
										Invalid VERIFICATIONSTATUS
									<cfelseif cfcatch.detail contains "spatialfit">
										Invalid SPATIALFIT
									<cfelseif cfcatch.detail contains "no data">
										No data or the wrong data (#cfcatch.detail#)
									<cfelse>
										<!--- provide the raw error message if it isn't readily interpretable --->
										#cfcatch.detail#
									</cfif>
								</span>
							</cfif>
						</h3>
						<table class='mx-3 px-0 sortable table-danger table table-responsive table-striped d-lg-table mt-3'>
							<thead>
								<tr>
									<th>COUNT</th><th>LAT_LONG</th><th>LAT_LONG_ID</th><th>LOCALITY_ID</th><th>DEC_LAT</th><th>DEC_LONG</th><th>DATUM</th><th>ORIG_LAT_LONG_UNITS</th><th>DETERMINED_BY_AGENT_ID</th><th>DETERMINED_DATE</th><th>LAT_LONG_REF_SOURCE</th><th>LAT_LONG_REMARKS</th><th>MAX_ERROR_DISTANCE</th><th>MAX_ERROR_UNITS</th><th>ACCEPTED_LAT_LONG_FG</th><th>EXTENT</th><th>GPSACCURACY</th><th>GEOREFMETHOD</th><th>VERIFICATIONSTATUS</th><th>SPATIALFIT</th>
								</tr> 
							</thead>
							<tbody>
								<cfset i=1>
								<cfloop query="getProblemData">
									<tr>
										<td>#i#</td>
										<td>#getProblemData.lat_long# </td>
										<td>#getProblemData.lat_long_id# </td>
										<td>#getProblemData.locality_id#</td>
										<td>#getProblemData.dec_lat#</td>
										<td>#getProblemData.dec_long# </td>
										<td>#getProblemData.datum# </td>
										<td>#getProblemData.orig_lat_long_units#</td>
										<td>#getProblemData.determined_by_agent_id#</td>
										<td>#getProblemData.determined_date#</td>
										<td>#getProblemData.lat_long_ref_source#</td>
										<td>#getProblemData.lat_long_remarks#</td>
										<td>#getProblemData.max_error_distance#</td>
										<td>#getProblemData.max_error_units#</td>
										<td>#getProblemData.accepted_lat_long_fg#</td>
										<td>#getProblemData.extent#</td>
										<td>#getProblemData.gpsaccuracy# </td>
										<td>#getProblemData.georefmethod# </td>
										<td>#getProblemData.verificationstatus# </td>
										<td>#getProblemData.spatialfit#</td>
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
			
			<cfquery name="clearTempTable" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="clearTempTable_result">
				DELETE FROM cf_temp_georef 
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
		</cfoutput>
	</cfif>
</main>
<cfinclude template="/shared/_footer.cfm">
