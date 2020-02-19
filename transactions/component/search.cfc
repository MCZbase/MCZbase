<!---
specimens/component/records_search.cfc

Copyright 2019 President and Fellows of Harvard College

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

<!---   Function getTransactions  --->
<cffunction name="getTransactions" access="remote" returntype="any" returnformat="json">
    <cfargument name="number" type="string" required="no">

	<cfset data = ArrayNew(1)>
	<cftry>
      <cfset rows = 0>
	    <cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			SELECT 
				transaction_id, trans_date, transaction_type,
				nature_of_material, trans_remarks,
				collection_cde, collection,
				specific_number, specific_type, status
			FROM 
				MCZBASE.transaction_view
			WHERE
				 transaction_id > 0 
		       <cfif isDefined("number") and len(number) gt 0>
                and specific_number like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#number#">
		       </cfif>
	    </cfquery>
      <cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfset row["transaction_id"] = "#search.transaction_id#">
			<cfset row["trans_date"] = "#search.trans_date#">
			<cfset row["transaction_type"] = "#search.transaction_type#">
			<cfset row["nature_of_material"] = "#search.nature_of_material#">
			<cfset row["trans_remarks"] = "#search.trans_remarks#">
			<cfset row["collection_cde"] = "#search.collection_cde#">
			<cfset row["collection"] = "#search.collection#">
			<cfset row["number"] = "#search.specific_number#">
			<cfset row["type"] = "#search.specific_type#">
			<cfset row["status"] = "#search.status#">
			<cfset data[i]  = row>
			<cfset i = i + 1>
		</cfloop>
		<cfreturn #serializeJSON(data)#>
	<cfcatch>
		<!--- <cfset row = StructNew()>
		<cfset row["error"] = "true">
		<cfset data[1]  = row>
      --->
      <cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
      <cfset message = trim("Error processing getTransactions: " & cfcatch.message & " " & cfcatch.detail & " " & queryError)  >
      <cfheader statusCode="500" statusText="#message#">
	   <cfabort>
	</cfcatch>
	</cftry>
	<cfreturn #serializeJSON(data)#>
</cffunction>

</cfcomponent>
