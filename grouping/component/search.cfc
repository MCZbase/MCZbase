<!---
grouping/component/search.cfc

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
<cf_rolecheck>
<cfinclude template="/shared/component/functions.cfc" runOnce="true">

<!---   Function getCollections  --->
<cffunction name="getCollections" access="remote" returntype="any" returnformat="json">
	<cfargument name="collection_name" type="string" required="no">
	<cfargument name="underscore_agent_id" type="string" required="no">
	<cfargument name="underscore_agent_name" type="string" required="no">
	<cfargument name="description" type="string" required="no">
	<cfargument name="underscore_collection_id" type="string" required="no">
	<cfargument name="guid" type="string" required="no">
	<cfargument name="collection_id" type="string" required="no">

	<cfset data = ArrayNew(1)>
	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			SELECT count(underscore_relation.collection_object_id) as specimen_count, 
				underscore_collection.underscore_collection_id as underscore_collection_id, 
				collection_name,
				description,
				underscore_agent_id, 
				case 
					when underscore_agent_id is null then '[No Agent]'
					else MCZBASE.get_agentnameoftype(underscore_agent_id, 'preferred')
					end
				as agentname,
				decode(mask_fg,1,'Hidden','Public') as visibility
			FROM underscore_collection
				left join underscore_relation on underscore_collection.underscore_collection_id = underscore_relation.underscore_collection_id
				<cfif (isDefined("guid") and len(guid) gt 0) OR (isDefined("collection_id") AND len(collection_id) GT 0)>
					left join #session.flatTableName# on underscore_relation.collection_object_id = #session.flatTableName#.collection_object_id
				</cfif>
			WHERE
				underscore_collection.underscore_collection_id is not null
				<cfif NOT isdefined("session.roles") OR NOT listfindnocase(session.roles,"manage_specimens")>
					AND mask_fg = 0
				</cfif>
				<cfif isDefined("collection_name") and len(collection_name) gt 0>
					and collection_name like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#collection_name#%">
				</cfif>
				<cfif isDefined("description") and len(description) gt 0>
					and upper(description) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(description)#%">
				</cfif>
				<cfif isDefined("underscore_agent_id") and len(underscore_agent_id) gt 0>
					and 
					( underscore_agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_agent_id#">
					<cfif isDefined("underscore_agent_name") and underscore_agent_name EQ "[no agent data]">
					 or underscore_agent_id IS NULL	
					</cfif>
					)
				</cfif>

				<cfif isDefined("collection_id") and len(collection_id) gt 0>
					and #session.flatTableName#.collection_id in (<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_id#" list="yes">)
				</cfif>
				<cfif isDefined("guid") and len(guid) gt 0>
					<cfif find(',',guid) GT 0> 
						and #session.flatTableName#.guid in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#guid#" list="yes">)
					<cfelseif guid EQ "NULL"> 
						and #session.flatTableName#.guid is NULL
					<cfelse>
						and #session.flatTableName#.guid = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#guid#">
					</cfif>
				</cfif>
			GROUP BY
				underscore_collection.underscore_collection_id,
				collection_name,
				description,
				underscore_agent_id, 
				case 
					when underscore_agent_id is null then '[No Agent]'
					else MCZBASE.get_agentnameoftype(underscore_agent_id, 'preferred')
					end,
				mask_fg
			ORDER BY
				underscore_collection.collection_name
		</cfquery>
		<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfset columnNames = ListToArray(search.columnList)>
			<cfloop array="#columnNames#" index="columnName">
				<cfset row["#columnName#"] = "#search[columnName][currentrow]#">
				<cfquery name="getClob" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getClob_result">
					SELECT html_description 
					FROM underscore_collection
					WHERE
						underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#search.underscore_collection_id#">
				</cfquery>
				<cfloop query="getClob">
					<cfset row["HTML_DESCRIPTION"] = "#replace(encodeForHTML(REReplace(getClob.html_description,'<[^>]*>','','All')),'\n','')#">
				</cfloop>
			</cfloop>
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
Function getNamedCollectionAutocomplete.  Search for named collections by name with a substring match on any name, returning json suitable for jquery-ui autocomplete.

@param term named collection name to search for.
@return a json structure containing id, meta, and value, with matching named collections with matched name in value and underscore_collection_id in id,
  and the begining of the description in meta.
--->
<cffunction name="getNamedCollectionAutocomplete" access="remote" returntype="any" returnformat="json">
	<cfargument name="term" type="string" required="yes">
	<!--- perform wildcard search anywhere in underscore_collection.collection_name --->

	<cfset data = ArrayNew(1)>
	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			SELECT 
				underscore_collection.underscore_collection_id as underscore_collection_id, 
				collection_name,
				case 
					when length(description) > 40 then
						substr(description,1,40) || '...'
					else
						description
					end
					as description_trim
			FROM 
				underscore_collection
			WHERE
				upper(collection_name) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(term)#%">
		</cfquery>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfset row["id"] = "#search.underscore_collection_id#">
			<cfset row["value"] = "#search.collection_name#" >
			<cfset row["meta"] = "#search.description_trim#" >
			<cfset data[i]  = row>
			<cfset i = i + 1>
		</cfloop>
		<cfreturn #serializeJSON(data)#>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset message = trim("Error processing getNamedCollectionAutocomplete: " & cfcatch.message & " " & cfcatch.detail & " " & queryError)  >
		<cfheader statusCode="500" statusText="#message#">
			<cfoutput>
				<div class="container">
					<div class="row">
						<div class="alert alert-danger" role="alert">
							<img src="/shared/images/Process-stop.png" alt="[ error ]" style="float:left; width: 50px;margin-right: 1em;">
							<h2>Internal Server Error.</h2>
							<p>#message#</p>
							<p><a href="/info/bugs.cfm">“Feedback/Report Errors”</a></p>
						</div>
					</div>
				</div>
			</cfoutput>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn #serializeJSON(data)#>
</cffunction>

<!--- Obtain a list of the specimens in a named group in a form suitable for display in a jqxgrid. 
  @param underscore_collection_id the surrogate numeric primary key identifying the named group.
  @param smallerfieldlist, set to true to return only the subset of fields used by the showNamedGroup grid
  @return a json data structure with specimen data 
--->
<cffunction name="getSpecimensInGroup" access="remote" returntype="any" returnformat="json">
	<cfargument name="underscore_collection_id" type="string" required="yes">
	<cfargument name="smallerfieldlist" type="string" required="no">
	<cfargument name="recordstartindex" type="string" required="no">
	<cfargument name="recordendindex" type="string" required="no">
	<cfargument name="pagesize" type="string" required="no">
	<cfargument name="pagenum" type="string" required="no">
	<cfargument name="sortdatafield" type="string" required="no">
	<cfargument name="sortorder" type="string" required="no">
	<cfargument name="filterscount" type="string" required="no">
	<cfargument name="returnallrecords" type="string" required="no">

	<cfif NOT isdefined("pagesize")><cfset pagesize=0></cfif>
	<cfif NOT isdefined("sortdatafield")><cfset sortdatafield=""></cfif>
	<cfif NOT isdefined("sortorder")><cfset sortorder="asc"></cfif>
	<cfif NOT isdefined("returnallrecords")><cfset returnallrecords=""></cfif>
	<cfif returnallrecords EQ "true">
		<!--- turn off all server side filtering/paging --->
		<cfset pagesize=0>
		<cfset pagenum="">
		<cfset sortdatafield="">
		<cfset sortorder="asc">
		<cfset filterscount="0">
	</cfif>
	<!--- 
	fields in the showNamedGroup grid
		{ name: 'guid', type: 'string' },
		{ name: 'scientific_name', type: 'string' },
		{ name: 'verbatim_date', type: 'string' },
		{ name: 'higher_geog', type: 'string' },
		{ name: 'spec_locality', type: 'string' },
		{ name: 'othercatalognumbers', type: 'string' },
		{ name: 'full_taxon_name', type: 'string' }
	--->
	<cftry>
		<cfquery name="search"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result" >
			<cfif pagesize GT 0 >
				SELECT * FROM (
			</cfif>
			SELECT DISTINCT 
				flat.guid, 
				flat.scientific_name, 
				flat.verbatim_date, 
				flat.higher_geog, 
				flat.spec_locality,
				flat.othercatalognumbers, 
				flat.full_taxon_name
				<cfif NOT isDefined("smallerfieldlist") OR len(smallerfieldlist) GT 0>
					,
					flat.collectors,
					flat.author_text,
					flat.collection_cde, 
					mczbase.get_pretty_date(flat.verbatim_date,flat.began_date,flat.ended_date,1,0) as date_collected,
					flat.country, flat.state_prov, flat.continent_ocean, flat.county,
					flat.island, flat.island_group,
					flat.phylum, flat.phylclass, flat.phylorder, flat.family,
					underscore_relation.underscore_relation_id -- needed for remove cell renderer on edit page
				</cfif>
				<cfif pagesize GT 0 >
					,
					row_number() OVER (
						<cfif lcase(sortdatafield) EQ "guid">
							ORDER BY flat.collection_cde <cfif ucase(sortorder) EQ "ASC">asc<cfelse>desc</cfif>,
								to_number(regexp_substr(flat.guid, '\d+')) <cfif ucase(sortorder) EQ "ASC">asc<cfelse>desc</cfif>,
								flat.guid <cfif ucase(sortorder) EQ "ASC">asc<cfelse>desc</cfif>
						<cfelseif lcase(sortdatafield) EQ "scientific_name">
							ORDER BY scientific_name <cfif ucase(sortorder) EQ "ASC">asc<cfelse>desc</cfif>
						<cfelseif lcase(sortdatafield) EQ "verbatim_date">
							ORDER BY verbatim_date <cfif ucase(sortorder) EQ "ASC">asc<cfelse>desc</cfif>
						<cfelseif lcase(sortdatafield) EQ "higher_geog">
							ORDER BY higher_geog <cfif ucase(sortorder) EQ "ASC">asc<cfelse>desc</cfif>
						<cfelseif lcase(sortdatafield) EQ "spec_locality">
							ORDER BY spec_locality <cfif ucase(sortorder) EQ "ASC">asc<cfelse>desc</cfif>
						<cfelseif lcase(sortdatafield) EQ "othercatalognumbers">
							ORDER BY othercatalognumbers <cfif ucase(sortorder) EQ "ASC">asc<cfelse>desc</cfif>
						<cfelseif lcase(sortdatafield) EQ "full_taxon_name">
							ORDER BY full_taxon_name <cfif ucase(sortorder) EQ "ASC">asc<cfelse>desc</cfif>
						<cfelse>
							ORDER BY flat.collection_cde asc, to_number(regexp_substr(flat.guid, '\d+')) asc, flat.guid asc
						</cfif>
					) rownumber
				</cfif>
			FROM
				underscore_relation 
				INNER JOIN <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat 
					on underscore_relation.collection_object_id = flat.collection_object_id
			WHERE underscore_relation.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
				<cfif isdefined("filterscount") AND filterscount GT 0>
					<cfloop index="i" from='0' to='#filterscount#'>
						<cfif isdefined("filterdatafield"&i) AND (isdefined("filtervalue"&i) OR isdefined("filtercondition"&i))>
							<cfif evaluate("filterdatafield"&i) EQ "scientific_name">
								<cfswitch expression="#lcase(evaluate('filtercondition'&i))#">
									<cfcase value="empty">
										AND scientific_name IS NULL
									</cfcase>
									<cfcase value="not_empty">
										AND scientific_name IS NOT NULL
									</cfcase>
									<cfcase value="contains">
										AND upper(scientific_name) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(evaluate('filtervalue'&i))#%">
									</cfcase>
									<cfcase value="contains_case_sensitive">
										AND scientific_name like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#evaluate('filtervalue'&i)#%">
									</cfcase>
									<cfcase value="does_not_contain">
										AND NOT upper(scientific_name) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(evaluate('filtervalue'&i))#%">
									</cfcase>
								</cfswitch>
							<cfelseif evaluate("filterdatafield"&i) EQ "verbatim_date">
								<cfswitch expression="#lcase(evaluate('filtercondition'&i))#">
									<cfcase value="empty">
										AND verbatim_date IS NULL
									</cfcase>
									<cfcase value="not_empty">
										AND verbatim_date IS NOT NULL
									</cfcase>
									<cfcase value="contains">
										AND upper(verbatim_date) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(evaluate('filtervalue'&i))#%">
									</cfcase>
									<cfcase value="contains_case_sensitive">
										AND verbatim_date like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#evaluate('filtervalue'&i)#%">
									</cfcase>
									<cfcase value="does_not_contain">
										AND NOT upper(verbatim_date) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(evaluate('filtervalue'&i))#%">
									</cfcase>
								</cfswitch>
							<cfelseif evaluate("filterdatafield"&i) EQ "guid">
								<cfswitch expression="#lcase(evaluate('filtercondition'&i))#">
									<cfcase value="empty">
										AND guid IS NULL
									</cfcase>
									<cfcase value="not_empty">
										AND guid IS NOT NULL
									</cfcase>
									<cfcase value="contains">
										AND upper(guid) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(evaluate('filtervalue'&i))#%">
									</cfcase>
									<cfcase value="contains_case_sensitive">
										AND guid like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#evaluate('filtervalue'&i)#%">
									</cfcase>
									<cfcase value="does_not_contain">
										AND NOT upper(guid) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(evaluate('filtervalue'&i))#%">
									</cfcase>
								</cfswitch>
							<cfelseif evaluate("filterdatafield"&i) EQ "spec_locality">
								<cfswitch expression="#lcase(evaluate('filtercondition'&i))#">
									<cfcase value="empty">
										AND spec_locality IS NULL
									</cfcase>
									<cfcase value="not_empty">
										AND spec_locality IS NOT NULL
									</cfcase>
									<cfcase value="contains">
										AND upper(spec_locality) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(evaluate('filtervalue'&i))#%">
									</cfcase>
									<cfcase value="contains_case_sensitive">
										AND spec_locality like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#evaluate('filtervalue'&i)#%">
									</cfcase>
									<cfcase value="does_not_contain">
										AND NOT upper(spec_locality) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(evaluate('filtervalue'&i))#%">
									</cfcase>
								</cfswitch>
							<cfelseif evaluate("filterdatafield"&i) EQ "higher_geog">
								<cfswitch expression="#lcase(evaluate('filtercondition'&i))#">
									<cfcase value="empty">
										AND higher_geog IS NULL
									</cfcase>
									<cfcase value="not_empty">
										AND higher_geog IS NOT NULL
									</cfcase>
									<cfcase value="contains">
										AND upper(higher_geog) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(evaluate('filtervalue'&i))#%">
									</cfcase>
									<cfcase value="contains_case_sensitive">
										AND higher_geog like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#evaluate('filtervalue'&i)#%">
									</cfcase>
									<cfcase value="does_not_contain">
										AND NOT upper(higher_geog) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(evaluate('filtervalue'&i))#%">
									</cfcase>
								</cfswitch>
							<cfelseif evaluate("filterdatafield"&i) EQ "othercatalognumbers">
								<cfswitch expression="#lcase(evaluate('filtercondition'&i))#">
									<cfcase value="empty">
										AND othercatalognumbers IS NULL
									</cfcase>
									<cfcase value="not_empty">
										AND othercatalognumbers IS NOT NULL
									</cfcase>
									<cfcase value="contains">
										AND upper(othercatalognumbers) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(evaluate('filtervalue'&i))#%">
									</cfcase>
									<cfcase value="contains_case_sensitive">
										AND othercatalognumbers like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#evaluate('filtervalue'&i)#%">
									</cfcase>
									<cfcase value="does_not_contain">
										AND NOT upper(othercatalognumbers) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(evaluate('filtervalue'&i))#%">
									</cfcase>
								</cfswitch>
							<cfelseif evaluate("filterdatafield"&i) EQ "full_taxon_name">
								<cfswitch expression="#lcase(evaluate('filtercondition'&i))#">
									<cfcase value="empty">
										AND full_taxon_name IS NULL
									</cfcase>
									<cfcase value="not_empty">
										AND full_taxon_name IS NOT NULL
									</cfcase>
									<cfcase value="contains">
										AND upper(full_taxon_name) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(evaluate('filtervalue'&i))#%">
									</cfcase>
									<cfcase value="contains_case_sensitive">
										AND full_taxon_name like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#evaluate('filtervalue'&i)#%">
									</cfcase>
									<cfcase value="does_not_contain">
										AND NOT upper(full_taxon_name) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(evaluate('filtervalue'&i))#%">
									</cfcase>
								</cfswitch>
							</cfif>
						</cfif>
					</cfloop>
				</cfif>
			<cfif lcase(sortdatafield) EQ "guid">
				ORDER BY flat.collection_cde <cfif ucase(sortorder) EQ "ASC">asc<cfelse>desc</cfif>,
					to_number(regexp_substr(flat.guid, '\d+')) <cfif ucase(sortorder) EQ "ASC">asc<cfelse>desc</cfif>,
					flat.guid <cfif ucase(sortorder) EQ "ASC">asc<cfelse>desc</cfif>
			<cfelseif lcase(sortdatafield) EQ "scientific_name">
				ORDER BY scientific_name <cfif ucase(sortorder) EQ "ASC">asc<cfelse>desc</cfif>
			<cfelseif lcase(sortdatafield) EQ "verbatim_date">
				ORDER BY verbatim_date <cfif ucase(sortorder) EQ "ASC">asc<cfelse>desc</cfif>
			<cfelseif lcase(sortdatafield) EQ "higher_geog">
				ORDER BY higher_geog <cfif ucase(sortorder) EQ "ASC">asc<cfelse>desc</cfif>
			<cfelseif lcase(sortdatafield) EQ "spec_locality">
				ORDER BY spec_locality <cfif ucase(sortorder) EQ "ASC">asc<cfelse>desc</cfif>
			<cfelseif lcase(sortdatafield) EQ "othercatalognumbers">
				ORDER BY othercatalognumbers <cfif ucase(sortorder) EQ "ASC">asc<cfelse>desc</cfif>
			<cfelseif lcase(sortdatafield) EQ "full_taxon_name">
				ORDER BY full_taxon_name <cfif ucase(sortorder) EQ "ASC">asc<cfelse>desc</cfif>
			<cfelse>
				ORDER BY flat.collection_cde asc, to_number(regexp_substr(flat.guid, '\d+')) asc, flat.guid asc
			</cfif>
			<cfif pagesize GT 0 >
				)
				WHERE rownumber between <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#recordstartindex#">
					and <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#recordendindex#">
			</cfif>
		</cfquery>
		<cfset i = 1>
		<cfset data = ArrayNew(1)>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfloop list="#ArrayToList(search.getColumnNames())#" index="col" >
				<cfset row["#lcase(col)#"] = "#search[col][currentRow]#">
				<cfif i EQ 1>
					<cfset row["recordcount"] = "#search.recordcount#">
				</cfif>
			</cfloop>
			<cfset data[i]  = row>
			<cfset i = i + 1>
		</cfloop>
	<cfcatch>
		<cfset error_message = cfcatchToErrorMessage(cfcatch)>
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
	   <cfabort>
	</cfcatch>
	</cftry>
	<cfreturn #serializeJSON(data)#>
</cffunction>

<cffunction name="getSpecimensInGroupCSV" access="remote" returntype="any" returnformat="plain">
	<cfargument name="underscore_collection_id" type="string" required="yes">
	<cfargument name="smallerfieldlist" type="string" required="no">

	<cfset retval = "">
	<cftry>
		<cfquery name="search"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result" cachedwithin="#CreateTimespan(24,0,0,0)#" >
			SELECT DISTINCT 
				flat.guid, 
				flat.scientific_name, 
				flat.verbatim_date, 
				flat.higher_geog, 
				flat.spec_locality,
				flat.othercatalognumbers, 
				flat.full_taxon_name
				<cfif NOT isDefined("smallerfieldlist") OR len(smallerfieldlist) GT 0>
					,
					flat.collectors,
					flat.author_text,
					flat.collection_cde, 
					mczbase.get_pretty_date(flat.verbatim_date,flat.began_date,flat.ended_date,1,0) as date_collected,
					flat.country, flat.state_prov, flat.continent_ocean, flat.county,
					flat.island, flat.island_group,
					flat.phylum, 
					flat.phylclass, 
					flat.phylorder, 
					flat.family
				</cfif>
			FROM
				underscore_relation 
				INNER JOIN <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat 
					on underscore_relation.collection_object_id = flat.collection_object_id
			WHERE underscore_relation.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
		</cfquery>
		<cfset retval = queryToCSV(search)>
	<cfcatch>
		<cfset error_message = cfcatchToErrorMessage(cfcatch)>
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
	   <cfabort>
	</cfcatch>
	</cftry>
	<cfheader name="Content-Type" value="text/csv">
<cfoutput>#retval#</cfoutput>
</cffunction>

<cffunction name="getNamedGroupBlockHtml" access="remote" returntype="string" returnformat="plain">
	<cfargument name="media_id" type="string" required="yes">
	<cfargument name="size" type="string" required="no" default="600">
	<cfargument name="displayAs" type="string" required="no" default="full">

	<!--- argument scope isn't available within the cfthread, so creating explicit local variables to bring optional arguments into scope within the thread --->
	<cfset l_media_id= #arguments.media_id#>
	<cfset l_displayAs = #arguments.displayAs#>
	<cfset l_size = #arguments.size#>
	<cfset tn = REReplace(CreateUUID(), "[-]", "", "all") >	
	<cfthread name="mediaWidgetThread#tn#" threadName="mediaWidgetThread#tn#">
		<cfoutput>
			<cftry>
				
				<cfquery name="media" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="media_result">
					SELECT media_id, 
						preview_uri, media_uri, 
						mime_type, media_type,
						auto_extension as extension,
						auto_host as host,
						CASE WHEN MCZBASE.is_mcz_media(media.media_id) = 1 THEN ctmedia_license.uri ELSE MCZBASE.get_media_dctermsrights(media.media_id) END as license_uri, 
						CASE WHEN MCZBASE.is_mcz_media(media.media_id) = 1 THEN ctmedia_license.display ELSE MCZBASE.get_media_dcrights(media.media_id) END as license_display, 
						MCZBASE.get_media_dcrights(media.media_id) as dc_rights,
						MCZBASE.get_media_credit(media.media_id) as credit,
						MCZBASE.get_media_owner(media.media_id) as owner,
						MCZBASE.get_media_creator(media.media_id) as creator,
						MCZBASE.get_medialabel(media.media_id,'aspect') as aspect,
						MCZBASE.get_medialabel(media.media_id,'description') as description,
						MCZBASE.get_medialabel(media.media_id,'made date') as made_date,
						MCZBASE.get_medialabel(media.media_id,'subject') as subject,
						MCZBASE.get_medialabel(media.media_id,'height') as height,
						MCZBASE.get_medialabel(media.media_id,'width') as width,
						MCZBASE.get_media_descriptor(media.media_id) as alt,
						MCZBASE.get_media_title(media.media_id) as title
					FROM 
						media
						left join ctmedia_license on media.media_license_id=ctmedia_license.media_license_id
					WHERE 
						media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#l_media_id#">
						AND MCZBASE.is_media_encumbered(media.media_id)  < 1 
				</cfquery>
				<cfif media.recordcount EQ 1>
					<cfloop query="media">
						<cfset isDisplayable = false>
						<cfif media_type EQ 'image' AND (media.mime_type EQ 'image/jpeg' OR media.mime_type EQ 'image/png')>
							<cfset isDisplayable = true>
						</cfif>
						<cfset altEscaped = replace(replace(alt,"'","&##8217;","all"),'"',"&quot;","all") >
						<cfset hw = 'height="100%" width="100%"'>
						<cfif isDisplayable>
							<cfif #l_displayAs# EQ "thumb">
								<cfset displayImage = preview_uri>
								<cfset l_size = "100">
								<cfset hw = 'width="100%"'>
							<cfelse>
								<cfif host EQ "mczbase.mcz.harvard.edu">
									<cfset hw = 'height="#l_size#px" width="#l_size#px"'>
									<cfset sizeType='&width=#l_size#&height=#l_size#'>
									<cfset displayImage = "/media/rescaleImage.cfm?media_id=#media.media_id##sizeType#">
								<cfelse>
									<cfset displayImage = media_uri>
								</cfif>
							</cfif>
						<cfelse>
							<!--- pick placeholder --->
							<cfif media_type is "image">
								<cfset displayImage = "/shared/images/Image-x-generic.svg">
								<cfset hw = 'height="60%" width="60%"'>
							<cfelseif media_type is "audio">
								<cfset displayImage =  "/shared/images/Gnome-audio-volume-medium.svg">
								<cfset hw = 'height="60%" width="60%"'>
							<cfelseif media_type IS "video">
								<cfset displayImage =  "/shared/images/Gnome-media-playback-start.svg">
								<cfset hw = 'height="60%" width="60%"'>
							<cfelseif media_type is "text">
								<cfset displayImage =  "/shared/images/Gnome-text-x-generic.svg">
								<cfset hw = 'height="60%" width="60%"'>
							<cfelseif media_type is "3D model">
								<cfset displayImage =  "/shared/images/Airy-3d.svg">
								<cfset hw = 'height="60%" width="60%"'>
							<cfelse>
								<cfset displayImage =  "/shared/images/Image-x-generic.svg">
								<cfset hw = 'height="60%" width="60%"'>
								<!---nothing was working for mime type--->
							</cfif>
						</cfif>
						<div class="media_widget">	
							<a href="#media.media_uri#" target="_blank" class="d-block my-0 w-100 active text-center" title="click to open full image">
								<img src="#displayImage#" class="mx-auto" alt="#alt#" #hw#>
							</a>
							<div class="mt-0 col-12 pb-1 px-0">
								<p class="text-center px-1 pb-1 mb-0 smaller col-12">
<!---									<cfif listcontainsnocase(session.roles,"manage_specimens")>
										<span class="d-inline">(<a target="_blank" href="/media.cfm?action=edit&media_id=#media_id#">edit</a>) </span>
									</cfif>--->
									(<a class="" target="_blank" href="/media/#media_id#">Media Record</a>)
									<cfif NOT isDisplayable>
										#media_type# (#mime_type#)
										(<a class="" target="_blank" href="#media_uri#">media file</a>)
									<cfelse>
										(<a class="" target="_blank" href="/MediaSet.cfm?media_id=#media_id#">zoom/related</a>)
										(<a class="" target="_blank" href="#media_uri#">full</a>)
									</cfif>
								</p>
								<div class="pb-1">
									<cfset showTitleText = trim(title)>
									<cfif len(showTitleText) EQ 0>
										<cfset showTitleText = trim(subject)>
									</cfif>
									<cfif len(showTitleText) EQ 0>
										<cfset showTitleText = "Unlinked Media Object">
									</cfif>
									<cfif #l_displayAs# EQ "thumb">
										<cfif len(showTitleText) GT 30>
											<cfset showTitleText = "#left(showTitleText,30)#..." >
										</cfif>
									</cfif>
									<p class="text-center col-12 my-0 p-0 smaller">#showTitleText#</p> 
									<cfif len(#license_uri#) gt 0>
										<p class="text-center col-12 p-0 my-0 smaller">
											<cfif #l_displayAs# NEQ "thumb">
												License: 
											</cfif>
											<a href="#license_uri#">#license_display#</a>
										</p>
									</cfif>
								</div>
							</div>
						</div>
					</cfloop>
				</cfif>
			<cfcatch>
				<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
				<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
				<cfset function_called = "#GetFunctionCalledName()#">
				<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
				<cfabort>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="mediaWidgetThread#tn#" />
	<cfreturn cfthread["mediaWidgetThread#tn#"].output>
</cffunction>
					
					
</cfcomponent>
