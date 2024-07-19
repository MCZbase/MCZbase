<cfif isDefined("action") AND action is "dumpProblems">
	<cfquery name="getProblemData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		SELECT INSTITUTION_ACRONYM,COLLECTION_CDE,OTHER_ID_TYPE,OTHER_ID_NUMBER,PART_NAME,ITEM_INSTRUCTIONS,ITEM_REMARKS,ITEM_DESCRIPTION,BARCODE,SUBSAMPLE,LOAN_NUMBER,PARTID,TRANSACTION_ID
		FROM CF_TEMP_LOAN_ITEM 
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

<cfset fieldlist = "INSTITUTION_ACRONYM,COLLECTION_CDE,OTHER_ID_TYPE,OTHER_ID_NUMBER,PART_NAME,ITEM_INSTRUCTIONS,ITEM_REMARKS,ITEM_DESCRIPTION,BARCODE,SUBSAMPLE,LOAN_NUMBER,PARTID,TRANSACTION_ID">
<cfset fieldTypes = "CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_NUMBER,CF_SQL_NUMBER">
<cfset requiredfieldlist = "INSTITUTION_ACRONYM,COLLECTION_CDE,OTHER_ID_TYPE,OTHER_ID_NUMBER,PART_NAME,BARCODE,SUBSAMPLE,LOAN_NUMBER">

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
<cfset pageTitle = "Bulkload Loan Items">
<cfinclude template="/shared/_header.cfm">
<cfinclude template="/tools/component/csv.cfc" runOnce="true"><!--- for common csv testing functions --->
<cfif not isDefined("action") OR len(action) EQ 0><cfset action="entryPoint"></cfif>
<main class="container-fluid py-3 px-xl-5" id="content">
	<h1 class="h2 mt-2">Bulkload Loan Items</h1>
	<!------------------------------------------------------->
	
	<cfif #action# is "entryPoint">
		<cfoutput>
			<p>This tool is used to bulkload loan items (connect parts to a loan).</p>
			<p>The following must all be true to use this form:</p>
			<ul>
				<li>Items in the file you load are not already on loan (check part disposition)</li>
				<li>Encumbrances have been checked</li>
				<li>A loan has been created in MCZbase.</li>
				<li>Loan Item reconciled person is you (mkennedy) - automatically added</li>
				<li>Loan Item reconciled date is today (2024-07-18) - automatically added</li>
			</ul>
			<p>Upload a comma-delimited text file (csv).  Include column headings, spelled exactly as below. Additional colums will be ignored</p>
		
			<span class="btn btn-xs btn-info" onclick="document.getElementById('template').style.display='block';">View template</span>
			<div id="template" style="margin: 1rem 0;display:none;">
				<label for="templatearea" class="data-entry-label mb-1">
					Copy this header line and save it as a .csv file (or <a href="/tools/BulkloadLoanItems.cfm?action=getCSVHeader" class="font-weight-lessbold">download</a>)
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
							and table_name = 'CF_TEMP_LOAN_ITEM'
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
			<form name="agts" method="post" enctype="multipart/form-data" action="/tools/BulkloadLoanItems.cfm">
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
		<h2 class="h4">First step: Reading data from CSV file.</h2>
		<cfoutput>
		<!--- Compare the numbers of headers expected against provided in CSV file --->
		<!--- Set some constants to identify error cases in cfcatch block --->
		<cfset NO_COLUMN_ERR = "One or more required fields are missing in the header line of the csv file.">
		<cfset DUP_COLUMN_ERR = "One or more columns are duplicated in the header line of the csv file.">
		<cfset COLUMN_ERR = "Error inserting data">
		<cfset NO_HEADER_ERR = "No header line found, csv file appears to be empty.">
		<cfset TABLE_NAME = "CF_TEMP_LOAN_ITEM">
		<cftry>
			<!--- cleanup any incomplete work by the same user --->
			<cfquery name="clearTempTable" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="clearTempTable_result">
				DELETE FROM CF_TEMP_LOAN_ITEM
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
					There are #ListLen(fieldList)# columns expected in the header (of these #ListLen(requiredFieldList)# are required).
				</div>

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
						<cfset thisBit = "#rowData.get(JavaCast('int',i))#" >
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
							insert into cf_temp_loan_item
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
					<cfset extendedResult = reportExtended(foundHighCount=foundHighCount,foundHighAscii=foundHighAscii,foundMultiByte=foundMultiByte,linkTarget='/tools/BulkloadLoanItems.cfm')>	
				</cfif>
				<h3 class="mt-3">
					<cfif loadedRows EQ 0>
						Loaded no rows from the CSV file. The file appears to be just a header with no data. Fix file and <a href="/tools/BulkloadLoanItems.cfm" class="text-danger">start again</a>
					<cfelse>
						<cfif variables.size eq 1>
							Size = 1
						<cfelse>
						Successfully read #loadedRows# records from the CSV file. Next <a href="/tools/BulkloadLoanItems.cfm?action=validate" class="btn-link font-weight-lessbold">click to validate</a>.</cfif>
					</cfif>
				</h3>
			<cfcatch>
				<h3 class="mt-3">
					<strong class="text-danger">Failed to read the CSV file.</strong> Fix the errors in the file and <a href="/tools/BulkloadLoanItems.cfm" class="text-danger">start again</a>.
				</h3>
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
						<cfset extendedResult = reportExtended(foundHighCount=foundHighCount,foundHighAscii=foundHighAscii,foundMultiByte=foundMultiByte,linkTarget='/tools/BulkloadLoanItems.cfm',inHeader='yes')>	
					</cfif>
				</cfif>
				<!--- identify and provide guidance for some standard failure conditions --->
				<cfif format EQ "DEFAULT"><cfset fmt="CSV: Default Comma Separated values"><cfelse><cfset fmt="#format#"></cfif>
				<cfif Find("#NO_COLUMN_ERR#",cfcatch.message) GT 0>
					<h4 class='mb-3'>#cfcatch.message#</h4>
				<cfelseif Find("#NO_HEADER_ERR#",cfcatch.message) GT 0>
					<h4 class='mb-3'>#cfcatch.message#</h4>
				<cfelseif Find("#COLUMN_ERR#",cfcatch.message) GT 0>
					<h4 class='mb-3'>#cfcatch.message#</h4>
				<cfelseif Find("#DUP_COLUMN_ERR#",cfcatch.message) GT 0>
					<h4 class='mb-3'>#cfcatch.message#</h4>
				<cfelseif Find("IOException reading next record: java.io.IOException: (line 1) invalid char between encapsulated token and delimiter",cfcatch.message) GT 0>
					<h4 class='mb-3'>
						Unable to read headers in line 1.  Does your file actually have the format #fmt#?  Did you select CSV format for a tab delimited file?
					</h4>
				<cfelseif Find("IOException reading next record: java.io.IOException: (line 1)",cfcatch.message) GT 0>
					<h4 class='mb-3'>
						Unable to read headers in line 1.  Is your file actually have the format #fmt#?
					</h4>
					<h4 class='mb-3'>#cfcatch.message#</h4>
				<cfelseif Find("invalid char between encapsulated token and delimiter",cfcatch.message) GT 0>
					<h4 class='mb-3'>
						Does your file have an inconsitent format?  Are some lines tab delimited but others comma delimited?
					</h4>
				<cfelseif Find("IOException reading next record: java.io.IOException:",cfcatch.message) GT 0>
					<h4 class='mb-3'>
						Unable to read a record from the file.  One or more lines may not be consistent with the specified format #fmt#
					</h4>
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
			<cfquery name="getTypes" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT *
				FROM 
					cf_temp_LOAN_ITEM
				WHERE 
					username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfloop query="getTypes">
				<cfif #other_id_type# is "catalog number">
					<cfquery name="collObj" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						UPDATE cf_temp_loan_item set PARTID = 
						(
							select
								specimen_part.collection_object_id
							from
								cataloged_item,
								collection,
								specimen_part,
								coll_object,
								(select collection_object_id, container_id from COLL_OBJ_CONT_HIST where CURRENT_CONTAINER_FG = 1) ch,
								CONTAINER c,
								container pc
							where
								cataloged_item.collection_id = collection.collection_id and
								cataloged_item.collection_object_id = specimen_part.derived_from_cat_item and
								specimen_part.collection_object_id = coll_object.collection_object_id and
								collection.institution_acronym = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#INSTITUTION_ACRONYM#"> and
								collection.collection_cde = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#COLLECTION_CDE#"> and
								part_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#PART_NAME#"> and
								cat_num = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#OTHER_ID_NUMBER#"> and
								coll_obj_disposition != 'on loan' and
								sampled_from_obj_id is null and
								specimen_part.collection_object_id = ch.COLLECTION_OBJECT_ID(+) and
								ch.CONTAINER_ID = C.CONTAINER_ID(+) and
								C.PARENT_CONTAINER_ID = PC.CONTAINER_ID(+) and
								PC.barcode = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#BARCODE#">
							)
						where username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.USERNAME#">
						and key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#key#">
					</cfquery>
				<cfelse>
					<cfquery name="collObj" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						UPDATE cf_temp_loan_item set PARTID = (
							select
								specimen_part.collection_object_id
							from
								cataloged_item,
								collection,
								specimen_part,
								coll_object,
								coll_obj_other_id_num,
								(select collection_object_id, container_id from COLL_OBJ_CONT_HIST where CURRENT_CONTAINER_FG = 1) ch,
								CONTAINER c,
								container pc
							where
								cataloged_item.collection_id = collection.collection_id and
								cataloged_item.collection_object_id = coll_obj_other_id_num.collection_object_id and
								cataloged_item.collection_object_id = specimen_part.derived_from_cat_item and
								specimen_part.collection_object_id = coll_object.collection_object_id and
								collection.institution_acronym = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#INSTITUTION_ACRONYM#"> 
							and
								collection.collection_cde = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#COLLECTION_CDE#"> and
								part_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#PART_NAME#"> and
								display_value = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#OTHER_ID_NUMBER#"> and
								other_id_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#OTHER_ID_TYPE#"> and
								coll_obj_disposition != 'on loan' and
								sampled_from_obj_id  is null
								specimen_part.collection_object_id = ch.COLLECTION_OBJECT_ID(+) and
								ch.CONTAINER_ID = C.CONTAINER_ID(+) and
								C.PARENT_CONTAINER_ID = PC.CONTAINER_ID(+) and
								PC.barcode = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#BARCODE#">
							)
						where username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.USERNAME#">
						and key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#key#">
					</cfquery>
				</cfif>
			</cfloop>
			<cfset key = ''>
			<cfset i = 1>
			<cfquery name="getTempData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT *
				FROM 
					CF_TEMP_LOAN_ITEM
				WHERE 
					username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfloop query="getTempData">
				<cfquery name="loanID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					update
						cf_temp_loan_item
					set
						transaction_id= (
							select
								transaction_id
							from
								loan
							where
								loan_number = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.loan_number#">
						)
					where username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
					and key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#key#"> 
				</cfquery>
			</cfloop>
			<cfloop list="#requiredfieldlist#" index="requiredField">
				<cfquery name="checkRequired" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE cf_temp_loan_item
					SET 
						status = concat(nvl2(status, status || '; ', ''),'#requiredField# is missing')
					WHERE #requiredField# is null
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
			</cfloop>
			<cfquery name="defDescr" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				update
					cf_temp_loan_item
					set (ITEM_DESCRIPTION) = 
					(
						select collection.collection_cde || ' ' || cat_num || ' ' || part_name
						from
						cataloged_item,
						collection,
						specimen_part
						where
						specimen_part.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_varchar" value="#getTempData.PARTID#"> and
						specimen_part.derived_from_cat_item = cataloged_item.collection_object_id and
						cataloged_item.collection_id = collection.collection_id
					)
				where ITEM_DESCRIPTION IS NULL 
				AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT INSTITUTION_ACRONYM,COLLECTION_CDE,OTHER_ID_TYPE,OTHER_ID_NUMBER,PART_NAME,ITEM_INSTRUCTIONS,ITEM_REMARKS,ITEM_DESCRIPTION,BARCODE,SUBSAMPLE,LOAN_NUMBER,PARTID,STATUS,TRANSACTION_ID,USERNAME
				FROM 
					cf_temp_LOAN_ITEM
				WHERE 
					username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="pf" dbtype="query">
				SELECT count(*) c 
				FROM data 
				WHERE status is not null
			</cfquery>
			<h3 class="mt-3">
				<cfif pf.c gt 0>
					There is a problem with #pf.c# of #data.recordcount# row(s). See the STATUS column. (<a href="/tools/BulkloadLoanItems.cfm?action=dumpProblems">download</a>). Fix the problems in the data and <a href="/tools/BulkloadLoanItems.cfm" class="text-danger">start again</a>.
				<cfelse>
					<span class="text-success">Validation checks passed</span>. Look over the table below and <a href="/tools/BulkloadLoanItems.cfm?action=load" class="btn-link font-weight-lessbold">click to continue</a> if it all looks good or <a href="/tools/BulkloadLoanItems.cfm" class="text-danger">start again</a>.
				</cfif>
			</h3>
			<table class='sortable px-0 mx-0 table small table-responsive table-striped w-100'>
				<thead>
					<tr>
						<th>BULKLOADING&nbsp;STATUS</th>
						<th>INSTITUTION_ACRONYM</th>
						<th>COLLECTION_CDE</th>
						<th>OTHER_ID_TYPE</th>
						<th>OTHER_ID_NUMBER</th>
						<th>PART_NAME</th>
						<th>ITEM_INSTRUCTIONS</th>
						<th>ITEM_REMARKS</th>
						<th>ITEM_DESCRIPTION</th>
						<th>BARCODE</th>
						<th>SUBSAMPLE</th>
						<th>LOAN_NUMBER</th>
						<th>PARTID</th>
						<th>TRANSACTION_ID</th>
					</tr>
				<tbody>
					<cfloop query="data">
						<tr>
							<td><cfif len(data.status) eq 0>Cleared to load<cfelse><strong>#data.status#</strong></cfif></td>
							<td>#data.INSTITUTION_ACRONYM#</td>
							<td>#data.COLLECTION_CDE#</td>
							<td>#data.OTHER_ID_TYPE#</td>
							<td>#data.OTHER_ID_NUMBER#</td>
							<td>#data.PART_NAME#</td>
							<td>#data.ITEM_INSTRUCTIONS#</td>
							<td>#data.ITEM_REMARKS#</td>
							<td>#data.ITEM_DESCRIPTION#</td>
							<td>#data.BARCODE#</td>
							<td>#data.SUBSAMPLE#</td>
							<td>#data.LOAN_NUMBER#</td>
							<td>#data.PARTID#</td>
							<td>#data.TRANSACTION_ID#</td>
						</tr>
					</cfloop>
				</tbody>
			</table>
		</cfoutput>
	</cfif>
	<!-------------------------------------------------------------------------------------------->

	<!-------------------------------------------------------------------------------------------->
	<cfif #action# is "load">
	<cfoutput>
		<cfquery name="getTempData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			select INSTITUTION_ACRONYM,COLLECTION_CDE,OTHER_ID_TYPE,OTHER_ID_NUMBER,PART_NAME,ITEM_INSTRUCTIONS,ITEM_REMARKS,ITEM_DESCRIPTION,BARCODE,SUBSAMPLE,LOAN_NUMBER,PARTID,TRANSACTION_ID,USERNAME,STATUS from cf_temp_loan_item
		</cfquery>
		<cftransaction>
			<cfloop query="getTempData">
				<cfif subsample is "yes">
					<cfquery name="nid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						select sq_collection_object_id.nextval nid from dual
					</cfquery>
					<cfset thisPartId=nid.nid>
					<cfquery name="makeSubsampleObj" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						INSERT INTO coll_object (
							COLLECTION_OBJECT_ID,
							COLL_OBJECT_TYPE,
							ENTERED_PERSON_ID,
							COLL_OBJECT_ENTERED_DATE,
							LAST_EDITED_PERSON_ID,
							COLL_OBJ_DISPOSITION,
							LOT_COUNT,
							CONDITION,
							FLAGS
						) (
							select
								#thisPartId#,
								'SS',
								#session.myAgentId#,
								sysdate,
								NULL,
								'on loan',
								lot_count,
								condition,
								flags
							from
								coll_object
							where
								collection_object_id = #PARTID#
						)
					</cfquery>
					<cfquery name="makeSubsample" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						INSERT INTO specimen_part (
							COLLECTION_OBJECT_ID,
							PART_NAME,
							PRESERVE_METHOD,
							DERIVED_FROM_cat_item,
							sampled_from_obj_id
						) ( 
							select
								#thisPartId#,
								part_name,
								PRESERVE_METHOD,
								DERIVED_FROM_cat_item,
								#PARTID#
							FROM
								specimen_part
							WHERE
								collection_object_id = #PARTID#
						)
					</cfquery>
				<cfelse>
					<cfset thisPartId=#PARTID#>
					<cfquery name="updateDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						update coll_object set 
							coll_obj_disposition = 'on loan'
						where
							collection_object_id ='#thisPartId#'
					</cfquery>
				</cfif>
				<cfquery name="move" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					INSERT INTO loan_item (
						collection_object_id,
						RECONCILED_BY_PERSON_ID,
						reconciled_date,
						<cfif len(#getTempData.ITEM_INSTRUCTIONS#) gt 0>
							item_instructions,
						</cfif>
						<cfif len(#getTempData.ITEM_REMARKS#) gt 0>
							LOAN_ITEM_REMARKS,
						</cfif>
						item_descr,
						transaction_id
						) VALUES (
						
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#thisPartID#">,
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#session.myAgentId#">,
						sysdate,
						<cfif len(#getTempData.ITEM_INSTRUCTIONS#) gt 0>
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ITEM_INSTRUCTIONS#">,
						</cfif>
						<cfif len(#getTempData.ITEM_REMARKS#) gt 0>
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ITEM_REMARKS#">,
						</cfif>
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ITEM_DESCRIPTION#">,
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#TRANSACTION_ID#">
						)
				</cfquery>
			</cfloop>
			</cftransaction>
			
			<cfquery name="clearTempTable" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="clearTempTable_result">
				DELETE FROM cf_temp_LOAN_ITEM
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
		</cfoutput>
	</cfif>
</main>
<cfinclude template="/shared/_footer.cfm">