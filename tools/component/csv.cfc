<!--- tools/component/csv.cfc functions to assist with csv parsing

Copyright 2024 President and Fellows of Harvard College

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
<cfcomponent>
<cf_rolecheck>
<cfif NOT isDefined("reportError")>
	<cfinclude template="/shared/component/error_handler.cfc" runOnce="true">
</cfif>

<!--- output a label and select where the options on the select match a set of java 
  StandardCharset names, and the select has name and id of characterSet.
  @see loadCsvFile for consumption of these option values.
--->
<cffunction name="getCharsetSelectHTML" returntype="string" access="remote" returnformat="plain">
	<cfoutput>
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
	</cfoutput>
</cffunction>

<!--- output a label and select where the options on the select match a set of CSVFormat constants 
  and the select has name and id of format.
  @see loadCsvFile for consumption of these option values.
--->
<cffunction name="getFormatSelectHTML" returntype="string" access="remote" returnformat="plain">
	<cfoutput>
		<label for="format" class="data-entry-label">Format:</label> 
		<select name="format" id="format" required class="data-entry-select reqdClr">
			<option value="DEFAULT" selected >Standard CSV</option>
			<option value="TDF">Tab Separated Values</option>
			<option value="EXCEL">CSV export from MS Excel</option>
			<option value="RFC4180">Strict RFC4180 CSV</option>
			<option value="ORACLE">Oracle SQL*Loader CSV</option>
			<option value="MYSQL">CSV export from MYSQL</option>
		</select>
	</cfoutput>
</cffunction>

<!--- given a file name, format, and characterset, load the file and return an iterator
  through commons csv CSVRecords for lines in the file after the header, having consumed
  the first line and placing a list of found headers in variables.foundHeaders and 
  the count of found headers in variables.size

 @param FileToUpload filename and path to the file to process.
 @param format the format for the file, using a value matched to CSVFormat constants.
 @param characterSet the character set for the file, using a value matched in java StandardCharsets.
 @return iterator through CSVRecords for lines after the header.
   sets variables.foundHeaders
   sets variables.size
 @see getFormatSelectHTML for formats that must be supported.
 @see getCharsetSelectHTML for character sets that must be supported.
--->
<cffunction name="loadCsvFile" returntype="string" access="remote" returnformat="plain">
	<cfargument name="FileToUpload" type="string" required="yes">
	<cfargument name="format" type="string" required="yes">
	<cfargument name="characterSet" type="string" required="yes">

	<cfoutput>
		<cfif arguments.format EQ "DEFAULT"><cfset fmt="CSV: Default Comma Separated values"><cfelse><cfset fmt="#arguments.format#"></cfif>
		<h4>Reading with character set: #encodeForHtml(characterSet)# and format: #encodeForHtml(fmt)#</h4>
		<!--- Parse the CSV file using Apache Commons CSV library included with coldfusion so that columns with comma delimeters will be separated properly --->
		<cfset fileProxy = CreateObject("java","java.io.File") >
		<cfobject type="Java" name="csvFormat" class="org.apache.commons.csv.CSVFormat" >
		<cfobject type="Java" name="csvParser" class="org.apache.commons.csv.CSVParser" >
		<cfobject type="Java" name="csvRecord" class="org.apache.commons.csv.CSVRecord" >			
		<cfobject type="java" class="java.io.FileReader" name="fileReader">	
		<cfobject type="Java" name="javaCharset" class="java.nio.charset.Charset" >
		<cfobject type="Java" name="standardCharsets" class="java.nio.charset.StandardCharsets" >
		<cfset filePath = fileProxy.init(JavaCast("string",#FiletoUpload#)) >
		<cfset tempFileInputStream = CreateObject("java","java.io.FileInputStream").Init(#filePath#) >
		<!--- Create a FileReader object to provide a reader for the CSV file --->
		<cfset fileReader = CreateObject("java","java.io.FileReader").Init(#filePath#) >
		<!--- we can not use the withHeader() method from coldfusion, as it is overloaded, and with no parameters provides coldfusion no means to pick the correct method --->
		<!--- Select format of csv file based on format variable from user --->
		<cfif not isDefined("format")><cfset format="DEFAULT"></cfif>
		<cfswitch expression="#format#">
			<cfcase value="DEFAULT">
				<cfset csvFormat = CSVFormat.DEFAULT>
			</cfcase>
			<cfcase value="TDF">
				<cfset csvFormat = CSVFormat.TDF>
			</cfcase>
			<cfcase value="RFC4180">
				<cfset csvFormat = CSVFormat.RFC4180>
			</cfcase>
			<cfcase value="EXCEL">
				<cfset csvFormat = CSVFormat.EXCEL>
			</cfcase>
			<cfcase value="ORACLE">
				<cfset csvFormat = CSVFormat.ORACLE>
			</cfcase>
			<cfcase value="MYSQL">
				<cfset csvFormat = CSVFormat.MYSQL>
			</cfcase>
			<cfdefaultcase>
				<cfset csvFormat = CSVFormat.DEFAULT>
			</cfdefaultcase>
		</cfswitch>
		<!--- Create a CSVParser using the FileReader and CSVFormat--->
		<cfset csvParser = CSVParser.parse(fileReader, csvFormat)>
		<!--- Select charset based on characterSet variable from user --->
		<cfswitch expression="#characterSet#">
			<cfcase value="utf-8">
				<cfset javaSelectedCharset = standardCharsets.UTF_8 >
			</cfcase>
			<cfcase value="iso-8859-1">
				<cfset javaSelectedCharset = standardCharsets.ISO_8859_1 >
			</cfcase>
			<cfcase value="windows-1250">
				<cfset javaSelectedCharset = javaCharset.forName(JavaCast("string","windows-1250")) >
			</cfcase>
			<cfcase value="windows-1251">
				<cfset javaSelectedCharset = javaCharset.forName(JavaCast("string","windows-1251")) >
			</cfcase>
			<cfcase value="windows-1252">
				<cfif javaCharset.isSupported(JavaCast("string","windows-1252"))>
					<cfset javaSelectedCharset = javaCharset.forName(JavaCast("string","windows-1252")) >
				<cfelse>
					<!--- if not available, iso-8859-1 will substitute, except for 0x80 to 0x9F --->
					<!--- the following characters won't be handled correctly if the source is windows-1252:  €  Š  š  Ž  ž  Œ  œ  Ÿ --->
					<cfset javaSelectedCharset = standardCharsets.ISO_8859_1 >
				</cfif>
			</cfcase>
			<cfcase value="x-MacCentralEurope">
				<cfset javaSelectedCharset = javaCharset.forName(JavaCast("string","x-MacCentralEurope")) >
			</cfcase>
			<cfcase value="MacRoman">
				<cfset javaSelectedCharset = javaCharset.forName(JavaCast("string","x-MacRoman")) >
			</cfcase>
			<cfcase value="utf-16">
				<cfset javaSelectedCharset = standardCharsets.UTF_16 >
			</cfcase>
			<cfcase value="utf-32">
				<cfset javaSelectedCharset = javaCharset.forName(JavaCast("string","utf-32")) >
			</cfcase>
			<cfdefaultcase>
				<cfset javaSelectedCharset = standardCharsets.UTF_8 >
			</cfdefaultcase>
		</cfswitch>
		<cfset records = CSVParser.parse(#tempFileInputStream#,#javaSelectedCharset#,#csvFormat#)>
		<!--- obtain an iterator to loops through the rows/records in the csv --->
		<cfset iterator = records.iterator()>
		<!---Obtain the first line of the file as the header line, we can not use the withHeader() method to do this in coldfusion --->
		<cfif iterator.hasNext()>
			<cfset headers = iterator.next()>
		<cfelse>
			<cfthrow message="#NO_HEADER_ERR# No first line found.">
		</cfif>
		<!---Get the number of column headers--->
		<cfset variables.size = headers.size()>
		<cfif variables.size EQ 0>
			<cfthrow message="#NO_HEADER_ERR# First line appears empty.">
		</cfif>
		<cfset separator = "">
		<cfset variables.foundHeaders = "">
		<cfloop index="i" from="0" to="#headers.size() - 1#">
			<cfset bit = headers.get(JavaCast("int",i))>
			<cfif i EQ 0 and characterSet EQ 'utf-8'>
				<!--- strip off windows non-standard UTF-8-BOM byte order mark if present (raw hex EF, BB, BF or U+FEFF --->
				<cfset bit = "#Replace(bit,CHR(65279),'')#" >
			</cfif>
			<!--- we could strip out all unexpected characters from the header, but seems likely to cause problems. --->
			<!--- cfset bit=REReplace(headers.get(JavaCast("int",i)),'[^A-Za-z0-9_-]','','All') --->
			<cfset variables.foundHeaders = "#foundHeaders##separator##bit#" >
			<cfset separator = ",">
		</cfloop>
	</cfoutput>
	<cfreturn iterator>
</cffunction>

<!--- given a list of provided fields and a list of required fields, check that all required
  fields are present in the provided list, and if not, throw an exception where the message
  includes a provided text string that identifies the exception.
--->
<cffunction name="checkRequiredFields" returntype="string" access="remote" returnformat="plain">
	<cfargument name="fieldList" type="string" required="yes">
	<cfargument name="requiredFieldList" type="string" required="yes">
	<cfargument name="NO_COLUMN_ERR" type="string" required="yes">
	<cfargument name="TABLE_NAME" type="string" required="yes">

	<cfoutput>
		<!--- check for required fields in header line (performng check in two different ways, Case 1, Case 2), listing all fields. --->
		<!---  Throw exception and fail if any required fields are missing --->
		<cfset missingRequiredFields = "">
		<cfloop list="#fieldList#" item="aField">
			<cfif ListFindNoCase(requiredFieldList,aField) GT 0>
				<!--- Case 1. Check by splitting assembled list of foundHeaders --->
				<cfif ListFindNoCase(foundHeaders,aField) EQ 0>
					<cfset missingRequiredFields = ListAppend(missingRequiredFields,aField)>
				</cfif>
			</cfif>
		</cfloop>
		<table class='table table-responsive'>
			<cfloop list="#fieldlist#" index="field" delimiters=",">
				<cfset hint="">
				<cfquery name = "getComments"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#"  result="getComments_result">
					select comments 
						from sys.all_col_comments
					where 
						owner = 'MCZBASE'
					AND
						TABLE_NAME = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(TABLE_NAME)#" />
					AND
						column_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(field)#" />
				</cfquery>
				<cfset comment = "">
				<cfif getComments.recordcount GT 0>
					<cfset comment = getComments.comments>
				</cfif>
				<cfif listContains(requiredfieldlist,field,",")>
					<cfset class="text-danger">
					<cfset hint="aria-label='required'">
				<cfelse>
					<cfset class="text-dark">
				</cfif>
				<tr>
					<td class="pl-xl-3">
						<cfif arrayFindNoCase(colNameArray,field) GT 0>
							<span class="text-success font-weight-bold">[&nbsp;Present&nbsp;in&nbsp;CSV&nbsp;]</span>
						<cfelse>
							<!--- Case 2. Check by identifying field in required field list --->
							<cfif ListFindNoCase(requiredFieldList,field) GT 0>
								<strong class="text-dark">[&nbsp;Required&nbsp;Column&nbsp;Not&nbsp;Found&nbsp;]</strong>
								<cfif ListFind(missingRequiredFields,field) EQ 0>
									<cfset missingRequiredFields = ListAppend(missingRequiredFields,field)>
								</cfif>
							<cfelse>
								<span class="text-warning font-weight-bold">[&nbsp;Not&nbsp;Found&nbsp;]</span>
							</cfif>
						</cfif>
					</td>
					<td class="pl-xl-1">
						<span class="#class# font-weight-lessbold pl-3" #hint#>#field#</span>
					</td>
					<td colspan="3" class="pl-xl-3">
						<span class="text-secondary">#comment#</span>
					</td>
				</tr>
			</cfloop>
		</table>
		<cfset errorMessage = "">
		<cfloop list="#missingRequiredFields#" index="missingField">
			<cfset errorMessage = "#errorMessage#<li style='font-size: 1.1rem;'>#missingField#</li>">
		</cfloop>
		<cfif len(errorMessage) GT 0>
			<h3 class="h3">Error Messages</h3>
			<cfset errorMessage = "<h4 class='h4'>Required Columns not found:</h4><ul>#errorMessage#</ul>">
			<cfif size EQ 1>
				<!--- Likely a problem parsing the first line into column headers --->
				<cfset errorMessage = "#errorMessage#<div>Only one column found, did you select the correct file format?</div>">
			</cfif>
 			<cfset errorMessage = "#errorMessage#<div>Check that headers exactly match the expected ones and that you have the correct encoding and file format.</div>"><!--- " --->
			<cfthrow message = "#NO_COLUMN_ERR# #errorMessage#">
		</cfif>
	</cfoutput>
</cffunction>

<cffunction name="checkAdditionalFields" returntype="string" access="remote" returnformat="plain">
	<cfargument name="fieldList" type="string" required="yes">

	<cfoutput>
		<!--- Test for additional columns not in list, warn and ignore. --->
		<cfset containsAdditional=false>
		<cfset additionalCount = 0>
		<cfloop list="#foundHeaders#" item="aField">
			<cfif ListFindNoCase(fieldList,aField) EQ 0>
				<cfset containsAdditional=true>
				<cfset additionalCount = additionalCount+1>
			</cfif>
		</cfloop>
		<cfif containsAdditional >
			<cfif additionalCount GT 1><cfset plural1="s"><cfelse><cfset plural1=""></cfif>
			<cfif additionalCount GT 1><cfset plural1a="are"><cfelse><cfset plural1a="is"></cfif>
			<h3 class="h4">Warning: Found #additionalCount# additional column header#plural1# in the CSV that #plural1a# not in the list of expected headers: </h3>
			<!--- Identify additional columns that will be ignored --->
			<ul class="pb-1 h4">
				<cfloop list="#foundHeaders#" item="aField">
					<cfif ListFindNoCase(fieldList,aField) EQ 0>
						<li class="pb-1 text-dark">#aField#</1i>
					</cfif>
				</cfloop>
			</ul>
			<!--- Do not throw an exception, additional columns to be ignored are not fatal. --->
		</cfif>
	</cfoutput>
</cffunction>

<cffunction name="checkDuplicateFields" returntype="string" access="remote" returnformat="plain">
	<cfargument name="foundHeaders" type="string" required="yes">
	<cfargument name="DUP_COLUMN_ERR" type="string" required="yes">

	<cfoutput>
		<!--- Identify duplicate columns and fail if found --->
		<cfif NOT ListLen(ListRemoveDuplicates(foundHeaders)) EQ ListLen(foundHeaders)>
			<cfset duplicateCount = 0>
			<cfset duplicateFields = "">
			<cfloop list="#foundHeaders#" item="aField">
				<cfif listValueCount(foundHeaders,aField) GT 1>
					<cfset duplicateCount = duplicateCount + 1>
					<cfif ListFind(duplicateFields,aField) EQ 0>
						<cfset duplicateFields = ListAppend(duplicateFields,aField)>
					</cfif>
				</cfif>
			</cfloop>
			<cfif duplicateCount GT 1><cfset plural1="s"><cfelse><cfset plural1=""></cfif>
			<cfif duplicateCount GT 1><cfset plural2=""><cfelse><cfset plural2="s"></cfif>
			<h3 class="h4">Error: The following expected column header#plural1# occur#plural2# more than once: </h3>
			<ul class="pb-1 h4">
				<!--- Identify duplicate columns and fail if found --->
				<cfloop list="#duplicateFields#" item="aField">
					<li class="pb-1 text-dark">#aField#</1i>
				</cfloop>
			</ul>
			<!--- throw exception to gracefully abort processing. --->
			<cfthrow message = "#DUP_COLUMN_ERR#">
		</cfif>
	</cfoutput>
</cffunction>

<!--- Report on extended characters found in the data --->
<cffunction name="reportExtended" returntype="string" access="remote" returnformat="plain">
	<cfargument name="foundHighCount" type="string" required="yes">
	<cfargument name="foundHighAscii" type="string" required="yes">
	<cfargument name="foundMultiByte" type="string" required="yes">
	<cfargument name="linkTarget" type="string" required="yes">
	<cfargument name="inHeader" type="string" required="no" default="no">
	<cfoutput>
		<cfif foundHighCount GT 1><cfset plural="s"><cfelse><cfset plural=""></cfif>
		<h3 class="h4">
			<span class="text-danger">Check character set.</span>
			<cfif inHeader EQ "yes">
				Found characters with unexpected encoding in the header row. This is probably the cause of your error.
			<cfelse>
				Found characters where the encoding is probably important in the input data.
			</cfif>
		</h3>
		<div class="border py-2 px-3 mt-1 mb-2">
			<p>
				Showing #foundHighCount# example#plural#.  
				<cfif inHeader EQ "yes">
					Did you select utf-16 or unicode for the encoding for a file that does not have multibyte encoding?
				<cfelse>
					If these do not appear as the correct characters, the file likely has a different encoding from the one you selected and you probably want to <a href="#linkTarget#" class="text-danger">start again</a> this file selecting a different encoding. If these appear as expected, then you selected the correct encoding and can continue to validate or load.
				</cfif>
			</p>
			<ul class="p-1 pl-2 h4 list-unstyled">
				<!---These include the <li></li>--->
				#foundHighAscii# #foundMultiByte#
			</ul>
		</div>
	</cfoutput>
</cffunction>

</cfcomponent>
