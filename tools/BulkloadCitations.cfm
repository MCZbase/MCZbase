<!--- tools/bulkloadCitations.cfm add citations to specimens in bulk.

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
		SELECT institution_acronym,collection_cde,other_id_type,other_id_number,publication_title,publication_id,cited_scientific_name,occurs_page_number,citation_page_uri,type_status,citation_remarks
		FROM cf_temp_citation 
		WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
		ORDER BY key
	</cfquery>
	<cfinclude template="/shared/component/functions.cfc">
	<cfinclude template="/shared/functionLib.cfm">
	<cfset csv = queryToCSV(getProblemData)>
	<cfheader name="Content-Type" value="text/csv; charset=utf-8">
	<cfoutput>#csv#</cfoutput>
	<cfabort>
</cfif>
<!--- end special case dump of problems --->

<cfset fieldlist = "institution_acronym,collection_cde,other_id_type,other_id_number,publication_id,cited_scientific_name,occurs_page_number,citation_page_uri,type_status,citation_remarks">
<cfset fieldTypes ="CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_DECIMAL,CF_SQL_VARCHAR,CF_SQL_DECIMAL,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR">
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
<cfinclude template="/tools/component/csv.cfc" runOnce="true"><!--- for common csv testing functions --->
<cfif not isDefined("action") OR len(action) EQ 0><cfset action="entryPoint"></cfif>
<main class="container-fluid py-3 px-5" id="content">
	<h1 class="h2 mt-2">Bulkload Citations</h1>

	<!------------------------------------------------------->
	<cfif #action# is "entryPoint">
		<cfoutput>
			<p>This tool adds citations to the specimen record. The publication and specimens have to be in the code table prior to uploading this .csv. It ignores rows that are exactly the same. Additional columns will be ignored. The publication_title and/or publication_id values must appear as they do on the <a href="/Publications.cfm" class="font-weight-bold">Publication Search Results</a>. The other_id_type and other_id_number values must also be in the database. Search for them via the <a href="/Specimens.cfm" class="font-weight-bold">Specimen Search</a>. Upload a comma-delimited text file (csv). Include column headings, spelled exactly as below. Use "catalog number" as the value of other_id_type to match on catalog number.</p>
			<span class="btn btn-xs btn-info" onclick="document.getElementById('template').style.display='block';">View template</span>
			<div id="template" class="my-1 mx-0" style="display:none;">
				<label for="templatearea" class="data-entry-label mb-1">
					Copy this header line and save it as a .csv file (<a href="/tools/BulkloadCitations.cfm?action=getCSVHeader">download</a>)
				</label>
				<textarea rows="2" cols="90" id="templatearea" class="w-100 data-entry-textarea">#fieldlist#</textarea>
			</div>
			<h2 class="mt-4 h4">Columns in <span class="text-danger">red</span> are required; others are optional:</h2>
			<ul class="mb-4 h4 font-weight-normal list-group">
				<cfloop list="#fieldlist#" index="field" delimiters=",">
					<cfquery name = "getComments"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#"  result="getComments_result">
						SELECT comments
						FROM sys.all_col_comments
						WHERE 
							owner = 'MCZBASE'
							and table_name = 'CF_TEMP_CITATION'
							and column_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(field)#" />
					</cfquery>
					<cfset comment = "">
					<cfif getComments.recordcount GT 0>
						<cfset comment = getComments.comments>
					</cfif>
					<cfset aria = "">
					<cfif listContains(requiredfieldlist,field,",")>
						<cfset class="text-danger font-weight-lessbold">
						<cfset aria = "aria-label='Required Field'">
					<cfelse>
						<cfset class="text-dark font-weight-lessbold">
					</cfif>
					<li class="pb-1 px-0 list-group-item">
						<span class="#class#" #aria#>#field#: </span> #comment#
					</li>
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
			<cfset NO_COLUMN_ERR = "One or more required fields are missing in the header line of the csv file. Check charset selected if columns match required headers and one column is not found.">
			<cfset DUP_COLUMN_ERR = "One or more columns are duplicated in the header line of the csv file.">
			<cfset COLUMN_ERR = "Error inserting data ">
			<cfset NO_HEADER_ERR = "No header line found, csv file appears to be empty.">
			<cfset table_name = "CF_TEMP_CITATION">
			<cftry>
				<!--- cleanup any incomplete work by the same user --->
				<cfquery name="clearTempTable" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="clearTempTable_result">
					DELETE FROM cf_temp_citation
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
								insert into cf_temp_citation
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
							<cfset error_message="#COLUMN_ERR# from line #row# in input file.<br>
							<p>Check format chosen for file uploaded.</p>
							<p>Header:[#colNames#] <br>Row:[#ArrayToList(collValuesArray)#] <br>Error: #cfcatch.message#"></p>
							<!--- " --->
							<cfif isDefined("cfcatch.queryError")>
								<cfset error_message = "#error_message# #cfcatch.queryError#">
							</cfif>
							<cfthrow message = "#error_message#">
						</cfcatch>
						</cftry>
					</cfloop>
					<cfif foundHighCount GT 0>
						<cfset extendedResult = reportExtended(foundHighCount=foundHighCount,foundHighAscii=foundHighAscii,foundMultiByte=foundMultiByte,linkTarget='/tools/BulkloadCitations.cfm')>	
					</cfif>
				</div>
				<h3>
					<cfif loadedRows EQ 0>
						Loaded no rows from the CSV file.  The file appears to be just a header with no data. Fix file and <a href="/tools/BulkloadCitations.cfm">reload</a>
					<cfelse>
						Successfully read #loadedRows# records from the CSV file. Next <a href="/tools/BulkloadCitations.cfm?action=validate">click to validate</a>.
					</cfif>
				</h3>
			<cfcatch>
				<h3 class="h4">
					Failed to read the CSV file.  Fix the errors in the file and <a href="/tools/BulkloadCitations.cfm">reload</a>.
				</h3>
				<cfif isDefined("variables.foundHeaders")>
					<cfset foundHighCount = 0>
					<cfset foundHighAscii = "">
					<cfset foundMultiByte = "">
					<cfloop list="#variables.foundHeaders#" index="thisBit">
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
						<cfset extendedResult = reportExtended(foundHighCount=foundHighCount,foundHighAscii=foundHighAscii,foundMultiByte=foundMultiByte,linkTarget='/tools/BulkloadCitations.cfm',inHeader='yes')>
					</cfif>
				</cfif>
				<cfif Find("#NO_COLUMN_ERR#",cfcatch.message) GT 0>
					<cfset errmessage = Replace(cfcatch.message,NO_COLUMN_ERR,"<h4 class='mb-3'>#NO_COLUMN_ERR#</h4>")><!--- " --->
					#errmessage#
				<cfelseif Find("#NO_HEADER_ERR#",cfcatch.message) GT 0>
					<h4 class='mb-3'>#cfcatch.message#</h4>
				<cfelseif Find("#COLUMN_ERR#",cfcatch.message) GT 0>
					<cfset errmessage = Replace(cfcatch.message,COLUMN_ERR,"<h4 class='mb-3'>#COLUMN_ERR#</h4>")><!--- " --->
					#errmessage#
				<cfelseif Find("#DUP_COLUMN_ERR#",cfcatch.message) GT 0>
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
			<cfset key = ''>
			<cfquery name="getTempTableTypes" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT 
					other_id_type,publication_id, key
				FROM 
					cf_temp_citation
				WHERE 
					username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfloop query="getTempTableTypes">
				<!--- For each row, set the target collection_object_id --->
				<cfif getTempTableTypes.other_id_type eq 'catalog number'>
					<!--- either based on catalog_number --->
					<cfquery name="updateCID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
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
					<cfquery name="updateCID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
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
			</cfloop>
			<!--- obtain the information needed to QC each row --->
			<cfquery name="getTempTableQC" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT 
					distinct key,collection_cde, cited_scientific_name,publication_title
				FROM 
					cf_temp_citation
				WHERE 
					username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfloop query="getTempTableQC">
				<!--- for each row, evaluate the attribute against expectations and provide an error message --->
				<!--- qc checks separate from getting ID numbers, includes presence of values in required columns --->
				<cfquery name="flagNotMatchedTypeStatus" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE cf_temp_citation
					SET 
						status = concat(nvl2(status, status || '; ', ''),'Unknown type_status: "' || type_status ||'"&mdash;not on list')
					WHERE type_status is not null 
						AND type_status not in (select type_status from ctcitation_type_status)
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						and key = <cfqueryparam cfsqltype="CF_SQL_decimal" value="#getTempTableQC.key#"> 
				</cfquery>
				<cfif len(publication_title) gt 0>
					<cfquery name="flagNoPublication" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						UPDATE cf_temp_citation
						SET publication_id = (select distinct publication_id from publication where publication.publication_title = <cfqueryparam cfsqltype="CF_SQL_varchar" value="#getTempTableQC.publication_title#">)
						WHERE publication_id is null
						and publication_title is not null
							AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
							AND key = <cfqueryparam cfsqltype="CF_SQL_decimal" value="#getTempTableQC.key#"> 
					</cfquery>
				<cfelse>
					<cfquery name="flagNoPublication1" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						UPDATE cf_temp_citation
						SET status = concat(nvl2(status, status || '; ', ''),' Publication_id field is missing')
						WHERE publication_id IS NULL
						and publication_title is null
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						AND key = <cfqueryparam cfsqltype="CF_SQL_decimal" value="#getTempTableQC.key#"> 
					</cfquery>
				</cfif>
				<cfquery name="flagNoPublication2" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE cf_temp_citation
					SET cited_taxon_name_id = (
					select taxon_name_id from taxonomy where scientific_name = <cfqueryparam cfsqltype="CF_SQL_varchar" value="#getTempTableQC.cited_scientific_name#"> 
					)
					WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
					and key = <cfqueryparam cfsqltype="CF_SQL_decimal" value="#getTempTableQC.key#"> 
				</cfquery>
				<cfquery name="flagMczAcronym" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE cf_temp_citation
					SET 
						status = concat(nvl2(status, status || '; ', ''),'INSTIUTION_ACRONYM is not "MCZ" (check case)')
					WHERE institution_acronym <> 'MCZ'
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						AND key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableQC.key#">
				</cfquery>
				<cfquery name="flagNotMatchedOther_ID_Type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE cf_temp_citation
					SET 
						status = concat(nvl2(status, status || '; ', ''), 'Unknown other_id_type: "' || other_id_type ||'"&mdash;not on list')
					WHERE other_id_type is not null 
						AND other_id_type <> 'catalog number'
						AND other_id_type not in (select other_id_type from ctcoll_other_id_type)
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						and key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableQC.key#">
				</cfquery>
				<cfquery name="flagNotMatchedTaxonName" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE cf_temp_citation
					SET 
						status = concat(nvl2(status, status || '; ', ''), 'Unknown cited_taxon_name_id created')
					WHERE cited_taxon_name_id not in (select cited_taxon_name_id from publication)
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						and key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableQC.key#">
				</cfquery>
				<cfquery name="FlagCdeProblems" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="citationProblems_result">
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
				<cfquery name="flagNoCollectionObject" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE cf_temp_citation
					SET 
						status = concat(nvl2(status, status || '; ', ''),' There is no match to a cataloged item on [' || other_id_type || ']=[' || other_id_number || '] in collection "' || collection_cde ||'"')
					WHERE collection_object_id IS NULL
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
					AND key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableQC.key#">
				</cfquery>
				<cfquery name="flagCitationExists" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE cf_temp_citation
					SET 
						status = concat(nvl2(status, status || '; ', ''),' Citation already exists ')
					WHERE collection_object_id|| '|' ||publication_id|| '|' ||cited_taxon_name_id IN (select collection_object_id|| '|' ||publication_id|| '|' ||cited_taxon_name_id from citation)
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
					AND key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableQC.key#">
				</cfquery>
			</cfloop>
		
			<!---Missing data in required fields--->
			<cfloop list="#requiredfieldlist#" index="requiredField">
				<cfquery name="checkRequired" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE cf_temp_citation
					SET 
						status = concat(nvl2(status, status || '; ', ''),'Required field, #requiredField#, is missing')
					WHERE #requiredField# is null
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
			</cfloop>
			<!---Go through all the data and report the status--->
			<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT institution_acronym,collection_cde,other_id_type,other_id_number,publication_title,publication_id,cited_scientific_name,
				occurs_page_number,citation_page_uri,cited_taxon_name_id,type_status,citation_remarks,collection_object_id,status
				FROM cf_temp_citation
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="problemsInData" dbtype="query">
				SELECT count(*) c 
				FROM data 
				WHERE status is not null
			</cfquery>
			<cfif problemsInData.c gt 0>
				<h3 class="h4 px-0 mt-3">
					There is a problem with #problemsInData.c# of #data.recordcount# row(s). See the STATUS column (<a href="/tools/BulkloadCitations.cfm?action=dumpProblems">download</a>).
				</h3>
				<h3 class="h4 px-0">
					Fix the problems in the data and <a href="/tools/BulkloadCitations.cfm">start again</a>.
				</h3>
			<cfelse>
				<h3 class="h4 px-0">
					<span class="text-success">Validation checks passed</span>. Look over the table below and <a href="/tools/BulkloadCitations.cfm?action=load" class="btn-link">click to continue</a> if it all looks good or <a href="/tools/BulkloadCitations.cfm" class="text-danger">start again</a>.
				</h3>
			</cfif>
			<table class='px-0 mx-0 sortable table small table-responsive w-100'>
				<thead class="thead-light">
					<tr>
						<th>BULKLOAD&nbsp;STATUS</th>
						<th>INSTITUTION_ACRONYM</th>
						<th>COLLECTION_CDE</th>
						<th>OTHER_ID_TYPE</th>
						<th>OTHER_ID_NUMBER</th>
						<th>PUBLICATION_ID</th>
						<th>PUBLICATION_TITLE</th>
						<th>CITED_SCIENTIFIC_NAME</th>
						<th>OCCURS_PAGE_NUMBER</th>
						<th>CITATION_PAGE_URI</th>
						<th>CITED_TAXON_NAME_ID</th>
						<th>TYPE_STATUS</th>
						<th>CITATION_REMARKS</th>
						<th>COLLECTION_OBJECT_ID</th>
					</tr>
				<tbody>
					<cfloop query="data">
						<tr>
							<td><strong>#data.STATUS#</strong></td>
							<td>#data.INSTITUTION_ACRONYM#</td>
							<td>#data.COLLECTION_CDE#</td>
							<td>#data.OTHER_ID_TYPE#</td>
							<td>#data.OTHER_ID_NUMBER#</td>
							<td>#data.PUBLICATION_ID#</td>
							<td>#data.PUBLICATION_TITLE#</td>
							<td>#data.CITED_SCIENTIFIC_NAME#</td>
							<td>#data.OCCURS_PAGE_NUMBER#</td>
							<td>#data.CITATION_PAGE_URI#</td>
							<th>#data.CITED_TAXON_NAME_ID#</th>
							<td>#data.TYPE_STATUS#</td>
							<td>#data.CITATION_REMARKS#</td>
							<td>#data.COLLECTION_OBJECT_ID#</td>
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
				<cfquery name="getCitData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT * FROM cf_temp_citation
					WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cfquery name="getCounts" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT count(distinct collection_object_id) ctobj FROM cf_temp_citation
					WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cftry>
					<cfset citation_updates = 0>
					<cfset citation_updates1 = 0>
					<cfif getCitData.recordcount EQ 0>
						<cfthrow message="You have no rows to load in the citations bulkloader table (cf_temp_citation).  <a href='/tools/BulkloadCitations.cfm'>Start over</a>"><!--- " --->
					</cfif>
					<cfloop query="getCitData">
						<cfset problem_key = #getCitData.key#>
						<cfquery name="updateCitations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="updateCitations_result">
							INSERT into citation (
							PUBLICATION_ID,
							COLLECTION_OBJECT_ID,
							CITED_TAXON_NAME_ID,
							OCCURS_PAGE_NUMBER,
							CIT_CURRENT_FG,
							TYPE_STATUS,
							CITATION_REMARKS,
							CITATION_PAGE_URI
							)VALUES(
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getCitData.PUBLICATION_ID#">,
							<cfqueryparam cfsqltype="CF_SQL_decimal" value="#getCitData.COLLECTION_OBJECT_ID#">,
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getCitData.CITED_TAXON_NAME_ID#">,
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getCitData.OCCURS_PAGE_NUMBER#">,
							1,
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getCitData.TYPE_STATUS#">,
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getCitData.CITATION_REMARKS#">, 
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getCitData.CITATION_PAGE_URI#">
							)
						</cfquery>
						<cfquery name="updateCitations1" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="updateCitations1_result">
							select PUBLICATION_ID,COLLECTION_OBJECT_ID,CITED_TAXON_NAME_ID,OCCURS_PAGE_NUMBER,TYPE_STATUS,CITATION_REMARKS,CITATION_PAGE_URI from citation
							where collection_object_id = <cfqueryparam cfsqltype="CF_SQL_decimal" value="#getCitData.collection_object_id#">
							group by publication_id,collection_object_id,cited_taxon_name_id,OCCURS_PAGE_NUMBER,TYPE_STATUS,CITATION_REMARKS,CITATION_PAGE_URI
							having count(*) > 1
						</cfquery>
						<cfset citation_updates = citation_updates + updateCitations_result.recordcount>
						<cfif updateCitations1_result.recordcount gt 0>
							<cfthrow message="Error: Attempting to insert a duplicate citation: publication_id=#getCitData.PUBLICATION_ID#, collection_object_id=#getCitData.COLLECTION_OBJECT_ID#, cited_taxon_name_id=#getCitData.CITED_TAXON_NAME_ID#">
						</cfif>
					</cfloop>
					<p>Number of citations to update: #citation_updates# (on #getCounts.ctobj# cataloged items)</p>
					<cfif getCitData.recordcount eq citation_updates and updateCitations1_result.recordcount eq 0>
						<h2 class="text-success">Success - loaded</h2>
					</cfif>
					<cfif updateCitations1_result.recordcount gt 0>
						<h2 class="text-danger">Not loaded - these have already been loaded</h2>
					</cfif>
					<cftransaction action="commit">
				<cfcatch>
					<cftransaction action="ROLLBACK">
					<h2 class="h3">There was a problem updating the citations. </h2>
					<cfquery name="getProblemData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						SELECT COLLECTION_CDE,OTHER_ID_TYPE,OTHER_ID_NUMBER,COLLECTION_OBJECT_ID,PUBLICATION_TITLE,PUBLICATION_ID,CITED_TAXON_NAME_ID,OCCURS_PAGE_NUMBER,TYPE_STATUS,CITATION_REMARKS,CITATION_PAGE_URI
						FROM cf_temp_citation
						where key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#problem_key#">
					</cfquery>
					<cfif getProblemData.recordcount GT 0>
						<h3>
							Fix the issues and <a href="/tools/BulkloadCitations.cfm">reload</a>. Error loading row (<span class="text-danger">#citation_updates + 1#</span>) from the CSV: 
							<cfif len(cfcatch.detail) gt 0>
								<span class="font-weight-normal border-bottom border-danger">
									<cfif cfcatch.detail contains "publication_id">
										Invalid Publication Title; Publication_id; Search Publications
									<cfelseif cfcatch.detail contains "occurs_page_number">
										Problem with OCCURS_PAGE_NUMBER
									<cfelseif cfcatch.detail contains "type_status">
										Invalid or missing TYPE_STATUS
									<cfelseif cfcatch.detail contains "citation_page_uri">
										Invalid CITATION_PAGE_URI
									<cfelseif cfcatch.detail contains "cited_taxon_name_id">
										Invalid CITED_TAXON_NAME_ID
									<cfelseif cfcatch.detail contains "citation_remarks">
										Problem with CITATION_REMARKS (#cfcatch.detail#)
									<cfelseif cfcatch.detail contains "collection_object-Id">
										Invalid COLLECTION_OBJECT_ID
									<cfelseif cfcatch.detail contains "integrity constraint (MCZBASE.FK_CITATION_PUBLICATION) violated">
										Invalid Publication ID
									<cfelseif cfcatch.detail contains "publication_id">
										Problem with PUBLICATION_ID (#cfcatch.detail#)
									<cfelseif cfcatch.detail contains "unique constraint">
										This citation has already been entered. Remove from spreadsheet and try again. (<a href="/tools/BulkloadCitations.cfm">Reload.</a>)
									<cfelseif cfcatch.detail contains "no data">
										No data or the wrong data (#cfcatch.detail#)
									<cfelse>
										<!--- provide the raw error message if it isn't readily interpretable --->
										#cfcatch.detail#
									</cfif>
								</span>
							</cfif>
						</h3>
						<table class='sortable small table table-responsive table-striped d-lg-table mt-3'>
							<thead>
								<tr>
									<th>COUNT</th>
									<th>COLLECTION_CDE</th>
									<th>OTHER_ID_TYPE</th>
									<th>OTHER_ID_NUMBER</th>
									<th>COLLECTION_OBJECT_ID</th>
									<th>PUBLICATION_TITLE</th>
									<th>PUBLICATION_ID</th>
									<th>CITED_TAXON_NAME_ID</th>
									<th>OCCURS_PAGE_NUMBER</th>
									<th>TYPE_STATUS</th>
									<th>CITATION_REMARKS</th>
									<th>CITATION_PAGE_URI</th>
									<th>CITED_TAXON_NAME_ID</th>
								</tr> 
							</thead>
							<tbody>
								<cfset i=1>
								<cfloop query="getProblemData">
									<tr>
										<td>#i#</td>
										<td>#getProblemData.COLLECTION_CDE# </td>
										<td>#getProblemData.OTHER_ID_TYPE# </td>
										<td>#getProblemData.OTHER_ID_NUMBER# </td>
										<td>#getProblemData.COLLECTION_OBJECT_ID#</td>
										<td>#getProblemData.PUBLICATION_TITLE#</td>
										<td>#getProblemData.PUBLICATION_ID#</td>
										<td>#getProblemData.CITED_TAXON_NAME_ID#</td>
										<td>#getProblemData.OCCURS_PAGE_NUMBER# </td>
										<td>#getProblemData.TYPE_STATUS# </td>
										<td>#getProblemData.CITATION_REMARKS#</td>
										<td>#getProblemData.CITATION_PAGE_URI#</td>
										<td>#getProblemData.CITED_TAXON_NAME_ID#</td>
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
			<cfquery name="clearTempTable" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="clearTempTable_result">
				DELETE FROM cf_temp_citation
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
		</cfoutput>
	</cfif>
</main>
<cfinclude template="/shared/_footer.cfm">
