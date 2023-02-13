<!---
localities/component/search.cfc

Copyright 2021 President and Fellows of Harvard College

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

<!--- function setupClause setup variables to put into a where clause of a query.

	Expected use: 

	<cfif isdefined("country") AND len(country) gt 0>
		<cfset setup = setupClause(field="geog_auth_rec.country",value="#country#")>
		<cfif len(retval["value"]) EQ 0>
			AND #retval["pre"]# #retval["post"]#
		<cfelse>
			AND #retval["pre"]# <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#retval['value']#" list="#retval['list']#"> #retval["post"]#
		</cfif>
	</cfif>
	

 @param field the field name, possibly needing to be prefixed by the tablename
	field must be supplied a string value, not a variable, and must not be supplied 
   from a user, otherwise could be used for sql injection.
 @param the value to be queried for, supports the following:
	NULL, NOT NULL, operators as leading characters =, !, $, !$, ~, !~,
   and a comma separated list
 @return a struct with the properties pre, value, list, and post.
--->
<cffunction name="setupClause" access="private" returntype="struct">
	<cfargument name="field" type="string" required="yes">
	<cfargument name="value" type="string" required="yes">
	<cfset retval = StructNew()>
	<cfset pre = "#field#">
	<cfset post = "">
	<cfset list = "no">
	<cfif ucase(value) EQ "NULL">
		<cfset value= "">
		<cfset post= "IS NULL">
	<cfelseif ucase(value) EQ "NOT NULL">
		<cfset value= "">
		<cfset value= "IS NOT NULL">
	<cfelseif left(value,1) is "=">
		<cfset pre="#field# =">
		<cfset value="#ucase(right(value,len(value)-1))#">
	<cfelseif left(value,1) is "~">
		<cfset pre="utl_match.jaro_winkler(#value#,">
		<cfset value="#right(value,len(value)-1)#">
		<cfset post = ") >= 0.90"><!--- " --->
	<cfelseif left(value,2) is "!~">
		<cfset pre="utl_match.jaro_winkler(#value#,"> 
		<cfset value="#right(value,len(value)-2)#">
		<cfset post=") < 0.90">
	<cfelseif left(value,1) is "$">
		<cfset pre="soundex(#value#) =  soundex(">
		<cfset value="#ucase(right(value,len(value)-1))#">
		<cfset post=")">
	<cfelseif left(value,2) is "!$">
		<cfset pre="soundex(#value#) <> soundex("><!--- ") --->
		<cfset value="#ucase(right(value,len(value)-2))#">
		<cfset post=")">
	<cfelseif left(value,1) is "!">
		<cfset pre="upper(#value#) <>"><!--- " --->
		<cfset value="#ucase(right(value,len(value)-1))#">
		<cfset post="">
	<cfelseif find(',',value) GT 0>
		<cfset pre="upper(#value#) in (">
		<cfset value="#ucase(value)#">
		<cfset post = ")">
		<cfset list="yes">
	<cfelse>
		<cfset pre="upper(#value#) LIKE ">
		<cfset value="%#ucase(value)#%">
		<cfset post ="">
	</cfif>
	<cfset retval["pre"]=pre>
	<cfset retval["value"]=value>
	<cfset retval["post"]=post>
	<cfset retval["list"]=list>
	<cfreturn retval>
</cffunction>

<!---
Function getSpecLocalityAutocomplete.  Search for spec_locality by name with a substring match on name, returning json suitable for jquery-ui autocomplete.

@param term spec_locality name to search for.
@return a json structure containing id and value, with matching with matched name in value and id.
--->
<cffunction name="getSpecLocalityAutocomplete" access="remote" returntype="any" returnformat="json">
	<cfargument name="term" type="string" required="yes">
	<!--- perform wildcard search anywhere in locality.spec_locality --->
	<cfset name = "%#term#%"> 

	<cfset data = ArrayNew(1)>
	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			SELECT 
				count(flat.collection_object_id) as ct,
				locality.spec_locality
			FROM 
				locality
					LEFT JOIN <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat
						on locality.locality_id = flat.locality_id
			WHERE
				upper(locality.spec_locality) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(name)#">
			GROUP BY
				locality.spec_locality
		</cfquery>
		<cfset rows = search_result.recordcount>
			<cfset i = 1>
			<cfloop query="search">
				<cfset row = StructNew()>
				<cfset row["id"] = "#search.spec_locality#">
				<cfset row["value"] = "#search.spec_locality#" >
				<cfset row["meta"] = "#search.ct# spec." >
				<cfset data[i]  = row>
				<cfset i = i + 1>
			</cfloop>
			<cfreturn #serializeJSON(data)#>
		<cfcatch>
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
	</cftry>
	<cfreturn #serializeJSON(data)#>
</cffunction>

<!---
Function getCountryAutocomplete.  Search for country by name with a substring match on name, returning json suitable for jquery-ui autocomplete.

@param term country name to search for.
@return a json structure containing id and value, with matching with matched name in value and id.
--->
<cffunction name="getCountryAutocomplete" access="remote" returntype="any" returnformat="json">
	<cfargument name="term" type="string" required="yes">
	<!--- perform wildcard search anywhere in geog_auth_rec.country --->
	<cfset name = "%#term#%"> 

	<cfset data = ArrayNew(1)>
	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			SELECT 
				count(flat.collection_object_id) as ct,
				count(distinct geog_auth_rec.geog_auth_rec_id) as geoct,
				geog_auth_rec.country
			FROM 
				geog_auth_rec
					LEFT JOIN <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat
						on geog_auth_rec.geog_auth_rec_id = flat.geog_auth_rec_id
			WHERE
				upper(geog_auth_rec.country) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(name)#">
			GROUP BY
				geog_auth_rec.country
			ORDER BY
				geog_auth_rec.country
		</cfquery>
	<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfset row["id"] = "#search.country#">
			<cfset row["value"] = "#search.country#" >
			<cfset row["meta"] = "#search.geoct# geog., #search.ct# spec." >
			<cfset data[i]  = row>
			<cfset i = i + 1>
		</cfloop>
		<cfreturn #serializeJSON(data)#>
	<cfcatch>
		<cfset error_message = cfcatchToErrorMessage(cfcatch)>
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn #serializeJSON(data)#>
</cffunction>

<!---
Function getGeogAutocomplete.  Search for distinct values of a particular higher geography 
  by name with a substring match on name, returning json suitable for jquery-ui autocomplete.

@param term value of the name to search for.
@param rank the rank to search (accepts any of the atomic field names in geog_auth_rec).
@return a json structure containing id and value, and meta, with matching with matched name in value and id, 
  and count metadata in meta.
--->
<cffunction name="getGeogAutocomplete" access="remote" returntype="any" returnformat="json">
	<cfargument name="term" type="string" required="yes">
	<cfargument name="rank" type="string" required="yes">
	<!--- perform wildcard search anywhere in target field --->
	<cfset name = "%#term#%"> 

	<cfset data = ArrayNew(1)>
	<cftry>
		<cfset rows = 0>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			SELECT count(*) as ct,
				<cfswitch expression="#rank#">
					<cfcase value="continent_ocean">continent_ocean as name</cfcase>
					<cfcase value="ocean_region">ocean_region as name</cfcase>
					<cfcase value="ocean_subregion">ocean_subregion as name</cfcase>
					<cfcase value="country">country as name</cfcase>
					<cfcase value="state_prov">state_prov as name</cfcase>
					<cfcase value="county">county as name</cfcase>
					<cfcase value="quad">quad as name</cfcase>
					<cfcase value="feature">feature as name</cfcase>
					<cfcase value="water_feature">water_feature as name</cfcase>
					<cfcase value="island_group">island_group as name</cfcase>
					<cfcase value="island">island as name</cfcase>
					<cfcase value="sea">sea as name</cfcase>
					<cfcase value="highergeographyid">highergeographyid as name</cfcase>
					<cfcase value="source_authority">source_authority as name</cfcase>
				</cfswitch>
			FROM 
				geog_auth_rec
			WHERE
				<cfswitch expression="#rank#">
					<cfcase value="continent_ocean">upper (continent_ocean )</cfcase>
					<cfcase value="ocean_region">upper (ocean_region )</cfcase>
					<cfcase value="ocean_subregion">upper (ocean_subregion )</cfcase>
					<cfcase value="country">upper (country )</cfcase>
					<cfcase value="state_prov">upper (state_prov )</cfcase>
					<cfcase value="county">upper (county )</cfcase>
					<cfcase value="quad">upper (quad )</cfcase>
					<cfcase value="feature">upper (feature )</cfcase>
					<cfcase value="water_feature">upper (water_feature )</cfcase>
					<cfcase value="island_group">upper (island_group )</cfcase>
					<cfcase value="island">upper (island )</cfcase>
					<cfcase value="sea">upper (sea )</cfcase>
					<cfcase value="highergeographyid">upper (highergeographyid )</cfcase>
					<cfcase value="source_authority">upper (source_authority )</cfcase>
				</cfswitch>
				like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(name)#">
			GROUP BY 
				<cfswitch expression="#rank#">
					<cfcase value="continent_ocean">continent_ocean</cfcase>
					<cfcase value="ocean_region">ocean_region</cfcase>
					<cfcase value="ocean_subregion">ocean_subregion</cfcase>
					<cfcase value="country">country</cfcase>
					<cfcase value="state_prov">state_prov</cfcase>
					<cfcase value="county">county</cfcase>
					<cfcase value="quad">quad</cfcase>
					<cfcase value="feature">feature</cfcase>
					<cfcase value="water_feature">water_feature</cfcase>
					<cfcase value="island_group">island_group</cfcase>
					<cfcase value="island">island</cfcase>
					<cfcase value="sea">sea</cfcase>
					<cfcase value="highergeographyid">highergeographyid</cfcase>
					<cfcase value="source_authority">source_authority</cfcase>
				</cfswitch>
			ORDER BY
				<cfswitch expression="#rank#">
					<cfcase value="continent_ocean">continent_ocean</cfcase>
					<cfcase value="ocean_region">ocean_region</cfcase>
					<cfcase value="ocean_subregion">ocean_subregion</cfcase>
					<cfcase value="country">country</cfcase>
					<cfcase value="state_prov">state_prov</cfcase>
					<cfcase value="county">county</cfcase>
					<cfcase value="quad">quad</cfcase>
					<cfcase value="feature">feature</cfcase>
					<cfcase value="water_feature">water_feature</cfcase>
					<cfcase value="island_group">island_group</cfcase>
					<cfcase value="island">island</cfcase>
					<cfcase value="sea">sea</cfcase>
					<cfcase value="highergeographyid">highergeographyid</cfcase>
					<cfcase value="source_authority">source_authority</cfcase>
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
		<cfset error_message = cfcatchToErrorMessage(cfcatch)>
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn #serializeJSON(data)#>
</cffunction>

<!---   Function getHigherGeographies
   Obtain a list of higher geographies in a form suitable for display in a jqxgrid
	@return json containing data about higher geographies matching specified search criteria.
--->
<cffunction name="getHigherGeographies" access="remote" returntype="any" returnformat="json">
	<cfargument name="higher_geog" type="string" required="no">
	<cfargument name="geog_auth_rec_id" type="string" required="no">
	<cfargument name="continent_ocean" type="string" required="no">
	<cfargument name="ocean_region" type="string" required="no">
	<cfargument name="ocean_subregion" type="string" required="no">
	<cfargument name="sea" type="string" required="no">
	<cfargument name="island" type="string" required="no">
	<cfargument name="island_group" type="string" required="no">
	<cfargument name="feature" type="string" required="no">
	<cfargument name="water_feature" type="string" required="no">
	<cfargument name="country" type="string" required="no">
	<cfargument name="state_prov" type="string" required="no">
	<cfargument name="county" type="string" required="no">
	<cfargument name="highergeographyid" type="string" required="no">
	<cfargument name="highergeographyid_guid_type" type="string" required="no">
	<cfargument name="return_wkt" type="string" required="no">

	<cfif NOT isDefined("return_wkt")><cfset return_wkt=""></cfif>
	<cfset linguisticFlag = false>
	<cfif isdefined("accentInsensitive") AND accentInsensitive EQ 1>
		<cfset linguisticFlag=true>
	</cfif>

	<cfset data = ArrayNew(1)>
	<cftry>
		<cfset rows = 0>
		<cfif linguisticFlag >
			<!--- Set up the session to run an accent insensitive search --->
			<cfquery datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				ALTER SESSION SET NLS_COMP = LINGUISTIC
			</cfquery>
			<cfquery datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				ALTER SESSION SET NLS_SORT = GENERIC_M_AI
			</cfquery>
		</cfif>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			SELECT 
				 geog_auth_rec.geog_auth_rec_id,
				 geog_auth_rec.continent_ocean,
				 geog_auth_rec.country,
				 geog_auth_rec.state_prov,
				 geog_auth_rec.county,
				 geog_auth_rec.quad,
				 geog_auth_rec.feature,
				 geog_auth_rec.island,
				 geog_auth_rec.island_group,
				 geog_auth_rec.sea,
				 geog_auth_rec.valid_catalog_term_fg,
				 geog_auth_rec.source_authority,
				 geog_auth_rec.higher_geog,
				 geog_auth_rec.ocean_region,
				 geog_auth_rec.ocean_subregion,
				 geog_auth_rec.water_feature,
				<cfif return_wkt EQ "true">
					 geog_auth_rec.wkt_polygon,
				<cfelse>
					 nvl2(geog_auth_rec.wkt_polygon,'Yes','No') as wkt_polygon,
				</cfif>
				 geog_auth_rec.highergeographyid_guid_type,
				 geog_auth_rec.highergeographyid,
				 count(flatTableName.collection_object_id) as specimen_count
			FROM 
				geog_auth_rec
				left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>flat<cfelse>filtered_flat</cfif> flatTableName on geog_auth_rec.geog_auth_rec_id=flatTableName.geog_auth_rec_id
			WHERE
				geog_auth_rec.geog_auth_rec_id is not null
				<cfif isDefined("higher_geog") and len(higher_geog) gt 0>
					<cfif left(higher_geog,1) is "=">
						AND upper(geog_auth_rec.higher_geog) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(higher_geog,len(higher_geog)-1))#">
					<cfelse>
						and geog_auth_rec.higher_geog like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#higher_geog#%">
					</cfif>
				</cfif>
				<cfif isDefined("valid_catalog_term_fg") and len(valid_catalog_term_fg) gt 0>
						and geog_auth_rec.valid_catalog_term_fg = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#valid_catalog_term_fg#">
				</cfif>
				<cfif isdefined("continent_ocean") AND len(continent_ocean) gt 0>
					<cfif ucase(continent_ocean) EQ "NULL">
						and geog_auth_rec.continent_ocean IS NULL
					<cfelseif ucase(continent_ocean) EQ "NOT NULL">
						and geog_auth_rec.continent_ocean IS NOT NULL
					<cfelseif left(continent_ocean,1) is "=">
						AND upper(geog_auth_rec.continent_ocean) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(continent_ocean,len(continent_ocean)-1))#">
					<cfelseif left(continent_ocean,1) is "~">
						AND utl_match.jaro_winkler(geog_auth_rec.continent_ocean, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(continent_ocean,len(continent_ocean)-1)#">) >= 0.90
					<cfelseif left(continent_ocean,1) is "!~">
						AND utl_match.jaro_winkler(geog_auth_rec.continent_ocean, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(continent_ocean,len(continent_ocean)-1)#">) < 0.90
					<cfelseif left(continent_ocean,1) is "$">
						AND soundex(geog_auth_rec.continent_ocean) = soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(continent_ocean,len(continent_ocean)-1))#">)
					<cfelseif left(continent_ocean,2) is "!$">
						AND soundex(geog_auth_rec.continent_ocean) <> soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(continent_ocean,len(continent_ocean)-2))#">)
					<cfelseif left(continent_ocean,1) is "!">
						AND upper(geog_auth_rec.continent_ocean) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(continent_ocean,len(continent_ocean)-1))#">
					<cfelse>
						<cfif find(',',continent_ocean) GT 0>
							AND upper(geog_auth_rec.continent_ocean) in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(continent_ocean)#" list="yes"> )
						<cfelse>
							AND upper(geog_auth_rec.continent_ocean) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(continent_ocean)#%">
						</cfif>
					</cfif>
				</cfif>
				<cfif isdefined("country") AND len(country) gt 0>
					<cfif ucase(country) EQ "NULL">
						and geog_auth_rec.country IS NULL
					<cfelseif ucase(country) EQ "NOT NULL">
						and geog_auth_rec.country IS NOT NULL
					<cfelseif left(country,1) is "=">
						AND upper(geog_auth_rec.country) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(country,len(country)-1))#">
					<cfelseif left(country,1) is "~">
						AND utl_match.jaro_winkler(geog_auth_rec.country, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(country,len(country)-1)#">) >= 0.90
					<cfelseif left(country,1) is "!~">
						AND utl_match.jaro_winkler(geog_auth_rec.country, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(country,len(country)-1)#">) < 0.90
					<cfelseif left(country,1) is "$">
						AND soundex(geog_auth_rec.country) = soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(country,len(country)-1))#">)
					<cfelseif left(country,2) is "!$">
						AND soundex(geog_auth_rec.country) <> soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(country,len(country)-2))#">)
					<cfelseif left(country,1) is "!">
						AND upper(geog_auth_rec.country) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(country,len(country)-1))#">
					<cfelse>
						<cfif find(',',country) GT 0>
							AND upper(geog_auth_rec.country) in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(country)#" list="yes"> )
						<cfelse>
							AND upper(geog_auth_rec.country) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(country)#%">
						</cfif>
					</cfif>
				</cfif>
				<cfif isdefined("state_prov") AND len(state_prov) gt 0>
					<cfif ucase(state_prov) EQ "NULL">
						and geog_auth_rec.state_prov IS NULL
					<cfelseif ucase(state_prov) EQ "NOT NULL">
						and geog_auth_rec.state_prov IS NOT NULL
					<cfelseif left(state_prov,1) is "=">
						AND upper(geog_auth_rec.state_prov) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(state_prov,len(state_prov)-1))#">
					<cfelseif left(state_prov,1) is "~">
						AND utl_match.jaro_winkler(geog_auth_rec.state_prov, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(state_prov,len(state_prov)-1)#">) >= 0.90
					<cfelseif left(state_prov,1) is "!~">
						AND utl_match.jaro_winkler(geog_auth_rec.state_prov, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(state_prov,len(state_prov)-1)#">) < 0.90
					<cfelseif left(state_prov,1) is "$">
						AND soundex(geog_auth_rec.state_prov) = soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(state_prov,len(state_prov)-1))#">)
					<cfelseif left(state_prov,2) is "!$">
						AND soundex(geog_auth_rec.state_prov) <> soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(state_prov,len(state_prov)-2))#">)
					<cfelseif left(state_prov,1) is "!">
						AND upper(geog_auth_rec.state_prov) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(state_prov,len(state_prov)-1))#">
					<cfelse>
						<cfif find(',',state_prov) GT 0>
							AND upper(geog_auth_rec.state_prov) in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(state_prov)#" list="yes"> )
						<cfelse>
							AND upper(geog_auth_rec.state_prov) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(state_prov)#%">
						</cfif>
					</cfif>
				</cfif>
				<cfif isdefined("county") AND len(county) gt 0>
					<cfif ucase(county) EQ "NULL">
						and geog_auth_rec.county IS NULL
					<cfelseif ucase(county) EQ "NOT NULL">
						and geog_auth_rec.county IS NOT NULL
					<cfelseif left(county,1) is "=">
						AND upper(geog_auth_rec.county) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(county,len(county)-1))#">
					<cfelseif left(county,1) is "~">
						AND utl_match.jaro_winkler(geog_auth_rec.county, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(county,len(county)-1)#">) >= 0.90
					<cfelseif left(county,1) is "!~">
						AND utl_match.jaro_winkler(geog_auth_rec.county, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(county,len(county)-1)#">) < 0.90
					<cfelseif left(county,1) is "$">
						AND soundex(geog_auth_rec.county) = soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(county,len(county)-1))#">)
					<cfelseif left(county,2) is "!$">
						AND soundex(geog_auth_rec.county) <> soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(county,len(county)-2))#">)
					<cfelseif left(county,1) is "!">
						AND upper(geog_auth_rec.county) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(county,len(county)-1))#">
					<cfelse>
						<cfif find(',',county) GT 0>
							AND upper(geog_auth_rec.county) in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(county)#" list="yes"> )
						<cfelse>
							AND upper(geog_auth_rec.county) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(county)#%">
						</cfif>
					</cfif>
				</cfif>
				<cfif isdefined("quad") AND len(quad) gt 0>
					<cfif ucase(quad) EQ "NULL">
						and geog_auth_rec.quad IS NULL
					<cfelseif ucase(quad) EQ "NOT NULL">
						and geog_auth_rec.quad IS NOT NULL
					<cfelseif left(quad,1) is "=">
						AND upper(geog_auth_rec.quad) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(quad,len(quad)-1))#">
					<cfelseif left(quad,1) is "~">
						AND utl_match.jaro_winkler(geog_auth_rec.quad, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(quad,len(quad)-1)#">) >= 0.90
					<cfelseif left(quad,1) is "!~">
						AND utl_match.jaro_winkler(geog_auth_rec.quad, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(quad,len(quad)-1)#">) < 0.90
					<cfelseif left(quad,1) is "$">
						AND soundex(geog_auth_rec.quad) = soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(quad,len(quad)-1))#">)
					<cfelseif left(quad,2) is "!$">
						AND soundex(geog_auth_rec.quad) <> soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(quad,len(quad)-2))#">)
					<cfelseif left(quad,1) is "!">
						AND upper(geog_auth_rec.quad) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(quad,len(quad)-1))#">
					<cfelse>
						<cfif find(',',quad) GT 0>
							AND upper(geog_auth_rec.quad) in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(quad)#" list="yes"> )
						<cfelse>
							AND upper(geog_auth_rec.quad) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(quad)#%">
						</cfif>
					</cfif>
				</cfif>
				<cfif isdefined("feature") AND len(feature) gt 0>
					<cfif ucase(feature) EQ "NULL">
						and geog_auth_rec.feature IS NULL
					<cfelseif ucase(feature) EQ "NOT NULL">
						and geog_auth_rec.feature IS NOT NULL
					<cfelseif left(feature,1) is "=">
						AND upper(geog_auth_rec.feature) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(feature,len(feature)-1))#">
					<cfelseif left(feature,1) is "~">
						AND utl_match.jaro_winkler(geog_auth_rec.feature, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(feature,len(feature)-1)#">) >= 0.90
					<cfelseif left(feature,1) is "!~">
						AND utl_match.jaro_winkler(geog_auth_rec.feature, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(feature,len(feature)-1)#">) < 0.90
					<cfelseif left(feature,1) is "$">
						AND soundex(geog_auth_rec.feature) = soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(feature,len(feature)-1))#">)
					<cfelseif left(feature,2) is "!$">
						AND soundex(geog_auth_rec.feature) <> soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(feature,len(feature)-2))#">)
					<cfelseif left(feature,1) is "!">
						AND upper(geog_auth_rec.feature) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(feature,len(feature)-1))#">
					<cfelse>
						<cfif find(',',feature) GT 0>
							AND upper(geog_auth_rec.feature) in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(feature)#" list="yes"> )
						<cfelse>
							AND upper(geog_auth_rec.feature) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(feature)#%">
						</cfif>
					</cfif>
				</cfif>
				<cfif isdefined("island") AND len(island) gt 0>
					<cfif ucase(island) EQ "NULL">
						and geog_auth_rec.island IS NULL
					<cfelseif ucase(island) EQ "NOT NULL">
						and geog_auth_rec.island IS NOT NULL
					<cfelseif left(island,1) is "=">
						AND upper(geog_auth_rec.island) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(island,len(island)-1))#">
					<cfelseif left(island,1) is "~">
						AND utl_match.jaro_winkler(geog_auth_rec.island, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(island,len(island)-1)#">) >= 0.90
					<cfelseif left(island,1) is "!~">
						AND utl_match.jaro_winkler(geog_auth_rec.island, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(island,len(island)-1)#">) < 0.90
					<cfelseif left(island,1) is "$">
						AND soundex(geog_auth_rec.island) = soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(island,len(island)-1))#">)
					<cfelseif left(island,2) is "!$">
						AND soundex(geog_auth_rec.island) <> soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(island,len(island)-2))#">)
					<cfelseif left(island,1) is "!">
						AND upper(geog_auth_rec.island) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(island,len(island)-1))#">
					<cfelse>
						<cfif find(',',island) GT 0>
							AND upper(geog_auth_rec.island) in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(island)#" list="yes"> )
						<cfelse>
							AND upper(geog_auth_rec.island) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(island)#%">
						</cfif>
					</cfif>
				</cfif>
				<cfif isdefined("island_group") AND len(island_group) gt 0>
					<cfif ucase(island_group) EQ "NULL">
						and geog_auth_rec.island_group IS NULL
					<cfelseif ucase(island_group) EQ "NOT NULL">
						and geog_auth_rec.island_group IS NOT NULL
					<cfelseif left(island_group,1) is "=">
						AND upper(geog_auth_rec.island_group) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(island_group,len(island_group)-1))#">
					<cfelseif left(island_group,1) is "~">
						AND utl_match.jaro_winkler(geog_auth_rec.island_group, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(island_group,len(island_group)-1)#">) >= 0.90
					<cfelseif left(island_group,1) is "!~">
						AND utl_match.jaro_winkler(geog_auth_rec.island_group, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(island_group,len(island_group)-1)#">) < 0.90
					<cfelseif left(island_group,1) is "$">
						AND soundex(geog_auth_rec.island_group) = soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(island_group,len(island_group)-1))#">)
					<cfelseif left(island_group,2) is "!$">
						AND soundex(geog_auth_rec.island_group) <> soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(island_group,len(island_group)-2))#">)
					<cfelseif left(island_group,1) is "!">
						AND upper(geog_auth_rec.island_group) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(island_group,len(island_group)-1))#">
					<cfelse>
						<cfif find(',',island_group) GT 0>
							AND upper(geog_auth_rec.island_group) in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(island_group)#" list="yes"> )
						<cfelse>
							AND upper(geog_auth_rec.island_group) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(island_group)#%">
						</cfif>
					</cfif>
				</cfif>
				<cfif isdefined("ocean_region") AND len(ocean_region) gt 0>
					<cfif ucase(ocean_region) EQ "NULL">
						and geog_auth_rec.ocean_region IS NULL
					<cfelseif ucase(ocean_region) EQ "NOT NULL">
						and geog_auth_rec.ocean_region IS NOT NULL
					<cfelseif left(ocean_region,1) is "=">
						AND upper(geog_auth_rec.ocean_region) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(ocean_region,len(ocean_region)-1))#">
					<cfelseif left(ocean_region,1) is "~">
						AND utl_match.jaro_winkler(geog_auth_rec.ocean_region, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(ocean_region,len(ocean_region)-1)#">) >= 0.90
					<cfelseif left(ocean_region,1) is "!~">
						AND utl_match.jaro_winkler(geog_auth_rec.ocean_region, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(ocean_region,len(ocean_region)-1)#">) < 0.90
					<cfelseif left(ocean_region,1) is "$">
						AND soundex(geog_auth_rec.ocean_region) = soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(ocean_region,len(ocean_region)-1))#">)
					<cfelseif left(ocean_region,2) is "!$">
						AND soundex(geog_auth_rec.ocean_region) <> soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(ocean_region,len(ocean_region)-2))#">)
					<cfelseif left(ocean_region,1) is "!">
						AND upper(geog_auth_rec.ocean_region) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(ocean_region,len(ocean_region)-1))#">
					<cfelse>
						<cfif find(',',ocean_region) GT 0>
							AND upper(geog_auth_rec.ocean_region) in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(ocean_region)#" list="yes"> )
						<cfelse>
							AND upper(geog_auth_rec.ocean_region) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(ocean_region)#%">
						</cfif>
					</cfif>
				</cfif>
				<cfif isdefined("ocean_subregion") AND len(ocean_subregion) gt 0>
					<cfif ucase(ocean_subregion) EQ "NULL">
						and geog_auth_rec.ocean_subregion IS NULL
					<cfelseif ucase(ocean_subregion) EQ "NOT NULL">
						and geog_auth_rec.ocean_subregion IS NOT NULL
					<cfelseif left(ocean_subregion,1) is "=">
						AND upper(geog_auth_rec.ocean_subregion) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(ocean_subregion,len(ocean_subregion)-1))#">
					<cfelseif left(ocean_subregion,1) is "~">
						AND utl_match.jaro_winkler(geog_auth_rec.ocean_subregion, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(ocean_subregion,len(ocean_subregion)-1)#">) >= 0.90
					<cfelseif left(ocean_subregion,1) is "!~">
						AND utl_match.jaro_winkler(geog_auth_rec.ocean_subregion, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(ocean_subregion,len(ocean_subregion)-1)#">) < 0.90
					<cfelseif left(ocean_subregion,1) is "$">
						AND soundex(geog_auth_rec.ocean_subregion) = soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(ocean_subregion,len(ocean_subregion)-1))#">)
					<cfelseif left(ocean_subregion,2) is "!$">
						AND soundex(geog_auth_rec.ocean_subregion) <> soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(ocean_subregion,len(ocean_subregion)-2))#">)
					<cfelseif left(ocean_subregion,1) is "!">
						AND upper(geog_auth_rec.ocean_subregion) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(ocean_subregion,len(ocean_subregion)-1))#">
					<cfelse>
						<cfif find(',',ocean_subregion) GT 0>
							AND upper(geog_auth_rec.ocean_subregion) in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(ocean_subregion)#" list="yes"> )
						<cfelse>
							AND upper(geog_auth_rec.ocean_subregion) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(ocean_subregion)#%">
						</cfif>
					</cfif>
				</cfif>
				<cfif isdefined("sea") AND len(sea) gt 0>
					<cfif ucase(sea) EQ "NULL">
						and geog_auth_rec.sea IS NULL
					<cfelseif ucase(sea) EQ "NOT NULL">
						and geog_auth_rec.sea IS NOT NULL
					<cfelseif left(sea,1) is "=">
						AND upper(geog_auth_rec.sea) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(sea,len(sea)-1))#">
					<cfelseif left(sea,1) is "~">
						AND utl_match.jaro_winkler(geog_auth_rec.sea, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(sea,len(sea)-1)#">) >= 0.90
					<cfelseif left(sea,1) is "!~">
						AND utl_match.jaro_winkler(geog_auth_rec.sea, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(sea,len(sea)-1)#">) < 0.90
					<cfelseif left(sea,1) is "$">
						AND soundex(geog_auth_rec.sea) = soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(sea,len(sea)-1))#">)
					<cfelseif left(sea,2) is "!$">
						AND soundex(geog_auth_rec.sea) <> soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(sea,len(sea)-2))#">)
					<cfelseif left(sea,1) is "!">
						AND upper(geog_auth_rec.sea) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(sea,len(sea)-1))#">
					<cfelse>
						<cfif find(',',sea) GT 0>
							AND upper(geog_auth_rec.sea) in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(sea)#" list="yes"> )
						<cfelse>
							AND upper(geog_auth_rec.sea) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(sea)#%">
						</cfif>
					</cfif>
				</cfif>
				<cfif isdefined("water_feature") AND len(water_feature) gt 0>
					<cfif ucase(water_feature) EQ "NULL">
						and geog_auth_rec.water_feature IS NULL
					<cfelseif ucase(water_feature) EQ "NOT NULL">
						and geog_auth_rec.water_feature IS NOT NULL
					<cfelseif left(water_feature,1) is "=">
						AND upper(geog_auth_rec.water_feature) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(water_feature,len(water_feature)-1))#">
					<cfelseif left(water_feature,1) is "~">
						AND utl_match.jaro_winkler(geog_auth_rec.water_feature, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(water_feature,len(water_feature)-1)#">) >= 0.90
					<cfelseif left(water_feature,1) is "!~">
						AND utl_match.jaro_winkler(geog_auth_rec.water_feature, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(water_feature,len(water_feature)-1)#">) < 0.90
					<cfelseif left(water_feature,1) is "$">
						AND soundex(geog_auth_rec.water_feature) = soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(water_feature,len(water_feature)-1))#">)
					<cfelseif left(water_feature,2) is "!$">
						AND soundex(geog_auth_rec.water_feature) <> soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(water_feature,len(water_feature)-2))#">)
					<cfelseif left(water_feature,1) is "!">
						AND upper(geog_auth_rec.water_feature) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(water_feature,len(water_feature)-1))#">
					<cfelse>
						<cfif find(',',water_feature) GT 0>
							AND upper(geog_auth_rec.water_feature) in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(water_feature)#" list="yes"> )
						<cfelse>
							AND upper(geog_auth_rec.water_feature) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(water_feature)#%">
						</cfif>
					</cfif>
				</cfif>
				<cfif isdefined("source_authority") AND len(source_authority) gt 0>
					<cfif left(source_authority,1) is "=">
						AND upper(geog_auth_rec.source_authority) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(source_authority,len(source_authority)-1))#">
					<cfelseif left(source_authority,1) is "~">
						AND utl_match.jaro_winkler(geog_auth_rec.source_authority, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(source_authority,len(source_authority)-1)#">) >= 0.90
					<cfelseif left(source_authority,1) is "!~">
						AND utl_match.jaro_winkler(geog_auth_rec.source_authority, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(source_authority,len(source_authority)-1)#">) < 0.90
					<cfelseif left(source_authority,1) is "$">
						AND soundex(geog_auth_rec.source_authority) = soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(source_authority,len(source_authority)-1))#">)
					<cfelseif left(source_authority,2) is "!$">
						AND soundex(geog_auth_rec.source_authority) <> soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(source_authority,len(source_authority)-2))#">)
					<cfelseif left(source_authority,1) is "!">
						AND upper(geog_auth_rec.source_authority) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(source_authority,len(source_authority)-1))#">
					<cfelse>
						<cfif find(',',source_authority) GT 0>
							AND upper(geog_auth_rec.source_authority) in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(source_authority)#" list="yes"> )
						<cfelse>
							AND upper(geog_auth_rec.source_authority) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(source_authority)#%">
						</cfif>
					</cfif>
				</cfif>
				<cfif isdefined("highergeographyid") AND len(highergeographyid) gt 0>
					<cfif ucase(highergeographyid) EQ "NULL">
						and geog_auth_rec.highergeographyid IS NULL
					<cfelseif ucase(highergeographyid) EQ "NOT NULL">
						and geog_auth_rec.highergeographyid IS NOT NULL
					<cfelseif left(highergeographyid,1) is "=">
						AND upper(geog_auth_rec.highergeographyid) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(highergeographyid,len(highergeographyid)-1))#">
					<cfelseif left(highergeographyid,1) is "~">
						AND utl_match.jaro_winkler(geog_auth_rec.highergeographyid, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(highergeographyid,len(highergeographyid)-1)#">) >= 0.90
					<cfelseif left(highergeographyid,1) is "!~">
						AND utl_match.jaro_winkler(geog_auth_rec.highergeographyid, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(highergeographyid,len(highergeographyid)-1)#">) < 0.90
					<cfelseif left(highergeographyid,1) is "$">
						AND soundex(geog_auth_rec.highergeographyid) = soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(highergeographyid,len(highergeographyid)-1))#">)
					<cfelseif left(highergeographyid,2) is "!$">
						AND soundex(geog_auth_rec.highergeographyid) <> soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(highergeographyid,len(highergeographyid)-2))#">)
					<cfelseif left(highergeographyid,1) is "!">
						AND upper(geog_auth_rec.highergeographyid) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(highergeographyid,len(highergeographyid)-1))#">
					<cfelse>
						<cfif find(',',highergeographyid) GT 0>
							AND upper(geog_auth_rec.highergeographyid) in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(highergeographyid)#" list="yes"> )
						<cfelse>
							AND upper(geog_auth_rec.highergeographyid) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(highergeographyid)#%">
						</cfif>
					</cfif>
				</cfif>
				<cfif isdefined("highergeographyid_guid_type") AND len(highergeographyid_guid_type) gt 0>
					<cfif ucase(highergeographyid_guid_type) EQ "NULL">
						and geog_auth_rec.highergeographyid_guid_type IS NULL
					<cfelseif ucase(highergeographyid_guid_type) EQ "NOT NULL">
						and geog_auth_rec.highergeographyid_guid_type IS NOT NULL
					<cfelseif left(highergeographyid_guid_type,1) is "=">
						AND upper(geog_auth_rec.highergeographyid_guid_type) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(highergeographyid_guid_type,len(highergeographyid_guid_type)-1))#">
					<cfelseif left(highergeographyid_guid_type,1) is "~">
						AND utl_match.jaro_winkler(geog_auth_rec.highergeographyid_guid_type, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(highergeographyid_guid_type,len(highergeographyid_guid_type)-1)#">) >= 0.90
					<cfelseif left(highergeographyid_guid_type,1) is "!~">
						AND utl_match.jaro_winkler(geog_auth_rec.highergeographyid_guid_type, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(highergeographyid_guid_type,len(highergeographyid_guid_type)-1)#">) < 0.90
					<cfelseif left(highergeographyid_guid_type,1) is "$">
						AND soundex(geog_auth_rec.highergeographyid_guid_type) = soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(highergeographyid_guid_type,len(highergeographyid_guid_type)-1))#">)
					<cfelseif left(highergeographyid_guid_type,2) is "!$">
						AND soundex(geog_auth_rec.highergeographyid_guid_type) <> soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(highergeographyid_guid_type,len(highergeographyid_guid_type)-2))#">)
					<cfelseif left(highergeographyid_guid_type,1) is "!">
						AND upper(geog_auth_rec.highergeographyid_guid_type) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(highergeographyid_guid_type,len(highergeographyid_guid_type)-1))#">
					<cfelse>
						<cfif find(',',highergeographyid_guid_type) GT 0>
							AND upper(geog_auth_rec.highergeographyid_guid_type) in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(highergeographyid_guid_type)#" list="yes"> )
						<cfelse>
							AND upper(geog_auth_rec.highergeographyid_guid_type) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(highergeographyid_guid_type)#%">
						</cfif>
					</cfif>
				</cfif>
				<cfif isdefined("wkt_polygon") AND len(wkt_polygon) gt 0>
					<cfif ucase(wkt_polygon) EQ "NULL">
						and geog_auth_rec.wkt_polygon IS NULL
					<cfelseif ucase(wkt_polygon) EQ "NOT NULL">
						and geog_auth_rec.wkt_polygon IS NOT NULL
					</cfif>
				</cfif>
			GROUP BY
				 geog_auth_rec.geog_auth_rec_id,
				 geog_auth_rec.continent_ocean,
				 geog_auth_rec.country,
				 geog_auth_rec.state_prov,
				 geog_auth_rec.county,
				 geog_auth_rec.quad,
				 geog_auth_rec.feature,
				 geog_auth_rec.island,
				 geog_auth_rec.island_group,
				 geog_auth_rec.sea,
				 geog_auth_rec.valid_catalog_term_fg,
				 geog_auth_rec.source_authority,
				 geog_auth_rec.higher_geog,
				 geog_auth_rec.ocean_region,
				 geog_auth_rec.ocean_subregion,
				 geog_auth_rec.water_feature,
				<cfif return_wkt EQ "true">
					 geog_auth_rec.wkt_polygon,
				<cfelse>
					 nvl2(geog_auth_rec.wkt_polygon,'Yes','No'),
				</cfif>
				 geog_auth_rec.highergeographyid_guid_type,
				 geog_auth_rec.highergeographyid
			ORDER BY
				geog_auth_rec.higher_geog
		</cfquery>
		<cfif linguisticFlag >
			<!--- Reset NLS_COMP back to the default, or the session will keep using the generic_m_ai comparison/sort on subsequent searches. --->
			<cfquery datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				ALTER SESSION SET NLS_COMP = BINARY
			</cfquery>
		</cfif>
		<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfset columnNames = ListToArray(search.columnList)>
			<cfloop array="#columnNames#" index="columnName">
				<cfset row["#columnName#"] = "#search[columnName][currentrow]#">
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


<!---   Function getLocalities
   Obtain a list of localities in a form suitable for display in a jqxgrid
	@return json containing data about localities matching specified search criteria.
--->
<cffunction name="getLocalities" access="remote" returntype="any" returnformat="json">
	<cfargument name="higher_geog" type="string" required="no">
	<cfargument name="geog_auth_rec_id" type="string" required="no">
	<cfargument name="continent_ocean" type="string" required="no">
	<cfargument name="ocean_region" type="string" required="no">
	<cfargument name="ocean_subregion" type="string" required="no">
	<cfargument name="sea" type="string" required="no">
	<cfargument name="island" type="string" required="no">
	<cfargument name="island_group" type="string" required="no">
	<cfargument name="feature" type="string" required="no">
	<cfargument name="water_feature" type="string" required="no">
	<cfargument name="country" type="string" required="no">
	<cfargument name="state_prov" type="string" required="no">
	<cfargument name="county" type="string" required="no">
	<cfargument name="highergeographyid" type="string" required="no">
	<cfargument name="highergeographyid_guid_type" type="string" required="no">
	<cfargument name="return_wkt" type="string" required="no">
	<cfargument name="locality_id" type="string" required="no">
	<cfargument name="spec_locality" type="string" required="no">
	<cfargument name="locality_remarks" type="string" required="no">
	<cfargument name="orig_elev_units" type="string" required="no">
	<cfargument name="minElevOper" type="string" required="no">
	<cfargument name="minimum_elevation" type="string" required="no">
	<cfargument name="maxElevOper" type="string" required="no">
	<cfargument name="maximum_elevation" type="string" required="no">
	<cfargument name="accentInsenstive" type="string" required="no">
	<cfargument name="collection_id" type="string" required="no">
	<cfargument name="collnOper" type="string" required="no">
	<!--- 
	"ORIG_ELEV_UNITS" VARCHAR2(2 CHAR), 
	"TOWNSHIP" NUMBER, 
	"TOWNSHIP_DIRECTION" CHAR(1 CHAR), 
	"RANGE" NUMBER, 
	"RANGE_DIRECTION" CHAR(1 CHAR), 
	"SECTION" NUMBER, 
	"SECTION_PART" VARCHAR2(30 CHAR), 
	"SPEC_LOCALITY" VARCHAR2(400 CHAR), 
	"LOCALITY_REMARKS" VARCHAR2(4000 CHAR), 
	"LEGACY_SPEC_LOCALITY_FG" NUMBER, 
	"DEPTH_UNITS" VARCHAR2(20 CHAR), 
	"MIN_DEPTH" NUMBER, 
	"MAX_DEPTH" NUMBER, 
	"NOGEOREFBECAUSE" VARCHAR2(500), 
	"GEOREF_UPDATED_DATE" DATE, 
	"GEOREF_BY" VARCHAR2(50 CHAR), 
	"SOVEREIGN_NATION" VARCHAR2(255) DEFAULT '[unknown]' NOT NULL ENABLE NOVALIDATE, 
	"CURATED_FG" NUMBER(1,0) DEFAULT 0, 
	--->

	<!--- set default values where not defined --->
	<cfset linguisticFlag = false>
	<cfif isdefined("accentInsensitive") AND accentInsensitive EQ 1>
		<cfset linguisticFlag=true>
	</cfif>
	<cfif isdefined("collection_id") and len(collection_id) gt 0>
		<cfif not isDefined("collnOper")><cfset collnOper= "usedBy"></cfif>
	</cfif>
	<cfif NOT isDefined("return_wkt")><cfset return_wkt=""></cfif>

	<!--- manipulate operators on min/maximum elevation to reduce number of cfelseif clauses --->
	<cfif isdefined("maximum_elevation") AND len(maximum_elevation) gt 0>
		<cfif NOT isDefined("maxElevOper")><cfset maxElevOper=""></cfif>
		<cfif left(maximum_elevation,1) is "=">
			<cfset maximum_elevation = "#right(maximum_elevation,len(maximum_elevation)-1)#">
			<cfset maxElevOper = "=">
		</cfif>
		<cfif left(maximum_elevation,1) is "!">
			<cfset maximum_elevation = "#right(maximum_elevation,len(maximum_elevation)-1)#">
			<cfset maxElevOper = "!">
		</cfif>
		<cfif isDefined("maxElevOper") AND maxElevOper EQ "<>"><!--- " --->
			<cfset maxElevOper = "!">
		</cfif>
	</cfif>
	<cfif isdefined("minimum_elevation") AND len(minimum_elevation) gt 0>
		<cfif NOT isDefined("minElevOper")><cfset minElevOper=""></cfif>
		<cfif left(minimum_elevation,1) is "=">
			<cfset minimum_elevation = "#right(minimum_elevation,len(minimum_elevation)-1)#">
			<cfset minElevOper = "=">
		</cfif>
		<cfif left(minimum_elevation,1) is "!">
			<cfset minimum_elevation = "#right(minimum_elevation,len(minimum_elevation)-1)#">
			<cfset minElevOper = "!">
		</cfif>
		<cfif isDefined("minElevOper") AND minElevOper EQ "<>"><!--- " --->
			<cfset minElevOper = "!">
		</cfif>
	</cfif>

	<cfset data = ArrayNew(1)>
	<cftry>
		<cfset rows = 0>
		<cfif linguisticFlag >
			<!--- Set up the session to run an accent insensitive search --->
			<cfquery datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				ALTER SESSION SET NLS_COMP = LINGUISTIC
			</cfquery>
			<cfquery datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				ALTER SESSION SET NLS_SORT = GENERIC_M_AI
			</cfquery>
		</cfif>
		<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="search_result">
			SELECT 
				geog_auth_rec.geog_auth_rec_id,
				geog_auth_rec.continent_ocean,
				geog_auth_rec.country,
				geog_auth_rec.state_prov,
				geog_auth_rec.county,
				geog_auth_rec.quad,
				geog_auth_rec.feature,
				geog_auth_rec.island,
				geog_auth_rec.island_group,
				geog_auth_rec.sea,
				geog_auth_rec.valid_catalog_term_fg,
				geog_auth_rec.source_authority,
				geog_auth_rec.higher_geog,
				geog_auth_rec.ocean_region,
				geog_auth_rec.ocean_subregion,
				geog_auth_rec.water_feature,
				<cfif return_wkt EQ "true">
					geog_auth_rec.wkt_polygon,
				<cfelse>
					nvl2(geog_auth_rec.wkt_polygon,'Yes','No') as wkt_polygon,
				</cfif>
				geog_auth_rec.highergeographyid_guid_type,
				geog_auth_rec.highergeographyid,
				locality.locality_id,
				locality.spec_locality,
				locality.locality_remarks,
				locality.maximum_elevation,
				locality.minimum_elevation,
				locality.orig_elev_units,
				locality.curated_fg,
				locality.sovereign_nation,
				count(flatTableName.collection_object_id) as specimen_count
			FROM 
				locality
				join geog_auth_rec on locality.geog_auth_rec_id = geog_auth_rec.geog_auth_rec_id
				left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>flat<cfelse>filtered_flat</cfif> flatTableName on locality.locality_id=flatTableName.locality_id
			WHERE
				locality.locality_id is not null
				<cfif isDefined("geog_auth_rec_id") and len(geog_auth_rec_id) gt 0>
						and geog_auth_rec.geog_auth_rec_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geog_auth_rec_id#">
				<cfelse>
					<cfif isDefined("higher_geog") and len(higher_geog) gt 0>
						<cfif left(higher_geog,1) is "=">
							AND upper(geog_auth_rec.higher_geog) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(higher_geog,len(higher_geog)-1))#">
						<cfelse>
							and geog_auth_rec.higher_geog like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#higher_geog#%">
						</cfif>
					</cfif>
				</cfif>
				<cfif isDefined("locality_id") and len(locality_id) gt 0>
						and locality.locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
				</cfif>
				<cfif isDefined("valid_catalog_term_fg") and len(valid_catalog_term_fg) gt 0>
						and geog_auth_rec.valid_catalog_term_fg = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#valid_catalog_term_fg#">
				</cfif>
				<cfif isDefined("curated_fg") and len(curated_fg) gt 0>
						and locality.curated_fg = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#curated_fg#">
				</cfif>
				<cfif isDefined("sovereign_nation") and len(sovereign_nation) gt 0>
						and locality.sovereign_nation = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#sovereign_nation#">
				</cfif>
				<cfif isdefined("continent_ocean") AND len(continent_ocean) gt 0>
					<cfif ucase(continent_ocean) EQ "NULL">
						and geog_auth_rec.continent_ocean IS NULL
					<cfelseif ucase(continent_ocean) EQ "NOT NULL">
						and geog_auth_rec.continent_ocean IS NOT NULL
					<cfelseif left(continent_ocean,1) is "=">
						AND upper(geog_auth_rec.continent_ocean) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(continent_ocean,len(continent_ocean)-1))#">
					<cfelseif left(continent_ocean,1) is "~">
						AND utl_match.jaro_winkler(geog_auth_rec.continent_ocean, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(continent_ocean,len(continent_ocean)-1)#">) >= 0.90
					<cfelseif left(continent_ocean,1) is "!~">
						AND utl_match.jaro_winkler(geog_auth_rec.continent_ocean, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(continent_ocean,len(continent_ocean)-1)#">) < 0.90
					<cfelseif left(continent_ocean,1) is "$">
						AND soundex(geog_auth_rec.continent_ocean) = soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(continent_ocean,len(continent_ocean)-1))#">)
					<cfelseif left(continent_ocean,2) is "!$">
						AND soundex(geog_auth_rec.continent_ocean) <> soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(continent_ocean,len(continent_ocean)-2))#">)
					<cfelseif left(continent_ocean,1) is "!">
						AND upper(geog_auth_rec.continent_ocean) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(continent_ocean,len(continent_ocean)-1))#">
					<cfelseif find(',',continent_ocean) GT 0>
							AND upper(geog_auth_rec.continent_ocean) in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(continent_ocean)#" list="yes"> )
					<cfelse>
						AND upper(geog_auth_rec.continent_ocean) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(continent_ocean)#%">
					</cfif>
				</cfif>
				<cfif isdefined("country") AND len(country) gt 0>
					<cfset setup = setupClause(field="geog_auth_rec.country",value="#country#")>
					<cfif len(retval["value"]) EQ 0>
						AND #retval["pre"]# #retval["post"]#
					<cfelse>
						AND #retval["pre"]# <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#retval['value']#" list="#retval['list']#"> #retval["post"]#
					</cfif>
				</cfif>
				<cfif isdefined("state_prov") AND len(state_prov) gt 0>
					<cfif ucase(state_prov) EQ "NULL">
						and geog_auth_rec.state_prov IS NULL
					<cfelseif ucase(state_prov) EQ "NOT NULL">
						and geog_auth_rec.state_prov IS NOT NULL
					<cfelseif left(state_prov,1) is "=">
						AND upper(geog_auth_rec.state_prov) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(state_prov,len(state_prov)-1))#">
					<cfelseif left(state_prov,1) is "~">
						AND utl_match.jaro_winkler(geog_auth_rec.state_prov, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(state_prov,len(state_prov)-1)#">) >= 0.90
					<cfelseif left(state_prov,1) is "!~">
						AND utl_match.jaro_winkler(geog_auth_rec.state_prov, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(state_prov,len(state_prov)-1)#">) < 0.90
					<cfelseif left(state_prov,1) is "$">
						AND soundex(geog_auth_rec.state_prov) = soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(state_prov,len(state_prov)-1))#">)
					<cfelseif left(state_prov,2) is "!$">
						AND soundex(geog_auth_rec.state_prov) <> soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(state_prov,len(state_prov)-2))#">)
					<cfelseif left(state_prov,1) is "!">
						AND upper(geog_auth_rec.state_prov) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(state_prov,len(state_prov)-1))#">
					<cfelseif find(',',state_prov) GT 0>
						AND upper(geog_auth_rec.state_prov) in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(state_prov)#" list="yes"> )
					<cfelse>
						AND upper(geog_auth_rec.state_prov) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(state_prov)#%">
					</cfif>
				</cfif>
				<cfif isdefined("county") AND len(county) gt 0>
					<cfif ucase(county) EQ "NULL">
						and geog_auth_rec.county IS NULL
					<cfelseif ucase(county) EQ "NOT NULL">
						and geog_auth_rec.county IS NOT NULL
					<cfelseif left(county,1) is "=">
						AND upper(geog_auth_rec.county) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(county,len(county)-1))#">
					<cfelseif left(county,1) is "~">
						AND utl_match.jaro_winkler(geog_auth_rec.county, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(county,len(county)-1)#">) >= 0.90
					<cfelseif left(county,1) is "!~">
						AND utl_match.jaro_winkler(geog_auth_rec.county, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(county,len(county)-1)#">) < 0.90
					<cfelseif left(county,1) is "$">
						AND soundex(geog_auth_rec.county) = soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(county,len(county)-1))#">)
					<cfelseif left(county,2) is "!$">
						AND soundex(geog_auth_rec.county) <> soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(county,len(county)-2))#">)
					<cfelseif left(county,1) is "!">
						AND upper(geog_auth_rec.county) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(county,len(county)-1))#">
					<cfelseif find(',',county) GT 0>
						AND upper(geog_auth_rec.county) in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(county)#" list="yes"> )
					<cfelse>
						AND upper(geog_auth_rec.county) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(county)#%">
					</cfif>
				</cfif>
				<cfif isdefined("quad") AND len(quad) gt 0>
					<cfif ucase(quad) EQ "NULL">
						and geog_auth_rec.quad IS NULL
					<cfelseif ucase(quad) EQ "NOT NULL">
						and geog_auth_rec.quad IS NOT NULL
					<cfelseif left(quad,1) is "=">
						AND upper(geog_auth_rec.quad) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(quad,len(quad)-1))#">
					<cfelseif left(quad,1) is "~">
						AND utl_match.jaro_winkler(geog_auth_rec.quad, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(quad,len(quad)-1)#">) >= 0.90
					<cfelseif left(quad,1) is "!~">
						AND utl_match.jaro_winkler(geog_auth_rec.quad, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(quad,len(quad)-1)#">) < 0.90
					<cfelseif left(quad,1) is "$">
						AND soundex(geog_auth_rec.quad) = soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(quad,len(quad)-1))#">)
					<cfelseif left(quad,2) is "!$">
						AND soundex(geog_auth_rec.quad) <> soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(quad,len(quad)-2))#">)
					<cfelseif left(quad,1) is "!">
						AND upper(geog_auth_rec.quad) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(quad,len(quad)-1))#">
					<cfelseif find(',',quad) GT 0>
						AND upper(geog_auth_rec.quad) in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(quad)#" list="yes"> )
					<cfelse>
						AND upper(geog_auth_rec.quad) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(quad)#%">
					</cfif>
				</cfif>
				<cfif isdefined("feature") AND len(feature) gt 0>
					<cfif ucase(feature) EQ "NULL">
						and geog_auth_rec.feature IS NULL
					<cfelseif ucase(feature) EQ "NOT NULL">
						and geog_auth_rec.feature IS NOT NULL
					<cfelseif left(feature,1) is "=">
						AND upper(geog_auth_rec.feature) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(feature,len(feature)-1))#">
					<cfelseif left(feature,1) is "~">
						AND utl_match.jaro_winkler(geog_auth_rec.feature, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(feature,len(feature)-1)#">) >= 0.90
					<cfelseif left(feature,1) is "!~">
						AND utl_match.jaro_winkler(geog_auth_rec.feature, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(feature,len(feature)-1)#">) < 0.90
					<cfelseif left(feature,1) is "$">
						AND soundex(geog_auth_rec.feature) = soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(feature,len(feature)-1))#">)
					<cfelseif left(feature,2) is "!$">
						AND soundex(geog_auth_rec.feature) <> soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(feature,len(feature)-2))#">)
					<cfelseif left(feature,1) is "!">
						AND upper(geog_auth_rec.feature) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(feature,len(feature)-1))#">
					<cfelseif find(',',feature) GT 0>
						AND upper(geog_auth_rec.feature) in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(feature)#" list="yes"> )
					<cfelse>
						AND upper(geog_auth_rec.feature) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(feature)#%">
					</cfif>
				</cfif>
				<cfif isdefined("island") AND len(island) gt 0>
					<cfif ucase(island) EQ "NULL">
						and geog_auth_rec.island IS NULL
					<cfelseif ucase(island) EQ "NOT NULL">
						and geog_auth_rec.island IS NOT NULL
					<cfelseif left(island,1) is "=">
						AND upper(geog_auth_rec.island) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(island,len(island)-1))#">
					<cfelseif left(island,1) is "~">
						AND utl_match.jaro_winkler(geog_auth_rec.island, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(island,len(island)-1)#">) >= 0.90
					<cfelseif left(island,1) is "!~">
						AND utl_match.jaro_winkler(geog_auth_rec.island, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(island,len(island)-1)#">) < 0.90
					<cfelseif left(island,1) is "$">
						AND soundex(geog_auth_rec.island) = soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(island,len(island)-1))#">)
					<cfelseif left(island,2) is "!$">
						AND soundex(geog_auth_rec.island) <> soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(island,len(island)-2))#">)
					<cfelseif left(island,1) is "!">
						AND upper(geog_auth_rec.island) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(island,len(island)-1))#">
					<cfelseif find(',',island) GT 0>
						AND upper(geog_auth_rec.island) in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(island)#" list="yes"> )
					<cfelse>
						AND upper(geog_auth_rec.island) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(island)#%">
					</cfif>
				</cfif>
				<cfif isdefined("island_group") AND len(island_group) gt 0>
					<cfif ucase(island_group) EQ "NULL">
						and geog_auth_rec.island_group IS NULL
					<cfelseif ucase(island_group) EQ "NOT NULL">
						and geog_auth_rec.island_group IS NOT NULL
					<cfelseif left(island_group,1) is "=">
						AND upper(geog_auth_rec.island_group) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(island_group,len(island_group)-1))#">
					<cfelseif left(island_group,1) is "~">
						AND utl_match.jaro_winkler(geog_auth_rec.island_group, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(island_group,len(island_group)-1)#">) >= 0.90
					<cfelseif left(island_group,1) is "!~">
						AND utl_match.jaro_winkler(geog_auth_rec.island_group, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(island_group,len(island_group)-1)#">) < 0.90
					<cfelseif left(island_group,1) is "$">
						AND soundex(geog_auth_rec.island_group) = soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(island_group,len(island_group)-1))#">)
					<cfelseif left(island_group,2) is "!$">
						AND soundex(geog_auth_rec.island_group) <> soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(island_group,len(island_group)-2))#">)
					<cfelseif left(island_group,1) is "!">
						AND upper(geog_auth_rec.island_group) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(island_group,len(island_group)-1))#">
					<cfelseif find(',',island_group) GT 0>
						AND upper(geog_auth_rec.island_group) in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(island_group)#" list="yes"> )
					<cfelse>
						AND upper(geog_auth_rec.island_group) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(island_group)#%">
					</cfif>
				</cfif>
				<cfif isdefined("ocean_region") AND len(ocean_region) gt 0>
					<cfif ucase(ocean_region) EQ "NULL">
						and geog_auth_rec.ocean_region IS NULL
					<cfelseif ucase(ocean_region) EQ "NOT NULL">
						and geog_auth_rec.ocean_region IS NOT NULL
					<cfelseif left(ocean_region,1) is "=">
						AND upper(geog_auth_rec.ocean_region) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(ocean_region,len(ocean_region)-1))#">
					<cfelseif left(ocean_region,1) is "~">
						AND utl_match.jaro_winkler(geog_auth_rec.ocean_region, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(ocean_region,len(ocean_region)-1)#">) >= 0.90
					<cfelseif left(ocean_region,1) is "!~">
						AND utl_match.jaro_winkler(geog_auth_rec.ocean_region, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(ocean_region,len(ocean_region)-1)#">) < 0.90
					<cfelseif left(ocean_region,1) is "$">
						AND soundex(geog_auth_rec.ocean_region) = soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(ocean_region,len(ocean_region)-1))#">)
					<cfelseif left(ocean_region,2) is "!$">
						AND soundex(geog_auth_rec.ocean_region) <> soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(ocean_region,len(ocean_region)-2))#">)
					<cfelseif left(ocean_region,1) is "!">
						AND upper(geog_auth_rec.ocean_region) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(ocean_region,len(ocean_region)-1))#">
					<cfelseif find(',',ocean_region) GT 0>
						AND upper(geog_auth_rec.ocean_region) in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(ocean_region)#" list="yes"> )
					<cfelse>
						AND upper(geog_auth_rec.ocean_region) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(ocean_region)#%">
					</cfif>
				</cfif>
				<cfif isdefined("ocean_subregion") AND len(ocean_subregion) gt 0>
					<cfif ucase(ocean_subregion) EQ "NULL">
						and geog_auth_rec.ocean_subregion IS NULL
					<cfelseif ucase(ocean_subregion) EQ "NOT NULL">
						and geog_auth_rec.ocean_subregion IS NOT NULL
					<cfelseif left(ocean_subregion,1) is "=">
						AND upper(geog_auth_rec.ocean_subregion) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(ocean_subregion,len(ocean_subregion)-1))#">
					<cfelseif left(ocean_subregion,1) is "~">
						AND utl_match.jaro_winkler(geog_auth_rec.ocean_subregion, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(ocean_subregion,len(ocean_subregion)-1)#">) >= 0.90
					<cfelseif left(ocean_subregion,1) is "!~">
						AND utl_match.jaro_winkler(geog_auth_rec.ocean_subregion, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(ocean_subregion,len(ocean_subregion)-1)#">) < 0.90
					<cfelseif left(ocean_subregion,1) is "$">
						AND soundex(geog_auth_rec.ocean_subregion) = soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(ocean_subregion,len(ocean_subregion)-1))#">)
					<cfelseif left(ocean_subregion,2) is "!$">
						AND soundex(geog_auth_rec.ocean_subregion) <> soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(ocean_subregion,len(ocean_subregion)-2))#">)
					<cfelseif left(ocean_subregion,1) is "!">
						AND upper(geog_auth_rec.ocean_subregion) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(ocean_subregion,len(ocean_subregion)-1))#">
					<cfelseif find(',',ocean_subregion) GT 0>
						AND upper(geog_auth_rec.ocean_subregion) in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(ocean_subregion)#" list="yes"> )
					<cfelse>
						AND upper(geog_auth_rec.ocean_subregion) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(ocean_subregion)#%">
					</cfif>
				</cfif>
				<cfif isdefined("sea") AND len(sea) gt 0>
					<cfif ucase(sea) EQ "NULL">
						and geog_auth_rec.sea IS NULL
					<cfelseif ucase(sea) EQ "NOT NULL">
						and geog_auth_rec.sea IS NOT NULL
					<cfelseif left(sea,1) is "=">
						AND upper(geog_auth_rec.sea) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(sea,len(sea)-1))#">
					<cfelseif left(sea,1) is "~">
						AND utl_match.jaro_winkler(geog_auth_rec.sea, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(sea,len(sea)-1)#">) >= 0.90
					<cfelseif left(sea,1) is "!~">
						AND utl_match.jaro_winkler(geog_auth_rec.sea, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(sea,len(sea)-1)#">) < 0.90
					<cfelseif left(sea,1) is "$">
						AND soundex(geog_auth_rec.sea) = soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(sea,len(sea)-1))#">)
					<cfelseif left(sea,2) is "!$">
						AND soundex(geog_auth_rec.sea) <> soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(sea,len(sea)-2))#">)
					<cfelseif left(sea,1) is "!">
						AND upper(geog_auth_rec.sea) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(sea,len(sea)-1))#">
					<cfelseif find(',',sea) GT 0>
						AND upper(geog_auth_rec.sea) in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(sea)#" list="yes"> )
					<cfelse>
						AND upper(geog_auth_rec.sea) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(sea)#%">
					</cfif>
				</cfif>
				<cfif isdefined("water_feature") AND len(water_feature) gt 0>
					<cfif ucase(water_feature) EQ "NULL">
						and geog_auth_rec.water_feature IS NULL
					<cfelseif ucase(water_feature) EQ "NOT NULL">
						and geog_auth_rec.water_feature IS NOT NULL
					<cfelseif left(water_feature,1) is "=">
						AND upper(geog_auth_rec.water_feature) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(water_feature,len(water_feature)-1))#">
					<cfelseif left(water_feature,1) is "~">
						AND utl_match.jaro_winkler(geog_auth_rec.water_feature, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(water_feature,len(water_feature)-1)#">) >= 0.90
					<cfelseif left(water_feature,1) is "!~">
						AND utl_match.jaro_winkler(geog_auth_rec.water_feature, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(water_feature,len(water_feature)-1)#">) < 0.90
					<cfelseif left(water_feature,1) is "$">
						AND soundex(geog_auth_rec.water_feature) = soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(water_feature,len(water_feature)-1))#">)
					<cfelseif left(water_feature,2) is "!$">
						AND soundex(geog_auth_rec.water_feature) <> soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(water_feature,len(water_feature)-2))#">)
					<cfelseif left(water_feature,1) is "!">
						AND upper(geog_auth_rec.water_feature) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(water_feature,len(water_feature)-1))#">
					<cfelseif find(',',water_feature) GT 0>
						AND upper(geog_auth_rec.water_feature) in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(water_feature)#" list="yes"> )
					<cfelse>
						AND upper(geog_auth_rec.water_feature) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(water_feature)#%">
					</cfif>
				</cfif>
				<cfif isdefined("source_authority") AND len(source_authority) gt 0>
					<cfif left(source_authority,1) is "=">
						AND upper(geog_auth_rec.source_authority) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(source_authority,len(source_authority)-1))#">
					<cfelseif left(source_authority,1) is "~">
						AND utl_match.jaro_winkler(geog_auth_rec.source_authority, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(source_authority,len(source_authority)-1)#">) >= 0.90
					<cfelseif left(source_authority,1) is "!~">
						AND utl_match.jaro_winkler(geog_auth_rec.source_authority, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(source_authority,len(source_authority)-1)#">) < 0.90
					<cfelseif left(source_authority,1) is "$">
						AND soundex(geog_auth_rec.source_authority) = soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(source_authority,len(source_authority)-1))#">)
					<cfelseif left(source_authority,2) is "!$">
						AND soundex(geog_auth_rec.source_authority) <> soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(source_authority,len(source_authority)-2))#">)
					<cfelseif left(source_authority,1) is "!">
						AND upper(geog_auth_rec.source_authority) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(source_authority,len(source_authority)-1))#">
					<cfelseif find(',',source_authority) GT 0>
						AND upper(geog_auth_rec.source_authority) in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(source_authority)#" list="yes"> )
					<cfelse>
						AND upper(geog_auth_rec.source_authority) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(source_authority)#%">
					</cfif>
				</cfif>
				<cfif isdefined("highergeographyid") AND len(highergeographyid) gt 0>
					<cfif ucase(highergeographyid) EQ "NULL">
						and geog_auth_rec.highergeographyid IS NULL
					<cfelseif ucase(highergeographyid) EQ "NOT NULL">
						and geog_auth_rec.highergeographyid IS NOT NULL
					<cfelseif left(highergeographyid,1) is "=">
						AND upper(geog_auth_rec.highergeographyid) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(highergeographyid,len(highergeographyid)-1))#">
					<cfelseif left(highergeographyid,1) is "~">
						AND utl_match.jaro_winkler(geog_auth_rec.highergeographyid, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(highergeographyid,len(highergeographyid)-1)#">) >= 0.90
					<cfelseif left(highergeographyid,1) is "!~">
						AND utl_match.jaro_winkler(geog_auth_rec.highergeographyid, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(highergeographyid,len(highergeographyid)-1)#">) < 0.90
					<cfelseif left(highergeographyid,1) is "$">
						AND soundex(geog_auth_rec.highergeographyid) = soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(highergeographyid,len(highergeographyid)-1))#">)
					<cfelseif left(highergeographyid,2) is "!$">
						AND soundex(geog_auth_rec.highergeographyid) <> soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(highergeographyid,len(highergeographyid)-2))#">)
					<cfelseif left(highergeographyid,1) is "!">
						AND upper(geog_auth_rec.highergeographyid) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(highergeographyid,len(highergeographyid)-1))#">
					<cfelseif find(',',highergeographyid) GT 0>
						AND upper(geog_auth_rec.highergeographyid) in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(highergeographyid)#" list="yes"> )
					<cfelse>
						AND upper(geog_auth_rec.highergeographyid) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(highergeographyid)#%">
					</cfif>
				</cfif>
				<cfif isdefined("highergeographyid_guid_type") AND len(highergeographyid_guid_type) gt 0>
					<cfif ucase(highergeographyid_guid_type) EQ "NULL">
						and geog_auth_rec.highergeographyid_guid_type IS NULL
					<cfelseif ucase(highergeographyid_guid_type) EQ "NOT NULL">
						and geog_auth_rec.highergeographyid_guid_type IS NOT NULL
					<cfelseif left(highergeographyid_guid_type,1) is "=">
						AND upper(geog_auth_rec.highergeographyid_guid_type) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(highergeographyid_guid_type,len(highergeographyid_guid_type)-1))#">
					<cfelseif left(highergeographyid_guid_type,1) is "~">
						AND utl_match.jaro_winkler(geog_auth_rec.highergeographyid_guid_type, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(highergeographyid_guid_type,len(highergeographyid_guid_type)-1)#">) >= 0.90
					<cfelseif left(highergeographyid_guid_type,1) is "!~">
						AND utl_match.jaro_winkler(geog_auth_rec.highergeographyid_guid_type, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(highergeographyid_guid_type,len(highergeographyid_guid_type)-1)#">) < 0.90
					<cfelseif left(highergeographyid_guid_type,1) is "$">
						AND soundex(geog_auth_rec.highergeographyid_guid_type) = soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(highergeographyid_guid_type,len(highergeographyid_guid_type)-1))#">)
					<cfelseif left(highergeographyid_guid_type,2) is "!$">
						AND soundex(geog_auth_rec.highergeographyid_guid_type) <> soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(highergeographyid_guid_type,len(highergeographyid_guid_type)-2))#">)
					<cfelseif left(highergeographyid_guid_type,1) is "!">
						AND upper(geog_auth_rec.highergeographyid_guid_type) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(highergeographyid_guid_type,len(highergeographyid_guid_type)-1))#">
					<cfelseif find(',',highergeographyid_guid_type) GT 0>
						AND upper(geog_auth_rec.highergeographyid_guid_type) in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(highergeographyid_guid_type)#" list="yes"> )
					<cfelse>
						AND upper(geog_auth_rec.highergeographyid_guid_type) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(highergeographyid_guid_type)#%">
					</cfif>
				</cfif>
				<cfif isdefined("wkt_polygon") AND len(wkt_polygon) gt 0>
					<cfif ucase(wkt_polygon) EQ "NULL">
						and geog_auth_rec.wkt_polygon IS NULL
					<cfelseif ucase(wkt_polygon) EQ "NOT NULL">
						and geog_auth_rec.wkt_polygon IS NOT NULL
					</cfif>
				</cfif>
				<cfif isdefined("spec_locality") AND len(spec_locality) gt 0>
					<cfif ucase(spec_locality) EQ "NULL">
						and locality.spec_locality IS NULL
					<cfelseif ucase(spec_locality) EQ "NOT NULL">
						and locality.spec_locality IS NOT NULL
					<cfelseif left(spec_locality,1) is "=">
						AND upper(locality.spec_locality) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(spec_locality,len(spec_locality)-1))#">
					<cfelseif left(spec_locality,1) is "~">
						AND utl_match.jaro_winkler(locality.spec_locality, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(spec_locality,len(spec_locality)-1)#">) >= 0.90
					<cfelseif left(spec_locality,1) is "!~">
						AND utl_match.jaro_winkler(locality.spec_locality, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(spec_locality,len(spec_locality)-1)#">) < 0.90
					<cfelseif left(spec_locality,1) is "$">
						AND soundex(locality.spec_locality) = soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(spec_locality,len(spec_locality)-1))#">)
					<cfelseif left(spec_locality,2) is "!$">
						AND soundex(locality.spec_locality) <> soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(spec_locality,len(spec_locality)-2))#">)
					<cfelseif left(spec_locality,1) is "!">
						AND upper(locality.spec_locality) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(spec_locality,len(spec_locality)-1))#">
					<cfelseif find(',',spec_locality) GT 0>
						AND upper(locality.spec_locality) in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(spec_locality)#" list="yes"> )
					<cfelse>
						AND upper(locality.spec_locality) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(spec_locality)#%">
					</cfif>
				</cfif>
				<cfif isdefined("locality_remarks") AND len(locality_remarks) gt 0>
					<cfif ucase(locality_remarks) EQ "NULL">
						and locality.locality_remarks IS NULL
					<cfelseif ucase(locality_remarks) EQ "NOT NULL">
						and locality.locality_remarks IS NOT NULL
					<cfelseif left(locality_remarks,1) is "=">
						AND upper(locality.locality_remarks) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(locality_remarks,len(locality_remarks)-1))#">
					<cfelseif left(locality_remarks,1) is "~">
						AND utl_match.jaro_winkler(locality.locality_remarks, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(locality_remarks,len(locality_remarks)-1)#">) >= 0.90
					<cfelseif left(locality_remarks,1) is "!~">
						AND utl_match.jaro_winkler(locality.locality_remarks, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(locality_remarks,len(locality_remarks)-1)#">) < 0.90
					<cfelseif left(locality_remarks,1) is "$">
						AND soundex(locality.locality_remarks) = soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(locality_remarks,len(locality_remarks)-1))#">)
					<cfelseif left(locality_remarks,2) is "!$">
						AND soundex(locality.locality_remarks) <> soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(locality_remarks,len(locality_remarks)-2))#">)
					<cfelseif left(locality_remarks,1) is "!">
						AND upper(locality.locality_remarks) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(locality_remarks,len(locality_remarks)-1))#">
					<cfelseif find(',',locality_remarks) GT 0>
						AND upper(locality.locality_remarks) in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(locality_remarks)#" list="yes"> )
					<cfelse>
						AND upper(locality.locality_remarks) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(locality_remarks)#%">
					</cfif>
				</cfif>
				<cfif isdefined("orig_elev_units") AND len(orig_elev_units) gt 0>
					<cfif ucase(orig_elev_units) EQ "NULL">
						and locality.orig_elev_units IS NULL
					<cfelseif ucase(orig_elev_units) EQ "NOT NULL">
						and locality.orig_elev_units IS NOT NULL
					<cfelseif left(orig_elev_units,1) is "=">
						AND upper(locality.orig_elev_units) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(orig_elev_units,len(orig_elev_units)-1))#">
					<cfelseif left(orig_elev_units,1) is "~">
						AND utl_match.jaro_winkler(locality.orig_elev_units, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(orig_elev_units,len(orig_elev_units)-1)#">) >= 0.90
					<cfelseif left(orig_elev_units,1) is "!~">
						AND utl_match.jaro_winkler(locality.orig_elev_units, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#right(orig_elev_units,len(orig_elev_units)-1)#">) < 0.90
					<cfelseif left(orig_elev_units,1) is "$">
						AND soundex(locality.orig_elev_units) = soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(orig_elev_units,len(orig_elev_units)-1))#">)
					<cfelseif left(orig_elev_units,2) is "!$">
						AND soundex(locality.orig_elev_units) <> soundex(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(orig_elev_units,len(orig_elev_units)-2))#">)
					<cfelseif left(orig_elev_units,1) is "!">
						AND upper(locality.orig_elev_units) <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(right(orig_elev_units,len(orig_elev_units)-1))#">
					<cfelseif find(',',orig_elev_units) GT 0>
						AND upper(locality.orig_elev_units) in (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(orig_elev_units)#" list="yes"> )
					<cfelse>
						AND upper(locality.orig_elev_units) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(orig_elev_units)#%">
					</cfif>
				</cfif>
				<cfif isdefined("minimum_elevation") AND len(minimum_elevation) gt 0>
					<cfif ucase(minimum_elevation) EQ "NULL">
						and locality.minimum_elevation IS NULL
					<cfelseif ucase(minimum_elevation) EQ "NOT NULL">
						and locality.minimum_elevation IS NOT NULL
					<cfelseif minElevOper EQ "=">
						and locality.minimum_elevation = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#minimum_elevation#">
					<cfelseif minElevOper EQ "!"><!--- " --->
						and locality.minimum_elevation <> <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#minimum_elevation#">
					<cfelseif minElevOper EQ "<">
						and locality.minimum_elevation < <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#minimum_elevation#">
					<cfelseif minElevOper EQ ">"><!--- " --->
						and locality.minimum_elevation > <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#minimum_elevation#">
					<cfelseif left(minimum_elevation,2) is ">="><!--- " --->
						AND locality.minimum_elevation >= <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#right(minimum_elevation,len(minimum_elevation)-2)#">
					<cfelseif left(minimum_elevation,2) is "<=">
						AND locality.minimum_elevation <= <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#right(minimum_elevation,len(minimum_elevation)-2)#">
					<cfelseif left(minimum_elevation,1) is ">"><!--- " --->
						AND locality.minimum_elevation > <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#right(minimum_elevation,len(minimum_elevation)-1)#">
					<cfelseif left(minimum_elevation,1) is "<">
						AND locality.minimum_elevation < <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#right(minimum_elevation,len(minimum_elevation)-1)#">
					<cfelseif find('-',minimum_elevation) GT 1>
						<cfset bits = listToArray(minimum_elevation,'-')>
						<cfif arrayLength(bits) GT 1>
							AND locality.minimum_elevation between <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#bits[1]#"> AND <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#bits[2]#">
						<cfelse>
							AND locality.minimum_elevation = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#bits[1]#">
						</cfif>
					<cfelse>
						AND locality.minimum_elevation = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#minimum_elevation#">
					</cfif>
				</cfif>
				<cfif isdefined("maximum_elevation") AND len(maximum_elevation) gt 0>
					<cfif ucase(maximum_elevation) EQ "NULL">
						and locality.maximum_elevation IS NULL
					<cfelseif ucase(maximum_elevation) EQ "NOT NULL">
						and locality.maximum_elevation IS NOT NULL
					<cfelseif maxElevOper EQ "=">
						and locality.maximum_elevation = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#maximum_elevation#">
					<cfelseif maxElevOper EQ "!">
						and locality.maximum_elevation <> <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#maximum_elevation#">
					<cfelseif maxElevOper EQ "<">
						and locality.maximum_elevation < <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#maximum_elevation#">
					<cfelseif maxElevOper EQ ">"><!--- " --->
						and locality.maximum_elevation > <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#maximum_elevation#">
					<cfelseif left(maximum_elevation,2) is ">="><!--- " --->
						AND locality.maximum_elevation >= <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#right(maximum_elevation,len(maximum_elevation)-2)#">
					<cfelseif left(maximum_elevation,2) is "<=">
						AND locality.maximum_elevation <= <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#right(maximum_elevation,len(maximum_elevation)-2)#">
					<cfelseif left(maximum_elevation,1) is ">"><!--- " --->
						AND locality.maximum_elevation > <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#right(maximum_elevation,len(maximum_elevation)-1)#">
					<cfelseif left(maximum_elevation,1) is "<">
						AND locality.maximum_elevation < <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#right(maximum_elevation,len(maximum_elevation)-1)#">
					<cfelseif find('-',maximum_elevation) GT 1>
						<cfset bits = listToArray(maximum_elevation,'-')>
						<cfif arrayLength(bits) GT 1>
							AND locality.maximum_elevation between <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#bits[1]#"> AND <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#bits[2]#">
						<cfelse>
							AND locality.maximum_elevation = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#bits[1]#">
						</cfif>
					<cfelse>
						AND locality.maximum_elevation = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#maximum_elevation#">
					</cfif>
				</cfif>
				<cfif isdefined("collection_id") and len(collection_id) gt 0>
					<cfif collnOper is "usedOnlyBy">
						AND locality.locality_id in
								(select locality_id from vpd_collection_locality where collection_id =  <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_id#"> )
						AND locality.locality_id not in
								(select locality_id from vpd_collection_locality where collection_id <>  <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_id#"> and collection_id <> 0 )
					<cfelseif collnOper is "usedBy">
						AND locality.locality_id in
							(select locality_id from vpd_collection_locality where collection_id =  <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_id#"> )
					<cfelseif collnOper is "notUsedBy">
						AND locality.locality_id  not in
							(select locality_id from vpd_collection_locality where collection_id =  <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_id#"> )
					<cfelseif collnOper is "eventUsedOnlyBy">
						AND collecting_event.collecting_event_id in
								(select collecting_event_id from cataloged_item where collection_id =  <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_id#"> )
						AND collecting_event.collecting_event_id not in
								(select collecting_event_id from cataloged_item where collection_id <>  <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_id#"> and collection_id <> 0 )
					<cfelseif collnOper is "eventUsedBy">
						AND collecting_event.collecting_event_id in
								(select collecting_event_id from cataloged_item where collection_id =  <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_id#"> )
					<cfelseif collnOper is "eventSharedOnlyBy">
						AND collecting_event.collecting_event_id in
								(select collecting_event_id from cataloged_item where collection_id =  <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_id#"> )
						AND collecting_event.collecting_event_id in
								(select collecting_event_id from cataloged_item where collection_id <>  <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_id#"> and collection_id <> 0 )
					</cfif>
				</cfif>
			GROUP BY
				geog_auth_rec.geog_auth_rec_id,
				geog_auth_rec.continent_ocean,
				geog_auth_rec.country,
				geog_auth_rec.state_prov,
				geog_auth_rec.county,
				geog_auth_rec.quad,
				geog_auth_rec.feature,
				geog_auth_rec.island,
				geog_auth_rec.island_group,
				geog_auth_rec.sea,
				geog_auth_rec.valid_catalog_term_fg,
				geog_auth_rec.source_authority,
				geog_auth_rec.higher_geog,
				geog_auth_rec.ocean_region,
				geog_auth_rec.ocean_subregion,
				geog_auth_rec.water_feature,
				<cfif return_wkt EQ "true">
					geog_auth_rec.wkt_polygon,
				<cfelse>
					nvl2(geog_auth_rec.wkt_polygon,'Yes','No'),
				</cfif>
				geog_auth_rec.highergeographyid_guid_type,
				geog_auth_rec.highergeographyid,
				locality.locality_id,
				locality.spec_locality,
				locality.locality_remarks,
				locality.maximum_elevation,
				locality.minimum_elevation,
				locality.orig_elev_units,
				locality.curated_fg,
				locality.sovereign_nation
			ORDER BY
				geog_auth_rec.higher_geog,
				locality.spec_locality
		</cfquery>
		<cfset rows = search_result.recordcount>
		<cfset i = 1>
		<cfloop query="search">
			<cfset row = StructNew()>
			<cfset columnNames = ListToArray(search.columnList)>
			<cfloop array="#columnNames#" index="columnName">
				<cfset row["#columnName#"] = "#search[columnName][currentrow]#">
			</cfloop>
			<cfset data[i]  = row>
			<cfset i = i + 1>
		</cfloop>
		<cfif linguisticFlag >
			<!--- Reset NLS_COMP back to the default, or the session will keep using the generic_m_ai comparison/sort on subsequent searches. --->
			<cfquery datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				ALTER SESSION SET NLS_COMP = BINARY
			</cfquery>
		</cfif>
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
