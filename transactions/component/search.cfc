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
		<cfif isDefined("number") and len(number) gt 0>
	    <cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			SELECT 
				transaction_id, trans_date, transaction_type,
				nature_of_material, trans_remarks,
				collection_cde, collection,
				num, type, status
			FROM 
				transactions_view
			WHERE 
             num = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#number#">
	    </cfquery>
		</cfif>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfset row["transaction_id"] = "#qryLoc.transaction_id#">
			<cfset row["trans_date"] = "#qryLoc.trans_date#">
			<cfset row["transaction_type"] = "#qryLoc.transaction_type#">
			<cfset row["nature_of_material"] = "#qryLoc.nature_of_material#">
			<cfset row["trans_remarks"] = "#qryLoc.trans_remarks#">
			<cfset row["collection_cde"] = "#qryLoc.collection_cde#">
			<cfset row["collection"] = "#qryLoc.collection#">
			<cfset row["number"] = "#qryLoc.num#">
			<cfset row["type"] = "#qryLoc.type#">
			<cfset row["status"] = "#qryLoc.status#">
			<cfset data[i]  = row>
			<cfset i = i + 1>
		</cfloop>
		<cfreturn #serializeJSON(data)#>
	<cfcatch>
		<!--- <cfset row = StructNew()>
		<cfset row["error"] = "true">
		<cfset data[1]  = row>
      --->
      <cfset message = "Error processing getTransactions: " & cfcatch.message & " " & cfcatch.detail & " " & cfcatch.queryError>
      <cfheader statusCode="500" statusText="#message#">
	   <cfabort>
	</cfcatch>
	</cftry>
	<cfreturn #serializeJSON(data)#>
</cffunction>

</cfcomponent>
