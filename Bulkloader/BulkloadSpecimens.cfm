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
			<cfoutput>
				<h1 class="h2">First step: Read data from CSV file into Staging.</h1>
				<cftry>
					<!--- remove existing staged data --->
					<cfquery name="killOld" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						delete from bulkloader_stage
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
					<cfloop from="1" to ="#ArrayLen(arrResult)#" index="row">
						<cfset colVals="">
						<cfloop from="1"  to ="#ArrayLen(arrResult[row])#" index="col">
							<cfset thisBit=trim(arrResult[row][col])>
							<cfif #row# is 1>
								<cfset colNames="#colNames#,#thisBit#">
							<cfelse>
								<cfset colVals="#colVals#,'#thisBit#'">
								<cfset ArrayAppend(rowArray,thisBit)>
							</cfif>
						</cfloop>
						<cfif #row# is 1>
							<cfset colNames=replace(colNames,",","","first")>
							<cfset colNameArray = listToArray(ucase(colNames))><!--- the list of columns/fields found in the input file --->
							<h3 class="h4">Found #arrayLen(colNameArray)# columns in header of csv file.</h3>
							<ul class="list-group list-group-horizontal flex-wrap">
								<cfloop list="#colNames#" index="colName">
									<li class="list-group-item float-left">#colName#</li>
								</cfloop>
							</ul>
						</cfif>
						<cfif len(#colVals#) gt 1>
							<cftry>
								<cfset colVals=replace(colVals,",","","first")>
								<cfquery name="insert" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="insert_result">
									insert into bulkloader_stage (#colNames#) values (#preservesinglequotes(colVals)#)
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
								<cfthrow message="Error inserting data from line #row# in input file. <div>Error: #cfcatch.message#</div><div>#cause#</div><div>Row:[#badRow#]</div> "><!--- " --->
							</cfcatch>
							</cftry>
						</cfif>
					</cfloop>
					<h3 class="h3">
						Successfully loaded #loadedRows# records from the CSV file into the staging table.  
						Next <a href="/Bulkloaders/BulkloadSpecimens.cfm?action=validate" target="_self">click to validate or load</a>.
					</h3>
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
				<cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select count(*) as cnt from bulkloader_stage
				</cfquery>
				<h1 class="h2">Second step: Check and Load or Load from staging table.</h1>
    			<div>
					You successfully loaded #c.cnt# records into the <em><strong>staging</strong></em> table.
					They have not been checked or processed yet. You aren&apos;t done here!  Next: 
				</div>

				<ul class="">
					<li>
						<a href="BulkloadSpecimens.cfm?action=checkStaged" target="_self">Check and load these records</a>.
						If no errors are found, the data will be moved from Staging to the Bulkloader.  If errors are found, 
						you can download the staged data with error messages, fix the errors, and reload your data.  
						This may be a slow iterative process, but following it will allow you to fix problems in the data with
						whatever tools you desire in your csv file and then re-load your data until no errors are found.  
						Email a DBA if you wish to check your records at this stage but the process times out. We can schedule
						the process, allowing it to take as long as necessary to complete, and notify you when it&apos;s done.
						This method is strongly preferred.
					</li>
					<li>
						<a href="BulkloadSpecimens.cfm?action=loadAnyway" target="_self">Just load these records</a>.
						Use this method if you wish to use MCZbase&apos;s tools to fix any errors. Everything will go to the normal
						Bulkloader tables and be available via <a href="/Bulkloader/browseBulk.cfm">the Browse Bulk app</a>.
						Once in the bulkloader, records need to have problems fixed with the bulkloader tools, you can&apos;t easily
						remove records from the bulkloader and upload an externally cleaned spreadsheet as you can with Staging.
						You need a thorough understanding of MCZbase&apos;s bulkloader tools and great confidence in your data
						to use this application.  Misuse, particularly of the bulk update tool, can result in 
						a mess in the Bulkloader, which may require sorting out record by record in the bulkloader.
					</li>
				</ul>
			</cfoutput>
		</cfcase>
		<!------------------------------------------------------->
		<cfcase value="loadAnyway">
			<cfoutput>
				<cftransaction>
					<cfquery name="allId" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select collection_object_id from bulkloader_stage
					</cfquery>
					<cfloop query="allId">
						<cfquery name="newID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							update bulkloader_stage set collection_object_id=bulkloader_pkey.nextval
							where collection_object_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
						</cfquery>
					</cfloop>
					<cfquery name="flag" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						update bulkloader_stage set loaded = 'BULKLOADED RECORD'
					</cfquery>
					<cfquery name="moveEm" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						insert into bulkloader select * from bulkloader_stage
					</cfquery>
				</cftransaction>
				<h1 class="h2">Loaded #allId.recordcount# records from Staging to Bulkloader.</h1>
	  			<div>
					Your records have been checked and are now in table Bulkloader and flagged as
					loaded='BULKLOADED RECORD'.  You can un-flag and load them.
					You can access these records in the Bulkloader with <a href="/Bulkloader/browseBulk.cfm">Browse and Edit</a>.
				</div>
			</cfoutput>
		</cfcase>
		<!------------------------------------------->
		<cfcase value="checkStaged">
			<cfoutput>
				<cfstoredproc datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" procedure="bulkloader_stage_check">
				</cfstoredproc>
				<cfquery name="anyBads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select count(*) as cnt from bulkloader_stage
					where loaded is not null
				</cfquery>
				<cfquery name="allData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select count(*) as cnt from bulkloader_stage
				</cfquery>
				<cfif #anyBads.cnt# gt 0>
					<cfinclude template="getBulkloaderStageRecs.cfm">
					<h1 class="h2">Problems Found Checking Staged Records.  Reload Recommended.</h1>
					<h2 class="h3">#anyBads.cnt# of #allData.cnt# records will not successfully load into MCZbase.</h2>
					<div>
						Click <a href="bulkloader.txt" target="_blank">here</a>
						to retrieve all data including error messages. Fix them up and then <a href="/Bulkloader/BulkloadSpecimens.cfm">reload</a> them.
						This method is strongly preferred.
					</div>
					<div>
						Click <a href="bulkloaderLoader.cfm?action=loadAnyway">here</a> to load them to the
						bulkloader anyway. Use The Bulkloader Browse and Edit tools to fix them up and load them.
					</div>
				<cfelse>
					<cftransaction>
						<cfquery name="allId" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							select collection_object_id from bulkloader_stage
						</cfquery>
						<cfloop query="allId">
							<cfquery name="newID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
								UPDATE bulkloader_stage 
								SET collection_object_id=bulkloader_pkey.nextval
								WHERE collection_object_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
							</cfquery>
						</cfloop>
						<cfquery name="flag" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							update bulkloader_stage set loaded = 'BULKLOADED RECORD'
						</cfquery>
						<cfquery name="moveEm" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							insert into bulkloader select * from bulkloader_stage
						</cfquery>
						<h1 class="h2">No Problems Found Checking Staged Records, loaded to Bulkloader</h1>
						<div>
							Your records have been checked and are now in table Bulkloader and flagged as
							loaded='BULKLOADED RECORD'.  You can un-flag and load them.
							You can access these records in the Bulkloader with <a href="/Bulkloader/browseBulk.cfm">Browse and Edit</a>.
						</div>
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
