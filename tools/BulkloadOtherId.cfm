<!--- special case handling to dump problem data as csv --->
<cfif isDefined("action") AND action is "dumpProblems">
	<cfquery name="getProblemData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		SELECT status,collection_cde,institution_acronym,existing_other_id_type,existing_other_id_number,new_other_id_type,new_other_id_number
		FROM cf_temp_OIDS 
		WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
	</cfquery>
	<cfinclude template="/shared/component/functions.cfc">
	<cfset csv = queryToCSV(getProblemData)>
	<cfheader name="Content-Type" value="text/csv">
	<cfoutput>#csv#</cfoutput>
	<cfabort>
</cfif>
<!--- end special case dump of problems --->
<cfset fieldlist = "institution_acronym,collection_cde,existing_other_id_type,existing_other_id_number,new_other_id_type,new_other_id_number"><cfset fieldTypes ="CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR">
<cfset requiredfieldlist = "collection_cde,institution_acronym,existing_other_id_type,existing_other_id_number,new_other_id_type,new_other_id_number">

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
<cfset pageTitle = "Bulkload Other IDs">
<cfinclude template="/shared/_header.cfm">
<cfif not isDefined("action") OR len(action) EQ 0><cfset action="nothing"></cfif>
<main class="container py-3" id="content">
	<h1 class="h2 mt-2">Bulkload Other IDs</h1>
	<cfif #action# is "nothing">
		<cfoutput>
			<p>This tool is used to bulkload Other IDs.</p>
			<p>Upload a comma-delimited text file (csv).  Include column headings, spelled exactly as below.  Additional colums will be ignored</p>
			<span class="btn btn-xs btn-info" onclick="document.getElementById('template').style.display='block';">View template</span>
			<div id="template" style="display:none;margin: 1em 0;">
				<label for="templatearea" class="data-entry-label">
					Copy this header line and save it as a .csv file (<a href="/tools/BulkloadOtherId.cfm?action=getCSVHeader">download</a>)
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
			<cfform name="cits" method="post" enctype="multipart/form-data" action="/tools/BulkloadOtherId.cfm">
				<input type="hidden" name="Action" value="getFile">
				<input type="file" name="FiletoUpload" size="45">
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
		<!--- Set some constants to identify error cases in cfcatch block --->
		<cfset NO_COLUMN_ERR = "One or more required fields are missing in the header line of the csv file.">
		<cfset COLUMN_ERR = "Error inserting data">
		<cfoutput>
			<cftry>
				<cffile action="READ" file="#FiletoUpload#" variable="fileContent" charset="#cSet#">
				<cfset fileContent=replace(fileContent,"'","''","all")>
				<cfset arrResult = CSVToArray(CSV = fileContent.Trim()) />
			
				<!--- cleanup any incomplete work by the same user --->
				<cfquery name="clearTempTable" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="clearTempTable_result">
					DELETE FROM cf_temp_oids
					WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				
			<!--- check for required fields in header line --->
			
			<cfset institution_acronym_exists = false>
			<cfset collection_cde_exists = false>
			<cfset existing_other_id_type_exists = false>
			<cfset existing_other_id_number_exists = false>
			<cfset new_other_id_type_exists = false>
			<cfset new_other_id_number_exists = false>
			<cfloop from="1" to ="#ArrayLen(arrResult[1])#" index="col">
				<cfset header = arrResult[1][col]>
				<cfif ucase(header) EQ 'institution_acronym'><cfset institution_acronym_exists=true></cfif>
				<cfif ucase(header) EQ 'collection_cde'><cfset collection_cde_exists=true></cfif>
				<cfif ucase(header) EQ 'existing_other_id_type'><cfset existing_other_id_type_exists=true></cfif>
				<cfif ucase(header) EQ 'existing_other_id_number'><cfset existing_other_id_number_exists=true></cfif>
				<cfif ucase(header) EQ 'new_other_id_type'><cfset new_other_id_type_exists=true></cfif>
				<cfif ucase(header) EQ 'new_other_id_number'><cfset new_other_id_number_exists=true></cfif>
			</cfloop>
		<cfif not (institution_acronym_exists AND collection_cde_exists AND existing_other_id_type_exists AND existing_other_id_number_exists AND new_other_id_type_exists AND new_other_id_number_exists)>
				<cfset message = "One or more required fields are missing in the header line of the csv file.">
				<cfif not institution_acronym_exists><cfset message = "#message# institution_acronym is missing."></cfif>
				<cfif not collection_cde_exists><cfset message = "#message# collection_cde is missing."></cfif>
				<cfif not existing_other_id_type_exists><cfset message = "#message# existing_other_id_type is missing."></cfif>
				<cfif not existing_other_id_number_exists><cfset message = "#message# existing_other_id_number is missing."></cfif>
				<cfif not new_other_id_type_exists><cfset message = "#message# new_other_id_type is missing."></cfif>
				<cfif not new_other_id_number_exists><cfset message = "#message# new_other_id_number is missing."></cfif>
				<cfthrow message="#message#">
			</cfif>
				<cfset colNames="">
				<cfset loadedRows = 0>
				<cfset foundHighCount = 0>
				<cfset foundHighAscii = "">
				<cfset foundMultiByte = "">
				<!--- get the headers from the first row of the input, then iterate through the remaining rows inserting the data into the temp table. --->
				<cfloop from="1" to ="#ArrayLen(arrResult)#" index="row">
					<!--- obtain the values in the current row --->
					<cfset colVals="">
					<cfloop from="1" to ="#ArrayLen(arrResult[row])#" index="col">
						<cfset thisBit=arrResult[row][col]>
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
								insert into cf_temp_oids
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
						<cfcatch>
							<!--- identify the problematic row --->
							<cfset error_message="#COLUMN_ERR# from line #row# in input file.  <br>Header:[#colNames#] <br>Row:[#colVals#] <br>Error: #cfcatch.message#"><!--- " --->
							<cfif isDefined("cfcatch.queryError")>
								<cfset error_message = "#error_message# #cfcatch.queryError#">
							</cfif>
							<cfthrow message = "#error_message#">
						</cfcatch>
						</cftry>
					</cfif>
				</cfloop>
			
				<cfif foundHighCount GT 0>
					<h3 class="h3">Found characters where the encoding is probably important in the input data.</h3>
					<div>
						Showing #foundHighCount# examples.  If these do not appear as the correct characters, the file likely has a different encoding from the one you selected and
						you probably want to <a href="/tools/BulkloadOtherId.cfm">reload this file</a> selecting a different encoding.  If these appear as expected, then 
						you selected the correct encoding and can continue to validate or load.
					</div>
					<ul class="py-1" style="font-size: 1.2rem;">
						#foundHighAscii#
						#foundMultiByte#
					</ul>
				</cfif>
				<h3 class="h3">
					Successfully read #loadedRows# records from the CSV file.  Next <a href="/tools/BulkloadOtherId.cfm?action=validate">click to validate</a>.
				</h3>
			<cfcatch>
				<h3 class="h3">
					Failed to read the CSV file.  Fix the errors in the file and <a href="/tools/BulkloadOtherId.cfm">reload</a>
				</h3>
				<cfif isDefined("arrResult")>
					<cfset foundHighCount = 0>
					<cfset foundHighAscii = "">
					<cfset foundMultiByte = "">
					<cfloop from="1" to ="#ArrayLen(arrResult[1])#" index="col">
						<cfset thisBit=arrResult[1][col]>
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
						<h3 class="h3">Found characters with unexpected encoding in the header row.  This is probably the cause of your error.</h3>
						<div>
							Showing #foundHighCount# examples.  Did you select utf-16 or unicode for the encoding for a file that does not have multibyte encoding?
						</div>
						<ul class="py-1" style="font-size: 1.2rem;">
							#foundHighAscii#
							#foundMultiByte#
						</ul>
					</cfif>
				</cfif>
				<cfif Find("#NO_COLUMN_ERR#",cfcatch.message) GT 0>
					<ul class="py-1" style="font-size: 1.2rem;">
						<li>#cfcatch.message#</li>
					</ul>
				<cfelseif Find("#COLUMN_ERR#",cfcatch.message) GT 0>
					<ul class="py-1" style="font-size: 1.2rem;">
						<li>#cfcatch.message#</li>
					</ul>
				<cfelse>
					<cfdump var="#cfcatch#">
				</cfif>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfif>
<!-------------------------------------------------------------------------------------------->
<!-------------------------------------------------------------------------------------------->
<!------------------------------------------------------->
	<cfif #action# is "validate">
		<h2 class="h3">Second step: Data Validation</h2>
			<cfoutput>
			<cfquery name="getTempTableTypes" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT 
					existing_other_id_type, existing_other_id_type,key
				FROM 
					cf_temp_oids
				WHERE 
					username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfloop query="getTempTableTypes">
				<cfif getTempTableTypes.existing_other_id_type eq 'catalog number'>
					<!--- either based on catalog_number --->
					<cfquery name="getCID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						UPDATE
							cf_temp_oids
						SET
							collection_object_id = (
								select collection_object_id 
								from cataloged_item 
								where cat_num = cf_temp_oids.existing_other_id_number 
								and collection_cde = cf_temp_oids.collection_cde
							),
							status = null
						WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
							and key = <cfqueryparam cfsqltype="CF_SQL_decimal" value="#getTempTableTypes.key#"> 
					</cfquery>
				<cfelse>
					<!--- or on specified other identifier --->
					<cfquery name="getCID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						UPDATE
							cf_temp_oids
						SET
							collection_object_id= (
								select cataloged_item.collection_object_id from cataloged_item,coll_obj_other_id_num 
								where coll_obj_other_id_num.other_id_type = cf_temp_oids.existing_other_id_type 
								and cataloged_item.collection_cde = cf_temp_oids.collection_cde 
								and display_value= cf_temp_oids.existing_other_id_number
								and cataloged_item.collection_object_id = coll_obj_other_id_num.COLLECTION_OBJECT_ID
							),
							status = null
						WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
							and key = <cfqueryparam cfsqltype="CF_SQL_decimal" value="#getTempTableTypes.key#"> 
					</cfquery>
				</cfif>
			</cfloop>
			<cfquery name="flagMczAcronym" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE cf_temp_oids
				SET 
					status = concat(nvl2(status, status || '; ', ''),'INSTIUTION_ACRONYM is not "MCZ" (check case)')
				WHERE institution_acronym <> 'MCZ'
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="flagMczAcronym" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE cf_temp_oids
				SET 
					status = concat(nvl2(status, status || '; ', ''),'COLLECTION_CDE is not "Cryo, Ent, Herp, Ich, IP, IZ, Mala, Mamm, Orn, SC, VP" (check case)')
				WHERE collection_cde not in (select collection_cde from ctcollection_cde)
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="flagNoCollectionObject" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE cf_temp_oids
				SET 
					status = concat(nvl2(status, status || '; ', ''),' There is no match to a cataloged item on [' || existing_other_id_type || ']=[' || existing_other_id_number || '] in collection "' || collection_cde ||'"')
				WHERE collection_object_id IS NULL
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="flagNotMatchedExistOther_ID_Type1" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE cf_temp_oids
				SET 
					status = concat(nvl2(status, status || '; ', ''), 'Unknown existing_other_id_type: "' || existing_other_id_type ||'"&mdash;not on list')
				WHERE existing_other_id_type is not null 
					AND existing_other_id_type <> 'catalog number'
					AND existing_other_id_type not in (select other_id_type from ctcoll_other_id_type)
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="flagNotMatchedExistOther_ID_Type2" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE cf_temp_oids
				SET 
					status = concat(nvl2(status, status || '; ', ''), 'Unknown new_other_id_type: "' || new_other_id_type ||'"&mdash;not on list')
				WHERE new_other_id_type is not null 
					AND new_other_id_type <> 'catalog number'
					AND new_other_id_type not in (select other_id_type from ctcoll_other_id_type)
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<!---Missing data in required fields--->
			<cfloop list="#requiredfieldlist#" index="requiredField">
				<cfquery name="checkRequired" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					UPDATE cf_temp_oids
					SET 
						status = concat(nvl2(status, status || '; ', ''),'#requiredField# is missing')
					WHERE #requiredField# is null
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
			</cfloop>
			<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT collection_object_id,collection_cde,institution_acronym,existing_other_id_type,existing_other_id_number,new_other_id_type,new_other_id_number,status
				FROM cf_temp_oids
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="pf" dbtype="query">
				SELECT count(*) c 
				FROM data 
				WHERE status is not null
			</cfquery>
			<cfif pf.c gt 0>
				<h2>
					There is a problem with #pf.c# of #data.recordcount# row(s). See the STATUS column. (<a href="/tools/BulkloadOtherId.cfm?action=dumpProblems">download</a>).
				</h2>
				<h3>
					Fix the problems in the data and <a href="/tools/BulkloadOtherId.cfm">start again</a>.
				</h3>
			<cfelse>
				<h2>
					Validation checks passed. Look over the table below and <a href="/tools/BulkloadOtherId.cfm?action=load">click to continue</a> if it all looks good.
				</h2>
			</cfif>
			<table class='sortable table table-responsive table-striped d-lg-table'>
				<thead>
					<tr>
						<th>status</th>
						<th>collection_cde</th>
						<th>institution_acronym</th>
						<th>existing_other_id_type</th>
						<th>existing_other_id_number</th>
						<th>new_other_id_type</th>
						<th>new_other_id_number</th>
					</tr>
				<tbody>
					<cfloop query="data">
						<tr>
							<td><strong>#data.status#</strong></td>
							<td>#data.collection_cde#</td>
							<td>#data.institution_acronym#</td>
							<td>#data.existing_other_id_type#</td>
							<td>#data.existing_other_id_number#</td>
							<td>#data.new_other_id_type#</td>
							<td>#data.new_other_id_number#</td>
						</tr>
					</cfloop>
				</tbody>
			</table>
		</cfoutput>
	</cfif>
	<!-------------------------------------------------------------------------------------------->
	<!-------------------------------------------------------------------------------------------->
	<cfif action is "load">
		<h2 class="h3">Third step: Apply changes.</h2>
		<cfoutput>
			<cfset problem_key = "">
			<cftransaction>
				<cfquery name="getTempData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT * FROM cf_temp_oids
					WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cfquery name="getCounts" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT count(distinct collection_object_id) ctobj FROM cf_temp_oids
					WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cftry>
					<cfset otherid_updates = 0>
					<cfset otherid_updates1 = 0>
					<cfif getTempData.recordcount EQ 0>
						<cfthrow message="You have no rows to load in the attributes bulkloader table (cf_temp_oids).  <a href='/tools/BulkloadOtherIds.cfm'>Start over</a>"><!--- " --->
					</cfif>
					<cfloop query="getTempData">
						<cfset problem_key = getTempData.key>
						<cfquery name="updateOtherId" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="updateOtherId_result">
							insert into coll_obj_other_id_num (
								COLLECTION_OBJECT_ID, 
								OTHER_ID_TYPE,
								OTHER_ID_PREFIX,
								OTHER_ID_NUMBER,
								OTHER_ID_SUFFIX,
								DISPLAY_VALUE
								)values(
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#COLLECTION_OBJECT_ID#">,
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#NEW_OTHER_ID_TYPE#">,
									'',
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#NEW_OTHER_ID_NUMBER#">,
									'',
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#NEW_OTHER_ID_NUMBER#">
								)
						</cfquery>
						<cfquery name="updateOtherId1" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="updateOtherId1_result">
							select DISPLAY_VALUE 
							from coll_obj_other_id_num 
							where DISPLAY_VALUE = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.new_other_id_number#">
								having count(*) > 1
						</cfquery>
						<cfset otherid_updates = otherid_updates + updateOtherId_result.recordcount>
						<cfif updateOtherId1_result.recordcount gt 0>
							<cftransaction action = "ROLLBACK">
						<cfelse>
							<cftransaction action="COMMIT">
						</cfif>
					</cfloop>
					<p>Number of Other IDs to update: #otherid_updates# (on #getCounts.ctobj# cataloged items)</p>
					<cfif getTempData.recordcount eq otherid_updates and updateOtherId1_result.recordcount eq 0>
						<h2 class="text-success">Success - loaded</h2>
					</cfif>
					<cfif updateOtherId1_result.recordcount gt 0>
						<h2 class="text-danger">Not loaded - these have already been loaded</h2>
					</cfif>
				<cfcatch>
					<cftransaction action="ROLLBACK">
					<h2 class="h3">There was a problem updating the Other IDs.</h2>
				<!---	<div>#cfcatch.message#</div>--->
					<cfquery name="getProblemData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						SELECT institution_acronym, collection_cde, existing_other_id_type, existing_other_id_number, new_other_id_type, new_other_id_number
						FROM cf_temp_oids 
						WHERE status is not null
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
					</cfquery>
					<cfif getProblemData.recordcount GT 0>
 						<h2 class="h3">Errors are displayed one row at a time.</h2>
						<h3>
							Error loading row (<span class="text-danger">#otherid_updates + 1#</span>) from the CSV: 
							<cfif len(cfcatch.detail) gt 0>
								<span class="font-weight-normal border-bottom border-danger">
									<cfif cfcatch.detail contains "other_id_type">
										Invalid OTHER_ID_TYPE; check controlled vocabulary (Help menu)
									<cfelseif cfcatch.detail contains "collection_cde">
										COLLECTION_CDE does not match abbreviated collection (e.g., Ent, Herp, Ich, IP, IZ, Mala, Mamm, Orn, SC, VP)
									<cfelseif cfcatch.detail contains "institution_acronym">
										INSTITUTION_ACRONYM does not match MCZ (all caps)
									<cfelseif cfcatch.detail contains "OTHER_ID_NUMBER">
										Problem with OTHER_ID_NUMBER, check to see the correct other_id_type was entered
									<cfelseif cfcatch.detail contains "COLLECTION_OBJECT_ID">
										Problem with OTHER_ID_TYPE or OTHER_ID_NUMBER (#cfcatch.detail#)
									<cfelseif cfcatch.detail contains "no data">
										No data or the wrong data (#cfcatch.detail#)
									<cfelseif cfcatch.detail contains "NULL">
										Missing Data (#cfcatch.detail#)
									<cfelse>
										 provide the raw error message if it isn't readily interpretable 
										#cfcatch.detail#
									</cfif>
								</span>
							</cfif>
						</h3>
						<table class='sortable table table-responsive table-striped d-lg-table'>
							<thead>
								<tr>
									<th>status</th>
									<th>institution_acronym</th>
									<th>collection_cde</th>
									<th>existing_other_id_type</th>
									<th>existing_other_id_number</th>
									<th>new_other_id_type</th>
									<th>new_other_id_number</th>
								</tr>
							</thead>
							<tbody>
								<cfloop query="getProblemData">
									<tr>
										<td>#getProblemData.status#</td>
										<td>#getProblemData.institution_acronym#</td>
										<td>#getProblemData.collection_cde#</td>
										<td>#getProblemData.existing_other_id_type#</td>
										<td>#getProblemData.existing_other_id_number#</td>
										<td>#getProblemData.new_other_id_type#</td>
										<td>#getProblemData.new_other_id_number#</td>
									</tr> 
								</cfloop>
							</tbody>
						</table>
					</cfif>
				</cfcatch>
				</cftry>
			</cftransaction>
			
			<cfquery name="clearTempTable" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="clearTempTable_result">
				DELETE FROM cf_temp_oids 
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
		</cfoutput>
	</cfif>

</main>
<cfinclude template="/shared/_footer.cfm">