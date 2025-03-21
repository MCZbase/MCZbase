<!--- dataquality/checknames.cfm to evaluate scientific names against MCZbase taxonomy

Copyright 2025 President and Fellows of Harvard College

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
<cfset pageTitle = "Check a list of names">

<!--- build lists of fields for CSV file and their types --->
<cfset fieldlist = "SCIENTIFIC_NAME">
<cfset fieldTypes = "CF_SQL_VARCHAR">
<cfset requiredfieldlist = "SCIENTIFIC_NAME">

<cfif isDefined("form.action")><cfset variables.action = form.action></cfif>
<cfif not isDefined("variables.action") OR len(variables.action) EQ 0>
	<cfset variables.action = "entryPoint">
</cfif>

<cfswitch expression="#variables.action#">
	<cfcase value="entryPoint">
		<cfinclude template="/shared/_header.cfm">
		<cfinclude template="/tools/component/csv.cfc" runOnce="true"><!--- for common csv testing functions --->
		<cfoutput>
			<main class="container-fluid py-3 px-xl-5" id="content">
				<h1 class="h2 mt-2">Check scientific names against MCZbase taxonomy records</h1>
				<div>
					<h2 class="h4 mt-4">Upload a comma-delimited text file (csv) containing a SCIENTIFIC_NAME column</h2>
					<form name="csvform" method="post" enctype="multipart/form-data" action="/dataquality/check_names.cfm">
						<div class="form-row border rounded p-2">
							<input type="hidden" name="action" value="checkNames">
							<div class="col-12 col-md-4">
								<label for="fileToUpload" class="data-entry-label">File to check:</label> 
								<input type="file" name="FiletoUpload" id="fileToUpload" class="data-entry-input p-0 m-0 reqdClr" required>
							</div>
							<div class="col-12 col-md-3">
								<cfset charsetSelect = getCharsetSelectHTML(default="utf-8")>
							</div>
							<div class="col-12 col-md-3">
								<cfset formatSelect = getFormatSelectHTML()>
							</div>
							<div class="col-12 col-md-2">
								<label for="returnAsCSV" class="data-entry-label">Return as:</label>
								<select name="returnAsCSV" id="returnAsCSV" class="data-entry-input p-0 m-0 reqdClr">
									<option value="html" selected>HTML</option>
									<option value="csv">CSV</option>
								</select>
							</div>
							<div class="col-12 col-md-4">
								<label for="remoteLookup" class="data-entry-label">Also Look up in:</label>
								<select name="remoteLookup" id="remoteLookup" class="data-entry-input p-0 m-0">
									<option value="" selected></option>
									<option value="GBIF">GBIF Backbone Taxonomy</option>
								</select>
							</div>
							<div class="col-12 col-md-2">
								<label for="submitButton" class="data-entry-label">&nbsp;</label>
								<input type="submit" id="submittButton" value="Upload this file" class="btn btn-primary btn-xs">
							</div>
						</div>
					</form>
				</div>
			</main>
		</cfoutput>
		<cfinclude template="/shared/_footer.cfm">
	</cfcase>
	<cfcase value="checkNames">
		<!--- Set some constants to identify error cases in cfcatch block --->
		<cfset NO_COLUMN_ERR = "One or more required fields are missing in the header line of the csv file.">
		<cfset DUP_COLUMN_ERR = "One or more columns are duplicated in the header line of the csv file.">
		<cfset COLUMN_ERR = "Error inserting data">
		<cfset NO_HEADER_ERR = "No header line found, csv file appears to be empty.">

		<!--- get form variables --->
		<cfif isDefined("form.fileToUpload")><cfset variables.fileToUpload = form.fileToUpload></cfif>
		<cfif isDefined("form.format")><cfset variables.format = form.format></cfif>
		<cfif isDefined("form.characterSet")><cfset variables.characterSet = form.characterSet></cfif>
		<cfif isDefined("form.remoteLookup")>
			<cfif form.remoteLookup EQ "GBIF">
				<cfset variables.gbifLookup = true>
			<cfelse>
				<cfset variables.gbifLookup = false>
			</cfif>
		<cfelse>
			<cfset variables.gbifLookup = false>
		</cfif>

		<!--- if not returning as csv, include header --->
		<cfset asCsv = false>
		<cfif isDefined("form.returnAsCSV") and form.returnAsCSV EQ "csv">
			<cfset asCsv = true>
			<cfheader name="Content-Type" value="application/csv">
			<cfheader name="Content-Disposition" value="attachment; filename=checkNamesResults.csv">
		<cfelse>
			<cfinclude template="/shared/_header.cfm">
		</cfif>
		<cfinclude template="/tools/component/csv.cfc" runOnce="true"><!--- for common csv testing functions --->

		<cfset row = 0>
		<cftry>
			<cfset variables.foundHeaders =""><!--- populated by loadCsvFile --->
			<cfset variables.size=""><!--- populated by loadCsvFile --->
			<cfif NOT asCSV>
				<cfoutput>
					<cfset iterator = loadCsvFile(FileToUpload=FileToUpload,format=format,characterSet=characterSet)>			
				</cfoutput>
			<cfelse>
				<cfset iterator = loadCsvFileSilent(FileToUpload=FileToUpload,format=format,characterSet=characterSet)>			
			</cfif>
	
			<!--- Note: As we can't use csvFormat.withHeader(), we can not match columns by name, we are forced to do so by number, thus arrays --->
			<cfset colNameArray = listToArray(ucase(variables.foundHeaders))><!--- the list of columns/fields found in the input file --->
			<cfset fieldArray = listToArray(ucase(fieldlist))><!--- the full list of fields --->
			<cfset typeArray = listToArray(fieldTypes)><!--- the types for the full list of fields --->
			<cfif NOT asCSV>
				<cfoutput>
					<div class="col-12 my-4 px-0">
						<h3 class="h4">Found #variables.size# columns in header of csv file.</h3>
						There are #ListLen(fieldList)# columns expected in the header (of these #ListLen(requiredFieldList)# are required).
					</div>
				</cfoutput>
			</cfif>
			<!--- check for required fields in header line, list all fields, throw exception and fail if any required fields are missing --->
			<cfset TABLE_NAME = ""><!--- not used in this case --->
			<cfif NOT asCSV>
				<cfoutput>
					<cfset reqFieldsResponse = checkRequiredFields(fieldList=fieldList,requiredFieldList=requiredFieldList,NO_COLUMN_ERR=NO_COLUMN_ERR,TABLE_NAME=TABLE_NAME)>
				</cfoutput>
			<cfelse>
			</cfif>
			<cfset resultsArray = ArrayNew(1)>
			<!--- Create an HTML table to display the results --->
			<cfif asCSV>
				<cfset ArrayAppend(resultsArray, "SCIENTIFIC_NAME,MCZBASE")>
			<cfelse>
				<cfoutput>
					<table border="1">
						<thead>
							<tr>
								<th>Scientific Name</th>
								<th>MCZbase</th>
								<cfif variables.gbifLookup>
									<th>GBIF</th>
								</cfif>
							</tr>
						</thead>
				</cfoutput>
			</cfif>
			<cfloop condition="#iterator.hasNext()#">
				<!--- obtain the values in the current row --->
				<cfset rowData = iterator.next()>
				<cfset row = row + 1>
				<cfset columnsCountInRow = rowData.size()>
				<cfset collValuesArray= ArrayNew(1)>
				<cfset scientificName = "">
				<!--- loop through the columns in the row finding the scientific name column --->
				<cfloop index="i" from="0" to="#rowData.size() - 1#">
					<!--- loading cells from object instead of list allows commas inside cells --->
					<cfset thisBit = "#rowData.get(JavaCast('int',i))#" >
					<!--- store in a coldfusion array so we won't need JavaCast to reference by position --->
					<cfset ArrayAppend(collValuesArray,thisBit)>
					<cfloop from="1" to ="#ArrayLen(fieldArray)#" index="col">
						<cfif arrayFindNoCase(colNameArray,fieldArray[col]) GT 0>
							<cfset fieldPos=arrayFind(colNameArray,fieldArray[col])>
							<cfset val =trim(collValuesArray[fieldPos])>
							<cfset scientificName = val>
						</cfif>
					</cfloop>
				</cfloop>
				<cfif len(trim(scientificName)) GT 0>
					<!--- Execute a query to check the scientific name against MCZbase taxonomy --->
					<cfquery name="checkScientificName" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="insert_result">
						SELECT  test_name, decode(t.scientific_name, null, 0, 1) as found 
						FROM 
							( SELECT <cfqueryparam value="#scientificName#" cfsqltype="CF_SQL_VARCHAR" maxlength="255"> as test_name FROM DUAL) d 
							LEFT JOIN taxonomy t
								ON t.scientific_name = <cfqueryparam value="#scientificName#" cfsqltype="CF_SQL_VARCHAR" maxlength="255">
					</cfquery>
					<cfset gbifName = "">
					<cfif variables.gbifLookup>
						<!--- Lookup name in GBIF Backbone taxonomy --->
						<cfobject type="Java" class="org.filteredpush.qc.sciname.services.Validator" name="validator">
						<cfobject type="Java" class="org.filteredpush.qc.sciname.services.WoRMSService" name="wormsService">
						<cfobject type="Java" class="org.filteredpush.qc.sciname.services.GBIFService" name="gbifService">
						<cfobject type="Java" class="org.filteredpush.qc.sciname.services.IRMNGService" name="irmngService">
						<cfobject type="Java" class="edu.harvard.mcz.nametools.NameUsage" name="nameUsage">
						<cfobject type="Java" class="edu.harvard.mcz.nametools.ICZNAuthorNameComparator" name="icznComparator">
		
						<cfset comparator = icznComparator.init(.75,.5)>
						<cfset lookupName = nameUsage.init()>
						<cfset lookupName.setScientificName(scientificName)>
						<cfset lookupName.setAuthorship("")>

						<!--- lookup in GBIF Backbone --->
						<cfset gbifAuthority = gbifService.init()>
						<cfset r=structNew()>
						<cftry>
							<cfset returnName = gbifAuthority.validate(lookupName)>
						<cfcatch>
							<cfset r.MATCHDESCRIPTION = "Error">
							<cfset r.SCIENTIFICNAME = "">
							<cfset r.AUTHORSHIP = "">
							<cfset r.GUID = "">
							<cfset r.AUTHORSTRINGDISTANCE = "">
							<cfset r.HABITATFLAGS = "">
						</cfcatch>
						</cftry>
						<cfif isDefined("returnName")>
							<cfset r.MATCHDESCRIPTION = returnName.getMatchDescription()>
							<cfset r.SCIENTIFICNAME = returnName.getScientificName()>
							<cfset r.AUTHORSHIP = returnName.getAuthorship()>
							<cfset r.GUID = returnName.getGuid()>
							<cfset r.AUTHORSTRINGDISTANCE = returnName.getAuthorshipStringEditDistance()>
							<cfset r.HABITATFLAGS = "">
							<cfset gbifName = "#returnName.getScientificName()# #returnName.getAuthorship()#">
						</cfif>
						<cfset result["GBIF Backbone"] = r>
						
					</cfif>
					<!--- Display the scientific name and its status --->
					<cfif asCSV>
						<cfset ArrayAppend(resultsArray, "#scientificName#,#checkScientificName.found#")>
					<cfelse>
						<cfoutput>
							<tr>
								<td>#scientificName#</td>
								<td>
									<cfif checkScientificName.found EQ 1>
										Found
									<cfelse>
										Not Found
									</cfif>
								</td>
								<cfif variables.gbifLookup>
									<td>
										<cfif len(trim(gbifName)) GT 0>
											#gbifName#
										<cfelse>
											Not Matched
										</cfif>
									</td>
								</cfif>
							</tr>
						</cfoutput>
					</cfif>
				</cfif>
			</cfloop>
			<cfif asCSV>
				<cfoutput>#ArrayToList(resultsArray, Chr(13) & Chr(10))#</cfoutput>
			<cfelse>
				<cfoutput>
					</table>
				</cfoutput>
			</cfif>
		<cfcatch type="any">
			<cfif not isDefined("collNameArray")><cfset colNameArray = ArrayNew(1)></cfif>
			<cfif not isDefined("collValuesArray")><cfset collValuesArray = ArrayNew(1)></cfif>
			<cfoutput>
				<cfset error_message="<h4>Error reading line #row# in input file.  <br>Header:[#ArrayToList(colNameArray)#] <br>Row:[#ArrayToList(collValuesArray)#] <br>Error: #cfcatch.message#"><!--- " --->
				<cfif isDefined("cfcatch.queryError")>
					<cfset error_message = "#error_message# #cfcatch.queryError#">
				</cfif>
				<h3 class="h4">Error processing file</h3>
				<p>There was an error processing the file. Please check the file and try again.</p>
				#error_message#
				<cfif isdefined("session.roles") and listfindnocase(session.roles,"global_admin")>
					<cfdump var="#cfcatch#">
				</cfif>
			</cfoutput>
		</cfcatch>
		</cftry>
		<cfif NOT asCSV>
			<cfinclude template="/shared/_footer.cfm">
		</cfif>
	</cfcase>

</cfswitch>
