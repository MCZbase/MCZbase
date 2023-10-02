<cfif isDefined("action") AND action is "dumpProblems">
	<cfquery name="getProblemData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		SELECT collection_cde,other_id_type,other_id_number,part_name,preserve_method,lot_count,lot_count_modifier,condition
		FROM cf_temp_parts
		WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
	</cfquery>
	<cfinclude template="/shared/component/functions.cfc"><!---need to add to functions.cfc page--->
	<cfset csv = queryToCSV(getProblemData)>
	<cfheader name="Content-Type" value="text/csv">
	<cfoutput>#csv#</cfoutput>
	<cfabort>
</cfif>
<cfset fieldlist = "collection_cde,other_id_type,other_id_number,part_name,preserve_method,lot_count,lot_count_modifier,condition">
<cfset fieldTypes ="CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR">
<cfset requiredfieldlist = "collection_cde,other_id_type,other_id_number,part_name,preserve_method,lot_count,lot_count_modifier,condition">
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
					Copy this header line and save it as a .csv file (<a href="/tools/BulkloadNewParts.cfm?action=getCSVHeader">download</a>)
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
			<cfform name="atts" method="post" enctype="multipart/form-data" action="/tools/BulkloadNewParts.cfm">
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
			<cfset COLLECTION_CDE_exists = false>
			<cfset OTHER_ID_TYPE_exists = false>
			<cfset OTHER_ID_NUMBER_exists = false>
			<cfset PART_NAME_exists = false>
			<cfset PRESERVE_METHOD_exists = false>
			<cfset LOT_COUNT_exists = false>
			<cfset LOT_COUNT_MODIFIER_exists = false>
			<cfset CONDITION_exists = false>
	
			<cfloop from="1" to ="#ArrayLen(arrResult[1])#" index="col">
				<cfset header = arrResult[1][col]>
				<cfif ucase(header) EQ 'COLLECTION_CDE'><cfset COLLECTION_CDE_exists=true></cfif>
				<cfif ucase(header) EQ 'OTHER_ID_TYPE'><cfset OTHER_ID_TYPE_exists=true></cfif>
				<cfif ucase(header) EQ 'OTHER_ID_NUMBER'><cfset OTHER_ID_NUMBER_exists=true></cfif>
				<cfif ucase(header) EQ 'PART_NAME'><cfset PART_NAME_exists=true></cfif>
				<cfif ucase(header) EQ 'PRESERVE_METHOD'><cfset PRESERVE_METHOD_exists=true></cfif>
				<cfif ucase(header) EQ 'LOT_COUNT'><cfset LOT_COUNT_exists=true></cfif>
				<cfif ucase(header) EQ 'LOT_COUNT_MODIFIER'><cfset LOT_COUNT_MODIFIER_exists=true></cfif>
				<cfif ucase(header) EQ 'CONDITION'><cfset CONDITION_exists=true></cfif>
		
			</cfloop>
			<cfif not (COLLECTION_CDE_exists AND OTHER_ID_TYPE_exists AND OTHER_ID_NUMBER_exists AND PART_NAME_exists AND PRESERVE_METHOD_exists AND LOT_COUNT_exists AND LOT_COUNT_MODIFIER_exists AND CONDITION_exists AND DERIVED_FROM_CAT_ITEM)>
				<cfset message = "One or more required fields are missing in the header line of the csv file.">
				<cfif not COLLECTION_CDE_exists><cfset message = "#message# COLLECTION_CDE is missing."></cfif>
				<cfif not OTHER_ID_TYPE_exists><cfset message = "#message# OTHER_ID_TYPE is missing."></cfif>
				<cfif not OTHER_ID_NUMBER_exists><cfset message = "#message# OTHER_ID_NUMBER is missing."></cfif>
				<cfif not PART_NAME_exists><cfset message = "#message# PART_NAME is missing."></cfif>
				<cfif not PRESERVE_METHOD_exists><cfset message = "#message# PRESERVE_METHOD is missing."></cfif>
				<cfif not LOT_COUNT_exists><cfset message = "#message# LOT_COUNT is missing."></cfif>
				<cfif not LOT_COUNT_MODIFIER_exists><cfset message = "#message# LOT_COUNT_MODIFIER is missing."></cfif>
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
				Successfully loaded #loadedRows# records from the CSV file.  Next <a href="/tools/BulkloadNewParts.cfm?action=validate">click to validate</a>.
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
					select sp.collection_object_id
					from specimen_part sp, cataloged_item ci
					where sp.derived_from_cat_item = ci.collection_object_id
					and ci.collection_cde = cf_temp_parts.collection_cde
					and ci.cat_num = cf_temp_parts.other_id_number
				) 
				where username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
<!---			<cfquery name="getCID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				update cf_temp_parts set DERIVED_FROM_CAT_ITEM = 
				(
				select sp.derived_from_cat_item
					from specimen_part sp, cataloged_item ci
					where sp.derived_from_cat_item = ci.collection_object_id
					and ci.collection_cde = cf_temp_parts.collection_cde
					and ci.cat_num = cf_temp_parts.other_id_number
				) 
				where username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>--->
			<cfquery name="miac" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				update cf_temp_parts 
				SET validated_status = 'part_not_found'
				WHERE collection_object_id is null
				and username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="miac" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				update cf_temp_parts 
				SET validated_status = 'part_name_not_found'
				WHERE part_name is null
				and username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT OTHER_ID_TYPE,OTHER_ID_NUMBER,COLLECTION_OBJECT_ID,COLLECTION_CDE,PART_NAME,PRESERVE_METHOD,LOT_COUNT,LOT_COUNT_MODIFIER,CONDITION,VALIDATED_STATUS 
				FROM cf_temp_parts
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="pf" dbtype="query">
				SELECT count(*) c 
				FROM data 
				WHERE validated_status is not null
			</cfquery>
			<cfif pf.c gt 0>
				<h2>
					There is a problem with #pf.c# of #data.recordcount# row(s). See the STATUS column. (<a href="/tools/BulkloadNewParts.cfm?action=validate">download</a>).
				</h2>
				<h3>
					Fix the problems in the data and <a href="/tools/BulkloadNewParts.cfm">start again</a>.
				</h3>
			<cfelse>
				<h2>
					Validation checks passed. Look over the table below and <a href="/tools/BulkloadNewParts.cfm?action=load">click to continue</a> if it all looks good.
				</h2>
			</cfif>
			<table class='sortable table table-responsive table-striped d-lg-table'>
				<thead>
					<tr>
						<th>OTHER_ID_TYPE</th>
						<th>OTHER_ID_NUMBER</th>
						<th>COLLECTION_CDE</th>
						<th>PART_NAME</th>
						<th>PRESERVE_METHOD</th>
						<th>LOT_COUNT</th>
						<th>LOT_COUNT_MODIFIER</th>
						<th>CONDITION</th>
						<th>VALIDATED_STATUS</th>
					</tr>
				<tbody>
					<cfloop query="data">
						<tr>
							<td>#data.OTHER_ID_TYPE#</td>
							<td>#data.OTHER_ID_NUMBER#</td>
							<td>#data.COLLECTION_CDE#</td>
							<td>#data.PART_NAME#</td>
							<td>#data.PRESERVE_METHOD#</td>
							<td>#data.lot_count#</td>
							<td>#data.lot_count_modifier#</td>
							<td>#data.condition#</td>
							<td><strong>#VALIDATED_STATUS#</strong></td>
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
				<cfset part_updates = 0>
					<cftransaction>
						<cfset install_date = ''>
						<cfloop query="getTempData">
							<cfquery name="updatePart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="updatePart_result">
							insert into 
								specimen_part 
									(collection_object_id,part_name,preserve_method) 
								values (#collection_object_id#,'#part_name#','#preserve_method#')
							</cfquery>
							<cfset part_updates = part_updates + updatePart_result.recordcount>
						</cfloop>
						<cfloop query="getTempData">
							<cfquery name="updatePart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="updatePart_result">
							insert into 
								coll_object 
									(collection_object_id,lot_count,lot_count_modifier,condition,derived_from_cat_item,entered_person_id) 
								values (#collection_object_id#,#lot_count#,#lot_count_modifier#,'#condition#',derived_from_cat_item,'#username#')
							</cfquery>
							<cfset part_updates = part_updates + updatePart_result.recordcount>
						</cfloop>
					</cftransaction> 
					<div class="container">
						<div class="row">
							<div class="col-12 mx-auto">
								<h2 class="h3">Updated #part_updates# part(s).</h2>
							</div>
						</div>
					</div>
				<cfcatch>
					<h2>There was a problem updating parts.</h2>
					<cfquery name="getProblemData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						SELECT *
						FROM cf_temp_parts 
						WHERE validated_status is not null
							AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
					</cfquery>
					<h3>Problematic Rows (<a href="/tools/BulkloadNewParts.cfm?action=dumpProblems">download</a>)</h3>
					<table class='sortable table table-responsive table-striped d-lg-table'>
						<thead>
							<tr>
								<th>COLLECTION_CDE</th>
								<th>OTHER_ID_TYPE</th>
								<th>OTHER_ID_NUMBER</th>
								<th>PART_NAME</th>
								<th>PRESERVE_METHOD</th>
								<th>LOT_COUNT</th>
								<th>LOT_COUNT_MODIFIER</th>
								<th>CONDITION</th>
								<th>VALIDTED_STATUS</th>
							</tr> 
						</thead>
						<tbody>
							<cfloop query="getProblemData">
								<tr>
									<td>#getProblemData.COLLECTION_CDE#</td>
									<td>#getProblemData.OTHER_ID_TYPE#</td>
									<td>#getProblemData.OTHER_ID_NUMBER#</td>
									<td>#getProblemData.PART_NAME#</td>
									<td>#getProblemData.PRESERVE_METHOD#</td>
									<td>#getProblemData.LOT_COUNT#</td>
									<td>#getProblemData.LOT_COUNT_MODIFIER#</td>
									<td>#getProblemData.CONDITION#</td>
									<td><strong>#VALIDTED_STATUS#</strong></td>
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
					<cfset part_updates = 0>
					<cfloop query="getTempData">
						<cfset problem_key = getTempData.key>
						<cfquery name="NEXTID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							select sq_collection_object_id.nextval NEXTID from dual
						</cfquery>
						<cfquery name="updatePart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="updatePart_result">
							INSERT INTO coll_object (
								COLLECTION_OBJECT_ID,
								COLL_OBJECT_TYPE,
								ENTERED_PERSON_ID,
								condition,
								lot_count,
								lot_count_modifier,
								condition,
								COLL_OBJECT_ENTERED_DATE
							)
							VALUES (
								#NEXTID.NEXTID#,
								'SP',
								#enteredbyid#,
								#lot_count#,
								#lot_count_modifier#,
								#condition#,
								sysdate 
							)
							where username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						</cfquery>
						<cfset part_container_updates = part_container_updates + updatePartContainer_result.recordcount>
					</cfloop>
					<cftransaction action="commit">
				<cfcatch>
					<cftransaction action="rollback">
						<cfquery name="getProblemData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						SELECT other_id_type,other_id_number,collection_cde,part_name,preserve_method,lot_count,lot_count_modifier,condition,validated_status 
						FROM cf_temp_parts 
						WHERE validated_status is not null
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						</cfquery>
						<h3>Error updating row (#part_updates + 1#): #cfcatch.message#</h3>
						<table class='sortable table table-responsive table-striped d-lg-table'>
							<thead>
								<tr>
									<th>other_id_type</th>
									<th>other_id_number</th>
									<th>collection_cde</th>
									<th>part_name</th>
									<th>preserve_method</th>
									<th>lot_count</th>
									<th>lot_count_modifier</th>
									<th>condition</th>
									<th>validated_status</th>
								</tr> 
							</thead>
							<tbody>
								<cfloop query="getProblemData">
									<tr>
										<td>#getProblemData.OTHER_ID_TYPE#</td>
										<td>#getProblemData.OTHER_ID_NUMBER#</td>
										<td>#getProblemData.COLLECTION_CDE#</td>
										<td>#getProblemData.PART_NAME#</td>
										<td>#getProblemData.PRESERVE_METHOD#</td>
										<td>#getProblemData.LOT_COUNT#</td>
										<td>#getProblemData.LOT_COUNT_MODIFIER#</td>
										<td>#getProblemData.CONDITION#</td>
										<td>#getProblemData.validated_status#</td>
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
				DELETE FROM cf_temp_parts 
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
		</cfoutput>
	</cfif>
</main>
<cfinclude template="/shared/_footer.cfm">
	
		
		
	