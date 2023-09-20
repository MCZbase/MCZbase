<cfif isDefined("action") AND action is "dumpProblems">
	<cfquery name="getProblemData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		SELECT OTHER_ID_TYPE,OTHER_ID_NUMBER,COLLECTION_CDE,INSTITUTION_ACRONYM,PART_NAME,PRESERVE_METHOD,CONTAINER_UNIQUE_ID
		FROM cf_temp_barcode_parts
		WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
	</cfquery>
	<cfinclude template="/shared/component/functions.cfc"><!---need to add to functions.cfc page--->
	<cfset csv = queryToCSV(getProblemData)>
	<cfheader name="Content-Type" value="text/csv">
	<cfoutput>#csv#</cfoutput>
	<cfabort>
</cfif>
<cfset fieldlist = "OTHER_ID_TYPE,OTHER_ID_NUMBER,COLLECTION_CDE,INSTITUTION_ACRONYM,PART_NAME,PRESERVE_METHOD,CONTAINER_UNIQUE_ID">
<cfset fieldTypes ="CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR">
<cfset requiredfieldlist = "OTHER_ID_TYPE,OTHER_ID_NUMBER,COLLECTION_CDE,INSTITUTION_ACRONYM,PART_NAME,PRESERVE_METHOD,CONTAINER_UNIQUE_ID">
	

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
<cfset pageTitle = "Bulk Part Container">
<cfinclude template="/shared/_header.cfm">
<cfif not isDefined("action") OR len(action) EQ 0><cfset action="nothing"></cfif>
<main class="container py-3" id="content">
	<h1 class="h2 mt-2">Bulkload Part Container</h1>
	<cfif #action# is "nothing">
		<cfoutput>
			<p>Use this form to put collection objects (that is, parts) in containers. Parts and containers must already exist. This form can be used for specimen records with multiple parts as long as the full names (name plus preserve method) of the parts are unique.</p>
			<p>Upload a comma-delimited text file (csv).  Include column headings, spelled exactly as below.  Additional colums will be ignored</p>
			<span class="btn btn-xs btn-info" onclick="document.getElementById('template').style.display='block';">View template</span>
			<div id="template" style="display:none;margin: 1em 0;">
				<label for="templatearea" class="data-entry-label">
					Copy this header line and save it as a .csv file (<a href="/tools/BulkloadPartContainer.cfm?action=getCSVHeader">download</a>)
				</label>
				<textarea rows="2" cols="90" id="templatearea" class="w-100 data-entry-textarea">#fieldlist#</textarea>
			</div>
			<p class="pt-2">Columns in <span class="text-danger">red</span> are required; others are optional:</p>
			<ul class="geol_hier">
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
				DELETE FROM MCZBASE.CF_TEMP_BARCODE_PARTS 
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			
			<!--- check for required fields in header line --->
			<cfset OTHER_ID_TYPE_exists = false>
			<cfset OTHER_ID_NUMBER_exists = false>
			<cfset COLLECTION_CDE_exists = false>
			<cfset INSTITUTION_ACRONYM_exists = false>
			<cfset PART_NAME_exists = false>
			<cfset PRESERVE_METHOD_exists = false>
			<cfset CONTAINER_UNIQUE_ID_exists = false>
			<cfloop from="1" to ="#ArrayLen(arrResult[1])#" index="col">
				<cfset header = arrResult[1][col]>
				<cfif ucase(header) EQ 'OTHER_ID_TYPE'><cfset OTHER_ID_TYPE_exists=true></cfif>
				<cfif ucase(header) EQ 'OTHER_ID_NUMBER'><cfset OTHER_ID_NUMBER_exists=true></cfif>
				<cfif ucase(header) EQ 'COLLECTION_CDE'><cfset COLLECTION_CDE_exists=true></cfif>
				<cfif ucase(header) EQ 'INSTITUTION_ACRONYM'><cfset INSTITUTION_ACRONYM_exists=true></cfif>
				<cfif ucase(header) EQ 'PART_NAME'><cfset PART_NAME_exists=true></cfif>
				<cfif ucase(header) EQ 'PRESERVE_METHOD'><cfset PRESERVE_METHOD_exists=true></cfif>
				<cfif ucase(header) EQ 'CONTAINER_UNIQUE_ID'><cfset CONTAINER_UNIQUE_ID_exists=true></cfif>
			</cfloop>
			<cfif not (OTHER_ID_TYPE_exists AND OTHER_ID_NUMBER_exists AND COLLECTION_CDE_exists AND INSTITUTION_ACRONYM_exists AND PART_NAME_exists AND PRESERVE_METHOD_exists AND CONTAINER_UNIQUE_ID_exists)>
				<cfset message = "One or more required fields are missing in the header line of the csv file.">
				<cfif not OTHER_ID_TYPE_exists><cfset message = "#message# OTHER_ID_TYPE is missing."></cfif>
				<cfif not OTHER_ID_NUMBER_exists><cfset message = "#message# OTHER_ID_NUMBER is missing."></cfif>
				<cfif not COLLECTION_CDE_exists><cfset message = "#message# COLLECTION_CDE is missing."></cfif>
				<cfif not INSTITUTION_ACRONYM_exists><cfset message = "#message# INSTITUTION_ACRONYM is missing."></cfif>
				<cfif not PART_NAME_exists><cfset message = "#message# PART_NAME is missing."></cfif>
				<cfif not PRESERVE_METHOD_exists><cfset message = "#message# PRESERVE_METHOD is missing."></cfif>
				<cfif not CONTAINER_UNIQUE_ID_exists><cfset message = "#message# CONTAINER_UNIQUE_ID is missing."></cfif>
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
							insert into MCZBASE.CF_TEMP_BARCODE_PARTS
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
				Successfully loaded #loadedRows# records from the CSV file.  Next <a href="/tools/BulkloadContEditParent.cfm?action=validate">click to validate</a>.
			</h3>
		</cfoutput>
	</cfif>
											
	<!------------------------------------------------------->
	<cfif #action# is "validate">
		<h2 class="h3">Second step: Data Validation</h2>
		<cfoutput>
			<cfquery name="getCID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				update cf_temp_barcode_parts cp set cp.collection_object_id = 
					(select sp.collection_object_id 
					from specimen_part sp, cataloged_item ci 
					where sp.derived_from_cat_item = ci.collection_object_id 
					and ci.collection_cde = cp.collection_cde
					and ci.cat_num = cp.other_id_number) 
				where <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="getCID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				update cf_temp_barcode_parts set container_id=
				(select container_id from container where container.barcode = cf_temp_barcode_parts.container_unique_id)
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="miac" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE cf_temp_barcode_parts 
				SET status = 'container_not_found'
				WHERE container_id is null
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="miap" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE cf_temp_barcode_parts 
				SET status = 'bad_container_type'
				WHERE container_type not in (select container_type from ctcontainer_type)
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="miap" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE cf_temp_barcode_parts
				SET status = 'missing_label'
				WHERE CONTAINER_NAME is null
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>

	
			<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT OTHER_ID_TYPE,OTHER_ID_NUMBER,COLLECTION_CDE,INSTITUTION_ACRONYM,PART_NAME,PRESERVE_METHOD,CONTAINER_UNIQUE_ID,COLLECTION_OBJECT_ID,PARENT_CONTAINER_ID,PART_CONTAINER_ID,PRINT_FG,CONTAINER_ID,STATUS 
				FROM cf_temp_barcode_parts
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="pf" dbtype="query">
				SELECT count(*) c 
				FROM data 
				WHERE status is not null
			</cfquery>
			<cfif pf.c gt 0>
				<h2>
					There is a problem with #pf.c# of #data.recordcount# row(s). See the STATUS column. (<a href="/tools/BulkloadPartContainer.cfm">download</a>).
				</h2>
				<h3>
					Fix the problems in the data and <a href="/tools/BulkloadPartContainer.cfm">start again</a>.
				</h3>
			<cfelse>
				<h2>
					Validation checks passed. Look over the table below and <a href="/tools/BulkloadPartContainer.cfm">click to continue</a> if it all looks good.
				</h2>
			</cfif>
			<table class='sortable table table-responsive table-striped d-lg-table'>
				<thead>
					<tr>
						<th>CONTAINER_UNIQUE_ID</th>
						<th>PARENT_UNIQUE_ID</th>
						<th>CONTAINER_TYPE</th>
						<th>CONTAINER_NAME</th>
						<th>DESCRIPTION</th>
						<th>REMARKS</th>
						<th>WIDTH</th>
						<th>HEIGHT</th>
						<th>LENGTH</th>
						<th>NUMBER_POSITIONS</th>
						<th>CONTAINER_ID</th>
						<th>PARENT_CONTAINER_ID</th>
						<th>STATUS</th>
					</tr>
				<tbody>
					<cfloop query="data">
						<tr>
							<td>#data.CONTAINER_UNIQUE_ID#</td>
							<td>#data.PARENT_UNIQUE_ID#</td>
							<td>#data.CONTAINER_TYPE#</td>
							<td>#data.CONTAINER_NAME#</td>
							<td>#data.DESCRIPTION#</td>
							<td>#data.REMARKS#</td>
							<td>#data.WIDTH#</td>
							<td>#data.HEIGHT#</td>
							<td>#data.LENGTH#</td>
							<td>#data.NUMBER_POSITIONS#</td>
							<td>#data.CONTAINER_ID#</td>
							<td>#data.PARENT_CONTAINER_ID#</td>
							<td><strong>#STATUS#</strong></td>
						</tr>
					</cfloop>
				</tbody>
			</table>
		</cfoutput>
	</cfif>
				
	<!-------------------------------------------------------------------------------------------->
	<cfif action is "load">
		<cfoutput>
			<h2 class="h3">Third step: Apply changes.</h2>
		</cfoutput>
			<cfquery name="getTempData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT * FROM cf_temp_barcode_parts
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
				#getTempData#
<!---			<cftry>
				<cfoutput>
				<cfset part_container_updates = 0>
					<cftransaction>
						<cfloop query="getTempData">
							<cfquery name="updatePart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="updatePart_result">
								UPDATE
									COLL_OBJ_CONT_HIST
								SET
									CONTAINER_ID = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getContID.CONTAINER_ID#">, installed_date = sysdate, current_container_fg = 1
								WHERE
									COLLECTION_OBJECT_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getCollObj.collection_object_id#">
							</cfquery>
							<cfset part_container_updates = part_container_updates + updatePart_result.recordcount>
						</cfloop>
					</cftransaction>
					<h2>Updated types for #part_container_updates# containers.</h2>
				</cfoutput>
				<cfcatch>
					<h2>There was a problem updating part container.</h2>
					<cfquery name="getProblemData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						SELECT OTHER_ID_TYPE, OTHER_ID_NUMBER, COLLECTION_CDE, INSTITUTION_ACRONYM, PART_NAME, PRESERVE_METHOD, CONTAINER_UNIQUE_ID
						FROM cf_temp_barcode_parts 
						WHERE status is not null
							AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
					</cfquery>
					<h3>Problematic Rows (<a href="/tools/BulkloadPartContainer.cfm?action=dumpProblems">download</a>)</h3>
					<table class='sortable table table-responsive table-striped d-lg-table'>
						<thead>
							<tr>
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
								<tr>
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
					<cfif coll_obj.collection_object_id gt 1>
					<cfset part_container_updates = 0>
					<cfloop query="getTempData">
						<cfset problem_key = getTempData.key>
						<cfquery name="updatePartContainer" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="updatePartContainer_result">
							UPDATE
								coll_obj_cont_hist 
							SET
								collection_object_id =<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#coll_obj.collection_object_id#">,
								CONTAINER_ID=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getContID#">,
								INSTALLED_DATE=sysdate,
								current_container_fg
							WHERE
								collection_object_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#coll_obj.collection_object_id#">
						</cfquery>
						<cfset part_container_updates = part_container_updates + updatePartContainer_result.recordcount>
					</cfloop>
					<cftransaction action="commit">
					<cfcatch>
						<cftransaction action="rollback">
						<cfquery name="getProblemData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							SELECT other_id_type, other_id_number, collection_cde, institutional_acronym, part_name, preserve_method, container_unique_id 
							FROM cf_temp_barcode_parts 
							WHERE key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#problem_key#">
						</cfquery>
						<h3>Error updating row (#container_updates + 1#): #cfcatch.message#</h3>
						<table class='sortable table table-responsive table-striped d-lg-table'>
							<thead>
								<tr>
									<th>other_id_type</th>
									<th>other_id_number</th>
									<th>collection_cde</th>
									<th>institutional_acronym</th>
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
			<cfoutput>
			<h2>Updated #container_updates# containers.</h2>
			<h2>Success, changes applied.</h2>
			</cfoutput>
			<cfquery name="clearTempTable" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="clearTempTable_result">
				DELETE FROM cf_temp_barcode_parts 
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>--->
	</cfif>
</main>
<cfinclude template="/shared/_footer.cfm">
