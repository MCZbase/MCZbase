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
					<p>
						This tool will check if the names exist as taxon records in MCZbase, and optionally in the GBIF backbone taxonomy and/or WoRMS.
						Any columns other than SCIENTIFIC_NAME will be ignored.  SCIENTIFIC_NAME should contain just the canonical name 
						of the taxon, and should not include the authorship.  The tool will return a list of the names checked, and whether
						exact matches for them exist in MCZbase.  If the GBIF option is selected, it will also return matches to the name 
						in the GBIF backbone taxonomy.  If the WoRMS options is selected, it will also return matches to the name in WoRMS.
						The results can be returned as an HTML table or as a CSV file.  This tool does
						not alter the MCZbase database.  It may be used to check if all names in list of names exist as MCZbase taxonomy
						records before attempting to add them in an specimen bulkload or an identification upload.  A list of unique
						scientific names from the input data will be returned.  This tool will identify exact matches against MCZbase taxon record and matches against MCZbase taxon records using a taxon formula (as would apply if you are loading identifications into MCZbase using a taxon formula).
					</p>
					<p>
						To use this tool to check names in a Specimen Bulkloader CSV file, save the content of the TAXON_NAME column in a separate CSV file, rename it SCIENTIFIC_NAME, and check that file here.  You do not have to deduplicate the names in the file, this tool will do that for you and produce a report on the matches on unique names in your input file.  
					</p>
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
									<option value="WoRMS">WoRMS</option>
									<option value="ALL">GBIF Backbone Taxonomy and WoRMS</option>
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
		<cfquery name="ctTaxaFormula" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			SELECT taxa_formula,
				'^(' || replace(replace(replace(replace(replace(taxa_formula,'.','\.'),'(','\('),')','\)'), 'A', '.+)'),'B','(.+)') || '$' as regex
			FROM cttaxa_formula
			WHERE taxa_formula != 'A'
		</cfquery>
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
			<cfif form.remoteLookup EQ "GBIF" or form.remoteLookup EQ "ALL">
				<cfset variables.gbifLookup = true>
			<cfelse>
				<cfset variables.gbifLookup = false>
			</cfif>
			<cfif form.remoteLookup EQ "WoRMS" or form.remoteLookup EQ "ALL">
				<cfset variables.wormsLookup = true>
			<cfelse>
				<cfset variables.wormsLookup = false>
			</cfif>
		<cfelse>
			<cfset variables.gbifLookup = false>
			<cfset variables.wormsLookup = false>
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
					<main class="container-fluid py-3 px-xl-5" id="content">
						<h1 class="h2 mt-2">Check of scientific names against MCZbase taxonomy records</h1>
					   <p><a href="/dataquality/check_names.cfm">Start again</a></p>
						<div>
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
				<cfif variables.gbifLookup AND NOT variables.wormsLookup>
					<cfset ArrayAppend(resultsArray, "SCIENTIFIC_NAME,MCZBASE,MCZBASE_FORMULA,GBIF,GBIFWITHAUTH,MATCHDESCRIPTION")>
				<cfelseif variables.wormsLookup AND NOT variables.gbifLookup>
					<cfset ArrayAppend(resultsArray, "SCIENTIFIC_NAME,MCZBASE,MCZBASE_FORMULA,WORMS,WORMSWITHAUTH,MATCHDESCRIPTION")>
				<cfelseif variables.wormsLookup AND variables.gbifLookup>
					<cfset ArrayAppend(resultsArray, "SCIENTIFIC_NAME,MCZBASE,MCZBASE_FORMULA,GBIF,WORMS,GBIFWITHAUTH,WORMSWITHAUTH,GBIFMATCHDESCRIPTION,WORMSMATCHDESCRIPTION")>
				<cfelse>
					<cfset ArrayAppend(resultsArray, "SCIENTIFIC_NAME,MCZBASE,MCZBASE_FORMULA")>
				</cfif>
			<cfelse>
				<cfoutput>
					<table border="1">
						<thead>
							<tr>
								<th>Scientific Name</th>
								<th>MCZbase</th>
								<cfif variables.gbifLookup>
									<th>GBIF</th>
									<th>GBIF Match Description</th>
								</cfif>
								<cfif variables.wormsLookup>
									<th>WoRMS</th>
									<th>WoRMS Match Description</th>
								</cfif>
							</tr>
						</thead>
				</cfoutput>
			</cfif>
			<cfset evaluatedNames = "">
			<cfset distinctNameCount = 0>
			<cfset matchedNameCount = 0>
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
				</cfloop>
				<cfloop index="i" from="0" to="#rowData.size() - 1#">
					<cfloop from="1" to ="#ArrayLen(fieldArray)#" index="col">
						<cfif arrayFindNoCase(colNameArray,fieldArray[col]) GT 0>
							<cfset fieldPos=arrayFind(colNameArray,fieldArray[col])>
							<cfset val =trim(collValuesArray[fieldPos])>
							<cfset scientificName = val>
						</cfif>
					</cfloop>
				</cfloop>
				<cfif len(trim(scientificName)) GT 0 AND ListFind(evaluatedNames, scientificName,"|") EQ 0>
					<cfset evaluatedNames = ListAppend(evaluatedNames, scientificName,"|")>
					<cfset distinctNameCount = distinctNameCount + 1>
					<!--- Execute a query to check the scientific name against MCZbase taxonomy --->
					<cfquery name="checkScientificName" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="insert_result">
						SELECT  test_name, decode(t.scientific_name, null, 0, 1) as found,
							'full' as matchtype
						FROM 
							( SELECT <cfqueryparam value="#scientificName#" cfsqltype="CF_SQL_VARCHAR" maxlength="255"> as test_name FROM DUAL) d 
							LEFT JOIN taxonomy t
								ON t.scientific_name = <cfqueryparam value="#scientificName#" cfsqltype="CF_SQL_VARCHAR" maxlength="255">
					</cfquery>
					<cfset matchedFormula = "">
					<cfif checkScientificName.found EQ 0>
						<cfloop query="ctTaxaFormula">
							<cfset bitA = "">
							<cfif REFindNoCase(ctTaxaFormula.regex, scientificName) GT 0>
								<cfset matches = REFind(ctTaxaFormula.regex, scientificName,1,true)>
								<cfset bits = matches.MATCH>
								<!--- matches.MATCH will be an array with first element the full match, and subsequent elements the captured groups --->
								<cfif ctTaxaFormula.taxa_formula contains("B")>
									<cfif ArrayLen(bits) EQ 3>
										<cfset bitA = bits[2]>
										<cfset bitB = bits[3]>
									</cfif>
								<cfelse>
									<cfif ArrayLen(bits) EQ 2>
										<cfset bitA = bits[2]>
									</cfif>
								</cfif>
								<cfif len(bitA) GT 0>
									<cfset matchedFormula = ctTaxaFormula.taxa_formula>
									<cfquery name="checkScientificName" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="insert_result">
										SELECT  test_name, decode(t.scientific_name, null, 0, 1) as found,
											'formula' as matchtype
										FROM 
											( SELECT <cfqueryparam value="#scientificName#" cfsqltype="CF_SQL_VARCHAR" maxlength="255"> as test_name FROM DUAL) d 
											LEFT JOIN taxonomy t
												ON t.scientific_name = <cfqueryparam value="#bitA#" cfsqltype="CF_SQL_VARCHAR" maxlength="255">
									</cfquery>
								</cfif>
							</cfif>
						</cfloop>
					</cfif>
					<cfset gbifName = "">
					<cfset gbifNameWithAuth = "">
					<cfset wormsName = "">
					<cfset wormsNameWithAuth = "">
					<cfset gbifMatchDescription = "">
					<cfset wormsMatchDescription = "">
					<cfif variables.gbifLookup>
						<!--- Lookup name in GBIF Backbone taxonomy --->
						<cfobject type="Java" class="org.filteredpush.qc.sciname.services.Validator" name="validator">
						<!---
						<cfobject type="Java" class="org.filteredpush.qc.sciname.services.WoRMSService" name="wormsService">
						<cfobject type="Java" class="org.filteredpush.qc.sciname.services.IRMNGService" name="irmngService">
						--->
						<cfobject type="Java" class="org.filteredpush.qc.sciname.services.GBIFService" name="gbifService">
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
							<cfif isDefined("returnName") >
								<cfset r.MATCHDESCRIPTION = returnName.getMatchDescription()>
								<cfset r.SCIENTIFICNAME = returnName.getScientificName()>
								<cfset r.AUTHORSHIP = returnName.getAuthorship()>
								<cfset r.GUID = returnName.getGuid()>
								<cfset r.AUTHORSTRINGDISTANCE = returnName.getAuthorshipStringEditDistance()>
								<cfset r.HABITATFLAGS = "">
								<cfset gbifName = "#returnName.getScientificName()#">
								<cfset gbifNameWithAuth = "#returnName.getScientificName()# #returnName.getAuthorship()#">
							<cfelse>
								<cfset r.MATCHDESCRIPTION = "Not Found">
								<cfset r.SCIENTIFICNAME = "">
								<cfset r.AUTHORSHIP = "">
								<cfset r.GUID = "">
								<cfset r.AUTHORSTRINGDISTANCE = "">
								<cfset r.HABITATFLAGS = "">
								<cfset gbifName = "">
								<cfset gbifNameWithAuth = "">
							</cfif>
						<cfcatch>
							<cfset r.MATCHDESCRIPTION = "Error">
							<cfset r.SCIENTIFICNAME = "">
							<cfset r.AUTHORSHIP = "">
							<cfset r.GUID = "">
							<cfset r.AUTHORSTRINGDISTANCE = "">
							<cfset r.HABITATFLAGS = "">
							<cfset gbifName="">
							<cfset gbifNameWithAuth = "">
						</cfcatch>
						</cftry>
						<cfset gbifMatchDescription = r.MATCHDESCRIPTION>
						<cfset result["GBIF Backbone"] = r>
					</cfif>
					<cfif variables.wormsLookup>
						<!--- Lookup name in WoRMS --->
						<cfobject type="Java" class="org.filteredpush.qc.sciname.services.Validator" name="validator">
						<cfobject type="Java" class="org.filteredpush.qc.sciname.services.WoRMSService" name="wormsService">
						<!---
						<cfobject type="Java" class="org.filteredpush.qc.sciname.services.IRMNGService" name="irmngService">
						<cfobject type="Java" class="org.filteredpush.qc.sciname.services.GBIFService" name="gbifService">
						--->
						<cfobject type="Java" class="edu.harvard.mcz.nametools.NameUsage" name="nameUsage">
						<cfobject type="Java" class="edu.harvard.mcz.nametools.ICZNAuthorNameComparator" name="icznComparator">
		
						<cfset comparator = icznComparator.init(.75,.5)>
						<cfset lookupName = nameUsage.init()>
						<cfset lookupName.setScientificName(scientificName)>
						<cfset lookupName.setAuthorship("")>

						<!--- lookup in WoRMS --->
						<cfset wormsAuthority = wormsService.init(false)>
						<cfset r=structNew()>
						<cftry>
							<cfset returnName = wormsAuthority.validate(lookupName)>
							<cfif isDefined("returnName")>
								<cfset r.MATCHDESCRIPTION = returnName.getMatchDescription()>
								<cfset r.SCIENTIFICNAME = returnName.getScientificName()>
								<cfset r.AUTHORSHIP = returnName.getAuthorship()>
								<cfset r.GUID = returnName.getGuid()>
								<cfset r.AUTHORSTRINGDISTANCE = returnName.getAuthorshipStringEditDistance()>
								<cfset r.HABITATFLAGS = "">
								<cfset wormsName = "#returnName.getScientificName()#">
								<cfset wormsNameWithAuth = "#returnName.getScientificName()# #returnName.getAuthorship()#">
							<cfelse>
								<cfset r.MATCHDESCRIPTION = "Not Found">
								<cfset r.SCIENTIFICNAME = "">
								<cfset r.AUTHORSHIP = "">
								<cfset r.GUID = "">
								<cfset r.AUTHORSTRINGDISTANCE = "">
								<cfset r.HABITATFLAGS = "">
								<cfset wormsName = "">
								<cfset wormsNameWithAuth = "">
							</cfif>
						<cfcatch>
							<cfset r.MATCHDESCRIPTION = "Error">
							<cfset r.SCIENTIFICNAME = "">
							<cfset r.AUTHORSHIP = "">
							<cfset r.GUID = "">
							<cfset r.AUTHORSTRINGDISTANCE = "">
							<cfset r.HABITATFLAGS = "">
						</cfcatch>
						</cftry>
						<cfset wormsMatchDescription = r.MATCHDESCRIPTION>
						<cfset result["WoRMS"] = r>
					</cfif>

					<cfif checkScientificName.found EQ 1>
						<cfset matchedNameCount = matchedNameCount + 1>
					</cfif>

					<!--- Display the scientific name and its status --->
					<cfif asCSV>
						<cfset formula = "">
						<cfset foundState = checkScientificName.found>
						<cfif checkScientificName.found EQ 1>
							<cfif checkScientificName.matchtype EQ 'formula'>
								<cfset foundState = 2>
								<cfset formula = matchedFormula>
							</cfif>
						</cfif>
						<cfset gbifMatchDescription = replace(gbifMatchDescription, '"', '""', 'all')><!--- escape quotes for CSV --->
						<cfset wormsMatchDescription = replace(wormsMatchDescription, '"', '""', 'all')><!--- escape quotes for CSV --->
						<cfset gbifNameWithAuth = replace(gbifNameWithAuth, '"', '""', 'all')><!--- escape quotes for CSV --->
						<cfset wormsNameWithAuth = replace(wormsNameWithAuth, '"', '""', 'all')><!--- escape quotes for CSV --->
						<cfif variables.gbifLookup AND NOT variables.wormsLookup>
							<cfset ArrayAppend(resultsArray, '#scientificName#,#foundState#,#formula#,#gbifName#,"#gbifNameWithAuth#","#gbifMatchDescription#"')>
						<cfelseif variables.wormsLookup AND NOT variables.gbifLookup>
							<cfset ArrayAppend(resultsArray, '#scientificName#,#foundState#,#formula#,#wormsName#,"#wormsNameWithAuth#","#wormsMatchDescription#"')>
						<cfelseif variables.wormsLookup AND variables.gbifLookup>
							<cfset ArrayAppend(resultsArray, '#scientificName#,#foundState#,#formula#,#gbifName#,#wormsName#,"#gbifNameWithAuth#","#wormsNameWithAuth#","#gbifMatchDescription#","#wormsMatchDescription#"')>
						<cfelse>
							<cfset ArrayAppend(resultsArray, "#scientificName#,#foundState#,#formula#")>
						</cfif>
					<cfelse>
						<cfoutput>
							<tr>
								<td>#scientificName#</td>
								<td>
									<cfif checkScientificName.found EQ 1>
										<cfif checkScientificName.matchtype EQ 'formula'>
											Found (#matchedFormula#)
										<cfelse>
											Found
										</cfif>
									<cfelse>
										Not Found
									</cfif>
								</td>
								<cfif variables.gbifLookup>
									<td>#gbifNameWithAuth#</td>
									<td>#gbifMatchDescription#</td>
								</cfif>
								<cfif variables.wormsLookup>
									<td>#wormsNameWithAuth#</td>
									<td>#wormsMatchDescription#</td>
								</cfif>
							</tr>
						</cfoutput>
					</cfif>
					<cfset formula="">
					<cfset gibfName =  "">
					<cfset wormsName =  "">
					<cfset gibfNameWithAuth =  "">
					<cfset wormsNameWithAuth =  "">
				</cfif>
			</cfloop>
			<cfif asCSV>
				<cfoutput>#ArrayToList(resultsArray, Chr(13) & Chr(10))#</cfoutput>
			<cfelse>
				<cfoutput>
					</table>
					<h2>Results Summary</h2>
					<div>
						<p>Total distinct names evaluated: #distinctNameCount#</p>
						<p>Total names matched in MCZbase: #matchedNameCount#</p>
					</div>
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
			<cfoutput>
				</main>
				<cfinclude template="/shared/_footer.cfm">
			</cfoutput>
		</cfif>
	</cfcase>

</cfswitch>
