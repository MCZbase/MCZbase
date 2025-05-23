<!--- tools/bulkloadMedia.cfm add media in bulk.

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

<!--- page can submit with action either as a form post parameter or as a url parameter, obtain either into variable scope. --->
<cfif isDefined("url.action")><cfset variables.action = url.action></cfif>
<cfif isDefined("form.action")><cfset variables.action = form.action></cfif>

<!--- increase timout to three minutes --->
<cfsetting requestTimeOut = "180" />

<!--- Set configuration for lists of fields --->  
<cfset NUMBER_OF_LABEL_VALUE_PAIRS = 8>
<cfset NUMBER_OF_RELATIONSHIP_PAIRS = 4>
<cfset fieldlist = "MEDIA_URI,MIME_TYPE,MEDIA_TYPE,SUBJECT,MADE_DATE,DESCRIPTION,PREVIEW_URI,MEDIA_LICENSE_ID,MASK_MEDIA">
<cfloop from="1" to="#NUMBER_OF_RELATIONSHIP_PAIRS#" index="i">
	<cfset fieldlist = "#fieldlist#,MEDIA_RELATIONSHIP_#i#,MEDIA_RELATED_TO_#i#">
</cfloop>
<cfloop from="1" to="#NUMBER_OF_LABEL_VALUE_PAIRS#" index="i">
	<cfset fieldlist = "#fieldlist#,MEDIA_LABEL_#i#,LABEL_VALUE_#i#">
</cfloop>
<cfset fieldTypes ="CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_DATE,CF_SQL_VARCHAR,CF_SQL_VARCHAR,CF_SQL_DECIMAL,CF_SQL_DECIMAL">
<cfloop from="1" to="#NUMBER_OF_RELATIONSHIP_PAIRS#" index="i">
	<cfset fieldTypes = "#fieldTypes#,CF_SQL_VARCHAR,CF_SQL_VARCHAR">
</cfloop>
<cfloop from="1" to="#NUMBER_OF_LABEL_VALUE_PAIRS#" index="i">
	<cfset fieldTypes = "#fieldTypes#,CF_SQL_VARCHAR,CF_SQL_VARCHAR">
</cfloop>
<cfset requiredfieldlist = "MEDIA_URI,MIME_TYPE,MEDIA_TYPE,SUBJECT,MADE_DATE,DESCRIPTION">

<!--- special case handling to dump problem data as csv --->

<cfif isDefined("variables.action") AND variables.action is "dumpProblems">
	<cfset separator = "">
	<cfquery name="getProblemData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		SELECT 
			REGEXP_REPLACE( status, '\s*</?\w+((\s+\w+(\s*=\s*(".*?"|''.*?''|[^''">\s]+))?)+\s*|\s*)/?>\s*', NULL, 1, 0, 'im') AS STATUS, 
			MEDIA_URI,MIME_TYPE,MEDIA_TYPE,PREVIEW_URI,SUBJECT,MADE_DATE,DESCRIPTION,MEDIA_LICENSE_ID,MASK_MEDIA,
			<cfloop from="1" to="#NUMBER_OF_RELATIONSHIP_PAIRS#" index="rpi">
				MEDIA_RELATIONSHIP_#rpi#,MEDIA_RELATED_TO_#rpi#,
			</cfloop>
			<cfloop from="1" to="#NUMBER_OF_LABEL_VALUE_PAIRS#" index="lpi">
				#separator#MEDIA_LABEL_#lpi#,LABEL_VALUE_#lpi#
				<cfset separator = ",">
			</cfloop>
		FROM cf_temp_media 
		WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
		ORDER BY key
	</cfquery>
	<cfinclude template="/shared/component/functions.cfc">
	<cfset csv = queryToCSV(getProblemData)>
	<cfheader name="Content-Type" value="text/csv">
	<cfoutput>#csv#</cfoutput>
	<cfabort>
</cfif>
<!--- end special case dump of problems --->

		
<!--- special case handling to dump column headers as csv --->
<cfif isDefined("variables.action") AND variables.action is "getCSVHeader">
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

<!--- special case handling to produce bulkloader sheet for files without media records in a directory --->
<cfif isDefined("variables.action") AND variables.action is "getFileList">
	<cfif NOT isDefined("url.path") or len(url.path) EQ 0>
		<cfthrow message="Missing required parameter path.">
	</cfif>
	<cfif NOT DirectoryExists("#Application.webDirectory#/specimen_images/#url.path#")>
		<cfthrow message="Error: Directory not found.">
	</cfif>
	<cfset csv = "">
	<cfset separator = "">
	<cfloop list="#fieldlist#" index="field" delimiters=",">
		<cfset csv='#csv##separator#"#field#"'>
		<cfset separator = ",">
	</cfloop>
	<cfheader name="Content-Type" value="text/csv">
	<cfoutput>#csv##chr(13)##chr(10)#</cfoutput>
	<cfquery name="knownMedia" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		SELECT 
			auto_path, auto_filename
		FROM
			media
		WHERE
			auto_path = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="/specimen_images/#url.path#/">
	</cfquery>
	<cfset knownFiles = ValueList(knownMedia.auto_filename)>
	<cfset allFiles = DirectoryList("#Application.webDirectory#/specimen_images/#url.path#",false,"query","","datelastmodified DESC","file")>
	<!--- DirectoryList as query returns: Attributes, DateLastModified, Directory, Link, Mode, Name, Size, Type --->
	<cfset numberUnknown = 0>
	<cfloop query="allFiles">
		<cfset csv = "">
		<cfif NOT ListContains(knownFiles,allFiles.Name)>
			<cfset localPath = Replace(allFiles.Directory,'#Application.webDirectory#','')>
			<cfset mimetype = FileGetMimeType("#allFiles.Directory#/#allFiles.Name#")>
			<cfset media_type = "">
			<cfif FindNoCase('image',mimetype) GT 0><cfset media_type="image"></cfif>
			<cfif FindNoCase('audio',mimetype) GT 0><cfset media_type="audio"></cfif>
			<cfif FindNoCase('video',mimetype) GT 0><cfset media_type="video"></cfif>
			<cfset madedate = "">
			<cftry>
				<cfif mimetype EQ "image/jpeg">
					<cfset targetFileName = "#allFiles.Directory#/#allFiles.Name#" >
					<cfimage source="#targetFileName#" name="image">
					<cfset madedate = ImageGetEXIFTag(image,'Date/Time') >
					<cfif Find(":",madedate) GT 0>
						<cfset madedate = replace(left(madedate,10),":","-","all")>
					</cfif>
				</cfif>
			<cfcatch>
				<!--- just consume any exception --->
			</cfcatch>
			</cftry>
			<cfif NOT isDefined("madedate")><cfset madedate = ""></cfif>  
			<cfset csv = csv & '"https://mczbase.mcz.harvard.edu#localPath#/#allFiles.Name#","#mimetype#","#media_type#","","#madedate#"'>
			<cfset fields = ',"","","","","","","","","","","","","","","","","","","","","","","","","","","",""'>
			<cfset csv = csv & fields>
			<cfoutput>#csv##chr(13)##chr(10)#</cfoutput>
		</cfif>
	</cfloop>
	<cfabort>
</cfif>

<!--- begin normal page delivery --->
<cfset pageTitle = "BulkloadMedia">
<cfinclude template="/shared/_header.cfm">
<cfinclude template="/tools/component/csv.cfc" runOnce="true"><!--- for common csv testing functions --->
<cfif not isDefined("variables.action") OR len(variables.action) EQ 0>
	<cfset variables.action="nothing">
</cfif>
	
	
<main class="container-fluid px-5 py-3" id="content">
	<h1 class="h2 mt-2">Bulkload Media </h1>

<!------------------------------------------------------->
	
	<cfif #variables.action# is "nothing">
		<cfoutput>
			<p>This tool adds media records. The media can be related to records that have to be in MCZbase prior to uploading this csv. Duplicate columns will be ignored. Some of the values must appear as they do on the controlled vocabulary lists.  For media on the shared storage, you may <a href="/tools/BulkloadMedia.cfm?action=pickTopDirectory">create a bulkloader sheet</a> from files that have no media record.  For very large image files you may include height and width attributes to skip automatic calculation if that is too slow.
			</p>
			<h2 class="h4">Use Template to Load Data</h2>
			<button class="btn btn-xs btn-primary float-left mr-3" id="copyButton">Copy Column Headers</button>
			<div id="template" class="my-1 mx-0">
				<label for="templatearea" class="data-entry-label" style="line-height: inherit;">
					Copy this header line, paste it into a blank worksheet, and save it as a .csv file or <a href="/tools/#pageTitle#.cfm?action=getCSVHeader" class="font-weight-bold">download</a> a template.
				</label>
				<textarea style="height: 60px;" cols="90" id="templatearea" class="mb-1 w-100 data-entry-textarea small">#fieldlist#</textarea>
			</div>
			<div class="accordion" id="accordionID1">
				<div class="steps card bg-light">
					<div class="card-header" id="headingID1">
						<h3 class="h5 my-0">
							<button type="button" role="button" aria-label="id pane 3" class="headerLnk text-left w-100" data-toggle="collapse" data-target="##IDPane1" aria-expanded="false" aria-controls="IDPane1">
							Steps for Bulkloading
							</button>
						</h3>
					</div>
					<div id="IDPane1" class="collapse" aria-labelledby="headingID1" data-parent="##accordionID1">
						<div class="accordion-body">			
							<dl class="pt-2 px-3">
								<dt class="float-left px-2">Preparation:</dt><dd class="px-5 mx-3">Prepare a spreadsheet for bulkload.</dd>
									<ul class="px-5 mx-3">
										<li>Create a spreadsheet with the appropriate column headers (you can use the <a href="/tools/BulkloadMedia.cfm?action=getCSVHeader">template</a>). Make sure that the required fields are included. </li>
										<li>Ensure MEDIA_URI and PREVIEW_URI fields contain media that exists on the shared drive or external URL. A preview_URI will be created from the media_URI if one is not provided. This gives you the opportunity to pick a representative image (or part of the larger image) that is clearly visible.</li>
										<li>For media on the shared storage, you may <a href="/tools/BulkloadMedia.cfm?action=pickTopDirectory">create a bulkloader sheet</a> from files that have no media record.</li>
										<li>Check to see that records exist for the relationships fields (e.g., cataloged_item, agent, collecting_event).</li>
									</ul>
								<dt class="float-left px-2">Step 1:</dt>
									<dd class="px-5 mx-3">Upload a comma-delimited text file (csv). It is best to work in a spreadsheet application and then save a sheet as a CSV file (using save options to make sure that formatting choices are retained). You can go back to the spreadsheet to make the changes and save it again to a CSV with another filename if changes are needed.</dd>
								<dt class="float-left px-2">Step 2:</dt>
									<dd class="px-5 mx-3">Validation. Check the table of data. If there are validation problems, you may download the data as a spreadsheet including the validation messages.</dd>
								<dt class="float-left px-2">Step 3:</dt>
									<dd class="px-5 mx-3">Load the data. </dd>
							</dl>
						</div>
					</div>
				</div>
				<div class="desc card bg-light">
					<div class="card-header" id="headingID2">
						<h3 class="h5 my-0">
							<button type="button" role="button" aria-label="id pane" class="headerLnk text-left w-100" data-toggle="collapse" data-target="##IDPane2" aria-expanded="false" aria-controls="IDPane2">
								Data Entry Instructions per Column
							</button>
						</h3>
					</div>
					<div id="IDPane2" class="collapse" aria-labelledby="headingID2" data-parent="##accordionID1">
						<div class="card-body" id="IDCardBody">
							<p class="px-3 pt-2"> Columns in <span class="text-danger">red</span> are required; others are optional.</p>
							<ul class="mb-4 h5 font-weight-normal list-group mx-3">
								<cfloop list="#fieldlist#" index="field" delimiters=",">
									<cfquery name = "getComments"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#"  result="getComments_result">
										SELECT comments
										FROM sys.all_col_comments
										WHERE 
											owner = 'MCZBASE'
											and table_name = 'CF_TEMP_MEDIA'
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
						</div>
					</div>
				</div>
										
				<div class="vocab card bg-light">
					<div class="card-header" id="headingID3">
						<h3 class="h5 my-0">
							<button type="button" role="button" aria-label="id pane 2" class="headerLnk text-left w-100" data-toggle="collapse" data-target="##IDPane3" aria-expanded="false" aria-controls="IDPane3" title="Controlled Vocabulary">
							Controlled Vocabulary Lists
							</button>
						</h3>
					</div>
					<div id="IDPane3" class="collapse" aria-labelledby="headingID3" data-parent="##accordionID1">
						<div class="accordion-body">
							<p class="px-3 pt-3 mb-0">Find controlled vocabulary in MCZbase.</p>
							<ul class="list-group pt-1 pb-2 px-3 list-group-horizontal-md">
								<li class="list-group-item font-weight-lessbold">
									<a href="/vocabularies/ControlledVocabulary.cfm?table=CTMEDIA_LABEL">MEDIA_LABEL</a> </li> <span class="mt-1 d-none d-md-inline-block"> | </span>
								<li class="list-group-item font-weight-lessbold">
									<a href="/vocabularies/ControlledVocabulary.cfm?table=CTMEDIA_RELATIONSHIP">MEDIA_RELATIONSHIP</a></li> <span class="mt-1 d-none d-md-inline-block"> | </span>
								<li class="list-group-item font-weight-lessbold">
									<a href="/vocabularies/ControlledVocabulary.cfm?table=CTMEDIA_TYPE">MEDIA_TYPE</a> </li><span class="mt-1 d-none d-md-inline-block"> | </span>
								<li class="list-group-item font-weight-lessbold">
									<a href="/vocabularies/ControlledVocabulary.cfm?table=CTMIME_TYPE">MIME_TYPE</a> </li><span class="mt-1 d-none d-md-inline-block"> | </span>
								<li class="list-group-item font-weight-lessbold">
									<a href="/vocabularies/ControlledVocabulary.cfm?table=CTMEDIA_LICENSE">MEDIA_LICENSE</a>
								</li>
							</ul>
						</div>
					</div>
				</div>
										
			
										
				<div class="rels card bg-light">
					<div class="card-header" id="headingID4">
						<h3 class="h5 my-0">
							<button type="button" role="button" aria-label="id pane 4" class="headerLnk text-left w-100" data-toggle="collapse" data-target="##IDPane4" aria-expanded="false" aria-controls="IDPane4">
								Media Relationship Entries
							</button>
						</h3>
					</div>
					<div id="IDPane4" class="collapse" aria-labelledby="headingID4" data-parent="##accordionID1">
						<div class="accordion-body">			
							<!--- Load from code table, lookup primary key for target table and display that for all media relationships --->
							<!--- Add configuration for additional fields this bulkloader supports --->
							<cfset alsoSupported = StructNew()>
							<cfset alsoSupported['agent']="AGENT_NAME">
							<cfset alsoSupported['cataloged_item']="GUID">
							<cfset alsoSupported['specimen_part']="PART CONTAINER BARCODE, or GUID">
							<cfset alsoSupported['underscore_collection']="COLLECTION_NAME">
							<cfset alsoSupported['project']="PROJECT_NAME">
							<cfset alsoSupported['accn']="ACCN_NUMBER">
							<cfset alsoSupported['deaccession']="DEACC_NUMBER">
							<cfset alsoSupported['loan']="LOAN_NUMBER">
							<cfset alsoSupported['borrow']="BORROW_NUMBER">
							<cfquery name="getRelationshipTypes" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
								SELECT
									media_relationship, description, label, auto_table, cols.column_name as primary_key
								FROM
									ctmedia_relationship, all_cons_columns cols, all_constraints cons
								WHERE 
									upper(ctmedia_relationship.auto_table) = cols.table_name
									and cons.constraint_type = 'P'
									AND cons.constraint_name = cols.constraint_name
									AND cons.owner = cols.owner
									and cons.owner='MCZBASE'
									AND cols.position = 1
								ORDER BY auto_table
							</cfquery>
							<p class="px-3 pt-3 pb-2 mb-0"><b>Note:</b> Special case for media bulkloads of media related to accessions: If making a relationship to an accession, use the ACCN_NUMBER, but prefix it with an A, soley for the purpose of this bulkload, for example, enter A23252 for accession number 23252 (or use the TRANSACTION_ID, prefixed with a T)</p>
							<table class="table table-responsive small table-striped mx-3 mb-4">
								<thead class="thead-light">
									<tr>
										<th>Table</th><br>
										<th>Relationship</th>
										<th>Keys</th>
									</tr>
								</thead>
								<tbody>
									<cfloop query="getRelationshipTypes">
										<tr>	
											<td>#getRelationshipTypes.auto_table#</td>
											<td>#getRelationshipTypes.media_relationship#</td>
											<cfif #getRelationshipTypes.auto_table# EQ "accn" >
												<!--- transaction_id and accn_number are both integers: only use accn_number --->
												<td>ACCN_NUMBER, prefixed with A, or TRANSACTION_ID, prefixed with at T.</td>
											<cfelse>
												<cfset also = "">
												<cfif StructKeyExists(alsoSupported,"#getRelationshipTypes.auto_table#")>
													<cfset also = " or " & alsoSupported["#getRelationshipTypes.auto_table#"]>
												</cfif>
												<td>#getRelationshipTypes.primary_key##also#</td>
											</cfif>
										</tr>	
									</cfloop>
								</tbody>
							</table>	
						</div>
					</div>
				</div>
								
				<div class="license card bg-light">
					<div class="card-header" id="headingID5">
						<h3 class="h5 my-0">
							<button type="button" role="button" aria-label="id pane 5" class="headerLnk text-left w-100" data-toggle="collapse" data-target="##IDPane5" aria-expanded="false" aria-controls="IDPane5">
								Media Licenses
							</button>
						</h3>
					</div>
					<div id="IDPane5" class="collapse" aria-labelledby="headingID5" data-parent="##accordionID1">
						<div class="accordion-body">
							<cfquery name="getMediaLicences" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
								SELECT media_license_id, display, description, uri 
								FROM ctmedia_license
								ORDER BY media_license_id
							</cfquery>
							<p class="px-3 py-2 mb-0">The MEDIA_LICENSE_ID should be entered using the numeric codes below. If omitted this will default to the &quot;1 - MCZ Permissions &amp; Copyright&quot; license.</p>
							<h3 class="small90 pl-3">Media License Codes:</h3>
							<dl class="pl-3 mb-4">
								<cfloop query="getMediaLicences">
									<dt class="btn-secondary"><span class="badge badge-light">#getMediaLicences.media_license_id# </span> #getMediaLicences.display#</dt> <dd>#getMediaLicences.description#</dd>
								</cfloop>
							</dl>
						</div>
					</div>
				</div>
								
				<div class="mask card mb-2 bg-light">
					<div class="card-header" id="headingID6">
						<h3 class="h5 my-0">
							<button type="button" role="button" aria-label="id pane 5" class="headerLnk text-left w-100" data-toggle="collapse" data-target="##IDPane6" aria-expanded="false" aria-controls="IDPane6">
								Mask Media
							</button>
						</h3>
					</div>
					<div id="IDPane6" class="collapse" aria-labelledby="headingID6" data-parent="##accordionID1">
						<div class="accordion-body">
							<p class="px-4 my-3">To mark media as hidden from the public, enter 1 in the MASK_MEDIA column. Enter zero or leave blank for public media.</p>
						</div>
					</div>
				</div>
			</div>
			<div class="">
				<h2 class="h4 mt-4">Upload a comma-delimited text file (csv)</h2>
				<form name="getFiles" method="post" enctype="multipart/form-data" action="/tools/#pageTitle#.cfm">
					<div class="form-row border rounded p-2">
						<input type="hidden" name="action" value="getFile">
						<div class="col-12 col-md-4">
							<label for="fileToUpload" class="data-entry-label">File to bulkload:</label> 
							<input type="file" name="FiletoUpload" id="fileToUpload" class="data-entry-input p-0 m-0">
						</div>
						<div class="col-12 col-md-3">
							<label for="characterSet" class="data-entry-label">Character Set:</label> 
							<select name="characterSet" id="characterSet" required class="data-entry-select reqdClr">
								<option selected></option>
								<option value="utf-8" >utf-8</option>
								<option value="iso-8859-1">iso-8859-1</option>
								<option value="windows-1252">windows-1252 (Win Latin 1)</option>
								<option value="MacRoman">MacRoman</option>
								<option value="x-MacCentralEurope">Macintosh Latin-2</option>
								<option value="windows-1250">windows-1250 (Win Eastern European)</option>
								<option value="windows-1251">windows-1251 (Win Cyrillic)</option>
								<option value="utf-16">utf-16</option>
								<option value="utf-32">utf-32</option>
							</select>
						</div>
						<div class="col-12 col-md-3">
							<label for="format" class="data-entry-label">Format:</label> 
							<select name="format" id="format" required class="data-entry-select reqdClr">
								<option value="DEFAULT" selected >Standard CSV</option>
								<option value="TDF">Tab Separated Values</option>
								<option value="EXCEL">CSV export from MS Excel</option>
								<option value="RFC4180">Strict RFC4180 CSV</option>
								<option value="ORACLE">Oracle SQL*Loader CSV</option>
								<option value="MYSQL">CSV export from MYSQL</option>
							</select>
						</div>
						<div class="col-12 col-md-2">
							<label for="submitButton" class="data-entry-label">&nbsp;</label>
							<input type="submit" id="submittButton" value="Upload this file" class="btn btn-primary btn-xs">
						</div>
					</div>
				</form>
			</div>
			<script>
				document.getElementById('copyButton').addEventListener('click', function() {
					// Get the textarea element
					var textArea = document.getElementById('templatearea');

					// Select the text content
					textArea.select();

					try {
						// Copy the selected text to the clipboard
						var successful = document.execCommand('copy');
						var msg = successful ? 'successful' : 'unsuccessful';
						console.log('Copy command was ' + msg);
					} catch (err) {
						console.log('Oops, unable to copy', err);
					}

					// Optionally deselect the text after copying to avoid confusion
					window.getSelection().removeAllRanges();

					// Optional: Provide feedback to the user
					alert('Text copied to clipboard!');
				});
			</script>
		</cfoutput>
	</cfif>

<!------------------------------------------------------->

	<cfif #variables.action# is "getFile">

		<!--- get form variables --->
		<cfif isDefined("form.fileToUpload")><cfset variables.fileToUpload = form.fileToUpload></cfif>
		<cfif isDefined("form.format")><cfset variables.format = form.format></cfif>
		<cfif isDefined("form.characterSet")><cfset variables.characterSet = form.characterSet></cfif>

		<cfoutput>
			<h2 class="h4">First step: Reading data from CSV file.</h2>
			<!--- Compare the numbers of headers expected against provided in CSV file --->
			<!--- Set some constants to identify error cases in cfcatch block --->
			<cfset NO_COLUMN_ERR = "<p>One or more required fields are missing in the header line of the csv file. <br>Missing fields: </p>"><!--- " --->
			<cfset DUP_COLUMN_ERR = "<p>One or more columns are duplicated in the header line of the csv file.<p>"><!--- " --->
			<cfset COLUMN_ERR = "Error inserting data ">
			<cfset NO_HEADER_ERR = "<p>No header line found, csv file appears to be empty.</p>"><!--- " --->
			<cfset table_name = "CF_TEMP_MEDIA">
			<cftry>
				<!--- cleanup any incomplete work by the same user --->
				<cfquery name="killOld" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					DELETE FROM cf_temp_media
					WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<!--- 
				<cfquery name="killOld" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					DELETE FROM cf_temp_media_relations
					WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cfquery name="killOld" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					DELETE FROM cf_temp_media_labels 
					WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				--->

				<cfset variables.foundHeaders =""><!--- populated by loadCsvFile --->
				<cfset variables.size=""><!--- populated by loadCsvFile --->
				<cfset iterator = loadCsvFile(FileToUpload=FileToUpload,format=format,characterSet=characterSet)>

				<!--- Note: As we can't use csvFormat.withHeader(), we can not match columns by name, we are forced to do so by number, thus arrays --->
				<cfset colNameArray = listToArray(ucase(variables.foundHeaders))><!---the list of columns/fields found in the input file--->
				<cfset fieldArray = listToArray(ucase(fieldlist))><!--- the full list of fields --->
				<cfset typeArray = listToArray(fieldTypes)><!--- the types for the full list of fields --->
					
				<div class="col-12 my-4">
					<h3 class="h4">Found #size# columns in header of csv file.</h3>
					<h3 class="h4">There are #ListLen(fieldList)# columns expected in the header (of these #ListLen(requiredFieldList)# are required).</h3>
					<!--- check for required fields in header line, list all fields, throw exception and fail if any required fields are missing --->
					<cfset reqFieldsResponse = checkRequiredFields(fieldList=fieldList,requiredFieldList=requiredFieldList,NO_COLUMN_ERR=NO_COLUMN_ERR,TABLE_NAME=TABLE_NAME)>

					<!--- Test for additional columns not in list, warn and ignore. --->
					<cfset addFieldsResponse = checkAdditionalFields(fieldList=fieldList)>

					<!--- Identify duplicate columns and fail if found --->
					<cfset dupFieldsResponse = checkDuplicateFields(foundHeaders=variables.foundHeaders,DUP_COLUMN_ERR=DUP_COLUMN_ERR)>

					<cfset colNames="#foundHeaders#">
					<cfset loadedRows = 0>
					<cfset foundHighCount = 0>
					<cfset foundHighAscii = "">
					<cfset foundMultiByte = "">
					<!--- Iterate through the remaining rows inserting the data into the temp table. --->
					<cfset row = 0>
					<cfset errorMessage = "">
					<cfloop condition="#iterator.hasNext()#">
						<!--- obtain the values in the current row --->
						<cfset rowData = iterator.next()>
						<cfset row = row + 1>
						<cfset columnsCountInRow = rowData.size()>
						<!--- Throw exception (below) if column count is not equal to header size --->
						<cfif columnsCountInRow NEQ size>
							<cfset errorMessage = "Row #row# contains #columnsCountInRow#, but #size# are expected from the headers">
						</cfif>
						<cfset collValuesArray= ArrayNew(1)>
						<cfloop index="i" from="0" to="#rowData.size() - 1#">
							<!--- loading cells from object instead of list allows commas inside cells --->
							<cfset thisBit = "#rowData.get(JavaCast("int",i))#" >
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
							<cfif len(errorMessage) GT 0>
								<cfthrow message="#errorMessage#">
							</cfif>
							<!--- construct insert for row with a line for each entry in fieldlist using cfqueryparam if column header is in fieldlist, otherwise using null --->
							<!--- Note: As we can't use csvFormat.withHeader(), we can not match columns by name, we are forced to do so by number, thus arrays --->
							<cfquery name="insert" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="insert_result">
								INSERT INTO cf_temp_media
									(#fieldlist#,username)
								VALUES (
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
							<cfset error_summary = "">
							<cfif cfcatch.message CONTAINS "invalid date or time string">
								<cfset error_summary = "Invalid date, format must be yyyy-mm-dd">
							<cfelseif cfcatch.message CONTAINS "CFSQLTYPE CF_SQL_DECIMAL">
								<cfset error_summary = "MASK_MEDIA must be a number or blank and MEDIA_LICENCE_ID must be a number.">
							</cfif>
							<cfset error_message="<h3 class='h4'>#COLUMN_ERR# from <strong>line #row#</strong> in input file. <strong>#error_summary#</strong></h3><div class='mt-1'><strong>Header:</strong>[#colNames#]</div><div class='mt-1'><strong>Row:</strong>[#ArrayToList(collValuesArray)#] </div><div class='mt-1 h3'><strong>Error:</strong> #cfcatch.message#</div>"><!--- " --->
							<cfif isDefined("cfcatch.queryError")>
								<cfset error_message = "#error_message# #cfcatch.queryError#">
							</cfif>
							<cfthrow message = "#error_message#">
						</cfcatch>
						</cftry>
					</cfloop>
					<cfif foundHighCount GT 0>
						<cfif foundHighCount GT 1><cfset plural="s"><cfelse><cfset plural=""></cfif>
						<h3 class="h4">Found characters where the encoding is probably important in the input data.</h3>
						<div>
							<p>Showing #foundHighCount# example#plural#.  If these do not appear as the correct characters, the file likely has a different encoding from the one you selected and
							you probably want to <strong><a href="/tools/BulkloadMedia.cfm">reload</a></strong> this file selecting a different encoding.  If these appear as expected, then 
								you selected the correct encoding and can continue to validate or load.</p>
						</div>
						<ul class="pb-1 h4 list-unstyled">
							#foundHighAscii# #foundMultiByte#
						</ul>
					</cfif>
				</div>
				<h3 class="h3">
					<cfif loadedRows EQ 0>
						Loaded no rows from the CSV file.  The file appears to be just a header with no data. Fix file and <a href="/tools/BulkloadMedia.cfm">reload</a>.
					<cfelse>
						Successfully read #loadedRows# records from the CSV file.  Next <a href="/tools/BulkloadMedia.cfm?action=validate">click to validate</a>.
					</cfif>
				</h3>
			<cfcatch>
				<h3 class="h4">
					Failed to read the CSV file.  Fix the errors in the file and <a href="/tools/BulkloadMedia.cfm">reload</a>.
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
						<h3 class="h4">Found characters with unexpected encoding in the header row.  This is probably the cause of your error.</h3>
						<div>
							Showing #foundHighCount# examples. Did you select utf-16 or unicode for the encoding for a file that does not have multibyte encoding?
						</div>
						<ul class="pb-1 h4 list-unstyled">
							#foundHighAscii# #foundMultiByte#
						</ul>
					</cfif>
				</cfif>
				<cfif Find("#NO_COLUMN_ERR#",cfcatch.message) GT 0>
					#cfcatch.message#
				<cfelseif Find("#COLUMN_ERR#",cfcatch.message) GT 0>
					#cfcatch.message#
				<cfelseif Find("#DUP_COLUMN_ERR#",cfcatch.message) GT 0>
					#cfcatch.message#
				<cfelseif Find("IOException reading next record: java.io.IOException: (line 1) invalid char between encapsulated token and delimiter",cfcatch.message) GT 0>
					<ul class="py-1 h4 list-unstyled">
						<li>Unable to read headers in line 1.  Did you select CSV format for a tab delimited file?</li>
					</ul>
				<cfelseif Find("IOException reading next record: java.io.IOException: (line 1)",cfcatch.message) GT 0>
					<ul class="py-1 h4 list-unstyled">
						<cfif format EQ "DEFAULT"><cfset fmt="CSV: Default Comma Separated values"><cfelse><cfset fmt="#format#"></cfif>
						<li>Unable to read headers in line 1.  Is your file actually have the format #fmt#?</li>
						<li>#cfcatch.message#</li>
					</ul>
				<cfelseif Find("IOException reading next record: java.io.IOException:",cfcatch.message) GT 0>
					<ul class="py-1 h4 list-unstyled">
						<cfif format EQ "DEFAULT"><cfset fmt="CSV: Default Comma Separated values"><cfelse><cfset fmt="#format#"></cfif>
						<li>Unable to read a record from the file.  One or more lines may not be consistent with the specified format #format#</li>
						<li>#cfcatch.message#</li>
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
			<a name="loader" class="text-white">top</a>
		</cfoutput>
	</cfif>

<!------------------------------------------------------->

	<cfif #variables.action# is "validate">
		<h2 class="h4 mb-3">Second step: Data Validation</h2>
		<cfoutput>
			<!--- Checks that do not require looping through the data, check for missing required data, missing values from key value pairs, bad formats (e.g., data) and values that do not match database code tables--->
				
			<cfset key = ''>

			<!--- Set a created by agent from the current user, used as metadata in relationships, not as the 'created by agent' relationship --->
			<cfquery name="update" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE
					cf_temp_media
				SET
					created_by_agent_id = (
						select AGENT_ID from AGENT_NAME WHERE AGENT_NAME = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#"> 
						and AGENT_NAME_TYPE = 'login'
						)
				WHERE  
					username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#"> 
			</cfquery>

			<!--- Correct any http://mczbase.mcz URIs to https://mczbase.mcz --->
			<cfquery name="getURIs" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT MEDIA_URI, KEY,USERNAME
				FROM 
					cf_temp_media
				WHERE 
					username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfloop query="getURIs">
				<cfif Find("http://mczbase.mcz.harvard.edu",getURIs.media_uri) EQ 1>
					<cfquery name="fixURI" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						UPDATE
							cf_temp_media
						SET media_uri = regexp_replace(media_uri,'^http://mczbase.mcz.harvard.edu','https://mczbase.mcz.harvard.edu')
						WHERE 
							key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getURIs.key#">
					</cfquery>
				</cfif> 
			</cfloop>

			<!--- Required fields missing warning --->
			<cfloop list="#requiredfieldlist#" index="requiredField">
				<cfquery name="checkRequired" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE cf_temp_media
					SET 
						status = concat(nvl2(status, status || '; ', ''),'#requiredField# is missing')
					WHERE #requiredField# is null
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
			</cfloop>
			<cfloop from="1" to="#NUMBER_OF_RELATIONSHIP_PAIRS#" index="relNo">
				<cfquery name="checkRequired" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE cf_temp_media
					SET 
						status = concat(nvl2(status, status || '; ', ''),'Both media_relationship_#relNo# and media_related_to_#relNo# must contain values.s')
					WHERE
						(
							( media_relationship_#relNo# IS NULL AND media_related_to_#relNo# IS NOT NULL)
							OR 
							( media_relationship_#relNo# IS NOT NULL AND media_related_to_#relNo# IS NULL)
						)
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
			</cfloop>

			<!---- Check a set of columns for values of length less than three --->
			<!--- Define an array of columns to check --->
			<cfset columns = ["subject", "description", "media_uri","MIME_TYPE","MEDIA_TYPE","PREVIEW_URI","MEDIA_LABEL_1","LABEL_VALUE_1","MEDIA_LABEL_2","LABEL_VALUE_2","KEY","USERNAME"]>
			<cfloop from="1" to="#NUMBER_OF_RELATIONSHIP_PAIRS#" index="relNo">
				<cfset ArrayAppend(columns,"MEDIA_RELATIONSHIP_#relNo#")>
			</cfloop>
			<cfset columsWithTooFewChars = false>
			<cfloop index="column" array="#columns#">
				<!--- loop through the array of column names, flag entries with too little data --->
				<cfquery name="lenCheck" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="lenCheck_result">
					UPDATE cf_temp_media 
					SET status = concat(nvl2(status, status || '; ', ''),'too few characters in #column#')
					WHERE 
						#column# IS NOT NULL 
						and LENGTH(#column#) < 3
						and username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cfif lenCheck_result.recordcount GT 0>
					<cfset columsWithTooFewChars = true>
				</cfif>
			</cfloop>
			<!--- Warn if there are any --->
			<cfif columsWithTooFewChars>
				<h2 class="text-danger">Entries with fewer than 3 characters found. Check for stray marks on the CSV.</h2>
			<cfelse>
				
			</cfif>
			<!---NOT in codetable warnings or match expectation--->
			<cfquery name="warningMessageMediaType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE
					cf_temp_media
				SET
					status = concat(nvl2(status, status || '; ', ''),'MEDIA_TYPE invalid - see <a href="/vocabularies/ControlledVocabulary.cfm?table=CTMEDIA_TYPE">controlled vocabulary</a>')
				WHERE 
					media_type not in (select media_type from ctmedia_type) AND
					username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="warningMessageMimeType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE
					cf_temp_media
				SET
					status = concat(nvl2(status, status || '; ', ''),'MIME_TYPE invalid - see <a href="/vocabularies/ControlledVocabulary.cfm?table=CTMEDIA_TYPE">controlled vocabulary</a>')
				WHERE 
					mime_type not in (select mime_type from CTMIME_TYPE) AND
					username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="warningMessageLicense" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE
					cf_temp_media
				SET
					status = concat(nvl2(status, status || '; ', ''),'MEDIA_LICENSE_ID ' || media_license_id  || ' invalid - see <a href="/vocabularies/ControlledVocabulary.cfm?table=CTMEDIA_LICENSE">controlled vocabulary</a>')
				WHERE
					media_license_id not in (select media_license_id from ctmedia_license) AND
					username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="warningMessageMask" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE
					cf_temp_media
				SET
					cf_temp_media.status = concat(nvl2(status, status || '; ', ''),'MASK_MEDIA must = blank, 1 or 0')
				WHERE 
					mask_media IS NOT NULL 
					and mask_media <> 0
					and mask_media <> 1
					and username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#"> 
			</cfquery>
				
			<!---- Identify incomplete label:value pairs and label values not in code tables --------------------->		
			<cfloop from="1" to="#NUMBER_OF_LABEL_VALUE_PAIRS#" index="idx">
				<cfset variableName = "media_label_#idx#">
				<cfset variableValueNo = "label_value_#idx#">
				<!--- Warn variable name does not match codetable or is missing when label_value is present --->
				<cfquery name="checkLabelType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE cf_temp_media
					SET 
						status = concat(nvl2(status, status || '; ', ''),'#variableName# is missing or does not match codetable')
					WHERE (
							#variableName# not in (select media_label from ctmedia_label) 
							OR 
							(#variableValueNo# is not null AND #variableName# is null)
						)
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<!--- Warn if Label_value is missing when media_label is there --->
				<cfquery name="checkLabelNullOfPair" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE cf_temp_media
					SET 
						status = concat(nvl2(status, status || '; ', ''),'#variableValueNo# is missing!')
					WHERE 
						#variableName# is not null
						and #variableValueNo# is null
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<!--- Warn if media_label is redundant with one of the required fields --->
				<cfquery name="checkLabelNullOfPair" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					UPDATE cf_temp_media
					SET 
						status = concat(nvl2(status, status || '; ', ''), #variableName# || ' in media_label_#idx# duplicates a required column. ')
					WHERE 
						upper(#variableName#) in ('DESCRIPTION','MADE DATE','SUBJECT')
						AND #variableValueNo# IS NOT NULL
						AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
			</cfloop>	

		
			<!--- Check for duplicated media records, within the set and between the set and existing media --->
			<cfquery name="mediaExists" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE cf_temp_media
				SET
					status = concat(nvl2(status, status || '; ', ''),'Media record for this media_uri already exists.')
				WHERE 
					media_uri IN (select media_uri from MEDIA)
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfquery name="mediaDups" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE cf_temp_media
				SET
					status = concat(nvl2(status, status || '; ', ''),'Duplicate media_uri in this bulkload.')
				WHERE 
					media_uri IN (
						SELECT media_uri 
						FROM cf_temp_media
						WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						GROUP BY media_uri
						HAVING count(*) > 1
					)
					AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<!---------------------------------------------------------->	
				
			<!--- Obtain data and loop through records performing additional checks --->
			<cfquery name="getTempMedia" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT MEDIA_URI,MIME_TYPE,MEDIA_TYPE,SUBJECT,MADE_DATE,DESCRIPTION,HEIGHT,WIDTH,PREVIEW_URI,MEDIA_LICENSE_ID,MASK_MEDIA,
					<cfloop from="1" to="#NUMBER_OF_RELATIONSHIP_PAIRS#" index="i">
						MEDIA_RELATIONSHIP_#i#,MEDIA_RELATED_TO_#i#,
					</cfloop>
					<cfloop from="1" to="#NUMBER_OF_LABEL_VALUE_PAIRS#" index="i">
						MEDIA_LABEL_#i#,LABEL_VALUE_#i#,
					</cfloop>
					KEY,USERNAME
				FROM 
					cf_temp_media
				WHERE 
					username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>

			<!--- LOOP throught getTempMedia and check each row for certain values--->
			<cfloop query="getTempMedia">
				<!--- Check MEDIA_URI ------------->
				<cfset urlToCheck = "#getTempMedia.media_uri#">
				<cfset validstyle = ''>
				<cfhttp url="#urlToCheck#" method="HEAD" timeout="10" throwonerror="false">
				<cfif cfhttp.statusCode NEQ '200 OK'>	
					<cfquery name="warningBadURI1" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						UPDATE
							cf_temp_media
						SET
							status = concat(nvl2(status, status || '; ', ''),'MEDIA_URI is invalid <span class="text-danger">(bad link)</span>')
						WHERE
							media_uri is not null and
							username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#"> and
							key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempMedia.key#">
					</cfquery>
				</cfif>

				<!--- Test for valid yyyy-mm-dd date string --->
				<cftry>
					<cfset formattedDate = DateFormat(made_date, "yyyy-mm-dd")>
					<cfquery name="testDateUpdate" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						UPDATE
							cf_temp_media
						SET
							made_date = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#formattedDate#">
						WHERE
							username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#"> and
							key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempMedia.key#">
					</cfquery>
				<cfcatch>
					<cfquery name="warningBadDate" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						UPDATE
							cf_temp_media
						SET
							status = concat(nvl2(status, status || '; ', ''),'made_date ['|| made_date ||'] not a valid date in the form yyyy-mm-dd.')
						WHERE
							username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#"> and
							key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempMedia.key#">
					</cfquery>
				</cfcatch>
				</cftry>

				<!--- loop through relationship pairs --->
				<cfloop from="1" to="#NUMBER_OF_RELATIONSHIP_PAIRS#" index="relNo">
					<cfif len(evaluate("media_relationship_#relNo#")) gt 0>
						<!---------- CHECK Relationship valid ----------------->
						<cfquery name="warningBadRel1" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							UPDATE
								cf_temp_media
							SET
								status = concat(nvl2(status, status || '; ', ''),'MEDIA_RELATIONSHIP_#relNo# is invalid check <a href="/vocabularies/ControlledVocabulary.cfm?table=CTMEDIA_RELATIONSHIP">controlled vocabulary</a>')
							WHERE
								media_relationship_#relNo# not in (select media_relationship from ctmedia_relationship) and 
								username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#"> and
								key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempMedia.key#">
						</cfquery>
					</cfif>
					<cfif len(evaluate("MEDIA_RELATED_TO_#relNo#")) eq 0>
						<!---------- CHECK Related to has value----------->
						<cfquery name="warningBadRel1" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							UPDATE
								cf_temp_media
							SET
								status = concat(nvl2(status, status || '; ', ''),'MEDIA_RELATED_TO_#relNo# is missing')
							WHERE
								media_relationship_#relNo# is not null and 
								username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#"> AND
								key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempMedia.key#">
						</cfquery>
					</cfif>
				</cfloop>

				<!--- check that the same relationship is not asserted twice in the same record --->
				<cfset relPairCheck = "">
				<cfloop from="1" to="#NUMBER_OF_RELATIONSHIP_PAIRS#" index="relNo">
					<cfquery name="getRel" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						SELECT 
							media_relationship_#relNo# || media_related_to_#relNo# as kvp
						FROM
							cf_temp_media
							WHERE
								media_relationship_#relNo# IS NOT NULL AND
								media_related_to_#relNo# IS NOT NULL AND
								username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#"> AND
								key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempMedia.key#">
					</cfquery>
					<cfif getRel.recordcount GT 0>
						<cfif ListContains(relPairCheck,getRel.kvp) GT 0>
							<!--- we have already seen this relationship for this media record, set a status message --->
							<cfquery name="warningBadRel1" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
								UPDATE
									cf_temp_media
								SET
									status = concat(nvl2(status, status || '; ', ''),'MEDIA_RELATIONSHIP_#relNo# : MEDIA_RELATED_TO_#relNo# is a duplicate relationship')
								WHERE
									username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#"> AND
									key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempMedia.key#">
							</cfquery>
						<cfelse>
							<!--- novel relationship, add to list for this record --->
							<cfset relPairCheck = ListAppend(relPairCheck,getRel.kvp)>
						</cfif>
					</cfif>
				</cfloop>
						
				<!--------------------------------------------------------->
				<cfset height = "">
				<cfset width= "">
				<cfloop from="1" to="#NUMBER_OF_LABEL_VALUE_PAIRS#" index="i">
					<cfset label = evaluate("getTempMedia.MEDIA_LABEL_#i#")>
					<cfset value = evaluate("getTempMedia.LABEL_VALUE_#i#")>
					<cfif label EQ "height" AND len(value) GT 0 >
						<cfset height = value>
					</cfif>
					<cfif label EQ "width" AND len(value) GT 0 >
						<cfset width = value>
					</cfif>
				</cfloop>
				<cfif len(height) GT 0 and len(width) GT 0>
					<!--- if user specified attributes, use these --->
					<cfquery name="setHWFromUser" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
						UPDATE cf_temp_media
						SET  
							height = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#height#">,
							width = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#height#">
						WHERE 
							username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#"> 
							AND
							key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempMedia.key#">
					</cfquery>
				<cfelseif getTempMedia.media_type EQ 'image'>
					<!--- Check Height and Width and add if not entered-------->
					<cfset foundHW = false>
					<cfset filefull = "#Application.webDirectory#/#Replace(getTempMedia.media_uri,"https://mczbase.mcz.harvard.edu/","")#">
					<cfif fileExists("#filefull#")>
						<cfset standardOut = "">
						<cftry>
							<!--- try to use ImageMagick identify to find height/width --->
							<!--- note that slide scans are multi-image tiffs, so more than one line of output with h x w values. --->
							<cfexecute name="/usr/bin/identify" arguments="#filefull#" variable="standardOut" errorVariable="errorOut"  timeout="10" >
							<cfif isDefined("standardOut") AND len(standardOut) GT 0>
								<!--- look for the height x width part of the string in the identify output (option -format "%h,%w" is not working) --->
								<cfset heightxwidth = REMatch(" [0-9]+x[0-9]+ ",standardOut)>
								<cfif ArrayLen(heightxwidth) GT 0>
									<cfset aheight = Trim(ListFirst(ArrayFirst(heightxwidth),"x"))>
									<cfset awidth = Trim(ListLast(ArrayFirst(heightxwidth),"x"))>
									<cfif len(aheight) GT 0 AND len(awidth) GT 0>
										<cfset foundHW = true>
										<cfquery name="setHWFromIM" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
											UPDATE cf_temp_media
											SET  
												height = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#aheight#">,
												width = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#awidth#">
											WHERE 
												username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#"> 
												AND
												key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempMedia.key#">
										</cfquery>
									</cfif>
								</cfif>
							</cfif>
						<cfcatch></cfcatch>
						</cftry>
						<cfif NOT foundHW>
							<cfset info = GetFileInfo("#filefull#")>
							<cfset size = info.size>
							<cfif size LT 3221225472><!--- 30 MB --->
								<!--- failover for smaller files, load image into memory and use coldfusion to find height/width --->
								<cfif getTempMedia.media_type EQ 'image' AND  isimagefile(getTempMedia.media_uri)>
									<cfimage action="info" source="#getTempMedia.media_uri#" structname="imgInfo"/>
									<cfquery name="makeHeightLabel" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
										UPDATE cf_temp_media
										SET  
											height = <cfif len(getTempMedia.height) gt 0>#getTempMedia.height#<cfelse>#imgInfo.height#</cfif>,
											width = <cfif len(getTempMedia.height) gt 0>#getTempMedia.width#<cfelse>#imgInfo.width#</cfif>
										WHERE 
											username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#"> 
											AND
											key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempMedia.key#">
									</cfquery>
								</cfif>
							</cfif>
						</cfif>
					</cfif>
				</cfif>
				<!----------END height and width labels------------------->

				<!--- MD5HASH---------------------------------------------->
				<cfif left(getTempMedia.media_uri,48) EQ 'https://mczbase.mcz.harvard.edu/specimen_images/' >
					<!--- build an md5hash of all local files --->
					<cfset filefull = "#Application.webDirectory#/#Replace(getTempMedia.media_uri,"https://mczbase.mcz.harvard.edu/","")#">
					<cfif fileExists("#filefull#")>
						<cfset info = GetFileInfo("#filefull#")>
						<cfset size = info.size>
						<cfset MD5HASH = "">
						<cfif size LT 3115008><!--- 3MB --->
							<!--- small file, just load and calculate --->
							<cfhttp url="#getTempMedia.media_uri#" method="get" getAsBinary="yes" result="result">
							<cfset MD5HASH=Hash(result.filecontent,"MD5")>
						<cfelseif size LT 3221225472><!--- 300 MB --->
							<!--- large file, handle in shell, but skip very large, likely to timeout load --->
							<cftry>
								<cfexecute name="/usr/bin/md5sum" arguments="#filefull#" variable="standardOut" errorVariable="errorOut"  timeout="4" >
								<cfif isDefined("standardOut") AND len(standardOut) GT 0>
									<cfset MD5HASH = ListFirst(standardOut," ",false)>
								</cfif>
							<cfcatch>
								<!--- may timeout with large files on shared storage --->
							</cfcatch>
							</cftry>
						</cfif>
						<cfif len(MD5HASH) GT 0>
							<cfquery name="makeMD5hash" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
								UPDATE cf_temp_media
								SET MD5HASH = '#MD5HASH#'
								where username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#"> 
								AND
									key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempMedia.key#">
							</cfquery>
						</cfif>
					</cfif>
				</cfif>
				<!----------END MD5HASH----------------------------------->

			</cfloop>
			<!-----END LOOP for getTempMedia----->
			
			<!-------------------Query the Table with updates again------------------------->			
			<cfquery name="getTempMedia2" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT MEDIA_URI,MIME_TYPE,MEDIA_TYPE,SUBJECT,MADE_DATE,DESCRIPTION,HEIGHT,WIDTH,PREVIEW_URI,MEDIA_LICENSE_ID,MASK_MEDIA,
					<cfloop from="1" to="#NUMBER_OF_RELATIONSHIP_PAIRS#" index="rpi">
						MEDIA_RELATIONSHIP_#rpi#,MEDIA_RELATED_TO_#rpi#,
					</cfloop>
					<cfloop from="1" to="#NUMBER_OF_LABEL_VALUE_PAIRS#" index="lpi">
						MEDIA_LABEL_#lpi#,LABEL_VALUE_#lpi#,
					</cfloop>
					KEY,USERNAME,STATUS
				FROM 
					cf_temp_media
				WHERE 
					username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				ORDER BY key
			</cfquery>	
			<!-------- Loop through updated table to add IDs for relationships if there are no status messages------->
			<cfloop query = "getTempMedia2">
				<cfif len(getTempMedia2.status) EQ 0> 
					<cfloop index="i" from="1" to="#NUMBER_OF_RELATIONSHIP_PAIRS#">
						<!--- This generalizes the two key:value pairs (to media_relationship and MEDIA_RELATED_TO)--->
						<cfquery name="getMediaRel" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							SELECT 
								key,
								media_relationship_#i# as media_relationship,
								MEDIA_RELATED_TO_#i# as MEDIA_RELATED_TO
							FROM 
								cf_temp_media
							WHERE 
								media_relationship_#i# is not null
								AND MEDIA_RELATED_TO_#i# is not null
								AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
								AND key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempMedia2.key#">
						</cfquery>

						<cfif getMediaRel.recordCount GT 0 >
							<!---Find the table name "theTable" from the second part of the media_relationship--->
							<cfset theTable = trim(listLast('#getMediaRel.media_relationship#'," "))>
							<!---based on the table, find the primary key--->
							<cfquery name="tables" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
								SELECT cols.table_name, cols.column_name, cols.position, cons.status, cons.owner
								FROM all_constraints cons, all_cons_columns cols
								WHERE cons.constraint_type = 'P'
								AND cons.constraint_name = cols.constraint_name
								AND cons.owner = cols.owner
								and cons.owner='MCZBASE'
								AND cols.table_name = UPPER(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#theTable#">)
								AND cols.position = 1
								ORDER BY cols.table_name, cols.position
							</cfquery>
							<cfif tables.recordcount EQ 0>
								<!--- table extracted from relationship not found, should be redundant with error message from checking code table for relatinships above --->
								<cfquery name="warningBadRel2" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									UPDATE
										cf_temp_media
									SET
										status = concat(nvl2(status, status || '; ', ''),'MEDIA_RELATIONSHIP_#i# table [#theTable#] not found')
									WHERE
										username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#"> AND
										key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempMedia.key#">
								</cfquery>
							<cfelse>
								<!--- Target table exists, lookup the related primary key value --->
								<cfif isNumeric(getMediaRel.MEDIA_RELATED_TO) AND theTable NEQ 'accn'>
									<!--- standard id situation where the surrogate numeric primary key value was provided --->
									<!--- check that key exists --->
									<cfquery name="checkRelatedPrimaryKey" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
											SELECT #tables.column_name# 
											FROM #theTable# 
											WHERE #tables.column_name# = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getMediaRel.MEDIA_RELATED_TO#">
									</cfquery>
									<cfif checkRelatedPrimaryKey.recordcount EQ 1>
										<!--- match found, no action needed to transform primary key ---> 
									<cfelse>
										<cfquery name="warningBadRel2" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
											UPDATE
												cf_temp_media
											SET
												status = concat(nvl2(status, status || '; ', ''),'MEDIA_RELATIONSHIP_#i# no match found for [#getMediaRel.MEDIA_RELATED_TO#] in table [#theTable#]')
											WHERE
												username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#"> AND
												key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempMedia.key#">
										</cfquery>
									</cfif>
									<cfquery name="chkCOID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
										update cf_temp_media set MEDIA_RELATED_TO_#i# =
										(
											select #tables.column_name# from #theTable# where #tables.column_name# = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getMediaRel.MEDIA_RELATED_TO#">
										)
										WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#"> AND
											key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getMediaRel.key#">
									</cfquery>
								<cfelse>
									<!--- Interpret non-numeric strings and lookup numeric primary key values ---> 
									<!--- SPECIAL CASES - Cataloged_item and specimen_part--->
									<cfif #getMediaRel.MEDIA_RELATED_TO# contains "MCZ:">
										<cfif #getMediaRel.media_relationship# contains 'cataloged_item' and len(getMediaRel.MEDIA_RELATED_TO) gt 0>
											<cfset IA = listGetAt(#getMediaRel.MEDIA_RELATED_TO#,1,":")>
											<cfset CCDE = listGetAt(#getMediaRel.MEDIA_RELATED_TO#,2,":")>
											<cfset CI = listGetAt(#getMediaRel.MEDIA_RELATED_TO#,3,":")>
											<cfquery name="chkCOID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
												update cf_temp_media 
												set MEDIA_RELATED_TO_#i# =
													(
														select collection_object_id
														from cataloged_item 
														where cat_num = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#CI#">
															and collection_cde = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#CCDE#">
														)
													WHERE MEDIA_RELATED_TO_#i# is not null AND
													username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#"> AND
													key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempMedia2.key#">
											</cfquery>
										<cfelseif #getMediaRel.media_relationship# contains 'specimen_part' and len(getMediaRel.MEDIA_RELATED_TO) gt 0>
											<cfset IA = listGetAt(#getMediaRel.MEDIA_RELATED_TO#,1,":")>
											<cfset CCDE = listGetAt(#getMediaRel.MEDIA_RELATED_TO#,2,":")>
											<cfset CI = listGetAt(#getMediaRel.MEDIA_RELATED_TO#,3,":")>
											<cfquery name="chkCount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
												select sp.collection_object_id
												from cataloged_item 
													join specimen_part sp on cataloged_item.collection_object_id = sp.derived_from_cat_item
												where cat_num = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#CI#">
													and collection_cde = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#CCDE#">
											</cfquery>
											<cfif chkCount NEQ 1>
												<cfquery name="warningFailedPart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
													UPDATE
														cf_temp_media
													SET
														status = concat(nvl2(status, status || '; ', ''),'failed to find exactly one specimen part for media_related_to_id_#i#  with GUID ['|| media_related_to_#i# ||'].')
													WHERE
														username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#"> and
														key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempMedia2.key#">
												</cfquery>
											<cfelse>
												<cfquery name="chkCOID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
													update cf_temp_media 
													set MEDIA_RELATED_TO_#i# =
														(
															select sp.collection_object_id
															from cataloged_item 
																join specimen_part sp on cataloged_item.collection_object_id = sp.derived_from_cat_item
															where cat_num = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#CI#">
																and collection_cde = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#CCDE#">
															)
														WHERE MEDIA_RELATED_TO_#i# is not null AND
														username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#"> AND
														key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempMedia2.key#">
												</cfquery>
											</cfif> 
										</cfif>
									<cfelseif #getMediaRel.media_relationship# contains 'specimen_part' and len(getMediaRel.MEDIA_RELATED_TO) gt 0>
										<cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
											select sp.collection_object_id as part_id
											from specimen_part sp
												join (select * from coll_obj_cont_hist where current_container_fg = 1)  ch on (sp.collection_object_id = ch.collection_object_id)
												join  container c on (ch.container_id = c.container_id)
												join  container pc on (c.parent_container_id = pc.container_id)
											where pc.barcode = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getMediaRel.media_related_to#">
										</cfquery>
										<cfif c.recordcount is 1 and len(c.part_id) gt 0>
											<cfquery name="chkCOID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
												UPDATE cf_temp_media 
												SET media_related_to_#i# = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#c.part_id#">
												WHERE media_related_to_#i# IS NOT NULL AND
													username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#"> AND
													key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getMediaRel.key#">
											</cfquery>
										<cfelseif REFIND("^[0-9]+$",getMediaRel.MEDIA_RELATED_TO) EQ 0>
											
											<cfquery name="warningFailedPart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
												UPDATE
													cf_temp_media
												SET
													status = concat(nvl2(status, status || '; ', ''),'failed to find a specimen part for media_related_to_id_#i# using part container barcode ['|| media_related_to_#i# ||'].')
													WHERE
														username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#"> and
														key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempMedia2.key#">
											</cfquery>
										</cfif>
									<cfelseif getMediaRel.media_relationship contains 'agent' and !isNumeric(getMediaRel.MEDIA_RELATED_TO)>
										<!-------------------------------------------------------------------------->			
										<!---Update and check media relationships that can take either ID or Name--->
										<cfset relatedAgentID = "">
										<cfset agentProblem = "">
										<cfquery name="findAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
											SELECT agent_id 
											FROM agent_name 
											WHERE agent_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getMediaRel.MEDIA_RELATED_TO#">
												and agent_name_type = 'preferred'
										</cfquery>
										<cfif findAgent.recordCount EQ 1>
											<cfset relatedAgentID = findAgent.agent_id>
										<cfelseif findAgent.recordCount EQ 0>
											<!--- relax criteria, find agent by any name. --->
											<cfquery name="findAgentAny" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
												SELECT agent_id 
												FROM agent_name 
												WHERE agent_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getMediaRel.MEDIA_RELATED_TO#">
											</cfquery>
											<cfif findAgentAny.recordCount EQ 1>
												<cfset relatedAgentID = findAgentAny.agent_id>
											<cfelseif findAgentAny.recordCount EQ 0>
												<cfset agentProblem = "No matches to any agent name">
											<cfelse>
												<cfset agentProblem = "Matches to multiple agent names, use agent_id">
											</cfif>
										<cfelse>
											<cfset agentProblem = "Matches to multiple preferred agent names, use agent_id">
										</cfif>
										<cfif len(relatedAgentID) GT 0>
											<cfquery name="chkCOID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
												update cf_temp_media 
												set MEDIA_RELATED_TO_#i# = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#relatedAgentID#">
												WHERE MEDIA_RELATED_TO_#i# is not null
												AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
												and key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempMedia2.key#">
											</cfquery>
										<cfelse>
											<cfquery name="warningFailedAgentMatch" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
												UPDATE
													cf_temp_media
												SET
													status = concat(nvl2(status, status || '; ', ''),'unable to match ['|| media_related_to_#i# ||'] #agentProblem#.')
												WHERE
													username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#"> and
													key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempMedia2.key#">
											</cfquery>
										</cfif>
									<cfelseif getMediaRel.media_relationship contains 'project' and !isNumeric(getMediaRel.MEDIA_RELATED_TO)>
										<cfquery name="lookupProject" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
											select project_id
											from project
											where project_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getMediaRel.MEDIA_RELATED_TO#">
										</cfquery>
										<cfif lookupProject.recordcount NEQ 1>
											<cfquery name="warningFailedProjectMatch" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
												UPDATE
													cf_temp_media
												SET
													status = concat(nvl2(status, status || '; ', ''),'failed to find project for media_related_to_id_#i#  ['|| media_related_to_#i# ||'].')
												WHERE
													username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#"> and
													key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempMedia2.key#">
											</cfquery>
										<cfelse>
											<cfquery name="setProjectID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
												UPDATE cf_temp_media 
												SET MEDIA_RELATED_TO_#i# = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#lookupProject.project_id#">
												WHERE MEDIA_RELATED_TO_#i# is not null AND 
													username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#"> AND
													key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempMedia2.key#">
											</cfquery>
										</cfif>
									<cfelseif getMediaRel.media_relationship contains 'underscore_collection' and !isNumeric(getMediaRel.MEDIA_RELATED_TO)>
										<cfquery name="lookupCollection" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
											select underscore_collection_id
											from #theTable#
											where collection_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getMediaRel.MEDIA_RELATED_TO#">
										</cfquery>
										<cfif lookupCollection.recordcount NEQ 1>
											<cfquery name="warningFailedProjectMatch" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
												UPDATE
													cf_temp_media
												SET
													status = concat(nvl2(status, status || '; ', ''),'failed to find named group for media_related_to_id_#i#  ['|| media_related_to_#i# ||'].')
												WHERE
													username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#"> and
													key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempMedia2.key#">
											</cfquery>
										<cfelse>
											<cfquery name="chkCOID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
												UPDATE cf_temp_media 
												SET MEDIA_RELATED_TO_#i# = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#lookupCollection.underscore_collection_id#"> 
												WHERE MEDIA_RELATED_TO_#i# is not null 
													AND username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#"> 
													AND key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempMedia2.key#">
											</cfquery>
										</cfif>
									<cfelseif #getMediaRel.media_relationship# contains 'loan' and !isNumeric(getMediaRel.MEDIA_RELATED_TO)>
										<!---lookup transaction_id from loan number if given --->
										<cfquery name="lookupLoan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
											SELECT #theTable#.transaction_id
											FROM #theTable#
											WHERE loan_number = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getMediaRel.MEDIA_RELATED_TO#">
										</cfquery>
										<cfif lookupLoan.recordcount NEQ 1>
											<cfquery name="warningFailedLoanMatch" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
												UPDATE
													cf_temp_media
												SET
													status = concat(nvl2(status, status || '; ', ''),'failed to find loan number for media_related_to_id_#i#  ['|| media_related_to_#i# ||'].')
												WHERE
													username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#"> and
													key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempMedia2.key#">
											</cfquery>
										<cfelse>
											<cfquery name="setLoanTrans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
												UPDATE cf_temp_media 
												SET MEDIA_RELATED_TO_#i# = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#lookupLoan.transaction_id#">
												WHERE MEDIA_RELATED_TO_#i# is not null AND
													username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#"> AND
													key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getMediaRel.key#">
											</cfquery>
										</cfif>
									<cfelseif #getMediaRel.media_relationship# contains 'deaccession' and !isNumeric(getMediaRel.MEDIA_RELATED_TO)>
										<cfquery name="lookupDeacc" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
											SELECT #theTable#.transaction_id
											FROM #theTable#
											WHERE deacc_number = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getMediaRel.MEDIA_RELATED_TO#">
										</cfquery>
										<cfif lookupDeacc.recordcount NEQ 1>
											<cfquery name="warningFailedProjectMatch" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
												UPDATE
													cf_temp_media
												SET
													status = concat(nvl2(status, status || '; ', ''),'failed to find deaccession for media_related_to_id_#i#  ['|| media_related_to_#i# ||'].')
												WHERE
													username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#"> and
													key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempMedia2.key#">
											</cfquery>
										<cfelse>
											<cfquery name="chkCOID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
												UPDATE cf_temp_media 
												SET MEDIA_RELATED_TO_#i# = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#lookupDeacc.transaction_id#">
												WHERE MEDIA_RELATED_TO_#i# is not null AND
													username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#"> AND
													key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getMediaRel.key#">
											</cfquery>
										</cfif>
									<cfelseif #getMediaRel.media_relationship# contains 'borrow' and !isNumeric(getMediaRel.MEDIA_RELATED_TO)>
										<cfquery name="lookupBorrow" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
											SELECT #theTable#.transaction_id
											FROM #theTable#
											WHERE borrow_number = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getMediaRel.MEDIA_RELATED_TO#">
										</cfquery>
										<cfif lookupBorrow.recordcount NEQ 1>
											<cfquery name="warningFailedProjectMatch" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
												UPDATE
													cf_temp_media
												SET
													status = concat(nvl2(status, status || '; ', ''),'failed to find borrow for media_related_to_id_#i#  ['|| media_related_to_#i# ||'].')
												WHERE
													username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#"> and
													key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempMedia2.key#">
											</cfquery>
										<cfelse>
											<cfquery name="setBorrowID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
												UPDATE cf_temp_media 
												SET MEDIA_RELATED_TO_#i# = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#lookupBorrow.transaction_id#">
												WHERE MEDIA_RELATED_TO_#i# is not null AND 
													username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#"> AND
													key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getMediaRel.key#">
											</cfquery>
										</cfif>
									<cfelseif REFind('.* accn$',getMediaRel.media_relationship) GT 0>
										<!--- Special case handling (to allow roundtrip download) --->
										<!--- transaction_id and accn_number are both integers, they are distinguished in a special case here with the prefix A or T --->
										<cfif Left(getMediaRel.media_related_to,1) EQ 'A'>
											<!--- Accession number ---> 
											<!--- lookup the transaction id and prefix it with a T --->
											<cfset putative_accession_number = Right(getMediaRel.media_related_to,len(getMediaRel.media_related_to)-1)>
											<cfquery name="lookupAccn" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
												SELECT 'T' || #theTable#.transaction_id as transaction_id
												FROM #theTable#
												WHERE accn_number = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#putative_accession_number#">
											</cfquery>
											<cfif lookupAccn.recordcount NEQ 1>
												<cfquery name="warningFailedAccnMatch" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
													UPDATE
														cf_temp_media
													SET
														status = concat(nvl2(status, status || '; ', ''),'failed to find accession number for media_related_to_id_#i#  ['|| media_related_to_#i# ||'].')
													WHERE
														username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#"> and
														key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempMedia2.key#">
												</cfquery>
											<cfelse>
												<cfquery name="settAccnID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
													UPDATE cf_temp_media 
													SET MEDIA_RELATED_TO_#i# = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#lookupAccn.transaction_id#">
													WHERE MEDIA_RELATED_TO_#i# is not null AND 
														username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#"> AND
														key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getMediaRel.key#">
												</cfquery>
											</cfif>
										<cfelseif Left(getMediaRel.media_related_to,1) EQ 'T'>
											<!--- Transaction_id ---> 
											<!--- confirm that the transaction id  --->
											<cfset putative_transaction_id = Right(getMediaRel.media_related_to,len(getMediaRel.media_related_to)-1)>
											<cfquery name="lookupAccn" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
												SELECT 'T' || #theTable#.transaction_id
												FROM #theTable#
												WHERE transaction_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#putative_transaction_id#">
											</cfquery>
											<cfif lookupAccn.recordcount NEQ 1>
												<cfquery name="warningFailedAccnMatch" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
													UPDATE
														cf_temp_media
													SET
														status = concat(nvl2(status, status || '; ', ''),'failed to find accession for media_related_to_id_#i#  with transaction_id ['|| media_related_to_#i# ||'].')
													WHERE
														username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#"> and
														key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempMedia2.key#">
												</cfquery>
											<cfelse>
												<!--- no action needed, match found --->
											</cfif>
										<cfelse>
											<cfquery name="warningAccnValue" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
												UPDATE
													cf_temp_media
												SET
													status = concat(nvl2(status, status || '; ', ''),'Relationships with accession must be prefixed with A for accession number or T for transaction_id  media_related_to_id_#i#  ['|| media_related_to_#i# ||'].')
												WHERE
													username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#"> and
													key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempMedia2.key#">
											</cfquery>
										</cfif>
									</cfif>
								</cfif>
							</cfif>
						</cfif>
					</cfloop>
				</cfif>
			</cfloop>
			<!---Display the issues if there is an error and give the links to either continue or start again.--->
			<cfquery name="problemData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				SELECT *
				FROM 
					cf_temp_media
				WHERE 
					username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				ORDER BY key
			</cfquery>
			<cfset i= 1>
			<cfquery name="problemsInData" dbtype="query">
				SELECT count(*) c 
				FROM problemData 
				WHERE status is not null
			</cfquery>
			<h3 class="mt-3">
				<cfif problemsInData.c gt 0>
					There is a problem with #problemsInData.c# of #problemData.recordcount# row(s). See the STATUS column (<a href="/tools/BulkloadMedia.cfm?action=dumpProblems">download</a>). Fix the problems in the data and <a href="/tools/BulkloadMedia.cfm" class="text-danger">start again</a> (Note: In the download non-numeric identifiers for relations that matched will be replaced with numeric values (e.g. the integer transaction_id will replace the Loan Number for documents loan relationships)).
				<cfelse>
					<span class="text-success">Validation checks passed</span>. Look over the table below and <a href="/tools/BulkloadMedia.cfm?action=load" class="btn-link font-weight-lessbold">click to continue (load data)</a> if it all looks good. Or, <a href="/tools/BulkloadMedia.cfm" class="text-danger">start again</a>.
				</cfif>
			</h3>
			<table class='px-0 mx-0 sortable table small table-responsive w-100'>
				<thead class="thead-light">
					<tr>
						<th>BULKLOAD&nbsp;STATUS</th>
						<th>MEDIA_URI</th>
						<th>MIME_TYPE</th>
						<th>MEDIA_TYPE</th>
						<th>SUBJECT</th>
						<th>MADE_DATE</th>
						<th>DESCRIPTION</th>
						<th>HEIGHT(px)</th>
						<th>WIDTH(px)</th>
						<th>PREVIEW_URI</th>
						<th>MEDIA_LICENSE_ID</th>
						<th>MASK_MEDIA</th>
						<cfloop from="1" to="#NUMBER_OF_RELATIONSHIP_PAIRS#" index="relNum">
							<th>MEDIA_RELATIONSHIP_#relNum#</th>
							<th>MEDIA_RELATED_TO_#relNum#</th>
						</cfloop>
						<cfloop from="1" to="#NUMBER_OF_LABEL_VALUE_PAIRS#" index="kvpNum">
							<th>MEDIA_LABEL_#kvpNum#</th>
							<th>LABEL_VALUE_#kvpNum#</th>
						</cfloop>
					</tr>
				<tbody>
					<cfloop query="problemData">
						<tr>
							<td>
								<cfif len(problemData.status) eq 0>
									Cleared to load
								<cfelse>
									<strong>#problemData.status#</strong>
								</cfif>
							</td>
							<td>#problemData.MEDIA_URI#</td>
							<td>#problemData.MIME_TYPE#</td>
							<td>#problemData.MEDIA_TYPE#</td>
							<td>#problemData.SUBJECT#</td>
							<td>#problemData.MADE_DATE#</td>
							<td>#problemData.DESCRIPTION#</td>
							<td>#problemData.HEIGHT#</td>
							<td>#problemData.WIDTH#</td>
							<td>#problemData.PREVIEW_URI#</td>
							<td>#problemData.MEDIA_LICENSE_ID#</td>
							<td>#problemData.MASK_MEDIA#</td>
							<cfloop from="1" to="#NUMBER_OF_RELATIONSHIP_PAIRS#" index="relNum">
								<td>#evaluate("problemData.MEDIA_RELATIONSHIP_"&relNum)#</td>
								<td>#evaluate("problemData.MEDIA_RELATED_TO_"&relNum)#</td>
							</cfloop>
							<cfloop from="1" to="#NUMBER_OF_LABEL_VALUE_PAIRS#" index="kvpNum">
								<td>#evaluate('problemData.MEDIA_LABEL_'&kvpNum)#</td>
								<td>#evaluate('problemData.LABEL_VALUE_'&kvpNum)#</td>
							</cfloop>
						</tr>
					</cfloop>
				</tbody>
			</table>
		
		</cfoutput>
	</cfif>

<!------------------------------------------------------->

	<cfif variables.action is "load">
		<h2 class="h4">Third step: Apply changes.</h2>
		<cfoutput>
			<div class="position-relative" style="padding-top: 22px;">
				<cfset problem_key = "">
				<cftransaction>
					<cftry>
						<cfquery name="getTempData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							SELECT * FROM cf_temp_media
							WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						</cfquery>
						<cfquery name="getCounts" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							SELECT 
								count(distinct media_uri) ctobj 
							FROM 
								cf_temp_media
							WHERE 
								username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						</cfquery>
						<cfset media_updates = 0>
						<cfif getTempData.recordcount EQ 0>
							<cfthrow message="You have no rows to load in the media bulkloader table (cf_temp_media). <a href='/tools/BulkloadMedia.cfm'>Start over</a>"><!--- " --->
						</cfif>
						<cfset successfullInserts = "">
						<cfset successfullInsertIDs = "">
						<cfloop query="getTempData">
							<!--- created_by_agent_id should have been filled in above, failover in case it was not --->
							<cfif len(getTempData.created_by_agent_id) EQ 0>
								<cfquery name="getAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									SELECT agent_id 
									FROM agent_name
									WHERE agent_name_type = 'login'
									AND agent_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
								</cfquery>
							<cfelse>
								<cfquery name="getAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									SELECT created_by_agent_id as agent_id
									FROM cf_temp_media
									WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
										AND key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getTempData.key#">
								</cfquery>
							</cfif>

							<cfset username = '#session.username#'>
							<cfset problem_key = getTempData.key>
							<cfquery name="mid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
								select sq_media_id.nextval nv from dual
							</cfquery>
							<cfset media_id=mid.nv>
							<cfset medialicenseid_local = 0>
							<cfif len(media_license_id) is 0>
								<cfset medialicenseid_local = 1>
							<cfelse>
								<cfset medialicenseid_local = media_license_id>
							</cfif>
							<cfset maskmedia_local = 0>
							<cfif len(mask_media) is 0>
								<cfset maskmedia_local = 0>
							<cfelse>
								<cfset maskmedia_local = mask_media>
							</cfif>
							<cfset apreview_uri = getTempData.preview_uri>
							<cfif len(getTempData.height) GT 0 
								AND len(getTempData.width) GT 0 
								AND len(preview_uri) EQ 0 
								AND getTempData.media_type EQ "image" 
								AND Find("https://mczbase.mcz.harvard.edu/specimen_images/",getTempData.media_uri) EQ 1
								AND Val(getTempData.width) GTE 400 
							>
								<!--- Generate a thumbnail link for on the iiif server --->
								<cfset apreview_uri = "https://iiif.mcz.harvard.edu/iiif/3/#media_id#/full/%5E400,/0/default.jpg">
							</cfif>
							<cfquery name="makeMedia" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#"  result="insResult">
								INSERT into media (
									media_id,
									media_uri,
									mime_type,
									media_type,
									preview_uri,
									media_license_id,
									mask_media_fg
								) VALUES (
									<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">,
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.media_uri#">,
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.mime_type#">,
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.media_type#">,
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#apreview_uri#">,
									<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#medialicenseid_local#">,
									<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#maskmedia_local#">
								)
							</cfquery>
							<cfif insResult.recordcount NEQ 1>
								<cfthrow message = "Insert of media record failed, insert query affected other than 1 row.">
							</cfif>
							<cfset hasCreatedByAgent = false>
							<!--- Add relationships --->
							<cfloop from="1" to="#NUMBER_OF_RELATIONSHIP_PAIRS#" index="relNo">
								<cfset rel = evaluate('getTempData.media_relationship_'&relNo) >
								<cfset relTo = evaluate('getTempData.media_related_to_'&relNo) >
								<!--- support special case handling for accessions, identify transaction_id from T prefix --->
								<cfif REFind('.* accn$',rel) GT 0 AND Left(relTo,1) EQ 'T'>
									<!--- if accession relationship, strip off leading T. --->
									<cfset relTo = Right(relTo,len(relTo)-1)>
								</cfif>
								<cfif len(rel) gt 0 AND len(relTo) GT 0>
									<cfif rel EQ "created by agent">
										<cfset hasCreatedByAgent = true>
									</cfif>
									<cfquery name="makeRelations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="RelResult">
										INSERT into media_relations (
											media_id,
											media_relationship,
											created_by_agent_id,
											RELATED_PRIMARY_KEY
										) VALUES (
											<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">,
											<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#rel#">,
											<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getAgent.agent_id#">,
											<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#relTo#">
										)
									</cfquery>
									<cfif relResult.recordcount NEQ 1>
										<cfthrow message = "Insert of relationship failed, insert query affected other than 1 row.">
									</cfif>
								</cfif>
							</cfloop>
							<cfquery name="makeLabels" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="LabResult">
								INSERT into media_labels (
									media_id,
									media_label,
									label_value,
									assigned_by_agent_id
								) VALUES (
									<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">,
									'Subject',
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.SUBJECT#">,	
									<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getAgent.agent_id#">
								)
							</cfquery>
							<cfquery name="makeLabels" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="LabResult">
								INSERT into media_labels (
									media_id,
									media_label,
									label_value,
									assigned_by_agent_id
								) VALUES (
									<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">,
									'description',
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.DESCRIPTION#">,	
									<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getAgent.agent_id#">
								)
							</cfquery>
							<cfquery name="makeLabels" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="LabResult">
								INSERT into media_labels (
									media_id,
									media_label,
									label_value,
									assigned_by_agent_id
								) VALUES (
									<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">,
									'made date',
									<cfqueryparam cfsqltype="CF_SQL_DATE" value="#getTempData.MADE_DATE#">,	
									<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getAgent.agent_id#">
								)
							</cfquery>
							<cfif len(getTempData.height) GT 0 and len(getTempData.width) GT 0 >
								<cfquery name="makeHeightLabel" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									insert into media_labels (
										media_id,
										MEDIA_LABEL,
										LABEL_VALUE,
										ASSIGNED_BY_AGENT_ID
									) values (
										<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">,
										'height',
										<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.height#">,
										<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getAgent.agent_id#">
									)
								</cfquery>
								<cfquery name="makeWidthLabel" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									insert into media_labels (
										media_id,
										MEDIA_LABEL,
										LABEL_VALUE,
										ASSIGNED_BY_AGENT_ID
									) values (
										<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">,
										'width',
										<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.width#">,
										<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getAgent.agent_id#">
									)
								</cfquery>
							</cfif>
							<cfif len(getTempData.MD5HASH) GT 0>
								<cfquery name="makehash" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									insert into media_labels (
										media_id,
										media_label,
										label_value,
										assigned_by_agent_id
									) values (
										<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">,
										'MD5HASH',
										<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getTempData.MD5HASH#">,
										<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getAgent.agent_id#">
									)
								</cfquery>
							</cfif>
							<cfloop index="kvpNum" from="1" to="#NUMBER_OF_LABEL_VALUE_PAIRS#">
								<cfif len(evaluate('getTempData.media_label_'&kvpNum)) gt 0>
									<cfset mediaLabel = evaluate('getTempData.media_label_'&kvpNum)>
									<cfset mediaLabelValue = evaluate('getTempData.label_value_'&kvpNum)>
									<cfif mediaLabel EQ "height" OR mediaLabel EQ "width"> 
										<!--- skip, height and width values are in getTempData.height and width after validation step --->
									<cfelseif len(trim(mediaLabel)) GT 0 AND len(trim(mediaLabelValue)) GT 0>
										<cfquery name="makeLabels" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="LabResult">
											INSERT into media_labels (
												media_id,
												media_label,
												label_value,
												assigned_by_agent_id
											) VALUES (
												<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#media_id#">,
												<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#mediaLabel#">,
												<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#mediaLabelValue#">,
												<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getAgent.agent_id#">
											)
										</cfquery>
									</cfif>
								</cfif>
							</cfloop>
							<cfset media_updates = media_updates + insResult.recordcount>
							<cfset successfullInserts = successfullInserts & '<p class="my-1">'><!--- ' --->
							<cfset successfullInserts = successfullInserts & '<a href="/media/#media_id#" target="_blank">#media_id#</a> '><!--- ' --->
							<cfset successfullInsertIDs = ListAppend(successfullInsertIDs,media_id)>
							<cfif len(getTempData.subject) gt 0>
								<cfset successfullInserts = successfullInserts & getTempData.subject>
							</cfif>
							<cfif len(getTempData.description) gt 0 AND getTempData.description NEQ getTempData.subject>
								<cfset successfullInserts = successfullInserts & '| #getTempData.description#'>
							</cfif> 
							<cfset successfullInserts = successfullInserts & '</p>'><!--- ' --->
						</cfloop>
						<cfif getTempData.recordcount eq media_updates>
							<h3 class="text-success position-absolute" style="top:0;">Success - loaded #media_updates# media records</h3>
							<div class="mt-2"><a href="/tools/BulkloadMedia.cfm">Bulkload More Media Records</a></div>
							<div class="mt-2"><a href="/media/findMedia.cfm?execute=true&method=getMedia&media_id=#successfullInsertIDs#">Show in media search</a></div>
							<div class="mt-2">
								#successfullInserts#
							</div>
						<cfelse>
							<cfthrow message="Undefined error loading media records.  [#getTempData.recordcount#] rows to add, but [#media_updates#] rows added.">
						</cfif>
						<cftransaction action="commit">
					<cfcatch>
						<cftransaction action="ROLLBACK">
						<h3>There was a problem adding media records. </h3>
						<cfquery name="getProblemData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							SELECT 
								STATUS,MEDIA_URI,MIME_TYPE,MEDIA_TYPE,SUBJECT,MADE_DATE,DESCRIPTION,PREVIEW_URI,CREATED_BY_AGENT_ID,HEIGHT,WIDTH,
								MEDIA_LICENSE_ID,MASK_MEDIA,
								<cfloop from="1" to="#NUMBER_OF_RELATIONSHIP_PAIRS#" index="rpi">
									MEDIA_RELATIONSHIP_#rpi#,MEDIA_RELATED_TO_#rpi#,
								</cfloop>
								<cfloop from="1" to="#NUMBER_OF_LABEL_VALUE_PAIRS#" index="lpi">
									MEDIA_LABEL_#lpi#,LABEL_VALUE_#lpi#,
								</cfloop>
								KEY, USERNAME
							FROM 
								cf_temp_media
							WHERE
								key = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#problem_key#"> AND
								username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						</cfquery>
						<cfif getProblemData.recordcount GT 0>
							<h3>
								Fix the issues and <a href="/tools/BulkloadMedia.cfm" class="text-danger font-weight-lessbold">start again</a>. Error loading row (<span class="text-danger">#media_updates + 1#</span>) from the CSV: 
								<cfif len(cfcatch.detail) gt 0>
									<span class="font-weight-normal border-bottom border-danger">
										<cfif cfcatch.detail contains "media_type">
											Problem with MEDIA_TYPE
										<cfelseif cfcatch.detail contains "media_uri">
											Duplicate MEDIA_URI
										<cfelseif cfcatch.detail contains "media_license_id">
											Problem with MEDIA_LICENSE_ID
										<cfelseif cfcatch.detail contains "mask_media">
											Invalid MASK_MEDIA number
										<cfelseif cfcatch.detail contains "integrity constraint">
											Invalid MEDIA_ID 
										<cfelseif cfcatch.detail contains "media_id">
											Problem with MEDIA_ID (#cfcatch.detail#)
										<cfelseif cfcatch.detail contains "unique constraint">
											Unique Constraint issue (#cfcatch.detail#)
										<cfelseif cfcatch.detail contains "media_label">
											Problem with a MEDIA_LABEL (#cfcatch.detail#)
										<cfelseif cfcatch.detail contains "label_value">
											Problem with a LABEL_VALUE (#cfcatch.detail#)
										<cfelseif cfcatch.detail contains "ListGetAt">
											Reload your spreadsheet: <a href='/tools/BulkloadMedia.cfm'>upload again</a>
										<cfelseif cfcatch.detail contains "date">
											Problem with MADE_DATE (#cfcatch.detail#)
										<cfelseif cfcatch.detail contains "media_relationship">
											Problem with a MEDIA_RELATIONSHIP (#cfcatch.detail#)
										<cfelseif cfcatch.detail contains "no data">
											No data or the wrong data (#cfcatch.detail#)
										<cfelse>
											<!--- provide the raw error message if it isn't readily interpretable --->
											#cfcatch.detail#
										</cfif>
									</span>
								</cfif>
							</h3>
							<table class='px-0 sortable small table table-responsive table-striped mt-3 w-100'>
								<thead>
									<tr>
										<th>COUNT</th>
										<th>MEDIA_URI</th>
										<th>MIME_TYPE</th>
										<th>MEDIA_TYPE</th>
										<th>SUBJECT</th>
										<th>MADE_DATE</th>
										<th>DESCRIPTION</th>
										<th>HEIGHT</th>
										<th>WIDTH</th>
										<th>PREVIEW_URI</th>
										<th>CREATED_BY_AGENT_ID</th>
										<th>MEDIA_LICENSE_ID</th>
										<th>MASK_MEDIA</th>
										<cfloop from="1" to="#NUMBER_OF_RELATIONSHIP_PAIRS#" index="relNum">
											<th>MEDIA_RELATIONSHIP_#relNum#</th>
											<th>MEDIA_RELATED_TO_#relNum#</th>
										</cfloop>
										<cfloop from="1" to="#NUMBER_OF_LABEL_VALUE_PAIRS#" index="kvpNum">
											<th>MEDIA_LABEL_#kvpNum#</th>
											<th>LABEL_VALUE_#kvpNum#</th>
										</cfloop>
									</tr> 
								</thead>
								<tbody>
									<cfset i=1>
									<cfloop query="getProblemData">
										<tr>
											<td>#i#</td>
											<td>#getProblemData.MEDIA_URI# </td>
											<td>#getProblemData.MIME_TYPE# </td>
											<td>#getProblemData.MEDIA_TYPE# </td>
											<td>#getProblemData.SUBJECT#</td>
											<td>#getProblemData.MADE_DATE#</td>
											<td>#getProblemData.DESCRIPTION#</td>
											<td>#getProblemData.HEIGHT#</td>
											<td>#getProblemData.WIDTH#</td>
											<td>#getProblemData.PREVIEW_URI# </td>
											<td>#getProblemData.CREATED_BY_AGENT_ID#</td>
											<td>#getProblemData.MEDIA_LICENSE_ID#</td>
											<td>#getProblemData.MASK_MEDIA#</td>
											<cfloop from="1" to="#NUMBER_OF_RELATIONSHIP_PAIRS#" index="relNum">
												<td>#evaluate("getProblemData.MEDIA_RELATIONSHIP_"&relNum)#</td>
												<td>#evaluate("getProblemData.MEDIA_RELATED_TO_"&relNum)#</td>a
											</cfloop>
											<cfloop from="1" to="#NUMBER_OF_LABEL_VALUE_PAIRS#" index="kvpNum">
												<td>#evaluate('getProblemData.MEDIA_LABEL_'&kvpNum)#</td>
												<td>#evaluate('getProblemData.LABEL_VALUE_'&kvpNum)#</td>
											</cfloop>
										</tr>
										<cfset i= i+1>
									</cfloop>
								</tbody>
							</table>
						</cfif>
						<div>#cfcatch.message#</div>
						<!--- always provide global admins with a dump --->
						<cfif isdefined("session.roles") and listfindnocase(session.roles,"global_admin")>
							<cfdump var="#cfcatch#">
						</cfif>
					</cfcatch>
					</cftry>
				</cftransaction>
			</div>
			<!--- cleanup any incomplete work by the same user --->
			<cfquery name="clearTempTable" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				DELETE from cf_temp_media WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
		</cfoutput>
	</cfif>
	<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_media")>
		<cfif variables.action is "pickTopDirectory">
			<cfquery name="collectionRoles" datasource="uam_god">
				SELECT
					granted_role role_name
				FROM
					dba_role_privs,
					collection
				WHERE
					upper(dba_role_privs.granted_role) = upper(collection.institution_acronym) || '_' || upper(collection.collection_cde) 
					and
					upper(grantee) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(session.username)#">
			</cfquery>
			<cfset collRoles = ValueList(collectionRoles.role_name)>
			<cfset drillList = "herpetology,ornithology,specialcollections,fish,mammalogy,entomology">
			<h2 class="h4">List all Media Files in a given Directory where the files have no matching Media records (or <a href="/tools/BulkloadMedia.cfm">start over</a>).</h2>
			<h3 class="h5">Step 1: Pick a high level directory on the shared storage from which to start:</h3>
			<cfoutput>
				<cfset directories = DirectoryList("#Application.webDirectory#/specimen_images/",false,"query","","Name ASC","dir")>
				<ul>
				<cfloop query="directories">
					<cfset show=true>
					<cfif directories.name EQ "cryogenic" AND listfindnocase(collRoles,"mcz_cryo") EQ 0><cfset show = false></cfif>
					<cfif directories.name EQ "ent-formicidae" AND listfindnocase(collRoles,"mcz_ent") EQ 0><cfset show = false></cfif>
					<cfif directories.name EQ "ent-lepidoptera" AND listfindnocase(collRoles,"mcz_ent") EQ 0><cfset show = false></cfif>
					<cfif directories.name EQ "entomology" AND listfindnocase(collRoles,"mcz_ent") EQ 0><cfset show = false></cfif>
					<cfif directories.name EQ "fish" AND listfindnocase(collRoles,"mcz_fish") EQ 0><cfset show = false></cfif>
					<cfif directories.name EQ "GlassInvertebrateModels" AND listfindnocase(collRoles,"mcz_sc") EQ 0><cfset show = false></cfif>
					<cfif directories.name EQ "specialcollections" AND listfindnocase(collRoles,"mcz_sc") EQ 0><cfset show = false></cfif>
					<cfif directories.name EQ "herpetology" AND listfindnocase(collRoles,"mcz_herp") EQ 0><cfset show = false></cfif>
					<cfif directories.name EQ "test" AND listfindnocase(collRoles,"collops") EQ 0><cfset show = false></cfif>
					<cfif directories.name EQ "publications" AND listfindnocase(collRoles,"collops") EQ 0><cfset show = false></cfif>
					<cfif directories.name EQ "invertebrates" AND listfindnocase(collRoles,"mcz_iz") EQ 0><cfset show = false></cfif>
					<cfif directories.name EQ "marineinverts" AND listfindnocase(collRoles,"mcz_iz") EQ 0><cfset show = false></cfif>
					<cfif directories.name EQ "invertpaleo" AND listfindnocase(collRoles,"mcz_ip") EQ 0><cfset show = false></cfif>
					<cfif directories.name EQ "malacology" AND listfindnocase(collRoles,"mcz_mala") EQ 0><cfset show = false></cfif>
					<cfif directories.name EQ "mammalogy" AND listfindnocase(collRoles,"mcz_mamm") EQ 0><cfset show = false></cfif>
					<cfif directories.name EQ "ornithology" AND listfindnocase(collRoles,"mcz_orn") EQ 0><cfset show = false></cfif>
					<cfif directories.name EQ "vertpaleo" AND listfindnocase(collRoles,"mcz_vp") EQ 0><cfset show = false></cfif>
					<cfif show>
						<cfif listContains(drillList,"#directories.name#")>
							<cfset nextDirectories = DirectoryList("#Application.webDirectory#/specimen_images/#directories.name#",false,"query","","Name ASC","dir")>
							<cfloop query="nextDirectories">
							
								<li><a href="/tools/BulkloadMedia.cfm?action=pickDirectory&path=#directories.name#%2F#nextDirectories.name#">#directories.name#/#nextDirectories.name#</a></li>
							</cfloop>
						<cfelse>
							<li><a href="/tools/BulkloadMedia.cfm?action=pickDirectory&path=#directories.name#">#directories.name#</a></li>
						</cfif>
					</cfif>
				</cfloop>
				</ul>
			</cfoutput>
		</cfif>
		<cfif variables.action is "pickDirectory">
			<cfset drillList = "herp,orni,spec">
			<h2 class="h4">List all Media Files in a given Directory where the files have no matching Media records (or <a href="/tools/BulkloadMedia.cfm">start over</a>).</h2>
			<h3 class="h5">Step 2: Pick a directory on the shared storage to check for files without media records:</h3>
			<cfoutput>
				<cfif len(REReplace(url.path,"[.]","")) EQ len(url.path)>
					<!--- DirectoryList and java File methods are slow on shared storage with many files, tree in shell is faster --->
					<cfexecute name="/usr/bin/tree" arguments='-d -f -i --noreport "#Application.webDirectory#/specimen_images/#path#"' variable="subdirectories" timeout="55">
					<ul>
						<cfloop list="#subdirectories#" delimiters="#chr(10)#" item="localPath">
							<cfset localPath = replace(localPath,"#Application.webDirectory#/specimen_images/","")>
							<li><a href="/tools/BulkloadMedia.cfm?action=listUnknowns&path=#encodeforUrl(localPath)#">#encodeForHtml(localPath)#</a></li>
						</cfloop>
					</ul>
				<cfelse>
					<cfthrow message="Error: Unknown top level directory">
				</cfif>
			</cfoutput>
		</cfif>
		<cfif variables.action is "listUnknowns">
			<cfoutput>
				<h2 class="h4">List all Media Files in a given Directory where the files have no matching Media records (or <a href="/tools/BulkloadMedia.cfm">start over</a>).</h2>
				<h3 class="h5">Step 3: List of files without media records in #encodeForHtml(url.path)#:</h3>
				<cfif NOT DirectoryExists("#Application.webDirectory#/specimen_images/#url.path#")>
					<cfthrow message="Error: Directory not found.">
				</cfif>
				<cfquery name="knownMedia" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
					SELECT 
						auto_path, auto_filename
					FROM
						media
					WHERE
						auto_path = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="/specimen_images/#url.path#/">
				</cfquery>
				<p>Number of known media: #knownMedia.recordcount# in shared storage directory #encodeForHtml(url.path)#</p>
				<cfset knownFiles = ValueList(knownMedia.auto_filename)>
				<cfset allFiles = DirectoryList("#Application.webDirectory#/specimen_images/#url.path#",false,"query","","datelastmodified DESC","file")>
				<!--- DirectoryList as query returns: Attributes, DateLastModified, Directory, Link, Mode, Name, Size, Type --->
				<cfset numberUnknown = 0>
				<cfloop query="allFiles">
					<cfif NOT ListContains(knownFiles,allFiles.Name)>
					<cfset localPath = Replace(allFiles.Directory,'#Application.webDirectory#/specimen_images/','')>
						#localPath#/#allFiles.Name# [#allFiles.size#]<br>
						<cfset numberUnknown = numberUnknown + 1>
					</cfif>
				</cfloop>
				<cfif numberUnknown EQ 0>
					<p>There are media records in MCZbase for all files in this directory.</p>
				<cfelse> 
					<p>There are #numberUnknown# files without corresponding MCZbase media records in the shared storage directory #encodeForHtml(url.path)#.</p>
					<p><a href="/tools/BulkloadMedia.cfm?action=getFileList&path=#url.path#">Download</a> a bulkloader sheet for these files.</p>
				</cfif>
			</cfoutput>
		</cfif>
	</cfif>
</main>
<cfinclude template="/shared/_footer.cfm">
