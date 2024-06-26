<!--- special case handling to dump problem data as csv --->
<cfif isDefined("action") AND action is "dumpProblems">
	<cfquery name="getColumnsNoUser" datasource="uam_god">
		SELECT column_name
		FROM all_tab_columns
		WHERE table_name='BULKLOADER_STAGE' AND owner='MCZBASE' 
			and column_name <> 'STAGING_USER'
		ORDER BY column_id
	</cfquery>
	<cfset columns = "">
	<cfloop query="getColumnsNoUser">
		<cfset columns=ListAppend(columns,getColumnsNoUser.column_name)>
	</cfloop>
	<cfquery name="getProblemData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		SELECT #columns#
		FROM bulkloader_stage
		WHERE staging_user = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
	</cfquery>
	<cfinclude template="/shared/component/functions.cfc">
	<cfset csv = queryToCSV(getProblemData)>
	<cfset timestamp = "#dateformat(now(),'yyyymmdd')#_#TimeFormat(Now(),'HHnnss')#">
	<cfset filename = "StagedData_#session.username#_#timestamp#.csv">
	<cfheader name="Content-Type" value="text/csv">
	<cfheader name="Content-Disposition" value="attachment; filename=#filename#">
	<cfoutput>#csv#</cfoutput>
	<cfabort>
</cfif>
<!--- end special case dump of problems --->
<!--- special case handling to dump unique problems as csv --->
<cfif isDefined("action") AND action is "dumpUniqueProblems">
	<cfset crlf = chr(13) & chr(10) >
	<cfquery name="getColumnsNoUser" datasource="uam_god">
		SELECT column_name
		FROM all_tab_columns
		WHERE table_name='BULKLOADER_STAGE' AND owner='MCZBASE' 
			and column_name <> 'STAGING_USER'
		ORDER BY column_id
	</cfquery>
	<cfset columns = "">
	<cfloop query="getColumnsNoUser">
		<cfset columns=ListAppend(columns,getColumnsNoUser.column_name)>
	</cfloop>
	<cfquery name="getLoadedValues" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		SELECT distinct loaded 
		FROM bulkloader_stage
		WHERE staging_user = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			AND loaded is not null
	</cfquery>
	<cfset loadedArray = ArrayNew(1)>
	<cfloop query="getLoadedValues">
		<cfset loadedList = getLoadedValues.loaded>
		<cfloop list="#loadedList#" index="loadedItem" delimiters=";">
			<cfif len(loadedItem) GT 0>
				<cfif NOT ArrayContains(loadedArray,loadedItem)>
					<cfset ArrayAppend(loadedArray,loadedItem)>
				</cfif>
			</cfif>
		</cfloop>
	</cfloop>
	<cfset csv ='"ERROR","COLUMN","VALUE","ROWS"'>
	<cfloop index="i" from="1" to="#ArrayLen(loadedArray)#">
		<!--- identify the error column, for that error condition, find distinct values of the column with the error, report those --->
		<cfquery name="getErrorRows" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			SELECT collection_object_id
			FROM bulkloader_stage
			WHERE staging_user = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				AND loaded like '%#loadedArray[i]#%'
		</cfquery>
		<cfset rows ="">
		<cfset separator="">
		<cfloop query="getErrorRows">
			<cfset rows = "#rows##separator##getErrorRows.collection_object_id#">
			<cfset separator=",">
		</cfloop>
		<cfset errorCase = loadedArray[i]>
		<cfset errorCase = Trim(Replace(errorCase,'"','""','All'))>
		<cfset columnInError = "">
		<cfif FindNoCase('geog_auth_rec matched 0 records',errorCase) GT 0>
			<cfset columnInError = "HIGHER_GEOG">
		<cfelseif FindNoCase('Taxonomy (',errorCase) GT 0>
			<cfset columnInError = "TAXON_NAME">
		<cfelse>
			<cfloop list="#columns#" index="col">
				<cfif FindNoCase(col,errorCase) GT 0>
					<cfset columnInError = col>
				</cfif>
			</cfloop>
		</cfif>
		<cfif columnInError NEQ "">
			<!--- TODO: Identify rows with the value_error --->
			<cfquery name="getErrorCases" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT distinct #columnInError# value_error
				FROM bulkloader_stage
				WHERE staging_user = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
					AND loaded like '%#errorCase#%'
			</cfquery>
			<cfloop query="getErrorCases">
				<cfquery name="getErrorCaseRows" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT collection_object_id
					FROM bulkloader_stage
					WHERE staging_user = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						AND loaded like '%#loadedArray[i]#%'
						AND #columnInError# = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getErrorCases.value_error#">
				</cfquery>
				<cfset caseRows ="">
				<cfset separator1="">
				<cfloop query="getErrorCaseRows">
					<cfset caseRows = "#caseRows##separator1##getErrorCaseRows.collection_object_id#">
					<cfset separator1=",">
				</cfloop>
				<cfset valError = Replace(getErrorCases.value_error,'"','""','All')>
				<cfset csv = '#csv##crlf#"#errorCase#","#columnInError#","#valError#","#caseRows#"'>
			</cfloop>
		<cfelse>
			<cfset csv = '#csv##crlf#"#errorCase#","","","#rows#"'>
		</cfif>
	</cfloop>
	<cfset timestamp = "#dateformat(now(),'yyyymmdd')#_#TimeFormat(Now(),'HHnnss')#">
	<cfset filename = "StagedDataProblems_#session.username#_#timestamp#.csv">
	<cfheader name="Content-Type" value="text/csv">
	<cfheader name="Content-Disposition" value="attachment; filename=#filename#">
	<cfoutput>#csv#</cfoutput>
	<cfabort>
</cfif>

<!--- end special case dump of unique problems --->

<cfset pageTitle="Bulkload Specimens">
<cfinclude template="/shared/_header.cfm">

<cfif not isDefined("action")>
	<cfset action="entryPoint">
</cfif>

<main class="container py-3" id="content">
	<cfswitch expression="#action#">
		<cfcase value="entryPoint">
			<h1 class="h2">Bulkload specimen records from a .csv file.</h1>
			<label for="fileToUpload">Upload a comma-delimited text file (csv).</label>
			<p>
				You can upload up to about 1000 specimen records at once from a CSV file into the Bulkloader from here.  You must correctly identify the character set for your file, 
				otherwise any accented or other extended characters will be loaded incorrectly.
				You can build template CSV files using the <a href="/Bulkloader/bulkloaderBuilder.cfm">Bulkloader Builder</a>.
				Alternatively, use one of the templates from the MCZbase Wiki <a href="https://code.mcz.harvard.edu/wiki/index.php/Bulkloader_Templates">Bulkloader Templates Page</a>.
				Additional documentation can be found on the <a href="https://code.mcz.harvard.edu/wiki/index.php/Bulk_Upload_a_Spreadsheet_with_multiple_specimen_records">MCZbase Wiki</a>
			</p>
			<cfform name="fileUploadForm" method="post" enctype="multipart/form-data">
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
				<input type="submit" value="Upload this file" class="savBtn">
			</cfform>
		</cfcase>
		<!------------------------------------------------------->
		<cfcase value="getFile">
			<!--- find the fields present in the bulkloader_stage table, column header must match --->
			<cfset fieldList = "">
			<cfset fieldTypes = "">
			<cfset fieldLengths = "">
			<cfquery name="getColumns" datasource="uam_god">
				SELECT column_name, data_type, data_length 
				FROM all_tab_columns
				WHERE table_name='BULKLOADER_STAGE' AND owner='MCZBASE' 
				ORDER BY column_id
			</cfquery>
			<cfloop query="getColumns">
				<cfset fieldList = ListAppend(fieldList,"#getColumns.column_name#")>
				<cfset fieldTypes = ListAppend(fieldList,"#getColumns.data_type#")>
				<cfset fieldLengths = ListAppend(fieldList,"#getColumns.data_length#")>
			</cfloop>
			<cfoutput>
				<h1 class="h2">First step: Read data from CSV file into Staging.</h1>
				<cftry>
					<!--- remove existing staged data --->
					<cfquery name="killOld" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						DELETE FROM bulkloader_stage
						WHERE staging_user = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
					</cfquery>
					<!--- read file --->
					<cffile action="READ" file="#FiletoUpload#" variable="fileContent" charset="#cSet#">
					<cfset fileContent=replace(fileContent,"'","''","all")>
					<cfset arrResult = CSVToArray(CSV = fileContent.Trim()) />
					<!--- TODO: Check required fields --->
					<cfloop from="1" to ="#ArrayLen(arrResult[1])#" index="col">
						<cfset header = arrResult[1][col]>
						<!--- TODO: check --->
					</cfloop>
					<!--- load --->
					<cfset loadedRows = 0>
					<cfset colNames="">
					<cfset rowArray=ArrayNew(1)>
					<cfset foundHighCount = 0>
					<cfset foundHighAscii = "">
					<cfset foundMultiByte = "">
					<cfloop from="1" to ="#ArrayLen(arrResult)#" index="row">
						<cfset colVals="">
						<cfloop from="1"  to ="#ArrayLen(arrResult[row])#" index="col">
							<cfset thisBit=trim(arrResult[row][col])>
							<cfif #row# is 1>
								<cfset colNames="#colNames#,#thisBit#">
							<cfelse>
								<cfset colVals="#colVals#,'#thisBit#'">
								<cfset ArrayAppend(rowArray,thisBit)>
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
							</cfif>
						</cfloop>
						<cfif #row# is 1>
							<cfset colNames=replace(colNames,",","","first")>
							<cfset colNameArray = listToArray(ucase(colNames))><!--- the list of columns/fields found in the input file --->
							<h3 class="h4">Found #arrayLen(colNameArray)# columns in header of csv file.</h3>
							<cfset error="">
							<ul class="list-group list-group-horizontal flex-wrap">
								<cfloop list="#colNames#" index="colName">
									<cfif REFind("[^0-9A-Z_]",trim(ucase(colName))) GT 0>
										<cfset error = "#error# Column [#colName#] contains a space or other incorrect character.">
										<li class="list-group-item float-left"><strong class="text-danger">#colName#</strong></li>
									<cfelseif NOT ListContains(fieldList,ucase(colName))>
										<cfset error = "#error# Column [#colName#] unknown.">
										<li class="list-group-item float-left"><strong class="text-danger">#colName#</strong></li>
									<cfelse>
										<li class="list-group-item float-left">#colName#</li>
									</cfif>
								</cfloop>
							</ul>
							<cfif error NEQ "">
								<h3 class="h4">Error(s) in the header row: #error#</h3>
							</cfif>
						</cfif>
						<cfif len(#colVals#) gt 1>
							<cftry>
								<cfset colVals=replace(colVals,",","","first")>
								<cfquery name="insert" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="insert_result">
									insert into bulkloader_stage (#colNames#,STAGING_USER) values (#preservesinglequotes(colVals)#,'#session.username#')
								</cfquery>
								<cfset loadedRows = loadedRows + insert_result.recordcount>
							<cfcatch>
								<cfset cause="">
								<cfif isDefined("cfcatch.cause")><cfset cause="Cause: #cfcatch.cause#"></cfif>
								<cfif find("unique constraint (MCZBASE.PK_BULKSTAGEID) violated",cause) GT 0>
									<cfset cause = "Duplicate COLLECTION_OBJECT_ID value.  Each row must have a unique value for collection_object_id. (unique constraint (MCZBASE.PK_BULKSTAGEID) violated).">
								</cfif>
								<cfset badRow = "">
								<cfset separator="">
								<cfloop index="i" from="1" to="#ArrayLen(colNameArray)#">
									<cfif find(colNameArray[i],cause) GT 0>
										<cfset badRow = "#badRow##separator#<strong>#colNameArray[i]#:#rowArray[i]#</strong>"><!--- " --->
									<cfelse>
										<cfset badRow = "#badRow##separator##colNameArray[i]#:#rowArray[i]#">
									</cfif>
									<cfset separator=", ">
								</cfloop>
								<cfthrow message="Error inserting data from <strong>line #row#</strong> in input file. <div>Error: #cfcatch.message#</div><div class='mb-2'>#cause#</div><div>Row:[#badRow#]</div> "><!--- " --->
							</cfcatch>
							</cftry>
						</cfif>
					</cfloop>
					<cfif foundHighCount GT 0>
						<h3 class="h3">Found characters where the encoding is probably important in the input data.</h3>
						<div>
							Showing #foundHighCount# examples.  If these do not appear as the correct characters, the file likely has a different encoding from the one you selected and
							you probably want to <a href="/Bulkloader/BulkloadSpecimens.cfm">reload this file</a> selecting a different encoding.  If these appear as expected, then 
							you selected the correct encoding and can continue to validate or load.
						</div>
						<ul class="py-1" style="font-size: 1.2rem;">
							#foundHighAscii#
							#foundMultiByte#
						</ul>
					</cfif>
					<cfif loadedRows GT 0>
						<h3 class="h3">
							Successfully loaded #loadedRows# records from the CSV file into the staging table.  
							Next <a href="/Bulkloader/BulkloadSpecimens.cfm?action=validate" target="_self">click to validate or load</a>.
						</h3>
					<cfelse>
						<h3 class="h3">
							Found #loadedRows# records from the CSV file to load into the staging table.  
							Examine your file and <a href="/Bulkloader/BulkloadSpecimens.cfm" target="_self">try again</a>.
						</h3>
					</cfif>
				<cfcatch>
					<h3 class="h3">Error: Failed to load data from the CSV file.</h3>
					<div>#cfcatch.message#</div>
					<h3 class="h3">Resolve the issue in your CSV file and <a href="/Bulkloader/BulkloadSpecimens.cfm">Upload Again</a>.</h3>
					<cfif isdefined("session.roles") AND listfindnocase(session.roles,"global_admin") AND isDefined("debug")>
						<cfdump var="#cfcatch#">
					</cfif>
				</cfcatch>
				</cftry>
			</cfoutput>
		</cfcase>
		<!------------------------------------------------------->
		<cfcase value="validate">
			<cfoutput>
				<cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT count(*) as cnt 
					FROM bulkloader_stage
					WHERE staging_user = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<h1 class="h2">Second step: Check and Load or Load from staging table.</h1>
    			<div>
					You successfully loaded #c.cnt# records into the <em><strong>staging</strong></em> table.
					They have not been checked or processed yet. You aren&apos;t done here!  Next: 
				</div>

				<div>
					<a href="BulkloadSpecimens.cfm?action=checkStaged" target="_self">Check and load these records</a>.
					If no errors are found, the data will be moved from Staging to the Bulkloader.  If errors are found, 
					you can download the staged data with error messages, fix the errors, and reload your data.  
					This may be a slow iterative process, but following it will allow you to fix problems in the data with
					whatever tools you desire in your csv file and then re-load your data until no errors are found.  
					Email a DBA if you wish to check your records at this stage but the process times out. We can schedule
					the process, allowing it to take as long as necessary to complete, and notify you when it&apos;s done.
					This method is strongly preferred.
				</div>
				<div><strong>Or</strong></div>
				<div>
					<a href="BulkloadSpecimens.cfm?action=loadAnyway" target="_self">Just load these records</a>.
					Use this method if you wish to use MCZbase&apos;s tools to fix any errors. Everything will go to the normal
					Bulkloader tables and be available via <a href="/Bulkloader/browseBulk.cfm">the Browse Bulk app</a>.
					Once in the bulkloader, records need to have problems fixed with the bulkloader tools, you can&apos;t easily
					remove records from the bulkloader and upload an externally cleaned spreadsheet as you can with Staging.
					You need a thorough understanding of MCZbase&apos;s bulkloader tools and great confidence in your data
					to use this application.  Misuse, particularly of the bulk update tool, can result in 
					a mess in the Bulkloader, which may require sorting out record by record in the bulkloader.
				</div>
			</cfoutput>
		</cfcase>
		<!------------------------------------------------------->
		<cfcase value="loadAnyway">
			<cfoutput>
				<cfquery name="getColumnsNoUser" datasource="uam_god">
					SELECT column_name
					FROM all_tab_columns
					WHERE table_name='BULKLOADER_STAGE' AND owner='MCZBASE' 
						and column_name <> 'STAGING_USER'
					ORDER BY column_id
				</cfquery>
				<cfset columns = "">
				<cfloop query="getColumnsNoUser">
					<cfset columns=ListAppend(columns,getColumnsNoUser.column_name)>
				</cfloop>
				<cfset movedCount = 0>
				<cftransaction>
					<cftry>
						<cfquery name="stagedToMove" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							SELECT collection_object_id 
							FROM bulkloader_stage
							WHERE staging_user = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						</cfquery>
						<cfset toMoveCount = stagedToMove.recordcount>
						<cfloop query="stagedToMove">
							<cfquery name="newID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
								UPDATE bulkloader_stage 
								SET collection_object_id=bulkloader_pkey.nextval
								WHERE collection_object_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
									AND staging_user = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
							</cfquery>
						</cfloop>
						<cfquery name="flag" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							UPDATE bulkloader_stage 
							SET loaded = 'BULKLOADED RECORD'
							WHERE staging_user = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						</cfquery>
						<cfquery name="toMove" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							SELECT collection_object_id 
							FROM bulkloader_stage
							WHERE staging_user = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						</cfquery>
						<!--- we could insert with a query on just staging_user, but that multi-row insert returns a count of 1 affected record, 
							so to check for success, need to move one record at a time --->
						<cfset movedCount = 0>
						<cfloop query="toMove">
							<cfquery name="moveRow" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="moveRow_result">
								INSERT into bulkloader (#columns#)
									SELECT #columns# from bulkloader_stage
									WHERE staging_user = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
									AND collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#toMove.collection_object_id#">
							</cfquery>
							<cfset movedCount=movedCount+moveRow_result.recordcount>
						</cfloop>
						<cfif movedCount EQ toMoveCount>
							<cfquery name="cleanUp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="cleanUp_result">
								DELETE from bulkloader_stage 
								WHERE staging_user = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
							</cfquery>
							<cftransaction action="commit">
							<h1 class="h2">Loaded #movedCount# records from Staging to Bulkloader.</h1>
	  						<div>
								Your records have been checked and are now in table Bulkloader and flagged as
								loaded='BULKLOADED RECORD'.  You can un-flag and load them.
								You can access these records in the Bulkloader with <a href="/Bulkloader/browseBulk.cfm">Browse and Edit</a>.
							</div>
						<cfelse>
							<cftransaction action="rollback">
							<cfthrow message="Attempted to move #toMoveCount# records, but moved #movedCount#, so rolled back.">
						</cfif>
					<cfcatch>
						<h1 class="h2">Error moving records from Staging to Bulkloader.</h1>
						<div>#cfcatch.message#</div>
						<cfdump var="#cfcatch#">
					</cfcatch>
					</cftry>
				</cftransaction>
			</cfoutput>
		</cfcase>
		<!------------------------------------------->
		<cfcase value="checkStaged">
			<cfoutput>
				<cfstoredproc datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" procedure="bulkloader_stage_check">
					<cfprocparam cfsqltype="CF_SQL_VARCHAR" value="#session.dbuser#">
				</cfstoredproc>
				<cfquery name="anyBads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT count(*) as cnt 
					FROM bulkloader_stage
					WHERE loaded is not null
						AND staging_user = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cfquery name="allData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT count(*) as cnt 
					FROM bulkloader_stage
					WHERE staging_user = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cfif #anyBads.cnt# gt 0>
					<cfinclude template="getBulkloaderStageRecs.cfm">
					<h1 class="h2">Problems Found Checking Staged Records.  Reload Recommended.</h1>
					<h2 class="h3">#anyBads.cnt# of #allData.cnt# records will not successfully load into MCZbase.</h2>
					<div>
						Download your data with error messages added as a <a href="/Bulkloader/bulkloader.txt" target="_blank">tab delimited</a> 
						or <a href="/Bulkloader/BulkloadSpecimens.cfm?action=dumpProblems">CSV</a> file. 
						You may also download a <a href="/Bulkloader/BulkloadSpecimens.cfm?action=dumpUniqueProblems">CSV file of distinct problems</a> found in the data. 
						Fix issues in the data and then <a href="/Bulkloader/BulkloadSpecimens.cfm">reload</a>.
						This method is strongly preferred.
					</div>
					<div><strong>Or</strong></div>
					<div>
						Click <a href="/Bulkloader/BulkloadSpecimens.cfm?action=loadAnyway">here</a> to load them to the
						bulkloader anyway. Use The Bulkloader Browse and Edit tools to fix issues and load them.
					</div>
					<cfquery name="listErrors" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						SELECT count(*) ct, loaded 
						FROM bulkloader_stage
						WHERE loaded is not null
							AND staging_user = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						GROUP BY loaded
						ORDER BY count(*) desc
					</cfquery>
					<cfset maxErrors = 30>
					<cfif listErrors.recordCount GT maxErrors>
						<h2 class="h3">Top 30 problems</h2>
					<cfelse>
						<h2 class="h3">Problems in the data</h2>
					</cfif>
					<ul>
						<cfloop query="listErrors" endRow="#maxErrors#">
							<li>#listErrors.loaded# (#listErrors.ct#)</li>
						</cfloop>				
					</ul>
				<cfelse>
					<cfquery name="getColumnsNoUser" datasource="uam_god">
						SELECT column_name
						FROM all_tab_columns
						WHERE table_name='BULKLOADER_STAGE' AND owner='MCZBASE' 
							and column_name <> 'STAGING_USER'
						ORDER BY column_id
					</cfquery>
					<cfset columns = "">
					<cfloop query="getColumnsNoUser">
						<cfset columns=ListAppend(columns,getColumnsNoUser.column_name)>
					</cfloop>
					<cfset movedCount = 0>
					<cftransaction>
						<cftry>
							<cfquery name="stagedToMove" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
								SELECT collection_object_id 
								FROM bulkloader_stage
								WHERE staging_user = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
							</cfquery>
							<cfset toMoveCount = stagedToMove.recordcount>
							<cfloop query="stagedToMove">
								<cfquery name="newID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									UPDATE bulkloader_stage 
									SET collection_object_id=bulkloader_pkey.nextval
									WHERE collection_object_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
										AND staging_user = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
								</cfquery>
							</cfloop>
							<cfquery name="flag" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
								UPDATE bulkloader_stage 
								SET loaded = 'BULKLOADED RECORD'
								WHERE staging_user = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
							</cfquery>
							<cfquery name="toMove" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
								SELECT collection_object_id 
								FROM bulkloader_stage
								WHERE staging_user = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
							</cfquery>
							<!--- we could insert with a query on just staging_user, but that multi-row insert returns a count of 1 affected record, 
								so to check for success, need to move one record at a time --->
							<cfset movedCount = 0>
							<cfloop query="toMove">
								<cfquery name="moveRow" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="moveRow_result">
									INSERT into bulkloader (#columns#)
										SELECT #columns# from bulkloader_stage
										WHERE staging_user = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
										AND collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#toMove.collection_object_id#">
								</cfquery>
								<cfset movedCount=movedCount+moveRow_result.recordcount>
							</cfloop>
							<cfif movedCount EQ toMoveCount>
								<cfquery name="cleanUp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="cleanUp_result">
									DELETE from bulkloader_stage 
									WHERE staging_user = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
								</cfquery>
								<cftransaction action="commit">
								<h1 class="h2">No Problems Found Checking Staged Records, loaded all #movedCount# to Bulkloader</h1>
								<div>
									Your records have been checked and are now in table Bulkloader and flagged as
									loaded='BULKLOADED RECORD'.  You can un-flag and load them.
									You can access these records in the Bulkloader with <a href="/Bulkloader/browseBulk.cfm">Browse and Edit</a>.
								</div>
							<cfelse>
								<cftransaction action="rollback">
								<cfthrow message="Attempted to move #toMoveCount# records, but moved #movedCount#, so rolled back.">
							</cfif>
						<cfcatch>
							<h1 class="h2">Error moving records from Staging to Bulkloader.</h1>
							<div>#cfcatch.message#</div>
							<cfdump var="#cfcatch#">
						</cfcatch>
						</cftry>
					</cftransaction>
				</cfif>
			</cfoutput>
		</cfcase>
		<cfdefaultcase>
			<cfthrow message="Error: unknown action [#encodeForHtml(action)#]">
		</cfdefaultcase>
	</cfswitch>
</main>

<cfinclude template="/shared/_footer.cfm">
