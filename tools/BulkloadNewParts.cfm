<cfif isDefined("action") AND action is "dumpProblems">
	<cfquery name="getProblemData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		SELECT institution_acronym,collection_cde,other_id_type,other_id_number,part_name,preserve_method,disposition,lot_count_modifier,lot_count,current_remarks,container_unique_id,condition,part_att_name_1,part_att_val_1,part_att_units_1,part_att_detby_1,part_att_madedate_1,part_att_rem_1,part_att_name_2,part_att_val_2,part_att_units_2,part_att_detby_2,part_att_madedate_2,part_att_rem_2
		FROM cf_temp_parts
		WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
	</cfquery>
	<cfinclude template="/shared/component/functions.cfc"><!---need to add to functions.cfc page--->
	<cfset csv = queryToCSV(getProblemData)>
	<cfheader name="Content-Type" value="text/csv">
	<cfoutput>#csv#</cfoutput>
	<cfabort>
</cfif>
<cfset fieldlist = "institution_acronym,collection_cde,other_id_type,other_id_number,part_name,preserve_method,disposition,lot_count_modifier,lot_count,current_remarks,container_unique_id,condition,part_att_name_1,part_att_val_1,part_att_units_1,part_att_detby_1,part_att_madedate_1,part_att_rem_1,part_att_name_2,part_att_val_2,part_att_units_2,part_att_detby_2,part_att_madedate_2,part_att_rem_2">
<cfset fieldTypes ="CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR">
<cfset requiredfieldlist = "institution_acronym,collection_cde,other_id_type,other_id_number,part_name,preserve_method,disposition,lot_count,condition">
	

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
<cfset pageTitle = "Bulk New Parts">
<cfinclude template="/shared/_header.cfm">
<cfif not isDefined("action") OR len(action) EQ 0><cfset action="nothing"></cfif>
<main class="container py-3" id="content">
	<h1 class="h2 mt-2">Bulkload New Parts (add part rows to specimen records)</h1>
	<cfif #action# is "nothing">
		<cfoutput>
			<span class="btn btn-xs btn-info" onclick="document.getElementById('template').style.display='block';">View template</span>
			<div id="template" style="display:none;margin: 1em 0;">
				<label for="templatearea" class="data-entry-label">
					Copy this header line and save it as a .csv file (<a href="/tools/BulkloadPartContainer.cfm?action=getCSVHeader">download</a>)
				</label>
				<textarea rows="2" cols="90" id="templatearea" class="w-100 data-entry-textarea">#fieldlist#</textarea>
			</div>
			<p class="pt-2">Columns in <span class="text-danger">red</span> are required; others are optional:</p>
			<ul class="">
				<cfloop list="#fieldlist#" index="field" delimiters=",">
					<cfif listContains(requiredfieldlist,field,",")>
						<cfset class="text-danger">
					<cfelse>
						<cfset class="text-dark">
					</cfif>
					<li class="#class#">#field#</li>
				</cfloop>
			</ul>
			<cfform name="atts" method="post" enctype="multipart/form-data" action="/tools/BulkloadPartContainer.cfm">
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
				DELETE FROM MCZBASE.CF_TEMP_PARTS 
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<!--- check for required fields in header line --->
			<cfset INSTITUTION_ACRONYM_exists = false>
			<cfset COLLECTION_CDE_exists = false>
			<cfset OTHER_ID_TYPE_exists = false>
			<cfset OTHER_ID_NUMBER_exists = false>
			<cfset PART_NAME_exists = false>
			<cfset PRESERVE_METHOD_exists = false>
			<cfset DISPOSITION_exists = false>
			<cfset LOT_COUNT_MODIFIER_exists = false>
			<cfset LOT_COUNT_exists = false>
			<cfset CURRENT_REMARKS_exists = false>
			<cfset CONTAINER_UNIQUE_ID_exists = false>
			<cfset CONDITION_exists = false>
			<cfset PART_ATT_NAME_1_exists = false>
			<cfset PART_ATT_VAL_1_exists = false>
			<cfset PART_ATT_UNITS_1_exists = false>
			<cfset PART_ATT_DETBY_1_exists = false>
			<cfset PART_ATT_MADEDATE_1_exists = false>
			<cfset PART_ATT_REM_1_exists = false>
			<cfset PART_ATT_NAME_2_exists = false>
			<cfset PART_ATT_VAL_2_exists = false>
			<cfset PART_ATT_UNITS_2_exists = false>
			<cfset PART_ATT_DETBY_2_exists = false>
			<cfset PART_ATT_MADEDATE_2_exists = false>
			<cfset PART_ATT_REM_2_exists = false>
			<cfset PART_ATT_NAME_3_exists = false>
			<cfset PART_ATT_VAL_3_exists = false>
			<cfset PART_ATT_UNITS_3_exists = false>
			<cfset PART_ATT_DETBY_3_exists = false>
			<cfset PART_ATT_MADEDATE_3_exists = false>
			<cfset PART_ATT_REM_3_exists = false>
			<cfset PART_ATT_NAME_4_exists = false>
			<cfset PART_ATT_VAL_4_exists = false>
			<cfset PART_ATT_UNITS_4_exists = false>
			<cfset PART_ATT_DETBY_4_exists = false>
			<cfset PART_ATT_MADEDATE_4_exists = false>
			<cfset PART_ATT_REM_4_exists = false>
			<cfset PART_ATT_NAME_5_exists = false>
			<cfset PART_ATT_VAL_5_exists = false>
			<cfset PART_ATT_UNITS_5_exists = false>
			<cfset PART_ATT_DETBY_5_exists = false>
			<cfset PART_ATT_MADEDATE_5_exists = false>
			<cfset PART_ATT_REM_5_exists = false>
			<cfset PART_ATT_NAME_6_exists = false>
			<cfset PART_ATT_VAL_6_exists = false>
			<cfset PART_ATT_UNITS_6_exists = false>
			<cfset PART_ATT_DETBY_6_exists = false>
			<cfset PART_ATT_MADEDATE_6_exists = false>
			<cfset PART_ATT_REM_6_exists = false>
			<cfloop from="1" to ="#ArrayLen(arrResult[1])#" index="col">
				<cfset header = arrResult[1][col]>
				<cfif ucase(header) EQ 'INSTITUTION_ACRONYM'><cfset INSTITUTION_ACRONYM_exists=true></cfif>
				<cfif ucase(header) EQ 'COLLECTION_CDE'><cfset COLLECTION_CDE_exists=true></cfif>
				<cfif ucase(header) EQ 'OTHER_ID_TYPE'><cfset OTHER_ID_TYPE_exists=true></cfif>
				<cfif ucase(header) EQ 'OTHER_ID_NUMBER'><cfset OTHER_ID_NUMBER_exists=true></cfif>
				<cfif ucase(header) EQ 'PART_NAME'><cfset PART_NAME_exists=true></cfif>
				<cfif ucase(header) EQ 'PRESERVE_METHOD'><cfset PRESERVE_METHOD_exists=true></cfif>
				<cfif ucase(header) EQ 'DISPOSITION'><cfset DISPOSITION_exists=true></cfif>
				<cfif ucase(header) EQ 'LOT_COUNT_MODIFIER'><cfset LOT_COUNT_MODIFIER_exists=true></cfif>
				<cfif ucase(header) EQ 'LOT_COUNT'><cfset LOT_COUNT_exists=true></cfif>
				<cfif ucase(header) EQ 'CURRENT_REMARKS'><cfset CURRENT_REMARKS_exists=true></cfif>
				<cfif ucase(header) EQ 'CONTAINER_UNIQUE_ID'><cfset CONTAINER_UNIQUE_ID_exists=true></cfif>
				<cfif ucase(header) EQ 'CONDITION'><cfset CONDITION_exists=true></cfif>
				<cfif ucase(header) EQ 'CURRENT_REMARKS'><cfset CURRENT_REMARKS_exists=true></cfif>
				<cfif ucase(header) EQ 'PART_ATT_NAME_1'><cfset PART_ATT_NAME_1_exists=true></cfif>
				<cfif ucase(header) EQ 'PART_ATT_VAL_1'><cfset PART_ATT_VAL_1_exists=true></cfif>
				<cfif ucase(header) EQ 'PART_ATT_UNITS_1'><cfset PART_ATT_UNITS_1_exists=true></cfif>
				<cfif ucase(header) EQ 'PART_ATT_DETBY_1'><cfset PART_ATT_DETBY_1_exists=true></cfif>
				<cfif ucase(header) EQ 'PART_ATT_MADEDATE_1'><cfset PART_ATT_MADEDATE_1_exists=true></cfif>
				<cfif ucase(header) EQ 'PART_ATT_REM_1'><cfset PART_ATT_REM_1_exists=true></cfif>
				<cfif ucase(header) EQ 'PART_ATT_NAME_2'><cfset PART_ATT_NAME_2_exists=true></cfif>
				<cfif ucase(header) EQ 'PART_ATT_VAL_2'><cfset PART_ATT_VAL_2_exists=true></cfif>
				<cfif ucase(header) EQ 'PART_ATT_UNITS_2'><cfset PART_ATT_UNITS_2_exists=true></cfif>
				<cfif ucase(header) EQ 'PART_ATT_DETBY_2'><cfset PART_ATT_DETBY_2_exists=true></cfif>
				<cfif ucase(header) EQ 'PART_ATT_MADEDATE_2'><cfset PART_ATT_MADEDATE_2_exists=true></cfif>
				<cfif ucase(header) EQ 'PART_ATT_REM_2'><cfset PART_ATT_REM_2_exists=true></cfif>
				<cfif ucase(header) EQ 'PART_ATT_NAME_3'><cfset PART_ATT_NAME_3_exists=true></cfif>
				<cfif ucase(header) EQ 'PART_ATT_VAL_3'><cfset PART_ATT_VAL_3_exists=true></cfif>
				<cfif ucase(header) EQ 'PART_ATT_UNITS_3'><cfset PART_ATT_UNITS_3_exists=true></cfif>
				<cfif ucase(header) EQ 'PART_ATT_DETBY_3'><cfset PART_ATT_DETBY_3_exists=true></cfif>
				<cfif ucase(header) EQ 'PART_ATT_MADEDATE_3'><cfset PART_ATT_MADEDATE_3_exists=true></cfif>
				<cfif ucase(header) EQ 'PART_ATT_REM_3'><cfset PART_ATT_REM_3_exists=true></cfif>
				<cfif ucase(header) EQ 'PART_ATT_NAME_4'><cfset PART_ATT_NAME_4_exists=true></cfif>
				<cfif ucase(header) EQ 'PART_ATT_VAL_4'><cfset PART_ATT_VAL_4_exists=true></cfif>
				<cfif ucase(header) EQ 'PART_ATT_UNITS_4'><cfset PART_ATT_UNITS_4_exists=true></cfif>
				<cfif ucase(header) EQ 'PART_ATT_DETBY_4'><cfset PART_ATT_DETBY_4_exists=true></cfif>
				<cfif ucase(header) EQ 'PART_ATT_MADEDATE_4'><cfset PART_ATT_MADEDATE_4_exists=true></cfif>
				<cfif ucase(header) EQ 'PART_ATT_REM_4'><cfset PART_ATT_REM_4_exists=true></cfif>
				<cfif ucase(header) EQ 'PART_ATT_NAME_5'><cfset PART_ATT_NAME_5_exists=true></cfif>
				<cfif ucase(header) EQ 'PART_ATT_VAL_5'><cfset PART_ATT_VAL_5_exists=true></cfif>
				<cfif ucase(header) EQ 'PART_ATT_UNITS_5'><cfset PART_ATT_UNITS_5_exists=true></cfif>
				<cfif ucase(header) EQ 'PART_ATT_DETBY_5'><cfset PART_ATT_DETBY_5_exists=true></cfif>
				<cfif ucase(header) EQ 'PART_ATT_MADEDATE_5'><cfset PART_ATT_MADEDATE_5_exists=true></cfif>
				<cfif ucase(header) EQ 'PART_ATT_REM_5'><cfset PART_ATT_REM_5_exists=true></cfif>
				<cfif ucase(header) EQ 'PART_ATT_NAME_6'><cfset PART_ATT_NAME_6_exists=true></cfif>
				<cfif ucase(header) EQ 'PART_ATT_VAL_6'><cfset PART_ATT_VAL_6_exists=true></cfif>
				<cfif ucase(header) EQ 'PART_ATT_UNITS_6'><cfset PART_ATT_UNITS_6_exists=true></cfif>
				<cfif ucase(header) EQ 'PART_ATT_DETBY_6'><cfset PART_ATT_DETBY_6_exists=true></cfif>
				<cfif ucase(header) EQ 'PART_ATT_MADEDATE_6'><cfset PART_ATT_MADEDATE_6_exists=true></cfif>
				<cfif ucase(header) EQ 'PART_ATT_REM_6'><cfset PART_ATT_REM_6_exists=true></cfif>
			</cfloop>
			<cfif not (INSTITUTION_ACRONYM_exists AND COLLECTION_CDE_exists AND OTHER_ID_TYPE_exists AND OTHER_ID_NUMBER_exists AND PART_NAME_exists AND PRESERVE_METHOD_exists AND DISPOSITION_exists AND LOT_COUNT_exists AND CONDITION_exists)>
				<cfset message = "One or more required fields are missing in the header line of the csv file.">
				<cfif not INSTITUTION_ACRONYM_exists><cfset message = "#message# INSTITUTION_ACRONYM is missing."></cfif>
				<cfif not COLLECTION_CDE_exists><cfset message = "#message# COLLECTION_CDE is missing."></cfif>
				<cfif not OTHER_ID_TYPE_exists><cfset message = "#message# OTHER_ID_TYPE is missing."></cfif>
				<cfif not OTHER_ID_NUMBER_exists><cfset message = "#message# OTHER_ID_NUMBER is missing."></cfif>
				<cfif not PART_NAME_exists><cfset message = "#message# PART_NAME is missing."></cfif>
				<cfif not PRESERVE_METHOD_exists><cfset message = "#message# PRESERVE_METHOD is missing."></cfif>
				<cfif not DISPOSITION_exists><cfset message = "#message# DISPOSITION is missing."></cfif>
				<cfif not LOT_COUNT_exists><cfset message = "#message# LOT_COUNT is missing."></cfif>
				<cfif not CONDITION_exists><cfset message = "#message# CONDITION is missing."></cfif>
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
							insert into MCZBASE.CF_TEMP_PARTS
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
				Successfully loaded #loadedRows# records from the CSV file.  Next <a href="/tools/BulkloadPartContainer.cfm?action=validate">click to validate</a>.
			</h3>
		</cfoutput>
	</cfif>
											
	<!------------------------------------------------------->
	<cfif #action# is "validate">
		<h2 class="h3">Second step: Data Validation</h2>
		<cfoutput>
			<cfquery name="getCID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				update cf_temp_parts set collection_object_id = 
				(
					select sp.derived_from_cat_item 
					from specimen_part sp, cataloged_item ci
					where sp.derived_from_cat_item = ci.collection_object_id
					and ci.collection_cde = cf_temp_barcode_parts.collection_cde
					and ci.cat_num = cf_temp_barcode_parts.other_id_number
				) 
				where username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="getCID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				update cf_temp__parts set container_id=
				(select container_id from container where container.barcode = cf_temp_parts.container_unique_id)
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="getCID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				update cf_temp_parts set parent_container_id=
				(select parent_container_id from container where container.barcode = cf_temp_parts.container_unique_id)
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="miac" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE cf_temp_parts 
				SET status = 'container_not_found'
				WHERE container_id is null
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="miac" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				update cf_temp_parts 
				SET status = 'part_not_found'
				WHERE collection_object_id is null
				and username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="miac" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				update cf_temp_parts 
				SET status = 'part_name_not_found'
				WHERE part_name is null
				and username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT OTHER_ID_TYPE,OTHER_ID_NUMBER,COLLECTION_OBJECT_ID,COLLECTION_CDE,CONTAINER_ID,
				INSTITUTION_ACRONYM,PART_NAME,PRESERVE_METHOD,CONTAINER_UNIQUE_ID,STATUS 
				FROM cf_temp_parts
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="pf" dbtype="query">
				SELECT count(*) c 
				FROM data 
				WHERE status is not null
			</cfquery>
			<cfif pf.c gt 0>
				<h2>
					There is a problem with #pf.c# of #data.recordcount# row(s). See the STATUS column. (<a href="/tools/BulkloadPartContainer.cfm?action=validate">download</a>).
				</h2>
				<h3>
					Fix the problems in the data and <a href="/tools/BulkloadPartContainer.cfm">start again</a>.
				</h3>
			<cfelse>
				<h2>
					Validation checks passed. Look over the table below and <a href="/tools/BulkloadPartContainer.cfm?action=load">click to continue</a> if it all looks good.
				</h2>
			</cfif>
			<table class='sortable table table-responsive table-striped d-lg-table'>
				<thead>
					<tr>
						<th>OTHER_ID_TYPE</th>
						<th>OTHER_ID_NUMBER</th>
						<th>COLLECTION_CDE</th>
						<th>INSTITUTION_ACRONYM</th>
						<th>PART_NAME</th>
						<th>CONTAINER_UNIQUE_ID</th>
						<th>COLLECTION_OBJECT_ID</th>
						<th>CONTAINER_ID</th>
						<th>PRESERVE_METHOD</th>
						<th>STATUS</th>
					</tr>
				<tbody>
					<cfloop query="data">
						<tr>
							<td>#data.OTHER_ID_TYPE#</td>
							<td>#data.OTHER_ID_NUMBER#</td>
							<td>#data.COLLECTION_CDE#</td>
							<td>#data.INSTITUTION_ACRONYM#</td>
							<td>#data.PART_NAME#</td>
							<td>#data.CONTAINER_UNIQUE_ID#</td>
							<td>#data.COLLECTION_OBJECT_ID#</td>
							<td>#data.CONTAINER_ID#</td>
							<td>#data.PRESERVE_METHOD#</td>
							<td><strong>#STATUS#</strong></td>
						</tr>
					</cfloop>
				</tbody>
			</table>
		</cfoutput>
	</cfif>
				
	<!-------------------------------------------------------------------------------------------->
	<cfif #action# is "load">
		<h2 class="h3">Third step: Apply changes.</h2>
		<cfoutput>
			<cfquery name="getTempData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT *
				FROM cf_temp_parts
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cftry>
				<cfset part_container_updates = 0>
					<cftransaction>
						<cfset install_date = ''>
						<cfloop query="getTempData">
							<cfquery name="updateContainerHist" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="updateContainerHist_result">
							insert into 
								container_history 
									(container_id,parent_container_id,install_date) 
								values (#container_id#,#parent_container_id#,SYSDATE)
							</cfquery>
							<cfset part_container_updates = part_container_updates + updateContainerHist_result.recordcount>
						</cfloop>
					</cftransaction> 
					<div class="container">
						<div class="row">
							<div class="col-12 mx-auto">
								<h2 class="h3">Updated #part_container_updates# part(s) with container(s).</h2>
							</div>
						</div>
					</div>
				<cfcatch>
					<h2>There was a problem updating part container.</h2>
					<cfquery name="getProblemData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						SELECT *
						FROM cf_temp_parts 
						WHERE status is not null
							AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
					</cfquery>
					<h3>Problematic Rows (<a href="/tools/BulkloadPartContainer.cfm?action=dumpProblems">download</a>)</h3>
					<table class='sortable table table-responsive table-striped d-lg-table'>
						<thead>
							<tr>
								<th>CONTAINER_ID</th>
								<th>COLLECTION_OBJECT_ID</th>
								<th>OTHER_ID_TYPE</th>
								<th>OTHER_ID_NUMBER</th>
								<th>COLLECTION_CDE</th>
								<th>INSTITUTION_ACRONYM</th>
								<th>PART_NAME</th>
								<th>PRESERVE_METHOD</th>
								<th>CONTAINER_UNIQUE_ID</th>
								<th>STATUS</th>
							</tr> 
						</thead>
						<tbody>
							<cfloop query="getProblemData">
								<tr><td>#getProblemData.CONTAINER_ID#</td>
									<td>#getProblemData.COLLECTION_OBJECT_ID#</td>
									<td>#getProblemData.OTHER_ID_TYPE#</td>
									<td>#getProblemData.OTHER_ID_NUMBER#</td>
									<td>#getProblemData.COLLECTION_CDE#</td>
									<td>#getProblemData.INSTITUTION_ACRONYM#</td>
									<td>#getProblemData.PART_NAME#</td>
									<td>#getProblemData.PRESERVE_METHOD#</td>
									<td>#getProblemData.CONTAINER_UNIQUE_ID#</td>
									<td><strong>#STATUS#</strong></td>
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
					<cfset part_container_updates = 0>
					<cfloop query="getTempData">
						<cfset problem_key = getTempData.key>
						<cfquery name="updatePartContainer" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="updatePartContainer_result">
							Insert into 
							container_history 
							(container_id, parent_container_id,install_date) 
							values (#CONTAINER_ID#,#PARENT_CONTAINER_ID#,SYSDATE)
						</cfquery>
						<cfset part_container_updates = part_container_updates + updatePartContainer_result.recordcount>
					</cfloop>
					<cftransaction action="commit">
				<cfcatch>
					<cftransaction action="rollback">
						<cfquery name="getProblemData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						SELECT other_id_type,other_id_number,collection_cde,institution_acronym,
							part_name,preserve_method,container_unique_id,status 
						FROM cf_temp_barcode_parts 
						WHERE status is not null
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						</cfquery>
						<h3>Error updating row (#part_container_updates + 1#): #cfcatch.message#</h3>
						<table class='sortable table table-responsive table-striped d-lg-table'>
							<thead>
								<tr>
									<th>other_id_type</th>
									<th>other_id_number</th>
									<th>collection_cde</th>
									<th>institution_acronym</th>
									<th>part_name</th>
									<th>preserve_method</th>
									<th>container_unique_id</th>
									<th>status</th>
								</tr> 
							</thead>
							<tbody>
								<cfloop query="getProblemData">
									<tr>
										<td>#getProblemData.OTHER_ID_TYPE#</td>
										<td>#getProblemData.OTHER_ID_NUMBER#</td>
										<td>#getProblemData.COLLECTION_CDE#</td>
										<td>#getProblemData.INSTITUTION_ACRONYM#</td>
										<td>#getProblemData.PART_NAME#</td>
										<td>#getProblemData.PRESERVE_METHOD#</td>
										<td>#getProblemData.CONTAINER_UNIQUE_ID#</td>
										<td>#getProblemData.status#</td>
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
			<cfquery name="clearTempTable" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="clearTempTable_result">
				DELETE FROM cf_temp_barcode_parts 
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
		</cfoutput>
	</cfif>
</main>
<cfinclude template="/shared/_footer.cfm">
	
		
		
		
		

<p>Upload a comma-delimited text file (csv).
    Include column headings, spelled exactly as below.</p>
<p style="margin:1em;"><span class="likeLink" onclick="document.getElementById('template').style.display='block';">view template</span></p>
	<div id="template" style="display:none;margin: 1em 0;">
		<label for="t">Copy the existing code and save as a .csv file</label>
		<textarea rows="2" cols="80" id="t">institution_acronym,collection_cde,other_id_type,other_id_number,part_name,preserve_method,disposition,lot_count_modifier,lot_count,current_remarks,container_unique_id,condition,part_att_name_1,part_att_val_1,part_att_units_1,part_att_detby_1,part_att_madedate_1,part_att_rem_1,part_att_name_2,part_att_val_2,part_att_units_2,part_att_detby_2,part_att_madedate_2,part_att_rem_2</textarea>
	</div>
    <p>Columns in <span style="color:red">red</span> are required; others are optional:</p>
<ul class="geol_hier" style="padding-bottom: .25em;">
	<li style="color:red">institution_acronym</li>
	<li style="color:red">collection_cde</li>
	<li style="color:red">other_id_type ("catalog number" is OK)</li>
	<li style="color:red">other_id_number</li>
	<li style="color:red">part_name</li>
	<li style="color:red">preserve_method</li>
	<li style="color:red">disposition</li>
	<li>lot_count_modifier</li>
	<li style="color:red">lot_count</li>
	<li>current_remarks
    	<ul style="margin-left:1em;padding-bottom: .5em;font-size: 14px;">
				<li>Remarks to be added with the new part</li>
			</ul></li>
	<li>container_unique_id

		<ul style="margin-left:1em;padding-bottom: .5em;font-size: 14px;">
				<li>Container unique ID in which to place this part</li>
			</ul>
	</li>
	<li style="color:red">condition</li>
	<li>part_att_name_1</li>
	<li>part_att_val_1</li>
	<li>part_att_units_1</li>
	<li>part_att_detby_1</li>
	<li>part_att_madedate_1</li>
	<li>part_att_rem_1</li>
	<li>part_att_name_2</li>
	<li>part_att_val_2</li>
	<li>part_att_units_2</li>
	<li>part_att_detby_2</li>
	<li>part_att_madedate_2</li>
	<li>part_att_rem_2</li>
	<li>part_att_name_3</li>
	<li>part_att_val_3</li>
	<li>part_att_units_3</li>
	<li>part_att_detby_3</li>
	<li>part_att_madedate_3</li>
	<li>part_att_rem_3</li>
	<li>part_att_name_4</li>
	<li>part_att_val_4</li>
	<li>part_att_units_4</li>
	<li>part_att_detby_4</li>
	<li>part_att_madedate_4</li>
	<li>part_att_rem_4</li>
	<li>part_att_name_5</li>
	<li>part_att_val_5</li>
	<li>part_att_units_5</li>
	<li>part_att_detby_5</li>
	<li>part_att_madedate_5</li>
	<li>part_att_rem_5</li>
	<li>part_att_name_6</li>
	<li>part_att_val_6</li>
	<li>part_att_units_6</li>
	<li>part_att_detby_6</li>
	<li>part_att_madedate_6</li>
	<li>part_att_rem_6</li>
</ul>
    <br>
<cfform name="atts" method="post" enctype="multipart/form-data" action="BulkloadNewParts.cfm">
			<input type="hidden" name="Action" value="getFile">
			  <input type="file"
		   name="FiletoUpload"
		   size="45">
			 <input type="submit" value="Upload this file"
		class="savBtn"
		onmouseover="this.className='savBtn btnhov'"
		onmouseout="this.className='savBtn'">
		<br><br>
	Character Set: <select name="cSet" id="cSet">
		<option value="windows-1252" selected>windows-1252</option>
		<option value="MacRoman">MacRoman</option>
		<option value="utf-8">utf-8</option>
		<option value="utf-16">utf-16</option>
		<option value="unicode">unicode</option>
	</input>
  </cfform>

</cfif>
<!------------------------------------------------------->
<!------------------------------------------------------->
<!------------------------------------------------------->
<cfif #action# is "getFile">
<cfoutput>
	<cffile action="READ" file="#FiletoUpload#" variable="fileContent" charset="#cSet#">
	<cfset fileContent=replace(fileContent,"'","''","all")>
	 <cfset arrResult = CSVToArray(CSV = fileContent.Trim()) />
 <cfquery name="die" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	delete from cf_temp_parts
</cfquery>
<cfset colNames="">
	<cfloop from="1" to ="#ArrayLen(arrResult)#" index="o">
		<cfset colVals="">
			<cfloop from="1"  to ="#ArrayLen(arrResult[o])#" index="i">
				<cfset thisBit=arrResult[o][i]>
				<cfif #o# is 1>
					<cfset colNames="#colNames#,#thisBit#">
				<cfelse>
					<cfset colVals="#colVals#,'#thisBit#'">
				</cfif>
			</cfloop>
		<cfif #o# is 1>
			<cfset colNames=replace(colNames,",","","first")>
		</cfif>
		<cfif len(#colVals#) gt 1>
			<cfset colVals=replace(colVals,",","","first")>
			<cfquery name="ins" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				insert into cf_temp_parts (#colNames#) values (#preservesinglequotes(colVals)#)
			</cfquery>
			<!---insert into cf_temp_parts (#colNames#) values (#preservesinglequotes(colVals)#)--->
		</cfif>
	</cfloop>

	<cflocation url="BulkloadNewParts.cfm?action=validate">
</cfoutput>
</cfif>
<!------------------------------------------------------->
<!------------------------------------------------------->
<cfif #action# is "validate">
<!---validate--->
<cfoutput>
	<cfquery name="getCodeTables" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select attribute_type, decode(value_code_table, null, units_code_table,value_code_table) code_table  from ctattribute_code_tables
	</cfquery>
	<cfset ctstruct=StructNew()>
	<cfloop query="getCodeTables">
		<cfset StructInsert(ctstruct, #attribute_type#, #code_table#)>
	</cfloop>
	<!---cfscript>
		writedump(ctstruct.find("sex"));
	</cfscript--->
	<cfquery name="getParentContainerId" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		update cf_temp_parts set parent_container_id =
		(select container_id from container where container.barcode = cf_temp_parts.container_unique_id)
	</cfquery>
	<cfquery name="validateGotParent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		update cf_temp_parts set validated_status = validated_status || ';Container Unique ID not found'
		where container_unique_id is not null and parent_container_id is null
	</cfquery>
	<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		update cf_temp_parts set validated_status = validated_status || ';Invalid part_name'
		where part_name|| '|' ||collection_cde NOT IN (
			select part_name|| '|' ||collection_cde from ctspecimen_part_name
			)
			OR part_name is null
	</cfquery>
	<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		update cf_temp_parts set validated_status = validated_status || ';Invalid preserve_method'
		where preserve_method|| '|' ||collection_cde NOT IN (
			select preserve_method|| '|' ||collection_cde from ctspecimen_preserv_method
			)
			OR preserve_method is null
	</cfquery>
	<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		update cf_temp_parts set validated_status = validated_status || ';Invalid container_unique_id'
		where container_unique_id NOT IN (
			select barcode from container where barcode is not null
			)
		AND container_unique_id is not null
	</cfquery>
	<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		update cf_temp_parts set validated_status = validated_status || ';Invalid DISPOSITION'
		where DISPOSITION NOT IN (
			select COLL_OBJ_DISPOSITION from CTCOLL_OBJ_DISP
			)
			OR disposition is null
	</cfquery>

	<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		update cf_temp_parts set validated_status = validated_status || ';Invalid CONDITION'
		where CONDITION is null
	</cfquery>
	<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		update cf_temp_parts set validated_status = validated_status || ';invalid lot_count_modifier'
		where lot_count_modifier NOT IN (
			select modifier from ctnumeric_modifiers
			)
	</cfquery>
	<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		update cf_temp_parts set validated_status = validated_status || ';Invalid LOT_COUNT'
		where (
			LOT_COUNT is null OR
			is_number(lot_count) = 0
			)
	</cfquery>


	<cfloop index="i" from="1" to="2">
		<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			update cf_temp_parts set validated_status = validated_status || ';invalid PART_ATT_NAME_#i#'
			where PART_ATT_NAME_#i# not in
			(select attribute_type from CTSPECPART_ATTRIBUTE_TYPE)
		</cfquery>

		<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			update cf_temp_parts set validated_status = validated_status || ';invalid PART_ATT_MADEDATE_#i#'
			where is_iso8601(PART_ATT_MADEDATE_#i#) <> 'valid'
			and PART_ATT_MADEDATE_#i# is not null
		</cfquery>
		<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			update cf_temp_parts set validated_status = validated_status || ';scientific name (' || PART_ATT_VAL_#i# || ') matched multiple taxonomy records'
 			where PART_ATT_NAME_#i# = 'scientific name'
			AND regexp_replace(PART_ATT_VAL_#i#, ' (\?|sp.)$', '') in
			(select scientific_name from taxonomy group by scientific_name having count(*) > 1)
			AND PART_ATT_VAL_#i# is not null
		</cfquery>
		<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			update cf_temp_parts set validated_status = validated_status || ';scientific name (' || PART_ATT_VAL_#i# || ') does not exist'
 			where PART_ATT_NAME_#i# = 'scientific name'
			AND regexp_replace(PART_ATT_VAL_#i#, ' (\?|sp.)$', '') not in
			(select scientific_name from taxonomy group by scientific_name having count(*) = 1)
			AND PART_ATT_VAL_#i# is not null
			and (validated_status not like '%;scientific name (' || PART_ATT_VAL_#i# || ') matched multiple taxonomy records%' or validated_status is null)
		</cfquery>
		<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			update cf_temp_parts set validated_status = validated_status || ';scientific name cannot be null'
 			where PART_ATT_NAME_#i# = 'scientific name'
			AND PART_ATT_VAL_#i# is null
		</cfquery>
		<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			update cf_temp_parts set validated_status = validated_status || ';PART_ATT_DETBY_#i# agent (' || PART_ATT_DETBY_#i# || ') matched multiple agent names'
			where PART_ATT_DETBY_#i# in
			(select agent_name from agent_name group by agent_name having count(*) > 1)
			AND PART_ATT_DETBY_#i# is not null
		</cfquery>
		<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			update cf_temp_parts set validated_status = validated_status || ';PART_ATT_DETBY_#i# agent (' || PART_ATT_DETBY_#i# || ') does not exist'
 			where PART_ATT_DETBY_#i# not in
			(select agent_name from agent_name group by agent_name having count(*) = 1)
			AND PART_ATT_DETBY_#i# is not null
			and (validated_status not like '%PART_ATT_DETBY_#i# agent (' || PART_ATT_DETBY_#i# || ') matched multiple agent names%' or validated_status is null)
		</cfquery>
		<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			update cf_temp_parts set validated_status = validated_status || ';PART_ATT_VAL_#i# is not valid for attribute(' || PART_ATT_NAME_#i# || ')'
			where chk_att_codetables(PART_ATT_NAME_#i#,PART_ATT_VAL_#i#,COLLECTION_CDE)=0
			and PART_ATT_NAME_#i# in
			(select attribute_type from ctattribute_code_tables where value_code_table is not null)
		</cfquery>
		<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			update cf_temp_parts set validated_status = validated_status || ';PART_ATT_UNITS_#i# is not valid for attribute(' || PART_ATT_NAME_#i# || ')'
			where chk_att_codetables(PART_ATT_NAME_#i#,PART_ATT_UNITS_#i#,COLLECTION_CDE)=0
			and PART_ATT_NAME_#i# in
			(select attribute_type from ctattribute_code_tables where units_code_table is not null)
		</cfquery>
	</cfloop>


	<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select * from cf_temp_parts where validated_status is null
	</cfquery>
	<cfloop query="data">
		<cfif #other_id_type# is "catalog number">
			<cfquery name="collObj" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT
						collection_object_id
					FROM
						cataloged_item,
						collection
					WHERE
						cataloged_item.collection_id = collection.collection_id and
						collection.collection_cde = '#collection_cde#' and
						collection.institution_acronym = '#institution_acronym#' and
						cat_num='#other_id_number#'
				</cfquery>
			<cfelse>
				<cfquery name="collObj" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT
						coll_obj_other_id_num.collection_object_id
					FROM
						coll_obj_other_id_num,
						cataloged_item,
						collection
					WHERE
						coll_obj_other_id_num.collection_object_id = cataloged_item.collection_object_id and
						cataloged_item.collection_id = collection.collection_id and
						collection.collection_cde = '#collection_cde#' and
						collection.institution_acronym = '#institution_acronym#' and
						other_id_type = '#other_id_type#' and
						display_value = '#other_id_number#'
				</cfquery>
			</cfif>
			<cfif #collObj.recordcount# is 1>
				<cfquery name="insColl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					UPDATE cf_temp_parts SET collection_object_id = #collObj.collection_object_id#,
					validated_status='VALID'
					where
					key = #key#
				</cfquery>
			<cfelse>
				<cfquery name="insColl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					UPDATE cf_temp_parts SET validated_status =
					validated_status || ';#data.institution_acronym# #data.collection_cde# #data.other_id_type# #data.other_id_number# could not be found.'
					where key = #key#
				</cfquery>
			</cfif>
		</cfloop>
		<!---
			Things that can happen here:
				1) Upload a part that doesn't exist
					Solution: create a new part, optionally put it in a container that they specify in the upload.
				2) Upload a part that already exists
					a) use_existing = 1
						1) part is in a container
							Solution: warn them, create new part, optionally put it in a container that they've specified
						 2) part is NOT already in a container
						 	Solution: put the existing part into the new container that they've specified or, if
						 	they haven't specified a new container, ignore this line as it does nothing.
					b) use_existing = 0
						1) part is in a container
							Solution: warn them, create a new part, optionally put it in the container they've specified
						2) part is not in a container
							Solution: same: warning and new part
		---->
		<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			update cf_temp_parts set (validated_status) = (
			select
			decode(parent_container_id,
			0,'NOTE: PART EXISTS',
			'NOTE: PART EXISTS IN PARENT CONTAINER')
			from specimen_part,coll_obj_cont_hist,container, coll_object_remark where
			specimen_part.collection_object_id = coll_obj_cont_hist.collection_object_id AND
			coll_obj_cont_hist.container_id = container.container_id AND
			coll_object_remark.collection_object_id(+) = specimen_part.collection_object_id AND
			derived_from_cat_item = cf_temp_parts.collection_object_id AND
			cf_temp_parts.part_name=specimen_part.part_name AND
			cf_temp_parts.preserve_method=specimen_part.preserve_method AND
			nvl(cf_temp_parts.current_remarks, 'NULL') = nvl(coll_object_remark.coll_object_remarks, 'NULL')
			group by parent_container_id)
			where validated_status='VALID'
		</cfquery>
		<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			update cf_temp_parts set (parent_container_id) = (
			select container_id
			from container where
			barcode=container_unique_id)
			where substr(validated_status,1,5) IN ('VALID','NOTE:')
		</cfquery>
		<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			update cf_temp_parts set (use_part_id) = (
			select min(specimen_part.collection_object_id)
			from specimen_part, coll_object_remark where
			specimen_part.collection_object_id = coll_object_remark.collection_object_id(+) AND
			cf_temp_parts.part_name=specimen_part.part_name and
			cf_temp_parts.preserve_method=specimen_part.preserve_method and
			cf_temp_parts.collection_object_id=specimen_part.derived_from_cat_item and
			nvl(cf_temp_parts.current_remarks, 'NULL') = nvl(coll_object_remark.coll_object_remarks, 'NULL'))
			where validated_status like '%NOTE: PART EXISTS%' AND
			use_existing = 1
		</cfquery>
		<cflocation url="BulkloadNewParts.cfm?action=checkValidate">
</cfoutput>
</cfif>
<!------------------------------------------------------->
<cfif #action# is "checkValidate">

	<cfoutput>

	<cfquery name="inT" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select * from cf_temp_parts
	</cfquery>
	<table border>
		<tr>
			<td>Problem</td>
			<td>institution_acronym</td>
			<td>collection_cde</td>
			<td>OTHER_ID_TYPE</td>
			<td>OTHER_ID_NUMBER</td>
			<td>part_name</td>
			<td>preserve_method</td>
			<td>disposition</td>
			<td>lot_count_modifier</td>
			<td>lot_count</td>
			<td>current_remarks</td>
			<td>condition</td>
			<td>container_unique_id</td>
			<td>part_att_name_1</td>
			<td>part_att_val_1</td>
			<td>part_att_units_1</td>
			<td>part_att_detby_1</td>
			<td>part_att_madedate_1</td>
			<td>part_att_rem_1</td>
			<td>part_att_name_2</td>
			<td>part_att_val_2</td>
			<td>part_att_units_2</td>
			<td>part_att_detby_2</td>
			<td>part_att_madedate_2</td>
			<td>part_att_rem_2</td>
			<td>part_att_name_3</td>
			<td>part_att_val_3</td>
			<td>part_att_units_3</td>
			<td>part_att_detby_3</td>
			<td>part_att_madedate_3</td>
			<td>part_att_rem_3</td>
			<td>part_att_name_4</td>
			<td>part_att_val_4</td>
			<td>part_att_units_4</td>
			<td>part_att_detby_4</td>
			<td>part_att_madedate_4</td>
			<td>part_att_rem_4</td>
			<td>part_att_name_5</td>
			<td>part_att_val_5</td>
			<td>part_att_units_5</td>
			<td>part_att_detby_5</td>
			<td>part_att_madedate_5</td>
			<td>part_att_rem_5</td>
			<td>part_att_name_6</td>
			<td>part_att_val_6</td>
			<td>part_att_units_6</td>
			<td>part_att_detby_6</td>
			<td>part_att_madedate_6</td>
			<td>part_att_rem_6</td>
		</tr>
		<cfloop query="inT">
			<tr>
				<td>
					<cfif len(#collection_object_id#) gt 0 and
							(#validated_status# is 'VALID')>
						<a href="/SpecimenDetail.cfm?collection_object_id=#collection_object_id#"
							target="_blank">Specimen</a>
					<cfelseif left(validated_status,5) is 'NOTE:'>
						<a href="/SpecimenDetail.cfm?collection_object_id=#collection_object_id#"
							target="_blank">Specimen</a> (#validated_status#)
					<cfelse>
						#validated_status#
					</cfif>
				</td>
				<td>#institution_acronym#</td>
				<td>#collection_cde#</td>
				<td>#OTHER_ID_TYPE#</td>
				<td>#OTHER_ID_NUMBER#</td>
				<td>#part_name#</td>
				<td>#preserve_method#</td>
				<td>#disposition#</td>
				<td>#lot_count_modifier#</td>
				<td>#lot_count#</td>
				<td>#current_remarks#</td>
				<td>#condition#</td>
				<td>#container_unique_id#</td>
				<td>#part_att_name_1#</td>
				<td>#part_att_val_1#</td>
				<td>#part_att_units_1#</td>
				<td>#part_att_detby_1#</td>
				<td>#part_att_madedate_1#</td>
				<td>#part_att_rem_1#</td>
				<td>#part_att_name_2#</td>
				<td>#part_att_val_2#</td>
				<td>#part_att_units_2#</td>
				<td>#part_att_detby_2#</td>
				<td>#part_att_madedate_2#</td>
				<td>#part_att_rem_2#</td>
				<td>#part_att_name_3#</td>
				<td>#part_att_val_3#</td>
				<td>#part_att_units_3#</td>
				<td>#part_att_detby_3#</td>
				<td>#part_att_madedate_3#</td>
				<td>#part_att_rem_3#</td>
				<td>#part_att_name_4#</td>
				<td>#part_att_val_4#</td>
				<td>#part_att_units_4#</td>
				<td>#part_att_detby_4#</td>
				<td>#part_att_madedate_4#</td>
				<td>#part_att_rem_4#</td>
				<td>#part_att_name_5#</td>
				<td>#part_att_val_5#</td>
				<td>#part_att_units_5#</td>
				<td>#part_att_detby_5#</td>
				<td>#part_att_madedate_5#</td>
				<td>#part_att_rem_5#</td>
				<td>#part_att_name_6#</td>
				<td>#part_att_val_6#</td>
				<td>#part_att_units_6#</td>
				<td>#part_att_detby_6#</td>
				<td>#part_att_madedate_6#</td>
				<td>#part_att_rem_6#</td>
			</tr>
		</cfloop>
	</table>
	</cfoutput>
	<cfquery name="allValid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select count(*) as cnt from cf_temp_parts where substr(validated_status,1,5) NOT IN
			('VALID','NOTE:')
	</cfquery>
	<cfif #allValid.cnt# is 0>
		<a href="BulkloadNewParts.cfm?action=loadToDb">Load these parts....</a>
	<cfelse>
		You must fix everything above to proceed.
	</cfif>

</cfif>

<!-------------------------------------------------------------------------------------------->

<cfif #action# is "loadToDb">

<cfoutput>
	<cfquery name="getTempData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select * from cf_temp_parts where validated_status not in ('LOADED') or validated_status is null
	</cfquery>
	<cfquery name= "getEntBy" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		SELECT agent_id FROM agent_name WHERE agent_name = '#session.username#'
	</cfquery>
	<cfif getEntBy.recordcount is 0>
		<cfabort showerror = "You aren't a recognized agent!">
	<cfelseif getEntBy.recordcount gt 1>
		<cfabort showerror = "Your login has has multiple matches.">
	</cfif>
	<cfset enteredbyid = getEntBy.agent_id>
	<cftransaction>
	<cfloop query="getTempData">
	<cfif len(#use_part_id#) is 0 <!---AND len(#container_unique_id#) gt 0--->>
		<cfquery name="NEXTID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select sq_collection_object_id.nextval NEXTID from dual
		</cfquery>
		<cfquery name="updateColl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			INSERT INTO coll_object (
				COLLECTION_OBJECT_ID,
				COLL_OBJECT_TYPE,
				ENTERED_PERSON_ID,
				COLL_OBJECT_ENTERED_DATE,
				LAST_EDITED_PERSON_ID,
				COLL_OBJ_DISPOSITION,
				LOT_COUNT_MODIFIER,
				LOT_COUNT,
				CONDITION,
				FLAGS )
			VALUES (
				#NEXTID.NEXTID#,
				'SP',
				#enteredbyid#,
				sysdate,
				#enteredbyid#,
				'#DISPOSITION#',
				'#lot_count_modifier#',
				#lot_count#,
				'#condition#',
				0 )
		</cfquery>
		<cfquery name="newTiss" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			INSERT INTO specimen_part (
				  COLLECTION_OBJECT_ID,
				  PART_NAME,
				  PRESERVE_METHOD,
				  DERIVED_FROM_cat_item )
				VALUES (
					#NEXTID.NEXTID#,
				  '#PART_NAME#',
				  '#PRESERVE_METHOD#'
					,#collection_object_id# )
		</cfquery>
		<cfif len(#current_remarks#) gt 0>
				<!---- new remark --->
				<cfquery name="newCollRem" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					INSERT INTO coll_object_remark (collection_object_id, coll_object_remarks)
					VALUES (sq_collection_object_id.currval, '#current_remarks#')
				</cfquery>
		</cfif>
		<cfif len(#changed_date#) gt 0>
			<cfquery name="change_date" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				update SPECIMEN_PART_PRES_HIST set CHANGED_DATE = to_date('#CHANGED_DATE#', 'YYYY-MM-DD') where collection_object_id =#NEXTID.NEXTID# and is_current_fg = 1
			</cfquery>
		</cfif>
		<cfif len(#container_unique_id#) gt 0>
			<cfquery name="part_container_id" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select container_id from coll_obj_cont_hist where collection_object_id = #NEXTID.NEXTID#
			</cfquery>
				<cfquery name="upPart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					update container set parent_container_id=#parent_container_id#
					where container_id = #part_container_id.container_id#
				</cfquery>
			<cfif #len(change_container_type)# gt 0>
				<cfquery name="upPart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					update container set
					container_type='#change_container_type#'
					where container_id=#parent_container_id#
				</cfquery>
			</cfif>
		</cfif>

		<cfif len(#part_att_name_1#) GT 0>
			<cfif len(#part_att_detby_1#) GT 0>
				<cfquery name="a" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select agent_id from agent_name where agent_name = trim('#part_att_detby_1#')
				</cfquery>
				<cfset numAgentID = a.agent_id>
			<cfelse>
				<cfset  numAgentID = "NULL">
			</cfif>
			<cfquery name="addPartAtt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				insert into SPECIMEN_PART_ATTRIBUTE(collection_object_id, attribute_type, attribute_value, attribute_units, determined_date, determined_by_agent_id, attribute_remark)
				values(sq_collection_object_id.currval, '#part_att_name_1#', '#part_att_val_1#', '#part_att_units_1#', '#part_att_madedate_1#', #numAgentId#, '#part_att_rem_1#')
			</cfquery>
		</cfif>
		<cfif len(#part_att_name_2#) GT 0>
			<cfif len(#part_att_detby_2#) GT 0>
				<cfquery name="a" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select agent_id from agent_name where agent_name = trim('#part_att_detby_2#')
				</cfquery>
				<cfset numAgentID = a.agent_id>
			<cfelse>
				<cfset  numAgentID = "NULL">
			</cfif>
			<cfquery name="addPartAtt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				insert into SPECIMEN_PART_ATTRIBUTE(collection_object_id, attribute_type, attribute_value, attribute_units, determined_date, determined_by_agent_id, attribute_remark)
				values(sq_collection_object_id.currval, '#part_att_name_2#', '#part_att_val_2#', '#part_att_units_2#', '#part_att_madedate_2#', #numAgentId#, '#part_att_rem_2#')
			</cfquery>
		</cfif>
		<cfif len(#part_att_name_3#) GT 0>
			<cfif len(#part_att_detby_3#) GT 0>
				<cfquery name="a" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select agent_id from agent_name where agent_name = trim('#part_att_detby_3#')
				</cfquery>
				<cfset numAgentID = a.agent_id>
			<cfelse>
				<cfset  numAgentID = "NULL">
			</cfif>
			<cfquery name="addPartAtt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				insert into SPECIMEN_PART_ATTRIBUTE(collection_object_id, attribute_type, attribute_value, attribute_units, determined_date, determined_by_agent_id, attribute_remark)
				values(sq_collection_object_id.currval, '#part_att_name_3#', '#part_att_val_3#', '#part_att_units_3#', '#part_att_madedate_3#', #numAgentId#, '#part_att_rem_3#')
			</cfquery>
		</cfif>
		<cfif len(#part_att_name_4#) GT 0>
			<cfif len(#part_att_detby_4#) GT 0>
				<cfquery name="a" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select agent_id from agent_name where agent_name = trim('#part_att_detby_4#')
				</cfquery>
				<cfset numAgentID = a.agent_id>
			<cfelse>
				<cfset  numAgentID = "NULL">
			</cfif>
			<cfquery name="addPartAtt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				insert into SPECIMEN_PART_ATTRIBUTE(collection_object_id, attribute_type, attribute_value, attribute_units, determined_date, determined_by_agent_id, attribute_remark)
				values(sq_collection_object_id.currval, '#part_att_name_4#', '#part_att_val_4#', '#part_att_units_4#', '#part_att_madedate_4#', #numAgentId#, '#part_att_rem_4#')
			</cfquery>
		</cfif>
		<cfif len(#part_att_name_5#) GT 0>
			<cfif len(#part_att_detby_5#) GT 0>
				<cfquery name="a" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select agent_id from agent_name where agent_name = trim('#part_att_detby_5#')
				</cfquery>
				<cfset numAgentID = a.agent_id>
			<cfelse>
				<cfset  numAgentID = "NULL">
			</cfif>
			<cfquery name="addPartAtt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				insert into SPECIMEN_PART_ATTRIBUTE(collection_object_id, attribute_type, attribute_value, attribute_units, determined_date, determined_by_agent_id, attribute_remark)
				values(sq_collection_object_id.currval, '#part_att_name_5#', '#part_att_val_5#', '#part_att_units_5#', '#part_att_madedate_5#', #numAgentId#, '#part_att_rem_5#')
			</cfquery>
		</cfif>
		<cfif len(#part_att_name_6#) GT 0>
			<cfif len(#part_att_detby_6#) GT 0>
				<cfquery name="a" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select agent_id from agent_name where agent_name = trim('#part_att_detby_6#')
				</cfquery>
				<cfset numAgentID = a.agent_id>
			<cfelse>
				<cfset  numAgentID = "NULL">
			</cfif>
			<cfquery name="addPartAtt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				insert into SPECIMEN_PART_ATTRIBUTE(collection_object_id, attribute_type, attribute_value, attribute_units, determined_date, determined_by_agent_id, attribute_remark)
				values(sq_collection_object_id.currval, '#part_att_name_6#', '#part_att_val_6#', '#part_att_units_6#', '#part_att_madedate_6#', #numAgentId#, '#part_att_rem_6#')
			</cfquery>
		</cfif>

	<cfelse>
	<!--- there is an existing matching container that is not in a parent_container;
		all we need to do is move the container to a parent IF it exists and is specified, or nothing otherwise --->
		<cfif len(#disposition#) gt 0>
			<cfquery name="upDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				update coll_object set COLL_OBJ_DISPOSITION = '#disposition#' where collection_object_id = #use_part_id#
			</cfquery>
		</cfif>
		<cfif len(#condition#) gt 0>
			<cfquery name="upCond" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				update coll_object set condition = '#condition#' where collection_object_id = #use_part_id#
			</cfquery>
		</cfif>
		<cfif len(#lot_count#) gt 0>
			<cfquery name="upCond" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				update coll_object set lot_count = #lot_count#, lot_count_modifier='#lot_count_modifier#' where collection_object_id = #use_part_id#
			</cfquery>
		</cfif>
		<cfif len(#new_preserve_method#) gt 0>
			<cfquery name="change_preservemethod" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				update SPECIMEN_PART set PRESERVE_METHOD = '#NEW_PRESERVE_METHOD#' where collection_object_id =#use_part_id#
			</cfquery>
		</cfif>
		<cfif len(#append_to_remarks#) gt 0>
			<cfquery name="remarksCount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select * from coll_object_remark where collection_object_id = #use_part_id#
			</cfquery>
			<cfif remarksCount.recordcount is 0>
				<cfquery name="insertRemarks" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					INSERT INTO coll_object_remark (collection_object_id, coll_object_remarks)
					VALUES (#use_part_id#, '#append_to_remarks#')
				</cfquery>
			<cfelse>
				<cfquery name="updateRemarks" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					update coll_object_remark
					set coll_object_remarks = DECODE(coll_object_remarks, null, '#append_to_remarks#', coll_object_remarks || '; #append_to_remarks#')
					where collection_object_id = #use_part_id#
				</cfquery>
			</cfif>
		</cfif>
		<cfif len(#container_unique_id#) gt 0>
			<cfquery name="part_container_id" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select container_id from coll_obj_cont_hist where collection_object_id = #use_part_id#
			</cfquery>
				<cfquery name="upPart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					update container set parent_container_id=#parent_container_id#
					where container_id = #part_container_id.container_id#
				</cfquery>
			<cfif #len(change_container_type)# gt 0>
				<cfquery name="upPart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					update container set
					container_type='#change_container_type#'
					where container_id=#parent_container_id#
				</cfquery>
			</cfif>
		</cfif>
		<cfif len(#changed_date#) gt 0>
			<cfquery name="change_date" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				update SPECIMEN_PART_PRES_HIST set CHANGED_DATE = to_date('#CHANGED_DATE#', 'YYYY-MM-DD') where collection_object_id =#use_part_id# and is_current_fg = 1
			</cfquery>
		</cfif>
	</cfif>
	<cfquery name="upLoaded" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		update cf_temp_parts set validated_status = 'LOADED'
	</cfquery>
	</cfloop>
	</cftransaction>

	Spiffy, all done.
	<a href="/SpecimenResults.cfm?collection_object_id=#valuelist(getTempData.collection_object_id)#">
		See in Specimen Results
	</a>
</cfoutput>
</cfif>
         </div>
<cfinclude template="/includes/_footer.cfm">
