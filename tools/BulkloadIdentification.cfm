<!--- special case handling to dump problem data as csv --->
<cfif isDefined("action") AND action is "dumpProblems">
	<cfquery name="getProblemData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		SELECT institution_acronym,collection_cde,other_id_type,other_id_number,scientific_name,made_date,nature_of_id,accepted_id_fg,identification_remarks,taxa_formula,agent_1,agent_2,stored_as_fg,publication_id
		FROM cf_temp_ID
		WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
	</cfquery>
	<cfinclude template="/shared/component/functions.cfc">
	<cfset csv = queryToCSV(getProblemData)>
	<cfheader name="Content-Type" value="text/csv">
	<cfoutput>#csv#</cfoutput>
	<cfabort>
</cfif>
		
<!--- end special case dump of problems --->
<cfset fieldlist = "INSTITUTION_ACRONYM,COLLECTION_CDE,OTHER_ID_TYPE,OTHER_ID_NUMBER,SCIENTIFIC_NAME,MADE_DATE,NATURE_OF_ID,ACCEPTED_ID_FG,IDENTIFICATION_REMARKS,AGENT_1,AGENT_2,TAXA_FORMULA,STORED_AS_FG,PUBLICATION_ID">
<cfset fieldTypes ="CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_DECIMAL,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_DECIMAL,CF_SQL_DECIMAL">
<cfset requiredfieldlist = "INSTITUTION_ACRONYM,COLLECTION_CDE,OTHER_ID_TYPE,OTHER_ID_NUMBER,SCIENTIFIC_NAME,NATURE_OF_ID,ACCEPTED_ID_FG,AGENT_1">
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
<cfset pageTitle = "Bulkload Identification">
<cfinclude template="/shared/_header.cfm">
<cfinclude template="/tools/component/csv.cfc" runOnce="true"><!--- for common csv testing functions --->
<cfif not isDefined("action") OR len(action) EQ 0><cfset action="nothing"></cfif>
<main class="container-fluid py-3 px-xl-5" id="content">
	<h1 class="h2 mt-2">Bulkload Identification</h1>
	<cfif #action# is "nothing">
		<cfoutput>
			<p>This tool is used to bulkload identifications.Upload a comma-delimited text file (csv). Include column headings, spelled exactly as below. Additional colums will be ignored.</p>
			<span class="btn btn-xs btn-info" onclick="document.getElementById('template').style.display='block';">View template</span>
			<div id="template" class="my-1 mx-0" style="display:none;">
				<label for="templatearea" class="data-entry-label mb-1">
					Copy this header line and save it as a .csv file (<a href="/tools/BulkloadIdentification.cfm?action=getCSVHeader" class="font-weight-lessbold">download</a>)
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
							and table_name = 'CF_TEMP_ID'
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
			<form name="atts" method="post" enctype="multipart/form-data" action="/tools/BulkloadIdentification.cfm">
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
			<cfset TABLE_NAME = "CF_TEMP_ID">
			<cftry>
				<!--- cleanup any incomplete work by the same user --->
				<cfquery name="clearTempTable" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="clearTempTable_result">
					DELETE FROM cf_temp_ID 
					WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>

				<cfset variables.foundHeaders =""><!--- populated by loadCsvFile --->
				<cfset variables.size=""><!--- populated by loadCsvFile --->
				<cfset iterator = loadCsvFile(FileToUpload=FileToUpload,format=format,characterSet=characterSet)>			

				<!--- Note: As we can't use csvFormat.withHeader(), we can not match columns by name, we are forced to do so by number, thus arrays --->
				<cfset colNameArray = listToArray(ucase(foundHeaders))><!--- the list of columns/fields found in the input file --->
				<cfset fieldArray = listToArray(ucase(fieldlist))><!--- the full list of fields --->
				<cfset typeArray = listToArray(fieldTypes)><!--- the types for the full list of fields --->
				<div class="col-12 my-4 px-0">
					<h3 class="h4">Found #size# columns in header of csv file.</h3>
					<h3 class="h4">There are #ListLen(fieldList)# columns expected in the header (of these #ListLen(requiredFieldList)# are required).</h3>
				</div>
				
				<!--- check for required fields in header line, list all fields, throw exception and fail if any required fields are missing --->
				<cfset reqFieldsResponse = checkRequiredFields(fieldList=fieldList,requiredFieldList=requiredFieldList,NO_COLUMN_ERR=NO_COLUMN_ERR,TABLE_NAME=TABLE_NAME)>

				<!--- Test for additional columns not in list, warn and ignore. --->
				<cfset addFieldsResponse = checkAdditionalFields(fieldList=fieldList)>

				<!--- Identify duplicate columns and fail if found --->
				<cfset dupFieldsResponse = checkDuplicateFields(foundHeaders=foundHeaders,DUP_COLUMN_ERR=DUP_COLUMN_ERR)>

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
						<cfset thisBit = "#rowData.get(JavaCast('int',i))#" >
						<!--- store in a coldfusion array so we won't need JavaCast to reference by position --->
						<cfset ArrayAppend(collValuesArray,thisBit)>
						<cfif REFind("[^\x00-\x7F]",thisBit) GT 0>
							<!--- high ASCII --->
							<cfif foundHighCount LT 6>
								<cfset foundHighAscii = "#foundHighAscii# <li class='text-dark pb-1'><i class='fas fa-arrow-right text-dark'></i> #thisBit#</li>"><!--- " --->
								<cfset foundHighCount = foundHighCount + 1>
							</cfif>
						<cfelseif REFind("[\xc0-\xdf][\x80-\xbf]",thisBit) GT 0>
							<!--- multibyte --->
							<cfif foundHighCount LT 6>
								<cfset foundMultiByte = "#foundMultiByte# <li class='text-dark pb-1'><i class='fas fa-arrow-right text-dark'></i>  #thisBit#</li>"><!--- " --->
								<cfset foundHighCount = foundHighCount + 1>
							</cfif>
						</cfif>
					</cfloop>
					<cftry>
						<!--- construct insert for row with a line for each entry in fieldlist using cfqueryparam if column header is in fieldlist, otherwise using null --->
						<!--- Note: As we can't use csvFormat.withHeader(), we can not match columns by name, we are forced to do so by number, thus arrays --->
						<cfquery name="insert" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="insert_result">
							insert into cf_temp_ID
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
					<cfset extendedResult = reportExtended(foundHighCount=foundHighCount,foundHighAscii=foundHighAscii,foundMultiByte=foundMultiByte,linkTarget='/tools/BulkloadIdentification.cfm')>
				</cfif>
				<h4>
					<cfif loadedRows EQ 0>
						Loaded no rows from the CSV file.  The file appears to be just a header with no data. Fix file and <a href="/tools/BulkloadIdentification.cfm">reload</a>
					<cfelse>
						<cfif size eq 1>Size = 1<cfelse>
						Successfully read #loadedRows# records from the CSV file. Next <a href="/tools/BulkloadIdentification.cfm?action=validate">click to validate</a>.</cfif>
					</cfif>
				</h4>
			<cfcatch>
				<h4>
					<strong class="text-danger">Failed to read the CSV file.</strong> Fix the errors in the file and <a href="/tools/BulkloadIdentification.cfm">reload</a>
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
						<cfset extendedResult = reportExtended(foundHighCount=foundHighCount,foundHighAscii=foundHighAscii,foundMultiByte=foundMultiByte,linkTarget='/tools/BulkloadIdentification.cfm',inHeader='yes')>
					</cfif>
				</cfif>
			
				<cfif Find("#NO_COLUMN_ERR#",cfcatch.message) GT 0>
					<cfset errmessage = Replace(cfcatch.message,NO_COLUMN_ERR,"<h4 class='mb-3'>#NO_COLUMN_ERR#</h4>")>
					#errmessage#
				<cfelseif Find("#NO_HEADER_ERR#",cfcatch.message) GT 0>
					<h4 class='mb-3'>#cfcatch.message#</h4>
				<cfelseif Find("#COLUMN_ERR#",cfcatch.message) GT 0>
					<cfset errmessage = Replace(cfcatch.message,COLUMN_ERR,"<h4 class='mb-3'>#COLUMN_ERR#</h4>")>
					#errmessage#
				<cfelseif Find("#DUP_COLUMN_ERR#",cfcatch.message) GT 0>
					<h4 class='mb-3'>#cfcatch.message#</h4>
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
		<h2 class="h4">Second step: Data Validation</h2>
		<cfoutput>
			<cfset error_message = 'You have multiple rows with the same collection_cde, other_id_type, other_id_number combination. Use another set of IDs to identify this cataloged item. <a href="/tools/BulkloadIdentification.cfm">Start over</a>'>

			<cfquery name="getTempTableTypes" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT 
					other_id_type,key
				FROM 
					cf_temp_ID
				WHERE 
					username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfloop query="getTempTableTypes">
				<cfquery name="getTempOtherCt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT 
						other_id_type
					FROM 
						cf_temp_ID
					WHERE 
						username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
					and other_id_type <> 'catalog number'
					group by other_id_type
					having count(*)>1
				</cfquery>
				<cfif getTempOtherCt.recordcount GT 1>
					<cfthrow message="#error_message#">
				</cfif>
				<cfif getTempTableTypes.other_id_type eq 'catalog number'>
					<!--- either based on catalog_number --->
					<cfquery name="getCID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						UPDATE
							cf_temp_ID
						SET
							collection_object_id = (
								select collection_object_id 
								from cataloged_item 
								where cat_num = cf_temp_ID.other_id_number 
								and collection_cde = cf_temp_ID.collection_cde
							),
							status = null
						WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
							and key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableTypes.key#"> 
					</cfquery>
				<cfelse>
					<!--- or on specified other identifier --->
					<cfquery name="getCID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						UPDATE
							cf_temp_ID
						SET
							collection_object_id= (
							SELECT cataloged_item.collection_object_id 
							FROM cataloged_item,coll_obj_other_id_num 
							WHERE coll_obj_other_id_num.other_id_type = cf_temp_ID.other_id_type 
							AND cataloged_item.collection_cde = cf_temp_ID.collection_cde 
							AND display_value = cf_temp_ID.other_id_number
							AND cataloged_item.collection_object_id = coll_obj_other_id_num.COLLECTION_OBJECT_ID
							),
							status = null
						WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
							and key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableTypes.key#"> 
					</cfquery>
				</cfif>
			</cfloop>
			<!--- obtain the information needed to QC each row --->
			<cfquery name="getTempTableQC" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT key,collection_object_id,institution_acronym,collection_cde,other_id_type,other_id_number,scientific_name,made_date,nature_of_id,accepted_id_fg,identification_remarks,agent_1,agent_2,taxa_formula,stored_as_fg,publication_id
				FROM 
					cf_temp_ID
				WHERE 
					username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfloop query="getTempTableQC">
				<cfquery name="flagMczAcronym" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE cf_temp_ID
					SET 
						status = concat(nvl2(status, status || '; ', ''),'INSTIUTION_ACRONYM is not "MCZ" (check case)')
					WHERE institution_acronym <> 'MCZ'
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cfquery name="flagCde" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE cf_temp_ID
					SET 
						status = concat(nvl2(status, status || '; ', ''),'COLLECTION_CDE does not match Cryo, Ent, Herp, Ich, IP, IZ, Mala, Mamm, Orn, SC, or VP (check case)')
					WHERE collection_cde not in (select collection_cde from ctcollection_cde)
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cfquery name="flagNoCollectionObject" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE cf_temp_ID
					SET 
						status = concat(nvl2(status, status || '; ', ''),' There is no match to a cataloged item on "'||other_id_type||'" = "'||other_id_number||'" in collection "'||collection_cde||'"')
					WHERE collection_object_id IS NULL
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cfquery name="flagNotMatchedExistOther_ID_Type1" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE cf_temp_ID
					SET 
						status = concat(nvl2(status, status || '; ', ''), 'Unknown other_id_type: "' || other_id_type ||'"&mdash;not on list')
					WHERE other_id_type is not null 
						AND other_id_type <> 'catalog number'
						AND other_id_type not in (select other_id_type from ctcoll_other_id_type)
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>

				<cfquery name="flagNotMatchSciName" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE cf_temp_ID SET status = concat(nvl2(status, status || '; ', ''),'scientific_name not found')
					WHERE scientific_name is null 
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>

				<cfquery name ="flagMadeDate"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE cf_temp_ID set
					status = concat(nvl2(status, status || '; ', ''),'Invalid MADE_DATE "'||MADE_DATE||'"') WHERE MADE_DATE is not null 
						AND is_iso8601(MADE_DATE) <> '' 
						AND length(MADE_DATE) <> 10
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cfquery name="flagNotMatchCTnature" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE cf_temp_ID SET 
					status = concat(nvl2(status, status || '; ', ''), 'Unknown nature of ID: "'||nature_of_id||'"')
					WHERE nature_of_id not in (select nature_of_id from ctnature_of_id)
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				
				<cfif right(scientific_name,4) is " sp.">
					<cfset scientific_name=left(scientific_name,len(scientific_name) -4)>
					<cfset tf = "A sp.">
					<cfset TaxonomyTaxonName=left(scientific_name,len(scientific_name) - 4)>
				<cfelseif right(scientific_name,5) is " ssp.">
					<cfset scientific_name=left(scientific_name,len(scientific_name) -5)>
					<cfset tf = "A ssp.">
					<cfset TaxonomyTaxonName=left(scientific_name,len(scientific_name) - 5)>
				<cfelseif right(scientific_name,5) is " spp.">
					<cfset scientific_name=left(scientific_name,len(scientific_name) -5)>
					<cfset tf = "A spp.">
					<cfset TaxonomyTaxonName=left(scientific_name,len(scientific_name) - 5)>
				<cfelseif right(scientific_name,5) is " var.">
					<cfset scientific_name=left(scientific_name,len(scientific_name) -5)>
					<cfset tf = "A var.">
					<cfset TaxonomyTaxonName=left(scientific_name,len(scientific_name) - 5)>
				<cfelseif right(scientific_name,9) is " sp. nov.">
					<cfset scientific_name=left(scientific_name,len(scientific_name) -9)>
					<cfset tf = "A sp. nov.">
					<cfset TaxonomyTaxonName=left(scientific_name,len(scientific_name) - 9)>
				<cfelseif right(scientific_name,10) is " gen. nov.">
					<cfset scientific_name=left(scientific_name,len(scientific_name) -10)>
					<cfset tf = "A gen. nov.">
					<cfset TaxonomyTaxonName=left(scientific_name,len(scientific_name) - 10)>
				<cfelseif right(scientific_name,8) is " (Group)">
					<cfset scientific_name=left(scientific_name,len(scientific_name) -8)>
					<cfset tf = "A (Group)">
					<cfset TaxonomyTaxonName=left(scientific_name,len(scientific_name) - 8)>
				<cfelseif right(scientific_name,4) is " nr.">
					<cfset scientific_name=left(scientific_name,len(scientific_name) -5)>
					<cfset tf = "A nr.">
					<cfset TaxonomyTaxonName=left(scientific_name,len(scientific_name) - 5)>
				<cfelseif right(scientific_name,4) is " cf.">
					<cfset scientific_name=left(scientific_name,len(scientific_name) -4)>
					<cfset tf = "A cf.">
					<cfset TaxonomyTaxonName=left(scientific_name,len(scientific_name) - 4)>
				<cfelseif right(scientific_name,2) is " ?">
					<cfset scientific_name=left(scientific_name,len(scientific_name) -2)>
					<cfset tf = "A ?">
					<cfset TaxonomyTaxonName=left(scientific_name,len(scientific_name) - 2)>
				<cfelse>
					<cfset  tf = "A">
					<cfset TaxonomyTaxonName="#scientific_name#">
				</cfif>
				<cfquery name="isTaxa" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select taxon_name_id from taxonomy 
					where scientific_name = '#TaxonomyTaxonName#'
				</cfquery>
				<cfif #isTaxa.recordcount# is not 1>
					<cfif len(#isTaxa.recordcount#) is 0>
						<cfquery name="probColl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							UPDATE cf_temp_ID
							SET status = concat(nvl2(status, status || '; ', ''),'taxonomy not found')
							WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						</cfquery>
					<cfelse>
						<cfquery name="probColl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							UPDATE cf_temp_ID
							SET status = concat(nvl2(status, status || '; ', ''),'multiple taxonomy records found for this scientific name')
							WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						</cfquery>
					</cfif>
				<cfelse>
					<cfquery name="updateColl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						UPDATE cf_temp_id SET taxon_name_id = '#isTaxa.taxon_name_id#'
						WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						and scientific_name = '#TaxonomyTaxonName#'
					</cfquery>
				</cfif>
				<cfquery name="flagNotMatchedToStoredAs" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE cf_temp_ID
					SET 
						status = concat(nvl2(status, status || '; ', ''), 'The stored_as_fg can only be 1 when identification is not current (accepted_id_fg=1)')
					WHERE stored_as_fg = 1 AND accepted_id_fg = 1
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cfquery name="a1" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select distinct agent_id from agent_name where agent_name=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempTableQC.agent_1#">
				</cfquery>
				<cfif #a1.recordcount# is not 1>
					<cfif len(#a1.agent_id#) is 0>
						UPDATE cf_temp_ID
						SET status = concat(nvl2(status, status || '; ', ''),'agent_1 not in database')
						WHERE agent_1 is not null
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
					<cfelse>
						UPDATE cf_temp_ID
						SET status = concat(nvl2(status, status || '; ', ''),'agent_1 matched #a1.recordcount# records in the database')
						WHERE agent_1 is not null
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
					</cfif>
				<cfelse>
					<cfquery name="insColl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						UPDATE cf_temp_id SET agent_1_id = #a1.agent_id#
					</cfquery>
				</cfif>
				<cfif len(agent_2) gt 0>
					<cfquery name="a2" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select distinct agent_id from agent_name where agent_name=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempTableQC.agent_2#"> 
					</cfquery>
					<cfif #a2.recordcount# is not 1>
						<cfif len(#a2.agent_id#) is 0>
							UPDATE cf_temp_ID
							SET status = concat(nvl2(status, status || '; ', ''),'agent_2 not in database')
							WHERE agent_1 is not null
							AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						<cfelse>
							UPDATE cf_temp_ID
							SET status = concat(nvl2(status, status || '; ', ''),'agent_2 matched #a1.recordcount# records in the database')
							WHERE agent_2 is not null
							AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						</cfif>
					<cfelse>
						<cfquery name="insColl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							UPDATE cf_temp_id SET agent_2_id = #a2.agent_id#
						</cfquery>
					</cfif>
				</cfif>
				<cfif len(publication_id) gt 0>
					<cfquery name="pub" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select distinct publication_id from publication where publication_id=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempTableQC.publication_id#"> 
					</cfquery>
					<cfif #pub.recordcount# is not 1>
						<cfif len(#pub.publication_id#) is 0>
							<p>publication_id does not match any records.</p>
						<cfelse>
							<p>publication_id matched #pub.recordcount# records</p>
						</cfif>
					<cfelse>
						<cfquery name="getPub" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							UPDATE cf_temp_id SET publication_id = #pub.publication_id# 
						</cfquery>
					</cfif>
				<cfelse>
					<cfquery name="getPub" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						UPDATE cf_temp_id SET publication_id = '' 
					</cfquery>
				</cfif>
				
			</cfloop>	
			<!---Missing data in required fields--->
			<cfloop list="#requiredfieldlist#" index="requiredField">
				<cfquery name="checkRequired" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE cf_temp_ID
					SET 
						status = concat(nvl2(status, status || '; ', ''),'#requiredField# is missing')
					WHERE #requiredField# is null
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
			</cfloop>
			<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT key,status,collection_object_id,nature_of_id,taxon_name_id,scientific_name,institution_acronym,collection_cde,other_id_type,other_id_number,made_date,accepted_id_fg,identification_remarks,taxa_formula,agent_1,agent_2,stored_as_fg,publication_id,taxon_name_id
				FROM cf_temp_ID
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="problemCount" dbtype="query">
				SELECT count(*) c 
				FROM data 
				WHERE status is not null
			</cfquery>
			<cfif problemCount.c gt 0>
				<h3 class="mt-4 mb-2">
					<cfif problemCount.c GT 1><cfset plural="s"><cfelse><cfset plural=""></cfif>
					There is a problem with #problemCount.c# of #data.recordcount# row#plural#. See the STATUS column. (<a href="/tools/BulkloadIdentification.cfm?action=dumpProblems">download</a>). Fix the problems in the data and <a href="/tools/BulkloadIdentification.cfm">start again</a>.
				</h3>
			<cfelse>
				<h3 class="mt-4 mb-2">
					<span class="text-success">Validation checks passed.</span> Look over the table below and <a href="/tools/BulkloadIdentification.cfm?action=load">click to continue</a> if it all looks good or <a href="/tools/BulkloadIdentification.cfm">start again</a>.
				</h3>
			</cfif>
			<table class='px-0 mx-0 sortable table w-100 small table-responsive table-striped'>
				<thead>
					<tr>
						<th>BULKLOAD&nbsp;STATUS</th>
						<th>INSTITUTION_ACRONYM</th>
						<th>COLLECTION_CDE</th>
						<th>OTHER_ID_TYPE</th>
						<th>OTHER_ID_NUMBER</th>
						<th>SCIENTIFIC_NAME</th>
						<th>MADE_DATE</th>
						<th>NATURE_OF_ID</th>
						<th>ACCEPTED_ID_FG</th>
						<th>IDENTIFICATION_REMARKS</th>
						<th>TAXA_FORMULA</th>
						<th>AGENT_1</th>
						<th>AGENT_2</th>
						<th>STORED_AS_FG</th>
						<th>PUBLICATION_ID</th>
					</tr>
				<tbody>
					<cfloop query="data">
						<tr>
							<td><cfif len(data.status) eq 0>Cleared to load<cfelse><strong>#data.status#</strong></cfif></td>
							<td>#data.INSTITUTION_ACRONYM#</td>
							<td>#data.COLLECTION_CDE#</td>
							<td>#data.OTHER_ID_TYPE#</td>
							<td>#data.OTHER_ID_NUMBER#</td>
							<td>#data.scientific_name# </td>
							<td>#data.MADE_DATE#</td>
							<td>#data.NATURE_OF_ID#</td>
							<td>#data.ACCEPTED_ID_FG#</td>
							<td>#data.IDENTIFICATION_REMARKS#</td>
							<td>#data.TAXA_FORMULA#</td>
							<td>#data.AGENT_1#</td>
							<td>#data.AGENT_2#</td>
							<td>#data.STORED_AS_FG#</td>
							<td>#data.PUBLICATION_ID#</td>
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
				<cfquery name="getCounts" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT count(distinct collection_object_id) c FROM cf_temp_ID
					WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cfquery name="getTempData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT KEY,COLLECTION_OBJECT_ID,COLLECTION_CDE,INSTITUTION_ACRONYM,OTHER_ID_TYPE,OTHER_ID_NUMBER,SCIENTIFIC_NAME,MADE_DATE,NATURE_OF_ID, ACCEPTED_ID_FG,IDENTIFICATION_REMARKS,AGENT_1,AGENT_2,TAXA_FORMULA,AGENT_1_ID,AGENT_2_ID,STORED_AS_FG,PUBLICATION_ID,TAXON_NAME_ID
					FROM cf_temp_ID
					WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cftry>
					<cfset testParse = 0>
					<cfif getTempData.recordcount EQ 0>
						<cfthrow message="You have no rows to load in the Identifications bulkloader table (cf_temp_ID). <a href='/tools/BulkloadIdentification.cfm'>Start over</a>">
					</cfif>
					<cfset i = 0>
					<cfloop query="getTempData">
						<cfset problem_key = getTempData.key>
						<cfif getTempData.ACCEPTED_ID_FG is 1>
							<cfquery name="sinkOld" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
								update identification set ACCEPTED_ID_FG=0 
								where COLLECTION_OBJECT_ID=#getTempData.COLLECTION_OBJECT_ID#
							</cfquery>
						</cfif>
						<cfif getTempData.STORED_AS_FG is 1>
							<cfquery name="removeOld" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
								update identification set STORED_AS_FG=0 
								where COLLECTION_OBJECT_ID=#getTempData.COLLECTION_OBJECT_ID#
							</cfquery>
						</cfif>
		
						<cftransaction>
							<cfquery name="NEXTID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
								select sq_identification_id.nextval from dual
							</cfquery>
							<cfquery name="insertID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="insertID_result">
								insert all
								into identification (
									IDENTIFICATION_ID,
									COLLECTION_OBJECT_ID,
									MADE_DATE,
									NATURE_OF_ID,
									ACCEPTED_ID_FG,
									IDENTIFICATION_REMARKS,
									TAXA_FORMULA,
									SCIENTIFIC_NAME,
									STORED_AS_FG,
									PUBLICATION_ID
								) values (
									#NEXTID.nextval#,
									<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempData.COLLECTION_OBJECT_ID#">,
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.MADE_DATE#">,
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.NATURE_OF_ID#">,
									<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempData.ACCEPTED_ID_FG#">,
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.IDENTIFICATION_REMARKS#">,
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.TAXA_FORMULA#">,
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.SCIENTIFIC_NAME#">,
									<cfif len(STORED_AS_FG)gt 0>
										<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempData.STORED_AS_FG#">,
									<cfelse>
										'0',
									</cfif>
									<cfif len(PUBLICATION_ID)gt 0>
										<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempData.PUBLICATION_ID#">
									<cfelse>
										''
									</cfif>
								)
								into identification_taxonomy (
									IDENTIFICATION_ID,
									TAXON_NAME_ID,
									VARIABLE
								) values (
									sq_identification_id.currval,
									<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempData.TAXON_NAME_ID#">,
									'A')
								into identification_agent (
									IDENTIFICATION_ID,
									AGENT_ID,
									IDENTIFIER_ORDER
								) values (
									sq_identification_id.currval,
									<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempData.AGENT_1_ID#">,
									1
								)
								select * from dual
							</cfquery>
						</cftransaction>
						<cfif len(agent_2_id) gt 0>
							<cfquery name="insertida2" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
								insert into identification_agent (
									IDENTIFICATION_ID,
									AGENT_ID,
									IDENTIFIER_ORDER
								) values (
									sq_identification_id.currval,
									<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempData.AGENT_2_ID#">,
									2
								)
							</cfquery>
						</cfif>
						<cfquery name="getID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getID_result">
							select identification.IDENTIFICATION_ID, identification.COLLECTION_OBJECT_ID, identification.MADE_DATE, identification.NATURE_OF_ID, identification.ACCEPTED_ID_FG,identification.IDENTIFICATION_REMARKS, identification.TAXA_FORMULA, identification.SCIENTIFIC_NAME,identification.stored_as_fg,identification.publication_id,identification_agent.agent_id,identification_agent.identifier_order,identification_agent.identification_agent_id,identification_taxonomy.taxon_name_id 
							from identification,identification_agent, identification_taxonomy
							where collection_object_id = <cfqueryparam cfsqltype="CF_SQL_decimal" value="#getTempData.collection_object_id#">
							AND identification.identification_id = identification_agent.identification_id
							and identification_agent.identification_id = identification_taxonomy.identification_id
							group by identification.IDENTIFICATION_ID, identification.COLLECTION_OBJECT_ID, identification.MADE_DATE, identification.NATURE_OF_ID, identification.ACCEPTED_ID_FG,identification.IDENTIFICATION_REMARKS, identification.TAXA_FORMULA, identification.SCIENTIFIC_NAME,identification.stored_as_fg,identification.publication_id,identification_agent.agent_id,identification_agent.identifier_order,identification_agent.identification_agent_id,identification_taxonomy.taxon_name_id 
							having count(*)>1
						</cfquery>
						<cfset testParse = testParse + 1>
						<cfif getID_result.recordcount gt 0>
							<cftransaction action = "ROLLBACK">
						<cfelse>
							<cftransaction action="COMMIT">
						</cfif>
						<cfset i = i+1>
					</cfloop>
					<cfif getTempData.recordcount eq testParse and getID_result.recordcount eq 0>
						<p>Number of Identifications updated: #i# (on #getCounts.c# cataloged items)</p>
						<h2 class="text-success">Success - loaded</h2>
					</cfif>
					<cfif getID_result.recordcount gt 1>
						<p>Attempted to update #i# Identifications (on #getCounts.c# cataloged items)</p>
						<h2 class="text-danger">Not loaded - these have already been loaded</h2>
					</cfif>
				<cfcatch>
					<cftransaction action="ROLLBACK">
					<h2 class="text-danger mt-4">There was a problem updating the Identifications.</h2>
					<cfquery name="getProblemData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getProblemData_result">
						SELECT institution_acronym, collection_cde,other_id_type,other_id_number,collection_object_id,scientific_name,made_date,nature_of_id,accepted_id_fg,identification_remarks,agent_1, agent_2,taxa_formula,taxon_name_id,stored_as_fg,publication_id
						FROM cf_temp_id
						WHERE key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#problem_key#">
					</cfquery>
					<h3 class="h4">Errors encountered during application are displayed one row at a time. Fix and <a href="/tools/BulkloadIdentification.cfm">start again</a>.</h3>
					<h3 class="mt-3 mb-2">
						Error loading row (<span class="text-danger">#getProblemData_result.recordcount#</span>) from the CSV: 
						<cfif len(cfcatch.detail) gt 0>
							<span class="border-bottom border-danger">
								<cfif cfcatch.detail contains "OTHER_ID_TYPE">
									Invalid OTHER_ID_TYPE; check controlled vocabulary (Help menu)
								<cfelseif cfcatch.detail contains "COLLECTION_CDE">
									COLLECTION_CDE does not match abbreviated collection (e.g., Ent, Herp, Ich, IP, IZ, Mala, Mamm, Orn, SC, or VP)
								<cfelseif cfcatch.detail contains "INSTITUTION_ACRONYM">
									INSTITUTION_ACRONYM does not match MCZ (all caps)
								<cfelseif cfcatch.detail contains "OTHER_ID_NUMBER">
									Problem with OTHER_ID_NUMBER, check to see the correct other_id_number was entered
								<cfelseif cfcatch.detail contains "MADE_DATE">
									Problem with MADE_DATE (should be in ISO format "YYYY-MM-DD")
								<cfelseif cfcatch.detail contains "unique constraint">
									Already entered; Fix and <a href="/tools/BulkloadIdentification.cfm">try again</a>.
								<cfelseif cfcatch.detail contains "COLLECTION_OBJECT_ID">
									Problem with OTHER_ID_TYPE or OTHER_ID_NUMBER (could not find collection_object_id) 
								<cfelseif cfcatch.detail contains "SCIENTIFIC_NAME">
									Problem with SCIENTIFIC_NAME 
								<cfelseif cfcatch.detail contains "publication_ID">
									Issue with PUBLICATION_ID (#cfcatch.detail#)
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
					<table class='px-0 mx-0 sortable table w-100 small table-responsive table-striped'>
						<thead>
							<tr>
								<th>institution_acronym</th>
								<th>collection_cde</th>
								<th>other_id_type</th>
								<th>other_id_number</th>
								<th>collection_object_id</th>
								<th>scientific_name</th>
								<th>made_date</th>
								<th>nature_of_id</th>
								<th>accepted_id_fg</th>
								<th>identification_remarks</th>
								<th>agent_1</th>
								<th>agent_2</th>
								<th>taxa_formula</th>
								<th>stored_as_fg</th>
								<th>publication_id</th>
							</tr>
						</thead>
						<tbody>
							<cfloop query="getProblemData">
								<tr>
									<td>#getProblemData.institution_acronym#</td>
									<td>#getProblemData.collection_cde#</td>
									<td>#getProblemData.other_id_type#</td>
									<td>#getProblemData.other_id_number#</td>
									<td>#getProblemData.collection_object_id#</td>
									<td>#getProblemData.scientific_name#</td>
									<td>#getProblemData.made_date#</td>
									<td>#getProblemData.nature_of_id#</td>
									<td>#getProblemData.accepted_id_fg#</td>
									<td>#getProblemData.identification_remarks#</td>
									<td>#getProblemData.agent_1#</td>
									<td>#getProblemData.agent_2#</td>
									<td>#getProblemData.taxa_formula#</td>
									<td>#getProblemData.stored_as_fg#</td>
									<td>#getProblemData.publication_id#</td>
								</tr>
							</cfloop>
						</tbody>
					</table>
					<cfrethrow>
				</cfcatch>
				</cftry>
			</cftransaction>
			<cfquery name="clearTempTable" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="clearTempTable_result">
				DELETE FROM cf_temp_ID 
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
		</cfoutput>
	</cfif>
</main>
<cfinclude template="/shared/_footer.cfm">
