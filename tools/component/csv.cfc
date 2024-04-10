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

<cffunction name="checkRequiredFields" returntype="string" access="remote" returnformat="plain">
	<cfargument name="fieldList" type="string" required="yes">
	<cfargument name="requiredFieldList" type="string" required="yes">
	<cfargument name="NO_COLUMN_ERR" type="string" required="yes">

	<cfoutput>
		<!--- check for required fields in header line (performng check in two different ways, Case 1, Case 2), listing all fields. --->
		<!---  Throw exception and fail if any required fields are missing --->
		<cfset missingRequiredFields = "">
		<cfloop list="#fieldList#" item="aField">
			<cfif ListContainsNoCase(requiredFieldList,aField)>
				<!--- Case 1. Check by splitting assembled list of foundHeaders --->
				<cfif NOT ListContainsNoCase(foundHeaders,aField)>
					<cfset missingRequiredFields = ListAppend(missingRequiredFields,aField)>
				</cfif>
			</cfif>
		</cfloop>
		<ul class="mb-4 h4 font-weight-normal">
			<cfloop list="#fieldlist#" index="field" delimiters=",">
				<cfset hint="">
				<cfif listContains(requiredfieldlist,field,",")>
					<cfset class="text-danger">
					<cfset hint="aria-label='required'">
				<cfelse>
					<cfset class="text-dark">
				</cfif>
				<li class="pb-1">
					<span class="#class#" #hint#>#field#</span>
					<cfif arrayFindNoCase(colNameArray,field) GT 0>
						<span class="text-success font-weight-bold">Present in CSV</span>
					<cfelse>
						<!--- Case 2. Check by identifying field in required field list --->
						<cfif ListContainsNoCase(requiredFieldList,field)>
							<strong class="text-dark">Required Column Not Found</strong>
							<cfif NOT ListContains(missingRequiredFields,field)>
								<cfset missingRequiredFields = ListAppend(missingRequiredFields,field)>
							</cfif>
						</cfif>
					</cfif>
				</li>
			</cfloop>
		</ul>
		<cfset errorMessage = "">
		<cfloop list="#missingRequiredFields#" index="missingField">
			<cfset errorMessage = "#errorMessage#<li style='font-size: 1.1rem;'>#missingField#</li>">
		</cfloop>
		<cfif len(errorMessage) GT 0>
			<h3 class="h3">Error Messages</h3>
			<cfset errorMessage = "<h4 class='h4'>Columns not found:</h4><ul>#errorMessage#</ul>">
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
			<cfif NOT ListContainsNoCase(fieldList,aField)>
				<cfset containsAdditional=true>
				<cfset additionalCount = additionalCount+1>
			</cfif>
		</cfloop>
		<cfif NOT ListContainsNoCase(fieldList,aField)>
			<cfif additionalCount GT 1><cfset plural1="s"><cfelse><cfset plural1=""></cfif>
			<cfif additionalCount GT 1><cfset plural1a="are"><cfelse><cfset plural1a="is"></cfif>
			<h3 class="h4">Warning: Found #additionalCount# additional column header#plural1# in the CSV that #plural1a# not in the list of expected headers: </h3>
			<!--- Identify additional columns that will be ignored --->
			<ul class="pb-1 h4">
				<cfloop list="#foundHeaders#" item="aField">
					<cfif NOT ListContainsNoCase(fieldList,aField)>
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
					<cfif NOT ListContains(duplicateFields,aField)>
						<cfset duplicateFields = ListAppend(duplicateFields,aField)>
					</cfif>
				</cfif>
			</cfloop>
			<cfif duplicateCount GT 1><cfset plural1="s"><cfelse><cfset plural1=""></cfif>
			<cfif duplicateCount GT 1><cfset plural2=""><cfelse><cfset plural2="s"></cfif>
			<h3 class="h4">Error: Expected column header#plural1# occur#plural2# more than once: </h3>
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

</cfcomponent>
