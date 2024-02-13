<!--- tools/bulkloadAttributes.cfm add attributes to specimens in bulk.

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
		SELECT institution_acronym,collection_cde,other_id_type,other_id_number,attribute,attribute_value,attribute_units,attribute_date,attribute_meth,determiner,remarks,status
		FROM cf_temp_attributes 
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
<cfset fieldlist = "institution_acronym,collection_cde,other_id_type,other_id_number,attribute,attribute_value,attribute_units,attribute_date,attribute_meth,determiner,remarks">
<cfset fieldTypes ="CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR">
<cfset requiredfieldlist = "institution_acronym,collection_cde,other_id_type,other_id_number,attribute,attribute_value,attribute_date,determiner">

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
<cfset pageTitle = "Bulkload Attributes">
<cfinclude template="/shared/_header.cfm">
<cfif not isDefined("action") OR len(action) EQ 0><cfset action="nothing"></cfif>
<main class="container-fluid px-5 py-3" id="content">
	<h1 class="h2 mt-2">Bulkload Attributes</h1>
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
					<cfif listContains(requiredfieldlist,field,",")>
						<cfset class="text-danger">
					<cfelse>
						<cfset class="text-dark">
					</cfif>
					<li class="#class#">#field#</li>
				</cfloop>
			</ul>
			<cfform name="atts" method="post" enctype="multipart/form-data" action="/tools/BulkloadAttributes.cfm">
				<input type="hidden" name="action" value="getFile">
				<cfinput type="file" name="FiletoUpload" id="fileToUpload" size="45" >
				<label for="cSet">Character Set:</label> 
				<select name="cSet" id="cSet" required class="reqdClr">
					<option selected></option>
					<option value="utf-8" >utf-8</option>
					<option value="windows-1252">windows-1252</option>
					<option value="MacRoman">MacRoman</option>
					<option value="utf-16">utf-16</option>
					<option value="unicode">unicode</option>
				</select>
				<input type="submit" value="Upload this file" class="btn btn-primary btn-xs">
			</cfform>
		</cfoutput>
	</cfif>
	<!------------------------------------------------------->
<!---as we can't use csvFormat.withHeader(), we can not match columns by name, we are forced to do so by number 
			TODO: to put the columns into fieldList order, map actualColumnNumber to fieldListColumnNumber  
			TODO: Test for multibyte characters 
			TODO: Create insert statement --->
	<cfif #action# is "getFile">
		<h2 class="h3">First step: Reading data from CSV file.</h2>
		<h4>Compare the numbers of headers expected against provided in CSV file</h4>
		<!--- Set some constants to identify error cases in cfcatch block --->
		<cfset NO_COLUMN_ERR = "One or more required fields are missing in the header line of the csv file.">
		<cfset COLUMN_ERR = "Error inserting data">
		<cfoutput>
			<cftry>
				<!--- Proof of concept parsing CSV with Java using Commons CSV library included with coldfusion so that columns with comma delimeters will be separated properly --->
				<cfset fileProxy = CreateObject("java","java.io.File") >
				<cfobject type="Java" name="csvFormat" class="org.apache.commons.csv.CSVFormat" >
				<cfobject type="Java" name="csvParser"  class="org.apache.commons.csv.CSVParser" >
				<cfobject type="Java" name="csvRecord"  class="org.apache.commons.csv.CSVRecord" >
				<cfobject type="java" class="java.io.FileReader" name="fileReader">	
				
				<cfobject type="Java" name="javaCharset"  class="java.nio.charset.Charset" >
				<cfobject type="Java" name="standardCharsets"  class="java.nio.charset.StandardCharsets" >
				<cfset tempFile = fileProxy.init(JavaCast("string",#FiletoUpload#)) >
				<cfset tempFileInputStream = CreateObject("java","java.io.FileInputStream").Init(#tempFile#) >
				<!---// Create a FileReader object--->
				<cfset fileReader = CreateObject("java","java.io.FileReader").Init(#tempFile#) >
						
				<!--- we can't use the withHeader() method from coldfusion, as it is overloaded, and with no parameters provides coldfusion no means to pick the correct method --->
				<!--- cfset defaultFormat = csvFormat.DEFAULT.withHeader() --->
				<cfset defaultFormat = csvFormat.DEFAULT >
				<!---// Create a CSVParser using the FileReader and CSVFormat--->
				<cfset csvParser = CSVFormat.DEFAULT.parse(fileReader)>
		
				<!--- TODO: Select charset based on cSet variable from user --->
				<cfset javaSelectedCharset = standardCharsets.UTF_8 >
				<cfset records = CSVParser.parse(#tempFileInputStream#,#javaSelectedCharset#,#defaultFormat#)>
				
				<cfset iterator = records.iterator()>
				<!--- Obtain the first line of the file as the header line --->
				<cfset headers = iterator.next()>
				<cfset size = headers.size()>
			
				<cfset items = records.getRecordNumber()>
				<cfscript>
					
				</cfscript>
			

<!---				<cfif headers.get(0) is not null><cfset columnOne = headers.get(0)><cfelse>columnOne missing</cfif>
				<cfif isDefined(headers.get(1))><cfset columnTwo = headers.get(1)><cfelse>columnTwo missing</cfif>
				<cfif isDefined(headers.get(2))><cfset columnThree = headers.get(2)><cfelse>columnThree missing</cfif>
				<cfif isDefined(headers.get(3))><cfset columnFour = headers.get(3)><cfelse>columnFour missing</cfif>
				<cfif isDefined(headers.get(4))><cfset columnFive = headers.get(4)><cfelse>columnFive missing</cfif>
				<cfif isDefined(headers.get(5))><cfset columnSix = headers.get(5)><cfelse>columnSix missing</cfif>
				<cfif isDefined(headers.get(6))><cfset columnSeven = headers.get(6)><cfelse>columnSeven missing</cfif>
				<cfif isDefined(headers.get(7))><cfset columnEight = headers.get(7)><cfelse>columnEight missing</cfif>
				<cfif isDefined(headers.get(8))><cfset columnNine = headers.get(8)><cfelse>columnNine missing</cfif>
				<cfif isDefined(headers.get(9))><cfset columnTen = headers.get(9)><cfelse>columnTen missing</cfif>
				<cfif isDefined(headers.get(10))><cfset columnEleven = headers.get(10)><cfelse>columnEleven missing</cfif>--->
						<!--- number of colums actually found --->
				
			<!---	#columnSeven#--->
				<div class="col-12 my-4">
				<h3 class="h4">Found <cfdump var="#headers.size()#"> matching columns in header of csv file (Green).</h3>
					
				<cfscript>
					data = [
						{field:"institution_acronym", required:"yes"},
						{field:"collection_cde", required:"yes"},
						{field:"other_id_type", required:"yes"},
						{field:"other_id_number", required:"yes"},
						{field:"attribute", required:"yes"},
						{field:"attribute_value", required:"yes"},
						{field:"attribute_units", required:"no"},
						{field:"attribute_date", required:"yes"},
						{field:"attribute_meth", required:"no"},
						{field:"determiner", required:"yes"},
						{field:"remarks", required:"no"}
					];
				
	
				</cfscript>			
				<h3 class="h4">There are <cfdump var="#data.size()#"> columns possible for attribute headers (black and red). (8 are required - RED)</h3>
			</div>
					<cfset fieldlist2 = "institution_acronym,collection_cde,other_id_type,other_id_number,attribute,attribute_value,attribute_units,attribute_date,attribute_meth,determiner,remarks">
		
<!---			<cfscript>
					i=0
					do {
					WriteOutput(headers.get("institution_acronym") & 'true');
					i++
					} while (headers.get("institution_acronym") == data.get("institution_acronym") & i>10);
				</cfscript>--->
				<!---Expected and required headers; red = required; black = expected;--->
				<ul class="list-group list-group-horizontal">
					<cfloop array="#data#" index="i">
						<cfoutput>
							<li class="list-group-item h5 border <cfif #i.required# eq "yes"> text-danger</cfif>" style="width:140px;">#i.field# </li>
						
						</cfoutput>
					</cfloop>
				</ul>
				<ul class="list-group list-group-horizontal">
				<cfloop index="i" from="0" to="#headers.size() - 1#">
					<li class="text-success list-group-item h5 border" style="width: 140px;"><cfset externalList = #headers.get(JavaCast("int",i))#>#headers.get(JavaCast("int",i))#</li>
				</cfloop>
				</ul>
				<cfscript>
				stringy = headers.get("attribute");
				</cfscript>

				<!--- cleanup any incomplete work by the same user --->
				<cfquery name="clearTempTable" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="clearTempTable_result">
					DELETE FROM cf_temp_attributes 
					WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>

				
		<!---		<cfset institution_acronym_exists = false>
				<cfset collection_cde_exists = false>
				<cfset other_id_type_exists = false>
				<cfset other_id_number_exists = false>
				<cfset attribute_exists = false>
				<cfset attribute_value_exists = false>
				<cfset attribute_date_exists = false>
				<cfset determiner_exists = false>
				<cfloop from="0" to="#headers.size() - 1#" index="items">
					<cfset thisheader = #iterator#>
					<cfif ucase(thisheader) EQ 'institution_acronym'><cfset institution_acronym_exists=true></cfif>
					<cfif ucase(thisheader) EQ 'collection_cde'><cfset collection_cde_exists=true></cfif>
					<cfif ucase(thisheader) EQ 'other_id_type'><cfset other_id_type_exists=true></cfif>
					<cfif ucase(thisheader) EQ 'other_id_number'><cfset other_id_number_exists=true></cfif>
					<cfif ucase(thisheader) EQ 'attribute'><cfset attribute_exists=true></cfif>
					<cfif ucase(thisheader) EQ 'attribute_value'><cfset attribute_value_exists=true></cfif>
					<cfif ucase(thisheader) EQ 'attribute_date'><cfset attribute_date_exists=true></cfif>
					<cfif ucase(thisheader) EQ 'determiner'><cfset determiner_exists=true></cfif>
				</cfloop>
				<cfif not (institution_acronym_exists AND collection_cde_exists AND other_id_type_exists AND other_id_number_exists AND attribute_exists AND attribute_value_exists AND attribute_date_exists AND determiner_exists)>
					<cfset message = "something is missing">
					<cfif not institution_acronym_exists><cfset message = "#message# institution_acronym is missing."></cfif>
					<cfif not collection_cde_exists><cfset message = "#message# collection_cde is missing."></cfif>
					<cfif not other_id_type_exists><cfset message = "#message# other_id_type is missing."></cfif>
					<cfif not other_id_number_exists><cfset message = "#message# other_id_number is missing."></cfif>
					<cfif not attribute_exists><cfset message = "#message# attribute is missing."></cfif>
					<cfif not attribute_value_exists><cfset message = "#message# attribute_value is missing."></cfif>
					<cfif not attribute_date_exists><cfset message = "#message# attribute_date is missing."></cfif>
					<cfif not determiner_exists><cfset message = "#message# determiner is missing."></cfif>
					<cfthrow message="#message#">
				</cfif>--->
		<!---		<cfset colNames="">
				<cfset loadedRows = 0>
				<cfset foundHighCount = 0>
				<cfset foundHighAscii = "">
				<cfset foundMultiByte = "">--->
				<!--- get the headers from the first row of the input, then iterate through the remaining rows inserting the data into the temp table. --->
				<!---<cfloop from="1" to ="#headers.size()#" index="row">--->	
					<!--- obtain the values in the current row --->
			<!---		<cfset colVals="">
					<cfloop from="1" to ="#headers.size()#" index="col">
						<cfset thisBit=#headers#>
						<cfif REFind("[^\x00-\x7F]",thisBit) GT 0>--->
							<!--- high ASCII --->
					<!---		<cfif foundHighCount LT 6>
								<cfset foundHighAscii = "#foundHighAscii# <li class='text-danger font-weight-bold'>#thisBit#</li>">---><!--- " --->
								<!---<cfset foundHighCount = foundHighCount + 1>
							</cfif>
						<cfelseif REFind("[\xc0-\xdf][\x80-\xbf]",thisBit) GT 0>--->
							<!--- multibyte --->
						<!---	<cfif foundHighCount LT 6>
								<cfset foundMultiByte = "#foundMultiByte# <li class='text-danger font-weight-bold'>#thisBit#</li>">---><!--- " --->
					<!---			<cfset foundHighCount = foundHighCount + 1>
							</cfif>
						</cfif>
						<cfif #row# is 1>
							<cfset colNames="#colNames#,#thisBit#">
						<cfelse>--->
							<!--- quote values to ensure all columns have content, will need to strip out later to insert values --->
						<!---	<cfset colVals="#colVals#,'#thisBit#'">
						</cfif>
					</cfloop>
					<cfif #row# is 1>--->
						<!--- first row, obtain column headers --->
						<!--- strip off the leading separator --->
					<!---	<cfset colNames=replace(colNames,",","","first")>--->
						<!---<cfset colNameArray = listToArray(ucase(colNames))>---><!--- the list of columns/fields found in the input file --->
						<!---<cfset fieldArray = listToArray(ucase(fieldlist))>---><!--- the full list of fields --->
						<!---<cfset typeArray = listToArray(fieldTypes)>---><!--- the types for the full list of fields --->
<!---						<h3 class="h4">Found #arrayLen(colNameArray)# matching columns in header of csv file.</h3>
						<ul class="">
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
					<cfelse>--->
						<!--- subsequent rows, data --->
						<!--- strip off the leading separator --->
				<!---		<cfset colVals=replace(colVals,",","","first")>
						<cfset colValArray=listToArray(colVals)>
						<cftry>--->
							<!--- construct insert for row with a line for each entry in fieldlist using cfqueryparam if column header is in fieldlist, otherwise using null --->
<!---							<cfquery name="insert" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="insert_result">
								insert into cf_temp_attributes
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
						<cfcatch>--->
							<!--- identify the problematic row --->
<!---							<cfset error_message="#COLUMN_ERR# from line #row# in input file.  <br>Header:[#colNames#] <br>Row:[#colVals#] <br>Error: #cfcatch.message#">---><!--- " --->
							<!---<cfif isDefined("cfcatch.queryError")>
								<cfset error_message = "#error_message# #cfcatch.queryError#">
							</cfif>
							<cfthrow message = "#error_message#">
						</cfcatch>
						</cftry>
					</cfif>
				</cfloop>--->
				<cfcatch>
					This is an Error message
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
					other_id_type, key
				FROM 
					cf_temp_attributes
				WHERE 
					username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfset i= 1>
			<cfloop query="getTempTableTypes">
				<!--- For each row, set the target collection_object_id --->
				<cfif getTempTableTypes.other_id_type eq 'catalog number'>
					<!--- either based on catalog_number --->
					<cfquery name="getCID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						UPDATE
							cf_temp_attributes
						SET
							collection_object_id = (
								select collection_object_id 
								from cataloged_item 
								where cat_num = cf_temp_attributes.other_id_number and collection_cde = cf_temp_attributes.collection_cde
							),
							status = null
						WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
							and key = <cfqueryparam cfsqltype="CF_SQL_decimal" value="#getTempTableTypes.key#"> 
					</cfquery>
				<cfelse>
					<!--- or on specified other identifier --->
					<cfquery name="getCID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						UPDATE
							cf_temp_attributes
						SET
							collection_object_id= (
								select cataloged_item.collection_object_id from cataloged_item,coll_obj_other_id_num 
								where coll_obj_other_id_num.other_id_type = cf_temp_attributes.other_id_type 
								and cataloged_item.collection_cde = cf_temp_attributes.collection_cde 
								and display_value= cf_temp_attributes.other_id_number
								and cataloged_item.collection_object_id = coll_obj_other_id_num.COLLECTION_OBJECT_ID
							),
							status = null
						WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
							and key = <cfqueryparam cfsqltype="CF_SQL_decimal" value="#getTempTableTypes.key#"> 
					</cfquery>
				</cfif>
			</cfloop>
			<!--- obtain the information needed to QC each row --->
			<cfquery name="getTempTableQC" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT 
					attribute_date, key, collection_cde, attribute
				FROM 
					cf_temp_attributes
				WHERE 
					username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfloop query="getTempTableQC">
				<!--- For each row, evaluate the date against expectations and provide an error message --->
				<!---DATE ERROR MESSAGE--->
				<cfset attDate = isDate(getTempTableQC.attribute_date)>
				<cfif #attdate# eq 'NO'>
					<cfquery name="flagDateProblem" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						UPDATE
							cf_temp_attributes
						SET 
							status = concat(nvl2(status, status || '; ', ''),'invalid attribute_date')
						WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#"> 
							and key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableQC.key#"> 
					</cfquery>	
				</cfif>
				<!--- for each row, evaluate the attribute against expectations and provide an error message --->
				<cfquery name="flatAttributeProblems" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="flatAttributeProblems_result">
					UPDATE cf_temp_attributes
					SET
						status = concat(nvl2(status, status || '; ', ''),'invalid attribute for collection_cde ' || collection_cde)
					WHERE 
						attribute IS NOT NULL
						AND attribute NOT IN (
							SELECT attribute_type 
							FROM ctattribute_type 
							WHERE collection_cde = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempTableQC.collection_cde#">
						)
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						AND key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableQC.key#">
				</cfquery>
				<cfquery name="ctAttribute_code_tables" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select upper(value_code_table) as value_code_table, upper(units_code_table) as units_code_table
					FROM ctattribute_code_tables
					WHERE attribute_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempTableQC.attribute#">
				</cfquery>
				<cfloop query="ctAttribute_code_tables">
					<!--- assumption, if an attribute has an entry in attribute_code_tables and the units_code_table there is blank, then 
							the attribute does not take units --->
					<!--- however, an entry in ctattribute_type without an entry in ctattribute_code_tables make take units. --->
					<cfif len(ctAttribute_code_tables.units_code_table) EQ 0>
						<cfquery name="flagNotNullUnits" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							UPDATE cf_temp_attributes
							SET 
								status = concat(nvl2(status, status || '; ', ''),'attribute inconsistent with units')
							WHERE 
								attribute_units is not null
								AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
								AND key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableQC.key#">
						</cfquery>
					<cfelse>
						<cfquery name="flagNullUnits" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							UPDATE cf_temp_attributes
							SET 
								status = concat(nvl2(status, status || '; ', ''),'attribute requires units from controlled vocabulary')
							WHERE 
								attribute_units is null
								AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
								AND key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableQC.key#">
						</cfquery>
						<cftry>
						<cfquery name="flatWrongUnits" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							UPDATE cf_temp_attributes
							SET 
								status = concat(nvl2(status, status || '; ', ''),'attribute_units not in controlled vocabulary #ctAttribute_code_tables.units_code_table#')
							WHERE 
								attribute_units not in (
									<cfif ctAttribute_code_tables.units_code_table EQ "CTLENGTH_UNITS">
										select LENGTH_UNITS from CTLENGTH_UNITS
									<cfelseif ctAttribute_code_tables.units_code_table EQ "CTWEIGHT_UNITS">
										select WEIGHT_UNITS from CTWEIGHT_UNITS
									<cfelseif ctAttribute_code_tables.units_code_table EQ "CTNUMERIC_AGE_UNITS">
										select NUMERIC_AGE_UNITS from CTNUMERIC_AGE_UNITS
									<cfelseif ctAttribute_code_tables.units_code_table EQ "CTAREA_UNITS">
										select AREA_UNITS from CTAREA_UNITS
									<cfelseif ctAttribute_code_tables.units_code_table EQ "CTTHICKNESS_UNITS">
										select THICKNESS_UNITS from CTTHICKNESS_UNITS
									<cfelseif ctAttribute_code_tables.units_code_table EQ "CTANGLE_UNITS">
										<!--- yes the field name is inconsistent with the table --->
										select LENGTH_UNITS from CTANGLE_UNITS
									<cfelseif ctAttribute_code_tables.units_code_table EQ "CTTISSUE_VOLUME_UNITS">
										select TISSUE_VOLUME_UNITS from CTTISSUE_VOLUME_UNITS
									</cfif>
								)
								AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
								AND key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableQC.key#">
						</cfquery>
						<cfcatch>
						</cfcatch>
							<!--- silently fail if another units table is added to the database but isn't added here. --->
						</cftry>
					</cfif>
					<cfif len(ctAttribute_code_tables.value_code_table) GT 0>
						<cftry>
						<cfquery name="flatWrongUnits" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							UPDATE cf_temp_attributes
							SET 
								status = concat(nvl2(status, status || '; ', ''),'attribute_value not in controlled vocabulary #ctAttribute_code_tables.value_code_table#')
							WHERE 
								attribute_value not in (
									<cfif ctAttribute_code_tables.value_code_table EQ "CTSEX_CDE">
										select SEX_CDE from CTSEX_CDE
										where collection_cde = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempTableQC.collection_cde#">
									<cfelseif ctAttribute_code_tables.value_code_table EQ "CTAGE_CLASS">
										select AGE_CLASS from CTAGE_CLASS
										where collection_cde = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempTableQC.collection_cde#">
									<cfelseif ctAttribute_code_tables.value_code_table EQ "CTASSOCIATED_GRANTS">
										select ASSOCIATED_GRANT from CTASSOCIATED_GRANTS
									<cfelseif ctAttribute_code_tables.value_code_table EQ "CTCOLLECTION_FULL_NAMES">
										select COLLECTION from CTCOLLECTION_FULL_NAMES
									</cfif>
								)
								AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
								AND key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempTableQC.key#">
						</cfquery>
						<cfcatch>
						</cfcatch>
							<!--- silently fail if another value code table is added to the database but isn't added here. --->
						</cftry>
					</cfif>
				</cfloop>
			</cfloop>
			<!--- qc checks independent of attributes, includes presence of values in required columns --->
			<cfloop list="#requiredfieldlist#" index="requiredField">
				<cfquery name="checkRequired" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					UPDATE cf_temp_attributes
					SET 
						status = concat(nvl2(status, status || '; ', ''),'#requiredField# is missing')
					WHERE #requiredField# is null
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
			</cfloop>
			<!---INSTITUTION_ACRONYM--->			
			<cfquery name="m1b" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE cf_temp_attributes
				SET 
					status = concat(nvl2(status, status || '; ', ''),'INSTIUTION_ACRONYM is not "MCZ" (check case)')
				WHERE institution_acronym <> 'MCZ'
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<!---COLLECTION_CDE--->	
			<!--- concat before other messages, as it is cause for unknown attribute for collection etc --->
			<cfquery name="flagUnknownCollectionCde" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE cf_temp_attributes
				SET 
					status = concat('Invalid collection_cde: ' || collection_cde, nvl2(status, '; ' || status, ''))
				WHERE collection_cde not in (select collection_cde from collection) 
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<!--- found a collection object --->
			<cfquery name="flagNoCollectionObject" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE cf_temp_attributes
				SET 
					status = concat(nvl2(status, status || '; ', ''),' no match to a cataloged item on [' || other_id_type || ']=[' || other_id_number || '] in collection ' || collection_cde)
				WHERE collection_object_id IS NULL
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>

			<!--- Determiner Agent --->
			<cfquery name="setAgentIDForDetermier" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE cf_temp_attributes
				SET determined_by_agent_id= (select agent_id from preferred_agent_name where agent_name = cf_temp_attributes.determiner)
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="flagEmptyAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE cf_temp_attributes
				SET 
					status = concat(nvl2(status, status || '; ', ''), 'agent value (preferred name) is missing in DETERMINER column')
				WHERE determiner is null
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="flagNotMatchedAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE cf_temp_attributes
				SET 
					status = concat(nvl2(status, status || '; ', ''), 'unknown agent (no match to preferred name) in DETERMINER column')
				WHERE determiner IS NOT NULL
					AND determined_by_agent_id IS NULL
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>

			<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT institution_acronym,collection_cde,other_id_type,other_id_number,attribute,attribute_value,attribute_units,attribute_date, attribute_meth,determiner,remarks,status
				FROM cf_temp_attributes
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				ORDER BY key
			</cfquery>
			
			<cfquery name="pf" dbtype="query">
				SELECT count(*) c 
				FROM data 
				WHERE status is not null
			</cfquery>
			<cfif pf.c gt 0>
				<h2>
					There is a problem with #pf.c# of #data.recordcount# row(s). See the STATUS column. (<a href="/tools/BulkloadAttributes.cfm?action=dumpProblems">download</a>).
				</h2>
				<h3>
					Fix the problem(s) noted in the status column and <a href="/tools/BulkloadAttributes.cfm">start again</a>.
				</h3>
			<cfelse>
				<h2>
					Validation checks passed. Look over the table below and <a href="/tools/BulkloadAttributes.cfm?action=load">click to continue</a> if it all looks good.
				</h2>
			</cfif>
			<table class='sortable table table-responsive table-striped d-xl-table w-100'>
				<thead>
					<tr>
						<th>Row</th>
						<th>STATUS</th>
						<th>INSTITUTION_ACRONYM</th>
						<th>COLLECTION_CDE</th>
						<th>OTHER_ID_TYPE</th>
						<th>OTHER_ID_NUMBER</th>
						<th>ATTRIBUTE</th>
						<th>ATTRIBUTE_VALUE</th>
						<th>ATTRIBUTE_UNITS</th>
						<th>ATTRIBUTE_DATE</th>
						<th>ATTRIBUTE_METH</th>
						<th>DETERMINER</th>
						<th>REMARKS</th>
					</tr>
				<tbody>
					<cfset i=1>
					<cfloop query="data">
						<tr>
							<td>#i#</td>
							<td><strong>#STATUS#</strong></td>
							<td>#data.INSTITUTION_ACRONYM#</td>
							<td>#data.COLLECTION_CDE#</td>
							<td>#data.OTHER_ID_TYPE#</td>
							<td>#data.OTHER_ID_NUMBER#</td>
							<td>#data.ATTRIBUTE#</td>
							<td>#data.ATTRIBUTE_VALUE#</td>
							<td>#data.ATTRIBUTE_UNITS#</td>
							<td>#data.ATTRIBUTE_DATE#</td>
							<td>#data.ATTRIBUTE_METH#</td>
							<td>#data.DETERMINER#</td>
							<td>#data.REMARKS#</td>
						</tr>
						<cfset i=i+1>
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
					SELECT * FROM cf_temp_attributes
					WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cfquery name="getCounts" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT count(distinct collection_object_id) ctobj FROM cf_temp_attributes
					WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
			<cftry>
					<cfset attributes_updates = 0>
					<cfset attributes_updates1 = 0>
					<cfif getTempData.recordcount EQ 0>
						<cfthrow message="You have no rows to load in the attributes bulkloader table (cf_temp_attributes).  <a href='/tools/BulkloadAttributes.cfm'>Start over</a>"><!--- " --->
					</cfif>
					<cfloop query="getTempData">
						<cfset problem_key = getTempData.key>
						<cfquery name="updateAttributes" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="updateAttributes_result">
							INSERT into attributes (
							COLLECTION_OBJECT_ID,
							ATTRIBUTE_TYPE,
							ATTRIBUTE_VALUE,
							ATTRIBUTE_UNITS,
							DETERMINED_DATE,
							DETERMINATION_METHOD,
							DETERMINED_BY_AGENT_ID,
							ATTRIBUTE_REMARK
							)VALUES(
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#collection_object_id#">,
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#attribute#">,
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#attribute_value#">,
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#attribute_units#">, 
							<cfqueryparam cfsqltype="CF_SQL_DATE" value="#attribute_date#">,
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#attribute_meth#">,
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#determined_by_agent_id#">,
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#remarks#">
							)
						</cfquery>
						<cfquery name="updateAttributes1" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="updateAttributes1_result">
							select attribute_type,attribute_value,collection_object_id from attributes 
							where collection_object_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.collection_object_id#">
							group by attribute_type,attribute_value,collection_object_id
							having count(*) > 1
						</cfquery>
						<cfset attributes_updates = attributes_updates + updateAttributes_result.recordcount>
						<cfif updateAttributes1_result.recordcount gt 0>
							<cftransaction action = "ROLLBACK">
						<cfelse>
							<cftransaction action="COMMIT">
						</cfif>
					</cfloop>
					<p>Number of attributes to update: #attributes_updates# (on #getCounts.ctobj# cataloged items)</p>
					<cfif getTempData.recordcount eq attributes_updates and updateAttributes1_result.recordcount eq 0>
						<h2 class="text-success">Success - loaded</h2>
					</cfif>
					<cfif updateAttributes1_result.recordcount gt 0>
						<h2 class="text-danger">Not loaded - these have already been loaded</h2>
					</cfif>
				<cfcatch>
					<cftransaction action="ROLLBACK">
					<h2 class="h3">There was a problem updating the attributes.</h2>
					<cfquery name="getProblemData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						SELECT status,institution_acronym,collection_cde,other_id_type,other_id_number,attribute,attribute_value, attribute_units,attribute_date,attribute_meth,determiner,remarks
						FROM cf_temp_attributes 
						WHERE key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#problem_key#">
					</cfquery>
					<cfif getProblemData.recordcount GT 0>
 						<h2 class="h3">Errors are displayed one row at a time.</h2>
						<h3>
							Error loading row (<span class="text-danger">#attributes_updates + 1#</span>) from the CSV: 
							<cfif len(cfcatch.detail) gt 0>
								<span class="font-weight-normal border-bottom border-danger">
									<cfif cfcatch.detail contains "Invalid ATTRIBUTE_TYPE">
										Invalid ATTRIBUTE_TYPE for this collection; check controlled vocabulary (Help menu)
									<cfelseif cfcatch.detail contains "collection_cde">
										COLLECTION_CDE does not match abbreviated collection (e.g., Ent, Herp, Ich, IP, IZ, Mala, Mamm, Orn, SC, VP)
									<cfelseif cfcatch.detail contains "institution_acronym">
										INSTITUTION_ACRONYM does not match MCZ (all caps)
									<cfelseif cfcatch.detail contains "other_id_type">
										OTHER_ID_TYPE is not valid
									<cfelseif cfcatch.detail contains "DETERMINED_BY_AGENT_ID">
										DETERMINER does not match preferred agent name
									<cfelseif cfcatch.detail contains "date">
										Problem with ATTRIBUTE_DATE, Check Date Format in CSV. (#cfcatch.detail#)
									<cfelseif cfcatch.detail contains "attribute_units">
										Invalid or missing ATTRIBUTE_UNITS
									<cfelseif cfcatch.detail contains "attribute_value">
										Invalid with ATTRIBUTE_VALUE for ATTRIBUTE_TYPE
									<cfelseif cfcatch.detail contains "attribute_meth">
										Problem with ATTRIBUTE_METH (#cfcatch.detail#)
									<cfelseif cfcatch.detail contains "OTHER_ID_NUMBER">
										Problem with OTHER_ID_NUMBER (#cfcatch.detail#)
									<cfelseif cfcatch.detail contains "attribute_remarks">
										Problem with ATTRIBUTE_REMARKS (#cfcatch.detail#)
									<cfelseif cfcatch.detail contains "no data">
										No data or the wrong data (#cfcatch.detail#)
									<cfelse>
										<!--- provide the raw error message if it isn't readily interpretable --->
										#cfcatch.detail#
									</cfif>
								</span>
							</cfif>
						</h3>
						<table class='sortable table-danger table table-responsive table-striped d-lg-table mt-3'>
							<thead>
								<tr><th>COUNT</th><th>STATUS</th>
									<th>INSTITUTION_ACRONYM</th><th>COLLECTION_CDE</th><th>OTHER_ID_TYPE</th><th>OTHER_ID_NUMBER</th><th>ATTRIBUTE</th><th>ATTRIBUTE_VALUE</th><th>ATTRIBUTE_UNITS</th><th>ATTRIBUTE_DATE</th><th>ATTRIBUTE_METH</th><th>DETERMINER</th><th>REMARKS</th>
								</tr> 
							</thead>
							<tbody>
								<cfset i=1>
								<cfloop query="getProblemData">
									<tr>
										<td>#i#</td>
										<td>#getProblemData.status# </td>
										<td>#getProblemData.institution_acronym# </td>
										<td>#getProblemData.collection_cde# </td>
										<td>#getProblemData.other_id_type#</td>
										<td>#getProblemData.other_id_number#</td>
										<td>#getProblemData.attribute# </td>
										<td>#getProblemData.attribute_value# </td>
										<td>#getProblemData.attribute_units# </td>
										<td>#getProblemData.attribute_date#</td>
										<td>#getProblemData.attribute_meth# </td>
										<td>#getProblemData.determiner# </td>
										<td>#getProblemData.remarks# </td>
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
				DELETE FROM cf_temp_attributes 
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
		</cfoutput>
	</cfif>
</main>
<cfinclude template="/shared/_footer.cfm">
