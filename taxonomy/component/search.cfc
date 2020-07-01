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
				<cfif isdefined("full_taxon_name") AND len(full_taxon_name) gt 0>
					<cfif left(full_taxon_name,1) is "=">
						AND upper(full_taxon_name) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(full_taxon_name,len(full_taxon_name)-1))#">
					<cfelse>
						AND upper(full_taxon_name) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(full_taxon_name)#%">
					</cfif>
				</cfif>
				<cfif isdefined("kingdom") AND len(kingdom) gt 0>
					<cfif left(kingdom,1) is "=">
						AND upper(kingdom) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(kingdom,len(kingdom)-1))#">
					<cfelse>
						AND upper(kingdom) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(kingdom)#%">
					</cfif>
				</cfif>
				<cfif isdefined("phylum") AND len(phylum) gt 0>
					<cfif left(phylum,1) is "=">
						AND upper(phylum) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(phylum,len(phylum)-1))#">
					<cfelse>
						AND upper(phylum) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(phylum)#%">
					</cfif>
				</cfif>
				<cfif isdefined("subphylum") AND len(subphylum) gt 0>
					<cfif left(subphylum,1) is "=">
						AND upper(subphylum) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(subphylum,len(subphylum)-1))#">
					<cfelse>
						AND upper(subphylum) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(subphylum)#%">
					</cfif>
				</cfif>
				<cfif isdefined("superclass") AND len(superclass) gt 0>
					<cfif left(superclass,1) is "=">
						AND upper(superclass) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(superclass,len(superclass)-1))#">
					<cfelse>
						AND upper(superclass) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(superclass)#%">
					</cfif>
				</cfif>
				<cfif isdefined("phylclass") AND len(phylclass) gt 0>
					<cfif left(phylclass,1) is "=">
						AND upper(phylclass) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(phylclass,len(phylclass)-1))#">
					<cfelse>
						AND upper(phylclass) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(phylclass)#%">
					</cfif>
				</cfif>
				<cfif isdefined("subclass") AND len(subclass) gt 0>
					<cfif left(subclass,1) is "=">
						AND upper(subclass) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(subclass,len(subclass)-1))#">
					<cfelse>
						AND upper(subclass) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(subclass)#%">
					</cfif>
				</cfif>
				<cfif isdefined("superorder") AND len(superorder) gt 0>
					<cfif left(superorder,1) is "=">
						AND upper(superorder) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(superorder,len(superorder)-1))#">
					<cfelse>
						AND upper(superorder) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(superorder)#%">
					</cfif>
				</cfif>
				<cfif isdefined("phylorder") AND len(phylorder) gt 0>
					<cfif left(phylorder,1) is "=">
						AND upper(phylorder) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(phylorder,len(phylorder)-1))#">
					<cfelse>
						AND upper(phylorder) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(phylorder)#%">
					</cfif>
				</cfif>
				<cfif isdefined("suborder") AND len(suborder) gt 0>
					<cfif left(suborder,1) is "=">
						AND upper(suborder) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(suborder,len(suborder)-1))#">
					<cfelse>
						AND upper(suborder) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(suborder)#%">
					</cfif>
				</cfif>
				<cfif isdefined("infraorder") AND len(infraorder) gt 0>
					<cfif left(infraorder,1) is "=">
						AND upper(infraorder) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(infraorder,len(infraorder)-1))#">
					<cfelse>
						AND upper(infraorder) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(infraorder)#%">
					</cfif>
				</cfif>
				<cfif isdefined("superfamily") AND len(superfamily) gt 0>
					<cfif left(superfamily,1) is "=">
						AND upper(superfamily) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(superfamily,len(superfamily)-1))#">
					<cfelse>
						AND upper(superfamily) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(superfamily)#%">
					</cfif>
				</cfif>
				<cfif isdefined("family") AND len(family) gt 0>
					<cfif left(family,1) is "=">
						AND upper(family) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(family,len(family)-1))#">
					<cfelse>
						AND upper(family) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(family)#%">
					</cfif>
				</cfif>
				<cfif isdefined("subfamily") AND len(subfamily) gt 0>
					<cfif left(subfamily,1) is "=">
						AND upper(subfamily) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(subfamily,len(subfamily)-1))#">
					<cfelse>
						AND upper(subfamily) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(subfamily)#%">
					</cfif>
				</cfif>
				<cfif isdefined("tribe") AND len(tribe) gt 0>
					<cfif left(tribe,1) is "=">
						AND upper(tribe) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(tribe,len(tribe)-1))#">
					<cfelse>
						AND upper(tribe) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(tribe)#%">
					</cfif>
				</cfif>
				<cfif isdefined("genus") AND len(genus) gt 0>
					<cfif left(genus,1) is "=">
						AND upper(genus) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(genus,len(genus)-1))#">
					<cfelse>
						AND upper(genus) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(genus)#%">
					</cfif>
				</cfif>
				<cfif isdefined("species") AND len(species) gt 0>
					<cfif left(species,1) is "=">
						AND upper(species) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(species,len(species)-1))#">
					<cfelse>
						AND upper(species) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(species)#%">
					</cfif>
				</cfif>
				<cfif isdefined("subspecies") AND len(subspecies) gt 0>
					<cfif left(subspecies,1) is "=">
						AND upper(subspecies) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(subspecies,len(subspecies)-1))#">
					<cfelse>
						AND upper(subspecies) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(subspecies)#%">
					</cfif>
				</cfif>
				<cfif isdefined("author_text") AND len(author_text) gt 0>
					<cfif left(author_text,1) is "=">
						AND upper(author_text) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(author_text,len(author_text)-1))#">
					<cfelse>
						AND upper(author_text) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(author_text)#%">
					</cfif>
				</cfif>
		</cfquery>
		<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfset row["id_link"] = "<a href='/taxonomy/Taxonomy.cfm?action=edit&taxon_name_id=#search.taxon_name_id#' target='_blank'>#search.display_name#</a>">
			<cfset columnNames = ListToArray(search.columnList)>
			<cfloop array="#columnNames#" index="columnName">
				<cfset row["#columnName#"] = "#search[columnName][currentrow]#">
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
