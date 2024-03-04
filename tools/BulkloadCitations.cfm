<!--- special case handling to dump problem data as csv --->
<cfif isDefined("action") AND action is "dumpProblems">
	<cfquery name="getProblemData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		SELECT institution_acronym,collection_cde,other_id_type,other_id_number,publication_title,publication_id,cited_scientific_name,occurs_page_number,citation_page_uri,type_status,citation_remarks
		FROM cf_temp_citation 
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
<!--- end special case dump of problems --->

<cfset fieldlist = "institution_acronym,collection_cde,other_id_type,other_id_number,publication_title,publication_id,cited_scientific_name,occurs_page_number,citation_page_uri,type_status,citation_remarks">
<cfset fieldTypes ="CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_DECIMAL,CF_SQL_VARCHAR,CF_SQL_DECIMAL,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR">
<cfset requiredfieldlist = "institution_acronym,collection_cde,other_id_type,other_id_number,cited_scientific_name,type_status,publication_id">

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
<cfset pageTitle = "Bulkload Citations">
<cfinclude template="/shared/_header.cfm">
<cfif not isDefined("action") OR len(action) EQ 0><cfset action="nothing"></cfif>
<main class="container-fluid py-3 px-5" id="content">
	<h1 class="h2 mt-2">Bulkload Citations</h1>

	<cfif #action# is "nothing">
		<cfoutput>
			<p>This tool adds attributes to the specimen record. The attribute has to be in the code table prior to uploading this .csv. It ignores rows that are exactly the same. Additional columns will be ignored.</p>
				
			<p>The attributes and attribute values must appear as they do on the <a href="https://mczbase.mcz.harvard.edu/vocabularies/ControlledVocabulary.cfm?" class="font-weight-bold">controlled vocabularies</a> lists for <a href="/vocabularies/ControlledVocabulary.cfm?table=CTATTRIBUTE_TYPE">ATTRIBUTE_TYPE</a> and for some attributes the controlled vocabularies are listed in <a href="/vocabularies/ControlledVocabulary.cfm?table=CTATTRIBUTE_CODE_TABLES">ATTRIBUTE_CODE_TABLES</a>. </p>
		
			<p>Upload a comma-delimited text file (csv). Include column headings, spelled exactly as below.</p>
			<p>Use "catalog number" as the value of other_id_type to match on catalog number.</p>
			<span class="btn btn-xs btn-info" onclick="document.getElementById('template').style.display='block';">View template</span>
			<div id="template" style="margin: 1rem 0;display:none;">
				<label for="templatearea" class="data-entry-label mb-1">
					Copy this header line and save it as a .csv file (<a href="/tools/BulkloadAttributes.cfm?action=getCSVHeader">download</a>)
				</label>
				<textarea rows="2" cols="90" id="templatearea" class="w-100 data-entry-textarea">#fieldlist#</textarea>
			</div>
			<p>Columns in <span class="text-danger">red</span> are required; others are optional:</p>
			<ul>
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
			<form name="atts" method="post" enctype="multipart/form-data" action="/tools/BulkloadCitations.cfm">
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
		<h2 class="h3">First step: Reading data from CSV file.</h2>
		<!--- Set some constants to identify error cases in cfcatch block --->
				<cfset NO_COLUMN_ERR = "One or more required fields are missing in the header line of the csv file.">
		<cfset DUP_COLUMN_ERR = "One or more columns are duplicated in the header line of the csv file.">
		<cfset COLUMN_ERR = "Error inserting data">
		<cfset NO_HEADER_ERR = "No header line found, csv file appears to be empty.">
		
		<cftry>
		<!--- Parse the CSV file using Apache Commons CSV library included with coldfusion so that columns with comma delimeters will be separated properly --->
				<cfset fileProxy = CreateObject("java","java.io.File") >
				<cfobject type="Java" name="csvFormat" class="org.apache.commons.csv.CSVFormat" >
				<cfobject type="Java" name="csvParser" class="org.apache.commons.csv.CSVParser" >
				<cfobject type="Java" name="csvRecord" class="org.apache.commons.csv.CSVRecord" >			
				<cfobject type="java" class="java.io.FileReader" name="fileReader">	
				<cfobject type="Java" name="javaCharset" class="java.nio.charset.Charset" >
				<cfobject type="Java" name="standardCharsets" class="java.nio.charset.StandardCharsets" >
				<cfset filePath = fileProxy.init(JavaCast("string",#FiletoUpload#)) >
				<cfset tempFileInputStream = CreateObject("java","java.io.FileInputStream").Init(#filePath#) >
				<!--- Create a FileReader object to provide a reader for the CSV file --->
				<cfset fileReader = CreateObject("java","java.io.FileReader").Init(#filePath#) >
				<!--- we can not use the withHeader() method from coldfusion, as it is overloaded, and with no parameters provides coldfusion no means to pick the correct method --->
				<!--- Select format of csv file based on format variable from user --->
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
							<!--- if not available, iso-8859-1 will substitute, except for 0x80 to 0x9F --->
							<!--- the following characters won't be handled correctly if the source is windows-1252:  €  Š  š  Ž  ž  Œ  œ  Ÿ --->
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
					DELETE FROM cf_temp_attributes 
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

				<div class="col-12 my-4">
					<h3 class="h4">Found #size# columns in header of csv file.</h3>
					<h3 class="h4">There are #ListLen(fieldList)# columns expected in the header. (of these #ListLen(requiredFieldList)# are required)</h3>
				</div>
					
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
				<!--- Loop through list of fields, mark each field as fields present in input or not, throw exception if required fields are missing --->
				<ul class="">
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
								<strong class="text-success">Present in CSV</strong>
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
						<!--- likely a problem parsing the first line into column headers --->
						<!--- to get here, upload a csv file with the correct headers as MYSQL format --->
						<cfset errorMessage = "You may have specified the wrong format, only one column header was found. #errorMessage#">
					</cfif>
					<cfthrow message = "#NO_COLUMN_ERR# #errorMessage#">
				</cfif>
				<ul>
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
							<!--- construct insert for row with a line for each entry in fieldlist using cfqueryparam if column header is in fieldlist, otherwise using null --->
							<cfquery name="insert" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="insert_result">
								insert into cf_temp_citation
									(#fieldlist#,username)
								values (
									<cfset separator = "">
									<cfloop from="1" to ="#ArrayLen(fieldArray)#" index="col">
										<cfif arrayFindNoCase(colNameArray,fieldArray[col]) GT 0>
											<cfset fieldPos=arrayFind(colNameArray,fieldArray[col])>
											<cfset val=trim(colValArray[fieldPos])>
											<cfset val=rereplace(val,"^'+",'')>
											<cfset val=rereplace(val,"'+$",'')>
											<cfif val EQ ""> 
												#separator#NULL
											<cfelse>
												#separator#<cfqueryparam cfsqltype="#typeArray[fieldPos]#" value="#val#">
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
					<h3 class="h3">Found characters where the encoding is probably important in the input data.</h3>
					<div>
						Showing #foundHighCount# examples.  If these do not appear as the correct characters, the file likely has a different encoding from the one you selected and
						you probably want to <a href="/tools/BulkloadCitatons.cfm">reload this file</a> selecting a different encoding.  If these appear as expected, then 
						you selected the correct encoding and can continue to validate or load.
					</div>
					<ul class="py-1" style="font-size: 1.2rem;">
						#foundHighAscii#
						#foundMultiByte#
					</ul>
				</cfif>
				<h3 class="h3">
					Successfully read #loadedRows# records from the CSV file.  Next <a href="/tools/BulkloadCitations.cfm?action=validate">click to validate</a>.
				</h3>
			<cfcatch>
				<h3 class="h3">
					Failed to read the CSV file.  Fix the errors in the file and <a href="/tools/BulkloadCitations.cfm">reload</a>
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
						<h3 class="h3">Found characters with unexpected encoding in the header row.  This is probably the cause of your error.</h3>
						<div>
							Showing #foundHighCount# examples.  Did you select utf-16 or unicode for the encoding for a file that does not have multibyte encoding?
						</div>
						<ul class="py-1" style="font-size: 1.2rem;">
							#foundHighAscii#
							#foundMultiByte#
						</ul>
					</cfif>
				</cfif>
				<cfif Find("#NO_COLUMN_ERR#",cfcatch.message) GT 0>
					<ul class="py-1" style="font-size: 1.2rem;">
						<li>#cfcatch.message#</li>
					</ul>
				<cfelseif Find("#COLUMN_ERR#",cfcatch.message) GT 0>
					<ul class="py-1" style="font-size: 1.2rem;">
						<li>#cfcatch.message#</li>
					</ul>
				<cfelse>
					<cfdump var="#cfcatch#">
				</cfif>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfif>
<!------------------------------------------------------->

	<cfif #action# is "validate">
		<h2 class="h3">Second step: Data Validation</h2>
		<cfoutput>
			<cfquery name="getTempTableTypes" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT 
					other_id_type, cited_scientific_name, publication_title, publication_id, key
				FROM 
					cf_temp_citation
				WHERE 
					username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfloop query="getTempTableTypes">
				<!--- For each row, set the target collection_object_id --->
				<cfif getTempTableTypes.other_id_type eq 'catalog number'>
					<!--- either based on catalog_number --->
					<cfquery name="getCID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						UPDATE
							cf_temp_citation
						SET
							collection_object_id = (
								select collection_object_id 
								from cataloged_item 
								where cat_num = cf_temp_citation.other_id_number 
								and collection_cde = cf_temp_citation.collection_cde
							),
							status = null
						WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
							and key = <cfqueryparam cfsqltype="CF_SQL_decimal" value="#getTempTableTypes.key#"> 
					</cfquery>
				<cfelse>
					<!--- or on specified other identifier --->
					<cfquery name="getCID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						UPDATE
							cf_temp_citation
						SET
							collection_object_id= (
								select cataloged_item.collection_object_id from cataloged_item,coll_obj_other_id_num 
								where coll_obj_other_id_num.other_id_type = cf_temp_citation.other_id_type 
								and cataloged_item.collection_cde = cf_temp_citation.collection_cde 
								and display_value= cf_temp_citation.other_id_number
								and cataloged_item.collection_object_id = coll_obj_other_id_num.COLLECTION_OBJECT_ID
							),
							status = null
						WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
							and key = <cfqueryparam cfsqltype="CF_SQL_decimal" value="#getTempTableTypes.key#"> 
					</cfquery>
				</cfif>
				<cfif len(publication_title) gt 0 and len(publication_id) eq 0>
					<cfquery name="getPNID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						UPDATE
							cf_temp_citation
						SET
							publication_id = (
								select publication_id 
								from publication 
								where cf_temp_citation.publication_title = publication.publication_title 
							)
						WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						and key = <cfqueryparam cfsqltype="CF_SQL_decimal" value="#getTempTableTypes.key#"> 
					</cfquery>
				</cfif>
				<cfif len(publication_ID) gt 0 and len(publication_title) eq 0>
					<cfquery name="getPTID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						UPDATE
							cf_temp_citation
						SET
							publication_title = (
								select publication_title 
								from publication 
								where cf_temp_citation.publication_id = publication.publication_id 
							)
						WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						and key = <cfqueryparam cfsqltype="CF_SQL_decimal" value="#getTempTableTypes.key#"> 
					</cfquery>
				</cfif>
				<cfquery name="getCTNID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					UPDATE
						cf_temp_citation
					SET
						cited_taxon_name_id = (
							select taxon_name_id 
							from taxonomy 
							where scientific_name = cf_temp_citation.cited_scientific_name 
						),
						status = null
					WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
					and key = <cfqueryparam cfsqltype="CF_SQL_decimal" value="#getTempTableTypes.key#"> 
				</cfquery>
			</cfloop>
			<!--- obtain the information needed to QC each row --->
			<cfquery name="getTempTableQC" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT 
					key, collection_cde, cited_scientific_name, cited_taxon_name_id, publication_id
				FROM 
					cf_temp_citation
				WHERE 
					username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfloop query="getTempTableQC">
				<!--- for each row, evaluate the attribute against expectations and provide an error message --->
				<cfquery name="FlagSciNameProblems" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="citationProblems_result">
					UPDATE cf_temp_citation
					SET
						status = concat(nvl2(status, status || '; ', ''),'Invalid cited_scientific_name: "' || cited_scientific_name||'"')
					WHERE 
						cited_scientific_name IS NOT NULL
						AND cited_scientific_name NOT IN (
							SELECT scientific_name 
							FROM taxonomy
							WHERE scientific_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempTableQC.cited_scientific_name#">
						)
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						AND key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableQC.key#">
				</cfquery>
			</cfloop>
			<!--- qc checks separate from getting ID numbers, includes presence of values in required columns --->
			<cfquery name="flagNotMatchedTypeStatus" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE cf_temp_citation
				SET 
					status = concat(nvl2(status, status || '; ', ''),'Unknown type_status: "' || type_status ||'"&mdash;not on list')
				WHERE type_status is not null 
					AND type_status not in (select type_status from ctcitation_type_status)
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="flagNoPublication" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE cf_temp_citation
				SET 
					status = concat(nvl2(status, status || '; ', ''),' The publication_title or publication_id fields are missing entries')
				WHERE publication_id IS NULL and publication_title IS NULL
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="flagNoPublication" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE cf_temp_citation
				SET 
					status = concat(nvl2(status, status || '; ', ''),' The publication_title entered does not match an existing title')
				WHERE publication_title IS NOT NULL and publication_ID IS NULL
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="flagMczAcronym" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE cf_temp_citation
				SET 
					status = concat(nvl2(status, status || '; ', ''),'INSTIUTION_ACRONYM is not "MCZ" (check case)')
				WHERE institution_acronym <> 'MCZ'
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="flagNotMatchedOther_ID_Type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE cf_temp_citation
				SET 
					status = concat(nvl2(status, status || '; ', ''), 'Unknown other_id_type: "' || other_id_type ||'"&mdash;not on list')
				WHERE other_id_type is not null 
					AND other_id_type <> 'catalog number'
					AND other_id_type not in (select other_id_type from ctcoll_other_id_type)
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="FlagCdeProblems" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="citationProblems_result">
				UPDATE cf_temp_citation
				SET
					status = concat(nvl2(status, status || '; ', ''),'Invalid collection_cde: "' || collection_cde ||'"')
				WHERE 
					collection_cde IS NOT NULL
					AND collection_cde NOT IN (
						SELECT collection_cde 
						FROM ctcollection_cde 
						WHERE collection_cde = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempTableQC.collection_cde#">
					)
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
					AND key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableQC.key#">
			</cfquery>
			<cfquery name="flagNoCollectionObject" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE cf_temp_citation
				SET 
					status = concat(nvl2(status, status || '; ', ''),' There is no match to a cataloged item on [' || other_id_type || ']=[' || other_id_number || '] in collection "' || collection_cde ||'"')
				WHERE collection_object_id IS NULL
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<!---Missing data in required fields--->
			<cfloop list="#requiredfieldlist#" index="requiredField">
				<cfquery name="checkRequired" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					UPDATE cf_temp_citation
					SET 
						status = concat(nvl2(status, status || '; ', ''),'#requiredField# is missing')
					WHERE #requiredField# is null
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
			</cfloop>
			<!---Go through all the data and report the status--->
			<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT institution_acronym,collection_cde,other_id_type,other_id_number,publication_title,publication_id,cited_scientific_name,occurs_page_number,citation_page_uri,type_status,citation_remarks,collection_object_id,cited_taxon_name_id,status
				FROM cf_temp_citation
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="pf" dbtype="query">
				SELECT count(*) c 
				FROM data 
				WHERE status is not null
			</cfquery>
			<cfif pf.c gt 0>
				<h2>
					There is a problem with #pf.c# of #data.recordcount# row(s). See the STATUS column. (<a href="/tools/BulkloadCitations.cfm?action=dumpProblems">download</a>).
				</h2>
				<h3>
					Fix the problems in the data and <a href="/tools/BulkloadCitations.cfm">start again</a>.
				</h3>
			<cfelse>
				<h2>
					Validation checks passed. Look over the table below and <a href="/tools/BulkloadCitations.cfm?action=load">click to continue</a> if it all looks good.
				</h2>
			</cfif>
			<table class='sortable table table-responsive w-100'>
				<thead class="thead-light">
					<tr>
						<th>STATUS&nbsp;OF&nbsp;CITATION&nbsp;BULKLOAD</th>
						<th>INSTITUTION_ACRONYM</th>
						<th>COLLECTION_CDE</th>
						<th>OTHER_ID_TYPE</th>
						<th>OTHER_ID_NUMBER</th>
						<th>PUBLICATION_TITLE</th>
						<th>PUBLICATION_ID</th>
						<th>CITED_SCIENTIFIC_NAME</th>
						<th>OCCURS_PAGE_NUMBER</th>
						<th>CITATION_PAGE_URI</th>
						<th>TYPE_STATUS</th>
						<th>CITATION_REMARKS</th>
					</tr>
				<tbody>
					<cfloop query="data">
						<tr>
							<td><strong>#STATUS#</strong></td>
							<td>#data.INSTITUTION_ACRONYM#</td>
							<td>#data.COLLECTION_CDE#</td>
							<td>#data.OTHER_ID_TYPE#</td>
							<td>#data.OTHER_ID_NUMBER#</td>
							<td>#data.PUBLICATION_TITLE#</td>
							<td>#data.PUBLICATION_ID#</td>
							<td>#data.CITED_SCIENTIFIC_NAME#</td>
							<td>#data.OCCURS_PAGE_NUMBER#</td>
							<td>#data.CITATION_PAGE_URI#</td>
							<td>#data.TYPE_STATUS#</td>
							<td>#data.CITATION_REMARKS#</td>
						</tr>
					</cfloop>
				</tbody>
			</table>
		</cfoutput>
	</cfif>
	<!-------------------------------------------------------------------------------------------->
	<cfif action is "load">
		<h2 class="h3">Third step: Apply changes.</h2>
		<cfoutput>
			<cfset problem_key = "">
			<cftransaction>
				<cfquery name="getTempData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT * FROM cf_temp_citation
					WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cfquery name="getCounts" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT count(distinct collection_object_id) ctobj FROM cf_temp_citation
					WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
			<cftry>
				<cfset citation_updates = 0>
				<cfset citation_updatesX = 0>
				<cfif getTempData.recordcount EQ 0>
					<cfthrow message="You have no rows to load in the citations bulkloader table (cf_temp_citations).  <a href='/tools/BulkloadCitations.cfm'>Start over</a>">
				</cfif>
				<cfloop query="getTempData">
					<cfset problem_key = getTempData.key>
					<cfquery name="updateCitations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="updateCitations_result">
						INSERT into citation (
							PUBLICATION_ID,
							COLLECTION_OBJECT_ID,
							CITED_TAXON_NAME_ID,
							CIT_CURRENT_FG,
							OCCURS_PAGE_NUMBER,
							TYPE_STATUS,
							CITATION_REMARKS,
							CITATION_PAGE_URI
						) values (
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#publication_id#">,
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#collection_object_id#">,
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#cited_taxon_name_id#">,
							1,
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#occurs_page_number#">,
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#type_status#">,
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#citation_remarks#">,
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#citation_page_uri#">
						)
					</cfquery>
					<cfquery name="updateCitationsX" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="updateCitationsX_result">
						select collection_object_id,publication_id,cited_taxon_name_id 
						from citation 
						where collection_object_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.collection_object_id#">
						group by collection_object_id,publication_id,cited_taxon_name_id
						having count(*) > 1
					</cfquery>
					<cfset citation_updates = citation_updates + updateCitations_result.recordcount>
					<cfif updateCitationsX_result.recordcount gt 0>
						<cftransaction action = "ROLLBACK">
					<cfelse>
						<cftransaction action="COMMIT">
					</cfif>
				</cfloop>
				<p>Number of citations to update: #citation_updates# (on #getCounts.ctobj# cataloged items)</p>
					<cfif getTempData.recordcount eq citation_updates and updateCitationsX_result.recordcount eq 0>
						<h2 class="h3 text-success">Success - loaded</h2>
					</cfif>
					<cfif updateCitationsX_result.recordcount gt 0>
						<h2 class="h3 text-danger">Not loaded - these have already been loaded</h2>
					</cfif>
				<cfcatch>
					<h2 class="h3">There was a problem updating citations.</h2>
					<cfquery name="getProblemData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						SELECT institution_acronym, collection_cde, other_id_type, other_id_number, publication_title, publication_id, cited_scientific_name, occurs_page_number,citation_page_uri, type_status, citation_remarks
						FROM cf_temp_citation 
						WHERE status is not null
							AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
					</cfquery>
					<cfif getProblemData.recordcount eq 0>
						<h2 class="h3 text-danger">Not loaded - these have already been loaded</h2>
					</cfif>
						
					<cfif getProblemData.recordcount gt 0>
						<h3 class="text-danger">Problematic Rows (<a href="/tools/BulkloadCitations.cfm?action=dumpProblems">download</a>)</h3>
						<table class='sortable table table-responsive table-striped d-lg-table'>
							<thead>
								<tr>
									<th>status</th>
									<th>institution_acronym</th>
									<th>collection_cde</th>
									<th>other_id_type</th>
									<th>other_id_number</th>
									<th>publication_title</th>
									<th>publication_id</th>
									<th>cited_scientific_name</th>
									<th>occurs_page_number</th>
									<th>citation_page_uri</th>
									<th>type_status</th>
									<th>citation_remarks</th>
								</tr>
							</thead>
							<tbody>
								<cfloop query="getProblemData">
									<tr>
										<td>#getProblemData.status#</td>
										<td>#getProblemData.institution_acronym#</td>
										<td>#getProblemData.collection_cde#</td>
										<td>#getProblemData.other_id_type#</td>
										<td>#getProblemData.other_id_number#</td>
										<td>#getProblemData.publication_title#</td>
										<td>#getProblemData.publication_id#</td>
										<td>#getProblemData.cited_scientific_name#</td>
										<td>#getProblemData.occurs_page_number#</td>
										<td>#getProblemData.citation_page_uri#</td>
										<td>#getProblemData.type_status#</td>
										<td>#getProblemData.citation_remarks#</td>
									</tr>
								</cfloop>
							</tbody>
						</table>
					</cfif>
				</cfcatch>
			</cftry>
			<cfset problem_key = "">
			<cftransaction>
				<cftry>
					<cftransaction action="commit">
				<cfcatch>
					<cftransaction action="rollback">
					<cfquery name="getProblemData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						SELECT institution_acronym, collection_cde, other_id_type, other_id_number, publication_title, publication_id, cited_scientific_name, occurs_page_number,citation_page_uri, type_status, citation_remarks
						FROM cf_temp_citation 
						WHERE username= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
					</cfquery>
					<h3 class="text-danger">Error updating row (#citation_updates + 1#): 
						<cfif len(cfcatch.detail)gt 0>
							<span class="font-weight-normal border-bottom border-danger">
								<cfif cfcatch.detail contains "Invalid PUBLICATION_TITLE">
									Invalid PUBLICATION_TITLE for this collection; check controlled vocabulary (Help menu)
								<cfelseif cfcatch.detail contains "collection_cde">
									COLLECTION_CDE does not match abbreviated collection (e.g., Ent, Herp, Ich, IP, IZ, Mala, Mamm, Orn, SC, VP)
								<cfelseif cfcatch.detail contains "institution_acronym">
									INSTITUTION_ACRONYM does not match MCZ (all caps)
								<cfelseif cfcatch.detail contains "other_id_type">
									OTHER_ID_TYPE is not valid
								<cfelseif cfcatch.detail contains "PUBLICATION_ID">
									PUBLICATION_ID does not match a publication ID
								<cfelseif cfcatch.detail contains "OTHER_ID_NUMBER">
									Problem with OTHER_ID_NUMBER, check to see the correct other_id_type was entered
								<cfelseif cfcatch.detail contains "CITED_SCIENTIFIC_NAME">
									Invalid or missing CITED_SCIENTIFIC_NAME
								<cfelseif cfcatch.detail contains "OCCURS_PAGE_NUMBER">
									Invalid with OCCURS_PAGE_NUMBER
								<cfelseif cfcatch.detail contains "TYPE_STATUS">
									Problem with TYPE_STATUS
								<cfelseif cfcatch.detail contains "CITATION_PAGE_URI">
									Problem with CITATION_PAGE_URI (#cfcatch.detail#)
								<cfelseif cfcatch.detail contains "COLLECTION_OBJECT_ID">
									Problem with OTHER_ID_TYPE or OTHER_ID_NUMBER (#cfcatch.detail#)
								<cfelseif cfcatch.detail contains "CITATION_REMARKS">
									Problem with CITATION_REMARKS (#cfcatch.detail#)
								<cfelseif cfcatch.detail contains "no data">
									No data or the wrong data (#cfcatch.detail#)
								<cfelseif cfcatch.detail contains "NULL">
									Missing Data (#cfcatch.detail#)
								<cfelse>
									 provide the raw error message if it isn't readily interpretable 
								 	#cfcatch.detail#
								</cfif>
							</span>
						</cfif>
					</h3>
					<table class='sortable table table-responsive table-striped d-lg-table'>
						<thead>
							<tr>
								<th>publication_title</th>
								<th>publication_id</th>
								<th>cited_scientific_name</th>
								<th>occurs_page_number</th>
								<th>citation_page_uri</th>
								<th>type_status</th>
								<th>citation_remarks</th>
								<th>institution_acronym</th>
								<th>collection_cde</th>
								<th>other_id_type</th>
								<th>other_id_number</th>
								<th>status</th>
							</tr> 
						</thead>
						<tbody>
							<cfloop query="getProblemData">
								<tr>
									<td>#getProblemData.publication_title#</td>
									<td>#getProblemData.publication_id#</td>
									<td>#getProblemData.cited_scientific_name#</td>
									<td>#getProblemData.occurs_page_number#</td>
									<td>#getProblemData.citation_page_uri#</td>
									<td>#getProblemData.type_status#</td>
									<td>#getProblemData.citation_remarks#</td>
									<td>#getProblemData.institution_acronym#</td>
									<td>#getProblemData.collection_cde#</td>
									<td>#getProblemData.other_id_type#</td>
									<td>#getProblemData.other_id_number#</td>
									<td>#getProblemData.status#</td>
								</tr> 
							</cfloop>
						</tbody>
					</table>
					<cfrethrow>
				</cfcatch>
				</cftry>
			</cftransaction>
			<cfquery name="clearTempTable" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="clearTempTable_result">
				DELETE FROM cf_temp_citation
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
		</cfoutput>
	</cfif>
</main>
<cfinclude template="/shared/_footer.cfm">