<!--- tools/bulkloadAgents.cfm add agents to specimens in bulk.

Copyright 2008-2017 Contributors to Arctos
Copyright 2008-2024 President and Fellows of Harvard College

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

--->
<!--- special case handling to dump problem data as csv --->
<cfif isDefined("action") AND action is "dumpProblems">
	<cfquery name="getProblemData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		SELECT agent_type,preferred_name,first_name,middle_name,last_name,birth_date,death_date,agent_remark,prefix,suffix,other_name_1,other_name_type_1,other_name_2,other_name_type_2,other_name_3,other_name_type_3,agentguid_guid_type,agentguid,t_preferred_agent_name_id,t_agent_id,status
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
<cfset fieldlist = "AGENT_TYPE,PREFERRED_NAME,FIRST_NAME,MIDDLE_NAME,LAST_NAME,BIRTH_DATE,DEATH_DATE,AGENT_REMARK,PREFIX,SUFFIX,OTHER_NAME_1,OTHER_NAME_TYPE_1,OTHER_NAME_2,OTHER_NAME_TYPE_2,OTHER_NAME_3,OTHER_NAME_TYPE_3,AGENTGUID_GUID_TYPE,AGENTGUID">
<cfset fieldTypes = "CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_DATE,CF_SQL_DATE,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR">
<cfset requiredfieldlist = "AGENT_TYPE,PREFERRED_NAME,LAST_NAME">

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
<cfset pageTitle = "Bulkload Agents">
<cfinclude template="/shared/_header.cfm">
<cfinclude template="/tools/component/csv.cfc" runOnce="true"><!--- for common csv testing functions --->
<cfif not isDefined("action") OR len(action) EQ 0><cfset action="nothing"></cfif>
<main class="container-fluid py-3 px-xl-5" id="content">
	<h1 class="h2 mt-2">Bulkload Agents</h1>
	<cfif #action# is "nothing">
		<cfoutput>
			<p>This tool is used to bulkload agents.</p>
			<p>Upload a comma-delimited text file (csv).  Include column headings, spelled exactly as below.  Additional colums will be ignored</p>
			<p>	<p><a href="/info/ctDocumentation.cfm?table=ctagent_name_type">Valid agent name types</a>, <a href="/info/ctDocumentation.cfm?table=ctagent_type">Valid agent types</a>, <a href="/info/ctDocumentation.cfm?table=ctguid_type">Valid agent_guid_guid_types</a></p>

			<span class="btn btn-xs btn-info" onclick="document.getElementById('template').style.display='block';">View template</span>
			<div id="template" style="margin: 1rem 0;display:none;">
				<label for="templatearea" class="data-entry-label mb-1">
					Copy this header line and save it as a .csv file (<a href="/tools/BulkloadAgents.cfm?action=getCSVHeader" class="font-weight-lessbold">download</a>)
				</label>
				<textarea rows="2" cols="90" id="templatearea" class="w-100 data-entry-textarea">#fieldlist#</textarea>
			</div>
			<h2 class="mt-4 h4">Columns in <span class="text-danger">red</span> are required; others are optional:</h2>
			<ul class="mb-4 h5 font-weight-normal list-group mx-3">
				<cfloop list="#fieldlist#" index="field" delimiters=",">
					<cfquery name = "getComments"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#"  result="getComments_result">
						SELECT comments
						FROM sys.all_col_comments
						WHERE 
							owner = 'MCZBASE'
							and table_name = 'CF_TEMP_AGENTS'
							and column_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(field)#" />
					</cfquery>
					<cfset comment = "">
					<cfif getComments.recordcount GT 0>
						<cfset comment = getComments.comments>
					</cfif>
					<cfset aria = "">
					<cfif listContains(requiredfieldlist,field,",")>
						<cfset class="text-danger">
						<cfset aria = "aria-label='Required Field'">
					<cfelse>
						<cfset class="text-dark">
					</cfif>
					<li class="pb-1 mx-3">
						<span class="#class# font-weight-lessbold" #aria#>#field#: </span> <span class="text-secondary">#comment#</span>
					</li>
				</cfloop>
			</ul>
			<form name="agts" method="post" enctype="multipart/form-data" action="/tools/BulkloadAgents.cfm">
				<div class="form-row border rounded p-2">
					<input type="hidden" name="action" value="getFile">
					<div class="col-12 col-md-4">
						<label for="fileToUpload" class="data-entry-label">File to bulkload:</label> 
						<input type="file" name="FiletoUpload" id="fileToUpload" class="data-entry-input p-0 m-0">
					</div>
					<div class="col-12 col-md-3">
						<cfset charsetSelect = getCharsetSelectHTML()>
					</div>
					<div class="col-12 col-md-3">
						<cfset formatSelect = getFormatSelectHTML()>
					</div>
					<div class="col-12 col-md-2">
						<label for="submitButton" class="data-entry-label">&nbsp;</label>
						<input type="submit" id="submittButton" value="Upload this file" class="btn btn-primary btn-xs">
					</div>
				</div>
			</form>
		</cfoutput>
	</cfif>	
	
	
<!------------------------------------------------------->
	<cfif #action# is "getFile">
		<h2 class="h4">First step: Reading data from CSV file.</h2>
		<cfoutput>
		<!--- Compare the numbers of headers expected against provided in CSV file --->
		<!--- Set some constants to identify error cases in cfcatch block --->
		<cfset NO_COLUMN_ERR = "One or more required fields are missing in the header line of the csv file.">
		<cfset DUP_COLUMN_ERR = "One or more columns are duplicated in the header line of the csv file.">
		<cfset COLUMN_ERR = "Error inserting data">
		<cfset NO_HEADER_ERR = "No header line found, csv file appears to be empty.">
		<cfset TABLE_NAME = "CF_TEMP_AGENTS">
		<cftry>
			<!--- cleanup any incomplete work by the same user --->
			<cfquery name="clearTempTable" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="clearTempTable_result">
				DELETE FROM cf_temp_agents
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>

				<cfset variables.foundHeaders =""><!--- populated by loadCsvFile --->
				<cfset variables.size=""><!--- populated by loadCsvFile --->
				<cfset iterator = loadCsvFile(FileToUpload=FileToUpload,format=format,characterSet=characterSet)>			

				<!--- Note: As we can't use csvFormat.withHeader(), we can not match columns by name, we are forced to do so by number, thus arrays --->
				<cfset colNameArray = listToArray(ucase(variables.foundHeaders))><!--- the list of columns/fields found in the input file --->
				<cfset fieldArray = listToArray(ucase(fieldlist))><!--- the full list of fields --->
				<cfset typeArray = listToArray(fieldTypes)><!--- the types for the full list of fields --->
				<div class="col-12 my-4 px-0">
					<h3 class="h4">Found #variables.size# columns in header of csv file.</h3>
					There are #ListLen(fieldList)# columns expected in the header (of these #ListLen(requiredFieldList)# are required).
				</div>

				<!--- check for required fields in header line, list all fields, throw exception and fail if any required fields are missing --->
				<cfset reqFieldsResponse = checkRequiredFields(fieldList=fieldList,requiredFieldList=requiredFieldList,NO_COLUMN_ERR=NO_COLUMN_ERR,TABLE_NAME=TABLE_NAME)>

				<!--- Test for additional columns not in list, warn and ignore. --->
				<cfset addFieldsResponse = checkAdditionalFields(fieldList=fieldList)>

				<!--- Identify duplicate columns and fail if found --->
				<cfset dupFieldsResponse = checkDuplicateFields(foundHeaders=variables.foundHeaders,DUP_COLUMN_ERR=DUP_COLUMN_ERR)>

				<cfset colNames="#variables.foundHeaders#">
				<cfset loadedRows = 0>
				<cfset foundHighCount = 0>
				<cfset foundHighAscii = "">
				<cfset foundMultiByte = "">
				<!--- Iterate through the remaining rows inserting the data into the temp table. --->
				<cfset row = 0>
				<cfloop condition="#iterator.hasNext()#">
					<!--- obtain the values in the current row --->
					<cfset rowData = iterator.next()>
					<cfset row = row + 1>
					<cfset columnsCountInRow = rowData.size()>
					<cfset collValuesArray= ArrayNew(1)>
					<cfloop index="i" from="0" to="#rowData.size() - 1#">
						<!--- loading cells from object instead of list allows commas inside cells --->
						<cfset thisBit = "#rowData.get(JavaCast('int',i))#" >
						<!--- store in a coldfusion array so we won't need JavaCast to reference by position --->
						<cfset ArrayAppend(collValuesArray,thisBit)>
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
					<cftry>
						<!--- construct insert for row with a line for each entry in fieldlist using cfqueryparam if column header is in fieldlist, otherwise using null --->
						<!--- Note: As we can't use csvFormat.withHeader(), we can not match columns by name, we are forced to do so by number, thus arrays --->
						<cfquery name="insert" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="insert_result">
							insert into cf_temp_agents
								(#fieldlist#,username)
							values (
								<cfset separator = "">
								<cfloop from="1" to ="#ArrayLen(fieldArray)#" index="col">
									<cfif arrayFindNoCase(colNameArray,fieldArray[col]) GT 0>
										<cfset fieldPos=arrayFind(colNameArray,fieldArray[col])>
										<cfset val=trim(collValuesArray[fieldPos])>
										<cfset val=rereplace(val,"^'+",'')>
										<cfset val=rereplace(val,"'+$",'')>
										<cfif val EQ ""> 
											#separator#NULL
										<cfelse>
											#separator#<cfqueryparam cfsqltype="#typeArray[col]#" value="#val#">
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
						<cfset error_message="<h4>Check character set and format selected if your headers match required headers in red above.</h4> #COLUMN_ERR# from line #row# in input file.  <br>Header:[#colNames#] <br>Row:[#ArrayToList(collValuesArray)#] <br>Error: #cfcatch.message#"><!--- " --->
						<cfif isDefined("cfcatch.queryError")>
							<cfset error_message = "#error_message# #cfcatch.queryError#">
						</cfif>
						<cfthrow message = "#error_message#">
					</cfcatch>
					</cftry>
				</cfloop>
			
				<cfif foundHighCount GT 0>
					<cfset extendedResult = reportExtended(foundHighCount=foundHighCount,foundHighAscii=foundHighAscii,foundMultiByte=foundMultiByte,linkTarget='/tools/BulkloadAgents.cfm')>	
				</cfif>
				<h3 class="mt-3">
					<cfif loadedRows EQ 0>
						Loaded no rows from the CSV file. The file appears to be just a header with no data. Fix file and <a href="/tools/BulkloadAgents.cfm" class="text-danger">start again</a>
					<cfelse>
						<cfif variables.size eq 1>
							Size = 1
						<cfelse>
						Successfully read #loadedRows# records from the CSV file. Next <a href="/tools/BulkloadAgents.cfm?action=validate" class="btn-link font-weight-lessbold">click to validate</a>.</cfif>
					</cfif>
				</h3>
			<cfcatch>
				<h3 class="mt-3">
					<strong class="text-danger">Failed to read the CSV file.</strong> Fix the errors in the file and <a href="/tools/BulkloadAgents.cfm" class="text-danger">start again</a>.
				</h3>
				<cfif isDefined("variables.foundHeaders")>
					<cfset foundHighCount = 0>
					<cfset foundHighAscii = "">
					<cfset foundMultiByte = "">
					<cfloop list="#variables.foundHeaders#" index="thisBit">
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
						<cfset extendedResult = reportExtended(foundHighCount=foundHighCount,foundHighAscii=foundHighAscii,foundMultiByte=foundMultiByte,linkTarget='/tools/BulkloadAgents.cfm',inHeader='yes')>	
					</cfif>
				</cfif>
				<!--- identify and provide guidance for some standard failure conditions --->
				<cfif format EQ "DEFAULT"><cfset fmt="CSV: Default Comma Separated values"><cfelse><cfset fmt="#format#"></cfif>
				<cfif Find("#NO_COLUMN_ERR#",cfcatch.message) GT 0>
					<h4 class='mb-3'>#cfcatch.message#</h4>
				<cfelseif Find("#NO_HEADER_ERR#",cfcatch.message) GT 0>
					<h4 class='mb-3'>#cfcatch.message#</h4>
				<cfelseif Find("#COLUMN_ERR#",cfcatch.message) GT 0>
					<h4 class='mb-3'>#cfcatch.message#</h4>
				<cfelseif Find("#DUP_COLUMN_ERR#",cfcatch.message) GT 0>
					<h4 class='mb-3'>#cfcatch.message#</h4>
				<cfelseif Find("IOException reading next record: java.io.IOException: (line 1) invalid char between encapsulated token and delimiter",cfcatch.message) GT 0>
					<h4 class='mb-3'>
						Unable to read headers in line 1.  Does your file actually have the format #fmt#?  Did you select CSV format for a tab delimited file?
					</h4>
				<cfelseif Find("IOException reading next record: java.io.IOException: (line 1)",cfcatch.message) GT 0>
					<h4 class='mb-3'>
						Unable to read headers in line 1.  Is your file actually have the format #fmt#?
					</h4>
					<h4 class='mb-3'>#cfcatch.message#</h4>
				<cfelseif Find("invalid char between encapsulated token and delimiter",cfcatch.message) GT 0>
					<h4 class='mb-3'>
						Does your file have an inconsitent format?  Are some lines tab delimited but others comma delimited?
					</h4>
				<cfelseif Find("IOException reading next record: java.io.IOException:",cfcatch.message) GT 0>
					<h4 class='mb-3'>
						Unable to read a record from the file.  One or more lines may not be consistent with the specified format #fmt#
					</h4>
					<h4 class='mb-3'>#cfcatch.message#</h4>
				<cfelse>
					<cfdump var="#cfcatch#">
				</cfif>
			</cfcatch>

			<cffinally>
				<cftry>
					<!--- Close the CSV parser and the reader --->
					<cfset csvParser.close()>
					<cfset fileReader.close()>
				<cfcatch>
					<!--- consume exception and proceed --->
				</cfcatch>
				</cftry>
			</cffinally>
		</cftry>
		</cfoutput>
	</cfif>
			
	<!------------------------------------------------------->
	<cfif #action# is "validate">
		<h2 class="h4">Second step: Data Validation</h2>
		<cfoutput>
			<cfset key = ''>
			<cfquery name="ctagent_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				select agent_type from ctagent_type order by agent_type
			</cfquery>
			<cfquery name="ctagent_name_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				select agent_name_type from ctagent_name_type order by agent_name_type
			</cfquery>
			<cfquery name="ctguid_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				select guid_type, placeholder from ctguid_type where applies_to like '%agent%' order by guid_type
			</cfquery>

			<cfquery name="rpn" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				select count(*) c from cf_temp_agents where preferred_name is null
				and username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfif rpn.c is not 0>
				<div>Preferred name is required for every agent.</div>
				<cfabort>
			</cfif>
			<cfquery name="getTempTableQC" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT 
					key,to_char(birth_date,'YYYY-MM-DD') birth_date,agent_type,preferred_name,first_name,middle_name,last_name,to_char(death_date,'YYYY-MM-DD') death_date,agent_remark,prefix,suffix,other_name_1,other_name_type_1,other_name_2,other_name_type_2,other_name_3,other_name_type_3,agentguid_guid_type,agentguid,status
				FROM 
					cf_temp_agents
				WHERE 
					username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfset i = 1>
			<cfloop query="getTempTableQC">
				<cfquery name="dupAgntName" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="dupAgntName_result">
					UPDATE cf_temp_agents
					SET 
						status = concat(nvl2(status, status || '; ', ''), 'Agent name already exists')
					WHERE 
						preferred_name in (select agent_name from preferred_agent_name where agent_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempTableQC.preferred_name#">)
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cfquery name="invAgntType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="invAgntType_result">
					UPDATE cf_temp_agents
					SET 
						status = concat(nvl2(status, status || '; ', ''), 'Agent type not valid - check controlled vocabulary')
					WHERE 
						agent_type not in (select agent_type from ctagent_type where agent_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempTableQC.agent_type#">)
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cfquery name="invAgntPrefix" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="invAgntPrefix_result">
					UPDATE cf_temp_agents
					SET 
						status = concat(nvl2(status, status || '; ', ''), 'Prefix not valid - check controlled vocabulary')
					WHERE 
						prefix not in (select prefix from ctprefix where prefix = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempTableQC.prefix#">)
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cfquery name="invAgntName1" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="invAgntPrefix_result">
					UPDATE cf_temp_agents
					SET 
						status = concat(nvl2(status, status || '; ', ''), 'Agent type not valid - check controlled vocabulary')
					WHERE 
						other_name_type_1 not in (
					select agent_type from ctagent_type where agent_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempTableQC.other_name_type_1#">
					)
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cfquery name="invAgntName2" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="invAgntPrefix_result">
					UPDATE cf_temp_agents
					SET 
						status = concat(nvl2(status, status || '; ', ''), 'OTHER_NAME_TYPE_2 not valid - check controlled vocabulary')
					WHERE 
						other_name_type_2 not in (
					select agent_type from ctagent_type where agent_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempTableQC.other_name_type_2#">
					)
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cfquery name="invAgntName3" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="invAgntPrefix_result">
					UPDATE cf_temp_agents
					SET 
						status = concat(nvl2(status, status || '; ', ''), 'OTHER_NAME_TYPE_3 not valid - check controlled vocabulary')
					WHERE 
						other_name_type_3 not in (
					select agent_type from ctagent_type where agent_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempTableQC.other_name_type_3#">
					)
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
			</cfloop>
			<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT to_char(birth_date,'YYYY-MM-DD') birth_date,agent_type, preferred_name,first_name,middle_name,last_name,to_char(death_date,'YYYY-MM-DD') death_date,agent_remark,prefix,suffix,other_name_1,other_name_type_1,other_name_2,other_name_type_2,other_name_3,other_name_type_3,agentguid_guid_type,agentguid,status
				FROM cf_temp_agents
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="pf" dbtype="query">
				SELECT count(*) c 
				FROM data 
				WHERE status is not null
			</cfquery>
			<h3 class="mt-3">
				<cfif pf.c gt 0>
					There is a problem with #pf.c# of #data.recordcount# row(s). See the STATUS column. (<a href="/tools/BulkloadAgents.cfm?action=dumpProblems">download</a>). Fix the problems in the data and <a href="/tools/BulkloadAgents.cfm" class="text-danger">start again</a>.
				<cfelse>
					<span class="text-success">Validation checks passed</span>. Look over the table below and <a href="/tools/BulkloadAgents.cfm?action=load" class="btn-link font-weight-lessbold">click to continue</a> if it all looks good or <a href="/tools/BulkloadAgents.cfm" class="text-danger">start again</a>.
				</cfif>
			</h3>
			<table class='sortable px-0 mx-0 table small table-responsive table-striped w-100'>
				<thead>
					<tr>
						<th>BULKLOADING&nbsp;STATUS</th>
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
						<th>AGENTGUID_GUID_TYPE</th>
						<th>AGENTGUID</th>
					</tr>
				<tbody>
					<cfloop query="data">
						<tr>
							<td><cfif len(data.status) eq 0>Cleared to load<cfelse><strong>#data.status#</strong></cfif></td>
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
						</tr>
					</cfloop>
				</tbody>
			</table>
		</cfoutput>
	</cfif>
	<!-------------------------------------------------------------------------------------------->
	<cfif action is "load">
		<h2 class="h4 mb-3">Third step: Apply changes.</h2>
		<cfoutput>
			<cfset problem_key = "">
			<cftransaction>
				<cfquery name="getTempData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					select key,to_char(birth_date,'YYYY-MM-DD') birth_date,agent_type, preferred_name,first_name,middle_name,last_name,to_char(death_date,'YYYY-MM-DD') death_date,agent_remark,prefix,suffix,other_name_1,other_name_type_1,other_name_2,other_name_type_2,other_name_3,other_name_type_3,agentguid_guid_type,agentguid,t_preferred_agent_name_id,t_agent_id,status
					from cf_temp_agents
				</cfquery>
				<cfquery name="getCounts" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT count(distinct preferred_name) AID FROM cf_temp_agents
					WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cftry>
					<cfset agent_updates = 0>
					<cfif getTempData.recordcount EQ 0>
						<cfthrow message="You have no rows to load in the agents bulkloader table (cf_temp_agents).  <a href='/tools/BulkloadAgents.cfm' class='text-danger'>Start again</a>"><!--- " --->
					</cfif>
					<cfloop query="getTempData">
						<cfset problem_key = #getTempData.key#>
						<cfquery name="newAgents" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="insResult">
							insert into agent (
							AGENT_ID, 
							AGENT_TYPE, 
							AGENT_REMARKS, 
							PREFERRED_AGENT_NAME_ID)
							values (
							sq_agent_id.nextval,
							'#agent_type#',
							'#agent_remark#',
							sq_agent_name_id.nextval
							)
						</cfquery>
						<cfquery name="savePK" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="pkResult">
							select preferred_agent_name_id,agent_id 
							from agent
							where ROWIDTOCHAR(rowid) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#insResult.GENERATEDKEY#">
						</cfquery>
						<cfquery name="newPrefAgentName" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="insResult">
							insert into agent_name (
							AGENT_NAME_ID, 
							AGENT_ID, 
							AGENT_NAME_TYPE, 
							AGENT_NAME
							) values (
							#savePK.preferred_agent_name_id#,
							#savePK.agent_ID#,
							'preferred',
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.preferred_name#">
							)
						</cfquery>
						<cfset agentNAMEID = #savePK.preferred_agent_name_id#>
						<cfquery name="agent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="pkResult">
							select preferred_agent_name_id 
							from agent
							where preferred_agent_name_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#agentNAMEID#">
						</cfquery>
						<cfif #agent_type# is "person">
							<cfquery name="newPerson" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
								insert into person (
								PERSON_ID,
								PREFIX,
								LAST_NAME,
								FIRST_NAME,
								MIDDLE_NAME,
								SUFFIX,
								BIRTH_DATE,
								DEATH_DATE
								) values (
								#savePK.agent_id#,
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#PREFIX#">,
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#LAST_NAME#">,
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#FIRST_NAME#">,
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#MIDDLE_NAME#">,
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#SUFFIX#">,
								'#dateformat(BIRTH_DATE,"yyyy-mm-dd")#',
								'#dateformat(DEATH_DATE,"yyyy-mm-dd")#')
							</cfquery>
						</cfif>
				<!---		<cfquery name="NEXTID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							select sq_agent_name_id.nextval NEXTID from dual
						</cfquery>--->
						<cfif len(#OTHER_NAME_1#) gt 0>
							<cfquery name="newAgentName" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
								insert into agent_name (
								AGENT_NAME_ID,
								AGENT_ID,
								AGENT_NAME_TYPE,
								AGENT_NAME 
								)
								values (
								SQ_AGENT_NAME_ID.NEXTVAL,
								#savePK.agent_id#,
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#OTHER_NAME_TYPE_1#">,
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#OTHER_NAME_1#">
								)
							</cfquery>
						</cfif>
						<cfif len(#OTHER_NAME_2#) gt 0>
							<cfquery name="newAgentName" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
								insert into agent_name (
								AGENT_NAME_ID,
								AGENT_ID,
								AGENT_NAME_TYPE,
								AGENT_NAME 
								)
								values (
								SQ_AGENT_NAME_ID.NEXTVAL,
								#savePK.agent_id#,
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#OTHER_NAME_TYPE_2#">,
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#OTHER_NAME_2#">
								)
							</cfquery>
						</cfif>
						<cfif len(#OTHER_NAME_3#) gt 0>
							<cfquery name="newAgentName" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
								insert into agent_name (
								AGENT_NAME_ID,
								AGENT_ID,
								AGENT_NAME_TYPE,
								AGENT_NAME 
								)
								values (
								SQ_AGENT_NAME_ID.NEXTVAL,
								#savePK.agent_id#,
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#OTHER_NAME_TYPE_3#">,
								<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#OTHER_NAME_3#">
								)
							</cfquery>
						</cfif>
						<cfif pkResult.recordcount gt 1>
							<cfthrow message="Error: Attempting to insert a duplicate agent">
						</cfif>
						<cfset agent_updates = agent_updates + pkResult.recordcount>
					</cfloop>
					<p>Number of agents to add: #agent_updates# </p>
						<cfif getTempData.recordcount eq agent_updates and pkResult.recordcount eq 1>
							<h3 class="text-success">Success - loaded</h3>
						</cfif>
						<cfif pkResult.recordcount gt 1>
							<h3 class="text-danger">Not loaded - these have already been loaded</h3>
						</cfif>
						<cftransaction action="commit">
					<cfcatch>
						<cftransaction action="ROLLBACK">
						<h3>There was a problem updating the agents. </h3>
						<cfquery name="getProblemData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							SELECT to_char(birth_date,'YYYY-MM-DD') birth_date,agent_type,preferred_name,first_name,middle_name,last_name,to_char(death_date,'YYYY-MM-DD') death_date,agent_remark,prefix,suffix,other_name_1,other_name_type_1,other_name_2,other_name_type_2,other_name_3,other_name_type_3,agentguid_guid_type,agentguid
							FROM cf_temp_agents
							where key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#problem_key#">
						</cfquery>
						<cfif getProblemData.recordcount GT 0>
							<h3>
								Fix the issues and <a href="/tools/BulkloadAgents.cfm" class="text-danger font-weight-lessbold">start again</a>. Error loading row (<span class="text-danger">#agent_updates + 1#</span>) from the CSV: 
								<cfif len(cfcatch.detail) gt 0>
									<span class="font-weight-normal border-bottom border-danger">
										<cfif cfcatch.detail contains "birth_date">
											Problem with BIRTH_DATE
										<cfelseif cfcatch.detail contains "agent_type">
											Invalid or missing AGENT_TYPE
										<cfelseif cfcatch.detail contains "preferred_name">
											Invalid PREFERRED_NAME
										<cfelseif cfcatch.detail contains "first_name">
											Invalid FIRST_NAME
										<cfelseif cfcatch.detail contains "last_name">
											Problem with LAST_NAME
										<cfelseif cfcatch.detail contains "agentguid">
											Invalid AGENTGUID
										<cfelseif cfcatch.detail contains "agentguid_guid_type">
											Invalid AGENT GUID TYPE
										<cfelseif cfcatch.detail contains "agent_id">
											Problem with AGENT_ID
										<cfelseif cfcatch.detail contains "unique constraint">
											This agent has already been entered. Remove from spreadsheet and try again.
										<cfelseif cfcatch.detail contains "no data">
											No data or the wrong data (#cfcatch.detail#)
										<cfelse>
											<!--- provide the raw error message if it isn't readily interpretable --->
											#cfcatch.detail#
										</cfif>
									</span>
								</cfif>
							</h3>
							<table class='px-0 sortable small table table-responsive table-striped w-100 mt-3'>
								<thead>
									<tr>
										<th>COUNT</th>
										<th>BIRTH_DATE</th>
										<th>AGENT_TYPE</th>
										<th>PREFERRED_NAME</th>
										<th>FIRST_NAME</th>
										<th>MIDDLE_NAME</th>
										<th>LAST_NAME</th>
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
										<th>AGENTGUID_GUID_TYPE</th>
										<th>AGENTGUID</th>
									</tr> 
								</thead>
								<tbody>
									<cfset i=1>
									<cfloop query="getProblemData">
										<tr>
										<td>#i#</td>
											<td>#getProblemData.BIRTH_DATE# </td>
											<td>#getProblemData.AGENT_TYPE# </td>
											<td>#getProblemData.PREFERRED_NAME# </td>
											<td>#getProblemData.FIRST_NAME#</td>
											<td>#getProblemData.MIDDLE_NAME#</td>
											<td>#getProblemData.LAST_NAME#</td>
											<td>#getProblemData.DEATH_DATE#</td>
											<td>#getProblemData.AGENT_REMARK# </td>
											<td>#getProblemData.PREFIX# </td>
											<td>#getProblemData.SUFFIX#</td>
											<td>#getProblemData.OTHER_NAME_1#</td>
											<td>#getProblemData.OTHER_NAME_TYPE_1#</td>
											<td>#getProblemData.OTHER_NAME_2#</td>
											<td>#getProblemData.OTHER_NAME_TYPE_2#</td>
											<td>#getProblemData.OTHER_NAME_3#</td>
											<td>#getProblemData.OTHER_NAME_TYPE_3#</td>
											<td>#getProblemData.AGENTGUID_GUID_TYPE#</td>
											<td>#getProblemData.AGENTGUID#</td>
										</tr>
										<cfset i= i+1>
									</cfloop>
								</tbody>
							</table>
						</cfif>
						<div>#cfcatch.message#</div>
					</cfcatch>
				</cftry>
			</cftransaction>
			<cfquery name="clearTempTable" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="clearTempTable_result">
				DELETE FROM cf_temp_agents
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
		</cfoutput>
	</cfif>
</main>
