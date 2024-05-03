<cfif isDefined("action") AND action is "dumpProblems">
	<cfquery name="getProblemData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		SELECT INSTITUTION_ACRONYM,COLLECTION_CDE,OTHER_ID_TYPE,OTHER_ID_VAL,RELATIONSHIP,RELATED_INSTITUTION_ACRONYM,RELATED_COLLECTION_CDE,RELATED_OTHER_ID_TYPE,RELATED_OTHER_ID_VAL,BIOL_INDIV_RELATION_REMARKS
		FROM cf_temp_bl_relations
		WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
	</cfquery>
	<cfinclude template="/shared/component/functions.cfc"><!---need to add to functions.cfc page--->
	<cfset csv = queryToCSV(getProblemData)>
	<cfheader name="Content-Type" value="text/csv">
	<cfoutput>#csv#</cfoutput>
	<cfabort>
</cfif>
<cfset fieldlist="INSTITUTION_ACRONYM,COLLECTION_CDE,OTHER_ID_TYPE,OTHER_ID_VAL,RELATIONSHIP,RELATED_INSTITUTION_ACRONYM,RELATED_COLLECTION_CDE,RELATED_OTHER_ID_TYPE,RELATED_OTHER_ID_VAL,BIOL_INDIV_RELATION_REMARKS">
<cfset fieldTypes="CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR">
<cfset requiredfieldlist="INSTITUTION_ACRONYM,COLLECTION_CDE,OTHER_ID_TYPE,OTHER_ID_VAL,RELATIONSHIP,RELATED_INSTITUTION_ACRONYM,RELATED_COLLECTION_CDE,RELATED_OTHER_ID_TYPE,RELATED_OTHER_ID_VAL,BIOL_INDIV_RELATION_REMARKS">
<!------>
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
<cfset pageTitle = "Bulk Relations">
<cfinclude template="/shared/_header.cfm">
<cfif not isDefined("action") OR len(action) EQ 0>
	<cfset action="nothing">
</cfif>
	
<main class="container py-3" id="content">
	<h1 class="h2 mt-2">Bulkload Relationships</h1>
	<cfif #action# is "nothing">
		<cfoutput>
			<p>Use this form to add relationships between specimens. Specimen records must already exist. This form can be used to create relationships between specimens within the MCZ or between institutions using the catalog number or another identifier.</p>
			<p>Upload a comma-delimited text file (csv). Include column headings, spelled exactly as below. Additional colums will be ignored.</p>
			<span class="btn btn-xs btn-info" onclick="document.getElementById('template').style.display='block';">View template</span>
			<div id="template" style="display:none;margin: 1em 0;">
				<label for="templatearea" class="data-entry-label">
					Copy this header line and save it as a .csv file 
					(<a href="/tools/BulkloadRelations.cfm?action=getCSVHeader">download</a>)
				</label>
				<textarea rows="2" cols="90" id="templatearea" class="w-100 data-entry-textarea">#fieldlist#</textarea>
			</div>
			<h2 class="mt-4 h4">Columns in <span class="text-danger">red</span> are required; others are optional:</h2>
			<ul class="mb-4 small90 font-weight-normal list-group">
				<cfloop list="#fieldlist#" index="field" delimiters=",">
					<cfquery name = "getComments"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#"  result="getComments_result">
						SELECT comments
						FROM sys.all_col_comments
						WHERE 
							owner = 'MCZBASE'
							and table_name = 'CF_TEMP_ATTRIBUTES'
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
					<li class="pb-1 mx-xl-5">
						<span class="#class# font-weight-lessbold" #aria#>#field#: </span> <span class="text-secondary">#comment#</span>
					</li>
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
	<!------------------------------------------------>
	<cfif #action# is "getFile">
		<cfoutput>
		<h2 class="h3">First step: Reading data from CSV file.</h2>
		<!--- Compare the numbers of headers expected against provided in CSV file --->
		<!--- Set some constants to identify error cases in cfcatch block --->
		<cfset NO_COLUMN_ERR = "One or more required fields are missing in the header line of the csv file. Check charset selected if columns match required headers and one column is not found.">
		<cfset DUP_COLUMN_ERR = "One or more columns are duplicated in the header line of the csv file.">
		<cfset COLUMN_ERR = "Error inserting data ">
		<cfset NO_HEADER_ERR = "No header line found, csv file appears to be empty.">
		<cfset table_name = "CF_TEMP_RELATIONS">

		<cftry>
			<cfquery name="clearTempTable" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="clearTempTable_result">
				DELETE FROM cf_temp_relations
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
							insert into cf_temp_relations
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
						you probably want to <strong><a href="/tools/BulkloadRelations.cfm">reload</a></strong> this file selecting a different encoding.  If these appear as expected, then 
							you selected the correct encoding and can continue to validate or load.</p>
					</div>
					<ul class="pb-1 h4 list-unstyled">
						#foundHighAscii# #foundMultiByte#
					</ul>
				</cfif>
				<h3 class="h3">
					<cfif loadedRows EQ 0>
						Loaded no rows from the CSV file.  The file appears to be just a header with no data. Fix file and <a href="/tools/BulkloadRelations.cfm">reload</a>
					<cfelse>
						Successfully read #loadedRows# records from the CSV file.  Next <a href="/tools/BulkloadRelations.cfm?action=validate">click to validate</a>.
					</cfif>
				</h3>
			<cfcatch>
				<h3 class="h4">
					Failed to read the CSV file.  Fix the errors in the file and <a href="/tools/BulkloadRelations.cfm">reload</a>
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
	<cfif #action# is "getFile">
		<h2 class="h3">First step: Reading data from CSV file.</h2>
		<cfoutput>
			<cffile action="READ" file="#FiletoUpload#" variable="fileContent">
			<cfset fileContent=replace(fileContent,"'","''","all")>
			<cfset arrResult = CSVToArray(CSV = fileContent.Trim()) />
		
			<!--- cleanup any incomplete work by the same user --->
			<cfquery name="clearTempTable" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="clearTempTable_result">
				DELETE FROM MCZBASE.cf_temp_bl_relations 
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<!--- check for required fields in header line --->
			<cfset INSTITUTION_ACRONYM_exists = false>
			<cfset COLLECTION_CDE_exists = false>
			<cfset OTHER_ID_TYPE_exists = false>
			<cfset OTHER_ID_VAL_exists = false>
			<cfset RELATIONSHIP_exists = false>
			<cfset RELATED_INSTITUTION_ACRONYM_exists = false>
			<cfset RELATED_COLLECTION_CDE_exists = false>
			<cfset RELATED_OTHER_ID_TYPE_exists = false>
			<cfset RELATED_OTHER_ID_VAL_exists = false>
			<cfset BIOL_INDIV_RELATION_REMARKS_exists = false>
			<cfloop from="1" to ="#ArrayLen(arrResult[1])#" index="col">
				<cfset header = arrResult[1][col]>
				<cfif ucase(header) EQ 'INSTITUTION_ACRONYM'><cfset INSTITUTION_ACRONYM_exists=true></cfif>
				<cfif ucase(header) EQ 'COLLECTION_CDE'><cfset COLLECTION_CDE_exists=true></cfif>
				<cfif ucase(header) EQ 'OTHER_ID_TYPE'><cfset OTHER_ID_TYPE_exists=true></cfif>
				<cfif ucase(header) EQ 'OTHER_ID_VAL'><cfset OTHER_ID_VAL_exists=true></cfif>
				<cfif ucase(header) EQ 'RELATIONSHIP'><cfset RELATIONSHIP_exists=true></cfif>
				<cfif ucase(header) EQ 'RELATED_INSTITUTION_ACRONYM'><cfset RELATED_INSTITUTION_ACRONYM_exists=true></cfif>
				<cfif ucase(header) EQ 'RELATED_COLLECTION_CDE'><cfset RELATED_COLLECTION_CDE_exists=true></cfif>
				<cfif ucase(header) EQ 'RELATED_OTHER_ID_TYPE'><cfset RELATED_OTHER_ID_TYPE_exists=true></cfif>
				<cfif ucase(header) EQ 'RELATED_OTHER_ID_VAL'><cfset RELATED_OTHER_ID_VAL_exists=true></cfif>
				<cfif ucase(header) EQ 'BIOL_INDIV_RELATION_REMARKS'><cfset BIOL_INDIV_RELATION_REMARKS_exists=true></cfif>
			</cfloop>
			<cfif not (INSTITUTION_ACRONYM_exists AND COLLECTION_CDE_exists AND OTHER_ID_TYPE_exists AND OTHER_ID_VAL_exists AND RELATIONSHIP_exists AND RELATED_INSTITUTION_ACRONYM_exists AND RELATED_COLLECTION_CDE_exists AND RELATED_OTHER_ID_TYPE_exists AND RELATED_OTHER_ID_VAL_exists AND BIOL_INDIV_RELATION_REMARKS_exists)>
				<cfset message = "One or more required fields are missing in the header line of the csv file.">
				<cfif not INSTITUTION_ACRONYM_exists><cfset message = "#message# INSTITUTION_ACRONYM is missing."></cfif>
				<cfif not COLLECTION_CDE_exists><cfset message = "#message# COLLECTION_CDE is missing."></cfif>
				<cfif not OTHER_ID_TYPE_exists><cfset message = "#message# OTHER_ID_TYPE is missing."></cfif>
				<cfif not OTHER_ID_VAL_exists><cfset message = "#message# OTHER_ID_VAL is missing."></cfif>
				<cfif not RELATIONSHIP_exists><cfset message = "#message# RELATIONSHIP is missing."></cfif>
				<cfif not RELATED_INSTITUTION_ACRONYM_exists><cfset message = "#message# RELATED_INSTITUTION_ACRONYM is missing."></cfif>
				<cfif not RELATED_COLLECTION_CDE_exists><cfset message = "#message# RELATED_COLLECTION_CDE is missing."></cfif>
				<cfif not RELATED_OTHER_ID_TYPE_exists><cfset message = "#message# RELATED_OTHER_ID_TYPE is missing."></cfif>
				<cfif not RELATED_OTHER_ID_VAL_exists><cfset message = "#message# RELATED_OTHER_ID_VAL is missing."></cfif>
				<cfif not BIOL_INDIV_RELATION_REMARKS_exists><cfset message = "#message# BIOL_INDIV_RELATION_REMARKS is missing."></cfif>
				<cfthrow message="#message#">
			</cfif>
			<cfset colNames="">
			<cfset loadedRows = 0>
			<!--- get the headers from the first row of the input, then iterate through the remaining rows inserting the data into the temp table. --->
			<cfloop from="1" to ="#ArrayLen(arrResult)#" index="row">
				<!--- obtain the values in the current row --->
				<cfset colVals="">
				<cfloop from="1" to ="#ArrayLen(arrResult[row])#" index="col">
					<cfset thisBit=arrResult[row][col]>
					<cfif #row# is 1>
						<cfset colNames="#colNames#,#thisBit#">
					<cfelse>
						<!--- quote values to ensure all columns have content, will need to strip out later to insert values --->
						<cfset colVals="#colVals#,'#thisBit#'">
					</cfif>
				</cfloop>
				<cfif #row# is 1>
					<!--- first row, obtain column headers --->
					<!--- strip off the leading separator --->
					<cfset colNames=replace(colNames,",","","first")>
					<cfset colNameArray = listToArray(ucase(colNames))><!--- the list of columns/fields found in the input file --->
					<cfset fieldArray = listToArray(ucase(fieldlist))><!--- the full list of fields --->
					<cfset typeArray = listToArray(fieldTypes)><!--- the types for the full list of fields --->
					<h3 class="h4">Found #arrayLen(colNameArray)# matching columns in header of csv file.</h3>
					<ul>
						<cfloop list="#fieldlist#" index="field" delimiters=",">
							<cfif listContains(requiredfieldlist,field,",")>
								<cfset class="text-danger">
							<cfelse>
								<cfset class="text-dark">
							</cfif>
							<li class="#class#">
								#field#
								<cfif arrayFindNoCase(colNameArray,field) GT 0>
									<strong>Present in CSV</strong>
								</cfif>
							</li>
						</cfloop>
					</ul>
				<cfelse>
					<!--- subsequent rows, data --->
					<!--- strip off the leading separator --->
					<cfset colVals=replace(colVals,",","","first")>
					<cfset colValArray=listToArray(colVals)>
					<cftry>
						<!--- construct insert for row with a line for each entry in fieldlist using cfqueryparam if column header is in fieldlist, otherwise using null --->
						<cfquery name="insert" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="insert_result">
							insert into MCZBASE.CF_TEMP_BL_RELATIONS
								(#fieldlist#,USERNAME)
							values (
								<cfset separator = "">
								<cfloop from="1" to ="#ArrayLen(fieldArray)#" index="col">
									<cfif arrayFindNoCase(colNameArray,fieldArray[col]) GT 0>
										<cfset fieldPos=arrayFind(colNameArray,fieldArray[col])>
										<cfset val=trim(colValArray[col])>
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
						<cfthrow message="Error inserting data from line #row# in input file.  Header:[#colNames#] Row:[#colVals#] Error: #cfcatch.message#">
					</cfcatch>
					</cftry>
				</cfif>
			</cfloop>
		
			<h3 class="h3">
				Successfully loaded #loadedRows# records from the CSV file.  Next <a href="/tools/BulkloadRelations.cfm?action=validate">click to validate</a>.
			</h3>
		</cfoutput>
	</cfif>

	<cfif #action# is "validate">
		<h2 class="h3">Second step: Data Validation</h2>
		<cfoutput>
			<cfquery name="getCID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				update cf_temp_bl_relations set collection_object_id = 
				(select collection_object_id from cataloged_item where cat_num = 'cf_temp_bl_relations.other_id_val' and collection_cde = cf_temp_bl_relations.collection_cde)
				 where username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="getRCID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				update cf_temp_bl_relations set RELATED_COLLECTION_OBJECT_ID = 
				(select collection_object_id from cataloged_item where collection_cde = cf_temp_bl_relations.related_collection_cde and cat_num = 'cf_temp_bl_relations.related_other_id_val) 
				where username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="miaa" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE cf_temp_bl_relations
				SET validated_status = 'No ID match'
				WHERE other_id_val is null
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="miab" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE cf_temp_bl_relations
				SET validated_status = 'No ID match'
				WHERE related_other_id_val is null
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="miac" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE cf_temp_bl_relations
				SET validated_status = 'collection not found'
				WHERE collection_cde is null
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="miad" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE cf_temp_bl_relations
				SET validated_status = 'related collection not found'
				WHERE related_collection_cde is null
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="miap" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE cf_temp_bl_relations
				SET validated_status = 'bad relationship'
				WHERE relationship not in (select biol_indiv_relationship from ctbiol_relations)
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT INSTITUTION_ACRONYM,COLLECTION_OBJECT_ID,RELATED_COLLECTION_OBJECT_ID,COLLECTION_CDE,OTHER_ID_TYPE,OTHER_ID_VAL,RELATIONSHIP,RELATED_INSTITUTION_ACRONYM,RELATED_COLLECTION_CDE,RELATED_OTHER_ID_TYPE,RELATED_OTHER_ID_VAL,BIOL_INDIV_RELATION_REMARKS,VALIDATED_STATUS
				FROM cf_temp_bl_relations 
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="pf" dbtype="query">
				SELECT count(*) c 
				FROM data 
				WHERE validated_status is not null
			</cfquery>
			<cfif pf.c gt 0>
				<h2>
					There is a problem with #pf.c# of #data.recordcount# row(s). See the STATUS column. (<a href="/tools/BulkloadRelations.cfm?action=dumpProblems">download</a>).
				</h2>
				<h3>
					Fix the problems in the data and <a href="/tools/BulkloadRelations.cfm">start again</a>.
				</h3>
			<cfelse>
				<h2>
					Validation checks passed. Look over the table below and <a href="/tools/BulkloadRelations.cfm?action=load">click to continue</a> if it all looks good.
				</h2>
			</cfif>
			<table class='sortable table table-responsive table-striped d-lg-table'>
				<thead>
					<tr>

						<th>INSTITUTION_ACRONYM</th>
						<th>COLLECTION_CDE</th>
						<th>OTHER_ID_TYPE</th>
						<th>OTHER_ID_VAL</th>
						<th>RELATIONSHIP</th>
						<th>RELATED_INSTITUTION_ACRONYM</th>
						<th>RELATED_COLLECTION_CDE</th>
						<th>RELATED_OTHER_ID_TYPE</th>
						<th>RELATED_OTHER_ID_VAL</th>
						<th>BIOL_INDIV_RELATION_REMARKS</th>
						<th>VALIDATED_STATUS</th>
					</tr>
				<tbody>
					<cfloop query="data">
						<tr>
				
							<td>#data.INSTITUTION_ACRONYM#</td>
							<td>#data.COLLECTION_CDE#</td>
							<td>#data.OTHER_ID_TYPE#</td>
							<td>#data.OTHER_ID_VAL#</td>
							<td>#data.RELATIONSHIP#</td>
							<td>#data.RELATED_INSTITUTION_ACRONYM#</td>
							<td>#data.RELATED_COLLECTION_CDE#</td>
							<td>#data.RELATED_OTHER_ID_TYPE#</td>
							<td>#data.RELATED_OTHER_ID_VAL#</td>
							<td>#data.BIOL_INDIV_RELATION_REMARKS#</td>
							<td><strong>#VALIDATED_STATUS#</strong></td>
						</tr>
					</cfloop>
				</tbody>
			</table>
		</cfoutput>
	</cfif>
				
	<!---Load data--->					
	<cfif #action# is "load">
		<h2 class="h3">Third step: Apply changes.</h2>
		<cfoutput>
			<cfquery name="getTempData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT *
				FROM cf_temp_bl_relations
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cftry>
				<cfset relations_updates = 0>
					<cftransaction>
						<cfloop query="getTempData">
							<cfquery name="updateRelations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="updateRelations_result">
							insert into 
								BIOL_INDIV_RELATIONS (collection_object_id,related_coll_object_id,biol_indiv_relationship,biol_indiv_relation_remarks) values (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#cf_temp_bl_relations.collection_object_id#">,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#cf_temp_bl_relations.related_collection_object_id#">,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#cf_temp_bl_relations.relationship#">,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#cf_temp_bl_relations.biol_indiv_relation_remarks#">)
							</cfquery>
							<cfset relations_updates = relations_updates + updateRelations_result.recordcount>
						</cfloop>
					</cftransaction> 
					<div class="container">
						<div class="row">
							<div class="col-12 mx-auto">
								<h2 class="h3">Updated #relations_updates# relationships.</h2>
							</div>
						</div>
					</div>
				<cfcatch>
					<h2>There was a problem updating relationships.</h2>
					<cfquery name="getProblemData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						SELECT *
						FROM cf_temp_bl_relations 
						WHERE validated_status is not null
							AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
					</cfquery>
					<h3>Problematic Rows (<a href="/tools/BulkloadRelations.cfm?action=dumpProblems">download</a>)</h3>
					<table class='sortable table table-responsive table-striped d-lg-table'>
						<thead>
							<tr>
								<th>INSTITUTION_ACRONYM</th>
								<th>COLLECTION_CDE</th>
								<th>OTHER_ID_TYPE</th>
								<th>OTHER_ID_VAL</th>
								<th>RELATIONSHIP</th>
								<th>RELATED_INSTITUTION_ACRONYM</th>
								<th>RELATED_COLLECTION_CDE</th>
								<th>RELATED_OTHER_ID_TYPE</th>
								<th>RELATED_OTHER_ID_VAL</th>
								<th>BIOL_INDIV_RELATION_REMARKS</th>
								<th>VALIDATED_STATUS</th>
							</tr> 
						</thead>
						<tbody>
							<cfloop query="getProblemData">
								<tr>
									<td>#getProblemData.INSTITUTION_ACRONYM#</td>
									<td>#getProblemData.COLLECTION_CDE#</td>
									<td>#getProblemData.OTHER_ID_TYPE#</td>
									<td>#getProblemData.OTHER_ID_VAL#</td>
									<td>#getProblemData.RELATIONSHIP#</td>
									<td>#getProblemData.RELATED_INSTITUTION_ACRONYM#</td>
									<td>#getProblemData.RELATED_COLLECTION_CDE#</td>
									<td>#getProblemData.RELATED_OTHER_ID_TYPE#</td>
									<td>#getProblemData.RELATED_OTHER_ID_VAL#</td>
									<td>#getProblemData.BIOL_INDIV_RELATION_REMARKS#</td>
									<td><strong>#VALIDATED_STATUS#</strong></td>
								</tr> 
							</cfloop>
						</tbody>
					</table>
					<cfrethrow>
				</cfcatch>
			</cftry>
			<cfset problem_key = "">
			<cftransaction>
				<cftry>
					<cfset relations_updates = 0>
					<cfloop query="getTempData">
						<cfset problem_key = getTempData.key>
						<cfquery name="updateRelations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="updateRelations_result">
							insert into 
								BIOL_INDIV_RELATIONS (collection_object_id,related_coll_object_id,biol_indiv_relationship,biol_indiv_relation_remarks) values (cf_temp_bl_relations.collection_object_id,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#related_collection_object_id#">,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#relationship#">,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#biol_indiv_relation_remarks#">)
						</cfquery>
						<cfset relations_updates = relations_updates + updateRelations_result.recordcount>
					</cfloop>
					<cftransaction action="commit">
				<cfcatch>
					<cftransaction action="rollback">
						<cfquery name="getProblemData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							SELECT INSTITUTION_ACRONYM,COLLECTION_CDE,OTHER_ID_TYPE,OTHER_ID_VAL,RELATIONSHIP,RELATED_INSTITUTION_ACRONYM,
							RELATED_COLLECTION_CDE,RELATED_OTHER_ID_TYPE,RELATED_OTHER_ID_VAL,BIOL_INDIV_RELATION_REMARKS,validated_status
							FROM cf_temp_bl_relations
							WHERE validated_status is not null
							AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						</cfquery>
						<h3>Error updating row (#relations_updates + 1#): #cfcatch.message#</h3>
						<table class='sortable table table-responsive table-striped d-lg-table'>
							<thead>
								<tr>
									<th>INSTITUTION_ACRONYM</th>
									<th>COLLECTION_CDE</th>
									<th>OTHER_ID_TYPE</th>
									<th>OTHER_ID_VAL</th>
									<th>RELATIONSHIP</th>
									<th>RELATED_INSTITUTION_ACRONYM</th>
									<th>RELATED_COLLECTION_CDE</th>
									<th>RELATED_OTHER_ID_TYPE</th>
									<th>RELATED_OTHER_ID_VAL</th>
									<th>BIOL_INDIV_RELATION_REMARKS</th>
									<th>VALIDATED_STATUS</th>
								</tr> 
							</thead>
							<tbody>
								<cfloop query="getProblemData">
									<tr>
										<td>#getProblemData.INSTITUTION_ACRONYM#</td>
										<td>#getProblemData.COLLECTION_CDE#</td>
										<td>#getProblemData.OTHER_ID_TYPE#</td>
										<td>#getProblemData.OTHER_ID_VAL#</td>
										<td>#getProblemData.RELATIONSHIP#</td>
										<td>#getProblemData.RELATED_INSTITUTION_ACRONYM#</td>
										<td>#getProblemData.RELATED_COLLECTION_CDE#</td>
										<td>#getProblemData.RELATED_OTHER_ID_TYPE#</td>
										<td>#getProblemData.RELATED_OTHER_ID_VAL#</td>
										<td>#getProblemData.BIOL_INDIV_RELATION_REMARKS#</td>
										<td>#getProblemData.VALIDATED_STATUS#</td>
									</tr> 
								</cfloop>
							</tbody>
						</table>
						<cfrethrow>
				</cfcatch>
				</cftry>
			</cftransaction>
			<div class="container">
				<div class="row">
					<div class="col-12 mx-auto">
						<h3 class="text-success">Success, changes applied.</h3>
					</div>
				</div>
			</div>
			<cfquery name="clearTempTable" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="clearTempTable_result">
				DELETE FROM cf_temp_bl_relations 
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
		</cfoutput>
	</cfif>
</main>
<cfinclude template="/shared/_footer.cfm">