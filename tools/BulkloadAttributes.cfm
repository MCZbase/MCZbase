<!--- special case handling to dump problem data as csv --->
<cfif isDefined("action") AND action is "dumpProblems">
	<cfquery name="getProblemData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		SELECT collection_cde,other_id_type,other_id_number,attribute,attribute_value,attribute_units,attribute_date,attribute_meth,determiner,remarks
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
<cfset fieldlist = "collection_cde,other_id_type,other_id_number,attribute,attribute_value,attribute_units,attribute_date,attribute_meth,determiner,remarks">

<cfset fieldTypes ="CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_DATE,CF_SQL_VARCHAR,CF_SQL_DECIMAL,CF_SQL_VARCHAR">
<cfset requiredfieldlist = "collection_cde,other_id_type,other_id_number,attribute,attribute_value,attribute_date,determiner">

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
<main class="container py-3" id="content">
	<h1 class="h2 mt-2">Bulkload Attributes</h1>

	<cfif #action# is "nothing">
		<cfoutput>
			<p>This tool adds attributes to the specimen record. The attribute has to be in the code table prior to uploading this .csv.</p>
			<p>Upload a comma-delimited text file (csv).  Include column headings, spelled exactly as below.  Additional colums will be ignored</p>
			<span class="btn btn-xs btn-info" onclick="document.getElementById('template').style.display='block';">View template</span>
			<div id="template" style="display:none;margin: 1em 0;">
				<label for="templatearea" class="data-entry-label">
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
				<input type="hidden" name="Action" value="getFile">
				<input type="file" name="FiletoUpload" size="45">
				<input type="submit" value="Upload this file" class="btn btn-primary btn-xs">
			</cfform>
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
			<cfquery name="clearTempTable" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="clearTempTable_result">
				DELETE FROM cf_temp_attributes 
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			
			<!--- check for required fields in header line --->
			<cfset collection_cde_exists = false>
			<cfset other_id_type_exists = false>
			<cfset other_id_number_exists = false>
			<cfset attribute_exists = false>
			<cfset attribute_value_exists = false>
			<cfset attribute_date_exists = false>
			<cfset determiner_exists = false>
			<cfloop from="1" to ="#ArrayLen(arrResult[1])#" index="col">
				<cfset header = arrResult[1][col]>
				<cfif ucase(header) EQ 'collection_cde'><cfset collection_cde_exists=true></cfif>
				<cfif ucase(header) EQ 'other_id_type'><cfset other_id_type_exists=true></cfif>
				<cfif ucase(header) EQ 'other_id_number'><cfset other_id_number_exists=true></cfif>
				<cfif ucase(header) EQ 'attribute'><cfset attribute_exists=true></cfif>
				<cfif ucase(header) EQ 'attribute_value'><cfset attribute_value_exists=true></cfif>
				<cfif ucase(header) EQ 'attribute_date'><cfset attribute_date_exists=true></cfif>
				<cfif ucase(header) EQ 'determiner'><cfset determiner_exists=true></cfif>
			</cfloop>
			<cfif not (collection_cde_exists AND other_id_type_exists AND other_id_number_exists AND attribute_exists AND attribute_value_exists AND attribute_date_exists AND determiner_exists)>
				<cfset message = "One or more required fields are missing in the header line of the csv file.">
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
					<ul class="geol_hier">
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
				Successfully loaded #loadedRows# records from the CSV file.  Next <a href="/tools/BulkloadAttributes.cfm?action=validate">click to validate</a>.
			</h3>
		</cfoutput>
	</cfif>
	<!------------------------------------------------------->
	<cfif #action# is "validate">
		<h2 class="h3">Second step: Data Validation</h2>
		<cfoutput>
			<cfset other_id_number = ''>
			<cfset collection_cde = ''>
<!---			<cfquery name="getCID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				update cf_temp_attributes set collection_object_id=
				(select collection_object_id from cataloged_item where cataloged_item.collection_cde = 'cf_temp_attributes.collection_cde'
				and cataloged_item.cat_num = 'cf_temp_attributes.other_id_number')
				WHERE other_id_type = 'catalog number' AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>--->
					<cfquery name="getCID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="updateAttributes_result">
							UPDATE
								cf_temp_attributes
							SET
								collection_object_id= 999322,
							key=#key#
							WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						</cfquery>
			<cfquery name="miac" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE cf_temp_attributes 
				SET status = 'attribute_not_found'
				WHERE attribute is null
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="miap" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE cf_temp_attributes
				SET status = 'attribute_value_not_found'
				WHERE attribute_value is null
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
<!---			<cfquery name="miab" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE cf_temp_attributes 
				SET status = 'collID_not_found'
				WHERE collection_object_id is null
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>--->
			<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT collection_cde,other_id_type,other_id_number,attribute,attribute_value,attribute_units,attribute_date,attribute_meth,determiner,remarks,status
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
					There is a problem with #pf.c# of #data.recordcount# row(s). See the STATUS column. (<a href="/tools/BulkloadAttributes.cfm?action=dumpProblems">download</a>).
				</h2>
				<h3>
					Fix the problems in the data and <a href="/tools/BulkloadAttributes.cfm">start again</a>.
				</h3>
			<cfelse>
				<h2>
					Validation checks passed. Look over the table below and <a href="/tools/BulkloadAttributes.cfm?action=load">click to continue</a> if it all looks good.
				</h2>
			</cfif>
			<table class='sortable table table-responsive table-striped d-lg-table'>
				<thead>
					<tr>
				
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
					<cfloop query="data">
						<tr>
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
			<cftry>
				<cfset attributes_updates = 0>
				<cftransaction>
					<cfloop query="getTempData">
						<cfquery name="updateAttributes" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="updateAttributes_result">
							INSERT into attributes (COLLECTION_OBJECT_ID,ATTRIBUTE_TYPE,ATTRIBUTE_VALUE,ATTRIBUTE_UNITS,DETERMINED_DATE,DETERMINATION_METHOD, DETERMINED_BY_AGENT_ID,ATTRIBUTE_REMARK)VALUES(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#collection_object_id#">,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#attribute#">,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#attribute_value#">,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#attribute_units#">, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#attribute_date#">,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#attribute_meth#">,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#determiner#">,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#remarks#">)
						</cfquery>
						<cfset attributes_updates = attributes_updates + updateAttributes_result.recordcount>
					</cfloop>
				</cftransaction>
				<h2>Updated #attributes_updates# attributes.</h2>
			<cfcatch>
				<h2>There was a problem updating container types.</h2>
				<cfquery name="getProblemData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT collection_cde,other_id_type,other_id_number,attribute,attribute_value, attribute_units, attribute_date,attribute_meth,determiner,remarks,status
					FROM cf_temp_attributes 
					WHERE status is not null
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<h3>Problematic Rows (<a href="/tools/BulkloadAttributes.cfm?action=dumpProblems">download</a>)</h3>
				<table class='sortable table table-responsive table-striped d-lg-table'>
					<thead>
						<tr>
							<th>collection_cde</th><th>other_id_type</th><th>other_id_number</th><th>attribute</th><th>attribute_value</th><th>attribute_units</th><th>attribute_date</th><th>attribute_meth</th><th>determiner</th><th>remarks</th><th>status</th>
						</tr> 
					</thead>
					<tbody>
						<cfloop query="getProblemData">
							<tr>
								<td>#getProblemData.collection_cde#</td>
								<td>#getProblemData.other_id_type#</td>
								<td>#getProblemData.other_id_number#</td>
								<td>#getProblemData.attribute#</td>
								<td>#getProblemData.attribute_value#</td>
								<td>#getProblemData.attribute_units#</td>
								<td>#getProblemData.attribute_date#</td>
								<td>#getProblemData.attribute_meth#</td>
								<td>#getProblemData.determiner#</td>
								<td>#getProblemData.remarks#</td>
								<td>#getProblemData.status#</td>
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
					<cfset attributes_updates = 0>
					<cfloop query="getTempData">
						<cfset problem_key = getTempData.key>
						<cfquery name="updateAttributes" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="updateAttributes_result">
							INSERT into attributes (COLLECTION_OBJECT_ID,ATTRIBUTE_TYPE,ATTRIBUTE_VALUE,ATTRIBUTE_UNITS,DETERMINED_DATE,DETERMINATION_METHOD, DETERMINED_BY_AGENT_ID,ATTRIBUTE_REMARK)VALUES(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#collection_object_id#">,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#attribute#">,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#attribute_value#">,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#attribute_units#">, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#attribute_date#">,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#attribute_meth#">,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#determiner#">,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#remarks#">)
						</cfquery>
						<cfset attributes_updates = attributes_updates + updateAttributes_result.recordcount>
					</cfloop>
					<cftransaction action="commit">
				<cfcatch>
					<cftransaction action="rollback">
					<cfquery name="getProblemData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						SELECT collection_cde,other_id_number,attribute,attribute_value,attribute_units,attribute_meth,determiner,remarks,status 
						FROM cf_temp_attributes 
						WHERE key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#problem_key#">
					</cfquery>
					<h3>Error updating row (#attributes_updates + 1#): #cfcatch.message#</h3>
					<table class='sortable table table-responsive table-striped d-lg-table'>
						<thead>
							<tr>
								<th>collection_cde</th><th>other_id_number</th><th>attribute</th><th>attribute_value</th><th>attribute_units</th><th>attribute_meth</th><th>determiner</th><th>remarks</th><th>status</th>
							</tr> 
						</thead>
						<tbody>
							<cfloop query="getProblemData">
								<tr>
									<td>#getProblemData.collection_cde#</td>
									<td>#getProblemData.other_id_number#</td>
									<td>#getProblemData.attribute#</td>
									<td>#getProblemData.attribute_value#</td>
									<td>#getProblemData.attribute_units#</td>
									<td>#getProblemData.attribute_meth#</td>
									<td>#getProblemData.determiner#</td>
									<td>#getProblemData.remarks#</td>
									<td>#getProblemData.status#</td>
								</tr> 
							</cfloop>
						</tbody>
					</table>
					<cfrethrow>
				</cfcatch>
				</cftry>
			</cftransaction>
			<h2>Updated #attributes_updates# attributes.</h2>
			<h2>Success, changes applied.</h2>
			<!--- cleanup --->
			<cfquery name="clearTempTable" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="clearTempTable_result">
				DELETE FROM cf_temp_attributes
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
		</cfoutput>
	</cfif>

</main>
<cfinclude template="/shared/_footer.cfm">
