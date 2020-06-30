<!---
taxonomy/component/search.cfc

Copyright 2020 President and Fellows of Harvard College

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

<!---   Function getTaxa  --->
<cffunction name="getTaxa" access="remote" returntype="any" returnformat="json">
	<cfargument name="scientific_name" type="string" required="no">

	<cfset data = ArrayNew(1)>
	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			SELECT DISTINCT
				taxonomy.TAXON_NAME_ID as taxon_name_id,
				FULL_TAXON_NAME,
				kingdom,
				phylum,
				SUBPHYLUM,
				SUPERCLASS,
				PHYLCLASS,
				SUBCLASS,
				SUPERORDER,
				PHYLORDER,
				SUBORDER,
				INFRAORDER,
				SUPERFAMILY,
				FAMILY,
				SUBFAMILY,
				TRIBE,
				GENUS,
				SUBGENUS,
				SPECIES,
				SUBSPECIES,
				INFRASPECIFIC_RANK,
				SCIENTIFIC_NAME,
				AUTHOR_TEXT,
				display_name,
				NOMENCLATURAL_CODE,
				DIVISION,
				SUBDIVISION,
				INFRASPECIFIC_AUTHOR,
				VALID_CATALOG_TERM_FG,
				SOURCE_AUTHORITY,
				scientificnameid,
				taxonid,
				taxon_status,
				TAXON_REMARKS
			 from taxonomy
				left join common_name on taxonomy.taxon_name_id = common_name.taxon_name_id
			WHERE
				taxonomy.TAXON_NAME_ID is not null
				<cfif isdefined("scientific_name") AND len(scientific_name) gt 0>
					<cfif left(scientific_name,1) is "=">
						AND upper(scientific_name) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(scientific_name,len(scientific_name)-1))#">
					<cfelse>
						AND upper(scientific_name) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(scientific_name)#%">
					</cfif>
				</cfif>
		</cfquery>
		<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfset row["id_link"] = "<a href='/taxonomy/Taxonomy.cfm?action=edit&taxon_name_id=#search.taxon_name_id#' target='_blank'>#search.display_name#</a>">
			<cfset columnNames = ArrayToList(search.getColumnList())>
			<cfloop array="#columnNames#" index="col">
				<cfset row["#col#"] = "#search[columnName][currentrow]#">
			</cfloop>
			<cfset data[i] = row>
			<cfset i = i + 1>
		</cfloop>
		<cfreturn #serializeJSON(data)#>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset message = trim("Error processing getTransactions: " & cfcatch.message & " " & cfcatch.detail & " " & queryError) >
		<cfheader statusCode="500" statusText="#message#">
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn #serializeJSON(data)#>
</cffunction>

</cfcomponent>
