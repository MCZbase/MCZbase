<!--- special case handling to dump problem data as csv --->
<cfif isDefined("action") AND action is "dumpProblems">
	<cfquery name="getProblemData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		SELECT agent_type,preferred_name,first_name,middle_name,last_name,birth_date,death_date,agent_remark,prefix,suffix,other_name_1,other_name_type_1,other_name_2,other_name_type_2,other_name_3,other_name_type_3,agentguid_guid_type,agentguid,status 
		FROM cf_temp_agents 
		WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
	</cfquery>
	<cfinclude template="/shared/component/functions.cfc">
	<cfset csv = queryToCSV(getProblemData)>
	<cfheader name="Content-Type" value="text/csv">
	<cfoutput>#csv#</cfoutput>
	<cfabort>
</cfif>
<!--- end special case dump of problems --->

<cfset fieldlist = "agent_type,preferred_name,first_name,middle_name,last_name,birth_date, death_date,agent_remark,prefix,suffix,other_name_1,other_name_type_1,other_name_2,other_name_type_2,other_name_3,other_name_type_3,agentguid_guid_type,agentguid">
<cfset fieldTypes ="CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_DATE,CF_SQL_DATE,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR, CF_SQL_VARCHAR,CF_SQL_VARCHAR, CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR">
<cfset requiredfieldlist = "agent_type,preferred_name,last_name">

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
	<h1 class="h2 mt-2">Bulkload Agents</h1>

	<cfif #action# is "nothing">
		<cfoutput>
			<p>This tool is used to edit container information and/or move parts to a different parent container.</p>
			<p>Upload a comma-delimited text file (csv).  Include column headings, spelled exactly as below.  Additional colums will be ignored</p>
			<span class="btn btn-xs btn-info" onclick="document.getElementById('template').style.display='block';">View template</span>
			<div id="template" style="display:none;margin: 1em 0;">
				<label for="templatearea" class="data-entry-label">
					Copy this header line and save it as a .csv file (<a href="/tools/BulkloadAgents.cfm?action=getCSVHeader">download</a>)
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
				DELETE FROM cf_temp_agents 
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			
			<!--- check for required fields in header line --->
			<cfset agent_type_exists = false>
			<cfset preferred_name_exists = false>
			<cfset last_name_exists = false>
			<cfloop from="1" to ="#ArrayLen(arrResult[1])#" index="col">
				<cfset header = arrResult[1][col]>
				<cfif ucase(header) EQ 'agent_type'><cfset agent_type_exists=true></cfif>
				<cfif ucase(header) EQ 'preferred_name'><cfset preferred_name_exists=true></cfif>
				<cfif ucase(header) EQ 'last_name'><cfset last_name_exists=true></cfif>
			</cfloop>
			<cfif not (agent_type_exists AND preferred_name_exists AND last_name_exists)>
				<cfset message = "One or more required fields are missing in the header line of the csv file.">
				<cfif not agent_type_exists><cfset message = "#message# agent_type is missing."></cfif>
				<cfif not preferred_name_exists><cfset message = "#message# preferred_name is missing."></cfif>
				<cfif not last_name_exists><cfset message = "#message# last_name is missing."></cfif>
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
							insert into cf_temp_agents
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
				Successfully loaded #loadedRows# records from the CSV file.  Next <a href="/tools/BulkloadAgents.cfm?action=validate">click to validate</a>.
			</h3>
		</cfoutput>
	</cfif>
	<!------------------------------------------------------->
	<cfif #action# is "validate">
		<h2 class="h3">Second step: Data Validation</h2>
		<cfoutput>
			<cfquery name="getCID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				update cf_temp_agents set container_id=
				(select container_id from container where container.barcode = cf_temp_agents.container_unique_id)
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="getCID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				update cf_temp_agents set parent_container_id=
				(select container_id from container where container.barcode = cf_temp_agents.parent_unique_id)
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="miac" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE cf_temp_agents 
				SET status = 'container_not_found'
				WHERE container_id is null
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="miap" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE cf_temp_agents 
				SET status = 'parent_container_not_found'
				WHERE parent_container_id is null and parent_unique_id is not null
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="miap" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE cf_temp_agents 
				SET status = 'bad_container_type'
				WHERE container_type not in (select container_type from ctcontainer_type)
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="miap" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE cf_temp_agents
				SET status = 'missing_label'
				WHERE CONTAINER_NAME is null
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT agent_type, preferred_name, first_name, middle_name, last_name, birth_date, death_date, agent_remark, prefix, suffix, other_name_1, other_name_type_1,other_name_2,other_name_type_2,other_name_3,other_name_type_3,agentguid_guid_type, agentguid, status
				FROM cf_temp_agents
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="pf" dbtype="query">
				SELECT count(*) c 
				FROM data 
				WHERE status is not null
			</cfquery>
			<cfif pf.c gt 0>
				<h2>
					There is a problem with #pf.c# of #data.recordcount# row(s). See the STATUS column. (<a href="/tools/BulkloadAgents.cfm?action=dumpProblems">download</a>).
				</h2>
				<h3>
					Fix the problems in the data and <a href="/tools/BulkloadAgents.cfm">start again</a>.
				</h3>
			<cfelse>
				<h2>
					Validation checks passed. Look over the table below and <a href="/tools/BulkloadAgents.cfm?action=load">click to continue</a> if it all looks good.
				</h2>
			</cfif>
			<table class='sortable table table-responsive table-striped d-lg-table'>
				<thead>
					<tr>
						<th>AGENT_TYPE</th>
						<th>PREFERRED_NAME</th>
						<th>FIRST_NAME</th>
						<th>MIDDLE_NAME</th>
						<th>LAST_NAME</th>
						<th>BIRTH_DATE</th>
						<th>DEATH_DATE</th>
						<th>AGENT_REMARK</th>
						<th>PREFIX</th>
						<th>SUFFIX</th>
						<th>OTHER_NAME_1</th>
						<th>OTHER_NAME_TYPE_1</th>
						<th>OTHER_NAME_2</th>
						<th>OTHER_NAME_TYPE_2</th>
						<th>OTHER_NAME_3</th>
						<th>OTHER_NAME_TYPE_3</th>
						<th>agentguid_guid_type</th>
						<th>agentguid</th>
						<th>STATUS</th>
					</tr>
				<tbody>
					<cfloop query="data">
						<tr>
							<td>#data.AGENT_TYPE#</td>
							<td>#data.PREFERRED_NAME#</td>
							<td>#data.FIRST_NAME#</td>
							<td>#data.MIDDLE_NAME#</td>
							<td>#data.LAST_NAME#</td>
							<td>#data.BIRTH_DATE#</td>
							<td>#data.DEATH_DATE#</td>
							<td>#data.AGENT_REMARK#</td>
							<td>#data.PREFIX#</td>
							<td>#data.SUFFIX#</td>
							<td>#data.OTHER_NAME_1#</td>
							<td>#data.OTHER_NAME_TYPE_1#</td>
							<td>#data.OTHER_NAME_2#</td>
							<td>#data.OTHER_NAME_TYPE_2#</td>
							<td>#data.OTHER_NAME_3#</td>
							<td>#data.OTHER_NAME_TYPE_3#</td>
							<td>#data.agentguid_guid_type#</td>
							<td>#data.agentguid#</td>
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
				SELECT * FROM cf_temp_agents
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cftry>
				<cfset agent_updates = 0>
				<cftransaction>
					<cfloop query="getTempData">
						<cfquery name="updateAgents" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="updateAgents_result">
							UPDATE
								agent_name 
							SET
								agent_name_type= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#agent_TYPE#">
							WHERE
								AGENT_ID= <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#AGENT_ID#">
						</cfquery>
						<cfset agent_updates = agent_updates + updateAgents_result.recordcount>
					</cfloop>
				</cftransaction>
				<h2>Updated #agent_updates# agents.</h2>
			<cfcatch>
				<h2>There was a problem updating container types.</h2>
				<cfquery name="getProblemData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT agent_type, preferred_name, first_name, middle_name, last_name, birth_date, death_date, agent_remark, prefix, suffix, other_name_1, other_name_type_1,other_name_2,other_name_type_2,other_name_3,other_name_type_3,agentguid_guid_type, agentguid, status 
					FROM cf_temp_agents 
					WHERE status is not null
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<h3>Problematic Rows (<a href="/tools/BulkloadAgents.cfm?action=dumpProblems">download</a>)</h3>
				<table class='sortable table table-responsive table-striped d-lg-table'>
					<thead>
						<tr>
							<th>agent_type</th><th>preferred_name</th><th>first_name</th><th>middle_name</th><th>last_name</th><th>birth_date</th><th>death_date</th><th>agent_remark</th><th>prefix</th><th>suffix</th><th>other_name_1</th><th>other_name_type_1</th><th>other_name_2</th><th>other_name_type_2</th><th>other_name_3</th><th>other_name_type_3</th><th>agentguid_guid_type</th><th>agentguid</th><th>status</th>
						</tr> 
					</thead>
					<tbody>
						<cfloop query="getProblemData">
							<tr>
								<td>#getProblemData.agent_type#</td>
								<td>#getProblemData.preferred_name#</td>
								<td>#getProblemData.first_name#</td>
								<td>#getProblemData.middle_name#</td>
								<td>#getProblemData.agent_type#</td>
								<td>#getProblemData.preferred_name#</td>
								<td>#getProblemData.first_name#</td>
								<td>#getProblemData.middle_name#</td>
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
				DELETE FROM cf_temp_agents
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
		</cfoutput>
	</cfif>
	
	
	
	
	
	
	
	
	
	
	
	
	
	
<!---<cfinclude template="/includes/_header.cfm">
<cfif #action# is "nothing">
Step 1: Upload a comma-delimited text file (csv). 
Include column headings, spelled exactly as below. 
<br><span class="likeLink" onclick="document.getElementById('template').style.display='block';">view template</span>
	<div id="template" style="display:none;">
		<label for="t">Copy and save as a .csv file</label>
		<textarea rows="2" cols="80" id="t">agent_type,preferred_name,first_name,middle_name,last_name,birth_date,death_date,agent_remark,prefix,suffix,other_name_type,other_name,other_name_2,other_name_type_2,other_name_3,other_name_type_3</textarea>
	</div> 
<p></p>




Columns in <span style="color:red">red</span> are required; others are optional:
<ul>
	<li style="color:red">agent_type</li>
	<li style="color:red">preferred_name</li>
	<li>first_name (agent_type="person" only)</li>
	<li>middle_name (agent_type="person" only)</li>
	<li>last_name (agent_type="person" only)</li>
	<li>birth_date (agent_type="person" only; format 1-Jan-2000)</li>
	<li>death_date (agent_type="person" only; format 1-Jan-2000)</li>
	<li>agent_remark</li>
	<li>prefix (agent_type="person" only)</li>
	<li>suffix (agent_type="person" only)</li>
	<li>other_name_type (second name type)</li>
	<li>other_name (second name)</li>
    <li>other_name_type_2</li>
	<li>other_name_2</li>
    <li>other_name_type_3</li>
	<li>other_name_3</li>				 
</ul>

<cfform name="atts" method="post" enctype="multipart/form-data">
			<input type="hidden" name="Action" value="getFile">
			  <input type="file"
		   name="FiletoUpload"
		   size="45">
			 <input type="submit" value="Upload this file"
		class="savBtn"
		onmouseover="this.className='savBtn btnhov'" 
		onmouseout="this.className='savBtn'">
  </cfform>

</cfif>--->
<!------------------------------------------------------->
<!------------------------------------------------------->

<!------------------------------------------------------->
<!---<cfif #action# is "getFile">
<cfoutput>

	<cfquery name="killOld" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		delete from cf_temp_agents
	</cfquery>
	<cffile action="READ" file="#FiletoUpload#" variable="fileContent">
	<cfset fileContent=replace(fileContent,"'","''","all")>
	<cfset arrResult = CSVToArray(CSV = fileContent.Trim()) />
	<cfset numberOfColumns = ArrayLen(arrResult[1])>--->

	
<!---	<cfset colNames="">
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
				insert into cf_temp_agents (#colNames#) values (#preservesinglequotes(colVals)#)
			</cfquery>
		</cfif>
	</cfloop>
</cfoutput>--->

 
<!---	<cflocation url="BulkloadAgents.cfm?action=validate">

</cfif>--->
<!---<cfif #action# is "validate">
<cfoutput>
<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select * from cf_temp_agents
</cfquery>
<cfquery name="setStatus" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	update cf_temp_agents set status='missing_data'
	where agent_type is null OR
	preferred_name is null
</cfquery>
<cfquery name="setStatus2" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	update cf_temp_agents set status='bad_type'
	where status is null AND (
		agent_type not in (select agent_type from ctagent_type))
</cfquery>
<cfquery name="setStatus2" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	update cf_temp_agents set status='bad_prefix'
	where status is null AND 
	prefix is not null and (
		prefix not in (select prefix from ctprefix))
</cfquery>
<cfquery name="setStatus2" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	update cf_temp_agents set status='bad_suffix'
	where status is null AND 
	suffix is not null and (
		suffix not in (select suffix from ctsuffix))
</cfquery>
<cfquery name="setStatus2" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	update cf_temp_agents set status='last_name_required'
	where status is null AND 
		agent_type ='person' and
		last_name is null
</cfquery>
<cfquery name="setStatus2" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	update cf_temp_agents set status='not_a_person'
	where status is null AND 
	agent_type != 'person' and (
		suffix is not null OR
		prefix is not null OR
		birth_date is not null OR
		death_date is not null OR
		first_name is not null OR
		middle_name is not null OR
		last_name is not null)
</cfquery>
<cfquery name="setStatus2" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	update cf_temp_agents set status='missing_name_type'
	where status is null AND 
	other_name is not null and other_name_type is null
</cfquery>
<cfquery name="setStatus2" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	update cf_temp_agents set status='bad_name_type'
	where status is null AND 
	other_name is not null and other_name_type is not null and
	other_name_type not in (select agent_name_type from ctagent_name_type)
</cfquery>
<cfquery name="setStatus3" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	update cf_temp_agents set status='bad_name_type'
	where status is null AND 
	other_name_2 is not null and other_name_type_2 is not null and
	other_name_type_2 not in (select agent_name_type from ctagent_name_type)
</cfquery>
<cfquery name="setStatus4" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	update cf_temp_agents set status='bad_name_type'
	where status is null AND 
	other_name_3 is not null and other_name_type_3 is not null and
	other_name_type_3 not in (select agent_name_type from ctagent_name_type)
</cfquery>
<cfquery name="bads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select * from cf_temp_agents where status is not null
</cfquery>

<cfif bads.recordcount gt 0>
	Your data will not load! See STATUS column below for more information.
	<cfdump var=#bads#>
<cfelse>
	Review the dump below. If everything seems OK, 
	<a href="BulkloadAgents.cfm?action=loadData">click here to proceed</a>.
	<cfdump var=#d#>
</cfif>--->


<!---</cfoutput>
</cfif>
<cfif #action# is "loadData">

<cfoutput>
	<cfquery name="getTempData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select * from cf_temp_agents
	</cfquery>
	<cftransaction>
	<cfloop query="getTempData">
		<cfquery name="newAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			insert into agent ( AGENT_ID,AGENT_TYPE ,AGENT_REMARKS , PREFERRED_AGENT_NAME_ID)
			values (sq_agent_id.nextval,'#agent_type#','#agent_remark#',#agent_name_id#)
		</cfquery>
		<cfquery name="newAgentName" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			insert into agent_name ( AGENT_NAME_ID,AGENT_ID,AGENT_NAME_TYPE,AGENT_NAME )
			values (sq_agent_name_id.nextval,sq_agent_id.currval,'preferred','#preferred_name#')
		</cfquery>
		
		<cfif #agent_type# is "person">
			<cfquery name="newProj" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				insert into person (PERSON_ID,PREFIX,LAST_NAME,FIRST_NAME,
					MIDDLE_NAME,SUFFIX,BIRTH_DATE,DEATH_DATE)
				values (sq_agent_id.currval,'#PREFIX#','#LAST_NAME#','#FIRST_NAME#',
					'#MIDDLE_NAME#','#SUFFIX#','#dateformat(BIRTH_DATE,"yyyy-mm-dd")#', '#dateformat(DEATH_DATE,"yyyy-mm-dd")#')
			</cfquery>
		</cfif>
		<cfif len(#OTHER_NAME#) gt 0>
			<cfset agent_name_id = #agent_name_id# + 1>
			<cfquery name="newAgentName" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				insert into agent_name ( AGENT_NAME_ID,AGENT_ID,AGENT_NAME_TYPE,AGENT_NAME )
				values (sq_agent_name_id.nextval,sq_agent_id.currval,'#OTHER_NAME_TYPE#','#OTHER_NAME#')
			</cfquery>
		</cfif>
        <cfif len(#OTHER_NAME_2#) gt 0>
			<cfset agent_name_id = #agent_name_id# + 1>
			<cfquery name="newAgentName" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				insert into agent_name ( AGENT_NAME_ID,AGENT_ID,AGENT_NAME_TYPE,AGENT_NAME )
				values (sq_agent_name_id.nextval,sq_agent_id.currval,'#OTHER_NAME_TYPE_2#','#OTHER_NAME_2#')
			</cfquery>
		</cfif>
        <cfif len(#OTHER_NAME_3#) gt 0>
			<cfset agent_name_id = #agent_name_id# + 1>
			<cfquery name="newAgentName" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				insert into agent_name ( AGENT_NAME_ID,AGENT_ID,AGENT_NAME_TYPE,AGENT_NAME )
				values (sq_agent_name_id.nextval,sq_agent_id.currval,'#OTHER_NAME_TYPE_3#','#OTHER_NAME_3#')
			</cfquery>
		</cfif>
	</cfloop>
	</cftransaction>

	Spiffy, all done.
</cfoutput>
</cfif>

<cfinclude template="/includes/_footer.cfm">--->
