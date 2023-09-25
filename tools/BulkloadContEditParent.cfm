<!--- special case handling to dump problem data as csv --->
<cfif isDefined("action") AND action is "dumpProblems">
	<cfquery name="getProblemData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		SELECT container_unique_id,parent_unique_id,container_type,container_name, 
			description, remarks, width, height, length, number_positions,
			status 
		FROM cf_temp_cont_edit 
		WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
	</cfquery>
	<cfinclude template="/shared/component/functions.cfc">
	<cfset csv = queryToCSV(getProblemData)>
	<cfheader name="Content-Type" value="text/csv">
	<cfoutput>#csv#</cfoutput>
	<cfabort>
</cfif>
<!--- end special case dump of problems --->

<cfset fieldlist = "container_unique_id,parent_unique_id,container_type,container_name,description,remarks,width,height,length,number_positions">
<cfset fieldTypes ="CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_DECIMAL,CF_SQL_DECIMAL,CF_SQL_DECIMAL,CF_SQL_DECIMAL">
<cfset requiredfieldlist = "container_unique_id,container_type,container_name">

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
<cfset pageTitle = "Bulk Edit Container">
<cfinclude template="/shared/_header.cfm">
<cfif not isDefined("action") OR len(action) EQ 0><cfset action="nothing"></cfif>
<main class="container py-3" id="content">
	<h1 class="h2 mt-2">Bulkload Container Edit Parent</h1>

	<cfif #action# is "nothing">
		<cfoutput>
			<p>This tool is used to edit container information and/or move parts to a different parent container.</p>
			<p>Upload a comma-delimited text file (csv).  Include column headings, spelled exactly as below.  Additional colums will be ignored</p>
			<span class="btn btn-xs btn-info" onclick="document.getElementById('template').style.display='block';">View template</span>
			<div id="template" style="display:none;margin: 1em 0;">
				<label for="templatearea" class="data-entry-label">
					Copy this header line and save it as a .csv file (<a href="/tools/BulkloadContEditParent.cfm?action=getCSVHeader">download</a>)
				</label>
				<textarea rows="2" cols="90" id="templatearea" class="w-100 data-entry-textarea">#fieldlist#</textarea>
			</div>
			<p>Columns in <span class="text-danger">red</span> are required; others are optional:</p>
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
			<cfform name="atts" method="post" enctype="multipart/form-data" action="/tools/BulkloadContEditParent.cfm">
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
				DELETE FROM cf_temp_cont_edit 
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			
			<!--- check for required fields in header line --->
			<cfset container_unique_id_exists = false>
			<cfset container_type_exists = false>
			<cfset container_name_exists = false>
			<cfloop from="1" to ="#ArrayLen(arrResult[1])#" index="col">
				<cfset header = arrResult[1][col]>
				<cfif ucase(header) EQ 'CONTAINER_UNIQUE_ID'><cfset container_unique_id_exists=true></cfif>
				<cfif ucase(header) EQ 'CONTAINER_TYPE'><cfset container_type_exists=true></cfif>
				<cfif ucase(header) EQ 'CONTAINER_NAME'><cfset container_name_exists=true></cfif>
			</cfloop>
			<cfif not (container_unique_id_exists AND container_type_exists AND container_name_exists)>
				<cfset message = "One or more required fields are missing in the header line of the csv file.">
				<cfif not container_unique_id_exits><cfset message = "#message# container_unique_id is missing."></cfif>
				<cfif not container_type_exits><cfset message = "#message# container_type is missing."></cfif>
				<cfif not container_name_exits><cfset message = "#message# container_name is missing."></cfif>
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
							insert into cf_temp_cont_edit
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
				Successfully loaded #loadedRows# records from the CSV file.  Next <a href="/tools/BulkloadContEditParent.cfm?action=validate">click to validate</a>.
			</h3>
		</cfoutput>
	</cfif>
	<!------------------------------------------------------->
	<cfif #action# is "validate">
		<h2 class="h3">Second step: Data Validation</h2>
		<cfoutput>
			<cfquery name="getCID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				update cf_temp_cont_edit set container_id=
				(select container_id from container where container.barcode = cf_temp_cont_edit.container_unique_id)
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="getCID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				update cf_temp_cont_edit set parent_container_id=
				(select container_id from container where container.barcode = cf_temp_cont_edit.parent_unique_id)
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="miac" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE cf_temp_cont_edit 
				SET status = 'container_not_found'
				WHERE container_id is null
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="miap" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE cf_temp_cont_edit 
				SET status = 'parent_container_not_found'
				WHERE parent_container_id is null and parent_unique_id is not null
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="miap" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE cf_temp_cont_edit 
				SET status = 'bad_container_type'
				WHERE container_type not in (select container_type from ctcontainer_type)
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="miap" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE cf_temp_cont_edit
				SET status = 'missing_label'
				WHERE CONTAINER_NAME is null
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>

				<!---
				*** labels deprecated in MCZbase ***
				<cfquery name="lq" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select container_id,parent_container_id,key from cf_temp_cont_edit
				</cfquery>
				<cfloop query="lq">
					<cfquery name="islbl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select container_type from container where container_id='#container_id#'
					</cfquery>
					<cfif islbl.container_type does not contain 'label'>
						<cfquery name="miap" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							update cf_temp_cont_edit set status = 'only_updates_to_labels'
							where key=#key#
								AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						</cfquery>
					</cfif>
				--->
				<!---
					<cfif len(parent_container_id) gt 0>
						<cfquery name="isplbl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							SELECT container_type from container 
							WHERE container_id = <cfqueryparam cfsqtype="CF_SQL_DECIMAL" value="#parent_container_id#">
						</cfquery>
						<cfif isplbl.container_type contains 'label'>
							<cfquery name="miapp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
								update cf_temp_cont_edit set status = 'parent_is_label'
								WHERE key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#key#">
									ANDusername = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						</cfquery>
						</cfif>
					</cfif>
				</cfloop>
				*** labels deprecated in MCZbase ***
				--->
	
			<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT CONTAINER_UNIQUE_ID, PARENT_UNIQUE_ID, CONTAINER_TYPE, CONTAINER_NAME, DESCRIPTION, REMARKS, WIDTH,
					HEIGHT, LENGTH, NUMBER_POSITIONS, CONTAINER_ID, PARENT_CONTAINER_ID, STATUS 
				FROM cf_temp_cont_edit
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="pf" dbtype="query">
				SELECT count(*) c 
				FROM data 
				WHERE status is not null
			</cfquery>
			<cfif pf.c gt 0>
				<h2>
					There is a problem with #pf.c# of #data.recordcount# row(s). See the STATUS column. (<a href="/tools/BulkloadContEditParent.cfm?action=dumpProblems">download</a>).
				</h2>
				<h3>
					Fix the problems in the data and <a href="/tools/BulkloadContEditParent.cfm">start again</a>.
				</h3>
			<cfelse>
				<h2>
					Validation checks passed. Look over the table below and <a href="/tools/BulkloadContEditParent.cfm?action=load">click to continue</a> if it all looks good.
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
		<h2 class="h3">Third step: Apply changes.</h2>
		<cfoutput>
			<cfquery name="getTempData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT * FROM cf_temp_cont_edit
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cftry>
				<cfset container_type_updates = 0>
				<cftransaction>
					<cfloop query="getTempData">
						<cfquery name="updateContainer" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="updateContainer_result">
							UPDATE
								container 
							SET
								parent_container_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#parent_container_id#">
							WHERE
								CONTAINER_ID= <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#part_CONTAINER_ID#">
						</cfquery>
						<cfset container_type_updates = container_type_updates + updateContainer_result.recordcount>
					</cfloop>
				</cftransaction>
				<h2>Updated types for #container_type_updates# containers.</h2>
			<cfcatch>
				<h2>There was a problem updating container types.</h2>
				<cfquery name="getProblemData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT container_unique_id,parent_unique_id,container_type,container_name, status 
					FROM cf_temp_cont_edit 
					WHERE status is not null
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<h3>Problematic Rows (<a href="/tools/BulkloadContEditParent.cfm?action=dumpProblems">download</a>)</h3>
				<table class='sortable table table-responsive table-striped d-lg-table'>
					<thead>
						<tr>
							<th>container_unique_id</th><th>parent_unique_id</th><th>container_type</th><th>container_name</th><th>status</th>
						</tr> 
					</thead>
					<tbody>
						<cfloop query="getProblemData">
							<tr>
								<td>#getProblemData.container_unique_id#</td>
								<td>#getProblemData.parent_unique_id#</td>
								<td>#getProblemData.container_type#</td>
								<td>#getProblemData.container_name#</td>
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
					<cfset container_updates = 0>
					<cfloop query="getTempData">
						<cfset problem_key = getTempData.key>
						<cfquery name="updateContainer" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="updateContainer_result">
							UPDATE
								container 
							SET
								label=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#CONTAINER_NAME#">,
								DESCRIPTION=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#DESCRIPTION#">,
								PARENT_INSTALL_DATE=sysdate,
								CONTAINER_REMARKS=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#remarks#">
								<cfif len(#WIDTH#) gt 0>
									,WIDTH=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#WIDTH#">
								</cfif>
								<cfif len(#HEIGHT#) gt 0>
									,HEIGHT=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#HEIGHT#">
								</cfif>
								<cfif len(#LENGTH#) gt 0>
									,LENGTH=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#LENGTH#">
								</cfif>
								<cfif len(#NUMBER_POSITIONS#) gt 0>
									,NUMBER_POSITIONS=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#NUMBER_POSITIONS#">
								</cfif>
								<cfif len(#parent_container_id#) gt 0>
									,parent_container_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#parent_container_id#">
								</cfif>
							WHERE
								CONTAINER_ID=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#CONTAINER_ID#">
						</cfquery>
						<cfset container_updates = container_updates + updateContainer_result.recordcount>
					</cfloop>
					<cftransaction action="commit">
				<cfcatch>
					<cftransaction action="rollback">
					<cfquery name="getProblemData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						SELECT container_unique_id,parent_unique_id,container_type,container_name, status 
						FROM cf_temp_cont_edit 
						WHERE key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#problem_key#">
					</cfquery>
					<h3>Error updating row (#container_updates + 1#): #cfcatch.message#</h3>
					<table class='sortable table table-responsive table-striped d-lg-table'>
						<thead>
							<tr>
								<th>container_unique_id</th><th>parent_unique_id</th><th>container_type</th><th>container_name</th><th>status</th>
							</tr> 
						</thead>
						<tbody>
							<cfloop query="getProblemData">
								<tr>
									<td>#getProblemData.container_unique_id#</td>
									<td>#getProblemData.parent_unique_id#</td>
									<td>#getProblemData.container_type#</td>
									<td>#getProblemData.container_name#</td>
									<td>#getProblemData.status#</td>
								</tr> 
							</cfloop>
						</tbody>
					</table>
					<cfrethrow>
				</cfcatch>
				</cftry>
			</cftransaction>
			<h2>Updated #container_updates# containers.</h2>
			<h2>Success, changes applied.</h2>
			<!--- cleanup --->
			<cfquery name="clearTempTable" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="clearTempTable_result">
				DELETE FROM cf_temp_cont_edit 
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
		</cfoutput>
	</cfif>

</main>
<cfinclude template="/shared/_footer.cfm">
