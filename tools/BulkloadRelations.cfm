<!--- tools/bulkloadRelations.cfm add attributes to specimens in bulk.

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
		SELECT INSTITUTION_ACRONYM,COLLECTION_CDE,OTHER_ID_TYPE,OTHER_ID_VAL,RELATIONSHIP,RELATED_INSTITUTION_ACRONYM,RELATED_COLLECTION_CDE,RELATED_OTHER_ID_TYPE,RELATED_OTHER_ID_VAL,BIOL_INDIV_RELATION_REMARKS
		FROM cf_temp_bl_relations
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
<cfset fieldlist="INSTITUTION_ACRONYM,COLLECTION_CDE,OTHER_ID_TYPE,OTHER_ID_VAL,RELATIONSHIP,RELATED_INSTITUTION_ACRONYM,RELATED_COLLECTION_CDE,RELATED_OTHER_ID_TYPE,RELATED_OTHER_ID_VAL,BIOL_INDIV_RELATION_REMARKS">
<cfset fieldTypes="CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR">
<cfset requiredfieldlist="INSTITUTION_ACRONYM,COLLECTION_CDE,OTHER_ID_TYPE,OTHER_ID_VAL,RELATIONSHIP,RELATED_INSTITUTION_ACRONYM,RELATED_COLLECTION_CDE,RELATED_OTHER_ID_TYPE,RELATED_OTHER_ID_VAL,BIOL_INDIV_RELATION_REMARKS">
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
<cfset pageTitle = "Bulkload Relations">
<cfinclude template="/shared/_header.cfm">
<cfinclude template="/tools/component/csv.cfc" runOnce="true"><!--- for common csv functions --->
<cfif not isDefined("action") OR len(action) EQ 0>
	<cfset action="nothing">
</cfif>
<main class="container-fluid px-xl-5 py-3" id="content">
	<h1 class="h2 mt-2">Bulkload Relations</h1>
	<cfif #action# is "nothing">
		<cfoutput>
			<p>This tool adds biological relationships to the specimen record. The relationship and inverse relationship has to be in the code table prior to uploading this .csv. It ignores rows that are exactly the same. Additional columns will be ignored. The relationships must appear as they do on the <a href="https://mczbase.mcz.harvard.edu/vocabularies/ControlledVocabulary.cfm?" class="font-weight-bold">controlled vocabularies</a> lists for <a href="/vocabularies/ControlledVocabulary.cfm?table=CTBIOL_RELATIONS">BIOL_RELATIONS</a> and for some attributes the controlled vocabularies are listed in <a href="/vocabularies/ControlledVocabulary.cfm?table=CTBIOL_RELATIONS">BIOL_RELATIONS</a>. Upload a comma-delimited text file (csv). Include column headings, spelled exactly as below. Use "catalog number" as the value of other_id_type to match on catalog number.</p>
			<span class="btn btn-xs btn-info" onclick="document.getElementById('template').style.display='block';">View template</span>
			<div id="template" style="margin: 1rem 0;display:none;">
				<label for="templatearea" class="data-entry-label mb-1">
					Copy this header line and save it as a .csv file (<a href="/tools/BulkloadRelations.cfm?action=getCSVHeader">download</a>)
				</label>
				<textarea rows="2" cols="90" id="templatearea" class="w-100 data-entry-textarea">#fieldlist#</textarea>
			</div>
			<h2 class="mt-4 h4">Columns in <span class="text-danger">red</span> are required; others are optional:</h2>
			<ul class="mb-4 h5 font-weight-normal list-group">
				<cfloop list="#fieldlist#" index="field" delimiters=",">
					<cfquery name = "getComments"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#"  result="getComments_result">
						SELECT comments
						FROM sys.all_col_comments
						WHERE 
							owner = 'MCZBASE'
							and table_name = 'CF_TEMP_BL_RELATIONS'
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
			<form name="atts" method="post" enctype="multipart/form-data" action="/tools/BulkloadRelations.cfm">
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
		<h2 class="h3">First step: Reading data from CSV file.</h2>
		<!--- Compare the numbers of headers expected against provided in CSV file --->
		<!--- Set some constants to identify error cases in cfcatch block --->
		<cfset NO_COLUMN_ERR = "One or more required fields are missing in the header line of the csv file. Check charset selected if columns match required headers and one column is not found.">
		<cfset DUP_COLUMN_ERR = "One or more columns are duplicated in the header line of the csv file.">
		<cfset COLUMN_ERR = "Error inserting data ">
		<cfset NO_HEADER_ERR = "No header line found, csv file appears to be empty.">
		<cfset table_name = "CF_TEMP_BL_RELATIONS">

		<cftry>
			<cfquery name="clearTempTable" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="clearTempTable_result">
				DELETE FROM cf_temp_bl_relations
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
							insert into cf_temp_bl_relations
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
	<!------------------------------------------------------->
	<cfif #action# is "validate">
		<cfoutput>
			<h2 class="h4">Second step: Data Validation</h2>
			<cfquery name="getTempTableTypes" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				select other_id_type,other_id_val,collection_cde,related_collection_cde,related_other_id_type,related_other_id_val,key 
				from cf_temp_bl_relations 
				where username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfset i= 1>
			<cfloop query="getTempTableTypes">
				<!--- For each row, set the target collection_object_id --->
				<cfif getTempTableTypes.other_id_type eq 'catalog number'>
					<!--- either based on catalog_number --->
					<cfquery name="getCID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						UPDATE
							cf_temp_bl_relations
						SET
							collection_object_id = (
								select collection_object_id 
								from cataloged_item 
								where cat_num = cf_temp_bl_relations.other_id_val
								and collection_cde = cf_temp_bl_relations.collection_cde
							),
							status = null
						WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
							and key = <cfqueryparam cfsqltype="CF_SQL_decimal" value="#getTempTableTypes.key#"> 
					</cfquery>
				<cfelse>
					<!--- or on specified other identifier --->
					<cfquery name="getCID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						UPDATE
							cf_temp_bl_relations
						SET
							collection_object_id= (
								select cataloged_item.collection_object_id 
								from cataloged_item,coll_obj_other_id_num 
								where coll_obj_other_id_num.other_id_type = cf_temp_bl_relations.other_id_type 
								and cataloged_item.collection_cde = cf_temp_bl_relations.collection_cde 
								and display_value= cf_temp_bl_relations.other_id_val
								and cataloged_item.collection_object_id = coll_obj_other_id_num.COLLECTION_OBJECT_ID
							),
							status = null
						WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
							and key = <cfqueryparam cfsqltype="CF_SQL_decimal" value="#getTempTableTypes.key#"> 
					</cfquery>
				</cfif>
				<cfif getTempTableTypes.related_other_id_type eq 'catalog number'>
					<!--- either based on catalog_number --->
					<cfquery name="getRID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						UPDATE
							cf_temp_bl_relations
						SET
							related_collection_object_id = (
								select collection_object_id 
								from cataloged_item 
								where cat_num = cf_temp_bl_relations.related_other_id_val
								and collection_cde = cf_temp_bl_relations.related_collection_cde
							),
							status = null
						WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
							and key = <cfqueryparam cfsqltype="CF_SQL_decimal" value="#getTempTableTypes.key#"> 
					</cfquery>
				<cfelse>
					<!--- or on specified other identifier --->
					<cfquery name="getRID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						UPDATE
							cf_temp_bl_relations
						SET
							related_collection_object_id= (
								select cataloged_item.collection_object_id 
								from cataloged_item,coll_obj_other_id_num 
								where coll_obj_other_id_num.other_id_type = cf_temp_bl_relations.related_other_id_type 
								and cataloged_item.collection_cde = cf_temp_bl_relations.related_collection_cde 
								and display_value= cf_temp_bl_relations.related_other_id_val
								and cataloged_item.collection_object_id = coll_obj_other_id_num.COLLECTION_OBJECT_ID
							),
							status = null
						WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
							and key = <cfqueryparam cfsqltype="CF_SQL_decimal" value="#getTempTableTypes.key#"> 
					</cfquery>
				</cfif>
				<cfquery name="miaa" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE CF_TEMP_BL_RELATIONS
					SET status = concat(nvl2(status, status || '; ', ''),'collection_object_id is null')
					WHERE collection_object_id is null
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cfquery name="miar" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE CF_TEMP_BL_RELATIONS
					SET status = concat(nvl2(status, status || '; ', ''),'related_collection_object_id is null')
					WHERE related_collection_object_id is null
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cfquery name="miaa" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE CF_TEMP_BL_RELATIONS
					SET status = concat(nvl2(status, status || '; ', ''),'No ID match')
					WHERE other_id_val is null
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cfquery name="miab" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE CF_TEMP_BL_RELATIONS
					SET status = concat(nvl2(status, status || '; ', ''),'No ID match')
					WHERE related_other_id_val is null
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cfquery name="miac" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE CF_TEMP_BL_RELATIONS
					SET status = concat(nvl2(status, status || '; ', ''),'Collection not found')
					WHERE collection_cde is null
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cfquery name="miad" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE CF_TEMP_BL_RELATIONS
					SET status = concat(nvl2(status, status || '; ', ''),'Related collection not found')
					WHERE related_collection_cde is null
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cfquery name="miap" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE CF_TEMP_BL_RELATIONS
					SET status = concat(nvl2(status, status || '; ', ''),'Bad relationship')
					WHERE relationship not in (select biol_indiv_relationship from ctbiol_relations)
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				</cfloop>
				<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT INSTITUTION_ACRONYM,COLLECTION_CDE,OTHER_ID_TYPE,OTHER_ID_VAL,COLLECTION_OBJECT_ID,RELATED_INSTITUTION_ACRONYM,RELATED_COLLECTION_CDE,RELATED_OTHER_ID_TYPE,RELATED_OTHER_ID_VAL,RELATED_COLLECTION_OBJECT_ID,RELATIONSHIP,BIOL_INDIV_RELATION_REMARKS,STATUS
					FROM CF_TEMP_BL_RELATIONS
					WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cfquery name="pf" dbtype="query">
					SELECT count(*) c 
					FROM data 
					WHERE status is not null
				</cfquery>
				<cfif pf.c gt 0>
					<h3>
						There is a problem with #pf.c# of #data.recordcount# row(s). See the STATUS column. (<a href="/tools/BulkloadRelations.cfm?action=dumpProblems">download</a>).
					</h3>
					<h3>
						Fix the problems in the data and <a href="/tools/BulkloadRelations.cfm">start again</a>.
					</h3>
				<cfelse>
					<h3>
						Validation checks passed. Look over the table below and <a href="/tools/BulkloadRelations.cfm?action=load">click to continue</a> if it all looks good or <a href = "/tools/BulkloadRelations.cfm">start again</a>.
					</h3>
				</cfif>
			<table class='sortable table table-responsive table-striped w-100 small px-0'>
				<thead>
					<tr>
						<th>BULKLOADING STATUS</th>
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
					</tr>
				<tbody>
					<cfloop query="data">
						<tr>
							<td><cfif len(data.status) eq 0>Cleared to load<cfelse><strong>#data.status#</strong></cfif></td>
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
						</tr>
					</cfloop>
				</tbody>
			</table>
		</cfoutput>
	</cfif>
				
	<!---------------------Load data--------------------------------->
	<cfif action is "load">
		<h2 class="h4">Third step: Apply changes.</h2>
		<cfoutput>
			<cfset problem_key = "">
			<cftransaction>
				<cfquery name="getTempData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT * FROM cf_temp_bl_relations
					WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cfquery name="getCounts" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT count(distinct collection_object_id) ctobj FROM cf_temp_bl_relations
					WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cftry>
					<cfset relations_updates = 0>
					<cfset relations_updates1 = 0>
					<cfif getTempData.recordcount EQ 0>
						<cfthrow message="You have no rows to load in the relations bulkloader table (cf_temp_bl_relations).  <a href='/tools/BulkloadRelations.cfm'>Start over</a>"><!--- " --->
					</cfif>
					<cfloop query="getTempData">
						<cfset problem_key = getTempData.key>
						<cfloop query="getTempData">
							<cfquery name="updateRelations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="updateRelations_result">
								INSERT into 
								BIOL_INDIV_RELATIONS (
								collection_object_id,
								related_coll_object_id,
								biol_indiv_relationship,
								biol_indiv_relation_remarks
								) values (
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.collection_object_id#">,
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.related_collection_object_id#">,
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.relationship#">,
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.biol_indiv_relation_remarks#">)
							</cfquery>
						</cfloop>
						<cfquery name="updateRelations1" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="updateRelations1_result">
							select other_id_type,other_id_val,collection_object_id from BIOL_INDIV_RELATIONS 
							where collection_object_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.collection_object_id#">
							group by other_id_type,other_id_val,collection_object_id
							having count(*) > 1
						</cfquery>
						<cfset relations_updates = relations_updates + updateRelations_result.recordcount>
						<cfif updateRelations1_result.recordcount gt 0>
							<cftransaction action = "ROLLBACK">
						<cfelse>
							<cftransaction action="COMMIT">
						</cfif>
					</cfloop>
					<p>Number of relations to update: #relations_updates# (on #getCounts.ctobj# cataloged items)</p>
					<cfif getTempData.recordcount eq relations_updates and updateRelations1_result.recordcount eq 0>
						<h2 class="text-success">Success - loaded</h2>
					</cfif>
					<cfif updateRelations1_result.recordcount gt 0>
						<h2 class="text-danger">Not loaded - these have already been loaded</h2>
					</cfif>
					<cfcatch>
						<cftransaction action="ROLLBACK">
						<h2 class="h3">There was a problem updating the relations.</h2>
						<cfquery name="getProblemData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							SELECT status,institution_acronym,collection_cde,other_id_type,other_id_val,relationship,related_institution_acronym,related_collection_cde,related_other_id_type,related_other_id_val,biol_indiv_relation_remarks
							FROM cf_temp_bl_relations 
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
							<h2 class="h3">Errors are displayed one row at a time.</h2>
							<h3>
								Error loading row (<span class="text-dark">#relations_updates + 1#</span>) from the CSV: 
								<cfif len(cfcatch.detail) gt 0>
									<span class="font-weight-normal border-bottom border-danger">
										<cfif cfcatch.detail contains "Invalid RELATIONSHIP">
											Invalid BIOL_RELATIONSHIP; check controlled vocabulary (Help menu)
										<cfelseif cfcatch.detail contains "collection_cde">
											COLLECTION_CDE does not match abbreviated collection (#collection_codes#)
										<cfelseif cfcatch.detail contains "institution_acronym">
											INSTITUTION_ACRONYM does not match #institutions# (all caps)
										<cfelseif cfcatch.detail contains "other_id_type">
											OTHER_ID_TYPE is not valid
										<cfelseif cfcatch.detail contains "related_other_id_type">
											RELATED_OTHER_ID_TYPE does not match controlled vocabulary
										<cfelseif cfcatch.detail contains "collection_object_id">
											Problem with COLLECTION_OBJECT_ID. (#cfcatch.detail#)
										<cfelseif cfcatch.detail contains "related_collection_object_id">
											Problem with RELATED_COLLECTION_OBJECT_ID. (#cfcatch.detail#)
										<cfelseif cfcatch.detail contains "related_institution_acronym">
											Invalid related_institution_acronym
										<cfelseif cfcatch.detail contains "RELATED_OTHER_ID_VAL">
											Problem with RELATED_OTHER_ID_VAL (#cfcatch.detail#)
										<cfelseif cfcatch.detail contains "OTHER_ID_VAL">
											Problem with OTHER_ID_VAL (#cfcatch.detail#)
										<cfelseif cfcatch.detail contains "biol_indiv_relation_remarks">
											Problem with BIOL_INDIV_RELATION_REMARKS (#cfcatch.detail#)
										<cfelseif cfcatch.detail contains "no data">
											No data or the wrong data (#cfcatch.detail#)
										<cfelse>
											<!--- provide the raw error message if it isn't readily interpretable --->
											#cfcatch.detail#
										</cfif>
									</span>
								</cfif>
							</h3>
							<h3>There was a problem updating relationships (<a href="/tools/BulkloadRelations.cfm?action=dumpProblems">download</a>).</h3>
							<cfquery name="getProblemData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
								SELECT *
								FROM cf_temp_bl_relations 
								WHERE status is not null
									AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
							</cfquery>
							<table class='px-0 sortable small w-100 table table-responsive table-striped mt-3'>
								<thead>
									<tr>
										<th>CT</th>
										<th>STATUS</th>
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
									</tr> 
								</thead>
								<tbody>
									<cfset i=1>
									<cfloop query="getProblemData">
										<tr>
											<td>#i#</td>
											<td><strong>#STATUS#</strong></td>
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
										</tr>
										<cfset i= i+1>
									</cfloop>
								</tbody>
							</table>
							<cfrethrow>
						</cfif>
						<div>#cfcatch.message#</div>
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