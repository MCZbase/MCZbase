<!---
Bulkloader/component/accessionFilter.cfc
Functions for filtering bulkloader records by accession number, including records with none.

Copyright 2026 President and Fellows of Harvard College

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
<!--- An accession list of the bulkloader pages is a comma separated list of accession numbers, in which
	the value of noAccessionValue() stands for records with no accession number; an empty list means
	any accession.  Included with runOnce; no method is remote. --->
<cfcomponent>

<!---
	noAccessionValue the value that stands for records with no accession number in an accession list.
	An empty value already means any accession; a bracketed word cannot be an accession number the
	bulkloader would load, where brackets only enclose a collection before the number.

	@return the value.
--->
<cffunction name="noAccessionValue" access="public" returntype="string" output="false">
	<cfreturn "[none]">
</cffunction>

<!---
	accessionNumbers the accession numbers in an accession list, without quotes and without the value
	for no accession number.

	@param accnList the accession list.
	@return a comma separated list of accession numbers, empty if there are none.
--->
<cffunction name="accessionNumbers" access="public" returntype="string" output="false">
	<cfargument name="accnList" type="string" required="yes">
	<cfset var numbers = "">
	<cfset var accnNumber = "">
	<!--- Quotes are stripped as on the callers; they were SQL string delimiters when lists were spliced into statements. --->
	<cfloop list="#replace(arguments.accnList, "'", "", "all")#" index="accnNumber">
		<cfif len(trim(accnNumber)) GT 0 AND trim(accnNumber) NEQ noAccessionValue()>
			<cfset numbers = listAppend(numbers, trim(accnNumber))>
		</cfif>
	</cfloop>
	<cfreturn numbers>
</cffunction>

<!---
	includesNoAccession whether an accession list asks for records with no accession number.

	@param accnList the accession list.
	@return true if the list holds the value for no accession number.
--->
<cffunction name="includesNoAccession" access="public" returntype="boolean" output="false">
	<cfargument name="accnList" type="string" required="yes">
	<cfreturn listFind(replace(arguments.accnList, "'", "", "all"), noAccessionValue()) GT 0>
</cffunction>

<!---
	describeAccessions the accessions of an accession list in words, for a page saying which records it shows.

	@param accnList the accession list, not empty.
	@return text such as "with accession number(s) 123, 456 or no accession number", not encoded.
--->
<cffunction name="describeAccessions" access="public" returntype="string" output="false">
	<cfargument name="accnList" type="string" required="yes">
	<cfset var numbers = accessionNumbers(arguments.accnList)>
	<cfset var description = "">
	<cfif len(numbers) GT 0>
		<cfset description = "with accession number(s) #replace(numbers, ',', ', ', 'all')#">
	</cfif>
	<cfif includesNoAccession(arguments.accnList)>
		<cfif len(description) GT 0>
			<cfset description = "#description# or no accession number">
		<cfelse>
			<cfset description = "with no accession number">
		</cfif>
	</cfif>
	<cfreturn description>
</cffunction>

</cfcomponent>
