<!--- special case handling to dump problem data as csv --->
<cfif isDefined("action") AND action is "dumpProblems">
	<cfquery name="getProblemData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		SELECT institution_acronym,collection_cde,other_id_type,other_id_number,scientific_name,made_date,nature_of_id,accepted_fg,identification_remarks,taxa_formula,agent_1,agent_2,stored_as_fg
		FROM cf_temp_ID
		WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
	</cfquery>
	<cfinclude template="/shared/component/functions.cfc">
	<cfset csv = queryToCSV(getProblemData)>
	<cfheader name="Content-Type" value="text/csv">
	<cfoutput>#csv#</cfoutput>
	<cfabort>
</cfif>
		
<!--- end special case dump of problems --->
<cfset fieldlist = "institution_acronym,collection_cde,other_id_type,other_id_number,scientific_name,made_date,nature_of_id,accepted_fg,identification_remarks,taxa_formula,agent_1,agent_2,stored_as_fg">
<cfset fieldTypes ="CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR">
<cfset requiredfieldlist = "institution_acronym,collection_cde,other_id_type,other_id_number,scientific_name,nature_of_id,accepted_fg,agent_1">
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
<cfset pageTitle = "Bulkload Identification">
<cfinclude template="/shared/_header.cfm">
<cfif not isDefined("action") OR len(action) EQ 0><cfset action="nothing"></cfif>
<main class="container py-3" id="content">
	<h1 class="h2 mt-2">Bulkload Identification</h1>
	<cfif #action# is "nothing">
	<cfoutput>
			<p>This tool is used to bulkload identifications.</p>
			<p>Upload a comma-delimited text file (csv).  Include column headings, spelled exactly as below.  Additional colums will be ignored</p>
			<span class="btn btn-xs btn-info" onclick="document.getElementById('template').style.display='block';">View template</span>
			<div id="template" style="display:none;margin: 1em 0;">
				<label for="templatearea" class="data-entry-label">
					Copy this header line and save it as a .csv file (<a href="/tools/BulkloadIdentification.cfm?action=getCSVHeader">download</a>)
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
			<cfform name="atts" method="post" enctype="multipart/form-data" action="/tools/BulkloadIdentification.cfm">
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
				DELETE FROM cf_temp_ID 
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<!--- check for required fields in header line --->
			<cfset institution_acronym_exists = false>
			<cfset collection_cde_exists = false>
			<cfset other_id_type_exists = false>
			<cfset other_id_number_exists = false>
			<cfset scientific_name_exists = false>
			<cfset nature_of_id_exists = false>
			<cfset accepted_fg_exists = false>
			<cfset taxa_formula_exists = false>
			<cfset agent_1_exists = false>
			<cfset stored_as_fg = false>
			<cfloop from="1" to ="#ArrayLen(arrResult[1])#" index="col">
				<cfset header = arrResult[1][col]>
				<cfif ucase(header) EQ 'institution_acronym'><cfset institution_acronym_exists=true></cfif>
				<cfif ucase(header) EQ 'collection_cde'><cfset collection_cde_exists=true></cfif>
				<cfif ucase(header) EQ 'other_id_type'><cfset other_id_type_exists=true></cfif>
				<cfif ucase(header) EQ 'other_id_number'><cfset other_id_number_exists=true></cfif>
				<cfif ucase(header) EQ 'scientific_name'><cfset scientific_name_exists=true></cfif>
				<cfif ucase(header) EQ 'nature_of_id'><cfset nature_of_id_exists=true></cfif>
				<cfif ucase(header) EQ 'accepted_fg'><cfset accepted_fg_exists=true></cfif>
				<cfif ucase(header) EQ 'taxa_formula'><cfset taxa_formula_exists=true></cfif>
				<cfif ucase(header) EQ 'agent_1'><cfset agent_1_exists=true></cfif>
				<cfif ucase(header) EQ 'stored_as_fg'><cfset stored_as_fg_exists=true></cfif>
			</cfloop>
			<cfif not (institution_acronym_exists AND collection_cde_exists AND other_id_type_exists AND other_id_number_exists AND scientific_name_exists AND nature_of_id_exists AND accepted_fg_exists AND agent_1_exists)>
				<cfset message = "One or more required fields are missing in the header line of the csv file.">
				<cfif not institution_acronym_exists><cfset message = "#message# institution_acronym is missing."></cfif>
				<cfif not collection_cde_exists><cfset message = "#message# collection_cde is missing."></cfif>
				<cfif not other_id_type_exists><cfset message = "#message# other_id_type is missing."></cfif>
				<cfif not other_id_number_exists><cfset message = "#message# other_id_number is missing."></cfif>
				<cfif not scientific_name_exists><cfset message = "#message# scientific_name is missing."></cfif>
				<cfif not nature_of_id_exists><cfset message = "#message# nature_of_id is missing."></cfif>
				<cfif not accepted_fg_exists><cfset message = "#message# accepted_fg is missing."></cfif>
				<cfif not agent_1_exists><cfset message = "#message# agent_1 is missing."></cfif>
				<cfif not stored_as_fg_exists><cfset message = "#message# stored_as_fg is missing."></cfif>
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
							insert into cf_temp_ID (#fieldlist#,username) values (
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
				Successfully loaded #loadedRows# records from the CSV file.  Next <a href="/tools/BulkloadIdentification.cfm?action=validate">click to validate</a>.
			</h3>
		</cfoutput>
	</cfif>
	<!------------------------------------------------------->
	<cfif #action# is "validate">
		<h2 class="h3">Second step: Data Validation</h2>
		<cfquery name="data1" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			SELECT * FROM cf_temp_id WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">	
		</cfquery>
		<cfoutput>
			<cfset TaxonomyTaxonName = ''>
			<cfset scientific_name = '#data1.scientific_name#'>
			<cfset tf = '#data1.taxa_formula#'>
			<cfloop query='data1'>
				<cfif right(scientific_name,4) is " sp.">
					<cfset scientific_name=left(scientific_name,len(scientific_name) -4)>
					<cfset tf = "A sp.">
					<cfset TaxonomyTaxonName=left(scientific_name,len(scientific_name) - 4)>
				<cfelseif right(scientific_name,5) is " ssp.">
					<cfset scientific_name=left(scientific_name,len(scientific_name) -5)>
					<cfset tf = "A ssp.">
					<cfset TaxonomyTaxonName=left(scientific_name,len(scientific_name) - 5)>
				<cfelseif right(scientific_name,5) is " spp.">
					<cfset scientific_name=left(scientific_name,len(scientific_name) -5)>
					<cfset tf = "A spp.">
					<cfset TaxonomyTaxonName=left(scientific_name,len(scientific_name) - 5)>
				<cfelseif right(scientific_name,5) is " var.">
					<cfset scientific_name=left(scientific_name,len(scientific_name) -5)>
					<cfset tf = "A var.">
					<cfset TaxonomyTaxonName=left(scientific_name,len(scientific_name) - 5)>
				<cfelseif right(scientific_name,9) is " sp. nov.">
					<cfset scientific_name=left(scientific_name,len(scientific_name) -9)>
					<cfset tf = "A sp. nov.">
					<cfset TaxonomyTaxonName=left(scientific_name,len(scientific_name) - 9)>
				<cfelseif right(scientific_name,10) is " gen. nov.">
					<cfset scientific_name=left(scientific_name,len(scientific_name) -10)>
					<cfset tf = "A gen. nov.">
					<cfset TaxonomyTaxonName=left(scientific_name,len(scientific_name) - 10)>
				<cfelseif right(scientific_name,8) is " (Group)">
					<cfset scientific_name=left(scientific_name,len(scientific_name) -8)>
					<cfset tf = "A (Group)">
					<cfset TaxonomyTaxonName=left(scientific_name,len(scientific_name) - 8)>
				<cfelseif right(scientific_name,4) is " nr.">
					<cfset scientific_name=left(scientific_name,len(scientific_name) -5)>
					<cfset tf = "A nr.">
					<cfset TaxonomyTaxonName=left(scientific_name,len(scientific_name) - 5)>
				<cfelseif right(scientific_name,4) is " cf.">
					<cfset scientific_name=left(scientific_name,len(scientific_name) -4)>
					<cfset tf = "A cf.">
					<cfset TaxonomyTaxonName=left(scientific_name,len(scientific_name) - 4)>
				<cfelseif right(scientific_name,2) is " ?">
					<cfset scientific_name=left(scientific_name,len(scientific_name) -2)>
					<cfset tf = "A ?">
					<cfset TaxonomyTaxonName=left(scientific_name,len(scientific_name) - 2)>
				<cfelse>
					<cfset  tf = "A">
					<cfset TaxonomyTaxonName="#scientific_name#">
				</cfif>
			</cfloop>
			<cfquery name="isTaxa" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				update cf_temp_id set taxon_name_id =
				(SELECT taxon_name_id FROM taxonomy WHERE scientific_name = cf_temp_id.scientific_name)
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
<!---			<cfquery name="ctnature" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select nature_of_id from ctnature_of_id
			</cfquery>
			<cfquery name="ctFormula" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select taxa_formula from cttaxa_formula order by taxa_formula
			</cfquery>--->
			<cfquery name="isSci" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE cf_temp_ID SET scientific_name= '#TaxonomyTaxonName#'
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="getCID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE cf_temp_ID SET collection_object_id= 
				(select collection_object_id from cataloged_item where cat_num = cf_temp_ID.other_id_number and collection_cde = cf_temp_ID.collection_cde)
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="miac" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE cf_temp_ID SET status = 'scientific_name not found'
				WHERE scientific_name is null AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="miap" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE cf_temp_ID SET status = 'collection_object_id not found'
				WHERE collection_object_id is null AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT institution_acronym,collection_cde,other_id_type,other_id_number,scientific_name,made_date,nature_of_id,accepted_fg,
				identification_remarks,taxa_formula,agent_1,agent_2,stored_as_fg,status
				FROM cf_temp_ID
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="pf" dbtype="query">
				SELECT count(*) c 
				FROM data 
				WHERE status is not null
			</cfquery>
			<cfif pf.c gt 0>
				<h2>
					There is a problem with #pf.c# of #data.recordcount# row(s). See the STATUS column. (<a href="/tools/BulkloadIdentification.cfm?action=dumpProblems">download</a>).
				</h2>
				<h3>
					Fix the problems in the data and <a href="/tools/BulkloadIdentification.cfm">start again</a>.
				</h3>
			<cfelse>
				<h2>
					Validation checks passed. Look over the table below and <a href="/tools/BulkloadIdentification.cfm?action=load">click to continue</a> if it all looks good.
				</h2>
			</cfif>
			<table class='sortable table table-responsive table-striped d-lg-table'>
				<thead>
					<tr>
						<th>INSTITUTION_ACRONYM</th>
						<th>COLLECTION_CDE</th>
						<th>OTHER_ID_TYPE</th>
						<th>OTHER_ID_NUMBER</th>
						<th>SCIENTIFIC_NAME</th>
						<th>MADE_DATE</th>
						<th>NATURE_OF_ID</th>
						<th>ACCEPTED_FG</th>
						<th>IDENTIFICATION_REMARKS</th>
						<th>taxa_formula</th>
						<th>AGENT_1</th>
						<th>AGENT_2</th>
						<th>STORED_AS_FG</th>
						<th>STATUS</th>
					</tr>
				<tbody>
					<cfloop query="data">
						<tr>
							<td>#data.INSTITUTION_ACRONYM#</td>
							<td>#data.COLLECTION_CDE#</td>
							<td>#data.OTHER_ID_TYPE#</td>
							<td>#data.OTHER_ID_NUMBER#</td>
							<td>#data.TaxonomyTaxonName# </td>
							<td>#data.MADE_DATE#</td>
							<td>#data.NATURE_OF_ID#</td>
							<td>#data.ACCEPTED_FG#</td>
							<td>#data.IDENTIFICATION_REMARKS#</td>
							<td>#data.TAXA_FORMULA#</td>
							<td>#data.AGENT_1#</td>
							<td>#data.AGENT_2#</td>
							<td>#data.STORED_AS_FG#</td>
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
				SELECT * FROM cf_temp_ID
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="NEXTID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select sq_identification_id.nextval NEXTID from dual
			</cfquery>
			<cftry>
				<cfset id_updates = 0>
				<cftransaction>
					<cfloop query="getTempData">
						<cfquery name="updateIds" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="updateIds_result">
							insert into identification (identification_id,collection_object_id,nature_of_id,accepted_id_fg,identification_remarks,taxa_formula,scientific_name,stored_as_fg,made_date)values(
							#NEXTID.NEXTID#,
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#collection_object_id#">,
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#nature_of_id#">,
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#accepted_fg#">,
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#identification_remarks#">,
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#taxa_formula#">,
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#scientific_name#">,
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#stored_as_fg#">,
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#made_date#">
							)
						</cfquery>
						<cfset id_updates = id_updates + updateIds_result.recordcount>
					</cfloop>
				</cftransaction>
				<h2>Updated #id_updates# identifications.</h2>
			<cfcatch>
				<h2>There was a problem updating Identifications.</h2>
				<cfquery name="getProblemData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT *
					FROM cf_temp_ID 
					WHERE status is not null
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<h3>Problematic Rows (<a href="/tools/BulkloadIdentification.cfm?action=dumpProblems">download</a>)</h3>
				<table class='sortable table table-responsive table-striped d-lg-table'>
					<thead>
						<tr>
							<th>institution_acronym</th>
							<th>collection_cde</th>
							<th>other_id_type</th>
							<th>other_id_number</th>
							<th>scientific_name</th>
							<th>made_date</th>
							<th>nature_of_id</th>
							<th>accepted_fg</th>
							<th>identification_remarks</th>
							<th>taxa_formula</th>
							<th>agent_1</th>
							<th>agent_2</th>
							<th>stored_as_fg</th>
							<th>status</th>
						</tr> 
					</thead>
					<tbody>
						<cfloop query="getProblemData">
							<tr>
								<td>#getProblemData.institution_acronym#</td>
								<td>#getProblemData.collection_cde#</td>
								<td>#getProblemData.other_id_type#</td>
								<td>#getProblemData.other_id_number#</td>
								<td>#getProblemData.scientific_name#</td>
								<td>#getProblemData.made_date#</td>
								<td>#getProblemData.nature_of_id#</td>
								<td>#getProblemData.accepted_fg#</td>
								<td>#getProblemData.identification_remarks#</td>
								<td>#getProblemData.taxa_formula#</td>
								<td>#getProblemData.agent_1#</td>
								<td>#getProblemData.agent_2#</td>
								<td>#getProblemData.stored_as_fg#</td>
								<td>#getProblemData.status#</td>
							</tr> 
						</cfloop>
					</tbody>
				</table>
				<cfrethrow>
			</cfcatch>
			</cftry>
		<!---	<cfset problem_key = "">
			<cftransaction>
				<cftry>
					<cfset id_updates = 0>
					<cfloop query="getTempData">
						<cfset problem_key = getTempData.key>
						<cfquery name="updateIds" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="updateIds_result">
							insert into identification (identification_id,collection_object_id,nature_of_id,accepted_id_fg,identification_remarks,taxa_formula,scientific_name,stored_as_fg,made_date) VALUES
							(#NEXTID.NEXTID#,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#nature_of_id#">,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#accepted_fg#">,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#identification_remarks#">,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#taxa_formula#">,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#scientific_name#">,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#stored_as_fg#">,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#made_date#">)
						</cfquery>
						<cfset id_updates = id_updates + updateIds_result.recordcount>
					</cfloop>
					<cftransaction action="commit">
				<cfcatch>
					<cftransaction action="rollback">
					<cfquery name="getProblemData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						SELECT *
						FROM cf_temp_id
						WHERE key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#problem_key#">
					</cfquery>
					<h3>Error updating row (#id_updates + 1#): #cfcatch.message#</h3>
					<table class='sortable table table-responsive table-striped d-lg-table'>
						<thead>
							<tr>
								<th>institution_acronym</th>
								<th>collection_cde</th>
								<th>other_id_type</th>
								<th>other_id_number</th>
								<th>scientific_name</th>
								<th>made_date</th>
								<th>nature_of_id</th>
								<th>accepted_fg</th>
								<th>identification_remarks</th>
								<th>agent_1</th>
								<th>agent_2</th>
								<th>taxon_name_id</th>
								<th>agent_1_id</th>
								<th>agent_2_id</th>
								<th>stored_as_fg</th>
								<th>status</th>
							</tr> 
						</thead>
						<tbody>
							<cfloop query="getProblemData">
								<tr>
									<td>#getProblemData.institution_acronym#</td>
									<td>#getProblemData.collection_cde#</td>
									<td>#getProblemData.other_id_type#</td>
									<td>#getProblemData.other_id_number#</td>
									<td>#getProblemData.scientific_name#</td>
									<td>#getProblemData.made_date#</td>
									<td>#getProblemData.nature_of_id#</td>
									<td>#getProblemData.accepted_fg#</td>
									<td>#getProblemData.identification_remarks#</td>
									<td>#getProblemData.agent_1#</td>
									<td>#getProblemData.agent_2#</td>
									<td>#getProblemData.taxon_name_id#</td>
									<td>#getProblemData.agent_1_id#</td>
									<td>#getProblemData.agent_2_id#</td>
									<td>#getProblemData.stored_as_fg#</td>
									<td>#getProblemData.status#</td>
								</tr> 
							</cfloop>
						</tbody>
					</table>
					<cfrethrow>
				</cfcatch>
				</cftry>
			</cftransaction>
			<h2>Updated #id_updates# Identifications.</h2>--->
			<h2>Success, changes applied.</h2>
			<!--- cleanup --->
			<cfquery name="clearTempTable" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="clearTempTable_result">
				DELETE FROM cf_temp_id
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
		</cfoutput>
	</cfif>
	