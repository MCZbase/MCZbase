<cfif isDefined("action") AND action is "dumpProblems">
	<cfquery name="getProblemData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		SELECT institution_acronym,collection_cde,other_id_type,other_id_number,part_name,preserve_method,lot_count_modifier,lot_count,condition,disposition
		FROM cf_temp_parts
		WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
	</cfquery>
	<cfinclude template="/shared/component/functions.cfc"><!---need to add to functions.cfc page--->
	<cfset csv = queryToCSV(getProblemData)>
	<cfheader name="Content-Type" value="text/csv">
	<cfoutput>#csv#</cfoutput>
	<cfabort>
</cfif>
<cfset fieldlist = "institution_acronym,collection_cde,other_id_type,other_id_number,part_name,preserve_method,lot_count_modifier,lot_count,condition,disposition">
<cfset fieldTypes ="CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR">
<cfset requiredfieldlist = "institution_acronym,collection_cde,other_id_type,other_id_number,part_name,preserve_method,lot_count,condition,disposition">
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
<!---			<cfform name="atts" method="post" enctype="multipart/form-data" action="/tools/BulkloadNewParts.cfm">
				<input type="hidden" name="Action" value="getFile">
				<input type="file" name="FiletoUpload" size="45">
				<input type="submit" value="Upload this file" class="btn btn-primary btn-xs">
			</cfform>--->
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
			<cfset LOT_COUNT_MODIFIER_exists = false>
			<cfset LOT_COUNT_exists = false>
			<cfset CONDITION_exists = false>
			<cfset DISPOSITION_exists = false>
	
			<cfloop from="1" to ="#ArrayLen(arrResult[1])#" index="col">
				<cfset header = arrResult[1][col]>
				<cfif ucase(header) EQ 'INSTITUTION_ACRONYM'><cfset INSTITUTION_ACRONYM_exists=true></cfif>
				<cfif ucase(header) EQ 'COLLECTION_CDE'><cfset COLLECTION_CDE_exists=true></cfif>
				<cfif ucase(header) EQ 'OTHER_ID_TYPE'><cfset OTHER_ID_TYPE_exists=true></cfif>
				<cfif ucase(header) EQ 'OTHER_ID_NUMBER'><cfset OTHER_ID_NUMBER_exists=true></cfif>
				<cfif ucase(header) EQ 'PART_NAME'><cfset PART_NAME_exists=true></cfif>
				<cfif ucase(header) EQ 'PRESERVE_METHOD'><cfset PRESERVE_METHOD_exists=true></cfif>
				<cfif ucase(header) EQ 'LOT_COUNT_MODIFIER'><cfset LOT_COUNT_MODIFIER_exists=true></cfif>
				<cfif ucase(header) EQ 'LOT_COUNT'><cfset LOT_COUNT_exists=true></cfif>
				<cfif ucase(header) EQ 'CONDITION'><cfset CONDITION_exists=true></cfif>
				<cfif ucase(header) EQ 'DISPOSITION'><cfset DISPOSITION_exists=true></cfif>
			</cfloop>
			<cfif not (INSTITUTION_ACRONYM_exists AND COLLECTION_CDE_exists AND OTHER_ID_TYPE_exists AND OTHER_ID_NUMBER_exists AND PART_NAME_exists AND PRESERVE_METHOD_exists AND LOT_COUNT_exists AND CONDITION_exists AND DISPOSITION_exists)>
				<cfset message = "One or more required fields are missing in the header line of the csv file.">
				<cfif not INSTITUTION_ACRONYM_exists><cfset message = "#message# INSTITUTION_ACRONYM is missing."></cfif>
				<cfif not COLLECTION_CDE_exists><cfset message = "#message# COLLECTION_CDE is missing."></cfif>
				<cfif not OTHER_ID_TYPE_exists><cfset message = "#message# OTHER_ID_TYPE is missing."></cfif>
				<cfif not OTHER_ID_NUMBER_exists><cfset message = "#message# OTHER_ID_NUMBER is missing."></cfif>
				<cfif not PART_NAME_exists><cfset message = "#message# PART_NAME is missing."></cfif>
				<cfif not PRESERVE_METHOD_exists><cfset message = "#message# PRESERVE_METHOD is missing."></cfif>
				<cfif not LOT_COUNT_MODIFIER_exists><cfset message = "#message# LOT_COUNT_MODIFIER is missing."></cfif>
				<cfif not LOT_COUNT_exists><cfset message = "#message# LOT_COUNT is missing."></cfif>
				<cfif not CONDITION_exists><cfset message = "#message# CONDITION is missing."></cfif>
				<cfif not DISPOSITION_exists><cfset message = "#message# DISPOSITION is missing."></cfif>
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
			<cfquery name="getAtt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select collection_object_id
				from cf_temp_parts
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfloop query="getAtt">
				<cfif getAtt.other_id_type eq 'catalog number'>
					<cfquery name="getCID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						UPDATE
							cf_temp_parts
						SET
							collection_object_id= (select collection_object_id from cataloged_item where cat_num = cf_temp_parts.other_id_number and collection_cde = cf_temp_parts.collection_cde) 
						WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
					</cfquery>
				<cfelse>
					<cfquery name="getCID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						UPDATE
							cf_temp_parts
						SET
							collection_object_id= (
								select cataloged_item.collection_object_id from cataloged_item,coll_obj_other_id_num 
								where coll_obj_other_id_num.other_id_type = cf_temp_parts.other_id_type 
								and cataloged_item.collection_cde = cf_temp_parts.collection_cde 
								and display_value= cf_temp_parts.other_id_number
								and cataloged_item.collection_object_id = coll_obj_other_id_num.COLLECTION_OBJECT_ID
							)
						WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
					</cfquery>
				</cfif>
			</cfloop>
			
<!---		<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select * from cf_temp_parts where 
			username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
		</cfquery>
		<cfloop query="data">
			<cfif #other_id_type# is "catalog number"><!---Checks to see if the catalog record exists--->
				<cfquery name="collObj" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					update cf_temp_parts set collection_object_id = 
					(select cataloged_item.collection_object_id
					FROM
						cataloged_item, collection
					WHERE
						cataloged_item.collection_id = collection.collection_id and
						collection.collection_cde = '#data.collection_cde#' and
						collection.institution_acronym = '#institution_acronym#' and
						cat_num='#data.other_id_number#')
				</cfquery>
			<cfelse>
				<cfquery name="collObj" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					update cf_temp_parts set collection_object_id = 
					(SELECT
						coll_obj_other_id_num.collection_object_id
					FROM
						coll_obj_other_id_num,
						cataloged_item,
						collection
					WHERE
						coll_obj_other_id_num.collection_object_id = cataloged_item.collection_object_id and
						cataloged_item.collection_id = collection.collection_id and
						collection.collection_cde = #data.collection_cde# and
						collection.institution_acronym = '#data.institution_acronym#' and
						other_id_type = '#other_id_type#' and
						display_value = '#data.other_id_number#'
					)
				</cfquery>
			</cfif>
		</cfloop>--->

			<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT INSTITUTION_ACRONYM,OTHER_ID_TYPE,OTHER_ID_NUMBER,COLLECTION_CDE,PART_NAME,PRESERVE_METHOD,LOT_COUNT_MODIFIER,LOT_COUNT,CONDITION,DISPOSITION,CONTAINER_UNIQUE_ID,VALIDATED_STATUS 
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
					There is a problem with #pf.c# of #data.recordcount# row(s). See the STATUS column. (<a href="/tools/BulkloadNewParts.cfm?action=dumpProblems">download</a>).
				</h2>
				<h3>
					Fix the problems in the data and <a href="/tools/BulkloadNewParts.cfm">start again</a>.
				</h3>
			<cfelse>
				<h2>
					Validation checks passed. Look over the table below and <a href="/tools/BulkloadNewParts.cfm?action=load">click to continue</a> if it all looks good.
				</h2>
			</cfif>
				
				
		<!---ERROR MESSAGES--->
		<!---INSTITUTION_ACRONYM--->			
			<cfquery name="m1a" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE cf_temp_parts
				SET status = 'INSTITUTION_ACRONYM is missing [1a]'
				WHERE institution_acronym is null
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="m1b" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE cf_temp_parts
				SET status = 'Institution Acronym is not: "MCZ" (check case) [1b]'
				WHERE institution_acronym <> 'MCZ'
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<!---COLLECTION_CDE--->	
			<cfquery name="m2a" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE
					cf_temp_parts
				SET status = 'collection_cde not valid [2a]'
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				and collection_cde not in (select collection_cde from collection)
			</cfquery>
			<cfquery name="m2b" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE
					cf_temp_parts
				SET status = 'collection_cde is missing [2b]'
				WHERE COLLECTION_CDE is null
				AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<!---OTHER_ID_TYPE--->
			<cfquery name="m3" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE cf_temp_parts
				SET status = 'OTHER_ID_TYPE is missing [3]'
				WHERE OTHER_ID_TYPE is null
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<!---OTHER_ID_NUMBER--->
			<cfquery name="m4" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE cf_temp_parts
				SET status = 'OTHER_ID_NUMBER is missing [4]'
				WHERE OTHER_ID_NUMBER is null
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<!---ATTRIBUTE--->
			<cfquery name="m5a" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE cf_temp_parts
				SET status = 'this part_name is not valid for this collection; not in ctspecimen_part_name [5a]'
				where part_name not in (select part_name from ctspecimen_part_name, cf_temp_parts where cf_temp_parts.collection_cde = ctspecimen.collection_cde)
				and part_name is not null
				and username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="m5b" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE cf_temp_parts
				SET status = 'part name is missing [6a]'
				WHERE part_name is null
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<!---ATTRIBUTE_VALUE--->
			<cfquery name="m6a" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE cf_temp_parts
				SET status = 'preserve method is missing [6a]'
				WHERE preserve_method is null
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="m6b" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE cf_temp_parts 
				SET status = 'invalid preserve method; not in ctspecimen_preserv_method [6b]'
				where preserve_method not in (select preserve_method from ctspecimen_preserv_method where collection_cde = cf_temp_parts.collection_cde)
				and preserve_method is not null
				and username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<!---ATTRIBUTE_UNITS--->
			<cfquery name="m7a" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE cf_temp_parts
				SET status = 'this attribute uses controlled_vocabulary [7a]'
				where attribute in (select attribute_type from ctattribute_code_tables where units_code_table is not null)
				and attribute_units is null
				and username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfif getType.attribute contains 'length'>
			<cfquery name="m7b" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE cf_temp_parts 
				SET status = 'invalid attribute_units; not in ctlength_units [7b]'
				where attribute_units not in (select length_units from ctlength_units)
				and username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			</cfif>
			<cfif getType.attribute is 'weight'>
				<cfquery name="m7c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					UPDATE cf_temp_parts 
					SET status = 'invalid attribute_units; not in ctweight_units [7b]'
					where attribute_units not in (select weight_units from ctweight_units)
					and username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
			</cfif>
			<!---ATTRIBUTE_DATE--->
			<cfquery name="m8a" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE cf_temp_parts
				SET status = 'attribute date missing [8a]'
				WHERE attribute_date is null
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			
			<!---DETERMINER--->
			<cfquery name="m9a" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE
					cf_temp_parts
				SET
					determined_by_agent_id= (select agent_id from preferred_agent_name where agent_name = cf_temp_attributes.determiner)
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="m9b" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE cf_temp_parts
				SET status = 'agent value (preferred name) is missing in DETERMINER column [9b]'
				WHERE determiner is null
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT institution_acronym,collection_cde,other_id_type,other_id_number,attribute,attribute_value,attribute_units,attribute_date, attribute_meth,determiner,remarks,status
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
				
				
				
				
			<table class='sortable table table-responsive table-striped d-lg-table'>
				<thead>
					<tr>
						<th>INSTITUTION_ACRONYM</th>
						<th>OTHER_ID_TYPE</th>
						<th>OTHER_ID_NUMBER</th>
						<th>COLLECTION_CDE</th>
						<th>PART_NAME</th>
						<th>PRESERVE_METHOD</th>
						<th>LOT_COUNT_MODIFIER</th>
						<th>LOT_COUNT</th>
						<th>CONDITION</th>
						<th>DISPOSITION</th>
						<th>Container_UNIQUE_ID</th>
						<th>VALIDATED_STATUS</th>
					</tr>
				<tbody>
					<cfloop query="data">
						<tr>
							<td>#data.INSTITUTION_ACRONYM#</td>
							<td>#data.OTHER_ID_TYPE#</td>
							<td>#data.OTHER_ID_NUMBER#</td>
							<td>#data.COLLECTION_CDE#</td>
							<td>#data.PART_NAME#</td>
							<td>#data.PRESERVE_METHOD#</td>
							<td>#data.lot_count_modifier#</td>
							<td>#data.lot_count#</td>
							<td>#data.condition#</td>
							<td>#data.disposition#</td>
							<td>#data.container_unique_ID#</td>
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
			<cfquery name="NEXTID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select sq_collection_object_id.nextval NEXTID from coll_object
			</cfquery>
			<cftry>
				<cfset part_updates = 0>
					<cftransaction>
						<cfloop query="getTempData">
							<cfquery name="updateParts" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
								insert into specimen_part sp
								INNER JOIN coll_object co ON co.collection_object_id = sp.derived_from_cat_item
								(collection_object_id, sp.part_name, sp.preserve_method, sp.derived_from_cat_item,co.condition,co.lot_count_modifier,co.lot_count ) 
								values
								(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#collection_object_id#">, '<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#PART_NAME#">', '<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#PRESERVE_METHOD#">', '<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#DERIVED_FROM_CAT_ITEM#">','<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#CONDITION#">','<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#lot_count_modifier#">',<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#lot_count#">)
							</cfquery>
							<cfset part_updates = part_updates + updateParts_result.recordcount>
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
								<th>INSTITUTION_ACRONYM</th>
								<th>COLLECTION_CDE</th>
								<th>OTHER_ID_TYPE</th>
								<th>OTHER_ID_NUMBER</th>
								<th>PART_NAME</th>
								<th>PRESERVE_METHOD</th>
								<th>LOT_COUNT</th>
								<th>LOT_COUNT_MODIFIER</th>
								<th>CONDITION</th>
								<th>CONTAINER_UNIQUE_ID</th>
								<th>VALIDTED_STATUS</th>
							</tr> 
						</thead>
						<tbody>
							<cfloop query="getProblemData">
								<tr>
									<td>#getProblemData.INSTITUTION_ACRONYM#</td>
									<td>#getProblemData.COLLECTION_CDE#</td>
									<td>#getProblemData.OTHER_ID_TYPE#</td>
									<td>#getProblemData.OTHER_ID_NUMBER#</td>
									<td>#getProblemData.PART_NAME#</td>
									<td>#getProblemData.PRESERVE_METHOD#</td>
									<td>#getProblemData.LOT_COUNT#</td>
									<td>#getProblemData.LOT_COUNT_MODIFIER#</td>
									<td>#getProblemData.CONDITION#</td>
									<td>#getProblemData.CONTAINER_UNIQUE_ID#</td>
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
						
						<cfset part_container_updates = part_container_updates + updatePartContainer_result.recordcount>
					</cfloop>
					<cftransaction action="commit">
				<cfcatch>
					<cftransaction action="rollback">
						<cfquery name="getProblemData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						SELECT institution_acronym,other_id_type,other_id_number,collection_cde,part_name,preserve_method,lot_count,lot_count_modifier,condition,validated_status 
						FROM cf_temp_parts 
						WHERE validated_status is not null
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						</cfquery>
						<h3>Error updating row (#part_updates + 1#): #cfcatch.message#</h3>
						<table class='sortable table table-responsive table-striped d-lg-table'>
							<thead>
								<tr>
									<th>institution_acronym</th>
									<th>other_id_type</th>
									<th>other_id_number</th>
									<th>collection_cde</th>
									<th>part_name</th>
									<th>lot_count_modifier</th>
									<th>preserve_method</th>
									<th>lot_count</th>
									<th>condition</th>
									<th>disposition</th>
									<th>Container_unique_id</th>
									<th>validated_status</th>
								</tr> 
							</thead>
							<tbody>
								<cfloop query="getProblemData">
									<tr>
										<td>#getProblemData.INSTITUTION_ACRONYM#</td>
										<td>#getProblemData.OTHER_ID_TYPE#</td>
										<td>#getProblemData.OTHER_ID_NUMBER#</td>
										<td>#getProblemData.COLLECTION_CDE#</td>
										<td>#getProblemData.PART_NAME#</td>
										<td>#getProblemData.PRESERVE_METHOD#</td>
										<td>#getProblemData.LOT_COUNT_MODIFIER#</td>
										<td>#getProblemData.LOT_COUNT#</td>
										<td>#getProblemData.CONDITION#</td>
										<td>#getProblemData.DISPOSITION#</td>
										<td>#getProblemData.CONTAINER_UNIQUE_ID#</td>
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
	
		
		
	