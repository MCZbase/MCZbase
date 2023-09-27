<cfif isDefined("action") AND action is "dumpProblems">
	<cfquery name="getProblemData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
SELECT INSTITUTION_ACRONYM,COLLECTION_CDE,OTHER_ID_TYPE,OTHER_ID_VAL,RELATIONSHIP,RELATED_INSTITUTION_ACRONYM,RELATED_COLLECTION_CDE,RELATED_OTHER_ID_TYPE,RELATED_OTHER_ID_VAL
		FROM cf_temp_bl_relations
		WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
	</cfquery>
	<cfinclude template="/shared/component/functions.cfc"><!---need to add to functions.cfc page--->
	<cfset csv = queryToCSV(getProblemData)>
	<cfheader name="Content-Type" value="text/csv">
	<cfoutput>#csv#</cfoutput>
	<cfabort>
</cfif>
<cfset fieldlist="INSTITUTION_ACRONYM,COLLECTION_CDE,OTHER_ID_TYPE,OTHER_ID_VAL,RELATIONSHIP,RELATED_INSTITUTION_ACRONYM,RELATED_COLLECTION_CDE,RELATED_OTHER_ID_TYPE,RELATED_OTHER_ID_VAL">
<cfset fieldTypes="CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR">
<cfset requiredfieldlist="INSTITUTION_ACRONYM,COLLECTION_CDE,OTHER_ID_TYPE,OTHER_ID_VAL,RELATIONSHIP,RELATED_INSTITUTION_ACRONYM,RELATED_COLLECTION_CDE,RELATED_OTHER_ID_TYPE,RELATED_OTHER_ID_VAL">

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
<cfset pageTitle = "Bulk Relations">
<cfinclude template="/shared/_header.cfm">
<cfif not isDefined("action") OR len(action) EQ 0>
	<cfset action="nothing">
</cfif>
	
<main class="container py-3" id="content">
	<h1 class="h2 mt-2">Bulkload Relationships</h1>
	<cfif #action# is "nothing">
		<cfoutput>
			<p>Use this form to add relationships between specimens. Specimen records must already exist. This form can be used to create relationships between specimens within the MCZ or between institutions using the catalog number or another identifier.</p>
			<p>Upload a comma-delimited text file (csv). Include column headings, spelled exactly as below. Additional colums will be ignored.</p>
			<span class="btn btn-xs btn-info" onclick="document.getElementById('template').style.display='block';">View template</span>
			<div id="template" style="display:none;margin: 1em 0;">
				<label for="templatearea" class="data-entry-label">
					Copy this header line and save it as a .csv file 
					(<a href="/tools/BulkloadRelations.cfm?action=getCSVHeader">download</a>)
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
			<cfform name="atts" method="post" enctype="multipart/form-data" action="/tools/BulkloadRelations.cfm">
				<input type="hidden" name="Action" value="getFile">
				<input type="file" name="FiletoUpload" size="45">
				<input type="submit" value="Upload this file" class="btn btn-primary btn-xs">
			</cfform>
		</cfoutput>
	</cfif>

	<cfif #action# is "getFile">
		<h2 class="h3">First step: Reading data from CSV file.</h2>
		<cfoutput>
			<cffile action="READ" file="#FiletoUpload#" variable="fileContent">
			<cfset fileContent=replace(fileContent,"'","''","all")>
			<cfset arrResult = CSVToArray(CSV = fileContent.Trim()) />
		
			<!--- cleanup any incomplete work by the same user --->
			<cfquery name="clearTempTable" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="clearTempTable_result">
				DELETE FROM MCZBASE.cf_temp_bl_relations 
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<!--- check for required fields in header line --->
			<cfset INSTITUTION_ACRONYM_exists = false>
			<cfset COLLECTION_CDE_exists = false>
			<cfset OTHER_ID_TYPE_exists = false>
			<cfset OTHER_ID_VAL_exists = false>
			<cfset RELATIONSHIP_exists = false>
			<cfset RELATED_INSTITUTION_ACRONYM_exists = false>
			<cfset RELATED_COLLECTION_CDE_exists = false>
			<cfset RELATED_OTHER_ID_TYPE_exists = false>
			<cfset RELATED_OTHER_ID_VAL_exists = false>
			<cfloop from="1" to ="#ArrayLen(arrResult[1])#" index="col">
				<cfset header = arrResult[1][col]>
				<cfif ucase(header) EQ 'INSTITUTION_ACRONYM'><cfset INSTITUTION_ACRONYM_exists=true></cfif>
				<cfif ucase(header) EQ 'COLLECTION_CDE'><cfset COLLECTION_CDE_exists=true></cfif>
				<cfif ucase(header) EQ 'OTHER_ID_TYPE'><cfset OTHER_ID_TYPE_exists=true></cfif>
				<cfif ucase(header) EQ 'OTHER_ID_VAL'><cfset OTHER_ID_VAL_exists=true></cfif>
				<cfif ucase(header) EQ 'RELATIONSHIP'><cfset RELATIONSHIP_exists=true></cfif>
				<cfif ucase(header) EQ 'RELATED_INSTITUTION_ACRONYM'><cfset RELATED_INSTITUTION_ACRONYM_exists=true></cfif>
				<cfif ucase(header) EQ 'RELATED_COLLECTION_CDE'><cfset RELATED_COLLECTION_CDE_exists=true></cfif>
				<cfif ucase(header) EQ 'RELATED_OTHER_ID_TYPE'><cfset RELATED_OTHER_ID_TYPE_exists=true></cfif>
				<cfif ucase(header) EQ 'RELATED_OTHER_ID_VAL'><cfset RELATED_OTHER_ID_VAL_exists=true></cfif>
			</cfloop>
			<cfif not (INSTITUTION_ACRONYM_exists AND COLLECTION_CDE_exists AND OTHER_ID_TYPE_exists AND OTHER_ID_VAL_exists AND RELATIONSHIP_exists AND RELATED_INSTITUTION_ACRONYM_exists AND RELATED_COLLECTION_CDE_exists AND RELATED_OTHER_ID_TYPE_exists AND RELATED_OTHER_ID_VAL_exists)>
				<cfset message = "One or more required fields are missing in the header line of the csv file.">
				<cfif not INSTITUTION_ACRONYM_exists><cfset message = "#message# INSTITUTION_ACRONYM is missing."></cfif>
				<cfif not COLLECTION_CDE_exists><cfset message = "#message# COLLECTION_CDE is missing."></cfif>
				<cfif not OTHER_ID_TYPE_exists><cfset message = "#message# OTHER_ID_TYPE is missing."></cfif>
				<cfif not OTHER_ID_VAL_exists><cfset message = "#message# OTHER_ID_VAL is missing."></cfif>
				<cfif not RELATIONSHIP_exists><cfset message = "#message# RELATIONSHIP is missing."></cfif>
				<cfif not RELATED_INSTITUTION_ACRONYM_exists><cfset message = "#message# RELATED_INSTITUTION_ACRONYM is missing."></cfif>
				<cfif not RELATED_COLLECTION_CDE_exists><cfset message = "#message# RELATED_COLLECTION_CDE is missing."></cfif>
				<cfif not RELATED_OTHER_ID_TYPE_exists><cfset message = "#message# RELATED_OTHER_ID_TYPE is missing."></cfif>
				<cfif not RELATED_OTHER_ID_VAL_exists><cfset message = "#message# RELATED_OTHER_ID_VAL is missing."></cfif>
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
							insert into MCZBASE.CF_TEMP_BL_RELATIONS
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
				Successfully loaded #loadedRows# records from the CSV file.  Next <a href="/tools/BulkloadRelations.cfm?action=validate">click to validate</a>.
			</h3>
		</cfoutput>
	</cfif>

	<cfif #action# is "validate">
		<h2 class="h3">Second step: Data Validation</h2>
		<cfoutput>
			<cfset other_id_type = ''>
			<cfset related_other_id_type = ''>
			<cfif other_id_type eq 'catalog number' OR related_other_id_type eq 'catalog number'>
				<cfquery name="getCID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					update cf_temp_bl_relations set collection_object_id = 
				(
					select ci.collection_object_id 
					from cataloged_item ci
					where (ci.collection_cde = #cf_temp_bl_relations.collection_cde# || co.collecton_cde = #cf_temp_bl_relations.related_collection_cde#)
					and (ci.cat_num = #cf_temp_bl_relations.other_id_value# || ci.cat_num = #cf_temp_bl_relations.related_other_id_val#)
				) 
				where username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
			<cfelse>
				<cfquery name="getCID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					update cf_temp_bl_relations set collection_object_id = 
				(
					select coll_obj_other_id_num co
					from cataloged_item ci
					where ci.collection_cde = #cf_temp_bl_relations.related_collection_cde#
					and ci.cat_num = #cf_temp_bl_relations.related_other_id_val#
				) 
				where username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
			</cfif>

			<cfquery name="getCID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				update cf_temp_bl_relations set related_collection_object_id=
				(
					select ci.collection_object_id
					from cataloged_item ci
					where ci.collection_cde = #cf_temp_bl_relations.related_collection_cde#
					and ci.cat_num = #cf_temp_bl_relations.related_other_id_val#
				)
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="miac" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE cf_temp_bl_relations
				SET status = 'collecton_cde not found'
				WHERE collection_cde is null
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="miap" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE cf_temp_bl_relations
				SET status = 'related_other_id not found'
				WHERE related_other_id_val is null
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="miac" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE cf_temp_bl_relations
				SET status = 'related_collecton_cde not found'
				WHERE related_collection_cde is null
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="miap" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE cf_temp_bl_relations
				SET status = 'other_id not found'
				WHERE other_id_val is null
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="miap" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE cf_temp_bl_relations
				SET status = 'bad relationship'
				WHERE relationship not in (select biol_indiv_relationship,inverse_relation from ctbiol_relations)
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT INSTITUTION_ACRONYM,COLLECTION_CDE,OTHER_ID_TYPE,OTHER_ID_VAL,RELATIONSHIP,RELATED_INSTITUTION_ACRONYM,RELATED_COLLECTION_CDE,RELATED_OTHER_ID_TYPE,RELATED_OTHER_ID_VAL
				FROM cf_temp_bl_relations 
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="pf" dbtype="query">
				SELECT count(*) c 
				FROM data 
				WHERE status is not null
			</cfquery>
			<cfif pf.c gt 0>
				<h2>
					There is a problem with #pf.c# of #data.recordcount# row(s). See the STATUS column. (<a href="/tools/BulkloadPartContainer.cfm?action=dumpProblems">download</a>).
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
						<th>PRESERVE_METHOD</th>
						<th>CONTAINER_UNIQUE_ID</th>
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
							<td>#data.PRESERVE_METHOD#</td>
							<td>#data.CONTAINER_UNIQUE_ID#</td>
							<td><strong>#STATUS#</strong></td>
						</tr>
					</cfloop>
				</tbody>
			</table>
		</cfoutput>
	</cfif>

</main>
<!------------------------------------------------------->

<!---<cfif #action# is "getFile">
	<cfoutput>
		<cfquery name="killOld" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			delete from cf_temp_bl_relations
		</cfquery>
		<cffile action="READ" file="#FiletoUpload#" variable="fileContent">
		<cfset fileContent=replace(fileContent,"'","''","all")>
		<cfset arrResult = CSVToArray(CSV = fileContent.Trim()) />
		<cfset numberOfColumns = ArrayLen(arrResult[1])>
		<cfset colNames="">
		<cfloop from="1" to ="#ArrayLen(arrResult)#" index="o">
			<cfset colVals="">
				<cfloop from="1"  to ="#ArrayLen(arrResult[o])#" index="i">
					 <cfset numColsRec = ArrayLen(arrResult[o])>
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
				<cfif numColsRec lt numberOfColumns>
					<cfset missingNumber = numberOfColumns - numColsRec>
					<cfloop from="1" to="#missingNumber#" index="c">
						<cfset colVals = "#colVals#,''">
					</cfloop>
				</cfif>
				<cfquery name="ins" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					insert into cf_temp_bl_relations (#colNames#) values (#preservesinglequotes(colVals)#)
				</cfquery>
			</cfif>
		</cfloop>
	</cfoutput>
	<cflocation url="BulkloadRelations.cfm?action=validate">
</cfif>--->

<!---<cfif #action# is "validate">
<cfoutput>
	<cfquery name="setStatus" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		update 
			cf_temp_bl_relations 
		set 
			validated_status='bad_relationship'
		where 
			validated_status is null AND (
				relationship not in (select BIOL_INDIV_RELATIONSHIP from CTBIOL_RELATIONS)
			)
	</cfquery>
	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select * from cf_temp_bl_relations
	</cfquery>
	<cfloop query="d">
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
					cat_num='#other_id_val#'
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
					other_id_num = '#other_id_val#'
			</cfquery>				
		</cfif>
		<cfif #collObj.recordcount# is 1>					
			<cfquery name="insColl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE cf_temp_bl_relations SET collection_object_id = #collObj.collection_object_id#
				where
				key = #key#
			</cfquery>
		<cfelse>				
			<cfquery name="insColl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE cf_temp_bl_relations SET validated_status = 
				validated_status || 'identifier matched #collObj.recordcount# records' 
				where key = #key#
			</cfquery>
		</cfif>
		<cfif #related_other_id_type# is "catalog number">
			<cfquery name="rcollObj" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT 
					collection_object_id
				FROM
					cataloged_item,
					collection
				WHERE
					cataloged_item.collection_id = collection.collection_id and
					collection.collection_cde = '#related_collection_cde#' and
					collection.institution_acronym = '#related_institution_acronym#' and
					cat_num='#related_other_id_val#'
			</cfquery>
		<cfelse>
			<cfquery name="rcollObj" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT 
					coll_obj_other_id_num.collection_object_id
				FROM
					coll_obj_other_id_num,
					cataloged_item,
					collection
				WHERE
					coll_obj_other_id_num.collection_object_id = cataloged_item.collection_object_id and
					cataloged_item.collection_id = collection.collection_id and
					collection.collection_cde = '#related_collection_cde#' and
					collection.institution_acronym = '#related_institution_acronym#' and
					other_id_type = '#related_other_id_type#' and
					other_id_num = '#related_other_id_val#'
			</cfquery>				
		</cfif>
		<cfif #rcollObj.recordcount# is 1>					
			<cfquery name="insColl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE cf_temp_bl_relations SET related_collection_object_id = #rcollObj.collection_object_id#
				where
				key = #key#
			</cfquery>
		<cfelse>				
			<cfquery name="insColl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE cf_temp_bl_relations SET validated_status = 
				validated_status || 'related identifier matched #rcollObj.recordcount# records.' 
				where key = #key#
			</cfquery>
		</cfif>
	</cfloop>
	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select * from cf_temp_bl_relations
	</cfquery>	
	<cfquery name="b" dbtype="query">
		select count(*) c from d where validated_status is not null
	</cfquery>
	<cfif b.c gt 0>
		You must clean up the #b.recordcount# rows with validated_status != NULL in this table before proceeding.
	<cfelse>
		Check out the table below and <a href="BulkloadRelations.cfm?action=loadData">click here to proceed</a> when all looks OK
	</cfif>
	<cfdump var=#d#>
</cfoutput>
</cfif>
<cfif #action# is "loadData">
<cfoutput>
	<cfquery name="getTempData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select * from cf_temp_bl_relations
	</cfquery>
	<cftransaction>
	<cfloop query="getTempData">
		<cfquery name="newAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			insert into biol_indiv_relations (
				collection_object_id,
				related_coll_object_id,
				biol_indiv_relationship
			) values (
				#collection_object_id#,
				#related_collection_object_id#,
				'#relationship#'
			)
		</cfquery>
	</cfloop>
	</cftransaction>
	Spiffy, all done.
</cfoutput>--->
<!---</cfif>--->
<cfinclude template="/shared/_footer.cfm">