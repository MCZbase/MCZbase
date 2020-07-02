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
	<cfargument name="full_taxon_name" type="string" required="no">
	<cfargument name="common_name" type="string" required="no">
	<cfargument name="kingdom" type="string" required="no">
	<cfargument name="phylum" type="string" required="no">
	<cfargument name="subphylum" type="string" required="no">
	<cfargument name="superclass" type="string" required="no">
	<cfargument name="phylclass" type="string" required="no">
	<cfargument name="subclass" type="string" required="no">
	<cfargument name="superorder" type="string" required="no">
	<cfargument name="phylorder" type="string" required="no">
	<cfargument name="suborder" type="string" required="no">
	<cfargument name="infraorder" type="string" required="no">
	<cfargument name="superfamily" type="string" required="no">
	<cfargument name="family" type="string" required="no">
	<cfargument name="subfamily" type="string" required="no">
	<cfargument name="tribe" type="string" required="no">
	<cfargument name="genus" type="string" required="no">
	<cfargument name="subgenus" type="string" required="no">
	<cfargument name="species" type="string" required="no">
	<cfargument name="subspecies" type="string" required="no">
	<cfargument name="infraspecific_rank" type="string" required="no">
	<cfargument name="author_text" type="string" required="no">
	<cfargument name="taxon_status" type="string" required="no">
	<cfargument name="taxon_remarks" type="string" required="no">
	<cfargument name="nomenclatural_code" type="string" required="no">
	<cfargument name="division" type="string" required="no">
	<cfargument name="subdivision" type="string" required="no">
	<cfargument name="infraspecific_author" type="string" required="no">
	<cfargument name="valid_catalog_term_fg" type="string" required="no">
	<cfargument name="scientificnameid" type="string" required="no">
	<cfargument name="taxonid" type="string" required="no">

	<cfset data = ArrayNew(1)>
	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			SELECT 
				taxonomy.TAXON_NAME_ID as taxon_name_id,
				taxonomy.FULL_TAXON_NAME,
				taxonomy.kingdom,
				taxonomy.phylum,
				taxonomy.SUBPHYLUM,
				taxonomy.SUPERCLASS,
				taxonomy.PHYLCLASS,
				taxonomy.SUBCLASS,
				taxonomy.SUPERORDER,
				taxonomy.PHYLORDER,
				taxonomy.SUBORDER,
				taxonomy.INFRAORDER,
				taxonomy.SUPERFAMILY,
				taxonomy.FAMILY,
				taxonomy.SUBFAMILY,
				taxonomy.TRIBE,
				taxonomy.GENUS,
				taxonomy.SUBGENUS,
				taxonomy.SPECIES,
				taxonomy.SUBSPECIES,
				taxonomy.INFRASPECIFIC_RANK,
				taxonomy.SCIENTIFIC_NAME,
				taxonomy.AUTHOR_TEXT,
				taxonomy.display_name,
				taxonomy.NOMENCLATURAL_CODE,
				taxonomy.DIVISION,
				taxonomy.SUBDIVISION,
				taxonomy.INFRASPECIFIC_AUTHOR,
				case taxonomy.VALID_CATALOG_TERM_FG
					when null then '[No Flag]'
					when 1 then 'Yes'
					when 0 then 'No'
					else '[Error]'
					end
				as VALID_CATALOG_TERM_FG,
				taxonomy.SOURCE_AUTHORITY,
				taxonomy.scientificnameid,
				taxonomy.taxonid,
				taxonomy.taxon_status,
				taxonomy.TAXON_REMARKS,
				count(#session.flatTableName#.collection_object_id) as specimen_count
			 from taxonomy
				left join common_name on taxonomy.taxon_name_id = common_name.taxon_name_id
				left join identification_taxonomy on taxonomy.taxon_name_id = identification_taxonomy.taxon_name_id
				left join #session.flatTableName# on identification_taxonomy.identification_id = #session.flatTableName#.identification_id
			WHERE
				taxonomy.TAXON_NAME_ID is not null
				<cfif isdefined("scientific_name") AND len(scientific_name) gt 0>
					<cfif left(scientific_name,1) is "=">
						AND upper(taxonomy.scientific_name) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(scientific_name,len(scientific_name)-1))#">
					<cfelse>
						<cfif find(',',scientific_name) GT 0>
							AND upper(taxonomy.scientific_name) in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(scientific_name)#" list="yes"> )
						<cfelse>
							AND upper(taxonomy.scientific_name) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(scientific_name)#%">
						</cfif>
					</cfif>
				</cfif>
				<cfif isdefined("full_taxon_name") AND len(full_taxon_name) gt 0>
					<cfif left(full_taxon_name,1) is "=">
						AND upper(taxonomy.full_taxon_name) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(full_taxon_name,len(full_taxon_name)-1))#">
					<cfelse>
						AND upper(taxonomy.full_taxon_name) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(full_taxon_name)#%">
					</cfif>
				</cfif>
				<cfif isdefined("kingdom") AND len(kingdom) gt 0>
					<cfif left(kingdom,1) is "=">
						AND upper(taxonomy.kingdom) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(kingdom,len(kingdom)-1))#">
					<cfelse>
						AND upper(taxonomy.kingdom) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(kingdom)#%">
					</cfif>
				</cfif>
				<cfif isdefined("phylum") AND len(phylum) gt 0>
					<cfif left(phylum,1) is "=">
						AND upper(taxonomy.phylum) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(phylum,len(phylum)-1))#">
					<cfelse>
						AND upper(taxonomy.phylum) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(phylum)#%">
					</cfif>
				</cfif>
				<cfif isdefined("subphylum") AND len(subphylum) gt 0>
					<cfif left(subphylum,1) is "=">
						AND upper(taxonomy.subphylum) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(subphylum,len(subphylum)-1))#">
					<cfelse>
						AND upper(taxonomy.subphylum) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(subphylum)#%">
					</cfif>
				</cfif>
				<cfif isdefined("superclass") AND len(superclass) gt 0>
					<cfif left(superclass,1) is "=">
						AND upper(taxonomy.superclass) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(superclass,len(superclass)-1))#">
					<cfelse>
						AND upper(taxonomy.superclass) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(superclass)#%">
					</cfif>
				</cfif>
				<cfif isdefined("phylclass") AND len(phylclass) gt 0>
					<cfif left(phylclass,1) is "=">
						AND upper(taxonomy.phylclass) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(phylclass,len(phylclass)-1))#">
					<cfelse>
						AND upper(taxonomy.phylclass) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(phylclass)#%">
					</cfif>
				</cfif>
				<cfif isdefined("subclass") AND len(subclass) gt 0>
					<cfif left(subclass,1) is "=">
						AND upper(taxonomy.subclass) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(subclass,len(subclass)-1))#">
					<cfelse>
						AND upper(taxonomy.subclass) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(subclass)#%">
					</cfif>
				</cfif>
				<cfif isdefined("superorder") AND len(superorder) gt 0>
					<cfif left(superorder,1) is "=">
						AND upper(taxonomy.superorder) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(superorder,len(superorder)-1))#">
					<cfelse>
						AND upper(taxonomy.superorder) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(superorder)#%">
					</cfif>
				</cfif>
				<cfif isdefined("phylorder") AND len(phylorder) gt 0>
					<cfif left(phylorder,1) is "=">
						AND upper(taxonomy.phylorder) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(phylorder,len(phylorder)-1))#">
					<cfelse>
						AND upper(taxonomy.phylorder) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(phylorder)#%">
					</cfif>
				</cfif>
				<cfif isdefined("suborder") AND len(suborder) gt 0>
					<cfif left(suborder,1) is "=">
						AND upper(taxonomy.suborder) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(suborder,len(suborder)-1))#">
					<cfelse>
						AND upper(taxonomy.suborder) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(suborder)#%">
					</cfif>
				</cfif>
				<cfif isdefined("infraorder") AND len(infraorder) gt 0>
					<cfif left(infraorder,1) is "=">
						AND upper(taxonomy.infraorder) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(infraorder,len(infraorder)-1))#">
					<cfelse>
						AND upper(taxonomy.infraorder) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(infraorder)#%">
					</cfif>
				</cfif>
				<cfif isdefined("superfamily") AND len(superfamily) gt 0>
					<cfif left(superfamily,1) is "=">
						AND upper(taxonomy.superfamily) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(superfamily,len(superfamily)-1))#">
					<cfelse>
						AND upper(taxonomy.superfamily) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(superfamily)#%">
					</cfif>
				</cfif>
				<cfif isdefined("family") AND len(family) gt 0>
					<cfif left(family,1) is "=">
						AND upper(taxonomy.family) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(family,len(family)-1))#">
					<cfelse>
						<cfif find(',',family) GT 0>
							AND upper(taxonomy.family) in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(family)#" list="yes"> )
						<cfelse>
							AND upper(taxonomy.family) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(family)#%">
						</cfif>
					</cfif>
				</cfif>
				<cfif isdefined("subfamily") AND len(subfamily) gt 0>
					<cfif left(subfamily,1) is "=">
						AND upper(taxonomy.subfamily) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(subfamily,len(subfamily)-1))#">
					<cfelse>
						AND upper(taxonomy.subfamily) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(subfamily)#%">
					</cfif>
				</cfif>
				<cfif isdefined("tribe") AND len(tribe) gt 0>
					<cfif left(tribe,1) is "=">
						AND upper(taxonomy.tribe) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(tribe,len(tribe)-1))#">
					<cfelse>
						AND upper(taxonomy.tribe) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(tribe)#%">
					</cfif>
				</cfif>
				<cfif isdefined("genus") AND len(genus) gt 0>
					<cfif left(genus,1) is "=">
						AND upper(taxonomy.genus) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(genus,len(genus)-1))#">
					<cfelse>
						<cfif find(',',genus) GT 0>
							AND upper(taxonomy.genus) in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(genus)#" list="yes"> )
						<cfelse>
							AND upper(taxonomy.genus) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(genus)#%">
						</cfif>
					</cfif>
				</cfif>
				<cfif isdefined("subgenus") AND len(subgenus) gt 0>
					<cfif left(subgenus,1) is "=">
						AND upper(taxonomy.subgenus) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(subgenus,len(subgenus)-1))#">
					<cfelse>
						AND upper(taxonomy.subgenus) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(subgenus)#%">
					</cfif>
				</cfif>
				<cfif isdefined("species") AND len(species) gt 0>
					<cfif left(species,1) is "=">
						AND upper(taxonomy.species) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(species,len(species)-1))#">
					<cfelse>
						<cfif find(',',species) GT 0>
							AND upper(taxonomy.species) in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(species)#" list="yes"> )
						<cfelse>
							AND upper(taxonomy.species) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(species)#%">
						</cfif>
					</cfif>
				</cfif>
				<cfif isdefined("subspecies") AND len(subspecies) gt 0>
					<cfif left(subspecies,1) is "=">
						AND upper(taxonomy.subspecies) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(subspecies,len(subspecies)-1))#">
					<cfelse>
						AND upper(taxonomy.subspecies) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(subspecies)#%">
					</cfif>
				</cfif>
				<cfif isdefined("author_text") AND len(author_text) gt 0>
					<cfif left(author_text,1) is "=">
						AND upper(taxonomy.author_text) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(author_text,len(author_text)-1))#">
					<cfelse>
						AND upper(taxonomy.author_text) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(author_text)#%">
					</cfif>
				</cfif>
				<cfif isdefined("taxon_remarks") AND len(taxon_remarks) gt 0>
					<cfif left(taxon_remarks,1) is "=">
						AND upper(taxonomy.taxon_remarks) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(taxon_remarks,len(taxon_remarks)-1))#">
					<cfelse>
						AND upper(taxonomy.taxon_remarks) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(taxon_remarks)#%">
					</cfif>
				</cfif>
				<cfif isdefined("taxon_status") AND len(taxon_status) gt 0>
					AND taxonomy.taxon_status = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#taxon_status#">
				</cfif>
				<cfif isdefined("nomenclatural_code") AND len(nomenclatural_code) gt 0>
					AND taxonomy.nomenclatural_code = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#nomenclatural_code#">
				</cfif>
				<cfif isdefined("valid_catalog_term_fg") AND len(valid_catalog_term_fg) gt 0>
					AND taxonomy.valid_catalog_term_fg = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#valid_catalog_term_fg#">
				</cfif>
			GROUP BY
				taxonomy.TAXON_NAME_ID,
				taxonomy.FULL_TAXON_NAME,
				taxonomy.kingdom,
				taxonomy.phylum,
				taxonomy.SUBPHYLUM,
				taxonomy.SUPERCLASS,
				taxonomy.PHYLCLASS,
				taxonomy.SUBCLASS,
				taxonomy.SUPERORDER,
				taxonomy.PHYLORDER,
				taxonomy.SUBORDER,
				taxonomy.INFRAORDER,
				taxonomy.SUPERFAMILY,
				taxonomy.FAMILY,
				taxonomy.SUBFAMILY,
				taxonomy.TRIBE,
				taxonomy.GENUS,
				taxonomy.SUBGENUS,
				taxonomy.SPECIES,
				taxonomy.SUBSPECIES,
				taxonomy.INFRASPECIFIC_RANK,
				taxonomy.SCIENTIFIC_NAME,
				taxonomy.AUTHOR_TEXT,
				taxonomy.display_name,
				taxonomy.NOMENCLATURAL_CODE,
				taxonomy.DIVISION,
				taxonomy.SUBDIVISION,
				taxonomy.INFRASPECIFIC_AUTHOR,
				taxonomy.VALID_CATALOG_TERM_FG,
				taxonomy.SOURCE_AUTHORITY,
				taxonomy.scientificnameid,
				taxonomy.taxonid,
				taxonomy.taxon_status,
				taxonomy.TAXON_REMARKS
		</cfquery>
		<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfset row["id_link"] = "<a href='/taxonomy/Taxonomy.cfm?action=edit&taxon_name_id=#search.taxon_name_id#' target='_blank'>#search.display_name# #search.author_text#</a>">
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
