<!--- special case handling to dump problem data as csv --->
<cfif isDefined("action") AND action is "dumpProblems">
	<cfquery name="getProblemData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		SELECT institution_acronym,collection_cde,other_id_type,other_id_number,attribute,attribute_value,attribute_units,attribute_date,attribute_meth,determiner,remarks
		FROM cf_temp_attributes 
		WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
	</cfquery>
	<cfinclude template="/shared/component/functions.cfc">
	<cfset csv = queryToCSV(getProblemData)>
	<cfheader name="Content-Type" value="text/csv">
	<cfoutput>#csv#</cfoutput>
	<cfabort>
</cfif>
<!--- end special case dump of problems --->
<cfset fieldlist = "institution_acronym,collection_cde,other_id_type,other_id_number,attribute,attribute_value,attribute_units,attribute_date,attribute_meth,determiner,remarks">
<cfset fieldTypes ="CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_DATE,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR">
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
				
			<p>The attributes and attribute values must appear as they do on the <a href="https://mczbase.mcz.harvard.edu/vocabularies/ControlledVocabulary.cfm?" class="font-weight-bold">controlled vocabularies</a> lists for ATTRIBUTE_TYPE and ATTRIBUTE_CODE_TABLES. </p>
		
			<p>Upload a comma-delimited text file (csv). Include column headings, spelled exactly as below.</p>
			<span class="btn btn-xs btn-info" onclick="document.getElementById('template').style.display='block';">View template</span>
			<div id="template" style="display:none;margin: 1em 0;">
				<label for="templatearea" class="data-entry-label">
					Copy this header line and save it as a .csv file (<a href="/tools/BulkloadAttributes.cfm?action=getCSVHeader">download</a>)
				</label>
				<textarea rows="2" cols="90" id="templatearea" class="w-100 data-entry-textarea">#fieldlist#</textarea>
			</div>
			<p class="mt-3">Columns in <span class="text-danger">red</span> are required; others are optional:</p>
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
	<cfif #action# is "getFile">
		<h2 class="h3">First step: Reading data from CSV file.</h2>
		<cfoutput>
			<cffile action="READ" file="#FiletoUpload#" variable="fileContent" charset="#cSet#">
			<cfset fileContent=replace(fileContent,"'","''","all")>
			<cfset arrResult = CSVToArray(CSV = fileContent.Trim()) />
		
			<!--- cleanup any incomplete work by the same user --->
			<cfquery name="clearTempTable" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="clearTempTable_result">
				DELETE FROM cf_temp_attributes 
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			
				
			<!--- check for required fields in header line --->
			<cfset institution_acronym_exists = false>
			<cfset collection_cde_exists = false>
			<cfset other_id_type_exists = false>
			<cfset other_id_number_exists = false>
			<cfset attribute_exists = false>
			<cfset attribute_value_exists = false>
			<cfset attribute_date_exists = false>
			<cfset determiner_exists = false>
			<cfloop from="1" to ="#ArrayLen(arrResult[1])#" index="col">
				<cfset header = arrResult[1][col]>
				<cfif ucase(header) EQ 'institution_acronym'><cfset institution_acronym_exists=true></cfif>
				<cfif ucase(header) EQ 'collection_cde'><cfset collection_cde_exists=true></cfif>
				<cfif ucase(header) EQ 'other_id_type'><cfset other_id_type_exists=true></cfif>
				<cfif ucase(header) EQ 'other_id_number'><cfset other_id_number_exists=true></cfif>
				<cfif ucase(header) EQ 'attribute'><cfset attribute_exists=true></cfif>
				<cfif ucase(header) EQ 'attribute_value'><cfset attribute_value_exists=true></cfif>
				<cfif ucase(header) EQ 'attribute_date'><cfset attribute_date_exists=true></cfif>
				<cfif ucase(header) EQ 'determiner'><cfset determiner_exists=true></cfif>
			</cfloop>
			<cfif not (institution_acronym_exists AND collection_cde_exists AND other_id_type_exists AND other_id_number_exists AND attribute_exists AND attribute_value_exists AND attribute_date_exists AND determiner_exists)>
				<cfset message = "One or more required fields are missing in the header line of the csv file.">
				<cfif not institution_acronym_exists><cfset message = "#message# institution_acronym is missing."></cfif>
				<cfif not collection_cde_exists><cfset message = "#message# collection_cde is missing."></cfif>
				<cfif not other_id_type_exists><cfset message = "#message# other_id_type is missing."></cfif>
				<cfif not other_id_number_exists><cfset message = "#message# other_id_number is missing."></cfif>
				<cfif not attribute_exists><cfset message = "#message# attribute is missing."></cfif>
				<cfif not attribute_value_exists><cfset message = "#message# attribute_value is missing."></cfif>
				<cfif not attribute_date_exists><cfset message = "#message# attribute_date is missing."></cfif>
				<cfif not determiner_exists><cfset message = "#message# determiner is missing."></cfif>
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
							<cfif field is ''>
								<cfquery name="m8a" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
									UPDATE cf_temp_attributes
									SET attribute_date = '#dateformat(getType.attribute_date,"YYYY-MM-DD")#'
									WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
								</cfquery>
							</cfif>
						</cfloop>
					</ul>
				<cfelse>
					<!--- subsequent rows, data --->
					<!--- strip off the leading separator --->
					<cfset colVals=replace(colVals,",","","first")>
					<cfset colValArray=listToArray(colVals)>
					<cftry>
						<!--- construct insert for row with a line for each entry in fieldlist using cfqueryparam if column header is in fieldlist, otherwise using null --->
						<cfquery name="insert" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="insert_result">
							insert into cf_temp_attributes
								(#fieldlist#,username)
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
				Successfully read #loadedRows# records from the CSV file.  Next <a href="/tools/BulkloadAttributes.cfm?action=validate">click to validate</a>.
			</h3>
		</cfoutput>
	</cfif>
	<!------------------------------------------------------->
	<cfif #action# is "validate">
		<h2 class="h3">Second step: Data Validation</h2>
		<cfoutput>
			<cfquery name="getType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select other_id_type,attribute,attribute_date
				from cf_temp_attributes
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
		
			<cfset result = isDate(getType.attribute_date)>
			<!---	<cfoutput>#result#</cfoutput>--->
			<cfloop query="getType">
				
				<cfif getType.other_id_type eq 'catalog number'>
					<cfquery name="getCID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						UPDATE
							cf_temp_attributes
						SET
							collection_object_id= (select collection_object_id from cataloged_item where cat_num = cf_temp_attributes.other_id_number and collection_cde = cf_temp_attributes.collection_cde) 
						WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
					</cfquery>
				<cfelse>
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
							)
						WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
					</cfquery>
				</cfif>
				<cfif len(attribute_date)gt 0>
					<cfquery name="getCID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					update
						cf_temp_attributes
					set attribute_date = #DateFormat(attribute_date,"yyyy-mm-dd")#
					where username=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
					</cfquery>
				</cfif>
			</cfloop>
		<!---ERROR MESSAGE--->
		<!---INSTITUTION_ACRONYM--->			
			<cfquery name="m1a" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE cf_temp_attributes
				SET status = 'INSTITUTION_ACRONYM is missing [1a]'
				WHERE institution_acronym is null
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="m1b" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE cf_temp_attributes
				SET status = 'Institution Acronym is not: "MCZ" (check case) [1b]'
				WHERE institution_acronym <> 'MCZ'
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<!---COLLECTION_CDE--->	
			<cfquery name="m2a" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE cf_temp_attributes
				SET status = 'collection_cde not valid [2a]'
				WHERE collection_cde not in (select collection_cde from collection) 
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="m2b" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE cf_temp_attributes
				SET status = 'collection_cde is missing [2b]'
				WHERE COLLECTION_CDE is null
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<!---OTHER_ID_TYPE--->
			<cfquery name="m3" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE cf_temp_attributes
				SET status = 'OTHER_ID_TYPE is missing [3]'
				WHERE OTHER_ID_TYPE is null
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<!---OTHER_ID_NUMBER--->
			<cfquery name="m4" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE cf_temp_attributes
				SET status = 'OTHER_ID_NUMBER is missing [4]'
				WHERE OTHER_ID_NUMBER is null
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<!---ATTRIBUTE--->
			<cfquery name="m5a" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE cf_temp_attributes 
				SET status = 'this attribute is not valid for this collection; not in ctattribute_type [5a]'
				where attribute not in (
					select attribute_type from ctattribute_type, cf_temp_attributes where cf_temp_attributes.collection_cde = ctattribute_type.collection_cde
				)
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<!---ATTRIBUTE_VALUE--->
			<cfquery name="m6a" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE cf_temp_attributes
				SET status = 'attribute value missing [6a]'
				WHERE attribute_value is null
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="m6b" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE cf_temp_attributes 
				SET status = 'this attribute references another code table for the value (e.g., ctsex_code, ctage_class, ctassociated_grants, ct_collections_full_names) [6b]'
				where attribute = (select attribute_type from ctattribute_code_tables where value_code_table is not null)
				and attribute_value is null
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
				<!---ATTRIBUTE_VALUE BASED ON ATTRIBUTE_TYPE--->
			<cfif getType.attribute is 'associated grant'>
				<cfquery name="m6c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					UPDATE cf_temp_attributes
					SET status = 'attribute value not valid [6c]'
					WHERE attribute = 'associated grant' 
					and attribute_value not in (select associated_grant from ctassociated_grants)
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cfquery name="m6d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					UPDATE cf_temp_attributes
					SET status = 'attribute units should be empty [6d]'
					WHERE attribute = 'associated grant' 
					and attribute_units is not null
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
			</cfif>
			<cfif getType.attribute is 'sex'>
				<cfquery name="m6e" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					UPDATE cf_temp_attributes
					SET status = 'sex value is not in ctsex_cde [6e]'
					WHERE attribute_value not in (select sex_cde from ctsex_cde where ctage_class.collection_cde = cf_temp_attributes.collection_cde)
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cfquery name="m6f" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					UPDATE cf_temp_attributes
					SET status = 'attribute units should be empty [6f]'
					WHERE attribute = 'sex' 
					and attribute_units is not null
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
			</cfif>
			<cfif getType.attribute is 'life stage'>
				<cfquery name="m6g" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					UPDATE cf_temp_attributes
					SET status = 'attribute value is not in life stage table [6g]'
					WHERE attribute = 'life stage' 
					and attribute_value not in (select age_class from ctage_class where ctage_class.collection_cde = cf_temp_attributes.collection_cde)
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cfquery name="m6h" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					UPDATE cf_temp_attributes
					SET status = 'attribute units should be empty [6h]'
					WHERE attribute = 'life stage' 
					and attribute_units is not null
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
			</cfif>
			<cfif getType.attribute is 'life stage'>
				<cfquery name="m6g" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					UPDATE cf_temp_attributes
					SET status = 'attribute value is not in life stage table [6g]'
					WHERE attribute = 'life stage' 
					and attribute_value not in (select age_class from ctage_class where ctage_class.collection_cde = cf_temp_attributes.collection_cde)
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cfquery name="m6h" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					UPDATE cf_temp_attributes
					SET status = 'attribute units should be empty [6h]'
					WHERE attribute = 'life stage' 
					and attribute_units is not null
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
			</cfif>
			<!---ATTRIBUTE_UNITS--->
			<cfquery name="m7a" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE cf_temp_attributes 
				SET status = 'this attribute uses controlled_vocabulary [7a]'
				where attribute in (select attribute_type from ctattribute_code_tables where units_code_table is not null)
				and attribute_units is null
				and username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfif getType.attribute contains 'length'>
				<cfquery name="m7b" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					UPDATE cf_temp_attributes 
					SET status = 'invalid attribute_units; not in ctlength_units [7b]'
					where attribute_units not in (select length_units from ctlength_units)
					and username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
			</cfif>
			<cfif getType.attribute is 'weight'>
				<cfquery name="m7c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					UPDATE cf_temp_attributes 
					SET status = 'invalid attribute_units; not in ctweight_units [7b]'
					where attribute_units not in (select weight_units from ctweight_units)
					and username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
			</cfif>
			<!---ATTRIBUTE_DATE--->
			<cfquery name="m8a" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE cf_temp_attributes
				SET status = 'attribute date is invalid'
				WHERE attribute_date is null
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfloop query="getType">
			<cfquery name="m8b" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE cf_temp_attributes
				SET status = 'attribute date is not formatted correctly'
				WHERE getType.result = 'NO'
				AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			</cfloop>
			<cfquery name="m9a" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE
					cf_temp_attributes
				SET
					determined_by_agent_id= (select agent_id from preferred_agent_name where agent_name = cf_temp_attributes.determiner)
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="m9b" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE cf_temp_attributes
				SET status = 'agent value (preferred name) is missing in DETERMINER column [9b]'
				WHERE determiner is null
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT institution_acronym,collection_cde,other_id_type,other_id_number,attribute,attribute_value,attribute_units,attribute_date, attribute_meth,determiner,remarks,status
				FROM cf_temp_attributes
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="pf" dbtype="query">
				SELECT count(*) c 
				FROM data 
				WHERE status is not null
			</cfquery>
			<cfif pf.c gt 0>
				<h2>
					There is a problem with #pf.c# of #data.recordcount# row(s). See the STATUS column. <!---(<a href="/tools/BulkloadAttributes.cfm?action=dumpProblems">download</a>).--->
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
					<tr><th>Count</th>
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
						<th>STATUS</th>
					</tr>
				<tbody>
					<cfset i=1>
					<cfloop query="data">
						<tr><td>#i#</td>
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
							<td><strong>#STATUS#</strong></td>
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
			<cfquery name="getTempData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT * FROM cf_temp_attributes
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfset problem_key = "">
			<cftransaction>
				<cftry>
					<cfset attributes_updates = 0>
					<cfset attributes_updates1 = 0>
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
							where DETERMINED_BY_AGENT_ID = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.determined_by_agent_id#">
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
					<p>Number of attributes to update: #attributes_updates#</p>
						<cfif updateAttributes1_result.recordcount gt 0>
							<h2 class="text-danger">Not loaded - these have already been loaded</h2>
						<cfelse>
							<cfif getTempData.recordcount eq attributes_updates>
								<h2 class="text-success">Success - loaded</h2>
							</cfif>
						</cfif>
					<cfcatch>
						<cftransaction action="ROLLBACK">
						<h2 class="h3">There was a problem updating the attributes. Errors are displayed one row at a time.</h2>
						<cfquery name="getProblemData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							SELECT institution_acronym,collection_cde,other_id_type,other_id_number,attribute,attribute_value, attribute_units,attribute_date,attribute_meth,determiner,remarks,status
							FROM cf_temp_attributes 
							WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						</cfquery><!---key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#problem_key#">--->
							<h3>Error loading row (<span class="text-danger">#attributes_updates + 1#</span>) from the CSV: 
								<cfif len(cfcatch.detail)gt 0>
								<span class="font-weight-normal border-bottom border-danger"><cfif cfcatch.detail contains "Invalid ATTRIBUTE_TYPE">Invalid ATTRIBUTE_TYPE for this collection; check controlled vocabulary (Help menu)</cfif></span>
								
								<span class="font-weight-normal border-bottom border-danger"><cfif cfcatch.detail contains "collection_cde">COLLECTION_CDE does not match abbreviated collection (e.g., Ent, Herp, Ich, IP, IZ, Mala, Mamm, Orn, SC, VP</cfif></span>
								
								<span class="font-weight-normal border-bottom border-danger"><cfif cfcatch.detail contains "institution_acronym">INSTITUTION_ACRONYM does not match MCZ (all caps)</cfif></span>
								
								<span class="font-weight-normal border-bottom border-danger"><cfif cfcatch.detail contains "other_id_type">OTHER_ID_TYPE is not valid</cfif></span>
								
								<span class="font-weight-normal border-bottom border-danger"><cfif cfcatch.detail contains "DETERMINED_BY_AGENT_ID">DETERMINER does not match preferred agent name</cfif></span>
								
								<span class="font-weight-normal border-bottom border-danger"><cfif cfcatch.detail contains "date">Problem with ATTRIBUTE_DATE</cfif></span>
								
								<span class="font-weight-normal border-bottom border-danger"><cfif cfcatch.detail contains "attribute_units">Invalid or missing ATTRIBUTE_UNITS</cfif></span>
								
								<span class="font-weight-normal border-bottom border-danger"><cfif cfcatch.detail contains "attribute_value">Invalid with ATTRIBUTE_VALUE for ATTRIBUTE_TYPE</cfif></span>
								
								<span class="font-weight-normal border-bottom border-danger"><cfif cfcatch.detail contains "attribute_meth">Problem with ATTRIBUTE_METH</cfif></span>
								
								<span class="font-weight-normal border-bottom border-danger"><cfif cfcatch.detail contains "OTHER_ID_NUMBER">Problem with OTHER_ID_NUMBER</cfif></span>
								
								<span class="font-weight-normal border-bottom border-danger"><cfif cfcatch.detail contains "attribute_remarks">Problem with ATTRIBUTE_REMARKS</cfif></span>
								
								<span class="font-weight-normal border-bottom border-danger"><cfif cfcatch.detail contains "no data">No data or the wrong data</cfif></span>
								<cfelse>
									<span class="border-bottom border-danger font-weight-normal">Check Date Format in CSV column</span>
								</cfif>
								<!--- use this to find errors that were missed above--->
						<!---	#cfcatch.detail#--->
							</h3>
							<table class='sortable table-danger table table-responsive table-striped d-lg-table mt-3'>
								<thead>
									<tr><th>COUNT</th>
										<th>INSTITUTION_ACRONYM</th><th>COLLECTION_CDE</th><th>OTHER_ID_TYPE</th><th>OTHER_ID_NUMBER</th><th>ATTRIBUTE</th><th>ATTRIBUTE_VALUE</th><th>ATTRIBUTE_UNITS</th><th>ATTRIBUTE_DATE</th><th>ATTRIBUTE_METH</th><th>DETERMINER</th><th>REMARKS</th><th>STATUS</th>
									</tr> 
								</thead>
								<tbody>
									<cfset i=1>
									<cfloop query="getProblemData">
										<tr>
											<td>#i#</td>
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
											<td>#getProblemData.status# </td>
										</tr>
										<cfset i= i+1>
									</cfloop>
								</tbody>
							</table>
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