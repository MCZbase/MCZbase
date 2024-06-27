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
<cfinclude template="/shared/component/error_handler.cfc" runOnce="true">

<!--- Function getTaxa  --->
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
	<cfargument name="infraclass" type="string" required="no">
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
	<cfargument name="scientificnameid" type="string" required="no">
	<cfargument name="taxonid" type="string" required="no">
	<cfargument name="we_have_some" type="string" required="no"><!--- 1 or empty string, thus type string --->
	<cfargument name="valid_catalog_term_fg" type="string" required="no"><!--- 1 or empty string, thus type string --->
	<cfargument name="relationship" type="string" required="no">
	<cfargument name="taxon_habitat" type="string" required="no">

	<!--- clear values that are just an empty operator without a search term --->
	<cfif isdefined("scientific_name") AND scientific_name IS "="><cfset scientific_name=""></cfif>
	<cfif isdefined("scientific_name") AND scientific_name IS "~"><cfset scientific_name=""></cfif>
	<cfif isdefined("full_taxon_name") AND full_taxon_name IS "!"><cfset full_taxon_name=""></cfif>
	<cfif isdefined("common_name") AND common_name IS "="><cfset common_name=""></cfif>
	<cfif isdefined("kingdom") AND kingdom IS "="><cfset kingdom=""></cfif>
	<cfif isdefined("phylum") AND phylum IS "="><cfset phylum=""></cfif>
	<cfif isdefined("subphylum") AND subphylum IS "="><cfset subphylum=""></cfif>
	<cfif isdefined("superclass") AND superclass IS "="><cfset superclass=""></cfif>
	<cfif isdefined("phylclass") AND phylclass IS "="><cfset phylclass=""></cfif>
	<cfif isdefined("subclass") AND subclass IS "="><cfset subclass=""></cfif>
	<cfif isdefined("infraclass") AND infraclass IS "="><cfset infraclass=""></cfif>
	<cfif isdefined("superorder") AND superorder IS "="><cfset superorder=""></cfif>
	<cfif isdefined("phylorder") AND phylorder IS "="><cfset phylorder=""></cfif>
	<cfif isdefined("infraorder") AND infraorder IS "="><cfset infraorder=""></cfif>
	<cfif isdefined("superfamily") AND superfamily IS "="><cfset superfamily=""></cfif>
	<cfif isdefined("family") AND family IS "="><cfset family=""></cfif>
	<cfif isdefined("subfamily") AND subfamily IS "="><cfset subfamily=""></cfif>
	<cfif isdefined("tribe") AND tribe IS "="><cfset tribe=""></cfif>
	<cfif isdefined("genus") AND genus IS "="><cfset genus=""></cfif>
	<cfif isdefined("genus") AND genus IS "$"><cfset genus=""></cfif>
	<cfif isdefined("subgenus") AND subgenus IS "="><cfset subgenus=""></cfif>
	<cfif isdefined("subgenus") AND subgenus IS "$"><cfset subgenus=""></cfif>
	<cfif isdefined("species") AND species IS "="><cfset species=""></cfif>
	<cfif isdefined("species") AND species IS "$"><cfset species=""></cfif>
	<cfif isdefined("subspecies") AND subspecies IS "="><cfset subspecies=""></cfif>
	<cfif isdefined("subspecies") AND subspecies IS "$"><cfset subspecies=""></cfif>
	<cfif isdefined("author_text") AND author_text IS "="><cfset author_text=""></cfif>
	<cfif isdefined("author_text") AND author_text IS "$"><cfset author_text=""></cfif>
	<cfif isdefined("infraspecific_author") AND infraspecific_author IS "="><cfset infraspecific_author=""></cfif>
	<cfif isdefined("infraspecific_author") AND infraspecific_author IS "$"><cfset infraspecific_author=""></cfif>

	<!--- TODO: Support following relationship directions --->
	<cfset relationshipdirection = "forward">

	<cfset data = ArrayNew(1)>
	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="search_result" timeout="#Application.query_timeout#">
			SELECT 
				taxonomy.TAXON_NAME_ID as taxon_name_id,
				taxonomy.FULL_TAXON_NAME,
				taxonomy.kingdom,
				taxonomy.phylum,
				taxonomy.SUBPHYLUM,
				taxonomy.SUPERCLASS,
				taxonomy.PHYLCLASS,
				taxonomy.SUBCLASS,
				taxonomy.INFRACLASS,
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
				taxonomy.YEAR_OF_PUBLICATION,
				taxonomy.display_name,
				taxonomy.NOMENCLATURAL_CODE,
				taxonomy.DIVISION,
				taxonomy.SUBDIVISION,
				taxonomy.INFRASPECIFIC_AUTHOR,
				case taxonomy.VALID_CATALOG_TERM_FG
					when null then '[No Flag]'
					when 1 then 'Yes '
					when 0 then 'No '
					else '[Error]'
					end
				as VALID_CATALOG_TERM,
				taxonomy.SOURCE_AUTHORITY,
				taxonomy.scientificnameid,
				taxonomy.taxonid,
				taxonomy.taxon_status,
				taxonomy.TAXON_REMARKS,
				CONCATCOMMONNAME(taxonomy.TAXON_NAME_ID) as common_names,
				count(#session.flatTableName#.collection_object_id) as specimen_count
			 from taxonomy
				<cfif isdefined("common_name") AND len(common_name) gt 0>
					left join common_name on taxonomy.taxon_name_id = common_name.taxon_name_id
				</cfif>
				<cfif isdefined("taxon_habitat") AND len(taxon_habitat) gt 0>
					left join taxon_habitat on taxonomy.taxon_name_id = taxon_habitat.taxon_name_id
				</cfif>
				left join identification_taxonomy on taxonomy.taxon_name_id = identification_taxonomy.taxon_name_id
				left join #session.flatTableName# on identification_taxonomy.identification_id = #session.flatTableName#.identification_id
			WHERE
				taxonomy.TAXON_NAME_ID is not null
				<cfif isdefined("scientific_name") AND len(scientific_name) gt 0>
					<cfif left(scientific_name,1) is "=">
						AND upper(taxonomy.scientific_name) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(scientific_name,len(scientific_name)-1))#">
					<cfelseif left(scientific_name,1) is "~">
						AND utl_match.jaro_winkler(taxonomy.scientific_name, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(scientific_name,len(scientific_name)-1)#">) >= 0.90
					<cfelseif left(scientific_name,1) is "!~">
						AND utl_match.jaro_winkler(taxonomy.scientific_name, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(scientific_name,len(scientific_name)-1)#">) < 0.90
					<cfelseif left(scientific_name,1) is "!">
						AND upper(taxonomy.scientific_name) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(scientific_name,len(scientific_name)-1))#">
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
					<cfelseif left(full_taxon_name,1) is "!">
						AND upper(taxonomy.full_taxon_name) NOT LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(right(full_taxon_name,len(full_taxon_name)-1))#%">
					<cfelse>
						<cfif find(',',full_taxon_name) GT 0>
							AND upper(taxonomy.full_taxon_name) in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(full_taxon_name)#" list="yes"> )
						<cfelse>
							AND upper(taxonomy.full_taxon_name) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(full_taxon_name)#%">
						</cfif>
					</cfif>
				</cfif>
				<cfif isdefined("kingdom") AND len(kingdom) gt 0>
					<cfif left(kingdom,1) is "=">
						AND upper(taxonomy.kingdom) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(kingdom,len(kingdom)-1))#">
					<cfelseif left(kingdom,1) is "!">
						AND upper(taxonomy.kingdom) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(kingdom,len(kingdom)-1))#">
					<cfelseif kingdom is "NULL">
						AND upper(taxonomy.kingdom) is null
					<cfelseif kingdom is "NOT NULL">
						AND upper(taxonomy.kingdom) is not null
					<cfelse>
						<cfif find(',',kingdom) GT 0>
							AND upper(taxonomy.kingdom) in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(kingdom)#" list="yes"> )
						<cfelse>
							AND upper(taxonomy.kingdom) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(kingdom)#%">
						</cfif>
					</cfif>
				</cfif>
				<cfif isdefined("phylum") AND len(phylum) gt 0>
					<cfif left(phylum,1) is "=">
						AND upper(taxonomy.phylum) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(phylum,len(phylum)-1))#">
					<cfelseif left(phylum,1) is "$">
						AND soundex(taxonomy.phylum) = soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(phylum,len(phylum)-1))#">)
					<cfelseif left(phylum,2) is "!$">
						AND soundex(taxonomy.phylum) <> soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(phylum,len(phylum)-2))#">)
					<cfelseif left(phylum,1) is "!">
						AND upper(taxonomy.phylum) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(phylum,len(phylum)-1))#">
					<cfelseif phylum is "NULL">
						AND upper(taxonomy.phylum) is null
					<cfelseif phylum is "NOT NULL">
						AND upper(taxonomy.phylum) is not null
					<cfelse>
						<cfif find(',',phylum) GT 0>
							AND upper(taxonomy.phylum) in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(phylum)#" list="yes"> )
						<cfelse>
							AND upper(taxonomy.phylum) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(phylum)#%">
						</cfif>
					</cfif>
				</cfif>
				<cfif isdefined("subphylum") AND len(subphylum) gt 0>
					<cfif left(subphylum,1) is "=">
						AND upper(taxonomy.subphylum) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(subphylum,len(subphylum)-1))#">
					<cfelseif left(subphylum,1) is "$">
						AND soundex(taxonomy.subphylum) = soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(subphylum,len(subphylum)-1))#">)
					<cfelseif left(subphylum,2) is "!$">
						AND soundex(taxonomy.subphylum) <> soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(subphylum,len(subphylum)-2))#">)
					<cfelseif left(subphylum,1) is "!">
						AND upper(taxonomy.subphylum) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(subphylum,len(subphylum)-1))#">
					<cfelseif subphylum is "NULL">
						AND upper(taxonomy.subphylum) is null
					<cfelseif subphylum is "NOT NULL">
						AND upper(taxonomy.subphylum) is not null
					<cfelse>
						<cfif find(',',subphylum) GT 0>
							AND upper(taxonomy.subphylum) in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(subphylum)#" list="yes"> )
						<cfelse>
							AND upper(taxonomy.subphylum) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(subphylum)#%">
						</cfif>
					</cfif>
				</cfif>
				<cfif isdefined("superclass") AND len(superclass) gt 0>
					<cfif left(superclass,1) is "=">
						AND upper(taxonomy.superclass) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(superclass,len(superclass)-1))#">
					<cfelseif left(superclass,1) is "$">
						AND soundex(taxonomy.superclass) = soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(superclass,len(superclass)-1))#">)
					<cfelseif left(superclass,2) is "!$">
						AND soundex(taxonomy.superclass) <> soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(superclass,len(superclass)-2))#">)
					<cfelseif left(superclass,1) is "!">
						AND upper(taxonomy.superclass) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(superclass,len(superclass)-1))#">
					<cfelseif superclass is "NULL">
						AND upper(taxonomy.superclass) is null
					<cfelseif superclass is "NOT NULL">
						AND upper(taxonomy.superclass) is not null
					<cfelse>
						<cfif find(',',superclass) GT 0>
							AND upper(taxonomy.superclass) in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(superclass)#" list="yes"> )
						<cfelse>
							AND upper(taxonomy.superclass) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(superclass)#%">
						</cfif>
					</cfif>
				</cfif>
				<cfif isdefined("phylclass") AND len(phylclass) gt 0>
					<cfif left(phylclass,1) is "=">
						AND taxonomy.phylclass = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(phylclass,len(phylclass)-1)#">
					<cfelseif left(phylclass,1) is "$">
						AND soundex(taxonomy.phylclass) = soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(phylclass,len(phylclass)-1))#">)
					<cfelseif left(phylclass,2) is "!$">
						AND soundex(taxonomy.phylclass) <> soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(phylclass,len(phylclass)-2))#">)
					<cfelseif left(phylclass,1) is "!">
						AND upper(taxonomy.phylclass) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(phylclass,len(phylclass)-1))#">
					<cfelseif phylclass is "NULL">
						AND upper(taxonomy.phylclass) is null
					<cfelseif phylclass is "NOT NULL">
						AND upper(taxonomy.phylclass) is not null
					<cfelse>
						<cfif find(',',phylclass) GT 0>
							AND upper(taxonomy.phylclass) in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(phylclass)#" list="yes"> )
						<cfelse>
							AND upper(taxonomy.phylclass) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(phylclass)#%">
						</cfif>
					</cfif>
				</cfif>
				<cfif isdefined("subclass") AND len(subclass) gt 0>
					<cfif left(subclass,1) is "=">
						AND upper(taxonomy.subclass) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(subclass,len(subclass)-1))#">
					<cfelseif left(subclass,1) is "$">
						AND soundex(taxonomy.subclass) = soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(subclass,len(subclass)-1))#">)
					<cfelseif left(subclass,2) is "!$">
						AND soundex(taxonomy.subclass) <> soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(subclass,len(subclass)-2))#">)
					<cfelseif left(subclass,1) is "!">
						AND upper(taxonomy.subclass) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(subclass,len(subclass)-1))#">
					<cfelseif subclass is "NULL">
						AND upper(taxonomy.subclass) is null
					<cfelseif subclass is "NOT NULL">
						AND upper(taxonomy.subclass) is not null
					<cfelse>
						<cfif find(',',subclass) GT 0>
							AND upper(taxonomy.subclass) in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(subclass)#" list="yes"> )
						<cfelse>
							AND upper(taxonomy.subclass) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(subclass)#%">
						</cfif>
					</cfif>
				</cfif>
					<cfif isdefined("infraclass") AND len(infraclass) gt 0>
					<cfif left(infraclass,1) is "=">
						AND upper(taxonomy.infraclass) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(infraclass,len(infraclass)-1))#">
					<cfelseif left(infraclass,1) is "$">
						AND soundex(taxonomy.infraclass) = soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(infraclass,len(infraclass)-1))#">)
					<cfelseif left(infraclass,2) is "!$">
						AND soundex(taxonomy.infraclass) <> soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(infraclass,len(infraclass)-2))#">)
					<cfelseif left(infraclass,1) is "!">
						AND upper(taxonomy.infraclass) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(infraclass,len(infraclass)-1))#">
					<cfelseif infraclass is "NULL">
						AND upper(taxonomy.infraclass) is null
					<cfelseif infraclass is "NOT NULL">
						AND upper(taxonomy.infraclass) is not null
					<cfelse>
						<cfif find(',',infraclass) GT 0>
							AND upper(taxonomy.infraclass) in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(infraclass)#" list="yes"> )
						<cfelse>
							AND upper(taxonomy.infraclass) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(infraclass)#%">
						</cfif>
					</cfif>
				</cfif>
				<cfif isdefined("superorder") AND len(superorder) gt 0>
					<cfif left(superorder,1) is "=">
						AND upper(taxonomy.superorder) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(superorder,len(superorder)-1))#">
					<cfelseif left(superorder,1) is "$">
						AND soundex(taxonomy.superorder) = soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(superorder,len(superorder)-1))#">)
					<cfelseif left(superorder,2) is "!$">
						AND soundex(taxonomy.superorder) <> soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(superorder,len(superorder)-2))#">)
					<cfelseif left(superorder,1) is "!">
						AND upper(taxonomy.superorder) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(superorder,len(superorder)-1))#">
					<cfelseif superorder is "NULL">
						AND upper(taxonomy.superorder) is null
					<cfelseif superorder is "NOT NULL">
						AND upper(taxonomy.superorder) is not null
					<cfelse>
						<cfif find(',',superorder) GT 0>
							AND upper(taxonomy.superorder) in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(superorder)#" list="yes"> )
						<cfelse>
							AND upper(taxonomy.superorder) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(superorder)#%">
						</cfif>
					</cfif>
				</cfif>
				<cfif isdefined("phylorder") AND len(phylorder) gt 0>
					<cfif left(phylorder,1) is "=">
						AND upper(taxonomy.phylorder) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(phylorder,len(phylorder)-1))#">
					<cfelseif left(phylorder,1) is "$">
						AND soundex(taxonomy.phylorder) = soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(phylorder,len(phylorder)-1))#">)
					<cfelseif left(phylorder,2) is "!$">
						AND soundex(taxonomy.phylorder) <> soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(phylorder,len(phylorder)-2))#">)
					<cfelseif left(phylorder,1) is "!">
						AND upper(taxonomy.phylorder) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(phylorder,len(phylorder)-1))#">
					<cfelseif phylorder is "NULL">
						AND upper(taxonomy.phylorder) is null
					<cfelseif phylorder is "NOT NULL">
						AND upper(taxonomy.phylorder) is not null
					<cfelse>
						<cfif find(',',phylorder) GT 0>
							AND upper(taxonomy.phylorder) in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(phylorder)#" list="yes"> )
						<cfelse>
							AND upper(taxonomy.phylorder) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(phylorder)#%">
						</cfif>
					</cfif>
				</cfif>
				<cfif isdefined("suborder") AND len(suborder) gt 0>
					<cfif left(suborder,1) is "=">
						AND upper(taxonomy.suborder) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(suborder,len(suborder)-1))#">
					<cfelseif left(suborder,1) is "$">
						AND soundex(taxonomy.suborder) = soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(suborder,len(suborder)-1))#">)
					<cfelseif left(suborder,2) is "!$">
						AND soundex(taxonomy.suborder) <> soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(suborder,len(suborder)-2))#">)
					<cfelseif left(suborder,1) is "!">
						AND upper(taxonomy.suborder) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(suborder,len(suborder)-1))#">
					<cfelseif suborder is "NULL">
						AND upper(taxonomy.suborder) is null
					<cfelseif suborder is "NOT NULL">
						AND upper(taxonomy.suborder) is not null
					<cfelse>
						<cfif find(',',suborder) GT 0>
							AND upper(taxonomy.suborder) in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(suborder)#" list="yes"> )
						<cfelse>
							AND upper(taxonomy.suborder) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(suborder)#%">
						</cfif>
					</cfif>
				</cfif>
				<cfif isdefined("infraorder") AND len(infraorder) gt 0>
					<cfif left(infraorder,1) is "=">
						AND upper(taxonomy.infraorder) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(infraorder,len(infraorder)-1))#">
					<cfelseif left(infraorder,1) is "$">
						AND soundex(taxonomy.infraorder) = soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(infraorder,len(infraorder)-1))#">)
					<cfelseif left(infraorder,2) is "!$">
						AND soundex(taxonomy.infraorder) <> soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(infraorder,len(infraorder)-2))#">)
					<cfelseif left(infraorder,1) is "!">
						AND upper(taxonomy.infraorder) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(infraorder,len(infraorder)-1))#">
					<cfelseif infraorder is "NULL">
						AND upper(taxonomy.infraorder) is null
					<cfelseif infraorder is "NOT NULL">
						AND upper(taxonomy.infraorder) is not null
					<cfelse>
						<cfif find(',',infraorder) GT 0>
							AND upper(taxonomy.infraorder) in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(infraorder)#" list="yes"> )
						<cfelse>
							AND upper(taxonomy.infraorder) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(infraorder)#%">
						</cfif>
					</cfif>
				</cfif>
				<cfif isdefined("superfamily") AND len(superfamily) gt 0>
					<cfif left(superfamily,1) is "=">
						AND upper(taxonomy.superfamily) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(superfamily,len(superfamily)-1))#">
					<cfelseif left(superfamily,1) is "$">
						AND soundex(taxonomy.superfamily) = soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(superfamily,len(superfamily)-1))#">)
					<cfelseif left(superfamily,2) is "!$">
						AND soundex(taxonomy.superfamily) <> soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(superfamily,len(superfamily)-2))#">)
					<cfelseif left(superfamily,1) is "!">
						AND upper(taxonomy.superfamily) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(superfamily,len(superfamily)-1))#">
					<cfelseif superfamily is "NULL">
						AND upper(taxonomy.superfamily) is null
					<cfelseif superfamily is "NOT NULL">
						AND upper(taxonomy.superfamily) is not null
					<cfelse>
						<cfif find(',',superfamily) GT 0>
							AND upper(taxonomy.superfamily) in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(superfamily)#" list="yes"> )
						<cfelse>
							AND upper(taxonomy.superfamily) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(superfamily)#%">
						</cfif>
					</cfif>
				</cfif>
				<cfif isdefined("family") AND len(family) gt 0>
					<cfif left(family,1) is "=">
						AND upper(taxonomy.family) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(family,len(family)-1))#">
					<cfelseif left(family,1) is "$">
						AND soundex(taxonomy.family) = soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(family,len(family)-1))#">)
					<cfelseif left(family,2) is "!$">
						AND soundex(taxonomy.family) <> soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(family,len(family)-2))#">)
					<cfelseif left(family,1) is "!">
						AND upper(taxonomy.family) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(family,len(family)-1))#">
					<cfelseif family is "NULL">
						AND upper(taxonomy.family) is null
					<cfelseif family is "NOT NULL">
						AND upper(taxonomy.family) is not null
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
					<cfelseif left(subfamily,1) is "$">
						AND soundex(taxonomy.subfamily) = soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(subfamily,len(subfamily)-1))#">)
					<cfelseif left(subfamily,2) is "!$">
						AND soundex(taxonomy.subfamily) <> soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(subfamily,len(subfamily)-2))#">)
					<cfelseif left(subfamily,1) is "!">
						AND upper(taxonomy.subfamily) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(subfamily,len(subfamily)-1))#">
					<cfelseif subfamily is "NULL">
						AND upper(taxonomy.subfamily) is null
					<cfelseif subfamily is "NOT NULL">
						AND upper(taxonomy.subfamily) is not null
					<cfelse>
						<cfif find(',',subfamily) GT 0>
							AND upper(taxonomy.subfamily) in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(subfamily)#" list="yes"> )
						<cfelse>
							AND upper(taxonomy.subfamily) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(subfamily)#%">
						</cfif>
					</cfif>
				</cfif>
				<cfif isdefined("tribe") AND len(tribe) gt 0>
					<cfif left(tribe,1) is "=">
						AND upper(taxonomy.tribe) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(tribe,len(tribe)-1))#">
					<cfelseif left(tribe,1) is "$">
						AND soundex(taxonomy.tribe) = soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(tribe,len(tribe)-1))#">)
					<cfelseif left(tribe,2) is "!$">
						AND soundex(taxonomy.tribe) <> soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(tribe,len(tribe)-2))#">)
					<cfelseif left(tribe,1) is "!">
						AND upper(taxonomy.tribe) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(tribe,len(tribe)-1))#">
					<cfelseif tribe is "NULL">
						AND upper(taxonomy.tribe) is null
					<cfelseif tribe is "NOT NULL">
						AND upper(taxonomy.tribe) is not null
					<cfelse>
						<cfif find(',',tribe) GT 0>
							AND upper(taxonomy.tribe) in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(tribe)#" list="yes"> )
						<cfelse>
							AND upper(taxonomy.tribe) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(tribe)#%">
						</cfif>
					</cfif>
				</cfif>
				<cfif isdefined("genus") AND len(genus) gt 0>
					<cfif left(genus,1) is "=">
						AND upper(taxonomy.genus) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(genus,len(genus)-1))#">
					<cfelseif left(genus,1) is "$">
						AND soundex(taxonomy.genus) = soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(genus,len(genus)-1)#">)
					<cfelseif left(genus,2) is "!$">
						AND soundex(taxonomy.genus) <> soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(genus,len(genus)-2)#">)
					<cfelseif left(genus,1) is "!">
						AND upper(taxonomy.genus) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(genus,len(genus)-1))#">
					<cfelseif genus is "NULL">
						AND upper(taxonomy.genus) is null
					<cfelseif genus is "NOT NULL">
						AND upper(taxonomy.genus) is not null
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
					<cfelseif left(subgenus,1) is "$">
						AND soundex(taxonomy.subgenus) = soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(subgenus,len(subgenus)-1)#">)
					<cfelseif left(subgenus,2) is "!$">
						AND soundex(taxonomy.subgenus) <> soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(subgenus,len(subgenus)-2)#">)
					<cfelseif left(subgenus,1) is "!">
						AND upper(taxonomy.subgenus) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(subgenus,len(subgenus)-1))#">
					<cfelseif subgenus is "NULL">
						AND upper(taxonomy.subgenus) is null
					<cfelseif subgenus is "NOT NULL">
						AND upper(taxonomy.subgenus) is not null
					<cfelse>
						<cfif find(',',subgenus) GT 0>
							AND upper(taxonomy.subgenus) in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(subgenus)#" list="yes"> )
						<cfelse>
							AND upper(taxonomy.subgenus) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(subgenus)#%">
						</cfif>
					</cfif>
				</cfif>
				<cfif isdefined("species") AND len(species) gt 0>
					<cfif left(species,1) is "=">
						AND upper(taxonomy.species) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(species,len(species)-1))#">
					<cfelseif left(species,1) is "$">
						AND soundex(taxonomy.species) = soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(species,len(species)-1)#">)
					<cfelseif left(species,2) is "!$">
						AND soundex(taxonomy.species) <> soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(species,len(species)-2)#">)
					<cfelseif left(species,1) is "!">
						AND upper(taxonomy.species) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(species,len(species)-1))#">
					<cfelseif species is "NULL">
						AND upper(taxonomy.species) is null
					<cfelseif species is "NOT NULL">
						AND upper(taxonomy.species) is not null
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
					<cfelseif left(subspecies,1) is "$">
						AND soundex(taxonomy.subspecies) = soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(subspecies,len(subspecies)-1)#">)
					<cfelseif left(subspecies,2) is "!$">
						AND soundex(taxonomy.subspecies) <> soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(subspecies,len(subspecies)-2)#">)
					<cfelseif left(subspecies,1) is "!">
						AND upper(taxonomy.subspecies) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(subspecies,len(subspecies)-1))#">
					<cfelseif subspecies is "NULL">
						AND upper(taxonomy.subspecies) is null
					<cfelseif subspecies is "NOT NULL">
						AND upper(taxonomy.subspecies) is not null
					<cfelse>
						<cfif find(',',subspecies) GT 0>
							AND upper(taxonomy.subspecies) in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(subspecies)#" list="yes"> )
						<cfelse>
							AND upper(taxonomy.subspecies) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(subspecies)#%">
						</cfif>
					</cfif>
				</cfif>
				<cfif isdefined("author_text") AND len(author_text) gt 0>
					<cfif left(author_text,1) is "=">
						AND upper(taxonomy.author_text) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(author_text,len(author_text)-1))#">
					<cfelseif left(author_text,1) is "$">
						AND soundex(taxonomy.author_text) = soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(author_text,len(author_text)-1)#">)
					<cfelseif left(author_text,2) is "!$">
						AND soundex(taxonomy.author_text) <> soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(author_text,len(author_text)-2)#">)
					<cfelseif left(author_text,1) is "!">
						AND upper(taxonomy.author_text) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(author_text,len(author_text)-1))#">
					<cfelseif author_text is "NULL">
						AND upper(taxonomy.author_text) is null
					<cfelseif author_text is "NOT NULL">
						AND upper(taxonomy.author_text) is not null
					<cfelse>
						AND upper(taxonomy.author_text) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(author_text)#%">
					</cfif>
				</cfif>
				<cfif isdefined("infraspecific_author") AND len(infraspecific_author) gt 0>
					<cfif left(infraspecific_author,1) is "=">
						AND upper(taxonomy.infraspecific_author) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(infraspecific_author,len(infraspecific_author)-1))#">
					<cfelseif left(infraspecific_author,1) is "$">
						AND soundex(taxonomy.infraspecific_author) = soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(infraspecific_author,len(infraspecific_author)-1)#">)
					<cfelseif left(infraspecific_author,2) is "!$">
						AND soundex(taxonomy.infraspecific_author) <> soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(infraspecific_author,len(infraspecific_author)-2)#">)
					<cfelseif left(infraspecific_author,1) is "!">
						AND upper(taxonomy.infraspecific_author) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(infraspecific_author,len(infraspecific_author)-1))#">
					<cfelseif infraspecific_author is "NULL">
						AND upper(taxonomy.infraspecific_author) is null
					<cfelseif infraspecific_author is "NOT NULL">
						AND upper(taxonomy.infraspecific_author) is not null
					<cfelse>
						AND upper(taxonomy.infraspecific_author) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(infraspecific_author)#%">
					</cfif>
				</cfif>
				<cfif isdefined("taxon_remarks") AND len(taxon_remarks) gt 0>
					<cfif left(taxon_remarks,1) is "=">
						AND upper(taxonomy.taxon_remarks) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(taxon_remarks,len(taxon_remarks)-1))#">
					<cfelseif left(taxon_remarks,1) is "!">
						AND upper(taxonomy.taxon_remarks) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(taxon_remarks,len(taxon_remarks)-1))#">
					<cfelseif taxon_remarks is "NULL">
						AND upper(taxonomy.taxon_remarks) is null
					<cfelseif taxon_remarks is "NOT NULL">
						AND upper(taxonomy.taxon_remarks) is not null
					<cfelse>
						AND upper(taxonomy.taxon_remarks) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(taxon_remarks)#%">
					</cfif>
				</cfif>
				<cfif isdefined("taxon_habitat") AND len(taxon_habitat) gt 0>
					<cfif left(taxon_habitat,1) is "=">
						AND upper(taxon_habitat.taxon_habitat) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(taxon_habitat,len(taxon_habitat)-1))#">
					<cfelseif left(taxon_habitat,1) is "!">
						AND upper(taxon_habitat.taxon_habitat) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(taxon_habitat,len(taxon_habitat)-1))#">
					<cfelseif taxon_habitat is "NULL">
						AND taxon_habitat.taxon_name_id IS NULL
					<cfelseif taxon_habitat is "NOT NULL">
						AND taxon_habitat.taxon_habitat_id IS NOT NULL
					<cfelse>
						AND upper(taxon_habitat.taxon_habitat) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(taxon_habitat)#%">
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
				<cfif isdefined("we_have_some") AND we_have_some EQ 1>
					AND #session.flatTableName#.collection_object_id is not null
				<cfelseif isdefined("we_have_some") AND we_have_some EQ 0>
					AND #session.flatTableName#.collection_object_id is null
				</cfif>
				<cfif isdefined("collection_cde") AND len(collection_cde) gt 0>
					AND taxonomy.taxon_name_id in (
						SELECT taxon_name_id 
						FROM  identification_taxonomy 
							left join identification on identification_taxonomy.IDENTIFICATION_ID = identification.identification_id
							left join cataloged_item on identification.collection_object_id = cataloged_item.COLLECTION_OBJECT_ID
						WHERE cataloged_item.collection_cde = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#collection_cde#">
						UNION
						SELECT CITED_TAXON_NAME_ID as taxon_name_id 
						FROM CITATION 
							left join cataloged_item on CITATION.COLLECTION_OBJECT_ID = CATALOGED_ITEM.COLLECTION_OBJECT_ID
						WHERE cataloged_item.collection_cde = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#collection_cde#">
					) 
				</cfif>
				<cfif isdefined("common_name") AND len(common_name) gt 0>
					<cfif left(common_name,1) is "=">
						AND upper(common_name.common_name) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(common_name,len(common_name)-1))#">
					<cfelse>
						<cfif find(',',common_name) GT 0>
							AND upper(common_name.common_name) in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(common_name)#" list="yes"> )
						<cfelse>
							AND upper(common_name.common_name) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(common_name)#%">
						</cfif>
					</cfif>
				</cfif>
				<cfif isdefined("relationship") AND len(relationship) gt 0>
					<cfif relationship IS 'NOT NULL'>
						AND taxonomy.taxon_name_id in (select distinct taxon_name_id from taxon_relations union select distinct related_taxon_name_id from taxon_relations)
					<cfelseif relationshipdirection IS "both" >
						AND taxonomy.taxon_name_id in (
							select taxon_name_id from taxon_relations where taxon_relationship = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#relationship#">
							union
							select related_taxon_name_id from taxon_relations where taxon_relationship = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#relationship#">
						)
					<cfelseif relationshipdirection IS "backwards" >
						AND taxonomy.taxon_name_id in (
							select related_taxon_name_id from taxon_relations where taxon_relationship = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#relationship#">
						)
					<cfelse>
						AND taxonomy.taxon_name_id in (
							select taxon_name_id from taxon_relations where taxon_relationship = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#relationship#">
						)
					</cfif>
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
				taxonomy.INFRACLASS,
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
				taxonomy.YEAR_OF_PUBLICATION,
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
				taxonomy.TAXON_REMARKS,
				CONCATCOMMONNAME(taxonomy.TAXON_NAME_ID)
			ORDER BY taxonomy.scientific_name, taxonomy.author_text
		</cfquery>
		<!--- Track queries by adding tracking information into uam_query.query_stats by sys.SP_GET_QUERYSTATS from drops in dba_recyclebin of TaxSrch... tables. 
		./includes/functionLib.cfm:	<cfset session.TaxSrchTab="TaxSrch" & temp>
		./TaxonomyResults.cfm:<CFSET SQL = "create table #session.TaxSrchTab# as #SQL#">
		./TaxonomyResults.cfm:		drop table #session.TaxSrchTab#
		--->
		<cftry>
			<cfquery name="prepStatRecord" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				create table <cfif isDefined("session.TaxSrchTab")>#session.TaxSrchTab#</cfif> as select * from taxonomy where rownum < 2
			</cfquery>
			<cfquery name="createStatRecord" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				drop table <cfif isDefined("session.TaxSrchTab")>#session.TaxSrchTab#</cfif>
			</cfquery>
		<cfcatch>
		</cfcatch>
		</cftry>
		<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfset row["DISPLAY_NAME_AUTHOR"] = "#search.display_name# <span style='font-variant: small-caps;'>#search.author_text#</span>">
			<cfset plain_name_author = "#search.scientific_name# #search.author_text#">
			<cfset row["PLAIN_NAME_AUTHOR"] = "#trim(plain_name_author)#">
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
		<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn #serializeJSON(data)#>
</cffunction>

<!---
Function getPhylumAutocomplete.  Search for phyla by name with a substring match on name, returning json suitable for jquery-ui autocomplete.

@param term phylum name to search for.
@return a json structure containing id and value, with matching with matched name in value and id.
--->
<cffunction name="getPhylumAutocomplete" access="remote" returntype="any" returnformat="json">
	<cfargument name="term" type="string" required="yes">
	<!--- perform wildcard search anywhere in taxonomy.phylum --->
	<cfset name = "%#term#%"> 

	<cfset data = ArrayNew(1)>
	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="search_result" timeout="#Application.query_timeout#">
			SELECT 
				count(*) as ct,
				phylum
			FROM 
				taxonomy
			WHERE
				upper(phylum) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(name)#">
			GROUP BY
				phylum
			ORDER BY 
				phylum
		</cfquery>
	<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfset row["id"] = "#search.phylum#">
			<cfset row["value"] = "#search.phylum#" >
			<cfset row["meta"] = "#search.ct#" >
			<cfset data[i]  = row>
			<cfset i = i + 1>
		</cfloop>
		<cfreturn #serializeJSON(data)#>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn #serializeJSON(data)#>
</cffunction>

<!---
Function getClassAutocomplete.  Search for taxonomic classes by name with a substring match on name, returning json suitable for jquery-ui autocomplete.

@param term class name to search for.
@return a json structure containing id and value, with matching with matched name in value and id.
--->
<cffunction name="getClassAutocomplete" access="remote" returntype="any" returnformat="json">
	<cfargument name="term" type="string" required="yes">
	<!--- perform wildcard search anywhere in taxonomy.class --->
	<cfset name = "%#term#%"> 

	<cfset data = ArrayNew(1)>
	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="search_result" timeout="#Application.query_timeout#">
			SELECT count(*) as ct,
				phylclass as class
			FROM 
				taxonomy
			WHERE
				upper(phylclass) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(name)#">
			GROUP BY 
				phylclass
			ORDER BY 
				phylclass
		</cfquery>
	<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfset row["id"] = "#search.class#">
			<cfset row["value"] = "#search.class#" >
			<cfset row["meta"] = "#search.ct#" >
			<cfset data[i]  = row>
			<cfset i = i + 1>
		</cfloop>
		<cfreturn #serializeJSON(data)#>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn #serializeJSON(data)#>
</cffunction>

<!---
Function getHigherRankAutocomplete.  Search for distinct values of a particular higher taxonomic rank 
  by name with a substring match on name, returning json suitable for jquery-ui autocomplete.

@param term value of the name to search for.
@param rank the rank to search (accepts any of the atomic field names in taxonomy table, including author_text).
@return a json structure containing id and value, and meta, with matching with matched name in value and id, 
  and count metadata in meta.
--->
<cffunction name="getHigherRankAutocomplete" access="remote" returntype="any" returnformat="json">
	<cfargument name="term" type="string" required="yes">
	<cfargument name="rank" type="string" required="yes">
	<!--- perform wildcard search anywhere in taxonomy.class --->
	<cfset name = "%#term#%"> 

	<cfset data = ArrayNew(1)>
	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="search_result" timeout="#Application.query_timeout#">
			SELECT count(*) as ct,
				<cfswitch expression="#rank#">
					<cfcase value="kingdom">kingdom as name</cfcase>
					<cfcase value="phylum">phylum as name</cfcase>
					<cfcase value="subphylum">subphylum as name</cfcase>
					<cfcase value="superclass">superclass as name</cfcase>
					<cfcase value="class">phylclass as name</cfcase>
					<cfcase value="subclass">subclass as name</cfcase>
					<cfcase value="infraclass">infraclass as name</cfcase>
					<cfcase value="superorder">superorder as name</cfcase>
					<cfcase value="order">phylorder as name</cfcase>
					<cfcase value="suborder">suborder as name</cfcase>
					<cfcase value="infraorder">infraorder as name</cfcase>
					<cfcase value="superfamily">superfamily as name</cfcase>
					<cfcase value="family">family as name</cfcase>
					<cfcase value="subfamily">subfamily as name</cfcase>
					<cfcase value="tribe">tribe as name</cfcase>
					<cfcase value="genus">genus as name</cfcase>
					<cfcase value="subgenus">subgenus as name</cfcase>
					<cfcase value="species">species as name</cfcase>
					<cfcase value="subspecies">subspecies as name</cfcase>
					<cfcase value="author_text">author_text as name</cfcase>
					<cfcase value="infraspecific_author">infraspecific_author as name</cfcase>
				</cfswitch>
			FROM 
				taxonomy
			WHERE
				<cfswitch expression="#rank#">
					<cfcase value="kingdom">upper (kingdom)</cfcase>
					<cfcase value="phylum">upper (phylum)</cfcase>
					<cfcase value="subphylum">upper (subphylum)</cfcase>
					<cfcase value="superclass">upper (superclass)</cfcase>
					<cfcase value="class">upper (phylclass)</cfcase>
					<cfcase value="subclass">upper (subclass)</cfcase>
					<cfcase value="infraclass">upper (infraclass)</cfcase>
					<cfcase value="superorder">upper (superorder)</cfcase>
					<cfcase value="order">upper (phylorder)</cfcase>
					<cfcase value="suborder">upper (suborder)</cfcase>
					<cfcase value="infraorder">upper (infraorder)</cfcase>
					<cfcase value="superfamily">upper (superfamily)</cfcase>
					<cfcase value="family">upper (family)</cfcase>
					<cfcase value="subfamily">upper (subfamily)</cfcase>
					<cfcase value="tribe">upper (tribe)</cfcase>
					<cfcase value="genus">upper (genus)</cfcase>
					<cfcase value="subgenus">upper (subgenus)</cfcase>
					<cfcase value="species">upper (species)</cfcase>
					<cfcase value="subspecies">upper (subspecies)</cfcase>
					<cfcase value="author_text">upper (author_text)</cfcase>
					<cfcase value="infraspecific_author">upper (infraspecific_author)</cfcase>
				</cfswitch>
				like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(name)#">
			GROUP BY 
				<cfswitch expression="#rank#">
					<cfcase value="kingdom">kingdom</cfcase>
					<cfcase value="phylum">phylum</cfcase>
					<cfcase value="subphylum">subphylum</cfcase>
					<cfcase value="superclass">superclass</cfcase>
					<cfcase value="class">phylclass</cfcase>
					<cfcase value="subclass">subclass</cfcase>
					<cfcase value="infraclass">infraclass</cfcase>
					<cfcase value="superorder">superorder</cfcase>
					<cfcase value="order">phylorder</cfcase>
					<cfcase value="suborder">suborder</cfcase>
					<cfcase value="infraorder">infraorder</cfcase>
					<cfcase value="superfamily">superfamily</cfcase>
					<cfcase value="family">family</cfcase>
					<cfcase value="subfamily">subfamily</cfcase>
					<cfcase value="tribe">tribe</cfcase>
					<cfcase value="genus">genus</cfcase>
					<cfcase value="subgenus">subgenus</cfcase>
					<cfcase value="species">species</cfcase>
					<cfcase value="subspecies">subspecies</cfcase>
					<cfcase value="author_text">author_text</cfcase>
					<cfcase value="infraspecific_author">infraspecific_author</cfcase>
				</cfswitch>
			ORDER BY 
				<cfswitch expression="#rank#">
					<cfcase value="kingdom">kingdom</cfcase>
					<cfcase value="phylum">phylum</cfcase>
					<cfcase value="subphylum">subphylum</cfcase>
					<cfcase value="superclass">superclass</cfcase>
					<cfcase value="class">phylclass</cfcase>
					<cfcase value="subclass">subclass</cfcase>
					<cfcase value="infraclass">infraclass</cfcase>
					<cfcase value="superorder">superorder</cfcase>
					<cfcase value="order">phylorder</cfcase>
					<cfcase value="suborder">suborder</cfcase>
					<cfcase value="infraorder">infraorder</cfcase>
					<cfcase value="superfamily">superfamily</cfcase>
					<cfcase value="family">family</cfcase>
					<cfcase value="subfamily">subfamily</cfcase>
					<cfcase value="tribe">tribe</cfcase>
					<cfcase value="genus">genus</cfcase>
					<cfcase value="subgenus">subgenus</cfcase>
					<cfcase value="species">species</cfcase>
					<cfcase value="subspecies">subspecies</cfcase>
					<cfcase value="author_text">author_text</cfcase>
					<cfcase value="infraspecific_author">infraspecific_author</cfcase>
				</cfswitch>
		</cfquery>
	<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfset row["id"] = "#search.name#">
			<cfset row["value"] = "#search.name#" >
			<cfset row["meta"] = "#search.ct#" >
			<cfset data[i]  = row>
			<cfset i = i + 1>
		</cfloop>
		<cfreturn #serializeJSON(data)#>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn #serializeJSON(data)#>
</cffunction>


<!---
Function getScientificNameAutocomplete.  Search for taxonomy entries by scientific name with a substring match on scientific 
 name, returning json suitable for jquery-ui autocomplete.

@param term substring match in scientific name to look for.
@param include_authorship if the string false then return just scientific_name as the value, otherwise, return scientific_name and author_string 
  as the value.
@param scope allows names to be limited to some scope of use, supports cited to just return names used in citations, and taxonomy_publication
  to return names with taxonomy_publication records.
@return a json structure containing id, meta, and value, with matching with matched name in value and id along with more detail in meta.
--->
<cffunction name="getScientificNameAutocomplete" access="remote" returntype="any" returnformat="json">
	<cfargument name="term" type="string" required="yes">
	<cfargument name="include_authorship" type="string" required="no">
	<cfargument name="scope" type="string" required="no">
	<cfset data = ArrayNew(1)>
	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="search_result" timeout="#Application.query_timeout#">
			SELECT
				distinct
				taxonomy.taxon_name_id,
				taxonomy.scientific_name,
				taxonomy.author_text,
				REGEXP_REPLACE(taxonomy.full_taxon_name, taxonomy.scientific_name || '$','') as higher_taxa
			FROM 
				taxonomy
			WHERE
				(
				upper(scientific_name) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(term)#%">
				OR
				upper(author_text) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(term)#%">
				)
				<cfif isDefined("scope") AND scope EQ "cited">
					AND taxon_name_id in (select cited_taxon_name_id from citation)
				<cfelseif isDefined("scope") AND scope EQ "taxonomy_publication">
					AND taxon_name_id in (select taxon_name_id from taxonomy_publication)
				</cfif>
			ORDER BY
				taxonomy.scientific_name
		</cfquery>
	<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfset row["id"] = "#search.taxon_name_id#">
			<cfif isDefined("include_authorship") AND include_authorship EQ "false">
				<cfset row["value"] = "#search.scientific_name#" >
			<cfelse>
				<cfset row["value"] = "#search.scientific_name# #search.author_text#" >
			</cfif>
			<cfset row["meta"] = "#search.scientific_name# #search.author_text# (#search.higher_taxa#)" >
			<cfset data[i]  = row>
			<cfset i = i + 1>
		</cfloop>
		<cfreturn #serializeJSON(data)#>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn #serializeJSON(data)#>
</cffunction>


</cfcomponent>
