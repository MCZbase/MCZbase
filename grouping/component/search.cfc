<!---
grouping/component/search.cfc

Copyright 2020-2026 President and Fellows of Harvard College

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

<!---   Function getCollections  
   Obtain a list of named groups in a form suitable for display in a jqxgrid
	@return json containing data about named groups matching specified search criteria.
--->
<cffunction name="getCollections" access="remote" returntype="any" returnformat="json">
	<cfargument name="collection_name" type="string" required="no">
	<cfargument name="underscore_collection_type" type="string" required="no">
	<cfargument name="underscore_agent_id" type="string" required="no">
	<cfargument name="underscore_agent_name" type="string" required="no">
	<cfargument name="description" type="string" required="no">
	<cfargument name="underscore_collection_id" type="string" required="no">
	<cfargument name="guid" type="string" required="no">
	<cfargument name="collection_id" type="string" required="no">

	<cfset data = ArrayNew(1)>
	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="search_result" timeout="#Application.query_timeout#">
			SELECT count(underscore_relation.collection_object_id) as specimen_count, 
				underscore_collection.underscore_collection_id as underscore_collection_id, 
				collection_name,
				underscore_collection_type,
				description,
				GET_UNDCOLLAGENTS(underscore_collection.underscore_collection_id) as agentname,
				displayed_media_id,
				decode(mask_fg,1,'Hidden','Public') as visibility
			FROM underscore_collection
				left join underscore_relation on underscore_collection.underscore_collection_id = underscore_relation.underscore_collection_id
				<cfif (isDefined("guid") and len(guid) gt 0) OR (isDefined("collection_id") AND len(collection_id) GT 0)>
					left join #session.flatTableName# on underscore_relation.collection_object_id = #session.flatTableName#.collection_object_id
				</cfif>
				<cfif (isDefined("underscore_agent_id") and len(underscore_agent_id) gt 0) OR (isDefined("underscore_agent_name") AND len(underscore_agent_name) GT 0)>
					left join underscore_collection_agent on underscore_collection.underscore_collection_id = underscore_collection_agent.underscore_collection_id
				</cfif>
			WHERE
				underscore_collection.underscore_collection_id is not null
				<cfif NOT isdefined("session.roles") OR NOT listfindnocase(session.roles,"manage_specimens")>
					AND mask_fg = 0
				<cfelse>
					<cfif isDefined("mask_fg") AND len(mask_fg) gt 0>
						AND mask_fg = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#mask_fg#">
					</cfif>
				</cfif>
				<cfif isDefined("underscore_collection_id") and len(underscore_collection_id) gt 0>
					AND underscore.collection.underscore_Collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
				<cfelseif isDefined("collection_name") and len(collection_name) gt 0>
					and collection_name like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#collection_name#%">
				</cfif>
				<cfif isDefined("underscore_collection_type") and len(underscore_collection_type) gt 0>
					and underscore_collection_type like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#underscore_collection_type#">
				</cfif>
				<cfif isDefined("description") and len(description) gt 0>
					and upper(description) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(description)#%">
				</cfif>
				<cfif isDefined("underscore_agent_id") and len(underscore_agent_id) gt 0>
					and 
					( underscore_collection_agent.agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_agent_id#">
					<cfif isDefined("underscore_agent_name") and underscore_agent_name EQ "[no agent name]">
					 or underscore_collection_agent.underscore_collection_id IS NULL	
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
				underscore_collection_type,
				description,
				GET_UNDCOLLAGENTS(underscore_collection.underscore_collection_id),
				displayed_media_id,
				mask_fg
			ORDER BY
				upper(underscore_collection.collection_name)
		</cfquery>
		<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfset columnNames = ListToArray(search.columnList)>
			<cfloop array="#columnNames#" index="columnName">
				<cfset row["#columnName#"] = "#search[columnName][currentrow]#">
				<cfquery name="getClob" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getClob_result">
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
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="search_result" timeout="#Application.query_timeout#">
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
				<cfif NOT isdefined("session.roles") OR NOT listfindnocase(session.roles,"manage_specimens")>
					AND mask_fg = 0
				</cfif>
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
		<cfquery name="search"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="search_result" timeout="#Application.query_timeout#" >
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
				<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_specimens")>
					flat.cabinets, 
				</cfif>
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
		<cfquery name="search"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="search_result" cachedwithin="#CreateTimespan(0,1,0,0)#" timeout="#Application.query_timeout#" >
			SELECT DISTINCT 
				flat.guid, 
				flat.scientific_name, 
				flat.verbatim_date, 
				flat.higher_geog, 
				flat.spec_locality,
				flat.othercatalognumbers, 
				<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_specimens")>
					flat.cabinets, 
				</cfif>
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

<cffunction name="getSpecimenImageMetadata" access="remote" returntype="any" returnformat="json">
	<cfargument name="underscore_collection_id" type="string" required="yes">

	<cfset data = ArrayNew(1)>
	<cftry>
		<cfquery name="getNamedGroup" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getNamedGroup_result" timeout="#Application.short_timeout#">
			SELECT underscore_collection_id, collection_name, description, html_description,
				mask_fg,
				displayed_media_id
			FROM underscore_collection
			WHERE underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
		</cfquery>
		<cfif getNamedGroup.mask_fg EQ 1 AND (NOT isdefined("session.roles") OR listfindnocase(session.roles,"coldfusion_user") EQ 0)>
			<!--- return no records --->
		<cfelse> 
			<cfset displayed_media_id = getNamedGroup.displayed_media_id>
			<cfquery name="specimenMedia_raw" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="specimenMedia_raw_result" cachedwithin="#CreateTimespan(0,24,0,0)#" timeout="#Application.query_timeout#" >
				<cfif len(displayed_media_id) GT 0>
				SELECT distinct media.media_id, 
					media.media_uri, 
					MCZBASE.get_media_descriptor(media.media_id) as alt,
					MCZBASE.is_media_encumbered(media.media_id)  as encumb,
					media.media_type,
					media.mime_type,
					1 as topsort
				FROM media
				WHERE
					media.media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#displayed_media_id#">
				UNION
				</cfif>
				SELECT distinct media.media_id, 
					media.media_uri, 
					MCZBASE.get_media_descriptor(media.media_id) as alt,
					MCZBASE.is_media_encumbered(media.media_id)  as encumb,
					media.media_type,
					media.mime_type,
					2 as topsort
				FROM
					underscore_collection
					left join underscore_relation on underscore_collection.underscore_collection_id = underscore_relation.underscore_collection_id
					left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat 
						on underscore_relation.collection_object_id = flat.collection_object_id
					left join media_relations
						on media_relations.related_primary_key = underscore_relation.collection_object_id
					left join media on media_relations.media_id = media.media_id							
				WHERE underscore_collection.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
					AND media_relations.media_relationship = 'shows cataloged_item'
					AND flat.guid is not null
				<cfif len(displayed_media_id) GT 0>
					AND media.media_id <> <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#displayed_media_id#">
				</cfif>
			</cfquery>
			<cfquery name="specimenImagesForCarousel" dbtype="query">
				SELECT * 
				FROM specimenMedia_raw 
				WHERE encumb < 1
					AND media_type = 'image'
					AND (mime_type = 'image/jpeg' OR mime_type = 'image/png')
				ORDER BY topsort asc, media_id
			</cfquery>
			<cfif specimenImagesForCarousel.recordcount GT 0>
				<cfset i = 1>
				<cfloop query="specimenImagesForCarousel">
					<cfset row = StructNew()>
					<cfset row["media_id"] = "#media_id#">
					<cfset row["media_uri"] = "#media_uri#">
					<cfset altEscaped = replace(replace(alt,"'","&##8217;","all"),'"',"&quot;","all") >
					<cfset row["alt"] = "#altEscaped#">
					<cfset data[i]  = row>
					<cfset i = i + 1>
				</cfloop>
			</cfif>
		</cfif>
	<cfcatch>
		<cfset error_message = cfcatchToErrorMessage(cfcatch)>
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn #serializeJSON(data)#>
</cffunction>

<!--- Function getSpecimenMediaForGroup
	Obtain the media shown with the cataloged items in a named group, with whether each is encumbered for
	the current user, cached.  Media descriptors are not included, as computing them for every image of a
	large group is slow; see getMediaDescriptors.  is_media_encumbered is in the select list, not the where
	clause, so Oracle evaluates it only on the group's rows.
	@param underscore_collection_id the named group whose specimen media to return.
	@param displayed_media_id the group's displayed_media_id, which is given topsort 1, may be blank.
	@return query of media_id, media_uri, encumb, media_type, mime_type and topsort.
--->
<cffunction name="getSpecimenMediaForGroup" access="public" returntype="query">
	<cfargument name="underscore_collection_id" type="string" required="yes">
	<cfargument name="displayed_media_id" type="string" required="yes">

	<cfquery name="local.specimenMedia" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="local.specimenMedia_result" cachedwithin="#CreateTimespan(0,24,0,0)#" timeout="#Application.query_timeout#">
		<cfif len(arguments.displayed_media_id) GT 0>
		SELECT DISTINCT media.media_id,
			media.media_uri,
			MCZBASE.is_media_encumbered(media.media_id) AS encumb,
			media.media_type,
			media.mime_type,
			1 AS topsort
		FROM media
		WHERE
			media.media_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.displayed_media_id#">
		UNION
		</cfif>
		SELECT DISTINCT media.media_id,
			media.media_uri,
			MCZBASE.is_media_encumbered(media.media_id) AS encumb,
			media.media_type,
			media.mime_type,
			2 AS topsort
		FROM
			underscore_collection
			LEFT JOIN underscore_relation ON underscore_collection.underscore_collection_id = underscore_relation.underscore_collection_id
			LEFT JOIN <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat
				ON underscore_relation.collection_object_id = flat.collection_object_id
			LEFT JOIN media_relations
				ON media_relations.related_primary_key = underscore_relation.collection_object_id
			LEFT JOIN media ON media_relations.media_id = media.media_id
		WHERE underscore_collection.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.underscore_collection_id#">
			AND media_relations.media_relationship = 'shows cataloged_item'
			AND flat.guid IS NOT NULL
			<cfif len(arguments.displayed_media_id) GT 0>
				AND media.media_id <> <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.displayed_media_id#">
			</cfif>
	</cfquery>
	<cfreturn local.specimenMedia>
</cffunction>

<!--- Function getSpecimenImagesForGroup
	Obtain the jpeg and png images of the cataloged items in a named group that the current user may see,
	in carousel order.  grouping/showNamedCollection.cfm and getSpecimenImagesAt both call this function,
	so they share one cached query, from getSpecimenMediaForGroup.
	@param underscore_collection_id the named group whose specimen images to return.
	@param displayed_media_id the group's displayed_media_id, which is placed first, may be blank.
	@return query of media_id, media_uri and topsort, ordered by topsort then media_id.
--->
<cffunction name="getSpecimenImagesForGroup" access="public" returntype="query">
	<cfargument name="underscore_collection_id" type="string" required="yes">
	<cfargument name="displayed_media_id" type="string" required="yes">

	<cfset local.specimenMedia = getSpecimenMediaForGroup(underscore_collection_id=arguments.underscore_collection_id, displayed_media_id=arguments.displayed_media_id)>
	<cfquery name="local.specimenImages" dbtype="query">
		SELECT media_id, media_uri, topsort
		FROM local.specimenMedia
		WHERE encumb < 1
			AND media_type = 'image'
			AND (mime_type = 'image/jpeg' OR mime_type = 'image/png')
		ORDER BY topsort ASC, media_id
	</cfquery>
	<cfreturn local.specimenImages>
</cffunction>

<!--- Function getMediaDescriptors
	Obtain the textual descriptions used as alt text and captions for a few media records.  Not remote:
	callers pass only media the current user may see.
	@param media_ids comma separated list of media_id values.
	@return query of media_id and alt.
--->
<cffunction name="getMediaDescriptors" access="public" returntype="query">
	<cfargument name="media_ids" type="string" required="yes">

	<cfquery name="local.descriptors" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="local.descriptors_result" timeout="#Application.short_timeout#">
		SELECT media_id,
			MCZBASE.get_media_descriptor(media_id) AS alt
		FROM media
		WHERE media_id IN (<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.media_ids#" list="yes">)
	</cfquery>
	<cfreturn local.descriptors>
</cffunction>

<!--- Function getSpecimenImagesAt
	Obtain the specimen images at given positions in a named group's specimen image carousel on
	grouping/showNamedCollection.cfm, so the carousel loads only the images it shows or prefetches.
	@param underscore_collection_id the named group whose specimen images to return.
	@param positions comma separated list of one based carousel positions, at most MAX_POSITIONS are used.
	@return json object with count, the number of images in the carousel, and images, an array of objects
		with position, media_id, media_uri and alt (html encoded); empty if the group is hidden from the
		current user.
--->
<cffunction name="getSpecimenImagesAt" access="remote" returntype="any" returnformat="json">
	<cfargument name="underscore_collection_id" type="string" required="yes">
	<cfargument name="positions" type="string" required="yes">

	<cfset var MAX_POSITIONS = 10>
	<cfset var data = StructNew()>
	<cfset var wantedPositions = ArrayNew(1)>
	<cfset var position = "">
	<cfset var mediaIds = "">
	<cfset var altById = StructNew()>
	<cfset var row = "">
	<cfset data["count"] = 0>
	<cfset data["images"] = ArrayNew(1)>
	<cftry>
		<cfquery name="local.checkGroup" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="local.checkGroup_result" timeout="#Application.short_timeout#">
			SELECT underscore_collection_id, displayed_media_id
			FROM underscore_collection
			WHERE underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.underscore_collection_id#">
				<cfif NOT isdefined("session.roles") OR listfindnocase(session.roles,"coldfusion_user") EQ 0>
					AND mask_fg = 0
				</cfif>
		</cfquery>
		<cfif local.checkGroup.recordcount EQ 1>
			<cfset local.images = getSpecimenImagesForGroup(underscore_collection_id=arguments.underscore_collection_id, displayed_media_id=local.checkGroup.displayed_media_id)>
			<cfset data["count"] = local.images.recordcount>
			<cfloop list="#arguments.positions#" index="position">
				<cfset position = trim(position)>
				<cfif isValid("integer", position) AND position GTE 1 AND position LTE local.images.recordcount AND NOT ArrayContains(wantedPositions, position) AND ArrayLen(wantedPositions) LT MAX_POSITIONS>
					<cfset ArrayAppend(wantedPositions, position)>
					<cfset mediaIds = ListAppend(mediaIds, local.images.media_id[position])>
				</cfif>
			</cfloop>
			<cfif ArrayLen(wantedPositions) GT 0>
				<cfset local.descriptors = getMediaDescriptors(media_ids=mediaIds)>
				<cfloop query="local.descriptors">
					<cfset altById[local.descriptors.media_id] = local.descriptors.alt>
				</cfloop>
				<cfloop array="#wantedPositions#" index="position">
					<cfset row = StructNew()>
					<cfset row["position"] = position>
					<cfset row["media_id"] = "#local.images.media_id[position]#">
					<cfset row["media_uri"] = "#local.images.media_uri[position]#">
					<cfset row["alt"] = "">
					<cfif structKeyExists(altById, local.images.media_id[position])>
						<cfset row["alt"] = encodeForHtml(altById[local.images.media_id[position]])>
					</cfif>
					<cfset ArrayAppend(data["images"], row)>
				</cfloop>
			</cfif>
		</cfif>
	<cfcatch>
		<cfset var error_message = cfcatchToErrorMessage(cfcatch)>
		<cfset var function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn serializeJSON(data)>
</cffunction>

<!--- Function getNamedGroupHeatmapPoints
	Obtain the georeferenced localities of the cataloged items in a named group, for the map on
	grouping/showNamedCollection.cfm.
	@param underscore_collection_id the named group whose localities to return.
	@return json array of objects with latitude, longitude, and weight (the number of records at
		that locality), empty if the group is hidden from the current user.
--->
<cffunction name="getNamedGroupHeatmapPoints" access="remote" returntype="any" returnformat="json">
	<cfargument name="underscore_collection_id" type="string" required="yes">

	<cfset var data = ArrayNew(1)>
	<cfset var row = "">
	<cftry>
		<cfquery name="local.checkGroup" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="local.checkGroup_result" timeout="#Application.short_timeout#">
			SELECT underscore_collection_id
			FROM underscore_collection
			WHERE underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.underscore_collection_id#">
				<cfif NOT isdefined("session.roles") OR listfindnocase(session.roles,"coldfusion_user") EQ 0>
					AND mask_fg = 0
				</cfif>
		</cfquery>
		<cfif local.checkGroup.recordcount EQ 1>
			<cfquery name="local.points" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="local.points_result" cachedwithin="#CreateTimespan(0,24,0,0)#" timeout="#Application.query_timeout#">
				SELECT
					flat.dec_lat as latitude,
					flat.dec_long as longitude,
					count(*) as record_count
				FROM
					underscore_relation
					join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat
						on underscore_relation.collection_object_id = flat.collection_object_id
				WHERE
					underscore_relation.underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.underscore_collection_id#">
					AND flat.guid IS NOT NULL
					AND flat.dec_lat IS NOT NULL
					AND flat.dec_lat BETWEEN -90 AND 90
					AND flat.dec_long BETWEEN -180 AND 180
				GROUP BY
					flat.locality_id,
					flat.dec_lat,
					flat.dec_long
			</cfquery>
			<cfloop query="local.points">
				<cfset row = StructNew()>
				<cfset row["latitude"] = val(local.points.latitude)>
				<cfset row["longitude"] = val(local.points.longitude)>
				<cfset row["weight"] = val(local.points.record_count)>
				<cfset ArrayAppend(data, row)>
			</cfloop>
		</cfif>
	<cfcatch>
		<cfset var error_message = cfcatchToErrorMessage(cfcatch)>
		<cfset var function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn serializeJSON(data)>
</cffunction>

</cfcomponent>
